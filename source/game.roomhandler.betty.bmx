SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.player.base.bmx"
Import "common.misc.dialogue.bmx"



'Betty
Type RoomHandler_Betty extends TRoomHandler
	Global _instance:RoomHandler_Betty


	Function GetInstance:RoomHandler_Betty()
		if not _instance then _instance = new RoomHandler_Betty
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS =====
		'nothing up to now


		'=== EVENTS ===
		'nothing up to now


		'(re-)localize content
		SetLanguage()
	End Method
	

	Method CleanUp()
		'=== unset cross referenced objects ===
		'
		
		'=== remove obsolete gui elements ===
		'

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("betty", GetInstance())
	End Method
	

	Method onDrawRoom:int( triggerEvent:TEventBase )
		For Local i:Int = 1 To 4
			local sprite:TSprite = GetSpriteFromRegistry("gfx_room_betty_picture1")
			Local picY:Int = 240
			Local picX:Int = 410 + i * (sprite.area.GetW() + 5)
			sprite.Draw( picX, picY )
			SetAlpha 0.4
			GetPlayerBase(i).color.copy().AdjustRelative(-0.5).SetRGB()
			DrawRect(picX + 2, picY + 8, 26, 28)
			SetColor 255, 255, 255
			SetAlpha 1.0
			local x:float = picX + Int(sprite.area.GetW() / 2) - Int(GetPlayerBase(i).Figure.Sprite.framew / 2)
			local y:float = picY + sprite.area.GetH() - 30
			GetPlayerBase(i).Figure.Sprite.DrawClipped(new TRectangle.Init(x, y, -1, sprite.area.GetH()-16), null, 8)
		Next

		TDialogue.DrawDialog("default", 440, 120, 280, 110, "StartLeftDown", 0, GetLocale("DIALOGUE_BETTY_WELCOME"), 0, GetBitmapFont("Default",14))
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'nothing yet
	End Method
End Type
