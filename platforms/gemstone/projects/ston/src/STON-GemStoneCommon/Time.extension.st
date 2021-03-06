Extension { #name : 'Time' }

{ #category : '*ston-gemstonecommon' }
Time >> stonOn: stonWriter [
  "Use an ISO style HH:MM:SS representation"

  stonWriter
    writeObject: self
    listSingleton: (self asStringUsingFormat: #($: true false))

]

{ #category : '*ston-gemstonecommon' }
Time class >> fromSton: stonReader [
  ^ self fromString: stonReader parseListSingleton usingFormat: #($: true false)

]
