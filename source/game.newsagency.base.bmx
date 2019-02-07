SuperStrict
Import Brl.LinkedList
Import "game.programme.newsevent.bmx"
Import "game.figure.customfigures.bmx"
Import "game.world.bmx"
Import "game.game.base.bmx"
Import "game.newsagency.sports.bmx"


'likely a kind of agency providing news...
'at the moment only a base object
Type TNewsAgency
	'when to announce a new newsevent
'	Field NextEventTime:Double = -1
	'check for a new news every x-y minutes
'	Field NextEventTimeInterval:int[] = [90, 140]

	Field NextEventTimes:Double[]
	'check for a new news every x-y minutes
	Field NextEventTimeIntervals:int[][]

	Field delayedLists:TList[]

	Field newsProviders:TNewsAgencyNewsProvider[]


	'=== TERRORIST HANDLING ===
	'both parties (VR and FR) have their own array entry
	'when to update aggression the next time
	Field terroristUpdateTime:Double[] = [Double(0),Double(0)]
	'update terrorists aggression every x-y minutes
	Field terroristUpdateTimeInterval:int[] = [80, 100]
	'level of terrorists aggression (each level = new news)
	'party 2 starts later
	Field terroristAggressionLevel:Int[] = [0, -1]
	Field terroristAggressionLevelMax:Int = 4
	'progress in the given aggression level (0 - 1.0)
	Field terroristAggressionLevelProgress:Float[] = [0.0, 0.0]
	'rate the aggression level progresses each game hour
	Field terroristAggressionLevelProgressRate:Float[][] = [ [0.06,0.08], [0.06,0.08] ]

	Global _eventListeners:TLink[]
	Global _instance:TNewsAgency


	Function GetInstance:TNewsAgency()
		if not _instance then _instance = new TNewsAgency
		return _instance
	End Function


	Method New()
		NextEventTimes = new Double[ TVTNewsGenre.count ]
		NextEventTimeIntervals = NextEventTimeIntervals[.. TVTNewsGenre.count]
		For local i:int = 0 until TVTNewsGenre.count
			NextEventTimeIntervals[i] = [180, 300]
		Next
	End Method


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		For local i:int = 0 until TVTNewsGenre.count
			'NextEventTimes[i] = GetWorldTime().GetTimeGone() - 60 * RandRange(60,180)
			NextEventTimes[i] = -1
		Next
		'setup the intervals of all genres
		InitializeNextEventTimeIntervals()


		terroristUpdateTime = [Double(0),Double(0)]
		terroristUpdateTimeInterval = [80, 100]
		terroristAggressionLevel = [0, -1]
		terroristAggressionLevelMax = 4
		terroristAggressionLevelProgress = [0.0, 0.0]
		terroristAggressionLevelProgressRate = [ [0.06,0.08], [0.06,0.08] ]


		'initialize all news providers too
		For local nP:TNewsAgencyNewsProvider = Eachin newsProviders
			nP.Initialize()
		Next

		'register custom game modifier functions
		GetGameModifierManager().RegisterRunFunction("TFigureTerrorist.SendFigureToRoom", TFigureTerrorist.SendFigureToRoom)


		'=== REGISTER EVENTS ===
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'react to confiscations
		_eventListeners :+ [ EventManager.registerListenerFunction( "publicAuthorities.onConfiscateProgrammeLicence", onPublicAuthoritiesConfiscateProgrammeLicence) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "room.onBombExplosion", onRoomBombExplosion) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.addNews", onPlayerProgrammeCollectionAddNews) ]

		'resize news genres when loading an older savegame
		_eventListeners :+ [ EventManager.registerListenerFunction( "SaveGame.OnLoad", onSavegameLoad) ]


		delayedLists = New TList[4]
	End Method


	Method InitializeNextEventTimeIntervals()
		For local i:int = 0 until TVTNewsGenre.count
			Select i
				case TVTNewsGenre.POLITICS_ECONOMY
					NextEventTimeIntervals[i] = [210, 330]
				case TVTNewsGenre.SHOWBIZ
					NextEventTimeIntervals[i] = [180, 290]
				case TVTNewsGenre.SPORT
					NextEventTimeIntervals[i] = [200, 300]
				case TVTNewsGenre.TECHNICS_MEDIA
					NextEventTimeIntervals[i] = [220, 350]
				case TVTNewsGenre.CULTURE
					NextEventTimeIntervals[i] = [240, 380]
				'default
			'	case TVTNewsGenre.CURRENT_AFFAIRS
			'		NextEventTimeIntervals[i] = [180, 300]
				default
					NextEventTimeIntervals[i] = [180, 300]
			End Select
		Next
	End Method


	Function onSavegameLoad:int(triggerEvent:TEventBase)
		local NA:TNewsAgency = GetInstance()
		if NA.NextEventTimes.length < TVTNewsGenre.count
			NA.NextEventTimes = NA.NextEventTimes[.. TVTNewsGenre.count]
			NA.NextEventTimeIntervals = NA.NextEventTimeIntervals[.. TVTNewsGenre.count]
		endif

		'=== SETUP ALL INTERVALS ===
		'this sets to the most current values (might differ from older
		'savegames)
		'and it also initializes times in savegames NOT having that time
		'defined yet
		NA.InitializeNextEventTimeIntervals()
	End Function


	Function onPlayerProgrammeCollectionAddNews:int(triggerEvent:TEventBase)
		'remove news events from delayed list IF still there
		'(happens with 3 start news - added to delayed and then added
		' directly to collection)

		local news:TNews = TNews(triggerEvent.GetData().get("news"))
		if not news then return False
		_instance.RemoveFromDelayedListsByNewsEvent(news.owner, news.newsEvent)
	End Function


	Function onPublicAuthoritiesConfiscateProgrammeLicence:int(triggerEvent:TEventBase)
		local targetProgrammeGUID:string = triggerEvent.GetData().GetString("targetProgrammeGUID")
		local confiscatedProgrammeGUID:string = triggerEvent.GetData().GetString("confiscatedProgrammeGUID")
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		'nothing more for now
	End Function


	Function onRoomBombExplosion:int(triggerEvent:TEventBase)
		local roomGUID:string = triggerEvent.GetData().GetString("roomGUID")
		local bombRedirectedByPlayers:int = triggerEvent.GetData().GetInt("roomSignMovedByPlayers")
		local bombLastRedirectedByPlayerID:int = triggerEvent.GetData().GetInt("roomSignLastMoveByPlayerID")

		local room:TRoomBase = TRoomBase( triggerEvent.GetSender() )
		if not room
			TLogger.Log("NewsAgency", "Failed to create news for bomb explosion: invalid room passed for roomGUID ~q"+roomGUID+"~q", LOG_ERROR)
			return False
		endif

		'collect all channels having done this
		local caughtChannels:string = ""
		local caughtChannelIDs:string = ""
		local caughtChannelIDsArray:int[]
		For local i:int = 1 to 4
			local playerBitmask:int = 2^(i-1)
			if bombRedirectedByPlayers & playerBitmask > 0
				if caughtChannels <> "" then caughtChannels :+ ", "
				caughtChannels :+ GetPlayerBase(i).channelname

				if caughtChannelIDs <> "" then caughtChannelIDs :+ ","
				caughtChannelIDs :+ string(i)

				caughtChannelIDsArray :+ [i]
			endif
		Next


		Local quality:Float = 0.01 * randRange(75,90)
		Local price:Float = 1.0 + 0.01 * randRange(-5,15)
		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", null, null, TVTNewsGenre.CURRENTAFFAIRS, quality, null, TVTNewsType.InitialNewsByInGameEvent)
		Local newsChain1GUID:string = NewsEvent.GetGUID()+"-1"
		NewsEvent.title = GetRandomLocalizedString("BOMB_DETONATION_IN_TVTOWER")
		NewsEvent.description = GetRandomLocalizedString("BOMB_DETONATION_IN_TVTOWER_TEXT")
		NewsEvent.description.ReplaceLocalized("%ROOM%", room.GetDescriptionLocalized())

		NewsEvent.SetModifier("price", price)
		NewsEvent.SetModifier("topicality::age", 1.25)
		NewsEvent.SetFlag(TVTNewsFlag.SEND_TO_ALL, True)

		'add news chain 2 ?
		local data:TData = new TData
		data.AddString("trigger", "happen")
		data.AddString("type", "TriggerNews")
		data.AddNumber("probability", 100)
		'time = in 3-7 hrs
		data.AddString("time", "1,3,7")

		data.AddString("news", newsChain1GUID)

		NewsEvent.AddEffectByData(data)

		'not strictly "happened", but "journalists wrote about it"
		NewsEvent.happenedTime = GetWorldTime().GetTimeGone() + 60 * RandRange(5,20)

		Local NewsChainEvent1:TNewsEvent
		if bombRedirectedByPlayers = 0 or RandRange(0,90) < 90
			'chain 1
			Local qualityChain1:Float = 0.01 * randRange(50,60)
			Local priceChain1:Float = 1.0 + 0.01 * randRange(-5,10)
			NewsChainEvent1 = new TNewsEvent.Init(newsChain1GUID, null, null, TVTNewsGenre.CURRENTAFFAIRS, qualityChain1, null, TVTNewsType.FollowingNews)
			NewsChainEvent1.title = GetRandomLocalizedString("BOMB_DETONATION_IN_TVTOWER_NO_CLUES")
			NewsChainEvent1.description = GetRandomLocalizedString("BOMB_DETONATION_IN_TVTOWER_NO_CLUES_TEXT")
			NewsChainEvent1.SetModifier("price", priceChain1)
		else
			'chain 2
			Local qualityChain1:Float = 0.01 * randRange(60,80)
			Local priceChain1:Float = 1.0 + 0.01 * randRange(0,15)
			NewsChainEvent1 = new TNewsEvent.Init(newsChain1GUID, null, null, TVTNewsGenre.CURRENTAFFAIRS, qualityChain1, null, TVTNewsType.FollowingNews)
			NewsChainEvent1.title = GetRandomLocalizedString("BOMB_DETONATION_IN_TVTOWER_FOUND_CLUES")
			NewsChainEvent1.description = GetRandomLocalizedString("BOMB_DETONATION_IN_TVTOWER_FOUND_CLUES_TEXT")
			NewsChainEvent1.SetModifier("price", priceChain1)


			local data:TData

			'do this for all caught ones
			for local pID:int = EachIn caughtChannelIDsArray
				data = new TData
				'decrease image for all caught channels
				data.AddString("trigger", "broadcastFirstTime")
				data.AddString("type", "ModifyChannelPublicImage")
				data.AddNumber("value", -3)
				data.AddNumber("valueIsRelative", True)
				data.AddNumber("playerID", pID)
				data.AddString("log", "decrease image for all caught channels")
				NewsChainEvent1.AddEffectByData(data)
			Next

			'increase image for a broadcasting channel not being caught
			data = new TData
			data.AddString("trigger", "broadcastFirstTime")
			data.AddString("type", "ModifyChannelPublicImage")
			data.AddNumber("value", 5)
			data.AddNumber("valueIsRelative", True)
			'use playerID of broadcasting player
			data.AddNumber("playerID", 0)
			data.Add("conditions", new TData.AddString("broadcaster_notInPlayerIDs", caughtChannelIDs))
			data.AddString("log", "increase image for a broadcasting channel not being caught")

			NewsChainEvent1.AddEffectByData(data)

			'increase image (a bit less) for a broadcasting channel being
			'caught but brave enough to send it...
			data = new TData
			data.AddString("trigger", "broadcastFirstTime")
			data.AddString("type", "ModifyChannelPublicImage")
			data.AddNumber("value", 2)
			data.AddNumber("valueIsRelative", True)
			'use playerID of broadcasting player
			data.AddNumber("playerID", 0)
			data.AddString("log", "increase for broadcasting channel")
			data.Add("conditions", new TData.AddString("broadcaster_inPlayerIDs", caughtChannelIDs))
			NewsChainEvent1.AddEffectByData(data)
		endif
		NewsChainEvent1.SetModifier("topicality::age", 1.4)

		NewsChainEvent1.description.ReplaceLocalized("%ROOM%", room.GetDescriptionLocalized())
		NewsChainEvent1.description.Replace("%CHANNELS%", caughtChannels)


		GetNewsEventCollection().AddOneTimeEvent(NewsChainEvent1)
		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)
	End Function


	Method AddNewsProvider:int(newsProvider:TNewsAgencyNewsProvider)
		If not HasNewsProvider(newsProvider)
			newsProviders :+ [newsProvider]
		EndIf
	End Method


	Method HasNewsProvider:int(newsProvider:TNewsAgencyNewsProvider)
		For local np:TNewsAgencyNewsProvider = EachIn newsProviders
			if np = newsProvider then return True
		Next
		return False
	End Method


	Method Update:int()
		'All players update their newsagency on their own.
		'As we use "randRange" this will produce the same random values
		'on all clients - so they should be sync'd all the time.

		'fetch new news from external providers
		ProcessNewsProviders()

		'check for new news triggered by previous ones
		ProcessUpcomingNewsEvents()

		'send out delayed news to players
		ProcessDelayedNews()


		for local i:int = 0 until TVTNewsGenre.count
			if NextEventTimes[i] = -1
				TLogger.Log("NewsAgency", "Initialize NextEventTime for genre "+i, LOG_DEBUG)
				ResetNextEventTime(i, RandRange(-120, 0))
			endif

			If NextEventTimes[i] < GetWorldTime().GetTimeGone() Then AnnounceNewNewsEvent(i)
		Next

		UpdateTerrorists()
	End Method


	Method UpdateTerrorists:int()
		'who is the mainaggressor? - this parties levelProgress grows faster
		local mainAggressor:int = (terroristAggressionLevel[1] + terroristAggressionLevelProgress[1] > terroristAggressionLevel[0] + terroristAggressionLevelProgress[0])

		For local i:int = 0 to 1
			If terroristUpdateTime[i] >= GetWorldTime().GetTimeGone() then continue
			UpdateTerrorist(i, mainAggressor)
		Next
	End Method


	Method UpdateTerrorist:int(terroristNumber:int, mainAggressor:int)
		'set next update time (between min-max interval)
		terroristUpdateTime[terroristNumber] = GetWorldTime().GetTimeGone() + 60*randRange(terroristUpdateTimeInterval[0], terroristUpdateTimeInterval[1])


		'adjust level progress

		'randRange uses "ints", so convert 1.0 to 100
		local increase:Float = 0.01 * randRange(int(terroristAggressionLevelProgressRate[terroristNumber][0]*100), int(terroristAggressionLevelProgressRate[terroristNumber][1]*100))
		'if not the mainaggressor, grow slower
		if terroristNumber <> mainAggressor then increase :* 0.5

		'each level has its custom increasement
		'so responses come faster and faster
		Select terroristAggressionLevel[terroristNumber]
			case 1
				terroristAggressionLevelProgress[terroristNumber] :+ 1.05 * increase
			case 2
				terroristAggressionLevelProgress[terroristNumber] :+ 1.11 * increase
			case 3
				terroristAggressionLevelProgress[terroristNumber] :+ 1.20 * increase
			case 4
				terroristAggressionLevelProgress[terroristNumber] :+ 1.35 * increase
			default
				terroristAggressionLevelProgress[terroristNumber] :+ increase
		End Select


		'handle "level ups"
		'nothing to do if no level up happens
		if terroristAggressionLevelProgress[terroristNumber] < 1.0 then return False

		'set to next level
		SetTerroristAggressionLevel(terroristNumber, terroristAggressionLevel[terroristNumber] + 1)
	End Method


	Method OnChangeTerroristAggressionLevel:int(terroristGroup:int, oldLevel:int, newLevel:int)
		if terroristGroup < 0 or terroristGroup > 1 then return False

		'announce news for levels 1-4
		if terroristAggressionLevel[terroristGroup] <= terroristAggressionLevelMax
			local newsEvent:TNewsEvent = GetTerroristNewsEvent(terroristGroup)
			If newsEvent then announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + 0)
		endif
		return True
	End Method


	Method SetTerroristAggressionLevel:int(terroristGroup:int, level:int)
		if terroristGroup < 0 or terroristGroup > 1 then return False

		level = MathHelper.Clamp(level, 0, terroristAggressionLevelMax )
		'nothing to do
		if level = terroristAggressionLevel[terroristGroup] then return False

		local oldLevel:int = terroristAggressionLevel[terroristGroup]
		'assign new value
		terroristAggressionLevel[terroristGroup] = level
		'if progress was 1.05, keep the 0.05 for the new level
		terroristAggressionLevelProgress[terroristGroup] = Max(0, terroristAggressionLevelProgress[terroristGroup] - 1.0)


		'handle effects
		OnChangeTerroristAggressionLevel(terroristGroup, oldLevel, level)


		'reset level if limit reached, also delay next Update so things
		'do not happen one after another
		if terroristAggressionLevel[terroristGroup] >= terroristAggressionLevelMax
			'reset to level 0
			terroristAggressionLevel[terroristGroup] = 0
			'8 * normal random "interval"
			terroristUpdateTime[terroristGroup] :+ 8 * 60*randRange(terroristUpdateTimeInterval[0], terroristUpdateTimeInterval[1])
		endif
		return True
	End Method


	Method GetTerroristAggressionLevel:int(terroristGroup:int = -1)
		if terroristGroup >= 0 and terroristGroup <= 1
			'the level might be 0 already after the terrorist got his
			'command to go to a room ... so we check the figure too
			local level:int = terroristAggressionLevel[terroristGroup]
			local fig:TFigureTerrorist = TFigureTerrorist(GetGameBase().terrorists[terroristGroup])
			'figure is just delivering a bomb?
			if fig and fig.HasToDeliver() then return terroristAggressionLevelMax
			return level
		else
			return Max( GetTerroristAggressionLevel(0), GetTerroristAggressionLevel(1) )
		endif
	End Method


	Method GetTerroristNewsEvent:TNewsEvent(terroristGroup:int = 0)
		Local aggressionLevel:int = terroristAggressionLevel[terroristGroup]
		Local quality:Float = 0.01 * (randRange(50,60) + aggressionLevel * 5)
		Local price:Float = 1.0 + 0.01 * (randRange(45,50) + aggressionLevel * 5)
		Local title:String
		Local description:String
		local genre:int = TVTNewsGenre.POLITICS_ECONOMY

		local localizeTitle:TLocalizedString
		local localizeDescription:TLocalizedString

		Select aggressionLevel
			case 1,2,3,4
				localizeTitle = GetRandomLocalizedString("NEWS_TERROR_GROUP"+(terroristGroup+1)+"_LEVEL"+aggressionLevel+"_TITLE")
				localizeDescription = GetRandomLocalizedString("NEWS_TERROR_GROUP"+(terroristGroup+1)+"_LEVEL"+aggressionLevel+"_TEXT")

				if aggressionLevel = 4
					'currents instead of politics
					genre = TVTNewsGenre.CURRENTAFFAIRS
				endif
			default
				return null
		End Select


		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, genre, quality, null, TVTNewsType.InitialNewsByInGameEvent)
		NewsEvent.SetModifier("price", price)

		'send out terrorist
		if aggressionLevel = terroristAggressionLevelMax
			local effect:TGameModifierBase = new TGameModifierBase

			effect.GetData().Add("figure", GetGameBase().terrorists[terroristGroup])
			effect.GetData().AddNumber("group", terroristGroup)
			'send figure to the intented target (it then looks for the position
			'using the "roomboard" - so switched signes are taken into
			'consideration there)
			if terroristGroup = 0
				effect.GetData().Add("room", GetRoomCollection().GetFirstByDetails("", "frduban"))
			else
				effect.GetData().Add("room", GetRoomCollection().GetFirstByDetails("", "vrduban"))
			endif
			'mark as a special effect so AI can categorize it accordingly
			effect.setModifierType(TVTGameModifierBase.TERRORIST_ATTACK)
			'defined function to call when executing
			effect.GetData().AddString("customRunFuncKey", "TFigureTerrorist.SendFigureToRoom")

			'Variant 1: pass delay to the SendFigureToRoom-function (delay delivery schedule)
			'effect.GetData().AddNumber("delayTime", 60 * RandRange(45,120))
			'Variant 2: delay the execution of the effect
			effect.SetDelayedExecutionTime(Long(GetWorldTime().GetTimeGone()) +  60 * RandRange(45,120))
			NewsEvent.effects.AddEntry("happen", effect)
		endif

		'send without delay!
		NewsEvent.SetFlag(TVTNewsFlag.SEND_IMMEDIATELY, True)
		'do not delay other news
		NewsEvent.SetFlag(TVTNewsFlag.KEEP_TICKER_TIME, True)

		NewsEvent.AddKeyword("TERRORIST")

		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)
		Return NewsEvent
	End Method


	Method GetMovieNewsEvent:TNewsEvent()
		Local licence:TProgrammeLicence = Self._GetAnnouncableProgrammeLicence()
		If Not licence Then Return Null
		If Not licence.getData() Then Return Null

		licence.GetData().releaseAnnounced = True

		Local localizeTitle:TLocalizedString
		Local localizeDescription:TLocalizedString

		'no director
		If licence.GetData().getActor(1) = null and licence.GetData().getDirector(1) = null
			localizeTitle = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_NO_CAST_TITLE")
			localizeDescription = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_NO_CAST_DESCRIPTION")
		'no actor named (eg. cartoon)
		elseif licence.GetData().getActor(1) = null
			localizeTitle = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_TITLE")
			localizeDescription = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_DESCRIPTION")
		'if same director and main actor...
		elseif licence.GetData().getActor(1) = licence.GetData().getDirector(1)
			localizeTitle = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_TITLE")
			localizeDescription = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_DESCRIPTION")
		'default
		else
			localizeTitle = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_TITLE")
			localizeDescription = GetRandomLocalizedString("NEWS_ANNOUNCE_MOVIE_DESCRIPTION")
		EndIf

		'replace data
		Self._ReplaceProgrammeData(localizeTitle, licence.GetData())
		Self._ReplaceProgrammeData(localizeDescription, licence.GetData())

		'quality and price are based on the movies data
		'quality of movie news never can reach quality of "real" news
		'so cut them to a specific range (0.10 - 0.80)
		local quality:Float = 0.1  + 0.70*licence.GetData().review
		'if outcome is less than 50%, it subtracts the price, else it increases
		local priceModifier:Float = 1.0 + 0.2 * (licence.GetData().outcome - 0.5)
		Local NewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, TVTNewsGenre.SHOWBIZ, quality, null, TVTNewsType.InitialNewsByInGameEvent)
		NewsEvent.SetModifier("price", priceModifier)

		'after 20 hours a news topicality is 0 - so accelerating it by
		'2 means it reaches topicality of 0 at 10 hours after creation.
		NewsEvent.SetModifier("topicality::age", 2)

		NewsEvent.AddKeyword("MOVIE")


		'add triggers
		'attention: not all persons have a popularity yet - skip them
		For local job:TProgrammePersonJob = EachIn licence.GetData().cast
			if job.personGUID
				local person:TProgrammePerson = GetProgrammePerson(job.personGUID)
				if person and person.GetPopularity()
					local jobMod:Float = TVTProgrammePersonJob.GetJobImportanceMod(job.job)
					if jobMod > 0.0
						NewsEvent.AddEffectByData(new TData.Add("trigger", "happen").Add("type", "ModifyPersonPopularity").Add("guid", job.personGUID).AddNumber("valueMin", 0.1 * jobMod).AddNumber("valueMax", 0.5 * jobMod))
						'TODO: take broadcast audience into consideration
						'      or maybe only use broadcastFirstTimeDone
						NewsEvent.AddEffectByData(new TData.Add("trigger", "broadcastDone").Add("type", "ModifyPersonPopularity").Add("guid", job.personGUID).AddNumber("valueMin", 0.01 * jobMod).AddNumber("valueMax", 0.025 * jobMod))
					endif
				endif
			endif
		Next
		'modify genre
		NewsEvent.AddEffectByData(new TData.Add("trigger", "broadcastFirstTime").Add("type", "ModifyMovieGenrePopularity").AddNumber("genre", licence.GetData().GetGenre()).AddNumber("valueMin", 0.025).AddNumber("valueMax", 0.04))
		NewsEvent.AddEffectByData(new TData.Add("trigger", "broadcast").Add("type", "ModifyMovieGenrePopularity").AddNumber("genre", licence.GetData().GetGenre()).AddNumber("valueMin", 0.005).AddNumber("valueMax", 0.01))


		GetNewsEventCollection().AddOneTimeEvent(NewsEvent)

		Return NewsEvent
	End Method


	Method _ReplaceProgrammeData:TLocalizedString(text:TLocalizedString, data:TProgrammeData)
		local actor:TProgrammePersonBase
		local director:TProgrammePersonBase
		For Local i:Int = 1 To 2
			actor = data.GetActor(i)
			director = data.GetDirector(i)
			if actor
				text.Replace("%ACTORNAME"+i+"%", actor.GetFullName())
			endif
			if director
				text.Replace("%DIRECTORNAME"+i+"%", director.GetFullName())
			endif
		Next
		text.Replace("%MOVIETITLE%", data.GetTitle())

		Return text
	End Method


	'helper to get a movie which can be used for a news
	Method _GetAnnouncableProgrammeLicence:TProgrammeLicence()
		'filter to entries we need
		Local candidates:TProgrammeLicence[] = new TProgrammeLicence[20]
		Local candidatesAdded:int = 0
		'series,collections,movies but no episodes/collection entries
		For local licence:TProgrammeLicence = EachIn GetProgrammeLicenceCollection()._GetParentLicences().Values()
			'must be in production!
			If not licence.GetData().IsInProduction() then continue
			'ignore if filtered out
			If licence.IsOwned() Then Continue
			'ignore already announced movies
			If licence.getData().releaseAnnounced Then Continue
			'ignore unreleased if outside the given filter
			If Not licence.GetData().ignoreUnreleasedProgrammes And licence.getData().GetYear() < TProgrammeData._filterReleaseDateStart Or licence.getData().GetYear() > TProgrammeData._filterReleaseDateEnd Then Continue

			if candidates.length >= candidatesAdded then candidates = candidates[.. candidates.length + 20]
			candidates[candidatesAdded] = licence
			candidatesAdded :+ 1
		Next
		if candidates.length > candidatesAdded then candidates = candidates[.. candidatesAdded]

		If candidates.length > 0 Then Return GetProgrammeLicenceCollection().GetRandomFromArray(candidates)

		Return Null
	End Method


	'creates new news events out of templates containing happenedTime-configs
	'-> call this method on start of a game
	Method CreateTimedNewsEvents:int()
		local now:long = GetWorldTime().GetTimeGone()

		For local template:TNewsEventTemplate = EachIn GetNewsEventTemplateCollection().GetUnusedAvailableInitialTemplates()
			if template.happenTime = -1 then continue

			'create fixed future news
			local newsEvent:TNewsEvent = new TNewsEvent.InitFromTemplate(template)

			'now and missed are not listed in the upcomingNewsList, so
			'no cache-clearance is needed
			'now
			if template.happenTime = 0 ' or template.HasFlag(TVTNewsFlag.TRIGGER_ON_GAME_START)
				template.happenTime = GetWorldTime().GetTimeGone()
				if template.IsAvailable()
					announceNewsEvent(newsEvent)
				endif
			'missed - only some minutes too late (eg gamestart news)
			'we could just announce them as their happen effects would
			'still be valid (attention: do not add a "new years eve -
			'drunken people"-effect as this would be active on game start
			'then)
			'this would mean a)
			elseif template.happenTime <= now
				'TODO: Wenn happened in der Vergangenheit liegt (und template noch nicht "used")
				'dann "onHappen" ausloesen damit Folgenachrichten kommen koennen
			endif

			GetNewsEventCollection().Add(newsEvent)
		Next
	End Method


	'announces planned news events (triggered by news some time before)
	Method ProcessUpcomingNewsEvents:Int()
		Local announced:Int = 0

		For local newsEvent:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
			'skip news events not happening yet
			If Not newsEvent.HasHappened() then continue
			announceNewsEvent(newsEvent)
			'attention: RESET_TICKER_TIME is only "useful" for followup news
			if newsEvent.HasFlag(TVTNewsFlag.RESET_TICKER_TIME)
				ResetNextEventTime(newsEvent.GetGenre())
			endif

			announced:+1
		Next

		'invalidate upcoming list
		if announced > 0 then GetNewsEventCollection()._InvalidateUpcomingNewsEvents()

		Return announced
	End Method


	'update external news sources and fetch their generated news
	Method ProcessNewsProviders:Int()
		local delayed:int = 0
		local announced:int = 0
		For local nP:TNewsAgencyNewsProvider = EachIn newsProviders
			nP.Update()
			For local newsEvent:TNewsEvent = EachIn nP.GetNewNewsEvents()
				'skip news events not happening yet
				'-> they will get processed once they happen (upcoming list)
				If not newsEvent.HasHappened()
					delayed:+1
					continue
				endif

				announceNewsEvent(newsEvent)

				'attention: KEEP_TICKER_TIME is only "useful" for initial/single news
				if not newsEvent.HasFlag(TVTNewsFlag.KEEP_TICKER_TIME)
					ResetNextEventTime(newsEvent.GetGenre())
				endif

				announced :+ 1
			Next

			nP.ClearNewNewsEvents()
		Next

		'invalidate upcoming list
		if delayed > 0 then GetNewsEventCollection()._InvalidateUpcomingNewsEvents()

		Return announced
	End Method


	'announces news to players with lower abonnement levels (delay)
	Method ProcessDelayedNews:Int()
		Local delayed:Int = 0

		For local playerID:int = 1 to delayedLists.Length
			local player:TPlayerBase = GetPlayerBase(playerID)
			if not delayedLists[playerID-1] or not player then continue

			local toRemove:TNews[]
			For local news:TNews = EachIn delayedLists[playerID-1]
				local genre:int = news.newsEvent.GetGenre()
				local subscriptionDelay:int = GetNewsAbonnementDelay(genre, player.GetNewsAbonnement(genre) )
				local maxSubscriptionDelay:int = GetNewsAbonnementDelay(genre, 1)

				'if playerID=1 then print "ProcessDelayedNews: " + news.GetTitle() + "  happened="+GetWorldTime().GetFormattedDate( news.GetHappenedTime())+"  announceToPlayer="+ GetWorldTime().GetFormattedDate( news.GetPublishTime() + subscriptionDelay )+ "  autoRemove=" + GetWorldTime().GetFormattedDate( news.GetPublishTime() + maxSubscriptionDelay + 1000 )

				'remove old news which are NOT subscribed on "latest
				'possible subscription-delay-time"
				'3600 - to also allow a bit "older" ones - like start news
				if news.GetPublishTime() + maxSubscriptionDelay + 3600 <  GetWorldTime().GetTimeGone()
					'mark the news for removal
					toRemove :+ [news]
					'print "ProcessDelayedNews #"+playerID+": Removed OLD/unsubscribed: " + news.GetTitle()
					continue
				endif


				'skip news events not for publishing yet
				if Not news.IsReadyToPublish(subscriptionDelay)
					continue
				endif

				'skip news events if not subscribed to its genre NOW
				'(including "not satisfying minimum subscription level")
				'alternatively also check: "or subscriptionDelay < 0"
				If not news.newsEvent.HasFlag(TVTNewsFlag.SEND_TO_ALL)
					If player.GetNewsabonnement(genre)<=0 or player.GetNewsabonnement(genre) < news.newsEvent.GetMinSubscriptionLevel()
						'if playerID=1 then print "ProcessDelayedNews #"+playerID+": NOT subscribed or not ready yet: " + news.GetTitle() + "   announceToPlayer="+ GetWorldTime().GetFormattedDate( news.GetPublishTime() + subscriptionDelay )
						continue
					endif
				endif


				'do not charge for immediate news
				if news.newsEvent.HasFlag(TVTNewsFlag.SEND_IMMEDIATELY)
					news.priceModRelativeNewsAgency = 0.0
				else
					news.priceModRelativeNewsAgency = GetNewsRelativeExtraCharge(genre, player.GetNewsAbonnement(genre))
				endif

				announceNews(news, playerID)

				'mark the news for removal
				toRemove :+ [news]
				delayed:+1
			Next

			For local news:TNews = EachIn toRemove
				delayedLists[playerID-1].Remove(news)
			Next

'			if playerID=1 then end
		Next

		Return delayed
	End Method


	Method RemoveFromDelayedListsByNewsEvent(playerID:int=0, newsEvent:TNewsEvent)
		if playerID<=0
			For local i:int = 1 to delayedLists.Length
				RemoveFromDelayedListsByNewsEvent(playerID, newsEvent)
			Next
		else
			if delayedLists.length >= playerID and delayedLists[playerID-1]
				local remove:TNews[]
				for local n:TNews = EachIn delayedLists[playerID-1]
					if n.newsEvent = newsEvent then remove :+ [n]
				next
				for local n:TNews = EachIn remove
					delayedLists[playerID-1].Remove(n)
				next
				for local n:TNews = EachIn delayedLists[playerID-1]
					if n.newsEvent = newsEvent then remove :+ [n]
				next
			endif
		endif
	End Method


	Method ResetDelayedList(playerID:int=0)
		if playerID<=0
			For local i:int = 1 to delayedLists.Length
				if delayedLists[i-1] then delayedLists[i-1].Clear()
			Next
		else
			if delayedLists.length >= playerID and delayedLists[playerID-1]
				delayedLists[playerID-1].Clear()
			endif
		endif
	End Method


	Function GetNewsAbonnementDelay:Int(genre:Int, level:int) {_exposeToLua}
		if level = 3 then return 0
		if level = 2 then return 60*60
		if level = 1 then return 150*60 'not needed but better overview
		return -1
	End Function


	'Returns the extra charge for a news
	Function GetNewsRelativeExtraCharge:Float(genre:Int, level:int) {_exposeToLua}
		'up to now: ignore genre, all share the same values
		if level = 3 then return 0.20
		if level = 2 then return 0.10
		if level = 1 then return 0.00 'not needed but better overview
		return 0.00
	End Function


	'Returns the price for this level of a news abonnement
	Function GetNewsAbonnementPrice:Int(playerID:int, newsGenreID:int, level:Int=0)
		if level = 1 then return 10000
		if level = 2 then return 25000
		if level = 3 then return 50000
		return 0
	End Function


	Method AddNewsEventToPlayer:Int(newsEvent:TNewsEvent, forPlayer:Int=-1, sendNow:Int=False, fromNetwork:Int=False)
		local player:TPlayerBase = GetPlayerBase(forPlayer)
		if not player then return False

		if newsEvent.HasFlag(TVTNewsFlag.INVISIBLE_EVENT) then return False

		local news:TNews = TNews.Create("", 0, newsEvent)

		sendNow = sendNow or newsEvent.HasFlag(TVTNewsFlag.SEND_IMMEDIATELY)
		If sendNow
			announceNews(news, player.playerID)
		Else
			'add to publishLater-List
			'so dynamical checks of "subscription levels" can take
			'place - and also "older" new will get added to the
			'players when they subscribe _after_ happening of the event
			if not delayedLists[player.playerID-1] then delayedLists[player.playerID-1] = CreateList()
			delayedLists[player.playerID-1].AddLast(news)
		EndIf
	End Method


	Method announceNewsEvent:Int(newsEvent:TNewsEvent, happenedTime:Double=0, sendNow:Int=False)
		if happenedTime = 0 then happenedTime = newsEvent.happenedTime
		newsEvent.doHappen(happenedTime)

		'only announce as news if not invisible
		if not newsEvent.HasFlag(TVTNewsFlag.INVISIBLE_EVENT)
			For Local i:Int = 1 To 4
				AddNewsEventToPlayer(newsEvent, i, sendNow)
			Next
		endif
	End Method


	'make news available for the player
	Method announceNews:Int(news:TNews, player:int)
		if not GetPlayerProgrammeCollection(player) then return False
		return GetPlayerProgrammeCollection(player).AddNews(news)
	End Method


	'generates a new news event from various sources (such as new
	'movie announcements, actor news ...)
	Method GenerateNewNewsEvent:TNewsEvent(genre:int = -1)
		local newsEvent:TNewsEvent = null

		'=== TYPE MOVIE NEWS ===
		'25% chance: try to load some movie news ("new movie announced...")
		if genre = -1 or genre = TVTNewsGenre.SHOWBIZ
			If Not newsEvent And RandRange(1,100) < 25
				newsEvent = GetMovieNewsEvent()
			EndIf
		endif


		'=== TYPE RANDOM NEWS ===
		'if no "special case" triggered, just use a random news
		If Not newsEvent
			newsEvent = GetNewsEventCollection().CreateRandomAvailable(genre)
		EndIf

		return newsEvent
	End Method

	'forceAdd: add regardless of abonnement levels?
	'sendNow: ignore delay of abonnement levels?
	'skipIfUnsubscribed: happen regardless of nobody subscribed to the news genre?
	Method AnnounceNewNewsEvent:TNewsEvent(genre:int=-1, adjustHappenedTime:Int=0, forceAdd:Int=False, sendNow:int=False, skipIfUnsubscribed:Int=True)
		'=== CREATE A NEW NEWS ===
		Local newsEvent:TNewsEvent = GenerateNewNewsEvent(genre)


		'=== ANNOUNCE THE NEWS ===
		local announced:int = False
		'only announce if forced or somebody is listening
		If newsEvent
			local skipNews:int = newsEvent.IsSkippable()
			'override newsevent skippability
			if not skipIfUnsubscribed then skipNews = False

			If skipNews
				For Local player:TPlayerBase = eachin GetPlayerBaseCollection().players
					'a player listens to this genre, disallow skipping
					If player.GetNewsabonnement(newsEvent.GetGenre()) > 0 Then skipNews = False
				Next
				if not forceAdd and not skipIfUnsubscribed
					?debug
					if skipNews then print "[NEWSAGENCY] Nobody listens to genre "+newsEvent.GetGenre()+". Skip news: ~q"+newsEvent.GetTitle()+"~q."
					?
					if skipNews then TLogger.Log("NewsAgency", "Nobody listens to genre "+newsEvent.GetGenre()+". Skip news: ~q"+newsEvent.GetTitle()+"~q.", LOG_DEBUG)
				else
					?debug
					if skipNews then print "[NEWSAGENCY] Nobody listens to genre "+newsEvent.GetGenre()+". Would skip news, but am forced to add: ~q"+newsEvent.GetTitle()+"~q."
					?
					if skipNews then TLogger.Log("NewsAgency", "Nobody listens to genre "+newsEvent.GetGenre()+". Would skip news, but am forced to add: ~q"+newsEvent.GetTitle()+"~q.", LOG_DEBUG)
				endif
			EndIf

			If not skipNews or forceAdd
				announceNewsEvent(newsEvent, GetWorldTime().GetTimeGone() + adjustHappenedTime, sendNow)
				announced = True
				TLogger.Log("NewsAgency", "Added news: ~q"+newsEvent.GetTitle()+"~q for day "+GetWorldTime().getDay(newsEvent.happenedtime)+" at "+GetWorldTime().GetFormattedTime(newsEvent.happenedtime)+".", LOG_DEBUG)
			EndIf
		EndIf


		'=== ADJUST TIME FOR NEXT NEWS ANNOUNCEMENT ===
		'reset even if no news was found - or if news allows so
		'attention: KEEP_TICKER_TIME is for initial news
		'           RESET_TICKER_TIME for follow up news
		if not newsEvent or not newsEvent.HasFlag(TVTNewsFlag.KEEP_TICKER_TIME)
			ResetNextEventTime(genre)
		endif

		if announced then return newsEvent
		return Null
	End Method


	Method SetNextEventTime:int(genre:int, time:Long)
		if genre >= TVTNewsGenre.count or genre < 0 then return False

		NextEventTimes[genre] = time
	End Method


	Method ResetNextEventTime:int(genre:int, addMinutes:int = 0)
		if genre >= TVTNewsGenre.count or genre < 0 then return False

		'during night, news come not that often
		if GetWorldTime().GetDayHour() < 4
			addMinutes :+ RandRange(15,45)
		'during night, news come not that often
		elseif GetWorldTime().GetDayHour() >= 22
			addMinutes :+ RandRange(15,30)
		'work time - even earlier now
		elseif GetWorldTime().GetDayHour() > 8 and GetWorldTime().GetDayHour() < 14
			addMinutes :- RandRange(15,30)
		endif


		'adjust time until next news
		NextEventTimes[genre] = GetWorldTime().GetTimeGone() + 60 * (randRange(NextEventTimeIntervals[genre][0], NextEventTimeIntervals[genre][1]) + addMinutes)

		'25% chance to have an even longer time (up to 2x)
		If RandRange(0,100) < 25
			NextEventTimes[genre] :+ randRange(NextEventTimeIntervals[genre][0], NextEventTimeIntervals[genre][1])
			TLogger.Log("NewsAgency", "Reset NextEventTime for genre "+genre+" to "+ GetWorldTime().GetFormattedDate(NextEventTimes[genre])+" ("+Long(NextEventTimes[genre])+"). DOUBLE TIME.", LOG_DEBUG)
		else
			TLogger.Log("NewsAgency", "Reset NextEventTime for genre "+genre+" to "+ GetWorldTime().GetFormattedDate(NextEventTimes[genre])+" ("+Long(NextEventTimes[genre])+")", LOG_DEBUG)
		EndIf
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return singleton instance
Function GetNewsAgency:TNewsAgency()
	Return TNewsAgency.GetInstance()
End Function




Type TNewsAgencyNewsProvider
	Field newNewsEvents:TNewsEvent[]


	Method Initialize:int()
		ClearNewNewsEvents()
	End Method


	Method Update:int() abstract


	Method AddNewNewsEvent:int(newsEvent:TNewsEvent)
		newNewsEvents :+ [newsEvent]
	End Method


	Method GetNewNewsEvents:TNewsEvent[]()
		return newNewsEvents
	End Method


	Method ClearNewNewsEvents:int()
		newNewsEvents = newNewsEvents[..0]
		return True
	End Method
End Type



