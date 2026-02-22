SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.player.bmx"

Type TDebugScreenPage_PlayerFinancials extends TDebugScreenPage
	Global _instance:TDebugScreenPage_PlayerFinancials


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_PlayerFinancials()
		If Not _instance Then new TDebugScreenPage_PlayerFinancials
		Return _instance
	End Function


	Method Init:TDebugScreenPage_PlayerFinancials()
		Local texts:String[] = ["Set Player 1 Bankrupt", "Set Player 2 Bankrupt", "Set Player 3 Bankrupt", "Set Player 4 Bankrupt"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler
			'custom position
			button.x = position.x + 510 + 3
			button.y = 14 + 2 + i * (button.h + 2)


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
		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		DrawWindow(position.x + 510, 13, 155, 100, "Manipulate")
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		RenderBlock_FinancialInfo(-1, position.x, position.y)

		RenderBlock_PlayerBudgets(playerID, position.x, position.y + 200)
	End Method


	Method RenderBlock_PlayerBudgets(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			Local colWidth:Int = 57
			Local labelWidth:Int = 80
			Local padding:Int = 15
			Local boxWidth:Int = labelWidth + padding + colWidth*4 + 2 '2 is border*2

			Local contentRect:SRectI = DrawWindow(x, y, boxWidth, 150, "Budget #" + playerID)

			Local textY:Int = contentRect.y

			textFont.DrawBox("Investment Savings: " + TFunctions.DottedValue(player.aiData.GetInt("budget_investmentsavings")), contentRect.x, textY, contentRect.w, 30, SALIGN_LEFT_TOP, SCOLOR8.WHITE)
			textY :+ textFont.DrawBox("Savings Part: " + TFunctions.DottedValue(player.aiData.GetFloat("budget_savingpart")*100)+"%", contentRect.x, textY, contentRect.w, 30, SALIGN_RIGHT_TOP, SCOLOR8.WHITE).y
			textY :+ textFont.DrawBox("Extra fixed costs savings: " + TFunctions.DottedValue(player.aiData.GetFloat("budget_extrafixedcostssavingspercentage")*100)+"%", contentRect.x, textY, contentRect.w, 30, SALIGN_RIGHT_TOP, SCOLOR8.WHITE).y

			textFontBold.Draw("Budget List: ", contentRect.x, textY)
			textFontBold.Draw("Current", contentRect.x + labelWidth + padding + colWidth*0, textY)
			textFontBold.Draw("Max", contentRect.x + labelWidth + padding + colWidth*1, textY)
			textFontBold.Draw("Day", contentRect.x + labelWidth + padding + colWidth*2, textY)
			textFontBold.Draw("FixCosts", contentRect.x + labelWidth + padding + colWidth*3, textY)
			textY :+ 10 + 2

			For Local taskNumber:Int = 1 To player.aiData.GetInt("budget_task_count", 1)
				textFont.Draw(player.aiData.GetString("budget_task_name"+taskNumber).Replace("Task", ""), contentRect.x, textY)
				textFont.Draw(TFunctions.DottedValue(player.aiData.GetInt("budget_task_currentbudget"+taskNumber)), contentRect.x + labelWidth + padding + colWidth*0, textY)
				textFont.Draw(TFunctions.DottedValue(player.aiData.GetInt("budget_task_budgetmaximum"+taskNumber)), contentRect.x + labelWidth + padding + colWidth*1, textY)
				textFont.Draw(TFunctions.DottedValue(player.aiData.GetInt("budget_task_budgetwholeday"+taskNumber)), contentRect.x + labelWidth + padding + colWidth*2, textY)
				textFont.Draw(TFunctions.DottedValue(player.aiData.GetInt("budget_task_fixcosts"+taskNumber)), contentRect.x + labelWidth + padding + colWidth*3, textY)
				textY :+ 11
			Next
		EndIf
	End Method


	Method RenderBlock_FinancialInfo(playerID:Int, x:Int, y:Int)
		Local windowW:Int = 160
		Local windowH:Int = 95

		If playerID = -1
			RenderBlock_FinancialInfo(1, x, y + (windowH + 5)*0)
			RenderBlock_FinancialInfo(2, x, y + (windowH + 5)*1)
			RenderBlock_FinancialInfo(3, x + windowW + 5, y + (windowH + 5)*0)
			RenderBlock_FinancialInfo(4, x + windowW + 5, y + (windowH + 5)*1)
			Return
		EndIf

		Local finance:TPlayerFinance = GetPlayerFinanceCollection().GetIgnoringStartDay(playerID, GetWorldTime().GetDay())
		Local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(playerID)

		Local contentRect:SRectI = DrawWindow(x, y, windowW, windowH, "Money #" + playerID, TFunctions.DottedValue(finance.money))

		Local textY:Int = contentRect.y
		Local font:TBitmapfont = GetBitmapFont("default", 9)

		textY :+ DrawEntry("Licences:", finance.income_programmeLicences, finance.expense_programmeLicences, font, contentRect.x, textY, contentRect.w)
		textY :+ DrawEntry("Ads:", finance.income_ads, finance.expense_penalty, font, contentRect.x, textY, contentRect.w)
		textY :+ DrawEntry("Stations:", finance.income_stations, finance.expense_stations, font, contentRect.x, textY, contentRect.w)
		textY :+ DrawEntry("Station Fees:", -1, finance.expense_stationFees, font, contentRect.x, textY, contentRect.w)
		textY :+ DrawEntry("News:", -1, finance.expense_news, font, contentRect.x, textY, contentRect.w)
		textY :+ DrawEntry("News Fees:", -1, finance.expense_newsAgencies, font, contentRect.x, textY, contentRect.w)
		
		Function DrawEntry:Int(title:String, income:Long, expense:Long, font:TBitmapFont, x:Int, y:Int, w:Int)
			Local dy:Int
			dy = Max(dy, font.Draw(title, x, y).y)
			if income >= 0 'minus allows to hide it
				dy = Max(dy, font.DrawBox(TFunctions.DottedValue(income), x + w - 95, y, 45, 20, SALIGN_RIGHT_TOP, New SColor8(120,255,120)).y)
			EndIf
			If expense >= 0 'minus allows to hide it
				dy = Max(dy, font.DrawBox(TFunctions.DottedValue(expense), x + w - 45, y, 45, 20, SALIGN_RIGHT_TOP, New SColor8(255,120,120)).y)
			EndIf
			Return dy
		End Function
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				GetGame().SetPlayerBankrupt(1)
			case 1
				GetGame().SetPlayerBankrupt(2)
			case 2
				GetGame().SetPlayerBankrupt(3)
			case 3
				GetGame().SetPlayerBankrupt(4)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
