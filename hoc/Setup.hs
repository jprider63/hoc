{-# OPTIONS_GHC -fwarn-unused-binds -fwarn-unused-imports #-}
module Main (main) where
import Distribution.Simple
import Distribution.PackageDescription
import Distribution.Simple.Setup
import Distribution.Simple.Configure
import Distribution.Simple.LocalBuildInfo
import System.FilePath
import System.IO
import System.Process
import qualified System.Info

main = defaultMainWithHooks $ defaultUserHooks {
        confHook = customConfig
    }

backquote :: String -> IO String
backquote cmd = do
    (inp,out,err,pid) <- runInteractiveCommand cmd
    hClose inp
    text <- hGetContents out
    waitForProcess pid
    hClose err
    return $ init text ++ let c = last text in if c == '\n' then [] else [c]

gnustepPaths :: IO (String, String, String)
gnustepPaths = do
    libgcc <- backquote "gcc --print-libgcc-file-name"
    headersAndLibraries <- backquote
            "opentool /bin/sh -c \
            \'. $GNUSTEP_MAKEFILES/filesystem.sh \
            \; echo $GNUSTEP_SYSTEM_HEADERS ; echo $GNUSTEP_SYSTEM_LIBRARIES'"

    let gcclibdir =  takeDirectory libgcc

    let system_headers : system_libs : _ = lines headersAndLibraries    
    -- sysroot <- getEnv "GNUSTEP_SYSTEM_ROOT"
    -- let system_headers = gnustepsysroot </> "Library/Headers"
    --    system_libs = gnustepsysroot </> "Library/Libraries"
    return (gcclibdir, system_libs, system_headers)

customConfig :: (GenericPackageDescription, HookedBuildInfo) -> ConfigFlags -> IO LocalBuildInfo
customConfig pdbi cf = do
    lbi <- configure pdbi cf
    if System.Info.os == "darwin"
        then return()
        else do
            (gcclibdir, system_libs, system_headers) <- gnustepPaths
            writeFile "HOC.buildinfo" $ unlines [
                "extra-lib-dirs: " ++ gcclibdir ++ ", " ++ system_libs,
                "include-dirs: " ++ system_headers ]

    return lbi
