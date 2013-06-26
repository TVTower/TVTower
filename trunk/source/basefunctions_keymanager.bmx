SuperStrict
Import brl.System
import brl.PolledInput
?Threaded
Import brl.Threads
?
Global MOUSEMANAGER:TMouseManager = New TMouseManager
Global KEYMANAGER:TKeyManager = New TKeyManager
Global KEYWRAPPER:TKeyWrapper = New TKeyWrapper

'Tastenstadien
Const KEY_STATE_NORMAL:int		= 0
Const KEY_STATE_HIT:int			= 1
Const KEY_STATE_DOWN:int		= 2
Const KEY_STATE_UP:int			= 3
Const KEY_STATE_DOUBLEHIT:int	= 4

For local i:int = 0 To 255
	KEYWRAPPER.allowKey(i,KEYWRAP_ALLOW_BOTH,600,200)
Next

Type TMouseManager
	Field LastMouseX:Int		= 0
	Field LastMouseY:Int		= 0
	Field hasMoved:int			= 0
	Field errorboxes:Int		= 0
	Field _iKeyStatus:Int[]		= [0,0,0,0]
	Field _iKeyDownTime:Int[]	= [0,0,0,0]		'time since when the button is pressed
	Field _iKeyHitTime:Int[]	= [0,0,0,0]		'time when the button was last hit
	Field _doubleClickTime:int	= 300			'ms between two clicks for 1 double click

	'Statusabfragen

	Method isNormal:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_NORMAL
	EndMethod

	Method IsHit:Int( iKey:Int, ignoreDoubleClicks:int=TRUE)
		if ignoreDoubleClicks then return Self._iKeyStatus[ iKey ] = KEY_STATE_HIT
		return (Self._iKeyStatus[ iKey ] = KEY_STATE_HIT) or (Self._iKeyStatus[ iKey ] = KEY_STATE_DOUBLEHIT)
	EndMethod

	Method IsDoubleHit:Int( iKey:Int)
		return Self._iKeyStatus[ iKey ] = KEY_STATE_DOUBLEHIT
	EndMethod

	Method IsDown:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_DOWN
	EndMethod

	Method IsDownTime:Int( iKey:Int )
		if Self._iKeyDownTime[ iKey ] > 0
			return Millisecs() - Self._iKeyDownTime[ iKey ]
		else
			return 0
		endif
	EndMethod

	Method isUp:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_UP
	EndMethod

	Method SetDown:Int(iKey:Int)
		Self._iKeyStatus[iKey] = KEY_STATE_DOWN
	EndMethod

	'changeStatus(  )
	'Iteriert alle Buttons (gespeichert in lokalem Array)
	'und ändert ggf. deren Status.
	Method changeStatus(_errorboxes:Int=0)
		errorboxes = _errorboxes
		hasMoved = False
		If LastMouseX <> MouseX() Or LastMouseY <> MouseY()
			hasMoved = True
			LastMouseX = MouseX()
			LastMouseY = MouseY()
		endif

		For Local i:Int = 1 To 3
			If _iKeyStatus[ i ] = KEY_STATE_NORMAL
				If MouseHit( i )
					_iKeyStatus[ i ] = KEY_STATE_HIT
					'check for double click
					'only act if we already clicked in the past
					if _iKeyHitTime[ i ] > 0
						'did we click in the time frame ?
						if _iKeyHitTime[ i ] + _doubleClickTime > Millisecs()
							_iKeyStatus[ i ] = KEY_STATE_DOUBLEHIT
							_iKeyHitTime[ i ] = 0
						else
							'start a new doubleclick time
							_iKeyHitTime[ i ] = millisecs()
						endif
					else
						'save the click time so we now the passed time on next click
						_iKeyHitTime[ i ] = millisecs()
					endif

				endif
			ElseIf _iKeyStatus[ i ] = KEY_STATE_HIT or _iKeyStatus[ i ] = KEY_STATE_DOUBLEHIT
				If MouseDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_DOWN Else _iKeyStatus[ i ] = KEY_STATE_UP
			ElseIf _iKeyStatus[ i ] = KEY_STATE_DOWN
				If Not MouseDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_UP
			ElseIf _iKeyStatus[ i ] = KEY_STATE_UP
				_iKeyStatus[ i ] = KEY_STATE_NORMAL
			EndIf

			if MouseDown(i)
				'store time when first mousedown happened
				if self._iKeyDownTime[i] = 0 then self._iKeyDownTime[i] = millisecs()
			Else
				'reset time - mousedown no longer happening
				self._iKeyDownTime[i] = 0
			endif
		Next
	EndMethod

	Method resetKey:Int( iKey:Int )
		_iKeyStatus[ iKey ] = KEY_STATE_UP
		Return KEY_STATE_UP
	EndMethod

	Method GetStatusDown:int[]()
		return [false,..
		        _iKeyStatus[1] = KEY_STATE_DOWN,..
		        _iKeyStatus[2] = KEY_STATE_DOWN,..
		        _iKeyStatus[3] = KEY_STATE_DOWN..
		        ]
	End Method

	Method GetStatusHit:int[]()
		return [false,..
		        _iKeyStatus[1] = (KEY_STATE_HIT or KEY_STATE_DOUBLEHIT),..
		        _iKeyStatus[2] = (KEY_STATE_HIT or KEY_STATE_DOUBLEHIT),..
		        _iKeyStatus[3] = (KEY_STATE_HIT or KEY_STATE_DOUBLEHIT)..
		        ]
	End Method

	Method getStatus:Int( iKey:Int )
		Return _iKeyStatus[ iKey ]
	EndMethod
EndType

Type TKeyManager
	'Array aller Tasten die man zur Auswahl hat
	Field _iKeyStatus:Int[256]

	Method isNormal:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_NORMAL
	EndMethod

	Method IsHit:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_HIT
	EndMethod

	Method IsDown:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_DOWN
	EndMethod

	Method isUp:Int( iKey:Int )
		return Self._iKeyStatus[ iKey ] = KEY_STATE_UP
	EndMethod

	Method changeStatus(  )
		For Local i:Int = 1 To 255
			If _iKeyStatus[ i ] = KEY_STATE_NORMAL
				If KeyDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_HIT
			ElseIf _iKeyStatus[ i ] = KEY_STATE_HIT
				If KeyDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_DOWN Else _iKeyStatus[ i ] = KEY_STATE_UP
			ElseIf _iKeyStatus[ i ] = KEY_STATE_DOWN
				If Not KeyDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_UP
			ElseIf _iKeyStatus[ i ] = KEY_STATE_UP
				_iKeyStatus[ i ] = KEY_STATE_NORMAL
			EndIf
		Next
	EndMethod

	Method getStatus:Int( iKey:Int )
		Return _iKeyStatus[ iKey ]
	EndMethod

	Method resetKey:Int( iKey:Int )
		_iKeyStatus[ iKey] = KEY_STATE_UP
		Return KEY_STATE_UP
	EndMethod
EndType

Const KEYWRAP_ALLOW_HIT:int	= %01
Const KEYWRAP_ALLOW_HOLD:int= %10
Const KEYWRAP_ALLOW_BOTH:int= %11

Type TKeyWrapper
	rem
		0 - Allow-Rule
		1 - Pausenlaenge fuer Hold nach Hit
		2 - Pausenlaenge fuer Hold nach Hold
		3 - Gesamtzeit bis zum naechsten Hold
	endrem
	Field _iKeySet:Int[256, 4]

	Method allowKey( iKey:Int, iRule:Int = KEYWRAP_ALLOW_BOTH, iHitTime:Int = 600, iHoldtime:Int =100 )
		_iKeySet[iKey, 0] = iRule
		If iRule & KEYWRAP_ALLOW_HIT then _iKeySet[iKey, 1] = iHitTime

		If iRule & KEYWRAP_ALLOW_HOLD then _iKeySet[iKey, 2] = iHoldTime
	EndMethod

	Method pressedKey:Int( iKey:Int )
		Local iKeyState:Int = KEYMANAGER.getStatus( iKey )
		Local iRule:Int = _iKeySet[iKey, 0]

		If iKeyState = KEY_STATE_NORMAL or iKeyState = KEY_STATE_UP Then Return False

		'Muss erlaubt und aktiv sein
		If iRule & KEYWRAP_ALLOW_HIT and iKeyState = KEY_STATE_HIT
			Return hitKey( iKey )
		ElseIf iRule & KEYWRAP_ALLOW_HOLD
			Return holdKey( iKey )
		EndIf
		Return False
	EndMethod

	Method hitKey:Int( iKey:Int )
		Local iKeyState:Int = KEYMANAGER.getStatus( iKey )
		Local iRule:Int = _iKeySet[iKey, 0]
		If iKeyState <> KEY_STATE_HIT Then Return False
		'Muss erlaubt und aktiv sein
		If iRule & KEYWRAP_ALLOW_HIT' And iKeyState = KEY_STATE_HIT
			'Zeit bis man Taste halten darf
			_iKeySet[iKey, 3] = MilliSecs(  ) + _iKeySet[iKey, 1]
			Return True
		EndIf
		Return False
	EndMethod

	Method holdKey:Int( iKey:Int )
		Local iRule:Int = _iKeySet[iKey, 0]
		'If iKeyState = KEY_STATE_NORMAL Or iKeyState = KEY_STATE_UP Then Return False
		If iRule & KEYWRAP_ALLOW_HOLD
			'Zeit die verstrichen sein muss
			Local iTime:Int = _iKeySet[iKey, 3]
			If MilliSecs(  ) > iTime
				'Zeit bis zum nchsten Halten aktualisieren
				_iKeySet[iKey, 3] = MilliSecs(  ) + _iKeySet[iKey, 2]
				Return True
			EndIf
		EndIf
		Return False
	EndMethod

	Method resetKey( iKey:Int )
		_iKeySet[iKey, 0] = 0
		_iKeySet[iKey, 1] = 0
		_iKeySet[iKey, 2] = 0
		_iKeySet[iKey, 3] = 0
	EndMethod
EndType