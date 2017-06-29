Rem
	===========================================================
	GUI Button with arrows
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.button.bmx"
Import "base.util.registry.spriteloader.bmx"


Type TGUICheckBox Extends TGUIButton
    Field checked:Int = False
    Field checkSprite:TSprite
	Field checkSpriteName:String = "gfx_gui_icon_check"
	Field checkboxDimension:TVec2D
	Field checkboxDimensionAutocalculated:int = True
	Field valueChecked:string = ""
	Field valueUnchecked:string = ""
	Field captionDisplacement:TVec2D = new TVec2D.Init(5,0)
	
	Global _checkboxMinDimension:TVec2D = new TVec2D.Init(20,20)
	Global _typeDefaultFont:TBitmapFont


	Method Create:TGUICheckbox(pos:TVec2D, dimension:TVec2D, value:String, limitState:String="")
		'use another sprite name (assign before initing super)
		spriteName = "gfx_gui_button.round"

		SetCaptionValues(value,value)

		Super.Create(pos, dimension, value, limitState)

		return self
	End Method


	Method SetCaptionValues:Int(checkedValue:string, uncheckedValue:string)
		self.valueChecked = checkedValue
		self.valueUnchecked = uncheckedValue

		if self.caption then setValue(GetValue())
	End Method


	Method SetChecked:Int(checked:Int=True, informOthers:Int=True)
		'if already same state - do nothing
		If self.checked = checked Then Return FALSE

		self.checked = checked

		If informOthers then EventManager.triggerEvent(TEventSimple.Create("guiCheckBox.onSetChecked", new TData.AddNumber("checked", checked), Self ) )
	End Method


	Method IsChecked:Int()
		Return checked
	End Method


	'override to get value depending on checked state
	Method GetValue:String()
		if IsChecked() then return valueChecked
		return valueUnchecked
	End Method


	Method SetCheckboxDimension:int(dimension:TVec2D)
		if not dimension
			checkboxDimension = null
			checkboxDimensionAutocalculated = True
		else
			checkboxDimension = dimension.copy()
			checkboxDimensionAutocalculated = False
		endif
	End Method


	Method GetCheckboxDimension:TVec2D()
		if not checkboxDimension
			local dim:TRectangle = GetSprite().GetNinePatchBorderDimension()
			checkboxDimension = new TVec2D.Init(..
				Max(_checkboxMinDimension.x, dim.GetLeft() + dim.GetRight()), ..
				Max(_checkboxMinDimension.y, dim.GetTop() + dim.GetBottom()) ..
			)
		endif
		return checkboxDimension
	End Method


	Function SetTypeFont:Int(font:TBitmapFont)
		_typeDefaultFont = font
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		return _typeDefaultFont
	End Function


	'override for a differing alignment
	Method SetCaption:Int(text:String, color:TColor=Null)
		Super.SetCaption(text, color)


		'only overwrite this values if they weren't set yet
		if valueChecked = "" and valueUnchecked = ""
			valueChecked = text
			valueUnchecked = text
		endif
		
		
		if caption
			caption.SetContentPosition(ALIGN_LEFT, ALIGN_TOP)
			caption.SetValueEffect(1, 0.2)
			caption.SetValueColor(TColor.CreateGrey(120))
		endif
	End Method


	Method ShowCaption:Int(bool:Int=True)
		if bool
			caption.Show()
		else
			caption.Hide()
		endif
	End Method
	

	'private getter
	'acts as cache
	Method GetCheckSprite:TSprite()
		if isChecked()
			'refresh cache if not set or wrong sprite name
			if not checkSprite or checkSprite.GetName() <> checkSpriteName
				checksprite = GetSpriteFromRegistry(checkSpriteName)
			endif
		endif
		return checkSprite
	End Method


	'override default to add checkbox+caption
	Method GetScreenWidth:float()
		if caption
			return GetCheckboxDimension().x + caption.rect.position.x + caption.GetValueDimension().x
		else
			return GetCheckboxDimension().x
		endif
	End Method


	'override default to add checkbox+caption
	Method GetScreenHeight:float()
		if caption
			return Max(GetCheckboxDimension().y, caption.rect.position.y + caption.GetValueDimension().y)
		else
			return GetCheckboxDimension().y
		endif
	End Method


	'override default to (un)check box
	Method onClick:Int(triggerEvent:TEventBase)
		local button:int = triggerEvent.GetData().GetInt("button", -1)
		'only react to left mouse button
		if button <> 1 then return FALSE

		'set box (un)checked
		SetChecked(1 - isChecked())
	End Method


	'override default to handle image changes
	Method onStatusAppearanceChange:int()
		Super.onStatusAppearanceChange()

		'reset autocalculated checkbox dimension
		if checkboxDimensionAutocalculated then SetCheckboxDimension(null)
	End Method


	'override so caption gets positioned next to checkbox instead
	'of within
	Method RepositionCaption:Int()
		if not caption then return False

		caption.rect.dimension.x = rect.GetW() - GetCheckboxDimension().x - captionDisplacement.x

		caption.rect.position.x = GetCheckboxDimension().x + captionDisplacement.x
		'center first line to checkbox center
		caption.rect.position.y = (GetCheckboxDimension().y - GetFont().GetMaxCharHeight()) / 2 + captionDisplacement.y
	End Method
	

	'override default draw-method
	Method DrawContent()
		Local atPoint:TVec2D = GetScreenPos()
		Local oldCol:TColor = new TColor.Get()

		'SetColor 255, 255, 255
		SetAlpha oldCol.a * GetScreenAlpha()

		Local sprite:TSprite = GetSprite()
		if state <> "" then sprite = GetSpriteFromRegistry(GetSpriteName() + state, sprite)
		if sprite then sprite.DrawArea(atPoint.getX(), atPoint.getY(), GetCheckboxDimension().x, GetCheckboxDimension().y)

		'draw checked mark at center of button
		if IsChecked() then GetCheckSprite().Draw(atPoint.getX() + int(GetCheckboxDimension().x/2), atPoint.getY() + int(GetCheckboxDimension().y/2), -1, new TVec2D.Init(0.5, 0.5))

		If caption and caption.IsVisible()
			caption.SetValue(GetValue())

			Local oldCol:TColor = caption.color.copy()
			If isChecked() Then caption.color.AdjustFactor(-60)
			If isHovered() Then caption.color.AdjustFactor(-30)

			caption.Draw()
			'reset color 
			caption.color = oldCol
		EndIf

		oldCol.SetRGBA()
	End Method	
End Type	
