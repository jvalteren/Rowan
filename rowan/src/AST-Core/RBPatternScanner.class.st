"
RBPatternScanner is a subclass of RBScanner that allows the extended syntax of pattern matching trees.

"
Class {
	#name : 'RBPatternScanner',
	#superclass : 'RBScanner',
	#category : 'AST-Core-Parser'
}

{ #category : 'class initialization' }
RBPatternScanner class >> initialize [
  "force initialization on load"

  "self initialize"

  super initialize
]

{ #category : 'accessing' }
RBPatternScanner >> scanToken [
	currentCharacter = PatternVariableCharacter 
		ifTrue: [^self scanPatternVariable].
	currentCharacter = $} ifTrue: [^self scanSpecialCharacter].
	^super scanToken
]
