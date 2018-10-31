SuperStrict
Import "Dig/base.util.graphicsmanagerbase.bmx"
Import "common.misc.gamegui.bmx"
Import "game.production.productionconcept.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx" 'to change game cursor


'a graphical representation of shopping lists in studios/supermarket
Type TGuiProductionConceptListItem Extends TGUIGameListItem
	Field productionConcept:TProductionConcept


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGuiProductionConceptListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_studio_productionConcept_0"
		Self.assetNameDragged = "gfx_studio_productionConcept_0"

		Return Self
	End Method


	Method CreateWithproductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
		Self.Create()
		Self.SeTProductionConcept(productionConcept)
		Return Self
	End Method


	Method SetProductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
		Self.productionConcept = productionConcept
		Self.InitAssets(GetAssetName(productionConcept.script.GetMainGenre(), False), GetAssetName(productionConcept.script.GetMainGenre(), True))

		Return Self
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'set mouse to "hover"
		If productionConcept.owner = GetPlayerBaseCollection().playerID Or productionConcept.owner <= 0 And isHovered()
			GetGameBase().cursorstate = 1
		EndIf

		'set mouse to "dragged"
		If isDragged()
			GetGameBase().cursorstate = 2
		EndIf
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Int = 80
		Local sheetX:Int = GetGraphicsManager().GetWidth()/2
		'move down if unplanned (less spaced needed on datasheet)
		if productionConcept.IsUnplanned() then sheetY :+ 50

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[float(sheetX+20),float(sheetY+25),float(sheetX+20),float(sheetY+90),Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		ShowStudioSheet(sheetX, sheetY, 0)
	End Method


	Method DrawSupermarketSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Int = 80
		Local sheetX:Int = GetGraphicsManager().GetWidth()/2

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[float(sheetX+20),float(sheetY+25),float(sheetX+20),float(sheetY+90),Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		ShowSupermarketSheet(sheetX, sheetY, 0)
	End Method


	Method ShowStudioSheet:Int(x:Int,y:Int, align:int=0, useOwner:int=-1)
		if useOwner = -1 then useOwner = productionConcept.owner

		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		if align = 1 then x = x + sheetWidth
		if align = 0 then x = x - 0.5 * sheetWidth
		if align = -1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("studioProductionConcept")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		local conceptIsEmpty:int = productionConcept.IsUnplanned()
		local title:string = productionConcept.script.GetTitle()
		local description:string = productionConcept.script.GetDescription()

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

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).GetY()
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))

		'message area
		If showMsgOrderWarning then msgAreaH :+ msgH
		If showMsgNotPlanned then msgAreaH :+ msgH
		If showMsgIncomplete then msgAreaH :+ msgH
		If showMsgDepositPaid then msgAreaH :+ msgH

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
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(description, contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH


		if not conceptIsEmpty
			'splitter
			skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
			contentY :+ splitterHorizontalH


			'=== CAST AREA ===
			skin.RenderContent(contentX, contentY, contentW, castH, "2")
			'cast
			local cast:string = ""

			For local i:int = 1 to TVTProgrammePersonJob.count
				local jobID:int = TVTProgrammePersonJob.GetAtIndex(i)
				local requiredPersons:int = productionConcept.script.GetSpecificCast(jobID).length
				if requiredPersons <= 0 then continue

				if cast <> "" then cast :+ ", "

				if requiredPersons = 1
					cast :+ "|b|"+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, True))+":|/b| "
				else
					cast :+ "|b|"+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, False))+":|/b| "
				endif

				cast :+ productionConcept.GetCastGroupString(jobID, False, GetLocale("JOB_POSITION_UNASSIGNED"))
			Next

			if cast <> ""
				contentY :+ 3

				'max width of cast word - to align their content properly
				skin.fontNormal.drawBlock(cast, contentX + 5, contentY , contentW  - 10, castH, null, skin.textColorNeutral)

				contentY:+ castH - 3
			else
				contentY:+ castH
			endif
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
			skin.RenderBar(contentX + 5, contentY, 200, 12, 1.0)
			skin.fontSemiBold.drawBlock(GetLocale("PRODUCTION_POTENTIAL"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
			contentY :+ barH + 2
		endif


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		If showMsgOrderWarning
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("EPISODES_NOT_IN_ORDER"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif
		If showMsgIncomplete
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_INCOMPLETE"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif
		If showMsgNotPlanned
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_NOT_DONE"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif
		If showMsgDepositPaid
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_DEPOSIT_PAID").Replace("%MONEY%", MathHelper.DottedValue(productionConcept.GetDepositCost()) + GetLocale("CURRENCY")), "money", "neutral", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif


		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		if not conceptIsEmpty
			'=== BOXES ===
			'boxes have a top-padding (except with messages)
			if msgAreaH = 0 then contentY :+ boxAreaPaddingY


			'=== BOX LINE 1 ===
			'production time
			skin.RenderBox(contentX + 5, contentY, 67, -1, productionconcept.GetBaseProductionTime()+GetLocale("HOUR_SHORT"), "duration", "neutral", skin.fontBold)

			'price
			if canAfford
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, MathHelper.DottedValue(productionConcept.GetTotalCost()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, MathHelper.DottedValue(productionConcept.GetTotalCost()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
			endif
			'=== BOX LINE 2 ===
			contentY :+ boxH
		endif


		'=== DEBUG ===
rem
		If TVTDebugInfos
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
			skin.fontNormal.draw("Tempo: "+MathHelper.NumberToString(data.GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Kritik: "+MathHelper.NumberToString(data.GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Kinokasse: "+MathHelper.NumberToString(data.GetOutcome(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Preismodifikator: "+MathHelper.NumberToString(data.GetModifier("price"), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Qualitaet roh: "+MathHelper.NumberToString(GetQualityRaw(), 4)+"  (ohne Alter, Wdh.)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Qualitaet: "+MathHelper.NumberToString(GetQuality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Aktualitaet: "+MathHelper.NumberToString(GetTopicality(), 4)+" von " + MathHelper.NumberToString(data.GetMaxTopicality(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Bloecke: "+data.GetBlocks(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Ausgestrahlt: "+data.GetTimesBroadcasted(useOwner)+"x Spieler, "+data.GetTimesBroadcasted()+"x alle  Limit:"+broadcastLimit, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(useOwner, -1).audience.GetTotalSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetTotalSum())+" (alle)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Preis: "+GetPrice(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Trailerakt.-modifikator: "+MathHelper.NumberToString(GetTrailerMod().GetTotalAverage(), 4), contentX + 5, contentY)
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

		local title:string = productionConcept.script.GetTitle()
		local subTitle:string = ""
		local description:string = productionConcept.script.GetDescription()
		local subDescription:string = ""
		if productionConcept.script.IsEpisode()
			local seriesScript:TScript = productionConcept.script.GetParentScript()
			subtitle = (seriesScript.GetSubScriptPosition(productionConcept.script)+1)+"/"+seriesScript.GetSubscriptCount()+": "+ title
			title = seriesScript.GetTitle()

			subDescription = productionConcept.script.GetDescription()
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

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))

		if subTitle
			subTitleH = Max(subTitleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(subTitle, contentW - 10, 100))
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
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			if titleH <= 18
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH

		'=== SUBTITLE AREA ===
		if subTitleH
			skin.RenderContent(contentX, contentY, contentW, subTitleH, "1")
				if subTitleH <= 18
					GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(subTitle, contentX + 5, contentY -1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				else
					GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(subTitle, contentX + 5, contentY +1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				endif
			contentY :+ subTitleH
		endif

		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
			local productionTypeText:string = productionConcept.script.GetProductionTypeString()
			local genreText:string = productionConcept.script.GetMainGenreString()
			local text:string = productionTypeText
			if genreText <> productionTypeText then text :+ " / "+genreText

			GetBitmapFontManager().Get("default", 12).drawBlock(text, contentX + 5, contentY -1, contentW - 10, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(description, contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH

		if subDescriptionH
			'splitter
			skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
			contentY :+ splitterHorizontalH

			skin.RenderContent(contentX, contentY, contentW, subDescriptionH, "2")
			skin.fontNormal.drawBlock(subDescription, contentX + 5, contentY + 3, contentW - 10, subDescriptionH - 3, null, skin.textColorNeutral)
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

			For local i:int = 1 to TVTProgrammePersonJob.count
				local jobID:int = TVTProgrammePersonJob.GetAtIndex(i)
				local requiredPersons:int = productionConcept.script.GetSpecificCast(jobID).length
				if requiredPersons <= 0 then continue

				if cast <> "" then cast :+ ", "

				if requiredPersons = 1
					cast :+ "|b|"+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, True))+":|/b| "
				else
					cast :+ "|b|"+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, False))+":|/b| "
				endif

				cast :+ productionConcept.GetCastGroupString(jobID, False, GetLocale("JOB_POSITION_UNASSIGNED"))
			Next

			if cast <> ""
				contentY :+ 3

				'max width of cast word - to align their content properly
				skin.fontNormal.drawBlock(cast, contentX + 5, contentY , contentW  - 10, castH, null, skin.textColorNeutral)

				contentY:+ castH - 3
			else
				contentY:+ castH
			endif
		endif


		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + messages + boxes
		if msgAreaH > 0
			skin.RenderContent(contentX, contentY, contentW, msgAreaH, "1_bottom")

			'=== MESSAGES ===
			'if there is a message then add padding to the begin
			contentY :+ msgAreaPaddingY

			If showMsgOrderWarning
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("EPISODES_NOT_IN_ORDER"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
				contentY :+ msgH
			endif
			If showMsgIncomplete
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_INCOMPLETE"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
				contentY :+ msgH
			endif
			If showMsgNotPlanned
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("PRODUCTION_SETUP_NOT_DONE"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
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
		Local oldCol:TColor = New TColor.Get()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If productionConcept.owner = GetPlayerBaseCollection().playerID
				SetAlpha 0.80*oldCol.a
				SetColor 200,200,200
			Else
				SetAlpha 0.70*oldCol.a
				SetColor 250,200,150
			EndIf
		EndIf

		if productionConcept.IsProduceable()
			SetColor 190,250,150
		elseif productionConcept.IsPlanned()
			SetColor 150,200,250
		elseif productionConcept.IsGettingPlanned()
			SetColor 250,200,150
		else 'elseif productionConcept.IsUnplanned()
			'default color
		endif

		Super.DrawContent()

		oldCol.SetRGBA()
	End Method
End Type



Type TGuiProductionConceptSelectListItem Extends TGuiProductionConceptListItem
	Field displayName:string = ""
	Field minHeight:int = 50 '61
	Const scaleAsset:Float = 0.55
	Const paddingBottom:Int	= 2
	Const paddingTop:Int = 2


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
	End Method


    Method Create:TGuiProductionConceptSelectListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
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

	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, max(minHeight, asset.GetHeight() * scaleAsset))

		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method


	Method DrawBackground()
		local oldCol:TColor = new TColor.Get()

		'available width is parentsDimension minus startingpoint
		Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		local bgColor:TColor

		'ready for production
		if productionConcept.IsProduceable()
			bgColor = TColor.Create(110,180,60, 0.1)
		'planned but not paid
		elseif productionConcept.isPlanned()
			bgColor = TColor.Create(60,110,180, 0.1)
		'in planning
		elseif productionConcept.IsGettingPlanned()
			bgColor = TColor.Create(180,110,60, 0.1)
		'default
		else 'elseif productionConcept.IsUnplanned()
			if IsHovered() or isSelected()
				bgColor = TColor.Create(175,165,120, 0.25)
			endif
		endif


		if bgColor
			If isSelected() then bgColor.a :+ 0.05; bgColor.AdjustBrightness(0.1)
			If isHovered() then bgColor.a :+ 0.1; bgColor.AdjustBrightness(0.1)

			bgColor.SetRGBA()

			DrawRect(GetScreenX(), GetScreenY() + paddingTop -2, GetScreenWidth(), GetScreenHeight() - paddingBottom -3)

			oldCol.SetRGBA()
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

		SetColor 150,150,150
		DrawLine(GetScreenX() + 10, GetScreenY2() - paddingBottom -1, GetScreenX2() - 20, GetScreenY2() - paddingBottom -1)
		SetColor 210,210,210
		DrawLine(GetScreenX() + 10, GetScreenY2() - paddingBottom, GetScreenX2() - 20, GetScreenY2() - paddingBottom)
	End Method


	Method DrawProductionConceptItem()
		GetAsset().draw(Self.GetScreenX(), Self.GetScreenY(), -1, null, scaleAsset)

		'ready for production
		if productionConcept.IsProduceable()
			GetSpriteFromRegistry("gfx_datasheet_icon_ok").Draw(Self.GetScreenX()-2, Self.GetScreenY() + GetAsset().GetHeight() * scaleAsset -1)
		'finished planning
		elseif productionConcept.IsPlanned()
			GetSpriteFromRegistry("gfx_datasheet_icon_ok2").Draw(Self.GetScreenX()-2, Self.GetScreenY() + GetAsset().GetHeight() * scaleAsset -1)
		'planning not yet finished
		elseif productionConcept.IsGettingPlanned()
			GetSpriteFromRegistry("gfx_datasheet_icon_warning").Draw(Self.GetScreenX()-3, Self.GetScreenY() + GetAsset().GetHeight() * scaleAsset -1)
		'default
		else 'elseif productionConcept.IsUnplanned()
			'nothing
		endif

		local textOffsetX:int = asset.GetWidth()*scaleAsset + 3
		local title:string = "unknown script"
		local subtitle:string = ""
		local titleSize:TVec2D
		local subTitleSize:TVec2D
		local genreColor:TColor
		local titleColor:TColor
		local titleFont:TBitmapFont = GetBitmapFont("default",,BOLDFONT)
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
		if productionConcept.IsProduceable()
			titleColor = TColor.Create(80,150,30)
			genreColor = TColor.CreateGrey(0, 0.6)
		'all slots filled, just not paid
		elseif productionConcept.IsPlanned()
			titleColor = TColor.Create(30,80,150)
			genreColor = TColor.CreateGrey(0, 0.6)
		'planned but not finished
		elseif productionConcept.IsGettingPlanned()
			titleColor = TColor.Create(150,80,30)
			genreColor = TColor.CreateGrey(0, 0.6)
		'default /unplanned
		else 'elseif productionConcept.IsUnplanned()
			titleColor = TColor.CreateGrey(50)
			genreColor = TColor.CreateGrey(0, 0.6)
		endif


		if isSelected()
			titleColor.AdjustBrightness(+0.05)
			genreColor.AdjustBrightness(+0.05)
		endif
		if isHovered()
			titleColor.AdjustBrightness(+0.05)
			genreColor.AdjustBrightness(+0.05)
		endif


		titleSize = titleFont.DrawBlock(title, int(GetScreenX()+ textOffsetX), int(GetScreenY()+2), GetScreenWidth() - textOffsetX - 1, GetScreenHeight()-4,,titleColor)
		if subTitle
			if titleSize.y > 20
				subTitleSize = titleFont.DrawBlock(subTitle, int(GetScreenX()+ textOffsetX), int(GetScreenY() + titleSize.y + 2), GetScreenWidth() - textOffsetX - 3, 14,,titleColor)
			else
				subTitleSize = titleFont.DrawBlock(subTitle, int(GetScreenX()+ textOffsetX), int(GetScreenY() + titleSize.y + 2), GetScreenWidth() - textOffsetX - 3, 28,,titleColor)
			endif
		endif


		titleFont.lineHeightModifier = oldMod


		if productionConcept
			local productionTypeText:string = productionConcept.script.GetProductionTypeString()
			local genreText:string = productionConcept.script.GetMainGenreString()
			local text:string = productionTypeText
			if genreText <> productionTypeText then text :+ " / "+genreText
			if subTitle
				GetBitmapFont("default").DrawBlock(text, int(GetScreenX()+ textOffsetX), int(GetScreenY()+2 + titleSize.y + subTitleSize.y), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-4,,genreColor)
			else
				GetBitmapFont("default").DrawBlock(text, int(GetScreenX()+ textOffsetX), int(GetScreenY()+2 + titleSize.y), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-4,,genreColor)
			endif
		endif
	End Method
End Type



Type TGUIProductionConceptSlotList Extends TGUIGameSlotList
    Method Create:TGUIProductionConceptSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
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
