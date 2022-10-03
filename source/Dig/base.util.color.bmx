SuperStrict
Import BRL.Max2D 'to "SetColor()"
Import BRL.Math
Import BRL.LinkedList
Import "base.util.math.bmx"

global tcolor_created:int = 0


Type SColor8Helper
	Function AdjustRelative:SColor8(c:SColor8, percentage:Float=1.0)
		Return new SColor8(Byte(Min(255, Max(0, c.r * (1.0 + percentage)))), ..
		                   Byte(Min(255, Max(0, c.g * (1.0 + percentage)))), ..
		                   Byte(Min(255, Max(0, c.b * (1.0 + percentage)))))
	End Function


	Function Mix:SColor8(c1:SColor8, c2:SColor8, mixFactor:Float = 0.5)
		mixFactor = Min(1.0, Max(0.0, mixFactor))
		Return new SColor8(Byte(c1.r * (1.0 - mixFactor) + c2.r * mixFactor), ..
		                   Byte(c1.g * (1.0 - mixFactor) + c2.g * mixFactor), ..
		                   Byte(c1.b * (1.0 - mixFactor) + c2.b * mixFactor))
	End Function


	Function GetBrightness:Float(c:SColor8)
		'variant "HSP"
		Return Sqr(0.299 * c.r^2 + 0.587 * c.g^2 + 0.114 * c.b^2)
		'variant "Luminance"
		'return 0.2126 * r + 0.7152 * g + 0.0722 *b
	End Function

End Type




Struct SColorRGBA
	Field r:Byte
	Field g:Byte
	Field b:Byte
	Field a:Float
	
	Method New(r:Byte, g:Byte, b:Byte, a:Float)
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	End Method
	
	
	'loses alpha!
	Method ToSColor8:SColor8()
		Return new SColor8(r,g,b)
	End Method
	
	
	Function FromSColor8:SColorRGBA(c:SColor8)
		Return new SColorRGBA(c.r, c.g, c.b, 1.0)
	End Function


	Function FromTColor:SColorRGBA(c:TColor)
		Return new SColorRGBA(Byte(c.r), Byte(c.g), Byte(c.b), c.a)
	End Function
	

	Function FromMix:SColorRGBA(c1:TColor, c2:TColor, mixFactor:Float = 0.5)
		mixFactor = Min(1.0, Max(0.0, mixFactor))
		Return new SColorRGBA(Byte(c1.r * (1.0 - mixFactor) + c2.r * mixFactor), ..
		                      Byte(c1.g * (1.0 - mixFactor) + c2.g * mixFactor), ..
		                      Byte(c1.b * (1.0 - mixFactor) + c2.b * mixFactor), ..
		                      c1.a * (1.0 - mixFactor) + c2.a * mixFactor)
	End Function
End Struct




Type TColor
	Field r:Int			= 0
	Field g:Int			= 0
	Field b:Int			= 0
	Field a:Float		= 1.0

	Global list:TList	= CreateList()	'storage for colors (allows handle referencing)
	'some const
	Global clBlack:TColor = TColor.CreateGrey(0)
	Global clWhite:TColor = TColor.CreateGrey(255)
	Global clRed:TColor = TColor.Create(255,0,0)
	Global clGreen:TColor = TColor.Create(0,255,0)
	Global clBlue:TColor = TColor.Create(0,0,255)
	
	Method New()
		tcolor_created :+ 1
	End Method

	
	Method New(col:SColor8)
		self.r = col.r
		self.g = col.g
		self.b = col.b
		self.a = col.a/255.0
	End Method
	

	Function Create:TColor(r:Int=0,g:Int=0,b:Int=0,a:Float=1.0)
		Return New TColor.InitRGBA(r, g, b, a)
	End Function


	Function CreateGrey:TColor(grey:Int=0,a:Float=1.0)
		Return New TColor.InitRGBA(grey, grey, grey, a)
	End Function


	Function CreateFromMix:TColor(colorA:TColor, colorB:TColor, mixFactor:Float = 0.5)
		Return colorA.Copy().Mix(colorB, mixFactor)
	End Function


	Method InitRGBA:TColor(r:Int, g:Int, b:Int, a:Float=1.0)
		Self.r = r
		Self.g = g
		Self.b = b
		Self.a = a

		Return Self
	End Method


	Method ToString:String()
		Return r+", "+g+", "+b+", "+a
	End Method


	Method ToRGBString:String(glue:String=", ")
		Return r+glue+g+glue+b
	End Method
	
	Method ToSColor8:SColor8()
		Return New SColor8(r,g,b,Int(Max(0, Min(255, a*255))))
	End Method
	

	Function FromName:TColor(name:String, alpha:Float=1.0)
		Select name.ToLower()
				Case "red"
						Return clRed.copy().AdjustAlpha(alpha, True)
				Case "green"
						Return clGreen.copy().AdjustAlpha(alpha, True)
				Case "blue"
						Return clBlue.copy().AdjustAlpha(alpha, True)
				Case "black"
						Return clBlack.copy().AdjustAlpha(alpha, True)
				Case "white"
						Return clWhite.copy().AdjustAlpha(alpha, True)
		End Select
		Return clWhite.copy()
	End Function


	Method Copy:TColor()
		Return TColor.Create(r,g,b,a)
	End Method


	Method CopyFrom:TColor(color:TColor)
		If color
			Self.r = color.r
			Self.g = color.g
			Self.b = color.b
			Self.a = color.a
		EndIf
		Return Self
	End Method


	Method CopyFrom:TColor(color:SColor8)
		Self.r = color.r
		Self.g = color.g
		Self.b = color.b
		Self.a = 1.0
		Return Self
	End Method


	Method AddToList:TColor()
		'remove first and append as last color
		list.remove(Self)
		list.AddLast(Self)

		Return Self
	End Method


	Function getFromList:TColor(col:TColor)
		Return TColor.getFromListByRGBA(col.r,col.g,col.b,col.a)
	End Function


	Function getFromListByRGBA:TColor(r:Int, g:Int, b:Int, a:Float=1.0)
		For Local obj:TColor = EachIn TColor.List
			If obj.r = r And obj.g = g And obj.b = b And obj.a = a Then Return obj
		Next
		Return Null
	End Function


	Method GetBrightness:Float()
		'variant "HSP"
		Return Sqr(0.299 * r^2 + 0.587 * g^2 + 0.114 * b^2)
		'variant "Luminance"
		'return 0.2126 * r + 0.7152 * g + 0.0722 *b
	End Method


	'mixes colors, mixFactor is percentage (0-1) of otherColors influence
	Method Mix:TColor(otherColor:TColor, mixFactor:Float = 0.5)
		'clamp mixFactor to 0-1.0
		mixFactor = Min(1.0, Max(0.0, mixFactor))
		Self.r = Min(255, Max(0, Self.r * (1.0 - mixFactor) + otherColor.r * mixFactor))
		Self.g = Min(255, Max(0, Self.g * (1.0 - mixFactor) + otherColor.g * mixFactor))
		Self.b = Min(255, Max(0, Self.b * (1.0 - mixFactor) + otherColor.b * mixFactor))
		Self.a = Min(1.0, Max(0, Self.a * (1.0 - mixFactor) + otherColor.a * mixFactor))
		Return Self
	End Method


	'mixes colors, mixFactor is percentage (0-1) of otherColors influence
	Method Mix:TColor(otherColor:SColor8, mixFactor:Float = 0.5)
		'clamp mixFactor to 0-1.0
		mixFactor = Min(1.0, Max(0.0, mixFactor))
		Self.r = Min(255, Max(0, Self.r * (1.0 - mixFactor) + otherColor.r * mixFactor))
		Self.g = Min(255, Max(0, Self.g * (1.0 - mixFactor) + otherColor.g * mixFactor))
		Self.b = Min(255, Max(0, Self.b * (1.0 - mixFactor) + otherColor.b * mixFactor))
		Return Self
	End Method


	Method AdjustRelative:TColor(percentage:Float=1.0)
		Self.r = Min(255, Max(0, Self.r * (1.0+percentage)))
		Self.g = Min(255, Max(0, Self.g * (1.0+percentage)))
		Self.b = Min(255, Max(0, Self.b * (1.0+percentage)))
		Return Self
	End Method


	Method AdjustFactor:TColor(factor:Int=100)
		Self.r = Min(255, Max(0, Self.r + factor))
		Self.g = Min(255, Max(0, Self.g + factor))
		Self.b = Min(255, Max(0, Self.b + factor))
		Return Self
	End Method


	'faster than using the RGB-HSL-RGB conversion
	'but results are not exactly the same
	Method AdjustSaturationRGB:TColor(percentage:Float = 0.0)
		'convert relative param to absolute param
		percentage = 1.0 + percentage
		'long
		Local luminance:Float = Sqr(0.299 * r*r + 0.587 * g*g + 0.114 * b*b)
		r = Min(255, Max(0, luminance + (r - luminance) * percentage))
		g = Min(255, Max(0, luminance + (g - luminance) * percentage))
		b = Min(255, Max(0, luminance + (b - luminance) * percentage))
		Return Self
	End Method


	Method AdjustSaturation:TColor(percentage:Float=1.0)
		Local h:Float, s:Float, l:Float
		ToHSL(h,s,l)
		FromHSL(h,s * (1.0 + percentage), l)
		Return Self
	End Method


	Method AdjustBrightness:TColor(percentage:Float=1.0)
		Local h:Float, s:Float, l:Float
		ToHSL(h,s,l)
		FromHSL(h,s, l * (1.0 + percentage))
		Return Self
	End Method


	Method AdjustAlpha:TColor(a:Float, overwrite:Int=0)
		If overwrite
			Self.a = a
		Else
			Self.a :+ a
		EndIf
		Return Self
	End Method


	Method AdjustRGB:TColor(r:Int=-1,g:Int=-1,b:Int=-1, overwrite:Int=0)
		If overwrite
			Self.r = Min(255, Max(0, r))
			Self.g = Min(255, Max(0, g))
			Self.b = Min(255, Max(0, b))
		Else
			Self.r = Min(255, Max(0, Self.r + r))
			Self.g = Min(255, Max(0, Self.g + g))
			Self.b = Min(255, Max(0, Self.b + b))
		EndIf
		Return Self
	End Method


	Method Multiply:TColor(rMultiplier:Float=1.0, gMultiplier:Float=1.0, bMultiplier:Float=1.0, aMultiplier:Float=1.0)
		self.r :* rMultiplier
		self.g :* gMultiplier
		self.b :* bMultiplier
		self.a :* aMultiplier
		Return Self
	End Method
	

	'returns RGB difference
	Method GetEuclideanDistance:Int(otherColor:TColor)
		'according to https://en.wikipedia.org/wiki/Color_difference
		Return Sqr( (otherColor.r - r)^2 + (otherColor.g - g)^2 + (otherColor.b - b)^2 )
	End Method


	'returns a delta value describing the perceived distance between colors
	Method GetCIELABDelta_ByLAB:Float(L:Float, A:Float, B:Float)
		'default to this implementation
		Return GetCIELABDelta_CIE76_ByLAB(L, A, B)
	End Method


	'returns a delta value describing the perceived distance between colors
	Method GetCIELABDelta:Float(otherColor:TColor)
		'default to this implementation
		Return GetCIELABDelta_CIE76(otherColor)
	End Method


	Method GetCIELABDelta_CIE76_ByLAB:Float(L:Float, A:Float, B:Float)
		Local myL:Float, myA:Float, myB:Float
		ToLAB(myL,myA,myB)

		'if result is ~2.3 then this is "jnd", just notable difference
		Return Sqr( (L - myL)^2 + (A - myA)^2 + (B - myB)^2 )
	End Method


	Method GetCIELABDelta_CIE76:Float(otherColor:TColor)
		Local L:Float, A:Float, b:Float
		Local otherL:Float, otherA:Float, otherB:Float
		ToLAB(L,A,B)
		otherColor.ToLAB(otherL, otherA, otherB)

		'if result is ~2.3 then this is "jnd", just notable difference
		Return Sqr( (otherL - L)^2 + (otherA - A)^2 + (otherB - B)^2 )
	End Method


	Method ToXYZ(X:Float Var, Y:Float Var, Z:Float Var)
		Local tmpR:Float = r/255.0
		Local tmpG:Float = g/255.0
		Local tmpB:Float = b/255.0

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


	Method ToLAB(L:Float Var, A:Float Var, B:Float Var)
		'based on http://www.easyrgb.com/en/math.php
		'-> RGB->XYZ and XYZ->L*AB

		'1) convert RGB to XYZ
		Local X:Float, Y:Float, Z:Float
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


	Function LAB2XYZ(L:Float, A:Float, B:Float, X:Float Var, Y:Float Var, Z:Float Var)
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
	Method ToHSL:TColor(h:Float Var, s:Float Var, l:Float Var)
		'convert 0-255 to 0-1
		Local rk:Float = r / 255.0
		Local gk:Float = g / 255.0
		Local bk:Float = b / 255.0

		'calculate max/min of r,g,b
		Local maxV:Float = Max(rk, Max(gk, bk))
		Local minV:Float = Min(rk, Min(gk, bk))

		l = (maxV + minV) / 2.0

		'gray
		If maxV = minV
			h = 0
			s = 0
		Else
			Local d:Float = maxV - minV
			If l > 0.5
				s = d / (2 - maxV - minV)
			Else
				s = d / (maxV + minV)
			EndIf

			Select maxV
				Case rK
					'according to mjijackson
					h = (gK - bK) / d
					If g < b Then h :+ 6

					'according to wikipedia
					'h = ((gK - bK) / d) mod 6
				Case gK
					h = (bK - rK) / d + 2
				Case bK
					h = (rK - gK) / d + 4
			End Select
			h :/ 6.0
		EndIf

		Return Self
	End Method


	'code based on the jscript code at:
	'https://github.com/mjackson/mjijackson.github.com/blob/master/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript.txt
	Method FromHSL:TColor(h:Float, s:Float, l:Float)
		'grayscale
		If Abs(s) < 0.0001 'floating point problems in bmax
			r = MathHelper.Clamp(Int(l * 255), 0,255)
			g = r
			b = r
			Return Self
		EndIf

        Local q:Float
        If l < 0.5
			q = l * (1 + s)
		Else
			q = l + s - l * s
		EndIf

		Local p:Float = 2 * l - q
        r = Min(255, Max(0, 255 * hue2rgb(p, q, h + 1/3.0)))
        g = Min(255, Max(0, 255 * hue2rgb(p, q, h)))
        b = Min(255, Max(0, 255 * hue2rgb(p, q, h - 1/3.0)))

		Function hue2rgb:Float(p:Float, q:Float, t:Float)
			If t < 0
				t :+ 1
			ElseIf t > 1
				t :- 1
			EndIf

			If t < 1/6.0 Then Return p + (q - p) * 6.0 * t
			If t < 1/2.0 Then Return q
			If t < 2/3.0 Then Return p + (q - p) * (2/3.0 - t) * 6.0
			Return p
		End Function

		Return Self
	End Method


	'code based on Yashas work:
	'http://www.blitzmax.com/codearcs/codearcs.php?code=2333
	Method ToHSV:TColor(h:Float Var, s:Float Var, v:Float Var)
		Local mn:Float, mx:Float, dif:Float, ad:Float, dv:Float, md:Float
		If(r < g And r < b)
			mn = r/255.0
		ElseIf (g < b)
			mn = g/255.0
		Else
			mn = b/255.0
		EndIf

		If(r > g And r > b)
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

		Return Self
	End Method


	Method FromHSV:TColor(h:Float, s:Float, v:Float, a:Float = 1.0)
		Local hi:Int, f:Float, p:Float, q:Float, t:Float
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


	Method IsSame:Int(otherCol:TColor)
		If Self = otherCol Then Return True
		If Not otherCol Then Return False

		Return (r = otherCol.r And g = otherCol.g And b = otherCol.b And a = otherCol.a)
	End Method


	Method IsSameRGBA:Int(r:Int, g:Int, b:Int, a:Float)
		Return (Self.r <> r Or Self.g <> g Or Self.b <> b Or Self.a <> a)
	End Method


	'returns true if the given pixel is monochrome (grey)
	'beTolerant defines if 240,240,241 is still monochrome, this
	'is useful if you use gradients, as sometimes gradients have this
	'differing values
	Method isMonochrome:Int(beTolerant:Int=False, ignoreAlpha:Int=False)
		If beTolerant
			If Abs(r - g)<=1 And Abs(r - b)<=1 And (a <> 0 Or IgnoreAlpha) Then Return r
		Else
			If r = g And r = b And (a <> 0 Or IgnoreAlpha) Then Return r
		EndIf
		Return -1
	End Method


	Method FromInt:TColor(color:Int)
		Self.r = ARGB_Red(color)
		Self.g = ARGB_Green(color)
		Self.b = ARGB_Blue(color)
		Self.a = Float(ARGB_Alpha(color))/255.0
		Return Self
	End Method


	Method ToInt:Int()
		Return ARGB_Color(Int(Ceil(Self.a*255)), Self.r, Self.g, Self.b )
	End Method


	Method ToHex:String()
		'lossy compression of alpha!
		Local h:String = ""
		h :+ MathHelper._StrRight(MathHelper.Int2Hex(r),2)
		h :+ MathHelper._StrRight(MathHelper.Int2Hex(g),2)
		h :+ MathHelper._StrRight(MathHelper.Int2Hex(b),2)
		'do not append alpha if alpha is 1.0
		If a < 1.0
			h:+ MathHelper._StrRight(MathHelper.Int2Hex(Int(Ceil(a*255))),2)
		EndIf
		Return h
	End Method


	Method FromHex:TColor(hexColor:String)
		Local start:Int = 0
		Local colIndex:Int = 0
		If hexColor.Find("#") = 0 Then start :+1
		For Local i:Int = start Until hexColor.length Step 2
			Local part:String = MathHelper._StrMid(hexColor, i+1, 2)
			If colIndex = 0 Then r = ("$"+part).ToInt()
			If colIndex = 1 Then g = ("$"+part).ToInt()
			If colIndex = 2 Then b = ("$"+part).ToInt()
			If colIndex = 3 Then a = ("$"+part).ToInt()/255.0
			colIndex :+1
		Next
		Return Self
	End Method


	'same as set()
	Method setRGB:TColor()
		SetColor(Self.r, Self.g, Self.b)
		Return Self
	End Method


	'same as set()
	Method setCls:TColor()
		SetClsColor(Self.r, Self.g, Self.b)
		Return Self
	End Method


	Method setRGBA:TColor()
		SetColor(Self.r, Self.g, Self.b)
		SetAlpha(Self.a)
		Return Self
	End Method


	Method get:TColor()
		GetColor(Self.r, Self.g, Self.b)
		Self.a = GetAlpha()
		Return Self
	End Method


	Method getFromClsColor:TColor()
		GetClsColor(Self.r, Self.g, Self.b)
		Self.a = GetAlpha()
		Return Self
	End Method
End Type



Function SColor8AdjustFactor:SColor8(color:SColor8, factor:Int)
	Return New SColor8(..
		Min(255, Max(0, color.r + factor)), ..
		Min(255, Max(0, color.g + factor)), ..
		Min(255, Max(0, color.b + factor)) ..
		)
End Function


'===== VARIOUS COLOR FUNCTIONS =====


Function ARGB_Alpha:Int(ARGB:Int) Inline
	Return (argb Shr 24) & $ff
EndFunction

Function ARGB_Red:Int(ARGB:Int) Inline
	Return (argb Shr 16) & $ff
EndFunction

Function ARGB_Green:Int(ARGB:Int) Inline
	Return (argb Shr 8) & $ff
EndFunction

Function ARGB_Blue:Int(ARGB:Int) Inline
	Return (argb & $ff)
EndFunction

Function ARGB_Color:Int(alpha:Int,red:Int,green:Int,blue:Int) Inline
	Return (Int(alpha * $1000000) + Int(red * $10000) + Int(green * $100) + Int(blue))
EndFunction

Function RGBA_Red:Byte(rgba:Int) Inline
	Return (rgba Shr 24) & $ff
EndFunction

Function RGBA_Green:Byte(rgba:Int) Inline
	Return (rgba Shr 16) & $ff
EndFunction

Function RGBA_Blue:Byte(rgba:Int) Inline
	Return (rgba Shr 8) & $ff
EndFunction

Function RGBA_Alpha:Byte(rgba:Int) Inline
	Return (rgba & $ff)
EndFunction

Function RGBA_Color:Int(r:Int, g:Int, b:Int, alpha:Int) Inline
	Return (r * $1000000) + (g * $10000) + (b * $100) + alpha
	'this would be 10% slower
	'Return (r Shl 24) | (g Shl 16) | (b Shl 8) | alpha
	'and is the same but 8 times slower :
	Rem
		Local rgba:Int = 0
		'pointer works "first as last" (rgba -> alpha as first)
		Local pointer:Byte Ptr = Varptr(rgba)
		pointer[0] = alpha
		pointer[1] = b
		pointer[2] = g
		pointer[3] = r
		Return rgba
	End Rem
EndFunction


Function ARGB2RGBA:Int(argb:Int) Inline
	Return ((argb Shl 8) & $FFFFFF00) | (argb Shr 24)
End Function

Function RGBA2ARGB:Int(rgba:Int) Inline
	Return ((rgba Shr 8) & $00FFFFFF) | (rgba Shl 24)
End Function




'returns true if the given pixel is monochrome (grey)
'beTolerant defines if 240,240,241 is still monochrome, this
'is useful if you use gradients, as sometimes gradients have this
'differing values
Function isMonochromeARGB:Int(argb:Int, beTolerant:Int=False, ignoreAlpha:Int=False) Inline
	Local pointer:Byte Ptr = Varptr(argb)
	'pointer are like "mirrored" "argb" as if "bgra"
	'argb: [0] = blue, [1] = green, [2] = red, [3] = alpha

	If beTolerant
		'If Abs(ARGB_Red(argb) - ARGB_Green(argb))<=1 And Abs(ARGB_Red(argb) - ARGB_Blue(argb))<=1 And (ARGB_Alpha(argb) <> 0 Or IgnoreAlpha) Then Return ARGB_Red(argb)
		If Abs(pointer[2] - pointer[1]) <= 1 And Abs(pointer[2] - pointer[0]) <= 1 And (IgnoreAlpha or pointer[3] <> 0) Then Return pointer[2]
	Else
		'red = green and red = blue alpha <> 0 or ignoreAlpha
		'If ARGB_Red(argb) = ARGB_Green(argb) And ARGB_Red(argb) = ARGB_Blue(argb) And (ARGB_Alpha(argb) <> 0 Or IgnoreAlpha) Then Return ARGB_Red(argb)
		If pointer[2] = pointer[1] and pointer[2] = pointer[0] and (IgnoreAlpha Or pointer[3] <> 0) Then Return pointer[2]
	EndIf
	Return -1
End Function



'returns true if the given pixel is monochrome (grey)
'beTolerant defines if 240,240,241 is still monochrome, this
'is useful if you use gradients, as sometimes gradients have this
'differing values
Function isMonochromeRGBA:Int(rgba:Int, beTolerant:Int=False, ignoreAlpha:Int=False) Inline
	'pointer are like "mirrored" "rgba" as if "abgr"
	'rgba: [0] = alpha, [1] = blue, [2] = green, [3] = red 
	Local pointer:Byte Ptr = Varptr(rgba)

	If beTolerant
		If Abs(pointer[3] - pointer[2]) <= 1 And Abs(pointer[3] - pointer[1]) <= 1 And (IgnoreAlpha or pointer[0] <> 0) Then Return pointer[3]
	Else
		If pointer[3] = pointer[2] and pointer[3] = pointer[1] and (IgnoreAlpha or pointer[0] <> 0) Then Return pointer[3]
	EndIf
	Return -1
End Function