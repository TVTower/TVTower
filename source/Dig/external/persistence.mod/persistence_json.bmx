' Copyright (c) 2016 Bruce A Henderson
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
bbdoc: Persistence JSON
about: An JSON-based object-persistence framework. 
End Rem
rem
Module BaH.PersistenceJSON

ModuleInfo "Version: 1.00"
ModuleInfo "Author: Bruce A Henderson"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: 2016 Bruce A Henderson"

ModuleInfo "History: 1.00"
ModuleInfo "History: Initial Release"
endrem

Import BaH.jansson
?Not bmxng
'using custom to have support for const/function reflection
Import "../reflectionExtended/reflection.bmx"
?bmxng
'ng has it built-in!
Import BRL.Reflection
?
Import BRL.Map
Import BRL.TextStream


Rem
bbdoc: Object Persistence.
End Rem
Type TPersistJSON

	Rem
	bbdoc: File format version
	End Rem
	Const BMO_VERSION:Int = 6

	' root object
	Field doc:TJSONObject
	
	' def object
	Field defs:TJSONObject
	
	' data object
	Field data:TJSONArray
	
	Field objectMap:TMap = New TMap
	
	Field types:TMap = New TMap
	
	' type table for deserializing
	Field registry:TMap
	' maps all refs to a registry entry for deserializing
	Field refsRegistry:TMap

	
	Rem
	bbdoc: Serialized formatting.
	about: Set to True to have the data formatted nicely. Default is False - off.
	End Rem
	Global format:Int = False
	
	Field fileVersion:Int

	'Added by Ronny:
	'a special connected type handling conversions of stored field contents
	'no longer matching up the definitions of a field (= types differing)
	Field converterTypeID:TTypeID
	Field converterType:object
	'a connected type overriding serialization/deserialization of elements
	'by containing Methods:
	'- SerializeTTypeNameToString() and
	'- DeSerializeTTypeNameFromString()
	Field serializer:object
	Field serializerTypeID:TTypeID

	
	Rem
	bbdoc: Serializes the specified Object into a String.
	End Rem
	Function Serialize:String(obj:Object)
		Local ser:TPersistJSON = New TPersistJSON
		
		Local s:String = ser.SerializeToString(obj)
		ser.Free()
		
		Return s
	End Function
	
	Method Free()
		If doc Then
			doc = Null
			defs = Null
			data = Null
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
			SaveText(ToString(), filename)
		End If
		Free()
	End Method
	
	Rem
	bbdoc: Serializes an Object to a TxmlDoc structure.
	about: It is up to the user to free the returned TxmlDoc object.
	End Rem
	'Method SerializeToDoc:TxmlDoc(obj:Object)
	'	Free()
	'	SerializeObject(obj)
	'	
	'	Local exportDoc:TxmlDoc = doc
	'	doc = Null
	'	Free()
	'	Return exportDoc
	'End Method

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
			If format Then
				Return doc.SaveString(JSON_PRESERVE_ORDER,2)
			Else
				Return doc.SaveString(JSON_PRESERVE_ORDER | JSON_COMPACT, 0)
			End If
		End If
	End Method

	Method ProcessArray(arrayObject:Object, size:Int, node:TJSONArray, typeId:TTypeId)

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
				
				node.Append(New TJSONString.Create(content))

			Default

				For Local i:Int = 0 Until size
				
					Local aObj:Object = typeId.GetArrayElement(arrayObject, i)
				
					Select elementType
						Case StringTypeId
							node.append(New TJSONString.Create(String(aObj)))
						Default
							If aObj Then
								Local objRef:String = GetObjRef(aObj)
								
								' file version 5 ... array cells can contain references
								If Not Contains(objRef, aObj) Then
									SerializeObject(aObj, node)
								Else
									node.Append(New TJSONString.Create(objRef))
								End If
							Else
								node.Append(New TJSONArray.Create())
							End If
					End Select
				Next
				
		End Select
		
	End Method

	Method RegisterType(tid:TTypeId, name:String)
		If name <> "_array_" And name <> "Object" Then
			Local refs: TJSONArray = TJSONArray(types.ValueForKey(name))
			If Not refs Then
				refs = New TJSONArray.Create()
				types.Insert(name, refs)


				Local fields:TJSONObject = New TJSONObject.Create()
				defs.Set(name, fields)
				
				Local decl:TJSONArray = New TJSONArray.Create()
				
				fields.Set("decl", decl)
				fields.Set("refs", refs)

				For Local f:TField = EachIn tid.EnumFields()
				
					If f.MetaData("nopersist") or f.MetaData("nosave") Then
						Continue
					End If
				
					Local fieldType:TTypeId = f.TypeId()
					
					Local fld:TJSONObject = New TJSONObject.Create()
					decl.Append(fld)

					Local t:String
					Select fieldType
						Case ByteTypeId
							fld.Set(f.Name(), New TJSONString.Create("byte"))
						Case ShortTypeId
							fld.Set(f.Name(), New TJSONString.Create("short"))
						Case IntTypeId
							fld.Set(f.Name(), New TJSONString.Create("int"))
						Case LongTypeId
							fld.Set(f.Name(), New TJSONString.Create("long"))
						Case FloatTypeId
							fld.Set(f.Name(), New TJSONString.Create("float"))
						Case DoubleTypeId
							fld.Set(f.Name(), New TJSONString.Create("double"))
						Case StringTypeId
							fld.Set(f.Name(), New TJSONString.Create("string"))
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
								
								fld.Set(f.Name(), New TJSONString.Create(t))

							Else

								fld.Set(f.Name(), New TJSONString.Create(t))
								
								RegisterType(fieldType, t)

							End If

					End Select

				Next



			End If
		End If
	End Method

	Method AddTypeRef(name:String, ref:String)
		If name <> "_array_" Then
			Local refs:TJSONArray = TJSONArray(types.ValueForKey(name))
			If refs Then
				refs.Append(New TJSONString.Create(ref))
			End If
		End If
	End Method

	Rem
	bbdoc: 
	End Rem
	Method SerializeObject(obj:Object, parent:TJSONArray = Null)
	
		If Not doc Then
			doc = New TJSONObject.Create()
			defs = New TJSONObject.Create()
			data = New TJSONArray.Create()
			
			parent = data
			
			Local root:TJSONObject = New TJSONObject.Create()
			doc.Set("bmo", root)
			root.Set("ver", New TJSONInteger.Create(BMO_VERSION))
			root.Set("def", defs)
			root.Set("data", data)
		Else
			If Not parent Then
				parent = data
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
			
			RegisterType(tid, tidName)
			
			Local node:TJSONArray = New TJSONArray.Create()
			
			Local objRef:String = GetObjRef(obj)

			Local ref:TJSONString = New TJSONString.Create(objRef)
			Local fields:TJSONArray = New TJSONArray.Create()
			
			node.Append(ref)
			node.Append(fields)

			parent.Append(node)


			' is this a TMap object?
			If tidName = "TMap" Then

				' special case for TMaps
				' They have a Global "nil" object which needs to be referenced properly.
				' We add a specific reference to nil, which we'll use to re-reference when we de-serialize.

				Local ref:String = GetObjRef(New TMap._root)
				If Not Contains(ref, New TMap._root) Then
					objectMap.Insert(ref, New TMap._root)
					AddTypeRef(tidName, ref)
				End If
			End If

			objectMap.Insert(objRef, obj)
			AddTypeRef(tidName, objRef)

			' We need to handle array objects differently..
			If objectIsArray Then
			
				tidName = tid.Name()[..tid.Name().length - 2]
				
				Local size:Int
if tidName.ToLower() = "null"
	throw "ups"
	tidName = "object"
endif
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

				If size > 0 Then
				
					ProcessArray(obj, size, node, tid)

				End If
			
			Else
 
				' special case for String object
				If tid = StringTypeId Then
					fields.Append(New TJSONString.Create(String(obj)))
				End If

rem ronny
				'Ronny: added "Serialize[classname]ToString"-support
				'check if there is a special "Serialize[classname]ToString" Method
				'defined for the object
				'only do serialization, if the way back is defined too
				local serialized:int = False
				Local serializedString:String
				Local mth:TMethod, mth2:TMethod
				'check if a common serializer wants to handle it
				If serializer
					if not serializerTypeID then serializerTypeID = TTypeID.ForObject(serializer)
					mth = serializerTypeID.FindMethod("Serialize"+tid.name()+"ToString")
					mth2 = serializerTypeID.FindMethod("DeSerialize"+tid.name()+"FromString")
					If mth And mth2
						'append the to-serialize-obj as param
						serializedString = String( mth.Invoke(serializer, [obj]) )
					endif
				endif

				'check if the type itself wants to handle it
				if not serializedString
					mth = tid.FindMethod("Serialize"+tid.name()+"ToString")
					mth2 = tid.FindMethod("DeSerialize"+tid.name()+"FromString")
					If mth And mth2
						serializedString = String( mth.Invoke(obj) )
					endif
				endif
				'no need to check wether "serialized" is <> "" (might be
				'empty on purpose!) - if mth/mth2 exist, then we trust
				'that methods to serialize properly
				If mth and mth2 'and serializedString
					'attributes are already encoded, so encoding it now
					'would lead to double-encoding
					'serializedString = doc.encodeEntities(serializedString)

					fields.Append(New TJSONString.Create(s))
					node.setAttribute("serialized" ,serializedString)
					serialized = True
				endif


				'if the method is not existing - parse each field
				if not serialized
endrem
						
				For Local f:TField = EachIn tid.EnumFields()
				
					If f.MetaData("nopersist") or f.MetaData("nosave") Then
						Continue
					End If
				
					Local fieldType:TTypeId = f.TypeId()
					
					Local t:String
					Select fieldType
						Case ByteTypeId
							fields.Append(New TJSONInteger.Create(f.GetInt(obj)))
						Case ShortTypeId
							fields.Append(New TJSONInteger.Create(f.GetInt(obj)))
						Case IntTypeId
							fields.Append(New TJSONInteger.Create(f.GetInt(obj)))
						Case LongTypeId
							fields.Append(New TJSONInteger.Create(f.GetLong(obj)))
						Case FloatTypeId
							'Ronny: save some space
							'if the float is xx.0000, write it without
							'the ".0000" part (-> as int)
							Local v:Float = f.GetFloat(obj)
							If Float(Int(v)) = v
								fields.Append(New TJSONInteger.Create(int(f.GetFloat(obj))))
							Else
								fields.Append(New TJSONReal.Create(f.GetFloat(obj)))
							EndIf
						Case DoubleTypeId
							fields.Append(New TJSONReal.Create(f.GetDouble(obj)))
						Case StringTypeId
							Local s:String = f.GetString(obj)
							fields.Append(New TJSONString.Create(s))
						Default

							If fieldType.ExtendsType( ArrayTypeId ) Then
	
								' prefix and strip brackets
								Local dims:Int = t.split("[").length
								
								dims = fieldType.ArrayDimensions(f.Get(obj))

								'Ronny: skip handling 0 sized arrays
								Local arrSize:Int = fieldType.ArrayLength(f.Get(obj))
								'on mac os x "0 sized"-arrays sometimes return dims to be veeeery big 
								If arrSize = 0 Then dims = 1
								'it also happens to others (Bruceys Linux box)
								if dims < 0 or dims > 1000000 then dims = 1

								If dims > 1 Then
									Local scales:String
									If dims > 1 Then
										For Local i:Int = 0 Until dims - 1
											scales :+ (fieldType.ArrayLength(f.Get(obj), i) / fieldType.ArrayLength(f.Get(obj), i + 1))
											scales :+ ","
										Next
										
									End If
									scales:+ fieldType.ArrayLength(f.Get(obj), dims - 1)
									
									
									Local arr:TJSONArray = New TJSONArray.Create()
									arr.Append(New TJSONString.Create(scales))
									
									fields.Append(arr)

									ProcessArray(f.Get(obj), fieldType.ArrayLength(f.Get(obj)), arr, fieldType)
								EndIf

							Else

								Local fieldObject:Object = f.Get(obj)

								If fieldObject Then
									Local fieldRef:String = GetObjRef(fieldObject)
	
									If Not Contains(fieldRef, fieldObject) Then
										SerializeObject(fieldObject, fields)
									Else
										'fieldNode.setAttribute("ref", fieldRef)
										fields.Append(New TJSONString.Create(fieldRef))
									End If
								Else
									fields.Append(New TJSONArray.Create())
								End If
							End If

					End Select
				
				Next
			End If

		End If
		
	End Method

	Rem
	bbdoc: De-serializes @text into an Object structure.
	about: Accepts a TxmlDoc, TStream or a String (of data).
	End Rem
	Function DeSerialize:Object(data:Object)
		Local ser:TPersistJSON = New TPersistJSON
		
		If TJSONObject(data) Then
			Return ser.DeSerializeFromDoc(TJSONObject(data))
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
	Method DeSerializeFromDoc:Object(jsonDoc:TJSONObject)
		doc = jsonDoc

		'xmlParserMaxDepth = maxDepth

		'Local root:TxmlNode = doc.GetRootElement()
		'fileVersion = root.GetAttribute("ver").ToInt() ' get the format version
		'Local obj:Object = DeSerializeObject("", root)
		'doc = Null
		'Free()
		'Return obj
	End Method

	Rem
	bbdoc: De-serializes the file @filename into an Object structure.
	End Rem
	Method DeSerializeFromFile:Object(filename:String)
	
		Local txt:String = LoadText(filename)

		Local obj:Object = DeSerializeObject(txt)
		Free()
		Return obj
	End Method

	Rem
	bbdoc: De-serializes @stream into an Object structure.
	End Rem
	Method DeSerializeFromStream:Object(stream:TStream)
		Local data:String
		Local buf:Byte[4096]

		While Not stream.Eof()
			Local count:Int = stream.Read(buf, 2048)
			data:+ String.FromBytes(buf, count)
		Wend
	
		Local obj:Object = DeSerializeObject(data)
		Free()
		Return obj
	End Method

	' holds information of all types and fields persisted.
	' deserialize uses this defined field order to recreate object structure.
	Method BuildTypeRegistry()
		' reset registry
		registry = New TMap
		refsRegistry = New TMap
	
		For Local dType:TJSONObject = EachIn defs
		
			Local decls:TJSONArray = TJSONArray(dType.Get("decl"))
			Local declRefs:TJSONArray = TJSONArray(dType.Get("refs"))
			
			Local entry:TPersistJSONRegistryEntry = New TPersistJSONRegistryEntry
			entry.name = dType.key
			
			' typeid
			Local id:TTypeId = TTypeId.ForName(dType.key)
			entry.id = id
			
			entry.fields = New TField[decls.Size()]
			
			Local index:Int
			' used fields
			For Local decl:TJSONObject = EachIn decls

				For Local fld:TJSONString = EachIn decl
					entry.fields[index] = id.FindField(fld.key)
				Next
				index:+ 1

			Next
			
			' add to registry
			registry.Insert(dType.key, entry)
			
			' map refs
			For Local ref:TJSONString = EachIn declRefs
				Local r:String = ref.Value()
				entry.refs.AddLast(r)
				refsRegistry.Insert(r, entry)
			Next
			
		Next
		
	End Method
	
	Rem
	bbdoc: 
	End Rem
	Method DeSerializeObject:Object(Text:String, parent:TJSONArray = Null, id:TTypeId = Null)

		Local node:TJSONArray
		
		If Not doc Then
			Local error:TJSONError
			
			Local jsonDoc:TJSON = TJSON.Load(Text, 0, error)
			
			If TJSONObject(jsonDoc) Then
				doc = TJSONObject(jsonDoc)
			Else
				' should be an object
				' TODO : error
				Return Null
			End If
			
			Local root:TJSONObject = TJSONObject(doc.Get("bmo"))
			
			If Not root Then
				' missing bmo object
				' TODO : error
				Return Null
			End If
			
			Local ver:TJSONInteger = TJSONInteger(root.Get("ver"))
			
			If Not ver Then
				' missing version...
				' TODO : error
				Return Null
			End If
			
			fileVersion = ver.Value()
			defs = TJSONObject(root.Get("def"))
			
			If Not defs Then
				' missing defs...
				' TODO : error
				Return Null
			End If
			
			BuildTypeRegistry()
			
			data = TJSONArray(root.Get("data"))

			parent = data
			
			node = TJSONArray(parent.Get(0))
		Else
			If Not parent Then
				' ??
			Else
				node = parent
			End If
		End If
		
		Local obj:Object 

		If node Then
		
			Local jsonRef:TJSONString = TJSONString(node.Get(0))
			
			If Not jsonRef
				' TODO error
				Return Null
			End If
			
			Local ref:String = jsonRef.Value()
		
		
			' Is this an array "Object" ?
			If  ref = "_array_" Then

				Throw "TODO : handle arrays as base instance"
			Else
			
				If objectMap.Contains(ref) Then
					Return objectMap.ValueForKey(ref)
				End If
			
			
				Local reg:TPersistJSONRegistryEntry = TPersistJSONRegistryEntry(refsRegistry.ValueForKey(ref))
			
				Local objType:TTypeId
				
				If Not reg Then
					If Not id Then
						' TODO error
						Return Null
					End If
					objType = id
				Else
					objType = reg.id
				End If
	
				' special case for String object
				If objType = StringTypeId Then
					obj = TJSONString(TJSONArray(node.Get(1)).Get(0)).Value()
					objectMap.Insert(ref, obj)
					Return obj
				End If

				If reg.name = "TMap" Then

					' special case for TMaps
					' They have a Global "nil" object which needs to be referenced properly.

					Local rootRef:String = String(reg.refs.First())
					If rootRef Then
						objectMap.Insert(rootRef, New TMap._root)
					End If
				End If

				' create the object
				obj = objType.NewObject()
				objectMap.Insert(ref, obj)

				Local fieldArray:TJSONArray = TJSONArray(node.Get(1))

				Local count:Int = fieldArray.Size()

				' iterate over the fields
				For Local i:Int = 0 Until count
				
					Local fieldObj:TField = reg.fields[i]
					
					Local fieldNode:TJSON = fieldArray.Get(i)
rem
					'Ronny: serialized data?
					If fieldNode.key = "serialized" Then
						'check if there is a special
						'"DeSerialize[classname]FromString" method defined
						'for the object
						Local mth:TMethod = objType.FindMethod("DeSerialize"+objType.name()+"FromString")
						If mth Then mth.Invoke(obj, [TJSONString(fieldNode).Value()])
					EndIf
endrem
	

					'Ronny: skip unknown fields (no longer existing in the type)
					If Not fieldObj Then
						Print "[WARNING] TPersistence: field ~q"+fieldNode.key+"~q is no longer available."
						Continue
					End If


					'Ronny: skip loading elements having "nosave" metadata
					If fieldObj.MetaData("nosave") or fieldObj.MetaData("nopersist") Then
						Continue
					End If


					Local fieldType:TTypeId = fieldObj.TypeId()
					Select fieldType
						Case ByteTypeId, ShortTypeId, IntTypeId
							fieldObj.SetInt(obj, Int(TJSONInteger(fieldNode).Value()))
						Case LongTypeId
							fieldObj.SetLong(obj, TJSONInteger(fieldNode).Value())
						Case FloatTypeId
							fieldObj.SetFloat(obj, Float(TJSONReal(fieldNode).Value()))
						Case DoubleTypeId
							fieldObj.SetDouble(obj, TJSONReal(fieldNode).Value())
						Case StringTypeId
							fieldObj.SetString(obj, TJSONString(fieldNode).Value())

						Default

							If fieldType.ExtendsType( ArrayTypeId ) Then

								Local arrayType:TTypeId = fieldObj.TypeId()
								Local arrayElementType:TTypeId = arrayType.ElementType()

								Local scalesString:TJSONString = TJSONString(TJSONArray(fieldNode).Get(0))
								
								
									
									' for file version 3+
									Local scalesi:Int[]
									Local scales:String[] = scalesString.Value().split(",")
									If scales.length > 1 Then
										scalesi = New Int[scales.length]
										For Local i:Int = 0 Until scales.length
											scalesi[i] = Int(scales[i])
										Next
									End If
									
									' for file Version 1+
									Select arrayElementType
										Case ByteTypeId, ShortTypeId, IntTypeId, LongTypeId, FloatTypeId, DoubleTypeId
										
											Local dataString:TJSONString = TJSONString(TJSONArray(fieldNode).Get(1))
										
											Local arrayList:String[]
											Local content:String = dataString.Value().Trim()

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
								
											Local size:Int = TJSONArray(fieldNode).Size()
											'Local arrayList:TList = fieldNode.getChildren()
											
											
											If size > 1
											
												Local arrayObj:Object = arrayType.NewArray(size - 1, scalesi)
												fieldObj.Set(obj, arrayObj)
												
												Local i:Int
												For Local n:Int = 1 Until size
												
													Local fieldArrayNode:TJSON = TJSONArray(fieldNode).Get(n)
				
													Select arrayElementType
				
														Case StringTypeId
															arrayType.SetArrayElement(arrayObj, n-1, TJSONString(fieldArrayNode).Value())
														Default
															
															' file version 5 ... array cells can contain references
															' is this a reference?
															If TJSONString(fieldArrayNode) Then
																Local ref:String = TJSONString(fieldArrayNode).Value()
																If ref Then
																	Local objRef:Object = objectMap.ValueForKey(ref)
																	If objRef Then
																		arrayType.SetArrayElement(arrayObj, n-1, objRef)
																	Else
																		Throw "Reference not mapped yet : " + ref
																	End If
																End If
															Else

																Local objArray:TJSONArray = TJSONArray(fieldArrayNode)
	
																' Null entry?
																If objArray.Size() = 0 Then
																	Continue
																End If

																	arrayType.SetArrayElement(arrayObj, n-1, DeSerializeObject("", objArray))
															End If

													End Select

												Next
											Else
												Throw "TODO..?"
											EndIf
										
									End Select
							Else

								' is this a reference?
								'Local ref:String = fieldNode.getAttribute("ref")
								If TJSONString(fieldNode) Then
									Local objRef:Object = objectMap.ValueForKey(TJSONString(fieldNode).Value())
									If objRef Then
										fieldObj.Set(obj, objRef)
									Else
										Throw "Reference not mapped yet : " + TJSONString(fieldNode).Value()
									End If
								Else
									fieldObj.Set(obj, DeSerializeObject("", TJSONArray(fieldNode), fieldType))
								End If
							End If

					End Select
					
				Next
				

			End If
		End If
		
		Return obj
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
		Throw TPersistJSONCollisionException.CreateException(ref, obj, cobj)
	End Method

	Function GetObjRef:String(obj:Object)
?ptr64
		Return Base36(Long(Byte Ptr(obj)))
?Not ptr64
		Return Base36(Int(Byte Ptr(obj)))
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

End Type

Type TPersistJSONRegistryEntry

	Field name:String
	Field id:TTypeId
	Field fields:TField[]
	Field refs:TList = New TList
	
End Type

Type TPersistJSONCollisionException Extends TPersistJSONException

	Field ref:String
	Field obj1:Object
	Field obj2:Object
	
	Function CreateException:TPersistJSONCollisionException(ref:String, obj1:Object, obj2:Object)
		Local e: TPersistJSONCollisionException = New TPersistJSONCollisionException
		e.ref = ref
		e.obj1 = obj1
		e.obj2 = obj2
		Return e
	End Function
	
	Method ToString:String()
		Return "Persist Collision. Matching ref '" + ref + "' for different objects"
	End Method

End Type

Type TPersistJSONException Extends TRuntimeException
End Type