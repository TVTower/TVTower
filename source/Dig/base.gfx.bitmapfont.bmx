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




CONST SHADOWFONT:INT = 256
CONST GRADIENTFONT:INT = 512

Type TBitmapFontManager
	Field baseFont:TBitmapFont
	Field baseFontBold:TBitmapFont
	Field baseFontItalic:TBitmapFont
	Field baseFontSmall:TBitmapFont
	Field _defaultFont:TBitmapFont
	Field fonts:TStringMap = new TStringMap
	Global systemFont:TBitmapFont
	Global _instance:TBitmapFontManager
	Global _defaultFlags:int = 0 'SMOOTHFONT


	Function GetInstance:TBitmapFontManager()
		if not _instance then _instance = new TBitmapFontManager
		return _instance
	End Function


	Method GetDefaultFont:TBitmapFont()
		'instead of doing it in "new" (no guarantee that graphicsmode
		'is set up already)
		if not systemFont then systemFont = TBitmapFont.Create("SystemFont", "", 12, SMOOTHFONT)

		'if no default font was set, return the system font
		if not _defaultFont then return systemFont

		return _defaultFont
	End Method


	'get ignores the "SMOOTHFONT" flag to allow adding "crisp" fonts
	Method Get:TBitmapFont(name:String="", size:Int=-1, style:Int=-1)
		name = lower(name)

		'fall back to default font if none was given
		if name = "" then name = "default"

		'no details given: return default font
		If name = "default" And size = -1 And style = -1 then return GetDefaultFont()


		'try to find default font settings for this font face
		Local hasDefaultStyledFont:int = False
		Local hasDefaultFont:int = False
		Local defaultStyledFont:TBitmapFont = TBitmapFont(fonts.ValueForKey(name+"_-1_"+style))
		Local defaultFont:TBitmapFont = defaultStyledFont

		if not defaultStyledFont
			defaultFont = TBitmapFont(fonts.ValueForKey(name))
			defaultStyledFont = defaultFont
			if defaultFont
				hasDefaultFont = True
			endif
		else
			hasDefaultStyledFont = True
		endif
		if not defaultStyledFont then defaultStyledFont = GetDefaultFont()


		'no size given: use default font size
		If size = -1 Then size = defaultStyledFont.FSize
		'no style given: use default font style
		If style = -1 Then style = defaultStyledFont.FStyle


		local key:string = name + "_" + size + "_" + style
		local font:TBitmapFont = TBitmapFont(fonts.ValueForKey(key))
		if font then return font
		'if the font wasn't found, use the defaultFont-fontfile to load this style
		font = Add(name, defaultStyledFont.FFile, size, style)

rem
		'insert as default too
		if not hasDefaultStyledFont then fonts.Insert(name+"_-1_"+style, font)
		if not hasDefaultFont then fonts.Insert(name, font)
		'if SMOOTHFONT was used - add the unsmoothed too (for easier retrieval)
		if (style & SMOOTHFONT) <> 0
			local keyWithoutSmooth:string = name + "_" + size + "_" + (style - SMOOTHFONT)
			if not TBitmapFont(fonts.ValueForKey(keyWithoutSmooth))
				fonts.insert(keyWithoutSmooth, font)
			endif
		endif
endrem

		Return font
	End Method


	Method Copy:TBitmapFont(sourceName:string, copyName:string, size:int=-1, style:int=-1)
		local sourceFont:TBitmapFont = Get(sourceName, size, style)
		Local newFont:TBitmapFont = TBitmapFont.Create(copyName, sourceFont.fFile, sourceFont.fSize, sourceFont.fStyle, sourceFont.fixedCharWidth, sourceFont.charWidthModifier)
		fonts.Insert(copyName+"_"+sourceFont.fSize+"_"+sourceFont.fStyle, newFont)

		return newFont
	End Method


	Method Add:TBitmapFont(name:String, file:String, size:Int, style:Int=0, ignoreDefaultStyle:int = False, fixedCharWidth:int=-1, charWidthModifier:Float=1.0)
		name = lower(name)
		if not ignoreDefaultStyle
			style :| _defaultFlags
		endif

		local defaultFont:TBitmapFont = GetDefaultFont()
		If size = -1 Then size = defaultFont.FSize
		If style = -1 Then style = defaultFont.FStyle
		If file = "" Then file = defaultFont.FFile

		Local font:TBitmapFont = TBitmapFont.Create(name, file, size, style, fixedCharWidth, charWidthModifier)
		Local key:string = name+"_"+size+"_"+style
		fonts.Insert(key, font)

		'insert as default font too (name + style, ignore size)
		if not TBitmapFont(fonts.ValueForKey(name+"_-1_"+style)) then fonts.Insert(name+"_-1_"+style, font)
		'insert as default font too (only name)
		if not TBitmapFont(fonts.ValueForKey(name)) then fonts.Insert(name, font)

		'if SMOOTHFONT was used - add the unsmoothed too (for easier retrieval)
		if (style & SMOOTHFONT) <> 0
			local styleNonSmooth:int = style - SMOOTHFONT
			if not TBitmapFont(fonts.ValueForKey(name + "_-1_" + (style - SMOOTHFONT)))
				fonts.insert(name + "_-1_" + (style - SMOOTHFONT), font)
			endif

			if not TBitmapFont(fonts.ValueForKey(name + "_" + size + "_" + (style - SMOOTHFONT)))
				fonts.insert(name + "_" + size + "_" + (style - SMOOTHFONT), font)
			endif
		endif



		'set default fonts if not done yet
		if _defaultFont = null then _defaultFont = Font
		if baseFont = null then baseFont = Font
		if baseFontBold = null and style & BOLDFONT > 0 then baseFontBold = Font
		if baseFontItalic  = null and style & ITALICFONT > 0 then baseFontItalic = Font

		Return Font
	End Method


	Method AddFont:TBitmapFont(font:TBitmapFont)
		local key:string = font.FName + "_" + font.FSize + "_" + font.FStyle
		fonts.insert(key, font)
	End Method

End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetBitmapFontManager:TBitmapFontManager()
	return TBitmapFontManager.GetInstance()
End Function

'===== CONVENIENCE ACCESSORS =====
'not really needed - but for convenience to avoid direct call to the
'instance getter GetBitmapFontManager()
Function GetBitmapFont:TBitmapfont(name:string="", size:Int=-1, style:Int=-1)
	Return TBitmapFontManager.GetInstance().Get(name, size, style)
End Function



Type TBitmapFontChar
	Field area:TRectangle
	Field charWidth:float
	Field img:TImage


	Method Init:TBitmapFontChar(img:TImage, x:int,y:int,w:Int, h:int, charWidth:float)
		self.img = img
		self.area = new TRectangle.Init(x, y, w, h)
		self.charWidth = charWidth
		Return self
	End Method
End Type




Type TBitmapFont
	'identifier
	Field FName:string = ""
	'source path
	Field FFile:string = ""
	'size of this font
	Field FSize:int = 0
	'style used in this font
	Field FStyle:int = 0
	'the original imagefont
	Field FImageFont:TImageFont

	Field chars:TBitmapFontChar[] = new TBitmapFontChar[256]
	Field charsSprites:TSprite[] = new TSprite[0]
	Field spriteSet:TSpritePack
	'by default only the first 256 chars get loaded
	'as soon as an "utf8"-code is requested, the font will re-init with
	'more sprites
	Field MaxSigns:Int = 256
	Field glyphCount:int = 0
	Field ExtraChars:String = ""
	Field gfx:TMax2dGraphics
	Field uniqueID:string =""
	Field displaceY:float=100.0
	'modifier * lineheight gets added at the end
	Field lineHeightModifier:float = 1.05
	'value the width of " " (space) is multiplied with
	Field spaceWidthModifier:float = 1.0
	Field charWidthModifier:float = 1.0
	Field fixedCharWidth:int = -1
	Field tabWidth:int = 15
	'whether to use ints or floats for coords
	Field drawAtFixedPoints:int = true
	Field _charsEffectFunc:TBitmapFontChar(font:TBitmapFont, charKey:int, char:TBitmapFontChar, config:TData)[]
	Field _charsEffectFuncConfig:TData[]
	'by default this is 8bit alpha only
	Field _pixmapFormat:int = PF_A8
	Field _maxCharHeight:int = 0
	Field _maxCharHeightAboveBaseline:int = 0
	Field _hasEllipsis:int = -1

	global drawToPixmap:TPixmap = null
	global pixmapOrigin:TVec2D = new TVec2D.Init(0,0)
'DISABLECACHE	global ImageCaches:TMap = CreateMap()
	global eventRegistered:int = 0

	global shadowColor:TColor = new TColor.clBlack
	global embossColor:TColor = new TColor.clWhite

	Const STYLE_NONE:int = 0
	Const STYLE_EMBOSS:int = 1
	Const STYLE_SHADOW:int = 2
	Const STYLE_GLOW:int = 3


	Function Create:TBitmapFont(name:String, url:String, size:Int, style:Int, fixedCharWidth:int = -1, charWidthModifier:Float = 1.0)
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
		If not obj.FImageFont
			'get system/current font
			obj.FImageFont = GetImageFont()
		endif
		If not obj.FImageFont
			Throw ("TBitmapFont.Create: font ~q"+url+"~q not found.")
			Return Null 'font not found
		endif

		'create spriteset
		obj.spriteSet = new TSpritePack.Init(null, obj.uniqueID+"_charmap")

		'generate a charmap containing packed rectangles where to store images
		obj.InitFont()

		'listen to App-timer
'DISABLECACHE		EventManager.registerListener( "App.onUpdate", 	TEventListenerRunFunction.Create(TBitmapFont.onUpdateCaches) )
		Return obj
	End Function


	Method SetCharsEffectFunction(position:int, _func:TBitmapFontChar(font:TBitmapFont, charKey:int, char:TBitmapFontChar, config:TData), config:TData=null)
		position :-1 '0 based
		if _charsEffectFunc.length <= position
			_charsEffectFunc = _charsEffectFunc[..position+1]
			_charsEffectFuncConfig = _charsEffectFuncConfig[..position+1]
		endif
		_charsEffectFunc[position] = _func
		_charsEffectFuncConfig[position] = config
	End Method


	'overrideable method
	Method ApplyCharsEffect(config:TData=null)
		'if instead of overriding a function was provided - use this
		if _charsEffectFunc.length > 0
			'for local _charKey:TIntKey = eachin chars.keys()
			for local charKey:int = 0 until chars.length

				'local charKey:Int = _charKey.Value
				'local char:TBitmapFontChar = TBitmapFontChar(chars.ValueForKey(charKey))
				local char:TBitmapFontChar = chars[charKey]
				If Not char then
					Continue
				End If

				'manipulate char
				local _func:TBitmapFontChar(font:TBitmapFont, charKey:int, char:TBitmapFontChar, config:TData)
				local _config:TData
				for local i:int = 0 to _charsEffectFunc.length-1
					_func = _charsEffectFunc[i]
					_config = _charsEffectFuncConfig[i]
					if not _config then _config = config
					char = _func(self, charKey, char, _config)
				Next
				'overwrite char
				'chars.Insert(charKey, char)
				chars[charKey] = char
			Next
		endif
		'else do nothing by default
	End Method


	'returns the same font in the given size/style combination
	'it is more or less a wrapper to make acces more convenient
	Method GetVariant:TBitmapFont(size:int=-1, style:int = -1)
		if size = -1 then size = self.FSize
		if style = -1 then style = self.FStyle
		return TBitmapFontManager.GetInstance().Get(self.FName, size, style)
	End Method


	'generate a charmap containing packed rectangles where to store images
	Method InitFont(config:TData=null )
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
	Method LoadCharsFromSource(source:object=null)
		local imgFont:TImageFont = TImageFont(source)
		if imgFont = null then imgFont = FImageFont
		Local glyph:TImageGlyph
		Local glyphCount:Int = imgFont.CountGlyphs()
		Local n:int
		Local loadMaxGlyphs:int = glyphCount
		if MaxSigns <> -1 then loadMaxGlyphs = MaxSigns

		if extraChars = ""
			extraChars :+ chr(8364) '€
			extraChars :+ chr(8230) '…
			extraChars :+ chr(8220) '“
			extraChars :+ chr(8221) '”
			extraChars :+ chr(8222) '„
			extraChars :+ chr(171) '«
			extraChars :+ chr(187) '»
			'extraChars :+ chr(8227) '‣
			'extraChars :+ chr(9662) '▾
			extraChars :+ chr(9650) '▲
			extraChars :+ chr(9660) '▼
			extraChars :+ chr(9664) '◀
			extraChars :+ chr(9654) '▶
			extraChars :+ chr(9632) '■
		endif

		self.glyphCount = glyphCount

		For Local i:Int = 0 Until loadMaxGlyphs
'		For Local i:Int = 0 Until MaxSigns
			n = imgFont.CharToGlyph(i)
			If n < 0 or n > glyphCount then Continue
			glyph = imgFont.LoadGlyph(n)
			If not glyph then continue

			'base displacement calculated with A-Z (space between
			'TOPLEFT of 'ABCDE' and TOPLEFT of 'acen'...)
			if i >= 65 AND i < 95 then displaceY = Min(displaceY, glyph._y)
			resizeChars(i)
			'chars.insert(i, new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance))
			if fixedCharWidth > 0
				chars[i] = new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w ,glyph._h, fixedCharWidth)
			else
				chars[i] = new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance * charWidthModifier)
			endif
		Next
		For Local charNum:Int = 0 Until ExtraChars.length
			n = imgFont.CharToGlyph( ExtraChars[charNum] )
			If n < 0 or n > glyphCount then Continue
			glyph = imgFont.LoadGlyph(n)
			If not glyph then continue
			resizeChars(ExtraChars[charNum])
			'chars.insert(ExtraChars[charNum] , new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance) )
			if fixedCharWidth > 0
				chars[ExtraChars[charNum]] = new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w ,glyph._h, fixedCharWidth)
			else
				chars[ExtraChars[charNum]] = new TBitmapFontChar.Init(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance * charWidthModifier)
			endif
		Next
	End Method


	Method resizeChars(index:int)
		if index >= chars.length then
			chars = chars[.. index + 1 + chars.length/3]
		end if
	end method


	Method resizeCharsSprites(index:int)
		if index >= charsSprites.length then
			charsSprites = charsSprites[.. index + 1 + charsSprites.length/3]
		end if
	end method


	'create a charmap-atlas with information where to optimally store
	'each char
	Method CreateCharmap:TSpriteAtlas(spaceBetweenChars:int=0)
		local charmap:TSpriteAtlas = TSpriteAtlas.Create(64,64)
		local bitmapFontChar:TBitmapFontChar
		'for local _charKey:TIntKey = eachin chars.keys()
		for Local charKey:int = 0 until chars.length
			'local charKey:Int = _charKey.Value
			'bitmapFontChar = TBitmapFontChar(chars.ValueForKey(charKey))
			bitmapFontChar = chars[charKey]
			if not bitmapFontChar then continue
			charmap.AddElement(charKey, int(bitmapFontChar.area.GetW()+spaceBetweenChars), int(bitmapFontChar.area.GetH()+spaceBetweenChars) ) 'add box of char and package atlas
		Next
		return charmap
	End Method


	'create an image containing all chars
	'the charmap-atlas contains information where to store each character
	Method CreateCharmapImage(charmap:TSpriteAtlas)
		local pix:TPixmap = CreatePixmap(charmap.w,charmap.h, _pixmapFormat) ; pix.ClearPixels(0)
		'loop through atlas boxes and add chars
		For local _charKey:String = eachin charmap.elements.Keys()
			local rect:TRectangle = TRectangle(charmap.elements.ValueForKey(_charKey))
			Local charKey:Int = _charKey.ToInt()
			'skip missing data
			if (charKey > chars.length) or (not chars[charKey]) then continue

			local bm:TBitmapFontChar = chars[charKey]
			if not bm.img then continue

			'draw char image on charmap
			'local charPix:TPixmap = LockImage(TBitmapFontChar(chars.ValueForKey(charKey)).img)
			local charPix:TPixmap = LockImage(bm.img)
			'make sure the pixmaps are 8bit alpha-format
'			If charPix.format <> 2 Then charPix.convert(PF_A8)
			DrawImageOnImage(charPix, pix, int(rect.GetX()), int(rect.GetY()))
			'UnlockImage(TBitmapFontChar(chars.ValueForKey(charKey)).img)
			UnlockImage(bm.img)
			' es fehlt noch charWidth - extraTyp?

			resizeCharsSprites(charKey)
			charsSprites[charKey] = new TSprite.Init(spriteSet, charKey, rect, null, 0)
		Next
		'set image to sprite pack
		if IsSmooth()
			spriteSet.image = LoadImage(pix)
		else
			'non smooth fonts should disable any filtering (eg. in virtual resolution scaling)
			spriteSet.image = LoadImage(pix, 0)
		endif
	End Method


	Method IsBold:Int()
		return (FStyle & BOLDFONT)
	End Method

	Method IsSmooth:Int()
		return (FStyle & SMOOTHFONT)
	End Method


	'Returns whether this font has a visible ellipsis char ("…")
	Method HasEllipsis:int()
		if _hasEllipsis = -1 then _hasEllipsis = GetWidth(chr(8230))
		return _hasEllipsis
	End Method


	Method GetEllipsis:string()
		if hasEllipsis() then return chr(8230)
		return "..."
	End Method


	Method GetMaxCharHeight:int(includeBelowBaseLine:int=True)
		if includeBelowBaseLine
			if _maxCharHeight = 0 then _maxCharHeight = getHeight("gQ'_") 'including "()" adds too much to the font height
			return _maxCharHeight
		else
			if _maxCharHeightAboveBaseline = 0 then _maxCharHeightAboveBaseline = getHeight("abCDE")
			return _maxCharHeightAboveBaseline
		endif
	End Method


	Method GetWidth:Float(text:String)
		return draw(text,0,0,null,0).getX()
	End Method


	Method GetHeight:Float(text:String)
		return draw(text,0,0,null,0).getY()
	End Method


	Method GetBlockHeight:Float(text:String, w:Float, h:Float, fixedLineHeight:int = -1)
		return drawBlock(text, 0,0,w,h, null, null, 0, 0).GetY()
	End Method


	Method GetBlockWidth:Float(text:String, w:Float, h:Float, fixedLineHeight:int = -1)
		return drawBlock(text, 0,0,w,h, null, null, 0, 0).GetX()
	End Method


	Method GetBlockDimension:TVec2D(text:String, w:Float, h:Float, fixedLineHeight:int = -1)
		return drawBlock(text, 0,0,w,h, null, null, 0, 0, 1.0, True, False, fixedLineHeight)
	End Method


	'render to target pixmap/image/screen
	Function SetRenderTarget:int(target:object=null)
		'render to screen
		if not target
			drawToPixmap = null
			return TRUE
		endif

		if TImage(target)
			drawToPixmap = LockImage(TImage(target))
		elseif TPixmap(target)
			drawToPixmap = TPixmap(target)
		endif
	End Function


	'splits a given text into an array of lines
	'splitting is done on "spaces", "-"
	'or in the middle of a word if "nicelyTruncateLastLine" is "FALSE"
	Method TextToMultiLine:string[](text:string, w:float, h:float, lineHeight:float, nicelyTruncateLastLine:int=TRUE)
		Local fittingChars:int	= 0
		Local processedChars:Int= 0
		Local paragraphs:string[]	= text.replace(chr(13), "~n").split("~n")
		'the lines to output at the end
		Local lines:string[]= null
		'how many space is left to draw?
		local heightLeft:float	= h
		'are we limited in height?
		local limitHeight:int = (heightLeft > 0)

		'for each line/paragraph
		For Local i:Int= 0 Until paragraphs.length
			'skip paragraphs if no space was left
			if limitHeight and heightLeft < lineHeight then continue

			local line:string = paragraphs[i]

			'process each line - and if needed add a line break
			repeat
				'the part of the line which has to get processed at that moment
				local linePartial:string = line
				local breakPosition:int = line.length
				'whether to skip the next char of a new line
				local skipNextChar:int	= FALSE


				'as long as the part of the line does not fit into
				'the given width, we have to search for linebreakers
				while (w>0 and self.getWidth(linePartial) > w) and linePartial.length >0
					'whether we found a break position by a rule
					local FoundBreakPosition:int = FALSE
					local spaces:int = 0

					'search for "nice" linebreak:
					'- if not on last line
					'- if enforced to do so ("nicelyTruncateLastLine")
					if i < (paragraphs.length-1) or nicelyTruncateLastLine
						'search for the "most right" position of a
						'linebreak
						'no need to check for the last char (no break then ;-)
						For local charPos:int = 0 until linePartial.length -1
							'special line break rules (spaces, -, ...)
							If linePartial[charPos] = Asc(" ")
								'use first space in a row ("  ")
								if spaces = 0
									breakPosition = charPos+1
									FoundBreakPosition=TRUE
									'if it is a " "-space, we have to skip it
									skipNextChar = TRUE 'aka delete the " "
								endif
								spaces :+ 1

							elseif linePartial[charPos] = Asc("-")
								breakPosition = charPos+1
								FoundBreakPosition=TRUE

								skipNextChar = FALSE

								spaces = 0
							else
								spaces = 0
							endif
						Next
						'remove spaces at end
						if spaces > 0
							linePartial  = linePartial[.. linePartial.length - spaces]
						endif
					endif

					'if no line break rule hit, use a "cut" in the
					'middle of a word
					if not FoundBreakPosition then breakPosition = Max(0, linePartial.length-1 -1)

					'cut off the part AFTER the breakposition
					linePartial = linePartial[..breakPosition]
				wend
				'add that line to the lines to draw
				lines :+ [linePartial]

				heightLeft :- lineHeight


				'strip the processed part from the original line
				line = line[linePartial.length..]

			'	if skipNextChar then line = line[Min(1, line.length)..]
			'until no text left, or no space left for another line
			until line.length = 0  or (limitHeight and heightLeft < lineHeight)

			'if the height was not enough - add a "..."
			if line.length > 0
				'get the line BEFORE
				local currentLine:string = lines[lines.length-1]
				'check whether we have to subtract some chars for the "..."
				local ellipsisChar:string = GetEllipsis()
				if (w>0 and getWidth(currentLine + ellipsisChar) > w)
					currentLine = currentLine[.. currentLine.length-3] + ellipsisChar
				else
					currentLine = currentLine[.. currentLine.length] + ellipsisChar
				endif
				lines[lines.length-1] = currentLine
			endif
		Next

		return lines
	End Method


	'draws the text lines in a given block according to given alignment.
	'@nicelyTruncateLastLine:      try to shorten a word with "..."
	'                              or just truncate?
	'@centerSingleLineOnBaseline:  if only 1 line is given, is center
	'                              calculated using baseline (no "y,g,p,...")
	Method drawLinesBlock:TVec2D(lines:String[], x:Float, y:Float, w:Float, h:Float, alignment:TVec2D=null, color:TColor=null, style:int=0, doDraw:int = 1, special:float=1.0, nicelyTruncateLastLine:int=TRUE, centerSingleLineOnBaseline:int=False, fixedLineHeight:int = -1)
		'use special chars (instead of text) for same height on all lines
		Local alignedX:float = 0.0
		Local lineMaxWidth:Float = 0
		local lineWidth:Float = 0
		Local lineHeight:float = getMaxCharHeight()
		if fixedLineHeight > 0 then lineHeight = fixedLineHeight

		'first height was calculated using all characters, but we now
		'know if we could center using baseline only (only available
		'when there is only 1 line to draw)
		if fixedLineHeight <= 0
			if lines.length = 1 and centerSingleLineOnBaseline
				lineHeight = getMaxCharHeight(False)
				'lineHeight = 0.25 * lineHeight + 0.75 * getMaxCharHeight(False)
				'lineHeight :+ 1 'a bit of influence of "below baseline" chars
			endif
		endif

		local blockHeight:Float = lineHeight * lines.length
		if fixedLineHeight <= 0
			if lines.length > 1
				'add the lineHeightModifier for all lines but the first or
				'single one
				blockHeight :+ lineHeight * (lineHeightModifier-1.0)
			endif
		endif

		'move along y according alignment
		'-> aligned top: no change
		'-> aligned bottom: move down by unused space so last line ends at Y + h
		'-> aligned inbetween: move accordingly
		if alignment
			'empty space = height - (..)
			'-> alignTop = add 0 of that space
			'-> alignBottom = add 100% of that space
			if alignment.GetY() <> ALIGN_TOP and h > 0
				y :+ alignment.GetY() * (h - blockHeight)
			endif
		endif


		'backup current setting
		local fontStyle:TBitmapFontStyle = new TBitmapFontStyle.Push(FName, FSize, FStyle, color)

		local startY:Float = y
		For local i:int = 0 until lines.length
			lineWidth = getWidth(lines[i])
			lineMaxWidth = Max(lineMaxwidth, lineWidth)

			'only align when drawing
			If doDraw
				if alignment and alignment.GetX() <> ALIGN_LEFT and w > 0
					alignedX = x + alignment.GetX() * (w - lineWidth)
				else
					alignedX = x
				endif
			EndIf
			local p:TVec2D = __drawStyled( lines[i], alignedX, y, color, style, doDraw, special, fontStyle)

			if fixedLineHeight <= 0
				y :+ Min(_maxCharHeight, Max(lineHeight, p.y))
				'add extra spacing _between_ lines
				If lines.length > 1 and i < lines.length-1
					y :+ lineHeight * (lineHeightModifier-1.0)
				Endif
			else
				y :+ fixedLineHeight
			endif
		Next

		return new TVec2D.Init(lineMaxWidth, y - startY)
	End Method


	'draws the text in a given block according to given alignment.
	'@nicelyTruncateLastLine:      try to shorten a word with "..."
	'                              or just truncate?
	'@centerSingleLineOnBaseline:  if only 1 line is given, is center
	'                              calculated using baseline (no "y,g,p,...")
	Method drawBlock:TVec2D(text:String, x:Float, y:Float, w:Float, h:Float, alignment:TVec2D=null, color:TColor=null, style:int=0, doDraw:int = 1, special:float=1.0, nicelyTruncateLastLine:int=TRUE, centerSingleLineOnBaseline:int=False, fixedLineHeight:Int = -1)
		Local lineHeight:float = getMaxCharHeight()
		Local lines:string[] = TextToMultiLine(text, w, h, lineHeight, nicelyTruncateLastLine)

		return drawLinesBlock(lines, x, y, w, h, alignment, color, style, doDraw, special, nicelyTruncateLastLine, centerSingleLineOnBaseline, fixedLineHeight)
	End Method


	Method drawWithBG:TVec2D(value:String, x:Int, y:Int, bgAlpha:Float = 0.3, bgCol:Int = 0, style:int=0)
		Local OldAlpha:Float = GetAlpha()
		Local color:TColor = new TColor.Get()
		local dimension:TVec2D = drawStyled(value,0,0, null, style,0)
		SetAlpha bgAlpha
		SetColor bgCol, bgCol, bgCol
		DrawRect(x, y, dimension.GetX(), dimension.GetY())
		color.setRGBA()

		'backup current setting
		local fontStyle:TBitmapFontStyle = new TBitMapFontStyle.Push( FName, FSize, FStyle, color )

		local vec:TVec2D = __drawStyled(value, x, y, color, style, true, , fontStyle)

		'restore backup
		'style.Reset()

		return vec
	End Method


	'can adjust used font or color
	Method ProcessCommand:int(command:string, payload:string, fontStyle:TBitMapFontStyle)
		if command = "color" and not fontStyle.ignoreColorTag
			local colors:string[] = payload.split(",")
			local color:TColor
			if colors.length >= 3
				color = new TColor
				color.r = int(colors[0])
				color.g = int(colors[1])
				color.b = int(colors[2])
				if colors.length >= 4
					color.a = int(colors[3]) / 255.0
				else
					color.a = 1.0
				endif
			else
				if not fontStyle.GetColor()
					color = TColor.clWhite.Copy()
				else
					color = fontStyle.GetColor().Copy()
				endif
			endif

			'backup current setting
			fontStyle.PushColor( color )
		endif
		if command = "/color" and not fontStyle.ignoreColorTag
			'local color:TColor =
			fontStyle.PopColor()
		endif

		if command = "b" then fontStyle.PushFontStyle( BOLDFONT )
		if command = "/b" then fontStyle.PopFontStyle( BOLDFONT )

		if command = "i" then fontStyle.PushFontStyle( ITALICFONT )
		if command = "/i" then fontStyle.PopFontStyle( ITALICFONT )

		'adjust line height if another font is selected
		if fontStyle.GetFont() <> self and fontStyle.GetFont()
			fontStyle.styleDisplaceY = getMaxCharHeight() - fontStyle.GetFont().getMaxCharHeight()
		else
			'reset displace
			fontStyle.styleDisplaceY = 0
		endif
	End Method


	Method draw:TVec2D(text:String,x:Float,y:Float, color:TColor=null, doDraw:int=TRUE)
		'backup current setting
		local fontStyle:TBitmapFontStyle = new TBitmapFontStyle.Push(FName, FSize, FStyle, color)

		local vec:TVec2D = __draw(text, x, y, color, doDraw, fontStyle)

		'restore backup
		'TBitmapFontStyle.Reset()

		return vec
	End Method


	Method drawStyled:TVec2D(text:String,x:Float,y:Float, color:TColor=null, style:int=0, doDraw:int=1, special:float=-1.0)
		'backup current setting
		local fontStyle:TBitmapFontStyle = new TBitmapFontStyle.Push(FName, FSize, FStyle, color)
		'backup current setting
		'TBitmapFontStyle.Push(FName, FSize, FStyle, color)

		local vec:TVec2D = __drawStyled(text, x, y, color, style, doDraw, special, fontStyle)

		'restore backup
		'fontStyle.Reset()

		return vec
	End Method


	Method __drawStyled:TVec2D(text:String,x:Float,y:Float, color:TColor=null, style:int=0, doDraw:int=1, special:float=-1.0, fontStyle:TBitmapFontStyle)
		if special = -1 then special = 1 '100%

		if drawAtFixedPoints
			x = int(x)
			y = int(y)
		endif

		local height:float = 0.0
		local width:float = 0.0

		'backup old color
		local oldColor:TColor
		if doDraw then oldColor = new TColor.Get()

		'emboss
		if style = STYLE_EMBOSS
			height:+ 1
			if doDraw
				SetAlpha float(special * 0.5 * oldColor.a)
				fontStyle.ignoreColorTag :+ 1
				__draw(text, x, y+1, embossColor, doDraw, fontStyle)
				fontStyle.ignoreColorTag :- 1
			endif
		'shadow
		else if style = STYLE_SHADOW
			height:+ 1
			width:+1
			if doDraw
				SetAlpha special*0.5*oldColor.a
				fontStyle.ignoreColorTag :+ 1
				__draw(text, x+1,y+1, shadowColor, doDraw, fontStyle)
				fontStyle.ignoreColorTag :- 1
			endif
		'glow
		else if style = STYLE_GLOW
			if doDraw
				fontStyle.ignoreColorTag :+ 1
				shadowColor.SetRGB()
				SetAlpha special*0.25*oldColor.a
				__draw(text, x-2,y, ,doDraw, fontStyle)
				__draw(text, x+2,y, ,doDraw, fontStyle)
				__draw(text, x,y-2, ,doDraw, fontStyle)
				__draw(text, x,y+2, ,doDraw, fontStyle)
				SetAlpha special*0.5*oldColor.a
				__draw(text, x+1,y+1, ,doDraw, fontStyle)
				__draw(text, x-1,y-1, ,doDraw, fontStyle)
				fontStyle.ignoreColorTag :- 1
			endif
		endif

		if oldColor then SetAlpha oldColor.a
		local result:TVec2D = __draw(text,x,y, color, doDraw, fontStyle)

		if oldColor then oldColor.SetRGBA()
		return result
	End Method


	Method __draw:TVec2D(text:String,x:Float,y:Float, color:TColor=null, doDraw:int=TRUE, fontStyle:TBitmapFontStyle)
		local width:float = 0.0
		local height:float = 0.0
		local textLines:string[]	= text.replace(chr(13), "~n").split("~n")
		local currentLine:int = 0
		local oldColor:TColor
		if doDraw
			oldColor = new TColor.Get()
			if not color
				color = oldColor.copy()
			else
				'take screen alpha into consideration
				'create a copy to not modify the original
				color = color.copy()
				color.a :* oldColor.a
			endif
			'black text is default
'			if not color then color = TColor.Create(0,0,0)
			if color then color.SetRGBA()
		endif
		'set the lineHeight before the "for-loop" so it has a set
		'value if a line "in the middle" just consists of spaces/nothing
		'-> allows double-linebreaks

		'control vars
		local controlChar:int = asc("|")
		local controlCharEscape:int = asc("\")
		local controlCharStarted:int = FALSE
		local currentControlCommandPayloadSeparator:string = "="
		local currentControlCommand:string = ""
		local currentControlCommandPayload:string = ""

		local lineHeight:int = 0
		local charCode:int
		local displayCharCode:int 'if char is not found
		local charBefore:int
		local rotation:int = GetRotation()
		local sprite:TSprite
		local styleDisplaceY:int = 0
		'cache
		local font:TBitmapFont = fontStyle.GetFont()
'		if not color then color = new TColor.Get()

		'store current color
		fontStyle.PushColor(color)

		For text:string = eachin textLines

			'except first line (maybe only one line) - add extra spacing
			'between lines
			if currentLine > 0 then height:+ ceil( lineHeight* (font.lineHeightModifier-1.0) )

			currentLine:+1

			local lineWidth:Float = 0

			For Local i:Int = 0 Until text.length
				charCode = int(text[i])

				'reload with utf8?
				If charCode > 256 and MaxSigns = 256 and glyphCount > 256 and extraChars.find(chr(charCode)) = -1
					LoadExtendedCharacters()
				EndIf


				'check for controls
				if controlCharStarted
					'receiving command
					if charCode <> controlChar
						currentControlCommand:+ chr(charCode)
					'receive stopper
					else
						controlCharStarted = FALSE
						local commandData:string[] = currentControlCommand.split(currentControlCommandPayloadSeparator)
						currentControlCommand = commandData[0]
						if commandData.length>1 then currentControlCommandPayload = commandData[1]

							ProcessCommand(currentControlCommand, currentControlCommandPayload, fontStyle)
							if fontStyle.GetColor()
								color = fontStyle.GetColor().Copy()
								if doDraw
									color.SetRGBA()
								endif
							endif
						'cache font to speed up processing
						font = fontStyle.GetFont()

						'reset
						currentControlCommand = ""
						currentControlCommandPayload = ""
					endif
					'skip char
					continue
				endif

				'someone wants style the font
				if charCode = controlChar and charBefore <> controlCharEscape
					controlCharStarted = 1 - controlCharStarted
					'skip char
					charBefore = charCode
					continue
				endif
				'skip drawing the escape char if we are escaping the
				'command char
				if charCode = controlCharEscape and i < text.length-1 and text[i+1] = controlChar
					charBefore = charCode
					continue
				endif

				Local bm:TBitmapFontChar
				' = TBitmapFontChar( font.chars.ValueForKey(charCode) )
				if charCode < font.chars.length then
					bm = font.chars[charCode]
				end if
				if bm
					displayCharCode = charCode
				else
					displayCharCode = Asc("?")
					if charCode < font.chars.length then
						bm = font.chars[charCode]
					end if
					'bm = TBitmapFontChar( font.chars.ValueForKey(displayCharCode) )
				endif
				if bm
					Local tx:Float = bm.area.GetX() * gfx.tform_ix + bm.area.GetY() * gfx.tform_iy
					Local ty:Float = bm.area.GetX() * gfx.tform_jx + bm.area.GetY() * gfx.tform_jy
					'drawable ? (> 32)
					if text[i] > 32
						lineHeight = MAX(lineHeight, bm.area.GetH())
						if doDraw
							if displayCharCode < font.charsSprites.length
								sprite = font.charsSprites[displayCharCode]
							else
								sprite = null
							end if
							'sprite = TSprite(font.charsSprites.ValueForKey(displayCharCode))
							if sprite
								if drawToPixmap
									sprite.DrawOnImage(drawToPixmap, int(pixmapOrigin.x + x+lineWidth+tx), int(pixmapOrigin.y + y+height+ty+styleDisplaceY - font.displaceY), -1, null, color)
								else
									sprite.Draw(int(x+lineWidth+tx), int(y+height+ty+styleDisplaceY - font.displaceY))
								endif
							endif
						endif
					endif
					if rotation = -90
						height:- MIN(lineHeight, bm.area.GetW())
					elseif rotation = 90
						height:+ MIN(lineHeight, bm.area.GetW())
					elseif rotation = 180
						lineWidth :- bm.charWidth * gfx.tform_ix
					else
						if text[i] = 32 'space
							lineWidth :+ bm.charWidth * gfx.tform_ix * spaceWidthModifier
						elseif text[i] = KEY_TAB
							lineWidth =  (int(lineWidth / tabWidth)+1) * tabWidth
						else
							lineWidth :+ bm.charWidth * gfx.tform_ix
						endif
					endif
				elseif text[i] = KEY_TAB
					lineWidth =  (int(lineWidth / tabWidth)+1) * tabWidth
				EndIf

				charBefore = charCode
			Next
			width = max(width, lineWidth)
			height :+ lineHeight
			'add extra spacing _between_ lines
			'not done when only 1 line available or on last line
			if currentLine < textLines.length
				height:+ ceil( lineHeight* (font.lineHeightModifier-1.0) )
			endif
		Next

		'restore color
		if doDraw then oldColor.SetRGBA()

		fontStyle.PopColor()

		return new TVec2D.Init(width, height)
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


Type TBitmapFontStyle
	Field fontNames:TList = CreateList()
	Field fontSizes:TList = CreateList()
	'one counter for each style (italicfont, boldfont)
	Field fontStyles:int[2]
	Field colors:TList = CreateList()
	Field ignoreColorTag:int = False
	Field ignoreStyleTags:int = False
	Global styleDisplaceY:int = 0

	Method Reset()
		fontNames.Clear()
		fontSizes.Clear()
		fontStyles[0] = 0
		fontStyles[1] = 0
		colors.Clear()
		styleDisplaceY = 0
	End Method


	Method Push:TBitMapFontStyle(fName:string, fSize:int, fStyle:int, color:TColor)
		PushFontName(fName)
		PushFontSize(fSize)
		PushFontStyle(fStyle)
		PushColor(color)
		return self
	End Method


	Method PushColor( color:TColor )
		'reuse the last one
		if not color then color = GetColor()

		colors.AddLast( color )
	End Method


	Method PopColor:TColor()
		return TColor(colors.RemoveLast())
	End Method


	Method PushFontStyle( style:int )
		if (style & BOLDFONT) > 0 then fontStyles[0] :+ 1
		if (style & ITALICFONT) > 0 then fontStyles[1] :+ 1
	End Method


	Method PopFontStyle:int( style:int )
		if (style & BOLDFONT) > 0 then fontStyles[0] = Max(0, fontStyles[0] - 1)
		if (style & ITALICFONT) > 0 then fontStyles[1] = Max(0, fontStyles[1] - 1)

		Return GetFontStyle()
	End Method


	Method PushFontSize( size:int )
		if not size then size = GetFontSize()

		fontSizes.AddLast( string(size) )
	End Method


	Method PopFontSize:int()
		return int(string(fontSizes.RemoveLast()))
	End Method


	Method PushFontName( name:string)
		fontNames.AddLast( name )
	End Method


	Method PopFontname:string()
		return string(fontNames.RemoveLast())
	End Method


	Method GetColor:TColor()
		local col:TColor = TColor(colors.Last())
		if not col then col = new TColor.Get()
		return col
	End Method


	Method GetFontName:string()
		return string(fontNames.Last())
	End Method


	Method GetFontSize:int()
		return int(string(fontSizes.Last()))
	End Method


	Method GetFontStyle:int()
		local style:int = 0
		if fontStyles[0] > 0 then style :| BOLDFONT
		if fontStyles[1] > 0 then style :| ITALICFONT
		return style
	End Method


	Method GetFont:TBitmapfont()
		return GetBitmapFontManager().Get(GetFontName(), GetFontSize(), GetFontStyle())
	End Method
End Type




' - max2d/max2d.bmx -> loadimagefont
' - max2d/imagefont.bmx TImageFont.Load ->
Function LoadTrueTypeFont:TImageFont( url:Object,size:int,style:int )
	Local src:TFont = TFreeTypeFont.Load( String( url ), size, style )
	If Not src Return null

	Local font:TImageFont=New TImageFont
	font._src_font=src
	font._glyphs=New TImageGlyph[src.CountGlyphs()]
	If style & SMOOTHFONT then font._imageFlags=FILTEREDIMAGE|MIPMAPPEDIMAGE

	Return font
End Function
