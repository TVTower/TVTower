Rem
	====================================================================
	Input classes
	====================================================================

	There are 3 Managers:

	TMouseManager: Mouse position, buttons ...
	TKeyManager: key states ...
	TKeyWrapper: managing "hold down" states for keys


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
ENDREM
SuperStrict
Import brl.System
Import brl.PolledInput
Import "base.util.vector.bmx"
Import "base.util.time.bmx"
Import "base.util.virtualgraphics.bmx"

Global MOUSEMANAGER:TMouseManager = New TMouseManager
Global KEYMANAGER:TKeyManager = New TKeyManager
Global KEYWRAPPER:TKeyWrapper = New TKeyWrapper


Const KEY_STATE_NORMAL:Int			= 0	'nothing done
Const KEY_STATE_HIT:Int				= 1	'once dow, now up
Const KEY_STATE_DOWN:Int			= 2 'down
Const KEY_STATE_UP:Int				= 4 'up
Const KEY_STATE_BLOCKED:Int			= 8

For Local i:Int = 0 To 255
	KEYWRAPPER.allowKey(i,KEYWRAP_ALLOW_BOTH,600,100)
Next
AddHook(EmitEventHook, TMouseManager.InputHook,Null,0)



Rem
	https://www.quirksmode.org/dom/events/click.html
	https://developer.mozilla.org/en-US/docs/Web/API/Element/dblclick_event
	-> they describe "doubleclick" as follow up of two clicks within
	   a given timeframe. So each "doubleclick" is preceeded by two clicks


	Hint:
	"click":
		the button was down and is now released
	"double click":
		the button was clicked two times within a defined time
End Rem
Type TMouseManager
	Field currentPos:TVec2D = New TVec2D.Init(0,0)
	Field x:Int = 0.0
	Field y:Int = 0.0
	'amount of pixels moved (0=zero, -upwards, +downwards)
	Field scrollWheelMoved:Int = 0
	'time (in ms) to wait for another click to recognize doubleclicks
	'so it is also the maximum time "between" that needed two clicks
	Field doubleClickMaxTime:Int = 250
	Field longClickMinTime:Int = 450


	Field _lastPos:TVec2D = New TVec2D.Init(0,0)
	Field _lastScrollWheel:Int = 0

	'store up to 20 click information of each type
	'so clicks between "updates" can still be processed one after another
	'each information contains: position, click type and time of the click
	Field _clickStack:TMouseManagerClick[][]
	Field _clickStackIndex:Int[5]
	Field _longClickStack:TMouseManagerClick[][]
	Field _longClickStackIndex:Int[5]
	Field _doubleClickStack:TMouseManagerClick[][]
	Field _doubleClickStackIndex:Int[5]

	'previous position at the screen when a button was clicked, doubleclicked
	'or longclicke the last time
	Field _lastAnyClickPos:TVec2D[5]
	'store clicks in the doubleclick timespan to identify double clicks
	Field _clicksInDoubleClickTimeCount:Int[] = [0,0,0,0,0]

	'down or not?
	Field _down:Int[] = [0,0,0,0,0]
	'time since when the button was pressed last
	Field _downTime:Long[] = [0:Long,0:Long,0:Long,0:Long,0:Long]
	'can clicks/hits get read?
	'special info read is possible (IsDown(), IsNormal())
	Field _enabled:Int[] = [True, True, True, True, True]


	'TOUCH emulation
	Field _longClickModeEnabled:Int = False
	Field _longClickLeadsToRightClick:Int = True
	'skip first click (touch screens)
	Field _ignoreFirstClick:Int = False
	Field _hasIgnoredFirstClick:Int[] = [0,0,0,0,0] 'currently ignoring?
	Field _ignoredFirstClickPos:TVec2D[] = [New TVec2D, New TVec2D, New TVec2D, New TVec2D, New TVec2D]
	'distance in pixels, if mouse moved further away, the next
	'click will get ignored ("tap")
	Field _minSwipeDistance:Int = 10

	Global stackSize:Int = 20
	Global evMouseDown:Int[5]
	Global evMouseHits:Int[5]
	Global evMousePosX:Int
	Global evMousePosY:Int
	Global evMouseZ:Int

	Global CLICKTYPE_CLICK:Int = 1
	Global CLICKTYPE_LONGCLICK:Int = 2
	Global CLICKTYPE_DOUBLECLICK:Int = 3


	'handle all incoming input events
	Function InputHook:Object( id:Int, data:Object, context:Object )
		Local ev:TEvent = TEvent(data)
		If Not ev Return data

		'filter by source?
		'If ev.source = ... Return data

		Select ev.id
			Case EVENT_MOUSEDOWN
				'we only handle up to the 5h mousebutton
				If ev.data > 0 and ev.data <= 5
					If Not evMouseDown[ev.data-1]
						evMouseDown[ev.data-1] = 1
						evMouseHits[ev.data-1] :+ 1
					EndIf
					MouseManager._HandleButtonEvent(ev.data)
				EndIf
			Case EVENT_MOUSEUP
				'we only handle up to the 5h mousebutton
				If ev.data > 0 and ev.data <= 5
					evMouseDown[ev.data-1] = 0
					MouseManager._HandleButtonEvent(ev.data)
				EndIf
			Case EVENT_MOUSEMOVE
				evMousePosX = ev.x
				evMousePosY = ev.y
			Case EVENT_MOUSEWHEEL
				evMouseZ :+ ev.data
			Case EVENT_APPSUSPEND, EVENT_APPRESUME
				evMouseDown = New Int[5] 'flush
				evMouseHits = New Int[5] 'flush
				evMouseZ = 0'flush
		End Select

		Return data
	End Function


	Method New()
		InitializeClickStacks(-1)
	End Method


	Method _GetClickStackEntry:TMouseManagerClick(button:Int, clickType:Int = -1)
	'	if clickType = -1 then clickType = CLICKTYPE_CLICK

		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				Return _doubleClickStack[button-1][ _doubleClickStackIndex[button-1] ]
			Case CLICKTYPE_LONGCLICK
				Return _longClickStack[button-1][ _longClickStackIndex[button-1] ]
			'case CLICKTYPE_CLICK
			Default
				Return _clickStack[button-1][ _clickStackIndex[button-1] ]
		End Select
	End Method


	Method _GetClickStackIndex:Int(button:Int, clickType:Int = -1)
		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				Return _doubleClickStackIndex[button-1]
			Case CLICKTYPE_LONGCLICK
				Return _longClickStackIndex[button-1]
			'case CLICKTYPE_CLICK
			Default
				Return _clickStackIndex[button-1]
		End Select
	End Method


	'remove the last added click from the stack
	'(actually it just lowers the index so the old click object will
	' be reused on the next click)
	Method _RemoveClickStackEntry:TMouseManagerClick(button:Int, clickType:Int = -1, clickCount:Int = 1)
		Local buttonIndex:Int = button - 1
		'remove all?
		If clickCount < 0 Then clickCount = stackSize

		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				_doubleClickStackIndex[buttonIndex] = Max(0, _doubleClickStackIndex[buttonIndex] - clickCount)

			Case CLICKTYPE_LONGCLICK
				_longClickStackIndex[buttonIndex] = Max(0, _longClickStackIndex[buttonIndex] - clickCount)

			Default
				_clickStackIndex[buttonIndex] = Max(0, _clickStackIndex[buttonIndex] - clickCount)
		End Select
	End Method


	Method _AddClickStackEntry:TMouseManagerClick(button:Int, clickType:Int = -1, position:TVec2D, time:Long = -1)
		Local buttonIndex:Int = button - 1
		Local stack:TMouseManagerClick[]
		Local stackIndex:Int
		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				stack = _doubleClickStack[buttonIndex]
				stackIndex = _doubleClickStackIndex[buttonIndex]

			Case CLICKTYPE_LONGCLICK
				stack = _longClickStack[buttonIndex]
				stackIndex = _longClickStackIndex[buttonIndex]

			Default
				stack = _clickStack[buttonIndex]
				stackIndex = _clickStackIndex[buttonIndex]
		End Select


		stackIndex :+ 1
		'reached limit? purge oldest 5 clicks
		If stackIndex >= stackSize
			stack = stack[5 .. ] + (New TMouseManagerClick[5])
			stackIndex :- 5
		EndIf

		'create new if missing, else just reuse existing
		If Not stack[stackIndex] Then stack[stackIndex] = New TMouseManagerClick
		stack[stackIndex].Init(clickType, position.Copy(), time)


		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				_doubleClickStack[buttonIndex] = stack
				_doubleClickStackIndex[buttonIndex] = stackIndex

			Case CLICKTYPE_LONGCLICK
				_longClickStack[buttonIndex] = stack
				_longClickStackIndex[buttonIndex] = stackIndex

			Default
				_clickStack[buttonIndex] = stack
				_clickStackIndex[buttonIndex] = stackIndex
		End Select

		Return stack[stackIndex]
	End Method


	Method InitializeClickStacks(clickType:Int = -1)
		If clickType = -1 Or clickType = CLICKTYPE_CLICK
			_clickStack = _clickStack[.. GetButtonCount()]
			For Local i:Int = 0 Until GetButtonCount()
				_clickStack[i] = New TMouseManagerClick[stackSize]
			Next
			_clickStackIndex = New Int[stackSize]
		EndIf
		If clickType = -1 Or clickType = CLICKTYPE_LONGCLICK
			_longClickStack = _longClickStack[.. GetButtonCount()]
			For Local i:Int = 0 Until GetButtonCount()
				_longClickStack[i] = New TMouseManagerClick[stackSize]
			Next
			_longClickStackIndex = New Int[stackSize]
		EndIf
		If clickType = -1 Or clickType = CLICKTYPE_DOUBLECLICK
			_doubleClickStack = _doubleClickStack[.. GetButtonCount()]
			For Local i:Int = 0 Until GetButtonCount()
				_doubleClickStack[i] = New TMouseManagerClick[stackSize]
			Next
			_doubleClickStackIndex = New Int[stackSize]
		EndIf
	End Method


	Method InitializeClickStack(button:Int = -1, clickType:Int = -1)
		If button < 1 Or button > GetButtonCount() Then Return

		If clickType = -1 Or clickType = CLICKTYPE_CLICK
			_clickStack[button-1] = New TMouseManagerClick[stackSize]
			_clickStackIndex[button-1] = 0
		EndIf
		If clickType = -1 Or clickType = CLICKTYPE_LONGCLICK
			_longClickStack[button-1] = New TMouseManagerClick[stackSize]
			_longClickStackIndex[button-1] = 0
		EndIf
		If clickType = -1 Or clickType = CLICKTYPE_DOUBLECLICK
			_doubleClickStack[button-1] = New TMouseManagerClick[stackSize]
			_doubleClickStackIndex[button-1] = 0
		EndIf
	End Method


	'return amount of managed buttons
	Method GetButtonCount:Int()
		Return _down.length 'ignore 0
	End Method


	'reset the state of the given button
	Method ResetButton:Int(button:Int)
		_downTime[button-1] = 0
		_down[button-1] = False

		'remove all potentially logged clicks for that button
		ResetClicks(button, -1)

		Return KEY_STATE_NORMAL
	End Method


	Method ResetClicks(button:Int, clickType:Int = -1)
		_RemoveClickStackEntry(button, clickType, -1)

		'reset emulated right clicks
		'-> longclick for real right click
		If _longClickModeEnabled And button = 2 And (clickType = -1 Or clickType = CLICKTYPE_CLICK)
			_RemoveClickStackEntry(1, CLICKTYPE_LONGCLICK, -1)
		EndIf
		'-> right click for a long click
		If _longClickModeEnabled And button = 1 And (clickType = -1 Or clickType = CLICKTYPE_LONGCLICK)
			_RemoveClickStackEntry(2, CLICKTYPE_CLICK, -1)
		EndIf
	End Method


	Method ResetClicked(button:Int)
		ResetClicks(button, CLICKTYPE_CLICK)
	End Method


	Method ResetDoubleClicked(button:Int)
		ResetClicks(button, CLICKTYPE_DOUBLECLICK)
	End Method


	Method ResetLongClicked(button:Int)
		ResetClicks(button, CLICKTYPE_LONGCLICK)
	End Method


	'remove all logged clicks older than "age" milliseconds
	Method RemoveOutdatedClicks:Int(age:Int)
		Local removed:Int = 0
		Local click:TMouseManagerClick
		Local t:Long = Time.GetAppTimeGone()

		For Local i:Int = 1 To GetButtonCount()
			For Local cType:Int = EachIn [CLICKTYPE_CLICK, CLICKTYPE_DOUBLECLICK, CLICKTYPE_LONGCLICK]
				click = _GetClickStackEntry(i, cType)
				While GetClicks(i, cType) > 0 And click And click.t + age < t
					_RemoveClickstackEntry(i, cType)
					click = _GetClickStackEntry(i, cType)
				Wend
			Next
		Next
	End Method


	Method SetClickHandled(button:Int, clickType:Int = -1)
		_RemoveClickStackEntry(button, clickType)

		'reset emulated right clicks
		'-> longclick for real right click
		If _longClickModeEnabled And button = 2 And (clickType = -1 Or clickType = CLICKTYPE_CLICK)
			_RemoveClickStackEntry(1, CLICKTYPE_LONGCLICK)
		EndIf
		'-> right click for a long click
		If _longClickModeEnabled And button = 1 And (clickType = -1 Or clickType = CLICKTYPE_LONGCLICK)
			_RemoveClickStackEntry(2, CLICKTYPE_CLICK)
		EndIf
	End Method


	Method SetDoubleClickHandled(button:Int)
		_RemoveClickStackEntry(button, CLICKTYPE_DOUBLECLICK)
	End Method


	Method SetLongClickHandled(button:Int)
		_RemoveClickStackEntry(button, CLICKTYPE_LONGCLICK)

		'reset emulated right clicks
		'-> right click for a long click
		If _longClickModeEnabled And button = 1
			_RemoveClickStackEntry(2, CLICKTYPE_CLICK)
		EndIf
	End Method


	Method Disable(button:Int)
		_enabled[button-1] = False
	End Method


	Method Enable(button:Int)
		_enabled[button-1] = True
	End Method


	Method IsEnabled:Int(button:Int)
		Return _enabled[button-1]
	End Method


	'returns whether the button is in normal state
	Method IsNormal:Int(button:Int)
		'currently ignoring the key?
		If _ignoreFirstClick And Not _hasIgnoredFirstClick[button-1] Then Return True

		Return Not _down[button-1]
	End Method


	'returns whether the button is in down state
	Method isDown:Int(button:Int)
		'currently ignoring the key?
		If _ignoreFirstClick And Not _hasIgnoredFirstClick[button-1] Then Return False

		Return _down[button-1]
	End Method


	'returns whether the button got clicked, no waiting time
	'is added
	Method IsClicked:Int(button:Int)
		If Not _enabled[button-1] Then Return False

		Return GetClicks(button, CLICKTYPE_CLICK) > 0
	End Method


	'returns whether the button was clicked 2 times
	Method IsDoubleClicked:Int(button:Int)
		If Not _enabled[button-1] Then Return False

		Return GetClicks(button, CLICKTYPE_DOUBLECLICK) > 0
	End Method


	'returns whether the button was clicked 2 times
	Method IsLongClicked:Int(button:Int)
		If Not _longClickModeEnabled Then Return False
		If Not _enabled[button-1] Then Return False

		Return GetClicks(button, CLICKTYPE_LONGCLICK) > 0
	End Method


	'returns whether the mouse moved between two updates
	Method HasMoved:Int()
		Return (0 <> GetMovedDistance())
	End Method


	'returns whether the mouse moved since last click of the button
	Method HasMovedSinceClick:Int(button:Int)
		Return (0 <> GetMovedDistanceSinceClick(button))
	End Method


	'returns whether the mouse moved since between last click and the one before
	Method HasMovedBetweenClicks:Int(button:Int)
		Return (0 <> GetMovedDistanceBetweenClicks(button))
	End Method


	Method GetMovedDistance:Int()
		Return Sqr((_lastPos.X - Int(x))^2 + (_lastPos.y - Int(y))^2)
	End Method


	Method GetMovedDistanceSinceClick:Int(button:Int, clickType:Int = -1)
		If clickType = -1 Then clickType = CLICKTYPE_CLICK

		Local c:TMouseManagerClick = _GetClickStackEntry(button, clickType)
		If Not c Then Return 0
		Return Sqr((c.position.x - Int(x))^2 + (c.position.y - Int(y))^2)
	End Method


	Method GetMovedDistanceBetweenClicks:Int(button:Int, clickType:Int = -1)
		If Not _lastAnyClickPos[button-1] Then Return 0

		Local c:TMouseManagerClick = _GetClickStackEntry(button, clickType)
		If Not c Then Return 0

		Return c.position.DistanceTo(_lastAnyClickPos[button])
		'Return Sqr((_lastAnyClickPos[button].position.x - c.position.x)^2 + (_lastAnyClickPos.position.y - c.position.y)^2)
	End Method


	Method GetClickTime:Long(button:Int, clickType:Int = -1)
		Local c:TMouseManagerClick = _GetClickStackEntry(button, clickType)
		If Not c Then Return 0
		Return c.t
	End Method


	Method GetClickPosition:TVec2D(button:Int, clickType:Int = -1)
		Local c:TMouseManagerClick = _GetClickStackEntry(button, clickType)
		If Not c Then Return Null
		Return c.position
	End Method


	Method GetPosition:TVec2D()
		Return currentPos
	End Method


	Method GetX:Int()
		Return Int(currentPos.x)
	End Method


	Method GetY:Int()
		Return Int(currentPos.y)
	End Method


	'returns how many milliseconds a button is down
	Method GetDownTime:Long(button:Int)
		If _downTime[button-1] > 0
			Return Time.GetAppTimeGone() - _downTime[button-1]
		Else
			Return 0
		EndIf
	End Method


	'returns positive or negative value describing the movement
	'of the scrollwheel
	Method GetScrollwheelMovement:Int()
		Return scrollWheelMoved
	End Method


	'returns the amount of clicks
	Method GetClicks:Int(button:Int, clickType:Int = -1)
		Return _GetClickStackIndex(button, clickType)
	End Method


	'returns the amount of double clicks
	Method GetDoubleClicks:Int(button:Int)
		Return _GetClickStackIndex(button, CLICKTYPE_DOUBLECLICK)
	End Method


	'returns the amount of long clicks
	Method GetLongClicks:Int(button:Int)
		Return _GetClickStackIndex(button, CLICKTYPE_LONGCLICK)
	End Method


	'returns array of bools describing down state of each button
	Method GetAllIsDown:Int[]()
		Return [False,..
		        IsDown(1), ..
		        IsDown(2), ..
		        IsDown(3) ..
		        ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllIsClicked:Int[]()
		Return [False,..
		        IsClicked(1), ..
		        IsClicked(2), ..
		        IsClicked(3) ..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllIsDoubleClicked:Int[]()
		Return [False,..
		        IsDoubleClicked(1),..
		        IsDoubleClicked(2),..
		        IsDoubleClicked(3)..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllIsLongClicked:Int[]()
		Return [False,..
		        IsLongClicked(1), ..
		        IsLongClicked(2), ..
		        IsLongClicked(3) ..
		       ]
	End Method


	'-----


	'Update the button states
	Method Update:Int()
		'SCROLLWHEEL
		'by default scroll wheel did not move
		scrollWheelMoved = 0

		If _lastScrollWheel <> evMouseZ
			scrollWheelMoved = -evMouseZ
			_lastScrollWheel = -evMouseZ
			evMouseZ = 0
		EndIf


		'POSITION
		'store last position
		_lastPos.SetXY(x, y)
		'update current position
		x = TVirtualGfx.getInstance().VMouseX()
		y = TVirtualGfx.getInstance().VMouseY()
		currentPos.x = x
		currentPos.y = y


		For Local i:Int = 0 Until GetButtonCount()
			If _ignoreFirstClick And _lastAnyClickPos[i] And _lastAnyClickPos[i].DistanceTo(currentPos) > _minSwipeDistance
				_hasIgnoredFirstClick[i] = False
			EndIf
		Next

	End Method


	'=== INTERNAL ===


	'called on incoming OS mouse events
	Method _HandleButtonEvent:Int(button:Int)
		Local buttonIndex:Int = button - 1

		'press (from "up" to "down")
		If evMouseDown[buttonIndex] And Not _down[buttonIndex]
			If Not _enabled[buttonIndex] Then Return False

			'Print Time.GetTimeGone() + "  normal => down"
			_down[buttonIndex] = True
			_downTime[buttonIndex] = Time.GetAppTimeGone()
		EndIf


		'release -> click (from down to up)
		If Not evMouseDown[buttonIndex] And _down[buttonIndex]

			If Not _enabled[buttonIndex]
				'if not enabled we still return to "NORMAL" and are no longer
				'down but do not count the hit/click
				_downTime[buttonIndex] = 0
				_down[buttonIndex] = False
				Return False
			EndIf

			Local t:Long = Time.GetAppTimeGone()
			Local timeSinceLastClick:Int = t - GetClickTime(button, CLICKTYPE_CLICK)
			If timeSinceLastClick < doubleClickMaxTime
				_clicksInDoubleClickTimeCount[buttonIndex] :+ 1
				'Print Time.GetTimeGone() + "    down => up => click within doubleclick time    clicks=" + (_clicksInDoubleClickTimeCount[buttonIndex])
			Else
				'Print Time.GetTimeGone() + "    down => up => reset doubleclick time"
				_clicksInDoubleClickTimeCount[buttonIndex] = 1
			EndIf


			Local currentPosVec:TVec2D = New TVec2D.Init(x, y)

			'check for swipe
			If _hasIgnoredFirstClick[buttonIndex] And _lastAnyClickPos[buttonIndex] And _lastAnyClickPos[buttonIndex].DistanceTo(currentPosVec) > _minSwipeDistance
				'Print "reset " + GetMovedDistanceBetweenClicks(button)+" > "+_minSwipeDistance
				_hasIgnoredFirstClick[buttonIndex] = False
			EndIf

			'store last click pos - even if we ignore the effect of the click
			_lastAnyClickPos[buttonIndex] = currentPosVec

			'- Ignore first click?
			'- Long click?
			'- Normal click + Double clicks?

			'ignore this potential click if it is the first one
			If _ignoreFirstClick And Not _hasIgnoredFirstClick[buttonIndex]
				_hasIgnoredFirstClick[buttonIndex] = True
				'Print Time.GetTimeGone() + "      click => ignored first click"
			Else

				' check for a long click
				If _longClickModeEnabled And _downTime[buttonIndex] + longClickMinTime < t
					_AddClickStackEntry(button, CLICKTYPE_LONGCLICK, currentPosVec.Copy(), t)

					'emulating right click?
					If _longClickLeadsToRightClick And button = 1
						_AddClickStackEntry(2, CLICKTYPE_CLICK, currentPosVec.Copy(), t)
						_downTime[2] = _downTime[1]
					EndIf

					'Print Time.GetTimeGone() + "      click => long clicked    downTime="+_downTime[button] +"  longClickMinTime="+longClickMinTime +"   button="+button

				' normal click + double clicks
				Else
					Print Time.GetTimeGone() + "    down => up => click   GetClicks( " + button + ")=" + GetClicks(button) + " _clicksInDoubleClickTimeCount["+buttonIndex+"]="+_clicksInDoubleClickTimeCount[buttonIndex]

					_AddClickStackEntry(button, CLICKTYPE_CLICK, currentPosVec.Copy(), t)

					'double clicks (additionally to normal clicks!)
					If _clicksInDoubleClickTimeCount[buttonIndex] >= 2
						_AddClickStackEntry(button, CLICKTYPE_DOUBLECLICK, currentPosVec.Copy(), t)

						_clicksInDoubleClickTimeCount[buttonIndex] :- 2
					EndIf
				EndIf
			EndIf

			'reset mousedown time - no longer happening
			_downTime[buttonIndex] = 0
			_down[buttonIndex] = False
		EndIf
	End Method
EndType




'record for each single click
Type TMouseManagerClick
	Field clickType:Int = 1
	Field position:TVec2D
	Field t:Long

	Method Init:TMouseManagerClick(clickType:Int, position:TVec2D, clickTime:Long = -1)
		If clickTime = -1 Then clickTime = Time.GetAppTimeGone()
		Self.clickType = clickType
		Self.position = position
		Self.t = clickTime
		Return Self
	End Method
End Type




Type TKeyManager
	'status of all keys
	Field _keyStatus:Int[256]
	Field _blockKeyTime:Long[256]

	Global processedAppSuspend:Int = False


	'returns whether the button is in normal state
	Method isNormal:Int(key:Int)
		Return _keyStatus[Key] = KEY_STATE_NORMAL
	End Method


	'returns whether the button is currently blocked
	Method isBlocked:Int(key:Int)
		'this time it is a bitmask flag (normal/hit/.. + blocked)
		Return _keyStatus[key] & KEY_STATE_BLOCKED
	End Method


	'returns whether the button is in hit state
	Method isHit:Int(key:Int)
		Return _keyStatus[key] = KEY_STATE_HIT
	End Method


	'returns whether the button is in down state
	Method isDown:Int(key:Int)
		Return _keyStatus[key] = KEY_STATE_DOWN
	End Method


	'returns whether the button is in up state
	Method isUp:Int(key:Int)
		Return _keyStatus[key] = KEY_STATE_UP
	End Method


	'refresh all key states
	Method Update:Int()
		If AppSuspended()
			If Not processedAppSuspend
				FlushKeys()
				processedAppSuspend = True
			EndIf
		ElseIf processedAppSuspend
			processedAppSuspend = False
		EndIf


		Local time:Long = Time.GetAppTimeGone()
		For Local i:Int = 1 To 255
			'ignore key if it is blocked
			'or set back to "normal" afterwards
			If _blockKeyTime[i] > time
				_keyStatus[i] :| KEY_STATE_BLOCKED
			ElseIf isBlocked(i)
				_keyStatus[i] :& ~KEY_STATE_BLOCKED
'				'meanwhile a hit can get renewed
				If _keyStatus[i] = KEY_STATE_HIT
					_keyStatus[i] = KEY_STATE_NORMAL
				EndIf
			EndIf

			'normal check
			If _keyStatus[i] = KEY_STATE_NORMAL
				If KeyDown(i) Then _keyStatus[i] = KEY_STATE_HIT
			ElseIf _keyStatus[i] = KEY_STATE_HIT
				If KeyDown(i) Then _keyStatus[i] = KEY_STATE_DOWN Else _keyStatus[i] = KEY_STATE_UP
			ElseIf _keyStatus[i] = KEY_STATE_DOWN
				If Not KeyDown(i) Then _keyStatus[i] = KEY_STATE_UP
			ElseIf _keyStatus[i] = KEY_STATE_UP
				_keyStatus[i] = KEY_STATE_NORMAL
			EndIf
		Next
	End Method



	'returns the status of a key
	Method getStatus:Int(key:Int)
		Return _keyStatus[key]
	End Method


	'set a key as blocked for the given time
	Method blockKey:Int(key:Int, milliseconds:Int=0)
		'time can be absolute as a key block is just for blocking a key
		'which has not to be deterministic
		_blockKeyTime[key] = Time.GetAppTimeGone() + milliseconds
		'also add the block state to the  current status
		_keyStatus[key] :| KEY_STATE_BLOCKED
	End Method


	'resets the keys status
	Method resetKey:Int(key:Int)
		_keyStatus[key] = KEY_STATE_UP
		Return KEY_STATE_UP
	End Method
EndType




Const KEYWRAP_ALLOW_HIT:Int	= 1
Const KEYWRAP_ALLOW_HOLD:Int= 2
Const KEYWRAP_ALLOW_BOTH:Int= 3


Type TKeyWrapper
	Rem
		0 - --
		1 - time to wait to get "hold" state after "hit"
		2 - time to wait for next "hold" after "hold"
		3 - total time till next hold
	EndRem
	Field _keySet:Long[256, 4]


	Method allowKey(key:Int, rule:Int=KEYWRAP_ALLOW_BOTH, hitTime:Int=600, holdtime:Int=100)
		_keySet[key, 0] = rule
		If rule & KEYWRAP_ALLOW_HIT Then _keySet[key, 1] = hitTime

		If rule & KEYWRAP_ALLOW_HOLD Then _keySet[key, 2] = holdTime
	End Method


	Method pressedKey:Int(key:Int, keyState:Int=-1)
		If keyState = -1 Then keyState = KEYMANAGER.getStatus(key)
		Local rule:Int = _keySet[key, 0]

		If keyState = KEY_STATE_NORMAL Or keyState = KEY_STATE_UP Then Return False
		If keyState & KEY_STATE_BLOCKED Then Return False

		'Muss erlaubt und aktiv sein
		If rule & KEYWRAP_ALLOW_HIT And keyState = KEY_STATE_HIT
			Return hitKey(key, keyState)
		ElseIf rule & KEYWRAP_ALLOW_HOLD
			Return holdKey(key, keyState)
		EndIf
		Return False
	End Method


	Method hitKey:Int(key:Int, keyState:Int=-1)
		If keyState = -1 Then keyState = KEYMANAGER.getStatus(key)
		If keyState <> KEY_STATE_HIT Then Return False

		'Muss erlaubt und aktiv sein
		If _keySet[key, 0] & KEYWRAP_ALLOW_HIT
			'Zeit bis man Taste halten darf
			_keySet[key, 3] = Time.GetAppTimeGone() + _keySet[key, 1]
			Return True
		EndIf
		Return False
	End Method


	Method holdKey:Int(key:Int, keyState:Int=-1)
		If keyState = -1 Then keyState = KEYMANAGER.getStatus(key)
		If keyState = KEY_STATE_NORMAL Or keyState = KEY_STATE_UP Then Return False
		If keyState & KEY_STATE_BLOCKED Then Return False

		If _keySet[key, 0] & KEYWRAP_ALLOW_HOLD
			'time which has to be gone until hold is set
			Local holdTime:Long = _keySet[key, 3]
			If Time.GetAppTimeGone() > holdTime
				'refresh time until next "hold"
				_keySet[key, 3] = Time.GetAppTimeGone() + _keySet[key, 2]
				Return True
			EndIf
		EndIf
		Return False
	End Method


	Method resetKey(key:Int)
		_keySet[key, 0] = 0
		_keySet[key, 1] = 0
		_keySet[key, 2] = 0
		_keySet[key, 3] = 0
	End Method
End Type