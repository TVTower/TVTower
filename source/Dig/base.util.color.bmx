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
		local obj:TColor = new TColor
		obj.r = r
		obj.g = g
		obj.b = b
		obj.a = a
		return obj
	End Function


	Function CreateGrey:TColor(grey:int=0,a:float=1.0)
		local obj:TColor = new TColor
		obj.r = grey
		obj.g = grey
		obj.b = grey
		obj.a = a
		return obj
	End Function


	Function CreateFromMix:TColor(colorA:TColor, colorB:TColor, mixFactor:float = 0.5)
		return colorA.Copy().Mix(colorB, mixFactor)
	End Function


	Function FromName:TColor(name:String, alpha:float=1.0)
		Select name.ToLower()
				Case "red"
						Return clRed.copy().AdjustAlpha(alpha)
				Case "green"
						Return clGreen.copy().AdjustAlpha(alpha)
				Case "blue"
						Return clBlue.copy().AdjustAlpha(alpha)
				Case "black"
						Return clBlack.copy().AdjustAlpha(alpha)
				Case "white"
						Return clWhite.copy().AdjustAlpha(alpha)
		End Select
		Return clWhite.copy()
	End Function


	Method Copy:TColor()
		return TColor.Create(r,g,b,a)
	end Method


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
		self.r = self.r * (1.0 - mixFactor) + otherColor.r * mixFactor
		self.g = self.g * (1.0 - mixFactor) + otherColor.g * mixFactor
		self.b = self.b * (1.0 - mixFactor) + otherColor.b * mixFactor
		self.a = self.a * (1.0 - mixFactor) + otherColor.a * mixFactor
		return self
	End Method


	Method AdjustRelative:TColor(percentage:float=1.0)
		self.r = Max(0, self.r * (1.0+percentage))
		self.g = Max(0, self.g * (1.0+percentage))
		self.b = Max(0, self.b * (1.0+percentage))
		return self
	End Method


	Method AdjustFactor:TColor(factor:int=100)
		self.r = Max(0, self.r + factor)
		self.g = Max(0, self.g + factor)
		self.b = Max(0, self.b + factor)
		return self
	End Method


	'faster than using the RGB-HSL-RGB conversion
	'but corrects are not exactly the same
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


	Method AdjustAlpha:TColor(a:float)
		self.a = a
		return self
	End Method


	Method AdjustRGB:TColor(r:int=-1,g:int=-1,b:int=-1, overwrite:int=0)
		if overwrite
			self.r = r
			self.g = g
			self.b = b
		else
			self.r :+r
			self.g :+g
			self.b :+b
		endif
		return self
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
        r = 255 * hue2rgb(p, q, h + 1/3.0)
        g = 255 * hue2rgb(p, q, h)
        b = 255 * hue2rgb(p, q, h - 1/3.0)

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


	Method FromInt:TColor(color:int)
		self.r = ARGB_Red(color)
		self.g = ARGB_Green(color)
		self.b = ARGB_Blue(color)
		self.a = float(ARGB_Alpha(color))/255.0
		return self
	End Method


	Method ToInt:int()
		return ARGB_Color(ceil(self.a*255), self.r, self.g, self.b )
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
Function isMonochrome:int(argb:Int, beTolerant:int=False)
	if beTolerant
		If Abs(ARGB_Red(argb) - ARGB_Green(argb))<=1 And Abs(ARGB_Red(argb) - ARGB_Blue(argb))<=1 And ARGB_Alpha(argb) <> 0 then Return ARGB_Red(argb)
	else
		If ARGB_Red(argb) = ARGB_Green(argb) And ARGB_Red(argb) = ARGB_Blue(argb) And ARGB_Alpha(argb) <> 0 then Return ARGB_Red(argb)
	endif
	Return -1
End Function