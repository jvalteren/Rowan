"
Abstract class with support for walking a modification tree and writing out the source code in a variety of formats:
	topaz fileout
	Tonel
	Filetree
"
Class {
	#name : 'RwModificationWriterVisitor',
	#superclass : 'Object',
	#instVars : [
		'currentProjectDefinition',
		'currentPackageDefinition',
		'currentClassDefinition',
		'currentClassExtension',
		'repositoryRootPath'
	],
	#category : 'Rowan-Core'
}

{ #category : 'accessing' }
RwModificationWriterVisitor class >> lineEnding [
  "Answer the os-specific line endings"

  ^ String with: Character lf
]

{ #category : 'private' }
RwModificationWriterVisitor >> _createFileNameMapForClassesOrPackages: aClassOrPackageDefinitionDictionary [
 
  "answer a dictionary that maps each definition name to a filename that is guaranteed unique on case insensitive file systems"

  | map filenameMap |
  map := Dictionary new.
  aClassOrPackageDefinitionDictionary
    do: [ :cDef | 
      | nam col |
      "sort into bins by lowercase selector. "
      nam := cDef name asLowercase.
      col := map
        at: nam
        ifAbsentPut: [ OrderedCollection new ].
      col add: cDef ].
  filenameMap := Dictionary new.
  map values
	do: [ :col | 
	  | name sortedCol |
	  col size = 1
		ifTrue: [ 
		  | def |
		  "no need to distinguish filename"
		  def := col at: 1.
		  filenameMap
			at: def name
			put: def name ]
		ifFalse: [ 
		  "tack on postfix to guarantee  file names are unique on case insensitive file systems"
		  sortedCol := col sorted: [ :a :b | a asString _unicodeLessThan: b asString ].
		  (1 to: sortedCol size) do: [ :index | 
			| def filename |
			def := sortedCol at: index.
			filename := def name.
			filename := filename , '..' , index printString.
			filenameMap at: def name put: filename ] ] ].
  ^ filenameMap
]

{ #category : 'private' }
RwModificationWriterVisitor >> _newLine [
	 ^ self class lineEnding
]

{ #category : 'project writing' }
RwModificationWriterVisitor >> _repositoryFormatFor: aProjectModification [

	^ (self _repositoryPropertyDictFor: aProjectModification) at: #format ifAbsent: [ 'filetree' ]
]

{ #category : 'project writing' }
RwModificationWriterVisitor >> _repositoryPropertyDictFor: aProjectModification [

	| propertiesFile |
	propertiesFile := self repositoryRootPath / aProjectModification after repoPath / 'properties.st'.
	propertiesFile exists
		ifFalse: [ propertiesFile := self repositoryRootPath / aProjectModification after repoPath / '.cypress' ].
	^ STON fromStream: (ZnBufferedReadStream on: propertiesFile  readStream)
]

{ #category : 'actions' }
RwModificationWriterVisitor >> addedClass: aClassModification [

	currentClassDefinition := aClassModification after.

	self processClass: aClassModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> addedClassExtension: aClassExtensionModification [

	currentClassExtension := aClassExtensionModification after.

	self processClassExtension: aClassExtensionModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> addedPackage: aPackageModification [

	currentPackageDefinition := aPackageModification after.
	self processPackage: aPackageModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> addedProject: aProjectModification [
	currentProjectDefinition := aProjectModification after.
	self repositoryRootPath ifNil: [ self repositoryRootPath: currentProjectDefinition repositoryRootPath ].
	self processProject: aProjectModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> changedClass: aClassModification [

	currentClassDefinition := aClassModification after.

	self processClass: aClassModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> changedClassExtension: aClassExtensionModification [

	currentClassExtension := aClassExtensionModification after.

	self processClassExtension: aClassExtensionModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> changedPackage: aPackageModification [

	currentPackageDefinition := aPackageModification after.
	self processPackage: aPackageModification
]

{ #category : 'actions' }
RwModificationWriterVisitor >> changedProject: aProjectModification [

	currentProjectDefinition := aProjectModification after.
	self repositoryRootPath ifNil: [ self repositoryRootPath: currentProjectDefinition repositoryRootPath ].
self halt.
]

{ #category : 'accessing' }
RwModificationWriterVisitor >> currentClassDefinition [

	^ currentClassDefinition
]

{ #category : 'accessing' }
RwModificationWriterVisitor >> currentClassExtension [

	^ currentClassExtension
]

{ #category : 'accessing' }
RwModificationWriterVisitor >> currentPackageDefinition [

	^ currentPackageDefinition
]

{ #category : 'accessing' }
RwModificationWriterVisitor >> currentProjectDefinition [

	^ currentProjectDefinition
]

{ #category : 'actions' }
RwModificationWriterVisitor >> deletedClass: aClassModification [

	currentClassDefinition := aClassModification after.

	self halt. "delete the class file"
]

{ #category : 'actions' }
RwModificationWriterVisitor >> deletedClassExtension: aClassExtensionModification [

	currentClassExtension := aClassExtensionModification after.


	self halt. "delete the class extension file"
]

{ #category : 'actions' }
RwModificationWriterVisitor >> deletedPackage: aPackageModification [

	self subclassResponsibility: #deletedPackage:
]

{ #category : 'actions' }
RwModificationWriterVisitor >> deletedProject: aProjectModification [

	"A deleted project means that the project was not inlcuded in the base project set definition ... we do not want to change anything on disk.
		So ignore the rest of the project"
]

{ #category : 'exporting' }
RwModificationWriterVisitor >> export [

	"noop ... directory-based formats written out as each element is visited"
]

{ #category : 'class writing' }
RwModificationWriterVisitor >> processClass: aClassModification [

	self subclassResponsibility: #processClass:
]

{ #category : 'class writing' }
RwModificationWriterVisitor >> processClassExtension: aClassExtensionModification [

	self subclassResponsibility: #processClassExtension:
]

{ #category : 'package writing' }
RwModificationWriterVisitor >> processPackage: aPackageModification [

	aPackageModification classesModification acceptVisitor: self.
	aPackageModification classExtensionsModification acceptVisitor: self
]

{ #category : 'project writing' }
RwModificationWriterVisitor >> processProject: aProjectModification [
 
	aProjectModification packagesModification acceptVisitor: self
]

{ #category : 'accessing' }
RwModificationWriterVisitor >> repositoryRootPath [

	^ repositoryRootPath
]

{ #category : 'accessing' }
RwModificationWriterVisitor >> repositoryRootPath: aStringOrFileReference [

	repositoryRootPath := aStringOrFileReference asFileReference.
	repositoryRootPath exists ifFalse: [ self error: 'The repository root path must exist: ', repositoryRootPath pathString printString ]
]

{ #category : 'public' }
RwModificationWriterVisitor >> visit: aPackageSetModification [

	aPackageSetModification acceptVisitor: self.
	self export.
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitClassesModification: aClassesModification [

	aClassesModification elementsModified
		do: [:each | each acceptVisitor: self]
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitClassExtensionModification: aClassExtensionModification [

	aClassExtensionModification isAddition
		ifTrue: [ ^ self addedClassExtension: aClassExtensionModification ] .
	aClassExtensionModification isDeletion
		ifTrue: [ ^ self deletedClassExtension: aClassExtensionModification ].
	^ self changedClassExtension: aClassExtensionModification
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitClassExtensionsModification: aClassExtensionsModification [

	aClassExtensionsModification elementsModified
		do: [ :each | each acceptVisitor: self ]
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitClassModification: aClassModification [

	aClassModification isAddition
		ifTrue: [ ^ self addedClass: aClassModification ] .
	aClassModification isDeletion
		ifTrue: [ ^ self deletedClass: aClassModification ].
	^ self changedClass: aClassModification
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitPackageModification: aPackageModification [

	aPackageModification isAddition
		ifTrue: [ ^ self addedPackage: aPackageModification ] .
	aPackageModification isDeletion
		ifTrue: [ ^ self deletedPackage: aPackageModification ].
	^ self changedPackage: aPackageModification
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitPackagesModification: aPackagesModification [

	aPackagesModification elementsModified do: [ :each | each acceptVisitor: self ]
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitProjecteSetModification: aProjectSetModification [

	aProjectSetModification elementsModified
		do: [ :each | each acceptVisitor: self ]
]

{ #category : 'visiting' }
RwModificationWriterVisitor >> visitProjectModification: aProjectModification [

	| propertiesModification |
	aProjectModification isAddition
		ifTrue: [ ^ self addedProject: aProjectModification ].
	aProjectModification isDeletion
		ifTrue: [ ^ self deletedProject: aProjectModification ].
	^ self changedProject: aProjectModification
]