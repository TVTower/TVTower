SuperStrict
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"


Type TDatasheetSkin
	Field textColorGood:SColor8
	Field textColorNeutral:SColor8
	Field textColorBad:SColor8
	Field textColorWarning:SColor8
	Field textColorLabel:SColor8
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
	Global drawTextEffect:TDrawTextEffect = new TDrawTextEffect
	Global textBlockDrawSettings:TDrawTextSettings = new TDrawTextSettings
	

	Function CreateDefault:TDatasheetSkin()
		local skin:TDatasheetSkin = New TDatasheetSkin
		skin.textColorGood = new SColor8(45,80,10)
		skin.textColorNeutral = new SColor8(25,25,25)
		skin.textColorLabel = new SColor8(75,75,75)
		skin.textColorWarning = new SColor8(80,45,10)
		skin.textColorBad = new SColor8(80,10,10)
		skin.defaultFont = GetBitmapFontManager().baseFont

		skin.fontNormal = GetBitmapFontManager().baseFont
		skin.fontBold = GetBitmapFontManager().baseFontBold
		skin.fontSmall = GetBitmapFontManager().Get("default", skin.fontNormal.FSize-1)
		skin.fontSemiBold = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)
		skin.fontCaption = GetBitmapFontManager().Get("default", 13, BOLDFONT)
		skin.fontSmallCaption = GetBitmapFontManager().Get("default", 12, BOLDFONT)

		'use content-params from sprite
		skin.contentPadding.CopyFrom( GetSpriteFromRegistry(skin.spriteBaseKey+"_border").GetNinePatchInformation().contentBorder )
		'slight overlay
		skin.contentPadding.SetBottom( skin.contentPadding.GetBottom() - 1 )
		
		
		drawTextEffect.data.mode = EDrawTextEffect.Emboss
		drawTextEffect.data.value = 0.2
		
		textBlockDrawSettings.data.lineHeight = 13
		textBlockDrawSettings.data.boxDimensionMode = 0

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
		local boxSprite:TSprite = GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType)
		boxSprite.DrawArea(x, y, w, h)
		if iconName then GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).Draw(x, y)

		if value
			if h < 0 then h = GetBoxSize(w,h, value, iconName).GetY()
			if fontColorType = "" then fontColorType = boxType
			if not font then font = GetDefaultFont()
			if not valueAlign then valueAlign = ALIGN_CENTER_CENTER
			local border:SRect = boxSprite.GetNinePatchInformation().contentBorder

			font.DrawBox( ..
				value, ..
				x + border.GetLeft(), ..
				y + border.GetTop() - 1, ..
				w - (border.GetRight() + border.GetLeft()),  ..
				h - (border.GetTop() + border.GetBottom() - 4), ..
				new SVec2F(valueAlign.x, valueAlign.y), GetTextColor(fontColorType), drawTextEffect.data)
		endif
	End Method


	Method GetBoxSize:TVec2D(w:int, h:int=-1, value:string, iconName:string="", boxType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		if h > 0
			return new TVec2D(w, h)
		elseif iconName
			return new TVec2D(w, max(GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).GetHeight(), GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetHeight()) )
		else
			return new TVec2D(w, GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetHeight() )
		endif
	End Method


	Method RenderMessage(x:int, y:int, w:int, h:int=-1, value:string, iconName:string="", msgType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).DrawArea(x, y, w, h)
		if iconName then GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).Draw(x, y)

		if value
			if h < 0 then h = GetBoxSize(w,h, value, iconName).GetY()
			if not font then font = GetDefaultFont()
			if not valueAlign then valueAlign = ALIGN_LEFT_CENTER
			local border:SRect = GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetNinePatchInformation().contentBorder

			font.DrawBox( ..
				value, ..
				x + border.GetLeft() + 1, ..
				y + border.GetTop() - 2, ..
				w - (border.GetRight() + border.GetLeft()) - 2,  ..
				h - (border.GetTop() + border.GetBottom() - 4), ..
				new SVec2F(valueAlign.x, valueAlign.y), GetTextColor(msgType), drawTextEffect.data)
		endif
	End Method


	Method GetMessageSize:TVec2D(w:int, h:int=-1, value:string, iconName:string="", msgType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		if h > 0
			return new TVec2D(w, h)
		elseif iconName
			return new TVec2D(w, max(GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).GetHeight(), GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetHeight()) )
		else
			return new TVec2D(w, GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetHeight() )
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
		local cB:SRect = spriteBarUnfilled.GetNinePatchInformation().contentBorder
		local barW:int = w - cb.GetLeft() - cb.GetRight()
		if secondProgress > progress
			SetAlpha GetAlpha()*0.25
			spriteBarFilled.DrawArea(x + cB.GetLeft(), y, barW, h, -1, 0, new TRectangle.Init(x + cB.GetLeft() + progress*barW, y, barW*(secondProgress-progress), h))
			SetAlpha GetAlpha()*4.0
		endif
		if progress > 0
			spriteBarFilled.DrawArea(x + cB.GetLeft(), y, barW, h, -1, 0, new TRectangle.Init(x + cB.GetLeft(), y, barW*progress, h))
		endif
	End Method


	Method GetBarSize:TVec2D(w:int, h:int=-1, barSkin:string="bar")
		if h = -1 then h = GetSpriteFromRegistry(spriteBaseKey+"_"+barSkin+"_filled").GetHeight()
		return new TVec2D(w, h)
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


	Method GetTextColor:SColor8(key:string)
		Select key.ToLower()
			case "good"     return textColorGood
			case "goodhint" return textColorNeutral 'green overemphasizes?
			case "neutral"  return textColorNeutral
			case "bad"      return textColorBad
			case "badhint"  return textColorBad
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