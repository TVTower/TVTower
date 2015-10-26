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
	Field open:int = FALSE
	Field selectedEntry:TGUIObject
	Field list:TGUISelectList
	Field listHeight:int = 100
	


    Method Create:TGUIDropDown(position:TVec2D = null, dimension:TVec2D = null, value:string="", maxLength:Int=128, limitState:String = "")
		'setup base widget (input)
		Super.Create(position, dimension, value, maxLength, limitState)
		'but this element does not react to keystrokes
		SetOption(GUI_OBJECT_CAN_RECEIVE_KEYSTROKES, False)

		'=== STYLE BUTTON ===
		'use another sprite than the default button
		spriteName = "gfx_gui_input.default"
		SetOverlayPosition("right")
		SetOverlay("gfx_gui_icon_arrowDown")
		SetEditable(False)


		'=== ENTRY LIST ===
		'create and style list
		if list then list.Remove()
		list = new TGUISelectList.Create(new TVec2D.Init(0, self.rect.GetH()), new TVec2D.Init(rect.GetW(), listHeight), "")
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
		local bg:TGUIBackgroundBox = new TGUIBackgroundBox.Create(new TVec2D, new TVec2D)
		bg.spriteBaseName = "gfx_gui_input.default"
		list.SetBackground(bg)
		'use padding from background
		list.SetPadding(bg.GetPadding().getTop(), bg.GetPadding().getLeft(),  bg.GetPadding().getBottom(), bg.GetPadding().getRight())

		'=== REGISTER EVENTS ===
		'to close the list automatically if the budget looses focus
		AddEventListener(EventManager.registerListenerMethod("guiobject.onRemoveFocus", Self, "onRemoveFocus", self ))
		'listen to clicks to dropdown-items
		AddEventListener(EventManager.registerListenerMethod("GUIDropDownItem.onClick",	Self.list, "onClickOnEntry" ))

		'to register if an item was selected
		AddEventListener(EventManager.registerListenerMethod("guiselectlist.onSelectEntry", self, "onSelectEntry", self.list ))

		Return Self
	End Method


	Method Remove:int()
		Super.Remove()
		list.Remove()
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
			EventManager.triggerEvent( TEventSimple.Create("GUIDropDown.onSelectEntry", null, Self, receiver) )
			SetSelectedEntry(receiver)

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

		SetSelectedEntry(item)
		'inform others: we successfully selected an item
		EventManager.triggerEvent( TEventSimple.Create("GUIDropDown.onSelectEntry", null, Self, item) )
	EndMethod


	'override onClick to add open/close toggle
	Method onClick:int(triggerEvent:TEventBase)
		'reset mouse button to avoid clicks below
		MouseManager.ResetKey(1)

		SetOpen(1- IsOpen())
	End Method


	Method SetSelectedEntry(item:TGUIObject)
		selectedEntry = item
		SetValue(item.GetValue())
	End Method


	Method GetSelectedEntry:TGUIObject()
		return selectedEntry
	End Method


	Method SetSelectedEntryByPos:Int(itemPos:int=0)
		local item:TGUIObject = GetSelectedEntryByPos(itemPos)
		if item then SetSelectedEntry(item)
	End Method


	Method GetSelectedEntryByPos:TGUIObject(itemPos:int=0)
		local item:TGUIObject = TGUIObject(list.entries.ValueAtIndex(itemPos))
		if not item then return Null

		return Item
	End Method


	Method GetEntries:TList()
		return list.entries
	End Method


	'sets the height of the lists content area (ignoring padding)
	Method SetListContentHeight:int(height:Float)
		list.Resize(list.rect.GetW(), height + list.GetPadding().GetTop() + list.GetPadding().GetBottom())
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

		'if the list is open, an "escape" is used to "abort the action"
		if isOpen() and KeyManager.IsHit(KEY_ESCAPE)
			'do not allow another ESC-press for 250ms
			KeyManager.blockKey(KEY_ESCAPE, 250)
			'close the list
			SetOpen(False)
			'remove focus from gui object
			GuiManager.ResetFocus()
		endif
		

		'move list to our position
		local listPosY:int = GetScreenY() + GetScreenHeight()
		'if list ends below screen end we might move it above the button
		if listPosY + list.GetScreenHeight() > GetGraphicsManager().GetHeight()
			if list.GetScreenHeight() < GetScreenY()
				listPosY = GetScreenY() - list.GetScreenHeight()
			endif
		endif
		list.rect.position.SetXY( GetScreenX(), listPosY )
	End Method
End Type




'as it is similar to a list - extend from a list item
'using "TGUISelectListItem" provides ability to easily
'add them to the list contained in TGUIDropDown
Type TGUIDropDownItem Extends TGUISelectListItem


    Method Create:TGUIDropDownItem(position:TVec2D=null, dimension:TVec2D=null, value:String="")
		if not dimension then dimension = new TVec2D.Init(80,20)

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



	Method DrawBackground()
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
	End Method


	'override onClick to close parental list
	Method OnClick:int(triggerEvent:TEventBase)
		Super.OnClick(triggerEvent)
		'inform others that a dropdownitem was clicked
		'this makes the "dropdownitem-clicked"-event filterable even
		'if the itemclass gets extended (compared to the general approach
		'of "guiobject.onclick")
		EventManager.triggerEvent(TEventSimple.Create("GUIDropDownItem.onClick", null, Self, triggerEvent.GetReceiver()) )
	End Method


	Method DrawValue()
		GetFont().draw(value, getScreenX(), Int(GetScreenY() + 2 + 0.5*(rect.getH()- GetFont().getHeight(value))), valueColor)
	End Method


	'override to select another parent
	Method GetRestrictingViewPortObject:TGUIObject()
		return GetParent("TGUIListBase")
	End Method


	'override
	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		local upperParent:TGUIObject = GetParent("TGUIListBase")
		upperParent.RestrictContentViewPort()

		DrawValue()

		upperParent.ResetViewPort()
		oldCol.SetRGBA()
	End Method
End Type