Extension { #name : 'RwProjectTest' }

{ #category : '*rowan-tests-componentsv2-onlyv2' }
RwProjectTest >> test_issue428_loaded_no_disk [

	| projectName  packageName projectDefinition projectSetDefinition  componentName |

	projectName := 'Issue428'.
	packageName := 'Issue428-Extension'.

	{projectName}
		do: [ :pn | 
			(Rowan image loadedProjectNamed: pn ifAbsent: [  ])
				ifNotNil: [ :loadedProject | Rowan image _removeLoadedProject: loadedProject ] ].

"create project"
	componentName := 'Core'.
	projectDefinition := RwResolvedProjectV2 new
		projectName: projectName;
		projectsHome: self _testRowanProjectsSandbox;
		gemstoneSetDefaultSymbolDictNameTo: self _symbolDictionaryName1;
		addNewComponentNamed: componentName;
		addPackagesNamed: { packageName }
			toComponentNamed: componentName;
		resolve;
		yourself.

"load"
	projectSetDefinition := RwProjectSetDefinition new.
	projectSetDefinition addDefinition: projectDefinition.
	Rowan projectTools load loadProjectSetDefinition: projectSetDefinition.

"test existsOnDisk"

	self deny: (RwProject newNamed: projectName) existsOnDisk.

]

{ #category : '*rowan-tests-componentsv2-onlyv2' }
RwProjectTest >> test_issue428_loaded_on_disk [

	| projectName projectDefinition projectTools packageNames componentName |
	projectName := 'Issue428'.
	packageNames := #('Issue428-Core' 'Issue428-Tests').
	projectTools := Rowan projectTools.

	{projectName}
		do: [ :name | 
			(Rowan image loadedProjectNamed: name ifAbsent: [  ])
				ifNotNil: [ :project | Rowan image _removeLoadedProject: project ] ].

	componentName := 'Core'.
	projectDefinition := RwResolvedProjectV2 new
		projectName: projectName;
		projectsHome: self _testRowanProjectsSandbox  / 'rowanSimpleProject';
		gemstoneSetDefaultSymbolDictNameTo: self _symbolDictionaryName1;
		addNewComponentNamed: componentName;
		addPackagesNamed: packageNames
			toComponentNamed: componentName;
		packageFormat: 'tonel';
		yourself.

	self
		handleConfirmationDuring: [ 
			projectDefinition 
				resolve;
				export;
				exportLoadSpecification;
				load;
				yourself ].

"test existsOnDisk"

	self assert: (RwProject newNamed: projectName) existsOnDisk.

]