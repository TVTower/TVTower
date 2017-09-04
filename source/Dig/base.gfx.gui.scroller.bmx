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
Import "base.gfx.gui.slider.bmx"



Type TGUIScrollerBase extends TGUIobject
	Field mouseDownTime:Int = 250	'milliseconds until we react on "mousedown"
	Field guiButtonMinus:TGUIArrowButton = Null
	Field guiButtonPlus:TGUIArrowButton	= Null
	Field minValue:Double = 0
	Field maxValue:Double = 100
	Field begunAMouseDown:int = False
	Field currentValue:Double
	Field _orientation:int = GUI_OBJECT_ORIENTATION_VERTICAL


	Method Create:TGUIScrollerBase(parent:TGUIobject)
		setParent(parent)

		'create buttons
		guiButtonMinus = New TGUIArrowButton.Create(Null, new TVec2D.Init(22,22), "UP", "")
		guiButtonPlus = New TGUIArrowButton.Create(Null, new TVec2D.Init(22,22), "DOWN", "")

		guiButtonMinus.spriteButtonBaseName = "gfx_gui_button.rounded"
		guiButtonPlus.spriteButtonBaseName = "gfx_gui_button.rounded"

		'set the buttons to ignore focus setting
		guiButtonMinus.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
		guiButtonPlus.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		'the scroller itself ignores focus too
		self.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		'style myself - aligns buttons
		onStatusAppearanceChange()


		'set the parent of the buttons so they inherit visible state etc.
'		guiButtonMinus.setParent(Self)
'		guiButtonPlus.setParent(Self)
		AddChild(guiButtonMinus)
		AddChild(guiButtonPlus)

		'scroller is interested in hits (not clicks) on its buttons
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScrollerBase.onButtonClick, guiButtonMinus ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScrollerBase.onButtonClick, guiButtonPlus ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScrollerBase.onButtonDown, guiButtonMinus ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScrollerBase.onButtonDown, guiButtonPlus ))

		GUIManager.Add( Self)

		Return Self
	End Method


	Method Remove:Int()
		Super.Remove()
		if guiButtonMinus then guiButtonMinus.Remove()
		if guiButtonPlus then guiButtonPlus.Remove()
	End Method


	'override to also check buttons
	Method IsAppearanceChanged:int()
		if guiButtonMinus and guiButtonMinus.isAppearanceChanged() then return TRUE
		if guiButtonPlus and guiButtonPlus.isAppearanceChanged() then return TRUE

		return Super.isAppearanceChanged()
	End Method


	'override default
	Method onStatusAppearanceChange:int()
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



	Method SetMinValue(value:Double)
		minValue = value

		'sort min max
		if minValue > maxValue
			local old:Double = minValue
			minValue = maxValue
			maxValue = minValue
		endif
	End Method


	Method SetMaxValue(value:Double)
		maxValue = value

		'sort min max
		if minValue > maxValue
			local old:Double = minValue
			minValue = maxValue
			maxValue = minValue
		endif
	End Method


	Method SetValueRange(minValue:Double, maxValue:Double)
		SetMinValue(minValue)
		SetMaxValue(maxValue)
	End Method


	Method SetCurrentValue(currentValue:Double)
		EventManager.triggerEvent( TEventSimple.Create( "guiobject.onChangeValue", null, self ) )
		self.currentValue = Max(minValue, Min(maxValue, currentValue))
	End Method


	Method GetRelativeValue:Float()
		if maxValue = minValue then return 0
		return Min(1.0, Max(0.0, currentValue / (maxValue - minValue)))
	End Method


	Method SetRelativeValue:Double(percentage:Float)
		SetCurrentValue(percentage * (maxValue - minValue))
		return currentValue
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

		Local guiScroller:TGUIScrollerBase = TGUIScrollerBase( sender._parent )
		If guiScroller = Null Then Return False

		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus or sender = guiScroller.guiButtonPlus
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", sender.direction.ToLower()).AddNumber("scrollAmount", 15), guiScroller ) )
		EndIf
	End Function


	'handle mousedown on the up/down-buttons and inform others about changes
	Function onButtonDown:Int( triggerEvent:TEventBase )
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScrollerBase = TGUIScrollerBase( sender._parent )
		If guiScroller = Null Then Return False

		If MOUSEMANAGER.GetDownTime(1) > 0
			'if we still have to wait - return without emitting events
			If MOUSEMANAGER.GetDownTime(1) < guiScroller.mouseDownTime
				Return False
			EndIf
		EndIf

		guiScroller.begunAMouseDown = True

		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus or sender = guiScroller.guiButtonPlus
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", sender.direction.ToLower()), guiScroller ) )
		EndIf
	End Function


	Method SetButtonStates:int(enableMinus:int = True, enablePlus:int = True)
		if enableMinus <> guiButtonMinus.IsEnabled()
			if enableMinus
				guiButtonMinus.Enable()
			else
				guiButtonMinus.Disable()
			endif
		endif

		if enablePlus <> guiButtonPlus.IsEnabled()
			if enablePlus
				guiButtonPlus.Enable()
			else
				guiButtonPlus.Disable()
			endif
		endif
	End Method


	Method ScrollerHasFocus:int()
		return HasFocus() or guiButtonMinus.HasFocus() or guiButtonPlus.HasFocus()
	End Method


	Method Update:int()
		Super.Update()

		if begunAMouseDown
			if not MouseManager.IsDown(1)
				begunAMouseDown = False
			else
				'(do it in an "update" so it also handles "mousedown"
				'avoid long left-mousebutton clicks
				MouseManager.ResetLongClicked(1, True)
			endif
		endif
	End Method
End Type




Type TGUIScroller Extends TGUIScrollerBase
	Field scrollHandle:TGUISlider

	Method Create:TGUIScroller(parent:TGUIobject)
		Super.Create(parent)

		scrollHandle = New TGUISlider.Create(Null, new TVec2D.Init(22,100), "", "")
		scrollHandle.setParent(Self)
		scrollHandle.SetValueRange(0,100)
		scrollHandle.steps = 0
		scrollHandle.SetDirection(TGUISlider.DIRECTION_DOWN)
		scrollHandle._showFilledGauge = False
		scrollHandle._gaugeAlpha = 0.5

		'manage (update/draw) the handle on our own
		AddChild(scrollHandle)
		
		'listen to interaction with scrollHandle elements (dragging it)
		'attention: do not listen to "guiobject.onchangevalue" as this is
		'           also triggered by "onScrollPositionChanged" (circlular
		'           triggers)
		AddEventListener(EventManager.registerListenerFunction( "guislider.setValueByMouse", onScrollHandleChange, scrollHandle ))
		'listen to changes via scroller buttons
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScrollPositionChanged, self))

		return self
	End Method


	Function onScrollPositionChanged:Int( triggerEvent:TEventBase )
		Local sender:TGUIScroller = TGUIScroller(triggerEvent.GetSender())
		If sender = Null Then Return False

		'ignore if coming from our own (changeType = percentage)
		if triggerEvent.GetData().Get("sendingSlider") = sender.scrollHandle then return False

'		local percentage:Float = triggerEvent.GetData().GetFloat("percentage")
'		print percentage + "  " + sender.GetRelativeValue()

		sender.scrollHandle.SetRelativeValue( sender.GetRelativeValue() )
	End Function
	

	'scroller got change
	Function onScrollHandleChange:Int( triggerEvent:TEventBase )
		Local sender:TGUISlider = TGUISlider(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		If guiScroller = Null Then Return False

		guiScroller.SetRelativeValue( sender.GetRelativeValue() )

		if MouseManager.IsDown(1) then guiScroller.begunAMouseDown = true

		'inform others (equally to up/down-buttonclicks)
		EventManager.triggerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("changeType", "percentage").AddNumber("percentage", sender.GetRelativeValue()).Add("sendingSlider", sender), guiScroller ) )
	End Function


	Method SetCurrentValue(currentValue:Double)
		Super.SetCurrentValue(currentValue)
		'move handle accordingly
		if scrollHandle then scrollHandle.SetRelativeValue( GetRelativeValue() )
	End Method


	'overridden
	'set scroll handle too
	Method SetRelativeValue:Double(percentage:Float)
		Super.SetRelativeValue(percentage)

		'move handle accordingly
		if scrollHandle then scrollHandle.SetRelativeValue( GetRelativeValue() )

		return currentValue
	End Method


	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)

		'called after scrollHandle creation?
		if scrollHandle
			scrollHandle._handleDim.SetX( guiButtonMinus.rect.GetW() )

			'according the orientation we limit height or width
			Select _orientation
				case GUI_OBJECT_ORIENTATION_HORIZONTAL
					scrollHandle.rect.position.SetXY( guiButtonMinus.rect.GetX2()-3, guiButtonMinus.rect.GetY())
					scrollHandle.rect.dimension.SetXY( guiButtonPlus.rect.GetX() - guiButtonMinus.rect.GetX2() + 6, guiButtonMinus.rect.GetH())
					scrollHandle.SetDirection(TGUISlider.DIRECTION_RIGHT)
				case GUI_OBJECT_ORIENTATION_VERTICAL
					scrollHandle.rect.position.SetXY( guiButtonMinus.rect.GetX(), guiButtonMinus.rect.GetY2() -3)
					scrollHandle.rect.dimension.SetXY( guiButtonPLus.rect.GetW(), guiButtonPlus.rect.GetY() - guiButtonMinus.rect.GetY2() + 6)
					scrollHandle.SetDirection(TGUISlider.DIRECTION_DOWN)
			End Select
		endif
	End Method


	'override to also check handle
	Method IsAppearanceChanged:int()
		if scrollHandle and scrollHandle.isAppearanceChanged() then return TRUE

		return Super.isAppearanceChanged()
	End Method


	Method ScrollerHasFocus:int()
		return Super.ScrollerHasFocus() or scrollHandle.HasFocus()
	End Method
	

	Method DrawContent()
	End Method
End Type




Type TGUIScrollerSimple Extends TGUIScrollerBase
	'area showing progress / react to clicks
	Field progressRect:TRectangle = new TRectangle.Init()
	Field progressRectHovered:int = False


	Method Create:TGUIScrollerSimple(parent:TGUIobject)
		Super.Create(parent)
		return self
	End Method


	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)

		'=== PROGRESS RECT ===
		'fill whole area
		progressRect.SetXYWH(0,0,GetScreenWidth(),GetScreenHeight())
		'subtract buttons
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				progressRect.position.AddY(+guiButtonMinus.rect.GetH()/4)
				progressRect.dimension.SetY(+guiButtonMinus.rect.GetH()/2)
				
				progressRect.position.AddX(+guiButtonMinus.rect.GetW() - 2)
				progressRect.dimension.AddX(-guiButtonMinus.rect.GetW() - guiButtonPlus.rect.GetW() + 2)
			case GUI_OBJECT_ORIENTATION_VERTICAL
				progressRect.position.AddX(+guiButtonMinus.rect.GetW()/4)
				progressRect.dimension.SetX(+guiButtonMinus.rect.GetW()/2)

				progressRect.position.AddY(+guiButtonMinus.rect.GetH() - 2)
				progressRect.dimension.AddY(-guiButtonMinus.rect.GetH() - guiButtonPlus.rect.GetH() + 2)
		End Select
	End Method


	'override to add progressRect-click support
	Method Update:int()
		Super.Update()
rem
		if (guiButtonMinus and guiButtonMinus.isHovered()) or (guiButtonPlus and guiButtonPlus.isHovered())
			'process long clicks to avoid odd "right click behaviour"
			if MouseManager.IsLongClicked(1)
				MouseManager.ResetClicked(1)
			endif
		endif
endrem

		'check if mouse over progressRect
		if not isHovered()
			progressRectHovered = False

		else
			local overPos:TVec2D = new TVec2D.Init( MouseManager.x -GetScreenX(), MouseManager.y -GetScreenY())
			if progressRect.ContainsVec(overPos)
				progressRectHovered = True
			endif

			'check if mouse clicked on the progressRect
			if mouseIsClicked
				'convert clicked position to local widget coordinates
				local clickPos:TVec2D = mouseIsClicked.Copy()
				clickPos.AddXY(-GetScreenX(), -GetScreenY())
				if progressRect.ContainsVec(clickPos)
'					clickPos.AddXY(progressRect.GetX(), progressRect.GetY())
					local progress:float = 0
				
					Select _orientation
						case GUI_OBJECT_ORIENTATION_HORIZONTAL
							if progressRect.GetW() > 0
								'subtract progress start from position
								clickPos.X :- progressRect.GetX()
								progress = clickPos.x / progressRect.GetW()
							endif
						case GUI_OBJECT_ORIENTATION_VERTICAL
							if progressRect.GetH() > 0
								'subtract progress start from position
								clickPos.y :- progressRect.GetY()
								progress = clickPos.y / progressRect.GetH()
							endif
					End Select
					'scroll to the percentage
					SetRelativeValue(progress)
					'inform others
					EventManager.triggerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("changeType", "percentage").AddNumber("percentage", GetRelativeValue()), self ) )

					'reset clicked state and button state
					mouseIsClicked = Null
					MouseManager.ResetKey(1)
				endif
			endif
		endif
	End Method
	

	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha() * 0.20

		'draw a area to click on
		if progressRectHovered
			SetColor 125,0,0
		else
			SetColor 125,50,50
		endif
		DrawRect(GetScreenX() + progressRect.GetX(), GetScreenY() + progressRect.GetY(), progressRect.GetW(), progressRect.GetH())

		SetAlpha oldCol.a * GetScreenAlpha() * 0.5
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				DrawRect(GetScreenX() + progressRect.GetX() + GetRelativeValue() * progressRect.GetW(), GetScreenY() + progressRect.GetY(), 3, progressRect.GetH())
			case GUI_OBJECT_ORIENTATION_VERTICAL
				DrawRect(GetScreenX() + progressRect.GetX(), GetScreenY() + progressRect.GetY() + GetRelativeValue() * progressRect.GetH(), progressRect.GetW(), 3)
		End Select

		oldCol.SetRGBA()
	End Method
End Type
