SuperStrict
Import brl.Map


Type TData
	field data:TMap = CreateMap()

	Method Init:TData(data:TMap=null)
		if data then self.data = data

		return self
	End Method


	Method ToString:String()
		local res:string = "TData content [~n"
		For local key:String = eachin data.Keys()
			res :+ key+" = " + string(data.ValueForKey(key)) + "~n"
		Next
		res :+ "]~n"
		return res
	End Method


	'add keys->values from other data object (and overwrite own if also existing)
	Method Merge:int(otherData:TData)
		if not otherData then return FALSE

		For local key:string = eachin otherData.data.Keys()
			key = key.ToLower()
			Add(key, otherData.data.ValueForKey(key))
		Next
		return TRUE
	End Method


	Method Add:TData(key:string, data:object)
		self.data.insert(key.ToLower(), data)
		return self
	End Method


	Method AddString:TData(key:string, data:string)
		Add( key, object(data) )
		return self
	End Method


	Method AddNumber:TData(key:string, data:float)
		Add( key, object( string(data) ) )
		return self
	End Method


	Method Get:object(key:string, defaultValue:object=null)
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


	Method GetFloat:float(key:string, defaultValue:float = 0.0)
		local result:object = Get(key)
		if result then return float( String( result ) )
		return defaultValue
	End Method


	Method GetInt:int(key:string, defaultValue:int = null)
		local result:object = Get(key)
		if result then return Int( float( String( result ) ) )
		return defaultValue
	End Method
End Type