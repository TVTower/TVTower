'Sprite-Classes
superstrict

Import BRL.Max2D
Import BRL.Random
Import brl.FreeTypeFont
'Import "basefunctions.bmx"
Import "basefunctions_image.bmx"
Import "Dig/base.util.event.bmx"
Import "basefunctions_asset.bmx"

rem
CONST VALIGN_TOP:float		= 1
CONST VALIGN_CENTER:float	= 0.5
CONST VALIGN_BOTTOM:float	= 0
CONST ALIGN_LEFT:float		= 1.0
CONST ALIGN_CENTER:float	= 0.5
CONST ALIGN_RIGHT:float		= 0
endrem


CONST ALIGN_LEFT:FLOAT		= 0
CONST ALIGN_CENTER:FLOAT	= 0.5
CONST ALIGN_RIGHT:FLOAT		= 1.0
CONST ALIGN_TOP:FLOAT		= 0
CONST ALIGN_BOTTOM:FLOAT	= 1.0
Global ALIGN_TOP_LEFT:TPoint = new TPoint


Type TRenderManager
	field list:TList = CreateList()

	Function Create:TRenderManager()
		local obj:TRenderManager = new TRenderManager
		return obj
	End Function

	Method Render()
		For local obj:TRenderable = eachin self.list
			'obj.Draw()
		Next
	end Method
End Type


Type TRenderable extends TAsset
	Field children:TList	= CreateList()
	Field area:TRectangle	= new TRectangle
	'the zIndex is LOCAL (when parented), higher values are on TOP
	Field zIndex:int		= 0


	Method Update:int(deltaTime:float=1.0)
		For local child:TRenderable = eachin children
			child.Update(deltaTime)
		Next
	End Method


	'implement it customized in each type
	rem
	Method Draw:int(tweenValue:float=1.0, minZIndex:int=-1, maxZIndex:int=-1)
		For local child:TRenderable = eachin children
			if minZIndex >=0 and child.zIndex < minZIndex then continue
			if maxZIndex >=0 and child.zIndex > minZIndex then continue
			child.Draw(tweenValue)
		Next
	End Method
	endrem


	Method AddChild:int(child:TRenderable)
		self.children.AddLast(child)
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




Type TSpriteAtlas
	field elements:TMap = CreateMap()
	field w:int, h:int
	field packer:TSpritePacker = New TSpritePacker

	Function Create:TSpriteAtlas(w:int, h:int)
		local obj:TSpriteAtlas = new TSpriteAtlas
		obj.w = w
		obj.h = h
		obj.packer.setRect(0,0,w,h)
		return obj
	End Function

	Method AddElement(name:string, w:int, h:int)
		Local freeArea:TSpritePacker = null

		while freeArea = null
			freeArea = self.packer.pack(w,h)
			if freeArea = Null
				self.IncreaseSize()
				self.Repack()
			endif
		Wend
		Self.elements.Insert(name, new TRectangle.Init(freeArea.x, freeArea.y, w, h))
	End Method

	Method Repack()
		local newElements:TMap = CopyMap(self.elements)
		self.packer = new TSpritePacker
		self.packer.setRect(0,0,self.w,self.h)

		ClearMap(self.elements)

		for local name:string = eachin newElements.Keys()
			local rect:TRectangle = TRectangle(newElements.ValueForKey(name))
			self.AddElement(name, rect.GetW(), rect.GetH())
		next
	End Method

	Method Draw(x:int=0, y:int=0)
		setColor 255,100,100
		DrawRect(x,y,self.w, self.h)
		setColor 50,100,200
		For local rect:TRectangle = eachin self.elements.Values()
			DrawRect(rect.GetX()+1, rect.GetY()+1, rect.GetW()-2, rect.GetH()-2)
		Next
	End Method

	Method IncreaseSize(w:int = 0, h:int = 0)
		if w = 0 AND h = 0
			if self.h < self.w then self.h = self.nextPow2(self.h) else self.w = self.nextPow2(self.w)
		else
			if w<>0 then self.w = w
			if h<>0 then self.h = h
		endif
		self.packer.setRect(0, 0, self.w, self.h)
	End Method

	Method nextPow2:int(currentValue:int=0)
		local newValue:int = 1
		while newValue <= currentValue
			newValue :* 2
		wend
		'print "nextPow2: got:"+currentValue + " new:"+newValue
		return newValue
	EndMethod
End Type




Type TSpritePacker
	Field childNode1:TSpritePacker
	Field childNode2:TSpritePacker

	Field x:Int,y:Int,w:Int,h:Int
	Field occupied:Int = False

	Method toString:String()
		Return "rect : "+x+" "+y+" "+w+" "+h
	End Method

	Method setRect(x:Int,y:Int,w:Int,h:Int)
		Self.x = x
		Self.y = y
		Self.w = w
		Self.h = h
	End Method

	' recursively split area until it fits the desired size
	Method pack:TSpritePacker(width:Int,height:Int)

		 'If we are a leaf node
		If (childNode1 = Null And childNode2 = Null)

			If occupied Or width > w Or height > h then Return Null

			If width = w And height = h
				occupied = True
				Return Self
			Else
				splitArea(width,height)
				Return childNode1.pack(width,height)
			EndIf

		Else
			' Try inserting into first child
			Local newNode:TSpritePacker = childNode1.pack(width,height)
			If newNode <> Null then Return newNode

			'no room, insert into second
			Return childNode2.pack(width,height)
		EndIf
	End Method

	Method splitArea(width:Int,height:Int)
		childNode1 = New TSpritePacker
        childNode2 = New TSpritePacker

        ' decide which way to split
        Local dw:Int = w - width
        Local dh:Int = h - height

        ' split vertically
        If dw > dh
            childNode1.setRect(x,y,width,h)
            childNode2.setRect(x+width,y,dw,h)
		Else ' split horizontally
            childNode1.setRect(x,y,w,height)
            childNode2.setRect(x,y+height,w,dh)
		EndIf

	End Method

End Type




' -------------------------------------
Type TImageCache
	field lifetime:int = 1000 '1000ms ?
	field image:TImage

	Method Setup:int(image:TImage, lifetime:int = 1000)
		self.image = image
		self.lifetime = Millisecs() + lifetime
	End Method

	Method isAlive:int()
		if self.lifetime < Millisecs() then return false
		return true
	End Method

	Method GetImage:TImage()
		return self.image
	End Method
End Type




Type TGW_BitmapFontChar
	Field area:TRectangle
	Field charWidth:float
	Field img:TImage

	Function Create:TGW_BitmapFontChar(img:TImage, x:int,y:int,w:Int, h:int, charWidth:float)
		Local obj:TGW_BitmapFontChar = New TGW_BitmapFontChar
		obj.img = img
		obj.area = new TRectangle.Init(x,y,w,h)
		obj.charWidth = charWidth
		Return obj
	End Function
End Type


Type TGW_BitmapFont
	Field FName:string	= ""		'identifier
	Field FFile:string	= ""		'source path
	Field FSize:int		= 0			'size of this font
	Field FStyle:int	= 0			'style used in this font
	Field FImageFont:TImageFont		'the original imagefont

	Field chars:TMap		= CreateMap()
	Field charsSprites:Tmap	=CreateMap()
	field spriteSet		:TGW_SpritePack
	Field MaxSigns		:Int=256
	Field ExtraChars	:string="€…"
	Field gfx			:TMax2dGraphics
	Field uniqueID		:string =""
	Field displaceY		:float=100.0
	Field lineHeightModifier:float = 0.2	'modifier * lineheight gets added at the end
	Field drawAtFixedPoints:int = true		'whether to use ints or floats for coords
	Field _charsEffectFunc:TGW_BitmapFontChar(font:TGW_BitmapFont, charKey:string, char:TGW_BitmapFontChar, config:TData)[]
	Field _charsEffectFuncConfig:TData[]
	Field _pixmapFormat:int = PF_A8			'by default this is 8bit alpha only
	Field _maxCharHeight:int = 0
	Field _hasEllipsis:int = -1

	global drawToPixmap:TPixmap = null
	global ImageCaches:TMap = CreateMap()
	global eventRegistered:int = 0

	Function Create:TGW_BitmapFont(name:String, url:String, size:Int, style:Int)
		Local obj:TGW_BitmapFont = New TGW_BitmapFont
		obj.FName		= name
		obj.FFile		= url
		obj.FSize		= size
		obj.FStyle		= style
		obj.uniqueID	= name+"_"+url+"_"+size+"_"+style
		obj.gfx			= tmax2dgraphics.Current()
		obj.FImageFont	= LoadTrueTypeFont(url, size, style)
		If not obj.FImageFont
			Throw ("TGW_BitmapFont.Create: font ~q"+url+"~q not found.")
			Return Null 'font not found
		endif
		'create spriteset
		obj.spriteSet	= TGW_SpritePack.Create(null, obj.uniqueID+"_charmap")

		'generate a charmap containing packed rectangles where to store images
		obj.InitFont()

		'listen to App-timer
		EventManager.registerListener( "App.onUpdate", 	TEventListenerRunFunction.Create(TGW_BitmapFont.onUpdateCaches) )

		Return obj
	End Function


	Method SetCharsEffectFunction(position:int, _func:TGW_BitmapFontChar(font:TGW_BitmapFont, charKey:string, char:TGW_BitmapFontChar, config:TData), config:TData=null)
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
			for local charKey:string = eachin chars.keys()
				local char:TGW_BitmapFontChar = TGW_BitmapFontChar(chars.ValueForKey(charKey))

				'manipulate char
				local _func:TGW_BitmapFontChar(font:TGW_BitmapFont, charKey:string, char:TGW_BitmapFontChar, config:TData)
				local _config:TData
				for local i:int = 0 to _charsEffectFunc.length-1
					_func = _charsEffectFunc[i]
					_config = _charsEffectFuncConfig[i]
					if not _config then _config = config
					char = _func(self, charKey, char, _config)
				Next
				'overwrite char
				chars.Insert(charKey, char)
			Next
		endif

		'else do nothing by default
	End Method


	'generate a charmap containing packed rectangles where to store images
	Method InitFont(config:TData=null )
		'1. load chars
		LoadCharsFromImgFont()
		'2. Process the characters (add shadow, gradients, ...)
		ApplyCharsEffect(config)
		'3. store them into a packed (optimized) charmap
		'   -> creates a 8bit alpha'd image (grayscale with alpha ...)
		CreateCharmapImage( CreateCharmap(1) )
	End Method


	'load glyphs of an imagefont as TGW_BitmapFontChar into a char-TMap
	Method LoadCharsFromImgFont(imgFont:TImageFont=null)
		if imgFont = null then imgFont = self.FImageFont
		Local glyph:TImageGlyph
		local n:int
		For Local i:Int = 0 Until MaxSigns
			n = imgFont.CharToGlyph(i)
			If n < 0 then Continue
			glyph = imgFont.LoadGlyph(n)
			If not glyph then continue

			'base displacement calculated with A-Z (space between TOPLEFT of 'ABCDE' and TOPLEFT of 'acen'...)
			if i >= 65 AND i < 95 then displaceY = Min(displaceY, glyph._y)
			chars.insert(string(i), TGW_BitmapFontChar.Create(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance))
		Next
		For Local charNum:Int = 0 Until ExtraChars.length
			n = imgFont.CharToGlyph( ExtraChars[charNum] )
			glyph = imgFont.LoadGlyph(n)
			If not glyph then continue

			chars.insert(string(ExtraChars[charNum]) , TGW_BitmapFontChar.Create(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance) )
		Next
	End Method


	'create a charmap-atlas with information where to optimally store
	'each char
	Method CreateCharmap:TSpriteAtlas(spaceBetweenChars:int=0)
		local charmap:TSpriteAtlas = TSpriteAtlas.Create(64,64)
		local bitmapFontChar:TGW_BitmapFontChar
		for local charKey:string = eachin chars.keys()
			bitmapFontChar = TGW_BitmapFontChar(chars.ValueForKey(charKey))
			if not bitmapFontChar then continue
			charmap.AddElement(charKey, bitmapFontChar.area.GetW()+spaceBetweenChars,bitmapFontChar.area.GetH()+spaceBetweenChars ) 'add box of char and package atlas
		Next
		return charmap
	End Method


	'create an image containing all chars
	'the charmap-atlas contains information where to store each character
	Method CreateCharmapImage(charmap:TSpriteAtlas)
		local pix:TPixmap = CreatePixmap(charmap.w,charmap.h, self._pixmapFormat) ; pix.ClearPixels(0)
		'loop through atlas boxes and add chars
		For local charKey:string = eachin charmap.elements.Keys()
			local rect:TRectangle = TRectangle(charmap.elements.ValueForKey(charKey))
			'skip missing data
			if not chars.ValueForKey(charKey) then continue
			if not TGW_BitmapFontChar(chars.ValueForKey(charKey)).img then continue

			'draw char image on charmap
			'print "adding "+charKey + " = "+chr(int(charKey))
			local charPix:TPixmap = LockImage(TGW_BitmapFontChar(chars.ValueForKey(charKey)).img)
'			If charPix.format <> 2 Then charPix.convert(PF_A8) 'make sure the pixmaps are 8bit alpha-format
			DrawImageOnImage(charPix, pix, rect.GetX(), rect.GetY())
			UnlockImage(TGW_BitmapFontChar(chars.ValueForKey(charKey)).img)
			' es fehlt noch charWidth - extraTyp?

			charsSprites.insert(charKey, new TGW_Sprite.Create(spriteSet, charKey, rect, null, 0, int(charKey)))
		Next
		'set image to sprite pack
		spriteSet.image = LoadImage(pix)
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


	Method getMaxCharHeight:int()
		if _maxCharHeight = 0 then _maxCharHeight = getHeight("gQ'_")
		return _maxCharHeight
	End Method


	Method getWidth:Float(text:String)
		return draw(text,0,0,null,0).getX()
	End Method

	Method getHeight:Float(text:String)
		return draw(text,0,0,null,0).getY()
	End Method

	Method getBlockHeight:Float(text:String, w:Float, h:Float)
		return drawBlock(text, 0,0,w,h, null, null, 0, 0).getY()
	End Method


	'render to target pixmap/image/screen
	Function setRenderTarget:int(target:object=null)
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



	Method TextToMultiLine:string[](text:string, w:float, h:float, lineHeight:float, nicelyTruncateLastLine:int=TRUE)
		Local fittingChars:int	= 0
		Local processedChars:Int= 0
		Local paragraphs:string[]	= text.replace(chr(13), "~n").split("~n")
		'the lines to output at the end
		Local lines:string[]= null
		'how many space is left to draw?
		local heightLeft:float	= h
		'are we limited in height?
		local limitHeight:int = (heightLeft <> -1)

		'for each line/paragraph
		For Local i:Int= 0 To paragraphs.length-1
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

				'copy the line to do processing and shortening
				linePartial = line

				'as long as the part of the line does not fit into
				'the given width, we have to search for linebreakers
				while self.getWidth(linePartial) >= w and linePartial.length >0
					'whether we found a break position by a rule
					local FoundBreakPosition:int = FALSE

					'search for "nice" linebreak:
					'- if not on last line
					'- if enforced to do so ("nicelyTruncateLastLine")
					if i < (paragraphs.length-1) or nicelyTruncateLastLine
						'search for the "most right" position of a linebreak
						For local charPos:int = 0 To linePartial.length-1
							'special line break rules (spaces, -, ...)
							If linePartial[charPos] = Asc(" ")
								breakPosition = charPos
								FoundBreakPosition=TRUE
							endif
							If linePartial[charPos] = Asc("-")
								breakPosition = charPos
								FoundBreakPosition=TRUE
							endif
						Next
					endif

					'if no line break rule hit, use a "cut" in the middle of a word
					if not FoundBreakPosition then breakPosition = Max(0, linePartial.length-1 -1)

					'if it is a " "-space, we have to skip it
					if linePartial[breakPosition] = ASC(" ")
						skipNextChar = TRUE 'aka delete the " "
					endif


					'cut off the part AFTER the breakposition
					linePartial = linePartial[..breakPosition]
				wend
				'add that line to the lines to draw
				lines = lines[..lines.length +1]
				lines[lines.length-1] = linePartial

				heightLeft :- lineHeight


				'strip the processed part from the original line
				line = line[linePartial.length..]
				if skipNextChar then line = line[Min(1, line.length)..]
			'until no text left, or no space left for another line
			until line.length = 0  or (limitHeight and heightLeft < lineHeight)

			'if the height was not enough - add a "..."
			if line.length > 0
				'get the line BEFORE
				local currentLine:string = lines[lines.length-1]
				'check whether we have to subtract some chars for the "..."
				local ellipsisChar:string = GetEllipsis()
				if getWidth(currentLine + ellipsisChar) > w
					currentLine = currentLine[.. currentLine.length-3] + ellipsisChar
				else
					currentLine = currentLine[.. currentLine.length] + ellipsisChar
				endif
				lines[lines.length-1] = currentLine
			endif
		Next

		return lines
	End Method


	Method drawBlock:TPoint(text:String, x:Float, y:Float, w:Float, h:Float, alignment:TPoint=null, color:TColor=null, style:int=0, doDraw:int = 1, special:float=1.0, nicelyTruncateLastLine:int=TRUE)
		'use special chars (instead of text) for same height on all lines
		Local alignedX:float	= 0.0
		Local lineHeight:float	= getMaxCharHeight()
		Local lines:string[] = TextToMultiLine(text, w, h, lineHeight, nicelyTruncateLastLine)

		local blockHeight:Float = lineHeight * lines.length
		if lines.length > 1
			'add the lineHeightModifier for all lines but the first or single one
			blockHeight :+ lineHeight * lineHeightModifier
		endif

		'move along y according alignment
		'-> aligned top: no change
		'-> aligned bottom: move down by unused space so last line ends at Y + h
		'-> aligned inbetween: move accordingly
		if alignment
			'empty space = height - (..)
			'so alignTop = add 0 of that space, alignBottom = add 100% of that space
			if alignment.GetY() <> ALIGN_TOP
				y :+ alignment.GetY() * (h - blockHeight)
			endif
		endif

		local startY:Float = y
		For local i:int = 0 to lines.length-1
			'only draw if wanted
			If doDraw
				if alignment and alignment.GetX() <> ALIGN_LEFT
					alignedX = x + alignment.GetX() * (w - getWidth(lines[i]))
				else
					alignedX = x
				endif
			Endif
			local p:TPoint = drawStyled( lines[i], alignedX, y, color, style, doDraw,special)

			y :+ Max(lineHeight, p.y)
			'add extra spacing _between_ lines
			If lines.length > 1 and i < lines.length-1
				y :+ lineHeight * lineHeightModifier
			Endif
		Next

		return new TPoint.Init(w, y - startY)
	End Method


	Method drawStyled:TPoint(text:String,x:Float,y:Float, color:TColor=null, style:int=0, doDraw:int=1, special:float=-1.0)
		if self.drawAtFixedPoints
			x = int(x)
			y = int(y)
		endif

		local height:float = 0.0
		local width:float = 0.0

		'backup old color
		local oldColor:TColor
		if doDraw and color then oldColor = new TColor.Get()

		'emboss
		if style = 1
			height:+ 1
			if doDraw
				if special <> -1.0
					SetAlpha float(special * oldColor.a)
				else
					SetAlpha float(0.75 * oldColor.a)
				endif
				self.draw(text, x, y+1, TColor.clWhite)
			endif
		'shadow
		else if style = 2
			height:+ 1
			width:+1
			if doDraw
				if special <> -1.0 then SetAlpha special*oldColor.a else SetAlpha 0.5*oldColor.a
				self.draw(text, x+1,y+1, TColor.clBlack)
			endif
		'glow
		else if style = 3
			if doDraw
				SetColor 0,0,0
				if special <> -1.0 then SetAlpha 0.5*oldColor.a else SetAlpha 0.25*oldColor.a
				self.draw(text, x-2,y)
				self.draw(text, x+2,y)
				self.draw(text, x,y-2)
				self.draw(text, x,y+2)
				if special <> -1.0 then SetAlpha special*oldColor.a else SetAlpha 0.5*oldColor.a
				self.draw(text, x+1,y+1)
				self.draw(text, x-1,y-1)
			endif
		endif

		if oldColor then SetAlpha oldColor.a
		local result:TPoint = self.draw(text,x,y, color, doDraw)

		if oldColor then oldColor.SetRGBA()
		return result
	End Method


	Method drawWithBG:TPoint(value:String, x:Int, y:Int, bgAlpha:Float = 0.3, bgCol:Int = 0, style:int=0)
		Local OldAlpha:Float = GetAlpha()
		Local color:TColor = new TColor.Get()
		local dimension:TPoint = self.drawStyled(value,0,0, null, style,0)
		SetAlpha bgAlpha
		SetColor bgCol, bgCol, bgCol
		DrawRect(x, y, dimension.GetX(), dimension.GetY())
		color.setRGBA()
		return self.drawStyled(value, x, y, color, style)
	End Method


	'can adjust used font or color
	Method ProcessCommand:int(command:string, payload:string, font:TGW_BitmapFont var , color:TColor var , colorOriginal:TColor, styleDisplaceY:int var)
		if color
			if command = "color"
				local colors:string[] = payload.split(",")
				if colors.length >= 3
					color.r = int(colors[0])
					color.g = int(colors[1])
					color.b = int(colors[2])
					if colors.length >= 4
						color.a = int(colors[3]) / 255.0
					else
						color.a = 1.0
					endif
				endif
				color.SetRGBA()
			endif
			if command = "/color"
				color.r = colorOriginal.r
				color.g = colorOriginal.g
				color.b = colorOriginal.b
				color.a = colorOriginal.a
				color.SetRGBA()
			endif
		endif

		if command = "b" then font = TGW_FontManager.GetInstance().GetFont(self.FName, self.FSize, BOLDFONT)
		if command = "/b" then font = self

		if command = "bi" then font = TGW_FontManager.GetInstance().GetFont(self.FName, self.FSize, BOLDFONT | ITALICFONT)
		if command = "/bi" then font = self

		if command = "i" then font = TGW_FontManager.GetInstance().GetFont(self.FName, self.FSize, ITALICFONT)
		if command = "/i" then font = self

		'adjust line height if another font is selected
		if font <> self
			styleDisplaceY = (getMaxCharHeight() - font.getMaxCharHeight())
		else
			'reset displace
			styleDisplaceY = 0
		endif
		if not font then font = self
	End Method


	Method draw:TPoint(text:String,x:Float,y:Float, color:TColor=null, doDraw:int=TRUE)
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
				'when drawing to a pixmap, take screen alpha into consideration
				if drawToPixmap
					'create a copy to not modify the original
					color = color.copy()
					color.a :* oldColor.a
				endif
			endif
			'black text is default
'			if not color then color = TColor.Create(0,0,0)
			if color then color.SetRGB()

		endif
		'set the lineHeight before the "for-loop" so it has a set
		'value if a line "in the middle" just consists of spaces or nothing
		'-> allows double-linebreaks

		'control vars
		local controlChar:int = asc("|")
		local controlCharEscape:int = asc("\")
		local controlCharStarted:int = FALSE
		local currentControlCommandPayloadSeparator:string = "="
		local currentControlCommand:string = ""
		local currentControlCommandPayload:string = ""

		local lineHeight:int = 0
		local char:string = ""
		local charBefore:int
		local font:TGW_BitmapFont = self 'by default this font is responsible
		local colorOriginal:TColor = null
		local rotation:int = GetRotation()
		local sprite:TGW_Sprite
		local styleDisplaceY:int = 0
		For text:string = eachin textLines
			currentLine:+1

			local lineWidth:int = 0

			For Local i:Int = 0 Until text.length
				char = text[i]


				'check for controls
				if controlCharStarted
					'receiving command
					if char <> controlChar
						currentControlCommand:+ chr(int(char))
					'receive stopper
					else
						controlCharStarted = FALSE
						local commandData:string[] = currentControlCommand.split(currentControlCommandPayloadSeparator)
						currentControlCommand = commandData[0]
						if commandData.length>1 then currentControlCommandPayload = commandData[1]

						if color and not colorOriginal then colorOriginal = color.copy()
						ProcessCommand(currentControlCommand, currentControlCommandPayload, font, color, colorOriginal, styleDisplaceY)
						'reset
						currentControlCommand = ""
						currentControlCommandPayload = ""
					endif
					'skip char
					continue
				endif

				'someone wants style the font
				if char = controlChar and charBefore <> controlCharEscape
					controlCharStarted = 1 - controlCharStarted
					'skip char
					charBefore = int(char)
					continue
				endif
				'skip drawing the escape char if we are escaping the command char
				if char = controlCharEscape and i < text.length-1 and text[i+1] = controlChar
					charBefore = int(char)
					continue
				endif

				Local bm:TGW_BitmapFontChar = TGW_BitmapFontChar( font.chars.ValueForKey(char) )
				if bm <> null
					Local tx:Float = bm.area.GetX() * gfx.tform_ix + bm.area.GetY() * gfx.tform_iy
					Local ty:Float = bm.area.GetX() * gfx.tform_jx + bm.area.GetY() * gfx.tform_jy
					'drawable ? (> 32)
					if text[i] > 32
						lineHeight = MAX(lineHeight, bm.area.GetH())
						if doDraw
							sprite = TGW_Sprite(font.charsSprites.ValueForKey(char))
							if sprite
								if drawToPixmap
									sprite.DrawOnImage(drawToPixmap, x+lineWidth+tx,y+height+ty+styleDisplaceY - font.displaceY, color)
								else
									sprite.Draw(x+lineWidth+tx,y+height+ty+styleDisplaceY - font.displaceY)
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
						lineWidth :+ bm.charWidth * gfx.tform_ix
					endif
				EndIf

				charBefore = int(char)
			Next
			width = max(width, lineWidth)
			'add extra spacing _between_ lines
			'not done when only 1 line available or on last line
			if currentLine < textLines.length
				height :+ ceil( lineHeight * (1+font.lineHeightModifier) )
			else
				height :+ lineHeight
			endif
		Next

		'restore color
		if doDraw then oldColor.SetRGB()

		return new TPoint.Init(width, height)
	End Method

rem
	Method drawfixed(text:String,x:Float,y:Float)
		local color:TColor = new TColor.Get()

		For Local i:Int = 0 Until text.length
			Local bm:TGW_BitmapFontChar = TGW_BitmapFontChar(self.chars.ValueForKey(string(text[i]-32)))
			if bm <> null
				Local tx:Float = bm.area.GetX() * gfx.tform_ix + bm.area.GetY() * gfx.tform_iy
				Local ty:Float = bm.area.GetX() * gfx.tform_jx + bm.area.GetY() * gfx.tform_jy
				local sprite:TGW_Sprite = TGW_Sprite(self.charsSprites.ValueForKey(string(text[i]-32)))
				if sprite <> null
					if self.drawToPixmap
						sprite.DrawOnPixmap(self.drawToPixmap, x+tx,y+ty, color)
					else
						sprite.Draw(x+tx,y+ty)
					endif
				endif
				x :+ bm.charWidth
			endif
		Next
	End Method
endrem


	Function onUpdateCaches(triggerEvent:TEventBase)
		For local key:string = eachin TGW_BitmapFont.ImageCaches.Keys()
			local cache:TImageCache = TImageCache(TGW_BitmapFont.ImageCaches.ValueForKey(key))
			if cache and not cache.isAlive() then TGW_BitmapFont.ImageCaches.Remove(key)
		Next
	End Function

End Type



CONST SHADOWFONT:INT = 256
CONST GRADIENTFONT:INT = 512

Type TGW_FontManager
	Field DefaultFont:TGW_BitmapFont	= null
	Field baseFont:TGW_BitmapFont		= null
	Field baseFontBold:TGW_BitmapFont	= null
	Field baseFontItalic:TGW_BitmapFont	= null
	Field baseFontSmall:TGW_BitmapFont	= null
	Field List:TList					= CreateList()
	global instance:TGW_FontManager


	Function GetInstance:TGW_FontManager()
		if not instance then instance = new TGW_FontManager
		return instance
	End Function


	Method GetFont:TGW_BitmapFont(name:String, size:Int=-1, style:Int=-1)
		name = lower(name)
		style :| SMOOTHFONT

		'create a default font if not done yet
		if not DefaultFont
			'add a defaultFont (uses default BlitzMax font if none was set before)
			DefaultFont = TGW_BitmapFont.Create("Default", "", 12, SMOOTHFONT)
		EndIf

		'no details given: return default font
		If name = "default" And size = -1 And style = -1 Then Return DefaultFont
		'no size given: use default font size
		If size = -1 Then size = DefaultFont.FSize
		'no style given: use default font style
		If style = -1 Then style = DefaultFont.FStyle 'Else style = style | SMOOTHFONT

		'if the font wasn't found, use the defaultFont-fontfile to load this style
		Local defaultFontFile:String = DefaultFont.FFile
		For Local Font:TGW_BitmapFont = EachIn Self.List
			If Font.FName = name And Font.FStyle = style Then defaultFontFile = Font.FFile
			If Font.FName = name And Font.FSize = size And Font.FStyle = style Then Return Font
		Next
		Return AddFont(name, defaultFontFile, size, style)
	End Method


	Method CopyFont:TGW_BitmapFont(sourceName:string, copyName:string, size:int=-1, style:int=-1)
		local sourceFont:TGW_BitmapFont = GetFont(sourceName, size, style)
		Local newFont:TGW_BitmapFont = TGW_BitmapFont.Create(sourceFont.fName, sourceFont.fFile, sourceFont.fSize, sourceFont.fStyle)
		Self.List.AddLast(newFont)
		return newFont
	End Method

	Method AddFont:TGW_BitmapFont(name:String, file:String, size:Int, style:Int=0)
		name = lower(name)
		style :| SMOOTHFONT

		If size = -1 Then size = DefaultFont.FSize
		If style = -1 Then style = DefaultFont.FStyle
		If file = "" Then file = DefaultFont.FFile

		Local Font:TGW_BitmapFont = TGW_BitmapFont.Create(name, file, size, style)
		Self.List.AddLast(Font)

		'set default fonts if not done yet
		if self.DefaultFont = null then self.DefaultFont = Font
		if self.baseFont = null then self.baseFont = Font

		Return Font
	End Method
End Type




Type TGW_SpritePack extends TRenderable
	Field image:TImage
	Field sprites:TGW_Sprite[]
'	Field sprites:TList = CreateList()
	Field LastSpriteID:Int = 0


	Function Create:TGW_SpritePack(image:TImage, name:string)
		Local Obj:TGW_SpritePack = New TGW_SpritePack
		Obj.image = image
		'asset
		Obj.setName(name)
		Obj.setUrl("NONE")
		Obj.setType("SPRITEPACK")

		Return Obj
	End Function


	'returns the sprite defined by "spriteName"
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSprite:TGW_Sprite(spriteName:String = "")
		spriteName = lower(spriteName)
		For Local i:Int = 0 To sprites.length - 1
			'skip missing or with wrong names
			If not sprites[i] or lower(sprites[i].spritename) <> spriteName then continue

			Return sprites[i]
		Next
		print "GetSprite: "+spritename+" not found in Pack "+self.GetName()
		Return sprites[0]
	End Method


	'returns the sprite with "spriteID"
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSpriteByID:TGW_Sprite(spriteID:Int = 0)
		For Local i:Int = 0 To sprites.length - 1
			'skip missing or with  wrong ids
			If not sprites[i] or sprites[i].spriteID <> spriteID Then continue

			Return sprites[i]
		Next
		print "GetSpriteByID: "+spriteID+" not found in Pack "+self.GetName()
		Return sprites[0]
	End Method


	Method GetNextSpriteID:int(spriteID:int=-1)
		if spriteID < 0
			LastSpriteID:+1
			spriteID = LastSpriteID
		endif
		return spriteID
	End Method


	Method AddSprite:int(sprite:TGW_Sprite, spriteID:int=-1)
		sprite.spriteID = GetNextSpriteID(spriteID)
		sprite.parent = self

		sprites = sprites[..sprites.length+1]
		sprites[sprites.length-1] = sprite
		'sprites.AddLast(sprite)
		return true
	End Method


	'draws the whole spritesheet
	Method Draw(tweenValue:float=1.0)
		DrawImage(self.image, self.area.GetX(), self.area.GetY())
	End Method


	Method CopySprite(spriteNameSrc:String, spriteNameDest:String, color:TColor)
		Local tmpSpriteDest:TGW_Sprite = Self.GetSprite(spriteNameDest)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(tmpSpriteDest.area.GetX(), tmpSpriteDest.area.GetY(), tmpSpriteDest.area.GetW(), tmpSpriteDest.area.GetH()).ClearPixels(0)
			DrawImageOnImage(ColorizeImageCopy(Self.GetSprite(spriteNameSrc).GetImage(), color), tmppix, tmpSpriteDest.area.GetX(), tmpSpriteDest.area.GetY())
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
	End Method


	Method AddSpriteCopy:TGW_Sprite(spriteNameSrc:String, spriteNameDest:String, area:TRectangle, offset:TRectangle=null, animcount:int = 0, color:TColor)
		local spriteCopy:TGW_Sprite = new TGW_Sprite.Create(self, spriteNameDest, area, offset, animcount)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(spriteCopy.area.GetX(), spriteCopy.area.GetY(), spriteCopy.area.GetW(), spriteCopy.area.GetH()).ClearPixels(0)
			DrawImageOnImage(ColorizeImageCopy(GetSprite(spriteNameSrc).GetImage(), color), tmppix, spriteCopy.area.GetX(), spriteCopy.area.GetY())
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
		'add the copy
		self.addSprite(spriteCopy)

		return spriteCopy
	End Method
rem
	Method CopyImageOnSpritePackImage(src:object, dest:object = null, destX:float, destY:float)
		local tmppix:TPixmap = null
		local imgWidth:int = 0
		local imgHeight:int = 0
		local srcPix:TPixmap = null
		if TImage(src)<> null then srcPix = LockImage(TImage(src), 0) else srcPix = TPixmap(src)
		if srcPix = null
			print "CopyImageOnSpritePackImage : srcPix is null"
		else
			if dest = null then tmppix = LockImage(self.image,0) else tmppix = TPixmap(dest)
				'resize needed ? position+dimension extends original size
				if tmppix.width < (srcPix.width + destX) OR ImageHeight(self.image) < (srcPix.height + destY)
					ResizePixmap(tmppix, srcPix.width + destX, srcPix.height + destY)
					print "CopyImageOnSpritePackImage: resize"
				endif

				If srcPix.format <> PF_RGBA8888 Then srcPix.convert(PF_RGBA8888) 'make sure the pixmaps are 32 bit format
				DrawPixmapOnPixmap(srcPix, tmppix, destX, destY)
			if dest = null then UnlockImage(Self.image, 0)
		endif
		if TImage(src)<> null then UnlockImage(TImage(src))
		GCCollect() '<- FIX!
	End Method
endrem
End Type


Type TGW_Sprite extends TRenderable
	Field spriteName:String = ""
	Field offset:TRectangle = new TRectangle
	Field frameW:Int
	Field frameH:Int
	Field animCount:Int
	Field SpriteID:Int = -1
	Field parent:TGW_SpritePack
	Field _pix:TPixmap = null


	Method Create:TGW_Sprite(spritepack:TGW_SpritePack=null, spritename:String, area:TRectangle, offset:TRectangle, animcount:Int = 0, SpriteID:Int = -1, spriteDimension:TPoint=null)
		self.spritename	= spritename
		self.parent		= spritepack
		self.area		= area.copy()
		if offset then self.offset = offset.copy()
		self.framew		= area.GetW()
		self.frameh		= area.GetH()
		self.SpriteID	= SpriteID
		self.animcount	= animcount
		If animcount > 0
			self.framew = ceil(area.GetW() / animcount)
			self.frameh = area.GetH()
		End If
		If spriteDimension and spriteDimension.x<>0 and spriteDimension.y<>0
			self.framew = spriteDimension.GetX()
			self.frameh = spriteDimension.GetY()
		End If

		'asset
		self.setName(spritename)
		self.setUrl("NONE")
		self.setType("SPRITE")
		Return self
	End Method


	Method CreateFromImage:TGW_Sprite(img:Timage, spriteName:string, spriteID:int =-1)
		'create new spritepack
		local spritepack:TGW_SpritePack = TGW_SpritePack.Create(img, spriteName+"_pack")
		self.Create(spritepack, spriteName, new TRectangle.Init(0, 0, img.width, img.height), null, Len(img.frames), spriteID)
		spritepack.addSprite(self)
		return self
	End Method


	Function LoadFromAsset:TGW_Sprite(asset:object)
		local obj:TGW_Sprite = TGW_Sprite(asset)

		local spritepack:TGW_Spritepack = null
		if obj.parent = null
			if obj._flags & MASKEDIMAGE then SetMaskColor(255,0,255)
			local _img:TImage = LoadImage(obj._url, obj._flags)

			'load img to find out celldimensions
			if obj.animcount > 0 AND (obj.framew = 0 OR obj.frameh = 0)
				obj.framew = ImageWidth(_img) / obj.animcount
				obj.frameh = ImageHeight(_img)
			endif
			spritepack = TGW_Spritepack.Create(_img, obj.getName()+"_pack")
			if _img = null then print "image null : "+obj.getName()
		else
			spritepack = obj.parent
		endif
		if obj._flags & MASKEDIMAGE then SetMaskColor(0,0,0)

		return new TGW_Sprite.Create(spritepack, obj.getName(), new TRectangle.Init(0,0, ImageWidth(spritepack.image), ImageHeight(spritepack.image)), null, obj.animcount, -1, new TPoint.Init(obj.framew, obj.frameh))
	End Function


	'returns the image of this sprite (reference, no copy)
	'if the frame is 0+, only this frame is returned
	'if includeBorder is TRUE, then an potential ninePatchBorder will be
	'included
	Method GetImage:TImage(frame:int=-1, includeBorder:int=FALSE)
		'if a frame is requested, just return it (no need for "animated" check)
		if frame >=0 then return GetFrameImage(frame)

		Local DestPixmap:TPixmap = LockImage(parent.image, 0, False, True).Window(area.GetX(), area.GetY(), area.GetW(), area.GetH())

		UnlockImage(parent.image)
		GCCollect() '<- FIX!

		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	Method GetFrameImage:TImage(frame:Int=0)
		Local DestPixmap:TPixmap = LockImage(parent.image, 0, False, True).Window(area.GetX() + frame * framew, area.GetY(), framew, area.GetH())
		GCCollect() '<- FIX!
		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	'return the pixmap of the sprite' image (reference, no copy)
	Method GetPixmap:TPixmap()
		Local DestPixmap:TPixmap = LockImage(parent.image, 0, False, True).Window(area.GetX(), area.GetY(), area.GetW(), area.GetH())
		'UnlockImage(self.parent.image)
		'GCCollect() '<- FIX!
		return DestPixmap
	End Method


	'creates a REAL copy (no reference) of an image
	Method GetImageCopy:TImage(loadAnimated:int = 1)
		SetMaskColor(255,0,255)
		If self.animcount >1 And loadAnimated
			Return LoadAnimImage(self.GetPixmap().copy(), self.framew, self.frameh, 0, self.animcount)
		Else
			Return LoadImage(self.GetPixmap().copy())
		EndIf
	End Method


	Method GetColorizedImage:TImage(color:TColor, frame:int=-1)
		return ColorizeImageCopy(self.GetImage(frame), color)
	End Method


	'removes the part of the sprite packs image occupied by the sprite
	Method ClearImageData:int()
		Local tmppix:TPixmap = LockImage(parent.image, 0)
		tmppix.Window(area.GetX(), area.GetY(), area.GetW(), area.GetH()).ClearPixels(0)
		GCCollect() '<- FIX!
	End Method


	Method GetWidth:int(includeOffset:int=TRUE)
		if includeOffset
			return area.GetW() - offset.GetLeft() - offset.GetRight()
		else
			return area.GetW()
		endif
	End Method


	Method GetHeight:int(includeOffset:int=TRUE)
		if includeOffset
			return area.GetH() + offset.GetTop() + offset.GetBottom()
		else
			return area.GetH()
		endif
	End Method


	Method GetFramePos:TPoint(frame:int=-1)
		If frame < 0 then return new TPoint.Init(0,0)

		Local MaxFramesInCol:Int	= Ceil(area.GetW() / framew)
		Local framerow:Int			= Ceil(frame / Max(1,MaxFramesInCol))
		Local framecol:Int 			= frame - (framerow * MaxFramesInCol)
		return new TPoint.Init( framecol * self.framew, framerow * self.frameh )
	End Method


	'let spritePack colorize the sprite
	Method Colorize(color:TColor)
		'store backup (we have to clean the image data
		'              before pasting colorized output)
		local newImg:TImage = ColorizeImageCopy(GetImage(), color)
		'remove old image part
		ClearImageData()
		'draw now colorized image on the parent image
		DrawImageOnImage(newImg, parent.image, area.GetX(), area.GetY())
	End Method


	Method PixelIsOpaque:int(x:int, y:int)
		if x < 0 or y < 0 or x > self.framew or y > self.frameh then print "out of: "+x+", "+y;return 0

		if not self._pix
			self._pix = LockImage(self.GetImage())
			'UnlockImage(self.parent.image) 'unlockimage does nothing in blitzmax (1.48)
		endif

		return ARGB_Alpha(ReadPixel(self._pix, x,y))
	End Method


	'draw the sprite onto a given image or pixmap
	Method DrawOnImage(imageOrPixmap:object, x:int, y:int, modifyColor:TColor=null)
		DrawImageOnImage(getPixmap(), imageOrPixmap, x + offset.GetLeft(), y + offset.GetTop(), modifyColor)
	End Method


	Method DrawResized(target:TRectangle, source:TRectangle, frame:int=-1)
		'needed as "target" is a reference (changes original variable)
		local targetCopy:TRectangle = target.Copy()

		'we got a frame request - try to find it
		'calculate WHERE the frame is positioned in spritepack
		if frame >= 0 and self.framew > 0 and self.frameh > 0
			Local MaxFramesInCol:Int	= floor(area.GetW() / framew)
			local frameInRow:int		= floor(frame / MaxFramesInCol)	'0based
			local frameInCol:int		= frame mod MaxFramesInCol		'0based
			'move the source rect accordingly
			source.position.SetXY(frameInCol*frameW, frameinRow*frameH)

			'if no source dimension was given - use frame dimension
			if source.GetW() <= 0 then source.dimension.setX(self.framew)
			if source.GetH() <= 0 then source.dimension.setY(self.frameh)
		else
			'if no source dimension was given - use image dimension
			if source.GetW() <= 0 then source.dimension.setX(area.GetW())
			if source.GetH() <= 0 then source.dimension.setY(area.GetH())
		endif
		'receive source rect so it stays within the sprite's limits
		source.dimension.SetX(Min(area.GetW(), source.GetW()))
		source.dimension.SetY(Min(area.GetH(), source.GetH()))

		'if no target dimension was given - use source dimension
		if targetCopy.GetW() <= 0 then targetCopy.dimension.SetX(source.GetW())
		if targetCopy.GetH() <= 0 then targetCopy.dimension.SetY(source.GetH())


		'take care of offsets
		if offset and (offset.position.x<>0 or offset.position.y<>0 or offset.dimension.x<>0 or offset.dimension.y<>0)
			'top and left border also modify position to draw
			'starting at the top border - so include that offset
			if source.GetY() = 0
				targetCopy.position.MoveY(-offset.GetTop())
				targetCopy.dimension.MoveY(offset.GetTop())
				source.dimension.MoveY(offset.GetTop())
			else
				source.position.MoveY(offset.GetTop())
			endif
			if source.GetX() = 0
				targetCopy.position.MoveX(-offset.GetLeft())
				targetCopy.dimension.MoveX(offset.GetLeft())
				source.dimension.MoveX(offset.GetLeft())
			else
				source.position.MoveX(offset.GetLeft())
			endif

			'hitting bottom border - draw bottom offset
			if (source.GetY() + source.GetH()) >= (area.GetH() - offset.GetBottom())
				source.dimension.MoveY(offset.GetBottom())
				targetCopy.dimension.MoveY(offset.GetBottom())
			endif
			'hitting right border - draw right offset
'			if (source.GetX() + source.GetW()) >= (area.GetW() - offset.GetRight())
'				source.dimension.MoveX(offset.GetRight())
'			endif
		endif

		DrawSubImageRect(parent.image, targetCopy.GetX(), targetCopy.GetY(), targetCopy.GetW(), targetCopy.GetH(), area.GetX() + source.GetX(), area.GetY() + source.GetY(), source.GetW(), source.GetH())
	End Method


	Method DrawClipped(target:TPoint, source:TRectangle, frame:int=-1)
		DrawResized(new TRectangle.Init(target.GetX(),target.GetY()), source, frame)
	End Method


	Method TileDrawHorizontal(x:float, y:float, w:float, scale:float=1.0, theframe:int=-1)
		local widthLeft:float	= w
		local currentX:float	= x
		local framePos:TPoint = self.getFramePos(theframe)

		while widthLeft > 0
			local widthPart:float = Min(self.framew, widthLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.image, currentX + offset.GetLeft(), y + offset.GetTop(), widthPart, self.area.GetH(), self.area.GetX() + framePos.x, self.area.GetY() + framePos.y, widthPart, self.frameh, 0 )
			currentX :+ widthPart * scale
			widthLeft :- widthPart * scale
		Wend
	End Method


	Method TileDrawVertical(x:float, y:float, h:float, scale:float=1.0)
		local heightLeft:float = h
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float = Min(self.area.GetH(), heightLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.image, x + offset.GetLeft(), currentY + offset.GetTop(), self.area.GetW(), ceil(heightPart), self.area.GetX(), self.area.GetY(), self.area.GetW(), ceil(heightPart) )
			currentY :+ floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method TileDraw(x:Float, y:Float, w:Int, h:Int, scale:float=1.0)
		local heightLeft:float = floor(h)
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float	= Min(self.area.GetH(), heightLeft) 'draw part of sprite or whole ?
			local widthLeft:float	= w
			local currentX:float	= x
			while widthLeft > 0
				local widthPart:float = Min(self.area.GetW(), widthLeft) 'draw part of sprite or whole ?
				DrawSubImageRect( parent.image, currentX + offset.GetLeft(), currentY + offset.GetTop(), ceil(widthPart), ceil(heightPart), self.area.GetX(), self.area.GetY(), ceil(widthPart), ceil(heightPart) )
				currentX	:+ floor(widthPart * scale)
				widthLeft	:- (widthPart * scale)
			Wend
			currentY	:+ floor(heightPart * scale)
			heightLeft	:- (heightPart * scale)
		Wend
	End Method


	Method Update(deltaTime:float=1.0)
	End Method


	Method Draw(x:Float, y:Float, frame:Int=-1, alignment:TPoint=null, scale:float=1.0)
		x:- offset.GetLeft()*scale
		y:- offset.GetTop()*scale

		rem
			ALIGNMENT IS POSITION OF HANDLE !!

			   TOPLEFT        TOPRIGHT
			           .----.
			           |    |
			           '----'
			BOTTOMLEFT        BOTTOMRIGHT
		endrem


		if not alignment then alignment = ALIGN_TOP_LEFT

		If frame = -1 Or framew = 0
			DrawSubImageRect(parent.image, x - alignment.GetX()*area.GetW()*scale , y - alignment.GetY()*area.GetH()*scale, area.GetW(), area.GetH(), area.GetX(), area.GetY(), area.GetW(), area.GetH(), 0, 0, 0)
			'DrawImageArea(parent.image, x - (1.0-alignment.GetX())*area.GetW()*scale + offset.GetLeft()*scale , y - valign*area.GetH()*scale + offset.GetTop()*scale, area.GetX(), area.GetY(), area.GetW(), area.GetH(), 0)
		Else
			Local MaxFramesInCol:Int	= Ceil(area.GetW() / framew)
			Local framerow:Int			= Ceil(frame / MaxFramesInCol)
			Local framecol:Int 			= frame - (framerow * MaxFramesInCol)

			DrawSubImageRect(parent.image,..
							 x - alignment.GetX()*framew*scale,..
							 y - alignment.GetY()*frameh*scale,..
							 framew,..
							 frameh,..
							 area.GetX() + framecol * framew,..
							 area.GetY() + framerow * frameh,..
							 framew,..
							 frameh,..
							 0, 0, 0)
		EndIf
	End Method
End Type




Type TGW_NinePatchSprite extends TGW_Sprite
	Field _middle:TPoint				'size of the middle parts (width, height)
	Field _border:TRectangle			'size of TopLeft,TopRight,BottomLeft,BottomRight
	Field _contentBorder:TRectangle		'limits for displaying content
	Field _borderScale:float	= 1.0	'the scale of "non-stretchable" borders - rest will scale automatically through bigger dimensions
	CONST MARKER_WIDTH:int		= 1		'subtract this amount of pixels on each side for markers


	Method Create:TGW_NinePatchSprite(spritepack:TGW_SpritePack=null, spritename:String, area:TRectangle, offset:TRectangle, animcount:Int = 0, SpriteID:Int = -1, spriteDimension:TPoint=null)
		super.Create(spritepack, spritename, area, offset, animcount, spriteID, spriteDimension)

		'read markers in the image to get border and content sizes
		_border			= ReadMarker(0)
		_contentBorder	= ReadMarker(1)

		'middle has to consider the marker_width (content dimension marker)
		_middle = new TPoint.Init(..
					area.GetW() - (_border.GetLeft() + _border.GetRight()), ..
					area.GetH() - (_border.GetTop() + _border.GetBottom()) ..
				  )

		self.setType("NINEPATCHSPRITE")

		'TLogger.log("NinePatchSprite", spritename+" border: "+int(_border.GetLeft())+","+int(_border.GetTop())+" -> "+int(_border.GetRight())+","+int(_border.GetBottom()), LOG_DEBUG)

		return self
	End Method


	Function LoadFromAsset:TGW_NinePatchSprite(asset:object)
		local gwSprite:TGW_Sprite = TGW_Sprite.LoadFromAsset(asset)
		return new TGW_NinePatchSprite.Create(gwSprite.parent, gwSprite.getName(), gwSprite.area, null, gwSprite.animcount, -1, new TPoint.Init(gwSprite.framew, gwSprite.frameh))
	End Function


	'returns the image of this sprite (reference, no copy)
	'if the frame is 0+, only this frame is returned
	'if includeBorder is TRUE, then an potential ninePatchBorder will be
	'included
	Method GetImage:TImage(frame:int=-1, includeBorder:int=FALSE)
		'if a frame is requested, just return it (no need for "animated" check)
		if frame >=0 then return GetFrameImage(frame)

		Local DestPixmap:TPixmap
		if includeBorder
			DestPixmap = LockImage(parent.image, 0, False, True).Window(area.GetX(), area.GetY(), area.GetW(), area.GetH())
		else
			local border:TRectangle = GetBorder()
			DestPixmap = LockImage(parent.image, 0, False, True).Window(area.GetX()+ border.GetLeft(), area.GetY() + border.GetTop(), area.GetW() - border.GetLeft() - border.GetRight(), area.GetH() - border.GetTop() - border.GetBottom())
		endif

		UnlockImage(parent.image)
		GCCollect() '<- FIX!

		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	Method GetBorder:TRectangle()
		return self._border
	End Method

	Method GetContentBorder:TRectangle()
		return self._contentBorder
	End Method


	Method DrawArea(x:float, y:float, width:float=-1, height:float=-1, frame:int=-1)
		if width=-1 then width = area.GetW()
		if height=-1 then height = area.GetH()
		'minimal dimension has to be same or bigger than all 4 borders + 0.5 of the stretch portion
		width = Max(width, 0.5 + _borderScale*(_border.GetLeft()+_border.GetRight()))
		height = Max(height, 0.5 + _borderScale*(_border.GetTop()+_border.GetBottom()))

		'dimensions of the stretch-parts (the middle elements)
		'adjusted by a potential border scale
		Local stretchDestW:float = width - _borderScale*(_border.GetLeft()+_border.GetRight())
		Local stretchDestH:float = height - _borderScale*(_border.GetTop()+_border.GetBottom())

		'top
		If _border.GetLeft() then DrawResized(new TRectangle.Init(x, y, _border.GetLeft()*_borderScale, _border.GetTop()*_borderScale), new TRectangle.Init(MARKER_WIDTH, MARKER_WIDTH, _border.GetLeft(), _border.GetTop()), frame)
		DrawResized(new TRectangle.Init(x+_border.GetLeft()*_borderScale, y, stretchDestW, _border.GetTop()*_borderScale), new TRectangle.Init(_border.GetLeft(), MARKER_WIDTH, _middle.GetX(), _border.GetTop()), frame )
		If _border.GetRight() then DrawResized(new TRectangle.Init(x+stretchDestW+_border.GetLeft()*_borderScale, y, _border.GetRight()*_borderScale, _border.GetTop()*_borderScale), new TRectangle.Init(_middle.GetX()+_border.GetLeft() - MARKER_WIDTH, MARKER_WIDTH, _border.GetRight(), _border.GetTop()), frame)
		'middle
		If _border.GetLeft() Then DrawResized(new TRectangle.Init(x, y+_border.GetTop()*_borderScale, _border.GetLeft()*_borderScale, stretchDestH), new TRectangle.Init(MARKER_WIDTH, _border.GetTop(), _border.GetLeft(), _middle.GetY()), frame)
'		DrawResized(new TRectangle.Init(x+_border.GetLeft()*_borderScale, y+_border.GetTop()*_borderScale, stretchDestW, stretchDestH), new TRectangle.Init(MARKER_WIDTH+_border.GetLeft(), MARKER_WIDTH+_border.GetTop(), _middle.GetX(), _middle.GetY()), frame)
		DrawResized(new TRectangle.Init(x+_border.GetLeft()*_borderScale, y+_border.GetTop()*_borderScale, stretchDestW, stretchDestH), new TRectangle.Init(_border.GetLeft(), _border.GetTop(), _middle.GetX(), _middle.GetY()), frame)
		If _border.GetRight() Then DrawResized(new TRectangle.Init(x+stretchDestW+_border.GetLeft()*_borderScale, y+_border.GetTop()*_borderScale, _border.GetRight()*_borderScale, stretchDestH), new TRectangle.Init(_middle.GetX()+_border.GetLeft() - MARKER_WIDTH, _border.GetTop(), _border.GetRight(), _middle.GetY()), frame)
		'bottom
		If _border.GetLeft() Then DrawResized(new TRectangle.Init(x, y+stretchDestH+_border.GetTop()*_borderScale, _border.GetLeft()*_borderScale, _border.GetBottom()*_borderScale), new TRectangle.Init(MARKER_WIDTH, _middle.GetY()+_border.GetTop() - MARKER_WIDTH, _border.GetLeft(), _border.GetBottom()), frame)
		DrawResized(new TRectangle.Init(x+_border.GetLeft()*_borderScale, y+stretchDestH+_border.GetTop()*_borderScale, stretchDestW, _border.GetBottom()*_borderScale), new TRectangle.Init(_border.GetLeft(), _middle.GetY()+_border.GetTop() - MARKER_WIDTH, _middle.GetX(), _border.GetBottom()), frame)
		If _border.GetRight() Then DrawResized(new TRectangle.Init(x+stretchDestW+_border.GetLeft()*_borderScale, y+stretchDestH+_border.GetTop()*_borderScale, _border.GetRight()*_borderScale, _border.GetBottom()*_borderScale), new TRectangle.Init(_middle.GetX()+_border.GetLeft() - MARKER_WIDTH, _middle.GetY()+_border.GetTop() - MARKER_WIDTH, _border.GetRight(), _border.GetBottom()), frame)
	End Method



	'read markers out of the sprites image data
	'mode = 0: sprite borders
	'mode = 1: content borders
	Method ReadMarker:TRectangle(mode:int=0)
		if not _pix then _pix = GetPixmap()
		Local sourcepixel:Int
		local sourceW:int = _pix.width - MARKER_WIDTH
		local sourceH:int = _pix.height - MARKER_WIDTH
		local result:TRectangle = new TRectangle.Init(0,0,0,0)
		local markerRow:int=0, markerCol:int=0, skipLines:int=0

		'content is defined at the last pixmap row/col
		if mode = 1
			markerCol = sourceH
			markerRow = sourceW
			skipLines = 1
		endif

		'  °= L ====== R = °			ROW ROW ROW ROW
		'  T               T		COL
		'  |               |		COL
		'  B               B		COL
		'  °= L ====== R = °		COL


		'find left border: from 0 to first non-transparent pixel in row 0
		For Local i:Int = skipLines To sourceW-1
			if ARGB_Alpha(ReadPixel(_pix, i, markerCol)) > 0 then result.SetLeft(i - skipLines);exit
		Next
		'find right border: from left border the first non opaque pixel in row 0
		For Local i:Int = result.GetLeft()+1 To sourceW-1
			if ARGB_Alpha(ReadPixel(_pix, i, markerCol)) = 0 then result.SetRight(sourceW - i);exit
		Next
		'find top border: from 0 to first opaque pixel in col 0
		For Local i:Int = skipLines To sourceH-1
			if ARGB_Alpha(ReadPixel(_pix, markerRow, i)) > 0 then result.SetTop(i - skipLines);exit
		Next
		'find bottom border: from top border the first non opaque pixel in col 0
		For Local i:Int = Min(sourceH-1, result.GetTop()+1) To sourceH-1
			if ARGB_Alpha(ReadPixel(_pix, markerRow, i)) = 0 then result.SetBottom(sourceH - i +1);exit
		Next

		Return result
	End Method
End Type





Type TAnimation
	field repeatTimes:int		= 0		'how many times animation should repeat until finished
	field currentFrame:int		= 0		'frame of sprite/image
	field currentFramePos:int	= 0		'position in frames-array
	field frames:int[]
	field framesTime:float[]			'duration for each frame
	field paused:byte			= 0		'stay with currentFrame or cycle through frames?
	field frameTimer:float		= null
	field randomness:int		= 0


	Function Create:TAnimation(framesArray:int[][], repeatTimes:int=0, paused:int=0, randomness:int = 0)
		local obj:TAnimation = new TAnimation
		local framecount:int = len( framesArray )

		obj.frames		= obj.frames[..framecount] 'extend
		obj.framesTime	= obj.framesTime[..framecount] 'extend

		For local i:int = 0 until framecount
			obj.frames[i]		= framesArray[i][0]
			obj.framesTime[i]	= float(framesArray[i][1]) * 0.001
		Next
		obj.repeatTimes	= repeatTimes
		obj.paused		= paused
		return obj
	End Function

	Method Update:int(deltaTime:float=1.0)
		'skip update if only 1 frame is set
		'skip if paused
		If self.paused or self.frames.length <= 1 then return 0

		if self.frameTimer = null then self.ResetFrameTimer()
		self.frameTimer :- deltaTime
		if self.frameTimer <= 0.0
			local nextPos:int = self.currentFramePos + 1
			'increase current frameposition but only if frame is set
			'resets frametimer too
			self.setCurrentFramePos(nextPos)
			'print self.currentFramePos + " -> "+ self.currentFrame

			'reached end? (use nextPos as setCurrentFramePos already limits value)
			If nextPos >= len(self.frames)
				If self.repeatTimes = 0
					self.Pause()	'stop animation
				Else
					self.setCurrentFramePos( 0 )
					self.repeatTimes	:-1
				EndIf
			EndIf
		Endif
	End Method

	Method Reset()
		self.setCurrentFramePos(0)
	End Method

	Method ResetFrameTimer()
		self.frameTimer = self.framesTime[self.currentFramePos] + Rand(-self.randomness, self.randomness)
	End Method

	Method getFrameCount:int()
		return len(self.frames)
	End Method

	Method getCurrentFrame:int()
		return self.currentFrame
	End Method

	Method setCurrentFrame(frame:int)
		self.currentFrame = frame
		self.ResetFrameTimer()
	End Method

	Method getCurrentFramePos:int()
		return self.currentFramePos
	End Method

	Method setCurrentFramePos(framePos:int)
		self.currentFramePos = Max( Min(framePos, len(self.frames) - 1), 0)
		self.setCurrentFrame( self.frames[ self.currentFramePos ] )
	End Method

	Method isPaused:byte()
		return self.paused
	End Method

	Method isFinished:byte()
		return self.paused AND (self.currentFramePos >= len(self.frames)-1)
	End Method

	Method Playback()
		self.paused = 0
	End Method

	Method Pause()
		self.paused = 1
	End Method


End Type

'makes anim sprites moveable
Type TMoveableAnimSprites extends TAnimSprites {_exposeToLua="selected"}
	Field rect:TRectangle	= new TRectangle.Init(0,0,0,0) {_exposeToLua}
	Field oldPos:TPoint		= new TPoint.Init(0,0) 'for tweening
	Field vel:TPoint		= new TPoint.Init(0,0) {_exposeToLua}
	Field returnToStart:Int	= 0


	Method Create:TMoveableAnimSprites(sprite:TGW_Sprite, AnimCount:Int = 1, animTime:Int)
		super.Create(sprite, AnimCount, animTime)
		return self
	End Method


	'not able to override TAnimSprites-functions/methods
	Method SetupMoveable:TMoveableAnimSprites(x:Int, y:Int, dx:Int, dy:int = 0)
		self.rect.position.setXY(x, y)
		self.rect.dimension.setXY(sprite.framew, sprite.frameh)
		self.vel.setXY(dx,dy)
		return self
	End Method


	Method Draw(_x:float= -10000, _y:float = -10000, overwriteAnimation:string="")
		If visible
			If _x = -10000 OR _x = null Then _x = rect.position.x
			If _y = -10000 Then _y = rect.position.y
			'call AnimSprites.Draw
			super.Draw(_x,_y)
		endif
	End Method


	Method UpdateMovement(deltaTime:float)
		'backup for tweening
		self.oldPos.SetXY(rect.position.x, rect.position.y)

		self.rect.position.MoveXY( deltaTime * self.vel.x, deltaTime * self.vel.y )
	End Method


	Method Update(deltaTime:float)
		'call AnimSprites.Update
		super.Update(deltaTime)

		self.UpdateMovement(deltaTime)
	End Method
End Type




'base of animated sprites... contains timers and so on, supports reversed animations
Type TAnimSprites
	Field sprite:TGW_Sprite
	Field spriteName:string			= ""
	Field visible:Int 				= 1
	Field AnimationSets:TMap	 	= CreateMap()
	Field currentAnimation:string	= "default"

	Method Create:TAnimSprites(sprite:TGW_Sprite, AnimCount:Int = 1, animTime:Int)
		SetSprite(sprite)

		local framesArray:int[][2]
		framesArray	= framesArray[..AnimCount] 'extend
		for local i:int = 0 to AnimCount -1
			framesArray[i]		= framesArray[i][..2] 'extend to 2 fields each entry
			framesArray[i][0]	= i
			framesArray[i][1]	= animTime
		Next
		insertAnimation( "default", TAnimation.Create(framesArray,0,0) )

		Return self
	End Method


	Method SetSprite(newSprite:TGW_Sprite)
		sprite = newSprite
		spriteName = newSprite.spriteName
	End Method


	Method GetSprite:TGW_Sprite()
		return sprite
	End Method


	Method GetWidth:int()
		return sprite.framew
	End Method


	Method GetHeight:int()
		return sprite.frameh
	End Method


	'insert a TAnimation with a certain Name
	Method InsertAnimation(animationName:string, animation:TAnimation)
		AnimationSets.insert(lower(animationName), animation)
		if not AnimationSets.contains("default") then setCurrentAnimation(animationName, 0)
	End Method

	'Set a new Animation
	'If it is a different animation name, the Animation will get reset (start from begin)
	Method setCurrentAnimation(animationName:string, startAnimation:int = 1)
		animationName = lower(animationName)
		local reset:int = 1 - (currentAnimation = animationName)
		currentAnimation = animationName
		if reset then getCurrentAnimation().Reset()
		if startAnimation then getCurrentAnimation().Playback()
	End Method

	Method getCurrentAnimation:TAnimation()
		local obj:TAnimation = TAnimation(AnimationSets.ValueForKey(currentAnimation))
		if obj = null then obj = TAnimation(AnimationSets.ValueForKey("default"))
		return obj
	End Method

	Method getAnimation:TAnimation(animationName:string="default")
		local obj:TAnimation = TAnimation(AnimationSets.ValueForKey(animationName))
		if obj = null then obj = TAnimation(AnimationSets.ValueForKey("default"))
		return obj
	End Method


	Method getCurrentAnimationName:string()
		return currentAnimation
	End Method


	Method getCurrentFrame:int()
		return getCurrentAnimation().getCurrentFrame()
	End Method


	Method Draw(_x:float= -10000, _y:float = -10000, overwriteAnimation:string="")
		If visible
			if overwriteAnimation <> ""
				sprite.Draw(_x,_y, getAnimation(overwriteAnimation).getCurrentFrame() )
			else
				sprite.Draw(_x,_y, getCurrentAnimation().getCurrentFrame() )
			endif
		EndIf
	End Method

	Method Update(deltaTime:float)
		getCurrentAnimation().Update(deltaTime)
	End Method

End Type



Type TGW_SpriteParticle
	Field x:Float,y:Float
	Field xrange:Int,yrange:Int
	Field vel:Float
	Field angle:Float
	Field image:TGW_Sprite
	Field life:float
	field startLife:float
	Field is_alive:Int
	Field alpha:Float
	Field scale:Float


		Method Spawn(px:Float,py:Float,pvel:Float,plife:Float,pscale:Float,pangle:Float,pxrange:Float,pyrange:Float)
			is_alive	= True
			x			= Rnd(px-(pxrange/2),px+(pxrange/2))
			y			= Rnd(py-(pyrange/2),py+(pyrange/2))
			vel			= pvel
			xrange		= pxrange
			yrange		= pyrange

			life		= plife
			startLife	= plife
			scale		= pscale
			angle		= pangle
			alpha		= 0.10 * plife + Rnd(1,10)*0.05
		End Method

		Method Update(deltaTime:float = 1.0)
			life:-deltaTime
			If life <0 then is_alive = False
			if is_alive = True
				'pcount:+1
				vel:* 0.99 '1.02 '0.98
				x:+(vel*Cos(angle-90))*deltaTime
				y:-(vel*Sin(angle-90))*deltaTime
				if life / startLife < 0.5 then alpha:*0.97*(1.0-deltaTime)

				If y < 330 Then 	scale:*1.03*(1.0-deltaTime)
				If y > 330 Then 	scale:*1.01*(1.0-deltaTime)
				angle:*0.999
			EndIf
		End Method

		Method Draw()
			If is_alive = True
				SetAlpha alpha
				SetRotation angle
				SetScale(scale,scale)
				image.draw(x,y)
				SetAlpha 1.0
				SetRotation 0
				SetScale 1,1
				SetColor 255,255,255
			EndIf
	    EndMethod
End Type






