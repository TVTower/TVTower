Rem
	===========================================================
	GUI Button with arrows
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.label.bmx"
Import "base.util.registry.spriteloader.bmx"



Type TGUIArrowButton Extends TGUIObject
    Field direction:String
    Field arrowSprite:TSprite
	Field buttonSprite:TSprite
	Field spriteBaseName:String	= "gfx_gui_icon_arrow"
	Field spriteButtonBaseName:String = "gfx_gui_button.round"


	Method Create:TGUIArrowButton(pos:TVec2D, dimension:TVec2D, direction:String="LEFT", limitState:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, limitState)

		SetDirection(direction)
'		setZindex(40)
		value = ""

		'let the guimanager manage the button
		GUIManager.Add(Self)

		Return Self
	End Method


	Method SetDirection(direction:String="LEFT")
		Select direction.ToUpper()
			Case "LEFT"		Self.direction="Left"
			Case "UP"		Self.direction="Up"
			Case "RIGHT"	Self.direction="Right"
			Case "DOWN"		Self.direction="Down"
			Default			Self.direction="Left"
		EndSelect
	End Method


	'override so we have a minimum size
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		if w <= 0 then w = rect.dimension.GetX()
		if h <= 0 then h = rect.dimension.GetY()

		'set to minimum size or bigger
		local spriteDimension:TRectangle = _GetButtonSprite().GetNinePatchBorderDimension()
		rect.dimension.setX( Max(w, spriteDimension.GetLeft() + spriteDimension.GetRight()) )
		rect.dimension.sety( Max(h, spriteDimension.GetTop() + spriteDimension.GetBottom()) )
	End Method


	'private getter
	'acts as cache
	Method _GetButtonSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not buttonSprite or buttonSprite.GetName() <> (spriteButtonBaseName + self.state)
			local newSprite:TSprite = GetSpriteFromRegistry(spriteButtonBaseName + self.state, spriteButtonBaseName)
			if not buttonSprite or newSprite.GetName() <> buttonSprite.GetName()
				buttonSprite = newSprite
				'new image - resize
				Resize()
			endif
		endif
		return buttonSprite
	End Method


	'private getter
	'acts as cache
	Method _GetArrowSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not arrowSprite or arrowSprite.GetName() <> (spriteBaseName + direction)
			arrowSprite = GetSpriteFromRegistry(spriteBaseName + direction)
		endif
		return arrowSprite
	End Method


	'override default draw-method
	Method DrawContent()
		Local atPoint:TVec2D = GetScreenPos()
		Local oldCol:TColor = new TColor.Get()

		SetColor 255, 255, 255
		SetAlpha oldCol.a * GetScreenAlpha()

		'draw button (background)
		_GetButtonSprite().DrawArea(atPoint.getX(), atPoint.getY(), rect.GetW(), rect.GetH())
		'draw arrow at center of button
		_GetArrowSprite().Draw(atPoint.getX() + int(rect.GetW()/2), atPoint.getY() + int(rect.GetH()/2), -1, new TVec2D.Init(0.5, 0.5))

		oldCol.SetRGBA()
	End Method
End Type