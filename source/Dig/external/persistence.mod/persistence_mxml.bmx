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
Import Text.xml
Import BRL.Reflection
Import Collections.IntMap
Import BRL.Map
Import Collections.ObjectList
Import "../../base.util.longmap.bmx"
Import BRL.Stream

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
	Field progressCallback:Int(progress:String, userData:Object)

	Field _sb:TStringBuilder = New TStringBuilder

	Rem
	bbdoc: Serialized formatting.
	about: Set to True to have the data formatted nicely. Default is False - off.
	End Rem
	Global format:Int = False

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
	Method SerializeToFile(obj:Object, file:Object)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."
		Free()
		SerializeObject(obj)

		If doc Then
			If TStream(file)
				doc.saveFile(file, False, format)
			'filename/string
			Else
				doc.saveFile(file, True, format)
			EndIf
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
			Return doc.ToStringFormat(format)
		End If
	End Method

	Method ProcessArray(arrayObject:Object, size:Int, node:TxmlNode, typeId:TTypeId)

		Local elementType:TTypeId = typeId.ElementType()

		Select elementType
			Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId ', UIntTypeId, ULongTypeId, LongIntTypeId, ULongIntTypeId

				Local sb:TStringBuilder = new TStringBuilder()
				
				For Local i:Int = 0 Until size

					Local aObj:Object = typeId.GetArrayElement(arrayObject, i)

					If i Then
						sb.Append(" ")
					End If
					sb.Append(String(aObj))
				Next
				
				node.SetContent(sb.ToString())
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

		'Ronny: inform someone about this specific field?
		If progressCallback
			Local metaProgress:String = f.MetaData("progress")
			If metaProgress
				progressCallback(metaProgress, f.Name())
			EndIf
		EndIf

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
	End Rem
	Method DeSerialize:Object(data:Object)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."

		If TxmlDoc(data) Then
			Return DeSerializeFromDoc(TxmlDoc(data))
		Else If TStream(data) Then
			Return DeSerializeFromStream(TStream(data))
		Else If String(data) Then
			Return DeSerializeObject(String(data), Null)
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
	End Rem
	Method DeSerializeFromFile:Object(filename:Object)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."
	
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
	End Rem
	Method DeSerializeFromStream:Object(stream:TStream)
		If Not _inited Throw "Use TXMLPersistenceBuilder to create TPersist instance."

		Rem
		Local data:String
		Local buf:Byte[2048]
		Local sb:TStringBuilder = new TStringBuilder

		While Not stream.Eof()
			Local count:Int = stream.Read(buf, 2048)
			sb.Append( String.FromBytes(buf, count) )
		Wend
		data = sb.ToString()
		Local obj:Object = DeSerializeObject(data, Null)
		EndRem

		Local obj:Object = DeSerializeObject(stream, Null)
		Free()
		Return obj
	End Method

	Method DeserializeByType:Object(objType:TTypeId, node:TxmlNode)
		'Ronny: skip loading elements having "nosave" metadata
		If objType.MetaData("nosave") And Not objType.MetaData("doload") Then Return Null
		'specific type interest?
		If progressCallback
			Local metaProgress:String = objType.MetaData("progress")
			If metaProgress
				progressCallback(metaProgress, objType.Name())
			EndIf
		EndIf


		Local serializer:TXMLSerializer = TXMLSerializer(serializers.ValueForKey(objType.Name()))
		If serializer Then
			Return serializer.Deserialize(objType, node)
		Else
			Local obj:Object = CreateObjectInstance(objType, node)
			'Ronny: try to let the type or a generic serializer handle it
			If Not DelegateDeserializeByType(objType, obj, node)
				'fall back to default field deserialization
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
	
	
	'tries to deserialize elements in the field so that potentially
	'stored objects can be referenced properly from other stored
	'objects (in other fields etc.)
	Method HandleMissingField:TTypeID(fieldNode:TxmlNode, fieldName:String, parent:object, parentType:TTypeId)
		'Local fieldNodeAttribute:String = fieldNode.getAttribute("type")
			
		'for now brl.reflection has a bug - until our fix
		'is merged into official repositories, we need
		'to circumvent it
		'this would segfault if attribute type ends with "]"
		'and the type is not found
		'Local serializedFieldTypeID:TTypeId = TTypeId.ForName(fieldNode.getAttribute("type"))
		Local serializedFieldTypeID:TTypeId
		local fieldTypeName:String = fieldNode.getAttribute("type")

		'for arrays we try to deserialize all contained objects (or strings)
		'so that references stay intact (elements in the array might contain
		'the original values - while others only reference it)
		If fieldTypeName.StartsWith("array:")
			'strip of "array:" and "[]" from "array:whatever[]"
			Local fieldTypeNameClean:String = fieldTypeName[6 .. fieldTypeName.length - 2 - 6]
			serializedFieldTypeID = TTypeId.ForName(fieldTypeNameClean)

			Select serializedFieldTypeID
				Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId
					'nothing to do
				Default
					For Local arrayNode:TxmlNode = EachIn fieldNode.getChildren()
						If not arrayNode.getAttribute("ref")
							DeSerializeObject("", arrayNode)
						EndIf
					Next
			End Select
		Else
			serializedFieldTypeID = TTypeId.ForName(fieldTypeName)
		EndIf


		If Not strictMode And serializedFieldTypeID
			'deserialize it, so that its reference exists
			Local deserializedObject:object
			'fall back to parent if reference-persisted
			'example:
			'an no longer existing field "currentAnimationName" of type
			'string will be single line if it is "reference"-persisted
			'
			'	<field name="currentAnimationName" ref="8OVR4" type="String" />
			'
			'compared to a one defining the reference):
			'
			'	<field name="currentAnimationName" type="String">
			'		<String id="1DUWSUY8PS">standfront</String>
			'	</field>
			
			'If serializedFieldTypeID.Name().ToLower() = "string" and fieldNode.getAttribute("ref")
			If fieldNode.getAttribute("ref")
				deserializedObject = DeSerializeObject("", fieldNode, True)
			Else
				'primitives can only be stored as "strings"
				Select fieldTypeName
					Case "byte", "short", "int", "long", "float", "double"
						deserializedObject = fieldNode.GetContent() 'string
					default
						deserializedObject = DeSerializeObject("", fieldNode)
				End Select
			EndIf


			Local parentTypeName:String
			if parentType then parentTypeName = parentType.name()
			If not DelegateHandleMissingField(parent, parentTypeName, fieldName, fieldTypeName, deserializedObject)
				Print "[WARNING] TPersistence: field ~q"+fieldNode.getAttribute("name")+"~q is no longer available. Created WorkAround-Storage."
			Else
				Print "[INFORMATION] TPersistence: Handled missing field: " + parentTypeName+"."+fieldName+":"+fieldTypeName+"."
			EndIf
		Else
			Print "[WARNING] TPersistence: field ~q"+fieldNode.getAttribute("name")+"~q is no longer available."
		EndIf
	End Method
	

	global specialCount:Int
	Method DeserializeFields(objType:TTypeId, obj:Object, node:TxmlNode)
		' does the node contain child nodes?
		Local childNodes:TObjectList = node.getChildren()

		If childNodes
			Local parentName:String = node.getAttribute("name")
			If not parentName and objType then parentName = objType.Name()

			For Local fieldNode:TxmlNode = EachIn childNodes
				' this should be a field
				If fieldNode.GetName() = "field" Then
					Local fieldName:String = fieldNode.getAttribute("name")
					Local fieldObj:TField = objType.FindField(fieldName)
					Local fieldType:String = fieldNode.getAttribute("type")
					
					' Ronny: skip unknown fields (no longer existing in the type)
					' or redirect to a different field if renamed
					If not fieldObj
						'if the field was just renamed, try to find
						'the new field to populate
						If fieldName
							Local newFieldName:String

							If parentName
								'print "missing field ... parentName="+parentName+ "  fieldName="+fieldName + "  objType.name="+objType.Name()
								newFieldName = DelegateRenamedFieldDetection(fieldName, parentName)
								'fetch new TField if a rename was defined
								If newFieldName <> fieldName 
									fieldObj = objType.FindField(newFieldName)
									
									If fieldObj
										fieldName = newFieldName
									EndIf
								EndIf
							EndIf
						EndIf
						
						If Not fieldObj
							HandleMissingField(fieldNode, fieldName, obj, objType)
							Continue
						EndIf

						'also refresh field type now
						fieldType = fieldObj.TypeId().Name()
						' As "arrays" in TPersistence-stuff have a "type" value of "array:TheType[]", 
						' it is required to add "array:" to it again
						If fieldType.Find("[]") > 0
							fieldType = "array:" + fieldType
						EndIf
					EndIf


					'Ronny: skip loading elements having "nosave" metadata
					If fieldObj.MetaData("nosave") And Not fieldObj.MetaData("doload") Then Continue

					'Ronny: inform someone about this specific field?
					If progressCallback
						Local metaProgress:String = fieldObj.MetaData("progress")
						If metaProgress
							progressCallback(metaProgress, fieldName)
						EndIf
					EndIf

					' Ronny: check if the current code knows the stored
					' but no longer known type under a different name.
					' This also allows handling of "compatible" type
					' changes (mytype.p:TBase -> mytype.p:TCompatibleBase)
					' with both types still being known to the code
					' As "arrays" in TPersistence-stuff have a "type" value of "array:TheType[]", 
					' it is required to extract "TheType[]" from it to be able to find a TTypeId
					Local pureFieldType:String = fieldType.Replace("array:", "")
					Local storedFieldTypeID:TTypeId = TTypeId.ForName(pureFieldType)
					Local targetFieldTypeID:TTypeId = fieldObj.TypeId()
					If Not storedFieldTypeID Or storedFieldTypeID <> targetFieldTypeID
						' It might have been renamed (or no longer be an
						' "extending" class but the original one).
						Local renamedFieldType:String = DelegateRenamedTypeDetection(pureFieldType, parentName + "." + fieldName)
						If renamedFieldType <> pureFieldType
							fieldType = renamedFieldType
							If fieldType.Find("[]") > 0 
								fieldType = "array:" + fieldType
							EndIf
							storedFieldTypeID = TTypeId.ForName(renamedFieldType)

							'rename the attribute "type" so follow up processes will
							'find the "new" type and do not need to do the rename part again
							fieldNode.SetAttribute("type", fieldType)
						EndIf
					EndIf


					' Ronny: delegate "primitive to object" conversions
					local isStoredPrimitive:Int = False
					local isFieldPrimitive:Int = False
					Select fieldType
						Case "byte", "short", "int", "long", "uint", "ulong", ..
						     "longint", "ulongint", "sizet", "float", "double"
							isStoredPrimitive = True
					End Select
					' only check field if stored is also a primitive
					' (both need to be true ...)
					If isStoredPrimitive
						Local fieldTypeName:String = fieldObj.TypeID().name()
						' assume stored and defined are same (should be
						' almost always the case)
						If storedFieldTypeID = targetFieldTypeID
							isFieldPrimitive = True
						Else
							Select fieldTypeName.ToLower()
								Case "int", "float", "double", "long", "byte", ..
								     "short", "sizet", "uint", "ulong", "longint", "ulongint"
									isFieldPrimitive = True
							End Select
						EndIf
					EndIf

					' primitives can be kind of "casted" (albeit with loss)
					if isStoredPrimitive and isFieldPrimitive
						_sb.SetLength(0)
						
						Select fieldType
							Case "byte", "short", "int"
								fieldObj.SetInt(obj, fieldNode.GetContent(_sb).toInt())
							Case "long"
								fieldObj.SetLong(obj, fieldNode.GetContent(_sb).toLong())
							Case "float"
								fieldObj.SetFloat(obj, fieldNode.GetContent(_sb).toFloat())
							Case "double"
								fieldObj.SetDouble(obj, fieldNode.GetContent(_sb).toDouble())
							Case "uint"
								fieldObj.SetUInt(obj, fieldNode.GetContent(_sb).toUInt())
							Case "sizet"
								fieldObj.SetSizeT(obj, fieldNode.GetContent(_sb).toSizeT())
							Case "ulong"
								fieldObj.SetULong(obj, fieldNode.GetContent(_sb).toULong())
							Case "longint"
								fieldObj.SetLongInt(obj, LongInt(fieldNode.GetContent(_sb).toLongInt())) ' FIXME : why do we need to cast here?
							Case "ulongint"
								fieldObj.SetULongInt(obj, fieldNode.GetContent(_sb).toULongInt())
						End Select
					Else
						Select fieldType
							'Ronny: Field is primitive, but serialized value is not
							Case "byte", "short", "int", "long", "uint", "ulong", ..
								 "longint", "ulongint", "sizet", "float", "double"

								Local convertedObject:Object = obj
								If DelegateDeserializationToType(convertedObject, fieldNode.getAttribute("name"), fieldType, fieldObj.TypeId().name(), fieldNode.GetContent())
									fieldObj.Set(obj, convertedObject)
								EndIf

							Default
								If fieldType.StartsWith("array:") Then

									Local arrayType:TTypeId = fieldObj.TypeId()
									Local arrayElementType:TTypeId = arrayType.ElementType()


									Local scalesi:Int[]
									Local scales:Int[] = fieldNode.getAttribute("scales", _sb).SplitInts(",")
									If scales.length > 1 Then
										scalesi = scales
									End If


									' for file Version 1+
									Select arrayElementType
										Case FloatTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Float[]
											If _sb.Length() > 0 Then
												values = _sb.SplitFloats(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case DoubleTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Double[]
											If _sb.Length() > 0 Then
												values = _sb.SplitDoubles(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case ByteTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Byte[]
											If _sb.Length() > 0 Then
												values = _sb.SplitBytes(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case ShortTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Short[]
											If _sb.Length() > 0 Then
												values = _sb.SplitShorts(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If
										
										Case IntTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Int[]
											If _sb.Length() > 0 Then
												values = _sb.SplitInts(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If
											
										Case LongTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Long[]
											If _sb.Length() > 0 Then
												values = _sb.SplitLongs(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case UIntTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:UInt[]
											If _sb.Length() > 0 Then
												values = _sb.SplitUInts(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case ULongTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:ULong[]
											If _sb.Length() > 0 Then
												values = _sb.SplitULongs(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If
										
										Case LongIntTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:LongInt[]
											If _sb.Length() > 0 Then
												values = _sb.SplitLongInts(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case ULongIntTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:ULongInt[]
											If _sb.Length() > 0 Then
												values = _sb.SplitULongInts(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If

										Case SizeTTypeId
											_sb.SetLength(0)
											fieldNode.GetContent(_sb).Trim()

											Local values:Size_T[]
											If _sb.Length() > 0 Then
												values = _sb.SplitSizeTs(" ")
											End If

											' Fast path for 1-dimensional arrays
											If scalesi.length = 0 Then
												fieldObj.Set(obj, values)
											Else
												' Multi-dimensional array - create and copy
												Local arrayObj:Object = arrayType.NewArray(values.length, scalesi)
												fieldObj.Set(obj, arrayObj)

												For Local i:Int = 0 Until values.length
													arrayType.SetArrayElement(arrayObj, i, values[i])
												Next
											End If


									Default
										Local arrayList:TObjectList = fieldNode.getChildren()

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
																Throw "[Array] Reference not mapped yet : " + ref
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
											'empty string - fileVersion >= 8 uses "String", not "string" ?
											'ElseIf fieldType = "String" and objectMap.Contains(ref)
											ElseIf fieldType.Equals("string", False) and objectMap.Contains(ref)
												fieldObj.Set(obj, "")
											Else
												Throw "[Field] Reference not mapped yet : " + ref
											End If
										Else
											'Ronny
											' check if the current programme knows how to handle the
											' no longer defined or changed data structure / type
											Local toSetObject:Object
											If storedFieldTypeID
												Local storedObject:Object = DeSerializeObject("", fieldNode)
												If storedFieldTypeID = targetFieldTypeID 'targetFieldTypeID is always valid/"known"
													'we can simply use the original format
													toSetObject = storedObject
												Else
													'deserialize it and pass it around to
													'get it converted into the desired format
													Local convertedObject:Object = DelegateDeserializationToType(storedObject, pureFieldType, targetFieldTypeID.name(), obj, parentName+"."+fieldName+":"+pureFieldType)
													If Not TPersistError(convertedObject)
														toSetObject = convertedObject
													EndIf
												EndIf
											Else
												Local nowKnownObject:Object = DelegateDeserializationOfUnknownType(pureFieldType, targetFieldTypeID.name(), fieldNode)
												If Not TPersistError(nowKnownObject)
													toSetObject = nowKnownObject
												EndIf
											EndIf
											fieldObj.Set(obj, toSetObject)
	'										fieldObj.Set(obj, DeSerializeObject("", fieldNode))
										End If
									End If
								End If
						End Select
					EndIf
				End If
			Next
		End If
	End Method


	'ronny
	Method DelegateRenamedTypeDetection:String(typeName:String, parentPath:String)
		if not converterTypeID then Return Null

		local m:TMethod = converterTypeID.FindMethod("GetRenamedTypeName")
		If not m Then Throw "Unknown function. Create function ~qGetRenamedTypeName:TTypeID(typeName:String, parentPath:String)~q in type ~q" + converterTypeID.name() +"~q."

		local newTypeName:String = String( m.Invoke(converterType, [object(typeName), object(parentPath)]) )
 		if newTypeName and newTypeName <> typeName
			If parentPath
				print "[INFORMATION] TPersistence: Renamed type ~q" + parentPath + ":" + typeName + "~q to ~q" + parentPath + ":" + newTypeName + "~q."
			Else
				print "[INFORMATION] TPersistence: Renamed type ~q" + typeName + "~q to ~q" + newTypeName + "~q."
			EndIf
 		EndIf
 		Return newTypeName
 	End Method


	'ronny
	Method DelegateRenamedFieldDetection:String(fieldName:string, parentName:String)
		if not converterTypeID then Return Null

		local m:TMethod  = converterTypeID.FindMethod("GetCurrentFieldName")
		If not m Then Throw "Unknown method. Create method ~qGetCurrentFieldName:String(fieldName:String, parentName:String)~q in type ~q" + converterTypeID.name() +"~q."

		'return null or the new field name
  		local newFieldName:String = String( m.Invoke(converterType, [object(fieldName), object(parentName)]) )
  		if newFieldName and newFieldName <> fieldName
 			print "[INFORMATION] TPersistence: Renamed field ~q" + fieldName + "~q to ~q" + newFieldName + "~q."
 		EndIf
 		Return newFieldName
 	End Method
 	
		
	'ronny
	'find and call a function which possibly deserializes a no longer
	'known type from the given node into an instance of the new type.
	Method DelegateDeserializationOfUnknownType:Object(typeName:String, newTypeName:String, node:Object)
		if not converterTypeID Then Return Null

		' try specialized "typename"-specific deserialization
 		Local deserializeFunction:TMethod = converterTypeID.FindMethod("DeSerialize"+typeName)
		if not deserializeFunction
			' or fall back to a generic deserializer for unknown types
			deserializeFunction = converterTypeID.FindMethod("DeserializeUnknownType")
			if not deserializeFunction
				Throw "unknown type: ~q"+typeName+"~q. To handle it, create function ~q"+("DeSerialize"+typeName)+"()~q or ~qDeSerializeUnknownType()~q."
			endif
		endif


		Local result:Object = deserializeFunction.Invoke(converterType, [object(typeName), object(newTypeName), node])
		if TPersistError(result)
 			Throw "Failed to deserialize ~q" + typeName + "~q. Function ~q" + deserializeFunction.name() + "~q does not handle that type."
 		endif

  		Return result
 	End Method
 	

	'ronny
	'find and call a function which deserializes given old type data
	'into a target type instance
	'sourceObject: the object to deserialize
	'sourceTypeName: name of the original type
	'targetTypeName: name of the target type
	'sourceIdentifier: eg. "TMyType.colour"
	'sourceParentObject: the parent of the object to deserialize (eg the type having a field)
	Method DelegateDeserializationToType:Object(sourceObject:Object, sourceTypeName:string, targetTypeName:string, sourceParentObject:object, sourceIdentifier:string)
 		Local sourceParentTypeID:TTypeID
 		Local deserializeName:string = "Deserialize"+ sourceTypeName + "To" + targetTypeName
 		Local deserializeName2:string = "DeserializeToType"
 		Local deserializeFunction:TMethod
 		Local functionContainer:object
 		If sourceParentObject 
			sourceParentTypeID = TTypeID.ForObject(sourceParentObject)
		EndIf
		If Not sourceIdentifier 
			If sourceParentTypeID
				sourceIdentifier = sourceParentTypeID.name()+":undefined_field"
			Else
				sourceIdentifier = "undefined_variable"
			EndIf
		EndIf
		
		'if a parent is defined, check if it contains a suiting deserializer
		If sourceParentTypeID
	 		functionContainer = sourceparentObject
			deserializeFunction = sourceParentTypeID.FindMethod(deserializeName)
		EndIf

		'search for a more generic function if no individual function was
 		'found
 		If Not deserializeFunction
 			If sourceParentTypeID
				deserializeFunction = sourceParentTypeID.FindMethod(deserializeName2)
			EndIf

  			'ask the generic converter
 			If Not deserializeFunction And converterTypeID
				deserializeFunction = converterTypeID.FindMethod(deserializeName)
				If Not deserializeFunction
					deserializeFunction = converterTypeID.FindMethod(deserializeName2)
				EndIf

				If deserializeFunction
					if not converterType then converterType = converterTypeID.NewObject()
					functionContainer = converterType
				EndIf
 			EndIf
 		EndIf

		'failed to find a valid deserializer function?
		If Not deserializeFunction
			Throw "~q"+sourceIdentifier+"~q requires conversion from ~q"+sourceTypeName+"~q to ~q"+targetTypeName+"~q). To handle it, create function ~q"+deserializeName+"()~q or ~q"+deserializeName2+"()~q."
		EndIf
		Local result:Object = deserializeFunction.Invoke(functionContainer, [sourceObject, object(sourceTypeName), object(targetTypeName), sourceParentObject])
		if TPersistError(result)
			Throw "Failed to deserialize ~q"+sourceIdentifier+"~q. Function ~q"+deserializeFunction.name()+"~q does not handle required conversion from ~q"+sourceTypeName+"~q to ~q"+targetTypeName+"~q."
 		EndIf

  		Return result
 	End Method


	'ronny
	Method DelegateHandleMissingField:Int(parent:object, parentTypeName:string, fieldName:string, fieldTypeName:string, fieldObject:object)
 		Local typeID:TTypeID = TTypeID.ForObject(parent)
 		Local handleName:string = "HandleMissingField"
 		Local handleFunction:TMethod
 		Local functionContainer:object = parent
 		if typeID then handleFunction = typeID.FindMethod(handleName)

		'ask the generic converter
 		if not handlefunction
			if converterTypeID
				handleFunction = converterTypeID.FindMethod(handleName)

				if handleFunction
					if not converterType then converterType = converterTypeID.NewObject()
					functionContainer = converterType
				endif
			endif

  			if not handleFunction
				Return False
 			endif
 		endif

  		local res:object = handleFunction.Invoke(functionContainer, [object(parentTypeName), object(fieldName), object(fieldTypeName), parent, fieldObject])
 		if not res
			Return False
 		endif

  		Return True
 	End Method


	'Ronny:
	'deserializes objects defined in "node" into "obj"
	Method DelegateDeserializeByType:Int(objType:TTypeId, obj:Object Var, node:TxmlNode)
		'no type information provided?
		If Not objType Then Return False

		Local mth:TMethod
		Local deserializationResult:Object = Null
		
		' serialized data in attribute?
		'serialized might be "" (eg. an empty TLowerString)
		Local serialized:String
		If node.tryGetAttribute("serialized", serialized)
			'check if there is a special "DeSerialize[classname]FromString" Method
			
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
				If mth Then mth.Invoke(deserializationResult, [Object(serialized)])
			EndIf
		Else
			'check if there is a special "DeSerialize[classname]FromNode" Method
			'defined for the object

			'check if a common serializer wants to handle it
			If serializer
				If Not serializerTypeID Then serializerTypeID = TTypeId.ForObject(serializer)
				mth = serializerTypeID.FindMethod("DeSerialize"+objType.Name()+"FromNode")
				If mth Then deserializationResult = mth.Invoke(serializer, [node, obj])
			EndIf

			'check if the type itself wants to handle it
			If Not deserializationResult Or Not serializer
				deserializationResult = obj
				mth = objType.FindMethod("DeSerialize"+objType.Name()+"FromNode")
				If mth Then mth.Invoke(deserializationResult, [node])
			EndIf
		EndIf

		' without method there happened no custom deserialization
		If mth
			'override referenced object
			If deserializationResult
				'assign obj (obj is passed as "var")
				obj = deserializationResult

				AddObjectRef(deserializationResult, node)
	'			objectMap.Insert(node.getAttribute("id"), deserializationResult)
				Return True
			EndIf
		EndIf

		Return False
	End Method


	Rem
	bbdoc:
	End Rem
	Method DeSerializeObject:Object(TextOrStream:Object, parent:TxmlNode = Null, parentIsNode:Int = False)
		Local node:TxmlNode

		If Not doc Then
			doc = TxmlDoc.readDoc(TextOrStream)
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
				'empty string?
				ElseIf node.getAttribute("type") = "String" and objectMap.Contains(ref)
					Return Null
				Else
rem
					'correct wrongly set reference for empty strings..
					if node.getAttribute("Type") = "String"
						obj = object("")
		objectMap.Insert(node.getAttribute("id"), obj)
						AddObjectRef(obj)
						Return obj
					EndIf
endrem
					Throw "[Object] Reference in node ~q" + node.GetName() + "~q not mapped yet : " + ref
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
							Local arrayList:TObjectList = node.getChildren()

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
													Throw "[Array2] Reference not mapped yet : " + ref
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


				'Ronny
				'check if the current programme knows the stored data structure / type
				if not objType
					'try to find the new typeID (eg a type was renamed)
					'compared to a "field" we only know the node name itself
					'and thus cannot do "parent specific" renames
					Local newObjTypeName:String = DelegateRenamedTypeDetection(nodeName, "")
					objType = TTypeID.ForName(newObjTypeName)
					if objType
						obj = DeserializeByType(objType, node)
					else
						obj = DelegateDeserializationOfUnknownType(nodeName, newObjTypeName, node)
						If TPersistError(obj)
							obj = Null
						EndIf
					endif
				else
					obj = DeserializeByType(objType, node)
				endif

				'obj = DeserializeByType(objType, node)
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
		Local vLong:Long = $FFFFFFFFFFFFFFFF:Long & Long(Byte Ptr(val))
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


Type TPersistError
	Field error:String
	
	Method New(s:String)
		self.error = s
	End Method
	
	Method ToString:String()
		return self.error
	End Method
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
		Return persist.DeserializeObject("", node, direct)
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

		Local childNodes:TObjectList = node.getChildren()
		If childNodes Then
			For Local mapNode:TxmlNode = EachIn childNodes
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

Type TLongMapXMLSerializer Extends TXMLSerializer

	Method TypeName:String()
		Return "TLongMap"
	End Method

	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local map:TLongMap = TLongMap(obj)

		If map Then
			For Local mapNode:TLongNode = EachIn map
				Local v:TxmlNode = node.addChild("e")
				If mapNode.Value() Then
					SerializeObject(mapNode.Value(), v)
				End If
				v.setAttribute("index", mapNode.Key())
			Next
		End If
	End Method

	Method Deserialize:Object(objType:TTypeId, node:TxmlNode)
		Local map:TLongMap = TLongMap(CreateObjectInstance(objType, node))
		If node.getChildren() Then
			Local ver:Int = GetFileVersion()

			For Local mapNode:TxmlNode = EachIn node.getChildren()
				Local index:Long = Long(mapNode.getAttribute("index"))
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

Type TIntMapXMLSerializer Extends TXMLSerializer

	Method TypeName:String()
		Return "TIntMap"
	End Method

	Method Serialize(tid:TTypeId, obj:Object, node:TxmlNode)
		Local map:TIntMap = TIntMap(obj)

		If map Then
			For Local mapNode:TIntKeyValue = EachIn map
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
			For Local mapNode:TStringKeyValue = EachIn map
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

TXMLPersistenceBuilder.RegisterDefault(New TLongMapXMLSerializer)
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
