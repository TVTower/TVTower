SuperStrict
Import brl.pngloader
Import "basefunctions_zip.bmx"
Import "basefunctions_lists.bmx" 'ilist + tobjectlist - faster than tlist for bigger amounts of data
Import "basefunctions_localization.bmx"
Import "basefunctions_text.bmx"
Import "basefunctions_keymanager.bmx"	'holds pressed Keys and Mousebuttons for one mainloop instead of resetting it like MouseHit()
Import brl.reflection
Import "basefunctions_loadsave.bmx"
Import "basefunctions_xml.bmx"

'Import bah.libxml


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
'	If (red = green) And (red = blue) And(alpha <> 0) And(red <> 0) Then Return green
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

Function StringSplit:String[] (text:String, Separator:String, MaxLength:Int = 0)
   If Separator = "" Then Return Null
   If text      = "" Then Return Null

   Local SeparatorCount:Int = 0
   Local TextPosition  :Int = 1
   Local LoopCounter   :Int
   Local Occurrence    :Int

   While Instr(text, Separator, TextPosition)
     TextPosition   =  Instr(text, Separator, TextPosition) + 1
     SeparatorCount :+ 1
   Wend

   If (MaxLength = 0) Or (MaxLength >= SeparatorCount) Then MaxLength = SeparatorCount

   Local Array:String[] = New String[MaxLength+1]

   If MaxLength <> SeparatorCount Then MaxLength :- 1

   For LoopCounter = 0 To MaxLength
     Occurrence = Instr(text, Separator)
     If Occurrence > 0 Then
       Array[LoopCounter] = Left(text, Occurrence-1)
       text               = Mid(text, Occurrence+Separator.length)
     Else
       Array[LoopCounter] = text
       text               = ""
     EndIf
   Next

   If text <> "" Then Array[LoopCounter] = text

   Return Array
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



Type TLength
	Field time:Int
End Type

Type TCall

	Field name:String
	Field start:Int
	Field Times:TList
	Field calls:Int
	Method New()
		times = CreateList()
	End Method

End Type

TLogFile.Strings = CreateList()
Type TLogFile
	Global activated:Byte = 1
	Global Strings:TList

	Function DumpLog(file:String, doPrint:Int = 1)
		If TLogFile.Strings = Null Then TLogFile.Strings = CreateList()

		Local fi:TStream = WriteFile( file )

			WriteLine fi, "TVT Log V1.0"
			For Local MyText:String = EachIn Strings
				If doPrint = 1
					Print MyText
				EndIf
				WriteLine fi, MyText
			Next
		CloseFile fi
	End Function

	Function AddLog(MyText:String)
		Strings.AddLast(MyText)
	End Function
End Type

tprofiler.calls = CreateList()
Type TProfiler
	Global activated:Byte = 1
	Global calls:TList

	Function DumpLog( file:String )

		Local fi:TStream = WriteFile( file )

			WriteLine fi,"Aurora Profiler Log V1.0"
			For Local c:TCall = EachIn calls

				WriteLine fi,"---------------------------------------------------------------------"
				Local totTime:int=0
				For Local t:TLength = EachIn c.times
					totTime:+t.time
				Next
				WriteLine fi, "Function:" + LSet:String(C.name, 30) + " Calls:" + c.calls + " Total:" + String(Float(tottime) / Float(1000)) + "s Avg:" + String((Float(TotTime) / Float(c.calls)) / Float(1000)) + "s"
'				WriteLine fi,"Function:"+C.name+" Calls:"+c.calls+" Total:"+TotTime+" Avg:"+Float(TotTime)/Float(c.calls)
'				WriteLine fi,"Total (Seconds):"+String( Float(tottime)/Float(1000) )
'				WriteLine fi,"Avg (Seconds):"+String( (Float(TotTime)/Float(c.calls) ) / Float(1000) )
			Next


		CloseFile fi

	End Function

	Function Enter(func:String)
	If TProfiler.activated

		For Local call:tcall = EachIn calls

			If call.name = func

				call.start = MilliSecs()
				call.calls:+1
				Return

			EndIf

		Next

		Local call:TCall = New TCall
		Print "added new call:"+func
		calls.addlast( call )
		call.calls = 1
		call.name = func
		call.start = MilliSecs()
	EndIf
	End Function

	Function Leave( func:String )
	If TProfiler.activated
		For Local call:TCall = EachIn calls

			If call.name = func

				Local l:TLength = New tlength
				l.time = MilliSecs()-call.start
				call.times.addlast( l )
				Return

			End If

		Next

'		RuntimeError "Unknown function"
	EndIf
	End Function

End Type


'collection of useful functions
Type TFunctions
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
		Local values:String[] = value.split(".")
		If values[1] <> Null Then Return values[0] + "." + Left(String(Ceil(Float(values[1]))), nachkomma) Else Return values[0]
	End Function

  Function DrawTextWithBG(value:String, x:Int, y:Int, bgAlpha:Float = 0.5, bgCol:Int = 0)
  	Local OldAlpha:Float = GetAlpha()
	Local colR:Int, colG:Int, colB:Int
	GetColor(colR, colG, colB)
  	SetAlpha bgAlpha
	SetColor bgCol, bgCol, bgCol
	DrawRect(x, y, TextWidth(value), TextHeight(value))
	SetAlpha OldAlpha
	SetColor colR, colG, colB
  	DrawText(value, x, y)
  End Function

  'returns used height
Function BlockText:Int(txt:String, x:Float, y:Float, width:Float, height:Float, align:Int = 0, _font:TImageFont = Null, colR:Int = 0, colG:Int = 0, colB:Int = 0, NoLineBreak:Byte = 0, doDraw:Int = 1)
Local charcount:Int = 0
Local deletedchars:Int = 0
Local charpos   : Int = 0
Local linetxt   : String
Local spaceAvaiable:Float = 0
Local oldcolr:Int = 0
Local oldcolg:Int = 0
Local oldcolb:Int = 0
Local alignedx:Int = 0
Local oldfont:TImageFont
Local usedHeight:Int = 0
  If _font = Null Then _font = GetImageFont()

  oldfont = GetImageFont()
  SetImageFont(_font)
  If doDraw
	  GetColor(oldcolr, oldcolg, oldcolb)
	  SetColor(colR,colG,colB)
  EndIf
  spaceAvaiable = height

  linetxt$ = txt$
 If NoLineBreak = False
  Repeat
    charcount = 0
	If TextWidth(linetxt$) >= width
	While TextWidth(linetxt$) >= width
      For charpos = 0 To Len(linetxt) - 1
		If linetxt[charpos] = Asc(" ") Then CharCount = charpos
		If linetxt[charpos] = Asc("-") Then CharCount = charpos - 1
		If linetxt[charpos] = Asc(Chr(13)) Then CharCount = charpos;charpos = Len(Linetxt) - 1
	  Next
	  linetxt = linetxt[..CharCount]
	Wend
	EndIf
    If 2 * TextHeight(linetxt) > SpaceAvaiable And linetxt <> txt[deletedchars..]
      If align = 0 Then alignedx = x
      If align = 1 Then alignedx = x + (width - TextWidth(linetxt[..Len(linetxt) - 3] ) / 2)
      If align = 2 Then alignedx = x + width - TextWidth(linetxt[..Len(linetxt) - 3] )
      If doDraw Then DrawText(linetxt[..Len(linetxt) - 3] + " ...", alignedx, y + Height - spaceAvaiable)
      charcount = 0
    Else
      If TextHeight(linetxt) < SpaceAvaiable
        If align = 0 Then alignedx = x
        If align = 1 Then alignedx = x + (width - TextWidth(linetxt)) / 2
        If align = 2 Then alignedx = x + width - TextWidth(linetxt)
        If doDraw Then DrawText(linetxt, alignedx, y + Height - spaceAvaiable)
      EndIf
    EndIf
    spaceAvaiable = spaceAvaiable - TextHeight(linetxt)
    deletedchars :+ (charcount+1)
    linetxt = txt[Deletedchars..]
  Until charcount = 0
  usedheight = Height - spaceAvaiable
 Else 'no linebreak allowed
   If TextWidth(linetxt$) >= width
     charcount = Len(linetxt$)-1
 	 While TextWidth(linetxt$) >= width
	   linetxt$ = linetxt$[..charcount]
	   charcount:-1
	 Wend
     If align = 0 Then alignedx = x
     If align = 1 Then alignedx = x+(width-TextWidth(linetxt$))/2
     If align = 2 Then alignedx = x+width-TextWidth(linetxt$)
     spaceAvaiable = spaceAvaiable - TextHeight(linetxt$[..Len(linetxt$)-2]+"..")
     If doDraw Then DrawText(linetxt:String[..Len(linetxt:String) - 2] + "..", alignedx, y)
   Else
     If align = 0 Then alignedx = x
     If align = 1 Then alignedx = x + (width - TextWidth(linetxt)) / 2
     If align = 2 Then alignedx = x + width - TextWidth(linetxt)
     spaceAvaiable = spaceAvaiable - TextHeight(linetxt)
     If doDraw Then DrawText(linetxt, alignedx, y)
   EndIf
   usedheight = TextHeight(linetxt)
 EndIf
  If doDraw
	  SetColor(oldcolr, oldcolg, oldcolb)
  EndIf
  SetImageFont(oldfont)
  Return usedheight
End Function
End Type
Global functions:TFunctions = New TFunctions


Type TDragAndDrop
  Field rectx:Int = 0
  Field recty:Int = 0
  Field rectw:Int = 0
  Field recth:Int = 0
  Field typ:String = ""
  Field slot:Int = 0
  Field used:Int = 0
  Global List:TList

    'set a dnd-target as unused (empty)
    'setze ein DND-Ziel als unbenutzt (frei)
    Method SetDragAndDropTargetUnused:Int()
      If Self <> Null
	    Self.used = 0
	    Return 1
	  EndIf
   	  Return 0
 	End Method

    'set a dnd-target as used (full)
    'setze ein DND-Ziel als benutzt (belegt)
    Method SetDragAndDropTargetUsed:Int()
 	  If Self <> Null
	    Self.used = 1
	    Return 1
	  EndIf
	  Return 0
 	End Method

	'set a dnd-target as used (full)
    'setze ein DND-Ziel als benutzt (belegt)
    Function FindAndSetDragAndDropTargetUsed:Int(List:TList, _x:Int, _y:Int)
	  Local P:TDragAndDrop = FindDragAndDropObject(list, _x, _y)
 	  If p <> Null
	    p.used = 1
	    Return 1
	  EndIf
	  Return 0
 	End Function

	'set a dnd-target as unused (empty)
    'setze ein DND-Ziel als unbenutzt (unbelegt)
    Function FindAndSetDragAndDropTargetUnUsed:Int(List:TList, _x:Int, _y:Int)
	  Local P:TDragAndDrop = FindDragAndDropObject(list, _x, _y)
 	  If p <> Null
	    p.used = 0
	    Return 1
	  EndIf
	  Return 0
 	End Function

 	Function FindDragAndDropObject:TDragAndDrop(List:TList, _x:Int, _y:Int)
 	  For Local P:TDragAndDrop = EachIn List
		If P.rectx = _x And P.recty = _y Then Return P
	  Next
	  Return Null
 	End Function


  Function Create:TDragAndDrop(x:Int, y:Int, w:Int, h:Int, _typ:String="")
    Local DragAndDrop:TDragAndDrop=New TDragAndDrop
    DragAndDrop.rectx = x
    DragAndDrop.recty = y
    DragAndDrop.rectw = w
    DragAndDrop.recth = h
    DragAndDrop.typ = _typ
    DragAndDrop.used = 0
    If Not List Then List = CreateList()
    List.AddLast(DragAndDrop)
    SortList List
    Return DragAndDrop
  EndFunction

    Method IsIn:Int(x:Int, y:Int)
      If x >= rectx And x <= rectx + rectw And y >= recty And y <= recty + recth
        Return 1
      Else
        Return 0
      EndIf
    End Method

    Method CanDrop:Int(x:Int, y:Int, _Typ:String="")
      If IsIn(x,y) = 1 And typ=_Typ 'used =0
      	 Return 1
      Else
         Return 0
      End If
    End Method

    Method Drop:Int(x:Int, y:Int, _typ:String="")
      If IsIn(x,y) = 1 And typ=_typ 'used =0
      	 used = 1
      	 Return 1
      Else
      	 used = 0
         Return 0
      End If
    End Method

	Method DrawMe()
        SetAlpha 0.8
			If used
			  SetColor 250,100,100
			Else
			  SetColor 100,100,100
			EndIf
			DrawRect(rectx,recty,rectw,recth)
		SetAlpha 1.0
	End Method

End Type


Type TPlayerColor
   Field colR:Int = 0
   Field colG:Int = 0
   Field colB:Int = 0
   Field color:Int = 0
   Field used:Byte 'id of player who uses this color

   Global List:TList = CreateList()


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
		Field life:Int
		Field is_alive:Int
		Field alpha:Float
		Field scale:Float
		Field pred:Int,pgreen:Int,pblue:Int


		Method Spawn(px:Float,py:Float,pvel:Float,plife:Float,pscale:Float,pangle:Float,pxrange:Float,pyrange:Float)
			is_alive = True
			x = Rnd(px-(pxrange/2),px+(pxrange/2))
			y = Rnd(py-(pyrange/2),py+(pyrange/2))


			vel = pvel
			xrange = pxrange
			yrange = pyrange

			life = plife

			scale = pscale

			angle = pangle

			alpha = Rnd(1.0,3.0)
			pred = Rnd(50,105)
			'pgreen = Rnd(0,255)
			'pblue = Rnd(0,255)
			pgreen = pred
			pblue = pred

		End Method

		Method Update()
			life:-1
			If life <0 Then is_alive = False
			If is_alive = True
				'pcount:+1
				vel:* 0.99 '1.02 '0.98
				x=x+(vel*Cos(angle-90))
				y=y-(vel*Sin(angle-90))
				alpha:*.98
				If y < 330 Then 	scale:*1.03
				If y > 330 Then 	scale:*1.01
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


