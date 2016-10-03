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

Import "glue.c"
?Not bmxng
Import "uni_conv.c"
?

Extern
	Function bmx_stringbuffer_new:Byte Ptr(initial:Int)
	Function bmx_stringbuffer_free(buffer:Byte Ptr)

	Function bmx_stringbuffer_count:Int(buffer:Byte Ptr)
	Function bmx_stringbuffer_capacity:Int(buffer:Byte Ptr)
	Function bmx_stringbuffer_setlength(buffer:Byte Ptr, length:Int)
	Function bmx_stringbuffer_tostring:String(buffer:Byte Ptr)
	Function bmx_stringbuffer_append_string(buffer:Byte Ptr, value:String)
	Function bmx_stringbuffer_remove(buffer:Byte Ptr, startIndex:Int, endIndex:Int)
	Function bmx_stringbuffer_insert(buffer:Byte Ptr, offset:Int, value:String)
	Function bmx_stringbuffer_reverse(buffer:Byte Ptr)
	Function bmx_stringbuffer_substring:String(buffer:Byte Ptr, beginIndex:Int, endIndex:Int)
	Function bmx_stringbuffer_append_stringbuffer(buffer:Byte Ptr, buffer2:Byte Ptr)
	Function bmx_stringbuffer_startswith:Int(buffer:Byte Ptr, subString:String)
	Function bmx_stringbuffer_endswith:Int(buffer:Byte Ptr, subString:String)
	Function bmx_stringbuffer_find:Int(buffer:Byte Ptr, subString:String, startIndex:Int)
	Function bmx_stringbuffer_findlast:Int(buffer:Byte Ptr, subString:String, startIndex:Int)
	Function bmx_stringbuffer_tolower(buffer:Byte Ptr)
	Function bmx_stringbuffer_toupper(buffer:Byte Ptr)
	Function bmx_stringbuffer_trim(buffer:Byte Ptr)
	Function bmx_stringbuffer_replace(buffer:Byte Ptr, subString:String, withString:String)
	Function bmx_stringbuffer_join(buffer:Byte Ptr, bits:String[], newBuffer:Byte Ptr)
	Function bmx_stringbuffer_split:Byte Ptr(buffer:Byte Ptr, separator:String)
	Function bmx_stringbuffer_setcharat(buffer:Byte Ptr, index:Int, char:Int)
	Function bmx_stringbuffer_charat:Int(buffer:Byte Ptr, index:Int)
	Function bmx_stringbuffer_removecharat(buffer:Byte Ptr, index:Int)
	Function bmx_stringbuffer_append_cstring(buffer:Byte Ptr, chars:Byte Ptr)
	Function bmx_stringbuffer_append_utf8string(buffer:Byte Ptr, chars:Byte Ptr)

	Function bmx_stringbuffer_splitbuffer_length:Int(splitPtr:Byte Ptr)
	Function bmx_stringbuffer_splitbuffer_text:String(splitPtr:Byte Ptr, index:Int)
	Function bmx_stringbuffer_splitbuffer_free(splitPtr:Byte Ptr)
	Function bmx_stringbuffer_splitbuffer_toarray:String[](splitPtr:Byte Ptr)

End Extern

