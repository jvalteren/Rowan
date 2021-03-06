Class {
	#name : 'RwClsExtensionAuditTool',
	#superclass : 'RwClsAuditTool',
	#category : 'Rowan-Tools-Core'
}

{ #category : 'other' }
RwClsExtensionAuditTool >> _auditCategory: anExtentionCategory forBehavior: aClassOrMeta loadedClass: aLoadedClassExtension [
"if we have loaded methods but no compiled methods add error to result"
| res |
	res := super _auditCategory: anExtentionCategory selectors:  (aClassOrMeta selectorsIn: anExtentionCategory) forBehavior: aClassOrMeta loadedClass: aLoadedClassExtension.
	aClassOrMeta isMeta 
		ifTrue: [
			(aLoadedClassExtension loadedClassMethods notEmpty and: [(aClassOrMeta selectorsIn: anExtentionCategory) isEmpty])
				ifTrue: [ self errorLog: res  add: ((aLoadedClassExtension name , ' #' ,anExtentionCategory asString -> 'Missing expected class methods in the category '))   ].
	] 	ifFalse: [
			(aLoadedClassExtension loadedInstanceMethods notEmpty and: [(aClassOrMeta selectorsIn: anExtentionCategory) isEmpty])
				ifTrue: [ self errorLog: res  add: (aLoadedClassExtension name , ' #' ,anExtentionCategory asString -> ('Missing expected instances methods in the category'))   ].
	].
	^res

]

{ #category : 'other' }
RwClsExtensionAuditTool >> auditLoadedClassExtension: aLoadedClassExtension [
"look for methods compiled into class without Rowan API"
| res   extensionCategoryName|

	res := self _result.
	extensionCategoryName :=  aLoadedClassExtension loadedPackage asExtensionName "'*' , aLoadedClassExtension loadedPackage name" .
	(Rowan globalNamed: aLoadedClassExtension name) 
		ifNil: [self errorLog: res  add: aLoadedClassExtension name -> ' Class does not exists for loaded class '] 
		ifNotNil: [:aBehavior ||categories | 
					
				aBehavior == aLoadedClassExtension handle
					ifFalse: [ 
						self
							errorLog: res
							add:
								(aLoadedClassExtension name , ' #' , extensionCategoryName)
									->
										(' loaded extension class (' , aLoadedClassExtension handle asOop printString
										, ') not latest version of class ('
										, aBehavior asOop printString , ') ') ].

				categories := (aBehavior _baseCategorys: 0) keys.
				(categories	
					detect: [:each | each equalsNoCase: extensionCategoryName ] ifNone: [ ])
						ifNotNil: [:aCategory | self errorLog: res  addAll:  (self _auditCategory: aCategory forBehavior: aBehavior loadedClass: aLoadedClassExtension)]
						ifNil: [aLoadedClassExtension loadedInstanceMethods notEmpty ifTrue: [
							self errorLog: res add: aLoadedClassExtension name , ' #' ,extensionCategoryName -> 'Missing instance method extension category ']
			].


			categories := (aBehavior class _baseCategorys: 0) keys.
			(categories
				detect: [:each | each equalsNoCase: extensionCategoryName ] ifNone: [ ])
					ifNotNil: [:aCategory | self errorLog: res  addAll:  (self _auditCategory: aCategory forBehavior: aBehavior class loadedClass: aLoadedClassExtension)]
					ifNil: [aLoadedClassExtension loadedClassMethods notEmpty ifTrue: [
						self errorLog: res add: aLoadedClassExtension name , ' #' ,extensionCategoryName -> 'Missing class method extension category ']
			].

		
			aLoadedClassExtension 
				loadedInstanceMethodsDo: [:loadedProject :loadedPackage :loadedClass :aLoadedMethod | 
					(self _auditLoadedInstanceMethod: aLoadedMethod forBehavior: aBehavior loadedClass: loadedClass) ifNotNil: [:x | self errorLog: res add: x]
				] 
				loadedClassMethodsDo: [:loadedProject :loadedPackage :loadedClass :aLoadedMethod |
					(self _auditLoadedClassMethod: aLoadedMethod forBehavior: aBehavior class loadedClass: loadedClass) ifNotNil: [:x |self errorLog: res add: x]
				]
		].
		^res
]
