"
Specifies permission for users in the file other class either:

-   To read, write, and search, if the file is a directory
-   To read, write, and execute, for a file other than a directory

This value has the same effect as specifying all three parameters (SIROTH, SIWOTH, and SIXOTH).
"
Class {
	#name : 'FileOtherAllPermissionFlag',
	#superclass : 'FilePermissionFlag',
	#category : 'FileSystem-Disk-Options'
}

{ #category : 'accessing' }
FileOtherAllPermissionFlag class >> defaultPlatformValue [
	^16r007
]

{ #category : 'accessing' }
FileOtherAllPermissionFlag class >> posixName [
	^'SIRWXO'
]

{ #category : 'accessing' }
FileOtherAllPermissionFlag class >> windowsValue [
	^0
]