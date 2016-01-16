Rem
	====================================================================
	GUI Select List
	====================================================================

	Code contains:
	- TGUISelectList: list allowing to select a specific item
	- TGUISelectListItem: selectable list item


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
Import "base.gfx.gui.list.base.bmx"



Type TGUISelectList Extends TGUIListBase
	Field selectedEntry:TGUIobject = Null


    Method Create:TGUISelectList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'register listeners in a central location
		RegisterListeners()

		Return Self
	End Method


	Method Remove:int()
		Super.Remove()
		if selectedEntry
			selectedEntry.Remove()
			selectedEntry = null
		endif
	End Method


	'overrideable
	Method RegisterListeners:Int()
		'we want to know about clicks
		AddEventListener(EventManager.registerListenerMethod("GUIListItem.onClick",	Self, "onClickOnEntry"))
	End Method


	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUIListItem = TGUIListItem( triggerEvent.getSender() )
		If Not entry Then Return False

		SelectEntry(entry)
	End Method


	Method SelectEntry:Int(entry:TGUIListItem)
		'only mark selected if we are owner of that entry
		If Self.HasItem(entry)
			'remove old entry
			Self.DeselectEntry()
			Self.selectedEntry = entry
			print "select"
			If TGUIListItem(Self.selectedEntry) Then TGUIListItem(Self.selectedEntry).SetSelected(True)

			'inform others: we successfully selected an item
			EventManager.triggerEvent( TEventSimple.Create( "GUISelectList.onSelectEntry", new TData.Add("entry", entry) , Self ) )
		EndIf
	End Method
	

	Method DeselectEntry:Int()
		If TGUIListItem(selectedEntry)
			print "deselect"
			TGUIListItem(selectedEntry).SetSelected(False)
		EndIf
		selectedEntry = Null
	End Method


	Method getSelectedEntry:TGUIobject()
		Return selectedEntry
	End Method
End Type




Type TGUISelectListItem Extends TGUIListItem
    Method Create:TGUISelectListItem(position:TVec2D=null, dimension:TVec2D=null, value:String="")
   		Super.Create(position, dimension, "")
		'revert dragable
		SetOption(GUI_OBJECT_DRAGABLE, False)

		Return Self
	End Method


	Method DrawBackground()
		local oldCol:TColor = new TColor.Get()

		'available width is parentsDimension minus startingpoint
		Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		If isHovered()
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), maxWidth, getScreenHeight())
			SetColor 255,255,255
		ElseIf isSelected()
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), maxWidth, getScreenHeight())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf

		oldCol.SetRGBA()
	End Method


	Method DrawValue()
		'draw value
		GetFont().draw(value, Int(GetScreenX() + 5), Int(GetScreenY() + 2 + 0.5*(rect.getH()- GetFont().getHeight(Self.value))), valueColor)
	End Method


	Method DrawContent()
		DrawValue()
	End Method

	
	Method Draw()
		if not isDragged()
			'this allows to use a list in a modal dialogue
			local upperParent:TGUIObject = TGUIListBase.FindGUIListBaseParent(self)
			if upperParent then upperParent.RestrictViewPort()

			Super.Draw()

			if upperParent then upperParent.ResetViewPort()
		else
			Super.Draw()
		endif
	End Method
End Type




Type TGUICustomSelectListItem Extends TGUISelectListItem
	'allow custom functions to get hooked in
	Field _customDraw:int(obj:TGUIObject)
	Field _customDrawValue:int(obj:TGUIObject)
	Field _customDrawBackground:int(obj:TGUIObject)


    Method Create:TGUICustomSelectListItem(position:TVec2D=null, dimension:TVec2D=null, value:String="")
   		Super.Create(position, dimension, value)
		Return Self
	End Method


	Method DrawBackground()
		if _customDrawBackground
			_customDrawBackground(self)
		else
			Super.DrawBackground()
		endif
	End Method


	Method DrawValue()
		if _customDrawValue
			_customDrawValue(self)
		else
			Super.DrawValue()
		endif
	End Method


	Method Draw()
		if _customDraw
			_customDraw(self)
		else
			Super.Draw()
		endif
	End Method
End Type