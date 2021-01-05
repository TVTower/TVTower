SuperStrict
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.helper.bmx"

TDialogue.textBlockDrawSettings.data.lineHeight = 16
TDialogue.textBlockDrawSettings.data.boxDimensionMode = 0
'TDialogue.selectedAnswersDrawEffect.data.Init(EDrawTextEffect.Glow, 0.2, new SColor8(255,200,200))
TDialogue.selectedAnswersDrawEffect.data.Init(EDrawTextEffect.Glow, 0.1, new SColor8(110,90,65))


Type TDialogue
	'list of TDialogueTexts
	Field _texts:TDialogueTexts[]
	Field _currentTextIndex:Int = 0
	'original positions
	Field _rawBalloonRect:TRectangle = New TRectangle
	Field _rawAnswerBalloonRect:TRectangle = New TRectangle
	'cached vars
	Field _balloonRect:TRectangle
	Field _contentRect:TRectangle
	Field _answerBalloonRect:TRectangle
	Field _answerContentRect:TRectangle
	Field _lastAnswersHeight:int = -1
	Field _contentPadding:TRectangle = New TRectangle.Init(10,15,15,15)
	Field _answerBalloonGrow:Int = -1 '0 = none, 1 = down, -1 = up
	Field _balloonGrow:Int = 0 '0 = none, 1 = down, -1 = up
	Field dialogueType:String = "default"
	Field startType:String = "StartLeftDown"
	Field answerStartType:String = "StartRightDown"
	Field moveDialogueBalloonStart:Int = 0
	Field moveAnswerDialogueBalloonStart:Int = 0
	Global font:TBitmapFont
	Global textBlockDrawSettings:TDrawTextSettings = new TDrawTextSettings
	Global selectedAnswersDrawEffect:TDrawTextEffect = new TDrawTextEffect


	Method SetArea:TDialogue(rect:TRectangle)
		If rect Then _rawBalloonRect.CopyFrom( rect )
		Return Self
	End Method


	Method SetAnswerArea:TDialogue(rect:TRectangle)
		If rect Then _rawAnswerBalloonRect = rect.Copy()
		Return Self
	End Method


	Method ResetRects()
		_answerBalloonRect = Null
		_answerContentRect = Null
		_balloonRect = Null
		_contentRect = Null
	End Method


	Method GetBalloonRect:TRectangle()
		If Not _balloonRect
			_balloonRect = _rawBalloonRect.Copy()


			Local text:TDialogueTexts = GetDialogueText(Self._currentTextIndex)
			If Not text Then Return _balloonRect

			Local adjBalloonY:Int = Int(_balloonRect.getY())
			Local adjBalloonH:Int = Int(_balloonRect.getH())

			If _balloonGrow <> 0
				local paddingWidth:Int = _contentPadding.GetLeft() + _contentPadding.GetRight()
				local paddingHeight:Int = _contentPadding.GetTop() + _contentPadding.GetBottom()
				Local contentDim:SVec2I = new SVec2I(int(_balloonRect.dimension.x - paddingWidth), int(_balloonRect.dimension.y - paddingHeight))

				'find out height without "limit"
				'give dialogue a minimum height of ... 100
				Local requiredHeight:Int = Max(100, text.GetTextHeight(new SVec2I(contentDim.x, -1)) + paddingHeight)

				'need to grow?
				If _balloonRect.getH() < requiredHeight
					'down - nothing to do
					'if _balloonGrow = 1 then ...

					'up
					If _balloonGrow = -1 Then _balloonRect.MoveXY(0, -(requiredHeight - _balloonRect.getH()) )

					_balloonRect.dimension.y = requiredHeight 
				EndIf
			EndIf
		EndIf
		Return _balloonRect
	End Method


	Method GetContentRect:TRectangle()
		If Not _contentRect
			_contentRect = GetBalloonRect().copy().Grow(-_contentPadding.GetLeft(),-_contentPadding.GetTop(),-_contentPadding.GetRight(),-_contentPadding.GetBottom())
		EndIf
		Return _contentRect
	End Method


	Method GetAnswerBalloonRect:TRectangle()
		If Not _answerBalloonRect
			_answerBalloonRect = _rawAnswerBalloonRect.Copy()


			Local text:TDialogueTexts = GetDialogueText(Self._currentTextIndex)
			If Not text Then Return _answerBalloonRect

			Local adjBalloonY:Int = Int(_answerBalloonRect.getY())
			Local adjBalloonH:Int = Int(_answerBalloonRect.getH())

			If _answerBalloonGrow <> 0
				Local usedHeight:Int = text.GetAnswersHeight() + _contentPadding.GetY() + _contentPadding.GetH()

				If _answerBalloonRect.getH() < usedHeight
					'down - nothing to do
					'if _answerBalloonGrow = 1 then ...

					'up
					If _answerBalloonGrow = -1 Then _answerBalloonRect.MoveXY(0, -(usedHeight - _answerBalloonRect.getH()) )

					_answerBalloonRect.dimension.y = usedHeight
				EndIf
			EndIf

		EndIf
		Return _answerBalloonRect
	End Method


	Method GetAnswerContentRect:TRectangle()
		If Not _answerContentRect
			_answerContentRect = GetAnswerBalloonRect().copy().Grow(-_contentPadding.GetX(),-_contentPadding.GetY(),-_contentPadding.GetW(),-_contentPadding.GetH())
		EndIf
		Return _answerContentRect
	End Method


	Method SetGrow(balloonGrow:Int, answerBalloonGrow:Int)
		_balloonGrow = balloonGrow
		_answerBalloonGrow = answerBalloonGrow
	End Method


	Method AddText(text:TDialogueTexts)
		_texts :+ [text]
	End Method


	Method AddTexts(texts:TDialogueTexts[])
		_texts :+ texts
	End Method


	Method GetDialogueText:TDialogueTexts(index:Int)
		If index < 0 Or _texts.length <= index Then Return Null

		Return _texts[_currentTextIndex]
	End Method


	Function DrawDialog(dialogueType:String="default", x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogWidth:Int = 0, DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TSprite = GetSpriteFromRegistry(DialogStart)
		height = Max(40, height ) 'minheight

		Select DialogStart
			Case "StartLeftUp", "StartLeftDown"
				dx = x - 48
				dy = y + 15 + DialogStartMove
				If DialogWidth = 0 Then DialogWidth = width - 15
			Case "StartRightUp", "StartRightDown"
				dx = x + width - 11
				dy = y + 15 + DialogStartMove
				If DialogWidth = 0 Then DialogWidth = width - 15
			Case "StartDownRight", "StartDownLeft"
				dx = x + 15 + DialogStartMove
				dy = y + Height - 11
			Case "StartUpRight", "StartUpLeft"
				dx = x + 15 + DialogStartMove
				dy = y + 8
		End Select

		'limit text width to available width
		DialogWidth = Min(width - 10 - 10, DialogWidth)

		GetSpriteFromRegistry("dialogue."+dialogueType).DrawArea(x,y,width,height)
		DialogSprite.Draw(dx, dy)

		If DialogText Then DialogFont.DrawBox(DialogText, x + 10, y + 10, DialogWidth - 25, Height - 16, SALIGN_LEFT_TOP, SColor8.Black)
	End Function


	Method Update:Int()
		Local nextTextIndex:Int = _currentTextIndex

		Local dialogueText:TDialogueTexts = GetDialogueText(_currentTextIndex)
		If dialogueText
			Local answersHeight:Int = dialogueText.GetAnswersHeight()
			If answersHeight <> _lastAnswersHeight
				_lastAnswersHeight = answersHeight
				ResetRects()
			EndIf

			Local returnValue:Int = dialogueText.Update(GetContentRect(), GetAnswerContentRect())
			If returnValue <> -1 Then nextTextIndex = returnValue
		EndIf
		If _currentTextIndex <> nextTextIndex
			_currentTextIndex = nextTextIndex
			'refresh rectangle caches
			ResetRects()
		EndIf


		If _currentTextIndex = -2
			_currentTextIndex = 0
			Return 0
		Else
			Return 1
		EndIf
	End Method


	Method Draw()
		Local dialogueText:TDialogueTexts = GetDialogueText(Self._currentTextIndex)
		If Not dialogueText Then Return

		Local answersHeight:Int = dialogueText.GetAnswersHeight()
		If answersHeight <> _lastAnswersHeight
			_lastAnswersHeight = answersHeight
			ResetRects()
		EndIf

		'cache once
		if not font then font = GetBitmapFont("Default", 14)

	    DrawDialog(dialogueType, Int(GetBalloonRect().getX()), Int(GetBalloonRect().GetY()), Int(GetBalloonRect().getW()), Int(GetBalloonRect().GetH()), startType, moveDialogueBalloonStart, "", Int(GetBalloonRect().GetW()), font)
	    DrawDialog(dialogueType, Int(GetAnswerBalloonRect().getX()), Int(GetAnswerBalloonRect().getY()), Int(GetAnswerBalloonRect().getW()), Int(GetAnswerBalloonRect().getH()), answerStartType, moveAnswerDialogueBalloonStart, "", Int(GetAnswerBalloonRect().GetW()), font)

		dialogueText.Draw(GetContentRect(), GetAnswerContentRect())
	End Method
End Type


'Answer - objects for dialogues
Type TDialogueAnswer
	Field _pos:TVec2D = New TVec2D
	Field _size:TVec2D = New TVec2D
	Field _sizeForWidth:Int = -1
	Field _text:String = ""
	Field _textCache:TBitmapFontText
	Field _leadsTo:Int = 0
	Field _onUseEvent:TEventBase
	Field _triggerFunction(data:TData)
	Field _triggerFunctionData:TData
	Field _highlighted:Int = 0
	Global _defaultColor:SColor8 = new SColor8(100, 100, 100)
	Global _oldColor:TColor = new TColor
	Global _boldFont:TBitmapFont = Null
	Global _font:TBitmapFont = Null


	Function Create:TDialogueAnswer(text:String, leadsTo:Int = 0, onUseEvent:TEventBase= Null, triggerFunction(data:TData) = Null, triggerFunctionData:TData = Null)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text = Text
		obj._leadsTo = leadsTo
		obj._onUseEvent	= onUseEvent
		obj._triggerFunction = triggerFunction
		obj._triggerFunctionData = triggerFunctionData
		Return obj
	End Function


	Method SetText(t:string)
		_text = t
		_sizeForWidth = -1
		if _textCache then _textCache.Invalidate()
	End Method


	Method GetTextSize:TVec2D(w:int)
		'calculate sizes on base of the bold font (so it does not move
		'answers below the highlighted one
		if _sizeForWidth <> w and _boldFont
			local s:SVec2I = _boldFont.GetBoxDimension(Self._text, w, -1)
			_size.Init(s.x, s.y)
			_sizeForWidth = w
		endif
		return _size
	End Method


	Method Update:Int(screenRect:TRectangle)
		'check over complete width - to allow easier selection of short
		'texts
		If THelper.MouseIn(Int(screenRect.GetX()), Int(screenRect.GetY() + _pos.y), Int(screenRect.GetW()), Int(GetTextSize(int(screenRect.GetW() - _pos.x - 9)).y))
			if not _highlighted and _textCache then _textCache.Invalidate()
			_highlighted = True

			If MouseManager.isClicked(1)
				'emit the event if there is one
				If _onUseEvent Then EventManager.triggerEvent(_onUseEvent)
				'run callback if there is one
				If _triggerFunction Then _triggerFunction(_triggerFunctionData)

				'handled left click
				MouseManager.SetClickHandled(1)

				Return _leadsTo
			EndIf
		else
			if _highlighted and _textCache then _textCache.Invalidate()
			_highlighted = False
		EndIf

		Return -1
	End Method


	Method Draw(screenRect:TRectangle)
		If Not _boldFont Then _boldFont = GetBitmapFont("Default", 13, BOLDFONT)
		If Not _font Then _font = GetBitmapFont("Default", 13)


		_oldColor.Get()

		if not _textCache then _textCache = new TBitmapFontText

		If Self._highlighted
			SetColor 180,100,100
			DrawOval(screenRect.GetX() + _pos.x, screenRect.GetY() + _pos.y +3, 6, 6)

			'avoid double tinting (especially of the "glow")
			SetColor 255,255,255
			if not _textCache.HasCache()
				'refresh _size
				GetTextSize(int(screenRect.GetW() - _pos.x - 9))
				_textCache.CacheDrawBlock(_font, Self._text, int(_size.x), -2, SALIGN_LEFT_TOP, new SColor8(180,100,0), TDialogue.selectedAnswersDrawEffect, null)
			EndIf

			_textCache.DrawCached(screenRect.GetX() + _pos.x + 9, screenRect.GetY() + _pos.y -2 -2)
		Else
			SetAlpha 0.9
			SetColor 100,100,100
			DrawOval(screenRect.GetX() + _pos.x, screenRect.GetY() + _pos.y +3, 6, 6)
			if not _textCache.HasCache()
				'refresh _size
				GetTextSize(int(screenRect.GetW() - _pos.x - 9))
				_textCache.CacheDrawBlock(_font, Self._text, int(_size.x), -2, SALIGN_LEFT_TOP, _defaultColor)
			EndIf
			'draw offset a bit so "glow" of selected stays at same position
			_textCache.DrawCached(screenRect.GetX() + _pos.x + 9 +2, screenRect.GetY() + _pos.y -2)
		EndIf

		_oldColor.SetRGBA()
	End Method
End Type




'Texts, maintext + list of answers to this said thing ;D
Type TDialogueTexts
	Field _text:String = ""
	Field _textCache:TBitmapFontText = new TBitmapFontText
	Field _answers:TDialogueAnswer[]
	Field _goTo:Int = -1
	Field contentChanged:Int = False
	Global _font:TBitmapFont

	Function Create:TDialogueTexts(text:String)
		Local obj:TDialogueTexts = New TDialogueTexts
		obj.SetText(text)
		Return obj
	End Function


	Method AddAnswer(answer:TDialogueAnswer)
		_answers :+ [answer]

		contentChanged = True
	End Method


	Method GetAnswersHeight:Int()
		Local res:Int = 0
		For Local answer:TDialogueAnswer = EachIn(_answers)
			res :+ answer._size.y
			res :+ 7
		Next
		res :- 7

		Return  res
	End Method


	Method Update:Int(textRect:TRectangle, answerRect:TRectangle)
		'move answers within the answerRect
		Local advanceY:Int = 0
		For Local answer:TDialogueAnswer = EachIn _answers
			answer._pos.SetXY(0, advanceY)
			advanceY :+ answer._size.y
			advanceY :+ 7
		Next


		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn _answers
			Local returnValue:Int = answer.Update(answerRect)
			If returnValue <> - 1
				_goTo = returnValue
			EndIf
		Next
		Return _goTo
	End Method


	Method SetText:Int(text:String)
		If _text <> text
			_text = Text
			if _textCache then _textCache.Invalidate()
		EndIf
	End Method


	Method GetTextHeight:int(textDim:SVec2I)
		FillTextCache(textDim)
		return _textCache.cache.height
	End Method


	Method FillTextCache(textDim:SVec2I)
		if not _textCache then _textCache = new TBitmapFontText
		if not _textCache.HasCache() or textDim.x <> _textCache.textBoxDimension.x or (textDim.y <> -1 and textDim.y <> _textCache.textBoxDimension.y)
			If Not _font Then _font = GetBitmapFont("Default", 14)

			_textCache.CacheDrawBlock(_font, _text, textDim.x, textDim.y, SALIGN_LEFT_TOP, SColor8.Black, _font.defaultDrawEffect, TDialogue.textBlockDrawSettings.data)
		endif
	End Method


	Method Draw(textRect:TRectangle, answerRect:TRectangle)
		FillTextCache(new SVec2I(int(textRect.dimension.x), int(textRect.dimension.y)))
		_textCache.DrawCached(textRect.GetX(), textRect.GetY())

		For Local answer:TDialogueAnswer = EachIn _answers
			answer.Draw(answerRect)
		Next
	End Method
End Type





