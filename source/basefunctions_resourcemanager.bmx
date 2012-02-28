' resource manager
SuperStrict

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
loadedObject.setLoaded(true)
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
		Local key:string
		For key = EachIn content.keys()
			local obj:object = content.ValueForKey(key)
			local objType:string = "UNKNOWN"
			if TAsset(obj)<> null
				self.Add( lower(key), TAsset(obj), TAsset(obj)._type)
			else
				self.Add( lower(key), TAsset.CreateBaseAsset(obj, objType), objType )
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
		'if asset._type <> "SPRITE" then print "ASSETMANAGER: Add TAsset '"+lower(string(assetName))+"' [" + asset._type+"]"
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



Type TXmlLoader
	Field currentFile:xmlDocument
	Field Values:TMap = CreateMap()

	global loadWarning:int = 0


	Function Create:TXmlLoader()
		Local obj:TXmlLoader = New TXmlLoader
		Return obj
	End Function


	Method Parse(url:String)
		PrintDebug("XmlLoader.Parse:", url, DEBUG_LOADING)
		'Local root:xmlNode
		Self.currentFile = xmlDocument.Create(url)
		If Self.currentFile = Null Then PrintDebug ("TXmlLoader", "Datei '" + url + "' nicht gefunden.", DEBUG_LOADING)
		For Local child:xmlNode = EachIn Self.currentFile.Root().ChildList
			Select child.Name
				Case "resources"	Self.LoadResources(child)
				Case "rooms"		Self.LoadRooms(child)
			End Select
		Next
	End Method


	Method LoadChild:TMap(childNode:xmlNode)
		Local optionsMap:TMap = CreateMap()
		For Local childOptions:xmlNode = EachIn childNode.ChildList
			If childOptions.HasChildren()
				optionsMap.Insert((Lower(childOptions.Name) + "_" + Lower(childoptions.Attribute("name", 0).value)), Self.LoadChild(childOptions))
			Else
				optionsMap.Insert((Lower(childOptions.Name) + "_" + Lower(childoptions.Attribute("name", 0).value)), childOptions.Value)
			EndIf
		Next
		Return optionsMap
	End Method


	Method LoadXmlResource(childNode:xmlNode)
		Local _url:String = childNode.FindChild("url", 0, 0).Value
		Local childXML:TXmlLoader = TXmlLoader.Create()
		childXML.Parse(_url)
		For Local obj:Object = EachIn MapKeys(childXML.Values)
			PrintDebug("XmlLoader.LoadXmlResource:", "loading object: " + String(obj), DEBUG_LOADING)
			'print "XmlLoader.LoadXmlResource:"+string(obj)+ " - "+_url
			Self.Values.Insert(obj, childXML.Values.ValueForKey(obj))
		Next
	End Method

	Method GetImageFlags:Int(childNode:xmlNode)
		Local flags:Int = 0
		Local flagsstring:String = ""
		If childNode.FindChild("flags", 0, 0) <> Null
			flagsstring = String(childNode.FindChild("flags", 0, 0).Value)
			Local flagsarray:String[] = flagsstring.split(",")
			For Local flag:String = EachIn flagsarray
				flag = Upper(flag.Trim())
				If flag = "MASKEDIMAGE" Then flags = flags | MASKEDIMAGE
				If flag = "DYNAMICIMAGE" Then flags = flags | DYNAMICIMAGE
				If flag = "FILTEREDIMAGE" Then flags = flags | FILTEREDIMAGE
			Next
		Else
			flags = 0
		EndIf
		Return flags
	End Method

	Method getAttribute:string(node:xmlNode, fieldname:string, defaultValue:string="")
		if node.HasAttribute(fieldname, false)
			return node.Attribute(fieldname).Value
		else
			return defaultValue
		endif
	End Method

	Method LoadImageResource(childNode:xmlNode)
		Local _name:String = Lower( getAttribute(childNode, "name", "default") )
		Local _type:String = Upper(childNode.FindChild("type", 0, 0).Value)
		Local _frames:Int = 0
		Local _cellwidth:Int = 0
		Local _cellheight:Int = 0
		Local _url:String = childNode.FindChild("url", 0, 0).Value
		Local _img:TImage = Null
		Local _flags:Int = Self.GetImageFlags(childNode)
		'direct load or threaded possible?
		'solange threaded n bissl buggy - immer direkt laden
		Local directLoadNeeded:Int = True ' <-- threaded load
		'recolor/colorize?
		Local _r:Int		= Int( getAttribute(childNode, "r", "-1") )
		Local _g:Int		= Int( getAttribute(childNode, "g", "-1") )
		Local _b:Int		= Int( getAttribute(childNode, "b", "-1") )
		If _r >= 0 And _g >= 0 And _b >= 0 then directLoadNeeded = true

		If childNode.FindChild("cellwidth", 0, 0) <> Null Then _cellwidth = Int(childNode.FindChild("cellwidth", 0, 0).Value)
		If childNode.FindChild("cellheight", 0, 0) <> Null Then _cellheight = Int(childNode.FindChild("cellheight", 0, 0).Value)
		If childNode.FindChild("frames", 0, 0) <> Null Then _frames = Int(childNode.FindChild("frames", 0, 0).Value)


		If childNode.FindChild("scripts") <> Null Then directLoadNeeded = True
		If childNode.FindChild("colorize") <> Null Then directLoadNeeded = True

		'create helper, so load-function has all needed data
		Local LoadAssetHelper:TGW_Sprites = TGW_Sprites.Create(Null, _name, 0,0, 0, 0, _frames, -1, _cellwidth, _cellheight)
		LoadAssetHelper._flags = _flags

		'referencing another sprite? (same base)
		If _url.StartsWith("[")
			_url = Mid(_url, 2, Len(_url)-2)
			Local referenceAsset:TGW_Sprites = Assets.GetSprite(_url)
			LoadAssetHelper.setUrl(_url)
			Assets.Add(_name, TGW_Sprites.LoadFromAsset(LoadAssetHelper))
			Self.parseScripts(childNode, _img)
		'original image, has to get loaded
		Else
			LoadAssetHelper.setUrl(_url)

			If directLoadNeeded Then
				'print "LoadImageResource: "+_name + " | DIRECT type = "+_type
				'add as single sprite so it is reachable through "GetSprite" too
				Local sprite:TGW_Sprites = TGW_Sprites.LoadFromAsset(LoadAssetHelper)
				If _r >= 0 And _g >= 0 And _b >= 0 then sprite.colorize(_r,_g,_b)
				Assets.Add(_name, sprite)
				Self.parseScripts(childNode, sprite.GetImage())
			Else
				'print "LoadImageResource: "+_name + " | THREAD type = "+_type
				Assets.AddToLoadAsset(_name, LoadAssetHelper)
				'TExtendedPixmap.Create(_name, _url, _cellwidth, _cellheight, _frames, _type)
			EndIf
		EndIf


	End Method

	Method parseScripts(childNode:xmlNode, data:Object)
		PrintDebug("XmlLoader.LoadImageResource:", "found image scripts", DEBUG_LOADING)
		Local scripts:xmlNode = childNode.FindChild("scripts")
		If scripts <> Null And scripts.ChildList <> Null
			For Local script:xmlNode = EachIn scripts.ChildList
				Local scriptDo:String= String(script.Attribute("do",0).Value)

				local _dest:string	= Lower(String(script.Attribute("dest").Value))
				Local _r:Int		= Int( getAttribute(script, "r", "-1") )
				Local _g:Int		= Int( getAttribute(script, "g", "-1") )
				Local _b:Int		= Int( getAttribute(script, "b", "-1") )


				If scriptDo = "ColorizeCopy"
					If _r >= 0 And _g >= 0 And _b >= 0 And _dest <> "" And TImage(data) <> Null
						if self.loadWarning < 2
							Print "parseScripts: COLORIZE  <-- param should be asset not timage"
							self.loadWarning :+1
						endif

						local img:Timage = ColorizeTImage(TImage(data),_r, _g, _b)
						if img <> null
							Assets.AddImageAsSprite(_dest, img)
						else
							print "WARNING: "+_dest+" could not be created"
						endif
					EndIf
				EndIf

				If scriptDo = "CopySprite"
					Local _src:String	= String(script.Attribute("src").Value)
					If _r >= 0 And _g >= 0 And _b >= 0 And _dest <> "" And _src <> ""
						TGW_Spritepack(data).CopySprite(_src, _dest, _r, _g, _b)
					EndIf
				EndIf

			Next
		EndIf
	End Method

	Method LoadSpritePackResource(childNode:xmlNode)
		Local _name:String = Lower(String(childNode.Attribute("name", 0).Value))
		Local _url:String = childNode.FindChild("url", 0, 0).Value
		Local _flags:Int = Self.GetImageFlags(childNode)
		'Print "LoadSpritePackResource: "+_name + " " + _flags + " ["+url+"]"
		Local _image:TImage = LoadImage(_url, _flags) 'CheckLoadImage(_url, _flags)
		Local spritePack:TGW_SpritePack = TGW_SpritePack.Create(_image, _name)
		'add spritepack to asset
		Assets.Add(_name, spritePack)

		'sprites
		If childNode.FindChild("children") <> Null
			Local children:xmlNode = childNode.FindChild("children")
			For Local child:xmlNode = EachIn children.ChildList
				Local childName:String	= Lower(String(child.Attribute("name", 0).Value))
				Local childX:Int		= Int( getAttribute(child, "x", "0") )
				Local childY:Int		= Int( getAttribute(child, "y", "0") )
				Local childW:Int		= Int( getAttribute(child, "w", "1") )
				Local childH:Int		= Int( getAttribute(child, "h", "1") )
				Local childID:Int		= -1
				Local childFrames:Int	= 1
				If child.HasAttribute("id", 0) Then childID	= Int(child.Attribute("id", 0).Value)
				If child.HasAttribute("frames", 0) Then childFrames	= Int(child.Attribute("frames", 0).Value)
				If child.HasAttribute("f", 0) Then childFrames	= Int(child.Attribute("f", 0).Value)

				If childName<> "" And childW > 0 And childH > 0
					'create sprite and add it to assets
					Local sprite:TGW_Sprites = spritePack.AddSprite(childName, childX, childY, childW, childH, childFrames, childID)
					Assets.Add(childName, sprite)

					'recolor/colorize?
					Local _r:Int		= Int( getAttribute(child, "r", "-1") )
					Local _g:Int		= Int( getAttribute(child, "g", "-1") )
					Local _b:Int		= Int( getAttribute(child, "b", "-1") )
					If _r >= 0 And _g >= 0 And _b >= 0 then sprite.colorize(_r,_g,_b)

				EndIf
			Next
		EndIf
		Self.parseScripts(childNode, spritepack)
		'Self.Values.Insert(_name, TAsset.CreateBaseAsset(spritePack, "SPRITEPACK"))

	End Method

	Method LoadResource(childNode:xmlNode)
		Local _type:String = Upper(childNode.FindChild("type", 0, 0).Value)
		Select _type
			Case "IMAGE", "BIGIMAGE"	Self.LoadImageResource(childNode)
			Case "XML"					Self.LoadXmlResource(childNode)
			Case "SPRITEPACK"			Self.LoadSpritePackResource(childNode)
		End Select
	End Method


	Method LoadResources(childNode:xmlNode)
		'for every single resource
		For Local child:xmlNode = EachIn childNode.ChildList
			Self.LoadResource(child)
		Next
	End Method


	Method GetValue:String(node:xmlNode, child:String = "", attribute:String, defaultvalue:String = "")
		Local result:String = defaultvalue
		Local usenode:xmlNode = node
		If child <> ""
			usenode = node.FindChild(child, 0, 0)
			If usenode = Null Then usenode = node
		EndIf
		If usenode.FindChild(attribute, 0, 0) <> Null
			If usenode.FindChild(attribute, 0, 0).Value <> Null Then Return usenode.FindChild(attribute, 0, 0).value
		Else If usenode.Attribute(attribute, 0) <> Null
			Return usenode.Attribute(attribute, 0).value
		Else
			Return result
		EndIf
	End Method


	Method LoadRooms(childNode:xmlNode)
		'for every single room
		Local values_room:TMap = TMap(Self.values.ValueForKey("rooms"))
		If values_room = Null Then values_room = CreateMap() ;

		For Local child:xmlNode = EachIn childNode.ChildList
			Local room:TMap = CreateMap()
			Local owner:Int = Int(Self.GetValue(child, "", "owner", "-1"))
			Local name:String = Self.GetValue(child, "", "name", "unknown")
			room.Insert("name",		Name + String(owner))
			room.Insert("owner",	String(owner))
			room.Insert("roomname", name)
			room.Insert("image", 	Self.GetValue(child, "", "image", "rooms_archive"))
			room.Insert("tooltip", 	Self.GetValue(child, "tooltip", "1", ""))
			room.Insert("tooltip2", Self.GetValue(child, "tooltip", "2", ""))
			room.Insert("x", 		Self.GetValue(child, "door", "x", "0"))
			room.Insert("y", 		Self.GetValue(child, "door", "y", "0"))
			room.Insert("doortype", Self.GetValue(child, "door", "type", "-1"))
			values_room.Insert(Name + owner, TAsset.CreateBaseAsset(room, "ROOMDATA"))
			PrintDebug("XmlLoader.LoadRooms:", "inserted room: " + Name, DEBUG_LOADING)
			'print "rooms: "+Name + owner
		Next
		Assets.Add("rooms", TAsset.CreateBaseAsset(values_room, "TMAP"))
		'Self.values.Insert("rooms", TAsset.Create(values_room, "ROOMS"))

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
				'Delay 1
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
