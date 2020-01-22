Class {
	#name : 'RwRepositoryResolvedProjectTonelReaderVisitorV2',
	#superclass : 'RwRepositoryComponentProjectReaderVisitor',
	#category : 'Rowan-DefinitionsV2'
}

{ #category : 'class file reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 class >> lineNumberStringForMethod: anRwMethodDefinition [
  "used when handling STONReaderError,  TonelParseError, CompileError, CompileWarning"
	(anRwMethodDefinition propertyAt:'_gsFileOffset' ifAbsent: nil) ifNotNil:[:offset |
		 (anRwMethodDefinition propertyAt:'_gsFileName' ifAbsent: nil) ifNotNil:[:fName | 
			 ^ self lineNumberStringForOffset: offset fileName: fName
			] 
	].
  ^ '  (Unable to determine line )' .
]

{ #category : 'class file reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 class >> lineNumberStringForOffset: offset fileName: fName [
  | res |
  res :='  (Unable to determine line number)' .
  [ | fRef |
    fRef := fName asFileReference .
    fRef readStreamDo:[ :fStream |  | buf lf lNum |
      buf := fStream contents .
      buf size > offset ifTrue:[ buf size: offset ].
      lNum := 1 + (buf occurrencesOf: (lf := Character lf)) .
      res := '', lf , ' near line ' , lNum asString , lf , ' in file ', fName .
    ]
  ] on: Error do:[:ex | "ignore" ].
  ^ res
]

{ #category : 'class file reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 class >> readClassFile: file [

	^ self readClassFiles: { file }
]

{ #category : 'class file reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 class >> readClassFile: file projectName: projectName packageName: packageName [

	^ self readClassFiles: { file } projectName: projectName packageName: packageName
]

{ #category : 'class file reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 class >> readClassFiles: fileArray [

	^ self readClassFiles: fileArray projectName: '___READ_CLASS_Project___' packageName: '___READ_CLASS_Package___'
]

{ #category : 'class file reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 class >> readClassFiles: fileArray projectName: projectName packageName: packageName [
	| visitor resolvedProject packageDefinition |
	resolvedProject := RwResolvedProjectV2 new
		projectName: projectName;
		packageConvention: 'Rowan';
		gemstoneSetDefaultSymbolDictNameTo: 'Globals';
		yourself.
	resolvedProject
		addComponentNamed: 'Core'
		definedGroupNames:
			(Dictionary new
				add: 'core' -> {};
				yourself)
		comment: 'Temporary project to hold class definitions read from disk'.
	1 to: fileArray size do: [ :index | 
		| file |
		file := fileArray at: index.
		packageDefinition := resolvedProject
			addPackageNamed: packageName , '_' , index asString
			toComponentNamed: 'Core'
			withConditions: {'common'}
			andGroupName: 'core'.
		visitor := self new
			currentProjectDefinition: resolvedProject;
			currentPackageDefinition: packageDefinition;
			_packageConvention: 'Rowan';
			yourself.
		visitor readClassFile: file inPackage: packageDefinition name ].
	^ resolvedProject
]

{ #category : 'package reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> _packageNameFromPackageDir: packageDir [

	"this is not really correct, but it works as a fallback (filetree does not have independent package name)"

	^ (self _readObjectFrom: (packageDir / 'package', 'st')) at: #name
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> checkMethodDefinitions: aClassDef [
  | cls clsName methBlk fakeMethDict pkgName |

  self compileWhileReading ifFalse:[ ^ self "do nothing"  ].

  clsName := aClassDef  name asSymbol .
  (pkgName := currentPackageDefinition name) = 'Filein1C' ifTrue:[ 
     "lookup in GemStone_Legacy_Streams first"
     cls := GemStone_Legacy_Streams at: clsName otherwise: nil.
  ].
  cls ifNil:[   
    (cls := System myUserProfile resolveSymbol: clsName ) ifNil:[
       "creating the class not implemented yet"
       Warning signal:'class ' , clsName , ' not found by name lookup'.
       ^ self "can't check syntax on the methods until class is defined"
    ].
  ].
  cls := cls"anAssociation" value.
  methBlk := [ :methDef "a RwMethodDefinition" |
    [
      cls compileMethod: methDef source
      dictionaries: System myUserProfile symbolList
      category: methDef protocol asSymbol
      intoMethodDict: fakeMethDict
      intoCategories: nil
      intoPragmas: nil
      environmentId:  0
    ] on: ( CompileError , CompileWarning ) do:[:ex | 
      ex addText: (RwRepositoryResolvedProjectTonelReaderVisitorV2 lineNumberStringForMethod: methDef ).
      ex pass
    ]
  ].
  fakeMethDict := GsMethodDictionary new .
  aClassDef instanceMethodDefinitions do: methBlk .
  cls := cls class .
  fakeMethDict := GsMethodDictionary new .
  aClassDef classMethodDefinitions do: methBlk .
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> classExtensionFileExtensions [

	^ #( 'extension' 'st' )
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> classFileExtensions [

	^ #( 'class' 'st' )
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> compileWhileReading [
  ^ (self dynamicInstVarAt: #compileWhileReading) ifNil:[ false ]
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> compileWhileReading: aBoolean [
  self dynamicInstVarAt: #compileWhileReading put: aBoolean 
]

{ #category : 'tonel parser' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> definitionForType: aString [
  aString = TonelWriter classLabel
    ifTrue: [ ^ #class ].
  aString = TonelWriter extensionLabel
    ifTrue: [ ^ #classExtension ].
  TonelParseError signal: 'Unknown type declaration.'
]

{ #category : 'tonel parser' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> newMethodDefinitionForClassNamed: className classIsMeta: meta selector: selector category: protocol source: source [

	| methodDef |
	methodDef := RwMethodDefinition
		newForSelector: selector 
			protocol: protocol 
			source: source.
	self 
		validateMethodDefinitionProtocol: methodDef 
			className: className
			isMeta: meta
			forPackageNamed: self currentPackageDefinition name.
	^ methodDef
]

{ #category : 'tonel parser' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> newTypeDefinitionFrom: anArray [
  | typeClass |
  typeClass := self definitionForType: anArray fourth.
  typeClass == #class
    ifTrue: [ ^  self newClassDefinitionFrom: anArray ].
  typeClass == #classExtension
	ifTrue: [ ^ self newClassExtensionDefinitionFrom: anArray ].
  ^ self error: 'unexpected typeClass: ', typeClass printString
]

{ #category : 'package reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> packageExtension [

	^ ''
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> readClassesFor: packageName packageRoot: packageRoot [

	| classFileExtensions classExtensionFileExtensions trace |
  trace := SessionTemps current at: #ROWAN_TRACE otherwise: nil .
	currentPackageDefinition := currentProjectDefinition 
		packageNamed: packageName 
		ifAbsent: [ currentProjectDefinition addRawPackageNamed: packageName ].
	classExtensionFileExtensions := self classExtensionFileExtensions.
	classFileExtensions := self classFileExtensions.
	packageRoot files do: [:file |
		| fileExtensions |
    trace == #gciLogServer ifTrue:[ GsFile gciLogServer: '--- reading ', file asString ].
		fileExtensions := file extensions asArray.
		fileExtensions = classFileExtensions
			ifTrue: [ self readClassFile: file inPackage: packageName ]
			ifFalse: [
				fileExtensions = classExtensionFileExtensions
					ifTrue: [ self readClassExtensionFile: file  inPackage: packageName ] ] ]
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> readClassExtensionFile: file inPackage: packageName [

	| fileReference |
	fileReference := file asFileReference.
	fileReference readStreamDo: [:fileStream | | stream |
		[ | definitions |
		  stream := ZnBufferedReadStream on: fileStream. "wrap with buffered stream to bypass https://github.com/GemTalk/FileSystemGs/issues/9"
		  stream sizeBuffer: fileReference size. "part of workaround for GemTalk/FileSystemGs#9"
		  definitions := (TonelParser on: stream forReader: self) start.
		  ((definitions at: 2) at: 1) do: [:mDef |
			  currentClassExtension addClassMethodDefinition: mDef ].
		  ((definitions at: 2) at: 2) do: [:mDef |
			  currentClassExtension addInstanceMethodDefinition: mDef ] .
      self checkMethodDefinitions: currentClassExtension .
    ] on: ( STONReaderError , TonelParseError) do:[:ex |
      ex addText: (self class lineNumberStringForOffset: stream position fileName: fileReference fullName).
      ex pass .
    ].
  ].
]

{ #category : 'class reading' }
RwRepositoryResolvedProjectTonelReaderVisitorV2 >> readClassFile: file inPackage: packageName [
	| fileReference |
	fileReference := file asFileReference.
	fileReference readStreamDo: [:fileStream | | stream |
    [
		  | definitions clsDef projectDef |
      "wrap with buffered stream to bypass https://github.com/GemTalk/FileSystemGs/issues/9"
		  stream := ZnBufferedReadStream on: fileStream. 
		  stream sizeBuffer: fileReference size. "part of workaround for GemTalk/FileSystemGs#9"
		  definitions := (TonelParser on: stream forReader: self) start.
      clsDef := currentClassDefinition ifNotNil:[:def |
                  currentClassExtension ifNotNil:[ 
                    Error signal:'both a class definition and extension in file ', file name ].
                  def
                ] ifNil:[ currentClassExtension ].
		  self validateClassCategory: clsDef forPackageNamed: packageName.
		  ((definitions at: 2) at: 1) do: [:mDef |
			  clsDef addClassMethodDefinition: mDef ].
		  ((definitions at: 2) at: 2) do: [:mDef |
			  clsDef addInstanceMethodDefinition: mDef ].
      self checkMethodDefinitions: clsDef .
		  projectDef := currentProjectDefinition packageNamed: packageName .
      currentClassDefinition ifNotNil:[ projectDef addClassDefinition: clsDef ] .
                             "ifNil:[ projectDef addClassExtensionDefinition: clsDef]."
    ] on: ( STONReaderError , TonelParseError) do:[:ex |
      ex addText: (self class lineNumberStringForOffset: stream position fileName: fileReference fullName).
      ex pass .
    ].
  ].
]