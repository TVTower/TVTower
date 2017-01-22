SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.award.base.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.broadcastmaterial.programme.bmx"

TAwardBaseCollection.AddAwardCreatorFunction(TVTAwardType.GetAsString(TVTAwardType.CULTURE), TAwardCulture.CreateAwardCulture )


'AwardCulture:
'Send the most culture-linked things on your channel.
'Score is given for:
'- broadcasting culture programmes
'- broadcasting culture news
Type TAwardCulture extends TAwardBase
	'how important are news for the award
	Global newsWeight:float = 0.25
	
	Global _registeredListeners:TLink[]
	Global _eventListeners:TLink[]
	

	Method New()
		awardType = TVTAwardType.CULTURE

		'=== REGISTER EVENTS ===
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'scan news shows for culture news
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllNewsShowBroadcasts", onBeforeFinishAllNewsShowBroadcasts) ]
		'scan programmes for culture-flag
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllProgrammeBlockBroadcasts", onBeforeFinishAllProgrammeBlockBroadcasts) ]
	End Method


	Function CreateAwardCulture:TAwardCulture()
		return new TAwardCulture
	End Function


	'override
	Method GenerateGUID:string()
		return "awardculture-"+id
	End Method


	Function onBeforeFinishAllNewsShowBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardCulture = TAwardCulture(GetAwardBaseCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local newsShow:TNewsShow = Eachin broadcasts
			local score:int = CalculateNewsShowScore(newsShow)
			if score = 0 then continue

			currentAward.AdjustScore(newsShow.owner, score)
		Next
	End Function


	Function onBeforeFinishAllProgrammeBlockBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardCulture = TAwardCulture(GetAwardBaseCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))

		For local broadcastMaterial:TBroadcastMaterial = Eachin broadcasts
			'only material which ends now ? So a 5block culture would get
			'ignored if ending _after_ award time 
			'if broadcastMaterial.currentBlockBroadcasting <> broadcastMaterial.GetBlocks()

			local score:int = CalculateProgrammeScore(broadcastMaterial)
			if score = 0 then continue

			currentAward.AdjustScore(broadcastMaterial.owner, score)
		Next
	End Function


	Function CalculateProgrammeScore:int(broadcastMaterial:TBroadcastMaterial)
		'for now only handle "programmes", not "infomercials"
		local programme:TProgramme = TProgramme(broadcastMaterial)
		if not programme or programme.owner < 0 then return 0


		'calculate score:
		'a perfect culture programme would give 1000 points (plus personal
		'taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- "Live" increases score
		'- "Trash/BMovie" decrease score

		'only interested in culture-programmes
		if not programme.data.HasFlag(TVTProgrammeDataFlag.CULTURE) then return 0

		local points:Float = 1000 * broadcastMaterial.GetQuality()
		local pointsMod:Float = 1.0

		if programme.data.HasFlag(TVTProgrammeDataFlag.LIVE) then pointsMod :+ 0.1
		if programme.data.HasFlag(TVTProgrammeDataFlag.TRASH) then pointsMod :- 0.1
		if programme.data.HasFlag(TVTProgrammeDataFlag.BMOVIE) then pointsMod :- 0.1
		if programme.data.HasFlag(TVTProgrammeDataFlag.PAID) then pointsMod :- 0.2

		'divide by block count so each block adds some points
		points :/ programme.GetBlocks()
		
		'calculate final score
		return int(ceil(Max(0, points * pointsMod)))
	End Function
	

	Function CalculateNewsShowScore:int(newsShow:TNewsShow)
		if not newsShow
			TLogger.Log("TAwardNews.CalculateNewsShowScore()", "No valid TNewsSow-material given.", LOG_ERROR)
			return 0
		endif
		if newsShow.owner < 0 then return 0


		'calculate score:
		'a perfect culture news would give 1000 points (plus personal
		'taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- no need to handle multiple slots - each culture news brings
		'  score, no average building needed

		local allPoints:Float = 0.0
		For local i:int = 0 until newsShow.news.length
			local news:TNews = TNews(newsShow.news[i])
			if not news or news.GetGenre() <> TVTNewsGenre.CULTURE then continue

			local newsPoints:Float = 1000 * news.GetQuality() * TNewsShow.GetNewsSlotWeight(i)
			local newsPointsMod:Float = 1.0

			'jury likes good news - and dislikes the really bad ones
			if news.newsEvent.GetQualityRaw() >= 0.2
				newsPointsMod :+ 0.2
			else
				newsPointsMod :- 0.2
			endif

			allPoints :+ Max(0, newsPoints * newsPointsMod)
		Next

		'calculate final score
		'news have only a small influence
		return int(ceil(newsWeight * allPoints))
	End Function
End Type