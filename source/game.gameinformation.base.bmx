SuperStrict

Import Brl.Map
Import "Dig/base.util.event.bmx"


Type TGameInformationCollection
	Field providers:TMap = CreateMap()
	?Threaded
	Field _dataMutex:TMutex = CreateMutex()
	?
	Global _instance:TGameInformationCollection


	Function GetInstance:TGameInformationCollection()
		if not _instance then _instance = new TGameInformationCollection
		return _instance
	End Function


	Method AddProvider(providerKey:string, provider:TGameInformationProvider)
		providers.Insert(providerKey, provider)
	End Method
	

	Method GetProvider:TGameInformationProvider(providerKey:string)
		Return TGameInformationProvider(providers.ValueForKey(providerKey.ToUpper()))
	End Method


	Method Get:object(providerKey:string, key:string, params:TData=null)
		if key="" and providerKey.Find(":") >= 0
			local p:string[] = providerKey.split(":")
			providerKey = p[0]
			key = p[1]
		endif
		local provider:TGameInformationProvider = GetProvider(providerKey)
		if provider then return provider.Get(key, params)
		return "UNKNOWN_INFORMATION"
	End Method


	Method ToString:String()
		local elementCount:int = 0
		For Local k:String = EachIn providers.Keys()
			elementCount :+ 1
		Next

		Return "TGameInformationCollection: " + elementCount + " information providers."
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetGameInformationCollection:TGameInformationCollection()
	Return TGameInformationCollection.GetInstance()
End Function

Function GetGameInformation:object(providerKey:string, key:string, params:TData=null)
	Return TGameInformationCollection.GetInstance().Get(providerKey, key, params)
End Function





'base class for all information providers
Type TGameInformationProvider
	Method Set(key:string, obj:object) abstract
	
	Method Get:object(key:string, params:object = null) abstract

	Method GetString:string(key:string, params:object = null)
		return string(Get(key, params))
	End Method
	
	Method GetFloat:Float(key:string, params:object = null)
		return float(string(Get(key, params)))
	End Method
	
	Method GetInt:Int(key:string, params:object = null)
		return int(string(Get(key, params)))
	End Method
	
	Method GetLong:Long(key:string, params:object = null)
		return Long(string(Get(key, params)))
	End Method
End Type
