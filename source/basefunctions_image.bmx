SuperStrict
Import brl.Graphics

Import brl.d3d7max2d
Import brl.glmax2d
Import brl.Max2D

Import brl.StandardIO
Import brl.Max2D

Import "basefunctions.bmx"
Import "Dig/base.util.color.bmx"
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




'ClipImageToViewport: Clips an image into a "safe" viewport (doesn't use BMax viewport)
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




rem
 unused
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
endrem




'draws a given source pixmap/image onto a destination pixmap/image
'modifyColor is used to increase (rgb > 255) or decrease brightness
'modifyColor.alpha is used to adjust the alpha of the src object.
Function DrawImageOnImage:int(src:object, dest:object, x:Int, y:Int, modifyColor:TColor = null)
	local source:TPixmap, destination:TPixmap
	if TPixmap(src) then source = TPixmap(src)
	if TImage(src) then source = LockImage(TImage(src))
	if TPixmap(dest) then destination = TPixmap(dest)
	if TImage(dest) then destination = LockImage(TImage(dest))
	if not source or not destination then return FALSE

	Local sourcePixel:int, destPixel:int
	Local sourceA:float, destA:float, mixA:float
	local weightSourceA:float=0.0, weightDestA:float= 0.0
	Local mixR:int, mixG:int, mixB:int
	Local modifyAlpha:Float = 1.0; if modifyColor then modifyAlpha = modifyColor.a

	rem
	formula for multiplying colors
		short: r=result, fg=added color, bg=background
		r.A = 1 - (1 - fg.A) * (1 - bg.A);
		r.R = fg.R * fg.A / r.A + bg.R * bg.A * (1 - fg.A) / r.A;
		r.G = fg.G * fg.A / r.A + bg.G * bg.A * (1 - fg.A) / r.A;
		r.B = fg.B * fg.A / r.A + bg.B * bg.A * (1 - fg.A) / r.A;
	endrem

	For Local i:Int = 0 To Source.width-1
		For Local j:Int = 0 To Source.height-1
			'skip if out of range
			If x+i >= destination.width or y+j >= destination.height then continue

			sourcePixel = ReadPixel(source, i,j)
			'modify the source's alpha with the modifer
			sourceA		= (ARGB_Alpha(sourcepixel) / 255.0) * modifyAlpha
			destPixel	= ReadPixel(destination, x+i,y+j)
			destA 		= ARGB_Alpha(destPixel) / 255.0

			'if target is having no alpha yet, do not calculate
			'things, just use the new color...
			if destA = 0
				if modifyColor
					'tint
					mixR = ARGB_Red(sourcePixel) * modifyColor.r/255.0
					mixG = ARGB_Green(sourcePixel) * modifyColor.g/255.0
					mixB = ARGB_Blue(sourcePixel) * modifyColor.b/255.0
					WritePixel(destination, x+i,y+j, ARGB_Color(sourceA*255.0, mixR, mixG, mixB))
				else
					WritePixel(destination, x+i,y+j, sourcePixel)
				endif
			'if the current pixel of the source is invisible, do not
			'calculate things, just skip
			elseif sourceA <> 0
				mixA = 1.0 - (1.0 - sourceA) * (1.0 - destA)
				if destA > 0.0 then weightSourceA = sourceA / mixA else weightSourceA = 1.0
				if mixA > 0.0 then weightDestA = destA * (1.0 - sourceA) / mixA else weightDestA = 0.0

				'tint?
				if modifyColor
					'if so - modify the source's color accordingly
					mixR = (ARGB_Red(sourcePixel) * modifyColor.r/255.0) * weightSourceA + ARGB_Red(destPixel) * weightDestA
					mixG = (ARGB_Green(sourcePixel) * modifyColor.g/255.0) * weightSourceA + ARGB_Green(destPixel) * weightDestA
					mixB = (ARGB_Blue(sourcePixel) * modifyColor.b/255.0) * weightSourceA + ARGB_Blue(destPixel) * weightDestA
				else
					mixR = ARGB_Red(sourcePixel) * weightSourceA + ARGB_Red(destPixel) * weightDestA
					mixG = ARGB_Green(sourcePixel) * weightSourceA + ARGB_Green(destPixel) * weightDestA
					mixB = ARGB_Blue(sourcePixel) * weightSourceA + ARGB_Blue(destPixel) * weightDestA
				endif
				'limit to 0-255
				mixR = Min(255, Max(0, mixR))
				mixG = Min(255, Max(0, mixG))
				mixB = Min(255, Max(0, mixB))

				WritePixel(destination, x+i,y+j, ARGB_Color(mixA*255.0, mixR, mixG, mixB))
			endif
		Next
	Next
	return TRUE
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
rem
	Return ARGB_Color(1.0,..
				(ARGB_Red(px2) * (1 - k)) + (ARGB_Red(px) * k), ..
				(ARGB_Green(px2) * (1 - k)) + (ARGB_Green(px) * k) ,..
				(ARGB_Blue(px2) * (1 - k)) + (ARGB_Blue(px) * k) ..
				)
endrem


	Local pxa:Byte = px Shr 24
	Local pxb:Byte = px Shr 16
	Local pxg:Byte = px Shr 8
	Local pxr:Byte = px

	Local px2a:Byte = px2 Shr 24
	Local px2b:Byte = px2 Shr 16
	Local px2g:Byte = px2 Shr 8
	Local px2r:Byte = px2

	pxa = (px2a * (1 - k)) + (pxa * k)
	pxb = (px2b * (1 - k)) + (pxb * k)
	pxg = (px2g * (1 - k)) + (pxg * k)
	pxr = (px2r * (1 - k)) + (pxr * k)

	Return Int(pxa Shl 24 | pxb Shl 16 | pxg Shl 8 | pxr)

EndFunction




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
    Field px:Float, py:Float
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
			DrawImageOnImage(ImgFrag.img, Pix, ImgFrag.x, ImgFrag.y)
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
            EndIf
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




'colorizes a copy of the given image/pixmap
'(may be an AnimImage when given cell_width and height)
Function ColorizeImageCopy:TImage(imageOrPixmap:object, color:TColor, cellW:Int=0, cellH:Int=0, cellFirst:Int=0, cellCount:Int=1, flag:Int=0)

	local pixmap:TPixmap
	'create a copy of the given image/pixmap
	if TPixmap(imageOrPixmap) then pixmap = TPixmap(imageOrPixmap).copy()
	if TImage(imageOrPixmap) then pixmap = LockImage(TImage(imageOrPixmap)).copy()
	If not pixmap then return Null

	'colorize this pixmap
	ColorizePixmap(pixmap, color)

	'load
	If cellW > 0 And cellCount > 0
		Return LoadAnimImage( pixmap, cellW, cellH, cellFirst, cellCount, flag)
	else
		Return LoadImage( pixmap )
	endif
End Function




'colorizes a given pixmap (directly modifies the sourcePixmap)
Function ColorizePixmap:Int(pixmap:TPixmap var, color:TColor)
	'convert format of wrong one -> make sure the pixmaps are 32 bit format
	If pixmap.format <> PF_RGBA8888 Then pixmap.convert(PF_RGBA8888)

	local pixel:int
	local colorTone:int = 0
	For Local x:Int = 0 To pixmap.width - 1
		For Local y:Int = 0 To pixmap.height - 1
			pixel = ReadPixel(pixmap, x,y)
			'skip invisible
			if ARGB_Alpha(pixel) = 0 then continue

			colorTone = isMonochrome(pixel)
			If colorTone > 0 and colorTone < 255
				WritePixel(pixmap, x,y, ARGB_Color( ARGB_Alpha(pixel), colorTone * color.r / 255, colortone * color.g / 255, colortone * color.b / 255))
			endif
		Next
	Next
	return True
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
