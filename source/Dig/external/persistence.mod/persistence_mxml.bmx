' Copyright (c) 2008-2019 Bruce A Henderson
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
Module BaH.Persistence

ModuleInfo "Version: 1.04"
ModuleInfo "Author: Bruce A Henderson"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: 2008-2019 Bruce A Henderson"

ModuleInfo "History: 1.04"
ModuleInfo "History: Improved persistence."
ModuleInfo "History: Added unit tests."
ModuleInfo "History: 1.03"
ModuleInfo "History: Added custom serializers."
ModuleInfo "History: 1.02"
ModuleInfo "History: Added XML parsing options arg for deserialization."
ModuleInfo "History: Fixed 64-bit address ref issue."
ModuleInfo "History: 1.01"
ModuleInfo "History: Added encoding for String and String Array fields. (Ronny Otto)"
ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release"

endrem
'Import "../libxml/libxml.bmx" 'BaH.libxml
Import Brl.xml
?Not bmxng
'using custom to have support for const/function reflection
Import "../reflectionExtended/reflection.bmx"
?bmxng
'ng has it built-in!
Import BRL.Reflection
?
Import BRL.Map
Import BRL.Stream
'Import brl.standardio

Import "glue.c"


Rem
bbdoc: Object Persistence.
End Rem
Type TPersist

	Rem
	bbdoc: File format version
	End Rem
	Const BMO_VERSION:Int = 8

	Field doc:TxmlDoc
	Field objectMap:TMap = New TMap

	Field lastNode:TxmlNode

	'Ronny
	Field strictMode:Int = True
	'a special connected type handling conversions of stored field contents
	'no longer matching up the definitions of a field (= types differing)
	Field converterTypeID:TTypeId
	Field converterType:Object
	'a connected type overriding serialization/deserialization of elements
	'by containing Methods:
	'- SerializeTTypeNameToString() and
	'- DeSerializeTTypeNameFromString()
	Field serializer:Object
	Field serializerTypeID:TTypeId


	Rem
	bbdoc: Serialized formatting.
	about: Set to True to have the data formatted nicely. Default is False - off.
	End Rem
	Global format:Int = False

	Rem
	bbdoc: Compressed serialization.
	about: Set to True to compress the serialized data. Default is False - no compression.
	End Rem
	Global compressed:Int = False
	Global maxDepth:Int = 0

?ptr64
	Global bbEmptyString:String = Base36(Long(bbEmptyStringPtr()))
	Global bbNullObject:String = Base36(Long(bbNullObjectPtr()))
	Global bbEmptyArray:String = Base36(Long(bbEmptyArrayPtr()))
?Not ptr64
	Global bbEmptyString:String = TPersist.Base36(Int(bbEmptyStringPtr()))
	Global bbNullObject:String = TPersist.Base36(Int(bbNullObjectPtr()))
	Global bbEmptyArray:String = TPersist.Base36(Int(bbEmptyArrayPtr()))
?

	Field fileVersion:Int

	Field serializers:TMap = New TMap
	Field _inited:Int

	Rem
	bbdoc: Serializes the specified Object into a String.
	End Rem
	Method Serialize:String(obj:Object)
		Return SerializeToString(obj)
	End Method

	Method Free()
		If doc Then
			doc.Free()
			doc = Null
		End If
		If lastNode Then
			lastNode = Null
		End If
		objectMap.Clear()
	End Method

	Rem
	bbdoc: Serializes an Object to a String.
	End Rem
	Method SerializeToString:String(obj:Object)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."
		Free()
		SerializeObject(obj)

		Return ToString()
	End Method

	Rem
	bbdoc: Serializes an Object to the file @filename.
	End Rem
	Method SerializeToFile(obj:Object, filename:String)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."
		Free()
		SerializeObject(obj)

		If doc Then
'			If compressed Then
'				doc.setCompressMode(9)
'			Else
'				doc.setCompressMode(0)
'			End If
'			doc.saveFormatFile(filename, format)
			doc.saveFile(filename, True, format)
		End If
		Free()
	End Method

	Rem
	bbdoc: Serializes an Object to a TxmlDoc structure.
	about: It is up to the user to free the returned TxmlDoc object.
	End Rem
	Method SerializeToDoc:TxmlDoc(obj:Object)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."
		Free()
		SerializeObject(obj)

		Local exportDoc:TxmlDoc = doc
		doc = Null
		Free()
		Return exportDoc
	End Method

	Rem
	bbdoc: Serializes an Object to a Stream.
	about: It is up to the user to close the stream.
	End Rem
	Method SerializeToStream(obj:Object, stream:TStream)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."
		Free()
		SerializeObject(obj)

		If doc Then
			stream.WriteString(ToString())
		End If
		Free()
	End Method

	Rem
	bbdoc: Returns the serialized object as a string.
	End Rem
	Method ToString:String()
		If doc Then
'			If compressed Then
'				doc.setCompressMode(9)
'			Else
'				doc.setCompressMode(0)
'			End If
			Return doc.ToStringFormat(format)
		End If
	End Method

	Method ProcessArray(arrayObject:Object, size:Int, node:TxmlNode, typeId:TTypeId)

		Local elementType:TTypeId = typeId.ElementType()

		Select elementType
			Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId

				Local content:String = ""

				For Local i:Int = 0 Until size

					Local aObj:Object = typeId.GetArrayElement(arrayObject, i)

					If i Then
						content:+ " "
					End If
					content:+ String(aObj)
				Next

				node.SetContent(content)
			Default

				For Local i:Int = 0 Until size

					Local elementNode:TxmlNode = node.addChild("val")

					Local aObj:Object = typeId.GetArrayElement(arrayObject, i)

					Select elementType
						Case StringTypeId
							' only if not empty
							If String(aObj) Then
								elementNode.setContent(String(aObj))
							End If
						Default
							Local objRef:String = GetObjRef(aObj)

							' file version 5 ... array cells can contain references
							If Not Contains(objRef, aObj) Then
								SerializeObject(aObj, elementNode)
							Else
								elementNode.setAttribute("ref", objRef)
							End If
					End Select
				Next

		End Select

	End Method

	Rem
	bbdoc:
	End Rem
	Method SerializeFields(tid:TTypeId, obj:Object, node:TxmlNode)
		For Local f:TField = EachIn tid.EnumFields()
			SerializeField(f, obj, node)
		Next
	End Method

	Rem
	bbdoc:
	End Rem
	Method CreateSerializedFieldNode:TxmlNode(f:TField, node:TxmlNode)
		Local fieldNode:TxmlNode = node.addChild("field")
		fieldNode.setAttribute("name", f.Name())
		Return fieldNode
	End Method

	Rem
	bbdoc:
	End Rem
	Method SerializeField(f:TField, obj:Object, node:TxmlNode)
		If f.MetaData("nopersist") Or f.MetaData("nosave") Then
			Return
		End If

		Local fieldType:TTypeId = f.TypeId()
		Local fieldNode:TxmlNode = CreateSerializedFieldNode(f, node)

		Local t:String
		Select fieldType
			Case ByteTypeId
				t = "byte"
				fieldNode.setContent(f.GetInt(obj))
			Case ShortTypeId
				t = "short"
				fieldNode.setContent(f.GetInt(obj))
			Case IntTypeId
				t = "int"
				fieldNode.setContent(f.GetInt(obj))
			Case LongTypeId
				t = "long"
				fieldNode.setContent(f.GetLong(obj))
			Case FloatTypeId
				t = "float"
				'Ronny:
				'if the float is xx.0000, write it without
				'the ".0000" part (-> as int)
				Local v:Float = f.GetFloat(obj)
				If Float(Int(v)) = v
					fieldNode.setContent(Int(v))
				Else
					fieldNode.setContent(v)
				EndIf

				'fieldNode.setContent(f.GetFloat(obj))
			Case DoubleTypeId
				t = "double"
				fieldNode.setContent(f.GetDouble(obj))
			Default
				t = fieldType.Name()

				If fieldType.ExtendsType( ArrayTypeId ) Then

					' prefix and strip brackets
					Local dims:Int = t.split("[").length
					If dims = 1 Then
						t = "array:" + t.Replace("[]", "")
					Else
						t = "array:" + t
					End If

					dims = fieldType.ArrayDimensions(f.Get(obj))
					If dims > 1 Then
						Local scales:String
						For Local i:Int = 0 Until dims - 1
							scales :+ (fieldType.ArrayLength(f.Get(obj), i) / fieldType.ArrayLength(f.Get(obj), i + 1))
							scales :+ ","
						Next

						scales:+ fieldType.ArrayLength(f.Get(obj), dims - 1)

						fieldNode.setAttribute("scales", scales)
					End If

					ProcessArray(f.Get(obj), fieldType.ArrayLength(f.Get(obj)), fieldNode, fieldType)

				Else
					Local fieldObject:Object = f.Get(obj)
					Local fieldRef:String = GetObjRef(fieldObject)

					If fieldRef <> bbEmptyString And fieldRef <> bbNullObject And fieldRef <> bbEmptyArray Then
						If fieldObject Then
							If Not Contains(fieldRef, fieldObject) Then
								SerializeObject(fieldObject, fieldNode)
							Else
								fieldNode.setAttribute("ref", fieldRef)
							End If
						End If
					End If
				End If
		End Select

		fieldNode.setAttribute("type", t)
	End Method

	Method SerializeByType(tid:TTypeId, obj:Object, node:TxmlNode)
		Local serializer:TXMLSerializer = TXMLSerializer(serializers.ValueForKey(tid.Name()))
		If serializer Then
			serializer.Serialize(tid, obj, node)
		Else
			'Ronny: try to let the type or a generic serializer handle it
			If Not CustomSerializeByType(tid, obj, node)
				'fall back to default field serialization
				SerializeFields(tid, obj, node)
			End If
		End If
	End Method


	'Ronny:
	Method CustomSerializeByType:Int(tid:TTypeId, obj:Object, node:TXmlNode)
		'check if there is a special "Serialize[classname]ToString" Method
		'defined for the object
		'only do serialization, if the way back is defined too
		Local serializedString:String
		Local mth:TMethod, mth2:TMethod

		'check if a common serializer wants to handle it
		If serializer
			If Not serializerTypeID Then serializerTypeID = TTypeId.ForObject(serializer)
			mth = serializerTypeID.FindMethod("Serialize"+tid.name()+"ToString")
			mth2 = serializerTypeID.FindMethod("DeSerialize"+tid.name()+"FromString")
			If mth And mth2
				'append the to-serialize-obj as param
				serializedString = String( mth.Invoke(serializer, [obj]) )
			EndIf
		EndIf

		'check if the type itself wants to handle it
		If Not serializedString
			mth = tid.FindMethod("Serialize"+tid.name()+"ToString")
			mth2 = tid.FindMethod("DeSerialize"+tid.name()+"FromString")
			If mth And mth2
				serializedString = String( mth.Invoke(obj) )
			EndIf
		EndIf

		'no need to check wether "serialized" is <> "" (might be
		'empty on purpose!) - if mth/mth2 exist, then we trust
		'that methods to serialize properly
		If mth And mth2 'and serializedString
			node.setAttribute("serialized" ,serializedString)
			Return True
		EndIf

		Return False
	End Method


	Rem
	bbdoc:
	End Rem
	Method SerializeObject:TxmlNode(obj:Object, parent:TxmlNode = Null)

		Local node:TxmlNode

		If Not doc Then
			doc = TxmlDoc.newDoc("1.0")
			parent = TxmlNode.newNode("bmo") ' BlitzMax Object
			parent.SetAttribute("ver", BMO_VERSION) ' set the format version
			doc.setRootElement(parent)
		Else
			If Not parent Then
				parent = doc.GetRootElement()
			End If
		End If

		If obj Then
			Local objRef:String = GetObjRef(obj)

			If objRef = bbEmptyString Or objRef = bbNullObject Or objRef = bbEmptyArray Then
				Return Null
			End If

			Local objectIsArray:Int = False

			Local tid:TTypeId = TTypeId.ForObject(obj)
			Local tidName:String = tid.Name()

			' Is this an array "Object" ?
			If tidName.EndsWith("[]") Then
				tidName = "_array_"
				objectIsArray = True
			End If

			node = parent.addChild(tidName)


			'already referenced?
			'just add the newly created "reference node"
			If Contains(objRef, obj)
				node.setAttribute("ref", objRef)
				Return node
			EndIf


			'not referenced, serialize object
			node.setAttribute("id", objRef)

			AddObjectRef(obj, node)

			' We need to handle array objects differently..
			If objectIsArray Then

				tidName = tid.Name()[..tid.Name().length - 2]

				Local size:Int

				' it's possible that the array is zero-length, in which case the object type
				' is undefined. Therefore we default it to type "Object".
				' This doesn't matter, since it's essentially a Null Object which has no
				' inherent value. We only store the instance so that the de-serialized object will
				' look similar.
				Try
					size = tid.ArrayLength(obj)
				Catch e$
					tidName = "Object"
					size = 0
				End Try

				node.setAttribute("type", tidName)
				node.setAttribute("size", size)

				If size > 0 Then
					ProcessArray(obj, size, node, tid)
				End If

			Else

				' special case for String object
				If tid = StringTypeId Then
					node.setContent(String(obj))
				Else
					SerializeByType(tid, obj, node)
				End If

			End If

		End If

		Return node

	End Method

	Method Contains:Int(ref:String, obj:Object)
		Local cobj:Object = objectMap.ValueForKey(ref)
		If Not cobj Then
			Return False
		End If

		' same object already exists!
		If cobj = obj Then
			Return True
		End If

		' same ref but different object????
		Throw TPersistCollisionException.CreateException(ref, obj, cobj)
	End Method

	Method Delete()
		Free()
	End Method

	Rem
	bbdoc: De-serializes @text into an Object structure.
	about: Accepts a TxmlDoc, TStream or a String (of data).
	@options relate to libxml specific parsing flags that can be applied.
	End Rem
	Method DeSerialize:Object(data:Object, options:Int = 0)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."

		If TxmlDoc(data) Then
			Return DeSerializeFromDoc(TxmlDoc(data))
		Else If TStream(data) Then
			Return DeSerializeFromStream(TStream(data), options)
		Else If String(data) Then
			Return DeSerializeObject(String(data), Null, options)
		End If
	End Method

	Rem
	bbdoc: De-serializes @doc into an Object structure.
	about: It is up to the user to free the supplied TxmlDoc.
	End Rem
	Method DeSerializeFromDoc:Object(xmlDoc:TxmlDoc)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."

		doc = xmlDoc

		Local root:TxmlNode = doc.GetRootElement()
		fileVersion = root.GetAttribute("ver").ToInt() ' get the format version
		Local obj:Object = DeSerializeObject("", root)
		doc = Null
		Free()
		Return obj
	End Method

	Rem
	bbdoc: De-serializes the file @filename into an Object structure.
	about: @options relate to libxml specific parsing flags that can be applied.
	End Rem
	Method DeSerializeFromFile:Object(filename:String, options:Int = 0)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."

		'doc = TxmlDoc.ReadFile(filename, "", options)
		doc = TxmlDoc.parseFile(filename)

		If doc Then
			Local root:TxmlNode = doc.GetRootElement()
			fileVersion = root.GetAttribute("ver").ToInt() ' get the format version
			Local obj:Object = DeSerializeObject("", root)
			Free()
			Return obj
		End If
	End Method

	Rem
	bbdoc: De-serializes @stream into an Object structure.
	about: @options relate to libxml specific parsing flags that can be applied.
	End Rem
	Method DeSerializeFromStream:Object(stream:TStream, options:Int = 0)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."

		Local data:String
		Local buf:Byte[2048]

		While Not stream.Eof()
			Local count:Int = stream.Read(buf, 2048)
			data:+ String.FromBytes(buf, count)
		Wend

		Local obj:Object = DeSerializeObject(data, Null, options)
		Free()
		Return obj
	End Method

	Method DeserializeByType:Object(objType:TTypeId, node:TxmlNode)
		'Ronny: skip loading elements having "nosave" metadata
		If objType.MetaData("nosave") And Not objType.MetaData("doload") Then Return Null

		Local serializer:TXMLSerializer = TXMLSerializer(serializers.ValueForKey(objType.Name()))
		If serializer Then
			Return serializer.Deserialize(objType, node)
		Else
			Local obj:Object = CreateObjectInstance(objType, node)
'			'Ronny: try to let the type or a generic serializer handle it
			If Not CustomDeserializeByType(objType, obj, node)
'				'fall back to default field deserialization
				DeserializeFields(objType, obj, node)
			End If
			Return obj
		End If
	End Method

	Method AddObjectRef(obj:Object, node:TxmlNode)
		objectMap.Insert(node.getAttribute("id"), obj)
	End Method

	Method CreateObjectInstance:Object(objType:TTypeId, node:TxmlNode)
		' create the object
		Local obj:Object = objType.NewObject()
		AddObjectRef(obj, node)
		Return obj
	End Method

	Method DeserializeFields(objType:TTypeId, obj:Object, node:TxmlNode)
		' does the node contain child nodes?
		If node.getChildren() <> Null Then
			For Local fieldNode:TxmlNode = EachIn node.getChildren()
				' this should be a field
				If fieldNode.GetName() = "field" Then
					Local fieldObj:TField = objType.FindField(fieldNode.getAttribute("name"))

					'Ronny: skip unknown fields (no longer existing in the type)
					If Not fieldObj

						Local serializedFieldTypeID:TTypeId = TTypeId.ForName(fieldNode.getAttribute("type"))
						If Not strictMode And serializedFieldTypeID
							Print "[WARNING] TPersistence: field ~q"+fieldNode.getAttribute("name")+"~q is no longer available. Created WorkAround-Storage."

							'deserialize it, so that its reference exists
							DeSerializeObject("", fieldNode)
						Else
							Print "[WARNING] TPersistence: field ~q"+fieldNode.getAttribute("name")+"~q is no longer available."
						EndIf
						Continue
					End If
					'Ronny: skip loading elements having "nosave" metadata
					If fieldObj.MetaData("nosave") And Not fieldObj.MetaData("doload") Then Continue

					Local fieldType:String = fieldNode.getAttribute("type")
					Select fieldType
						Case "byte", "short", "int"
							fieldObj.SetInt(obj, fieldNode.GetContent().toInt())
						Case "long"
							fieldObj.SetLong(obj, fieldNode.GetContent().toLong())
						Case "float"
							fieldObj.SetFloat(obj, fieldNode.GetContent().toFloat())
						Case "double"
							fieldObj.SetDouble(obj, fieldNode.GetContent().toDouble())
						Default
							If fieldType.StartsWith("array:") Then

								Local arrayType:TTypeId = fieldObj.TypeId()
								Local arrayElementType:TTypeId = arrayType.ElementType()

								Local scalesi:Int[]
								Local scales:String[] = fieldNode.getAttribute("scales").split(",")
								If scales.length > 1 Then
									scalesi = New Int[scales.length]
									For Local i:Int = 0 Until scales.length
										scalesi[i] = Int(scales[i])
									Next
								End If

								Select arrayElementType
									Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId

										Local arrayList:String[]
										Local content:String = fieldNode.GetContent().Trim()

										If content Then
											arrayList = content.Split(" ")
										Else
											arrayList = New String[0]
										End If

										Local arrayObj:Object = arrayType.NewArray(arrayList.length, scalesi)
										fieldObj.Set(obj, arrayObj)

										For Local i:Int = 0 Until arrayList.length
											arrayType.SetArrayElement(arrayObj, i, arrayList[i])
										Next

									Default
										Local arrayList:TList = fieldNode.getChildren()

										If arrayList ' Birdie
											Local arrayObj:Object = arrayType.NewArray(arrayList.Count(), scalesi)
											fieldObj.Set(obj, arrayObj)

											Local i:Int
											For Local arrayNode:TxmlNode = EachIn arrayList

												Select arrayElementType
													Case StringTypeId
														arrayType.SetArrayElement(arrayObj, i, arrayNode.GetContent())
													Default
														' file version 5 ... array cells can contain references
														' is this a reference?
														Local ref:String = arrayNode.getAttribute("ref")
														If ref Then
															Local objRef:Object = objectMap.ValueForKey(ref)
															If objRef Then
																arrayType.SetArrayElement(arrayObj, i, objRef)
															Else
																Throw "Reference not mapped yet : " + ref
															End If
														Else
															arrayType.SetArrayElement(arrayObj, i, DeSerializeObject("", arrayNode))
														End If
												End Select

												i:+ 1
											Next
										EndIf
								End Select
							Else
								If fieldType = "string" And fileVersion < 8 Then
									fieldObj.SetString(obj, fieldNode.GetContent())
								Else
									' is this a reference?
									Local ref:String = fieldNode.getAttribute("ref")
									If ref Then
										Local objRef:Object = objectMap.ValueForKey(ref)
										If objRef Then
											fieldObj.Set(obj, objRef)
										Else
											Throw "Reference not mapped yet : " + ref
										End If
									Else
										fieldObj.Set(obj, DeSerializeObject("", fieldNode))
									End If
								End If
							End If
					End Select

				End If
			Next
		End If
	End Method


	'Ronny:
	'deserializes objects defined in "node" into "obj"
	Method CustomDeserializeByType:Int(objType:TTypeId, obj:Object Var, node:TxmlNode)
		' serialized data in attribute?
		If Not node.HasAttribute("serialized") Then Return False
		'no type information provided?
		If Not objType Then Return False

		'serialized might be "" (eg. an empty TLowerString)
		Local serialized:String = node.GetAttribute("serialized")
		'check if there is a special "DeSerialize[classname]ToString" Method
		'defined for the object
		Local mth:TMethod
		Local deserializationResult:Object = Null
		'check if a common serializer wants to handle it
		If serializer
			If Not serializerTypeID Then serializerTypeID = TTypeId.ForObject(serializer)
			mth = serializerTypeID.FindMethod("DeSerialize"+objType.Name()+"FromString")
			'append the obj as param
			If mth
				deserializationResult = mth.Invoke(serializer, [Object(serialized), obj])
			EndIf
		EndIf

		'check if the type itself wants to handle it
		If Not deserializationResult Or Not serializer
			deserializationResult = obj
			mth = objType.FindMethod("DeSerialize"+objType.Name()+"FromString")
			If mth Then mth.Invoke(deserializationResult, [serialized])
		EndIf

		'override referenced object
		If deserializationResult
			'assign obj (obj is passed as "var")
			obj = deserializationResult

			AddObjectRef(deserializationResult, node)
'			objectMap.Insert(node.getAttribute("id"), deserializationResult)
			Return True
		EndIf

		Return False
	End Method


	Rem
	bbdoc:
	End Rem
	Method DeSerializeObject:Object(Text:String, parent:TxmlNode = Null, options:Int = 0, parentIsNode:Int = False)
		Local node:TxmlNode

		If Not doc Then
			'doc = TxmlDoc.readDoc(Text, "", "", options)
			doc = TxmlDoc.readDoc(Text)
			parent = doc.GetRootElement()
			fileVersion = parent.GetAttribute("ver").ToInt() ' get the format version
			node = TxmlNode(parent.GetFirstChild())
			lastNode = node
		Else
			If Not parent Then
				' find the next element node, if there is one. (content are also "nodes")
				node = TxmlNode(lastNode.NextSibling())
				'While node And (node.getType() <> XML_ELEMENT_NODE)
				'	node = TxmlNode(node.NextSibling())
				'Wend
				If Not node Then
					Return Null
				End If
				lastNode = node
			Else
				If parentIsNode Then
					node = parent
				Else
					node = TxmlNode(parent.GetFirstChild())
				End If
				lastNode = node
			End If
		End If

		Local obj:Object

		If node Then
			'if node contains a reference, just return reference object
			Local ref:String = node.getAttribute("ref")
			If ref Then
				Local objRef:Object = objectMap.ValueForKey(ref)
				If objRef Then
					obj = objRef
					Return obj
				Else
					Throw "Reference not mapped yet : " + ref
				End If
			EndIf


			'else deserialize object
			Local nodeName:String = node.GetName()

			' Is this an array "Object" ?
			If nodeName = "_array_" Then
				'Grable's reflectionExtended identifies null arrays as "Null[]"
				'but BlitzMaxNG's and BRL-Vanilla reflection code cannot
				'handle that. So set it to "object" (as done in serialization
				'for unhandled typeids)

				'old:
				'Local objType:TTypeId = TTypeId.ForName(node.getAttribute("type") + "[]")
				'new:
				Local attributeName:String = node.getAttribute("type")
				If attributeName = "Null" Then attributeName = "Object"
				Local objType:TTypeId = TTypeId.ForName(attributeName + "[]")

				Local size:Int = node.getAttribute("size").toInt()
				obj = objType.NewArray(size)
				AddObjectRef(obj, node)

				If size > 0 Then
					Local arrayElementType:TTypeId = objType.ElementType()

					Select arrayElementType
						Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId

							Local arrayList:String[] = node.GetContent().Split(" ")

							For Local i:Int = 0 Until arrayList.length
								objType.SetArrayElement(obj, i, arrayList[i])
							Next

						Default
							Local arrayList:TList = node.getChildren()

							If arrayList

								Local i:Int
								For Local arrayNode:TxmlNode = EachIn arrayList

									Select arrayElementType
										Case StringTypeId
											objType.SetArrayElement(obj, i, arrayNode.GetContent())
										Default
											' file version 5 ... array cells can contain references
											' is this a reference?
											Local ref:String = arrayNode.getAttribute("ref")
											If ref Then
												Local objRef:Object = objectMap.ValueForKey(ref)
												If objRef Then
													objType.SetArrayElement(obj, i, objRef)
												Else
													Throw "Reference not mapped yet : " + ref
												End If
											Else
												objType.SetArrayElement(obj, i, DeSerializeObject("", arrayNode))
											End If

									End Select

									i:+ 1
								Next
							EndIf
					End Select
				End If
			Else
				Local objType:TTypeId = TTypeId.ForName(nodeName)

				' special case for String object
				If objType = StringTypeId Then
					obj = node.GetContent()
					AddObjectRef(obj, node)
					Return obj
				End If

				obj = DeserializeByType(objType, node)
			End If
		End If

		Return obj

	End Method


	Function GetObjRef:String(obj:Object)
?ptr64
		Return Base36(Long(bbObjectRef(obj)))
?Not ptr64
		Return Base36(Int(bbObjectRef(obj)))
?
	End Function

?ptr64
	Function Base36:String( val:Long )
		Const size:Int = 13
?Not ptr64
	Function Base36:String( val:Int )
		Const size:Int = 6
?
		Local vLong:Long = $FFFFFFFFFFFFFFFF & Long(Byte Ptr(val))
		Local buf:Short[size]
		For Local k:Int=(size-1) To 0 Step -1
			Local n:Int=(vLong Mod 36) + 48
			If n > 57 n:+ 7
			buf[k]=n
			vLong = vLong / 36
		Next

		' strip leading zeros
		Local offset:Int = 0
		While offset < size
			If buf[offset] - Asc("0") Exit
			offset:+ 1
		Wend

		Return String.FromShorts( Short Ptr(buf) + offset,size-offset )
	End Function

	Method AddSerializer(serializer:TXMLSerializer)
		serializers.Insert(serializer.TypeName(), serializer)
		serializer.persist = Self
	End Method
End Type

Type TPersistCollisionException Extends TPersistException

	Field ref:String
	Field obj1:Object
	Field obj2:Object

	Function CreateException:TPersistCollisionException(ref:String, obj1:Object, obj2:Object)
		Local e:TPersistCollisionException = New TPersistCollisionException
		e.ref = ref
		e.obj1 = obj1
		e.obj2 = obj2
		Return e
	End Function

	Method ToString:String()
		Return "Persist Collision. Matching ref '" + ref + "' for different objects"
	End Method

End Type

Type TPersistException Extends TRuntimeException
End Type

Rem
bbdoc:
End Rem
Type TXMLPersistenceBuilder

	Global defaultSerializers:TMap = New TMap
	Field serializers:TMap = New TMap

	Method New()
		For Local s:TXMLSerializer = EachIn defaultSerializers.Values()
			Register(s.Clone())
		Next
	End Method

	Rem
	bbdoc:
	End Rem
	Method Build:TPersist()
		Local persist:TPersist = New TPersist
		persist._inited = True

		For Local s:TXMLSerializer = EachIn serializers.Values()
			persist.AddSerializer(s)
		Next

		Return persist
	End Method

	Rem
	bbdoc:
	End Rem
	Method Register:TXMLPersistenceBuilder(serializer:TXMLSerializer)
		serializers.Insert(serializer.TypeName(), serializer)
		Return Self
	End Method

	Rem
	bbdoc:
	End Rem
	Function RegisterDefault(serializer:TXMLSerializer)
		defaultSerializers.Insert(serializer.TypeName(), serializer)
	End Function

End Type

Rem
bbdoc:
End Rem
Type TXMLSerializer
	Field persist:TPersist

	Rem
	bbdoc: Returns the typeid name that the serializer handles - For example, "TMap"
	End Rem
	Method TypeName:String() Abstract

	Rem
	bbdoc: Serializes the object.
	End Rem
	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode) Abstract

	Rem
	bbdoc: Deserializes the object.
	End Rem
	Method Deserialize:Object(objType:TTypeId, node:TxmlNode) Abstract

	Rem
	bbdoc: Returns a new instance.
	End Rem
	Method Clone:TXMLSerializer() Abstract

	Rem
	bbdoc:
	End Rem
	Method SerializeObject:TxmlNode(obj:Object, node:TxmlNode)
		Return persist.SerializeObject(obj, node)
	End Method

	Rem
	bbdoc: Iterates over all of the object fields, serializing them.
	End Rem
	Method SerializeFields(tid:TTypeId, obj:Object, node:TxmlNode)
		persist.SerializeFields(tid, obj, node)
	End Method

	Rem
	bbdoc:
	End Rem
	Method GetFileVersion:Int()
		Return persist.fileVersion
	End Method

	Method DeserializeObject:Object(node:TxmlNode, direct:Int = False)
		Return persist.DeserializeObject("", node, 0, direct)
	End Method

	Rem
	bbdoc: Returns True if the reference has already been processed.
	End Rem
	Method Contains:Int(ref:String, obj:Object)
		Return persist.Contains(ref, obj)
	End Method

	Rem
	bbdoc: Adds the object reference to the object map, in order to track what object instances have been processed.
	End Rem
	Method AddObjectRef(ref:String, obj:Object)
		persist.objectMap.Insert(ref, obj)
	End Method

	Rem
	bbdoc: Convenience method for checking and adding an object reference.
	returns: True if the object has already been processed.
	End Rem
	Method AddObjectRefAsRequired:Int(ref:String, obj:Object)
		If Contains(ref, obj) Then
			Return True
		End If
		AddObjectRef(ref, obj)
	End Method

	Rem
	bbdoc: Adds the xml reference to the object map, in order to track what object instances have been processed.
	End Rem
	Method AddObjectRefNode(node:TxmlNode, obj:Object)
		persist.AddObjectRef(obj, node)
	End Method

	Rem
	bbdoc: Returns a String representation of an object reference, suitable for serializing.
	End Rem
	Method GetObjRef:String(obj:Object)
		Return TPersist.GetObjRef(obj)
	End Method

	Method GetReferencedObj:Object(ref:String)
		Return persist.objectMap.ValueForKey(ref)
	End Method

	Rem
	bbdoc: Serializes a single field.
	End Rem
	Method SerializeField(f:TField, obj:Object, node:TxmlNode)
		persist.SerializeField(f, obj, node)
	End Method

	Rem
	bbdoc:
	End Rem
	Method CreateObjectInstance:Object(objType:TTypeId, node:TxmlNode)
		Return persist.CreateObjectInstance(objType, node)
	End Method

	Method DeserializeFields(objType:TTypeId, obj:Object, node:TxmlNode)
		persist.DeserializeFields(objType, obj, node)
	End Method
End Type

Type TMapXMLSerializer Extends TXMLSerializer

	Global nil:TNode = New TMap._root

	Method TypeName:String()
		Return "TMap"
	End Method

	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local map:TMap = TMap(obj)

		If map Then
			For Local mapNode:TNode = EachIn map
				Local n:TxmlNode = node.addChild("n")

				SerializeObject(mapNode.Key(), n.addChild("k"))
				SerializeObject(mapNode.Value(), n.addChild("v"))
			Next
		End If
	End Method

	Method Deserialize:Object(objType:TTypeId, node:TxmlNode)
		Local map:TMap = TMap(CreateObjectInstance(objType, node))

		If node.getChildren() Then
			For Local mapNode:TxmlNode = EachIn node.getChildren()
				Local key:Object = DeserializeObject(TxmlNode(mapNode.getFirstChild()))
				Local value:Object = DeserializeObject(TxmlNode(mapNode.getLastChild()))

				map.Insert(key, value)
			Next
		End If

		Return map
	End Method

	Method Clone:TXMLSerializer()
		Return New TMapXMLSerializer
	End Method

End Type

Type TListXMLSerializer Extends TXMLSerializer

	Method TypeName:String()
		Return "TList"
	End Method

	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local list:TList = TList(obj)

		If list Then
			For Local item:Object = EachIn list
				SerializeObject(item, node)
			Next
		End If
	End Method

	Method Deserialize:Object(objType:TTypeId, node:TxmlNode)
		Local list:TList = TList(CreateObjectInstance(objType, node))

		If node.getChildren() Then
			For Local listNode:TxmlNode = EachIn node.getChildren()
				list.AddLast(DeserializeObject(listNode, True))
'				list.AddLast(DeserializeObject(listNode))
			Next
		End If

		Return list
	End Method

	Method Clone:TXMLSerializer()
		Return New TListXMLSerializer
	End Method

End Type

Type TIntMapXMLSerializer Extends TXMLSerializer

	Method TypeName:String()
		Return "TIntMap"
	End Method

	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local map:TIntMap = TIntMap(obj)

		If map Then
			For Local mapNode:TIntNode = EachIn map
				Local v:TxmlNode = node.addChild("e")
				If mapNode.Value() Then
					SerializeObject(mapNode.Value(), v)
				End If
				v.setAttribute("index", mapNode.Key())
			Next
		End If
	End Method

	Method Deserialize:Object(objType:TTypeId, node:TxmlNode)
		Local map:TIntMap = TIntMap(CreateObjectInstance(objType, node))
		If node.getChildren() Then
			Local ver:Int = GetFileVersion()

			For Local mapNode:TxmlNode = EachIn node.getChildren()
				Local index:Int = Int(mapNode.getAttribute("index"))
				Local obj:Object = DeserializeObject(mapNode)
				map.Insert(index, obj)
			Next
		End If
		Return map
	End Method

	Method Clone:TXMLSerializer()
		Return New TIntMapXMLSerializer
	End Method

End Type

Type TStringMapXMLSerializer Extends TXMLSerializer

	Method TypeName:String()
		Return "TStringMap"
	End Method

	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local map:TStringMap = TStringMap(obj)

		If map Then
			For Local mapNode:TStringNode = EachIn map
				Local n:TxmlNode = node.addChild("n")
				SerializeObject(mapNode.Key(), n.addChild("k"))
				SerializeObject(mapNode.Value(), n.addChild("v"))
			Next
		End If
	End Method

	Method Deserialize:Object(objType:TTypeId, node:TxmlNode)
		Local map:TStringMap = TStringMap(CreateObjectInstance(objType, node))

		If node.getChildren() Then
			Local ver:Int = GetFileVersion()

			For Local mapNode:TxmlNode = EachIn node.getChildren()
				Local keyNode:TxmlNode = TxmlNode(mapNode.getFirstChild())
				Local valueNode:TxmlNode = TxmlNode(mapNode.getLastChild())

				Local k:String = String(DeserializeObject(keyNode))
				Local v:Object = DeserializeObject(valueNode)
				map.Insert(k, v)
			Next
		End If

		Return map
	End Method

	Method Clone:TXMLSerializer()
		Return New TStringMapXMLSerializer
	End Method

End Type

TXMLPersistenceBuilder.RegisterDefault(New TIntMapXMLSerializer)
TXMLPersistenceBuilder.RegisterDefault(New TStringMapXMLSerializer)
TXMLPersistenceBuilder.RegisterDefault(New TMapXMLSerializer)
TXMLPersistenceBuilder.RegisterDefault(New TListXMLSerializer)

Extern
	Function bbEmptyStringPtr:Byte Ptr()
	Function bbNullObjectPtr:Byte Ptr()
	Function bbObjectRef:Byte Ptr(obj:Object)
	Function bbEmptyArrayPtr:Byte Ptr()
End Extern
