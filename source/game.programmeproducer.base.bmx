SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"




Type TProgrammeProducerCollection Extends TGameObjectCollection
	Global _eventsRegistered:int= FALSE
	Global _eventListeners:TLink[]
	Global _instance :TProgrammeProducerCollection


	Function GetInstance:TProgrammeProducerCollection()
		if not _instance then _instance = new TProgrammeProducerCollection
		return _instance
	End Function


	Method New()
		if not _eventsRegistered
			'=== remove all registered event listeners
			EventManager.unregisterListenersByLinks(_eventListeners)
			_eventListeners = new TLink[0]
			'...

			_eventsRegistered = True
		endif
	End Method


	Method GetByGUID:TProgrammeProducerBase(GUID:String)
		Return TProgrammeProducerBase( Super.GetByGUID(GUID) )
	End Method


	Method GetRandom:TProgrammeProducerBase()
		Return TProgrammeProducerBase( Super.GetRandom() )
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeProducerCollection:TProgrammeProducerCollection()
	Return TProgrammeProducerCollection.GetInstance()
End Function




Type TProgrammeProducerBase extends TGameObject
	'override
	Method GenerateGUID:string()
		return "programmeproducerbase-"+id
	End Method


	Method CreateProgrammeLicence:object()
	End Method


	Method CreateProgrammeData:object()
	End Method
End Type