Rem
	====================================================================
	class providing helpers for XML files
	====================================================================

	Various helper functions to ease work with XML files.

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
EndRem
SuperStrict
Import Brl.Standardio
Import "external/libxml/libxml.bmx"
Import "base.util.data.bmx"
Import "base.util.string.bmx"
Import Brl.Retro 'for filesize


Type TXmlHelper
	Field filename:String =""
	Field xmlDoc:TxmlDoc
	Global dataLS:TLowerString = TLowerString.Create("data")

	Function Create:TXmlHelper(filename:String, rootNode:String="", createIfMissing:Int=True)
		Local obj:TXmlHelper = New TXmlHelper
		obj.LoadDocument(filename, rootNode, createIfMissing)

		return obj
	End Function


	Method LoadDocument:TxmlDoc(filename:String, rootNode:String="", createIfMissing:Int=True)
		'reset old values
		if self.xmlDoc
			xmlDoc.free()
		endif
		self.xmlDoc = null

		If FileSize(filename) >= 0
			self.filename = filename
			self.xmlDoc = TxmlDoc.parseFile(filename)
		Else
			self.filename = filename

			'try to load it via a stream (maybe SDL wants to help out)
			Local stream:TStream = OpenStream(filename)
			If stream
				self.xmlDoc = TxmlDoc.ReadDoc(stream)
				stream.Close()
			EndIf
		EndIf


		If not xmlDoc
			If createIfmissing
				self.xmlDoc = CreateDocument(rootNode)
			Else
				If FileSize(filename) >= 0
					Print "Document ~~"+filename+"~~ not parsed successfully."
				Else
					Print "Document ~~"+filename+"~~ not found."
					Return Null
				EndIf
			EndIf
		EndIf

		Return self.xmlDoc
	End Method


	Function CreateFromString:TXmlHelper(content:String, rootNode:String="")
		Local obj:TXmlHelper = New TXmlHelper
		obj.filename = "memory"
		obj.xmlDoc = TxmlDoc.parseDoc(content)
		Return obj
	End Function


	Function CreateDocument:TXmlDoc(rootNodeName:string = "")
		local xmlDoc:TXmlDoc = TxmlDoc.newDoc("1.0")
		If rootNodeName <> "" Then CreateRootNode(xmlDoc, rootNodeName)

		return xmlDoc
	End Function


	Method GetRootNode:TxmlNode()
		If xmlDoc Then Return xmlDoc.getRootElement()
		Return Null
	End Method


	Function CreateRootNode:TxmlNode(document:TXmlDoc, key:String)
		if not document then return Null

		If key = "" Then key = "root"
		Local result:TxmlNode = TxmlNode.newNode(key)
		'add a new line within <key></key>" so children get added on
		'the next line
		result.AddContent("~n")

		'add as root
		document.setRootElement(result)

		Return result
	End Function


	Function _FindElementNodeLS:TxmlNode(startNode:TXmlNode, nodeName:TLowerString)
		If Not startNode Then Return Null

		'maybe we are searching for start node
		If nodeName.EqualsLower(startNode.getName()) Then Return startNode

		'traverse through children
		For Local child:TxmlNode = EachIn GetNodeChildElements(startNode)
			If nodeName.EqualsLower(child.getName()) Then Return child
			For Local subStartNode:TxmlNode = EachIn GetNodeChildElements(child)
				Local subChild:TXmlNode = _FindElementNodeLS(subStartNode, nodeName)
				If subChild Then Return subChild
			Next
		Next
		Return Null
	End Function


	'find a "<tag>"-element within a given start node
	Function FindElementNode:TxmlNode(startNode:TXmlNode, _nodeName:String)
		local nodeName:TLowerString = TLowerString.Create(_nodeName)
		return _FindElementNodeLS(startNode, nodeName)
rem
		nodeName = nodeName.ToLower()
		If Not startNode Then startNode = GetRootNode()
		If Not startNode Then Return Null

		'maybe we are searching for start node
		If startNode.getName().ToLower() = nodeName Then Return startNode

		'traverse through children
		For Local child:TxmlNode = EachIn GetNodeChildElements(startNode)
			If child.getName().ToLower() = nodeName Then Return child
			For Local subStartNode:TxmlNode = EachIn GetNodeChildElements(child)
				Local subChild:TXmlNode = FindElementNode(subStartNode, nodeName)
				If subChild Then Return subChild
			Next
		Next
		Return Null
end rem
	End Function


	Method FindElementNodeLS:TxmlNode(startNode:TXmlNode, nodeName:TLowerString)
		If Not startNode Then startNode = GetRootNode()
		return _FindElementNodeLS(startNode, nodeName)
	End Method


	Method FindRootChild:TxmlNode(nodeName:String)
		Return FindChild(GetRootNode(), nodeName)
	End Method


	Function FindAttribute:String(node:TxmlNode, attributeName:String, defaultValue:String)
		If HasAttribute(node, attributeName) Then Return GetAttribute(node, attributeName) Else Return defaultValue
	End Function


	'returns a list of all child elements (one level deeper)
	'in comparison to "txmlnode.GetChildren()" it returns a TList
	'in all cases.
	Function GetNodeChildElements:TList(node:TxmlNode)
		'we only want "<ELEMENTS>"
		Local res:TList
		If node Then res = node.GetChildren(XML_ELEMENT_NODE)
		If Not res Then res = CreateList()
		Return res
	End Function


	'non recursive child finding
	Function FindChild:TxmlNode(node:TxmlNode, _nodeName:String)
		If Not node Then Return Null
		Local nodeName:TLowerString = TLowerString.Create(_nodeName)
		For Local child:TxmlNode = EachIn GetNodeChildElements(node)
			If nodeName.EqualsLower(child.getName()) Then Return child
		Next
		Return Null
	End Function


	'loads values of a node into a tdata object
	Function LoadValuesToData:TData(node:TXmlNode, data:TData, fieldNames:String[], searchInChildNodeNames:String[] = Null)
		If Not node Then Return data

		For Local fieldName:String = EachIn fieldNames
			If Not TXmlHelper.HasValue(node, fieldName, searchInChildNodeNames) Then Continue
			'use the first fieldname ("frames|f" -> add as "frames")
			Local names:String[] = fieldName.Split("|")
			data.Add(names[0], FindValue(node, fieldName, "", "", searchInChildNodeNames))
		Next
		Return data
	End Function


	'loads values of a node into a tdata object
	Function LoadAllValuesToData:TData(node:TXmlNode, data:TData, ignoreNames:String[] = Null)
		If Not node Then Return data

		'=== ATTRIBUTES ===
		For Local attribute:TxmlAttribute = EachIn node.GetAttributeList()
			If StringHelper.InArray(attribute.GetName(), ignoreNames, False) Then Continue
			data.Add(attribute.GetName(), node.GetAttribute(attribute.GetName()))
		Next


		'=== CHILD ELEMENTS ===
		For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
			local children:int = subNode.GetAttributeList().Count()
			if children = 0
				local childList:TList = subNode.GetChildren()
				if childList then children = childList.Count()
			endif

			If StringHelper.InArray(subNode.GetName(), ignoreNames, False) Then Continue

			If dataLS.EqualsLower(subNode.getName()) or children > 0
				Local subData:TData = New TData
				LoadAllValuesToData(subNode, subData, ignoreNames)
				if dataLS.EqualsLower(subNode.getName())
					data.Add(dataLS, subData)
				else
					data.Add(subNode.getName(), subData)
				endif
			else
				data.Add(subNode.getName(), subNode.getContent())
			endif
		Next
		Return data
	End Function


	'search for an attribute
	'(compared to node.HasAttribute() this is NOT case sensitive!)
	Function HasAttribute:Int(node:TXmlNode, fieldName:String)
		If Not node Then Return False

		Local att:TList = node.GetAttributeList()
		Local name:TLowerString = TLowerString.Create(fieldName)
		For Local attribute:TxmlBase = EachIn att
			If name.EqualsLower(attribute.GetName()) Then Return True
		Next

		Return False
	End Function


	'returns the value of an attribute
	'(compared to node.GetAttribute() this is NOT case sensitive!)
	Function GetAttribute:String(node:TXmlNode, _fieldName:String)
		Local att:TList = node.GetAttributeList()
		local fieldName:TLowerString = TLowerString.Create(_fieldName)
		'fieldName = fieldName.ToLower()
		For Local attribute:TxmlBase = EachIn att
			If fieldName.EqualsLower(attribute.GetName()) Then Return node.GetAttribute(attribute.GetName())
		Next
		Return ""
	End Function


	Function _SetNodeContent:int(path:string, value:string, startNode:TXmlNode)
		local node:TXmlNode = _GetNode(startNode, path, True)

		if node
			node.SetContent(value)
			return True
		endif

		return False
	End Function


	Function _SetNodeAttribute:int(path:string, name:string, value:string, startNode:TXmlNode)
		local node:TXmlNode
		if path
			node = _GetNode(startNode, path, True)
		else
			node = startNode
		endif

		if node
			node.SetAttribute(name, value)
			return True
		endif

		return False
	End Function


	Function GetNodeDepth:int(node:TXmlBase)
		if node and node.GetParent()
			local depth:int = 0
			local nextParent:TXmlBase = node.GetParent()

			while nextParent
				depth :+ 1
				nextParent = nextParent.GetParent()
			wend

			'ignore "root" -> subtract -1
			return depth -1
		endif

		return 0
	End Function


	Function _GetNode:TXmlNode(startNode:TXmlNode, path:string, createIfMissing:int = False)
		if not startNode then return Null

		local branches:string[] = path.ToLower().split("/")
		local currentNode:TXmlNode = startNode
		local nextNode:TXmlNode
		for local branch:string = EachIn branches
			nextNode = TxmlHelper.FindElementNode(currentNode, branch)

			if not nextNode
				'one deeper than the upcoming </...>-closing tag
				if currentNode.GetText().Find("~n") < 0
					currentNode.AddContent("~n")
					currentNode.AddContent( RSet("", GetNodeDepth(currentNode)).Replace(" ", "~t") )
				endif
				currentNode.AddContent("~t")

				nextNode = currentNode.AddTextChild(branch)
				'new line
				currentNode.AddContent("~n")
				'move the upcoming </...>-closing tag into position again
				currentNode.AddContent( RSet("", GetNodeDepth(currentNode)).Replace(" ", "~t") )
			endif

			currentNode = nextNode
		Next

		return currentNode
	End Function


	Method GetNode:TXmlNode(startNode:TXmlNode, path:string, createIfMissing:int = False)
		if not startNode then startNode = GetRootNode()

		return _GetNode(startNode, path, createIfMissing)
	End Method


	Function RemoveNode:int(node:TXmlNode)
		if node
			'removing a node does _not_ remove potentially prepended
			'whitespace (and the appended newline)

			'so we remove every sibling before until we reach another "node element"
			'(whitespace is "text node" but we want to remove comments a now
			' deleted node too )
			local prevNode:TxmlNode = TxmlNode(node.previousSibling())
			if prevNode and prevNode.GetType() <> XML_ELEMENT_NODE then RemoveNode(prevNode)

			node.unlinkNode()
			node.freeNode()
			return True
		endif
		return False
	End Function


	Function RemoveNodeAttribute:int(node:TXmlNode, attributeKey:string)
		if node
			Select node.unsetAttribute(attributeKey)
				case 0
					return True
				case -1
					return False 'not found
			End Select
		endif
		return False
	End Function


	Function HasValue:Int(node:TXmlNode, fieldName:String, searchInChildNodeNames:String[] = Null)
		If Not node Then Return False

		'loop through all potential fieldnames ("frames|f" -> "frames", "f")
		Local fieldNames:String[] = fieldName.ToLower().Split("|")

		For Local name:String = EachIn fieldNames
			If HasAttribute(node, name) Then Return True

			For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
				If subNode.getType() = XML_TEXT_NODE Then Continue
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


	'find a value within:
	'- the current NODE's attributes
	'  <obj FIELDNAME="bla" />
	'- the first level children
	'  <obj><FIELDNAME>bla</FIELDNAME><anotherfield ...></anotherfield></obj>
	'- in one of the children defined in "searchInChildNodeNames" (recursive!)
	'  ["other"] or ["*"]
	'  <obj><other><FIELDNAME>bla</FIELDNAME></other></obj>
	Function FindValue:String(node:TxmlNode, fieldName:String, defaultValue:String, logString:String="", searchInChildNodeNames:String[] = Null)
		If node
			'loop through all potential fieldnames ("frames|f" -> "frames", "f")
			Local fieldNames:String[] = fieldName.ToLower().Split("|")

			For Local name:String = EachIn fieldNames
				'given node has attribute (<episode number="1">)
				If HasAttribute(node, name) Then Return GetAttribute(node, name)

				For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
					If subNode.getName().ToLower() = name Then Return subNode.getContent()
					If dataLS.EqualsLower(subNode.getName()) And HasAttribute(subNode, name) Then Return GetAttribute(subNode, name)
					If searchInChildNodeNames And searchInChildNodeNames.length > 0
						If searchInChildNodeNames[0] = "*" Or StringHelper.InArray(subNode.getName(), searchInChildNodeNames, False)
							Return FindValue(subNode, fieldName, defaultValue, logString, searchInChildNodeNames)
						EndIf
					EndIf
				Next
			Next
		EndIf
		If logString <> "" Then Print logString
		Return defaultValue
	End Function


	Function FindValueInt:Int(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString, searchInChildNodeNames)
		If result = Null Then Return defaultValue
		Return Int( result )
	End Function


	Function FindValueFloat:Float(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="", searchInChildNodeNames:String[] = Null)
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString, searchInChildNodeNames)
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
End Type
