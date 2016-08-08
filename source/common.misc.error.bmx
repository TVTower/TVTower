SuperStrict

Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.vector.bmx"
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.helper.bmx"
Import "game.game.base.bmx"



Type TError
	Field title:String
	Field message:String
	Field id:Int
	Field link:TLink
	Field pos:TVec2D

	Global List:TList = CreateList()
	Global LastID:Int=0
	Global sprite:TSprite


	Function Create:TError(title:String, message:String)
		Local obj:TError =  New TError
		obj.title	= title
		obj.message	= message
		obj.id		= LastID
		LastID :+1
		If obj.sprite = Null Then obj.sprite = GetSpriteFromRegistry("gfx_errorbox")
		obj.pos		= New TVec2D.Init(400-obj.sprite.area.GetW()/2 +6, 200-obj.sprite.area.GetH()/2 +6)
		obj.link	= List.AddLast(obj)
		Return obj
	End Function

	Function hasActiveError:Int()
		Return (List.count() > 0)
	End Function


	Function CreateNotEnoughMoneyError()
		TError.Create(getLocale("ERROR_NOT_ENOUGH_MONEY"),getLocale("ERROR_NOT_ENOUGH_MONEY_TEXT"))
	End Function


	Function DrawErrors()
		Local error:TError = TError(List.Last())
		If error Then error.draw()
	End Function


	Function UpdateErrors()
		Local error:TError = TError(List.Last())
		If error Then error.Update()
	End Function


	Method Update()
		'no right clicking allowed as long as "error notice is active"
		MouseManager.ResetKey(2)
		'also avoid long-clicking (touch)
		MouseManager.ResetLongClicked(1)
		
		If Mousemanager.IsClicked(1)
			If THelper.MouseIn(Int(pos.x),Int(pos.y), Int(sprite.area.GetW()), Int(sprite.area.GetH()))
				link.Remove()
				MouseManager.resetKey(1) 'clicked to remove error
			EndIf
		EndIf
	End Method


	Function DrawNewError(str:String="unknown error")
		TError(TError.List.Last()).message = str
		TError.DrawErrors()
		Flip 0
	End Function


	Method Draw()
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(0,0,800, 385)
		SetAlpha 1.0
		GetGameBase().cursorstate = 0
		SetColor 255,255,255
		sprite.Draw(pos.x,pos.y)
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.area.GetW() - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.area.GetW()-40, sprite.area.GetH()-60, Null, TColor.Create(50, 50, 50))
  End Method
End Type
