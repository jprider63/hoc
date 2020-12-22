set -x
function build()
{
    pushd HOC-$1
    stack exec -- runhaskell Setup.hs configure $ARGUMENTS
    stack exec -- runhaskell Setup.hs build
    stack exec -- runhaskell Setup.hs install
    popd
}

ARGUMENTS=$*
OPTS=-q

IFGEN="stack exec -- hoc-ifgen"

if [ "$HOC_SDK" != "" ];
then
    IFGEN="$IFGEN -s $HOC_SDK"
fi

set -e
mkdir -p Generated
cd Generated

$IFGEN Foundation -f -b ../binding-script.txt -a ../AdditionalCode/ $OPTS
build Foundation
$IFGEN QuartzCore -f -b ../binding-script.txt -a ../AdditionalCode/ -d Foundation $OPTS
build QuartzCore
$IFGEN AppKit -f -b ../binding-script.txt -a ../AdditionalCode/ -d Foundation -d QuartzCore $OPTS
build AppKit
$IFGEN CoreData -f -b ../binding-script.txt -a ../AdditionalCode/ -d Foundation \
    -d AppKit -d QuartzCore $OPTS    # fake dependencies
build CoreData
$IFGEN Cocoa -u -d Foundation -d QuartzCore -d AppKit -d CoreData $OPTS
build Cocoa
