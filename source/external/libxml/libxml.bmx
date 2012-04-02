' Copyright (c) 2006-2010 Bruce A Henderson
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
bbdoc: Libxml
Module BaH.LibXml

ModuleInfo "Version: 1.15"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: (libxml2) 1998-2009 Daniel Veillard"
ModuleInfo "Copyright: (wrapper) 2006-2010 Bruce A Henderson"
ModuleInfo "Modserver: BRL"

ModuleInfo "History: 1.15"
ModuleInfo "History: Updated to Libxml 2.7.6."
ModuleInfo "History: Added missing xmlParserOptions."
ModuleInfo "History: Added TxmlDoc readFile() and readDoc() functions."
ModuleInfo "History: 1.14"
ModuleInfo "History: Updated to Libxml 2.7.4."
ModuleInfo "History: Fixed TxmlTextReader cleaning up string before it had finished using it."
ModuleInfo "History: Added xmlParserMaxDepth global variable."
ModuleInfo "History: Added utf-8 BOM detection/strip for doc string parsing."
ModuleInfo "History: Fixed Win32 saving issue when compression was set."
ModuleInfo "History: Added TStream support to saveFile() and saveFormatFile()."
ModuleInfo "History: Removed some source files which were not part of the library."
ModuleInfo "History: 1.13"
ModuleInfo "History: Fixed getLineNumber() returning wrong type."
ModuleInfo "History: Added TxmlDoc ToString() and ToStringFormat() methods."
ModuleInfo "History: setContent() now accepts empty string."
ModuleInfo "History: Added TxmlDoc SetEncoding() and SetStandalone() methods."
ModuleInfo "History: 1.12"
ModuleInfo "History: Improved error handling/capture."
ModuleInfo "History: Fixed xmlGetLastError calling wrong api."
ModuleInfo "History: Added new xmlSetErrorFunction() function to allow capture of all errors."
ModuleInfo "History: More error information available via new TxmlError methods()."
ModuleInfo "History: 1.11"
ModuleInfo "History: Added unlinkNode and freeNode methods to TxmlNode."
ModuleInfo "History: 1.10"
ModuleInfo "History: Updated to Libxml 2.6.27."
ModuleInfo "History: Fixed Null byte ptr handling on UTF8 conversion."
ModuleInfo "History: Fixed several memory issues."
ModuleInfo "History: 1.09"
ModuleInfo "History: Added automatic libxml UTF-to-Max and Max-To-UTF String conversion. Fixes non-ascii string issues."
ModuleInfo "History: Added getLineNumber method to TxmlBase."
ModuleInfo "History: 1.08"
ModuleInfo "History: Exposed some XPathContext properties."
ModuleInfo "History: Fixed TxmlBuffer getContent not returning anything."
ModuleInfo "History: API change - Renamed TxmlURI URIEscapeStr() to URIEscapeString()."
ModuleInfo "History: Docs tidy up."
ModuleInfo "History: Many more examples."
ModuleInfo "History: 1.07"
ModuleInfo "History: Added TxmlNode getAttributeList method."
ModuleInfo "History: Added TxmlAttribute getAttributeType, getNameSpace methods."
ModuleInfo "History: Fixed attribute getValue returning nothing."
ModuleInfo "History: Added TxmlDoc getVersion, getEncoding, isStandalone methods."
ModuleInfo "History: Added TxmlBase getParent method."
ModuleInfo "History: getFirstChild and getLastChild now accept types."
ModuleInfo "History: Added more document examples."
ModuleInfo "History: 1.06"
ModuleInfo "History: Split out extern/const to libxml_base."
ModuleInfo "History: Added more globals."
ModuleInfo "History: Added validation API."
ModuleInfo "History: Added TxmlDtdAttribute, TxmlDtdElement, TxmlNotation, TxmlValidCtxt, TxmlElementContent, TxmlXPathCompExpr."
ModuleInfo "History: 1.05"
ModuleInfo "History: Fixed TxmlNodeSet.getNodeList."
ModuleInfo "History: API change - Added TxmlBase (for shared methods). Extended Node, Doc, Dtd, Attribute, Entity from it. Should be backwards compatible."
ModuleInfo "History: Implemented debug-time assertion checking."
ModuleInfo "History: Incbin support added for TxmlDoc and TxmlTextReader."
ModuleInfo "History: Added more XPath functionality."
ModuleInfo "History: Added libxml globals."
ModuleInfo "History: Added Entities API, XInclude API, XPointer API."
ModuleInfo "History: Added XML catalogs and SGML catalogs API."
ModuleInfo "History: Added TxmlURI, TxmlCatalog, TxmlEntity, TxmlIncludeCtxt, TxmlLocationSet."
ModuleInfo "History: 1.04"
ModuleInfo "History: Removed small memory leak."
ModuleInfo "History: Fixed typo - addProcessingInstruction(), and added some missing docs."
ModuleInfo "History: Added newNode() function for TxmlNode."
ModuleInfo "History: 1.03"
ModuleInfo "History: Added TxmlTextReader API."
ModuleInfo "History: Removed ansidecl.h use for linux - not always present."
ModuleInfo "History: 1.02"
ModuleInfo "History: Removed xmlmodule.c"
ModuleInfo "History: Changed references of xmllasterror to xmllasterror1 for Mac compile."
ModuleInfo "History: Disabled thread support and made static build - removed lots of warnings."
ModuleInfo "History: 1.01"
ModuleInfo "History: Added Linux and Mac support. Still some Mac issues to resolve."
ModuleInfo "History: 1.00 Initial Release (Libxml 2.6.23)"
End Rem

Import "libxml_base.bmx"

'
' Build Notes :
'
' config.h : customized for multi-platform builds.
'
' xmlversion.h : disable LIBXML_ICONV_ENABLED, LIBXML_THREAD_ENABLED and LIBXML_MODULES_ENABLED.
'

Extern
	Rem
	bbdoc: Global setting, asking the parser to print out debugging informations while handling entities.
	about: Disabled by default.
	End Rem
	Global xmlParserDebugEntities:Int

	Rem
	bbdoc: Global setting, indicate that the parser should work in validating mode.
	about: Disabled by default.
	End Rem
	Global xmlDoValidityCheckingDefaultValue:Int

	Rem
	bbdoc: Global setting, indicate that the parser should provide warnings.
	about: Activated by default.
	End Rem
	Global xmlGetWarningsDefaultValue:Int

	Rem
	bbdoc: Global setting, indicate that the parser should load DTD while not validating.
	about: Disabled by default.
	End Rem
	Global xmlLoadExtDtdDefaultValue:Int

	Rem
	bbdoc: Global setting, indicate that the parser should store the line number in the content field of elements in the DOM tree.
	about: Disabled by default since this may not be safe for old classes of applicaton.
	End Rem
	Global xmlLineNumbersDefaultValue:Int

	Rem
	bbdoc: Global setting, asking the serializer to indent the output tree by default
	about: Enabled by default.
	End Rem
	Global xmlIndentTreeOutput:Int

	Rem
	bbdoc: Global setting, asking the serializer to not output empty tags as <empty/> but <empty></empty>.
	about: Those two forms are undistinguishable once parsed.<br>
	Disabled by default.
	End Rem
	Global xmlSaveNoEmptyTags:Int

	Rem
	bbdoc: Arbitrary depth limit for the XML documents that we allow to process.
	about: This is not a limitation of the parser but a safety boundary feature.
	End Rem
	Global xmlParserMaxDepth:Int

End Extern


Rem
bbdoc: Cleanup function for the XML library.
about: It tries to reclaim all parsing related global memory allocated for the library processing.
It doesn't deallocate any document related memory. Calling this function should not prevent reusing the
library but one should call #xmlCleanupParser only when the process has finished using the library or XML
document built with it.
End Rem
Function xmlCleanupParser()
	_xmlCleanupParser()
End Function

Rem
bbdoc: Get the last global error registered.
returns: Null if no error occured ora TxmlError object
End Rem
Function xmlGetLastError:TxmlError()
	Return TxmlError._create(_xmlGetLastError())
End Function

Rem
bbdoc: Sets the callback handler for errors.
about: The function will be called passing the optional user data and the error details.
End Rem
Function xmlSetErrorFunction(callback(data:Object, error:TxmlError), data:Object = Null)
	initGenericErrorDefaultFunc(Null)

	_xmlErrorFunction = callback
	xmlSetStructuredErrorFunc(data, _xmlErrorCallback)
End Function

Global _xmlErrorFunction(data:Object, error:TxmlError)

' internal - call xmlSetErrorFunction!!
Function _xmlErrorCallback(data:Object, error:Byte Ptr)
	_xmlErrorFunction(data, TxmlError._create(error))
End Function

Rem
bbdoc: Set and return the previous value for default entity support.
returns: The last value for 0 for no substitution, 1 for substitution.
about: Initially the parser always keep entity references instead of substituting entity values in the
output. This function has to be used to change the default parser behavior.
<p>Parameters:
<ul>
<li><b>value</b> : the value to set</li>
</ul>
</p>
End Rem
Function xmlSubstituteEntitiesDefault:Int(value:Int)
	_xmlSubstituteEntitiesDefault(value)
End Function

Rem
bbdoc: Check whether this name is an predefined entity.
returns: Null if not, otherwise the entity.
about: Parameters:
<ul>
<li><b>name</b> : the entity name</li>
</ul>
End Rem
Function xmlGetPredefinedEntity:TxmlEntity(name:String)
	Assert name, XML_ERROR_PARAM

	Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

	Local entity:TxmlEntity = TxmlEntity._create(_xmlGetPredefinedEntity(cStr))
	MemFree(cStr)

	Return entity
End Function

' converts a UTF character array from byte-size characters to short-size characters
' based on the TextStream UTF code...
Function _xmlConvertUTF8ToMax:String(s:Byte Ptr)
	If s Then
		Local l:Int = _strlen(s)
		Local b:Short[] = New Short[l]
		Local bc:Int = -1
		Local c:Int
		Local d:Int
		Local e:Int
		For Local i:Int = 0 Until l
			bc:+1
			c = s[i]
			If c<128
				b[bc] = c
				Continue
			End If
			i:+1
			d=s[i]
			If c<224
				b[bc] = (c-192)*64+(d-128)
				Continue
			End If
			i:+1
			e = s[i]
			If c < 240
				b[bc] = (c-224)*4096+(d-128)*64+(e-128)
				Continue
			End If
		Next

		Return String.fromshorts(b, bc + 1)
	End If

	Return ""

End Function

' converts a Max short-based String to a byte-based UTF-8 String.
' based on the TextStream UTF code...
Function _xmlConvertMaxToUTF8:String(text:String)
	If Not text Then
		Return ""
	End If

	Local l:Int = text.length
	If l = 0 Then
		Return ""
	End If

	Local count:Int = 0
	Local s:Byte[] = New Byte[l * 3] ' max possible is 3 x original size.

	For Local i:Int = 0 Until l
		Local char:Int = text[i]

		If char < 128 Then
			s[count] = char
			count:+ 1
			Continue
		Else If char<2048
			s[count] = char/64 | 192
			count:+ 1
			s[count] = char Mod 64 | 128
			count:+ 1
			Continue
		Else
			s[count] =  char/4096 | 224
			count:+ 1
			s[count] = char/64 Mod 64 | 128
			count:+ 1
			s[count] = char Mod 64 | 128
			count:+ 1
			Continue
		EndIf

	Next

	Return String.fromBytes(s, count)
End Function

'Function UTF8Toisolat1:String(utf8Text:String)
'	Local inlen:Int = utf8Text.length
'	Local out:Byte Ptr = "".toCString()
'	Local outlen:Int = 0
'	Local ret:Int = _UTF8Toisolat1(out, outlen , utf8Text.toCString(), inlen)
'
'	Return String.fromCString(out)
'End Function

Type TxmlBaseEnumerator

	Field _next:TxmlBase

	Function Create:TxmlBaseEnumerator( parent_:TxmlBase )
		Local ret_:TxmlBaseEnumerator = New TxmlBaseEnumerator
		ret_._next = TxmlBase.chooseCreateFromType( Byte Ptr( Int Ptr( parent_._basePtr + TxmlBase._children )[0] ) )

		Return ret_
	End Function

	Method HasNext:Int()
		Return _next<> Null
	End Method

	Method NextObject:Object()
		Local ret_:TxmlBase = _next

		_next = _next.nextSibling()
		Return ret_
	End Method

End Type


Rem
bbdoc: The base Type for #TxmlDoc, #TxmlNode, #TxmlAttribute, #TxmlEntity, #TxmlDtd, #TxmlDtdElement and #TxmlDtdAttribute.
End Rem
Type TxmlBase Abstract
	Const _type:Int = 4			' XML_DOCUMENT_NODE, (int)
	Const _name:Int = 8			' name/filename/URI of the document (Byte Ptr)
	Const _children:Int = 12		' the document tree (byte ptr)
	Const _last:Int = 16			' last child link (byte ptr)
	Const _parent:Int = 20		' child->parent link (byte ptr)
	Const _next:Int = 24			' Next sibling link (byte ptr)
	Const _prev:Int = 28			' previous sibling link (byte ptr)
	Const _doc:Int = 32			' autoreference To itself (byte ptr)

	Field _basePtr:Byte Ptr

	Method initBase(pointer:Byte Ptr)
		_basePtr = pointer
	End Method

	Method ObjectEnumerator:TxmlBaseEnumerator()
		Return TxmlBaseEnumerator.Create( Self )
	End Method

	Function chooseCreateFromType:TxmlBase(_ptr:Byte Ptr)
		If _ptr <> Null Then
			Select Int Ptr(_ptr + TxmlBase._type)[0]
				Case XML_DOCUMENT_NODE
					Return TxmlDoc._create(_ptr)
				Case XML_ATTRIBUTE_NODE
					Return TxmlAttribute._create(_ptr)
				Case XML_DTD_NODE
					Return TxmlDtd._create(_ptr)
				Case XML_ENTITY_DECL
					Return TxmlEntity._create(_ptr)
				Case XML_ELEMENT_DECL
					Return TxmlDtdElement._create(_ptr)
				Case XML_ATTRIBUTE_DECL
					Return TxmlDtdAttribute._create(_ptr)
				Default
					Return TxmlNode._create(_ptr)
			End Select
		End If

		Return Null
	End Function

	Rem
	bbdoc: Returns the type of this xml object
	about: The following lists possible types:<br>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ELEMENT_NODE</td></tr>
	<tr><td>XML_ATTRIBUTE_NODE</td></tr>
	<tr><td>XML_TEXT_NODE</td></tr>
	<tr><td>XML_CDATA_SECTION_NODE</td></tr>
	<tr><td>XML_ENTITY_REF_NODE</td></tr>
	<tr><td>XML_ENTITY_NODE</td></tr>
	<tr><td>XML_PI_NODE</td></tr>
	<tr><td>XML_COMMENT_NODE</td></tr>
	<tr><td>XML_DOCUMENT_NODE</td></tr>
	<tr><td>XML_DOCUMENT_TYPE_NODE</td></tr>
	<tr><td>XML_DOCUMENT_FRAG_NODE</td></tr>
	<tr><td>XML_NOTATION_NODE</td></tr>
	<tr><td>XML_HTML_DOCUMENT_NODE</td></tr>
	<tr><td>XML_DTD_NODE</td></tr>
	<tr><td>XML_ELEMENT_DECL</td></tr>
	<tr><td>XML_ATTRIBUTE_DECL</td></tr>
	<tr><td>XML_ENTITY_DECL</td></tr>
	<tr><td>XML_NAMESPACE_DECL</td></tr>
	<tr><td>XML_XINCLUDE_START</td></tr>
	<tr><td>XML_XINCLUDE_END</td></tr>
	<tr><td>XML_DOCB_DOCUMENT_NODE</td></tr>
	</table>
	End Rem
	Method getType:Int()
		Return Int Ptr(_basePtr + _type)[0]
	End Method

	Rem
	bbdoc: Returns the node name
	End Rem
	Method getName:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_basePtr + _name)[0]))
	End Method

	Rem
	bbdoc: Returns the document for this object.
	End Rem
	Method getDocument:TxmlDoc()
		Return TxmlDoc._create(Byte Ptr(Int Ptr(_basePtr + _doc)[0]))
	End Method


	Rem
	bbdoc: Get the next sibling node
	returns: The next node or Null if there are none.
	End Rem
	Method nextSibling:TxmlBase()
		If Byte Ptr(Int Ptr(_basePtr + _next)[0]) = Null Then
			Return Null
		End If
		Return chooseCreateFromType(Byte Ptr(Int Ptr(_basePtr + _next)[0]))
	End Method

	Rem
	bbdoc: Get the previous sibling node
	returns: The previous node or Null if there are none.
	End Rem
	Method previousSibling:TxmlBase()
		If Byte Ptr(Int Ptr(_basePtr + _prev)[0]) = Null Then
			Return Null
		End If
		Return chooseCreateFromType(Byte Ptr(Int Ptr(_basePtr + _prev)[0]))
	End Method

	Rem
	bbdoc: Returns a list of child nodes of a given node type.
	about:Parameters:
	<ul>
	<li><b>nodeType</b> : the type of node to return, or 0 for any.</li>
	</ul>
	See #getType for a list of node types.
	End Rem
	Method getChildren:TList(nodeType:Int = XML_ELEMENT_NODE)
		If Byte Ptr(Int Ptr(_basePtr + _children)[0]) = Null Then
			Return Null
		End If

		Local children:TList
		Local node:TxmlBase = chooseCreateFromType(Byte Ptr(Int Ptr(_basePtr + _children)[0]))

		While node <> Null

			' if we are wanting specific children...
			If nodeType <> 0 Then
				If node.getType() = nodeType Then
					If Not children Then
						children = New TList
					End If

					children.addLast(node)
				End If
			Else
				If Not children Then
					children = New TList
				End If

				' otherwise get all children...
				children.addLast(node)
			End If

			node = node.nextSibling()
		Wend

		Return children
	End Method

	Rem
	bbdoc: Get the last child.
	returns: The last child or Null if none.
	End Rem
	Method getLastChild:TxmlBase(nodeType:Int = XML_ELEMENT_NODE)
		If nodeType = 0 Then
			Return chooseCreateFromType(xmlGetLastChild(_basePtr))
		Else
			Local list:TList = getChildren(nodeType)
			If list Then
				Return TxmlBase(list.last())
			End If
		End If
		Return Null
	End Method

	Rem
	bbdoc: Get the first child.
	returns: The first child or Null if none.
	End Rem
	Method getFirstChild:TxmlBase(nodeType:Int = XML_ELEMENT_NODE)
		If nodeType = 0 Then
			Return chooseCreateFromType(Byte Ptr(Int Ptr(_basePtr + _children)[0]))
		Else
			Local list:TList = getChildren(nodeType)
			If list Then
				Return TxmlBase(list.First())
			End If
		End If
		Return Null
	End Method

	Rem
	bbdoc: Get the parent.
	returns: The parent to this object.
	End Rem
	Method GetParent:TxmlBase()
		Return chooseCreateFromType(Byte Ptr(Int Ptr(_basePtr + _parent)[0]))
	End Method

	Rem
	bbdoc: Get the line number of the element.
	returns: The line number if successful, or -1 otherwise.
	End Rem
	Method getLineNumber:Int()

		Return xmlGetLineNo(_basePtr)

	End Method

End Type

Rem
bbdoc: An XML Document
End Rem
Type TxmlDoc Extends TxmlBase

	'Const _type:Int = 4			' XML_DOCUMENT_NODE, (int)
	'Const _name:Int = 8			' name/filename/URI of the document (Byte Ptr)
	'Const _children:Int = 12		' the document tree (byte ptr)
	'Const _last:Int = 16			' last child link (byte ptr)
	'Const _parent:Int = 20		' child->parent link (byte ptr)
	'Const _next:Int = 24			' Next sibling link (byte ptr)
	'Const _prev:Int = 28			' previous sibling link (byte ptr)
	'Const _doc:Int = 32			' autoreference To itself (byte ptr)
	Const _compression:Int = 36	' level of zlib compression (int)
	Const _standalone:Int = 40		' standalone document (no external refs) (int)
	Const _intSubset:Int = 44		' the document internal subset (Byte Ptr)
	Const _extSubset:Int = 48		' Global namespace, the old way (Byte Ptr)
	Const _oldNs:Int = 52			' the document external subset (Byte Ptr)
	Const _version:Int = 56		' the XML Version String (Byte Ptr)
	Const _encoding:Int = 60		' external initial encoding, If any (Byte Ptr)
	Const _ids:Int = 64			' Hash table For ID attributes If any (Byte Ptr)
	Const _refs:Int = 68			' Hash table For IDREFs attributes If any (Byte Ptr)
	Const _URL:Int = 72			' The URI For that document (Byte Ptr)
	Const _charset:Int = 76		' encoding of the in-memory content actua (Byte Ptr)
	Const _dict:Int = 80			' dict used To allocate names Or Null (Byte Ptr)


	' reference to the actual document
	Field _xmlDocPtr:Byte Ptr

	Field _readStream:TStream

	Rem
	bbdoc: Creates a new XML document.
	about: Parameters:
	<ul>
	<li><b>version</b> : string giving the version of XML "1.0".</li>
	</ul>
	End Rem
	Function newDoc:TxmlDoc(Version:String)
		Assert Version, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(version).toCString()
		Local doc:TxmlDoc = TxmlDoc._create(xmlNewDoc(cStr))
		MemFree cStr

		doc.setCompressMode(0)

		Return doc
	End Function

	Rem
	bbdoc: Parse an XML file and build a tree.
	returns: The resulting document tree or Null if error.
	about: Automatic support for ZLIB/Compress compressed document is provided by default.
	<p>Parameters:
	<ul>
	<li><b>filename</b> : the name of the file to be parsed. Supports "incbin::".</li>
	</ul>
	</p>
	End Rem
	Function parseFile:TxmlDoc(filename:String)
		Assert filename, XML_ERROR_PARAM

		Local i:Int = filename.Find( "::",0 )
		' a "normal" url?
		If i = -1 Then
			Local cStr:Byte Ptr = filename.toCString()
			Local doc:TxmlDoc = TxmlDoc._create(xmlParseFile(cStr))
			MemFree cStr
			Return doc
		Else
			Local proto:String = filename[..i].ToLower()
			Local path:String = filename[i+2..]

			If proto = "incbin" Then
				Local buf:Byte Ptr = IncbinPtr( path )
				If Not buf Then
					Return Null
				End If
				Local size:Int = IncbinLen( path )

				Return TxmlDoc._create(xmlParseMemory(buf, size))
			End If
		End If

		Return Null
	End Function

	Rem
	bbdoc: Parse an XML string and build a tree.
	returns: The resulting document tree or Null if error.
	about: Parameters:
	<ul>
	<li><b>text</b> : the string to be parsed.</li>
	</ul>
	End Rem
	Function parseDoc:TxmlDoc(text:String)
		Assert text, XML_ERROR_PARAM

		' strip utf8 BOM
		If text[..3] = BOM_UTF8 Then
			text = text[3..]
		End If

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(text).toCString()
		Local _xmlDocPtr:Byte Ptr = xmlParseDoc(cStr)
		MemFree cStr

		If _xmlDocPtr = Null Then
			Return Null
		Else
			Return TxmlDoc._create(_xmlDocPtr)
		End If

	End Function

	Rem
	bbdoc: Parse an XML file from the filesystem or the network.
	returns: The resulting document tree.
	about: The parsing flags @options are a combination of the following:
	<table>
	<tr><th>Constant</th><th>Meaning</th></tr>
	<tr><td>XML_PARSE_RECOVER</td><td>recover on errors</td></tr>
	<tr><td>XML_PARSE_NOENT</td><td>substitute entities</td></tr>
	<tr><td>XML_PARSE_DTDLOAD</td><td>load the external subset</td></tr>
	<tr><td>XML_PARSE_DTDATTR</td><td>default DTD attributes</td></tr>
	<tr><td>XML_PARSE_DTDVALID</td><td>validate with the DTD</td></tr>
	<tr><td>XML_PARSE_NOERROR</td><td>suppress error reports</td></tr>
	<tr><td>XML_PARSE_NOWARNING</td><td>suppress warning reports</td></tr>
	<tr><td>XML_PARSE_PEDANTIC</td><td>pedantic error reporting</td></tr>
	<tr><td>XML_PARSE_NOBLANKS</td><td>remove blank nodes</td></tr>
	<tr><td>XML_PARSE_SAX1</td><td>use the SAX1 interface internally</td></tr>
	<tr><td>XML_PARSE_XINCLUDE</td><td>Implement XInclude substitition</td></tr>
	<tr><td>XML_PARSE_NONET</td><td>Forbid network access</td></tr>
	<tr><td>XML_PARSE_NODICT</td><td>Do not reuse the context dictionnary</td></tr>
	<tr><td>XML_PARSE_NSCLEAN</td><td>remove redundant namespaces declarations</td></tr>
	<tr><td>XML_PARSE_NOCDATA</td><td>merge CDATA as text nodes</td></tr>
	<tr><td>XML_PARSE_NOXINCNODE</td><td>do not generate XINCLUDE START/END nodes</td></tr>
	<tr><td>XML_PARSE_COMPACT</td><td>compact small text nodes. no modification of the tree allowed
	afterwards (will possibly crash if you try to modify the tree)</td></tr>
	<tr><td>XML_PARSE_OLD10</td><td>parse using XML-1.0 before update 5</td></tr>
	<tr><td>XML_PARSE_NOBASEFIX</td><td>do not fixup XINCLUDE xml:base uris</td></tr>
	<tr><td>XML_PARSE_HUGE</td><td>relax any hardcoded limit from the parser</td></tr>
	<tr><td>XML_PARSE_OLDSAX</td><td>parse using SAX2 interface from before 2.7.0</td></tr>
	</table>
	Parameters:
	<ul>
	<li><b> filename </b> : a file or URL.</li>
	<li><b> encoding </b> : the document encoding, or NULL.</li>
	<li><b> options </b> : a combination of parser options.</li>
	</ul>
	End Rem
	Function ReadFile:TxmlDoc(filename:String, encoding:String = "", options:Int = 0)
		Assert filename, XML_ERROR_PARAM

		Local i:Int = filename.Find( "::",0 )
		' a "normal" url?
		If i = -1 Then
			Local cStr:Byte Ptr = filename.toCString()
			Local cStr1:Byte Ptr
			If encoding Then
				cStr1 = encoding.toCString()
			End If
			Local doc:TxmlDoc
			If cStr1 Then
				doc = TxmlDoc._create(xmlReadFile(cStr, cStr1, options))
				MemFree cStr1
			Else
				doc = TxmlDoc._create(xmlReadFile(cStr, Null, options))
			End If
			MemFree cStr
			Return doc
		Else
			Local proto:String = filename[..i].ToLower()
			Local path:String = filename[i+2..]

			If proto = "incbin" Then
				Local buf:Byte Ptr = IncbinPtr( path )
				If Not buf Then
					Return Null
				End If
				Local size:Int = IncbinLen( path )

				Local cStr1:Byte Ptr
				If encoding Then
					cStr1 = encoding.toCString()
				End If

				Local doc:TxmlDoc
				If cStr1 Then
					doc = TxmlDoc._create(xmlReadMemory(buf, size, Null, cStr1, options))
					MemFree cStr1
				Else
					doc = TxmlDoc._create(xmlReadMemory(buf, size, Null, Null, options))
				End If
				Return doc
			End If
		End If

		Return Null
	End Function

	Rem
	bbdoc: Parse an XML document from a String or TStream and build a tree.
	returns: The resulting document tree.
	about: The parsing flags @options are a combination of the following:
	<table>
	<tr><th>Constant</th><th>Meaning</th></tr>
	<tr><td>XML_PARSE_RECOVER</td><td>recover on errors</td></tr>
	<tr><td>XML_PARSE_NOENT</td><td>substitute entities</td></tr>
	<tr><td>XML_PARSE_DTDLOAD</td><td>load the external subset</td></tr>
	<tr><td>XML_PARSE_DTDATTR</td><td>default DTD attributes</td></tr>
	<tr><td>XML_PARSE_DTDVALID</td><td>validate with the DTD</td></tr>
	<tr><td>XML_PARSE_NOERROR</td><td>suppress error reports</td></tr>
	<tr><td>XML_PARSE_NOWARNING</td><td>suppress warning reports</td></tr>
	<tr><td>XML_PARSE_PEDANTIC</td><td>pedantic error reporting</td></tr>
	<tr><td>XML_PARSE_NOBLANKS</td><td>remove blank nodes</td></tr>
	<tr><td>XML_PARSE_SAX1</td><td>use the SAX1 interface internally</td></tr>
	<tr><td>XML_PARSE_XINCLUDE</td><td>Implement XInclude substitition</td></tr>
	<tr><td>XML_PARSE_NONET</td><td>Forbid network access</td></tr>
	<tr><td>XML_PARSE_NODICT</td><td>Do not reuse the context dictionnary</td></tr>
	<tr><td>XML_PARSE_NSCLEAN</td><td>remove redundant namespaces declarations</td></tr>
	<tr><td>XML_PARSE_NOCDATA</td><td>merge CDATA as text nodes</td></tr>
	<tr><td>XML_PARSE_NOXINCNODE</td><td>do not generate XINCLUDE START/END nodes</td></tr>
	<tr><td>XML_PARSE_COMPACT</td><td>compact small text nodes. no modification of the tree allowed
	afterwards (will possibly crash if you try to modify the tree)</td></tr>
	<tr><td>XML_PARSE_OLD10</td><td>parse using XML-1.0 before update 5</td></tr>
	<tr><td>XML_PARSE_NOBASEFIX</td><td>do not fixup XINCLUDE xml:base uris</td></tr>
	<tr><td>XML_PARSE_HUGE</td><td>relax any hardcoded limit from the parser</td></tr>
	<tr><td>XML_PARSE_OLDSAX</td><td>parse using SAX2 interface from before 2.7.0</td></tr>
	</table>
	Parameters:
	<ul>
	<li><b> doc </b> : a string for parsing, or an open TStream.</li>
	<li><b> url </b> : the base URL to use for the document.</li>
	<li><b> encoding </b> : the document encoding, or NULL.</li>
	<li><b> options </b> : a combination of parser options.</li>
	</ul>
	End Rem
	Function ReadDoc:TxmlDoc(doc:Object, url:String = "", encoding:String = "", options:Int = 0)
		Assert doc, XML_ERROR_PARAM

		If String(doc) Then
			Local text:String = String(doc)

			' strip utf8 BOM
			If text[..3] = BOM_UTF8 Then
				text = text[3..]
			End If

			Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(text).toCString()

			Local cStr1:Byte Ptr, cStr2:Byte Ptr
			If url Then
				cStr1 = url.toCString()
			End If
			If encoding Then
				cStr2 = encoding.toCString()
			End If

			Local _xmlDocPtr:Byte Ptr

			If cStr1 Then
				If cStr2 Then
					_xmlDocPtr = xmlReadDoc(cStr, cStr1, cStr2, options)
				Else
					_xmlDocPtr = xmlReadDoc(cStr, cStr1, Null, options)
				End If
			Else
				If cStr2 Then
					_xmlDocPtr = xmlReadDoc(cStr, Null, cStr2, options)
				Else
					_xmlDocPtr = xmlReadDoc(cStr, Null, Null, options)
				End If
			End If

			If cStr1 Then
				MemFree cStr1
			End If
			If cStr2 Then
				MemFree cStr2
			End If

			MemFree cStr

			If _xmlDocPtr = Null Then
				Return Null
			Else
				Return TxmlDoc._create(_xmlDocPtr)
			End If

		Else If TStream(doc) Then

			Local tempDoc:TxmlDoc = New TxmlDoc
			tempDoc._readStream = TStream(doc)


			Local cStr1:Byte Ptr, cStr2:Byte Ptr
			If url Then
				cStr1 = url.toCString()
			End If
			If encoding Then
				cStr2 = encoding.toCString()
			End If

			Local _xmlDocPtr:Byte Ptr

			If cStr1 Then
				If cStr2 Then
					_xmlDocPtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, cStr1, cStr2, options)
				Else
					_xmlDocPtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, cStr1, Null, options)
				End If
			Else
				If cStr2 Then
					_xmlDocPtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, Null, cStr2, options)
				Else
					_xmlDocPtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, Null, Null, options)
				End If
			End If

			If cStr1 Then
				MemFree cStr1
			End If
			If cStr2 Then
				MemFree cStr2
			End If

			If _xmlDocPtr = Null Then
				Return Null
			Else
				Return TxmlDoc._create(_xmlDocPtr)
			End If

		End If

	End Function

	Function _xmlInputReadCallback:Int(doc:Object, buffer:Byte Ptr, length:Int)
		Return TxmlDoc(doc)._readStream.Read(buffer, length)
	End Function

	Function _xmlInputCloseCallback:Int(doc:Object)
		Return 0
	End Function

	Rem
	bbdoc: Parse an XML file and build a tree.
	returns: The resulting document tree or Null in case of error
	about: It's like #parseFile() except it bypasses all catalog lookups. Note: Doesn't support "incbin::".
	<p>Parameters:
	<ul>
	<li><b>filename</b> : the filename</li>
	</ul>
	</p>
	End Rem
	Function parseCatalogFile:TxmlDoc(filename:String)
		Assert filename, XML_ERROR_PARAM

		Local cStr:Byte Ptr = filename.toCString()
		Local doc:TxmlDoc = TxmlDoc._create(xmlParseCatalogFile(cStr))
		MemFree cStr
		Return doc
	End Function

	' private - non API function
	Function _create:TxmlDoc(_xmlDocPtr:Byte Ptr)
		If _xmlDocPtr <> Null Then
			Local this:TxmlDoc = New TxmlDoc

			this._xmlDocPtr = _xmlDocPtr
			this.initBase(_xmlDocPtr)

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: The document URI.
	End Rem
	Method getURL:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDocPtr + _URL)[0]))
	End Method

	Rem
	bbdoc: Returns the root element of the document
	End Rem
	Method getRootElement:TxmlNode()
		Return TxmlNode._create(xmlDocGetRootElement(_xmlDocPtr))
	End Method

	Rem
	bbdoc: Set the root element of the document (doc->children is a list containing possibly comments, PIs, etc ...)
	returns: the old root element if any was found
	about: Parameters:
	<ul>
	<li><b>root</b> : the new document root element</li>
	</ul>
	End Rem
	Method setRootElement:TxmlNode(root:TxmlNode)
		Assert root, XML_ERROR_PARAM
		Return TxmlNode._create(xmlDocSetRootElement(_xmlDocPtr, root._xmlNodePtr))
	End Method

	Rem
	bbdoc: Free up all the structures used by a document, tree included.
	End Rem
	Method free()
		xmlFreeDoc(_xmlDocPtr)
	End Method

	Rem
	bbdoc: The XML version string.
	End Rem
	Method getVersion:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDocPtr + _version)[0]))
	End Method

	Rem
	bbdoc: The external initial encoding, if any.
	End Rem
	Method getEncoding:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDocPtr + _encoding)[0]))
	End Method

	Rem
	bbdoc: Sets the document encoding.
	End Rem
	Method setEncoding(encoding:String)
		Local enc:Byte Ptr = Byte Ptr(Int Ptr(_xmlDocPtr + _encoding)[0])
		If enc Then
			xmlMemFree(enc)
		End If

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(encoding).toCString()
		Int Ptr(_xmlDocPtr + _encoding)[0] = Int(xmlStrdup(cStr))
		MemFree(cStr)
	End Method

	Rem
	bbdoc: Is this document standalone?
	returns: True if the document has no external refs.
	End Rem
	Method isStandalone:Int()
		Return Int Ptr(_xmlDocPtr + _standalone)[0]
	End Method

	Rem
	bbdoc: Sets document to standalone (or not).
	End Rem
	Method setStandalone(value:Int)
		Int Ptr(_xmlDocPtr + _standalone)[0] = value
	End Method

	Rem
	bbdoc: Creation of a processing instruction element.
	returns: The new node object
	about: Note - The processing instruction is only linked against the document, not the tree structure.
	You will need to additionally add it to the structure yourself.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the processing instruction name</li>
	<li><b>content</b> : the processing instruction content</li>
	</ul>
	</p>
	End Rem
	Method addProcessingInstruction:TxmlNode(name:String, content:String)
		Assert name, XML_ERROR_PARAM
		Assert content, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()
		Local node:TxmlNode = TxmlNode._create(xmlNewDocPI(_xmlDocPtr, cStr1, cStr2))
		MemFree cStr1
		MemFree cStr2

		Return node
	End Method

	Rem
	bbdoc: Create a new property carried by the document.
	returns: The new attribute object.
	about: Note - The property is only linked against the document, not the tree structure.
	You will need to additionally add it to the structure yourself.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the name of the attribute</li>
	<li><b>value</b> : the value of the attribute</li>
	</ul>
	</p>
	End Rem
	Method addProperty:TxmlAttribute(name:String, value:String)
		Assert name, XML_ERROR_PARAM
		Assert value, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local attribute:TxmlAttribute = TxmlAttribute._create(xmlNewDocProp(_xmlDocPtr, cStr1, cStr2))
		MemFree cStr1
		MemFree cStr2
		Return attribute
	End Method

	Rem
	bbdoc: Set the default compression mode used, ZLIB based Correct values: 0 (uncompressed) to 9 (max compression)
	about: Parameters:
	<ul>
	<li><b>mode</b> : the compression ratio</li>
	</ul>
	End Rem
	Method setCompressMode(Mode:Int)
		' make sure it's in the valid range, 0-9
		Mode = Max(Min(Mode, 9), 0)
		xmlSetDocCompressMode(_xmlDocPtr, Mode)
	End Method

	Rem
	bbdoc: Get the compression ratio for a document.
	returns: 0 (uncompressed) to 9 (max compression)
	End Rem
	Method getCompressMode:Int()
		Return xmlGetDocCompressMode(_xmlDocPtr)
	End Method

	Rem
	bbdoc: Dump an XML document to a file.
	returns: the number of bytes written or -1 in case of failure.
	about: Will use compression if set. If @filename is "-" the standard out (console) is used.
	<p>Parameters:
	<ul>
	<li><b>file</b> : either the filename or URL (String), or stream (TStream).</li>
	<li><b>autoClose</b> : for streams only. When True, will automatically Close the stream. (default)</li>
	</ul>
	</p>
	End Rem
	Method saveFile:Int(file:Object, autoClose:Int = True)
		Assert file, XML_ERROR_PARAM
		Local ret:Int

		If String(file) Then
			Local filename:String = String(file)

?win32
			filename = filename.Replace("/","\") ' compression requires Windows backslashes
?

			Local cStr:Byte Ptr = filename.toCString()
			ret = xmlSaveFile(cStr, _xmlDocPtr)
			MemFree cStr

		Else If TStream(file) Then
			Local stream:TStream = TStream(file)

			TxmlOutputStreamHandler.stream = stream
			TxmlOutputStreamHandler.autoClose = autoClose

			Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createIO()
			ret = xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, _xmlDocPtr, Null, True)
		End If

		Return ret
	End Method

	Rem
	bbdoc: Dump an XML document to a file.
	returns: the number of bytes written or -1 in case of failure.
	about: Will use compression if compiled in and enabled. If @filename is "-" the standard out (console)
	is used. If @format is set to true then the document will be indented on output.
	<p>Parameters:
	<ul>
	<li><b>file</b> : either the filename or URL (String), or stream (TStream).</li>
	<li><b>format</b> : should formatting spaces been added</li>
	<li><b>autoClose</b> : for streams only. When True, will automatically Close the stream. (default)</li>
	</ul>
	</p>
	End Rem
	Method saveFormatFile:Int(file:Object, format:Int, autoClose:Int = True)
		Assert file, XML_ERROR_PARAM
		Local ret:Int

		If String(file) Then
			Local filename:String = String(file)

?win32
			filename = filename.Replace("/","\") ' compression requires Windows backslashes
?

			Local cStr:Byte Ptr = filename.toCString()
			ret = xmlSaveFormatFile(cStr, _xmlDocPtr, format)
			MemFree cStr

		Else If TStream(file) Then
			Local stream:TStream = TStream(file)

			TxmlOutputStreamHandler.stream = stream
			TxmlOutputStreamHandler.autoClose = autoClose

			Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createIO()
			ret = xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, _xmlDocPtr, Null, format)
		End If

		Return ret
	End Method

	Rem
	bbdoc: Returns a string representation of the document.
	End Rem
	Method ToString:String()
		Local buffer:TxmlBuffer = TxmlBuffer.newBuffer()
		Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createBuffer(buffer)
		xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, _xmlDocPtr, Null, True)
		Local t:String = buffer.getContent()
		buffer.free()
		Return t
	End Method

	Rem
	bbdoc: Returns a string representation of the document, optionally formatting the output.
	End Rem
	Method ToStringFormat:String(format:Int = False)
		Local buffer:TxmlBuffer = TxmlBuffer.newBuffer()
		Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createBuffer(buffer)
		xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, _xmlDocPtr, Null, format)
		Local t:String = buffer.getContent()
		buffer.free()
		Return t
	End Method

	Rem
	bbdoc: Create a new #TxmlXPathContext
	Returns: a new TxmlXPathContext.
	End Rem
	Method newXPathContext:TxmlXPathContext()
		Return TxmlXPathContext._create(xmlXPathNewContext(_xmlDocPtr))
	End Method

	Rem
	bbdoc: Do a global encoding of a string.
	returns: A new string with the substitution done.
	about: Replaces the predefined entities and non ASCII values with their entities and CharRef counterparts.
	<p>Parameters:
	<ul>
	<li><b>text</b> : A string to convert to XML.</li>
	</ul>
	</p>
	End Rem
	Method encodeEntities:String(text:String)
		Assert text, XML_ERROR_PARAM

		Return encodeEntitiesReentrant(text)
	'	Local cStr:Byte Ptr = text.toCString()
	'	Local s:Byte Ptr = xmlEncodeEntitiesReentrant(_xmlDocPtr, cStr)
	'	MemFree cStr
	'	If s <> Null Then
	'		Local t:String = String.fromCString(s)
	'		xmlMemFree(s)
	'		Return t
	'	Else
	'		Return Null
	'	End If
	End Method

	Rem
	bbdoc: Create the internal subset of a document
	returns: a new TxmlDtd object
	about: Parameters:
	<ul>
	<li><b>name</b> : the DTD name.</li>
	<li><b>externalID</b> : the external (PUBLIC) ID.</li>
	<li><b>systemID</b> : the system ID.</li>
	</ul>
	End Rem
	Method createInternalSubset:TxmlDtd(name:String, externalID:String, systemID:String)
		Assert name, XML_ERROR_PARAM
		Assert externalID, XML_ERROR_PARAM
		Assert systemID, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(externalID).toCString()
		Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(systemID).toCString()
		Local dtd:TxmlDtd = TxmlDtd._create(xmlCreateIntSubset(_xmlDocPtr, cStr1, cStr2, cStr3))
		MemFree cStr1
		MemFree cStr2
		MemFree cStr3
		Return dtd
	End Method

	Rem
	bbdoc: Get the internal subset of a document
	returns: the DTD structure or Null if not found
	End Rem
	Method getInternalSubset:TxmlDtd()
		Return TxmlDtd._create(xmlGetIntSubset(_xmlDocPtr))
	End Method

	Rem
	bbdoc: Creation of a new DTD for the external subset.
	returns: a new TxmlDtd object
	about: To create an internal subset, use #createInternalSubset
	<p>Parameters:
	<ul>
	<li><b>name</b> : the DTD name.</li>
	<li><b>externalID</b> : the external ID.</li>
	<li><b>systemID</b> : the system ID.</li>
	</ul>
	</p>
	End Rem
	Method createExternalSubset:TxmlDtd(name:String, externalID:String, systemID:String)
		Assert name, XML_ERROR_PARAM
		Assert externalID, XML_ERROR_PARAM
		Assert systemID, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(externalID).toCString()
		Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(systemID).toCString()
		Local dtd:TxmlDtd = TxmlDtd._create(xmlNewDtd(_xmlDocPtr, cStr1, cStr2, cStr3))
		MemFree cStr1
		MemFree cStr2
		MemFree cStr3
		Return dtd
	End Method


	Rem
	bbdoc: Call this routine to speed up XPath computation on static documents.
	returns: The number of elements found in the document or -1 in case of error.
	about: This stamps all the element nodes with the document order Like for line information, the order is kept
	in the element->content field, the value stored is actually - the node number (starting at -1) to be able
	to differentiate from line numbers.
	End Rem
	Method XPathOrderElements:Long()
		Return xmlXPathOrderDocElems(_xmlDocPtr)
	End Method

	Rem
	bbdoc: Do a copy of the document info.
	returns: a new TxmlDoc, or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>recursive</b> : if True, the content tree will be copied too as well as DTD, namespaces and entities.</li>
	</ul>
	End Rem
	Method copy:TxmlDoc(recursive:Int = True)
		Return TxmlDoc._create(xmlCopyDoc(_xmlDocPtr, recursive))
	End Method

	Rem
	bbdoc: Register a new entity for this document.
	returns: The entity reference or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>name</b> : the entity name</li>
	<li><b>entityType</b> : the entity type (see above for details)</li>
	<li><b>externalID</b> : the entity external ID, if available</li>
	<li><b>systemID</b> : the entity system ID if available</li>
	<li><b>content</b> : the entity content</li>
	</ul>
	End Rem
	Method addDocEntity:TxmlEntity(name:String, EntityType:Int, externalID:String, systemID:String, content:String)
		Assert name, XML_ERROR_PARAM
		Assert content, XML_ERROR_PARAM

		Local entity:TxmlEntity = Null

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()

		If externalID <> Null Then
			Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(externalID).toCString()

			If systemID <> Null Then
				Local cStr4:Byte Ptr = _xmlConvertMaxToUTF8(systemID).toCString()
				entity = TxmlEntity._create(xmlAddDocEntity(_xmlDocPtr, cStr1, EntityType, cStr3, cStr4, cStr2))
				MemFree(cStr4)
			Else
				entity = TxmlEntity._create(xmlAddDocEntity(_xmlDocPtr, cStr1, EntityType, cStr3, Null, cStr2))
			End If

			MemFree(cStr3)
		Else
			If systemID <> Null Then
				Local cStr4:Byte Ptr = _xmlConvertMaxToUTF8(systemID).toCString()
				entity = TxmlEntity._create(xmlAddDocEntity(_xmlDocPtr, cStr1, EntityType, Null, cStr4, cStr2))
				MemFree(cStr4)
			Else
				entity = TxmlEntity._create(xmlAddDocEntity(_xmlDocPtr, cStr1, EntityType, Null, Null, cStr2))
			End If
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return entity
	End Method

	Rem
	bbdoc: Register a new entity for this document DTD external subset.
	returns: The entity reference or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>name</b> : the entity name</li>
	<li><b>entityType</b> : the entity type (see above for details)</li>
	<li><b>externalID</b> : the entity external ID, if available</li>
	<li><b>systemID</b> : the entity system ID if available</li>
	<li><b>content</b> : the entity content</li>
	</ul>
	End Rem
	Method addDtdEntity:TxmlEntity(name:String, EntityType:Int, externalID:String, systemID:String, content:String)
		Assert name, XML_ERROR_PARAM
		Assert content, XML_ERROR_PARAM

		Local entity:TxmlEntity = Null

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()

		If externalID <> Null Then
			Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(externalID).toCString()

			If systemID <> Null Then
				Local cStr4:Byte Ptr = _xmlConvertMaxToUTF8(systemID).toCString()
				entity = TxmlEntity._create(xmlAddDtdEntity(_xmlDocPtr, cStr1, EntityType, cStr3, cStr4, cStr2))
				MemFree(cStr4)
			Else
				entity = TxmlEntity._create(xmlAddDtdEntity(_xmlDocPtr, cStr1, EntityType, cStr3, Null, cStr2))
			End If

			MemFree(cStr3)
		Else
			If systemID <> Null Then
				Local cStr4:Byte Ptr = _xmlConvertMaxToUTF8(systemID).toCString()
				entity = TxmlEntity._create(xmlAddDtdEntity(_xmlDocPtr, cStr1, EntityType, Null, cStr4, cStr2))
				MemFree(cStr4)
			Else
				entity = TxmlEntity._create(xmlAddDtdEntity(_xmlDocPtr, cStr1, EntityType, Null, Null, cStr2))
			End If
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return entity
	End Method

	Rem
	bbdoc: Do a global encoding of a string.
	returns: A newly allocated string with the substitution done.
	about: Replaces the predefined entities and non ASCII values with their entities and CharRef
	counterparts.
	<p>Parameters:
	<ul>
	<li><b>inp</b> : a string to convert to XML</li>
	</ul>
	</p>
	End Rem
	Method encodeEntitiesReentrant:String(inp:String)
		Assert inp, XML_ERROR_PARAM

		Local ret:String = Null
		Local s:Byte Ptr
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(inp).toCString()

		s = xmlEncodeEntitiesReentrant(_xmlDocPtr, cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Do a global encoding of a string, replacing the predefined entities.
	returns: A newly allocated string with the substitution done.
	about: Parameters:
	<ul>
	<li><b>inp</b> : a string to convert to XML</li>
	</ul>
	End Rem
	Method encodeSpecialChars:String(inp:String)
		Assert inp, XML_ERROR_PARAM

		Local ret:String = Null
		Local s:Byte Ptr
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(inp).toCString()

		s = xmlEncodeSpecialChars(_xmlDocPtr, cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Do an entity lookup in the document entity hash table and return the corresponding entity, otherwise a lookup is done in the predefined entities too.
	returns: Returns the entity structure or Null if not found.
	about: Parameters:
	<ul>
	<li><b>name</b> : the entity name</li>
	</ul>
	End Rem
	Method getDocEntity:TxmlEntity(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local entity:TxmlEntity = TxmlEntity._create(xmlGetDocEntity(_xmlDocPtr, cStr))
		MemFree(cStr)

		Return entity
	End Method

	Rem
	bbdoc: Do an entity lookup in the internal and external subsets and return the corresponding parameter entity, if found.
	returns: Returns the entity structure or Null if not found.
	about: Parameters:
	<ul>
	<li><b>name</b> : the entity name</li>
	</ul>
	End Rem
	Method getDtdEntity:TxmlEntity(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local entity:TxmlEntity = TxmlEntity._create(xmlGetDtdEntity(_xmlDocPtr, cStr))
		MemFree(cStr)

		Return entity
	End Method

	Rem
	bbdoc: Do an entity lookup in the internal and external subsets and return the corresponding parameter entity, if found.
	returns: Returns the entity structure or Null if not found.
	about: Parameters:
	<ul>
	<li><b>name</b> : the entity name</li>
	</ul>
	End Rem
	Method getParameterEntity:TxmlEntity(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local entity:TxmlEntity = TxmlEntity._create(xmlGetParameterEntity(_xmlDocPtr, cStr))
		MemFree(cStr)

		Return entity
	End Method

	Rem
	bbdoc: Implement the XInclude substitution on the XML document.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	End Rem
	Method XIncludeProcess:Int()
		Return xmlXIncludeProcess(_xmlDocPtr)
	End Method

	Rem
	bbdoc: Implement the XInclude substitution on the XML document.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	about: Parameters:
	<ul>
	<li><b>flags</b> : a set of xml Parser Options used for parsing XML includes (see #fromFile for option details)</li>
	</ul>
	End Rem
	Method XIncludeProcessFlags:Int(flags:Int)
		Return xmlXIncludeProcessFlags(_xmlDocPtr, flags)
	End Method

	Rem
	bbdoc: Search the attribute declaring the given ID.
	returns: Null if not found, otherwise the TxmlAttrribute defining the ID.
	about: Parameters:
	<ul>
	<li><b>id</b> : the ID value</li>
	</ul>
	End Rem
	Method getID:TxmlAttribute(id:String)
		Assert id, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(id).toCString()

		Local ret:TxmlAttribute = TxmlAttribute._create(xmlGetID(_xmlDocPtr, cStr))

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Determine whether an attribute is of type ID.
	returns: 0 or 1 depending on the lookup result.
	about: In case we have DTD(s) then this is done if DTD loading has been requested. In the case
	of HTML documents parsed with the HTML parser, then ID detection is done systematically.
	<p>Parameters:
	<ul>
	<li><b>node</b> : the node carrying the attribute</li>
	<li><b>attr</b> : the attribute</li>
	</ul>
	</p>
	End Rem
	Method isID:Int(node:TxmlNode, attr:TxmlAttribute)
		Assert node, XML_ERROR_PARAM
		Assert attr, XML_ERROR_PARAM

		Return xmlIsID(_xmlDocPtr, node._xmlNodePtr, attr._xmlAttrPtr)
	End Method

	Rem
	bbdoc: Determine whether an attribute is of type Ref.
	returns: 0 or 1 depending on the lookup result.
	about: In case we have DTD(s) then this is simple, otherwise we use an heuristic: name Ref
	(upper or lowercase).
	<p>Parameters:
	<ul>
	<li><b>node</b> : the node carrying the attribute</li>
	<li><b>attr</b> : the attribute</li>
	</ul>
	</p>
	End Rem
	Method isRef:Int(node:TxmlNode, attr:TxmlAttribute)
		Assert node, XML_ERROR_PARAM
		Assert attr, XML_ERROR_PARAM

		Return xmlIsRef(_xmlDocPtr, node._xmlNodePtr, attr._xmlAttrPtr)
	End Method

	Rem
	bbdoc: Search in the DTDs whether an element accept Mixed content (or ANY) basically if it is supposed to accept text childs.
	returns: 0 if no, 1 if yes, and -1 if no element description is available.
	about: Parameters:
	<ul>
	<li><b>name</b> : the element name</li>
	</ul>
	End Rem
	Method isMixedElement:Int(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local ret:Int = xmlIsMixedElement(_xmlDocPtr, cStr)

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Remove the given attribute from the ID table maintained internally.
	returns: -1 if the lookup failed and 0 otherwise.
	about: Parameters:
	<ul>
	<li><b>attr</b> : the attribute</li>
	</ul>
	End Rem
	Method removeID:Int(attr:TxmlAttribute)
		Assert attr, XML_ERROR_PARAM

		Return xmlRemoveID(_xmlDocPtr, attr._xmlAttrPtr)
	End Method

	Rem
	bbdoc: Remove the given attribute from the Ref table maintained internally.
	returns: -1 if the lookup failed and 0 otherwise.
	about: Parameters:
	<ul>
	<li><b>attr</b> : the attribute</li>
	</ul>
	End Rem
	Method removeRef:Int(attr:TxmlAttribute)
		Assert attr, XML_ERROR_PARAM

		Return xmlRemoveRef(_xmlDocPtr, attr._xmlAttrPtr)
	End Method

	Rem
	bbdoc: Allocate an element content structure for the document.
	returns: Null if not, otherwise the new element content structure.
	about: Parameters:
	<ul>
	<li><b>name</b> : the subelement name or Null</li>
	<li><b>contentType</b> : the type of element content decl (see below)</li>
	</ul>
	<p>The following lists the valid content types:</p>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ELEMENT_CONTENT_PCDATA</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_ELEMENT</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_SEQ</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_OR</td></tr>
	</table>
	End Rem
	Method newDocElementContent:TxmlElementContent(name:String, contentType:Int)
		Local ret:TxmlElementContent = Null

		If name = Null Then
			ret = TxmlElementContent._create(xmlNewDocElementContent(_xmlDocPtr, Null, contentType))
		Else
			Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
			ret = TxmlElementContent._create(xmlNewDocElementContent(_xmlDocPtr, cStr, contentType))
			MemFree(cStr)
		End If

		Return ret
	End Method

	Rem
	bbdoc: Free an element content structure.
	about: The whole subtree is removed.
	<p>Parameters:
	<ul>
	<li><b>content</b> : the element content tree to free</li>
	</ul>
	</p>
	End Rem
	Method freeDocElementContent(content:TxmlElementContent)
		Assert content, XML_ERROR_PARAM

		xmlFreeDocElementContent(_xmlDocPtr, content._xmlElementContentPtr)
	End Method

	Rem
	bbdoc: Does the validation related extra step of the normalization of attribute values.
	returns: A new normalized string if normalization is needed, Null otherwise.
	about: If the declared value is not CDATA, then the XML processor must further process
	the normalized attribute value by discarding any leading and trailing space (#x20) characters,
	and by replacing sequences of space (#x20) characters by single space (#x20) character.<br>
	Also check VC: Standalone Document Declaration in P32, and update ctxt-&gt;valid accordingly
	<p>Parameters:
	<ul>
	<li><b>elem</b> : the parent</li>
	<li><b>name</b> : the attribute name</li>
	<li><b>value</b> : the attribute value</li>
	<li><b>context</b> : the validation context or Null</li>
	</ul>
	</p>
	End Rem
	Method contextNormalizeAttributeValue:String(elem:TxmlNode, name:String, value:String, context:TxmlValidCtxt)
		Assert elem, XML_ERROR_PARAM
		Assert name, XML_ERROR_PARAM
		Assert value, XML_ERROR_PARAM

		Local ret:String = Null
		Local s:Byte Ptr

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()

		If context = Null Then
			s = xmlValidCtxtNormalizeAttributeValue(Null, _xmlDocPtr, elem._xmlNodePtr, cStr1, cStr2)
		Else
			s = xmlValidCtxtNormalizeAttributeValue(context._xmlValidCtxtPtr, _xmlDocPtr, elem._xmlNodePtr, cStr1, cStr2)
		End If

		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Method

	Rem
	bbdoc: Does the validation related extra step of the normalization of attribute values.
	returns: A new normalized string if normalization is needed, Null otherwise.
	about: If the declared value is not CDATA, then the XML processor must further process the
	normalized attribute value by discarding any leading and trailing space (#x20) characters,
	and by replacing sequences of space (#x20) characters by single space (#x20) character.
	<p>Parameters:
	<ul>
	<li><b>elem</b> : the parent</li>
	<li><b>name</b> : the attribute name</li>
	<li><b>value</b> : the attribute value</li>
	</ul>
	</p>
	End Rem
	Method normalizeAttributeValue:String(elem:TxmlNode, name:String, value:String)
		Assert elem, XML_ERROR_PARAM
		Assert name, XML_ERROR_PARAM
		Assert value, XML_ERROR_PARAM

		Local ret:String = Null
		Local s:Byte Ptr

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()

		s = xmlValidNormalizeAttributeValue(_xmlDocPtr, elem._xmlNodePtr, cStr1, cStr2)

		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Method

End Type

Rem
bbdoc: An XML Node
End Rem
Type TxmlNode Extends TxmlBase

	' offsets from the pointer
	'Const _type:Int = 4		' Type number, (int)
	'Const _name:Int = 8		' the name of the node, Or the entity (byte ptr)
	'Const _children:Int = 12	' parent->childs link (byte ptr)
	'Const _last:Int = 16		' last child link (byte ptr)
	'Const _parent:Int = 20	' child->parent link (byte ptr)
	'Const _next:Int = 24		' Next sibling link (byte ptr)
	'Const _prev:Int = 28		' previous sibling link (byte ptr)
	'Const _doc:Int = 32		' the containing document (byte ptr)
	Const _ns:Int = 36		' pointer To the associated namespace (byte ptr)
	Const _content:Int = 40	' the content (byte ptr)
	Const _properties:Int = 44	' properties list (byte ptr)
	Const _nsDef:Int = 48		' namespace definitions on this node

	' reference to the actual node
	Field _xmlNodePtr:Byte Ptr


	' internal function... not part of the API !
	Function _create:TxmlNode(_xmlNodePtr:Byte Ptr)
		If _xmlNodePtr <> Null Then
			Local this:TxmlNode = New TxmlNode

			this._xmlNodePtr = _xmlNodePtr
			this.initBase(_xmlNodePtr)

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Creation of a new node element.
	about: @namespace is optional.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the node name.</li>
	<li><b>namespace</b> : namespace, if any.</li>
	</ul>
	</p>
	End Rem
	Function newNode:TxmlNode(name:String, namespace:TxmlNs = Null)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local node:TxmlNode
		If namespace = Null Then
			node = _create(xmlNewNode(Null, cStr))
		Else
			node = _create(xmlNewNode(namespace._xmlNSPtr, cStr))
		End If

		Return node
	End Function

	Rem
	bbdoc: Read the value of a node.
	returns: The node content.
	about: This can be either the text carried directly by this node if it's a TEXT node or the aggregate
	string of the values carried by this node child's (TEXT and ENTITY_REF). Entity references are substituted.
	End Rem
	Method getContent:String()
		Local s:Byte Ptr = xmlNodeGetContent(_xmlNodePtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Concat the given string at the end of the existing node content.
	returns: -1 in case of error, 0 otherwise
	about: Parameters:
	<ul>
	<li><b>content</b> : the content.</li>
	</ul>
	End Rem
	Method concatText:Int(content:String)
		Assert content, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()
		Local ret:Int = xmlTextConcat(_xmlNodePtr, cStr, content.length)
		MemFree cStr
		Return ret
	End Method

	Rem
	bbdoc: Is this node a Text node ?
	End Rem
	Method isText:Int()
		Return xmlNodeIsText(_xmlNodePtr)
	End Method

	Rem
	bbdoc: Checks whether this node is an empty or whitespace only (and possibly ignorable) text-node.
	End Rem
	Method isBlankNode:Int()
		Return xmlIsBlankNode(_xmlNodePtr)
	End Method

	Rem
	bbdoc: Set (or reset) the base URI of a node, i.e. the value of the xml:base attribute.
	about: Parameters:
	<ul>
	<li><b>uri</b> : the new base URI.</li>
	</ul>
	End Rem
	Method setBase(uri:String)
		Assert uri, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
		xmlNodeSetBase(_xmlNodePtr, cStr)
		MemFree cStr
	End Method

	Rem
	bbdoc: Searches for the BASE URL.
	returns: The base URL, or Null if not found.
	about: The code should work on both XML and HTML document even if base mechanisms are completely different.
	It returns the base as defined in RFC 2396 sections 5.1.1. Base URI within Document Content and 5.1.2.
	Base URI from the Encapsulating Entity However it does not return the document base (5.1.3),
	use TxmlDoc. #getBase for this
	End Rem
	Method getBase:String()
		Local s:Byte Ptr = xmlNodeGetBase(Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]), _xmlNodePtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Replace the content of a node.
	about:Parameters:
	<ul>
	<li><b>content</b> : the new value of the content</li>
	</ul>
	End Rem
	Method setContent(content:String)
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()
		xmlNodeSetContent(_xmlNodePtr, cStr)
		MemFree cStr
	End Method

	Rem
	bbdoc: Append the extra substring to the node content.
	about:Parameters:
	<ul>
	<li><b>content</b> : extra content</li>
	</ul>
	End Rem
	Method addContent(content:String)
		Assert content, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()
		xmlNodeAddContent(_xmlNodePtr, cStr)
		MemFree cStr
	End Method

	Rem
	bbdoc: Set (or reset) the name of a node.
	about:Parameters:
	<ul>
	<li><b>name</b> : the new tag name</li>
	</ul>
	End Rem
	Method setName(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		xmlNodeSetName(_xmlNodePtr, cStr)
		MemFree cStr
	End Method

	Rem
	bbdoc: Merge two text nodes into one
	about: Parameters:
	<ul>
	<li><b>node</b> : the second text node being merged.</li>
	</ul>
	End Rem
	Method textMerge:TxmlNode(node:TxmlNode)
		If node <> Null Then
			Return TxmlNode._create(xmlTextMerge(_xmlNodePtr, node._xmlNodePtr))
		Else
			Return Self
		End If
	End Method

	Rem
	bbdoc: Creation of a new child element
	about: Added at the end of child nodes list. @namespace and @content parameters are optional (Null).
	If @namespace is Null, the newly created element inherits the namespace of the node. If @content is non Null,
	a child list containing the TEXTs and ENTITY_REFs node will be created.<br>
	NOTE: @content is supposed to be a piece of XML CDATA, so it allows entity references.
	XML special chars must be escaped first by using doc.#encodeEntities, or #addTextChild should be used.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the name of the child.</li>
	<li><b>namespace</b> : a namespace if any.</li>
	<li><b>content</b> : the XML content of the child if any.</li>
	</ul>
	</p>
	End Rem
	Method addChild:TxmlNode(name:String, namespace:TxmlNs = Null, content:String = Null)
		Assert name, XML_ERROR_PARAM

		Local s:Byte Ptr
		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		If content <> Null Then

			Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()

			If namespace <> Null Then
				s = xmlNewChild(_xmlNodePtr, namespace._xmlNsPtr, cStr1, cStr2)
			Else
				s = xmlNewChild(_xmlNodePtr, Null, cStr1, cStr2)
			End If

			MemFree cStr2
		Else
			If namespace <> Null Then
				s = xmlNewChild(_xmlNodePtr, namespace, Cstr1, Null)
			Else
				s = xmlNewChild(_xmlNodePtr, Null, cStr1, Null)
			End If
		End If

		MemFree cStr1

		Return TxmlNode._create(s)
	End Method

	Rem
	bbdoc: Creation of a new child text element
	returns: The new child node.
	about: Added at the end of @parent children list.
	@namespace and @content parameters are optional (Null). If @namespace is Null, the newly
	created element inherits the namespace of the parent. If @content is non Null, a child TEXT
	node will be created containing the string @content.<br>
	NOTE: Use #addChild if @content will contain entities that need to be preserved. Use this function, #addTextChild,
	if you need to ensure that reserved XML chars that might appear in @content, such as the ampersand,
	greater-than or less-than signs, are automatically replaced by their XML escaped entity
	representations.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the name of the child.</li>
	<li><b>namespace</b> : a namespace, if any.</li>
	<li><b>content</b> : the text content of the child, if any.</li>
	</ul>
	</p>
	End Rem
	Method addTextChild:TxmlNode(name:String, namespace:TxmlNs = Null, content:String = Null)
		Assert name, XML_ERROR_PARAM

		Local s:Byte Ptr

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		If content <> Null Then

			Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()

			If namespace <> Null Then
				s = xmlNewTextChild(_xmlNodePtr, namespace._xmlNsPtr, cStr1, cStr2)
			Else
				s = xmlNewTextChild(_xmlNodePtr, Null, cStr1, cStr2)
			End If

			MemFree cStr2
		Else
			If namespace <> Null Then
				s = xmlNewTextChild(_xmlNodePtr, namespace._xmlNsPtr, cStr1, Null)
			Else
				s = xmlNewTextChild(_xmlNodePtr, Null, cStr1, Null)
			End If
		End If

		MemFree cStr1

		Return TxmlNode._create(s)
	End Method

	Rem
	bbdoc: Add a list of nodes at the end of the child list of this node, merging adjacent TEXT nodes.
	returns: the last child or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>list</b> : the list of nodes.</li>
	</ul>
	End Rem
	Method addChildList:TxmlNode(list:TList)
		If list <> Null Then
			Local firstNode:TxmlNode = Null
			Local currentNode:TxmlNode = Null
			For Local node:TxmlNode = EachIn list
				If firstNode = Null Then
					firstNode = node
				Else
					currentNode.addNextSibling(node)
				End If
				currentNode = node
			Next
			Return TxmlNode._create(xmlAddChild(_xmlNodePtr, firstNode._xmlNodePtr))
		End If
		Return Null
	End Method

	Rem
	bbdoc: Add a new node @node as the next sibling.
	returns: the new node or Null in case of error.
	about: If the new node was already inserted in a document it is first unlinked from its existing context.
	If the new node is ATTRIBUTE, it is added into properties 	instead of children. If there is an attribute with
	equal name, it is first destroyed.
	<p>Parameters:
	<ul>
	<li><b>node</b> : the new node.</li>
	</ul>
	</p>
	End Rem
	Method addNextSibling:TxmlNode(node:TxmlNode)
		Assert node, XML_ERROR_PARAM

		Return TxmlNode._create(xmlAddNextSibling(_xmlNodePtr, node._xmlNodePtr))
	End Method

	Rem
	bbdoc: Add a new node @node as the previous sibling, merging adjacent TEXT nodes.
	returns: the new node or Null in case of error.
	about: If the new node was already inserted in a document it is first unlinked from its existing context.
	If the new node is ATTRIBUTE, it is added into properties instead of children. If there is an attribute
	with equal name, it is first destroyed.
	<p>Parameters:
	<ul>
	<li><b>node</b> : the new node.</li>
	</ul>
	</p>
	End Rem
	Method addPreviousSibling:TxmlNode(node:TxmlNode)
		Assert node, XML_ERROR_PARAM

		Return TxmlNode._create(xmlAddPrevSibling(_xmlNodePtr, node._xmlNodePtr))
	End Method

	Rem
	bbdoc: Add a new element @node to the list of siblings, merging adjacent TEXT nodes.
	returns: the new node or Null in case of error.
	about: If the new element was already inserted in a document it is first unlinked from its existing context.
	<p>Parameters:
	<ul>
	<li><b>node</b> : the new node.</li>
	</ul>
	</p>
	End Rem
	Method addSibling:TxmlNode(node:TxmlNode)
		Assert node, XML_ERROR_PARAM

		Return TxmlNode._create(xmlAddSibling(_xmlNodePtr, node._xmlNodePtr))
	End Method

	Rem
	bbdoc: Create a new attribute.
	returns: The Attribute object.
	about: Parameters:
	<ul>
	<li><b>name</b> : the attribute name.</li>
	<li><b>value</b> : the attribute value.</li>
	</ul>
	End Rem
	Method addAttribute:TxmlAttribute(name:String, value:String = "")
		Assert name, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local att:TxmlAttribute = TxmlAttribute._create(xmlNewProp(_xmlNodePtr, cStr1, cStr2))
		MemFree cStr1
		MemFree cStr2
		Return att
	End Method

	Rem
	bbdoc: Set (or reset) an attribute carried by a node.
	returns: The attribute object.
	about: Parameters:
	<ul>
	<li><b>name</b> : the attribute name.</li>
	<li><b>value</b> : the attribute value.</li>
	</ul>
	End Rem
	Method setAttribute:TxmlAttribute(name:String, value:String = "")
		Assert name, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local att:TxmlAttribute = TxmlAttribute._create(xmlSetProp(_xmlNodePtr, cStr1, cStr2))
		MemFree cStr1
		MemFree cStr2
		Return att
	End Method

	Rem
	bbdoc: Set (or reset) an attribute carried by a node.
	returns: The attribute object.
	about: The @namespace must be in scope, this is not checked.
	<p>Parameters:
	<ul>
	<li><b>namespace</b> : the namespace definition.</li>
	<li><b>name</b> : the attribute name.</li>
	<li><b>value</b> : the attribute value.</li>
	</ul>
	</p>
	End Rem
	Method setNsAttribute:TxmlAttribute(namespace:TxmlNs, name:String, value:String = "")
		Assert namespace, XML_ERROR_PARAM
		Assert name, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local att:TxmlAttribute = TxmlAttribute._create(xmlSetNsProp(_xmlNodePtr, namespace._xmlNsPtr, cStr1, cStr2))
		MemFree cStr1
		MemFree cStr2
		Return att
	End Method

	Rem
	bbdoc: Remove an attribute carried by the node.
	returns: 0 if successful, -1 if not found
	about: Parameters:
	<ul>
	<li><b>namespace</b> : the namespace definition.</li>
	<li><b>name</b> : the attribute name.</li>
	</ul>
	End Rem
	Method unsetNsAttribute:Int(namespace:TxmlNs, name:String)
		Assert namespace, XML_ERROR_PARAM
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local ret:Int = xmlUnsetNsProp(_xmlNodePtr, namespace._xmlNsPtr, cStr)
		MemFree cStr
		Return ret
	End Method

	Rem
	bbdoc: Remove an attribute carried by the node.
	returns: 0 if successful, -1 if not found
	about: Parameters:
	<ul>
	<li><b>name</b> : the attribute name.</li>
	</ul>
	End Rem
	Method unsetAttribute:Int(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local ret:Int = xmlUnsetProp(_xmlNodePtr, cStr)
		MemFree cStr
		Return ret
	End Method

	Rem
	bbdoc: Search and get the value of an attribute associated to the node
	returns: The attribute value or Null if not found.
	about: This does the entity substitution. This function looks in DTD attribute declaration for FIXED or
	default declaration values unless DTD use has been turned off.<br>
	NOTE: this function acts independently of namespaces associated to the attribute. Use
	#getNsAttribute or #getNoNsAttribute for namespace aware processing.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the attribute name.</li>
	</ul>
	</p>
	End Rem
	Method getAttribute:String(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local s:Byte Ptr = xmlGetProp(_xmlNodePtr, cStr)
		MemFree cStr
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Search and get the value of an attribute associated to a node.
	returns: the attribute value or Null if not found.
	about: This attribute has to be anchored in the namespace specified. This does the entity substitution.
	This function looks in DTD attribute declaration for FIXED or default declaration values unless DTD
	use has been turned off.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the attribute name</li>
	<li><b>namespace</b> : the URI of the namespace</li>
	</ul>
	</p>
	End Rem
	Method getNsAttribute:String(name:String, namespace:String)
		Assert name, XML_ERROR_PARAM
		Assert namespace, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(namespace).toCString()

		Local s:Byte Ptr = xmlGetNsProp(_xmlNodePtr, cStr1, cStr2)

		MemFree cStr1
		MemFree cStr2

		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Search and get the value of an attribute associated to the node.
	returns: the attribute value or Null if not found.
	about: This does the entity substitution. This function looks in DTD attribute declaration for FIXED or
	default declaration values unless DTD use has been turned off. This function is similar to #getAttribute except
	it will accept only an attribute in no namespace.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the attribute name</li>
	</ul>
	</p>
	End Rem
	Method getNoNsAttribute:String(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local s:Byte Ptr = xmlGetNoNsProp(_xmlNodePtr, cStr)
		MemFree cStr

		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Search for an attribute associated to the node
	returns: the attribute or Null if not found.
	about: This attribute has to be anchored in the namespace specified. This does the entity substitution.
	This function looks in DTD attribute declaration for FIXED or default declaration values unless DTD
	use has been turned off. Note that a namespace of Null indicates to use the default namespace.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the attribute name</li>
	<li><b>namespace</b> : the URI of the namespace</li>
	</ul>
	</p>
	End Rem
	Method hasNsAttribute:TxmlAttribute(name:String, namespace:String)
		Assert name, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		If namespace <> Null Then
			Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(namespace).toCString()
			Local att:TxmlAttribute = TxmlAttribute._create(xmlHasNsProp(_xmlNodePtr, cStr1, cStr2))
			MemFree cStr1
			MemFree cStr2
			Return att
		Else
			Local att:TxmlAttribute = TxmlAttribute._create(xmlHasNsProp(_xmlNodePtr, cStr1, Null))
			MemFree cStr1
			Return att
		End If
	End Method

	Rem
	bbdoc: Search an attribute associated to the node
	returns: the attribute or Null if not found.
	about: This function also looks in DTD attribute declaration for FIXED or default declaration values
	unless DTD use has been turned off.
	<p>Parameters:
	<ul>
	<li><b>name</b> : the attribute name</li>
	</ul>
	</p>
	End Rem
	Method hasAttribute:TxmlAttribute(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local att:TxmlAttribute = TxmlAttribute._create(xmlHasProp(_xmlNodePtr, cStr))
		MemFree cStr
		Return att
	End Method

	Rem
	bbdoc: Build a structure based Path for the node.
	returns: The path or Null in case of error.
	End Rem
	Method getNodePath:String()
		Local s:Byte Ptr = xmlGetNodePath(_xmlNodePtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Unlink the old node from its current context
	returns: The removed node.
	about: Prune the new one at the same place. If @withNode was already inserted in a document it is first
	unlinked from its existing context.
	<p>Parameters:
	<ul>
	<li><b>withNode</b> : the replacing node.</li>
	</ul>
	</p>
	End Rem
	Method replaceNode:TxmlNode(withNode:TxmlNode)
		Assert withNode, XML_ERROR_PARAM
		Return TxmlNode._create(xmlReplaceNode(_xmlNodePtr, withNode._xmlNodePtr))
	End Method

	Rem
	bbdoc: Associate a namespace to a node, a posteriori.
	about: Parameters:
	<ul>
	<li><b>namespace</b> : a namespace.</li>
	</ul>
	End Rem
	Method setNamespace(namespace:TxmlNs)
		Assert namespace, XML_ERROR_PARAM

		xmlSetNs(_xmlNodePtr, namespace._xmlNsPtr)
	End Method

	Rem
	bbdoc: Set (or reset) the space preserving behaviour of a node, i.e. the value of the xml:space attribute.
	about: Parameters:
	<ul>
	<li><b>value</b> : the xml:space value ("0": default, 1: "preserve").</li>
	</ul>
	End Rem
	Method setSpacePreserve(value:Int = False)
		If value <> False Then
			value = True
		End If
		xmlNodeSetSpacePreserve(_xmlNodePtr, value)
	End Method

	Rem
	bbdoc: Searches the space preserving behaviour of a node, i.e. the values of the xml:space attribute or the one carried by the nearest ancestor.
	Returns: -1 if xml:space is not inherited, 0 if "default", 1 if "preserve"
	End Rem
	Method getSpacePreserve:Int()
		Return xmlNodeGetSpacePreserve(_xmlNodePtr)
	End Method

	Rem
	bbdoc: Set the language of a node, i.e. the values of the xml:lang attribute.
	about: Parameters:
	<ul>
	<li><b>lang</b> : the language description.</li>
	</ul>
	End Rem
	Method setLanguage(lang:String)
		Assert lang, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(lang).toCString()
		xmlNodeSetLang(_xmlNodePtr, cStr)
		MemFree cStr
	End Method

	Rem
	bbdoc: Searches the language of a node, i.e. the values of the xml:lang attribute or the one carried by the nearest ancestor.
	returns: the language value, or Null if not found.
	End Rem
	Method GetLanguage:String()
		Local s:Byte Ptr = xmlNodeGetLang(_xmlNodePtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Creation of a new node containing a comment.
	returns: the new node object
	about: Parameters:
	<ul>
	<li><b>comment</b> : the comment content</li>
	</ul>
	End Rem
	Method addComment:TxmlNode(comment:String)
		Assert comment, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(comment).toCString()
		Local commentPtr:Byte Ptr = xmlNewComment(cStr)
		MemFree cStr

		If commentPtr <> Null Then
			Return TxmlNode._create(xmlAddChild(_xmlNodePtr, commentPtr))
		End If
	End Method

	Rem
	bbdoc: Creation of a new node containing a CDATA block.
	returns: the new node object
	about: Parameters:
	<ul>
	<li><b>content</b> : the CDATA block content</li>
	</ul>
	End Rem
	Method addCDataBlock:TxmlNode(content:String)
		Assert content, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(content).toCString()

		Local cdataPtr:Byte Ptr = xmlNewCDataBlock(Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]), cStr, content.length)
		MemFree cStr

		If cdataPtr <> Null Then
			Return TxmlNode._create(xmlAddChild(_xmlNodePtr, cdataPtr))
		End If
	End Method

	Rem
	bbdoc: Return the string equivalent to the text contained in the child nodes made of TEXTs and ENTITY_REFs.
	End Rem
	Method GetText:String()
		Local s:Byte Ptr = xmlNodeListGetString(Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]), Byte Ptr(Int Ptr(_xmlNodePtr + _children)[0]), 1)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Get the next sibling node
	returns: The next node or Null if there are none.
	about: Equivalent to TxmlNode( #nextSibling() ).
	End Rem
	Method nextNode:TxmlNode()
		Return TxmlNode(nextSibling())
	End Method

	Rem
	bbdoc: Get the previous sibling node
	returns: The previous node or Null if there are none.
	about: Equivalent to TxmlNode( #previousSibling() ).
	End Rem
	Method previousNode:TxmlNode()
		Return TxmlNode(previousSibling())
	End Method

	Rem
	bbdoc: Get the last child.
	returns: The last child or Null if none.
	End Rem
	Method getLastChild:TxmlNode(nodeType:Int = XML_ELEMENT_NODE)
		Return TxmlNode(Super.getLastChild(nodeType))
	End Method

	Rem
	bbdoc: Get the first child.
	returns: The first child or Null if none.
	End Rem
	Method getFirstChild:TxmlBase(nodeType:Int = XML_ELEMENT_NODE)
		Return TxmlNode(Super.getFirstChild(nodeType))
	End Method

	Rem
	bbdoc: Returns a string representation of the node and its children.
	End Rem
	Method toString:String()
		Local buffer:TxmlBuffer = TxmlBuffer.newBuffer()
		xmlNodeDump(buffer._xmlBufferPtr, Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]) ,_xmlNodePtr, 1, True)
		Local t:String = buffer.getContent()
		buffer.free()
		Return t
	End Method

	Rem
	bbdoc: Search a Namespace registered under a given name space for a document.
	returns: the namespace or Null.
	about: Recurse on the parents until it finds the defined namespace or return Null otherwise.
	@nameSpace can be Null, this is a search for the default namespace. We don't allow to cross entities boundaries.
	If you don't declare the namespace within those you will be in troubles !!! A warning is generated to cover
	this case.
	<p>Parameters:
	<ul>
	<li><b>namespace</b> : the namespace prefix.</li>
	</ul>
	</p>
	End Rem
	Method searchNamespace:TxmlNs(namespace:String)
		If namespace <> Null Then
			Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(namespace).toCString()

			Local ns:TxmlNs = TxmlNs._create(xmlSearchNs(Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]), _xmlNodePtr, cStr))
			MemFree cStr
			Return ns
		Else
			Return TxmlNs._create(xmlSearchNs(Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]), _xmlNodePtr, Null))
		End If
	End Method

	Rem
	bbdoc: Search a Namespace aliasing a given URI.
	returns: The namespace or Null.
	about: Recurse on the parents until it finds the defined namespace or return Null otherwise.
	<p>Parameters:
	<ul>
	<li><b>href</b> : the namespace value.</li>
	</ul>
	</p>
	End Rem
	Method searchNsByHref:TxmlNs(href:String)
		Assert href, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(href).toCString()
		Local ns:TxmlNs = TxmlNs._create(xmlSearchNsByHref(Byte Ptr(Int Ptr(_xmlNodePtr + _doc)[0]), _xmlNodePtr, cStr))
		MemFree cStr
		Return ns
	End Method

	Rem
	bbdoc: Do a copy of the node.
	returns: a new TxmlNode, or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>extended</b> : if 1 do a recursive copy (properties, namespaces and children when applicable)<br>
					if 2 copy properties and namespaces (when applicable)</li>
	</ul>
	End Rem
	Method copy:TxmlNode(extended:Int = 1)
		Return TxmlNode._create(xmlCopyNode(_xmlNodePtr, extended))
	End Method

	Rem
	bbdoc: Do a copy of the node to a given document.
	returns: a new TxmlNode, or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>doc</b> : the document.</li>
	<li><b>extended</b> : if 1 do a recursive copy (properties, namespaces and children when applicable)<br>
					if 2 copy properties and namespaces (when applicable)</li>
	</ul>
	End Rem
	Method copyToDoc:TxmlNode(doc:TxmlDoc, extended:Int = 1)
		Assert doc, XML_ERROR_PARAM
		Return TxmlNode._create(xmlDocCopyNode(_xmlNodePtr, doc._xmlDocPtr, extended))
	End Method

	Rem
	bbdoc: Update all nodes under the tree to point to the right document.
	about: Parameters:
	<ul>
	<li><b>doc</b> : the document.</li>
	</ul>
	End Rem
	Method setTreeDoc(doc:TxmlDoc)
		Assert doc, XML_ERROR_PARAM
		xmlSetTreeDoc(_xmlNodePtr, doc._xmlDocPtr)
	End Method

	Rem
	bbdoc: Implement the XInclude substitution for the subtree.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	End Rem
	Method XIncludeProcessTree:Int()
		Return xmlXIncludeProcessTree(_xmlNodePtr)
	End Method

	Rem
	bbdoc: Implement the XInclude substitution for the subtree.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	about: Parameters:
	<ul>
	<li><b>flags</b> : a set of xml Parser Options used for parsing XML includes (see #fromFile for details on available options)</li>
	</ul>
	End Rem
	Method XIncludeProcessTreeFlags:Int(flags:Int)
		Return xmlXIncludeProcessTreeFlags(_xmlNodePtr, flags)
	End Method

	Rem
	bbdoc: Returns the associated namespace.
	End Rem
	Method getNamespace:TxmlNs()
		Return TxmlNs._create(Byte Ptr(Int Ptr(_xmlNodePtr + _ns)[0]))
	End Method

	Rem
	bbdoc: Returns the list of node attributes.
	returns: The list of attributes or Null if the node has none.
	End Rem
	Method getAttributeList:TList()
		If Byte Ptr(Int Ptr(_basePtr + _properties)[0]) = Null Then
			Return Null
		End If

		Local attributes:TList = New TList
		Local attr:TxmlBase = chooseCreateFromType(Byte Ptr(Int Ptr(_basePtr + _properties)[0]))

		While attr <> Null

			attributes.addLast(attr)

			attr = attr.nextSibling()
		Wend

		Return attributes

	End Method

	Rem
	bbdoc: Unlinks a node from the document.
	about: After unlinking, and the node is no longer required, it should be freed using #freeNode.
	End Rem
	Method unlinkNode()
		xmlUnlinkNode(_xmlNodePtr)
	End Method

	Rem
	bbdoc: Frees a node.
	about: The node should be @unlinked before being freed. See #unlinkNode.
	End Rem
	Method freeNode()
		xmlFreeNode(_xmlNodePtr)
	End Method

End Type

Rem
bbdoc: Xml Buffer
End Rem
Type TxmlBuffer
	Const _content:Int	 = 0		' The buffer content UTF8 (byte ptr)
	Const _use:Int = 4			' The buffer size used (int)
	Const _size:Int = 8		' The buffer size (int)
	Const _alloc:Int = 12		' The buffer allocation scheme (int)

	Field _xmlBufferPtr:Byte Ptr

	Function _create:TxmlBuffer(_xmlBufferPtr:Byte Ptr)
		If _xmlBufferPtr <> Null Then
			Local this:TxmlBuffer = New TxmlBuffer

			this._xmlBufferPtr = _xmlBufferPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Function newBuffer:TxmlBuffer()
		Return TxmlBuffer._create(xmlBufferCreate())
	End Function

	Rem
	bbdoc: Routine to create an XML buffer from an immutable memory area.
	about: The area won't be modified nor copied, and is expected to be present until the end
	of the buffer lifetime.
	End Rem
	Function CreateStatic:TxmlBuffer(mem:Byte Ptr, size:Int)
		Return TxmlBuffer._create(xmlBufferCreateStatic(mem, size))
	End Function

	Rem
	bbdoc: Extract the content of a buffer.
	End Rem
	Method getContent:String()
		'Local s:Byte Ptr = xmlBufferContent(_xmlBufferPtr)
		'If s <> Null Then
	'		Local ret:String String.fromCString(s)
	'		MemFree(s)
	'		Return ret
	'	End If
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlBufferPtr + _content)[0]))
	End Method

	Method free()
		xmlBufferFree(_xmlBufferPtr)
	End Method
End Type

Rem
bbdoc:
End Rem
Type TxmlOutputBuffer

	Field _xmlOutputBufferPtr:Byte Ptr

	Function _create:TxmlOutputBuffer(_xmlOutputBufferPtr:Byte Ptr)
		If _xmlOutputBufferPtr <> Null Then
			Local this:TxmlOutputBuffer = New TxmlOutputBuffer

			this._xmlOutputBufferPtr = _xmlOutputBufferPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Function createBuffer:TxmlOutputBuffer(buffer:TxmlBuffer)
		Return TxmlOutputBuffer._create(xmlOutputBufferCreateBuffer(buffer._xmlBufferPtr, Null))
	End Function

	Function createIO:TxmlOutputBuffer()
		Return TxmlOutputBuffer._create(xmlOutputBufferCreateIO(TxmlOutputStreamHandler.writeCallback, ..
				TxmlOutputStreamHandler.closeCallback, Null, Null))
	End Function

End Type

Rem
bbdoc: An XML Namespace
End Rem
Type TxmlNs
	Const _next:Int = 0		' Next Ns link For this node (byte ptr)
	Const _type:Int = 4		' Global Or Local (int)
	Const _href:Int = 8		' URL For the namespace (byte ptr)
	Const _prefix:Int = 12	' prefix For the namespace (byte ptr)

	Field _xmlNsPtr:Byte Ptr

	Function _create:TxmlNs(_xmlNsPtr:Byte Ptr)
		If _xmlNsPtr <> Null Then
			Local this:TxmlNs = New TxmlNs
			this._xmlNsPtr = _xmlNsPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the type... global or local.
	End Rem
	Method getType:Int()
		Return Int Ptr(_xmlNsPtr + _type)[0]
	End Method

	Rem
	bbdoc: Returns the URL for the namespace.
	End Rem
	Method getHref:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlNsPtr + _href)[0]))
	End Method

	Rem
	bbdoc: Returns the prefix for the namespace.
	End Rem
	Method getPrefix:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlNsPtr + _prefix)[0]))
	End Method

	Rem
	bbdoc: Free up the structures associated to the namespace
	End Rem
	Method free()
		xmlFreeNs(_xmlNsPtr)
	End Method
End Type

Rem
bbdoc: An XML Attribute
End Rem
Type TxmlAttribute Extends TxmlBase

	' offsets from the pointer
	'Const _type:Int = 4		' Type number, (int)
	'Const _name:Int = 8		' the name of the node, Or the entity (byte ptr)
	'Const _value:Int = 12		' the value of the property (byte ptr)
	'Const _last:Int = 16		' last child link (byte ptr)
	'Const _parent:Int = 20		' child->parent link (byte ptr)
	'Const _next:Int = 24		' Next sibling link (byte ptr)
	'Const _prev:Int = 28		' previous sibling link (byte ptr)
	'Const _doc:Int = 32		' the containing document (byte ptr)
	Const _ns:Int = 36			' pointer To the associated namespace (byte ptr)
	Const _atype:Int = 40		' the attribute Type If validating (int?)

	' reference to the actual attribute
	Field _xmlAttrPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlAttribute(_xmlAttrPtr:Byte Ptr)
		If _xmlAttrPtr <> Null Then
			Local this:TxmlAttribute = New TxmlAttribute

			this._xmlAttrPtr = _xmlAttrPtr
			this.initBase(_xmlAttrPtr)

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the attribute value.
	End Rem
	Method getValue:String()
		Local s:Byte Ptr = xmlNodeListGetString(Byte Ptr(Int Ptr(_xmlAttrPtr + _doc)[0]), Byte Ptr(Int Ptr(_xmlAttrPtr + _children)[0]), 1)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: The attribute type, if validating.
	returns: The attribute type.
	about: Possible attribute types are:<br>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ATTRIBUTE_CDATA</td></tr>
	<tr><td>XML_ATTRIBUTE_ID</td></tr>
	<tr><td>XML_ATTRIBUTE_IDREF</td></tr>
	<tr><td>XML_ATTRIBUTE_IDREFS</td></tr>
	<tr><td>XML_ATTRIBUTE_ENTITY</td></tr>
	<tr><td>XML_ATTRIBUTE_ENTITIES</td></tr>
	<tr><td>XML_ATTRIBUTE_NMTOKEN</td></tr>
	<tr><td>XML_ATTRIBUTE_NMTOKENS</td></tr>
	<tr><td>XML_ATTRIBUTE_ENUMERATION</td></tr>
	<tr><td>XML_ATTRIBUTE_NOTATION</td></tr>
	</table>
	End Rem
	Method getAttributeType:Int()
		Return Int Ptr(_xmlAttrPtr + _atype)[0]
	End Method

	Rem
	bbdoc: Returns the associated Namespace.
	returns: The associated namespace, or Null if none.
	End Rem
	Method getNameSpace:TxmlNs()
		Return TxmlNs._create(Byte Ptr(Int Ptr(_xmlAttrPtr + _ns)[0]))
	End Method

End Type

Rem
bbdoc: An XML Node set
End Rem
Type TxmlNodeSet

	Const _nodeNr:Int = 0		' number of nodes in the set (int)
	Const _nodeMax:Int = 4		' size of the array as allocated (int)
	Const _nodelist:Int = 8	' array of nodes in no particular order (byte ptr)

	' reference to the actual node set
	Field _xmlNodeSetPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlNodeSet(_xmlNodeSetPtr:Byte Ptr)
		If _xmlNodeSetPtr <> Null Then
			Local this:TxmlNodeSet = New TxmlNodeSet

			this._xmlNodeSetPtr = _xmlNodeSetPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: The count of nodes in the node set.
	End Rem
	Method getNodeCount:Int()
		Return Int Ptr(_xmlNodeSetPtr + _nodeNr)[0]
	End Method

	Rem
	bbdoc: The list of nodes in the node set.
	End Rem
	Method getNodeList:TList()
		If Byte Ptr(Int Ptr(_xmlNodeSetPtr + _nodelist)[0]) = Null Then
			Return Null
		End If

		Local nodeList:TList = New TList

		Local count:Int = getNodeCount()

		' use a pointer to the list of pointers, then iterate through that list
		Local pointer:Int Ptr = Int Ptr(Byte Ptr(Int Ptr(_xmlNodeSetPtr + _nodelist)[0]))

		For Local i:Int = 0 Until count

			Local node:TxmlNode = TxmlNode._create(Byte Ptr(pointer[i]))

			nodeList.addLast(node)

		Next

		Return nodeList
	End Method

	Rem
	bbdoc: Converts the node set to its boolean value.
	returns: The boolean value
	End Rem
	Method castToBoolean:Int()
		Return xmlXPathCastNodeSetToBoolean(_xmlNodeSetPtr)
	End Method

	Rem
	bbdoc: Converts the node set to its number value.
	returns: The number value
	End Rem
	Method castToNumber:Double()
		Return xmlXPathCastNodeSetToNumber(_xmlNodeSetPtr)
	End Method

	Rem
	bbdoc: Converts the node set to its string value.
	returns: The string value
	End Rem
	Method castToString:String()
		Return _xmlConvertUTF8ToMax(xmlXPathCastNodeSetToString(_xmlNodeSetPtr))
	End Method

	Rem
	bbdoc: Checks whether the node set is empty or not.
	End Rem
	Method isEmpty:Int()
		Return getNodeCount() = 0 Or Byte Ptr(Int Ptr(_xmlNodeSetPtr + _nodelist)[0]) = Null
	End Method

	Rem
	bbdoc: Free the node set compound (not the actual nodes !).
	End Rem
	Method free()
		xmlXPathFreeNodeSet(_xmlNodeSetPtr)
	End Method
End Type

Rem
bbdoc: An XML XPath Object
End Rem
Type TxmlXPathObject

	Const _type:Int = 0 		' (int)
	Const _nodesetval:Int = 4	' a pointer to a nodeset (byte ptr)
	Const _boolval:Int = 8	' (int)
	Const _floatval:Int = 12	' (double)
	Const _stringval:Int = 16	' (byte ptr)
	Const _user:Int = 20		' (byte ptr)
	Const _index:Int = 24	' (int)
	Const _user2:Int = 28	' (byte ptr)
	Const _index2:Int = 32	' (int)

	' reference to the actual xpath object
	Field _xmlXPathObjectPtr:Byte Ptr


	' internal function... not part of the API !
	Function _create:TxmlXPathObject(_xmlXPathObjectPtr:Byte Ptr)
		If _xmlXPathObjectPtr <> Null Then
			Local this:TxmlXPathObject = New TxmlXPathObject

			this._xmlXPathObjectPtr = _xmlXPathObjectPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type range using a single node.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>node</b> : the starting and ending node</li>
	</ul>
	End Rem
	Function XPointerNewCollapsedRange:TxmlXPathObject(node:TxmlNode)
		Assert node, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewCollapsedRange(node._xmlNodePtr))
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type LocationSet and initialize it with all the nodes from @nodeset.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>nodeset</b> : a node set</li>
	</ul>
	End Rem
	Function XPointerNewLocationSetNodeSet:TxmlXPathObject(nodeset:TxmlNodeSet)
		Assert nodeset, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewLocationSetNodeSet(nodeset._xmlNodeSetPtr))
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type LocationSet and initialize it with the single range made of the two nodes @startnode and @endnode.
	returns: the newly created object.
	about: Parameters:
	<ul>
	<li><b>startnode</b> : the start Node value</li>
	<li><b>endnode</b> : the end Node value or Null</li>
	</ul>
	End Rem
	Function XPointerNewLocationSetNodes:TxmlXPathObject(startnode:TxmlNode, endnode:TxmlNode)
		Assert startnode, XML_ERROR_PARAM

		Local obj:TxmlXPathObject = Null

		If endnode <> Null Then
			obj = TxmlXPathObject._create(xmlXPtrNewLocationSetNodes(startnode._xmlNodePtr, endnode._xmlNodePtr))
		Else
			obj = TxmlXPathObject._create(xmlXPtrNewLocationSetNodes(startnode._xmlNodePtr, Null))
		End If

		Return obj
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type range.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>startnode</b> : the starting node</li>
	<li><b>startindex</b> : the start index</li>
	<li><b>endnode</b> : the ending node</li>
	<li><b>endindex</b> : the ending index</li>
	</ul>
	End Rem
	Function XPointerNewRange:TxmlXPathObject(startnode:TxmlNode, startindex:Int, endnode:TxmlNode, endindex:Int)
		Assert startnode, XML_ERROR_PARAM
		Assert endnode, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewRange(startnode._xmlNodePtr, startindex, endnode._xmlNodePtr, endindex))
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type range from a node to an object.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>startnode</b> : the starting node</li>
	<li><b>endobj</b> : the ending object</li>
	</ul>
	End Rem
	Function XPointerNewRangeNodeObject:TxmlXPathObject(startnode:TxmlNode, endobj:TxmlXPathObject)
		Assert startnode, XML_ERROR_PARAM
		Assert endobj, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewRangeNodeObject(startnode._xmlNodePtr, endobj._xmlXPathObjectPtr))
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type range from a node to a point.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>startnode</b> : the starting node</li>
	<li><b>endpoint</b> : the ending point</li>
	</ul>
	End Rem
	Function XPointerNewRangeNodePoint:TxmlXPathObject(startnode:TxmlNode, endpoint:TxmlXPathObject)
		Assert startnode, XML_ERROR_PARAM
		Assert endpoint, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewRangeNodePoint(startnode._xmlNodePtr, endpoint._xmlXPathObjectPtr))
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type range using 2 nodes.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>startnode</b> : the starting node</li>
	<li><b>endnode</b> : the ending node</li>
	</ul>
	End Rem
	Function XPointerNewRangeNodes:TxmlXPathObject(startnode:TxmlNode, endnode:TxmlNode)
		Assert startnode, XML_ERROR_PARAM
		Assert endnode, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewRangeNodes(startnode._xmlNodePtr, endnode._xmlNodePtr))
	End Function

	Rem
	bbdoc: Create a new TxmlXPathObject of type range from a point to a node.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>startpoint</b> : the starting point</li>
	<li><b>endnode</b> : the ending node</li>
	</ul>
	End Rem
	Function XPointerNewRangePointNode:TxmlXPathObject(startpoint:TxmlXPathObject, endnode:TxmlNode)
		Assert startpoint, XML_ERROR_PARAM
		Assert endnode, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewRangePointNode(startpoint._xmlXPathObjectPtr, endnode._xmlNodePtr))
	End Function

	Rem
	bbdoc: Create a new xmlXPathObjectPtr of type range using 2 Points.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>startpoint</b> : the starting point</li>
	<li><b>endpoint</b> : the ending point</li>
	</ul>
	End Rem
	Function XPointerNewRangePoints:TxmlXPathObject(startpoint:TxmlXPathObject, endpoint:TxmlXPathObject)
		Assert startpoint, XML_ERROR_PARAM
		Assert endpoint, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrNewRangePoints(startpoint._xmlXPathObjectPtr, endpoint._xmlXPathObjectPtr))
	End Function

	Rem
	bbdoc: Wrap the LocationSet @value in a new TxmlXPathObject.
	returns: The newly created object.
	about: Parameters:
	<ul>
	<li><b>value</b> : the LocationSet value</li>
	</ul>
	End Rem
	Function XPointerWrapLocationSet:TxmlXPathObject(value:TxmlLocationSet)
		Assert value, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPtrWrapLocationSet(value._xmlLocationSetPtr))
	End Function

	Rem
	bbdoc: The XPath object type
	about: The following lists possible XPath object types:<br>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XPATH_UNDEFINED</td></tr>
	<tr><td>XPATH_NODESET</td></tr>
	<tr><td>XPATH_BOOLEAN</td></tr>
	<tr><td>XPATH_NUMBER</td></tr>
	<tr><td>XPATH_STRING</td></tr>
	<tr><td>XPATH_POINT</td></tr>
	<tr><td>XPATH_RANGE</td></tr>
	<tr><td>XPATH_LOCATIONSET</td></tr>
	<tr><td>XPATH_USERS</td></tr>
	<tr><td>XPATH_XSLT_TREE</td></tr>
	</table>
	End Rem
	Method getType:Int()
		Return Int Ptr(_xmlXPathObjectPtr + _type)[0]
	End Method

	Rem
	bbdoc: Returns the node set for the xpath
	End Rem
	Method getNodeSet:TxmlNodeSet()
		Return TxmlNodeSet._create(Byte Ptr(Int Ptr(_xmlXPathObjectPtr + _nodesetval)[0]))
	End Method

	Rem
	bbdoc: Whether the node set is empty or not
	End Rem
	Method nodeSetIsEmpty:Int()
		Return Byte Ptr(Int Ptr(_xmlXPathObjectPtr + _nodesetval)[0]) = Null Or getNodeSet().isEmpty()
	End Method

	Rem
	bbdoc: Returns the xpath object string value
	End Rem
	Method getStringValue:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlXPathObjectPtr + _stringval)[0]))
	End Method

	Rem
	bbdoc: Converts the XPath object to its boolean value
	returns: The boolean value
	End Rem
	Method castToBoolean:Int()
		Return xmlXPathCastToBoolean(_xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Converts the XPath object to its number value
	returns: The number value
	End Rem
	Method castToNumber:Double()
		Return xmlXPathCastToNumber(_xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Converts the XPath object to its string value
	returns: The string value
	End Rem
	Method castToString:String()
		Local s:Byte Ptr = xmlXPathCastToString(_xmlXPathObjectPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Converts an existing object to its boolean() equivalent.
	returns: the new object, this one is freed
	End Rem
	Method convertBoolean:TxmlXPathObject()
		Return TxmlXPathObject._create(xmlXPathConvertBoolean(_xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Converts an existing object to its number() equivalent.
	returns: the new object, this one is freed
	End Rem
	Method convertNumber:TxmlXPathObject()
		Return TxmlXPathObject._create(xmlXPathConvertNumber(_xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Converts an existing object to its string() equivalent.
	returns: the new object, this one is freed
	End Rem
	Method convertString:TxmlXPathObject()
		Return TxmlXPathObject._create(xmlXPathConvertString(_xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Allocate a new copy of a given object.
	returns: The newly created object.
	End Rem
	Method copy:TxmlXPathObject()
		Return TxmlXPathObject._create(xmlXPathObjectCopy(_xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Build a node list tree copy of the XPointer result.
	returns: An node list or Null. The caller has to free the node tree.
	about: This will drop Attributes and Namespace declarations.
	end rem
	Method XPointerBuildNodeList:TxmlNode()
		Return TxmlNode._create(xmlXPtrBuildNodeList(_xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Create a new TxmlLocationSet of type double and value of this XPathObject.
	returns: The newly created object.
	end rem
	Method XPointerLocationSetCreate:TxmlLocationSet()
		Return TxmlLocationSet._create(xmlXPtrLocationSetCreate(_xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Free up the TxmlXPathObject.
	End Rem
	Method free()
		xmlXPathFreeObject(_xmlXPathObjectPtr)
	End Method
End Type

Rem
bbdoc: An XML XPath Context
about: Expression evaluation occurs with respect to a context.<br>
The context consists of:
<ul>
<li> a node (the context node)</li>
<li> a node list (the context node list)</li>
<li> a set of variable bindings</li>
<li> a function library</li>
<li> the set of namespace declarations in scope for the expression</li>
</ul>
End Rem
Type TxmlXPathContext
	Const _doc:Int = 0					' The current document (byte ptr)
	Const _node:Int = 4				' The current node (byte ptr)
	Const _nb_variables_unused:Int = 8	' unused (hash table) (int)
	Const _max_variables_unused:Int = 12	' unused (hash table) (int)
	Const _varHash:Int = 16			' Hash table of defined variables (byte ptr)
	Const _nb_types:Int = 20			' number of defined types (int)
	Const _max_types:Int = 24			' Max number of types (int)
	Const _types:Int = 28				' Array of defined types (byte ptr)
	Const _nb_funcs_unused:Int = 32		' unused (hash table) (int)
	Const _max_funcs_unused:Int = 36	' unused (hash table) (int)
	Const _funcHash:Int = 40			' Hash table of defined funcs (byte ptr)
	Const _nb_axis:Int = 44			' number of defined axis (int)
	Const _max_axis:Int = 48			' Max number of axis (int)
	Const _axis:Int = 52				' Array of defined axis the namespace nod (byte ptr)
	Const _namespaces:Int = 56			' Array of namespaces (byte ptr)
	Const _nsNr:Int = 60				' number of namespace in scope (int)
	Const _user:Int = 64				' Function To free extra variables (byte ptr)
	Const _contextSize:Int = 68			' the context size (int)
	Const _proximityPosition:Int = 72	' the proximity position extra stuff For (int)
	Const _xptr:Int = 76				' is this an XPointer context (int)
	Const _here:Int = 80				' For here() (byte ptr)
	Const _origin:Int = 84				' For origin() the set of namespace decla (byte ptr)
	Const _nsHash:Int = 88				' The namespaces hash table (byte ptr)
	Const _varLookupFunc:Int = 92		' variable lookup func (byte ptr)
	Const _varLookupData:Int = 96		' variable lookup data Possibility To lin (byte ptr)
	Const _extra:Int = 100				' needed For XSLT The Function name And U (byte ptr)
	Const _function:Int = 104			'  (byte ptr)
	Const _functionURI:Int = 108		' Function lookup Function And data (byte ptr)
	Const _funcLookupFunc:Int = 112		' Function lookup func (byte ptr)
	Const _funcLookupData:Int = 116		' Function lookup data temporary namespac (byte ptr)
	Const _tmpNsList:Int = 120			' Array of namespaces (byte ptr)
	Const _tmpNsNr:Int = 124			' number of namespace in scope error repo (int)
	Const _userData:Int = 128			' user specific data block (byte ptr)
	Const _error:Int = 132				' the callback in Case of errors (byte ptr)
	Const _lastError:Int = 136			' the last error (byte ptr)
	Const _debugNode:Int = 140			' the source node XSLT dictionary (byte ptr)
	Const _dict:Int = 144				' dictionnary If any (byte ptr)
	Const _flags:Int = 148				' flags To control compilation (int)

	' reference to the actual xpath object
	Field _xmlXPathContextPtr:Byte Ptr


	' internal function... not part of the API !
	Function _create:TxmlXPathContext(_xmlXPathContextPtr:Byte Ptr)
		If _xmlXPathContextPtr <> Null Then
			Local this:TxmlXPathContext = New TxmlXPathContext

			this._xmlXPathContextPtr = _xmlXPathContextPtr

			Return this
		End If
		Return Null
	End Function

	Rem
	bbdoc: Create a new XPointer context.
	returns: The TxmlXPathContext just allocated.
	about: Parameters:
	<ul>
	<li><b>doc</b> : the XML document</li>
	<li><b>here</b> : the node that directly contains the XPointer being evaluated or Null</li>
	<li><b>origin</b> : the element from which a user or program initiated traversal of the link, or Null</li>
	</ul>
	End Rem
	Function XPointerNewContext:TxmlXPathContext(doc:TxmlDoc, here:TxmlNode, origin:TxmlNode)
		Assert doc, XML_ERROR_PARAM

		Local context:TxmlXPathContext = Null

		If here <> Null Then
			If origin <> Null Then
				context = TxmlXPathContext._create(xmlXPtrNewContext(doc._xmlDocPtr, here._xmlNodePtr, origin._xmlNodePtr))
			Else
				context = TxmlXPathContext._create(xmlXPtrNewContext(doc._xmlDocPtr, here._xmlNodePtr, Null))
			End If
		Else
			If origin <> Null Then
				context = TxmlXPathContext._create(xmlXPtrNewContext(doc._xmlDocPtr, Null, origin._xmlNodePtr))
			Else
				context = TxmlXPathContext._create(xmlXPtrNewContext(doc._xmlDocPtr, Null, Null))
			End If
		End If

		Return context
	End Function

	Rem
	bbdoc: Evaluate the XPath expression in the context.
	returns: A TxmlXPathObject resulting from the evaluation or Null
	about: Parameters:
	<ul>
	<li><b>text</b> : the XPath expression</li>
	</ul>
	End Rem
	Method evalExpression:TxmlXPathObject(text:String)
		Assert text, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(text).toCString()
		Local xp:TxmlXPathObject = TxmlXPathObject._create(xmlXPathEvalExpression(cStr, _xmlXPathContextPtr))
		MemFree cStr
		Return xp
	End Method

	Rem
	bbdoc: Evaluate the XPath Location Path in the context.
	returns: A TxmlXPathObject resulting from the evaluation or Null
	about: Parameters:
	<ul>
	<li><b>text</b> : the XPath expression</li>
	</ul>
	End Rem
	Method eval:TxmlXPathObject(text:String)
		Assert text, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(text).toCString()
		Local xp:TxmlXPathObject = TxmlXPathObject._create(xmlXPathEval(cStr, _xmlXPathContextPtr))
		MemFree cStr
		Return xp
	End Method

	'Rem
	'bbdoc: Creates/frees an Object cache on the XPath context.
	'returns: 0 If the setting succeeded, And -1 on API Or internal errors.
	'about: If activated XPath objects (TxmlXPathObject) will be cached internally To be reused.
	'@options: 0: This will set the XPath Object caching.
	'@value: This will set the maximum number of XPath objects To be cached per slot There are 5 slots For: node-set,
	'String, number, boolean, And misc objects. Use <0 For the Default number (100). Other values For @options have
	'currently no effect.
	'<p>Parameters:
	'<ul>
	'<li><b>active</b> : enables/disables (creates/frees) the cache</li>
	'<li><b>value</b> : a value with semantics dependant on @options</li>
	'<li><b>options</b> : options (currently only the value 0 is used)</li>
	'</ul>
	'</p>
	'End Rem
	'Method setCache:Int(active:Int, value:Int, options:Int)
	'	Return xmlXPathContextSetCache(_xmlXPathContextPtr, active, value, options)
	'End Method

	Rem
	bbdoc: Return the TxmlDoc associated to this XPath context.
	End Rem
	Method getDocument:TxmlDoc()
		Return TxmlDoc._create(Byte Ptr(Int Ptr(_xmlXPathContextPtr + _doc)[0]))
	End Method

	Rem
	bbdoc: Return the current TxmlNode associated with this XPath context.
	End Rem
	Method GetNode:TxmlNode()
		Return TxmlNode._create(Byte Ptr(Int Ptr(_xmlXPathContextPtr + _node)[0]))
	End Method

	Rem
	bbdoc: Register a new namespace.
	about: If @uri is Null it unregisters the namespace
	End Rem
	Method registerNamespace:Int(prefix:String, uri:String)
		Local ret:Int = -1

		If prefix = Null Then
			If uri = Null Then
				ret = xmlXPathRegisterNs(_xmlXPathContextPtr, Null, Null)
			Else
				Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
				ret = xmlXPathRegisterNs(_xmlXPathContextPtr, Null, cStr)
				MemFree cStr
			End If
		Else
			Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(prefix).toCString()

			If uri = Null Then
				ret = xmlXPathRegisterNs(_xmlXPathContextPtr, cStr1, Null)
			Else
				Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
				ret = xmlXPathRegisterNs(_xmlXPathContextPtr, cStr1, cStr)
				MemFree cStr
			End If

			MemFree cStr1
		End If

		Return ret
	End Method

	Rem
	bbdoc: Evaluate a predicate result for the current node.
	about: A PredicateExpr is evaluated by evaluating the Expr and converting the result to a boolean.
	If the result is a number, the result will be converted to true if the number is equal to the position of the
	context node in the context node list (as returned by the position function) and will be converted to false
	otherwise; if the result is not a number, then the result will be converted as if by a call to the boolean function.
	End Rem
	Method evalPredicate:Int(res:TxmlXPathObject)
		Assert res, XML_ERROR_PARAM

		Local result:Int

		If res <> Null Then
			result = xmlXPathEvalPredicate(_xmlXPathContextPtr, res._xmlXPathObjectPtr)
		End If

		Return result
	End Method

	Rem
	bbdoc: Evaluate the XPath Location Path in the context.
	returns: The TxmlXPathObject resulting from the evaluation or Null. The caller has to free the object.
	End Rem
	Method XPointerEval:TxmlXPathObject(expr:String)
		Assert expr, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(expr).toCString()
		Local obj:TxmlXPathObject = TxmlXPathObject._create(xmlXPtrEval(cStr, _xmlXPathContextPtr))

		MemFree(cStr)

		Return obj
	End Method

	Rem
	bbdoc: Returns the number of defined types.
	End Rem
	Method countDefinedTypes:Int()
		Return Int Ptr(_xmlXPathContextPtr + _nb_types)[0]
	End Method

	Rem
	bbdoc: Returns the max number of types.
	End Rem
	Method getMaxTypes:Int()
		Return Int Ptr(_xmlXPathContextPtr + _max_types)[0]
	End Method

	Rem
	bbdoc: Returns the context size.
	End Rem
	Method getContextSize:Int()
		Return Int Ptr(_xmlXPathContextPtr + _contextSize)[0]
	End Method

	Rem
	bbdoc: Returns the proximity position.
	End Rem
	Method getProximityPosition:Int()
		Return Int Ptr(_xmlXPathContextPtr + _proximityPosition)[0]
	End Method

	Rem
	bbdoc: Returns whether this is an XPointer context or not.
	End Rem
	Method isXPointerContext:Int()
		Return Int Ptr(_xmlXPathContextPtr + _xptr)[0]
	End Method

	Rem
	bbdoc: Returns the XPointer for here.
	End Rem
	Method getHere:TxmlNode()
		Return TxmlNode._create(Byte Ptr(Int Ptr(_xmlXPathContextPtr + _here)[0]))
	End Method

	Rem
	bbdoc: Returns the XPointer for origin.
	End Rem
	Method GetOrigin:TxmlNode()
		Return TxmlNode._create(Byte Ptr(Int Ptr(_xmlXPathContextPtr + _origin)[0]))
	End Method

	Rem
	bbdoc: Returns the function name when calling a function.
	End Rem
	Method getFunction:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlXPathContextPtr + _function)[0]))
	End Method

	Rem
	bbdoc: Returns the function URI when calling a function.
	End Rem
	Method getFunctionURI:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlXPathContextPtr + _functionURI)[0]))
	End Method

	Rem
	bbdoc: Free up the TxmlXPathContext
	End Rem
	Method free()
		xmlXPathFreeContext(_xmlXPathContextPtr)
	End Method
End Type

Rem
bbdoc: An XML DTD
End Rem
Type TxmlDtd Extends TxmlBase
	'Const _type:Int = 4    		' XML_DTD_NODE, must be second ! (byte ptr)
	'Const _name:Int = 8    		' Name of the DTD (byte ptr)
	'Const _children:Int = 12        ' the value of the property link (byte ptr)
	'Const _last:Int = 16			' last child link (byte ptr)
	'Const _parent:Int = 20		' child->parent link (byte ptr)
	'Const _next:Int = 24			' Next sibling link (byte ptr)
	'Const _prev:Int = 28			' previous sibling link (byte ptr)
	'Const _doc:Int = 32			' the containing document (byte ptr)
	Const _notations:Int = 36       ' Hash table For notations If any (byte ptr)
	Const _elements:Int = 40		' Hash table For elements If any (byte ptr)
	Const _attributes:Int = 44      ' Hash table For attributes If any (byte ptr)
	Const _entities:Int = 48        ' Hash table For entities If any (byte ptr)
	Const _externalID:Int = 52      ' External identifier For Public DTD (byte ptr)
	Const _systemID:Int = 56        ' URI For a SYSTEM Or Public DTD (byte ptr)
	Const pentities:Int = 60       ' Hash table For param entities If any (byte ptr)

	Field _xmlDtdPtr:Byte Ptr

	Function _create:TxmlDtd(_xmlDtdPtr:Byte Ptr)
		If _xmlDtdPtr <> Null Then
			Local this:TxmlDtd = New TxmlDtd
			this._xmlDtdPtr = _xmlDtdPtr
			this.initBase(_xmlDtdPtr)
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the external identifier for PUBLIC DTD.
	End Rem
	Method getExternalID:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDtdPtr+ _externalID)[0]))
	End Method

	Rem
	bbdoc: Returns the URI for a SYSTEM or PUBLIC DTD.
	End Rem
	Method getSystemID:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDtdPtr+ _systemID)[0]))
	End Method

	Rem
	bbdoc: Do a copy of the dtd.
	returns: A new TxmlDtd object, or Null in case of error.
	End Rem
	Method copyDtd:TxmlDtd()
		Return TxmlDtd._create(xmlCopyDtd(_xmlDtdPtr))
	End Method

	Rem
	bbdoc: Search the DTD for the description of this attribute on this element.
	returns: The TxmlDtdAttribute if found or Null.
	about: Parameters:
	<ul>
	<li><b>elem</b> : the element name</li>
	<li><b>name</b> : the attribute name</li>
	</ul>
	End Rem
	Method getAttrDesc:TxmlDtdAttribute(elem:String, name:String)
		Assert elem, XML_ERROR_PARAM
		Assert name, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(elem).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local ret:TxmlDtdAttribute = TxmlDtdAttribute._create(xmlGetDtdAttrDesc(_xmlDtdPtr, cStr1, cStr2))

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Method

	Rem
	bbdoc: Search the DTD for the description of this element.
	returns: The TxmlDtdElement if found or Null.
	about: Parameters:
	<ul>
	<li><b>name</b> : the element name</li>
	</ul>
	End Rem
	Method getElementDesc:TxmlDtdElement(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local ret:TxmlDtdElement = TxmlDtdElement._create(xmlGetDtdElementDesc(_xmlDtdPtr, cStr))

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Search the DTD for the description of this notation.
	returns: The TxmlNotation if found or Null.
	about: Parameters:
	<ul>
	<li><b>name</b> : the notation name</li>
	</ul>
	End Rem
	Method getNotationDesc:TxmlNotation(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local ret:TxmlNotation = TxmlNotation._create(xmlGetDtdNotationDesc(_xmlDtdPtr, cStr))

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Search the DTD for the description of this qualified attribute on this element.
	returns: The TxmlDtdAttribute if found or Null.
	about: Parameters:
	<ul>
	<li><b>elem</b> : the element name</li>
	<li><b>name</b> : the attribute name</li>
	<li><b>prefix</b> : the attribute namespace prefix</li>
	</ul>
	End Rem
	Method getQAttrDesc:TxmlDtdAttribute(elem:String, name:String, prefix:String)
		Assert elem, XML_ERROR_PARAM
		Assert name, XML_ERROR_PARAM
		Assert prefix, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(elem).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(prefix).toCString()

		Local ret:TxmlDtdAttribute = TxmlDtdAttribute._create(xmlGetDtdQAttrDesc(_xmlDtdPtr, cStr1, cStr2, cStr3))

		MemFree(cStr1)
		MemFree(cStr2)
		MemFree(cStr3)

		Return ret
	End Method

	Rem
	bbdoc: Search the DTD for the description of this qualified element.
	returns: The TxmlDtdElement if found or Null.
	about: Parameters:
	<ul>
	<li><b>name</b> : the element name</li>
	<li><b>prefix</b> : the element namespace prefix</li>
	</ul>
	End Rem
	Method getQElementDesc:TxmlDtdElement(name:String, prefix:String)
		Assert name, XML_ERROR_PARAM
		Assert prefix, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(prefix).toCString()

		Local ret:TxmlDtdElement = TxmlDtdElement._create(xmlGetDtdQElementDesc(_xmlDtdPtr, cStr1, cStr2))

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Method

	Rem
	bbdoc: Free the DTD structure
	End Rem
	Method free()
		xmlFreeDtd(_xmlDtdPtr)
	End Method
End Type


Rem
bbdoc: An XML Error
End Rem
Type TxmlError
	Const _domain:Int = 0		' What part of the library raised this error (int)
	Const _code:Int = 4		' The error code, e.g. an xmlParserError (int)
	Const _message:Int = 8	' human-readable informative error message (byte ptr)
	Const _level:Int = 12		' how consequent is the error (int)
	Const _file:Int = 16		' the filename (byte ptr)
	Const _line:Int = 20		' the line number If available (int)
	Const _str1:Int = 24		' extra String information (byte ptr)
	Const _str2:Int = 28		' extra String information (byte ptr)
	Const _str3:Int = 32		' extra String information (byte ptr)
	Const _int1:Int = 36		' extra number information (int)
	Const _int2:Int = 40		' column number of the error Or 0 If N/A (int)
	Const _ctxt:Int = 44		' the parser context If available (byte ptr)
	Const _node:Int = 48		' the node in the tree (byte ptr)

	Field _xmlErrorPtr:Byte Ptr

	Function _create:TxmlError(_xmlErrorPtr:Byte Ptr)
		If _xmlErrorPtr <> Null Then
			Local this:TxmlError = New TxmlError
			this._xmlErrorPtr = _xmlErrorPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the part of the library that raised the error.
	about: The following lists possible domains:<br>
	<table>
	<tr><th>Constant</th><th>Meaning</th></tr>
	<tr><td>XML_FROM_NONE</td><td>From none</td></tr>
	<tr><td>XML_FROM_PARSER</td><td>The XML parser</td></tr>
	<tr><td>XML_FROM_TREE</td><td>The tree module</td></tr>
	<tr><td>XML_FROM_NAMESPACE</td><td>The XML Namespace module</td></tr>
	<tr><td>XML_FROM_DTD</td><td>The XML DTD validation with parser contex</td></tr>
	<tr><td>XML_FROM_HTML</td><td>The HTML parser</td></tr>
	<tr><td>XML_FROM_MEMORY</td><td>The memory allocator</td></tr>
	<tr><td>XML_FROM_OUTPUT</td><td>The serialization code</td></tr>
	<tr><td>XML_FROM_IO</td><td>The Input/Output stack</td></tr>
	<tr><td>XML_FROM_FTP</td><td>The FTP module</td></tr>
	<tr><td>XML_FROM_HTTP</td><td>The HTTP module</td></tr>
	<tr><td>XML_FROM_XINCLUDE</td><td>The XInclude processing</td></tr>
	<tr><td>XML_FROM_XPATH</td><td>The XPath module</td></tr>
	<tr><td>XML_FROM_XPOINTER</td><td>The XPointer module</td></tr>
	<tr><td>XML_FROM_REGEXP</td><td>The regular expressions module</td></tr>
	<tr><td>XML_FROM_DATATYPE</td><td>The W3C XML Schemas Datatype module</td></tr>
	<tr><td>XML_FROM_SCHEMASP</td><td>The W3C XML Schemas parser module</td></tr>
	<tr><td>XML_FROM_SCHEMASV</td><td>The W3C XML Schemas validation module</td></tr>
	<tr><td>XML_FROM_RELAXNGP</td><td>The Relax-NG parser module</td></tr>
	<tr><td>XML_FROM_RELAXNGV</td><td>The Relax-NG validator module</td></tr>
	<tr><td>XML_FROM_CATALOG</td><td>The Catalog module</td></tr>
	<tr><td>XML_FROM_C14N</td><td>The Canonicalization module</td></tr>
	<tr><td>XML_FROM_XSLT</td><td>The XSLT engine from libxslt</td></tr>
	<tr><td>XML_FROM_VALID</td><td>The XML DTD validation with valid context</td></tr>
	<tr><td>XML_FROM_CHECK</td><td>The error checking module</td></tr>
	<tr><td>XML_FROM_WRITER</td><td>The xmlwriter module</td></tr>
	<tr><td>XML_FROM_MODULE</td><td>The dynamically loaded module</td></tr>
	<tr><td>XML_FROM_I18N</td><td>The module handling character conversion</td></tr>
	</table>
	End Rem
	Method getErrorDomain:Int()
		Return Int Ptr(_xmlErrorPtr + _domain)[0]
	End Method

	Rem
	bbdoc: Returns the error code.
	End Rem
	Method getErrorCode:Int()
		Return Int Ptr(_xmlErrorPtr + _code)[0]
	End Method

	Rem
	bbdoc: Returns the error message text.
	End Rem
	Method getErrorMessage:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlErrorPtr + _message)[0]))
	End Method

	Rem
	bbdoc: Returns the error level.
	about: The following is a list of error levels:<br>
	<table>
	<tr><th>Constant</th><th>Meaning</th></tr>
	<tr><td>XML_ERR_NONE</td><td>No error</td></tr>
	<tr><td>XML_ERR_WARNING</td><td>A simple warning</td></tr>
	<tr><td>XML_ERR_ERROR</td><td>A recoverable error</td></tr>
	<tr><td>XML_ERR_FATAL</td><td>A fatal error</td></tr>
	</table>
	End Rem
	Method getErrorLevel:Int()
		Return Int Ptr(_xmlErrorPtr + _level)[0]
	End Method

	Rem
	bbdoc: Returns the filename.
	End Rem
	Method getFilename:String()
		Local s:Byte Ptr = Byte Ptr(Int Ptr(_xmlErrorPtr + _file)[0])
		If s Then
			Return _xmlConvertUTF8ToMax(s)
		End If
		Return Null
	End Method

	Rem
	bbdoc: Returns the error line, if available.
	End Rem
	Method getLine:Int()
		Return Int Ptr(_xmlErrorPtr + _line)[0]
	End Method

	Rem
	bbdoc: Returns extra error text information, if available.
	End Rem
	Method getExtraText:String[]()
		Local xtra:String[] = New String[0]
		Local s:Byte Ptr = Byte Ptr(Int Ptr(_xmlErrorPtr + _str1)[0])
		If s Then
			xtra = xtra[..xtra.length + 1]
			xtra[0] = _xmlConvertUTF8ToMax(s)
		End If

		s = Byte Ptr(Int Ptr(_xmlErrorPtr + _str2)[0])
		If s Then
			xtra = xtra[..xtra.length + 1]
			xtra[xtra.length - 1] = _xmlConvertUTF8ToMax(s)
		End If

		s = Byte Ptr(Int Ptr(_xmlErrorPtr + _str3)[0])
		If s Then
			xtra = xtra[..xtra.length + 1]
			xtra[xtra.length - 1] = _xmlConvertUTF8ToMax(s)
		End If

		If xtra.length > 0 Then
			Return xtra
		End If
		Return Null
	End Method

	Rem
	bbdoc: Returns the column number of the error or 0 if not available.
	End Rem
	Method getColumn:Int()
		Return Int Ptr(_xmlErrorPtr + _int2)[0]
	End Method

	Rem
	bbdoc: Returns the node in the tree, if available.
	End Rem
	Method getErrorNode:TxmlNode()
		Return TxmlNode._create(Byte Ptr(Int Ptr(_xmlErrorPtr + _node)[0]))
	End Method

End Type

Rem
bbdoc: An XML Streaming Text Reader
about: Text Reader API provides a simpler, more standard and more extensible interface to handle
large documents than a SAX-based reader.
<p>
A TxmlTextReader object can be instantiated through its #fromFile or #fromDoc functions.
</p>
<p>
For more insight into this parser, see the <a href="textreader_tutorial.html">Text Reader Tutorial</a>.
</p>
End Rem
Type TxmlTextReader

	Field _xmlTextReaderPtr:Byte Ptr

	Field docTextPtr:Byte Ptr
	Field urlTextPtr:Byte Ptr
	Field encTextPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlTextReader(_xmlTextReaderPtr:Byte Ptr)
		If _xmlTextReaderPtr <> Null Then
			Local this:TxmlTextReader = New TxmlTextReader

			this._xmlTextReaderPtr = _xmlTextReaderPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Method Delete()
		If docTextPtr Then
			MemFree docTextPtr
			docTextPtr = Null
		End If

		If urlTextPtr Then
			MemFree urlTextPtr
			urlTextPtr = Null
		End If

		If encTextPtr Then
			MemFree encTextPtr
			encTextPtr = Null
		End If
	End Method

	Rem
	bbdoc: Parse an XML file from the filesystem or the network.
	about: The parsing flags @options are a combination of the following:
	<table>
	<tr><th>Constant</th><th>Meaning</th></tr>
	<tr><td>XML_PARSE_RECOVER</td><td>recover on errors</td></tr>
	<tr><td>XML_PARSE_NOENT</td><td>substitute entities</td></tr>
	<tr><td>XML_PARSE_DTDLOAD</td><td>load the external subset</td></tr>
	<tr><td>XML_PARSE_DTDATTR</td><td>default DTD attributes</td></tr>
	<tr><td>XML_PARSE_DTDVALID</td><td>validate with the DTD</td></tr>
	<tr><td>XML_PARSE_NOERROR</td><td>suppress error reports</td></tr>
	<tr><td>XML_PARSE_NOWARNING</td><td>suppress warning reports</td></tr>
	<tr><td>XML_PARSE_PEDANTIC</td><td>pedantic error reporting</td></tr>
	<tr><td>XML_PARSE_NOBLANKS</td><td>remove blank nodes</td></tr>
	<tr><td>XML_PARSE_SAX1</td><td>use the SAX1 interface internally</td></tr>
	<tr><td>XML_PARSE_XINCLUDE</td><td>Implement XInclude substitition</td></tr>
	<tr><td>XML_PARSE_NONET</td><td>Forbid network access</td></tr>
	<tr><td>XML_PARSE_NODICT</td><td>Do not reuse the context dictionnary</td></tr>
	<tr><td>XML_PARSE_NSCLEAN</td><td>remove redundant namespaces declarations</td></tr>
	<tr><td>XML_PARSE_NOCDATA</td><td>merge CDATA as text nodes</td></tr>
	<tr><td>XML_PARSE_NOXINCNODE</td><td>do not generate XINCLUDE START/END nodes</td></tr>
	<tr><td>XML_PARSE_COMPACT</td><td>compact small text nodes. no modification of the tree allowed
	afterwards (will possibly crash if you try to modify the tree)</td></tr>
	<tr><td>XML_PARSE_OLD10</td><td>parse using XML-1.0 before update 5</td></tr>
	<tr><td>XML_PARSE_NOBASEFIX</td><td>do not fixup XINCLUDE xml:base uris</td></tr>
	<tr><td>XML_PARSE_HUGE</td><td>relax any hardcoded limit from the parser</td></tr>
	<tr><td>XML_PARSE_OLDSAX</td><td>parse using SAX2 interface from before 2.7.0</td></tr>
	</table>
	<p>Parameters:
	<ul>
	<li><b>filename</b> : a file or URL. Supports "incbin::" paths.</li>
	<li><b>encoding</b> : the document encoding, or Null.</li>
	<li><b>options</b> : a combination of xmlParserOptions.</li>
	</ul>
	</p>
	End Rem
	Function fromFile:TxmlTextReader(filename:String, encoding:String = Null, options:Int = 0)
		Assert filename, XML_ERROR_PARAM

		Local i:Int = filename.Find( "::",0 )
		' a "normal" url?
		If i = -1 Then
			Local cStr1:Byte Ptr = filename.toCString()
			If encoding = Null And options = 0 Then
				Local t:TxmlTextReader = _create(xmlNewTextReaderFilename(cStr1))

				MemFree cStr1
				Return t
			Else
				Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(encoding).toCString()
				Local t:TxmlTextReader = _create(xmlReaderForFile(cStr1, cStr2, options))

				MemFree cStr1
				MemFree cStr2
				Return t
			End If
		Else
			Local proto:String = filename[..i].ToLower()
			Local path:String = filename[i+2..]

			If proto = "incbin" Then
				Local buf:Byte Ptr = IncbinPtr( path )
				If Not buf Then
					Return Null
				End If
				Local size:Int = IncbinLen( path )

				If encoding = Null Then
					Return TxmlTextReader._create(xmlReaderForMemory(buf, size, Null, Null, options))
				Else
					Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(encoding).toCString()
					Local t:TxmlTextReader = TxmlTextReader._create(xmlReaderForMemory(buf, size, Null, cStr2, options))
					MemFree(cStr2)
					Return t
				End If
			End If
		End If

	End Function

	Rem
	bbdoc: Create an TxmlTextReader for an XML in-memory document.
	returns: The new reader or Null in case of error.
	about: The parsing flags @options are a combination of the options listed in #fromFile
	<p>Parameters:
	<ul>
	<li><b>text</b> : the string to be parsed.</li>
	<li><b>url</b> : the base URL to use for the document.</li>
	<li><b>encoding</b> : the document encoding, or Null.</li>
	<li><b>options</b> : a combination of xmlParserOptions</li>
	</ul>
	</p>
	End Rem
	Function fromDoc:TxmlTextReader(text:String, url:String, encoding:String, options:Int)
		Assert text, XML_ERROR_PARAM
		Assert url, XML_ERROR_PARAM

		Local docTextPtr:Byte Ptr = _xmlConvertMaxToUTF8(text).toCString()
		Local urlTextPtr:Byte Ptr = _xmlConvertMaxToUTF8(url).toCString()

		Local t:TxmlTextReader = Null
		If encoding <> Null Then
			Local encTextPtr:Byte Ptr = _xmlConvertMaxToUTF8(encoding).toCString()
			t = _create(xmlReaderForDoc(docTextPtr, urlTextPtr, encTextPtr, options))
			If t Then
				t.encTextPtr = encTextPtr
			End If
		Else
			t = _create(xmlReaderForDoc(docTextPtr, urlTextPtr, Null, options))
		End If

		If t Then
			t.docTextPtr = docTextPtr
			t.urlTextPtr = urlTextPtr
		End If

		Return t
	End Function

	Rem
	bbdoc: Provides the number of attributes of the current node.
	returns: 0 if no attributes, -1 in case of error or the attribute count
	End Rem
	Method attributeCount:Int()
		Return xmlTextReaderAttributeCount(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The base URI of the node.
	End Rem
	Method baseUri:String()
		Local s:Byte Ptr = xmlTextReaderBaseUri(_xmlTextReaderPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		End If
		Return Null
	End Method

	Rem
	bbdoc: Hacking interface allowing to get the TxmlDoc correponding to the current document being accessed by the TxmlTextReader.
	returns: The TxmlDoc or Null in case of error.
	about: NOTE: as a result of this call, the reader will not destroy the associated XML document and calling free()
	on the TxmlDoc is needed once the reader parsing has finished.
	End Rem
	Method currentDoc:TxmlDoc()
		Return TxmlDoc._create(xmlTextReaderCurrentDoc(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Deallocate all the resources associated to the reader.
	End Rem
	Method free()
		xmlFreeTextReader(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the next node in the stream, exposing its properties.
	returns: 1 if the node was read successfully, 0 if there is no more nodes to read, or -1 in case of error
	End Rem
	Method read:Int()
		Return xmlTextReaderRead(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Parses an attribute value into one or more Text and EntityReference nodes.
	about: 1 in case of success, 0 if the reader was not positioned on an attribute node or all the attribute values have been read, or -1 in case of error.
	End Rem
	Method readAttributeValue:Int()
		Return xmlTextReaderReadAttributeValue(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of the current node, including child nodes and markup.
	returns: A string containing the XML content, or Null if the current node is neither an element nor attribute, or has no child nodes.
	End Rem
	Method readInnerXml:String()
		Local s:Byte Ptr = xmlTextReaderReadInnerXml(_xmlTextReaderPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Reads the contents of the current node, including child nodes and markup.
	returns: A string containing the XML content, or NULL if the current node is neither an element nor attribute, or has no child nodes.
	End Rem
	Method readOuterXml:String()
		Local s:Byte Ptr = xmlTextReaderReadOuterXml(_xmlTextReaderPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Gets the read state of the reader.
	about: The state value, or -1 in case of error.
	End Rem
	Method readState:Int()
		Return xmlTextReaderReadState(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of an element or a text node as a string.
	about: A string containing the contents of the Element or Text node, or Null if the reader is positioned on any other type of node.
	End Rem
	Method ReadString:String()
		Local s:Byte Ptr = xmlTextReaderReadString(_xmlTextReaderPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: The qualified name of the node, equal to Prefix :LocalName.
	returns: The local name or Null if not available.
	End Rem
	Method constName:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstName(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The local name of the node.
	returns: The local name or Null if not available.
	End Rem
	Method constLocalName:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstLocalName(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Determine the encoding of the document being read.
	returns: A string containing the encoding of the document or Null in case of error.
	End Rem
	Method constEncoding:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstEncoding(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The base URI of the node.
	returns: The base URI or Null if not available.
	End Rem
	Method constBaseUri:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstBaseUri(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The URI defining the namespace associated with the node.
	returns: The namespace URI or Null if not available.
	End Rem
	Method constNamespaceUri:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstNamespaceUri(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: A shorthand reference to the namespace associated with the node.
	returns: The prefix or Null if not available.
	End Rem
	Method constPrefix:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstPrefix(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Provides the text value of the node if present.
	returns: the string or Null if not available.
	End Rem
	Method constValue:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstValue(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The xml:lang scope within which the node resides.
	returns: The xml:lang value or Null if none exists.
	End Rem
	Method constXmlLang:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstXmlLang(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Determine the XML version of the document being read.
	returns: A string containing the XML version of the document or Null in case of error.
	End Rem
	Method constXmlVersion:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderConstXmlVersion(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The depth of the node in the tree.
	returns: the depth or -1 in case of error
	End Rem
	Method depth:Int()
		Return xmlTextReaderDepth(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of the current node and the full subtree.
	about: It then makes the subtree available until the next #read call.
	returns: A node, valid until the next #read call or Null in case of error.
	End Rem
	Method expand:TxmlNode()
		Return TxmlNode._create(xmlTextReaderExpand(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Provides the value of the attribute with the specified qualified name.
	returns: A string containing the value of the specified attribute, or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>name</b> : the qualified name of the attribute.</li>
	</ul>
	End Rem
	Method getAttribute:String(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()

		Local s:Byte Ptr = xmlTextReaderGetAttribute(_xmlTextReaderPtr, cStr)
		MemFree cStr

		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Provides the value of the attribute with the specified index relative to the containing element.
	returns: A string containing the value of the specified attribute, or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>index</b> : the zero-based index of the attribute relative to the containing element.</li>
	</ul>
	End Rem
	Method getAttributeByIndex:String(index:Int)
		Local s:Byte Ptr = xmlTextReaderGetAttributeNo(_xmlTextReaderPtr, index)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Provides the value of the specified attribute
	returns: A string containing the value of the specified attribute, or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>localName</b> : the local name of the attribute.</li>
	<li><b>namespaceURI</b> : the namespace URI of the attribute.</li>
	</ul>
	End Rem
	Method getAttributeByNamespace:String(localName:String, namespaceURI:String)
		Assert localName, XML_ERROR_PARAM
		Assert namespaceURI, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(localName).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(namespaceURI).toCString()

		Local s:Byte Ptr = xmlTextReaderGetAttributeNs(_xmlTextReaderPtr, cStr1, cStr2)

		MemFree cStr1
		MemFree cStr2

		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Provide the column number of the current parsing point.
	returns: An int or 0 if not available
	End Rem
	Method getParserColumnNumber:Int()
		Return xmlTextReaderGetParserColumnNumber(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Provide the line number of the current parsing point.
	returns: An int or 0 if not available.
	End Rem
	Method getParserLineNumber:Int()
		Return xmlTextReaderGetParserLineNumber(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Read the parser internal property.
	returns: The value, usually 0 or 1, or -1 in case of error.
	about: The parser property can be one of the following values:
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_PARSER_LOADDTD</td></tr>
	<tr><td>XML_PARSER_DEFAULTATTRS</td></tr>
	<tr><td>XML_PARSER_VALIDATE</td></tr>
	<tr><td>XML_PARSER_SUBST_ENTITIES</td></tr>
	</table>
	<p>Parameters:
	<ul>
	<li><b>prop</b> : the parser property.</li>
	</ul>
	</p>
	End Rem
	Method getParserProperty:Int(prop:Int)
		Return xmlTextReaderGetParserProp(_xmlTextReaderPtr, prop)
	End Method

	Rem
	bbdoc: Whether the node has attributes.
	returns: 1 if true, 0 if false, and -1 in case or error
	End Rem
	Method hasAttributes:Int()
		Return xmlTextReaderHasAttributes(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Whether the node can have a text value.
	returns: 1 if true, 0 if false, and -1 in case or error.
	End Rem
	Method hasValue:Int()
		Return xmlTextReaderHasValue(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Whether an Attribute node was generated from the default value defined in the DTD or schema.
	returns: 0 if not defaulted, 1 if defaulted, and -1 in case of error
	End Rem
	Method isDefault:Int()
		Return xmlTextReaderIsDefault(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Check if the current node is empty.
	returns: 1 if empty, 0 if not and -1 in case of error.
	End Rem
	Method isEmptyElement:Int()
		Return xmlTextReaderIsEmptyElement(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Determine whether the current node is a namespace declaration rather than a regular attribute.
	returns: 1 if the current node is a namespace declaration, 0 if it is a regular attribute or other type of node, or -1 in case of error.
	End Rem
	Method isNamespaceDecl:Int()
		Return xmlTextReaderIsNamespaceDecl(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Retrieve the validity status from the parser context.
	about: The flag value 1 if valid, 0 if no, and -1 in case of error.
	End Rem
	Method isValid:Int()
		Return xmlTextReaderIsValid(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The local name of the node.
	returns: the local name or Null if not available
	End Rem
	Method localName:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderLocalName(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Resolves a namespace prefix in the scope of the current element.
	returns: A string containing the namespace URI to which the prefix maps or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>prefix</b> : the prefix whose namespace URI is to be resolved. To return the default namespace, specify Null.</li>
	</ul>
	End Rem
	Method lookupNamespace:String(prefix:String)
		Local s:Byte Ptr

		If prefix <> Null Then
			Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(prefix).toCString()
			s = xmlTextReaderLookupNamespace(_xmlTextReaderPtr, cStr)
			MemFree cStr
		Else
			s = xmlTextReaderLookupNamespace(_xmlTextReaderPtr, Null)
		End If

		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the attribute with the specified qualified name.
	returns: 1 in case of success, -1 in case of error, 0 if not found.
	about: Parameters:
	<ul>
	<li><b>name</b> : the qualified name of the attribute.</li>
	</ul>
	End Rem
	Method moveToAttribute:Int(name:String)
		Assert name, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(name).toCString()
		Local ret:Int = xmlTextReaderMoveToAttribute(_xmlTextReaderPtr, cStr)
		MemFree cStr
		Return ret
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the attribute with the specified index relative to the containing element.
	returns: 1 in case of success, -1 in case of error, 0 if not found
	about: Parameters:
	<ul>
	<li><b>index</b> : the zero-based index of the attribute relative to the containing element.</li>
	</ul>
	End Rem
	Method moveToAttributeByIndex:Int(index:Int)
		Return xmlTextReaderMoveToAttributeNo(_xmlTextReaderPtr, index)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the attribute with the specified local name and namespace URI.
	returns: 1 in case of success, -1 in case of error, 0 if not found
	about: Parameters:
	<ul>
	<li><b>localName</b> : the local name of the attribute.</li>
	<li><b>namespaceURI</b> : the namespace URI of the attribute.</li>
	</ul>
	End Rem
	Method moveToAttributeByNamespace:Int(localName:String, namespaceURI:String)
		Assert localName, XML_ERROR_PARAM
		Assert namespaceURI, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(localName).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(namespaceURI).toCString()
		Local ret:Int = xmlTextReaderMoveToAttributeNs(_xmlTextReaderPtr, cStr1, cStr2)
		MemFree cStr1
		MemFree cStr2
		Return ret
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the node that contains the current Attribute node.
	returns: 1 in case of success, -1 in case of error, 0 if not moved.
	End Rem
	Method moveToElement:Int()
		Return xmlTextReaderMoveToElement(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the first attribute associated with the current node.
	returns: 1 in case of success, -1 in case of error, 0 if not found
	End Rem
	Method moveToFirstAttribute:Int()
		Return xmlTextReaderMoveToFirstAttribute(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the next attribute associated with the current node.
	returns: 1 in case of success, -1 in case of error, 0 if not found
	End Rem
	Method moveToNextAttribute:Int()
		Return xmlTextReaderMoveToNextAttribute(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The qualified name of the node, equal to Prefix :LocalName.
	returns: the local name or Null if not available.
	End Rem
	Method name:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderName(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The URI defining the namespace associated with the node.
	returns: the namespace URI or Null if not available
	End Rem
	Method namespaceUri:String()
		Return _xmlConvertUTF8ToMax(xmlTextReaderNamespaceUri(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Skip to the node following the current one in document order while avoiding the subtree if any.
	returns: 1 if the node was read successfully, 0 if there is no more nodes to read, or -1 in case of error.
	End Rem
	Method nextNode:Int()
		Return xmlTextReaderNext(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Get the node type of the current node.
	returns: The xmlNodeType of the current node or -1 in case of error.
	End Rem
	Method nodeType:Int()
		Return xmlTextReaderNodeType(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The value indicating whether to normalize white space and attribute values.
	returns: 1 or -1 in case of error.
	about: Since attribute value and end of line normalizations are a MUST in the XML specification only the value true
	is accepted. The broken bahaviour of accepting out of range character entities like &amp;#0; is of course not supported
	either.
	End Rem
	Method normalization:Int()
		Return xmlTextReaderNormalization(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: A shorthand reference to the namespace associated with the node.
	returns: The prefix or Null if not available.
	End Rem
	Method prefix:Int()
		Return xmlTextReaderPrefix(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: This tells the XML Reader to preserve the current node.
	returns: The TxmlNode or Null in case of error.
	about: The caller must also use #currentDoc to keep an handle on the resulting document once
	parsing has finished.
	End Rem
	Method preserve:TxmlNode()
		Return TxmlNode._create(xmlTextReaderPreserve(_xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The quotation mark character used to enclose the value of an attribute.
	returns: " or ' and Null in case of error
	End Rem
	Method quoteChar:String()
		Local c:Int = xmlTextReaderQuoteChar(_xmlTextReaderPtr)
		If c <> -1 Then
			If c = 34 Then
				Return "~q"
			Else
				Return "'"
			End If
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: Use RelaxNG to validate the document as it is processed.
	returns: 0 in case the RelaxNG validation could be (des)activated and -1 in case of error.
	about: Activation is only possible before the first #read. if @rng is Null, then RelaxNG validation is desactivated.
	<p>Parameters:
	<ul>
	<li><b>rng</b> : the path to a RelaxNG schema or Null.</li>
	</ul>
	</p>
	End Rem
	Method relaxNGValidate:Int(rng:String)
		If rng <> Null Then
			Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(rng).toCString()
			Local ret:Int = xmlTextReaderRelaxNGValidate(_xmlTextReaderPtr, cStr)
			MemFree cStr
			Return ret
		Else
			Return xmlTextReaderRelaxNGValidate(_xmlTextReaderPtr, Null)
		End If
	End Method

	Rem
	bbdoc: Use W3C XSD schema to validate the document as it is processed.
	returns: 0 in case the schemas validation could be (de)activated and -1 in case of error.
	about: Activation is only possible before the first #read. If @xsd is Null, then XML Schema validation is deactivated.
	<p>Parameters:
	<ul>
	<li><b>xsd</b> : the path to a W3C XSD schema or Null.</li>
	</ul>
	</p>
	End Rem
	Method schemaValidate:Int(xsd:String)
		If xsd <> Null Then
			Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(xsd).toCString()
			Local ret:Int = xmlTextReaderSchemaValidate(_xmlTextReaderPtr, cStr)
			MemFree cStr
			Return ret
		Else
			Return xmlTextReaderSchemaValidate(_xmlTextReaderPtr, Null)
		End If
	End Method

	Rem
	bbdoc: Change the parser processing behaviour by changing some of its internal properties.
	returns: 0 if the call was successful, or -1 in case of error
	about: Note that some properties can only be changed before any read has been done.
	<p>Parameters:
	<ul>
	<li><b>prop</b> : the parser property to set. ( see #getParserProperty )</li>
	<li><b>value</b> : usually 0 or 1 to (de)activate it.</li>
	</ul>
	</p>
	End Rem
	Method setParserProp:Int(prop:Int, value:Int)
		Return xmlTextReaderSetParserProp(_xmlTextReaderPtr, prop, value)
	End Method

	Rem
	bbdoc: Determine the standalone status of the document being read.
	returns: 1 if the document was declared to be standalone, 0 if it was declared to be not standalone, or -1 if the document did not specify its standalone status or in case of error.
	End Rem
	Method standalone:Int()
		Return xmlTextReaderStandalone(_xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Provides the text value of the node if present
	returns: The string or Null if not available.
	End Rem
	Method value:String()
		Local s:Byte Ptr = xmlTextReaderValue(_xmlTextReaderPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

	Rem
	bbdoc: The xml:lang scope within which the node resides.
	returns: the xml:lang value or Null if none exists.
	End Rem
	Method xmlLang:String()
		Local s:Byte Ptr = xmlTextReaderXmlLang(_xmlTextReaderPtr)
		If s <> Null Then
			Local t:String = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
			Return t
		Else
			Return Null
		End If
	End Method

End Type

Rem
bbdoc: An XML Entity
End Rem
Type TxmlEntity Extends TxmlBase
	' offsets from the pointer
	'Const _type:Int = 4			' XML_ENTITY_DECL, (int)
	'Const _name:Int = 8			' Entity name (byte ptr)
	'Const _children:Int = 12		' First child link (byte ptr)
	'Const _last:Int = 16			' Last child link (Byte Ptr)
	'Const _parent:Int = 20		' -> DTD (Byte Ptr)
	'Const _next:Int = 24			' next sibling link (byte ptr)
	'Const _prev:Int = 28			' previous sibling link (byte ptr)
	'Const _doc:Int = 32			' the containing document (byte ptr)
	Const _orig:Int = 36			' content without ref substitution (byte ptr)
	Const _content:Int = 40		' content or ndata if unparsed (byte ptr)
	Const _length:Int = 44		' the content length (int)
	Const _etype:Int = 48		' The entity type (int)
	Const _ExternalID:Int = 52	' External identifier for PUBLIC (byte ptr)
	Const _SystemID:Int = 56		' URI for a SYSTEM or PUBLIC Entity (byte ptr)
	Const _nexte:Int = 60		' unused (byte ptr)
	Const _URI:Int = 64			' the full URI as computed (byte ptr)
	Const _owner:Int = 68		' does the entity own the childrens (int)

	Field _xmlEntityPtr:Byte Ptr

	Function _create:TxmlEntity(_xmlEntityPtr:Byte Ptr)
		If _xmlEntityPtr <> Null Then
			Local this:TxmlEntity = New TxmlEntity
			this._xmlEntityPtr = _xmlEntityPtr
			this.initBase(_xmlEntityPtr)
			Return this
		Else
			Return Null
		End If
	End Function

End Type

Rem
bbdoc: An XML Catalog
End Rem
Type TxmlCatalog

	Field _xmlCatalogPtr:Byte Ptr

	Function _create:TxmlCatalog(_xmlCatalogPtr:Byte Ptr)
		If _xmlCatalogPtr <> Null Then
			Local this:TxmlCatalog = New TxmlCatalog
			this._xmlCatalogPtr = _xmlCatalogPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Create a new Catalog.
	returns: A new catalog or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>sgml</b> : should this create an SGML catalog</li>
	</ul>
	End Rem
	Function newCatalog:TxmlCatalog(sgml:Int)
		Return TxmlCatalog._create(xmlNewCatalog(sgml))
	End Function

	Rem
	bbdoc: Load the catalog and build the associated data structures.
	returns: The catalog parsed or Null in case of error.
	about: This can be either an XML Catalog or an SGML Catalog.
	It will recurse in SGML Catalog entries. On the other hand XML Catalogs are not handled recursively.
	<p>Parameters:
	<ul>
	<li><b>filename</b> : a file path</li>
	</ul>
	</p>
	End Rem
	Function loadCatalog:TxmlCatalog(filename:String)
		Assert filename, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(filename).toCString()
		Local this:TxmlCatalog = TxmlCatalog._create(xmlLoadACatalog(cStr))
		MemFree(cStr)

		Return this
	End Function

	Rem
	bbdoc: Load the catalog and makes its definitions effective for the default external entity loader.
	returns: 0 in case of success -1 in case of error
	about: It will recurse in SGML CATALOG entries.
	<p>Parameters:
	<ul>
	<li><b>filename</b> : a file path</li>
	</ul>
	</p>
	End Rem
	Function loadDefaultCatalg:Int(filename:String)
		Assert filename, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(filename).toCString()
		Local ret:Int = xmlLoadCatalog(cStr)
		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Load an SGML super catalog.
	returns: The catalog parsed or Null in case of error.
	about: It won't expand CATALOG or DELEGATE references. This is only needed for manipulating SGML
	Super Catalogs like adding and removing CATALOG or DELEGATE entries.
	<p>Parameters:
	<ul>
	<li><b>filename</b> : a file path</li>
	</ul>
	</p>
	End Rem
	Function loadSGMLSuperCatalog:TxmlCatalog(filename:String)
		Assert filename, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(filename).toCString()
		Local this:TxmlCatalog = TxmlCatalog._create(xmlLoadSGMLSuperCatalog(cStr))
		MemFree(cStr)

		Return this
	End Function

	Rem
	bbdoc: Used to set the user preference w.r.t. to what catalogs should be accepted.
	about: The following lists possible xmlCatalogAllow values:
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_CATA_ALLOW_NONE</td></tr>
	<tr><td>XML_CATA_ALLOW_GLOBAL</td></tr>
	<tr><td>XML_CATA_ALLOW_DOCUMENT</td></tr>
	<tr><td>XML_CATA_ALLOW_ALL</td></tr>
	</table>
	End Rem
	Function setDefaults(allow:Int)
		Assert allow >=0 And allow <=3

		xmlCatalogSetDefaults(allow)
	End Function

	Rem
	bbdoc: Used to get the user preference w.r.t. to what catalogs should be accepted.
	returns: The current xmlCatalogAllow value. See @setDefaults for more information.
	End Rem
	Function getDefaults:Int()
		Return xmlCatalogGetDefaults()
	End Function

	Rem
	bbdoc: Used to set the debug level for catalog operation.
	returns: The previous value of the catalog debugging level.
	about: 0 disable debugging, 1 enable it.
	<p>Parameters:
	<ul>
	<li><b>level</b> : the debug level of catalogs required</li>
	</ul>
	</p>
	End Rem
	Function setDebug:Int(level:Int)
		Assert level = 0 Or level = 1

		Return xmlCatalogSetDebug(level)
	End Function

	Rem
	bbdoc: Allows to set the preference between public and system for deletion in XML Catalog resolution.
	returns: The previous value of the default preference for delegation.
	about: (C.f. section 4.1.1 of the spec)
	Values accepted are XML_CATA_PREFER_PUBLIC or XML_CATA_PREFER_SYSTEM.
	<p>Parameters:
	<ul>
	<li><b>prefer</b> : the default preference for delegation</li>
	</ul>
	</p>
	End Rem
	Function setDefaultPrefer:Int(prefer:Int)
		Return xmlCatalogSetDefaultPrefer(prefer)
	End Function

	Rem
	bbdoc: Add an entry in the catalog.
	returns: 0 if successful, -1 otherwise.
	about: It may overwrite existing but different entries. If called before any other catalog routine,
	allows to override the default shared catalog put in place by #initializeCatalog.
	<p>Parameters:
	<ul>
	<li><b>rtype</b> : the type of record to add to the catalog</li>
	<li><b>orig</b> : the system, public or prefix to match</li>
	<li><b>rep</b> : the replacement value for the match, if any</li>
	</ul>
	</p>
	End Rem
	Function addDefault:Int(rtype:String, orig:String, rep:String)
		Assert rtype, XML_ERROR_PARAM
		Assert orig, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(rtype).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(orig).toCString()

		Local ret:Int

		If rep <> Null Then
			Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(rep).toCString()
			ret = xmlCatalogAdd(cStr1, cStr2, cStr3)
			MemFree(cStr3)
		Else
			ret = xmlCatalogAdd(cStr1, cStr2, Null)
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Function

	Rem
	bbdoc: Convert all the SGML catalog entries as XML ones.
	return: The number of entries converted if successful, -1 otherwise.
	End Rem
	Function convertDefault:Int()
		Return xmlCatalogConvert()
	End Function

	Rem
	bbdoc: Remove an entry from the catalog.
	returns: The number of entries removed if successful, -1 otherwise.
	about: Parameters:
	<ul>
	<li><b>value</b> : the value to remove</li>
	</ul>
	End Rem
	Function defaultRemove:Int(value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local ret:Int = xmlCatalogRemove(cStr)
		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Do a complete resolution lookup of an External Identifier.
	returns: The URI of the resource or Null if not found.
	about: Parameters:
	<ul>
	<li><b>pubID</b> : the public ID string</li>
	<li><b>sysID</b> : the system ID string</li>
	</ul>
	End Rem
	Function defaultResolve:String(pubID:String, sysID:String)
		Assert pubID, XML_ERROR_PARAM
		Assert sysID, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(pubID).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(sysID).toCString()

		Local s:Byte Ptr = xmlCatalogResolve(cStr1, cStr2)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Function

	Rem
	bbdoc: Try to lookup the catalog reference associated to a public ID.
	returns: The resource if found or Null otherwise.
	about: Parameters:
	<ul>
	<li><b>pubID</b> : the public ID string</li>
	</ul>
	End Rem
	Function defaultResolvePublic:String(pubID:String)
		Assert pubID, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(pubID).toCString()

		Local s:Byte Ptr = xmlCatalogResolvePublic(cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Try to lookup the catalog resource for a system ID.
	returns: The resource if found or Null otherwise.
	about: Parameters:
	<ul>
	<li><b>sysID</b> : the system ID string</li>
	</ul>
	End Rem
	Function defaultResolveSystem:String(sysID:String)
		Assert sysID, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(sysID).toCString()

		Local s:Byte Ptr = xmlCatalogResolveSystem(cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Do a complete resolution lookup of an URI.
	returns: The URI of the resource or Null if not found.
	about: Parameters:
	<ul>
	<li><b>uri</b> : the URI</li>
	</ul>
	End Rem
	Function defaultResolveURI:String(uri:String)
		Assert uri, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()

		Local s:Byte Ptr = xmlCatalogResolveURI(cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Add an entry in the catalog, it may overwrite existing but different entries.
	returns: 0 if successful, -1 otherwise.
	about: Parameters:
	<ul>
	<li><b>rtype</b> : the type of record to add to the catalog</li>
	<li><b>orig</b> : the system, public or prefix to match</li>
	<li><b>rep</b> : the replacement value for the match</li>
	</ul>
	End Rem
	Method add:Int(rtype:String, orig:String, rep:String)
		Assert rtype, XML_ERROR_PARAM
		Assert orig, XML_ERROR_PARAM
		Assert rep, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(rtype).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(orig).toCString()
		Local cStr3:Byte Ptr = _xmlConvertMaxToUTF8(rep).toCString()

		Local ret:Int = xmlACatalogAdd(_xmlCatalogPtr, cStr1, cStr2, cStr3)

		MemFree(cStr1)
		MemFree(cStr2)
		MemFree(cStr3)

		Return ret
	End Method

	Rem
	bbdoc: Remove an entry from the catalog.
	returns: The number of entries removed if successful, -1 otherwise.
	about: Parameters:
	<ul>
	<li><b>value</b> : the value to remove</li>
	</ul>
	End Rem
	Method remove:Int(value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local ret:Int = xmlACatalogRemove(_xmlCatalogPtr, cStr)
		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Do a complete resolution lookup of an External Identifier.
	returns: The URI of the resource or Null if not found.
	about: Parameters:
	<ul>
	<li><b>pubID</b> : the public ID string</li>
	<li><b>sysID</b> : the system ID string</li>
	</ul>
	End Rem
	Method resolve:String(pubID:String, sysID:String)
		Assert pubID, XML_ERROR_PARAM
		Assert sysID, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(pubID).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(sysID).toCString()

		Local s:Byte Ptr = xmlACatalogResolve(_xmlCatalogPtr, cStr1, cStr2)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr1)
		MemFree(cStr2)

		Return ret
	End Method

	Rem
	bbdoc: Try to lookup the catalog local reference associated to a public ID in that catalog.
	returns: The local resource if found or Null otherwise.
	about: Parameters:
	<ul>
	<li><b>pubID</b> : the public ID string</li>
	</ul>
	End Rem
	Method resolvePublic:String(pubID:String)
		Assert pubID, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(pubID).toCString()

		Local s:Byte Ptr = xmlACatalogResolvePublic(_xmlCatalogPtr, cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Try to lookup the catalog resource for a system ID.
	returns: The resource if found or Null otherwise.
	about: Parameters:
	<ul>
	<li><b>sysID</b> : the system ID string</li>
	</ul>
	End Rem
	Method resolveSystem:String(sysID:String)
		Assert sysID, XML_ERROR_PARAM

		Local ret:String = Null
		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(sysID).toCString()

		Local s:Byte Ptr = xmlACatalogResolveSystem(_xmlCatalogPtr, cStr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Check is a catalog is empty
	returns: 1 if the catalog is empty, 0 if not, and -1 in case of error.
	End Rem
	Method isEmpty:Int()
		Return xmlCatalogIsEmpty(_xmlCatalogPtr)
	End Method

	Rem
	bbdoc: Convert all the SGML catalog entries as XML ones.
	returns: The number of entries converted if successful, -1 otherwise.
	End Rem
	Method convertSGML:Int()
		Return xmlConvertSGMLCatalog(_xmlCatalogPtr)
	End Method

	Rem
	bbdoc: Dump the catalog to the given file.
	End Rem
	Method dump(file:Int)
		xmlACatalogDump(_xmlCatalogPtr, file)
	End Method

	Rem
	bbdoc: Free the memory allocated to a Catalog.
	End Rem
	Method free()
		xmlFreeCatalog(_xmlCatalogPtr)
	End Method
End Type

Rem
bbdoc: An XML XInclude context.
End Rem
Type TxmlXIncludeCtxt

	Field _xmlXIncludeCtxtPtr:Byte Ptr

	Function _create:TxmlXIncludeCtxt(_xmlXIncludeCtxtPtr:Byte Ptr)
		If _xmlXIncludeCtxtPtr <> Null Then
			Local this:TxmlXIncludeCtxt = New TxmlXIncludeCtxt
			this._xmlXIncludeCtxtPtr = _xmlXIncludeCtxtPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Creates a new XInclude context.
	returns: The new context.
	about: Parameters:
	<ul>
	<li><b>doc</b> : an XML Document</li>
	</ul>
	End Rem
	Function newContext:TxmlXIncludeCtxt(doc:TxmlDoc)
		Assert doc, XML_ERROR_PARAM

		Return TxmlXIncludeCtxt._create(xmlXIncludeNewContext(doc._xmlDocPtr))
	End Function

	Rem
	bbdoc: Implement the XInclude substitution for the given subtree reusing the informations and data coming from the given context.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	about: Parameters:
	<ul>
	<li><b>node</b> : a node in an XML document</li>
	</ul>
	End Rem
	Method processNode:Int(node:TxmlNode)
		Assert node, XML_ERROR_PARAM

		Return xmlXIncludeProcessNode(_xmlXIncludeCtxtPtr, node._xmlNodePtr)
	End Method

	Rem
	bbdoc: Set the flags used for further processing of XML resources.
	returns: 0 in case of success and -1 in case of error.
	about: Parameters:
	<ul>
	<li><b>flags</b> : a set of xml Parser Options used for parsing XML includes. (see #fromFile for details on available options)</li>
	</ul>
	End Rem
	Method setFlags:Int(flags:Int)
		Return xmlXIncludeSetFlags(_xmlXIncludeCtxtPtr, flags)
	End Method

	Rem
	bbdoc: Free the XInclude context
	End Rem
	Method free()
		xmlXIncludeFreeContext(_xmlXIncludeCtxtPtr)
	End Method
End Type

Rem
bbdoc: A URI
about: Provides some standards-savvy functions for URI handling.
End Rem
Type TxmlURI
	Const _scheme:Int = 0		' the URI scheme (byte ptr)
	Const _opaque:Int = 4		' opaque part (byte ptr)
	Const _authority:Int = 8	' the authority part (byte ptr)
	Const _server:Int = 12		' the server part (byte ptr)
	Const _user:Int = 16		' the user part (byte ptr)
	Const _port:Int = 20		' the port number (int)
	Const _path:Int = 24		' the path string (byte ptr)
	Const _query:Int = 28		' the query string (byte ptr)
	Const _fragment:Int = 32	' the fragment identifier (byte ptr)
	Const _cleanup:Int = 36	' parsing potentially unclean URI (int)

	Field _xmlURIPtr:Byte Ptr

	Function _create:TxmlURI(_xmlURIPtr:Byte Ptr)
		If _xmlURIPtr<> Null Then
			Local this:TxmlURI = New TxmlURI
			this._xmlURIPtr= _xmlURIPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Simply creates an empty TxmlURI.
	returns: The new structure or Null in case of error.
	End Rem
	Function createURI:TxmlURI()
		Return TxmlURI._create(xmlCreateURI())
	End Function

	Rem
	bbdoc: Parse a URI.
	returns: A newly built TxmlURI or Null in case of error.
	about:  URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]
	<p>Parameters:
	<ul>
	<li><b>uri</b> : the URI string to analyze</li>
	</ul>
	</p>
	End Rem
	Function parseURI:TxmlURI(uri:String)
		Assert uri, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
		Local u:TxmlURI = TxmlURI._create(xmlParseURI(cStr))

		MemFree(cStr)

		Return u
	End Function

	Rem
	bbdoc: Parse an URI but allows to keep intact the original fragments.
	returns: A newly built TxmlURI or Null in case of error.
	about: URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]
	<p>Parameters:
	<ul>
	<li><b>uri</b> : the URI string to analyze</li>
	<li><b>raw</b> : if 1 unescaping of URI pieces are disabled</li>
	</ul>
	</p>
	End Rem
	Function parseURIRaw:TxmlURI(uri:String, raw:Int)
		Assert uri, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
		Local u:TxmlURI = TxmlURI._create(xmlParseURIRaw(cStr, raw))

		MemFree(cStr)

		Return u
	End Function

	Rem
	bbdoc: Computes the final URI of the reference done by checking that the given URI is valid, and building the final URI using the base URI.
	returns: A new URI string or Null in case of error.
	about: This is processed according to section 5.2 of the RFC 2396 5.2. Resolving Relative References to
	Absolute Form
	<p>Parameters:
	<ul>
	<li><b>uri</b> : the URI instance found in the document</li>
	<li><b>base</b> : the base value</li>
	</ul>
	</p>
	End Rem
	Function buildURI:String(uri:String, base:String)
		Assert uri, XML_ERROR_PARAM
		Assert base, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
		Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(base).toCString()

		Local s:Byte Ptr = xmlBuildURI(cStr1, cStr2)
		Local ret:String = Null
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr1)
		MemFree(cStr2)
		Return ret
	End Function

	Rem
	bbdoc: Constructs a canonic path from the specified path.
	returns: A new canonic path, or a duplicate of the path parameter if the construction fails.
	about: Parameters:
	<ul>
	<li><b>path</b> : the resource locator in a filesystem notation</li>
	</ul>
	End Rem
	Function canonicPath:String(path:String)
		Assert path, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(path).toCString()
		Local s:Byte Ptr = xmlCanonicPath(cStr)
		Local ret:String = path
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		Return ret
	End Function

	Rem
	bbdoc: Applies the 5 normalization steps to a path string.
	returns: The normalized string.
	about: That is, RFC 2396 Section 5.2, steps 6.c through 6.g.
	<p>Parameters:
	<ul>
	<li><b>path</b> : the path string</li>
	</ul>
	</p>
	End Rem
	Function normalizeURIPath:String(path:String)
		Assert path, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(path).toCString()

		Local r:Int = xmlNormalizeURIPath(cStr)
		Local ret:String = _xmlConvertUTF8ToMax(cStr)
		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Escaping routine, does not do validity checks !
	returns: A copy of the string, but escaped.
	about: It will try to escape the chars needing this, but this is heuristic based it's impossible to be sure.
	<p>Parameters:
	<ul>
	<li><b>uri</b> : the string of the URI to escape</li>
	</ul>
	</p>
	End Rem
	Function URIEscape:String(uri:String)
		Assert uri, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
		Local s:Byte Ptr = xmlURIEscape(cStr)
		Local ret:String = Null
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If
		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: This routine escapes a string to hex, ignoring reserved characters (a-z) and the characters in the exception list.
	returns: A new escaped string or Null in case of error.
	about: Parameters:
	<ul>
	<li><b>uri</b> : the string to escape</li>
	<li><b>list</b> : exception list string of chars not to escape, if any</li>
	</ul>
	End Rem
	Function URIEscapeString:String(uri:String, list:String)
		Assert uri, XML_ERROR_PARAM

		Local cStr1:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()
		Local s:Byte Ptr
		If list <> Null Then
			Local cStr2:Byte Ptr = _xmlConvertMaxToUTF8(list).toCString()
			s = xmlURIEscapeStr(cStr1, cStr2)
			MemFree(cStr2)
		Else
			s = xmlURIEscapeStr(cStr1, Null)
		End If

		Local ret:String = Null
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If
		MemFree(cStr1)

		Return ret
	End Function

	Rem
	bbdoc: Unescaping routine.
	returns: A copy of the string, but unescaped.
	about: Does not do validity checks. Output is direct unsigned char translation of %XX values (no encoding)
	<p>Parameters:
	<ul>
	<li><b>str</b> : the string to unescape</li>
	</ul>
	</p>
	End Rem
	Function URIUnescapeString:String(str:String)
		Assert str, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(str).toCString()
		Local s:Byte Ptr = xmlURIUnescapeString(cStr, 0, Null)
		Local ret:String = Null
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		MemFree(cStr)
		Return ret
	End Function

	Rem
	bbdoc: Parse an URI reference string and fills in the appropriate fields of the URI structure.
	returns: 0 or the error code.
	about: URI-reference = [ absoluteURI | relativeURI ] [ "#" fragment ]
	<p>Parameters:
	<ul>
	<li><b>uri</b> : the string to analyze</li>
	</ul>
	</p>
	End Rem
	Method parseURIReference:Int(uri:String)
		Assert uri, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(uri).toCString()

		Local ret:Int = xmlParseURIReference(_xmlURIPtr, cStr)
		MemFree(cStr)

		Return ret
	End Method

	Rem
	bbdoc: Save the URI as an escaped string.
	returns: A new string.
	End Rem
	Method saveURI:String()
		Local ret:String

		Local s:Byte Ptr = xmlSaveUri(_xmlURIPtr)
		If s <> Null Then
			ret = _xmlConvertUTF8ToMax(s)
			xmlMemFree(s)
		End If

		Return ret
	End Method

	Rem
	bbdoc: Returns the URI scheme.
	End Rem
	Method getScheme:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _scheme)[0]))
	End Method

	Rem
	bbdoc: Returns the opaque part.
	End Rem
	Method getOpaque:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _opaque)[0]))
	End Method

	Rem
	bbdoc: Returns the authority part.
	End Rem
	Method getAuthority:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _authority)[0]))
	End Method

	Rem
	bbdoc: Returns the server part.
	End Rem
	Method getServer:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _server)[0]))
	End Method

	Rem
	bbdoc: Returns the user part.
	End Rem
	Method getUser:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _user)[0]))
	End Method

	Rem
	bbdoc: Returns the port number.
	End Rem
	Method getPort:Int()
		Return Int Ptr(_xmlURIPtr + _port)[0]
	End Method

	Rem
	bbdoc: Returns the path string.
	End Rem
	Method getPath:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _path)[0]))
	End Method

	Rem
	bbdoc: Returns the query string.
	End Rem
	Method getQuery:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _query)[0]))
	End Method

	Rem
	bbdoc: Returns the fragment identifier.
	End Rem
	Method getFragment:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlURIPtr + _fragment)[0]))
	End Method

	Rem
	bbdoc: Free up the TxmlURI object.
	End Rem
	Method free()
		xmlFreeURI(_xmlURIPtr)
	End Method

End Type

Rem
bbdoc: An XML Location Set.
End Rem
Type TxmlLocationSet
	Const _locNr:Int = 0		' number of locations in the set (Int)
	Const _locMax:Int = 4		' size of the array as allocated (Int)
	Const _locTab:Int = 8		' array of locations (Byte Ptr)

	Field _xmlLocationSetPtr:Byte Ptr

	Function _create:TxmlLocationSet(_xmlLocationSetPtr:Byte Ptr)
		If _xmlLocationSetPtr <> Null Then
			Local this:TxmlLocationSet = New TxmlLocationSet
			this._xmlLocationSetPtr = _xmlLocationSetPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Create a new xmlLocationSetPtr of type double
	returns: The newly created object.
	End Rem
	Function Create:TxmlLocationSet()
		Return TxmlLocationSet._create(xmlXPtrLocationSetCreate(Null))
	End Function

	Rem
	bbdoc: Add a new TxmlXPathObject to an existing LocationSet.
	about: If the location already exist in the set @value is freed.
	<p>Parameters:
	<ul>
	<li><b>value</b> : a new TxmlXPathObject</li>
	</ul>
	</p>
	End Rem
	Method add(value:TxmlXPathObject)
		Assert value, XML_ERROR_PARAM

		xmlXPtrLocationSetAdd(_xmlLocationSetPtr, value._xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Removes a TxmlXPathObject from the LocationSet.
	End Rem
	Method del(value:TxmlXPathObject)
		Assert value, XML_ERROR_PARAM

		xmlXPtrLocationSetDel(_xmlLocationSetPtr, value._xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Merges two rangesets.
	returns: This set once extended or Null in case of error.
	about: All ranges from @value are added to this set.
	<p>Parameters:
	<ul>
	<li><b>value</b> : a location set to merge</li>
	</ul>
	</p>
	End Rem
	Method merge:TxmlLocationSet(value:TxmlLocationSet)
		Assert value, XML_ERROR_PARAM

		Return TxmlLocationSet._create(xmlXPtrLocationSetMerge(_xmlLocationSetPtr, value._xmlLocationSetPtr))
	End Method

	Rem
	bbdoc: Removes an entry from an existing LocationSet list.
	about: Parameters:
	<ul>
	<li><b>index</b> : the index to remove</li>
	</ul>
	End Rem
	Method remove(index:Int)
		xmlXPtrLocationSetRemove(_xmlLocationSetPtr, index)
	End Method

	Rem
	bbdoc: Free the LocationSet compound (not the actual ranges !).
	End Rem
	Method free()
		xmlXPtrFreeLocationSet(_xmlLocationSetPtr)
	End Method

End Type

Rem
bbdoc: An XML Attribute Decl.
End Rem
Type TxmlDtdAttribute Extends TxmlBase

	' offsets from the pointer
	Const _nexth:Int = 36		'	 next in hash table (byte ptr)
	Const _atype:Int = 40		' The attribute type (int)
	Const _def:Int = 44			' the default (int)
	Const _defaultValue:Int = 48	' or the default value (byte ptr)
	Const _tree:Int = 52			' or the enumeration tree if any (byte ptr)
	Const _prefix:Int = 56		' the namespace prefix if any (byte ptr)
	Const _elem:Int = 60			' Element holding the attribute (byte ptr)

	' reference to the actual attribute
	Field _xmlDtdAttributePtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlDtdAttribute(_xmlDtdAttributePtr:Byte Ptr)
		If _xmlDtdAttributePtr <> Null Then
			Local this:TxmlDtdAttribute = New TxmlDtdAttribute

			this._xmlDtdAttributePtr = _xmlDtdAttributePtr
			this.initBase(_xmlDtdAttributePtr)

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the attribute default value
	End Rem
	Method getDefaultValue:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDtdAttributePtr + _defaultValue)[0]))
	End Method

End Type

Rem
bbdoc: An XML Element.
End Rem
Type TxmlDtdElement Extends TxmlBase

	' offsets from the pointer
	'Const _type:Int = 4		' Type number, (int)
	'Const _name:Int = 8		' the name of the node, Or the entity (byte ptr)
	'Const _value:Int = 12		' the value of the property (byte ptr)
	'Const _last:Int = 16		' last child link (byte ptr)
	'Const _parent:Int = 20		' child->parent link (byte ptr)
	'Const _next:Int = 24		' Next sibling link (byte ptr)
	'Const _prev:Int = 28		' previous sibling link (byte ptr)
	'Const _doc:Int = 32		' the containing document (byte ptr)
	Const _etype:Int = 36	' The type (int)
	Const _content:Int = 36	' the allowed element content (byte ptr)
	Const _attributes:Int = 36	' List of the declared attributes (byte ptr)
	Const _prefix:Int = 36	' the namespace prefix if any (byte ptr)
	Const _contModel:Int = 36	' the validating regexp (byte ptr)
	'Const _contModel		' (byte ptr)

	' reference to the actual element
	Field _xmlDtdElementPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlDtdElement(_xmlDtdElementPtr:Byte Ptr)
		If _xmlDtdElementPtr <> Null Then
			Local this:TxmlDtdElement = New TxmlDtdElement

			this._xmlDtdElementPtr = _xmlDtdElementPtr
			this.initBase(_xmlDtdElementPtr)

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the element type.
	about: The following lists possible element types:<br>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ELEMENT_TYPE_UNDEFINED</td></tr>
	<tr><td>XML_ELEMENT_TYPE_EMPTY</td></tr>
	<tr><td>XML_ELEMENT_TYPE_ANY</td></tr>
	<tr><td>XML_ELEMENT_TYPE_MIXED</td></tr>
	<tr><td>XML_ELEMENT_TYPE_ELEMENT</td></tr>
	</table>
	End Rem
	Method getElementType:Int()
		Return Int Ptr(_xmlDtdElementPtr + _etype)[0]
	End Method

	Rem
	bbdoc: Returns the namespace prefix, if any.
	End Rem
	Method getPrefix:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlDtdElementPtr + _prefix)[0]))
	End Method

End Type

Rem
bbdoc:  An XML Notation.
End Rem
Type TxmlNotation
	' offsets from the pointer
	Const _name:Int = 0		' Notation name (byte ptr)
	Const _PublicID:Int = 4	' Public identifier, if any (byte ptr)
	Const _SystemID:Int = 8	' System identifier, if any (byte ptr)

	' reference to the actual element
	Field _xmlNotationPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlNotation(_xmlNotationPtr:Byte Ptr)
		If _xmlNotationPtr <> Null Then
			Local this:TxmlNotation = New TxmlNotation

			this._xmlNotationPtr = _xmlNotationPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the notation name.
	End Rem
	Method getName:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlNotationPtr + _name)[0]))
	End Method

	Rem
	bbdoc: Returns the public identifier, if any.
	End Rem
	Method getPublicID:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlNotationPtr + _PublicID)[0]))
	End Method

	Rem
	bbdoc: Returns the system identifier, if any.
	End Rem
	Method getSystemID:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlNotationPtr + _SystemID)[0]))
	End Method

End Type

Rem
bbdoc: XML validation context.
End Rem
Type TxmlValidCtxt

	Const _error:Int = 4		' the callback in case of errors (byte ptr)
	Const _warning:Int = 8	' the callback in case of warning Node an (byte ptr)
	Const _node:Int = 12		' Current parsed Node (byte ptr)
	Const _nodeNr:Int = 16	' Depth of the parsing stack (int)
	Const _nodeMax:Int = 20	' Max depth of the parsing stack (int)
	Const _nodeTab:Int = 24	' array of nodes (byte ptr)
	Const _finishDtd:Int = 28	' finished validating the Dtd ? (int)
	Const _doc:Int = 32		' the document (byte ptr)
	Const _valid:Int = 36	' temporary validity check result state s (int)
	Const _vstate:Int = 40	' current state (byte ptr)
	Const _vstateNr:Int = 44	' Depth of the validation stack (int)
	Const _vstateMax:Int = 48	' Max depth of the validation stack (int)
	Const _vstateTab:Int = 52	' array of validation states (byte ptr)
	Const _am:Int = 56		' the automata (byte ptr)
	Const _state:Int = 60	' used to build the automata (byte ptr)

	' reference to the actual element
	Field _xmlValidCtxtPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlValidCtxt(_xmlValidCtxtPtr:Byte Ptr)
		If _xmlValidCtxtPtr <> Null Then
			Local this:TxmlValidCtxt = New TxmlValidCtxt

			this._xmlValidCtxtPtr = _xmlValidCtxtPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Validate that the given attribute value match the proper production.
	returns: 1 if valid or 0 otherwise.
	about: [ VC: ID ] Values of type ID must match the Name production....<br>
	[ VC: IDREF ] Values of type IDREF must match the Name production, and values of type IDREFS must match Names ...<br>
	[ VC: Entity Name ] Values of type ENTITY must match the Name production, values of type ENTITIES must match Names ...<br>
	[ VC: Name Token ] Values of type NMTOKEN must match the Nmtoken production; values of type NMTOKENS must match Nmtokens.
	<p>Parameters:
	<ul>
	<li><b>attributeType</b> : an attribute type (see below)</li>
	<li><b>value</b> : an attribute value</li>
	</ul>
	</p>
	<p>The following lists possible attribute types:</p>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ATTRIBUTE_CDATA</td></tr>
	<tr><td>XML_ATTRIBUTE_ID</td></tr>
	<tr><td>XML_ATTRIBUTE_IDREF</td></tr>
	<tr><td>XML_ATTRIBUTE_IDREFS</td></tr>
	<tr><td>XML_ATTRIBUTE_ENTITY</td></tr>
	<tr><td>XML_ATTRIBUTE_ENTITIES</td></tr>
	<tr><td>XML_ATTRIBUTE_NMTOKEN</td></tr>
	<tr><td>XML_ATTRIBUTE_NMTOKENS</td></tr>
	<tr><td>XML_ATTRIBUTE_ENUMERATION</td></tr>
	<tr><td>XML_ATTRIBUTE_NOTATION</td></tr>
	</table>
	End Rem
	Function validateAttributeValue:Int(attributeType:Int, value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()

		Local ret:Int = xmlValidateAttributeValue(attributeType, cStr)

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Allocate a validation context structure.
	returns: Null if not, otherwise the new validation context structure.
	End Rem
	Function newValidCtxt:TxmlValidCtxt()
		Return _create(xmlNewValidCtxt())
	End Function

	Rem
	bbdoc: Validate that the given value match Name production.
	returns: 1 if valid or 0 otherwise.
	about: Parameters:
	<ul>
	<li><b>value</b> : an Name value</li>
	</ul>
	End Rem
	Function validateNameValue:Int(value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local ret:Int = xmlValidateNameValue(cStr)

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Validate that the given value match Names production.
	returns: 1 if valid or 0 otherwise.
	about: Parameters:
	<ul>
	<li><b>value</b> : a Names value</li>
	</ul>
	End Rem
	Function validateNamesValue:Int(value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local ret:Int = xmlValidateNamesValue(cStr)

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Validate that the given value match Nmtoken production.
	returns: 1 if valid or 0 otherwise.
	about: [ VC: Name Token ]
	<p>Parameters:
	<ul>
	<li><b>value</b> : an Nmtoken value</li>
	</ul>
	</p>
	End Rem
	Function validateNmtokenValue:Int(value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local ret:Int = xmlValidateNmtokenValue(cStr)

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Validate that the given value match Nmtokens production.
	returns: 1 if valid or 0 otherwise.
	about: [ VC: Name Token ]
	<p>Parameters:
	<ul>
	<li><b>value</b> : an Nmtokens value</li>
	</ul>
	</p>
	End Rem
	Function validateNmtokensValue:Int(value:String)
		Assert value, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(value).toCString()
		Local ret:Int = xmlValidateNmtokensValue(cStr)

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Returns the temporary validity check result state.
	End Rem
	Method isValid:Int()
		Return Int Ptr(_xmlValidCtxtPtr + _valid)[0]
	End Method

	Rem
	bbdoc: Returns true if finished validating the DTD.
	End Rem
	Method isFinishedDtd:Int()
		Return Int Ptr(_xmlValidCtxtPtr + _finishDtd)[0]
	End Method

	Rem
	bbdoc: Returns the document for this object.
	End Rem
	Method getDocument:TxmlDoc()
		Return TxmlDoc._create(Byte Ptr(Int Ptr(_xmlValidCtxtPtr + _doc)[0]))
	End Method

	Rem
	bbdoc: Try to validate the document instance.
	returns: 1 if valid or 0 otherwise.
	about : Basically it does the all the checks described by the XML Rec i.e. validates the
	internal and external subset (if present) and validate the document tree.
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	</ul>
	</p>
	End Rem
	Method validateDocument:Int(doc:TxmlDoc)
		Assert doc, XML_ERROR_PARAM

		Return xmlValidateDocument(_xmlValidCtxtPtr, doc._xmlDocPtr)
	End Method

	Rem
	bbdoc: Does the final step for the document validation once all the incremental validation steps have been completed.
	returns: 1 if valid or 0 otherwise
	about: Basically it does the following checks described by the XML Rec. Check all the IDREF/IDREFS
	attributes definition for validity.
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	</ul>
	</p>
	End Rem
	Method validateDocumentFinal:Int(doc:TxmlDoc)
		Assert doc, XML_ERROR_PARAM

		Return xmlValidateDocumentFinal(_xmlValidCtxtPtr, doc._xmlDocPtr)
	End Method

	Rem
	bbdoc: Try to validate the document against the dtd instance.
	returns: 1 if valid or 0 otherwise.
	about: Basically it does check all the definitions in the DtD. Note the the internal subset
	(if present) is de-coupled (i.e. not used), which could give problems if ID or IDREF is present.
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	<li><b>dtd</b> : a DTD instance</li>
	</ul>
	</p>
	End Rem
	Method validateDtd:Int(doc:TxmlDoc, dtd:TxmlDtd)
		Assert doc, XML_ERROR_PARAM
		Assert dtd, XML_ERROR_PARAM

		Return xmlValidateDtd(_xmlValidCtxtPtr, doc._xmlDocPtr, dtd._xmlDtdPtr)
	End Method

	Rem
	bbdoc: Does the final step for the dtds validation once all the subsets have been parsed.
	returns: 1 if valid or 0 if invalid and -1 if not well-formed.
	about: Basically it does the following checks described by the XML Rec<br>
	Check that ENTITY and ENTITIES type attributes default or possible values matches one of the
	defined entities.<br>
	Check that NOTATION type attributes default or possible values matches one of the defined notations.
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	</ul>
	</p>
	End Rem
	Method validateDtdFinal:Int(doc:TxmlDoc, dtd:TxmlDtd)
		Assert doc, XML_ERROR_PARAM

		Return xmlValidateDtdFinal(_xmlValidCtxtPtr, doc._xmlDocPtr)
	End Method

	Rem
	bbdoc: Try to validate a the root element.
	returns: 1 if valid or 0 otherwise.
	about: Basically it does the following check as described by the XML-1.0 recommendation:<br>
	[ VC: Root Element Type ] it doesn't try to recurse or apply other check to the element
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	</ul>
	</p>
	End Rem
	Method validateRoot:Int(doc:TxmlDoc)
		Assert doc, XML_ERROR_PARAM

		Return xmlValidateRoot(_xmlValidCtxtPtr, doc._xmlDocPtr)
	End Method

	Rem
	bbdoc: Try to validate the subtree under an element.
	returns: 1 if valid or 0 otherwise.
	about: Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	<li><b>elem</b> : an element instance</li>
	</ul>
	End Rem
	Method validateElement:Int(doc:TxmlDoc, elem:TxmlNode)
		Assert doc, XML_ERROR_PARAM
		Assert elem, XML_ERROR_PARAM

		Return xmlValidateElement(_xmlValidCtxtPtr, doc._xmlDocPtr, elem._xmlNodePtr)
	End Method

	Rem
	bbdoc: Try to validate a single element definition.
	about: Basically it does the following checks as described by the XML-1.0 recommendation:<br>
	[ VC: One ID per Element Type ]<br>
	[ VC: No Duplicate Types ]<br>
	[ VC: Unique Element Type Declaration ]
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	<li><b>elem</b> : an element definition</li>
	</ul>
	</p>
	End Rem
	Method validateElementDecl:Int(doc:TxmlDoc, elem:TxmlDtdElement)
		Assert doc, XML_ERROR_PARAM
		Assert elem, XML_ERROR_PARAM

		Return xmlValidateElementDecl(_xmlValidCtxtPtr, doc._xmlDocPtr, elem._xmlDtdElementPtr)
	End Method

	Rem
	bbdoc: Try to validate a single attribute definition.
	returns: 1 if valid or 0 otherwise.
	about: Basically it does the following checks as described by the XML-1.0 recommendation:<br>
	[ VC: Attribute Default Legal ]<br>
	[ VC: Enumeration ]<br>
	[ VC: ID Attribute Default ]<br>
	The ID/IDREF uniqueness and matching are done separately.
	<p>Parameters:
	<ul>
	<li><b>doc</b> : a document instance</li>
	<li><b>attr</b> : an attribute definition</li>
	</ul>
	</p>
	End Rem
	Method validateAttributeDecl:Int(doc:TxmlDoc, attr:TxmlDtdAttribute)
		Assert doc, XML_ERROR_PARAM
		Assert attr, XML_ERROR_PARAM

		Return xmlValidateAttributeDecl(_xmlValidCtxtPtr, doc._xmlDocPtr, attr._xmlDtdAttributePtr)
	End Method

	Rem
	bbdoc: (Re)Build the automata associated to the content model of the element.
	returns: 1 in case of success, 0 in case of error.
	about: Parameters:
	<ul>
	<li><b>elem</b> : an element declaration node</li>
	</ul>
	End Rem
	Method buildContentModel:Int(elem:TxmlDtdElement)
		Assert elem, XML_ERROR_PARAM

		Return xmlValidBuildContentModel(_xmlValidCtxtPtr, elem._xmlDtdElementPtr)
	End Method

	Rem
	bbdoc: Free the validation context structure.
	End Rem
	Method free()
		xmlFreeValidCtxt(_xmlValidCtxtPtr)
	End Method

End Type

Rem
bbdoc: An XML element content tree.
End Rem
Type TxmlElementContent

	Const _type:Int = 0		' PCDATA, ELEMENT, SEQ or OR (int)
	Const _ocur:Int = 4		' ONCE, OPT, MULT or PLUS (int)
	Const _name:Int = 8		' Element name (byte ptr)
	Const _c1:Int = 12		' first child (byte ptr)
	Const _c2:Int = 16		' second child (byte ptr)
	Const _parent:Int = 20	' parent (byte ptr)
	Const _prefix:Int = 24	' Namespace prefix (byte ptr)

	' reference to the actual element
	Field _xmlElementContentPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlElementContent(_xmlElementContentPtr:Byte Ptr)
		If _xmlElementContentPtr <> Null Then
			Local this:TxmlElementContent = New TxmlElementContent

			this._xmlElementContentPtr = _xmlElementContentPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the content type.
	about: The following lists the possible content types:</p>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ELEMENT_CONTENT_PCDATA</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_ELEMENT</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_SEQ</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_OR</td></tr>
	</table>
	End Rem
	Method getType:Int()
		Return Int Ptr(_xmlElementContentPtr + _type)[0]
	End Method

	Rem
	bbdoc: Returns the content occurance.
	about: The following lists the possible content occurances:<br>
	<table>
	<tr><th>Constant</th></tr>
	<tr><td>XML_ELEMENT_CONTENT_ONCE</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_OPT</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_MULT</td></tr>
	<tr><td>XML_ELEMENT_CONTENT_PLUS</td></tr>
	</table>
	End Rem
	Method getOccur:Int()
		Return Int Ptr(_xmlElementContentPtr + _ocur)[0]
	End Method

	Rem
	bbdoc: Returns the element name.
	End Rem
	Method getName:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlElementContentPtr + _name)[0]))
	End Method

	Rem
	bbdoc: Returns the namespace prefix.
	End Rem
	Method getPrefix:String()
		Return _xmlConvertUTF8ToMax(Byte Ptr(Int Ptr(_xmlElementContentPtr + _prefix)[0]))
	End Method

End Type

Rem
bbdoc: A compiled XPath expression.
End Rem
Type TxmlXPathCompExpr

	' reference to the actual compiled expression
	Field _xmlXPathCompExprPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlXPathCompExpr(_xmlXPathCompExprPtr:Byte Ptr)
		If _xmlXPathCompExprPtr <> Null Then
			Local this:TxmlXPathCompExpr = New TxmlXPathCompExpr

			this._xmlXPathCompExprPtr = _xmlXPathCompExprPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Compile an XPath expression.
	returns: The TxmlXPathCompExpr resulting from the compilation or Null.
	about: Parameters:
	<ul>
	<li><b>expr</b> : the XPath expression</li>
	</ul>
	End Rem
	Function Compile:TxmlXPathCompExpr(expr:String)
		Assert expr, XML_ERROR_PARAM

		Local cStr:Byte Ptr = _xmlConvertMaxToUTF8(expr).toCString()
		Local ret:TxmlXPathCompExpr = TxmlXPathCompExpr._create(xmlXPathCompile(cStr))

		MemFree(cStr)

		Return ret
	End Function

	Rem
	bbdoc: Evaluate the precompiled XPath expression in the given context.
	returns: The TxmlXPathObject resulting from the evaluation or Null.
	about: Parameters:
	<ul>
	<li><b>context</b> : the XPath context</li>
	</ul>
	End Rem
	Method eval:TxmlXPathObject(context:TxmlXPathContext)
		Assert context, XML_ERROR_PARAM

		Return TxmlXPathObject._create(xmlXPathCompiledEval(_xmlXPathCompExprPtr, context._xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Free up the allocated memory.
	End Rem
	Method free()
		xmlXPathFreeCompExpr(_xmlXPathCompExprPtr)
	End Method

End Type

