Class {
	#name : 'RowanAnsweringServiceTest',
	#superclass : 'RowanServicesTest',
	#instVars : [
		'service'
	],
	#category : 'Rowan-Services-Tests'
}

{ #category : 'support' }
RowanAnsweringServiceTest >> setUp [

	super setUp. 
	service := RowanAnsweringService new organizer: ClassOrganizer new.
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_disableBreakpointsInterface [
  self
    jadeiteIssueTested: #'issue515'
    withTitle: '(3.0.77) clear all breakpoints menu item would be useful'.
  service setBreakPointsAreEnabled: true.
  self assert: service breakPointsAreEnabled.
  self assert: RowanService breakPointsAreEnabled equals: true.
  self assert: (SessionTemps current at: #'Jadeite_BreakPointsAreEnabled').
  service setBreakPointsAreEnabled: false.
  self deny: service breakPointsAreEnabled.
  self assert: RowanService breakPointsAreEnabled equals: false.
  self deny: (SessionTemps current at: #'Jadeite_BreakPointsAreEnabled')
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_execCompileError [
 
	self deny: (service exec: '1 +' context: nil asOop) key.
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_execNilContext [

	self assert: (service exec: '123' context: nil asOop) value equals: 123 asOop.
	self assert: (service exec: '$a' context: nil asOop) value equals: $a asOop.
	self assert: (service exec: '3+4' context: nil asOop) value equals: 7 asOop.
	self assert: (service exec: 'true' context: nil asOop) value equals: true asOop.
	self assert: (service exec: 'false' context: nil asOop) value equals: false asOop.
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_execWithContext [

	self assert: (service exec: 'self' context: 123 asOop) value equals: 123 asOop.
	self assert: (service exec: 'self size' context: Array new asOop) value equals: 0 asOop.
	self assert: (service exec: '1 + self' context: 2 asOop) value equals: 3 asOop.
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_initializeAutoCommit [
	| autoCommit | 
	self jadeiteIssueTested: #issue396 withTitle: 'Ability to turn on autocommit would be nice'.
	autoCommit := RowanService autoCommit. 
	self assert: RowanService autoCommit equals: autoCommit.
	self assert: (SessionTemps current at: #'Jadeite_AutoCommit') equals: autoCommit.
	[service initializeAutoCommit. 
	self deny: RowanService autoCommit. 
	self deny: (SessionTemps current at: #'Jadeite_AutoCommit')] ensure: [
		RowanService setAutoCommit: autoCommit.
		self assert: RowanService autoCommit equals: autoCommit.]
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_initializeBreakPointsAreDisabled [
  | breakPointsAreEnabled |
  self
    jadeiteIssueTested: #'issue515'
    withTitle: '(3.0.77) clear all breakpoints menu item would be useful'.
  breakPointsAreEnabled := RowanService breakPointsAreEnabled.
  self assert: RowanService breakPointsAreEnabled equals: breakPointsAreEnabled.
  self
    assert: (SessionTemps current at: #'Jadeite_BreakPointsAreEnabled')
    equals: breakPointsAreEnabled.
  [ 
  service initializeBreakPointsAreEnabled.
  self assert:  RowanService breakPointsAreEnabled.
  self assert: (SessionTemps current at: #'Jadeite_BreakPointsAreEnabled') ]
    ensure: [ 
      RowanService setBreakPointsAreEnabled: breakPointsAreEnabled.
      self
        assert: RowanService breakPointsAreEnabled
        equals: breakPointsAreEnabled ]
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_loadedPackageExists [
	self jadeiteIssueTested: #issue205 withTitle: 'misspelled extension category name causes trouble'.
	Rowan packageNames do:[:packageName |
		self assert: (service loadedPackageExists: packageName) answer].
	self deny: (service loadedPackageExists: 'AAAA') answer.
	self deny: (service loadedPackageExists: 'AJsfdjsdf') answer.
	self assert: (service loadedPackageExists: 'Rowan-Kernel') answer. 
	self assert: (service loadedPackageExists: 'rowan-kernel') answer. "lower case is accepted"
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_matchingPattern [

	self jadeiteIssueTested: #issue235 withTitle: 'Need Find Class/Method from console'.
	service selectorsMatchingPattern: #('size'). 
	self assert: service answer size equals: 1. 
	self assert: service answer first = #size.

	service selectorsMatchingPattern: #('SIZE').  "no case match"
	self assert: service answer size equals: 1. 
	self assert: service answer first = #size.

	service selectorsMatchingPattern: #('test_matching' $*). 
	self assert: service answer size equals: 1.
	self assert: service answer first = #test_matchingPattern.

	service selectorsMatchingPattern: #($* 'test_matching' ). 
	self assert: service answer size equals: 0.

	"sorted result"
	service selectorsMatchingPattern: #('size' $*). 
	self assert: service answer size > 1. 
	1 to: service answer size - 1 do:[:idx | 
		self assert: (service answer at: idx) < (service answer at: idx + 1)].
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_maxPrint [
	self jadeiteIssueTested: #issue398 withTitle: 'String Inspectors don''t display lfs'.
	self assert: (service printStringOf: 123 asOop toMaxSize: 5) equals: '123'.
	self assert: (service printStringOf: 123 asOop toMaxSize: 2) equals: '12...'.
	self assert: (service printStringOf: 'abc' asOop toMaxSize: 2) equals: '''a...'.
	self assert: (service printStringOf: Object new asOop toMaxSize: 25) equals: 'anObject'.
	self assert: (service printStringOf: 'ab
cd' asOop toMaxSize: 25) equals: '''ab
cd'''.  "includes lf (10) - no ? substitution"
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_play [

	"method to safely play with commits" 

	self deny: false
]

{ #category : 'tests' }
RowanAnsweringServiceTest >> test_setAutoCommit [
	| autoCommit | 
	self jadeiteIssueTested: #issue396 withTitle: 'Ability to turn on autocommit would be nice'.
	autoCommit := RowanService autoCommit. 
	[service setAutoCommit: true. 
	self assert: RowanService autoCommit. 
	self assert: (SessionTemps current at: #'Jadeite_AutoCommit').
	service setAutoCommit: false. 
	self deny: RowanService autoCommit. 
	self deny: (SessionTemps current at: #'Jadeite_AutoCommit')] ensure: [
		RowanService setAutoCommit: autoCommit.
		self assert: RowanService autoCommit equals: autoCommit.]
]
