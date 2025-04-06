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

		DrawBorderRect(position.x + 510, 13, 160, 80)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		RenderBlock_FinancialInfo(-1, position.x + 5, position.y + 20)

		RenderBlock_PlayerBudgets(playerID, position.x + 5, position.y + 150)
	End Method


	Method RenderBlock_PlayerBudgets(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)

		If player.playerAI
			Local colWidth:Int = 45
			Local labelWidth:Int = 80
			Local padding:Int = 15
			Local boxWidth:Int = labelWidth + padding + colWidth*4 + 2 '2 is border*2

			DrawBorderRect(x, y, boxWidth, 140)

			Local textX:Int = x + 3
			Local textY:Int = y + 3 - 1

			textFont.Draw("Investment Savings: " + MathHelper.DottedValue(player.aiData.GetInt("budget_investmentsavings")), textX, textY)
			textY :+ 10
			textFont.Draw("Savings Part: " + MathHelper.DottedValue(player.aiData.GetFloat("budget_savingpart")*100)+"%", textX, textY)
			textY :+ 10
			textFont.Draw("Extra fixed costs savings percentage: " + MathHelper.DottedValue(player.aiData.GetFloat("budget_extrafixedcostssavingspercentage")*100)+"%", textX, textY)
			textY :+ 10

			textFontBold.Draw("Budget List: ", textX, textY)
			textFontBold.Draw("Current", textX + labelWidth + padding + colWidth*0, textY)
			textFontBold.Draw("Max", textX + labelWidth + padding + colWidth*1, textY)
			textFontBold.Draw("Day", textX + labelWidth + padding + colWidth*2, textY)
			textFontBold.Draw("FixCosts", textX + labelWidth + padding + colWidth*3, textY)
			textY :+ 10 + 2

			For Local taskNumber:Int = 1 To player.aiData.GetInt("budget_task_count", 1)
				textFont.Draw(player.aiData.GetString("budget_task_name"+taskNumber).Replace("Task", ""), textX, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_currentbudget"+taskNumber)), textX + labelWidth + padding + colWidth*0, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_budgetmaximum"+taskNumber)), textX + labelWidth + padding + colWidth*1, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_budgetwholeday"+taskNumber)), textX + labelWidth + padding + colWidth*2, textY)
				textFont.Draw(MathHelper.DottedValue(player.aiData.GetInt("budget_task_fixcosts"+taskNumber)), textX + labelWidth + padding + colWidth*3, textY)
				textY :+ 10
			Next
		EndIf
	End Method


	Method RenderBlock_FinancialInfo(playerID:Int, x:Int, y:Int)
		If playerID = -1
			RenderBlock_FinancialInfo(1, x, y + 30*0)
			RenderBlock_FinancialInfo(2, x, y + 30*1)
			RenderBlock_FinancialInfo(3, x + 125, y + 30*0)
			RenderBlock_FinancialInfo(4, x + 125, y + 30*1)
			Return
		EndIf

		DrawBorderRect(x, y, 123, 35)

		Local textX:Int = x+1
		Local textY:Int = y+1

		Local finance:TPlayerFinance = GetPlayerFinanceCollection().GetIgnoringStartDay(playerID, GetWorldTime().GetDay())
		Local financeTotal:TPlayerFinance = GetPlayerFinanceCollection().GetTotal(playerID)

		Local font:TBitmapfont = GetBitmapFont("default", 9)
		font.Draw("Money #"+playerID+": "+MathHelper.DottedValue(finance.money), textX, textY)
		textY :+ 9+1
		font.Draw("~tLic:~t~t|color=120,255,120|"+MathHelper.DottedValue(finance.income_programmeLicences)+"|/color| / |color=255,120,120|"+MathHelper.DottedValue(finance.expense_programmeLicences), textX, textY)
		textY :+ 9
		font.Draw("~tAd:~t~t|color=120,255,120|"+MathHelper.DottedValue(finance.income_ads)+"|/color| / |color=255,120,120|"+MathHelper.DottedValue(finance.expense_penalty), textX, textY)
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
