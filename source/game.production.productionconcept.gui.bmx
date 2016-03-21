SuperStrict
Import "Dig/base.util.graphicsmanager.bmx"
Import "common.misc.gamelist.bmx"
Import "game.production.productionconcept.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx" 'to change game cursor


'a graphical representation of shopping lists in studios/supermarket
Type TGuiProductionConceptListItem Extends TGUIGameListItem
	Field productionConcept:TProductionConcept

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


	Method SeTProductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
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
		Local sheetY:Float 	= 80 
		Local sheetX:Float 	= GetGraphicsManager().GetWidth()/2
		'move down if unplanned (less spaced needed on datasheet)
		if productionConcept.IsUnplanned() then sheetY :+ 50

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		ShowStudioSheet(sheetX, sheetY, 0)
	End Method


	Method DrawSupermarketSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Float 	= 80 
		Local sheetX:Float 	= GetGraphicsManager().GetWidth()/2

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
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

		local title:string = productionConcept.script.GetTitle()
		local conceptIsEmpty:int = productionConcept.IsUnplanned()

		local showMsgOrderWarning:Int = False
		local showMsgIncomplete:Int = productionConcept.IsGettingPlanned()
		local showMsgNotPlanned:Int = productionConcept.IsUnplanned()


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
		skin.fontNormal.drawBlock(productionConcept.script.GetDescription(), contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
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

		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		if not conceptIsEmpty
			'=== BOXES ===
			'boxes have a top-padding (except with messages)
			if msgAreaH = 0 then contentY :+ boxAreaPaddingY


			'=== BOX LINE 1 ===
			'production time
			skin.RenderBox(contentX + 5, contentY, 47, -1, 2, "duration", "neutral", skin.fontBold)
			'price
			if canAfford
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(productionConcept.GetTotalCost()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(productionConcept.GetTotalCost()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
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
			skin.fontNormal.draw("Trailerakt.-modifikator: "+MathHelper.NumberToString(data.GetTrailerMod().GetTotalAverage(), 4), contentX + 5, contentY)
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
		skin.RenderContent(contentX, contentY, contentW, subTitleH, "1")
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
		skin.RenderContent(contentX, contentY, contentW, msgAreaH, "1_bottom")


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

		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

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
