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
	Field dayLastChecked:Long=-1


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
		'create remakes only once a day
		Local day:Int=GetWorldTime().getDay()
		If dayLastChecked <> day
			dayLastChecked = day
		Else
			Return True
		EndIf

		Local now:Long = GetWorldTime().GetTimeGone()
		Local goodCount:Int = 0
		Local filterMoviesGood:TProgrammeLicenceFilterGroup = RoomHandler_MovieAgency.GetInstance().filterMoviesGood
		print "UPDATING FOR REMAKES"
		For Local l:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().singles.values()
			If l.getData().IsCustomProduction() Then Continue
			If filterMoviesGood And filterMoviesGood.DoesFilter(l) And l.getData().GetReleaseTime() <= now Then goodCount:+1
		Next
		print "  good "+goodCount

		If goodCount < 120 Then
			Local candidateFilter:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterCrap.Copy()
			candidateFilter.licenceTypes = [TVTProgrammeLicenceType.SINGLE]
			candidateFilter.requiredOwners = [TOwnedGameObject.OWNER_NOBODY]
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.INVISIBLE)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.LIVE)
			candidateFilter.SetNotDataFlag(TVTProgrammeDataFlag.LIVEONTAPE)
			'TODO not flag customProd and not remade
			Local toRemake:TProgrammeLicence[] = GetProgrammeLicenceCollection().GetRandomsByFilter(candidateFilter, 10)
			For Local l:TProgrammeLicence = EachIn toRemake
				addRemake(l)
			Next
		EndIf
	End Method


	Method addRemake(licence:TProgrammeLicence)
		Local data:TProgrammeData = licence.GetData()

		If data.title.ContainsString(":~qcast~q:") Or data.description.ContainsString(":~qcast~q:") Then
			print "texts contain cast reference - no remake for "+data.getTitle()
			'TODO add noRemake flag to licence
			return
		EndIf

		Local nd:TProgrammeData = New TProgrammeData
		Local nl:TProgrammeLicence = new TProgrammeLicence

		'TODO cast!!

		nd.country=data.country'TODO
		nd.targetGroupAttractivityMod = data.targetGroupAttractivityMod
		nd.targetGroups = data.targetGroups
		nd.proPressureGroups = data.proPressureGroups
		nd.contraPressureGroups = data.contraPressureGroups

		nd.outcome=data.outcome'TODO randomize
		nd.review=data.review'TODO randomize
		nd.speed=data.speed'TODO randomize

		nd.genre=data.genre
		nd.subGenres=data.subGenres
		nd.blocks=data.blocks

		nd.dataType=data.dataType
		nd.franchiseGUID=data.franchiseGUID
		nd.franchisees=data.franchisees

		nd.distributionChannel=data.distributionChannel
		nd.productType=data.productType

		nd.releaseTime = GetWorldTime().GetTimeGone() + 3 * TWorldTime.DAYLENGTH
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
		
		print "creating remake of "+licence.getTitle()
		
		GetProgrammeDataCollection().Add(nd)
		GetProgrammeLicenceCollection().AddAutomatic(nl)

		'TODO add remake flag to licence
	EndMethod


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