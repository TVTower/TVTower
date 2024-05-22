' MODIFICATION:
' author: Ronny Otto
' changes: - Removed "Module"-part so it could be used with
'            import "libxml.bmx"
'          - disabled
'              ModuleInfo "CC_OPTS: -DIN_LIBXML"
'            replaced similar code in "glue.cpp"

'
' Copyright (c) 2006-2012 Bruce A Henderson
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
End Rem
Rem
Module BaH.LibXml

ModuleInfo "Version: 2.01"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: (libxml2) 1998-2012 Daniel Veillard"
ModuleInfo "Copyright: (wrapper) 2006-2012 Bruce A Henderson"
ModuleInfo "Modserver: BRL"

ModuleInfo "History: 2.01"
ModuleInfo "History: Fixed incorrect filename in include."
ModuleInfo "History: Re-added TxmlDoc SetEncoding() method."
ModuleInfo "History: 2.00"
ModuleInfo "History: Updated to Libxml 2.9.0."
ModuleInfo "History: Complete rewrite of API glue to match standard module layout."
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

?win32
ModuleInfo "CC_OPTS: -DIN_LIBXML"
?
EndRem

Import "common.bmx"

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
	Return TxmlError._create(bmx_libxml_xmlGetLastError())
End Function

Rem
bbdoc: Sets the callback handler For errors.
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
	Return bmx_libxml_xmlSubstituteEntitiesDefault(value)
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

	Return TxmlEntity._create(bmx_libxml_xmlGetPredefinedEntity(name))
End Function

' converts a UTF character array from byte-size characters to short-size characters
' based on the TextStream UTF code...
Rem
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
End Rem
' converts a Max short-based String to a byte-based UTF-8 String.
' based on the TextStream UTF code...
Rem
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
End Rem
'Function UTF8Toisolat1:String(utf8Text:String)
'	Local inlen:Int = utf8Text.length
'	Local out:Byte Ptr = "".toCString()
'	Local outlen:Int = 0
'	Local ret:Int = _UTF8Toisolat1(out, outlen , utf8Text.toCString(), inlen)
'
'	Return String.fromCString(out)
'End Function

Rem
bbdoc: The base Type for #TxmlDoc, #TxmlNode, #TxmlAttribute, #TxmlEntity, #TxmlDtd, #TxmlDtdElement and #TxmlDtdAttribute.
End Rem
Type TxmlBase Abstract
	'Const _type:Int = 4			' XML_DOCUMENT_NODE, (int)
	'Const _name:Int = 8			' name/filename/URI of the document (Byte Ptr)
	'Const _children:Int = 12		' the document tree (byte ptr)
	'Const _last:Int = 16			' last child link (byte ptr)
	'Const _parent:Int = 20		' child->parent link (byte ptr)
	'Const _next:Int = 24			' Next sibling link (byte ptr)
	'Const _prev:Int = 28			' previous sibling link (byte ptr)
	'Const _doc:Int = 32			' autoreference To itself (byte ptr)

	Field basePtr:Byte Ptr

	Function chooseCreateFromType:TxmlBase(_ptr:Byte Ptr)
		If _ptr <> Null Then
			Select bmx_libxml_xmlbase_getType(_ptr)
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
		Return bmx_libxml_xmlbase_getType(basePtr)
	End Method

	Rem
	bbdoc: Returns the node name
	End Rem
	Method getName:String()
		Return bmx_libxml_xmlbase_getName(basePtr)
	End Method

	Rem
	bbdoc: Returns the document for this object.
	End Rem
	Method getDocument:TxmlDoc()
		Return TxmlDoc._create(bmx_libxml_xmlbase_getDoc(basePtr))
	End Method


	Rem
	bbdoc: Get the next sibling node
	returns: The next node or Null if there are none.
	End Rem
	Method nextSibling:TxmlBase()
		Return chooseCreateFromType(bmx_libxml_xmlbase_next(basePtr))
	End Method

	Rem
	bbdoc: Get the previous sibling node
	returns: The previous node or Null if there are none.
	End Rem
	Method previousSibling:TxmlBase()
		Return chooseCreateFromType(bmx_libxml_xmlbase_prev(basePtr))
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
		Local children:TList
		Local node:TxmlBase = chooseCreateFromType(bmx_libxml_xmlbase_children(basePtr))

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
			Return chooseCreateFromType(bmx_libxml_xmlGetLastChild(basePtr))
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
			Return chooseCreateFromType(bmx_libxml_xmlbase_children(basePtr))
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
		Return chooseCreateFromType(bmx_libxml_xmlbase_parent(basePtr))
	End Method

	Rem
	bbdoc: Get the line number of the element.
	returns: The line number if successful, or -1 otherwise.
	End Rem
	Method getLineNumber:Int()

		Return bmx_libxml_xmlGetLineNo(basePtr)

	End Method

End Type

Rem
bbdoc: An XML Document
End Rem
Type TxmlDoc Extends TxmlBase

	Field _readStream:TStream

	Rem
	bbdoc: Creates a new XML document.
	about: Parameters:
	<ul>
	<li><b>version</b> : string giving the version of XML "1.0".</li>
	</ul>
	End Rem
	Function newDoc:TxmlDoc(version:String)
		Assert Version, XML_ERROR_PARAM

		Local doc:TxmlDoc = TxmlDoc._create(bmx_libxml_xmlNewDoc(version))
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
			Return TxmlDoc._create(bmx_libxml_xmlParseFile(filename))
		Else
			Local proto:String = filename[..i].ToLower()
			Local path:String = filename[i+2..]

			If proto = "incbin" Then
				Local buf:Byte Ptr = IncbinPtr( path )
				If Not buf Then
					Return Null
				End If
				Local size:Int = IncbinLen( path )

				Return TxmlDoc._create(bmx_libxml_xmlParseMemory(buf, size))
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

		Return TxmlDoc._create(bmx_libxml_xmlParseDoc(text))
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
			Return TxmlDoc._create(bmx_libxml_xmlReadFile(filename, encoding, options))
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

			Return TxmlDoc._create(bmx_libxml_xmlReadDoc(text, url, encoding, options))

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

			Local basePtr:Byte Ptr

			If cStr1 Then
				If cStr2 Then
					basePtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, cStr1, cStr2, options)
				Else
					basePtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, cStr1, Null, options)
				End If
			Else
				If cStr2 Then
					basePtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, Null, cStr2, options)
				Else
					basePtr = xmlReadIO(_xmlInputReadCallback, _xmlInputCloseCallback, tempDoc, Null, Null, options)
				End If
			End If

			If cStr1 Then
				MemFree cStr1
			End If
			If cStr2 Then
				MemFree cStr2
			End If

			If basePtr = Null Then
				Return Null
			Else
				Return TxmlDoc._create(basePtr)
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

		Return TxmlDoc._create(bmx_libxml_xmlParseCatalogFile(filename))
	End Function

	' private - non API function
	Function _create:TxmlDoc(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlDoc = New TxmlDoc

			this.basePtr = basePtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: The document URI.
	End Rem
	Method getURL:String()
		Return bmx_libxml_xmldoc_url(basePtr)
	End Method

	Rem
	bbdoc: Returns the root element of the document
	End Rem
	Method getRootElement:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlDocGetRootElement(basePtr))
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
		Return TxmlNode._create(bmx_libxml_xmlDocSetRootElement(basePtr, root.basePtr))
	End Method

	Rem
	bbdoc: Free up all the structures used by a document, tree included.
	End Rem
	Method free()
		bmx_libxml_xmlFreeDoc(basePtr)
	End Method

	Rem
	bbdoc: The XML version string.
	End Rem
	Method getVersion:String()
		Return bmx_libxml_xmldoc_version(basePtr)
	End Method

	Rem
	bbdoc: The external initial encoding, if any.
	End Rem
	Method getEncoding:String()
		Return bmx_libxml_xmldoc_encoding(basePtr)
	End Method

	Rem

	bbdoc: Sets the document encoding.

	End Rem

	Method setEncoding(encoding:String)
		bmx_libxml_xmldoc_setencoding(basePtr, encoding)

	End Method


	Rem
	bbdoc: Is this document standalone?
	returns: True if the document has no external refs.
	End Rem
	Method isStandalone:Int()
		Return bmx_libxml_xmldoc_standalone(basePtr)
	End Method

	Rem
	bbdoc: Sets document to standalone (or not).
	End Rem
	Method setStandalone(value:Int)
		bmx_libxml_xmldoc_setStandalone(basePtr, value)
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

		Return TxmlNode._create(bmx_libxml_xmlNewDocPI(basePtr, name, content))
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

		Return TxmlAttribute._create(bmx_libxml_xmlNewDocProp(basePtr, name, value))
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
		bmx_libxml_xmlSetDocCompressMode(basePtr, Mode)
	End Method

	Rem
	bbdoc: Get the compression ratio for a document.
	returns: 0 (uncompressed) to 9 (max compression)
	End Rem
	Method getCompressMode:Int()
		Return bmx_libxml_xmlGetDocCompressMode(basePtr)
	End Method

	Rem
	bbdoc: Dump an XML document to a file.
	returns: the number of bytes written or -1 in case of failure.
	about: Will use compression if set. If @filename is "-" the standard out (console) is used.
	<p>Parameters:
	<ul>
	<li><b>file</b> : either the filename or URL (String), or stream (TStream).</li>
	<li><b>autoClose</b> : for streams only. When True, will automatically Close the stream. (default)</li>
	<li><b>encoding</b> : the name of an encoding, or Null.</li>
	</ul>
	</p>
	End Rem
	Method saveFile:Int(file:Object, autoClose:Int = True, encoding:String = Null)
		Assert file, XML_ERROR_PARAM
		Local ret:Int

		If String(file) Then
			Local filename:String = String(file)

?win32
			filename = filename.Replace("/","\") ' compression requires Windows backslashes
?

			ret = bmx_libxml_xmlSaveFile(filename, basePtr, encoding)

		Else If TStream(file) Then
			Local stream:TStream = TStream(file)

			TxmlOutputStreamHandler.stream = stream
			TxmlOutputStreamHandler.autoClose = autoClose

			Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createIO()
			ret = bmx_libxml_xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, basePtr, encoding, True)
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
	<li><b>encoding</b> : the encoding, if any.</li>
	<li><b>autoClose</b> : for streams only. When True, will automatically Close the stream. (default)</li>
	</ul>
	</p>
	End Rem
	Method saveFormatFile:Int(file:Object, format:Int, encoding:String = Null, autoClose:Int = True)
		Assert file, XML_ERROR_PARAM
		Local ret:Int

		If String(file) Then
			Local filename:String = String(file)

?win32
			filename = filename.Replace("/","\") ' compression requires Windows backslashes
?

			ret = bmx_libxml_xmlSaveFormatFile(filename, basePtr, encoding, format)

		Else If TStream(file) Then
			Local stream:TStream = TStream(file)

			TxmlOutputStreamHandler.stream = stream
			TxmlOutputStreamHandler.autoClose = autoClose

			Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createIO()
			ret = bmx_libxml_xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, basePtr, encoding, format)
		End If

		Return ret
	End Method

	Rem
	bbdoc: Returns a String representation of the document.
	End Rem
	Method ToString:String()
		Local buffer:TxmlBuffer = TxmlBuffer.newBuffer()
		Local outputBuffer:TxmlOutputBuffer = TxmlOutputBuffer.createBuffer(buffer)
		bmx_libxml_xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, basePtr, Null, True)
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
		bmx_libxml_xmlSaveFormatFileTo(outputBuffer._xmlOutputBufferPtr, basePtr, Null, format)
		Local t:String = buffer.getContent()
		buffer.free()
		Return t
	End Method

	Rem
	bbdoc: Create a new #TxmlXPathContext
	Returns: a new TxmlXPathContext.
	End Rem
	Method newXPathContext:TxmlXPathContext()
		Return TxmlXPathContext._create(bmx_libxml_xmlXPathNewContext(basePtr))
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

		Return TxmlDtd._create(bmx_libxml_xmlCreateIntSubset(basePtr, name, externalID, systemID))
	End Method

	Rem
	bbdoc: Get the internal subset of a document
	returns: the DTD structure or Null if not found
	End Rem
	Method getInternalSubset:TxmlDtd()
		Return TxmlDtd._create(bmx_libxml_xmlGetIntSubset(basePtr))
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

		Return TxmlDtd._create(bmx_libxml_xmlNewDtd(basePtr, name, externalID, systemID))
	End Method


	Rem
	bbdoc: Call this routine to speed up XPath computation on static documents.
	returns: The number of elements found in the document or -1 in case of error.
	about: This stamps all the element nodes with the document order Like for line information, the order is kept
	in the element->content field, the value stored is actually - the node number (starting at -1) to be able
	to differentiate from line numbers.
	End Rem
	Method XPathOrderElements:Long()
		Local value:Long
		bmx_libxml_xmlXPathOrderDocElems(basePtr, Varptr value)
		Return value
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
		Return TxmlDoc._create(bmx_libxml_xmlCopyDoc(basePtr, recursive))
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
		Return TxmlEntity._create(bmx_libxml_xmlAddDocEntity(basePtr, name, EntityType, externalID, systemID, content))
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
		Return TxmlEntity._create(bmx_libxml_xmlAddDtdEntity(basePtr, name, EntityType, externalID, systemID, content))
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
		Return bmx_libxml_xmlEncodeEntitiesReentrant(basePtr, inp)
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
		Return bmx_libxml_xmlEncodeSpecialChars(basePtr, inp)
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
		Return TxmlEntity._create(bmx_libxml_xmlGetDocEntity(basePtr, name))
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
		Return TxmlEntity._create(bmx_libxml_xmlGetDtdEntity(basePtr, name))
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
		Return TxmlEntity._create(bmx_libxml_xmlGetParameterEntity(basePtr, name))
	End Method

	Rem
	bbdoc: Implement the XInclude substitution on the XML document.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	End Rem
	Method XIncludeProcess:Int()
		Return bmx_libxml_xmlXIncludeProcess(basePtr)
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
		Return bmx_libxml_xmlXIncludeProcessFlags(basePtr, flags)
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

		Return TxmlAttribute._create(bmx_libxml_xmlGetID(basePtr, id))
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

		Return bmx_libxml_xmlIsID(basePtr, node.basePtr, attr.basePtr)
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

		Return bmx_libxml_xmlIsRef(basePtr, node.basePtr, attr.basePtr)
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

		Return bmx_libxml_xmlIsMixedElement(basePtr, name)
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

		Return bmx_libxml_xmlRemoveID(basePtr, attr.basePtr)
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

		Return bmx_libxml_xmlRemoveRef(basePtr, attr.basePtr)
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
		Return TxmlElementContent._create(bmx_libxml_xmlNewDocElementContent(basePtr, name, contentType))
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

		bmx_libxml_xmlFreeDocElementContent(basePtr, content.xmlElementContentPtr)
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

		If context = Null Then
			Return bmx_libxml_xmlValidCtxtNormalizeAttributeValue(Null, basePtr, elem.basePtr, name, value)
		Else
			Return bmx_libxml_xmlValidCtxtNormalizeAttributeValue(context.xmlValidCtxtPtr, basePtr, elem.basePtr, name, value)
		End If
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

		Return bmx_libxml_xmlValidNormalizeAttributeValue(basePtr, elem.basePtr, name, value)
	End Method

End Type

Rem
bbdoc: An XML Node
End Rem
Type TxmlNode Extends TxmlBase

	' internal function... not part of the API !
	Function _create:TxmlNode(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlNode = New TxmlNode

			this.basePtr = basePtr
			'this.initBase(basePtr)

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

		Local node:TxmlNode
		If namespace = Null Then
			node = _create(bmx_libxml_xmlNewNode(Null, name))
		Else
			node = _create(bmx_libxml_xmlNewNode(namespace.xmlNsPtr, name))
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
		Return bmx_libxml_xmlNodeGetContent(basePtr)
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

		Return bmx_libxml_xmlTextConcat(basePtr, content)
	End Method

	Rem
	bbdoc: Is this node a Text node ?
	End Rem
	Method isText:Int()
		Return bmx_libxml_xmlNodeIsText(basePtr)
	End Method

	Rem
	bbdoc: Checks whether this node is an empty or whitespace only (and possibly ignorable) text-node.
	End Rem
	Method isBlankNode:Int()
		Return bmx_libxml_xmlIsBlankNode(basePtr)
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

		bmx_libxml_xmlNodeSetBase(basePtr, uri)
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
		Return bmx_libxml_xmlNodeGetBase(getDocument().basePtr, basePtr)
	End Method

	Rem
	bbdoc: Replace the content of a node.
	about:Parameters:
	<ul>
	<li><b>content</b> : the new value of the content</li>
	</ul>
	End Rem
	Method setContent(content:String)
		bmx_libxml_xmlNodeSetContent(basePtr, content)
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

		bmx_libxml_xmlNodeAddContent(basePtr, content)
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

		bmx_libxml_xmlNodeSetName(basePtr, name)
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
			Return TxmlNode._create(bmx_libxml_xmlTextMerge(basePtr, node.basePtr))
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

		If namespace <> Null Then
			s = bmx_libxml_xmlNewChild(basePtr, namespace.xmlNsPtr, name, content)
		Else
			s = bmx_libxml_xmlNewChild(basePtr, Null, name, content)
		End If

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

		If namespace <> Null Then
			s = bmx_libxml_xmlNewTextChild(basePtr, namespace.xmlNsPtr, name, content)
		Else
			s = bmx_libxml_xmlNewTextChild(basePtr, Null, name, content)
		End If

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
			Return TxmlNode._create(bmx_libxml_xmlAddChild(basePtr, firstNode.basePtr))
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

		Return TxmlNode._create(bmx_libxml_xmlAddNextSibling(basePtr, node.basePtr))
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

		Return TxmlNode._create(bmx_libxml_xmlAddPrevSibling(basePtr, node.basePtr))
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

		Return TxmlNode._create(bmx_libxml_xmlAddSibling(basePtr, node.basePtr))
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

		Return TxmlAttribute._create(bmx_libxml_xmlNewProp(basePtr, name, value))
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

		Return TxmlAttribute._create(bmx_libxml_xmlSetProp(basePtr, name, value))
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

		Return TxmlAttribute._create(bmx_libxml_xmlSetNsProp(basePtr, namespace.xmlNsPtr, name, value))
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

		Return bmx_libxml_xmlUnsetNsProp(basePtr, namespace.xmlNsPtr, name)
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

		Return bmx_libxml_xmlUnsetProp(basePtr, name)
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

		Return bmx_libxml_xmlGetProp(basePtr, name)
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

		Return bmx_libxml_xmlGetNsProp(basePtr, name, namespace)
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

		Return bmx_libxml_xmlGetNoNsProp(basePtr, name)
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

		Return TxmlAttribute._create(bmx_libxml_xmlHasNsProp(basePtr, name, namespace))
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

		Return TxmlAttribute._create(bmx_libxml_xmlHasProp(basePtr, name))
	End Method

	Rem
	bbdoc: Build a structure based Path for the node.
	returns: The path or Null in case of error.
	End Rem
	Method getNodePath:String()
		Return bmx_libxml_xmlGetNodePath(basePtr)
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
		Return TxmlNode._create(bmx_libxml_xmlReplaceNode(basePtr, withNode.basePtr))
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

		bmx_libxml_xmlSetNs(basePtr, namespace.xmlNsPtr)
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
		bmx_libxml_xmlNodeSetSpacePreserve(basePtr, value)
	End Method

	Rem
	bbdoc: Searches the space preserving behaviour of a node, i.e. the values of the xml:space attribute or the one carried by the nearest ancestor.
	Returns: -1 if xml:space is not inherited, 0 if "default", 1 if "preserve"
	End Rem
	Method getSpacePreserve:Int()
		Return bmx_libxml_xmlNodeGetSpacePreserve(basePtr)
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

		bmx_libxml_xmlNodeSetLang(basePtr, lang)
	End Method

	Rem
	bbdoc: Searches the language of a node, i.e. the values of the xml:lang attribute or the one carried by the nearest ancestor.
	returns: the language value, or Null if not found.
	End Rem
	Method GetLanguage:String()
		Return bmx_libxml_xmlNodeGetLang(basePtr)
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

		Local commentPtr:Byte Ptr = bmx_libxml_xmlNewComment(comment)

		If commentPtr <> Null Then
			Return TxmlNode._create(bmx_libxml_xmlAddChild(basePtr, commentPtr))
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

		Local cdataPtr:Byte Ptr = bmx_libxml_xmlNewCDataBlock(basePtr, content)

		If cdataPtr <> Null Then
			Return TxmlNode._create(bmx_libxml_xmlAddChild(basePtr, cdataPtr))
		End If
	End Method

	Rem
	bbdoc: Return the string equivalent to the text contained in the child nodes made of TEXTs and ENTITY_REFs.
	End Rem
	Method GetText:String()
		Return bmx_libxml_xmlNodeListGetString(basePtr)
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
		bmx_libxml_xmlNodeDump(buffer.xmlBufferPtr, basePtr)
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
		Return TxmlNs._create(bmx_libxml_xmlSearchNs(basePtr, namespace))
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

		Return TxmlNs._create(bmx_libxml_xmlSearchNsByHref(basePtr, href))
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
		Return TxmlNode._create(bmx_libxml_xmlCopyNode(basePtr, extended))
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
		Return TxmlNode._create(bmx_libxml_xmlDocCopyNode(basePtr, doc.basePtr, extended))
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
		bmx_libxml_xmlSetTreeDoc(basePtr, doc.basePtr)
	End Method

	Rem
	bbdoc: Implement the XInclude substitution for the subtree.
	returns: 0 if no substitution were done, -1 if some processing failed or the number of substitutions done.
	End Rem
	Method XIncludeProcessTree:Int()
		Return bmx_libxml_xmlXIncludeProcessTree(basePtr)
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
		Return bmx_libxml_xmlXIncludeProcessTreeFlags(basePtr, flags)
	End Method

	Rem
	bbdoc: Returns the associated namespace.
	End Rem
	Method getNamespace:TxmlNs()
		Return TxmlNs._create(bmx_libxml_xmlnode_namespace(basePtr))
	End Method

	Rem
	bbdoc: Returns the list of node attributes.
	returns: The list of attributes or Null if the node has none.
	End Rem
	Method getAttributeList:TList()
		Local attributes:TList = New TList
		Local attr:TxmlBase = chooseCreateFromType(bmx_libxml_xmlnode_properties(basePtr))

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
		bmx_libxml_xmlUnlinkNode(basePtr)
	End Method

	Rem
	bbdoc: Frees a node.
	about: The node should be @unlinked before being freed. See #unlinkNode.
	End Rem
	Method freeNode()
		bmx_libxml_xmlFreeNode(basePtr)
	End Method

End Type

Rem
bbdoc: Xml Buffer
End Rem
Type TxmlBuffer

	Field xmlBufferPtr:Byte Ptr

	Function _create:TxmlBuffer(xmlBufferPtr:Byte Ptr)
		If xmlBufferPtr <> Null Then
			Local this:TxmlBuffer = New TxmlBuffer

			this.xmlBufferPtr = xmlBufferPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Function newBuffer:TxmlBuffer()
		Return TxmlBuffer._create(bmx_libxml_xmlBufferCreate())
	End Function

	Rem
	bbdoc: Routine to create an XML buffer from an immutable memory area.
	about: The area won't be modified nor copied, and is expected to be present until the end
	of the buffer lifetime.
	End Rem
	Function CreateStatic:TxmlBuffer(mem:Byte Ptr, size:Int)
		Return TxmlBuffer._create(bmx_libxml_xmlBufferCreateStatic(mem, size))
	End Function

	Rem
	bbdoc: Extract the content of a buffer.
	End Rem
	Method getContent:String()
		Return bmx_libxml_xmlbuffer_content(xmlBufferPtr)
	End Method

	Method free()
		bmx_libxml_xmlBufferFree(xmlBufferPtr)
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
		Return TxmlOutputBuffer._create(xmlOutputBufferCreateBuffer(buffer.xmlBufferPtr, Null))
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

	Field xmlNsPtr:Byte Ptr

	Function _create:TxmlNs(xmlNsPtr:Byte Ptr)
		If xmlNsPtr <> Null Then
			Local this:TxmlNs = New TxmlNs
			this.xmlNsPtr = xmlNsPtr
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the type... global or local.
	End Rem
	Method getType:Int()
		Return bmx_libxml_xmlns_type(xmlNsPtr)
	End Method

	Rem
	bbdoc: Returns the URL for the namespace.
	End Rem
	Method getHref:String()
		Return bmx_libxml_xmlns_href(xmlNsPtr)
	End Method

	Rem
	bbdoc: Returns the prefix for the namespace.
	End Rem
	Method getPrefix:String()
		Return bmx_libxml_xmlns_prefix(xmlNsPtr)
	End Method

	Rem
	bbdoc: Free up the structures associated to the namespace
	End Rem
	Method free()
		bmx_libxml_xmlFreeNs(xmlNsPtr)
	End Method
End Type

Rem
bbdoc: An XML Attribute
End Rem
Type TxmlAttribute Extends TxmlBase

	' internal function... not part of the API !
	Function _create:TxmlAttribute(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlAttribute = New TxmlAttribute

			this.basePtr = basePtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the attribute value.
	End Rem
	Method getValue:String()
		Return bmx_libxml_xmlNodeListGetString(basePtr)
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
		Return bmx_libxml_xmlattr_atype(basePtr)
	End Method

	Rem
	bbdoc: Returns the associated Namespace.
	returns: The associated namespace, or Null if none.
	End Rem
	Method getNameSpace:TxmlNs()
		Return TxmlNs._create(bmx_libxml_xmlattr_ns(basePtr))
	End Method

End Type

Rem
bbdoc: An XML Node set
End Rem
Type TxmlNodeSet

	' reference to the actual node set
	Field xmlNodeSetPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlNodeSet(xmlNodeSetPtr:Byte Ptr)
		If xmlNodeSetPtr <> Null Then
			Local this:TxmlNodeSet = New TxmlNodeSet

			this.xmlNodeSetPtr = xmlNodeSetPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: The count of nodes in the node set.
	End Rem
	Method getNodeCount:Int()
		Return bmx_libxml_xmlnodeset_nodeNr(xmlNodeSetPtr)
	End Method

	Rem
	bbdoc: The list of nodes in the node set.
	End Rem
	Method getNodeList:TList()

		Local nodeList:TList = New TList

		Local count:Int = getNodeCount()

		For Local i:Int = 0 Until count

			Local node:TxmlNode = TxmlNode._create(bmx_libxml_xmlnodeset_nodetab(xmlNodeSetPtr, i))
			nodeList.addLast(node)

		Next

		Return nodeList
	End Method

	Rem
	bbdoc: Converts the node set to its boolean value.
	returns: The boolean value
	End Rem
	Method castToBoolean:Int()
		Return bmx_libxml_xmlXPathCastNodeSetToBoolean(xmlNodeSetPtr)
	End Method

	Rem
	bbdoc: Converts the node set to its number value.
	returns: The number value
	End Rem
	Method castToNumber:Double()
		Return bmx_libxml_xmlXPathCastNodeSetToNumber(xmlNodeSetPtr)
	End Method

	Rem
	bbdoc: Converts the node set to its string value.
	returns: The string value
	End Rem
	Method castToString:String()
		Return bmx_libxml_xmlXPathCastNodeSetToString(xmlNodeSetPtr)
	End Method

	Rem
	bbdoc: Checks whether the node set is empty or not.
	End Rem
	Method isEmpty:Int()
		Return getNodeCount() = 0
	End Method

	Rem
	bbdoc: Free the node set compound (not the actual nodes !).
	End Rem
	Method free()
		bmx_libxml_xmlXPathFreeNodeSet(xmlNodeSetPtr)
	End Method
End Type

Rem
bbdoc: An XML XPath Object
End Rem
Type TxmlXPathObject

	' reference to the actual xpath object
	Field xmlXPathObjectPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlXPathObject(xmlXPathObjectPtr:Byte Ptr)
		If xmlXPathObjectPtr <> Null Then
			Local this:TxmlXPathObject = New TxmlXPathObject

			this.xmlXPathObjectPtr = xmlXPathObjectPtr

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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewCollapsedRange(node.basePtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewLocationSetNodeSet(nodeset.xmlNodeSetPtr))
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
			obj = TxmlXPathObject._create(bmx_libxml_xmlXPtrNewLocationSetNodes(startnode.basePtr, endnode.basePtr))
		Else
			obj = TxmlXPathObject._create(bmx_libxml_xmlXPtrNewLocationSetNodes(startnode.basePtr, Null))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewRange(startnode.basePtr, startindex, endnode.basePtr, endindex))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewRangeNodeObject(startnode.basePtr, endobj.xmlXPathObjectPtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewRangeNodePoint(startnode.basePtr, endpoint.xmlXPathObjectPtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewRangeNodes(startnode.basePtr, endnode.basePtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewRangePointNode(startpoint.xmlXPathObjectPtr, endnode.basePtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrNewRangePoints(startpoint.xmlXPathObjectPtr, endpoint.xmlXPathObjectPtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrWrapLocationSet(value.xmlLocationSetPtr))
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
		Return bmx_libxml_xmlxpathobject_type(xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Returns the node set for the xpath
	End Rem
	Method getNodeSet:TxmlNodeSet()
		Return TxmlNodeSet._create(bmx_libxml_xmlxpathobject_nodesetval(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Whether the node set is empty or not
	End Rem
	Method nodeSetIsEmpty:Int()
		Return getNodeSet() = Null Or getNodeSet().isEmpty()
	End Method

	Rem
	bbdoc: Returns the xpath object string value
	End Rem
	Method getStringValue:String()
		Return bmx_libxml_xmlxpathobject_stringval(xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Converts the XPath object to its boolean value
	returns: The boolean value
	End Rem
	Method castToBoolean:Int()
		Return bmx_libxml_xmlXPathCastToBoolean(xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Converts the XPath object to its number value
	returns: The number value
	End Rem
	Method castToNumber:Double()
		Return bmx_libxml_xmlXPathCastToNumber(xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Converts the XPath object to its string value
	returns: The string value
	End Rem
	Method castToString:String()
		Return bmx_libxml_xmlXPathCastToString(xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Converts an existing object to its boolean() equivalent.
	returns: the new object, this one is freed
	End Rem
	Method convertBoolean:TxmlXPathObject()
		Return TxmlXPathObject._create(bmx_libxml_xmlXPathConvertBoolean(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Converts an existing object to its number() equivalent.
	returns: the new object, this one is freed
	End Rem
	Method convertNumber:TxmlXPathObject()
		Return TxmlXPathObject._create(bmx_libxml_xmlXPathConvertNumber(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Converts an existing object to its string() equivalent.
	returns: the new object, this one is freed
	End Rem
	Method convertString:TxmlXPathObject()
		Return TxmlXPathObject._create(bmx_libxml_xmlXPathConvertString(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Allocate a new copy of a given object.
	returns: The newly created object.
	End Rem
	Method copy:TxmlXPathObject()
		Return TxmlXPathObject._create(bmx_libxml_xmlXPathObjectCopy(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Build a node list tree copy of the XPointer result.
	returns: An node list or Null. The caller has to free the node tree.
	about: This will drop Attributes and Namespace declarations.
	end rem
	Method XPointerBuildNodeList:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlXPtrBuildNodeList(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Create a new TxmlLocationSet of type double and value of this XPathObject.
	returns: The newly created object.
	end rem
	Method XPointerLocationSetCreate:TxmlLocationSet()
		Return TxmlLocationSet._create(bmx_libxml_xmlXPtrLocationSetCreate(xmlXPathObjectPtr))
	End Method

	Rem
	bbdoc: Free up the TxmlXPathObject.
	End Rem
	Method free()
		bmx_libxml_xmlXPathFreeObject(xmlXPathObjectPtr)
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

	' reference to the actual xpath object
	Field xmlXPathContextPtr:Byte Ptr


	' internal function... not part of the API !
	Function _create:TxmlXPathContext(xmlXPathContextPtr:Byte Ptr)
		If xmlXPathContextPtr <> Null Then
			Local this:TxmlXPathContext = New TxmlXPathContext

			this.xmlXPathContextPtr = xmlXPathContextPtr

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
				context = TxmlXPathContext._create(bmx_libxml_xmlXPtrNewContext(doc.basePtr, here.basePtr, origin.basePtr))
			Else
				context = TxmlXPathContext._create(bmx_libxml_xmlXPtrNewContext(doc.basePtr, here.basePtr, Null))
			End If
		Else
			If origin <> Null Then
				context = TxmlXPathContext._create(bmx_libxml_xmlXPtrNewContext(doc.basePtr, Null, origin.basePtr))
			Else
				context = TxmlXPathContext._create(bmx_libxml_xmlXPtrNewContext(doc.basePtr, Null, Null))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPathEvalExpression(text, xmlXPathContextPtr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPathEval(text, xmlXPathContextPtr))
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
	'	Return xmlXPathContextSetCache(xmlXPathContextPtr, active, value, options)
	'End Method

	Rem
	bbdoc: Return the TxmlDoc associated to this XPath context.
	End Rem
	Method getDocument:TxmlDoc()
		Return TxmlDoc._create(bmx_libxml_xmlxpathcontext_doc(xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Return the current TxmlNode associated with this XPath context.
	End Rem
	Method GetNode:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlxpathcontext_node(xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Register a new namespace.
	about: If @uri is Null it unregisters the namespace
	End Rem
	Method registerNamespace:Int(prefix:String, uri:String)
		Return bmx_libxml_xmlXPathRegisterNs(xmlXPathContextPtr, prefix, uri)
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
			result = bmx_libxml_xmlXPathEvalPredicate(xmlXPathContextPtr, res.xmlXPathObjectPtr)
		End If

		Return result
	End Method

	Rem
	bbdoc: Evaluate the XPath Location Path in the context.
	returns: The TxmlXPathObject resulting from the evaluation or Null. The caller has to free the object.
	End Rem
	Method XPointerEval:TxmlXPathObject(expr:String)
		Assert expr, XML_ERROR_PARAM

		Return TxmlXPathObject._create(bmx_libxml_xmlXPtrEval(expr, xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Returns the number of defined types.
	End Rem
	Method countDefinedTypes:Int()
		Return bmx_libxml_xmlxpathcontext_nb_types(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Returns the max number of types.
	End Rem
	Method getMaxTypes:Int()
		Return bmx_libxml_xmlxpathcontext_max_types(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Returns the context size.
	End Rem
	Method getContextSize:Int()
		Return bmx_libxml_xmlxpathcontext_contextSize(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Returns the proximity position.
	End Rem
	Method getProximityPosition:Int()
		Return bmx_libxml_xmlxpathcontext_proximityPosition(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Returns whether this is an XPointer context or not.
	End Rem
	Method isXPointerContext:Int()
		Return bmx_libxml_xmlxpathcontext_xptr(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Returns the XPointer for here.
	End Rem
	Method getHere:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlxpathcontext_here(xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Returns the XPointer for origin.
	End Rem
	Method GetOrigin:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlxpathcontext_origin(xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Returns the function name when calling a function.
	End Rem
	Method getFunction:String()
		Return bmx_libxml_xmlxpathcontext_function(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Returns the function URI when calling a function.
	End Rem
	Method getFunctionURI:String()
		Return bmx_libxml_xmlxpathcontext_functionURI(xmlXPathContextPtr)
	End Method

	Rem
	bbdoc: Free up the TxmlXPathContext
	End Rem
	Method free()
		bmx_libxml_xmlXPathFreeContext(xmlXPathContextPtr)
	End Method
End Type

Rem
bbdoc: An XML DTD
End Rem
Type TxmlDtd Extends TxmlBase

	Function _create:TxmlDtd(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlDtd = New TxmlDtd
			this.basePtr = basePtr
			'this.initBase(basePtr)
			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the external identifier for PUBLIC DTD.
	End Rem
	Method getExternalID:String()
		Return bmx_libxml_xmldtd_externalID(basePtr)
	End Method

	Rem
	bbdoc: Returns the URI for a SYSTEM or PUBLIC DTD.
	End Rem
	Method getSystemID:String()
		Return bmx_libxml_xmldtd_systemID(basePtr)
	End Method

	Rem
	bbdoc: Do a copy of the dtd.
	returns: A new TxmlDtd object, or Null in case of error.
	End Rem
	Method copyDtd:TxmlDtd()
		Return TxmlDtd._create(bmx_libxml_xmlCopyDtd(basePtr))
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

		Return TxmlDtdAttribute._create(bmx_libxml_xmlGetDtdAttrDesc(basePtr, elem, name))
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

		Return TxmlDtdElement._create(bmx_libxml_xmlGetDtdElementDesc(basePtr, name))
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

		Return TxmlNotation._create(bmx_libxml_xmlGetDtdNotationDesc(basePtr, name))
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

		Return TxmlDtdAttribute._create(bmx_libxml_xmlGetDtdQAttrDesc(basePtr, elem, name, prefix))
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

		Return TxmlDtdElement._create(bmx_libxml_xmlGetDtdQElementDesc(basePtr, name, prefix))
	End Method

	Rem
	bbdoc: Free the DTD structure
	End Rem
	Method free()
		bmx_libxml_xmlFreeDtd(basePtr)
	End Method
End Type


Rem
bbdoc: An XML Error
End Rem
Type TxmlError

	Field xmlErrorPtr:Byte Ptr

	Function _create:TxmlError(xmlErrorPtr:Byte Ptr)
		If xmlErrorPtr <> Null Then
			Local this:TxmlError = New TxmlError
			this.xmlErrorPtr = xmlErrorPtr
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
		Return bmx_libxml_xmlerror_domain(xmlErrorPtr)
	End Method

	Rem
	bbdoc: Returns the error code.
	End Rem
	Method getErrorCode:Int()
		Return bmx_libxml_xmlerror_code(xmlErrorPtr)
	End Method

	Rem
	bbdoc: Returns the error message text.
	End Rem
	Method getErrorMessage:String()
		Return bmx_libxml_xmlerror_message(xmlErrorPtr)
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
		Return bmx_libxml_xmlerror_level(xmlErrorPtr)
	End Method

	Rem
	bbdoc: Returns the filename.
	End Rem
	Method getFilename:String()
		Return bmx_libxml_xmlerror_file(xmlErrorPtr)
	End Method

	Rem
	bbdoc: Returns the error line, if available.
	End Rem
	Method getLine:Int()
		Return bmx_libxml_xmlerror_line(xmlErrorPtr)
	End Method

	Rem
	bbdoc: Returns extra error text information, if available.
	End Rem
	Method getExtraText:String[]()
		Local xtra:String[] = New String[0]
		Local s:String = bmx_libxml_xmlerror_str1(xmlErrorPtr)
		If s Then
			xtra = xtra[..xtra.length + 1]
			xtra[0] = s
		End If

		s = bmx_libxml_xmlerror_str2(xmlErrorPtr)
		If s Then
			xtra = xtra[..xtra.length + 1]
			xtra[xtra.length - 1] = s
		End If

		s = bmx_libxml_xmlerror_str3(xmlErrorPtr)
		If s Then
			xtra = xtra[..xtra.length + 1]
			xtra[xtra.length - 1] = s
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
		Return bmx_libxml_xmlerror_int2(xmlErrorPtr)
	End Method

	Rem
	bbdoc: Returns the node in the tree, if available.
	End Rem
	Method getErrorNode:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlerror_node(xmlErrorPtr))
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

	Field xmlTextReaderPtr:Byte Ptr

	Field docTextPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlTextReader(xmlTextReaderPtr:Byte Ptr)
		If xmlTextReaderPtr <> Null Then
			Local this:TxmlTextReader = New TxmlTextReader

			this.xmlTextReaderPtr = xmlTextReaderPtr

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

			If encoding = Null And options = 0 Then
				Return TxmlTextReader._create(bmx_libxml_xmlNewTextReaderFilename(filename))
			Else
				Return TxmlTextReader._create(bmx_libxml_xmlReaderForFile(filename, encoding, options))
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

				Return TxmlTextReader._create(bmx_libxml_xmlReaderForMemory(buf, size, Null, encoding, options))
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

		Local docTextPtr:Byte Ptr = text.ToUTF8String()

		Local t:TxmlTextReader = TxmlTextReader._create(bmx_libxml_xmlReaderForDoc(docTextPtr, url, encoding, options))

		If t Then
			t.docTextPtr = docTextPtr
		Else
			MemFree(docTextPtr)
		End If

		Return t
	End Function

	Rem
	bbdoc: Provides the number of attributes of the current node.
	returns: 0 if no attributes, -1 in case of error or the attribute count
	End Rem
	Method attributeCount:Int()
		Return bmx_libxml_xmlTextReaderAttributeCount(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The base URI of the node.
	End Rem
	Method baseUri:String()
		Return bmx_libxml_xmlTextReaderBaseUri(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Hacking interface allowing to get the TxmlDoc correponding to the current document being accessed by the TxmlTextReader.
	returns: The TxmlDoc or Null in case of error.
	about: NOTE: as a result of this call, the reader will not destroy the associated XML document and calling free()
	on the TxmlDoc is needed once the reader parsing has finished.
	End Rem
	Method currentDoc:TxmlDoc()
		Return TxmlDoc._create(bmx_libxml_xmlTextReaderCurrentDoc(xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: Deallocate all the resources associated to the reader.
	End Rem
	Method free()
		bmx_libxml_xmlFreeTextReader(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the next node in the stream, exposing its properties.
	returns: 1 if the node was read successfully, 0 if there is no more nodes to read, or -1 in case of error
	End Rem
	Method read:Int()
		Return bmx_libxml_xmlTextReaderRead(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Parses an attribute value into one or more Text and EntityReference nodes.
	about: 1 in case of success, 0 if the reader was not positioned on an attribute node or all the attribute values have been read, or -1 in case of error.
	End Rem
	Method readAttributeValue:Int()
		Return bmx_libxml_xmlTextReaderReadAttributeValue(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of the current node, including child nodes and markup.
	returns: A string containing the XML content, or Null if the current node is neither an element nor attribute, or has no child nodes.
	End Rem
	Method readInnerXml:String()
		Return bmx_libxml_xmlTextReaderReadInnerXml(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of the current node, including child nodes and markup.
	returns: A string containing the XML content, or NULL if the current node is neither an element nor attribute, or has no child nodes.
	End Rem
	Method readOuterXml:String()
		Return bmx_libxml_xmlTextReaderReadOuterXml(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Gets the read state of the reader.
	about: The state value, or -1 in case of error.
	End Rem
	Method readState:Int()
		Return bmx_libxml_xmlTextReaderReadState(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of an element or a text node as a string.
	about: A string containing the contents of the Element or Text node, or Null if the reader is positioned on any other type of node.
	End Rem
	Method ReadString:String()
		Return bmx_libxml_xmlTextReaderReadString(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The qualified name of the node, equal to Prefix :LocalName.
	returns: The local name or Null if not available.
	End Rem
	Method constName:String()
		Return bmx_libxml_xmlTextReaderConstName(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The local name of the node.
	returns: The local name or Null if not available.
	End Rem
	Method constLocalName:String()
		Return bmx_libxml_xmlTextReaderConstLocalName(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Determine the encoding of the document being read.
	returns: A string containing the encoding of the document or Null in case of error.
	End Rem
	Method constEncoding:String()
		Return bmx_libxml_xmlTextReaderConstEncoding(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The base URI of the node.
	returns: The base URI or Null if not available.
	End Rem
	Method constBaseUri:String()
		Return bmx_libxml_xmlTextReaderConstBaseUri(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The URI defining the namespace associated with the node.
	returns: The namespace URI or Null if not available.
	End Rem
	Method constNamespaceUri:String()
		Return bmx_libxml_xmlTextReaderConstNamespaceUri(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: A shorthand reference to the namespace associated with the node.
	returns: The prefix or Null if not available.
	End Rem
	Method constPrefix:String()
		Return bmx_libxml_xmlTextReaderConstPrefix(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Provides the text value of the node if present.
	returns: the string or Null if not available.
	End Rem
	Method constValue:String()
		Return bmx_libxml_xmlTextReaderConstValue(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The xml:lang scope within which the node resides.
	returns: The xml:lang value or Null if none exists.
	End Rem
	Method constXmlLang:String()
		Return bmx_libxml_xmlTextReaderConstXmlLang(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Determine the XML version of the document being read.
	returns: A string containing the XML version of the document or Null in case of error.
	End Rem
	Method constXmlVersion:String()
		Return bmx_libxml_xmlTextReaderConstXmlVersion(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The depth of the node in the tree.
	returns: the depth or -1 in case of error
	End Rem
	Method depth:Int()
		Return bmx_libxml_xmlTextReaderDepth(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Reads the contents of the current node and the full subtree.
	about: It then makes the subtree available until the next #read call.
	returns: A node, valid until the next #read call or Null in case of error.
	End Rem
	Method expand:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlTextReaderExpand(xmlTextReaderPtr))
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

		Return bmx_libxml_xmlTextReaderGetAttribute(xmlTextReaderPtr, name)
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
		Return bmx_libxml_xmlTextReaderGetAttributeNo(xmlTextReaderPtr, index)
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

		Return bmx_libxml_xmlTextReaderGetAttributeNs(xmlTextReaderPtr, localName, namespaceURI)
	End Method

	Rem
	bbdoc: Provide the column number of the current parsing point.
	returns: An int or 0 if not available
	End Rem
	Method getParserColumnNumber:Int()
		Return bmx_libxml_xmlTextReaderGetParserColumnNumber(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Provide the line number of the current parsing point.
	returns: An int or 0 if not available.
	End Rem
	Method getParserLineNumber:Int()
		Return bmx_libxml_xmlTextReaderGetParserLineNumber(xmlTextReaderPtr)
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
		Return bmx_libxml_xmlTextReaderGetParserProp(xmlTextReaderPtr, prop)
	End Method

	Rem
	bbdoc: Whether the node has attributes.
	returns: 1 if true, 0 if false, and -1 in case or error
	End Rem
	Method hasAttributes:Int()
		Return bmx_libxml_xmlTextReaderHasAttributes(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Whether the node can have a text value.
	returns: 1 if true, 0 if false, and -1 in case or error.
	End Rem
	Method hasValue:Int()
		Return bmx_libxml_xmlTextReaderHasValue(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Whether an Attribute node was generated from the default value defined in the DTD or schema.
	returns: 0 if not defaulted, 1 if defaulted, and -1 in case of error
	End Rem
	Method isDefault:Int()
		Return bmx_libxml_xmlTextReaderIsDefault(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Check if the current node is empty.
	returns: 1 if empty, 0 if not and -1 in case of error.
	End Rem
	Method isEmptyElement:Int()
		Return bmx_libxml_xmlTextReaderIsEmptyElement(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Determine whether the current node is a namespace declaration rather than a regular attribute.
	returns: 1 if the current node is a namespace declaration, 0 if it is a regular attribute or other type of node, or -1 in case of error.
	End Rem
	Method isNamespaceDecl:Int()
		Return bmx_libxml_xmlTextReaderIsNamespaceDecl(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Retrieve the validity status from the parser context.
	about: The flag value 1 if valid, 0 if no, and -1 in case of error.
	End Rem
	Method isValid:Int()
		Return bmx_libxml_xmlTextReaderIsValid(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The local name of the node.
	returns: the local name or Null if not available
	End Rem
	Method localName:String()
		Return bmx_libxml_xmlTextReaderLocalName(xmlTextReaderPtr)
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
		Return bmx_libxml_xmlTextReaderLookupNamespace(xmlTextReaderPtr, prefix)
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

		Return bmx_libxml_xmlTextReaderMoveToAttribute(xmlTextReaderPtr, name)
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
		Return bmx_libxml_xmlTextReaderMoveToAttributeNo(xmlTextReaderPtr, index)
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

		Return bmx_libxml_xmlTextReaderMoveToAttributeNs(xmlTextReaderPtr, localName, namespaceURI)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the node that contains the current Attribute node.
	returns: 1 in case of success, -1 in case of error, 0 if not moved.
	End Rem
	Method moveToElement:Int()
		Return bmx_libxml_xmlTextReaderMoveToElement(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the first attribute associated with the current node.
	returns: 1 in case of success, -1 in case of error, 0 if not found
	End Rem
	Method moveToFirstAttribute:Int()
		Return bmx_libxml_xmlTextReaderMoveToFirstAttribute(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Moves the position of the current instance to the next attribute associated with the current node.
	returns: 1 in case of success, -1 in case of error, 0 if not found
	End Rem
	Method moveToNextAttribute:Int()
		Return bmx_libxml_xmlTextReaderMoveToNextAttribute(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The qualified name of the node, equal to Prefix :LocalName.
	returns: the local name or Null if not available.
	End Rem
	Method name:String()
		Return bmx_libxml_xmlTextReaderName(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The URI defining the namespace associated with the node.
	returns: the namespace URI or Null if not available
	End Rem
	Method namespaceUri:String()
		Return bmx_libxml_xmlTextReaderNamespaceUri(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Skip to the node following the current one in document order while avoiding the subtree if any.
	returns: 1 if the node was read successfully, 0 if there is no more nodes to read, or -1 in case of error.
	End Rem
	Method nextNode:Int()
		Return bmx_libxml_xmlTextReaderNext(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Get the node type of the current node.
	returns: The xmlNodeType of the current node or -1 in case of error.
	End Rem
	Method nodeType:Int()
		Return bmx_libxml_xmlTextReaderNodeType(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The value indicating whether to normalize white space and attribute values.
	returns: 1 or -1 in case of error.
	about: Since attribute value and end of line normalizations are a MUST in the XML specification only the value true
	is accepted. The broken bahaviour of accepting out of range character entities like &amp;#0; is of course not supported
	either.
	End Rem
	Method normalization:Int()
		Return bmx_libxml_xmlTextReaderNormalization(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: A shorthand reference to the namespace associated with the node.
	returns: The prefix or Null if not available.
	End Rem
	Method prefix:String()
		Return bmx_libxml_xmlTextReaderPrefix(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: This tells the XML Reader to preserve the current node.
	returns: The TxmlNode or Null in case of error.
	about: The caller must also use #currentDoc to keep an handle on the resulting document once
	parsing has finished.
	End Rem
	Method preserve:TxmlNode()
		Return TxmlNode._create(bmx_libxml_xmlTextReaderPreserve(xmlTextReaderPtr))
	End Method

	Rem
	bbdoc: The quotation mark character used to enclose the value of an attribute.
	returns: " or ' and Null in case of error
	End Rem
	Method quoteChar:String()
		Local c:Int = bmx_libxml_xmlTextReaderQuoteChar(xmlTextReaderPtr)
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
		Return bmx_libxml_xmlTextReaderRelaxNGValidate(xmlTextReaderPtr, rng)
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
		Return bmx_libxml_xmlTextReaderSchemaValidate(xmlTextReaderPtr, xsd)
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
		Return bmx_libxml_xmlTextReaderSetParserProp(xmlTextReaderPtr, prop, value)
	End Method

	Rem
	bbdoc: Determine the standalone status of the document being read.
	returns: 1 if the document was declared to be standalone, 0 if it was declared to be not standalone, or -1 if the document did not specify its standalone status or in case of error.
	End Rem
	Method standalone:Int()
		Return bmx_libxml_xmlTextReaderStandalone(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: Provides the text value of the node if present
	returns: The string or Null if not available.
	End Rem
	Method value:String()
		Return bmx_libxml_xmlTextReaderValue(xmlTextReaderPtr)
	End Method

	Rem
	bbdoc: The xml:lang scope within which the node resides.
	returns: the xml:lang value or Null if none exists.
	End Rem
	Method xmlLang:String()
		Return bmx_libxml_xmlTextReaderXmlLang(xmlTextReaderPtr)
	End Method

End Type

Rem
bbdoc: An XML Entity
End Rem
Type TxmlEntity Extends TxmlBase

	Function _create:TxmlEntity(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlEntity = New TxmlEntity
			this.basePtr = basePtr
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

	Field xmlCatalogPtr:Byte Ptr

	Function _create:TxmlCatalog(xmlCatalogPtr:Byte Ptr)
		If xmlCatalogPtr <> Null Then
			Local this:TxmlCatalog = New TxmlCatalog
			this.xmlCatalogPtr = xmlCatalogPtr
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
		Return TxmlCatalog._create(bmx_libxml_xmlNewCatalog(sgml))
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

		Return TxmlCatalog._create(bmx_libxml_xmlLoadACatalog(filename))
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

		Return bm_libxml_xmlLoadCatalog(filename)
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

		Return TxmlCatalog._create(bmx_libxml_xmlLoadSGMLSuperCatalog(filename))
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

		bmx_libxml_xmlCatalogSetDefaults(allow)
	End Function

	Rem
	bbdoc: Used to get the user preference w.r.t. to what catalogs should be accepted.
	returns: The current xmlCatalogAllow value. See @setDefaults for more information.
	End Rem
	Function getDefaults:Int()
		Return bmx_libxml_xmlCatalogGetDefaults()
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

		Return bmx_libxml_xmlCatalogSetDebug(level)
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
		Return bmx_libxml_xmlCatalogSetDefaultPrefer(prefer)
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

		Return bmx_libxml_xmlCatalogAdd(rtype, orig, rep)
	End Function

	Rem
	bbdoc: Convert all the SGML catalog entries as XML ones.
	return: The number of entries converted if successful, -1 otherwise.
	End Rem
	Function convertDefault:Int()
		Return bmx_libxml_xmlCatalogConvert()
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

		Return bmx_libxml_xmlCatalogRemove(value)
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

		Return bmx_libxml_xmlCatalogResolve(pubID, sysID)
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

		Return bmx_libxml_xmlCatalogResolvePublic(pubID)
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

		Return bmx_libxml_xmlCatalogResolveSystem(sysID)
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

		Return bmx_libxml_xmlCatalogResolveURI(uri)
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

		Return bmx_libxml_xmlACatalogAdd(xmlCatalogPtr, rtype, orig, rep)
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

		Return bmx_libxml_xmlACatalogRemove(xmlCatalogPtr, value)
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

		Return bmx_libxml_xmlACatalogResolve(xmlCatalogPtr, pubID, sysID)
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

		Return bmx_libxml_xmlACatalogResolvePublic(xmlCatalogPtr, pubID)
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

		Return bmx_libxml_xmlACatalogResolveSystem(xmlCatalogPtr, sysID)
	End Method

	Rem
	bbdoc: Check is a catalog is empty
	returns: 1 if the catalog is empty, 0 if not, and -1 in case of error.
	End Rem
	Method isEmpty:Int()
		Return bmx_libxml_xmlCatalogIsEmpty(xmlCatalogPtr)
	End Method

	Rem
	bbdoc: Convert all the SGML catalog entries as XML ones.
	returns: The number of entries converted if successful, -1 otherwise.
	End Rem
	Method convertSGML:Int()
		Return bmx_libxml_xmlConvertSGMLCatalog(xmlCatalogPtr)
	End Method

	Rem
	bbdoc: Dump the catalog to the given file.
	End Rem
	Method dump(file:Int)
		bmx_libxml_xmlACatalogDump(xmlCatalogPtr, file)
	End Method

	Rem
	bbdoc: Free the memory allocated to a Catalog.
	End Rem
	Method free()
		bmx_libxml_xmlFreeCatalog(xmlCatalogPtr)
	End Method
End Type

Rem
bbdoc: An XML XInclude context.
End Rem
Type TxmlXIncludeCtxt

	Field xmlXIncludeCtxtPtr:Byte Ptr

	Function _create:TxmlXIncludeCtxt(xmlXIncludeCtxtPtr:Byte Ptr)
		If xmlXIncludeCtxtPtr <> Null Then
			Local this:TxmlXIncludeCtxt = New TxmlXIncludeCtxt
			this.xmlXIncludeCtxtPtr = xmlXIncludeCtxtPtr
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

		Return TxmlXIncludeCtxt._create(bmx_libxml_xmlXIncludeNewContext(doc.basePtr))
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

		Return bmx_libxml_xmlXIncludeProcessNode(xmlXIncludeCtxtPtr, node.basePtr)
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
		Return bmx_libxml_xmlXIncludeSetFlags(xmlXIncludeCtxtPtr, flags)
	End Method

	Rem
	bbdoc: Free the XInclude context
	End Rem
	Method free()
		bmx_libxml_xmlXIncludeFreeContext(xmlXIncludeCtxtPtr)
	End Method
End Type

Rem
bbdoc: A URI
about: Provides some standards-savvy functions for URI handling.
End Rem
Type TxmlURI

	Field xmlURIPtr:Byte Ptr

	Function _create:TxmlURI(xmlURIPtr:Byte Ptr)
		If xmlURIPtr<> Null Then
			Local this:TxmlURI = New TxmlURI
			this.xmlURIPtr = xmlURIPtr
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
		Return TxmlURI._create(bmx_libxml_xmlCreateURI())
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

		Return TxmlURI._create(bmx_libxml_xmlParseURI(uri))
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

		Return TxmlURI._create(bmx_libxml_xmlParseURIRaw(uri, raw))
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

		Return bmx_libxml_xmlBuildURI(uri, base)
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

		Return bmx_libxml_xmlCanonicPath(path)
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

		Return bmx_libxml_xmlNormalizeURIPath(path)
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

		Return bmx_libxml_xmlURIEscape(uri)
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

		Return bmx_libxml_xmlURIEscapeStr(uri, list)
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

		Return bmx_libxml_xmlURIUnescapeString(str)
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

		Return bmx_libxml_xmlParseURIReference(xmlURIPtr, uri)
	End Method

	Rem
	bbdoc: Save the URI as an escaped string.
	returns: A new string.
	End Rem
	Method saveURI:String()
		Return bmx_libxml_xmlSaveUri(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the URI scheme.
	End Rem
	Method getScheme:String()
		Return bmx_libxml_xmluri_scheme(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the opaque part.
	End Rem
	Method getOpaque:String()
		Return bmx_libxml_xmluri_opaque(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the authority part.
	End Rem
	Method getAuthority:String()
		Return bmx_libxml_xmluri_authority(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the server part.
	End Rem
	Method getServer:String()
		Return bmx_libxml_xmluri_server(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the user part.
	End Rem
	Method getUser:String()
		Return bmx_libxml_xmluri_user(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the port number.
	End Rem
	Method getPort:Int()
		Return bmx_libxml_xmluri_port(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the path string.
	End Rem
	Method getPath:String()
		Return bmx_libxml_xmluri_path(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the query string.
	End Rem
	Method getQuery:String()
		Return bmx_libxml_xmluri_query(xmlURIPtr)
	End Method

	Rem
	bbdoc: Returns the fragment identifier.
	End Rem
	Method getFragment:String()
		Return bmx_libxml_xmluri_fragment(xmlURIPtr)
	End Method

	Rem
	bbdoc: Free up the TxmlURI object.
	End Rem
	Method free()
		bmx_libxml_xmlFreeURI(xmlURIPtr)
	End Method

End Type

Rem
bbdoc: An XML Location Set.
End Rem
Type TxmlLocationSet
	'Const _locNr:Int = 0		' number of locations in the set (Int)
	'Const _locMax:Int = 4		' size of the array as allocated (Int)
	'Const _locTab:Int = 8		' array of locations (Byte Ptr)

	Field xmlLocationSetPtr:Byte Ptr

	Function _create:TxmlLocationSet(xmlLocationSetPtr:Byte Ptr)
		If xmlLocationSetPtr <> Null Then
			Local this:TxmlLocationSet = New TxmlLocationSet
			this.xmlLocationSetPtr = xmlLocationSetPtr
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
		Return TxmlLocationSet._create(bmx_libxml_xmlXPtrLocationSetCreate(Null))
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

		bmx_libxml_xmlXPtrLocationSetAdd(xmlLocationSetPtr, value.xmlXPathObjectPtr)
	End Method

	Rem
	bbdoc: Removes a TxmlXPathObject from the LocationSet.
	End Rem
	Method del(value:TxmlXPathObject)
		Assert value, XML_ERROR_PARAM

		bmx_libxml_xmlXPtrLocationSetDel(xmlLocationSetPtr, value.xmlXPathObjectPtr)
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

		Return TxmlLocationSet._create(bmx_libxml_xmlXPtrLocationSetMerge(xmlLocationSetPtr, value.xmlLocationSetPtr))
	End Method

	Rem
	bbdoc: Removes an entry from an existing LocationSet list.
	about: Parameters:
	<ul>
	<li><b>index</b> : the index to remove</li>
	</ul>
	End Rem
	Method remove(index:Int)
		bmx_libxml_xmlXPtrLocationSetRemove(xmlLocationSetPtr, index)
	End Method

	Rem
	bbdoc: Free the LocationSet compound (not the actual ranges !).
	End Rem
	Method free()
		bmx_libxml_xmlXPtrFreeLocationSet(xmlLocationSetPtr)
	End Method

End Type

Rem
bbdoc: An XML Attribute Decl.
End Rem
Type TxmlDtdAttribute Extends TxmlBase

	' internal function... not part of the API !
	Function _create:TxmlDtdAttribute(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlDtdAttribute = New TxmlDtdAttribute

			this.basePtr = basePtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the attribute default value
	End Rem
	Method getDefaultValue:String()
		Return bmx_libxml_xmldtdattribute_defaultValue(basePtr)
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
	'Const _etype:Int = 36	' The type (int)
	'Const _content:Int = 36	' the allowed element content (byte ptr)
	'Const _attributes:Int = 36	' List of the declared attributes (byte ptr)
	'Const _prefix:Int = 36	' the namespace prefix if any (byte ptr)
	'Const _contModel:Int = 36	' the validating regexp (byte ptr)
	'Const _contModel		' (byte ptr)

	' internal function... not part of the API !
	Function _create:TxmlDtdElement(basePtr:Byte Ptr)
		If basePtr <> Null Then
			Local this:TxmlDtdElement = New TxmlDtdElement

			this.basePtr = basePtr

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
		Return bmx_libxml_xmldtdelement_etype(basePtr)
	End Method

	Rem
	bbdoc: Returns the namespace prefix, if any.
	End Rem
	Method getPrefix:String()
		Return bmx_libxml_xmldtdelement_prefix(basePtr)
	End Method

End Type

Rem
bbdoc:  An XML Notation.
End Rem
Type TxmlNotation
	' offsets from the pointer
	'Const _name:Int = 0		' Notation name (byte ptr)
	'Const _PublicID:Int = 4	' Public identifier, if any (byte ptr)
	'Const _SystemID:Int = 8	' System identifier, if any (byte ptr)

	' reference to the actual element
	Field xmlNotationPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlNotation(xmlNotationPtr:Byte Ptr)
		If xmlNotationPtr <> Null Then
			Local this:TxmlNotation = New TxmlNotation

			this.xmlNotationPtr = xmlNotationPtr

			Return this
		Else
			Return Null
		End If
	End Function

	Rem
	bbdoc: Returns the notation name.
	End Rem
	Method getName:String()
		Return bmx_libxml_xmlnotation_name(xmlNotationPtr)
	End Method

	Rem
	bbdoc: Returns the public identifier, if any.
	End Rem
	Method getPublicID:String()
		Return bmx_libxml_xmlnotation_PublicID(xmlNotationPtr)
	End Method

	Rem
	bbdoc: Returns the system identifier, if any.
	End Rem
	Method getSystemID:String()
		Return bmx_libxml_xmlnotation_SystemID(xmlNotationPtr)
	End Method

End Type

Rem
bbdoc: XML validation context.
End Rem
Type TxmlValidCtxt

	'Const _error:Int = 4		' the callback in case of errors (byte ptr)
	'Const _warning:Int = 8	' the callback in case of warning Node an (byte ptr)
	'Const _node:Int = 12		' Current parsed Node (byte ptr)
	'Const _nodeNr:Int = 16	' Depth of the parsing stack (int)
	'Const _nodeMax:Int = 20	' Max depth of the parsing stack (int)
	'Const _nodeTab:Int = 24	' array of nodes (byte ptr)
	'Const _finishDtd:Int = 28	' finished validating the Dtd ? (int)
	'Const _doc:Int = 32		' the document (byte ptr)
	'Const _valid:Int = 36	' temporary validity check result state s (int)
	'Const _vstate:Int = 40	' current state (byte ptr)
	'Const _vstateNr:Int = 44	' Depth of the validation stack (int)
	'Const _vstateMax:Int = 48	' Max depth of the validation stack (int)
	'Const _vstateTab:Int = 52	' array of validation states (byte ptr)
	'Const _am:Int = 56		' the automata (byte ptr)
	'Const _state:Int = 60	' used to build the automata (byte ptr)

	' reference to the actual element
	Field xmlValidCtxtPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlValidCtxt(xmlValidCtxtPtr:Byte Ptr)
		If xmlValidCtxtPtr <> Null Then
			Local this:TxmlValidCtxt = New TxmlValidCtxt

			this.xmlValidCtxtPtr = xmlValidCtxtPtr

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

		Return bmx_libxml_xmlValidateAttributeValue(attributeType, value)
	End Function

	Rem
	bbdoc: Allocate a validation context structure.
	returns: Null if not, otherwise the new validation context structure.
	End Rem
	Function newValidCtxt:TxmlValidCtxt()
		Return _create(bmx_libxml_xmlNewValidCtxt())
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

		Return bmx_libxml_xmlValidateNameValue(value)
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

		Return bmx_libxml_xmlValidateNamesValue(value)
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

		Return bmx_libxml_xmlValidateNmtokenValue(value)
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

		Return bmx_libxml_xmlValidateNmtokensValue(value)
	End Function

	Rem
	bbdoc: Returns the temporary validity check result state.
	End Rem
	Method isValid:Int()
		Return bmx_libxml_xmlvalidctxt_valid(xmlValidCtxtPtr)
	End Method

	Rem
	bbdoc: Returns true if finished validating the DTD.
	End Rem
	Method isFinishedDtd:Int()
		Return bmx_libxml_xmlvalidctxt_finishDtd(xmlValidCtxtPtr)
	End Method

	Rem
	bbdoc: Returns the document for this object.
	End Rem
	Method getDocument:TxmlDoc()
		Return TxmlDoc._create(bmx_libxml_xmlvalidctxt_doc(xmlValidCtxtPtr))
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

		Return bmx_libxml_xmlValidateDocument(xmlValidCtxtPtr, doc.basePtr)
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

		Return bmx_libxml_xmlValidateDocumentFinal(xmlValidCtxtPtr, doc.basePtr)
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

		Return bmx_libxml_xmlValidateDtd(xmlValidCtxtPtr, doc.basePtr, dtd.basePtr)
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

		Return bmx_libxml_xmlValidateDtdFinal(xmlValidCtxtPtr, doc.basePtr)
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

		Return bmx_libxml_xmlValidateRoot(xmlValidCtxtPtr, doc.basePtr)
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

		Return bmx_libxml_xmlValidateElement(xmlValidCtxtPtr, doc.basePtr, elem.basePtr)
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

		Return bmx_libxml_xmlValidateElementDecl(xmlValidCtxtPtr, doc.basePtr, elem.basePtr)
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

		Return bmx_libxml_xmlValidateAttributeDecl(xmlValidCtxtPtr, doc.basePtr, attr.basePtr)
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

		Return bmx_libxml_xmlValidBuildContentModel(xmlValidCtxtPtr, elem.basePtr)
	End Method

	Rem
	bbdoc: Free the validation context structure.
	End Rem
	Method free()
		bmx_libxml_xmlFreeValidCtxt(xmlValidCtxtPtr)
	End Method

End Type

Rem
bbdoc: An XML element content tree.
End Rem
Type TxmlElementContent

	' reference to the actual element
	Field xmlElementContentPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlElementContent(xmlElementContentPtr:Byte Ptr)
		If xmlElementContentPtr <> Null Then
			Local this:TxmlElementContent = New TxmlElementContent

			this.xmlElementContentPtr = xmlElementContentPtr

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
		Return bmx_libxml_xmlelementcontent_type(xmlElementContentPtr)
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
		Return bmx_libxml_xmlelementcontent_ocur(xmlElementContentPtr)
	End Method

	Rem
	bbdoc: Returns the element name.
	End Rem
	Method getName:String()
		Return bmx_libxml_xmlelementcontent_name(xmlElementContentPtr)
	End Method

	Rem
	bbdoc: Returns the namespace prefix.
	End Rem
	Method getPrefix:String()
		Return bmx_libxml_xmlelementcontent_prefix(xmlElementContentPtr)
	End Method

End Type

Rem
bbdoc: A compiled XPath expression.
End Rem
Type TxmlXPathCompExpr

	' reference to the actual compiled expression
	Field xmlXPathCompExprPtr:Byte Ptr

	' internal function... not part of the API !
	Function _create:TxmlXPathCompExpr(xmlXPathCompExprPtr:Byte Ptr)
		If xmlXPathCompExprPtr <> Null Then
			Local this:TxmlXPathCompExpr = New TxmlXPathCompExpr

			this.xmlXPathCompExprPtr = xmlXPathCompExprPtr

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

		Return TxmlXPathCompExpr._create(bmx_libxml_xmlXPathCompile(expr))
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

		Return TxmlXPathObject._create(bmx_libxml_xmlXPathCompiledEval(xmlXPathCompExprPtr, context.xmlXPathContextPtr))
	End Method

	Rem
	bbdoc: Free up the allocated memory.
	End Rem
	Method free()
		bmx_libxml_xmlXPathFreeCompExpr(xmlXPathCompExprPtr)
	End Method

End Type

