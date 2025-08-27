SuperStrict
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"


Enum EDatasheetColorStyle
	Undefined
	Good
	GoodHint
	Neutral
	Bad
	BadHint
	Warning
	Label
End Enum


Type TDatasheetSkin
	Field textColorGood:SColor8
	Field textColorNeutral:SColor8
	Field textColorBad:SColor8
	Field textColorWarning:SColor8
	Field textColorLabel:SColor8
	Field spriteBaseKey:string = "gfx_datasheet"
	Field spriteBorder:TSprite
	Field spriteContentKey:String
	Field spriteContent:TSprite
	Field spriteContentType:String
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
	

	Method New()
		SetSpriteBaseKey("gfx_datasheet")
	End Method


	Function CreateDefault:TDatasheetSkin()
		local skin:TDatasheetSkin = New TDatasheetSkin
		skin.textColorGood = new SColor8(45,80,10)
		skin.textColorNeutral = new SColor8(25,25,25)
		skin.textColorLabel = new SColor8(75,75,75)
		skin.textColorWarning = new SColor8(80,45,10)
		skin.textColorBad = new SColor8(80,10,10)
		skin.defaultFont = GetBitmapFontManager().baseFont

		skin.fontNormal = GetBitmapFontManager().Get("default", 11)
		skin.fontBold = GetBitmapFontManager().Get("default", 12, BOLDFONT)
		skin.fontSmall = GetBitmapFontManager().Get("default", skin.fontNormal.FSize-1)
		skin.fontSemiBold = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)
		skin.fontCaption = GetBitmapFontManager().Get("default", 12, BOLDFONT)
		skin.fontSmallCaption = GetBitmapFontManager().Get("default", 11, BOLDFONT)

		'use content-params from sprite
		skin.contentPadding.CopyFrom( skin.spriteBorder.GetNinePatchInformation().contentBorder )
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
	
	
	Method SetSpriteBaseKey(spriteBaseKey:String)
		If self.spriteBaseKey <> spriteBaseKey or not spriteBorder
			spriteBorder = GetSpriteFromRegistry(spriteBaseKey+"_border")
		Endif
		self.spriteBaseKey = spriteBaseKey
		self.spriteContentKey = spriteBaseKey+"_content_"
	End Method


	Method RenderContent(x:int, y:int, w:int, h:int, contentType:string="1")
		if spriteContentType <> contentType
			spriteContent = GetSpriteFromRegistry(spriteContentKey + contentType)
			spriteContentType = contentType
		EndIf
		spriteContent.DrawArea(x, y, w, h)
	End Method


	Method RenderBorder(x:int, y:int, w:int, h:int)
		spriteBorder.DrawArea(x, y, w, h)
	End Method


	Method RenderBox(x:int, y:int, w:int, h:int=-1, value:string, iconName:string="", boxStyle:EDatasheetColorStyle=EDatasheetColorStyle.Neutral, font:TBitmapFont=null, valueAlign:TVec2D=null, fontColorStyle:EDatasheetColorStyle=EDatasheetColorStyle.Undefined)
		local boxSprite:TSprite = GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxStyle.ToString())
		boxSprite.DrawArea(x, y, w, h)
		if iconName then GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).Draw(x, y)

		if value
			if h < 0 then h = GetBoxSize(w,h, value, iconName).y
			if fontColorStyle = EDatasheetColorStyle.Undefined then fontColorStyle = boxStyle
			if not font then font = GetDefaultFont()
			if not valueAlign then valueAlign = ALIGN_CENTER_CENTER
			local border:SRect = boxSprite.GetNinePatchInformation().contentBorder

			font.DrawBox( ..
				value, ..
				x + border.GetLeft(), ..
				y + border.GetTop() - 2, ..
				w - (border.GetRight() + border.GetLeft()),  ..
				h - (border.GetTop() + border.GetBottom() - 4), ..
				new SVec2F(valueAlign.x, valueAlign.y), GetTextColor(fontColorStyle), drawTextEffect.data)
		endif
	End Method


	Method GetBoxSize:SVec2I(w:int, h:int=-1, value:string, iconName:string="", boxType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		if h > 0
			return new SVec2I(w, h)
		elseif iconName
			return new SVec2I(w, max(GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).GetHeight(), GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetHeight()) )
		else
			return new SVec2I(w, GetSpriteFromRegistry(spriteBaseKey+"_box_"+boxType).GetHeight() )
		endif
	End Method


	Method RenderMessage(x:int, y:int, w:int, h:int=-1, value:string, iconName:string="", msgType:EDatasheetColorStyle=EDatasheetColorStyle.Neutral, font:TBitmapFont=null, valueAlign:TVec2D=null)
		Local msgSprite:TSprite = GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType.ToString())
		msgSprite.DrawArea(x, y, w, h)
		if iconName then GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).Draw(x, y)

		if value
			if h < 0 then h = GetBoxSize(w,h, value, iconName).y
			if not font then font = GetDefaultFont()
			if not valueAlign then valueAlign = ALIGN_LEFT_CENTER
			local border:SRect = msgSprite.GetNinePatchInformation().contentBorder

			font.DrawBox( ..
				value, ..
				x + border.GetLeft() + 1, ..
				y + border.GetTop() - 2, ..
				w - (border.GetRight() + border.GetLeft()) - 2,  ..
				h - (border.GetTop() + border.GetBottom() - 4), ..
				new SVec2F(valueAlign.x, valueAlign.y), GetTextColor(msgType), drawTextEffect.data)
		endif
	End Method


	Method GetMessageSize:SVec2I(w:int, h:int=-1, value:string, iconName:string="", msgType:string="neutral", font:TBitmapFont=null, valueAlign:TVec2D=null)
		if h > 0
			return new SVec2I(w, h)
		elseif iconName
			return new SVec2I(w, max(GetSpriteFromRegistry(spriteBaseKey+"_icon_"+iconName).GetHeight(), GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetHeight()) )
		else
			return new SVec2I(w, GetSpriteFromRegistry(spriteBaseKey+"_msg_"+msgType).GetHeight() )
		endif
	End Method



	Method RenderBar(x:Float, y:Float, w:int, h:int=-1, progress:Float=0.5, secondProgress:Float=-1.0, barSkin:string="bar")
		'drawing the filled bar "clipped" so potential gradients
		'(like normal->danger: green->red) are working as intended
		'-> instead of truncating the width/height of the area, we
		'   restrict the viewport

		Local baseKey:String = spriteBaseKey+"_"+barSkin
		local spriteBarUnfilled:TSprite = GetSpriteFromRegistry(baseKey+"_unfilled")
		local spriteBarFilled:TSprite = GetSpriteFromRegistry(baseKey+"_filled")

		'viewports need to know the height...
		if h = -1 then h = spriteBarUnfilled.GetHeight()

		spriteBarUnfilled.DrawArea(x, y, w, h)
		local cB:SRect = spriteBarUnfilled.GetNinePatchInformation().contentBorder
		local barW:int = w - cb.GetLeft() - cb.GetRight()
		if secondProgress > progress
			SetAlpha GetAlpha()*0.25
			spriteBarFilled.DrawArea(x + cB.GetLeft(), y, barW, h, -1, 0, True, New SRectI(Int(x + cB.GetLeft() + progress*barW), Int(y), Int(barW*(secondProgress-progress)), Int(h)))
			SetAlpha GetAlpha()*4.0
		endif
		if progress > 0
			spriteBarFilled.DrawArea(x + cB.GetLeft(), y, barW, h, -1, 0, True, New SRectI(Int(x + cB.GetLeft()), Int(y), Int(barW*progress), Int(h)))
		endif
	End Method


	Method GetBarSize:SVec2I(w:int, h:int=-1, barSkin:string="bar")
		If h = -1
			Local sb:TStringBuilder = New TStringBuilder(spriteBaseKey).Append("_").Append(barSkin).Append("_filled")
			h = GetSpriteFromRegistry(sb.ToString()).GetHeight()
		EndIf
		return new SVec2I(w, h)
	End Method


	Method GetContentPadding:TRectangle()
		return contentPadding
	End Method


	Method GetContentRect:SRectI(sheetRect:SRectI)
		Local cpLeft:Float = contentPadding.GetLeft()
		Local cpTop:Float = contentPadding.GetTop()
		Return new SRectI(Int(sheetRect.x + cpLeft), ..
                          Int(sheetRect.y + contentPadding.GetTop()), ..
		                  Int(sheetRect.w - cpLeft - contentPadding.GetRight()), ..
		                  Int(sheetRect.h - cpTop - contentPadding.GetBottom())..
		                 )
	End Method
	
	
	Method GetContentRect:SRectI(x:Float, y:Float, sheetWidth:Float, sheetHeight:Float)
		Local cpLeft:Float = contentPadding.GetLeft()
		Local cpTop:Float = contentPadding.GetTop()
		Return new SRectI(Int(x + cpLeft), ..
                          Int(y + contentPadding.GetTop()), ..
		                  Int(sheetWidth - cpLeft - contentPadding.GetRight()), ..
		                  Int(sheetHeight - cpTop - contentPadding.GetBottom())..
		                 )
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


	Method GetTextColor:SColor8(color:EDatasheetColorStyle)
		Select color
			case EDatasheetColorStyle.Undefined  return textColorNeutral
			case EDatasheetColorStyle.Good       return textColorGood
			case EDatasheetColorStyle.GoodHint   return textColorNeutral 'green overemphasizes?
			case EDatasheetColorStyle.Neutral    return textColorNeutral
			case EDatasheetColorStyle.Bad        return textColorBad
			case EDatasheetColorStyle.BadHint    return textColorBad
			case EDatasheetColorStyle.Warning    return textColorWarning
			case EDatasheetColorStyle.Label      return textColorLabel
			default
				Throw "unhandled GetTextColor-EDatasheetColorStyle enum"
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
