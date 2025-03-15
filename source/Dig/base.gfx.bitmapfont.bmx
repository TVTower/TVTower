Rem
	====================================================================
	Bitmapfont + Manager classes
	====================================================================

	Bitmapfont classes using sprite atlases for faster drawing.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
Import BRL.Max2D
Import BRL.Map
Import Brl.RectPacker
Import Math.Vector
'to load from truetype
Import brl.FreeTypeFont
'Import "base.util.srectangle.bmx"
Import "base.gfx.sprite.bmx"

Global BITMAPFONTBENCHMARK:Int = False

Const SHADOWFONT:Int = 256
Const GRADIENTFONT:Int = 512

'set line mode, lineheight etc
TBitmapFont.InitDefaultDrawSettings()
TBitmapFont.globalBoxParseInfo = New TTextParseInfo()
TBitmapFont.globalParseInfo = New TTextParseInfo()

Type TBitmapFontManager
	Field baseFont:TBitmapFont
	Field baseFontBold:TBitmapFont
	Field baseFontItalic:TBitmapFont
	Field baseFontSmall:TBitmapFont
	Field _defaultFont:TBitmapFont

	Field fonts:TMap = New TMap
	Field fontsID:TIntMap = New TIntMap
	Global systemFont:TBitmapFont
	Global _instance:TBitmapFontManager
	Global _defaultFlags:Int = 0 'SMOOTHFONT


	Function GetInstance:TBitmapFontManager()
		If Not _instance Then _instance = New TBitmapFontManager
		Return _instance
	End Function


	Method GetDefaultFont:TBitmapFont()
		'instead of doing it in "new" (no guarantee that graphicsmode
		'is set up already)
		If Not systemFont 
			systemFont = TBitmapFont.Create("SystemFont", "", 12, SMOOTHFONT)
			'FIX ascender/descender values for the system font!
			systemFont.ascend = 13
			systemFont.descend = -3
	'		systemFont.ascend = 9
	'		systemFont.descend = -6
		EndIf

		'if no default font was set, return the system font
		If Not _defaultFont Then Return systemFont

		Return _defaultFont
	End Method


'	Method Get:TBitmapFont(id:Int, size:Int=-1, style:Int=-1)
'	End Method

	'get ignores the "SMOOTHFONT" flag to allow adding "crisp" fonts
	Method Get:TBitmapFont(name:String="", size:Float=-1, style:Int=-1)
		name = Lower(name)

		'fall back to default font if none was given
		If name = "" Then name = "default"

		'no details given: return default font
		If name = "default" And size = -1 And style = -1 Then Return GetDefaultFont()


		'try to find default font settings for this font face
		Local defaultStyledFont:TBitmapFont
		Local defaultFont:TBitmapFont

		If size = -1 Or style = -1 Then
			defaultStyledFont = GetDefaultStyledFont(name, style)

			'no size given: use default font size
			If size = -1 Then size = defaultStyledFont.FSize
			'no style given: use default font style
			If style = -1 Then style = defaultStyledFont.FStyle
		End If

		'Local key:String = name + "_" + size + "_" + style
		Local font:TBitmapFont = GetFont(name, size, style)
		If font Then Return font
		'if the font wasn't found, use the defaultFont-fontfile to load this style

		If Not defaultStyledFont Then
			defaultStyledFont = GetDefaultStyledFont(name, style)
		End If

		font = Add(name, defaultStyledFont.FFile, size, style)

		Return font
	End Method


	Method GetDefaultStyledFont:TBitmapFont(name:String, style:Int)

		Local defaultStyledFont:TBitmapFont = GetFont(name, -1, style)
	
		If Not defaultStyledFont
			defaultStyledFont = GetFont(name, -1, -1)
		EndIf
		If Not defaultStyledFont Then defaultStyledFont = GetDefaultFont()

		Return defaultStyledFont
	End Method


	Method Copy:TBitmapFont(sourceName:String, copyName:String, size:Float=-1, style:Int=-1)
		Local sourceFont:TBitmapFont = Get(sourceName, size, style)
		Local newFont:TBitmapFont = TBitmapFont.Create(copyName, sourceFont.fFile, sourceFont.fSize, sourceFont.fStyle, sourceFont.fixedCharWidth, sourceFont.charWidthModifier)
		InsertFont(copyName, sourceFont.fSize, sourceFont.fStyle, newFont)

		Return newFont
	End Method


	Method InsertFont(name:String, size:Float, style:Int, font:TBitmapFont)
		Local sizes:TSizedBitmapFonts = TSizedBitmapFonts(fonts.ValueForKey(name))

		If Not sizes Then
			sizes = New TSizedBitmapFonts
			fonts.Insert(name, sizes)
		End If

		sizes.Insert(size, style, font)
		
		fontsID.Insert(font.id, font)
	End Method


	Method GetFont:TBitmapFont(fontID:Int)
		Return TBitmapFont(fontsID.ValueForKey(fontID))
	End Method


	Method GetFont:TBitmapFont(name:String, size:Float = -1, style:Int = -1)
		Local sizes:TSizedBitmapFonts = TSizedBitmapFonts(fonts.ValueForKey(name))

		If Not sizes Then
			Return Null
		End If

		Return sizes.Get(size, style)
	End Method


	Method Add:TBitmapFont(name:String, file:String, size:Float, style:Int=0, ignoreDefaultStyle:Int = False, fixedCharWidth:Int=-1, charWidthModifier:Float=1.0)
		name = Lower(name)
		If Not ignoreDefaultStyle
			style :| _defaultFlags
		EndIf

		Local defaultFont:TBitmapFont = GetDefaultFont()
		If size = -1 Then size = defaultFont.FSize
		If style = -1 Then style = defaultFont.FStyle
		If file = "" Then file = defaultFont.FFile

		Local font:TBitmapFont = TBitmapFont.Create(name, file, size, style, fixedCharWidth, charWidthModifier)

		InsertFont(name, size, style, font)

		'insert as default font too (name + style, ignore size)
		If Not GetFont(name, -1, style) Then InsertFont(name, -1, style, font)

		'insert as default font too (only name)
		If Not GetFont(name) Then InsertFont(name, -1, -1, font)

		'if SMOOTHFONT was used - add the unsmoothed too (for easier retrieval)
		If (style & SMOOTHFONT) <> 0
			Local styleNonSmooth:Int = style - SMOOTHFONT
			If Not GetFont(name, -1, (style - SMOOTHFONT))
				InsertFont(name, -1, (style - SMOOTHFONT), font)
			EndIf

			If Not GetFont(name, size , (style - SMOOTHFONT))
				InsertFont(name, size, (style - SMOOTHFONT), font)
			EndIf
		EndIf



		'set default fonts if not done yet
		If _defaultFont = Null Then _defaultFont = Font
		If baseFont = Null Then baseFont = Font
		If baseFontBold = Null And style & BOLDFONT > 0 Then baseFontBold = Font
		If baseFontItalic  = Null And style & ITALICFONT > 0 Then baseFontItalic = Font

		Return Font
	End Method


	Method AddFont:TBitmapFont(font:TBitmapFont)
		InsertFont(font.FName, font.FSize, font.FStyle, font)
	End Method
End Type


'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetBitmapFontManager:TBitmapFontManager()
	Return TBitmapFontManager.GetInstance()
End Function

'not really needed - but for convenience to avoid direct call to the
'instance getter GetBitmapFontManager()
Function GetBitmapFont:TBitmapfont(name:String="", size:Float=-1, style:Int=-1)
	Return TBitmapFontManager.GetInstance().Get(name, size, style)
End Function

Function GetBitmapFont:TBitmapfont(familyID:Int, size:Float=-1, style:Int=-1)
	Return TBitmapFontManager.GetInstance().Get(familyID, size, style)
End Function




Type TBitmapFontChar
	Field charCode:Int
	Field pos:SVec2I
	Field dim:SVec2I
	Field charWidth:Float
	' rasterized pixel data of the glyph
	Field pixmap:TPixmap
	' backup of original data in case of applied effects
	Field pixmapBackup:TPixmap
	' gpu oriented sprite (sub rect of a spritepack/TImage)
	Field sprite:TSprite


	Method Init:TBitmapFontChar(charCode:Int, imgOrPixmap:Object, x:Int,y:Int,w:Int, h:Int, charWidth:Float)
		Self.charCode = charCode 
		Self.pos = New SVec2I(x,y)
		Self.dim = New SVec2I(w,h)
		Self.charWidth = charWidth
		Self.SetPixmap(imgOrPixmap)
		Return Self
	End Method
	
	
	Method SetPixmap(o:Object)
		If TImage(o)
			Local img:TImage = TImage(o)
			Self.pixmap = LockImage(img)
			UnlockImage(img)
		ElseIf TPixmap(o)
			Self.pixmap = TPixmap(o)
		Else
			Self.pixmap = Null
		EndIf
		
		Self.pixmapBackup = Self.pixmap
	End Method
	
	
	Method SetSprite(s:TSprite)
		Self.sprite = s
	End Method
End Type




' A char group is similar to a code page - it can hold a various
' amount of chars "belonging" together
' Chars often used together should be grouped (eg ANSI/ASCII for the
' classic AZ,az,09 ... support
Type TBitmapFontCharGroup
	Field chars:TBitmapFontChar[]
	Field spritePacks:TSpritePack[]


	Method New(chars:TBitmapFontChar[])
		Self.chars = chars
	End Method


	'try to pack the chars into as few textures as possible
	Method CreateSpritePacks(font:TBitmapFont)
		If chars.Length = 0 Then Return
		
		' create one or multiple sprite-atlas with information where to
		' optimally store each char
		Local packer:TRectPacker = New TRectPacker
		packer.maxSheets = 100
		'NOT working as expected now!
		packer.overAllocate = 2 'a bit of padding around the texture
		packer.borderPadding = font._pixmapCharPadding
		' we want our images to not exceed 2048x2048 px
		packer.maxHeight = 2048
		packer.maxWidth = 2048

		For Local charIndex:Int = 0 Until chars.Length
			If Not chars[charIndex] or chars[charIndex].dim.x = 0 or chars[charIndex].dim.y = 0
				Continue
			EndIf

			' TODO: The packer for now does not do "borderPadding" to the sprites
			'       the sprites - this is why for NOW we add it to the
			'       rect here, and subtract it below again

			' add box of the char to the sprite atlas
			'packer.Add( Int(chars[charIndex].dim.x + 2*packer.borderPadding), Int(chars[charIndex].dim.y + 2*packer.borderPadding), charIndex)
			' using the pixmap size allows effects to alter the size
			packer.Add( Int(chars[charIndex].pixmap.width + 2*packer.borderPadding), Int(chars[charIndex].pixmap.height + 2*packer.borderPadding), charIndex)
		Next
		' pack all char rects together
		Local sheets:TPackedSheet[] = packer.Pack()

		' create the corresponding pixmaps for the sprite atlases
		spritePacks = New TSpritePack[sheets.Length]

		For Local sheetIndex:Int = 0 Until sheets.Length
			Local sheet:TPackedSheet = sheets[sheetIndex]

			Local pix:TPixmap = CreatePixmap(sheet.width, sheet.height, font._pixmapFormat)
			pix.ClearPixels(0)
			spritePacks[sheetIndex] = New TSpritePack.Init(Null, "charmap")

			For Local j:Int = 0 Until sheet.rects.Length
				Local rect:SPackedRect = sheet.rects[j]

				Local char:TBitmapFontChar = chars[rect.id]
				If Not char.pixmap Then Continue
				
				Local atlasX:Int = rect.x + font._pixmapCharPadding
				Local atlasY:Int = rect.y + font._pixmapCharPadding
				' TODO: Packer does not properly pad sprites / doc is
				'       wrong, so we manually added padding and now need
				'       to substract again
				Local unpaddedW:Int = rect.width - packer.borderPadding
				Local unpaddedH:Int = rect.height - packer.borderPadding

				' draw char image on charmap
				DrawImageOnImage(char.pixmap, pix, atlasX, atlasY)

				' create sprite
				char.sprite = New TSprite.Init(spritePacks[sheetIndex], String(rect.id), New SRectI(atlasX, atlasY, unpaddedW, unpaddedH), Null, 0)
			Next

			'set image to sprite pack
			If font.IsSmooth()
				spritePacks[sheetIndex].image = LoadImage(pix) ', FILTEREDIMAGE | DYNAMICIMAGE)
			Else
				'non smooth fonts should disable any filtering (eg. in virtual resolution scaling)
				spritePacks[sheetIndex].image = LoadImage(pix, 0)
			EndIf
		Next
	End Method
End Type




Type TBitmapFont
	Field id:Int = 0 
	'identifier
	Field FName:String = ""
	'source path
	Field FFile:String = ""
	'size of this font
	Field FSize:Float = 0
	Field FSize266:Int = 0 'size in 26.6 freetype format (int(size* 64))
	'style used in this font
	Field FStyle:Int = 0
	'the original imagefont
	Field FImageFont:TImageFont

	Field charGroups:TBitmapFontCharGroup[]

	Field gfx:TMax2dGraphics
	
	'distance between baseline and highest font's characters coordinates
	Field ascend:Int = -1000
	'distance between baseline and lowest font's characters coordinates
	Field descend:Int = -1000
	Field xHeight:Int = -1
	'value the font designer thinks is approbriate as line height
	Field automaticLineHeight:Int = -1000
	
	'what is the pixel offset of the "biggest/tallest" glyph?
	'taken into account A-Z and all "extended" chars
	Field displaceY:Float=100.0
	'taken into account A-Z 
	Field baseDisplaceY:Float=100.0
	'modifier * lineheight gets added at the end
	Field lineHeightModifier:Float = 1.00
	'value the width of " " (space) is multiplied with
	Field spaceWidthModifier:Float = 1.0
	Field charWidthModifier:Float = 1.0
	Field fixedCharWidth:Int = -1
	Field tabWidth:Int = 15
	Field _charsEffectFuncs:TBitmapFontChar(font:TBitmapFont, char:TBitmapFontChar, config:TData)[]
	Field _charsEffectFuncsConfig:TData[]

	'adjust if you add effects
	Field _pixmapCharPadding:Int = 2
	'by default this is 8bit alpha only
	Field _pixmapFormat:Int = PF_A8
	Field _hasEllipsis:Int = -1
	Field _ellipsisWidth:Int = -1
	Field _maxCharWidth:Int = 10
	

	Global defaultDrawSettings:SDrawTextSettings
	Global defaultDrawEffect:SDrawTextEffect
	
	'callback used to return sprites for "|sprite|" commands
	Global _spriteProvider:TSprite(key:String)

	Global drawToPixmap:TPixmap = Null
	Global pixmapOrigin:SVec2I = New SVec2I(0,0)
	
	Global _lastID:Int

	Global shadowColor:SColor8 = SColor8.Black
	Global embossColor:SColor8 = SColor8.White
	
	'if you use DrawBox() to render to a texture
	'and are not passing a STextParseInfo struct (so it uses the
	'global one), the mutex blocks concurrent access
	Global globalBoxParseInfoMutex:TMutex = CreateMutex()
	Global globalBoxParseInfo:TTextParseInfo
	'if you use Draw() to render to a texture
	'and are not passing a STextParseInfo struct (so it uses the
	'global one), the mutex blocks concurrent access
	Global globalParseInfoMutex:TMutex = CreateMutex()
	Global globalParseInfo:TTextParseInfo

	Const COMMAND_CHARCODE:Int = Asc("|")
	Const PAYLOAD_CHARCODE:Int = Asc("=")
	Const ESCAPE_CHARCODE:Int = Asc("\")
	
	'each line height depends on the chars in this line
	Const LINEHEIGHTMODE_INDIVIDUAL:Int = -1
	'line height depends on the highest line in a the block
	Const LINEHEIGHTMODE_MAX:Int = -2
	'line height uses _maxCharHeight on each line
	Const LINEHEIGHTMODE_FIXED:Int = -3
	'positive values = height to use
	

	Method New()
		_lastID :+ 1
		Self.id = _lastID
	End Method 


	Function Create:TBitmapFont(name:String, url:String, size:Float, style:Int, fixedCharWidth:Int = -1, charWidthModifier:Float = 1.0)
		Local obj:TBitmapFont = New TBitmapFont
		obj.FName = name
		obj.FFile = url
		obj.FSize = Int(size)
		obj.FSize266 = Int(size * 64)
		obj.FStyle = style
		obj.gfx = tmax2dgraphics.Current()
		obj.fixedCharWidth = fixedCharWidth
		obj.charWidthModifier = charWidthModifier

		obj.FImageFont = LoadTrueTypeFont(url, size, style)
		If Not obj.FImageFont
			'get system/current font
			obj.FImageFont = GetImageFont()
		EndIf
		If Not obj.FImageFont
			Throw ("TBitmapFont.Create: font ~q"+url+"~q not found.")
			Return Null 'font not found
		EndIf

		' store basic font information
		If TFreeTypeFont(obj.FImageFont._src_font)
			Local ftf:TFreeTypeFont = TFreeTypeFont(obj.FImageFont._src_font)
			obj.ascend = ftf._ascend
			obj.descend = ftf._descend
			obj.automaticLineHeight = ftf._height
		EndIf

		' generate a basic charGroup (Ascii)
		obj.LoadCharGroup(0)
		Return obj
	End Function

	
	Function InitDefaultDrawSettings()
		'configure defaults
		defaultDrawSettings.lineHeightMode = EDrawLineHeightModes.FixedOrAllLinesMax
		defaultDrawSettings.lineHeight=-1
	End Function
	

	'returns the same font in the given size/style combination
	'it is more or less a wrapper to make acces more convenient
	Method GetVariant:TBitmapFont(size:Float=-1, style:Int = -1)
		If size = -1 Then size = Self.FSize
		If style = -1 Then style = Self.FStyle
		Return TBitmapFontManager.GetInstance().Get(Self.FName, size, style)
	End Method	


	Method SetCharsEffectFunction(position:Int, _func:TBitmapFontChar(font:TBitmapFont, char:TBitmapFontChar, config:TData), config:TData)
		position :-1 '0 based
		If _charsEffectFuncs.Length <= position
			_charsEffectFuncs = _charsEffectFuncs[.. position+1]
			_charsEffectFuncsConfig = _charsEffectFuncsConfig[.. position+1]
		EndIf

		_charsEffectFuncs[position] = _func
		_charsEffectFuncsConfig[position] = config
	End Method


	' (re-)apply assigned char effects to all or a specified char group
	' overrideable method
	Method ApplyCharsEffects(config:TData = Null, charGroup:TBitmapFontCharGroup = Null)
		If _charsEffectFuncs.Length = 0 Then Return

		'only apply to a specified group - or all?
		If charGroup
			ApplyEffectsToCharGroup(charGroup, config)
			' recreate and optimize spritepacks holding char sprites
			' that way a "new" chargroup called via "LoadGroup" only
			' creates spritepacks once
			If charGroup.spritepacks.length > 0
				charGroup.CreateSpritePacks(Self)
			EndIf
		Else
			For Local charGroup:TBitmapFontCharGroup = EachIn charGroups
				ApplyEffectsToCharGroup(charGroup, config)
				' recreate and optimize spritepacks holding char sprites
				' that way a "new" chargroup called via "LoadGroup" only
				' creates spritepacks once
				If charGroup.spritepacks.length > 0
					charGroup.CreateSpritePacks(Self)
				EndIf
			Next
		EndIf
	End Method


	Method ApplyEffectsToCharGroup(charGroup:TBitmapFontCharGroup, defaultConfig:TData = Null)
		For Local charKey:Int = 0 Until charGroup.chars.Length
			Local char:TBitmapFontChar = charGroup.chars[charKey]
			If Not char Then Continue
			' not all chars have "visuals" (eg. "Space" char)
			If Not char.pixmapBackup Then Continue
			
			' reload original glyph
			'Local glyph:TImageGlyph = font.FImageFont.LoadGlyph(charKey)			
			' or restore backup (and decouple them, so copy())
			char.pixmap = char.pixmapBackup.Copy()

			' manipulate char
			Local _func:TBitmapFontChar(font:TBitmapFont, char:TBitmapFontChar, config:TData)
			Local _config:TData
			For Local i:Int = 0 Until _charsEffectFuncs.Length
				_func = _charsEffectFuncs[i]
				_config = _charsEffectFuncsConfig[i]
				'use default if nothing defined
				If Not _config Then _config = defaultConfig

				char = _func(Self, char, _config)
			Next

			' overwrite char
			charGroup.chars[charKey] = char
		Next
	End Method


	' generate a char group for the basic chars (Ascii)
	Method LoadCharGroup:TBitmapFontCharGroup(charGroupIndex:Int, charCodeStart:Int=-1, charCodeEnd:Int=-1, config:TData=Null )
		If charGroupIndex < 0 Then charGroupIndex = 0
		If charCodeStart = -1 Then charCodeStart = charGroupIndex * 256
		If charCodeEnd = -1 Then charCodeEnd = charCodeStart + 256
		
		' 0. Ensure group array is big enough
		If charGroups.Length <= charGroupIndex
			charGroups = charGroups[.. charGroupIndex + 1]
		EndIf
		
		' 1. Load chars
		Local chars:TBitmapFontChar[] = LoadCharsFromSource(charCodeStart, charCodeEnd)

		' 2. create the char group (and pack sprite atlas etc)
		Local charGroup:TBitmapFontCharGroup = New TBitmapFontCharGroup(chars)

		' 3. Process the characters (add shadow, gradients, ...)
		ApplyCharsEffects(config, charGroup)
		
		' 4. create and optimize spritepacks holding char sprites
		charGroup.CreateSpritePacks(Self)

		' 5. store group
		charGroups[charGroupIndex] = charGroup

		Return charGroup
	End Method

Rem
			extraChars :+ Chr(8239) 'Narrow No Breaking Space
			extraChars :+ Chr(160)  'No Breaking Space
			extraChars :+ Chr(8364) 'Euro
			extraChars :+ Chr(8230) 'Horizontal Ellipsis
			extraChars :+ Chr(8216) 'Left Single Quotation Mark
			extraChars :+ Chr(8217) 'Right Single Quotation Mark
			extraChars :+ Chr(8218) 'Single Low-9 Quotation Mark
			extraChars :+ Chr(8219) 'Single High-Reversed-9 Quotation Mark
			extraChars :+ Chr(8220) 'Left Double Quotation Mark
			extraChars :+ Chr(8221) 'Right Double Quotation Mark
			extraChars :+ Chr(8222) 'Double Low-9 Quotation Mark
			extraChars :+ Chr(8223) 'Double High-Reversed-9 Quotation Mark
			extraChars :+ Chr(8482) 'Trade Mark Sign
			extraChars :+ Chr(171)  'Left-Pointing Double Angle Quotation Mark
			extraChars :+ Chr(187)  'Right-Pointing Double Angle Quotation Mark
			'extraChars :+ chr(8227) '
			'extraChars :+ chr(9662) '
			extraChars :+ Chr(9650) 'Black Up-Pointing Triangle
			extraChars :+ Chr(9660) 'Black Down-Pointing Triangle
			extraChars :+ Chr(9664) 'Black Left-Pointing Triangle
			extraChars :+ Chr(9654) 'Black Right-Pointing Triangle
			extraChars :+ Chr(9632) 'Black Square
			'extraChars :+ Chr(632)  'Latin Small Letter Phi - TODO: this doesn't seem to display; 966 Greek Small Letter Phi doesn't seem to display either
			extraChars :+ Chr(8243) 'Double Prime (Inch)
			extraChars :+ Chr(8531) 'Vulgar Fraction One Third
			'extraChars :+ Chr(9829) 'Black Heart Suit - TODO: This one doesn't seem to display
endrem

	'load glyphs of an imagefont as TBitmapFontChar into a char-TMap
	Method LoadCharsFromSource:TBitmapFontChar[](charCodeStart:Int, charCodeEnd:Int, source:Object=Null)
		Local imgFont:TImageFont = TImageFont(source)
		If Not imgFont Then imgFont = Self.FImageFont
		If Not imgfont Then Return Null

		'ensure params are in right order and within range
		If charCodeStart < 0 Then charCodeStart = 0
		If charCodeEnd < 0 Then charCodeEnd = 0
		If charCodeEnd < charCodeStart 
			Local tmp:Int = charCodeStart
			charCodeStart = charCodeEnd
			charCodeEnd = tmp
		EndIf


		Local charsToLoad:Int = charCodeEnd - charCodeStart
		Local chars:TBitmapFontChar[charsToLoad]
		For Local i:Int = 0 Until charsToLoad
			Local glyphIndex:Int = imgFont.CharToGlyph(charCodeStart + i)
			If glyphIndex < 0 Then Continue

			Local glyph:TImageGlyph = imgFont.LoadGlyph(glyphIndex)
			If Not glyph Then Continue
			
			'glyph._image can be Null! (eg "space" char code)
			If fixedCharWidth > 0
				chars[i] = New TBitmapFontChar.Init(charCodeStart + i, glyph._image, glyph._x, glyph._y, glyph._w, glyph._h, fixedCharWidth)
			Else
				chars[i] = New TBitmapFontChar.Init(charCodeStart + i, glyph._image, glyph._x, glyph._y, glyph._w, glyph._h, glyph._advance * charWidthModifier)
				Self._maxCharWidth = Max(Self._maxCharWidth, chars[i].charWidth)
			EndIf
			'print "loading #"+i+"/"+charsToLoad+"  glyphIndex "  + glyphIndex + " => " + chr(i)

			'base displacement calculated with A-Z (space between
			'TOPLEFT of 'ABCDE' and TOPLEFT of 'acen'...)
			If i >= 65 And i < 95
				Self.baseDisplaceY = Min(Self.baseDisplaceY, glyph._y)
			EndIf
			If i >= 65 'i>32
				Self.displaceY = Min(Self.displaceY, glyph._y)
			EndIf
		Next

		If fixedCharWidth > 0 
			Self._maxCharWidth = fixedCharWidth
		EndIf
		
		Return chars
	End Method

	
	
	'-----------------


	Method GetLineHeight:Int(fixedLineHeight:Int = -1)
		If fixedLineHeight >= 0
			Return fixedLineHeight
		Else
			If automaticLineHeight = -1000 Then __FixAutomaticLineHeight()
			Return automaticLineHeight * lineHeightModifier
		EndIf
	End Method


	'render to target pixmap/image/screen
	Function SetRenderTarget:Int(target:Object=Null)
		'render to screen
		If Not target
			drawToPixmap = Null
			Return True
		EndIf

		If TImage(target)
			drawToPixmap = LockImage(TImage(target))
		ElseIf TPixmap(target)
			drawToPixmap = TPixmap(target)
		EndIf
	End Function


	Method IsBold:Int()
		Return (FStyle & BOLDFONT)
	End Method

	Method IsSmooth:Int()
		Return (FStyle & SMOOTHFONT)
	End Method


	'Returns whether this font has a visible ellipsis char ("...")
	Method HasEllipsis:Int()
		If _hasEllipsis = -1 Then _hasEllipsis = Int(GetSimpleDimension(Chr(8230)).x)
		Return _hasEllipsis
	End Method


	Method GetEllipsis:String()
		If hasEllipsis() Then Return Chr(8230)
		Return "..."
	End Method
	
	
	Method GetEllipsisWidth:Float()
		If _ellipsisWidth < 0 Then _ellipsisWidth = GetSimpleDimension(GetEllipsis()).x
		Return _ellipsisWidth
	End Method


	Method GetXHeight:Int()
		If xHeight < 0
			Local bm:TBitmapFontChar = __GetBitmapFontChar(Asc("x"))
			If bm 
				xHeight = bm.dim.y
			Else
				xHeight = GetMaxCharHeightAboveBaseline()/2
			EndIf
		EndIf
		Return xHeight
	End Method
	
	
	Method GetMaxCharHeightAboveBaseline:Int()
		Return GetMaxCharHeight(False)
	End Method


	Method GetMaxCharHeightBelowBaseline:Int()
		If descend = -1000 Then GetMaxCharHeight(False)
		Return Abs(descend)
	End Method
	
	
	Method GetMaxCharHeight:Int(includeBelowBaseLine:Int=True)
		If ascend = -1000
			__FixAscendDescend()
		EndIf

		If includeBelowBaseLine
			Return ascend + Abs(descend)
		Else
			Return ascend
		EndIf
	End Method


	Method __FixAutomaticLineHeight(forceRecalculation:Int = False, forceAscendDescendRecalculation:Int = False)
		If Not forceRecalculation And automaticLineHeight <> -1000 Then Return

		__FixAscendDescend(forceAscendDescendRecalculation)
		automaticLineHeight = ascend + Abs(descend)
	End Method
	
	
	Method __FixAscendDescend(force:Int = False)
		'already done
		If Not force And (ascend <> -1000 Or descend <> -1000) Then Return

		'measure till "base" of some upper case chars (offset + dim)
		'this is our ascend
		'then measure the "base" of some chars crossing baseline
		'difference of ascend and this value is the descend.
		'
		'Values might differ to original font information (as we do not
		'know which characters are the ones going down the most below
		'the baseline
		
		Local upperChars:String = "EU" 'some upper case chars
		Local maxY:Int
		For Local i:Int = 0 Until upperChars.Length
			Local bm:TBitmapFontChar = __GetBitmapFontChar(upperChars[i])
			maxY = Max(maxY, bm.pos.y + bm.dim.y)
		Next
		ascend = maxY

		Local belowBaseChars:String = "q_|"
		maxY = 0
		For Local i:Int = 0 Until belowBaseChars.Length
			Local bm:TBitmapFontChar = __GetBitmapFontChar(belowBasechars[i])
			maxY = Max(maxY, bm.pos.y + bm.dim.y)
		Next

		descend = ascend - maxY
	End Method

	
	'returns the dimensions of the given text.
	'NO styles/font variation support!
	'supports multi-line
	Method GetSimpleDimension:SVec2I(s:String, trimWhitespace:Int = False, fixedLineHeight:Int = -1)
		Local textX:Float
		Local textH:Float
		Local textW:Float 
		Local lineContentHeight:Float
		Local textMaxW:Float
		Local currentLine:Int = 0

		Local contentLineHeight:Int = GetMaxCharHeight(True)
		Local lineHeight:Int = automaticLineHeight
		If fixedLineHeight >= 0
			lineHeight = fixedLineHeight
		EndIf
		
		For Local i:Int = 0 Until s.Length
			Local charCode:Int = s[i]
			Local newLineChar:Int = (charCode = 13 Or charCode = Asc("~n"))

			If Not newLineChar
				Local bm:TBitmapFontChar = __GetBitmapFontChar(charCode)
				Local charAdv:SVec2F = __GetCharAdvance(bm, charCode, textX)
				Local charDim:SVec2F = __GetCharDim(bm, charCode, textX)

				textX :+ charAdv.x
				textW :+ charDim.x
			EndIf
			
			'update text dimensions
			'(when new line char or reached end)
			If newLineChar Or i = s.Length - 1
				textMaxW = Max(textMaxW, textW)
				If trimWhitespace And (currentLine = 0 Or i = s.Length - 1)
					textH :+ Min(contentLineHeight, lineHeight)
				Else
					textH :+ lineHeight
				EndIf
				textW = 0
				lineContentHeight = 0
				
				currentLine :+ 1
			EndIf
		Next

		Return New SVec2I(Int(textMaxW), Int(textH))
	End Method


	'returns width of unstyled (but optionally multiline) text
	Method GetSimpleWidth:Int(text:String)
		Return GetSimpleDimension(text).x
	End Method


	'returns height of unstyled (but optionally multiline) text
	Method GetSimpleHeight:Int(text:String)
		Return GetSimpleDimension(text).y
	End Method


	Method GetDimension:SVec2I(text:String, parseInfo:STextParseInfo Var)
		Return GetBoxDimension(text, 100000, 100000, parseInfo, defaultDrawSettings)
	End Method


	Method GetDimension:SVec2I(text:String)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local result:SVec2I = GetBoxDimension(text, 100000, 100000, globalBoxParseInfo, defaultDrawSettings)
		UnlockMutex(globalBoxParseInfoMutex)

		Return result
	End Method


	Method GetWidth:Int(text:String, boxWidth:Float, boxHeight:Float)
		Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawSettings).x
	End Method


	Method GetWidth:Int(text:String, effect:TDrawTextEffect)
		If effect
			Return GetBoxDimension(text, 100000, 10000, effect.data, defaultDrawSettings).x
		Else
			Return GetBoxDimension(text, 100000, 10000, defaultDrawEffect, defaultDrawSettings).x
		EndIf
	End Method


	Method GetWidth:Int(text:String, effect:SDrawTextEffect Var)
		Return GetBoxDimension(text, 100000, 10000, effect, defaultDrawSettings).x
	End Method


	Method GetWidth:Int(text:String)
		Return GetBoxDimension(text, 100000, 10000, defaultDrawEffect, defaultDrawSettings).x
	End Method


	Method GetHeight:Int(text:String, boxWidth:Float, boxHeight:Float)
		Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawEffect, defaultDrawSettings).y
	End Method


	Method GetHeight:Int(text:String, effect:TDrawTextEffect)
		If effect
			Return GetBoxDimension(text, 100000, 10000, effect.data, defaultDrawSettings).y
		Else
			Return GetBoxDimension(text, 100000, 10000, defaultDrawEffect, defaultDrawSettings).y
		EndIf
	End Method

	Method GetHeight:Int(text:String, effect:SDrawTextEffect Var)
		Return GetBoxDimension(text, 100000, 10000, effect, defaultDrawSettings).y
	End Method


	Method GetHeight:Int(text:String)
		Return GetBoxDimension(text, 100000, 10000, defaultDrawEffect, defaultDrawSettings).y
	End Method


	Method GetBoxDimension:SVec2I(parseInfo:STextParseInfo Var, settings:SDrawTextSettings Var )
		Return GetBoxDimension(parseInfo, defaultDrawEffect, settings)
	End Method


	Method GetBoxDimension:SVec2I(parseInfo:STextParseInfo Var, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var)
		Select effect.Mode
			Case EDrawTextEffect.Shadow 
				Return New SVec2I(parseInfo.GetBoxWidth(settings.boxDimensionMode) + 1, parseInfo.GetBoxHeight(settings.boxDimensionMode) + 1)
			Case EDrawTextEffect.Glow 
				Return New SVec2I(parseInfo.GetBoxWidth(settings.boxDimensionMode) + 4, parseInfo.GetBoxHeight(settings.boxDimensionMode) + 4)
			Case EDrawTextEffect.Emboss 
				Return New SVec2I(parseInfo.GetBoxWidth(settings.boxDimensionMode), parseInfo.GetBoxHeight(settings.boxDimensionMode) + 1)
			Default
				Return New SVec2I(parseInfo.GetBoxWidth(settings.boxDimensionMode), parseInfo.GetBoxHeight(settings.boxDimensionMode))
		End Select
	End Method


	Method GetBoxDimension:SVec2I(parseInfo:TTextParseInfo, settings:SDrawTextSettings Var )
		Return GetBoxDimension(parseInfo, defaultDrawEffect, settings)
	End Method


	Method GetBoxDimension:SVec2I(parseInfo:TTextParseInfo, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var)
		Select effect.Mode
			Case EDrawTextEffect.Shadow 
				Return New SVec2I(parseInfo.data.GetBoxWidth(settings.boxDimensionMode) + 1, parseInfo.data.GetBoxHeight(settings.boxDimensionMode) + 1)
			Case EDrawTextEffect.Glow 
				Return New SVec2I(parseInfo.data.GetBoxWidth(settings.boxDimensionMode) + 4, parseInfo.data.GetBoxHeight(settings.boxDimensionMode) + 4)
			Case EDrawTextEffect.Emboss 
				Return New SVec2I(parseInfo.data.GetBoxWidth(settings.boxDimensionMode), parseInfo.data.GetBoxHeight(settings.boxDimensionMode) + 1)
			Default
				Return New SVec2I(parseInfo.data.GetBoxWidth(settings.boxDimensionMode), parseInfo.data.GetBoxHeight(settings.boxDimensionMode))
		End Select
	End Method


	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float)
		Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawSettings)
	End Method


	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, effect:TDrawTextEffect)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local result:SVec2I = GetBoxDimension(text, boxWidth, boxHeight, globalBoxParseInfo, effect.data, defaultDrawSettings)
		UnlockMutex(globalBoxParseInfoMutex)

		Return result
	End Method


	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local result:SVec2I = GetBoxDimension(text, boxWidth, boxHeight, globalBoxParseInfo, effect, settings)
		UnlockMutex(globalBoxParseInfoMutex)

		Return result
	End Method
	

	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, settings:SDrawTextSettings Var)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local result:SVec2I = GetBoxDimension(text, boxWidth, boxHeight, globalBoxParseInfo, settings)
		UnlockMutex(globalBoxParseInfoMutex)

		Return result
	End Method

	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, settings:TDrawTextSettings)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local result:SVec2I
		If settings
			result = GetBoxDimension(text, boxWidth, boxHeight, globalBoxParseInfo, settings.data)
		Else
			result = GetBoxDimension(text, boxWidth, boxHeight, globalBoxParseInfo, defaultDrawSettings)
		EndIf
		UnlockMutex(globalBoxParseInfoMutex)

		Return result
	End Method


	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, parseInfo:TTextParseInfo, settings:SDrawTextSettings Var)
		Return GetBoxDimension(text, boxWidth, boxHeight, parseInfo, defaultDrawEffect, settings)
	End Method
	

	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, parseInfo:STextParseInfo Var, settings:SDrawTextSettings Var)
		Return GetBoxDimension(text, boxWidth, boxHeight, parseInfo, defaultDrawEffect, settings)
	End Method


	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, parseInfo:TTextParseInfo, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var)
		'calculate line widths/heights and total text width/height
		Local font:TBitmapFont = Self
		If Not parseInfo.data.calculated Then parseInfo.data.CalculateDimensions(text, boxWidth, boxHeight, font, settings)
	
		Return GetBoxDimension(parseInfo, effect, settings)
	End Method

	
	Method GetBoxDimension:SVec2I(text:String, boxWidth:Float, boxHeight:Float, parseInfo:STextParseInfo Var, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var)
		'calculate line widths/heights and total text width/height
		Local font:TBitmapFont = Self
		If Not parseInfo.calculated Then parseInfo.CalculateDimensions(text, boxWidth, boxHeight, font, settings)
	
		Return GetBoxDimension(parseInfo, effect, settings)
	End Method


	Method GetBoxWidth:Int(text:String, boxWidth:Float, boxHeight:Float)
		Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawSettings).x
	End Method

	Method GetBoxWidth:Int(text:String, boxWidth:Float, boxHeight:Float, settings:SDrawTextSettings Var)
		Return GetBoxDimension(text, boxWidth, boxHeight, settings).x
	End Method

	Method GetBoxWidth:Int(text:String, boxWidth:Float, boxHeight:Float, settings:TDrawTextSettings)
		If settings
			Return GetBoxDimension(text, boxWidth, boxHeight, settings.data).x
		Else
			Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawSettings).x
		EndIf
	End Method


	Method GetBoxHeight:Int(text:String, boxWidth:Float, boxHeight:Float)
		Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawSettings).y
	End Method
	
	Method GetBoxHeight:Int(text:String, boxWidth:Float, boxHeight:Float, settings:SDrawTextSettings Var)
		Return GetBoxDimension(text, boxWidth, boxHeight, settings).y
	End Method

	Method GetBoxHeight:Int(text:String, boxWidth:Float, boxHeight:Float, settings:TDrawTextSettings)
		If settings
			Return GetBoxDimension(text, boxWidth, boxHeight, settings.data).y
		Else
			Return GetBoxDimension(text, boxWidth, boxHeight, defaultDrawSettings).y
		EndIf
	End Method

	' returns how many pixels to advance when rendering the char
	' lineWidth is used for "tab" position calculation
	Method __GetCharAdvance:SVec2F(bm:TBitmapFontChar, charCode:Int, lineWidth:Float)
		If bm
			If charCode = 32 'space
				Return New SVec2F(+ bm.charWidth * spaceWidthModifier, 0)
			Else
				Return New SVec2F(+ bm.charWidth, 0)
			EndIf
		EndIf

		If charCode = KEY_TAB
			Return New SVec2F(+ (Int(lineWidth / tabWidth)+1) * tabWidth, 0)
		EndIf
		
		Return New SVec2F
	End Method


	Method __GetCharDim:SVec2F(bm:TBitmapFontchar, charCode:Int, lineWidth:Float)
		If bm
			If charCode = 32 'space
				Return New SVec2F(+ bm.charWidth * spaceWidthModifier, bm.dim.y)
			Else
				Return New SVec2F(+ bm.charWidth, bm.dim.y)
			EndIf
		EndIf
		If charCode = KEY_TAB
			Return New SVec2F(+ (Int(lineWidth / tabWidth)+1) * tabWidth, 0)
		EndIf
		
		Return New SVec2F
	End Method



	Method __GetBitmapFontChar:TBitmapFontChar(charCode:Int)
		Local charGroupIndex:Int = charCode Shr 8 'each group contains 256 chars...
		Local charIndex:Int = charCode & $FF 'which one in the 256 ?
		'TODO: Return a default char (some "[?]" thingy ?)
		If charGroupIndex < 0 Then Return Null
		
		' create group if not done yet
		If charGroups.Length <= charGroupIndex Or Not charGroups[charGroupIndex]
			LoadCharGroup(charGroupIndex)

			'debug
			Rem
			Print "FONT "  + FName + ": char group " + charGroupIndex + " loaded."
			Local charCodes:String
			For Local char:TBitmapFontChar = EachIn charGroups[charGroupIndex].chars
				charCodes :+ char.charCode + "=~q" + Chr(char.charCode)+"~q  "
				If charCodes.Length > 120 Then Print charCodes; charCodes =""
			Next
			Print charCodes
			EndRem
		EndIf

		Local bm:TBitmapFontChar = charGroups[charGroupIndex].chars[charIndex]

		'some fonts do not contain the given char ... display "?" there
		If Not bm And (charGroupIndex <> 0 Or charIndex <> Asc("?"))
			bm = __GetBitmapFontChar(Asc("?"))
		EndIf
		Return bm
	End Method


	Method __DrawSingleChar(charCode:Int, x:Float, y:Float)
		__DrawSingleChar(__GetBitmapFontChar(charCode), charCode, x, y)
	End Method


	Method __DrawSingleChar(bm:TBitmapFontchar, charCode:Int, x:Float, y:Float)
		If bm And bm.sprite
			Local tx:Float = bm.pos.x * gfx.tform_ix + bm.pos.y * gfx.tform_iy
			Local ty:Float = bm.pos.x * gfx.tform_jx + bm.pos.y * gfx.tform_jy
			bm.sprite.Draw(Int(x + tx), Int(y + ty))
		EndIf
	End Method


	Method __DrawSingleCharToPixmap(charCode:Int, x:Float, y:Float, color:SColor8)
		__DrawSingleCharToPixmap(__GetBitmapFontChar(charCode), charCode, x, y, color)
	End Method


	Method __DrawSingleCharToPixmap(bm:TBitmapFontchar, charCode:Int, x:Float, y:Float, color:SColor8)
		If bm And bm.sprite
			Local tx:Float = bm.pos.x * gfx.tform_ix + bm.pos.y * gfx.tform_iy
			Local ty:Float = bm.pos.x * gfx.tform_jx + bm.pos.y * gfx.tform_jy
			bm.sprite.DrawOnImageSColor(drawToPixmap, Int(pixmapOrigin.x + x + tx), Int(pixmapOrigin.y + y + ty), -1, Null, color)
		EndIf
	End Method


	Method __DrawSpriteToPixmap(s:TSprite, x:Float, y:Float, color:SColor8, scaleX:Float=1.0, scaleY:Float=1.0)
		s.DrawOnImageSColor(drawToPixmap, Int(pixmapOrigin.x + x), Int(pixmapOrigin.y + y), -1, Null, color, scaleX, scaleY)
	End Method
	

'	Method __DrawEllipsis:SVec2F(x:Float, y:Float, offsetX:Float, offsetY:Float, w:Float, h:Float, handle:SVec2f, currentColor:SColor8)
	Method __DrawEllipsis:SVec2F(x:Float, y:Float, offsetX:Float, offsetY:Float, currentColor:SColor8)
		Local ellipsis:String = GetEllipsis()
		Local bm:TBitmapFontChar
		Local charCode:Int
		Local textX:Float, width:Float
		
		For Local ellipsisIndex:Int = 0 Until ellipsis.Length
			charCode = ellipsis[ellipsisIndex]
			bm = __GetBitmapFontChar(charCode)

			Local transformedPos:SVec2F = __GetTransformedPosition(x + textX, y, offsetX, offsetY)

			If Not BITMAPFONTBENCHMARK
				If drawToPixmap
					__DrawSingleCharToPixmap(bm, charCode, transformedPos.x, transformedPos.y, currentColor)
				Else
'					__DrawSingleChar(bm, charCode, x + offsetX, y + offsetY)
					__DrawSingleChar(bm, charCode, transformedPos.x, transformedPos.y)
				EndIf
			EndIf

			textX :+ __GetCharAdvance(bm, charCode, 0).x
			width :+ __GetCharDim(bm, charCode, 0).x
		Next
		Return New SVec2F(textX, width)
	End Method
	
	
	Method GetBoxLineText:String(txt:String, lineIndex:Int, w:Float, h:Float, settings:TDrawTextSettings, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		LockMutex(globalBoxParseInfoMutex)
		Local currentFont:TBitmapFont = Self

		globalBoxParseInfo.data.calculated = False
		If settings
			globalBoxParseInfo.data.CalculateDimensions(txt, w, h, currentFont, settings.data)
		Else
			globalBoxParseInfo.data.CalculateDimensions(txt, w, h, currentFont, defaultDrawSettings)
		EndIf

		Local nextLineBreakIndex:Int = globalBoxParseInfo.data.lineinfo_lineBreakIndices[0]
		Local lastLineBreakIndex:Int = 0
		Local result:String
		Local currentIndex:Int
		Repeat
			If currentIndex = lineIndex
				result = txt[lastLineBreakIndex .. nextLineBreakIndex+1]
				Exit
			EndIf

			currentIndex:+ 1
		
			Local dynamicIndex:Int = currentIndex - globalBoxParseInfo.data.lineinfo_boxHeights.Length
			If dynamicIndex >= 0
				lastLineBreakIndex = nextLineBreakIndex + 1
				nextLineBreakIndex = globalBoxParseInfo.data.lineinfo_lineBreakIndicesDynamic[dynamicIndex]
			Else
				lastLineBreakIndex = nextLineBreakIndex + 1
				nextLineBreakIndex = globalBoxParseInfo.data.lineinfo_lineBreakIndices[currentIndex]
			EndIf
			
		Until currentIndex > lineIndex
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return result
	End Method


	'=== BOX / BLOCK TEXT
	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, color:SColor8)
		Return DrawBox(txt, x, y, w, h, New SVec2F(0.0, 0.0), color, Null, EDRawTextOption.None)
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8)
		Return DrawBox(txt, x,y,w,h, alignment, color, defaultDrawSettings)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, settings:TDrawTextSettings)
		If settings
			Return DrawBox(txt, x, y, w, h, alignment, color, settings.data)
		Else
			Return DrawBox(txt, x, y, w, h, alignment, color, defaultDrawSettings)
		EndIf
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, settings:SDrawTextSettings Var)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local dim:SVec2I = DrawBox(txt, x, y, w, h, alignment, color, Null, globalBoxParseInfo.data, EDrawTextOption.None, defaultDrawEffect, settings)
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return dim
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, settings:TDrawTextSettings, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		If settings
			Return DrawBox(txt, x, y, w, h, alignment, color, settings.data, effectMode, effectValue)
		Else
			Return DrawBox(txt, x, y, w, h, alignment, color, defaultDrawSettings, effectMode, effectValue)
		EndIf
	End Method
	
	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, settings:SDrawTextSettings Var, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue

		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local dim:SVec2I = DrawBox(txt, x, y, w, h, alignment, color, Null, globalBoxParseInfo, EDrawTextOption.None, effect, settings)
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return dim
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, parseInfo:TTextParseInfo)
		Return DrawBox(txt, x, y, w, h, alignment, color, Null, parseInfo, EDrawTextOption.None)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, parseInfo:STextParseInfo Var)
		Return DrawBox(txt, x, y, w, h, alignment, color, Null, parseInfo, EDrawTextOption.None)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8,  parseInfo:TTextParseInfo, effect:TDrawTextEffect)
		Return DrawBox(txt, x, y, w, h, alignment, color,  parseInfo, effect.data.Mode, effect.data.value)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8,  parseInfo:STextParseInfo Var, effect:TDrawTextEffect)
		Return DrawBox(txt, x, y, w, h, alignment, color,  parseInfo, effect.data.Mode, effect.data.value)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8,  parseInfo:TTextParseInfo, effect:SDrawTextEffect Var)
		Return DrawBox(txt, x, y, w, h, alignment, color,  parseInfo, effect.Mode, effect.value)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8,  parseInfo:STextParseInfo Var, effect:SDrawTextEffect Var)
		Return DrawBox(txt, x, y, w, h, alignment, color,  parseInfo, effect.Mode, effect.value)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8,  parseInfo:TTextParseInfo, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue
		Return DrawBox(txt, x, y, w, h, alignment, color, Null, parseInfo, EDrawTextOption.None, effect, defaultDrawSettings)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8,  parseInfo:STextParseInfo Var, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue
		Return DrawBox(txt, x, y, w, h, alignment, color, Null, parseInfo, EDrawTextOption.None, effect, defaultDrawSettings)
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, color:SColor8,  parseInfo:TTextParseInfo, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue

		Return DrawBox(txt, x, y, w, h, New SVec2F(0.0, 0.0), color, Null, parseInfo, EDrawTextOption.None, effect, defaultDrawSettings)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, color:SColor8,  parseInfo:STextParseInfo Var, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue

		Return DrawBox(txt, x, y, w, h, New SVec2F(0.0, 0.0), color, Null, parseInfo, EDrawTextOption.None, effect, defaultDrawSettings)
	End Method
	

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, color:SColor8, handle:SVec2F, options:EDrawTextOption = EDrawTextOption.None)
		Return DrawBox(txt, x, y, w, h, New SVec2F(0.0, 0.0), color, handle, options)
	End Method
	

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, options:EDrawTextOption = EDrawTextOption.None)
		Return DrawBox(txt, x,y,w,h, alignment, color, handle, options, defaultDrawSettings)
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, options:EDrawTextOption = EDrawTextOption.None, settings:TDrawTextSettings)
		Return DrawBox(txt, x, y, w, h, alignment, color, handle, options, settings.data)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, options:EDrawTextOption = EDrawTextOption.None, settings:SDrawTextSettings Var)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local dim:SVec2I = DrawBox(txt, x, y, w, h, alignment, color, handle, globalBoxParseInfo, options, defaultDrawEffect, settings)
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return dim
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, effect:SDrawTextEffect)
		'Return DrawBox(txt, x, y, w, h, alignment, color, effect.Mode, effect.value)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		DrawBox(txt, x, y, w, h, alignment, color, New SVec2F(0,0), globalBoxParseInfo, EDrawTextOption.None, effect, defaultDrawSettings)
		Local dim:SVec2I = GetBoxDimension(globalBoxParseInfo.data, effect, defaultDrawSettings)
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return dim
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
'		DrawBox(txt, x, y, w, h, alignment, color, new SVec2F(0,0), effectMode, effectValue)
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue
		Local dim:SVec2I = DrawBox(txt, x, y, w, h, alignment, color, effect)

		Rem
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		DrawBox(txt, x, y, w, h, alignment, color, New SVec2F(0,0), globalBoxParseInfo.data, EDrawTextOption.None, effect, defaultDrawSettings)
		Local dim:SVec2I = GetBoxDimension(globalBoxParseInfo.data, effect, defaultDrawSettings)
		UnlockMutex(globalBoxParseInfoMutex)
		EndRem

		Return dim
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, effectMode:EDrawTextEffect, effectValue:Float = -1.0)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local effect:SDrawTextEffect
		effect.Mode = effectMode
		effect.value = effectValue
		Local dim:SVec2I = DrawBox(txt, x, y, w, h, alignment, color, handle, globalBoxParseInfo, EDrawTextOption.None, effect, defaultDrawSettings)
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return dim
	End Method
	
	
	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:TTextParseInfo, options:EDrawTextOption = EDrawTextOption.None)
		Return DrawBox(txt, x,y,w,h, alignment, color, handle, parseInfo, options, defaultDrawEffect, defaultDrawSettings)
	End Method

	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:STextParseInfo Var, options:EDrawTextOption = EDrawTextOption.None)
		Return DrawBox(txt, x,y,w,h, alignment, color, handle, parseInfo, options, defaultDrawEffect, defaultDrawSettings)
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, options:EDrawTextOption = EDrawTextOption.None, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var, limitFirstElement:Int = -1, limitLastElement:Int = -1)
		LockMutex(globalBoxParseInfoMutex)
		globalBoxParseInfo.data.calculated = False
		Local dim:SVec2I = DrawBox(txt, x, y, w, h, alignment, color, handle, globalBoxParseInfo, options, effect, settings, limitFirstElement, limitLastElement)
		UnlockMutex(globalBoxParseInfoMutex)
		
		Return dim
	End Method

	'main definition (including styles)
	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:TTextParseInfo, options:EDrawTextOption = EDrawTextOption.None, effect:TDrawTextEffect, settings:TDrawTextSettings, limitFirstElement:Int = -1, limitLastElement:Int = -1)
		If Not parseInfo
			If Not effect And Not settings
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, options, defaultDrawEffect, defaultDrawSettings, limitFirstElement, limitLastElement)
			ElseIf Not effect
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, options, defaultDrawEffect, settings.data, limitFirstElement, limitLastElement)
			ElseIf Not settings
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, options, effect.data, defaultDrawSettings, limitFirstElement, limitLastElement)
			Else
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, options, effect.data, settings.data, limitFirstElement, limitLastElement)
			EndIf
		Else
			If Not effect And Not settings
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, parseInfo, options, defaultDrawEffect, defaultDrawSettings, limitFirstElement, limitLastElement)
			ElseIf Not effect
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, parseInfo, options, defaultDrawEffect, settings.data, limitFirstElement, limitLastElement)
			ElseIf Not settings
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, parseInfo, options, effect.data, defaultDrawSettings, limitFirstElement, limitLastElement)
			Else
				Return DrawBox(txt, x, y, w, h, alignment, color, handle, parseInfo, options, effect.data, settings.data, limitFirstElement, limitLastElement)
			EndIf
		EndIf
	End Method


	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:TTextParseInfo, options:EDrawTextOption = EDrawTextOption.None, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var, limitFirstElement:Int = -1, limitLastElement:Int = -1)
		Local effectValue:Float = effect.value

		Select effect.Mode
			Case EDrawTextEffect.SHADOW
				If effectValue = -1 Then effectValue = 0.6

				Local shadowColor8:SColor8 = New SColor8(shadowColor.r, shadowColor.g, shadowColor.b, Int(color.a/255.0 * shadowColor.a * effectValue))
				__DrawBox(txt, x + 1, y+1, w-1, h-1, alignment, shadowColor8, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x, y, w-1, h-1, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo.data._visibleBoxWidth + 1, parseInfo.data._visibleBoxHeight + 1)


			Case EDrawTextEffect.GLOW
				If effectValue = -1 Then effectValue = 0.5

				'subtract 1 height so emboss stays in the box

				Local glowColor8a:SColor8 = New SColor8(effect.color.r, effect.color.g, effect.color.b, Int(color.a/255.0 * effect.color.a * 0.5 * effectValue))
				Local glowColor8b:SColor8 = New SColor8(effect.color.r, effect.color.g, effect.color.b, Int(color.a/255.0 * effect.color.a * 1.0 * effectValue))
				__DrawBox(txt, x  ,y+2,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x+4,y+2,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x+2,y  ,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x+2,y+4,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x+3,y+3,w-4,h-4, alignment, glowColor8b, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x+1,y+1,w-4,h-4, alignment, glowColor8b, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x+2, y+2, w-4, h-4, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo.data._visibleBoxWidth + 4, parseInfo.data._visibleBoxHeight + 4)

			Case EDrawTextEffect.EMBOSS
				If effectValue = -1 Then effectValue = 0.5

				'subtract 1 height so emboss stays in the box

				Local embossColor8:SColor8 = New SColor8(embossColor.r, embossColor.g, embossColor.b, Int(color.a/255.0 * embossColor.a * effectValue))
				__DrawBox(txt, x, y+1, w, h-1, alignment, embossColor8, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x, y, w, h-1, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo.data._visibleBoxWidth, parseInfo.data._visibleBoxHeight + 1)


			Default
				__DrawBox(txt, x,y,w,h, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo.data._visibleBoxWidth, parseInfo.data._visibleBoxHeight)

		End Select
	End Method	
	Method DrawBox:SVec2I(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:STextParseInfo Var, options:EDrawTextOption = EDrawTextOption.None, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var, limitFirstElement:Int = -1, limitLastElement:Int = -1)
		Local effectValue:Float = effect.value

		Select effect.Mode
			Case EDrawTextEffect.SHADOW
				If effectValue = -1 Then effectValue = 0.6

				Local shadowColor8:SColor8 = New SColor8(shadowColor.r, shadowColor.g, shadowColor.b, Int(color.a/255.0 * shadowColor.a * effectValue))
				__DrawBox(txt, X + 1, Y+1, w-1, h-1, alignment, shadowColor8, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x, y, w-1, h-1, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo._visibleBoxWidth + 1, parseInfo._visibleBoxHeight + 1)


			Case EDrawTextEffect.GLOW
				If effectValue = -1 Then effectValue = 0.5

				'subtract 1 height so emboss stays in the box

				Local glowColor8a:SColor8 = New SColor8(effect.color.r, effect.color.g, effect.color.b, Int(color.a/255.0 * effect.color.a * 0.5 * effectValue))
				Local glowColor8b:SColor8 = New SColor8(effect.color.r, effect.color.g, effect.color.b, Int(color.a/255.0 * effect.color.a * 1.0 * effectValue))
				__DrawBox(txt, X  ,Y+2,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, X+4,Y+2,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, X+2,Y  ,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, X+2,Y+4,w-4,h-4, alignment, glowColor8a, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, X+3,Y+3,w-4,h-4, alignment, glowColor8b, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, X+1,Y+1,w-4,h-4, alignment, glowColor8b, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, X+2, Y+2, w-4, h-4, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo._visibleBoxWidth + 4, parseInfo._visibleBoxHeight + 4)

			Case EDrawTextEffect.EMBOSS
				If effectValue = -1 Then effectValue = 0.5

				'subtract 1 height so emboss stays in the box

				Local embossColor8:SColor8 = New SColor8(embossColor.r, embossColor.g, embossColor.b, Int(color.a/255.0 * embossColor.a * effectValue))
				__DrawBox(txt, X, Y+1, w, h-1, alignment, embossColor8, handle, parseInfo, options | EDrawTextOption.IgnoreColor, settings, limitFirstElement, limitLastElement)
				__DrawBox(txt, x, y, w, h-1, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo._visibleBoxWidth, parseInfo._visibleBoxHeight + 1)


			Default
				__DrawBox(txt, X,Y,w,h, alignment, color, handle, parseInfo, options, settings, limitFirstElement, limitLastElement)
				Return New SVec2I(parseInfo._visibleBoxWidth, parseInfo._visibleBoxHeight)

		End Select
	End Method


	Method __GetTransformedPosition:SVec2F( x:Float, y:Float, offsetX:Float = 0.0, offsetY:Float = 0.0)
'		Local tempX:Float = x
'		x = x * gfx.tform_ix + y * gfx.tform_iy
'		y = tempX * gfx.tform_jx + y *gfx.tform_jy
		
'		local transformedX:Float = x * gfx.tform_ix + y * gfx.tform_iy
'		local transformedY:Float = x * gfx.tform_jx + y * gfx.tform_jy
'		x = transformedX
'		y = transformedY
		Return New SVec2F(offsetX + x * gfx.tform_ix + y * gfx.tform_iy, ..
		                  offsetY + x * gfx.tform_jx + y * gfx.tform_jy)
	End Method


	Method __DrawBox(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:TTextParseInfo, options:EDrawTextOption, settings:SDrawTextSettings Var, limitFirstElement:Int = -1, limitLastElement:Int = -1)
		Local screenColor:SColor8
		Local screenColorA:Float
		Local currentColor:SColor8 = color
		GetColor(screenColor)
		screenColorA = GetAlpha()
		X :+ 1 * handle.X*w
		Y :+ 1 * handle.Y*h

		'currently in use font
		Local currentFont:TBitmapFont = Self
		
		If Not drawToPixmap
			parseInfo.data.baseColor = New SColor8(color.r, color.g, color.b, Int(color.a * screenColorA))
		Else
			parseInfo.data.baseColor = color
		EndIf

		'calculate line widths/heights and total text width/height
		If Not parseInfo.data.calculated
			parseInfo.data.CalculateDimensions(txt, w, h, currentFont, settings)
			parseInfo.data.calculated = True
		EndIf


		' some single character (required to be displayed) was not
		' able to get fit into the box ... abort rendering at all
		If Not parseInfo.data.minimumTextFitsIntoBox
			Return
		EndIf


		'if block width exceeds allowed width we cannot render it
		'(this happens if box is less wide than a single char)
		If (parseInfo.data._visibleBoxWidth > w And w > 0) Or parseInfo.data._visibleBoxWidth = -1
			Return
		EndIf


		' ensure to start code commands afresh ...
		' to avoid issues with more tags being opened than closed
		parseInfo.data.ResetStyle()


		' Rendering
		Local currentLine:Int = 1
		Local textX:Float, textY:Float, lineWidth:Float
		Local nextLineBreakIndex:Int = parseInfo.data.lineinfo_lineBreakIndices[0]
		
		'if current line already does not fit
		'TODO: Offset for "alignment" ...
		'skip rendering if even a single line does not fit

		If parseInfo.data.GetLineHeight(1, settings.boxDimensionMode) > h And h > 0 Then Return
		If parseInfo.data.GetLineWidth(1, settings.boxDimensionMode) > w And w > 0 Then Return

		Local localX:Float '= gfx.origin_x + gfx.handle_x * gfx.tform_ix + gfx.handle_y * gfx.tform_iy
		Local localY:Float '= gfx.origin_y + gfx.handle_x * gfx.tform_jx + gfx.handle_y * gfx.tform_jy
		localX :+ X
		localY :+ Y


		textX = alignment.X * (w - parseInfo.data.GetLineWidth(1, settings.boxDimensionMode))
		textY = alignment.Y * (h - parseInfo.data.GetBoxHeight(settings.boxDimensionMode))
		textX = Int(textX)
		textY = Int(textY)

		'avoid text starting earlier
		If textY < 0 Then textY = 0


		Local currentDisplaceY:Short
		Select settings.lineHeightMode
			Case EDrawLineHeightModes.AllLinesMax, EDrawLineHeightModes.FixedOrAllLinesMax
				currentDisplaceY = parseInfo.data.lineFontDisplaceYMax
			Default 'lineMax
				currentDisplaceY = parseInfo.data.lineinfo_fontDisplaceYs[0]
		EndSelect

		Local element:STextParseElement
		Local fontChanges:Int

'		If Not(options & EDrawTextOption.IgnoreColor)
		If Not drawToPixmap
			SetColor(parseInfo.data.baseColor)
			'SetAlpha(currentColor.a/255.0)
			SetAlpha(parseInfo.data.baseColor.a / 255.0)
		EndIf
'		EndIf
		Local renderedElementCount:Int = 0
		For Local i:Int = 0 Until txt.Length

			Local charCode:Int = txt[i]
			Local escaped:Int = False

			Local dynamicIndex:Int = currentLine - parseInfo.data.lineinfo_BoxHeights.Length

			'only render what parseInfo was able to process
			If i > parseInfo.data.handledCharIndex Then Exit
			If parseInfo.data.truncateEndIndex >= 0 And i > parseInfo.data.truncateEndIndex Then Exit

			' append an ellipsis / truncate here?
			' but only if we can draw an ellipsis ..
			If parseInfo.data.truncateEndIndex >= 0 And i >= parseInfo.data.truncateEndIndex
				If settings.truncateWithEllipse
					If (w < 0 Or textX + Self.GetEllipsisWidth() <= w)
						If (limitFirstElement<=i) And (limitLastElement<0 Or limitLastElement>=i)
							If parseInfo.data.stylesInvisible = 0
								'draw ellipsis in current font or default font style?
								'currentFont.__DrawEllipsis(x, y, textX, textY - currentFont.displaceY, currentColor, rotation, lineWidth, parseInfo.data.lineHeights[currentLine])
								If Not (options & EDrawTextOption.IgnoreColor)
									If Not drawToPixmap
										SetColor(parseInfo.data.baseColor)
										SetAlpha(parseInfo.data.baseColor.a  / 255.0) * (currentColor.a  / 255.0)
									EndIf
									__DrawEllipsis(textX - handle.X * w, textY - handle.Y*h - currentDisplaceY, localX, localY, parseInfo.data.baseColor)
									If Not drawToPixmap
										SetColor(currentColor)
										SetAlpha(currentColor.a / 255.0)
									EndIf
								Else
'									__DrawEllipsis(textX - handle.x * w, textY - handle.y*h - currentDisplaceY, x + localX, y + localY, parseInfo.data.baseColor)
									__DrawEllipsis(textX - handle.X * w, textY - handle.Y*h - currentDisplaceY, localX, localY, parseInfo.data.baseColor)
								EndIf
							EndIf
							
							renderedElementCount :+ 1
						EndIf
					EndIf
				EndIf
				i = txt.Length
				Exit
			EndIf

		
			' escaping command or escape char?
			If charCode = ESCAPE_CHARCODE And i < txt.Length - 2 And (txt[i+1] = COMMAND_CHARCODE Or txt[i+1] = ESCAPE_CHARCODE)
				i :+ 1
				charCode = txt[i]
				escaped = True
			EndIf


			' reading command?
			' for now we ignore any escape chars within an active command
			' so no "|b \|escaped stuff|bold text|/b|" -- this would fail!
			If charCode = COMMAND_CHARCODE And Not escaped
				element = parseInfo.data.HandleCommand(currentFont, txt, i, Int(X + textX), Int(Y + textY))
				fontChanges :+ element.changedFont

				'handle commands only changing colors (etc) but not
				'altering the layout
				If drawToPixmap And (options & EDrawTextOption.IgnoreColor)
					Local ignoreColor:SColor8
					parseInfo.data.HandleVisibleOnlyCommands(currentFont, txt, i, ignoreColor)
				Else
					parseInfo.data.HandleVisibleOnlyCommands(currentFont, txt, i, currentColor)
				EndIf

				' react to font changes (if required)
				If element.changedFont 
					parseInfo.data.HandleFontChanges(currentFont, True)
					
					If settings.lineHeightMode = EDrawLineHeightModes.LineMax
						currentDisplaceY = Max(currentDisplaceY, currentFont.displaceY)
					EndIf
				EndIf

			' received char potentially being displayed
			Else
				element = parseInfo.data.HandleChar(currentFont, txt, i, textX, Null)

				'disable eating of whitespace?
				If Not settings.skipOptionalElementOnEOL Then element.skipOnLinebreak = False
			EndIf
			
			If element.visible And parseInfo.data.colorChanged And Not(options & EDrawTextOption.IgnoreColor)
				If Not drawToPixmap
					SetColor(currentColor)
					SetAlpha((parseInfo.data.baseColor.a / 255.0) * (currentColor.a  / 255.0))
				EndIf
			EndIf


			'is this the last char on this line?
			Local doLineBreak:Int = (i >= nextLineBreakIndex)

			'no need to check further
			If limitLastElement>=0 And renderedElementCount > limitLastElement Then Exit

			'render out the char
			If element.visible And Not (doLineBreak And element.skipOnLinebreak)
				If (limitFirstElement<=renderedElementCount)
					If parseInfo.data.stylesInvisible = 0
						' actually render the glyph and advance
						If Not BITMAPFONTBENCHMARK
							If element.width > 0 And element.height > 0
								'local transformedX:Float = localX + (textX - handle.x*w) * ix + (textY - handle.y*h - currentDisplaceY) * iy
								'local transformedY:Float = localY + (textX - handle.x*w) * jx + (textY - handle.y*h - currentDisplaceY) * jy
								Local transformedPos:SVec2F = __GetTransformedPosition(textX - handle.X*w, textY - handle.Y*h - currentDisplaceY, localX, localY)

								If TBitmapFontChar(element.renderObject)
									Local bm:TBitmapFontChar = TBitmapFontChar(element.renderObject)
									If drawToPixmap
										currentFont.__DrawSingleCharToPixmap(bm, charCode, X + textX, Y + textY - currentDisplaceY, currentColor)
									Else
										currentFont.__DrawSingleChar(bm, charCode, transformedPos.X, transformedPos.Y)
									EndIf
								ElseIf TSprite(element.renderObject)
									Local ox:Float, oy:Float
									GetScale(ox, oy)

									Local s:TSprite = TSprite(element.renderObject)
									If Self.drawToPixmap
										ox = ox * Float(element.width)/s.GetWidth()
										oy = oy * Float(element.height)/s.GetHeight()
										Local alphaAdjustedColor:SColor8 = New SColor8(255,255,255, parseInfo.data.baseColor.a)
										If ox <> 1 Or oy <> 1
											Self.__DrawSpriteToPixmap(s, X + transformedPos.X, Y + transformedPos.Y, alphaAdjustedColor, ox, oy)
										Else
											Self.__DrawSpriteToPixmap(s, X + transformedPos.X, Y + transformedPos.Y, alphaAdjustedColor)
										EndIf
									Else
										SetColor 255,255,255
										SetScale(ox * element.width/Float(s.GetWidth()), oy * element.height/Float(s.GetHeight()))
										s.Draw(transformedPos.X, transformedPos.Y) 
										SetScale(ox, oy)
										SetColor(currentColor)
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
					
					renderedElementCount :+ 1

					textX :+ element.advWidth
					lineWidth :+ element.width
				EndIf
			EndIf


			If doLineBreak
				Local nextLine:Int = currentLine + 1

				textY :+ parseInfo.data.GetLineHeight(currentLine, settings.boxDimensionMode )
				textX = 0

				If nextLine <= parseInfo.data.totalLineCount
					textX = alignment.X * (w - parseInfo.data.GetLineWidth(nextLine))
					'avoid blurred lines
					textX = Int(textX)

					dynamicIndex = nextLine - parseInfo.data.lineinfo_boxHeights.Length - 1
					If dynamicIndex >= 0
						nextLineBreakIndex = parseInfo.data.lineinfo_lineBreakIndicesDynamic[dynamicIndex]

						If settings.lineHeightMode = EDrawLineHeightModes.LineMax
							currentDisplaceY = parseInfo.data.lineinfo_fontDisplaceYsDynamic[dynamicIndex]
						EndIf
					Else
						nextLineBreakIndex = parseInfo.data.lineinfo_lineBreakIndices[nextLine - 1]
						
						If settings.lineHeightMode = EDrawLineHeightModes.LineMax
							currentDisplaceY = parseInfo.data.lineinfo_fontDisplaceYs[nextLine - 1]
						EndIf
					EndIf
				EndIf

				lineWidth = 0
				currentLine :+ 1
			EndIf
		Next
		SetColor(screenColor)
		SetAlpha(screenColorA)
	End Method
	Method __DrawBox(txt:String,x:Float,y:Float,w:Float,h:Float, alignment:SVec2F, color:SColor8, handle:SVec2F, parseInfo:STextParseInfo Var, options:EDrawTextOption, settings:SDrawTextSettings Var, limitFirstElement:Int = -1, limitLastElement:Int = -1)
		Local screenColor:SColor8
		Local screenColorA:Float
		Local currentColor:SColor8 = color
		GetColor(screenColor)
		screenColorA = GetAlpha()
		x :+ 1 * handle.x*w
		y :+ 1 * handle.y*h

		'currently in use font
		Local currentFont:TBitmapFont = Self
		
		If Not drawToPixmap
			parseInfo.baseColor = New SColor8(color.r, color.g, color.b, Int(color.a * screenColorA))
		Else
			parseInfo.baseColor = color
		EndIf

		'calculate line widths/heights and total text width/height
		If Not parseInfo.calculated
			parseInfo.CalculateDimensions(txt, w, h, currentFont, settings)
			parseInfo.calculated = True
		EndIf


		' some single character (required to be displayed) was not
		' able to get fit into the box ... abort rendering at all
		If Not parseInfo.minimumTextFitsIntoBox
			Return
		EndIf


		'if block width exceeds allowed width we cannot render it
		'(this happens if box is less wide than a single char)
		If (parseInfo._visibleBoxWidth > w And w > 0) Or parseInfo._visibleBoxWidth = -1
			Return
		EndIf


		' ensure to start code commands afresh ...
		' to avoid issues with more tags being opened than closed
		parseInfo.ResetStyle()


		' Rendering
		Local currentLine:Int = 1
		Local textX:Float, textY:Float, lineWidth:Float
		Local nextLineBreakIndex:Int = parseInfo.lineinfo_lineBreakIndices[0]
		
		'if current line already does not fit
		'TODO: Offset for "alignment" ...
		'skip rendering if even a single line does not fit

		If parseInfo.GetLineHeight(1, settings.boxDimensionMode) > h And h > 0 Then Return
		If parseInfo.GetLineWidth(1, settings.boxDimensionMode) > w And w > 0 Then Return

		Local localX:Float '= gfx.origin_x + gfx.handle_x * gfx.tform_ix + gfx.handle_y * gfx.tform_iy
		Local localY:Float '= gfx.origin_y + gfx.handle_x * gfx.tform_jx + gfx.handle_y * gfx.tform_jy
		localX :+ x
		localY :+ y


		textX = alignment.x * (w - parseInfo.GetLineWidth(1, settings.boxDimensionMode))
		textY = alignment.y * (h - parseInfo.GetBoxHeight(settings.boxDimensionMode))
		textX = Int(textX)
		textY = Int(textY)

		'avoid text starting earlier
		If textY < 0 Then textY = 0


		Local currentDisplaceY:Short
		Select settings.lineHeightMode
			Case EDrawLineHeightModes.AllLinesMax, EDrawLineHeightModes.FixedOrAllLinesMax
				currentDisplaceY = parseInfo.lineFontDisplaceYMax
			Default 'lineMax
				currentDisplaceY = parseInfo.lineinfo_fontDisplaceYs[0]
		EndSelect

		Local element:STextParseElement
		Local fontChanges:Int

'		If Not(options & EDrawTextOption.IgnoreColor)
		If Not drawToPixmap
			SetColor(parseInfo.baseColor)
			'SetAlpha(currentColor.a/255.0)
			SetAlpha(parseInfo.baseColor.a / 255.0)
		EndIf
'		EndIf
		Local renderedElementCount:Int = 0
		For Local i:Int = 0 Until txt.Length

			Local charCode:Int = txt[i]
			Local escaped:Int = False

			Local dynamicIndex:Int = currentLine - parseInfo.lineinfo_BoxHeights.Length

			'only render what parseInfo was able to process
			If i > parseInfo.handledCharIndex Then Exit
			If parseInfo.truncateEndIndex >= 0 And i > parseInfo.truncateEndIndex Then Exit

			' append an ellipsis / truncate here?
			' but only if we can draw an ellipsis ..
			If parseInfo.truncateEndIndex >= 0 And i >= parseInfo.truncateEndIndex
				If settings.truncateWithEllipse
					If (w < 0 Or textX + Self.GetEllipsisWidth() <= w)
						If (limitFirstElement<=i) And (limitLastElement<0 Or limitLastElement>=i)
							If parseInfo.stylesInvisible = 0
								'draw ellipsis in current font or default font style?
								'currentFont.__DrawEllipsis(x, y, textX, textY - currentFont.displaceY, currentColor, rotation, lineWidth, parseInfo.lineHeights[currentLine])
								If Not (options & EDrawTextOption.IgnoreColor)
									If Not drawToPixmap
										SetColor(parseInfo.baseColor)
										SetAlpha(parseInfo.baseColor.a  / 255.0) * (currentColor.a  / 255.0)
									EndIf
									__DrawEllipsis(textX - handle.x * w, textY - handle.y*h - currentDisplaceY, localX, localY, parseInfo.baseColor)
									If Not drawToPixmap
										SetColor(currentColor)
										SetAlpha(currentColor.a / 255.0)
									EndIf
								Else
'									__DrawEllipsis(textX - handle.x * w, textY - handle.y*h - currentDisplaceY, x + localX, y + localY, parseInfo.baseColor)
									__DrawEllipsis(textX - handle.x * w, textY - handle.y*h - currentDisplaceY, localX, localY, parseInfo.baseColor)
								EndIf
							EndIf
							
							renderedElementCount :+ 1
						EndIf
					EndIf
				EndIf
				i = txt.Length
				Exit
			EndIf

		
			' escaping command or escape char?
			If charCode = ESCAPE_CHARCODE And i < txt.Length - 2 And (txt[i+1] = COMMAND_CHARCODE Or txt[i+1] = ESCAPE_CHARCODE)
				i :+ 1
				charCode = txt[i]
				escaped = True
			EndIf


			' reading command?
			' for now we ignore any escape chars within an active command
			' so no "|b \|escaped stuff|bold text|/b|" -- this would fail!
			If charCode = COMMAND_CHARCODE And Not escaped
				element = parseInfo.HandleCommand(currentFont, txt, i, Int(x + textX), Int(y + textY))
				fontChanges :+ element.changedFont

				'handle commands only changing colors (etc) but not
				'altering the layout
				If drawToPixmap And (options & EDrawTextOption.IgnoreColor)
					Local ignoreColor:SColor8
					parseInfo.HandleVisibleOnlyCommands(currentFont, txt, i, ignoreColor)
				Else
					parseInfo.HandleVisibleOnlyCommands(currentFont, txt, i, currentColor)
				EndIf

				' react to font changes (if required)
				If element.changedFont 
					parseInfo.HandleFontChanges(currentFont, True)
					
					If settings.lineHeightMode = EDrawLineHeightModes.LineMax
						currentDisplaceY = Max(currentDisplaceY, currentFont.displaceY)
					EndIf
				EndIf

			' received char potentially being displayed
			Else
				element = parseInfo.HandleChar(currentFont, txt, i, textX, Null)

				'disable eating of whitespace?
				If Not settings.skipOptionalElementOnEOL Then element.skipOnLinebreak = False
			EndIf
			
			If element.visible And parseInfo.colorChanged And Not(options & EDrawTextOption.IgnoreColor)
				If Not drawToPixmap
					SetColor(currentColor)
					SetAlpha((parseInfo.baseColor.a / 255.0) * (currentColor.a  / 255.0))
				EndIf
			EndIf


			'is this the last char on this line?
			Local doLineBreak:Int = (i >= nextLineBreakIndex)

			'no need to check further
			If limitLastElement>=0 And renderedElementCount > limitLastElement Then Exit

			'render out the char
			If element.visible And Not (doLineBreak And element.skipOnLinebreak)
				If (limitFirstElement<=renderedElementCount)
					If parseInfo.stylesInvisible = 0
						' actually render the glyph and advance
						If Not BITMAPFONTBENCHMARK
							If element.width > 0 And element.height > 0
								'local transformedX:Float = localX + (textX - handle.x*w) * ix + (textY - handle.y*h - currentDisplaceY) * iy
								'local transformedY:Float = localY + (textX - handle.x*w) * jx + (textY - handle.y*h - currentDisplaceY) * jy
								Local transformedPos:SVec2F = __GetTransformedPosition(textX - handle.x*w, textY - handle.y*h - currentDisplaceY, localX, localY)

								If TBitmapFontChar(element.renderObject)
									Local bm:TBitmapFontChar = TBitmapFontChar(element.renderObject)
									If drawToPixmap
										currentFont.__DrawSingleCharToPixmap(bm, charCode, x + textX, y + textY - currentDisplaceY, currentColor)
									Else
										currentFont.__DrawSingleChar(bm, charCode, transformedPos.x, transformedPos.y)
									EndIf
								ElseIf TSprite(element.renderObject)
									Local ox:Float, oy:Float
									GetScale(ox, oy)

									Local s:TSprite = TSprite(element.renderObject)
									If Self.drawToPixmap
										ox = ox * Float(element.width)/s.GetWidth()
										oy = oy * Float(element.height)/s.GetHeight()
										Local alphaAdjustedColor:SColor8 = New SColor8(255,255,255, parseInfo.baseColor.a)
										If ox <> 1 Or oy <> 1
											Self.__DrawSpriteToPixmap(s, x + transformedPos.x, y + transformedPos.y, alphaAdjustedColor, ox, oy)
										Else
											Self.__DrawSpriteToPixmap(s, x + transformedPos.x, y + transformedPos.y, alphaAdjustedColor)
										EndIf
									Else
										SetColor 255,255,255
										SetScale(ox * element.width/Float(s.GetWidth()), oy * element.height/Float(s.GetHeight()))
										s.Draw(transformedPos.x, transformedPos.y) 
										SetScale(ox, oy)
										SetColor(currentColor)
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
					
					renderedElementCount :+ 1

					textX :+ element.advWidth
					lineWidth :+ element.width
				EndIf
			EndIf


			If doLineBreak
				Local nextLine:Int = currentLine + 1

				textY :+ parseInfo.GetLineHeight(currentLine, settings.boxDimensionMode )
				textX = 0

				If nextLine <= parseInfo.totalLineCount
					textX = alignment.X * (w - parseInfo.GetLineWidth(nextLine))
					'avoid blurred lines
					textX = Int(textX)

					dynamicIndex = nextLine - parseInfo.lineinfo_boxHeights.Length - 1
					If dynamicIndex >= 0
						nextLineBreakIndex = parseInfo.lineinfo_lineBreakIndicesDynamic[dynamicIndex]

						If settings.lineHeightMode = EDrawLineHeightModes.LineMax
							currentDisplaceY = parseInfo.lineinfo_fontDisplaceYsDynamic[dynamicIndex]
						EndIf
					Else
						nextLineBreakIndex = parseInfo.lineinfo_lineBreakIndices[nextLine - 1]
						
						If settings.lineHeightMode = EDrawLineHeightModes.LineMax
							currentDisplaceY = parseInfo.lineinfo_fontDisplaceYs[nextLine - 1]
						EndIf
					EndIf
				EndIf

				lineWidth = 0
				currentLine :+ 1
			EndIf
		Next
		SetColor(screenColor)
		SetAlpha(screenColorA)
	End Method


	Method Draw:SVec2I(txt:String,x:Float,y:Float)
		Local col:SColor8
		GetColor(col)
		Return Draw(txt, x, y, col)
	End Method


	Method Draw:SVec2I(txt:String,x:Float,y:Float, color:SColor8)
		LockMutex(globalParseInfoMutex)
		globalParseInfo.data.calculated = False
		Local result:SVec2I = DrawBox(txt, x, y, 100000, 100000, New SVec2F(0,0), color, globalParseInfo)
		UnlockMutex(globalParseInfoMutex)
		Return result
	End Method


	Method Draw:SVec2I(txt:String,x:Float,y:Float, color:SColor8, parseInfo:TTextParseInfo)
		Return DrawBox(txt, x, y, 100000, 100000, New SVec2F(0,0), color, parseInfo)
	End Method

	Method Draw:SVec2I(txt:String,x:Float,y:Float, color:SColor8, parseInfo:STextParseInfo Var)
		Return DrawBox(txt, x, y, 100000, 100000, New SVec2F(0,0), color, parseInfo)
	End Method


	'render out globally styled (shadow, glow...) text
	'NO styling support
	Method DrawSimple:SVec2I(txt:String, x:Float, y:Float, color:SColor8, effectMode:EDrawTextEffect, effectValue:Float)
		Local oldCol:SColor8
		Local oldA:Float = GetAlpha()
		GetColor(oldCol)
		
		Local colA:Float = color.a / 255.0

		'modify effectValue and color alpha by screen's  alpha too
		effectValue :* oldA
		colA :* oldA

		Select effectMode
			Case EDrawTextEffect.SHADOW
				If effectValue = -1 Then effectValue = 0.6

				'subtract 1 from width/height so shadow stays in the box
				DrawSimple(txt, x + 1, y+1, shadowColor, shadowColor.a/255.0 * effectValue)
				Local res:SVec2I = DrawSimple(txt, x, y, color, colA)
				Return New SVec2I(res.x + 1, res.y + 1)

			Case EDrawTextEffect.GLOW
				If effectValue = -1 Then effectValue = 0.5

				'subtract 1 height so emboss stays in the box

				DrawSimple(txt, x  ,y+2, embossColor, (embossColor.a/255.0 * 0.5 * effectValue))
				DrawSimple(txt, x+4,y+2, embossColor, (embossColor.a/255.0 * 0.5 * effectValue))
				DrawSimple(txt, x+2,y  , embossColor, (embossColor.a/255.0 * 0.5 * effectValue))
				DrawSimple(txt, x+2,y+4, embossColor, (embossColor.a/255.0 * 0.5 * effectValue))

				DrawSimple(txt, x+3,y+3, embossColor, (embossColor.a/255.0 * 1.0 * effectValue))
				DrawSimple(txt, x+1,y+1, embossColor, (embossColor.a/255.0 * 1.0 * effectValue))

				Local res:SVec2I = DrawSimple(txt, x+2, y+2, color)
				Return New SVec2I(res.x + 4, res.y + 4)

			Case EDrawTextEffect.EMBOSS
				If effectValue = -1 Then effectValue = 0.5

				'subtract 1 height so emboss stays in the box
				DrawSimple(txt, x, y+1, embossColor, (embossColor.a/255.0 * effectValue))
				Local res:SVec2I = DrawSimple(txt, x, y, color)
				Return New SVec2I(res.x, res.y + 1)


			Default
				Return DrawSimple(txt, x, y, color, colA)

		End Select
	End Method


	'render out text
	'NO styling support
	Method DrawSimple:SVec2I(s:String, x:Float, y:Float, color:SColor8, colorAlpha:Float = 1.0)
		Return DrawSimple(s, x, y, color, colorAlpha, New SVec2F(0,0), -1)
	End Method


	Method DrawSimple:SVec2I(s:String, x:Float, y:Float)
		Local col:SColor8
		Local a:Float = GetAlpha()
		GetColor(col)
		Return DrawSimple(s, x, y, col, a, New SVec2F(0,0), -1)
	End Method
	

	Method DrawSimple:SVec2I(s:String, x:Float, y:Float, color:SColor8, colorAlpha:Float = 1.0, handle:SVec2F, fixedLineHeight:Int = -1)
		Local oldColor:SColor8
		Local oldColorA:Float

		'backup screen color
		If Not drawToPixmap
			GetColor(oldColor)
			oldColorA = GetAlpha()
		EndIf

		'if a custom handle is set, we need to know the dimensions 
		Local w:Int, h:Int
		If handle.x <> 0 Or handle.y <> 0
			Local dim:SVec2I = GetSimpleDimension(s, ,fixedLineHeight)
			w = dim.x
			h = dim.y

			x :+ 1 * handle.x*w
			y :+ 1 * handle.y*h
		EndIf

		'take global origin/handle into consideration?
		Local localX:Float '= gfx.origin_x + gfx.handle_x * gfx.tform_ix + gfx.handle_y * gfx.tform_iy
		Local localY:Float '= gfx.origin_y + gfx.handle_x * gfx.tform_jx + gfx.handle_y * gfx.tform_jy
		If Not drawToPixmap 
			localX :+ x
			localY :+ y
		EndIf 

		Local textX:Float
		Local textY:Float
		Local textMaxX:Float
		Local currentLine:Int
		Local rot:Float = GetRotation()
		Local lineContentHeight:Float = Self.GetMaxCharHeight(True)

		Local lineHeight:Int = automaticLineHeight * lineHeightModifier
		If fixedLineHeight >= 0
			lineHeight = fixedLineHeight
		EndIf
'		lineHeight = 20
		'how much to move the content in the line box?
		'TODO: text-valign ?
		Local contentAlignDY:Float = Int(0.5 * (lineHeight - lineContentHeight))

		'take screen alpha into consideration
		color = New SColor8(color.r, color.g, color.b, Byte(color.a * colorAlpha))
		SetColor(color)
		SetAlpha(color.a/255.0)

		For Local i:Int = 0 Until s.Length
			Local charCode:Int = s[i]
			Local newLineChar:Int = charCode = 13 Or charCode = Asc("~n")


			'render char and advance to next char position 
			If Not newLineChar
				Local transformedPos:SVec2F = __GetTransformedPosition(textX - handle.x*w, textY + contentAlignDY - handle.y*h - Self.displaceY, localX, localY)


				Local bm:TBitmapFontChar = __GetBitmapFontChar(charCode)
				If Not BITMAPFONTBENCHMARK
					If drawToPixmap
						Self.__DrawSingleCharToPixmap(bm, charCode, x + textX, y + textY - contentAlignDY, color)
						'Self.__DrawSingleCharToPixmap(bm, charCode, transformedPos.x, transformedPos.y, color)
					Else
						Self.__DrawSingleChar(bm, charCode, transformedPos.x, transformedPos.y)
					EndIf
				EndIf

				Local charAdv:SVec2F = __GetCharAdvance(bm, charCode, textX)
				textX :+ charAdv.x
			EndIf


			'update text dimensions
			'(when new line char or reached end)
			If newLineChar Or i = s.Length - 1
				'move to next line
				textY :+ lineHeight
				If textX > textMaxX Then textMaxX = textX
				textX = 0				
				currentLine :+ 1
			EndIf
		Next


		'restore screen color
		If Not drawToPixmap
			SetColor(oldColor)
			SetAlpha(oldColorA)
		EndIf
		
		Return New SVec2I(Int(Ceil(textMaxX)), Int(textY))
	End Method
End Type


'container to allow easy passing around and sharing the setting
Type TDrawTextEffect
	'private
	Field data:SDrawTextEffect
End Type


Struct SDrawTextEffect
	Field mode:EDrawTextEffect
	Field value:Float = -1.0
	Field color:SColor8 = SColor8.White

	Method Init(mode:EDrawTextEffect, value:Float, color:SColor8)
		Self.mode = mode
		Self.value = value
		Self.color = color
	End Method
	
	
	Method InitDefaults(mode:EDrawTextEffect)
		value = -1.0
		Select mode
			Case EDrawTextEffect.Shadow
				color = SColor8.Black
			Case EDrawTextEffect.Emboss
				color = SColor8.White
			Case EDrawTextEffect.Glow
				color = SColor8.White
		End Select
	End Method
End Struct


Enum EDrawTextEffect:Byte flags
	None = 0
	Shadow = 1
	Glow
	Emboss
End Enum




Enum EDrawTextOption:Byte flags
	None = 0
	IgnoreColor = 1
	IgnoreFontstyles
	IgnoreSprites
End Enum


Enum EDrawLineHeightModes:Byte
	AllLinesMax
	LineMax
	FixedOrAllLinesMax 'use fixed height or all lines max
End Enum



'container to allow easy passing around and sharing the setting
Type TDrawTextSettings
	'private
	Field data:SDrawTextSettings
End Type

Struct SDrawTextSettings
	Field lineHeightMode:EDrawLineHeightModes
	Field lineHeight:Int = -1
	Field wordWrap:Int = True
	'should big sprites affect line heights?
	Field ignoreSpecialElementLineOverlaps:Byte = False
	'disable if full text has to be drawn even if it exceeds
	'the limits
	Field truncationEnabled:Byte = True
	Field truncateWithEllipse:Byte = True
	'enable linebreaks to cut words not just on "spaces" etc
	Field lineBreakCanCutWords:Byte = False
	'is eating a whitespace at the end of lines allowed?
	Field skipOptionalElementOnEOL:Byte = True
	'by default a text box ends when the "line box" of the 
	'last line ends, not when the actually rendered characters end
	Field boxDimensionMode:Int = 0
End Struct


Type TStyledBitmapFonts
	Field styles:TBitmapFont[2]

	Method Get:TBitmapFont(style:Int)
		style :+ 1
		If style < styles.Length
			Return styles[style]
		End If
	End Method

	Method Insert(style:Int, font:TBitmapFont)
		style :+ 1
		If style >= styles.Length
			styles = styles[..style + 1]
		End If
		styles[style] = font
	End Method
End Type




Type TSizedBitmapFonts
	Field sizes:TStyledBitmapFonts[12]

	Method Get:TBitmapFont(size:Float, style:Int)
		size :+ 1
		'compute 26.6 value (1.0 => 64, 1,1 => rounded to 1,09375 => 70/64)
		Local sizeInt:Int = Int(size*64)

		If sizeInt < sizes.Length
			Local styled:TStyledBitmapFonts = sizes[sizeInt]
			If styled Then
				Return styled.Get(style)
			End If
		End If
	End Method

	Method Insert(size:Float, style:Int, font:TBitmapFont)
		size :+ 1
		'compute 26.6 value (1.0 => 64, 1,1 => rounded to 1,09375 => 70/64)
		Local sizeInt:Int = Int(size*64)
		If sizeInt >= sizes.Length
			sizes = sizes[..sizeInt + 1]
		End If
		Local styled:TStyledBitmapFonts = sizes[sizeInt]
		If Not styled Then
			styled = New TStyledBitmapFonts
			sizes[sizeInt] = styled
		End If

		styled.Insert(style, font)
	End Method
End Type






' - max2d/max2d.bmx -> loadimagefont
' - max2d/imagefont.bmx TImageFont.Load ->
Function LoadTrueTypeFont:TImageFont( url:Object,size:Float,style:Int )
	Local src:TFont = TFreeTypeFont.Load( String( url ), size, style )
	If Not src Then Return Null

	Local font:TImageFont=New TImageFont
	font._src_font=src
	font._glyphs=New TImageGlyph[src.CountGlyphs()]
	If style & SMOOTHFONT Then font._imageFlags=FILTEREDIMAGE|MIPMAPPEDIMAGE

	Return font
End Function


Struct STextParseElement
	'todo: bitmask
	Field visible:Byte
	'eg space at the end...
	Field skipOnLinebreak:Byte
	Field changedFont:Byte
	Field manualLineBreak:Byte
	Field elementType:Byte
	Field renderObject:Object
	
	Field width:Short
	Field height:Short
	Field advWidth:Short
	
	Global ELEMENTTYPE_GLYPH:Byte = 0
	Global ELEMENTTYPE_SPRITE:Byte = 1
	Global ELEMENTTYPE_MISC:Byte = 2
	
	
	Method New(width:Short, height:Short, advanceWidth:Short, visible:Int, changedFont:Int)
		Self.width = width
		Self.height = height
		Self.advWidth = advanceWidth
		Self.visible = (visible = True)
		Self.changedFont = (changedFont = True)

		Self.skipOnLinebreak = False
	End Method
	
End Struct




'container to allow easy passing around and sharing the setting
Type TTextParseInfo
	'private
	Field data:STextParseInfo

	Method New()
		data = New STextParseInfo(5, 10)
	End Method

	
	Method New(estimatedLineCount:Short, estimatedNestedColorStyles:Int)
		data = New STextParseInfo(estimatedLineCount, estimatedNestedColorStyles)
	End Method
End Type


'TODO: can be "struct" as soon as all NG releases ship with the new/fixed
'      bcc (newer than begin of April 2022)
Type STextParseInfo
	'storage of current font styles
	Field stylesB:Int
	Field stylesI:Int
	Field stylesInvisible:Int
	Field StaticArray stylesColors:SColor8[10]
	Field stylesColorsDynamic:SColor8[]
	Field stylesColorsIndex:Int

	Field baseColor:SColor8
	Field hasCurrentColor:Int

	'helper to read from a given text without extracting strings first
	Field command:SSubString
	Field payload:SSubString
	
	' word wrap, alignment and dimensions storage
	'Private
	Field StaticArray lineinfo_widths:Short[10]
	Field StaticArray lineinfo_boxHeights:Short[10]
	Field StaticArray lineinfo_contentHeights:Short[10]
	Field StaticArray lineinfo_maxFontHeights:Short[10]
	Field StaticArray lineinfo_lineBreakIndices:Int[10]
	Field StaticArray lineinfo_lineBreakOptions:Byte[10]
	Field StaticArray lineinfo_fontDisplaceYs:Int[10]
	Field lineinfo_widthsDynamic:Short[] = Null
	Field lineinfo_boxHeightsDynamic:Short[] = Null
	Field lineinfo_contentHeightsDynamic:Short[] = Null
	Field lineinfo_maxFontHeightsDynamic:Short[] = Null
	Field lineinfo_lineBreakIndicesDynamic:Int[] = Null
	Field lineinfo_lineBreakOptionsDynamic:Byte[] = Null
	Field lineinfo_fontDisplaceYsDynamic:Int[] = Null

	Public
	Field lineFontDisplaceYMax:Int
	
	Field visibleLineCount:Short
	Field totalLineCount:Short
	Field visibleElementCount:Int
	Field totalVisibleElementCount:Int
	' if >= 0 it defines the first visible char of the string after an
	' ellipsis is rendered
	Field truncateStartIndex:Int = -1
	Field truncateStartLine:Int = -1
	' if >= 0 it defines the last visible char of the string before an
	' ellipsis is rendered
	Field truncateEndIndex:Int = -1
	Field truncateEndLine:Int = -1

	Private
	'block width and block height are "Line box" based
	'subtract last lines content height / maxFontHeight to trim
	Field _visibleBoxWidth:Short
	Field _visibleBoxHeight:Short
	'height without "truncation"
	Field _totalBoxWidth:Short
	Field _totalBoxHeight:Short

	Public
	'position which would be the "last on the line"
	Field possibleLineBreakIndex:Int = -1
	Field possibleLineBreakCharIndex:Int = 0
	Field handledCharIndex:Int = -1
	Field lastAutomaticLineBreakIndex:Int = -1
	Field minimumTextFitsIntoBox:Int = True
	Field fontChanged:Int
	Field colorChanged:Int
	Field calculated:Int = False
	
	'0 ... LINEHEIGHT
	'      lineHeight (or bigger)
	'1 ... MINIMUM
	'      lineHeight equals to "max descending" used character 
	'2 ... NICE
	'      lineHeight equals to "max descending" character of used font 
	Global BLOCK_HEIGHT_MODE_LINEHEIGHT:Int = 0
	Global BLOCK_HEIGHT_MODE_MINIMUM:Int = 0
	Global BLOCK_HEIGHT_MODE_NICE:Int = 0

	Method New()
		New(5, 10)
	End Method

	
	Method New(estimatedLineCount:Short, estimatedNestedColorStyles:Int)
		Reset(estimatedLineCount, estimatedNestedColorStyles)

		'set first break index to "none" so rendering only breaks if needed
		lineinfo_lineBreakIndices[0] = -1
	End Method


	Method PrepareNewCalculation(estimatedLineCount:Int = -1, estimatedStyleColors:Int = -1)
		calculated = False

		Reset(estimatedLineCount, estimatedStyleColors)
	End Method


	Method Reset(estimatedLineCount:Int = -1, estimatedStyleColors:Int = -1)
		Local dynamicArrayLength:Int = Max(0, estimatedLineCount - lineinfo_widths.Length)
		Local dynamicStyleColorsLength:Int = Max(0, estimatedStyleColors - stylesColors.Length)

		ResetStyle()

		'presize arrays
		If dynamicStyleColorsLength >= 0 And stylesColorsDynamic.Length <> dynamicStyleColorsLength
			stylesColorsDynamic = New SColor8[dynamicStyleColorsLength]
		EndIf

		If dynamicArrayLength >= 0 And lineinfo_widthsDynamic.Length <> dynamicArrayLength
			EnsureDynamicArraySize(dynamicArrayLength)
		EndIf


		'reset variables
		hasCurrentColor = False
		
		totalLineCount = 0
		visibleLineCount = 0
		
		truncateStartIndex = -1
		truncateStartLine = -1

		truncateEndIndex = -1
		truncateEndLine = -1

		visibleElementCount = 0
		totalVisibleElementCount = 0

		_totalBoxWidth = 0
		_totalBoxHeight = 0
		_visibleBoxWidth = 0
		_visibleBoxHeight = 0
		
		For Local i:Int = 0 Until 10
			lineinfo_boxHeights[i] = 0
			lineinfo_contentHeights[i] = 0
			lineinfo_maxFontHeights[i] = 0
			lineinfo_fontDisplaceYs[i] = 0
			lineinfo_lineBreakIndices[i] = 0
			lineinfo_lineBreakOptions[i] = 0
			lineinfo_widths[i] = 0
		Next

		'position which would be the "last on the line"
		possibleLineBreakIndex = -1
		possibleLineBreakCharIndex = 0
		handledCharIndex = -1
		lastAutomaticLineBreakIndex = -1
		minimumTextFitsIntoBox = True
		fontChanged = False
		colorChanged = False
		lineFontDisplaceYMax = 0
		
		calculated = False
	End Method


	Method ResetStyle()
		stylesB = 0
		stylesI = 0
		stylesInvisible = 0
		stylesColorsIndex = 0
	End Method


	Method GetBoxWidth:Short(boxDimensionMode:Int = 0)
		Return _visibleBoxWidth
	End Method
	
	
	Method GetBoxHeight:Short(boxDimensionMode:Int = 0)
		Select boxDimensionMode
			Case 1 'content based
				Return _visibleBoxHeight - GetLineHeight(visibleLineCount, 0) + GetLineHeight(visibleLineCount, boxDimensionMode)
			Case 2 'max font content based
				Return _visibleBoxHeight - GetLineHeight(visibleLineCount, 0) + Max(GetLineHeight(visibleLineCount, 1), GetLineHeight(visibleLineCount, 2))
			Default
				Return _visibleBoxHeight
		End Select
	End Method


	Method GetTotalBoxWidth:Short(boxDimensionMode:Int = 0)
		Return _totalBoxWidth
	End Method
	
	
	Method GetTotalBoxHeight:Short(boxDimensionMode:Int = 0)
		Select boxDimensionMode
			Case 1 'content based
				Return _totalBoxHeight - GetLineHeight(totalLineCount, 0) + GetLineHeight(totalLineCount, boxDimensionMode)
			Case 2 'max font content based
				Return _totalBoxHeight - GetLineHeight(totalLineCount, 0) + Max(GetLineHeight(totalLineCount, 1), GetLineHeight(totalLineCount, 2))
			Default
				Return _totalBoxHeight
		End Select
	End Method


	Method GetLineY:Int(line:Int)
		If line < 1 Then Return 0
		
		Local y:Int
		For Local i:Int = 0 Until Min(totalLineCount, line)
			y :+ GetLineHeight(i + 1, 0)
		Next
		Return y
	End Method

	
	Method GetLineWidth:Short(line:Int, boxDimensionMode:Int = 0)
		Local lineIndex:Int = line - 1
		If lineIndex >= 0 And lineIndex < lineinfo_widths.Length + lineinfo_widthsDynamic.Length
			If lineIndex < lineinfo_widths.Length
				Return lineinfo_widths[lineIndex]
			Else
				Return lineinfo_widthsDynamic[lineIndex - lineinfo_widths.Length]
			EndIf
		EndIf
		Return -1
	End Method

	
	Method GetLineHeight:Int(line:Int, boxDimensionMode:Int = 0)
		Local lineIndex:Int = line - 1
		If lineIndex >= 0 And lineIndex < lineinfo_widthsDynamic.Length + lineinfo_widths.Length And lineIndex < totalLineCount
			If lineIndex < lineinfo_widths.Length
				Select boxDimensionMode
					Case 1
						Return lineinfo_contentHeights[lineIndex]
					Case 2
						Return lineinfo_maxFontHeights[lineIndex]
					Default '/ case 0
						Return lineinfo_boxHeights[lineIndex]
				End Select
			Else
				Select boxDimensionMode
					Case 1
						Return lineinfo_contentHeightsDynamic[lineIndex - lineinfo_contentHeights.Length]
					Case 2
						Return lineinfo_maxFontHeightsDynamic[lineIndex - lineinfo_maxFontHeights.Length]
					Default '/ case 0
						Return lineinfo_boxHeightsDynamic[lineIndex - lineinfo_boxHeights.Length]
				End Select
			EndIf
		EndIf
		Return -1
	End Method


	Method StorePotentialLineBreak(txt:String Var, txtIndex:Int Var)
		Local charcode:Int = txt[txtIndex]

		'store potential line break positions
		'TODO: add other hypens (unicode)
		If charCode = Asc(" ") 
			possibleLineBreakIndex = txtIndex
'		ElseIf txtIndex + 1 < txt.length-1 and txt[txtIndex + 1] = Asc("-") 
'			possibleLineBreakIndex = txtIndex + 1
		ElseIf charCode = Asc("-") 
			possibleLineBreakIndex = txtIndex
		'handle enforced new line
		ElseIf charCode = 13 Or charCode = Asc("~n")
			possibleLineBreakIndex = txtIndex
		EndIf
	End Method

	
	Method UpdateLinebreakIndex:Int(txt:String Var, txtIndex:Int Var)
		Local lineBreakIndex:Int = possibleLineBreakIndex 'Max(possibleLineBreakIndex, Min(1, txt.length))
		
		Local cutWord:Int = -1

		'if last possible linebreak was a line earlier or never happened
		'...just cut inbetween the words
		If possibleLineBreakIndex = -1
			txtIndex :- 1
			Return True
		ElseIf totalLineCount>1
			'Local thisLineIndex:int = totalLineCount - 1
			'Local lastLineIndex:int = thisLineIndex - 1
			Local lastLineIndex:Int = totalLineCount - 1 - 1
			Local dynamicIndex:Int = lastLineIndex - lineinfo_lineBreakIndices.Length

			If dynamicIndex >= 0 
				If lineinfo_lineBreakIndicesDynamic[dynamicIndex] >= possibleLineBreakIndex
					txtIndex :- 1
					Return True
				EndIf
			Else	
				If lineinfo_lineBreakIndices[lastLineIndex] >= possibleLineBreakIndex
					txtIndex :- 1
					Return True
				EndIf
			EndIf
		EndIf


		' to avoid handling the same chars over and over for 
		' line breaks (eg the word does not fit into the line)
		' we store what was processed already - and never
		' are able to go back further
		If possibleLineBreakCharIndex >= lineBreakIndex
			 lineBreakIndex = possibleLineBreakCharIndex + 1
		EndIf
		possibleLineBreakCharIndex = txtIndex


		If txtIndex <> lineBreakIndex
			txtIndex = lineBreakIndex
			Return True
		Else
			Return False
		End If
	End Method
	

	Method HandleFontChanges:TBitmapFont(font:TBitmapFont Var, fontChanged:Int = -1)
		If fontChanged = -1 Then fontChanged = Self.fontChanged
		If fontChanged
			Local style:Int
			If stylesB > 0 Then style :| BOLDFONT
			If stylesI > 0 Then style :| ITALICFONT

			font = GetBitmapFont(font.fName, font.fSize, style)
			fontChanged = False
		EndIf
	End Method


	Method HandleVisibleOnlyCommands(font:TBitmapFont Var, txt:String Var, txtPos:Int Var, currentColor:SColor8 Var)
		'color
		If command.Matches("color")
			'read colors
			'(avoiding "split" command which creates more strings)
			Local cStart:Int = payload.start
			Local cIndex:Int = 0
			Local StaticArray c:Byte[4]; c[3] = 255 'default to alpha = 1.0

			Local ci:Int
			For Local i:Int = 0 Until payload.Length
				ci = payload.start + i

				'inbetween
				If txt[ci] = Asc(",")
					c[cIndex] = payload.ToByte( cStart , ci )
					cIndex :+ 1
					cStart = ci + 1
				EndIf
				If cIndex >= 4 Then Exit
			Next
			If cIndex < 4 Then
				c[cIndex] = payload.ToByte( cStart, ci + 1 )
			End If

			If Not hasCurrentColor Or (currentColor.r <> c[0] Or currentColor.g <> c[1] Or currentColor.b <> c[2] Or currentColor.a <> c[3])
				currentColor = New SColor8(c[0], c[1], c[2], c[3])
				hasCurrentColor = True
			
				
				Local dynamicIndex:Int = stylesColorsIndex - stylesColors.Length
				If dynamicIndex >= 0
					If stylesColorsDynamic.Length <= dynamicIndex Then stylesColorsDynamic = stylesColorsDynamic[ .. dynamicIndex + 10]
					stylesColorsDynamic[dynamicIndex] = currentColor
				Else
					stylesColors[stylesColorsIndex] = currentColor
				EndIf

				stylesColorsIndex :+ 1

				colorChanged = True
			EndIf
		
		Else If command.Matches("/color")
			stylesColorsIndex = Max(0, stylesColorsIndex - 1)

			' when we reached index 0 this time, fall back to
			' initial color
			If stylesColorsIndex >= 1
				Local dynamicIndex:Int = stylesColorsIndex - stylesColors.Length - 1
				If dynamicIndex >= 0
					currentColor = stylesColorsDynamic[dynamicIndex]
				Else
					currentColor = stylesColors[stylesColorsIndex - 1]
				EndIf
			Else
				currentColor = baseColor
				hasCurrentColor = False
			EndIf

			colorChanged = True
		EndIf
	End Method
	

	Method HandleSpriteCommand:STextParseElement(font:TBitmapFont, txt:String Var, txtPos:Int Var, x:Float, y:Float)
		'read colors
		'(avoiding "split" command which creates more strings)
		Local cStart:Int = payload.start
		Local cIndex:Int = 0
		'@Brucey - maybe it is better to avoid this string?
		Local name:String
		Local StaticArray dim:Byte[2]; dim[0] = -1; dim[1] = -1 'default to no dimension

		Local ci:Int
		For Local i:Int = 0 Until payload.Length
			ci = payload.start + i

			'inbetween
			If txt[ci] = Asc(",")
				If cIndex = 0
					name = txt[payload.start .. ci]
				Else
					dim[cIndex - 1] = payload.ToByte( cStart , ci )
				EndIf
				cIndex :+ 1
				cStart = ci + 1
			EndIf
			If cIndex >= 3 Then Exit
		Next
		If cIndex < 3 Then
			dim[cIndex - 1] = payload.ToByte( cStart, ci + 1 )
		End If


		Local sprite:TSprite
		If TBitmapFont._spriteProvider
			sprite = TBitmapFont._spriteProvider(name)
		EndIf
		
		If sprite
			If dim[0] = -1 Then dim[0] = sprite.GetWidth()
			If dim[1] = -1 Then dim[1] = sprite.GetHeight()
		Else
			If dim[0] = -1 Then dim[0] = 0
			If dim[1] = -1 Then dim[1] = 0
		EndIf
	
		Local element:STextParseElement = New STextParseElement()
		element.manualLineBreak = False
		element.elementType = STextParseElement.ELEMENTTYPE_SPRITE
		element.width = dim[0]
		element.height = dim[1]
		element.advWidth = dim[0]
		element.visible = True

		element.renderObject = sprite

		Return element
	End Method	


	Method HandleSpacerCommand:STextParseElement(font:TBitmapFont, txt:String Var, txtPos:Int Var, x:Float, y:Float)
		'read dimensions
		'(avoiding "split" command which creates more strings)
		Local dimStart:Int = payload.start
		Local dimIndex:Int = 0
		Local StaticArray dim:Byte[2]
		

		Local dimI:Int
		For Local i:Int = 0 Until payload.Length
			dimI = payload.start + i

			'inbetween
			If txt[dimi] = Asc(",")
				dim[dimIndex] = payload.ToByte( dimStart , dimI )
				dimIndex :+ 1
				dimStart = dimI + 1
			EndIf
			If dimIndex >= 2 Then Exit
		Next
		If dimIndex < 2 Then
			dim[dimIndex] = payload.ToByte( dimStart, dimi + 1 )
		End If


		Local element:STextParseElement = New STextParseElement()
		element.manualLineBreak = False
		element.elementType = STextParseElement.ELEMENTTYPE_MISC
		element.width = dim[0]
		element.height = dim[1]
		element.advWidth = dim[0]
		element.visible = True

		Return element
	End Method


	Method EatCommands(txt:String Var, txtPos:Int Var)
		' finished processing txt if last char is a command char
		If txtPos = txt.Length - 1 Then Return

		' read command until next commandCharCode
		' if encountering the "=" sign, read payload
		Local j:Int = txtPos
		Local isPayload:Int = False

		While j < txt.Length - 1
			j :+ 1
			If txt[j] = TBitmapFont.COMMAND_CHARCODE
				Exit
			EndIf
		Wend
		txtPos = j
	End Method


	Method HandleCommand:STextParseElement(font:TBitmapFont Var, txt:String Var, txtPos:Int Var, x:Int, y:Int)
		' finished processing txt if last char is a command char
		If txtPos = txt.Length - 1 Then Return New STextParseElement()

		' read command until next commandCharCode
		' if encountering the "=" sign, read payload
		Local j:Int = txtPos
		Local isPayload:Int = False
		Local fontChanged:Byte

		While j < txt.Length - 1
			j :+ 1
			If txt[j] = TBitmapFont.PAYLOAD_CHARCODE
				command.Set(txt, txtPos + 1, j - (txtPos + 1))
				txtPos = j
				isPayload = True
			ElseIf txt[j] = TBitmapFont.COMMAND_CHARCODE
				If isPayload
					payload.Set(txt, txtPos + 1, j - (txtPos + 1))
				Else
					command.Set(txt, txtPos + 1, j - (txtPos + 1))
				EndIf
				Exit
			EndIf
		Wend
		txtPos = j
					
		
		'bold
		If command.Matches("b")
			stylesB :+ 1
			If stylesB = 1 Then fontChanged = True

		ElseIf command.Matches("/b")
			If stylesB = 1 Then fontChanged = True
			stylesB = Max(stylesB - 1, 0)

		'italic
		ElseIf command.Matches("i")
			stylesI :+ 1
			If stylesI = 1 Then fontChanged = True

		ElseIf command.Matches("/i")
			If stylesI = 1 Then fontChanged = True
			stylesI = Max(stylesI - 1, 0)

		'invisible
		ElseIf command.Matches("invisible")
			stylesInvisible :+ 1

		ElseIf command.Matches("/invisible")
			stylesInvisible = Max(stylesInvisible - 1, 0)
			
		'spacers
		ElseIf command.Matches("spacer")
			Return HandleSpacerCommand(font, txt, txtPos, x, y)
		'sprites
		ElseIf command.Matches("sprite")
			Return HandleSpriteCommand(font, txt, txtPos, x, y)
		EndIf
		
		Return New STextParseElement(0:Short,0:Short, 0:Short, False, fontChanged)
	End Method


	Method HandleChar:STextParseElement(font:TBitmapFont Var, txt:String Var, txtPos:Int Var, textX:Float, bm:TBitmapFontChar = Null)
		Local charCode:Int = txt[txtPos]
		If Not bm Then bm = font.__GetBitmapFontChar(charcode)

		Local charAdv:SVec2F = font.__GetCharAdvance(bm, charCode, textX)
		Local charDim:SVec2F = font.__GetCharDim(bm, charCode, textX)
		Local element:STextParseElement = New STextParseElement()
		element.manualLineBreak = (charCode = 13 Or charCode = Asc("~n"))
		element.width = charDim.x
		element.height = charDim.y
		element.advWidth = Floor(charAdv.x)
		element.visible = True
		element.renderObject = bm

		If charCode = Asc(" ")
			element.skipOnLinebreak = True
		'no need to render this character
		ElseIf element.manualLineBreak
			element.skipOnLinebreak = True
		EndIf

		Return element
	End Method
	
	
	Method EnsureDynamicArraySize(size:Int)
		If lineinfo_boxHeightsDynamic.Length < size
			lineinfo_boxHeightsDynamic = lineinfo_boxHeightsDynamic[.. size + 10]
			lineinfo_contentHeightsDynamic = lineinfo_contentHeightsDynamic[.. size + 10]
			lineinfo_maxFontHeightsDynamic = lineinfo_maxFontHeightsDynamic[.. size + 10]
			lineinfo_widthsDynamic = lineinfo_widthsDynamic[.. size + 10]
			lineinfo_lineBreakIndicesDynamic = lineinfo_lineBreakIndicesDynamic[.. size + 10]
			lineinfo_lineBreakOptionsDynamic = lineinfo_lineBreakOptionsDynamic[.. size + 10]
			lineinfo_fontDisplaceYsDynamic = lineinfo_fontDisplaceYsDynamic[.. size + 10]
		EndIf
	End Method


	Method CalculateDimensions(txt:String Var, limitWidth:Float, limitHeight:Float, font:TBitmapFont)
		CalculateDimensions(txt, limitWidth, limitHeight, font, TBitmapFont.defaultDrawSettings)
	End Method


	Method CalculateDimensions(txt:String Var, limitWidth:Float, limitHeight:Float, font:TBitmapFont, settings:SDrawTextSettings Var)
		Local currentFont:TBitmapFont = font

		Reset()
'		calculated = True

		'done in "reset()" already
		'ResetStyle()


		'step 1: find line breaks / word wrapping positions
		'step 2: measure line dimensions to allow proper alignment
		'step 3: adjust line heights if needed (eg all lines set to "fixed height or more")
		'step 4: (optional) mark truncation index when required to 
		'        append an ellipsis as limits are exceeded
		'You cannot mix step 1 and 2 - as in step 1 we also can go back
		'some characters (word wrapping) and we would then need to know
		'the "width/height" at that time (extra data - per char!)
		'You cannot mix step 2 and 3 - as in step 2 we calculate line
		'height. If you need to check if next line would exceed maximum
		'height you need to know the height of the next line already
		totalLineCount = 1
		visibleLineCount = 1

		Local fontChanges:Int
		'done in Reset())
		'possibleLineBreakCharIndex = -1
		'possibleLineBreakIndex = -1
		'lastAutomaticLineBreakIndex = -1

		'handled max until said differently
		handledCharIndex = txt.Length
		
		Local element:STextParseElement
		' on a line break we might eat the breaking char (eg. a "space")
		Local eatChars:Int = 0
		Local lineWidth:Int


		Local textX:Float
		Local textY:Float
		Local lastHandledCommandIndex:Int = 0
		'find line breaks
		For Local i:Int = 0 Until txt.Length
			Local charCode:Int = txt[i]
			Local escaped:Int = False

			If totalLineCount > 64000 'or whatever is a useful line count limit
				handledCharIndex = i - 1
				Exit
			EndIf


 			' escaping command or escape char?
			If charCode = TBitmapFont.ESCAPE_CHARCODE And i < txt.Length - 2 And (txt[i+1] = TBitmapFont.COMMAND_CHARCODE Or txt[i+1] = TBitmapFont.ESCAPE_CHARCODE)
				i :+ 1
				charCode = txt[i]
				escaped = True
			EndIf

			' reading command?
			' for now we ignore any escape chars within an active command
			' so no "|b \|escaped stuff|bold text|/b|" -- this would fail!
			If charCode = TBitmapFont.COMMAND_CHARCODE And Not escaped
				element = HandleCommand(currentFont, txt, i, 0, 0)
				fontChanges :+ element.changedFont

'ddd
'damit wird einiger Blocktext nicht gehandelt
'aber ohne spinnt es, wenn der Linebreak so stattfindet, dass "|blabla|" auf einer
'Zeile vorher startet, und dann "nochmal" ausgefuehrt wird				
				'mark as line break index (so word wrap goes not beyond
				'an already opened tag/command)
'				if element.changedFont
'					local commandEndIndex:Int = i-1
'					UpdateLinebreakIndex(txt, commandEndIndex)
'				endif

				'skip command if already handled
				If i <= lastHandledCommandIndex
					i:-1
					EatCommands(txt, i)
					lastHandledCommandIndex = i
				' react to font changes (if required)
				ElseIf element.changedFont
					Local commandEndIndex:Int = i-1
					UpdateLinebreakIndex(txt, commandEndIndex)

					HandleFontChanges(currentFont, True)

					'update if we did not handle that already (with a wordwrap-go-back-some-chars)
					lastHandledCommandIndex = i
				EndIf

			' received char potentially being displayed
			Else
				element = HandleChar(currentFont, txt, i, textX)
				
				'disable eating of whitespace?
				If Not settings.skipOptionalElementOnEOL Then element.skipOnLinebreak = False
			EndIf


			'would this element exceed line width?
			'required new line (automatic linebreak)?
			Local automaticLineBreak:Int
			If Not element.manualLineBreak And element.visible And settings.wordWrap
				' if not enough space left, go back to last potential
				' line break position and break there
				' we cannot go new line if nothing was printed on
				' this line ... as it means it would not fit on the
				' next line either!
				If limitWidth > 0 And lineWidth > 0 And lineWidth + element.width > limitWidth
					automaticLineBreak = True

					' adjusts "i" to the best suiting linebreak position
					If settings.lineBreakCanCutWords 
						i :- 1
						element = HandleChar(currentFont, txt, i, textX)
						charCode = txt[i]
					
					ElseIf settings.skipOptionalElementOnEOL And element.skipOnLinebreak
						'nothing to do

					ElseIf UpdateLinebreakIndex(txt, i)
						element = HandleChar(currentFont, txt, i, textX)
						charCode = txt[i]
					EndIf
					'disable eating of whitespace?
					If Not settings.skipOptionalElementOnEOL Then element.skipOnLinebreak = False

'TODO: noch noetig?
					' if index does not change, then this means
					' we were not able to fit a single letter into 
					' the box
					If lastAutomaticLineBreakIndex >= 0 And lastAutomaticLineBreakIndex = i
						minimumTextFitsIntoBox = False
						Return
					Else
						lastAutomaticLineBreakIndex = i
					EndIf
				EndIf
			EndIf


			'eat new line chars and spaces, ...
			If (element.manualLinebreak Or automaticLinebreak) And element.skipOnLinebreak And i < txt.Length - 1
				eatChars :+ 1
			'eat end of commands etc
			ElseIf Not element.visible
				eatChars :+ 1
			EndIf
			
			' when the char (eg. space) is used to do a line break
			' we do not render it
			If eatChars > 0
				eatChars :- 1
			Else
				lineWidth :+ element.width
				textX :+ element.advWidth
			EndIf


			'move on to the next line ?
			If (automaticLineBreak Or element.manualLineBreak) Or i = txt.Length-1
				'reset line width
				lineWidth = 0
				textX = 0
				lastAutomaticLineBreakIndex = -1

				' and also store where it does the break
				Local dynamicIndex:Int = totalLineCount - 1 - lineinfo_lineBreakIndices.Length
				If dynamicIndex >= 0 
					EnsureDynamicArraySize(dynamicIndex + 1)
					lineinfo_lineBreakIndicesDynamic[dynamicIndex] = i
				Else
					lineinfo_lineBreakIndices[totalLineCount - 1] = i
				EndIf

				'TODO: maybe just have an amount of "to eat" stored there?
				If element.manualLineBreak Or (automaticLineBreak And element.skipOnLinebreak)
					If dynamicIndex >= 0 
						EnsureDynamicArraySize(dynamicIndex + 1)
						lineinfo_lineBreakOptionsDynamic[dynamicIndex] = 1
					Else
						lineinfo_lineBreakOptions[totalLineCount - 1] = 1
					EndIf
				EndIf


				If i < txt.Length - 1  'or add if last is a newline char?
					totalLineCount :+ 1
					visibleLineCount :+ 1
				EndIf
				
			'if the char did not lead to a line break yet, we can store
			'it (if space, hyphen, ...) as last possible line break index
			ElseIf element.visible
				'store potential line break position (spaces, hyphens...)
				StorePotentialLineBreak(txt, i)
			EndIf
		Next
		'backup lineCount just in case the other steps manipulate it
		Local totalLineCountBackup:Int = totalLineCount 
		Local visibleLineCountBackup:Int = totalLineCount 

		ResetStyle()


		'measure line dimensions
		'also store the biggest font offset in this line
		'so that all glyphs can have the same "baseline" 
		eatChars = 0
		currentFont = font
		Local startNewLine:Int = True
		Local currentLineFontDisplaceYMax:Int = currentFont.displaceY
		Local currentLineContentHeight:Short
		Local currentLineMaxFontHeight:Short
		Local currentLineLineBoxHeight:Int '= currentfont.GetLineHeight(settings.lineHeight)
		Local currentLine:Int = 1
		Local lineWidthMax:Short
		Local lineBoxHeightMin:Short
		Local lineBoxHeightMax:Short
		

		For Local i:Int = 0 Until txt.Length 'handledCharIndex
			Local charCode:Int = txt[i]
			Local escaped:Int = False

			If startNewLine
				startNewLine = False
				'reset line dimensions
				lineWidth = 0
				currentLineLineBoxHeight = currentFont.GetLineHeight(settings.lineHeight)
				'avoid last line being "cut" - so increase line height if required
				If currentLine = totalLineCount
					currentLineLineBoxHeight = Max(currentLineLineBoxHeight, currentFont.GetLineHeight(-1))
				EndIf

				currentLineContentHeight = 0
				currentLineMaxFontHeight = currentFont.GetMaxCharHeight(True)

				textX = 0
			EndIf
		
 			' escaping command or escape char?
			If charCode = TBitmapFont.ESCAPE_CHARCODE And i < txt.Length - 2 And (txt[i+1] = TBitmapFont.COMMAND_CHARCODE Or txt[i+1] = TBitmapFont.ESCAPE_CHARCODE)
				i :+ 1
				charCode = txt[i]
				escaped = True
			EndIf


			' reading command?
			' for now we ignore any escape chars within an active command
			' so no "|b \|escaped stuff|bold text|/b|" -- this would fail!
			If charCode = TBitmapFont.COMMAND_CHARCODE And Not escaped
				element = HandleCommand(currentFont, txt, i, 0, 0)
				fontChanges :+ element.changedFont

				' react to font changes (if required)
				If fontChanges > 0 And element.changedFont
					HandleFontChanges(currentFont, True)
					currentLineFontDisplaceYMax = Int(Min(currentLineFontDisplaceYMax, currentFont.displaceY))
					'update to new line height
					currentLineMaxFontHeight = Max(currentLineMaxFontHeight, currentFont.GetMaxCharHeight(True))

					currentLineLineBoxHeight = Max(currentLineLineBoxHeight, currentFont.GetLineHeight(settings.lineHeight))
					'avoid last line being "cut" - so increase line height if required
					If currentLine = totalLineCount
						currentLineLineBoxHeight = Max(currentLineLineBoxHeight, currentFont.GetLineHeight(-1))
					EndIf
				EndIf

			' received char potentially being displayed
			Else
				element = HandleChar(currentFont, txt, i, textX)
				'disable eating of whitespace?
				If Not settings.skipOptionalElementOnEOL Then element.skipOnLinebreak = False
			EndIf

			Local dynamicIndex:Int = currentLine - 1 - lineinfo_lineBreakIndices.Length
						
			'has next char to be placed on a new line?
			Local doLineBreak:Int
			If dynamicIndex >= 0
				doLineBreak = (lineinfo_lineBreakIndicesDynamic[dynamicIndex] <= i)
			Else
				doLineBreak = (lineinfo_lineBreakIndices[currentLine - 1] <= i)
			EndIf

			Local lineBreakOption:Int
			If dynamicIndex >= 0
				lineBreakOption = (lineinfo_lineBreakOptionsDynamic[dynamicIndex] > 0)
			Else
				lineBreakOption = (lineinfo_lineBreakOptions[currentLine - 1] > 0)
			EndIf


			'eat new line chars and spaces, ...
			If doLineBreak And lineBreakOption > 0 And element.skipOnLinebreak And currentLine < totalLineCount
				eatChars :+ lineBreakOption
			ElseIf Not element.visible
				eatChars :+ 1
			EndIf

			' when the char (eg. space) is used to do a line break
			' we do not render it
			If eatChars > 0
				eatChars :- 1
			Else
				lineWidth :+ element.width
				textX :+ element.advWidth

				currentLineContentHeight = Max(currentLineContentHeight, element.height)
				
				visibleElementCount :+ 1
				totalVisibleElementCount :+ 1
			EndIf


			'increase height
			If doLineBreak Or i = txt.Length - 1
				'if this is the last line, then ensure a possibly "too short"
				'font designer's line height is not cutting the text or an sprite
				If currentLine = totalLineCount
					currentLineLineBoxHeight = Max(currentLineContentHeight, currentLineLineBoxHeight)
'					currentLineLineBoxHeight = Max(currentLineMaxFontHeight, currentLineLineBoxHeight)
				EndIf
		
				'if there was even bigger content (eg a sprite, take it
				'into consideration)
				If Not settings.ignoreSpecialElementLineOverlaps
					currentLineLineBoxHeight = Max(currentLineContentHeight, currentLineLineBoxHeight)

					'if there is a fixed line height requested, we should
					'not exceed it (sprites still might exceed visually)
					'exception is last line
					If settings.lineHeight > 0 And currentLine < totalLineCount
						currentLineLineBoxHeight = Min(settings.lineHeight, currentLineLineBoxHeight)
					EndIf
				EndIf


				lineBoxHeightMax = Max(currentLineLineBoxHeight, lineBoxHeightMax)
				lineBoxHeightMin = Min(currentLineLineBoxHeight, lineBoxHeightMin)
			
				startNewLine = True
				'lines cannot exceed box width 
				'(this can happen if the box is less wide than a single char)
				If limitWidth >= 0
					'lineWidth = min(lineWidth, limitWidth)
				EndIf

				' store line height/width calculation
				If dynamicIndex >= 0 
					lineinfo_boxHeightsDynamic[dynamicIndex] = currentLineLineBoxHeight
					lineinfo_contentHeightsDynamic[dynamicIndex] = currentLineContentHeight
					lineinfo_maxFontHeightsDynamic[dynamicIndex] = currentLineMaxFontHeight
					lineinfo_widthsDynamic[dynamicIndex] = lineWidth
					lineinfo_fontDisplaceYsDynamic[dynamicIndex] = currentLineFontDisplaceYMax
				Else
					lineinfo_boxHeights[currentLine-1] = currentLineLineBoxHeight
					lineinfo_contentHeights[currentLine-1] = currentLineContentHeight
					lineinfo_maxFontHeights[currentLine-1] = currentLineMaxFontHeight
					lineinfo_widths[currentLine-1] = lineWidth
					lineinfo_fontDisplaceYs[currentLine-1] = currentLineFontDisplaceYMax
				EndIf

				lineFontDisplaceYMax = Max(currentLineFontDisplaceYMax, lineFontDisplaceYMax)
				lineWidthMax = Max(lineWidth, lineWidthMax)

				_totalBoxHeight :+ currentLineLineBoxHeight
				_totalBoxWidth = Max(_totalBoxWidth, lineWidth)
				_visibleBoxHeight :+ currentLineLineBoxHeight
				_visibleBoxWidth = Max(_visibleBoxWidth, lineWidth)

				'print "line break ... " + currentLine + "/" + totalLineCount + "   dynamicIndex="+dynamicIndex + "  index="+(currentLine-1) +"  width="+lineWidth + " maxWidth="+lineWidthMax
				
				If i < txt.Length - 1  'or add if last is a newline char?
					currentLine :+ 1
				EndIf
			EndIf
		Next


		'step 3: fix line heights (in case of "all lines max")
		'only do this if we have line height changes in the text
		If lineBoxHeightMax <> lineBoxHeightMin And settings.lineHeight = -1 And ..
		   (settings.lineHeightMode = EDrawLineHeightModes.FixedOrAllLinesMax Or ..
		    settings.lineHeightMode = EDrawLineHeightModes.AllLinesMax)

			_totalBoxHeight = 0
			_visibleBoxHeight = 0
			currentLineLineBoxHeight = Max(settings.lineHeight, lineBoxHeightMax)

			For Local i:Int = 0 Until totalLineCount
				Local dynamicIndex:Int = i - lineinfo_lineBreakIndices.Length
				If dynamicIndex >= 0
					lineinfo_boxHeightsDynamic[dynamicIndex] = currentLineLineBoxHeight
				Else
					lineinfo_boxHeights[i] = currentLineLineBoxHeight
				EndIf
			Next
			_totalBoxHeight = totalLineCount * currentLineLineBoxHeight
			_visibleBoxHeight = visibleLineCount * currentLineLineBoxHeight
		EndIf
		


		'step 4: find truncations
		' only do this when end of last line exceeds height limit
		' also adjust blockwidth (wider lines might have been cut off)
		Local dynamicIndex:Int = totalLineCount - 1 - lineinfo_widths.Length
		Local lastLineY:Int = GetLineY(totalLineCount)
		' ensure that we calculate in both cases: linebox cut or content cut
		Local lastLineHeight:Short = Min(GetLineHeight(totalLineCount, 1), GetLineHeight(totalLineCount, 0))

		If (settings.truncationEnabled And limitHeight >= 0 And lastLineY + lastLineHeight > limitHeight) 
			currentFont = font
			_visibleBoxWidth = 0
			_visibleBoxHeight = 0
			visibleLineCount = 0

			'recount visible elements
			visibleElementCount = 0

			Local defaultFontEllipsisWidth:Int = font.GetEllipsisWidth()
			Local currentFontEllipsisWidth:Int = -1

			lineWidth = 0
			textX = 0
			eatChars = 0
			Local currentLine:Int =  1
			Local truncateEndOfLine:Int = False
			Local truncateBeginOfLine:Int = False
			Local nextLineBreakIndex:Int = lineinfo_lineBreakIndices[0]
			Local checkLineForTruncation:Int = True
			For Local i:Int = 0 Until handledCharIndex
				Local charCode:Int = txt[i]
				Local escaped:Int = False
				Local elementStart:Int = i

				' escaping command or escape char?
				If charCode = TBitmapFont.ESCAPE_CHARCODE And i < txt.Length - 2 And (txt[i+1] = TBitmapFont.COMMAND_CHARCODE Or txt[i+1] = TBitmapFont.ESCAPE_CHARCODE)
					i :+ 1
					charCode = txt[i]
					escaped = True
				EndIf


				' reading command?
				' for now we ignore any escape chars within an active command
				' so no "|b \|escaped stuff|bold text|/b|" -- this would fail!
				If charCode = TBitmapFont.COMMAND_CHARCODE And Not escaped
					element = HandleCommand(currentFont, txt, i, 0, 0)
					fontChanges :+ element.changedFont

					' react to font changes (if required)
					If fontChanges > 0 And element.changedFont
						HandleFontChanges(currentFont, True)
					EndIf

				' received char potentially being displayed
				Else
					element = HandleChar(currentFont, txt, i, textX, Null)

					'disable eating of whitespace?
					If Not settings.skipOptionalElementOnEOL Then element.skipOnLinebreak = False
				EndIf

				' escaping command or escape char?
				If charCode = TBitmapFont.ESCAPE_CHARCODE And i < txt.Length - 2 And (txt[i+1] = TBitmapFont.COMMAND_CHARCODE Or txt[i+1] = TBitmapFont.ESCAPE_CHARCODE)
					i :+ 1
					charCode = txt[i]
					escaped = True
				EndIf


				'has next char to be placed on a new line?
				'doLineBreak = (parseInfo.lineBreakIndices[currentLine - 1] < i)
				Local doLineBreak:Int = nextLineBreakIndex =< i 


				If Not doLineBreak And Not element.visible Then Continue
				

				If checkLineForTruncation
					' done for this line
					checkLineForTruncation = False

					' check if the upcoming line exceeds box height
					' truncate the current one then
					' attention: do not read beyond totalLineCount
					If currentLine + 1 <= totalLineCount
						Local thisLineHeight:Short = GetLineHeight(currentLine, 0)
						'retrieve height according to desired mode for "last lines"
						Local nextLineHeight:Short = GetLineHeight(currentLine + 1, settings.boxDimensionMode)

						If nextLineHeight > 0
							If textY + thisLineHeight + nextLineHeight > limitHeight
								truncateEndLine = currentLine
							EndIf
						EndIf
						truncateEndOfLine = (currentLine = truncateEndLine)
						truncateBeginOfLine = (currentLine = truncateStartLine)
					EndIf
				EndIf

				' truncate "upcoming" lines 
				' draw an ellipsis on this line?
				If truncateEndOfLine And ((doLineBreak And i >= nextLineBreakIndex) Or i = txt.Length - 1)
					truncateEndIndex = i
				
					'only add ellipsis if possible - and allowed
					If settings.truncateWithEllipse
						If limitWidth < 0 Or lineWidth + defaultFontEllipsisWidth =< limitWidth
							'lineWidth :+ currentFontEllipsisWidth
							lineWidth :+ defaultFontEllipsisWidth

							_visibleBoxWidth = Max(_visibleBoxWidth, lineWidth)

							visibleElementCount :+ 1
							
							dynamicIndex:Int = currentLine - 1 - lineinfo_widths.Length
							If dynamicIndex >= 0 
								lineinfo_widthsDynamic[dynamicIndex] = lineWidth
							Else
								lineinfo_Widths[currentLine - 1] = lineWidth
							EndIf

							lineWidthMax = Max(lineWidth, lineWidthMax)
						EndIf
					EndIf
					
					'add "last line" height
'					_visibleBoxHeight :+ GetLineHeight(currentLine, settings.boxDimensionMode)
					_visibleBoxHeight :+ GetLineHeight(currentLine, 0)
					
					'done
					Exit
				EndIf


				' truncate the current line
				' do this if ellipsis would not fit on the line after this very char
				' do a ">=" comparison as else "int alignment" can lead to the ellipsis not fitting into the limits
				' anylonger
				If truncateEndOfLine And limitWidth > 0 And textX + element.advWidth + defaultFontEllipsisWidth >= limitWidth 
					truncateEndIndex = elementStart

					'only add ellipsis if possible and allowed
					If settings.truncateWithEllipse
						If limitWidth < 0 Or lineWidth + defaultFontEllipsisWidth < limitWidth 
							'lineWidth :+ currentFontEllipsisWidth
							lineWidth :+ defaultFontEllipsisWidth
							_visibleBoxWidth = Max(_visibleBoxWidth, lineWidth)

							visibleElementCount :+ 1

							dynamicIndex = currentLine - 1 - lineinfo_boxHeights.Length
							If dynamicIndex >= 0
								EnsureDynamicArraySize(dynamicIndex + 1)
								lineinfo_widthsDynamic[dynamicIndex] = lineWidth
							Else
								lineinfo_widths[currentLine-1] = lineWidth
							EndIf
							lineWidthMax = Max(lineWidth, lineWidthMax) 'should be blockWidth
						EndIf
					EndIf

					'add "last line" height
'					_visibleBoxHeight :+ GetLineHeight(currentLine, settings.boxDimensionMode)
					_visibleBoxHeight :+ GetLineHeight(currentLine, 0)

					i = txt.Length
					
					'done
					Exit
				ElseIf settings.skipOptionalElementOnEOL And element.skipOnLinebreak And nextLineBreakIndex = i
					'skip this char
				Else
					visibleElementCount :+ 1

					textX :+ element.advWidth
					lineWidth :+ element.width
				EndIf
				
				'line break - but not the one happening on "last char" ?
				If doLineBreak Or i = txt.Length - 1
					dynamicIndex = currentLine - lineinfo_boxHeights.Length

					'move on to next line (already calculated)
					'and update the next line break index
					Local lineHeight:Int
					'if on last line ... set lineheight according to setting?
					'or ... keep it as we subtract this stuff in "GetVisibleBoxHeight()"
					'already
'					if i = txt.length
'						lineHeight = GetLineHeight(currentLine, settings.boxDimensionMode)
'					else
						lineHeight = GetLineHeight(currentLine, 0)
'					endif
					textY :+ lineHeight
					_visibleBoxHeight :+ lineHeight
					_visibleBoxWidth = Max(_visibleBoxWidth, lineWidth)
	
					If dynamicIndex >= 0
						EnsureDynamicArraySize(dynamicIndex + 1)
						nextLineBreakIndex = lineinfo_lineBreakIndicesDynamic[dynamicIndex]
					Else
						nextLineBreakIndex = lineinfo_lineBreakIndices[currentLine]
					EndIf

					textX = 0			
					lineWidth = 0	

					currentLine :+ 1
					
					checkLineForTruncation = True

					'reached end?
					'If i = txt.length-1 Then Continue
				EndIf
			Next
		EndIf



Rem
local lc:int = 0
For local i:int = 0 until lineWidths.length
	lc :+ 1
	print "line #" + lc + "  width="+linewidths[i]
Next
'For local i:int = 0 until lineWidthsDynamic.length
'	lc :+ 1
'	print "line #" + lc + "  width="+lineWidthsDynamic[i]
'Next
end
endrem
	End Method
End Type




Struct STextParseLineInfo
	'used height in block texts (eg fixed line heights)
	Field boxHeight:Short
	'actual height of content (text, sprites)
	Field contentHeight:Short
	'height including "below baseline" (descend) elements of chars
	'even if not used in this line ("ab" equal high as "qb")
	Field maxFontHeight:Short
	Field width:Short
	Field lineBreakIndex:Int
	Field lineBreakOption:Byte
	Field fontDisplaceY:Int
End Struct



	
	
Struct SSubString
	Field s:String
	Field start:Int
	Field Length:Int
	Field isSet:Int = False
	
	Method Set(s:String, start:Int, Length:Int)
		Self.s = s
		Self.start = start
		Self.Length = Length
		isSet = True
	End Method
	
	Method Matches:Int(other:String)
		If Length <> other.Length Return False
		Local i:Int = 0
		While i < Length
			If s[start + i] <> other[i] Return False
			i :+ 1
		Wend
		Return True
	End Method
	
	Method ToByte:Byte(i1:Int, i2:Int)
		Local b:Byte

		For Local i:Int = i1 Until i2
			b :* 10
			b :+ (s[i] - 48)
		Next
		Return b
	End Method
	
End Struct





Type TBitmapFontText
	Field textBoxDimension:SVec2I
	Field cacheDimension:SVec2I
	Field text:String
	Field font:TBitmapFont
	Field alignment:SVec2F
	Field color:SColor8
	'store calculated line dimensions/information
	Field parseInfo:STextParseInfo
	'use structs, not types here as we else would not identify
	'invalid caches if settings/effects are changed "outside"
	Field settings:SDrawTextSettings
	Field effect:SDrawTextEffect

	Field cache:TImage
	
	Global defaultSettings:TDrawTextSettings
	Global defaultEffect:TDrawTextEffect
	
	
	Method New()
		If Not defaultSettings Then defaultSettings = New TDrawTextSettings
		If Not defaultEffect Then defaultEffect = New TDrawTextEffect
		
		'ddd
		'for now as "struct STextParseInfo" creates bugs with arrays 
		If Not parseInfo Then parseInfo = New STextParseInfo
	End Method


	Method Invalidate()
		cache = Null
	End Method


	Method HasCache:Int()
		Return cache <> Null
	End Method


	Method FillCache(img:TImage)
		Local oldRot:Float = GetRotation()
		Local oldScaleX:Float, oldScaleY:Float
		GetScale(oldScalex, oldScaleY)
		SetRotation(0)
		SetScale(1,1)

		Local p:TPixmap = LockImage(img)
		p.ClearPixels(0)
		UnlockImage(img)

		Local offX:Int = Floor((textBoxDimension.x - cacheDimension.x) * alignment.x)
		Local offY:Int = Floor((textBoxDimension.y - cacheDimension.y) * alignment.y)

		font.SetRenderTarget( img )
		font.DrawBox(text, -offX, -offY, textBoxDimension.x, textBoxDimension.y, alignment, color, New SVec2F(0,0), parseInfo, EDrawTextOption.None, effect, settings)
		font.SetRenderTarget( Null )

		SetRotation(oldRot)
		SetScale(oldScaleX, oldScaleY)
	End Method


	Method DrawCached:Int(x:Float, y:Float)
		If cache 
			Local offX:Int = Int((textBoxDimension.x - cacheDimension.x) * alignment.x)
			Local offY:Int = Int((textBoxDimension.y - cacheDimension.y) * alignment.y)
			DrawImage(cache, x - offX, y - offY)
		EndIf
	End Method


	Method CacheDraw:Int(font:TBitmapFont, text:String, color:SColor8)
		If cache
			If Self.text <> text
				cache = Null
			ElseIf Self.font <> font
				cache = Null
			ElseIf Self.color.ToARGB() <> color.ToARGB()
				cache = Null
			EndIf
		EndIf

		If Not cache
			Self.font = font
			Self.text = text
			Self.color = color
			
			'calculate box and line dimensions
			parseInfo.PrepareNewCalculation()

			cacheDimension = font.GetDimension(text, parseInfo)

			cache = CreateImage( cacheDimension.x, cacheDimension.y )

			FillCache(cache)
		EndIf
	End Method


	Method Draw:Int(font:TBitmapFont, text:String, x:Float, y:Float)
		Local c:SColor8
		GetColor(c)
		Return Draw(font, text, x, y, c)
	End Method


	Method Draw:Int(font:TBitmapFont, text:String, x:Float, y:Float, color:SColor8)
		If text = ""
			'an empty text can still move forward to a "new line"
			If font 
				textBoxDimension = New SVec2I(0, font.GetMaxCharHeight())
			EndIf
			Return False 'nothing to render
		EndIf

		'(re-)create cache
		CacheDraw(font, text, color)

		'render
		DrawImage(cache, x, y)

		Return True
	End Method


	Method CacheDrawBlock:Int(font:TBitmapFont, text:String, w:Int, h:Int, alignment:SVec2F, color:SColor8)
		Return CacheDrawBlock(font, text, w, h, alignment, color, font.defaultDrawEffect, font.defaultDrawSettings)
	End Method

	Method CacheDrawBlock:Int(font:TBitmapFont, text:String, w:Int, h:Int, alignment:SVec2F, color:SColor8, effect:TDrawTextEffect, settings:TDrawTextSettings)
		If Not effect And Not settings
			Return CacheDrawBlock(font, text, w, h, alignment, color, font.defaultDrawEffect, font.defaultDrawSettings)
		ElseIf Not effect
			Return CacheDrawBlock(font, text, w, h, alignment, color, font.defaultDrawEffect, settings.data)
		ElseIf Not settings
			Return CacheDrawBlock(font, text, w, h, alignment, color, effect.data, font.defaultDrawSettings)
		Else
			Return CacheDrawBlock(font, text, w, h, alignment, color, effect.data, settings.data)
		EndIf
	End Method

	Method CacheDrawBlock:Int(font:TBitmapFont, text:String, w:Int, h:Int, alignment:SVec2F, color:SColor8, effect:SDrawTextEffect Var, settings:SDrawTextSettings Var)
		If cache
			If (Self.textBoxDimension.x <> w Or Self.textBoxDimension.y <> h) And (w > 0 And h > 0)
				cache = Null
			ElseIf Self.text <> text
				cache = Null
			ElseIf Self.font<>font
				cache = Null
			ElseIf Self.effect.Mode <> effect.Mode Or Self.effect.value <> effect.value
				cache = Null
			ElseIf Self.color.ToARGB() <> color.ToARGB()
				cache = Null
			ElseIf (Self.alignment.x <> alignment.x Or Self.alignment.y <> alignment.y)
				cache = Null
			ElseIf Self.settings.truncateWithEllipse <> settings.truncateWithEllipse
				cache = Null
'			ElseIf Self.settings.centerSingleLineOnBaseline <> settings.centerSingleLineOnBaseline
'				cache = Null
			ElseIf Self.settings.lineHeight <> settings.lineHeight
				cache = Null
			EndIf
		EndIf

		If Not cache
			Self.font = font
			Self.text = text

			Self.effect = effect
			Self.alignment = alignment
			Self.color = color
			Self.settings = settings
			
			'calculate line dimensions
			parseInfo.PrepareNewCalculation()
			'fetch dimension including styles like shadows/glow
			Local styledDim:SVec2I = font.GetBoxDimension(text, w, h, parseInfo, effect, settings)			


			'go not bigger than allowed dimensions
			If w < 0 And h < 0
				Self.cacheDimension = New SVec2I(styledDim.x, styledDim.y)
				Self.textBoxDimension = New SVec2I(cacheDimension.x, cacheDimension.y)
			ElseIf w < 0
				Self.cacheDimension = New SVec2I(styledDim.x, Int(Min(h, styledDim.y)))
				Self.textBoxDimension = New SVec2I(cacheDimension.x, h)
			ElseIf h < 0 
				Self.cacheDimension = New SVec2I(Int(Min(w, styledDim.x)), styledDim.y)
				Self.textBoxDimension = New SVec2I(w, cacheDimension.y)
			Else
				Self.cacheDimension = New SVec2I(Int(Min(w, styledDim.x)), Int(Min(h, styledDim.y)))
				Self.textBoxDimension = New SVec2I(w, h)
			EndIf

			
			cache = CreateImage( Int(Max(cacheDimension.x, 1)), Int(Max(cacheDimension.y, 1)) )

Rem
Print "create drawblock cache for: ~q" + text.replace("~n", "~~n") + "~q"
Print "textBox dimension: " + textBoxDimension.ToString()
Print "styledText dimension: " + styledDim.ToString()
Print "cache dimension: " + cacheDimension.ToString()
Print "boxSize: " + parseInfo.GetBoxWidth(0) +", " + parseInfo.GetBoxHeight(0) + "  (content = "+parseInfo.GetBoxHeight(1)+")"
Print "alignment: " + alignment.ToString()
Print "cache img dimension: " + cache.width + ", " + cache.height
print "font: ascend=" + font.ascend +"  descend=" + font.descend
print "."
print "."
'end
endrem
			FillCache(cache)
		EndIf
	End Method


	Method DrawBlock:Int(font:TBitmapFont, text:String, x:Float, y:Float, w:Int, h:Int, alignment:SVec2F, color:SColor8, effect:TDrawTextEffect, settings:TDrawTextSettings)
		If text = ""
			'an empty text can still move forward to a "new line"
			If font
				Self.textBoxDimension = New SVec2I(0, font.GetMaxCharHeight())
			EndIf
			Return False 'nothing to render
		EndIf
		
		If Not effect Then effect = defaultEffect
		If Not settings Then settings = defaultSettings

		'(re-)create cache if required
		CacheDrawBlock(font, text, w, h, alignment, color, effect.data, settings.data)
		
		If w < 0 Then w = cacheDimension.x
		If h < 0 Then h = cacheDimension.y

Rem
SetColor 255,120,255
SetAlpha 0.7
DrawRect(x,y,w,h)
SetColor 255,255,255
SetAlpha 1.0
endrem
		'render cache
		Local offX:Int = Int(Floor((w - cacheDimension.x) * alignment.x))
		Local offY:Int = Int(Floor((h - cacheDimension.y) * alignment.y))

Rem
SetColor 0,120,255
SetAlpha 0.7
DrawRect(x + offX, y + offY, cache.width, cache.height)

'SetColor 255,0,0
'DrawRect(x,y+(h/2) - font.GetMaxCharHeightAboveBaseline(),w,1)
'DrawRect(x,y+(h/2) + font.GetMaxCharHeightBelowBaseline(),w,1)
'SetColor 200,0,0
'DrawRect(x,y+(h/2),w,1)

SetColor 255,255,255
SetAlpha 1.0
endrem
'"descendMax" einfuehren - und descendMax*alignement.y optional als offset, falls man 
'Zext nur von "oben bis baseline" als Basis fuer das alignment nehmen will

		DrawImage(cache, x + offX, y + offY)

'		font.DrawBox(text, x  + 40, y, textBoxDimension.x, textBoxDimension.y, alignment, color, New SVec2F(0,0), parseInfo, EDrawTextOption.None, effect.data, settings.data)

		Return True
	End Method
End Type

