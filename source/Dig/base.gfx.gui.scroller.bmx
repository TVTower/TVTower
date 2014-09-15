Rem
	===========================================================
	GUI Scroller
	===========================================================

	Scrollers have to get attached to other gui objects to get
	createable.
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.arrowbutton.bmx"




Type TGUIScroller Extends TGUIobject
	Field mouseDownTime:Int = 250	'milliseconds until we react on "mousedown"
	Field guiButtonMinus:TGUIArrowButton = Null
	Field guiButtonPlus:TGUIArrowButton	= Null
	Field _orientation:int = GUI_OBJECT_ORIENTATION_VERTICAL


	Method Create:TGUIScroller(parent:TGUIobject)
		setParent(parent)

		'create buttons
		guiButtonMinus = New TGUIArrowButton.Create(Null, null, "UP", "")
		guiButtonPlus = New TGUIArrowButton.Create(Null, null, "DOWN", "")

		'set the buttons to ignore focus setting
		guiButtonMinus.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
		guiButtonPlus.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		'the scroller itself ignores focus too
		self.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		'style myself - aligns buttons
		onAppearanceChanged()


		'set the parent of the buttons so they inherit visible state etc.
		guiButtonMinus.setParent(Self)
		guiButtonPlus.setParent(Self)

		'scroller is interested in hits (not clicks) on its buttons
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScroller.onButtonClick, guiButtonMinus ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScroller.onButtonClick, guiButtonPlus ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScroller.onButtonDown, guiButtonMinus ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScroller.onButtonDown, guiButtonPlus ))

		GUIManager.Add( Self)

		Return Self
	End Method


	'override to also check buttons
	Method IsAppearanceChanged:int()
		if guiButtonMinus and guiButtonMinus.isAppearanceChanged() then return TRUE
		if guiButtonPlus and guiButtonPlus.isAppearanceChanged() then return TRUE

		return Super.isAppearanceChanged()
	End Method


	'override default
	Method onAppearanceChanged:int()
		rect.position.setXY(GetParent().rect.getW() - guiButtonMinus.rect.getW(),0)

		'this also aligns the buttons
		Resize(GetParent().rect.getW(), GetParent().rect.getH())
		'Resize()
	End Method


	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		'according the orientation we limit height or width
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				h = guiButtonMinus.rect.getH()
				'if w <= 0 then w = rect.GetW()
			case GUI_OBJECT_ORIENTATION_VERTICAL
				w = guiButtonMinus.rect.getW()
				'if h <= 0 then h = rect.GetH()
		End Select
		Super.Resize(w, h)

		'move the first button to the most left and top position
		guiButtonMinus.rect.position.SetXY(0, 0)
		'move the second button to the most right and bottom position
		guiButtonPlus.rect.position.SetXY(GetScreenWidth() - guiButtonPlus.GetScreenWidth(), GetScreenHeight() - guiButtonPlus.GetScreenHeight())
	End Method


	Method SetOrientation:int(orientation:Int=0)
		if _orientation = orientation then return FALSE

		_orientation = orientation
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				guiButtonMinus.SetDirection("LEFT")
				guiButtonPlus.SetDirection("RIGHT")
				'set scroller area to full WIDTH of parent
				if GetParent() then rect.dimension.SetX(GetParent().rect.getW())
			default
				guiButtonMinus.SetDirection("UP")
				guiButtonPlus.SetDirection("DOWN")
				'set scroller area to full height of parent
				if GetParent() then rect.dimension.SetY(GetParent().rect.getH())
		End Select

		Resize()

		return TRUE
	End Method


	'handle clicks on the up/down-buttons and inform others about changes
	Function onButtonClick:Int( triggerEvent:TEventBase )
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		If guiScroller = Null Then Return False

		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "up").AddNumber("scrollAmount", 15), guiScroller ) )
		ElseIf sender = guiScroller.guiButtonPlus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "down").AddNumber("scrollAmount", 15), guiScroller ) )
		EndIf
	End Function


	'handle mousedown on the up/down-buttons and inform others about changes
	Function onButtonDown:Int( triggerEvent:TEventBase )
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		If guiScroller = Null Then Return False

		If MOUSEMANAGER.GetDownTime(1) > 0
			'if we still have to wait - return without emitting events
			If MOUSEMANAGER.GetDownTime(1) < guiScroller.mouseDownTime
				Return False
			EndIf
		EndIf

		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "up"), guiScroller ) )
		ElseIf sender = guiScroller.guiButtonPlus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "down"), guiScroller ) )
		EndIf
	End Function


	Method SetButtonStates:int(enableMinus:int = True, enablePlus:int = True)
		if enableMinus
			guiButtonMinus.Enable()
		else
			guiButtonMinus.Disable()
		endif

		if enablePlus
			guiButtonPlus.Enable()
		else
			guiButtonPlus.Disable()
		endif
	End Method


	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha() * 0.20

		SetColor 125,0,0
		Local width:Int = guiButtonMinus.GetScreenWidth()
		Local height:Int = guiButtonMinus.GetScreenHeight()
rem
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				DrawRect(GetScreenX() + width/4, GetScreenY() + height/2, width/2, GetScreenHeight() - height)
			Default
				DrawRect(GetScreenX() + width/2, GetScreenY() + height/4, GetScreenWidth() - width, height/2)
		End Select
endrem
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				DrawRect(GetScreenX() + width/4, GetScreenY() + 0.75*height, width/2, GetScreenHeight() - 1.25*height)
			Default
				DrawRect(GetScreenX() + 0.75*width, GetScreenY() + height/4, GetScreenWidth() - 1.25*width, height/2)
		End Select

		oldCol.SetRGBA()
	End Method
End Type
