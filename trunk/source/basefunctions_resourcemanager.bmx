' resource manager
SuperStrict

Import BRL.Max2D
Import BRL.Random
Import brl.reflection
?Threaded
Import brl.Threads
?
Import "basefunctions_image.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_asset.bmx"
Import "basefunctions_events.bmx"

Global Assets:TAssetManager = TAssetManager.Create(null,1)

Type TAssetManager
	global content:TMap = CreateMap()
	global fonts:TGW_FontManager = TGW_FontManager.Create()
	Field checkExistence:Int

	global AssetsToLoad:TMap = CreateMap()
'	global AssetsLoaded:TMap = CreateMap()
	?Threaded
	global MutexContentLock:TMutex = CreateMutex()
	global AssetsToLoadLock:TMutex = CreateMutex()
	global AssetsLoadThread:TThread
	?
	'threadable function that loads objects
	Function LoadAssetsInThread:Object(Input:Object)
		print "loadassetsinthread"
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
				LockMutex(MutexContentLock)
			?
			TAssetManager.content.insert(obj.GetName(), loadedObject)
			'remove asset from toload-map ?
			'---
			?Threaded
				UnlockMutex(MutexContentLock)
			?
			GCCollect() '<- FIX!
		next
	End Function

	Method StartLoadingAssets()
		print "startloadingassets"
		?Threaded
			if not TAssetManager.AssetsLoadThread OR not ThreadRunning(TAssetManager.AssetsLoadThread)
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
		print "addtoloadasset"
		TAssetManager.AssetsToLoad.insert(resourceName, resource)
		self.StartLoadingAssets()
	End Method

	Function Create:TAssetManager(initialContent:TMap=Null, checkExistence:Int = 0)
		print "create:Tassetmanager"
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
		elseif asset._type = "PIXMAP"
			if TPixmap(asset._object) = null
				print "ASSETS: given pixmap '"+assetName+"' is NULL"
			endif
		endif
		'if asset._type <> "SPRITE" then print "ASSETMANAGER: Add TAsset '"+lower(string(assetName))+"' [" + asset._type+"]"
		?Threaded
			LockMutex(MutexContentLock)
			Self.content.Insert(assetName, asset)
			UnlockMutex(MutexContentLock)
		?not Threaded
			Self.content.Insert(assetName, asset)
		?
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
			?Threaded
				LockMutex(MutexContentLock)
			?
			self.content.insert(assetName, result )
			?Threaded
				UnlockMutex(MutexContentLock)
			?
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

	Method GetFont:TBitmapFont(_FName:String, _FSize:Int = -1, _FStyle:Int = -1)
		return self.fonts.GetFont(_FName, _FSize, _FStyle)
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

	Method GetImageFont:TImageFont(assetName:String)
		assetName = lower(assetName)
		Return TImageFont(Self.GetObject(assetName,"IMAGEFONT"))
	End Method

	Method GetImage:TImage(assetName:String)
		assetName = lower(assetName)
		Self.checkExistence = True
		'tpixmap is no child of TAsset ...get _object
		Return TImage(TAsset(Self.GetObject(assetName))._object)
	End Method

	Method GetPixmap:TPixmap(assetName:String)
		assetName = lower(assetName)
		Self.checkExistence = True
		'tpixmap is no child of TAsset ...get _object
		Return TPixmap(TAsset(Self.GetObject(assetName, "PIXMAP"))._object)
	End Method

	Method GetBigImage:TBigImage(assetName:String)
		assetName = lower(assetName)
		Self.checkExistence = True
		Return TBigImage(Self.GetObject(assetName))
	End Method

End Type



Type TXmlLoader
	field xml:TXmlHelper = null
'	Field currentFile:xmlDocument
	Field Values:TMap = CreateMap()
	Field url:string=""

	global loadWarning:int = 0
	global maxItemNumber:int = 0
	global currentItemNumber:int = 0
	global loadedItems:int = 0

	Function Create:TXmlLoader()
		return New TXmlLoader
	End Function


	Method doLoadElement(element:string, text:string, action:String, number:int=-1)
		if number < 0 then self.currentItemNumber:+1;number= self.currentItemNumber
		self.loadedItems:+1

		'fire event so LoaderScreen can refresh
		EventManager.triggerEvent( TEventSimple.Create("XmlLoader.onLoadElement", TData.Create().AddString("element", element).AddString("text", text).AddString("action", action).AddNumber("itemNumber", number).AddNumber("maxItemNumber", self.maxItemNumber) ) )
	End Method


	Method Parse(url:String)
		PrintDebug("XmlLoader.Parse:", url, DEBUG_LOADING)
		'reset counter
		self.maxItemNumber = 1
		self.currentItemNumber = 0

		self.xml = TXmlHelper.Create(url)
		self.url = url
		If Self.xml = Null Then PrintDebug ("TXmlLoader", "Datei '" + url + "' nicht gefunden.", DEBUG_LOADING)

		self.LoadResources(xml.root)
		EventManager.triggerEvent( TEventSimple.Create("XmlLoader.onFinishParsing", TData.Create().AddString("url", url).AddNumber("loaded", self.loadedItems) ) )
	End Method


	Method LoadResources(node:TxmlNode)
		local children:TList = node.getChildren()
		for local childNode:TxmlNode = eachin children

			Local _type:String = Upper(xml.findValue(childNode, "type", childNode.getName()))
			if _type<>"RESOURCES" then self.maxItemNumber:+ 1' children.count()	'it is a entry - so increase
		Next

		for local childNode:TxmlNode = eachin node.getChildren()
			Local _type:String = Upper(xml.findValue(childNode, "type", childNode.getName()))


			'some loaders might be interested - fire it so handler reacts immediately
			EventManager.triggerEvent( TEventSimple.Create("LoadResource."+_type, TData.Create().AddObject("node", childNode).AddObject("xmlLoader", self) ) )

			self.currentItemNumber:+1		'increase by each entry

			Select _type
				Case "RESOURCES"			Self.LoadResources(childNode)
'				Case "ROOMS"				Self.LoadRooms(childNode)
				Case "FILE"					Self.LoadXmlFile(childNode)
				Case "PIXMAP"				Self.LoadPixmapResource(childNode)
				Case "IMAGE", "BIGIMAGE"	Self.LoadImageResource(childNode)
				Case "SPRITEPACK"			Self.LoadSpritePackResource(childNode)
			End Select
		Next
	End Method

	Method LoadXmlFile(childNode:TxmlNode)
		Local _url:String = xml.FindValue(childNode, "url", "")
		if _url = "" then return

		'emit loader event for loading screen
		self.doLoadElement("XmlFile", _url, "loading", self.currentItemNumber)

		Local childXML:TXmlLoader = TXmlLoader.Create()
		childXML.Parse(_url)

		For Local obj:Object = EachIn MapKeys(childXML.Values)
			PrintDebug("XmlLoader.LoadXmlResource:", "loading object: " + String(obj), DEBUG_LOADING)
			Self.Values.Insert(obj, childXML.Values.ValueForKey(obj))
		Next
	End Method

	Method LoadChild:TMap(childNode:TxmlNode)
		Local optionsMap:TMap = CreateMap()
		For Local childOptions:TxmlNode = EachIn childNode
			If childOptions.getChildren() <> null
				optionsMap.Insert((Lower(childOptions.getName()) + "_" + Lower(xml.findAttribute(childoptions, "name", "unkown"))), Self.LoadChild(childOptions))
			Else
				optionsMap.Insert((Lower(childOptions.getName()) + "_" + Lower(xml.findAttribute(childoptions, "name", "unkown"))), childOptions.getContent())
			EndIf
		Next
		Return optionsMap
	End Method

	Method GetImageFlags:Int(childNode:TxmlNode)
		Local flags:Int = 0
		Local flagsstring:String = xml.FindValue(childNode, "flags", "")
		If flagsstring <> ""
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


	Method LoadPixmapResource(childNode:TxmlNode)
		Local _name:String		= Lower( xml.FindValue(childNode, "name", "default") )
		Local _type:String		= Upper( xml.FindValue(childNode, "type", childNode.getName()))
		Local _url:String		= xml.FindValue(childNode, "url", "")
		if _type = "" or _url = "" then return

		'emit loader event for loading screen
		self.doLoadElement("pixmap resource", _url, "loading", self.currentItemNumber)
		Assets.Add(_name, TAsset.CreateBaseAsset( LoadPixmap(_url) ,"PIXMAP") )
	End Method

	Method LoadImageResource(childNode:TxmlNode)
		Local _name:String		= Lower( xml.FindValue(childNode, "name", "default") )
		Local _type:String		= Upper( xml.FindValue(childNode, "type", childNode.getName()))
		Local _url:String		= xml.FindValue(childNode, "url", "")
		if _type = "" or _url = "" then return

		'emit loader event for loading screen
		self.doLoadElement("image resource", _url, "loading", self.currentItemNumber)


		Local _frames:Int		= xml.FindValueInt(childNode, "frames", xml.FindValueInt(childNode, "f", 0))
		Local _cellwidth:Int	= xml.FindValueInt(childNode, "cellwidth", xml.FindValueInt(childNode, "cw", 0))
		Local _cellheight:Int	= xml.FindValueInt(childNode, "cellheight", xml.FindValueInt(childNode, "ch", 0))
		Local _img:TImage		= Null

		Local _flags:Int		= Self.GetImageFlags(childNode)
		'recolor/colorize?
		Local _r:Int			= xml.FindValueInt(childNode, "r", -1)
		Local _g:Int			= xml.FindValueInt(childNode, "g", -1)
		Local _b:Int			= xml.FindValueInt(childNode, "b", -1)

		'direct load or threaded possible?
		'solange threaded n bissl buggy - immer direkt laden
		Local directLoadNeeded:Int = True ' <-- threaded load
		If _r >= 0 And _g >= 0 And _b >= 0 then directLoadNeeded = true

		If xml.FindChild(childNode, "scripts") <> Null Then directLoadNeeded = True
		If xml.FindChild(childNode,"colorize") <> Null Then directLoadNeeded = True
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

			If directLoadNeeded
				'print "LoadImageResource: "+_name + " | DIRECT type = "+_type
				'add as single sprite so it is reachable through "GetSprite" too
				Local sprite:TGW_Sprites = TGW_Sprites.LoadFromAsset(LoadAssetHelper)
				If _r >= 0 And _g >= 0 And _b >= 0 then sprite.colorize( TColor.Create(_r,_g,_b) )
				Assets.Add(_name, sprite)
				Self.parseScripts(childNode, sprite.GetImage())
			Else
				'print "LoadImageResource: "+_name + " | THREAD type = "+_type
				Assets.AddToLoadAsset(_name, LoadAssetHelper)
				'TExtendedPixmap.Create(_name, _url, _cellwidth, _cellheight, _frames, _type)
			EndIf
		EndIf

	End Method

	Method parseScripts(childNode:TxmlNode, data:Object)
		PrintDebug("XmlLoader.LoadImageResource:", "found image scripts", DEBUG_LOADING)
		Local scripts:TxmlNode = xml.FindChild(childNode, "scripts")
		If scripts <> Null
			For Local script:TxmlNode = EachIn scripts
				if script.getType() <> XML_ELEMENT_NODE then continue

				Local scriptDo:String	= xml.findValue(script,"do", "")
				local _dest:string		= Lower(xml.findValue(script,"dest", ""))
				Local _r:Int			= xml.FindValueInt(script, "r", -1)
				Local _g:Int			= xml.FindValueInt(script, "g", -1)
				Local _b:Int			= xml.FindValueInt(script, "b", -1)

				If scriptDo = "ColorizeCopy"
					If _r >= 0 And _g >= 0 And _b >= 0 And _dest <> "" And TImage(data) <> Null
						if self.loadWarning < 2
							Print "parseScripts: COLORIZE  <-- param should be asset not timage"
							self.loadWarning :+1
						endif

						'emit loader event for loading screen
			'			self.doLoadElement("colorize copy", _dest, "colorize copy")

						local img:Timage = ColorizeTImage(TImage(data), TColor.Create(_r, _g, _b) )
						if img <> null
							Assets.AddImageAsSprite(_dest, img)
						else
							print "WARNING: "+_dest+" could not be created"
						endif
					EndIf
				EndIf

				If scriptDo = "CopySprite"
					Local _src:String	= xml.findValue(script, "src", "")
					If _r >= 0 And _g >= 0 And _b >= 0 And _dest <> "" And _src <> ""
						'emit loader event for loading screen
				'		self.doLoadElement("copy sprite", _dest, "")

						TGW_Spritepack(data).CopySprite(_src, _dest, TColor.Create(_r, _g, _b))
					EndIf
				EndIf

				If scriptDo = "AddCopySprite"
					Local _src:String	= xml.findValue(script, "src", "")
					If _r >= 0 And _g >= 0 And _b >= 0 And _dest <> "" And _src <> ""
						Local _x:Int		= xml.findValueInt(script, "x", 	TGW_Spritepack(data).getSprite(_src).pos.x)
						Local _y:Int		= xml.findValueInt(script, "y", 	TGW_Spritepack(data).getSprite(_src).pos.y)
						Local _w:Int		= xml.findValueInt(script, "w", 	TGW_Spritepack(data).getSprite(_src).w)
						Local _h:Int		= xml.findValueInt(script, "h", 	TGW_Spritepack(data).getSprite(_src).h)
						Local _frames:Int	= xml.findValueInt(script, "frames",TGW_Spritepack(data).getSprite(_src).animcount)

						'emit loader event for loading screen
						self.doLoadElement("add copy sprite", _dest, "")

						Assets.Add(_dest, TGW_Spritepack(data).AddCopySprite(_src, _dest, _x, _y, _w, _h, _frames, TColor.Create(_r, _g, _b)))
					EndIf
				EndIf


			Next
		EndIf
	End Method

	Method LoadSpritePackResource(childNode:TxmlNode)
		Local _name:String	= Lower( xml.findValue(childNode, "name", "") )
		Local _url:String	= xml.findValue(childNode, "url", "")
		Local _flags:Int	= Self.GetImageFlags(childNode)

		'emit loader event for loading screen
		self.doLoadElement("image spritepack resource", _url, "loading", self.currentItemNumber)


		'Print "LoadSpritePackResource: "+_name + " " + _flags + " ["+url+"]"
		Local _image:TImage	= LoadImage(_url, _flags) 'CheckLoadImage(_url, _flags)
		Local spritePack:TGW_SpritePack = TGW_SpritePack.Create(_image, _name)
		'add spritepack to asset
		Assets.Add(_name, spritePack)

		'sprites
		Local children:TxmlNode = xml.FindChild(childNode, "children")
		If children <> Null
			For Local child:TxmlNode = EachIn children
				if child.getType() <> XML_ELEMENT_NODE then continue

				Local childName:String	= Lower(xml.findValue(child,"name", ""))
				Local childX:Int		= xml.findValueInt(child, "x", 0)
				Local childY:Int		= xml.findValueInt(child, "y", 0)
				Local childW:Int		= xml.findValueInt(child, "w", 1)
				Local childH:Int		= xml.findValueInt(child, "h", 1)
				Local childID:Int		= xml.findValueInt(child, "id", -1)
				Local childFrames:Int	= xml.findValueInt(child, "frames", 1)
				      childFrames		= xml.findValueInt(child, "f", childFrames)

				If childName<> "" And childW > 0 And childH > 0
					'emit loader event for loading screen
					self.doLoadElement("image spritepack resource", _url, "load sprite from pack")


					'create sprite and add it to assets
					Local sprite:TGW_Sprites = spritePack.AddSprite(childName, childX, childY, childW, childH, childFrames, childID)
					Assets.Add(childName, sprite)

					'recolor/colorize?
					Local _r:Int			= xml.FindValueInt(child, "r", -1)
					Local _g:Int			= xml.FindValueInt(child, "g", -1)
					Local _b:Int			= xml.FindValueInt(child, "b", -1)
					If _r >= 0 And _g >= 0 And _b >= 0 then sprite.colorize( TColor.Create(_r,_g,_b) )
				EndIf
			Next
		EndIf
		Self.parseScripts(childNode, spritepack)
		'Self.Values.Insert(_name, TAsset.CreateBaseAsset(spritePack, "SPRITEPACK"))

	End Method
End Type


Type TResourceLoaders
	Function Create:TResourceLoaders()
		EventManager.registerListener( "LoadResource.ROOMS",	TEventListenerRunFunction.Create(TResourceLoaders.onLoadRooms)  )

		return new TResourceLoaders
	End Function

	Function onLoadRooms:int( triggerEvent:TEventBase )
		Local evt:TEventSimple = TEventSimple(triggerEvent)
		If evt=Null then return 0

		local childNode:TxmlNode = TxmlNode(evt.getData().get("node"))
		if childNode = null then return 0
		local xmlLoader:TXmlLoader = TXmlLoader(evt.getData().get("xmlLoader"))
		if xmlLoader = null then return 0


		'for every single room
		Local values_room:TMap = TMap(xmlLoader.values.ValueForKey("rooms"))
		If values_room = Null Then values_room = CreateMap() ;

		For Local child:TxmlNode = EachIn childNode.GetChildren()
'			if child.getType() <> XML_ELEMENT_NODE then continue
			Local room:TMap		= CreateMap()
			Local owner:Int		= xmlLoader.xml.FindValueInt(child, "owner", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")

			'emit loader event for loading screen
			'self.doLoadElement("load rooms", name, "load room")

			room.Insert("name",		name + String(owner))
			room.Insert("owner",	String(owner))
			room.Insert("roomname", name)
			room.Insert("image", 	xmlLoader.xml.FindValue(child, "image", "rooms_archive") )
			local subNode:TxmlNode = null
			subNode = xmlLoader.xml.FindChild(child, "tooltip")
			if subNode <> null
				room.Insert("tooltip", 	xmlLoader.xml.FindValue(subNode, "text", "") )
				room.Insert("tooltip2", xmlLoader.xml.FindValue(subNode, "description", "") )
			else
				room.Insert("tooltip", 	"" )
				room.Insert("tooltip2", "" )
			endif
			subNode = xmlLoader.xml.FindChild(child, "door")
			room.Insert("x", 		xmlLoader.xml.FindValue(subNode, "x", 0) )
			room.Insert("y", 		xmlLoader.xml.FindValue(subNode, "y", 0) )
			room.Insert("doortype", xmlLoader.xml.FindValue(subNode, "type", -1) )
			values_room.Insert(Name + owner, TAsset.CreateBaseAsset(room, "ROOMDATA"))
			PrintDebug("XmlLoader.LoadRooms:", "inserted room: " + Name, DEBUG_LOADING)
			'print "rooms: "+Name + owner
		Next
		Assets.Add("rooms", TAsset.CreateBaseAsset(values_room, "TMAP"))

	End Function
End Type
TResourceLoaders.Create()


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
