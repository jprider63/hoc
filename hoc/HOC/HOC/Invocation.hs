module HOC.Invocation where

import Foreign
import Foreign.C            ( CInt )
import Control.Monad        ( when )

import HOC.CBits
import HOC.Arguments
import HOC.FFICallInterface

import HOC.Exception

callWithException cif fun ret args = do
    exception <- c_callWithExceptions cif fun ret args
    when (exception /= nullPtr) $
        exceptionObjCToHaskell exception

withMarshalledArgument :: ObjCArgument a => a -> (Ptr () -> IO c) -> IO c

withMarshalledArgument arg act =
    withExportedArgument arg (\exported -> with exported (act . castPtr))

callWithoutRetval :: FFICif -> FunPtr a
                  -> Ptr (Ptr ())
                  -> IO ()

callWithoutRetval cif fun args = callWithException cif fun nullPtr args


callWithRetval :: ObjCArgument b
               => FFICif -> FunPtr a
               -> Ptr (Ptr ())
               -> IO b

callWithRetval cif fun args = do
    allocaRetval $ \retptr ->
        callWithException cif fun retptr args
        >> peekRetval retptr >>= importArgument


setMarshalledRetval :: ObjCArgument a => Bool -> Ptr () -> a -> IO ()
setMarshalledRetval retained ptr val =
    (if retained then exportArgumentRetained else exportArgument) val
        >>= poke (castPtr ptr)

getMarshalledArgument :: ObjCArgument a => Ptr (Ptr ()) -> Int -> IO a
getMarshalledArgument args idx = do
    p <- peekElemOff args idx
    arg <- peek (castPtr p)
    importArgument arg
    
    
kHOCEnteredHaskell = 1 :: CInt
kHOCImportedArguments = 2 :: CInt
kHOCAboutToExportResult = 3 :: CInt
kHOCAboutToLeaveHaskell = 4 :: CInt


