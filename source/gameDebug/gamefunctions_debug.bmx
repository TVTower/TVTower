Global debugAudienceInfo:TDebugAudienceInfo = New TDebugAudienceInfo
Global debugProfiler:TDebugProfiler = new TDebugProfiler


Type TDebugScreen
	Field _enabled:Int
	Field _lastEnabled:Int
	Field _mode:Int = 0
	Field _lastMode:Int
	Field currentPage:TDebugScreenPage

	Field sideButtons:TDebugControlsButton[]
	Field sideButtonPanelWidth:Int = 130

	Field pageOverview:TDebugScreenPage_Overview
	Field pagePlayerCommands:TDebugScreenPage_PlayerCommands
	Field pagePlayerFinancials:TDebugScreenPage_PlayerFinancials
	Field pagePlayerBroadcasts:TDebugScreenPage_PlayerBroadcasts
	Field pagePublicImages:TDebugScreenPage_PublicImages
	Field pageStationmap:TDebugScreenPage_StationMap
	Field pageNewsAgency:TDebugScreenPage_NewsAgency
	Field pageAdAgency:TDebugScreenPage_AdAgency
	Field pageMovieAgency:TDebugScreenPage_MovieAgency
	Field pageScriptAgency:TDebugScreenPage_ScriptAgency
	Field pageRoomAgency:TDebugScreenPage_RoomAgency
	Field pagePolitics:TDebugScreenPage_Politics
	Field pageCustomProductions:TDebugScreenPage_CustomProductions
	Field pageProducers:TDebugScreenPage_Producers
	Field pageSports:TDebugScreenPage_Sports
	Field pageModifiers:TDebugScreenPage_Modifiers
	Field pageMisc:TDebugScreenPage_Misc

	Global _eventListeners:TEventListenerBase[]


	Method New()
		Local button:TDebugControlsButton
		Local texts:String[] = ["Overview", "Player Commands", "Player Financials", "Player Broadcasts", "Public Image", "Stationmap", "-", "Ad Agency", "Movie Vendor", "News Agency", "Script Agency", "Room Agency", "-", "Politics Sim", "Custom Production", "Producers", "Sports Sim", "Modifiers", "Misc"]
		Local mode:int = 0
		For Local i:Int = 0 Until texts.length
			If texts[i] = "-" Then Continue 'spacer
			button = TDebugScreenPage.CreateActionButton(i, texts[i], -510 , 10)
			button.w = 118
			button.dataInt = mode
			mode :+ 1
			button._onClickHandler = OnButtonClickHandler

			sideButtons :+ [button]
		Next

		pageOverview = new TDebugScreenPage_Overview.Init()
		pageOverview.SetPosition(sideButtonPanelWidth, 20)

		currentPage = pageOverview

		pagePlayerCommands = TDebugScreenPage_PlayerCommands.GetInstance().Init()
		pagePlayerCommands.SetPosition(sideButtonPanelWidth, 20)

		pagePlayerFinancials = TDebugScreenPage_PlayerFinancials.GetInstance().Init()
		pagePlayerFinancials.SetPosition(sideButtonPanelWidth, 20)

		pagePlayerBroadcasts = TDebugScreenPage_PlayerBroadcasts.GetInstance().Init()
		pagePlayerBroadcasts.SetPosition(sideButtonPanelWidth, 20)

		pagePublicImages = TDebugScreenPage_PublicImages.GetInstance().Init()
		pagePublicImages.SetPosition(sideButtonPanelWidth, 20)

		pageStationmap = TDebugScreenPage_StationMap.GetInstance().Init()
		pageStationmap.SetPosition(sideButtonPanelWidth, 20)

		pageAdAgency = TDebugScreenPage_AdAgency.GetInstance().Init()
		pageAdAgency.SetPosition(sideButtonPanelWidth, 20)

		pageMovieAgency = TDebugScreenPage_MovieAgency.GetInstance().Init()
		pageMovieAgency.SetPosition(sideButtonPanelWidth, 20)

		pageNewsAgency = TDebugScreenPage_NewsAgency.GetInstance().Init()
		pageNewsAgency.SetPosition(sideButtonPanelWidth, 20)

		pageScriptAgency = TDebugScreenPage_ScriptAgency.GetInstance().Init()
		pageScriptAgency.SetPosition(sideButtonPanelWidth, 20)

		pageRoomAgency = TDebugScreenPage_RoomAgency.GetInstance().Init()
		pageRoomAgency.SetPosition(sideButtonPanelWidth, 20)

		pagePolitics = TDebugScreenPage_Politics.GetInstance().Init()
		pagePolitics.SetPosition(sideButtonPanelWidth, 20)

		pageCustomProductions = TDebugScreenPage_CustomProductions.GetInstance().Init()
		pageCustomProductions.SetPosition(sideButtonPanelWidth, 20)

		pageProducers = TDebugScreenPage_Producers.GetInstance().Init()
		pageProducers.SetPosition(sideButtonPanelWidth, 20)

		pageSports = TDebugScreenPage_Sports.GetInstance().Init()
		pageSports.SetPosition(sideButtonPanelWidth, 20)

		pageModifiers = TDebugScreenPage_Modifiers.GetInstance().Init()
		pageModifiers.SetPosition(sideButtonPanelWidth, 20)

		pageMisc = TDebugScreenPage_Misc.GetInstance().Init()
		pageMisc.SetPosition(sideButtonPanelWidth, 20)

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, onStartGame) ]
	End Method


	Method Reset()
		If pageOverview Then pageOverview.Reset()
		If pagePlayerCommands Then pagePlayerCommands.Reset()
		If pagePlayerFinancials Then pagePlayerFinancials.Reset()
		If pagePlayerBroadcasts Then TDebugScreenPage_PlayerBroadcasts.GetInstance().Reset()
		If pagePublicImages Then pagePublicImages.Reset()
		If pageStationmap Then pageStationmap.Reset()
		If pageAdAgency Then TDebugScreenPage_AdAgency.GetInstance().Reset()
		If pageMovieAgency Then TDebugScreenPage_MovieAgency.GetInstance().GetInstance().Reset()
		If pageNewsAgency Then TDebugScreenPage_NewsAgency.GetInstance().Reset()
		If pageScriptAgency Then TDebugScreenPage_ScriptAgency.GetInstance().Reset()
		If pageRoomAgency Then TDebugScreenPage_RoomAgency.GetInstance().Reset()
		If pagePolitics Then pagePolitics.Reset()
		If pageCustomProductions Then pageCustomProductions.Reset()
		If pageProducers Then pageProducers.Reset()
		If pageSports Then pageSports.Reset()
		If pageModifiers Then pageModifiers.Reset()
		If pageMisc Then pageMisc.Reset()
	End Method


	'Call reset on new game / loaded game
	Function onStartGame:Int(triggerEvent:TEventBase)
		DebugScreen.Reset()
	End Function


	Method SetMode(newMode:Int)
		If newMode <> _mode
			_mode = newMode

			Local newPage:TDebugScreenPage
			Select _mode
				Case 0	newPage = pageOverview
				Case 1	newPage = pagePlayerCommands
				Case 2	newPage = pagePlayerFinancials
				Case 3	newPage = pagePlayerBroadcasts
				Case 4	newPage = pagePublicImages
				Case 5	newPage = pageStationmap

				Case 6	newPage = pageAdAgency
				Case 7	newPage = pageMovieAgency
				Case 8	newPage = pageNewsAgency
				Case 9	newPage = pageScriptAgency
				Case 10	newPage = pageRoomAgency

				Case 11	newPage = pagePolitics
				Case 12	newPage = pageCustomProductions
				Case 13	newPage = pageProducers
				Case 14	newPage = pageSports
				Case 15	newPage = pageModifiers
				Case 16	newPage = pageMisc
				default newPage = Null
			End Select

			If newPage <> currentPage
				If currentPage Then currentPage.Deactivate()
				If newPage Then newPage.Activate()
				currentPage = newPage
			EndIf
		EndIf
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		DebugScreen.SetMode(sender.dataInt)
	End Function


	'called no matter if debug screen is shown or not - use this for
	'stuff needing regular updates anyways (eg to reset values)
	Method UpdateSystem()
		If _enabled <> _lastEnabled
			If currentPage
				If _enabled
					currentPage.Activate()
				Else
					currentPage.Deactivate()
				EndIf
			EndIf

			_lastEnabled = _enabled
		EndIf
	End Method


	Method Update()
		For Local b:TDebugControlsButton = EachIn sideButtons
			b.Update()

			If _mode = b.dataInt
				b.selected = True
			Else
				b.selected = False
			EndIf
		Next

		If currentPage Then currentPage.Update()
	End Method


	Method Render()
		If Not TDebugScreenPage.titleFont
			TDebugScreenPage.titleFont = GetBitmapFont("default", 12, BOLDFONT)
			TDebugScreenPage.textFontBold = GetBitmapFont("default", 10, BOLDFONT)
			TDebugScreenPage.textFont = GetBitmapFont("default", 10)
		EndIf

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		TDebugScreenPage.DrawOutlineRect(0, 0, sideButtonPanelWidth - 2, 355)
		For Local b:TDebugControlsButton = EachIn sideButtons
			b.Render()
		Next

		SetColor 0,0,0
		SetAlpha 0.2 * oldColA
		DrawRect(sideButtonPanelWidth,0, 800 - sideButtonPanelWidth, 385)
		SetColor(oldCol)
		SetAlpha(oldColA)

		If currentPage Then currentPage.Render()
	End Method


	Function Dev_MaxAudience(playerID:Int)
		GetStationMap(playerID).CheatMaxAudience()
		GetGame().SendSystemMessage("[DEV] Set Player #" + playerID + "'s maximum audience to " + GetStationMap(playerID).GetReach())
	End Function


	Function Dev_SetMasterKey(playerID:Int, bool:Int)
		Local player:TPlayer = GetPlayer(playerID)
		player.GetFigure().SetHasMasterkey(bool)
		If bool
			GetGame().SendSystemMessage("[DEV] Added masterkey to player '" + player.name +"' ["+player.playerID + "]!")
		Else
			GetGame().SendSystemMessage("[DEV] Removed masterkey from player '" + player.name +"' ["+player.playerID + "]!")
		EndIf
	End Function
End Type
Global DebugScreen:TDebugScreen = New TDebugScreen



Type TDebugAudienceInfoForPlayer
	Field playerID:Int
	Field reach:String=""
	Field money:String=""
	Field credit:String=""
	Field potAudience:String=""
	Field progTitle:String=""
	Field currentImageNews:Float
	Field currentImageProgramme:Float
	Field diffNews:String
	Field colorDiffNews:SColor8
	Field diffProgramme:String
	Field colorDiffProgramme:SColor8
	Field currentQuoteNews:String
	Field currentQuoteProgramme:String
	Field currentTitleProgramme:String
	Field imageBeforeNews:Float


	Method Update(minute:Int)
		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )
		Local image:Float = Min(Max(GetPublicImage(playerID).GetAverageImage()/100.0, 0.0),1.0)*100
		Local diff:Float
		If minute < 6
			reach = TFunctions.convertValue(audienceResult.WholeMarket.GetTotalValue(0),2)
			currentQuoteNews = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
			imageBeforeNews = currentImageProgramme
			currentImageNews = image
			diff = currentImageNews - imageBeforeNews
			colorDiffNews = SColor8.Green
			If diff < 0 Then colorDiffNews = SColor8.Red
			diffNews =  MathHelper.NumberToString(diff,2)
		ElseIf minute > 5
			Local player:TPlayer = GetPlayer(playerID)
			money = player.GetMoneyFormatted()
			credit = player.GetCreditFormatted()
			currentQuoteProgramme = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
			imageBeforeNews = currentImageProgramme
			currentImageProgramme = image
			diff = currentImageProgramme - currentImageNews
			colorDiffProgramme = SColor8.Green
			If diff < 0 Then colorDiffProgramme = SColor8.Red
			diffProgramme = MathHelper.NumberToString(diff,2)
		EndIf
		potAudience = TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetTotalSum(),2)
		progTitle = audienceResult.GetTitle()
	EndMethod
End Type



Type TDebugAudienceInfo
	Field currentStatement:TBroadcastFeedbackStatement
	Field lastCheckedMinute:Int
	Field mode:Int = 0 '0=off, 1=one player, 2=all players
	Field playerData:TDebugAudienceInfoForPlayer[4]

	Method Reset()
		currentStatement = Null
		lastCheckedMinute = 0
	End Method


	Method Update(playerID:Int, x:Int, y:Int)
	End Method


	Method Toggle()
		mode = (mode + 1) mod 3
		Reset()
		If mode = 2
			playerData = new TDebugAudienceInfoForPlayer[4]
			For Local playerID:Int = 1 To 4
				playerData[playerID-1] = New TDebugAudienceInfoForPlayer
				playerData[playerID-1].playerID = playerID
			Next
		EndIf
	End Method


	Method Draw()
		SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetColor 255, 255, 255

		If mode = 1
			DrawSinglePlayer()
		ElseIf mode = 2
			DrawAllPlayers()
		EndIF
	End Method


	Method DrawAllPlayers()
		GetBitmapFontManager().baseFont.DrawBox("|b|Taste |color=255,100,0|~qQ~q|/color| drücken|/b|, um Quotenbildschirm auszublenden.", 0, 360, GetGraphicsManager().GetWidth(), 25, sALIGN_CENTER_CENTER, SColor8.Red)

		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		Local h:Int = 15
		'table player info in column
		font.DrawSimple("Spieler", 15, h, SColor8.White)
		font.DrawSimple("Geld", 15, 2 * h, SColor8.White)
		font.DrawSimple("Schulden", 15, 3 * h, SColor8.White)
		font.DrawSimple("Bevölkerung", 15, 4 * h, SColor8.White)
		font.DrawSimple("pot. Zuschauer", 15, 5 * h, SColor8.White)
		font.DrawSimple("akt. Zuschauer", 15, 8 * h, SColor8.White)

		'table player info in row
		Local rowX:Int = 80
		Local rowY:Int = 11 * h
		font.DrawBox("ImgAlt", rowX, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("News-%", rowX + 60, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("+/-", rowX + 110, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("ImgN", rowX + 160, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Prog-%", rowX + 210, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("+/-", rowX + 260, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("ImgP", rowX + 310, rowY, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)

		Local minute:Int = GetWorldTime().GetDayMinute()
		If (minute < 6 And lastCheckedMinute > 5) Or (minute > 5 And lastCheckedMinute < 6)
			For Local playerID:Int = 1 To 4
				playerData[playerID-1].Update(minute)
			Next
			lastCheckedMinute = minute
		EndIf

		For Local playerID:Int = 1 To 4
			'player info in colum
			Local x:Int = 130 + (playerID-1) * 150
			Local data:TDebugAudienceInfoForPlayer = playerData[playerID-1]
			Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )
			font.DrawBox(playerID, x, h, 195, 17, sALIGN_LEFT_TOP, SColor8.White)

			font.DrawBox(data.money, x, 2*h, 150, 17, sALIGN_LEFT_TOP, SColor8.White)
			font.DrawBox(data.credit, x, 3*h, 150, 17, sALIGN_LEFT_TOP, SColor8.White)
			font.DrawBox(data.reach, x, 4*h, 150, 17, sALIGN_LEFT_TOP, SColor8.White)

			font.DrawBox(data.potAudience, x, 5*h, 150, 17, sALIGN_LEFT_TOP, SColor8.White)
			Local percent:String = MathHelper.NumberToString(audienceResult.GetPotentialMaxAudienceQuotePercentage()*100,2) + "%"
			font.DrawSimple(percent, x, 6*h, SColor8.White)

			font.DrawBox(data.progTitle, x, 7*h, 150, 17, sALIGN_LEFT_TOP, SColor8.White)

			font.DrawBox(TFunctions.convertValue(audienceResult.Audience.GetTotalSum(),2), x, 8*h, 150, 17, sALIGN_LEFT_TOP, SColor8.White)

			'player info in row
			Local y:Int = (11+playerID) * h
			font.DrawSimple("Spieler "+playerID+":", 15, y, SColor8.White)
			font.DrawBox(MathHelper.NumberToString(data.imageBeforeNews,2), rowX, y, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
			font.DrawBox(data.currentQuoteNews, rowX+60, y, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
			font.DrawBox(data.diffNews, rowX+110, y, 55, 17, sALIGN_RIGHT_TOP, data.colorDiffNews)
			font.DrawBox(MathHelper.NumberToString(data.currentImageNews,2), rowX+160, y, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
			font.DrawBox(data.currentQuoteProgramme, rowX+210, y, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
			font.DrawBox(data.diffProgramme, rowX+260, y, 55, 17, sALIGN_RIGHT_TOP, data.colorDiffProgramme)
			font.DrawBox(MathHelper.NumberToString(data.currentImageProgramme,2), rowX+310, y, 55, 17, sALIGN_RIGHT_TOP, SColor8.White)
		Next
	End Method


	Method DrawSinglePlayer()
		GetBitmapFontManager().baseFont.DrawBox("|b|Taste |color=255,100,0|~qQ~q|/color| drücken|/b|, um auf Übersicht für alle Spieler umzuschalten. Spielerwechsel: TV-Kanalbuttons", 0, 360, GetGraphicsManager().GetWidth(), 25, sALIGN_CENTER_CENTER, SColor8.Red)
		'GetBitmapFontManager().baseFont.Draw("Bevölkerung", 25, startY)

		Local playerID:Int = TIngameInterface.GetInstance().ShowChannel
		If playerID <= 0 Then playerID = GetPlayerBaseCollection().playerID

		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )

		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall

		GetBitmapFontManager().baseFontBold.DrawSimple("Spieler: "+playerID, 25, 25, SColor8.Red)
		font.DrawBox("Gesamt", x, y, 65, 25, sALIGN_RIGHT_TOP, SColor8.Red)
		font.DrawBox("Kinder", x + (70*1), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Jugendliche", x + (70*2), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Hausfrau.", x + (70*3), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Arbeitneh.", x + (70*4), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Arbeitslose", x + (70*5), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Manager", x + (70*6), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)
		font.DrawBox("Rentner", x + (70*7), y, 65, 25, sALIGN_RIGHT_TOP, SColor8.White)


		font.DrawSimple("Bevölkerung", 25, 50, SColor8.White)
		DrawAudience(audienceResult.WholeMarket.data, 200, 50)

		Local percent:String = MathHelper.NumberToString(audienceResult.GetPotentialMaxAudienceQuotePercentage()*100,2) + "%"
		font.DrawSimple("Potentielle Zuschauer", 25, 70, SColor8.White)
		font.DrawSimple(percent, 160, 70, SColor8.White)
		DrawAudience(audienceResult.PotentialMaxAudience.data, 200, 70)

		Local colorLight:SColor8 = new SColor8(150, 150, 150)

		'font.drawStyled("      davon Exklusive", 25, 90, TColor.clWhite)
		'DrawAudience(audienceResult.ExclusiveAudienceSum.data, 200, 90, true)

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, colorLight)
		'DrawAudience(audienceResult.AudienceFlowSum.data, 200, 105, true)

		'font.drawStyled("      davon Zapper", 25, 120, colorLight)
		'DrawAudience(audienceResult.ChannelSurferToShare.data, 200, 120, true)


		font.DrawSimple("Aktuelle Zuschauerzahl", 25, 90, SColor8.White)
		percent = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
		font.DrawSimple(percent, 160, 90, SColor8.White)
		DrawAudience(audienceResult.Audience.data, 200, 90)

		'font.drawStyled("      davon Exklusive", 25, 155, colorLight)
		'DrawAudience(audienceResult.ExclusiveAudience.data, 200, 155, true)

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, colorLight)
		'DrawAudience(audienceResult.AudienceFlow.data, 200, 170, true)

		'font.drawStyled("      davon Zapper", 25, 185, colorLight)
		'DrawAudience(audienceResult.ChannelSurfer.data, 200, 185, true)





		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		Local popularity:String = ""
		Select attraction.BroadcastType
			Case TVTBroadcastMaterialType.PROGRAMME
				If (attraction.BaseAttraction <> Null And attraction.genreDefinition)
					genre = GetLocale("PROGRAMME_GENRE_"+TVTProgrammeGenre.GetAsString(attraction.genreDefinition.referenceID))
					If attraction.GenrePopularityMod
						popularity = "Popularity "+genre+ ": " + MathHelper.NumberToString(attraction.GenrePopularityMod,2) +"; Long Term: "+MathHelper.NumberToString(1+ attraction.genreDefinition._popularity.LongTermPopularity/100.0,2)
					EndIf
				EndIf
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If (attraction.BaseAttraction <> Null)
					genre = GetLocale("INFOMERCIAL")
				EndIf
			Case TVTBroadcastMaterialType.NEWSSHOW
				If (attraction.BaseAttraction <> Null)
					genre = "News-Genre-Mix"
				EndIf
		End Select

		Local offset:Int = 110

		GetBitmapFontManager().baseFontBold.DrawSimple("Sendung (" + genre + "): " + audienceResult.GetTitle(), 25, offset, SColor8.Red)
		If popularity
			font.DrawBox(popularity, 455, offset, 300, 25, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		offset :+ 20

		font.DrawSimple("1. Programmqualität & Aktual.", 25, offset, SColor8.White)
		If attraction.Quality
			DrawAudiencePercent(New SAudience(attraction.Quality, attraction.Quality), 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("2. * Zielgruppenattraktivität", 25, offset, SColor8.White)
		If attraction.targetGroupAttractivity
			DrawAudiencePercent(attraction.targetGroupAttractivity.data, 200, offset, True, True)
		Else
'			print "   dyn: "+  attraction.GetTargetGroupAttractivity().ToString()
		EndIf
		offset :+ 20

		font.DrawSimple("3. * TrailerMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_TRAILER*100)+"%)", 25, offset, SColor8.White)
		If attraction.TrailerMod
			font.DrawBox(genre, 60, offset, 205, 25, sALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.TrailerMod.Copy().Multiply(TAudienceAttraction.MODINFLUENCE_TRAILER).Add(1).data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("4. + Sonstige Mods ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_MISC*100)+"%)", 25, offset, SColor8.White)
		If attraction.MiscMod
			DrawAudiencePercent(attraction.MiscMod.data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("5. + CastMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_CAST*100)+"%)", 25, offset, SColor8.White)
		DrawAudiencePercent(New SAudience(attraction.CastMod,  attraction.CastMod), 200, offset, True, True)
		offset :+ 20

		font.DrawSimple("6. * SenderimageMod", 25, offset, SColor8.White)
		If attraction.PublicImageMod
			DrawAudiencePercent(attraction.PublicImageMod.Copy().Add(1.0).data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("7. + Zuschauerentwicklung (inaktiv)", 25, offset, SColor8.White)
	'	DrawAudiencePercent(New TAudience.Set(-1, attraction.QualityOverTimeEffectMod), 200, offset, true, true)
		offset :+ 20

		font.DrawSimple("9. + Glück / Zufall", 25, offset, SColor8.White)
		If attraction.LuckMod
			DrawAudiencePercent(attraction.LuckMod.data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("9. + Audience Flow Bonus", 25, offset, SColor8.White)
		If attraction.AudienceFlowBonus
			DrawAudiencePercent(attraction.AudienceFlowBonus.data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("10. * Genreattraktivität (zeitabh.)", 25, offset, SColor8.White)
		If attraction.GetGenreAttractivity()
			DrawAudiencePercent(attraction.GetGenreAttractivity().data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("11. + Sequence", 25, offset, SColor8.White)
		If attraction.SequenceEffect
			DrawAudiencePercent(attraction.SequenceEffect.data, 200, offset, True, True)
		EndIf
		offset :+ 20

		font.DrawSimple("Finale Attraktivität (Effektiv)", 25, offset, SColor8.White)
		If attraction.FinalAttraction
			DrawAudiencePercent(attraction.FinalAttraction.data, 200, offset, False, True)
		EndIf
Rem
		font.Draw("Basis-Attraktivität", 25, offset+230, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BaseAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BaseAttraction, 200, offset+230, false, true);
		EndIf
		endrem
		Rem
		endrem

		Rem
		font.Draw("10. Nachrichteneinfluss", 25, offset+330, TColor.clWhite)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.NewsShowBonus Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.NewsShowBonus, 200, offset+330, true, true);
		EndIf
		endrem

		Rem
		font.Draw("Block-Attraktivität", 25, offset+290, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BlockAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BlockAttraction, 200, offset+290, false, true);
		EndIf
		endrem



		Rem
		font.Draw("Ausstrahlungs-Attraktivität", 25, offset+270, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BroadcastAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BroadcastAttraction, 200, offset+270, false, true);
		EndIf
		endrem

		Local currBroadcast2:TBroadcast = GetBroadcastManager().GetCurrentBroadcast()
		Local feedback:TBroadcastFeedback = currBroadcast2.GetFeedback(playerID)

		Local minute:Int = GetWorldTime().GetDayMinute()

		If ((minute Mod 5) = 0)
			If Not (Self.lastCheckedMinute = minute)
				Self.lastCheckedMinute = minute
				currentStatement = Null
				'DebugStop
			End If
		EndIf

		If Not currentStatement Then
			currentStatement:TBroadcastFeedbackStatement = feedback.GetNextAudienceStatement()
		EndIf

		SetColor 0,0,0
		DrawRect(520,415,250,40)
		font.DrawSimple("Interest: " + feedback.AudienceInterest.ToStringMinimal(), 530, 420, SColor8.Red)
		font.DrawSimple("Statements: count=" + feedback.FeedbackStatements.Count(), 530, 430, SColor8.Red)
		If currentStatement Then
			font.DrawSimple(currentStatement.ToString(), 530, 440, SColor8.Red)
		EndIf

		SetColor 255,255,255


Rem
		font.Draw("Genre <> Sendezeit", 25, offset+240, TColor.clWhite)
		Local genreTimeMod:String = MathHelper.NumberToString(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:String = MathHelper.NumberToString(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240, TColor.clWhite)
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)

		'Nur vorübergehend
		font.Draw("Trailer-Mod", 25, offset+250, TColor.clWhite)
		Local trailerMod:String = MathHelper.NumberToString(attraction.TrailerMod  * 100,2) + "%"
		Local trailerQuality:String = MathHelper.NumberToString(attraction.TrailerQuality * 100,2) + "%"
		font.Draw(trailerMod, 160, offset+250, TColor.clWhite)
		font.drawBlock(trailerQuality, 200, offset+250, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)



		font.Draw("Image", 25, offset+295, TColor.clWhite);
		font.Draw("100%", 160, offset+295, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+295);

		font.Draw("Effektive Attraktivität", 25, offset+325, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+325)
endrem
	End Method


	Function DrawAudience(audience:SAudience, x:Int, y:Int, gray:Int = False)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		Local color:SColor8 = SColor8.White
		If gray Then color = new SColor8(150, 150, 150)

		val = TFunctions.convertValue(audience.GetTotalSum(), 2)
		If gray Then
			font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, new SColor8(150, 80, 80))
		Else
			font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, SColor8.Red)
		End If

		Local i:Int = 0
		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			i :+ 1
			val = TFunctions.convertValue(audience.GetTotalValue(targetGroupID), 2)
			font.DrawBox(val, x2 + 70*(i-1), y, 65, 25, sALIGN_RIGHT_TOP, color)
		Next
	End Function


	Function DrawAudiencePercent(audience:SAudience, x:Int, y:Int, gray:Int = False, hideAverage:Int = False)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		Local color:SColor8 = SColor8.White
		If gray Then color = new SColor8(150, 150, 150)

		If Not hideAverage Then
			val = MathHelper.NumberToString(audience.GetWeightedAverage(),2)
			If gray Then
				font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, new SColor8(150, 80, 80))
			Else
				font.DrawBox(val, x, y, 65, 25, sALIGN_RIGHT_TOP, SColor8.Red)
			End If
		End If

		Local i:Int = 0
		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			i :+ 1
			val = MathHelper.NumberToString(0.5 * audience.GetTotalValue(targetGroupID),2)
			font.DrawBox(val, x2 + 70*(i-1), y, 65, 25, sALIGN_RIGHT_TOP, color)
		Next
	End Function
End Type



Type TDebugProfiler
	Field active:Int = False
	Field callNames:object[]


	Method ObserveCall(callName:Object)
		callNames :+ [callName]
	End Method


	Method Update(x:Int, y:Int)
	End Method


	Method Draw(x:Int, y:Int)
		If Not active Then Return

		Local textX:Int = x
		Local textY:Int = y
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float; oldColA = GetAlpha()
		Local font:TBitmapfont = GetBitmapFont("default", 10)

		SetColor 0,0,0
		SetAlpha 0.75*oldColA
		DrawRect(x, y, 220, 100)
		
		SetColor(255,255,255)
		font.Draw("Profiler", textX, textY)
		textY :+ 12
		For Local callName:object = EachIn callNames
			Local c:TProfilerCall = TProfiler.GetCall(callName)
			If c
				font.Draw(c.name.ToString() + "  " + c.calls + " calls, " + StringHelper.printf("%5.2f", [string(float(c.timeTotal) / c.calls)])+"ms avg.", textX, textY)
				textY :+ 12
			EndIf
		Next

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method
End Type
