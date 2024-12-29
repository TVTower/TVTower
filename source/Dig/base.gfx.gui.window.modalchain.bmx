Rem
	====================================================================
	GUI Modal Window Chain
	====================================================================

	a modal window with chained content (different "pages")

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015 Ronny Otto, digidea.de

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
EndRem
SuperStrict
Import "base.util.virtualgraphics.bmx"
Import "base.util.interpolation.bmx"
Import "base.util.graphicsmanagerbase.bmx"
Import "base.gfx.gui.button.bmx"
Import "base.gfx.gui.input.bmx"
Import "base.gfx.gui.list.selectlist.bmx"
Import "base.gfx.gui.window.modal.bmx"


Type TGUIModalWindowChain Extends TGUIObject
	Field DarkenedArea:TRectangle = Null
	'the area the window centers to
	Field screenArea:TRectangle = Null
	Field autoAdjustHeight:Int = True
	Field activeChainElement:TGUIModalWindowChainElement
	'limits of top/left/right/bottom which should not get passed
	Field centerLimit:TRectangle = null
	'=== CLOSING VARIABLES ===
	'indicator if currently closing
	Field closeActionStarted:Long = 0
	'the time a close action started
	Field closeActionTime:Long = 0
	'the time a close action runs
	Field closeActionDuration:int = 650
	'the position of the widget when closing
	Field closeActionStartPosition:TVec2D = new TVec2D


	Method GetClassName:String()
		Return "tguimodalwindowchain"
	End Method


	Method Create:TGUIModalWindowChain(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)
		setZIndex(10000)
		setOption(GUI_OBJECT_CLICKABLE, False)

		GuiManager.Add(self)

		Return Self
	End Method


	Method Initialize:int()
		closeActionStarted = 0
		closeActionTime = 0
	End Method


	Method Remove:int()
		Super.Remove()
		if activeChainElement then activeChainElement.Remove()
		activeChainElement = null
	End Method


	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)
		Recenter()
	End Method


	'overwrite windowBase-method to recenter after appearance change
	Method onAppearanceChanged:int()
		Super.onAppearanceChanged()
		Recenter()
	End Method


	Method SetScreenArea:int(area:TRectangle)
		screenArea = area.Copy()
		Recenter()
	End Method


	Method SetDarkenedArea:int(area:TRectangle)
		darkenedArea = area.Copy()
		Recenter()
	End Method


	Method SetCenterLimit:int(area:TRectangle)
		centerLimit = area.Copy()
		Recenter()
	End Method


	'override
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
		if centerLimit
			centerX = MathHelper.Clamp(centerX, centerLimit.GetLeft() + rect.GetW()/2, GetGraphicsManager().GetWidth() - centerLimit.GetRight() - rect.GetW()/2)
			centerY = MathHelper.Clamp(centerY, centerLimit.GetTop() + rect.GetH()/2, GetGraphicsManager().GetHeight() - centerLimit.GetBottom() - rect.GetH()/2)
		endif

		SetPosition(centerX - rect.getW()/2 + moveByX, centerY - rect.getH()/2 + moveByY)


		'inform element
		if activeChainElement then activeChainElement.onRecenter()
	End Method


	Method SetContentElement:int(element:TGUIModalWindowChainElement)
		if activeChainElement
			activeChainElement.SetParent(null)
			GuiManager.Remove(activeChainElement)

			'remove the element if it is not the "previous one"
			'if activeChainElement <> element.previousChainElement
			'	activeChainElement.Remove()
			'endif
		endif

		if element
			'resize to dimensions of the content element
			SetSize(element.GetScreenRect().GetW(), element.GetScreenRect().GetH())
			'maybe change the size of the element too?
			element.SetSize(-1,-1)
		endif

		activeChainElement = element
		activeChainElement.SetParent(self)
		'inform
		activeChainElement.Activate()

		'we handle it now
		GUIManager.Remove(element)

		'set to new center
		Recenter()
	End Method


	Method Back:int()
		if not activeChainElement or not activeChainElement.Back()
			Close(-1)
			return False
		endif

		return True
	End Method


	Method Open:Int()
		TriggerBaseEvent(GUIEventKeys.GUIModalWindowChain_OnOpen, Self)
	End Method


	'close the window (eg. with an animation)
	Method Close:Int(closeButton:Int=-1)
		'only close once :D
		if closeActionStarted then return False

		closeActionStarted = True
		closeActionTime = Time.GetAppTimeGone()
		closeActionStartPosition = new TVec2D(rect.x, rect.y)

		'fire event so others know that the window is closed
		'and what button was used
		TriggerBaseEvent(GUIEventKeys.GUIModalWindowChain_OnClose, new TData.Add("closeButton", closeButton) , Self)
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


	Method SetClosed:int()
		closeActionStarted = True
		closeActionTime = Time.GetAppTimeGone() - closeActionDuration
	End Method


	Method IsClosed:int()
		return closeActionStarted and closeActionTime + closeActionDuration < Time.GetAppTimeGone()
	End Method


	Method IsClosing:int()
		return closeActionStarted
	End Method
	
	
	Method HandleKeyboard() override
		If Not IsClosing()
			If Not GuiManager.GetKeyboardInputReceiver() 
				'abort/cancel
				If KeyManager.IsHit(KEY_ESCAPE)
					'do not allow another ESC-press for X ms
					if activeChainElement and activeChainElement.previousChainElement
						KeyManager.blockKey(KEY_ESCAPE, 350)
					else
						KeyManager.blockKey(KEY_ESCAPE, 250)
					endif
					self.Back()
				EndIf
			EndIf
		EndIf
	End Method


	'override default update-method
	Method Update:Int()
		if activeChainElement then activeChainElement.Update()

		'maybe children intercept clicks...
		'so call Super.Update as it calls UpdateChildren already
		Super.Update()

		'remove the window as soon as there is no animation active
		'until then: play the animation
		If IsClosed()
			Self.remove()
			Return False
		EndIf


		'deactivate mousehandling for other underlying objects
		GUIManager._ignoreMouse = True
	End Method


	Method DrawContent()
		local oldCol:SColor8; GetColor(oldCol)
		local oldColA:Float = GetAlpha()
		SetAlpha oldColA * GetScreenAlpha()
		local newAlpha:Float = 1.0

		if closeActionStarted
			local yUntilScreenLeft:int = VirtualHeight() - (closeActionStartPosition.y + GetScreenRect().GetH())
			newAlpha = 1.0 - TInterpolation.Linear(0.0, 1.0, Min(closeActionDuration, Time.GetAppTimeGone() - closeActionTime), closeActionDuration)
			Recenter(0, - yUntilScreenLeft * Float(TInterpolation.BackIn(0.0, 1.0, Min(closeActionDuration, Time.GetAppTimeGone() - closeActionTime), closeActionDuration)))
		endif

		self.alpha = newAlpha

		SetAlpha(oldColA * alpha * 0.5)
		SetColor(0, 0, 0)
		If Not DarkenedArea
			DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		Else
			DrawRect(DarkenedArea.getX(), DarkenedArea.getY(), DarkenedArea.getW(), DarkenedArea.getH())
		EndIf
		SetColor(oldCol)
		SetAlpha(oldColA)

		if activeChainElement then activeChainElement.Draw()
	End Method


	Method UpdateLayout()
	End Method
End Type




Type TGUIModalWindowChainElement Extends TGUIWindowBase
	Field previousChainElement:TGUIModalWindowChainElement


	Method GetClassName:String()
		Return "tguimodalwindowchainelement"
	End Method


	Method Create:TGUIModalWindowChainElement(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		setZIndex(10001)

		'avoid auto handling
		RemoveChild(guiBackground)

		Return Self
	End Method


	Method GetZIndex:int() 'override
		'be at least above parent
		if _parent and _parent <> self then return Max(Super.GetZIndex(), _parent.GetZindex() + 1)

		Return Super.GetZIndex()
	End Method


	Method Remove:Int()
		Super.Remove()
		'unlink, so we do not get circular references
		previousChainElement = null
	End Method


	'called when set as active content of a container
	Method Activate:int()
	End Method


	Method Back:int()
		if previousChainElement
			SwitchActive(previousChainElement)
			return True
		endif

		return False
	End Method


	Method Close:int(closeButton:Int=-1)
		local p:TGUIModalWindowChain = TGUIModalWindowChain(_parent)
		if not p
			print "Cannot Close(), parent is not of type TGUIModalWindowChain"
			return false
		endif
		p.Close(closeButton)
		return true
	End Method


	Method SwitchActive:int(otherElement:TGUIModalWindowChainElement)
		local p:TGUIModalWindowChain = TGUIModalWindowChain(_parent)
		if not p
			print "Cannot SwitchActive(), parent is not of type TGUIModalWindowChain"
			return false
		endif

		p.SetContentElement(otherElement)

		return true
	End Method


	Method onRecenter()
		InvalidateScreenRect()
	End Method


	Method Update:int()
		Super.Update()
		guiBackground.Update()
	End Method


	Method DrawBackground()
		guiBackground.Draw()
	End Method
End Type




Type TGUIModalWindowChainDialogue extends TGUIModalWindowChainElement
	Field dialogueButtons:TGUIButton[]


	Method GetClassName:String()
		Return "tguimodalwindowchaindialogue"
	End Method


	Method Create:TGUIModalWindowChainDialogue(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		'by default just a "ok" button
		SetDialogueType(1)

'		guiBackground.spriteBaseName = "gfx_gui_modalWindow"

		'we want to know if one clicks on a windows buttons
		AddEventListener(EventManager.registerListenerMethod(GUIEventKeys.GUIButton_OnClick, Self, "onButtonClick", "tguibutton"))
		return self
	End Method


	'easier setter for dialogue types
	Method SetDialogueType:Int(typeID:Int)
		'remove old buttons
		For Local button:TGUIobject = EachIn dialogueButtons
			button.remove()
			'RemoveChild(button)
		Next
		dialogueButtons = New TGUIButton[0] '0 sized array

		'create new ones
		Select typeID
			'a default button
			Case 1
				dialogueButtons = dialogueButtons[..1]
				dialogueButtons[0] = New TGUIButton.Create(New SVec2I(0,0), New SVec2I(120,-1), GetLocale("OK"))
				AddChild(dialogueButtons[0])
				'set to ignore parental padding (so it starts at 0,0)
				dialogueButtons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
			'yes and no button
			Case 2
				dialogueButtons = dialogueButtons[..2]
				dialogueButtons[0] = New TGUIButton.Create(New SVec2I(0,0), new SVec2I(Int(GetContentScreenRect().w / 2 - 10), -1), GetLocale("YES"))
				dialogueButtons[1] = New TGUIButton.Create(New SVec2I(0,0), new SVec2I(Int(GetContentScreenRect().w / 2 - 10), -1), GetLocale("NO"))
				AddChild(dialogueButtons[0])
				AddChild(dialogueButtons[1])
				'set to ignore parental padding (so it starts at 0,0)
				dialogueButtons[0].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
				dialogueButtons[1].SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
		End Select
		
		MoveDialogueButtonsIntoPosition()
	End Method


	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)
		
		MoveDialogueButtonsIntoPosition()
	End Method
	
	
	Method MoveDialogueButtonsIntoPosition()
		'move button
		If dialogueButtons.length = 1
			dialogueButtons[0].SetPosition(rect.GetW()/2 - dialogueButtons[0].rect.GetW()/2, GetScreenRect().GetH() - 50)
		ElseIf dialogueButtons.length = 2
			dialogueButtons[0].SetPosition(rect.GetW()/2 - dialogueButtons[0].rect.GetW() - 10, GetScreenRect().GetH() - 50)
			dialogueButtons[1].SetPosition(rect.GetW()/2 + 10, GetScreenRect().GetH() - 50)
		EndIf
	End Method
	

	Method GetSelectedButtonIndex:Int()
		For Local i:Int = 0 To Self.dialogueButtons.length - 1
			If Self.dialogueButtons[i].IsSelected() Then Return i
		Next
		Return -1
	End Method
	
	
	Method CanSelectButton:int(index:Int)
		If index >= 0 And index <= Self.dialogueButtons.length - 1
			If Self.dialogueButtons[index].IsEnabled()
				Return True
			EndIf
		EndIf
		Return False
	End Method
	
	
	Method SelectButton:Int(index:Int)
		Local selectedSomething:Int
		Local lastSelected:Int = GetSelectedButtonIndex()

		If lastSelected <> index
			'select new (if possible)
			If index >= 0 And index <= Self.dialogueButtons.length - 1
				If Not Self.dialogueButtons[index].IsEnabled()
					'cannot set a disabled as selected
					'... ignore request for now
				Else
					Self.dialogueButtons[index].SetSelected(True)
					selectedSomething = True
				EndIf
			EndIf

			'deselect old (if new is selected - or deselection is requested)
			If selectedSomething Or index = -1 
				If lastSelected <> -1 And Self.dialogueButtons[lastSelected].IsSelected()
					Self.dialogueButtons[lastSelected].SetSelected(False)
				EndIf
			EndIf
		EndIf
		
		Return selectedSomething
	End Method


	Method ClickButton:Int(index:Int)
		if index < 0 or index >= self.dialogueButtons.length Then Return False
		
		Return self.dialogueButtons[index].Click(EGUIClickType.KEYBOARD, KEY_ENTER)
	End Method


	Method Update:int() override
		Super.Update()

		HandleKeyboard()
	End Method


	Method HandleKeyboard() override
		If Not GuiManager.GetKeyboardInputReceiver() 
			'tab through buttons?
			If KeyManager.IsHit(KEY_TAB)
				'do not allow another Tab-press for X ms
				KeyManager.blockKey(KEY_TAB, 250)
				If KeyManager.IsDown(KEY_LSHIFT) or KeyManager.IsDown(KEY_RSHIFT)
					SelectButton((GetSelectedButtonIndex() + Self.dialogueButtons.length - 1) mod Self.dialogueButtons.length)
				Else
					SelectButton((GetSelectedButtonIndex() + 1) mod Self.dialogueButtons.length)
				EndIf
			ElseIf KeyManager.IsHit(KEY_LEFT)
				KeyManager.blockKey(KEY_LEFT, 250)
				SelectButton( (GetSelectedButtonIndex() + Self.dialogueButtons.length - 1) mod Self.dialogueButtons.length)
			ElseIf KeyManager.IsHit(KEY_UP)
				KeyManager.blockKey(KEY_UP, 250)
				SelectButton( (GetSelectedButtonIndex() + Self.dialogueButtons.length - 1) mod Self.dialogueButtons.length)
			ElseIf KeyManager.IsHit(KEY_RIGHT)
				KeyManager.blockKey(KEY_RIGHT, 250)
				SelectButton( (GetSelectedButtonIndex() + 1) mod Self.dialogueButtons.length)
			ElseIf KeyManager.IsHit(KEY_DOWN)
				KeyManager.blockKey(KEY_DOWN, 250)
				SelectButton( (GetSelectedButtonIndex() + 1) mod Self.dialogueButtons.length)
			EndIf
		EndIf
	End Method
	

	'handle clicks on the various close buttons
	Method onButtonClick:Int( triggerEvent:TEventBase )
		Local sender:TGUIButton = TGUIButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		For Local i:Int = 0 until dialogueButtons.length
			If dialogueButtons[i] <> sender Then Continue
			Back()
		Next
	End Method
End Type
