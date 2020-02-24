Extension { #name : 'RwProjectComponentVisitorV2Test' }

{ #category : '*rowan-testsV2' }
RwProjectComponentVisitorV2Test >> _cloneRowanSample9: projectAlias [
	"clone https://github.com/dalehenrich/RowanSample9 and return full path to the clone"

	| basicProject loadSpec projectPath projectsHome |
	projectsHome := RwRowanSample9Test _testRowanProjectsSandbox asFileReference.
	projectPath := projectsHome / projectAlias.
	projectPath exists
		ifTrue: [ projectPath deleteAll ].

	loadSpec := RwLoadSpecificationV2 new
		projectAlias: projectAlias;
		specName: projectAlias;
		projectsHome: projectsHome;
		componentNames: #('Core');
		groupNames: #('core');
		projectSpecFile: 'rowan/project.ston';
		gitUrl: 'https://github.com/dalehenrich/RowanSample9';
		revision: 'spec_0008';
		yourself.
	loadSpec _validate.

	basicProject := RwResolvedProjectV2 basicLoadSpecification: loadSpec.
	basicProject _projectRepository resolve.	"create clone"

	^ projectPath pathString
]

{ #category : '*rowan-testsV2' }
RwProjectComponentVisitorV2Test >> _cloneVastTonelDemo_555: projectAlias deleteClone: deleteClone [
	"Read project definition from a tonel repository written by VAST .. includes additional package/class/method properties not used by GemStone or Pharo"

	"https://github.com/GemTalk/Rowan/issues/555"

	| loadSpec projectsHome projectPath basicProject |
	projectsHome := RwRowanSample9Test _testRowanProjectsSandbox asFileReference.
	deleteClone
		ifTrue: [ 
			projectPath := projectsHome / projectAlias.
			projectPath exists
				ifTrue: [ projectPath deleteAll ] ].

	loadSpec := RwLoadSpecificationV2 new
		projectAlias: projectAlias;
		specName: projectAlias;
		projectsHome: projectsHome;
		componentNames: #('Core');
		groupNames: #('core');
		projectSpecFile: 'rowan/project.ston';
		gitUrl: 'https://github.com/dalehenrich/tonel-demos';
		revision: 'rowan_553';
		yourself.

	loadSpec _validate.

	basicProject := RwResolvedProjectV2 basicLoadSpecification: loadSpec.
	basicProject _projectRepository resolve.	"create clone"

	^ projectPath pathString
]

{ #category : '*rowan-testsV2' }
RwProjectComponentVisitorV2Test >> _readVastTonelDemo_555: platformAttributes deleteClone: deleteClone [
	"Read project definition from a tonel repository written by VAST .. includes additional package/class/method properties not used by GemStone or Pharo"

	"https://github.com/GemTalk/Rowan/issues/555"

	| projectName loadSpec projectAlias projectsHome projectPath |
	projectName := 'tonel-demo'.
	projectAlias := projectName , '_DiskConfig_Test'.

	projectsHome := RwRowanSample9Test _testRowanProjectsSandbox asFileReference.
	deleteClone
		ifTrue: [ 
			projectPath := projectsHome / projectAlias.
			projectPath exists
				ifTrue: [ projectPath deleteAll ] ].

	loadSpec := RwLoadSpecificationV2 new
		projectName: projectName;
		projectAlias: projectAlias;
		specName: projectName;
		projectsHome: projectsHome;
		componentNames: #('Core');
		groupNames: #('core');
		projectSpecFile: 'rowan/project.ston';
		gitUrl: 'https://github.com/dalehenrich/tonel-demos';
		revision: 'rowan_553';
		yourself.

	^ loadSpec resolve: platformAttributes
]

{ #category : '*rowan-testsV2' }
RwProjectComponentVisitorV2Test >> testBasicVisit_withResolvedProject [
	"test of RwProjectLoadComponentVisitorV2 as it is used in the RwPrjReadToolV2."

	| platformConditionalAttributes groupNames componentsRoot basicProject visitor componentNamesToLoad projectName loadSpec projectAlias projectPath projectsHome |
	platformConditionalAttributes := {'common'.
	'gemstone'.
	('3.5.0' asRwGemStoneVersionNumber)}.
	projectName := 'RowanSample9'.
	projectAlias := projectName , '_DiskConfig_Test'.
	componentNamesToLoad := #('Core').

	projectsHome := RwRowanSample9Test _testRowanProjectsSandbox asFileReference.
	projectPath := projectsHome / projectAlias.
	projectPath exists
		ifTrue: [ projectPath deleteAll ].

	loadSpec := RwLoadSpecificationV2 new
		projectName: projectName;
		projectAlias: projectAlias;
		specName: projectName;
		projectsHome: projectsHome;
		componentNames: componentNamesToLoad;
		groupNames: #('core');
		projectSpecFile: 'rowan/project.ston';
		gitUrl: 'https://github.com/dalehenrich/RowanSample9';
		revision: 'spec_0008';
		yourself.
	basicProject := RwResolvedProjectV2 basicLoadSpecification: loadSpec.
	basicProject _projectRepository resolve.	"create clone"
	groupNames := loadSpec groupNames.
	componentsRoot := basicProject componentsRoot.

	self assert: basicProject packageNames isEmpty.

	visitor := RwResolvedProjectComponentVisitorV2
		resolvedProject: basicProject
		platformConditionalAttributes: platformConditionalAttributes
		groupNames: groupNames.
	projectName := basicProject projectAlias.

	self assert: visitor packageNames isEmpty.

	componentNamesToLoad
		do: [ :componentName | 
			| component url |
			url := 'file:' , (componentsRoot / componentName , 'ston') pathString.
			component := RwAbstractProjectLoadComponentV2 fromUrl: url.
			component projectName: projectName.

			visitor visit: component ].
	self
		assert: visitor packageNames sort
		equals:
			#('RowanSample9-Core' 'RowanSample9-Extensions' 'RowanSample9-GemStone') sort.
	self assert: visitor projectLoadSpecs isEmpty
]

{ #category : '*rowan-testsV2' }
RwProjectComponentVisitorV2Test >> testReadVastTonelDemo_555 [
	"Read project definition from a tonel repository written by VAST .. includes additional package/class/method properties not used by GemStone or Pharo"

	"https://github.com/GemTalk/Rowan/issues/555"

	| resolvedProject x |
"vast"
	resolvedProject := self
		_readVastTonelDemo_555:
			{'common'.
			'vast'}
		deleteClone: true.
	self
		assert: (x := resolvedProject packageNames sort)
		equals:
			#('TonelExampleAnotherSubSubApp' 'TonelAnotherShadowSubSubApp' 'TonelExampleApp' 'TonelExampleShadowSubSubApp' 'TonelExampleSubApp' 'TonelExampleShadowSubSubSubApp' 'TonelExampleSubSubApp' 'TonelExampleForVastPharoApp')
				sort.

"pharo"
	resolvedProject := self
		_readVastTonelDemo_555:
			{'common'.
			'pharo'}
		deleteClone: false.
	self
		assert: resolvedProject packageNames sort
		equals: #('TonelExampleApp' 'TonelExampleForPharoApp' 'TonelExampleForVastPharoApp') sort.

"gemstone"
	resolvedProject := self
		_readVastTonelDemo_555:
			{'common'.
			'gemstone'}
		deleteClone: false.
	self assert: resolvedProject packageNames sort equals: #('TonelExampleApp' 'TonelExampleForGemStoneApp') sort
]