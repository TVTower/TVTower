SuperStrict
Import BRL.Max2D 'to "SetColor()"
Import BRL.Math
Import BRL.LinkedList
Import "base.util.math.bmx"


Type TColor
	Field r:int			= 0
	Field g:int			= 0
	Field b:int			= 0
	Field a:float		= 1.0

	global list:TList	= CreateList()	'storage for colors (allows handle referencing)
	'some const
	global clBlack:TColor = TColor.CreateGrey(0)
	global clWhite:TColor = TColor.CreateGrey(255)
	global clRed:TColor = TColor.Create(255,0,0)
	global clGreen:TColor = TColor.Create(0,255,0)
	global clBlue:TColor = TColor.Create(0,0,255)


	Function Create:TColor(r:int=0,g:int=0,b:int=0,a:float=1.0)
		return new TColor.InitRGBA(r, g, b, a)
	End Function


	Function CreateGrey:TColor(grey:int=0,a:float=1.0)
		return new TColor.InitRGBA(grey, grey, grey, a)
	End Function


	Function CreateFromMix:TColor(colorA:TColor, colorB:TColor, mixFactor:float = 0.5)
		return colorA.Copy().Mix(colorB, mixFactor)
	End Function


	Method InitRGBA:TColor(r:int, g:int, b:int, a:float=1.0)
		self.r = r
		self.g = g
		self.b = b
		self.a = a

		return self
	End Method


	Method ToString:string()
		return r+", "+g+", "+b+", "+a
	End Method


	Method ToRGBString:string(glue:string=", ")
		return r+glue+g+glue+b
	End Method


	Function FromName:TColor(name:String, alpha:float=1.0)
		Select name.ToLower()
				Case "red"
						Return clRed.copy().AdjustAlpha(alpha, true)
				Case "green"
						Return clGreen.copy().AdjustAlpha(alpha, true)
				Case "blue"
						Return clBlue.copy().AdjustAlpha(alpha, true)
				Case "black"
						Return clBlack.copy().AdjustAlpha(alpha, true)
				Case "white"
						Return clWhite.copy().AdjustAlpha(alpha, true)
		End Select
		Return clWhite.copy()
	End Function


	Method Copy:TColor()
		return TColor.Create(r,g,b,a)
	end Method


	Method CopyFrom:TColor(color:TColor)
		if color
			self.r = color.r
			self.g = color.g
			self.b = color.b
			self.a = color.a
		endif
		return self
	End Method


	Method AddToList:TColor()
		'remove first and append as last color
		list.remove(self)
		list.AddLast(self)

		return self
	End Method


	Function getFromList:TColor(col:TColor)
		return TColor.getFromListByRGBA(col.r,col.g,col.b,col.a)
	End Function


	Function getFromListByRGBA:TColor(r:Int, g:Int, b:Int, a:float=1.0)
		For local obj:TColor = EachIn TColor.List
			If obj.r = r And obj.g = g And obj.b = b And obj.a = a Then Return obj
		Next
		Return Null
	End Function


	Method GetBrightness:Float()
		'variant "HSP"
		return Sqr(0.299 * r^2 + 0.587 * g^2 + 0.114 * b^2)
		'variant "Luminance"
		'return 0.2126 * r + 0.7152 * g + 0.0722 *b
	End Method


	'mixes colors, mixFactor is percentage (0-1) of otherColors influence
	Method Mix:TColor(otherColor:TColor, mixFactor:float = 0.5)
		'clamp mixFactor to 0-1.0
		mixFactor = Min(1.0, Max(0.0, mixFactor))
		self.r = Min(255, Max(0, self.r * (1.0 - mixFactor) + otherColor.r * mixFactor))
		self.g = Min(255, Max(0, self.g * (1.0 - mixFactor) + otherColor.g * mixFactor))
		self.b = Min(255, Max(0, self.b * (1.0 - mixFactor) + otherColor.b * mixFactor))
		self.a = Min(1.0, Max(0, self.a * (1.0 - mixFactor) + otherColor.a * mixFactor))
		return self
	End Method


	Method AdjustRelative:TColor(percentage:float=1.0)
		self.r = Min(255, Max(0, self.r * (1.0+percentage)))
		self.g = Min(255, Max(0, self.g * (1.0+percentage)))
		self.b = Min(255, Max(0, self.b * (1.0+percentage)))
		return self
	End Method


	Method AdjustFactor:TColor(factor:int=100)
		self.r = Min(255, Max(0, self.r + factor))
		self.g = Min(255, Max(0, self.g + factor))
		self.b = Min(255, Max(0, self.b + factor))
		return self
	End Method


	'faster than using the RGB-HSL-RGB conversion
	'but results are not exactly the same
	Method AdjustSaturationRGB:TColor(percentage:Float = 0.0)
		'convert relative param to absolute param
		percentage = 1.0 + percentage
		'long
		local luminance:float = sqr(0.299 * r*r + 0.587 * g*g + 0.114 * b*b)
		r = Min(255, Max(0, luminance + (r - luminance) * percentage))
		g = Min(255, Max(0, luminance + (g - luminance) * percentage))
		b = Min(255, Max(0, luminance + (b - luminance) * percentage))
		return self
	End Method


	Method AdjustSaturation:TColor(percentage:Float=1.0)
		local h:float, s:float, l:float
		ToHSL(h,s,l)
		FromHSL(h,s * (1.0 + percentage), l)
		return self
	End Method


	Method AdjustBrightness:TColor(percentage:Float=1.0)
		local h:float, s:float, l:float
		ToHSL(h,s,l)
		FromHSL(h,s, l * (1.0 + percentage))
		return self
	End Method


	Method AdjustAlpha:TColor(a:float, overwrite:int=0)
		if overwrite
			self.a = a
		else
			self.a :+ a
		endif
		return self
	End Method


	Method AdjustRGB:TColor(r:int=-1,g:int=-1,b:int=-1, overwrite:int=0)
		if overwrite
			self.r = Min(255, Max(0, r))
			self.g = Min(255, Max(0, g))
			self.b = Min(255, Max(0, b))
		else
			self.r = Min(255, Max(0, self.r + r))
			self.g = Min(255, Max(0, self.g + g))
			self.b = Min(255, Max(0, self.b + b))
		endif
		return self
	End Method


	'returns RGB difference
	Method GetEuclideanDistance:int(otherColor:TColor)
		'according to https://en.wikipedia.org/wiki/Color_difference
		return sqr( (otherColor.r - r)^2 + (otherColor.g - g)^2 + (otherColor.b - b)^2 )
	End Method


	'returns a delta value describing the perceived distance between colors
	Method GetCIELABDelta_ByLAB:Float(L:float, A:float, B:float)
		'default to this implementation
		return GetCIELABDelta_CIE76_ByLAB(L, A, B)
	End Method


	'returns a delta value describing the perceived distance between colors
	Method GetCIELABDelta:Float(otherColor:TColor)
		'default to this implementation
		return GetCIELABDelta_CIE76(otherColor)
	End Method


	Method GetCIELABDelta_CIE76_ByLAB:Float(L:float, A:float, B:float)
		local myL:float, myA:float, myB:float
		ToLAB(myL,myA,myB)

		'if result is ~2.3 then this is "jnd", just notable difference
		return sqr( (L - myL)^2 + (A - myA)^2 + (B - myB)^2 )
	End Method


	Method GetCIELABDelta_CIE76:Float(otherColor:TColor)
		local L:float, A:float, b:float
		local otherL:float, otherA:float, otherB:float
		ToLAB(L,A,B)
		otherColor.ToLAB(otherL, otherA, otherB)

		'if result is ~2.3 then this is "jnd", just notable difference
		return sqr( (otherL - L)^2 + (otherA - A)^2 + (otherB - B)^2 )
	End Method


	Method ToXYZ(X:Float var, Y:Float var, Z:Float var)
		local tmpR:Float = r/255.0
		local tmpG:Float = g/255.0
		local tmpB:Float = b/255.0

		If tmpR > 0.04045
			tmpR = 100 * ((tmpR + 0.055) / 1.055) ^ 2.4
		Else
			tmpR = 100 * tmpR / 12.92
		EndIf
		If tmpG > 0.04045
			tmpG = 100 * ((tmpG + 0.055) / 1.055) ^ 2.4
		Else
			tmpG = 100 * tmpG / 12.92
		EndIf
		If tmpB > 0.04045
			tmpB = 100 * ((tmpB + 0.055) / 1.055) ^ 2.4
		Else
			tmpB = 100 * tmpB / 12.92
		EndIf

		X = tmpR * 0.4124 + tmpG * 0.3576 + tmpB * 0.1805
		Y = tmpR * 0.2126 + tmpG * 0.7152 + tmpB * 0.0722
		Z = tmpR * 0.0193 + tmpG * 0.1192 + tmpB * 0.9505
	End Method


	Method ToLAB(L:float var, A:float var, B:float var)
		'based on http://www.easyrgb.com/en/math.php
		'-> RGB->XYZ and XYZ->L*AB

		'1) convert RGB to XYZ
		local X:Float, Y:Float, Z:Float
		ToXYZ(X, Y, Z)

		'adjust values according "XYZ (Tristimulus) Reference values"
		'using "D65" (Daylight, sRGB, Adobe-RGB) and "2°" (CIE 1931)
		X :/ 95.047
		Y :/ 100.000
		Z :/ 108.883

		If X > 0.008856
			X = X ^ (1/3.0)
		Else
			X = (7.787 * X) + (16/116.0)
		EndIf
		If Y > 0.008856
			Y = Y ^ (1/3.0)
		Else
			Y = (7.787 * Y) + (16/116.0)
		EndIf
		If Z > 0.008856
			Z = Z ^ (1/3.0)
		Else
			Z = (7.787 * Z) + (16/116.0)
		EndIf

		L = 116 * Y - 16
		A = 500 * (X - Y)
		B = 200 * (Y - Z)
	End Method


	Function LAB2XYZ(L:Float, A:Float, B:Float, X:Float var, Y:Float var, Z:Float var)
		'based on http://www.easyrgb.com/en/math.php

		Y = (L + 16) / 116.0
		X = A/500.0 + Y
		Z = Y - B/200.0

		If Y^3 > 0.008856
			Y = Y^3
		Else
			Y = (Y - 16/116.0) / 7.787
		EndIf
		If X^3 > 0.008856
			X = X^3
		Else
			X = (X - 16/116.0) / 7.787
		EndIf
		If Z^3 > 0.008856
			Z = Z^3
		Else
			Z = (Z - 16/116.0) / 7.787
		EndIf

		'adjust values according "XYZ (Tristimulus) Reference values"
		'using "D65" (Daylight, sRGB, Adobe-RGB) and "2°" (CIE 1931)
		X :* 95.047
		Y :* 100.000
		Z :* 108.883
	End Function


	Method FromXYZ:TColor(X:Float, Y:Float, Z:Float)
		X :/ 100.0
		Y :/ 100.0
		Z :/ 100.0

		Local tmpR:Float = X *  3.2406 + Y * -1.5372 + Z * -0.4986
		Local tmpG:Float = X * -0.9689 + Y *  1.8758 + Z *  0.0415
		Local tmpB:Float = X *  0.0557 + Y * -0.2040 + Z *  1.0570

		If tmpR > 0.0031308
			r = 255 * (1.055 * tmpR^(1/2.4) - 0.055)
		Else
			r = 255 * 12.92 * tmpR
		EndIf
		If tmpG > 0.0031308
			g = 255 * (1.055 * tmpG^(1/2.4) - 0.055)
		Else
			g = 255 * 12.92 * tmpG
		EndIf
		If tmpB > 0.0031308
			b = 255 * (1.055 * tmpB^(1/2.4) - 0.055)
		Else
			b = 255 * 12.92 * tmpB
		EndIf
	End Method


	Method FromLab(L:Float, A:Float, B:Float)
		'based on http://www.easyrgb.com/en/math.php
		'-> L*AB->XYZ then XYZ->RGB
		Local X:Float, Y:Float, Z:Float
		LAB2XYZ(L, A, B, X, Y, Z)

		FromXYZ(X, Y, Z)
	End Method


	'convert rgb to hsl
	'Formula adapted from http://en.wikipedia.org/wiki/HSL_color_space.
	'code based on the jscript code at:
	'https://github.com/mjackson/mjijackson.github.com/blob/master/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript.txt
	Method ToHSL(h:float var, s:float var, l:float var)
		'convert 0-255 to 0-1
		Local rk:float = r / 255.0
		local gk:float = g / 255.0
		local bk:float = b / 255.0

		'calculate max/min of r,g,b
		Local maxV:float = Max(rk, Max(gk, bk))
		local minV:float = Min(rk, Min(gk, bk))

		l = (maxV + minV) / 2.0

		'gray
		If maxV = minV
			h = 0
			s = 0
		Else
			local d:float = maxV - minV
			if l > 0.5
				s = d / (2 - maxV - minV)
			else
				s = d / (maxV + minV)
			endif

			select maxV
				case rK
					'according to mjijackson
					h = (gK - bK) / d
					if g < b then h :+ 6

					'according to wikipedia
					'h = ((gK - bK) / d) mod 6
				case gK
					h = (bK - rK) / d + 2
				case bK
					h = (rK - gK) / d + 4
			end select
			h :/ 6.0
		EndIf
	End Method


	'code based on the jscript code at:
	'https://github.com/mjackson/mjijackson.github.com/blob/master/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript.txt
	Method FromHSL(h:float, s:float, l:float)
		'grayscale
		if Abs(s) < 0.0001 'floating point problems in bmax
			r = MathHelper.Clamp(int(l * 255), 0,255)
			g = r
			b = r
			return
		endif

        local q:float
        if l < 0.5
			q = l * (1 + s)
		else
			q = l + s - l * s
		endif

		local p:float = 2 * l - q
        r = Min(255, Max(0, 255 * hue2rgb(p, q, h + 1/3.0)))
        g = Min(255, Max(0, 255 * hue2rgb(p, q, h)))
        b = Min(255, Max(0, 255 * hue2rgb(p, q, h - 1/3.0)))

		Function hue2rgb:Float(p:float, q:float, t:float)
			if t < 0
				t :+ 1
			elseif t > 1
				t :- 1
			endif

			if t < 1/6.0 then return p + (q - p) * 6.0 * t
			if t < 1/2.0 then return q
			if t < 2/3.0 then return p + (q - p) * (2/3.0 - t) * 6.0
			return p
		End Function
	End Method


	'code based on Yashas work:
	'http://www.blitzmax.com/codearcs/codearcs.php?code=2333
	Method ToHSV(h:float var, s:float var, v:float var)
		Local mn:float, mx:float, dif:float, ad:float, dv:float, md:float
		If(r < g and r < b)
			mn = r/255.0
		ElseIf (g < b)
			mn = g/255.0
		Else
			mn = b/255.0
		EndIf

		If(r > g and r > b)
			mx = r/255.0
			dif = (g - b)/255.0
			ad = 0.0
		ElseIf(g > b)
			mx = g/255.0
			dif = (b - r)/255.0
			ad = 120.0
		Else
			mx = b/255.0
			dif = (r - g)/255.0
			ad = 240.0
		EndIf

		md = mx - mn

		h = (60.0 * (dif / md)) + ad
		s = md / mx
		v = mx
	End Method


	Method FromHSV:TColor(h:float, s:float, v:float, a:float = 1.0)
		Local hi:int, f:float, p:float, q:float, t:float
		f = h / 60.0
		hi = Int(f) Mod 6
		f :- hi
		p = v * (1 - s)
		q = v * (1 - (f * s))
		t = v * (1 - ((1 - f) * s))
		Select hi
			Case 0; r=v; g=t; b=p
			Case 1; r=q; g=v; b=p
			Case 2; r=p; g=v; b=t
			Case 3; r=p; g=q; b=v
			Case 4; r=t; g=p; b=v
			Case 5; r=v; g=p; b=q
		End Select

		Self.a = a
		Return Self
	End Method


	'returns true if the given pixel is monochrome (grey)
	'beTolerant defines if 240,240,241 is still monochrome, this
	'is useful if you use gradients, as sometimes gradients have this
	'differing values
	Method isMonochrome:int(beTolerant:int=False, ignoreAlpha:int=False)
		if beTolerant
			If Abs(r - g)<=1 And Abs(r - b)<=1 And (a <> 0 or IgnoreAlpha) then Return r
		else
			If r = g And r = b And (a <> 0 or IgnoreAlpha) then Return r
		endif
		Return -1
	End Method


	Method FromInt:TColor(color:int)
		self.r = ARGB_Red(color)
		self.g = ARGB_Green(color)
		self.b = ARGB_Blue(color)
		self.a = float(ARGB_Alpha(color))/255.0
		return self
	End Method


	Method ToInt:int()
		return ARGB_Color(int(ceil(self.a*255)), self.r, self.g, self.b )
	End Method


	Method ToHex:string()
		'lossy compression of alpha!
		local h:string = ""
		h :+ MathHelper._StrRight(MathHelper.Int2Hex(r),2)
		h :+ MathHelper._StrRight(MathHelper.Int2Hex(g),2)
		h :+ MathHelper._StrRight(MathHelper.Int2Hex(b),2)
		'do not append alpha if alpha is 1.0
		if a < 1.0
			h:+ MathHelper._StrRight(MathHelper.Int2Hex(int(ceil(a*255))),2)
		endif
		return h
	End Method


	Method FromHex:TColor(hexColor:string)
		local start:int = 0
		local colIndex:int = 0
		if hexColor.Find("#") = 0 then start :+1
		for local i:int = start until hexColor.length step 2
			local part:string = MathHelper._StrMid(hexColor, i+1, 2)
			if colIndex = 0 then r = ("$"+part).ToInt()
			if colIndex = 1 then g = ("$"+part).ToInt()
			if colIndex = 2 then b = ("$"+part).ToInt()
			if colIndex = 3 then a = ("$"+part).ToInt()/255.0
			colIndex :+1
		Next
		return self
	End Method


	'same as set()
	Method setRGB:TColor()
		SetColor(self.r, self.g, self.b)
		return self
	End Method


	'same as set()
	Method setCls:TColor()
		SetClsColor(self.r, self.g, self.b)
		return self
	End Method


	Method setRGBA:TColor()
		SetColor(self.r, self.g, self.b)
		SetAlpha(self.a)
		return self
	End Method


	Method get:TColor()
		GetColor(self.r, self.g, self.b)
		self.a = GetAlpha()
		return self
	End Method


	Method getFromClsColor:TColor()
		GetClsColor(self.r, self.g, self.b)
		self.a = GetAlpha()
		return self
	End Method
End Type




'===== VARIOUS COLOR FUNCTIONS =====


Function ARGB_Alpha:Int(ARGB:Int)
	Return (argb Shr 24) & $ff
EndFunction

Function ARGB_Red:Int(ARGB:Int)
	Return (argb Shr 16) & $ff
EndFunction

Function ARGB_Green:Int(ARGB:Int)
	Return (argb Shr 8) & $ff
EndFunction

Function ARGB_Blue:Int(ARGB:Int)
	Return (argb & $ff)
EndFunction

Function ARGB_Color:Int(alpha:Int,red:Int,green:Int,blue:Int)
	Return (Int(alpha * $1000000) + Int(red * $10000) + Int(green * $100) + Int(blue))
EndFunction

Function RGBA_Color:Int(alpha:int,red:int,green:int,blue:int)
'	Return (Int(alpha * $1000000) + Int(blue * $10000) + Int(green * $100) + Int(red))
'	is the same :
	local argb:int = 0
	local pointer:Byte Ptr = Varptr(argb)
	pointer[0] = red
	pointer[1] = green
	pointer[2] = blue
	pointer[3] = alpha

	return argb
EndFunction




'returns true if the given pixel is monochrome (grey)
'beTolerant defines if 240,240,241 is still monochrome, this
'is useful if you use gradients, as sometimes gradients have this
'differing values
Function isMonochrome:int(argb:Int, beTolerant:int=False, ignoreAlpha:int=False)
	if beTolerant
		If Abs(ARGB_Red(argb) - ARGB_Green(argb))<=1 And Abs(ARGB_Red(argb) - ARGB_Blue(argb))<=1 And (ARGB_Alpha(argb) <> 0 or IgnoreAlpha) then Return ARGB_Red(argb)
	else
		If ARGB_Red(argb) = ARGB_Green(argb) And ARGB_Red(argb) = ARGB_Blue(argb) And (ARGB_Alpha(argb) <> 0 or IgnoreAlpha) then Return ARGB_Red(argb)
	endif
	Return -1
End Function