Rem
	====================================================================
	String2IntArray
	====================================================================

	Functions to either iterate over integers in a string, or to convert
	it to an integer array.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	TIntSpliterator: Copyright (C) 2026 Ronny Otto, digidea.de
	String2IntArray: Copyright (C) 2026 Ronny Otto, digidea.de

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
EndRem
SuperStrict



Function String2IntArray:Int[](s:String, separator:Int, skipEmpty:Int = False)
	Local _index:Int = 0
	Local _current:Int

	Local elementCount:Int = 1 'no comma needed for the first
	For Local char:Int = EachIn s
		If char = separator Then elementCount:+ 1
	Next

	Local result:Int[] = New Int[elementCount]
	Local resultIndex:Int = 0

	
	While _index < s.Length
		' If we're exactly at end, we may optionally yield one final empty token
		If _index = s.Length And skipEmpty Then Exit


		Local start:Int = _index
		' Scan to separator or end
		While _index < s.Length And s[_index] <> separator
			_index :+ 1
		Wend


		Local finish:Int = _index
		' Consume separator if present
		If _index < s.Length And s[_index] = separator
			_index :+ 1
		EndIf

		' Maybe skip empty tokens
		If skipEmpty And finish = start
			Continue
		EndIf

		' Extract value
		Local pos:Int = s.ToIntEx(_current, start, finish, CHARSFORMAT_ALLOWLEADINGPLUS | CHARSFORMAT_SKIPWHITESPACE)
		If Not pos
			_current = 0
		EndIf
		
		result[resultIndex] = _current
		resultIndex :+ 1

		' Handle the end
		If finish = s.Length
			Exit
		EndIf
	Wend
	
	If skipEmpty and result.length > 0
		If result.Length <> resultIndex
			result = result[.. resultIndex]
		EndIf
	EndIf

	Return result
End Function


Type TIntSpliterator Implements IIterator<Int>

	Field _src:String
	Field _separator:Int
	Field _length:Int
	Field _index:Int
	Field _current:Int
	Field _skipEmpty:Int

	Method New( src:String, separator:Int, skipEmpty:Int = False )
		_src = src
		_separator = separator
		_skipEmpty = skipEmpty
		_length = _src.Length
		_index = 0
	End Method

	Method Current:Int()
		Return _current
	End Method


	Method MoveNext:Int()

		' If we're exactly at end, we may optionally yield one final empty token
		If _index = _length Then
			If _skipEmpty Then
				Return False
			End If
			Local pos:Int = _src.ToIntEx(_current, _length, _length, CHARSFORMAT_ALLOWLEADINGPLUS | CHARSFORMAT_SKIPWHITESPACE)
			If Not pos Then
				_current = 0
			End If
			_index = _length + 1 ' terminate next time
			Return True
		End If

		While _index < _length
			Local start:Int = _index

			' Scan to separator or end
			While _index < _length And _src[_index] <> _separator
				_index :+ 1
			Wend

			Local finish:Int = _index

			' Consume separator if present
			If _index < _length And _src[_index] = _separator Then
				_index :+ 1
			End If

			' Maybe skip empty tokens
			If _skipEmpty And finish = start Then
				Continue
			End If

			Local pos:Int = _src.ToIntEx(_current, start, finish, CHARSFORMAT_ALLOWLEADINGPLUS | CHARSFORMAT_SKIPWHITESPACE)
			If Not pos Then
				_current = 0
			End If

			' Handle the end
			If finish = _length Then
				_index = _length + 1
			End If

			Return True
		Wend

		Return False
	End Method
End Type
