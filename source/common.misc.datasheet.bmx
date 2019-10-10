SuperStrict
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"


Type TDatasheetSkin
	Field textColorGood:TColor
	Field textColorNeutral:TColor
	Field textColorBad:TColor
	Field textColorWarning:TColor
	Field textColorLabel:TColor
	Field spriteBaseKey:string = "gfx_datasheet"
	Field fontSmall:TBitmapFont
	Field fontNormal:TBitmapFont
	Field fontBold:TBitmapFont
	Field fontSemiBold:TBitmapFont
	Field fontCaption:TBitmapFont
	Field fontSmallCaption:TBitmapFont

	Field defaultFont:TBitmapFont
	Field contentPadding:TRectangle = New TRectangle
	Global defaultSkin:TDatasheetSkin


	Function CreateDefault:TDatasheetSkin()
		local skin:TDatasheetSkin = New TDatasheetSkin
		skin.textColorGood = TColor.Create(45,80,10)
		skin.textColorNeutral = TColor.CreateGrey(25)
		skin.textColorLabel = TColor.CreateGrey(75)
		skin.textColorWarning = TColor.Create(80,45,10)
		skin.textColorBad = TColor.Create(80,10,10)
		skin.defaultFont = GetBitmapFontManager().baseFont

		skin.fontNormal = GetBitmapFontManager().baseFont
		skin.fontBold = GetBitmapFontManager().baseFontBold
		skin.fontSmall = GetBitmapFontManager().Get("default", skin.fontNormal.FSize-1)
		skin.fontSemiBold = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)
		skin.fontCaption = GetBitmapFontManager().Get("default", 13, BOLDFONT)
		skin.fontSmallCaption = GetBitmapFontManager().Get("default", 12, BOLDFONT)

		'use content-params from sprite
		skin.contentPadding.CopyFrom( GetSpriteFromRegistry(skin.spriteBaseKey+"_border").GetNinePatchContentBorder() )
		'slight overlay
		skin.contentPadding.SetBottom( skin.contentPadding.GetBottom() - 1 )

		return skin
	End Function


	Function GetSkin:TDatasheetSkin(name:string="")
		'TODO: implement support for multiple skins

		if not TDatasheetSkin.defaultSkin
			TDatasheetSkin.defaultSkin = TDatasheetSkin.CreateDefault()
		endif
		return TDatasheetSkin.defaultSkin
	End Function


	Method RenderContent(x:int, y:int, w:int, h:int, contentType:string="1")
		GetSpriteFromRegistry(spriteBaseKey+"_content_"+contentType).DrawArea(x, y, w, h)
	End Method


	Method RenderBorder(x:int, y:int, w:int, h:int)
		GetSpriteFromRegistry(spriteBaseKey+"_border").DrawArea(x, y, w, h)
	End Method


	Method RenderBox(x:int, y:int, w:int, h:int=-1, value:string, iconName:string="", boxType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null, fontColorType:string="")
		GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).DrawArea(x, y, w, h)
		if iconName then GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).Draw(x, y)

		if value
			if h < 0 then h = GetBoxSize(w,h, value, iconName).GetY()
			if fontColorType = "" then fontColorType = boxType
			if not font then font = GetDefaultFont()
			if not valueAlign then valueAlign = ALIGN_CENTER_CENTER
			local border:TRectangle = GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetNinePatchContentBorder()

			font.drawBlock( ..
				value, ..
				x + border.GetLeft(), ..
				y + border.GetTop(), .. '-1 to align it more properly
				w - (border.GetRight() + border.GetLeft()),  ..
				h - (border.GetTop() + border.GetBottom()), ..
				valueAlign, GetTextColor(fontColorType), 0,1,1.0,True, True)
		endif
	End Method


	Method GetBoxSize:TVec2D(w:int, h:int=-1, value:string, iconName:string="", boxType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		if h > 0
			return new TVec2D.Init(w, h)
		elseif iconName
			return new TVec2D.Init(w, max(GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).GetHeight(), GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetHeight()) )
		else
			return new TVec2D.Init(w, GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetHeight() )
		endif
	End Method


	Method RenderMessage(x:int, y:int, w:int, h:int=-1, value:string, iconName:string="", msgType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).DrawArea(x, y, w, h)
		if iconName then GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).Draw(x, y)

		if value
			if h < 0 then h = GetBoxSize(w,h, value, iconName).GetY()
			if not font then font = GetDefaultFont()
			if not valueAlign then valueAlign = ALIGN_LEFT_CENTER
			local border:TRectangle = GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetNinePatchContentBorder()

			font.drawBlock( ..
				value, ..
				x + border.GetLeft(), ..
				y + border.GetTop(), ..
				w - (border.GetRight() + border.GetLeft()),  ..
				h - (border.GetTop() + border.GetBottom()), ..
				valueAlign, GetTextColor(msgType), 0,1,1.0,True, True)
		endif
	End Method


	Method GetMessageSize:TVec2D(w:int, h:int=-1, value:string, iconName:string="", msgType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		if h > 0
			return new TVec2D.Init(w, h)
		elseif iconName
			return new TVec2D.Init(w, max(GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).GetHeight(), GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetHeight()) )
		else
			return new TVec2D.Init(w, GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetHeight() )
		endif
	End Method



	Method RenderBar(x:Float, y:Float, w:int, h:int=-1, progress:Float=0.5, secondProgress:Float=-1.0, barSkin:string="bar")
		'drawing the filled bar "clipped" so potential gradients
		'(like normal->danger: green->red) are working as intended
		'-> instead of truncating the width/height of the area, we
		'   restrict the viewport

		local spriteBarUnfilled:TSprite = GetSpriteFromRegistry(spriteBaseKey+"_"+barSkin+"_unfilled")
		local spriteBarFilled:TSprite = GetSpriteFromRegistry(spriteBaseKey+"_"+barSkin+"_filled")

		'viewports need to know the height...
		if h = -1 then h = spriteBarUnfilled.GetHeight()

		spriteBarUnfilled.DrawArea(x, y, w, h)
		local barW:int = w - spriteBarUnfilled.GetNinePatchContentBorder().GetLeft() - spriteBarUnfilled.GetNinePatchContentBorder().GetRight()
		if secondProgress > progress
			SetAlpha GetAlpha()*0.25
			spriteBarFilled.DrawArea(x + spriteBarUnfilled.GetNinePatchContentBorder().GetLeft(), y, barW, h, -1, 0, new TRectangle.Init(x + spriteBarUnfilled.GetNinePatchContentBorder().GetLeft() + progress*barW, y, barW*(secondProgress-progress), h))
			SetAlpha GetAlpha()*4.0
		endif
		if progress > 0
			spriteBarFilled.DrawArea(x + spriteBarUnfilled.GetNinePatchContentBorder().GetLeft(), y, barW, h, -1, 0, new TRectangle.Init(x + spriteBarUnfilled.GetNinePatchContentBorder().GetLeft(), y, barW*progress, h))
		endif
	End Method


	Method GetBarSize:TVec2D(w:int, h:int=-1, barSkin:string="bar")
		if h = -1 then h = GetSpriteFromRegistry(spriteBaseKey+"_"+barSkin+"_filled").GetHeight()
		return new TVec2D.Init(w, h)
	End Method


	Method GetContentPadding:TRectangle()
		return contentPadding
	End Method


	Method GetContentX:int(x:Float = 0)
		return int(x + contentPadding.GetLeft())
	End Method


	Method GetContentY:int(y:Float = 0)
		return int(y + contentPadding.GetTop())
	End Method


	Method GetContentW:int(sheetWidth:Float)
		return int(sheetWidth - contentPadding.GetLeft() - contentPadding.GetRight())
	End Method


	Method GetContentH:int(sheetHeight:Float)
		return int(sheetHeight - contentPadding.GetTop() - contentPadding.GetBottom())
	End Method


	Method GetTextColor:TColor(key:string)
		Select key.ToLower()
			case "good"     return textColorGood
			case "neutral"  return textColorNeutral
			case "bad"      return textColorBad
			case "warning"  return textColorWarning
			case "label"    return textColorLabel
		End Select
	End Method


	Method GetDefaultFont:TBitmapFont()
		if defaultFont then return defaultFont
		return GetBitmapFontManager().baseFont
	End Method
End Type


Function GetDatasheetSkin:TDatasheetSkin(skinName:string="")
	return TDatasheetSkin.GetSkin(skinName)
End Function