Rem
	====================================================================
	GUI Window
	====================================================================
	
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
End Rem
SuperStrict
Import "base.gfx.gui.panel.bmx"


Type TGUIWindowBase Extends TGUIPanel
	Field guiCaptionTextBox:TGUITextBox
	Field guiCaptionArea:TRectangle
	'this panel can contain additional content (buttons, panels....)
	Field guiContent:TGUIPanel
	Global defaultCaptionColor:TColor = null


	Method Create:TGUIWindowBase(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		'create background, setup text etc.
		InitWindow(dimension)

		guiTextBoxAlignment = ALIGN_LEFT_TOP

		GUIManager.Add(Self)
		Return Self
	End Method


	'override to delete children too
	Method Remove:Int()
		Super.Remove()

		if guiCaptionTextBox then guiCaptionTextBox.Remove()

		return True
	End Method
	

	Method InitWindow(dimension:TVec2D)
		If Not guiBackground
			SetBackground( new TGUIBackgroundBox.Create(null, null) )
		Else
			guiBackground.rect.position.SetXY(0,0)
			guiBackground.resize(dimension.GetX(), dimension.GetY())
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
			guiContent = new TGUIPanel.Create(new TVec2D, new TVec2D.Init(GetContentScreenWidth(), GetContentScreenHeight()), "")
			AddChild(guiContent)
		endif

		return guiContent
	End Method


	'override to add guiContent-resizing
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)

		'resize content (if exists) to use all available content space
		If guiContent
			guiContent.SetPosition(0,0)
			guiContent.resize(GetContentScreenWidth(),GetContentScreenHeight())
		EndIf
	End Method



	'overwrite default to reapply caption/value to reposition them
	Method onStatusAppearanceChange:int()
		if guiCaptionTextBox
			Local rect:TRectangle = new TRectangle.Init(-1,-1,-1,-1)
			'if an area was defined - use as much values of this as
			'possible
			If guiCaptionArea
				if guiCaptionArea.position.x <> -1 then rect.position.x = guiCaptionArea.position.x
				if guiCaptionArea.position.y <> -1 then rect.position.y = guiCaptionArea.position.y
				if guiCaptionArea.dimension.x <> -1 then rect.dimension.x = guiCaptionArea.dimension.x
				if guiCaptionArea.dimension.y <> -1 then rect.dimension.y = guiCaptionArea.dimension.y
			EndIf

			'calculation of undefined/automatic values
			'vertical center the caption between 0 and the start of
			'content but to make it visible in all cases use "max(...)".
			Local padding:TRectangle
			if guiBackground
				padding = guiBackground.GetSprite().GetNinePatchContentBorder()
			else
				padding = new TRectangle.Init()
			endif
			if rect.position.x = -1 then rect.position.x = padding.GetLeft()
			if rect.position.y = -1 then rect.position.y = 0
			if rect.dimension.x = -1 then rect.dimension.x = GetContentScreenWidth()
			if rect.dimension.y = -1 then rect.dimension.y = Max(25, padding.GetTop())


			'reposition in all cases
			guiCaptionTextBox.rect.position.SetXY(rect.GetX(), rect.GetY())
			guiCaptionTextBox.resize(rect.GetW(), rect.GetH())
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
				guiCaptionTextBox = New TGUITextBox.Create(new TVec2D, new TVec2D, caption, "")

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
			onStatusAppearanceChange()
		EndIf
	End Method


	Method SetCaptionAndValue:Int(caption:String="", value:String="")
		Local oldTextboxHeight:Float = GetContentScreenHeight()

		SetCaption(caption)
		SetValue(value)

		'resize window
		if guiTextBox
			if guiTextBox.getHeight() - GetContentScreenHeight() > 0
				Self.resize(0, GetScreenHeight() + Max(guiTextBox.GetScreenHeight(), guiTextBox.getHeight()) - GetContentScreenHeight())
			else
				Self.resize(0, GetScreenHeight() + guiTextBox.getHeight() - GetContentScreenHeight() + 4)
			endif
		else
			Self.resize(0, rect.getH())
		endif

		Return True
	End Method
End Type