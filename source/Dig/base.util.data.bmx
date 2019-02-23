Rem
	====================================================================
	Data container
	====================================================================



	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2016 Ronny Otto, digidea.de

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
'Import BaH.StringBuffer
Import "external/stringbuffer.mod/stringbuffer.bmx"
Import "external/string_comp.bmx"

Type TData
	field data:TMap = New TMap

	Method Init:TData(data:TMap=null)
		if data
			self.data.Clear()

			For local k:object = EachIn data.Keys()
				local ls:TLowerString = TLowerString(k)
				If Not ls Then
					ls = TLowerString.Create(String(k))
				End If

				self.data.Insert(ls, data.ValueForKey(k))
			Next
		endif

		return self
	End Method


	Method Clear:int()
		if data then data.Clear()
		return true
	End Method


	Method ToString:String()
		return ToStringFormat(0)
	End Method


	Method ToStringFormat:String(depth:int = 0)
		local depthString:TStringBuffer = new TStringBuffer
		'local depthString:string = ""
		For local i:int = 0 until depth
			depthString.Append("|  ")
		Next

		local res:TStringBuffer = new TStringBuffer
		res.Append("TData~n")
		'local res:string = "TData~n"
		For local key:TLowerString = eachin data.Keys()
			if TData(data.ValueForKey(key))
				res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(TData(data.ValueForKey(key)).ToStringFormat(depth + 1)).Append("~n")
			elseif TData[](data.ValueForKey(key))
				for local d:TData = EachIn TData[](data.ValueForKey(key))
					res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(d.ToStringFormat(depth + 1)).Append("~n")
				next
			elseif object[](data.ValueForKey(key))
				for local o:object = EachIn object[](data.ValueForKey(key))
					res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(o.ToString()).Append("~n")
				next
			elseif data.ValueForKey(key)
				res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = ").Append(data.ValueForKey(key).ToString()).Append("~n")
			else
				res.AppendObject(depthString).Append("|- ").Append(key.orig).Append(" = NULL~n")
			endif
		Next
		res.AppendObject(depthString).Append("'-------~n")
		return res.ToString()
	End Method


	Method Copy:TData()
		local dataCopy:TData = new TData

		For local key:TLowerString = eachin data.Keys()
			'key = key.ToLower()
			local value:object = data.ValueForKey(key)
			if TData(value)
				dataCopy.Add(key, TData(value).Copy())
			else
				dataCopy.Add(key, value)
			endif
		Next

		return dataCopy
	End Method


	Function JoinData:int(dataSource:TData, dataTarget:TData)
		if not dataSource then return False
		if not dataTarget then return False
		For local key:TLowerString = eachin dataSource.data.Keys()
			'key = key.ToLower()
			dataTarget.Add(key, dataSource.data.ValueForKey(key))
		Next
		return True
	End Function


	'merge multiple TData with the current data object
	Method AppendDataSets:int(dataSets:TData[])
		For local set:TData = Eachin dataSets
			JoinData(set, self)
		Next
		return True
	End Method


	'add keys->values from other data object (and overwrite own if also existing)
	Method Append:TData(otherData:TData)
		JoinData(otherData, self)
		return Self
	End Method


	'appends own key->value pairs to given dataset
	Method AppendTo:TData(otherData:TData var)
		JoinData(self, otherData)
		return Self
	End Method


	'returns a data set containing only differing data
	'1) original contains key->value, customized does not contain key->value
	'   -> SKIP key->value
	'2) original contains key->value, customized contains key->value2
	'   -> add key->value2
	'3) original contains key->value, customized contains same key->value
	'   -> SKIP key->value and key->value2
	Function GetDataDifference:TData(original:TData, customized:TData)
		Local result:TData = new TData
		if not original then original = new TData
		if not customized then customized = new TData

		'add all data available in "customized" but not in "original"
		For Local key:TLowerString = EachIn customized.data.Keys()
			'skip if original contains value too
			if original.Get(key) then continue

			result.Add(key, customized.Get(key))
		Next


		'add all data differing in "customized" compared to "original"
		'iterate through original to skip already "added ones"
		For Local key:TLowerString = EachIn original.data.Keys()
			local newValue:object = customized.Get(key)
			'if customized does not contain that value yet - skip
			if not newValue then continue

			'both contain a value for the given key
			'only add the key->value if original and custom differ
			if newValue <> original.Get(key)
				if string(newValue) = string(original.Get(key)) then continue

				'if it is another dataset, try to get their
				'difference too
				if TData(newValue)
					newValue = GetDataDifference(TData(original.Get(key)), TData(newValue))
				endif

				result.Add(key, newValue)
			endif
		Next

		Return result
	End Function


	Method GetDifferenceTo:TData(otherData:TData)
		return GetDataDifference(otherData, self)
	End Method


	Method Add:TData(key:Object, data:object)
		local ls:TLowerString = TLowerString(key)
		If Not ls Then
			ls = TLowerString.Create(String(key))
		End If
		self.data.insert(ls, data)
		return self
	End Method


	Method AddString:TData(key:Object, data:string)
		Add( key, data )
		return self
	End Method


	Method AddNumber:TData(key:Object, data:Double)
		Local dd:TDoubleData = new TDoubleData
		dd.value = data
		Add( key, dd )
		return self
	End Method


	Method AddBoolString:TData(key:string, data:string)
		Select data.toLower()
			case "1", "true", "yes"
				Add( key, "TRUE")
			default
				Add( key, "FALSE")
		End Select
		return self
	End Method


	Method AddBool:TData(key:string, bool:int)
		if bool
			Add( key, "TRUE")
		else
			Add( key, "FALSE")
		endif
		return self
	End Method


	Method Remove:object(key:object)
		local removed:object = Get(key)
		data.Remove(key)
		return removed
	End Method


	Method Has:int(key:Object)
		Local ls:TLowerString = TLowerString(key)
		if not ls then
			ls = TLowerString.Create(String(key))
		end if
		return data.Contains(ls)
	End Method


	Method Get:object(k:Object, defaultValue:object=null)
		'only react if the "::" is in the middle of something

		Local ls:TLowerString = TLowerString(k)
		if ls then
			local key:TLowerString = ls
			local pos:int = key.Find("::")

			if pos > 0
				local group:string = Left(key.orig,pos)
				local groupData:TData = TData(Get(group))
				if groupData
					return groupData.Get(Right(key.orig, pos+1), defaultValue)
				endif
			endif
		Else
			Local key:String = String(k)
			local pos:int = key.Find("::")

			if pos > 0
				local group:string = Left(key,pos)
				local groupData:TData = TData(Get(group))
				if groupData
					return groupData.Get(Right(key, pos+1), defaultValue)
				endif
			endif
		End if
		if String(k) then
			k = TLowerString.Create(String(k))
		end if
		local result:object = data.ValueForKey(k)
		if result then
			return result
		end if
		return defaultValue
	End Method


	Method GetString:string(key:object, defaultValue:string=null)
		local result:object = Get(key)
		if result then
			return result.ToString()
		End If
		return defaultValue
	End Method


	Method GetBool:int(key:object, defaultValue:int=FALSE)
		local result:object = Get(key)
		if not result then return defaultValue
		Select String(result).toLower()
			case "true", "yes"
				return True
			default
				'also allow "1" / "1.00000" or "33"
				if int(string(result)) >= 1 then return True
				return False
		End Select
		return False
	End Method


	Method GetDouble:Double(key:object, defaultValue:Double = 0.0)
		local result:object = Get(key)
		if result then
			local dd:TDoubleData = TDoubleData(result)
			if dd Then
				Return dd.value
			End if
			return Double( String( result ) )
		End If
		return defaultValue
	End Method


	Method GetLong:Long(key:object, defaultValue:Long = 0)
		local result:object = Get(key)
		if result then
			Local dd:TDoubleData = TDoubleData(result)
			if dd then
				return Long(dd.value)
			end if
			return Long( String( result ) )
		end if
		return defaultValue
	End Method


	Method GetFloat:float(key:object, defaultValue:float = 0.0)
		local result:object = Get(key)
		if result then
			local dd:TDoubleData = TDoubleData(result)
			if dd then
				return Float(dd.value)
			end if
			return float( String( result ) )
		End If
		return defaultValue
	End Method


	Method GetInt:int(key:object, defaultValue:int = null)
		local result:object = Get(key)
		if result then
			Local dd:TDoubleData = TDoubleData(result)
			if dd Then
				return Int(dd.value)
			End If
			return Int( String( result ) )
		end if
		return defaultValue
	End Method


	Method GetData:TData(key:string, defaultValue:TData = null)
		return TData(Get(key, defaultValue))
	End Method
End Type


Type TDoubleData
	Field value:Double

	Method ToString:String()
		return String(value)
	End Method


	Method SerializeTDoubleDataToString:string()
		'fits into a long? skip the ".0000" values
		if double(long(value)) = value then return string(long(value))
		return string(value)
	End Method


	Method DeSerializeTDoubleDataFromString(text:String)
		value = double(text)
	End Method
End Type

