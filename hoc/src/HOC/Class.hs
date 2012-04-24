{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances #-}
module HOC.Class
    ( Class_
    , Class
    , MetaClass
    
    , ClassAndObject
    , ClassObject(..)
    , unsafeGetClassObject
    , RawStaticClass(..)
    , unsafeGetRawClassObject
    ) where

import Foreign.ObjC         ( ObjCClass, objc_getClass, object_getClass )
import Foreign.Ptr          ( Ptr, castPtr )
import HOC.ID               ( ID, importClass )
import HOC.MessageTarget    ( Object )
import System.IO.Unsafe     ( unsafePerformIO )

data Class_ a
type Class a = ID (Class_ a)
type MetaClass a = Class (Class_ a)

class (Object a, Object b) => ClassAndObject a b | a -> b, b -> a

instance ClassAndObject (Class a) (ID a)

class Object cls => ClassObject cls
    where
        classObject :: cls

-- called from generated code, save space:
unsafeGetClassObject :: String -> Class a
unsafeGetClassObject name = unsafePerformIO $
    importClass (unsafeGetRawClassObject name)


class Object a => RawStaticClass a where
    rawStaticClassForObject :: a -> Ptr ObjCClass

instance RawStaticClass (ID a) => RawStaticClass (Class a) where
    rawStaticClassForObject = unsafePerformIO . object_getClass
        . castPtr . rawStaticClassForObject . objdummy
        where
            objdummy :: Class a -> ID a
            objdummy = undefined

unsafeGetRawClassObject :: String -> Ptr ObjCClass
unsafeGetRawClassObject = unsafePerformIO . objc_getClass
