Extension { #name : 'Class' }

{ #category : '*rowan-gemstone-3215' }
Class >> _equivalentSubclass: oldClass superCls: actualSelf name: aString newOpts: optionsArray newFormat: theFormat newInstVars: anArrayOfInstvarNames newClassInstVars: anArrayOfClassInstVars newPools: anArrayOfPoolDicts newClassVars: anArrayOfClassVars inDict: aDictionary constraints: aConstraint isKernel: isKernelBool [

	"Backport of bugfix for Bug47413"

	"oldClass is equivalent to the subclass that would be created using
 the other arguments if 
     instVar names match exactly ,
   and class instVar names match exactly ,
   and the classVars in oldClass can be modified to add/remove Associations 
     to match anArrayOfClassVars ,
   and pool dictionaries match exactly,
   and (constraints match exactly  or( aConstraint size == 0 and oldClass has a reserved oop))

  With respect to options and format, oldClass is equivalent if
    The state of format bits dbTransient, instancesNonPersistent, instancesInvariant  
     match exactly ,
    and subclassesDisallowed cannot be set in the new subclass if it not set in oldClass ,
    and modifiable  cannot be set if it is not set in oldClass  ,
    and  (SELF_CAN_BE_SPECIAL, NSC_DUPLICATES, INDEXABLE, IMPLEMENTATION, NO_STRUCT_UPDATE bits)
        of the formats must match exactly.

  If all other equivalence tests pass, the following changes to oldClass may be 
  made to match the arguments and avoid creating a new subclass
    subclassesDisallowed bit may be cleared in format of oldClass 
    traverseByCallback bit may be set or cleared in format of oldClass
    oldClass may be changed from modifiable to not modifiable (by sending immediateInvariant)
    classVars may be added to oldClass 
    classVars having modifiable Associations may be removed from oldClass 
"

	| oldOk fmtArr nam supr opts ivs civs poolds cvars constr cvarsArray |
	fmtArr := self _validateOptions: optionsArray withFormat: theFormat.
	(oldClass isKindOf: Class)
		ifFalse: [ oldClass _validateClass: Class ].
	nam := oldClass name asString = aString asString.
	supr := oldClass superClass == actualSelf.
	opts := oldClass _optionsChangableTo: fmtArr.
	ivs := oldClass _instVarsEqual: anArrayOfInstvarNames.
	civs := oldClass class _instVarsEqual: anArrayOfClassInstVars.
	poolds := oldClass _poolDictsEqual: anArrayOfPoolDicts.
	cvars := oldClass
		_classVarsChangableTo: (cvarsArray := anArrayOfClassVars copy).
	constr := (isKernelBool and: [ aConstraint size == 0 ])
		ifTrue: [ true ]
		ifFalse: [ oldClass _constraintsEqual: aConstraint ].
	oldOk := nam
		and: [ 
			supr
				and: [ opts and: [ ivs and: [ civs and: [ poolds and: [ cvars and: [ constr ] ] ] ] ] ] ].
	oldOk
		ifTrue: [ 
			| oldVal newName |
			aDictionary
				ifNotNil: [ 
					newName := aString asSymbol.
					oldVal := aDictionary at: newName otherwise: nil.
					oldVal == oldClass
						ifFalse: [ 
							ImproperOperation
								signal:
									'no new subclass needed, but aDictionary at: oldClass name ~~ oldClass'.
							^ false ] ].
			oldClass _adjustOptions: optionsArray formatArr: fmtArr.
			oldClass _adjustClassVars: cvarsArray.
			(fmtArr at: 3)
				ifTrue: [ GsFile gciLogServer: 'class ' , aString , ' equivalent to reqested class' ].
			^ true ]
		ifFalse: [ 
			(fmtArr at: 3)
				ifTrue: [ 
					GsFile
						gciLogServer:
							'_equivalentSubclass false, nam:' , nam asString , ' supr:' , supr asString
								, ' opts:' , opts asString , ' ivs:' , ivs asString , ' civs:'
								, civs asString , ' poolds:' , poolds asString , ' cvars:'
								, cvars asString , ' constr:' , constr asString ] ].
	^ false

]

{ #category : '*rowan-gemstone-3215' }
Class >> _subclass: className instVarNames: anArrayOfInstvarNames format: theFormat constraints: theConstraints classVars: anArrayOfClassVars classInstVars: anArrayOfClassInstVars poolDictionaries: anArrayOfPoolDicts inDictionary: aDictionary inClassHistory: aClassHistory description: aDescription options: optionsArray [

	"Backport of bugfix for Bug47433"

	"The preferred private subclass creation method.
 optionsArray is an Array of Symbols containing zero or more of  
   #noInheritOptions,  #subclassesDisallowed, #disallowGciStore, #modifiable , 
   #traverseByCallback 
 and at most one of 
   #dbTransient, #instancesNonPersistent, #instancesInvariant .
 If present, #noInheritOptions must be the first element and it causes
 none of subclassesDisallowed, disallowGciStore, traverseByCallback,
         dbTransient, instancesNonPersistent, instancesInvariant 
 to be inherited from the superclass, nor copied from the
 current version of the class.
"

	| cvDict result theName ivNames classCon conEle conEleEle theHist poolDicts modifiableBool fmtArr fmt nCivs sza szb civNames |
	self _validatePrivilege
		ifFalse: [ ^ nil ].
	className _isOneByteString
		ifFalse: [ 
			(className _validateClass: CharacterCollection)
				ifFalse: [ ^ nil ] ].
	self subclassesDisallowed
		ifTrue: [ ^ self _error: #'classErrSubclassDisallowed' ].
	anArrayOfClassInstVars
		ifNotNil: [ 
			anArrayOfClassInstVars _isArray
				ifFalse: [ 
					(anArrayOfClassInstVars _validateClass: Array)
						ifFalse: [ ^ nil ] ] ].
	aDictionary
		ifNotNil: [ 
			(aDictionary _validateClass: SymbolDictionary)
				ifFalse: [ ^ nil ] ].
	fmtArr := self _validateOptions: optionsArray withFormat: theFormat.
	fmt := fmtArr at: 1.
	modifiableBool := fmtArr at: 2.
	(self instancesInvariant and: [ (fmt bitAnd: 16r8) == 0 ])
		ifTrue: [ ^ self _error: #'classErrInvariantSuperClass' ].
	anArrayOfInstvarNames _isArray
		ifFalse: [ 
			(anArrayOfInstvarNames _validateClass: Array)
				ifFalse: [ ^ nil ] ].
	ivNames := {}.
	1 to: anArrayOfInstvarNames size do: [ :j | ivNames add: (anArrayOfInstvarNames at: j) ].
	theConstraints _isArray
		ifFalse: [ classCon := theConstraints ]
		ifTrue: [ 
			classCon := theConstraints class new.
			1 to: theConstraints size do: [ :j | 
				conEle := theConstraints at: j.
				conEle _isArray
					ifFalse: [ classCon add: conEle ]
					ifTrue: [ 
						| temp |
						temp := conEle class new.
						1 to: conEle size do: [ :k | 
							conEleEle := conEle at: k.
							(conEleEle isKindOf: CharacterCollection)
								ifTrue: [ temp add: conEleEle asSymbol ]
								ifFalse: [ temp add: conEleEle ] ].
						classCon add: temp ] ] ].
	nCivs := anArrayOfClassInstVars size.
	civNames := anArrayOfClassInstVars.
	nCivs ~~ 0
		ifTrue: [ 
			| aSet |
			civNames := Array new: nCivs.
			aSet := IdentitySet new.
			1 to: nCivs do: [ :k | 
				| aName |
				aName := (anArrayOfClassInstVars at: k) asSymbol.
				self class _validateNewClassInstVar: aName.
				civNames at: k put: aName.
				aSet add: aName.
				aSet size < k
					ifTrue: [ 
						ImproperOperation
							signal:
								'array of new class instanceVariables contains a duplicate ' , aName printString ] ] ].	"Gs64 v3.0 , cvDict and poolDicts maybe nil from caller,
    and will be converted to nil if caller passed an empty Array."
	cvDict := self _makeClassVarDict: anArrayOfClassVars.	"undo the compiler's canonicalization of empty arrays (fix bug 14103) "
	poolDicts := anArrayOfPoolDicts.
	(poolDicts _isArray and: [ poolDicts size == 0 ])
		ifTrue: [ poolDicts := nil ].
	theName := className asSymbol.
	result := self
		_subclass: theName
		instVarNames: ivNames
		format: fmt
		constraints: classCon
		classVars: cvDict
		poolDictionaries: poolDicts
		classInstanceVars: civNames.
	modifiableBool
		ifTrue: [ result _subclasses: IdentitySet new ].
	subclasses ifNotNil: [ subclasses add: result ].
	aDictionary ifNotNil: [ aDictionary at: theName put: result ].

	result extraDict: SymbolDictionary new.
	result _commentOrDescription: aDescription.
	theHist := aClassHistory.
	theHist ifNil: [ theHist := ClassHistory new name: className ].
	theHist notEmpty
		ifTrue: [ result category: theHist current _classCategory ].
	theHist add: result.
	result classHistory: theHist.
	result timeStamp: DateTime now.
	result userId: System myUserProfile userId.

	sza := self class instSize + anArrayOfClassInstVars size.
	szb := result class instSize.
	sza == szb
		ifFalse: [ 
			InternalError
				signal:
					'prim 233: inconsistent class instance variables, superClass+args=>'
						, sza asString , '  newClass=>' , szb asString ].

	modifiableBool
		ifFalse: [ result immediateInvariant ].
	result copyVariables.
	self _clearCachedOrganizer.
	(fmtArr at: 3)
		ifTrue: [ GsFile gciLogServer: 'created class ' , className ].
	^ result

]

{ #category : '*rowan-gemstone-3215' }
Class >> byteSubclass: aString
classVars: anArrayOfClassVars
classInstVars: anArrayOfClassInstVars
poolDictionaries: anArrayOfPoolDicts
inDictionary: aDictionary
newVersionOf: oldClass
description: aDescription
options: optionsArray [

	"backport of fix for Bug47403"

	"Creates and returns a new byte subclass of the receiver.  You are not
 permitted to modify the new class after it is created.  If the receiver is not
 some kind of String class, then instances of the new class store and return
 SmallIntegers in the range 0 - 255.

 This method generates an error if instances of the receiver are of special
 storage format, if they are NSCs, or if they have instance variables.

 optionsArray is an Array of Symbols containing zero or more of  
   #noInheritOptions,  #subclassesDisallowed, #disallowGciStore, #modifiable , 
   #traverseByCallback 
 and at most one of 
   #dbTransient, #instancesNonPersistent, #instancesInvariant
 If present, #noInheritOptions must be the first element and it causes
 none of subclassesDisallowed, disallowGciStore, traverseByCallback,
         dbTransient, instancesNonPersistent, instancesInvariant 
 to be inherited from the superclass, nor copied from the
 current version of the class.

 Returns oldClass if it would be equivalent to the requested new class.
 (See Class(C)>>comment). "

	| hist fmt descr |
	aDictionary
		ifNotNil: [ 
			(aDictionary _validateClass: SymbolDictionary) ifFalse: [^nil] ].
	self instSize ~~ 0 ifTrue: [^self _error: #classErrByteObjInstVars].
	self isNsc
		ifTrue: 
			[^aString _error: #classErrBadFormat
				with: 'cannot create byte subclass of Nsc class'].
	fmt := (format bitAnd: 16r3 bitInvert) bitOr: 16r1 + 16r4.
	descr := aDescription.
	oldClass
		ifNotNil: 
			[(self
				_equivalentSubclass: oldClass
				superCls: self
				name: aString
				newOpts: optionsArray
				newFormat: fmt
				newInstVars: #()
				newClassInstVars: anArrayOfClassInstVars
				newPools: anArrayOfPoolDicts
				newClassVars: anArrayOfClassVars
				inDict: aDictionary
				constraints: #() isKernel: false ) 
					ifTrue: 
						[oldClass _commentOrDescription: aDescription.
						^oldClass	"avoid creation of a new version" ].
			hist := oldClass classHistory.
			descr ifNil: [descr := oldClass comment]].
	^self
		_subclass: aString
		instVarNames: #()
		format: fmt
		constraints: #()
		classVars: anArrayOfClassVars
		classInstVars: anArrayOfClassInstVars
		poolDictionaries: anArrayOfPoolDicts
		inDictionary: aDictionary
		inClassHistory: hist
		description: descr
		options: optionsArray

]
