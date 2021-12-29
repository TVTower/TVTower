SuperStrict
Import "game.ingameinterface.bmx"
Import "game.player.base.bmx"


Type TDebugScreenPage
	Field position:SVec2I
	Field dimension:SVec2I

	Global titleFont:TBitmapFont
	Global textFont:TBitmapFont
	Global textFontBold:TBitmapFont

	Method Init:TDebugScreenPage() abstract
	'what to do on deactivation (stop showing it)
	Method Deactivate() abstract
	'what to do on activation (begin showing it)
	Method Activate() abstract
	Method Update() abstract
	Method Render() abstract

	Method MoveBy(dx:Int, dy:Int)
	End Method

	
	Method SetPosition(x:Int, y:Int) 
		local move:SVec2I = new SVec2I(x - position.x, y - position.y)
		position = new SVec2I(x, y)
		
		MoveBy(move.x, move.y)
	End Method


	Method GetShownPlayerID:Int()
		Local playerID:Int = GetPlayerBaseCollection().GetObservedPlayerID()
		If GetInGameInterface().ShowChannel > 0
			playerID = GetInGameInterface().ShowChannel
		EndIf
		If playerID <= 0 Then playerID = GetPlayerBase().playerID
		Return playerID
	End Method


	Method CreateActionButton:TDebugControlsButton(index:int, text:String, x:Int, y:Int)
		Local button:TDebugControlsButton = New TDebugControlsButton
		button.h = 15
		button.w = 150
		button.x = x + 510 + 5
		button.y = y + index * (button.h + 3)
		button.dataInt = index
		button.text = text
		return button
	End Method


	Function DrawOutlineRect(x:int, y:int, w:int, h:int, borderTop:int = True, borderRight:int = True, borderBottom:int = True, borderLeft:Int = True, r:int = 0, g:int = 0, b:int = 0, borderAlpha:Float = 0.5, bgAlpha:Float = 0.5)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		SetColor(r, g, b)

		SetAlpha(bgAlpha * oldColA)
		DrawRect(x+2, y+2, w-4, h-4)

		SetAlpha(borderAlpha * oldColA)
		if borderTop then DrawRect(x, y, w, 2)
		if borderRight then DrawRect(x + w - 2, y, 2, h)
		if borderBottom then DrawRect(x, y + h - 2, w, 2)
		if borderLeft then DrawRect(x, y, 2, h)

		SetAlpha(oldColA)
		SetColor(oldCol)
	End Function
End Type



Type TDebugControlsButton
	Field data:Object
	Field dataInt:Int = -1
	Field text:String = "Button"
	Field x:Int = 0
	Field y:Int = 0
	Field w:Int = 150
	Field h:Int = 16
	Field selected:Int = False
	Field clicked:Int = False
	Field enabled:Int = True
	Field visible:Int = True
	Field _onClickHandler(sender:TDebugControlsButton)

	Method SetXY:TDebugControlsButton(x:Int, y:Int)
		self.x = x
		self.y = y
		Return self
	End Method

	Method SetWH:TDebugControlsButton(w:Int, h:Int)
		self.w = w
		self.h = h
		Return self
	End Method

	Method Update:Int(offsetX:Int=0, offsetY:Int=0)
		If Not visible Or Not Enabled Then Return False

		If THelper.MouseIn(offsetX + x,offsetY + y,w,h)
			If MouseManager.IsClicked(1)
				onClick()
				'handle clicked
				MouseManager.SetClickHandled(1)
				Return True
			EndIf
		EndIf
	End Method


	Method Render:Int(offsetX:Int=0, offsetY:Int=0)
		If Not visible Then Return False

		Local oldColA:Float = GetAlpha()
		If Not enabled Then SetAlpha oldColA * 0.5 

		SetColor 150,150,150
		DrawRect(offsetX + x,offsetY + y,w,h)
		If selected
			If THelper.MouseIn(offsetX + x,offsetY + y,w,h)
				SetColor 120,110,100
			Else
				SetColor 80,70,50
			EndIf
		ElseIf THelper.MouseIn(offsetX + x,offsetY + y,w,h)
			SetColor 50,50,50
		Else
			SetColor 0,0,0
		EndIf

		DrawRect(offsetX + x+1,offsetY + y+1,w-2,h-2)
		SetColor 255,255,255
		GetBitmapFont("default", 11).DrawBox(text, offsetX + x,offsetY + y,w,h, sALIGN_CENTER_CENTER, SColor8.White)
		
		SetAlpha(oldColA)
	End Method


	Method onClick()
		selected = True
		clicked = True

		If _onClickHandler Then _onClickHandler(Self)
	End Method
End Type

