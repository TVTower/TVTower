SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.newsagency.bmx"

Type TDebugScreenPage_NewsAgency extends TDebugScreenPage
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

		RenderNewsAgencyQueue(playerID, position.x + 5, 13, 495, 190)
		RenderNewsAgencyGenreSchedule(playerID, position.x + 5, 13 + 190 + 10, 200, 140)
		RenderNewsAgencyInformation(playerID, position.x + 5 + 200 + 10, 13 + 190 + 10, 285, 140)
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
				textFont.DrawSimple(GetWorldTime().GetFormattedGameDate(n.happenedTime), textX, textY)
				textFont.DrawSimple(n.GetTitle() + "  ("+GetLocale("NEWS_"+TVTNewsGenre.GetAsString(n.GetGenre()))+")", textX + 100, textY)
				textY :+ 12
				nCount :+ 1
				If nCount > 12 Then Exit
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
