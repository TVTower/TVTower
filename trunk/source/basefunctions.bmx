SuperStrict
Import brl.pngloader
Import "basefunctions_zip.bmx"
Import "basefunctions_localization.bmx"
'Import "basefunctions_text.bmx"
Import "basefunctions_keymanager.bmx"	'holds pressed Keys and Mousebuttons for one mainloop instead of resetting it like MouseHit()
Import brl.reflection

'Import bah.libxml
Import "external/libxml/libxml.bmx"
Import "external/persistence.mod/persistence.bmx"


'Mersenne: Random numbers
'reproduceable random numbers for network
Import "basefunctions_mersenne.c"

Extern "c"
  Function SeedRand(seed:int)
  Function Rand32:Int()
  Function RandMax:Int(hi:int)
  Function RandRange:Int(lo:int,hi:int)
End Extern
'------------------------

Type TApplicationSettings
	field fullscreen:int	= 0
	field directx:int		= 0
	field colordepth:int	= 16
	field width:int			= 800
	field height:int		= 600
	field hertz:int			= 60
	field flag:Int			= 0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER

	Function Create:TApplicationSettings()
		local obj:TApplicationSettings = new TApplicationSettings
		return obj
	End Function
End Type


Type TXmlHelper
	field filename:string =""
	field file:TxmlDoc
	field root:TxmlNode

	Function Create:TXmlHelper(filename:string)
		local obj:TXmlHelper = new TXmlHelper
		obj.filename	= filename
		obj.file		= TxmlDoc.parseFile(filename)
		obj.root		= obj.file.getRootElement()
		return obj
	End Function

	Method FindRootChild:TxmlNode(nodeName:string)
		local children:TList = root.getChildren()
		if not children then return null
		For local child:TxmlNode = eachin children
			if child.getName() = nodeName then return child
		Next
		return null
	End Method

	Method findAttribute:string(node:TxmlNode, attributeName:string, defaultValue:string)
		if node.hasAttribute(attributeName) <> null then return node.getAttribute(attributeName) else return defaultValue
	End Method


	Method FindChild:TxmlNode(node:TxmlNode, nodeName:string)
		nodeName = nodeName.ToLower()
		local children:TList = node.getChildren()
		if not children then return null
		For local child:TxmlNode = eachin children
			if child.getName().ToLower() = nodeName then return child
		Next
		return null
	End Method

	Method FindValue:string(node:TxmlNode, fieldName:string, defaultValue:string, logString:string="")
		fieldName = fieldName.ToLower()

		'given node has attribute (<episode number="1">)
		If node.hasAttribute(fieldName) <> null
			Return node.getAttribute(fieldName)
		endif
		'children
'		local children:TList = node.getChildren()
'		if children <> null and children.count() > 0
			For local subNode:TxmlNode = EachIn node
				if subNode.getType() = XML_TEXT_NODE then continue
				if subNode <> null
					If subNode.getName().ToLower() = fieldName then return subNode.getContent()
					If subNode.getName().ToLower() = "data" and subNode.hasAttribute(fieldName) then Return subNode.getAttribute(fieldName)
				endif
			Next
'		endif
		if logString <> "" then print logString
		return defaultValue
	EndMethod

	Method FindValueInt:int(node:TxmlNode, fieldName:string, defaultValue:int, logString:string="")
		local result:string = self.FindValue(node, fieldName, string(defaultValue), logString)
		if result = null then return defaultValue
		return int( result )
	End Method

	Method FindValueFloat:float(node:TxmlNode, fieldName:string, defaultValue:int, logString:string="")
		local result:string = self.FindValue(node, fieldName, string(defaultValue), logString)
		if result = null then return defaultValue
		return float( result )
	End Method

End Type


Type TData
	field data:TMap = CreateMap()

	Function Create:TData()
		local obj:TData = new TData
		return obj
	End Function

	Method Add:TData(key:string, data:object)
		self.data.insert(key, data)
		return self
	End Method

	Method AddString:TData(key:string, data:string)
		self.Add( key, object(data) )
		return self
	End Method

	Method AddNumber:TData(key:string, data:float)
		self.Add( key, object( string(data) ) )
		return self
	End Method

	Method AddObject:TData(key:string, data:object)
		self.Add( key, object( data ) )
		return self
	End Method

	Method Get:object(key:string, defaultValue:object=null)
		local result:object = self.data.ValueForKey(key)
		if result then return result
		return defaultValue
	End Method

	Method GetString:string(key:string, defaultValue:string=null)
		local result:object = self.Get(key)
		if result then return String( result )
		return defaultValue
	End Method

	Method GetInt:int(key:string, defaultValue:int = null)
		local result:object = self.Get(key)
		if result then return Int( float( String( result ) ) )
		return defaultValue
	End Method
End Type





Const DEBUG_ALL:Byte = 128
Const DEBUG_SAVELOAD:Byte = 64
Const DEBUG_NO:Byte = 0
Const DEBUG_NETWORK:Byte = 32
Const DEBUG_XML:Byte = 16
Const DEBUG_LUA:Byte = 8
Const DEBUG_LOADING:Byte = 4
Const DEBUG_UPDATES:Byte = 2
Const DEBUG_NEWS:Byte = 1
Const DEBUG_START:Byte = 3
Const DEBUG_IMAGES:Byte = 5

Function CurrentDateTime:String(_what:String="%d %B %Y")
	Local	time:Byte[256],buff:Byte[256]
	time_(time)
	strftime_(buff,256,_what,localtime_( time ))
	Return String.FromCString(buff)
End Function

Function PrintDebug(functiontext:String = "", message:String, Debug:Byte)
	Local debugtext:String = ""
	If Debug = DEBUG_NETWORK Then debugtext = "NET"
	If Debug = DEBUG_LOADING Then debugtext = "LOAD"
	If Debug = DEBUG_SAVELOAD Then debugtext = "SAVELOAD"
	If Debug = DEBUG_XML Then debugtext = "XML"
	If Debug = DEBUG_LUA Then debugtext = "LUA"
	If Debug = DEBUG_UPDATES Then debugtext = "UPDATES"
	If Debug = DEBUG_NEWS Then debugtext = "NEWS"
	If Debug = DEBUG_START Then debugtext = "START"
	If Debug = DEBUG_IMAGES Then debugtext = "IMAGES"
	debugtext = LSet(debugtext, 8) + "| "
	AppLog.AddLog("[" + CurrentTime() + "] " + debugtext + Upper(functiontext) + ": " + message)
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


Type TRectangle {_exposeToLua="selected"}
	Field position:TPoint {_exposeToLua saveload="normal"}
	Field dimension:TPoint {_exposeToLua saveload="normal"}

	Function Create:TRectangle(x:Float=0.0,y:Float=0.0, w:float=0.0, h:float=0.0)
		local obj:TRectangle = new TRectangle
		obj.position	= TPoint.Create(x,y)
		obj.dimension	= TPoint.Create(w,h)
		return obj
	End Function

	Method Copy:TRectangle()
		return TRectangle.Create(self.position.x, self.position.y, self.dimension.x, self.dimension.y)
	End Method

	'does the rects overlap?
	Method Intersects:int(rect:TRectangle) {_exposeToLua}
		return (   self.containsXY( rect.GetX(), rect.GetY() ) ..
		        OR self.containsXY( rect.GetX() + rect.GetW(),  rect.GetY() + rect.GetH() ) ..
		       )
	End Method

	'global helper variables should be faster than allocating locals each time (in huge amount)
	global ix:float,iy:float,iw:float,ih:float
	'get intersecting rectangle
	Method IntersectRect:TRectangle(rectB:TRectangle) {_exposeToLua}
		ix = max(self.GetX(), rectB.GetX())
		iy = max(self.GetY(), rectB.GetY())
		iw = min(self.GetX()+self.dimension.GetX(), rectB.position.GetX()+rectB.dimension.GetX() ) -ix
		ih = min(self.GetY()+self.dimension.GetY(), rectB.position.GetY()+rectB.dimension.GetY() ) -iy

		local intersect:TRectangle = TRectangle.Create(ix,iy,iw,ih)

		if iw > 0 AND ih > 0 then
			return intersect
		else
			return Null
		endif
	End Method

	'does the point overlap?
	Method containsPoint:int(point:TPoint) {_exposeToLua}
		return self.containsXY( point.GetX(), point.GetY() )
	End Method

	Method containsX:int(x:float) {_exposeToLua}
		return (    x >= self.position.GetX()..
		        And x <= self.position.GetX() + self.dimension.GetX() )
	End Method

	Method containsY:int(y:float) {_exposeToLua}
		return (    y >= self.position.GetY()..
		        And y <= self.position.GetY() + self.dimension.GetY() )
	End Method

	'does the rect overlap with the coordinates?
	Method containsXY:int(x:float, y:float) {_exposeToLua}
		return (    x >= self.position.GetX()..
		        And x <= self.position.GetX() + self.dimension.GetX() ..
		        And y >= self.position.GetY()..
		        And y <= self.position.GetY() + self.dimension.GetY() )
	End Method

	'rectangle names
	Method setXYWH(x:float,y:float,w:float,h:float)
		self.position.setXY(x,y)
		self.dimension.setXY(w,h)
	End Method

	Method GetX:float()
		return self.position.GetX()
	End Method

	Method GetY:float()
		return self.position.GetY()
	End Method

	Method GetW:float()
		return self.dimension.GetX()
	End Method

	Method GetH:float()
		return self.dimension.GetY()
	End Method

	'four sided functions
	Method setTLBR(top:float,left:float,bottom:float,right:float)
		self.position.setXY(top,left)
		self.dimension.setXY(bottom,right)
	End Method

	Method SetTop:int(value:float)
		return self.position.SetX(value)
	End Method

	Method SetLeft:int(value:float)
		return self.position.SetY(value)
	End Method

	Method SetBottom:int(value:float)
		return self.dimension.SetX(value)
	End Method

	Method SetRight:int(value:float)
		return self.dimension.SetY(value)
	End Method

	Method GetTop:float()
		return self.position.GetX()
	End Method

	Method GetLeft:float()
		return self.position.GetY()
	End Method

	Method GetBottom:float()
		return self.dimension.GetX()
	End Method

	Method GetRight:float()
		return self.dimension.GetY()
	End Method




	Method GetX2:float()
		return self.position.GetX() + self.dimension.GetX()
	End Method

	Method GetY2:float()
		return self.position.GetY() + self.dimension.GetY()
	End Method

	Method GetAbsoluteCenterPoint:TPoint()
		return TPoint.Create(Self.GetX() + Self.GetW()/2, Self.GetY() + Self.GetH()/2)
	End Method

End Type

Type TPoint {_exposeToLua="selected"}
	Field x:Float
	Field y:Float
	Field z:Float 'Tiefe des Raumes (für Audio) Minus-Werte = Hintergrund; Plus-Werte = Vordergrund

	Function Create:TPoint(_x:Float=0.0,_y:Float=0.0,_z:Float=0.0)
		Local tmpObj:TPoint = New TPoint
		tmpObj.SetX(_x)
		tmpObj.SetY(_y)
		tmpObj.SetZ(_z)
		Return tmpObj
	End Function

	Function CreateFromPos:TPoint(pos:TPoint)
		return TPoint.Create(pos.x,pos.y)
	End Function

	Method GetIntX:int() {_exposeToLua}
		return floor(self.x)
	End Method

	Method GetIntY:int() {_exposeToLua}
		return floor(self.y)
	End Method


	Method GetX:float() {_exposeToLua}
		return self.x
	End Method

	Method GetY:float() {_exposeToLua}
		return self.y
	End Method

	Method GetZ:float() {_exposeToLua}
		return self.z
	End Method

	Method SetX(_x:Float)
		Self.x = _x
	End Method

	Method SetY(_y:Float)
		Self.y = _y
	End Method

	Method SetZ(_z:Float)
		Self.z = _z
	End Method

	Method SetXY(_x:Float, _y:Float)
		Self.SetX(_x)
		Self.SetY(_y)
	End Method

	Method SetPos(otherPos:TPoint)
		Self.SetX(otherPos.x)
		Self.SetY(otherPos.y)
		Self.SetZ(otherPos.z)
	End Method

	Method MoveXY( _x:float, _y:float )
		Self.x:+ _x
		Self.y:+ _y
	End Method

	Method isSame:int(otherPos:TPoint, round:int=0) {_exposeToLua}
		if round
			return abs(self.x -otherPos.x)<1.0 AND abs(self.y -otherPos.y) < 1.0
		else
			return self.x = otherPos.x AND self.y = otherPos.y
		endif
	End Method

	Method isInRect:int(rect:TRectangle)
		return rect.containsPoint(self)
	End Method

	Method DistanceTo:float(otherPoint:TPoint, withZ:int = true)
		local distanceX:float = DistanceOfValues(x, otherPoint.x)
		local distanceY:float = DistanceOfValues(y, otherPoint.y)
		local distanceZ:float = DistanceOfValues(z, otherPoint.z)

		local distanceXY:float = Sqr(distanceX * distanceX + distanceY * distanceY) 'Wurzel(a² + b²) = Hypotenuse von X und Y

		If withZ and distanceZ <> 0
			Return Sqr(distanceXY * distanceXY + distanceZ * distanceZ) 'Wurzel(a² + b²) = Hypotenuse von XY und Z
		Else
			Return distanceXY
		Endif
	End Method

	Function DistanceOfValues:int(value1:int, value2:int)
		If (value1 > value2) Then
			Return value1 - value2
		Else
			Return value2 - value1
		EndIf
	End Function

	Function SwitchPos(Pos:TPoint Var, otherPos:TPoint Var)
		Local oldx:Float, oldy:Float, oldz:Float
		oldx = Pos.x
		oldy = Pos.y
		oldz = Pos.z
		Pos.x = otherpos.x
		Pos.y = otherpos.y
		Pos.z = otherpos.z
		otherpos.x = oldx
		otherpos.y = oldy
		otherpos.z = oldz
	End Function

 	Method Save()
		print "implement"
	End Method

	Function Load:TPoint(pnode:TxmlNode)
		print "implement load position"
	End Function
End Type


'--- color
'Type TColorFunctions

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
Function isMonochrome:int(argb:Int)
	If ARGB_Red(argb) = ARGB_Green(argb) And ARGB_Red(argb) = ARGB_Blue(argb) And ARGB_Alpha(argb) <> 0 then Return ARGB_Red(argb)
	'old with "white filter < 250"
	'filter should be done outside of that function
	'If (red = green) And (red = blue) And(alpha <> 0) And(red < 250) Then Return green
	Return 0
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

Function SaveScreenshot()

	Local filename:String, padded:String
	Local num:Int = 0

	padded = num
	While padded.length < 3
		padded = "0"+padded
	Wend
	filename = "screen"+padded+".png"

	While FileType(filename) <> 0
		num:+1

		padded = num
		While padded.length < 3
			padded = "0"+padded
		Wend
		filename = "screen"+padded+".png"
	Wend
	SetBlend ALPHABLEND
	Local img:TPixmap = GrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight())
	SavePixmapPNG(img, filename)

	Print "Screenshot saved as "+filename

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

Type TLogFile
	field Strings:TList		= CreateList()
	field title:string		= ""
	field filename:string	= ""
	global logs:TList		= CreateList()

	Function Create:TLogFile(title:string, filename:string)
		local obj:TLogFile = new TLogFile
		obj.title = title
		obj.filename = filename
		TLogfile.logs.addLast(obj)

		return obj
	End Function

	Function DumpLog(doPrint:Int = 1)
		For local logfile:TLogFile = eachin TLogFile.logs
			Local fi:TStream = WriteFile( logfile.filename )
			WriteLine fi, logfile.title
			For Local line:String = EachIn logfile.Strings
				If doPrint = 1 then Print line
				WriteLine fi, line
			Next
			CloseFile fi
		Next
	End Function

	Method AddLog:int(text:String, addDateTime:int=FALSE)
		if addDateTime then text = "[" + CurrentTime() + "] " + text
		Strings.AddLast(text)
		return TRUE
	End Method
End Type
Global AppLog:TLogFile = TLogFile.Create("TVT Log v1.0", "log.app.txt")

Type TProfiler
	Global activated:Byte = 1
	Global calls:TMap = CreateMap()
	Global lastCall:TCall = null

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
		EndIf
	End Function

	Function Leave:int( func:String )
		If TProfiler.activated
			Local call:TCall = TCall(calls.ValueForKey(func))
			If call <> null
				Local l:int = MilliSecs()-call.start
				call.times.addlast( string(l) )
				if call.parent <> null
					TProfiler.LastCall = call.parent
				endif
				Return true
			EndIf
		EndIf
		return false
	End Function
End Type


'collection of useful functions
Type TFunctions
	Function MouseIn:int(x:float,y:float,w:float,h:float)
		return TFunctions.IsIn(MouseX(), MouseY(), x,y,w,h)
	End Function

	Function DoMeet:int(startA:float, endA:float, startB:float, endB:float)
rem
		local tmp:float = 0
		'sort
		tmp		= Max(startA, endA)
		startA	= Min(startA, endA)
		enda	= tmp

		tmp		= Max(startB, endB)
		startB	= Min(startB, endB)
		endB	= tmp

		'DoMeet - 4 possibilities - but only 2 for not meeting
		' |--A--| .--B--.    or   .--B--. |--A--|
		'needs ordered start->end
'		return ( (startA < startB and endA < endB) or (startA > startB and endA > endB) )
endrem
		'DoMeet - 4 possibilities - but only 2 for not meeting
		' |--A--| .--B--.    or   .--B--. |--A--|
		return  not (Max(startA,endA) < Min(startB,endB) or Min(startA,endA) > Max(startB, endB) )
	End function

	Function IsIn:Int(x:Float, y:Float, rectx:Float, recty:Float, rectw:Float, recth:Float)
		If x >= rectx And x<=rectx+rectw And..
		   y >= recty And y<=recty+recth
			Return 1
		Else
			Return 0
		End If
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
		if value = 0 then return 0
		if value <= 25 then return 25
		if value <= 50 then return 50
		if value <= 75 then return 75
		if value <= 100 then return 100
		'102 /50 = 2 mod 2 = 0 -> un/gerade
		if value <= 1000 then return ceil(float(value) / 250.0)*250
		if value <= 5000 then return ceil(float(value) / 500.0)*500
		if value <= 10000 then return ceil(float(value) / 1000.0)*1000
		if value <= 50000 then return ceil(float(value) / 2500.0)*2500
		if value <= 100000 then return ceil(float(value) / 10000.0)*10000
		if value <= 500000 then return ceil(float(value) / 25000.0)*25000
		if value <= 1000000 then return ceil(float(value) / 250000.0)*250000
		return ceil(value / 2500000)*2500000
	End Function


  'formats a value: 1000400 = 1,0 Mio
	Function convertValue:String(value:String,nachkomma:Int=2,typ:Int=0)
      ' typ 1: 250000 = 250Tsd
      ' typ 2: 250000 = 0,25Mio
      ' typ 3: 250000 = 0,0Mrd
      ' typ 0: 250000 = 0,25Mio (automatisch)
      ' nachkomma - anzahl der Nachkommastellen, nicht genuegend Nachkommas vorhanden: passiert nix weiter
		Local delimeter:String	= ","
		Local minus:String		= ""
		Local laenge:Int		= 0
		If Int(value) < 0
			value = Mid(value, 2, Len(value))
			minus = "-"
		EndIf

		laenge = Len(string(int(value)))

		If nachkomma < 1 Then delimeter = ""
		If typ = 0
			'
'			If laenge <  4 Then typ=0
'			If laenge <  7 and laenge >= 4 Then typ=1
			If laenge < 9 and laenge >= 7 Then typ=2
			If laenge >= 9 Then typ=3
		EndIf
		If value = "0" Then typ = -1

		local dottedValue:string = ""
		if int(value) < 1000000 then dottedValue = int(floor(int(value) / 1000))+"."+Left( int((int(value) - int(floor(int(value) / 1000)*1000))) +"000",3)
		if int(value) < 1000 then dottedValue = value

		select typ
'			case -1		Return "0"
'			case 0		Return minus + value
'			case 1		Return minus + Mid(value, 1,Len(value)-(3*typ))+ delimeter + Mid(value, Len(value)-(3*typ-1),nachkomma)+ " Tsd"
			case 2		Return minus + Mid(value, 1,Len(value)-(3*typ))+ delimeter + Mid(value, Len(value)-(3*typ-1),nachkomma)+ " Mio"
			case 3 		Return minus + Mid(value, 1,Len(value)-(3*typ))+ delimeter + Mid(value, Len(value)-(3*typ-1),nachkomma)+ " Mrd"

			default		Return minus + dottedValue
		endselect
		'Return convertValue
    End Function

	Function convertPercent:String(value:String, nachkomma:Int)
		if float(value) = 0 then return "0"
		Local values:String[] = value.split(".")
		If values[1] <> Null Then Return values[0] + "." + Left(String(Ceil(Float(values[1]))), nachkomma) Else Return values[0]
	End Function
End Type
Global functions:TFunctions = New TFunctions


Type TDragAndDrop
	field pos:TPoint = TPoint.Create(0,0)
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

Type TColor
	Field r:int			= 0
	Field g:int			= 0
	Field b:int			= 0
	Field a:float		= 1.0
	Field ownerID:int	= 0				'store if a player/object... uses that color

	global list:TList	= CreateList()	'storage for colors (allows handle referencing)

	Function Create:TColor(r:int=0,g:int=0,b:int=0,a:float=1.0)
		local obj:TColor = new TColor
		obj.r = r
		obj.g = g
		obj.b = b
		obj.a = a
		return obj
	End Function

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

	Method adjust:TColor(r:int=-1,g:int=-1,b:int=-1, overwrite:int=0)
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

	Method set:TColor()
		SetColor(self.r, self.g, self.b)
		return self
	End Method

	'same as set()
	Method setRGB:TColor()
		SetColor(self.r, self.g, self.b)
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
End Type



'==================================================================================================================================
Type appKubSpline
  Field dataX:Float[]
  Field dataY:Float[]
  Field dataCount:Int =0
  Field koeffB:Float[]
  Field koeffC:Float[]
  Field koeffD:Float[]
  '------------------------------------------------------------------------------------------------------------
  ' gets data as FLOAT and calculates the cubic splines
  ' if x-, y-arrays size is different, only the smaller count is taken
  ' data must be sorted uprising for x
  Method GetData(x:Float[], y:Float[])
    Local i:Int =0

    Local count:Int =Min(x.length, y.length)
    dataX =x[..]
    dataX =x[..count]
    dataY =y[..]
    dataY =y[..count]
    koeffB =koeffB[..count]
    koeffC =koeffC[..count]
    koeffD =koeffD[..count]

    Local m:Int =count -2
    Local s:Float = 0.0
    Local r:Float = 0.0
    For i =0 To m
      koeffD[i] =dataX[i +1] -dataX[i]
      r =(dataY[i +1] -dataY[i]) /koeffD[i]
      koeffC[i] =r -s
      s =r
    Next
    s =0
    r =0
    koeffC[0] =0
    koeffC[count -1] =0
    For i =1 To m
      koeffC[i] =koeffC[i] +r *koeffC[i -1]
      koeffB[i] =(dataX[i -1] -dataX[i +1]) *2 -r *s
      s =koeffD[i]
      r =s /koeffB[i]
    Next
    For i =m To 1 Step -1
      koeffC[i] =(koeffD[i] *koeffC[i +1] -koeffC[i]) /koeffB[i]
    Next
    For i =0 To m
      s =koeffD[i]
      r =koeffC[i +1] -koeffC[i]
      koeffD[i] =r /s
      koeffC[i] =koeffC[i] *3
      koeffB[i] =(dataY[i +1] -dataY[i]) /s -(koeffC[i] +r) *s
    Next

    dataCount =count

  End Method
  '------------------------------------------------------------------------------------------------------------
  ' gets data as INT and calculates the cubic splines
  ' if x-, y-arrays size is different, only the smaller count is taken
  ' data must be sorted uprising for x
  Method GetDataInt(x:Int[], y:Int[])
    Local z:Int=0
    Local i:Int=0
    Local count:Int =Min(x.length, y.length)

    dataX =dataX[..count]
    For z =1 To count
      dataX[z -1] =Float(x[z -1])
    Next
    dataY =dataY[..count]
    For z =1 To count
      dataY[z -1] =Float(y[z -1])
    Next
    koeffB =koeffB[..count]
    koeffC =koeffC[..count]
    koeffD =koeffD[..count]

    Local m:Int =count -2
    Local s:Float
    Local r:Float
    For i =0 To m
      koeffD[i] =dataX[i +1] -dataX[i]
      r =(dataY[i +1] -dataY[i]) /koeffD[i]
      koeffC[i] =r -s
      s =r
    Next
    s =0
    r =0
    koeffC[0] =0
    koeffC[count -1] =0
    For i =1 To m
      koeffC[i] =koeffC[i] +r *koeffC[i -1]
      koeffB[i] =(dataX[i -1] -dataX[i +1]) *2 -r *s
      s =koeffD[i]
      r =s /koeffB[i]
    Next
    For i =m To 1 Step -1
      koeffC[i] =(koeffD[i] *koeffC[i +1] -koeffC[i]) /koeffB[i]
    Next
    For i =0 To m
      s =koeffD[i]
      r =koeffC[i +1] -koeffC[i]
      koeffD[i] =r /s
      koeffC[i] =koeffC[i] *3
      koeffB[i] =(dataY[i +1] -dataY[i]) /s -(koeffC[i] +r) *s
    Next

    dataCount =count

  End Method
  '------------------------------------------------------------------------------------------------------------
  ' returns kubic splines value as FLOAT at given x -position
   'or always 0 if currently no data is loaded
  Method value:Float(x:Float)

    If dataCount =0 Then Return 0

    If x <dataX[0] Then
      Repeat
        x :+dataX[dataCount -1] -dataX[0]
      Until x =>dataX[0]
    ElseIf x >dataX[dataCount -1] Then
      Repeat
        x :-dataX[dataCount -1] -dataX[0]
      Until x <=dataX[dataCount -1]
    End If

    Local q:Float =Sgn(dataX[dataCount -1] -dataX[0])
    Local k:Int =-1
    Local i:Int
    Repeat
      i =k
      k :+1
    Until (q *x <q *dataX[k]) Or k =dataCount -1

    q =x - dataX[i]
    Return ((koeffD[i] *q +koeffC[i]) *q +koeffB[i]) *q +dataY[i]

  End Method
  '------------------------------------------------------------------------------------------------------------
  ' returns kubic splines value as rounded INT at given x -position
   'or always 0 if currently no data is loaded
  Method ValueInt:Int(x:Float)

    If dataCount =0 Then Return 0

    If x <dataX[0] Then
      Repeat
        x :+dataX[dataCount -1] -dataX[0]
      Until x =>dataX[0]
    ElseIf x >dataX[dataCount -1] Then
      Repeat
        x :-dataX[dataCount -1] -dataX[0]
      Until x <=dataX[dataCount -1]
    End If

    Local q:Float =Sgn(dataX[dataCount -1] -dataX[0])
    Local k:Int =-1
    Local i:Int
    Repeat
      i =k
      k :+1
    Until (q *x <q *dataX[k]) Or k =dataCount -1

    q =x - dataX[i]
    Local tmpResult:Float =((koeffD[i] *q +koeffC[i]) *q +koeffB[i]) *q +dataY[i]
    If tmpResult -Floor(tmpResult) <=.5 Then
      Return Floor(tmpResult)
    Else
      Return Floor(tmpResult) +1
    End If

  End Method
  '------------------------------------------------------------------------------------------------------------

End Type
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

'Global colorfunctions:TColorFunctions = New TColorFunctions


