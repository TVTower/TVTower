Import brl.System
import brl.PolledInput
Global MOUSEMANAGER:TMouseManager = New TMouseManager
Global KEYMANAGER:TKeyManager = New TKeyManager
Global KEYWRAPPER:TKeyWrapper = New TKeyWrapper

'Tastenstadien
Const KEY_STATE_NORMAL = 0
Const KEY_STATE_HIT = 1
Const KEY_STATE_DOWN = 2
Const KEY_STATE_UP = 3

Local keyi:Int
For keyi = 0 To 255
  KEYWRAPPER.allowKey(keyi,KEYWRAP_ALLOW_BOTH, 600, 100)
Next

Type TMouseManager
   Field LastMouseX:Int =0
   Field LastMouseY:Int =0
   Field hasMoved:int =0
   Field errorboxes:Int =0
   Field _iKeyStatus:Int[4]

   'Statusabfragen

   Method isNormal:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_NORMAL Then Return True Else Return False
   EndMethod

   Method IsHit:Int( iKey:Int)
      If Self._iKeyStatus[ iKey ] = KEY_STATE_HIT Then Return True Else Return False
   EndMethod

   Method IsDown:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_DOWN Then Return True Else Return False
   EndMethod

   Method isUp:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_UP Then Return True Else Return False
   EndMethod

   Method SetDown:Int(iKey:Int)
      Self._iKeyStatus[iKey] = KEY_STATE_DOWN
   End Method

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
            If MouseHit( i ) Then _iKeyStatus[ i ] = KEY_STATE_HIT
         ElseIf _iKeyStatus[ i ] = KEY_STATE_HIT
            If MouseDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_DOWN Else _iKeyStatus[ i ] = KEY_STATE_UP
         ElseIf _iKeyStatus[ i ] = KEY_STATE_DOWN
            If Not MouseDown( i ) Then _iKeyStatus[ i ] = KEY_STATE_UP
         ElseIf _iKeyStatus[ i ] = KEY_STATE_UP
            _iKeyStatus[ i ] = KEY_STATE_NORMAL
         EndIf

      Next

   EndMethod

   Method resetKey:Int( iKey:Int )
      _iKeyStatus[ iKey] = KEY_STATE_UP
      Return _iKeyStatus[ iKey ]
   EndMethod

   Method getStatus:Int( iKey:Int )
      Return _iKeyStatus[ iKey ]
   EndMethod

EndType

Type TKeyManager

   'Array aller Tasten die man zur Auswahl hat
   Field _iKeyStatus:Int[256]

   rem
      Statusabfragen
   endrem

   Method isNormal:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_NORMAL Then Return True Else Return False
   EndMethod

   Method IsHit:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_HIT Then Return True Else Return False
   EndMethod

   Method IsDown:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_DOWN Then Return True Else Return False
   EndMethod

   Method isUp:Int( iKey:Int )
      If Self._iKeyStatus[ iKey ] = KEY_STATE_UP Then Return True Else Return False
   EndMethod

   rem
      changeStatus(  )

      Iteriert alle Tasten (gespeichert in lokalem Array)
      und ndert ggf. deren Status.
   EndRem
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
      Return _iKeyStatus[ iKey ]
   EndMethod

EndType

Const KEYWRAP_ALLOW_HIT = %01
Const KEYWRAP_ALLOW_HOLD = %10
Const KEYWRAP_ALLOW_BOTH = %11

Type TKeyWrapper

   rem
      0 - Allow-Rule
      1 - Pausenlnge fr Hold nach Hit
      2 - Pausenlnge fr Hold nach Hold
      3 - Gesamtzeit bis zum nchsten Hold
   endrem
   Field _iKeySet:Int[256, 4]

   Method allowKey( iKey:Int, iRule:Int = KEYWRAP_ALLOW_BOTH, iHitTime:Int = 600, iHoldtime:Int =100 )
      _iKeySet[iKey, 0] = iRule
      If iRule & KEYWRAP_ALLOW_HIT
         _iKeySet[iKey, 1] = iHitTime
      EndIf

      If iRule & KEYWRAP_ALLOW_HOLD
         _iKeySet[iKey, 2] = iHoldTime
      EndIf

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