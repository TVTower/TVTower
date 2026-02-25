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
	Field spriteInterfaceAudienceOffBG:TSprite
	Field spriteInterfaceAudienceOnBG:TSprite
	Field spriteInterfaceAudienceTVOverlay:TSprite
	Field spriteInterfaceAudienceAreaOverlay:TSprite
	Field spriteInterfaceButtonSpeed1_active:TSprite
	Field spriteInterfaceButtonSpeed2_active:TSprite
	Field spriteInterfaceButtonSpeed3_active:TSprite
	Field spriteInterfaceButtonSpeed1_hover:TSprite
	Field spriteInterfaceButtonSpeed2_hover:TSprite
	Field spriteInterfaceButtonSpeed3_hover:TSprite
	Field spriteInterfaceButtonHelp_hover:TSprite
	Field spriteInterfaceButtonSettings_hover:TSprite
	Field _interfaceFont:TBitmapFont
	Field _interfaceAudienceFont:TBitmapFont
	Field _interfaceBigFont:TBitmapFont
	Field _interfaceTVfamily:TWatchingFamily
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
	Field noiseDisplace:TRectangle = new TRectangle
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field LastShowChannel:Byte = 0
	Field ChatWindowMode:Int = 0 '0=TV-Family, 1=Chat, 2=Audience Distribution
	Field ChatContainsUnread:int = False
	Field ChatShowHideLocked:int = False
	Field hoveredMenuButton:int = 0
	Field hoveredMenuButtonPos:TVec2D = new TVec2D(0,0)
	'did text values change?
	Field valuesChanged:int = True
	Field customImageDirExists:Int = False

	Field chat:TGUIGameChat

	Global _instance:TInGameInterface
	Global keyLS_DevKeys:TLowerString = New TLowerString.Create("DEV_KEYS")

	Field ingameState:TLowerString = TLowerString.Create("InGame")

	Function GetInstance:TInGameInterface()
		if not _instance then _instance = new TInGameInterface.Init()
		return _instance
	End Function


	'initializes an interface
	Method Init:TInGameInterface()
		if not chat
			'TLogger.Log("TGame", "Creating ingame GUIelements", LOG_DEBUG)
			chat = New TGUIGameChat.Create(New SVec2I(515, 414), New SVec2I(278,180), "InGame")
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
			chat.guiInput.rect.SetXY( 515, 354 )
			chat.guiInput.SetSize( 280, 30 )
			chat.guiInput.setMaxLength(200)
			chat.guiInput.setOption(GUI_OBJECT_POSITIONABSOLUTE, True)
			chat.guiInput.SetMaxTextWidth(255)
			chat.guiInput.SetSpriteName("gfx_interface_ingamechat_input")
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
		spriteInterfaceButtonSpeed1_hover = GetSpriteFromRegistry("gfx_interface_button_speed1.hover")
		spriteInterfaceButtonSpeed2_hover = GetSpriteFromRegistry("gfx_interface_button_speed2.hover")
		spriteInterfaceButtonSpeed3_hover = GetSpriteFromRegistry("gfx_interface_button_speed3.hover")
		spriteInterfaceButtonHelp_hover = GetSpriteFromRegistry("gfx_interface_button_help.hover")
		spriteInterfaceButtonSettings_hover = GetSpriteFromRegistry("gfx_interface_button_settings.hover")
		spriteInterfaceButtonSpeed1_active = GetSpriteFromRegistry("gfx_interface_button_speed1.active")
		spriteInterfaceButtonSpeed2_active = GetSpriteFromRegistry("gfx_interface_button_speed2.active")
		spriteInterfaceButtonSpeed3_active = GetSpriteFromRegistry("gfx_interface_button_speed3.active")
		spriteInterfaceAudienceOffBG = GetSpriteFromRegistry("gfx_interface_audience_off_bg")
		spriteInterfaceAudienceOnBG = GetSpriteFromRegistry("gfx_interface_audience_on_bg")
		spriteInterfaceAudienceTVOverlay = GetSpriteFromRegistry("gfx_interface_audience_tv_overlay")
		spriteInterfaceAudienceAreaOverlay = GetSpriteFromRegistry("gfx_interface_audience_area_overlay")

		_interfaceFont = GetBitmapFont("Default", 10, BOLDFONT)
		_interfaceAudienceFont = GetBitmapFont("Default", 11)
		_interfaceBigFont = GetBitmapFont("Default", 14, BOLDFONT)
		_interfaceTVfamily = new TWatchingFamily().Init()

		If FileType("res/images") = FILETYPE_DIR
			customImageDirExists = True
		EndIf

		moneyColor = new SColor8(200,230,200)
		audienceColor = new SColor8(200,200,230)
		bettyLovecolor = new SColor8(220,200,180)
		channelImageColor = new SColor8(200,220,180)
		currentDaycolor = new SColor8(180,180,180, 200)
		marketShareColor = new SColor8(180,180,210, 200)
		negativeProfitColor = new SColor8(200,170,170, 200)
		neutralProfitColor = new SColor8(170,170,170, 200)
		positiveProfitColor = new SColor8(170,200,170, 200)

		'set space "left" when subtracting the genre image
		'so we know how many pixels we can move that image to simulate animation
		noiseDisplace.SetW(Max(0, noiseSprite.GetWidth() - tvOverlaySprite.GetWidth()))
		noiseDisplace.SetH(Max(0, noiseSprite.GetHeight() - tvOverlaySprite.GetHeight()))


		'=== SETUP SPAWNPOINTS FOR TOASTMESSAGES ===
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle(5,5, 395,300), new TVec2D(0, 0), "TOPLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle(400,5, 395,300), new TVec2D(1, 0), "TOPRIGHT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle(5,230, 395,50), new TVec2D(0, 1), "BOTTOMLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle(400,230, 395,50), new TVec2D(1, 1), "BOTTOMRIGHT" )


		'show chat if an chat entry was added
		EventManager.registerListenerFunction(GameEventKeys.Chat_onAddEntry, onIngameChatAddEntry )
		'invalidate audience tooltip's "audienceresult" on recalculation
		EventManager.registerListenerFunction(GameEventKeys.StationMap_OnRecalculateAudienceSum, onStationMapRecalculateAudienceSum )
		'reset chat when loading in an other game
		EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, OnLoadSaveGame)

		Return self
	End Method

	
	Function OnLoadSaveGame:Int( triggerEvent:TEventBase )
		GetInstance().CleanUp()
	End Function


	Function onIngameChatAddEntry:Int( triggerEvent:TEventBase )
		'ignore if not in a game
		If not GetGameBase().PlayingAGame() then return False

		'mark that there is something to read
		GetInstance().ChatContainsUnread = True

		'if user did not lock the current view
		If not GetInstance().ChatShowHideLocked
			GetInstance().ChatWindowMode = 1
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


	Method CleanUp()
		If chat
			'clear chat
			chat.Clear()

			ChatContainsUnread = False
		EndIf
		If Not _interfaceTVfamily Then _interfaceTVfamily = New TWatchingFamily().Init()
	End Method

	Method getCustomSprite:TSprite(obj:TBroadcastMaterial)
		If customImageDirExists
			Local image:TImage
			If TProgramme(obj)
				Local programme:TProgramme = TProgramme(obj)
				If programme.licence
					If Not programme.licence.data.customImagePresent
						image = getImage(programme.licence.data.GUID)
						'episode head
						If Not image And programme.licence.IsEpisode()
							image = getImage(programme.licence.GetParentLicence().data.GUID)
						EndIf
						'for custom production use template 
						If Not image And programme.licence.data.IsCustomProduction()
							If programme.licence.data.extra
								Local scriptId:Int = programme.licence.data.extra.GetInt("scriptID")
								If scriptId
									Local script:TScript= GetScriptCollection().GetById(scriptId)
									If script
										Local template:TScriptTemplate = GetScriptTemplateCollection().GetById(script.basedOnScriptTemplateID)
										If template
											image = getImage(template.GUID)
											'parent in case of episode
											If Not image And template.parentScriptID Then template = template.GetParentScript()
											If template Then image = getImage(template.GUID)
										EndIf
									EndIF
								EndIf
							EndIf
						EndIf
						If image
							programme.licence.data.customImagePresent = 1
							'TODO scaling
							programme.licence.data.customSprite = new TSprite.InitFromImage(image, programme.licence.data.GUID)
						Else
							programme.licence.data.customImagePresent = -1
						EndIf
					EndIf
					
					If programme.licence.data.customImagePresent > 0
						Return programme.licence.data.customSprite
					EndIf
				EndIf
			ElseIf TAdvertisement(obj)
				Local contract:TAdContract =  TAdvertisement(obj).contract
				If contract and contract.base
					If Not contract.base.customImagePresent
						image = getImage(contract.base.GUID)
						If image
							contract.base.customImagePresent = 1
							'TODO scaling
							contract.base.customSprite = new TSprite.InitFromImage(image, contract.base.GUID)
						Else
							contract.base.customImagePresent = -1
						EndIf
					EndIf
					If contract.base.customImagePresent > 0
						Return contract.base.customSprite
					EndIf
				EndIf
			EndIf
		EndIf
		Return Null

		Function getImage:TImage(guid:String)
			Local imagePath:String = "res/images/" + guid + ".png"
			Local image:TImage
			If FileType(imagePath) = FILETYPE_FILE
				image= LoadImage(imagePath, 0)
				If image Then return image
			EndIf
			imagePath:String = "res/images/" + guid + ".jpg"
			If FileType(imagePath) = FILETYPE_FILE
				image= LoadImage(imagePath, 0)
				If image Then return image
			EndIf
			Return Null
		EndFunction
	EndMethod

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
						If i = 0
							If ShowChannel = 0
								If LastShowChannel
									ShowChannel = LastShowChannel
								Else
									ShowChannel = GetCurrentPlayer().playerID
								EndIF
							Else
								LastShowChannel = ShowChannel
								ShowChannel = 0
							EndIf
						Else
							ShowChannel = i
						EndIf

						'handled left click
						MouseManager.SetClickHandled(1)
						exit
					EndIf
				Next
			EndIf


			'reset current programme sprites
			CurrentProgrammeOverlay = Null
			CurrentProgramme = Null
			Local contentPrefix:String = "~n"

			if programmePlan	'similar to "ShowChannel<>0"
				If GetWorldTime().GetDayMinute() >= 55
					Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
					CurrentProgramme = getCustomSprite(obj)
					_interfaceTVfamily.Update(ShowChannel, programmePlan.GetProgramme())
					If obj
						If Not CurrentProgramme Then CurrentProgramme = spriteProgrammeAds
						'real ad
						If TAdvertisement(obj)
							CurrentProgrammeToolTip.TitleBGtype = 1
							CurrentProgrammeText = GetLocale("ADVERTISMENT") + ": " + obj.GetTitle()
						Else
							If Not CurrentProgramme And TProgramme(obj)
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
					'TODO custom sprite for news?
					CurrentProgramme = spriteProgrammeNews
					CurrentProgrammeToolTip.TitleBGtype	= 3
					CurrentProgrammeText = getLocale("NEWS")
					_interfaceTVfamily.Update(ShowChannel, programmePlan.GetNewsShow())
				Else
					Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
					CurrentProgramme = getCustomSprite(obj)
					_interfaceTVfamily.Update(ShowChannel, obj)
					If obj
						CurrentProgrammeToolTip.TitleBGtype	= 0
						'real programme
						If TProgramme(obj)
							Local programme:TProgramme = TProgramme(obj)
							contentPrefix = programme.licence.GetGenresLine() + "~n"
							If Not CurrentProgramme Then CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_genre_" + TVTProgrammeGenre.GetAsString(programme.data.GetGenre()), "gfx_interface_tv_programme_none")
							If (programme.IsSeriesEpisode() or programme.IsCollectionElement()) and programme.licence.parentLicenceGUID
								CurrentProgrammeText = programme.licence.GetParentLicence().GetTitle() + " ("+ programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
							Else
								CurrentProgrammeText = programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
							EndIf
						ElseIf TAdvertisement(obj)
							If Not CurrentProgramme Then CurrentProgramme = spriteProgrammeAds
							CurrentProgrammeOverlay = spriteProgrammeInfomercialOverlay
							CurrentProgrammeText = GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						ElseIf TNews(obj)
							CurrentProgrammeText = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						EndIf
						If Not CurrentProgramme Then CurrentProgramme = spriteProgrammeNone
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
						audiencePercentageStr = TFunctions.LocalizedNumberToString(audienceResult.GetAudienceQuotePercentage() * 100, 2)
					EndIf

					content	= GetLocale("AUDIENCE")+": "+ audienceStr + " (" + audiencePercentageStr + "%)"


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
									Local contract:TAdContract = TAdvertisement(obj).contract
									If audience >= 0
										minAudienceText = TFunctions.ConvertCompareValue(contract.getMinAudience(), audience, 2)
									Else
										minAudienceText = TFunctions.ConvertValue(contract.getMinAudience(), 2)
									Endif
									if TAdvertisement(obj).contract.GetLimitedToTargetGroup() > 0
										minAudienceText :+ " " + contract.GetLimitedToTargetGroupString()
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
											minAudienceText = "|color=200,100,100|" + minAudienceText + " " + contract.GetLimitedToProgrammeGenreString()+ "!|/color|"
										case "FLAGS"
											minAudienceText = "|color=200,100,100|" + minAudienceText + " " + contract.GetProgrammeFlagString(contract.GetLimitedToProgrammeFlag())+ "!|/color|"
										case "FLAGSFORBIDDEN"
											minAudienceText = "|color=200,100,100|" + minAudienceText + " " + contract.GetProgrammeFlagString(contract.GetForbiddenProgrammeFlag())+ "!|/color|"
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

				CurrentProgrammeToolTip.SetContent(contentPrefix + content)
				CurrentProgrammeToolTip.enabled = 1
				CurrentProgrammeToolTip.Hover()
			EndIf
			If THelper.MouseIn(309,412,178,32)
				MoneyToolTip.SetTitle(getLocale("MONEY") + ": " + GetFormattedCurrency(GetPlayerBase().GetMoney()))
				local content:String = ""
				if GetPlayerBase().GetCredit() > 0
					content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=200,100,100|"+ GetFormattedCurrency(GetPlayerBase().GetCredit()) +"|/color|"
				else
					content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=0,200,100|" + GetFormattedCurrency(0)+"|/color|"
				endif

				local profit:long = GetPlayerFinance(GetPlayerBase().playerID).GetCurrentProfit()
				if profit > 0
					content	:+ "~n"
					content	:+ "|b|"+getLocale("FINANCES_TODAYS_INCOME")+":|/b| |color=100,200,100|+"+ GetFormattedCurrency(profit) +"|/color|"
				elseif profit = 0
					content	:+ "~n"
					content	:+ "|b|"+getLocale("FINANCES_TODAYS_INCOME")+":|/b| |color=100,100,100|" + GetFormattedCurrency(0)+"|/color|"
				else
					content	:+ "~n"
					content	:+ "|b|"+getLocale("FINANCES_TODAYS_INCOME")+":|/b| |color=200,100,100|"+ GetFormattedCurrency(profit) +"|/color|"
				endif

				MoneyTooltip.SetContent(content)
				MoneyToolTip.enabled 	= 1
				MoneyToolTip.Hover()
			EndIf
			If chatWindowMode <> 2 And (THelper.MouseIn(309,447,178,32) or CurrentAudienceToolTip.forceShow)
				local playerProgrammePlan:TPlayerProgrammePlan = GetPlayerProgrammePlan( GetPlayerBaseCollection().playerID )
				if playerProgrammePlan
					Local audienceStr:String = "0"
					Local audiencePercentageStr:String = "0"
					Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( GetPlayerBaseCollection().playerID )
					If audienceResult 
						audienceStr = TFunctions.convertValue(audienceResult.audience.GetTotalSum(), 2)
						audiencePercentageStr = TFunctions.LocalizedNumberToString(audienceResult.GetAudienceQuotePercentage() * 100, 2)
					EndIf
					CurrentAudienceToolTip.SetTitle(GetLocale("AUDIENCE")+": " + audienceStr + " (" + audiencePercentageStr +"%)")
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
						content :+ "|b|"+GetPlayerBase(i).channelname+": " + TFunctions.LocalizedNumberToString(channelImage*100, 2)+"%|/b|"
					else
						content :+ GetPlayerBase(i).channelname+": " + TFunctions.LocalizedNumberToString(channelImage*100, 2)+"%"
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
				'content :+ "|b|"+GetLocale("DATE")+":|/b| "+GetWorldTime().GetFormattedDate(GameConfig.dateFormat)+" ("+GetLocale("SEASON_"+GetWorldTime().GetSeasonName())+")"
				content :+ GetLocale("SEASON_"+GetWorldTime().GetSeasonName())+" "+ GetWorldTime().GetYear()
				CurrentTimeToolTip.SetContent(content)
				CurrentTimeToolTip.enabled = 1
				CurrentTimeToolTip.Hover()
				'force redraw
				CurrentTimeToolTip.dirtyImage = True
			EndIf
			If THelper.MouseIn(309,577,45,23)
				hoveredMenuButton = 1
				hoveredMenuButtonPos.SetXY(309,577)

				MenuToolTip.area.SetX(364)
				MenuToolTip.SetTitle(getLocale("MENU"))
				MenuToolTip.SetContent("[ESC] " + getLocale("OPEN_MENU"))
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					openEscapeMenuViaInterface = True

					'handled left click
					MouseManager.SetClickHandled(1)
				EndIf

			ElseIf THelper.MouseIn(357,577,43,23)
				hoveredMenuButton = 2
				hoveredMenuButtonPos.SetXY(357,577)

				MenuToolTip.area.SetX(410)
				MenuToolTip.SetTitle(getLocale("HELP"))
				MenuToolTip.SetContent("[F1] "+ getLocale("SHOW_HELP"))
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
				hoveredMenuButtonPos.SetXY(400,577)

				MenuToolTip.area.SetX(439)
				MenuToolTip.SetTitle(getLocale("GAMESPEED"))
				If GameRules.devConfig.GetBool(keyLS_DevKeys, False)
					MenuToolTip.SetContent(getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 1))
				Else
					MenuToolTip.SetContent("[1] "+getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 1))
				EndIf
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					GetGameBase().SetGameSpeedPreset(0)

					'handled left click
					MouseManager.SetClickHandled(1)
				EndIf

			ElseIf THelper.MouseIn(429,577,30,23)
				hoveredMenuButton = 4
				hoveredMenuButtonPos.SetXY(429,577)

				MenuToolTip.area.SetX(469)
				MenuToolTip.SetTitle(getLocale("GAMESPEED"))
				If GameRules.devConfig.GetBool(keyLS_DevKeys, False)
					MenuToolTip.SetContent(getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 2))
				Else
					MenuToolTip.SetContent("[2] " + getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 2))
				EndIf
				MenuToolTip.enabled = 1
				MenuToolTip.Hover()
				If MouseManager.IsClicked(1)
					GetGameBase().SetGameSpeedPreset(1)

					'handled left click
					MouseManager.SetClickHandled(1)
				EndIf

			ElseIf THelper.MouseIn(457,577,30,23)
				hoveredMenuButton = 5
				hoveredMenuButtonPos.SetXY(457,577)

				MenuToolTip.area.SetX(497)
				MenuToolTip.SetTitle(getLocale("GAMESPEED"))
				If GameRules.devConfig.GetBool(keyLS_DevKeys, False)
					MenuToolTip.SetContent(getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 3))
				Else
					MenuToolTip.SetContent("[3] "+ getLocale("SET_SPEED_TO_X").Replace("%SPEED%", 3))
				EndIf
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
		'arrow area
		if MouseManager.IsClicked(1) And THelper.MouseIn(537, 397, 215, 20)
			Local emptyChatFallback:Int = 2
			If THelper.MouseIn(537, 397, 25, 20)
				ChatWindowMode :- 1
				emptyChatFallback = 0
			ElseIf THelper.MouseIn(717, 397, 25, 20)
				ChatWindowMode :+ 1
			EndIf
			ChatWindowMode = (ChatWindowMode + 3)Mod 3
			'do not show chat if there are no chat entries
			If ChatWindowMode = 1 And chat And chat.guiList.entries.count() = 0 Then ChatWindowMode = emptyChatFallback
			'handled left click
			MouseManager.SetClickHandled(1)
		endif
		'lock area
		if MouseManager.IsClicked(1) and THelper.MouseIn(770, 397, 20, 20)
			ChatShowHideLocked = 1- ChatShowHideLocked
			'handled left click
			MouseManager.SetClickHandled(1)
		endif

		if chat and ChatWindowMode = 1
			chat.ShowChat()
			ChatContainsUnread = False
		else
			chat.HideChat()
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
				noiseDisplace.SetXY(Rand(0, int(noiseDisplace.w)),Rand(0, int(noiseDisplace.h)))
				ChangeNoiseTimer = 0.0
				NoiseAlpha = 0.45 - (Rand(0,20)*0.01)
			EndIf
		EndIf
	End Method





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
		If ChatWindowMode = 0
			If programmePlan and GetBroadcastManager().GetCurrentAudience(showChannel) > 0
				_interfaceTVfamily.Draw(True, spriteInterfaceAudienceOffBG, spriteInterfaceAudienceOnBG)
			'draw empty couch
			Else
				_interfaceTVfamily.Draw(False, spriteInterfaceAudienceOffBG, spriteInterfaceAudienceOnBG)
			EndIf 'showchannel <>0
			'draw the small electronic parts - "the inner tv"
			spriteInterfaceAudienceTVOverlay.Draw(515, 417, 0, ALIGN_LEFT_TOP)
		EndIf


		'=== INTERFACE TEXTS ===

		'player money / current days financial win/loss
		_interfaceBigFont.DrawBox(GetPlayerBase().getMoneyFormatted(), 357, 414, 130, 29, sALIGN_CENTER_TOP, moneyColor, EDrawTextEffect.Shadow, 0.5)
		local profit:long = GetPlayerFinance(playerID).GetCurrentProfit()
		if profit > 0
			_interfaceFont.DrawBox("+"+TFunctions.LocalizedDottedValue(profit), 357, 414, 130, 29, sALIGN_CENTER_BOTTOM, positiveProfitColor, EDrawTextEffect.Shadow, 0.5)
		elseif profit = 0
			_interfaceFont.DrawBox(0, 357, 414, 130, 29, sALIGN_CENTER_BOTTOM, neutralProfitColor, EDrawTextEffect.Shadow, 0.5)
		else
			_interfaceFont.DrawBox(TFunctions.LocalizedDottedValue(profit), 357, 414, 130, 29, sALIGN_CENTER_BOTTOM, negativeProfitColor, EDrawTextEffect.Shadow, 0.5)
		endif


		' audience / market share
		Local audienceStr:String = "0"
		Local audiencePercentageStr:String = "0"
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )
		If audienceResult 
			audienceStr = TFunctions.convertValue(audienceResult.audience.GetTotalSum(), 2)
			audiencePercentageStr = TFunctions.LocalizedNumberToString(audienceResult.GetAudienceQuotePercentage() * 100, 2)
		EndIf
		_interfaceBigFont.DrawBox(audienceStr, 357, 449, 130, 29, sALIGN_CENTER_TOP, audienceColor, EDrawTextEffect.Shadow, 0.5)
		_interfaceFont.DrawBox(audiencePercentageStr+"%", 357, 449, 130, 29, sALIGN_CENTER_BOTTOM, marketShareColor, EDrawTextEffect.Shadow, 0.5)


		' current time / day
		_interfaceBigFont.DrawBox(GetWorldTime().getFormattedTime() + " "+GetLocale("OCLOCK"), 357, 540, 130, 29, sALIGN_CENTER_TOP, new SColor8(220,220,220), EDrawTextEffect.Shadow, 0.5)
		_interfaceFont.DrawBox((GetWorldTime().GetDaysRun()+1) + ". "+GetLocale("DAY"), 357, 540, 130, 29, sALIGN_CENTER_BOTTOM, currentDayColor, EDrawTextEffect.Shadow, 0.5)
		

		' betty love bar / label
		local bettyLove:Float = Min(Max(GetBetty().GetInLovePercentage( playerID ), 0.0),1.0)
		local bettyLoveText:String = TFunctions.LocalizedNumberToString(bettyLove*100, 2)+"%"
		if bettyLove * 116 >= 1
			SetAlpha oldAlpha * 0.65
			SetColor 180,85,65
			DrawRect(364, 489, 116 * bettyLove, 12)
			Setcolor 255,255,255
			SetAlpha oldAlpha
		endif
		_interfaceFont.DrawBox(bettyLoveText, 363, 488-1, 118, 18, sALIGN_CENTER_CENTER, bettyLoveColor, EDrawTextEffect.Shadow, 0.5)
		

		' channel image bar / label
		local channelImage:Float = Min(Max(GetPublicImageCollection().Get( playerID ).GetAverageImage()/100.0, 0.0),1.0)
		local channelImageText:String = TFunctions.LocalizedNumberToString(channelImage*100, 2)+"%"
		if channelImage * 120 >= 1
			SetAlpha oldAlpha * 0.65
			SetColor 150,170,65
			DrawRect(364, 517, 116 * channelImage, 12)
			Setcolor 255,255,255
			SetAlpha oldAlpha
		endif
		_interfaceFont.DrawBox(channelImageText, 363, 516-1, 118, 18, sALIGN_CENTER_CENTER, channelImageColor, EDrawTextEffect.Shadow, 0.5)


		'DrawText(GetBetty().GetLoveSummary(),358, 535)


		'=== DRAW HIGHLIGHTED CURRENT SPEED ===
		if GameRules.worldTimeSpeedPresets[0] = int(GetWorldTime().GetRawTimeFactor())
			spriteInterfaceButtonSpeed1_active.Draw(400,577)
		elseif GameRules.worldTimeSpeedPresets[1] = int(GetWorldTime().GetRawTimeFactor())
			spriteInterfaceButtonSpeed2_active.Draw(429,577)
		elseif GameRules.worldTimeSpeedPresets[2] = int(GetWorldTime().GetRawTimeFactor())
			spriteInterfaceButtonSpeed3_active.Draw(457,577)
		endif


		'=== DRAW MENU BUTTON OVERLAYS ===
		if hoveredMenuButton > 0
			SetBlend LightBLEND
			SetAlpha 0.3

			Select hoveredMenuButton
				case 1
					spriteInterfaceButtonSettings_hover.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 2
					spriteInterfaceButtonHelp_hover.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 3
					spriteInterfaceButtonSpeed1_hover.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 4
					spriteInterfaceButtonSpeed2_hover.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
				case 5
					spriteInterfaceButtonSpeed3_hover.Draw(hoveredMenuButtonPos.GetIntX(), hoveredMenuButtonPos.GetIntY())
			End Select

			SetBlend ALPHABLEND
			SetAlpha oldAlpha
		endif

		'draw shadow over TV/Chat
		spriteInterfaceAudienceAreaOverlay.Draw(511, 412, 0, ALIGN_LEFT_TOP)

		'=== DRAW CHAT OVERLAY + ARROWS ===
		local arrowPos:int = 397

		'arrows
		GetSpriteFromRegistry("gfx_interface_ingamechat_arrow.up."+GetArrowHighlightMode(537, ChatContainsUnread)).Draw(540, arrowPos)
		GetSpriteFromRegistry("gfx_interface_ingamechat_arrow.down."+GetArrowHighlightMode(717, ChatContainsUnread)).Draw(720, arrowPos)

		'key
		local lockMode:string = "unlocked"
		if THelper.MouseIn(770, arrowPos, 20, 20)
			lockMode = "active"
		elseif ChatShowHideLocked
			lockMode = "locked"
		endif
		GetSpriteFromRegistry("gfx_interface_ingamechat_key."+lockMode).Draw(770, arrowPos)

		'=== DRAW AUDIENCE DETAILS
		If ChatWindowMode = 2
			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(playerID)
			Local iconWidth:Int=15
			Local iconHeight:Int=15
			Local w:Int=230
			Local lineheight:Int=15
			Local lineX:Int = 520
			Local lineY:Int = 420
			Local lineText:String = ""
			Local lineTextX:Int = lineX + iconWidth + 5
			Local lineTextWidth:Int = w - (iconWidth + 5)
			Local lineIconOffsetY:Int = Floor(0.5 * (lineHeight - iconHeight))
			Local lines:String[TVTTargetGroup.count]
			Local percents:String[TVTTargetGroup.count]
			Local numbers:String[TVTTargetGroup.count]
			Local targetGroupID:Int = 0
			Local colorLight:SColor8 = new SColor8(235,235,235)

	
			'show how many receivers your stations cover (compared to country)
			Local receivers:Int = GetStationMap( GetPlayerBase().playerID ).GetReceivers()
			Local receiversOnMap:Int = GetStationMapCollection().GetReceivers()
			lineText = GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(receivers, 2, 0) + " (" + TFunctions.LocalizedNumberToString(100.0 * Float(receivers)/receiversOnMap, 2) + "% "+GetLocale("OF_THE_MAP")+")"
			_interfaceAudienceFont.DrawSimple(lineText, lineX, lineY, colorLight)
			lineY :+ _interfaceAudienceFont.GetHeight(lineText)
	
			'draw overview text
			lineText = StringHelper.ucfirst(GetLocale("POTENTIAL_AUDIENCE")) + ": " + TFunctions.convertValue(audienceResult.PotentialAudience.GetTotalSum(), 2, 0) + " (" + TFunctions.LocalizedNumberToString(100.0 * audienceResult.GetPotentialAudienceQuotePercentage(), 2) + "%)"
			_interfaceAudienceFont.DrawSimple(lineText, lineX, lineY, colorLight)
			lineY :+ 1 * _interfaceAudienceFont.GetHeight(lineText) + 5

			For Local i:Int = 1 To TVTTargetGroup.count
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				Local col:SColor8 = GameConfig.GetTargetGroupColor(i)
				lines[i-1] = "|color="+col.r+","+col.g+","+col.b+"|"+Chr(9654)+"|/color| " + getLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)) + ": "
				numbers[i-1] = TFunctions.convertValue(audienceResult.Audience.GetTotalValue(targetGroupID), 2, 0)

				percents[i-1] = TFunctions.LocalizedNumberToString(audienceResult.Audience.GetTotalValue(targetGroupID) / audienceResult.GetPotentialAudience().GetTotalValue(targetGroupID) * 100, 2)
			Next

			Local colorDark:SColor8 = new SColor8(230,230,230)
			Local colorTextLight:SColor8 = SColor8AdjustFactor(colorLight, 0)
			Local colorTextDark:SColor8 = SColor8AdjustFactor(colorDark, -140)

			For Local i:Int = 1 To TVTTargetGroup.count
				SetColor 255,255,255
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				GetSpriteFromRegistry("gfx_targetGroup_"+TVTTargetGroup.GetAsString(targetGroupID)).draw(lineX+1, lineY + lineIconOffsetY)
				_interfaceAudienceFont.DrawBox(lines[i-1], lineTextX, lineY,  w, lineHeight + 2, sALIGN_LEFT_CENTER, ColorTextLight)
				_interfaceAudienceFont.DrawBox(numbers[i-1], lineTextX, lineY, lineTextWidth - 5 - 50, lineHeight + 2, sALIGN_RIGHT_CENTER, ColorTextLight)
				_interfaceAudienceFont.DrawBox(percents[i-1]+"%", lineTextX, lineY, lineTextWidth - 5, lineHeight + 2, sALIGN_RIGHT_CENTER, ColorTextLight)
				lineY :+ lineHeight
			Next
		EndIf


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

		Function GetArrowHighlightMode:String(offset:Int, chatContainsUnread:Int)
			If THelper.MouseIn(offset, 397, 25, 20)
				return "active"
			ElseIf chatContainsUnread
				return "highlight"
			Else
				return "default"
			EndIf
		End Function
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetInGameInterface:TInGameInterface()
	return TInGameInterface.GetInstance()
End Function


Type TWatchingFamily

	Field currentChannel:Int=0
	Field currentBroadCast:TBroadcastMaterial[4]
	Field watchingMembers:String[4][]
	Field couchPositions:Int[4][]
	Field employeeExists:Int = False

	Method Init:TWatchingFamily()
		If GetRegistry().contains("gfx_interface_audience_employee_male") Then employeeExists = True
		Return self
	End Method

	'determine family members currently watching TV
	Method Update(playerID:int = 0, material:TBroadCastMaterial)
		If playerID = 0 Then Return
		'use cached result if possible
		If currentChannel = playerID And material = currentBroadCast[playerID-1] Then Return

		local result:String[]
		local hour:Int=GetWorldTime().GetDayHour()

		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )
		local useSlots:Int = 0
		local childAllowed:Int = True
		If audienceResult
			'determine number of family members
			Local percentage:Float = audienceResult.GetAudienceQuotePercentage()
			If hour >= 10 and hour <=23
				If percentage >= 0.3
					useSlots = 3
				ElseIf percentage >= 0.2
					useSlots = 2
				ElseIf percentage >= 0.1
					useSlots = 1
				ElseIf percentage >= 0.05
					result = ["unemployed.bored"]
				EndIf
			Else
				If percentage >= 0.15
					useSlots = 2
				ElseIf percentage >= 0.07
					useSlots = 1
				ElseIf percentage >= 0.03
					result = ["unemployed.bored"]
				EndIf
			EndIf

			'TODO disallow manager during working hours?
			If hour <= 4 Or hour >= 22 Then childAllowed = False

			If useSlots > 0
				'sort target groups by audience quote
				Local map:TNumberSortMap = audienceResult.GetAudienceQuote().ToNumberSortMap()
				map.Sort(False)
				For Local entry:TKeyValueNumber = EachIn map.Content
					If result.length < useSlots
						Local group:Int = Int(entry.Key)
						Local suffix:String = "_male"
						'TODO if more gender versions exist, then use random gender unless the audience numbers differ a lot (60/40?)
						'in this case the broadcast licence id must be stored in order to use the same gender for later blocks!
						If audienceResult.audience.GetGenderValue(group, TVTPersonGender.FEMALE) > audienceResult.audience.GetGenderValue(group, TVTPersonGender.MALE) Then suffix="_female"
						Select group
							Case TVTTargetGroup.Children
								If Not childAllowed Then Continue
								result :+ ["child"+suffix]
							Case TVTTargetGroup.Teenagers
								result :+ ["teen"+suffix]
							Case TVTTargetGroup.HouseWives
								result :+ ["housewife"+suffix]
							Case TVTTargetGroup.Employees
								If Not employeeExists Then continue
								result :+ ["employee"+suffix]
								continue
							Case TVTTargetGroup.Unemployed
								result :+ ["unemployed"+suffix]
							Case TVTTargetGroup.Managers
								result :+ ["manager"+suffix]
							Case TVTTargetGroup.Pensioners
								result :+ ["pensioner"+suffix]
							Default
								Throw "unknown audience "+ entry.Key
						EndSelect
					EndIf
				Next
			EndIf
		EndIf

rem
		'add feedback to watching members
		'leaving original code for later reference
		Local feedback:TBroadcastFeedback = GetBroadcastManager().GetCurrentBroadcast().GetFeedback(playerID)

		if not feedback or not feedback.AudienceInterest
			print "Interface.GetWatchingFamily: no AudienceInterest!"
			debugstop
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
endrem

		_assignSpots(result, playerID-1)
		currentBroadCast[playerID-1] = material
		currentChannel = playerID
	End Method

	'assign couch seats
	Method _assignSpots(newViewers:String[], playerIndex:Int)
		Local oldMembers:String[] = watchingMembers[playerIndex]
		Local oldCouchPositions:Int[] = couchPositions[playerIndex]
		Local finalMembers:String[]
		Local familyMembersUsed:int = newViewers.length
		Local newCouchPositions:Int[] = new Int[newViewers.length]
		'default couch positions
		If familyMembersUsed >= 3 Then newCouchPositions = [550, 610, 670]
		If familyMembersUsed = 2 Then newCouchPositions = [580, 640]
		If familyMembersUsed = 1
			'prevent alternating of single viewers in center seat
			newCouchPositions = [610]
			If oldMembers.length = 1 And oldCouchPositions[0] = 610 Then newCouchPositions = [670]
		EndIf

		Local unemployedPresent:Int = False
		Local sameViewerExists:Int = False

		'unemployed always on the left
		For Local j:int=0 to newViewers.length-1
			If newViewers[j].StartsWith("unemployed")
				finalMembers:+ [newViewers[j]]
				newCouchPositions[0] = 540
				newViewers[j] = null
				unemployedPresent = True
			EndIf
		Next

		'leave order seats of already watching members unchanged if possible
		For Local i:int=0 to oldMembers.length-1
			For Local j:int=0 to newViewers.length-1
				Local oldPosition:Int = oldCouchPositions[i]
				If oldMembers[i] = newViewers[j]
					If unemployedPresent And oldPosition < 600
						'cannot stay in same position
					Else
						finalMembers:+ [newViewers[j]]
						newViewers[j] = null
						sameViewerExists = True
						If familyMembersUsed = 3 and ((oldPosition-580) mod 60) = 0
							'two-seat position but three needed - cannot stay in same position
						Else
							'stay in same position
							newCouchPositions[finalMembers.length-1] = oldPosition
						EndIf
					EndIf
				EndIf
			Next
		Next

		'at this point all prior viewers should have a non-overlapping spot
		'as the critical cases have not retained their old seats and were assigned default spots
		'add remaining (new) viewers
		For Local j:int=0 to newViewers.length-1
			If newViewers[j]
				finalMembers:+ [newViewers[j]]
				'default couch positions may only be invalid if there were prior viewers
				If sameViewerExists
					Local spot:Int = finalMembers.length-1 'spot 0 not possible, as there were prior viewers
					'check if default position is already occupied
					Local intendedPosition:Int = newCouchPositions[spot]
					If spot = 1
						'right or middle position - too little space - move to the left
						If abs(intendedPosition - newCouchPositions[spot-1]) < 60 Then newCouchPositions[spot] = newCouchPositions[spot-1] - 60 
					ElseIf spot = 2
						'three seats - use only one left
						If newCouchPositions[1] = intendedPosition Or newCouchPositions[0] = intendedPosition
							intendedPosition = intendedPosition - 60
							If newCouchPositions[1] = intendedPosition Or newCouchPositions[0] = intendedPosition Then intendedPosition = intendedPosition - 60
							newCouchPositions[spot] = intendedPosition
						EndIf
					EndIf
				EndIf
			EndIf
		Next

		watchingMembers[playerIndex] = finalMembers
		couchPositions[playerIndex] = newCouchPositions
	EndMethod
	

	Method HasWatchingMember:Int()
		If currentChannel < 1 Then Return False
		Return watchingMembers[currentChannel-1].length > 0
	End Method


	Method Draw(showFamily:Int, spriteInterfaceAudienceOffBG:TSprite, spriteInterfaceAudienceOnBG:TSprite)
		If Not showFamily Or currentChannel < 1
			'off-variant of couch
			spriteInterfaceAudienceOffBG.Draw(521, 419, 0, ALIGN_LEFT_TOP)
			Return
		EndIf

		'fetch a list of watching family members
		local members:string[] = watchingMembers[currentChannel-1]

		'slots if 3 members watch
		local figureSlots:int[] = couchPositions[currentChannel-1]

		'if nothing is displayed, a empty/dark room is shown
		if members.length = 0
			spriteInterfaceAudienceOffBG.Draw(521, 419, 0, ALIGN_LEFT_TOP)
		Elseif members.length > 0
			spriteInterfaceAudienceOnBG.Draw(521, 419, 0, ALIGN_LEFT_TOP)
			local currentSlot:int = 0
			For local member:string = eachin members
				'only X slots available
				if currentSlot >= figureSlots.length then continue

				GetSpriteFromRegistry("gfx_interface_audience_"+member).Draw(figureslots[currentslot], GetGraphicsManager().GetHeight()-176)
				currentslot:+1 'occupy a slot
			Next
		endif
	End Method
End Type



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
			Local reach:Int = GetStationMap( GetPlayerBase().playerID ).GetPopulation()
			Local totalReach:Int = GetStationMapCollection().GetPopulation()

			Return Max(5 + Self.useFont.GetWidth(GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 2, 0) + " (" + TFunctions.LocalizedNumberToString(100.0 * Float(reach)/totalReach, 2) + "% "+GetLocale("OF_THE_MAP")+")"), ..
                       Self.useFont.GetWidth(StringHelper.ucfirst(GetLocale("POTENTIAL_AUDIENCE")) + ": " + TFunctions.convertValue(audienceResult.PotentialAudience.GetTotalSum(), 2, 0) + " (" + TFunctions.LocalizedNumberToString(100.0 * audienceResult.GetPotentialAudienceQuotePercentage(), 2) + "%)" ) )
		Else
			Return Max(Self.Usefont.GetWidth(GetLocale("BROADCASTING_AREA") + ": 100 (100%)"), ..
			           Self.Usefont.GetWidth(StringHelper.ucfirst(GetLocale("POTENTIAL_AUDIENCE")) + ": 100 (100%)"))
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
			If Not originalPos Then originalPos = new TVec2D(area.x, area.y)

		Else
			If showDetails Then Self.dirtyImage = True
			showDetails = False
			'restore position
			If originalPos
				area.SetXY(originalPos)
				originalPos = Null
			EndIf
		EndIf

		Super.Update()
	End Method


	Method GetContentHeight:Int(width:Int)
		Local result:Int = 0

		Local reach:Int = GetStationMap( GetPlayerBase().playerID ).GetPopulation()
		Local totalReach:Int = GetStationMapCollection().GetPopulation()
		result:+ Usefont.GetHeight(GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 2, 0) + " (" + TFunctions.LocalizedNumberToString(100.0 * Float(reach)/totalReach, 2) + "% "+GetLocale("OF_THE_MAP")+")")
		result:+ Usefont.GetHeight(GetLocale("POTENTIAL_AUDIENCE") + ": " + TFunctions.convertValue(audienceResult.PotentialAudience.GetTotalSum(),2, 0) + " (" + TFunctions.LocalizedNumberToString(100.0 * audienceResult.GetPotentialAudienceQuotePercentage(), 2) + "%)")
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

		'show how many receivers your stations cover (compared to country)
		Local receivers:Int = GetStationMap( GetPlayerBase().playerID ).GetReceivers()
		Local receiversOnMap:Int = GetStationMapCollection().GetReceivers()
		Local currentLineHeight:Int
		currentLineHeight = Self.Usefont.DrawSimple(StringHelper.ucfirst(GetLocale("BROADCASTING_AREA")) + ": ", lineX, lineY, col1).y
		Self.UseFont.DrawBox(TFunctions.convertValue(receivers, 2, 0), lineX, lineY, iconWidth + lineTextWidth - 50, lineHeight+2, sALIGN_RIGHT_TOP, col1)
		Self.UseFont.DrawBox(TFunctions.LocalizedNumberToString(100.0 * Float(receivers)/receiversOnMap, 2) + "%", lineX, lineY, iconWidth + lineTextWidth, lineHeight+2, sALIGN_RIGHT_TOP, col1)
		lineY :+ currentLineHeight

		'draw overview text
		lineHeight = Self.Usefont.DrawSimple(StringHelper.ucfirst(GetLocale("POT_AUDIENCE")) + ": ", lineX, lineY, col1).y
		Self.UseFont.DrawBox(TFunctions.convertValue(audienceResult.GetPotentialAudience().GetTotalSum(), 2, 0), lineX, lineY, iconWidth + lineTextWidth - 50, lineHeight+2, sALIGN_RIGHT_TOP, col1)
		Self.UseFont.DrawBox(TFunctions.LocalizedNumberToString(100.0 * audienceResult.GetPotentialAudienceQuotePercentage()) + "%", lineX, lineY, iconWidth + lineTextWidth, lineHeight+2, sALIGN_RIGHT_TOP, col1)
		lineY :+ currentLineHeight

		rem
		local receptionAntenna:string = "Antenna " + TFunctions.LocalizedNumberToString(100.0 * GameConfig.GetModifier(modKeyStationMap_Reception_AntennaMod, 1.0), 2, True)+"%"
		local receptionCableNetwork:string = "CableNetwork " + TFunctions.LocalizedNumberToString(100.0 * GameConfig.GetModifier(modKeyStationMap_Reception_CableNetworkMod, 1.0), 2, True)+"%"
		local receptionSatellite:string = "Satellite " + TFunctions.LocalizedNumberToString(100.0 * GameConfig.GetModifier(modKeyStationMap_Reception_SatelliteMod, 1.0), 2, True)+"%"
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
			Local targetGroupID:Int = 0
			For Local i:Int = 1 To TVTTargetGroup.count
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				Local col:SColor8 = GameConfig.GetTargetGroupColor(i)
				lines[i-1] = "|color="+col.r+","+col.g+","+col.b+"|"+Chr(9654)+"|/color| " + getLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)) + ": "
				numbers[i-1] = TFunctions.convertValue(audienceResult.Audience.GetTotalValue(targetGroupID), 2, 0)

				percents[i-1] = TFunctions.LocalizedNumberToString(audienceResult.Audience.GetTotalValue(targetGroupID) / audienceResult.GetPotentialAudience().GetTotalValue(targetGroupID) * 100, 2)
			Next

			Local colorLight:SColor8 = new SColor8(240,240,240)
			Local colorDark:SColor8 = new SColor8(230,230,230)
			Local colorTextLight:SColor8 = SColor8AdjustFactor(colorLight, -110)
			Local colorTextDark:SColor8 = SColor8AdjustFactor(colorDark, -140)

			SetColor 200,200,200
			DrawRect(lineX-1, lineY-1, w+2, TVTTargetGroup.count * lineHeight + 1) 
			For Local i:Int = 1 To TVTTargetGroup.count
				'shade the rows
				If i Mod 2 = 0 Then SetColor(colorLight) Else SetColor(colorDark)
				DrawRect(lineX, lineY, w, lineHeight)
				SetColor 250,250,250
				DrawLine(lineX, lineY, lineX + w -1, lineY)
				SetColor 200,200,200
				DrawLine(lineX, lineY + lineHeight -1, lineX + w -1, lineY + lineHeight -1)

				SetColor 200,200,200
				DrawLine(lineX+1 + iconWidth + 1, lineY + 1, lineX+1 + iconWidth + 1, lineY + lineHeight - 2)
				SetColor 250,250,250
				DrawLine(lineX+1 + iconWidth + 2, lineY + 1, lineX+1 + iconWidth + 2, lineY + lineHeight - 2)

				SetColor 255,255,255
				targetGroupID = TVTTargetGroup.GetAtIndex(i)
				GetSpriteFromRegistry("gfx_targetGroup_"+TVTTargetGroup.GetAsString(targetGroupID)).draw(lineX+1, lineY + lineIconOffsetY)
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
