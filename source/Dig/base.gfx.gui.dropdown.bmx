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
Import "base.gfx.gui.list.selectlist.bmx"




Type TGUIDropDown Extends TGUIObject
	'height of the opened drop down
	Field openHeight:int = 100
	Field open:int = FALSE
	Field selectButton:TGUIInput
	Field list:TGUISelectList
	'use another sprite than the default button
	'global selectButtonSpriteNameDefault:String = "gfx_gui_input.default"


    Method Create:TGUIDropDown(position:TPoint = null, dimension:TPoint = null, limitState:String = "")
		'setup base widget
		Super.CreateBase(position, dimension, State)

		'elements added with "addChild" have their position as "offset",
		'so "0,0" means right at the top left spot of the dropdown

		'create and style button
		selectButton = new TGUIInput.Create(new TPoint.Init(0,0), new TPoint.Init(dimension.GetX(), -1), "", -1, "")
		selectButton.SetOverlayPosition("right")
		selectbutton.SetEditable(False)
		selectButton.SetOverlay("gfx_gui_icon_arrowDown")

		'selectButton.spriteName = self.selectButtonSpriteNameDefault
		self.AddChild(selectButton)

		'create and style list
		list = new TGUISelectList.Create(new TPoint.Init(0, selectButton.rect.GetH()), new TPoint.Init(rect.GetW(), 80), "")
		self.AddChild(list)
		'hide list to begin
		SetOpen(false)

		'set self not clickable so mouse can reach child elements
		SetOption(GUI_OBJECT_CLICKABLE, False)


		'register to get informed about clicks on the selectbutton
		EventManager.RegisterListenerMethod("guiobject.onclick", self, "onClickSelectButton", selectButton)

		GUIManager.Add(Self)
		Return Self
	End Method


	Method onClickSelectButton:int(triggerEvent:TEventBase)
		'not interested in other than my button
		if selectButton <> triggerEvent.GetSender() then return FALSE

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


	'overwrite default method
	Method GetScreenHeight:Float()
		if open then Return openHeight
		return Super.GetScreenHeight()
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()
		UpdateChildren()
	End Method

rem
	'override default update-method
	Method Update:Int()
		Super.Update()

        If Not(Self._flags & GUI_OBJECT_ENABLED) Then Self.mouseIsClicked = Null

		If Not Self.hasFocus() Or Not Self.mouseIsDown Then Return False

		Local currentAddY:Int = Self.rect.GetH() 'ignore "if open"
		Local lineHeight:Float = Assets.GetSprite("gfx_gui_dropdown_list_entry.L").area.GetH()*Self.scale

		'reset hovered item id ...
		Self.hoveredEntryID = -1

		'check new hovered or clicked items
		For Local Entry:TGUIEntry = EachIn Self.EntryList 'Liste hier global
			If TFunctions.MouseIn( Self.GetScreenX(), Self.GetScreenY() + currentAddY, Self.GetScreenWidth(), lineHeight)
				If MOUSEMANAGER.IsHit(1)
					value			= Entry.getValue()
					clickedEntryID	= Entry.id
		'			GUIManager.setActive(0)
					EventManager.registerEvent( TEventSimple.Create( "guiobject.OnChange", new TData.AddNumber("entryID", entry.id), Self ) )
					'threadsafe?
					MOUSEMANAGER.ResetKey(1)
					Exit
				Else
					hoveredEntryID	= Entry.id
				EndIf
			EndIf
			currentAddY:+ lineHeight
		Next
		'store height if opened
		Self.heightIfOpen = Self.rect.GetH() + currentAddY


		If hoveredEntryID > 0
			Self.setState("hover")
		Else
			'clicked outside of list
			'Print "RONFOCUS: clicked outside of list, remove focus from "+Self._id
			If MOUSEMANAGER.IsHit(1) Then GUIManager.setFocus(Null)
		EndIf
	End Method
endrem


	Method Draw()
		DrawChildren()
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


	Method Draw:Int()
		local oldCol:TColor = new TColor.Get()
		local upperParent:TGUIObject = GetUppermostParent()
		upperParent.RestrictViewPort()

		'available width is parentsDimension minus startingpoint
		Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text


		If mouseover
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), maxWidth, rect.getH())
			SetColor 255,255,255
		ElseIf selected
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), maxWidth, rect.getH())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf

		'draw value
		GetFont().draw(value, Int(GetScreenX() + 5), Int(GetScreenY() + 2 + 0.5*(rect.getH()- GetFont().getHeight(Self.value))), valueColor)

		upperParent.ResetViewPort()
		oldCol.SetRGBA()
	End Method
End Type