Class {
	#name : 'RwGsLoadedSymbolDictClassExtension',
	#superclass : 'RwLoadedClassExtension',
	#category : 'Rowan-GemStone-Core'
}

{ #category : 'instance creation' }
RwGsLoadedSymbolDictClassExtension class >> newForClass: aClass inPackage: aLoadedPackage [

	^ self new initializeForClass: aClass inPackage: aLoadedPackage
]

{ #category : 'methods' }
RwGsLoadedSymbolDictClassExtension >> addLoadedClassMethod: aLoadedMethod [

	self markPackageDirty.
	loadedClassMethods at: aLoadedMethod key put: aLoadedMethod.
	aLoadedMethod loadedClass: self
]

{ #category : 'methods' }
RwGsLoadedSymbolDictClassExtension >> addLoadedInstanceMethod: aLoadedMethod [

	self markPackageDirty.
	loadedInstanceMethods at: aLoadedMethod key put: aLoadedMethod.
	aLoadedMethod loadedClass: self
]

{ #category : 'methods' }
RwGsLoadedSymbolDictClassExtension >> addLoadedMethod: aLoadedMethod [

	aLoadedMethod classIsMeta
		ifTrue: [self addLoadedClassMethod: aLoadedMethod]
		ifFalse: [self addLoadedInstanceMethod: aLoadedMethod]
]

{ #category : 'removing' }
RwGsLoadedSymbolDictClassExtension >> disownFromLoaded: aPackageSymbolDictionary [

	loadedInstanceMethods
		valuesDo: [ :loadedInstanceMethod | 
			self removeLoadedInstanceMethod: loadedInstanceMethod.
			aPackageSymbolDictionary methodRegistry
				removeKey: loadedInstanceMethod handle ].
	loadedClassMethods
		valuesDo: [ :loadedClassMethod | 
			self removeLoadedClassMethod: loadedClassMethod.
			aPackageSymbolDictionary methodRegistry removeKey: loadedClassMethod handle ].

	(aPackageSymbolDictionary classExtensionRegistry at: handle classHistory) remove: self.
	(aPackageSymbolDictionary classExtensionRegistry at: handle classHistory) isEmpty
		ifTrue: [ aPackageSymbolDictionary classExtensionRegistry removeKey: handle classHistory ].

]

{ #category : 'private-updating' }
RwGsLoadedSymbolDictClassExtension >> handleClassDeletion [

	"The class to which I refer is or has been deleted. Clean up the loaded extension methods.
		I expect the caller to remove me from the registry."

	loadedInstanceMethods values , loadedClassMethods values
		do: [ :loadedMethod | loadedMethod handleClassDeletion ].
	self loadedPackage removeLoadedClassExtension: self
]

{ #category : 'private-updating' }
RwGsLoadedSymbolDictClassExtension >> handleClassDeletionOrNewVersion [
	"The class is deleted if both:
	* its name no longer resolves to a class in the classHistory of the class I remember.
	* no class in the classHistory of the class I remember is accessible under its name.
	If my name no longer resolves to my class, but another class in its classHistory does resolve,
	consider it a class re-version or rename.
	Answer true if the class still exists, false if it has been deleted."

	| resolved thoseResolving |
	resolved := Rowan image resolveClassNamed: name.
	resolved == handle
		ifTrue: [ ^ true ].	"Has been deleted, renamed, or a new version under the same name.
	Answer false if deleted, set handle and answer true otherwise."
	thoseResolving := handle classHistory reverse
		select: [ :aClass | aClass == (Rowan image resolveClassNamed: aClass name) ].
	thoseResolving size = 0
		ifTrue: [ 
			self handleClassDeletion.
			^ false ].
	thoseResolving size > 1
		ifTrue: [ 
			RwNotification
				signal:
					'Class history with multiple "current" members found. One associated name is '
						, name ].
	handle := thoseResolving first.
	^ true
]

{ #category : 'initialization' }
RwGsLoadedSymbolDictClassExtension >> initialize [

	super initialize.
	loadedInstanceMethods := KeyValueDictionary new.
	loadedClassMethods := KeyValueDictionary new
]

{ #category : 'initialization' }
RwGsLoadedSymbolDictClassExtension >> initializeForClass: aClass inPackage: aLoadedPackage [

	self initialize.
	name := aClass name asString.
	handle := aClass.
	aLoadedPackage addLoadedClassExtension: self.
	self propertyAt: 'name' put: name
]

{ #category : 'accessing' }
RwGsLoadedSymbolDictClassExtension >> key [
	"Answer some token that will uniquely identify me relative to any other LoadedExtendedClass in the same package."

	^name
]

{ #category : 'methods' }
RwGsLoadedSymbolDictClassExtension >> removeLoadedClassMethod: aLoadedMethod [

	self markPackageDirty.
	loadedClassMethods removeKey: aLoadedMethod key
		ifAbsent: [self error: 'Method not present in LoadedClassExtension']
]

{ #category : 'methods' }
RwGsLoadedSymbolDictClassExtension >> removeLoadedInstanceMethod: aLoadedMethod [

	self markPackageDirty.
	loadedInstanceMethods removeKey: aLoadedMethod key
		ifAbsent: [self error: 'Method not present in LoadedClassExtension']
]

{ #category : 'methods' }
RwGsLoadedSymbolDictClassExtension >> removeLoadedMethod: aLoadedMethod [

	aLoadedMethod classIsMeta
		ifTrue: [self removeLoadedClassMethod: aLoadedMethod]
		ifFalse: [self removeLoadedInstanceMethod: aLoadedMethod]
]
