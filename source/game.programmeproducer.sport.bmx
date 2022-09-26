SuperStrict
Import "game.programmeproducer.base.bmx"
Import "game.newsagency.sports.bmx"
'for TSportsProgrammeData
Import "game.programme.programmedata.specials.bmx"
Import "game.programme.programmelicence.bmx"

'to know the short country name of the used map
Import "game.stationmap.bmx"

'register self to producer collection
'disabled: done in game.GenerateStartProgrammeProducers() now
'GetProgrammeProducerCollection().Add( TProgrammeProducerSport.GetInstance() )




Type TProgrammeProducerSport Extends TProgrammeProducerBase
	Global _eventsRegistered:Int= False
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TProgrammeProducerSport
	
	
	Method Remove:Int() Override
		'remove instance specific event listeners...
	End Method

	'override
	Method GenerateGUID:String()
		Return "programmeproducersport-"+id
	End Method


	Function GetInstance:TProgrammeProducerSport()
		If Not _instance Then _instance = New TProgrammeProducerSport
		Return _instance
	End Function
	
	
	Method Initialize:TProgrammeProducerBase() override
		name = "Generic Sport Producer"
		'reset budget etc
		RandomizeCharacteristics()

		Return self
	End Method


	Method New()
		'our sport producers produce locally :)
		countryCode = GetStationMapCollection().config.GetString("nameShort", "Unk").ToUpper()
		'this would be useful if persons need to be generated with the
		'person generator, or a host is required
		'countryCode = GetStationMapCollection().GetMapISO3166Code().ToUpper()

		If Not _eventsRegistered
			'=== remove all registered event listeners
			EventManager.UnregisterListenersArray(_eventListeners)
			_eventListeners = new TEventListenerBase[0]

			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SportLeague_StartSeason, onSportLeagueStartSeason) ]
			'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Sport.StartPlayoffs, onSportLeagueStartSeason) ]

			_eventsRegistered = True
		EndIf
	End Method


	Function onSportLeagueStartSeason:Int( triggerEvent:TEventBase )
		Local league:TNewsEventSportLeague = TNewsEventSportLeague(triggerEvent.GetSender())
		If Not league Then Return False

		'Notify "onSportLeagueStartSeason  league.GetDoneMatchesCount()="+league.GetDoneMatchesCount() + "  league.GetNextMatchTime()="+league.GetNextMatchTime() + "  now="+GetWorldTime().GetTimeGone()


		'ignore seasons if the first match already happened ?
		If league.GetDoneMatchesCount() = 0 And league.GetNextMatchTime() > GetWorldTime().GetTimeGone()
			TLogger.Log("TProgrammeProducerSport", "New league season started: " + league.name + "  " + GetWorldTime().GetFormattedGameDate(), LOG_DEBUG)

			Local licence:TProgrammeLicence = GetInstance().CreateLeagueMatchesCollectionProgrammeLicence(league)
			If licence
				'print "  -> licence: "+ licence.GetGUID() +"  release: " + GetWorldTime().GetFormattedGameDate( licence.data.GetReleaseTime() )
				'GameConfig.devGUID = licence.GetGUID()
				
				'add children
				For Local sub:TProgrammeLicence = EachIn licence.subLicences
					GetProgrammeDataCollection().Add(sub.GetData())
					GetProgrammeLicenceCollection().AddAutomatic(sub)
				Next

				GetProgrammeDataCollection().Add(licence.GetData())
				GetProgrammeLicenceCollection().AddAutomatic(licence)
			EndIf
		EndIf
	End Function


	Method CreateProgrammeLicence:Object(params:TData)
		If Not params
			Print "TProgrammeProducerSport: CreateProgrammeLicence() called with empty param."
			Return Null
		EndIf
		If Not TNewsEventSportLeague(params.get("league"))
			Print "TProgrammeProducerSport: CreateProgrammeLicence() called without league."
			Return Null
		EndIf

		Return CreateLeagueMatchesCollectionProgrammeLicence( TNewsEventSportLeague(params.get("league")) )
	End Method


	Method CreateLeagueMatchesCollectionProgrammeLicence:TProgrammeLicence(league:TNewsEventSportLeague)
		If Not league Then Return Null

		Local programmeData:TSportsHeaderProgrammeData = New TSportsHeaderProgrammeData
		Local programmeLicence:TProgrammeLicence = New TProgrammeLicence
		programmeLicence.SetData(programmeData)
		programmeLicence.owner = TOwnedGameObject.OWNER_NOBODY
		programmeLicence.extra = New TData
		programmeLicence.extra.AddInt("producerID", - GetID()) 'negative!

		programmeLicence.licenceType = TVTProgrammeLicenceType.COLLECTION
		programmeData.dataType = TVTProgrammeDataType.COLLECTION

		programmeData.title = New TLocalizedString
		programmeData.description = New TLocalizedString
		programmeData.descriptionAirtimeHint = New TLocalizedString
		programmeData.descriptionAiredHint = New TLocalizedString
		'only store for current/default to save savegame space
		'For local locale:string = EachIn TLocalization.languages.Keys()
		Local localeIDs:Int[] = [TLocalization.currentLanguageID, TLocalization.defaultLanguageID]
		For Local localeID:Int = EachIn localeIDs

			Local title:String = GetRandomLocalizedString("SPORT_PROGRAMME_TITLE").Get(localeID)
			Local description:String = GetRandomLocalizedString("SPORT_PROGRAMME_ALL_X_MATCHES_OF_LEAGUEX_IN_SEASON_X").Get(localeID)
			Local descriptionAirtimeHint:String = GetRandomLocalizedString("SPORT_PROGRAMME_MATCH_TIMES").Get(localeID)
			Local descriptionAiredHint:String = GetRandomLocalizedString("ALL_MATCHES_RUN").Get(localeID)

			'as the collection header is of "TProgrammeData" we have to
			'replace placeholders manually
			title = TSportsProgrammeData._replaceSportInformation(title, league.GetSport(), localeID)
			title = TSportsProgrammeData._replaceLeagueInformation(title, league, localeID)
			description = TSportsProgrammeData._replaceSportInformation(description, league.GetSport(), localeID)
			description = TSportsProgrammeData._replaceLeagueInformation(description, league, localeID)
			descriptionAirtimeHint = TSportsProgrammeData._replaceSportInformation(descriptionAirtimeHint, league.GetSport(), localeID)
			descriptionAirtimeHint = TSportsProgrammeData._replaceLeagueInformation(descriptionAirtimeHint, league, localeID)
			descriptionAiredHint = TSportsProgrammeData._replaceSportInformation(descriptionAiredHint, league.GetSport(), localeID)
			descriptionAiredHint = TSportsProgrammeData._replaceLeagueInformation(descriptionAiredHint, league, localeID)

			programmeData.title.Set(StringHelper.UCFirst(title), localeID)
			programmeData.description.Set(StringHelper.UCFirst(description), localeID)
			programmeData.descriptionAirtimeHint.Set(StringHelper.UCFirst(descriptionAirtimeHint), localeID)
			programmeData.descriptionAiredHint.Set(StringHelper.UCFirst(descriptionAiredHint), localeID)
		Next

		programmeData.GUID = "programmedata-sportleaguecollection-"+league.GetGUID() +"-season-"+league.GetCurrentSeason().GetGUID()
		programmeData.titleProcessed = Null
		programmeData.descriptionProcessed = Null
		programmeData.productType = TVTProgrammeProductType.EVENT 'or MISC?

		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK").ToUpper()
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		programmeData.blocks = 1 'overridden in the individual matches

		programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)

		'programmeData.review = 0.2
		'programmeData.speed = 0.5

		programmeData.genre = TVTProgrammeGenre.Event_Sport

		programmeData.releaseTime = league.GetFirstMatchTime()
		programmeData.leagueGUID = league.GetGUID()

		'so the licence datasheet does expose that information
		programmeData.SetBroadcastLimit(3)
		'once sold, this programmelicence wont be buyable anylonger
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REMOVES_TRADEABILITY, True)

		'fuer jetzt: alle noch kommenden Spiele "verlizenzen"
		Local matchNumber:Int = 0
		For Local match:TNewsEventSportMatch = EachIn league.GetUpcomingMatches(GetWorldTime().GetTimeGone(), -1)
			Local matchLicence:TProgrammeLicence = GetInstance().CreateMatchProgrammelicence(match, programmeLicence)
			'add to collections

			If matchLicence
				programmeLicence.AddSubLicence(matchLicence, matchNumber)
				matchNumber :+ 1
			EndIf
		Next

		Return programmeLicence
	End Method


	Method CreateMatchProgrammeLicence:TProgrammeLicence(match:TNewsEventSportMatch, parentLicence:TProgrammeLicence)
		'TODO: programmeData.speed 		abhaengig von Liga und Platzierung (-> in Update() )
		'TODO: programmeData.country	Map-Country
		'TODO: keywords: soccer mit Sportartname ersetzen
		'TODO: cast: Moderator hinzufuegen (wenn moeglich - 50% - mit "Event_sport"-Erfahrung, was erst nach der ersten Produktion moeglich ist)
		If Not match Then Return Null

		Local programmeData:TProgrammeData
		If parentLicence
			programmeData = New TSportsProgrammeData
			THelper.TakeOverObjectValues(parentLicence.data, programmeData)
		EndIf
		If Not programmeData Then programmeData = New TSportsProgrammeData

		'needed so title/description can fetch the right information
		If TSportsProgrammeData(programmeData)
			TSportsProgrammeData(programmeData).AssignSportMatch(match)
		EndIf

		Local programmeLicence:TProgrammeLicence = New TProgrammeLicence
		programmeLicence.SetData(programmeData)
		programmeLicence.owner = TOwnedGameObject.OWNER_NOBODY
		'when setting to "SINGLE" they might be sold independently
		programmeLicence.licenceType = TVTProgrammeLicenceType.COLLECTION_ELEMENT
		'also set data to this kind of type
		programmeData.dataType = TVTProgrammeDataType.COLLECTION_ELEMENT


		programmeData.GUID = "programmedata-sportmatch-"+match.GetGUID()


		programmeData.title = New TLocalizedString
		programmeData.description = New TLocalizedString
		Local localeIDs:Int[] = [TLocalization.currentLanguageID, TLocalization.defaultLanguageID]
		For Local localeID:Int = EachIn localeIDs
			programmeData.title.Set("%LEAGUENAMESHORT%: %MATCHNAMESHORT%", localeID )
			programmeData.description.Set( GetRandomLocale("SPORT_PROGRAMME_MATCH_DESCRIPTION") , localeID )
		Next

		'this gets overridden in "GetTitle()/GetDescription()"
		TSportsProgrammeData(programmeData).dynamicTexts = True

		programmeData.titleProcessed = Null
		programmeData.descriptionProcessed = Null
		programmeData.productType = TVTProgrammeProductType.EVENT 'or MISC?

		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK")
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		'as much blocks as it needs to fit the match into it (90min -> 2 blocks)
		programmeData.blocks = Int( Ceil(match.duration / Double(TWorldTime.HOURLENGTH)) )
		'alternative code
		'programmeData.blocks = (match.duration + 0.5 * TWorldTime.HOURLENGTH) / TWorldTime.HOURLENGTH

		programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)

		If Not programmeData.extra Then programmeData.extra = New TData
		programmeData.extra.AddInt("producerID", - GetID()) 'negative!

		programmeData.review = 0.6 'maximum possible
		programmeData.speed = 0.75 'maximum possible
		programmeData.genre = TVTProgrammeGenre.Event_Sport
		programmeData.outcome = 0.5 'maximum possible

		Select match.sportName
			Case "ICEHOCKEY"
				'in germany not so successful
				programmeData.outcome = 0.4
			Case "SOCCER"
				'really popular
				programmeData.outcome = 0.75
		End Select

		'loss due to first broadcast and not being live are covered by
		'default values of live programmes
		'after first broadcast, sport matches loose a lot of interest
		'programmeData.SetModifier("topicality::firstBroadcastDone", 1.0)
		'also they lose a bit when no longer live
		'programmeData.SetModifier("topicality::notLive", 0.25)

		programmeData.releaseTime = match.matchTime '- 2*24*TWorldTime.HOURLENGTH - 24*TWorldTime.HOURLENGTH

		'remove after broadcasting 3 times
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.REMOVE_ON_REACHING_BROADCASTLIMIT, True)
		'once sold, this programmelicence wont be buyable anylonger
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REMOVES_TRADEABILITY, True)
		programmeLicence.SetBroadcastLimit(3) 'needed?
		programmeData.SetBroadcastLimit(3)
		'while limiting the broadcasts, we should also lower the price
		'do this for the licences, as the data should be still "expensive"
		programmeLicence.SetModifier("price", 0.4)



		Return programmeLicence
	End Method
End Type