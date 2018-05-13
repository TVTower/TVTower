Rem
	===========================================================
	GUI Backgroundbox
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.util.registry.spriteloader.bmx"




Type TGUIBackgroundBox Extends TGUIobject
	Field sprite:TSprite
	Field spriteAlpha:Float = 1.0
	Field spriteBaseName:String = "gfx_gui_panel"
	Field spriteTintColor:TColor


	Method Create:TGUIBackgroundBox(position:TVec2D, dimension:TVec2D, limitState:String="")
		Super.CreateBase(position, dimension, limitState)

		SetZindex(0)
		SetOption(GUI_OBJECT_CLICKABLE, False) 'by default not clickable


		GUIManager.Add(Self)

		Return Self
	End Method


	Method GetPadding:TRectangle()
		'if no manual padding was setup - use sprite padding
		if not _padding then return GetSprite().GetNinePatchContentBorder()
		Return Super.GetPadding()
	End Method


	'acts as cache
	Method GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not sprite or sprite.GetName() <> spriteBaseName
			sprite = GetSpriteFromRegistry(spriteBaseName)
			'new -non default- sprite: adjust appearance
			if sprite.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return sprite
	End Method


	Method DrawContent()
		'
	End Method


	Method DrawBackground()
		Local drawPos:TVec2D = GetScreenPos()
		local oldCol:TColor = new TColor.Get()
		'a local spriteAlpha means widget as "parent" can have alpha 1.0
		'while the sprite is drawn with 0.3
		SetAlpha oldCol.a * GetScreenAlpha() * spriteAlpha
		if spriteTintColor then spriteTintColor.SetRGB()
		GetSprite().DrawArea(drawPos.getX(), drawPos.getY(), GetScreenWidth(), GetScreenHeight())
		oldCol.SetRGBA()
	End Method
End Type
