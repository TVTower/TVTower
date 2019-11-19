SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.award.base.bmx"
Import "game.broadcastmaterial.news.bmx"

TAwardCollection.AddAwardCreatorFunction(TVTAwardType.GetAsString(TVTAwardType.NEWS), TAwardNews.CreateAwardNews )



Type TAwardNews extends TAward
	Global _eventListeners:TEventListenerBase[]


	Method New()
		awardType = TVTAwardType.NEWS

		priceMoney = 25000
		priceImage = 2.0

		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'react to news shows
		'news(event)-quality is adjusted (aired amount increases,
		'topicality decreases) right on finishing - so we listen to just
		'before
		_eventListeners :+ [ EventManager.registerListenerFunction( "broadcasting.BeforeFinishAllNewsShowBroadcasts", onBeforeFinishAllNewsShowBroadcasts) ]
	End Method


	Function CreateAwardNews:TAwardNews()
		return new TAwardNews
	End Function


	'override
	Method GenerateGUID:string()
		return "awardnews-"+id
	End Method


	'Method Reset()
	'Method Finish()

	Function onBeforeFinishAllNewsShowBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardNews = TAwardNews(GetAwardCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local newsShow:TNewsShow = Eachin broadcasts
			local score:int = CalculateNewsShowScore(newsShow)
			if score = 0 then continue

			currentAward.AdjustScore(newsShow.owner, score)
		Next
	End Function


	Function CalculateNewsShowScore:int(newsShow:TNewsShow)
		if not newsShow
			TLogger.Log("TAwardNews.CalculateNewsShowScore()", "No valid TNewsSow-material given.", LOG_ERROR)
			return 0
		endif
		if newsShow.owner < 0 then return 0


		'calculate score:
		'a perfect news would give 1000 points (plus personal taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- genres like "yellow press" (or movies/showbizz) reduce points
		'  (jury thinks they are better than others)
		'- there are 3 news slots, so sum them all up and divide by 3
		'- bonus for premiering/first-broadcast news
		'- exclusive stories get a bonus
		'  this also takes care of empty slots (1.0 + 0.0 + 0.0 becomes 0.3)

		local allPoints:Float = 0.0
		For local i:int = 0 until newsShow.news.length
			local news:TNews = TNews(newsShow.news[i])
			if not news then continue
			'not of interest for us?
			if news.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_AWARDS) then continue


			local newsPoints:Float = 1000 * news.GetQuality() * TNewsShow.GetNewsSlotWeight(i)
			local newsPointsMod:Float = 1.0

			Select news.GetGenre()
				case TVTNewsGenre.SHOWBIZ
					'jury dislikes SHOWBIZ - except good stories!
					if news.GetNewsEvent().GetQualityRaw() < 0.8 then newsPointsMod :- 0.1
				case TVTNewsGenre.CULTURE
					'jury likes CULTURE - except the really bad ones
					if news.GetNewsEvent().GetQualityRaw() >= 0.2
						newsPointsMod :+ 0.1
					else
						newsPointsMod :- 0.1
					endif
			End Select

			'not aired before? (this is also considered in news.GetQuality() !)
			if news.GetNewsEvent().GetTimesBroadcasted() = 0 then newsPointsMod :+ 0.1
			if news.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.EXCLUSIVE_TO_ONE_OWNER) then newsPointsMod :+ 0.1

			allPoints :+ Max(0, newsPoints * newsPointsMod)
		Next

		'calculate final score
		return allPoints / newsShow.news.length
	End Function
End Type