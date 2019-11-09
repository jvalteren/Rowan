Class {
	#name : 'RwPrjLoadToolV2',
	#superclass : 'RwProjectTool',
	#category : 'Rowan-Tools-Core'
}

{ #category : 'private' }
RwPrjLoadToolV2 >> _doProjectSetLoad: projectSetDefinition instanceMigrator: instanceMigrator originalProjectSet: originalProjectSet processedClassNames: processedClassNames [
	| copiedProjectSetDef theClassName theClass projectDef theLoadedProject loadedClass packageDef |
	[ 
	^ self
		_loadProjectSetDefinition: projectSetDefinition
		instanceMigrator: instanceMigrator ]
		on: RwExistingVisitorAddingExistingClassNotification
		do: [ :ex | 
			theClassName := ex classDefinition name.
			(processedClassNames includes: theClassName)
				ifTrue: [ ex resume ].
			theClass := Rowan globalNamed: theClassName.
			theClass isBehavior
				ifFalse: [ 
					self halt.
					ex pass ].
			theLoadedProject := Rowan image loadedProjectNamed: theClass rowanProjectName.
			theLoadedProject
				ifNil: [ 
					"the loaded project should not be nil - if it is, pass the notification"
					ex pass ].
			(originalProjectSet projectNamed: theLoadedProject name ifAbsent: [  ])
				ifNotNil: [ 
					"If the loadedProject is in the originalProjectSet, then is likely to be a class move - resume and let the chips fall where they may"
					ex resume ].
			copiedProjectSetDef := projectSetDefinition copy.	"a project in the original project set is taking ownership of an already  loaded class,
					remove the class from the original project's package and attempt a reload"
			projectDef := copiedProjectSetDef
				projectNamed: theLoadedProject name
				ifAbsent: [ 
					projectDef := theLoadedProject asDefinition.
					copiedProjectSetDef addProject: projectDef.
					projectDef ].
			loadedClass := Rowan image loadedClassNamed: theClassName.
			packageDef := projectDef packageNamed: loadedClass loadedPackage name.
			packageDef removeClassNamed: theClassName.
			processedClassNames add: theClassName ].	"trim the stack"
	^ self
		_doProjectSetLoad: copiedProjectSetDef
		instanceMigrator: instanceMigrator
		originalProjectSet: originalProjectSet
		processedClassNames: processedClassNames
]

{ #category : 'private' }
RwPrjLoadToolV2 >> _loadProjectSetDefinition: projectSetDefinitionToLoad instanceMigrator: instanceMigrator [
	| loadedProjectSet loadedProjectDefinitionSet diff loadedProjectInfo loadedProjects |
	loadedProjectSet := projectSetDefinitionToLoad deriveLoadedThings.
	loadedProjectDefinitionSet := loadedProjectSet asProjectDefinitionSet.
	loadedProjectInfo := projectSetDefinitionToLoad properties
		at: 'loadedProjectInfo'
		ifAbsent: [ Dictionary new ].
	loadedProjectInfo
		keysAndValuesDo: [ :projectName :projectInfo | 
			| projectDefinition "install the packageMapSpecs for this load into the specification prior to the load" |
			projectDefinition := projectSetDefinitionToLoad
				projectNamed: projectName
				ifAbsent: [  ].
			projectDefinition updateGsPlatformSpecLoadedProjectInfo: projectInfo ].
	projectSetDefinitionToLoad definitions
		keysAndValuesDo: [ :projectName :projectDefinition | 
			projectDefinition packages
				keysAndValuesDo: [ :packageName :packageDefinition | 
					"set the target symbol dictionary name for each incoming package definition"
					(packageDefinition gs_symbolDictionary isNil
						or: [ 
							(loadedProjectInfo includesKey: projectName)
								or: [ 
									(projectDefinition projectDefinitionSourceProperty
										= RwLoadedProject _projectLoadedDefinitionSourceValue) not ] ])
						ifTrue: [ 
							"set gs_symbolDictionary for the first time, or (potentially) override if project freshly read 
								from disk (loadedProjectInfo available)"
							packageDefinition
								gs_symbolDictionary:
									(projectDefinition symbolDictNameForPackageNamed: packageName) ] ] ].
	diff := projectSetDefinitionToLoad
		compareAgainstBase: loadedProjectDefinitionSet.
	diff isEmpty
		ifFalse: [ Rowan image applyModification_254: diff instanceMigrator: instanceMigrator ].
	loadedProjects := Array new.
	projectSetDefinitionToLoad definitions
		do: [ :projectDef | 
			| theLoadedProject |
			loadedProjects add: (RwProject newNamed: projectDef name).
			theLoadedProject := Rowan image loadedProjectNamed: projectDef name.
			projectDef projectDefinitionSourceProperty
				= RwLoadedProject _projectDiskDefinitionSourceValue
				ifTrue: [ 
					theLoadedProject
						updateLoadedCommitId;
						markNotDirty.
					theLoadedProject loadedPackages
						valuesDo: [ :loadedPackage | loadedPackage markNotDirty ] ].
			(loadedProjectInfo at: projectDef name ifAbsent: [  ])
				ifNotNil: [ :map | projectDef updateLoadedComponentInfoFor: theLoadedProject from: map ] ].
	^ loadedProjects
]

{ #category : 'load project definitions' }
RwPrjLoadToolV2 >> loadProjectDefinition: projectDefinition [
	^ self
		loadProjectDefinition: projectDefinition
		platformConfigurationAttributes: Rowan platformConfigurationAttributes
		instanceMigrator: Rowan platform instanceMigrator
]

{ #category : 'load project definitions' }
RwPrjLoadToolV2 >> loadProjectDefinition: projectDefinition instanceMigrator: instanceMigrator [
	^ self
		loadProjectDefinition: projectDefinition
		platformConfigurationAttributes: Rowan platformConfigurationAttributes
		instanceMigrator: instanceMigrator
]

{ #category : 'load project definitions' }
RwPrjLoadToolV2 >> loadProjectDefinition: projectDefinition platformConfigurationAttributes: platformConfigurationAttributes [
	"read the configurations for <projectDefinition> to develop the list of dependent projects"

	^ self
		loadProjectDefinition: projectDefinition
		platformConfigurationAttributes: platformConfigurationAttributes
		instanceMigrator: Rowan platform instanceMigrator
]

{ #category : 'load project definitions' }
RwPrjLoadToolV2 >> loadProjectDefinition: projectDefinition platformConfigurationAttributes: platformConfigurationAttributes instanceMigrator: instanceMigrator [
	"read the configurations for <projectDefinition> to develop the list of dependent projects"

	| projectSetDefinition sourceProperty rereadProject |
	sourceProperty := projectDefinition projectDefinitionSourceProperty.
	rereadProject := sourceProperty
		~= RwLoadedProject _projectSourceValueNewProject
		and: [ sourceProperty ~= RwLoadedProject _projectDiskDefinitionSourceValue ].
	projectSetDefinition := (projectDefinition repositoryRoot exists
		and: [ rereadProject ])
		ifTrue: [ 
			"only read from disk if the repository exists and the project definition has not 
				already been loaded from disk"
			Rowan projectTools read
				readProjectSetForComponentProjectDefinition: projectDefinition
				withConfigurations: projectDefinition loadedConfigurationNames
				groupNames: projectDefinition loadedGroupNames
				platformConfigurationAttributes: platformConfigurationAttributes ]
		ifFalse: [ 
			"If this project definition _was_ read from disk, we cannot trust that it was 
				not modified, so clear source property"
			projectDefinition projectDefinitionSourceProperty: nil.
			RwProjectSetDefinition new
				addProject: projectDefinition;
				yourself ].
	^ self
		loadProjectSetDefinition: projectSetDefinition
		instanceMigrator: instanceMigrator
]

{ #category : 'load project definitions' }
RwPrjLoadToolV2 >> loadProjectSetDefinition: projectSetDefinitionToLoad [

	^ self
		loadProjectSetDefinition: projectSetDefinitionToLoad
		instanceMigrator: Rowan platform instanceMigrator
]

{ #category : 'load project definitions' }
RwPrjLoadToolV2 >> loadProjectSetDefinition: projectSetDefinition instanceMigrator: instanceMigrator [

	"NOTE: when loading a definition into a stone, the loaded things are not marked as non-dirty ... dirty state is relative to the disk image for a
		project and a definition can have come from anywhere"

	^ self 
		_doProjectSetLoad: projectSetDefinition
		instanceMigrator: instanceMigrator 
		originalProjectSet: projectSetDefinition 
		processedClassNames: Set new
]