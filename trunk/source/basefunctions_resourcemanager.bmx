' resource manager
SuperStrict

Import BRL.Max2D
Import BRL.Random
?Threaded
Import brl.Threads
?
Import "basefunctions_image.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_asset.bmx"
Import "basefunctions_events.bmx"
Import "basefunctions_screens.bmx"
Import "basefunctions_sound.bmx"


Global Assets:TAssetManager = TAssetManager.Create(null)

Type TAssetManager
	global content:TMap = CreateMap()
	global defaults:TMap = CreateMap()	'if not specified,  first added of each type gets default
	global fonts:TGW_FontManager = TGW_FontManager.GetInstance()

	global AssetsToLoad:TMap = CreateMap()
'	global AssetsLoaded:TMap = CreateMap()
	?Threaded
	global MutexContentLock:TMutex = CreateMutex()
	global MutexDefaultLock:TMutex = CreateMutex()
	global AssetsToLoadLock:TMutex = CreateMutex()
	global AssetsLoadThread:TThread
	?


	Function Create:TAssetManager(initialContent:TMap=Null)
		Local obj:TAssetManager = New TAssetManager
		If initialContent <> Null Then obj.content = initialContent

		'create some default types (eg. sprite)
		obj.CreateDefaults()

		Return obj
	End Function


	Method CreateDefaults()
		'create a base image
		'this contains a simple checkerboard and a border indicating
		'9patch marks
		'    -			top / left		: mark stretchable area
		'   X0X			bottom / right	: mark content area
		'  |000|
		'   x0x
		'    -
		'so we end with a 30+2 x 30+x pimxap (10px pattern)
		local pix:TPixmap = CreatePixmap(32,32, PF_RGBA8888)
		pix.ClearPixels(ARGB_COLOR(0.0, 0,0,0))
		'marks line
		for local i:int= 12 to 18
			pix.WritePixel(i ,  0, ARGB_COLOR(1.0, 0,0,0))
			pix.WritePixel(i , 31, ARGB_COLOR(1.0, 0,0,0))
			pix.WritePixel(0 ,  i, ARGB_COLOR(1.0, 0,0,0))
			pix.WritePixel(31,  i, ARGB_COLOR(1.0, 0,0,0))
		Next
		'pattern - 4 rects
		for local i:int = 1 to 10
			for local j:int = 1 to 10
				pix.WritePixel(i    , j, ARGB_COLOR(255, 255,  0,  0))
				pix.WritePixel(i+10 , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+20 , j, ARGB_COLOR(255, 255,  0,  0))
			Next
			for local j:int = 11 to 20
				pix.WritePixel(i    , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+10 , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+20 , j, ARGB_COLOR(255, 255,255,255))
			Next
			for local j:int = 21 to 30
				pix.WritePixel(i    , j, ARGB_COLOR(255, 255,  0,  0))
				pix.WritePixel(i+10 , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+20 , j, ARGB_COLOR(255, 255,  0,  0))
			Next
		Next

		local img:Timage = LoadImage(pix, DYNAMICIMAGE | FILTEREDIMAGE)
		local sprite:TGW_Sprite = ConvertImageToSprite(img, "defaultsprite", -1)
		local ninePatchSprite:TGW_NinePatchSprite = new TGW_NinePatchSprite.Create(sprite.parent, "defaultninepatchsprite", sprite.area, null, sprite.animcount, -1, TPoint.Create(sprite.framew, sprite.frameh))

		defaults.insert("pixmap", TAsset.CreateBaseAsset(pix, "defaultpixmap", "PIXMAP"))
		defaults.insert("image", TAsset.CreateBaseAsset(img, "defaultimage", "IMAGE"))
		defaults.insert("sprite", sprite)
		defaults.insert("ninepatchsprite", ninePatchSprite)
	End Method


	'threadable function that loads objects
	Function LoadAssetsInThread:Object(Input:Object)
		print "loadassetsinthread"
		For Local key:string = EachIn TAssetManager.AssetsToLoad.keys()
			local obj:TAsset			= TAsset(TAssetManager.AssetsToLoad.ValueForKey(key))
			local loadedObject:TAsset	= null

			print "LoadAssetsInThread: "+obj.GetName() + " ["+obj.getType()+"]"

			'loader types
'			if obj.getType() = "IMAGE" then loadedObject = TAssetManager.ConvertImageToSprite( LoadImage( obj.getUrl() ), obj.getName() )
			if obj.getType() = "SPRITE" then loadedObject = TAsset(TGW_Sprite.LoadFromAsset(obj) )
			if obj.getType() = "NINEPATCHSPRITE" then loadedObject = TAsset(TGW_NinePatchSprite.LoadFromAsset(obj) )
			if obj.getType() = "IMAGE" then loadedObject = TAsset(TGW_Sprite.LoadFromAsset(obj) )

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
		TAssetManager.AssetsToLoad.insert(resourceName, resource)
		self.StartLoadingAssets()
	End Method


	Method AddSet(content:TMap)
		Local key:string
		For key = EachIn content.keys()
			local obj:object = content.ValueForKey(key)
			if TAsset(obj)
				self.Add(TAsset(obj))
			else
				self.Add(TAsset.CreateBaseAsset(obj, key, "UNKNOWN"))
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


	Method Add:int(asset:TAsset, assetName:string="")
		if not asset then return FALSE
		if assetName="" then assetName = asset.GetName() else assetName = assetName.toLower()

		if asset.GetType() = "IMAGE"
			if TImage(asset._object) = null
				if TGW_Sprite(asset._object) <> null
					print "ASSETS: '" + asset.GetName() + "' image is null but is SPRITE"
				else
					print "ASSETS: '" + asset.GetName() + "' image is null"
				endif
			endif
			asset = ConvertImageToSprite(TImage(asset._object), assetName, -1)
		elseif asset.GetType() = "PIXMAP"
			if TPixmap(asset._object) = null
				print "ASSETS: given pixmap '" + asset.GetName() + "' is NULL"
			endif
		endif

		?Threaded
			LockMutex(MutexContentLock)
			content.Insert(assetName, asset)
			UnlockMutex(MutexContentLock)
		?not Threaded
			content.Insert(assetName, asset)
		?

	End Method


	Function ConvertImageToSprite:TGW_Sprite(img:Timage, spriteName:string, spriteID:int =-1)
		local spritepack:TGW_SpritePack = TGW_SpritePack.Create(img, spriteName+"_pack")
		local sprite:TGW_Sprite = new TGW_Sprite.Create(spritepack, spriteName, TRectangle.Create(0, 0, img.width, img.height), null, Len(img.frames), spriteID)
		spritepack.addSprite(sprite)
'		GCCollect() '<- FIX!
		return sprite
	End Function


	Method AddImageAsSprite:int(assetName:String, img:TImage, animCount:int = 1)
		if img = null
			print "AddImageAsSprite - null image for "+assetName
			return FALSE
		endif


		local result:TGW_Sprite = self.ConvertImageToSprite(img, assetName,-1)
		if animCount > 0
			result.animCount = animCount
			result.framew = result.area.GetW() / animCount
		endif

		return Add(result)
	End Method


	'getters for different object-types
	Method GetObject:Object(assetName:String, assetType:string="", defaultAssetName:string="")
		assetName = lower(assetName)
		local result:TAsset = TAsset(content.ValueForKey(assetName))

		'nothing found - try given default asset
		if not result and defaultAssetName <> ""
			result = TAsset(content.ValueForKey(defaultAssetName.toLower()))
		endif

		'if neither assetName nor defaultAssetName returned a value, use managers
		'default values - only possible if Type is  known
		if not result
			result = TAsset(defaults.ValueForKey(assetType.toLower()))
			'if an default is known - set it
			if result
				'to avoid multiple messages, we NOW add this default asset as the required
				'one so that next run it is found normally
				Print "ASSETMANAGER: ~q"+ assetName +"~q of type ~q"+assetType+"~q not found ! XML-file missing or wrong name? Added a default to avoid crashes."
				'this time add "assetName" so it is stored with the name looked for
				Add(result, assetName)
			endif
		endif

		'check result
		if result
			'do not limit to specific assetType?
			if assetType = "" then return result
			'result of required  type?
			if result.GetType() = assetType.toUpper() then return result
		endif

		'something went wrong - print an error and exit application
		PrintAssets()
		Throw assetName+" type ~q"+assetType+"~q not found in assets. XML configuration file missing or mispelled name? Error not recoverable. App might crash now"
		return Null
	End Method


	Method GetFont:TGW_BitmapFont(_FName:String, _FSize:Int = -1, _FStyle:Int = -1)
		return fonts.GetFont(_FName, _FSize, _FStyle)
	End Method


	Method GetSprite:TGW_Sprite(assetName:String, defaultName:string="")
		return TGW_Sprite(GetObject(assetName, "SPRITE", defaultName))
	End Method


	Method GetNinePatchSprite:TGW_NinePatchSprite(assetName:String, defaultName:string="")
		return TGW_NinePatchSprite(GetObject(assetName, "NINEPATCHSPRITE", defaultName))
	End Method


	Method GetList:TList(assetName:String)
		Return TList(TAsset(GetObject(assetName, "TLIST"))._object)
	End Method


	Method GetMap:TMap(assetName:String)
		Return TMap(TAsset(GetObject(assetName, "TMAP"))._object)
	End Method


	Method GetSpritePack:TGW_SpritePack(assetName:String)
		Return TGW_SpritePack(GetObject(assetName, "SPRITEPACK"))
	End Method


	Method GetImageFont:TImageFont(assetName:String)
		Return TImageFont(GetObject(assetName,"IMAGEFONT"))
	End Method


	Method GetImage:TImage(assetName:String)
		'tpixmap is no child of TAsset ...get _object
		Return TImage(TAsset(GetObject(assetName))._object)
	End Method


	Method GetPixmap:TPixmap(assetName:String)
		'tpixmap is no child of TAsset ...get _object
		Return TPixmap(TAsset(GetObject(assetName, "PIXMAP"))._object)
	End Method


	Method GetBigImage:TBigImage(assetName:String)
		Return TBigImage(GetObject(assetName))
	End Method
End Type



Type TXmlLoader
	Field xml:TXmlHelper = null
	Field Values:TMap = CreateMap()
	Field url:string=""
	Field baseURI:string = ""	'by default all resources are based on "main"dir

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


	Method ConvertURI:string(uri:string)
		return baseURI + uri
	End Method


	Method Parse(url:String)
		TDevHelper.log("XmlLoader.Parse:", url, LOG_LOADING)
		'reset counter
		self.maxItemNumber = 1
		self.currentItemNumber = 0

		self.url = ConvertURI(url)
		self.xml = TXmlHelper.Create(self.url)
		If Self.xml = Null Then TDevHelper.log("TXmlLoader.Parse", "file '" + url + "' not found.", LOG_LOADING)

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
			EventManager.triggerEvent(TEventSimple.Create("resources.onLoad." + _type, TData.Create().AddObject("node", childNode).AddObject("xmlLoader", Self)))

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

		'process given relative-url
		_url = ConvertURI(_url)

		'emit loader event for loading screen
		self.doLoadElement("XmlFile", _url, "loading", self.currentItemNumber)

		Local childXML:TXmlLoader = TXmlLoader.Create()
		childXML.Parse(_url)

		For Local obj:Object = EachIn MapKeys(childXML.Values)
			TDevHelper.log("XmlLoader.LoadXmlResource()", "loading object: " + String(obj), LOG_LOADING | LOG_DEBUG, TRUE)
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

		'process given relative-url
		_url = ConvertURI(_url)

		'emit loader event for loading screen
		self.doLoadElement("pixmap resource", _url, "loading", self.currentItemNumber)
		Assets.Add(TAsset.CreateBaseAsset(LoadPixmap(_url), _name, "PIXMAP") )
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
		Local LoadAssetHelper:TGW_Sprite = new TGW_Sprite.Create(null,_name, TRectangle.Create(0,0,0,0), null, _frames, -1, TPoint.Create(_cellwidth, _cellheight))
		LoadAssetHelper._flags = _flags

		'referencing another sprite? (same base)
		If _url.StartsWith("[")
			_url = Mid(_url, 2, Len(_url)-2)
			Local referenceAsset:TGW_Sprite = Assets.GetSprite(_url)
			LoadAssetHelper.setUrl(_url)
			Assets.Add(TGW_Sprite.LoadFromAsset(LoadAssetHelper))
			Self.parseScripts(childNode, _img)
		'original image, has to get loaded
		Else
			'process given relative-url
			_url = ConvertURI(_url)

			LoadAssetHelper.setUrl(_url)

			If directLoadNeeded
				'print "LoadImageResource: "+_name + " | DIRECT type = "+_type
				'add as single sprite so it is reachable through "GetSprite" too
				Local sprite:TGW_Sprite = TGW_Sprite.LoadFromAsset(LoadAssetHelper)
				If _r >= 0 And _g >= 0 And _b >= 0 then sprite.colorize( TColor.Create(_r,_g,_b) )
				Assets.Add(sprite)
				Self.parseScripts(childNode, sprite.GetImage())
			Else
				'print "LoadImageResource: "+_name + " | THREAD type = "+_type
				Assets.AddToLoadAsset(_name, LoadAssetHelper)
				'TExtendedPixmap.Create(_name, _url, _cellwidth, _cellheight, _frames, _type)
			EndIf
		EndIf

	End Method


	Method parseScripts(childNode:TxmlNode, data:Object)
		'TDevHelper.log("XmlLoader.LoadImageResource()", "found image scripts", LOG_LOADING | LOG_DEBUG, TRUE)
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
						'if self.loadWarning < 2
						'	Print "parseScripts: COLORIZE  <-- param should be asset not timage"
						'	self.loadWarning :+1
						'endif

						'emit loader event for loading screen
			'			self.doLoadElement("colorize copy", _dest, "colorize copy")

						local img:Timage = ColorizeImage(TImage(data), TColor.Create(_r, _g, _b) )
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
						Local _x:Int			= xml.findValueInt(script, "x", 			TGW_Spritepack(data).getSprite(_src).area.GetX())
						Local _y:Int			= xml.findValueInt(script, "y", 			TGW_Spritepack(data).getSprite(_src).area.GetY())
						Local _w:Int			= xml.findValueInt(script, "w", 			TGW_Spritepack(data).getSprite(_src).area.GetW())
						Local _h:Int			= xml.findValueInt(script, "h", 			TGW_Spritepack(data).getSprite(_src).area.GetH())
						Local _offsetTop:Int	= xml.findValueInt(script, "offsetTop", 	TGW_Spritepack(data).getSprite(_src).offset.GetTop())
						Local _offsetLeft:Int	= xml.findValueInt(script, "offsetLeft", 	TGW_Spritepack(data).getSprite(_src).offset.GetLeft())
						Local _offsetBottom:Int	= xml.findValueInt(script, "offsetBottom", 	TGW_Spritepack(data).getSprite(_src).offset.GetBottom())
						Local _offsetRight:Int	= xml.findValueInt(script, "offsetRight", 	TGW_Spritepack(data).getSprite(_src).offset.GetRight())
						Local _frames:Int		= xml.findValueInt(script, "frames",		TGW_Spritepack(data).getSprite(_src).animcount)

						'emit loader event for loading screen
						self.doLoadElement("add copy sprite", _dest, "")

						Assets.Add(TGW_Spritepack(data).AddSpritecopy(_src, _dest, TRectangle.Create(_x,_y,_w,_h), TRectangle.Create(_offsetTop, _offsetLeft, _offsetBottom, _offsetRight), _frames, TColor.Create(_r, _g, _b)))
					EndIf
				EndIf


			Next
		EndIf
	End Method


	Method LoadSpritePackResource(childNode:TxmlNode)
		Local _name:String	= Lower( xml.findValue(childNode, "name", "") )
		Local _url:String	= xml.findValue(childNode, "url", "")
		Local _flags:Int	= Self.GetImageFlags(childNode)

		'process given relative-url
		_url = ConvertURI(_url)


		'emit loader event for loading screen
		self.doLoadElement("image spritepack resource", _url, "loading", self.currentItemNumber)


		'Print "LoadSpritePackResource: "+_name + " " + _flags + " ["+url+"]"
		Local _image:TImage	= LoadImage(_url, _flags) 'CheckLoadImage(_url, _flags)
		Local spritePack:TGW_SpritePack = TGW_SpritePack.Create(_image, _name)
		'add spritepack to asset
		Assets.Add(spritePack)

		'sprites
		Local children:TxmlNode = xml.FindChild(childNode, "children")
		If children <> Null
			For Local child:TxmlNode = EachIn children
				if child.getType() <> XML_ELEMENT_NODE then continue

				Local childName:String		= Lower(xml.findValue(child,"name", ""))
				Local childX:Int			= xml.findValueInt(child, "x", 0)
				Local childY:Int			= xml.findValueInt(child, "y", 0)
				Local childW:Int			= xml.findValueInt(child, "w", 1)
				Local childH:Int			= xml.findValueInt(child, "h", 1)
				Local childOffsetTop:Int	= xml.findValueInt(child, "offsetTop", 0)
				Local childOffsetLeft:Int	= xml.findValueInt(child, "offsetLeft", 0)
				Local childOffsetRight:Int	= xml.findValueInt(child, "offsetRight", 0)
				Local childOffsetBottom:Int	= xml.findValueInt(child, "offsetBottom", 0)
				Local childID:Int			= xml.findValueInt(child, "id", -1)
				Local childFrames:Int		= xml.findValueInt(child, "frames", 1)
				      childFrames			= xml.findValueInt(child, "f", childFrames)
				Local childIsNinePatch:Int	= xml.findValueBool(child, "ninePatch", FALSE)

				If childName<> "" And childW > 0 And childH > 0
					'emit loader event for loading screen
					self.doLoadElement("image spritepack resource", _url, "load sprite from pack")


					'create sprite and add it to assets
					Local sprite:TGW_Sprite
					if childIsNinePatch
						sprite = new TGW_NinePatchSprite.Create(spritePack, childName, TRectangle.Create(childX, childY, childW, childH), TRectangle.Create(childOffsetTop, childOffsetLeft, childOffsetBottom, childOffsetRight), childFrames, childID)
					else
						sprite = new TGW_Sprite.Create(spritePack, childName, TRectangle.Create(childX, childY, childW, childH), TRectangle.Create(childOffsetTop, childOffsetLeft, childOffsetBottom, childOffsetRight), childFrames, childID)
					endif

					spritePack.addSprite(sprite)
					Assets.Add(sprite)

					'recolor/colorize?
					Local _r:Int			= xml.FindValueInt(child, "r", -1)
					Local _g:Int			= xml.FindValueInt(child, "g", -1)
					Local _b:Int			= xml.FindValueInt(child, "b", -1)
					If _r >= 0 And _g >= 0 And _b >= 0 then sprite.colorize( TColor.Create(_r,_g,_b) )
				EndIf
			Next
		EndIf
		Self.parseScripts(childNode, spritepack)
	End Method
End Type


Type TResourceLoaders
	'register the loader-functions to the loader-events
	Function Create:TResourceLoaders()
		EventManager.registerListenerFunction("resources.onLoad.FONTS",			TResourceLoaders.onLoadFonts)
		EventManager.registerListenerFunction("resources.onLoad.FONT",			TResourceLoaders.onLoadFonts)
		EventManager.registerListenerFunction("resources.onLoad.ROOMS",			TResourceLoaders.onLoadRooms)
		EventManager.registerListenerFunction("resources.onLoad.COLORS",		TResourceLoaders.onLoadColors)
		EventManager.registerListenerFunction("resources.onLoad.COLOR", 		TResourceLoaders.onLoadColors)
		EventManager.registerListenerFunction("resources.onLoad.NEWSGENRES",	TResourceLoaders.onLoadNewsGenres)
		EventManager.registerListenerFunction("resources.onLoad.GENRES",		TResourceLoaders.onLoadGenres)
		EventManager.registerListenerFunction("resources.onLoad.MUSIC",			TResourceLoaders.onLoadMusicFile)
		EventManager.registerListenerFunction("resources.onLoad.SFX",			TResourceLoaders.onLoadSfxFile)

		return new TResourceLoaders
	End Function


	Function assignBasics:int(event:TEventBase, childNode:TxmlNode var, xmlLoader:TXmlLoader var)
		childNode = TxmlNode(event.getData().get("node"))
		if childNode = null then return false

		xmlLoader = TXmlLoader(event.getData().get("xmlLoader"))
		if xmlLoader = null then return false

		return true
	End Function


	Function onLoadMusicFile:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'music file
		if triggerEvent.isTrigger("resources.onLoad.MUSIC")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local playOnLoad:int= xmlLoader.xml.FindValueBool(childNode, "playOnLoad", FALSE)
			Local loop:int = xmlLoader.xml.FindValueBool(childNode, "loop", FALSE)
			Local playlists:string= xmlLoader.xml.FindValue(childNode, "playlists", "")
			'instead of using a default-value in "FindValue()" we also want to have "default"
			'set if one defines 'playlists=""' in the xml file
			if playlists="" then playlists = "default"

			url = xmlLoader.ConvertURI(url)

			local stream:TMusicStream = TMusicStream.Create(url, loop)
			if not stream or not stream.isValid()
				TDevHelper.log("TResourceLoaders.onLoadSoundFiles()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
			else
				TSoundManager.GetInstance().AddSound(name, stream, playlists)

				'if no music is played yet, try to get one from the "menu"-playlist
				if not TSoundManager.GetInstance().isPlaying()
					TSoundManager.GetInstance().PlayMusicPlaylist("menu")
				endif

				'TDevHelper.log("TResourceLoaders.onLoadSoundFiles()", "File ~q"+url+"~q loaded.", LOG_LOADING | LOG_DEBUG, TRUE)
			endif

		endif
	End Function


	Function onLoadSfxFile:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'sfx file
		if triggerEvent.isTrigger("resources.onLoad.SFX")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local optionLoop:int= xmlLoader.xml.FindValueBool(childNode, "loop", FALSE)
			Local playlists:string= xmlLoader.xml.FindValue(childNode, "playlists", "")

			url = xmlLoader.ConvertURI(url)

			local flags:int = SOUND_HARDWARE
			if optionLoop then flags :| SOUND_LOOP

			local sound:TSound = LoadSound(url, flags)
			if not sound
				TDevHelper.log("TResourceLoaders.onLoadSfxFile()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
			else
				TSoundManager.GetInstance().AddSound(name, sound, playlists)
				'TDevHelper.log("TResourceLoaders.onLoadSfxFile()", "File ~q"+url+"~q loaded.", LOG_LOADING | LOG_DEBUG, TRUE)
			endif

		endif
	End Function

	'could also be in a different files - just register to the special event
	Function onLoadFonts:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'groups
		if triggerEvent.isTrigger("resources.onLoad.FONTS")
			For Local child:TxmlNode = EachIn childNode.GetChildren()
				EventManager.triggerEvent( TEventSimple.Create("resources.onLoad.FONT", TData.Create().AddObject("node", child).AddObject("xmlLoader", xmlLoader) ) )
			Next
		endif

		'individual color
		if triggerEvent.isTrigger("resources.onLoad.FONT")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local size:int		= xmlLoader.xml.FindValueInt(childNode, "size", 10)
			Local setDefault:int= xmlLoader.xml.FindValueInt(childNode, "default", 0)

			url = xmlLoader.ConvertURI(url)

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
			local font:TGW_BitmapFont = Assets.fonts.AddFont(name, url, size, SMOOTHFONT +flags)

			if setDefault
				if flags & BOLDFONT
					Assets.fonts.baseFontBold = font
				elseif flags & ITALICFONT
					Assets.fonts.baseFontItalic = font
				ElseIf name = "smalldefault"
					Assets.fonts.baseFontSmall = font
				else
					Assets.fonts.baseFont = font
				endif
			endif
		endif
	End Function


	'could also be in a different file - just register to the special event
	Function onLoadColors:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'groups
		if triggerEvent.isTrigger("resources.onLoad.COLORS")
			local listName:string = xmlLoader.xml.FindValue(childNode, "name", "colorList")
			local list:TList = CreateList()
			'add list to assets
			Assets.Add(TAsset.CreateBaseAsset(list, listName, "TLIST"))

			For Local child:TxmlNode = EachIn childNode.GetChildren()
				EventManager.triggerEvent( TEventSimple.Create("resources.onLoad.COLOR", TData.Create().AddObject("node", child).AddObject("xmlLoader", xmlLoader).AddObject("list", list) ) )
			Next
		endif

		'individual color
		if triggerEvent.isTrigger("resources.onLoad.COLOR")
			local list:TList	= TList( TEventSimple(triggerEvent).getData().get("list") )
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local r:int			= xmlLoader.xml.FindValueInt(childNode, "r", 0)
			Local g:int			= xmlLoader.xml.FindValueInt(childNode, "g", 0)
			Local b:int			= xmlLoader.xml.FindValueInt(childNode, "b", 0)
			Local a:int			= xmlLoader.xml.FindValueFloat(childNode, "a", 1.0)

			'if a list was given - add to that group
			if list then list.addLast(TColor.Create(r,g,b,a))

			'add the color asset if name given (special colors have names :D)
			if name <> "" then Assets.Add(TAsset.CreateBaseAsset(TColor.Create(r,g,b,a), name, "TCOLOR"))
		endif
	End Function


	'could also be in a different file - just register to the special event
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
			local key:string = Name + owner + id
			values_room.Insert(key, TAsset.CreateBaseAsset(room, key, "ROOMDATA"))
			'TDevHelper.log("XmlLoader.LoadRooms()", "inserted room: " + Name, LOG_LOADING | LOG_DEBUG, TRUE)
			'print "rooms: "+Name + owner
		Next
		Assets.Add(TAsset.CreateBaseAsset(values_room, "rooms", "TMAP"))

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
			local key:string = String(id)
			values_newsgenre.Insert(key, TAsset.CreateBaseAsset(genre, key, "NEWSGENREDATA"))
			'TDevHelper.log("XmlLoader.onLoadNewsGenres()", "inserted newsgenre: " + Name, LOG_LOADING | LOG_DEBUG, TRUE)
		Next

		Assets.Add(TAsset.CreateBaseAsset(values_newsgenre, "newsgenres", "TMAP"))

	End Function


	Function onLoadGenres:int( triggerEvent:TEventBase )
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		Local values_genre:TMap = TMap(xmlLoader.Values.ValueForKey("genres"))
		If values_genre = Null Then values_genre = CreateMap()

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
			local key:string = String(id)
			values_genre.Insert(key, TAsset.CreateBaseAsset(genre, key, "GENREDATA"))
			'TDevHelper.log("XmlLoader.onLoadGenres()", "inserted genre: " + name, LOG_LOADING | LOG_DEBUG, TRUE)
		Next

		Assets.Add(TAsset.CreateBaseAsset(values_genre, "genres", "TMAP"))
	End Function
End Type
TResourceLoaders.Create()