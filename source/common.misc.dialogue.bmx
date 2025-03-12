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
	Field _textIndex:Int = 0
	'original position and dimension
	Field _rawBalloonRect:TRectangle = New TRectangle
	'final position and dimension
	Field _balloonRect:TRectangle
	Field _contentRect:TRectangle
	Field _balloonGrow:Int = 0 '0 = none, 1 = down, -1 = up
	Field moveDialogueBalloonStart:Int = 0

	Field _rawAnswerBalloonRect:TRectangle = New TRectangle
	Field _answerBalloonRect:TRectangle
	Field _answerContentRect:TRectangle
	Field _lastAnswersHeight:int = -1
	Field _answerBalloonGrow:Int = -1 '0 = none, 1 = down, -1 = up
	Field moveAnswerDialogueBalloonStart:Int = 0

	Field _contentPadding:TRectangle 'custom padding?
	Field dialogueSprite:TSprite
	Field dialogueSpritePadding:TRectangle
	Field startType:String = "StartLeftDown"
	Field answerStartType:String = "StartRightDown"
	Global font:TBitmapFont
	Global textBlockDrawSettings:TDrawTextSettings = new TDrawTextSettings
	Global selectedAnswersDrawEffect:TDrawTextEffect = new TDrawTextEffect
	Global nullPadding:TRectangle = new TRectangle


	Method SetArea:TDialogue(rect:TRectangle)
		If rect Then _rawBalloonRect.CopyFrom( rect )
		Return Self
	End Method


	Method SetAnswerArea:TDialogue(rect:TRectangle)
		If rect Then _rawAnswerBalloonRect = rect.Copy()
		Return Self
	End Method
	
	
	Method SetDialogueSprite(s:TSprite)
		If dialogueSprite <> s
			dialogueSprite = s
			
			if s and s.IsNinePatch()
				Local r:sRect = s.GetNinePatchInformation().contentBorder
				if not dialogueSpritePadding then dialogueSpritePadding = New TRectangle
				dialogueSpritePadding.SetTLBR(r.x, r.y, r.w, r.h)
			endif

			'content padding might have changed!
			ResetRects()
		EndIf
	End Method
	
	
	Method GetDialogueSprite:TSprite()
		If Not dialogueSprite
			SetDialogueSprite( GetSpriteFromRegistry("dialogue.default") )
		EndIf
		Return dialogueSprite
	End Method


	Method ResetRects()
		_balloonRect = Null
		_contentRect = Null

		_answerBalloonRect = Null
		_answerContentRect = Null

		_lastAnswersHeight = -1
	End Method
	
	
	Method GetContentPadding:TRectangle()
		If _contentPadding
			Return _contentPadding
		Else
			If Not dialogueSpritePadding And Not dialogueSprite
				GetDialogueSprite()
			EndIf
			If dialogueSpritePadding
				Return dialogueSpritePadding
			EndIf
		EndIf
		
		Return nullPadding
	End Method


	Method GetBalloonRect:TRectangle()
		If Not _balloonRect
			_balloonRect = _rawBalloonRect.Copy()

			Local text:TDialogueTexts = GetDialogueText(Self._textIndex)
			If Not text Then Return _balloonRect

			If _balloonGrow <> 0
				'to find out how much height is needed, we need to calculate
				'the used height by the content of the balloon
				'the text is padded by "_contentPadding"
				local paddingHeight:Int = int(GetContentPadding().GetTop() + GetContentPadding().GetBottom())
				local contentWidth:Int = int(_balloonRect.w - (GetContentPadding().GetLeft() + GetContentPadding().GetRight()))
				'local contentHeight:Int = int(_balloonRect.h - (GetContentPadding().GetTop() + GetContentPadding().GetBottom()))

				'find out height without height limitation
				'give dialogue a minimum height of ... 100
				Local requiredHeight:Int = Max(100, text.GetTextHeight(new SVec2I(contentWidth, -1)) + paddingHeight)
				'need to grow?
				If _balloonRect.getH() < requiredHeight
					'down - nothing to do
					'if _balloonGrow = 1 then ...

					'up
					If _balloonGrow = -1 Then _balloonRect.MoveY(-(requiredHeight - _balloonRect.getH()))

					_balloonRect.SetH(requiredHeight)
				EndIf
			EndIf
		EndIf
		Return _balloonRect
	End Method


	Method GetContentRect:TRectangle()
		If Not _contentRect
			local cp:TRectangle = GetContentPadding()
			_contentRect = GetBalloonRect().copy().GrowTLBR(-cp.GetLeft(),-cp.GetTop(),-cp.GetRight(),-cp.GetBottom())
		EndIf
		Return _contentRect
	End Method


	Method GetAnswerBalloonRect:TRectangle()
		If Not _answerBalloonRect
			_answerBalloonRect = _rawAnswerBalloonRect.Copy()

			Local text:TDialogueTexts = GetDialogueText(Self._textIndex)
			If Not text Then Return _answerBalloonRect

			If _answerBalloonGrow <> 0
				'using a independent content-width-getter (to avoid 
				'circular dependency)
				Local usedHeight:Int = text.GetAnswersHeight( GetAnswerContentMaxWidth() )
				'add back content padding
				usedHeight :+ GetContentPadding().GetTop() + GetContentPadding().GetBottom()

				'print "usedHeight="+usedHeight + "  _answerBalloonRect.getH()="+_answerBalloonRect.getH()
				If _answerBalloonRect.getH() < usedHeight
					'down - nothing to do
					'if _answerBalloonGrow = 1 then ...

					'up
					If _answerBalloonGrow = -1 Then _answerBalloonRect.MoveXY(0, -(usedHeight - _answerBalloonRect.getH()) )

					_answerBalloonRect.SetH(usedHeight)
					
					'reset
					_answerContentRect = null
				EndIf
			EndIf

		EndIf

		Return _answerBalloonRect
	End Method
	
	
	Method GetAnswerContentMaxWidth:Int()
		'print "GetAnswerContentMaxWidth: " + _rawAnswerBalloonRect.w + " - " + GetContentPadding().GetLeft() + " - " + GetContentPadding().GetRight()
		Return _rawAnswerBalloonRect.w - GetContentPadding().GetLeft() - GetContentPadding().GetRight()
	End Method


	Method GetAnswerContentRect:TRectangle()
		If Not _answerContentRect
'			_answerContentRect = GetAnswerBalloonRect().copy().Grow(-GetContentPadding().GetX(),-GetContentPadding().GetY(),-GetContentPadding().GetW(),-GetContentPadding().GetH())
			local cp:TRectangle = GetContentPadding()
			_answerContentRect = GetAnswerBalloonRect().copy().GrowTLBR(-cp.GetTop(),-cp.GetLeft(),-cp.GetBottom(),-cp.GetRight())
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

		Return _texts[_textIndex]
	End Method


	Function DrawDialogueBalloon(dialogueSprite:TSprite, x:Int, y:Int, width:Int, Height:Int, DialogueStart:String = "StartDownLeft", DialogueStartMove:Int = 0, DialogueText:String = "", DialogueWidth:Int = 0, DialogueFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local dialogueStartSprite:TSprite = GetSpriteFromRegistry(DialogueStart)
		height = Max(40, height ) 'minheight

		Select DialogueStart
			Case "StartLeftUp", "StartLeftDown"
				dx = x - 48
				dy = y + 15 + DialogueStartMove
				If DialogueWidth = 0 Then DialogueWidth = width - 15
			Case "StartRightUp", "StartRightDown"
				dx = x + width - 11
				dy = y + 15 + DialogueStartMove
				If DialogueWidth = 0 Then DialogueWidth = width - 15
			Case "StartDownRight", "StartDownLeft"
				dx = x + 15 + DialogueStartMove
				dy = y + Height - 11
			Case "StartUpRight", "StartUpLeft"
				dx = x + 15 + DialogueStartMove
				dy = y + 8
		End Select

		'limit text width to available width
		DialogueWidth = Min(width - 10 - 10, DialogueWidth)

		dialogueSprite.DrawArea(x,y,width,height)
		dialogueStartSprite.Draw(dx, dy)

		If DialogueText Then DialogueFont.DrawBox(DialogueText, x + 10, y + 10, DialogueWidth - 25, Height - 16, SALIGN_LEFT_TOP, SColor8.Black)
	End Function


	Method Update:Int()
		Local nextTextIndex:Int = _textIndex

		Local dialogueText:TDialogueTexts = GetDialogueText(_textIndex)
		If dialogueText
			Local answersHeight:Int = dialogueText.GetAnswersHeight(GetAnswerContentMaxWidth())
			If answersHeight <> _lastAnswersHeight
				_lastAnswersHeight = answersHeight
				ResetRects()
			EndIf

			Local returnValue:Int = dialogueText.Update(GetContentRect(), GetAnswerContentRect())
			If returnValue <> -1 Then nextTextIndex = returnValue
		EndIf
		If _textIndex <> nextTextIndex
			_textIndex = nextTextIndex
			'refresh rectangle caches
			ResetRects()
		EndIf


		If _textIndex = -2
			_textIndex = 0
			Return 0
		Else
			Return 1
		EndIf
	End Method


	Method Draw()
		Local dialogueText:TDialogueTexts = GetDialogueText(Self._textIndex)
		If Not dialogueText Then Return

		Local answersHeight:Int = dialogueText.GetAnswersHeight(GetAnswerContentMaxWidth())
		If answersHeight <> _lastAnswersHeight
			_lastAnswersHeight = answersHeight
			ResetRects()
		EndIf

		'cache once
		if not font then font = GetBitmapFont("Default", 14)

		Local balloonRect:TRectangle = GetBalloonRect()
	    local answerBalloonRect:TRectangle = GetAnswerBalloonRect()
	    DrawDialogueBalloon(GetDialogueSprite(), Int(balloonRect.getX()), Int(balloonRect.GetY()), Int(balloonRect.getW()), Int(balloonRect.GetH()), startType, moveDialogueBalloonStart, "", Int(balloonRect.GetW()), font)
	    DrawDialogueBalloon(GetDialogueSprite(), Int(answerBalloonRect.getX()), Int(answerBalloonRect.getY()), Int(answerBalloonRect.getW()), Int(answerBalloonRect.getH()), answerStartType, moveAnswerDialogueBalloonStart, "", Int(answerBalloonRect.GetW()), font)

		dialogueText.DrawText(GetContentRect())
		'SetColor 0,255,255
		'TFunctions.DrawOutlineRect(int(GetAnswerBalloonRect().x -1), int(GetAnswerBalloonRect().y - 1), int(GetAnswerBalloonRect().w + 2), int(GetAnswerBalloonRect().h + 2))
		'SetColor 255,255,255

		dialogueText.DrawAnswers(GetAnswerContentRect())
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
		LoadFonts()
		If not _boldFont Then print "GetTextSize() called BEFORE bold font is loaded!"
			

		'calculate sizes on base of the bold font (so it does not move
		'answers below the highlighted one
		if _sizeForWidth <> w and _boldFont
			local s:SVec2I = _boldFont.GetBoxDimension(Self._text, w, -1)
			_size.SetXY(s.x, s.y)
			_sizeForWidth = w
		endif
		return _size
	End Method
	
	
	Function LoadFonts()
		If not _boldFont Then _boldFont = GetBitmapFont("Default", 13, BOLDFONT)
		If Not _font Then _font = GetBitmapFont("Default", 13)
	End Function


	Method GetBoxSize:SVec2I(answersBoxWidth:Int)
		local textSize:TVec2D = GetTextSize(answersBoxWidth - GetTextOffset().x)
		Return new SVec2I(int(textSize.x + GetTextOffset().x - _pos.x), int(textSize.y))
	End Method
	
	
	Method GetTextOffset:SVec2I()
		'return answers local offset + offset because of "bullet"
		Return new SVec2I(int(_pos.x + 9), 0)
	End Method
	

	Method Update:Int(screenRect:TRectangle)
		'check over complete width - to allow easier selection of short
		'texts
		If THelper.MouseIn(Int(screenRect.GetX()), Int(screenRect.GetY() + _pos.y), Int(screenRect.GetW()), GetBoxSize(int(screenRect.GetW())).y)
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


	Method GenerateCache(screenRect:TRectangle)

		if not _textCache then _textCache = new TBitmapFontText
		_oldColor.Get()

		If Self._highlighted
			SetColor 255,255,255
			if not _textCache.HasCache()
				'refresh _size
				local s:TVec2D = GetTextSize(int(screenRect.GetW() - GetTextOffset().x))
				_textCache.CacheDrawBlock(_font, Self._text, int(s.x), -2, SALIGN_LEFT_TOP, new SColor8(180,100,0), TDialogue.selectedAnswersDrawEffect, null)
			EndIf
		Else
			SetAlpha 0.9
			SetColor 100,100,100
			if not _textCache.HasCache()
				'refresh _size
				local s:TVec2D = GetTextSize(int(screenRect.GetW() - GetTextOffset().x))
				_textCache.CacheDrawBlock(_font, Self._text, int(s.x), -2, SALIGN_LEFT_TOP, _defaultColor)
			EndIf
		EndIf
		_oldColor.SetRGBA()
	End Method
	

	Method Draw(screenRect:TRectangle)
		LoadFonts()

		GenerateCache(screenRect)

'done by GenerateCache()
'		_oldColor.Get()

		if not _textCache then _textCache = new TBitmapFontText

		If Self._highlighted
			SetColor 180,100,100
			DrawOval(screenRect.GetX() + _pos.x, screenRect.GetY() + _pos.y +3, 6, 6)

			'avoid double tinting (especially of the "glow")
			SetColor 255,255,255
'done by GenerateCache()
rem
			if not _textCache.HasCache()
				'refresh _size
				GetTextSize(int(screenRect.GetW() - GetTextOffset().x))
				_textCache.CacheDrawBlock(_font, Self._text, int(_size.x), -2, SALIGN_LEFT_TOP, new SColor8(180,100,0), TDialogue.selectedAnswersDrawEffect, null)
			EndIf
endrem

			_textCache.DrawCached(screenRect.GetX() + _pos.x + 9, screenRect.GetY() + _pos.y -2 -2)
		Else
			SetAlpha 0.9
			SetColor 100,100,100
			DrawOval(screenRect.GetX() + _pos.x, screenRect.GetY() + _pos.y +3, 6, 6)
'done by GenerateCache()
rem
			if not _textCache.HasCache()
				'refresh _size
				GetTextSize(int(screenRect.GetW() - GetTextOffset().x))
				_textCache.CacheDrawBlock(_font, Self._text, int(_size.x), -2, SALIGN_LEFT_TOP, _defaultColor)
			EndIf
endrem
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


	Method GetAnswersHeight:Int(answersBoxWidth:Int)
		Local res:Int = 0
		For Local answer:TDialogueAnswer = EachIn(_answers)
			res :+ answer.GetBoxSize(answersBoxWidth).y
			res :+ 7
		Next
		res :- 7

		Return  res
	End Method
	
	
	Method MoveAnswers(answerRect:TRectangle)
		'move answers within the answerRect
		Local advanceY:Int = 0

		For Local answer:TDialogueAnswer = EachIn _answers
			answer._pos.SetXY(0, advanceY)
			advanceY :+ answer.GetBoxSize(Int(answerRect.w)).y
			advanceY :+ 7
		Next
	End Method
	
	
	Method Update:Int(textRect:TRectangle, answerRect:TRectangle)
		MoveAnswers(answerRect)

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
	

	Method DrawText(textRect:TRectangle)
		FillTextCache(new SVec2I(int(textRect.w), int(textRect.h)))
		_textCache.DrawCached(textRect.x, textRect.y)
	End Method


	Method DrawAnswers(answerRect:TRectangle)
		MoveAnswers(answerRect)

		'SetColor 0,255,255
		'TFunctions.DrawOutlineRect(int(answerRect.x -1), int(answerRect.y - 1), int(answerRect.w + 2), int(answerRect.h + 2))
		'SetColor 255,255,255

		For Local answer:TDialogueAnswer = EachIn _answers
			answer.Draw(answerRect)
		Next

rem
'debug view
		Local advanceY:Int = 0
		For Local answer:TDialogueAnswer = EachIn _answers
			SetColor 255,0, advanceY*50
			TFunctions.DrawOutlineRect(int(answerRect.x), int(answerRect.y + advanceY), int(answerRect.w), answer.GetBoxSize(Int(answerRect.w)).y)
			TFunctions.DrawOutlineRect(int(answerRect.x + answer.GetTextOffset().x), int(answerRect.y + advanceY), int(answerRect.w - answer.GetTextOffset().x), answer.GetBoxSize(Int(answerRect.w)).y)
			advanceY :+ answer.GetBoxSize(Int(answerRect.w)).y
			advanceY :+ 7
		Next
		SetColor 255,255,255
endrem
	End Method
End Type





