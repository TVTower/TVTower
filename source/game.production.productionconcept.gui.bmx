SuperStrict
Import "Dig/base.util.graphicsmanagerbase.bmx"
Import "common.misc.gamegui.bmx"
Import "game.production.productionconcept.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx" 'to change game cursor


TGuiProductionConceptSelectListItem.textBlockDrawSettings = new TDrawTextSettings()
TGuiProductionConceptSelectListItem.textBlockDrawSettings.data.lineHeight = 13
TGuiProductionConceptSelectListItem.textBlockDrawSettings.data.boxDimensionMode = 0


'a graphical representation of shopping lists in studios/supermarket
Type TGuiProductionConceptListItem Extends TGUIGameListItem
	Field productionConcept:TProductionConcept
	Field mode:Int = 0

	Const MODE_STUDIO:Int = 0
	Const MODE_SUPERMARKET:Int = 1

	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGuiProductionConceptListItem(pos:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_studio_productionConcept_0"
		Self.assetNameDragged = "gfx_studio_productionConcept_0"

		Return Self
	End Method


	Method CreateWithproductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
		Self.Create(New SVec2I(0,0), New SVec2I(0,0))
		Self.SetProductionConcept(productionConcept)
		Return Self
	End Method
	
	
	Method SetMode(mode:int)
		self.mode = mode
	End Method


	Method SetProductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
		Self.productionConcept = productionConcept
		Self.InitAssets(GetAssetName(productionConcept.script.GetMainGenre(), False), GetAssetName(productionConcept.script.GetMainGenre(), True))

		Return Self
	End Method


	'override default draw-method
	Method Draw() override
		Super.Draw()

		'set mouse to "dragged"
		If isDragged()
			GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
		'set mouse to "hover"
		ElseIf isHovered() And (productionConcept.owner = GetPlayerBaseCollection().playerID Or productionConcept.owner <= 0)
			if mode = MODE_SUPERMARKET
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
			elseif mode = MODE_STUDIO
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK)
			endif
		EndIf
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30, sheetAlign:int = 0)
		Local sheetY:Int = 80
		Local sheetX:Int = leftX
		Local sheetWidth:Int = 310
		Select sheetAlign
			'align to left x
			case -1	 sheetX = leftX
			'use left X as center
			case  0  sheetX = leftX
			'align to right if required
			case  1  sheetX = GetGraphicsManager().GetWidth() - rightX
			'automatic - left or right
			default
				If MouseManager.x < GetGraphicsManager().GetWidth()/2
					sheetX = GetGraphicsManager().GetWidth() - rightX
					sheetAlign = 1
				Else
					sheetX = leftX
					sheetAlign = -1
				EndIf
		EndSelect
	
		'move down if unplanned (less spaced needed on datasheet)
		if productionConcept.IsUnplanned() then sheetY :+ 50
		if productionConcept.script.IsLive() then sheetY :- 20
		if productionConcept.script.GetProductionBroadcastLimit() > 0 then sheetY :- 15
		if productionConcept.script.HasBroadcastTimeSlot() then sheetY :- 15

		
		Local baseX:Float
		Select sheetAlign
			case 0	baseX = sheetX
			case 1  baseX = sheetX - sheetWidth/2
			default baseX = sheetX + sheetWidth/2 
		End Select

		local oldCol:SColor8; GetColor(oldCol)
		local oldColA:Float = GetAlpha()
		SetColor 0,0,0
		SetAlpha 0.2 * oldColA
		TFunctions.DrawBaseTargetRect(baseX, ..
		                              sheetY + 50, ..
		                              Self.GetScreenRect().GetX() + Self.GetScreenRect().GetW()/2.0, ..
		                              Self.GetScreenRect().GetY() + Self.GetScreenRect().GetH()/2.0, ..
		                              20, 3)
		SetColor( oldCol )
		SetAlpha( oldColA )

		ShowStudioSheet(sheetX, sheetY, sheetAlign)
	End Method


	Method DrawSupermarketSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Int = 80
		Local sheetX:Int = GetGraphicsManager().GetWidth()/2

		local oldCol:SColor8; GetColor(oldCol)
		local oldColA:Float = GetAlpha()
		SetColor 0,0,0
		SetAlpha 0.2 * oldColA
		TFunctions.DrawBaseTargetRect(sheetX, ..
		                              sheetY + 50, ..
		                              Self.GetScreenRect().GetX() + Self.GetScreenRect().GetW()/2.0, ..
		                              Self.GetScreenRect().GetY() + Self.GetScreenRect().GetH()/2.0, ..
		                              20, 3)
		SetColor( oldCol )
		SetAlpha( oldColA )

		ShowSupermarketSheet(sheetX, sheetY, 0)
	End Method


	Method ShowStudioSheet:Int(x:Int,y:Int, align:int=0, useOwner:int=-1)
		if useOwner = -1 then useOwner = productionConcept.owner

		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		if align = -1 then x = x
		if align = 0 then x = x - 0.5 * sheetWidth
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("studioProductionConcept")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		local conceptIsEmpty:int = productionConcept.IsUnplanned()
		local title:string = productionConcept.GetTitle()
		local description:string = productionConcept.GetDescription()

		'series episode
		if productionConcept.script.IsEpisode() and productionConcept.script.GetParentScript() <> productionConcept.script
			local episodesMax:int = productionConcept.script.GetParentScript().GetSubScriptCount()
			local episodeNum:int = 1 + productionConcept.script.GetParentScript().GetSubScriptPosition(productionConcept.script)

			title = episodeNum+"/"+episodesMax+": "+title

			'episode got no description?
			if not description
				description = productionConcept.script.GetParentScript().GetDescription()
			endif

			description = "|i|"+productionConcept.script.GetParentScript().GetTitle()+"|/i|~n~n" + description
		endif


		local showMsgOrderWarning:Int = False
		local showMsgIncomplete:Int = productionConcept.IsGettingPlanned()
		local showMsgNotPlanned:Int = productionConcept.IsUnplanned()
		local showMsgDepositPaid:Int = productionConcept.IsDepositPaid()
		Local showMsgLiveInfo:Int = False
		Local showMsgBroadcastLimit:Int = False
		Local showMsgTimeSlotLimit:Int = False

		If productionConcept.script.IsLive() Then showMsgLiveInfo = True
		If productionConcept.script.GetProductionBroadcastLimit() > 0 Then showMsgBroadcastLimit= True
		If productionConcept.script.HasBroadcastTimeSlot() Then showMsgTimeSlotLimit = True


		'save on requests to the player finance
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if useOwner <= 0 or GetPlayerBaseCollection().playerID = useOwner
			finance = GetPlayerFinance(GetPlayerBaseCollection().playerID)
		endif

		'can player afford this licence?
		local canAfford:int = False
		'if it is another player... just display "can afford"
		if useOwner > 0
			canAfford = True
		'not our licence but enough money to buy
		elseif finance and finance.canAfford(productionConcept.GetTotalCost())
			canAfford = True
		endif

		'if planned unordered (1-3-2) warn the user
		'if ... then showMsgOrderWarning = True

		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, descriptionH:int = 70, castH:int=50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, msgH:int = 0, barH:int = 0
		local msgAreaH:int = 0, boxAreaH:int = 0, barAreaH:int = 0
		local boxAreaPaddingY:int = 4, msgAreaPaddingY:int = 4, barAreaPaddingY:int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).y
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").y
		barH = skin.GetBarSize(100, -1).y
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 12, BOLDFONT).GetBoxHeight(title, contentW - 10, 100))

		'message area
		If showMsgOrderWarning then msgAreaH :+ msgH
		If showMsgNotPlanned then msgAreaH :+ msgH
		If showMsgIncomplete then msgAreaH :+ msgH
		If showMsgDepositPaid then msgAreaH :+ msgH
		If showMsgLiveInfo Then msgAreaH :+ msgH
		If showMsgBroadcastLimit Then msgAreaH :+ msgH
		If showMsgTimeSlotLimit Then msgAreaH :+ msgH

		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ 2* msgAreaPaddingY


		'total height
		sheetHeight = titleH + descriptionH + msgAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()

		if not conceptIsEmpty
			'box area
			'contains 1 line of boxes
			'box area might start with padding and end with padding
			boxAreaH = 1 * boxH
			if msgAreaH = 0 then boxAreaH :+ boxAreaPaddingY
			'no ending if nothing comes after "boxes"

			'bar area starts with padding, ends with padding and contains
			'also contains 1 bar (production potential)
			barAreaH = 2 * barAreaPaddingY + 1 * (barH + 2)

			sheetHeight :+ castH + barAreaH + boxAreaH

			'there is a splitter between description and cast...
			sheetHeight :+ splitterHorizontalH
		endif


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		if titleH <= 18
			GetBitmapFontManager().Get("default", 12, BOLDFONT).DrawBox(title, contentX + 5, contentY + 1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		else
			GetBitmapFontManager().Get("default", 12, BOLDFONT).DrawBox(title, contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		endif
		contentY :+ titleH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(description, contentX + 5, contentY + 1, contentW - 10, descriptionH - 1, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		contentY :+ descriptionH


		if not conceptIsEmpty
			'splitter
			skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
			contentY :+ splitterHorizontalH


			'=== CAST AREA ===
			skin.RenderContent(contentX, contentY, contentW, castH, "2")
			'cast
			local cast:string = ""

			For local jobID:int = EachIn TVTPersonJob.GetCastJobs()
				local requiredPersons:int = productionConcept.script.GetSpecificJob(jobID).length
				if requiredPersons <= 0 then continue

				if cast <> "" then cast :+ ", "

				if requiredPersons = 1
					cast :+ "|b|"+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, True))+":|/b| "
				else
					cast :+ "|b|"+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, False))+":|/b| "
				endif

				cast :+ productionConcept.GetCastGroupString(jobID, False, GetLocale("JOB_POSITION_UNASSIGNED"))
			Next

			if cast <> ""
				'max width of cast word - to align their content properly
				skin.fontNormal.DrawBox(cast, contentX + 5, contentY, contentW  - 10, castH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
			endif
			contentY:+ castH
		endif


		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + messages + boxes
		if conceptIsEmpty
			skin.RenderContent(contentX, contentY, contentW, msgAreaH, "1_bottom")
		else
			skin.RenderContent(contentX, contentY, contentW, barAreaH + msgAreaH + boxAreaH, "1_bottom")
		endif


		if not conceptIsEmpty
			'===== DRAW BARS =====

			'bars have a top-padding
			contentY :+ barAreaPaddingY
			'production potential
			skin.RenderBar(contentX + 5, contentY, 200, 12, productionConcept.script.getPotential())
			skin.fontSmallCaption.DrawSimple(GetLocale("PRODUCTION_POTENTIAL"), contentX + 5 + 200 + 5, contentY - 3, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
			contentY :+ barH + 2
		endif


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		If showMsgLiveInfo
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, productionconcept.GetLiveTimeText(), "runningTime", EDatasheetColorStyle.Bad, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		If showMsgTimeSlotLimit
			if productionConcept.script.productionBroadcastFlags & TVTBroadcastMaterialSourceFlag.KEEP_BROADCAST_TIME_SLOT_ENABLED_ON_BROADCAST > 0
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", productionConcept.script.GetBroadcastTimeSlotStart()).Replace("%Y%", productionConcept.script.GetBroadcastTimeSlotEnd()), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("FIRST_BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", productionConcept.script.GetBroadcastTimeSlotStart()).Replace("%Y%", productionConcept.script.GetBroadcastTimeSlotEnd()), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			endif
			contentY :+ msgH
		EndIf


		If showMsgBroadcastLimit
			if productionConcept.script.GetProductionBroadcastLimit() = 1
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("ONLY_1_BROADCAST_POSSIBLE"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			Else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("ONLY_X_BROADCASTS_POSSIBLE").Replace("%X%", productionConcept.script.GetProductionBroadcastLimit()), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			EndIf
			contentY :+ msgH
		EndIf

		If showMsgOrderWarning
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("EPISODES_NOT_IN_ORDER"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif
		If showMsgIncomplete
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_INCOMPLETE"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif
		If showMsgNotPlanned
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_NOT_DONE"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif
		If showMsgDepositPaid
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_DEPOSIT_PAID").Replace("%MONEY%", GetFormattedCurrency(productionConcept.GetDepositCost())), "money", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif


		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		if not conceptIsEmpty
			'=== BOXES ===
			'boxes have a top-padding (except with messages)
			if msgAreaH = 0 then contentY :+ boxAreaPaddingY


			'=== BOX LINE 1 ===
			'duration (blocks)
			skin.RenderBox(contentX + 5, contentY, 50, -1, productionconcept.script.GetBlocks(), "duration", EDatasheetColorStyle.Neutral, skin.fontBold)
			'production time
			'skin.RenderBox(contentX + 5 + 60, contentY, 65, -1, (productionconcept.GetBaseProductionTime()/TWorldTime.HOURLENGTH) + GetLocale("HOUR_SHORT"), "runningTime", EDatasheetColorStyle.Neutral, skin.fontBold)
			skin.RenderBox(contentX + 5 + 60, contentY, 72, -1, TWorldtime.GetHourMinutesLeft(productionconcept.GetBaseProductionTime(), 4), "runningTime", EDatasheetColorStyle.Neutral, skin.fontBold)

			'price
			if canAfford
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(productionConcept.GetTotalCost()), "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(productionConcept.GetTotalCost()), "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
			endif
			'=== BOX LINE 2 ===
			contentY :+ boxH
		endif


		'=== DEBUG ===
rem
		If TVTDebugInfo
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.drawBlock("Programm: "+GetTitle(), contentX + 5, contentY, contentW - 10, 28)
			contentY :+ 28
			skin.fontNormal.draw("Letzte Stunde im Plan: "+latestPlannedEndHour, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Tempo: "+TFunctions.NumberToString(data.GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Kritik: "+TFunctions.NumberToString(data.GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Kinokasse: "+TFunctions.NumberToString(data.GetOutcome(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Preismodifikator: "+TFunctions.NumberToString(data.GetModifier("price"), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Qualitaet roh: "+TFunctions.NumberToString(GetQualityRaw(), 4)+"  (ohne Alter, Wdh.)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Qualitaet: "+TFunctions.NumberToString(GetQuality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Aktualitaet: "+TFunctions.NumberToString(GetTopicality(), 4)+" von " + TFunctions.NumberToString(data.GetMaxTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Bloecke: "+data.GetBlocks(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Ausgestrahlt: "+data.GetTimesBroadcasted(useOwner)+"x Spieler, "+data.GetTimesBroadcasted()+"x alle  Limit:"+broadcastLimit, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(useOwner, -1).audience.GetTotalSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetTotalSum())+" (alle)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Preis: "+GetPrice(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Trailerakt.-modifikator: "+TFunctions.NumberToString(GetTrailerMod().GetTotalAverage(), 4), contentX + 5, contentY)
		endif
endrem
		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	Method ShowSupermarketSheet:Int(x:Int,y:Int, align:int=0, useOwner:int=-1)
		if useOwner = -1 then useOwner = productionConcept.owner

		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		if align = 1 then x = x + sheetWidth
		if align = 0 then x = x - 0.5 * sheetWidth
		if align = -1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("supermarketProductionConcept")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		local title:string = productionConcept.GetTitle()
		local subTitle:string = ""
		local description:string = productionConcept.GetDescription()
		local subDescription:string = ""
		if productionConcept.script.IsEpisode()
			local seriesScript:TScript = productionConcept.script.GetParentScript()
			subtitle = (seriesScript.GetSubScriptPosition(productionConcept.script)+1)+"/"+seriesScript.GetSubscriptCount()+": "+ title
			title = seriesScript.GetTitle()

			subDescription = productionConcept.GetDescription()
			description = seriesScript.GetDescription()
		endif
		local conceptIsEmpty:int = productionConcept.IsUnplanned()

		local showMsgOrderWarning:Int = False
		local showMsgIncomplete:Int = productionConcept.IsGettingPlanned()
		local showMsgNotPlanned:Int = productionConcept.IsUnplanned()


		'if planned unordered (1-3-2) warn the user
		'if ... then showMsgOrderWarning = True

		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, subTitleH:int=16, genreH:int=16, descriptionH:int = 70, subDescriptionH:int = 50, castH:int=50
		local splitterHorizontalH:int = 6
		local msgH:int = 0, msgAreaH:int = 0, msgAreaPaddingY:int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).y
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 12, BOLDFONT).GetBoxHeight(title, contentW - 10, 100))

		if subTitle
			subTitleH = Max(subTitleH, 2 + GetBitmapFontManager().Get("default", 11, BOLDFONT).GetBoxHeight(subTitle, contentW - 10, 100))
		else
			subTitleH = 0
		endif

		if not subDescription then subDescriptionH = 0


		'message area
		If showMsgOrderWarning then msgAreaH :+ msgH
		If showMsgNotPlanned then msgAreaH :+ msgH
		If showMsgIncomplete then msgAreaH :+ msgH

		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ 2* msgAreaPaddingY


		'total height
		sheetHeight = titleH + subTitleH + genreH + descriptionH + subDescriptionH + msgAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()

		if not conceptIsEmpty
			sheetHeight :+ castH

			if msgAreaH > 0
				'there is a splitter between description and cast...
				sheetHeight :+ splitterHorizontalH
			endif
		endif


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH + subTitleH, "1_top")
		if titleH <= 18
			GetBitmapFontManager().Get("default", 12, BOLDFONT).DrawBox(title, contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		else
			GetBitmapFontManager().Get("default", 12, BOLDFONT).DrawBox(title, contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		endif
		contentY :+ titleH

		'=== SUBTITLE AREA ===
		if subTitleH
			if subTitleH <= 18
				GetBitmapFontManager().Get("default", 11, BOLDFONT).DrawBox(subTitle, contentX + 5, contentY -1, contentW - 10, subTitleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			else
				GetBitmapFontManager().Get("default", 11, BOLDFONT).DrawBox(subTitle, contentX + 5, contentY +1, contentW - 10, subTitleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			endif
			contentY :+ subTitleH
		endif

		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
			local productionTypeText:string = productionConcept.script.GetProductionTypeString()
			local genreText:string = productionConcept.script.GetMainGenreString()
			local text:string = productionTypeText
			if genreText <> productionTypeText then text :+ " / "+genreText

			GetBitmapFontManager().Get("default", 11).DrawBox(text, contentX + 5, contentY -1, contentW - 10, genreH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ genreH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(description, contentX + 5, contentY + 1, contentW - 10, descriptionH - 1, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		contentY :+ descriptionH

		if subDescriptionH
			'splitter
			skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
			contentY :+ splitterHorizontalH

			skin.RenderContent(contentX, contentY, contentW, subDescriptionH, "2")
			skin.fontNormal.DrawBox(subDescription, contentX + 5, contentY + 1, contentW - 10, subDescriptionH - 1, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
			contentY :+ subDescriptionH
		endif

		if not conceptIsEmpty
			'splitter
			skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
			contentY :+ splitterHorizontalH


			'=== CAST AREA ===
			skin.RenderContent(contentX, contentY, contentW, castH, "2")
			'cast
			local cast:string = ""

			For local jobID:Int = EachIn TVTPersonJob.GetCastJobs()
				local requiredPersons:int = productionConcept.script.GetSpecificJob(jobID).length
				if requiredPersons <= 0 then continue

				if cast <> "" then cast :+ ", "

				if requiredPersons = 1
					cast :+ "|b|"+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, True))+":|/b| "
				else
					cast :+ "|b|"+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, False))+":|/b| "
				endif

				cast :+ productionConcept.GetCastGroupString(jobID, False, GetLocale("JOB_POSITION_UNASSIGNED"))
			Next

			if cast <> ""
				'max width of cast word - to align their content properly
				skin.fontNormal.DrawBox(cast, contentX + 5, contentY , contentW  - 10, castH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
			endif
			contentY:+ castH
		endif


		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + messages + boxes
		if msgAreaH > 0
			skin.RenderContent(contentX, contentY, contentW, msgAreaH, "1_bottom")

			'=== MESSAGES ===
			'if there is a message then add padding to the begin
			contentY :+ msgAreaPaddingY

			If showMsgOrderWarning
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("EPISODES_NOT_IN_ORDER"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
				contentY :+ msgH
			endif
			If showMsgIncomplete
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_INCOMPLETE"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
				contentY :+ msgH
			endif
			If showMsgNotPlanned
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_NOT_DONE"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
				contentY :+ msgH
			endif

			'if there is a message then add padding to the bottom
			contentY :+ msgAreaPaddingY
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	Method DrawContent()
		SetColor 255,255,255
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If productionConcept.owner = GetPlayerBaseCollection().playerID
				SetAlpha( 0.80 * oldColA )
				SetColor( 200,200,200 )
			Else
				SetAlpha( 0.70*oldCol.a )
				SetColor( 250,200,150 )
			EndIf
		EndIf

		if productionConcept.IsProduceable()
			SetColor( 190,250,150 )
		elseif productionConcept.IsPlanned()
			SetColor( 150,200,250 )
		elseif productionConcept.IsGettingPlanned()
			SetColor( 250,200,150 )
		else 'elseif productionConcept.IsUnplanned()
			'default color
		endif

		Super.DrawContent()

		SetColor( oldCol )
		SetAlpha( oldColA )
	End Method
End Type




Type TGuiProductionConceptSelectListItem Extends TGuiProductionConceptListItem
	Field displayName:string = ""
	Field minHeight:int = 50 '61

	Global colorPlanned:SColor8 = new SColor8(30,80,150)
	Global colorGettingPlanned:SColor8 = new SColor8(150,80,30)
	Global colorProduceable:SColor8 = new SColor8(80,150,30)
	Global colorDefault:SColor8 = new SColor8(50,50,50)
	Global colorHint:SColor8 = new SColor8(0,0,0, int(0.6 * 255))

	Global colorProduceableBG:TColor = TColor.Create(110,180,60, 0.1)
	Global colorPlannedBG:TColor = TColor.Create(60,110,180, 0.1)
	Global colorGettingPlannedBG:TColor = TColor.Create(180,110,60, 0.1)
	Global colorSelectedBG:TColor = TColor.Create(175,165,120, 0.25)
	Global textBlockDrawSettings:TDrawTextSettings = new TDrawTextSettings

	Const scaleAsset:Float = 0.55
	Const paddingBottom:Int	= 2
	Const paddingTop:Int = 2


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
	End Method


    Method Create:TGuiProductionConceptSelectListItem(pos:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(pos, dimension, value)
		SetOption(GUI_OBJECT_DRAGABLE, False)

		Self.InitAssets(GetAssetName(0, False), GetAssetName(0, True))

		'resize it
		GetDimension()

		Return Self
	End Method


	Method Compare:Int(Other:Object)
		if Other = self then return 0 'no change

		Local otherItem:TGuiProductionConceptSelectListItem = TGuiProductionConceptSelectListItem(Other)
		if not otherItem then return Super.Compare(other)
		If not otherItem.productionConcept or not otherItem.productionConcept.script then return -1 'before
		if not productionConcept or not productionConcept.script then return 1 'after

		'ATTENTION: productionConcept.script.GetParentScript() might return
		'           NULL (eg. when cleaning up OLD gui lists)

		'both are episodes of the same series
		if productionConcept.script.GetParentScript() and productionConcept.script.GetParentScript() = otherItem.productionConcept.script.GetParentScript()
			if productionConcept.studioSlot < otherItem.productionConcept.studioSlot
				return -1 'before other
			elseif productionConcept.studioSlot > otherItem.productionConcept.studioSlot
				return 1 'after it
			'order by episode if nothing was defined
			else
				local parentScript:TScript = productionConcept.script.GetParentScript()
				if parentScript.GetSubScriptPosition(productionConcept.script) < parentScript.GetSubScriptPosition(otherItem.productionConcept.script)
					return -1 'before other
				elseif parentScript.GetSubScriptPosition(productionConcept.script) > parentScript.GetSubScriptPosition(otherItem.productionConcept.script)
					return 1 'after other
				endif
				'else: sort alphabetically
			endif
		endif

		local titleA:string = productionConcept.GetTitle()
		local titleB:string = otherItem.productionConcept.GetTitle()
		if productionConcept.script.IsEpisode() and productionConcept.script.GetParentScript()
			titleA = productionConcept.script.GetParentScript().GetTitle() + titleA
		endif
		if otherItem.productionConcept.script.IsEpisode() and otherItem.productionConcept.script.GetParentScript()
			titleB = otherItem.productionConcept.script.GetParentScript().GetTitle() + titleB
		endif

		'let the name be sorted alphabetically
		if titleA < titleB
			return -1 'before
		elseif titleA > titleB
			return 1 'after
		else
			'sort by guid
			if productionConcept.GetGUID() < otherItem.productionConcept.GetGUID()
				return -1 'before
			elseif productionConcept.GetGUID() > otherItem.productionConcept.GetGUID()
				return 1
			endif
		endif

		Return Super.Compare(Other)
	End Method

rem
TODO: might be needed somewhen
	'override to add scaleAsset
	Method SetAsset(sprite:TSprite=Null, name:string = "")
		If Not sprite then sprite = Self.assetDefault
		If Not name then name = Self.assetNameDefault


		'only resize if not done already
		If Self.asset <> sprite or self.assetName <> name
			Self.asset = sprite
			Self.assetName = name
			Self.Resize(sprite.area.GetW() * scaleAsset, sprite.area.GetH() * scaleAsset)
		EndIf
	End Method
endrem

	Method GetDimension:SVec2F() override
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.GetContentScreenRect().GetW() '- GetScreenRect().GetW()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		'2 lines of text
		Local w:Float = maxWidth
		Local h:Float = max(minHeight, asset.GetHeight() * scaleAsset)

		'add padding
		h :+ Self.paddingTop
		h :+ Self.paddingBottom

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.w <> w Or Self.rect.h <> h
			'resize item
			Self.SetSize(w, h)
		EndIf

		Return new SVec2F(w, h)
	End Method


	Method DrawBackground()
		'available width is parentsDimension minus startingpoint
		Local maxWidth:Int = rect.GetX()
		if _parent then maxWidth = _parent.GetContentScreenRect().GetW() - rect.getX()
		local bgColor:TColor

		'ready for production
		if productionConcept.IsProduceable() or productionConcept.IsProductionStarted() or productionConcept.IsProductionFinished()
			bgColor = colorProduceableBG
		'planned but not paid
		elseif productionConcept.isPlanned()
			bgColor = colorPlannedBG
		'in planning
		elseif productionConcept.IsGettingPlanned()
			bgColor = colorGettingPlannedBG
		'default
		else 'elseif productionConcept.IsUnplanned()
			if IsHovered() or isSelected()
				bgColor = colorSelectedBG
			endif
		endif


		if bgColor
			Local oldCol:SColor8; GetColor(oldCol)
			Local oldColA:Float = GetAlpha()

 			If isSelected() or isHovered()
				bgColor = bgColor.copy()
				If isSelected()
					bgColor.a :+ 0.05
					bgColor.AdjustBrightness(0.1)
				EndIf
				If isHovered()
					bgColor.a :+ 0.1
					bgColor.AdjustBrightness(0.1)
				EndIf
			EndIf

			bgColor.SetRGBA()

			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY() + paddingTop -2, GetScreenRect().GetW(), GetScreenRect().GetH() - paddingBottom -3)

			SetColor( oldCol )
			SetAlpha( oldColA )
		endif
	End Method


	'override
	Method DrawContent()
		DrawProductionConceptItem()

		'hovered
		If isHovered() and not isDragged()
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend

			DrawProductionConceptItem()

			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf

		Local scrRect:TRectangle = GetScreenRect()
		SetColor 150,150,150
		DrawLine(scrRect.GetX() + 10, scrRect.GetY2() - paddingBottom -1, scrRect.GetX2() - 20, scrRect.GetY2() - paddingBottom -1)
		SetColor 210,210,210
		DrawLine(scrRect.GetX() + 10, scrRect.GetY2() - paddingBottom, scrRect.GetX2() - 20, scrRect.GetY2() - paddingBottom)
	End Method


	Method DrawProductionConceptItem()
		GetAsset().draw(Self.GetScreenRect().GetX(), Self.GetScreenRect().GetY(), -1, null, scaleAsset)

		'ready for production
		if productionConcept.IsProduceable() or productionConcept.isProductionStarted() or productionConcept.isProductionFinished()
			GetSpriteFromRegistry("gfx_datasheet_icon_ok").Draw(Self.GetScreenRect().GetX()-2, Self.GetScreenRect().GetY() + GetAsset().GetHeight() * scaleAsset -1)
		'finished planning
		elseif productionConcept.IsPlanned()
			GetSpriteFromRegistry("gfx_datasheet_icon_ok2").Draw(Self.GetScreenRect().GetX()-2, Self.GetScreenRect().GetY() + GetAsset().GetHeight() * scaleAsset -1)
		'planning not yet finished
		elseif productionConcept.IsGettingPlanned()
			GetSpriteFromRegistry("gfx_datasheet_icon_warning").Draw(Self.GetScreenRect().GetX()-3, Self.GetScreenRect().GetY() + GetAsset().GetHeight() * scaleAsset -1)
		'default
		else 'elseif productionConcept.IsUnplanned()
			'nothing
		endif

		local textOffsetX:int = asset.GetWidth()*scaleAsset + 3
		local title:string = "unknown script"
		local titleSize:SVec2I
		local subtitle:string = ""
		local subTitleSize:SVec2I
		local genreColor:SColor8
		local titleColor:SColor8
		local titleFont:TBitmapFont = GetBitmapFont("default",11,BOLDFONT)
		local oldMod:float = titleFont.lineHeightModifier
		titleFont.lineHeightModifier :* 0.9

		if productionConcept
			title = productionConcept.GetTitle()
			if productionConcept.script.IsEpisode()
				local seriesScript:TScript = productionConcept.script.GetParentScript()
				subtitle = (seriesScript.GetSubScriptPosition(productionConcept.script)+1)+"/"+seriesScript.GetSubscriptCount()+": "+ title
				title = seriesScript.GetTitle()
			endif
		endif


		'finished
		if productionConcept.IsProduceable() or productionConcept.IsProductionStarted() or productionConcept.IsProductionFinished()
			titleColor = colorProduceable
			genreColor = colorHint
		'all slots filled, just not paid
		elseif productionConcept.IsPlanned()
			titleColor = colorPlanned
			genreColor = colorHint
		'planned but not finished
		elseif productionConcept.IsGettingPlanned()
			titleColor = colorGettingPlanned
			genreColor = colorHint
		'default /unplanned
		else 'elseif productionConcept.IsUnplanned()
			titleColor = colorDefault
			genreColor = colorHint
		endif


		if isSelected() or isHovered()
			if isSelected()
				titleColor = SColor8AdjustFactor(titleColor, 10)
				genreColor = SColor8AdjustFactor(genreColor, 10)
			endif
			if isHovered()
				titleColor = SColor8AdjustFactor(titleColor, 10)
				genreColor = SColor8AdjustFactor(genreColor, 10)
			endif
		endif


		if subTitle
			titleSize = titleFont.DrawBox(title, int(GetScreenRect().GetX()+ textOffsetX), int(GetScreenRect().GetY() - 2), GetScreenRect().GetW() - textOffsetX - 1, titleFont.GetLineHeight(), sALIGN_LEFT_TOP, titleColor, textBlockDrawSettings)
			if titleSize.y > 20
				subTitleSize = titleFont.DrawBox(subTitle, int(GetScreenRect().GetX()+ textOffsetX), int(GetScreenRect().GetY() + titleSize.y - 3), GetScreenRect().GetW() - textOffsetX - 3, 14, sALIGN_LEFT_TOP, titleColor, textBlockDrawSettings)
			else
				subTitleSize = titleFont.DrawBox(subTitle, int(GetScreenRect().GetX()+ textOffsetX), int(GetScreenRect().GetY() + titleSize.y - 3), GetScreenRect().GetW() - textOffsetX - 3, 28, sALIGN_LEFT_TOP, titleColor, textBlockDrawSettings)
			endif
		else
			titleSize = titleFont.DrawBox(title, int(GetScreenRect().GetX()+ textOffsetX), int(GetScreenRect().GetY() - 2), GetScreenRect().GetW() - textOffsetX - 1, GetScreenRect().GetH()-4, sALIGN_LEFT_TOP, titleColor, textBlockDrawSettings)
'print title + "  " + titleSize.ToString() + "  scrRect="+GetScreenRect().ToString()
		endif


		titleFont.lineHeightModifier = oldMod


		if productionConcept
			local productionTypeText:string = productionConcept.script.GetProductionTypeString()
			local genreText:string = productionConcept.script.GetMainGenreString()
			local text:string = productionTypeText
			if genreText <> productionTypeText then text :+ " / "+genreText
			if subTitle
				GetBitmapFont("default").DrawBox(text, int(GetScreenRect().GetX()+ textOffsetX), int(GetScreenRect().GetY() + titleSize.y + subTitleSize.y - 2), GetScreenRect().GetW() - textOffsetX - 3, GetScreenRect().GetH()-4, sALIGN_LEFT_TOP, genreColor)
			else
				GetBitmapFont("default").DrawBox(text, int(GetScreenRect().GetX()+ textOffsetX), int(GetScreenRect().GetY() + titleSize.y - 2), GetScreenRect().GetW() - textOffsetX - 3, GetScreenRect().GetH()-4, sALIGN_LEFT_TOP, genreColor)
			endif
		endif
	End Method
End Type



Type TGUIProductionConceptSlotList Extends TGUIGameSlotList
    Method Create:TGUIProductionConceptSlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsproductionConcept:Int(productionConcept:TProductionConcept)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGuiProductionConceptListItem = TGuiProductionConceptListItem( Self.GetItemBySlot(i) )
			If block And block.productionConcept = productionConcept Then Return True
		Next
		Return False
	End Method
End Type
