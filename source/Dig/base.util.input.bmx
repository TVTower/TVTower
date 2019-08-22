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
	'position at the screen when a button was "CLICKED"
	Field _clickPosition:TVec2D[4]
	'previous position at the screen when a button was "CLICKED" last time
	Field _previousClickPosition:TVec2D[4]
	'time when the button was last clicked
	Field _clickTime:Long[] = [0:Long,0:Long,0:Long,0:Long]
	Field _doubleClickTime:Long[] = [0:Long,0:Long,0:Long,0:Long]
	Field _longClickTime:Long[] = [0:Long,0:Long,0:Long,0:Long]
	'amount of clicks since last reset
	Field _clickCount:Int[] = [0,0,0,0]
	Field _doubleClickCount:Int[] = [0,0,0,0]
	Field _longClickCount:Int[] = [0,0,0,0]
	'store clicks in the doubleclick timespan to identify double clicks
	Field _clicksInDoubleClickTimeCount:Int[] = [0,0,0,0]

	'down or not?
	Field _down:Int[] = [0,0,0,0]
	'time since when the button was pressed last
	Field _downTime:Long[] = [0:Long,0:Long,0:Long,0:Long]
	'can clicks/hits get read?
	'special info read is possible (IsDown(), IsNormal())
	Field _enabled:Int[] = [True, True, True, True]


	'TOUCH emulation
	Field _longClickModeEnabled:Int = True
	Field _longClickLeadsToRightClick:Int = True
	'skip first click (touch screens)
	Field _ignoreFirstClick:Int = False
	Field _hasIgnoredFirstClick:Int[] = [0,0,0,0] 'currently ignoring?
	'distance in pixels, if mouse moved further away, the next
	'click will get ignored ("tap")
	Field _minSwipeDistance:Int = 10


	Global evMouseDown:Int[4]
	Global evMouseHits:Int[4]
	Global evMousePos:Int[2]
	Global evMouseZ:Int


	'handle all incoming input events
	Function InputHook:Object( id:Int, data:Object, context:Object )
		Local ev:TEvent = TEvent(data)
		If Not ev Return data

		'filter by source?
		'If ev.source = ... Return data

		Select ev.id
			Case EVENT_MOUSEDOWN
				If Not evMouseDown[ev.data]
					evMouseDown[ev.data] = 1
					evMouseHits[ev.data] :+ 1
				EndIf
				MouseManager._HandleButtonEvent(ev.data)
			Case EVENT_MOUSEUP
				evMouseDown[ev.data] = 0
				MouseManager._HandleButtonEvent(ev.data)
			Case EVENT_MOUSEMOVE
				evMousePos[0] = ev.x
				evMousePos[1] = ev.y
			Case EVENT_MOUSEWHEEL
				evMouseZ :+ ev.data
			Case EVENT_APPSUSPEND, EVENT_APPRESUME
				evMouseDown = New Int[4] 'flush
				evMouseHits = New Int[4] 'flush
				evMouseZ = 0'flush
		End Select

		Return data
	End Function


	'return amount of handled buttons
	Method GetButtonCount:Int()
		Return _down.length-1 'ignore 0
	End Method


	'reset the state of the given button
	Method ResetKey:Int(key:Int)
		_downTime[key] = 0
		_down[key] = False
		_clickTime[key] = 0
		_clickPosition[key] = Null
		_doubleClickTime[key] = 0
		_longClickTime[key] = 0

		ResetClicked(key)
		Return KEY_STATE_NORMAL
	End Method


	Method ResetClicked(key:Int)
		_clickCount[key] = 0
		_doubleClickCount[key] = 0
		_longClickCount[key] = 0

		'reset emulated right clicks
		if _longClickModeEnabled and _longClickLeadsToRightClick and key = 2
			_longClickCount[1] = 0
		endif
	End Method


	Method ResetDoubleClicked(key:Int, resetTime:Int=False)
		_doubleClickCount[key] = 0
		If resetTime Then _doubleClickTime[key] = 0
	End Method


	Method ResetLongClicked(key:Int, resetTime:Int=False)
		_longClickCount[key] = 0
		If resetTime Then _longClickTime[key] = 0
	End Method


	Method Disable(key:Int)
		_enabled[key] = False
	End Method


	Method Enable(key:Int)
		_enabled[key] = True
	End Method


	Method IsEnabled:Int(key:Int)
		return _enabled[key]
	End Method


	'returns whether the button is in normal state
	Method IsNormal:Int(key:Int)
		'currently ignoring the key?
		If _ignoreFirstClick And Not _hasIgnoredFirstClick[key] Then Return True

		Return not _down[key]
	End Method


	'returns whether the button is in down state
	Method isDown:Int(key:Int)
		'currently ignoring the key?
		If _ignoreFirstClick And Not _hasIgnoredFirstClick[key] Then Return False

		Return _down[key]
	End Method


	'returns whether the button got clicked, no waiting time
	'is added
	Method IsClicked:Int(key:Int)
		If Not _enabled[key] Then Return False

		return _clickCount[key] > 0
	End Method


	'returns whether the button was clicked 2 times
	'strictMode defines whether more than 2 clicks also count
	'as "double click"
	'includes waiting time
	Method IsDoubleClicked:Int(key:Int)
		If Not _enabled[key] Then Return False

		return _doubleClickCount[key] > 0
	EndMethod


rem
	'returns whether the button was single (guaranteed no double) clicked
	Method IsSingleClicked:Int(key:Int)
		If Not _enabled[key] Then Return False

		Return _singleClickCount[key]
	End Method
endrem


	'returns whether the button got "long clicked"
	'(Button needs to have been down for a while)
	Method IsLongClicked:Int(key:Int)
		If Not _longClickModeEnabled Then Return False
		If Not _enabled[key] Then Return False

		Return _longClickCount[key] > 0
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


	Method GetMovedDistanceSinceClick:Int(button:int)
		if not _clickPosition[button] then return 0
		Return Sqr((_clickPosition[button].x - Int(x))^2 + (_clickPosition[button].y - Int(y))^2)
	End Method


	Method GetMovedDistanceBetweenClicks:Int(button:int)
		if not _previousClickPosition[button] then return 0
		if not _clickPosition[button] then return 0
		Return Sqr((_previousClickPosition[button].x - _ClickPosition[button].x)^2 + (_previousClickPosition[button].y - _clickPosition[button].y)^2)
	End Method


	Method GetClickPosition:TVec2D(key:Int)
		Return _clickPosition[key]
	End Method


	Method GetPosition:TVec2D()
		Return currentPos
	End Method


	Method GetX:Int()
		Return int(currentPos.x)
	End Method


	Method GetY:Int()
		Return int(currentPos.y)
	End Method


	'returns how many milliseconds a button is down
	Method GetDownTime:Long(key:Int)
		If _downTime[key] > 0
			Return Time.GetAppTimeGone() - _downTime[key]
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
	Method GetClicks:Int(key:Int)
		Return _clickCount[key]
	End Method


	'returns the amount of double clicks
	Method GetDoubleClicks:Int(key:Int)
		Return _doubleClickCount[key]
	End Method


	'returns the amount of long clicks
	Method GetLongClicks:Int(key:Int)
		Return _longClickCount[key]
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
	Method GetAllIsLongClicked:Int[]()
		Return [False,..
		        IsLongClicked(1), ..
		        IsLongClicked(2), ..
		        IsLongClicked(3) ..
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


	'-----


	'Update the button states
	Method Update:Int()
		'SCROLLWHEEL
		'by default scroll wheel did not move
		scrollWheelMoved = 0

		If _lastScrollWheel <> evMouseZ
			scrollWheelMoved = _lastScrollWheel - evMouseZ
			_lastScrollWheel = evMouseZ
		EndIf


		'POSITION
		'store last position
		_lastPos.SetXY(x, y)
		'update current position
		x = TVirtualGfx.getInstance().VMouseX()
		y = TVirtualGfx.getInstance().VMouseY()
		currentPos.x = x
		currentPos.y = y


		'GESTURES
		For Local i:Int = 1 To 3
			'check if we moved far enough to recognize swipe..
			If _ignoreFirstClick then _CheckSwipe(i)
		Next

	End Method


	'=== INTERNAL ===


	'called on incoming OS mouse events
	Method _HandleButtonEvent:Int(button:Int)
		'press (from "up" to "down")
		If evMouseDown[button] And not _down[button]
			if not _enabled[button] then return False

			'Print Time.GetTimeGone() + "  normal => down"
			_down[button] = true
			_downTime[button] = Time.GetAppTimeGone()

			'store mousedown time ... someone may need this measurement
			If Not _hasIgnoredFirstClick[button]
				'store time when first mousedown happened
				if _clickCount[button] = 0 then _downTime[button] = Time.GetAppTimeGone()
			EndIf
		EndIf


		'release -> click (from down to up)
		If Not evMouseDown[button] And _down[button]

			if not _enabled[button]
				'if not enabled we still return to "NORMAL" and are no longer
				'down but do not count the hit/click
				_downTime[button] = 0
				_down[button] = false
				return False
			endif

			local t:Long = Time.GetAppTimeGone()
			local timeSinceLastClick:int = t - _clickTime[button]
			if timeSinceLastClick < doubleClickMaxTime
				_clicksInDoubleClickTimeCount[button] :+ 1
				'Print Time.GetTimeGone() + "    down => up => click within doubleclick time    clicks=" + (_clicksInDoubleClickTimeCount[button])
			else
				_clicksInDoubleClickTimeCount[button] = 1
			endif


			'- Ignore first click?
			'- Long click?
			'- Normal click + Double clicks?

			'ignore this potential click if it is the first one
			If _ignoreFirstClick And Not _hasIgnoredFirstClick[button]
				_hasIgnoredFirstClick[button] = True
				_clickTime[button] = 0
				'Print Time.GetTimeGone() + "      click => ignored first click"

			' check for a long click
			ElseIf _longClickModeEnabled And _downTime[button] + longClickMinTime < t
				_longClickTime[button] = t
				_longClickCount[button] :+ 1

				'emulating right click?
				if _longClickLeadsToRightClick and button = 1
					_clickCount[2] :+ 1
					_clickPosition[2] = _clickPosition[1]
					_downTime[2] = _downTime[1]
				endif

				'Print Time.GetTimeGone() + "      click => long clicked    downTime="+_downTime[button] +"  longClickMinTime="+longClickMinTime +"   button="+button

			' normal click + double clicks
			Else
				'Print Time.GetTimeGone() + "    down => up => click   clicks["+button+"]=" + (_clickCount[button]+1)
				'store click time
				_clickTime[button] = t

				'increase click count of this button
				_clickCount[button] :+ 1

				'also store the position of this click
				'(and backup before - null if not existing!)
				_previousClickPosition[button] = _clickPosition[button]
				_clickPosition[button] = New TVec2D.Init(x, y)


				'double clicks (additionally to normal clicks!)
				if _clicksInDoubleClickTimeCount[button] >= 2
					'Print Time.GetTimeGone() + "    down => up => click + click => double click    clicks=" + (_doubleClickCount[button] + 1)
					_doubleClickTime[button] = t
					_doubleClickCount[button] :+ 1
					_clicksInDoubleClickTimeCount[button] :- 2
				endif
			EndIf

			'reset mousedown time - no longer happening
			_downTime[button] = 0
			_down[button] = false
		EndIf
	End Method



	Method _CheckSwipe:Int(button:int)
		'moved a bigger distance - "swiped" ?
		For Local i:Int = 1 to _down.length
			If Not _hasIgnoredFirstClick[i] Then Continue

			If GetMovedDistanceBetweenClicks(i) > _minSwipeDistance
				_hasIgnoredFirstClick[i] = False
				_clickPosition[i] = null
			EndIf
		Next
	End Method
EndType




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