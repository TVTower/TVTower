SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"

Type TDebugScreenPage_Misc extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Misc
	Field buttonsAwardControls:TDebugControlsButton[]

	Field FastForward_Active:Int = False
	Field FastForward_Continuous_Active:Int = False
	Field FastForwardSpeed:Int = 0 'initialized by reset
	Field FastForward_SwitchedPlayerToAI:Int = 0
	Field FastForward_TargetTime:Long = -1
	Field FastForward_SpeedFactorBackup:Float = 0.0
	Field FastForward_TimeFactorBackup:Float = 0.0
	Field FastForward_BuildingTimeSpeedFactorBackup:Float = 0.0
	Field FastForward_autoSaveBackup:Int


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Misc()
		If Not _instance Then new TDebugScreenPage_Misc
		Return _instance
	End Function


	Method Init:TDebugScreenPage_Misc()
		Local texts:String[] = ["Print Ad Stats", "Print Player's Today Finance Overview", "Print All Players' Finance Overview", "Print Player's Today Broadcast Stats", "Print Total Broadcast Stats", "Print Performance Stats", "Print Player's Programme Plan", "AI Game", "Fast Forward One Day"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], - 510, position.y)
			button.w = 185
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		InitAwardStatusButtons()
		Return self
	End Method

	Method InitAwardStatusButtons()
		Local texts:String[] = ["Finish", "P1", "P2", "P3", "P4", "Start Next", "Random", "Audience", "Culture" ,"Custom Production", "News"]
		Local mode:int = 0
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			If texts[i] = "-" Then Continue 'spacer
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button.dataInt = mode

			button._onClickHandler = OnButtonClickHandler_AwardStatusButtons

			mode :+ 1

			buttonsAwardControls :+ [button]
		Next
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For Local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy + 20
		Next
		Local x:Int = position.x + 210 + 200
		Local y:Int = 20
		Local buttonStartY:Int = 15
		If buttonsAwardControls.length >= 6
			buttonsAwardControls[ 0].SetXY(x              , y + 0 * 18 + buttonStartY).SetWH( 50, 15)
			buttonsAwardControls[ 1].SetXY(x + 54 + 0 * 22, y + 0 * 18 + buttonStartY).SetWH( 20, 15)
			buttonsAwardControls[ 2].SetXY(x + 54 + 1 * 22, y + 0 * 18 + buttonStartY).SetWH( 20, 15)
			buttonsAwardControls[ 3].SetXY(x + 54 + 2 * 22, y + 0 * 18 + buttonStartY).SetWH( 20, 15)
			buttonsAwardControls[ 4].SetXY(x + 54 + 3 * 22, y + 0 * 18 + buttonStartY).SetWH( 20, 15)
			buttonsAwardControls[ 5].SetXY(x              , y + 0 * 18 + buttonStartY).SetWH(145, 15)
			'add award - genres
			buttonsAwardControls[ 6].SetXY(x              , y + 2 * 18 + buttonStartY).SetWH(145, 15)
			buttonsAwardControls[ 7].SetXY(x              , y + 3 * 18 + buttonStartY).SetWH(145, 15)
			buttonsAwardControls[ 8].SetXY(x              , y + 4 * 18 + buttonStartY).SetWH(145, 15)
			buttonsAwardControls[ 9].SetXY(x              , y + 5 * 18 + buttonStartY).SetWH(145, 15)
			buttonsAwardControls[10].SetXY(x              , y + 6 * 18 + buttonStartY).SetWH(145, 15)
		EndIf
	End Method


	Method Reset()
		FastForward_Continuous_Active = False
		FastForward_Active = False
		FastForwardSpeed = GameRules.devConfig.GetInt(New TLowerString.Create("DEV_AI_GAME_SPEED"), 1000)
		FastForward_SwitchedPlayerToAI = 0
		FastForward_TargetTime = -1
		FastForward_SpeedFactorBackup = 0.0
		FastForward_TimeFactorBackup = 0.0
		FastForward_BuildingTimeSpeedFactorBackup = 0.0
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		If FastForward_Continuous_Active
			buttons[7].text = "Stop AI Game"
		Else
			buttons[7].text = "AI Game"
		EndIf

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next

		UpdateAwardStatus()
	End Method


	Method UpdateAwardStatus()
		If buttonsAwardControls.length >= 6
			If Not GetAwardCollection().GetCurrentAward()
				buttonsAwardControls[0].visible = False
				buttonsAwardControls[1].visible = False
				buttonsAwardControls[2].visible = False
				buttonsAwardControls[3].visible = False
				buttonsAwardControls[4].visible = False
				buttonsAwardControls[5].visible = true
			Else
				buttonsAwardControls[0].visible = True
				buttonsAwardControls[1].visible = True
				buttonsAwardControls[2].visible = True
				buttonsAwardControls[3].visible = True
				buttonsAwardControls[4].visible = True
				buttonsAwardControls[5].visible = False
			EndIf

			If Not GetAwardCollection().GetCurrentAward() And Not GetAwardCollection().GetNextAward()
				buttonsAwardControls[0].visible = False
				buttonsAwardControls[5].visible = False
			EndIf
		EndIf

		For Local b:TDebugControlsButton = EachIn buttonsAwardControls
			b.Update()
		Next
	End Method


	Method Render()
		Local contentRect:SRectI = DrawWindow(position.x, position.y, 195, 200, "Misc", "", 0.0)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
		RenderAwardStatus(position.x + 200, position.y)
	End Method


	Method RenderAwardStatus(x:int, y:int, w:int = 360, h:int = 200)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Award", "", 0.0)
		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y

		Local currentAward:TAward = GetAwardCollection().GetCurrentAward()
		Local nextAward:TAward = GetAwardCollection().GetNextAward()
		Local nextAwardTime:Long = GetAwardCollection().GetNextAwardTime()

		textFont.DrawSimple("Current: ", textX, textY)
		If currentAward 
			textFont.DrawSimple(currentAward.GetTitle(), textX + 40, textY)
			textY :+ 12

			Local rewards:String = currentAward.GetRewardText()
			If rewards.length > 0
				textY :+ textFont.DrawBox(rewards, textX + 40, textY, w - 150 - 40 - 10, 100, sALIGN_LEFT_TOP, SColor8.White, new SVec2F(0,0), EDrawTextOption.IgnoreColor).y
			EndIf
			textFont.DrawSimple("Ends " + GetWorldTime().GetFormattedGameDate(currentAward.GetEndTime()), textX + 40, textY)
			textY :+ 12

			'ranking
			For Local i:Int = 1 To 4
				Local myX:Int = textX + 40
				Local myY:Int = textY
				If i = 2 Or i = 4 Then myX :+ 80
				If i = 3 Or i = 4 Then myY :+ 12
				textFont.DrawSimple("P"+i, myX, myY)
				textFont.DrawBox(currentAward.GetScore(i) +" (", myX, myY, 40, 100, sALIGN_RIGHT_TOP, SColor8.WHITE)
				textFont.DrawBox(int(currentAward.GetScoreShare(i)*100 + 0.5)+"%)", myX + 35, myY, 30, 100, sALIGN_RIGHT_TOP, SColor8.WHITE)
			Next
			textY :+ 2*12
		Else
			textFont.DrawSimple("--", textX + 40, textY)
			textY :+ 12
		EndIf
		textY :+ 3

		Local nextCount:int = 0
		If GetAwardCollection().upcomingAwards.Count() = 0
			textFont.DrawSimple("Next:", textX, textY)
			textFont.DrawSimple("--", textX + 40, textY)
				textY :+ 12
		Else
			For Local nextAward:TAward = EachIn GetAwardCollection().upcomingAwards
				textFont.DrawSimple("Next:", textX, textY)
				If nextAward
					textFont.DrawSimple(nextAward.GetTitle(), textX + 40, textY)
					textY :+ 12

					'only render details for very next
					If nextCount = 0
						Local rewards:String = nextAward.GetRewardText()
						If rewards.length > 0
							textY :+ textFont.DrawBox(rewards, textX + 40, textY, w - 150 - 40 - 10, 100, sALIGN_LEFT_TOP, SColor8.white, New SVec2F(0,0), EDrawTextOption.IgnoreColor).y
						EndIf
					EndIf
					textFont.DrawSimple("Begins " + GetWorldTime().GetFormattedGameDate(nextAward.GetStartTime()), textX + 40, textY)
					textY :+ 12
				Else
					textFont.DrawSimple("--", textX + 40, textY)
					textY :+ 12
				EndIf

				nextCount :+ 1
				'do not show more than 3
				If nextCount > 3 Then Exit
			Next
		EndIf

		textFont.DrawSimple("Add new award: ", buttonsAwardControls[6].x, buttonsAwardControls[6].y - 14)
		For Local b:TDebugControlsButton = EachIn buttonsAwardControls
			b.Render()
		Next
	End Method

	Function SortContractAudienceRange:Int(o1:Object, o2:Object)
		Local a1:TAdContractBase = TAdContractBase(o1)
		Local a2:TAdContractBase = TAdContractBase(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1
		Local a1Audience:Float=a1.minAudienceBase
		Local a2Audience:Float=a2.minAudienceBase

		If a1Audience = a2Audience
			Local aTitle1:String = a1.GetTitle().ToLower()
			Local aTitle2:String = a2.GetTitle().ToLower()
			If aTitle1 > aTitle2
				Return 1
			ElseIf aTitle1 < aTitle2
				Return -1
			Else
				Return a1.profitBase > a2.profitBase
			EndIf
		ElseIf a1Audience > a2Audience
			Return 1
		EndIf
		Return -1
	End Function

	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				Local csv:Int = GameRules.devConfig.GetInt("DEV_ADCONTRACT_STAT_CSV", 0)
				Local adList:TList = CreateList()
				For Local a:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
					adList.AddLast(a)
				Next


				Print "==== AD CONTRACT OVERVIEW ===="
				If csv
					adList.Sort(True, SortContractAudienceRange)
					Print "Name;Audience;%;Image;Base;Profit;per Spot;Penalty;Spots;Days;Available;TargetGroup"
					For Local a:TAdContractBase = EachIn adList
						Local ad:TAdContract = New TAdContract
						'do NOT call ad.Create() as it adds to the adcollection
						ad.base = a
						Local profit:Int = ad.GetProfit()
						Local spots:Int = ad.GetSpotCount()
						print a.GetTitle()+";"+ad.GetMinAudience()+";"+TFunctions.LocalizedNumberToString(100 * a.minAudienceBase,2)+";"+TFunctions.LocalizedNumberToString(ad.GetMinImage()*100, 2)..
						+";"+Int(a.profitBase)+";"+profit+";"+profit/spots+";"+ad.GetPenalty()+";"+spots+";"+ad.GetDaysToFinish()+";"+ad.base.IsAvailable()+";"+ad.GetLimitedToTargetGroupString()
					Next
				else
					adList.Sort(True, TAdContractBase.SortByName)
					Print ".---------------------------------.------------------.---------.----------.----------.-------.------.-------."
					Print "| Name                            | Audience       % |  Image  |  Profit  |  Penalty | Spots | Days | Avail |"
					Print "|---------------------------------+------------------+---------+----------+----------|-------|------|-------|"

					'For Local a:TAdContractBase = EachIn GetAdContractBaseCollection().entries.Values()
					For Local a:TAdContractBase = EachIn adList
						Local ad:TAdContract = New TAdContract
						'do NOT call ad.Create() as it adds to the adcollection
						ad.base = a
						Local title:String = LSet(a.GetTitle(), 30)
						Local audience:String = LSet( RSet(ad.GetMinAudience(), 7), 8)+"  "+RSet( TFunctions.LocalizedNumberToString(100 * a.minAudienceBase,2)+"%", 6)
						Local image:String =  RSet(TFunctions.LocalizedNumberToString(ad.GetMinImage()*100, 2)+"%", 7)
						Local profit:String =  RSet(ad.GetProfit(), 8)
						Local penalty:String =  RSet(ad.GetPenalty(), 8)
						Local spots:String = RSet(ad.GetSpotCount(), 5)
						Local days:String = RSet(ad.GetDaysToFinish(), 4)
						Local availability:String = ""
						Local targetGroup:String = ""
						If ad.GetLimitedToTargetGroup() > 0
							targetGroup = "* "+ getLocale("AD_TARGETGROUP")+": "+ad.GetLimitedToTargetGroupString()
							title :+ "*"
						Else
							title :+ " "
						EndIf
						If ad.base.IsAvailable()
							availability = RSet("Yes", 5)
						Else
							availability = RSet("No", 5)
						EndIf
	
						Print "| "+title + " | " + audience + " | " + image + " | " + profit + " | " + penalty + " | " + spots + " | " + days + " | " + availability + " |" + targetgroup
	
					Next
					Print "'---------------------------------'------------------'---------'----------'----------'-------'------'-------'"
				EndIf
'
			Case 1
				'single overview - only today
				Local text:String[] = GetPlayerFinanceOverviewText(GetPlayer().playerID, GetWorldTime().GetOnDay() -1 )
				For Local s:String = EachIn text
					Print s
				Next

			Case 2
				printLog("TOTAL FINANCE OVERVIEW", GetPlayerFinanceOverviewText, "financeoverview")
			Case 3
				Local text:String[] = GetBroadcastOverviewText(GetPlayer().playerID)
				For Local s:String = EachIn text
					Print s
				Next
			Case 4
				printLog("TOTAL BROADCAST OVERVIEW", GetBroadcastOverviewText, "broadcastoverview")
			Case 5
				Print "====== TOTAL PLAYER PERFORMANCE OVERVIEW ======" + "~n"
				Local result:String = ""
				For Local day:Int = GetWorldTime().GetStartDay() To GetworldTime().GetDay()
					Local text:String[] = GetPlayerPerformanceOverviewText(day)
					For Local s:String = EachIn text
						result :+ s + "~n"
					Next
				Next

				Local logFile:TStream = WriteStream("utf8::" + "logfiles/log.playerperformanceoverview.txt")
				logFile.WriteString(result)
				logFile.close()

				Print result
				Print "==============================================="

			Case 6
				GetPlayer().GetProgrammePlan().printOverview()
			Case 7
				Local instance:TDebugScreenPage_Misc = GetInstance()
				'continuous fast forward: save game at the end of every fifth day
				If instance.FastForward_Continuous_Active
					instance.FastForward_Continuous_Active = False
					instance.FastForward_TargetTime = -1
					GetGame().SetGameSpeedPreset(1)
					GameConfig.autoSaveIntervalHours = instance.FastForward_autoSaveBackup
				Else
					instance.FastForward_autoSaveBackup = GameConfig.autoSaveIntervalHours
					GameConfig.autoSaveIntervalHours = 0
					instance.FastForward_Continuous_Active = True
					instance.FastForward_TargetTime = GetWorldTime().CalcTime_DaysFromNowAtHour(-1,0,0,23,23) + 56*TWorldTime.MINUTELENGTH
					GetGame().SetGameSpeed(instance.FastForwardSpeed)
				EndIf
			Case 8
				GetInstance().Dev_FastForwardToTime(GetWorldTime().GetTimeGone() + 1*TWorldTime.DAYLENGTH, GetInstance().GetShownPlayerID())
		End Select

		'handled
		sender.clicked = False
		sender.selected = False


		Function printLog:Int(heading:String, _function:String[](playerID:Int, day:Int), logFileName:String)
			Local playerIDs:Int[] = [1,2,3,4]
			Local logFiles:TStream[4]
			For Local playerID:Int = EachIn playerIDs
				logFiles[playerID-1] =  WriteStream("utf8::" + "logfiles/log."+logFileName+"_"+playerID+".txt")
			Next
			Local result:String = "====== " + heading + " ======"
			For Local day:Int = GetWorldTime().GetStartDay() To GetworldTime().GetDay()
				result :+ "~n~n"
				For Local playerID:Int = EachIn playerIDs
					For Local s:String = EachIn _function(playerID, day)
						result :+ s+"~n"
						If logFiles[playerID-1] <> Null Then logFiles[playerID-1].WriteString(s+"~n")
					Next
				Next
			Next
			For Local playerID:Int = EachIn playerIDs
				 If logFiles[playerID-1] <> Null Then logFiles[playerID-1].close()
			Next

			Print result
			Print "==============================================="
		EndFunction
	End Function


	Function OnButtonClickHandler_AwardStatusButtons(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				'finish
				GetAwardCollection().FinishCurrentAward()
			Case 1
				'finish P1
				GetAwardCollection().FinishCurrentAward(1)
			Case 2
				'finish P2
				GetAwardCollection().FinishCurrentAward(2)
			Case 3
				'finish P3
				GetAwardCollection().FinishCurrentAward(3)
			Case 4
				'finish P4
				GetAwardCollection().FinishCurrentAward(4)
			Case 5
				'start next (stop current first - if needed)
				If GetAwardCollection().GetCurrentAward()
					GetAwardCollection().FinishCurrentAward()
				EndIf
				GetAwardCollection().SetCurrentAward( GetAwardCollection().PopNextAward() )
			Case 6
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(-1, Null)
			Case 7
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.AUDIENCE, Null)
			Case 8
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.CULTURE, Null)
			Case 9
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.CUSTOMPRODUCTION, Null)
			Case 10
				'generate additional/upcoming (random)
				GetAwardCollection().GenerateUpcomingAward(TVTAwardType.NEWS, Null)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Function GetPlayerFinanceOverviewText:String[](playerID:Int, day:Int)
		If day = -1 Then day = GetWorldTime().GetDay()
		Local latestHour:Int = 23
		Local latestMinute:Int = 59
		If day = GetWorldTime().GetDay()
			latestHour = GetWorldTime().GetDayHour()
			latestMinute = GetWorldTime().GetDayMinute()
		EndIf
		Local now:Long = GetWorldTime().GetTimeGoneForGameTime(0, day, latestHour, latestMinute, 0)
		Local midnight:Long = GetWorldTime().GetTimeGoneForGameTime(0, day+1, 0, 0, 0)
		Local latestTime:String = RSet(latestHour,2).Replace(" ","0") + ":" + RSet(latestMinute,2).Replace(" ", "0")

		'ignore player start day and fetch information about "older incarnations"
		'of that player too (bankruptcies)
		Local finance:TPlayerFinance = GetPlayerFinanceCollection().GetIgnoringStartDay(playerID, day)
		Local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(playerID)

		Local title:String = LSet("Finance Stats for player #" + playerID + " on day " + GetWorldTime().GetDaysRun(midnight) +" ("+GetWorldTime().GetDay(midnight)+")"+ ". Time: 00:00 - " + latestTime, 87)
		Local text:String[]

		text :+ [".----------------------------------------------------------------------------------------."]
		text :+ ["| " + title                                            + "|"]
		If Not finance
			text :+ ["| " + LSet("No Financial overview available for the requested day.", 87) + "|"]
		EndIf

		Local bankruptcyCountAtMidnight:Int = GetPlayer(playerID).GetBankruptcyAmount(midnight)
		'bankruptcy happened today?
		If bankruptcyCountAtMidnight > 0
			Local bankruptcyCountAtDayBegin:Int = GetPlayer(playerID).GetBankruptcyAmount(midnight - TWorldTime.DAYLENGTH)
			'print "player #"+playerID+": bankruptcyCountAtDayBegin=" + bankruptcyCountAtDayBegin+ "  ..AtMidnight=" + bankruptcyCountAtMidnight+"  midnight="+GetWorldTime().GetFormattedGameDate(midnight)

			For Local bankruptcyCount:Int = bankruptcyCountAtDayBegin To bankruptcyCountAtMidnight
				If bankruptcyCount = 0 Then Continue
				Local bankruptcyTime:Long = GetPlayer(playerID).GetBankruptcyTime(bankruptcyCount)

				Rem
				'disabled: use this if restarts of players happen the next day
				Local restartTime:Long = GetWorldTime().ModifyTime(bankruptcyTime, 0, 1, 0, 0, 0)

				'bankruptcy on that day (or more detailed: right on midnight the
				'next day)
				If GetWorldTime().GetDay(bankruptcyTime) = day
					text :+ ["| " + LSet("* Player #"+playerID+" went into bankruptcy that day !", 85) + "|"]
				EndIf
				endrem

				text :+ ["| " + LSet("* Player #"+playerID+" (re)started at "+GetWorldTime().GetFormattedTime(bankruptcyTime) + " that day!", 87) + "|"]
			Next
		EndIf

		If finance And financeTotal
			Local titleLength:Int = 30
			text :+ ["|----------------------------------------------------------.-----------------------------|"]
			text :+ ["| Money:        "+RSet(TFunctions.LocalizedDottedValue(finance.GetMoney()), 15)+"  |                         |             TOTAL           |"]
			text :+ ["|--------------------------------|------------.------------|---------------.-------------|"]
			text :+ ["|                                |   INCOME   |  EXPENSE   |     INCOME    |   EXPENSE   |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_TRADING_PROGRAMMELICENCES")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_programmeLicences), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_programmeLicences), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_programmeLicences), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_programmeLicences), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_AD_INCOME__CONTRACT_PENALTY")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_ads), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_penalty), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_ads), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_penalty), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_CALL_IN_SHOW_INCOME")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_callerRevenue), 10) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_callerRevenue), 13) + " | " + RSet("-", 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_SPONSORSHIP_INCOME__PENALTY")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_sponsorshipRevenue), 10) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_sponsorshipRevenue), 13) + " | " + RSet("-", 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_NEWS")), titleLength) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_news), 10) + " | " + RSet("-", 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_news), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_NEWSAGENCIES")), titleLength) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_newsAgencies), 10)+ " | " + RSet("-", 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_newsAgencies), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_STATIONS")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_stations), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_stations), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_stations), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_stations), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_STATIONS_FEES")), titleLength) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_stationFees), 10) + " | " + RSet("-", 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_stationFees), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_SCRIPTS")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_scripts), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_scripts), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_scripts), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_scripts), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_ACTORS_AND_PRODUCTIONSTUFF")), titleLength) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_productionStuff), 10) + " | " + RSet("-", 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_productionStuff), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_STUDIO_RENT")), titleLength) + " | " + RSet("-", 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_rent), 10) + " | " + RSet("-", 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_rent), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_INTEREST_BALANCE__CREDIT")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_balanceInterest), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_drawingCreditInterest + finance.expense_creditInterest), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_balanceInterest), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_drawingCreditInterest + financeTotal.expense_creditInterest), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_CREDIT_TAKEN__REPAYED")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_creditTaken), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_creditRepayed), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_creditTaken), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_creditRepayed), 11)+ " |"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_MISC")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_misc), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_misc), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_misc), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_misc), 11)+ " |"]
			text :+ ["|--------------------------------|------------|------------|---------------|-------------|"]
			text :+ ["| "+LSet(StringHelper.RemoveUmlauts(GetLocale("FINANCES_TOTAL")), titleLength) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.income_total), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(finance.expense_total), 10) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.income_total), 13) + " | " + RSet(TFunctions.LocalizedDottedValue(financeTotal.expense_total), 11)+ " |"]
			text :+ ["'--------------------------------'------------'------------'---------------'-------------'"]
		Else
			text :+ ["'----------------------------------------------------------------------------------------'"]
		EndIf
		Return text
	End Function


	Function GetBroadcastOverviewText:String[](playerID:Int = -1, day:Int = -1)
		If day = -1 Then day = GetWorldTime().GetDay()
		Local lastHour:Int = GetWorldTime().GetDayHour()
		If day < GetWorldTime().GetDay() Then lastHour = 23
		Local time:Long = GetWorldTime().GetTimeGoneForGameTime(0, day, lastHour, 0, 0)

		Local result:String = ""
		result :+ "==== BROADCAST OVERVIEW ====  "
		result :+ GetWorldTime().GetFormattedDate(time) + "~n"

		Local stat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
		If Not stat
			result :+ "  no dailybroadcaststatistic found." + "~n"
			Return [result]
		EndIf

		Local playerMin:Int = 1
		Local playerMax:Int	= 4
		If playerId > 0
			playerMin = playerID
			playerMax = playerID
		EndIf

		For Local player:Int = playerMin To playerMax
			result :+ ".----------." + "~n"
			result :+ "| PLAYER " + player + " |" + "~n"
			result :+ ".-------.--'------.---------------------------.-----------------.----------------------.---------." + "~n"
			result :+ "| TIME  | NEWS-Q  | PROGRAMME                 | QUOTE / SHARE   | ADVERTISEMENT        | MIN-Q   |" + "~n"
			result :+ "|-------+---------+---------------------------+-----------------+----------------------+---------|" + "~n"
			For Local hour:Int = 0 To lastHour
				Local audience:TAudienceResultBase = stat.GetAudienceResult(player, hour, False)
				Local newsAudience:TAudienceResultBase = stat.GetNewsAudienceResult(player, hour, False)
				Local adAudience:TAudienceResultBase = stat.GetAdAudienceResult(player, hour, False)
	'			Local progSlot:TBroadcastMaterial = GetPlayerProgrammePlan(player).GetProgramme(day, hour)

				'old savegames
				Local adSlotMaterial:TBroadcastMaterial
				If adAudience
					adSlotMaterial = adAudience.broadcastMaterial
				Else
					adSlotMaterial = GetPlayerProgrammePlan(player).GetAdvertisement(day, hour)
				EndIf

				Local progText:String, progAudienceText:String
				Local adText:String, adAudienceText:String
				Local newsAudienceText:String

				If audience And audience.broadcastMaterial
					progText = audience.broadcastMaterial.GetTitle()
					If Not audience.broadcastMaterial.isType(TVTBroadcastMaterialType.PROGRAMME)
						progText = "[I] " + progText
					EndIf

					progAudienceText = RSet(Int(audience.audience.GetTotalSum()), 7) + " " + RSet(TFunctions.LocalizedNumberToString(audience.GetAudienceQuotePercentage()*100,2), 6)+"%"
				Else
					progAudienceText = RSet(" -/- ", 7) + " " +RSet("0%", 7)
					progText = "Outage"
				EndIf
				progText = LSet(StringHelper.RemoveUmlauts(progText), 25)

				If newsAudience
					newsAudienceText = RSet(Int(newsAudience.audience.GetTotalSum()), 7)
				Else
					newsAudienceText = RSet(" -/- ", 7)
				EndIf

				If adSlotMaterial
					adText = LSet(adSlotMaterial.GetTitle(), 20)
					adAudienceText = RSet(" -/- ", 7)

					If adSlotMaterial.isType(TVTBroadcastMaterialType.PROGRAMME)
						adText = LSet("[T] " + StringHelper.RemoveUmlauts(adSlotMaterial.GetTitle()), 20)
					ElseIf adSlotMaterial.isType(TVTBroadcastMaterialType.ADVERTISEMENT)
						adAudienceText = RSet(Int(TAdvertisement(adSlotMaterial).contract.GetMinAudience()),7)
					EndIf
				Else
					adText = LSet("-/-", 20)
					adAudienceText = RSet(" -/- ", 7)
				EndIf

				result :+ "| " + RSet(hour, 2)+":00 | " + newsAudienceText+" | " + progText + " | " + progAudienceText+" | " + adText + " | " + adAudienceText +" |" +"~n"
			Next
			result :+ "'-------'---------'---------------------------'-----------------'----------------------'---------'" + "~n"
		Next
		Return [result]
	End Function


	Function GetPlayerPerformanceOverviewText:String[](day:Int)
		If day = -1 Then day = GetWorldTime().GetDay()
		Local latestHour:Int = 23
		Local latestMinute:Int = 59
		If day = GetWorldTime().GetDay()
			latestHour = GetWorldTime().GetDayHour()
			latestMinute = GetWorldTime().GetDayMinute()
		EndIf
		Local now:Long = GetWorldTime().GetTimeGoneForGameTime(0, day, latestHour, latestMinute, 0)
		Local midnight:Long = GetWorldTime().GetTimeGoneForGameTime(0, day+1, 0, 0, 0)
		Local latestTime:String = RSet(latestHour,2).Replace(" ","0") + ":" + RSet(latestMinute,2).Replace(" ", "0")

		Local text:String[]

		Local title:String = LSet("Performance Stats for day " + (GetWorldTime().GetDaysRun(midnight)+1) + ". Time: 00:00 - " + latestTime, 83)

		text :+ [".-----------------------------------------------------------------------------------."]
		text :+ ["|" + title                                          + "|"]

		For Local playerID:Int = 1 To 4
			Local bankruptcyCount:Int = GetPlayer(playerID).GetBankruptcyAmount(midnight)
			Local bankruptcyTime:Long = GetPlayer(playerID).GetBankruptcyTime(bankruptcyCount)
			'bankruptcy happened today?
			If bankruptcyCount > 0
				Local restartTime:Long = bankruptcyTime 'GetWorldTime().ModifyTime(bankruptcyTime, 0, 1, 0, 0, 0)

				'bankruptcy on that day (or more detailed: right on midnight the
				'next day)
				If GetWorldTime().GetDay(bankruptcyTime) = GetWorldTime().GetDay(midnight)
					text :+ ["| " + LSet("* Player #"+playerID+" went into bankruptcy that day !", 83) + "|"]
				EndIf

				'restarted later on?
				If GetWorldTime().GetDay(restartTime) = GetWorldTime().GetDay(midnight)
					text :+ ["| " + LSet("* Player #"+playerID+" (re)started at "+GetWorldTime().GetFormattedTime(restartTime) +" on day " + (GetWorldTime().getDaysRun(restartTime)+1)+" !", 83) + "|"]
				EndIf
			EndIf
		Next

		text :+ ["|---------------------------------------.----------.----------.----------.----------|"]
		text :+ ["| TITLE                                 |       P1 |       P2 |       P3 |       P4 |"]
		text :+ ["|---------------------------------------|----------|----------|----------|----------|"]

		Local keys:String[]
		Local values1:String[]
		Local values2:String[]
		Local values3:String[]
		Local values4:String[]

		Local adAudienceProgrammeAudienceRate:Float[4]
		Local failedAdSpots:Int[4]
		Local spotPenalty:String[4]
		Local sentTrailers:Int[4]
		Local sentInfomercials:Int[4]
		Local sentAdvertisements:Int[4]

		Local broadcastStat:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day)
		If broadcastStat
			Local audienceSum:Long[4]
			Local adAudienceSum:Long[4]

			For Local player:Int = 1 To 4
				For Local hour:Int = 0 To latestHour
					Local audience:TAudienceResultBase = broadcastStat.GetAudienceResult(player, hour, False)
					Local adAudience:TAudienceResultBase = broadcastStat.GetAdAudienceResult(player, hour, False)

					Local advertisement:TAdvertisement
					Local adAudienceValue:Int, audienceValue:Int

					' AD
					If adAudience
						If TAdvertisement(adAudience.broadcastMaterial)
							advertisement = TAdvertisement(adAudience.broadcastMaterial)
							adAudienceValue = Int(advertisement.contract.GetMinAudience())
						Else
							sentTrailers[player-1] :+ 1
						EndIf
					EndIf

					' PROGRAMME
					If audience And audience.broadcastMaterial
						audienceValue = Int(audience.audience.GetTotalSum())
						If TAdvertisement(audience.broadcastMaterial)
							sentInfomercials[player-1] :+ 1
						EndIf
					EndIf

					If advertisement
						If advertisement.isState(TAdvertisement.STATE_OK)
							adAudienceSum[player-1] :+ adAudienceValue
							audienceSum[player-1] :+ audienceValue
						ElseIf advertisement.isState(TAdvertisement.STATE_FAILED)
							failedAdSpots[player-1] :+ 1
						EndIf
					EndIf
				Next
				adAudienceProgrammeAudienceRate[player-1] = 0
				If adAudienceSum[player-1] > 0
					adAudienceProgrammeAudienceRate[player-1] = Float(adAudienceSum[player-1]) / audienceSum[player-1]
				EndIf

				Local finance:TPlayerFinance = TPlayerFinanceCollection.getInstance().Get(player, day)
				Local penalty:Long = finance.expense_penalty
				If penalty > 0
					spotPenalty[player-1] = ""+penalty / 1000 +"K; "
				Else
					spotPenalty[player-1] =""
				EndIf
			Next
		EndIf

		keys :+ [ "AdMinAudience/ProgrammeAudience-Rate" ]
		values1 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[0]*100,2)+"%" ]
		values2 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[1]*100,2)+"%" ]
		values3 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[2]*100,2)+"%" ]
		values4 :+ [ MathHelper.NumberToString(adAudienceProgrammeAudienceRate[3]*100,2)+"%" ]

		keys :+ [ "Penalty; Failed Adspots" ]
		values1 :+ [ spotPenalty[0]+String(failedAdSpots[0]) ]
		values2 :+ [ spotPenalty[1]+String(failedAdSpots[1]) ]
		values3 :+ [ spotPenalty[2]+String(failedAdSpots[2]) ]
		values4 :+ [ spotPenalty[3]+String(failedAdSpots[3]) ]
		keys :+ [ "Sent [T]railers and [I]nfomercials" ]
		values1 :+ [ "T:"+sentTrailers[0] + " I:"+sentInfomercials[0] ]
		values2 :+ [ "T:"+sentTrailers[1] + " I:"+sentInfomercials[1] ]
		values3 :+ [ "T:"+sentTrailers[2] + " I:"+sentInfomercials[2] ]
		values4 :+ [ "T:"+sentTrailers[3] + " I:"+sentInfomercials[3] ]

		'TFunctions.LocalizedDottedValue(financeTotal.expense_programmeLicences)
		For Local i:Int = 0 Until keys.length
			Local line:String = "| "+LSet(StringHelper.RemoveUmlauts(keys[i]), 38) + "|"

			line :+ RSet( values1[i] + " |", 11)
			line :+ RSet( values2[i] + " |", 11)
			line :+ RSet( values3[i] + " |", 11)
			line :+ RSet( values4[i] + " |", 11)

			text :+ [line]
		Next

		text :+ ["'---------------------------------------'----------'----------'----------'----------'"]

		Return text
	End Function


	Method Dev_FastForwardToTime(time:Long, switchPlayerToAI:Int=0)
		'just update time? / avoid backupping the modified speeds
		If FastForward_Active
			FastForward_TargetTime = time
		Else
			FastForward_Active = True
			
			FastForward_TargetTime = time

			If switchPlayerToAI > 0 And GetPlayer(switchPlayerToAI).IsLocalHuman()
				FastForward_SwitchedPlayerToAI = switchPlayerToAI
				Dev_SetPlayerAI(switchPlayerToAI, True)
			EndIf

			FastForward_SpeedFactorBackup = TEntity.globalWorldSpeedFactor
			FastForward_TimeFactorBackup = GetWorldTime()._timeFactor
			FastForward_BuildingTimeSpeedFactorBackup = GetBuildingTime()._timeFactor

			GetGame().SetGameSpeed( 90 * 60 )
		EndIf
	End Method


	Method Dev_StopFastForwardToTime()
		If FastForward_Active
			FastForward_Active = False

			If FastForward_SwitchedPlayerToAI > 0
				Dev_SetPlayerAI(FastForward_SwitchedPlayerToAI, False)
				FastForward_SwitchedPlayerToAI = 0
			EndIf

			TEntity.globalWorldSpeedFactor = FastForward_SpeedFactorBackup
			GetWorldTime().SetTimeFactor(FastForward_TimeFactorBackup)
			GetBuildingTime().SetTimeFactor(FastForward_BuildingTimeSpeedFactorBackup)
		EndIf
	End Method


	Function Dev_SetPlayerAI:Int(playerID:Int, bool:int)
		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return False

		If bool
			If Not player.IsLocalAI()
				player.SetLocalAIControlled()
				'reload ai - to avoid using "outdated" information
				player.InitAI( New TAI.Create(player.playerID, GetGame().GetPlayerAIFileURI(player.playerID)) )
				player.playerAI.CallOnInit()
				'player.PlayerAI.CallLuaFunction("OnForceNextTask", null)
				GetGame().SendSystemMessage("[DEV] Enabled AI for player "+player.playerID)
			Else
				GetGame().SendSystemMessage("[DEV] Already enabled AI for player "+player.playerID)
			EndIf
		Else
			If player.IsLocalAI()
				'calling "SetLocalHumanControlled()" deletes AI too
				player.SetLocalHumanControlled()
				GetGame().SendSystemMessage("[DEV] Disabled AI for player "+player.playerID)
			Else
				GetGame().SendSystemMessage("[DEV] Already disabled AI for player "+player.playerID)
			EndIf
		EndIf
	End Function
End Type
