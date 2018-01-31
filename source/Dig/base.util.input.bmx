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

	Copyright (C) 2002-2017 Ronny Otto, digidea.de

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


Rem
	Hint:
	"hit":   the button was down and is now released
	"click": the button was hit and the waiting time for another
	         hit is gone now.
	This means: if you tap tap tap tap on your mouse button, you
	            generate "hits". If you then wait a certain amount of time
	            (eg. 100 ms) all your last hits get converted to "clicks".
	            A "tap tap tap" therefor is no "click" and also no
	            "doubleclick" (in this case "GetClicks()" returns 3 so you
	            might call it "tripleClick" :D).
End Rem
Type TMouseManager
	Field lastPos:TVec2D = New TVec2D.Init(0,0)
	Field currentPos:TVec2D = New TVec2D.Init(0,0)
	Field x:Float = 0.0
	Field y:Float = 0.0
	Field lastScrollWheel:Int = 0

	'amount of pixels moved (0=zero, -upwards, +downwards)
	Field scrollWheelMoved:Int = 0
	'position at the screen when a button was "HIT"
	Field _hitPosition:TVec2D[4]
	Field _lastHitPosition:TVec2D[4]
	'position at the screen when a button was "CLICKED"
	'(first click in a series)
	Field _clickPosition:TVec2D[4]
	'current status of the buttons
	Field _keyStatus:Int[] = [0,0,0,0]
	'time since when the button is pressed
	Field _keyDownTime:Long[] = [0:Long,0:Long,0:Long,0:Long]
	'time when the button was last hit
	Field _keyHitTime:Long[]	= [0:Long,0:Long,0:Long,0:Long]
	'amount of hits until "doubleClickTime" was over without another hit
	Field _keyHitCount:Int[] = [0,0,0,0]
	'amount of clicks (hits until doubleClickTime was over)
	Field _keyClickCount:Int[] = [0,0,0,0]
	'boolean if the button was clicked since last update (mouseup after
	'a "hit")
	Field _keyClicked:Int[] = [0,0,0,0]
	'boolean if the button was clicked since last update (mouseup after
	'a "hit") AND was down for a longer period (-> touch screen handling)
	Field _keyLongClicked:Int[] = [0,0,0,0]
	'time (in ms) to wait for another click to recognize doubleclicks
	'so it is also the maximum time "between" that needed two clicks
	Field _doubleClickTime:Int = 250
	Field _longClickTime:Int = 400

	'TOUCH emulation
	Field _longClickModeEnabled:Int = True
	Field _ignoreFirstClick:Int = False 'skip first click (touch screens)
	Field _hasIgnoredFirstClick:Int[] = [0,0,0,0] 'currently ignoring?
	'distance in pixels, if mouse moved further away, the next
	'click will get ignored ("tap")
	Field _minSwipeDistance:Int = 10

	'can clicks/hits get read?
	'special info read is possible (IsDown(), IsUp())
	Field _enabled:Int[] = [True, True, True, True]

	Global processedAppSuspend:Int = False


	Method GetButtonCount:Int()
		Return _keyStatus.length
	End Method


	'reset the state of the given button
	Method ResetKey:Int(key:Int)
		_keyDownTime[key] = 0
		_keyHitTime[key] = 0
		_keyStatus[key] = KEY_STATE_NORMAL
		_keyHitCount[key] = 0
		_keyClickCount[key] = 0
		_hitPosition[key] = Null
		_clickPosition[key] = Null
		ResetClicked(key)
		Return KEY_STATE_UP
	End Method


	Method ResetClicked(key:Int)
		_keyClicked[key] = 0
		_keyLongClicked[key] = 0
	End Method


	Method ResetLongClicked(key:Int, resetTime:Int=False)
		_keyLongClicked[key] = 0
		If resetTime Then _keyHitTime[key] = 0
	End Method


	Method Disable(key:Int)
		_enabled[key] = False
	End Method


	Method Enable(key:Int)
		_enabled[key] = True
	End Method


	'returns whether the button is in normal state
	Method isNormal:Int(key:Int)
		Return _keyStatus[key] = KEY_STATE_NORMAL
	End Method


	'returns whether the button is in hit state
	Method isHit:Int(key:Int)
		If Not _enabled[key] Then Return False

		Return _keyStatus[key] = KEY_STATE_HIT
	End Method


	'returns whether the button was clicked 2 times
	'strictMode defines whether more than 2 clicks also count
	'as "double click"
	'includes waiting time
	Method isDoubleClicked:Int(key:Int, strictMode:Int=True)
		If Not _enabled[key] Then Return False
		
		If strictMode
			Return GetClicks(key) = 2
		Else
			Return GetClicks(key) > 2
		EndIf
	EndMethod


	'returns whether the button is in clicked state
	'includes waiting time
	Method isSingleClicked:Int(key:Int)
		If Not _enabled[key] Then Return False

		Return GetClicks(key) = 1
	End Method


	'returns whether the button got clicked, no waiting time
	'is added
	Method isClicked:Int(key:Int)
		If Not _enabled[key] Then Return False

		If Not _keyClicked[key]
			Return False
		Else
			Return _keyStatus[key] = KEY_STATE_NORMAL And (_keyHitCount[key] > 0)
		EndIf
	End Method


	Method isShortClicked:Int(key:Int)
		Return isClicked(key) And Not isLongClicked(key)
	End Method


	'returns whether the button got clicked, no waiting time
	'is added. Button needs to have been down for a while
	Method isLongClicked:Int(key:Int)
		If Not _longClickModeEnabled Then Return False
		If Not _enabled[key] Then Return False

		If Not _keyLongClicked[key]
			Return False
		Else
			Return _keyStatus[key] = KEY_STATE_NORMAL And (_keyHitCount[key] > 0)
		EndIf
	End Method


	'returns whether the button is in down state
	Method isDown:Int(key:Int)
		'currently ignoring the key?
		If _ignoreFirstClick And Not _hasIgnoredFirstClick[key] Then Return False

		Return _keyStatus[key] = KEY_STATE_DOWN
	End Method


	'returns whether the button is in up state
	Method isUp:Int(key:Int)
		Return _keyStatus[key] = KEY_STATE_UP
	End Method


	Method HasMoved:Int()
		Return (0 = GetMovedDistance())
	End Method


	Method GetMovedDistance:Int()
		Return Sqr((lastPos.X - Int(x))^2 + (lastPos.y - Int(y))^2)
	End Method


	Method GetClickPosition:TVec2D(key:Int)
		Return _clickPosition[key]
	End Method


	Method GetHitPosition:TVec2D(key:Int)
		Return _hitPosition[key]
	End Method


	Method GetPosition:TVec2D()
		Return currentPos
	End Method


	Method GetX:Float()
		Return currentPos.x
	End Method


	Method GetY:Float()
		Return currentPos.y
	End Method
	

	'returns how many milliseconds a button is down
	Method GetDownTime:Long(key:Int)
		If _keyDownTime[key] > 0
			Return Time.GetAppTimeGone() - _keyDownTime[key]
		Else
			Return 0
		EndIf
	End Method


	'returns positive or negative value describing the movement
	'of the scrollwheel
	Method GetScrollwheelMovement:Int()
		Return scrollWheelMoved
	End Method


	'returns the status of a button
	Method GetStatus:Int(key:Int)
		Return _keyStatus[key]
	End Method


	'returns the amount of clicks
	Method GetClicks:Int(key:Int)
		'there still may come other hits... after then we know
		'the real amount of clicks
		If _keyHitTime[key] > 0 Then Return 0
		Return _keyHitCount[key]
	End Method


	'returns array of bools describing down state of each button
	Method GetAllStatusDown:Int[]()
		Return [False,..
		        IsDown(1),..
		        IsDown(2),..
		        IsDown(3)..
		        ]
	End Method


	'returns array of bools describing hit/doublehit state of each button
	Method GetAllStatusHit:Int[]()
		Return [False,..
		        _keyStatus[1] = (KEY_STATE_HIT),..
		        _keyStatus[2] = (KEY_STATE_HIT),..
		        _keyStatus[3] = (KEY_STATE_HIT)..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllStatusClicked:Int[]()
		Return [False,..
		        isClicked(1),..
		        isClicked(2),..
		        isClicked(3)..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllStatusLongClicked:Int[]()
		Return [False,..
		        isLongClicked(1),..
		        isLongClicked(2),..
		        isLongClicked(3)..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllStatusDoubleClicked:Int[]()
		Return [False,..
		        isDoubleClicked(1),..
		        isDoubleClicked(2),..
		        isDoubleClicked(3)..
		       ]
	End Method


	Method UpdateKey:Int(i:Int)
		'reset hit count if there is no hit time (which means: waited
		'long enough for another hit)
		'-> if the hit evolved into a click, this should have been
		'handled already after the last call of UpdateKey()
		If _keyHitTime[i] = 0
			_keyHitCount[i] = 0
			'reset clickposition ()
			_clickPosition[i] = Null
			_hitPosition[i] = Null
		EndIf
		
		'set to non-clicked - for "isClicked()"
		_keyClicked[i] = False
		_keyLongClicked[i] = False

		If _keyStatus[i] = KEY_STATE_NORMAL
			If MouseHit(i)
				_keyStatus[i] = KEY_STATE_HIT
				'also store the position of this hit (and backup before)
				If _hitPosition[i]
					_lastHitPosition[i] = _hitPosition[i]
				Else
					_lastHitPosition[i] = New TVec2D.Init(x, y)
				EndIf
				_hitPosition[i] = New TVec2D.Init(x, y)
			EndIf
		ElseIf _keyStatus[i] = KEY_STATE_HIT
			If MouseDown(i) Then _keyStatus[i] = KEY_STATE_DOWN Else _keyStatus[i] = KEY_STATE_UP
		ElseIf _keyStatus[i] = KEY_STATE_DOWN
			If Not MouseDown(i) Then _keyStatus[i] = KEY_STATE_UP
		ElseIf _keyStatus[i] = KEY_STATE_UP
			'ignore this click if it is the first one
			If _ignoreFirstClick And Not _hasIgnoredFirstClick[i]
				_hasIgnoredFirstClick[i] = True
				'reset hit time to avoid accidental double click recognition
				_keyHitTime[i] = 0
			Else
				_keyClicked[i] = True

				'store the position of the first click
				If _clickPosition[i] = Null
					_clickPosition[i] = New TVec2D.Init(x,y)
				EndIf

				If _longClickModeEnabled
					If _keyHitTime[i] <> 0 And _keyHitTime[i] + _longClickTime < Time.GetAppTimeGone()
						_keyLongClicked[i] = True
					EndIf
				EndIf
			EndIf
			_keyStatus[i] = KEY_STATE_NORMAL
		EndIf


		'=== MOUSE HIT/CLICK COUNTER ====
		'hit means: button was DOWN and is now UP
		If _keyStatus[i] = KEY_STATE_HIT
			'if not _hasIgnoredFirstClick[i]
				'increase hit count of this button
				_keyHitCount[i] :+1

				'refresh hit time - so we wait for more hits
				'-> time gone -> "click" happened
				_keyHitTime[i] = Time.GetAppTimeGone()
			'endif
		EndIf


		'mouse is normal and was hit at least once
		'-> check if this are "clicks" or still "hits"
		If _keyStatus[i] = KEY_STATE_NORMAL And _keyHitCount[i] > 0
			'waited long enough for another hit?
			If _keyHitTime[i] + _doubleClickTime < Time.GetAppTimeGone()
				'reset hit time - indicator that "waiting is over"
				_keyHitTime[i] = 0
			EndIf
		EndIf


		'=== MOUSE DOWN TIME ====
		'store mousedown time ... someone may need this measurement
		If MouseDown(i)
			If Not _hasIgnoredFirstClick[i]
				'store time when first mousedown happened
				If _keyDownTime[i] = 0 Then _keyDownTime[i] = Time.GetAppTimeGone()
			EndIf
		Else
			'reset time - mousedown no longer happening
			_keyDownTime[i] = 0
		EndIf
	End Method


	'Update the button states
	Method Update:Int()
		If AppSuspended()
			If Not processedAppSuspend
				FlushMouse()
				lastScrollWheel = MouseZ()
				For Local i:Int = 1 To 3
					ResetKey(i)
				Next
				processedAppSuspend = True
			EndIf
		ElseIf processedAppSuspend
			processedAppSuspend = False
		EndIf


		'by default scroll wheel did not move
		scrollWheelMoved = 0

		If lastScrollWheel <> MouseZ()
			scrollWheelMoved = lastScrollWheel - MouseZ()
			lastScrollWheel = MouseZ()
		EndIf

		x = TVirtualGfx.getInstance().VMouseX()
		y = TVirtualGfx.getInstance().VMouseY()


		'check if we moved far enough to recognize swipe..
		If _ignoreFirstClick
			'moved a bigger distance - "swiped" ?
			For Local i:Int = 0 Until _keyStatus.length
				If Not _hasIgnoredFirstClick[i] Then Continue
				If Not _lastHitPosition[i] Then Continue
				'if isDown(i) then continue

				If Sqr((x - _lastHitPosition[i].x)^2 + (y - _lastHitPosition[i].y)^2) > _minSwipeDistance
					_hasIgnoredFirstClick[i] = False
				EndIf
			Next
		EndIf

		currentPos.x = x
		currentPos.y = y

		For Local i:Int = 1 To 3
			UpdateKey(i)
		Next

		lastPos.SetXY(x, y)
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