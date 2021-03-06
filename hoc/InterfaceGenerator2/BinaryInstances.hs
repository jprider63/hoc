{-# LANGUAGE PatternGuards, ScopedTypeVariables, ExistentialQuantification #-}
module BinaryInstances() where

import Data.Binary hiding ( gput, gget)
import Data.Generics
import Control.Monad.Fix        ( MonadFix(..) )
import Control.Monad            ( msum )
import Data.ByteString.Char8    ( ByteString )
import Data.Maybe               ( fromJust, fromMaybe )

import Entities

data BinaryType = forall a. (Binary a, Typeable a) => BinaryType a

-- list of types that are handled by their real Binary instance
-- instead of the generic code below
specialTypes = [
        BinaryType (undefined :: ByteString),
        BinaryType (undefined :: String),
        BinaryType (undefined :: Int)
    ]

gput :: Data a => a -> Put
gput thing
    = fromMaybe gput0 $ msum $ map gput1 specialTypes
    where
        gput0 = case constrRep (toConstr thing) of
            IntConstr i     -> put i
            FloatConstr f   -> put f
            CharConstr c    -> put c
            AlgConstr i     -> do
                putWord8 (fromIntegral i)
                gmapM (\x -> gput x >> return x) thing
                return ()

        gput1 (BinaryType t) = fmap put $ cast thing `asTypeOf` Just t
    
gget :: forall a . Data a => Get a
gget
    = mfix gget' where
    
    gget' result =
            fromMaybe gget0 $ msum $ map gget1 specialTypes
        where
            dataType = dataTypeOf result
            resultType = typeOf result

            gget0 = do
                constr <- case dataTypeRep dataType of
                    IntRep -> do
                        i <- get @Int
                        return $ mkIntegralConstr dataType i
                    FloatRep -> do
                        f <- get @Float
                        return $ mkRealConstr dataType f
                    CharRep -> do
                        c <- get
                        return $ mkCharConstr dataType c
                    AlgRep constrs -> do
                        i <- getWord8
                        return (constrs !! (fromIntegral i - 1))
                fromConstrM gget constr
            
            gget1 :: Data a => BinaryType -> Maybe (Get a)
            gget1 (BinaryType t)  
                | typeOf t == resultType
                = Just (get >>= \x -> return $ fromJust $ cast $ x `asTypeOf` t)
                | otherwise = Nothing

instance MonadFix Get where
    mfix = error "TODO"

-- use gget and ggput to declare Binary instances for the types we need

instance Binary Entity where
    put = gput
    get = gget
instance Binary EntityID where
    put = gput
    get = gget
