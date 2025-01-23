SuperStrict
Import "base.util.helper.bmx"
Import "base.gfx.gui.panel.scrollablepanel.bmx"
Import "base.gfx.gui.scroller.bmx"


Type TGUITextArea Extends TGUIobject
	Field guiTextPanel:TGUIScrollablePanel = Null
	Field guiScrollerH:TGUIScroller = Null
	Field guiScrollerV:TGUIScroller	= Null
	Field _drawTextSettings:TDrawTextSettings
	Field _drawTextEffect:TDrawTextEffect
	Field _textParseInfo:TTextParseInfo
	Field _textDimension:SVec2I = new SVec2I(200, 1200)
	Field _textDimensionValid:Int = False
	Field _textCacheImage:TImage
	Field _textCacheImageVisibleMin:SVec2I
	Field _textCacheImageVisibleMax:SVec2I
	Field _textCacheImageOffset:SVec2I
	'pre-cached content both directions of each axis
	Field _textCacheImagePreload:SVec2I = new SVec2I(150,150)
	Field _textCacheImageValid:int = False
	Field textColor:SColor8 = new SColor8.Black
	Field backgroundColor:SColor8 = new SColor8(0,0,0,0)
	Field backgroundColorHovered:SColor8 = new SColor8(0,0,0,0)
	Field _mouseOverArea:Int = False
	Field _verticalScrollerAllowed:int = True
	Field _horizontalScrollerAllowed:int = True
	
	Global _defaultDrawTextSettings:TDrawTextSettings = new TDrawTextSettings
	Global _defaultDrawTextEffect:TDrawTextEffect = new TDrawTextEffect


	Method GetClassName:String()
		Return "tguitextarea"
	End Method


	Method Create:TGUITextArea(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.CreateBase(position, dimension, limitState)

		'setZIndex(0)

		guiScrollerH = New TGUIScroller.Create(Self)
		guiScrollerV = New TGUIScroller.Create(Self)
		'orientation of horizontal scroller has to get set manually
		guiScrollerH.SetOrientation(GUI_OBJECT_ORIENTATION_HORIZONTAL)

		guiTextPanel = New TGUIScrollablePanel.Create(new SVec2I(0,0), new SVec2I(int(rect.w - guiScrollerV.rect.w), int(rect.h - guiScrollerH.rect.h)), limitState)

		AddChild(guiScrollerH)
		AddChild(guiScrollerV)
		AddChild(guiTextPanel) 'manage by our own


		'by default all lists do not have scrollers
		setScrollerState(False, False)

		'the text panel cannot be focused
		guiTextPanel.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		'this element reacts to keystrokes (cursor up/down, page up/down ...)
		SetOption(GUI_OBJECT_CAN_RECEIVE_KEYBOARDINPUT, True)

		'register events
		'someone uses the mouse wheel to scroll over the panel
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnMouseScrollwheel, onScrollWheel, Null, Self))
		'- we are interested in certain events from the scroller or self
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScroll, Null, guiScrollerH ))
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScroll, Null, guiScrollerV ))
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScroll, Null, self ))


		GUIManager.Add(Self)
		Return Self
	End Method


	Method Remove:int() override
		super.Remove()

		if guiTextPanel then guiTextPanel.Remove()
		if guiScrollerH then guiScrollerH.Remove()
		if guiScrollerV then guiScrollerV.Remove()
	End Method


rem
	'override to subtract potential scroller
	Method _UpdateContentScreenW:Float() override
		'calculate base
		Super._UpdateContentScreenW()

		'visible and relatively positioned _vertical_ scroller
		'(subtracts from width)?
		if guiScrollerV and guiScrollerV.hasOption(GUI_OBJECT_ENABLED) and not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			_contentScreenRect.SetW( _contentScreenRect.GetW() - guiScrollerV.rect.getW())
		endif

		Return _contentScreenRect.GetW() 
	End Method


	'override to subtract potential scroller
	Method _UpdateContentScreenH:Float() override
		'calculate base
		Super._UpdateContentScreenH()

		'visible and relatively positioned _horizontal_ scroller
		'(subtracts from height)?
		if guiScrollerH and guiScrollerH.hasOption(GUI_OBJECT_ENABLED) and not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			_contentScreenRect.SetH( _contentScreenRect.GetH() - guiScrollerH.rect.getH())
		endif

		Return _contentScreenRect.GetH() 
	End Method
endrem


	Method RefreshScrollLimits:int()
		if not guiTextPanel then return False

		if not _textDimensionValid then GetTextDimension()

		'determine if we did not scroll the list to a middle
		'position so this is true if we are at the very bottom
		'of the text aka "the end"
		Local atBottom:Int = IsAtBottom()

		Local xLimit:Float
		Local yLimit:Float

		'set scroll limits:
		if _textDimension.y < guiTextPanel.GetScreenRect().GetH()
			'text might be "less high" than the available area - no need
			'to align it at the bottom

			'Ronny 16/06/16: commented out, does not seem to be needed
			'                it also bugs textareas with a single line
			'                as it allows scrolling for 1 line then
			'yLimit = -_textDimension.y
		Else
			'maximum is at the bottom of the area, not top - so
			'subtract height
			yLimit = - (_textDimension.y - guiTextPanel.GetScreenRect().GetH())
			'yLimit = - (_textDimension.y - guiScrollerV.GetScreenRect().GetH())
		EndIf

		if _textDimension.x < guiTextPanel.GetScreenRect().GetW()
			'text might be "less wide" than the available area - no need
			'to align it at the right

			xLimit = -_textDimension.x
		Else
			'maximum is at the right of the area, not left - so
			'subtract width
			xLimit = - (_textDimension.x - guiTextPanel.GetScreenRect().GetW())
		EndIf
		guiTextPanel.SetLimits(xLimit, yLimit)

'		guiScrollerH.SetValueRange(0, _textDimension.x)
'		guiScrollerV.SetValueRange(0, _textDimension.y)
		guiScrollerH.SetValueRange(0, - xLimit)
		guiScrollerV.SetValueRange(0, - yLimit)
	End Method


	Method SetScrollerState:int(boolH:int, boolV:int)
		local changed:int = FALSE
		if boolH <> guiScrollerH.hasOption(GUI_OBJECT_ENABLED) then changed = TRUE
		if boolV <> guiScrollerV.hasOption(GUI_OBJECT_ENABLED) then changed = TRUE

		guiScrollerH.setOption(GUI_OBJECT_ENABLED, boolH)
		guiScrollerH.setOption(GUI_OBJECT_VISIBLE, boolH)
		guiScrollerV.setOption(GUI_OBJECT_ENABLED, boolV)
		guiScrollerV.setOption(GUI_OBJECT_VISIBLE, boolV)

		'resize everything
		If changed Then UpdateLayout()
	End Method


	Method SetFixedLineHeight(lineHeight:int = -1)
		if not _drawTextSettings then _drawTextSettings = new TDrawTextSettings

		if lineHeight <> _drawTextSettings.data.lineHeight
			_drawTextSettings.data.lineHeight = lineHeight

			ResetTextCache()
		endif
	End Method


	Method SetWordwrap(enable:int = True)
		if not _drawTextSettings then _drawTextSettings = new TDrawTextSettings

		if _drawTextSettings.data.wordWrap = enable then return

		_drawTextSettings.data.wordWrap = enable
		ResetTextCache()
		'UpdateContent()
		'GenerateTextCache()
	End Method


	Method GetLineHeight:Float()
		local lHeight:Int = _defaultDrawTextSettings.data.lineHeight
		if _drawTextSettings then lHeight = _drawTextSettings.data.lineHeight
			
		If lHeight = -1 then return GetFont().GetMaxCharHeight()
		Return lHeight
	End Method
	
	
	Method ResetTextCache()
		_textDimension = new SVec2I(0,0)
		_textDimensionValid = False
		_textCacheImageValid = False
		if _textParseInfo then _textParseInfo.data.PrepareNewCalculation(_textParseInfo.data.totalLineCount)
		'_textParseInfo = new TTextParseInfo()
'		_textParseInfo = Null
	End Method


	Method GetTextImageCache:TImage()
		If not _textCacheImage or not _textCacheImageValid
			GenerateTextCache()
		Endif
		return _textCacheImage
	End Method



	Method GenerateTextCache()
		local drawSettings:TDrawTextSettings = _drawTextSettings
		local drawEffect:TDrawTextEffect = _drawTextEffect
		if not drawSettings then drawSettings = _defaultDrawTextSettings
		if not drawEffect then drawEffect = _defaultDrawTextEffect

		if not _textParseInfo 
			_textParseInfo = new TTextParseInfo()
		endif
		if not _textParseInfo.data.calculated
			local maxWidth:Int = -1
			if drawSettings.data.wordWrap then maxWidth = guiTextPanel.GetContentWidth()
			if not _drawTextSettings
				_textParseInfo.data.CalculateDimensions(self.value, maxWidth, -1, GetFont(), _defaultDrawTextSettings.data)
			else
				_textParseInfo.data.CalculateDimensions(self.value, maxWidth, -1, GetFont(), _drawTextSettings.data)
			endif
		endif

		local createNew:int = False
		local linesHeight:int = _textParseInfo.data.GetBoxHeight(0)

		'calculate how much "preload" area to give
		'everything fits on the screen
		if linesHeight < guiTextPanel.GetScreenRect().GetH()
			_textCacheImagePreload = new SVec2I(_textCacheImagePreload.x, 25)
		'much to scroll?
		elseif linesHeight > guiTextPanel.GetScreenRect().GetH() * 10
			_textCacheImagePreload = new SVec2I(_textCacheImagePreload.x, int(MathHelper.Clamp(linesHeight * 10, 150, 400)))
		else
			_textCacheImagePreload = new SVec2I(_textCacheImagePreload.x, 150)
		endif

		local textBoxWidth:Int
		local texHeight:int
		local texWidth:int
		if guiTextPanel.GetScreenRect().GetH() < 0
			texHeight = _textParseInfo.data.GetBoxHeight(0) + 2*_textCacheImagePreload.y
		else
			texHeight = Min(_textParseInfo.data.GetBoxHeight(0), guiTextPanel.GetScreenRect().GetH()) + 2*_textCacheImagePreload.y
		endif
		if guiTextPanel.GetScreenRect().GetW() < 0
			textBoxWidth = _textParseInfo.data.GetBoxWidth(0)
		else
			textBoxWidth = Min(_textParseInfo.data.GetBoxWidth(0), guiTextPanel.GetScreenRect().GetW())
		endif
		texWidth = textBoxWidth +2*_textCacheImagePreload.x

		if not _textCacheImage
			createNew = True
		elseif not _textCacheImageValid
			if _textCacheImage.Width <> texWidth
				createNew = True
			elseif _textCacheImage.Height <> texHeight
				createNew = True
			EndIf
		EndIf
		if createNew then _textCacheImage = CreateImage(texWidth, texHeight, 1)
		'remove garbage or old content
		LockImage(_textCacheImage).ClearPixels(0)


		'render text into the texture
		TBitmapFont.setRenderTarget(_textCacheImage)

		'draw it offset by the top-cacheimage-size
		local offsetX:int = guiTextPanel.scrollPosition.GetX() + _textCacheImagePreload.x
		local offsetY:int = guiTextPanel.scrollPosition.GetY() + _textCacheImagePreload.y

		GetFont().DrawBox(self.value, offsetX, offsetY, textBoxwidth, -1, new SVec2f(0,0), textColor, new SVec2f(0,0), _textParseInfo, EDrawTextOption.None, drawEffect, drawSettings, -1, -1)
		
		TBitmapFont.setRenderTarget(null)


		'refresh area / scroll coordinates
		local dy:int = _textCacheImageVisibleMin.y - guiTextPanel.scrollPosition.GetIntY()
		local dx:int = _textCacheImageVisibleMin.x - guiTextPanel.scrollPosition.GetIntX()
		_textCacheImageVisibleMin = new SVec2I( guiTextPanel.scrollPosition.GetIntX(), guiTextPanel.scrollPosition.GetIntY() )
	
		'advance/de-advance by preload area
		local newMaxX:Int = _textCacheImageVisibleMin.x + guiTextPanel.GetScreenRect().GetW()
		local newMaxY:Int = _textCacheImageVisibleMin.y + guiTextPanel.GetScreenRect().GetH()
		if dy < 0
			newMaxY :- _textCacheImagePreload.y
		elseif dy > 0
			newMaxY :+ _textCacheImagePreload.y
		endif
		if dx < 0
			newMaxX :- _textCacheImagePreload.x
		elseif dx > 0
			newMaxX :+ _textCacheImagePreload.x
		endif
		_textCacheImageVisibleMax = new SVec2I(newMaxX, newMaxY)
'print "GenerateTextCache  linesHeight="+linesHeight +"  _textCacheImagePreload="+_textCacheImagePreload.x+", "+_textCacheImagePreload.y + "   offset="+offsetX+", "+offsetY +"  newMax="+newMaxX+", "+newMaxX
	
		
		_textCacheImageOffset = new SVec2I(0,0)
		_textCacheImageValid = True
	End Method


	Method IsAtBottom:int()
		if not guiTextPanel then return True

		local result:int = 1 > Floor(Abs(guiTextPanel.scrollLimit.GetY() - guiTextPanel.scrollPosition.getY()))

		'if whole text fits on the screen, scroll limit will be
		'lower than the container panel
		if Abs(guiTextPanel.scrollLimit.GetY()) < guiTextPanel.GetScreenRect().GetH()
			'if scrolled = 0 this could also mean we scrolled up to the top part
			'in this case we check if the text fits into the panel
			if guiTextPanel.scrollPosition.getY() = 0
				result = 1
				if GetTextDimension().y > guiTextPanel.GetScreenRect().GetH()
					result = 0
				endif
			endif
		endif
		return result
	End Method


	Method UpdateContent:int()
		if not _textDimensionValid then GetTextDimension()

		'resize container panel
		guiTextPanel.SetSize(_textDimension.x, _textDimension.y)
'print "Update Content: textDimension= "+_textDimension.getIntX()+"x"+_textDimension.getIntY()
'print "                guiTextPanel screen= " + guiTextPanel.GetScreenRect().GetW()+"x"+guiTextPanel.GetScreenRect().GetH()
		'refresh scrolling limits
		RefreshScrollLimits()

		'if not all entries fit on the panel, enable scroller
		SetScrollerState(..
			_horizontalScrollerAllowed and (_textDimension.x > guiTextPanel.GetScreenRect().GetW()), ..
			_verticalScrollerAllowed and (_textDimension.y > guiTextPanel.GetScreenRect().GetH()) ..
		)
		GetTextDimension()
'print "                textDimension2= "+_textDimension.getIntX()+"x"+_textDimension.getIntY()
'print "                guiTextPanel screen2= " + guiTextPanel.GetScreenRect().GetW()+"x"+guiTextPanel.GetScreenRect().GetH()
	End Method


	Function FindGUITextAreaParent:TGUITextArea(guiObject:TGUIObject)
		if not guiObject then return null

		local parent:TGUITextArea = TGUITextArea(guiObject)
		if parent then return parent

		local obj:TGUIObject = guiObject._parent
		While obj and obj <> guiObject And Not TGUITextArea(obj)
			obj = obj._parent
		wend
		'return the area or null (if topmost parent is of incompatible type)
		return TGUITextArea(obj)
	End Function


	'handle clicks on the up/down-buttons and inform others about changes
	Function onScrollWheel:Int( triggerEvent:TEventBase )
		Local textArea:TGUITextArea = TGUITextArea(triggerEvent.GetSender())
		Local scroller:TGUIScroller = TGUIScroller(triggerEvent.GetSender())
		if scroller
			textArea = TGUITextArea(scroller._parent)
		endif

		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If Not textArea Or value=0 Then Return False

		'emit event that the scroller position has changed
		local direction:string = ""
		if scroller
			if scroller = textArea.guiScrollerH
				If value < 0 then direction = "left"
				If value > 0 then direction = "right"
			elseif scroller = textArea.guiScrollerV
				If value < 0 then direction = "up"
				If value > 0 then direction = "down"
			endif
		'scrolling the panel itself defaults to up/down
		else
			If value < 0 then direction = "up"
			If value > 0 then direction = "down"
		endif

		if direction <> ""
			'try to scroll by 1.0 of a text line height
			local scrollAmount:Float = abs(value) * 1.0 * textArea.GetFont().getMaxCharHeight() '25

			TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, new TData.AddString("direction", direction).AddNumber("scrollAmount", scrollAmount), textArea)
		endif
		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Function


	'handle events from the connected scroller
	Function onScroll:Int( triggerEvent:TEventBase )
		local guiSender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		if not guiSender then return False

		'search a TGUIListBase-parent
		local guiTextArea:TGUITextArea = FindGUITextAreaParent(guiSender)
		If Not guiTextArea Then Return False

		Local data:TData = triggerEvent.GetData()
		If Not data Then Return False

		'by default scroll by 2 pixels
		Local baseScrollSpeed:int = 2
		'the longer you pressed the mouse button, the "speedier" we get
		'1px per 100ms. Start speeding up after 500ms, limit to 20px per scroll
		baseScrollSpeed :+ Min(20, Max(0, MOUSEMANAGER.GetDownTime(1) - 500)/100.0)

		Local scrollAmount:Int = data.GetInt("scrollAmount", baseScrollSpeed)
		'this should be "calculate height and change amount"
		If data.GetString("direction") = "up" Then guiTextArea.ScrollContent(0, +scrollAmount)
		If data.GetString("direction") = "down" Then guiTextArea.ScrollContent(0, -scrollAmount)
		If data.GetString("direction") = "left" Then guiTextArea.ScrollContent(+scrollAmount, 0)
		If data.GetString("direction") = "right" Then guiTextArea.ScrollContent(-scrollAmount, 0)
		'maybe data was given in percents - so something like a
		'"scrollTo"-value
		If data.getInt("isRelative") = True
			local percentage:Float = data.GetFloat("percentage", 0)

			if guiSender = guiTextArea.guiScrollerH
				guiTextArea.SetScrollPercentageX(percentage)

			elseif guiSender = guiTextArea.guiScrollerV
				guiTextArea.SetScrollPercentageY(percentage)
			endif
		endif
	End Function


	'positive values scroll to top or left
	Method ScrollContent(dx:float, dy:float)
		ScrollContentTo(guiTextPanel.scrollPosition.GetX() + dx, guiTextPanel.scrollPosition.GetY() +dy)
	End Method


	'positive values scroll to top or left
	Method ScrollContentTo(x:float, y:float, paramsArePercent:int = False)
		local oldX:int = guiTextPanel.scrollPosition.GetIntX()
		local oldY:int = guiTextPanel.scrollPosition.GetIntY()
		if paramsArePercent
			x = x * guiTextPanel.scrollLimit.GetX()
			y = y * guiTextPanel.scrollLimit.GetY()
		endif
		guiTextPanel.scrollTo(x,y)

		'refresh scroller values (for "progress bar" on the scroller)
		guiScrollerH.SetRelativeValue( GetScrollPercentageX() )
		guiScrollerV.SetRelativeValue( GetScrollPercentageY() )

		'moved to somewhere?
		if guiTextPanel.scrollPosition.GetIntY() <> oldY or guiTextPanel.scrollPosition.GetIntX() <> oldX
			'recalc visible min/max
			local currentVisibleMinY:int = guiTextPanel.scrollPosition.GetIntY()
			local currentVisibleMaxY:int = _textCacheImageVisibleMin.y + guiTextPanel.GetScreenRect().GetH()

			local newX:Int = _textCacheImageOffset.x + guiTextPanel.scrollPosition.GetIntX() - oldX
			local newY:Int = _textCacheImageOffset.y + guiTextPanel.scrollPosition.GetIntY() - oldY
			_textCacheImageOffset = new SVec2I(newX, newY)
'print "ScrollContent: Moved panel.  _textCacheImageOffsetY="+_textCacheImageOffset.y

			if not _IsVisibleAreaInCacheArea()
'print "reset cache: currentMinY="+currentVisibleMinY+" ImageMinY="+_textCacheImageVisibleMin.y+"  currentMaxY="+currentVisibleMaxY+"  imageMaxY="+_textCacheImageVisibleMax.Y
				GenerateTextCache()
			endif
		endif
	End Method


	Method GetScrollPercentageY:Float()
		return guiTextPanel.GetScrollPercentageY()
	End Method


	Method GetScrollPercentageX:Float()
		return guiTextPanel.GetScrollPercentageX()
	End Method


	Method SetScrollPercentageX:Float(percentage:float = 0.0)
		guiScrollerH.SetRelativeValue(percentage)

		ScrollContentTo(percentage, 0, True)
		return guiTextPanel.scrollPosition.GetX()

		'return guiTextPanel.SetScrollPercentageX(percentage)
	End Method


	Method SetScrollPercentageY:Float(percentage:float = 0.0)
		guiScrollerV.SetRelativeValue(percentage)

		ScrollContentTo(0, percentage, True)
		return guiTextPanel.scrollPosition.GetY()

		'return guiTextPanel.SetScrollPercentageY(percentage)
	End Method
	
	
	Method _GetDrawTextSettings:TDrawTextSettings()
		if _drawTextSettings Then return _drawTextSettings
		Return _defaultDrawTextSettings
	End Method


	Method _GetDrawTextEffect:TDrawTextEffect()
		if _drawTextEffect Then return _drawTextEffect
		Return _defaultDrawTextEffect
	End Method
		

	Method GetTextDimension:SVec2I()
		if not _textDimensionValid

			if _GetDrawTextSettings().data.wordwrap
				local tX:Int = guiTextPanel.GetContentScreenRect().GetW()
				local tY:Int = GetFont().GetBoxHeight(value, tX, -1, _GetDrawTextSettings())
				_textDimension = new SVec2I(tX, tY)
			else
				_textDimension = GetFont().GetBoxDimension(value, 3500, -1, _GetDrawTextSettings())
			endif
			
			_textDimensionValid = True
		endif
		return _textDimension
	End Method


	Method _IsVisibleAreaInCacheAreaV:int()
		return abs((_textCacheImageVisibleMin.y + guiTextPanel.GetScreenRect().GetH()) - _textCacheImageVisibleMax.y) <= _textCacheImagePreload.y and ..
			   abs(guiTextPanel.scrollPosition.GetIntY() - _textCacheImageVisibleMin.y) <= _textCacheImagePreload.y
	End Method


	Method _IsVisibleAreaInCacheAreaH:int()
		return abs((_textCacheImageVisibleMin.x + guiTextPanel.GetScreenRect().GetW()) - _textCacheImageVisibleMax.x) <= _textCacheImagePreload.x and ..
			   abs(guiTextPanel.scrollPosition.GetIntX() - _textCacheImageVisibleMin.x) <= _textCacheImagePreload.x
	End Method


	Method _IsVisibleAreaInCacheArea:int()
		return _IsVisibleAreaInCacheAreaH() and _IsVisibleAreaInCacheAreaV()
	End Method


	Method onAppearanceChanged:int()
		Super.onAppearanceChanged()

		'refresh cache (maybe we got a new font?)
		RefreshScrollLimits()
		GenerateTextCache()

		return True
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()
		
		
		'react to some special keys
		If IsFocused()
			If KeyWrapper.IsPressed(KEY_PAGEDOWN)
				ScrollContent(0, -rect.GetH())
			EndIf
			If KeyWrapper.IsPressed(KEY_PAGEUP)
				ScrollContent(0, +rect.GetH())
			EndIf

			If KeyManager.IsDown(KEY_HOME)
				ScrollContentTo(0, 0.0, True)
			ElseIf KeyManager.IsDown(KEY_END)
				ScrollContentTo(0, 1.0, True)
			EndIf

			If KeyWrapper.IsPressed(KEY_DOWN)
				local baseLineHeight:Int = GetFont().getMaxCharHeight()
				ScrollContent(0, -baseLineHeight)
			ElseIf KeyWrapper.IsPressed(KEY_UP)
				local baseLineHeight:Int = GetFont().getMaxCharHeight()
				ScrollContent(0, +baseLineHeight)
			EndIf
		EndIf


		'need refresh?
		if not _IsVisibleAreaInCacheArea() then GenerateTextCache()

		'enable/disable buttons of scrollers if they reached the
		'limits of the scrollable panel
		if guiScrollerH.hasOption(GUI_OBJECT_ENABLED)
			guiScrollerH.SetButtonStates(not guiTextPanel.ReachedLeftLimit(), not guiTextPanel.ReachedRightLimit())
		endif
		if guiScrollerV.hasOption(GUI_OBJECT_ENABLED)
			guiScrollerV.SetButtonStates(not guiTextPanel.ReachedTopLimit(), not guiTextPanel.ReachedBottomLimit())
		endif

		_mouseOverArea = THelper.MouseIn(int(GetScreenRect().GetX()), int(GetScreenRect().GetY()), int(rect.GetW()), int(rect.GetH()))
	End Method


	Method DrawBackground()
		Local oldCol:SColor8
		GetColor(oldCol)
		Local oldAlpha:Float = GetAlpha()
		Local rect:TRectangle = new TRectangle.Init(guiTextPanel.GetScreenRect().GetX(), guiTextPanel.GetScreenRect().GetY(), Min(rect.GetW(), guiTextPanel.rect.GetW()), Min(rect.GetH(), guiTextPanel.rect.GetH()) )

		If _mouseOverArea
			SetColor(backgroundColorHovered)
			SetAlpha(oldAlpha * backgroundColorHovered.a/255.0)
		Else
			SetColor(backgroundColor)
			SetAlpha(oldAlpha * backgroundColor.a/255.0)
		EndIf
		if GetAlpha() > 0
			DrawRect(rect.GetX(), rect.GetY(), rect.GetW(), rect.GetH())
		endif

		SetColor(oldCol)
		SetAlpha(oldAlpha)
	End Method


	Method SetValue(value:string)
		Super.SetValue(value)
		ResetTextCache()
		UpdateContent()
		GetTextImageCache()
	End Method


	Method DrawContent()
rem
		'orange: komplettes Widget
'		SetColor 255, 255,0
'		SetAlpha GetAlpha() * 0.25
'		DrawRect(GetParent().GetScreenRect().GetX(), GetParent().GetScreenRect().GetY(), GetParent().GetScreenRect().GetW(), GetParent().GetScreenRect().GetH())

		'gruen: Inhaltsbereich
		SetColor 0,255,0
		DrawRect(GetContentScreenRect().GetX(), GetContentScreenRect().GetY(), GetContentScreenRect().GetW(), GetContentScreenRect().GetH())
		SetAlpha GetAlpha() * 4

		'blau: textbereich
		SetColor 0,0,125
		DrawRect(GetContentScreenRect().GetX(), GetContentScreenRect().GetY(), GetTextDimension().x, 50)

		'cache width
		SetColor 0,0,255
		if _textCacheImage
			DrawRect(GetContentScreenRect().GetX(), GetContentScreenRect().GetY() + 60, _textCacheImage.width, 20)
		endif
		SetColor 255,0,0
		DrawRect(guiTextPanel.GetScreenRect().GetX(), guiTextPanel.GetScreenRect().GetY(), guiTextPanel.GetScreenRect().GetW(), guiTextPanel.GetScreenRect().GetH())

		SetAlpha 1.0
		SetColor 0,0,0
		DrawRect(0,0,200,100)
		SetColor 255,255,255
		DrawText("posX: "+int(guiTextPanel.scrollPosition.GetX()) + "  limitX: "+int(guiTextPanel.scrollLimit.GetX()), 10, 30)
		DrawText("posY: "+int(guiTextPanel.scrollPosition.GetY()) + "  limitY: "+int(guiTextPanel.scrollLimit.GetY()), 10, 50)
endrem
		RestrictContentViewport()
		'restrict even more
		Local rect:TRectangle = GetContentScreenRect()
		local panelRect:TRectangle = guiTextPanel.GetScreenRect()
		If rect And rect.GetW() > 0 And rect.GetH() > 0
			GUIManager.RestrictViewport(Int(rect.getX()), Int(rect.getY()), Int(Min(rect.getW(), panelRect.GetW())), Int(Min(rect.getH(), panelRect.GetH())))
		EndIf

		SetColor 255,255,255
		DrawImage(GetTextImageCache(), GetContentScreenRect().GetX() + _textCacheImageOffset.x - _textCacheImagePreload.x, GetContentScreenRect().GetY() + _textCacheImageOffset.y - _textCacheImagePreload.y)

		'remove "even more" restriction
		If rect And rect.GetW() > 0 And rect.GetH() > 0
			GUIManager.ResetViewport()
		endif

		ResetViewport()
		SetAlpha 1.0
		SetColor 255,255,255
	End Method


	Method UpdateLayout()
		'cache enabled state of both scrollers
		Local showScrollerH:Int = 0<(guiScrollerH And guiScrollerH.hasOption(GUI_OBJECT_ENABLED))
		Local showScrollerV:Int = 0<(guiScrollerV And guiScrollerV.hasOption(GUI_OBJECT_ENABLED))

		'resize panel - but use resulting dimensions, not given (maybe restrictions happening!)
		If guiTextPanel
			'also set minsize so scroll works
			guiTextPanel.minSize.SetXY(..
				GetContentScreenRect().GetW() - showScrollerV * guiScrollerV.GetScreenRect().GetW(),..
				GetContentScreenRect().GetH() - showScrollerH * guiScrollerH.rect.getH()..
			)

			guiTextPanel.SetSize(..
				GetContentScreenRect().GetW() - showScrollerV * guiScrollerV.rect.getW(),..
				GetContentScreenRect().GetH() - showScrollerH * guiScrollerH.rect.getH()..
			)
		EndIf


		If guiScrollerH And Not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			If showScrollerV
				guiScrollerH.SetSize(GetContentScreenRect().GetW() - guiScrollerV.GetScreenRect().GetW(), 0)
			Else
				guiScrollerH.SetSize(GetContentScreenRect().GetW())
			EndIf
		EndIf
		If guiScrollerV And Not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			If showScrollerH
				guiScrollerV.SetSize(0, GetContentScreenRect().GetH() - guiScrollerH.GetScreenRect().GetH() - 3)
			Else
				guiScrollerV.SetSize(0, GetContentScreenRect().GetH())
			EndIf
		EndIf


		'move horizontal scroller --
		If showScrollerH and not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerH.SetPosition(0, GetContentScreenRect().GetH() - guiScrollerH.guiButtonMinus.rect.getH())
			guiScrollerH.InvalidateScreenRect()
		EndIf
		'move vertical scroller |
		If showScrollerV and not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerV.SetPosition( GetContentScreenRect().GetW() - guiScrollerV.guiButtonMinus.rect.getW(), 0)
			guiScrollerV.InvalidateScreenRect()
		EndIf



		'recalculate scroll limits etc.
		if guiTextPanel then RefreshScrollLimits()

		'refresh text status
		ResetTextCache()
	End Method
End Type
