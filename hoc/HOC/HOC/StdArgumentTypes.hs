{-# LANGUAGE TemplateHaskell,
             TypeFamilies, UndecidableInstances,
             TypeSynonymInstances, FlexibleInstances,
             ScopedTypeVariables #-}
module HOC.StdArgumentTypes where

import HOC.CBits
import HOC.Arguments
import HOC.FFICallInterface

import Control.Exception        ( bracket )
import Foreign
import Foreign.C.Types

import HOC.Unicode

-- Objective C

-- ID: already defined 

instance FFITypeable SEL where
    makeFFIType _ = makeFFIType (undefined :: Ptr ())

$(declareStorableObjCArgument [t| SEL |] ":")

instance ObjCArgument Bool where
    type ForeignArg Bool = CSChar
    exportArgument False = return 0
    exportArgument True = return 1
    importArgument 0 = return False
    importArgument _ = return True
    
    objCTypeString _ = "c"

$(declareStorableObjCArgument [t| Int |] "l")
$(declareStorableObjCArgument [t| Float |] "f")
$(declareStorableObjCArgument [t| Double |] "d")

instance ObjCArgument a => ObjCArgument (Ptr a) where
    exportArgument a = return a
    importArgument a = return a
    objCTypeString _
        | nested == "c" = "*"
        | otherwise = '^' : nested
        where nested = objCTypeString (undefined :: a)

-- Foreign.C.Types

$(declareStorableObjCArgument [t| CInt |] "i")
$(declareStorableObjCArgument [t| CUInt |] "I")

$(declareStorableObjCArgument [t| CFloat |] "f")
$(declareStorableObjCArgument [t| CDouble |] "d")

$(declareStorableObjCArgument [t| CChar |] "c")
$(declareStorableObjCArgument [t| CSChar |] "c")
$(declareStorableObjCArgument [t| CUChar |] "C")

$(declareStorableObjCArgument [t| CShort |] "s")
$(declareStorableObjCArgument [t| CUShort |] "S")

$(declareStorableObjCArgument [t| CLong |] "l")
$(declareStorableObjCArgument [t| CULong |] "L")

$(declareStorableObjCArgument [t| CLLong |] "q")
$(declareStorableObjCArgument [t| CULLong |] "Q")

-- String

withUTF8String str = withArray0 0 (unicodeToUtf8 str)

instance (ObjCArgument a, ForeignArg a ~ Ptr b) => ObjCArgument (Maybe a) where
    type ForeignArg (Maybe a) = ForeignArg a
    
    withExportedArgument Nothing  action = action nullPtr
    withExportedArgument (Just x) action = withExportedArgument x action
    exportArgument Nothing  = return nullPtr
    exportArgument (Just x) = exportArgument x
    importArgument p
        | p == nullPtr  = return Nothing
        | otherwise     = fmap Just (importArgument p)
    objCTypeString _ = objCTypeString (undefined :: a)

instance ObjCArgument String where
    type ForeignArg String = Ptr ObjCObject
    
    withExportedArgument arg action =
        bracket (withUTF8String arg utf8ToNSString) releaseObject action
    exportArgument arg = do
        nsstr <- withUTF8String arg utf8ToNSString
        autoreleaseObject nsstr
        return nsstr
    importArgument arg = nsStringToUTF8 arg >>= peekArray0 0
                         >>= return . utf8ToUnicode
   
    objCTypeString _ = "@"
