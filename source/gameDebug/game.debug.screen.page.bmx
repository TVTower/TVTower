SuperStrict
Import "../game.ingameinterface.bmx"
Import "../game.player.base.bmx"

Type TDebugScreenPage
	Field position:SVec2I
	Field dimension:SVec2I
	Field buttons:TDebugControlsButton[]

	Global titleFont:TBitmapFont
	Global textFont:TBitmapFont
	Global textFontBold:TBitmapFont

	Method Init:TDebugScreenPage() abstract
	'what to do on deactivation (stop showing it)
	Method Deactivate() abstract
	'what to do on activation (begin showing it)
	Method Activate() abstract
	Method Reset() abstract
	Method Update() abstract
	Method Render() abstract

	Method MoveBy(dx:Int, dy:Int)
	End Method


	Method SetPosition(x:Int, y:Int) 
		Local move:SVec2I = new SVec2I(x - position.x, y - position.y)
		position = new SVec2I(x, y)

		MoveBy(move.x, move.y)
	End Method


	Method GetShownPlayerID:Int()
		If GetGameBase().gamestate <> TGameBase.STATE_RUNNING
			Return 1
		Else
			Local playerID:Int = GetPlayerBaseCollection().GetObservedPlayerID()
			If GetInGameInterface().ShowChannel > 0
				playerID = GetInGameInterface().ShowChannel
			EndIf
			If playerID <= 0 Then playerID = GetPlayerBase().playerID
			Return playerID
		EndIf
	End Method


	Function CreateActionButton:TDebugControlsButton(index:Int, text:String, x:Int, y:Int)
		Local button:TDebugControlsButton = New TDebugControlsButton
		button.h = 15
		button.w = 150
		button.x = x + 510 + 5
		button.y = y + index * (button.h + 3)
		button.dataInt = index
		button.text = text
		Return button
	End Function
	
	
	Function DrawWindow:SRectI(x:Int, y:Int, w:Int, h:int, caption:String, caption2:String = "", hAlignCaption:Float = 0.5, hAlignCaption2:Float = 1.0)
		TFunctions.DrawOutlineRect(x, y, w, h, New SColor8(0, 0, 0, 200), New SColor8(0,0,0, 125))
		
		Local captionHeight:Int = 0
		
		'set it to 0.49 to avoid correction if you really want the main
		'caption to be centered while caption2 is set too!
		if caption2 and hAlignCaption = 0.5
			hAlignCaption = 0.0 'left align main caption
		EndIf

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()

		If caption
			captionHeight = 14

			SetColor 100,100,100
			SetAlpha oldA * 0.75
			DrawRect(x + 2, y + 2, w - 4, captionHeight)

			SetAlpha oldA
			'-1 to include oversized "descend"
			textFontBold.DrawBox(caption, x + 2, y + 2 -1, w -4, captionHeight, new SVec2F(hAlignCaption, 0.5), SColor8.White)
		EndIf

		If caption2
			SetAlpha oldA
			SetColor oldCol

			captionHeight = 14
			'-1 to include oversized "descend"
			textFont.DrawBox(caption2, x + 2, y + 2 -1, w -4, captionHeight, new SVec2F(hAlignCaption2, 0.5), SColor8.White)
		EndIf

		SetAlpha oldA
		SetColor oldCol
		
		'return content rect
		If caption or caption2
			Return New SRectI(x + 2, y + 2 + captionHeight + 2, w - 4, h - 2 - captionHeight - 2)
		Else
			Return New SRectI(x + 2, y + 2, w - 4, h - 2)
		EndIf
	End Function


	Function DrawBorderRect(x:Int, y:Int, w:Int, h:Int, borderTop:Int = True, borderRight:Int = True, borderBottom:Int = True, borderLeft:Int = True, r:Int = 0, g:Int = 0, b:Int = 0, borderAlpha:Float = 0.75, bgAlpha:Float = 0.75)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		SetColor(r, g, b)

		SetAlpha(bgAlpha * oldColA)
		DrawRect(x+2, y+2, w-4, h-4)

		SetAlpha(borderAlpha * oldColA)
		If borderTop Then DrawRect(x, y, w, 2)
		If borderRight Then DrawRect(x + w - 2, y, 2, h)
		If borderBottom Then DrawRect(x, y + h - 2, w, 2)
		If borderLeft Then DrawRect(x, y, 2, h)

		SetAlpha(oldColA)
		SetColor(oldCol)
	End Function
End Type


rem
Struct SDebugClickBox
	Field callbackParam:Int
	Field callbackData:Object
	Field onClickCallback:Int(param:Int, data:Object = Null)
	Field onHoverCallback:Int(param:Int, data:Object = Null)
	Field position:SVec2I
	Field size:SVec2I
	Field hovered:Int = False
	Field clicked:Int = False

	
	Method New (position:SVec2I, size:SVec2I, hoverCallback:Int(param:Int, data:Object = Null) = Null, clickCallback:Int(param:Int, data:Object = Null) = Null, param:Int = 0, data:Object = Null)
		self.hovered = False
		self.clicked = False
		self.position = position
		self.size = size
		self.onHoverCallback = hoverCallback
		self.onClickCallback = clickCallback
		self.callbackParam = param
		self.callbackData = data
	End Method

	Method New (position:SVec2I, size:SVec2I, hoverCallback:Int(param:Int, data:Object = Null) = Null, clickCallback:Int(param:Int, data:Object = Null) = Null, param:Int)
		self.hovered = False
		self.clicked = False
		self.position = position
		self.size = size
		self.onHoverCallback = hoverCallback
		self.onClickCallback = clickCallback
		self.callbackParam = param
	End Method


	Method IsHovered:Int()
		Return hovered
	End Method


	Method Update()
		If THelper.MouseIn(position.x, position.y, size.x, size.y)
			hovered = True
			If onHoverCallback Then onHoverCallback(callbackParam, callbackData)
			
			'without callback we "ignore" clicks
			'If onClickCallback And MouseManager.IsClicked(1)
			
			If MouseManager.IsClicked(1)
				clicked = True
				If onClickCallback Then	onClickCallback(callbackParam, callbackData)

				MouseManager.SetClickHandled(1)
			EndIf
		EndIf
	End Method
End Struct
endrem


'a content block (eg to display some information about a studio or a programme)
Type TDebugContentBlock
	Field size:SVec2I
	Field contentSize:SVec2I
	Field contentPadding:SVec2I
	Field selected:Int
	Field hovered:Int


	Method New()
		contentPadding = New SVec2I(2,2)
	End Method


	Method SetHovered(bool:Int=True)
		hovered = False
	End Method


	Method SetSelected(bool:Int=True)
		selected = False
	End Method


	Method DrawBG(x:Int, y:Int, w:Int, h:Int)
		If selected
			SetColor 80,60,40
		ElseIf hovered
			SetColor 60,60,60
		Else
			SetColor 40,40,40
		EndIf
		DrawRect(x, y, w, h)

		If selected
			SetColor 90,70,50
		ElseIf hovered
			SetColor 70,70,70
		Else
			SetColor 50,40,40
		EndIf
		DrawRect(x+1, y+1, w-2, h-2)
		SetColor 255,255,255
	End Method


	Method Update(x:Int, y:Int)	
		If THelper.MouseIn(x,y, size.x, size.y)
			hovered = True
		Else
			hovered = False
		EndIf
	End Method


	Method Draw:SVec2I(x:Int, y:Int)
		'update size
		size = new SVec2I(2 * contentPadding.x + contentSize.x, 2 * contentPadding.y + contentSize.y)

		DrawBG(x, y, size.x, size.y)

		DrawContent(x, y)
	End Method


	Method DrawContent(x:Int, y:Int) abstract
'	End Method
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

		RenderButton(offsetX + x, offsetY + y, w, h, text, enabled, selected)
	End Method


	Function RenderButton(x:Int, y:Int, w:Int, h:Int, text:String, enabled:Int = True, selected:Int = False)
		Local oldColA:Float = GetAlpha()
		If Not enabled Then SetAlpha oldColA * 0.5 

		SetColor 150,150,150
		DrawRect(x,y,w,h)
		If selected
			If THelper.MouseIn(x,y,w,h)
				SetColor 120,110,100
			Else
				SetColor 80,70,50
			EndIf
		ElseIf THelper.MouseIn(x,y,w,h)
			SetColor 50,50,50
		Else
			SetColor 0,0,0
		EndIf

		DrawRect(x+1,y+1,w-2,h-2)
		SetColor 255,255,255
		GetBitmapFont("default", 10).DrawBox(text, x,y,w,h, sALIGN_CENTER_CENTER, SColor8.White)

		SetAlpha(oldColA)
	End Function


	Method onClick()
		selected = True
		clicked = True

		If _onClickHandler Then _onClickHandler(Self)
	End Method
End Type
