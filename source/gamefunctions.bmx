Function Font_AddGradient:TBitmapFontChar(font:TBitmapFont, charKey:String, char:TBitmapFontChar, config:TData=Null)
	If Not char.img Then Return char 'for "space" and other empty signs
	Local pixmap:TPixmap	= LockImage(char.img)
	'convert to rgba
	If pixmap.format = PF_A8 Then pixmap = pixmap.convert(PF_RGBA8888)
'	pixmap = pixmap.convert(PF_A8)
	If Not config Then config = New TData

	'gradient
	Local color:Int
	Local gradientTop:Int	= config.GetInt("gradientTop", 255)
	Local gradientBottom:Int= config.GetInt("gradientBottom", 100)
	Local gradientSteps:Int = font.GetMaxCharHeight()
	Local onStep:Int		= Max(0, char.area.GetY() -2)
	Local brightness:Int	= 0

	For Local y:Int = 0 To pixmap.height-1
		brightness = 255 - onStep * (gradientTop - gradientBottom) / gradientSteps
		onStep :+1
		For Local x:Int = 0 To pixmap.width-1
			color = ARGB_Color( ARGB_Alpha( ReadPixel(pixmap, x,y) ), brightness, brightness, brightness)
			WritePixel(pixmap, x,y, color)
		Next
	Next
	char.img = LoadImage(pixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function


Function Font_AddShadow:TBitmapFontChar(font:TBitmapFont, charKey:String, char:TBitmapFontChar, config:TData=Null)
	If Not char.img Then Return char 'for "space" and other empty signs

	If Not config Then config = New TData
	Local shadowSize:Int = config.GetInt("size", 0)
	'nothing to do?
	If shadowSize=0 Then Return char
	Local pixmap:TPixmap	= LockImage(char.img) ;If pixmap.format = PF_A8 Then pixmap = pixmap.convert(PF_RGBA8888)
	Local stepX:Float		= Float(config.GetString("stepX", "0.75"))
	Local stepY:Float		= Float(config.GetString("stepY", "1.0"))
	Local intensity:Float	= Float(config.GetString("intensity", "0.75"))
	Local blur:Float		= Float(config.GetString("blur", "0.5"))
 	Local width:Int			= pixmap.width + shadowSize
	Local height:Int		= pixmap.height + shadowSize

	Local newPixmap:TPixmap = TPixmap.Create(width, height, PF_RGBA8888)
	newPixmap.ClearPixels(0)

	If blur > 0.0
		DrawImageOnImage(pixmap, newPixmap, 1,1, TColor.Create(0,0,0,1.0))
		blurPixmap(newPixmap,0.5)
	EndIf

	'shadow
	For Local i:Int = 0 To shadowSize
		DrawImageOnImage(pixmap, newPixmap, Int(i*stepX),Int(i*stepY), TColor.Create(0,0,0,intensity/i))
	Next
	'original image
	DrawImageOnImage(pixmap, newPixmap, 0,0)

	'increase character dimension
	char.charWidth :+ shadowSize
	char.area.dimension.addXY(shadowSize, shadowSize)

	char.img = LoadImage(newPixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function






