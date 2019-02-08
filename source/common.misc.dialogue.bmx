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
	'original positions
	Field _rawBalloonRect:TRectangle = new TRectangle.Init(0,0,0,0)
	Field _rawAnswerBalloonRect:TRectangle = new TRectangle.Init(0,0,0,0)
	'cached vars
	Field _balloonRect:TRectangle
	Field _contentRect:TRectangle
	Field _answerBalloonRect:TRectangle
	Field _answerContentRect:TRectangle

	Field _contentPadding:TRectangle = new TRectangle.Init(10,15,15,15)
	Field _answerBalloonGrow:int = -1 '0 = none, 1 = down, -1 = up
	Field _balloonGrow:int = 0 '0 = none, 1 = down, -1 = up
	Field dialogueType:string = "default"
	Field startType:string = "StartLeftDown"
	Field answerStartType:string = "StartRightDown"
	Field moveDialogueBalloonStart:int = 0
	Field moveAnswerDialogueBalloonStart:int = 0


	Method SetArea:TDialogue(rect:TRectangle)
		if rect then _rawBalloonRect = rect.Copy()
		Return Self
	End Method


	Method SetAnswerArea:TDialogue(rect:TRectangle)
		if rect then _rawAnswerBalloonRect = rect.Copy()
		Return Self
	End Method


	Method ResetRects()
		_answerBalloonRect = null
		_answerContentRect = null
		_balloonRect = null
		_contentRect = null
	End Method


	Method GetBalloonRect:TRectangle()
		if not _balloonRect
			_balloonRect = _rawBalloonRect.Copy()


			local text:TDialogueTexts = GetDialogueText(Self._currentTextIndex)
			if not text then return _balloonRect

			local adjBalloonY:int = int(_balloonRect.getY())
			local adjBalloonH:int = int(_balloonRect.getH())

			if _balloonGrow <> 0
				local usedHeight:int = text.GetUsedHeight(_balloonRect) + _contentPadding.GetY() + _contentPadding.GetH()

				if _balloonRect.getH() < usedHeight
					'down - nothing to do
					'if _balloonGrow = 1 then ...

					'up
					if _balloonGrow = -1 then _balloonRect.position.y :- (usedHeight - _balloonRect.getH())

					_balloonRect.dimension.y = usedHeight
				endif
			endif
		endif
		return _balloonRect
	End Method


	Method GetContentRect:TRectangle()
		if not _contentRect
			_contentRect = GetBalloonRect().copy().Grow(-_contentPadding.GetX(),-_contentPadding.GetY(),-_contentPadding.GetW(),-_contentPadding.GetH())
		endif
		return _contentRect
	End Method


	Method GetAnswerBalloonRect:TRectangle()
		if not _answerBalloonRect
			_answerBalloonRect = _rawAnswerBalloonRect.Copy()


			local text:TDialogueTexts = GetDialogueText(Self._currentTextIndex)
			if not text then return _answerBalloonRect

			local adjBalloonY:int = int(_answerBalloonRect.getY())
			local adjBalloonH:int = int(_answerBalloonRect.getH())

			if _answerBalloonGrow <> 0
				local usedHeight:int = text.GetAnswersHeight() + _contentPadding.GetY() + _contentPadding.GetH()

				if _answerBalloonRect.getH() < usedHeight
					'down - nothing to do
					'if _answerBalloonGrow = 1 then ...

					'up
					if _answerBalloonGrow = -1 then _answerBalloonRect.position.y :- (usedHeight - _answerBalloonRect.getH())

					_answerBalloonRect.dimension.y = usedHeight
				endif
			endif

		endif
		return _answerBalloonRect
	End Method


	Method GetAnswerContentRect:TRectangle()
		if not _answerContentRect
			_answerContentRect = GetAnswerBalloonRect().copy().Grow(-_contentPadding.GetX(),-_contentPadding.GetY(),-_contentPadding.GetW(),-_contentPadding.GetH())
		endif
		return _answerContentRect
	End Method


	Method SetGrow(balloonGrow:int, answerBalloonGrow:int)
		_balloonGrow = balloonGrow
		_answerBalloonGrow = answerBalloonGrow
	End Method


	Method AddText(text:TDialogueTexts)
		_texts.AddLast(text)
	End Method


	Method AddTexts(texts:TDialogueTexts[])
		for local text:TDialogueTexts = EachIn texts
			_texts.AddLast(Text)
		Next
	End Method


	Method GetDialogueText:TDialogueTexts(index:int)
		if index < 0 or _texts.Count() <= index then return Null

		return TDialogueTexts(_texts.ValueAtIndex(_currentTextIndex))
	End Method



	Function DrawDialog(dialogueType:String="default", x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogWidth:int = 0, DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TSprite = GetSpriteFromRegistry(DialogStart)
		height = Max(40, height ) 'minheight

		Select DialogStart
			case "StartLeftDown"
				dx = x - 48
				dy = y + 15 + DialogStartMove
				if DialogWidth = 0 then DialogWidth = width - 15
			case "StartRightDown"
				dx = x + width - 11
				dy = y + 15 + DialogStartMove
				if DialogWidth = 0 then DialogWidth = width - 15
			case "StartDownRight"
				dx = x + 15 + DialogStartMove
				dy = y + Height - 11
			case "StartDownLeft"
				dx = x + 15 + DialogStartMove
				dy = y + Height - 11
		End Select

		'limit text width to available width
		DialogWidth = Min(width - 10 - 10, DialogWidth)

		GetSpriteFromRegistry("dialogue."+dialogueType).DrawArea(x,y,width,height)
		DialogSprite.Draw(dx, dy)

		If DialogText <> ""
			DialogFont.drawBlock(DialogText, x + 10, y + 10, DialogWidth - 25, Height - 16, Null, TColor.clBlack)
		EndIf
	End Function


	Method Update:Int()
		Local nextTextIndex:Int = _currentTextIndex

		local dialogueText:TDialogueTexts = GetDialogueText(_currentTextIndex)
		if dialogueText
			local answersHeight:int = dialogueText.GetAnswersHeight()
			if answersHeight <> GetAnswerContentRect().GetH()
				'min height?
				if answersHeight > _rawAnswerBalloonRect.GetH()
					ResetRects()
				endif
			endif

			Local returnValue:Int = dialogueText.Update(GetContentRect(), GetAnswerContentRect())
			If returnValue <> -1 Then nextTextIndex = returnValue
		EndIf
		if _currentTextIndex <> nextTextIndex
			_currentTextIndex = nextTextIndex
			'refresh rectangle caches
			ResetRects()
		endif



		If _currentTextIndex = -2
			_currentTextIndex = 0
			Return 0
		else
			Return 1
		endif
	End Method


	Method Draw()
		local dialogueText:TDialogueTexts = GetDialogueText(Self._currentTextIndex)
		if not dialogueText then return

		local answersHeight:int = dialogueText.GetAnswersHeight()
		if answersHeight <> GetAnswerContentRect().GetH()
			'min height? - disabled to avoid wrong cache informations
			'TODO: find out reason
'			if answersHeight > _rawAnswerBalloonRect.GetH()
				ResetRects()
'			endif
		endif

	    DrawDialog(dialogueType, int(GetBalloonRect().getX()), int(GetBalloonRect().GetY()), int(GetBalloonRect().getW()), int(GetBalloonRect().GetH()), startType, moveDialogueBalloonStart, "", int(GetBalloonRect().GetW()), GetBitmapFont("Default", 14))
	    DrawDialog(dialogueType, int(GetAnswerBalloonRect().getX()), int(GetAnswerBalloonRect().getY()), int(GetAnswerBalloonRect().getW()), int(GetAnswerBalloonRect().getH()), answerStartType, moveAnswerDialogueBalloonStart, "", int(GetAnswerBalloonRect().GetW()), GetBitmapFont("Default", 14))

		dialogueText.Draw(GetContentRect(), GetAnswerContentRect())
	End Method
End Type


'Answer - objects for dialogues
Type TDialogueAnswer
	Field _pos:TVec2D = new TVec2D.Init(0,0)
	Field _size:TVec2D = new TVec2D.Init(0,0)
	Field _text:String = ""
	Field _leadsTo:Int = 0
	Field _onUseEvent:TEventBase
	Field _triggerFunction(data:TData)
	Field _triggerFunctionData:TData
	Field _highlighted:Int = 0
	global _boldFont:TBitmapFont = null
	global _font:TBitmapFont = null


	Function Create:TDialogueAnswer(text:String, leadsTo:Int = 0, onUseEvent:TEventBase= Null, triggerFunction(data:TData) = Null, triggerFunctionData:TData = null)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text = Text
		obj._leadsTo = leadsTo
		obj._onUseEvent	= onUseEvent
		obj._triggerFunction = triggerFunction
		obj._triggerFunctionData = triggerFunctionData
		Return obj
	End Function


	Method Update:Int(screenRect:TRectangle)
		Self._highlighted = False

		if not _size and _boldFont
			_size = _boldFont.GetBlockDimension(self._text, screenRect.GetW() - _pos.y, -1)
		endif

		'check over complete width - to allow easier selection of short
		'texts
		If THelper.MouseIn(int(screenRect.GetX()), int(screenRect.GetY() + _pos.y), int(screenRect.GetW()), int(_size.y))
			Self._highlighted = True
			If MouseManager.isClicked(1)
				'emit the event if there is one
				If _onUseEvent Then EventManager.triggerEvent(_onUseEvent)
				'run callback if there is one
				If _triggerFunction Then _triggerFunction(_triggerFunctionData)

				MouseManager.ResetKey(1)

				Return _leadsTo
			EndIf
		EndIf

		Return -1
	End Method


	Method Draw(screenRect:TRectangle)
		if not _boldFont then _boldFont = GetBitmapFont("Default", 13, BOLDFONT)
		if not _font then _font = GetBitmapFont("Default", 13)

		'calculate sizes on base of the bold font (so it does not move
		'answers below the highlighted one
		if not _size then _size = new TVec2D
		_size.CopyFrom(_boldFont.GetBlockDimension(self._text, screenRect.GetW() - _pos.y, -1))

		local oldColor:TColor = new TColor.Get()

		If Self._highlighted
			SetColor 200,100,100
			DrawOval(screenRect.GetX() + _pos.x, screenRect.GetY() + _pos.y +3, 6, 6)
			_boldFont.drawBlock(Self._text, screenRect.GetX() + _pos.x + 9, screenRect.GetY() + _pos.y -1, _size.x, -1, Null, TColor.clBlack)
		Else
			SetAlpha 0.9
			SetColor 100,100,100
			DrawOval(screenRect.GetX() + _pos.x, screenRect.GetY() + _pos.y +3, 6, 6)
			_font.drawBlock(Self._text, screenRect.GetX() + _pos.x + 9, screenRect.GetY() + _pos.y -1, _size.x, -1, Null, TColor.CreateGrey(100))
		EndIf

		oldColor.SetRGBA()
	End Method
End Type




'Texts, maintext + list of answers to this said thing ;D
Type TDialogueTexts
	Field _text:String = ""
	Field _answers:TList = CreateList() 'of TDialogueAnswer
	Field _goTo:Int = -1
	Field contentChanged:int = False
	'cache
	Field _textUsedHeight:Int = -1
	Global _font:TBitmapFont

	Function Create:TDialogueTexts(text:String)
		Local obj:TDialogueTexts = New TDialogueTexts
		obj.SetText(text)
		Return obj
	End Function


	Method AddAnswer(answer:TDialogueAnswer)
		Self._answers.AddLast(answer)

		contentChanged = True
	End Method


	Method GetAnswersHeight:int()
		local res:int = 0
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			res :+ answer._size.y
			res :+ 7
		Next
		res :- 7

		return  res
	End Method


	Method Update:Int(textRect:TRectangle, answerRect:TRectangle)
		'move answers within the answerRect
		local advanceY:int = 0
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer._pos.SetXY(0, advanceY)
			advanceY :+ answer._size.y
			advanceY :+ 7
		Next


		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(answerRect)
			If returnValue <> - 1
				_goTo = returnValue
			endif
		Next
		Return _goTo
	End Method


	Method SetText:int(text:string)
		_text = Text
		_textUsedHeight = -1
	End Method


	Method GetUsedHeight:int(textRect:TRectangle)
		if not _font then _font = GetBitmapFont("Default", 14)

		if _textUsedHeight = -1 and _font
			_textUsedHeight = _font.GetBlockHeight(Self._text, textRect.GetW(), textRect.GetH())
		endif
		return _textUsedHeight
	End Method


	Method Draw(textRect:TRectangle, answerRect:TRectangle)
		if not _font then _font = GetBitmapFont("Default", 14)
		'draw text and also calculate used height
		_textUsedHeight = _font.DrawBlock(Self._text, textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), null, TColor.clBlack).GetY()

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer.Draw(answerRect)
		Next
	End Method
End Type





