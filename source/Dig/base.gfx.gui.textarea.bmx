SuperStrict
Import "base.util.helper.bmx"
Import "base.gfx.gui.panel.scrollablepanel.bmx"
Import "base.gfx.gui.scroller.bmx"


Type TGUITextArea Extends TGUIobject
	Field guiTextPanel:TGUIScrollablePanel = Null
	Field guiScrollerH:TGUIScroller = Null
	Field guiScrollerV:TGUIScroller	= Null
	Field _textLinesCache:string[]
	Field _textDimension:TVec2D = new TVec2D.Init(200, 1200)
	Field _textCacheImage:TImage
	Field _textCacheImageVisibleMin:TVec2D = new TVec2D
	Field _textCacheImageVisibleMax:TVec2D = new TVec2D
	Field _textCacheImageOffset:TVec2D = new TVec2D
	'pre-cached content both directions of each axis
	Field _textCacheImagePreload:TVec2D = new TVec2D.Init(150,150)
	Field _textCacheImageValid:int = False
	Field textColor:TColor = TColor.Create(0,0,0,1.0)
	Field backgroundColor:TColor = TColor.Create(0,0,0,0)
	Field backgroundColorHovered:TColor	= TColor.Create(0,0,0,0)
	Field _mouseOverArea:Int = False
	Field _wordwrap:int = False
	Field _fixedLineHeight:Int = 0
	Field _verticalScrollerAllowed:int = True 
	Field _horizontalScrollerAllowed:int = True 


    Method Create:TGUITextArea(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.CreateBase(position, dimension, limitState)

		'setZIndex(0)

		guiScrollerH = New TGUIScroller.Create(Self)
		guiScrollerV = New TGUIScroller.Create(Self)
		'orientation of horizontal scroller has to get set manually
		guiScrollerH.SetOrientation(GUI_OBJECT_ORIENTATION_HORIZONTAL)

		guiTextPanel = New TGUIScrollablePanel.Create(null, new TVec2D.Init(rect.GetW() - guiScrollerV.rect.getW(), rect.GetH() - guiScrollerH.rect.getH()), self.state)

		AddChild(guiTextPanel) 'manage by our own


		'by default all lists do not have scrollers
		setScrollerState(False, False)

		'the text panel cannot be focused
		guiTextPanel.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		'register events
		'someone uses the mouse wheel to scroll over the panel
		AddEventListener(EventManager.registerListenerFunction( "guiobject.OnScrollwheel", onScrollWheel, guiScrollerH))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.OnScrollwheel", onScrollWheel, guiScrollerV))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.OnScrollwheel", onScrollWheel, Self))
		'- we are interested in certain events from the scroller or self
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScroll, guiScrollerH ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScroll, guiScrollerV ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScroll, self ))


		GUIManager.Add(Self)
		Return Self
	End Method


	Method Remove:int()
		super.Remove()

		if guiTextPanel then guiTextPanel.Remove()
		if guiScrollerH then guiScrollerH.Remove()
		if guiScrollerV then guiScrollerV.Remove()
	End Method



	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w,h)

		'cache enabled state of both scrollers
		local showScrollerH:int = 0<(guiScrollerH and guiScrollerH.hasOption(GUI_OBJECT_ENABLED))
		local showScrollerV:int = 0<(guiScrollerV and guiScrollerV.hasOption(GUI_OBJECT_ENABLED))

		'resize panel - but use resulting dimensions, not given (maybe restrictions happening!)
		If guiTextPanel
			'also set minsize so scroll works
			guiTextPanel.minSize.SetXY(..
				GetContentScreenWidth() - showScrollerV*guiScrollerV.GetScreenWidth(),..
				GetContentScreenHeight() - showScrollerH*guiScrollerH.GetScreenHeight()..
			)
'				GetContentScreenHeight() - showScrollerH*guiScrollerH.rect.getH()..

			guiTextPanel.Resize(..
				GetContentScreenWidth() - showScrollerV * guiScrollerV.rect.getW(),..
				GetContentScreenHeight() - showScrollerH * guiScrollerH.rect.getH()..
			)
		EndIf

		'move horizontal scroller --
		If showScrollerH and not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerH.rect.position.setXY(0, GetScreenHeight() - guiScrollerH.guiButtonMinus.rect.getH())
			guiScrollerH.Resize(GetContentScreenWidth())
		EndIf
		'move vertical scroller |
		If showScrollerV and not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerV.rect.position.setXY( GetScreenWidth() - guiScrollerV.guiButtonMinus.rect.getW(), 0)
			guiScrollerV.Resize(0, GetContentScreenHeight())
		EndIf

		'recalculate scroll limits etc.
		if guiTextPanel then RefreshScrollLimits()

		'refresh text status
		ResetTextCache()
	End Method


	'override to subtract potential scroller
	Method GetContentScreenWidth:Float()
		'visible and relatively positioned _vertical_ scroller
		'(subtracts from width)?
		if guiScrollerV and guiScrollerV.hasOption(GUI_OBJECT_ENABLED) and not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			Return Super.GetContentScreenWidth() - guiScrollerV.rect.getW()
		endif

		Return Super.GetContentScreenWidth()
	End Method

	'available height for content/children
	Method GetContentScreenHeight:Float()
		'visible and relatively positioned _horizontal_ scroller
		'(subtracts from height)?
		if guiScrollerH and guiScrollerH.hasOption(GUI_OBJECT_ENABLED) and not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			Return Super.GetContentScreenHeight() - guiScrollerH.rect.getH()
		endif

		Return Super.GetContentScreenHeight()
	End Method



	Method RefreshScrollLimits:int()
		if not guiTextPanel then return False

		if not _textDimension then GetTextDimension()

		'determine if we did not scroll the list to a middle
		'position so this is true if we are at the very bottom
		'of the text aka "the end"
		Local atBottom:Int = IsAtBottom()

		Local xLimit:Float
		Local yLimit:Float

		'set scroll limits:
		if _textDimension.getY() < guiTextPanel.getScreenheight()
			'text might be "less high" than the available area - no need
			'to align it at the bottom

			'Ronny 16/06/16: commented out, does not seem to be needed
			'                it also bugs textareas with a single line
			'                as it allows scrolling for 1 line then
			'yLimit = -_textDimension.getY()
		Else
			'maximum is at the bottom of the area, not top - so
			'subtract height
			yLimit = - (_textDimension.getY() - guiTextPanel.getScreenheight())
		EndIf

		if _textDimension.getX() < guiTextPanel.getScreenWidth()
			'text might be "less wide" than the available area - no need
			'to align it at the right

			xLimit = -_textDimension.getX()
		Else
			'maximum is at the right of the area, not left - so
			'subtract width
			xLimit = - (_textDimension.getX() - guiTextPanel.getScreenWidth())
		EndIf

		guiTextPanel.SetLimits(xLimit, yLimit)

		guiScrollerH.SetValueRange(0, _textDimension.getX())
		guiScrollerV.SetValueRange(0, _textDimension.getY())
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
		Resize()
	End Method


	Method SetFixedLineHeight(lineHeight:int = -1)
		if lineHeight <> _fixedLineHeight
			_fixedLineHeight = lineHeight
			ResetTextCache()
		endif
	End Method


	Method SetWordwrap(enable:int = True)
		if _wordwrap = enable then return

		_wordwrap = enable
		ResetTextCache()
		'UpdateContent()
		'GenerateTextCache()
	End Method


	Method GetLineHeight:Float()
		if _fixedLineHeight = -1 then return GetFont().GetMaxCharHeight()
		return _fixedLineHeight
	End Method


	Method ResetTextCache()
		_textLinesCache = new String[0]
		_textDimension = null
		_textCacheImageValid = False
	End Method


	Method GetTextImageCache:TImage()
		If not _textCacheImage or not _textCacheImageValid
			GenerateTextCache()
		Endif
		return _textCacheImage
	End Method


	Method GetValueLines:string[]()
		if not _textLinesCache or (value.length > 0 and _textLinesCache.length = 0)
			Local lineHeight:float = GetFont().getMaxCharHeight()
			if _wordwrap
				_textLinesCache = GetFont().TextToMultiLine(value, guiTextPanel.GetContentScreenWidth(), 0, lineHeight)
			else
				_textLinesCache = GetFont().TextToMultiLine(value, 0, 0, lineHeight)
			endif
		endif
		return _textLinesCache
	End Method


	Method GenerateTextCache()
		local createNew:int = False
		local linesHeight:int = GetValueLines().length * GetFont().getMaxCharHeight()
		'everything fits on the screen
		if linesHeight < guiTextPanel.GetScreenHeight()
			_textCacheImagePreload.SetY(25)
		'much to scroll?
		elseif linesHeight > guiTextPanel.GetScreenHeight() * 10
			_textCacheImagePreload.SetY( MathHelper.Clamp(linesHeight * 10, 150, 400) )
		else
			_textCacheImagePreload.SetY( 150 )
		endif
		
		local texHeight:int = Min(GetTextDimension().GetY(), guiTextPanel.GetScreenHeight()) + 2*_textCacheImagePreload.GetIntY()
		local texWidth:int = Min(GetTextDimension().GetX(), guiTextPanel.GetScreenWidth()) + 2*_textCacheImagePreload.GetIntX()

		if not _textCacheImage
			createNew = True
		elseif not _textCacheImageValid
			'if _textCacheImage.Width <> GetTextDimension().GetX()
			if _textCacheImage.Width <> texWidth
				createNew = True
			elseif _textCacheImage.Height <> texHeight
				createNew = True
			EndIf
		EndIf
		if createNew then _textCacheImage = CreateImage(texWidth, texHeight, 1)
		'remove garbage or old content
		LockImage(_textCacheImage).ClearPixels(0)

		TBitmapFont.setRenderTarget(_textCacheImage)
		'draw it offset by the top-cacheimage-size
		local offsetX:int = guiTextPanel.scrollPosition.GetX() + _textCacheImagePreload.GetIntX()
		local offsetY:int = guiTextPanel.scrollPosition.GetY() + _textCacheImagePreload.GetIntY()
		
		GetFont().DrawLinesBlock(GetValueLines(), offsetX, offsetY, Max(GetTextDimension().GetX(), -1), Max(GetTextDimension().GetY(), -1), , textColor, 0, true, 1.0, True, False, _fixedLineHeight)
		TBitmapFont.setRenderTarget(null)

		'refresh area / scroll coordinates
		local dy:int = _textCacheImageVisibleMin.GetIntY() - guiTextPanel.scrollPosition.GetIntY()
		local dx:int = _textCacheImageVisibleMin.GetIntX() - guiTextPanel.scrollPosition.GetIntX()
		_textCacheImageVisibleMin.SetX( guiTextPanel.scrollPosition.GetIntX() )
		_textCacheImageVisibleMin.SetY( guiTextPanel.scrollPosition.GetIntY() )
		_textCacheImageVisibleMax.SetX( _textCacheImageVisibleMin.GetIntX() + guiTextPanel.GetScreenWidth() )
		_textCacheImageVisibleMax.SetY( _textCacheImageVisibleMin.GetIntY() + guiTextPanel.GetScreenHeight() )
		'advance/de-advance by preload area
		if dy < 0
			_textCacheImageVisibleMax.AddY( - _textCacheImagePreload.y )
		elseif dy > 0
			_textCacheImageVisibleMax.AddY( + _textCacheImagePreload.y )
		endif
		if dx < 0
			_textCacheImageVisibleMax.AddX( - _textCacheImagePreload.x )
		elseif dx > 0
			_textCacheImageVisibleMax.AddX( + _textCacheImagePreload.x )
		endif
		_textCacheImageOffset.SetXY(0,0)


		_textCacheImageValid = True
	End Method


	Method IsAtBottom:int()
		if not guiTextPanel then return True
		
		local result:int = 1 > Floor(Abs(guiTextPanel.scrollLimit.GetY() - guiTextPanel.scrollPosition.getY()))

		'if whole text fits on the screen, scroll limit will be
		'lower than the container panel 
		if Abs(guiTextPanel.scrollLimit.GetY()) < guiTextPanel.GetScreenHeight()
			'if scrolled = 0 this could also mean we scrolled up to the top part
			'in this case we check if the text fits into the panel
			if guiTextPanel.scrollPosition.getY() = 0
				result = 1
				if GetTextDimension().GetY() > guiTextPanel.getScreenheight()
					result = 0
				endif
			endif
		endif
		return result
	End Method


	Method UpdateContent:int()
		if not _textDimension then GetTextDimension()

		'resize container panel
		guiTextPanel.resize(_textDimension.getX(), _textDimension.getY())
'print "Update Content: textDimension= "+_textDimension.getIntX()+"x"+_textDimension.getIntY()
'print "                guiTextPanel screen= " + guiTextPanel.GetScreenWidth()+"x"+guiTextPanel.GetScreenHeight()
		'refresh scrolling limits
		RefreshScrollLimits()

		'if not all entries fit on the panel, enable scroller
		SetScrollerState(..
			_horizontalScrollerAllowed and (_textDimension.getX() > guiTextPanel.GetScreenWidth()), ..
			_verticalScrollerAllowed and (_textDimension.getY() > guiTextPanel.GetScreenHeight()) ..
		)
		GetTextDimension()
'print "                textDimension2= "+_textDimension.getIntX()+"x"+_textDimension.getIntY()
'print "                guiTextPanel screen2= " + guiTextPanel.GetScreenWidth()+"x"+guiTextPanel.GetScreenHeight()
	End Method


	Function FindGUITextAreaParent:TGUITextArea(guiObject:TGUIObject)
		if not guiObject then return null
		
		local parent:TGUITextArea = TGUITextArea(guiObject)
		if parent then return parent
		
		local obj:TGUIObject = guiObject.GetParent()
		while obj <> guiObject and not TGUITextArea(obj) 
			obj = obj.GetParent()
		wend
		return TGUITextArea(obj)
	End Function


	'handle clicks on the up/down-buttons and inform others about changes
	Function onScrollWheel:Int( triggerEvent:TEventBase )
		Local textArea:TGUITextArea = TGUITextArea(triggerEvent.GetSender())
		Local scroller:TGUIScroller = TGUIScroller(triggerEvent.GetSender())
		if scroller
			textArea = TGUITextArea(scroller.GetParent())
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
			
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onScrollPositionChanged", new TData.AddString("direction", direction).AddNumber("scrollAmount", scrollAmount), textArea))
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
		If data.getString("changeType") = "percentage"
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
			local currentVisibleMaxY:int = _textCacheImageVisibleMin.GetIntY() + guiTextPanel.GetScreenHeight()

			_textCacheImageOffset.AddY( guiTextPanel.scrollPosition.GetIntY() - oldY )
			_textCacheImageOffset.AddX( guiTextPanel.scrollPosition.GetIntX() - oldX )
'print "ScrollContent: Moved panel.  _textCacheImageOffsetY="+_textCacheImageOffset.y

			if not _IsVisibleAreaInCacheArea()
'print "reset cache: currentMinY="+currentVisibleMinY+" ImageMinY="+_textCacheImageVisibleMin.GetIntY()+"  currentMaxY="+currentVisibleMaxY+"  imageMaxY="+_textCacheImageVisibleMax.Y
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


	Method GetTextDimension:TVec2D()
		if not _textDimension
			_textDimension = new TVec2D
			if _wordwrap
				_textDimension.SetX( guiTextPanel.GetContentScreenWidth() )
				_textDimension.SetY( GetFont().GetBlockHeight(value, _textDimension.GetX(), -1, _fixedLineHeight) )
			else
				local dim:TVec2D = GetFont().getBlockDimension(value, 3500, -1, _fixedLineHeight)
				_textDimension.SetXY( dim.GetX(), dim.GetY() )
			endif
		endif
		return _textDimension
	End Method


	Method _IsVisibleAreaInCacheAreaV:int()
		return abs((_textCacheImageVisibleMin.GetIntY() + guiTextPanel.GetScreenHeight()) - _textCacheImageVisibleMax.GetIntY()) <= _textCacheImagePreload.GetIntY() and ..
			   abs(guiTextPanel.scrollPosition.GetIntY() - _textCacheImageVisibleMin.GetIntY()) <= _textCacheImagePreload.GetIntY()
	End Method


	Method _IsVisibleAreaInCacheAreaH:int()
		return abs((_textCacheImageVisibleMin.GetIntX() + guiTextPanel.GetScreenWidth()) - _textCacheImageVisibleMax.GetIntX()) <= _textCacheImagePreload.GetIntX() and ..
			   abs(guiTextPanel.scrollPosition.GetIntX() - _textCacheImageVisibleMin.GetIntX()) <= _textCacheImagePreload.GetIntX()
	End Method
	

	Method _IsVisibleAreaInCacheArea:int()
		return _IsVisibleAreaInCacheAreaH() and _IsVisibleAreaInCacheAreaV()
	End Method
	

	Method onStatusAppearanceChange:int()
		Super.onStatusAppearanceChange()

		'refresh cache (maybe we got a new font?)
		RefreshScrollLimits()
		GenerateTextCache()

		return True
	End Method
	

	'override default update-method
	Method Update:Int()
		Super.Update()

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

		_mouseOverArea = THelper.MouseIn(int(GetScreenX()), int(GetScreenY()), int(rect.GetW()), int(rect.GetH()))
	End Method


	Method DrawBackground()
		Local oldCol:TColor = new TColor.Get()
		Local rect:TRectangle = new TRectangle.Init(guiTextPanel.GetScreenX(), guiTextPanel.GetScreenY(), Min(rect.GetW(), guiTextPanel.rect.GetW()), Min(rect.GetH(), guiTextPanel.rect.GetH()) )

		If _mouseOverArea
			backgroundColorHovered.setRGBA()
		Else
			backgroundColor.setRGBA()
		EndIf
		if GetAlpha() > 0
			DrawRect(rect.GetX(), rect.GetY(), rect.GetW(), rect.GetH())
		endif

		oldCol.SetRGBA()
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
'		DrawRect(GetParent().GetScreenX(), GetParent().GetScreenY(), GetParent().GetScreenWidth(), GetParent().GetScreenHeight())

		'gruen: Inhaltsbereich
'		SetColor 0,255,0
'		DrawRect(GetContentScreenX(), GetContentScreenY(), GetContentScreenWidth(), GetContentScreenHeight())
'		SetAlpha GetAlpha() * 4

		'blau: textbereich
		SetColor 0,0,125
		DrawRect(GetContentScreenX(), GetContentScreenY(), GetTextDimension().GetX(), 50)

		'cache width
		SetColor 0,0,255
		if _textCacheImage
			DrawRect(GetContentScreenX(), GetContentScreenY() + 60, _textCacheImage.width, 20)
		endif
		SetColor 255,0,0
		DrawRect(guiTextPanel.GetScreenX(), guiTextPanel.GetScreenY(), guiTextPanel.GetScreenWidth(), guiTextPanel.GetScreenHeight())

		SetColor 0,0,0
		DrawRect(0,0,200,100)
		SetColor 255,255,255
		DrawText("posX: "+guiTextPanel.scrollPosition.GetX() + "  limitX: "+guiTextPanel.scrollLimit.GetX(), 10, 30)  
		DrawText("posY: "+guiTextPanel.scrollPosition.GetY() + "  limitY: "+guiTextPanel.scrollLimit.GetY(), 10, 50)  
endrem
		RestrictContentViewport()
		SetColor 255,255,255
		DrawImage(GetTextImageCache(), GetContentScreenX() + _textCacheImageOffset.x - _textCacheImagePreload.x, GetContentScreenY() + _textCacheImageOffset.y - _textCacheImagePreload.y)
		ResetViewport()
	End Method
End Type