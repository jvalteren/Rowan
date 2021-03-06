"
Represents modifications to a single class definition or class extension.

Instvars:

propertiesModification			PropertiesModification -- changes to class or class extension properties
instanceMethodsModification	MethodsModification -- changes to instance methods defined
classMethodsModification		MethodsModification -- changes to class methods defined
"
Class {
	#name : 'RwClassModification',
	#superclass : 'RwModification',
	#instVars : [
		'instanceMethodsModification',
		'classMethodsModification'
	],
	#category : 'Rowan-Core'
}

{ #category : 'visiting' }
RwClassModification >> acceptVisitor: aVisitor [

	^aVisitor visitClassModification: self
]

{ #category : 'Accessing' }
RwClassModification >> classMethodsModification [
	^classMethodsModification

]

{ #category : 'Updating' }
RwClassModification >> classMethodsModification: newValue [
	classMethodsModification := newValue

]

{ #category : 'initialization' }
RwClassModification >> initialize [
	"Dummy initialization that understands isEmpty for printing."

	super initialize.
	instanceMethodsModification := #().
	classMethodsModification := #()
]

{ #category : 'Accessing' }
RwClassModification >> instanceMethodsModification [
	^instanceMethodsModification

]

{ #category : 'Updating' }
RwClassModification >> instanceMethodsModification: newValue [
	instanceMethodsModification := newValue

]

{ #category : 'testing' }
RwClassModification >> isEmpty [

	^super isEmpty & instanceMethodsModification isEmpty
		& classMethodsModification isEmpty
]

{ #category : 'merging' }
RwClassModification >> mergeForExistingClassWith: anExistingClassModification [

	"merge aClassModification modifictions into the receiver"

	anExistingClassModification propertiesModification isEmpty
		ifFalse: [
			self propertiesModification isEmpty
				ifFalse: ["the properties modification for the receiver can be safely ignored" ].
			propertiesModification := anExistingClassModification propertiesModification copy ].
	instanceMethodsModification
		mergeForExistingClassWith: anExistingClassModification instanceMethodsModification.
	classMethodsModification
		mergeForExistingClassWith: anExistingClassModification classMethodsModification.
	after := anExistingClassModification after

]

{ #category : 'merging' }
RwClassModification >> mergeForNewClassVersionWith: aClassModification [

	"merge aClassModification modifictions into the receiver"

	aClassModification propertiesModification isEmpty
		ifFalse: [ 
			self
				error:
					'internal error - an incoming class modification is not expected to have properties when a new class version is involved' ].
	instanceMethodsModification
		mergeForNewClassVersionWith: aClassModification instanceMethodsModification.
	classMethodsModification
		mergeForNewClassVersionWith: aClassModification classMethodsModification

]
