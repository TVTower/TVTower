Rem
	====================================================================
	GUI Window
	====================================================================

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015-now Ronny Otto, digidea.de

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
Import "base.gfx.gui.panel.bmx"


Type TGUIWindowBase Extends TGUIPanel
	Field guiCaptionTextBox:TGUITextBox
	Field guiCaptionArea:TRectangle
	'this panel can contain additional content (buttons, panels....)
	Field guiContent:TGUIPanel
	Global defaultCaptionColor:TColor = null


	Method Create:TGUIWindowBase(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		'create background, setup text etc.
		InitWindow(dimension)

		guiTextBoxAlignment = ALIGN_LEFT_TOP

		GUIManager.Add(Self)
		Return Self
	End Method


	'override to delete additional widgets too
	Method Remove:Int() override
		Super.Remove()

		if guiCaptionTextBox then guiCaptionTextBox.Remove()

		return True
	End Method


	Method InitWindow(dimension:SVec2I)
		If Not guiBackground
			SetBackground( new TGUIBackgroundBox.Create(null, null) )
		Else
			guiBackground.rect.SetXY(0,0)
			guiBackground.SetSize(dimension.x, dimension.y)
		EndIf

		'set another panel background
		guiBackground.spriteBaseName = "gfx_gui_window"

		SetCaption("Window")
		guiCaptionTextBox.SetFont( GetBitmapFont("Default", 16, BOLDFONT) )

		guiBackground.SetParent(self)
		'background has same zindex like window
		guiBackground.SetZIndex(-1)
		'caption uses automatic zindex (+1 to parent)
		guiCaptionTextBox.SetZIndex(0)
	End Method


	'returns the content panel to add content too
	'content panel gets created if not done yet
	Method GetGuiContent:TGUIPanel()
		if not guiContent
			Local screenRectDim:SVec2F = GetContentScreenRect().GetDimension()
			guiContent = new TGUIPanel.Create(new SVec2I(0,0), new SVec2I(Int(screenRectDim.x), Int(screenRectDim.y)), "")
			AddChild(guiContent)
		endif

		return guiContent
	End Method


	'override to add guiContent-resizing
	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)
	End Method


	'override
	Method UpdateLayout()
		Super.UpdateLayout()

		'resize content (if exists) to use all available content space
		If guiContent
			local contentScreenRect:TRectangle = GetContentScreenRect()
			'content element is aligned according to padding setup, so 0,0
			'is ok
			guiContent.SetPosition(0,0)
			guiContent.SetSize(contentScreenRect.GetW(), contentScreenRect.GetH())
		EndIf


		if guiCaptionTextBox
			Local rX:Float = -1
			Local rY:Float = -1
			Local rW:Float = -1
			Local rH:Float = -1
			'if an area was defined - use as much values of this as
			'possible
			If guiCaptionArea
				if guiCaptionArea.x <> -1 then rX = guiCaptionArea.x
				if guiCaptionArea.y <> -1 then rY = guiCaptionArea.y
				if guiCaptionArea.w <> -1 then rW = guiCaptionArea.w
				if guiCaptionArea.h <> -1 then rH = guiCaptionArea.h
			EndIf

			'calculation of undefined/automatic values
			'vertical center the caption between 0 and the start of
			'content but to make it visible in all cases use "max(...)".
			if guiBackground
				Local padding:SRect = guiBackground.GetSprite().GetNinePatchInformation().contentBorder
				if rX = -1 then rX = padding.GetLeft()
				if rY = -1 then rY = 0
				if rW = -1 then rW = GetContentScreenRect().w
				if rH = -1 then rH = Max(25, padding.GetTop())
			else
				if rX = -1 then rX = 0
				if rY = -1 then rY = 0
				if rW = -1 then rW = GetContentScreenRect().w
				if rH = -1 then rH = 25
			endif


			'reposition in all cases
			guiCaptionTextBox.rect.SetXY(rX, rY)
			guiCaptionTextBox.SetSize(rW, rH)
		endif
	End Method


	Method SetCaptionArea(area:TRectangle)
		guiCaptionArea = area.copy()
	End Method


	Method SetCaption:Int(caption:String="")
		If caption=""
			If guiCaptionTextBox
				guiCaptionTextBox.remove()
				guiCaptionTextBox = Null
			EndIf
		Else
			If Not guiCaptionTextBox
				'create the caption container
				guiCaptionTextBox = New TGUITextBox.Create(new SVec2I(0,0), GUI_DIM_AUTOSIZE, caption, "")

				If defaultCaptionColor
					guiCaptionTextBox.SetValueColor(defaultCaptionColor)
				Else
					guiCaptionTextBox.SetValueColor(TColor.clWhite)
				EndIf
				guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_CENTER )
				guiCaptionTextBox.SetAutoAdjustHeight(False)
				guiCaptionTextBox.SetZIndex(1)
				'set to ignore parental padding (so it starts at 0,0)
				guiCaptionTextBox.SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)

				'we handle it
				addChild(guiCaptionTextBox)
			EndIf

			'assign new caption
			guiCaptionTextBox.value = caption

			'manually call reposition function
			InvalidateLayout()
		EndIf
	End Method


	Method SetCaptionAndValue:Int(caption:String="", value:String="")
		Local oldTextboxHeight:Float = GetContentScreenRect().GetH()

		SetCaption(caption)
		SetValue(value)

		'resize window
		if guiTextBox
			if guiTextBox.getHeight() - GetContentScreenRect().GetH() > 0
				Self.SetSize(0, GetScreenRect().GetH() + Max(guiTextBox.GetScreenRect().GetH(), guiTextBox.getHeight()) - GetContentScreenRect().GetH())
			else
				Self.SetSize(0, GetScreenRect().GetH() + guiTextBox.getHeight() - GetContentScreenRect().GetH() + 4)
			endif
		else
			Self.SetSize(0, rect.getH())
		endif

		Return True
	End Method
End Type
