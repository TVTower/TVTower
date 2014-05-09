Rem
	===========================================================
	GUI Button with arrows
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.label.bmx"
Import "base.util.registry.spriteloader.bmx"




Type TGUICheckBox Extends TGUIObject
    Field _checked:Int=False
    Field _showValue:Int=True
    Field checkSprite:TSprite
	Field buttonSprite:TSprite
	Field spriteBaseName:String	= "gfx_gui_icon_check"
	Field spriteButtonBaseName:String = "gfx_gui_button.round"

	Global _typeDefaultFont:TBitmapFont


	Method Create:TGUICheckbox(pos:TPoint, dimension:TPoint, checked:Int=False, labelValue:String, limitState:String="")
		'setup base widget
		Super.CreateBase(pos, dimension, limitState)

		SetZindex(40)
		SetValue(labelValue)
		SetChecked(checked, False) 'without sending events

		'let the guimanager manage the button
		GUIManager.Add(Self)

		Return Self
	End Method


	Method SetChecked:Int(checked:Int=True, informOthers:Int=True)
		'if already same state - do nothing
		If _checked = checked Then Return FALSE

		_checked = checked

		If informOthers Then EventManager.registerEvent(TEventSimple.Create("guiCheckBox.onSetChecked", new TData.AddNumber("checked", checked), Self ) )
	End Method


	Method SetShowValue:Int(bool:Int=True)
		_showValue = bool
	End Method


	'override to use custom global
	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override to use custom global
	Function GetTypeFont:TBitmapFont()
		return _typeDefaultFont
	End Function


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
	Method _GetCheckSprite:TSprite()
		if isChecked()
			'refresh cache if not set or wrong sprite name
			if not checkSprite or checkSprite.GetName() <> spriteBaseName
				checksprite = GetSpriteFromRegistry(spriteBaseName)
			endif
		endif
		return checkSprite
	End Method


	'override so we have a minimum size
	Method Resize(w:Float=Null,h:Float=Null)
		if not w or w < 0 then w = rect.dimension.GetX()
		if not h or h < 0 then h = rect.dimension.GetY()

		'set to minimum size or bigger
		local spriteDimension:TRectangle = _GetButtonSprite().GetNinePatchBorderDimension()
		rect.dimension.setX( Max(w, spriteDimension.GetLeft() + spriteDimension.GetRight()) )
		rect.dimension.sety( Max(h, spriteDimension.GetTop() + spriteDimension.GetBottom()) )
	End Method


	Method IsChecked:Int()
		Return _checked
	End Method


	'override default to (un)check box
	Method onClick:Int(triggerEvent:TEventBase)
		local button:int = triggerEvent.GetData().GetInt("button", -1)
		'only react to left mouse button
		if button <> 1 then return FALSE

		'set box (un)checked
		SetChecked(1-isChecked())
	End Method


	'override default draw-method
	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		Local oldCol:TColor = new TColor.Get()

		SetColor 255, 255, 255
		SetAlpha oldCol.a * alpha

		Local buttonWidth:Int = rect.GetH() 'square...

		'draw button (background)
		_GetButtonSprite().DrawArea(atPoint.getX(), atPoint.getY(), rect.GetW(), rect.GetH())
		'draw checked mark at center of button
		if IsChecked() then _GetCheckSprite().Draw(atPoint.getX() + int(rect.GetW()/2), atPoint.getY() + int(rect.GetH()/2), -1, new TPoint.Init(0.5, 0.5))

		If _showValue
			Local col:TColor = TColor.Create(75,75,75)
			If isChecked() Then col = col.AdjustFactor(-50)
			If mouseover Then col = col.AdjustFactor(-25)

			GetFont().drawStyled(GetFont().FName + " " +value, atPoint.GetX() + buttonWidth + 5, Int(atPoint.GetY() + (GetScreenHeight()- GetFont().GetMaxCharHeight()) / 2) +2, col, 1 )
		EndIf

		oldCol.SetRGBA()
	End Method
End Type
