SuperStrict

Import Brl.Map
Import "Dig/base.util.event.bmx"


Type TGameInformationCollection
	Field providers:TMap = CreateMap()
	?Threaded
	Field _dataMutex:TMutex = CreateMutex() {nosave}
	?
	Global _instance:TGameInformationCollection


	Function GetInstance:TGameInformationCollection()
		if not _instance then _instance = new TGameInformationCollection
		return _instance
	End Function


	Method AddProvider(providerKey:string, provider:TGameInformationProvider)
		providers.Insert(providerKey.ToUpper(), provider)
	End Method


	Method GetProvider:TGameInformationProvider(providerKey:string)
		Return TGameInformationProvider(providers.ValueForKey(providerKey.ToUpper()))
	End Method


	Method Get:object(providerKey:string, key:string, params:TData=null)
		if key="" and providerKey.Find(":") >= 0
			local p:string[] = providerKey.split(":")
			providerKey = p[0]
			if p.length > 2
				key = p[1]
				for local i:int = 2 to p.length-1
					if not params then params = new TData
					params.Add("param"+(i-2 +1), p[i])
				Next
			elseif p.length > 1
				key = p[1]
			else
				return "UNKNOWN_INFORMATION"
			endif
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




Function ReplaceTextWithGameInformation:int(text:string, replacement:string var)
	local gameinformationResult:string = string(GetGameInformation(text, ""))

	'found something valid?
	if gameinformationResult <> "UNKNOWN_INFORMATION"
		replacement = gameinformationResult
		return True
	else
		return False
	endif
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
