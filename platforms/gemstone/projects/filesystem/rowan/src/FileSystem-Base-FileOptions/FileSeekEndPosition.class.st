"
SEEK_END  It moves file pointer position to the end of file.
"
Class {
	#name : 'FileSeekEndPosition',
	#superclass : 'FilePositioning',
	#category : 'FileSystem-Base-FileOptions'
}

{ #category : 'accessing' }
FileSeekEndPosition class >> defaultPlatformValue [
	^2
]

{ #category : 'accessing' }
FileSeekEndPosition class >> posixName [
	^'SEEK_END'
]