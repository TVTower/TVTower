' resource manager

Import BRL.Max2D
Import BRL.Random
Import brl.reflection
?Threaded
Import brl.Threads
?
Import "basefunctions_xml.bmx"
Import "basefunctions_image.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_asset.bmx"

Global Assets:TAssetManager = TAssetManager.Create(null,1)

Type TAssetManager
	global content:TMap = CreateMap()
	Field checkExistence:Int

	global AssetsToLoad:TMap = CreateMap()
'	global AssetsLoaded:TMap = CreateMap()
	?Threaded
	global AssetsLoadedLock:TMutex = CreateMutex()
	global AssetsToLoadLock:TMutex = CreateMutex()
	global AssetsLoadThread:TThread
	?
	'threadable function that loads objects
	Function LoadAssetsInThread:Object(Input:Object)
		For Local key:string = EachIn TAssetManager.AssetsToLoad.keys()
			local obj:TAsset			= TAsset(TAssetManager.AssetsToLoad.ValueForKey(key))
			local loadedObject:TAsset	= null

			print "LoadAssetsInThread: "+obj.GetName() + " ["+obj.getType()+"]"

			'loader types
'			if obj.getType() = "IMAGE" then loadedObject = TAssetManager.ConvertImageToSprite( LoadImage( obj.getUrl() ), obj.getName() )
			if obj.getType() = "SPRITE" then loadedObject = TAsset(TGW_Sprites.LoadFromAsset(obj) )
			if obj.getType() = "IMAGE" then loadedObject = TAsset(TGW_Sprites.LoadFromAsset(obj) )

			'add to map of loaded objects
			?Threaded
				LockMutex(TAssetManager.AssetsLoadedLock)
			?
			TAssetManager.content.insert(obj.GetName(), loadedObject)
			'remove asset from toload-map ?
			'---
			?Threaded
				UnlockMutex(TAssetManager.AssetsLoadedLock)
			?
			GCCollect() '<- FIX!
		next
	End Function

	Method StartLoadingAssets()
		?Threaded
			if TAssetManager.AssetsLoadThread = null OR not ThreadRunning(TAssetManager.AssetsLoadThread)
				print " - - - - - - - - - - - - "
				print "StartLoadingAssets: create thread"
				print " - - - - - - - - - - - - "
				TAssetManager.AssetsLoadThread = CreateThread(TAssetManager.LoadAssetsInThread, Null)
			endif
		?
		?not Threaded
			TAssetManager.LoadAssetsInThread(null)
		?
	End Method

	Method AddToLoadAsset(resourceName:string, resource:object)
		TAssetManager.AssetsToLoad.insert(resourceName, resource)
		self.StartLoadingAssets()
	End Method

	Function Create:TAssetManager(initialContent:TMap=Null, checkExistence:Int = 0)
		Local obj:TAssetManager = New TAssetManager
		If initialContent <> Null Then obj.content = initialContent
		obj.checkExistence = checkExistence
		Return obj
	End Function

	Method AddSet(content:TMap)
		Local key:Object
		For key = EachIn content.keys()
			local obj:object = content.ValueForKey(key)
			local objType:string = "UNKNOWN"
			if TAsset(obj)<> null
				self.Add( lower(string(key)), TAsset(obj), TAsset(obj)._type)
			else
				self.Add( lower(string(key)), TAsset.CreateBaseAsset(obj, objType), objType )
			endif
		Next
	End Method

	Method PrintAssets()
		local res:string = ""
		local count:int = 0
		for local key:object = eachin self.content.keys()
			local obj:object = self.content.ValueForKey(key)
			res = res + " " + string(key) + "["+TAsset(obj)._type+"]"
			count:+1
			if count >= 5 then count=0;res = res + chr(13)
		next
		print res
	End Method

	Method SetContent(content:TMap)
		Self.content = content
	End Method

	Method Add(assetName:String, asset:TAsset, assetType:string="unknown")
		assetName = lower(assetName)
		if asset._type = "IMAGE"
			if TImage(asset._object) = null
				if TGW_Sprites(asset._object) <> null
					print assetName+": image is null but is SPRITE"
				else
					print assetName+": image is null"
				endif
			endif
			asset = self.ConvertImageToSprite(TImage(asset._object), assetName, -1)
		endif
		'if asset._type <> "SPRITE" then print "ASSETMANAGER: Add TAsset '"+lower(string(assetName))+"' [" + asset._type+"]"#
		Self.content.Insert(assetName, asset)
	End Method

	Function ConvertImageToSprite:TGW_Sprites(img:Timage, spriteName:string, spriteID:int =-1)
		local spritepack:TGW_SpritePack = TGW_SpritePack.Create(img, spriteName+"_pack")
		spritepack.AddSprite(spriteName, 0, 0, img.width, img.height, Len(img.frames), spriteID)
		GCCollect() '<- FIX!
		return spritepack.GetSprite(spriteName)
	End Function

	Method AddImageAsSprite(assetName:String, img:TImage, animCount:int = 1)
		if img = null
			print "AddImageAsSprite - null image for "+assetName
		else
			local result:TGW_Sprites =self.ConvertImageToSprite(img, assetName,-1)
			if animCount > 0
				result.animCount = animCount
				result.framew = result.w / animCount
			endif
			self.content.insert(assetName, result )
		endif
	End Method


	'getters for different object-types
	Method GetObject:Object(assetName:String, assetType:string="", defaultAssetName:string="")
		assetName = lower(assetName)
		If Self.checkExistence
			If not Self.content.Contains(assetName) AND defaultAssetName <> "" and Self.content.Contains(lower(defaultAssetName))
				assetName = lower(defaultAssetName)
			endif
			If Self.content.Contains(assetName)
				local result:TAsset = TAsset(Self.content.ValueForKey(assetName))
				if assetType <> ""
					if assetType = result._type
						return result
						'return result._object
					else
						Print assetName+" with type '"+assetType+"' not found, missing a XML configuration file or mispelled name?"
						Throw(assetName+" with type '"+assetType+"' not found, missing a XML configuration file or mispelled name?")
						return Null
					endif
				else
					return result
					'return result._object
				endif
			Else
				self.PrintAssets()
				Print assetName+" not found, missing a XML configuration file or mispelled name?"
				Throw(assetName+" not found, missing a XML configuration file or mispelled name?")
				Return Null
			EndIf
		EndIf
		'Return TAsset(Self.content.ValueForKey(assetName))._object
		return Self.content.ValueForKey(assetName)
	End Method

	Method GetSprite:TGW_Sprites(assetName:String, defaultName:string="")
		assetName = lower(assetName)
		Self.checkExistence = True
		return TGW_Sprites(Self.GetObject(assetName, "SPRITE", defaultName))
	End Method

	Method GetMap:TMap(assetName:String)
		assetName = lower(assetName)
		Return TMap(TAsset(Self.GetObject(assetName, "TMAP"))._object)
	End Method

	Method GetSpritePack:TGW_SpritePack(assetName:String)
		assetName = lower(assetName)
		Self.checkExistence = True
		Return TGW_SpritePack(Self.GetObject(assetName, "SPRITEPACK"))
	End Method

	Method GetFont:TImageFont(assetName:String)
		assetName = lower(assetName)
		Return TImageFont(Self.GetObject(assetName,"IMAGEFONT"))
	End Method

	Method GetImage:TImage(assetName:String)
		assetName = lower(assetName)
		Self.checkExistence = True
		Return TImage(Self.GetObject(assetName))
	End Method

	Method GetBigImage:TBigImage(assetName:String)
		assetName = lower(assetName)
		Self.checkExistence = True
		Return TBigImage(Self.GetObject(assetName))
	End Method

End Type

rem

Type TResource
	field _name:string
	field _loaded:int = 0
	field _type:string
	field _url:object

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

Type TResourceImage extends TResource
	field pixmap:TPixmap
	field image:TImage
	field width:float
	field height:float
	field flags:int

	Function Create:TResourceImage(name:string, url:object, flags:int=-1)
		local tmpObj:TResourceImage = new TResourceImage
		tmpObj.setName(name)
		tmpObj.setUrl(url)
		tmpObj.setType("IMAGE")
		tmpObj.flags = flags
		return tmpObj
	End Function

	Method LoadFromPixmap()
		self.image = LoadImage(self.pixmap, self.flags)
		self.width = self.image.width
		self.height = self.image.height
		GCCollect() '<- FIX!
	End Method
End Type

Type TResourceManager
	global resources:TMap = CreateMap()
	global unloadedResources:TMap = CreateMap()
	global loaderVars:TMap = CreateMap()
	global unloadedMutex:TMutex = CreateMutex()
	global loaderVarsMutex:TMutex = CreateMutex()
	global unloadedThread:TThread


	Function Create:TResourceManager()
		local tmpobj:TResourceManager = new TResourceManager
		return tmpobj
	End Function

	Function StartLoadFiles()
		if TResourceManager.unloadedThread = null
			TResourceManager.unloadedThread =  CreateThread( TResourceManager.LoadFiles, Null )
		endif
	End Function

	'thread function
	Function LoadFiles:Object(data:Object)
		Local count:Int = 0
		Local total:Int = 0
		LockMutex TResourceManager.unloadedMutex
			For tmpobj:object = eachin TResourceManager.unloadedResources.Keys()
				total:+1
			Next

			For Local obj:TResource = EachIn TResourceManager.unloadedResources.Values()
				count:+1
				if TResourceImage(obj) <> Null then TResourceImage(obj).pixmap = LoadPixmap(obj.GetUrl())
				TResourceManager.unloadedResources.remove(obj)
				TResourceManager.resources.insert(obj.GetName(),obj)
				obj.setLoaded(true)
				'print "loaded "+ string(obj.GetUrl()) + " for "+ obj.GetName()
				LockMutex TResourceManager.loaderVarsMutex
					TResourceManager.loaderVars.Insert("count", String(count))
					TResourceManager.loaderVars.Insert("text", String(obj.GetUrl()))
					TResourceManager.loaderVars.Insert("total", String(total))
				UnlockMutex TResourceManager.loaderVarsMutex
				Delay 1
			Next
		UnlockMutex TResourceManager.unloadedMutex
	End Function

	Function LoadImagesFromPixmaps()
		For Local obj:TResource = EachIn TResourceManager.resources.Values()
			if TResourceImage(obj) <> null
				if TResourceImage(obj).flags & MASKEDIMAGE then SetMaskColor 255, 0, 255 else SetMaskColor 0, 0, 0
				TResourceImage(obj).LoadFromPixmap()
				'print "loaded image from pixmap for "+ obj.GetName()
				TResourceImage(obj).pixmap = null
			endif
		Next
	End Function

	Function Add:int(resource:TResource)
		if( NOT resource.GetLoaded() )
			TResourceManager.unloadedResources.Insert(resource.GetName(), resource)
		else
			TResourceManager.resources.Insert(resource.GetName(), resource)
		endif

		'immediately start loading
		TResourceManager.StartLoadFiles()

		return true
	End Function

	Function Get:TResource(name:string)
		If TResource(TResourceManager.resources.ValueForKey(name)) = Null Then Print "TResourceManager: '" + name + "' konnte nicht gefunden werden."
		Return TResource(TResourceManager.resources.ValueForKey(name))
	End Function

	Function GetTImage:TImage(name:string)
		If TResource(TResourceManager.resources.ValueForKey(name)) = Null Then Print "TResourceManager: '" + name + "' konnte nicht gefunden werden."
		Return TResourceImage(TResourceManager.resources.ValueForKey(name)).image
	End Function
End Type
endrem
