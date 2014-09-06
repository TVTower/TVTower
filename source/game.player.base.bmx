SuperStrict
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.player.finance.bmx"


Type TPlayerBase {_exposeToLua="selected"}
	'playername
	Field Name:String
	'name of the channel
	Field channelname:String
	'global used ID of the player
	Field playerID:Int = 0
	'the color used to colorize symbols and figures
	Field color:TColor
	'actual number of an array of figure-images
	Field figurebase:Int = 0
	'1=ready, 0=not set, ...
	Field networkstate:Int = 0
	Field CreditMaximum:Int	= 600000

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


	'returns the financial of the given day
	'if the day is in the future, a new finance object is created
	Method GetFinance:TPlayerFinance(day:Int=-1)
		return GetPlayerFinanceCollection().Get(playerID, day)
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
		color.ownerID = 0
		color = newColor
		color.ownerID = playerID
		UpdateFigureBase(figurebase)
	End Method


	'nothing up to now
	Method UpdateFinances:Int()
		'For Local i:Int = 0 To 6
		'
		'Next
	End Method
End Type