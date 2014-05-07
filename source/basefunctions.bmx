SuperStrict
Import brl.pngloader
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.virtualgraphics.bmx"
Import "Dig/base.util.xmlhelper.bmx"
Import "Dig/base.util.helper.bmx"

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


Type TApplicationSettings
	field fullscreen:int	= 0
	field directx:int		= 0
	field colordepth:int	= 16
	field realWidth:int		= 800
	field realHeight:int	= 600
	field designedWidth:int	= 800
	field designedHeight:int= 600
	field hertz:int			= 60
	field flag:Int			= 0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER

	Function Create:TApplicationSettings()
		local obj:TApplicationSettings = new TApplicationSettings
		return obj
	End Function

	Method GetHeight:int()
		return self.designedHeight
	End Method

	Method GetWidth:int()
		return self.designedWidth
	End Method

End Type



Global CURRENT_TWEEN_FACTOR:float = 0.0
Function GetTweenResult:float(currentValue:float, oldValue:float, avoidShaking:int=TRUE)
	local result:float = currentValue * CURRENT_TWEEN_FACTOR + oldValue * (1.0 - CURRENT_TWEEN_FACTOR)
	if avoidShaking and Abs(result - currentValue) < 0.1 then return currentValue
	return result
End Function


Function GetTweenPoint:TPoint(currentPoint:TPoint, oldPoint:TPoint, avoidShaking:int=TRUE)
	return new TPoint.Init(..
	         GetTweenResult(currentPoint.x, oldPoint.x, avoidShaking),..
	         GetTweenResult(currentPoint.y, oldPoint.y, avoidShaking)..
	       )
End Function




Function CurrentDateTime:String(_what:String="%d %B %Y")
	Local	time:Byte[256],buff:Byte[256]
	time_(time)
	strftime_(buff,256,_what,localtime_( time ))
	Return String.FromCString(buff)
End Function



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


'for things happening every X moments
Type TIntervalTimer
	field interval:int		= 0		'happens every ...
	field intervalToUse:int	= 0		'happens every ...
	field actionTime:int	= 0		'plus duration
	field randomness:int	= 0		'value the interval can "change" on GetIntervall() to BOTH sides - minus and plus
	field timer:int			= 0		'time when event last happened

	Function Create:TIntervalTimer(interval:int, actionTime:int = 0, randomness:int = 0)
		local obj:TIntervalTimer = new TIntervalTimer
		obj.interval	= interval
		obj.actionTime	= actionTime
		obj.randomness	= randomness
		'set timer
		obj.reset()
		return obj
	End Function

	Method GetInterval:int()
		return self.intervalToUse
	End Method

	Method SetInterval(value:int, resetTimer:int=false)
		self.interval = value
		if resetTimer then self.Reset()
	End Method

	Method SetActionTime(value:int, resetTimer:int=false)
		self.actionTime = value
		if resetTimer then self.Reset()
	End Method

	'returns TRUE if interval is gone (ignores action time)
	'action time could be eg. "show text for actiontime-seconds EVERY interval-seconds"
	Method doAction:int()
		local timeLeft:int = Millisecs() - (self.timer + self.GetInterval() )
		return ( timeLeft > 0 AND timeLeft < self.actionTime )
	End Method

	'returns TRUE if interval and duration is gone (ignores duration)
	Method isExpired:int()
		return ( self.timer + self.GetInterval() + self.actionTime <= Millisecs() )
	End Method

	Method getTimeGoneInPercents:float()
		local restTime:int = Max(0, getTimeUntilExpire())
		if restTime = 0 then return 1.0
		return 1.0 - (restTime / float(self.GetInterval()))
	End Method

	Method getTimeUntilExpire:int()
		return self.timer + self.GetInterval() + self.actionTime - Millisecs()
	End Method

	Method reachedHalftime:int()
		return ( self.timer + 0.5*(self.GetInterval() + self.actionTime) <= Millisecs() )
	End Method

	Method expire()
		self.timer = -self.GetInterval()
	End Method

	Method reset()
		self.intervalToUse = self.interval + rand(-self.randomness, self.randomness)

		self.timer = Millisecs()
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

'Gibt Eingabewert zurueck, wenn innerhalb Grenzen, ansonsten passende Grenze
Function Clamp:Float(value:Float, minvalue:Float = 0.0, maxvalue:Float = 1.0)
	value=Max(value,minvalue)
	value=Min(value,maxvalue)
	Return value
End Function

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
TProfiler.Enter("SortFast")
		Local Arr:Object[] = ListToArray(list)
		Arr.Sort()
		list = ListFromArray(Arr)
  TPRofiler.Leave("SortFast")
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


Type TCall
	Field depth:int = 0
	Field parent:TCall = null
	Field name:String
	Field start:Int
	Field Times:TList
	Field calls:Int
	Method New()
		times = CreateList()
	End Method

End Type


Type TProfiler
	Global activated:Byte = 1
	Global calls:TMap = CreateMap()
	Global lastCall:TCall = null
	?Threaded
	Global accessMutex:TMutex = CreateMutex()
	?

	Function DumpLog( file:String )

		Local fi:TStream = WriteFile( file )

			WriteLine fi,".-----------------------------------------------------------------------------."
			WriteLine fi,"| AppProfiler |                                                               |"
			WriteLine fi,"|-----------------------------------------------------------------------------|"
			For Local c:TCall = EachIn calls.Values()
				Local totTime:int=0
				For Local time:string = EachIn c.times
					totTime:+int(time)
				Next
				local funcName:string = C.Name
				local depth:int = 0
				while Instr(funcName, "-") > 0
					funcName = Mid(funcName, Instr(funcName, "-")+1)
					depth:+1
				Wend
				c.depth = max(c.depth, depth)

				if c.depth > 0
					funcName = "'-"+funcName
					if c.depth >=2
						for local i:int = 0 to c.depth-2
							funcName = "  "+funcName
						Next
					endif
				endif
				local AvgTime:string = String( floor(int(1000.0*(Float(TotTime) / Float(c.calls)))) / 1000.0 )
				WriteLine fi, "| " + LSet(funcName, 24) + "  Calls: " + RSet(c.calls, 8) + "  Total: " + LSet(String(Float(tottime) / Float(1000)),8)+"s" + "  Avg:" + LSet(AvgTime,8)+"ms"+ " |"
			Next
			WriteLine fi,"'-----------------------------------------------------------------------------'"
		CloseFile fi

	End Function

	Function Enter:int(func:String)
		If TProfiler.activated
			?Threaded
				return TRUE
				'wait for the mutex to get access to child variables
				LockMutex(accessMutex)
			?

			Local call:tcall = null
			call = TCall(calls.ValueForKey(func))
			if call <> null
				call.start	= MilliSecs()
				call.calls	:+1
				Return true
			EndIf

			call = New TCall

			if TProfiler.LastCall <> null then call.depth = TProfiler.LastCall.depth +1
			'Print "Profiler: added new call:"+func + " depth:"+ call.depth
			call.parent	= TProfiler.LastCall
			call.calls	= 1
			call.name	= func
			call.start	= MilliSecs()
			calls.insert(func, call)
			TProfiler.LastCall = call
			?Threaded
				'wait for the mutex to get access to child variables
				UnLockMutex(accessMutex)
			?
		EndIf
	End Function

	Function Leave:int( func:String )
		If TProfiler.activated
			?Threaded
				return TRUE
				'wait for the mutex to get access to child variables
				LockMutex(accessMutex)
			?
			Local call:TCall = TCall(calls.ValueForKey(func))
			If call <> null
				Local l:int = MilliSecs()-call.start
				call.times.addlast( string(l) )
				if call.parent <> null
					TProfiler.LastCall = call.parent
				endif
				?Threaded
					'wait for the mutex to get access to child variables
					UnLockMutex(accessMutex)
				?
				Return true
			EndIf
			?Threaded
				'wait for the mutex to get access to child variables
				UnLockMutex(accessMutex)
			?
		EndIf
		return false
	End Function
End Type


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
		if typ=1 then return THelper.floatToString(value/1000.0, 0)+" Tsd"
		'250000 = 0,25Mio -> divide by 1000000
		if typ=2 then return THelper.floatToString(value/1000000.0, 2)+" Mio"
		'250000 = 0,0Mrd -> divide by 1000000000
		if typ=3 then return THelper.floatToString(value/1000000000.0, 2)+" Mrd"
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


Type TDragAndDrop
	Field pos:TPoint = new TPoint
	Field w:Int = 0
	Field h:Int = 0
	Field typ:String = ""
	Field slot:Int = 0
	Global List:TList = CreateList()

 	Function FindDragAndDropObject:TDragAndDrop(List:TList, _pos:TPoint)
 	  For Local P:TDragAndDrop = EachIn List
		If P.pos.isSame(_pos) Then Return P
	  Next
	  Return Null
 	End Function


	Function Create:TDragAndDrop(x:Int, y:Int, w:Int, h:Int, _typ:String="")
		Local DragAndDrop:TDragAndDrop=New TDragAndDrop
		DragAndDrop.pos.SetXY(x,y)
		DragAndDrop.w = w
		DragAndDrop.h = h
		DragAndDrop.typ = _typ
		List.AddLast(DragAndDrop)
		SortList List
		Return DragAndDrop
	EndFunction

    Method IsIn:Int(x:Int, y:Int)
		return (x >= pos.x And x <= pos.x + w And y >= pos.y And y <= pos.y + h)
    End Method

    Method CanDrop:Int(x:Int, y:Int, _Typ:String="")
		return (IsIn(x,y) = 1 And typ=_Typ)
    End Method
End Type



Type TCatmullRomSpline
	Field points:TList			= CreateList()	'list of the control points (TPoint)
	Field cache:TPoint[]						'array of cached points
	Field cacheGenerated:int	= FALSE
	Field totalDistance:float	= 0				'how long is the spline?
	const resolution:float		= 100.0

	Method New()
		'
	End Method

	Method addXY:TCatmullRomSpline(x:float,y:float)
		points.addLast( new TPoint.Init(x, y) )
		cacheGenerated = FALSE
		return self
	End MEthod


	'Call this to add a point to the end of the list
	Method addPoint:TCatmullRomSpline(p:TPoint)
		points.addlast(p)
		cacheGenerated = FALSE
		return self
	End Method


	Method addPoints:TCatmullRomSpline(p:TPoint[])
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
		For local p:TPoint = EachIn self.points
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
		local p0:TPoint = Null
		local p1:TPoint = Null
		local p2:TPoint = Null
		local p3:TPoint = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TPoint( pl.value() )
		pl = pl.nextlink()
		p1 = TPoint( pl.value() )
		pl = pl.nextlink()
		p2 = TPoint( pl.value() )
		pl = pl.nextlink()

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = TPoint( pl.value() )

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
		local p0:TPoint, p1:TPoint, p2:TPoint, p3:TPoint = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TPoint( pl.value() )
		pl = pl.nextlink()
		p1 = TPoint( pl.value() )
		pl = pl.nextlink()
		p2 = TPoint( pl.value() )
		pl = pl.nextlink()

		local oldPoint:TPoint = new TPoint
		local cachedPoints:int = 0

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = Tpoint( pl.value() )

			oldPoint.CopyFrom(p1)

			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For local t:float = 0 To 1 Step 1.0/self.resolution
				local point:TPoint = new TPoint
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
	Method GetPoint:TPoint(distance:float, relativeValue:int=FALSE)
		if not self.cacheGenerated then self.generateCache()
		if relativeValue then distance = distance*self.totalDistance

		For local t:float = 0 To self.cache.length-1
			'if the searched distance is reached - return it
			if self.cache[t].z > distance
				return self.cache[Max(t-1, 0)]
			endif
		Next
		return Null
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetTweenPoint:TPoint(distance:float, relativeValue:int=FALSE)
		if not cacheGenerated then generateCache()
		if relativeValue then distance = distance * totalDistance

		local pointA:TPoint = Null
		local pointB:TPoint = Null

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

			return new TPoint.Init(..
				pointA.x*weightAX + pointB.x*(1-weightAX), ..
				pointA.y*weightAX + pointB.y*(1-weightAX) ..
			)
		else
			return Null
		endif
	End Method

End Type
