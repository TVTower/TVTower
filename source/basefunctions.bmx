SuperStrict
Import brl.pngloader
Import "basefunctions_zip.bmx"
Import "basefunctions_lists.bmx" 'ilist + tobjectlist - faster than tlist for bigger amounts of data
Import "basefunctions_localization.bmx"
'Import "basefunctions_text.bmx"
Import "basefunctions_keymanager.bmx"	'holds pressed Keys and Mousebuttons for one mainloop instead of resetting it like MouseHit()
Import brl.reflection
Import "basefunctions_loadsave.bmx"
Import "basefunctions_xml.bmx"

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
	field currentNode:TxmlNode

	Function Create:TXmlHelper(filename:string)
		local obj:TXmlHelper = new TXmlHelper
		obj.filename	= filename
		obj.file		= TxmlDoc.parseFile(filename)
		obj.root		= obj.file.getRootElement()
		return obj
	End Function

	Method SetNode(newCurrentNode:TxmlNode)
		self.currentNode = newCurrentNode
	End Method

	Method FindRootChild:TxmlNode(nodeName:string)
		local children:TList = root.getChildren()
		For local child:TxmlNode = eachin children
			if child.getName() = nodeName then return child
		Next
		return null
	End Method

	Method FindChild:TxmlNode(nodeName:string)
		nodeName = nodeName.ToLower()
		local children:TList = currentNode.getChildren()
		For local child:TxmlNode = eachin children
			if child.getName().ToLower() = nodeName then return child
		Next
		return null
	End Method

	Method FindValue:string(fieldName:string, defaultValue:string, logString:string="")
		fieldName = fieldName.ToLower()

		'given node has attribute (<episode number="1">)
		If currentNode.getAttribute(fieldName) <> null
			Return currentNode.getAttribute(fieldName)
		endif

		'children
		local children:TList = currentNode.getChildren()

		For local subNode:TxmlNode = EachIn children
			If subNode.getName().ToLower() = fieldName then return subNode.getContent()
			If subNode.getAttribute(fieldName) <> null then Return subNode.getAttribute(fieldName)
		Next

		if logString <> "" then print logString

		return defaultValue
	EndMethod

	Method FindValueInt:int(fieldName:string, defaultValue:int, logString:string="")
		return int( self.FindValue(fieldName, string(defaultValue), logString) )
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

	TLogFile.AddLog("[" + CurrentTime() + "] " + debugtext + Upper(functiontext) + ": " + message)
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




Type TPosition
	Field x:Float
	Field y:Float

	Function Create:TPosition(_x:Float=0.0,_y:Float=0.0)
		Local tmpObj:TPosition = New TPosition
		tmpObj.SetX(_x)
		tmpObj.SetY(_y)
		Return tmpObj
	End Function

	Function CreateFromPos:TPosition(pos:TPosition)
		return TPosition.Create(pos.x,pos.y)
	End Function

	Method SetX(_x:Float)
		Self.x = _x
	End Method

	Method SetY(_y:Float)
		Self.y = _y
	End Method

	Method SetXY(_x:Float, _y:Float)
		Self.SetX(_x)
		Self.SetY(_y)
	End Method

	Method isSame:int(otherPos:TPosition)
		return self.x = otherPos.x AND self.y = otherPos.y
	End Method

	Method SetPos(otherPos:TPosition)
		Self.SetX(otherPos.x)
		Self.SetY(otherPos.y)
	End Method

	Function SwitchPos(Pos:TPosition Var, otherPos:TPosition Var)
		Local oldx:Float, oldy:Float
		oldx = Pos.x
		oldy = Pos.y
		Pos.x = otherpos.x
		Pos.y = otherpos.y
		otherpos.x = oldx
		otherpos.y = oldy
	End Function

 	Method Save()
		print "implement"
		rem
		LoadSaveFile.xmlBeginNode("POS")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
	 	LoadSaveFile.xmlCloseNode()
		endrem
	End Method

	Function Load:TPosition(pnode:xmlNode)
		print "implement load position"
		rem
		Local tmpObj:TPosition = New TPosition
		Local node:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(figure)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" And Upper(t.name()) = NODE.name
					t.Set(tmpObj, nodevalue)
				EndIf
			Next
			Node = Node.NextSibling()
		Wend
	  Return tmpObj
		endrem
  End Function
End Type


'--- color
'Type TColorFunctions

Function ARGB_Alpha:Int(ARGB:Int)
 Return (argb Shr 24) & $ff
 'Return Int((ARGB & $FF000000:Int) / $1000000:Int)
End Function

Function ARGB_Red:Int(ARGB:Int)
  Return (argb Shr 16) & $ff
' Return Int((ARGB & $00FF0000:Int) / $10000:Int)
End Function

Function ARGB_Green:Int(ARGB:Int)
  Return (argb Shr 8) & $ff
' Return Int((ARGB & $0000FF00:Int) / $100:Int)
End Function

Function ARGB_Blue:Int(ARGB:Int)
 Return (argb & $ff)
' Return (ARGB & $000000FF:Int)
End Function

Function ARGB_Color:Int(alpha:Int,red:Int,green:Int,blue:Int)
 Return (Int(alpha * $1000000) + Int(red * $10000) + Int(green * $100) + Int(blue))
End Function


'returns true if the given pixel is monochrome (grey)
Function isMonochrome:int(argb:Int)
Try
	Local alpha:Int = ARGB_Alpha(argb)
	Local red:Int = ARGB_Red(argb)
	Local green:Int = ARGB_Green(argb)
	Local blue:Int = ARGB_Blue(argb)
	                                                        '250
	If (red = green) And (red = blue) And(alpha <> 0) And(red < 250) Then Return green
	Return 0
Catch a$
	Print "abgefangen: "+a$
EndTry

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

Function WriteStringWithLen(str:String, stream:TStream)
  stream.WriteInt(Len(str))
  stream.WriteString(str)
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
	Global activated:Byte = 1
	Global Strings:TList = CreateList()

	Function DumpLog(file:String, doPrint:Int = 1)
		If TLogFile.Strings = Null Then TLogFile.Strings = CreateList()

		Local fi:TStream = WriteFile( file )

			WriteLine fi, "TVT Log V1.0"
			For Local MyText:String = EachIn Strings
				If doPrint = 1 then Print MyText
				WriteLine fi, MyText
			Next
		CloseFile fi
	End Function

	Function AddLog(MyText:String)
		Strings.AddLast(MyText)
	End Function
End Type

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

			WriteLine fi,""
			WriteLine fi,".-----------------------------------------------------------------------------."
			WriteLine fi,"| AppLog      |                                                               |"
			WriteLine fi,"|-----------------------------------------------------------------------------|"
			For Local MyText:String = EachIn TLogFile.Strings
				if len(MyText)<=75
					WriteLine fi, "| "+LSet(MyText, 75)+" |"
				else
					WriteLine fi, "| "+MyText
				endif
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

  'formats a value: 100400 = 100,4TSD
  'formatiert einen Zahlenwert: 100400 = 100,4TSD
  Function convertValue:String(value:String,nachkomma:Int,typ:Int)
      ' typ 1: 250000 = 250Tsd
      ' typ 2: 250000 = 0,25Mio
      ' typ 3: 250000 = 0,0Mrd
      ' typ 0: 250000 = 0,25Mio (automatisch)
      ' nachkomma - anzahl der Nachkommastellen, nicht genuegend Nachkommas vorhanden: passiert nix weiter
      Local delimeter:String = ","
      Local minus:String = ""
      Local laenge:Int
      If Int(value) < 0
        value = Mid(value, 2, Len(value))
        minus = "-"
      Else
        minus = ""
      EndIf

      laenge = Len(value)
      If laenge < 4
        For Local i:Int = 0 To laenge-3
          value = "0"+value
        Next
      EndIf

      If nachkomma < 1 Then delimeter = ""
      If typ = 0 Then
        If laenge <  7 Then typ=1
        If laenge < 10 and laenge >= 7 Then typ=2
        If laenge >= 10 Then typ=3
      EndIf
      If value = "0" Then typ = 0
      If typ = 0 Then Return "0"
      If typ = 1 Then Return minus + Mid(value, 1,Len(value)-(3*typ))+ delimeter + Mid(value, Len(value)-(3*typ-1),nachkomma)+ " Tsd"
      If typ = 2 Then Return minus + Mid(value, 1,Len(value)-(3*typ))+ delimeter + Mid(value, Len(value)-(3*typ-1),nachkomma)+ " Mio"
      If typ = 3 Then Return minus + Mid(value, 1,Len(value)-(3*typ))+ delimeter + Mid(value, Len(value)-(3*typ-1),nachkomma)+ " Mrd"
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
	field pos:TPosition = TPosition.Create(0,0)
  Field w:Int = 0
  Field h:Int = 0
  Field typ:String = ""
  Field slot:Int = 0
  Global List:TList = CreateList()

 	Function FindDragAndDropObject:TDragAndDrop(List:TList, _pos:TPosition)
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
	Field r:int=0, g:int=0, b:int=0

	Function Create:TColor(r:int=0,g:int=0,b:int=0)
		local obj:TColor = new TColor
		obj.r = r
		obj.g = g
		obj.b = b
		return obj
	End Function

	Method adjust(r:int=-1,g:int=-1,b:int=-1, overwrite:int=0)
		if overwrite
			self.r = r
			self.g = g
			self.b = b
		else
			self.r :+r
			self.g :+g
			self.b :+b
		endif
	End Method

	Method set()
		SetColor(self.r, self.g, self.b)
	End Method

	Method get()
		GetColor(self.r, self.g, self.b)
	End Method
End Type

Type TPlayerColor
   Field colR:Int = 0
   Field colG:Int = 0
   Field colB:Int = 0
   Field color:Int = 0
   Field used:Byte 'id of player who uses this color

   Global List:TList = CreateList()

	Method SetColor(colR:Int, colG:Int, colB:Int)
		self.colR = colR
		self.colG = colG
		self.colB = colB
	End Method

	Method ToInt:int()
		return ARGB_Color(255, colR, colG, colB )
	End Method

	Method FromInt:int(color:int)
		colR = ARGB_Red(color)
		colG = ARGB_Green(color)
		colB = ARGB_Blue(color)
	End Method

   Function GetColor:TPlayerColor(colR:Int, colG:Int, colB:Int)
     Local color:TPlayerColor
     For color = EachIn TPlayerColor.List
     	If color.colR = colR And color.colG = colG And color.colB = colB Then Return color
     Next
     Return Null
   End Function

   Method GetUnusedColor:TPlayerColor(playerID:Int)
     For Local color:TPlayerColor = EachIn TPlayerColor.List
     	If color.used = 0 Then color.used =playerID; Self.used=0; Return color
     Next
   End Method

   Function Create:TPlayerColor(r:Int = 0, g:Int = 0, b:Int = 0, used:Byte = 0)
    Local locObject:TPlayerColor = TPlayerColor.GetColor(r, g, b)
	If locObject = Null
		locObject = New TPlayerColor
	    locObject.colR = r
	    locObject.colG = g
	    locObject.colB = b
	    locObject.used = used
	    locObject.color = ARGB_Color(255,r,g,b)
	    List.AddLast(locObject)
	    Return locObject
	Else
		Return locObject
	EndIf
   End Function


   Method MySetColor()
		SetColor (colR, colG, colB)
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

Type Tparticle
		Field x:Float,y:Float
		Field xrange:Int,yrange:Int
		Field vel:Float
		Field angle:Float
		Field image:TImage
		Field life:float
		Field is_alive:Int
		Field alpha:Float
		Field scale:Float
		Field pred:Int,pgreen:Int,pblue:Int


		Method Spawn(px:Float,py:Float,pvel:Float,plife:Float,pscale:Float,pangle:Float,pxrange:Float,pyrange:Float)
			is_alive	= True
			x			= Rnd(px-(pxrange/2),px+(pxrange/2))
			y			= Rnd(py-(pyrange/2),py+(pyrange/2))
			vel			= pvel
			xrange		= pxrange
			yrange		= pyrange

			life		= plife / 1000.0
			scale		= pscale
			angle		= pangle
			alpha		= Rnd(1.5,3.5)
			pred		= Rnd(50,105)
			pgreen		= pred
			pblue		= Min(255,pred + 10)
		End Method

		Method Update(deltaTime:float = 1.0)
			life:-deltaTime
			If life <0 then is_alive = False
			if is_alive = True
				'pcount:+1
				vel:* 0.99 '1.02 '0.98
				x:+(vel*Cos(angle-90))*deltaTime
				y:-(vel*Sin(angle-90))*deltaTime
				alpha:*0.99*(1.0-deltaTime)
				If y < 330 Then 	scale:*1.03*(1.0-deltaTime)
				If y > 330 Then 	scale:*1.01*(1.0-deltaTime)
				angle:*0.999
				pred:* 1.005
			EndIf
		End Method

		Method Draw()
			If is_alive = True
				SetBlend LIGHTBLEND 'ALPHABLEND
				SetAlpha alpha
				SetColor pred,pred,pred
				SetRotation angle
				SetScale(scale/2,scale/2)
				DrawImage image,x,y
				SetAlpha 1.0
				SetBlend ALPHABLEND
				SetRotation 0
				SetScale 1,1
				SetColor 255,255,255
			EndIf
	    EndMethod
End Type


