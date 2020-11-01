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
	Field open:Int = False
	'close dropdown as soon as an item gets selected
	Field closeOnSelect:Int = True
	Field selectedEntry:TGUIObject
	Field list:TGUISelectList
	Field listHeight:Int = 100
	Field automaticListHeight:Int = True
	Field additionalZIndex:Int = 0
	Global defaultSpriteName:String = "gfx_gui_input.default"
	Global defaultOverlaySpriteName:String = "gfx_gui_icon_arrowDown"



	Method GetClassName:String()
		Return "tguidropdown"
	End Method


	Method Create:TGUIDropDown(pos:SVec2I, dimension:SVec2I, value:String="", maxLength:Int=128, limitState:String = "")
		Return Create(new TVec2D.Init(pos.x, pos.y), new TVec2D.Init(dimension.x, dimension.y), value, maxLength, limitState)
	End Method


    Method Create:TGUIDropDown(position:TVec2D = Null, dimension:TVec2D = Null, value:String="", maxLength:Int=128, limitState:String = "")
		'setup base widget (input)
		Super.Create(position, dimension, value, maxLength, limitState)
		'but this element does not react to keystrokes
		SetOption(GUI_OBJECT_CAN_RECEIVE_KEYSTROKES, False)

		'=== STYLE BUTTON ===
		'use another sprite than the default button
		If Not spriteName Then spriteName = defaultSpriteName
		SetOverlayPosition("right")
		SetOverlay(defaultOverlaySpriteName)
		SetEditable(False)


		'=== ENTRY LIST ===
		'create and style list
		If list Then list.Remove()
		list = New TGUISelectList.Create(New TVec2D.Init(0, Self.rect.GetH()), New TVec2D.Init(rect.GetW(), listHeight), "")
		'do not add as child - we position it on our own when updating
		'hide list to begin
		SetOpen(False)

		'set the list to ignore focus requests (avoids onRemoveFocus-events)
		list.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
		'list ignores screen limits of parents ("overflow")
		list.setOption(GUI_OBJECT_IGNORE_PARENTLIMITS, True)
		'avoid auto-sorting dropdown elements by default
		list.SetAutosortItems(False)

		'draw the open list on top of nearly everything
		list.SetZIndex(20000)

		'add bg to list
		Local bg:TGUIBackgroundBox = New TGUIBackgroundBox.Create(New TVec2D, New TVec2D)
		bg.spriteBaseName = spriteName
'		bg.SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)
		list.SetBackground(bg)
		'use padding from background
		list.SetPadding(bg.GetPadding().getTop(), bg.GetPadding().getLeft(),  bg.GetPadding().getBottom(), bg.GetPadding().getRight())

		list.OnResize()

		'=== REGISTER EVENTS ===
		'to close the list automatically if the object looses focus
		AddEventListener(EventManager.registerListenerMethod("guiobject.onRemoveFocus", Self, "onRemoveFocus", Self))
		'listen to clicks to dropdown-items
		AddEventListener(EventManager.registerListenerMethod("GUIDropDownItem.onClick",	Self.list, "onClickOnEntry"))
		'someone uses the mouse wheel to scroll over the panel
		AddEventListener(EventManager.registerListenerFunction("guiobject.OnScrollwheel", onScrollWheel, Self))

		'to register if an item was selected
		AddEventListener(EventManager.registerListenerMethod("guiselectlist.onSelectEntry", Self, "onSelectEntry", Self.list))

		Return Self
	End Method


	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)
		If list Then list.SetSize(w, -1)
	End Method


	Method Remove:Int()
		Super.Remove()
		If list Then list.Remove()
	End Method


	'override
	Method OnUpdateScreenRect()
		Super.OnUpdateScreenRect()
		If list Then list.InvalidateScreenRect()
'		if list then list.InvalidateLayout()
	End Method


	'check if the drop down has to close
	Method onRemoveFocus:Int(triggerEvent:TEventBase)
		'skip indeep checks if already closed
		If Not IsOpen() Then Return False

		Local sender:TGuiObject = TGUIObject(triggerEvent.GetSender())
		Local receiver:TGuiObject = TGUIObject(triggerEvent.GetReceiver())
		If Not sender Then Return False

		Rem
		'if the receiver is an entry of the list - close and "click"
		if self.list.HasItem(receiver)
			SetOpen(False)
		endif
		EndRem
		'close on click on a list item
		If receiver And list.HasItem(receiver)
			'emit an emulated click event so that the list item
			'can handle the click accordingly (eg inform GUI Manager)
			receiver.OnClick( TEventSimple.Create("emulatedClick", New TData.AddNumber("button", 1), Self, triggerEvent.GetReceiver()) )
			SetSelectedEntry(receiver)

			'handled mouse button click to avoid clicks below
			GUIManager.UpdateState_foundClickedObject[1] = receiver
			MouseManager.SetClickHandled(1)
			MouseManager.ResetClicked(1)
			SetOpen(False)
		EndIf


		'skip when loosing focus to self->list or list->self
		If receiver
			Local senderBelongsToWidget:Int = False
			Local receiverBelongsToWidget:Int = False

			If sender = Self
				senderBelongsToWidget = True
			ElseIf sender.HasParent(Self.list)
				senderBelongsToWidget = True
			EndIf

			If senderBelongsToWidget And receiver
				If receiver = Self
					receiverBelongsToWidget = True
				ElseIf receiver.HasParent(Self.list)
					receiverBelongsToWidget = True
				EndIf
			EndIf

			'keep the widgets list "open" if new focus is now at a sub element
			'of the widget
			If senderBelongsToWidget And receiverBelongsToWidget Then Return False
		EndIf


		SetOpen(False)
	End Method


	Method onSelectEntry:Int(triggerEvent:TEventBase)
		Local guiobj:TGUIObject = TGUIObject(triggerEvent.GetData().Get("entry"))

		Local item:TGUIDropDownItem = TGUIDropDownItem(triggerEvent.GetData().Get("entry"))
		'clicked item is of a different type
		If Not item Then Return False

		SetSelectedEntry(item)

		If closeOnSelect Then SetOpen(0)
	EndMethod


	'override onClick to add open/close toggle
	Method onClick:Int(triggerEvent:TEventBase)
		Local button:Int = triggerEvent.GetData().GetInt("button")

		If button = 1 'left button
			'handled mouse button click to avoid clicks below
			MouseManager.SetClickHandled(1)

			SetOpen(1- IsOpen())
		EndIf
	End Method


	'handle mousewheel right on the drop down "input" (not the list)
	Function onScrollWheel:Int( triggerEvent:TEventBase )
		Local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If Not dropdown Or value=0 Then Return False

		Local newEntryPos:Int = -1
		If value >= 1
			newEntryPos = Min(dropdown.list.entries.count()-1, dropdown.GetEntryPos(dropdown.GetSelectedEntry()) + 1)
		Else
			newEntryPos = Max(0, dropdown.GetEntryPos(dropdown.GetSelectedEntry()) - 1)
		EndIf
		dropdown.SetSelectedEntryByPos( newEntryPos )

		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Function
	
	
	Method RefreshValue()
		If selectedEntry
			SetValue(selectedEntry.GetValue())
		Else
			SetValue("")
		EndIf
	End Method
	

	Method SetSelectedEntry(item:TGUIObject)
		selectedEntry = item
		
		RefreshValue()

		EventManager.triggerEvent( TEventSimple.Create("GUIDropDown.onSelectEntry", Null, Self, item) )
	End Method


	Method GetSelectedEntry:TGUIObject()
		Return selectedEntry
	End Method


	Method SetSelectedEntryByPos:Int(itemPos:Int=0)
		Local item:TGUIObject = GetEntryByPos(itemPos)
		If item Then SetSelectedEntry(item)
	End Method


	Method GetEntryByPos:TGUIObject(itemPos:Int=0)
		Local item:TGUIObject = TGUIObject(list.entries.ValueAtIndex(itemPos))
		If Not item Then Return Null

		Return Item
	End Method


	Method GetEntryPos:Int(entry:TGUIObject)
		If Not entry Then Return -1
		For Local i:Int = 0 Until list.entries.count()
			If entry = TGUIObject(list.entries.ValueAtIndex(i)) Then Return i
		Next
		Return -1
	End Method


	Method GetEntries:TList()
		Return list.entries
	End Method
	
	
	Method GetAutoSizeListContentHeight:Int()
		'up to 3 items as default
		local height:Int = 0
		local itemCount:Int = list.entries.count()

		For local i:int = 0 until 3
			if itemCount <= i then exit

			local item:TGUIObject = TGUIObject(list.entries.ValueAtIndex(i))
			height :+ item.GetHeight()
		Next
		
		return height
	End Method
	

	'sets the height of the lists content area (ignoring padding)
	Method SetListContentHeight:Int(height:Float)
		'automatic mode?
		if height < 0
			automaticListHeight = True
			height = GetAutoSizeListContentHeight()
		else
			automaticListHeight = False
		endif
		
		listHeight = height + list.GetPadding().GetTop() + list.GetPadding().GetBottom()
		list.SetSize(list.rect.GetW(), listHeight)
	End Method


	'sets the height of the lists content area to X times of the Nth
	'element
	Method SetListContentHeight:Int(itemCount:int, referenceListItemIndex:Int)
		if not list then return False
		if not list.entries then return False
		
		'keep current
		if list.entries.count() = 0 Then return False
		'fall back to entry 0 if requesting an invalid item
		if list.entries.count() <= referenceListItemIndex Then referenceListItemIndex = 0

		local item:TGUIObject = TGUIObject(list.entries.ValueAtIndex(referenceListItemIndex))
		SetListcontentHeight(itemCount * item.GetHeight())
	End Method


	Method SetOpen:Int(bool:Int)
		open = bool
		If open
			'update z index to be above parent's child widgets
			If _parent
'				if list.GetZIndex() <= GetZIndex() + 1
				If GetZIndex() <= _parent.GetZIndex() + 1
					SetZIndex( GetZIndex() + 2)
					additionalZIndex = 2
					'OnChildZIndexChanged()
				EndIf
			EndIf
			list.Show()
		Else
			If _parent
				If GetZIndex() > _parent.GetZIndex() + 1
				'if list.GetZIndex() > GetZIndex() + 1
					SetZIndex( GetZIndex() - additionalZIndex)
					additionalZIndex = 0
					'OnChildZIndexChanged()
				EndIf
			EndIf

			list.Hide()
		EndIf
	End Method


	Method IsOpen:Int()
		Return open
	End Method


	Method AddItem:Int(item:TGUIDropDownItem)
		If Not list Then Return False
	
		list.AddItem(item)

		if automaticListHeight
			local autoHeight:Int = GetAutoSizeListContentHeight()
			if autoHeight > 0
				SetListContentHeight( autoHeight )
				'restore
				automaticListHeight = True
			endif
		endif
	End Method


	Method onStatusAppearanceChange:Int()
		'update list position
		MoveListIntoPosition()
	End Method


	Method MoveListIntoPosition()
		'move list to our position
		Local listPosY:Int = GetScreenRect().GetY2()
		'if list ends below screen end we might move it above the button
		If listPosY + list.GetScreenRect().GetH() > GetGraphicsManager().GetHeight()
			If list.GetScreenRect().GetH() < GetScreenRect().GetY()
				listPosY = GetScreenRect().GetY() - list.GetScreenRect().GetH()
			EndIf
		EndIf
		list.SetPosition( GetScreenRect().GetX(), listPosY )
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'if the list is open, an "escape" is used to "abort the action"
		If isOpen() And KeyManager.IsHit(KEY_ESCAPE)
			'do not allow another ESC-press for 250ms
			KeyManager.blockKey(KEY_ESCAPE, 250)
			'close the list
			SetOpen(False)
			'remove focus from gui object
			GuiManager.ResetFocus()
		EndIf

		'close with right click
		If isOpen() And (MouseManager.IsClicked(2) Or MouseManager.IsLongClicked(1))
			'close the list
			SetOpen(False)
			'remove focus from gui object
			GuiManager.ResetFocus()

			'avoid clicks
			'remove right click - to avoid leaving the room
			MouseManager.ResetClicked(2)
			'also avoid long click (touch screen)
			MouseManager.ResetLongClicked(1)
		EndIf


		Local screenPos:TVec2D = GetScreenRect().position
		If Not lastPosition Or Not lastPosition.IsSame(GetScreenRect().position)
			If Not lastPosition Then lastPosition = New TVec2D
			lastPosition.CopyFrom( GetScreenRect().position )

			'update list position (as it is not maintained as "child")
			MoveListIntoPosition()
		EndIf
	End Method
End Type




'as it is similar to a list - extend from a list item
'using "TGUISelectListItem" provides ability to easily
'add them to the list contained in TGUIDropDown
Type TGUIDropDownItem Extends TGUISelectListItem


	Method GetClassName:String()
		Return "tguidropdownitem"
	End Method


    Method Create:TGUIDropDownItem(position:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		If Not dimension Then dimension = New TVec2D.Init(80,20)

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(position, dimension, "")

		SetValue(value)

		GUIManager.add(Self)

		Return Self
	End Method


	Method DrawBackground()
		If Not isHovered() And Not isSelected() Then Return


		Local oldCol:TColor = New TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		Local upperParent:TGUIObject = TGUIListBase.FindGUIListBaseParent(Self)
		upperParent.RestrictContentViewPort()

		If isHovered()
			SetColor 250,210,100
			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
			SetColor 255,255,255
		ElseIf isSelected()
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf

		upperParent.ResetViewPort()
		oldCol.SetRGBA()
	End Method


	'override onClick to close parental list
	Method OnClick:Int(triggerEvent:TEventBase)
		Super.OnClick(triggerEvent)

		Local button:Int = triggerEvent.GetData().GetInt("button")

		If button = 1 'left button
			'inform others that a dropdownitem was clicked
			'this makes the "dropdownitem-clicked"-event filterable even
			'if the itemclass gets extended (compared to the general approach
			'of "guiobject.onclick")
			EventManager.triggerEvent(TEventSimple.Create("GUIDropDownItem.onClick", New TData.AddNumber("button", button), Self, triggerEvent.GetReceiver()) )

			'we handled it
			Return True
		EndIf

		Return False
	End Method


	Method DrawValue()
		'use rect height as limit as screen rect height might be limited
		local scrRect:TRectangle = GetScreenRect()
		GetFont().DrawBox(value, scrRect.GetX()+2, scrRect.GetY(), rect.GetW()-4, rect.GetH(), sALIGN_LEFT_CENTER, valueColor)
	End Method


	'override to select another parent
	Method GetRestrictingViewPortObject:TGUIObject()
		Return TGUIListBase.FindGUIListBaseParent(Self)
	End Method


	'override
	Method DrawContent()
		If GetScreenRect().GetH() = 0 Or GetScreenRect().GetW() = 0 Then Return
		Local oldCol:TColor = New TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		Local upperParent:TGUIObject = TGUIListBase.FindGUIListBaseParent(Self)
		If upperParent Then upperParent.RestrictContentViewPort()

		DrawValue()

		If upperParent Then	upperParent.ResetViewPort()
		oldCol.SetRGBA()
	End Method
End Type
