module HOC (
        SEL,
        ID,
        nil,
        Object(..),
        Class,
        MetaClass,
        ClassAndObject,
        ClassObject,
        classObject,
        ( # ), ( #. ),
        castObject,
        declareClass,
        declareSelector,
        declareRenamedSelector,
        Covariant,
        CovariantInstance,
        Allocated,
        Inited,

        getSEL,
        
        withAutoreleasePool,

        isNil,
        
        IVar,
        getIVar,
        setIVar,
        getAndSetIVar,
        getInstanceMVar,

        ClassMember(..),
        exportClass,
        
        NewlyAllocated,
        
        SuperClass,
        SuperTarget,
        super,
        castSuper,
        
        CEnum(..),
        declareCEnum,
        declareAnonymousCEnum,
        
        declareExternConst,
        declareExternFun,
        
        sel,
        
        ObjCArgument(..),
        declareMarshalledObjectType,
        
        FFIType(..),
        struct,
        
        WrappedNSException(..),
        
        declareCStruct,
        declareCStructWithTag,
        
        getImportedObjectCount
    ) where

import HOC.CBits
import HOC.Arguments
import HOC.MessageTarget
import HOC.Class
import HOC.DeclareClass
import HOC.DeclareSelector
import HOC.ExportClass
import HOC.ID
import HOC.Utilities
import HOC.NewlyAllocated
import HOC.Super
import HOC.CEnum
import HOC.ExternConstants
import HOC.ExternFunctions
import HOC.Selectors
import HOC.Exception
import HOC.CStruct
import Foreign.ObjC ( SEL, getSEL )
import Foreign.LibFFI.Experimental