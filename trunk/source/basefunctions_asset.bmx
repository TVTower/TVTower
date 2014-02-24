superstrict

'base for all resources from AssetManager (sprites, data, music..)
Type TAsset
	field _type:string="unknownType"
	field _object:object
	field _name:string = "unknown"
	field _loaded:int = 0
	field _url:object
	field _flags:int = 0


	Function CreateBaseAsset:TAsset(obj:object, objName:string, objType:string)
		local tmpobj:TAsset = new TAsset
		tmpobj.SetObject(obj)
		tmpobj.SetType(objType)
		tmpobj.SetName(objName)
		tmpobj._loaded = 0
		return tmpobj
	End Function


	Method SetObject(obj:object)
		_object = obj
	end Method


	Method GetName:string()
		return _name
	End Method


	Method SetName(value:string)
		_name = value.toLower()
	end Method


	Method GetUrl:object()
		return _url
	End Method


	Method SetUrl(url:object)
		_url = url
	end Method


	Method GetType:string()
		return _type
	End Method


	Method SetType(value:string)
		_type = value
	end Method


	Method GetLoaded:int()
		return _loaded
	End Method


	Method SetLoaded(bool:int)
		_loaded = bool
	end Method
End Type

