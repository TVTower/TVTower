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
	Field mouseScrollAmount:Int = 5
	Field currentValue:Double
	Field _orientation:int = GUI_OBJECT_ORIENTATION_VERTICAL


	Method GetClassName:String()
		Return "tguiscrollerbase"
	End Method


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
		'allow to keep mouse button pressed and leave the area while still
		'scrolling
		self.setOption(GUI_OBJECT_KEEP_ACTIVE_ON_OUTSIDE_CONTINUED_MOUSEDOWN, True)


		'style myself - aligns buttons
		onAppearanceChanged()


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
	
	
	Method SetMouseScrollAmount(amount:Int)
		mouseScrollAmount = amount
	End Method


	'override to also check buttons
	Method IsAppearanceChanged:int()
		if guiButtonMinus and guiButtonMinus.isAppearanceChanged() then return TRUE
		if guiButtonPlus and guiButtonPlus.isAppearanceChanged() then return TRUE

		return Super.isAppearanceChanged()
	End Method


	'override default
	Method onAppearanceChanged:int()
		If _parent
			rect.position.setXY(_parent.rect.getW() - guiButtonMinus.rect.getW(),0)
			'this also aligns the buttons
			SetSize(_parent.rect.getW(), _parent.rect.getH())
		Else
			rect.position.setXY(rect.getW() - guiButtonMinus.rect.getW(),0)
			'this also aligns the buttons
			SetSize(rect.getW(), rect.getH())
		EndIf
	End Method


	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		'according the orientation we limit height or width
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				h = guiButtonMinus.rect.getH()
				'if w <= 0 then w = rect.GetW()
			case GUI_OBJECT_ORIENTATION_VERTICAL
				w = guiButtonMinus.rect.getW()
				'if h <= 0 then h = rect.GetH()
		End Select
		Super.SetSize(w, h)
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
		TriggerBaseEvent(GUIEventKeys.GUIObject_OnChangeValue, null, self)
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
				if _parent then rect.dimension.SetX(_parent.rect.getW())
			default
				guiButtonMinus.SetDirection("UP")
				guiButtonPlus.SetDirection("DOWN")
				'set scroller area to full height of parent
				if _parent then rect.dimension.SetY(_parent.rect.getH())
		End Select

		SetSize(-1,-1)

		return TRUE
	End Method


	Method onMouseScrollWheel:Int( triggerEvent:TEventBase ) override
		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If value = 0 Then Return False
		'emit event that the scroller position has changed
		Local direction:String = ""
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				If value < 0 Then direction = "up"
				If value > 0 Then direction = "down"
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				If value < 0 Then direction = "left"
				If value > 0 Then direction = "right"
		End Select
		If direction <> ""
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, New TData.AddString("direction", direction).AddInt("scrollAmount", mouseScrollAmount), self)
		EndIf

		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Method


	'handle clicks on the up/down-buttons and inform others about changes
	Function onButtonClick:Int( triggerEvent:TEventBase )
		'only handle left/primary key clicks
		If triggerEvent.GetData().GetInt("button") <> 1 Then Return False

		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScrollerBase = TGUIScrollerBase( sender._parent )
		If guiScroller = Null Then Return False

		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus or sender = guiScroller.guiButtonPlus
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, new TData.AddString("direction", sender.direction.ToLower()).AddInt("scrollAmount", 15), guiScroller)
		EndIf

		'handled the click
		Return True
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
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, new TData.AddString("direction", sender.direction.ToLower()), guiScroller )
		EndIf

		Return True
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
		return IsFocused() or guiButtonMinus.IsFocused() or guiButtonPlus.IsFocused()
	End Method


	Method Update:int()
		Super.Update()

		if begunAMouseDown
			MouseManager.ResetClicked(1)
			if not MouseManager.IsDown(1)
				begunAMouseDown = False
				MouseManager.ResetLongClicked(1)
			else
				'(do it in an "update" so it also handles "mousedown"
				'avoid long left-mousebutton clicks
				MouseManager.ResetLongClicked(1)
			endif
		endif
	End Method


	Method UpdateLayout()
		'realign buttons

		'move the first button to the most left and top position
		guiButtonMinus.rect.position.SetXY(0, 0)
		'move the second button to the most right and bottom position
		'do not use "screenRect" for the button as the LimitToRect() filters it out
		guiButtonPlus.rect.position.SetXY(GetScreenRect().GetW() - guiButtonPlus.rect.GetW(), GetScreenRect().GetH() - guiButtonPlus.rect.GetH())
	End Method
End Type




Type TGUIScroller Extends TGUIScrollerBase
	Field scrollHandle:TGUISlider


	Method GetClassName:String()
		Return "tguiscroller"
	End Method


	Method Create:TGUIScroller(parent:TGUIobject)
		Super.Create(parent)

		scrollHandle = New TGUISlider.Create(Null, new TVec2D.Init(22,100), "", "")
		scrollHandle.setParent(Self)
		scrollHandle.SetValueRange(0,100)
		scrollHandle.steps = 0
		scrollHandle.SetDirection(TGUISlider.DIRECTION_DOWN)
		scrollHandle._showFilledGauge = False
		scrollHandle._gaugeAlpha = 0.5
		scrollHandle.SetOption(GUI_OBJECT_KEEP_ACTIVE_ON_OUTSIDE_CONTINUED_MOUSEDOWN)
		scrollHandle.mouseScrollWheelStepSize = mouseScrollAmount

		'manage (update/draw) the handle on our own
		AddChild(scrollHandle)

		'listen to interaction with scrollHandle elements (dragging it)
		'or mouse scrolling over its "progress area"
		'attention: do not listen to "guiobject.onchangevalue" as this is
		'           also triggered by "onScrollPositionChanged" (circlular
		'           triggers)
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUISlider_SetValueByMouse, onScrollHandleChange, scrollHandle ))
		'listen to changes via scroller buttons
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScrollPositionChanged, self))

		return self
	End Method


	Method SetMouseScrollAmount(amount:Int) override
		Super.SetMouseScrollAmount(amount)
		if scrollHandle then scrollHandle.mouseScrollWheelStepSize = mouseScrollAmount
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
		TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, new TData.AddInt("isRelative", True).AddFloat("percentage", sender.GetRelativeValue()).Add("sendingSlider", sender), guiScroller )
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


	'override to also check handle
	Method IsAppearanceChanged:int()
		if scrollHandle and scrollHandle.isAppearanceChanged() then return TRUE

		return Super.isAppearanceChanged()
	End Method


	Method ScrollerHasFocus:int()
		return Super.ScrollerHasFocus() or scrollHandle.IsFocused()
	End Method


	Method DrawContent()
'		DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
	End Method


	Method UpdateLayout()
		'realign buttons
		Super.UpdateLayout()

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
End Type




Type TGUIScrollerSimple Extends TGUIScrollerBase
	'area showing progress / react to clicks
	Field progressRect:TRectangle = new TRectangle.Init()
	Field progressRectHovered:int = False


	Method GetClassName:String()
		Return "tguiscrollersimple"
	End Method


	Method Create:TGUIScrollerSimple(parent:TGUIobject)
		Super.Create(parent)

		return self
	End Method


	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)

		'=== PROGRESS RECT ===
		'fill whole area
		progressRect.SetXYWH(0,0, GetScreenRect().GetW(),GetScreenRect().GetH())
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

		'check if mouse over progressRect
		if not isHovered()
			progressRectHovered = False

		else
			local overPos:TVec2D = new TVec2D.Init( MouseManager.x - GetScreenRect().GetX(), MouseManager.y - GetScreenRect().GetY())
			if progressRect.ContainsVec(overPos)
				progressRectHovered = True
			endif

			'check if mouse clicked on the progressRect
			if mouseIsClicked
				'convert clicked position to local widget coordinates
				local clickPos:TVec2D = mouseIsClicked.Copy()
				clickPos.AddXY(-GetScreenRect().GetX(), -GetScreenRect().GetY())
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
					TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, new TData.Addint("isRelative", True).AddFloat("percentage", GetRelativeValue()), self )

					'reset clicked state and button state
					mouseIsClicked = Null

					'handled left click
					MouseManager.SetClickHandled(1)
				endif
			endif
		endif
	End Method


	Method DrawContent()
		local oldCol:SColor8; GetColor(oldCol)
		local oldColA:Float = GetAlpha()
		SetAlpha oldColA * GetScreenAlpha() * 0.20

		'draw a area to click on
		if progressRectHovered
			SetColor 125,0,0
		else
			SetColor 125,50,50
		endif
		DrawRect(GetScreenRect().GetX() + progressRect.GetX(), GetScreenRect().GetY() + progressRect.GetY(), progressRect.GetW(), progressRect.GetH())

		SetAlpha oldColA * GetScreenAlpha() * 0.5
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				DrawRect(GetScreenRect().GetX() + progressRect.GetX() + GetRelativeValue() * progressRect.GetW(), GetScreenRect().GetY() + progressRect.GetY(), 3, progressRect.GetH())
			case GUI_OBJECT_ORIENTATION_VERTICAL
				DrawRect(GetScreenRect().GetX() + progressRect.GetX(), GetScreenRect().GetY() + progressRect.GetY() + GetRelativeValue() * progressRect.GetH(), progressRect.GetW(), 3)
		End Select

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method
End Type
