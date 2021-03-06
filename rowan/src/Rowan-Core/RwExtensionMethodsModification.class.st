Class {
	#name : 'RwExtensionMethodsModification',
	#superclass : 'RwMethodsModification',
	#instVars : [
		'extendedClassName'
	],
	#category : 'Rowan-Core'
}

{ #category : 'instance creation' }
RwExtensionMethodsModification class >> extendedClassName: aString [

	^ self new
		extendedClassName: aString;
		yourself
]

{ #category : 'visiting' }
RwExtensionMethodsModification >> acceptVisitor: aVisitor [

	^ aVisitor visitExtensionMethodsModification: self
]

{ #category : 'modifications' }
RwExtensionMethodsModification >> addElementModification: aModification [

	aModification isEmpty
		ifFalse: [ 
			| anExtensionModification |
			anExtensionModification := aModification asExtensionMethodModification.
			anExtensionModification extendedClassName: self extendedClassName.
			elementsModified at: anExtensionModification key put: anExtensionModification ]

]

{ #category : 'accessing' }
RwExtensionMethodsModification >> extendedClassName [

   ^extendedClassName

]

{ #category : 'accessing' }
RwExtensionMethodsModification >> extendedClassName: anObject [

	extendedClassName := anObject
]
