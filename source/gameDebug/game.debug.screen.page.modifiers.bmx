SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.player.bmx"

Type TDebugScreenPage_Modifiers extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Modifiers
	Field buttons:TDebugControlsButton[]
	Field difficultyX:Int
	Field difficultyY:Int
	Field difficultyWidth:Int
	Field playerID:Int
	Field difficulty:TPlayerDifficulty
	Field buttonsCreated:Int = False


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Modifiers()
		If Not _instance Then new TDebugScreenPage_Modifiers
		Return _instance
	End Function


	Method Init:TDebugScreenPage_Modifiers()
		Local texts:String[] = ["Set to easy", "Set to normal", "Set to hard", "Reset Values"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button.w = 115
			'custom position
			button.x = position.x + 547
			button.y = 18 + 2 + i * (button.h + 2)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		Return self
	End Method


	Method Reset()
		playerID=-1
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons action buttons
		For Local i:Int = 0 Until 4
			buttons[i].x :+ dx
			buttons[i].y :+ dy
		Next
	End Method


	Method Update()
		Local player:Int = GetShownPlayerID()
		If player <> playerID
			playerID = player
			difficulty:TPlayerDifficulty = GetPlayerDifficulty(playerID)
		EndIf 
		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		RenderDifficulties(position.x, position.y)

		RenderGameModifierList(position.x, position.y + 220, 540, 140)

		DrawWindow(position.x + 545, position.y, 120, 89, "Manipulate")
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
	End Method


	Method RenderGameModifierList(x:int, y:int, w:int = 300, h:int = 120)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Game Modifiers", "", 0.0)
		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y
		Local modifierWidth:Int = contentRect.w / 2 - 15
		Local data:TData = GameConfig._modifiers
		If data
			For Local k:TLowerString = EachIn data.data.Keys()
				If textY + 12 > contentRect.y + contentRect.h 
					textY = contentRect.Y
					textX :+ modifierWidth + 15
				EndIf
				If textX - contentRect.x > contentRect.w Then exit

				textFont.DrawBox(k.ToString(), textX, textY, modifierWidth - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
				textFont.DrawBox(TFunctions.LocalizedNumberToString(data.GetFloat(k.ToString()), 3), textX + modifierWidth - 40, textY, 40, 15, sALIGN_RIGHT_TOP, SColor8.White)
				textY :+ 12
			Next
		EndIf
	End Method


	Method RenderDifficulties(x:int, y:int, w:int = 540, h:int = 215)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Player #" + playerID, "Difficulty: " +difficulty.GetGUID(), 0.0)
		difficultyX = contentRect.x
		difficultyY = contentRect.y
		difficultyWidth = contentRect.w / 2 - 15

		'TODO Spieler mit gleichem Level teilen sich wohl dasselbe Objekt - keine spielerindividuellen Difficulty-Werte
		'programme
		renderModifier("Programme Price", "licPrice", difficulty.programmePriceMod)
		renderModifier("Prog. Topicality Cut", "licTopCut", difficulty.programmeTopicalityCutMod)
		renderModifier("Xrated Penalty", "xPenalty", difficulty.sentXRatedPenalty, 5000)
		renderModifier("Xrated Confiscate Risk", "xRisk", difficulty.sentXRatedConfiscateRisk)

		'Ads
		renderModifier("Ad Min Audience", "adAudience", difficulty.adcontractRawMinAudienceMod)
		renderModifier("Ad Price (global)", "adPrice", difficulty.adcontractPriceMod)
		renderModifier("Ad Profit", "adProfit", difficulty.adcontractProfitMod)
		renderModifier("Ad Penalty", "adPenalty", difficulty.adcontractPenaltyMod)
		renderModifier("Target Group", "adTarget", difficulty.adcontractLimitedTargetgroupMod)
		renderModifier("Infomercial Profit", "infoProfit", difficulty.adcontractInfomercialProfitMod)
		
		renderModifier("Broadcast Permission", "permPrice", difficulty.broadcastPermissionPriceMod)
		renderModifier("Antenna Price", "stPrice", difficulty.antennaBuyPriceMod)
		renderModifier("Antenna Constr. Time", "stTime", difficulty.antennaConstructionTime,1)
		renderModifier("Antenna Daily Costs", "stDaily", difficulty.antennaDailyCostsMod)
		renderModifier("Ant. Daily Costs Increase", "stInc", difficulty.antennaDailyCostsIncrease,1)
		renderModifier("Ant. Daily Increase Max", "stIncMax", difficulty.antennaDailyCostsIncreaseMax,1)

		difficultyX = contentRect.x + (1 * difficultyWidth + 2*15)
		difficultyY = contentRect.y

		renderModifier("Network Price", "cablePrice", difficulty.cableNetworkBuyPriceMod)
		renderModifier("Network Constr. Time", "cableTime", difficulty.cableNetworkConstructionTime,1)
		renderModifier("Network Daily Costs", "cableDaily", difficulty.cableNetworkDailyCostsMod,1)
		renderModifier("Satellite Price", "satPrice", difficulty.satelliteBuyPriceMod)
		renderModifier("Satellite Constr. Time", "satTime", difficulty.satelliteConstructionTime,1)
		renderModifier("Satellite Daily Costs", "satDaily", difficulty.satelliteDailyCostsMod,1)
		
		'News
		renderModifier("News Price", "newsPrice", difficulty.newsItemPriceMod)

		'Room
		renderModifier("Room rent", "roomPrice", difficulty.roomRentMod)

		'credit
		renderModifier("Credit Base", "credBase", difficulty.creditBaseValue, 500)
		renderModifier("Credit Interest Rate", "credRate", difficulty.interestRateCredit,1)
		renderModifier("Interest Rate positive Balance", "credIntPos", difficulty.interestRatePositiveBalance,1)
		renderModifier("Interest Rate negative Balance", "credIntNeg", difficulty.interestRateNegativeBalance, 1)

		'Production
		renderModifier("Production Time", "prodTime", difficulty.productionTimeMod)

		'Terrorist effects
		renderModifier("Renovation Base Price", "renovPrice", difficulty.renovationBaseCost, 500)
		renderModifier("Renovation Time Mod", "renovTimeMod", difficulty.renovationTimeMod)

		buttonsCreated = True
	End Method


	Method renderModifier(caption:String, fieldName:String, value:Float, change:Int=5)
		textFont.DrawBox(caption, difficultyX, difficultyY, difficultyWidth - 60 - 25, 15, sALIGN_LEFT_TOP, SColor8.White)
		textFont.DrawBox(TFunctions.LocalizedNumberToString(value, 3), difficultyX, difficultyY, difficultyWidth - 60, 15, sALIGN_RIGHT_TOP, SColor8.White)

		If Not buttonsCreated
			createModifierButtons(fieldName, change, difficultyX + difficultyWidth, difficultyY)
		EndIf
		difficultyY :+ 12
	End Method


	Method renderModifier(caption:String, fieldName:String, value:Int, change:Int=10)
		textFont.DrawBox(caption, difficultyX, difficultyY, difficultyWidth - 60 - 25, 15, sALIGN_LEFT_TOP, SColor8.White)
		textFont.DrawBox(value, difficultyX, difficultyY, difficultyWidth - 60, 15, sALIGN_RIGHT_TOP, SColor8.White)

		If Not buttonsCreated
			createModifierButtons(fieldName, change, difficultyX + difficultyWidth, difficultyY)
		EndIf
		difficultyY = difficultyY + 12
	End Method


	Method createModifierButtons(fieldName:String, change:Int, xOffset:Int, yPos:Int)
		createModifierButton(fieldName, "+", change, xOffset-55, ypos)
		createModifierButton(fieldName, "-", -change, xOffset-30, ypos)
	End Method


	Method createModifierButton(fieldName:String, plusMinus:String, change:Int, xOffset:Int, yPos:Int)
		Local button:TDebugControlsButton = New TDebugControlsButton
		button.h = 14
		button.w = 20
		button.x = xOffset
		button.y = yPos
		button.dataInt = change
		button.text = plusMinus
		button.data=fieldName
		button._onClickHandler = OnClickModifyHandler
		buttons :+ [button]
	End Method


	Function OnClickModifyHandler(sender:TDebugControlsButton)
		Local difficulty:TPlayerDifficulty = TDebugScreenPage_Modifiers.GetInstance().difficulty
		Local diff:Int = sender.dataInt
		Local fieldName:String = String(sender.data)
		Select fieldName
			Case "licPrice"
				difficulty.programmePriceMod:+ diff/100.0
			Case "licTopCut"
				difficulty.programmeTopicalityCutMod:+ diff/100.0
			Case "xPenalty"
				difficulty.sentXRatedPenalty:+ diff
			Case "xRisk"
				difficulty.sentXRatedConfiscateRisk:+ diff

			Case "adAudience"
				difficulty.adcontractRawMinAudienceMod:+ diff/100.0
			Case "adPrice"
				difficulty.adcontractPriceMod:+ diff/100.0
			Case "adProfit"
				difficulty.adcontractProfitMod:+ diff/100.0
			Case "adPenalty"
				difficulty.adcontractPenaltyMod:+ diff/100.0
			Case "adTarget"
				difficulty.adcontractLimitedTargetgroupMod:+ diff/100.0
			Case "infoProfit"
				difficulty.adcontractInfomercialProfitMod:+ diff/100.0

			Case "permPrice"
				difficulty.broadcastPermissionPriceMod:+ diff/100.0
			Case "stPrice"
				difficulty.antennaBuyPriceMod:+ diff/100.0
			Case "stTime"
				difficulty.antennaConstructionTime:+ diff
			Case "stDaily"
				difficulty.antennaDailyCostsMod:+ diff/100.0
			Case "stInc"
				difficulty.antennaDailyCostsIncrease:+ diff/100.0
			Case "stIncMax"
				difficulty.antennaDailyCostsIncreaseMax:+ diff/100.0
			Case "cablePrice"
				difficulty.cableNetworkBuyPriceMod:+ diff/100.0
			Case "cableTime"
				difficulty.cableNetworkConstructionTime:+ diff
			Case "cableDaily"
				difficulty.cableNetworkDailyCostsMod:+ diff/100.0
			Case "satPrice"
				difficulty.satelliteBuyPriceMod:+ diff/100.0
			Case "satTime"
				difficulty.satelliteConstructionTime:+ diff
			Case "satDaily"
				difficulty.satelliteDailyCostsMod:+ diff/100.0
			Case "newsPrice"
				difficulty.newsItemPriceMod:+ diff/100.0
			Case "roomPrice"
				difficulty.roomRentMod:+ diff/100.0
			Case "credBase"
				difficulty.creditBaseValue:+ diff
			Case "credRate"
				difficulty.interestRateCredit:+ diff/100.0
			Case "credIntPos"
				difficulty.interestRatePositiveBalance:+ diff/100.0
			Case "credIntNeg"
				difficulty.interestRateNegativeBalance:+ diff/100.0
			Case "prodTime"
				difficulty.productionTimeMod:+ diff/100.0
			Case "renovPrice"
				difficulty.renovationBaseCost:+ diff
			Case "renovTimeMod"
				difficulty.renovationTimeMod:+ diff/100.0
			Default
				throw "unkown field for "+ fieldName
		End Select
		'handled
		sender.clicked = False
		sender.selected = False
	End Function


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local collection:TPlayerDifficultyCollection=TPlayerDifficultyCollection.GetInstance()
		Local level:String = ""
		Local changePlayerLevel:Int = True
		Select sender.dataInt
			Case 0
				level ="easy"
			Case 1
				level ="normal"
			Case 2
				level ="hard"
			Case 3
				'reset all level values
				changePlayerLevel = False
				Local levels:String[] = new String[4]
				For Local i:Int = 0 Until levels.length
					levels[i] = GetPlayerDifficulty(i+1).GetGUID()
				Next
				collection.InitializeDefaults()
				For Local i:Int = 0 Until levels.length
					collection.AddToPlayer(i+1, collection.GetByGUID(levels[i]))
				Next
		End Select

		Local screen:TDebugScreenPage_Modifiers=TDebugScreenPage_Modifiers.GetInstance()
		If changePlayerLevel Then
			GetPlayerBase(screen.playerID).SetDifficulty(level)
		EndIf
		screen.Reset()

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
