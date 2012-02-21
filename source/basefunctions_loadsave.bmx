SuperStrict
Import "basefunctions_xml.bmx"
Import brl.reflection

Type TSaveFile
  Field file:xmlDocument
  Field node:xmlNode
  Field currentnode:xmlNode
  Field root:xmlNode
  Field Nodes:xmlNode[10]
  Field NodeDepth:Int = 0
  Field lastNode:xmlNode
  
  Function Create:TSaveFile()
  	Local tmpobj:TSaveFile = New TSaveFile
	Return tmpobj
  End Function

  Method InitSave()
	Self.file 	= New xmlDocument
	Self.root 	= Self.file.root()
	Self.root.name = "savegame"
    Self.Nodes[0] = Self.root
	Self.lastNode = Self.root
  End Method

  Method InitLoad(filename:String="save.xml", zipped:Byte=0)
    Self.file = xmlDocument.Create(filename, zipped) 
	Self.root = Self.file.root()
	Self.NODE = Self.root
  End Method

  Method xmlWrite(typ:String="unknown",str:String, newDepth:Byte=0, depth:Int=-1)
	If depth <=-1 Or depth >=10 Then depth = Self.NodeDepth ';newDepth=False
    If newDepth
		Self.Nodes[Self.NodeDepth+1] = Self.Nodes[depth].AddNode(typ)
		Self.Nodes[Self.NodeDepth+1].Attribute("var").value = str
		Self.NodeDepth:+1
	Else
		Self.Nodes[depth].AddNode(typ).Attribute("var").value = str
	EndIf
  End Method

  Method xmlCloseNode()
    Self.NodeDepth:-1	
  End Method

  Method xmlBeginNode(str:String)
	Self.Nodes[Self.NodeDepth + 1] = Self.Nodes[Self.NodeDepth].AddNode(str) 
    Self.NodeDepth:+1	
  End Method

  Method xmlSave(filename:String="-", zipped:Byte=0)
	If filename = "-" Then Print "nodes:"+Self.file.NodeCount() Else Self.file.Save(filename,FORMAT_XML, zipped)
  End Method
  
	'Summary: saves an object to defined XMLstream
	Method SaveObject:Int(obj:Object, nodename:String, _addfunc(obj:Object))
		Local result:String = ""
	    Self.xmlBeginNode(nodename)
			'list of objects as obj-param - iterate through all listobjects
			If TList(obj) <> Null
				For Local listobj:Object = EachIn TList(obj)
					SaveObject(listobj, nodename + "_CHILD", _addfunc)
'					SaveObject(listobj, TTypeId.ForObject(listobj).Name().ToUpper(), _addfunc)
				Next
			Else
				Local typ:TTypeId = TTypeId.ForObject(obj)
				For Local t:TField = EachIn typ.EnumFields()
					If t.MetaData("sl") <> "no"
						local fieldtype:TTypeId = TTypeId.ForObject(t.get(obj))
						If fieldtype.ExtendsType(ArrayTypeId)
							If fieldtype.ArrayLength(typ) > 0
								Print "array '" + t.Name() + " - " + fieldtype.Name() + "'"
							EndIf
						End If
						If TList(t.Get(obj)) <> Null
							Local liste:TList = TList(t.Get(obj))
							For Local childobj:Object = EachIn liste
								Print "saving list children..."
								Self.SaveObject(childobj, nodename + "_CHILD", _addfunc)
							Next
						Else
							Self.xmlWrite(Upper(t.name()), String(t.Get(obj)))
						End If
					EndIf
				Next
				If _addfunc <> Null Then _addfunc(obj)
			EndIf
		Self.xmlCloseNode()
	End Method

	'Summary: loads an object from a XMLstream
	Method LoadObject:Object(obj:Object, _handleNodefunc(_obj:Object, _node:xmlnode))
		Local NODE:xmlNode = Self.NODE.FirstChild()
		Local nodevalue:String
		While NODE <> Null
			nodevalue = ""
			If NODE.hasAttribute("var", False) Then nodevalue = Self.NODE.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(obj)
			For Local t:TField = EachIn typ.EnumFields() 
				If t.MetaData("sl") <> "no" And Upper(t.name()) = NODE.name
					t.Set(obj, nodevalue)
				EndIf
			Next
			Self.NODE = Self.NODE.nextSibling()
			If _handleNodefunc <> Null Then _handleNodefunc(obj, NODE)
		Wend
		Return obj
	End Method
End Type
Global LoadSaveFile:TSaveFile = TSaveFile.Create()
