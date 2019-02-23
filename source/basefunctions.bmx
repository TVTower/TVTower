SuperStrict
Import brl.pngloader
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.virtualgraphics.bmx"
Import "Dig/base.util.xmlhelper.bmx"
Import "Dig/base.util.helper.bmx"
Import "Dig/base.util.string.bmx"

Import "external/zipengine.mod/zipengine.bmx"
Import brl.reflection
?Threaded
Import Brl.threads
?
'Import bah.libxml
?bmxng
Import "Dig/external/persistence.mod/persistence_mxml.bmx"
?not bmxng
Import "Dig/external/persistence.mod/persistence.bmx"
?
Import "Dig/base.util.mersenne.bmx"

Const CURRENCYSIGN:String = Chr(8364) 'eurosign



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
	Local list:TList = a.copy()
	For Local obj:Object = EachIn b
		list.addLast(obj)
	Next
	Return list
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
	Global roundToBeautifulEnabled:Int = True

	Function DrawOutlineRect:Int(x:Int, y:Int, w:Int, h:Int)
		DrawLine(x, y, x + w, y, 0)
		DrawLine(x + w , y, x + w, y + h, 0)
		DrawLine(x + w, y + h, x, y + h, 0)
		DrawLine(x, y + h , x, y, 0)
	End Function


	Function CreateEmptyImage:TImage(width:Int, height:Int, flags:Int=DYNAMICIMAGE | FILTEREDIMAGE)
		if width < 0 or height < 0 then Throw "CreateEmptyImage() called with invalid dimensions. Width="+width+", height="+height+"."
		Local image:TImage = CreateImage(width, height, flags)
		Local pixmap:TPixmap = LockImage(image)
		pixmap.ClearPixels(0)
		Return image
	End Function


	Function RoundToBeautifulValue:Long(value:Double)
		'dev
		If Not roundToBeautifulEnabled Then Return value

		If value = 0 Then Return 0
		If value <= 25 Then Return 25
		If value <= 50 Then Return 50
		If value <= 75 Then Return 75
		If value <= 100 Then Return 100
		'102 /50 = 2 mod 2 = 0 -> un/gerade
		If value <= 1000 Then Return Ceil(value / 100.0)*100 'bisher 250
		If value <= 5000 Then Return Ceil(value / 250.0)*250 'bisher 500
		If value <= 10000 Then Return Ceil(value / 500.0)*500 'bisher 1.000
		If value <= 50000 Then Return Ceil(value / 1000.0)*1000 'bisher 2.500
		If value <= 100000 Then Return Ceil(value / 5000.0)*5000 'bisher 10.000
		If value <= 500000 Then Return Ceil(value / 10000.0)*10000 'bisher 25.000
		If value <= 1000000 Then Return Ceil(value / 25000.0)*25000 'bisher 250.000
		If value <= 2500000 Then Return Ceil(value / 100000.0)*100000 'bisher --
		If value <= 5000000 Then Return Ceil(value / 250000.0)*250000 'bisher --
		'>5.000.0000 in steps of 1 million
		Return Ceil(value / 1000000.0)*1000000
	End Function


	'formats a given value from "123000,12" to "123.000,12"
	'optimized variant
	Function dottedValue:String(value:Double, thousandsDelimiter:String=".", decimalDelimiter:String=",", digitsAfterDecimalPoint:int = -1)
		'is there a "minus" in front ?
		Local addSign:Int = value < 0
		Local result:String
		Local decimalValue:string

		'only process decimals when requested
		if digitsAfterDecimalPoint > 0 and 1=2
			Local stringValues:String[] = String(Abs(value)).Split(".")
			Local fractionalValue:String = ""
			decimalValue = stringValues[0]
			if stringValues.length > 1 then fractionalValue = stringValues[1]

			'do we even have a fractionalValue <> ".000" ?
			if Long(fractionalValue) > 0
				'not rounded, just truncated
				fractionalValue = Left(fractionalValue, digitsAfterDecimalPoint)
				result :+ decimalDelimiter + fractionalValue
			endif
		else
			decimalValue = String(Abs(Long(value)))
		endif


		For Local i:Int = decimalValue.length-1 To 0 Step -1
			result = Chr(decimalValue[i]) + result

			'every 3rd char, but not if the last one (avoid 100 -> .100)
			If (decimalValue.length-i) Mod 3 = 0 And i > 0
				result = thousandsDelimiter + result
			EndIf
		Next

		if addSign
			Return "-" + result
		else
			Return result
		endif
	End Function


	Function dottedValue_OLD:String(value:Double, thousandsDelimiter:String=".", decimalDelimiter:String=",", digitsAfterDecimalPoint:int = -1)
		'is there a "minus" in front ?
		Local addSign:String = ""
		If value < 0 Then addSign="-"

		Local stringValue:String = String(Abs(value))
		'find out amount of digits before decimal point
		Local length:Int = String(Abs(Long(value))).length
		'add 2 to length, as this contains the "." delimiter
		Local fractionalValue:String = Mid(stringValue, length+2, -1)
		Local decimalValue:String = Left(stringValue, length)
		Local result:String = ""

		'do we have a fractionalValue <> ".000" ?
		If Long(fractionalValue) > 0
			if digitsAfterDecimalPoint > 0
				'not rounded, just truncated
				fractionalValue = Left(fractionalValue, digitsAfterDecimalPoint)
				result :+ decimalDelimiter + fractionalValue
			endif
		endif

		For Local i:Int = decimalValue.length-1 To 0 Step -1
			result = Chr(decimalValue[i]) + result

			'every 3rd char, but not if the last one (avoid 100 -> .100)
			If (decimalValue.length-i) Mod 3 = 0 And i > 0
				result = thousandsDelimiter + result
			EndIf
		Next
		Return addSign+result
	End Function


	'formats a value: 1000400 = 1,0 Mio
	Function convertValue:String(value:Double, digitsAfterDecimalPoint:Int=2, typ:Int=0, delimeter:String=",")
		typ = MathHelper.Clamp(typ, 0,3)
      ' typ 1: 250000 = 250Tsd
      ' typ 2: 250000 = 0,25Mio
      ' typ 3: 250000 = 0,0Mrd
      ' typ 0: 250000 = 0,25Mio (automatically)

		'find out amount of digits before decimal point
		Local longValue:Long = Long(value)
		Local length:Int = String(longValue).length
		'avoid problems with "0.000" being shown as "-21213234923"
		If value = 0 Then longValue = 0;length = 1
		'do not count negative signs.
		If longValue < 0 Then length:-1

		'automatically
		If typ=0
			If length < 10 And length >= 7 Then typ=2
			If length >= 10 Then typ=3
		EndIf
		'250000 = 250Tsd -> divide by 1000
		If typ=1 Then Return MathHelper.NumberToString(value/1000.0, 0)+" "+GetLocale("ABBREVIATION_THOUSAND")
		'250000 = 0,25Mio -> divide by 1000000
		If typ=2 Then Return MathHelper.NumberToString(value/1000000.0, 2)+" "+GetLocale("ABBREVIATION_MILLION")
		'250000 = 0,0Mrd -> divide by 1000000000
		If typ=3 Then Return MathHelper.NumberToString(value/1000000000.0, 2)+" "+GetLocale("ABBREVIATION_BILLION")

		'add thousands-delimiter: 10000 = 10.000
		return dottedValue(value, ".", ",", digitsAfterDecimalPoint)
    End Function

End Type




Type TCatmullRomSpline
	Field points:TList			= CreateList()	'list of the control points (TVec3D)
	Field cache:TVec3D[]						'array of cached points
	Field cacheGenerated:Int	= False
	Field totalDistance:Float	= 0				'how long is the spline?
	Const resolution:Float		= 100.0

	Method New()
		'
	End Method

	Method addXY:TCatmullRomSpline(x:Float,y:Float)
		points.addLast( New TVec3D.Init(x, y) )
		cacheGenerated = False
		Return Self
	End Method


	'Call this to add a point to the end of the list
	Method addPoint:TCatmullRomSpline(p:TVec3D)
		points.addlast(p)
		cacheGenerated = False
		Return Self
	End Method


	Method addPoints:TCatmullRomSpline(p:TVec3D[])
		For Local i:Int = 0 To p.length-1
			Self.points.addLast(p[i])
		Next
		Self.cacheGenerated = False
		Return Self
	End Method

	'draw the spline!
	Method draw:Int()
		'Draw a rectangle at each control point so we can see
		'them (not relevant to the algorithm)
		For Local p:TVec3D = EachIn Self.points
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

		Local pl:TLink	= Null
		Local p0:TVec3D = Null
		Local p1:TVec3D = Null
		Local p2:TVec3D = Null
		Local p3:TVec3D = Null

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

			Local oldX:Float = p1.x
			Local oldY:Float = p1.y
			Local x:Float = 0.0
			Local y:Float = 0.0
			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For Local t:Float = 0 To 1 Step .01
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

	Method GetTotalDistance:Float()
		If Not Self.cacheGenerated Then Self.GenerateCache()

		Return Self.totalDistance
	End Method

	Method GenerateCache:Float()
		If Self.points.count()<4 Then Return 0

		Local pl:TLink	= Null
		Local p0:TVec3D, p1:TVec3D, p2:TVec3D, p3:TVec3D = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TVec3D( pl.value() )
		pl = pl.nextlink()
		p1 = TVec3D( pl.value() )
		pl = pl.nextlink()
		p2 = TVec3D( pl.value() )
		pl = pl.nextlink()

		Local oldPoint:TVec3D = New TVec3D
		Local cachedPoints:Int = 0

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = TVec3D( pl.value() )

			oldPoint.CopyFrom(p1)

			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For Local t:Float = 0 To 1 Step 1.0/Self.resolution
				Local point:TVec3D = New TVec3D
				point.x = .5 * ( (2 * p1.x) + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t * t + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t * t * t)
				point.y = .5 * ( (2 * p1.y) + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t * t + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t * t * t)

				'set distance
				Self.totalDistance :+ point.DistanceTo(oldPoint, False)
				'distance is stored in the current points Z coordinate
				point.z = Self.totalDistance
				oldPoint.CopyFrom(point)

				'add to cache
				Self.cache = Self.cache[.. cachedPoints+1]
				Self.cache[cachedPoints] = point
				cachedPoints:+1
			Next

			'Move one place along the list
			p0 = p1
			p1 = p2
			p2 = p3
			pl=pl.nextlink()

		Wend

		Self.cacheGenerated = True

		Return Self.totalDistance
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetPoint:TVec2D(distance:Float, relativeValue:Int=False)
		If Not Self.cacheGenerated Then Self.generateCache()
		If relativeValue Then distance = distance*Self.totalDistance

		For Local t:Float = 0 To Self.cache.length-1
			'if the searched distance is reached - return it
			If Self.cache[t].z > distance
				Return Self.cache[Max(t-1, 0)].ToVec2D()
			EndIf
		Next
		Return Null
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetTweenPoint:TVec2D(distance:Float, relativeValue:Int=False)
		If Not cacheGenerated Then generateCache()
		If relativeValue Then distance = distance * totalDistance

		Local pointA:TVec3D = Null
		Local pointB:TVec3D = Null

		For Local t:Float = 0 To cache.length-1
			'if the searched distance is reached
			If cache[t].z > distance
				If Not pointA
					pointA = cache[Max(t-1, 0)]
				ElseIf Not pointB
					pointB = cache[Max(t-1, 0)]
					Exit
				EndIf
			EndIf
		Next

		'if no point was good enough - use the last possible one
		If Not pointA Then pointA = cache[cache.length-1]
		'if pointA is already the last one we have, the second point
		'could be the same
		If Not pointB Then pointB = pointA.Copy()

		If pointA And pointB
			'local distanceAB:float = abs(pointB.z - pointA.z)
			'local distanceAX:float = abs(distance - pointA.z)
			'local distanceBX:float = abs(distance - pointB.z)
			'local weightAX:float   = 1- distanceAX/distanceAB
			Local weightAX:Float   = 1- Abs(distance - pointA.z)/Abs(pointB.z - pointA.z)

			Return New TVec2D.Init(..
				pointA.x*weightAX + pointB.x*(1-weightAX), ..
				pointA.y*weightAX + pointB.y*(1-weightAX) ..
			)
		Else
			Return Null
		EndIf
	End Method

End Type


