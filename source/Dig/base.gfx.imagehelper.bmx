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
Const DRAWMODE_NORMAL:int = 0
Const DRAWMODE_MULTIPLY:int = 1
Const DRAWMODE_DIFFERENCE:int = 2


Function DrawImageOnImage:int(src:object, dest:object, x:Int, y:Int, modifyColor:TColor = null, drawMode:int=0)
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



Function ConvertToSingleColor:TImage(image:TImage, targetColor:int, backgroundColor:int = 0)
	'load source
	Local srcPix:TPixmap = LockImage(image)
	if not srcPix then return Null
	'if it is the wrong format to use, create a temporary copy
	If srcPix.format <> PF_RGBA8888
		srcPix = srcPix.Copy().Convert(PF_RGBA8888)
	EndIf

	'create target
	Local targetPix:TPixmap = CreatePixmap(srcPix.width, srcPix.height, srcPix.format)
	targetPix.ClearPixels(backgroundColor)

	For Local x:Int = 0 Until srcPix.width
		For Local y:Int = 0 Until srcPix.height
			'read alpha
			WritePixel(targetPix, x,y, ..
			           Int( ..
						int(Byte(ReadPixel(srcPix, x,y) Shr 24)) Shl 24 | ..
						int(Byte(targetColor Shr 16)) Shl 16 | ..
						int(Byte(targetColor Shr  8)) Shl  8 | ..
						int(Byte(targetColor)) ..
                      ))
		Next
	Next

	return LoadImage(targetPix)
End Function




'padding variable is there to avoid creating a target image over and over
'if you plan to add a "blur" afterwards (which needs some additional
'pixels on all sides)
Function ConvertToOutLine:TImage(image:TImage, lineThickness:int=1, alphaTreshold:Float = 0.0, outlineColor:int=-1, targetPadding:int=0)
	if outlineColor = -1 then outlineColor = -1 '(Int(255 * $1000000) + Int(255 * $10000) + Int(255 * $100) + Int(255))
	lineThickness = lineThickness / 2

	'convert 0.0-1.0 to 0-255
	alphaTreshold :* 255

	'load source
	Local srcPix:TPixmap = LockImage(image)
	if not srcPix then return Null
	'if it is the wrong format to use, create a temporary copy
	If srcPix.format <> PF_RGBA8888
		srcPix = srcPix.Copy().Convert(PF_RGBA8888)
	EndIf

	'create target
	Local targetPix:TPixmap = CreatePixmap(srcPix.width + targetPadding*2, srcPix.height + targetPadding*2, srcPix.format)
	targetPix.ClearPixels(0)

	'storage for alpha of a pixel's surrounding pixels 
	Local sum:int

	For Local x:Int = 0 Until srcPix.width
		For Local y:Int = 0 Until srcPix.height
			'ignore if above treshold
			'except for borders
'			If ARGB_Alpha(col) > alphaTreshold Then continue
			if (x <> 0 and x <> srcPix.width-1) and (y <> 0 and y <> srcPix.height-1)
				If ((ReadPixel(srcPix, x, y) Shr 24) & $ff) > alphaTreshold
					continue
				endif
			EndIf


			'check pixels left/right/top/bottom of current pixel
			'add all of their alphas to "sum" so we could check
			'whether there is something needing a outline
			sum = 0
'			If x > 0               Then sum :+ ARGB_Alpha( ReadPixel(srcPix, x-1, y) )
'			If x < srcPix.width-1  Then sum :+ ARGB_Alpha( ReadPixel(srcPix, x+1, y) )
'			If y > 0               Then sum :+ ARGB_Alpha( ReadPixel(srcPix, x, y-1) )
'			If y < srcPix.height-1 Then sum :+ ARGB_Alpha( ReadPixel(srcPix, x, y+1) )
			If x > 0               Then sum :+ ((ReadPixel(srcPix, x-1, y) Shr 24) & $ff) > alphaTreshold
			If x < srcPix.width-1  Then sum :+ ((ReadPixel(srcPix, x+1, y) Shr 24) & $ff) > alphaTreshold
			If y > 0               Then sum :+ ((ReadPixel(srcPix, x, y-1) Shr 24) & $ff) > alphaTreshold
			If y < srcPix.height-1 Then sum :+ ((ReadPixel(srcPix, x, y+1) Shr 24) & $ff) > alphaTreshold
				
			If sum > 0
				If lineThickness = 0
					WritePixel(targetPix, x + targetPadding, y + targetPadding, outlineColor )
				Else
					For local i:int = 0 to lineThickness
						If x + targetPadding - i >= 0               Then WritePixel(targetPix, x + targetPadding - i , y + targetPadding, outlineColor )
						If x + targetPadding + i < targetPix.width  Then WritePixel(targetPix, x + targetPadding + i , y + targetPadding, outlineColor )
						If y + targetPadding - i >= 0               Then WritePixel(targetPix, x + targetPadding, y + targetPadding - i, outlineColor )
						If y + targetPadding + i < targetPix.height Then WritePixel(targetPix, x + targetPadding, y + targetPadding + i, outlineColor )
					Next
				EndIf
			EndIf
		Next
	Next

	return LoadImage(targetPix)
End Function




Function blurPixmap:TPixmap(pm:TPixmap, k:Float = 0.5, backgroundColor:int=0)
	'pm - the pixmap to blur. Format must be PF_RGBA8888
	'k - blurring amount. Value between 0.0 and 1.0
	'	 0.1 = Extreme, 0.9 = Minimal

	For Local x:Int = 1 Until pm.Width
    	For Local z:Int = 0 Until pm.Height
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x - 1, z), k, backgroundColor))
    	Next
    Next

    For Local x:Int = (pm.Width - 3) To 0 Step -1
    	For Local z:Int = 0 Until pm.Height
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x + 1, z), k, backgroundColor))
    	Next
    Next

    For Local x:Int = 0 Until pm.Width
    	For Local z:Int = 1 Until pm.Height
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z - 1), k, backgroundColor))
    	Next
    Next

    For Local x:Int = 0 Until pm.Width
    	For Local z:Int = (pm.Height - 3) To 0 Step -1
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z + 1), k, backgroundColor))
    	Next
    Next


	'function in a function - it is just a helper
	Function blurPixel:Int(px:Int, px2:Int, k:Float, backgroundColor:int = 0)
		'if there is no actual "pixel color" (eg a fully transparent black)
		'then mix colors accordingly
		if px2 = backgroundColor
			Return Int( ..
						int(Byte(px2 Shr 24)) Shl 24 | ..
						int(Byte(px Shr 16)) Shl 16 | ..
						int(Byte(px Shr  8)) Shl  8 | ..
						int(Byte(px)) ..
					  )
		elseif px = backgroundColor
			Return Int( ..
						int(Byte(px Shr 24)) Shl 24 | ..
						int(Byte(px2 Shr 16)) Shl 16 | ..
						int(Byte(px2 Shr  8)) Shl  8 | ..
						int(Byte(px2)) ..
					  )
		else
			Return Int( ..
						int((Byte(px2 Shr 24) * (1 - k)) + (Byte(px Shr 24) * k)) Shl 24 | ..
						int((Byte(px2 Shr 16) * (1 - k)) + (Byte(px Shr 16) * k)) Shl 16 | ..
						int((Byte(px2 Shr  8) * (1 - k)) + (Byte(px Shr  8) * k)) Shl  8 | ..
						int((Byte(px2)        * (1 - k)) + (Byte(px)        * k)) ..
					  )
		endif
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




'modifies saturation of the given pixmap
Function AdjustPixmapSaturation:TPixmap(pixmap:TPixmap, saturation:Float = 1.0)
	'convert format of wrong one -> make sure the pixmaps are 32 bit format
	If pixmap.format <> PF_RGBA8888 Then pixmap.convert(PF_RGBA8888)

	local pixel:int
	local color:TColor = new TColor
	local colorTone:int = 0
	
	For Local x:Int = 0 To pixmap.width - 1
		For Local y:Int = 0 To pixmap.height - 1
			color.FromInt(ReadPixel(pixmap, x,y))
			'skip invisible
			if color.a = 0 then continue
			'nothing to do for already gray pixels (no color information)
			if color.isMonochrome(False) >= 0
				WritePixel(pixmap, x,y, color.ToInt())
			else
				WritePixel(pixmap, x,y, color.AdjustSaturationRGB(saturation-1.0).ToInt())
			endif
		Next
	Next

	return pixmap
End Function




Function ExtractPixmapFromPixmap:TPixmap(pixmap:TPixmap, shape:TPixmap, offsetX:int=0, offsetY:int=0)
	if not pixmap or not shape then return Null
	
	local extractedPixmap:TPixmap = shape.Copy()
	'convert format of wrong one -> make sure the pixmaps are 32 bit format
	If extractedPixmap.format <> PF_RGBA8888 Then extractedPixmap.convert(PF_RGBA8888)

	local pixel:int
	local color:TColor = new TColor
	local shapeAlpha:Float
	local xMin:int = Max(0, offsetX)
	local xMax:int = Min(pixmap.width, offsetX + shape.width)
	local yMin:int = Max(0, offsetY)
	local yMax:int = Min(pixmap.height, offsetY + shape.height)
	
	For Local x:Int = xMin To xMax - 1
		For Local y:Int = yMin To yMax - 1
			color.FromInt(ReadPixel(shape, x-xMin,y-yMin))
			'skip invisible
			if color.a = 0 then continue

			shapeAlpha = color.a
			color.FromInt(ReadPixel(pixmap, x,y))

			'adjust effective color by the alpha components of the shape
			color.a :* shapeAlpha

			WritePixel(extractedPixmap, x-xMin,y-yMin, color.ToInt())
		Next
	Next

	return extractedPixmap
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


Function TrimImage:TImage(src:object, offset:TRectangle var, trimColor:TColor = null, paddingSize:int = 0, trimLeft:int=True, trimRight:int=True, trimTop:int=True, trimBottom:int=True)
	local pix:TPixmap
	local flags:int = 0
	if TImage(src) then pix = LockImage(TImage(src))
	if TImage(src) then flags = TImage(src).flags
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

	local tolerance:int = 4

	'= left =
	if trimLeft
		For Local x:Int = 0 until pix.width
			local found:int = False
			For Local y:Int = 0 until pix.height
				pixel = pix.ReadPixel(x,y)

				'other color than the one to trim?
				if (trimColor.a >= 0 and (Abs((pixel Shr 24) & $ff) - int(trimColor.a)) > tolerance) or ..
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
	endif

	'= right =
	if trimRight
		For Local x:Int = pix.width-1 to 0 step -1
			local found:int = False
			For Local y:Int = 0 until pix.height
				pixel = pix.ReadPixel(x,y)

				'other color than the one to trim?
				if (trimColor.a >= 0 and (Abs((pixel Shr 24) & $ff) - int(trimColor.a)) > tolerance) or ..
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
	endif
	
	'= top =
	if trimTop
		For Local y:Int = 0 until pix.height
			local found:int = False
			For Local x:Int = 0 until pix.width
				pixel = pix.ReadPixel(x,y)

				'other color than the one to trim?
				if (trimColor.a >= 0 and (Abs((pixel Shr 24) & $ff) - int(trimColor.a)) > tolerance) or ..
				   (trimColor.r >= 0 and ((pixel Shr 16) & $ff <> trimColor.b)) or ..
				   (trimColor.g >= 0 and ((pixel Shr 8) & $ff <> trimColor.g)) or ..
				   (trimColor.b >= 0 and (pixel & $ff <> trimColor.b))
					 contentTop = y
					 found = True
					 exit
				endif
			Next
			if found then exit
		Next
	endif

	'= bottom =
	if trimBottom
		For Local y:Int = pix.height-1 to 0 step -1
			local found:int = False
			For Local x:Int = 0 until pix.width
				pixel = pix.ReadPixel(x,y)

				'other color than the one to trim?
				if (trimColor.a >= 0 and (Abs((pixel Shr 24) & $ff) - int(trimColor.a)) > tolerance) or ..
				   (trimColor.r >= 0 and ((pixel Shr 16) & $ff) <> trimColor.b) or ..
				   (trimColor.g >= 0 and ((pixel Shr 8) & $ff) <> trimColor.g) or ..
				   (trimColor.b >= 0 and (pixel & $ff) <> trimColor.b)
					 contentBottom = y
print "found at " + x+","+y + "   pixel="+pixel+ "  ("+(new TColor.FromInt(pixel).ToString())+")   trimColor="+trimColor.ToInt()+" ("+trimColor.ToString()+")" +"   " + ((pixel Shr 24) & $ff)
					 found = True
					 exit
				endif
			Next
			if found then exit
		Next
	endif

	'=== actually trim it ===
	local effHeight:int = pix.height - (contentTop + (pix.height - contentBottom))
	local newPix:TPixmap = PixmapWindow(pix, contentLeft, contentTop, contentRight - contentLeft + 1, effHeight)

	if paddingSize > 0
		local paddedPix:TPixmap = CreatePixmap(newPix.width + 2*paddingSize, newPix.height + 2*paddingSize, newPix.format)
		paddedPix.ClearPixels(0)

		paddedPix.Paste(newPix, paddingSize, paddingSize)

		newPix = paddedPix
	endif

	local trimmedImage:TImage = LoadImage(newPix, flags)
rem
	local trimmedImage:TImage = CreateImage(newPix.width, newPix.height, 1, flags)

	local trimmedPix:TPixmap = LockImage(trimmedImage)
	trimmedPix.ClearPixels(0)
	For local x:int = 0 until newPix.width
		For local y:int = 0 until newPix.height
			trimmedPix.WritePixel(x,y, newPix.ReadPixel(x,y))
		Next
	Next
endrem

	offset.SetTLBR(contentTop, contentLeft, pix.height - contentBottom, pix.width - contentRight)

	return trimmedImage
End Function





Function ExtractPixmapFromPixmapByPolyShape:TPixmap(pixmap:TPixmap, polyShape:int[])
	if not pixmap or not polyShape or polyShape.length < 6 then return Null


	'get width/height of polyShape
	local minShapeX:int = polyShape[0]
	local maxShapeX:int = minShapeX
	local minShapeY:int = polyShape[1]
	local maxShapeY:int = minShapeY

	For local i:int = 0 until polyShape.length/2
		minShapeX = Min(minShapeX, polyShape[i*2])
		maxShapeX = Max(maxShapeX, polyShape[i*2])
		minShapeY = Min(minShapeY, polyShape[i*2+1])
		maxShapeY = Max(maxShapeY, polyShape[i*2+1])
	Next
	local shapeW:int = maxShapeX - minShapeX
	local shapeH:int = maxShapeY - minShapeY
	

	'create pixmap
	Local targetPix:TPixmap = CreatePixmap(shapeW, shapeH, pixmap.format)
	targetPix.ClearPixels(0)

	local pixel:int
	local color:TColor = new TColor
	local shapeAlpha:Float
	local xMin:int = Max(0, minShapeX)
	local xMax:int = Min(pixmap.width, maxShapeX)
	local yMin:int = Max(0, minShapeY)
	local yMax:int = Min(pixmap.height, maxShapeY)

	For Local x:Int = xMin To xMax - 1
		For Local y:Int = yMin To yMax - 1
			If IntPointInIntPoly(x,y, polyShape)
				WritePixel(targetPix, x-xMin, y-yMin, ReadPixel(pixmap, x, y))
			EndIf
		Next
	Next

	return targetPix
End Function




'conversion of
'https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
'PNPOLY - Point Inclusion in Polygon Test
'W. Randolph Franklin (WRF)
Function PointInPoly:int(x:Float, y:float, polyXY:float[])
	local numberVertices:int = polyXY.length/2

	local c:int
	local j:int = numberVertices - 1
	For local i:int = 0 until numberVertices
		if ( (polyXY[i*2 + 1] > y) <> (polyXY[j*2 + 1] > y)) and (x < (polyXY[j*2] - polyXY[i*2]) * (y - polyXY[i*2 + 1]) / (polyXY[j*2 + 1] - polyXY[i*2 + 1]) + polyXY[i*2])
			c = 1 - c
		endif

		j = i
	Next

	return c
End Function


Function IntPointInIntPoly:int(x:Int, y:Int, polyXY:Int[])
	local numberVertices:int = polyXY.length/2

	local c:int
	local j:int = numberVertices - 1
	For local i:int = 0 until numberVertices
		if ( (polyXY[i*2 + 1] > y) <> (polyXY[j*2 + 1] > y)) and (x < (polyXY[j*2] - polyXY[i*2]) * (y - polyXY[i*2 + 1]) / (polyXY[j*2 + 1] - polyXY[i*2 + 1]) + polyXY[i*2])
			c = 1 - c
		endif

		j = i
	Next

	return c
End Function



'Code by Oddball:
'http://www.mojolabs.nz/codearcs.php?code=1676
Function ODD_PointInPoly:int(pX:Float, pY:Float, polyXY:Float[] )
	'at least 3 corners/triangle needed
	If polyXY.length<6 Or (polyXY.length & 1) then Return False
	
	Local x1:Float = polyXY[polyXY.length-2]
	Local y1:Float = polyXY[polyXY.length-1]
	Local currentQuad:Int = GetPolyQuad(pX, pY, x1, y1)
	Local nextQuad:Int
	Local total:Int
	
	For Local i:int = 0 Until polyXY.length Step 2
		Local x2:Float = polyXY[i]
		Local y2:Float = polyXY[i+1]
		nextQuad = GetPolyQuad(pX, pY, x2, y2)

		Local diff:Int = nextQuad - currentQuad
		
		Select diff
			Case 2, -2
				If (x2 - ( ((y2 - pY) * (x1 - x2)) / (y1 - y2) ) ) < pX
					diff = -diff
				EndIf
			Case 3
				diff = -1
			Case -3
				diff = 1
		End Select
		
		total :+ diff
		currentQuad = nextQuad
		x1 = x2
		y1 = y2
	Next
	
	Return Abs(total) = 4


	Function GetPolyQuad:int(axis_x:Float,axis_y:Float,vert_x:Float,vert_y:Float)
		If vert_x<axis_x
			If vert_y<axis_y
				Return 1
			Else
				Return 4
			EndIf
		Else
			If vert_y<axis_y
				Return 2
			Else
				Return 3
			EndIf	
		EndIf

	End Function
End Function


Function ODD_IntPointInIntPoly:int(pX:Int, pY:Int, polyXY:Int[] )
	'at least 3 corners/triangle needed
	If polyXY.length<6 Or (polyXY.length & 1) then Return False
	
	Local x1:Int = polyXY[polyXY.length-2]
	Local y1:Int = polyXY[polyXY.length-1]
	Local currentQuad:Int = GetPolyQuad(pX, pY, x1, y1)
	Local nextQuad:Int
	Local total:Int
	
	For Local i:int = 0 Until polyXY.length Step 2
		Local x2:Float = polyXY[i]
		Local y2:Float = polyXY[i+1]
		nextQuad = GetPolyQuad(pX, pY, x2, y2)

		Local diff:Int = nextQuad - currentQuad
		
		Select diff
			Case 2, -2
				If (x2 - ( ((y2 - pY) * (x1 - x2)) / (y1 - y2) ) ) < pX
					diff = -diff
				EndIf
			Case 3
				diff = -1
			Case -3
				diff = 1
		End Select
		
		total :+ diff
		currentQuad = nextQuad
		x1 = x2
		y1 = y2
	Next
	
	Return Abs(total) = 4


	Function GetPolyQuad:int(axis_x:Float,axis_y:Float,vert_x:Float,vert_y:Float)
		If vert_x<axis_x
			If vert_y<axis_y
				Return 1
			Else
				Return 4
			EndIf
		Else
			If vert_y<axis_y
				Return 2
			Else
				Return 3
			EndIf	
		EndIf

	End Function
End Function