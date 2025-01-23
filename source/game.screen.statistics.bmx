SuperStrict
Import "Dig/base.gfx.gui.arrowbutton.bmx"
Import "Dig/base.gfx.gui.tabgroup.bmx"
Import "game.screen.base.bmx"


Type TScreenHandler_OfficeStatistics Extends TScreenHandler
	Field roomOwner:Int = 0
	Field tabGroup:TGUITabGroup
	Field subScreenType:Int = 0

	Field previousDayButton:TGUIArrowButton
	Field nextDayButton:TGUIArrowButton
	Field showDay:Int = 0
	Field hoveredHour:Int = -1
	Field showHour:Int = -1

	Global subScreenChannelImage:TStatisticsSubScreen = new TStatisticsSubScreen_ChannelImage
	Global subScreenAudience:TStatisticsSubScreen = new TStatisticsSubScreen_Audience


	Global LS_officeStatisticsScreen:TLowerString = TLowerString.Create("officeStatisticsScreen")

	Global programmeColor:SColor8 = new SColor8(110,180,100)
	Global newsColor:SColor8 = new SColor8(110,100,180)
	Global fontColor:SColor8 = new SColor8(50, 50, 50)
	Global lightFontColor:SColor8 = new SColor8(120, 120, 120)
	Global rankFontColor:SColor8 = new SColor8(140, 140, 140)
	Global captionColor:SColor8 = new SColor8(70, 70, 70)
	Global backupColor:SColor8 = SColor8.Black
	Global captionFont:TBitmapFont
	Global textFont:TBitmapFont
	Global boldTextFont:TBitmapFont
	Global smallTextFont:TBitmapFont
	Global smallBoldTextFont:TBitmapFont

	Global valueBG:TSprite
	Global valueBG2:TSprite

	Global _eventListeners:TEventListenerBase[]
	Global _instance:TScreenHandler_OfficeStatistics

	Const SUBSCREEN_AUDIENCE:Int = 0
	Const SUBSCREEN_CHANNELIMAGE:Int = 1
	Const SUBSCREEN_TARGETGROUP:Int = 2
	Const SUBSCREEN_STATIONMAP:Int = 3
	Const SUBSCREEN_MISC:Int = 4
	Const SUBSCREEN_TRENDS:Int = 5




	Function GetInstance:TScreenHandler_OfficeStatistics()
		If Not _instance Then _instance = New TScreenHandler_OfficeStatistics
		Return _instance
	End Function


	Method Initialize:Int()
		Local screen:TScreen = ScreenCollection.GetScreen("screen_office_statistics")
		If Not screen Then Return False


		'=== create gui elements if not done yet
		If Not tabGroup
			'for all screens
			tabGroup = New TGUITabGroup.Create(New SVec2I(19, 10), New SVec2I(762,28), "officeStatisticsScreen")

			Local buttonFont:TBitmapFont = GetBitmapFontManager().Get("Default", 12, BOLDFONT)
			For Local i:Int = 0 Until 5
				Local btn:TGUIToggleButton = New TGUIToggleButton.Create(New SVec2I(i*155, 0), New SVec2I(142, 28), "", "officeStatisticsScreen")
				btn.SetFont( buttonFont )
				tabGroup.AddButton(btn, i)
'				statisticGroupButtons :+ [btn]
			Next


			'AudienceScreen
			previousDayButton = New TGUIArrowButton.Create(New SVec2I(290, 251), New SVec2I(24, 24), "LEFT", "officeStatisticsScreen_Audience")
			nextDayButton = New TGUIArrowButton.Create(New SVec2I(290 + 175 + 20, 251), New SVec2I(24, 24), "RIGHT", "officeStatisticsScreen_Audience")

			previousDayButton.SetSpriteButtonOption(TGUISpriteButton.SHOW_BUTTON_NORMAL, False)
			nextDayButton.SetSpriteButtonOption(TGUISpriteButton.SHOW_BUTTON_NORMAL, False)
		EndIf

		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]


		'=== register event listeners
		'listen to clicks on the four buttons
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickButtons, Null, "TGUIArrowButton") ]
		'listen to tab group selections
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUITabGroup_OnSetToggledButton, Self, "onToggleSubScreenTabGroupButton", Null, tabGroup) ]
		'reset show day when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterScreen, Null, screen) ]


		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )

		'(re-)localize content
		SetLanguage()
	End Method


	Method SetLanguage()
		'nothing up to now
		Local captions:String[] = ["AUDIENCE_RATINGS", "CHANNEL_IMAGE", "TARGET_GROUPS", "STATIONMAP", "FINANCES_MISC"]
		For Local i:Int = 0 Until tabGroup.buttons.length
			Local btn:TGUIToggleButton = tabGroup.buttons[i]
			btn.SetCaption(StringHelper.UCFirstSimple(GetLocale(captions[i])))
		Next
	End Method


	Method AbortScreenActions:Int()
		'nothing yet
	End Method


	Method SetSubScreenType:Int(subScreenType:Int)
		If Self.subScreenType = subScreenType Then Return False

		Self.subScreenType = subScreenType

		Select subScreenType
			Case SUBSCREEN_AUDIENCE
				OnActivateSubScreen_Audience()
			Case SUBSCREEN_CHANNELIMAGE
				OnActivateSubScreen_ChannelImage()
			Case SUBSCREEN_TRENDS
			'	OnActivateSubScreen_Trends()
			Case SUBSCREEN_STATIONMAP
			'	OnActivateSubScreen_StationMap()
			Case SUBSCREEN_MISC
			'	OnActivateSubScreen_MISC()
		End Select
	End Method


	Method SetScreenBackground(name:String)
		Local screen:TScreen = ScreenCollection.GetScreen("screen_office_statistics")
		If Not screen Then Return
'		if not TInGameScreen(screen) then return

		TInGameScreen(screen).backgroundSpriteName = name
	End Method


	'=== EVENTS ===

	Method OnActivateSubScreen_Audience:Int()
		'set background
		SetScreenBackground("screen_bg_statistics_audience")

		'move shared gui
	End Method


	Method OnActivateSubScreen_ChannelImage:Int()
		'set background
		SetScreenBackground("screen_bg_statistics_channelimage")

		'move shared gui
	End Method


	Method onToggleSubScreenTabGroupButton:Int(triggerEvent:TEventBase)
		Local buttonIndex:Int = triggerEvent.GetData().GetInt("index", -1)
		If buttonIndex < 0 Then Return False

		SetSubScreenType(buttonIndex)
	End Method


	'reset statistics show day to current when entering the screen
	Function onEnterScreen:Int( triggerEvent:TEventBase )
		GetInstance().showDay = GetWorldTime().GetDay()
	End Function


	Function onClickButtons:Int(triggerEvent:TEventBase)
		Local arrowButton:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If Not arrowButton Then Return False

		If arrowButton = GetInstance().nextDayButton Then GetInstance().showDay :+ 1
		If arrowButton = GetInstance().previousDayButton Then GetInstance().showDay :- 1
	End Function


	Function onDraw:Int( triggerEvent:TEventBase )
		Local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		GetInstance().roomOwner = room.owner

		GetInstance().Render()
	End Function


	Function onUpdate:Int( triggerEvent:TEventBase )
		Local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		GetInstance().roomOwner = room.owner

		GetInstance().Update()
	End Function


	Method Update()
		Select subScreenType
			Case SUBSCREEN_AUDIENCE
				UpdateSubScreen_Audience()
			Case SUBSCREEN_CHANNELIMAGE
				UpdateSubScreen_ChannelImage()
			Case SUBSCREEN_TARGETGROUP
			'	UpdateSubScreen_TargetGroup()
			Case SUBSCREEN_STATIONMAP
			'	UpdateSubScreen_StationMap()
			Case SUBSCREEN_MISC
			'	UpdateSubScreen_MISC()
			Case SUBSCREEN_TRENDS
			'	UpdateSubScreen_Trends()

		End Select

		GuiManager.Update(LS_officeStatisticsScreen)
	End Method


	Method Render()
		Select subScreenType
			Case SUBSCREEN_AUDIENCE
				RenderSubScreen_Audience()
			Case SUBSCREEN_CHANNELIMAGE
				RenderSubScreen_ChannelImage()
			Case SUBSCREEN_TARGETGROUP
			'	RenderSubScreen_TargetGroup()
			Case SUBSCREEN_STATIONMAP
			'	RenderSubScreen_StationMap()
			Case SUBSCREEN_MISC
			'	RenderSubScreen_MISC()
			Case SUBSCREEN_TRENDS
			'	RenderSubScreen_Trends()

		End Select

		GuiManager.Draw( LS_officeStatisticsScreen )
	End Method


	Method UpdateSubScreen_ChannelImage:Int()
		subScreenChannelImage.Update(self)
	End Method


	Method RenderSubScreen_ChannelImage:Int()
		subScreenChannelImage.Render(self)
	End Method


	Method UpdateSubScreen_Audience:Int()
		subScreenAudience.Update(self)
	End Method


	Method RenderSubScreen_Audience:Int()
		subScreenAudience.Render(self)
	End Method
End Type




Type TStatisticsSubScreen
	Field LS_screenName:TLowerString

	Global fontColor:SColor8 = new SColor8(50, 50, 50)
'	Global newsColor:SColor8 = new SColor8(110,100,180)
	Global lightFontColor:SColor8 = new SColor8(120, 120, 120)
	Global rankFontColor:SColor8 = new SColor8(140, 140, 140)
	Global captionColor:SColor8 = new SColor8(70, 70, 70)
	Global backupColor:SColor8 = SColor8.Black

	Global captionFont:TBitmapFont
	Global textFont:TBitmapFont
	Global boldTextFont:TBitmapFont
	Global smallTextFont:TBitmapFont
	Global smallBoldTextFont:TBitmapFont

	Global valueBG:TSprite
	Global valueBG2:TSprite



	Method Update(parent:TScreenHandler_OfficeStatistics)
	End Method

	Method Render(parent:TScreenHandler_OfficeStatistics)
	End Method
End Type




Type TStatisticsSubScreen_Audience extends TStatisticsSubScreen
	Field dataChart:TDataChart
	Field dataChartRequiresRefresh:int = True
	Field lastShowDay:int = -1
	Field _eventListeners:TEventListenerBase[]
	Const DATASET_NEWS:int = 0
	Const DATASET_PROGRAMME:int = 1

	Method New()
		LS_screenName = TLowerString.Create("officeStatisticsScreen_Audience")

		dataChart = new TDataChart
		dataChart.SetPosition(25, 282)
		dataChart.SetDimension(750, 90)
		dataChart.SetXSegmentsCount(24)

		dataChart.valueFormat = "convertvalue"

if TScreenHandler_OfficeStatistics.programmeColor.b <> TScreenHandler_OfficeStatistics.programmeColor.g and TScreenHandler_OfficeStatistics.programmeColor.b <> TScreenHandler_OfficeStatistics.programmeColor.r
	print "Remove programme color reinitialization - seems to be fixed: old programmeColor=" + TScreenHandler_OfficeStatistics.programmeColor.r+", "+ TScreenHandler_OfficeStatistics.programmeColor.g+", " + TScreenHandler_OfficeStatistics.programmeColor.b
endif
		TScreenHandler_OfficeStatistics.programmeColor = new SColor8(110,180,100)
		TScreenHandler_OfficeStatistics.newsColor = new SColor8(110,100,180)

		'news
		dataChart.AddDataSet(new TDataChartDataSet, TScreenHandler_OfficeStatistics.newsColor, new TVec2D(-5,0))
		dataChart.SetDataCount(DATASET_NEWS, 26) '26 to have one earlier and later (-1 to 25)
		'programmes
		dataChart.AddDataSet(new TDataChartDataSet, TScreenHandler_OfficeStatistics.programmeColor, new TVec2D(5,0))
		dataChart.SetDataCount(DATASET_PROGRAMME,26)

		dataChart.SetXRange(0, 24)
rem
		dataChart.SetDataEntry(0, 0, 0 -0.5, 1.0) 'dataset | dataIndex | dataX | dataY
				dataChart.SetDataEntry(0, 1, 1 -0.5, 0.5)
				dataChart.SetDataEntry(0, 2, 3 -0.5, 0.2)
				dataChart.SetDataEntry(0, 3, 6 -0.5, 0.2)
				dataChart.SetDataEntry(0, 4, 8 -0.5, 0.5)
		dataChart.SetDataEntry(0, 8, 9 -0.5, 1.0)
endrem

		For local i:int = 0 until 24
			dataChart.SetXSegmentLabel(i, i)
		Next


		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]


		'refresh charts when a new broadcast begins (newsshow, movie...)
		_eventListeners :+ [EventManager.registerListenerMethod(GameEventKeys.Broadcast_Common_BeginBroadcasting, Self, "OnBeginBroadcasting")]
		'refresh charts when audience changes through station buy/sell
		_eventListeners :+ [EventManager.registerListenerMethod(GameEventKeys.StationMap_OnRecalculateAudienceSum, Self, "OnRecalculateAudienceSum")]
'RONNY
'hier weitermachen:
'- chartpunkte nach "aktueller stunde" sind mit "0" drin, statt "null"
	End Method


	Method Init()
		rem
		If Not valueBG Then valueBG = GetSpriteFromRegistry("screen_financial_balanceValue")
		If Not valueBG2 Then valueBG2 = GetSpriteFromRegistry("screen_financial_balanceValue2filled")
		If Not captionFont Then captionFont = GetBitmapFont("Default", 14, BOLDFONT)
		If Not textFont Then textFont = GetBitmapFont("Default", 14)
		If Not boldTextFont Then boldTextFont = GetBitmapFont("Default", 14, BOLDFONT)
		If Not smallTextFont Then smallTextFont = GetBitmapFont("Default", 12)
		If Not smallBoldTextFont Then smallBoldTextFont = GetBitmapFont("Default", 12, BOLDFONT)
		endrem
	End Method


	Method OnBeginBroadcasting:Int(triggerEvent:TEventBase)
		dataChartRequiresRefresh = True
	End Method

	Method OnRecalculateAudienceSum:Int(triggerEvent:TEventBase)
		dataChartRequiresRefresh = True
	End Method


	Method Update(parent:TScreenHandler_OfficeStatistics)
		if parent.showDay <> lastShowDay
			lastShowDay = parent.showDay
			dataChartRequiresRefresh = True
		endif

		if dataChartRequiresRefresh
			RefreshChartData(parent.roomOwner, parent.showDay)
		endif

		'disable "previous" or "newxt" button of finance display
		If parent.showDay = 0 Or parent.showDay = GetWorldTime().GetStartDay()
			parent.previousDayButton.Disable()
		Else
			parent.previousDayButton.Enable()
		EndIf

		If parent.showDay = GetWorldTime().GetDay()
			parent.nextDayButton.Disable()
			dataChart.autoHoverSegment = GetWorldTime().GetDayHour()
		Else
			parent.nextDayButton.Enable()
			dataChart.autoHoverSegment = -1
		EndIf

		'CHART
		dataChart.Update()

		parent.showHour = dataChart.selectedSegment
		if dataChart.hoveredSegment > -1
			parent.showHour = dataChart.hoveredSegment
		endif

		'GUI
		GuiManager.Update(LS_screenName)
	End Method


	Method RefreshChartData(owner:int, day:int, changedTime:int = False)
		dataChartRequiresRefresh = False

		dataChart.ClearData(0)
		dataChart.ClearData(1)

'		if dataChart.hoveredSegment = -1
'		if dataChart.selectedSegment = -1 or changedTime
'			dataChart.SetSelectedSegment( GetWorldTime().GetDayHour() )
'		endif

		'select chart?
		if GetWorldTime().GetDay() = lastShowDay
			dataChart.SetCurrentSegment( GetWorldTime().GetDayHour() )
		endif



		Local maxHour:Int = 23
		If day = GetWorldTime().GetDay() Then maxHour = GetWorldTime().GetDayHour()

		'statistic for today
		Local yesterdaysBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day-1, True)
		Local todaysBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day, True)
		Local tomorrowsBroadcastStatistic:TDailyBroadcastStatistic
		'showing past?
		if maxHour = 23 and day < GetworldTime().GetDay()
			tomorrowsBroadcastStatistic = GetDailyBroadcastStatistic(day+1, True)
		endif

		'NEWS and PROGRAMME
		For Local broadcastType:Int = EachIn [TVTBroadcastMaterialType.NEWSSHOW, TVTBroadcastMaterialType.PROGRAMME]
			Local datasetIndex:int = 0
			Local audienceResult:TAudienceResultBase

			'add yesterdays last hour
			If broadcastType = TVTBroadcastMaterialType.PROGRAMME
				audienceResult = yesterdaysBroadcastStatistic.GetAudienceResult(owner, 23)
				datasetIndex = DATASET_PROGRAMME
			Else
				audienceResult = yesterdaysBroadcastStatistic.GetNewsAudienceResult(owner, 23)
				datasetIndex = DATASET_NEWS
			EndIf
			'outtage?
			If Not audienceResult
				dataChart.SetDataEntry(datasetIndex, 0, -1, 0)
				'TODO: einfaerben des halbtransparenten hintergrunds in rot
			Else
				dataChart.SetDataEntry(datasetIndex, 0, -1, audienceResult.audience.GetTotalSum())
			EndIf


			'add todays hours
			For Local i:Int = 0 To maxHour
				If broadcastType = TVTBroadcastMaterialType.PROGRAMME
					audienceResult = todaysBroadcastStatistic.GetAudienceResult(owner, i)
					datasetIndex = DATASET_PROGRAMME
				Else
					audienceResult = todaysBroadcastStatistic.GetNewsAudienceResult(owner, i)
					datasetIndex = DATASET_NEWS
				EndIf
				'skip not yet broadcasted programme while news is
				'broadcasted now
				If broadcastType = TVTBroadcastMaterialType.PROGRAMME
					If day = GetWorldTime().GetDay() And i = GetWorldTime().GetDayHour() And GetWorldTime().GetDayMinute() < 5
						dataChart.SetDataEntryPoint(DATASET_PROGRAMME, i+1, Null)
						Continue
					EndIf
				EndIf

				'outtage?
				If Not audienceResult
					dataChart.SetDataEntry(datasetIndex, i+1, i + 0.5, 0)
					'TODO: einfaerben des halbtransparenten hintergrunds in rot
				Else
					dataChart.SetDataEntry(datasetIndex, i+1, i + 0.5, audienceResult.audience.GetTotalSum())
				EndIf
			Next


			'add tomorrows hour
			if tomorrowsBroadcastStatistic
				If broadcastType = TVTBroadcastMaterialType.PROGRAMME
					audienceResult = tomorrowsBroadcastStatistic.GetAudienceResult(owner, 0)
					datasetIndex = DATASET_PROGRAMME
				Else
					audienceResult = tomorrowsBroadcastStatistic.GetNewsAudienceResult(owner, 0)
					datasetIndex = DATASET_NEWS
				EndIf
				'outtage?
				If Not audienceResult
					dataChart.SetDataEntry(datasetIndex, 25, 24, 0)
					'TODO: einfaerben des halbtransparenten hintergrunds in rot
				Else
					dataChart.SetDataEntry(datasetIndex, 25, 24, audienceResult.audience.GetTotalSum())
				EndIf
			endif
		Next
	End Method


	Method RenderChart(parent:TScreenHandler_OfficeStatistics)
		if dataChartRequiresRefresh
			RefreshChartData(parent.roomOwner, parent.showDay)
		endif

		dataChart.Render()
	End Method


	Method Render(parent:TScreenHandler_OfficeStatistics)
		'load sprites if not done yet (or not available before)
		Init()

'		RenderNewsSlot(parent)
'		RenderProgrammeSlot(parent)

'		RenderChart(parent)


		'=== CONFIG ===
		'to center it to table header according "font Baseline"
		Local captionHeight:Int = 24
		Local startY:Int
		'statistic for today
		Local dailyBroadcastStatistic:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(parent.showDay, True)

		'fill cache
		If Not valueBG Then valueBG = GetSpriteFromRegistry("screen_financial_balanceValue")
		If Not valueBG2 Then valueBG2 = GetSpriteFromRegistry("screen_financial_balanceValue2")
		If Not captionFont Then captionFont = GetBitmapFont("Default", 14, BOLDFONT)
		If Not textFont Then textFont = GetBitmapFont("Default", 14)
		If Not boldTextFont Then boldTextFont = GetBitmapFont("Default", 14, BOLDFONT)
		If Not smallTextFont Then smallTextFont = GetBitmapFont("Default", 12)
		If Not smallBoldTextFont Then smallBoldTextFont = GetBitmapFont("Default", 12, BOLDFONt)

		'=== DAY CHANGER ===
		'how much days to draw
		Local showHours:Int = 24
		'where to draw + dimension
		'Local curveArea:SRectI = New SRectI(29, 284, 738, 70)
		'heighest reached audience value of that hours
		Local maxValue:Int = 0
		'minimum audience
		Local minValue:Int = 0
		Local audienceResult:TAudienceResultBase
		
		Local backupColorA:Float

		'add 1 to "today" as we are on this day then
		Local today:Long = GetWorldTime().GetTimeGoneForGameTime(0, parent.showDay, 0, 0)
		Local todayText:String = GetWorldTime().GetDayOfYear(today)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().GetYear(today)
		textFont.DrawBox(GetLocale("GAMEDAY")+" "+todayText, 290+30, 250, 160, 24, sALIGN_CENTER_CENTER, new SColor8(30, 30, 30))


		'=== UNAVAILABLE STATISTICS ===
		If GetDailyBroadcastStatisticCollection().minShowDay >= parent.showDay
			textFont.DrawBox(GetLocale("STATISTICS_NOT_AVAILABLE"), 20 + 4, 80, 175 - 4, 20, sALIGN_LEFT_CENTER, fontColor)


		'=== STATISTICS TABLE ===
		Else
			'for PROGRAMME and NEWS
			For Local progNewsIterator:Int = 0 To 1
				Local tableX:Int = 20
				If progNewsIterator = 1 Then tableX = 450

				'the small added/subtracted numbers are for padding of the text
				Local labelArea:SRectI = New SRectI(tableX + 4, 81-1, 175-4, 19)
				Local valueArea:SRectI = New SRectI(labelArea.GetX2(), labelArea.y + 2, 155 - 5, 19)
				Local captionArea:SRectI = New SRectI(labelArea.x, 57, 322, captionHeight)
				Local bgArea:SRectI = New SRectI(tableX + 4 - 3, 81 -1, valueArea.GetX2() - labelArea.x + 6, 19)
				
				
				Local futureHour:Int = False
				If parent.showDay > GetWorldTime().GetDay()
					futureHour = True
				ElseIf parent.showDay = GetWorldTime().GetDay()
					If parent.showHour > GetWorldTime().GetDayHour() Or (progNewsIterator = 1 And parent.showHour = GetWorldTime().GetDayHour() And GetWorldTime().GetDayMinute() <= 4)
						futureHour = True
					EndIf
				EndIf

				'row backgrounds
				For Local i:Int = 0 To 7
					If i Mod 2 = 0
						valueBG.DrawArea(bgArea.x, bgArea.y, bgArea.w, bgArea.h)
					Else
						valueBG2.DrawArea(bgArea.x, bgArea.y, bgArea.w, bgArea.h)
					EndIf
					bgArea = bgArea.Move(0, bgArea.h)
				Next


				audienceResult = Null
				Local audienceRanks:Int[]
				If parent.showHour >= 0
					If progNewsIterator = 1
						audienceResult = dailyBroadcastStatistic.GetAudienceResult(parent.roomOwner, parent.showHour)
						audienceRanks = dailyBroadcastStatistic.GetAudienceRanking(parent.roomOwner, parent.showHour)
					Else
						audienceResult = dailyBroadcastStatistic.GetNewsAudienceResult(parent.roomOwner, parent.showHour)
						audienceRanks = dailyBroadcastStatistic.GetNewsAudienceRanking(parent.roomOwner, parent.showHour)
					EndIf
				EndIf

				'row entries
				If parent.showHour < 0 Or parent.showHour > 23 Or futureHour
					If progNewsIterator = 1
						captionFont.DrawBox(GetLocale("PROGRAMME")+": "+GetLocale("AUDIENCE_RATING"), captionArea.x, captionArea.y,  captionArea.w, captionArea.h, sALIGN_CENTER_CENTER, captionColor, EDrawTextEffect.Emboss, 0.7)
					Else
						captionFont.DrawBox(GetLocale("NEWS")+": "+GetLocale("AUDIENCE_RATING"), captionArea.x, captionArea.y,  captionArea.w, captionArea.h, sALIGN_CENTER_CENTER, captionColor, EDrawTextEffect.Emboss, 0.7)
					EndIf
				ElseIf Not audienceResult
					If progNewsIterator = 1
						captionFont.DrawBox(GetLocale("PROGRAMME")+": "+GetLocale("BROADCASTING_OUTAGE"), captionArea.x, captionArea.y,  captionArea.w, captionArea.h, sALIGN_CENTER_CENTER, captionColor, EDrawTextEffect.Emboss, 0.5)
					Else
						captionFont.DrawBox(GetLocale("NEWS")+": "+GetLocale("BROADCASTING_OUTAGE"), captionArea.x, captionArea.y,  captionArea.w, captionArea.h, sALIGN_CENTER_CENTER, captionColor, EDrawTextEffect.Emboss, 0.5)
					EndIf
				Else
					Local title:String = audienceResult.GetTitle()
					If audienceResult.broadcastMaterial
						Local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan(parent.roomOwner)
						'real programme
						If TProgramme(audienceResult.broadcastMaterial)
							Local programme:TProgramme = TProgramme(audienceResult.broadcastMaterial)
							Local blockText:String = " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock(parent.showDay, parent.showHour) + "/" + programme.GetBlocks() + ")"
							If (programme.isSeriesEpisode() Or programme.IsCollectionElement()) And programme.licence.parentLicenceGUID
								title = programme.licence.GetParentLicence().GetTitle() + " ("+ programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + blockText
							Else
								title = programme.GetTitle() + blockText
							EndIf
						ElseIf TAdvertisement(audienceResult.broadcastMaterial)
							title = GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")+": "+audienceResult.broadcastMaterial.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock(parent.showDay, parent.showHour) + "/" + audienceResult.broadcastMaterial.GetBlocks() + ")"
						ElseIf TNews(audienceResult.broadcastMaterial)
							title = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+audienceResult.broadcastMaterial.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock(parent.showDay, parent.showHour) + "/" + audienceResult.broadcastMaterial.GetBlocks() + ")"
						ElseIf TNewsShow(audienceResult.broadcastMaterial)
							title = GetLocale("NEWS")+" - "+RSet(parent.showHour,2).Replace(" ","0")+":05"
						EndIf
					EndIf
					captionFont.DrawBox(title, captionArea.x, captionArea.y,  captionArea.w, captionArea.h, sALIGN_CENTER_CENTER, captionColor, EDrawTextEffect.Emboss, 0.5)

					textFont.DrawBox(GetLocale("AUDIENCE")+":", labelArea.x, labelArea.y + 0*labelArea.h, labelArea.w, labelArea.h, sALIGN_LEFT_CENTER, fontColor)
					textFont.DrawBox(GetLocale("POTENTIAL_AUDIENCE")+":", labelArea.x, labelArea.y + 1*labelArea.h, labelArea.w, labelArea.h, sALIGN_LEFT_CENTER, fontColor)
					textFont.DrawBox(GetLocale("BROADCASTING_AREA")+":", labelArea.x, labelArea.y + 2*labelArea.h, labelArea.w, labelArea.h, sALIGN_LEFT_CENTER, fontColor)

					boldTextFont.DrawBox(MathHelper.DottedValue(audienceResult.audience.GetTotalSum()), valueArea.x, valueArea.y + 0*valueArea.h, valueArea.w - 80, valueArea.h, sALIGN_RIGHT_CENTER, fontColor)
					boldTextFont.DrawBox(MathHelper.NumberToString(100.0 * audienceResult.GetAudienceQuotePercentage(), 2) + "%", valueArea.x, valueArea.y + 0*valueArea.h, valueArea.w-20, valueArea.h, sALIGN_RIGHT_CENTER, lightFontColor)
					TextFont.DrawBox("#"+audienceRanks[0], valueArea.x, valueArea.y + 0*valueArea.h -2, valueArea.w, valueArea.h, sALIGN_RIGHT_CENTER, rankFontColor)

					boldTextFont.DrawBox(TFunctions.convertValue(audienceResult.PotentialAudience.GetTotalSum(), 2, 0), valueArea.x, valueArea.y + 1*valueArea.h, valueArea.w - 80, valueArea.h, sALIGN_RIGHT_CENTER, fontColor)
					boldTextFont.DrawBox(MathHelper.NumberToString(100.0 * audienceResult.GetPotentialAudienceQuotePercentage(), 2) + "%", valueArea.x, valueArea.y + 1*valueArea.h, valueArea.w-20, valueArea.h, sALIGN_RIGHT_CENTER, lightFontColor)

					boldTextFont.DrawBox(TFunctions.convertValue(audienceResult.WholeMarket.GetTotalSum(),2, 0), valueArea.x, valueArea.y + 2*valueArea.h, valueArea.w - 80, valueArea.h, sALIGN_RIGHT_CENTER, fontColor)
					boldTextFont.DrawBox(MathHelper.NumberToString(100.0 * audienceResult.WholeMarket.GetTotalSum() / GetStationMapCollection().GetPopulation(), 2) + "%", valueArea.x, valueArea.y + 2*valueArea.h, valueArea.w-20, valueArea.h, sALIGN_RIGHT_CENTER, lightFontColor)

					'target groups
					Local halfWidth:Int = 0.5 * (valueArea.GetX2() - labelArea.x)
					Local splitter:Int = 20

					Local drawOnLeft:Int = True
					For Local i:Int = 1 To 9
						Local row:Int = 3 + Floor((i-1) / 2)

						If i >= 8 Then row = 7
						If i = 8 Then drawOnLeft = 1
						
						Local targetGroupID:Int = TVTTargetGroup.GetAtIndex(i)

						If drawOnLeft
							smallTextFont.DrawBox(GetLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)), labelArea.x, labelArea.y + row*labelArea.h, halfWidth - splitter, labelArea.h, sALIGN_LEFT_CENTER, fontColor)
							smallBoldTextFont.DrawBox(TFunctions.convertValue( audienceResult.audience.GetTotalValue(targetGroupID), 2, 0 ), labelArea.x, labelArea.y + row*labelArea.h, halfWidth - splitter - 20, labelArea.h, sALIGN_RIGHT_CENTER, fontColor)
							smallTextFont.DrawBox("#"+audienceRanks[i], labelArea.x, labelArea.y + row*labelArea.h, halfWidth - splitter, labelArea.h, sALIGN_RIGHT_CENTER, rankFontColor)
						Else
							smallTextFont.DrawBox(GetLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)), labelArea.x + halfWidth + splitter, labelArea.y + row*labelArea.h, halfWidth - splitter, labelArea.h, sALIGN_LEFT_CENTER, fontColor)
							smallBoldTextFont.DrawBox(TFunctions.convertValue( audienceResult.audience.GetTotalValue(targetGroupID), 2, 0 ), labelArea.x +  halfWidth + splitter, labelArea.y + row*labelArea.h, halfWidth - splitter - 20, labelArea.h, sALIGN_RIGHT_CENTER, fontColor)
							smallTextFont.DrawBox("#"+audienceRanks[i], labelArea.x +  halfWidth + splitter, labelArea.y + row*labelArea.h, halfWidth - splitter, labelArea.h, sALIGN_RIGHT_CENTER, rankFontColor)
						EndIf
						drawOnLeft = 1 - drawOnLeft
					Next
				EndIf
			Next




			'=== DRAW AUDIENCE CURVE ===
			startY = 253
			GetColor(backupColor)
			backupColorA = GetAlpha()

			captionFont.DrawBox(GetLocale("AUDIENCE_RATINGS"), 30, startY,  740, captionHeight, sALIGN_LEFT_CENTER, captionColor, EDrawTextEffect.Emboss,  0.5)

			Local rightX:Int = 0
			Local dim:SVec2I
			dim = smallTextFont.DrawBox(GetLocale("PROGRAMME"), 30 + 370, startY+1, 370, 20, sALIGN_RIGHT_CENTER, new SColor8(50, 50, 50), EDrawTextEffect.Emboss, 0.7)
			rightX :+ dim.x + 5

			SetAlpha 0.5 * backupColorA
			SetColor 0,0,0
			DrawRect(30 + 740 - rightX - 15 + 1, startY+3 +1, 15-2, 14-2)
			SetAlpha backupColorA
			SetColor(TScreenHandler_OfficeStatistics.programmeColor)
			DrawRect(30 + 740 - rightX - 15, startY+3, 15, 14)
			rightX :+ 15 + 20

			dim = smallTextFont.DrawBox(GetLocale("NEWS"), 30 + 370 , startY+1, 370 - rightX, 20, sALIGN_RIGHT_CENTER, new SColor8(50, 50, 50), EDrawTextEffect.Emboss, 0.7)
			rightX :+ dim.x + 5

			SetAlpha 0.5 * backupColorA
			SetColor 0,0,0
			DrawRect(30 + 740 - rightX - 15 + 1, startY+3 +1, 15-2, 14-2)
			SetAlpha backupColorA
			SetColor(TScreenHandler_OfficeStatistics.newsColor)
			DrawRect(30 + 740 - rightX - 15, startY+3, 15, 14)

			SetColor(backupColor)

			RenderChart(parent)
		endif

		GuiManager.Draw( LS_screenName )
	End Method
End Type




Type TStatisticsSubScreen_ChannelImage extends TStatisticsSubScreen
	'SUBSCREEN: channel image
	Field hoveredChannelImageTargetGroup:int = -1
	Field hoveredChannelImagePressureGroup:int = -1
	Field selectedChannelImageTargetGroup:int = -1
	Field selectedChannelImagePressureGroup:int = -1

	Field tgCaptionHeight:Int = 25
	Field tgLabelArea:TRectangle
	Field tgValueArea:TRectangle
	Field tgCaptionArea:TRectangle
	Field tgBgArea:TRectangle

	Field pgCaptionHeight:Int = 25
	Field pgLabelArea:TRectangle
	Field pgValueArea:TRectangle
	Field pgCaptionArea:TRectangle
	Field pgBgArea:TRectangle

	Field tgColsTotalW:Int
	Field tgCol1x:Int
	Field tgCol1w:Int
	Field tgCol2x:Int
	Field tgCol2w:Int
	Field tgCol3x:Int
	Field tgCol3w:Int
	Field tgCol4x:Int
	Field tgCol4w:Int

	Field pgColsTotalW:Int
	Field pgCol1x:Int
	Field pgCol1w:Int
	Field pgCol2x:Int
	Field pgCol2w:Int
	Field pgCol3x:Int
	Field pgCol3w:Int
	Field pgCol4x:Int
	Field pgCol4w:Int

	Field dataChart:TDataChart

	Const positiveIndicator:String = " |color=60,150,50|"+Chr(9650)+"|/color|"
	Const neutralIndicator:String = " |color=120,120,120|"+Chr(9632)+"|/color|"
	Const negativeIndicator:String = " |color=150,60,50|"+Chr(9660)+"|/color|"




	Method New()
		LS_screenName = TLowerString.Create("officeStatisticsScreen_ChannelImage")

		tgLabelArea = New TRectangle.Init(35, 61 + 1, 175-4, 19)
		tgValueArea = New TRectangle.Init(tgLabelArea.GetX2(), tgLabelArea.GetY(), 155 - 5, 19)
		tgCaptionArea = New TRectangle.Init(tgLabelArea.GetX(), 57, 323, tgCaptionHeight)

		tgBgArea = tgLabelArea.Copy()
		tgBgArea.SetW( tgValueArea.GetX2() - tgLabelArea.GetX() + 2)

		tgColsTotalW:Int = (tgValueArea.GetX2() - tgLabelArea.GetX())
		tgCol1w = 0.34 * tgColsTotalW
		tgCol2w = 0.22 * tgColsTotalW
		tgCol3w = 0.22 * tgColsTotalW
		tgCol4w = 0.22 * tgColsTotalW

		tgCol1x = tgLabelArea.GetX()
		tgCol2x = tgCol1x + tgCol1w
		tgCol3x = tgCol2x + tgCol2w
		tgCol4x = tgCol3x + tgCol3w



		pgLabelArea = New TRectangle.Init(435, 61 + 1, 175-4, 19)
		pgValueArea = New TRectangle.Init(pgLabelArea.GetX2(), pgLabelArea.GetY(), 155 - 5, 19)
		pgCaptionArea = New TRectangle.Init(pgLabelArea.GetX(), 57, 323, pgCaptionHeight)

		pgBgArea = pgLabelArea.Copy()
		pgBgArea.SetW( pgValueArea.GetX2() - pgLabelArea.GetX() + 2)
		pgColsTotalW = (pgValueArea.GetX2() - pgLabelArea.GetX())
		pgCol1w = 0.34 * pgColsTotalW
		pgCol2w = 0.22 * pgColsTotalW
		pgCol3w = 0.22 * pgColsTotalW
		pgCol4w = 0.22 * pgColsTotalW

		pgCol1x = pgLabelArea.GetX()
		pgCol2x = pgCol1x + pgCol1w
		pgCol3x = pgCol2x + pgCol2w
		pgCol4x = pgCol3x + pgCol3w


		dataChart = new TDataChart
		dataChart.SetPosition(25, 282)
		dataChart.SetDimension(750, 90)
		dataChart.SetXSegmentsCount(8)

		dataChart.AddDataSet(new TDataChartDataSet)
		'26 to have one earlier and later (-1 to 25)
		dataChart.SetDataCount(0,10)

		local times:long[] = new Long[10]
		local timeBegin:Long
		local timeEnd:Long
		local timeTotal:Long
		For local i:int = 0 until 10
			times[i] = GetWorldTime().GetTimeGoneForGameTime(1985, 0 + i, 7, 0)
		Next
		timeBegin = times[0] - 7200 'oder mehr?
		timeEnd = times[9] + 7200 'oder mehr?
		timeTotal = timeEnd - timeBegin

		dataChart.SetXRange(0, 8)
		dataChart.SetDataEntry(0, 0, 0 -0.5, 1.0) 'dataset | dataIndex | dataX | dataY
				dataChart.SetDataEntry(0, 1, 1 -0.5, 0.5)
				dataChart.SetDataEntry(0, 2, 3 -0.5, 0.2)
				dataChart.SetDataEntry(0, 3, 6 -0.5, 0.2)
				dataChart.SetDataEntry(0, 4, 8 -0.5, 0.5)
		dataChart.SetDataEntry(0, 8, 9 -0.5, 1.0)

		For local i:int = 0 until 10
			local dataX:Float = (Float((times[i] - timeBegin)) / timeTotal) * 750
			'start with "1"
'			dataChart.SetDataEntry(0, 1 + i, dataX, RandRange(0, 10)/10.0)

			'skip first
			if i > 0
				'index is "i-1" !
'				dataChart.SetXSegmentLabel(i-1, GetWorldTime().GetFormattedDate(times[i]))
				'test
'				dataChart.SetSegmentWidth(i-1, 60 + (i mod 2 = 0)*20)
			endif
		Next

	End Method




	Method Init()
		If Not valueBG Then valueBG = GetSpriteFromRegistry("screen_financial_balanceValue")
		If Not valueBG2 Then valueBG2 = GetSpriteFromRegistry("screen_financial_balanceValue2filled")
		If Not captionFont Then captionFont = GetBitmapFont("Default", 14, BOLDFONT)
		If Not textFont Then textFont = GetBitmapFont("Default", 14)
		If Not boldTextFont Then boldTextFont = GetBitmapFont("Default", 14, BOLDFONT)
		If Not smallTextFont Then smallTextFont = GetBitmapFont("Default", 12)
		If Not smallBoldTextFont Then smallBoldTextFont = GetBitmapFont("Default", 12, BOLDFONt)
	End Method



	'helper
	Function _DrawValue(value:String, change:Float, x:Int, y:Int, w:Int, h:Int, font:TBitmapFont, fontColor:SColor8)
		font.DrawBox(value, x, y, w - 15, h, sALIGN_RIGHT_CENTER, fontColor)

		If Abs(change) < 0.001
			font.DrawBox(neutralIndicator, x + w - 15, y, 15, h, sALIGN_CENTER_CENTER, fontColor)
		ElseIf change < 0
			font.DrawBox(negativeIndicator, x + w - 15, y, 15, h, sALIGN_CENTER_CENTER, fontColor)
		Else
			font.DrawBox(positiveIndicator, x + w - 15, y, 15, h, sALIGN_CENTER_CENTER, fontColor)
		EndIf
	End Function




	Method Update(parent:TScreenHandler_OfficeStatistics)
		'CHART
		dataChart.Update()


		'TARGET AND PRESSURE GROUPS
		hoveredChannelImageTargetGroup = -1
		hoveredChannelImagePressureGroup = -1


		'TARGET GROUPS
		tgBgArea.SetXY( tgLabelArea.x - 3, tgLabelArea.y - 1 )
		tgBgArea.MoveY( tgBgArea.h ) 'skip row 0

		For Local i:Int = 0 To TVTTargetGroup.baseGroupCount
			if tgBgArea.ContainsVec(MouseManager.currentPos)
				hoveredChannelImageTargetGroup = i
				exit
			endif

			tgBgArea.MoveY( tgBgArea.h )
		Next

		If hoveredChannelImageTargetGroup = -1
			pgBgArea.SetXY( pgLabelArea.x - 3, pgLabelArea.y - 1)
			pgBgArea.MoveY( pgBgArea.h ) 'skip row 0

			For Local i:Int = 1 To TVTPressureGroup.count
				if pgBgArea.ContainsVec(MouseManager.currentPos)
					hoveredChannelImagePressureGroup = i
					exit
				endif

				pgBgArea.MoveY( pgBgArea.h )
			Next
		EndIf


		If MouseManager.IsClicked(1)
			selectedChannelImageTargetGroup = -1
			selectedChannelImagePressureGroup = -1
			If hoveredChannelImagePressureGroup >= 1 or hoveredChannelImageTargetGroup >= 0
				if hoveredChannelImagePressureGroup >= 1
					selectedChannelImagePressureGroup = hoveredChannelImagePressureGroup
				elseif hoveredChannelImageTargetGroup >= 0
					selectedChannelImageTargetGroup = hoveredChannelImageTargetGroup
				endif

				'handled single click
				MouseManager.SetClickHandled(1)
			EndIf
		EndIf

		GuiManager.Update(LS_screenName)
	End Method


	Method RenderTargetGroups(parent:TScreenHandler_OfficeStatistics)
		'TARGET GROUPS
		tgBgArea.SetXY( tgLabelArea.x - 3, tgLabelArea.y - 1 )
		tgBgArea.MoveY( tgBgArea.h ) 'skip row 0


		For Local i:Int = 0 To TVTTargetGroup.baseGroupCount
			If i Mod 2 = 0
				valueBG2.DrawArea(tgBgArea.x, tgBgArea.y, tgBgArea.w, tgBgArea.h)
			Else
				SetColor 240,240,240
				valueBG2.DrawArea(tgBgArea.x, tgBgArea.y, tgBgArea.w, tgBgArea.h)
				SetColor 255,255,255
			EndIf
			If i = selectedChannelImageTargetGroup
'				SetBlend LightBlend
				SetAlpha 0.25
				SetColor 70,110,255
				valueBG2.DrawArea(tgBgArea.x, tgBgArea.y, tgBgArea.w, tgBgArea.h)
				SetColor 255,255,255
				SetAlpha 1.0
				SetBlend alphaBlend
			EndIf
			If i = hoveredChannelImageTargetGroup
				SetBlend LightBlend
				SetAlpha 0.08
				valueBG2.DrawArea(tgBgArea.x, tgBgArea.y, tgBgArea.w, tgBgArea.h)
				SetAlpha 1.0
				SetBlend alphaBlend
			EndIf


			tgBgArea.MoveY( tgBgArea.h )
		Next

		Local channelImageValues:TAudience = GetPublicImageCollection().GetImageValues(parent.roomOwner, 1)
		Local oldChannelImageValues:TAudience = GetPublicImageCollection().GetImageValues(parent.roomOwner, 1, 1)
		smallBoldTextFont.DrawBox(GetLocale("AD_TARGETGROUP"), tgCol1x, tgLabelArea.y + 0*int(tgLabelArea.h), tgCol1w, int(tgLabelArea.h), sALIGN_LEFT_CENTER, fontColor)
		smallBoldTextFont.DrawBox(GetLocale("GENDER_MEN"), tgCol2x, tgLabelArea.y + 0*int(tgLabelArea.h), tgCol2w, int(tgLabelArea.h), sALIGN_RIGHT_CENTER, fontColor)
		smallBoldTextFont.DrawBox(GetLocale("GENDER_WOMEN"), tgCol3x, tgLabelArea.y + 0*int(tgLabelArea.h), tgCol3w, int(tgLabelArea.h), sALIGN_RIGHT_CENTER, fontColor)
		smallBoldTextFont.DrawBox(GetLocale("GENDER_ALL"), tgCol4x, tgLabelArea.y + 0*int(tgLabelArea.h), tgCol4w, int(tgLabelArea.h), sALIGN_RIGHT_CENTER, fontColor)


		For Local i:Int = 0 To TVTTargetGroup.baseGroupCount
			smallTextFont.DrawBox(GetLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString( TVTTargetGroup.GetAtIndex(i) )), tgCol1x, tgLabelArea.y + (i+1)*int(tgLabelArea.h), tgCol1w, int(tgLabelArea.h), sALIGN_LEFT_CENTER, fontColor)
			If i = 0
				Local change:Float
				change = channelImageValues.GetGenderAverage(TVTPersonGender.MALE) - oldChannelImageValues.GetGenderAverage(TVTPersonGender.MALE)
				_DrawValue(MathHelper.NumberToString(channelImageValues.GetGenderAverage(TVTPersonGender.MALE), 2), change, tgCol2x, int(tgLabelArea.y + (0+1)*tgLabelArea.h), tgCol2w, int(tgLabelArea.h), smallTextFont, fontColor )

				change = channelImageValues.GetGenderAverage(TVTPersonGender.FEMALE) - oldChannelImageValues.GetGenderAverage(TVTPersonGender.FEMALE)
				_DrawValue(MathHelper.NumberToString(channelImageValues.GetGenderAverage(TVTPersonGender.FEMALE), 2), change, tgCol3x, int(tgLabelArea.y + (0+1)*tgLabelArea.h), tgCol3w, int(tgLabelArea.h), smallTextFont, fontColor )

				change = channelImageValues.GetTotalAverage() - oldChannelImageValues.GetTotalAverage()
				_DrawValue(MathHelper.NumberToString(channelImageValues.GetTotalAverage(), 2), change, tgCol4x, int(tgLabelArea.y + (0+1)*tgLabelArea.h), tgCol4w, int(tgLabelArea.h), smallTextFont, fontColor )

			Else
				Local change:Float
				change = channelImageValues.GetGenderValue(i, TVTPersonGender.MALE) - oldChannelImageValues.GetGenderValue(i, TVTPersonGender.MALE)
				_DrawValue(MathHelper.NumberToString(channelImageValues.GetGenderValue(i, TVTPersonGender.MALE), 2), change, tgCol2x, int(tgLabelArea.y + (i+1)*tgLabelArea.h), tgCol2w, int(tgLabelArea.h), smallTextFont, fontColor )

				change = channelImageValues.GetGenderValue(i, TVTPersonGender.FEMALE) - oldChannelImageValues.GetGenderValue(i, TVTPersonGender.FEMALE)
				_DrawValue(MathHelper.NumberToString(channelImageValues.GetGenderValue(i, TVTPersonGender.FEMALE), 2), change, tgCol3x, int(tgLabelArea.y + (i+1)*tgLabelArea.h), tgCol3w, int(tgLabelArea.h), smallTextFont, fontColor )

				change = channelImageValues.GetTotalValue(i) - oldChannelImageValues.GetTotalValue(i)
				_DrawValue(MathHelper.NumberToString(channelImageValues.GetTotalValue(i), 2), change, tgCol4x, int(tgLabelArea.y + (i+1)*tgLabelArea.h), tgCol4w, int(tgLabelArea.h), smallTextFont, fontColor )
			EndIf
		Next
	End Method


	Method RenderPressureGroups(parent:TScreenHandler_OfficeStatistics)
		'LOBBY/PRESSURE GROUPS
		pgBgArea.SetXY( pgLabelArea.x - 3, pgLabelArea.y - 1)
		pgBgArea.MoveY( pgBgArea.h ) 'skip row 0


		For Local i:Int = 1 To TVTPressureGroup.count
			If i Mod 2 = 1
				valueBG.DrawArea(pgBgArea.x, pgBgArea.y, pgBgArea.w, pgBgArea.h)
			Else
				valueBG2.DrawArea(pgBgArea.x, pgBgArea.y, pgBgArea.w, pgBgArea.h)
			EndIf
			If i = selectedChannelImagePressureGroup
				SetBlend LightBlend
				SetAlpha 0.15
				If i Mod 2 = 0
					valueBG.DrawArea(pgBgArea.x, pgBgArea.y, pgBgArea.w, pgBgArea.h)
				Else
					valueBG2.DrawArea(pgBgArea.x, pgBgArea.y, pgBgArea.w, pgBgArea.h)
				EndIf
				SetAlpha 1.0
				SetBlend alphaBlend
			EndIf
			If i = hoveredChannelImagePressureGroup
				SetBlend LightBlend
				SetAlpha 0.10
				If i Mod 2 = 0
					valueBG.DrawArea(pgBgArea.x, pgBgArea.y, pgBgArea.w, pgBgArea.h)
				Else
					valueBG2.DrawArea(pgBgArea.x, pgBgArea.y, pgBgArea.w, pgBgArea.h)
				EndIf
				SetAlpha 1.0
				SetBlend alphaBlend
			EndIf

			pgBgArea.MoveY( pgBgArea.h )
		Next


		smallBoldTextFont.DrawBox(GetLocale("PRESSURE_GROUPS"), pgCol1x, pgLabelArea.y + 0*int(pgLabelArea.h), pgCol1w + pgCol2w, int(pgLabelArea.h), sALIGN_LEFT_CENTER, fontColor)
		For Local i:Int = 1 To TVTPressureGroup.count
			smallTextFont.DrawBox(GetLocale("PRESSURE_GROUPS_"+TVTPressureGroup.GetAsString( TVTPressureGroup.GetAtIndex(i) )), pgCol1x, pgLabelArea.y + (i)*int(pgLabelArea.h), pgCol1w, int(pgLabelArea.h), sALIGN_LEFT_CENTER, fontColor)

			Local change:Float = GetPressureGroupCollection().GetChannelSympathy(parent.roomOwner, i, 0) - GetPressureGroupCollection().GetChannelSympathy(parent.roomOwner, i, 1)
			_DrawValue(MathHelper.NumberToString(GetPressureGroup(i).GetChannelSympathy(parent.roomOwner), 2, False), change, pgCol4x, int(pgLabelArea.y + i*int(pgLabelArea.h)), pgCol4w, int(pgLabelArea.h), smallTextFont, fontColor)
		Next
	End Method


	Method RenderChart(parent:TScreenHandler_OfficeStatistics)
		dataChart.Render()
	End Method


	Method Render(parent:TScreenHandler_OfficeStatistics)
		'load sprites if not done yet (or not available before)
		Init()



		RenderTargetGroups(parent)
		RenderPressureGroups(parent)

		RenderChart(parent)


		GuiManager.Draw( LS_screenName )
	End Method
End Type




Type TDataChartDataSet
	Field points:TVec2D[]
	Field minimumY:Float
	Field maximumY:Float
	Field maximumAtIndex:Int
	Field minimumAtIndex:Int
	Field _cacheValid:Int = False



	Method UpdateCache()
		'TODO: max/min fuer derzeitig angezeigte Werte/Viewport
		If points.length > 0
			maximumY = points[0].y
			minimumY = points[0].y
			maximumAtIndex = 0
			minimumAtIndex = 0

			For Local i:int = 0 until points.length
				if not points[i] then continue

				If maximumY < points[i].y
					maximumAtIndex = i
					maximumY = points[i].y
				EndIf
				If minimumY > points[i].y
					minimumAtIndex = i
					minimumY = points[i].y
				EndIf
			Next
		EndIf

		_cacheValid = True
	End Method


	Method GetMinimumY:Float()
		If Not _cacheValid Then UpdateCache()
		return minimumY
	End Method


	Method GetMaximumY:Float()
		If Not _cacheValid Then UpdateCache()
		return maximumY
	End Method


	Method ClearData:TDataChartDataSet()
		points = new TVec2D[ points.length ]

		_cacheValid = False

		Return self
	End Method


	Method SetData:TDataChartDataSet(points:TVec2D[])
		self.points = points

		_cacheValid = False

		Return Self
	End Method


	Method SetDataCount:TDataChartDataSet(count:Int)
		If points
			If count <> points.length
				points = points[ .. count]
				_cacheValid = False
			EndIf
		Else
			points = new TVec2D[count]
			_cacheValid = False
		EndIf

		Return Self
	End Method


	Method SetDataEntry:TDataChartDataSet(index:Int, x:Float, y:Float)
		if points.length <= index or index < 0 then Return Self
		if points[index]
			points[index].x = x
			points[index].y = y
		else
			points[index] = new TVec2D(x,y)
		endif

		_cacheValid = False

		Return Self
	End Method


	Method SetDataEntryPoint:TDataChartDataSet(index:Int, point:TVec2D)
		if points.length <= index or index < 0 then Return Self
		points[index] = point

		_cacheValid = False

		Return Self
	End Method

End Type




Type TDataChart
	Field area:TRectangle = new TRectangle
	Field areaGraph:TRectangle = new TRectangle

	'x value limits (min-max)
	Field xRangeBegin:Float
	Field xRangeEnd:Float
	'begin/end indices for each dataset
	'they are depending on the currently set (visible) range
	Field xRangeDataIndexBegin:Int[]
	Field xRangeDataIndexEnd:Int[]
	'Field xRangeMinimum:Float
	'Field xRangeMaximum:Float

	'zoom factor, how many data points fit into one pixel
	'             or how many pixels are needed to show all data points
	Field _pixelsPerDataPointX:Float


	Field xSegmentsCount:int
	'width for all (if no individuals are set)
	Field xSegmentWidth:int = -1
	'width of the individual segments
	Field xSegmentWidths:int[]
	'start position of the individual segments
	Field xSegmentStarts:int[]
	Field xSegmentLabels:string[]
	'how many data blocks are _before_ the first
	Field xDataOffset:int = 1
	Field hoveredSegment:int = -1
	Field currentSegment:int = -1
	Field selectedSegment:int = -1
	Field dataStartX:Float = 0
	Field dataEndX:Float = 23
	Field dataSets:TDataChartDataSet[]
	Field dataSetColors:SColor8[]
	Field dataSetSecondaryColors:SColor8[]
	Field dataSetOffsets:TVec2D[]
	Field labelFont:TBitmapFont
	Field labelColor:SColor8 = new SColor8(120, 120, 120)
	Field labelColor2:SColor8 = new SColor8(80, 80, 80)

	'Field selectedColor:TColor = TColor.Create(200,200,200)
	Field selectedColor:SColor8 = new SColor8(185,200,255)
	Field hoveredColor:SColor8 = new SColor8(95,110,255)

	Field leftAxisLabelEnabled:int = True
	Field rightAxisLabelEnabled:int = True
	Field topAxisLabelEnabled:int = False
	Field bottomAxisLabelEnabled:int = True

	Field leftAxisLabelSize:int = 50
	Field rightAxisLabelSize:int = 50
	Field topAxisLabelSize:int = 15
	Field bottomAxisLabelSize:int = 15
	Field leftAxisLabelOffset:TVec2D = new TVec2D(0, 0)
	Field rightAxisLabelOffset:TVec2D = new TVec2D(4, -4)
	Field topAxisLabelOffset:TVec2D = new TVec2D(0, -2)
	Field bottomAxisLabelOffset:TVec2D = new TVec2D(0, 2)

	Field valueFormat:String = "%3.3f"
	Field valueDisplayMaximumY:Float
	Field valueDisplayMinimumY:Float

	'segment implicitly hovered if no other is hovered explicitly
	Field autoHoverSegment:Int = -1
	'depending of to viewport
	'Field _dataStartIndex:Int
	'Field _dataEndIndex:Int


	Method GetPixelsPerDataPointX:Float()
		If _pixelsPerDataPointX > 0
			return _pixelsPerDataPointX
		Else
			if (xRangeEnd - xRangeBegin) <> 0
				return abs((areaGraph.GetIntW() / Float(xRangeEnd - xRangeBegin)))
			else
				return area.GetW()
			endif
		EndIf
	End Method


	Method SetPosition:TDataChart(x:int, y:int)
		area.SetXY(x,y)

'		_RefreshElementSizes()

		Return self
	End Method


	Method SetDimension:TDataChart(w:int, h:int)
		area.SetWH(w,h)

		_RefreshElementSizes()
		Return self
	End Method


	Method SetXRange(valueBegin:Float, valueEnd:Float)
		xRangeBegin = valueBegin
		xRangeEnd = valueEnd
	End Method


	Method SetXSegmentLabels:TDataChart(labels:string[], referenceArray:int = False)
		If referenceArray
			xSegmentLabels = labels
		Else
			xSegmentLabels = labels[ .. ]
		EndIf

		Return self
	End Method


	Method SetXSegmentLabel:TDataChart(index:int, label:string)
		if index < 0 or index >= xSegmentLabels.length Then Return self
		xSegmentLabels[index] = label
	End Method


	Method SetXSegmentsCount:TDataChart(count:int)
		xSegmentsCount = count
		If xSegmentLabels.length <> count
			xSegmentLabels = xSegmentLabels[ .. xSegmentsCount]
			xSegmentWidths = xSegmentWidths[ .. xSegmentsCount]
			xSegmentStarts = xSegmentStarts[ .. xSegmentsCount]
		EndIf

		_RefreshElementSizes()
		Return self
	End Method


	Method _RefreshElementSizes()
		'update padding information
		local axisTop:int = topAxisLabelEnabled * topAxisLabelSize
		local axisLeft:int = leftAxisLabelEnabled * leftAxisLabelSize
		local axisBottom:int = bottomAxisLabelEnabled * bottomAxisLabelSize
		local axisRight:int = rightAxisLabelEnabled * rightAxisLabelSize

		'update graph area
		areaGraph.SetXYWH(axisLeft + 1, ..
		                  axisTop, ..
		                  area.GetW() - (axisLeft + 1 + axisRight), ..
		                  area.GetH() - (axisTop  + axisBottom + 1) ..
		                 )

		'resize segments
		'global
		xSegmentWidth = areaGraph.GetW() / xSegmentsCount
		'individual
		'TODO

		'add "skipped pixels" to right label area
		areaGraph.MoveW( -(areaGraph.w - xSegmentWidth * xSegmentsCount))
	End Method


	Method SetSegmentWidth(segmentIndex:int, width:int)
		if segmentIndex < 0 or segmentIndex >= xSegmentWidths.length then return

		xSegmentWidths[segmentIndex] = width
		'position this segment after the previous one
		if segmentIndex > 0
			xSegmentStarts[segmentIndex] = xSegmentStarts[segmentIndex -1] + GetSegmentWidth(segmentIndex -1)
		endif

		'reposition all elements afterwards
		if segmentIndex < xSegmentWidths.length-1
			'recursive called for all coming segments
			SetSegmentWidth(segmentIndex + 1, GetSegmentWidth(segmentIndex + 1))
		endif
	End Method


	Method GetSegmentWidth:int(segmentIndex:int)
		if segmentIndex < 0 or segmentIndex >= xSegmentWidths.length then return 0
		'fallback
		if xSegmentWidths[segmentIndex] <= 0 and xSegmentWidth > 0 then return xSegmentWidth
		'or use defined value
		return xSegmentWidths[segmentIndex]
	End Method


	Method GetSegmentStart:int(segmentIndex:int)
		if segmentIndex < 0 or not xSegmentStarts or segmentIndex >= xSegmentStarts.length then return 0

		'use auto-calculated value
		if xSegmentStarts[segmentIndex] <= 0
			if segmentIndex > 0
				return GetSegmentStart(segmentIndex -1) + GetSegmentWidth(segmentIndex -1)
			else
				return 0
			endif
		endif

		'or use defined value
		return xSegmentStarts[segmentIndex]
	End Method


	Method GetMinimumY:Float()
		if dataSets.length = 0 then return 0

		local m:Float = dataSets[0].GetMinimumY()
		For local ds:TDataChartDataSet = EachIn dataSets
			if m > ds.GetMinimumY() then m = ds.GetMinimumY()
		Next
		return m
	End Method


	Method GetMaximumY:Float()
		if dataSets.length = 0 then return 0

		local m:Float = dataSets[0].GetMaximumY()
		For local ds:TDataChartDataSet = EachIn dataSets
			if m < ds.GetMaximumY() then m = ds.GetMaximumY()
		Next
		return m
	End Method


	Method AddDataSet:TDataChart(dataSet:TDataChartDataSet)
		Return AddDataSet(dataSet, SColor8.Black, Null)
	End Method

	Method AddDataSet:TDataChart(dataSet:TDataChartDataSet, color:SColor8, offset:TVec2D = null)
		dataSets :+ [dataSet]
		dataSetColors :+ [color]
		dataSetSecondaryColors = dataSetSecondaryColors[ .. dataSetSecondaryColors.length + 1]
		dataSetOffsets = dataSetOffsets[ .. dataSetOffsets.length + 1]
		return self
	End Method


	Method SetDataSet:TDataChart(index:int, dataSet:TDataChartDataSet, color:SColor8, offset:TVec2D = null)
		if dataSets.length <= index
			dataSets = dataSets[ .. index]
			dataSetColors = dataSetColors[ .. index]
			dataSetSecondaryColors = dataSetSecondaryColors[ .. index]
			dataSetOffsets = dataSetOffsets[ .. index]
		endif
		dataSets[index] = dataSet
		dataSetColors[index] = color
		dataSetOffsets[index] = offset
		return self
	End Method


	Method ClearData:TDataChart(dataSetIndex:int = -1)
		if dataSetIndex < 0
			For local ds:TDataChartDataSet = EachIn dataSets
				ds.ClearData()
			Next
		elseif dataSetIndex < dataSets.length and dataSets[dataSetIndex]
			dataSets[dataSetIndex].ClearData()
		endif
		return self
	End Method


	Method SetData:TDataChart(dataSetIndex:int, dataPoints:TVec2D[])
		if dataSetIndex >= 0 and dataSetIndex < dataSets.length and dataSets[dataSetIndex]
			dataSets[dataSetIndex].SetData(dataPoints)
		endif

		Return Self
	End Method


	Method SetDataCount:TDataChart(dataSetIndex:int, count:Int)
		if dataSetIndex >= 0 and dataSetIndex < dataSets.length and dataSets[dataSetIndex]
			dataSets[dataSetIndex].SetDataCount(count)
		endif

		Return Self
	End Method


	Method SetDataEntry:TDataChart(dataSetIndex:int, index:Int, x:Float, y:Float)
		if dataSetIndex >= 0 and dataSetIndex < dataSets.length and dataSets[dataSetIndex]
			dataSets[dataSetIndex].SetDataEntry(index, x, y)
		endif

		Return Self
	End Method


	Method SetDataEntryPoint:TDataChart(dataSetIndex:int, index:Int, point:TVec2D)
		if dataSetIndex >= 0 and dataSetIndex < dataSets.length and dataSets[dataSetIndex]
			dataSets[dataSetIndex].SetDataEntryPoint(index, point)
		endif

		Return Self
	End Method


	'for current hour
	Method SetCurrentSegment:TDataChart(segmentIndex:int = -1)
		currentSegment = segmentIndex
		return self
	End Method


	Method SetSelectedSegment:TDataChart(segmentIndex:int = -1)
		selectedSegment = segmentIndex
		return self
	End Method


	Method SetHoveredSegment:TDataChart(segmentIndex:int = -1)
		hoveredSegment = segmentIndex
		return self
	End Method


	Method Update()
		hoveredSegment = -1

		If area.ContainsVec(MouseManager.currentPos)
			Local startX:int = area.GetX() + areaGraph.GetX()
			For local i:int = 0 until xSegmentsCount
				If MouseManager.currentPos.x > startX and MouseManager.currentPos.x <= startX + xSegmentWidth
					SetHoveredSegment(i)

					If MouseManager.IsClicked(1)
						If selectedSegment = i
							SetSelectedSegment(-1)
						Else
							SetSelectedSegment(i)
						EndIf
						'handled single click
						MouseManager.SetClickHandled(1)
					EndIf

					exit
				EndIf
				startX :+ xSegmentWidth
			Next
		EndIf
		If hoveredSegment < 0 And selectedSegment < 0 And autoHoverSegment >= 0
			hoveredSegment = autoHoverSegment
		EndIf
	End Method


	Method Render()
		if not labelFont Then labelFont = GetBitmapFont("Default", 10)


		RenderBackground()
		RenderData()
		RenderTexts()
	End Method


	Method RenderBackground()
		Local x:int = area.GetIntX() + areaGraph.GetIntX() - 1 '+-1 for the borders
		Local y:int = area.GetIntY() + areaGraph.GetIntY() - 1
		Local w:int = areaGraph.GetIntW() + 2
		Local h:int = areaGraph.GetIntH() + 2
'		SetColor 255,0,0
'		DrawRect(x,y,w,h)
		SetColor 50,50,50
		DrawLine(x, y, x, y + h - 1)
		DrawLine(x, y + h - 1, x + w - 1, y + h - 1)
'print x+"  " + y + "  " + w + "  " + h
		SetColor 150,150,150
		DrawLine(x + w - 1, y + 1, x + w - 1, y + h - 2) '+2 and -2 to avoid overlap
		DrawLine(x + 1, y, x + w - 1, y) '+1 and -1 to avoid overlap
		SetColor 255,255,255


		for local i:int = 0 until xSegmentsCount
			SetColor 0,0,0
			if i mod 2 = 0
				SetAlpha 0.1
			else
				SetAlpha 0.05
			endif
			DrawRect(x + 1 + GetSegmentStart(i), y+1, GetSegmentWidth(i), h-2)
		next
		SetAlpha 1.0

		'hover states
		if hoveredSegment>=0 or selectedSegment>=0 or currentSegment>=0
			if currentSegment >= 0
				SetAlpha 0.10
				SetBlend LightBlend
				SetColor 255,255,255
				DrawRect(x + 1 + GetSegmentStart(currentSegment), y+1, GetSegmentWidth(currentSegment), h-2)
			endif
			'selected segment itself is hovered or no other segment is hovered
			if selectedSegment >= 0 And (hoveredSegment < 0 Or selectedSegment = hoveredSegment)
				SetAlpha 0.15
				SetBlend ShadeBlend
				SetColor(selectedColor)
				DrawRect(x + 1 + GetSegmentStart(selectedSegment), y+1, GetSegmentWidth(selectedSegment), h-2)
			endif
			if hoveredSegment >= 0
				SetAlpha 0.15
				SetBlend LightBlend
				SetColor(hoveredColor)
				DrawRect(x + 1 + GetSegmentStart(hoveredSegment), y+1, GetSegmentWidth(hoveredSegment), h-2)
			endif
			SetAlpha 1.0
			SetBlend AlphaBlend
		endif


		'splitter lines
		SetColor 150,150,150
'		SetAlpha 0.2
		For local i:int = 0 until xSegmentsCount - 1 'skip last
			DrawLine(x + GetSegmentStart(i+1), y + 1, x + GetSegmentStart(i+1), y + h - 2)
		Next
'		SetAlpha 1.0

		'draw arrows on axis
		SetColor 50,50,50
		DrawPoly([Float(x),Float(y), Float(x+4), Float(y+3), Float(x-2), Float(y+3)]) '+4 instead of +2 -- don't know why
		DrawPoly([Float(x+w),Float(y+h), Float(x+w-3), Float(y+h-2), Float(x+w-3), Float(y+h+2)])

		SetColor 255,255,255
	End Method


	Method RenderData()
		GetGraphicsManager().BackupAndSetViewport( areaGraph.Copy().MoveXY(area.x, area.y) )

		local shadowCol:TColor = TColor.Create(0,0,0)
		shadowCol.a = 0.3

		'shadow render
		For local dsIndex:int = 0 until dataSets.length
			RenderDataSet(dsIndex, 0, 1, shadowCol)
		Next

		'points render
		For local dsIndex:int = 0 until dataSets.length
			RenderDataSet(dsIndex, 0, 0)
		Next

		GetGraphicsManager().RestoreViewport()
	End Method


	Method RenderDataSet(dsIndex:int, xOffset:int=0, yOffset:int=0, colorOverride:TColor=Null)
		Local x:int = area.GetIntX() + areaGraph.GetIntX()
		Local y:int = area.GetIntY() + areaGraph.GetIntY()
		Local w:int = areaGraph.GetIntW()
		Local h:int = areaGraph.GetIntH()
		Local maximumY:Float = GetMaximumY()
		Local minimumY:Float = GetMinimumY()
		Local effectiveMaximumY:Float = 1.1 * maximumY
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		Local pixelsPerDataPointX:Float = GetPixelsPerDataPointX()

		Local baseDataPointX:Int = x ' + 0.5*pixelsPerDataPointX
		Local dataPointX:Float

		valueDisplayMaximumY = 1.1 * maximumY
		valueDisplayMinimumY = 0

		if dataSetOffsets.length > dsIndex and dataSetOffsets[dsIndex]
			x :+ dataSetOffsets[dsIndex].x
			y :+ dataSetOffsets[dsIndex].y
		endif

		if not dataSetColors[dsIndex]
			dataSetColors[dsIndex] = new SColor8(70 + Rand(130), 70 + Rand(130), 70 + Rand(130))
		endif

		if not dataSetSecondaryColors[dsIndex]
			dataSetSecondaryColors[dsIndex] = new TColor(dataSetColors[dsIndex]).AdjustBrightness(-0.25).Multiply(1.0, 1.0, 1.0, 0.5).ToSColor8()
		endif


		'=== DOTS BG ===
		if colorOverride
			colorOverride.SetRGBA()
		else
			SetColor(dataSetSecondaryColors[dsIndex])
			SetAlpha(dataSetSecondaryColors[dsIndex].a/255.0)
		endif
		dataPointX = basedataPointX
		if dataSets[dsIndex]
			For Local i:int = xDataOffset until Min(xDataOffset + xSegmentsCount, dataSets[dsIndex].points.length)
				if not dataSets[dsIndex].points[i] then continue

				dataPointX = int(baseDataPointX + pixelsPerDataPointX * dataSets[dsIndex].points[i].x)

				DrawOval(xOffset + dataPointX -3, ..
						 yOffset + y + (1 - dataSets[dsIndex].points[i].y/valueDisplayMaximumY) * h -3, ..
						 7,7)
			Next
		endif

		'=== LINES ===
		'if drawConnected
		if colorOverride
			colorOverride.SetRGBA()
		else
			SetColor(dataSetSecondaryColors[dsIndex])
			SetAlpha(dataSetSecondaryColors[dsIndex].a/255.0)
		endif
		SetAlpha 0.5 * GetAlpha()
		SetLineWidth(2)
		GetGraphicsManager().EnableSmoothLines()
		if dataSets[dsIndex].points.length >= xDataOffset
			'for now: first must be present
			local lastX:Float = dataSets[dsIndex].points[0 + xDataOffset - 1].x
			local lastY:Float = dataSets[dsIndex].points[0 + xDataOffset - 1].y
			For Local i:int = xDataOffset to Min(xDataOffset + xSegmentsCount +1, dataSets[dsIndex].points.length-1)
				if not dataSets[dsIndex].points[i] then continue

				DrawLine(int(xOffset + baseDataPointX + pixelsPerDataPointX * lastX), ..
						 int(yOffset + y + (1 - lastY/valueDisplayMaximumY) * h), ..
						 int(xOffset + baseDataPointX + pixelsPerDataPointX * dataSets[dsIndex].points[i].x), ..
						 int(yOffset + y + (1 - dataSets[dsIndex].points[i].y/valueDisplayMaximumY) * h))
				lastX = dataSets[dsIndex].points[i].x
				lasty = dataSets[dsIndex].points[i].y
			Next
		endif
		SetLineWidth(1)
		SetAlpha 2 * GetAlpha()

		'endif


		'=== DOTS ===
		if colorOverride
			colorOverride.SetRGBA()
		else
			SetColor(dataSetColors[dsIndex])
			SetAlpha(dataSetColors[dsIndex].a/255.0)
		endif
		dataPointX = basedataPointX
		For Local i:int = xDataOffset until Min(xDataOffset + xSegmentsCount, dataSets[dsIndex].points.length)
			if not dataSets[dsIndex].points[i] then continue

			dataPointX = int(baseDataPointX + pixelsPerDataPointX * dataSets[dsIndex].points[i].x)
			DrawOval(xOffset + dataPointX -2, yOffset + y + (1 - dataSets[dsIndex].points[i].y/valueDisplayMaximumY) * h -2, 5,5)
		Next

		SetColor( oldCol )
		SetAlpha( oldColA )
	End Method


	Method RenderTexts()
		'segment labels
		Local bottomXLabelH:int = area.GetH() - areaGraph.GetY2()
		Local x:int = area.GetIntX() + areaGraph.GetIntX()
		Local x2:int = area.GetIntX() + areaGraph.GetIntX2()

		Local col:SColor8
		For Local i:Int = 0 Until xSegmentsCount
			local dataIndex:int = i  + xDataOffset

			if xSegmentLabels.length > i and xSegmentLabels[i]
				if i = hoveredSegment
					col = hoveredColor
'				elseif i = selectedSegment
'					col = selectedColor
				elseif (i mod 2 = 0)
					col = labelColor2
				else
					col = labelColor
				endif

				labelFont.DrawBox(xSegmentLabels[i], x + GetSegmentStart(i) + bottomAxisLabelOffset.GetIntX(), area.GetY2() - bottomXLabelH + bottomAxisLabelOffset.GetIntY(), GetSegmentWidth(i), bottomXLabelH, sALIGN_CENTER_CENTER, col)
			EndIf
			labelFont.DrawBox(dataIndex, x + GetSegmentStart(i) + bottomAxisLabelOffset.GetIntX(), -20 + area.GetY2() - bottomXLabelH + bottomAxisLabelOffset.GetIntY(), GetSegmentWidth(i), bottomXLabelH, sALIGN_CENTER_CENTER, col)
		Next

		'values
		labelFont.DrawBox(GetFormattedValue(valueDisplayMaximumY), int(x2 + rightAxisLabelOffset.GetIntX()), int(area.GetY() + areaGraph.GetY() + rightAxisLabelOffset.GetY()), (area.GetX2() - areaGraph.GetX2()), 20, sALIGN_LEFT_TOP, labelColor)
		labelFont.DrawBox(GetFormattedValue(valueDisplayMinimumY), int(x2 + rightAxisLabelOffset.GetIntX()), int(area.GetY() + areaGraph.GetY2() + rightAxisLabelOffset.GetY()), (area.GetX2() - areaGraph.GetX2()), 20, sALIGN_LEFT_TOP, labelColor)
	End Method


	Method GetFormattedValue:string(v:float)
		if valueFormat = "convertvalue"
			return TFunctions.convertValue(v,0,2)
		else
			return StringHelper.printf(valueFormat, [string(v)])
		endif
	End Method
End Type
