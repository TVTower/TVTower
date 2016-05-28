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


	Function Create:TXmlHelper(filename:String, rootNode:String="", createIfMissing:Int=True)
		Local obj:TXmlHelper = New TXmlHelper
		if filesize(filename) >= 0
			obj.filename = filename
			obj.xmlDoc = TxmlDoc.parseFile(filename)
		else
			obj.filename = filename

			'try to load it via a stream (maybe SDL wants to help out)
			local stream:TStream = OpenStream(filename)
			if stream
				obj.xmlDoc = TxmlDoc.ReadDoc(stream)
				stream.Close()
			else
				if createIfmissing
					obj.xmlDoc = TxmlDoc.newDoc("1.0")
					if rootNode <> "" then obj.CreateRootNode(rootNode)
				endif
			endif
		endif
		Return obj
	End Function


	Function CreateFromString:TXmlHelper(content:String, rootNode:String="")
		Local obj:TXmlHelper = New TXmlHelper
		obj.filename = "memory"
		obj.xmlDoc = TxmlDoc.parseDoc(content)
		Return obj
	End Function


	Method GetRootNode:TxmlNode()
		if xmlDoc then return xmlDoc.getRootElement()
		return Null
	End Method


	Method CreateRootNode:TxmlNode(key:string)
		if key = "" then key = "root"
		local result:TxmlNode = TxmlNode.newNode(key)
		xmlDoc.setRootElement(result)
		'add a new line within <key></key>" so children get added on
		'the next line
		GetRootNode().AddContent("~n")
		return result
	End Method


	'find a "<tag>"-element within a given start node
	Method FindElementNode:TxmlNode(startNode:TXmlNode, nodeName:String)
		nodeName = nodeName.ToLower()
		If Not startNode Then startNode = GetRootNode()
		if Not startNode Then return Null

		'maybe we are searching for start node
		if startNode.getName().ToLower() = nodeName then return startNode

		'traverse through children
		For Local child:TxmlNode = EachIn GetNodeChildElements(startNode)
			If child.getName().ToLower() = nodeName Then Return child
			For Local subStartNode:TxmlNode = EachIn GetNodeChildElements(child)
				Local subChild:TXmlNode = FindElementNode(subStartNode, nodeName)
				If subChild Then Return subChild
			Next
		Next
		Return Null
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
	Function FindChild:TxmlNode(node:TxmlNode, nodeName:String)
		if not node then return Null
		nodeName = nodeName.ToLower()
		For Local child:TxmlNode = EachIn GetNodeChildElements(node)
			If child.getName().ToLower() = nodeName Then Return child
		Next
		Return Null
	End Function


	'loads values of a node into a tdata object
	Function LoadValuesToData:TData(node:TXmlNode, data:TData, fieldNames:String[])
		if not node then return data

		For Local fieldName:String = EachIn fieldNames
			If Not TXmlHelper.HasValue(node, fieldName) Then Continue
			'use the first fieldname ("frames|f" -> add as "frames")
			Local names:String[] = fieldName.ToLower().Split("|")

			data.Add(names[0], FindValue(node, fieldName, ""))
		Next
		return data
	End Function
	

	'loads values of a node into a tdata object
	Function LoadAllValuesToData:TData(node:TXmlNode, data:TData, ignoreNames:String[] = null)
		if not node then return data


		'=== ATTRIBUTES ===
		Local att:TList = node.GetAttributeList()
		For Local attribute:TxmlBase = EachIn att
			if StringHelper.InArray(attribute.GetName(), ignoreNames, False) then continue

			data.Add(attribute.GetName().toLower(), node.GetAttribute(attribute.GetName()))
		Next


		'=== CHILD ELEMENTS ===
		For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
			if StringHelper.InArray(subNode.GetName(), ignoreNames, False) then continue

			If subNode.getName().ToLower() = "data"
				local subData:TData = new TData
				LoadAllValuesToData(subNode, subData, ignoreNames)
				data.Add("data", subData)
			endif

			data.Add(subNode.getName().ToLower(), subNode.getContent())
		Next

		return data
	End Function
	

	'search for an attribute
	'(compared to node.HasAttribute() this is NOT case sensitive!)
	Function HasAttribute:Int(node:TXmlNode, fieldName:String)
		if not node then return False

		Local att:TList = node.GetAttributeList()
		fieldName = fieldName.ToLower()
		For Local attribute:TxmlBase = EachIn att
			If attribute.GetName().toLower() = fieldname Then Return True
		Next

		Return False
	End Function


	'returns the value of an attribute
	'(compared to node.GetAttribute() this is NOT case sensitive!)
	Function GetAttribute:String(node:TXmlNode, fieldName:String)
		Local att:TList = node.GetAttributeList()
		fieldName = fieldName.ToLower()
		For Local attribute:TxmlBase = EachIn att
			If attribute.GetName().toLower() = fieldname Then Return node.GetAttribute(attribute.GetName())
		Next
		Return ""
	End Function


	Function HasValue:Int(node:TXmlNode, fieldName:String)
		if not node then return False

		'loop through all potential fieldnames ("frames|f" -> "frames", "f")
		Local fieldNames:String[] = fieldName.ToLower().Split("|")

		For Local name:String = EachIn fieldNames
			If HasAttribute(node, name) Then Return True

			For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
				If subNode.getType() = XML_TEXT_NODE Then Continue
				If subNode.getName().ToLower() = name Then Return True
				If subNode.getName().ToLower() = "data" And HasAttribute(subNode, name) Then Return True
			Next
		Next
		Return False
	End Function


	'find a value within:
	'- the current NODE's attributes
	'  <obj FIELDNAME="bla" />
	'- the first level children
	'- <obj><FIELDNAME>bla</FIELDNAME><anotherfield ...></anotherfield></obj>
	Function FindValue:String(node:TxmlNode, fieldName:String, defaultValue:String, logString:String="")
		if node 
			'loop through all potential fieldnames ("frames|f" -> "frames", "f")
			Local fieldNames:String[] = fieldName.ToLower().Split("|")

			For Local name:String = EachIn fieldNames
				'given node has attribute (<episode number="1">)
				If HasAttribute(node, name) Then Return GetAttribute(node, name)

				For Local subNode:TxmlNode = EachIn GetNodeChildElements(node)
					If subNode.getName().ToLower() = name Then Return subNode.getContent()
					If subNode.getName().ToLower() = "data" And HasAttribute(subNode, name) Then Return GetAttribute(subNode, name)
				Next
			Next
		endif
		If logString <> "" Then Print logString
		Return defaultValue
	End Function


	Function FindValueInt:Int(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="")
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString)
		If result = Null Then Return defaultValue
		Return Int( result )
	End Function


	Function FindValueFloat:Float(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="")
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString)
		If result = Null Then Return defaultValue
		Return Float( result )
	End Function


	Function FindValueBool:Float(node:TxmlNode, fieldName:String, defaultValue:Int, logString:String="")
		Local result:String = FindValue(node, fieldName, String(defaultValue), logString)
		Select result.toLower()
			Case "0", "false"	Return False
			Case "1", "true"	Return True
		End Select
		Return defaultValue
	End Function
End Type