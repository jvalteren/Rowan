"
ParseTreeSearcher walks over a normal source code parse tree using the visitor pattern, and then matches these nodes against the meta-nodes using the match:inContext: methods defined for the meta-nodes.

Instance Variables:
	answer	<Object>	the ""answer"" that is propagated between matches
	argumentSearches	<Collection of: (Association key: RBProgramNode value: BlockClosure)>	argument searches (search for the BRProgramNode and perform the BlockClosure when its found)
	context	<RBSmallDictionary>	a dictionary that contains what each meta-node matches against. This could be a normal Dictionary that is created for each search, but is created once and reused (efficiency).
	messages	<Collection>	the sent messages in our searches
	searches	<Collection of: (Association key: RBProgramNode value: BlockClosure)>	non-argument searches (search for the BRProgramNode and perform the BlockClosure when its found)
"
Class {
	#name : 'RBParseTreeSearcher',
	#superclass : 'RBProgramNodeVisitor',
	#instVars : [
		'searches',
		'answer',
		'argumentSearches',
		'context',
		'messages'
	],
	#category : 'AST-Core-Matching'
}

{ #category : 'private' }
RBParseTreeSearcher class >> buildSelectorString: aSelector [ 
	| stream keywords |
	aSelector numArgs = 0 ifTrue: [^aSelector].
	stream := WriteStreamPortable on: String new.
	keywords := aSelector keywords.
	1 to: keywords size
		do: 
			[:i | 
			stream
				nextPutAll: (keywords at: i);
				nextPutAll: ' ``@arg';
				nextPutAll: i printString;
				nextPut: $ ].
	^stream contents
]

{ #category : 'private' }
RBParseTreeSearcher class >> buildSelectorTree: aSelector [ 
	aSelector isEmpty ifTrue: [^nil].
	^RBParser parseRewriteExpression: '``@receiver ' 
				, (self buildSelectorString: aSelector)
		onError: [:err :pos | ^nil]
]

{ #category : 'private' }
RBParseTreeSearcher class >> buildTree: aString method: aBoolean [ 
	^aBoolean 
		ifTrue: [RBParser parseRewriteMethod: aString]
		ifFalse: [RBParser parseRewriteExpression: aString]
]

{ #category : 'instance creation' }
RBParseTreeSearcher class >> getterMethod: aVarName [ 
	^(self new)
		matchesMethod: '`method ^' , aVarName do: [:aNode :ans | aNode selector];
		yourself
]

{ #category : 'instance creation' }
RBParseTreeSearcher class >> justSendsSuper [
	^ self new
		matchesAnyMethodOf: #(
			'`@method: `@args ^ super `@method: `@args' 
			'`@method: `@args super `@method: `@args')
		do: [ :node :answer | true ];
		yourself
]

{ #category : 'instance creation' }
RBParseTreeSearcher class >> returnSetterMethod: aVarName [ 
	^(self new)
		matchesMethod: '`method: `Arg ^' , aVarName , ' := `Arg'
			do: [:aNode :ans | aNode selector];
		yourself
]

{ #category : 'instance creation' }
RBParseTreeSearcher class >> setterMethod: aVarName [ 
	^(self new)
		matchesAnyMethodOf: (Array with: '`method: `Arg ' , aVarName , ' := `Arg'
					with: '`method: `Arg ^' , aVarName , ' := `Arg')
			do: [:aNode :ans | aNode selector];
		yourself
]

{ #category : 'accessing' }
RBParseTreeSearcher class >> treeMatching: aString in: aParseTree [ 
	(self new)
		matches: aString do: [:aNode :answer | ^aNode];
		executeTree: aParseTree.
	^nil
]

{ #category : 'accessing' }
RBParseTreeSearcher class >> treeMatchingStatements: aString in: aParseTree [ 
	| notifier tree |
	notifier := self new.
	tree := RBParser parseExpression: aString.
	tree isSequence 
		ifFalse: [tree := RBSequenceNode statements: (Array with: tree)].
	tree temporaries: (Array with: (RBPatternVariableNode named: '`@temps')).
	tree addNodeFirst: (RBPatternVariableNode named: '`@.S1').
	tree lastIsReturn 
		ifFalse: [tree addNode: (RBPatternVariableNode named: '`@.S2')].
	notifier matchesTree: tree
		do: [:aNode :answer | ^RBParser parseExpression: aString].
	notifier executeTree: aParseTree.
	^nil
]

{ #category : 'accessing' }
RBParseTreeSearcher >> addArgumentRule: aParseTreeRule [ 
	argumentSearches add: aParseTreeRule.
	aParseTreeRule owner: self
]

{ #category : 'accessing' }
RBParseTreeSearcher >> addArgumentRules: ruleCollection [ 
	ruleCollection do: [:each | self addArgumentRule: each]
]

{ #category : 'accessing' }
RBParseTreeSearcher >> addRule: aParseTreeRule [ 
	searches add: aParseTreeRule.
	aParseTreeRule owner: self
]

{ #category : 'accessing' }
RBParseTreeSearcher >> addRules: ruleCollection [ 
	ruleCollection do: [:each | self addRule: each]
]

{ #category : 'accessing' }
RBParseTreeSearcher >> answer [
	^answer
]

{ #category : 'initialize-release' }
RBParseTreeSearcher >> answer: anObject [
	answer := anObject
]

{ #category : 'testing' }
RBParseTreeSearcher >> canMatchMethod: aCompiledMethod [
	| actualMessages |
	self messages isEmpty
		ifTrue: [ ^ true ].
	actualMessages := aCompiledMethod messages.
	^ self messages 
		anySatisfy: [ :each | actualMessages includes: each ]
]

{ #category : 'accessing' }
RBParseTreeSearcher >> context [
	^context
]

{ #category : 'accessing' }
RBParseTreeSearcher >> executeMethod: aParseTree initialAnswer: anObject [ 
	answer := anObject.
	searches detect: [:each | (each performOn: aParseTree) notNil] ifNone: [].
	^answer
]

{ #category : 'accessing' }
RBParseTreeSearcher >> executeTree: aParseTree [ 
	"Save our current context, in case someone is performing another search inside a match."

	| oldContext |
	oldContext := context.
	context := RBSmallDictionary new.
	self visitNode: aParseTree.
	context := oldContext.
	^answer
]

{ #category : 'accessing' }
RBParseTreeSearcher >> executeTree: aParseTree initialAnswer: aValue [ 
	answer := aValue.
	^self executeTree: aParseTree
]

{ #category : 'private' }
RBParseTreeSearcher >> foundMatch [
]

{ #category : 'testing' }
RBParseTreeSearcher >> hasRules [
	^searches notEmpty
]

{ #category : 'initialize-release' }
RBParseTreeSearcher >> initialize [
	super initialize.
	context := RBSmallDictionary new.
	searches := OrderedCollection new.
	argumentSearches := OrderedCollection new: 0.
	answer := nil
]

{ #category : 'private' }
RBParseTreeSearcher >> lookForMoreMatchesInContext: oldContext [ 
	oldContext keysAndValuesDo: 
			[:key :value | 
			(key isString not and: [key recurseInto]) 
				ifTrue: [value do: [:each | self visitNode: each]]]
]

{ #category : 'searching' }
RBParseTreeSearcher >> matches: aString do: aBlock [ 
	self addRule: (RBSearchRule searchFor: aString thenDo: aBlock)
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesAnyArgumentOf: stringCollection do: aBlock [ 
	stringCollection do: [:each | self matchesArgument: each do: aBlock]
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesAnyMethodOf: aStringCollection do: aBlock [ 
	aStringCollection do: [:each | self matchesMethod: each do: aBlock]
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesAnyOf: aStringCollection do: aBlock [ 
	aStringCollection do: [:each | self matches: each do: aBlock]
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesAnyTreeOf: treeCollection do: aBlock [ 
	treeCollection do: [:each | self matchesTree: each do: aBlock]
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesArgument: aString do: aBlock [ 
	self addArgumentRule: (RBSearchRule searchFor: aString thenDo: aBlock)
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesArgumentTree: aBRProgramNode do: aBlock [ 
	self 
		addArgumentRule: (RBSearchRule searchForTree: aBRProgramNode thenDo: aBlock)
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesMethod: aString do: aBlock [ 
	self addRule: (RBSearchRule searchForMethod: aString thenDo: aBlock)
]

{ #category : 'searching' }
RBParseTreeSearcher >> matchesTree: aBRProgramNode do: aBlock [ 
	self addRule: (RBSearchRule searchForTree: aBRProgramNode thenDo: aBlock)
]

{ #category : 'accessing' }
RBParseTreeSearcher >> messages [
	messages notNil ifTrue: [^messages].
	argumentSearches notEmpty ifTrue: [^messages := #()].
	messages := Set new.
	searches do: 
			[:each | 
			| searchMessages |
			searchMessages := each sentMessages.
			RBProgramNode optimizedSelectors 
				do: [:sel | searchMessages remove: sel ifAbsent: []].
			searchMessages isEmpty ifTrue: [^messages := #()].
			messages addAll: searchMessages].
	^messages := messages asArray
]

{ #category : 'private' }
RBParseTreeSearcher >> performSearches: aSearchCollection on: aNode [ 
	| value |
	1 to: aSearchCollection size
		do: 
			[:i | 
			value := (aSearchCollection at: i) performOn: aNode.
			value notNil 
				ifTrue: 
					[self foundMatch.
					^value]].
	^nil
]

{ #category : 'private' }
RBParseTreeSearcher >> recusivelySearchInContext [
	"We need to save the matched context since the other searches might overwrite it."

	| oldContext |
	oldContext := context.
	context := RBSmallDictionary new.
	self lookForMoreMatchesInContext: oldContext.
	context := oldContext
]

{ #category : 'visiting' }
RBParseTreeSearcher >> visitArgument: aNode [ 
	| value |
	value := self performSearches: argumentSearches on: aNode.
	^value isNil 
		ifTrue: 
			[aNode acceptVisitor: self.
			aNode]
		ifFalse: [value]
]

{ #category : 'visiting' }
RBParseTreeSearcher >> visitNode: aNode [ 
	| value |
	value := self performSearches: searches on: aNode.
	^value isNil 
		ifTrue: 
			[aNode acceptVisitor: self.
			aNode]
		ifFalse: [value]
]
