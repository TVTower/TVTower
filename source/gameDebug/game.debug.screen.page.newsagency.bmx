SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.newsagency.bmx"

Type TDebugScreenPage_NewsAgency extends TDebugScreenPage
	Field hoveredNewsEvent:TNewsEvent
	Global _instance:TDebugScreenPage_NewsAgency


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_NewsAgency()
		If Not _instance Then new TDebugScreenPage_NewsAgency
		Return _instance
	End Function


	Method Init:TDebugScreenPage_NewsAgency()
		Return self
	End Method


	Method Reset()
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		self.hoveredNewsEvent = Null

		RenderNewsAgencyHistory(playerID, position.x + 5, 13, 465, 70)
		RenderNewsAgencyQueue(playerID, position.x + 5, 13 +80, 465, 150)
		RenderNewsAgencyGenreSchedule(playerID, position.x + 5, 13 + 190 + 45, 200, 110)
		RenderNewsAgencyInformation(playerID, position.x + 5 + 200 + 10, 13 + 190 + 45, 255, 110)
		
		If hoveredNewsEvent
			RenderNewsEventInfo(playerID, position.x + 475, 13, 190, 345)
		EndIf
	End Method


	Method RenderNewsEventInfo(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		If Not hoveredNewsEvent Then Return
		
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textY :+ textFont.DrawSimple("ID: " + hoveredNewsEvent.GetID(), textX, textY).y
		textY :+ textFont.DrawSimple("Price: " + hoveredNewsEvent.GetPrice(), textX, textY).y

		If hoveredNewsEvent.triggeredByID or hoveredNewsEvent.GetEffectsList("happen")
			'move up as much as possible
			Local newsEventChain:TNewsEvent[] = [hoveredNewsEvent]

			Local triggeredByNewsEvent:TNewsEvent
			Local newsEvent:TNewsEvent = hoveredNewsEvent
			Repeat 
				triggeredByNewsEvent = Null
				If newsEvent.triggeredByID
					triggeredByNewsEvent = GetNewsEventCollection().GetByID(newsEvent.triggeredByID)
					if triggeredByNewsEvent
						newsEventChain = [triggeredByNewsEvent] + newsEventChain
						newsEvent = triggeredByNewsEvent
					EndIf
				EndIf
			until triggeredByNewsEvent = Null
			
			If newsEventChain.length > 0
				textY :+ textFont.DrawSimple("Chain:", textX, textY).y
				For local i:int = 0 until newsEventChain.length
					Local color:SColor8 = SColor8.White
					If hoveredNewsEvent = newsEventChain[i]
						color = New SColor8(255,200,200)
					EndIf
					Local t:String = newsEventChain[i].GetTitle()
					If Not t 
						If newsEventChain[i].HasFlag(TVTNewsFlag.INVISIBLE_EVENT)
							t = "Hidden Trigger News"
						Else
							t = "No title"
						EndIf
					EndIf
					textY :+ textFont.DrawBox(t, textX, textY, x + w - textX, 15, sALIGN_LEFT_TOP, color).y
					textY :- 2
					If newsEventChain[i].happenedTime > GetWorldTime().GetTimeGone()
						textY :+ textFont.DrawBox("happens: " + GetWorldTime().GetFormattedGameDate(newsEventChain[i].happenedTime) , textX, textY, x + w - textX - 5, 15, sALIGN_RIGHT_TOP, color).y
					Else
						textY :+ textFont.DrawBox("happened: " + GetWorldTime().GetFormattedGameDate(newsEventChain[i].happenedTime) , textX, textY, x + w - textX - 5, 15, sALIGN_RIGHT_TOP, New SColor8(255,255,255,200)).y
					EndIf
					textY :+ 2
				Next
			EndIf

			'add what it will trigger ?!
			Local entryLimit:Int = 15 'long chains might call itself again, or hundreds of other chains
			Local entryCount:Int = 0
			Local lastNewsEvent:TNewsEvent = newsEventChain[newsEventChain.length-1]
			Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByID(lastNewsEvent.templateID)
			while newsEventTemplate and entryCount < entryLimit
				Local effects:TList = newsEventTemplate.GetEffectsList("happen")
				If not effects Then exit

				' reset to exit in case of no triggernews effects
				newsEventTemplate = null
				
				For Local newsTrigger:TGameModifierNews_TriggerNews = EachIn effects
					Local color:SColor8 = SColor8.White
					newsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(newsTrigger.triggerNewsGUID)
					
					If newsEventTemplate and newsEventTemplate.GetID() = lastNewsEvent.templateID
						textY :+ textFont.DrawBox("-> last one again", textX, textY, x + w - textX, 15, sALIGN_LEFT_TOP, color).y
						newsEventTemplate = Null 'stop here
					ElseIf newsEventTemplate
						textY :+ textFont.DrawBox("-> " + newsEventTemplate.GetTitle(), textX, textY, x + w - textX, 15, sALIGN_LEFT_TOP, color).y
					Else
						textY :+ textFont.DrawBox("-> unknown news event", textX, textY, x + w - textX, 15, sALIGN_LEFT_TOP, color).y
					EndIf
					textY :- 2
					
					entryCount :+ 1
				Next
			Wend
		EndIf
		
	End Method


	Method RenderNewsAgencyHistory(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)

		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		
		Local lastNews:TNewsEvent[] = GetNewsEventCollection().GetNewsHistory(4) 'only last x
		textFont.DrawSimple("Log", textX, textY)
		textY :+ 12+3
		If lastNews.length = 0
			textFont.DrawSimple("--", textX, textY)
		Else
			For Local n:TNewsEvent = EachIn lastNews
				If THelper.MouseIn(textX, textY, x+w - textX, 12)
					self.hoveredNewsEvent = n
					
					Local oldA:Float = GetAlpha()

					SetColor 255,235,20
					SetAlpha Float(0.4)
					SetBlend LIGHTBLEND
					DrawRect(textX, textY, x+w - textX, 12)
					SetBlend ALPHABLEND
					SetAlpha oldA
					SetColor 255,255,255
				EndIf

				local textColor:SColor8 = SColor8.White
				' mark triggered-by-hovered news events 
				If hoveredNewsEvent and hoveredNewsEvent.GetID() = n.triggeredByID
					textColor = New Scolor8(255,235,20)
				EndIf

				textFont.DrawSimple(GetWorldTime().GetFormattedGameDate(n.happenedTime), textX, textY, textColor)
				Local genreW:Int = textFont.DrawBox(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(n.GetGenre())), textX + 100, textY, x + w - textX - 5 - 100, 15, sALIGN_RIGHT_TOP, New SColor8(255,255,255, 200)).x
				textFont.DrawBox(n.GetTitle(), textX + 100, textY, x + w - textX - 5 - 100 - genreW, 15, sALIGN_LEFT_TOP, textColor)
				textY :+ 12
			Next
		EndIf
	End Method
	

	Method RenderNewsAgencyQueue(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		
		Local upcoming:TObjectList = GetNewsEventCollection().GetUpcomingNewsList()

		textFont.DrawSimple("Queue", textX, textY)
		textY :+ 12+3
		If upcoming.Count() = 0
			textFont.DrawSimple("--", textX, textY)
		Else
			Local upcomingSorted:TObjectList = upcoming.Copy()
			upcomingSorted.sort(True, TNewsEventCollection.SortByHappenedTime)

			Local nCount:Int
			For Local n:TNewsEvent = EachIn upcomingSorted
				If THelper.MouseIn(textX, textY, x+w - textX, 12)
					self.hoveredNewsEvent = n
					
					Local oldA:Float = GetAlpha()

					SetColor 255,235,20
					SetAlpha Float(0.4)
					SetBlend LIGHTBLEND
					DrawRect(textX, textY, x+w - textX, 12)
					SetBlend ALPHABLEND
					SetAlpha oldA
					SetColor 255,255,255
				EndIf
				local textColor:SColor8 = SColor8.White
				' mark triggered-by-hovered news events 
				If hoveredNewsEvent and hoveredNewsEvent.GetID() = n.triggeredByID
					textColor = New Scolor8(255,235,20)
				EndIf

				textFont.DrawSimple(GetWorldTime().GetFormattedGameDate(n.happenedTime), textX, textY, textColor)
				Local genreW:Int = textFont.DrawBox(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(n.GetGenre())), textX + 100, textY, x + w - textX - 5 - 100, 15, sALIGN_RIGHT_TOP, New SColor8(255,255,255, 200)).x
				textFont.DrawBox(n.GetTitle(), textX + 100, textY, x + w - textX - 5 - 100 - genreW, 15, sALIGN_LEFT_TOP, textColor)
				textY :+ 12
				nCount :+ 1
				If nCount >= 10 Then Exit
			Next
		EndIf
	End Method


	Method RenderNewsAgencyGenreSchedule(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 100)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		Local upcomingCount:Int[TVTNewsGenre.count+1]
		For Local n:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
			upcomingCount[n.GetGenre()] :+ 1
		Next

		textFont.DrawSimple("Scheduled News", textX, textY)
		textY :+ 12 + 3
		textFont.DrawSimple("Genre", textX, textY)
		textFont.DrawSimple("Next", textX + 100, textY)
		textFont.DrawSimple("Upcoming", textX + 140, textY)
		textY :+ 12 + 3
		For Local i:Int = 0 Until TVTNewsGenre.count
			textFont.DrawSimple(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(i)), textX, textY)
			textFont.DrawSimple(GetWorldTime().GetFormattedTime(GetNewsAgency().NextEventTimes[i]), textX + 100, textY)
			textFont.DrawSimple(upcomingCount[i]+"x", textX + 140, textY)
			textY :+ 12
		Next
	End Method


	Method RenderNewsAgencyInformation(playerID:Int, x:Int, y:Int, w:Int = 180, h:Int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textFont.DrawSimple("Player News Subscriptions", textX, textY)
		textY :+ 12 + 3

		Local playerIndex:Int = 0
		Local textYBackup:Int = textY
		For Local player:TPlayerBase = EachIn GetPlayerBaseCollection().players
			textFont.DrawSimple(player.name, textX + playerIndex * 70, textY, player.color.Copy().AdjustBrightness(0.5).ToSColor8())
			textY :+ 12 + 3
			For Local genre:Int = 0 Until player.newsabonnements.length
				Local currLevel:Int = player.GetNewsAbonnement(genre)
				Local maxLevel:Int = max(0, player.GetNewsAbonnementDaysMax(genre))
				If currLevel < maxLevel
					textFont.DrawSimple(currLevel + " / " + maxLevel + " @ " + GetWorldTime().GetFormattedDate(player.newsabonnementsSetTime[genre], "h:i"), textX + playerIndex * 70, textY, SColor8.white)
				ElseIf currLevel > maxLevel
					'add time until "fixation" (so "end time")
					textFont.DrawSimple(currLevel + " @ " + GetWorldTime().GetFormattedDate(player.newsabonnementsSetTime[genre] + GameRules.newsSubscriptionIncreaseFixTime, "h:i") + " / " + maxLevel, textX + playerIndex * 70, textY, SColor8.white)
				Else
					textFont.DrawSimple(currLevel + " / " + maxLevel, textX + playerIndex * 70, textY, SColor8.white)
				EndIf
				textY :+ 12
			Next

			textY = textYBackup
			playerIndex :+ 1
		Next
	End Method
End Type
