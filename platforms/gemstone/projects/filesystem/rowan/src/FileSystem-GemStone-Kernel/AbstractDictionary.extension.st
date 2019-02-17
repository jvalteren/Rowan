Extension { #name : 'AbstractDictionary' }

{ #category : '*filesystem-gemstone-kernel' }
AbstractDictionary >> at: key ifPresent: aBlock [
	"Lookup the given key in the receiver. If it is present, answer the
	value of evaluating the given block optionally with the value associated
	with the key.
	Otherwise, answer nil."

	^(self at: key ifAbsent: [])
		ifNotNil: [:aValue | aBlock cull: aValue]
]

{ #category : '*filesystem-gemstone-kernel' }
AbstractDictionary >> fillFrom: aCollection with: aBlock [
	"Evaluate aBlock with each of aCollections's elements as the argument.  
	Collect the resulting values into self. Answer self."

	aCollection keysAndValuesDo: [ :key :value |
		self at: key put: (aBlock value: value) ]
]

{ #category : '*filesystem-gemstone-kernel' }
AbstractDictionary >> removeAll [

	self removeAllKeys: self keys
]

{ #category : '*filesystem-gemstone-kernel' }
AbstractDictionary class >> newFromPairs: anArray [
	"Answer an instance of me associating (anArray at: i) to (anArray at: i+1)
	 for each odd i.  anArray must have an even number of entries."

	"Dictionary newFromPairs: {'Red' . Color red . 'Blue' . Color blue . 'Green' . Color green}."

	| newDictionary |
	newDictionary := self new: anArray size / 2.
	1 to: anArray size - 1 by: 2 do: [ :i | newDictionary at: (anArray at: i) put: (anArray at: i + 1) ].
	^ newDictionary
]