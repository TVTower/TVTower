'Sprite-Classes
superstrict

Import BRL.Max2D
Import BRL.Random
Import brl.reflection
Import brl.FreeTypeFont
'Import "basefunctions.bmx"
Import "basefunctions_xml.bmx"
Import "basefunctions_loadsave.bmx"
Import "basefunctions_image.bmx"
Import "basefunctions_asset.bmx"

CONST VALIGN_TOP:float		= 1
CONST VALIGN_CENTER:float	= 0.5
CONST VALIGN_BOTTOM:float	= 0
CONST ALIGN_LEFT:float		= 1
CONST ALIGN_CENTER:float	= 0.5
CONST ALIGN_RIGHT:float		= 0

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
	field pos:TPosition = TPosition.Create(0,0)

End Type

'children get parent linked
Type TRenderableChild extends TRenderable
	field parent:TRenderable

	Method Update(deltaTime:float=1.0) abstract
	Method Draw(tweenValue:float=1.0) abstract
End Type

'manages children
Type TRenderableChildrenManager extends TrenderableChild
	field list:TList = CreateList()

	Function Create:TRenderableChildrenManager(parent:TRenderable)
		local obj:TRenderableChildrenManager = new TRenderableChildrenManager
		obj.parent = parent
		return obj
	end Function

	Method Attach(child:TRenderableChild)
		self.list.addLast(child)
	End Method

	Method Detach(child:TRenderableChild)
		self.list.remove(child)
	endMethod

	Method Update(deltaTime:float=1.0)
		For local obj:TRenderableChild = eachin self.list
			obj.update(deltaTime)
		Next
	End Method

	Method Draw(tweenValue:float=1.0)
		For local obj:TRenderableChild = eachin self.list
			obj.draw(tweenValue)
		Next
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
		Self.elements.Insert(name, TBox.Create( freeArea.x, freeArea.y, w, h ) )
	End Method

	Method Repack()
		local newElements:TMap = CopyMap(self.elements)
		self.packer = new TSpritePacker
		self.packer.setRect(0,0,self.w,self.h)

		ClearMap(self.elements)

		for local name:string = eachin newElements.Keys()
			local box:TBox = TBox(newElements.ValueForKey(name))
			self.AddElement(name, box.w, box.h)
		next
	End Method

	Method Draw(x:int=0, y:int=0)
		setColor 255,100,100
		DrawRect(x,y,self.w, self.h)
		setColor 50,100,200
		For local box:TBox = eachin self.elements.Values()
			DrawRect(box.x+1, box.y+1, box.w-2, box.h-2)
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

    	If (childNode1 = Null And childNode2 = Null) 'If we are a leaf node

        	If occupied Or width > w Or height > h Return Null

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
        	If newNode <> Null Return newNode

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

        If dw > dh Then ' split vertically
            childNode1.setRect(x,y,width,h)
            childNode2.setRect(x+width,y,dw,h)
		Else ' split horizontally
            childNode1.setRect(x,y,w,height)
            childNode2.setRect(x,y+height,w,dh)
		EndIf

	End Method

End Type

Type TBox
	Field x:Int,y:Int,w:Int,h:Int

	function Create:TBox(x:int,y:int,w:int,h:int)
		local obj:TBox = new TBox
		obj.x = x
		obj.y = y
		obj.w = w
		obj.h = h
		return obj
	End Function

	Method Compare:Int(o:Object)
		Local box:TBox = TBox(o)
		If box.h*box.w < h*w Return -1
		If box.h*box.w > h*w Return 1
		Return 0
	End Method
End Type

' -------------------------------------


Type TBitmapFontChar
	field box:TBox
	Field charWidth:float
	Field img:TImage

	Function Create:TBitmapFontChar(img:TImage, x:int,y:int,w:Int, h:int, charWidth:float)
		Local obj:TBitmapFontChar = New TBitmapFontChar
		obj.img = img
		obj.box = TBox.Create(x,y,w,h)
		obj.charWidth = charWidth
		Return obj
	End Function
End Type

Type TBitmapFont
	Field chars:TMap	= CreateMap()
	Field charsSprites:Tmap=CreateMap()
	field spriteSet		:TGW_SpritePack
	Field MaxSigns		:Int=256
	Field ExtraChars	:string="€"
	Field gfx			:TMax2dGraphics
	Field uniqueID		:string =""
	Field displaceY		:float=100.0

	Function Create:TBitmapFont(url:String,size:Int, style:Int)
		Local obj:TBitmapFont = New TBitmapFont

		Local imgFont:TImageFont = LoadTrueTypeFont(url,size, style)
		If imgfont=Null Return Null

		local oldFont:TImageFont = getImageFont()
		SetImageFont(imgfont)

		obj.uniqueID = url+"_"+size+"_"+style

		obj.gfx = tmax2dgraphics.Current()

		'create spriteset
		obj.spriteSet = TGW_SpritePack.Create(null, obj.uniqueID+"_charmap")


		local charmap:TSpriteAtlas = TSpriteAtlas.Create(64,64)
		local spacer:int = 1
		For Local i:Int = 0 Until obj.MaxSigns
			Local n:Int = imgFont.CharToGlyph(i)
			If n < 0 then Continue
			Local glyph:TImageGlyph = imgFont.LoadGlyph(n)
			If glyph
				'base displacement calculated with A-Z (space between TOPLEFT of 'ABCDE' and TOPLEFT of 'acen'...)
				if i >= 65 AND i < 95 then obj.displaceY = Min(obj.displaceY, glyph._y)
				obj.chars.insert(string(i), TBitmapFontChar.Create(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance))
				charmap.AddElement(i,glyph._w+spacer,glyph._h+spacer ) 'add box of char and package atlas
			endif
		Next
		For Local charNum:Int = 0 Until obj.ExtraChars.length
			Local n:Int = imgFont.CharToGlyph( obj.ExtraChars[charNum] )
			Local glyph:TImageGlyph = imgFont.LoadGlyph(n)
			If glyph
				obj.chars.insert(string(obj.ExtraChars[charNum]) , TBitmapFontChar.Create(glyph._image, glyph._x, glyph._y,glyph._w,glyph._h, glyph._advance) )
				charmap.AddElement(obj.ExtraChars[charNum] ,glyph._w+spacer,glyph._h+spacer ) 'add box of char and package atlas
			endif
		Next

		'now we have final dimension of image
		'create 8bit alpha'd image (grayscale with alpha ...)
		local pix:TPixmap = CreatePixmap(charmap.w,charmap.h, PF_A8) ; pix.ClearPixels(0)
		'loop through atlax boxes and add chars
		For local charKey:string = eachin charmap.elements.Keys()
			local box:TBox = TBox(charmap.elements.ValueForKey(charKey))
			'draw char image on charmap
			if obj.chars.ValueForKey(charKey) <> null AND TBitmapFontChar(obj.chars.ValueForKey(charKey)).img <> null
				'print "adding "+charKey + " = "+chr(int(charKey))
				local charPix:TPixmap = LockImage(TBitmapFontChar(obj.chars.ValueForKey(charKey)).img)
				If charPix.format <> 2 Then charPix.convert(PF_A8) 'make sure the pixmaps are 8bit alpha-format
				self.DrawCharPixmapOnPixmap(charPix, pix, box.x,box.y, size, style)
				UnlockImage(TBitmapFontChar(obj.chars.ValueForKey(charKey)).img)
				' es fehlt noch charWidth - extraTyp?

				obj.charsSprites.insert(charKey, TGW_Sprites.Create(obj.spriteSet, charKey, box.x, box.y, box.w, box.h, 0, int(charKey)))
			endif
		Next
		'set image to sprite pack
		obj.spriteSet.image = LoadImage(pix)

		SetImageFont(oldFont)
		Return obj
	End Function

	Function DrawCharPixmapOnPixmap(Source:TPixmap,Pixmap:TPixmap, x:Int, y:Int, fontSize:int, fontStyle:int =0)
		  For Local i:Int = 0 To Source.width-1
			For Local j:Int = 0 To Source.height-1
			  If x+1 < pixmap.width And y+j < pixmap.height
				Local sourcepixel:Int = ReadPixel(Source, i,j)
				Local destpixel:Int = ReadPixel(pixmap, x+i,y+j)
	'			Local destA:Int = ARGB_Alpha(destpixel)
				Local sourceA:Int = ARGB_Alpha(sourcepixel)
				If sourceA <> -1 Then
					If sourceA< -1 Then sourceA = -sourceA
					Local destR:Int = ARGB_Red(destpixel)
					Local destG:Int = ARGB_Green(destpixel)
					Local destB:Int = ARGB_Blue(destpixel)
					Local destA:Int = ARGB_Alpha(destpixel)
					Local SourceR:Int = ARGB_Red(Sourcepixel)
					Local SourceG:Int = ARGB_Green(Sourcepixel)
					Local SourceB:Int = ARGB_Blue(Sourcepixel)
					sourceR = Int( Float(sourceA/255.0)*sourceR) + Int(Float((255-sourceA)/255.0)*destR)
					sourceG = Int( Float(sourceA/255.0)*sourceG) + Int(Float((255-sourceA)/255.0)*destG)
					sourceB = Int( Float(sourceA/255.0)*sourceB) + Int(Float((255-sourceA)/255.0)*destB)
					'also mix alpha
					if (not fontStyle & BOLDFONT) OR fontSize >= 10
						sourceA = 0.6*(SourceA*SourceA)/255 + 0.4*SourceA
					endif
'					else
'						if sourceA >=200 then sourceA = 0.4*(SourceA*SourceA)/255 + 0.6*SourceA
'						if sourceA < 200 then sourceA = 0.5*(SourceA*SourceA)/255 + 0.5*SourceA
'					endif
					sourcepixel = ARGB_Color(sourceA, sourceR, sourceG, sourceB)
				EndIf
				If sourceA <> 0 Then WritePixel(Pixmap, x+i,y+j, sourcepixel)
			  EndIf
			Next
		  Next
	End Function

	Method AddChar:TBitmapFontChar(charCode:int, img:timage, x:int, y:int, w:int, h:int, charWidth:float)
		'paint on pixmap
		self.spriteSet.CopyImageOnSpritePackImage(img, null, x,y)
		self.chars.insert(string(charCode), TBitmapFontChar.Create(img, x,y,w,h, charWidth))
	End Method

	Method getWidth:Float(text:String)
		return float(string( self.draw(text,0,0,0,0) ))
	End Method

	Method getHeight:Float(text:String)
		return float(string( self.draw(text,0,0,1,0) ))
	End Method

	Method getBlockHeight:Float(text:String, w:Float, h:Float)
		Return self.getHeight(text)
	End Method

	Method drawOnPixmap(Text:String, x:Int, y:Int, cR:Int=0, cG:Int=0, cB:Int=0, Pixmap:TPixmap, blur:Byte=0)
		local oldR:int, oldG:int, oldB:int
		GetColor(oldR, oldG, oldB)

		If blur
			SetColor(50,50,50)
			self.draw(Text,x-1,y-1)
			self.draw(Text,x+1,y+1)
			SetColor cr,cg,cb
		Else
			self.draw(Text,x,y)
		EndIf
			Local TxtWidth:Int   = self.getWidth(Text)
			Local Source:TPixmap = GrabPixmap(x-2,y-2,TxtWidth+4,self.getHeight(Text)+4)
			Source = ConvertPixmap(Source, PF_RGB888)
		If blur
			blurPixmap(Source, 0.5)
			Source = ConvertPixmap(Source, PF_RGB888)
			DrawImage(LoadImage(Source), x-2,y-2)
			self.draw(Text,x,y)
			Source = GrabPixmap(x-2,y-2,TxtWidth+4,self.getHeight(Text)+4)
			Source = ConvertPixmap(Source, PF_RGB888)
		EndIf
		DrawPixmapOnPixmap(Source, Pixmap,x-20,y-10)
		SetColor( oldR, oldG, oldB )
	End Method

	Method drawBlock:float(text:String, x:Float,y:Float,w:Float,h:Float, align:Int=0, cR:Int=0, cG:Int=0, cB:Int=0, NoLineBreak:Byte = 0, style:int=0, doDraw:int = 1)
		Local charcount:Int		= 0
		Local deletedchars:Int	= 0
		Local charpos:Int		= 0
		Local linetxt:String	= text
		Local spaceAvaiable:Float = h
		Local alignedx:Int		= 0
		Local usedHeight:Int	= 0
		local oldColor:TColor	= TColor.Create()

		If doDraw then oldcolor.get(); SetColor(cR,cG,cB)

		If NoLineBreak = False
			Repeat
				charcount = 0
				'line to wide for box - shorten it
				while self.getWidth(linetxt) >= w
					'if cant get shortened: CharCount = 0 -> line deleted
					For charpos = 0 To Len(linetxt) - 1
						If linetxt[charpos] = Asc(" ") Then CharCount = charpos
						If linetxt[charpos] = Asc("-") Then CharCount = charpos' - 1
						If linetxt[charpos] = Asc(Chr(13)) Then CharCount = charpos;charpos = Len(Linetxt) - 1
					Next
					linetxt = linetxt[..CharCount]
				Wend

				'place (truncated) line
				local drawLine:string = linetxt

				'no space left, we have finally to truncate and delete rest...
				If 2 * self.getHeight(linetxt) > SpaceAvaiable And linetxt <> text[deletedchars..]
					drawLine = linetxt[..Len(linetxt) - 3] + " ..."
					charcount = 0
				EndIf

				If doDraw
					If align = 0 Then alignedx = x
					If align = 1 Then alignedx = x + (w - self.getWidth(linetxt)) / 2
					If align = 2 Then alignedx = x + (w - self.getWidth(linetxt))
					self.drawStyled(drawLine, alignedx, y + h - spaceAvaiable, cR, cG, cB, style)
				endif

				spaceAvaiable :- self.getHeight(linetxt)
				deletedchars :+ (charcount+1)
				linetxt = text[Deletedchars..]
			Until charcount = 0
			usedheight = h - spaceAvaiable
		Else 'no linebreak allowed
			If self.getWidth(linetxt) >= w
				charcount = Len(linetxt)-1
				While self.getWidth(linetxt) >= w
					linetxt = linetxt[..charcount]
					charcount:-1
				Wend
				If align = 0 Then alignedx = x
				If align = 1 Then alignedx = x+(w - self.getWidth(linetxt$))/2
				If align = 2 Then alignedx = x+(w - self.getWidth(linetxt$))
				spaceAvaiable = spaceAvaiable - self.getHeight(linetxt$[..Len(linetxt$)-2]+"..")
				If doDraw Then self.drawStyled(linetxt[..Len(linetxt) - 2] + "..", alignedx, y, cR, cG, cB, style)
			Else
				If align = 0 Then alignedx = x
				If align = 1 Then alignedx = x + (w - self.getWidth(linetxt)) / 2
				If align = 2 Then alignedx = x + (w - self.getWidth(linetxt))
				spaceAvaiable :- self.getHeight(linetxt)
				If doDraw Then self.drawStyled(linetxt, alignedx, y, cR, cG, cB, style)
			EndIf
			usedheight = self.getHeight(linetxt)
		EndIf

		If doDraw then oldColor.set()
		Return usedheight
	End Method

	Method drawStyled:object(text:String,x:Float,y:Float, cr:int, cg:int, cb:int, style:int=0, returnType:int=0, doDraw:int=1, special:float=0.0)
		local height:float = 0.0
		local width:float = 0.0
		local oldR:int, oldG:int, oldB:int
		GetColor(oldR, oldG, oldB)

		'emboss
		if style = 1
			height:+ 1
			if doDraw
				local oldA:float = getAlpha()
				SetAlpha float(0.75*oldA)
				SetColor 250,250,250
				self.draw(text, x,y+1)
				SetAlpha oldA
			endif
		'shadow
		else if style = 2
			height:+ 1
			width:+1
			if doDraw
				local oldA:float = getAlpha()
				if special <> 0.0 then SetAlpha special*oldA else SetAlpha 0.5*oldA
				SetColor 0,0,0
				self.draw(text, x+1,y+1)
				SetAlpha oldA
			endif
		endif

		SetColor cr,cg,cb
		local result:object = self.draw(text,x,y, returnType, doDraw)


		SetColor( oldR, oldG, oldB )
		return result
	End Method


	Method drawWithBG:object(value:String, x:Int, y:Int, bgAlpha:Float = 0.3, bgCol:Int = 0, style:int=0)
		Local OldAlpha:Float = GetAlpha()
		Local color:TColor = TColor.Create()
		color.get()
		SetAlpha bgAlpha
		SetColor bgCol, bgCol, bgCol
		local dimension:TPosition = TPosition( self.drawStyled(value,0,0, 0,0,0, style,2,0) )
		DrawRect(x, y, dimension.x, dimension.y)
		SetAlpha OldAlpha
		color.set()
		return self.drawStyled(value, x, y, color.r,color.g,color.b, style)
	End Method


	Method draw:object(text:String,x:Float,y:Float, returnType:int=1, doDraw:int = 1)
		local width:float = 0.0
		local height:float = 0.0
		local textLines:string[]	= text.split(chr(13))
		local currentLine:int = 0

		For text:string = eachin textLines
			currentLine:+1

			local lineHeight:int = 0
			local lineWidth:int = 0
			For Local i:Int = 0 Until text.length
				Local bm:TBitmapFontChar = TBitmapFontChar( self.chars.ValueForKey(string(text[i])) )
				if bm <> null
					Local tx:Float = bm.box.x * gfx.tform_ix + bm.box.y * gfx.tform_iy
					Local ty:Float = bm.box.x * gfx.tform_jx + bm.box.y * gfx.tform_jy
					'drawable ? (> 32)
					if text[i] > 32
						lineHeight = MAX(lineHeight, bm.box.h)
						if doDraw
							local sprite:TGW_Sprites = TGW_Sprites(self.charsSprites.ValueForKey(string(text[i])))
							if sprite <> null then sprite.Draw(x+lineWidth+tx,y+height+ty - self.displaceY)
						endif
					endif
					lineWidth :+ bm.charWidth * gfx.tform_ix
				EndIf
			Next
			width = max(width, lineWidth)
			height:+lineHeight
			'except first line (maybe only one line) - add extra spacing between lines
			if currentLine > 0 then height:+ ceil(lineHeight*0.4)
		Next
		if returnType = 0 then return string(width)
		if returnType = 1 then return string(height)
		return TPosition.Create(width, height)
	End Method

	Method drawfixed(text:String,x:Float,y:Float)
		For Local i:Int = 0 Until text.length
			Local bm:TBitmapFontChar = TBitmapFontChar(self.chars.ValueForKey(string(text[i]-32)))
			if bm <> null
				Local tx:Float = bm.box.x * gfx.tform_ix + bm.box.y * gfx.tform_iy
				Local ty:Float = bm.box.x * gfx.tform_jx + bm.box.y * gfx.tform_jy
				local sprite:TGW_Sprites = TGW_Sprites(self.charsSprites.ValueForKey(string(text[i]-32)))
				if sprite <> null then sprite.Draw(x+tx,y+ty)
				x :+ bm.charWidth
			endif
		Next
	End Method

End Type


Type TGW_FontManager
	Field DefaultFont:TGW_Font
	Field baseFont:TBitmapFont
	Field baseFontBold:TBitmapFont
	Field List:TList = CreateList()

	Function Create:TGW_FontManager()
		Local tmpObj:TGW_FontManager = New TGW_FontManager
		tmpObj.List = CreateList()
		Return tmpObj
	End Function

'	Method GW_GetFont:TImageFont(_FName:String, _FSize:Int = -1, _FStyle:Int = -1)
	Method GetFont:TBitmapFont(_FName:String, _FSize:Int = -1, _FStyle:Int = -1)
		If _FName = "Default" And _FSize = -1 And _FStyle = -1 Then Return DefaultFont.FFont
		If _FSize = -1 Then _FSize = DefaultFont.FSize
		If _FStyle = -1 Then _FStyle = DefaultFont.FStyle Else _FStyle = _FStyle | SMOOTHFONT

		Local defaultFontFile:String = DefaultFont.FFile
		For Local Font:TGW_Font = EachIn Self.List
			If Font.FName = _FName And Font.FStyle = _FStyle Then defaultFontFile = Font.FFile
			If Font.FName = _FName And Font.FSize = _FSize And Font.FStyle = _FStyle Then Return Font.FFont
		Next
		Return AddFont(_FName, defaultFontFile, _FSize, _FStyle).FFont
	End Method

	Method AddFont:TGW_Font(_FName:String, _FFile:String, _FSize:Int, _FStyle:Int)
		If _FSize = -1 Then _FSize = DefaultFont.FSize
		If _FStyle = -1 Then _FStyle = DefaultFont.FStyle
		If _FFile = "" Then _FFile = DefaultFont.FFile

		Local Font:TGW_Font = TGW_Font.Create(_FName, _FFile, _FSize, _FStyle)
		Self.List.AddLast(Font)
		Return Font
	End Method
End Type

Type TGW_Font
	Field FName:String
	Field FFile:String
	Field FSize:Int
	Field FStyle:Int
	'Field FFont:TImageFont
	Field FFont:TBitmapFont

	Function Create:TGW_Font(_FName:String, _FFile:String, _FSize:Int, _FStyle:Int)
		Local tmpObj:TGW_Font = New TGW_Font
		tmpObj.FName = _FName
		tmpObj.FFile = _FFile
		tmpObj.FSize = _FSize
		tmpObj.FStyle = _FStyle
		tmpObj.FFont = TBitmapFont.Create(_FFile, _FSize, _FStyle | SMOOTHFONT)
		Return tmpObj
	End Function
End Type


Type TGW_SpritePack extends TRenderable
	Field image:TImage
	Field sprites:TList = CreateList()
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

	Method GetSpriteImage:TImage(spritename:String = "", SpriteID:Int = -1, loadAnimated:Int =1)
		Local tmpObj:TGW_Sprites
		If spritename <> ""
			tmpObj = GetSprite(spritename)
		Else
			tmpObj = GetSpriteByID(SpriteID)
		EndIf
		Local DestPixmap:TPixmap = LockImage(image, 0, False, True).Window(tmpObj.Pos.x, tmpObj.Pos.y, tmpObj.w, tmpObj.h)
		UnlockImage(image)
		GCCollect() '<- FIX!
		If tmpObj.animcount >1 And loadAnimated
			Return TImage.LoadAnim(DestPixmap, tmpObj.framew, tmpObj.frameh, 0, tmpObj.animcount, 0, 255, 0, 255)
		Else
			Return TImage.Load(DestPixmap, 0, 255, 0, 255)
		End If
	End Method

	Method GetSpriteFrameImage:TImage(spritename:String = "", SpriteID:Int = -1, framenr:Int = 0)
		Local tmpObj:TGW_Sprites
		If spritename <> ""
			tmpObj = GetSprite(spritename)
		Else
			tmpObj = GetSpriteByID(SpriteID)
		EndIf
		Local DestPixmap:TPixmap = LockImage(image, 0, False, True).Window(tmpObj.Pos.x + framenr * tmpObj.framew, tmpObj.Pos.y, tmpObj.framew, tmpObj.h)
		UnlockImage(image)
		GCCollect() '<- FIX!
		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method

	Method GetSprite:TGW_Sprites(spritename:String = "")
		For Local i:Int = 0 To Self.sprites.Count() - 1
			If lower(TGW_Sprites(Self.sprites.ValueAtIndex(i)).spritename) = lower(spritename) Then Return TGW_Sprites(Self.sprites.ValueAtIndex(i))
		Next
		print "GetSprite: "+spritename+" not found"
		Return TGW_Sprites(Self.sprites.ValueAtIndex(0))
	End Method

	Method GetSpriteByID:TGW_Sprites(SpriteID:Int = 0)
		For Local i:Int = 0 To Self.sprites.Count() - 1
			If TGW_Sprites(Self.sprites.ValueAtIndex(i)).SpriteID = SpriteID Then Return TGW_Sprites(Self.sprites.ValueAtIndex(i))
		Next
		Return TGW_Sprites(Self.sprites.ValueAtIndex(0))
	End Method

	Method AddSprite:TGW_Sprites(spritename:String, posx:Float, posy:Float, w:Int, h:Int, animcount:int = 0, SpriteID:Int = -1)
		Local sID:Int = SpriteID
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID;
		local sprite:TGW_Sprites = TGW_Sprites.Create(Self, spritename, posx, posy, w, h, animcount, SpriteID)
		Self.sprites.AddLast(sprite)
		return sprite
	End Method

	Method AddAnimSpriteMultiCol(spritename:String, posx:Float, posy:Float, w:Int, h:Int, spritew:Int, spriteh:Int, animcount:Int, SpriteID:Int = -1)
		Local sID:Int = SpriteID
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID;
		Self.sprites.AddLast(TGW_Sprites.Create(Self, spritename, posx, posy, w, h, animcount, SpriteID, spritew, spriteh))
	End Method

	Method DrawSprite(spritename:String = "", x:Float, y:Float, animframe:Int = -1, spriteobj:TGW_Sprites = Null)
		If spriteobj = Null
			For Local i:Int = 0 To Self.sprites.Count() - 1
				If TGW_Sprites(Self.sprites.ValueAtIndex(i)).spritename = spritename Then spriteobj = TGW_Sprites(Self.sprites.ValueAtIndex(i)) ;Exit
			Next
		End If
		If spriteobj <> Null
			DrawImageArea(Self.image, x, y, spriteobj.Pos.x + Max(0, animframe) * spriteobj.framew, spriteobj.Pos.y, spriteobj.framew, spriteobj.h, 0)
		EndIf
	End Method

	Method Draw(tweenValue:float=1.0)
		DrawImage(self.image, self.pos.x, self.pos.y)
	End Method

	Method DrawToViewPort(spritename:String = "", x:Float, y:Float, vx:Float, vy:Float, vw:Float, vh:Float, spriteobj:TGW_Sprites = Null)
		If spriteobj = Null
			For Local i:Int = 0 To Self.sprites.Count() - 1
				If TGW_Sprites(Self.sprites.ValueAtIndex(i)).spritename = spritename Then spriteobj = TGW_Sprites(Self.sprites.ValueAtIndex(i)) ;Exit
			Next
		End If
		If spriteobj <> Null Then ClipImageToViewport(Self.image, x - spriteobj.pos.x, y - spriteobj.pos.y, vx, vy, vw, vh, 0, 0)
	End Method

	Method ColorizeSprite(spriteName:String, colR:Int,colG:Int,colB:Int)
		'to access pos and dimension
		Local tmpSprite:TGW_Sprites = Self.GetSprite(spriteName)
		'store backup (we clean it before pasting colorized output
		local tmpImg:TImage = ColorizeTImage(Self.GetSpriteImage(spriteName), colR, colG, colB)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(tmpSprite.Pos.x, tmpSprite.pos.y, tmpSprite.w, tmpSprite.h).ClearPixels(0)
			DrawOnPixmap(tmpImg, 0, tmppix, tmpSprite.pos.x, tmpSprite.pos.y)
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
	End Method

	Method CopySprite(spriteNameSrc:String, spriteNameDest:String, colR:Int,colG:Int,colB:Int)
		Local tmpSpriteDest:TGW_Sprites = Self.GetSprite(spriteNameDest)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(tmpSpriteDest.Pos.x, tmpSpriteDest.pos.y, tmpSpriteDest.w, tmpSpriteDest.h).ClearPixels(0)
			DrawOnPixmap(ColorizeTImage(Self.GetSpriteImage(spriteNameSrc), colR, colG, colB), 0, tmppix, tmpSpriteDest.pos.x, tmpSpriteDest.pos.y)
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
	End Method

	Method AddCopySprite:TGW_Sprites(spriteNameSrc:String, spriteNameDest:String, posx:Float, posy:Float, w:Int, h:Int, animcount:int = 0, colR:Int,colG:Int,colB:Int)
		local tmpSpriteDest:TGW_Sprites = self.AddSprite(spriteNameDest,posx, posy, w, h, animcount)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(tmpSpriteDest.Pos.x, tmpSpriteDest.pos.y, tmpSpriteDest.w, tmpSpriteDest.h).ClearPixels(0)
			DrawOnPixmap(ColorizeTImage(Self.GetSpriteImage(spriteNameSrc), colR, colG, colB), 0, tmppix, tmpSpriteDest.pos.x, tmpSpriteDest.pos.y)
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
		return tmpSpriteDest
	End Method

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
		'		print srcPix.format + " sollte:" +PF_RGBA8888
				If srcPix.format <> PF_RGBA8888 Then srcPix.convert(PF_RGBA8888) 'make sure the pixmaps are 32 bit format
		'		If tmppix.format <> PF_RGBA8888 Then tmppix.convert(PF_RGBA8888) 'make sure the pixmaps are 32 bit format
				DrawPixmapOnPixmap(srcPix, tmppix, destX, destY)
			if dest = null then UnlockImage(Self.image, 0)
		endif
		if TImage(src)<> null then UnlockImage(TImage(src))
		GCCollect() '<- FIX!
	End Method
End Type


Type TGW_Sprites extends TRenderable
	Field spriteName:String = ""
	Field w:Float
	Field h:Float
	Field framew:Int
	Field frameh:Int
	Field animcount:Int
	Field SpriteID:Int = -1
	Field parent:TGW_SpritePack

	Function Create:TGW_Sprites(spritepack:TGW_SpritePack=null, spritename:String, posx:Float, posy:Float, w:Int, h:Int, animcount:Int = 0, SpriteID:Int = -1, spritew:Int = 0, spriteh:Int = 0)
		Local Obj:TGW_Sprites = New TGW_Sprites
		Obj.spritename	= spritename
		Obj.parent		= spritepack
		Obj.Pos.setXY(posx, posy)
		Obj.w = w
		Obj.framew = w
		obj.frameh = h
		Obj.h			= h
		Obj.SpriteID	= SpriteID
		Obj.animcount	= animcount
		If animcount > 0 Then
			Obj.framew = ceil(w / animcount)
			Obj.frameh = h
		End If
		If spritew <> 0 And spriteh <> 0
			Obj.framew = spritew
			Obj.frameh = spriteh
		End If

		'asset
		Obj.setName(spritename)
		Obj.setUrl("NONE")
		Obj.setType("SPRITE")
		Return Obj
	End Function

	Function LoadFromAsset:TGW_Sprites(asset:object)
		local obj:TGW_Sprites = TGW_Sprites(asset)

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

		return TGW_Sprites.Create(spritepack, obj.getName(), 0,0, ImageWidth(spritepack.image), ImageHeight(spritepack.image), obj.animcount, -1, obj.framew, obj.frameh)
	End Function

	Method GetImage:TImage(loadAnimated:Int =1)
		Local DestPixmap:TPixmap = LockImage(self.parent.image, 0, False, True).Window(self.Pos.x, self.Pos.y, self.w, self.h)
		UnlockImage(self.parent.image)
		GCCollect() '<- FIX!
		SetMaskColor(255,0,255)
		If self.animcount >1 And loadAnimated
			Return LoadAnimImage(DestPixmap, self.framew, self.frameh, 0, self.animcount)
		Else
			Return LoadImage(DestPixmap)
		EndIf
	End Method

	'let spritePack colorize the sprite
	Method Colorize(colR:Int,colG:Int,colB:Int)
		self.parent.ColorizeSprite(self.spriteName, colR,colG,colB)
	End Method

	Method GetColorizedImage:TImage(r:int, g:int, b:int)
		return ColorizeTImage(self.GetImage(0), r,g,b, self.framew, self.frameh, 0, self.animcount, 0, 0)
	End Method

	Method GetFrameImage:TImage(framenr:Int = 0)
		Local tmpObj:TGW_Sprites = self.parent.GetSprite(self.spritename)
		Local DestPixmap:TPixmap = LockImage(self.parent.image, 0, False, True).Window(tmpObj.Pos.x + framenr * tmpObj.framew, tmpObj.Pos.y, tmpObj.framew, tmpObj.h)
		UnlockImage(self.parent.image)
		GCCollect() '<- FIX!
		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method

	Method DrawClipped(imagex:Float, imagey:Float, ViewportX:Float, ViewPortY:Float, ViewPortW:Float, ViewPortH:Float, offsetx:Float = 0, offsety:Float = 0, theframe:Int = 0)
		if ViewPortW < 0 then ViewPortW = self.w
		if ViewPortH < 0 then ViewPortH = self.h

		If imagex+framew>=ViewportX And imagex-framew<ViewportX+ViewportW And imagey+frameh>=ViewportY And imagey-frameh<ViewportY+ViewportH Then
			Local startx#	= Max(0,ViewportX-imagex)
			Local starty#	= Max(0,ViewportY-imagey)
			Local endx#		= Max(0,(imagex+framew)-(ViewportX+ViewportW))
			Local endy#		= Max(0,(imagey+frameh)-(ViewportY+ViewportH))

			'calculate WHERE the frame is positioned in spritepack
			If Self.framew <> 0
				Local MaxFramesInCol:Int	= Ceil(w / framew)
				Local framerow:Int			= Ceil(theframe / maxframesincol)
				Local framecol:Int 			= theframe - (framerow * maxframesincol)
				DrawImageArea(parent.image, imageX + startX + offsetx, imagey + starty + offsety, pos.x + framecol* framew + startx, pos.y + framerow * frameh + starty, framew - startx - endx, frameh - starty - endy, 0)
			EndIf
		EndIf
	End Method

	'Draws an Image if its in the viewport of the screen (not on Interface)
	Method DrawInViewPort(_x:Int, _yItStandsOn:Int, align:Byte=0, Frame:Int=0)
		If _yItStandsOn > 10 And _yItStandsOn - self.h < 373+10
		  If align = 0 '_x is left side of image
			self.Draw(_x, _yItStandsOn - self.h, Frame)
		  ElseIf align = 1 '_x is right side of image
			self.Draw(_x - self.w, _yItStandsOn - self.h,Frame)
		  EndIf
		EndIf
	End Method

	Method TileDrawHorizontal(x:float, y:float, w:float, scale:float=1.0)
		local widthLeft:float = w
		local currentX:float = x
		while widthLeft > 0
			local widthPart:float = Min(self.w, widthLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.image, currentX, y, widthPart, self.h, self.pos.x, self.pos.y, widthPart, self.h )
			currentX :+ widthPart * scale
			widthLeft :- widthPart * scale
		Wend
	End Method

	Method TileDrawVertical(x:float, y:float, h:float, scale:float=1.0)
		local heightLeft:float = h
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float = Min(self.h, heightLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.image, x, currentY, self.w, ceil(heightPart), self.pos.x, self.pos.y, self.w, ceil(heightPart) )
			currentY :+ floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method TileDraw(x:Float, y:Float, w:Int, h:Int, animframe:Int = -1, scale:float=1.0)
		local heightLeft:float = floor(h)
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float	= Min(self.h, heightLeft) 'draw part of sprite or whole ?
			local widthLeft:float	= w
			local currentX:float	= x
			while widthLeft > 0
				local widthPart:float = Min(self.w, widthLeft) 'draw part of sprite or whole ?
				DrawSubImageRect( parent.image, currentX, currentY, ceil(widthPart), ceil(heightPart), self.pos.x, self.pos.y, ceil(widthPart), ceil(heightPart) )
				currentX	:+ floor(widthPart * scale)
				widthLeft	:- (widthPart * scale)
			Wend
			currentY	:+ floor(heightPart * scale)
			heightLeft	:- (heightPart * scale)
		Wend
	End Method

	Method Update(deltaTime:float=1.0)
	End Method

	Method Draw(x:Float, y:Float, theframe:Int = -1, valign:float = 0.0, align:float=0.0, scale:float=1.0)
		If theframe = -1 Or framew = 0
			DrawImageArea(parent.image, x - align*w*scale , y - valign * h * scale, pos.x, pos.y, w, h, 0)
		Else
			Local MaxFramesInCol:Int	= Ceil(w / framew)
			Local framerow:Int			= Ceil(theframe / MaxFramesInCol)
			Local framecol:Int 			= theframe - (framerow * MaxFramesInCol)
			DrawImageArea(parent.image, x - align*w * scale, y - valign * h * scale, pos.x + framecol * framew, pos.y + framerow * frameh, framew, frameh, 0)
		EndIf
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


	Function Create:TAnimation(framesArray:int[][], repeatTimes:int=0, paused:byte=0)
		local obj:TAnimation = new TAnimation
		local framecount:int = len( framesArray )

		obj.frames		= obj.frames[..framecount] 'extend
		obj.framesTime	= obj.framesTime[..framecount] 'extend

		For local i:int = 0 to framecount-1
			obj.frames[i]		= framesArray[i][0]
			obj.framesTime[i]	= float(framesArray[i][1]) * 0.001
		Next
		obj.repeatTimes	= repeatTimes
		obj.paused		= paused
		return obj
	End Function

	Method Update(deltaTime:float=1.0)
		If not self.paused
			if self.frameTimer = null then self.ResetFrameTimer()

			self.frameTimer :- deltaTime
			if self.frameTimer <= 0.0
				'increase current frameposition but only if frame is set
				'resets frametimer too
				self.setCurrentFramePos(self.currentFramePos + 1)
				'print self.currentFramePos + " -> "+ self.currentFrame

				'reached end
				If self.currentFramePos >= len(self.frames)-1
					If self.repeatTimes = 0 then
						self.Pause()	'stop animation
					Else
						self.setCurrentFramePos( 0 )
						self.repeatTimes	:-1
					EndIf
				EndIf
			Endif
		EndIf
	End Method

	Method Reset()
		self.setCurrentFramePos(0)
	End Method

	Method ResetFrameTimer()
		self.frameTimer = self.framesTime[self.currentFramePos]
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


'base of animated sprites... contains timers and so on, supports reversed animations
Type TAnimSprites
	Field pos:TPosition				= TPosition.Create(0,0)
	Field vel:TPosition				= TPosition.Create(0,0)
	Field sprite:TGW_Sprites
	Field returnToStart:Int			= 0
	Field visible:Int 				= 1
	Field AnimationSets:TMap	 	= CreateMap()
	Field currentAnimation:string	= "default"

	Function Create:TAnimSprites(sprite:TGW_Sprites, x:Int, y:Int, dx:Int, dy:int = 0, AnimCount:Int = 1, animTime:Int)
		Local AnimSprites:TAnimSprites=New TAnimSprites
		AnimSprites.pos.setXY(x, y)
		AnimSprites.vel.setXY(dx,dy)
		AnimSprites.sprite = sprite

		local framesArray:int[][2]
		framesArray	= framesArray[..AnimCount] 'extend
		for local i:int = 0 to AnimCount -1
			framesArray[i]		= framesArray[i][..2] 'extend to 2 fields each entry
			framesArray[i][0]	= i
			framesArray[i][1]	= animTime
		Next
		AnimSprites.insertAnimation( "default", TAnimation.Create(framesArray,0,0) )

		Return AnimSprites
	End Function

	Method InsertAnimation(animationName:string, animation:TAnimation)
		self.AnimationSets.insert(lower(animationName), animation)
		if not self.AnimationSets.contains("default") then self.setCurrentAnimation(animationName, 0)
	End Method

	Method setCurrentAnimation(animationName:string, startAnimation:byte = 1)
		self.currentAnimation = lower(animationName)
		self.getCurrentAnimation().Reset()
		if startAnimation then self.getCurrentAnimation().Playback()
	End Method

	Method getCurrentAnimation:TAnimation()
		local obj:TAnimation = TAnimation(self.AnimationSets.ValueForKey(self.currentAnimation))
		if obj = null then obj = TAnimation(self.AnimationSets.ValueForKey("default"))
		return obj
	End Method

	Method getAnimation:TAnimation(animationName:string="default")
		local obj:TAnimation = TAnimation(self.AnimationSets.ValueForKey(animationName))
		if obj = null then obj = TAnimation(self.AnimationSets.ValueForKey("default"))
		return obj
	End Method


	Method getCurrentAnimationName:string()
		return self.currentAnimation
	End Method


	Method getCurrentFrame:int()
		return self.getCurrentAnimation().getCurrentFrame()
	End Method

	Method Draw(_x:float=-10000.0, _y:float = -10000, overwriteAnimation:string="")
		If visible
			If _x = -10000 OR _x = null Then _x = pos.x
			If _y = -10000 Then _y = pos.y
			if overwriteAnimation <> ""
				sprite.Draw(_x,_y, self.getAnimation(overwriteAnimation).getCurrentFrame() )
			else
				sprite.Draw(_x,_y, self.getCurrentAnimation().getCurrentFrame() )
			endif
		EndIf
	End Method

	Method Update(deltaTime:float)
		self.getCurrentAnimation().Update(deltaTime)
		self.pos.x :+ deltaTime * self.vel.x
		self.pos.y :+ deltaTime * self.vel.y
	End Method

	Method UpdateWithReturn(deltaTime:float=1.0)
		Update(deltaTime)
		If returnToStart > 0 And pos.x-returntostart>800 Then pos.x = -returnToStart
	End Method
End Type