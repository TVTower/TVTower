SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.roomhandler.adagency.bmx"

Type TDebugScreenPage_Adagency extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Adagency
	Field offerHightlight:TAdContract


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Adagency()
		If Not _instance Then new TDebugScreenPage_Adagency
		Return _instance
	End Function


	Method Init:TDebugScreenPage_AdAgency()
		Local texts:String[] = ["Refill Offers", "Replace All Offers", "Replace Offers", "Change Mode"]
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
		For Local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Method Reset()
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		UpdateBlock_AdAgencyOffers(playerID, position.x + 5, position.y + 3, 300, 230)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method UpdateBlock_AdAgencyOffers(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		Local adAgency:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()

		'reset
		offerHightlight = null

		Local textX:Int = x + 2
		Local textY:Int = y + 20 + 2

		Local adLists:TAdContract[][] = [adAgency.listNormal, adAgency.listCheap]
		Local entryPos:Int = 0
		For Local listNumber:Int = 0 Until adLists.length
			Local ads:TAdContract[] = adLists[listNumber]
			textY :+ 12
			For Local i:Int = 0 Until ads.length
				If THelper.MouseIn(textX, textY, 290, 11)
					offerHightlight = ads[i]
					Exit
				EndIf

				textY :+ 11
				entryPos :+ 1
			Next
			If offerHightlight Then Exit
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		RenderBlock_AdAgencyOffers(playerID, position.x + 5, position.y + 3, 300, 230)
		'RenderBlock_AdAgencyInformation(playerID, position.x + 5 + 250 + 5, position.y + 3)
		RenderBlock_PlayerAdContractInformation(playerID, position.x + 5 + 300 + 5, position.y + 3)

		DrawBorderRect(position.x + 510, 13, 160, 83)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		If offerHightlight
			offerHightlight.ShowSheet(position.x + 5 + 300, position.y + 3, 0, TVTBroadcastMaterialType.ADVERTISEMENT, playerID, null)
		EndIf
	End Method


	Method RenderBlock_PlayerAdContractInformation(playerID:Int, x:Int, y:Int, w:Int = 170, h:Int = 180)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Player contracts")
		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y

		Local oldAlpha:Float = GetAlpha()
		Local oldCol:SColor8; GetColor(oldCol)

		textY :+ textFontBold.Draw("Normal", textX, textY).y
		textY :+ 2
		
		Local slot:Int = 1
		For Local adContract:TAdContract = EachIn GetPlayerProgrammeCollection(playerID).adContracts
			If slot Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(textX, textY + 1, contentRect.w, 11)

			SetColor oldCol
			SetAlpha oldAlpha

			textFont.Draw(slot + ":", textX, textY)
			textFont.Draw(adContract.GetTitle(), textX + 15, textY)
			slot :+ 1
			textY :+ 11
		Next

		textY :+ 10

		textY :+ textFontBold.Draw("Suitcase", textX, textY).y
		textY :+ 2

		Local suitCasePos:Int = 1
		For Local adContract:TAdContract = EachIn GetPlayerProgrammeCollection(playerID).suitcaseAdContracts
			If suitCasePos Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(textX, textY + 1, contentRect.w, 11)

			SetColor oldCol
			SetAlpha oldAlpha

			textFont.Draw(suitCasePos + ":", textX, textY)
			textFont.Draw(adContract.GetTitle(), textX + 15, textY)
			suitCasePos :+ 1
			slot :+ 1
			textY :+ 11
		Next
	End Method


	Method RenderBlock_AdAgencyInformation(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
'		DrawBorderRect(x, y, w, h)
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


	Method RenderBlock_AdAgencyOffers(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		Local adAgency:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()

		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Adagency offers", "(Refilled on figure visit)")
		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y + 5

		Local adlistTitle:String[] = ["Normal", "Cheap"]
		Local adLists:TAdContract[][] = [adAgency.listNormal, adAgency.listCheap]
		Local entryPos:Int = 0
		Local oldAlpha:Float = GetAlpha()
		For Local listNumber:Int = 0 Until adLists.length
			Local ads:TAdContract[] = adLists[listNumber]

			textFontBold.Draw(adListTitle[listNumber] + ":", textX, textY - 1)
			textY :+ 12
			For Local i:Int = 0 Until ads.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, textY, 290, 11)

				SetColor 255,255,255
				SetAlpha oldAlpha

				If ads[i] And ads[i] = offerHightlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, textY, 290, 11)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				EndIf

				textFont.DrawSimple(RSet(i, 2).Replace(" ", "0"), textX, textY - 1)
				If ads[i]
					textFont.DrawBox(": " + ads[i].GetTitle(), textX + 15, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
					textFont.DrawSimple(MathHelper.DottedValue(ads[i].GetMinAudience(playerID)), textX + 15 + 120, textY - 1)
					If ads[i].GetLimitedToTargetGroup() > 0
						textFont.DrawBox(ads[i].GetLimitedToTargetGroupString(), textX + 15 + 170, textY - 1, 100, 15, sALIGN_RIGHT_TOP, SColor8.White)
					Else
						SetAlpha 0.5
						textFont.DrawBox("no limit", textX + 15 + 170, textY - 1, 100, 15, sALIGN_RIGHT_TOP, SColor8.White)
						SetAlpha oldAlpha
					EndIf
				Else
					textFont.DrawSimple(": -", textX + 15, textY - 1)
				EndIf
				textY :+ 11

				entryPos :+ 1
			Next
			textY :+ 5
		Next
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				RoomHandler_AdAgency.GetInstance().ReFillBlocks()
			Case 1
				RoomHandler_AdAgency.GetInstance().ReFillBlocks(True, 1.0)
			Case 2
				RoomHandler_AdAgency.GetInstance().ReFillBlocks(True, GameRules.refillAdAgencyPercentage)
			Case 3
				If RoomHandler_AdAgency.GetInstance()._setRefillMode = 10
					RoomHandler_AdAgency.GetInstance().SetRefillMode(11)
					GetInstance().UpdateAdAgencyModeButton()
				ElseIf RoomHandler_AdAgency.GetInstance()._setRefillMode = 11
					RoomHandler_AdAgency.GetInstance().SetRefillMode(12)
					GetInstance().UpdateAdAgencyModeButton()
				Else
					RoomHandler_AdAgency.GetInstance().SetRefillMode(10)
					GetInstance().UpdateAdAgencyModeButton()
				EndIf
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Method UpdateAdAgencyModeButton()
		Local cm:Int = RoomHandler_AdAgency.GetInstance()._setRefillMode
		Select cm
			Case 10 buttons[3].text = "Change Mode "+cm+" -> conservative"
			Case 11 buttons[3].text = "Change Mode "+cm+" -> bold"
			Case 12 buttons[3].text = "Change Mode "+cm+" -> random"
		End Select
	End Method
End Type
