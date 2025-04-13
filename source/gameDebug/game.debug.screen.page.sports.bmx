SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.newsagency.sports.bmx"

Type TDebugScreenPage_Sports extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Sports


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Sports()
		If Not _instance Then new TDebugScreenPage_Sports
		Return _instance
	End Function


	Method Init:TDebugScreenPage_Sports()
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
		RenderSportsBlock(position.x, 13)
	End Method


	Method RenderSportsBlock(x:Int, y:Int, w:Int=375, h:Int=300)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Sport Leagues", "", 0.0)
		Local textY:Int = contentRect.y

		Local mouseOverLeague:TNewsEventSportLeague

		For Local sport:TNewsEventSport = EachIn GetNewsEventSportCollection()
			textFont.DrawBox(sport.name, contentRect.x, textY, contentRect.w - 10 - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 13

			Local seasonInfo:String
			If sport.IsSeasonStarted() Then seasonInfo :+ "Started  "
			If sport.IsSeasonFinished() Then seasonInfo :+ "Finished  "
			If sport.ReadyForNextSeason() Then seasonInfo :+ "ReadyForNextSeason  "
			If sport.ArePlayoffsRunning() Then seasonInfo :+ "Playoffs running  "
			If sport.ArePlayoffsFinished() Then seasonInfo :+ "Playoffs finished  "
			textFont.DrawBox("  Season: " + seasonInfo, contentRect.X, textY, contentRect.w, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 13

			For Local league:TNewsEventSportLeague = EachIn sport.leagues
				Local col:SColor8 = SColor8.White

				If THelper.MouseIn(contentRect.x, textY, contentRect.w, 12)
					mouseOverLeague = league 
					col = SColor8.Yellow
				EndIf

				textFont.DrawBox("  L: " + league.name, contentRect.x, textY, contentRect.w, 15, sALIGN_LEFT_TOP, col)

				Local matchInfo:String
				matchInfo :+ "Matches " + GetWorldTime().GetFormattedDate(league.GetFirstMatchTime(), "g/h:i")
				matchInfo :+ " to " + GetWorldTime().GetFormattedDate(league.GetLastMatchTime(), "g/h:i")
				matchInfo :+ "   Next " + GetWorldTime().GetFormattedDate(league.GetNextMatchTime(), "g/h:i")
				textFont.DrawBox(matchInfo, contentRect.x + 140, textY, contentRect.w - 140, 15, sALIGN_LEFT_TOP, col)
				If league.IsSeasonFinished() 
					textFont.DrawBox("FIN", contentRect.x + contentRect.w - 35, textY, 25, 15, sALIGN_RIGHT_TOP, col)
				Else
					textFont.DrawBox(league.GetDoneMatchesCount() + "/" + league.GetMatchCount(), contentRect.x + contentRect.w - 35, textY, 35, 15, sALIGN_RIGHT_TOP, col)
				EndIf

				textY :+ 11
			Next

			textY :+ 6
		Next

		If mouseOverLeague
			RenderSportsLeagueBlock(mouseOverLeague, x + w + 5, y)
		EndIf
	End Method


	Method RenderSportsLeagueBlock(league:TNewsEventSportLeague, x:Int, y:Int, w:Int=190, h:Int=300)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Leaderboard", "", 0.0)
		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y

		For Local rank:TNewsEventSportLeagueRank = EachIn league.GetLeaderboard()
			textFont.DrawBox(rank.team.GetTeamName(), textX, textY, w - 25, 15, sALIGN_LEFT_TOP, SColor8.White)
			textFont.DrawBox(rank.score, textX + w - 20, textY, 20, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 12
			textFont.DrawBox("Attr: " + MathHelper.NumberToString(rank.team.GetAttractivity()*100,0) + "  Pwr: " + MathHelper.NumberToString(rank.team.GetPower()*100,0) + "  Skill: " + MathHelper.NumberToString(rank.Team.GetSkill()*100,0), textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textY :+ 12 + 4 
		Next
	End Method
End Type
