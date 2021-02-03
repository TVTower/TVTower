SuperStrict
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "game.gameobject.bmx"
Import "game.programme.programmelicence.bmx"




Type TProgrammeProducerCollection Extends TGameObjectCollection
	Global _eventsRegistered:int= FALSE
	Global _eventListeners:TEventListenerBase[]
	Global _instance :TProgrammeProducerCollection

	Global nameTemplates:String[] = ["%lastname% %film%", "The %lastname% Brothers", "%colour% %fabric% %film%", "%colour% %jewel% %film%"]
	Global nameTemplateFilms:String[] = ["film", "movies", "pictures", "productions"]
	Global nameTemplateFabrics:String[] = ["velvet", "cotton", "satin", "leather", "jeans"]
	Global nameTemplateJewels:String[] = ["diamond", "crystal", "jade", "emerald", "topas", "stone"]
	Global nameTemplateColours:String[] = ["pink", "red", "green", "yellow", "black", "white"]


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


	Method GenerateRandomCountryCode:String()
		'TODO: maybe limit to specific countries?
		
		Return GetPersonGenerator().GetRandomCountryCode().ToUpper()
	End Method
	

	Method GenerateRandomName:String(countryCode:String="")
		if not countryCode then countryCode = GenerateRandomCountryCode()
		
		Local name:String = nameTemplates[ RandRange(0, nameTemplates.length-1) ]
		if name.find("%lastname%") >= 0 then name = name.replace("%lastname%", StringHelper.UCFirst(GetPersonGenerator().GetLastName(countryCode, 0)))
		if name.find("%colour%") >= 0 then name = name.replace("%colour%", StringHelper.UCFirst(nameTemplateColours[ RandRange(0, nameTemplateColours.length-1) ]))
		if name.find("%film%") >= 0 then name = name.replace("%film%", StringHelper.UCFirst(nameTemplateFilms[ RandRange(0, nameTemplateFilms.length-1) ]))
		if name.find("%fabric%") >= 0 then name = name.replace("%fabric%", StringHelper.UCFirst(nameTemplateFabrics[ RandRange(0, nameTemplateFabrics.length-1) ]))
		if name.find("%jewel%") >= 0 then name = name.replace("%jewel%", StringHelper.UCFirst(nameTemplateJewels[ RandRange(0, nameTemplateJewels.length-1) ]))

		'todo: save name once used
	
		Return name
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
	Field countryCode:String
	Field name:String
	Field budget:Int
	'0 = no clue, 100 = knowing everything
	Field experience:Int = 10

	'override
	Method GenerateGUID:string()
		return "programmeproducerbase-"+id
	End Method
	
	
	Method CreateProgrammeLicence:object(params:TData) abstract


	Method RandomizeCharacteristics:Int()
		budget = RandRange(2,15) * 125000
		experience = RandRange(10, 30)
	End Method

	
	Method GainExperienceForProgrammeLicence(licence:TProgrammeLicence)
		if not licence.data Then Return
		
		Local quality:Int = (100 * licence.data.GetQualityRaw() + 0.5)
		Local gain:Int = 0
		If quality > 5 
			gain = 1
		ElseIf quality > 25
			gain = 2
		ElseIf quality > 50
			gain = 3
		ElseIf quality > 75
			gain = 4
		EndIf
		If experience < 10
			gain = Max(0, gain)
		ElseIf experience < 20
			gain = Max(0, gain)
		ElseIf experience < 50
			gain = Max(0, gain - 1)
		ElseIf experience < 75
			gain = Max(-1, gain - 2) 'yes, you can loose here!
		ElseIf experience < 100
			gain = Max(-2, gain - 3) 'yes, you can loose here!
		EndIf
		'series episodes do not get that much exp
		If licence.data.IsEpisode() 
			If gain > 0 
				gain = Max(1, gain / 2)
			ElseIf gain < 0
				gain = Min(-1, gain / 2)
			EndIf
		EndIf
		experience :+ gain
	End Method


	'called on a more or less regular base (to start new productions etc)
	Method Update:Int()
	End Method


	Method onGiveBackLicenceToPool:Int(licence:TProgrammeLicence)
		Return True
	End Method
End Type