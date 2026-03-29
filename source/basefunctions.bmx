SuperStrict
Import Brl.Max2D
Import Collections.ArrayList
Import Math.Vector
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.vector.bmx"
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.string.bmx"

'collection of useful functions
Type TFunctions
	Global roundToBeautifulEnabled:Int = True
	Global thousandsDelimiter:String=","
	Global decimalDelimiter:String="."
	Global currencyPosition:Int = 0
	Const CURRENCYSIGN:String = Chr(8364) 'eurosign


	'base/targetWidth of 0 leads to a triangle
	Function DrawBaseTargetRect(baseX:Float, baseY:Float, targetX:Float, targetY:Float, baseWidth:Int = 0, targetWidth:Int = 0)
		rem
		       (base)         (base)..-B
			A----x----B         _,x'   |
			 \   :   /       A-'   \_  |
			  \  :  /         '--.   \ |
			   \ : /              '--.\|
			    \:/                    C (target)
			     C (target)                     
		endrem

'		Local lengthBaseTarget:Float = sqr((base.x - target.x)^2 + (base.y - target.y)^2)
'		Local rotationBaseTarget:Float = acos((targety - baseY) / lengthBaseTarget)
		Local rotationBaseTarget:Float = acos((targetY - baseY) / sqr((baseX - targetX)^2 + (baseY - targetY)^2))
		if targetX < baseX then rotationBaseTarget :* -1

		Local bX:Float = baseX + cos(rotationBaseTarget) * baseWidth/2
		Local bY:Float = baseY - sin(rotationBaseTarget) * baseWidth/2
		Local aX:Float = baseX - cos(rotationBaseTarget) * baseWidth/2
		Local aY:Float = baseY + sin(rotationBaseTarget) * baseWidth/2

		Local cX:Float = targetX + cos(rotationBaseTarget) * targetWidth/2
		Local cY:Float = targetY - sin(rotationBaseTarget) * targetWidth/2
		Local dX:Float = targetX - cos(rotationBaseTarget) * targetWidth/2
		Local dY:Float = targetY + sin(rotationBaseTarget) * targetWidth/2
		
		DrawPoly([aX, aY, bX, bY, cX, cY, dX, dY])
	End Function
	

	Function DrawOutlineRect:Int(x:Int, y:Int, w:Int, h:Int)
		DrawLine(x, y, x + w-1, y, 0)
		DrawLine(x + w - 1 , y, x + w - 1, y + h - 1, 0)
		DrawLine(x + w - 1, y + h -1, x, y + h - 1, 0)
		DrawLine(x, y + h -1, x, y, 0)
	End Function


	Function DrawOutlineRect:Int(x:Int, y:Int, w:Int, h:Int, outlineColor:SColor8, inlineColor:SColor8)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float; oldA = GetAlpha()
		SetColor outlineColor
		SetAlpha oldA * outlineColor.a/255.0
		DrawLine(x, y, x + w-1, y, 0)
		DrawLine(x + w - 1 , y, x + w - 1, y + h - 1, 0)
		DrawLine(x + w - 1, y + h -1, x, y + h - 1, 0)
		DrawLine(x, y + h -1, x, y, 0)

		' is there something to draw despite the border?
		If w > 2 and h > 2
			SetColor inlineColor
			SetAlpha oldA * inlineColor.a/255.0
			DrawRect(x + 1, y + 1, w - 2, h - 2)
		EndIf
	
		SetColor(oldCol)
		SetAlpha(oldA)
	End Function

	Function CreateEmptyImage:TImage(width:Int, height:Int, flags:Int=DYNAMICIMAGE | FILTEREDIMAGE)
		if width < 0 or height < 0 then Throw "CreateEmptyImage() called with invalid dimensions. Width="+width+", height="+height+"."
		Local image:TImage = CreateImage(width, height, flags)
		Local pixmap:TPixmap = LockImage(image)
		pixmap.ClearPixels(0)
		Return image
	End Function


	Function RoundToBeautifulValue:Long(value:Double)
		If Not roundToBeautifulEnabled Then Return value

		Local sign:Int = 1
		Local absValue:Double = value
		If value < 0
			sign = -1
			absValue = -value
		End If

		If absValue = 0 Then Return 0
		If absValue <= 25      Then Return sign * 25
		If absValue <= 50      Then Return sign * 50
		If absValue <= 75      Then Return sign * 75
		If absValue <= 100     Then Return sign * 100

		If absValue <= 1000    Then Return sign * Ceil(absValue / 100.0   ) * 100
		If absValue <= 5000    Then Return sign * Ceil(absValue / 250.0   ) * 250
		If absValue <= 10000   Then Return sign * Ceil(absValue / 500.0   ) * 500
		If absValue <= 50000   Then Return sign * Ceil(absValue / 1000.0  ) * 1000
		If absValue <= 100000  Then Return sign * Ceil(absValue / 5000.0  ) * 5000
		If absValue <= 500000  Then Return sign * Ceil(absValue / 10000.0 ) * 10000
		If absValue <= 1000000 Then Return sign * Ceil(absValue / 25000.0 ) * 25000
		If absValue <= 2500000 Then Return sign * Ceil(absValue / 100000.0) * 100000
		If absValue <= 5000000 Then Return sign * Ceil(absValue / 250000.0) * 250000
		If absValue <=20000000 Then Return sign * Ceil(absValue / 500000.0) * 500000

		' >20.000.000 in steps of 1 million
		Return sign * Ceil(absValue / 1000000.0) * 1000000
	End Function


	Function GetFormattedCurrency:String(money:Long)
		'160 is the "no breaking space" code
		'8239 is the "narrow no breaking space" code
		'currencyPosition: 1 front no space
		'                  2 front with space
		'                  3 end no space
		'                  4 end with space
		Local result:String=""
		If money < 0
			result="-"
			money=-money
		EndIf
		Select currencyPosition
			Case 1
				result:+CURRENCYSIGN + LocalizedDottedValue(money)
			Case 2
				result:+CURRENCYSIGN + Chr(160) + LocalizedDottedValue(money)
			Case 3
				result:+LocalizedDottedValue(money) + CURRENCYSIGN
			Default
				result:+LocalizedDottedValue(money) + Chr(160) + CURRENCYSIGN
		EndSelect
		return result
	EndFunction


	'formats a given value from "123000,12" to "123.000,12"
	'using grouping and separator according to localization
	'compared to LocalizedNumberToString "truncateZeros" defaults to TRUE here!
	Function LocalizedDottedValue:String(value:Double, decimalPrecision:int = -1, truncateZeros:Int = True)
		Local thousandsSeparatorChar:Int = 0 'none
		Local decimalSeparatorChar:Int = Asc(".")
		if thousandsDelimiter.length Then thousandsSeparatorChar = thousandsDelimiter[0]
		if decimalDelimiter.length Then decimalSeparatorChar = decimalDelimiter[0]
		return MathHelper.DottedValue(value, thousandsSeparatorChar, decimalSeparatorChar, decimalPrecision, truncateZeros)
	End Function


	Function LocalizedNumberToString:String(number:Double, decimalPrecision:Int = 2, truncateZeros:Int = False)
		Local decimalSeparatorChar:Int = Asc(".")
		if decimalDelimiter.length Then decimalSeparatorChar = decimalDelimiter[0]
		Return MathHelper.NumberToString(number, decimalPrecision, truncateZeros, decimalSeparatorChar)
	End Function


	'converts a value in a way that it shows as much digits as needed to
	'distinguish between value and compareValue
	Function ConvertCompareValue:String(value:Double, compareValue:Double, decimalPrecision:Int = 2)
		If decimalPrecision < 0 Then decimalPrecision = 0
		If decimalPrecision > 10 Then decimalPrecision = 10

		If value = compareValue Then Return ConvertValue(value, decimalPrecision, 0)

		Local valueS:String
		For local i:int = decimalPrecision to 10
			valueS = ConvertValue(value, i, 0)
			If valueS <> ConvertValue(compareValue, i, 0)
				return valueS
			EndIf
		Next
		Return valueS 
	End Function


	'formats a value: 1000400 = 1,0 Mio
	Function convertValue:String(value:Double, decimalPrecision:Int=2, convertFormat:Int = 0)
		convertFormat = MathHelper.Clamp(convertFormat, 0, 3)
		' convertFormat 1: 250000 = 250Tsd
		' convertFormat 2: 250000 = 0,25Mio
		' convertFormat 3: 250000 = 0,0Mrd
		' convertFormat 0: 250000 = 0,25Mio (automatically)

		If decimalPrecision < 0 Then decimalPrecision = 0
		If decimalPrecision > 10 Then decimalPrecision = 10


		'find out amount of digits before decimal point
		Local longValue:Long = Long(value)
		'this does NOT count "-" in negative numbers as digit!
		Local length:Int = MathHelper.LongDigitCount(longValue)
		'avoid problems with "0.000" being shown as "-21213234923"
		If value = 0 Then longValue = 0;length = 1

		'automatically
		If convertFormat = 0
			If length < 10 And length >= 7
				convertFormat = 2
			ElseIf length >= 10 
				convertFormat = 3
			EndIf
		EndIf
		
		Select convertFormat
			Case 1 '250000 = 250Tsd -> divide by 1000
				Return LocalizedNumberToString(value/1000.0, 0) + " " + GetLocale("ABBREVIATION_THOUSAND")
			Case 2 '250000 = 0,25Mio -> divide by 1000000
				Return LocalizedNumberToString(value/1000000.0, decimalPrecision) + " " + GetLocale("ABBREVIATION_MILLION")
			Case 3 '250000 = 0,0Mrd -> divide by 1000000000
				Return LocalizedNumberToString(value/1000000000.0, decimalPrecision) + " " + GetLocale("ABBREVIATION_BILLION")
		End Select

		'add thousands-delimiter: 10000 = 10.000
		return LocalizedDottedValue(value, decimalPrecision)
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
	Method GetTweenPoint:SVec2F(distance:Float, relativeValue:Int=False)
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
		If Not pointB Then pointB = pointA

		If pointA And pointB
			'local distanceAB:float = abs(pointB.z - pointA.z)
			'local distanceAX:float = abs(distance - pointA.z)
			'local distanceBX:float = abs(distance - pointB.z)
			'local weightAX:float   = 1- distanceAX/distanceAB
			Local weightAX:Float   = 1- Abs(distance - pointA.z)/Abs(pointB.z - pointA.z)

			Return New SVec2F(pointA.x*weightAX + pointB.x*(1-weightAX), ..
			                  pointA.y*weightAX + pointB.y*(1-weightAX))
		Else
			Return New SVec2F(0,0)
		EndIf
	End Method

End Type


