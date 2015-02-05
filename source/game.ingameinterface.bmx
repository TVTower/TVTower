
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
	Field CurrentTimeToolTip:TTooltip
	Field tooltips:TList = CreateList()
	Field noiseSprite:TSprite
	Field noiseAlpha:Float	= 0.95
	Field noiseDisplace:Trectangle = new TRectangle.Init(0,0,0,0)
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field ChatShow:int = False
	Field ChatContainsUnread:int = False
	Field ChatShowHideLocked:int = False
	Field BottomImgDirty:Int = 1

	Global _instance:TInGameInterface


	Function GetInstance:TInGameInterface()
		if not _instance then _instance = new TInGameInterface.Init()
		return _instance
	End Function


	'initializes an interface
	Method Init:TInGameInterface()
		CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")

		CurrentProgrammeToolTip = TTooltip.Create("", "", 40, 395)
		CurrentProgrammeToolTip.minContentWidth = 220

		CurrentAudienceToolTip = TTooltipAudience.Create("", "", 490, 440)
		CurrentAudienceToolTip.minContentWidth = 200

		CurrentTimeToolTip = TTooltip.Create("", "", 490, 535)
		MoneyToolTip = TTooltip.Create("", "", 490, 408)
		BettyToolTip = TTooltip.Create("", "", 490, 485)

		'collect them in one list (to sort them correctly)
		tooltips.AddLast(CurrentProgrammeToolTip)
		tooltips.AddLast(CurrentAudienceToolTip)
		tooltips.AddLast(CurrentTimeToolTip)
		tooltips.AddLast(MoneyTooltip)
		tooltips.AddLast(BettyToolTip)


		noiseSprite = GetSpriteFromRegistry("gfx_interface_tv_noise")
		'set space "left" when subtracting the genre image
		'so we know how many pixels we can move that image to simulate animation
		noiseDisplace.Dimension.SetX(Max(0, noiseSprite.GetWidth() - CurrentProgramme.GetWidth()))
		noiseDisplace.Dimension.SetY(Max(0, noiseSprite.GetHeight() - CurrentProgramme.GetHeight()))


		'=== SETUP SPAWNPOINTS FOR TOASTMESSAGES ===
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(5,5, 395,300), new TVec2D.Init(0,0), "TOPLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(400,5, 395,300), new TVec2D.Init(1,0), "TOPRIGHT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(5,230, 395,50), new TVec2D.Init(0,1), "BOTTOMLEFT" )
		GetToastMessageCollection().AddNewSpawnPoint( new TRectangle.Init(400,230, 395,50), new TVec2D.Init(1,1), "BOTTOMRIGHT" )


		'show chat if an chat entry was added
		EventManager.registerListenerFunction( "chat.onAddEntry", onIngameChatAddEntry )
		

		Return self
	End Method


	Function onIngameChatAddEntry:Int( triggerEvent:TEventBase )
		'ignore if not in a game
		If not Game.PlayingAGame() then return False

		'mark that there is something to read
		GetInstance().ChatContainsUnread = True

		'if user did not lock the current view
		If not GetInstance().ChatShowHideLocked
			GetInstance().ChatShow = True
		EndIf
	End Function
	

	Method Update(deltaTime:Float=1.0)
		local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(ShowChannel)

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
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_genre_" + TVTProgrammeGenre.GetGenreStringID(programme.data.GetGenre()), "gfx_interface_tv_programme_none")
						If programme.isSeries() and programme.licence.parentLicenceGUID
							CurrentProgrammeText = programme.licence.GetParentLicence().GetTitle() + " ("+ (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						Else
							CurrentProgrammeText = programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						EndIf
					ElseIf TAdvertisement(obj)
						CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_ads")
						CurrentProgrammeOverlay = GetSpriteFromRegistry("gfx_interface_tv_programme_infomercialoverlay")
						CurrentProgrammeText = GetLocale("INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
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

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Update()
		Next
		tooltips.Sort() 'sort according lifetime

		'channel selection (tvscreen on interface)
		If MOUSEMANAGER.IsHit(1)
			For Local i:Int = 0 To 4
				If THelper.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
					ShowChannel = i
					BottomImgDirty = True
				EndIf
			Next
		EndIf


		'skip adjusting the noise if the tv is off
		If programmePlan
			'noise on interface-tvscreen
			ChangeNoiseTimer :+ deltaTime
			If ChangeNoiseTimer >= 0.20
				noiseDisplace.position.SetXY(Rand(0, noiseDisplace.dimension.GetX()),Rand(0, noiseDisplace.dimension.GetY()))
				ChangeNoiseTimer = 0.0
				NoiseAlpha = 0.45 - (Rand(0,20)*0.01)
			EndIf
		EndIf


		If THelper.MouseIn(20,385,280,200)
			CurrentProgrammeToolTip.SetTitle(CurrentProgrammeText)
			local content:String = ""
			If programmePlan
				content	= GetLocale("AUDIENCE_NUMBER")+": "+programmePlan.getFormattedAudience()+ " ("+MathHelper.NumberToString(programmePlan.GetAudiencePercentage()*100,2)+"%)"

				'show additional information if channel is player's channel
				If ShowChannel = GetPlayerCollection().playerID
					If GetWorldTime().GetDayMinute() >= 5 And GetWorldTime().GetDayMinute() < 55
						Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
						If TAdvertisement(obj)
							'outage before?
							If not programmePlan.GetProgramme()
								content :+ "~n ~n|b||color=200,100,100|"+getLocale("NEXT_ADBLOCK")+":|/color||/b|~n" + obj.GetTitle()+" ("+ GetLocale("INVALID_BY_BROADCAST_OUTAGE") +")"
							Else
								local minAudienceText:string = TFunctions.convertValue(TAdvertisement(obj).contract.getMinAudience())
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
						Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
						If TProgramme(obj)
							content :+ "~n ~n|b|"+getLocale("NEXT_PROGRAMME")+":|/b|~n"
							If TProgramme(obj) And TProgramme(obj).isSeries() and TProgramme(obj).licence.parentLicenceGUID
								content :+ TProgramme(obj).licence.GetParentLicence().data.GetTitle() + ": " + obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							Else
								content :+ obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							EndIf
						ElseIf TAdvertisement(obj)
							content :+ "~n ~n|b|"+getLocale("NEXT_PROGRAMME")+":|/b|~n"+ GetLocale("INFOMERCIAL")+": " + obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
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
		If THelper.MouseIn(355,468,130,30)
			local playerProgrammePlan:TPlayerProgrammePlan = GetPlayer().GetProgrammePlan()
			if playerProgrammePlan
				CurrentAudienceToolTip.SetTitle(GetLocale("AUDIENCE_NUMBER")+": "+playerProgrammePlan.getFormattedAudience()+ " ("+MathHelper.NumberToString(playerProgrammePlan.GetAudiencePercentage() * 100,2)+"%)")
				CurrentAudienceToolTip.SetAudienceResult(GetBroadcastManager().GetAudienceResult(playerProgrammePlan.owner))
				CurrentAudienceToolTip.enabled = 1
				CurrentAudienceToolTip.Hover()
				'force redraw
				CurrentTimeToolTip.dirtyImage = True
			endif
		EndIf
		If THelper.MouseIn(355,533,130,45)
			CurrentTimeToolTip.SetTitle(getLocale("GAME_TIME")+": ")
			CurrentTimeToolTip.SetContent(GetWorldTime().getFormattedTime()+" "+getLocale("DAY")+" "+GetWorldTime().getDayOfYear()+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear())
			CurrentTimeToolTip.enabled = 1
			CurrentTimeToolTip.Hover()
		EndIf
		If THelper.MouseIn(355,415,130,30)
			MoneyToolTip.title = getLocale("MONEY")
			local content:String = ""
			content	= "|b|"+getLocale("MONEY")+":|/b| "+TFunctions.DottedValue(GetPlayer().GetMoney()) + getLocale("CURRENCY")
			content	:+ "~n"
			content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=200,100,100|"+ TFunctions.DottedValue(GetPlayer().GetCredit()) + getLocale("CURRENCY")+"|/color|"
			MoneyTooltip.SetContent(content)
			MoneyToolTip.enabled 	= 1
			MoneyToolTip.Hover()
		EndIf
		If THelper.MouseIn(355,510,130,15)
			BettyToolTip.SetTitle(getLocale("BETTY_FEELINGS"))
			BettyToolTip.SetContent(getLocale("THERE_IS_NO_LOVE_IN_THE_AIR_YET"))
			BettyToolTip.enabled = 1
			BettyToolTip.Hover()
		EndIf


		'=== SHOW / HIDE / LOCK CHAT ===
		if not ChatShow
			'arrow area
			if MouseManager.IsHit(1) and THelper.MouseIn(540, 397, 200, 20)
				'reset unread
				ChatContainsUnread = False

				ChatShow = True
				InGame_Chat.ShowChat()

				MouseManager.ResetKey(1)
			endif
			'lock area
			if MouseManager.IsHit(1) and THelper.MouseIn(770, 397, 20, 20)
				ChatShowHideLocked = 1- ChatShowHideLocked
			endif
		else
			'arrow area
			if MouseManager.IsHit(1) and THelper.MouseIn(540, 583, 200, 17)
				'reset unread
				ChatContainsUnread = False

				ChatShow = False
				InGame_Chat.HideChat()

				MouseManager.ResetKey(1)
			endif
			'lock area
			if MouseManager.IsHit(1) and THelper.MouseIn(770, 583, 20, 20)
				ChatShowHideLocked = 1 - ChatShowHideLocked
			endif
		endif

		if not ChatShowHideLocked
			if not ChatShow
				InGame_Chat.HideChat()
			else
				InGame_Chat.ShowChat()
			endif
		endif
		'====

	End Method


	'returns a string list of abbreviations for the watching family
	Function GetWatchingFamily:string[]()
		'fetch feedback to see which test-family member might watch
		Local feedback:TBroadcastFeedback = GetBroadcastManager().GetCurrentBroadcast().GetFeedback(GetPlayerCollection().playerID)

		local result:String[]

		if (feedback.AudienceInterest.Children > 0)
			'maybe sent to bed ? :D
			'If GetWorldTime().GetDayHour() >= 5 and GetWorldTime().GetDayHour() < 22 then 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["girl"]
		endif

		if (feedback.AudienceInterest.Pensioners > 0) then result :+ ["grandpa"]

		if (feedback.AudienceInterest.Teenagers > 0)
			'in school monday-friday - in school from till 7 to 13 - needs no sleep :D
			'If Game.GetWeekday()>6 or (GetWorldTime().GetDayHour() < 7 or GetWorldTime().GetDayHour() >= 13) then result :+ ["teen"] 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["teen"]
		endif

		if (feedback.AudienceInterest.Unemployed > 0)
			result :+ ["unemployed"]
		else
			'if there is some audience, show the sleeping unemployed
			if GetPlayer().GetProgrammePlan().GetAudiencePercentage() > 0.05
				result :+ ["unemployed.bored"]
			endif
		endif

		return result
	End Function


	'draws the interface
	Method Draw(tweenValue:Float=1.0)
		If BottomImgDirty
			'draw bottom, aligned "bottom"
			GetSpriteFromRegistry("gfx_interface_bottom").Draw(0, GetGraphicsManager().GetHeight(), 0, ALIGN_LEFT_BOTTOM)
		
		    'channel choosen and something aired?
		    local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(ShowChannel)

			'CurrentProgramme can contain "outage"-image, so draw
			'even without audience
			If CurrentProgramme Then CurrentProgramme.Draw(45, 405)
			If CurrentProgrammeOverlay Then CurrentProgrammeOverlay.Draw(45, 405)

			If programmePlan and programmePlan.GetAudience() > 0

				'fetch a list of watching family members
				local members:string[] = GetWatchingFamily()
				'later: limit to amount of "places" on couch
				Local familyMembersUsed:int = members.length

				'slots if 3 members watch
				local figureSlots:int[]
				if familyMembersUsed = 3 then figureSlots = [550, 610, 670]
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
						
						GetSpriteFromRegistry("gfx_interface_audience_"+member).Draw(figureslots[currentslot], GetGraphicsManager().GetHeight()-176)
						currentslot:+1 'occupy a slot
					Next
					'draw the small electronic parts - "the inner tv"
					GetSpriteFromRegistry("gfx_interface_audience_overlay").Draw(520, GetGraphicsManager().GetHeight()-31, 0, ALIGN_LEFT_BOTTOM)
				endif
			EndIf 'showchannel <>0

			'draw noise of tv device
			If ShowChannel <> 0
				SetAlpha NoiseAlpha
				If noiseSprite Then noiseSprite.DrawClipped(new TRectangle.Init(45, 405, 220,170), new TVec2D.Init(noiseDisplace.GetX(), noiseDisplace.GetY()) )
				SetAlpha 1.0
			EndIf
			'draw overlay to hide corners of non-round images
			GetSpriteFromRegistry("gfx_interface_tv_overlay").Draw(45,405)

		    For Local i:Int = 0 To 4
				If i = ShowChannel
					GetSpriteFromRegistry("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 559)
				Else
					GetSpriteFromRegistry("gfx_interface_channelbuttons_off_"+i).Draw(75 + i * 33, 559)
				EndIf
		    Next

			GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetPlayer().getMoneyFormatted(), 366, 421, 112, 15, ALIGN_CENTER_CENTER, TColor.Create(200,230,200), 2, 1, 0.5)

			GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetPlayer().GetProgrammePlan().getFormattedAudience(), 366, 463, 112, 15, ALIGN_CENTER_CENTER, TColor.Create(200,200,230), 2, 1, 0.5)

			'=== DRAW SECONDARY INFO ===
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha*0.75

			'current days financial win/loss
			local profit:int = GetPlayer().GetFinance().GetCurrentProfit()
			if profit > 0
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock("+"+TFunctions.DottedValue(profit), 366, 421+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(170,200,170), 2, 1, 0.5)
			elseif profit = 0
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock(0, 366, 421+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(170,170,170), 2, 1, 0.5)
			else
				GetBitmapFont("Default", 12, BOLDFONT).drawBlock(TFunctions.DottedValue(profit), 366, 421+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(200,170,170), 2, 1, 0.5)
			endif

			'market share
			GetBitmapFont("Default", 12, BOLDFONT).drawBlock(MathHelper.NumberToString(GetPlayer().GetProgrammePlan().GetAudiencePercentage()*100,2)+"%", 366, 463+15, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(170,170,200), 2, 1, 0.5)

			'current day
		 	GetBitmapFont("Default", 12, BOLDFONT).drawBlock((GetWorldTime().GetDaysRun()+1) + ". "+GetLocale("DAY"), 366, 555, 112, 12, ALIGN_CENTER_CENTER, TColor.Create(180,180,180), 2, 1, 0.5)

			SetAlpha oldAlpha
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND

'DrawRect(366, 542, 112, 15)
		GetBitmapFont("Default", 16, BOLDFONT).drawBlock(GetWorldTime().getFormattedTime() + " "+GetLocale("OCLOCK"), 366, 540, 112, 15, ALIGN_CENTER_CENTER, TColor.Create(220,220,220), 2, 1, 0.5)


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

		
	    GUIManager.Draw("InGame")

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Render()
		Next


		TError.DrawErrors()
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetInGameInterface:TInGameInterface()
	return TInGameInterface.GetInstance()
End Function