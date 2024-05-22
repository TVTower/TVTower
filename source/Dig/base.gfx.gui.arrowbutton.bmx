Rem
	===========================================================
	GUI Button with arrows
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.label.bmx"
Import "base.util.registry.spriteloader.bmx"


Type TGUIArrowButton Extends TGUISpriteButton
    Field direction:String

	Method New()
		spriteBaseName = "gfx_gui_icon_arrow"
	End Method


	Method GetClassName:String()
		Return "tguiarrowbutton"
	End Method


	Method Create:TGUIArrowButton(pos:SVec2I, dimension:SVec2I, direction:String="LEFT", limitState:String = "")
		Super.Create(pos, dimension, spriteBaseName, limitState)

		SetDirection(direction)

		Return Self
	End Method


	'override to add direction
	Method _GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not sprite or sprite.GetName() <> (spriteBaseName + direction)
			sprite = GetSpriteFromRegistry(spriteBaseName + direction)
		endif
		return sprite
	End Method


	Method SetDirection(direction:String="LEFT")
		direction = direction.ToUpper()
		if self.direction = direction then return

		Select direction
			Case "LEFT"		Self.direction="Left"
			Case "UP"		Self.direction="Up"
			Case "RIGHT"	Self.direction="Right"
			Case "DOWN"		Self.direction="Down"
			Default			Self.direction="Left"
		EndSelect

		sprite = null
	End Method
End Type




Type TGUISpriteButton Extends TGUIObject
    Field sprite:TSprite
	Field buttonSprite:TSprite
	Field spriteBaseName:String	= ""
	Field spriteButtonBaseName:String = "gfx_gui_button.round"

	Field spriteButtonOptions:int = SHOW_BUTTON_NORMAL + SHOW_BUTTON_HOVER + SHOW_BUTTON_ACTIVE

	CONST SHOW_BUTTON_NORMAL:int = 1
	CONST SHOW_BUTTON_HOVER:int = 2
	CONST SHOW_BUTTON_ACTIVE:int = 4


	Method Create:TGUISpriteButton(pos:SVec2I, dimension:SVec2I, spriteName:String="", limitState:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, limitState)

		SetSpriteName(spriteName)

		value = ""

		'let the guimanager manage the button
		GUIManager.Add(Self)

		Return Self
	End Method


	Method HasSpriteButtonOption:Int(option:Int)
		Return (spriteButtonOptions & option) <> 0
	End Method


	Method SetSpriteButtonOption(option:Int, enable:Int=True)
		If enable
			spriteButtonOptions :| option
		Else
			spriteButtonOptions :& ~option
		EndIf
	End Method


	Method SetSprite(sprite:TSprite)
		if sprite
			self.sprite = sprite
			self.spriteBaseName = sprite.GetName()
		else
			self.sprite = null
			self.spriteBaseName = ""
		endif
	End Method


	Method SetSpriteName(spriteName:string)
		if self.spriteBaseName <> spriteName
			self.spriteBaseName = spriteName
			'force cache reset
			self.sprite = null
		endif
	End Method


	'override so we have a minimum size
	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0)
		if w <= 0 then w = rect.w
		if h <= 0 then h = rect.h

		'set to minimum size or bigger
		local spriteDimension:SRect = _GetButtonSprite().GetNinePatchInformation().borderDimension
		w = Max(w, spriteDimension.GetLeft() + spriteDimension.GetRight())
		h = Max(h, spriteDimension.GetTop() + spriteDimension.GetBottom())

		Super.SetSize(w, h)
	End Method


	'private getter
	'acts as cache
	Method _GetButtonSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if spriteButtonBaseName
			if not buttonSprite or buttonSprite.GetName() <> (spriteButtonBaseName + self.GetStateSpriteAppendix())
				local newSprite:TSprite = GetSpriteFromRegistry(spriteButtonBaseName + self.GetStateSpriteAppendix(), spriteButtonBaseName)
				if not buttonSprite or newSprite.GetName() <> buttonSprite.GetName()
					buttonSprite = newSprite
					'new image - resize
					SetSize(-1, -1)
				endif
			endif
			return buttonSprite
		else
			return null
		endif
	End Method


	'private getter
	'acts as cache
	Method _GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not sprite or sprite.GetName() <> spriteBaseName
			sprite = GetSpriteFromRegistry(spriteBaseName)
		endif
		return sprite
	End Method


	'override default draw-method
	Method DrawContent()
		Local atPoint:SVec2F = GetScreenRect().GetPosition()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		SetColor 255, 255, 255
		SetAlpha oldColA * GetScreenAlpha()

		'draw button (background)
		local bs:TSprite
		if IsActive()
			if HasSpriteButtonOption(SHOW_BUTTON_ACTIVE) then bs = _GetButtonSprite()
		elseif IsHovered()
			if HasSpriteButtonOption(SHOW_BUTTON_HOVER) then bs = _GetButtonSprite()
		elseif HasSpriteButtonOption(SHOW_BUTTON_NORMAL)
			bs = _GetButtonSprite()
		endif
		if bs then bs.DrawArea(atPoint.x, atPoint.y, rect.w, rect.h)

		'draw arrow at center of button
		_GetSprite().Draw(atPoint.x + int(rect.w/2.0), atPoint.y + int(rect.h/2.0), -1, ALIGN_CENTER_CENTER)

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method


	Method UpdateLayout()
	End Method
End Type
