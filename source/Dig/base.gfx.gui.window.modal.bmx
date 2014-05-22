Rem
	===========================================================
	GUI Modal Window
	===========================================================
End Rem
SuperStrict
Import "base.util.virtualgraphics.bmx"
Import "base.gfx.gui.window.base.bmx"
Import "base.gfx.gui.button.bmx"




Type TGUIModalWindow Extends TGUIWindowBase
	Field DarkenedArea:TRectangle = Null
	Field buttons:TGUIButton[]
	Field autoAdjustHeight:Int = True
	'variables for closing animation
	Field moveAcceleration:Float = 1.2
	Field moveDY:Float = -1.0
	Field moveOld:TPoint = new TPoint.Init(0,0)
	Field move:TPoint = new TPoint.Init(0,0)
	Field fadeValueOld:Float = 1.0
	Field fadeValue:Float = 1.0
	Field fadeFactor:Float = 0.9
	Field fadeActive:Float = False
	Field isSetToClose:Int = False



	Method Create:TGUIModalWindow(pos:TPoint, dimension:TPoint, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		setZIndex(10000)

		'by default just a "ok" button
		SetDialogueType(1)

		'set another panel background
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"


		'we want to know if one clicks on a windows buttons
		AddEventListener(EventManager.registerListenerMethod("guiobject.onClick", Self, "onButtonClick"))

		'fire event so others know that the window is created
		EventManager.triggerEvent(TEventSimple.Create("guiModalWindow.onCreate", Self))
		Return Self
	End Method


	'easier setter for dialogue types
	Method SetDialogueType:Int(typeID:Int)
		For Local button:TGUIobject = EachIn Self.buttons
			button.remove()
			removeChild(button)
		Next
		buttons = New TGUIButton[0] '0 sized array

		Select typeID
			'a default button
			Case 1
				buttons = buttons[..1]
				buttons[0] = New TGUIButton.Create(new TPoint.Init(0, 0), new TPoint.Init(120, -1), GetLocale("OK"))
				AddChild(buttons[0])
				'set to ignore parental padding (so it starts at 0,0)
				buttons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
			'yes and no button
			Case 2
				buttons = buttons[..2]
				buttons[0] = New TGUIButton.Create(new TPoint.Init(0, 0), new TPoint.Init(90, -1), GetLocale("YES"))
				buttons[1] = New TGUIButton.Create(new TPoint.Init(0, 0), new TPoint.Init(90, -1), GetLocale("NO"))
				AddChild(buttons[0])
				AddChild(buttons[1])
				'set to ignore parental padding (so it starts at 0,0)
				buttons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
				buttons[1].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)

		End Select
	End Method


	Method Resize:Int(w:Float=Null,h:Float=Null)
		Super.Resize(w, h)
		'move button
		If buttons.length = 1
			buttons[0].rect.position.setXY(rect.GetW()/2 - buttons[0].rect.GetW()/2, GetScreenHeight() - 50)
		ElseIf buttons.length = 2
			buttons[0].rect.position.setXY(rect.GetW()/2 - buttons[0].rect.GetW() - 10, GetScreenHeight() - 50)
			buttons[1].rect.position.setXY(rect.GetW()/2 + 10, GetScreenHeight() - 50)
		EndIf

		Recenter()
	End Method


	'overwrite windowBase-method to recenter after appearance change
	Method onStatusAppearanceChange:int()
		Super.onStatusAppearanceChange()
		'Resize(-1,-1)
		Recenter()
	End Method


	Method Recenter:Int(moveBy:TPoint=Null)
		'center the window
		Local centerX:Float=0.0
		Local centerY:Float=0.0
		If Not darkenedArea
			centerX = VirtualWidth()/2
			centerY = VirtualHeight()/2
		Else
			centerX = DarkenedArea.getX() + DarkenedArea.GetW()/2
			centerY = DarkenedArea.getY() + DarkenedArea.GetH()/2
		EndIf

		If Not moveBy Then moveBy = new TPoint.Init(0,0)
		rect.position.setXY(centerX - rect.getW()/2 + moveBy.getX(),centerY - rect.getH()/2 + moveBy.getY() )
	End Method


	'cleanup function
	Method Remove:Int()
		Super.remove()

		'button is managed from guimanager
		'so we have to delete that separately
		For Local button:TGUIobject = EachIn Self.buttons
			button.remove()
		Next
		Return True
	End Method


	'close the window (eg. with an animation)
	Method Close:Int(closeButton:Int=-1)
		Self.isSetToClose = True

		'no animation just calls "remove"
		'but we want a nice fadeout
		Self.fadeActive = True

		'fire event so others know that the window is closed
		'and what button was used
		EventManager.triggerEvent(TEventSimple.Create("guiModalWindow.onClose", new TData.AddNumber("closeButton", closeButton) , Self))
	End Method


	Method canClose:Int()
		If Self.fadeActive Then Return False

		Return True
	End Method


	'handle clicks on the up/down-buttons and inform others about changes
	Method onButtonClick:Int( triggerEvent:TEventBase )
		Local sender:TGUIButton = TGUIButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		For Local i:Int = 0 To Self.buttons.length - 1
			If Self.buttons[i] <> sender Then Continue

			'close window
			Self.close(i)
		Next
	End Method


	'override default update-method
	Method Update:Int()
		'maybe children intercept clicks...
		UpdateChildren()

		Super.Update()

		'remove the window as soon as there is no animation active
		If isSetToClose
			If canClose()
				Self.remove()
				Return False
			Else
				If fadeActive
					'backup for tweening
					fadeValueOld = fadeValue
					fadeValue :* fadeFactor
				EndIf
				'buttons are managed by guimanager, so we have to set
				'their alpha here so they can draw correctly
				For Local i:Int = 0 To buttons.length-1
					buttons[i].alpha = fadeValue
				Next
				'quit fading when nearly zero
				If fadeValue < 0.05 Then fadeActive = False

				'move the dialogue too
				'- first increase the speed
				moveDY :* moveAcceleration
				'backup old move for tweening, store fade as .z
				moveold.setXY(0, move.y)
				'- now displace the objects
				move.moveXY(0, moveDY)
			EndIf
		EndIf

		Self.recenter(move)


		'deactivate mousehandling for other underlying objects
		GUIManager._ignoreMouse = True
	End Method


	Method Draw()
		local tween:Float = GetDeltaTimer().GetTween()

		'move to tweened move-position
		Self.recenter( THelper.GetTweenedPoint(move, moveOld, tween))

		SetAlpha Max(0, 0.5 * MathHelper.SteadyTween(fadeValueOld, fadeValue, tween))
		SetColor 0,0,0
		If Not DarkenedArea
			DrawRect(0,0,GraphicsWidth(), GraphicsHeight())
		Else
			DrawRect(DarkenedArea.getX(),DarkenedArea.getY(),DarkenedArea.getW(), DarkenedArea.getH())
		EndIf
		SetAlpha Max(0, 1.0 * MathHelper.SteadyTween(fadeValueOld, fadeValue, tween))
		SetColor 255,255,255

		DrawChildren()

		SetAlpha 1.0
	End Method
End Type
