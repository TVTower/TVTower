Rem
	====================================================================
	Data container
	====================================================================



	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2022 Ronny Otto, digidea.de

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
Import brl.Map
Import brl.Retro
Import brl.StringBuilder
Import "external/string_comp.bmx"

Type TData
	Field data:TMap

	Method Init:TData(data:TMap=Null)
		If data
			If Not self.data
				self.data = new TMap
			Else
				Self.data.Clear()
			EndIf

			For Local k:Object = EachIn data.Keys()
				Local ls:TLowerString = TLowerString(k)
				If Not ls Then
					ls = TLowerString.Create(String(k))
				End If

				Self.data.Insert(ls, data.ValueForKey(k))
			Next
		EndIf

		Return Self
	End Method


	Method Clear:Int()
		If data Then data.Clear()
		Return True
	End Method


	Method ToString:String()
		Return ToStringFormat(0)
	End Method


	Method ToStringFormat:String(depth:Int = 0)
		Local depthString:TStringBuilder = New TStringBuilder
		'local depthString:string = ""
		For Local i:Int = 0 Until depth
			depthString.Append("|  ")
		Next

		Local res:TStringBuilder = New TStringBuilder
		res.Append("TData~n")
		'local res:string = "TData~n"
		If self.data
			For Local key:TLowerString = EachIn data.Keys()
				If TData(data.ValueForKey(key))
					res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(TData(data.ValueForKey(key)).ToStringFormat(depth + 1)).Append("~n")
				ElseIf TData[](data.ValueForKey(key))
					For Local d:TData = EachIn TData[](data.ValueForKey(key))
						res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(d.ToStringFormat(depth + 1)).Append("~n")
					Next
				ElseIf Object[](data.ValueForKey(key))
					For Local o:Object = EachIn Object[](data.ValueForKey(key))
						res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(o.ToString()).Append("~n")
					Next
				ElseIf data.ValueForKey(key)
					res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(data.ValueForKey(key).ToString()).Append("~n")
				Else
					res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = NULL~n")
				EndIf
			Next
		EndIf
		res.AppendObject(depthString).Append("'-------~n")
		Return res.ToString()
	End Method


	Method Copy:TData()
		Local dataCopy:TData = New TData

		If self.data
			For Local key:TLowerString = EachIn data.Keys()
				'key = key.ToLower()
				Local value:Object = data.ValueForKey(key)
				If TData(value)
					dataCopy.Add(key, TData(value).Copy())
				Else
					dataCopy.Add(key, value)
				EndIf
			Next
		EndIf

		Return dataCopy
	End Method


	Function JoinData:Int(dataSource:TData, dataTarget:TData)
		If Not dataSource Then Return False
		If Not dataTarget Then Return False
		If dataSource.data
			For Local key:TLowerString = EachIn dataSource.data.Keys()
				'key = key.ToLower()
				dataTarget.Add(key, dataSource.data.ValueForKey(key))
			Next
		EndIf
		Return True
	End Function


	'merge multiple TData with the current data object
	Method AppendDataSets:Int(dataSets:TData[])
		For Local set:TData = EachIn dataSets
			JoinData(set, Self)
		Next
		Return True
	End Method


	'add keys->values from other data object (and overwrite own if also existing)
	Method Append:TData(otherData:TData)
		JoinData(otherData, Self)
		Return Self
	End Method


	'appends own key->value pairs to given dataset
	Method AppendTo:TData(otherData:TData Var)
		JoinData(Self, otherData)
		Return Self
	End Method


	'returns a data set containing only differing data
	'1) original contains key->value, customized does not contain key->value
	'   -> SKIP key->value
	'2) original contains key->value, customized contains key->value2
	'   -> add key->value2
	'3) original contains key->value, customized contains same key->value
	'   -> SKIP key->value and key->value2
	Function GetDataDifference:TData(original:TData, customized:TData)
		Local result:TData = New TData
		If Not original Then original = New TData
		If Not customized Then customized = New TData

		'add all data available in "customized" but not in "original"
		If customized.data
			For Local key:TLowerString = EachIn customized.data.Keys()
				'skip if original contains value too
				If original.Get(key) Then Continue

				result.Add(key, customized.Get(key))
			Next
		EndIf


		'add all data differing in "customized" compared to "original"
		'iterate through original to skip already "added ones"
		if original.data
			For Local key:TLowerString = EachIn original.data.Keys()
				Local newValue:Object = customized.Get(key)
				'if customized does not contain that value yet - skip
				If Not newValue Then Continue

				'both contain a value for the given key
				'only add the key->value if original and custom differ
				If newValue <> original.Get(key)
					If String(newValue) = String(original.Get(key)) Then Continue

					'if it is another dataset, try to get their
					'difference too
					If TData(newValue)
						newValue = GetDataDifference(TData(original.Get(key)), TData(newValue))
					EndIf

					result.Add(key, newValue)
				EndIf
			Next
		EndIf

		Return result
	End Function


	Method GetDifferenceTo:TData(otherData:TData)
		Return GetDataDifference(otherData, Self)
	End Method


	Method Add:TData(key:Object, value:Object)
		If Not key Then Return self
		
		If Not self.data Then self.data = New TMap
		If TLowerString(key)
			self.data.insert(key, value)
		Else
			self.data.insert(TLowerString.Create(String(key)), value)
		EndIf
		
		Return self
	End Method


	Method Add:TData(key:String, value:Object)
		If Not key Then Return self
		
		If Not self.data Then self.data = New TMap
		self.data.insert(TLowerString.Create(key), value)
		
		Return self
	End Method


	Method Add:TData(key:TLowerString, value:Object)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(key, value)

		Return self
	End Method


	Method Add:TData(key:String, value:Double)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(TLowerString.Create(key), New TDoubleData(value))

		Return self
	End Method


	Method Add:TData(key:TLowerString, value:Double)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(key, New TDoubleData(value))

		Return self
	End Method


	Method Add:TData(key:String, value:Long)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(TLowerString.Create(key), New TLongData(value))

		Return self
	End Method


	Method Add:TData(key:TLowerString, value:Long)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(key, New TLongData(value))

		Return self
	End Method


	Method Add:TData(key:String, value:String)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(TLowerString.Create(key), value)

		Return self
	End Method


	Method Add:TData(key:TLowerString, value:String)
		If Not key Then Return self

		If Not self.data Then self.data = New TMap
		self.data.insert(key, value)

		Return self
	End Method


	Method AddBool:TData(key:String, value:String)
		If Not key Then Return self

		Select value.ToLower()
			Case "true", "yes", "1"
				value = "true"
			Default
				value = "false"
		End Select

		If Not self.data Then self.data = New TMap
		self.data.insert(TLowerString.Create(key), value)
		
		Return Self
	End Method


	Method AddBool:TData(key:TLowerString, value:String)
		If Not key Then Return self

		Select value.ToLower()
			Case "true", "yes", "1"
				value = "true"
			Default
				value = "false"
		End Select

		If Not self.data Then self.data = New TMap
		self.data.insert(key, value)
		
		Return Self
	End Method


	Method AddBool:TData(key:String, value:Int)
		If Not key Then Return self
		
		If Not self.data Then self.data = New TMap
		If value 
			self.data.insert(TLowerString.Create(key), "true")
		Else
			self.data.insert(TLowerString.Create(key), "false")
		EndIf

		Return Self
	End Method


	Method AddBool:TData(key:TLowerString, value:Int)
		If Not key Then Return self
		If Not key Then Return self
		
		If Not self.data Then self.data = New TMap
		If value 
			self.data.insert(key, "true")
		Else
			self.data.insert(key, "false")
		EndIf
		
		Return Self
	End Method


	Method Remove:Object(key:String)
		if not self.data Then Return Null
		If Not key Then Return Null

		Local ls:TLowerString = TLowerString.Create(key)
		Local removed:Object = Get(ls)
		data.Remove(ls)

		Return removed
	End Method


	Method Remove:Object(key:TLowerString)
		if not self.data Then Return Null
		If Not key Then Return Null

		Local removed:Object = Get(key)
		data.Remove(key)

		Return removed
	End Method


	Method Has:Int(key:String)
		If Not self.data Then Return False
		If Not key Then Return False

		Return data.Contains(TLowerString.Create(key))
	End Method


	Method Has:Int(key:TLowerString)
		If Not self.data Then Return False
		If Not key Then Return False

		Return data.Contains(key)
	End Method


	Method Get:Object(key:String, defaultValue:Object=Null)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)
		If result Then Return Result

		If defaultValue And Not self.data.Contains(ls)
			Return defaultValue
		EndIf
		
		Return Null
	End Method


	Method Get:Object(key:TLowerString, defaultValue:Object=Null)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)
		If result Then Return Result

		If defaultValue And Not self.data.Contains(key)
			Return defaultValue
		EndIf
		
		Return Null
	End Method


	Method GetString:String(key:String, defaultValue:String=Null)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)
		If result Then Return result.ToString()
		
		'check if the entry is just "empty" (skip lookup is defaultValue is also Null)
		If defaultValue And Not self.data.Contains(ls) 
			Return defaultValue
		EndIf
		
		Return ""
	End Method


	Method GetString:String(key:TLowerString, defaultValue:String=Null)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)
		If result Then Return result.ToString()
		
		'check if the entry is just "empty" (skip lookup is defaultValue is also Null)
		If defaultValue And Not self.data.Contains(key) 
			Return defaultValue
		EndIf
		
		Return ""
	End Method


	Method GetBool:Int(key:String, defaultValue:Int=False)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)
		'empty = default
		If Not result Then Return defaultValue
		
		Local s:String = String(result)
		'string interpretation
		If s
			s = s.ToLower()
			Select s
				Case "true", "yes"
					Return True
				Default
					'also allow "1" / "1.00000" or "33"
					If Int(s) >= 1 Then Return True
					Return False
			End Select
		'number interpretation
		ElseIf TDoubleData(result) and Int(TDoubleData(result).value) >= 1
			Return True
		'number interpretation
		ElseIf TLongData(result) and TLongData(result).value >= 1
			Return True
		EndIf
		
		Return False
	End Method


	Method GetBool:Int(key:TLowerString, defaultValue:Int=False)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)
		'empty = default
		If Not result Then Return defaultValue
		
		Local s:String = String(result)
		'string interpretation
		If s
			s = s.ToLower()
			Select s
				Case "true", "yes"
					Return True
				Default
					'also allow "1" / "1.00000" or "33"
					If Int(s) >= 1 Then Return True
					Return False
			End Select
		'number interpretation
		ElseIf TDoubleData(result) and Int(TDoubleData(result).value) >= 1
			Return True
		'number interpretation
		ElseIf TLongData(result) and TLongData(result).value >= 1
			Return True
		EndIf
		
		Return False
	End Method


	Method GetDouble:Double(key:String, defaultValue:Double = 0.0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)

		If result
			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return dd.value

			Local ld:TLongData = TLongData(result)
			If ld Then Return Double(ld.value)

			'TODO: replace with s.ToDoubleEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Double(String(result))
		End If
		Return defaultValue
	End Method


	Method GetDouble:Double(key:TLowerString, defaultValue:Double = 0.0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)

		If result
			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return dd.value

			Local ld:TLongData = TLongData(result)
			If ld Then Return Double(ld.value)

			'TODO: replace with s.ToDoubleEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Double(String(result))
		End If
		Return defaultValue
	End Method


	Method GetLong:Long(key:String, defaultValue:Double = 0.0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)

		If result
			Local ld:TLongData = TLongData(result)
			If ld Then Return ld.value

			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return Long(dd.value)

			'TODO: replace with s.ToLongEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Long(String(result))
		End If
		Return defaultValue
	End Method
	

	Method GetLong:Long(key:TLowerString, defaultValue:Double = 0.0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)

		If result
			Local ld:TLongData = TLongData(result)
			If ld Then Return ld.value

			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return Long(dd.value)

			'TODO: replace with s.ToLongEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Long(String(result))
		End If
		Return defaultValue
	End Method


	Method GetFloat:Float(key:String, defaultValue:Float = 0.0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)

		If result
			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return Float(dd.value)

			Local ld:TLongData = TLongData(result)
			If ld Then Return Float(ld.value)

			'TODO: replace with s.ToFloatEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Float(String(result))
		End If
		Return defaultValue
	End Method


	Method GetFloat:Float(key:TLowerString, defaultValue:Float = 0.0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)

		If result
			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return Float(dd.value)

			Local ld:TLongData = TLongData(result)
			If ld Then Return Float(ld.value)

			'TODO: replace with s.ToFloatEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Float(String(result))
		End If
		Return defaultValue
	End Method


	Method GetInt:Int(key:String, defaultValue:Int = 0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:Object = self.data.ValueForKey(ls)

		If result
			Local ld:TLongData = TLongData(result)
			If ld Then Return Int(ld.value)

			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return Int(dd.value)

			'TODO: replace with s.ToIntEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Int(String(result))
		End If
		Return defaultValue
	End Method
	

	Method GetInt:Int(key:TLowerString, defaultValue:Int = 0)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:Object = self.data.ValueForKey(key)

		If result
			Local ld:TLongData = TLongData(result)
			If ld Then Return Int(ld.value)

			Local dd:TDoubleData = TDoubleData(result)
			If dd Then Return Int(dd.value)

			'TODO: replace with s.ToIntEx() (added to brl.mod 12/2024)
			'this does NOT convert "" to 0 (as we check "If result" before)
			Return Int(String(result))
		End If
		Return defaultValue
	End Method


	Method GetData:TData(key:String, defaultValue:TData=Null)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local ls:TLowerString = TLowerString.Create(key)
		Local result:TData = TData(self.data.ValueForKey(ls))
		If result Then Return Result

		Return defaultValue 'Null or some passed data
	End Method


	Method GetData:TData(key:TLowerString, defaultValue:TData=Null)
		If Not self.data Then Return Null
		If Not key Then Return defaultValue

		Local result:TData = TData(self.data.ValueForKey(key))
		If result Then Return Result

		Return defaultValue 'Null or some passed data
	End Method
End Type




'TData with case sensitive Keys
Type TDataCSK
	Field data:TStringMap

	Method Init:TDataCSK(data:Object)
		If TMap(data)
			Local map:TMap = TMap(data)
			If Not self.data
				self.data = new TStringMap
			Else
				Self.data.Clear()
			EndIf

			For Local k:Object = EachIn map.Keys()
				Self.data.Insert(String(k).ToLower(), map.ValueForKey(k))
			Next
		ElseIf TStringMap(data)
			Local map:TStringMap = TStringMap(data)
			If Not self.data
				self.data = new TStringMap
			Else
				Self.data.Clear()
			EndIf

			For Local k:String = EachIn map.Keys()
				Self.data.Insert(k.ToLower(), map.ValueForKey(k))
			Next
		EndIf

		Return Self
	End Method


	Method Clear:Int()
		If data Then data.Clear()
		Return True
	End Method


	Method ToString:String()
		Return ToStringFormat(0)
	End Method


	Method ToStringFormat:String(depth:Int = 0)
		Local depthString:TStringBuilder = New TStringBuilder
		'local depthString:string = ""
		For Local i:Int = 0 Until depth
			depthString.Append("|  ")
		Next

		Local res:TStringBuilder = New TStringBuilder
		res.Append("TData~n")
		'local res:string = "TData~n"
		If self.data
			For Local key:String = EachIn data.Keys()
				If TDataCSK(data.ValueForKey(key))
					res.AppendObject(depthString).Append("|- ").Append(key).Append(" = ").Append(TDataCSK(data.ValueForKey(key)).ToStringFormat(depth + 1)).Append("~n")
				ElseIf TData(data.ValueForKey(key))
					res.AppendObject(depthString).Append("|- ").Append(key).Append(" = ").Append(TData(data.ValueForKey(key)).ToStringFormat(depth + 1)).Append("~n")
				ElseIf TDataCSK[](data.ValueForKey(key))
					For Local d:TDataCSK = EachIn TDataCSK[](data.ValueForKey(key))
						res.AppendObject(depthString).Append("|- ").Append(key).Append(" = ").Append(d.ToStringFormat(depth + 1)).Append("~n")
					Next
				ElseIf TData[](data.ValueForKey(key))
					For Local d:TData = EachIn TData[](data.ValueForKey(key))
						res.AppendObject(depthString).Append("|- ").Append(key).Append(" = ").Append(d.ToStringFormat(depth + 1)).Append("~n")
					Next
				ElseIf Object[](data.ValueForKey(key))
					For Local o:Object = EachIn Object[](data.ValueForKey(key))
						res.AppendObject(depthString).Append("|- ").Append(key).Append(" = ").Append(o.ToString()).Append("~n")
					Next
				ElseIf data.ValueForKey(key)
					res.AppendObject(depthString).Append("|- ").Append(key).Append(" = ").Append(data.ValueForKey(key).ToString()).Append("~n")
				Else
					res.AppendObject(depthString).Append("|- ").Append(key).Append(" = NULL~n")
				EndIf
			Next
		EndIf
		res.AppendObject(depthString).Append("'-------~n")
		Return res.ToString()
	End Method


	Method Copy:TDataCSK()
		Local dataCopy:TDataCSK = New TDataCSK

		If self.data
			For Local key:String = EachIn data.Keys()
				'key = key.ToLower()
				Local value:Object = data.ValueForKey(key)
				If TDataCSK(value)
					dataCopy.Add(key, TDataCSK(value).Copy())
				ElseIf TData(value)
					dataCopy.Add(key, TData(value).Copy())
				Else
					dataCopy.Add(key, value)
				EndIf
			Next
		EndIf

		Return dataCopy
	End Method


	Function JoinData:Int(dataSource:TDataCSK, dataTarget:TDataCSK)
		If Not dataSource Then Return False
		If Not dataTarget Then Return False
		If dataSource.data
			For Local key:String = EachIn dataSource.data.Keys()
				dataTarget.Add(key, dataSource.data.ValueForKey(key))
			Next
		EndIf
		Return True
	End Function


	'merge multiple TData with the current data object
	Method AppendDataSets:Int(dataSets:TDataCSK[])
		For Local set:TDataCSK = EachIn dataSets
			JoinData(set, Self)
		Next
		Return True
	End Method


	'add keys->values from other data object (and overwrite own if also existing)
	Method Append:TDataCSK(otherData:TDataCSK)
		JoinData(otherData, Self)
		Return Self
	End Method


	'appends own key->value pairs to given dataset
	Method AppendTo:TDataCSK(otherData:TDataCSK)
		JoinData(Self, otherData)
		Return Self
	End Method


	'returns a data set containing only differing data
	'1) original contains key->value, customized does not contain key->value
	'   -> SKIP key->value
	'2) original contains key->value, customized contains key->value2
	'   -> add key->value2
	'3) original contains key->value, customized contains same key->value
	'   -> SKIP key->value and key->value2
	Function GetDataDifference:TDataCSK(original:TDataCSK, customized:TDataCSK)
		Local result:TDataCSK = New TDataCSK
		If Not original Then original = New TDataCSK
		If Not customized Then customized = New TDataCSK

		'add all data available in "customized" but not in "original"
		If customized.data
			For Local key:String = EachIn customized.data.Keys()
				'skip if original contains value too
				If original.Get(key) Then Continue

				result.Add(key, customized.Get(key))
			Next
		EndIf


		'add all data differing in "customized" compared to "original"
		'iterate through original to skip already "added ones"
		if original.data
			For Local key:String = EachIn original.data.Keys()
				Local newValue:Object = customized.Get(key)
				'if customized does not contain that value yet - skip
				If Not newValue Then Continue

				'both contain a value for the given key
				'only add the key->value if original and custom differ
				If newValue <> original.Get(key)
					If String(newValue) = String(original.Get(key)) Then Continue

					'if it is another dataset, try to get their
					'difference too
					If TDataCSK(newValue)
						newValue = GetDataDifference(TDataCSK(original.Get(key)), TDataCSK(newValue))
					EndIf

					result.Add(key, newValue)
				EndIf
			Next
		EndIf

		Return result
	End Function


	Method GetDifferenceTo:TDataCSK(otherData:TDataCSK)
		Return GetDataDifference(otherData, Self)
	End Method


	Method Add:TDataCSK(key:String, data:Object)
		if not self.data then self.data = new TStringMap
		Self.data.insert(key, data)
		Return Self
	End Method


	Method AddNumber:TDataCSK(key:String, data:Double)
		Local dd:TDoubleData = New TDoubleData
		dd.value = data
		Add(key, dd)
		Return Self
	End Method


	Method AddString:TDataCSK(key:String, data:String)
		Add(key, data)
		Return Self
	End Method


	Method AddFloat:TDataCSK(key:String, data:Float)
		Return AddDouble(key, data)
	End Method


	Method AddDouble:TDataCSK(key:String, data:Double)
		Local dd:TDoubleData = New TDoubleData
		dd.value = data
		Add(key, dd)
		Return Self
	End Method


	Method AddInt:TDataCSK(key:String, data:int)
		Return AddLong(key, data)
	End Method


	Method AddLong:TDataCSK(key:String, data:Long)
		Local ld:TLongData = New TLongData
		ld.value = data
		Add(key, ld)
		Return Self
	End Method


	Method AddBoolString:TDataCSK(key:String, data:String)
		Select data.toLower()
			Case "1", "true", "yes"
				Add(key, "TRUE")
			Default
				Add(key, "FALSE")
		End Select
		Return Self
	End Method


	Method AddBool:TDataCSK(key:String, bool:Int)
		If bool
			Add(key, "TRUE")
		Else
			Add(key, "FALSE")
		EndIf
		Return Self
	End Method


	Method Remove:Object(key:String)
		if not self.data Then Return Null

		Local removed:Object = Get(key)
		data.Remove(key)

		Return removed
	End Method


	Method Has:Int(key:String)
		if not self.data Then Return False

		Return data.Contains(key)
	End Method


	Method Get:Object(key:String, defaultValue:Object = Null, groupsEnabled:Int = False)
		if not self.data Then Return Null

		'only react if the "::" is in the middle of something
		If groupsEnabled
			Local pos:Int = key.Find("::")
			If pos > 0
				Local group:String = Left(key, pos)
				Local groupData:Object = Get(group)
				If groupData
					If TDataCSK(groupData)
						Return TDataCSK(groupData).Get(Right(key, pos+1), defaultValue)
					ElseIf TData(groupData)
						Return TData(groupData).Get(Right(key, pos+1), defaultValue)
					EndIf
				EndIf
			EndIf
		EndIf

		Local result:Object = data.ValueForKey(key)
		If result Then	Return result

		Return defaultValue
	End Method


	Method GetString:String(key:String, defaultValue:String = Null)
		Local result:Object = Get(key)
		If result Then Return result.ToString()

		Return defaultValue
	End Method


	Method GetBool:Int(key:String, defaultValue:Int = False)
		Local result:Object = Get(key)
		If Not result Then Return defaultValue

		Select String(result).toLower()
			Case "true", "yes"
				Return True
			Default
				'also allow "1" / "1.00000" or "33"
				If Int(String(result)) >= 1 Then Return True
		End Select

		Return False
	End Method


	Method GetDouble:Double(key:String, defaultValue:Double = 0.0)
		Local result:Object = Get(key)
		If result
			Local dd:TDoubleData = TDoubleData(result)
			If dd
				Return dd.value
			Else
				Local ld:TLongData = TLongData(result)
				If ld
					Return ld.value
				EndIf
			End If
			Return Double( String( result ) )
		End If
		Return defaultValue
	End Method


	Method GetLong:Long(key:String, defaultValue:Long = 0)
		Local result:Object = Get(key)
		If result
			Local ld:TLongData = TLongData(result)
			If ld
				Return ld.value
			Else
				Local dd:TDoubleData = TDoubleData(result)
				If dd
					Return Long(dd.value)
				EndIf
			End If
			Return Long( String( result ) )
		End If
		Return defaultValue
	End Method


	Method GetFloat:Float(key:String, defaultValue:Float = 0.0)
		Local result:Object = Get(key)
		If result
			Local dd:TDoubleData = TDoubleData(result)
			If dd
				Return Float(dd.value)
			Else
				Local ld:TLongData = TLongData(result)
				If ld
					Return ld.value
				EndIf
			End If
			Return Float( String( result ) )
		End If
		Return defaultValue
	End Method


	Method GetInt:Int(key:String, defaultValue:Int = Null)
		Local result:Object = Get(key)
		If result
			Local ld:TLongData = TLongData(result)
			If ld
				Return Int(ld.value)
			Else
				Local dd:TDoubleData = TDoubleData(result)
				If dd
					Return Int(dd.value)
				End If
			EndIf
			Return Int( String( result ) )
		End If
		Return defaultValue
	End Method


	Method GetDataCSK:TDataCSK(key:String, defaultValue:TDataCSK = Null)
		Return TDataCSK(Get(key, defaultValue))
	End Method


	Method GetData:TData(key:String, defaultValue:TData = Null)
		Return TData(Get(key, defaultValue))
	End Method
End Type




Type TDoubleData
	Field value:Double
	
	Method New(value:Double)
		self.value = value
	End Method


	Method ToString:String()
		Return String(value)
	End Method


	Method SerializeTDoubleDataToString:String()
		'fits into a long? skip the ".0000" values
		If Double(Long(value)) = value Then Return String(Long(value))
		Return String(value)
	End Method


	Method DeSerializeTDoubleDataFromString(text:String)
		value = Double(text)
	End Method
End Type



Type TLongData
	Field value:Long

	Method New(value:Long)
		self.value = value
	End Method


	Method ToString:String()
		Return String(value)
	End Method


	Method SerializeTLongDataToString:String()
		Return String(value)
	End Method


	Method DeSerializeTLongDataFromString(text:String)
		value = Long(text)
	End Method
End Type

