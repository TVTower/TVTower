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


	Method AdjustSaturation(percentage:Float=1.0)
		'maybe better convert to HSL instead of this simple approach
		local luminance:float = 0.3 * r + 0.6 * g + 0.1 * b
		r = r + percentage * (luminance - r)
		g = g + percentage * (luminance - g)
		b = b + percentage * (luminance - b)
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