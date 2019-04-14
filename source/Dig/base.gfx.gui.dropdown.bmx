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
End Rem
SuperStrict
Import "base.gfx.gui.input.bmx"
'Import "base.gfx.gui.button.bmx"
Import "base.gfx.gui.list.selectlist.bmx"



Type TGUIDropDown Extends TGUIInput
	Field lastPosition:TVec2D
	'height of the opened drop down
	Field open:int = FALSE
	'close dropdown as soon as an item gets selected
	Field closeOnSelect:int = True
	Field selectedEntry:TGUIObject
	Field list:TGUISelectList
	Field listHeight:int = 100
	Global defaultSpriteName:string = "gfx_gui_input.default"
	Global defaultOverlaySpriteName:string = "gfx_gui_icon_arrowDown"



    Method Create:TGUIDropDown(position:TVec2D = null, dimension:TVec2D = null, value:string="", maxLength:Int=128, limitState:String = "")
		'setup base widget (input)
		Super.Create(position, dimension, value, maxLength, limitState)
		'but this element does not react to keystrokes
		SetOption(GUI_OBJECT_CAN_RECEIVE_KEYSTROKES, False)

		'=== STYLE BUTTON ===
		'use another sprite than the default button
		if not spriteName then spriteName = defaultSpriteName
		SetOverlayPosition("right")
		SetOverlay(defaultOverlaySpriteName)
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
		list.setOption(GUI_OBJECT_IGNORE_PARENTLIMITS, True)
		'avoid auto-sorting dropdown elements by default
		list.SetAutosortItems(False)

		'draw the open list on top of nearly everything
		list.SetZIndex(20000)

		'add bg to list
		local bg:TGUIBackgroundBox = new TGUIBackgroundBox.Create(new TVec2D, new TVec2D)
		bg.spriteBaseName = spriteName
		list.SetBackground(bg)
		'use padding from background
		list.SetPadding(bg.GetPadding().getTop(), bg.GetPadding().getLeft(),  bg.GetPadding().getBottom(), bg.GetPadding().getRight())


		'=== REGISTER EVENTS ===
		'to close the list automatically if the object looses focus
		AddEventListener(EventManager.registerListenerMethod("guiobject.onRemoveFocus", Self, "onRemoveFocus", self ))
		'listen to clicks to dropdown-items
		AddEventListener(EventManager.registerListenerMethod("GUIDropDownItem.onClick",	Self.list, "onClickOnEntry" ))
		'someone uses the mouse wheel to scroll over the panel
		AddEventListener(EventManager.registerListenerFunction( "guiobject.OnScrollwheel", onScrollWheel, Self))

		'to register if an item was selected
		AddEventListener(EventManager.registerListenerMethod("guiselectlist.onSelectEntry", self, "onSelectEntry", self.list ))

		Return Self
	End Method


	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)
		if list then list.Resize(w, -1)
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

			'keep the widgets list "open" if new focus is now at a sub element
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

		if closeOnSelect then SetOpen(0)
	EndMethod


	'override onClick to add open/close toggle
	Method onClick:int(triggerEvent:TEventBase)
		local button:int = triggerEvent.GetData().GetInt("button")

		if button = 1 'left button
			'reset mouse button to avoid clicks below
			MouseManager.ResetKey(1)

			SetOpen(1- IsOpen())
		endif
	End Method


	'handle clicks on the up/down-buttons and inform others about changes
	Function onScrollWheel:Int( triggerEvent:TEventBase )
		Local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If Not dropdown Or value=0 Then Return False

		local newEntryPos:int = -1
		If value >= 1
			newEntryPos = Min(dropdown.list.entries.count()-1, dropdown.GetEntryPos(dropdown.GetSelectedEntry()) + 1)
		else
			newEntryPos = Max(0, dropdown.GetEntryPos(dropdown.GetSelectedEntry()) - 1)
		endif
		dropdown.SetSelectedEntryByPos( newEntryPos )

		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Function


	Method SetSelectedEntry(item:TGUIObject)
		selectedEntry = item
		SetValue(item.GetValue())

		EventManager.triggerEvent( TEventSimple.Create("GUIDropDown.onSelectEntry", null, Self, item) )
	End Method


	Method GetSelectedEntry:TGUIObject()
		return selectedEntry
	End Method


	Method SetSelectedEntryByPos:Int(itemPos:int=0)
		local item:TGUIObject = GetEntryByPos(itemPos)
		if item then SetSelectedEntry(item)
	End Method


	Method GetEntryByPos:TGUIObject(itemPos:int=0)
		local item:TGUIObject = TGUIObject(list.entries.ValueAtIndex(itemPos))
		if not item then return Null

		return Item
	End Method


	Method GetEntryPos:int(entry:TGUIObject)
		if not entry then return -1
		For local i:int = 0 until list.entries.count()
			if entry = TGUIObject(list.entries.ValueAtIndex(i)) then return i
		Next
		return -1
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
			'update z index to be above parent's child widgets
			if GetParent() <> self
				if list.GetZIndex() <= GetZIndex() + 1
					list.SetZIndex( GetZIndex() + 2)
				endif
			endif
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


	Method onStatusAppearanceChange:Int()
		'update list position
		MoveListIntoPosition()
	End Method


	Method MoveListIntoPosition()
		'move list to our position
		local listPosY:int = GetScreenY() + GetScreenHeight()
		'if list ends below screen end we might move it above the button
		if listPosY + list.GetScreenHeight() > GetGraphicsManager().GetHeight()
			if list.GetScreenHeight() < GetScreenY()
				listPosY = GetScreenY() - list.GetScreenHeight()
			endif
		endif
		list.SetPosition( GetScreenX(), listPosY )
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

		'close with right click
		if isOpen() and (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'close the list
			SetOpen(False)
			'remove focus from gui object
			GuiManager.ResetFocus()

			MouseManager.ResetKey(2)
		endif


		local screenPos:TVec2D = GetScreenPos()
		if not lastPosition or not lastPosition.IsSame(screenPos)
			lastPosition = screenPos

			'update list position (as it is not maintained as "child")
			MoveListIntoPosition()
		endif
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
		if not isHovered() and not isSelected() then return


		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		local upperParent:TGUIObject = GetParent("TGUIListBase")
		upperParent.RestrictContentViewPort()

		If isHovered()
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), GetScreenHeight())
			SetColor 255,255,255
		ElseIf isSelected()
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), GetScreenHeight())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf

		upperParent.ResetViewPort()
		oldCol.SetRGBA()
	End Method


	'override onClick to close parental list
	Method OnClick:int(triggerEvent:TEventBase)
		Super.OnClick(triggerEvent)

		local button:int = triggerEvent.GetData().GetInt("button")

		if button = 1 'left button
			'inform others that a dropdownitem was clicked
			'this makes the "dropdownitem-clicked"-event filterable even
			'if the itemclass gets extended (compared to the general approach
			'of "guiobject.onclick")
			EventManager.triggerEvent(TEventSimple.Create("GUIDropDownItem.onClick", new TData.AddNumber("button", button), Self, triggerEvent.GetReceiver()) )
		endif
	End Method


	Method DrawValue()
		GetFont().DrawBlock(value, getScreenX()+2, GetScreenY(), GetScreenWidth()-4, GetScreenHeight(), ALIGN_LEFT_CENTER, valueColor)
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