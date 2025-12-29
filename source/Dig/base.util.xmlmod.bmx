SuperStrict

Import Text.xml
Import Collections.ObjectList
Import "base.util.xmlmod.c"


Extern
	Function bmx_mxmlElementGetAttrMOD:String(handle:Byte Ptr, name:String, found:Int var)
	Function bmx_mxmlElementGetAttrByIndexNoNameMOD:String(handle:Byte Ptr, index:Int)
	Function bmx_mxmlElementGetAttrCaseInsensitiveMOD:String(handle:Byte Ptr, name:String, found:Int var)
	Function bmx_mxmlElementHasAttrCaseInsensitiveMOD:Int(handle:Byte Ptr, name:String)
	Function bmx_mxmlElementDeleteAttrCaseInsensitiveMOD(handle:Byte Ptr, name:String)
	Function bmx_mxmlFindElementCaseInsensitiveMOD:Byte Ptr(handle:Byte Ptr, element:String, attr:String, value:String, descend:Int)
End Extern


Function XMLMOD_Node_getAttribute:String(node:TXmlNode, name:String, caseInsensitive:Int = False)
	Local found:Int
	If Not caseInsensitive
		Return bmx_mxmlElementGetAttrMOD(node.nodePtr, name, found)
	Else
		Return bmx_mxmlElementGetAttrCaseInsensitiveMOD(node.nodePtr, name, found)
	EndIf
End Function


Function XMLMOD_Node_tryGetAttribute:Int(node:TXmlNode, name:String, value:String var, caseInsensitive:Int = False)
	Local found:Int
	If Not caseInsensitive
		value = bmx_mxmlElementGetAttrMOD(node.nodePtr, name, found)
	Else
		value = bmx_mxmlElementGetAttrCaseInsensitiveMOD(node.nodePtr, name, found)
	EndIf
	Return found
End Function


Function XMLMOD_Node_getAttributeCount:Int(node:TXmlNode)
	Return bmx_mxmlElementGetAttrCount(node.nodePtr)
End Function


Function XMLMOD_Node_getAttributeByIndex:String(node:TXmlNode, index:Int, name:String var)
	Return bmx_mxmlElementGetAttrByIndex(node.nodePtr, index, name)
End Function


Function XMLMOD_Node_getAttributeByIndex:String(node:TXmlNode, index:Int)
	Return bmx_mxmlElementGetAttrByIndexNoNameMOD(node.nodePtr, index)
End Function


Function XMLMOD_Node_unsetAttribute(node:TXmlNode, name:String, caseInsensitive:Int = False)
	If Not caseInsensitive
		bmx_mxmlElementDeleteAttr(node.nodePtr, name)
	Else
		bmx_mxmlElementDeleteAttrCaseInsensitiveMOD(node.nodePtr, name)
	EndIf
End Function


Function XMLMOD_Node_hasAttribute:Int(node:TXmlNode, name:String, caseInsensitive:Int = False)
	If Not caseInsensitive
		Return bmx_mxmlElementHasAttr(node.nodePtr, name)
	Else
		Return bmx_mxmlElementHasAttrCaseInsensitiveMOD(node.nodePtr, name)
	EndIf
End Function


Function XMLMOD_Node_getChildren:TObjectList(node:TXmlNode)
	Local list:TObjectList = New TObjectList
	
	Local n:Byte Ptr = bmx_mxmlWalkNext(node.nodePtr, node.nodePtr, MXML_DESCEND)
	
	While n
		If bmx_mxmlGetType(n) = MXML_ELEMENT Then
			list.AddLast(TxmlNode._create(n))
		End If
		n = bmx_mxmlWalkNext(n, node.nodePtr, MXML_NO_DESCEND)
	Wend
	
	Return list
End Function


Function XMLMOD_Node_findElement:TxmlNode(node:TXmlNode, element:String = "", attr:String = "", value:String = "", descend:Int=MXML_DESCEND, caseInsensitive:Int = False)
	If Not caseInsensitive
		Return TxmlNode._create(bmx_mxmlFindElement(node.nodePtr, element, attr, value, descend))
	Else
		Return TxmlNode._create(bmx_mxmlFindElementCaseInsensitiveMOD(node.nodePtr, element, attr, value, descend))
	EndIf
End Function
