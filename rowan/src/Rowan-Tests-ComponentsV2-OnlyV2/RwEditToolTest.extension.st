Extension { #name : 'RwEditToolTest' }

{ #category : '*rowan-tests-componentsv2-onlyv2' }
RwEditToolTest >> _standardProjectDefinition: projectName packageNames: packageNames defaultSymbolDictName: defaultSymbolDictName comment: comment [

	| projectDefinition |
	projectDefinition := (Rowan globalNamed: 'RwProjectDefinition')
		newForGitBasedProjectNamed: projectName.
	projectDefinition
		comment: comment;
		packageNames: packageNames;
		yourself.
	projectDefinition defaultSymbolDictName: defaultSymbolDictName.

	^ projectDefinition
]