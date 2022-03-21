SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.player.bmx"


Global debugWidget_ProgrammeCollectionInfo:TDebugWidget_ProgrammeCollectionInfo = new TDebugWidget_ProgrammeCollectionInfo



Type TDebugScreenPage_PlayerBroadcasts extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field widget_playerProgrammePlanInfo:TDebugWidget_ProgrammePlanInfo
	
	Global _instance:TDebugScreenPage_PlayerBroadcasts
	
	
	Method New()
		_instance = self
	End Method
	
	
	Function GetInstance:TDebugScreenPage_PlayerBroadcasts()
		if not _instance then new TDebugScreenPage_PlayerBroadcasts
		return _instance
	End Function 
	

	Method Init:TDebugScreenPage_PlayerBroadcasts()
		Local texts:String[] = ["< Day", "Today", "Day >"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler
			button.x = 15 + 110*i
			button.y = 345
			button.w = 100

			buttons :+ [button]
		Next
		
		widget_playerProgrammePlanInfo = new TDebugWidget_ProgrammePlanInfo
		
		Return self
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local dayShown:Int = GetInstance().widget_playerProgrammePlanInfo.dayShown
		Select sender.dataInt
			case 0
				dayShown:-1
			case 1
				dayShown = GetWorldTime().GetDay()
			case 2
				dayShown:+1
		End Select
		
		GetInstance().widget_playerProgrammePlanInfo.SetDayShown(dayShown)

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
	
	
	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method
	
	
	Method Reset()
	End Method
	
	
	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		widget_playerProgrammePlanInfo.Update(playerID, position.x + 5, position.y + 13)
		debugWidget_ProgrammeCollectionInfo.Update(playerID, position.x + 5 + 350, position.y + 13)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		widget_playerProgrammePlanInfo.Render(playerID, position.x + 5, position.y + 3)
		debugWidget_ProgrammeCollectionInfo.Render(playerID, position.x + 350, position.y + 3)
		If widget_playerProgrammePlanInfo.programmeForHover
			widget_playerProgrammePlanInfo.programmeForHover.ShowSheet(position.x + 400, position.y + 3)
		ElseIf debugWidget_ProgrammeCollectionInfo.programmeForHover
			debugWidget_ProgrammeCollectionInfo.programmeForHover.ShowSheet(position.x + 5, position.y + 3, 0, 0, playerID)
		ElseIf debugWidget_ProgrammeCollectionInfo.contractForHover
			debugWidget_ProgrammeCollectionInfo.contractForHover.ShowSheet( position.x + 170, position.y + 3, 0, 0, playerID)
		EndIf

	End Method
End Type



Type TDebugWidget_ProgrammePlanInfo
	Field programmeBroadcasts:TIntMap = new TIntMap
	Field adBroadcasts:TIntMap = new TIntMap
	Field newsInShow:TIntMap = new TIntMap
	Field oldestEntryTime:Long
	Field predictor:TBroadcastAudiencePrediction = New TBroadcastAudiencePrediction
	Field predictionCacheProgAudience:TAudience[24]
	Field predictionCacheProg:TAudienceAttraction[24]
	Field predictionCacheNews:TAudienceAttraction[24]
	Field predictionRefreshMarketsNeeded:int = True
	Field currentPlayer:Int = 0
	Field adSlotWidth:Int = 120
	Field programmeSlotWidth:Int = 200
	Field clockSlotWidth:Int = 15
	Field slotPadding:Int = 3
	Field dayShown:Int = -1
	Field showCurrent:Int = 1
	Field haveToRemoveOutdated:Int = 0
	Field haveToRemoveOutdatedCount:Int = 0
	Field _eventListeners:TEventListenerBase[]
	Field programmeForHover:TBroadcastMaterial = null


	Method New()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.ProgrammePlan_AddObject, self, "onChangeProgrammePlan") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.ProgrammePlan_SetNews, self, "onChangeNewsShow") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.StationMap_OnRecalculateAudienceSum, self, "onChangeAudienceSum") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.Game_OnStart, self, "onStartGame") ]
	End Method


	Method onStartGame:Int(triggerEvent:TEventBase)
		predictionRefreshMarketsNeeded = True
	End Method


	Method onChangeAudienceSum:Int(triggerEvent:TEventBase)
		Local reachBefore:Int = triggerEvent.GetData().GetInt("reachBefore")
		Local reach:Int = triggerEvent.GetData().GetInt("reach")
		Local playerID:Int = triggerEvent.GetData().GetInt("playerID")
		if playerID = currentPlayer and reach <> reachBefore
			predictionRefreshMarketsNeeded = True
		EndIf
	End Method


	Method onChangeNewsShow:Int(triggerEvent:TEventBase)
		Local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("news"))
		Local slot:Int = triggerEvent.GetData().GetInt("slot", -1)
		If Not broadcast Or slot < 0 Then Return False

		newsInShow.Insert(broadcast.GetID(), String(Time.GetTimeGone()) )

		haveToRemoveOutdated = True
		haveToRemoveOutdatedCount :+ 1
	End Method


	Method onChangeProgrammePlan:Int(triggerEvent:TEventBase)
		Local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("object"))
		Local slotType:Int = triggerEvent.GetData().GetInt("slotType", -1)
		If Not broadcast Or slotType <= 0 Then Return False

		If slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			adBroadcasts.Insert(broadcast.GetID(), String(Time.GetTimeGone()) )
		Else
			programmeBroadcasts.Insert(broadcast.GetID(), String(Time.GetTimeGone()) )
		EndIf

		haveToRemoveOutdated = True
		haveToRemoveOutdatedCount :+ 1
	End Method


	Method RemoveOutdated()
		Local maps:TIntMap[] = [programmeBroadcasts, adBroadcasts, newsInShow]

		oldestEntryTime = -1

		'remove outdated ones (older than 30 seconds))
		For Local map:TIntMap = EachIn maps
			Local remove:Int[]
			For Local idKey:TIntKey = EachIn map.Keys()
				Local broadcastTime:Long = Long( String(map.ValueForKey(idKey.value)) )
				'old or not happened yet ?
				If broadcastTime + 8000 < Time.GetTimeGone() ' or broadcastTime > Time.GetTimeGone()
					remove :+ [idKey.value]
					Continue
				EndIf

				If oldestEntryTime = -1 Then oldestEntryTime = broadcastTime
				oldestEntryTime = Min(oldestEntryTime, broadcastTime)
			Next

			For Local id:Int = EachIn remove
				map.Remove(id)
			Next
		Next

		'reset cache
		ResetPredictionCache( GetWorldTime().GetDayHour()+1 )
	End Method


	Method ResetPredictionCache(minHour:Int = 0)
		If minHour = 0
			predictionCacheProgAudience = New TAudience[24]
			predictionCacheProg = New TAudienceAttraction[24]
			predictionCacheNews = New TAudienceAttraction[24]
		Else
			For Local hour:Int = minHour To 23
				predictionCacheProgAudience[hour] = Null
				predictionCacheProg[hour] = Null
				predictionCacheNews[hour] = Null
			Next
		EndIf
	End Method


	Method GetAddedTime:Long(id:Int, slotType:Int=0)
		Select slotType
			Case TVTBroadcastMaterialType.PROGRAMME
				Return Long( String(programmeBroadcasts.ValueForKey(id)) )
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				Return Long( String(adBroadcasts.ValueForKey(id)) )
			Case TVTBroadcastMaterialType.NEWS
				Return Long( String(newsInShow.ValueForKey(id)) )
		End Select
		Return 0
	End Method


	Method Update(playerID:Int, x:Int, y:Int)
		If showCurrent > 0 Then dayShown = GetWorldTime().GetDay()
	End Method


	Method Render(playerID:Int, x:Int, y:Int)
		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Local currentDay:Int = GetWorldTime().GetDay()
		Local currHour:Int = GetWorldTime().GetDayHour()
		Local daysProgramme:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetProgrammeSlotsInTimeSpan(dayShown, 0, dayShown, 23)
		Local daysAdvertisements:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetAdvertisementSlotsInTimeSpan(dayShown, 0, dayShown, 23)
		Local lineHeight:Int = 12
		Local lineTextHeight:Int = 15
		Local lineTextDY:Int = -1
		Local programmeSlotX:Int = x + clockSlotWidth + slotPadding
		Local adSlotX:Int = programmeSlotX + programmeSlotWidth + slotPadding
		programmeForHover = null

		Local font:TBitmapFont = GetBitmapFont("default", 10)

		'statistic for the shown day
		Local dailyBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(dayShown, True)

		'clean up if needed
		If haveToRemoveOutdated Or (oldestEntryTime >= 0 And oldestEntryTime + 10000 < Time.GetTimeGone())
			haveToRemoveOutdated = False
			RemoveOutdated()
		EndIf

		If currentPlayer <> playerID
			currentPlayer = playerID
			ResetPredictionCache(0) 'predict all again
			
			predictionRefreshMarketsNeeded = True
		EndIf

		'refresh markets? maybe stations were built / audience reach
		'changed
		If predictionRefreshMarketsNeeded
			predictor.RefreshMarkets()
			predictionRefreshMarketsNeeded = False
		EndIf


		Local s:String = "|color=200,255,200|PRED|/color|/|color=200,200,255|GUESS|/color|/|color=255,220,210|REAL|/color|"
		GetBitmapFont("default", 10).DrawBox( s, programmeSlotX, y + -1*lineHeight + lineTextDY, programmeSlotWidth, lineTextHeight, sALIGN_RIGHT_TOP, SColor8.White)


		For Local hour:Int = 0 Until daysProgramme.length
			Local audienceResult:TAudienceResultBase
			If dayShown < currentDay or dayShown = currentDay and hour <= currHour
'			If hour <= currHour
				audienceResult = dailyBroadcastStatistic.GetAudienceResult(playerID, hour)
			EndIf

			Local adString:String = ""
			Local progString:String = ""
			Local adString2:String = ""
			Local progString2:String = ""

			'use "0" as day param because currentHour includes days already
			Local advertisement:TBroadcastMaterial = daysAdvertisements[hour]
			If advertisement
				Local spotNumber:String
				Local specialMarker:String = ""
				Local ad:TAdvertisement = TAdvertisement(advertisement)
				If ad
					If ad.IsState(TAdvertisement.STATE_FAILED)
						spotNumber = "-/" + ad.contract.GetSpotCount()
					Else
						spotNumber = GetPlayerProgrammePlan(advertisement.owner).GetAdvertisementSpotNumber(ad) + "/" + ad.contract.GetSpotCount()
					EndIf

					If ad.contract.GetLimitedToTargetGroup()>0 Or ad.contract.GetLimitedToProgrammeGenre()>0 Or ad.contract.GetLimitedToProgrammeFlag()>0
						specialMarker = "**"
					EndIf
				Else
					spotNumber = (hour - advertisement.programmedHour + 1) + "/" + advertisement.GetBlocks(TVTBroadcastMaterialType.ADVERTISEMENT)
				EndIf
				adString = advertisement.GetTitle()
				If ad Then adString = Int(ad.contract.GetMinAudience()/1000) +"k " + adString
				adString2 = specialMarker + "[" + spotNumber + "]"

				If TProgramme(advertisement) Then adString = "T: "+adString
			EndIf

			Local programme:TBroadcastMaterial = daysProgramme[hour]
			If programme
				progString = programme.GetTitle()
				If THelper.MouseIn(x, y + hour * lineHeight, programmeSlotWidth, lineheight)
					programmeForHover = programme
				EndIf
				If TAdvertisement(programme) Then progString = "I: "+progString

				progString2 = ((hour - programme.programmedHour + 25) Mod 24) + "/" + programme.GetBlocks(TVTBroadcastMaterialType.PROGRAMME)
'				if currHour < hour
					'uncached
					If Not predictionCacheProgAudience[hour]
						For Local i:Int = 1 To 4
							Local prog:TBroadcastMaterial = GetPlayerProgrammePlan(i).GetProgramme(dayShown, hour)
							If prog
								Local progBlock:Int = GetPlayerProgrammePlan(i).GetProgrammeBlock(dayShown, hour)
								Local prevProg:TBroadcastMaterial = GetPlayerProgrammePlan(i).GetProgramme(dayShown, hour-1)
								Local newsAttr:TAudienceAttraction = Null
								Local prevAttr:TAudienceAttraction = Null
								If prevProg And dayShown
									Local prevProgBlock:Int = GetPlayerProgrammePlan(i).GetProgrammeBlock(dayShown, (hour-1 + 24) Mod 24)
									If prevProgBlock > 0
										prevAttr = prevProg.GetAudienceAttraction((hour-1 + 24) Mod 24, prevProgBlock, Null, Null, True, True)
									EndIf
								EndIf
								Local newsAge:Int = 0
								Local newsshow:TBroadcastMaterial
								For Local hoursAgo:Int = 0 To 6
									newsshow = GetPlayerProgrammePlan(i).GetNewsShow(dayShown, hour - hoursAgo)
									If newsshow Then Exit
									newsAge = hoursAgo
								Next
								If newsshow
									newsAttr = newsshow.GetAudienceAttraction(hour, 1, prevAttr, Null, True, True)
'									newsAttr.MultiplyFloat()
								EndIf
								Local attr:TAudienceAttraction = prog.GetAudienceAttraction(hour, progBlock, prevAttr, newsAttr, True, True)
								predictor.SetAttraction(i, attr)
							Else
								predictor.SetAverageValueAttraction(i, 0)
							EndIf
						Next
						predictor.RunPrediction(dayShown, hour)
						predictionCacheProgAudience[hour] = predictor.GetAudience(playerID)
					EndIf
				'show predictions only for the current day
				if dayShown = currentDay
					progString2 :+ " |color=200,255,200|"+Int(predictionCacheProgAudience[hour].GetTotalSum()/1000)+"k|/color|"
				else
					progString2 :+ " |color=200,200,255|??|/color|"
				endif

				Local player:TPlayer = GetPlayer(playerID)
				Local guessedAudience:TAudience
				If player Then guessedAudience = TAudience(player.aiData.Get("guessedaudience_"+dayShown+"_"+hour, Null))
				If guessedAudience
					progString2 :+ " / |color=200,200,255|"+Int(guessedAudience.GetTotalSum()/1000)+"k|/color|"
				Else
					progString2 :+ " / |color=200,200,255|??|/color|"
				EndIf

				If audienceResult
					progString2 :+ " / |color=255,220,210|"+Int(audienceResult.audience.GetTotalSum()/1000) +"k|/color|"
				Else
					progString2 :+ " / |color=255,220,210|??|/color|"
				EndIf
			EndIf

			If progString = "" And GetWorldTime().GetDayHour() > hour And dayShown <= currentDay Then progString = "PROGRAMME OUTAGE"
			If adString = "" And GetWorldTime().GetDayHour() > hour And dayShown <= currentDay Then adString = "AD OUTAGE"

			Local oldAlpha:Float = GetAlpha()
			If hour Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 50,50,50
			EndIf
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, y + hour * lineHeight, clockSlotWidth, lineHeight-1)
			DrawRect(programmeSlotX, y + hour * lineHeight, programmeSlotWidth, lineHeight-1)
			DrawRect(adSlotX, y + hour * lineHeight, adSlotWidth, lineHeight-1)


			Local progTime:Long = 0, adTime:Long = 0
			If advertisement Then adTime = GetAddedTime(advertisement.GetID(), TVTBroadcastMaterialType.ADVERTISEMENT)
			If programme Then progTime = GetAddedTime(programme.GetID(), TVTBroadcastMaterialType.PROGRAMME)

			SetColor 255,235,20
			If progTime <> 0
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - progTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(programmeSlotX, y + hour * lineHeight, programmeSlotWidth, lineHeight-1)
				SetBlend ALPHABLEND
			EndIf
			If adTime <> 0
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - adTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(adSlotX, y + hour * lineHeight, adSlotWidth, lineHeight-1)
				SetBlend ALPHABLEND
			EndIf

			'indicate reached / required audience
			'indicator for previous days (not essential) causes segmentation fault
			If dayShown = currentDay and hour < currHour And TAdvertisement(advertisement) And audienceResult
				Local reachedAudience:Int = audienceResult.audience.GetTotalValue(TAdvertisement(advertisement).contract.GetLimitedToTargetGroup())
				Local adMinAudience:Int = TAdvertisement(advertisement).contract.GetMinAudience()
				local passingRequirements:String = TAdvertisement(advertisement).isPassingRequirements(TAudienceResult(audienceResult))
				local ratio:Float = Float(adMinAudience) / reachedAudience
				if adMinAudience > reachedAudience then ratio = reachedAudience / Float(adMinAudience)
				Select passingRequirements
					case "OK"
						SetColor 160,160,255
					default
						SetColor 255,160,160
				End Select
				SetAlpha 0.75 * oldAlpha
				DrawRect(adSlotX, y + hour * lineHeight + lineHeight - 4, adSlotWidth * Min(1.0,  ratio), 2)
			EndIf

			SetColor 255,255,255
			SetAlpha oldAlpha

			font.Draw( RSet(hour,2).Replace(" ", "0"), x + 2, y + hour*lineHeight + lineTextDY)
			Local fontColor:SColor8
			If programme Then SetStateColor(programme)
			GetColor(fontColor)
			font.DrawBox( progString, programmeSlotX + 2, y + hour*lineHeight + lineTextDY, programmeSlotWidth - 70, lineTextHeight, sALIGN_LEFT_TOP, fontColor)
			font.DrawBox( progString2, programmeSlotX, y + hour*lineHeight + lineTextDY, programmeSlotWidth - 2, lineTextHeight, sALIGN_RIGHT_TOP, fontColor)
			If advertisement Then SetStateColor(advertisement, True)
			GetColor(fontColor)
			font.DrawBox( adString, adSlotX + 2, y + hour*lineHeight + lineTextDY, adSlotWidth - 30, lineTextHeight, sALIGN_LEFT_TOP, fontColor)
			font.DrawBox( adString2, adSlotX, y + hour*lineHeight + lineTextDY, adSlotWidth - 2, lineTextHeight, sALIGN_RIGHT_TOP, fontColor)
			SetColor 255,255,255
		Next

		'a bit space between programme plan and news show plan
		Local newsY:Int = y + daysProgramme.length * lineHeight + lineHeight
		If dayShown = currentDay
			For Local newsSlot:Int = 0 To 2
				Local news:TBroadcastMaterial = GetPlayerProgrammePlan( playerID ).GetNewsAtIndex(newsSlot)
				Local oldAlpha:Float = GetAlpha()
				If newsSlot Mod 2 = 0
					SetColor 0,0,40
				Else
					SetColor 50,50,90
				EndIf
				SetAlpha 0.85 * oldAlpha
				DrawRect(x, newsY + newsSlot * lineHeight, clockSlotWidth, lineHeight-1)
				DrawRect(programmeSlotX, newsY + newsSlot * lineHeight, programmeSlotWidth, lineHeight-1)
	
	
				If TNews(news)
					Local newsTime:Long = GetAddedTime(news.GetID(), TVTBroadcastMaterialType.NEWS)
					If newsTime <> 0
						Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - newsTime) / 5000.0))
						SetColor 255,255,255
						SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
						SetBlend LIGHTBLEND
						DrawRect(programmeSlotX, newsY + newsSlot * lineHeight, programmeSlotWidth, lineHeight-1)
						SetBlend ALPHABLEND
					EndIf
	
					SetColor 220,110,110
					SetAlpha 0.50 * oldAlpha
					DrawRect(programmeSlotX, newsY + newsSlot * lineHeight + lineHeight-3, programmeSlotWidth * TNews(news).GetNewsEvent().GetTopicality(), 2)
				EndIf
	
				SetColor 255,255,255
				SetAlpha oldAlpha
	
				font.DrawBox( newsSlot+1 , x + 2, newsY + newsSlot * lineHeight + lineTextDY, clockSlotWidth-2, lineTextHeight, sALIGN_CENTER_TOP, SColor8.White)
				If news
					font.DrawBox(news.GetTitle(), programmeSlotX + 2, newsY + newsSlot*lineHeight + lineTextDY, programmeSlotWidth - 4, lineTextHeight, sALIGN_LEFT_TOP, SColor8.White)
				Else
					font.DrawBox("NEWS OUTAGE", programmeSlotX + 2, newsY + newsSlot*lineHeight + lineTextDY, programmeSlotWidth - 4, lineTextHeight, sALIGN_LEFT_TOP, SColor8.Red)
				EndIf
			Next
		Else
			SetColor 0,0,40
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.85 * oldAlpha
			DrawRect(programmeSlotX, newsY , programmeSlotWidth, lineHeight-1)
			SetAlpha oldAlpha
			Local text:String = "Showing programme of day "
			text:+ (dayShown - GetWorldTime().GetStartDay() + 1)+ "  ("
			Local diff:Int = dayShown-currentDay
			Local suffix:String = " days)"
			If Abs(diff) = 1 Then suffix = " day)"
			If diff > 0 Then text:+ "+"
			text:+ diff + suffix
			font.DrawBox(text, programmeSlotX + 2, newsY + lineTextDY, programmeSlotWidth - 4, lineTextHeight, sALIGN_LEFT_TOP, SColor8.White)
			SetColor 255,255,255
		EndIf
	End Method


	Method SetStateColor(material:TBroadcastMaterial, adSlot:Int=False)
		If Not material
			SetColor 255,255,255
			Return
		ElseIf adSlot And TProgramme(material) And material.state <> TBroadcastMaterial.STATE_RUNNING
			'make trailer easily recognizable
			SetColor 255,255,255
			Return
		EndIf

		Select material.state
			Case TBroadcastMaterial.STATE_RUNNING
				SetColor 255,230,120
			Case TBroadcastMaterial.STATE_OK
				SetColor 200,255,200
			Case TBroadcastMaterial.STATE_FAILED
				SetColor 250,150,120
			Default
				SetColor 255,255,255
		End Select
	End Method
	
	
	Method SetDayShown(newDayShown:Int)
		dayShown = newDayShown
		showCurrent = (dayShown = GetWorldTime().GetDay())
		Local today:Int = GetWorldTime().GetDay()
		If showCurrent > 0 and today <> dayShown Then dayShown = today
		dayShown = Max(dayShown, GetWorldTime().GetStartDay())
	End Method
End Type




Type TDebugWidget_ProgrammeCollectionInfo
	Global initialized:Int
	Global addedProgrammeLicences:TIntMap = new TIntMap
	Global removedProgrammeLicences:TIntMap = new TIntMap
	Global availableProgrammeLicences:TIntMap = new TIntMap
	'Global suitcaseProgrammeLicences:TIntMap = new TIntMap
	Global addedAdContracts:TIntMap = new TIntMap
	Global removedAdContracts:TIntMap = new TIntMap
	Global availableAdContracts:TIntMap = new TIntMap
	Global scheduledRemoveOutdatedTimes:Long[]
	Global haveToRemoveOutdated:Int
	Global _eventListeners:TEventListenerBase[]
	Global programmeForHover:TProgrammeLicence = null
	Global contractForHover:TAdContract = null

	Method New()
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveAdContract, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddAdContract, onChangeProgrammeCollection) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddUnsignedAdContractToSuitcase, onChangeProgrammeCollection) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveUnsignedAdContractFromSuitcase, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicence, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, onGameStart) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_PreparePlayer, onPreparePlayer) ]
	End Method
	

	Function onGameStart:Int(triggerEvent:TEventBase)
		debugWidget_ProgrammeCollectionInfo.Initialize()
		
		scheduledRemoveOutdatedTimes = New Long[0]
		haveToRemoveOutdated = True
	End Function

	'called if a player restarts
	Function onPreparePlayer:Int(triggerEvent:TEventBase)
		debugWidget_ProgrammeCollectionInfo.Initialize()
	End Function


	Function onChangeProgrammeCollection:Int(triggerEvent:TEventBase)
		Local prog:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("programmelicence"))
		Local contract:TAdContract = TAdContract(triggerEvent.GetData().Get("adcontract"))
		Local broadcastSource:TBroadcastMaterialSource = prog
		If Not broadcastSource Then broadcastSource = contract

		If Not broadcastSource Then Print "TDebugProgrammeCollectionInfo.onChangeProgrammeCollection: invalid broadcastSourceMaterial."


		Local map:TIntMap = Null
		Select triggerEvent.GetEventKey()
			Case GameEventKeys.ProgrammeCollection_RemoveAdContract
				map = removedAdContracts
				'schedule a cleanup
				AddToRemoveOutdatedSchedule(Time.GetTimeGone() + 3000)
				'directly remove on outdated? 
				'-> would instantly remove it - without animation
				'availableAdContracts.Remove(broadcastSource.GetID())
			Case GameEventKeys.ProgrammeCollection_AddAdContract
				map = addedAdContracts
				'schedule a cleanup
				AddToRemoveOutdatedSchedule(Time.GetTimeGone() + 3000)
				availableAdContracts.Insert(broadcastSource.GetID(), broadcastSource)
	'		Case GameEventKeys.ProgrammeCollection_AddUnsignedAdContractToSuitcase
	'			map = addedAdContracts
	'		Case GameEventKeys.ProgrammeCollection_RemoveUnsignedAdContractFromSuitcase
	'			map = addedAdContracts
	'		Case GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase
	'			map = suitcaseProgrammeLicences
	'		Case GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase
	'			map = suitcaseProgrammeLicences
			Case GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence
				map = removedProgrammeLicences
				'schedule a cleanup
				AddToRemoveOutdatedSchedule(Time.GetTimeGone() + 3000)
				'remove on outdated
				'availableProgrammeLicences.Remove(broadcastSource.GetID())
			Case GameEventKeys.ProgrammeCollection_AddProgrammeLicence
				map = addedProgrammeLicences
				availableProgrammeLicences.Insert(broadcastSource.GetID(), broadcastSource)
				'schedule a cleanup
				AddToRemoveOutdatedSchedule(Time.GetTimeGone() + 3000)
		End Select
		If Not map Then Return False

		map.Insert(broadcastSource.GetID(), String(Time.GetTimeGone()) )

		haveToRemoveOutdated = True
	End Function
	
	
	Function AddToRemoveOutdatedSchedule(scheduledTime:Long)
		'cleanup to avoid excessive array usage (with nobody watching
		'the debug screen)
		If scheduledRemoveOutdatedTimes.length > 10
			RemoveOutdatedScheduleTimes()
		EndIf
	
		'round time so "almost equally timed" entries are removed at the
		'same time, not eg 1-2 ms later ?
		'we want this entry to be removed (rounded to 10ms steps) in about 3 seconds
		Local t:Long = long(scheduledTime/10)*10
		'check if already scheduled and calculate index
		Local index:Int
		If scheduledRemoveOutdatedTimes.length > 0
			For Local i:Int = 0 Until scheduledRemoveOutdatedTimes.length
				Local existingTime:Long = scheduledRemoveOutdatedTimes[index]
				If existingTime = t
					'already added
					Return
				ElseIf existingTime > t
					index = i
				Else
					index = i + 1
				EndIf
			Next
		EndIf
		If index >= scheduledRemoveOutdatedTimes.length
			scheduledRemoveOutdatedTimes :+ [t]
		Else
			scheduledRemoveOutdatedTimes :+ scheduledRemoveOutdatedTimes[.. index] + [t] + scheduledRemoveOutdatedTimes[index ..]
		EndIf

		'PrintOutdatedScheduleTimes()
	End Function


	Function RemoveOutdatedScheduleTimes()
		If scheduledRemoveOutdatedTimes.length > 0
			Local removeTillIndex:Int = -1
			Local t:Long = Time.GetTimeGone()
			For Local i:int = 0 until scheduledRemoveOutdatedTimes.length
				If t >= scheduledRemoveOutdatedTimes[i]
					removeTillIndex = i
				Else
					'skip further checks - the array is sorted
					Exit
				EndIf
			Next
			If removeTillIndex >= 0
				scheduledRemoveOutdatedTimes = scheduledRemoveOutdatedTimes[removeTillIndex + 1..]
				
				'PrintOutdatedScheduleTimes()
			EndIf
		EndIf
	End Function
	
'dev
rem
	Function PrintOutdatedScheduleTimes()
		print "OutdatedScheduleTimes:"
		for local i:int = 0 until scheduledRemoveOutdatedTimes.length
			print scheduledRemoveOutdatedTimes[i]
		Next
		print "----"
	End Function
endrem
	
	Function RemoveOutdated()
		Local maps:TIntMap[] = [removedProgrammeLicences, removedAdContracts, addedProgrammeLicences, addedAdContracts]

		'pop off all "too old"
		RemoveOutdatedScheduleTimes()

		'remove outdated ones (older than 30 seconds))
		For Local map:TIntMap = EachIn maps
			Local remove:Int[]
			For Local idKey:TIntKey = EachIn map.Keys()
				Local changeTime:Long = Long( String(map.ValueForKey(idKey.value)) )

				If changeTime + 3000 < Time.GetTimeGone()
					remove :+ [idKey.value]

					If map = removedProgrammeLicences Then availableProgrammeLicences.Remove(idKey.value)
					If map = removedAdContracts Then availableAdContracts.Remove(idKey.value)
					Continue
				EndIf
			Next

			For Local id:Int = EachIn remove
				map.Remove(id)
			Next
		Next
	End Function



	Function GetAddedTime:Long(id:Int, materialType:Int=0)
		If materialType = TVTBroadcastMaterialType.PROGRAMME
			Return Long( String(addedProgrammeLicences.ValueForKey(id)) )
		Else
			Return Long( String(addedAdContracts.ValueForKey(id)) )
		EndIf
	End Function


	Function GetRemovedTime:Long(id:Int, materialType:Int=0)
		If materialType = TVTBroadcastMaterialType.PROGRAMME
			Return Long( String(removedProgrammeLicences.ValueForKey(id)) )
		Else
			Return Long( String(removedAdContracts.ValueForKey(id)) )
		EndIf
	End Function


	Function GetChangedTime:Long(id:Int, materialType:Int=0)
		Local addedTime:Long = GetAddedTime(id, materialType)
		Local removedTime:Long = GetRemovedTime(id, materialType)
		If addedTime <> 0 Then Return addedTime
		Return removedTime
	End Function


	Function Initialize:Int()
		availableProgrammeLicences.Clear()
		'suitcaseProgrammeLicences.Clear()
		availableAdContracts.Clear()
		'on savegame loads, the maps would be empty without
		For Local i:Int = 1 To 4
			Local coll:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(i)
			For Local l:TProgrammeLicence = EachIn coll.GetProgrammeLicences()
				availableProgrammeLicences.insert(l.GetID(), l)
			Next
			'For Local l:TProgrammeLicence = EachIn coll.GetSuitcaseProgrammeLicences()
			'	suitcaseProgrammeLicences.insert(l.GetID(), l)
			'Next
			For Local a:TAdContract = EachIn coll.GetAdContracts()
				availableAdContracts.insert(a.GetID(), a)
			Next
		Next

		initialized = True
	End Function


	Function Update(playerID:Int, x:Int, y:Int)
	End Function


	Function Render(playerID:Int, x:Int, y:Int)
		If Not initialized Then Initialize()

		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Local lineHeight:Int = 11
		Local lineTextDY:Int = -3
		Local lineTextHeight:Int = 15
		Local lineWidth:Int = 160
		Local adLineWidth:Int = 145
		Local adLeftX:Int = 165
		Local font:TBitmapFont = GetBitmapFont("default", 10)
		Local initialY:Int = y
		programmeForHover = null
		contractForHover = null

		'clean up if needed
		If scheduledRemoveOutdatedTimes.length > 0 and scheduledRemoveOutdatedTimes[0] < Time.GetTimeGone()
			haveToRemoveOutdated = False
			RemoveOutdated()
		EndIf

		Local collection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		Local secondLineCol:SColor8 = new SColor8(220, 220,220)

		Local entryPos:Int = 0
		Local oldAlpha:Float = GetAlpha()

		For Local a:TAdContract = EachIn availableAdContracts.Values() 'collection.GetAdContracts()
			If a.owner <> playerID Then Continue

			If entryPos Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 50,50,50
			EndIf
			SetAlpha 0.85 * oldAlpha
			DrawRect(x + adLeftX, y + entryPos * lineHeight*2, adLineWidth, lineHeight*2-1)

			Local changedTime:Int = GetChangedTime(a.GetID(), TVTBroadcastMaterialType.ADVERTISEMENT)
			If changedTime <> 0
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - changedTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND

				SetColor 255,235,20
				If GetRemovedTime(a.GetID(), TVTBroadcastMaterialType.ADVERTISEMENT) <> 0
					If a.state = a.STATE_FAILED
						SetColor 255,0,0
					ElseIf a.state = a.STATE_OK
						SetColor 0,255,0
					EndIf
				EndIf

				DrawRect(x + adLeftX, y + entryPos * lineHeight*2, adLineWidth, lineHeight*2-1)
				SetBlend ALPHABLEND
			EndIf
			SetAlpha oldalpha
			SetColor 255,255,255

			Local adString1a:String = a.GetTitle()
			Local adString1b:String = "R: "+(a.GetDaysLeft())+"D"
			If a.GetDaysLeft() = 1
				adString1b = "|color=220,180,50|"+adString1b+"|/color|"
			ElseIf a.GetDaysLeft() = 0
				adString1b = "|color=220,80,80|"+adString1b+"|/color|"
			EndIf
			Local adString2a:String = "Min: " +MathHelper.DottedValue(a.GetMinAudience())
			If a.GetLimitedToTargetGroup() > 0 Or a.GetLimitedToProgrammeGenre() > 0  Or a.GetLimitedToProgrammeFlag() > 0
				adString2a = "**" + adString2a
				'adString1a :+ a.GetLimitedToTargetGroup()+","+a.GetLimitedToProgrammeGenre()+","+a.GetLimitedToProgrammeFlag()
			EndIf
			adString1b :+ " Bl/D: "+a.SendMinimalBlocksToday()

			Local adString2b:String = "Acu: " +MathHelper.NumberToString(a.GetAcuteness()*100.0)
			Local adString2c:String = a.GetSpotsSent() + "/" + a.GetSpotCount()
			font.DrawBox( adString1a, x + adLeftX + 2, y+1 + entryPos*lineHeight*2 + lineHeight*0 + lineTextDY, adLeftX - 40, lineTextHeight, sALIGN_LEFT_CENTER, SColor8.White)
			font.DrawBox( adString1b, x + adLeftX + 2 + adLineWidth-60-2, y+1 + entryPos*lineHeight*2 + lineHeight*0 + lineTextDY, 60, lineTextHeight, sALIGN_RIGHT_CENTER, secondLineCol)

			font.DrawBox( adString2a, x + adLeftX + 2, y+1 + entryPos*lineHeight*2 + lineHeight*1 + lineTextDY, 60, lineTextHeight, sALIGN_LEFT_CENTER, secondLineCol)
			font.DrawBox( adString2b, x + adLeftX + 2 + 65, y+1 + entryPos*lineHeight*2 + lineHeight*1 + lineTextDY, 55, lineTextHeight, sALIGN_CENTER_CENTER, secondLineCol)
			font.DrawBox( adString2c, x + adLeftX + 2 + adLineWidth-55-2, y+1 + entryPos*lineHeight*2 + lineHeight*1 + lineTextDY, 55, lineTextHeight, sALIGN_RIGHT_CENTER, secondLineCol)

			If THelper.MouseIn(x + adLeftX +2, y + entryPos * lineHeight*2, lineWidth, lineTextHeight*2)
				contractForHover = a
			EndIf

			entryPos :+ 1
		Next

		Local countractCount:Int = entryPos
		entryPos = 0
		lineHeight = 12

		For Local l:TProgrammeLicence = EachIn availableProgrammeLicences.Values() 'collection.GetProgrammeLicences()
			If l.owner <> playerID Then Continue
			'skip starting programme
			If Not l.isControllable() Then Continue
			'skip individual episodes
			If l.isEpisode() Then Continue

			Local oldAlpha:Float = GetAlpha()
			If entryPos Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight, lineWidth, lineHeight-1)

			Local changedTime:Int = GetChangedTime(l.GetID(), TVTBroadcastMaterialType.PROGRAMME)
			If changedTime <> 0
				SetColor 255,235,20
				Local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - changedTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x, y + entryPos * lineHeight, lineWidth, lineHeight-1)
				SetBlend ALPHABLEND
			EndIf

			'draw in topicality
			SetColor 200,50,50
			SetAlpha 0.65 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, lineWidth * l.GetMaxTopicality(), 2)
			SetColor 240,80,80
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, lineWidth * l.GetTopicality(), 2)

			SetAlpha oldalpha
			SetColor 255,255,255

			Local progString:String = l.GetTitle()
			font.DrawBox( progString, x+2, y+1 + entryPos*lineHeight + lineTextDY, lineWidth - 30, lineTextHeight, sALIGN_LEFT_CENTER, SColor8.White)

			Local attString:String = ""
'			local s:string = string(GetPlayer(playerID).aiData.Get("licenceAudienceValue_" + l.GetID()))
			Local s:String = MathHelper.NumberToString(l.GetProgrammeTopicality() * l.GetQuality(), 4)
			If s Then attString = "|color=180,180,180|A|/color|"+ s + " "

			font.DrawBox(attString, x+2, y+1 + entryPos*lineHeight + lineTextDY, lineWidth-5, lineTextHeight, sALIGN_RIGHT_CENTER, SColor8.White)

			If THelper.MouseIn(x, y + entryPos*lineHeight, lineWidth, lineTextHeight)
				programmeForHover = l
			EndIf

			entryPos :+ 1
			If entryPos = 31
				x:+adLeftX
				y = initialY - 9 * lineHeight - ( 11 - countractCount) * 2 * lineHeight
			EndIf
		Next

		If entryPos > 30
			y = initialY + countractCount * 2 * lineHeight + (entryPos - 32) * lineHeight 
		Else
			y = initialY + entryPos*lineHeight
		EndIf
		y :+ 20
		font.DrawSimple("Suitcase: " + collection.GetSuitcaseProgrammeLicenceCount() +" licences", x, y, SColor8.White)
		y :+ 12
		entryPos = 0
		For Local l:TProgrammeLicence = EachIn collection.GetSuitcaseProgrammeLicences()
			Local oldAlpha:Float = GetAlpha()
			If entryPos Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight, lineWidth, lineHeight-1)

			'draw in topicality
			SetColor 200,50,50
			SetAlpha 0.65 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, lineWidth * l.GetMaxTopicality(), 2)
			SetColor 240,80,80
			SetAlpha 0.85 * oldAlpha
			DrawRect(x, y + entryPos * lineHeight + lineHeight-3, lineWidth * l.GetTopicality(), 2)

			SetAlpha oldalpha
			SetColor 255,255,255

			Local progString:String = l.GetTitle()
			font.DrawBox( progString, x+2, y+1 + entryPos*lineHeight + lineTextDY, lineWidth - 30, lineTextHeight, sALIGN_LEFT_CENTER, SColor8.White)

			Local attString:String = ""
'			local s:string = string(GetPlayer(playerID).aiData.Get("licenceAudienceValue_" + l.GetID()))
			Local s:String = MathHelper.NumberToString(l.GetProgrammeTopicality() * l.GetQuality(), 4)
			If s Then attString = "|color=180,180,180|A|/color|"+ s + " "

			font.DrawBox(attString, x+2, y+1 + entryPos*lineHeight + lineTextDY, lineWidth-5, lineTextHeight, sALIGN_RIGHT_CENTER, SColor8.White)

			entryPos :+ 1
		Next
		

		SetAlpha oldAlpha
		SetColor 255,255,255
	End Function
End Type

