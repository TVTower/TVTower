Function Font_AddGradient:TBitmapFontChar(font:TBitmapFont, char:TBitmapFontChar, config:TData=Null)
	If Not char.pixmap Then Return char 'for "space" and other empty signs
	'convert to rgba
	If char.pixmap.format = PF_A8 Then char.pixmap = char.pixmap.convert(PF_RGBA8888)

	If Not config Then config = New TData

	'gradient
	Local color:Int
	Local gradientTop:Int	= config.GetInt("gradientTop", 255)
	Local gradientBottom:Int= config.GetInt("gradientBottom", 100)
	Local gradientSteps:Int = font.GetMaxCharHeight()
	Local onStep:Int		= Max(0, char.pos.y -2)
	Local brightness:Int	= 0

	For Local y:Int = 0 To char.pixmap.height-1
		brightness = 255 - onStep * (gradientTop - gradientBottom) / gradientSteps
		onStep :+1
		For Local x:Int = 0 To char.pixmap.width-1
			color = ARGB_Color( ARGB_Alpha( ReadPixel(char.pixmap, x,y) ), brightness, brightness, brightness)
			WritePixel(char.pixmap, x,y, color)
		Next
	Next

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function


Function Font_AddShadow:TBitmapFontChar(font:TBitmapFont, char:TBitmapFontChar, config:TData=Null)
	If Not char.pixmap Then Return char 'for "space" and other empty signs
	'convert to rgba
	If char.pixmap.format = PF_A8 Then char.pixmap = char.pixmap.convert(PF_RGBA8888)

	If Not config Then config = New TData

	Local shadowSize:Int = config.GetInt("size", 0)
	'nothing to do?
	If shadowSize=0 Then Return char
	Local stepX:Float		= Float(config.GetString("stepX", "0.75"))
	Local stepY:Float		= Float(config.GetString("stepY", "1.0"))
	Local intensity:Float	= Float(config.GetString("intensity", "0.75"))
	Local blur:Float		= Float(config.GetString("blur", "0.5"))
 	Local width:Int			= char.pixmap.width + shadowSize
	Local height:Int		= char.pixmap.height + shadowSize

	Local newPixmap:TPixmap = TPixmap.Create(width, height, PF_RGBA8888)
	newPixmap.ClearPixels(0)

	If blur > 0.0
		DrawImageOnImageSColor(char.pixmap, newPixmap, 1,1, SColor8.Black)
		blurPixmap(newPixmap,0.5)
	EndIf

	'shadow
	For Local i:Int = 0 To shadowSize
		DrawImageOnImageSColor(char.pixmap, newPixmap, Int(i*stepX), Int(i*stepY), new SColor8(0,0,0,int(255 * intensity/i)))
	Next
	'original image
	DrawImageOnImage(char.pixmap, newPixmap, 0,0)

	'increase character dimension
	char.charWidth :+ shadowSize
	char.dim = new Svec2i(char.dim.x + shadowSize, char.dim.y + shadowSize)

	char.pixmap = newPixmap

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function






