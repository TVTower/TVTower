Rem
	====================================================================
	class providing helpers for XML files
	====================================================================

	Various helper functions to ease work with XML files.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2025 Ronny Otto, digidea.de

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
Import Brl.Standardio
?not bmxng
Import Brl.xml
?bmxng
Import Text.xml
?
Import "base.util.data.bmx"
Import "base.util.string.bmx"
Import "base.util.localization.bmx"
Import Brl.Retro 'for filesize
Import Brl.ObjectList



Type TXmlHelper
	Field filename:String =""
	Field xmlDoc:TxmlDoc

	Function Create:TXmlHelper(filename:String, rootNode:String="", createIfMissing:Int=True)
		Local obj:TXmlHelper = New TXmlHelper
		obj.LoadDocument(filename, rootNode, createIfMissing)

		Return obj
	End Function


	Method LoadDocument:TxmlDoc(filename:String, rootNode:String="", createIfMissing:Int=True)
		'reset old values
		If Self.xmlDoc
			xmlDoc.free()
			Self.xmlDoc = Null
		EndIf


		If FileSize(filename) >= 0
			Self.filename = filename
			Self.xmlDoc = TxmlDoc.parseFile(filename)
		Else
			Self.filename = filename

			'try to load it via a stream (maybe SDL wants to help out)
			Local stream:TStream = OpenStream(filename)
			If stream
				Self.xmlDoc = TxmlDoc.readDoc(stream)
				stream.Close()
			EndIf
		EndIf


		If Not xmlDoc
			If createIfmissing
				Self.xmlDoc = CreateDocument(rootNode)
			Else
				If FileSize(filename) >= 0
					Print "Document ~~"+filename+"~~ not parsed successfully."
				Else
					Print "Document ~~"+filename+"~~ not found."
					Return Null
				EndIf
			EndIf
		EndIf

		Return Self.xmlDoc
	End Method


	Function CreateFromString:TXmlHelper(content:String, rootNode:String="")
		Local obj:TXmlHelper = New TXmlHelper
		obj.filename = "memory"
		obj.xmlDoc = TxmlDoc.readDoc(content)
		Return obj
	End Function


	Function CreateDocument:TxmlDoc(rootNodeName:String = "")
		Local xmlDoc:TxmlDoc = TxmlDoc.newDoc("1.0")
		If rootNodeName <> "" Then CreateRootNode(xmlDoc, rootNodeName)

		Return xmlDoc
	End Function


	'====


	'compare (ascii only) strings case-insensitively
	Function StartsWithAsciiNameLC:Int(s:String, needle:String)
		if s.length < needle.length Then Return False

		For Local c:Int = 0 Until needle.length
			Local cmp:Int = AsciiCharacterToLower(s[c]) - AsciiCharacterToLower(needle[c])
			If cmp <> 0 Then Return False
		Next
		Return True
	End Function


	Function CompareAsciiNamesLC:Int(a:String, b:String)
		Local diff:Int = a.length - b.length
		if diff <> 0 Then Return diff

		For Local c:Int = 0 Until Min(a.length, b.length)
			Local cmp:Int = AsciiCharacterToLower(a[c]) - AsciiCharacterToLower(b[c])
			If cmp <> 0 Then Return cmp
		Next
		
		Return 0
	End Function


	Function AsciiNamesLCAreEqual:Int(a:String, b:String)
		If a.length <> b.length Then Return False
		
		For Local c:Int = 0 Until Min(a.length, b.length)
			If AsciiCharacterToLower(a[c]) <> AsciiCharacterToLower(b[c]) Then Return False
		Next
		Return True
	End Function


	Function InAsciiNamesLCArray:Int(str:String, arr:String[])
		Local inArray:Int
		For Local i:Int = 0 Until arr.length
			If AsciiNamesLCAreEqual(arr[i], str) 
				Return True
			EndIf
		Next
		Return False
	End Function
	

	Function AsciiCharacterToLower:Int(c:Int)
		Return c | ((c - Asc("A")) <= (Asc("Z") - Asc("A"))) * (Asc("a") - Asc("A"))
	'	Return c | ((c - 65) <= 25) * $20
	End Function

	'====


	Method GetRootNode:TxmlNode()
		If xmlDoc Then Return xmlDoc.getRootElement()
		Return Null
	End Method


	Function CreateRootNode:TxmlNode(document:TxmlDoc, key:String)
		If Not document Then Return Null

		If key = "" Then key = "root"
		Local result:TxmlNode = TxmlNode.newNode(key)
		'add a new line within <key></key>" so children get added on
		'the next line
		result.AddContent("~n")

		'add as root
		document.setRootElement(result)

		Return result
	End Function


	'====


	'returns a list of all child elements (one level deeper)
	'in comparison to "txmlnode.GetChildren()" it returns a TObjectList
	'in all cases.
	Function GetNodeChildElements:TObjectList(node:TxmlNode)
		'we only want "<ELEMENTS>"
		If Not node Then Return New TObjectList()
		Return node.getChildren()
	End Function



	'find a "<tag>"-element within a given start node
	Method FindElementNode:TxmlNode(startNode:TxmlNode, nodeName:String)
		If Not startNode Then startNode = GetRootNode()
		Return _FindElementNode(startNode, nodeName)
	End Method


	'non recursive child finding
	Function FindChild:TxmlNode(node:TxmlNode, _nodeName:String)
		If Not node Then Return Null

		Local child:TXmlNode = TXmlNode(node.GetFirstChild())
		If Not child Then Return Null
		
		While child
			If AsciiNamesLCAreEqual(_nodeName, child.getName()) Then Return child
			child = child.NextSibling()
		Wend
		
		Return Null
	End Function


	Function FindAttribute:String(node:TxmlNode, attributeName:String, defaultValue:String)
		Local attributeExists:Int
		Local result:String = GetAttribute(node, attributeName, attributeExists)
		If attributeExists Then Return result
		Return defaultValue
	End Function


	'search for an attribute
	'(compared to node.HasAttribute() this is NOT case sensitive!)
	Function HasAttribute:Int(node:TxmlNode, fieldName:String)
		If Not node Then Return False

		Return node.HasAttribute(fieldName, True)

rem
		For Local attribute:TxmlAttribute = EachIn node.GetAttributeList()
			If AsciiNamesLCAreEqual(fieldName, attribute.GetName()) then Return True
		Next

		Return False
endrem
	End Function


	'returns the value of an attribute
	'(compared to node.GetAttribute() this is NOT case sensitive!)
	Function GetAttribute:String(node:TxmlNode, fieldName:String)
		Local exists:Int
		Return GetAttribute(node, fieldName, exists)
	End Function


	'variant allowing to retrieve the existence-status
	'this allows skipping a HasAttribute() check before getting the value
	Function GetAttribute:String(node:TxmlNode, fieldName:String, attributeExists:Int Var)
		Local res:String
rem
		Local att:TObjectList = node.GetAttributeList()
'		Local fieldNameLS:TLowerString = TLowerString.Create(fieldName)
		For Local attribute:TxmlAttribute = EachIn att
'			Local attributeName:String = attribute.GetName()
'			If fieldNameLS.EqualsLower(attributeName) 
			If AsciiNamesLCAreEqual(fieldName, attribute.GetName())
				attributeExists = True
				'Return attribute.GetValue()
				res = attribute.GetValue()
				exit
			EndIf
		Next
endrem
		attributeExists = node.tryGetAttribute(fieldName, res, True)
		Return res
		
'		attributeExists = False
'		Return ""
	End Function


	'find a value within:
	'- the current NODE's attributes
	'  <obj FIELDNAME="bla" />
	'- the first level children
	'  <obj><FIELDNAME>bla</FIELDNAME><anotherfield ...></anotherfield></obj>
	'- in one of the children defined in "searchInChildNodeNames" (recursive!)
	'  ["other"] or ["*"]
	'  <obj><other><FIELDNAME>bla</FIELDNAME></other></obj>
	Function FindValue:String(node:TxmlNode, fieldName:String, defaultValue:String, logString:String="", searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
		Local exists:Int
		Return FindValue(node, fieldName, defaultValue, exists, logString, searchInChildNodeNames, searchInChildNodeAttributes, depth)
	End function
	

	Function FindValue:String(node:TxmlNode, fieldName:String, defaultValue:String, valueExists:Int var, logString:String="", searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
		If node
			'loop through all potential fieldnames ("frames|f" -> "frames", "f")
			If fieldName.Find("|") > 0
				Local fieldNames:String[] = fieldName.ToLower().Split("|")

				For Local name:String = EachIn fieldNames
					Local result:String = _FindValueInternalLC(node, name, defaultValue, valueExists, searchInChildNodeNames, searchInChildNodeAttributes, depth)
					if valueExists Then Return result
				Next
			Else
				fieldName = fieldName.ToLower()
				Local result:String = _FindValueInternalLC(node, fieldName, defaultValue, valueExists, searchInChildNodeNames, searchInChildNodeAttributes, depth)
				if valueExists Then Return result
			EndIf
		EndIf

		If logString <> "" Then Print logString
		valueExists = False

		Return defaultValue
	End Function
	
	
	Function _FindValueInternalLC_NEW:String(node:TxmlNode, nameLC:String, defaultValue:String, valueExists:Int var, searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
'295000 -- eigentlich alle mit "depth = 0", also nicht-rekursive Aufrufe

		'given node has attribute (<episode number="1">)
		If depth = 0 or searchInChildNodeAttributes
			Local attributeExists:Int
			Local result:String = GetAttribute(node, nameLC, attributeExists)
			if attributeExists 
				valueExists = True
				Return result
			EndIf
		EndIf
		
		' to look things up we need the first child of the node,
		' and use this as starting point for lookups (eg find things on
		' same level/depth without descending
		Local firstChild:TXmlNode = TXmlNode(node.GetFirstChild())
		If Not firstChild
			valueExists = False
			Return defaultValue
		EndIf

		Local childNode:TXmlNode
		Local dataNode:TXmlNode


		' is there a child-node with this name?
		childNode = firstChild
		While childNode
			If AsciiNamesLCAreEqual(nameLC, childNode.GetName())
				valueExists = True
				Return childNode.GetContent()
			EndIf
			childNode = childNode.NextSibling()
		Wend


		' is there a data-node with this name?
		childNode = firstChild
		While childNode
			If AsciiNamesLCAreEqual("data", childNode.GetName())
				Local result:String
				Local attributeExists:Int = childNode.tryGetAttribute(nameLC, result, True)
				If attributeExists
					valueExists = True
					Return result
				EndIf
			EndIf
			childNode = childNode.NextSibling()
		Wend

		
		' search in whitelisted child node names (or "*" all)
		If searchInChildNodeNames.length > 0
			local checkAll:Int = (searchInChildNodeNames[0] = "*")
			'iterate over all direct children

			childNode = firstChild
			While childNode
				Local inArray:Int = InAsciiNamesLCArray(childNode.GetName(), searchInChildNodeNames)
				
				if checkAll or inArray
					Local result:String = _FindValueInternalLC_NEW(childNode, nameLC, defaultValue, valueExists, searchInChildNodeNames, searchInChildNodeAttributes, depth)
					If valueExists
						Return result
					EndIf
				EndIf
				childNode = childNode.NextSibling()
			Wend
		EndIf

		valueExists = False
		Return defaultValue
	End Function

	'node/attribute name must be lowercased already!
	Function _FindValueInternalLC:String(node:TxmlNode, nameLC:String, defaultValue:String, valueExists:Int var, searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
'		Local vExists1:Int
		Local vExists2:Int

'		Local result1:String = _FindValueInternalLC_OLD(node, nameLC, defaultValue, vExists1, searchInChildNodeNames, searchInChildNodeAttributes, depth)
		Local result2:String = _FindValueInternalLC_NEW(node, nameLC, defaultValue, vExists2, searchInChildNodeNames, searchInChildNodeAttributes, depth)
	
'		if result1 <> result2
'			Throw "Node ~q"+node.GetName() +"~q differs for ~q" + nameLC + "~q   result1=~q"+result1+"~q   result2=~q"+result2+"~q  defaultValue=~q"+defaultValue+"~q.  node=" + node.GetContent()
'		EndIf
		
'		valueExists = vExists1
'		Return result1
		valueExists = vExists2
		Return result2
	End Function
	
	Function _FindValueInternalLC_OLD:String(node:TxmlNode, nameLC:String, defaultValue:String, valueExists:Int var, searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
		'given node has attribute (<episode number="1">)
		If depth = 0 or searchInChildNodeAttributes
			Local attributeExists:Int
			Local result:String = GetAttribute(node, nameLC, attributeExists)
			if attributeExists 
				valueExists = True
				Return result
			EndIf
		EndIf

		For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
			Local subNodeName:String = subNode.GetName()
			If nameLC.length = subNodeName.length and nameLC = subNodeName.ToLower() 
				valueExists = True
				Return subNode.GetContent()
			EndIf
			If AsciiNamesLCAreEqual("data", subNodeName) 
				Local attributeExists:Int
				Local result:String = GetAttribute(subNode, nameLC, attributeExists)
				If attributeExists
					valueExists = True
					Return result
				EndIf
			EndIf
			If searchInChildNodeNames And searchInChildNodeNames.length > 0
				If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNode.getName(), searchInChildNodeNames, False)
					Return _FindValueInternalLC_OLD(subNode, nameLC, defaultValue, valueExists, searchInChildNodeNames, searchInChildNodeAttributes, depth + 1)
				EndIf
			EndIf
		Next
		valueExists = False
		
		Return defaultValue
	End Function


	'loads values of a node into a tdata object
	Function LoadValuesToData:TData(node:TxmlNode, data:TData, fieldNames:String[], searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, overwriteExisting:Int = True)
		If Not node Then Return data

		For Local fieldName:String = EachIn fieldNames
			'use the first fieldname ("frames|f" -> add as "frames")
			Local splitPos:Int = fieldName.Find("|")
			Local firstFieldName:String = fieldName
			if splitPos >= 0 Then firstFieldName = fieldName[.. splitPos]

			Local exists:Int
			Local value:String = FindValue(node, fieldName, "", exists, "", searchInChildNodeNames, searchInChildNodeAttributes)
			If not exists Then Continue
		
			'if name is occupied -> convert to array and append
			If Not overwriteExisting And data.Has(firstFieldName)
				Local old:Object = data.Get(firstFieldName)
				Local arr:Object[] = Object[](old)
				If Not arr Then arr = New Object[0]

				arr :+ [value]
				data.Add(firstFieldName, arr)
			Else
				data.Add(firstFieldName, value)
			EndIf
		Next
		Return data
	End Function


	'loads values of a node into a TDataCSK object
	'fieldNames original casing will be used as storage key!
	Function LoadValuesToDataCSK:TDataCSK(node:TxmlNode, data:TDataCSK, fieldNames:String[], searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, overwriteExisting:Int = True)
		If Not node Then Return data

		For Local fieldName:String = EachIn fieldNames
			'use the first fieldname ("frames|f" -> add as "frames")
			Local splitPos:Int = fieldName.Find("|")
			Local firstFieldName:String = fieldName
			if splitPos >= 0 Then firstFieldName = fieldName[.. splitPos]

			Local exists:Int
			Local value:String = FindValue(node, fieldName, "", exists, "", searchInChildNodeNames, searchInChildNodeAttributes)
			If not exists Then Continue
			
			'if name is occupied -> convert to array and append
			If Not overwriteExisting And data.Has(firstFieldName)
				Local old:Object = data.Get(firstFieldName)
				Local arr:Object[] = Object[](old)
				If Not arr Then arr = New Object[0]

				arr :+ [value]
				data.Add(firstFieldName, arr)
			Else
				data.Add(firstFieldName, value)
			EndIf
		Next
		Return data
	End Function


	'loads values of a node into a tdata object
	Function LoadAllValuesToData:TData(node:TxmlNode, data:TData, ignoreNames:String[] = Null)
'		Local resultOLD:TData = LoadAllValuesToData_OLD(node, data, ignoreNames)
		Local result:TData = LoadAllValuesToData_NEW(node, data, ignoreNames)
		
'		if resultOLD.ToString() <> result.ToString()
'			Throw "differs: " + node.GetName()
'		EndIf
		Return result
	End Function


	Function LoadAllValuesToData_NEW:TData(node:TxmlNode, data:TData, ignoreNames:String[] = Null)
		If Not node Then Return data

		'=== ATTRIBUTES ===
		Local attributeCount:Int = node.getAttributeCount()
		For Local i:Int = 0 Until attributeCount
			Local name:String
			Local value:String = node.getAttributeByIndex(i, name)

			If ignoreNames.length > 0 And InAsciiNamesLCArray(name, ignoreNames) Then Continue

			data.Add(name, value)
		Next


		'=== CHILD ELEMENTS ===
		' count only "valid" children (unignored, no comments)
		Local childrenCount:Int
		Local child:TxmlNode = TxmlNode(node.GetFirstChild())
		If child
			While child
				Local childNodeName:String = child.getName()
				' skip comments
				If childNodeName And childNodeName[0] = Asc("<") And childNodeName.Find("<!--") = 0 Then Continue
				' skip ignored
				If InAsciiNamesLCArray(childNodeName, ignoreNames) Then Continue

				childrenCount :+ 1
				
				Local childData:TData = New TData
				LoadAllValuesToData_NEW(child, childData, ignoreNames)
				data.Add(childNodeName, childData)

				child = child.NextSibling()
			Wend
		EndIf

		' if a child has NO attributes and NO children then its
		' own value is added directly, else their attibutes or
		' children are added as "sub data" entries recursively.
		if attributeCount = 0 And childrenCount = 0
			data.Add(node.getName(), node.GetContent())
		EndIf
		
		Return data
	End Function


	Function LoadAllValuesToData_OLD:TData(node:TxmlNode, data:TData, ignoreNames:String[] = Null)
		If Not node Then Return data

		'=== ATTRIBUTES ===
		For Local attribute:TxmlAttribute = EachIn node.GetAttributeList()
			If ignoreNames.length > 0 And StringHelper.InArray(attribute.GetName(), ignoreNames, False) Then Continue
			data.Add(attribute.GetName(), attribute.GetValue())
		Next

		'=== CHILD ELEMENTS ===
		For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
			Local subNodeName:String = subNode.getName()
			' skip comments
			If subNodeName And subNodeName[0] = Asc("<") And subNodeName.Find("<!--") = 0 Then Continue
			' skip ignored
			If StringHelper.InArray(subNodeName, ignoreNames, False) Then Continue

			Local children:Int = subNode.GetAttributeList().Count()
			If children = 0
				Local childList:TObjectList = subNode.GetChildren()
				If childList Then children = childList.Count()
			EndIf

			If children > 0
				Local subData:TData = New TData
				LoadAllValuesToData_OLD(subNode, subData, ignoreNames)

				data.Add(subNode.getName(), subData)
			Else
				data.Add(subNodeName, subNode.GetContent())
			EndIf
		Next
		Return data
	End Function


	Function _FindElementNode:TxmlNode(startNode:TxmlNode, nodeName:String)
'		Local node_OLD:TxmlNode = _FindElementNode_OLD(startNode, nodeName)
		Local node_NEW:TxmlNode = _FindElementNode_NEW(startNode, nodeName)
'		If node_OLD <> node_New 'different TXmlNode objects - except for NULL
'			If node_OLD.GetName() <> node_NEW.GetName() 'also different node name required
'				Throw "_FindElementNode differs: " + startNode.getName() + "  nodeName="+nodeName
'			EndIf
'		EndIf
		Return node_NEW
	End Function
	

	Function _FindElementNode_NEW:TxmlNode(startNode:TxmlNode, nodeName:String)
		If Not startNode Then Return Null

		'maybe we are searching for start node
		If AsciiNamesLCAreEqual(nodeName, startNode.getName()) Then Return startNode

		'traverse through children
		Local child:TXmlNode = TXmlNode(startNode.GetFirstChild())
		If child
			While child
				Local result:TxmlNode = _FindElementNode_NEW(child, nodeName)
				If result Then Return result

				child = child.NextSibling()
			Wend
		EndIf
		Return Null
	End Function


	Function _FindElementNode_OLD:TxmlNode(startNode:TxmlNode, nodeName:String)
		If Not startNode Then Return Null

		'maybe we are searching for start node
		If AsciiNamesLCAreEqual(nodeName, startNode.getName()) Then Return startNode

		'traverse through children
		For Local child:TxmlNode = EachIn GetNodeChildElements(startNode)
			Local result:TxmlNode = _FindElementNode_OLD(child, nodeName)
			If result Then Return result
		Next
		Return Null
	End Function


	Function GetLocalizedStringFromNode:TLocalizedString(node:TxmlNode)
		if not node then return Null


		local localized:TLocalizedString
		Local nodeLangEntry:TxmlNode = TxmlNode(node.GetFirstChild())
		While nodeLangEntry
			If Not localized Then localized = New TLocalizedString

			'do not trim, as this corrupts variables like "<de> %WORLDTIME:YEAR%</de>" (with space!)
			local value:String = nodeLangEntry.getContent() '.Trim()

			if value <> ""
				local language:String = nodeLangEntry.GetName().ToLower()
				localized.Set(value, TLocalization.GetLanguageID(language))
			endif
			
			nodeLangEntry = nodeLangEntry.NextSibling()
		Wend

		return localized 'can be null!
	End Function



	Function FindValueInt:Int(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local exists:Int
		Local result:String = FindValue(node, fieldName, "", exists, logString, searchInChildNodeNames)
		If Not exists Then Return defaultValue
		Return Int( result )
	End Function


	Function FindValueFloat:Float(node:TxmlNode, fieldName:String, defaultValue:Float, logString:String="", searchInChildNodeNames:String[] = Null)
		Local exists:Int
		Local result:String = FindValue(node, fieldName, "", exists, logString, searchInChildNodeNames)
		If Not exists Then Return defaultValue
		Return Float( result )
	End Function


	Function FindValueBool:Float(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local exists:Int
		Local result:String = FindValue(node, fieldName, "", exists, logString, searchInChildNodeNames)
		If exists
			If result = "0" Then Return False
			If result = "1" Then Return True
			If AsciiNamesLCAreEqual(result, "false") Then Return False 
			If AsciiNamesLCAreEqual(result, "true") Then Return True
		Else
			Return defaultValue
		EndIf
	End Function


	'GETTERS
	Function GetNodeDepth:Int(node:TxmlNode)
		If node And node.GetParent()
			Local depth:Int = 0
			Local nextParent:TxmlNode = node.GetParent()

			While nextParent
				depth :+ 1
				nextParent = nextParent.GetParent()
			Wend

			'ignore "root" -> subtract -1
			Return depth -1
		EndIf

		Return 0
	End Function


	Function GetNode:TxmlNode(startNode:TxmlNode, path:String, createIfMissing:Int = False)
		If Not startNode Then Return Null

		Local branches:String[] = path.ToLower().split("/")
		Local currentNode:TxmlNode = startNode
		Local nextNode:TxmlNode
		For Local branch:String = EachIn branches
			nextNode = _FindElementNode(currentNode, branch)

			If Not nextNode
				If Not createIfMissing Then Return Null

				'one deeper than the upcoming </...>-closing tag
				If currentNode.GetContent().Find("~n") < 0
					currentNode.AddContent("~n")
					currentNode.AddContent( RSet("", GetNodeDepth(currentNode)).Replace(" ", "~t") )
				EndIf
				currentNode.AddContent("~t")

				nextNode = currentNode.AddChild(branch)
				'new line
				currentNode.AddContent("~n")
				'move the upcoming </...>-closing tag into position again
				currentNode.AddContent( RSet("", GetNodeDepth(currentNode)).Replace(" ", "~t") )
			EndIf

			currentNode = nextNode
		Next

		Return currentNode
	End Function


	'SETTERS / WRITERS
	Function SetNodeContent:Int(path:String, value:String, startNode:TxmlNode)
		Local node:TxmlNode = GetNode(startNode, path, True)

		If node
			node.SetContent(value)
			Return True
		EndIf

		Return False
	End Function


	Function SetNodeAttribute:Int(path:String, name:String, value:String, startNode:TxmlNode)
		Local node:TxmlNode
		If path
			node = GetNode(startNode, path, True)
		Else
			node = startNode
		EndIf

		If node
			If node.HasAttribute(name)
				node.SetAttribute(name, value)
			Else
				node.AddAttribute(name, value)
			EndIf
			Return True
		EndIf

		Return False
	End Function


	Function RemoveNode:Int(node:TxmlNode)
		If node
			'removing a node does _not_ remove potentially prepended
			'whitespace (and the appended newline)

			'so we remove every sibling before until we reach another "node element"
			'(whitespace is "text node" but we want to remove comments a now
			' deleted node too )
			Local prevNode:TxmlNode = TxmlNode(node.previousSibling())
			'mxml only returns "elements"
			'If prevNode And prevNode.GetType() <> XML_ELEMENT_NODE Then RemoveNode(prevNode)
			If prevNode Then RemoveNode(prevNode)

'			node.free()
			Return True
		EndIf
		Return False
	End Function


	Function _GetRootNode:TxmlNode(node:TxmlNode)
		If Not node Then Return null

		Local parent:TxmlNode = node.GetParent()
		If not parent Then Return node

		While parent And parent.GetParent()
			parent = parent.GetParent()
		Wend
		Return parent
	End Function
End Type
