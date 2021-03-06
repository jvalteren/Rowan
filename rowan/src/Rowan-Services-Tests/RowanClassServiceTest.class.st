"
Created to test inherited tests on client
"
Class {
	#name : 'RowanClassServiceTest',
	#superclass : 'RowanServicesTest',
	#category : 'Rowan-Services-Tests'
}

{ #category : 'patch' }
RowanClassServiceTest >> createClassNamed: className [

]

{ #category : 'support' }
RowanClassServiceTest >> createHierarchyWithNonResolvableClass [

	"do not delete - sent by Jadeite client test
	RowanClassServiceTest new createHierarchyWithNonResolvableClass.
	Code by dhenrich"

  | projectName  packageName1 packageName2 projectDefinition classDefinition packageDefinition className1 className2 className3
    className4 projectSetDefinition class1 class2 class3 class4 oldClass1 oldClass2 oldClass3  |

  projectName := 'Issue470'.
  packageName1 := 'Issue470-Core'.
  packageName2 := 'Issue470-Extensions'.
  className1 := 'Issue470Class1'.
  className2 := 'Issue470Class2'.
  className3 := 'Issue470Class3'.
  className4 := 'Issue470Class4'.

  {projectName}
    do: [ :pn |
      (Rowan image loadedProjectNamed: pn ifAbsent: [  ])
        ifNotNil: [ :loadedProject | Rowan image _removeLoadedProject: loadedProject ] ].

"create project"
  projectDefinition := (RwProjectDefinition
    newForGitBasedProjectNamed: projectName)
    addPackageNamed: packageName1;
    addPackageNamed: packageName2;
    defaultSymbolDictName: 'UserGlobals';
    yourself.

  packageDefinition := projectDefinition packageNamed: packageName1.

  classDefinition := (RwClassDefinition
    newForClassNamed: className1
      super: 'Object'
      instvars: #(ivar1)
      classinstvars: #()
      classvars: #()
      category: packageName1
      comment: 'comment'
      pools: #()
      type: 'normal')
    yourself.
  packageDefinition
    addClassDefinition: classDefinition.

  classDefinition := (RwClassDefinition
    newForClassNamed: className2
      super: className1
      instvars: #('ivar2')
      classinstvars: #()
      classvars: #()
      category: packageName1
      comment: 'comment'
      pools: #()
      type: 'normal')
    yourself.
  packageDefinition
    addClassDefinition: classDefinition.

  classDefinition := (RwClassDefinition
    newForClassNamed: className3
      super: className2
      instvars: #('ivar4' 'ivar3')
      classinstvars: #()
      classvars: #()
      category: packageName1
      comment: 'comment'
      pools: #()
      type: 'normal')
   yourself.
  packageDefinition
    addClassDefinition: classDefinition.

"load"
  projectSetDefinition := RwProjectSetDefinition new.
  projectSetDefinition addDefinition: projectDefinition.
  Rowan projectTools load loadProjectSetDefinition: projectSetDefinition.

"validate"
  class1 := Rowan globalNamed: className1.
  self assert: class1 instVarNames = #(ivar1).

  class2 := Rowan globalNamed: className2.
  self assert: class2 instVarNames = #(ivar2).
  self assert: class2 superClass == class1.

  class3 := Rowan globalNamed: className3.
  self assert: class3 instVarNames = #(ivar4 ivar3).
  self assert: class3 superClass == class2.

"remove class2 and add class4 -- edit projectDefinition structure in place"
  projectDefinition := (Rowan image loadedProjectNamed: projectName) asDefinition.
  packageDefinition := projectDefinition packageNamed: packageName1.

  packageDefinition removeClassNamed: className2.

  classDefinition := (RwClassDefinition
    newForClassNamed: className4
      super: className1
      instvars: #('ivar2')
      classinstvars: #()
      classvars: #()
      category: packageName1
      comment: 'comment'
      pools: #()
      type: 'normal')
    yourself.
  packageDefinition
    addClassDefinition: classDefinition.
"load"
  projectSetDefinition := RwProjectSetDefinition new.
  projectSetDefinition addDefinition: projectDefinition.
  Rowan projectTools load loadProjectSetDefinition: projectSetDefinition.

"validate"
  oldClass1 := class1.
  oldClass2 := class2.
  oldClass3 := class3.
 
  class1 := Rowan globalNamed: className1.
  self assert: class1 instVarNames = #(ivar1).
  self assert: oldClass1 == class1.

  class4 := Rowan globalNamed: className4.
  self assert: class4 instVarNames = #(ivar2).
  self assert: class4 superClass == class1.

  class3 := Rowan globalNamed: className3.
  self assert: class3 instVarNames = #(ivar4 ivar3).
  self assert: class3 superClass == oldClass2.
  self assert: oldClass3 == class3.
]

{ #category : 'support' }
RowanClassServiceTest >> servicesClassInstance [

	^self servicesDefaultClassName evaluate perform: #new
]

{ #category : 'support' }
RowanClassServiceTest >> setUp [
	super setUp.
	self createServicesTestClass.
	self loadServicesTestProject.
]

{ #category : 'support' }
RowanClassServiceTest >> tearDown [

	self unloadServicesTestProject.
	super tearDown.
]

{ #category : 'tests' }
RowanClassServiceTest >> test_addCategory [
	| classService behavior |
	
	behavior := Rowan globalNamed: self servicesDefaultClassName. 
	self deny: (behavior categoryNames includes: 'fnoodle'). 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName meta: false. 
	classService addCategory: 'fnoodle'.
	self assert: (behavior categoryNames includes: #fnoodle).
]

{ #category : 'tests' }
RowanClassServiceTest >> test_addedProjectNotOnDisk [

	| projectDefinition packageDefinition classDefinition projectService |
	projectDefinition := self createNonDiskTestProjectNamed: 'Azer' packageName: 'Baijan'. 
	[packageDefinition := projectDefinition packageNamed: 'Baijan'.

	classDefinition := RwClassDefinition
		newForClassNamed: #Baijan
		super: 'Object'
		instvars: #(name address orderHistory)
		classinstvars: #()
		classvars: #()
		category: nil
		comment: 'a CustomerRecord holds the sales record for a customer.'
		pools: #()
		type: 'normal'.
	packageDefinition addClassDefinition: classDefinition.
	Rowan projectTools load loadProjectDefinition: projectDefinition.

	(RowanClassService forClassNamed: 'Baijan') update. "<-- walkback occurrred here"
	projectService := RowanProjectService newNamed: 'Azer'. 
	self deny: projectService existsOnDisk.
	self deny: projectService isSkew]
		ensure: [RowanBrowserService new unloadProjectsNamed: (Array with: 'Azer')]
]

{ #category : 'tests' }
RowanClassServiceTest >> test_behavior [
	"return class or meta class" 
	| classService |
	classService := RowanClassService forClassNamed: 'Array' meta: false.
	self assert: classService behavior equals: Array.
	classService := RowanClassService forClassNamed: 'OrderedCollection' meta: true.
	self assert: classService behavior equals: OrderedCollection class
]

{ #category : 'tests' }
RowanClassServiceTest >> test_classComment [
	| classService behavior |
	behavior := Rowan globalNamed: self servicesDefaultClassName. 
	self assert: behavior comment equals: String new. 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName meta: false. 
	classService classComment: 'This is a test'. 
	self assert: behavior comment equals: 'This is a test'
]

{ #category : 'tests' }
RowanClassServiceTest >> test_classFromName [
	"always return thisClass" 
	| classService |
	classService := RowanClassService forClassNamed: 'Array' meta: false.
	self assert: classService theClass equals: Array.
	classService := RowanClassService forClassNamed: 'OrderedCollection' meta: true.
	self assert: classService theClass equals: OrderedCollection
]

{ #category : 'tests' }
RowanClassServiceTest >> test_classHierarchy [
	"return class hierarchy in format client can use.
	#nil -> #(Object class service)
	Object class service -> #(RowanService class service) 
	etc"
  
	| classService hierarchy objectClassService rowanServiceService |
	classService := RowanClassService forClassNamed: 'RowanClassService'.
	hierarchy := classService classHierarchy hierarchyServices. 
	self assert: (hierarchy isKindOf: Dictionary). 
	self assert: ((hierarchy at: #nil) isKindOf: Array).
	self assert: (hierarchy at: #nil) size equals: 1. 
	objectClassService := (hierarchy at: #nil) first.
	self assert: (objectClassService isKindOf: RowanClassService).
	self assert: objectClassService name equals: 'Object'.
	rowanServiceService := (hierarchy at: objectClassService) first. 
	self assert: rowanServiceService name equals: 'RowanService'.
	self assert: (hierarchy at: rowanServiceService) first name equals: 'RowanClassService'.
]

{ #category : 'tests' }
RowanClassServiceTest >> test_classHierarchyClassSide [
	"same as instance side"
  
	| classService hierarchy objectClassService rowanServiceService |
	classService := RowanClassService forClassNamed: 'RowanClassService' meta: true.
	hierarchy := classService classHierarchy hierarchyServices. 
	self assert: (hierarchy isKindOf: Dictionary). 
	self assert: ((hierarchy at: #nil) isKindOf: Array).
	self assert: (hierarchy at: #nil) size equals: 1. 
	objectClassService := (hierarchy at: #nil) first.
	self assert: (objectClassService isKindOf: RowanClassService).
	self assert: objectClassService name equals: 'Object'.
	rowanServiceService := (hierarchy at: objectClassService) first. 
	self assert: rowanServiceService name equals: 'RowanService'.
	self assert: (hierarchy at: rowanServiceService) first name equals: 'RowanClassService'.
]

{ #category : 'tests' }
RowanClassServiceTest >> test_classWasDeleted [
  | classService classDefinition packageDefinition |
  self
    jadeiteIssueTested: #'issue284'
    withTitle:
      '(3.0.49 and 3.0.50) project browser not updated properly on reload of project'.
  self unloadServicesTestProject.	"test class created in setUp"
  packageDefinition := self createServicesTestPackage. 
  [ 
  self loadServicesTestProject.
  System commitTransaction.	"commit loaded package, but not class"
  classDefinition := self
    createClassDefinitionNamed: self servicesDefaultClassName.
  packageDefinition addClassDefinition: classDefinition.
  self loadServicesTestProject.	"reload with class"
  classService := RowanClassService new name: self servicesDefaultClassName.
  self deny: classService wasDeleted.
  System abortTransaction.
  self assert: classService wasDeleted ]
    ensure: [ 
      self unloadServicesTestProject.
      System commitTransaction ]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_compileClassInitializer [
	"if you compile a class side method #initialize, the error 
	RwExecuteClassInitializeMethodsAfterLoadNotification is signaled. 
	Ensure that #saveMethodSource:category: doesn't handle it as
	it should be handled in compileMethod:behavior:symbolList:inCategory:"
	| classService errorHit methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	selector := #initialize. 
	classService meta: true. 
	errorHit := false. 
	[classService saveMethodSource: selector asString , ' ^$a' category: 'test initialize'] on: 
		RwExecuteClassInitializeMethodsAfterLoadNotification do:[:ex | errorHit := true.  ex resume: false. ].
	[self deny: errorHit. 
	methodService := classService methodsNamed: selector.
	self assert: methodService size equals: 1. 
	self assert: methodService first selector equals: selector.
	self assert: methodService first meta equals: true.
	self assert: (self servicesDefaultClassName evaluate perform: selector) equals: $a]
		ensure: [
			classService removeSelector: selector ifAbsent: [].
			self deny: ((self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false))]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_compileMethodNoCategory [
	"defaults to 'other'"
	| classService methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	selector := #fnoodle. 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	self deny: (self servicesDefaultClassName evaluate categoryNames includes: 'other'). 
	classService saveMethodSource: selector asString, ' ^$a' category: nil.
	[methodService := classService methodsNamed: selector.
	self assert: methodService size equals: 1. 
	self assert: methodService first meta equals: false.
	self assert: methodService first category equals: 'other'. 
	self assert: (self servicesDefaultClassName evaluate categoryNames includes: #'other'). 
	self assert: (self servicesClassInstance perform: selector) equals: $a]
		ensure: [
			classService removeSelector: selector ifAbsent: [].
			self deny: ((self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false))]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_dirtyState [
	| classService methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	selector := #simpleMethod. 
	self loadRowanSample1. "ensure we're in a clean state"
	self deny: (RowanProjectService newNamed:  'RowanSample1') isDirty.
	self deny: (RowanPackageService forPackageNamed: 'RowanSample1-Core') isDirty.
	classService := RowanClassService forClassNamed: 'RowanSample1'.
	classService saveMethodSource: selector asString,  ' ^123' category: 'abc'.
	
	methodService := classService methodsNamed: selector.
	[self assert: (RowanProjectService newNamed: 'RowanSample1') isDirty.
	self assert: (RowanPackageService new name: 'RowanSample1-Core') isDirty.]
			ensure: [
				Rowan projectTools delete deleteProjectNamed: 'RowanSample1'.]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_dirtyStateNewProject [
  "dirtiness is based on a comparison to disk.
	New projects (created in setUp) should be dirty"

  | classService selector |
  self
    jadeiteIssueTested: #'issue356'
    withTitle: 'Add method compilation tests in server services tests'.
  selector := #'simpleMethod'.
  [ 
  self assert: (RowanProjectService newNamed: 'RowanServicesTestProject') isDirty.
  self
    assert:
      (RowanPackageService forPackageNamed: 'RowanServicesTestPackage') isDirty.
  classService := RowanClassService forClassNamed: 'RowanServicesTestClass'.
  classService saveMethodSource: selector asString , ' ^123' category: 'abc' ]
    ensure: [ Rowan projectTools browser removeClassNamed: 'RowanServicesTestClass' ]
]

{ #category : 'tests' }
RowanClassServiceTest >> test_equality [

	| classService1 classService2 |
	classService1 := RowanClassService forClassNamed: 'RowanClassService'. 
	classService2 := RowanClassService forClassNamed: 'RowanClassService'. 
	self assert: classService1 equals: classService2.
	self deny: classService1 == classService2.
	self deny: classService1 equals: RowanClassService. 
	self deny: classService1 equals: #foo.
	self deny: classService1 equals: (RowanPackageService forPackageNamed: 'Rowan-Services-Tests').
	self deny: classService1 equals: (RowanProjectService newNamed: 'Rowan').
	self deny: classService1 equals: (RowanMethodService forSelector: #test_equality class: RowanClassServiceTest meta: false organizer: ClassOrganizer new)
]

{ #category : 'tests' }
RowanClassServiceTest >> test_instVarNamesIsArray [
	"instVarNames was getting set to a collection which
	was not handled well by STON"
	| classService |
	
	classService := RowanClassService forClassNamed: 'UnauthorizedObjectStub' meta: false. 
	self assert: (classService instVarNames isKindOf: Array).
]

{ #category : 'tests' }
RowanClassServiceTest >> test_nameIsString [

	| classService |
	self jadeiteIssueTested: #issue441 withTitle: '(3.0.62) suspicious code in RowanClassService>>hierarchyClassServiceFor:'.
	classService := RowanClassService forClassNamed: 'RowanClassService'. 
	self assert: (classService name isKindOf: String).
	classService := RowanClassService forClassNamed: #RowanClassService.
	self assert: (classService name isKindOf: String).

	classService := RowanClassService forClassNamed: 'RowanClassService' meta: true. 
	self assert: (classService name isKindOf: String).
	classService := RowanClassService forClassNamed: #RowanClassService meta: true. 
	self assert: (classService name isKindOf: String).

	classService := RowanClassService basicForClassNamed: 'RowanClassService'.
	self assert: (classService name isKindOf: String).
	classService := RowanClassService basicForClassNamed: #RowanClassService.
	self assert: (classService name isKindOf: String).

	classService := RowanClassService forClassNamed: 'RowanClassService' package: 'Rowan-Services-Tests'. 
	self assert: (classService name isKindOf: String).
	classService := RowanClassService forClassNamed: #RowanClassService package: 'Rowan-Services-Tests'. 
	self assert: (classService name isKindOf: String).

	classService := RowanClassService minimalForClassNamed: 'RowanClassService'.
	self assert: (classService name isKindOf: String).
	classService := RowanClassService minimalForClassNamed: #RowanClassService.
	self assert: (classService name isKindOf: String).
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_rowanCompileGone [

	"#rowanCompile was used to tell Rowan
	to compile a method in a Rowan package
	or in the traditional manner. That is no 
	longer needed. Make sure it's not referenced
	anywhere." 

	self assert: (ClassOrganizer new referencesToLiteral: '#rowanCompile' evaluate) first isEmpty
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_selectedMethod [
	| classService methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	selector := #simpleMethod. 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	self deny: classService meta. 
	self deny: (self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false).
	classService saveMethodSource: selector asString,  ' ^123' category: 'abc'.
	
	methodService := classService methodsNamed: selector.
	[self assert: classService selectedMethods size equals: 1.
	self assert: classService selectedMethods first selector equals: selector]
		ensure: [
			classService removeSelector: selector ifAbsent: [].
			self deny: ((self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false))]
]

{ #category : 'tests' }
RowanClassServiceTest >> test_setClassCommentDuringMetaclassRefresh [
  | classService behavior meta metaClassService |
  behavior := Rowan globalNamed: self servicesDefaultClassName.
  self assert: behavior comment equals: String new.
  classService := RowanClassService
    forClassNamed: self servicesDefaultClassName
    meta: false.
  classService classComment: 'This is a test'.
  meta := behavior class.
  metaClassService := RowanClassService new
    name: 'RowanClassService';
    oop: meta asOop.
  metaClassService fastRefresh.
  self assert: metaClassService comment equals: 'This is a test'
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_setSuperSubIndicators [
	| classService superclassMethodService subclassMethodService selector subclassService browserService |
	selector := #indicatorTesting. 
	self loadRowanSample1.
	[browserService := RowanBrowserService new. 
	browserService compileClass: 
		'RowanSample1 rwSubclass: ''RowanSubClass''
			instVarNames: #()
			classVars: #()
			classInstVars: #()
			poolDictionaries: #()
			category: ''RowanSample1-Core''
			options: #()'.
	classService := RowanClassService forClassNamed: 'RowanSample1'.
	self assert: RowanCommandResult results size equals: 0. "we no longer return a service on first stage of compile"
	browserService recompileMethodsAfterClassCompilation. 
	classService saveMethodSource: selector asString,  ' ^#deleteThisMethod' category: 'abc'.
	superclassMethodService := (classService methodsNamed: selector) first.
	self deny: superclassMethodService hasSupers.
	self deny: superclassMethodService hasSubs.
	subclassService := RowanClassService forClassNamed: 'RowanSubClass'.
	subclassService saveMethodSource: selector asString,  ' ^#subclassMethod' category: 'abc'.
	subclassMethodService := RowanCommandResult results 
			detect:[:service | service isMethodService
				and:[service selector = selector and:[service className = 'RowanSubClass']]]. "an updated subclass method should be heading back to the client" 
	superclassMethodService := RowanCommandResult results 
			detect:[:service | service isMethodService
				and:[service selector = selector and:[service className = 'RowanSample1']]]. "an updated superclass method should be heading back to the client" 
	self assert: superclassMethodService hasSubs.  
	self deny: superclassMethodService hasSupers.
	self assert: subclassMethodService hasSupers.
	self deny: subclassMethodService hasSubs.
	]
			ensure: [
				Rowan projectTools delete deleteProjectNamed: 'RowanSample1'.]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_simpleCompile [
	| classService methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	selector := #simpleMethod. 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	self deny: classService meta. 
	self deny: (self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false).
	classService saveMethodSource: selector asString,  ' ^123' category: 'abc'.
	
	methodService := classService methodsNamed: selector.
	[self assert: methodService size equals: 1. 
	self assert: methodService first selector equals: selector.
	self assert: methodService first meta equals: false.
	self assert: methodService first category equals: 'abc'.
	self assert: (self servicesClassInstance perform: selector) equals: 123.
	self assert: ((self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: nil) isKindOf: GsNMethod)]
		ensure: [
			classService removeSelector: selector ifAbsent: [].
			self deny: ((self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false))]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_simpleCompileClassSide [
	| classService methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	selector := #simpleMethod.
	classService meta: true. 
	self assert: classService meta. 
	self deny: (((self servicesDefaultClassName evaluate perform: #class)  compiledMethodAt: selector otherwise: false)).
	classService saveMethodSource: selector asString,  ' ^123' category: 'abc'.
	[methodService := classService methodsNamed: selector.
	self assert: methodService size equals: 1. 
	self assert: methodService first selector equals: selector.
	self assert: methodService first meta equals: true.
	self assert: methodService first category equals: 'abc'.
	self assert: (self servicesDefaultClassName evaluate perform: selector) equals: 123.
	((self servicesDefaultClassName evaluate perform: #class)compiledMethodAt: selector) isKindOf: GsNMethod]
		ensure: [
			classService removeSelector: selector ifAbsent: [].
			self deny: (((self servicesDefaultClassName evaluate perform: #class)  compiledMethodAt: selector otherwise: false)).]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_simpleCompileOnClassWithoutMetaSet [
	| classService  methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	selector := #noMeta. 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	classService meta: nil.  "possible for meta not to be set but it should have an oop from which to determine" 
	classService oop: (self servicesDefaultClassName, ' class') evaluate asOop. 
	self deny: (((self servicesDefaultClassName evaluate perform: #class)  compiledMethodAt: selector otherwise: false)).
	classService saveMethodSource: selector asString,  ' ^true' category: 'testing'.
	[methodService := classService methodsNamed: selector.
	self assert: methodService size equals: 1. 
	self assert: methodService first selector equals: selector.
	self assert: methodService first meta equals: true. "we created a class method"
	self assert: methodService first category equals: 'testing'.
	self assert: (self servicesDefaultClassName evaluate perform: selector)]
		ensure: [
			classService removeSelector: selector ifAbsent: [].
			self deny: (((self servicesDefaultClassName evaluate perform: #class)  compiledMethodAt: selector otherwise: false)).]
]

{ #category : 'test method compilation' }
RowanClassServiceTest >> test_simpleCompileWithoutMetaSet [
	| classService methodService selector |
	self jadeiteIssueTested: #issue356 withTitle: 'Add method compilation tests in server services tests'.
	selector := #noMeta. 
	classService := RowanClassService forClassNamed: self servicesDefaultClassName.
	classService meta: nil.  "possible for meta not to be set but it should have an oop from which to determine" 
	classService oop: self servicesDefaultClassName evaluate asOop. 
	self deny: (self servicesDefaultClassName evaluate compiledMethodAt: selector otherwise: false).
	classService saveMethodSource: selector asString,  ' ^true' category: 'testing'.
	methodService := classService methodsNamed: selector.
	self assert: methodService size equals: 1. 
	self assert: methodService first selector equals: selector.
	self assert: methodService first meta equals: false. "we created an instance method"
	self assert: methodService first category equals: 'testing'.
	self assert: (self servicesClassInstance perform: selector).
]
