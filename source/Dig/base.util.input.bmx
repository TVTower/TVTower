REM
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

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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
Import "base.util.point.bmx"
Import "base.util.time.bmx"

Global MOUSEMANAGER:TMouseManager = New TMouseManager
Global KEYMANAGER:TKeyManager = New TKeyManager
Global KEYWRAPPER:TKeyWrapper = New TKeyWrapper


Const KEY_STATE_NORMAL:int			= 0	'nothing done
Const KEY_STATE_HIT:int				= 1	'once dow, now up
Const KEY_STATE_DOWN:int			= 2 'down
Const KEY_STATE_UP:int				= 3 'up
Const KEY_STATE_BLOCKED:int			= 6

For local i:int = 0 To 255
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
	Field lastPos:TPoint = new TPoint
	Field x:float = 0.0
	Field y:float = 0.0

	'amount of pixels moved (0=zero, -upwards, +downwards)
	Field scrollWheelMoved:int = 0
	'current status of the buttons
	Field _keyStatus:Int[] = [0,0,0,0]
	'time since when the button is pressed
	Field _keyDownTime:Int[] = [0,0,0,0]
	'time when the button was last hit
	Field _keyHitTime:Int[]	= [0,0,0,0]
	'amount of hits until "doubleClickTime" was over without another hit
	Field _keyHitCount:Int[] = [0,0,0,0]
	'amount of clicks (hits until doubleClickTime was over)
	Field _keyClickCount:Int[] = [0,0,0,0]
	'boolean if the button was clicked since last update (mouseup after
	'a "hit")
	Field _keyClicked:Int[] = [0,0,0,0]
	'time (in ms) to wait for another click to recognize doubleclicks
	'so it is also the maximum time "between" that needed two clicks
	Field _doubleClickTime:int = 250



	'reset the state of the given button
	Method ResetKey:Int(key:Int)
		_keyDownTime[key] = 0
		_keyHitTime[key] = 0
		_keyStatus[key] = KEY_STATE_NORMAL
		_keyHitCount[key] = 0
		_keyClickCount[key] = 0
		ResetClicked(key)
		Return KEY_STATE_UP
	End Method


	Method ResetClicked(key:int)
		_keyClicked[key] = 0
	End Method


	'returns whether the button is in normal state
	Method isNormal:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_NORMAL
	End Method


	'returns whether the button is in hit state
	Method isHit:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_HIT
	End Method


	'returns whether the button was clicked 2 times
	'strictMode defines whether more than 2 clicks also count
	'as "double click"
	'includes waiting time
	Method isDoubleClicked:Int(key:Int, strictMode:int=TRUE)
		if strictMode
			return GetClicks(key) = 2
		else
			return GetClicks(key) > 2
		endif
	EndMethod


	'returns whether the button is in clicked state
	'includes waiting time
	Method isSingleClicked:Int(key:Int)
		return GetClicks(key) = 1
	End Method


	'returns whether the button got clicked, no waiting time
	'is added
	Method isClicked:Int(key:Int)
		if not _keyClicked[key]
			return false
		else
			return _keyStatus[key] = KEY_STATE_NORMAL and (_keyHitCount[key] > 0)
		endif
	End Method


	'returns whether the button is in down state
	Method isDown:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_DOWN
	End Method


	'returns whether the button is in up state
	Method isUp:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_UP
	End Method


	Method HasMoved:int()
		return (0 = GetMovedDistance())
	End Method


	Method GetMovedDistance:int()
		Return sqr((lastPos.X - int(x))^2 + (lastPos.y - int(y))^2)
	End Method


	'returns how many milliseconds a button is down
	Method GetDownTime:Int(key:Int)
		If _keyDownTime[key] > 0
			return Time.GetTimeGone() - _keyDownTime[key]
		else
			return 0
		endif
	End Method


	'returns positive or negative value describing the movement
	'of the scrollwheel
	Method GetScrollwheelMovement:int()
		return scrollWheelMoved
	End Method


	'returns the status of a button
	Method GetStatus:Int(key:Int)
		Return _keyStatus[key]
	End Method


	'returns the amount of clicks
	Method GetClicks:int(key:int)
		'there still may come other hits... after then we know
		'the real amount of clicks
		if _keyHitTime[key] > 0 then return 0
		return _keyHitCount[key]
	End Method


	'returns array of bools describing down state of each button
	Method GetAllStatusDown:int[]()
		return [false,..
		        _keyStatus[1] = KEY_STATE_DOWN,..
		        _keyStatus[2] = KEY_STATE_DOWN,..
		        _keyStatus[3] = KEY_STATE_DOWN..
		        ]
	End Method


	'returns array of bools describing hit/doublehit state of each button
	Method GetAllStatusHit:int[]()
		return [false,..
		        _keyStatus[1] = (KEY_STATE_HIT),..
		        _keyStatus[2] = (KEY_STATE_HIT),..
		        _keyStatus[3] = (KEY_STATE_HIT)..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllStatusClicked:int[]()
		return [false,..
		        isClicked(1),..
		        isClicked(2),..
		        isClicked(3)..
		       ]
	End Method


	'returns array of bools describing clicked state of each button
	Method GetAllStatusDoubleClicked:int[]()
		return [false,..
		        isDoubleClicked(1),..
		        isDoubleClicked(2),..
		        isDoubleClicked(3)..
		       ]
	End Method


	Method UpdateKey:int(i:int)
		'reset hit count if there is no hit time (which means: waited
		'long enough for another hit)
		'-> if the hit evolved into a click, this should have been
		'handled already after the last call of UpdateKey()
		if _keyHitTime[i] = 0 then _keyHitCount[i] = 0

		'set to non-clicked - for "isClicked()"
		_keyClicked[i] = false

		If _keyStatus[i] = KEY_STATE_NORMAL
			If MouseHit(i) then _keyStatus[i] = KEY_STATE_HIT
		ElseIf _keyStatus[i] = KEY_STATE_HIT
			If MouseDown(i) Then _keyStatus[i] = KEY_STATE_DOWN Else _keyStatus[i] = KEY_STATE_UP
		ElseIf _keyStatus[i] = KEY_STATE_DOWN
			If Not MouseDown(i) Then _keyStatus[i] = KEY_STATE_UP
		ElseIf _keyStatus[i] = KEY_STATE_UP
			_keyClicked[i] = True
			_keyStatus[i] = KEY_STATE_NORMAL
		EndIf


		'=== MOUSE HIT/CLICK COUNTER ====
		'hit means: button was DOWN and is now UP
		If _keyStatus[i] = KEY_STATE_HIT
			'increase hit count of this button
			_keyHitCount[i] :+1

			'refresh hit time - so we wait for more hits
			'-> time gone -> "click" happened
			_keyHitTime[i] = Time.GetTimeGone()
		endif

		'mouse is normal and was hit at least once
		'-> check if this are "clicks" or still "hits"
		If _keyStatus[i] = KEY_STATE_NORMAL and _keyHitCount[i] > 0
			'waited long enough for another hit?
			if _keyHitTime[i] + _doubleClickTime < Time.GetTimeGone()
				'reset hit time - indicator that "waiting is over"
				_keyHitTime[i] = 0
			Endif
		EndIf


		'=== MOUSE DOWN TIME ====
		'store mousedown time ... someone may need this measurement
		If MouseDown(i)
			'store time when first mousedown happened
			If _keyDownTime[i] = 0 Then _keyDownTime[i] = Time.GetTimeGone()
		Else
			'reset time - mousedown no longer happening
			_keyDownTime[i] = 0
		EndIf
	End Method


	'Update the button states
	Method Update:Int()
		'by default scroll wheel did not move
		scrollWheelMoved = 0

		If lastPos.z <> MouseZ()
			scrollWheelMoved = lastPos.z - MouseZ()
			lastPos.z = MouseZ()
		endif

		x = MouseX()
		y = MouseY()

		For Local i:Int = 1 To 3
			UpdateKey(i)
		Next

		lastPos.SetXY(x, y)
	End Method
EndType




Type TKeyManager
	'status of all keys
	Field _keyStatus:Int[256]
	Field _blockKeyTime:Int[256]


	'returns whether the button is in normal state
	Method isNormal:Int(key:Int)
		return _keyStatus[Key] = KEY_STATE_NORMAL
	End Method


	'returns whether the button is currently blocked
	Method isBlocked:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_BLOCKED
	End Method


	'returns whether the button is in hit state
	Method isHit:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_HIT
	End Method


	'returns whether the button is in down state
	Method isDown:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_DOWN
	End Method


	'returns whether the button is in up state
	Method isUp:Int(key:Int)
		return _keyStatus[key] = KEY_STATE_UP
	End Method


	'refresh all key states
	Method Update:Int()
		local time:int = Time.GetTimeGone()
		For Local i:Int = 1 To 255
			'ignore key if it is blocked
			'or set back to "normal" afterwards
			if _blockKeyTime[i] > time
				_keyStatus[i] = KEY_STATE_BLOCKED
			elseif _keyStatus[i] = KEY_STATE_BLOCKED
				_keyStatus[i] = KEY_STATE_NORMAL
			endif

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
	Method blockKey:int(key:int, milliseconds:int=0)
		'time can be absolute as a key block is just for blocking a key
		'which has not to be deterministic
		_blockKeyTime[key] = Time.GetTimeGone() + milliseconds
		'also set the current status to blocked
		_keyStatus[key] = KEY_STATE_BLOCKED
	End Method


	'resets the keys status
	Method resetKey:Int(key:Int)
		_keyStatus[key] = KEY_STATE_UP
		Return KEY_STATE_UP
	End Method
EndType




Const KEYWRAP_ALLOW_HIT:int	= 1
Const KEYWRAP_ALLOW_HOLD:int= 2
Const KEYWRAP_ALLOW_BOTH:int= 3


Type TKeyWrapper
	Rem
		0 - --
		1 - time to wait to get "hold" state after "hit"
		2 - time to wait for next "hold" after "hold"
		3 - total time till next hold
	EndRem
	Field _keySet:Int[256, 4]


	Method allowKey(key:Int, rule:Int=KEYWRAP_ALLOW_BOTH, hitTime:Int=600, holdtime:Int=100)
		_keySet[key, 0] = rule
		If rule & KEYWRAP_ALLOW_HIT then _keySet[key, 1] = hitTime

		If rule & KEYWRAP_ALLOW_HOLD then _keySet[key, 2] = holdTime
	End Method


	Method pressedKey:Int(key:Int, keyState:int=-1)
		if keyState = -1 then keyState = KEYMANAGER.getStatus(key)
		Local rule:Int = _keySet[key, 0]

		If keyState = KEY_STATE_NORMAL or keyState = KEY_STATE_UP Then Return False
		If keyState = KEY_STATE_BLOCKED Then Return False

		'Muss erlaubt und aktiv sein
		If rule & KEYWRAP_ALLOW_HIT and keyState = KEY_STATE_HIT
			Return hitKey(key, keyState)
		ElseIf rule & KEYWRAP_ALLOW_HOLD
			return holdKey(key, keyState)
		EndIf
		Return False
	End Method


	Method hitKey:Int(key:Int, keyState:int=-1)
		if keyState = -1 then keyState = KEYMANAGER.getStatus(key)
		If keyState <> KEY_STATE_HIT Then Return False

		'Muss erlaubt und aktiv sein
		If _keySet[key, 0] & KEYWRAP_ALLOW_HIT
			'Zeit bis man Taste halten darf
			_keySet[key, 3] = Time.GetTimeGone() + _keySet[key, 1]
			Return True
		EndIf
		Return False
	End Method


	Method holdKey:Int(key:Int, keyState:int=-1)
		if keyState = -1 then keyState = KEYMANAGER.getStatus(key)
		If keyState = KEY_STATE_NORMAL Or keyState = KEY_STATE_UP Then Return False

		If _keySet[key, 0] & KEYWRAP_ALLOW_HOLD
			'time which has to be gone until hold is set
			Local holdTime:Int = _keySet[key, 3]
			If Time.GetTimeGone() > holdTime
				'refresh time until next "hold"
				_keySet[key, 3] = Time.GetTimeGone() + _keySet[key, 2]
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