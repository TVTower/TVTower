SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.gameobject.bmx"
Import "game.programme.programmelicence.bmx"




Type TProgrammeProducerCollection Extends TGameObjectCollection
	Global _eventsRegistered:int= FALSE
	Global _eventListeners:TEventListenerBase[]
	Global _instance :TProgrammeProducerCollection


	Function GetInstance:TProgrammeProducerCollection()
		if not _instance then _instance = new TProgrammeProducerCollection
		return _instance
	End Function


	Method New()
		if not _eventsRegistered
			'=== remove all registered event listeners
			EventManager.UnregisterListenersArray(_eventListeners)
			_eventListeners = new TEventListenerBase[0]
			'...


			'inform producers about no longer used or sold programmes
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicence_OnGiveBackToLicencePool, onGiveBackLicenceToPool) ]


			_eventsRegistered = True
		endif
	End Method


	Method GetByGUID:TProgrammeProducerBase(GUID:String)
		Return TProgrammeProducerBase( Super.GetByGUID(GUID) )
	End Method


	Method GetRandom:TProgrammeProducerBase()
		Return TProgrammeProducerBase( Super.GetRandom() )
	End Method


	Method UpdateAll()
		For local p:TProgrammeProducerBase = EachIn entries.Values()
			p.Update()
		Next
	End Method


	Function onGiveBackLicenceToPool:Int( triggerEvent:TEventBase )
		Local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetSender())
		If Not licence Then Return False

		For local producer:TProgrammeProducerBase = EachIn GetProgrammeProducerCollection()
			If licence.data.extra And licence.data.extra.GetString("producerName") = producer._producerName
				producer.onGiveBackLicenceToPool(licence)
			EndIf
		Next

	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammeProducerCollection:TProgrammeProducerCollection()
	Return TProgrammeProducerCollection.GetInstance()
End Function




Type TProgrammeProducerBase extends TGameObject
	Field _producerName:string

	'override
	Method GenerateGUID:string()
		return "programmeproducerbase-"+id
	End Method


	Method CreateProgrammeLicence:object(params:TData) abstract


	'called on a more or less regular base (to start new productions etc)
	Method Update:Int()
	End Method


	Method onGiveBackLicenceToPool:Int(licence:TProgrammeLicence)
		Return True
	End Method
End Type