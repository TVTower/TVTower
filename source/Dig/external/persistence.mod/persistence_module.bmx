' Copyright (c) 2008-2012 Bruce A Henderson
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
bbdoc: Persistence
about: An object-persistence framework.
End Rem
Module BaH.Persistence

ModuleInfo "Version: 1.00"
ModuleInfo "Author: Bruce A Henderson"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: 2008-2012 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release"

Import BaH.libxml
Import BRL.Reflection
Import BRL.Map
Import BRL.Stream

Rem
bbdoc: Object Persistence.
End Rem
Type TPersist

	Rem
	bbdoc: File format version
	End Rem
	Const BMO_VERSION:Int = 5

	Field doc:TxmlDoc
	Field objectMap:TMap = New TMap

	Field lastNode:TxmlNode

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

	Rem
	bbdoc: Node-depth of XML to support when de-serializing.
	about: Default is 1024.
	<p>
	If you have any problems with this, make it bigger.
	</p>
	End Rem
	Global maxDepth:Int = xmlParserMaxDepth

	Field fileVersion:Int

	Rem
	bbdoc: Serializes the specified Object into a String.
	End Rem
	Function Serialize:String(obj:Object)
		Local ser:TPersist = New TPersist

		Local s:String = ser.SerializeToString(obj)
		ser.Free()

		Return s
	End Function

	Method Free()
		If doc Then
			doc.Free()
			doc = Null
		End If
		objectMap.Clear()
	End Method

	Rem
	bbdoc: Serializes an Object to a String.
	End Rem
	Method SerializeToString:String(obj:Object)
		Free()
		SerializeObject(obj)

		Return ToString()
	End Method

	Rem
	bbdoc: Serializes an Object to the file @filename.
	End Rem
	Method SerializeToFile(obj:Object, filename:String)
		Free()
		SerializeObject(obj)

		If doc Then
			If compressed Then
				doc.setCompressMode(9)
			Else
				doc.setCompressMode(0)
			End If
			doc.saveFormatFile(filename, format)
		End If
		Free()
	End Method

	Rem
	bbdoc: Serializes an Object to a TxmlDoc structure.
	about: It is up to the user to free the returned TxmlDoc object.
	End Rem
	Method SerializeToDoc:TxmlDoc(obj:Object)
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
			If compressed Then
				doc.setCompressMode(9)
			Else
				doc.setCompressMode(0)
			End If
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
	Method SerializeObject(obj:Object, parent:TxmlNode = Null)

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

			Local objectIsArray:Int = False

			Local tid:TTypeId = TTypeId.ForObject(obj)
			Local tidName:String = tid.Name()

			' Is this an array "Object" ?
			If tidName.EndsWith("[]") Then
				tidName = "_array_"
				objectIsArray = True
			End If

			Local node:TxmlNode = parent.addChild(tidName)

			Local objRef:String = GetObjRef(obj)
			node.setAttribute("ref", objRef)
			objectMap.Insert(objRef, obj)

			' is this a TMap object?
			If tidName = "TMap" Then

				' special case for TMaps
				' They have a Global "nil" object which needs to be referenced properly.
				' We add a specific reference to nil, which we'll use to re-reference when we de-serialize.

				Local ref:String = GetObjRef(New TMap._root)
				If Not Contains(ref, New TMap._root) Then
					'Local node:TxmlNode = parent.addChild("TMap_nil")
					node.setAttribute("nil", ref)
					objectMap.Insert(ref, New TMap._root)
				End If
			End If

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
					node.SetContent(String(obj))
				End If

				For Local f:TField = EachIn tid.EnumFields()

					If f.MetaData("nopersist") Then
						Continue
					End If

					Local fieldType:TTypeId = f.TypeId()

					Local fieldNode:TxmlNode = node.addChild("field")
					fieldNode.setAttribute("name", f.Name())

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
							fieldNode.setContent(f.GetFloat(obj))
						Case DoubleTypeId
							t = "double"
							fieldNode.setContent(f.GetDouble(obj))
						Case StringTypeId
							t = "string"
							' only if not empty
							Local s:String = f.GetString(obj)
							If s Then
								fieldNode.setContent(s)
							End If
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

								If fieldObject Then
									If Not Contains(fieldRef, fieldObject) Then
										SerializeObject(fieldObject, fieldNode)
									Else
										fieldNode.setAttribute("ref", fieldRef)
									End If
								End If
							End If
					End Select

					fieldNode.setAttribute("type", t)

				Next
			End If

		End If

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
	Function DeSerialize:Object(data:Object)
		Local ser:TPersist = New TPersist

		xmlParserMaxDepth = maxDepth

		If TxmlDoc(data) Then
			Return ser.DeSerializeFromDoc(TxmlDoc(data))
		Else If TStream(data) Then
			Return ser.DeSerializeFromStream(TStream(data))
		Else If String(data) Then
			Return ser.DeSerializeObject(String(data))
		End If
	End Function

	Rem
	bbdoc: De-serializes @doc into an Object structure.
	about: It is up to the user to free the supplied TxmlDoc.
	End Rem
	Method DeSerializeFromDoc:Object(xmlDoc:TxmlDoc)
		doc = xmlDoc

		xmlParserMaxDepth = maxDepth

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
	Method DeSerializeFromFile:Object(filename:String)

		xmlParserMaxDepth = maxDepth

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
		Local data:String
		Local buf:Byte[2048]

		xmlParserMaxDepth = maxDepth

		While Not stream.Eof()
			Local count:Int = stream.Read(buf, 2048)
			data:+ String.FromBytes(buf, count)
		Wend

		Local obj:Object = DeSerializeObject(data)
		Free()
		Return obj
	End Method

	Rem
	bbdoc:
	End Rem
	Method DeSerializeObject:Object(text:String, parent:TxmlNode = Null)

		Local node:TxmlNode

		If Not doc Then
			xmlParserMaxDepth = maxDepth

			doc = TxmlDoc.parseDoc(text)
			parent = doc.GetRootElement()
			fileVersion = parent.GetAttribute("ver").ToInt() ' get the format version
			node = TxmlNode(parent.GetFirstChild())
			lastNode = node
		Else
			If Not parent Then
				' find the next element node, if there is one. (content are also "nodes")
				node = TxmlNode(lastNode.NextSibling())
				While node And (node.getType() <> XML_ELEMENT_NODE)
					node = TxmlNode(node.NextSibling())
				Wend
				If Not node Then
					Return Null
				End If
				lastNode = node
			Else
				node = TxmlNode(parent.GetFirstChild())
				lastNode = node
			End If
		End If

		Local obj:Object


		If node Then

			Local nodeName:String = node.GetName()

			' Is this an array "Object" ?
			If nodeName = "_array_" Then

				Local objType:TTypeId = TTypeId.ForName(node.getAttribute("type") + "[]")

				Local size:Int = node.getAttribute("size").toInt()
				obj = objType.NewArray(size)
				objectMap.Insert(node.getAttribute("ref"), obj)

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
													Throw New "Reference not mapped yet : " + ref
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
					objectMap.Insert(node.getAttribute("ref"), obj)
					Return obj
				End If

				If nodeName = "TMap" Then

					' special case for TMaps
					' They have a Global "nil" object which needs to be referenced properly.

					Local attr:String = node.getAttribute("nil")
					If attr Then
						objectMap.Insert(attr, New TMap._root)
					End If
				End If

				' create the object
				obj = objType.NewObject()
				objectMap.Insert(node.getAttribute("ref"), obj)

				' does the node contain child nodes?
				If node.getChildren() <> Null Then
					For Local fieldNode:TxmlNode = EachIn node.getChildren()

						' this should be a field
						If fieldNode.GetName() = "field" Then

							Local fieldObj:TField = objType.FindField(fieldNode.getAttribute("name"))

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
								Case "string"
									fieldObj.SetString(obj, fieldNode.GetContent())
								Default
									If fieldType.StartsWith("array:") Then

										Local arrayType:TTypeId = fieldObj.TypeId()
										Local arrayElementType:TTypeId = arrayType.ElementType()

										If fileVersion Then

											' for file version 3+
											Local scalesi:Int[]
											Local scales:String[] = fieldNode.getAttribute("scales").split(",")
											If scales.length > 1 Then
												scalesi = New Int[scales.length]
												For Local i:Int = 0 Until scales.length
													scalesi[i] = Int(scales[i])
												Next
											End If

											' for file Version 1+
											Select arrayElementType
												Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId

													Local arrayList:String[] = fieldNode.GetContent().Split(" ")
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
																			Throw New "Reference not mapped yet : " + ref
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
											' For file version 0 (zero)

											Local arrayList:TList = fieldNode.getChildren()
											If arrayList 'Birdie
												Local arrayObj:Object = arrayType.NewArray(arrayList.Count())
												fieldObj.Set(obj, arrayObj)

												Local i:Int
												For Local arrayNode:TxmlNode = EachIn arrayList

													Select arrayElementType
														Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId, StringTypeId
															arrayType.SetArrayElement(arrayObj, i, arrayNode.GetContent())
														Default
															arrayType.SetArrayElement(arrayObj, i, DeSerializeObject("", arrayNode))
													End Select

													i:+ 1
												Next
											EndIf
										End If
									Else
										' is this a reference?
										Local ref:String = fieldNode.getAttribute("ref")
										If ref Then
											Local objRef:Object = objectMap.ValueForKey(ref)
											If objRef Then
												fieldObj.Set(obj, objRef)
											Else
												Throw New "Reference not mapped yet : " + ref
											End If
										Else
											fieldObj.Set(obj, DeSerializeObject("", fieldNode))
										End If
									End If
							End Select

						End If

					Next
				End If
			End If
		End If

		Return obj

	End Method


	Function GetObjRef:String(obj:Object)
		Return Base36(Int(Byte Ptr(obj)))
	End Function

	Function Base36:String( val:Int )
		Local vLong:Long = $FFFFFFFF & Long(Byte Ptr(val))
		Local buf:Short[6]
		For Local k:Int=5 To 0 Step -1
			Local n:Int=(vLong Mod 36) + 48
			If n > 57 n:+ 7
			buf[k]=n
			vLong = vLong / 36
		Next
		Return String.FromShorts( buf,6 )
	End Function

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
