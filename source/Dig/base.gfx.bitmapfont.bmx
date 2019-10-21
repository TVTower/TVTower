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
'to load from truetype
Import brl.FreeTypeFont
Import "base.util.rectangle.bmx"
Import "base.gfx.sprite.bmx"
Import "base.gfx.spriteatlas.bmx"




Const SHADOWFONT:Int = 256
Const GRADIENTFONT:Int = 512

Type TBitmapFontManager
	Field baseFont:TBitmapFont
	Field baseFontBold:TBitmapFont
	Field baseFontItalic:TBitmapFont
	Field baseFontSmall:TBitmapFont
	Field _defaultFont:TBitmapFont
'Private
	Field fonts:TMap = New TMap
?bmxng
Public
?
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
		If Not systemFont Then systemFont = TBitmapFont.Create("SystemFont", "", 12, SMOOTHFONT)

		'if no default font was set, return the system font
		If Not _defaultFont Then Return systemFont

		Return _defaultFont
	End Method


	'get ignores the "SMOOTHFONT" flag to allow adding "crisp" fonts
	Method Get:TBitmapFont(name:String="", size:Int=-1, style:Int=-1)
		name = Lower(name)

		'fall back to default font if none was given
		If name = "" Then name = "default"

		'no details given: return default font
		If name = "default" And size = -1 And style = -1 Then Return GetDefaultFont()


		'try to find default font settings for this font face
		Local defaultStyledFont:TBitmapFont' = GetFont(name, -1, style) ' TBitmapFont(fonts.ValueForKey(name+"_-1_"+style))
		Local defaultFont:TBitmapFont' = defaultStyledFont

		If size = -1 Or style = -1 Then
			defaultStyledFont = GetDefaultStyledFont(name, style)

			'no size given: use default font size
			If size = -1 Then size = defaultStyledFont.FSize
			'no style given: use default font style
			If style = -1 Then style = defaultStyledFont.FStyle
		End If

		'Local key:String = name + "_" + size + "_" + style
		Local font:TBitmapFont = GetFont(name, size, style) 'TBitmapFont(fonts.ValueForKey(key))
		If font Then Return font
		'if the font wasn't found, use the defaultFont-fontfile to load this style

		If Not defaultStyledFont Then
			defaultStyledFont = GetDefaultStyledFont(name, style)
		End If

		font = Add(name, defaultStyledFont.FFile, size, style)

		Return font
	End Method


	Method GetDefaultStyledFont:TBitmapFont(name:String, style:Int)

		Local defaultStyledFont:TBitmapFont = GetFont(name, -1, style) ' TBitmapFont(fonts.ValueForKey(name+"_-1_"+style))

		If Not defaultStyledFont
			defaultStyledFont = GetFont(name, -1, -1) 'TBitmapFont(fonts.ValueForKey(name))
		EndIf
		If Not defaultStyledFont Then defaultStyledFont = GetDefaultFont()

		Return defaultStyledFont
	End Method


	Method Copy:TBitmapFont(sourceName:String, copyName:String, size:Int=-1, style:Int=-1)
		Local sourceFont:TBitmapFont = Get(sourceName, size, style)
		Local newFont:TBitmapFont = TBitmapFont.Create(copyName, sourceFont.fFile, sourceFont.fSize, sourceFont.fStyle, sourceFont.fixedCharWidth, sourceFont.charWidthModifier)
		InsertFont(copyName, sourceFont.fSize, sourceFont.fStyle, newFont)

		Return newFont
	End Method


	Method InsertFont(name:String, size:Int, style:Int, font:TBitmapFont)
		Local sizes:TSizedBitmapFonts = TSizedBitmapFonts(fonts.ValueForKey(name))

		If Not sizes Then
			sizes = New TSizedBitmapFonts
			fonts.Insert(name, sizes)
		End If

		sizes.Insert(size, style, font)
	End Method


	Method GetFont:TBitmapFont(name:String, size:Int = -1, style:Int = -1)
		Local sizes:TSizedBitmapFonts = TSizedBitmapFonts(fonts.ValueForKey(name))

		If Not sizes Then
			Return Null
		End If

		Return sizes.Get(size, style)
	End Method


	Method Add:TBitmapFont(name:String, file:String, size:Int, style:Int=0, ignoreDefaultStyle:Int = False, fixedCharWidth:Int=-1, charWidthModifier:Float=1.0)
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
Function GetBitmapFont:TBitmapfont(name:String="", size:Int=-1, style:Int=-1)
	Return TBitmapFontManager.GetInstance().Get(name, size, style)
End Function




Type TBitmapFontChar
	Field area:TRectangle
	Field charWidth:Float
	Field img:TImage


	Method Init:TBitmapFontChar(img:TImage, x:Int,y:Int,w:Int, h:Int, charWidth:Float)
		Self.img = img
		Self.area = New TRectangle.Init(x, y, w, h)
		Self.charWidth = charWidth
		Return Self
	End Method
End Type




Type TBitmapFont
	'identifier
	Field FName:String = ""
	'source path
	Field FFile:String = ""
	'size of this font
	Field FSize:Int = 0
	'style used in this font
	Field FStyle:Int = 0
	'the original imagefont
	Field FImageFont:TImageFont

	Field chars:TBitmapFontChar[] = New TBitmapFontChar[256]
	Field charsSprites:TSprite[] = New TSprite[0]
	Field spriteSet:TSpritePack
	'by default only the first 256 chars get loaded
	'as soon as an "utf8"-code is requested, the font will re-init with
	'more sprites
	Field MaxSigns:Int = 256
	Field glyphCount:Int = 0
	Field ExtraChars:String = ""
	Field gfx:TMax2dGraphics
	Field uniqueID:String =""
	Field displaceY:Float=100.0
	'modifier * lineheight gets added at the end
	Field lineHeightModifier:Float = 1.05
	'value the width of " " (space) is multiplied with
	Field spaceWidthModifier:Float = 1.0
	Field charWidthModifier:Float = 1.0
	Field fixedCharWidth:Int = -1
	Field tabWidth:Int = 15
	'whether to use ints or floats for coords
	Field drawAtFixedPoints:Int = True
	Field _charsEffectFunc:TBitmapFontChar(font:TBitmapFont, charKey:Int, char:TBitmapFontChar, config:TData)[]
	Field _charsEffectFuncConfig:TData[]
	'by default this is 8bit alpha only
	Field _pixmapFormat:Int = PF_A8
	Field _maxCharHeight:Int = 0
	Field _maxCharHeightAboveBaseline:Int = 0
	Field _hasEllipsis:Int = -1

	Global drawToPixmap:TPixmap = Null
	Global pixmapOrigin:TVec2D = New TVec2D.Init(0,0)
'DISABLECACHE	global ImageCaches:TMap = CreateMap()
	Global eventRegistered:Int = 0

	Global shadowColor:TColor = New TColor.clBlack
	Global embossColor:TColor = New TColor.clWhite

	Const STYLE_NONE:Int = 0
	Const STYLE_EMBOSS:Int = 1
	Const STYLE_SHADOW:Int = 2
	Const STYLE_GLOW:Int = 3


	Function Create:TBitmapFont(name:String, url:String, size:Int, style:Int, fixedCharWidth:Int = -1, charWidthModifier:Float = 1.0)
		Local obj:TBitmapFont = New TBitmapFont
		obj.FName = name
		obj.FFile = url
		obj.FSize = size
		obj.FStyle = style
		obj.uniqueID = name+"_"+url+"_"+size+"_"+style
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

		'create spriteset
		obj.spriteSet = New TSpritePack.Init(Null, obj.uniqueID+"_charmap")

		'generate a charmap containing packed rectangles where to store images
		obj.InitFont()

		Return obj
	End Function


	Method SetCharsEffectFunction(position:Int, _func:TBitmapFontChar(font:TBitmapFont, charKey:Int, char:TBitmapFontChar, config:TData), config:TData=Null)
		position :-1 '0 based
		If _charsEffectFunc.length <= position
			_charsEffectFunc = _charsEffectFunc[..position+1]
			_charsEffectFuncConfig = _charsEffectFuncConfig[..position+1]
		EndIf
		_charsEffectFunc[position] = _func
		_charsEffectFuncConfig[position] = config
	End Method


	'overrideable method
	Method ApplyCharsEffect(config:TData=Null)
		'if instead of overriding a function was provided - use this
		If _charsEffectFunc.length > 0
			'for local _charKey:TIntKey = eachin chars.keys()
			For Local charKey:Int = 0 Until chars.length

				'local charKey:Int = _charKey.Value
				'local char:TBitmapFontChar = TBitmapFontChar(chars.ValueForKey(charKey))
				Local char:TBitmapFontChar = chars[charKey]
				If Not char Then
					Continue
				End If

				'manipulate char
				Local _func:TBitmapFontChar(font:TBitmapFont, charKey:Int, char:TBitmapFontChar, config:TData)
				Local _config:TData
				For Local i:Int = 0 To _charsEffectFunc.length-1
					_func = _charsEffectFunc[i]
					_config = _charsEffectFuncConfig[i]
					If Not _config Then _config = config
					char = _func(Self, charKey, char, _config)
				Next
				'overwrite char
				'chars.Insert(charKey, char)
				chars[charKey] = char
			Next
		EndIf
		'else do nothing by default
	End Method


	'returns the same font in the given size/style combination
	'it is more or less a wrapper to make acces more convenient
	Method GetVariant:TBitmapFont(size:Int=-1, style:Int = -1)
		If size = -1 Then size = Self.FSize
		If style = -1 Then style = Self.FStyle
		Return TBitmapFontManager.GetInstance().Get(Self.FName, size, style)
	End Method


	'generate a charmap containing packed rectangles where to store images
	Method InitFont(config:TData=Null )
		'1. load chars
		LoadCharsFromSource()
		'2. Process the characters (add shadow, gradients, ...)
		ApplyCharsEffect(config)
		'3. store them into a packed (optimized) charmap
		'   -> creates a 8bit alpha'd image (grayscale with alpha ...)
		CreateCharmapImage( CreateCharmap(1) )
	End Method


	'reinits the font and loads the characters above charcode 256
	Method LoadExtendedCharacters()
		MaxSigns = -1
		InitFont()
	End Method


	'load glyphs of an imagefont as TBitmapFontChar into a char-TMap
	Method LoadCharsFromSource(source:Object=Null)
		Local imgFont:TImageFont = TImageFont(source)
		If imgFont = Null Then imgFont = FImageFont
		Local glyph:TImageGlyph
		Local glyphCount:Int = imgFont.CountGlyphs()
		Local n:Int
		Local loadMaxGlyphs:Int = glyphCount
		If MaxSigns <> -1 Then loadMaxGlyphs = MaxSigns

		If extraChars = ""
			extraChars :+ Chr(8364) '
			extraChars :+ Chr(8230) '
			extraChars :+ Chr(8220) '
			extraChars :+ Chr(8221) '
			extraChars :+ Chr(8222) '
			extraChars :+ Chr(171) '
			extraChars :+ Chr(187) '
			'extraChars :+ chr(8227) '
			'extraChars :+ chr(9662) '
			extraChars :+ Chr(9650) '
			extraChars :+ Chr(9660) '
			extraChars :+ Chr(9664) '
			extraChars :+ Chr(9654) '
			extraChars :+ Chr(9632) '
		EndIf

		Self.glyphCount = glyphCount

		For Local i:Int = 0 Until loadMaxGlyphs
'		For Local i:Int = 0 Until MaxSigns
			n = imgFont.CharToGlyph(i)
			If n < 0 Or n > glyphCount Then Continue
			glyph = imgFont.LoadGlyph(n)
			If Not glyph Then Continue

			'base displacement calculated with A-Z (space between
			'TOPLEFT of 'ABCDE' and TOPLEFT of 'acen'...)
			If i >= 65 And i < 95 Then displaceY = Min(displaceY, glyph._y)
			resizeChars(i)
			'chars.insert(i, new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance))
			If fixedCharWidth > 0
				chars[i] = New TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w ,glyph._h, fixedCharWidth)
			Else
				chars[i] = New TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance * charWidthModifier)
			EndIf
		Next
		For Local charNum:Int = 0 Until ExtraChars.length
			n = imgFont.CharToGlyph( ExtraChars[charNum] )
			If n < 0 Or n > glyphCount Then Continue
			glyph = imgFont.LoadGlyph(n)
			If Not glyph Then Continue
			resizeChars(ExtraChars[charNum])
			'chars.insert(ExtraChars[charNum] , new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance) )
			If fixedCharWidth > 0
				chars[ExtraChars[charNum]] = New TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w ,glyph._h, fixedCharWidth)
			Else
				chars[ExtraChars[charNum]] = New TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance * charWidthModifier)
			EndIf
		Next
	End Method


	Method resizeChars(index:Int)
		If index >= chars.length Then
			chars = chars[.. index + 1 + chars.length/3]
		End If
	End Method


	Method resizeCharsSprites(index:Int)
		If index >= charsSprites.length Then
			charsSprites = charsSprites[.. index + 1 + charsSprites.length/3]
		End If
	End Method


	'create a charmap-atlas with information where to optimally store
	'each char
	Method CreateCharmap:TSpriteAtlas(spaceBetweenChars:Int=0)
		Local charmap:TSpriteAtlas = TSpriteAtlas.Create(64,64)
		Local bitmapFontChar:TBitmapFontChar
		'for local _charKey:TIntKey = eachin chars.keys()
		For Local charKey:Int = 0 Until chars.length
			'local charKey:Int = _charKey.Value
			'bitmapFontChar = TBitmapFontChar(chars.ValueForKey(charKey))
			bitmapFontChar = chars[charKey]
			If Not bitmapFontChar Then Continue
			charmap.AddElement(charKey, Int(bitmapFontChar.area.GetW()+spaceBetweenChars), Int(bitmapFontChar.area.GetH()+spaceBetweenChars) ) 'add box of char and package atlas
		Next
		Return charmap
	End Method


	'create an image containing all chars
	'the charmap-atlas contains information where to store each character
	Method CreateCharmapImage(charmap:TSpriteAtlas)
		Local pix:TPixmap = CreatePixmap(charmap.w,charmap.h, _pixmapFormat) ; pix.ClearPixels(0)
		'create spriteset
		If Not spriteSet Then spriteSet = New TSpritePack.Init(Null, uniqueID+"_charmap")

		'loop through atlas boxes and add chars
		For Local _charKey:String = EachIn charmap.elements.Keys()
			Local rect:TRectangle = TRectangle(charmap.elements.ValueForKey(_charKey))
			Local charKey:Int = _charKey.ToInt()
			'skip missing data
			If (charKey > chars.length) Or (Not chars[charKey]) Then Continue

			Local bm:TBitmapFontChar = chars[charKey]
			If Not bm.img Then Continue

			'draw char image on charmap
			'local charPix:TPixmap = LockImage(TBitmapFontChar(chars.ValueForKey(charKey)).img)
			Local charPix:TPixmap = LockImage(bm.img)
			'make sure the pixmaps are 8bit alpha-format
'			If charPix.format <> 2 Then charPix.convert(PF_A8)
			DrawImageOnImage(charPix, pix, Int(rect.GetX()), Int(rect.GetY()))
			'UnlockImage(TBitmapFontChar(chars.ValueForKey(charKey)).img)
			UnlockImage(bm.img)
			' es fehlt noch charWidth - extraTyp?

			resizeCharsSprites(charKey)
			charsSprites[charKey] = New TSprite.Init(spriteSet, charKey, rect, Null, 0)
		Next
		'set image to sprite pack
		If IsSmooth()
			spriteSet.image = LoadImage(pix)
		Else
			'non smooth fonts should disable any filtering (eg. in virtual resolution scaling)
			spriteSet.image = LoadImage(pix, 0)
		EndIf
	End Method


	Method IsBold:Int()
		Return (FStyle & BOLDFONT)
	End Method

	Method IsSmooth:Int()
		Return (FStyle & SMOOTHFONT)
	End Method


	'Returns whether this font has a visible ellipsis char ("&")
	Method HasEllipsis:Int()
		If _hasEllipsis = -1 Then _hasEllipsis = GetWidth(Chr(8230))
		Return _hasEllipsis
	End Method


	Method GetEllipsis:String()
		If hasEllipsis() Then Return Chr(8230)
		Return "..."
	End Method


	Method GetMaxCharHeight:Int(includeBelowBaseLine:Int=True)
		If includeBelowBaseLine
			If _maxCharHeight = 0 Then _maxCharHeight = getHeight("gQ'_") 'including "()" adds too much to the font height
			Return _maxCharHeight
		Else
			If _maxCharHeightAboveBaseline = 0 Then _maxCharHeightAboveBaseline = getHeight("abCDE")
			Return _maxCharHeightAboveBaseline
		EndIf
	End Method


	Method GetWidth:Float(text:String)
		Local v:TVec2D = New TVec2D
		draw(text,0,0,Null,0, v)
		Return v.x
	End Method


	Method GetHeight:Float(text:String)
		Local v:TVec2D = New TVec2D
		draw(text,0,0,Null,0, v)
		Return v.y
	End Method


	Method GetBlockHeight:Float(text:String, w:Float, h:Float, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		If Not dimensionResult Then dimensionResult = New TVec2D
		drawBlock(text, 0,0,w,h, Null, Null, 0, 0, , , , , dimensionResult)
		Return dimensionResult.GetY()
	End Method


	Method GetBlockWidth:Float(text:String, w:Float, h:Float, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		If Not dimensionResult Then dimensionResult = New TVec2D
		drawBlock(text, 0,0,w,h, Null, Null, 0, 0, , , , , dimensionResult)
		Return dimensionResult.GetX()
	End Method


	Method GetBlockDimension:TVec2D(text:String, w:Float, h:Float, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		If Not dimensionResult Then dimensionResult = New TVec2D
		drawBlock(text, 0,0,w,h, Null, Null, 0, 0, , , , fixedLineHeight, dimensionResult)
		Return dimensionResult
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


	'splits a given text into an array of lines
	'splitting is done on "spaces", "-"
	'or in the middle of a word if "nicelyTruncateLastLine" is "FALSE"
	Method TextToMultiLine:String[](text:String, w:Float, h:Float, lineHeight:Float, nicelyTruncateLastLine:Int=True)
		Local fittingChars:Int	= 0
		Local processedChars:Int= 0
		Local paragraphs:String[]	= text.Replace(Chr(13), "~n").split("~n")
		'the lines to output at the end
		Local LINES:String[]= Null
		'how many space is left to draw?
		Local heightLeft:Float	= h
		'are we limited in height?
		Local limitHeight:Int = (heightLeft > 0)

		'for each line/paragraph
		For Local i:Int= 0 Until paragraphs.length
			'skip paragraphs if no space was left
			If limitHeight And heightLeft < lineHeight Then Continue

			Local line:String = paragraphs[i]

			'process each line - and if needed add a line break
			Repeat
				'the part of the line which has to get processed at that moment
				Local linePartial:String = line
				Local breakPosition:Int = line.length
				'whether to skip the next char of a new line
				Local skipNextChar:Int	= False


				'as long as the part of the line does not fit into
				'the given width, we have to search for linebreakers
				While (w>0 And Self.getWidth(linePartial) > w) And linePartial.length >0
					'whether we found a break position by a rule
					Local FoundBreakPosition:Int = False
					Local spaces:Int = 0

					'search for "nice" linebreak:
					'- if not on last line
					'- if enforced to do so ("nicelyTruncateLastLine")
					If i < (paragraphs.length-1) Or nicelyTruncateLastLine
						'search for the "most right" position of a
						'linebreak
						'no need to check for the last char (no break then ;-)
						For Local charPos:Int = 0 Until linePartial.length -1
							'special line break rules (spaces, -, ...)
							If linePartial[charPos] = Asc(" ")
								'use first space in a row ("  ")
								If spaces = 0
									breakPosition = charPos+1
									FoundBreakPosition=True
									'if it is a " "-space, we have to skip it
									skipNextChar = True 'aka delete the " "
								EndIf
								spaces :+ 1

							ElseIf linePartial[charPos] = Asc("-")
								breakPosition = charPos+1
								FoundBreakPosition=True

								skipNextChar = False

								spaces = 0
							Else
								spaces = 0
							EndIf
						Next
						'remove spaces at end
						If spaces > 0
							linePartial  = linePartial[.. linePartial.length - spaces]
						EndIf
					EndIf

					'if no line break rule hit, use a "cut" in the
					'middle of a word
					If Not FoundBreakPosition Then breakPosition = Max(0, linePartial.length-1 -1)

					'cut off the part AFTER the breakposition
					linePartial = linePartial[..breakPosition]
				Wend
				'add that line to the lines to draw
				LINES :+ [linePartial]

				heightLeft :- lineHeight


				'strip the processed part from the original line
				line = line[linePartial.length..]

			'	if skipNextChar then line = line[Min(1, line.length)..]
			'until no text left, or no space left for another line
			Until line.length = 0  Or (limitHeight And heightLeft < lineHeight)

			'if the height was not enough - add a "..."
			If line.length > 0
				'get the line BEFORE
				Local currentLine:String = LINES[LINES.length-1]
				'check whether we have to subtract some chars for the "..."
				Local ellipsisChar:String = GetEllipsis()
				If (w > 0 And getWidth(currentLine + ellipsisChar) > w)
					Repeat
						currentLine = currentLine[.. currentLine.length-1]
					Until getWidth(currentLine + ellipsisChar) <= w

					currentLine = currentLine + ellipsisChar
				Else
					currentLine = currentLine[.. currentLine.length] + ellipsisChar
				EndIf
				LINES[LINES.length-1] = currentLine
			EndIf
		Next

		Return LINES
	End Method


	'draws the text lines in a given block according to given alignment.
	'@nicelyTruncateLastLine:      try to shorten a word with "..."
	'                              or just truncate?
	'@centerSingleLineOnBaseline:  if only 1 line is given, is center
	'                              calculated using baseline (no "y,g,p,...")
	Method drawLinesBlock:Int(LINES:String[], x:Float, y:Float, w:Float, h:Float, alignment:TVec2D=Null, color:TColor=Null, style:Int=0, doDraw:Int = 1, special:Float=1.0, nicelyTruncateLastLine:Int=True, centerSingleLineOnBaseline:Int=False, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		'use special chars (instead of text) for same height on all lines
		Local alignedX:Float = 0.0
		Local lineMaxWidth:Float = 0
		Local lineWidth:Float = 0
		Local lineHeight:Float = getMaxCharHeight()
		If fixedLineHeight > 0 Then lineHeight = fixedLineHeight

		'first height was calculated using all characters, but we now
		'know if we could center using baseline only (only available
		'when there is only 1 line to draw)
		If fixedLineHeight <= 0
			If LINES.length = 1 And centerSingleLineOnBaseline
				lineHeight = getMaxCharHeight(False)
				'lineHeight = 0.25 * lineHeight + 0.75 * getMaxCharHeight(False)
				'lineHeight :+ 1 'a bit of influence of "below baseline" chars
			EndIf
		EndIf

		Local blockHeight:Float = lineHeight * LINES.length
		If fixedLineHeight <= 0
			If LINES.length > 1
				'add the lineHeightModifier for all lines but the first or
				'single one
				blockHeight :+ lineHeight * (lineHeightModifier-1.0)
			EndIf
		EndIf

		'move along y according alignment
		'-> aligned top: no change
		'-> aligned bottom: move down by unused space so last line ends at Y + h
		'-> aligned inbetween: move accordingly
		If alignment
			'empty space = height - (..)
			'-> alignTop = add 0 of that space
			'-> alignBottom = add 100% of that space
			If alignment.GetY() <> ALIGN_TOP And h > 0
				y :+ alignment.GetY() * (h - blockHeight)
			EndIf
		EndIf


		'backup current setting
		Local FontStyle:TBitmapFontStyle = New TBitmapFontStyle.Push(FName, FSize, FStyle, color)

		Local startY:Float = y
		For Local i:Int = 0 Until LINES.length
			lineWidth = getWidth(LINES[i])
			lineMaxWidth = Max(lineMaxwidth, lineWidth)

			'only align when drawing
			If doDraw
				If alignment And alignment.GetX() <> ALIGN_LEFT And w > 0
					alignedX = x + alignment.GetX() * (w - lineWidth)
				Else
					alignedX = x
				EndIf
			EndIf
			If fixedLineHeight <= 0
				Local p:TVec2D = New TVec2D
				__drawStyled( LINES[i], alignedX, y, color, style, doDraw, special, FontStyle, p)

				y :+ Min(_maxCharHeight, Max(lineHeight, p.y))
				'add extra spacing _between_ lines
				If LINES.length > 1 And i < LINES.length-1
					y :+ lineHeight * (lineHeightModifier-1.0)
				EndIf
			Else
				__drawStyled( LINES[i], alignedX, y, color, style, doDraw, special, FontStyle, Null)

				y :+ fixedLineHeight
			EndIf
		Next

		If dimensionResult Then dimensionResult.SetXY(lineMaxWidth, y - startY)

		Return True
	End Method


	'draws the text in a given block according to given alignment.
	'@nicelyTruncateLastLine:      try to shorten a word with "..."
	'                              or just truncate?
	'@centerSingleLineOnBaseline:  if only 1 line is given, is center
	'                              calculated using baseline (no "y,g,p,...")
	Method drawBlock:Int(text:String, x:Float, y:Float, w:Float, h:Float, alignment:TVec2D=Null, color:TColor=Null, style:Int=0, doDraw:Int = 1, special:Float=1.0, nicelyTruncateLastLine:Int=True, centerSingleLineOnBaseline:Int=False, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		Local lineHeight:Float = getMaxCharHeight()
		Local LINES:String[] = TextToMultiLine(text, w, h, lineHeight, nicelyTruncateLastLine)

		Return drawLinesBlock(LINES, x, y, w, h, alignment, color, style, doDraw, special, nicelyTruncateLastLine, centerSingleLineOnBaseline, fixedLineHeight, dimensionResult)
	End Method


	Method drawWithBG:Int(value:String, x:Int, y:Int, bgAlpha:Float = 0.3, bgCol:Int = 0, style:Int=0, dimensionResult:TVec2D = Null)
		Local OldAlpha:Float = GetAlpha()
		Local color:TColor = New TColor.Get()

		drawStyled(value,0,0, Null, style,0 , , dimensionResult)

		SetAlpha bgAlpha
		SetColor bgCol, bgCol, bgCol
		DrawRect(x, y, dimensionResult.GetX(), dimensionResult.GetY())
		color.setRGBA()

		'backup current setting
		Local FontStyle:TBitmapFontStyle = New TBitMapFontStyle.Push( FName, FSize, FStyle, color )

		Return __drawStyled(value, x, y, color, style, True, , FontStyle, dimensionResult)
	End Method


	'can adjust used font or color
	Method ProcessCommand:Int(command:String, payload:String, FontStyle:TBitMapFontStyle)
		If command = "color" And Not FontStyle.ignoreColorTag
			Local colors:String[] = payload.split(",")
			Local color:TColor
			If colors.length >= 3
				color = New TColor
				color.r = Int(colors[0])
				color.g = Int(colors[1])
				color.b = Int(colors[2])
				If colors.length >= 4
					color.a = Int(colors[3]) / 255.0
				Else
					color.a = 1.0
				EndIf
			Else
				If Not FontStyle.GetColor()
					color = TColor.clWhite.Copy()
				Else
					color = FontStyle.GetColor().Copy()
				EndIf
			EndIf

			'backup current setting
			FontStyle.PushColor( color )
		EndIf
		If command = "/color" And Not FontStyle.ignoreColorTag
			'local color:TColor =
			FontStyle.PopColor()
		EndIf

		If command = "b" Then FontStyle.PushFontStyle( BOLDFONT )
		If command = "/b" Then FontStyle.PopFontStyle( BOLDFONT )

		If command = "i" Then FontStyle.PushFontStyle( ITALICFONT )
		If command = "/i" Then FontStyle.PopFontStyle( ITALICFONT )

		'adjust line height if another font is selected
		If FontStyle.GetFont() <> Self And FontStyle.GetFont()
			FontStyle.styleDisplaceY = 0.5*(getMaxCharHeight() - FontStyle.GetFont().getMaxCharHeight())
		Else
			'reset displace
			FontStyle.styleDisplaceY = 0
		EndIf
	End Method


	Method draw:Int(text:String,x:Float,y:Float, color:TColor=Null, doDraw:Int=True, dimensionResult:TVec2D = Null)
		'backup current setting
		Local FontStyle:TBitmapFontStyle = New TBitmapFontStyle.Push(FName, FSize, FStyle, color)

		Return __draw(text, x, y, color, doDraw, FontStyle, dimensionResult)
	End Method


	Method drawStyled:Int(text:String,x:Float,y:Float, color:TColor=Null, style:Int=0, doDraw:Int=1, special:Float=-1.0, dimensionResult:TVec2D = Null)
		'backup current setting
		Local FontStyle:TBitmapFontStyle = New TBitmapFontStyle.Push(FName, FSize, FStyle, color)

		Return __drawStyled(text, x, y, color, style, doDraw, special, FontStyle, dimensionResult)
	End Method


	Method __drawStyled:Int(text:String,x:Float,y:Float, color:TColor=Null, style:Int=0, doDraw:Int=1, special:Float=-1.0, FontStyle:TBitmapFontStyle, dimensionResult:TVec2D = Null)
		If special = -1 Then special = 1 '100%

		If drawAtFixedPoints
			x = Int(x)
			y = Int(y)
		EndIf

		Local height:Float = 0.0
		Local width:Float = 0.0

		'backup old color
		Local oldColor:TColor
		If doDraw Then oldColor = New TColor.Get()

		'emboss
		If style = STYLE_EMBOSS
			height:+ 1
			If doDraw
				SetAlpha Float(special * 0.5 * oldColor.a)
				FontStyle.ignoreColorTag :+ 1
				__draw(text, x, y+1, embossColor, doDraw, FontStyle, Null)
				FontStyle.ignoreColorTag :- 1
			EndIf
		'shadow
		Else If style = STYLE_SHADOW
			height:+ 1
			width:+1
			If doDraw
				SetAlpha special*0.5*oldColor.a
				FontStyle.ignoreColorTag :+ 1
				__draw(text, x+1,y+1, shadowColor, doDraw, FontStyle, Null)
				FontStyle.ignoreColorTag :- 1
			EndIf
		'glow
		Else If style = STYLE_GLOW
			If doDraw
				FontStyle.ignoreColorTag :+ 1
				shadowColor.SetRGB()
				SetAlpha special*0.25*oldColor.a
				__draw(text, x-2,y, ,doDraw, FontStyle, Null)
				__draw(text, x+2,y, ,doDraw, FontStyle, Null)
				__draw(text, x,y-2, ,doDraw, FontStyle, Null)
				__draw(text, x,y+2, ,doDraw, FontStyle, Null)
				SetAlpha special*0.5*oldColor.a
				__draw(text, x+1,y+1, ,doDraw, FontStyle, Null)
				__draw(text, x-1,y-1, ,doDraw, FontStyle, Null)
				FontStyle.ignoreColorTag :- 1
			EndIf
		EndIf

		If oldColor Then SetAlpha oldColor.a
		__draw(text,x,y, color, doDraw, FontStyle, dimensionResult)
		If oldColor Then oldColor.SetRGBA()

		Return True
	End Method


	Method __draw:Int(text:String,x:Float,y:Float, color:TColor=Null, doDraw:Int=True, FontStyle:TBitmapFontStyle, dimensionResult:TVec2D = Null)
		Local width:Float = 0.0
		Local height:Float = 0.0
		Local textLines:String[]	= text.Replace(Chr(13), "~n").split("~n")
		Local currentLine:Int = 0
		Local oldColor:TColor
		If doDraw
			oldColor = New TColor.Get()
			If Not color
				color = oldColor.copy()
			Else
				'take screen alpha into consideration
				'create a copy to not modify the original
				color = color.copy()
				color.a :* oldColor.a
			EndIf
			'black text is default
'			if not color then color = TColor.Create(0,0,0)
			If color Then color.SetRGBA()
		EndIf
		'set the lineHeight before the "for-loop" so it has a set
		'value if a line "in the middle" just consists of spaces/nothing
		'-> allows double-linebreaks

		'control vars
		Local controlChar:Int = Asc("|")
		Local controlCharEscape:Int = Asc("\")
		Local controlCharStarted:Int = False
		Local currentControlCommandPayloadSeparator:String = "="
		Local currentControlCommand:String = ""
		Local currentControlCommandPayload:String = ""

		Local lineHeight:Int = 0
		Local charCode:Int
		Local displayCharCode:Int 'if char is not found
		Local charBefore:Int
		Local Rotation:Int = GetRotation()
		Local sprite:TSprite
		'cache
		Local font:TBitmapFont = FontStyle.GetFont()
'		if not color then color = new TColor.Get()

		'store current color
		FontStyle.PushColor(color)

		For text:String = EachIn textLines

			'except first line (maybe only one line) - add extra spacing
			'between lines
			If currentLine > 0 Then height:+ Ceil( lineHeight* (font.lineHeightModifier-1.0) )

			currentLine:+1

			Local lineWidth:Float = 0

			For Local i:Int = 0 Until text.length
				charCode = Int(text[i])

				'reload with utf8?
				If charCode > 256 And MaxSigns = 256 And glyphCount > 256 And extraChars.find(Chr(charCode)) = -1
					LoadExtendedCharacters()
				EndIf


				'check for controls
				If controlCharStarted
					'receiving command
					If charCode <> controlChar
						currentControlCommand:+ Chr(charCode)
					'receive stopper
					Else
						controlCharStarted = False
						Local commandData:String[] = currentControlCommand.split(currentControlCommandPayloadSeparator)
						currentControlCommand = commandData[0]
						If commandData.length>1 Then currentControlCommandPayload = commandData[1]

							ProcessCommand(currentControlCommand, currentControlCommandPayload, FontStyle)
							If FontStyle.GetColor()
								color = FontStyle.GetColor().Copy()
								If doDraw
									color.SetRGBA()
								EndIf
							EndIf
						'cache font to speed up processing
						font = FontStyle.GetFont()

						'reset
						currentControlCommand = ""
						currentControlCommandPayload = ""
					EndIf
					'skip char
					Continue
				EndIf

				'someone wants style the font
				If charCode = controlChar And charBefore <> controlCharEscape
					controlCharStarted = 1 - controlCharStarted
					'skip char
					charBefore = charCode
					Continue
				EndIf
				'skip drawing the escape char if we are escaping the
				'command char
				If charCode = controlCharEscape And i < text.length-1 And text[i+1] = controlChar
					charBefore = charCode
					Continue
				EndIf

				Local bm:TBitmapFontChar
				' = TBitmapFontChar( font.chars.ValueForKey(charCode) )
				If charCode < font.chars.length Then
					bm = font.chars[charCode]
				End If
				If bm
					displayCharCode = charCode
				Else
					displayCharCode = Asc("?")
					If charCode < font.chars.length Then
						bm = font.chars[charCode]
					End If
					'bm = TBitmapFontChar( font.chars.ValueForKey(displayCharCode) )
				EndIf
				If bm
					Local tx:Float = bm.area.GetX() * gfx.tform_ix + bm.area.GetY() * gfx.tform_iy
					Local ty:Float = bm.area.GetX() * gfx.tform_jx + bm.area.GetY() * gfx.tform_jy
					'drawable ? (> 32)
					If text[i] > 32
						lineHeight = Max(lineHeight, bm.area.GetH())
						If doDraw
							If displayCharCode < font.charsSprites.length
								sprite = font.charsSprites[displayCharCode]
							Else
								sprite = Null
							End If
							'sprite = TSprite(font.charsSprites.ValueForKey(displayCharCode))
							If sprite
								If drawToPixmap
									sprite.DrawOnImage(drawToPixmap, Int(pixmapOrigin.x + x+lineWidth+tx), Int(pixmapOrigin.y + y+height+ty + FontStyle.styleDisplaceY - font.displaceY), -1, Null, color)
								Else
									sprite.Draw(Int(x+lineWidth+tx), Int(y+height+ty + FontStyle.styleDisplaceY - font.displaceY))
								EndIf
							EndIf
						EndIf
					EndIf
					If Rotation = -90
						height:- Min(lineHeight, bm.area.GetW())
					ElseIf Rotation = 90
						height:+ Min(lineHeight, bm.area.GetW())
					ElseIf Rotation = 180
						lineWidth :- bm.charWidth * gfx.tform_ix
					Else
						If text[i] = 32 'space
							lineWidth :+ bm.charWidth * gfx.tform_ix * spaceWidthModifier
						ElseIf text[i] = KEY_TAB
							lineWidth =  (Int(lineWidth / tabWidth)+1) * tabWidth
						Else
							lineWidth :+ bm.charWidth * gfx.tform_ix
						EndIf
					EndIf
				ElseIf text[i] = KEY_TAB
					lineWidth =  (Int(lineWidth / tabWidth)+1) * tabWidth
				EndIf

				charBefore = charCode
			Next
			width = Max(width, lineWidth)
			height :+ lineHeight
			'add extra spacing _between_ lines
			'not done when only 1 line available or on last line
			If currentLine < textLines.length
				height:+ Ceil( lineHeight* (font.lineHeightModifier-1.0) )
			EndIf
		Next

		'restore color
		If doDraw Then oldColor.SetRGBA()

		FontStyle.PopColor()

		If dimensionResult Then dimensionResult.SetXY(width, height)

		Return True
	End Method

Rem
DISABLECACHE
	Function onUpdateCaches(triggerEvent:TEventBase)
		For local key:string = eachin TBitmapFont.ImageCaches.Keys()
			local cache:TImageCache = TImageCache(TBitmapFont.ImageCaches.ValueForKey(key))
			if cache and not cache.isAlive() then TBitmapFont.ImageCaches.Remove(key)
		Next
	End Function
EndRem
End Type




Type TStyledBitmapFonts
	Field styles:TBitmapFont[2]

	Method Get:TBitmapFont(style:Int)
		style :+ 1
		If style < styles.length
			Return styles[style]
		End If
	End Method

	Method Insert(style:Int, font:TBitmapFont)
		style :+ 1
		If style >= styles.length
			styles = styles[..style + 1]
		End If
		styles[style] = font
	End Method
End Type




Type TSizedBitmapFonts
	Field sizes:TStyledBitmapFonts[12]

	Method Get:TBitmapFont(size:Int, style:Int)
		size :+ 1
		If size < sizes.length
			Local styled:TStyledBitmapFonts = sizes[size]
			If styled Then
				Return styled.Get(style)
			End If
		End If
	End Method

	Method Insert(size:Int, style:Int, font:TBitmapFont)
		size :+ 1
		If size >= sizes.length
			sizes = sizes[..size + 1]
		End If
		Local styled:TStyledBitmapFonts = sizes[size]
		If Not styled Then
			styled = New TStyledBitmapFonts
			sizes[size] = styled
		End If

		styled.Insert(style, font)
	End Method
End Type


Type TBitmapFontStyle
	Field fontNames:TList = CreateList()
	Field fontSizes:TList = CreateList()
	'one counter for each style (italicfont, boldfont)
	Field fontStyles:Int[2]
	Field colors:TList = CreateList()
	Field ignoreColorTag:Int = False
	Field ignoreStyleTags:Int = False
	Global styleDisplaceY:Int = 0

	Method Reset()
		fontNames.Clear()
		fontSizes.Clear()
		fontStyles[0] = 0
		fontStyles[1] = 0
		colors.Clear()
		styleDisplaceY = 0
	End Method


	Method Push:TBitMapFontStyle(fName:String, fSize:Int, fStyle:Int, color:TColor)
		PushFontName(fName)
		PushFontSize(fSize)
		PushFontStyle(fStyle)
		PushColor(color)
		Return Self
	End Method


	Method PushColor( color:TColor )
		'reuse the last one
		If Not color Then color = GetColor()

		colors.AddLast( color )
	End Method


	Method PopColor:TColor()
		Return TColor(colors.RemoveLast())
	End Method


	Method PushFontStyle( style:Int )
		If (style & BOLDFONT) > 0 Then fontStyles[0] :+ 1
		If (style & ITALICFONT) > 0 Then fontStyles[1] :+ 1
	End Method


	Method PopFontStyle:Int( style:Int )
		If (style & BOLDFONT) > 0 Then fontStyles[0] = Max(0, fontStyles[0] - 1)
		If (style & ITALICFONT) > 0 Then fontStyles[1] = Max(0, fontStyles[1] - 1)

		Return GetFontStyle()
	End Method


	Method PushFontSize( size:Int )
		If Not size Then size = GetFontSize()

		fontSizes.AddLast( String(size) )
	End Method


	Method PopFontSize:Int()
		Return Int(String(fontSizes.RemoveLast()))
	End Method


	Method PushFontName( name:String)
		fontNames.AddLast( name )
	End Method


	Method PopFontname:String()
		Return String(fontNames.RemoveLast())
	End Method


	Method GetColor:TColor()
		Local col:TColor = TColor(colors.Last())
		If Not col Then col = New TColor.Get()
		Return col
	End Method


	Method GetFontName:String()
		Return String(fontNames.Last())
	End Method


	Method GetFontSize:Int()
		Return Int(String(fontSizes.Last()))
	End Method


	Method GetFontStyle:Int()
		Local style:Int = 0
		If fontStyles[0] > 0 Then style :| BOLDFONT
		If fontStyles[1] > 0 Then style :| ITALICFONT
		Return style
	End Method


	Method GetFont:TBitmapfont()
		Return GetBitmapFontManager().Get(GetFontName(), GetFontSize(), GetFontStyle())
	End Method
End Type




' - max2d/max2d.bmx -> loadimagefont
' - max2d/imagefont.bmx TImageFont.Load ->
Function LoadTrueTypeFont:TImageFont( url:Object,size:Int,style:Int )
	Local src:TFont = TFreeTypeFont.Load( String( url ), size, style )
	If Not src Then Return Null

	Local font:TImageFont=New TImageFont
	font._src_font=src
	font._glyphs=New TImageGlyph[src.CountGlyphs()]
	If style & SMOOTHFONT Then font._imageFlags=FILTEREDIMAGE|MIPMAPPEDIMAGE

	Return font
End Function




Type TBitmapFontText
	Field offsetX:Int, offsetY:Int
	Field text:String
	Field x:Float, y:Float, w:Float, h:Float
	Field style:Int = 0
	Field special:Float = -1.0
	Field font:TBitmapFont
	Field alignment:TVec2D
	Field color:TColor
	Field nicelyTruncateLastLine:Int = True
	Field centerSingleLineOnBaseline:Int = False
	Field fixedLineHeight:Int = -1

	Field cache:TImage

Rem
	Method SetText(text:String, skipChecks:Int = False)
		if skipChecks or self.text <> text
			self.text = text

			cache = CreateImage( dimensionResult.x, dimensionResult.y )
			FillCache(cache)
		EndIf
	End Method
endrem

	Method Invalidate()
		cache = Null
	End Method


	Method HasCache:Int()
		Return cache <> Null
	End Method


	Method FillCache(img:TImage)
		Local p:TPixmap = LockImage(img)
		p.ClearPixels(0)
		UnlockImage(img)

		font.SetRenderTarget( img )
		font.DrawBlock(text, -offsetX, -offsetY,w,h,alignment,color,style, True, special, nicelyTruncateLastLine, centerSingleLineOnBaseline, fixedLineHeight, Null)
		font.SetRenderTarget( Null )
	End Method


	Method DrawCached:Int(x:Float, y:Float)
		If cache Then DrawImage(cache, x + offsetX, y + offsetY)
	End Method


	Method CacheDraw:Int(font:TBitmapFont, text:String, x:Float, y:Float, color:TColor=Null, dimensionResult:TVec2D = Null)
		If cache
			If Self.w<>w Or Self.h<>h
				cache = Null
			ElseIf text <> text
				cache = Null
			ElseIf Self.font<>font
				cache = Null
			ElseIf (Self.color And Not Self.color.IsSame(color)) Or (Not Self.color And color)
				cache = Null
			EndIf
		EndIf

		If Not cache
			Self.font = font
			Self.text = text
			If color
				Self.color = color.copy()
			Else
				Self.color = Null
			EndIf

			'render to image
			'first we render to the screen to get the dimensions
			If Not dimensionResult Then dimensionResult = New TVec2D
			'fetch dimension
			font.Draw(text, x,y, color, False, dimensionResult)

			Self.w = dimensionResult.x
			Self.h = dimensionResult.y

			cache = CreateImage( Int(Self.w), Int(Self.h) )

'Print "create draw cache for: " + text + "    " + w +"," +h
			FillCache(cache)
		EndIf
	End Method


	Method Draw:Int(font:TBitmapFont, text:String, x:Float, y:Float, color:TColor=Null, dimensionResult:TVec2D = Null)
		If text = ""
			'an empty text can still move forward to a "new line"
			If font And dimensionResult
				dimensionResult.x = 0
				dimensionResult.y = font.GetMaxCharHeight()
			EndIf
			Return False 'nothing to render
		EndIf

		If Not cache Then CacheDraw(font, text, x, y, color, dimensionResult)

		DrawImage(cache, x, y)

		If dimensionResult Then dimensionResult.SetXY(cache.width, cache.height)
		Return True
	End Method


	Method CacheDrawBlock:Int(font:TBitmapFont, text:String, x:Float, y:Float, w:Float, h:Float, alignment:TVec2D=Null, color:TColor=Null, style:Int=0, doDraw:Int = 1, special:Float=1.0, nicelyTruncateLastLine:Int=True, centerSingleLineOnBaseline:Int=False, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		If cache
'			If self.x<>x or self.y<>y or self.w<>w or self.h<>h
'				cache = Null
			If Self.w<>w Or Self.h<>h
				cache = Null
			ElseIf text <> text
				cache = Null
			ElseIf Self.font<>font
				cache = Null
			ElseIf Self.style<>style Or Self.special<>special
				cache = Null
			ElseIf (Self.color And Not Self.color.IsSame(color)) Or ((Self.color<>Null) <> (color<>Null))
				cache = Null
			ElseIf (Self.alignment And Not Self.alignment.IsSame(alignment)) Or ((Self.alignment<>Null) <> (alignment<>Null))
				cache = Null
			ElseIf Self.nicelyTruncateLastLine <> nicelyTruncateLastLine Or Self.centerSingleLineOnBaseline <> centerSingleLineOnBaseline Or Self.fixedLineHeight <> fixedLineHeight
				cache = Null
			EndIf
		EndIf

		If Not cache
			Self.font = font
			Self.text = text
'			self.x = x
'			self.y = y
			Self.w = w
			Self.h = h
			Self.style = style
			Self.special = special
			If alignment
				Self.alignment = alignment.copy()
			Else
				Self.alignment = Null
			EndIf
			If color
				Self.color = color.copy()
			Else
				Self.color = Null
			EndIf
			Self.nicelyTruncateLastLine = nicelyTruncateLastLine
			Self.centerSingleLineOnBaseline = centerSingleLineOnBaseline
			Self.fixedLineHeight = fixedLineHeight

			'render to image
			If Not dimensionResult Then dimensionResult = New TVec2D
			'fetch dimension
			font.DrawBlock(text, x,y,w,h,alignment,color,style, False, special, nicelyTruncateLastLine, centerSingleLineOnBaseline, fixedLineHeight, dimensionResult)

			'invalid glyphs might lead to dimensions of "0"
			If dimensionResult.x <= 0 Then dimensionResult.x = 1
			If dimensionResult.y <= 0 Then dimensionResult.y = 1

			If w = -1 Or Not alignment
				offsetX = 0
			Else
				offsetX = (w - dimensionResult.x) * alignment.x
			EndIf
			If h = -1 Or Not alignment
				offsetY = 0
			Else
				offsetY = (h - dimensionResult.y) * alignment.y
			EndIf
Rem
Print "size: " + w + ", " + h
Print "offset: " + offsetX + ", " + offsetY
Print "dimension: " + dimensionResult.ToString()
Print "alignment: " + alignment.ToString()

Print "create drawblock cache for: " + text + "    " + w +"," +h + "   " + dimensionResult.ToString()
EndRem

			cache = CreateImage( Int(dimensionResult.x), Int(dimensionResult.y) )
'			cache = CreateImage( int(Max(dimensionResult.x, w)), int(Max(dimensionResult.y, h)) )
			FillCache(cache)
		EndIf
	End Method


	Method DrawBlock:Int(font:TBitmapFont, text:String, x:Float, y:Float, w:Float, h:Float, alignment:TVec2D=Null, color:TColor=Null, style:Int=0, doDraw:Int = 1, special:Float=1.0, nicelyTruncateLastLine:Int=True, centerSingleLineOnBaseline:Int=False, fixedLineHeight:Int = -1, dimensionResult:TVec2D = Null)
		If text = ""
			'an empty text can still move forward to a "new line"
			If font And dimensionResult
				dimensionResult.x = 0
				dimensionResult.y = font.GetMaxCharHeight()
			EndIf
			Return False 'nothing to render
		EndIf

		CacheDrawBlock(font, text, x, y, w, h, alignment, color, style, doDraw, special, nicelyTruncateLastLine, centerSingleLineOnBaseline, fixedLineHeight, dimensionResult)

		DrawImage(cache, x + offsetX, y + offsetY)

		If dimensionResult Then dimensionResult.SetXY(cache.width, cache.height)
		Return True
	End Method
End Type