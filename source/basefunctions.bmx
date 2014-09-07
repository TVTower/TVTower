SuperStrict
Import brl.pngloader
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.virtualgraphics.bmx"
Import "Dig/base.util.xmlhelper.bmx"
Import "Dig/base.util.helper.bmx"
Import "Dig/base.util.string.bmx"


'Import "external/libxml/libxml.bmx"
'Import "Dig/external/libxml/libxml.bmx"

Import "basefunctions_zip.bmx"
Import brl.reflection
?Threaded
Import Brl.threads
?
'Import bah.libxml
Import "external/persistence.mod/persistence.bmx"
Import "Dig/base.util.mersenne.bmx"

Const CURRENCYSIGN:string = Chr(8364) 'eurosign



Function SortListArray(List:TList Var)
	Local Arr:Object[] = List.ToArray()
	Arr.Sort()
	List = List.FromArray(arr)
End Function


Type TNumberCurveValue
	Field _value:Int

	Function Create:TNumberCurveValue(number:Int = 0)
		Local obj:TNumberCurveValue = New TNumberCurveValue
		obj._value = number
		Return obj
	End Function
End Type


Type TNumberCurve
	Field _values:TList[]
	Field _ratio:Float[]
	Field _amount:Int = 100

	Function Create:TNumberCurve(curves:Int = 1, amount:Int = 0)
		Local obj:TNumberCurve = New TNumberCurve
		obj._values = obj._values[..Curves + 1]
		obj._ratio = obj._ratio[..Curves + 1]
		For Local i:Int = 1 To Curves
			obj._values[i] = CreateList()
		Next
		Return obj
	End Function

	Method SetCurveRatio(curve:Int = 1, ratio:Float = 1.0)
		Self._ratio[curve] = ratio
	End Method

	Method AddNumber(curve:Int = 1, number:Int = 0)
		If Self._values.Length <= curve
			Self._values[curve].AddLast(TNumberCurveValue.Create(number))
			'remove first if over _amount
			For Local i:Int = 0 To (Self._values[curve].Count() - _amount)
				Self._values[curve].RemoveFirst()
			Next
		EndIf
	End Method

	Method Draw(x:Float, y:Float, w:Float, h:Float)
		SetAlpha 0.5
		SetColor 255, 255, 255
		DrawRect(x, y, w, h)
		SetAlpha 1.0

		'find out max value
		Local curvescount:Int = Self._values.Length
		Local maxvalue:Int[curvescount]
		For Local i:Int = 0 To curvescount - 1
			maxvalue[i] = 0
			For Local number:TNumberCurveValue = EachIn Self._values[i]
				If number._value > maxvalue[i] Then maxvalue[i] = number._value
			Next
			'Set each ratio
			If maxvalue[i] > 0
				Self._ratio[i] = h / maxvalue[i]
			Else
				Self._ratio[i] = 1.0
			EndIf
			Self._ratio[i] = Self._ratio[i] * 0.75 'don't be at the top each time, 3/4 of height is enough
		Next

		Local base:Float = y + h

		'draw
		For Local i:Int = 0 To curvescount - 1
			Local dx:Float = 0.0
			Local lastdx:Float = -1
			Local lastpoint:Float = Null
			If i = 0 Then SetColor 0, 255, 0
			If i = 1 Then SetColor 255, 0, 0
			If i = 2 Then SetColor 0, 0, 255

			For Local number:TNumberCurveValue = EachIn Self._values[i]
				Local point:Float = base - number._value * Self._ratio[i]
				If lastpoint = Null Then lastpoint = point
				DrawLine(x + Max(lastdx, 0), base - lastpoint, x + dx, base - point, True)
				lastdx = + 1
				dx = + 1
			Next
		Next

	End Method
End Type




Function MergeLists:TList(a:TList,b:TList)
	local list:TList = a.copy()
	for local obj:object = eachin b
		list.addLast(obj)
	next
	return list
End Function


Type TStringHelper
   Function FirstPart:String(txt:String,trenn:Byte=32)
      Local i:Short
      For i=0 To txt.length-1
         If txt[i]=trenn Then
           Return txt[..i]+":"
         End If
      Next
      Return ""
   End Function

   Function LastPart:String(txt:String,trenn:Byte=32)
      Local i:Short
      For i = 0 To txt.length - 1
         If txt[i]=trenn Then
          Return txt[(i+1)..]
         End If
      Next
      Return txt
   End Function

	Function gparam:String(txt:String, Count:Int, trenn:Byte = 32)
		Local x:Int = 0
		Local lastpos:Int = 0
		For local i:int = 0 To txt.length-1
			If txt[i]=trenn
				x:+1
				If x=count Then Return txt[lastpos..i]
				lastpos=i+1
			EndIf
		Next
		If x < Count - 1 Then Return Null
		Return txt[lastpos..x]
	End Function
End Type


Global LastSeekPos:Int =0
Function Stream_SeekString:Int(str:String, stream:TStream)
  If stream <> Null
    stream.Seek(LastSeekPos)
	Local lastchar:Int=0
	For Local i:Int = LastSeekPos To stream.Size()-1
	  stream.Seek(i)
	  If stream.ReadByte() = str[lastchar] Then lastchar:+1 Else lastchar = 0
	  If lastchar = Len(str) Then LastSeekPos=i;Return i
	Next
	If LastSeekPos > 0 Then Return Stream_SeekString(str,stream)
	Return -1
  EndIf
End Function

Function SortListFast(list:TList)
		Local Arr:Object[] = ListToArray(list)
		Arr.Sort()
		list = ListFromArray(Arr)
End Function



Function RequestFromUrl:String(myurl:String)
	Local myip:TStream    = ReadStream(myurl$)	'Now we gonna open the requested URL to read
	Local ipstring:String	= ""				'var to store the string returned by the php script
	'Successfully opened the requested URL?
	If Not myip 								'If not then we let the user know
	  ipstring$ = "Error"
	Else 										'If yes then we read all that our script has for us
	  While Not Eof(myip)
		ipstring$ :+ ReadLine(myip) 			'And store the output line by line
	  Wend
	EndIf
	CloseStream myip							'Don't forget to close the opened stream in the end!
	Return ipstring$							'Just return what we've got
End Function


'collection of useful functions
Type TFunctions
	Global roundToBeautifulEnabled:int = TRUE

	Function DrawOutlineRect:int(x:int, y:int, w:int, h:int)
		DrawLine(x, y, x + w, y, 0)
		DrawLine(x + w , y, x + w, y + h, 0)
		DrawLine(x + w, y + h, x, y + h, 0)
		DrawLine(x, y + h , x, y, 0)
	End Function


	Function CreateEmptyImage:TImage(width:int, height:int, flags:int=DYNAMICIMAGE | FILTEREDIMAGE)
		local image:TImage = CreateImage(width, height, flags)
		local pixmap:TPixmap = LockImage(image)
		pixmap.clearPixels(0)
		return image
	End Function


	Function ListDir:String(dir:String, onlyExtension:String = "", out:String = "")
		Local separator:String = "/"
		Local csd:Int = ReadDir(dir:String)
		If Not csd Then Return ""

		Repeat
		Local file:String = NextFile(csd)
		If file:String = "" Then Exit
		If FileType(dir + separator + file) = 1
			If onlyExtension = "" Or ExtractExt(dir + separator + file) = onlyExtension
				out = out + dir + separator + file + Chr:String(13) + Chr:String(10)
			EndIf
		EndIf

		If FileType(dir + separator + file) = 2 And file <> ".." And file <> "."
			out:String = out:String + ListDir:String(dir:String + separator + file:String, onlyExtension)
		EndIf
		Forever
		Return out$
	End Function


	Function RoundToBeautifulValue:int(value:int)
		'dev
		if not roundToBeautifulEnabled then return value

		if value = 0 then return 0
		if value <= 25 then return 25
		if value <= 50 then return 50
		if value <= 75 then return 75
		if value <= 100 then return 100
		'102 /50 = 2 mod 2 = 0 -> un/gerade
		If value <= 1000 then return ceil(value / 100.0)*100 'bisher 250
		If value <= 5000 then return ceil(value / 250.0)*250 'bisher 500
		If value <= 10000 then return ceil(value / 500.0)*500 'bisher 1.000
		If value <= 50000 then return ceil(value / 1000.0)*1000 'bisher 2.500
		If value <= 100000 then return ceil(value / 5000.0)*5000 'bisher 10.000
		If value <= 500000 then return ceil(value / 10000.0)*10000 'bisher 25.000
		If value <= 1000000 then return ceil(value / 25000.0)*25000 'bisher 250.000
		If value <= 2500000 then return ceil(value / 100000.0)*100000 'bisher --
		If value <= 5000000 then return ceil(value / 250000.0)*250000 'bisher --
		'>5.000.0000 in steps of 1 million
		return ceil(value / 1000000.0)*1000000
	End Function


	Function dottedValue:String(value:Float)
		'find out amount of digits before decimal point
		local intValue:int = int(value)
		local length:int = string(intValue).length

		if length <= 10 and length > 6
			return int(floor(int(value) / 1000000))+"."+int(floor(int(value) / 1000))+"."+Left( abs(int((int(value) - int(floor(int(value) / 1000000)*1000000)))) +"000",3)
		elseif length <= 7 and length > 3
			return int(floor(int(value) / 1000))+"."+Left( abs(int((int(value) - int(floor(int(value) / 1000)*1000)))) +"000",3)
		else
			return int(value)
		endif
	End Function


	'formats a value: 1000400 = 1,0 Mio
	Function convertValue:String(value:float, digitsAfterDecimalPoint:int=2, typ:Int=0, delimeter:string=",")
      ' typ 1: 250000 = 250Tsd
      ' typ 2: 250000 = 0,25Mio
      ' typ 3: 250000 = 0,0Mrd
      ' typ 0: 250000 = 0,25Mio (automatically)

		'find out amount of digits before decimal point
		local intValue:int = int(value)
		local length:int = string(intValue).length
		'do not count negative signs.
		if intValue < 0 then length:-1

		'automatically
		if typ=0
			If length < 10 and length >= 7 Then typ=2
			If length >= 10 Then typ=3
		endif
		'250000 = 250Tsd -> divide by 1000
		if typ=1 then return MathHelper.floatToString(value/1000.0, 0)+" Tsd"
		'250000 = 0,25Mio -> divide by 1000000
		if typ=2 then return MathHelper.floatToString(value/1000000.0, 2)+" Mio"
		'250000 = 0,0Mrd -> divide by 1000000000
		if typ=3 then return MathHelper.floatToString(value/1000000000.0, 2)+" Mrd"
		'add thousands-delimiter: 10000 = 10.000
		if length <= 10 and length > 6
			return int(floor(int(value) / 1000000))+"."+int(floor(int(value) / 1000))+"."+Left( abs(int((int(value) - int(floor(int(value) / 1000000)*1000000)))) +"000",3)
		elseif length <= 7 and length > 3
			return int(floor(int(value) / 1000))+"."+Left( abs(int((int(value) - int(floor(int(value) / 1000)*1000)))) +"000",3)
		else
			return int(value)
		endif
		'Return convertValue
    End Function

End Type




Type TCatmullRomSpline
	Field points:TList			= CreateList()	'list of the control points (TVec3D)
	Field cache:TVec3D[]						'array of cached points
	Field cacheGenerated:int	= FALSE
	Field totalDistance:float	= 0				'how long is the spline?
	const resolution:float		= 100.0

	Method New()
		'
	End Method

	Method addXY:TCatmullRomSpline(x:float,y:float)
		points.addLast( new TVec3D.Init(x, y) )
		cacheGenerated = FALSE
		return self
	End MEthod


	'Call this to add a point to the end of the list
	Method addPoint:TCatmullRomSpline(p:TVec3D)
		points.addlast(p)
		cacheGenerated = FALSE
		return self
	End Method


	Method addPoints:TCatmullRomSpline(p:TVec3D[])
		For local i:int = 0 to p.length-1
			self.points.addLast(p[i])
		Next
		self.cacheGenerated = FALSE
		return self
	End Method

	'draw the spline!
	Method draw:int()
		'Draw a rectangle at each control point so we can see
		'them (not relevant to the algorithm)
		For local p:TVec3D = EachIn self.points
			DrawRect(p.x-3 , p.y-3 , 7 , 7)
		Next

		'Check there are enough points to draw a spline
	'	If self.points.count()<4 Then Return FALSE

		'Get the first three  TLinks in the list of points. This algorithm
		'is going to work by working out the first three points, then
		'getting the last point at the start of the while loop. After the
		'curve section has been drawn, every point is moved along one,
		'and the TLink is moved to the next one so we can see if it's
		'null, and then get the next p3 from it if not.

		local pl:TLink	= Null
		local p0:TVec3D = Null
		local p1:TVec3D = Null
		local p2:TVec3D = Null
		local p3:TVec3D = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TVec3D( pl.value() )
		pl = pl.nextlink()
		p1 = TVec3D( pl.value() )
		pl = pl.nextlink()
		p2 = TVec3D( pl.value() )
		pl = pl.nextlink()

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = TVec3D( pl.value() )

			local oldX:float = p1.x
			local oldY:float = p1.y
			local x:float = 0.0
			local y:float = 0.0
			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For local t:float = 0 To 1 Step .01
				x = .5 * ( (2 * p1.x) + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t * t + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t * t * t)
				y = .5 * ( (2 * p1.y) + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t * t + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t * t * t)
				DrawLine oldX , oldY , x , y

				oldX = x
				oldY = y
			Next

			'Move one place along the list
			p0 = p1
			p1 = p2
			p2 = p3
			pl=pl.nextlink()
		Wend
	End Method

	Method GetTotalDistance:float()
		if not self.cacheGenerated then self.GenerateCache()

		return self.totalDistance
	End Method

	Method GenerateCache:float()
		If self.points.count()<4 Then Return 0

		local pl:TLink	= Null
		local p0:TVec3D, p1:TVec3D, p2:TVec3D, p3:TVec3D = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TVec3D( pl.value() )
		pl = pl.nextlink()
		p1 = TVec3D( pl.value() )
		pl = pl.nextlink()
		p2 = TVec3D( pl.value() )
		pl = pl.nextlink()

		local oldPoint:TVec3D = new TVec3D
		local cachedPoints:int = 0

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = TVec3D( pl.value() )

			oldPoint.CopyFrom(p1)

			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For local t:float = 0 To 1 Step 1.0/self.resolution
				local point:TVec3D = new TVec3D
				point.x = .5 * ( (2 * p1.x) + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t * t + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t * t * t)
				point.y = .5 * ( (2 * p1.y) + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t * t + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t * t * t)

				'set distance
				self.totalDistance :+ point.DistanceTo(oldPoint, false)
				'distance is stored in the current points Z coordinate
				point.z = self.totalDistance
				oldPoint.CopyFrom(point)

				'add to cache
				self.cache = self.cache[.. cachedPoints+1]
				self.cache[cachedPoints] = point
				cachedPoints:+1
			Next

			'Move one place along the list
			p0 = p1
			p1 = p2
			p2 = p3
			pl=pl.nextlink()

		Wend

		self.cacheGenerated = TRUE

		return self.totalDistance
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetPoint:TVec2D(distance:float, relativeValue:int=FALSE)
		if not self.cacheGenerated then self.generateCache()
		if relativeValue then distance = distance*self.totalDistance

		For local t:float = 0 To self.cache.length-1
			'if the searched distance is reached - return it
			if self.cache[t].z > distance
				return self.cache[Max(t-1, 0)].ToVec2D()
			endif
		Next
		return Null
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetTweenPoint:TVec2D(distance:float, relativeValue:int=FALSE)
		if not cacheGenerated then generateCache()
		if relativeValue then distance = distance * totalDistance

		local pointA:TVec3D = Null
		local pointB:TVec3D = Null

		For local t:float = 0 To cache.length-1
			'if the searched distance is reached
			if cache[t].z > distance
				if not pointA
					pointA = cache[Max(t-1, 0)]
				elseif not pointB
					pointB = cache[Max(t-1, 0)]
					exit
				endif
			endif
		Next

		'if no point was good enough - use the last possible one
		if not pointA then pointA = cache[cache.length-1]
		'if pointA is already the last one we have, the second point
		'could be the same
		if not pointB then pointB = pointA.Copy()

		if pointA and pointB
			'local distanceAB:float = abs(pointB.z - pointA.z)
			'local distanceAX:float = abs(distance - pointA.z)
			'local distanceBX:float = abs(distance - pointB.z)
			'local weightAX:float   = 1- distanceAX/distanceAB
			local weightAX:float   = 1- abs(distance - pointA.z)/abs(pointB.z - pointA.z)

			return new TVec2D.Init(..
				pointA.x*weightAX + pointB.x*(1-weightAX), ..
				pointA.y*weightAX + pointB.y*(1-weightAX) ..
			)
		else
			return Null
		endif
	End Method

End Type
