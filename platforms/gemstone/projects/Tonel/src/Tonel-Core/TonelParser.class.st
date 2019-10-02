"
I'm a parser for tonel files. 
I parse a class with the following format: 

Tonel spec
====

    [comment]
    type { typeDefinition }
    (
        [{ methodMetadata }]
        method [
            methodBody ] 
    )*


comment
---
""
comment string
""
is optional (but it should be there, in good design ;)

type
---
Class|Trait|Extension

typeDefinition
---
a STON file with class/trait/extension metadata

methodMetadata
---
a STON file with method metadata
is optional (but also, recommended)

method
---
method declaration as this: 

Class[ class] >> selector

methodBody 
---
the method body (we do not parse contents, that's class builder task)
"
Class {
	#name : 'TonelParser',
	#superclass : 'Object',
	#instVars : [
		'packageReader',
		'stream',
		'lastSelectorParsed'
	],
	#category : 'Tonel-Core'
}

{ #category : 'Topaz support' }
TonelParser class >> _compileForTopaz: aString envId: envId [
  "aString is the topaz text object for topaz TMETHOD command"
| strm parser catDict category methInfo methSrc symList clsName cls
  warnStr  |
strm :=  ReadStreamPortable on: aString  .
(parser := self new) stream: strm .

parser separator ifNotNil:[ Error signal:'expected parser separator to be nil'].

catDict :=  (parser try: [ parser metadata ]).
catDict ifNil:[ Error signal:'Category dictionary not found'. ].
category := catDict at: #category .

parser separator ifNotNil:[ Error signal:'expected second parser separator to be nil'].

methInfo :=  parser method.
clsName := Symbol _existingWithAll: ((methInfo at: 1) at: 1) .

methSrc :=  (methInfo at: 2)"keywords+args" ,  parser methodBody .
symList := System myUserProfile symbolList .
cls := (symList resolveSymbol: clsName) value .
((methInfo at: 1) at: 2) ifNotNil:[:classWord |
  classWord = 'class' ifTrue:[ cls := cls class ]
      ifFalse:[ Error signal:'unrecognized ' , classWord asString, ' after >>'].
].
[ cls compileMethod: methSrc dictionaries: symList 
               category: category  
               environmentId: envId .
] on: CompileWarning do:[:ex | 
   warnStr := ex warningString .
   ex resume 
].
^ warnStr "nil if no warnings"

]

{ #category : 'instance creation' }
TonelParser class >> on: aStream forReader: aTonelReader [
	^ self new 
		stream: aStream;
		packageReader: aTonelReader;
		yourself

]

{ #category : 'instance creation' }
TonelParser class >> onString: aString forReader: aTonelReader [
  ^ self on: (self readStreamClass on: aString) forReader: aTonelReader

]

{ #category : 'parsing' }
TonelParser class >> parseStream: aStream forReader: aTonelReader [
	^ (self on: aStream forReader: aTonelReader)
		 start

]

{ #category : 'parsing' }
TonelParser class >> parseString: aString forReader: aTonelReader [
	^ self parseStream: (self readStreamClass on: aString) forReader: aTonelReader

]

{ #category : 'private' }
TonelParser >> cleanSelector: aString [
	"BEWARE: I'm doing some heave assumptions here: I'm removing just ONE space (in case there 
	 is one) because I expect this to be a file generated by tonel, and tonel adds one space 
	 before start with the method body to make the format more readable. 
	 But of course this is not very good :("
	^ (aString last = Character space
		ifTrue: [ aString allButLast ]
		ifFalse: [ aString ]) 
		trimLeft

]

{ #category : 'parsing' }
TonelParser >> comment [
	| result ch eatNext |
	
	result := String new writeStreamPortable.

	eatNext := false.
	stream next = $" ifFalse: [ TonelParseError signal: 'Can''t parse comment' ].	
	[ stream atEnd not 
		and: [ 
				(ch := stream next) ~= $" 
				or: [ eatNext := (stream peek = $") ] ] ]
	whileTrue: [ 
		result nextPut: ch.
		eatNext ifTrue: [ 
			stream skip: 1.
			eatNext := false ] ].
	
	^ self 
		removeFrom: '"',result contents,'"' 
		enclosingStart: $" 
		end: $"

]

{ #category : 'private factory' }
TonelParser >> definitionForType: aString [
  ^ self packageReader definitionForType: aString

]

{ #category : 'parsing' }
TonelParser >> document [
	^ { 
	self typeDef.
	self methodDefList.
	 } 
	select: [:each | each notNil ]

]

{ #category : 'private' }
TonelParser >> extractSelector: aString [
	| separators selectorStream keywords |
	
	separators := { 
		Character space. 
		Character tab. 
		Character lf. 
		Character newPage. 
		Character cr. 
		$:}.

	keywords := Array new writeStreamPortable.
	selectorStream := aString readStream.
	[ selectorStream atEnd ]
	whileFalse: [ | word ch |
		word := String new writeStreamPortable.
		[ selectorStream atEnd not and: [ (separators includes: (ch := selectorStream next)) not ] ]
		whileTrue: [ word nextPut: ch ].
		ch = $: ifTrue: [ word nextPut: ch ]. 
		word contents trimBoth ifNotEmpty: [ :v | keywords nextPut: v ] ].
	keywords := keywords contents.

	^ (keywords size <= 2 
		ifTrue: [ keywords first]
		ifFalse: [ ('' join: (keywords pairsCollect: [ :keyword :argument | keyword ])) ])
		asSymbol

]

{ #category : 'testing' }
TonelParser >> isEnter: aCharacter [
	^ #(13 10) includes: aCharacter asciiValue

]

{ #category : 'testing' }
TonelParser >> isSeparator: aCharacter [ 
	^ aCharacter isSeparator

]

{ #category : 'parsing' }
TonelParser >> metadata [
	| result ch count |
	
	result := String new writeStreamPortable.

	count := 0.
	stream peek = ${ ifFalse: [ TonelParseError signal: 'Can''t parse metadata' ].	
	[ stream atEnd not ]
	whileTrue: [ 
		ch := stream next.
		result nextPut: ch.
		ch = ${ ifTrue: [ count := count +1 ].
		ch = $} ifTrue: [ count := count -1 ].
		count = 0 ifTrue: [ ^ STON fromString: result contents ]].

	TonelParseError signal: 'Can''t parse metadata'

]

{ #category : 'parsing' }
TonelParser >> method [
	| type selector |
	
	type := self untilIncluding: '>>'.
	selector := self cleanSelector: (self untilExcluding: '[').
	type := type trimBoth substrings: ' '.
	type size = 1 ifTrue: [ type := type copyWith: nil ].
  lastSelectorParsed := selector .
	^ { 
		type.
		selector.
	}

]

{ #category : 'parsing' }
TonelParser >> methodBody [
	"I read a methodbody (what is inside [ ... ])
	 Since a method body can contain enclosing brackets we need to be sure we will skip them and
	 correctly read the method. For that, I have to take into account: 
		- I can mention [] in comments
		- I can mention [] in strings
		- I can use $[, $] 
		- I can have inner blocks
		- I can mention a comment of the form ""$"" or a comment of the form '$'
	 all that needs to be skipped "
	| result char prevChar comment string count startPos |
	
	result := self class writeStreamClass on: String new.

	comment := false.
	string := false.
	prevChar := nil.
	count := 0.
        startPos := stream position .
        "startBody := stream peek: 300 ." "uncomment for debugging parse problems"
	stream peek = $[ ifFalse: [ TonelParseError signal: 'Can''t parse method body' ].
	[ stream atEnd not ]
	whileTrue: [ 
		char := stream next.
		result nextPut: char.
		(char = $" and: [ string not and: [ prevChar ~= $$ or: [ comment ] ] ]) 
			ifTrue: [ comment := comment not ]. 
		(char = $' and: [ comment not and: [ prevChar ~= $$ or: [ string ] ] ]) 
			ifTrue: [ string := string not ]. 
		(comment or: [ string ]) ifFalse: [ 
			(char = $[ and: [  prevChar ~= $$ ]) ifTrue: [ count := count +1 ].
			(char = $] and: [ prevChar ~= $$ ]) ifTrue: [ count := count -1 ] ].
		count = 0 ifTrue: [ 
			^ self 
				removeFrom: result contents 
				enclosingStart: $[ 
				end: $]
				clean: #right ].
		prevChar := char ].

	TonelParseError signal: 'Can''t parse method body'

]

{ #category : 'parsing' }
TonelParser >> methodDef [
	"kept around for tests"

	| methodDef |
	self methodDef: [:isMeta :mDef |
		methodDef :=  mDef.
		"skip possible spaces at the end"
		self separator ].
	^methodDef

]

{ #category : 'parsing' }
TonelParser >> methodDef: aBlock [
	| ar def |
	ar := { 
		self separator.
		self try: [ self metadata ]. 
		self separator. 
		self method. 
		self methodBody 
	}.
	def := self newMethodDefinitionFrom: ar.
	aBlock 
		value: ar fourth first second notNil 
		value: def

]

{ #category : 'parsing' }
TonelParser >> methodDefList [
	| result classStream instanceStream |
	self separator. "to arrive to the end of the file in case there are no methods"
	result := { {}. {} }.
	classStream := (result at: 1) writeStreamPortable.
	instanceStream := (result at: 2) writeStreamPortable.
	[
		[ stream atEnd ]
			whileFalse: [ 
				self methodDef: [:isMeta :mDef |
					isMeta
						ifTrue: [ classStream nextPut: mDef ]
						ifFalse: [ instanceStream nextPut: mDef ].
					"skip possible spaces at the end"
					self separator ]
			] 
  ] on: TonelParseError do:[:ex | 
		lastSelectorParsed ifNotNil:[ | str |
      str := ex details ifNil:[ '' ].
      ex details: str, ', after tonel method selector: ', lastSelectorParsed printString 
    ].
		ex pass 
  ].
	^ result
]

{ #category : 'private factory' }
TonelParser >> newMethodDefinitionFrom: anArray [
	| metadata className meta selector source  |
	
	metadata := anArray second ifNil: [ Dictionary new ].
	className := anArray fourth first first.
	meta := anArray fourth first second notNil.
	selector := self extractSelector: anArray fourth second trimBoth.
	source := String streamContents: [ :s | 
		s << anArray fourth second.
		anArray fifth ifNotEmpty: [ :src | s << src ] ].

	^ self packageReader newMethodDefinitionForClassNamed: className
		classIsMeta: meta
		selector: selector
		category: (metadata at: #category ifAbsent: [ '' ]) 
		source: source

]

{ #category : 'private factory' }
TonelParser >> newTypeDefinitionFrom: anArray [
	^ self packageReader newTypeDefinitionFrom: anArray

]

{ #category : 'accessing' }
TonelParser >> packageReader [
	^ packageReader

]

{ #category : 'accessing' }
TonelParser >> packageReader: aPackageReader [ 
	packageReader := aPackageReader

]

{ #category : 'private' }
TonelParser >> removeFrom: aString enclosingStart: startChar end: endChar [
	^ self 
		removeFrom: aString 
		enclosingStart: startChar 
		end: endChar
		clean: #both

]

{ #category : 'private' }
TonelParser >> removeFrom: aString enclosingStart: startChar end: endChar clean: cleanSymbol [
  "cleanSymbol can be #left, #rigth and #both"

  | result stop ch start end |
  result := self class readStreamClass on: aString trimBoth.
  result peek = startChar
    ifFalse: [ TonelParseError signal: 'I cannot remove enclosing start' ].
  result skip: 1.
  (#(#'both' #'left') includes: cleanSymbol)
    ifTrue: [ 
      stop := TonelWriter lineEnding size.
      [ stop > 0 and: [ self isSeparator: (ch := result peek) ] ]
        whileTrue: [ 
          (self isEnter: ch)
            ifTrue: [ stop := stop - 1 ].
          result skip: 1 ] ].
  start := result position.
  result setToEnd.
  result skip: -1.
  result peek = endChar
    ifFalse: [ TonelParseError signal: 'I cannot remove enclosing end' ].
  result skip: -1.
  (#(#'both' #'right') includes: cleanSymbol)
    ifTrue: [ 
      stop := TonelWriter lineEnding size.
      [ stop > 0 and: [ self isSeparator: (ch := result peek) ] ]
        whileTrue: [ 
          (self isEnter: ch)
            ifTrue: [ stop := stop - 1 ].
          result skip: -1 ] ].
  end := result position.
  ^ result originalContents copyFrom: start + 1 to: end + 1

]

{ #category : 'parsing' }
TonelParser >> separator [
	[ stream atEnd not and: [ self isSeparator: stream peek ] ]
	whileTrue: [ stream next ].
	^ nil

]

{ #category : 'parsing' }
TonelParser >> shebang [
	"look for a '#!' in first two character position and skip to next line if present"

	(stream peekFor: $#) ifFalse: [ ^ nil ].	
	(stream peekFor: $!) ifFalse: [ ^ nil ].
	^ stream  upTo: Character lf.
]

{ #category : 'accessing' }
TonelParser >> start [
	^ self document

]

{ #category : 'accessing' }
TonelParser >> stream: aStream [ 
	stream := aStream

]

{ #category : 'private parsing' }
TonelParser >> try: aBlock [
	^ self 
		try: aBlock 
		onSuccess: [ :parsedValue | parsedValue ] 
		onFailure: [ nil ]

]

{ #category : 'private parsing' }
TonelParser >> try: aBlock onFailure: failureBlock [
	^ self 
		try: aBlock 
		onSuccess: [ :parsedValue |  parsedValue ] 
		onFailure: failureBlock

]

{ #category : 'private parsing' }
TonelParser >> try: aBlock onSuccess: successBlock [
	^ self 
		try: aBlock 
		onSuccess: successBlock 
		onFailure: [ nil ]

]

{ #category : 'private parsing' }
TonelParser >> try: aBlock onSuccess: successBlock onFailure: failureBlock [
	| pos |
	
	pos := stream position.
	[ ^ successBlock value: aBlock value ]
	on: TonelParseError 
	do: [ :e | 
		stream position: pos.
		^ failureBlock value ]. 
	

]

{ #category : 'parsing' }
TonelParser >> type [
	self try: [ self word: 'Class' ] onSuccess: [ :word | ^ word  ].
	self try: [ self word: 'Trait' ] onSuccess: [ :word | ^ word  ].
	self try: [ self word: 'Extension' ] onSuccess: [ :word | ^ word  ].
	
	"at end"
	TonelParseError signal: 'Can''t parse type.'	

]

{ #category : 'parsing' }
TonelParser >> typeDef [
	| shebang |
	shebang := self shebang. "ignore shebang on first line of file if present"
	^ self newTypeDefinitionFrom: { 
		self separator.
		self try: [ self comment ]. 
		self separator. 
		self type. 
		self separator. 
		self try: [ 
			| typeMetadata normalizedMetadata |
			typeMetadata := self metadata.
			normalizedMetadata := Dictionary new.
			typeMetadata keysAndValuesDo: [:key :value |
				normalizedMetadata at: key asLowercase asSymbol put: value ].
			normalizedMetadata at: #shebang put: shebang.
			normalizedMetadata ] 
	}
]

{ #category : 'private parsing' }
TonelParser >> untilExcluding: aCollection [
	| result |
	result := stream upToAll: aCollection.
	stream position: stream position - aCollection size.
	^ result

]

{ #category : 'private parsing' }
TonelParser >> untilIncluding: aCollection [
	^ stream upToAll: aCollection

]

{ #category : 'private parsing' }
TonelParser >> word: aString [
	| result |
	result := stream next: aString size.
	result = aString
		ifFalse: [ TonelParseError signal: 'Can''t parse ', aString ].
	^ result

]