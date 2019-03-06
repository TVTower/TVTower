' Copyright (c) 2016 Bruce A Henderson
' 
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
' 
' The above copyright notice and this permission notice shall be included in
' all copies or substantial portions of the Software.
' 
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
' THE SOFTWARE.
' 
SuperStrict

Rem
bbdoc: A string buffer.
End Rem	
rem
Module BaH.StringBuffer

ModuleInfo "Version: 1.03"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: 2016 Bruce A Henderson"

ModuleInfo "History: 1.03"
ModuleInfo "History: Added overloaded constructor for providing instance specific initial capacity."
ModuleInfo "History: 1.02"
ModuleInfo "History: Added AppendCString() and AppendUTF8String() methods."
ModuleInfo "History: 1.01"
ModuleInfo "History: Added CharAt(), SetCharAt() and RemoveCharAt() methods."
ModuleInfo "History: 1.00 Initial Release"
endrem

Import "common.bmx"

Rem
bbdoc: A modifiable String.
about: A string buffer provides functionality to efficiently insert, replace, remove, append and reverse.
It is an order of magnitude faster to append Strings to a TStringBuffer than it is to append Strings to Strings.
End Rem	
Type TStringBuffer

	' the char buffer
	Field buffer:Byte Ptr
	
	Global initialCapacity:Int = 16
	
	Method New()
		buffer = bmx_stringbuffer_new(initialCapacity)
	End Method
?bmxng
	Method New(initialCapacity:Int)
		buffer = bmx_stringbuffer_new(initialCapacity)
	End Method
?
	Rem
	bbdoc: Constructs a string buffer initialized to the contents of the specified string.
	End Rem	
	Function Create:TStringBuffer(Text:String)
?Not bmxng
		Local this:TStringBuffer = New TStringBuffer
?bmxng
		Local this:TStringBuffer
		If text.length > initialCapacity Then
			this = New TStringBuffer(text.length)
		Else
			this = New TStringBuffer
		End If
?
		Return this.Append(Text)
	End Function

	Rem
	bbdoc: Returns the length of the string the string buffer would create.
	End Rem	
	Method Length:Int()
		Return bmx_stringbuffer_count(buffer)
	End Method
	
	Rem
	bbdoc: Returns the total number of characters that the string buffer can accommodate before needing to grow.
	End Rem	
	Method Capacity:Int()
		Return bmx_stringbuffer_capacity(buffer)
	End Method
	
	Rem
	bbdoc: Sets the length of the string buffer.
	about: If the length is less than the current length, the current text will be truncated. Otherwise,
	the capacity will be increased as necessary, although the actual length of text will remain the same.
	End Rem	
	Method SetLength(length:Int)
		bmx_stringbuffer_setlength(buffer, length)
	End Method
	
	Rem
	bbdoc: Appends the text onto the string buffer.
	End Rem	
	Method Append:TStringBuffer(value:String)
		bmx_stringbuffer_append_string(buffer, value)
		Return Self
	End Method

	Rem
	bbdoc: Appends an object onto the string buffer.
	about: This generally calls the object's ToString() method.
	TStringBuffer objects are simply mem-copied.
	End Rem
	Method AppendObject:TStringBuffer(obj:Object)
		If TStringBuffer(obj) Then
			bmx_stringbuffer_append_stringbuffer(buffer, TStringBuffer(obj).buffer)
		Else
			bmx_stringbuffer_append_string(buffer, obj.ToString())
		End If
		Return Self
	End Method
	
	Rem
	bbdoc: Appends a null-terminated C string onto the string buffer.
	End Rem
	Method AppendCString:TStringBuffer(chars:Byte Ptr)
		bmx_stringbuffer_append_cstring(buffer, chars)
		Return Self
	End Method
	
	Rem
	bbdoc: Appends a null-terminated UTF-8 string onto the string buffer.
	End Rem
	Method AppendUTF8String:TStringBuffer(chars:Byte Ptr)
		bmx_stringbuffer_append_utf8string(buffer, chars)
		Return Self
	End Method
	
	Rem
	bbdoc: Finds first occurance of a sub string.
	returns: -1 if @subString not found.
	End Rem
	Method Find:Int(subString:String, startIndex:Int = 0)
		Return bmx_stringbuffer_find(buffer, subString, startIndex)
	End Method
	
	Rem
	bbdoc: Finds last occurance of a sub string.
	returns: -1 if @subString not found.
	End Rem
	Method FindLast:Int(subString:String, startIndex:Int = 0)
		Return bmx_stringbuffer_findlast(buffer, subString, startIndex)
	End Method
	
	Rem
	bbdoc: Removes leading and trailing non-printable characters from the string buffer.
	End Rem
	Method Trim:TStringBuffer()
		bmx_stringbuffer_trim(buffer)
		Return Self
	End Method
	
	Rem
	bbdoc: Replaces all occurances of @subString with @withString.
	End Rem
	Method Replace:TStringBuffer(subString:String, withString:String)
		bmx_stringbuffer_replace(buffer, subString, withString)
		Return Self
	End Method
	
	Rem
	bbdoc: Returns true if string starts with @subString.
	End Rem
	Method StartsWith:Int(subString:String)
		Return bmx_stringbuffer_startswith(buffer, subString)
	End Method
	
	Rem
	bbdoc: Returns true if string ends with @subString.
	End Rem
	Method EndsWith:Int(subString:String)
		Return bmx_stringbuffer_endswith(buffer, subString)
	End Method
	
	Rem
	bbdoc: Returns the char value in the buffer at the specified index.
	about: The first char value is at index 0, the next at index 1, and so on, as in array indexing.
	@index must be greater than or equal to 0, and less than the length of the buffer.
	End Rem
	Method CharAt:Int(index:Int)
		Return bmx_stringbuffer_charat(buffer, index)
	End Method
	
	Rem
	bbdoc: Returns true if string contains @subString.
	End Rem
	Method Contains:Int(subString:String)
		Return Find(subString) >= 0
	End Method
	
	Rem
	bbdoc: Joins @bits together by inserting this string buffer between each bit.
	returns: A new TStringBuffer object.
	End Rem
	Method Join:TStringBuffer(bits:String[])
		Local buf:TStringBuffer = New TStringBuffer
		bmx_stringbuffer_join(buffer, bits, buf.buffer)
		Return buf
	End Method

	Rem
	bbdoc: Converts all of the characters in the buffer to lower case.
	End Rem	
	Method ToLower:TStringBuffer()
		bmx_stringbuffer_tolower(buffer)
		Return Self
	End Method
	
	Rem
	bbdoc: Converts all of the characters in the buffer to upper case.
	End Rem	
	Method ToUpper:TStringBuffer()
		bmx_stringbuffer_toupper(buffer)
		Return Self
	End Method

	Rem
	bbdoc: Removes a range of characters from the string buffer.
	about: @startIndex is the first character to remove. @endIndex is the index after the last character to remove.
	End Rem
	Method Remove:TStringBuffer(startIndex:Int, endIndex:Int)
		bmx_stringbuffer_remove(buffer, startIndex, endIndex)
		Return Self
	End Method

	Rem
	bbdoc: Removes the character at the specified position in the buffer.
	about: The buffer is shortened by one character.
	End Rem
	Method RemoveCharAt:TStringBuffer(index:Int)
		bmx_stringbuffer_removecharat(buffer, index)
		Return Self
	End Method
	
	Rem
	bbdoc: Inserts text into the string buffer at the specified offset.
	End Rem
	Method Insert:TStringBuffer(offset:Int, value:String)
		bmx_stringbuffer_insert(buffer, offset, value)
		Return Self
	End Method
	
	Rem
	bbdoc: Reverses the characters of the string buffer.
	End Rem
	Method Reverse:TStringBuffer()
		bmx_stringbuffer_reverse(buffer)
		Return Self
	End Method
	
	Rem
	bbdoc: The character at the specified index is set to @char.
	about: @index must be greater than or equal to 0, and less than the length of the buffer.
	End Rem
	Method SetCharAt(index:Int, char:Int)
		bmx_stringbuffer_setcharat(buffer, index, char)
	End Method
	
	Rem
	bbdoc: Returns a substring of the string buffer given the specified indexes.
	about: @beginIndex is the first character of the substring.
	@endIndex is the index after the last character of the substring. If @endIndex is zero,
	will return everything from @beginIndex until the end of the string buffer.
	End Rem
	Method Substring:String(beginIndex:Int, endIndex:Int = 0)
		Return bmx_stringbuffer_substring(buffer, beginIndex, endIndex)
	End Method
	
	Rem
	bbdoc: 
	End Rem
	Method Split:TSplitBuffer(separator:String)
		Local buf:TSplitBuffer = New TSplitBuffer
		buf.buffer = Self
		buf.splitPtr = bmx_stringbuffer_split(buffer, separator)
		Return buf
	End Method
	
	Rem
	bbdoc: Converts the string buffer to a String.
	End Rem	
	Method ToString:String()
		Return bmx_stringbuffer_tostring(buffer)
	End Method

	Method Delete()
		If buffer Then
			bmx_stringbuffer_free(buffer)
			buffer = Null
		End If
	End Method

End Type

Rem
bbdoc: An array of split text from a TStringBuffer.
about: Note that the TSplitBuffer is only valid while its parent TStringBuffer is unchanged.
Once you modify the TStringBuffer you should call Split() again.
End Rem
Type TSplitBuffer
	Field buffer:TStringBuffer
	Field splitPtr:Byte Ptr
	
	Rem
	bbdoc: The number of split elements.
	End Rem
	Method Length:Int()
		Return bmx_stringbuffer_splitbuffer_length(splitPtr)
	End Method
	
	Rem
	bbdoc: Returns the text for the given index in the split buffer.
	End Rem
	Method Text:String(index:Int)
		Return bmx_stringbuffer_splitbuffer_text(splitPtr, index)
	End Method
	
	Rem
	bbdoc: Creates a new string array of all the split elements.
	End Rem
	Method ToArray:String[]()
		Return bmx_stringbuffer_splitbuffer_toarray(splitPtr)
	End Method

	Method ObjectEnumerator:TSplitBufferEnum()
		Local enumerator:TSplitBufferEnum = New TSplitBufferEnum
		enumerator.buffer = Self
		enumerator.length = Length()
		Return enumerator
	End Method

	Method Delete()
		If splitPtr Then
			buffer = Null
			bmx_stringbuffer_splitbuffer_free(splitPtr)
			splitPtr = Null
		End If
	End Method
	
End Type

Type TSplitBufferEnum

	Field index:Int
	Field length:Int
	Field buffer:TSplitBuffer

	Method HasNext:Int()
		Return index < length
	End Method

	Method NextObject:Object()
		Local s:String = buffer.Text(index)
		index :+ 1
		Return s
	End Method

End Type
