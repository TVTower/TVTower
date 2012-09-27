SuperStrict
Import brl.Graphics

Import brl.d3d7max2d
Import brl.glmax2d
Import brl.Max2D

Import brl.StandardIO
Import brl.Max2D

Import "basefunctions.bmx"
?Win32
'Import "Dx9Max2dDriver05\Dx9Max2dGraphicsDriver.bmx"
?

Function DrawImageArea(image:TImage, x:Float, y:Float, rx:Float, ry:Float, rw:Float, rh:Float, theframe:Int = 0)
	DrawSubImageRect(image, x, y, rw, rh, rx, ry, rw, rh, 0, 0, theframe)
End Function

Function DrawImageAreaPow2Size:Int(n:Int)
	n:-1
	n :| (n Shr 1)
	n :| (n Shr 2)
	n :| (n Shr 4)
	n :| (n Shr 8)
	n :| (n Shr 16)
	Return n+1
End Function

' -----------------------------------------------------------------------------
' ClipImageToViewport: Clips an image into a "safe" viewport (doesn't use BMax viewport)
' -----------------------------------------------------------------------------
Function ClipImageToViewport(image:TImage, imagex:Float, imagey:Float, ViewportX:Float, ViewPortY:Float, ViewPortW:Float, ViewPortH:Float, offsetx:Float = 0, offsety:Float = 0, theframe:Int = 0)
	'Perform basic clipping first by checking to see if the image is completely outside of the viewport.
	'Note that images are drawn from the top left, not midhandled or anything else.
	Local w:Int = ImageWidth(image)
	Local h:Int = ImageHeight(image)

	If imagex+w>=ViewportX And imagex-w<ViewportX+ViewportW And..
		imagey+h>=ViewportY And imagey-h<ViewportY+ViewportH Then
		'Clip left and top
		Local startx#=ViewportX-imagex
		Local starty#=ViewportY-imagey
		If startx<0 Then startx=0 'clamp normal values
		If starty<0 Then starty=0 'clamp normal values
		'Clip right and bottom
		Local endx#=(imagex+w)-(ViewportX+ViewportW)
		Local endy#=(imagey+h)-(ViewportY+ViewportH)
		If endx<0 Then endx=0 'clamp normal values
		If endy<0 Then endy=0 'clamp normal values
		DrawImageArea(Image, imageX + startX + offsetx, imagey + starty + offsety, startx, starty, w - startx - endx, h - starty - endy, theframe)
	EndIf
End Function

  'Draws an Image if its in the viewport of the screen (not on Interface)
Function DrawImageInViewPort(_image:TImage, _x:Int, _yItStandsOn:Int, align:Byte=0, Frame:Int=0)
    If _yItStandsOn > 10 And _yItStandsOn - ImageHeight(_image) < 373+10
	  If align = 0 '_x is left side of image
	    DrawImage(_image, _x, _yItStandsOn - ImageHeight(_image), Frame)
	  ElseIf align = 1 '_x is right side of image
	    DrawImage(_image, _x-ImageWidth(_image), _yItStandsOn - ImageHeight(_image),Frame)
	  EndIf
    EndIf
End Function


Function DrawOnPixmap(image:TImage, framenr:Int = 0, Pixmap:TPixmap, x:Int, y:Int, alpha:Float = 1.0, light:Float = 1.0, multiply:Int = 0)
      Local TempPix:TPixmap = Null
	  If image = Null Then Throw "image doesnt exist"
	  If framenr = 0 Then TempPix = LockImage(image)
      If framenr > 0 Then TempPix = LockImage(image, Framenr)
	  For Local i:Int = 0 To ImageWidth(image) - 1
	    For Local j:Int = 0 To ImageHeight(image) - 1
		  If x + i < pixmap.width And y + j < pixmap.Height 'And i >= x And j >= y
			Local sourcepixel:Int = ReadPixel(TempPix, i, j)

			Local destpixel:Int = ReadPixel(pixmap, x + i, y + j)
			Local destA:Float = ARGB_Alpha(destpixel)
			Local sourceA:Float = ARGB_Alpha(sourcepixel) * alpha
			If sourceA = 255 Then destA = 0
			'remove comment to remove unneeded calculations
			'but only when light/alpha not used!
'			If sourceA <> 255 And sourceA <> 0
				Local destR:Float = ARGB_Red(destpixel)
				Local destG:Float = ARGB_Green(destpixel)
				Local destB:Float = ARGB_Blue(destpixel)
				Local SourceR:Float = ARGB_Red(Sourcepixel)
				Local SourceG:Float = ARGB_Green(Sourcepixel)
				Local SourceB:Float = ARGB_Blue(Sourcepixel)
					Local AlphaSum:Int = destA + sourceA
					If multiply = 1
						sourceR = (sourceR * light * sourceA / AlphaSum) + destA / AlphaSum * (destR * destA / AlphaSum)
						sourceG = (sourceG * light * sourceA / AlphaSum) + destA / AlphaSum * (destG * destA / AlphaSum)
						sourceB = (sourceB * light * sourceA / AlphaSum) + destA / AlphaSum * (destB * destA / AlphaSum)
					Else
						sourceR = (sourceR * light * sourceA / AlphaSum) + (destR * destA / AlphaSum)
						sourceG = (sourceG * light * sourceA / AlphaSum) + (destG * destA / AlphaSum)
						sourceB = (sourceB * light * sourceA / AlphaSum) + (destB * destA / AlphaSum)
					EndIf
					If AlphaSum > 255 Then AlphaSum = 255
					sourcepixel = ARGB_Color(AlphaSum, SourceR, sourceG, sourceB)
'			EndIf
			If SourceA <> 0 Then WritePixel(Pixmap, x + i, y + j, sourcepixel)
		  EndIf
		Next
	  Next
	  If framenr = 0 UnlockImage(image)
	  If framenr > 0 UnlockImage(image, framenr)
End Function

Function DrawPixmapOnPixmap(Source:TPixmap,Pixmap:TPixmap, x:Int, y:Int, color:TColor = null)
	Local SourceR:float		= 0.0
	Local SourceG:float		= 0.0
	Local SourceB:float		= 0.0
	Local SourceA:float		= 0.0
	Local DestR:float		= 0.0
	Local DestG:float		= 0.0
	Local DestB:float		= 0.0
	Local DestA:float		= 0.0
	Local modifyAlpha:Float = 1.0
	if color then modifyAlpha = color.a

	For Local i:Int = 0 To Source.width-1
		For Local j:Int = 0 To Source.height-1
			If x+1 < pixmap.width And y+j < pixmap.height
				Local sourcepixel:Int = ReadPixel(Source, i,j)
				Local destpixel:Int = ReadPixel(pixmap, x+i,y+j)
				sourceA = ARGB_Alpha(sourcepixel) * modifyAlpha
				If sourceA <> -1
					If sourceA< -1 Then sourceA = -sourceA
					destR	= ARGB_Red(destpixel)
					destG	= ARGB_Green(destpixel)
					destB	= ARGB_Blue(destpixel)
					destA	= ARGB_Alpha(destpixel)
					SourceR	= ARGB_Red(Sourcepixel)
					SourceG	= ARGB_Green(Sourcepixel)
					SourceB	= ARGB_Blue(Sourcepixel)
					if color
							SourceR :*color.r/255.0
							SourceG :*color.g/255.0
							SourceB :*color.b/255.0
					endif
					sourceR = Int( Float(sourceA/255.0)*sourceR) + Int(Float((255-sourceA)/255.0)*destR)
					sourceG = Int( Float(sourceA/255.0)*sourceG) + Int(Float((255-sourceA)/255.0)*destG)
					sourceB = Int( Float(sourceA/255.0)*sourceB) + Int(Float((255-sourceA)/255.0)*destB)
					'also mix alpha
					sourceA = SourceA + ((255-sourceA)/255) * destA
					sourcepixel = ARGB_Color(sourceA, sourceR, sourceG, sourceB)
				EndIf
				If sourceA <> 0 Then WritePixel(Pixmap, x+i,y+j, sourcepixel)
			EndIf
		Next
	Next
End Function

Function blurPixmap(pm:TPixmap, k:Float = 0.5)

	'pm - the pixmap to blur. Format must be PF_RGBA8888
	'k - blurring amount. Value between 0.0 and 1.0
	'	 0.1 = Extreme, 0.9 = Minimal

	For Local x:Int = 1 To (pm.Width - 1)
    	For Local z:Int = 0 To (pm.Height - 1)
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x - 1, z), k))
    	Next
    Next

    For Local x:Int = (pm.Width - 3) To 0 Step -1
    	For Local z:Int = 0 To (pm.Height - 1)
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x + 1, z), k))
    	Next
    Next

    For Local x:Int = 0 To (pm.Width - 1)
    	For Local z:Int = 1 To (pm.Height - 1)
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z - 1), k))
    	Next
    Next

    For Local x:Int = 0 To (pm.Width - 1)
    	For Local z:Int = (pm.Height - 3) To 0 Step -1
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z + 1), k))
    	Next
    Next

End Function

Function blurPixel:Int(px:Int, px2:Int, k:Float)

	'Utility function used by blurPixmap.
	'Uncomment the commented lines to enable alpha component
	'processing (usually not required).

	Local pxa:Byte = px Shr 24
	Local pxb:Byte = px Shr 16
	Local pxg:Byte = px Shr 8
	Local pxr:Byte = px

	'Local px2a:Byte = px2 Shr 24
	Local px2b:Byte = px2 Shr 16
	Local px2g:Byte = px2 Shr 8
	Local px2r:Byte = px2

	'pxa = (px2a * (1 - k)) + (pxa * k)
	pxb = (px2b * (1 - k)) + (pxb * k)
	pxg = (px2g * (1 - k)) + (pxg * k)
	pxr = (px2r * (1 - k)) + (pxr * k)

	Return Int(pxa Shl 24 | pxb Shl 16 | pxg Shl 8 | pxr)

EndFunction

Function DrawTextOnPixmap(Text:String, x:Int, y:Int, Pixmap:TPixmap, blur:Byte=0)
	If blur
		Local r:Int = 0, g:Int = 0, b:Int = 0
		GetColor(r,g,b)
		SetColor(50,50,50)
		DrawText(Text,x-1,y-1)
		DrawText(Text,x+1,y+1)
		SetColor(r,g,b)
	Else
		DrawText(Text,x,y)
	EndIf
		Local TxtWidth:Int   = TextWidth(Text)
		Local Source:TPixmap = GrabPixmap(x-2,y-2,TxtWidth+4,TextHeight(Text)+4)
		Source = ConvertPixmap(Source, PF_RGB888)
	If blur
		blurPixmap(Source, 0.5)
		Source = ConvertPixmap(Source, PF_RGB888)
		DrawPixmap(Source, x-2,y-2)
		DrawText(Text,x,y)
		Source = GrabPixmap(x-2,y-2,TxtWidth+4,TextHeight(Text)+4)
		Source = ConvertPixmap(Source, PF_RGB888)
	EndIf
	DrawPixmapOnPixmap(Source, Pixmap,x-20,y-10)
End Function

Const MINFRAGSIZE:Int = 64 ' maximum image fragment size
Const MAXFRAGSIZE:Int = 256 ' maximum image fragment size
Type ImageFragment

    Field img:TImage
    Field x:Float,y:Float,w:Float,h:Float

    ' ----------------------------------
    ' constructor
    ' ----------------------------------
    Function Create:ImageFragment(pmap:TPixmap,x:Float,y:Float,w:Float,h:Float)

        Local frag:ImageFragment = New ImageFragment
        frag.img = LoadImage(PixmapWindow(pmap,x,y,w,h),0)'|FILTEREDIMAGE)
        frag.x = x
        frag.y = y
        frag.w = w
        frag.h = h

        Return frag

    End Function

    ' --------------------
    ' Draw individual tile
    ' --------------------
    Method render(xoff:Float = 0, yoff:Float = 0, Scale:Float = 1.0)
	    Local vx:Int = 0, vy:Int = 0, vh:Int = 0
	    GetViewport(vx,vy,vx,vh)
		If yoff + Scale * Self.y + Self.h > 0 And yoff + Scale * Self.y < vy + vh Then
          DrawImage(Self.img, xoff + Scale * Self.x, yoff + Scale * Self.y)
		EndIf
    End Method

    Method renderInViewPort(xoff:Float = 0, yoff:Float = 0, vx:Float, vy:Float, vw:Float, vh:Float)
		'DrawSubImageRect(Self.img,xoff + Self.x, yoff + Self.y, vw, vh,  vx,vy,vw,vh,0,0,0)

		ClipImageToViewport(Self.img, xoff + Self.x, yoff + Self.y, vx, vy, vw, vh, 0, 0, 0)
	End Method

End Type

Type TBigImage

    Field pixmap:TPixmap
    Field px:Float,py:Float
    Field fragments:TList
    Field width:Float
    Field height:Float
	Field PixFormat:Int
    Field x:Float = 0
    Field y:Float = 0

    ' ----------------------------------
    ' constructor
    ' ----------------------------------
	Function CreateFromImage:TBigImage(i:TImage)
	  Local pix:TPixmap = i.pixmaps[0]
	  Return TBigImage.Create(pix)
	End Function

	Function CreateFromPixmap:TBigImage(i:TPixmap)
	  Return TBigImage.Create(i)
	End Function

	Function Create:TBigImage(p:TPixmap)

        Local bi:TBigImage = New TBigImage
        bi.pixmap = p
        bi.width = p.width
        bi.height = p.height
        bi.fragments = CreateList()
        bi.Load()
		bi.PixFormat = p.format
		bi.pixmap = Null
        Return bi

    End Function

    Method RestorePixmap:TPixmap()
	  Local Pix:TPixmap = TPixmap.Create(Self.width, Self.height, Self.PixFormat)
	  For Local ImgFrag:ImageFragment = EachIn Self.fragments
	    DrawOnPixmap(ImgFrag.img,0, Pix, ImgFrag.x, ImgFrag.y)
      Next
	  Return Pix
	End Method

	' -------------------------------------
    ' convert pixmap into image fragments
    ' -------------------------------------
    Method Load()
		'Print "Adding Fragments..."

        Local px:Float = 0
        Local py:Float = 0
        Local loading:Byte = True

        While (loading)
            Local w:Int = MAXFRAGSIZE
            Local h:Int = MAXFRAGSIZE
            If Self.pixmap.width - px < MAXFRAGSIZE w = Self.pixmap.width - px
            If Self.pixmap.Height - py < MAXFRAGSIZE h = Self.pixmap.Height - py
            Local f1:ImageFragment = ImageFragment.Create(Self.pixmap, px, py, w, h)
			'Print "Added Fragment: w" + w + " h" + h
            ListAddLast Self.fragments, f1
            px:+MAXFRAGSIZE
            If px >= Self.pixmap.width
                px = 0
                py:+MAXFRAGSIZE
                If py >= Self.pixmap.height loading = False
            End If

        Wend

    End Method

    ' -----------------
    ' Draw entire image
    ' -----------------
    Method render(x:Float = 0, y:Float = 0, Scale:Float = 1.0)
        For Local f:ImageFragment = EachIn Self.fragments
            f.render(x, y, Scale)
        Next
    End Method

    ' -----------------
    ' Draw entire image
    ' -----------------
    Method renderInViewPort(x:Float = 0, y:Float = 0, vx:Float, vy:Float, vw:Float, vh:Float)
        For Local f:ImageFragment = EachIn Self.fragments
            f.renderInViewPort(x, y, vx, vy, vw, vh)
        Next
    End Method
End Type




'colorizes an TImage (may be an AnimImage when given cell_width and height)
Function ColorizeTImage:TImage(_image:TImage, color:TColor, cell_width:Int=0,cell_height:Int=0,first_cell:Int=0,cell_count:Int=1, flag:Int=0, loadAnimated:Int = 1)
	If _image = Null then return Null

	'get pixmap of image - unlock not needed as it does nothing (26.09.2012)
	local pixmap:TPixmap = LockImage(_image)

	'load
	If cell_width > 0 And cell_count > 0 And loadAnimated
		Return LoadAnimImage( ColorizePixmap(pixmap, color), cell_width, cell_height, first_cell,cell_count, flag)
	else
		Return LoadImage( ColorizePixmap(pixmap, color) )
	endif
End Function

'colorize an Pixmap and return a pixmap
Function ColorizePixmap:TPixmap(pixmap:TPixmap,color:TColor)
	'create a copy to work on
	local newpixmap:TPixmap = pixmap.Copy()

	'convert format of wrong one -> make sure the pixmaps are 32 bit format
	If newpixmap.format <> PF_RGBA8888 Then newpixmap.convert(PF_RGBA8888)

	'create INT pointer to pixels - we have a RGBA format
	'Int Pointer contain 4 bytes -> RGBA
	'Byte Pointer would point to individual bytes
	local pixelPointer:Int Ptr = Int Ptr( newpixmap.PixelPtr(0,0) )

	For local x:int = 0 to pixmap.width * pixmap.height
		'skip empty pixels - even possible?
		'if not pixelPointer[0] then continue

		'get "graytone" of the pixel at pixelPointer position
		local colorTone:int = isMonochrome( pixelPointer[0] )

		'colorize if monochrome and not black (>0) and not white (255)
		'colorize with RGBA! not ARGB!
		If colorTone > 0 and colorTone < 255 then pixelPointer[0] = RGBA_Color( ARGB_Alpha(pixelPointer[0]), Int(colorTone * color.r / 255), Int(colortone * color.g / 255), Int(colortone * color.b / 255))

		'move next pixel
		pixelPointer:+1
	Next
	return newpixmap
End Function



'for single frames
Function CopyImage2:TImage(src:TImage)
	return LoadImage( LockImage(src).copy() , src.flags )
End Function

'copies an TImage to not manipulate the source image
Function CopyImage:TImage(src:TImage)
   If src = Null Then Return Null

   Local dst:TImage = New TImage
   MemCopy(dst, src, SizeOf(dst))

   dst.pixmaps = New TPixmap[src.pixmaps.length]
   dst.frames = New TImageFrame[src.frames.length]
   dst.seqs = New Int[src.seqs.length]

   For Local i:Int = 0 To dst.pixmaps.length-1
      dst.pixmaps[i] = CopyPixmap(src.pixmaps[i])
   Next

   For Local i:Int = 0 To dst.frames.length-1
      dst.Frame(i)
   Next

   MemCopy(dst.seqs, src.seqs, SizeOf(dst.seqs))

   Return dst
End Function
