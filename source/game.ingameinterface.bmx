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
	Field spriteProgrammeNews:TSprite
	Field spriteProgrammeNone:TSprite
	Field spriteProgrammeAdsNone:TSprite
	Field spriteProgrammeTrailerOverlay:TSprite
	Field spriteProgrammeAds:TSprite
	Field spriteProgrammeInfomercialOverlay:TSprite
	Field spriteInterfaceBottom:TSprite
	Field spriteInterfaceAudienceBG:TSprite
	Field spriteInterfaceAudienceOverlay:TSprite
	Field spriteInterfaceButtonSpeed1:TSprite
	Field spriteInterfaceButtonSpeed2:TSprite
	Field spriteInterfaceButtonSpeed3:TSprite
	Field spriteInterfaceButtonHelp:TSprite
	Field spriteInterfaceButtonSettings:TSprite
	Field _interfaceFont:TBitmapFont
	Field _interfaceBigFont:TBitmapFont
	Field moneyColor:SColor8
	Field audienceColor:SColor8
	Field bettyLovecolor:SColor8
	Field channelImageColor:SColor8
	Field currentDaycolor:SColor8
	Field marketShareColor:SColor8
	Field negativeProfitColor:SColor8
	Field neutralProfitColor:SColor8
	Field positiveProfitColor:SColor8
	Field noiseAlpha:Float	= 0.95
	Field noiseDisplace:Trectangle = new TRectangle
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field ChatShow:int = False
	Field ChatContainsUnread:int = False
	Field ChatShowHideLocked:int = False
	Field hoveredMenuButton:int = 0
	Field hoveredMenuButtonPos:TVec2D = new TVec2D.Init(0,0)
	'did text values change?
	Field valuesChanged:int = True

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

			chat.guiList.SetSize(chat.guiList.rect.GetW(), chat.guiList.rect.GetH()-10)

			'reposition input
			chat.guiInput.rect.position.setXY( 515, 354 )
			chat.guiInput.SetSize( 280, 30 )
			chat.guiInput.setMaxLength(200)
			chat.guiInput.setOption(GUI_OBJECT_POSITIONABSOLUTE, True)
			chat.guiInput.SetMaxTextWidth(255)
			chat.guiInput.spriteName = "gfx_interface_ingamechat_input"
			chat.guiInput.color = SColor8AdjustFactor(chat.guiInput.color, 30)
			chat.guiInput.SetValueDisplacement(3,3)
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
		spriteProgrammeNone = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
		spriteProgrammeAdsNone = GetSpriteFromRegistry("gfx_interface_tv_programme_ads_none")
		spriteProgrammeNews = GetSpriteFromRegistry("gfx_interface_tv_programme_news")
		spriteProgrammeTrailerOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_traileroverlay")
		spriteProgrammeAds = GetSpriteFromRegistry("gfx_interface_tv_programme_ads")
		spriteProgrammeInfomercialOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_infomercialoverlay")

		spriteInterfaceBottom = GetSpriteFromRegistry("gfx_interface_bottom")
		spriteInterfaceButtonSpeed1 = GetSpriteFromRegistry("gfx_interface_button_speed1")
		spriteInterfaceButtonSpeed2 = GetSpriteFromRegistry("gfx_interface_button_speed2")
		spriteInterfaceButtonSpeed3 = GetSpriteFromRegistry("gfx_interface_button_speed3")
		spriteInterfaceButtonHelp = GetSpriteFromRegistry("gfx_interface_button_help")
		spriteInterfaceButtonSettings = GetSpriteFromRegistry("gfx_interface_button_settings")
		spriteInterfaceAudienceBG = GetSpriteFromRegistry("gfx_interface_audience_bg")
		spriteInterfaceAudienceOverlay = GetSpriteFromRegistry("gfx_interface_audience_overlay")

		_interfaceFont = GetBitmapFont("Default", 12, BOLDFONT)
		_interfaceBigFont = GetBitmapFont("Default", 16, BOLDFONT)

		moneyColor = new SColor8(200,230,200)
		audienceColor = new SColor8(200,200,230)
		bettyLovecolor = new SColor8(220,200,180)
		channelImageColor = new SColor8(200,220,180)
		currentDaycolor = new SColor8(180,180,180)
		marketShareColor = new SColor8(170,170,200)
		negativeProfitColor = new SColor8(200,170,170)
		neutralProfitColor = new SColor8(170,170,170)
		positiveProfitColor = new SColor8(170,200,170)

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
		EventManager.registerListenerFunction(GameEventKeys.Chat_onAddEntry, onIngameChatAddEntry )
		'invalidate audience tooltip's "audienceresult" on recalculation
		EventManager.registerListenerFunction(GameEventKeys.StationMap_OnRecalculateAudienceSum, onStationMapRecalculateAudienceSum )

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
			If MOUSEMANAGER.IsClicked(1)
				For Local i:Int = 0 To 4
					If THelper.MouseIn( 75 + i * 33, 171 + 383 + 16 - i*4, 33, 25)
						ShowChannel = i

						'handled left click
						MouseManager.SetClickHandled(1)
						exit
					EndIf
				Next
			EndIf


			'reset current programme sprites
			CurrentProgrammeOverlay = Null
			CurrentProgramme = Null

			if programmePlan	'similar to "ShowChannel<>0"
				If GetWorldTime().GetDayMinute() >= 55
					Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
					If obj
						CurrentProgramme = spriteProgrammeAds
						'real ad
						If TAdvertisement(obj)
							CurrentProgrammeToolTip.TitleBGtype = 1
							CurrentProgrammeText = GetLocale("ADVERTISMENT") + ": " + obj.GetTitle()
						Else
							If(TProgramme(obj))
								CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_genre_" + TVTProgrammeGenre.GetAsString(TProgramme(obj).data.GetGenre()), "gfx_interface_tv_programme_none")
							EndIf
							CurrentProgrammeOverlay = spriteProgrammeTrailerOverlay
							CurrentProgrammeToolTip.TitleBGtype = 1
							CurrentProgrammeText = GetLocale("TRAILER") + ": " + obj.GetTitle()
						EndIf
					Else
						CurrentProgramme = spriteProgrammeAdsNone

						CurrentProgrammeToolTip.TitleBGtype	= 2
						CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
					EndIf
				ElseIf GetWorldTime().GetDayMinute() < 5
					CurrentProgramme = spriteProgrammeNews
					CurrentProgrammeToolTip.TitleBGtype	= 3
					CurrentProgrammeText = getLocale("NEWS")
				Else
					Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
					If obj
						CurrentProgramme = spriteProgrammeNone
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
							CurrentProgramme = spriteProgrammeAds
							CurrentProgrammeOverlay = spriteProgrammeInfomercialOverlay
							CurrentProgrammeText = GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						ElseIf TNews(obj)
							CurrentProgrammeText = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						EndIf
					Else
						CurrentProgramme = spriteProgrammeNone
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
					Local adMinAudience:Int = -1
					'fetch advertisement requirement to display enough
					'audience digits if minAudience is almost equal to
					'actual audience
					If GetWorldTime().GetDayMinute() >= 5 And GetWorldTime().GetDayMinute() < 55
						Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
						If TAdvertisement(obj)
							adMinAudience = TAdvertisement(obj).contract.getMinAudience()
						EndIf
					EndIf


					Local audience:Int = -1
					Local audienceStr:String = "0"
					Local audiencePercentageStr:String = "0"
					Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( programmePlan.owner )
					If audienceResult 
						audience = audienceResult.audience.GetTotalSum()
						If adMinAudience >= 0
							audienceStr = TFunctions.ConvertCompareValue(audience, adMinAudience, 2)
						Else
							audienceStr = TFunctions.ConvertValue(audience, 2)
						EndIf
						audiencePercentageStr = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage() * 100, 2)
					EndIf

					content	= GetLocale("AUDIENCE_NUMBER")+": "+ audienceStr + " (" + audiencePercentageStr + " %)"


					'Newsshow details
					If GetWorldTime().GetDayMinute() < 5
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
									Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(programmePlan.owner)
									local minAudienceText:string
									If audience >= 0
										minAudienceText = TFunctions.ConvertCompareValue(TAdvertisement(obj).contract.getMinAudience(), audience, 2)
									Else
										minAudienceText = TFunctions.ConvertValue(TAdvertisement(obj).contract.getMinAudience(), 2)
									Endif
									if TAdvertisement(obj).contract.GetLimitedToTargetGroup() > 0
										minAudienceText :+ " " + TAdvertisement(obj).contract.GetLimitedToTargetGroupString()
									endif

									'check if the ad passes all checks for the current broadcast
									local passingRequirements:String = TAdvertisement(obj).IsPassingRequirements(audienceResult)
									Select passingRequirements
										case "OK"
											minAudienceText = "|color=100,200,100|" + minAudienceText + "|/color|"
										case "TARGETGROUP"
											'tg already added above (for OK and WILL FAIL)
											minAudienceText = "|color=200,100,100|" + minAudienceText + "!|/color|"
										case "GENRE"
											minAudienceText = "|color=200,100,100|" + minAudienceText + " " + TAdvertisement(obj).contract.GetLimitedToProgrammeGenreString()+ "!|/color|"
										default
											minAudienceText = "|color=200,100,100|" + minAudienceText + "|/color|"
									End Select

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
					Local audienceStr:String = "0"
					Local audiencePercentageStr:String = "0"
					Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( GetPlayerBaseCollection().playerID )
					If audienceResult 
						audienceStr = TFunctions.convertValue(audienceResult.audience.GetTotalSum(), 2)
						audiencePercentageStr = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage() * 100, 2)
					EndIf
					CurrentAudienceToolTip.SetTitle(GetLocale("AUDIENCE_NUMBER")+": " + audienceStr + " (" + audiencePercentageStr +" %)")
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
				CurrentTimeToolTip.SetTitle(getLocale("GAME_TIME")+": " + GetWorldTime().GetFormattedTime())
				local content:string = ""
				content :+ "|b|"+GetLocale("GAMEDAY")+":|/b| "+(GetWorldTime().GetDaysRun()+1) + " (" + GetLocale("WEEK_LONG_"+GetWorldTime().GetDayName(GetWorldTime().GetWeekday())) + ")"
				content :+ "~n"
				content :+ "|b|"+GetLocale("DAY_OF_YEAR")+":|/b| "+GetWorldTime().getDayOfYear()+"/"+GetWorldTime().GetDaysPerYear()
				content :+ "~n"
				content :+ "|b|"+GetLocale("DATE")+":|/b| "+GetWorldTime().GetFormattedDate(GameConfig.dateFormat)+" ("+GetLocale("SEASON_"+GetWorldTime().GetSeasonName())+")"
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

					'handled left click
					MouseManager.SetClickHandled(1)
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
					IngameHelpWindowCollection.openHelpWindow()

					'handled left click
					MouseManager.SetClickHandled(1)
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

					'handled left click
					MouseManager.SetClickHandled(1)
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

					'handled left click
					MouseManager.SetClickHandled(1)
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

					'handled left click
					MouseManager.SetClickHandled(1)
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

				'handled left click
				MouseManager.SetClickHandled(1)
			endif
			'lock area
			if MouseManager.IsClicked(1) and THelper.MouseIn(770, 397, 20, 20)
				ChatShowHideLocked = 1- ChatShowHideLocked

				'handled left click
				MouseManager.SetClickHandled(1)
			endif
		else
			'arrow area
			if MouseManager.IsClicked(1) and THelper.MouseIn(540, 583, 200, 17)
				'reset unread
				ChatContainsUnread = False

				ChatShow = False
				if chat then chat.HideChat()

				'handled left click
				MouseManager.SetClickHandled(1)
			endif
			'lock area
			if MouseManager.IsClicked(1) and THelper.MouseIn(770, 583, 20, 20)
				ChatShowHideLocked = 1 - ChatShowHideLocked

				'handled left click
				MouseManager.SetClickHandled(1)
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

		if (feedback.AudienceInterest.GetTotalValue(TVTTargetGroup.Housewives) > 0) then result :+ ["mother"]

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
			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( GetPlayerBaseCollection().playerID )
			If audienceResult and audienceResult.GetAudienceQuotePercentage() > 0.05
				result :+ ["unemployed.bored"]
			endif
		endif

		if (feedback.AudienceInterest.GetTotalValue(TVTTargetGroup.Manager) > 0) then result :+ ["manager"]

		return result
	End Function


	'draws the interface
	Method Draw(tweenValue:Float=1.0)
		local oldAlpha:float = GetAlpha()

		local playerID:int = GetPlayerBase().playerID
		'channel choosen and something aired?
		local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan( ShowChannel )


		'=== INTERFACE ===

		'draw bottom, aligned "bottom"
		spriteInterfaceBottom.Draw(0, GetGraphicsManager().GetHeight(), 0, ALIGN_LEFT_BOTTOM)


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
			If noiseSprite Then noiseSprite.DrawClipped(45, 405, 220,170, noiseDisplace.GetX(), noiseDisplace.GetY())
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
				spriteInterfaceAudienceBG.Draw(520, GetGraphicsManager().GetHeight()-31, 0, ALIGN_LEFT_BOTTOM)
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
				spriteInterfaceAudienceOverlay.Draw(520, GetGraphicsManager().GetHeight()-31, 0, ALIGN_LEFT_BOTTOM)
			endif
		EndIf 'showchannel <>0


		'=== INTERFACE TEXTS ===

		_interfaceBigFont.DrawBox(GetPlayerBase().getMoneyFormatted(), 357, 413, 130, 32, sALIGN_CENTER_TOP, moneyColor, EDrawTextEffect.Shadow, 0.5)

		Local audienceStr:String = "0"
		Local audiencePercentageStr:String = "0"
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )
		If audienceResult 
			audienceStr = TFunctions.convertValue(audienceResult.audience.GetTotalSum(), 2)
			audiencePercentageStr = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage() * 100, 2)
		EndIf
		_interfaceBigFont.DrawBox(audienceStr, 357, 448, 130, 32, sALIGN_CENTER_TOP, audienceColor, EDrawTextEffect.Shadow, 0.5)


		'=== DRAW SECONDARY INFO ===
'			local oldAlpha:Float = GetAlpha()
		SetAlpha oldAlpha*0.75

		'current days financial win/loss
		local profit:int = GetPlayerFinance(playerID).GetCurrentProfit()
		if profit > 0
			_interfaceFont.DrawBox("+"+MathHelper.DottedValue(profit), 357, 413, 130, 32, sALIGN_CENTER_BOTTOM, positiveProfitColor, EDrawTextEffect.Shadow, 0.5)
		elseif profit = 0
			_interfaceFont.DrawBox(0, 357, 413, 130, 32, sALIGN_CENTER_BOTTOM, neutralProfitColor, EDrawTextEffect.Shadow, 0.5)
		else
			_interfaceFont.DrawBox(MathHelper.DottedValue(profit), 357, 413, 130, 32, sALIGN_CENTER_BOTTOM, negativeProfitColor, EDrawTextEffect.Shadow, 0.5)
		endif

		'market share
		_interfaceFont.DrawBox(audiencePercentageStr+" %", 357, 448, 130, 32, sALIGN_CENTER_BOTTOM, marketShareColor, EDrawTextEffect.Shadow, 0.5)

		'current day
		_interfaceFont.DrawBox((GetWorldTime().GetDaysRun()+1) + ". "+GetLocale("DAY"), 357, 539, 130, 32, sALIGN_CENTER_BOTTOM, currentDayColor, EDrawTextEffect.Shadow, 0.5)

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
		_interfaceFont.DrawBox(bettyLoveText, 363, 487, 118, 18, sALIGN_CENTER_CENTER, bettyLoveColor, EDrawTextEffect.Shadow, 0.5)

		local channelImage:Float = Min(Max(GetPublicImageCollection().Get( playerID ).GetAverageImage()/100.0, 0.0),1.0)
		local channelImageText:String = MathHelper.NumberToString(channelImage*100, 2)+"%"
		if channelImage * 120 >= 1
			SetAlpha oldAlpha * 0.65
			SetColor 150,170,65
			DrawRect(364, 517, 116 * channelImage, 12)
			Setcolor 255,255,255
			SetAlpha oldAlpha
		endif
		_interfaceFont.DrawBox(channelImageText, 363, 515, 118, 18, sALIGN_CENTER_CENTER, channelImageColor, EDrawTextEffect.Shadow, 0.5)

		'DrawText(GetBetty().GetLoveSummary(),358, 535)

		SetBlend ALPHABLEND

		_interfaceBigFont.DrawBox(GetWorldTime().getFormattedTime() + " "+GetLocale("OCLOCK"), 357, 539, 130, 32, sALIGN_CENTER_TOP, new SColor8(220,220,220), EDrawTextEffect.Shadow, 0.5)


		'=== DRAW HIGHLIGHTED CURRENT SPEED ===
		if GameRules.worldTimeSpeedPresets[0] = int(GetWorldTime().GetRawTimeFactor())
			spriteInterfaceButtonSpeed1.Draw(400,577)
		elseif GameRules.worldTimeSpeedPresets[1] = int(GetWorldTime().GetRawTimeFactor())
			spriteInterfaceButtonSpeed2.Draw(429,577)
		elseif GameRules.worldTimeSpeedPresets[2] = int(GetWorldTime().GetRawTimeFactor())
			spriteInterfaceButtonSpeed3.Draw(457,577)
		endif


		'=== DRAW MENU BUTTON OVERLAYS ===
		if hoveredMenuButton > 0
			SetBlend LightBLEND
			SetAlpha 0.5

			Select hoveredMenuButton
				case 1
					spriteInterfaceButtonSettings.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 2
					spriteInterfaceButtonHelp.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 3
					spriteInterfaceButtonSpeed1.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 4
					spriteInterfaceButtonSpeed2.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 5
					spriteInterfaceButtonSpeed3.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
			End Select

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


		'change mouse icon when hovering the "buttons"
		if not GetWorldTime().IsPaused()
			For Local i:Int = 0 To 4
				If THelper.MouseIn( 75 + i * 33, 171 + 383 + 16 - i*4, 33, 25)
					GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
					exit
				EndIf
			Next
		endif

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
	Field iconWidth:Int = 0
	Field iconHeight:Int = 0
	Field originalPos:TVec2D

	Function Create:TTooltipAudience(title:String = "", text:String = "unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Local obj:TTooltipAudience = New TTooltipAudience
		obj.Initialize(title, text, x, y, w, h, lifetime)

		Return obj
	End Function


	'override to add lineheight
	Method Initialize:Int(title:String="", content:String="unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Super.Initialize(title, content, x, y, w, h, lifetime)
		local lineTextHeight:Int = 14
		if self.usefont
'			Self.lineHeight = Self.useFont.getMaxCharHeight()+1
			lineTextHeight = Self.useFont.getMaxCharHeight()
		endif
		'text line with icon
		Self.iconHeight = GetSpriteFromRegistry("gfx_targetGroup_men").area.GetH()
		Self.iconWidth = GetSpriteFromRegistry("gfx_targetGroup_men").area.GetW()
		'add +1 to have "spacing"
		Self.lineHeight = max(lineTextHeight, iconHeight) + 1
	End Method


	Method SetAudienceResult:Int(audienceResult:TAudienceResult)
		If Self.audienceResult = audienceResult Then Return False

		Self.audienceResult = audienceResult
		Self.dirtyImage = True
	End Method


	Method GetContentInnerWidth:Int()
		If audienceResult
			Return Self.useFont.GetWidth( GetLocale("POTENTIAL_AUDIENCE_NUMBER") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(), 2, 0) + " (" + MathHelper.NumberToString(100.0 * audienceResult.GetPotentialMaxAudienceQuotePercentage(), 2) + "%)" )
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
		result:+ Usefont.GetHeight(GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 2, 0) + " (" + MathHelper.NumberToString(100.0 * Float(reach)/totalReach, 2) + "% "+GetLocale("OF_THE_MAP")+")")
		result:+ Usefont.GetHeight(GetLocale("POTENTIAL_AUDIENCE_NUMBER") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(),2, 0) + " (" + MathHelper.NumberToString(100.0 * audienceResult.GetPotentialMaxAudienceQuotePercentage(), 2) + "%)")
		result:+ 1*lineHeight

		If showDetails
			result:+ 9*lineHeight
			if CheckObservedFigureInRoom("adagency") or CheckObservedFigureInRoom("office")
				result:+ 1*lineHeight
			endif
		Else
			result:+ 1*lineHeight
		EndIf

		result:+ contentPadding.GetTop() + contentPadding.GetBottom()

		Return result
	End Method


	'override default
	Method DrawContent:Int(x:Int, y:Int, w:Int, h:Int)
		'give text padding
		x :+ contentPadding.GetLeft()
		y :+ contentPadding.GetTop()
		w :- (contentPadding.GetLeft() + contentPadding.GetRight())
		h :- (contentPadding.GetTop() + contentPadding.GetBottom())

		If Not Self.audienceResult
			Usefont.DrawSimple("Audience data missing", x, y)
			Return False
		EndIf


		Local lineY:Int = y
		Local lineX:Int = x
		Local lineText:String = ""
		Local lineTextX:Int = lineX + iconWidth + 5
		Local lineTextWidth:Int = w - (iconWidth + 5)
		Local lineIconOffsetY:Int = Floor(0.5 * (lineHeight - iconHeight))
'		Local lineTextOffsetY:Int = Floor(0.5 * (lineHeight - lineTextHeight)) 'lineIconDY + 2
		Local col1:SColor8 = new SColor8(90,90,90)
		Local col2:SColor8 = new SColor8(150,150,150)

		'show how many people your stations cover (compared to country)
		Local reach:Int = GetStationMap( GetPlayerBase().playerID ).GetReach()
		Local totalReach:Int = GetStationMapCollection().population
		lineText = GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 2, 0) + " (" + MathHelper.NumberToString(100.0 * Float(reach)/totalReach, 2) + "% "+GetLocale("OF_THE_MAP")+")"
		Self.Usefont.DrawSimple(lineText, lineX, lineY, col1)
		lineY :+ Self.Usefont.GetHeight(lineText)

		'draw overview text
		lineText = GetLocale("POTENTIAL_AUDIENCE") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(), 2, 0) + " (" + MathHelper.NumberToString(100.0 * audienceResult.GetPotentialMaxAudienceQuotePercentage(), 2) + "%)"
		Self.Usefont.DrawSimple(lineText, lineX, lineY, col1)
		lineY :+ 1 * Self.Usefont.GetHeight(lineText)

		rem
		local receptionAntenna:string = "Antenna " + MathHelper.NumberToString(100.0 * GameConfig.GetModifier(modKeyStationMap_Reception_AntennaMod, 1.0), 2, True)+"%"
		local receptionCableNetwork:string = "CableNetwork " + MathHelper.NumberToString(100.0 * GameConfig.GetModifier(modKeyStationMap_Reception_CableNetworkMod, 1.0), 2, True)+"%"
		local receptionSatellite:string = "Satellite " + MathHelper.NumberToString(100.0 * GameConfig.GetModifier(modKeyStationMap_Reception_SatelliteMod, 1.0), 2, True)+"%"
		lineText = GetLocale("RECEPTION") + ": " + receptionAntenna + " " + receptionCableNetwork + " " + receptionSatellite
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ Self.Usefont.GetHeight(lineText)
		endrem


		'add 1 line more - as spacing to details
		lineY :+ lineHeight

		if CheckObservedFigureInRoom("adagency") or CheckObservedFigureInRoom("office")
			if forceShow
				Self.Usefont.DrawSimple(GetLocale("HINT_PRESSING_ALT_WILL_RELEASE_TOOLTIP") , lineX, lineY, col2)
			else
				Self.Usefont.DrawSimple(GetLocale("HINT_PRESSING_ALT_WILL_FIX_TOOLTIP") , lineX, lineY, col2)
			endif

			'add 1 line more - as spacing to details
			lineY :+ lineHeight
		endif


		If Not showDetails
			Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_SHOW_DETAILS") , lineX, lineY, col2)
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
				numbers[i-1] = TFunctions.convertValue(audienceResult.Audience.GetTotalValue(targetGroupID), 2, 0)

				if i = 8 or i = 9
					percents[i-1] = MathHelper.NumberToString(audienceResult.Audience.GetTotalValue(targetGroupID) / audienceResult.GetPotentialMaxAudience().GetTotalValue(targetGroupID) * 100, 2)
				else
					percents[i-1] = MathHelper.NumberToString(audienceResult.Audience.GetTotalValue(targetGroupID) / audienceResult.GetPotentialMaxAudience().GetTotalValue(targetGroupID) * 100, 2)
'					percents[i-1] = MathHelper.NumberToString(genderlessQuote.GetValue(targetGroupID) * 100, 2)
				endif
			Next

			Local colorLight:SColor8 = new SColor8(240,240,240)
			Local colorDark:SColor8 = new SColor8(230,230,230)
			Local colorTextLight:SColor8 = SColor8AdjustFactor(colorLight, -110)
			Local colorTextDark:SColor8 = SColor8AdjustFactor(colorDark, -140)

			For Local i:Int = 1 To TVTTargetGroup.count
				'shade the rows
				If i Mod 2 = 0 Then SetColor(colorLight) Else SetColor(colorDark)
				DrawRect(lineX, lineY, w, lineHeight)
				SetColor 250,250,250
				DrawLine(lineX, lineY, lineX + w -1, lineY)
				SetColor 200,200,200
				DrawLine(lineX, lineY + lineHeight -1, lineX + w -1, lineY + lineHeight -1)

				'draw icon
				if i mod 2 = 0 then SetColor 170,170,170 else SetColor 150,150,150
				'icon is offset "in the image" already 1*1px
				DrawRect(lineX, lineY + lineIconOffsetY - 1, iconWidth+2, iconHeight+2)
				if i mod 2 = 0 then SetColor 130,130,130 else SetColor 100,100,100
				DrawRect(lineX+1, lineY + lineIconOffsetY - 1 +1, iconWidth+1, iconHeight+1)

				SetColor 255,255,255
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				GetSpriteFromRegistry("gfx_targetGroup_"+TVTTargetGroup.GetAsString(targetGroupID).toLower()).draw(lineX+1, lineY + lineIconOffsetY)
				'draw text
				If i Mod 2 = 0
					Usefont.DrawBox(lines[i-1], lineTextX, lineY,  w, lineHeight, sALIGN_LEFT_CENTER, ColorTextLight)
					Usefont.DrawBox(numbers[i-1], lineTextX, lineY, lineTextWidth - 5 - 50, lineHeight, sALIGN_RIGHT_CENTER, ColorTextLight)
					Usefont.DrawBox(percents[i-1]+"%", lineTextX, lineY, lineTextWidth - 5, lineHeight, sALIGN_RIGHT_CENTER, ColorTextLight)
				Else
					Usefont.DrawBox(lines[i-1], lineTextX, lineY,  w, lineHeight, sALIGN_LEFT_CENTER, ColorTextDark)
					Usefont.DrawBox(numbers[i-1], lineTextX, lineY, lineTextWidth - 5 - 50, lineHeight, sALIGN_RIGHT_CENTER, ColorTextDark)
					Usefont.DrawBox(percents[i-1]+"%", lineTextX, lineY, lineTextWidth - 5, lineHeight, sALIGN_RIGHT_CENTER, ColorTextDark)
				EndIf

				lineY :+ lineHeight
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
