SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.newsagency.bmx"

Type TDebugScreenPage_ScriptAgency extends TDebugScreenPage
	Global _instance:TDebugScreenPage_ScriptAgency
	Field scriptAgencyOfferHightlight:TScript


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_ScriptAgency()
		If Not _instance Then new TDebugScreenPage_ScriptAgency
		Return _instance
	End Function


	Method Init:TDebugScreenPage_ScriptAgency()
		Local texts:String[] = ["Refill Offers", "Replace Offers"]
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

		UpdateScriptAgencyOffers(playerID, position.x + 5, 13 + 45 + 5)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method UpdateScriptAgencyOffers(playerID:Int, x:Int, y:Int, w:Int = 400, h:Int = 150)
		scriptAgencyOfferHightlight = null

		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textY :+ 15
		If Not scriptAgencyOfferHightlight
			For Local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
				If Not script.isOwnedByVendor() Continue
				If THelper.MouseIn(textX, textY, 230, 13)
					scriptAgencyOfferHightlight = script
					Exit
				EndIf
				textY:+ 13
			Next
		EndIf

'		textY = y + 5
'		textX :+ 200
		textY :+ 15
		If Not scriptAgencyOfferHightlight
			For Local script:TScript = EachIn GetScriptCollection().GetAvailableScriptList()
				If THelper.MouseIn(textX, textY, 230, 13)
					scriptAgencyOfferHightlight = script
					Exit
				EndIf
				textY:+ 13
			Next
		EndIf

	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		RenderScriptAgencyInformation(playerID, position.x + 5, 13, , 45)
		RenderScriptAgencyOffers(playerID, position.x + 5, 13 + 45 + 5)

		DrawBorderRect(position.x + 510, 13, 160, 45)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		If scriptAgencyOfferHightlight
			scriptAgencyOfferHightlight.ShowSheet(position.x + 5 + 450, 13, 0, -1)
		EndIf
	End Method


	Method RenderScriptAgencyInformation(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 30)
		DrawBorderRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		textFont.DrawSimple("Offer refill: " + GetGameBase().refillScriptAgencyTime +"min", x, y)
	End Method


	Method RenderScriptAgencyOffers(playerID:Int, x:Int, y:Int, w:Int = 500, h:Int = 150)
		DrawBorderRect(x, y, w, h + 120)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		Local entryNum:Int = 0
		Local oldAlpha:Float = GetAlpha()
		Local barWidth:Int = 230

		textFontBold.Draw("Offered:", textX, textY)
		textY :+ 14
		For Local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
			If Not script.isOwnedByVendor() Then Continue
			RenderScript(script, entryNum, textX, textY, barWidth, oldAlpha, scriptAgencyOfferHightlight, True)
			textY:+ 13
			entryNum :+ 1
		Next

		textY:+ 5
		textFontBold.Draw("Available:", textX, textY)
		textY :+ 15
		entryNum = 0
		For Local script:TScript = EachIn GetScriptCollection().GetAvailableScriptList()
			RenderScript(script, entryNum, textX, textY, barWidth, oldAlpha, scriptAgencyOfferHightlight)
			textY:+ 13
			entryNum :+ 1
		Next

		textY = y + 5
		textX :+ 250
		textFontBold.Draw("Player owned:", textX, textY)
		textY :+ 15
		entryNum = 0
		For Local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
			If Not script.IsOwnedByPlayer(GetShownPlayerID()) Then Continue
			RenderScript(script, entryNum, textX, textY, barWidth, oldAlpha, scriptAgencyOfferHightlight)
			textY:+ 13
			entryNum :+ 1
		Next

		Function RenderScript(script:TScript, entryNum:Int, textX:Int, textY:Int, barWidth:Int, oldAlpha:Float, scriptAgencyOfferHightlight:Tscript, checkAgencyList:Int = False)
			If entryNum Mod 2 = 0
				SetColor 0,0,0
			Else
				SetColor 60,60,60
			EndIf
			SetAlpha 0.75 * oldAlpha
			DrawRect(textX, textY, barWidth, 12)

			SetColor 255,255,255
			SetAlpha oldAlpha

			If script = scriptAgencyOfferHightlight
				SetAlpha 0.25 * oldAlpha
				SetBlend LIGHTBLEND
				DrawRect(textX, textY, barWidth, 12)
				SetAlpha oldAlpha
				SetBlend ALPHABLEND
			EndIf

			If checkAgencyList And Not RoomHandler_ScriptAgency.GetInstance().HasScript(script)
				SetColor 200, 0, 0
				textFont.DrawSimple("[NOT IN LIST] " + script.GetTitle(), textX, textY - 2)
				SetColor 255, 255, 255
			Else
				textFont.DrawSimple(script.GetTitle(), textX, textY - 2)
			EndIf
		End Function
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				RoomHandler_ScriptAgency.GetInstance().ReFillBlocks()
			Case 1
				RoomHandler_ScriptAgency.GetInstance().ReFillBlocks(True, 1.0)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
