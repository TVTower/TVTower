Rem
	====================================================================
	class providing helpers for XML files
	====================================================================

	Various helper functions to ease work with XML files.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

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



Type TXmlHelper
	Field filename:String =""
	Field xmlDoc:TxmlDoc
	Global dataLS:TLowerString = TLowerString.Create("data")

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
	'in comparison to "txmlnode.GetChildren()" it returns a TList
	'in all cases.
	Function GetNodeChildElements:TList(node:TxmlNode)
		'we only want "<ELEMENTS>"
		If Not node Then Return CreateList()
		Return node.getChildren()
	End Function



	'find a "<tag>"-element within a given start node
	Function FindElementNode:TxmlNode(startNode:TxmlNode, _nodeName:String)
		Local nodeName:TLowerString = TLowerString.Create(_nodeName)
		Return _FindElementNodeLS(startNode, nodeName)
	End Function


	Method FindElementNodeLS:TxmlNode(startNode:TxmlNode, nodeName:TLowerString)
		If Not startNode Then startNode = GetRootNode()
		Return _FindElementNodeLS(startNode, nodeName)
	End Method


	Method FindRootChild:TxmlNode(nodeName:String)
		Return FindChild(GetRootNode(), nodeName)
	End Method


	Method FindRootChildLC:TxmlNode(nodeNameLC:String)
		Return FindChildLC(GetRootNode(), nodeNameLC)
	End Method


	'non recursive child finding
	Function FindChild:TxmlNode(node:TxmlNode, _nodeName:String)
		If Not node Then Return Null
		Local nodeName:TLowerString = TLowerString.Create(_nodeName)
		For Local child:TxmlNode = EachIn GetNodeChildElements(node)
			If nodeName.EqualsLower(child.getName()) Then Return child
		Next
		Return Null
	End Function


	'same as FindChild() but assuming nodeName to be LowerCase already
	Function FindChildLC:TxmlNode(node:TxmlNode, nodeNameLC:String)
		If Not node Then Return Null
		For Local child:TxmlNode = EachIn GetNodeChildElements(node)
			Local childName:String = child.getName()
			if nodeNameLC.length = childName.length And nodeNameLC = child.getName().ToLower() Then Return child
		Next
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

		Local att:TList = node.GetAttributeList()
		Local name:TLowerString = TLowerString.Create(fieldName)
		For Local attribute:TxmlAttribute = EachIn att
			If name.EqualsLower(attribute.GetName()) Then Return True
		Next

		Return False
	End Function


	'same as HasAttribute() but assuming fieldName is LowerCase
	Function HasAttributeLC:Int(node:TxmlNode, fieldNameLC:String)
		If Not node Then Return False

		Local att:TList = node.GetAttributeList()
		For Local attribute:TxmlAttribute = EachIn att
			Local attributeName:String = attribute.GetName()
			if fieldNameLC.length = attributeName.length and fieldNameLC = attributeName.ToLower() Then Return True
		Next

		Return False
	End Function


	'returns the value of an attribute
	'(compared to node.GetAttribute() this is NOT case sensitive!)
	Function GetAttribute:String(node:TxmlNode, fieldName:String)
		Local att:TList = node.GetAttributeList()
		Local fieldNameLS:TLowerString = TLowerString.Create(fieldName)
		'fieldName = fieldName.ToLower()
		For Local attribute:TxmlAttribute = EachIn att
			Local attributeName:String = attribute.GetName()
			If fieldNameLS.EqualsLower(attributeName) Then Return node.GetAttribute(attributeName)
		Next
		Return ""
	End Function


	'variant allowing to retrieve the existence-status
	'this allows skipping a HasAttribute() check before getting the value
	Function GetAttribute:String(node:TxmlNode, fieldName:String, attributeExists:Int Var)
		Local att:TList = node.GetAttributeList()
		Local fieldNameLS:TLowerString = TLowerString.Create(fieldName)
		For Local attribute:TxmlAttribute = EachIn att
			Local attributeName:String = attribute.GetName()
			If fieldNameLS.EqualsLower(attributeName) 
				attributeExists = True
				Return node.GetAttribute(attributeName)
			EndIf
		Next
		attributeExists = False
		Return ""
	End Function

	'same as GetAttribute() but assuming _fieldName is LowerCase
	Function GetAttributeLC:String(node:TxmlNode, fieldNameLC:String)
		Local att:TList = node.GetAttributeList()
		For Local attribute:TxmlAttribute = EachIn att
			Local attributeName:String = attribute.GetName()
			If fieldNameLC.length = attributeName.length and fieldNameLC = attributeName.ToLower() Then Return node.GetAttribute(attributeName)
		Next
		Return ""
	End Function


	'same as GetAttribute() but assuming _fieldName is LowerCase
	'this allows skipping a HasAttribute() check before getting the value
	Function GetAttributeLC:String(node:TxmlNode, fieldNameLC:String, attributeExists:Int Var)
		Local att:TList = node.GetAttributeList()
		For Local attribute:TxmlAttribute = EachIn att
			Local attributeName:String = attribute.GetName()
			If fieldNameLC.length = attributeName.length and fieldNameLC = attributeName.ToLower() 
				attributeExists = True
				Return node.GetAttribute(attributeName)
			EndIf
		Next
		attributeExists = False
		Return ""
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
		If node
			'loop through all potential fieldnames ("frames|f" -> "frames", "f")
			Local fieldNames:String[] = fieldName.ToLower().Split("|")

			For Local name:String = EachIn fieldNames
				'given node has attribute (<episode number="1">)
				If depth = 0 or searchInChildNodeAttributes
					Local attributeExists:Int
					Local result:String = GetAttribute(node, name, attributeExists)
					if attributeExists then Return result
				EndIf

				For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
					Local subNodeName:String = subNode.GetName()
					If name.length = subNodeName.length and name = subNodeName.ToLower() Then Return subNode.GetContent()
					If dataLS.EqualsLower(subNodeName) 
						Local attributeExists:Int
						Local result:String = GetAttribute(subNode, name, attributeExists)
						If attributeExists Then Return result
					EndIf
					If searchInChildNodeNames And searchInChildNodeNames.length > 0
						If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNode.getName(), searchInChildNodeNames, False)
							Return FindValue(subNode, fieldName, defaultValue, logString, searchInChildNodeNames, searchInChildNodeAttributes, depth + 1)
						EndIf
					EndIf
				Next
			Next
		EndIf
		If logString <> "" Then Print logString
		Return defaultValue
	End Function


	'same as FindValue but assuming fieldName is LowerCase already
	Function FindValueLC:String(node:TxmlNode, fieldNameLC:String, defaultValue:String, logString:String="", searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
		If node
			'loop through all potential fieldnames ("frames|f" -> "frames", "f")
			Local fieldNames:String[] = fieldNameLC.Split("|")

			For Local name:String = EachIn fieldNames
				'given node has attribute (<episode number="1">)
				If depth = 0 or searchInChildNodeAttributes
					Local attributeExists:Int
					Local result:String = GetAttributeLC(node, name, attributeExists)
					if attributeExists then Return result
				EndIf

				For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
					Local subNodeName:String = subNode.GetName()
					If name.length = subNodeName.length and name = subNodeName.ToLower() Then Return subNode.GetContent()
					If dataLS.EqualsLower(subNodeName) 
						Local attributeExists:Int
						Local result:String = GetAttributeLC(subNode, name, attributeExists)
						If attributeExists Then Return result
					EndIf
					If searchInChildNodeNames And searchInChildNodeNames.length > 0
						If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNodeName, searchInChildNodeNames, False)
							Return FindValueLC(subNode, fieldNameLC, defaultValue, logString, searchInChildNodeNames, searchInChildNodeAttributes, depth + 1)
						EndIf
					EndIf
				Next
			Next
		EndIf
		If logString <> "" Then Print logString
		Return defaultValue
	End Function



	'same as FindValue but assuming fieldName is LowerCase already
	'added value_exists so to check if defaultValue is returned (or just the same)
	Function FindValueLC:String(node:TxmlNode, fieldNameLC:String, defaultValue:String, value_exists:Int var, logString:String="", searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, depth:Int = 0)
		If node
			'loop through all potential fieldnames ("frames|f" -> "frames", "f")
			Local fieldNames:String[] = fieldNameLC.Split("|")

			For Local name:String = EachIn fieldNames
				'given node has attribute (<episode number="1">)
				If depth = 0 or searchInChildNodeAttributes
					Local attributeExists:Int
					Local result:String = GetAttributeLC(node, name, attributeExists)
					if attributeExists 
						value_exists = True
						Return result
					EndIf
				EndIf

				For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
					Local subNodeName:String = subNode.GetName()
					If name.length = subNodeName.length and name = subNodeName.ToLower() 
						value_exists = True
						Return subNode.GetContent()
					EndIf
					If dataLS.EqualsLower(subNodeName) 
						Local attributeExists:Int
						Local result:String = GetAttributeLC(subNode, name, attributeExists)
						If attributeExists 
							value_exists = True
							Return result
						EndIf
					EndIf
					If searchInChildNodeNames And searchInChildNodeNames.length > 0
						If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNodeName, searchInChildNodeNames, False)
							Return FindValueLC(subNode, fieldNameLC, defaultValue, value_exists, logString, searchInChildNodeNames, searchInChildNodeAttributes, depth + 1)
						EndIf
					EndIf
				Next
			Next
		EndIf
		If logString <> "" Then Print logString
		value_exists = False
		Return defaultValue
	End Function


	Function HasValue:Int(node:TxmlNode, fieldName:String, searchInChildNodeNames:String[] = Null)
		If Not node Then Return False

		'loop through all potential fieldnames ("frames|f" -> "frames", "f")
		Local fieldNames:String[] = fieldName.ToLower().Split("|")

		For Local name:String = EachIn fieldNames
			If HasAttribute(node, name) Then Return True

			For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
'				If subNode.getType() = MXML_SAX_COMMENT Then Continue
				'If subNode.getType() = XML_TEXT_NODE Then Continue
				If subNode.getName().ToLower() = name Then Return True
				If dataLS.EqualsLower(subNode.getName()) And HasAttribute(subNode, name) Then Return True
				If searchInChildNodeNames And searchInChildNodeNames.length > 0
					If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNode.getName(), searchInChildNodeNames, False)
						Return HasValue(subNode, fieldName, searchInChildNodeNames)
					EndIf
				EndIf
			Next
		Next
		Return False
	End Function


	'same as HasValue() but fieldName is LowerCase
	Function HasValueLC:Int(node:TxmlNode, fieldNameLC:String, searchInChildNodeNames:String[] = Null)
		If Not node Then Return False

		'loop through all potential fieldnames ("frames|f" -> "frames", "f")
		Local fieldNames:String[] = fieldNameLC.Split("|")

		For Local name:String = EachIn fieldNames
			If HasAttributeLC(node, name) Then Return True

			For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
'				If subNode.getType() = MXML_SAX_COMMENT Then Continue
				'If subNode.getType() = XML_TEXT_NODE Then Continue
				If subNode.getName().ToLower() = name Then Return True
				If dataLS.EqualsLower(subNode.getName()) And HasAttributeLC(subNode, name) Then Return True
				If searchInChildNodeNames And searchInChildNodeNames.length > 0
					If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNode.getName(), searchInChildNodeNames, False)
						Return HasValueLC(subNode, fieldNameLC, searchInChildNodeNames)
					EndIf
				EndIf
			Next
		Next
		Return False
	End Function


	'loads values of a node into a tdata object
	Function LoadValuesToData:TData(node:TxmlNode, data:TData, fieldNames:String[], searchInChildNodeNames:String[] = Null, searchInChildNodeAttributes:Int = False, overwriteExisting:Int = True)
		If Not node Then Return data

		For Local fieldName:String = EachIn fieldNames
			If Not TXmlHelper.HasValue(node, fieldName, searchInChildNodeNames) Then Continue
			'use the first fieldname ("frames|f" -> add as "frames")
			Local names:String[] = fieldName.Split("|")
			'if name is occupied -> convert to array and append
			If Not overwriteExisting And data.Has(names[0])
				Local old:Object = data.Get(names[0])
				Local arr:Object[] = Object[](old)
				If Not arr Then arr = New Object[0]

				arr :+ [FindValue(node, fieldName, "", "", searchInChildNodeNames, searchInChildNodeAttributes)]
				data.Add(names[0], arr)
			Else
				data.Add(names[0], FindValue(node, fieldName, "", "", searchInChildNodeNames, searchInChildNodeAttributes))
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

			Local value_exists:Int
			Local value:String = FindValueLC(node, fieldName, "", value_exists, "", searchInChildNodeNames, searchInChildNodeAttributes)
			If Not value_exists Then Continue
			
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
		If Not node Then Return data

		'=== ATTRIBUTES ===
		For Local attribute:TxmlAttribute = EachIn node.GetAttributeList()
			If StringHelper.InArray(attribute.GetName(), ignoreNames, False) Then Continue
			data.Add(attribute.GetName(), node.GetAttribute(attribute.GetName()))
		Next


		'=== CHILD ELEMENTS ===
		For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
			Local children:Int = subNode.GetAttributeList().Count()
			If children = 0
				Local childList:TList = subNode.GetChildren()
				If childList Then children = childList.Count()
			EndIf

			If StringHelper.InArray(subNode.GetName(), ignoreNames, False) Then Continue

			If dataLS.EqualsLower(subNode.getName()) Or children > 0
				Local subData:TData = New TData

				LoadAllValuesToData(subNode, subData, ignoreNames)
				Local subNodeName:String = subNode.getName()
				If dataLS.EqualsLower(subNodeName)
					data.Add(dataLS, subData)
				Else
					data.Add(subNodeName, subData)
				EndIf
			Else
				Local value:String = subNode.ToString()
				'skip comments
				If value  And value.Find("<!--") = 0 Then Continue

				data.Add(subNode.getName(), subNode.GetContent())
			EndIf
		Next
		Return data
	End Function



	Function _FindElementNodeLS:TxmlNode(startNode:TxmlNode, nodeName:TLowerString)
		If Not startNode Then Return Null

		'maybe we are searching for start node
		If nodeName.EqualsLower(startNode.getName()) Then Return startNode

		'traverse through children
		For Local child:TxmlNode = EachIn GetNodeChildElements(startNode)
			If nodeName.EqualsLower(child.getName()) Then Return child
			For Local subStartNode:TxmlNode = EachIn GetNodeChildElements(child)
				Local subChild:TxmlNode = _FindElementNodeLS(subStartNode, nodeName)
				If subChild Then Return subChild
			Next
		Next
		Return Null
	End Function


	Function GetLocalizedStringFromNode:TLocalizedString(node:TxmlNode)
		if not node then return Null

		local foundEntry:int = True
		local localized:TLocalizedString = new TLocalizedString
		For local nodeLangEntry:TxmlNode = EachIn GetNodeChildElements(node)
			local language:String = nodeLangEntry.GetName().ToLower()
			'do not trim, as this corrupts variables like "<de> %WORLDTIME:YEAR%</de>" (with space!)
			local value:String = nodeLangEntry.getContent() '.Trim()

			if value <> ""
				localized.Set(value, TLocalization.GetLanguageID(language))
				foundEntry = True
			endif
		Next

		if not foundEntry then return Null
		return localized
	End Function



	Function FindValueInt:Int(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString, searchInChildNodeNames)
		If result = Null Then Return defaultValue
		Return Int( result )
	End Function

	Function FindValueIntLC:Int(node:TxmlNode, fieldNameLC:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValueLC(node, fieldNameLC, String(defaultValue), logString, searchInChildNodeNames)
		If result = Null Then Return defaultValue
		Return Int( result )
	End Function


	Function FindValueFloat:Float(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString, searchInChildNodeNames)
		If result = Null Then Return defaultValue
		Return Float( result )
	End Function

	Function FindValueFloatLC:Float(node:TxmlNode, fieldNameLC:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValueLC(node, fieldNameLC, String(defaultValue), logString, searchInChildNodeNames)
		If result = Null Then Return defaultValue
		Return Float( result )
	End Function


	Function FindValueBool:Float(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString, searchInChildNodeNames)
		Select result.toLower()
			Case "0", "false"	Return False
			Case "1", "true"	Return True
		End Select
		Return defaultValue
	End Function

	Function FindValueBoolLC:Float(node:TxmlNode, fieldNameLC:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValueLC(node, fieldNameLC, String(defaultValue), logString, searchInChildNodeNames)
		Select result.toLower()
			Case "0", "false"	Return False
			Case "1", "true"	Return True
		End Select
		Return defaultValue
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
			nextNode = FindElementNode(currentNode, branch)

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
			print "SetNodeContent: " + value
			node.SetContent(value)
			print "       Content: " + node.GetContent()
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


	Function GetRootNode:TxmlNode(node:TxmlNode)
		If Not node Then Return null

		Local parent:TxmlNode = node.GetParent()
		If not parent Then Return node

		While parent And parent.GetParent()
			parent = parent.GetParent()
		Wend
		Return parent
	End Function
End Type
