SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.roomhandler.adagency.bmx"



Type TDebugScreenPage_Adagency extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field offerHightlight:TAdContract

	Global _instance:TDebugScreenPage_Adagency
	
	
	Method New()
		_instance = self
	End Method
	
	
	Function GetInstance:TDebugScreenPage_Adagency()
		if not _instance then new TDebugScreenPage_Adagency
		return _instance
	End Function 


	Method Init:TDebugScreenPage_AdAgency()
		Local texts:String[] = ["Refill Offers", "Replace Offers", "Change Mode"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next
		
		Return self
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				RoomHandler_AdAgency.GetInstance().ReFillBlocks()
			case 1
				RoomHandler_AdAgency.GetInstance().ReFillBlocks(True, 1.0)
			case 2
				if RoomHandler_AdAgency.GetInstance()._setRefillMode = 2
					RoomHandler_AdAgency.GetInstance().SetRefillMode(1)
					GetInstance().UpdateAdAgencyModeButton()
				else
					RoomHandler_AdAgency.GetInstance().SetRefillMode(2)
					GetInstance().UpdateAdAgencyModeButton()
				endif
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
	

	Method Reset()
	End Method
	
	
	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method UpdateAdAgencyModeButton()
		Select RoomHandler_AdAgency.GetInstance()._setRefillMode
			case 1	buttons[2].text = "Change Mode: " + RoomHandler_AdAgency.GetInstance()._setRefillMode + "->2"
			case 2	buttons[2].text = "Change Mode: " + RoomHandler_AdAgency.GetInstance()._setRefillMode + "->1"
			default	buttons[2].text = "Change Mode: " + RoomHandler_AdAgency.GetInstance()._setRefillMode + "->2"
		End Select
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		'initial refill?
		'if RoomHandler_AdAgency.listNormal.length = 0 then ReFillBlocks()

		UpdateBlock_AdAgencyOffers(playerID, position.x + 5, position.y + 3, 250, 230)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		RenderBlock_AdAgencyOffers(playerID, position.x + 5, position.y + 3, 250, 230)
		RenderBlock_AdAgencyInformation(playerID, position.x + 5 + 250 + 5, position.y + 3)

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		if offerHightlight
			offerHightlight.ShowSheet(position.x + 5 + 250, position.y + 3, 0, TVTBroadcastMaterialType.ADVERTISEMENT, playerID)
		endif
	End Method


	Method RenderBlock_AdAgencyInformation(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
'		DrawOutlineRect(x, y, w, h)
rem
		Local captionFont:TBitMapFont
			SetColor 0,0,0
			SetAlpha 0.6
			DrawRect(15,215, 380, 200)
			SetAlpha 1.0
			SetColor 255,255,255
			GetBitmapFont("default", 12).Draw("RefillMode:" + GameRules.adagencyRefillMode, 20, 220)
			GetBitmapFont("default", 12).Draw("Durchschnittsquoten:", 20, 240)
			Local y:Int = 260
			Local filterNum:Int = 0
			For Local filter:TAdContractBaseFilter = EachIn levelFilters
				filterNum :+ 1
				Local title:String = "#"+filterNum
				Select filterNum
					Case 1	title = "Schlechtester (Tag):~t"
					Case 2	title = "Schlechtester (Prime):"
					Case 3	title = "Durchschnitt (Tag):~t"
					Case 4	title = "Durchschnitt (Prime):"
					Case 5	title = "Bester Spieler (Tag):~t"
					Case 6	title = "Bester Spieler (Prime):"
				End Select
				GetBitmapFont("default", 12).Draw(title+"~tMinAudience = " + MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"% - "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"%", 20, y)
				If filterNum Mod 2 = 0 Then y :+ 4
				y:+ 13
			Next
endrem
	End Method


	Method UpdateBlock_AdAgencyOffers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		'reset
		offerHightlight = null

		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local adAgency:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()
		textY :+ 12 + 10 + 5

		local adLists:TAdContract[][] = [adAgency.listNormal, adAgency.listCheap]
		local entryPos:int = 0
		For local listNumber:int = 0 until adLists.length
			local ads:TAdContract[] = adLists[listNumber]
			textY :+ 10
			For local i:int = 0 until ads.length
				if THelper.MouseIn(textX, textY, 240, 10)
					offerHightlight = ads[i]
					exit
				endif

				textY :+ 10
				entryPos :+ 1
			Next
			if offerHightlight then exit
		Next
	End Method


	Method RenderBlock_AdAgencyOffers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local adAgency:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()

		titleFont.draw("AdAgency", textX, textY - 1)
		textY :+ 12
		textFont.Draw("Refilled on figure visit.", textX, textY - 1)
		textY :+ 10
		textY :+ 5

		local adlistTitle:String[] = ["Normal", "Cheap"]
		local adLists:TAdContract[][] = [adAgency.listNormal, adAgency.listCheap]
		local entryPos:int = 0
		local oldAlpha:Float = GetAlpha()
		For local listNumber:int = 0 until adLists.length
			local ads:TAdContract[] = adLists[listNumber]

			textFontBold.Draw(adListTitle[listNumber] + ":", textX, textY - 1)
			textY :+ 10
			For local i:int = 0 until ads.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, textY, 240, 10)

				SetColor 255,255,255
				SetAlpha oldAlpha

				if ads[i] and ads[i] = offerHightlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, textY, 240, 10)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				endif

				textFont.DrawSimple(RSet(i, 2).Replace(" ", "0"), textX, textY - 1)
				if ads[i]
					textFont.DrawBox(": " + ads[i].GetTitle(), textX + 15, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
					textFont.DrawSimple(MathHelper.DottedValue(ads[i].GetMinAudience(playerID)), textX + 15 + 120, textY - 1)
					if ads[i].GetLimitedToTargetGroup() > 0
						textFont.DrawBox(ads[i].GetLimitedToTargetGroupString(), textX + 15 + 120, textY - 1, 100, 15, sALIGN_RIGHT_TOP, SColor8.White)
					else
						SetAlpha 0.5
						textFont.DrawBox("no limit", textX + 15 + 120, textY - 1, 100, 15, sALIGN_RIGHT_TOP, SColor8.White)
						SetAlpha oldAlpha
					endif
				else
					textFont.DrawSimple(": -", textX + 15, textY - 1)
				endif
				textY :+ 10

				entryPos :+ 1
			Next
			textY :+ 5
		Next
	End Method
End Type