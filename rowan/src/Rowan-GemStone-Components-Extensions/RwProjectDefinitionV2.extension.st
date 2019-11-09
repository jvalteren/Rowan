Extension { #name : 'RwProjectDefinitionV2' }

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> asLoadedSymbolDictProject [

	^ RwGsLoadedSymbolDictComponentProject newForProjectReferenceDefinition: self projectRef.
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> exportTopazFormatTo: filePath [
	| projectSetDefinition projectSetModification visitor fileReference |
	fileReference := filePath asFileReference.
	projectSetDefinition := RwProjectSetDefinition new.
	projectSetDefinition addDefinition: self.
	projectSetModification := projectSetDefinition
		compareAgainstBase: RwProjectSetDefinition new.
	visitor := RwGsModificationTopazWriterVisitor new
		repositoryRootPath: fileReference parent;
		topazFilename: fileReference basename;
		yourself.
	visitor visit: projectSetModification
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> exportTopazFormatTo: filePath usingPackageNamesMap: packageNamesMap [
	| projectSetDefinition projectSetModification visitor fileReference |
	fileReference := filePath asFileReference.
	projectSetDefinition := RwProjectSetDefinition new.
	projectSetDefinition addDefinition: self.
	projectSetModification := projectSetDefinition
		compareAgainstBase: RwProjectSetDefinition new.
	visitor := RwGsModificationTopazWriterVisitor new
		repositoryRootPath: fileReference parent;
		topazFilename: fileReference basename;
		topazFilenamePackageNamesMap: packageNamesMap;
		yourself.
	visitor visit: projectSetModification
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetDefaultMethodEnvForUser: userId to: aBool [
	self projectRef gemstoneSetDefaultMethodEnvForUser: userId to: aBool
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetDefaultMethodEnvTo: aBool [
	self projectRef gemstoneSetDefaultMethodEnvTo: aBool
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetDefaultSymbolDictNameForUser: userId to: symbolDictName [
	self projectRef gemstoneSetDefaultSymbolDictNameForUser: userId to: symbolDictName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetDefaultSymbolDictNameTo: symbolDictName [
	self projectRef gemstoneSetDefaultSymbolDictNameTo: symbolDictName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetDefaultUseSessionMethodsForExtensionsForUser: userId to: aBool [
	self projectRef gemstoneSetDefaultUseSessionMethodsForExtensionsForUser: userId to: aBool
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetDefaultUseSessionMethodsForExtensionsTo: aBool [
	self projectRef gemstoneSetDefaultUseSessionMethodsForExtensionsTo: aBool
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetMethodEnv: env forPackageNamed: packageName [
	self projectRef gemstoneSetMethodEnv: env forPackageNamed: packageName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetSymbolDictName: symbolDictName forPackageNamed: packageName [
	^ self projectRef
		gemstoneSetSymbolDictName: symbolDictName
		forPackageNamed: packageName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> gemstoneSetUseSessionMethodsForExtensions: aBool forPackageNamed: packageName [
	self projectRef
		gemstoneSetUseSessionMethodsForExtensions: aBool
		forPackageNamed: packageName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> methodEnvForPackageNamed: packageName [

	^self projectRef methodEnvForPackageNamed: packageName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> symbolDictNameForPackageNamed: packageName [

	^self projectRef symbolDictNameForPackageNamed: packageName
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> updateGsPlatformLoadedComponentInfoFor: aLoadedProject from: projectInfo [

	|  thePackageMapSpecs |
	thePackageMapSpecs := projectInfo at:  'packageMapSpecs' .
	(thePackageMapSpecs at: #defaultSymbolDictName otherwise: nil) 
		ifNotNil: [:name | aLoadedProject defaultSymbolDictName: name ].
	(thePackageMapSpecs at: #defaultUseSessionMethodsForExtensions otherwise: nil) 
		ifNotNil: [:boolean | 
			aLoadedProject defaultUseSessionMethodsForExtensions: boolean  ].
	(thePackageMapSpecs at: #packageNameToPlatformPropertiesMap otherwise: nil) 
		ifNotNil: [:map | aLoadedProject packageNameToPlatformPropertiesMap: map]
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> updateGsPlatformSpecLoadedProjectInfo: projectInfo [

	| thePackageMapSpecs |
	thePackageMapSpecs := projectInfo at:  'packageMapSpecs' .
	(thePackageMapSpecs at: #defaultSymbolDictName otherwise: nil) 
		ifNotNil: [:name | self defaultSymbolDictName: name ].
	(thePackageMapSpecs at: #defaultUseSessionMethodsForExtensions otherwise: nil) 
		ifNotNil: [:boolean | 
			self defaultUseSessionMethodsForExtensions: boolean  ].
	(thePackageMapSpecs at: #packageNameToPlatformPropertiesMap otherwise: nil) 
		ifNotNil: [:map | self packageNameToPlatformPropertiesMap: map]
]

{ #category : '*rowan-gemstone-components-extensions' }
RwProjectDefinitionV2 >> useSessionMethodsForExtensionsForPackageNamed: packageName [

	^ self projectRef useSessionMethodsForExtensionsForPackageNamed: packageName
]