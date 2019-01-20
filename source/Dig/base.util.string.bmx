Rem
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
Import "base.util.math.bmx"

Import "external/string_comp.bmx"

Type StringHelper
	'extracts and returns all placeholders in a text
	'ex.: Hi my name is %NAME%
	Function ExtractPlaceholders:string[](text:string, placeHolderChar:string="%", stripPlaceHolderChar:int = False)
		local result:string[]
		local readingPlaceHolder:int = False
		local currentPlaceHolder:string = ""
		local escapeCharCode:string = Asc("\")
		local escapeCharFound:int = False
		local placeHolderCharCode:int = Asc(placeHolderChar)
		local charCode:int
		For local i:int = 0 until text.length
			charCode = text[i]

			'found the start of an escape char
			if charCode = escapeCharCode and not escapeCharFound
				escapeCharFound = True
				continue
			endif

			'found a placeholder start or end
			If charCode = placeHolderCharCode and not escapeCharFound
				'start
				if not readingPlaceHolder
					readingPlaceHolder = True
					if stripPlaceHolderChar then continue
				'end (and extract it)
				else
					if stripPlaceHolderChar
						result :+ [currentPlaceHolder]
					else
						result :+ [currentPlaceHolder+placeholderChar]
					endif
					readingPlaceHolder = False
					currentPlaceHolder = ""

					continue
				endif
			EndIf

			if readingPlaceHolder
				currentPlaceHolder :+ chr(charCode)
			endif

			escapeCharFound = False
		Next

		return result
	End Function


	'extracts and returns all placeholders in a text
	'ex.: Hi my name is %NAME%
	Function ExtractPlaceholdersOld:string[](text:string, placeHolderChar:string="%", stripPlaceHolderChar:int = False)
		local result:string[]
		local readingPlaceHolder:int = False
		local currentPlaceHolder:string = ""
		local char:string
		'char for grouping placeholders: "%person:name%"
		local splitterChar:int = Asc(":")
		local underscoreChar:int = Asc("_")
		For local i:int = 0 until text.length
			char = chr(text[i])
			'found a potential placeholder start
			If char = placeHolderChar and not readingPlaceHolder
				readingPlaceHolder = True
			EndIf

			If readingPlaceHolder
				'found end of the placeholder?
				If char = placeHolderChar and currentPlaceHolder.find(placeHolderChar) >= 0
					readingPlaceHolder = False
					result :+ [currentPlaceHolder+char]
					if stripPlaceHolderChar
						result[result.length-1] = result[result.length-1][1 .. result[result.length-1].length-1]
					endif
					currentPlaceHolder = ""
					'go on with next char
					continue
				EndIf

				'add the placeHolderChar and alphanumeric characters to
				'the placeholder value
				If IsAlphaNum(Asc(char)) or char = placeHolderChar or text[i] = splitterChar or text[i] = underscoreChar
					currentPlaceHolder :+ char
				'found something different
				'ex.: a single placeholderChar ("The % of %ALL% is %X%")
				Else
					currentPlaceHolder = ""
					'go on with next char
					continue
				EndIf

			EndIf
		Next

		return result
	End Function


	Function RSetChar:string(str:string, n:int, char:string=" ")
		if str.length > n then return str[n+1 ..]

		local paddedStr:string = ""
		For local i:int = n until str.length step -1
			paddedStr :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		if paddedStr.length + str.length > n
			paddedStr = paddedStr[.. n-str.length]
		endif

		return paddedStr + str
	End Function


	Function LSetChar:string(str:string, n:int, char:string=" ")
		if str.length > n then return str[.. n]

		local paddedStr:string = ""
		For local i:int = n until str.length step -1
			paddedStr :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		if paddedStr.length + str.length > n
			paddedStr = paddedStr[.. n-str.length]
		endif

		return str + paddedStr
	End Function


	Function MSetChar:string(str:string, n:int, char:string=" ")
		local leftOffset:int = (n - str.length)/2
		local rightOffset:int = (n+1 - str.length)/2
		if str.length > n then return str[leftOffset .. (n - rightOffset - leftOffset)]

		local paddedStrL:string = ""
		For local i:int = 0 until leftOffset
			paddedStrL :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		if paddedStrL.length > leftOffset then paddedStrL = paddedStrL[.. leftOffset]

		local paddedStrR:string = ""
		For local i:int = 0 until rightOffset
			paddedStrR :+ char
		Next
		'maybe "char" is a sequence like "-=-=-"
		if paddedStrR.length > rightOffset then paddedStrR = paddedStrR[.. rightOffset]


		return paddedStrL + str + paddedStrR
	End Function


	Function NumericFromString:Long(str:string)
		local resultString:string = ""
		'take over numbers
		For local i:int = 0 until str.length
			local ch:int = str[i]
			if (ch >= Asc("0") And ch <= Asc("9")) or ch = Asc("-")
				resultString :+ Chr(ch)
			endif
		Next
		return Long(resultString)
	End Function


	Function JoinIntArray:string(glue:string, intArray:int[])
		local result:string = ""
		for local i:int = 0 until intArray.length
			if result <> "" then result :+ glue
			result :+ intArray[i]
		next
		return result
	End Function


	Function RemoveArrayIndex:int(index:int, arr:string[] var)
		if not arr or arr.length = 0
			return False
		elseif arr.length = 1
			arr = new String[0]
		else
			arr = arr[0 .. index] + arr[index+1 .. arr.Length]
		endif
		return True
	End Function


	Function RemoveArrayEntry:int(str:string, arr:string[] var, caseSensitive:int = True)
		local atIndex:int = GetArrayIndex(str, arr, caseSensitive)
		'not found
		if atIndex < 0 then return False

		RemoveArrayIndex(atIndex, arr)
		return True
	End function


	Function InArray:int(str:string, arr:string[], caseSensitive:int = True)
		return (GetArrayIndex(str, arr, caseSensitive) >= 0)
	End Function


	Function GetArrayIndex:int(str:string, arr:string[], caseSensitive:int = True)
		if caseSensitive
			For local i:int = 0 until arr.length
				if arr[i] = str then return i
			Next
		else
			str = str.toLower()
			For local i:int = 0 until arr.length
				if arr[i].ToLower() = str then return i
			Next
		endif
		return -1
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


	Function EscapeString:string(in:string, escapeChar:string=":")
		return in.replace("\","\\").replace(escapeChar, "\"+escapeChar)
	End Function


	Function UnEscapeString:string(in:string, escapeChar:string=":")
		return in.replace("\"+escapeChar, escapeChar).replace("\\", "\")
	End Function


	Function UTF8toISO8859:String(s:string)
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
			if i >= s.length then continue

			d=s[i]
			If c<224
				b[bc] = (c-192)*64+(d-128)
				Continue
			End If
			i:+1
			'avoid out-of-bounds
			if i >= s.length then continue

			e = s[i]
			If c < 240
				b[bc] = (c-224)*4096+(d-128)*64+(e-128)
				Continue
			End If
		Next

		Return String.fromshorts(b, bc + 1)
	End Function


	Function RemoveNonAlphaNum:string(text:string)
		local result:string
		For local i:int = 0 until text.length
			if not IsAlphaNum(text[i]) then continue
			result :+ chr(text[i])
		Next
		return result
	End Function



	Function RemoveUmlauts:string(text:string)
		local s:string[]
		local t:string[]
		s :+ ["ü Ü ö Ö ä Ä ß"]
		't :+ [Chr(129) +" "+ Chr(154) +" "+ Chr(148) +" "+ Chr(153) +" "+ Chr(132) +" "+ Chr(142) +" "+ Chr(225)]
		t :+ ["ue Ue oe Oe ae Ae ss"]

		s :+ ["„ “ ” « »"]
		t :+ ["~q ~q ~q ~q ~q"]

		s :+ ["é è ê É È Ê á à â Á À Â ó ò ô Ó Ò Ô ú ù û Ú Ù Û"]
		t :+ ["e e e E E E a a a A A A o o o O O O u u u U U U"]


		For local i:int = 0 until s.length
			local src:string[] = s[i].split(" ")
			local tar:string[] = t[i].split(" ")
			For local j:int = 0 until src.length
				text = text.replace(src[j], tar[j])
			Next
		Next

		return text
	End function



	'fill a given string with the args provided
	'examples:
	'print StringHelper.printf("price %3.3f", ["12.12399"])
	'print StringHelper.printf("My name is %s, write it big! %S is %d", ["John", "John", "12"])
	Function printf:String(text:string, args:string[])
		Local argCount:Int = args.Length

		Local result:String = ""
		Local formatting:Int = False
		Local escapingBackslash:Int = False
		Local escapingPercent:Int = False
		Local textPos:Int = 0
		Local argnum:Int = 0
		Local char:string = ""

		While textPos < text.Length
			char = chr(text[textPos])
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
				endif

				Local fmtarg:String = char
				Local foundPeriod:int = False
				Local foundMinus:int = False
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
				endif

				Local fmtargptr:Int = 0
				' check for minus
				If chr(fmtarg[0]) = "-"
					foundMinus = True
					fmtargptr :+ 1
				' check for padding
				ElseIf chr(fmtarg[fmtargptr]) = "0"
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
					endif
					result :+ chr(Int(args[argnum]))
				'string
				ElseIf formatType = "s" Or formatType = "S"
					If foundPadding
						Throw "StringHelper.printf(): Error parsing format string!"
					endif
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
		return result

		'helper function
		Function IsValidFormat:Int(char:String)
			'Return "dfsScxX".Find(char)
			Return char = "d" Or char = "f" Or char = "s" Or char = "S" Or char = "c" Or char = "x" Or char = "X"
		End Function
	End Function


	Function IntArrayToString:string(intArray:Int[], glue:string=",")
		local result:String
		For local i:int = EachIn intArray
			result :+ i + glue
		Next
		if glue <> "" then result = result[.. result.length - glue.length]
		return result
	End Function


	Function StringToIntArray:int[](s:string, delim:string=",")
		if s.length = 0 then return new Int[0]

		local sArray:string[] = s.split(delim)
		local a:int[ sArray.length ]
		For local i:int = 0 until a.length
			a[i] = int(sArray[i])
		Next
		return a
	End Function

	'convert first alpha (optional alphanumeric) character to uppercase.
	'does _not_ work with UTF8 characters (would need some utf8-library
	'like glib or so)
	Function UCFirst:String(s:String, length:Int = 1, skipNumeric:Int = True)
		If s.length = 0 Then Return ""

		For Local start:Int = 0 Until s.length
			Local ch:Int = s[start]
			If (ch>=Asc("a") And ch<=Asc("z")) Or (Not skipNumeric And (ch>=Asc("0") And ch<=Asc("9")))
				Return Left(s, start) + Upper( Mid(s, start+1, length) ) + Right(s, s.length - length - start)
			else
				'already uppercase, so skip one
				length :- 1
			EndIf
		Next

		Return s
	End Function

	'convert very first character to uppercase, skips checks
	'of wether non-alpha-chars are there
	Function UCFirstSimple:string(s:string, length:int = 1)
		if s.length = 0 then return ""

		return Upper( Left(s, length) ) + Right(s, s.length - length)
	End Function
End Type