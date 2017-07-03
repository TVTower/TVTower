SuperStrict
Import BRL.Max2D
Import "base.util.rectangle.bmx"
Import "base.util.color.bmx"


rem
Import brl.Graphics

Import brl.d3d7max2d
Import brl.glmax2d
Import brl.Max2D

Import brl.StandardIO
Import brl.Max2D

Import "basefunctions.bmx"
endrem


Function DrawImageArea(image:TImage, x:Float, y:Float, rx:Float, ry:Float, rw:Float, rh:Float, theframe:Int = 0)
	DrawSubImageRect(image, x, y, rw, rh, rx, ry, rw, rh, 0, 0, theframe)
End Function


'returns the next pow2
'-> 3 = 4, 9 = 16, 120 = 128, ...
Function NextPowerOfTwo:Int(n:Int)
	n:-1
	n :| (n Shr 1)
	n :| (n Shr 2)
	n :| (n Shr 4)
	n :| (n Shr 8)
	n :| (n Shr 16)
	Return n+1
End Function


'clips an image into a "safe" viewport (doesn't use BMax viewport)
Function ClipImageToViewport(image:TImage, x:Float, y:Float, vp:TRectangle, offsetX:Float=0, offsetY:Float=0, frame:Int=0)
	'Perform basic clipping first by checking to see if the image is completely outside of the viewport.
	'Note that images are drawn from the top left, not midhandled or anything else.
	Local w:Int = ImageWidth(image)
	Local h:Int = ImageHeight(image)

	If vp.ContainsXY(x,y) and vp.ContainsXY(x + w, y + h)
		'Clip left and top
		Local startX:float = Max(0, vp.GetX() - x)
		Local startY:float = Max(0, vp.GetY() - y)
		'Clip right and bottom
		Local endX:float = Max(0, (x + w) - vp.GetX2())
		Local endY:float = Max(0, (y + h) - vp.GetY2())

		DrawImageArea(Image, x + startX + offsetX, y + startY + offsetY, startX, startY, w - startX - endX, h - startY - endY, frame)
	EndIf
End Function




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
			If x+i < 0 or y+j < 0 then continue

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
					WritePixel(destination, x+i,y+j, ARGB_Color(int(sourceA*255.0), mixR, mixG, mixB))
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

				WritePixel(destination, x+i,y+j, ARGB_Color(int(mixA*255.0), mixR, mixG, mixB))
			endif
		Next
	Next
	return TRUE
End Function




Function blurPixmap:TPixmap(pm:TPixmap, k:Float = 0.5)
	'pm - the pixmap to blur. Format must be PF_RGBA8888
	'k - blurring amount. Value between 0.0 and 1.0
	'	 0.1 = Extreme, 0.9 = Minimal

	For Local x:Int = 1 Until pm.Width
    	For Local z:Int = 0 Until pm.Height
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x - 1, z), k))
    	Next
    Next

    For Local x:Int = (pm.Width - 3) To 0 Step -1
    	For Local z:Int = 0 Until pm.Height
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x + 1, z), k))
    	Next
    Next

    For Local x:Int = 0 Until pm.Width
    	For Local z:Int = 1 Until pm.Height
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z - 1), k))
    	Next
    Next

    For Local x:Int = 0 Until pm.Width
    	For Local z:Int = (pm.Height - 3) To 0 Step -1
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z + 1), k))
    	Next
    Next


	'function in a function - it is just a helper
	Function blurPixel:Int(px:Int, px2:Int, k:Float)
		Return Int( ..
		            int((Byte(px2 Shr 24) * (1 - k)) + (Byte(px Shr 24) * k)) Shl 24 | ..
		            int((Byte(px2 Shr 16) * (1 - k)) + (Byte(px Shr 16) * k)) Shl 16 | ..
		            int((Byte(px2 Shr  8) * (1 - k)) + (Byte(px Shr  8) * k)) Shl  8 | ..
		            int((Byte(px2)        * (1 - k)) + (Byte(px)        * k)) ..
		          )
	End Function

	return pm
End Function



Const COLORIZEMODE_MULTIPLY:int = 0
Const COLORIZEMODE_NEGATIVEMULTIPLY:int = 1
Const COLORIZEMODE_OVERLAY:int = 2

'colorizes an TImage (may be an AnimImage when given cell_width and height)
Function ColorizeImageCopy:TImage(imageOrPixmap:object, color:TColor, cellW:Int=0, cellH:Int=0, cellFirst:Int=0, cellCount:Int=1, flag:Int=0, colorizationMode:int = 0)
	local pixmap:TPixmap
	if TPixmap(imageOrPixmap) then pixmap = TPixmap(imageOrPixmap)
	if TImage(imageOrPixmap) then pixmap = LockImage(TImage(imageOrPixmap))
	If not pixmap then return Null

	'load
	If cellW > 0 And cellCount > 0
		Return LoadAnimImage( ColorizePixmapCopy(pixmap, color, colorizationMode), cellW, cellH, cellFirst, cellCount, flag)
	else
		Return LoadImage( ColorizePixmapCopy(pixmap, color, colorizationMode) )
	endif
End Function




'creates a pixmap copy and colorizes it
Function ColorizePixmapCopy:TPixmap(sourcePixmap:TPixmap, color:TColor, colorizationMode:int = 0)
	'create a copy to work on
	local colorizedPixmap:TPixmap = sourcePixmap.Copy()

	'convert format of wrong one -> make sure the pixmaps are 32 bit format
	If colorizedPixmap.format <> PF_RGBA8888 Then colorizedPixmap.convert(PF_RGBA8888)

	local pixel:int
	local colorTone:int = 0
	

	'for performance reasons we have the for-loops AFTER the colorizationMode
	'selection, so selecting the mode does not get run for each pixel
	Select colorizationMode
		case COLORIZEMODE_MULTIPLY
			For Local x:Int = 0 To colorizedPixmap.width - 1
				For Local y:Int = 0 To colorizedPixmap.height - 1
					pixel = ReadPixel(colorizedPixmap, x,y)
					'skip invisible
					if ARGB_Alpha(pixel) = 0 then continue

					colorTone = isMonochrome(pixel, True)
					'disabling "and..." allows to tint pure white too
					If colorTone > 0 'and colorTone < 255
						WritePixel(colorizedPixmap, x,y, ARGB_Color(..
							ARGB_Alpha(pixel),..
							colorTone * color.r / 255, ..
							colortone * color.g / 255, ..
							colortone * color.b / 255 ..
						))
					elseif colorTone = 0 and ARGB_Alpha(pixel) = 255
						'somehow writing 255,0,0,0 keeps things transparent
						WritePixel(colorizedPixmap, x,y, ARGB_Color( 255, 0, 0, 1))
					endif
				Next
			Next

		'"Negative Multiply" (Photoshop calls this "SCREEN") sets black
		'to the given color, and white to white.
		'rgb 0,0,0 -> color, rgb 128,128,18 -> 50% color + 50% white ...
		'Formula: resultColor = 255 - (((255 - topColor)*(255 - bottomColor))/255)
    	case COLORIZEMODE_NEGATIVEMULTIPLY
			For Local x:Int = 0 To colorizedPixmap.width - 1
				For Local y:Int = 0 To colorizedPixmap.height - 1
					pixel = ReadPixel(colorizedPixmap, x,y)
					'skip invisible
					if ARGB_Alpha(pixel) = 0 then continue

					colorTone = isMonochrome(pixel, True)
					If colorTone > 0 'and colorTone < 255
						WritePixel(colorizedPixmap, x,y, ARGB_Color(..
							ARGB_Alpha(pixel),..
							255 - (255 - color.r) * (255 - colorTone) / 255, ..
							255 - (255 - color.g) * (255 - colorTone) / 255, ..
							255 - (255 - color.b) * (255 - colorTone) / 255 ..
						))
					elseif colorTone = 0 and ARGB_Alpha(pixel) = 255
						'somehow writing 255,0,0,0 keeps things transparent
						WritePixel(colorizedPixmap, x,y, ARGB_Color( 255, color.r, color.g, color.b))
					endif
				Next
			Next			

		'overlay darkens pixels below 128 and brightens pixels above 128
		'so with 0 you get black, with 255 you get white, and 128 is
		'the color you want to colorize to
		'Formula: resultColor =
		'				if (bottomColor < 128) then (2 * topColor * bottomColor / 255) 
		'				else (255 - 2 * (255 - topColor) * (255 - bottomColor) / 255)
		case COLORIZEMODE_OVERLAY
			For Local x:Int = 0 To colorizedPixmap.width - 1
				For Local y:Int = 0 To colorizedPixmap.height - 1
					pixel = ReadPixel(colorizedPixmap, x,y)
					'skip invisible
					if ARGB_Alpha(pixel) = 0 then continue

					colorTone = isMonochrome(pixel, True)
					If colorTone > 0' and colorTone < 255
						if colorTone < 128
							WritePixel(colorizedPixmap, x,y, ARGB_Color(..
								ARGB_Alpha(pixel),..
								(2* colorTone * color.r) / 255, ..
								(2* colortone * color.g) / 255, ..
								(2* colortone * color.b) / 255 ..
							))
						else
							WritePixel(colorizedPixmap, x,y, ARGB_Color(..
								ARGB_Alpha(pixel),..
								255 - 2 * (255 - color.r) * (255 - colorTone) / 255, ..
								255 - 2 * (255 - color.g) * (255 - colorTone) / 255, ..
								255 - 2 * (255 - color.b) * (255 - colorTone) / 255 ..
							))
						endif
					elseif colorTone = 0 and ARGB_Alpha(pixel) = 255
						'somehow writing 255,0,0,0 keeps things transparent
						WritePixel(colorizedPixmap, x,y, ARGB_Color( 255, 0, 0, 1))
					endif
				Next
			Next
	End Select

	return colorizedPixmap
End Function




'copies an TImage to not manipulate the source image
Function CopyImage:TImage(src:TImage)
	If src = Null Then Return Null

	Local dst:TImage = New TImage
	?bmxng
	MemCopy(dst, src, Size_T(SizeOf(dst)))
	?not bmxng
	MemCopy(dst, src, SizeOf(dst))
	?

	dst.pixmaps = New TPixmap[src.pixmaps.length]
	dst.frames = New TImageFrame[src.frames.length]
	dst.seqs = New Int[src.seqs.length]

	For Local i:Int = 0 To dst.pixmaps.length-1
	  dst.pixmaps[i] = CopyPixmap(src.pixmaps[i])
	Next

	For Local i:Int = 0 To dst.frames.length-1
	  dst.Frame(i)
	Next

	?bmxng
	MemCopy(dst.seqs, src.seqs, Size_T(SizeOf(dst.seqs)))
	?not bmxng
	MemCopy(dst.seqs, src.seqs, SizeOf(dst.seqs))
	?

	Return dst
End Function


Function TrimImage:TImage(src:object, offset:TRectangle var, trimColor:TColor = null, paddingSize:int = 0)
	local pix:TPixmap
	if TImage(src) then pix = LockImage(TImage(src))
	if TPixmap(src) then pix = TPixmap(src)
	if not pix then return Null

	if pix.width = 0 or pix.height = 0 then return Null

	'=== convert pixmap to correct format ===
	pix = ConvertPixmap(pix, PF_RGBA8888)
	
	'without given trimColor, we use the color at pixel 0,0
	if not trimColor then trimColor = new TColor.FromInt(pix.ReadPixel(0,0))

	'=== find trimmable portions ===
	local pixel:int
	local contentTop:int = 0, contentBottom:int = pix.height
	local contentLeft:int = 0, contentRight:int = pix.width


	'= left =
	For Local x:Int = 0 until pix.width
		local found:int = False
		For Local y:Int = 0 until pix.height
			pixel = pix.ReadPixel(x,y)

			'other color than the one to trim?
			if (trimColor.a >= 0 and (pixel Shr 24) & $ff <> int(trimColor.a)) or ..
			   (trimColor.r >= 0 and (pixel Shr 16) & $ff <> trimColor.b) or ..
			   (trimColor.g >= 0 and (pixel Shr 8) & $ff <> trimColor.g) or ..
			   (trimColor.b >= 0 and pixel & $ff <> trimColor.b)
			     contentLeft = x
			     found = True
			     exit
			endif
		Next
		if found then exit
	Next
	'= right =
	For Local x:Int = pix.width-1 to 0 step -1
		local found:int = False
		For Local y:Int = 0 until pix.height
			pixel = pix.ReadPixel(x,y)

			'other color than the one to trim?
			if (trimColor.a >= 0 and (pixel Shr 24) & $ff <> int(trimColor.a)) or ..
			   (trimColor.r >= 0 and (pixel Shr 16) & $ff <> trimColor.b) or ..
			   (trimColor.g >= 0 and (pixel Shr 8) & $ff <> trimColor.g) or ..
			   (trimColor.b >= 0 and pixel & $ff <> trimColor.b)
			     contentRight = x
			     found = True
			     exit
			endif
		Next
		if found then exit
	Next
	'= top =
	For Local y:Int = 0 until pix.height
		local found:int = False
		For Local x:Int = 0 until pix.width
			pixel = pix.ReadPixel(x,y)

			'other color than the one to trim?
			if (trimColor.a >= 0 and (pixel Shr 24) & $ff <> int(trimColor.a)) or ..
			   (trimColor.r >= 0 and (pixel Shr 16) & $ff <> trimColor.b) or ..
			   (trimColor.g >= 0 and (pixel Shr 8) & $ff <> trimColor.g) or ..
			   (trimColor.b >= 0 and pixel & $ff <> trimColor.b)
			     contentTop = y
			     found = True
			     exit
			endif
		Next
		if found then exit
	Next
	'= bottom =
	For Local y:Int = pix.height-1 to 0 step -1
		local found:int = False
		For Local x:Int = 0 until pix.width
			pixel = pix.ReadPixel(x,y)

			'other color than the one to trim?
			if (trimColor.a >= 0 and (pixel Shr 24) & $ff <> int(trimColor.a)) or ..
			   (trimColor.r >= 0 and (pixel Shr 16) & $ff <> trimColor.b) or ..
			   (trimColor.g >= 0 and (pixel Shr 8) & $ff <> trimColor.g) or ..
			   (trimColor.b >= 0 and pixel & $ff <> trimColor.b)
			     contentBottom = y
			     found = True
			     exit
			endif
		Next
		if found then exit
	Next

	'=== actually trim it ===
	local newPix:TPixmap = PixmapWindow(pix, contentLeft, contentTop, contentRight - contentLeft + 1, contentBottom - ContentTop + 1)

	if paddingSize > 0
	print "padding"
		local paddedPix:TPixmap = CreatePixmap(newPix.width + 2*paddingSize, newPix.height + 2*paddingSize, newPix.format)
		paddedPix.ClearPixels(0)

		paddedPix.Paste(newPix, paddingSize, paddingSize)

		newPix = paddedPix
	endif

	
	local trimmedImage:TImage = LoadImage(newPix)

	offset.SetTLBR(contentTop, contentLeft, contentBottom, contentRight)

	return trimmedImage
End Function