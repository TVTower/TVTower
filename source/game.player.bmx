
'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer {_exposeToLua="selected"}
	Field Name:String 								'playername
	Field channelname:String 						'name of the channel
	Field finances:TPlayerFinance[]					'financial stats about credit, money, payments ...
	Field audience:TAudienceResult

	Field PublicImage:TPublicImage							{_exposeToLua}
	Field ProgrammeCollection:TPlayerProgrammeCollection	{_exposeToLua}
	Field ProgrammePlan:TPlayerProgrammePlan				{_exposeToLua}
	Field Figure:TFigure									{_exposeToLua}				'actual figure the player uses
	Field playerID:Int 			= 0					'global used ID of the player
	Field color:TColor				 				'the color used to colorize symbols and figures
	Field figurebase:Int 		= 0					'actual number of an array of figure-images
	Field networkstate:Int 		= 0					'1=ready, 0=not set, ...
	Field newsabonnements:Int[6]							{_private}					'abonnementlevels for the newsgenres
	Field newsabonnementsDayMax:Int[] = [-1,-1,-1,-1,-1,-1] {_private}					'maximum abonnementlevel for this day
	Field newsabonnementsSetTime:Int[6]						{_private}					'when was the level set
	Field PlayerKI:KI			= Null						{_private}
	Field CreditMaximum:Int		= 600000					{_private}


	Method onLoad:int(triggerEvent:TEventBase)
		'reconnect AI engine
		if IsAi() then PlayerKI.Start()

		'load savestate
		if IsAi() then PlayerKI.CallOnLoad()
	End Method


	Method GetPlayerID:Int() {_exposeToLua}
		Return playerID
	End Method


	Method IsAI:Int() {_exposeToLua}
		'return self.playerKI <> null
		Return figure.IsAI()
	End Method


	Method GetStationMap:TStationMap() {_exposeToLua}
		'fetch from StationMap-list
		local map:TStationMap = StationMapCollection.GetMap(playerID)
		'still not existing - create it
		if not map then map = TStationMap.Create(self)
		return map
	End Method


	'returns the financial of the given day
	'if the day is in the future, a new finance object is created
	Method GetFinance:TPlayerFinance(day:Int=-1)
		If day <= 0 Then day = Game.GetDay()
		'subtract start day to get a index starting at 0 and add 1 day again
		Local arrayIndex:Int = day +1 - Game.GetStartDay()

		If arrayIndex < 0 Then Return GetFinance(Game.GetStartDay()-1)
		If (arrayIndex = 0 And Not finances[0]) Or arrayIndex >= finances.length
			'TDevHelper.Log("TPlayer.GetFinance()", "Adding a new finance to player "+Self.playerID+" for day "+day+ " at index "+arrayIndex, LOG_DEBUG)
			If arrayIndex >= finances.length
				'resize array
				finances = finances[..arrayIndex+1]
			EndIf
			finances[arrayIndex] = New TPlayerFinance.Create(Self)
			'reuse the money from the day before
			'if arrayIndex 0 - we do not need to take over
			'calling GetFinance(day-1) instead of accessing the array
			'assures that the object is created if needed (recursion)
			If arrayIndex > 0 Then TPlayerFinance.TakeOverFinances(GetFinance(day-1), finances[arrayIndex])
		EndIf
		Return finances[arrayIndex]
	End Method


	Method GetMaxAudience:Int() {_exposeToLua}
		Return GetStationMap().GetReach()
	End Method


	Method isInRoom:Int(roomName:String="", checkFromRoom:Int=False) {_exposeToLua}
		If checkFromRoom
			'from room has to be set AND inroom <> null (no building!)
			Return (Figure.inRoom And Figure.inRoom.Name.toLower() = roomname.toLower()) Or (Figure.inRoom And Figure.fromRoom And Figure.fromRoom.Name.toLower() = roomname.toLower())
		Else
			Return (Figure.inRoom And Figure.inRoom.Name.toLower() = roomname.toLower())
		EndIf
	End Method


	'creates and returns a player
	'-creates the given playercolor and a figure with the given
	' figureimage, a programmecollection and a programmeplan
	Function Create:TPlayer(playerID:int, Name:String, channelname:String = "", sprite:TGW_Sprite, x:Int, onFloor:Int = 13, dx:Int, color:TColor, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer		= New TPlayer
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", new TData.AddString("text", "Create Player").AddNumber("itemNumber", playerID).AddNumber("maxItemNumber", 4) ) )

		Player.Name					= Name
		Player.playerID				= playerID
		Player.color				= color.AddToList(True).SetOwner(playerID)
		Player.channelname			= channelname
		Player.Figure				= New TFigure.CreateFigure(FigureName, sprite, x, onFloor, dx, ControlledByID)
		Player.Figure.ParentPlayerID= playerID
		Player.PublicImage			= New TPublicImage.Create(Player)
		Player.ProgrammeCollection	= TPlayerProgrammeCollection.Create(Player)
		Player.ProgrammePlan		= New TPlayerProgrammePlan.Create(Player)

		Player.RecolorFigure(Player.color)

		Player.UpdateFigureBase(1)

		Return Player
	End Function


	Method SetAIControlled(luafile:String="")
		figure.controlledByID = 0
		PlayerKI = new KI.Create(playerID, luafile)
		PlayerKI.Start()
	End Method


	'loads a new figurbase and colorizes it
	Method UpdateFigureBase(newfigurebase:Int)
		Local figureCount:Int = 13
		If newfigurebase > figureCount Then newfigurebase = 1
		If newfigurebase <= 0 Then newfigurebase = figureCount
		figurebase = newfigurebase

		Local figureSprite:TGW_Sprite = Assets.GetSpritePack("figures").GetSprite("Player" + Self.playerID)
		'umstellen: anhand von "namen" ermitteln ("base"+figurebase)
		Local figureImageReplacement:TImage = ColorizeImageCopy(Assets.GetSpritePack("figures").GetSpriteByID(figurebase).GetImage(), color)

		'clear occupied area within pixmap
		figureSprite.ClearImageData()
		'draw the new figure at that area
		DrawImageOnImage(figureImageReplacement, Assets.GetSpritePack("figures").image, figureSprite.area.GetX(), figureSprite.area.GetY())
rem
		CLS
		DrawImage(Assets.GetSpritePack("figures").image, 10,10)
		Flip 0
		Delay(500)
endrem
	End Method


	'colorizes a figure and the corresponding sign next to the players doors in the building
	Method RecolorFigure(newColor:TColor = Null)
		If newColor = Null Then newColor = color
		color.ownerID	= 0
		color			= newColor
		color.ownerID	= playerID
		UpdateFigureBase(figurebase)
	End Method


	'nothing up to now
	Method UpdateFinances:Int()
		For Local i:Int = 0 To 6
			'
		Next
	End Method


	Method GetNewsAbonnementPrice:Int(level:Int=0)
		Return Min(5,level) * 10000
	End Method


	Method GetNewsAbonnementDelay:Int(genre:Int) {_exposeToLua}
		Return 60*(Game.maxAbonnementLevel - newsabonnements[genre])
	End Method


	'return which is the highest level for the given genre today
	'(which was active for longer than X game minutes)
	'if the last time a abonnement level was set was before today
	'use the current level value
	Method GetNewsAbonnementDaysMax:Int(genre:Int)
		If genre > 5 Then Return 0 'max 6 categories 0-5

		'not set yet - use the current abonnement
		if newsabonnementsDayMax[genre] = -1
			SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
		endif

		'if level of genre changed - adjust maximum
		if newsabonnementsDayMax[genre] <> newsabonnements[genre]
			'if the "set time" is not the current day, we assume
			'the current abonnement level as maxium
			'eg.: genre set 23:50 - not catched by the "30 min check"
			'also a day change sets maximum even if level is lower than
			'maximum (which is not allowed during day to pay for the best
			'level you had this day)
			if Game.GetDay(newsabonnementsSetTime[genre]) < Game.GetDay()
				'NOT 0:00 (the time daily costs are computed)
				if Game.GetMinute() > 0
					SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
				EndIf
			EndIf

			'more than 30 mins gone since last "abonnement set"
			if Game.GetTimeGone() - newsabonnementsSetTime[genre] > 30
				'only set maximum if the new level is higher than the
				'current days maxmimum.
				if newsabonnementsDayMax[genre] < newsabonnements[genre]
					SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
				EndIf
			EndIf
		EndIf
		
		return newsabonnementsDayMax[genre]
	End Method


	'sets the current maximum level of a news abonnement level for that day
	Method SetNewsAbonnementDaysMax:Int(genre:Int, level:int)
		If genre > 5 Then Return 0 'max 6 categories 0-5
		newsabonnementsDayMax[genre] = level
	End Method
	

	'return CURRENT newsAbonnement
	Method GetNewsAbonnement:Int(genre:Int) {_exposeToLua}
		If genre > 5 Then Return 0 'max 6 categories 0-5
		Return Self.newsabonnements[genre]
	End Method


	Method IncreaseNewsAbonnement(genre:Int) {_exposeToLua}
		SetNewsAbonnement( genre, GetNewsAbonnement(genre)+1 )
	End Method


	Method SetNewsAbonnement(genre:Int, level:Int, sendToNetwork:Int = True) {_exposeToLua}
		If level > Game.maxAbonnementLevel Then level = 0 'before: Return
		If genre > 5 Then Return 'max 6 categories 0-5
		If newsabonnements[genre] <> level
			newsabonnements[genre] = level
			'set at which time we did this
			newsabonnementsSetTime[genre] = Game.GetTimeGone()
			
			If Game.networkgame And Network.IsConnected And sendToNetwork Then NetworkHelper.SendNewsSubscriptionChange(Self.playerID, genre, level)
		EndIf
	End Method


	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetAudiencePercentage:Float() {_exposeToLua}
		Return TAudienceResult.Curr(playerID).AudienceQuote.Average
		'Local audienceResult:TAudienceResult = TAudienceResult.Curr(playerID)
		'Return audienceResult.MaxAudienceThisHour.GetSumFloat() / audienceResult.WholeMarket.GetSumFloat()
	End Method


Rem
	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetRelativeAudiencePercentage:Float(playerID:Int) {_exposeToLua}
		Return TAudienceResult.Curr(playerID).AudienceQuote.GetAverage()
	End Method
endrem


	'returns value chief will give as credit
	Method GetCreditAvailable:Int() {_exposeToLua}
		Return Max(0, CreditMaximum - GetFinance().credit)
	End Method


	'nothing up to now
	Method Update:Int()
		''
	End Method


	'returns formatted value of actual money
	'gibt einen formatierten Wert des aktuellen Geldvermoegens zurueck
	Method GetMoneyFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).money, 2)
	End Method


	'attention: when used through LUA without param, the param gets "0"
	'instead of "-1"
	Method GetMoney:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).money
	End Method


	'returns formatted value of actual credit
	Method GetCreditFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).credit, 2)
	End Method


	Method GetCredit:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).credit
	End Method


	Method GetAudience:Int() {_exposeToLua}
		If Not Self.audience Then Return 0
		Return Self.audience.Audience.GetSum()
	End Method


	'returns formatted value of actual audience
	'gibt einen formatierten Wert der aktuellen Zuschauer zurueck
	Method GetFormattedAudience:String() {_exposeToLua}
		Return TFunctions.convertValue(GetAudience(), 2)
	End Method

	Method Compare:Int(otherObject:Object)
		Local s:TPlayer = TPlayer(otherObject)
		If Not s Then Return 1
		If s.playerID > Self.playerID Then Return 1
		Return 0
	End Method


	Method isActivePlayer:Int()
		Return (Self.playerID = Game.playerID)
	End Method
End Type