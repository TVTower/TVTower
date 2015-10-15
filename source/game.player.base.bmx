SuperStrict
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.player.color.bmx"
Import "game.player.finance.bmx"
Import "game.figure.base.bmx"


Type TPlayerBaseCollection
	Field players:TPlayerBase[4]
	'playerID of player who sits in front of the screen
	Field playerID:Int = 1
	Global _instance:TPlayerBaseCollection


	Function GetInstance:TPlayerBaseCollection()
		if not _instance then _instance = new TPlayerBaseCollection
		return _instance
	End Function


	Method Initialize:int()
		players = new TPlayerBase[4]
		playerID = 1
	End Method


	Method Set:int(id:int=-1, player:TPlayerBase)
		If id = -1 Then id = playerID
		if id <= 0 Then return False

		If players.length < playerID Then players = players[..id+1]
		players[id-1] = player
	End Method


	Method Get:TPlayerBase(id:Int=-1)
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


	Method IsLocalPlayer:Int(number:Int)
		Return number = playerID
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerBaseCollection:TPlayerBaseCollection()
	Return TPlayerBaseCollection.GetInstance()
End Function
'return specific playerBase
Function GetPlayerBase:TPlayerBase(playerID:int=-1)
	Return TPlayerBaseCollection.GetInstance().Get(playerID)
End Function




Type TPlayerBase {_exposeToLua="selected"}
	'playername
	Field Name:String
	'name of the channel
	Field channelname:String
	'global used ID of the player
	Field playerID:Int = 0
	'the color used to colorize symbols and figures
	Field color:TPlayerColor
	'actual number of an array of figure-images
	Field figurebase:Int = 0
	'actual figure the player uses
	Field Figure:TFigureBase {_exposeToLua}

	'1=ready, 0=not set, ...
	Field networkstate:Int = 0

	'=== NEWS ABONNEMENTS ===
	'abonnementlevels for the newsgenres
	Field newsabonnements:Int[6]
	'maximum abonnementlevel for this day
	Field newsabonnementsDayMax:Int[] = [-1,-1,-1,-1,-1,-1]
	'when was the level set
	Field newsabonnementsSetTime:Int[6]
		

	Method GetPlayerID:Int() {_exposeToLua}
		Return playerID
	End Method

	
	Method GetFigure:TFigureBase()
		return figure
	End Method


	Method HasMasterKey:int()
		return figure.hasMasterKey
	End Method


	'returns value boss will give as credit
	Method GetCreditAvailable:Int() {_exposeToLua}
		Return 0
	End Method


	'returns the currently taken credit
	Method GetCredit:Int(day:Int=-1) {_exposeToLua}
		Return 0
	End Method


	'returns formatted value of actual money
	Method GetMoneyFormatted:String(day:Int=-1)
		Return "0"
	End Method
	

	'attention: when used through LUA without param, the param gets "0"
	'instead of "-1"
	Method GetMoney:Int(day:Int=-1) {_exposeToLua}
		Return 0
	End Method

	'returns the financial of the given day
	'if the day is in the future, a new finance object is created
	Method GetFinance:TPlayerFinance(day:Int=-1) {_exposeToLua}
		return GetPlayerFinance(playerID, day)
	End Method


	'nothing up to now
	Method UpdateFinances:Int()
		'For Local i:Int = 0 To 6
		'
		'Next
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
		Local newImage:TImage = ColorizeImageCopy(newSprite.GetImage(), color, 0,0,0,1, 0, COLORIZEMODE_OVERLAY)
		Local figuresPack:TSpritePack = TSpritePack(GetRegistry().Get("gfx_figuresPack"))

		'clear occupied area within pixmap
		oldSprite.ClearImageData()
		'draw the new figure at that area
		DrawImageOnImage(newImage, figuresPack.image, oldSprite.area.GetX(), oldSprite.area.GetY())
	End Method


	'colorizes a figure and the corresponding sign next to the players doors in the building
	Method RecolorFigure(newColor:TPlayerColor = Null)
		If newColor = Null Then newColor = color
		color.ownerID = 0
		color = newColor
		color.ownerID = playerID
		UpdateFigureBase(figurebase)
	End Method


	Method Update:Int()
		'nothing up to now
	End Method


	Method Compare:Int(otherObject:Object)
		Local s:TPlayerBase = TPlayerBase(otherObject)
		If Not s Then Return 1
		If s.playerID > Self.playerID Then Return 1
		Return 0
	End Method


	Method IsActivePlayer:Int()
		Return (playerID = GetPlayerBaseCollection().playerID)
	End Method


	Method IsInRoom:Int(roomName:String="") {_exposeToLua}
		return GetFigure().IsInRoom(roomName)
	End Method

	'remove this helper as soon as "player" class gets a single importable
	'file
	Method SendToBoss:Int()
		'implement in real class
	End Method
End Type