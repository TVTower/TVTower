SuperStrict
Import "game.programmeproducer.bmx"
Import "game.roomhandler.movieagency.bmx"

'register self to producer collection
'disabled: done in game.GenerateStartProgrammeProducers() now
'GetProgrammeProducerCollection().Add( TProgrammeProducerMorningShows.GetInstance() )



Type TProgrammeProducerMorningShows Extends TProgrammeProducer
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TProgrammeProducerMorningShows


	Method New()
		_producerName:String = "PP_MorningShows"

		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]

		'react to "finished" special programmes
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicence_OnGiveBackToLicencePool, onGiveBackLicenceToPool) ]
	End Method

	'override
	Method GenerateGUID:String()
		Return "programmeproducermorningshows-"+id
	End Method


	Function GetInstance:TProgrammeProducerMorningShows()
		If Not _instance Then _instance = New TProgrammeProducerMorningShows
		Return _instance
	End Function


	Method onGiveBackLicenceToPool:Int( licence:TProgrammeLicence )
		'reduce count of currently produced morning shows ...
	End Method


	Method Update:Int()
		'hier eventuell auf "Typ" limitieren aber mehrfache Simultanproduktion
		'ermoeglichen
		If activeProductions.Count() = 0
'			CreateProgrammeLicence(Null)
		EndIf
	End Method





Rem
		programmeData.GUID = "programmedata-programmeproducer-specialprogrammes-"+programmeData.id
		programmeData.productType = TVTProgrammeProductType.MISC
		programmeData.country = ProducerCountry
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)
		programmeData.genre = TVTProgrammeGenre.SHOW
		'so the licence datasheet does expose that information
		programmeData.SetBroadcastLimit(10)
		'once sold, this programmelicence wont be buyable anylonger
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REMOVES_TRADEABILITY, True)

		return programmeLicence
endrem
End Type


Type TProgrammeProducerRemake Extends TProgrammeProducer
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TProgrammeProducerRemake
	Field nextRemakeTime:Long = -1


	Method New()
		_producerName:String = "PP_Remake"

		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]

		'react to "finished" special programmes
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicence_OnGiveBackToLicencePool, onGiveBackLicenceToPool) ]
	End Method

	'override
	Method GenerateGUID:String()
		Return "programmeproducerremake-"+id
	End Method


	Function GetInstance:TProgrammeProducerRemake()
		If Not _instance Then _instance = New TProgrammeProducerRemake
		Return _instance
	End Function


	Method onGiveBackLicenceToPool:Int( licence:TProgrammeLicence )
	End Method


	Method Update:Int()
		Local now:Long = GetWorldTime().GetTimeGone()
		If nextRemakeTime < 0
			'determine when to start making remakes
			Local isFictional:Int
			Local data:TProgrammeData
			Local cast:TPersonProductionJob[]
			Local c:TPersonProductionJob
			Local persons:TPersonBaseCollection = GetPersonBaseCollection()
			Local p:TPersonBase
			For Local l:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().singles.values()
				data=l.getData()
				If Not data Then continue
				If data.GetYear() < 1950 Then data.SetFlag(TVTProgrammeDataFlag.NOREMAKE, True)
				If data.GetReleaseTime() <= nextRemakeTime Then Continue
				If data.IsCustomProduction() Then Continue
				If data.HasFlag(TVTProgrammeDataFlag.LIVE+TVTProgrammeDataFlag.LIVEONTAPE+TVTProgrammeDataFlag.PAID) Then Continue
				'ignore fictional entries (no explicit flag - inspect cast)
				isFictional = False
				cast=data.GetCast()
				If Not cast Or cast.length = 0 Then Continue
				For c = EachIn cast
					p = persons.getById(c.personID)
					If Not p Then continue
					If p.IsFictional()
						isFictional = True
						Exit
					EndIf
				Next
				If isFictional Then Continue
				'if the licence made it here it is a candidate with later release time
				nextRemakeTime = l.getData().GetReleaseTime()
			Next
			TLogger.Log("TProgrammeProducerRemake", "will start producing remakes at " + GetWorldTime().GetFormattedGameDate(nextRemakeTime), LOG_DEBUG)
		ElseIf now >= nextRemakeTime
			Local candidateFilter:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterCrap.Copy()
			candidateFilter.licenceTypes = [TVTProgrammeLicenceType.SINGLE]
			candidateFilter.requiredOwners = [TOwnedGameObject.OWNER_NOBODY]
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.INVISIBLE)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.LIVE)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.LIVEONTAPE)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.NOREMAKE)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.PAID)
			'TODO number of remakes depending on number of days per season?
			'currently 5 fix, one movie per day per player
			'(candidates may be excluded due to cast reference)
			Local toRemake:TProgrammeLicence[] = GetProgrammeLicenceCollection().GetRandomsByFilter(candidateFilter, 5)
			For Local l:TProgrammeLicence = EachIn toRemake
				addRemake(l, now)
			Next
			nextRemakeTime = now + TWorldTime.DAYLENGTH 'randomize a bit?
		EndIf
	End Method


	Method addRemake(licence:TProgrammeLicence, releaseTime:Long)
		Local data:TProgrammeData = licence.GetData()
		'only one remake per data
		data.SetFlag(TVTProgrammeDataFlag.NOREMAKE, True)

		If data.title.ContainsString(":~qcast~q:") Or data.description.ContainsString(":~qcast~q:") Then
			'print "texts contain cast reference - no remake for "+data.getTitle()
			return
		EndIf

		Local nd:TProgrammeData = New TProgrammeData
		Local nl:TProgrammeLicence = new TProgrammeLicence

		Local persons:TPersonBaseCollection = GetPersonBaseCollection()
		Local p:TPersonBase
		Local np:TPersonBase
		Local pm:TProductionManager = GetProductionManager()
		For Local c:TPersonProductionJob = EachIn data.GetCast()
			Local nc:TPersonProductionJob = c.Copy()
			p = persons.GetById(nc.personID)
			np=Null
			If p
				If p.getGuid().startsWith("various")
					'no need to replace
					np = p
				Else
					Local amateurs:TPersonBase[] = pm.GetCurrentAvailableAmateurs(nc.job, p.gender, 21, 5, 0)
					If amateurs And amateurs.length > 0 And randRange(0,10) > 5
						np = amateurs[randRange(0,amateurs.length-1)]
					Else
						If p.IsInsignificant()
							np = persons.GetRandomCastableInsignificant(Null, True, True, nc.job, p.gender, True, p.GetCountry())
						EndIf
						If Not np then np = persons.GetRandomCastableCelebrity(Null, True, True, nc.job, p.gender, True, p.GetCountry())
						'If Not np then np = persons.GetRandomCastableCelebrity(Null, True, False, nc.job, p.gender, True, p.GetCountry())
						If Not np then np = persons.GetRandomCastableCelebrity(Null, True, True, nc.job, p.gender, True, "")
					EndIf
				EndIf
				If np
					nc.personID=np.GetId()
					nd.AddCast(nc)
				EndIf
			EndIf
		Next

		nd.country=data.country
		nd.targetGroupAttractivityMod = data.targetGroupAttractivityMod
		nd.targetGroups = data.targetGroups
		nd.proPressureGroups = data.proPressureGroups
		nd.contraPressureGroups = data.contraPressureGroups

		'randomize?
		nd.outcome=data.outcome
		nd.review=data.review
		nd.speed=data.speed

		nd.genre=data.genre
		nd.subGenres=data.subGenres
		nd.blocks=data.blocks

		nd.dataType=data.dataType
		nd.franchiseGUID=data.franchiseGUID
		nd.franchisees=data.franchisees

		nd.distributionChannel=data.distributionChannel
		nd.productType=data.productType

		nd.releaseTime = releaseTime
		If data.modifiers then nd.modifiers=data.modifiers.Copy()
		nd.flags = data.flags
		If data.broadcastFlags Then nd.broadcastFlags=data.broadcastFlags.Copy()
		nd.title = data.title.Copy()
		nd.description = data.description.Copy()

		nl.SetData(nd)
		nl.owner = TOwnedGameObject.OWNER_NOBODY
		nl.extra = New TData
		nl.extra.AddInt("producerID", - GetID()) 'negative!
		nl.licenceType = licence.licenceType
		nl.licenceFlags = licence.licenceFlags

		GetProgrammeDataCollection().Add(nd)
		GetProgrammeLicenceCollection().AddAutomatic(nl)
		TLogger.Log("TProgrammeProducerRemake", "created remake of " + licence.getTitle(), LOG_DEBUG)
	EndMethod
End Type