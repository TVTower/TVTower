SuperStrict
Import BRL.Max2D 'to "SetColor()"
Import BRL.Math
Import BRL.LinkedList



Type TColor
	Field r:int			= 0
	Field g:int			= 0
	Field b:int			= 0
	Field a:float		= 1.0
	Field ownerID:int	= 0				'store if a player/object... uses that color

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


	Method SetOwner:TColor(ownerID:int)
		self.ownerID = ownerID
		return self
	End Method


	Method AddToList:TColor(remove:int=0)
		'if in list - remove first as wished
		if remove then self.list.remove(self)

		self.list.AddLast(self)
		return self
	End Method


	Function getFromListObj:TColor(col:TColor)
		return TColor.getFromList(col.r,col.g,col.b,col.a)
	End Function


	Function getFromList:TColor(r:Int, g:Int, b:Int, a:float=1.0)
		For local obj:TColor = EachIn TColor.List
			If obj.r = r And obj.g = g And obj.b = b And obj.a = a Then Return obj
		Next
		Return Null
	End Function


	Function getByOwner:TColor(ownerID:int=0)
		For local obj:TColor = EachIn TColor.List
			if obj.ownerID = ownerID then return obj
		Next
		return Null
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


	Method ToHSL(h:float var, s:float var, l:float var)
		Local rk:float = r / 255.0
		local gk:float = g / 255.0
		local bk:float = b / 255.0

		Local maxV:float = rk
		local minV:float = gk
	
		If gk > maxV Then maxV = gk
		If bk > maxV Then maxV = bk
		If rk < minV Then minV = rk
		If bk < minV Then minV = bk
	
		If maxV = minV
			h = 0
			s = 0
			l = maxV
		Else
			If maxV = rk
				h = (60 * (gk - bk) / (maxV - minV)) Mod 360
			ElseIf maxV = gk
				h = (60 * (bk - rk) / (maxV - minV)) + 120
			ElseIf maxV = bk
				h = (60 * (rk - gk) / (maxV - minV)) + 240
			EndIf
		
			l = (maxV + minV) / 2
			If l <= 0.5
				s = (maxV - minV) / (2 * l)
			ElseIf l > 0.5
				s = (maxV - minV) / (2 - 2*l)
			EndIf
		EndIf
	End Method
	

	'code based on Yashas work:
	'http://www.blitzmax.com/codearcs/codearcs.php?code=2333
	Method FromHSL(h:float, s:float, l:float)
		Local p:float, q:float
		
		If l < 0.5
			q = l * (1 + s)
		Else
			q = l + s - (l*s)
		EndIf
		p = 2*l - q
		
		Local tR:float = h + 0.3333; If tR > 1 Then tR:- 1
		Local tG:float = h
		Local tB:float = h - 0.3333; If tB < 0 Then tB:+ 1
		r = p*255
		g = p*255
		b = p*255
		
		If tR < 0.1666
			r = 255 * (p + ((q - p) * 6 * tR))
		ElseIf tR < 0.5 And tR >= 0.1666
			r = 255 * (q)
		ElseIf tR < 0.6666 And tR >= 0.5
			r = 255 * (p + ((q - p) * 6 * (0.6666 - tR)))
		EndIf
		
		If tG < 0.1666
			g = 255 * (p + ((q - p) * 6 * tG))
		ElseIf tG < 0.5 And tG >= 0.1666
			g = 255 * (q)
		ElseIf tG < 0.6666 And tG >= 0.5
			g = 255 * (p + ((q - p) * 6 * (0.6666 - tG)))
		EndIf
		
		If tB < 0.1666
			b = 255 * (p + ((q - p) * 6 * tB))
		ElseIf tB < 0.5 And tB >= 0.1666
			b = 255 * (q)
		ElseIf tB < 0.6666 And tB >= 0.5
			b = 255 * (p + ((q - p) * 6 * (0.6666 - tB)))
		EndIf
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