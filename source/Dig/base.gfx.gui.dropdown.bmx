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
'Import "base.gfx.gui.input.bmx"
Import "base.gfx.gui.button.bmx"
Import "base.gfx.gui.list.selectlist.bmx"


Type TGUIMySelectList extends TGUISelectList

    Method Create:TGUIMySelectList(position:TPoint = null, dimension:TPoint = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method

	Method Draw:int()
		SetColor 255,0,0
		SetAlpha 0.5
		DrawRect(GetContentScreenX(),GetContentScreenY(),2,GetContentScreenHeight())
		DrawRect(GetContentScreenX() + GetContentScreenWidth() - 2,GetContentScreenY(),2,GetContentScreenHeight())
		SetAlpha 1.0
		SetColor 255,255,255

		Super.Draw()
	End Method
End Type



Type TGUIDropDown Extends TGUIButton
	'height of the opened drop down
	Field openHeight:int = 100
	Field open:int = FALSE
	Field list:TGUIMySelectList


    Method Create:TGUIDropDown(position:TPoint = null, dimension:TPoint = null, value:string="", limitState:String = "")
		'setup base widget (button)
		Super.Create(position, dimension, State)

		'=== STYLE BUTTON ===
		'use another sprite than the default button
		spriteName = "gfx_gui_input.default"
'		selectButton.SetOverlayPosition("right")
'		selectButton.SetOverlay("gfx_gui_icon_arrowDown")


		'=== ENTRY LIST ===
		'create and style list
		list = new TGUIMYSelectList.Create(new TPoint.Init(0, self.rect.GetH()), new TPoint.Init(rect.GetW(), 80), "")
		'do not add as child - we position it on our own when updating
		'hide list to begin
		SetOpen(false)


		'=== REGISTER EVENTS ===
		'to close the list automatically if the button or the list
		'looses focus
		EventManager.registerListenerMethod("guiobject.onRemoveFocus", Self, "onRemoveFocus", self )
		EventManager.registerListenerMethod("guiobject.onRemoveFocus", Self, "onRemoveFocus", self.list )
		'to register if an item was selected
		EventManager.registerListenerMethod("guiselectlist.onSelectEntry", self, "onSelectEntry", self.list )

		Return Self
	End Method


	'check if the drop down has to close
	Method onRemoveFocus:int(triggerEvent:TEventBase)
		'skip indeep checks if already closed
		if not IsOpen() then return False

		local sender:TGuiObject = TGUIObject(triggerEvent.GetSender())
		local receiver:TGuiObject = TGUIObject(triggerEvent.GetReceiver())

		'one method to register "clicks":
		rem
		'if the receiver is an entry of the list - close and "click"
		if self.list.HasItem(receiver)
			SetOpen(False)
			print "clicked"
		endif
		endrem

		'skip when loosing focus to self->list or list->self
		if sender = self and receiver = self.list then return False
		if sender = self.list and receiver = self then return False
		'skip if the receiver has a parent which is this button or the list
		if receiver.HasParent(self.list) then return False



		SetOpen(False)
	End Method


	Method onSelectEntry:int(triggerEvent:TEventBase)
		local item:TGUIDropDownItem = TGUIDropDownItem(triggerEvent.GetData().Get("item"))
		'clicked item is of a different type
		if not item then return False
	EndMethod


	'override onClick to add open/close toggle
	Method onClick:int(triggerEvent:TEventBase)
		SetOpen(1- IsOpen())
	End Method


	Method SetOpen:Int(bool:int)
		open = bool
		if open
			print "show list"
			list.Show()
		else
			print "hide list"
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

rem

	'override default method
	Method GetScreenHeight:Float()
		local height:int = Super.GetScreenHeight()
		if IsOpen() then height :+ list.GetScreenHeight()
		return height
	End Method

	'override default method to return a different rect when "open"
	Method GetScreenRect:TRectangle()
		if not IsOpen() then return Super.GetScreenRect()

		return new TRectangle.Init( GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
	End Method
endrem

	'override default update-method
	Method Update:Int()
		Super.Update()

		'move list to our position
		list.rect.position.SetXY( rect.GetX(), rect.GetY() + GetScreenHeight() )

'		list.Update()
		UpdateChildren()
	End Method


	Method Draw()
		SetAlpha 0.5
		DrawRect(GetContentScreenX(),GetContentScreenY(),GetContentScreenWidth(),GetContentScreenHeight())
		SetAlpha 1.0


		Super.Draw()
'		list.Draw()
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