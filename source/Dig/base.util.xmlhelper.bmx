SuperStrict
Import Brl.Standardio
Import "external/libxml/libxml.bmx"
Import "base.util.data.bmx"
Import Brl.Retro 'for filesize


Type TXmlHelper
	Field filename:String =""
	Field xmlDoc:TxmlDoc


	Function Create:TXmlHelper(filename:String, rootNode:String="")
		Local obj:TXmlHelper = New TXmlHelper
		if filesize(filename) >= 0
			obj.filename = filename
			obj.xmlDoc = TxmlDoc.parseFile(filename)
		else
			obj.filename = filename
			obj.xmlDoc = TxmlDoc.newDoc("1.0")
			if rootNode <> "" then obj.CreateRootNode(rootNode)
		endif
		Return obj
	End Function


	Method GetRootNode:TxmlNode()
		return xmlDoc.getRootElement()
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


	Function findAttribute:String(node:TxmlNode, attributeName:String, defaultValue:String)
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
		nodeName = nodeName.ToLower()
		For Local child:TxmlNode = EachIn GetNodeChildElements(node)
			If child.getName().ToLower() = nodeName Then Return child
		Next
		Return Null
	End Function


	'loads values of a node into a tdata object
	Function LoadValuesToData:Int(node:TXmlNode, data:TData Var, fieldNames:String[])
		For Local fieldName:String = EachIn fieldNames
			If Not TXmlHelper.HasValue(node, fieldName) Then Continue
			'use the first fieldname ("frames|f" -> add as "frames")
			Local names:String[] = fieldName.ToLower().Split("|")

			data.Add(names[0], FindValue(node, fieldName, ""))
		Next
	End Function


	'search for an attribute
	'(compared to node.HasAttribute() this is NOT case sensitive!)
	Function HasAttribute:Int(node:TXmlNode, fieldName:String)
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