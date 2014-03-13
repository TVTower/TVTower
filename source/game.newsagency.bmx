'likely a kind of agency providing news... 'at the moment only a base object
Type TNewsAgency
	Field NextEventTime:Double		= 0
	Field NextChainChecktime:Double	= 0
	Field activeChains:TList		= CreateList() 'holding chained news from the past hours/day

	Method Create:TNewsAgency()
		'maybe do some initialization here

		Return Self
	End Method

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
			Local licenceTime:Int = licence.GetData().year * Game.daysPerYear + licence.getData().releaseDay
			If licenceTime > Game.getDay() And licenceTime - Game.getDay() < 14 Then resultList.addLast(licence)
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

			If chainElement.happenedTime + newsEvent.getHappenDelay() < Game.timeGone
				announceNewsEvent(newsEvent)
				announced:+1
			EndIf
		Next

		'check every 10 game minutes
		Self.NextChainCheckTime = Game.timeGone + 10

		Return announced
	End Method

	Method AddNewsEventToPlayer:Int(newsEvent:TNewsEvent, forPlayer:Int=-1, fromNetwork:Int=0)
		'only add news/newsblock if player is Host/Player OR AI
		'If Not Game.isLocalPlayer(forPlayer) And Not Game.isAIPlayer(forPlayer) Then Return 'TODO: Wenn man gerade Spieler 2 ist/verfolgt (Taste 2) dann bekommt Spieler 1 keine News
		If Game.Players[ forPlayer ].newsabonnements[newsEvent.genre] > 0
			'print "[LOCAL] AddNewsToPlayer: creating newsblock, player="+forPlayer
			TNews.Create("", forPlayer, Game.Players[ forPlayer ].GetNewsAbonnementDelay(newsEvent.genre), newsEvent)
		EndIf
	End Method

	Method announceNewsEvent:Int(newsEvent:TNewsEvent, happenedTime:Int=0)
		newsEvent.doHappen(happenedTime)

		For Local i:Int = 1 To 4
			AddNewsEventToPlayer(newsEvent, i)
		Next

		If newsEvent.episodes.count() > 0 Then activeChains.AddLast(newsEvent)
	End Method

	Method AnnounceNewNewsEvent:Int(delayAnnouncement:Int=0)
		'no need to check for gameleader - ALL players
		'will handle it on their own - so the randomizer stays intact
		'if not Game.isGameLeader() then return FALSE
		Local newsEvent:TNewsEvent = Null
		'try to load some movie news ("new movie announced...")
		If Not newsEvent And RandRange(1,100)<35 Then newsEvent = Self.GetMovieNewsEvent()

		If Not newsEvent Then newsEvent = NewsEventCollection.GetRandom()

		If newsEvent
			Local NoOneSubscribed:Int = True
			For Local i:Int = 1 To 4
				If Game.Players[i].newsabonnements[newsEvent.genre] > 0 Then NoOneSubscribed = False
			Next
			'only add news if there are players wanting the news, else save them
			'for later stages
			If Not NoOneSubscribed
				'Print "[LOCAL] AnnounceNewNews: added news title="+news.title+", day="+Game.getDay(news.happenedtime)+", time="+Game.GetFormattedTime(news.happenedtime)
				announceNewsEvent(newsEvent, Game.timeGone + delayAnnouncement)
			EndIf
		EndIf

		If RandRange(0,10) = 1
			NextEventTime = Game.timeGone + Rand(20,50) 'between 20 and 50 minutes until next news
		Else
			NextEventTime = Game.timeGone + Rand(90,250) 'between 90 and 250 minutes until next news
		EndIf
	End Method
End Type