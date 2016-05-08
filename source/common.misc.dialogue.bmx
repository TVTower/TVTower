SuperStrict
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.helper.bmx"


Type TDialogue
	'list of TDialogueTexts
	Field _texts:TList = CreateList()
	Field _currentTextIndex:Int = 0
	Field _rect:TRectangle = new TRectangle.Init(0,0,0,0)
	Field contentWidth:Int = 0
	Field dialogueType:string = "default"
	Field startType:string = "StartLeftDown"
	Field moveDialogueBalloonStart:int = 0


	Method SetArea:TDialogue(rect:TRectangle)
		_rect = rect.copy()
		contentWidth = _rect.GetW()
		Return Self
	End Method


	Method AddText(text:TDialogueTexts)
		_texts.AddLast(text)
	End Method


	Method AddTexts(texts:TDialogueTexts[])
		for local text:TDialogueTexts = EachIn texts
			_texts.AddLast(Text)
		Next
	End Method


	Method Update:Int()
		Local clicked:Int = 0
		if MouseManager.isClicked(1)
			clicked = 1
			MouseManager.resetKey(1)
		endif

		Local nextTextIndex:Int = _currentTextIndex
		If Self._texts.Count() > 0
			Local returnValue:Int = TDialogueTexts(_texts.ValueAtIndex(_currentTextIndex)).Update(_rect.getX() + 10, _rect.getY() + 10, contentWidth - 20 - 45, _rect.getH(), clicked)
			If returnValue <> -1 Then nextTextIndex = returnValue
		EndIf
		_currentTextIndex = nextTextIndex
		If _currentTextIndex = -2 Then _currentTextIndex = 0;Return 0
		Return 1
	End Method


	Function DrawDialog(dialogueType:String="default", x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogWidth:int = 0, DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TSprite = GetSpriteFromRegistry(DialogStart)
		height = Max(95, height ) 'minheight
		Select DialogStart
			case "StartLeftDown"
				dx = x - 48
				dy = y + Height/3 + DialogStartMove
				width :- 48
				if DialogWidth = 0 then DialogWidth = width - 15
			case "StartRightDown"
				dx = x + width - 12
				dy = y + Height/2 + DialogStartMove
				width :- 48
				if DialogWidth = 0 then DialogWidth = width - 15
			case "StartDownRight"
				dx = x + width/2 + DialogStartMove
				dy = y + Height - 12
				Height:-53
			case "StartDownLeft"
				dx = x + width/2 + DialogStartMove
				dy = y + Height - 12
				Height:-53
		End Select

		'limit text width to available width
		DialogWidth = Min(width - 10 - 10, DialogWidth)

		GetSpriteFromRegistry("dialogue."+dialogueType).DrawArea(x,y,width,height)
		DialogSprite.Draw(dx, dy)

		If DialogText <> ""
			DialogFont.drawBlock(DialogText, x + 10, y + 10, DialogWidth - 25, Height - 16, Null, TColor.clBlack)
		EndIf
	End Function



	Method Draw()
		SetColor 255, 255, 255
	    DrawDialog(dialogueType, int(_rect.getX()), int(_rect.getY()), int(_rect.getW()), int(_rect.getH()), startType, moveDialogueBalloonStart, "", contentWidth, GetBitmapFont("Default", 14))
		SetColor 0, 0, 0
		If Self._texts.Count() > 0
			TDialogueTexts(Self._texts.ValueAtIndex(Self._currentTextIndex)).Draw(_rect.getX() + 10, _rect.getY() + 10, contentWidth - 20 - 45, _rect.getH())
		endif
		SetColor 255, 255, 255
	End Method
End Type


'Answer - objects for dialogues
Type TDialogueAnswer
	Field _text:String = ""
	Field _leadsTo:Int = 0
	Field _onUseEvent:TEventBase
	Field _triggerFunction(data:TData)
	Field _triggerFunctionData:TData
	Field _highlighted:Int = 0
	Field _size:TVec2D = new TVec2D.Init(0,0)
	global _boldFont:TBitmapFont = null
	global _font:TBitmapFont = null


	Function Create:TDialogueAnswer (text:String, leadsTo:Int = 0, onUseEvent:TEventBase= Null, triggerFunction(data:TData) = Null, triggerFunctionData:TData = null)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text		= Text
		obj._leadsTo	= leadsTo
		obj._onUseEvent	= onUseEvent
		obj._triggerFunction = triggerFunction
		obj._triggerFunctionData = triggerFunctionData
		Return obj
	End Function


	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Self._highlighted = False

		If THelper.MouseIn(Int(x), int(y-2), _size.x + 9, _size.y)
			Self._highlighted = True
			If clicked
				'emit the event if there is one
				If _onUseEvent Then EventManager.triggerEvent(_onUseEvent)
				'run callback if there is one
				If _triggerFunction Then _triggerFunction(_triggerFunctionData)
				Return _leadsTo
			EndIf
		EndIf

		Return -1
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		if not _boldFont then _boldFont = GetBitmapFont("Default", 13, BOLDFONT)
		if not _font then _font = GetBitmapFont("Default", 13)

		'calculate sizes on base of the bold font (so it does not move
		'answers below the highlighted one
		_size = _boldFont.drawBlock(self._text, 0,0,w,h, null, null, 0, 0)

		
		If Self._highlighted
			SetColor 200,100,100
			DrawOval(x, y +3, 6, 6)
			_boldFont.drawBlock(Self._text, x+9, y-1, w-10, h, Null, TColor.Create(0, 0, 0))
		Else
			SetColor 0,0,0
			DrawOval(x, y +3, 6, 6)
			_font.drawBlock(Self._text, x+10, y, w-10, h, Null, TColor.Create(100, 100, 100))
		EndIf
	End Method
End Type




'Texts, maintext + list of answers to this said thing ;D
Type TDialogueTexts
	Field _text:String = ""
	Field _answers:TList = CreateList() 'of TDialogueAnswer
	Field _goTo:Int = -1
	Global font:TBitmapFont

	Function Create:TDialogueTexts(text:String)
		Local obj:TDialogueTexts = New TDialogueTexts
		obj._text = Text
		Return obj
	End Function


	Method AddAnswer(answer:TDialogueAnswer)
		Self._answers.AddLast(answer)
	End Method


	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Local ydisplace:Float = 0
		if font then ydisplace = font.GetBlockHeight(Self._text, w, h)

		ydisplace:+15 'displace answers a bit

		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(x + 9, y + ydisplace, w - 9, h, clicked)
			If returnValue <> - 1
				_goTo = returnValue
				'handled click
				clicked = False
			endif
			ydisplace :+ answer._size.y + 4
		Next
		Return _goTo
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		if not font then font = GetBitmapFont("Default", 14)
		Local ydisplace:Float = font.drawBlock(Self._text, x, y, w, h).getY()

		ydisplace:+15 'displace answers a bit

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer.Draw(x, y + ydisplace, w, h)
			ydisplace :+ answer._size.y + 4
		Next
	End Method
End Type





