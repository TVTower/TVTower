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
Import "basefunctions_screens.bmx"

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

	Method GetList:TList(assetName:String)
		assetName = lower(assetName)
		Return TList(TAsset(Self.GetObject(assetName, "TLIST"))._object)
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
			EventManager.triggerEvent(TEventSimple.Create("LoadResource." + _type, TData.Create().AddObject("node", childNode).AddObject("xmlLoader", Self)))

			self.currentItemNumber:+1		'increase by each entry

			Select _type
				Case "RESOURCES"			Self.LoadResources(childNode)
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


	Method LoadPixmapResource(childNode:TxmlNode, defaultName:string="default")
		Local _name:String		= Lower( xml.FindValue(childNode, "name", defaultName) )
		Local _type:String		= Upper( xml.FindValue(childNode, "type", childNode.getName()))
		Local _url:String		= xml.FindValue(childNode, "url", "")
		if _type = "" or _url = "" then return

		'emit loader event for loading screen
		self.doLoadElement("pixmap resource", _url, "loading", self.currentItemNumber)
		Assets.Add(_name, TAsset.CreateBaseAsset( LoadPixmap(_url) ,"PIXMAP") )
	End Method

	Method LoadImageResource(childNode:TxmlNode, defaultName:string="default")
		Local _name:String		= Lower( xml.FindValue(childNode, "name", defaultName) )
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
		EventManager.registerListener( "LoadResource.FONTS",	TEventListenerRunFunction.Create(TResourceLoaders.onLoadFonts)  )
		EventManager.registerListener( "LoadResource.FONT",		TEventListenerRunFunction.Create(TResourceLoaders.onLoadFonts)  )
		EventManager.registerListener( "LoadResource.ROOMS",	TEventListenerRunFunction.Create(TResourceLoaders.onLoadRooms)  )
		EventManager.registerListener( "LoadResource.SCREENS",	TEventListenerRunFunction.Create(TResourceLoaders.onLoadScreens)  )
		EventManager.registerListener( "LoadResource.COLORS",	TEventListenerRunFunction.Create(TResourceLoaders.onLoadColors)  )
		EventManager.registerListener("LoadResource.COLOR", TEventListenerRunFunction.Create(TResourceLoaders.onLoadColors))
		EventManager.registerListener("LoadResource.NEWSGENRES", TEventListenerRunFunction.Create(TResourceLoaders.onLoadNewsGenres))
		EventManager.registerListener( "LoadResource.GENRES",	TEventListenerRunFunction.Create(TResourceLoaders.onLoadGenres)  )

		return new TResourceLoaders
	End Function

	Function assignBasics:int(event:TEventBase, childNode:TxmlNode var, xmlLoader:TXmlLoader var)
		Local evt:TEventSimple = TEventSimple(event)
		If evt=Null then return false

		childNode = TxmlNode(evt.getData().get("node"))
		if childNode = null then return false

		xmlLoader = TXmlLoader(evt.getData().get("xmlLoader"))
		if xmlLoader = null then return false

		return true
	End Function


	'could also be in a different files - just register to the special event
	Function onLoadFonts:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'groups
		if triggerEvent.isTrigger("LoadResource.FONTS")
			For Local child:TxmlNode = EachIn childNode.GetChildren()
				EventManager.triggerEvent( TEventSimple.Create("LoadResource.FONT", TData.Create().AddObject("node", child).AddObject("xmlLoader", xmlLoader) ) )
			Next
		endif

		'individual color
		if triggerEvent.isTrigger("LoadResource.FONT")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local size:int		= xmlLoader.xml.FindValueInt(childNode, "size", 10)
			Local setDefault:int= xmlLoader.xml.FindValueInt(childNode, "default", 0)

			Local flags:Int = 0
			Local flagsstring:String = xmlLoader.xml.FindValue(childNode, "flags", "")
			If flagsstring <> ""
				Local flagsarray:String[] = flagsstring.split(",")
				For Local flag:String = EachIn flagsarray
					flag = Upper(flag.Trim())
					If flag = "BOLDFONT" Then flags = flags + BOLDFONT
					If flag = "ITALICFONT" Then flags = flags + ITALICFONT
				Next
			endif

			if name="" or url="" then return 0
			local font:TGW_Font = Assets.fonts.AddFont(name, url, size, SMOOTHFONT +flags)

			if setDefault
				if flags & BOLDFONT
					Assets.fonts.baseFontBold = font.FFont
				elseif flags & ITALICFONT
					Assets.fonts.baseFontItalic = font.FFont
				else
					Assets.fonts.baseFont = font.FFont
				endif
			endif
		endif
	End Function

	'could also be in a different files - just register to the special event
	Function onLoadColors:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'groups
		if triggerEvent.isTrigger("LoadResource.COLORS")
			local listName:string = xmlLoader.xml.FindValue(childNode, "name", "colorList")
			local list:TList = CreateList()
			'add list to assets
			Assets.Add(listName, TAsset.CreateBaseAsset(list, "TLIST"))

			For Local child:TxmlNode = EachIn childNode.GetChildren()
				EventManager.triggerEvent( TEventSimple.Create("LoadResource.COLOR", TData.Create().AddObject("node", child).AddObject("xmlLoader", xmlLoader).AddObject("list", list) ) )
			Next
		endif

		'individual color
		if triggerEvent.isTrigger("LoadResource.COLOR")
			local list:TList	= TList( TEventSimple(triggerEvent).getData().get("list") )
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local r:int			= xmlLoader.xml.FindValueInt(childNode, "r", 0)
			Local g:int			= xmlLoader.xml.FindValueInt(childNode, "g", 0)
			Local b:int			= xmlLoader.xml.FindValueInt(childNode, "b", 0)
			Local a:int			= xmlLoader.xml.FindValueInt(childNode, "a", 255)

			'if a list was given - add to that group
			if list then list.addLast(TColor.Create(r,g,b,a))

			'add the color asset if name given (special colors have names :D)
			if name <> "" then Assets.Add(name, TAsset.CreateBaseAsset(TColor.Create(r,g,b,a), "TCOLOR"))
		endif
	End Function

	'could also be in a different files - just register to the special event
	Function onLoadRooms:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0


		'for every single room
		Local values_room:TMap = TMap(xmlLoader.values.ValueForKey("rooms"))
		If values_room = Null Then values_room = CreateMap() ;

		For Local child:TxmlNode = EachIn childNode.GetChildren()
'			if child.getType() <> XML_ELEMENT_NODE then continue
			Local room:TMap		= CreateMap()
			Local owner:Int		= xmlLoader.xml.FindValueInt(child, "owner", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")
			Local id:string		= xmlLoader.xml.FindValue(child, "id", "")

			'emit loader event for loading screen
			'self.doLoadElement("load rooms", name, "load room")

			room.Insert("name",		name + String(owner))
			room.Insert("owner",	String(owner))
			room.Insert("roomname", name)
			room.Insert("fake", 	xmlLoader.xml.FindValue(child, "fake", "0") )
			room.Insert("screen", 	xmlLoader.xml.FindValue(child, "screen", "screen_credits") )
			local subNode:TxmlNode = null

			'load tooltips
			subNode = xmlLoader.xml.FindChild(child, "tooltip")
			if subNode <> null
				room.Insert("tooltip", 	xmlLoader.xml.FindValue(subNode, "text", "") )
				room.Insert("tooltip2", xmlLoader.xml.FindValue(subNode, "description", "") )
			else
				room.Insert("tooltip", 	"" )
				room.Insert("tooltip2", "" )
			endif

			'hotspots
			local hotSpots:TList = CreateList()
			subNode = xmlLoader.xml.FindChild(child, "hotspots")
			if subNode and subNode.GetChildren()
				For Local hotSpotNode:TxmlNode = EachIn subNode.GetChildren()
					if not hotSpotNode then continue
					local hotspot:TMap = CreateMap()

					hotspot.Insert("name", 					xmlLoader.xml.FindValue(hotSpotNode, "name", "") )
					hotspot.Insert("tooltiptext", 			xmlLoader.xml.FindValue(hotSpotNode, "tooltiptext", "") )
					hotspot.Insert("tooltipdescription", 	xmlLoader.xml.FindValue(hotSpotNode, "tooltipdescription", "") )
					hotspot.Insert("x", 					xmlLoader.xml.FindValue(hotSpotNode, "x", -1) )
					hotspot.Insert("y", 					xmlLoader.xml.FindValue(hotSpotNode, "x", -1) )
					hotspot.Insert("floor", 				xmlLoader.xml.FindValue(hotSpotNode, "floor", -1) )
					hotspot.Insert("width", 				xmlLoader.xml.FindValue(hotSpotNode, "width", 0) )
					hotspot.Insert("height", 				xmlLoader.xml.FindValue(hotSpotNode, "height", 0) )
					hotspot.Insert("bottomy", 				xmlLoader.xml.FindValue(hotSpotNode, "bottomy", 0) )

					hotSpots.addLast(hotspot)
				Next
			endif
			room.Insert("hotspots", hotSpots )

			'load door settings
			subNode = xmlLoader.xml.FindChild(child, "door")
			if subNode
				room.Insert("x", 		xmlLoader.xml.FindValue(subNode, "x", -1) )
				room.Insert("floor",	xmlLoader.xml.FindValue(subNode, "floor", -1) )
				room.Insert("doorslot",	xmlLoader.xml.FindValue(subNode, "doorslot", -1) )
				room.Insert("doortype", xmlLoader.xml.FindValue(subNode, "doortype", -1) )
				room.Insert("doorwidth", xmlLoader.xml.FindValue(subNode, "doorwidth", -1) )
			else
				room.Insert("x", "-1" )
				room.Insert("floor", "0" )
				room.Insert("xpos", "-1")
				room.Insert("doorslot",	"-1")
				room.Insert("doortype", "-1")
				room.Insert("doorwidth", "-1")
			endif
			values_room.Insert(Name + owner + id, TAsset.CreateBaseAsset(room, "ROOMDATA"))
			PrintDebug("XmlLoader.LoadRooms:", "inserted room: " + Name, DEBUG_LOADING)
			'print "rooms: "+Name + owner
		Next
		Assets.Add("rooms", TAsset.CreateBaseAsset(values_room, "TMAP"))

	End Function


	Function onLoadScreens:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'screen group
		if triggerEvent.isTrigger("LoadResource.SCREENS")
			For Local child:TxmlNode = EachIn childNode.GetChildren()
				Local name:String	= Lower( xmlLoader.xml.FindValue(child, "name", "") )
				local image:string	= Lower( xmlLoader.xml.FindValue(child, "image", "screen_bg_archive") )
				local parent:string = Lower( xmlLoader.xml.FindValue(child, "parent", "") )
				if name <> ""
					local screen:TScreen= TScreen.Create(name, Assets.GetSprite(image))

					'if screen has a parent -> set it
					if parent <> "" and TScreen.GetScreen(parent) <> null
						TScreen.GetScreen(parent).AddSubScreen(screen)
					endif
				endif
			Next
		endif
	End Function

	Function onLoadNewsGenres:Int(triggerEvent:TEventBase)
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		If Not TResourceLoaders.assignBasics(triggerEvent, childNode, xmlLoader) Then Return 0

		Local values_newsgenre:TMap = TMap(xmlLoader.Values.ValueForKey("newsgenres"))
		If values_newsgenre = Null Then values_newsgenre = CreateMap() ;

		For Local child:TxmlNode = EachIn childNode.GetChildren()
'			if child.getType() <> XML_ELEMENT_NODE then continue
			Local genre:TMap		= CreateMap()
			
			Local id:Int		= xmlLoader.xml.FindValueInt(child, "id", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")

			genre.Insert("id",		String(id))
			genre.Insert("name", Name)
			
			Local subNode:TxmlNode = Null
			subNode = xmlLoader.xml.FindChild(child, "audienceAttractions")
			For Local subNodeChild:TxmlNode = EachIn subNode.GetChildren()		
				Local attrId:String = xmlLoader.xml.FindValue(subNodeChild, "id", "-1")
				Local Value:String = xmlLoader.xml.FindValue(subNodeChild, "value", "0.7")
				
				genre.Insert(attrId, Value)
			Next			
			
			values_newsgenre.Insert(String(id), TAsset.CreateBaseAsset(genre, "NEWSGENREDATA"))
			PrintDebug("XmlLoader.onLoadNewsGenres:", "inserted newsgenre: " + Name, DEBUG_LOADING)
		Next

		Assets.Add("newsgenres", TAsset.CreateBaseAsset(values_newsgenre, "TMAP"))

	End Function	
	
	Function onLoadGenres:int( triggerEvent:TEventBase )

		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		Local values_genre:TMap = TMap(xmlLoader.Values.ValueForKey("genres"))
		If values_genre = Null Then values_genre = CreateMap() ;

		For Local child:TxmlNode = EachIn childNode.GetChildren()
'			if child.getType() <> XML_ELEMENT_NODE then continue
			Local genre:TMap		= CreateMap()
			
			Local id:Int		= xmlLoader.xml.FindValueInt(child, "id", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")

			genre.Insert("id",		String(id))
			genre.Insert("name",	name)
			genre.Insert("outcomeMod",	string(xmlLoader.xml.FindValueFloat(child, "outcome-mod", -1)))
			genre.Insert("reviewMod",	string(xmlLoader.xml.FindValueFloat(child, "review-mod", -1)))
			genre.Insert("speedMod",	string(xmlLoader.xml.FindValueFloat(child, "speed-mod", -1)))						 
			
			local subNode:TxmlNode = null
			subNode = xmlLoader.xml.FindChild(child, "timeMods")
			For Local subNodeChild:TxmlNode = EachIn subNode.GetChildren()
				local time:String = xmlLoader.xml.FindValue(subNodeChild, "time", "-1")			
				genre.Insert("timeMod_" + time, 	xmlLoader.xml.FindValue(subNodeChild, "value", "") )				
			Next
			
			
			subNode = xmlLoader.xml.FindChild(child, "audienceAttractions")
			For Local subNodeChild:TxmlNode = EachIn subNode.GetChildren()		
				local id:String = xmlLoader.xml.FindValue(subNodeChild, "id", "-1")
				Local Value:String = xmlLoader.xml.FindValue(subNodeChild, "value", "0.7")
				
				genre.Insert(id, value)
			Next			
			
			values_genre.Insert(String(id), TAsset.CreateBaseAsset(genre, "GENREDATA"))
			PrintDebug("XmlLoader.onLoadGenres:", "inserted genre: " + name, DEBUG_LOADING)
		Next

		Assets.Add("genres", TAsset.CreateBaseAsset(values_genre, "TMAP"))

	End Function	
End Type
TResourceLoaders.Create()