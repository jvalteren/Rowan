Class {
	#name : 'RwProjectLoadComponentVisitor',
	#superclass : 'RwProjectLoadConfigurationVisitor',
	#instVars : [
		'projectNames',
		'projectBasePath'
	],
	#category : 'Rowan-Components'
}

{ #category : 'private' }
RwProjectLoadComponentVisitor >> _projects: projectDirPath forProject: aProjectName [

	| urlBase |
	self projectNames isEmpty ifTrue: [ ^ #() ].
	urlBase := 'file:' ,projectDirPath asFileReference pathString, '/'.
	^ self projectNames
		collect: [ :prjName | 
			| url |
			url := urlBase , prjName , '.ston'.
self error: 'now which class are we expecting here? ... does it matter?'.
			(RwAbstractProjectConfiguration fromUrl: url)
				projectName: aProjectName;
				yourself ]
]

{ #category : 'initialization' }
RwProjectLoadComponentVisitor >> initialize [

	super initialize.
	projectNames := Set new.
]

{ #category : 'accessing' }
RwProjectLoadComponentVisitor >> projectBasePath [

	^ projectBasePath
]

{ #category : 'accessing' }
RwProjectLoadComponentVisitor >> projectBasePath: aString [

	projectBasePath := aString
]

{ #category : 'accessing' }
RwProjectLoadComponentVisitor >> projectNames [

	^ projectNames
]

{ #category : 'visiting' }
RwProjectLoadComponentVisitor >> visitComponentLoadConfiguration: aComponentLoadConfiguration [

	| seedGroupNames |
	(visitedConfigurationNames includes: aComponentLoadConfiguration name)
		ifTrue: [ ^ self ].

	self _visited: aComponentLoadConfiguration. 

	definedGroupNames := aComponentLoadConfiguration definedGroupNames.
	seedGroupNames := groupNames asSet copy.
	[seedGroupNames isEmpty ]
		whileFalse: [ 
			seedGroupNames copy do: [:groupName |
				| referencedGroupNames |
				"make sure that required groups are included in group names, recursively"
				seedGroupNames remove: groupName.
				referencedGroupNames := definedGroupNames at: groupName ifAbsent: [ #() ].
				groupNames addAll: referencedGroupNames.
				seedGroupNames addAll: referencedGroupNames ] ].

	self _processConditionalPackageNames: aComponentLoadConfiguration.

	self _processConditionalPackageMapSpecs: aComponentLoadConfiguration.

	self configurationNames addAll: aComponentLoadConfiguration configurationNames.
	(self _configurations: self configurationBasePath, '/' forProject: aComponentLoadConfiguration projectName)
		do: [:config | config acceptNestedVisitor: self ].

	self projectNames addAll: aComponentLoadConfiguration projectNames.
	(self _projects: self projectBasePath, '/' forProject: aComponentLoadConfiguration projectName)
		do: [:projectReference | projectReference acceptVisitor: self ].
]