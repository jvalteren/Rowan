"
A RBLiteralArrayNode is an AST node that represents literal arrays and literal byte arrays.

Instance Variables
	contents: <Array of: RBLiteralNode> literal nodes of the array
	isByteArray: <Boolean> if the receiver is a literal byte array
	start: <Integer | nil> source position of #( or #[
	stop: <Integer | nil> source position of ) or ]
"
Class {
	#name : 'RBLiteralArrayNode',
	#superclass : 'RBLiteralNode',
	#instVars : [
		'isByteArray',
		'stop',
		'contents',
		'start'
	],
	#category : 'AST-Core-Nodes'
}

{ #category : 'instance creation' }
RBLiteralArrayNode class >> startPosition: startInteger contents: anArray stopPosition: stopInteger isByteArray: aBoolean [ 
	^(self new)
		startPosition: startInteger
			contents: anArray
			stopPosition: stopInteger
			isByteArray: aBoolean;
		yourself
]

{ #category : 'instance creation' }
RBLiteralArrayNode class >> value: aValue [ 
	^(self new)
		startPosition: nil
			contents: (aValue asArray collect: [:each | RBLiteralNode value: each])
			stopPosition: nil
			isByteArray: aValue class ~~ Array;
		yourself
]

{ #category : 'comparing' }
RBLiteralArrayNode >> = anObject [ 
	super = anObject ifFalse: [^false].
	self isForByteArray = anObject isForByteArray ifFalse: [^false].
	self contents size = anObject contents size ifFalse: [^false].
	1 to: self contents size
		do: [:i | (self contents at: i) = (anObject contents at: i) ifFalse: [^false]].
	^true
]

{ #category : 'visitor' }
RBLiteralArrayNode >> acceptVisitor: aProgramNodeVisitor [ 
	^aProgramNodeVisitor acceptLiteralArrayNode: self
]

{ #category : 'accessing' }
RBLiteralArrayNode >> children [
	^contents
]

{ #category : 'accessing' }
RBLiteralArrayNode >> contents [
	^contents
]

{ #category : 'initialize-release' }
RBLiteralArrayNode >> contents: aRBLiteralNodeCollection [ 
	contents := aRBLiteralNodeCollection.
	contents do: [:each | each parent: self]
]

{ #category : 'matching' }
RBLiteralArrayNode >> copyInContext: aDictionary [ 
	^ self class 
		startPosition: nil
		contents: (self copyList: self contents inContext: aDictionary)
		stopPosition: nil
		isByteArray: isByteArray
]

{ #category : 'comparing' }
RBLiteralArrayNode >> equalTo: anObject withMapping: aDictionary [ 
	self class = anObject class ifFalse: [^false].
	self isForByteArray = anObject isForByteArray ifFalse: [^false].
	self contents size = anObject contents size ifFalse: [^false].
	1 to: self contents size
		do: 
			[:i | 
			((self contents at: i) equalTo: (anObject contents at: i)
				withMapping: aDictionary) ifFalse: [^false]].
	^true
]

{ #category : 'testing' }
RBLiteralArrayNode >> isForByteArray [
	^isByteArray
]

{ #category : 'testing' }
RBLiteralArrayNode >> isLiteralArray [
	^true
]

{ #category : 'matching' }
RBLiteralArrayNode >> match: aNode inContext: aDictionary [ 
	aNode class = self class ifFalse: [^false].
	self isForByteArray = aNode isForByteArray ifFalse: [^false].
	^self 
		matchList: contents
		against: aNode contents
		inContext: aDictionary
]

{ #category : 'copying' }
RBLiteralArrayNode >> postCopy [
	super postCopy.
	self contents: (self contents collect: [ :each | each copy ])
]

{ #category : 'replacing' }
RBLiteralArrayNode >> replaceNode: aNode withNode: anotherNode [ 
	self contents: (contents 
				collect: [:each | each == aNode ifTrue: [anotherNode] ifFalse: [each]])
]

{ #category : 'private-replacing' }
RBLiteralArrayNode >> replaceSourceWith: aNode [ 
	(self class = aNode class and: 
			[self isForByteArray = aNode isForByteArray 
				and: [self contents size = aNode contents size]]) 
		ifFalse: [^super replaceSourceWith: aNode].
	1 to: self contents size
		do: 
			[:i | 
			(self contents at: i) = (aNode contents at: i) 
				ifFalse: [(self contents at: i) replaceSourceWith: (aNode contents at: i)]]
]

{ #category : 'initialize-release' }
RBLiteralArrayNode >> startPosition: startInteger contents: anArray stopPosition: stopInteger isByteArray: aBoolean [ 
	start := startInteger.
	self contents: anArray.
	stop := stopInteger.
	isByteArray := aBoolean
]

{ #category : 'accessing' }
RBLiteralArrayNode >> startWithoutParentheses [
	^start
]

{ #category : 'accessing' }
RBLiteralArrayNode >> stopWithoutParentheses [
	^stop
]

{ #category : 'accessing' }
RBLiteralArrayNode >> value [
	| array |
	array := (isByteArray ifTrue: [ByteArray] ifFalse: [Array]) 
				new: contents size.
	1 to: contents size
		do: [:each | array at: each put: (contents at: each) value].
	^array
]
