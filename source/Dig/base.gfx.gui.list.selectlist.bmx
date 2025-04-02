Rem
	====================================================================
	GUI Select List
	====================================================================

	Code contains:
	- TGUISelectList: list allowing to select a specific item
	- TGUISelectListItem: selectable list item


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
Import "base.gfx.gui.list.base.bmx"



Type TGUISelectList Extends TGUIListBase
	Field selectedEntry:TGUIobject = Null
	Field selectionChangedTime:Long


	Method GetClassName:String()
		Return "tguiselectlist"
	End Method


	Method Create:TGUISelectList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'register listeners in a central location
		RegisterListeners()

		Return Self
	End Method


	Method Remove:Int()
		Super.Remove()
		If selectedEntry
			selectedEntry.Remove()
			selectedEntry = Null
		EndIf
	End Method


	'overrideable
	Method RegisterListeners:Int()
		'we want to know about clicks
		AddEventListener(EventManager.registerListenerMethod(GUIEventKeys.GUIListItem_OnClick,	Self, "onClickOnEntry"))
	End Method


	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUIListItem = TGUIListItem( triggerEvent.getSender() )
		If Not entry Then Return False

		'ignore entries of other lists
		If entry._parent <> Self.guiEntriesPanel Then Return False

		'default to left button if nothing was sent
		Local button:Int = triggerEvent.GetData().GetInt("button", 1)
		If button = 1
			SelectEntry(entry)
		EndIf
		
		Return True
	End Method


	Method SelectEntry:Int(entry:TGUIObject)
		'only mark selected if we are owner of that entry
		If Self.HasItem(entry)
			Local oldEntry:TGUIObject = self.selectedEntry
			'remove old entry
			Self.deselectEntry()
			Self.selectedEntry = entry
			Self.selectedEntry.SetSelected(True)
			Self.selectionChangedTime = Time.GetTimeGone()
			'inform others: we successfully selected an item
			TriggerBaseEvent(GUIEventKeys.GUISelectList_OnSelectEntry, Null, Self, entry)
			If oldEntry <> entry
				TriggerBaseEvent(GUIEventKeys.GUISelectList_OnSelectionChanged, New TData.Add("previousSelection", oldEntry), Self, entry)
			EndIf
		EndIf
	End Method


	Method DeselectEntry:Int()
		If TGUIListItem(selectedEntry)
			TGUIListItem(selectedEntry).SetSelected(False)
			selectedEntry = Null
			selectionChangedTime = Time.GetTimeGone()
		EndIf
	End Method


	Method GetSelectedEntry:TGUIobject()
		Return selectedEntry
	End Method


	Method ScrollToSelectedItem()
		local item:TGUIObject = GetSelectedEntry()
		if item Then ScrollToItem(item)
	End Method


	Method ScrollAndSelectItem(item:TGUIObject, alignment:Float = 0.5)
		ScrollToItem(item, alignment)
		SelectEntry(item)
	End Method


	Method ScrollAndSelectItem(index:Int, alignment:Float = 0.5)
		ScrollAndSelectItem( GetItemAtIndex(index), alignment )
	End Method
	
	
	Method OnResize(dW:Float, dH:Float) override
		Super.OnResize(dW, dH)

'		InvalidateContentScreenRect()
'		InvalidateLayout()
		UpdateLayout()
		
		EnsureEntryIsVisible(GetSelectedEntry())
	End Method
	

	Method HandleKeyboardScrolling() override	
		Local oldScrollPercentageX:Float = GetScrollPercentageX()
		Local oldScrollPercentageY:Float = GetScrollPercentageY()
		
		'use "IsPressedKey()" to not alter pressed-state
		Local doDown:Int = KeyWrapper.IsPressed(KEY_DOWN)
		Local doUp:Int = KeyWrapper.IsPressed(KEY_UP)

		Super.HandleKeyboardScrolling()
		
		If doDown
			'scroll back
			'SetScrollPercentageY(oldScrollPercentageY)

			Local focusItem:TGUIObject = GetSelectedEntry()
			If Not focusItem
				focusItem = GetItemAtIndex(0)
			Else
				Local currentIndex:Int = GetItemIndex(focusItem)
				focusItem = GetItemAtIndex(currentIndex + 1)				
			EndIf
			If focusItem
				SelectEntry(focusItem)
				EnsureEntryIsVisible(focusItem)
			EndIf
		ElseIf doUp
			'scroll back
			'SetScrollPercentageY(oldScrollPercentageY)

			Local focusItem:TGUIObject = GetSelectedEntry()
			If Not focusItem
				focusItem = GetItemAtIndex(0)
			Else
				local currentIndex:Int = GetItemIndex(focusItem)
				focusItem = GetItemAtIndex(currentIndex - 1)				
			EndIf
			If focusItem
				SelectEntry(focusItem)
				EnsureEntryIsVisible(focusItem)
			EndIf
		EndIf
	End Method
End Type




Type TGUISelectListItem Extends TGUIListItem


	Method GetClassName:String()
		Return "tguiselectlistitem"
	End Method


    Method Create:TGUISelectListItem(position:SVec2I, dimension:SVec2I, value:String="")
		If dimension.x = 0 and dimension.y = 0 Then dimension = New SVec2I(80,20)

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(position, dimension, "")

		SetValue(value)

		GUIManager.add(Self)

		Return Self
	End Method


	Method DrawBackground()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		Local useAlpha:Float = oldColA * GetScreenAlpha()
	
		'available width is parentsDimension minus startingpoint
		'Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		Local maxWidth:Int = GetScreenRect().GetW()
		If isHovered()
			SetAlpha useAlpha
			SetColor 250,210,100
			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), maxWidth, GetScreenRect().GetH())
		ElseIf isSelected()
			SetColor 250,210,100
			SetAlpha useAlpha * 0.5
			DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), maxWidth, GetScreenRect().GetH())
		EndIf

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method


	Method DrawContent()
		DrawValue()
	End Method


	Method Draw()
		If Not isDragged()
			'this allows to use a list in a modal dialogue
			Local upperParent:TGUIObject = TGUIListBase.FindGUIListBaseParent(Self)
			If upperParent Then upperParent.RestrictViewPort()

			Super.Draw()

			If upperParent Then upperParent.ResetViewPort()
		Else
			Super.Draw()
		EndIf
	End Method


	Method UpdateLayout()
	End Method
End Type
