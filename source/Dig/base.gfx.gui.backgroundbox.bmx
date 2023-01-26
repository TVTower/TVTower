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


	Method GetClassName:String()
		Return "tguibackgroundbox"
	End Method


	Method Create:TGUIBackgroundBox(position:SVec2I, dimension:SVec2I, limitState:String="")
		Super.CreateBase(position, dimension, limitState)

		SetZindex(0)
		SetOption(GUI_OBJECT_CLICKABLE, False) 'by default not clickable


		GUIManager.Add(Self)

		Return Self
	End Method


	Method GetPadding:TRectangle()
		'if no manual padding was setup - use sprite padding
		If Not _padding
			Local s:TSprite = GetSprite()
			if s and s.IsNinePatch()
				Local r:sRect = GetSprite().GetNinePatchInformation().contentBorder
				Return New TRectangle.Init(r.x, r.y, r.w, r.h)
			endif
		EndIf
		Return Super.GetPadding()
	End Method


	'acts as cache
	Method GetSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		If Not sprite Or sprite.GetName() <> spriteBaseName
			sprite = GetSpriteFromRegistry(spriteBaseName)
			'new -non default- sprite: adjust appearance
			If sprite <> TSprite.defaultSprite
				SetAppearanceChanged(True)
			EndIf
		EndIf
		Return sprite
	End Method


	Method DrawContent()
	End Method


	Method DrawBackground()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		'a local spriteAlpha means widget as "parent" can have alpha 1.0
		'while the sprite is drawn with 0.3
		SetAlpha oldColA * GetScreenAlpha() * spriteAlpha
		If spriteTintColor Then spriteTintColor.SetRGB()

		Local r:TRectangle = GetScreenRect()
		GetSprite().DrawArea(r.x, r.y, r.w, r.h)

		SetColor(oldCol)
		SetAlpha(oldColA)
	End Method


	Method UpdateLayout()
	End Method
End Type
