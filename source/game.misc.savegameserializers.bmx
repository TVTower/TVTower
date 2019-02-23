SuperStrict
Import "Dig/external/string_comp.bmx"
?bmxng
Import "Dig/external/persistence.mod/persistence_mxml.bmx"
?not bmxng
Import "Dig/external/persistence.mod/persistence.bmx"
?
TXMLPersistenceBuilder.RegisterDefault(New TLowerStringXMLSerializer)



Type TLowerStringXMLSerializer Extends TXMLSerializer

	Method TypeName:String()
		Return "TLowerString"
	End Method

	Method Clone:TXMLSerializer()
		Return New TLowerStringXMLSerializer
	End Method


	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local ls:TLowerString = TLowerString(obj)
		node.SetContent(ls.orig)
	End Method


	Method Deserialize:Object(objType:TTypeId, node:TxmlNode)
		'use CreateObjectInstance() to keep reference
		local ls:TLowerString = TLowerString(CreateObjectInstance(objType, node))
		if not ls then return null

		'mark processed
		AddObjectRef(node.GetAttribute("id"), ls)
		'recreate lower string interna without creating a new instance
		ls.DeSerializeTLowerStringFromString( node.GetContent() )

		Return ls
	End Method

End Type
