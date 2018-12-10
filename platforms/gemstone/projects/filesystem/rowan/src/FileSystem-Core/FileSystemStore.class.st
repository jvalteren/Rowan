"
I am an abstract superclass for store implementations. My subclasses provide access to the actual data storage of a particular kind of filesystem. 

The file system can be accessed via
	FileSystem disk 
	FileSystem memory
	
My associated filesystem can be accessed as follows:
      DiskStore currentFileSystem
"
Class {
	#name : 'FileSystemStore',
	#superclass : 'Object',
	#category : 'FileSystem-Core-Kernel'
}

{ #category : 'accessing' }
FileSystemStore class >> delimiter [
	^ self shouldBeImplemented 
]

{ #category : 'accessing' }
FileSystemStore class >> isCaseSensitive [
	^ self shouldBeImplemented
]

{ #category : 'instance creation' }
FileSystemStore class >> new [

	^self basicNew
		initialize;
		yourself
]

{ #category : 'accessing' }
FileSystemStore class >> osName [
	^System gemVersionAt: 'osName'
]

{ #category : 'accessing' }
FileSystemStore class >> separator [
	self shouldBeImplemented
]

{ #category : 'modes' }
FileSystemStore >> appendAndReadMode [
	"Open for reading and appending (writing at end of file).  The
     file is created if it does not exist.  The initial file
     position for reading is at the beginning of the file, but
     output is always appended to the end of the file."
	^FileAppendAndReadMode new
]

{ #category : 'modes' }
FileSystemStore >> appendBinaryAndReadMode [
	"Open for reading and appending (writing at end of file).  The
     file is created if it does not exist.  The initial file
     position for reading is at the beginning of the file, but
     output is always appended to the end of the file."
	^FileAppendAndReadBinaryMode new
]

{ #category : 'modes' }
FileSystemStore >> appendBinaryMode [
	"Open for appending (writing at end of file).  The file is
     created if it does not exist.  The stream is positioned at the
     end of the file."
	^FileAppendBinaryMode new
]

{ #category : 'modes' }
FileSystemStore >> appendMode [
	"Open for appending (writing at end of file).  The file is
     created if it does not exist.  The stream is positioned at the
     end of the file."
	^FileAppendMode new
]

{ #category : 'public' }
FileSystemStore >> basenameFromEntry: aNode [
	"Used to extract the basename from the low-level representation (node / entry) from the store."
	self subclassResponsibility
]

{ #category : 'abstract' }
FileSystemStore >> basicCreationTimeOf: aNode [
	"Used to decide whether the low-level representation (node / entry) from the store is a readable
	file or a directory whose contents can be listed."
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> basicEntry: directoryEntry path: aPath nodesDo: aBlock [
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> basicIsDirectory: aNode [
	"Used to decide whether the low-level representation (node / entry) from the store is a directory.
	This private message should only be called form within the store."
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> basicIsFile: aNode [
	"Used to decide whether the low-level representation (node / entry) from the store is a file.
	This private message should only be called form within the store."
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> basicIsSymlink: aNode [
	^self subclassResponsibility 
	
]

{ #category : 'abstract' }
FileSystemStore >> basicIsWritable: aNode [
	"Used to decide whether the low-level representation (node / entry) from the store is 
	a writable file or can be changed."
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> basicModificationTime: aNode [
	"Used to decide whether the low-level representation (node / entry) from the store is a readable
	file or a directory whose contents can be listed."
	self subclassResponsibility 
]

{ #category : 'error signalling' }
FileSystemStore >> basicOpen: aPath writable: aBoolean [
	"open the file at the given path and return an identifier"
	self subclassResponsibility
]

{ #category : 'abstract' }
FileSystemStore >> basicPosixPermissions: aNode [
	"Used to get the posix permissions from a low-level filesystem entry / node"
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> basicSizeOf: aNode [
	"Used to get the size of the low-level representation (node / entry) "
	self subclassResponsibility 
]

{ #category : 'public' }
FileSystemStore >> checkName: aString fixErrors: fixErrors [
	^ self subclassResponsibility
]

{ #category : 'abstract' }
FileSystemStore >> close [
	"Some kinds of filesystems need to open connections to external resources"
]

{ #category : 'private' }
FileSystemStore >> copy: sourcePath ifAbsent: absentBlock to: destinationPath ifPresent: presentBlock fileSystem: aFilesystem [

	| buffer out in |
	
	in := nil.
	out := nil.
	buffer := nil.
	[
		in := aFilesystem binaryReadStreamOn: sourcePath.
		in ifNil: [ ^ absentBlock value ].
		
		(self exists: destinationPath)
			ifTrue: [ "cannot overwrite destination"
				^ presentBlock value ].
			
		out := aFilesystem binaryWriteStreamOn: destinationPath.
		buffer := ByteArray new: 1024.
		
		[ in atEnd ]
			whileFalse: [ 
				buffer := in nextInto: buffer.
				out nextPutAll: buffer ]]
	ensure: [ 
		in ifNotNil: [ in close ].
		out ifNotNil: [ out close ]]
]

{ #category : 'abstract' }
FileSystemStore >> createDirectory: aPath [
	self subclassResponsibility 
]

{ #category : 'public' }
FileSystemStore >> creationTimeOf: aPath [
	"Return the date of creation of the File described by aPath"
	^ self 
		nodeAt: aPath 
		ifPresent: [ :entry | self basicCreationTimeOf: entry ] 
		ifAbsent: [ self signalFileDoesNotExist: aPath ].
	
]

{ #category : 'accessing' }
FileSystemStore >> defaultWorkingDirectory [
	^ Path root
]

{ #category : 'abstract' }
FileSystemStore >> delete: aPath [
	self subclassResponsibility 
]

{ #category : 'accessing' }
FileSystemStore >> delimiter [
	^ self class delimiter
]

{ #category : 'public' }
FileSystemStore >> directoryAt: aPath ifAbsent: absentBlock directoryNodesDo: aBlock [
	^ self 
		directoryAt: aPath 
		ifAbsent: absentBlock 
		nodesDo: [ :entry|
			(self basicIsDirectory: entry) 
				ifTrue: [ aBlock value: entry ]].
]

{ #category : 'public' }
FileSystemStore >> directoryAt: aPath ifAbsent: absentBlock fileNodesDo: aBlock [
	^ self 
		directoryAt: aPath 
		ifAbsent: absentBlock 
		nodesDo: [ :entry|
			(self basicIsDirectory: entry) 
				ifFalse: [ aBlock value: entry ]].
]

{ #category : 'public' }
FileSystemStore >> directoryAt: aPath ifAbsent: absentBlock nodesDo: aBlock [
	^ self
		nodeAt: aPath
		ifPresent: [ :entry | 
			(self basicIsDirectory: entry)
				ifTrue: [ self basicEntry: entry path: aPath nodesDo: aBlock ]
				ifFalse: [ DirectoryDoesNotExist signalWith: aPath ] ]
		ifAbsent: absentBlock
]

{ #category : 'public' }
FileSystemStore >> ensureCreateDirectory: aPath [
	(self isDirectory: aPath) ifTrue: [ ^ self ].
	self ensureCreateDirectory: aPath parent.
	self createDirectory: aPath
]

{ #category : 'private' }
FileSystemStore >> entryFromNode: aNode fileSystem: aFilesystem path: aPath [
	^ FileSystemDirectoryEntry
		fileSystem: aFilesystem
		path: aPath
		creation: (self basicCreationTimeOf: aNode)
		modification:(self basicModificationTimeOf: aNode)
		isDir: (self basicIsDirectory: aNode)
		size: (self basicSizeOf: aNode)
		posixPermissions: (self basicPosixPermissions: aNode)
		isSymlink: (self basicIsSymlink: aNode)
]

{ #category : 'public' }
FileSystemStore >> entryFromNode: node path: path for: aFileystem [
	| entryPath |
	entryPath := path / (self basenameFromEntry: node).
	^ self entryFromNode: node fileSystem: aFileystem path: entryPath
]

{ #category : 'public' }
FileSystemStore >> exists: aPath [
	self 
		nodeAt: aPath 
		ifPresent: [ :entry | ^ true ] 
		ifAbsent: [ ^ false ].
	
]

{ #category : 'private' }
FileSystemStore >> filename: aByteString matches: aByteString2 [
	^ aByteString = aByteString2
]

{ #category : 'initialization' }
FileSystemStore >> initialize [
]

{ #category : 'accessing' }
FileSystemStore >> isCaseSensitive [
	^ self class isCaseSensitive
]

{ #category : 'public' }
FileSystemStore >> isDirectory: aPath [
	aPath isRoot ifTrue: [ ^ true ].
	self 
		nodeAt: aPath 
		ifPresent: [ :entry | ^ self basicIsDirectory: entry ] 
		ifAbsent: [ ^ false ].
	
]

{ #category : 'public' }
FileSystemStore >> isFile: aPath [
	"slow solution for big directories! "
	^ self 
		nodeAt: aPath 
		ifPresent: [ :entry | ^ self basicIsFile: entry ] 
		ifAbsent: [ ^ false ]
	
]

{ #category : 'public' }
FileSystemStore >> isSymlink: aPath [
	aPath isRoot ifTrue: [ ^ true ].
	self 
		nodeAt: aPath 
		ifPresent: [ :entry | ^ self basicIsSymlink: entry ] 
		ifAbsent: [ ^ false ].
	
]

{ #category : 'public' }
FileSystemStore >> isWritable: aPath [
	self nodeAt: aPath 
		ifPresent: [ :entry | ^ self basicIsWritable: entry ] 
		ifAbsent: [ ^ false ].
	
]

{ #category : 'public' }
FileSystemStore >> modificationTimeOf: aPath [
	"Returns the last date of modification of the File described by aPath"
	^ self 
		nodeAt: aPath 
		ifPresent: [ :entry | self basicModificationTimeOf: entry ] 
		ifAbsent: [ self signalFileDoesNotExist: aPath ].
	
]

{ #category : 'public' }
FileSystemStore >> nodeAt: aPath [
	^ self 
		nodeAt: aPath 
		ifPresent: [ :node| node ]
		ifAbsent: [ self error: 'the node ', aPath printString, ' not found.' ]
]

{ #category : 'abstract' }
FileSystemStore >> nodeAt: aPath ifPresent: presentBlock ifAbsent: absentBlock [
	self subclassResponsibility 
]

{ #category : 'abstract' }
FileSystemStore >> open [
	"Some kinds of filesystems need to open connections to external resources"
]

{ #category : 'public' }
FileSystemStore >> openFileStream: path writable: writable [
	self subclassResponsibility
]

{ #category : 'converting' }
FileSystemStore >> pathFromString: aString [
	"Use the unix convention by default, since many filesystems are based on it."
	
	^ Path from: aString delimiter: self delimiter
]

{ #category : 'public' }
FileSystemStore >> permissions: aPath [
	self nodeAt: aPath 
		ifPresent: [ :entry | ^ FileSystemPermission posixPermissions: (self basicPosixPermissions: entry) ] 
		ifAbsent: [ ^ FileSystemPermission default ].
	
]

{ #category : 'converting' }
FileSystemStore >> printPath: aPath on: out [
	"Use the unix convention by default, since it's the most common."
	
	aPath isAbsolute ifTrue: [ out nextPut: self delimiter ].
	^ aPath printOn: out delimiter: self delimiter
]

{ #category : 'modes' }
FileSystemStore >> readBinaryMode [
	"Open binary for reading and writing.  The stream is positioned at the beginning of the file."
	^FileReadBinaryMode new
]

{ #category : 'modes' }
FileSystemStore >> readMode [
	"Open for reading and writing.  The stream is positioned at the beginning of the file."
	^FileReadMode new
]

{ #category : 'modes' }
FileSystemStore >> readWriteBinaryMode [
	"Open binary file for reading and writing.  The stream is positioned at the beginning of the file."
	^FileReadBinaryMode new
]

{ #category : 'modes' }
FileSystemStore >> readWriteBinaryTruncatedMode [
	"Open binary file for reading and writing.  The file is created if it does
      not exist, otherwise it is truncated.  The stream is
      positioned at the beginning of the file."
	^FileReadWriteTruncatedBinaryMode new
]

{ #category : 'modes' }
FileSystemStore >> readWriteMode [
	"Open for reading and writing.  The stream is positioned at the beginning of the file."
	^FileReadWriteMode new
]

{ #category : 'modes' }
FileSystemStore >> readWriteTruncatedMode [
	"Open for reading and writing.  The file is created if it does
      not exist, otherwise it is truncated.  The stream is
      positioned at the beginning of the file."
	^FileReadWriteTruncatedMode new
]

{ #category : 'private' }
FileSystemStore >> rename: sourcePath ifAbsent: absentBlock to: destinationPath ifPresent: presentBlock fileSystem: anFSFilesystem [

	| result |
	(self exists: destinationPath) ifTrue: [ ^ presentBlock value ].
	(self exists: sourcePath) ifFalse: [ ^ absentBlock value ].
	result := self rename: sourcePath to: destinationPath.
	result ifNil: [ self primitiveFailed ].
	^ self.
]

{ #category : 'abstract' }
FileSystemStore >> rename: sourcePath to: destinationPath [
	self subclassResponsibility 
]

{ #category : 'accessing' }
FileSystemStore >> separator [
	^ self class separator
]

{ #category : 'error signalling' }
FileSystemStore >> signalDirectoryDoesNotExist: aPath [
	^ DirectoryDoesNotExist signalWith: aPath
]

{ #category : 'error signalling' }
FileSystemStore >> signalDirectoryExists: aPath [
	^ DirectoryExists signalWith: aPath
]

{ #category : 'error signalling' }
FileSystemStore >> signalFileDoesNotExist: aPath [
	^ FileDoesNotExist
		signalWith: aPath
]

{ #category : 'error signalling' }
FileSystemStore >> signalFileExists: aPath [
	^ FileExists signalWith: aPath
]

{ #category : 'public' }
FileSystemStore >> sizeOf: aPath [
	"Return the size of the File described by aPath"
	^ self 
		nodeAt: aPath 
		ifPresent: [ :entry | self basicSizeOf: entry ] 
		ifAbsent: [ self signalFileDoesNotExist: aPath ]
	
]

{ #category : 'converting' }
FileSystemStore >> stringFromPath: aPath [
	^ String streamContents: [ :out | 
		self printPath: aPath on: out ]
]

{ #category : 'modes' }
FileSystemStore >> writeBinaryMode [
	"Truncate binary file to zero length or create text file for writing. 
	 The stream is positioned at the beginning of the file."
	^FileWriteBinaryMode new
]

{ #category : 'modes' }
FileSystemStore >> writeMode [
	"Truncate file to zero length or create text file for writing. 
	 The stream is positioned at the beginning of the file."
	^FileWriteMode new
]