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
		Local day:Int=GetWorldTime().getDay()
		If dayLastChecked <> day
			dayLastChecked = day
		Else
			Return True
		EndIf

		Local now:Long = GetWorldTime().GetTimeGone()
		Local futureCount:Int = 0
		Local goodCount:Int = 0
		Local filterMoviesGood:TProgrammeLicenceFilterGroup = RoomHandler_MovieAgency.GetInstance().filterMoviesGood
		print "UPDATING FOR REMAKES"
		For Local l:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().singles.values()
			If l.getData().IsCustomProduction() Then Continue
			If l.getData().GetReleaseTime() > now Then futureCount:+1
			If filterMoviesGood And filterMoviesGood.DoesFilter(l) Then goodCount:+1
		Next
		print "  future "+futureCount
		print "  good "+goodCount

		If goodCount < 25 Or futureCount < 50 Then
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
		print "creating remake of "+licence.getTitle()
		
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