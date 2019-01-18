Class {
	#name : 'RwRepositoryComponentProjectReaderVisitor',
	#superclass : 'RwAbstractReaderWriterVisitor',
	#instVars : [
		'packageNames',
		'currentDirectory',
		'currentProjectDefinition',
		'currentProjectReferenceDefinition'
	],
	#category : 'Rowan-Components'
}

{ #category : 'private' }
RwRepositoryComponentProjectReaderVisitor >> _readObjectFrom: aFileReference [

	aFileReference readStreamDo: [:stream |
		^ STON fromStream: (ZnBufferedReadStream on:  stream) ]
]

{ #category : 'private' }
RwRepositoryComponentProjectReaderVisitor >> _repositoryPropertyDictFor: packagesRoot [

	^ self _readObjectFrom: packagesRoot / 'properties', 'st'
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> currentDirectory [

	^ currentDirectory
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> currentDirectory: aFileReference [

	currentDirectory := aFileReference
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> currentProjectDefinition [

	^ currentProjectDefinition
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> currentProjectDefinition: aRwComponentProjectDefinition [

	currentProjectDefinition := aRwComponentProjectDefinition
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> currentProjectReferenceDefinition [

	^ currentProjectReferenceDefinition
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> currentProjectReferenceDefinition: aRwProjectReferenceDefinition [

	currentProjectReferenceDefinition := aRwProjectReferenceDefinition
]

{ #category : 'tonel parser' }
RwRepositoryComponentProjectReaderVisitor >> newClassDefinitionFrom: anArray [
  | metadata classDef |
  metadata := anArray sixth.
  classDef := RwClassDefinition
		newForClassNamed: (metadata at: #'name') 
			super: (metadata at: #'superclass' ifAbsent: [metadata at: #'super']) 
			instvars: (metadata at: #'instvars' ifAbsent: [ #() ]) 
			classinstvars: (metadata at: #'classinstvars' ifAbsent: [ #() ]) 
			classvars: (metadata at: #'classvars' ifAbsent: [ #() ]) 
			category: (metadata at: #'category' ifAbsent: [ ])
			comment: (anArray second ifNil: [ '' ]) 
			pools: (metadata at: #'pools' ifAbsent: [ #() ]) 
			type: (metadata at: #'type' ifAbsent: [ #'normal' ]) asSymbol.
	^ classDef
		gs_options: (metadata at: #'gs_options' ifAbsent: [ #() ]);
		gs_constraints: (metadata at: #'gs_constraints' ifAbsent: [ #() ]);
		yourself
]

{ #category : 'package reading' }
RwRepositoryComponentProjectReaderVisitor >> packageExtension [

	^ self subclassResponsibility: #packageExtension
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
RwRepositoryComponentProjectReaderVisitor >> packageNames: anArray [

	packageNames := anArray
]

{ #category : 'class reading' }
RwRepositoryComponentProjectReaderVisitor >> readClassesFor: packageName packageRoot: packageRoot [

	^ self subclassResponsibility: #readClassesFor:packageRoot:
]

{ #category : 'package reading' }
RwRepositoryComponentProjectReaderVisitor >> readPackages: packagesRoot [
	packagesRoot directories do: [:packageDir |
		(packageDir extension = self packageExtension and: [ self packageNames includes: packageDir basenameWithoutExtension])
			ifTrue: [ self readClassesFor: packageDir basenameWithoutExtension packageRoot: packageDir ] ]
]

{ #category : 'public' }
RwRepositoryComponentProjectReaderVisitor >> visit: anObject [

	anObject acceptVisitor: self.
]

{ #category : 'visiting' }
RwRepositoryComponentProjectReaderVisitor >> visitComponentProjectDefinition: aRwComponentProjectDefinition [

	self currentProjectDefinition: aRwComponentProjectDefinition.
	aRwComponentProjectDefinition packages: Dictionary new.
	self visit: aRwComponentProjectDefinition projectRef
]

{ #category : 'visiting' }
RwRepositoryComponentProjectReaderVisitor >> visitProjectReferenceDefinition: aRwProjectReferenceDefinition [
	"read the packageNames from the repository"

	self currentProjectReferenceDefinition: aRwProjectReferenceDefinition.
	self readPackages: aRwProjectReferenceDefinition packagesRoot
]