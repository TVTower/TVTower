' Copyright (c) 2016-now Bruce A Henderson
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

Import "string_comp.c"

Type TLowerString

	Field orig:String
	Field data:Byte Ptr {nosave}

	Function Create:TLowerString(s:String)
		Local this:TLowerString = New TLowerString
		this.orig = s
		this.data = bmx_stringcomp_init(s)
		Return this
	End Function
	
	Method EqualsLower:Int(txt:String)
		Return bmx_stringcomp_equals_lower(data, txt)
	End Method
	
	Rem
	bbdoc: Returns true if any split field occurs in the passed in split text
	End Rem 
	Method HasSplitFieldInSplitText:Int(srcSplit:String, txt:String, txtSplit:String)
		Return bmx_stringcomp_equals_split_in_split(data, srcSplit, txt, txtSplit)
	End Method

	Method Compare:Int(obj:Object)
		If obj <> Self Then
			Local ls:TLowerString = TLowerString(obj)
			If ls Then
				Return bmx_stringcomp_compare_lowerstring(data, ls.data)
			End If
			If String(obj) Then
				Return bmx_stringcomp_compare_string(data, obj)
			End If
		End If
		Return 0
	End Method
	
	Method Find:Int(txt:String, pos:Int = 0)
		Return bmx_stringcomp_find(data, txt, pos)
	End Method
	
	Method ToString:String()
		Return orig
	End Method

	Method Delete()
		if data then
			bmx_stringcomp_free(data)
			data = null
		end if
	End Method

	Method StartsWithLower:Int(txt:String)
		Return bmx_stringcomp_startswith(data, txt)
	End Method

	'=== serialization stuff ===
	Method SerializeTLowerStringToString:string()
		return orig
	End Method

	Method DeSerializeTLowerStringFromString(text:String)
		'get rid of old objects to avoid mem leaks
		if data then bmx_stringcomp_free(data)

		orig = text
		data = bmx_stringcomp_init(text)
	End Method
End Type

Extern
	Function bmx_stringcomp_init:Byte Ptr(s:String)
	Function bmx_stringcomp_equals_lower:Int(handle:Byte Ptr, txt:String)
	Function bmx_stringcomp_free(handle:Byte Ptr)
	
	Function bmx_stringcomp_equals_split_in_split:Int(handle:Byte Ptr, srcSplit:String, txt:String, txtSplit:String)
	
	Function bmx_stringcomp_compare_string:Int(handle:Byte Ptr, obj:Object)
	Function bmx_stringcomp_compare_lowerstring:Int(handle:Byte Ptr, data:Byte Ptr)
	Function bmx_stringcomp_find:Int(handle:Byte Ptr, txt:String, pos:Int)
	
	function bmx_stringcomp_startswith:int(handle:byte ptr, txt:String)
End Extern
