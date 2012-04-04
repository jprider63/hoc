{-# LANGUAGE MagicHash, TemplateHaskell #-}
module HOC.SelectorMarshaller(
        SelectorInfo(..),
        mkSelectorInfo,
        mkSelectorInfoRetained,
        makeMarshaller,
        makeMarshallers,
        marshallerName
    ) where

import Foreign                      ( withArray )
import Foreign.LibFFI.Experimental  ( CIF, withOutArg )
import Foreign.ObjC                 ( SEL )
import Foreign.Ptr                  ( Ptr, castPtr )
import GHC.Base                     ( unpackCString# )
import HOC.Arguments                ( objcOutArg )
import HOC.Base                     ( getSelectorForName )
import HOC.CBits                    ( ObjCObject )
import HOC.MessageTarget
import HOC.TH
import System.IO.Unsafe             ( unsafePerformIO )

data SelectorInfo a = SelectorInfo {
        selectorInfoObjCName :: String,
        selectorInfoHaskellName :: String,
        selectorInfoCif :: !(CIF (Ptr ObjCObject -> SEL -> a)),
        selectorInfoSel :: !SEL,
        selectorInfoResultRetained :: !Bool
    }

{-# NOINLINE mkSelectorInfo #-}
mkSelectorInfo objCName hsName cif
    = SelectorInfo objCName hsName cif (getSelectorForName objCName) False

{-# NOINLINE mkSelectorInfo# #-}
mkSelectorInfo# objCName# hsName# cif
    -- NOTE: Don't call mkSelectorInfo here, the rule would apply!
    = SelectorInfo objCName hsName cif (getSelectorForName objCName) False
    where
        objCName = unpackCString# objCName#
        hsName   = unpackCString# hsName#

{-# RULES
"litstr" forall s1 s2 cif.
    mkSelectorInfo (unpackCString# s1) (unpackCString# s2) cif
    = mkSelectorInfo# s1 s2 cif
  #-}

{-# NOINLINE mkSelectorInfoRetained #-}
mkSelectorInfoRetained objCName hsName cif
    = SelectorInfo objCName hsName cif (getSelectorForName objCName) True

{-# NOINLINE mkSelectorInfoRetained# #-}
mkSelectorInfoRetained# objCName# hsName# cif
    -- NOTE: Don't call mkSelectorInfo here, the rule would apply!
    = SelectorInfo objCName hsName cif (getSelectorForName objCName) True
    where
        objCName = unpackCString# objCName#
        hsName   = unpackCString# hsName#

{-# RULES
"litstr" forall s1 s2 cif.
    mkSelectorInfoRetained (unpackCString# s1) (unpackCString# s2) cif
    = mkSelectorInfoRetained# s1 s2 cif
  #-}


makeMarshaller maybeInfoName haskellName nArgs isUnit isPure isRetained =
            funD haskellName [
                clause (map varP $ infoArgument ++ map mkName arguments
                        ++ [mkName "target"])
                     (normalB $ marshallerBody
                    ) []
            ]
    where
        (infoVar, infoArgument) = case maybeInfoName of
                    Just name -> (varE name, [])
                    Nothing -> (varE (mkName "info"), [mkName "info"])
        arguments = [ "arg" ++ show i | i <- [1..nArgs] ]
        argumentsToMarshal = varE (mkName "target")
                           : [| selectorInfoSel $(infoVar) |]
                           : map (varE.mkName) arguments
        marshalledArguments = mkName "target'"
                            : mkName "selector'"
                            : map (mkName . (++"'")) arguments
   
        marshallerBody = purify $
                         checkTargetNil $
                         releaseRetvalIfRetained $
                         marshallArgs  $
                         collectArgs $
                         invoke

        marshallArgs = marshallArgs' argumentsToMarshal marshalledArguments
            where
                marshallArgs' [] [] e = e
                marshallArgs' (arg:args) (arg':args') e =
                    [| withOutArg objcOutArg $arg $(lamE [varP arg'] e') |]
                    where e' = marshallArgs' args args' e
   
        collectArgs e = [| withArray $(listE [ [| castPtr $(varE arg) |]
                                             | arg <- marshalledArguments
                                             ])
                                     $(lamE [varP $ mkName "args"] e) |]

        invoke | isUnit = [| sendMessageWithoutRetval $(targetVar)
                                                      (selectorInfoCif $(infoVar))
                                                      $(argsVar)|]
               | otherwise = [| sendMessageWithRetval $(targetVar)
                                                      (selectorInfoCif $(infoVar))
                                                      $(argsVar)|]
            where argsVar = varE $ mkName "args"
                  targetVar = varE $ mkName "target"

        purify e | isPure = [| unsafePerformIO $(e) |]
                 | otherwise = e
                 
        releaseRetvalIfRetained e | isRetained = [| $e >>= releaseExtraReference |]
                                  | otherwise = e
                                  
        checkTargetNil e = [| failNilMessage $(varE $ mkName "target")
                                             (selectorInfoHaskellName $(infoVar))
                              >> $(e) |]
    
makeMarshallers n =
        sequence $
        [ makeMarshaller Nothing (mkName $ marshallerName nArgs isUnit) nArgs isUnit False False
        | nArgs <- [0..n], isUnit <- [False, True] ]

marshallerName nArgs False = "method" ++ show nArgs
marshallerName nArgs True = "method" ++ show nArgs ++ "_"

failNilMessage :: MessageTarget t => t -> String -> IO ()
failNilMessage target selectorName
    | isNil target = fail $ "Message sent to nil: " ++ selectorName
    | otherwise = return ()
