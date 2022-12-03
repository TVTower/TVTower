SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.player.bmx"

Type TDebugScreenPage_Modifiers extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field difficultyX:Int
	Field difficultyY:Int
	Field difficultyWidth:Int
	Field playerID:Int
	Field difficulty:TPlayerDifficulty
	Field buttonsCreated:Int = False

	Global _instance:TDebugScreenPage_Modifiers

	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Modifiers()
		if not _instance then new TDebugScreenPage_Modifiers
		return _instance
	End Function


	Method Init:TDebugScreenPage_Modifiers()
		Local texts:String[] = ["Set to easy", "Set to normal", "Set to hard", "Reset Values"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		Return self
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local collection:TPlayerDifficultyCollection=TPlayerDifficultyCollection.GetInstance()
		Local level:String = ""
		Local changePlayerLevel:Int = True
		Select sender.dataInt
			case 0
				level ="easy"
			case 1
				level ="normal"
			case 2
				level ="hard"
			case 3
				'reset all level values
				changePlayerLevel = False
				local levels:String[] = new String[4]
				For Local i:Int = 0 Until levels.length
					levels[i] = GetPlayerDifficulty(i+1).GetGUID()
				Next
				collection.InitializeDefaults()
				For Local i:Int = 0 Until levels.length
					collection.AddToPlayer(i+1, collection.GetByGUID(levels[i]))
				Next
		End Select

		local screen:TDebugScreenPage_Modifiers=TDebugScreenPage_Modifiers.GetInstance()
		If changePlayerLevel Then
			collection.AddToPlayer(screen.playerID, collection.GetByGUID(level))
		EndIf
		screen.Reset()

		'handled
		sender.clicked = False
		sender.selected = False
	End Function


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
		If player <> playerID then
			playerID = player
			difficulty:TPlayerDifficulty = GetPlayerDifficulty(playerID)
		EndIf 
		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		RenderGameModifierList(position.x + 5, position.y - 10, 280)

		RenderDifficulties(position.x + 290, position.y -10)

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
	End Method


	Method RenderGameModifierList(x:int, y:int, w:int = 300, h:int = 370)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 2

		titleFont.DrawSimple("Game Modifiers: ", textX, textY)

		textY :+ 12 

		Local data:TData = GameConfig._modifiers
		If data
			For Local k:TLowerString = EachIn data.data.Keys()
				If textY + 12 > y + h Then Continue

				textFont.DrawBox(k.ToString(), textX, textY, w - 10 - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
				textFont.DrawBox(MathHelper.NumberToString(data.GetFloat(k.ToString()), 3), textX, textY, w - 10, 15, sALIGN_RIGHT_TOP, SColor8.White)
				textY :+ 12
			Next
		EndIf
	End Method

	Method RenderDifficulties(x:int, y:int, w:int = 220, h:int = 370)
		DrawOutlineRect(x, y, w, h)
		difficultyX = x + 5
		difficultyY = y + 2
		difficultyWidth = w

		titleFont.DrawSimple("Player " + playerID +" Difficulty (" +difficulty.GetGUID()+"): ", difficultyX, difficultyY)
		difficultyY = difficultyY + 12
		'TODO Spieler mit gleichem Level teilen sich wohl dasselbe Objekt - keine spielerindividuellen Difficulty-Werte
		'programme
		renderModifier("Programme Price", "licPrice", difficulty.programmePriceMod)
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
		textFont.DrawBox(MathHelper.NumberToString(value, 3), difficultyX, difficultyY, difficultyWidth - 60, 15, sALIGN_RIGHT_TOP, SColor8.White)

		if not buttonsCreated then
			createModifierButtons(fieldName, change, difficultyX + difficultyWidth, difficultyY)
		endif
		difficultyY = difficultyY + 12
	End Method

	Method renderModifier(caption:String, fieldName:String, value:Int, change:Int=10)
		textFont.DrawBox(caption, difficultyX, difficultyY, difficultyWidth - 60 - 25, 15, sALIGN_LEFT_TOP, SColor8.White)
		textFont.DrawBox(value, difficultyX, difficultyY, difficultyWidth - 60, 15, sALIGN_RIGHT_TOP, SColor8.White)

		if not buttonsCreated then
			createModifierButtons(fieldName, change, difficultyX + difficultyWidth, difficultyY)
		endif
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
			case "licPrice"
				difficulty.programmePriceMod:+ diff/100.0
			case "xPenalty"
				difficulty.sentXRatedPenalty:+ diff
			case "xRisk"
				difficulty.sentXRatedConfiscateRisk:+ diff

			case "adAudience"
				difficulty.adcontractRawMinAudienceMod:+ diff/100.0
			case "adPrice"
				difficulty.adcontractPriceMod:+ diff/100.0
			case "adProfit"
				difficulty.adcontractProfitMod:+ diff/100.0
			case "adPenalty"
				difficulty.adcontractPenaltyMod:+ diff/100.0
			case "adTarget"
				difficulty.adcontractLimitedTargetgroupMod:+ diff/100.0
			case "infoProfit"
				difficulty.adcontractInfomercialProfitMod:+ diff/100.0

			case "permPrice"
				difficulty.broadcastPermissionPriceMod:+ diff/100.0
			case "stPrice"
				difficulty.antennaBuyPriceMod:+ diff/100.0
			case "stTime"
				difficulty.antennaConstructionTime:+ diff
			case "stDaily"
				difficulty.antennaDailyCostsMod:+ diff/100.0
			case "stInc"
				difficulty.antennaDailyCostsIncrease:+ diff/100.0
			case "stIncMax"
				difficulty.antennaDailyCostsIncreaseMax:+ diff/100.0
			case "cablePrice"
				difficulty.cableNetworkBuyPriceMod:+ diff/100.0
			case "cableTime"
				difficulty.cableNetworkConstructionTime:+ diff
			case "cableDaily"
				difficulty.cableNetworkDailyCostsMod:+ diff/100.0
			case "satPrice"
				difficulty.satelliteBuyPriceMod:+ diff/100.0
			case "satTime"
				difficulty.satelliteConstructionTime:+ diff
			case "satDaily"
				difficulty.satelliteDailyCostsMod:+ diff/100.0
			case "newsPrice"
				difficulty.newsItemPriceMod:+ diff/100.0
			case "roomPrice"
				difficulty.roomRentMod:+ diff/100.0
			case "credBase"
				difficulty.creditBaseValue:+ diff
			case "credRate"
				difficulty.interestRateCredit:+ diff/100.0
			case "credIntPos"
				difficulty.interestRatePositiveBalance:+ diff/100.0
			case "credIntNeg"
				difficulty.interestRateNegativeBalance:+ diff/100.0
			case "prodTime"
				difficulty.productionTimeMod:+ diff/100.0
			case "renovPrice"
				difficulty.renovationBaseCost:+ diff
			case "renovTimeMod"
				difficulty.renovationTimeMod:+ diff/100.0
			default
				throw "unkown field for "+ fieldName
		End Select
		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type