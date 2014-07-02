'likely a kind of agency providing news...
'at the moment only a base object
Type TNewsAgency
	Field NextEventTime:Double = 0
	Field NextChainChecktime:Double = 0
	'holding chained news from the past hours/day
	Field activeChains:TList = CreateList()
	Global _instance:TNewsAgency


	Function GetInstance:TNewsAgency()
		if not _instance then _instance = new TNewsAgency
		return _instance
	End Function


	Method GetMovieNewsEvent:TNewsEvent()
		Local licence:TProgrammeLicence = Self._GetAnnouncableProgrammeLicence()
		If Not licence Then Return Null
		If Not licence.getData() Then Return Null

		licence.GetData().releaseAnnounced = True

		Local title:String = getLocale("NEWS_ANNOUNCE_MOVIE_TITLE"+Rand(1,2) )
		Local description:String = getLocale("NEWS_ANNOUNCE_MOVIE_DESCRIPTION"+Rand(1,4) )

		'if same director and main actor...
		If licence.GetData().getActor(1) = licence.GetData().getDirector(1)
			title = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_ACTOR_IS_DIRECTOR_DESCRIPTION")
		EndIf
		'if no actors ...
		If licence.GetData().getActor(1) = ""
			title = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_TITLE")
			description = getLocale("NEWS_ANNOUNCE_MOVIE_NO_ACTOR_DESCRIPTION")
		EndIf

		'replace data
		title = Self._ReplaceProgrammeData(title, licence.GetData())
		description = Self._ReplaceProgrammeData(description, licence.GetData())

		'quality and price are based on the movies data
		Local NewsEvent:TNewsEvent = TNewsEvent.Create(title, description, 1, licence.GetData().review/2.0, licence.GetData().outcome/3.0)
		'remove news from available list as we do not want to have them repeated :D
		NewsEventCollection.Remove(NewsEvent)

		Return NewsEvent
	End Method


	Method _ReplaceProgrammeData:String(text:String, data:TProgrammeData)
		For Local i:Int = 1 To 2
			text = text.Replace("%ACTORNAME"+i+"%", data.getActor(i))
			text = text.Replace("%DIRECTORNAME"+i+"%", data.getDirector(i))
		Next
		text = text.Replace("%MOVIETITLE%", data.title)

		Return text
	End Method


	'helper to get a movie which can be used for a news
	Method _GetAnnouncableProgrammeLicence:TProgrammeLicence()
		'filter to entries we need
		Local licence:TProgrammeLicence
		Local resultList:TList = CreateList()
		For licence = EachIn TProgrammeLicence.movies
			'ignore collection and episodes (which should not be in that list)
			If Not licence.getData() Then Continue

			'ignore if filtered out
			If licence.owner <> 0 Then Continue
			'ignore already announced movies
			If licence.getData().releaseAnnounced Then Continue
			'ignore unreleased
			If Not licence.ignoreUnreleasedProgrammes And licence.getData().year < licence._filterReleaseDateStart Or licence.getData().year > licence._filterReleaseDateEnd Then Continue
			'only add movies of "next X days" - 14 = 1 year
			Local licenceTime:Int = licence.GetData().year * GetGameTime().daysPerYear + licence.getData().releaseDay
			If licenceTime > GetGameTime().getDay() And licenceTime - GetGameTime().getDay() < 14 Then resultList.addLast(licence)
		Next
		If resultList.count() > 0 Then Return TProgrammeLicence._GetRandomFromList(resultList)

		Return Null
	End Method


	Method GetSpecialNewsEvent:TNewsEvent()
	End Method


	'announces new news chain elements
	Method ProcessNewsEventChains:Int()
		Local announced:Int = 0
		Local newsEvent:TNewsEvent = Null
		For Local chainElement:TNewsEvent = EachIn activeChains
			If Not chainElement.isLastEpisode() Then newsEvent = chainElement.GetNextNewsEventFromChain()
			'remove the "old" one, the new element will get added instead (if existing)
			activeChains.Remove(chainElement)

			'ignore if the chain ended already
			If Not newsEvent Then Continue

			If chainElement.happenedTime + newsEvent.getHappenDelay() < GetGameTime().timeGone
				announceNewsEvent(newsEvent)
				announced:+1
			EndIf
		Next

		'check every 10 game minutes
		Self.NextChainCheckTime = GetGameTime().timeGone + 10

		Return announced
	End Method


	Function GetNewsAbonnementDelay:Int(genre:Int, level:int) {_exposeToLua}
		if level = 3 then return 0
		if level = 2 then return 60
		if level = 1 then return 150 'not needed but better overview
		return 150
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
	Function GetNewsAbonnementPrice:Int(level:Int=0)
		if level = 1 then return 10000
		if level = 2 then return 20000
		if level = 3 then return 35000
		return 0
	End Function


	Method AddNewsEventToPlayer:Int(newsEvent:TNewsEvent, forPlayer:Int=-1, fromNetwork:Int=0)
		local player:TPlayer = GetPlayerCollection().Get(forPlayer)
		'only add news/newsblock if player is Host/Player OR AI
		'If Not Game.isLocalPlayer(forPlayer) And Not Game.isAIPlayer(forPlayer) Then Return 'TODO: Wenn man gerade Spieler 2 ist/verfolgt (Taste 2) dann bekommt Spieler 1 keine News
		If Player.newsabonnements[newsEvent.genre] > 0
			local news:TNews = TNews.Create("", 0, newsEvent)

			news.publishDelay = GetNewsAbonnementDelay(newsEvent.genre, Player.newsabonnements[newsEvent.genre] )
			news.priceModRelativeNewsAgency = GetNewsRelativeExtraCharge(newsEvent.genre, GetPlayerCollection().Get(forPlayer).GetNewsAbonnement(newsEvent.genre))

			'add to players collection (sends out event which gets
			'recognized by the network handler)
			player.GetProgrammeCollection().AddNews(news)
		EndIf
	End Method


	Method announceNewsEvent:Int(newsEvent:TNewsEvent, happenedTime:Int=0)
		newsEvent.doHappen(happenedTime)

		For Local i:Int = 1 To 4
			AddNewsEventToPlayer(newsEvent, i)
		Next

		If newsEvent.episodes.count() > 0 Then activeChains.AddLast(newsEvent)
	End Method


	'generates a new news event from various sources (such as new
	'movie announcements, actor news ...)
	Method GenerateNewNewsEvent:TNewsEvent()
		local newsEvent:TNewsEvent = null

		'=== TYPE MOVIE NEWS ===
		'35% chance: try to load some movie news ("new movie announced...")
		If Not newsEvent And RandRange(1,100) < 35
			newsEvent = GetMovieNewsEvent()
		EndIf


		'=== TYPE RANDOM NEWS ===
		'if no "special case" triggered, just use a random news
		If Not newsEvent
			newsEvent = NewsEventCollection.GetRandom()
		EndIf

		return newsEvent
	End Method


	Method AnnounceNewNewsEvent:Int(delayAnnouncement:Int=0)
		'=== CREATE A NEW NEWS ===
		Local newsEvent:TNewsEvent = GenerateNewNewsEvent()


		'=== ANNOUNCE THE NEWS ===
		'only announce if forced or somebody is listening
		If newsEvent
			local skipNews:int = newsEvent.IsSkippable()
			If skipNews
				For Local player:TPlayer = eachin GetPlayerCollection().players
					'a player listens to this genre, disallow skipping
					If player.newsabonnements[newsEvent.genre] > 0 Then skipNews = False
				Next
			EndIf

			If not skipNews
				'Print "[LOCAL] AnnounceNewNews: added news title="+news.title+", day="+GetGameTime().getDay(news.happenedtime)+", time="+GetGameTime().GetFormattedTime(news.happenedtime)
				announceNewsEvent(newsEvent, GetGameTime().timeGone + delayAnnouncement)
			EndIf
		EndIf


		'=== ADJUST TIME FOR NEXT NEWS ANNOUNCEMENT ===
		If RandRange(0,10) = 1
			'between 20 and 50 minutes until next news
			NextEventTime = GetGameTime().timeGone + Rand(20,50)
		Else
			'between 90 and 250 minutes until next news
			NextEventTime = GetGameTime().timeGone + Rand(90,250)
		EndIf
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return singleton instance
Function GetNewsAgency:TNewsAgency()
	Return TNewsAgency.GetInstance()
End Function
