Rem
	====================================================================
	GUI DropDown classes
	====================================================================

	Code contains:
	- TGUIDropDown: widget showing - on click - a list to select from
	- TGUIDropDownItem: item of a drop down widget

	The dropdown widget is grouping multiple objects together. Utilizing
	a button and a select list which is hidden until activation


	====================================================================
	LICENCE

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
End Rem
SuperStrict
Import "base.gfx.gui.input.bmx"
'Import "base.gfx.gui.button.bmx"
Import "base.gfx.gui.list.selectlist.bmx"



Type TGUIDropDown Extends TGUIInput
	'height of the opened drop down
	Field openHeight:int = 100
	Field open:int = FALSE
	Field list:TGUISelectList


    Method Create:TGUIDropDown(position:TPoint = null, dimension:TPoint = null, value:string="", maxLength:Int=128, limitState:String = "")
		'setup base widget (button)
		Super.Create(position, dimension, value, maxLength, State)

		'=== STYLE BUTTON ===
		'use another sprite than the default button
		spriteName = "gfx_gui_input.default"
		SetOverlayPosition("right")
		SetOverlay("gfx_gui_icon_arrowDown")
		SetEditable(False)


		'=== ENTRY LIST ===
		'create and style list
		list = new TGUISelectList.Create(new TPoint.Init(0, self.rect.GetH()), new TPoint.Init(rect.GetW(), 80), "")
		'do not add as child - we position it on our own when updating
		'hide list to begin
		SetOpen(false)

		'set the list to ignore focus requests (avoids onRemoveFocus-events)
		list.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
		'list ignores screen limits of parents ("overflow")
		list.setOption(GUI_OBJECT_IGNORE_PARENTLIMITS, TRUE)

		'draw the open list on top of nearly everything
		list.SetZIndex(20000)

		'add bg to list
		local bg:TGUIBackgroundBox = new TGUIBackgroundBox.Create(new TPoint, new TPoint)
		bg.spriteBaseName = "gfx_gui_input.default"
		list.SetBackground(bg)
		'use padding from background
		list.SetPadding(bg.GetPadding().getTop(), bg.GetPadding().getLeft(),  bg.GetPadding().getBottom(), bg.GetPadding().getRight())

		'=== REGISTER EVENTS ===
		'to close the list automatically if the budget looses focus
		AddEventListener(EventManager.registerListenerMethod("guiobject.onRemoveFocus", Self, "onRemoveFocus", self ))
		'listen to clicks to dropdown-items
		AddEventListener(EventManager.registerListenerMethod( "guiobject.onClick",	Self.list, "onClickOnEntry", "TGUIDropDownItem" ))

		'to register if an item was selected
		AddEventListener(EventManager.registerListenerMethod("guiselectlist.onSelectEntry", self, "onSelectEntry", self.list ))

		Return Self
	End Method


	'check if the drop down has to close
	Method onRemoveFocus:int(triggerEvent:TEventBase)
		'skip indeep checks if already closed
		if not IsOpen() then return False

		local sender:TGuiObject = TGUIObject(triggerEvent.GetSender())
		local receiver:TGuiObject = TGUIObject(triggerEvent.GetReceiver())
		if not sender then return False

		Rem
		'if the receiver is an entry of the list - close and "click"
		if self.list.HasItem(receiver)
			SetOpen(False)
			print "clicked"
		endif
		EndRem

		'close on click on a list item
		if receiver and list.HasItem(receiver)
			SetValue(receiver.GetValue())

			'reset mouse button to avoid clicks below
			MouseManager.ResetKey(1)

			SetOpen(False)
		endif


		'skip when loosing focus to self->list or list->self
		if receiver
			local senderBelongsToWidget:int = False
			local receiverBelongsToWidget:int = False

			if sender = self
				senderBelongsToWidget = True
			elseif sender.HasParent(self.list)
				senderBelongsToWidget = True
			endif

			if senderBelongsToWidget and receiver
				if receiver = self
					receiverBelongsToWidget = True
				elseif receiver.HasParent(self.list)
					receiverBelongsToWidget = True
				endif
			endif

			'keep the widgets list "open" if ne focus is now at a sub element
			'of the widget
			if senderBelongsToWidget and receiverBelongsToWidget then return False
		endif


		SetOpen(False)
	End Method


	Method onSelectEntry:int(triggerEvent:TEventBase)
		local guiobj:TGUIObject = TGUIObject(triggerEvent.GetData().Get("entry"))

		local item:TGUIDropDownItem = TGUIDropDownItem(triggerEvent.GetData().Get("entry"))
		'clicked item is of a different type
		if not item then return False

		SetValue(item.GetValue())
	EndMethod


	'override onClick to add open/close toggle
	Method onClick:int(triggerEvent:TEventBase)
		'reset mouse button to avoid clicks below
		MouseManager.ResetKey(1)

		SetOpen(1- IsOpen())
	End Method


	Method SetOpen:Int(bool:int)
		open = bool
		if open
			list.Show()
		else
			list.Hide()
		endif
	End Method


	Method IsOpen:Int()
		return open
	End Method


	Method AddItem:Int(item:TGUIDropDownItem)
		if not list then return false

		list.AddItem(item)
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'move list to our position
		list.rect.position.SetXY( GetScreenX(), GetScreenY() + GetScreenHeight() )
'RON
'		UpdateChildren()
	End Method


	Method Draw()
		Super.Draw()
rem
		if open
			SetAlpha 1.0
			SetColor 100,0,0
			DrawRect(list.GetContentScreenX(),list.GetContentScreenY()+100,list.GetContentScreenWidth(), list.GetContentScreenHeight())
			SetColor 255,255,255
			DrawRect(list.guiEntriesPanel.GetContentScreenX(),list.guiEntriesPanel.GetContentScreenY()+150,list.guiEntriesPanel.GetContentScreenWidth(), list.guiEntriesPanel.GetContentScreenHeight())
			SetAlpha 1.0
		endif
endrem
'RON
'		DrawChildren()
	End Method
End Type




'as it is similar to a list - extend from a list item
'using "TGUISelectListItem" provides ability to easily
'add them to the list contained in TGUIDropDown
Type TGUIDropDownItem Extends TGUISelectListItem


    Method Create:TGUIDropDownItem(position:TPoint=null, dimension:TPoint=null, value:String="")
		if not dimension then dimension = new TPoint.Init(80,20)

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(position, dimension, "")

		SetValue(value)

		GUIManager.add(Self)

		Return Self
	End Method


	Method GetScreenWidth:Float()
		local listParent:TGUIListBase = TGUIListBase(GetParent("TGUIListBase"))
		if not listParent or not listParent.guiEntriesPanel
			Return GetParent().GetScreenWidth()
		else
			Return listParent.guiEntriesPanel.GetContentScreenWidth()
		endif
	End Method


	Method Draw:Int()
		local oldCol:TColor = new TColor.Get()
		local upperParent:TGUIObject = GetParent("TGUIListBase")
		upperParent.RestrictContentViewPort()

		If mouseover
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), rect.getH())
			SetColor 255,255,255
		ElseIf selected
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), rect.getH())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf
		'draw value
		GetFont().draw(value, getScreenX(), Int(GetScreenY() + 2 + 0.5*(rect.getH()- GetFont().getHeight(value))), valueColor)

		upperParent.ResetViewPort()
		oldCol.SetRGBA()
	End Method
End Type