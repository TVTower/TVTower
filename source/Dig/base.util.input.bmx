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

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
Import Math.vector
Import "base.util.vector.bmx"
Import "base.util.time.bmx"
Import "base.util.graphicsmanagerbase.bmx"
Import "base.util.objectqueue.bmx"

Global MOUSEMANAGER:TMouseManager = New TMouseManager
Global KEYMANAGER:TKeyManager = New TKeyManager
Global KEYWRAPPER:TKeyWrapper = New TKeyWrapper


Const KEY_STATE_NORMAL:Int               =  0 'nothing done
Const KEY_STATE_HIT:Int                  =  1 'once down, now up
Const KEY_STATE_DOWN:Int                 =  2 'down
Const KEY_STATE_UP:Int                   =  4 'up
Const KEY_STATE_BLOCKED:Int              =  8
Const KEY_STATE_BLOCKED_TILL_RELEASE:Int = 16 'no keyhit/keydown/... until released first

For Local i:Int = 0 To 255
	KEYWRAPPER.Init(i, 600, 100)
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
	Field currentPos:TVec2D = New TVec2D(0,0)
	Field x:Int = 0.0
	Field y:Int = 0.0
	'amount of pixels moved (0=zero, -upwards, +downwards)
	Field scrollWheelMoved:Int = 0
	'time (in ms) to wait for another click to recognize doubleclicks
	'so it is also the maximum time "between" that needed two clicks
	Field doubleClickMaxTime:Int = 250
	Field longClickMinTime:Int = 450


	Field _lastPos:TVec2D = New TVec2D(0,0)
	Field _lastScrollWheel:Int = 0
	
	'store the last click for each button
	'so we can check if we moved "since then"
	Field lastClick:TMouseManagerClick[5]
	Field lastDoubleClick:TMouseManagerClick[5]
	Field lastLongClick:TMouseManagerClick[5]

	Field skipLongClicks:Int[] = [0,0,0,0,0]
	Field skipClicks:Int[] = [0,0,0,0,0]

	'store up to 20 click information of all click types and all buttons
	'so clicks between "updates" can still be processed one after another
	'each information contains: position, click type and time of the click
	Field _unhandledClicksStack:TObjectQueue
	'once handled store them in there. Update() then clears this stack
	'or removes the first from unhandled if none was handled that cycle
	Field _handledClicksStack:TObjectQueue

	Field _changedClicksUpdateCycle:Int
	Field _updateCycle:Int
	
	Field _lastMovementTime:Long

	'previous position at the screen when a button was clicked, doubleclicked
	'or longclicke the last time
	Field _lastAnyClickPos:TVec2D[5]
	'store clicks in the doubleclick timespan to identify double clicks
	Field _clicksInDoubleClickTimeCount:Int[] = [0,0,0,0,0]

	'down or not?
	Field _down:Int[] = [0,0,0,0,0]
	'time since when the button was pressed last
	Field _downTime:Long[] = [0:Long,0:Long,0:Long,0:Long,0:Long]
	Field _downStartPos:SVec2I[] = New SVec2I[5]
	'can clicks/hits get read?
	'special info read is possible (IsDown(), IsNormal())
	Field _enabled:Int[] = [True, True, True, True, True]


	'TOUCH emulation
	Field _longClickModeEnabled:Int = True
	Field _longClickLeadsToRightClick:Int = True
	'skip first click (touch screens)
	Field _ignoreFirstClick:Int = False
	Field _hasIgnoredFirstClick:Int[] = [0,0,0,0,0] 'currently ignoring?
	Field _ignoredFirstClickPos:TVec2D[] = [New TVec2D, New TVec2D, New TVec2D, New TVec2D, New TVec2D]
	'distance in pixels, if mouse moved further away, the next
	'click will get ignored ("tap")
	Field _minSwipeDistance:Int = 10

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
				If ev.data > 0 And ev.data <= 5
					If Not evMouseDown[ev.data-1]
						evMouseDown[ev.data-1] = 1
						evMouseHits[ev.data-1] :+ 1
					EndIf
					MouseManager._HandleButtonEvent(ev.data)
				EndIf
			Case EVENT_MOUSEUP
				'we only handle up to the 5h mousebutton
				If ev.data > 0 And ev.data <= 5
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
		_unhandledClicksStack = New TObjectQueue
		_handledClicksStack = New TObjectQueue
	End Method


	Method _GetClickEntry:TMouseManagerClick()
		If _unhandledClicksStack.IsEmpty() Then Return Null
		Return TMouseManagerClick(_unhandledClicksStack.Peek())
	End Method
	
			
	'remove X added clicks from the stack (the "oldest" first)
	Method _RemoveClickEntry:Int(clickCount:Int = 1)
		'remove all
		If clickCount < 0 
			_unhandledClicksStack.Clear()
		'remove (up to) defined amount
		Else
			For Local i:Int = 0 Until clickCount
				If _unhandledClicksStack.IsEmpty() Then Exit

				_unhandledClicksStack.Dequeue()
			Next
		EndIf
		Return True
	End Method
	
	
	Method _RemoveClickEntries:Int(button:Int = -1, clickType:Int = -1)
		Local clicks:Object[] = _unhandledClicksStack.ToArray()
		_unhandledClicksStack.Clear()

		For Local c:TMouseManagerClick = EachIn clicks
			If button >= 0 And c.button <> button Then Continue
			If clickType >= 0 And c.clickType <> clickType Then Continue
			 
			_unhandledClicksStack.Enqueue(c)
		Next
	End Method


	Method _AddClickEntry:TMouseManagerClick(button:Int, clickType:Int = -1, position:TVec2D, time:Long = -1)
		'store for next update cycle
		Local click:TMouseManagerClick = New TMouseManagerClick.Init(button, clickType, position.Copy(), time)
		'print "_addClickentry: " + _updateCycle
		_unhandledClicksStack.Enqueue( click )
		
		_changedClicksUpdateCycle = _updateCycle
		
		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				lastDoubleClick[button-1] = click
			Case CLICKTYPE_LONGCLICK
				lastLongClick[button-1] = click
			Default
				lastClick[button-1] = click
		End Select
		
		Return click
	End Method


	'return amount of managed buttons
	Method GetButtonCount:Int()
		Return _down.Length 'ignore 0
	End Method
	
	
	Method SkipNextLongClick:Int(button:Int, amount:Int = 1)
		skipLongClicks[button-1] = amount
	End Method


	Method SkipNextClick:Int(button:Int, amount:Int = 1)
		skipClicks[button-1] = amount
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
		_RemoveClickEntries(button, clickType)
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
		Local t:Long = time.GetAppTimeGone()
		
		Local click:TMouseManagerClick = _GetClickEntry()
		While click And click.t + age < t
			_RemoveClickEntry()
			click = _GetClickEntry()
		Wend
	End Method


	'set the current single/double/long click of one of the mousebutton
	'handled
	'TODO: remove button, kept it in for compatiblity (in case we split
	'      it clickStack up for each button)
	Method SetClickHandled:Int(button:Int)
		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return False

		c.handled = True
		
		_RemoveClickEntry()
		'add to handled clicks
		_handledClicksStack.Enqueue(c)

		_changedClicksUpdateCycle = _updateCycle		
		
		Return True
	End Method

	'TODO: remove, kept it in for compatiblity (in case we split
	'      it clickStack up for each button)
	Method SetLongClickHandled:Int(button:Int)
		Return SetClickHandled(button)
	End Method

	'TODO: remove, kept it in for compatiblity (in case we split
	'      it clickStack up for each button)
	Method SetDoubleClickHandled:Int(button:Int)
		Return SetClickHandled(button)
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

		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return False

		Return Not c.handled And c.button = button And c.clickType = CLICKTYPE_CLICK
	End Method


	'returns whether the button was clicked 2 times
	Method IsDoubleClicked:Int(button:Int)
		If Not _enabled[button-1] Then Return False

		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return False

		Return Not c.handled And c.button = button And c.clickType = CLICKTYPE_DOUBLECLICK
	End Method


	'returns whether the button was clicked 2 times
	Method IsLongClicked:Int(button:Int)
		If Not _longClickModeEnabled Then Return False
		If Not _enabled[button-1] Then Return False

		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return False

		Return Not c.handled And c.button = button And c.clickType = CLICKTYPE_LONGCLICK
	End Method


	'returns whether the mouse moved between two updates
	Method HasMoved:Int()
		Return (0 <> GetMovedDistance())
	End Method


	'returns whether the mouse moved since last click of the button
	Method HasMovedSinceClick:Int(button:Int)
		Return (0 <> GetMovedDistanceSinceClick(button))
	End Method


	Method GetMovedDistance:Int()
		Return Sqr((_lastPos.X - Int(x))^2 + (_lastPos.y - Int(y))^2)
	End Method


	Method GetLastMovedTime:Long()
		Return _lastMovementTime
	End Method


	Method GetMovedDistanceSinceClick:Int(button:Int, clickType:Int = -1)
		If clickType = -1 Then clickType = CLICKTYPE_CLICK
		
		'fetch last click
		Local c:TMouseManagerClick
		Select clickType
			Case CLICKTYPE_DOUBLECLICK
				c = lastDoubleClick[button]
			Case CLICKTYPE_LONGCLICK
				c = lastLongClick[button]
			Default
				c = lastClick[button]
		End Select
		If Not c Then Return 0

		Return Sqr((c.position.x - Int(x))^2 + (c.position.y - Int(y))^2)
	End Method


	Method GetClickTime:Long()
		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return 0
		If c.handled Then Return 0 
		Return c.t
	End Method


	'TODO: remove button, kept it in for compatiblity (in case we split
	'      it clickStack up for each button)
	Method GetClickPosition:TVec2D(button:Int)
		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return Null
		If c.handled Then Return Null
		Return c.position
	End Method


	Method GetDownStartPosition:SVec2I(button:Int)
		If _down[button-1]
			Return _downStartPos[button-1]
		Else
			Return New SVec2I(-1,-1)
		EndIf
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
			Return time.GetAppTimeGone() - _downTime[button-1]
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
		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return 0
		If button >= 0 And c.button <> button Then Return 0
		If clickType >= 0 And c.clickType <> clickType Then Return 0

		Return 1
	End Method


	'returns the amount of double clicks
	Method GetDoubleClicks:Int(button:Int)
		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return 0
		If button >= 0 And c.button <> button Then Return 0
		If c.clickType <> CLICKTYPE_DOUBLECLICK Then Return 0

		Return 1
	End Method


	'returns the amount of long clicks
	Method GetLongClicks:Int(button:Int)
		Local c:TMouseManagerClick = _GetClickEntry()
		If Not c Then Return 0
		If button >= 0 And c.button <> button Then Return 0
		If c.clickType <> CLICKTYPE_LONGCLICK Then Return 0

		Return 1
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
		'if nobody was handling something for more than a cycle
		'remove the oldest/first unhandled one
		If _changedClicksUpdateCycle <> _updateCycle And _unhandledClicksStack And _unhandledClicksStack.Count() > 0
			'print "updatecycle="+ _updateCycle + "  Removing " + _unhandledClicksStack.Count() + " unhandled click(s).  " + Millisecs()
			'print "- " + TMouseManagerClick( _unhandledClicksStack.Dequeue() ).ToString()
			_unhandledClicksStack.Dequeue()
		EndIf

		'some click got handled?
		If _handledClicksStack And _handledClicksStack.Count() > 0 
			'print "Removing " + _handledClicksStack.Count() + " handled clicks.  " + Millisecs()
			_handledClicksStack.Clear()
		EndIf
		_updateCycle :+ 1


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
		x = GetGraphicsManager().DesignedMouseX()
		y = GetGraphicsManager().DesignedMouseY()
		currentPos.x = x
		currentPos.y = y


		'MOVEMENT TIME
		If HasMoved() 
			_lastMovementTime = time.GetTimeGone()
		EndIf


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

			'Print Time.GetTimeGone() + "  normal => down   x="+x + " y="+y
			_down[buttonIndex] = True
			_downTime[buttonIndex] = time.GetAppTimeGone()
			_downStartPos[buttonIndex] = New SVec2I(x, y)
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

			Local t:Long = time.GetAppTimeGone()
			Local timeSinceLastClick:Int = 0
			If lastClick[buttonIndex] Then timeSinceLastClick = t - lastClick[buttonIndex].t

			If timeSinceLastClick < doubleClickMaxTime
				_clicksInDoubleClickTimeCount[buttonIndex] :+ 1
				'Print Time.GetTimeGone() + "    down => up => click within doubleclick time    clicks=" + (_clicksInDoubleClickTimeCount[buttonIndex])
			Else
				'Print Time.GetTimeGone() + "    down => up => reset doubleclick time"
				_clicksInDoubleClickTimeCount[buttonIndex] = 1
			EndIf


			Local currentPosVec:TVec2D = New TVec2D(x, y)

			'check for swipe
			If _hasIgnoredFirstClick[buttonIndex] And _lastAnyClickPos[buttonIndex] And _lastAnyClickPos[buttonIndex].DistanceTo(currentPosVec) > _minSwipeDistance
				'Print "reset " + _lastAnyClickPos[buttonIndex].DistanceTo(currentPosVec) +" > "+_minSwipeDistance
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
					If skipLongClicks[buttonIndex] > 0
						skipLongClicks[buttonIndex] :- 1
					Else
						'but also a long click one
						_AddClickEntry(button, CLICKTYPE_LONGCLICK, currentPosVec.Copy(), t)

						'emulating right click?
						If _longClickLeadsToRightClick And button = 1
							_AddClickEntry(2, CLICKTYPE_CLICK, currentPosVec.Copy(), t)
							_downTime[2] = _downTime[1]
						Else
							'it is a click nonetheless
							_AddClickEntry(button, CLICKTYPE_CLICK, currentPosVec.Copy(), t)
						EndIf
					EndIf

					'Print Time.GetTimeGone() + "      click => long clicked    downTime="+_downTime[button] +"  longClickMinTime="+longClickMinTime +"   button="+button

				' normal click + double clicks
				Else
					'Print Time.GetTimeGone() + "    down => up => click   GetClicks( " + button + ")=" + GetClicks(button) + " _clicksInDoubleClickTimeCount["+buttonIndex+"]="+_clicksInDoubleClickTimeCount[buttonIndex]
					If skipClicks[buttonIndex] > 0
						skipClicks[buttonIndex] :- 1
					Else
						_AddClickEntry(button, CLICKTYPE_CLICK, currentPosVec.Copy(), t)

						'double clicks (additionally to normal clicks!)
						If _clicksInDoubleClickTimeCount[buttonIndex] >= 2
							_AddClickEntry(button, CLICKTYPE_DOUBLECLICK, currentPosVec.Copy(), t)

							_clicksInDoubleClickTimeCount[buttonIndex] :- 2
						EndIf
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
	Field button:Int
	Field clickType:Int = 1
	Field position:TVec2D
	Field t:Long
	Field handled:Int 
	Field id:Int
	Global lastID:Int = 0
	
	Method New()
		lastID :+ 1
		id = lastID
	End Method
		

	Method Init:TMouseManagerClick(button:Int, clickType:Int, position:TVec2D, clickTime:Long = -1)
		If clickTime = -1 Then clickTime = time.GetAppTimeGone()
		Self.button = button
		Self.clickType = clickType
		Self.position = position
		Self.handled = False
		Self.t = clickTime
		Return Self
	End Method
	
	
	Method ToString:String()
		Select clickType
			Case TMouseManager.CLICKTYPE_CLICK
				Return "Click #" + id +". button=" + button + "  clickType=" + clickType + " [singleclick]  position="+position.ToString() + "  t=" + t + "  handled="+handled
			Case TMouseManager.CLICKTYPE_DOUBLECLICK
				Return "Click #" + id +". button=" + button + "  clickType=" + clickType + " [doubleclick]  position="+position.ToString() + "  t=" + t + "  handled="+handled
			Case TMouseManager.CLICKTYPE_LONGCLICK
				Return "Click #" + id +". button=" + button + "  clickType=" + clickType + " [longclick]  position="+position.ToString() + "  t=" + t + "  handled="+handled
			Default
				Return "Click #" + id +". button=" + button + "  clickType=" + clickType + " [unknown]  position="+position.ToString() + "  t=" + t + "  handled="+handled
		End Select
	End Method
End Type




Type TKeyManager
	'status of all keys
	Field _keyStatus:Int[256]
	Field _downTime:Long[256]
	Field _blockKeyTime:Long[256]

	Global processedAppSuspend:Int = False


	'returns whether the button is in normal state
	Method isNormal:Int(key:Int)
		Return _keyStatus[Key] = KEY_STATE_NORMAL
	End Method


	'returns whether the button is currently blocked (time wise)
	Method isBlocked:Int(key:Int)
		'this time it is a bitmask flag (normal/hit/.. + blocked)
		Return (_keyStatus[key] & KEY_STATE_BLOCKED)
	End Method

	Method isBlockedTillRelease:Int(key:Int)
		'this time it is a bitmask flag (normal/hit/.. + blocked)
		Return (_keyStatus[key] & KEY_STATE_BLOCKED_TILL_RELEASE)
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

	'returns how many milliseconds a key is down
	Method GetDownTime:Long(key:Int)
		If _downTime[key-1] > 0
			Return time.GetAppTimeGone() - _downTime[key-1]
		Else
			Return 0
		EndIf
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


		Local nowTime:Long = time.GetAppTimeGone()
		For Local i:Int = 1 To 255
			'ignore key if it is blocked
			'or set back to "normal" afterwards
			If _blockKeyTime[i] > nowTime
				_keyStatus[i] :| KEY_STATE_BLOCKED
			ElseIf isBlocked(i)
				_downTime[i] = 0

				_keyStatus[i] :& ~KEY_STATE_BLOCKED
'				'meanwhile a hit can get renewed
				If _keyStatus[i] = KEY_STATE_HIT
					_keyStatus[i] = KEY_STATE_NORMAL
				EndIf
			EndIf

			'normal check
			If Not KeyDown(i) And isBlockedTillRelease(i)
				_keyStatus[i] = KEY_STATE_NORMAL
			EndIf
			If _keyStatus[i] = KEY_STATE_NORMAL
				If KeyDown(i)
					_downTime[i] = nowTime
					_keyStatus[i] = KEY_STATE_HIT
				EndIf
			ElseIf _keyStatus[i] = KEY_STATE_HIT
				If KeyDown(i) 
					_keyStatus[i] = KEY_STATE_DOWN 
				Else
					_downTime[i] = 0
					_keyStatus[i] = KEY_STATE_UP
				EndIf
			ElseIf _keyStatus[i] = KEY_STATE_DOWN
				If Not KeyDown(i) 
					_downTime[i] = 0
					_keyStatus[i] = KEY_STATE_UP
				EndIf
			ElseIf _keyStatus[i] = KEY_STATE_UP
				_keyStatus[i] = KEY_STATE_NORMAL
			EndIf
		Next
		
		'update wrapper too
		KeyWrapper.Update()
	End Method



	'returns the status of a key
	Method getStatus:Int(key:Int)
		Return _keyStatus[key]
	End Method


	'set a key as blocked for the given time
	Method BlockKey:Int(key:Int, milliseconds:Int=0)
		'time can be absolute as a key block is just for blocking a key
		'which has not to be deterministic
		_blockKeyTime[key] = time.GetAppTimeGone() + milliseconds
		'also add the block state to the  current status
		_keyStatus[key] :| KEY_STATE_BLOCKED
	End Method


	Method BlockKeyTillRelease:Int(key:Int)
		'also add the block state to the  current status
		_keyStatus[key] :| KEY_STATE_BLOCKED_TILL_RELEASE
	End Method


	'resets the keys status
	Method ResetKey:Int(key:Int)
		_keyStatus[key] = KEY_STATE_UP
		Return KEY_STATE_UP
	End Method
EndType




Const KEYWRAP_ALLOW_HIT:Int	= 1
Const KEYWRAP_ALLOW_HOLD:Int= 2
Const KEYWRAP_ALLOW_BOTH:Int= 3





Type TKeyWrapper
	Field keyHoldInformation:TKeyHoldInformation[256]
	
	
	Method New()
		For Local i:Int = 0 To 255
			keyHoldInformation[i] = New TKeyHoldInformation(i, 600, 100)
		Next
	End Method
	

	Method Init(key:Int, firstHoldTime:Int=600, holdTime:Int=100)
		keyHoldInformation[key].Init(key, firstHoldTime, holdTime)
	End Method


	Method Update:Int()
		For Local key:Int = 0 To 255
			keyHoldInformation[key].Update( KeyManager._keyStatus[key] )
		Next
	End Method


	'returns if key is currently hit or "hold" (and enough holding time
	'is gone)
	Method IsPressed:Int(key:Int)
		Return keyHoldInformation[key].IsPressed()
	End Method


	Method IsHit:Int(key:Int)
		Return keyHoldInformation[key].IsHit()
	End Method
	

	'returns if a key is currently hold
	Method IsHold:Int(key:Int)
		Return keyHoldInformation[key].IsHold()
	End Method
	

	Method ResetKey(key:Int)
		keyHoldInformation[key].Reset()
	End Method
End Type



'Type to allow a check if a key is held for an individual hold time.
'The default "KeyWrapper.IsPressed()" uses a defined "hold time" for a key
'but sometimes you want to check for another time span without altering
'it globally.
'TODO: Replace with "struct" once NG/BCC gets fixed
Type TKeyHoldInformation
	Field key:Int
	'after the initial hit a specific time is waited until the first "hold"
	'after this, the normal "_holdTime" is used
	Field _firstHoldTime:Int
	Field _holdTime:Int
	'exact app time when next "hold" happens
	Field _nextHoldTimer:Long
	Field _holdRepetitions:Int 
	'hit and hold status
	Field _holdState:Int
	Field _hitState:Int 

	

	Method New(key:Int, firstHoldTime:Int=600, holdTime:Int=100)
		Init(key, firstHoldTime, holdTime)
	End Method


	Method Init(key:Int, firstHoldTime:Int=600, holdTime:Int=100)
		Self.key = key

		Self._firstHoldTime = firstHoldTime
		Self._holdTime = holdTime
		Self._nextHoldTimer = -1
	End Method


	Method Update:Int(keyState:Int = -1)
		If keyState = -1 Then keyState = KeyManager.GetStatus(key)

		'reset HIT
		If keyState <> KEY_STATE_HIT And _hitState
			'print Time.GetAppTimeGone() +"  key " + key + " no longer hit."
			_hitState = False
		EndIf
		
		'reset HOLD
		If (keyState = KEY_STATE_NORMAL Or keyState = KEY_STATE_UP) And _nextHoldTimer >= 0
			'print Time.GetAppTimeGone() +"  key " + key + " no longer hold."
			_holdState = False
			_nextHoldTimer = -1
			_holdRepetitions = 0
		EndIf

		'update HOLD / wait for next
		If _holdState And _nextHoldTimer >= 0 And time.GetAppTimeGone() > _nextHoldTimer
			'print Time.GetAppTimeGone() +"  key " + key + " repetition reset."
			_holdState = False
		EndIf


		'set HIT
		If keyState = KEY_STATE_HIT
			'print Time.GetAppTimeGone() +"  key " + key + " hit."
			_hitState = True
			'set "first hold" start
			_nextHoldTimer = time.GetAppTimeGone() + _firstHoldTime
		EndIf

		'set HOLD
		If keyState = KEY_STATE_DOWN And _nextHoldTimer >= 0 And time.GetAppTimeGone() > _nextHoldTimer
			'print Time.GetAppTimeGone() +"  key " + key + " is (repeated) hold."
			_holdState = True
			'set "next hold" start
			_nextHoldTimer = time.GetAppTimeGone() + _holdTime
			'increase count of "repeated holds since key down" 
			_holdRepetitions :+ 1
		EndIf
	End Method


	'returns if key is currently hit or "hold" (and enough holding time
	'is gone)
	Method IsPressed:Int()
		Return (IsHit() Or IsHold())
	End Method


	Method IsHit:Int()
		If KeyManager.GetStatus(key) & KEY_STATE_BLOCKED Then Return False

		Return _hitState
	End Method
	

	'returns if a key is currently hold
	Method IsHold:Int()
		If KeyManager.GetStatus(key) & KEY_STATE_BLOCKED Then Return False

		Return _holdState
	End Method
	

	Method Reset()
		'_firstHoldTime = 0
		'_holdTime = 0
		_nextHoldTimer = -1
		_holdRepetitions = 0
	End Method
End Type
