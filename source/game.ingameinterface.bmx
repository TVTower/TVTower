SuperStrict
Import "Dig/base.framework.tooltip.bmx"
Import "Dig/base.framework.toastmessage.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.util.graphicsmanagerbase.bmx"

Import "game.gui.chat.bmx"

Import "game.betty.bmx"

Import "game.player.base.bmx"
Import "game.figure.bmx"
Import "game.player.programmeplan.bmx"
Import "game.game.base.bmx"
Import "game.misc.ingamehelp.bmx"


Global openEscapeMenuViaInterface:Int = False
'Interface, border, TV-antenna, audience-picture and number, watch...
'updates tv-images shown and so on
Type TInGameInterface
	Field gfx_bottomRTT:TImage
	Field CurrentProgramme:TSprite
	Field CurrentProgrammeOverlay:TSprite
	Field CurrentAudience:TImage
	Field CurrentProgrammeText:String
	Field CurrentProgrammeToolTip:TTooltip
	Field CurrentAudienceToolTip:TTooltipAudience
	Field keepCurrentAudienceToolTipOpen:int = False
	Field MoneyToolTip:TTooltip
	Field BettyToolTip:TTooltip
	Field ChannelImageTooltip:TTooltip
	Field MenuToolTip:TTooltip
	Field CurrentTimeToolTip:TTooltip
	Field tooltips:TList = CreateList()
	Field tvOverlaySprite:TSprite
	Field noiseSprite:TSprite
	Field noiseAlpha:Float	= 0.95
	Field noiseDisplace:Trectangle = new TRectangle.Init(0,0,0,0)
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field ChatShow:int = False
	Field ChatContainsUnread:int = False
	Field ChatShowHideLocked:int = False
	Field BottomImgDirty:Int = 1
	Field hoveredMenuButton:int = 0
	Field hoveredMenuButtonPos:TVec2D = new TVec2D.Init(0,0)

	Field chat:TGUIGameChat

	Global _instance:TInGameInterface

	Field ingameState:TLowerString = TLowerString.Create("InGame")

	Function GetInstance:TInGameInterface()
		if not _instance then _instance = new TInGameInterface.Init()
		return _instance
	End Function


	'initializes an interface
	Method Init:TInGameInterface()
		if not chat
			'TLogger.Log("TGame", "Creating ingame GUIelements", LOG_DEBUG)
			chat = New TGUIGameChat.Create(New TVec2D.Init(515, 404), New TVec2D.Init(278,180), "InGame")
			'keep the chat entries visible
			'chat.setDefaultHideEntryTime(10000)
			chat.setOption(GUI_OBJECT_CLICKABLE, False)
			chat.SetDefaultTextColor( TColor.Create(255,255,255) )
			'bugged:
			'chat.guiList.autoHideScroller = True
			'remove unneeded elements
			chat.SetBackground(Null)

			'reposition input
			chat.guiInput.rect.position.setXY( 515, 354 )
			chat.guiInput.Resize( 280, 30 )
			chat.guiInput.setMaxLength(200)
			chat.guiInput.setOption(GUI_OBJECT_POSITIONABSOLUTE, True)
			chat.guiInput.SetMaxTextWidth(255)
			chat.guiInput.spriteName = "gfx_interface_ingamechat_input"
			chat.guiInput.color.AdjustRGB(30,30,30,True)
			chat.guiInput.SetValueDisplacement(3,5)
		EndIf

		CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")

		CurrentProgrammeToolTip = TTooltip.Create("", "", 40, 395)
		CurrentProgrammeToolTip.SetMinTitleAndContentWidth(240)

		CurrentAudienceToolTip = TTooltipAudience.Create("", "", 490, 440)
		CurrentAudienceToolTip.SetMinTitleAndContentWidth(200)

		CurrentTimeToolTip = TTooltip.Create("", "", 490, 535)
		CurrentTimeTooltip._minContentWidth = 190
		MoneyToolTip = TTooltip.Create("", "", 490, 408)
		MoneyToolTip.SetMinTitleAndContentWidth(190)
		BettyToolTip = TTooltip.Create("", "", 490, 485)
		ChannelImageTooltip = TTooltip.Create("", "", 490, 510)
		MenuToolTip = TTooltip.Create("", "", 470, 560)

		'collect them in one list (to sort them correctly)
		tooltips.Clear()
		tooltips.AddLast(CurrentProgrammeToolTip)
		tooltips.AddLast(CurrentAudienceToolTip)
		tooltips.AddLast(CurrentTimeToolTip)
		tooltips.AddLast(MoneyTooltip)
		tooltips.AddLast(BettyToolTip)
		tooltips.AddLast(MenuToolTip)
		tooltips.AddLast(ChannelImageTooltip)

		noiseSprite = GetSpriteFromRegistry("gfx_interface_tv_noise")
		tvOverlaySprite = GetSpriteFromRegistry("gfx_interface_tv_overlay")
		'set space "left" when subtracting the genre image
		'so we know how many pixels we can move that image to simulate animation
		noiseDisplace.Dimension.SetX(Max(0, noiseSprite.GetWidth() - tvOverlaySprite.GetWidth()))
		noiseDisplace.Dimension.SetY(Max(0, noiseSprite.GetHeight() - tvOverlaySprite.GetHeight()))


		'=== SETUP SPAWNPOINTS FOR TOASTMESSAGES ===
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(5,5, 395,300), new TVec2D.Init(0,0), "TOPLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(400,5, 395,300), new TVec2D.Init(1,0), "TOPRIGHT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(5,230, 395,50), new TVec2D.Init(0,1), "BOTTOMLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(400,230, 395,50), new TVec2D.Init(1,1), "BOTTOMRIGHT" )


		'show chat if an chat entry was added
		EventManager.registerListenerFunction( "chat.onAddEntry", onIngameChatAddEntry )
		'invalidate audience tooltip's "audienceresult" on recalculation
		EventManager.registerListenerFunction( "StationMap.onRecalculateAudienceSum", onStationMapRecalculateAudienceSum )

		Return self
	End Method


	Function onIngameChatAddEntry:Int( triggerEvent:TEventBase )
		'ignore if not in a game
		If not GetGameBase().PlayingAGame() then return False

		'mark that there is something to read
		GetInstance().ChatContainsUnread = True

		'if user did not lock the current view
		If not GetInstance().ChatShowHideLocked
			GetInstance().ChatShow = True
		EndIf
	End Function


	'invalidate audience tooltip's "audienceresult" on recalculation
	'this is needed as the passed "audience" is the same instance
	'(just with different numbers)
	Function onStationMapRecalculateAudienceSum:Int( triggerEvent:TEventBase )
		local playerID:int = triggerEvent.GetData().GetInt("playerID", -1)
		if playerID > 0
			if GetInstance().CurrentAudienceToolTip
				GetInstance().CurrentAudienceToolTip.dirtyImage = True
			endif
		endif
	End Function


	Method Update(deltaTime:Float=1.0)
		local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan(ShowChannel)

		'reset old hovered state
		hoveredMenuButton = 0

		if not GetWorldTime().IsPaused()
			'show the channels tooltip on hovering the button
			For Local i:Int = 1 To 4
				'already done
				if ShowChannel = i then continue

				'tooltip to show (regardless of currently shown channel)
				If THelper.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
					programmePlan = GetPlayerProgrammePlan(i)
				EndIf
			Next

			'channel selection (tvscreen on interface)
			For Local i:Int = 0 To 4
				If THelper.MouseIn( 75 + i * 33, 171 + 383 + 16 - i*4, 33, 25)
					'hover state
					GetGameBase().cursorstate = 1

					If MOUSEMANAGER.IsClicked(1)
						ShowChannel = i
						BottomImgDirty = True
						exit
					EndIf
				EndIf
			Next


			'reset current programme sprites
			CurrentProgrammeOverlay = Null
			CurrentProgramme = Null

			if programmePlan	'similar to "ShowChannel<>0"
				If GetWorldTime().GetDayMinute() >= 55
					Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
					If obj
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads")
						'real ad
						If TAdvertisement(obj)
							CurrentProgrammeToolTip.TitleBGtype = 1
							CurrentProgrammeText = getLocale("ADVERTISMENT") + ": " + obj.GetTitle()
						Else
							If(TProgramme(obj))
								CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_" + TProgramme(obj).data.GetGenre(), "gfx_interface_tv_programme_none")
							EndIf
							CurrentProgrammeOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_traileroverlay")
							CurrentProgrammeToolTip.TitleBGtype = 1
							CurrentProgrammeText = getLocale("TRAILER") + ": " + obj.GetTitle()
						EndIf
					Else
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads_none")

						CurrentProgrammeToolTip.TitleBGtype	= 2
						CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
					EndIf
				ElseIf GetWorldTime().GetDayMinute() < 5
					CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_news")
					CurrentProgrammeToolTip.TitleBGtype	= 3
					CurrentProgrammeText = getLocale("NEWS")
				Else
					Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
					If obj
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
						CurrentProgrammeToolTip.TitleBGtype	= 0
						'real programme
						If TProgramme(obj)
							Local programme:TProgramme = TProgramme(obj)
							CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_genre_" + TVTProgrammeGenre.GetAsString(programme.data.GetGenre()), "gfx_interface_tv_programme_none")
							If (programme.IsSeriesEpisode() or programme.IsCollectionElement()) and programme.licence.parentLicenceGUID
								CurrentProgrammeText = programme.licence.GetParentLicence().GetTitle() + " ("+ programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
							Else
								CurrentProgrammeText = programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
							EndIf
						ElseIf TAdvertisement(obj)
							CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads")
							CurrentProgrammeOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_infomercialoverlay")
							CurrentProgrammeText = GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						ElseIf TNews(obj)
							CurrentProgrammeText = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						EndIf
					Else
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
						CurrentProgrammeToolTip.TitleBGtype	= 2
						CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
					EndIf
				EndIf
			Else
				CurrentProgrammeToolTip.TitleBGtype = 3
				CurrentProgrammeText = getLocale("TV_OFF")
			EndIf 'no programmePlan found -> invalid player / tv off


			If THelper.MouseIn(20,382,280,200)
				CurrentProgrammeToolTip.SetTitle(CurrentProgrammeText)
				local content:String = ""
				If programmePlan
					content	= GetLocale("AUDIENCE_NUMBER")+": "+programmePlan.getFormattedAudience()+ " ("+MathHelper.NumberToString(programmePlan.GetAudiencePercentage()*100,2)+"%)"

					'Newsshow details
					If GetWorldTime().GetDayMinute()<5
						local newsCount:int = 0
						Local show:TNewsShow = TNewsShow(programmePlan.GetNewsShow())

						if show and show.news then newsCount = show.news.length

						If newsCount > 0
							content :+ "~n"
							For local i:int = 0 until newsCount
								if show.news[i]
									content :+ "~n"+(i+1)+"/"+newsCount+": " + show.news[i].GetTitle()
								else
									content :+ "~n"+(i+1)+"/"+newsCount+": -/-"
								endif
							Next
						endif
					EndIf

					'show additional information if channel is player's channel
					If programmePlan.owner = GetPlayerBaseCollection().playerID
						If GetWorldTime().GetDayMinute() >= 5 And GetWorldTime().GetDayMinute() < 55
							Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
							If TAdvertisement(obj)
								'outage before?
								If not programmePlan.GetProgramme()
									content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n" + obj.GetTitle()+" ("+ GetLocale("INVALID_BY_BROADCAST_OUTAGE") +")"
								Else
									local minAudienceText:string = TFunctions.convertValue(TAdvertisement(obj).contract.getMinAudience())
									if TAdvertisement(obj).contract.GetLimitedToTargetGroup() > 0
										minAudienceText :+" " + TAdvertisement(obj).contract.GetLimitedToTargetGroupString()
									endif

									'check if the ad passes all checks for the current broadcast
									local passingRequirements:String = TAdvertisement(obj).IsPassingRequirements(GetBroadcastManager().GetAudienceResult(programmePlan.owner))
									if passingRequirements = "OK"
										minAudienceText = "|color=100,200,100|" + minAudienceText + "|/color|"
									else
										Select passingRequirements
											case "TARGETGROUP"
												minAudienceText = "|color=200,100,100|" + minAudienceText + " " + TAdvertisement(obj).contract.GetLimitedToTargetGroupString()+ "!|/color|"
											case "GENRE"
												minAudienceText = "|color=200,100,100|" + minAudienceText + " " + TAdvertisement(obj).contract.GetLimitedToGenreString()+ "!|/color|"
											default
												minAudienceText = "|color=200,100,100|" + minAudienceText + "|/color|"
										End Select
									endif

									content :+ "~n ~n|b||color=100,150,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n" + "|b|"+obj.GetTitle()+"|/b|~n" + GetLocale("MIN_AUDIENCE") +": "+ minAudienceText
								EndIf
							ElseIf TProgramme(obj)
								content :+ "~n ~n|b|"+getLocale("NEXT_ADBLOCK")+":|/b|~n"+ GetLocale("TRAILER")+": " + obj.GetTitle()
							Else
								content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n"+ GetLocale("NEXT_NOTHINGSET")
							EndIf

						ElseIf GetWorldTime().GetDayMinute()>=55 Or GetWorldTime().GetDayMinute()<5
							'upcoming programme hint
							Local obj:TBroadcastMaterial
							Local upcomingProgDay:int = -1
							Local upcomingProgHour:int = -1
							if GetWorldTime().GetDayMinute()>= 55
								local nextHourTime:Long = GetWorldTime().ModifyTime(-1, 0, 0, 1)
								upcomingProgDay = GetWorldTime().GetDay(nextHourTime)
								upcomingProgHour = GetWorldTime().GetDayHour(nextHourTime)
							endif
							obj = programmePlan.GetProgramme(upcomingProgDay, upcomingProgHour)

							If TProgramme(obj)
								content :+ "~n ~n|b|"+getLocale("NEXT_PROGRAMME")+":|/b|~n"
								If TProgramme(obj) And (TProgramme(obj).IsSeriesEpisode() or TProgramme(obj).IsCollectionElement()) And TProgramme(obj).licence.parentLicenceGUID
									content :+ TProgramme(obj).licence.GetParentLicence().data.GetTitle() + ": " + obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock(upcomingProgDay, upcomingProgHour) + "/" + obj.GetBlocks() + ")"
								Else
									content :+ obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock(upcomingProgDay, upcomingProgHour) + "/" + obj.GetBlocks() + ")"
								EndIf
							ElseIf TAdvertisement(obj)
								content :+ "~n ~n|b|"+getLocale("NEXT_PROGRAMME")+":|/b|~n"+ GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")+": " + obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock(upcomingProgDay, upcomingProgHour) + "/" + obj.GetBlocks() + ")"
							Else
								content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_PROGRAMME")+":|/color||/b|~n"+ GetLocale("NEXT_NOTHINGSET")
							EndIf
						EndIf
					EndIf
				Else
					content = getLocale("TV_TURN_IT_ON")
				EndIf

				CurrentProgrammeToolTip.SetContent(content)
				CurrentProgrammeToolTip.enabled = 1
				CurrentProgrammeToolTip.Hover()
			EndIf
			If THelper.MouseIn(309,412,178,32)
				MoneyToolTip.title = getLocale("MONEY")
				local content:String = ""
				content	= "|b|"+getLocale("MONEY")+":|/b| "+MathHelper.DottedValue(GetPlayerBase().GetMoney()) + getLocale("CURRENCY")
				if GetPlayerBase().GetCredit() > 0
					content	:+ "~n"
					content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=200,100,100|"+ MathHelper.DottedValue(GetPlayerBase().GetCredit()) + getLocale("CURRENCY")+"|/color|"
				else
					content	:+ "~n"
					content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=0,200,100|0" + getLocale("CURRENCY")+"|/color|"
				endif

				local profit:int = GetPlayerFinance(GetPlayerBase().playerID).GetCurrentProfit()
				if profit > 0
					content	:+ "~n"
					content	:+ "|b|"+getLocale("FINANCES_TODAYS_INCOME")+":|/b| |color=100,200,100|+"+ MathHelper.DottedValue(profit) + getLocale("CURRENCY")+"|/color|"
				elseif profit = 0
					content	:+ "~n"
					content	:+ "|b|"+getLocale("FINANCES_TODAYS_INCOME")+":|/b| |color=100,100,100|0" + getLocale("CURRENCY")+"|/color|"
				else
					content	:+ "~n"
					content	:+ "|b|"+getLocale("FINANCES_TODAYS_INCOME")+":|/b| |color=200,100,100|"+ MathHelper.DottedValue(profit) + getLocale("CURRENCY")+"|/color|"
				endif

				MoneyTooltip.SetContent(content)
				MoneyToolTip.enabled 	= 1
				MoneyToolTip.Hover()
			EndIf
			If THelper.MouseIn(309,447,178,32) or CurrentAudienceToolTip.forceShow
				local playerProgrammePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan( GetPlayerBaseCollection().playerID )
				if playerProgrammePlan
					CurrentAudienceToolTip.SetTitle(GetLocale("AUDIENCE_NUMBER")+": "+playerProgrammePlan.getFormattedAudience()+ " ("+MathHelper.NumberToString(playerProgrammePlan.GetAudiencePercentage() * 100,2)+"%)")
					CurrentAudienceToolTip.SetAudienceResult(GetBroadcastManager().GetAudienceResult(playerProgrammePlan.owner))

					CurrentAudienceToolTip.enabled = 1
					CurrentAudienceToolTip.Hover()
					'force redraw
					'CurrentAudienceToolTip.dirtyImage = True
				endif
			EndIf
			If THelper.MouseIn(309,482,178,25)
				BettyToolTip.SetTitle(getLocale("BETTY_FEELINGS"))
				local bettyLove:Float = GetBetty().GetInLovePercentage( GetPlayerBase().playerID )
				if bettyLove = 0
					BettyToolTip.SetContent(getLocale("THERE_IS_NO_LOVE_IN_THE_AIR_YET"))
				elseif bettyLove < 0.1
					BettyToolTip.SetContent(getLocale("BETTY_KNOWS_WHO_YOU_ARE"))
				elseif bettyLove < 0.2
					BettyToolTip.SetContent(getLocale("BETTY_SEEMS_TO_LIKE_YOU"))
				elseif bettyLove < 0.4
					BettyToolTip.SetContent(getLocale("BETTY_SEEMS_TO_LIKE_YOU_A_BIT_MORE"))
				elseif bettyLove < 0.75
					BettyToolTip.SetContent(getLocale("BETTY_LOVES_YOU"))
				else
					BettyToolTip.SetContent(getLocale("BETTY_REALLY_LOVES_YOU"))
				endif
				BettyToolTip.enabled = 1
				BettyToolTip.Hover()
			EndIf
			'channel image
			If THelper.MouseIn(309,510,178,25)
				ChannelImageTooltip.SetTitle(getLocale("CHANNEL_IMAGE"))
				local content:string = ""
				for local i:int = 1 to 4
					if content then content :+ "~n"

					local channelImage:Float = Min(Max(GetPublicImage(i).GetAverageImage()/100.0, 0.0),1.0)
					if i = GetPlayerBase().playerID
						content :+ "|b|"+GetPlayerBase(i).channelname+": " + MathHelper.NumberToString(channelImage*100, 2)+"%|/b|"
					else
						content :+ GetPlayerBase(i).channelname+": " + MathHelper.NumberToString(channelImage*100, 2)+"%"
					endif
				Next
				ChannelImageToolTip.SetContent(content)
				ChannelImageToolTip.enabled = 1
				ChannelImageToolTip.Hover()
			endif

			If THelper.MouseIn(309,538,178,32)
				CurrentTimeToolTip.SetTitle(getLocale("GAME_TIME")+": " + GetWorldTime().getFormattedTime())
				local content:string = ""
				content :+ "|b|"+GetLocale("GAMEDAY")+":|/b| "+(GetWorldTime().GetDaysRun()+1) + " (" + GetLocale("WEEK_LONG_"+GetWorldTime().GetDayName(GetWorldTime().GetWeekday())) + ")"
				content :+ "~n"
				content :+ "|b|"+GetLocale("DAY_OF_YEAR")+":|/b| "+GetWorldTime().getDayOfYear()+"/"+GetWorldTime().GetDaysPerYear()
				content :+ "~n"
				content :+ "|b|"+GetLocale("DATE")+":|/b| "+GetWorldTime().GetFormattedDate(-1, GameConfig.dateFormat)+" ("+GetLocale("SEASON_"+GetWorldTime().GetSeasonName())+")"
				CurrentTimeToolTip.SetContent(content)
				CurrentTimeToolTip.enabled = 1
				CurrentTimeToolTip.Hover()
				'force redraw
				CurrentTimeToolTip.dirtyImage = True
			EndIf
			If THelper.MouseIn(309,577,45,23)
				hoveredMenuButton = 1
				hoveredMenuButtonPos.SetXY(309,578)

				MenuToolTip.area.position.SetX(364)
				MenuToolTip.SetTitle(getLocale("MENU"))
				MenuToolTip.SetContent(getLocale("OPEN_MENU"))
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					openEscapeMenuViaInterface = True
					MouseManager.ResetKey(1)
				EndIf

			ElseIf THelper.MouseIn(357,577,43,23)
				hoveredMenuButton = 2
				hoveredMenuButtonPos.SetXY(357,578)

				MenuToolTip.area.position.SetX(410)
				MenuToolTip.SetTitle(getLocale("HELP"))
				MenuToolTip.SetContent(getLocale("SHOW_HELP"))
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					'force show manual
					IngameHelpWindowCollection.ShowByHelpGUID("GameManual", True)
					MouseManager.ResetKey(1)
				EndIf

			ElseIf THelper.MouseIn(400,577,29,23)
				hoveredMenuButton = 3
				hoveredMenuButtonPos.SetXY(400,578)

				MenuToolTip.area.position.SetX(439)
				MenuToolTip.SetTitle(getLocale("GAMESPEED"))
				MenuToolTip.SetContent(getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 1))
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					GetGameBase().SetGameSpeedPreset(0)
					MouseManager.ResetKey(1)
				EndIf

			ElseIf THelper.MouseIn(429,577,30,23)
				hoveredMenuButton = 4
				hoveredMenuButtonPos.SetXY(429,578)

				MenuToolTip.area.position.SetX(469)
				MenuToolTip.SetTitle(getLocale("GAMESPEED"))
				MenuToolTip.SetContent(getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 2))
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					GetGameBase().SetGameSpeedPreset(1)
					MouseManager.ResetKey(1)
				EndIf

			ElseIf THelper.MouseIn(457,577,30,23)
				hoveredMenuButton = 5
				hoveredMenuButtonPos.SetXY(457,578)

				MenuToolTip.area.position.SetX(497)
				MenuToolTip.SetTitle(getLocale("GAMESPEED"))
				MenuToolTip.SetContent(getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 3))
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					GetGameBase().SetGameSpeedPreset(2)
					MouseManager.ResetKey(1)
				EndIf
			EndIf
		endif


		if CurrentAudienceToolTip
			if CheckObservedFigureInRoom("adagency") or CheckObservedFigureInRoom("office")
				'show longer tooltip by default
				CurrentAudienceToolTip.showDetailed = True

				'keep showing the tooltip
				if KeyManager.IsHit(KEY_LALT) or KeyManager.IsHit(KEY_RALT)
					CurrentAudienceToolTip.forceShow = 1 - CurrentAudienceToolTip.forceShow
				endif
			else
				'disable force show if not in the rooms above
				CurrentAudienceToolTip.forceShow = false

				'show longer tooltip
				CurrentAudienceToolTip.showDetailed = False
				If KeyManager.isDown(KEY_LALT) Or KeyManager.isDown(KEY_RALT)
					CurrentAudienceToolTip.showDetailed = True
				endif
			endif
		endif



		'=== THINGS DONE REGARDLESS OF PAUSED STATE ===



		'=== SHOW / HIDE / LOCK CHAT ===
		if not ChatShow
			'arrow area
			if MouseManager.IsClicked(1) and THelper.MouseIn(540, 397, 200, 20)
				'reset unread
				ChatContainsUnread = False

				ChatShow = True
				if chat then chat.ShowChat()

				MouseManager.ResetKey(1)
			endif
			'lock area
			if MouseManager.IsClicked(1) and THelper.MouseIn(770, 397, 20, 20)
				ChatShowHideLocked = 1- ChatShowHideLocked
			endif
		else
			'arrow area
			if MouseManager.IsClicked(1) and THelper.MouseIn(540, 583, 200, 17)
				'reset unread
				ChatContainsUnread = False

				ChatShow = False
				if chat then chat.HideChat()

				MouseManager.ResetKey(1)
			endif
			'lock area
			if MouseManager.IsClicked(1) and THelper.MouseIn(770, 583, 20, 20)
				ChatShowHideLocked = 1 - ChatShowHideLocked
			endif
		endif

		if chat and not ChatShowHideLocked
			if not ChatShow
				chat.HideChat()
			else
				chat.ShowChat()
			endif
		endif
		'====


		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Update()
		Next
		tooltips.Sort() 'sort according lifetime


		'skip adjusting the noise if the tv is off
		If programmePlan
			'noise on interface-tvscreen
			ChangeNoiseTimer :+ deltaTime
			If ChangeNoiseTimer >= 0.20
				noiseDisplace.position.SetXY(Rand(0, int(noiseDisplace.dimension.GetX())),Rand(0, int(noiseDisplace.dimension.GetY())))
				ChangeNoiseTimer = 0.0
				NoiseAlpha = 0.45 - (Rand(0,20)*0.01)
			EndIf
		EndIf
	End Method


	'returns a string list of abbreviations for the watching family
	Function GetWatchingFamily:string[](playerID:int = 0)
		'fall back to local player
		if playerID = 0 then playerID = GetPlayerBase().playerID
		'fetch feedback to see which test-family member might watch
		Local feedback:TBroadcastFeedback = GetBroadcastManager().GetCurrentBroadcast().GetFeedback(playerID)

		local result:String[]
		if not feedback or not feedback.AudienceInterest
			print "Interface.GetWatchingFamily: no AudienceInterest!"
			debugstop
			return result
		endif
		if (feedback.AudienceInterest.GetTotalValue(TVTTargetGroup.Children) > 0)

			'maybe sent to bed ? :D
			'If GetWorldTime().GetDayHour() >= 5 and GetWorldTime().GetDayHour() < 22 then 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["girl"]
		endif

		if (feedback.AudienceInterest.GetTotalValue(TVTTargetGroup.Pensioners) > 0) then result :+ ["grandpa"]

		if (feedback.AudienceInterest.GetTotalValue(TVTTargetGroup.Teenagers) > 0)
			'in school monday-friday - in school from till 7 to 13 - needs no sleep :D
			'If GetworldTime().GetWeekday()>6 or (GetWorldTime().GetDayHour() < 7 or GetWorldTime().GetDayHour() >= 13) then result :+ ["teen"] 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["teen"]
		endif

		if (feedback.AudienceInterest.GetTotalValue(TVTTargetGroup.Unemployed) > 0)
			result :+ ["unemployed"]
		else
			'if there is some audience, show the sleeping unemployed
			if GetPlayerProgrammePlan( GetPlayerBase().playerID ).GetAudiencePercentage() > 0.05
				result :+ ["unemployed.bored"]
			endif
		endif

		return result
	End Function


	'draws the interface
	Method Draw(tweenValue:Float=1.0)
		local oldAlpha:float = GetAlpha()

		If BottomImgDirty 'unused for now
			local playerID:int = GetPlayerBase().playerID
		    'channel choosen and something aired?
			local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan( ShowChannel )


			'=== INTERFACE ===

			'draw bottom, aligned "bottom"
			GetSpriteFromRegistry("gfx_interface_bottom").Draw(0, GetGraphicsManager().GetHeight(), 0, ALIGN_LEFT_BOTTOM)


			'=== TV on the left ===

			'CurrentProgramme can contain "outage"-image, so draw
			'even without audience
			If CurrentProgramme
				if CurrentProgramme.GetWidth() < 200 '220 is normal width
					local scaleRatio:Float = 220.0 / CurrentProgramme.GetWidth()
					CurrentProgramme.DrawArea(45, 405, 220, CurrentProgramme.GetHeight()*scaleRatio)
				else
					CurrentProgramme.Draw(45, 405)
				endif
			endif
			'draw trailer/infomercial-hint
			If CurrentProgrammeOverlay
				if CurrentProgrammeOverlay.GetWidth() < 200 '220 is normal width
					local scaleRatio:Float = 220.0 / CurrentProgrammeOverlay.GetWidth()
					CurrentProgrammeOverlay.DrawArea(45, 405, 220, CurrentProgrammeOverlay.GetHeight()*scaleRatio)
				else
					CurrentProgrammeOverlay.Draw(45, 405)
				endif
			endif

			'draw noise of tv device
			If ShowChannel <> 0
				'decrease contrast a bit
				SetAlpha float(0.1 * (Sin(Millisecs()*0.15)+1))
				SetColor 125,125,125
				DrawRect(45,405, 220, 170)
				SetColor 255,255,255

				SetAlpha NoiseAlpha
				If noiseSprite Then noiseSprite.DrawClipped(new TRectangle.Init(45, 405, 220,170), new TVec2D.Init(noiseDisplace.GetX(), noiseDisplace.GetY()) )
				SetAlpha 1.0
			EndIf

			'draw overlay to hide corners of non-round images
			if tvOverlaySprite then tvOverlaySprite.Draw(45,405)

			'draw buttons
		    For Local i:Int = 0 To 4
				If i = ShowChannel
					GetSpriteFromRegistry("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 559)
					'lighten up the channel button
					SetBlend LightBlend
					SetAlpha 0.25 * oldAlpha
					GetSpriteFromRegistry("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 559)
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				Else
					GetSpriteFromRegistry("gfx_interface_channelbuttons_off_"+i).Draw(75 + i * 33, 559)
				EndIf
				'hover effect
				If THelper.MouseIn( 75 + i * 33, 171 + 383 + 16 - i*4, 33, 25)
					SetBlend LightBlend
					SetAlpha 0.35 * oldAlpha
					If i = ShowChannel
						GetSpriteFromRegistry("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 559)
					Else
						GetSpriteFromRegistry("gfx_interface_channelbuttons_off_"+i).Draw(75 + i * 33, 559)
					EndIf
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				EndIf
		    Next


			'=== TV-FAMILY ===

			'draw TV-family
			If programmePlan and GetBroadcastManager().GetCurrentAudience(showChannel) > 0

				'fetch a list of watching family members
				local members:string[] = GetWatchingFamily( ShowChannel )
				'later: limit to amount of "places" on couch
				Local familyMembersUsed:int = members.length

				'slots if 3 members watch
				local figureSlots:int[]
				if familyMembersUsed >= 3 then figureSlots = [550, 610, 670]
				if familyMembersUsed = 2 then figureSlots = [580, 640]
				if familyMembersUsed = 1 then figureSlots = [610]

				'if nothing is displayed, a empty/dark room is shown
				'by default (on interface bg)
				'-> just care if family is watching
				if familyMembersUsed > 0
					GetSpriteFromRegistry("gfx_interface_audience_bg").Draw(520, GetGraphicsManager().GetHeight()-31, 0, ALIGN_LEFT_BOTTOM)
					local currentSlot:int = 0

					'unemployed always on the "most left slot"
					For local member:string = eachin members
						if member = "unemployed" or member = "unemployed.bored"
							figureSlots[0] = 540
							GetSpriteFromRegistry("gfx_interface_audience_"+member).Draw(figureslots[currentslot], GetGraphicsManager().GetHeight()-176)
							currentslot:+1 'occupy a slot
						endif
					Next

					For local member:string = eachin members
						'unemployed already handled
						if member = "unemployed" or member = "unemployed.bored" then continue
						'only X slots available
						if currentSlot >= figureSlots.length then continue

						GetSpriteFromRegistry("gfx_interface_audience_"+member).Draw(figureslots[currentslot], GetGraphicsManager().GetHeight()-176)
						currentslot:+1 'occupy a slot
					Next
					'draw the small electronic parts - "the inner tv"
					GetSpriteFromRegistry("gfx_interface_audience_overlay").Draw(520, GetGraphicsManager().GetHeight()-31, 0, ALIGN_LEFT_BOTTOM)
				endif
			EndIf 'showchannel <>0


			'=== INTERFACE TEXTS ===

			GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetPlayerBase().getMoneyFormatted(), 357, 412 +4, 130, 27, ALIGN_CENTER_TOP, TColor.Create(200,230,200), 2, 1, 0.5)

			GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetPlayerProgrammePlanCollection().Get(playerID).getFormattedAudience(), 357, 447+4, 130, 27, ALIGN_CENTER_TOP, TColor.Create(200,200,230), 2, 1, 0.5)

			'=== DRAW SECONDARY INFO ===
'			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha*0.75

			'current days financial win/loss
			local profit:int = GetPlayerFinance(playerID).GetCurrentProfit()
			if profit > 0
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock("+"+MathHelper.DottedValue(profit), 357, 412, 130, 32 - 2, ALIGN_CENTER_BOTTOM, TColor.Create(170,200,170), 2, 1, 0.5)
			elseif profit = 0
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock(0, 357, 412, 130, 32 - 2, ALIGN_CENTER_BOTTOM, TColor.Create(170,170,170), 2, 1, 0.5)
			else
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock(MathHelper.DottedValue(profit), 357, 412, 130, 32 - 2, ALIGN_CENTER_BOTTOM, TColor.Create(200,170,170), 2, 1, 0.5)
			endif

			'market share
			GetBitmapFont("Default", 12, BOLDFONT).drawBlock(MathHelper.NumberToString(GetPlayerProgrammePlan(playerID).GetAudiencePercentage()*100,2)+"%", 357, 447, 130, 32 - 2, ALIGN_CENTER_BOTTOM, TColor.Create(170,170,200), 2, 1, 0.5)

			'current day
		 	GetBitmapFont("Default", 12, BOLDFONT).drawBlock((GetWorldTime().GetDaysRun()+1) + ". "+GetLocale("DAY"), 357, 538, 130, 32 - 2, ALIGN_CENTER_BOTTOM, TColor.Create(180,180,180), 2, 1, 0.5)

			SetAlpha oldAlpha

			local bettyLove:Float = Min(Max(GetBetty().GetInLovePercentage( playerID ), 0.0),1.0)
			local bettyLoveText:String = MathHelper.NumberToString(bettyLove*100, 2)+"%"
			if bettyLove * 116 >= 1
				SetAlpha oldAlpha * 0.65
				SetColor 180,85,65
				DrawRect(364, 489, 116 * bettyLove, 12)
				Setcolor 255,255,255
				SetAlpha oldAlpha
			endif
		 	GetBitmapFont("Default", 12, BOLDFONT).drawBlock(bettyLoveText, 363, 488+1, 118, 14, ALIGN_CENTER_CENTER, TColor.Create(220,200,180), 2, 1, 0.5)


			local channelImage:Float = Min(Max(GetPublicImageCollection().Get( playerID ).GetAverageImage()/100.0, 0.0),1.0)
			local channelImageText:String = MathHelper.NumberToString(channelImage*100, 2)+"%"
			if channelImage * 120 >= 1
				SetAlpha oldAlpha * 0.65
				SetColor 150,170,65
				DrawRect(364, 517, 116 * channelImage, 12)
				Setcolor 255,255,255
				SetAlpha oldAlpha
			endif
		 	GetBitmapFont("Default", 12, BOLDFONT ).drawBlock(channelImageText, 363, 516+1, 118, 14, ALIGN_CENTER_CENTER, TColor.Create(200,220,180), 2, 1, 0.5)

			'DrawText(GetBetty().GetLoveSummary(),358, 535)
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND

		GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetWorldTime().getFormattedTime() + " "+GetLocale("OCLOCK"), 357, 538 + 4, 130, 27, ALIGN_CENTER_TOP, TColor.Create(220,220,220), 2, 1, 0.5)


		'=== DRAW HIGHLIGHTED CURRENT SPEED ===
		if GameRules.worldTimeSpeedPresets[0] = int(GetWorldTime().GetRawTimeFactor())
			GetSpriteFromRegistry("gfx_interface_button_speed1").Draw(400,577)
		elseif GameRules.worldTimeSpeedPresets[1] = int(GetWorldTime().GetRawTimeFactor())
			GetSpriteFromRegistry("gfx_interface_button_speed2").Draw(429,577)
		elseif GameRules.worldTimeSpeedPresets[2] = int(GetWorldTime().GetRawTimeFactor())
			GetSpriteFromRegistry("gfx_interface_button_speed3").Draw(457,577)
		endif


		'=== DRAW MENU BUTTON OVERLAYS ===
		if hoveredMenuButton > 0
			SetBlend LightBLEND
			SetAlpha 0.5
		endif

		Select hoveredMenuButton
			case 1
				GetSpriteFromRegistry("gfx_interface_button_settings").Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
			case 2
				GetSpriteFromRegistry("gfx_interface_button_help").Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
			case 3
				GetSpriteFromRegistry("gfx_interface_button_speed1").Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
			case 4
				GetSpriteFromRegistry("gfx_interface_button_speed2").Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
			case 5
				GetSpriteFromRegistry("gfx_interface_button_speed3").Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
		End Select

		if hoveredMenuButton > 0
			SetBlend ALPHABLEND
			SetAlpha oldAlpha
		endif

		'=== DRAW CHAT OVERLAY + ARROWS ===
		local arrowPos:int = 0
		local arrowDir:string = ""
		local arrowMode:string = "default"
		local lockMode:string = "unlocked"
		if ChatShowHideLocked then lockMode = "locked"
		if ChatContainsUnread then arrowMode = "highlight"

		if ChatShow
			GetSpriteFromRegistry("gfx_interface_ingamechat_bg").Draw(800, 600, -1, ALIGN_RIGHT_BOTTOM)
			arrowPos = 583
			arrowDir = "up"
		else
			arrowPos = 397
			arrowDir = "down"
		endif

		if THelper.MouseIn(540, arrowPos, 200, 20)
			arrowMode = "active"
		endif
		if THelper.MouseIn(770, arrowPos, 20, 20)
			lockMode = "active"
		endif

		'arrows
		GetSpriteFromRegistry("gfx_interface_ingamechat_arrow."+arrowDir+"."+arrowMode).Draw(540, arrowPos)
		GetSpriteFromRegistry("gfx_interface_ingamechat_arrow."+arrowDir+"."+arrowMode).Draw(720, arrowPos)
		'key
		GetSpriteFromRegistry("gfx_interface_ingamechat_key."+lockMode).Draw(770, arrowPos)
		'===


	    GUIManager.Draw(ingameState)

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Render()
		Next
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetInGameInterface:TInGameInterface()
	return TInGameInterface.GetInstance()
End Function




'extend tooltip to overwrite draw method
Type TTooltipAudience Extends TTooltip
	Field audienceResult:TAudienceResult
	Field showDetails:Int = False
	Field showDetailed:Int = False
	Field forceShow:Int = False
	Field lineHeight:Int = 0
	Field lineIconHeight:Int = 0
	Field originalPos:TVec2D

	Function Create:TTooltipAudience(title:String = "", text:String = "unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Local obj:TTooltipAudience = New TTooltipAudience
		obj.Initialize(title, text, x, y, w, h, lifetime)

		Return obj
	End Function


	'override to add lineheight
	Method Initialize:Int(title:String="", content:String="unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Super.Initialize(title, content, x, y, w, h, lifetime)
		if self.usefont
			Self.lineHeight = Self.useFont.getMaxCharHeight()+1
		endif
		'text line with icon
		Self.lineIconHeight = 1 + Max(lineHeight, GetSpriteFromRegistry("gfx_targetGroup_men").area.GetH())
	End Method


	Method SetAudienceResult:Int(audienceResult:TAudienceResult)
		If Self.audienceResult = audienceResult Then Return False

		Self.audienceResult = audienceResult
		Self.dirtyImage = True
	End Method


	Method GetContentInnerWidth:Int()
		If audienceResult
			Return Self.useFont.GetWidth( GetLocale("POTENTIAL_AUDIENCE_NUMBER") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(),0) + " (" + MathHelper.NumberToString(100.0 * audienceResult.GetPotentialMaxAudienceQuotePercentage(), 2) + "%)" )
		Else
			Return Self.Usefont.GetWidth( GetLocale("POTENTIAL_AUDIENCE_NUMBER") + ": 100 (100%)")
		EndIf
	End Method


	'override default to add "ALT-Key"-Switcher
	Method Update:Int()
		'hovered for more than 1.5 seconds and not fading out
		If _aliveTime > 1.5 and getFadeAmount() >= 1.0 then showDetailed = True


		If showDetailed
			If Not showDetails Then Self.dirtyImage = True
			showDetails = True
			'backup position
			If Not originalPos Then originalPos = area.position.Copy()

		Else
			If showDetails Then Self.dirtyImage = True
			showDetails = False
			'restore position
			If originalPos
				area.position.CopyFrom(originalPos)
				originalPos = Null
			EndIf
		EndIf

		Super.Update()
	End Method


	Method GetContentHeight:Int(width:Int)
		Local result:Int = 0

		Local reach:Int = GetStationMap( GetPlayerBase().playerID ).GetReach()
		Local totalReach:Int = GetStationMapCollection().population
		result:+ Usefont.GetHeight(GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 0) + " (" + MathHelper.NumberToString(100.0 * Float(reach)/totalReach, 2) + "% "+GetLocale("OF_THE_MAP")+")")
		result:+ Usefont.GetHeight(GetLocale("POTENTIAL_AUDIENCE_NUMBER") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(),0) + " (" + MathHelper.NumberToString(100.0 * audienceResult.GetPotentialMaxAudienceQuotePercentage(), 2) + "%)")
		result:+ 1*lineHeight

		If showDetails
			result:+ 9*lineIconHeight
			if CheckObservedFigureInRoom("adagency") or CheckObservedFigureInRoom("office")
				result :+ 1*lineIconHeight
			endif
		Else
			result:+ 1*lineHeight
		EndIf

		result:+ padding.GetTop() + padding.GetBottom()

		Return result
	End Method


	'override default
	Method DrawContent:Int(x:Int, y:Int, w:Int, h:Int)
		'give text padding
		x :+ padding.GetLeft()
		y :+ padding.GetTop()
		w :- (padding.GetLeft() + padding.GetRight())
		h :- (padding.GetTop() + padding.GetBottom())

		If Not Self.audienceResult
			Usefont.draw("Audience data missing", x, y)
			Return False
		EndIf


		Local lineY:Int = y
		Local lineX:Int = x
		Local lineText:String = ""
		Local lineIconX:Int = lineX + GetSpriteFromRegistry("gfx_targetGroup_men").area.GetW() + 2
		Local lineIconWidth:Int = w - GetSpriteFromRegistry("gfx_targetGroup_men").area.GetW()
		Local lineIconDY:Int = Floor(0.5 * (lineIconHeight - lineHeight))
		Local lineTextDY:Int = lineIconDY + 2

		'show how many people your stations cover (compared to country)
		Local reach:Int = GetStationMap( GetPlayerBase().playerID ).GetReach()
		Local totalReach:Int = GetStationMapCollection().population
		lineText = GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 0) + " (" + MathHelper.NumberToString(100.0 * Float(reach)/totalReach, 2) + "% "+GetLocale("OF_THE_MAP")+")"
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ Self.Usefont.GetHeight(lineText)

		'draw overview text
		lineText = GetLocale("POTENTIAL_AUDIENCE") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(),0) + " (" + MathHelper.NumberToString(100.0 * audienceResult.GetPotentialMaxAudienceQuotePercentage(), 2) + "%)"
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ 1 * Self.Usefont.GetHeight(lineText)

		rem
		local receptionAntenna:string = "Antenna " + MathHelper.NumberToString(100.0 * GameConfig.GetModifier("StationMap.Reception.AntennaMod", 1.0), 2, True)+"%"
		local receptionCableNetwork:string = "CableNetwork " + MathHelper.NumberToString(100.0 * GameConfig.GetModifier("StationMap.Reception.CableNetworkMod", 1.0), 2, True)+"%"
		local receptionSatellite:string = "Satellite " + MathHelper.NumberToString(100.0 * GameConfig.GetModifier("StationMap.Reception.SatelliteMod", 1.0), 2, True)+"%"
		lineText = GetLocale("RECEPTION") + ": " + receptionAntenna + " " + receptionCableNetwork + " " + receptionSatellite
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ Self.Usefont.GetHeight(lineText)
		endrem


		'add 1 line more - as spacing to details
		lineY :+ lineHeight

		if CheckObservedFigureInRoom("adagency") or CheckObservedFigureInRoom("office")
			if forceShow
				Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_RELEASE_TOOLTIP") , lineX, lineY, TColor.CreateGrey(150))
			else
				Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_FIX_TOOLTIP") , lineX, lineY, TColor.CreateGrey(150))
			endif

			'add 1 line more - as spacing to details
			lineY :+ lineHeight
		endif

'print audienceResult.ToString()
		If Not showDetails
			Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_SHOW_DETAILS") , lineX, lineY, TColor.CreateGrey(150))
		Else
			'add lines so we can have an easier "for loop"
			Local lines:String[TVTTargetGroup.count]
			Local percents:String[TVTTargetGroup.count]
			Local numbers:String[TVTTargetGroup.count]
			local genderlessQuote:TAudienceBase = audienceResult.GetGenderlessAudienceQuote()
			Local targetGroupID:Int = 0
			For Local i:Int = 1 To TVTTargetGroup.count
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				lines[i-1] = getLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)) + ": "
				numbers[i-1] = TFunctions.convertValue(audienceResult.Audience.GetTotalValue(targetGroupID), 0)

				if i = 8 or i = 9
					percents[i-1] = MathHelper.NumberToString(audienceResult.Audience.GetTotalValue(targetGroupID) / audienceResult.GetPotentialMaxAudience().GetTotalValue(targetGroupID) * 100, 2)
				else
					percents[i-1] = MathHelper.NumberToString(audienceResult.Audience.GetTotalValue(targetGroupID) / audienceResult.GetPotentialMaxAudience().GetTotalValue(targetGroupID) * 100, 2)
'					percents[i-1] = MathHelper.NumberToString(genderlessQuote.GetValue(targetGroupID) * 100, 2)
				endif
			Next

			Local colorLight:TColor = TColor.CreateGrey(240)
			Local colorDark:TColor = TColor.CreateGrey(230)
			Local colorTextLight:TColor = colorLight.copy().AdjustFactor(-110)
			Local colorTextDark:TColor = colorDark.copy().AdjustFactor(-140)

			For Local i:Int = 1 To TVTTargetGroup.count
				'shade the rows
				If i Mod 2 = 0 Then colorLight.SetRGB() Else colorDark.SetRGB()
				DrawRect(lineX, lineY, w, lineIconHeight)

				'draw icon
				SetColor 255,255,255
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				GetSpriteFromRegistry("gfx_targetGroup_"+TVTTargetGroup.GetAsString(targetGroupID).toLower()).draw(lineX, lineY + lineIconDY)
				'draw text
				If i Mod 2 = 0
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineTextDY,  w, lineHeight, Null, ColorTextLight)
					Usefont.drawBlock(numbers[i-1], lineIconX, lineY + lineTextDY, lineIconWidth - 5 - 50, lineIconHeight, New TVec2D.Init(ALIGN_RIGHT), ColorTextLight)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineTextDY, lineIconWidth - 5, lineIconHeight, New TVec2D.Init(ALIGN_RIGHT), ColorTextLight)
				Else
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineTextDY,  w, lineHeight, Null, ColorTextDark)
					Usefont.drawBlock(numbers[i-1], lineIconX, lineY + lineTextDY, lineIconWidth - 5 - 50, lineIconHeight, New TVec2D.Init(ALIGN_RIGHT), ColorTextDark)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineTextDY, lineIconWidth - 5, lineIconHeight, New TVec2D.Init(ALIGN_RIGHT), ColorTextDark)
				EndIf

				lineY :+ lineIconHeight
			Next
		EndIf
	End Method
End Type




Function CheckObservedFigureInRoom:int(roomName:string, allowChangingRoom:int = true)
	local figure:TFigure = TFigure(GameConfig.GetObservedObject())
	'when not observing someone, fall back to the players figure
	if not figure then figure = TFigure(GetPlayerBase().GetFigure())
	if not figure then return False

	'check if we are in the correct room
	If not allowChangingRoom and figure.isChangingRoom() Then Return False
	If not figure.inRoom Then Return False
	if figure.inRoom.GetName() <> roomName then return FALSE
	return TRUE
End Function
