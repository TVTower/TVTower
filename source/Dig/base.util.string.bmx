﻿Rem
	====================================================================
	String helper classes
	====================================================================

	Various helpers to work with strings.



	====================================================================
	function UTF8toISO8859:
	-----------------------
	Source: https://github.com/maxmods/bah.mod/blob/master/
	        gtkmaxgui.mod/gtkcommon.bmx

	Modified: by Ronny Otto, changed to string-parameter

	Licence
	Copyright (c) 2006-2009 Bruce A Henderson
	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation files
	(the "Software"), to deal in the Software without restriction,
	including without limitation the rights to use, copy, modify, merge,
	publish, distribute, sublicense, and/or sell copies of the Software,
	and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
	BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.


	====================================================================
	function printf:
	----------------
	Source: https://code.google.com/p/diddy/source/browse/src/diddy/
	        format.monkey

	Modified: by Ronny Otto, added Rounding of Floats

	Licence:
	Copyright (c) 2011 Steve Revill and Shane Woolcock
	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation files
	(the "Software"), to deal in the Software without restriction,
	including without limitation the rights to use, copy, modify, merge,
	publish, distribute, sublicense, and/or sell copies of the Software,
	and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
	BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
End Rem
SuperStrict
Import Brl.Retro
?bmxng
Import Brl.StringBuilder
?
Import "base.util.math.bmx"
Import "external/string_comp.bmx"

Type StringHelper
	'extracts and returns all placeholders in a text
	'extracts old (%var%) and new (${var}) variable form 
	'ex.: Hi my name is %NAME% and also ${NAME} or ${NAME${SUB}} (which only sees "SUB")
	Function ExtractPlaceholdersCombined:String[](text:String, stripPlaceHolderTag:Int = False)
		Return ExtractPlaceholders(text, stripPlaceHolderTag) + ExtractPlaceholdersOld(text, "%", stripPlaceHolderTag)
	End Function


	'extracts and returns all placeholders in a text
	'ex.: Hi my name is %NAME% and also ${NAME} or ${NAME${SUB}} (which only sees "SUB")
	Function ExtractPlaceholders:String[](text:String, stripPlaceHolderTag:Int = False)
		Global escapeCharCode:Int = Asc("\")
		'since we hardcoded the tags we can simply use two variables..
		Global placeHolderOpenTagCharCode1:Int = Asc("$")
		Global placeHolderOpenTagCharCode2:Int = Asc("{")
		Global placeHolderCloseTagCharCode:Int = Asc("}")

		Local result:String[]
		Local escapeCharFound:Int = False
		Local placeHolderTagOpen:Int = False
		Local placeHolderStartPos:Int = 0
		Local placeHolderEndPos:Int = 0
		local charCode:Int
		
		For Local i:Int = 0 Until text.length
			charCode = text[i]
			
			'found the start of an escape char: "\${}"
			If charCode = escapeCharCode And Not escapeCharFound
				escapeCharFound = True
				Continue
			EndIf

			'found a placeholder start ("$") but not an escaped one ("\$")
			If charCode = placeHolderOpenTagCharCode1 And Not escapeCharFound
				'and also found the opener ("{")
				If i < text.length and text[i+1] = placeHolderOpenTagCharCode2
					placeHolderTagOpen = True
					placeHolderStartPos = i
				EndIf
			'closing the "inner" one? ("${hello${world}}" - close on last but one "}")
			'-> so finds "${world}"
			ElseIf charCode = placeHolderCloseTagCharCode 
				'add found placeholder
				If placeHolderTagOpen
					placeHolderTagOpen = False
					placeHolderEndPos = i

					if stripPlaceHolderTag
						result :+ [ text[placeHolderStartPos + 2 ..  placeHolderEndPos] ]
					else
						result :+ [ text[placeHolderStartPos ..  placeHolderEndPos + 1] ]
					endif
				EndIf
			EndIf
			
			escapeCharFound = False
		Next
		
		Return result
	End Function


	'extracts and returns all placeholders in a text
	'ex.: Hi my name is %NAME%
	Function ExtractPlaceholdersOld:String[](text:String, placeHolderChar:String="%", stripPlaceHolderChar:Int = False)
		Local result:String[]
		Local readingPlaceHolder:Int = False
		Local currentPlaceHolder:String = ""
		Local escapeCharCode:Int = Asc("\")
		Local escapeCharFound:Int = False
		Local placeHolderCharCode:Int = Asc(placeHolderChar)
		Local charCode:Int
		For Local i:Int = 0 Until text.length
			charCode = text[i]

			'found the start of an escape char
			If charCode = escapeCharCode And Not escapeCharFound
				escapeCharFound = True
				Continue
			EndIf

			'found a placeholder start or end
			If charCode = placeHolderCharCode And Not escapeCharFound
				'start
				If Not readingPlaceHolder
					readingPlaceHolder = True
					If stripPlaceHolderChar Then Continue
				'end (and extract it)
				Else
					If stripPlaceHolderChar
						result :+ [currentPlaceHolder]
					Else
						result :+ [currentPlaceHolder+placeholderChar]
					EndIf
					readingPlaceHolder = False
					currentPlaceHolder = ""

					Continue
				EndIf
			EndIf

			If readingPlaceHolder
				currentPlaceHolder :+ Chr(charCode)
			EndIf

			escapeCharFound = False
		Next

		Return result
	End Function


	Function RSetChar:String(str:String, n:Int, char:String=" ")
		If str.length > n Then Return str[n+1 ..]

		Local paddedStr:String = ""
		For Local i:Int = n Until str.length Step -1
			paddedStr :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		If paddedStr.length + str.length > n
			paddedStr = paddedStr[.. n-str.length]
		EndIf

		Return paddedStr + str
	End Function


	Function LSetChar:String(str:String, n:Int, char:String=" ")
		If str.length > n Then Return str[.. n]

		Local paddedStr:String = ""
		For Local i:Int = n Until str.length Step -1
			paddedStr :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		If paddedStr.length + str.length > n
			paddedStr = paddedStr[.. n-str.length]
		EndIf

		Return str + paddedStr
	End Function


	Function MSetChar:String(str:String, n:Int, char:String=" ")
		Local leftOffset:Int = (n - str.length)/2
		Local rightOffset:Int = (n+1 - str.length)/2
		If str.length > n Then Return str[leftOffset .. (n - rightOffset - leftOffset)]

		Local paddedStrL:String = ""
		For Local i:Int = 0 Until leftOffset
			paddedStrL :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		If paddedStrL.length > leftOffset Then paddedStrL = paddedStrL[.. leftOffset]

		Local paddedStrR:String = ""
		For Local i:Int = 0 Until rightOffset
			paddedStrR :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		If paddedStrR.length > rightOffset Then paddedStrR = paddedStrR[.. rightOffset]


		Return paddedStrL + str + paddedStrR
	End Function


	Function NumericFromString:Long(str:String)
		Local resultString:String = ""
		'take over numbers
		For Local i:Int = 0 Until str.length
			Local ch:Int = str[i]
			If (ch >= Asc("0") And ch <= Asc("9")) Or ch = Asc("-")
				resultString :+ Chr(ch)
			EndIf
		Next
		Return Long(resultString)
	End Function


	?bmxng
	Function JoinIntArray:String(glue:String, intArray:Int[])
		Local sb:TStringBuilder = New TStringBuilder()
		For Local i:Int = 0 Until intArray.Length
			If sb.Length() > 0 Then sb.Append(glue)
			sb.Append(intArray[i])
		Next
		Return sb.ToString()
	End Function
	?not bmxng
	Function JoinIntArray:String(glue:String, intArray:Int[])
		Local result:String = ""
		For Local i:Int = 0 Until intArray.length
			If result.length > 0 Then result :+ glue
			result :+ intArray[i]
		Next
		Return result
	End Function
	?


	Function RemoveArrayIndex:Int(index:Int, arr:String[] Var)
		If Not arr Or arr.length = 0
			Return False
		ElseIf arr.length = 1
			arr = New String[0]
		Else
			arr = arr[0 .. index] + arr[index+1 .. arr.Length]
		EndIf
		Return True
	End Function


	Function RemoveArrayEntry:Int(str:String, arr:String[] Var, caseSensitive:Int = True)
		Local atIndex:Int = GetArrayIndex(str, arr, caseSensitive)
		'not found
		If atIndex < 0 Then Return False

		RemoveArrayIndex(atIndex, arr)
		Return True
	End Function


	Function InArray:Int(str:String, arr:String[], caseSensitive:Int = True)
		Return (GetArrayIndex(str, arr, caseSensitive) >= 0)
	End Function


	Function GetArrayIndex:Int(str:String, arr:String[], caseSensitive:Int = True)
		If caseSensitive
			For Local i:Int = 0 Until arr.length
				If arr[i] = str Then Return i
			Next
		Else
			str = str.toLower()
			For Local i:Int = 0 Until arr.length
				If arr[i].ToLower() = str Then Return i
			Next
		EndIf
		Return -1
	End Function


	Function StringHash:Long(txt:String)
		Local hash:Long = 5381

		?bmxng
		For Local c:Int = EachIn txt
			hash = ((hash Shl 5) + hash) + c
		Next
		?Not bmxng
		For Local i:Int = 0 Until txt.length
			hash = ((hash Shl 5) + hash) + txt[i]
		Next
		?

		Return hash
	End Function


	Function IsAlpha:Int( ch:Int )
		Return (ch>=Asc("A") And ch<=Asc("Z")) Or (ch>=Asc("a") And ch<=Asc("z"))
	End Function


	Function IsDigit:Int( ch:Int )
		Return ch>=Asc("0") And ch<=Asc("9")
	End Function


	Function IsAlphaNum:Int( ch:Int )
		Return (ch>=Asc("0") And ch<=Asc("9")) Or ((ch>=Asc("A") And ch<=Asc("Z")) Or (ch>=Asc("a") And ch<=Asc("z")))
	End Function


	Function EscapeString:String(in:String, escapeChar:String=":")
		Return in.Replace("\","\\").Replace(escapeChar, "\"+escapeChar)
	End Function


	Function UnEscapeString:String(in:String, escapeChar:String=":")
		Return in.Replace("\"+escapeChar, escapeChar).Replace("\\", "\")
	End Function


	Function UTF8toISO8859:String(s:String)
		Local b:Short[] = New Short[s.length]
		Local bc:Int = -1
		Local c:Int, d:Int, e:Int
		For Local i:Int = 0 Until s.length
			bc:+1
			c = s[i]
			If c<128
				b[bc] = c
				Continue
			End If
			i:+1
			'avoid out-of-bounds
			If i >= s.length Then Continue

			d=s[i]
			If c<224
				b[bc] = (c-192)*64+(d-128)
				Continue
			End If
			i:+1
			'avoid out-of-bounds
			If i >= s.length Then Continue

			e = s[i]
			If c < 240
				b[bc] = (c-224)*4096+(d-128)*64+(e-128)
				Continue
			End If
		Next

		Return String.fromshorts(b, bc + 1)
	End Function


	Function RemoveNonAlphaNum:String(text:String)
		Local result:String
		For Local i:Int = 0 Until text.length
			If Not IsAlphaNum(text[i]) Then Continue
			result :+ Chr(text[i])
		Next
		Return result
	End Function



	Function RemoveUmlauts:String(text:String)
		Local s:String[]
		Local t:String[]
		s :+ ["ü Ü ö Ö ä Ä ß"]
		't :+ [Chr(129) +" "+ Chr(154) +" "+ Chr(148) +" "+ Chr(153) +" "+ Chr(132) +" "+ Chr(142) +" "+ Chr(225)]
		t :+ ["ue Ue oe Oe ae Ae ss"]

		s :+ ["„ “ ” « »"]
		t :+ ["~q ~q ~q ~q ~q"]

		s :+ ["é è ê É È Ê á à â Á À Â ó ò ô Ó Ò Ô ú ù û Ú Ù Û"]
		t :+ ["e e e E E E a a a A A A o o o O O O u u u U U U"]


		For Local i:Int = 0 Until s.length
			Local src:String[] = s[i].split(" ")
			Local tar:String[] = t[i].split(" ")
			For Local j:Int = 0 Until src.length
				text = text.Replace(src[j], tar[j])
			Next
		Next

		Return text
	End Function



	'fill a given string with the args provided
	'examples:
	'print StringHelper.printf("price %3.3f", ["12.12399"])
	'print StringHelper.printf("My name is %s, write it big! %S is %d", ["John", "John", "12"])
	Function printf:String(text:String, args:String[])
		Local argCount:Int = args.Length

		Local result:String = ""
		Local formatting:Int = False
		Local escapingBackslash:Int = False
		Local escapingPercent:Int = False
		Local textPos:Int = 0
		Local argnum:Int = 0
		Local char:String = ""

		While textPos < text.Length
			char = Chr(text[textPos])
			textPos :+ 1

			'if escaping with backslash, add the character
			If escapingBackslash
				result :+ char 'maybe better Mid(text, textPos, 1) for UTF8 ?
				escapingBackslash = False

			'if not escaping enable escaping when char is a backslash
			ElseIf char = "\"
				escapingBackslash = True

			'if receiving % while not formatting, enable formatting + escape percent
			ElseIf Not formatting And char = "%"
				formatting = True
				escapingPercent = True

			'if escaping a percent and receiving another one, disable formatting
			ElseIf escapingPercent And char = "%"
				result :+ char
				escapingPercent = False
				formatting = False

			'if not formatting, just add the character
			ElseIf Not formatting
				result :+ char


			'if formatting
			Else
				'check if text contains more placeholders than arguments given
				If argnum >= argcount
					Throw "StringHelper.printf(): not enough arguments given to format the given string."
				EndIf

				Local fmtarg:String = char
				Local foundPeriod:Int = False
				Local foundMinus:Int = False
				Local foundPadding:Int = False
				Local formatLengthStr:String = ""
				Local formatLength:Int = 0
				Local formatDPStr:String = ""
				Local formatDP:Int = 0
				Local formatType:String = ""

				' extract the rest of the format tag
				If Not IsValidFormat(char)
					While textPos < text.Length
						fmtarg :+ text[textPos..textPos+1]
						textPos :+ 1
						If IsValidFormat(fmtarg[fmtarg.Length-1..]) Then Exit
					Wend
				EndIf
				' set format type
				formatType = fmtarg[fmtarg.Length-1..]

				' get the last character as the format type and die if it's wrong
				If formatType = ""
					Throw "StringHelper.printF(): Error parsing format string!"
				EndIf

				Local fmtargptr:Int = 0
				' check for minus
				If Chr(fmtarg[0]) = "-"
					foundMinus = True
					fmtargptr :+ 1
				' check for padding
				ElseIf Chr(fmtarg[fmtargptr]) = "0"
					foundPadding = True
					fmtargptr :+ 1
				EndIf

				' check for digits up to a period or a character
				While fmtargptr < fmtarg.Length
					If IsValidFormat(fmtargptr)
						Exit
					ElseIf fmtarg[fmtargptr] >= "0"[0] And fmtarg[fmtargptr] <= "9"[0]
						If Not foundPeriod
							formatLengthStr :+ fmtarg[fmtargptr..fmtargptr+1]
						Else
							formatDPStr :+ fmtarg[fmtargptr..fmtargptr+1]
						EndIf
					ElseIf fmtarg[fmtargptr] = "."[0]
						foundPeriod = True
					EndIf
					fmtargptr :+ 1
				Wend

				formatting = False
				If formatLengthStr <> "" Then formatLength = Int(formatLengthStr)
				If formatDPStr <> "" Then formatDP = Int(formatDPStr)

				'integer
				If formatType = "d"
					Local ds:String = Int(args[argnum])
					While ds.Length < formatLength
						If foundPadding
							ds = "0"+ds
						ElseIf foundMinus
							ds :+ " "
						Else
							ds = " "+ds
						EndIf
					Wend
					result :+ ds
				'float (or double)
				ElseIf formatType = "f"
					'Ronny: replaced code with a rounding one from
					'       our framework
					Local df:Double = Double(args[argnum])
					result :+ MathHelper.NumberToString(df, formatDP)
				'char
				ElseIf formatType = "c"
					If foundPadding Or foundMinus
						Throw "StringHelper.printf(): Error parsing format string!"
					EndIf
					result :+ Chr(Int(args[argnum]))
				'string
				ElseIf formatType = "s" Or formatType = "S"
					If foundPadding
						Throw "StringHelper.printf(): Error parsing format string!"
					EndIf
					Local ds:String = args[argnum]
					If formatType = "S" Then ds = ds.ToUpper()
					While ds.Length < formatLength
						If foundMinus
							ds :+ " "
						Else
							ds = " " + ds
						EndIf
					Wend
					result :+ ds
				'hex
				ElseIf formatType = "x" Or formatType = "X"
					Local ds:String = Hex(Int(args[argnum])).ToLower()
					If formatType = "X" Then ds = ds.ToUpper()
					While ds.Length < formatLength
						If foundPadding
							ds = "0" + ds
						ElseIf foundMinus
							ds :+ " "
						Else
							ds = " " + ds
						EndIf
					Wend
					result :+ ds
				EndIf

				argnum :+ 1
			EndIf
		Wend
		Return result

		'helper function
		Function IsValidFormat:Int(char:String)
			'Return "dfsScxX".Find(char)
			Return char = "d" Or char = "f" Or char = "s" Or char = "S" Or char = "c" Or char = "x" Or char = "X"
		End Function
	End Function


	'fill a given string with the args provided
	'examples:
	'print StringHelper.printf("price %3.3f", ["12.12399"])
	'print StringHelper.printf("My name is %s, write it big! %S is %d", ["John", "John", "12"])
	Function printf2:String(text:String, args:String[])
		Local argCount:Int = args.Length

		Local result:String = ""
		Local formatting:Int = False
		Local escapingBackslash:Int = False
		Local escapingPercent:Int = False
		Local textPos:Int = 0
		Local argnum:Int = 0
		Local char:String = ""

		While textPos < text.Length
			char = Chr(text[textPos])
			textPos :+ 1

			'if escaping with backslash, add the character
			If escapingBackslash
				result :+ char 'maybe better Mid(text, textPos, 1) for UTF8 ?
				escapingBackslash = False

			'if not escaping enable escaping when char is a backslash
			ElseIf char = "\"
				escapingBackslash = True

			'if receiving % while not formatting, enable formatting + escape percent
			ElseIf Not formatting And char = "%"
				formatting = True
				escapingPercent = True

			'if escaping a percent and receiving another one, disable formatting
			ElseIf escapingPercent And char = "%"
				result :+ char
				escapingPercent = False
				formatting = False

			'if not formatting, just add the character
			ElseIf Not formatting
				result :+ char


			'if formatting
			Else
				'check if text contains more placeholders than arguments given
				If argnum >= argcount
					Throw "StringHelper.printf(): not enough arguments given to format the given string."
				EndIf

				Local fmtarg:String = char
				Local foundPeriod:Int = False
				Local foundMinus:Int = False
				Local foundPadding:Int = False
				Local formatLengthStr:String = ""
				Local formatLength:Int = 0
				Local formatDPStr:String = ""
				Local formatDP:Int = 0
				Local formatType:String = ""
				Local formatTypeI:Int

				' extract the rest of the format tag
				If Not IsValidFormat(char)
					While textPos < text.Length
						fmtarg :+ text[textPos..textPos+1]
						textPos :+ 1
						If IsValidFormat(fmtarg[fmtarg.Length-1..]) Then Exit
					Wend
				EndIf
				' set format type
				formatType = fmtarg[fmtarg.Length-1..]
				formatTypeI = Asc(formatType)

				' get the last character as the format type and die if it's wrong
				If formatTypeI = Asc("")
					Throw "StringHelper.printF(): Error parsing format string!"
				EndIf

				Local fmtargptr:Int = 0
				' check for minus
				If fmtarg[0] = Asc("-")
					foundMinus = True
					fmtargptr :+ 1
				' check for padding
				ElseIf fmtarg[fmtargptr] = Asc("0")
					foundPadding = True
					fmtargptr :+ 1
				EndIf

				' check for digits up to a period or a character
				While fmtargptr < fmtarg.Length
					If IsValidFormat(fmtargptr)
						Exit
					ElseIf fmtarg[fmtargptr] >= Asc("0") And fmtarg[fmtargptr] <= Asc("9")
						If Not foundPeriod
							formatLengthStr :+ fmtarg[fmtargptr..fmtargptr+1]
						Else
							formatDPStr :+ fmtarg[fmtargptr..fmtargptr+1]
						EndIf
					ElseIf fmtarg[fmtargptr] = Asc(".")
						foundPeriod = True
					EndIf
					fmtargptr :+ 1
				Wend

				formatting = False
				If formatLengthStr.length > 0 Then formatLength = Int(formatLengthStr)
				If formatDPStr.length > 0 Then formatDP = Int(formatDPStr)

				'integer
				If formatTypeI = Asc("d")
					Local ds:String = Int(args[argnum])
					While ds.Length < formatLength
						If foundPadding
							ds = "0"+ds
						ElseIf foundMinus
							ds :+ " "
						Else
							ds = " "+ds
						EndIf
					Wend
					result :+ ds
				'float (or double)
				ElseIf formatTypeI = Asc("f")
					'Ronny: replaced code with a rounding one from
					'       our framework
					Local df:Double = Double(args[argnum])
					result :+ MathHelper.NumberToString(df, formatDP)
				'char
				ElseIf formatTypeI = Asc("c")
					If foundPadding Or foundMinus
						Throw "StringHelper.printf(): Error parsing format string!"
					EndIf
					result :+ Chr(Int(args[argnum]))
				'string
				ElseIf formatTypeI = Asc("s") Or formatTypeI = Asc("S")
					If foundPadding
						Throw "StringHelper.printf(): Error parsing format string!"
					EndIf
					Local ds:String = args[argnum]
					If formatTypeI = Asc("S") Then ds = ds.ToUpper()
					While ds.Length < formatLength
						If foundMinus
							ds :+ " "
						Else
							ds = " " + ds
						EndIf
					Wend
					result :+ ds
				'hex
				ElseIf formatTypeI = Asc("x") Or formatType = Asc("X")
					Local ds:String = Hex(Int(args[argnum])).ToLower()
					If formatTypeI = Asc("X") Then ds = ds.ToUpper()
					While ds.Length < formatLength
						If foundPadding
							ds = "0" + ds
						ElseIf foundMinus
							ds :+ " "
						Else
							ds = " " + ds
						EndIf
					Wend
					result :+ ds
				EndIf

				argnum :+ 1
			EndIf
		Wend
		Return result

		'helper function
		Function IsValidFormat:Int(char:String)
			'Return "dfsScxX".Find(char)
			'Return char = "d" Or char = "f" Or char = "s" Or char = "S" Or char = "c" Or char = "x" Or char = "X"
			Local charI:Int = Asc(char)
			Return charI = Asc("d") Or charI = Asc("f") Or charI = Asc("s") Or charI = Asc("S") Or charI = Asc("c") Or charI = Asc("x") Or charI = Asc("X")
		End Function
	End Function

	Function IntArrayToString:String(intArray:Int[], glue:String=",")
		Local result:String
		For Local i:Int = EachIn intArray
			result :+ i + glue
		Next
		If glue <> "" Then result = result[.. result.length - glue.length]
		Return result
	End Function


	Function StringToIntArray:Int[](s:String, delim:String=",")
		If s.length = 0 Then Return New Int[0]

		Local sArray:String[] = s.split(delim)
		Local a:Int[ sArray.length ]
		For Local i:Int = 0 Until a.length
			a[i] = Int(sArray[i])
		Next
		Return a
	End Function

	'convert first alpha (optional alphanumeric) character to uppercase.
	'does _not_ work with UTF8 characters (would need some utf8-library
	'like glib or so)
	Function UCFirst:String(s:String, skipNumeric:Int = True)
		If s.length = 0 Then Return ""

		'find first "to uppercase" char
		Local offset:Int = -1
		For Local i:Int = 0 Until s.length
			Local ch:Int = s[i]
			'first alpha char is already uppercase
			If ch >= Asc("A") and ch <= Asc("Z")
				Return s
			ElseIf (ch >= Asc("a") And ch <= Asc("z")) Or (Not skipNumeric And (ch >= Asc("0") And ch <= Asc("9")))
				offset = i
				exit
			EndIf
		Next
		If offset = 0
			Return s[.. offset + 1].ToUpper() + s[offset + 1 ..]
		ElseIf offset = s.length - 1
			Return s[.. s.length - 1] + Chr(s[s.length-1]).ToUpper()
		Else
			Return s[.. offset] + Chr(s[offset]).ToUpper() + s[offset + 1 .. ]
		EndIf
	End Function

	'convert very first character to uppercase, skips checks
	'of wether non-alpha-chars are there
	Function UCFirstSimple:String(s:String, length:Int = 1)
		If s.length = 0 Then Return ""

		Return Upper( Left(s, length) ) + Right(s, s.length - length)
	End Function
End Type
