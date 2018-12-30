SuperStrict

Import "game.roomhandler.base.bmx"
Import "game.screen.programmeplanner.bmx"
Import "game.screen.stationmap.bmx"
Import "game.screen.achievements.bmx"
Import "game.screen.archivedmessages.bmx"
Import "game.screen.statistics.bmx"
Import "game.gameconfig.bmx"

Import "game.misc.archivedmessage.bmx"

Type TScreenHandler_Financials
	global financePreviousDayButton:TGUIArrowButton
	global financeNextDayButton:TGUIArrowButton
	global financeHistoryDownButton:TGUIArrowButton
	global financeHistoryUpButton:TGUIArrowButton
	Global financeHistoryStartPos:int = 0
	Global financeShowDay:int = 0
	Global clTypes:TColor[6]

	Global labelBGs:TSprite[6]
	Global balanceValueBG:TSprite
	Global balanceValueBG2:TSprite

	Global _eventListeners:TLink[]


	Function Initialize:int()
		local screen:TInGameScreen = TInGameScreen(ScreenCollection.GetScreen("screen_office_financials"))
		if not screen then return False

		'create finance entry colors
		clTypes[TVTPlayerFinanceEntryType.GROUP_NEWS] = new TColor.Create(0, 31, 83)
		clTypes[TVTPlayerFinanceEntryType.GROUP_PROGRAMME] = new TColor.Create(89, 40, 0)
		clTypes[TVTPlayerFinanceEntryType.GROUP_DEFAULT] = new TColor.Create(30, 30, 30)
		clTypes[TVTPlayerFinanceEntryType.GROUP_PRODUCTION] = new TColor.Create(44, 0, 78)
		clTypes[TVTPlayerFinanceEntryType.GROUP_STATION] = new TColor.Create(0, 75, 69)


		'=== create gui elements if not done yet
		if not financeHistoryUpButton
			financeHistoryUpButton = new TGUIArrowButton.Create(new TVec2D.Init(500 + 20, 180), new TVec2D.Init(130, 22), "DOWN", "officeFinancialScreen")
			financeHistoryDownButton = new TGUIArrowButton.Create(new TVec2D.Init(500 + 130 + 20, 180), new TVec2D.Init(130, 22), "UP", "officeFinancialScreen")

			financeHistoryUpButton.spriteButtonBaseName = "gfx_gui_button.roundedMore"
			financeHistoryDownButton.spriteButtonBaseName = "gfx_gui_button.roundedMore"

			financePreviousDayButton = new TGUIArrowButton.Create(new TVec2D.Init(20, 10 + 11), new TVec2D.Init(24, 24), "LEFT", "officeFinancialScreen")
			financeNextDayButton = new TGUIArrowButton.Create(new TVec2D.Init(20 + 175 + 20, 10 + 11), new TVec2D.Init(24, 24), "RIGHT", "officeFinancialScreen")
		endif


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		'to listen to clicks on the four buttons
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickFinanceButtons, "TGUIArrowButton") ]
		'to reset finance history scroll position when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterFinancialScreen, screen) ]

		'to update/draw the screens
		_eventListeners :+ TRoomHandler._RegisterScreenHandler( onUpdateFinancials, onDrawFinancials, screen)

		'(re-)localize content
		SetLanguage()
	End Function


	Function SetLanguage()
		'nothing up to now
	End Function


	'=== EVENTS ===

	'reset finance history scrolling position when entering the screen
	'reset finance show day to current when entering the screen
	Function onEnterFinancialScreen:int( triggerEvent:TEventBase )
		financeHistoryStartPos = 0
		financeShowDay = GetWorldTime().GetDay()
	End function


global LS_officeFinancialScreen:TLowerString = TLowerString.Create("officeFinancialScreen")
	Function onDrawFinancials:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'limit finance day between 0 and current day
		financeShowDay = Max(0, Min(financeShowDay, GetWorldTime().GetDay()))


		local screenOffsetX:int = 20
		local screenOffsetY:int = 10

		local finance:TPlayerFinance = GetPlayerFinanceCollection().GetIgnoringStartDay(room.owner, financeShowDay)

		local captionColor:TColor = new TColor.CreateGrey(70)
		local captionFont:TBitmapFont = GetBitmapFont("Default", 14, BOLDFONT)
		local captionHeight:int = 20 'to center it to table header according "font Baseline"
		local textFont:TBitmapFont = GetBitmapFont("Default", 14)
		local logFont:TBitmapFont = GetBitmapFont("Default", 12)
		local textSmallFont:TBitmapFont = GetBitmapFont("Default", 11)
		local textBoldFont:TBitmapFont = GetBitmapFont("Default", 14, BOLDFONT)

		local clLog:TColor = new TColor.CreateGrey(50)


		local clOriginal:TColor = new TColor.Get()


		'=== BANKRUPTCY HINT ===
		'showing something before that player started
		if GetPlayerFinanceCollection().GetPlayerStartDay(room.owner) > financeShowDay
			local midnight:Long = GetWorldTime().MakeTime(0, financeShowDay+1, 0, 0, 0)
			local bankruptcyCountAtMidnight:int = GetPlayer(room.owner).GetBankruptcyAmount(midnight)
			local bankruptcyCountAtDayBegin:int = GetPlayer(room.owner).GetBankruptcyAmount(midnight - TWorldTime.DAYLENGTH)
			local bankruptcyCount:int = 4
		'bankruptcy happened today?
'		if bankruptcyCountAtMidnight > 0

			textFont.DrawBlock(GetLocale("BEFORE_XTH_PLAYER_RESTART").Replace("%X%", (bankruptcyCountAtMidnight+1)), 250 + screenOffsetX, screenOffsetY - 10, 200, 20, ALIGN_CENTER_CENTER, TColor.Create(120,80,80), 2, 1, 0.2)
			'tint color
			SetColor 255,240,240
		endif



		'=== DAY CHANGER ===
		'add 1 to "today" as we are on this day then
		local today:Double = GetWorldTime().MakeTime(0, financeShowDay, 0, 0)
		local todayText:string = GetWorldTime().GetDayOfYear(today)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().GetYear(today)
		textFont.DrawBlock(GetLocale("GAMEDAY")+" "+todayText, 30 + screenOffsetX, 15 +  screenOffsetY, 160, 20, ALIGN_CENTER_CENTER, TColor.CreateGrey(90), 2, 1, 0.2)


		'=== NEWS LOG ===
		captionFont.DrawBlock(GetLocale("FINANCES_LAST_FINANCIAL_ACTIVITIES"), 500 + screenOffsetX, 13 + screenOffsetY,  240, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)
		local list:TList = GetPlayerFinanceHistoryList(room.owner)
		local logSlot:int = 0
		local logH:int = 19
		local history:TPlayerFinanceHistoryEntry
		local logCol:string = ""

		'limit log
		financeHistoryStartPos = Max(0, Min(list.Count()-1 - 6, financeHistoryStartPos))

		For local i:int = financeHistoryStartPos to Min(financeHistoryStartPos + 6, list.Count()-1)
			history = TPlayerFinancehistoryEntry(list.ValueAtIndex(i))
			if not history then continue

			GetSpriteFromRegistry("screen_financial_newsLog"+history.GetTypeGroup()).DrawArea(501 + screenOffsetX, 39 + screenOffsetY + logSlot*logH , 258, logH)
			if history.GetMoney() < 0
				logCol = "color=190,30,30"
			else
				logCol = "color=35,130,30"
			Endif
			'ronny: do not "abs()" the value - this helps color-blind
			'       people to distinguish positive and negative
			logFont.DrawBlock("|"+logCol+"|"+MathHelper.DottedValue(history.GetMoney())+" "+getLocale("CURRENCY")+"|/color| "+history.GetDescription(), 501 + screenOffsetX + 5, 41 + screenOffsetY + logSlot*logH, 258 - 2*5, logH, ALIGN_LEFT_CENTER, clLog)
			'logFont.DrawBlock("|"+logCol+"|"+MathHelper.DottedValue(abs(history.GetMoney()))+" "+getLocale("CURRENCY")+"|/color| "+history.GetDescription(), 501 + screenOffsetX + 5, 41 + screenOffsetY + logSlot*logH, 258 - 2*5, logH, ALIGN_LEFT_CENTER, clLog)
			logSlot:+1
		Next



		'=== BALANCE TABLE ===

		local labelX:int = 20
		local labelStartY:int = 39 + screenOffsetY
		local labelH:int = 19, labelW:int = 240

		local valueIncomeX:int = labelX + labelW
		local valueExpenseX:int = valueIncomeX + 120
		local valueStartY:int = 39 + screenOffsetY
		local valueH:int = 19, valueW:int = 95

		'draw balance table
		captionFont.DrawBlock(GetLocale("FINANCES_INCOME"), 240 + screenOffsetX, 13 + screenOffsetY,  104, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)
		captionFont.DrawBlock(GetLocale("FINANCES_EXPENSES"), 352 + screenOffsetX, 13 + screenOffsetY,  104, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)

		'draw total-area
		local profit:int = finance.revenue_after - finance.revenue_before
		if profit >= 0
			GetSpriteFromRegistry("screen_financial_positiveBalance").DrawArea(250 + screenOffsetX, 332 + screenOffsetY, 200, 25)
		else
			GetSpriteFromRegistry("screen_financial_negativeBalance").DrawArea(250 + screenOffsetX, 332 + screenOffsetY, 200, 25)
		endif
		captionFont.DrawBlock(MathHelper.DottedValue(profit), 250 + screenOffsetX, 332 + screenOffsetY, 200, 25, ALIGN_CENTER_CENTER, TColor.clWhite, 2, 1, 0.75)

		'draw label backgrounds
		local labelBGX:int = 20
		local labelBGW:int = 240
		local valueBGX:int = labelBGX + labelBGW + 1

		for local i:int = 1 to 5
			if not labelBGs[i] then labelBGs[i] = GetSpriteFromRegistry("screen_financial_balanceLabel"+i)
		Next

		labelBGs[TVTPlayerFinanceEntryType.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 0*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 1*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 2*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_PROGRAMME].DrawArea(labelBGX, labelStartY + 3*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_NEWS].DrawArea(labelBGX, labelStartY + 4*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_NEWS].DrawArea(labelBGX, labelStartY + 5*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_STATION].DrawArea(labelBGX, labelStartY + 6*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_PRODUCTION].DrawArea(labelBGX, labelStartY + 7*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_PRODUCTION].DrawArea(labelBGX, labelStartY + 8*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_PRODUCTION].DrawArea(labelBGX, labelStartY + 9*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 10*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 11*valueH, labelBGW, labelH)
		labelBGs[TVTPlayerFinanceEntryType.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 12*valueH, labelBGW, labelH)

		labelBGs[TVTPlayerFinanceEntryType.GROUP_DEFAULT].DrawArea(labelBGX, labelStartY + 14*valueH +4, labelBGW, labelH)

		'draw value backgrounds
		if not balanceValueBG then balanceValueBG = GetSpriteFromRegistry("screen_financial_balanceValue")
		if not balanceValueBG2 then balanceValueBG2 = GetSpriteFromRegistry("screen_financial_balanceValue2")
		for local i:int = 0 to 12
			if i mod 2 = 0
				balanceValueBG.DrawArea(valueBGX, labelStartY + i*valueH, balanceValueBG.GetWidth(), labelH)
			else
				balanceValueBG2.DrawArea(valueBGX, labelStartY + i*valueH, balanceValueBG.GetWidth(), labelH)
			endif
		Next
		balanceValueBG.DrawArea(valueBGX, labelStartY + 14*valueH + 4, balanceValueBG.GetWidth(), labelH)

		'draw balance labels
		textFont.DrawBlock(GetLocale("FINANCES_TRADING_PROGRAMMELICENCES"), labelX, labelStartY + 0*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_AD_INCOME__CONTRACT_PENALTY"), labelX, labelStartY + 1*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_CALL_IN_SHOW_INCOME"), labelX, labelStartY + 2*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_SPONSORSHIP_INCOME__PENALTY"), labelX, labelStartY + 3*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PROGRAMME])
		textFont.DrawBlock(GetLocale("FINANCES_NEWS"), labelX, labelStartY + 4*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_NEWS])
		textFont.DrawBlock(GetLocale("FINANCES_NEWSAGENCIES"), labelX, labelStartY + 5*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_NEWS])
		textFont.DrawBlock(GetLocale("FINANCES_STATIONS"), labelX, labelStartY + 6*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_STATION])
		textFont.DrawBlock(GetLocale("FINANCES_SCRIPTS"), labelX, labelStartY + 7*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PRODUCTION])
		textFont.DrawBlock(GetLocale("FINANCES_ACTORS_AND_PRODUCTIONSTUFF"), labelX, labelStartY + 8*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PRODUCTION])
		textFont.DrawBlock(GetLocale("FINANCES_STUDIO_RENT"), labelX, labelStartY + 9*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_PRODUCTION])
		textFont.DrawBlock(GetLocale("FINANCES_INTEREST_BALANCE__CREDIT"), labelX, labelStartY + 10*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_DEFAULT])
		textFont.DrawBlock(GetLocale("FINANCES_CREDIT_TAKEN__REPAYED"), labelX, labelStartY + 11*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_DEFAULT])
		textFont.DrawBlock(GetLocale("FINANCES_MISC"), labelX, labelStartY + 12*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_DEFAULT])
		'spacer for total
		textBoldFont.DrawBlock(GetLocale("FINANCES_TOTAL"), labelX, labelStartY + 14*valueH+4, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_DEFAULT])


		'draw "grouped"-info-sign
		GetSpriteFromRegistry("screen_financial_balanceInfo").Draw(valueBGX, labelStartY + 1 + 6*valueH)

		'draw balance values: income
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_programmeLicences), valueIncomeX, valueStartY + 0*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_ads), valueIncomeX, valueStartY + 1*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_callerRevenue), valueIncomeX, valueStartY + 2*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_sponsorshipRevenue), valueIncomeX, valueStartY + 3*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		'news: generate no income
		'newsagencies: generate no income
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_stations), valueIncomeX, valueStartY + 6*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_scripts), valueIncomeX, valueStartY + 7*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		'actors and productionstuff: generate no income
		'studios: generate no income
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_balanceInterest), valueIncomeX, valueStartY + 10*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_creditTaken), valueIncomeX, valueStartY + 11*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		'misc contains "granted benefits"
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_misc + finance.income_granted_benefits), valueIncomeX, valueStartY + 12*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
		'spacer for total
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_total), valueIncomeX, valueStartY + 14*valueH +4, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)


		'draw balance values: expenses
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_programmeLicences), valueExpenseX, valueStartY + 0*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_penalty), valueExpenseX, valueStartY + 1*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		'no callin expenses ?
		'no expenses for sponsorships ?
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_news), valueExpenseX, valueStartY + 4*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_newsAgencies), valueExpenseX, valueStartY + 5*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_stationFees + finance.expense_stations), valueExpenseX, valueStartY + 6*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_scripts), valueExpenseX, valueStartY + 7*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_productionStuff), valueExpenseX, valueStartY + 8*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_rent), valueExpenseX, valueStartY + 9*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_drawingCreditInterest + finance.expense_creditInterest), valueExpenseX, valueStartY + 10*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_creditRepayed), valueExpenseX, valueStartY + 11*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_misc), valueExpenseX, valueStartY + 12*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		'spacer for total
		textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_total), valueExpenseX, valueStartY + 14*valueH +4, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)



		'=== DRAW GROUP HOVERS ===
		local balanceEntryW:int = labelBGW + balanceValueBG.GetWidth() +2
		'"station group"
		if THelper.MouseIn(labelX, labelStartY + 6*valueH, balanceEntryW, labelH)
			local bgcol:TColor = new TColor.Get()

			SetAlpha bgcol.a * 0.5
			SetColor 200,200,200
			TFunctions.DrawOutlineRect(labelX, labelStartY + 6*valueH, balanceEntryW +2, 2*labelH +2)
			SetAlpha bgcol.a * 0.75
			SetColor 100,100,100
			TFunctions.DrawOutlineRect(labelX-1, labelStartY + 6*valueH -1, balanceEntryW + 1, 2*labelH +1)
			bgcol.SetRGBA()
			labelBGs[TVTPlayerFinanceEntryType.GROUP_STATION].DrawArea(labelBGX, labelStartY + 6*valueH, labelBGW, labelH)
			labelBGs[TVTPlayerFinanceEntryType.GROUP_STATION].DrawArea(labelBGX, labelStartY + 7*valueH, labelBGW, labelH)

			balanceValueBG.DrawArea(valueBGX, labelStartY + 6*valueH, balanceValueBG.GetWidth(), labelH)
			balanceValueBG2.DrawArea(valueBGX, labelStartY + 7*valueH, balanceValueBG.GetWidth(), labelH)

			textFont.DrawBlock(GetLocale("FINANCES_STATIONS_FEES"), labelX, labelStartY + 6*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_STATION])
			textFont.DrawBlock(GetLocale("FINANCES_STATIONS_BUY_SELL"), labelX, labelStartY + 7*valueH, labelW, labelH, ALIGN_LEFT_CENTER, clTypes[TVTPlayerFinanceEntryType.GROUP_STATION])

			textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_stationFees), valueExpenseX, valueStartY + 6*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)

			textBoldFont.drawBlock(MathHelper.DottedValue(finance.income_stations), valueIncomeX, valueStartY + 7*valueH, valueW, valueH, ALIGN_RIGHT_CENTER, GameConfig.clPositive)
			textBoldFont.drawBlock(MathHelper.DottedValue(finance.expense_stations), valueExpenseX, valueStartY + 7*valueH, valueW, valueH, ALIGN_LEFT_CENTER, GameConfig.clNegative)
		endif


		'==== DRAW MONEY CURVE====
		captionFont.DrawBlock(GetLocale("FINANCES_FINANCIAL_CURVES"), 500 + screenOffsetX, 207 + screenOffsetY,  260, captionHeight, ALIGN_CENTER_CENTER, captionColor, 1,,0.5)

		'how much days to draw
		local showDays:int = 10
		'where to draw + dimension
		local curveArea:TRectangle = new TRectangle.Init(509 + screenOffsetX,239 + screenOffsetY, 240, 70)
		'heighest reached money value of that days
		Local maxValue:int = 0
		'minimum money (may be negative)
		Local minValue:int = 0
		'color of labels
		Local labelColor:TColor = new TColor.CreateGrey(80)

		'first get the maximum value so we know how to scale the rest
		For local i:Int = GetWorldTime().GetDay()-showDays To GetWorldTime().GetDay()
			'skip if day is less than startday (saves calculations)
			if i < GetWorldTime().GetStartDay() then continue

			For Local player:TPlayer = EachIn GetPlayerCollection().players
				maxValue = max(maxValue, player.GetFinance(i).money)
				minValue = min(minValue, player.GetFinance(i).money)
			Next
		Next


		local slot:int				= 0
		local slotPos:TVec2D		= new TVec2D.Init(0,0)
		local previousSlotPos:TVec2D= new TVec2D.Init(0,0)
		local slotWidth:int 		= curveArea.GetW() / showDays

		local yPerMoney:Float = curveArea.GetH() / Float(Abs(minValue) + maxValue)
		'zero is at "bottom - minMoney*yPerMoney"
		local yOfZero:Float = curveArea.GetH() - yPerMoney * Abs(minValue)

		local hoveredDay:int = -1
		For local i:Int = GetWorldTime().GetDay()-showDays To GetWorldTime().GetDay()
			if THelper.MouseIn(int(curveArea.GetX() + (slot-0.5) * slotWidth), int(curveArea.GetY()), slotWidth, int(curveArea.GetH()))
				hoveredDay = i
				'leave for loop
				exit
			EndIf
			slot :+ 1
		Next
		if hoveredDay > 0
			local time:Double = GetWorldTime().MakeTime(0, hoveredDay, 0, 0)
			local gameDay:string = GetWorldTime().GetDayOfYear(time)+"/"+GetWorldTime().GetDaysPerYear()+" "+GetWorldTime().getYear(time)
			if GetPlayerCollection().Get(room.owner).GetFinance(hoveredDay).money > 0
				textSmallFont.Draw(GetLocale("GAMEDAY")+" "+gameDay+": |color=50,110,50|"+MathHelper.DottedValue(GetPlayerCollection().Get(room.owner).GetFinance(hoveredDay).money)+"|/color|", curveArea.GetX(), curveArea.GetY() + curveArea.GetH() + 2, TColor.CreateGrey(50))
			Else
				textSmallFont.Draw(GetLocale("GAMEDAY")+" "+gameDay+": |color=110,50,50|"+MathHelper.DottedValue(GetPlayerCollection().Get(room.owner).GetFinance(hoveredDay).money)+"|/color|", curveArea.GetX(), curveArea.GetY() + curveArea.GetH() + 2, TColor.CreateGrey(50))
			Endif

			local hoverX:int = curveArea.GetX() + (slot-0.5) * slotWidth
			local hoverW:int = Min(curveArea.GetX() + curveArea.GetW() - hoverX, slotWidth)
			if hoverX < curveArea.GetX() then hoverW = slotWidth / 2
			hoverX = Max(curveArea.GetX(), hoverX)

			local col:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha 0.1 * col.a
			DrawRect(hoverX, curveArea.GetY(), hoverW, curveArea.GetH())
			SetBlend AlphaBlend
			col.SetRGBA()
		EndIf

		'draw the curves
		SetLineWidth(2)
		GetGraphicsManager().EnableSmoothLines()

		slot = 0
		'TODO: integrate live curves?
		'      Could be done via analyzing the FinanceHistory-Log and
		'      sum up changes to blocks (fixed steps for the graphical
		'      width of a day)
		For Local player:TPlayer = EachIn GetPlayerCollection().players
			slot = 0
			slotPos.SetXY(0,0)
			previousSlotPos.SetXY(0,0)
			local oldAlpha:Float = GetAlpha()
			For local i:Int = GetWorldTime().GetDay()-showDays To GetWorldTime().GetDay()
				local afterStart:int = not (i < GetWorldTime().GetStartDay())

				previousSlotPos.SetXY(slotPos.x, slotPos.y)
				slotPos.SetXY(slot * slotWidth, 0)
				'maximum is at 90% (so it is nicely visible)
'				if maxValue > 0 then slotPos.SetY(curveArea.GetH() - Floor((player.GetFinance(i).money / float(maxvalue)) * curveArea.GetH()))

				slotPos.SetY(yOfZero - player.GetFinance(i).money * yPerMoney)
				if afterStart
					player.color.setRGB()
					SetAlpha 0.3 * oldAlpha
					DrawOval(curveArea.GetX() + slotPos.GetX()-3, curveArea.GetY() + slotPos.GetY()-3,6,6)
					SetAlpha 1.0 * oldAlpha
					if slot > 0
						DrawLine(curveArea.GetX() + previousSlotPos.GetX(), curveArea.GetY() + previousSlotPos.GetY(), curveArea.GetX() + slotPos.GetX(), curveArea.GetY() + slotPos.GetY())
						SetColor 255,255,255
					endif
					SetAlpha oldAlpha
				endif
				slot :+ 1
			Next
		Next
		SetLineWidth(1)

		'coord descriptor
		textSmallFont.drawBlock(TFunctions.convertValue(maxvalue,2,0), curveArea.GetX(), curveArea.GetY(), curveArea.GetW(), 20, new TVec2D.Init(ALIGN_RIGHT), labelColor)
		textSmallFont.drawBlock(TFunctions.convertValue(minvalue,2,0), curveArea.GetX(), curveArea.GetY() + curveArea.GetH()-20, curveArea.GetW(), 20, new TVec2D.Init(ALIGN_RIGHT, ALIGN_BOTTOM), labelColor)


		GuiManager.Draw( LS_officeFinancialScreen )

		clOriginal.SetRGB()
	End Function


	Function onUpdateFinancials:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'disable "up" or "down" button of finance history
		if financeHistoryStartPos = 0
			financeHistoryDownButton.Disable()
		else
			financeHistoryDownButton.Enable()
		endif

		local maxVisible:int = 6
		local notVisible:int = GetPlayerFinanceHistoryListCollection().Get(room.owner).Count() - financeHistoryStartPos - maxVisible
		if notVisible <= 0
			financeHistoryUpButton.Disable()
		else
			financeHistoryUpButton.Enable()
		endif


		'disable "previou" or "newxt" button of finance display
		if financeShowDay = 0 or financeShowDay = GetWorldTime().GetStartDay()
			financePreviousDayButton.Disable()
		else
			financePreviousDayButton.Enable()
		endif

		if financeShowDay = GetWorldTime().GetDay()
			financeNextDayButton.Disable()
		else
			financeNextDayButton.Enable()
		endif



		GetGameBase().cursorstate = 0
		GuiManager.Update( LS_officeFinancialScreen )
	End Function


	'right mouse button click: remove the block from the player's programmePlan
	'left mouse button click: check shortcuts and create a copy/nextepisode-block
	Function onClickFinanceButtons:int(triggerEvent:TEventBase)
		local arrowButton:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		if not arrowButton then return False

		if arrowButton = financeHistoryDownButton then financeHistoryStartPos :- 1
		if arrowButton = financeHistoryUpButton then financeHistoryStartPos :+ 1

		if arrowButton = financeNextDayButton then financeShowDay :+ 1
		if arrowButton = financePreviousDayButton then financeShowDay :- 1
	End Function
End Type