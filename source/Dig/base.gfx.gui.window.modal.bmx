Rem
	====================================================================
	GUI Modal Window
	====================================================================

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015-2025 Ronny Otto, digidea.de

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
End Rem
SuperStrict
Import "base.util.virtualgraphics.bmx"
Import "base.util.interpolation.bmx"
Import "base.gfx.gui.window.base.bmx"
Import "base.gfx.gui.button.bmx"




Type TGUIModalWindow Extends TGUIWindowBase
	Field DarkenedArea:TRectangle = Null
	Field darkenedAreaAlpha:Float = 0.5
	'the area the window centers to
	Field screenArea:TRectangle = Null
	Field buttons:TGUIButton[]
	'0 = centered, -1 = left aligned, 1 = right aligned
	Field buttonAlignment:Int = 0
	'templates for button positions
	Field buttonPositionTemplate:Int = 0
	Field autoAdjustHeight:Int = True
	Field isOpen:Int
	'=== CLOSING VARIABLES ===
	'indicator if currently closing
	Field closeActionStarted:Long = 0
	'the time a close action started
	Field closeActionTime:Long = 0
	'the time a close action runs
	Field closeActionDuration:int = 650
	'the position of the widget when closing
	Field closeActionStartPosition:TVec2D = new TVec2D



	Method Create:TGUIModalWindow(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		setZIndex(10000)

		'by default just a "ok" button
		SetDialogueType(1)

		'set another panel background
		GUIManager.Remove(guiBackground)
		guiBackground.spriteBaseName = "gfx_gui_modalWindow"


		'fire event so others know that the window is created
		TriggerBaseEvent(GUIEventKeys.GUIModalWindow_OnCreate, Null, Self)
		Return Self
	End Method


	'override to delete children too (not really needed)
	Method Remove:Int() override
		Super.Remove()

		'buttons are normally removed by "Super.Remove()" already
		'as they are added as "children" and are iterated on its own 
		For Local o:TGUIObject = EachIn buttons
			o.Remove()
		Next
	End Method


	Method Initialize:int()
		closeActionStarted = 0
		closeActionTime = 0
	End Method


	'easier setter for dialogue types
	Method SetDialogueType:Int(typeID:Int)
		For Local button:TGUIobject = EachIn Self.buttons
			button.remove()
		Next
		buttons = New TGUIButton[0] '0 sized array

		Select typeID
			'a default button
			Case 1
				buttons = buttons[..1]
				buttons[0] = New TGUIButton.Create(new SVec2I(0,0), new SVec2I(120,-1), GetLocale("OK"))
				buttons[0]._callbacks_onClick :+ [onButtonsCloseClickCallback]
				AddChild(buttons[0])
				'set to ignore parental padding (so it starts at 0,0)
				buttons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
			'yes and no button
			Case 2
				buttons = buttons[..2]
				buttons[0] = New TGUIButton.Create(new SVec2I(0,0), new SVec2I(90,-1), GetLocale("YES"))
				buttons[1] = New TGUIButton.Create(new SVec2I(0,0), new SVec2I(90,-1), GetLocale("NO"))
				buttons[0]._callbacks_onClick :+ [onButtonsCloseClickCallback]
				buttons[1]._callbacks_onClick :+ [onButtonsCloseClickCallback]
				AddChild(buttons[0])
				AddChild(buttons[1])
				'set to ignore parental padding (so it starts at 0,0)
				buttons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
				buttons[1].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)

		End Select
	End Method
	

	'handle clicks on the various close buttons
	Function onButtonsCloseClickCallback:Int(sender:TGUIObject, mouseButton:Int, x:Int, y:Int)
		local window:TGUIModalWindow = TGUIModalWindow(sender._parent)
		If Not window Then Throw "Button is no child of TGUIModalWindow"
		
		For local i:int = 0 until window.buttons.length
			if window.buttons[i] = sender
				Return window.Close(i)
			EndIf
		Next
		Return False
	End Function


	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)
		
		'move button
		If buttons.length = 1
			Select buttonAlignment
				Case -1
					buttons[0].SetPosition(0, GetScreenRect().GetH() - 49)
				Case 1
					buttons[0].SetPosition(rect.GetW() - buttons[0].rect.GetW(), GetScreenRect().GetH() - 49)
				Default
					buttons[0].SetPosition(rect.GetW()/2 - buttons[0].rect.GetW()/2, GetScreenRect().GetH() - 49)
			End Select
		ElseIf buttons.length = 2
			Select buttonAlignment
				Case -1
					buttons[0].SetPosition(0, GetScreenRect().GetH() - 49)
					buttons[1].SetPosition(buttons[0].rect.GetW() + 10, GetScreenRect().GetH() - 49)
				Case 1
					buttons[0].SetPosition(rect.GetW() - buttons[1].rect.GetW() - 10 - buttons[0].rect.GetW(), GetScreenRect().GetH() - 49)
					buttons[1].SetPosition(rect.GetW() - buttons[0].rect.GetW(), GetScreenRect().GetH() - 49)

				Default
					buttons[0].SetPosition(rect.GetW()/2 - buttons[0].rect.GetW() - 10, GetScreenRect().GetH() - 49)
					buttons[1].SetPosition(rect.GetW()/2 + 10, GetScreenRect().GetH() - 49)
			End Select
		EndIf

		'move some buttons according to a template (here: left or right)
		'while keeping position of others intact
		If buttonPositionTemplate = 1
			if buttons.length > 1
				buttons[0].SetPositionX(rect.GetW()/2 - buttons[0].rect.GetW()/2)
				buttons[1].SetPositionX(GetContentX())
			endif
		ElseIf buttonPositionTemplate = 2
			if buttons.length > 1
				buttons[0].SetPositionX(rect.GetW()/2 - buttons[0].rect.GetW()/2)
				buttons[1].SetPositionX(GetContentX() - buttons[1].rect.GetW())
			endif
		EndIf

		Recenter()
	End Method


	'overwrite windowBase-method to recenter after appearance change
	Method onAppearanceChanged:int()
		Super.onAppearanceChanged()
		Recenter()
	End Method


	Method Recenter:Int(moveByX:Float = 0, moveByY:Float = 0)
		'center the window
		Local centerX:Float=0.0
		Local centerY:Float=0.0
		If Not screenArea
			centerX = VirtualWidth()/2
			centerY = VirtualHeight()/2
		Else
			centerX = screenArea.getX() + screenArea.GetW()/2
			centerY = screenArea.getY() + screenArea.GetH()/2
		EndIf

		SetPosition(centerX - rect.getW()/2 + moveByX,centerY - rect.getH()/2 + moveByY)
	End Method


	Method Open:Int()
		TriggerBaseEvent(GUIEventKeys.GUIModalWindow_OnOpen, Null, Self)

		isOpen = True
	End Method


	'close the window (eg. with an animation)
	Method Close:Int(closeButton:Int=-1)
		'only close once :D
		if closeActionStarted then return False
		
		isOpen = False

		closeActionStarted = True
		closeActionTime = Time.GetAppTimeGone()
		closeActionStartPosition = new TVec2D(rect.x, rect.y)
		
		'fire event so others know that the window is closed
		'and what button was used
		TriggerBaseEvent(GUIEventKeys.GUIModalWindow_OnClose, new TData.AddNumber("closeButton", closeButton) , Self)
	End Method


	Method canClose:Int()
		'is there an animation active?
		If closeActionStarted
			If closeActionTime + closeActionDuration < Time.GetAppTimeGone()
				Return True
			Else
				Return False
			EndIf
		Else
			Return True
		EndIf
	End Method


	Method IsClosed:int()
		return closeActionStarted and closeActionTime + closeActionDuration < Time.GetAppTimeGone()
	End Method


	Method IsClosing:int()
		return closeActionStarted
	End Method


	Method GetSelectedButtonIndex:Int()
		For Local i:Int = 0 To Self.buttons.length - 1
			If Self.buttons[i].IsSelected() Then Return i
		Next
		Return -1
	End Method
	
	
	Method SelectButton:Int(index:Int)
		if index < 0 or index >= self.buttons.length Then Return False

		Local selectedSomething:Int
		'remove selection indicator from others
		For Local i:Int = 0 To Self.buttons.length - 1
			If index <> i 
				If Self.buttons[i].IsSelected()
					Self.buttons[i].SetSelected(False)
				EndIf
			Else
				Self.buttons[i].SetSelected(True)
				selectedSomething = True
			EndIf
		Next
		
		Return selectedSomething
	End Method


	Method ClickButton:Int(index:Int)
		if index < 0 or index >= self.buttons.length Then Return False
		
		Return buttons[index].Click(EGUIClickType.KEYBOARD, KEY_ENTER)
	End Method


	'override default update-method
	Method Update:Int()
		'maybe children intercept clicks...
		'so call Super.Update as it calls UpdateChildren already
		Super.Update()

		if closeActionStarted
			local yUntilScreenLeft:int = VirtualHeight() - (closeActionStartPosition.y + GetScreenRect().GetH())
			Recenter(0, Float(- yUntilScreenLeft * TInterpolation.BackIn(0.0, 1.0, Min(closeActionDuration, Time.GetAppTimeGone() - closeActionTime), closeActionDuration)))
		endif

		If Not IsClosing()
			If Not GuiManager.GetKeyboardInputReceiver() 
				'tab through buttons?
				If KeyManager.IsHit(KEY_TAB)
					'do not allow another Tab-press for X ms
					KeyManager.blockKey(KEY_TAB, 250)

					'avoid "modulo 0" 
					If Self.buttons.length > 0
						SelectButton( (GetSelectedButtonIndex() + 1) mod Self.buttons.length)
					EndIf
				'abort/cancel
				ElseIf KeyManager.IsHit(KEY_ESCAPE)
					'do not allow another ESC-press for X ms
					KeyManager.blockKey(KEY_ESCAPE, 250)

					Close()

				'click selected button
				ElseIf KeyManager.IsHit(KEY_ENTER)
					Local selectedButtonIndex:Int = Self.GetSelectedButtonIndex()
					If selectedButtonIndex >= 0
						'click on the currently selected button
						'do not allow another ENTER-press for X ms
						KeyManager.blockKey(KEY_ENTER, 250)
						
						ClickButton(selectedButtonIndex)

						Close()
					EndIf
				EndIf
			EndIf
		EndIf


		'remove the window as soon as there is no animation active
		'until then: play the animation
		If IsClosed()
			Remove()
			Return False
		EndIf

		'we manage drawing and updating our background
		If guiBackground and guiBackground.IsEnabled() then guiBackground.Update()

		'deactivate mousehandling for other underlying objects
		GUIManager._ignoreMouse = True
	End Method


	Method DrawBackground()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		local newAlpha:Float = 1.0
		if closeActionStarted
			newAlpha = 1.0 - TInterpolation.Linear(0.0, 1.0, Min(closeActionDuration, Time.GetAppTimeGone() - closeActionTime), closeActionDuration)
		endif
		self.alpha = newAlpha

		SetAlpha(oldColA * alpha * darkenedAreaAlpha)
		SetColor(0, 0, 0)
		If Not DarkenedArea
			DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		Else
			DrawRect(DarkenedArea.getX(), DarkenedArea.getY(), DarkenedArea.getW(), DarkenedArea.getH())
		EndIf
		SetColor(oldCol)
		SetAlpha(oldColA)

		'we manage drawing and updating our background
		If guiBackground and guiBackground.IsEnabled() then guiBackground.Draw()


		Super.DrawBackground()
	End Method


	Method DrawContent()
		if closeActionStarted
			local newAlpha:Float = 1.0 - TInterpolation.Linear(0.0, 1.0, Min(closeActionDuration, Time.GetAppTimeGone() - closeActionTime), closeActionDuration)

			'as text "wobbles" (drawn at INT position while sprites draw
			'with floats - so they seem to change offsets) we fade them
			'out earlier
			if guiCaptionTextBox then guiCaptionTextBox.alpha = 0.5 * newAlpha
			if guiTextBox then guiTextBox.alpha = 0.5 * newAlpha
		endif

		Super.DrawContent()
	End Method
End Type
