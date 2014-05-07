'SuperStrict
'Import "game.player.finance.bmx"
'Import "game.player.programmeplan.bmx"
'Import "game.broadcast.audienceresult.bmx"
'Import "game.publicimage.bmx"
'Import "game.figure.bmx"


Type TPlayerCollection
	Field players:TPlayer[4]
	'playerID of player who sits in front of the screen
	Field playerID:Int = 1
	Global _instance:TPlayerCollection


	Method New()
		_instance = self
	End Method


	Function GetInstance:TPlayerCollection()
		if not _instance then _instance = new TPlayerCollection
		return _instance
	End Function


	Method Set:int(id:int=-1, player:TPlayer)
		If id = -1 Then id = playerID
		if id <= 0 Then return False

		If players.length < playerID Then players = players[..id+1]
		players[id-1] = player
	End Method


	Method Get:TPlayer(id:Int=-1)
		If id = -1 Then id = playerID
		If Not isPlayer(id) Then Return Null

		Return players[id-1]
	End Method


	Method GetCount:Int()
		return players.length
	End Method


	Method IsPlayer:Int(number:Int)
		Return (number > 0 And number <= players.length And players[number-1] <> Null)
	End Method


	Method IsHuman:Int(number:Int)
		Return (IsPlayer(number) And Not Get(number).figure.IsAI())
	End Method


	'the negative of "isHumanPlayer" - also "no human player" is possible
	Method IsAI:Int(number:Int)
		Return (IsPlayer(number) And Get(number).figure.IsAI())
	End Method


	Method IsLocalPlayer:Int(number:Int)
		Return number = playerID
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPlayerCollection:TPlayerCollection()
	Return TPlayerCollection.GetInstance()
End Function




'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer {_exposeToLua="selected"}
	'playername
	Field Name:String
	'name of the channel
	Field channelname:String

	Field PublicImage:TPublicImage							{_exposeToLua}
	Field ProgrammeCollection:TPlayerProgrammeCollection	{_exposeToLua}
	Field ProgrammePlan:TPlayerProgrammePlan				{_exposeToLua}
	'actual figure the player uses
	Field Figure:TFigure									{_exposeToLua}
	'global used ID of the player
	Field playerID:Int = 0
	'the color used to colorize symbols and figures
	Field color:TColor
	'actual number of an array of figure-images
	Field figurebase:Int = 0
	'1=ready, 0=not set, ...
	Field networkstate:Int = 0
	'abonnementlevels for the newsgenres
	Field newsabonnements:Int[6]
	'maximum abonnementlevel for this day
	Field newsabonnementsDayMax:Int[] = [-1,-1,-1,-1,-1,-1]
	'when was the level set
	Field newsabonnementsSetTime:Int[6]
	Field PlayerKI:KI
	Field CreditMaximum:Int	= 600000


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
		Return figure.IsAI()
	End Method


	Method GetStationMap:TStationMap() {_exposeToLua}
		'fetch from StationMap-list
		local map:TStationMap = StationMapCollection.GetMap(playerID)
		'still not existing - create it
		if not map then map = TStationMap.Create(self.playerID)
		return map
	End Method


	'returns the financial of the given day
	'if the day is in the future, a new finance object is created
	Method GetFinance:TPlayerFinance(day:Int=-1)
		return GetPlayerFinanceCollection().Get(playerID, day)
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
	Function Create:TPlayer(playerID:int, Name:String, channelname:String = "", sprite:TSprite, x:Int, onFloor:Int = 13, dx:Int, color:TColor, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer = New TPlayer

		Player.Name	= Name
		Player.playerID	= playerID
		Player.color = color.AddToList(True).SetOwner(playerID)
		Player.channelname = channelname
		Player.Figure = New TFigure.Create(FigureName, sprite, x, onFloor, dx, ControlledByID)
		Player.Figure.ParentPlayerID = playerID
		Player.PublicImage = New TPublicImage.Create(Player.playerID)
		Player.ProgrammeCollection = TPlayerProgrammeCollection.Create(Player.playerID)
		Player.ProgrammePlan = New TPlayerProgrammePlan.Create(Player.playerID)

		GetPlayerProgrammeCollectionCollection().Set(Player.playerID, Player.ProgrammeCollection)
		GetPlayerProgrammePlanCollection().Set(Player.playerID, Player.ProgrammePlan)

		Player.RecolorFigure(Player.color)

		Player.UpdateFigureBase(0)

		Return Player
	End Function



	Method SetAIControlled(luafile:String="")
		figure.controlledByID = 0
		PlayerKI = new KI.Create(playerID, luafile)
		PlayerKI.Start()
	End Method


	'loads a new figurbase and colorizes it
	Method UpdateFigureBase:int(newfigurebase:Int)
		'load configuration from registry
		Local figuresConfig:TData = TData(GetRegistry().Get("figuresConfig", new TData))
		Local playerFigures:string[] = figuresConfig.GetString("playerFigures", "").split(",")
		Local figureCount:Int = Len(playerFigures)

		'skip if no figures are available (an error ?!)
		If figureCount = 0 then return False

		'limit the figurebase to the available figures
		If newfigurebase > figureCount-1 Then newfigurebase = 0
		If newfigurebase < 0 Then newfigurebase = figureCount-1
		figurebase = newfigurebase

		Local newSpriteName:string = playerFigures[figurebase].trim().toLower()
		Local newSprite:TSprite = GetSpriteFromRegistry(newSpriteName)
		'skip if replacement sprite does not exist or default was returned
		If not newSprite or newSprite.GetName().toLower() <>  newSpriteName then return False

		Local oldSprite:TSprite = GetSpriteFromRegistry("Player" + Self.playerID)
		Local newImage:TImage = ColorizeImageCopy(newSprite.GetImage(), color)
		Local figuresPack:TSpritePack = TSpritePack(GetRegistry().Get("gfx_figuresPack"))

		'clear occupied area within pixmap
		oldSprite.ClearImageData()
		'draw the new figure at that area
		DrawImageOnImage(newImage, figuresPack.image, oldSprite.area.GetX(), oldSprite.area.GetY())
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
		'For Local i:Int = 0 To 6
		'
		'Next
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
			if GetGameTime().GetDay(newsabonnementsSetTime[genre]) < GetGameTime().GetDay()
				'NOT 0:00 (the time daily costs are computed)
				if GetGameTime().GetMinute() > 0
					SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
				EndIf
			EndIf

			'more than 30 mins gone since last "abonnement set"
			if GetGameTime().GetTimeGone() - newsabonnementsSetTime[genre] > 30
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
			newsabonnementsSetTime[genre] = GetGameTime().GetTimeGone()

			If Game.networkgame And Network.IsConnected And sendToNetwork Then NetworkHelper.SendNewsSubscriptionChange(Self.playerID, genre, level)
		EndIf
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


	Method Compare:Int(otherObject:Object)
		Local s:TPlayer = TPlayer(otherObject)
		If Not s Then Return 1
		If s.playerID > Self.playerID Then Return 1
		Return 0
	End Method


	Method isActivePlayer:Int()
		Return (playerID = GetPlayerCollection().playerID)
	End Method
End Type