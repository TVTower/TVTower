Rem
	====================================================================
	Data container
	====================================================================



	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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



Type TData
	field data:TMap = CreateMap()

	Method Init:TData(data:TMap=null)
		if data
			'convert all keys to lower case
			'attention: do not directly modify the data set (modification
			'while iteration might be bad)
			local modifyKeys:string[]
			For local k:string = EachIn data.Keys()
				if k <> k.toLower() then modifyKeys :+ [k]
			Next
			For local k:string = EachIn modifyKeys
				data.Insert(k.ToLower(), data.ValueForKey(k))
				data.Remove(k)
			Next
			
			self.data = data
		endif

		return self
	End Method


	Method ToString:String()
		return ToStringFormat(0)
	End Method


	Method ToStringFormat:String(depth:int = 0)
		local depthString:string = ""
		For local i:int = 0 until depth
			depthString :+ "|  "
		Next

		local res:string = "TData~n"
		For local key:String = eachin data.Keys()
			if TData(data.ValueForKey(key))
				res :+ depthString+"|- "+key+" = "+TData(data.ValueForKey(key)).ToStringFormat(depth + 1)
			else
				res :+ depthString+"|- "+key+" = " + string(data.ValueForKey(key)) + "~n"
			endif
		Next
		res :+ depthString + "'-------~n"
		return res
	End Method


	Method Copy:TData()
		local dataCopy:TData = new TData

		For local key:string = eachin data.Keys()
			key = key.ToLower()
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
		For local key:string = eachin dataSource.data.Keys()
			key = key.ToLower()
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
		For Local key:String = EachIn customized.data.Keys()
			'skip if original contains value too
			if original.Get(key) then continue

			result.Add(key, customized.Get(key))
		Next


		'add all data differing in "customized" compared to "original"
		'iterate through original to skip already "added ones"
		For Local key:String = EachIn original.data.Keys()
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


	Method Add:TData(key:string, data:object)
		self.data.insert(key.ToLower(), data)
		return self
	End Method


	Method AddString:TData(key:string, data:string)
		Add( key, object(data) )
		return self
	End Method


	Method AddNumber:TData(key:string, data:Double)
		Add( key, object( string(data) ) )
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


	Method Remove:object(key:string)
		local removed:object = Get(key)
		data.Remove(key)
		return removed
	End Method


	Method Get:object(key:string, defaultValue:object=null)
		'only react if the "::" is in the middle of something
		if key.Find("::") > 0
			local pos:int = key.Find("::")
			local group:string = Left(key,pos)
			local groupData:TData = TData(Get(group))
			if groupData
				return groupData.Get(Right(key, pos+1))
			endif
		endif
		local result:object = data.ValueForKey(key.ToLower())
		if result then return result
		return defaultValue
	End Method


	Method GetString:string(key:string, defaultValue:string=null)
		local result:object = Get(key)
		if result then return String( result )
		return defaultValue
	End Method


	Method GetBool:int(key:string, defaultValue:int=FALSE)
		local result:object = Get(key)
		if not result then return defaultValue
		Select String(result).toLower()
			case "1", "true", "yes"
				return True
			default
				return False
		End Select
		return False
	End Method


	Method GetDouble:Double(key:string, defaultValue:Double = 0.0)
		local result:object = Get(key)
		if result then return Double( String( result ) )
		return defaultValue
	End Method


	Method GetLong:Long(key:string, defaultValue:Long = 0)
		local result:object = Get(key)
		if result then return Long( String( result ) )
		return defaultValue
	End Method


	Method GetFloat:float(key:string, defaultValue:float = 0.0)
		local result:object = Get(key)
		if result then return float( String( result ) )
		return defaultValue
	End Method


	Method GetInt:int(key:string, defaultValue:int = null)
		local result:object = Get(key)
		if result then return Int( String( result ) )
		return defaultValue
	End Method


	Method GetData:TData(key:string, defaultValue:TData = null)
		return TData(Get(key, defaultValue))
	End Method
End Type