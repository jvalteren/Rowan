Class {
	#name : 'RowanQueryService',
	#superclass : 'RowanService',
	#instVars : [
		'queryResults'
	],
	#category : 'Rowan-Services-Core'
}

{ #category : 'ston' }
RowanQueryService >> excludedInstVars [

	^#(#organizer)

]

{ #category : 'queries' }
RowanQueryService >> hierarchyImplementorsOf: selector inClass: className [

	| methods behavior classes |
	behavior := Rowan globalNamed: className.
	classes := behavior allSuperclasses. 
	classes add: behavior. 
	classes addAll: (organizer subclassesOf: behavior). 
	methods := organizer implementorsOf: selector in: classes.
	queryResults := self methodServicesFrom: methods.
	RowanCommandResult addResult: self.

]

{ #category : 'queries' }
RowanQueryService >> hierarchySendersOf: selector inClass: className [

	| methods behavior classes |
	behavior := Rowan globalNamed: className.
	classes := behavior allSuperclasses. 
	classes add: behavior. 
	classes addAll: (organizer subclassesOf: behavior). 
	methods := organizer sendersOf: selector in: classes.
	queryResults := self methodServicesFrom: methods first.
	RowanCommandResult addResult: self.

]

{ #category : 'queries' }
RowanQueryService >> implementorsOf: selector [

	| methods |
	methods := organizer implementorsOf: selector.
	queryResults := self methodServicesFrom: methods.
	RowanCommandResult addResult: self.

]

{ #category : 'queries' }
RowanQueryService >> methodsContaining: string [

	| methods |
	methods := organizer substringSearch: string.
	queryResults := self methodServicesFrom: methods first.
	RowanCommandResult addResult: self.

]

{ #category : 'queries' }
RowanQueryService >> methodServicesFrom: methods [

	| sorted | 
	sorted := SortedCollection sortBlock: [:x :y | x className = y className ifTrue:[x selector < y selector] ifFalse:[x className < y className]].
	sorted addAll: (methods collect:[:gsNMethod | 
			RowanMethodService forSelector: gsNMethod selector class: gsNMethod inClass thisClass meta: gsNMethod inClass isMeta organizer: organizer]).
	^sorted asArray

]

{ #category : 'queries' }
RowanQueryService >> sendersOf: selector [

	| methods |
	methods := organizer sendersOf: selector.
	queryResults := self methodServicesFrom: methods first.
	RowanCommandResult addResult: self.

]

{ #category : 'ston' }
RowanQueryService >> stonOn: stonWriter [   
	| instanceVariableNames |
	instanceVariableNames := self class allInstVarNames reject: [:iv | self excludedInstVars includes: iv].
	stonWriter writeObject: self
		streamMap: 
			[:dictionary |
			instanceVariableNames do: 
					[:each |
					(self instVarAt: (self class allInstVarNames indexOf: each asSymbol))
						ifNotNil: [:value | dictionary at: each asSymbol put: value]
						ifNil: [self stonShouldWriteNilInstVars ifTrue: [dictionary at: each asSymbol put: nil]]]]
]