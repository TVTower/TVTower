superstrict

'base for all resources from AssetManager (sprites, data, music..)
Type TAsset
	field _type:string="unknownType"
	field _object:object
	field _name:string = "unknown"
	field _loaded:int = 0
	field _url:object
	field _flags:int = 0

	Function CreateBaseAsset:TAsset(obj:object, objtype:string)
		local tmpobj:TAsset = new TAsset
		tmpobj._type = objtype
		tmpobj._object = obj
		tmpobj._loaded = 0
		return tmpobj
	End Function

	Method GetName:string()
		return self._name
	End Method

	Method SetName(name:string)
		self._name = name
	end Method

	Method GetUrl:object()
		return self._url
	End Method

	Method SetUrl(url:object)
		self._url = url
	end Method

	Method GetType:string()
		return self._type
	End Method

	Method SetType(name:string)
		self._type = name
	end Method

	Method GetLoaded:int()
		return self._loaded
	End Method

	Method SetLoaded(loaded:int)
		self._loaded = loaded
	end Method

End Type

