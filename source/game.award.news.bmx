SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.award.base.bmx"
Import "game.broadcastmaterial.news.bmx"

TAwardBaseCollection.AddAwardCreatorFunction(TVTAwardType.GetAsString(TVTAwardType.NEWS), TAwardNews.CreateAwardNews )



Type TAwardNews extends TAwardBase
	Global _registeredListeners:TLink[]
	Global _eventListeners:TLink[]
	

	Method New()
		awardType = TVTAwardType.NEWS

		'=== REGISTER EVENTS ===
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

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
		local currentAward:TAwardNews = TAwardNews(GetAwardBaseCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local newsShow:TNewsShow = Eachin broadcasts
			local score:int = CalculateNewsShowScore(newsShow)

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
		'a perfect news would give 100.0 points (plus personal taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- genres like "yellow press" (or movies/showbizz) reduce points
		'  (jury things they are better than others)
		'- there are 3 news slots, so sum them all up and divide by 3
		'  this also takes care of empty slots (1.0 + 0.0 + 0.0 becomes 0.3)

		local allPoints:Float = 0.0
		For local i:int = 0 until newsShow.news.length
			local news:TNews = TNews(newsShow.news[i])
			if not news then continue

			local newsPoints:Float = 100.0 * news.GetQuality() * TNewsShow.GetNewsSlotWeight(i)

			Select news.GetGenre()
				case TVTNewsGenre.SHOWBIZ
					'jury dislikes SHOWBIZ - except good stories!
					if news.GetQuality() < 0.8 then newsPoints :* 0.9
				case TVTNewsGenre.CULTURE
					'jury likes CULTURE - except the really bad ones
					if news.GetQuality() >= 0.2
						newsPoints :* 1.1
					else
						newsPoints :* 0.9
					endif
			End Select

			allPoints :+ newsPoints
		Next

		'calculate final score
		return allPoints / newsShow.news.length
	End Function
End Type