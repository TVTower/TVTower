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


Global Assets:TAssetManager = TAssetManager.Create(Null)

Type TAssetManager
	Global content:TMap = CreateMap()
	Global defaults:TMap = CreateMap()	'if not specified,  first added of each type gets default
	Global fonts:TGW_FontManager = TGW_FontManager.GetInstance()

	Global AssetsToLoad:TMap = CreateMap()
'	global AssetsLoaded:TMap = CreateMap()
	?Threaded
	Global MutexContentLock:TMutex = CreateMutex()
	Global MutexDefaultLock:TMutex = CreateMutex()
	Global AssetsToLoadLock:TMutex = CreateMutex()
	Global AssetsLoadThread:TThread
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
		Local pix:TPixmap = CreatePixmap(32,32, PF_RGBA8888)
		pix.ClearPixels(ARGB_COLOR(0.0, 0,0,0))
		'marks line
		For Local i:Int= 12 To 18
			pix.WritePixel(i ,  0, ARGB_COLOR(1.0, 0,0,0))
			pix.WritePixel(i , 31, ARGB_COLOR(1.0, 0,0,0))
			pix.WritePixel(0 ,  i, ARGB_COLOR(1.0, 0,0,0))
			pix.WritePixel(31,  i, ARGB_COLOR(1.0, 0,0,0))
		Next
		'pattern - 4 rects
		For Local i:Int = 1 To 10
			For Local j:Int = 1 To 10
				pix.WritePixel(i    , j, ARGB_COLOR(255, 255,  0,  0))
				pix.WritePixel(i+10 , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+20 , j, ARGB_COLOR(255, 255,  0,  0))
			Next
			For Local j:Int = 11 To 20
				pix.WritePixel(i    , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+10 , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+20 , j, ARGB_COLOR(255, 255,255,255))
			Next
			For Local j:Int = 21 To 30
				pix.WritePixel(i    , j, ARGB_COLOR(255, 255,  0,  0))
				pix.WritePixel(i+10 , j, ARGB_COLOR(255, 255,255,255))
				pix.WritePixel(i+20 , j, ARGB_COLOR(255, 255,  0,  0))
			Next
		Next

		Local img:TImage = LoadImage(pix, DYNAMICIMAGE | FILTEREDIMAGE)
		Local sprite:TGW_Sprite = ConvertImageToSprite(img, "defaultsprite", -1)
		Local ninePatchSprite:TGW_NinePatchSprite = New TGW_NinePatchSprite.Create(sprite.parent, "defaultninepatchsprite", sprite.area, Null, sprite.animcount, -1, TPoint.Create(sprite.framew, sprite.frameh))

		defaults.insert("pixmap", TAsset.CreateBaseAsset(pix, "defaultpixmap", "PIXMAP"))
		defaults.insert("image", TAsset.CreateBaseAsset(img, "defaultimage", "IMAGE"))
		defaults.insert("sprite", sprite)
		defaults.insert("ninepatchsprite", ninePatchSprite)
	End Method


	'threadable function that loads objects
	Function LoadAssetsInThread:Object(Input:Object)
		Print "loadassetsinthread"
		For Local key:String = EachIn TAssetManager.AssetsToLoad.keys()
			Local obj:TAsset			= TAsset(TAssetManager.AssetsToLoad.ValueForKey(key))
			Local loadedObject:TAsset	= Null

			Print "LoadAssetsInThread: "+obj.GetName() + " ["+obj.getType()+"]"

			'loader types
'			if obj.getType() = "IMAGE" then loadedObject = TAssetManager.ConvertImageToSprite( LoadImage( obj.getUrl() ), obj.getName() )
			If obj.getType() = "SPRITE" Then loadedObject = TAsset(TGW_Sprite.LoadFromAsset(obj) )
			If obj.getType() = "NINEPATCHSPRITE" Then loadedObject = TAsset(TGW_NinePatchSprite.LoadFromAsset(obj) )
			If obj.getType() = "IMAGE" Then loadedObject = TAsset(TGW_Sprite.LoadFromAsset(obj) )

			loadedObject.setLoaded(True)

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
		Next
	End Function


	Method StartLoadingAssets()
		Print "startloadingassets"
		?Threaded
			If Not TAssetManager.AssetsLoadThread Or Not ThreadRunning(TAssetManager.AssetsLoadThread)
				Print " - - - - - - - - - - - - "
				Print "StartLoadingAssets: create thread"
				Print " - - - - - - - - - - - - "
				TAssetManager.AssetsLoadThread = CreateThread(TAssetManager.LoadAssetsInThread, Null)
			EndIf
		?
		?Not Threaded
			TAssetManager.LoadAssetsInThread(Null)
		?
	End Method


	Method AddToLoadAsset(resourceName:String, resource:Object)
		TAssetManager.AssetsToLoad.insert(resourceName, resource)
		Self.StartLoadingAssets()
	End Method


	Method AddSet(content:TMap)
		Local key:String
		For key = EachIn content.keys()
			Local obj:Object = content.ValueForKey(key)
			If TAsset(obj)
				Self.Add(TAsset(obj))
			Else
				Self.Add(TAsset.CreateBaseAsset(obj, key, "UNKNOWN"))
			EndIf
		Next
	End Method


	Method PrintAssets()
		Local res:String = ""
		Local count:Int = 0
		For Local key:Object = EachIn Self.content.keys()
			Local obj:Object = Self.content.ValueForKey(key)
			res = res + " " + String(key) + "["+TAsset(obj)._type+"]"
			count:+1
			If count >= 5 Then count=0;res = res + Chr(13)
		Next
		Print res
	End Method


	Method SetContent(content:TMap)
		Self.content = content
	End Method


	Method Add:Int(asset:TAsset, assetName:String="")
		If Not asset Then Return False
		If assetName="" Then assetName = asset.GetName() Else assetName = assetName.toLower()

		If asset.GetType() = "IMAGE"
			If TImage(asset._object) = Null
				If TGW_Sprite(asset._object) <> Null
					Print "ASSETS: '" + asset.GetName() + "' image is null but is SPRITE"
				Else
					Print "ASSETS: '" + asset.GetName() + "' image is null"
				EndIf
			EndIf
			asset = ConvertImageToSprite(TImage(asset._object), assetName, -1)
		ElseIf asset.GetType() = "PIXMAP"
			If TPixmap(asset._object) = Null
				Print "ASSETS: given pixmap '" + asset.GetName() + "' is NULL"
			EndIf
		EndIf

		?Threaded
			LockMutex(MutexContentLock)
			content.Insert(assetName, asset)
			UnlockMutex(MutexContentLock)
		?Not Threaded
			content.Insert(assetName, asset)
		?

	End Method


	Function ConvertImageToSprite:TGW_Sprite(img:TImage, spriteName:String, spriteID:Int =-1)
		Local spritepack:TGW_SpritePack = TGW_SpritePack.Create(img, spriteName+"_pack")
		Local sprite:TGW_Sprite = New TGW_Sprite.Create(spritepack, spriteName, TRectangle.Create(0, 0, img.width, img.height), Null, Len(img.frames), spriteID)
		spritepack.addSprite(sprite)
'		GCCollect() '<- FIX!
		Return sprite
	End Function


	Method AddImageAsSprite:Int(assetName:String, img:TImage, animCount:Int = 1)
		If img = Null
			Print "AddImageAsSprite - null image for "+assetName
			Return False
		EndIf


		Local result:TGW_Sprite = Self.ConvertImageToSprite(img, assetName,-1)
		If animCount > 0
			result.animCount = animCount
			result.framew = result.area.GetW() / animCount
		EndIf

		Return Add(result)
	End Method


	'getters for different object-types
	Method GetObject:Object(assetName:String, assetType:String="", defaultAssetName:String="", skipErrors:Int = False)
		assetName = Lower(assetName)
		Local result:TAsset = TAsset(content.ValueForKey(assetName))

		'nothing found - try given default asset
		If Not result And defaultAssetName <> ""
			result = TAsset(content.ValueForKey(defaultAssetName.toLower()))
		EndIf

		'if neither assetName nor defaultAssetName returned a value, use managers
		'default values - only possible if Type is  known
		If Not result
			result = TAsset(defaults.ValueForKey(assetType.toLower()))
			'if an default is known - set it
			If result
				'to avoid multiple messages, we NOW add this default asset as the required
				'one so that next run it is found normally
				Print "ASSETMANAGER: ~q"+ assetName +"~q of type ~q"+assetType+"~q not found ! XML-file missing or wrong name? Added a default to avoid crashes."
				'this time add "assetName" so it is stored with the name looked for
				Add(result, assetName)
			EndIf
		EndIf

		'check result
		If result
			'do not limit to specific assetType?
			If assetType = "" Then Return result
			'result of required  type?
			If result.GetType() = assetType.toUpper() Then Return result
		EndIf

		If Not skipErrors
			'something went wrong - print an error and exit application
			PrintAssets()
			Throw assetName+" type ~q"+assetType+"~q not found in assets. XML configuration file missing or mispelled name? Error not recoverable. App might crash now"
		EndIf
		Return Null
	End Method


	Method GetFont:TGW_BitmapFont(_FName:String, _FSize:Int = -1, _FStyle:Int = -1)
		Return fonts.GetFont(_FName, _FSize, _FStyle)
	End Method


	Method GetSprite:TGW_Sprite(assetName:String, defaultName:String="")
		Return TGW_Sprite(GetObject(assetName, "SPRITE", defaultName))
	End Method


	Method GetNinePatchSprite:TGW_NinePatchSprite(assetName:String, defaultName:String="")
		Return TGW_NinePatchSprite(GetObject(assetName, "NINEPATCHSPRITE", defaultName))
	End Method


	Method GetData:TData(assetName:String, defaultObj:TData=Null)
		Local asset:TAsset = TAsset(GetObject(assetName, "TDATA", "", True))
		If Not asset Then Return defaultObj
		Local data:TData = TData(asset._object)
		If Not data Then Return defaultObj
		Return data
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
	Field xml:TXmlHelper = Null
	Field Values:TMap = CreateMap()
	Field url:String=""
	Field baseURI:String = ""	'by default all resources are based on "main"dir

	Global loadWarning:Int = 0
	Global maxItemNumber:Int = 0
	Global currentItemNumber:Int = 0
	Global loadedItems:Int = 0

	Function Create:TXmlLoader()
		Return New TXmlLoader
	End Function


	Method doLoadElement(element:String, text:String, action:String, number:Int=-1)
		If number < 0 Then Self.currentItemNumber:+1;number= Self.currentItemNumber
		Self.loadedItems:+1

		'fire event so LoaderScreen can refresh
		EventManager.triggerEvent( TEventSimple.Create("XmlLoader.onLoadElement", New TData.AddString("element", element).AddString("text", text).AddString("action", action).AddNumber("itemNumber", number).AddNumber("maxItemNumber", Self.maxItemNumber) ) )
	End Method


	Method ConvertURI:String(uri:String)
		Return baseURI + uri
	End Method


	Method Parse(url:String)
		TDevHelper.Log("XmlLoader.Parse:", url, LOG_LOADING)
		'reset counter
		Self.maxItemNumber = 1
		Self.currentItemNumber = 0

		Self.url = ConvertURI(url)
		Self.xml = TXmlHelper.Create(Self.url)
		If Self.xml = Null Then TDevHelper.Log("TXmlLoader.Parse", "file '" + url + "' not found.", LOG_LOADING)

		Self.LoadResources(xml.root)
		EventManager.triggerEvent( TEventSimple.Create("XmlLoader.onFinishParsing", New TData.AddString("url", url).AddNumber("loaded", Self.loadedItems) ) )
	End Method


	Method LoadResources(node:TxmlNode)
		For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
			Local _type:String = Upper(xml.findValue(childNode, "type", childNode.getName()))
			If _type<>"RESOURCES" Then Self.maxItemNumber:+ 1' children.count()	'it is a entry - so increase
		Next

		For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
			Local _type:String = Upper(xml.findValue(childNode, "type", childNode.getName()))


			'some loaders might be interested - fire it so handler reacts immediately
			EventManager.triggerEvent(TEventSimple.Create("resources.onLoad." + _type, New TData.AddObject("node", childNode).AddObject("xmlLoader", Self)))

			Self.currentItemNumber:+1		'increase by each entry

			Select _type
				Case "RESOURCES"			Self.LoadResources(childNode)
				Case "FILE"					Self.LoadXmlFile(childNode)
				Case "DATA"					Self.LoadDataBlock(childNode)
				Case "PIXMAP"				Self.LoadPixmapResource(childNode)
				Case "IMAGE", "BIGIMAGE"	Self.LoadImageResource(childNode)
				Case "SPRITEPACK"			Self.LoadSpritePackResource(childNode)
			End Select
		Next
	End Method

	Method LoadXmlFile:Int(childNode:TxmlNode)
		Local _url:String = xml.FindValue(childNode, "url", "")
		If _url = "" Then Return False

		'process given relative-url
		_url = ConvertURI(_url)

		'emit loader event for loading screen
		Self.doLoadElement("XmlFile", _url, "loading", Self.currentItemNumber)

		If FileSize(_url) = -1 Then
			TDevHelper.Log("XmlLoader.LoadXmlResource()", "file missing: "+_url, LOG_LOADING | LOG_ERROR, True)
			Return False
		EndIf

		Local childXML:TXmlLoader = TXmlLoader.Create()
		childXML.Parse(_url)

		For Local obj:Object = EachIn MapKeys(childXML.Values)
			TDevHelper.Log("XmlLoader.LoadXmlResource()", "loading object: " + String(obj), LOG_LOADING | LOG_DEBUG, True)
			Self.Values.Insert(obj, childXML.Values.ValueForKey(obj))
		Next
	End Method


	Method LoadDataBlock:TData(childNode:TxmlNode)
		Local dataName:String = xml.FindValue(childNode, "name", childNode.GetName())

		'skip unnamed data (no name="x" or <namee type="data">)
		If dataName = "" Or dataName.ToUpper() = "DATA"
			TDevHelper.Log("TRegistryDataLoader.LoadFromXML", "Node ~q<"+childNode.GetName()+">~q contained no or invalid name field. Skipped.", LOG_WARNING)
			Return Null
		EndIf

		Local dataMerge:Int = xml.FindValueBool(childNode, "merge", True)
		Local values:TData = New TData.Init()
		Local data:TData = New TData.Init()

		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
			Local name:String = xml.FindValue(child, "type", child.getName())
			If name = "" Then Continue
			Local value:String = xml.FindValue(child, "value", child.getcontent())
			values.Add(name, value)
		Next



		'if merging - we load the previously stored data (if there is some)
		If dataMerge Then data = Assets.GetData(dataName)
		If Not data Then data = New TData

		'merge in the new values (to an empty - or the old tdata)
		data.Merge(values)

		'add to registry
		Assets.Add(TAsset.CreateBaseAsset(data, dataName, "TDATA"))

		Return data
	End Method


	Method LoadChild:TMap(childNode:TxmlNode)
		Local optionsMap:TMap = CreateMap()

		For Local childOptions:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
			If childOptions.getChildren() <> Null
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


	Method LoadPixmapResource(childNode:TxmlNode, defaultName:String="default")
		Local _name:String		= Lower( xml.FindValue(childNode, "name", defaultName) )
		Local _type:String		= Upper( xml.FindValue(childNode, "type", childNode.getName()))
		Local _url:String		= xml.FindValue(childNode, "url", "")
		If _type = "" Or _url = "" Then Return

		'process given relative-url
		_url = ConvertURI(_url)

		'emit loader event for loading screen
		Self.doLoadElement("pixmap resource", _url, "loading", Self.currentItemNumber)
		Assets.Add(TAsset.CreateBaseAsset(LoadPixmap(_url), _name, "PIXMAP") )
	End Method


	Method LoadImageResource(childNode:TxmlNode, defaultName:String="default")
		Local _name:String		= Lower( xml.FindValue(childNode, "name", defaultName) )
		Local _type:String		= Upper( xml.FindValue(childNode, "type", childNode.getName()))
		Local _url:String		= xml.FindValue(childNode, "url", "")
		If _type = "" Or _url = "" Then Return

		'emit loader event for loading screen
		Self.doLoadElement("image resource", _url, "loading", Self.currentItemNumber)


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
		If _r >= 0 And _g >= 0 And _b >= 0 Then directLoadNeeded = True

		If xml.FindChild(childNode, "scripts") <> Null Then directLoadNeeded = True
		If xml.FindChild(childNode,"colorize") <> Null Then directLoadNeeded = True
		'create helper, so load-function has all needed data
		Local LoadAssetHelper:TGW_Sprite = New TGW_Sprite.Create(Null,_name, TRectangle.Create(0,0,0,0), Null, _frames, -1, TPoint.Create(_cellwidth, _cellheight))
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
				If _r >= 0 And _g >= 0 And _b >= 0 Then sprite.colorize( TColor.Create(_r,_g,_b) )
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
		Local scriptsNode:TxmlNode = xml.FindChild(childNode, "scripts")
		If not scriptsNode then return

		For Local script:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(scriptsNode)
			Local scriptDo:String	= xml.findValue(script,"do", "")
			Local _dest:String		= Lower(xml.findValue(script,"dest", ""))
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

					Local img:TImage = ColorizeImageCopy(TImage(data), TColor.Create(_r, _g, _b) )
					If img <> Null
						Assets.AddImageAsSprite(_dest, img)
					Else
						Print "WARNING: "+_dest+" could not be created"
					EndIf
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
					Self.doLoadElement("add copy sprite", _dest, "")

					Assets.Add(TGW_Spritepack(data).AddSpritecopy(_src, _dest, TRectangle.Create(_x,_y,_w,_h), TRectangle.Create(_offsetTop, _offsetLeft, _offsetBottom, _offsetRight), _frames, TColor.Create(_r, _g, _b)))
				EndIf
			EndIf
		Next
	End Method


	Method LoadSpritePackResource(childNode:TxmlNode)
		Local _name:String	= Lower( xml.findValue(childNode, "name", "") )
		Local _url:String	= xml.findValue(childNode, "url", "")
		Local _flags:Int	= Self.GetImageFlags(childNode)

		'process given relative-url
		_url = ConvertURI(_url)


		'emit loader event for loading screen
		Self.doLoadElement("image spritepack resource", _url, "loading", Self.currentItemNumber)


		'Print "LoadSpritePackResource: "+_name + " " + _flags + " ["+url+"]"
		Local _image:TImage	= LoadImage(_url, _flags) 'CheckLoadImage(_url, _flags)
		Local spritePack:TGW_SpritePack = TGW_SpritePack.Create(_image, _name)
		'add spritepack to asset
		Assets.Add(spritePack)

		'sprites
		Local children:TxmlNode = xml.FindChild(childNode, "children")
		local childrenList:TList = CreateList()
		If children then childrenList = TXmlHelper.GetNodeChildElements(children)

		For Local child:TxmlNode = EachIn childrenList
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
			Local childIsNinePatch:Int	= xml.findValueBool(child, "ninePatch", False)

			If childName<> "" And childW > 0 And childH > 0
				'emit loader event for loading screen
				Self.doLoadElement("image spritepack resource", _url, "load sprite from pack")


				'create sprite and add it to assets
				Local sprite:TGW_Sprite
				If childIsNinePatch
					sprite = New TGW_NinePatchSprite.Create(spritePack, childName, TRectangle.Create(childX, childY, childW, childH), TRectangle.Create(childOffsetTop, childOffsetLeft, childOffsetBottom, childOffsetRight), childFrames, childID)
				Else
					sprite = New TGW_Sprite.Create(spritePack, childName, TRectangle.Create(childX, childY, childW, childH), TRectangle.Create(childOffsetTop, childOffsetLeft, childOffsetBottom, childOffsetRight), childFrames, childID)
				EndIf

				spritePack.addSprite(sprite)
				Assets.Add(sprite)

				'recolor/colorize?
				Local _r:Int			= xml.FindValueInt(child, "r", -1)
				Local _g:Int			= xml.FindValueInt(child, "g", -1)
				Local _b:Int			= xml.FindValueInt(child, "b", -1)
				If _r >= 0 And _g >= 0 And _b >= 0 Then sprite.colorize( TColor.Create(_r,_g,_b) )
			EndIf
		Next

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

		Return New TResourceLoaders
	End Function


	Function assignBasics:Int(event:TEventBase, childNode:TxmlNode Var, xmlLoader:TXmlLoader Var)
		childNode = TxmlNode(event.getData().get("node"))
		If childNode = Null Then Return False

		xmlLoader = TXmlLoader(event.getData().get("xmlLoader"))
		If xmlLoader = Null Then Return False

		Return True
	End Function


	Function onLoadMusicFile:Int( triggerEvent:TEventBase )
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) Then Return 0

		'music file
		If triggerEvent.isTrigger("resources.onLoad.MUSIC")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local playOnLoad:Int= xmlLoader.xml.FindValueBool(childNode, "playOnLoad", False)
			Local loop:Int = xmlLoader.xml.FindValueBool(childNode, "loop", False)
			Local playlists:String= xmlLoader.xml.FindValue(childNode, "playlists", "")
			'instead of using a default-value in "FindValue()" we also want to have "default"
			'set if one defines 'playlists=""' in the xml file
			If playlists="" Then playlists = "default"

			url = xmlLoader.ConvertURI(url)

			Local stream:TMusicStream = TMusicStream.Create(url, loop)
			If Not stream Or Not stream.isValid()
				TDevHelper.Log("TResourceLoaders.onLoadSoundFiles()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
			Else
				TSoundManager.GetInstance().AddSound(name, stream, playlists)

				'if no music is played yet, try to get one from the "menu"-playlist
				If Not TSoundManager.GetInstance().isPlaying()
					TSoundManager.GetInstance().PlayMusicPlaylist("menu")
				EndIf

				'TDevHelper.log("TResourceLoaders.onLoadSoundFiles()", "File ~q"+url+"~q loaded.", LOG_LOADING | LOG_DEBUG, TRUE)
			EndIf

		EndIf
	End Function


	Function onLoadSfxFile:Int( triggerEvent:TEventBase )
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) Then Return 0

		'sfx file
		If triggerEvent.isTrigger("resources.onLoad.SFX")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local optionLoop:Int= xmlLoader.xml.FindValueBool(childNode, "loop", False)
			Local playlists:String= xmlLoader.xml.FindValue(childNode, "playlists", "")

			url = xmlLoader.ConvertURI(url)

			Local flags:Int = SOUND_HARDWARE
			If optionLoop Then flags :| SOUND_LOOP

			Local sound:TSound = LoadSound(url, flags)
			If Not sound
				TDevHelper.Log("TResourceLoaders.onLoadSfxFile()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
			Else
				TSoundManager.GetInstance().AddSound(name, sound, playlists)
				'TDevHelper.log("TResourceLoaders.onLoadSfxFile()", "File ~q"+url+"~q loaded.", LOG_LOADING | LOG_DEBUG, TRUE)
			EndIf

		EndIf
	End Function

	'could also be in a different files - just register to the special event
	Function onLoadFonts:Int( triggerEvent:TEventBase )
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) Then Return 0

		'groups
		If triggerEvent.isTrigger("resources.onLoad.FONTS")
			For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
				EventManager.triggerEvent( TEventSimple.Create("resources.onLoad.FONT", New TData.AddObject("node", child).AddObject("xmlLoader", xmlLoader) ) )
			Next
		EndIf

		'individual color
		If triggerEvent.isTrigger("resources.onLoad.FONT")
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local url:String	= xmlLoader.xml.FindValue(childNode, "url", "")
			Local size:Int		= xmlLoader.xml.FindValueInt(childNode, "size", 10)
			Local setDefault:Int= xmlLoader.xml.FindValueInt(childNode, "default", 0)

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
			EndIf

			If name="" Or url="" Then Return 0
			Local font:TGW_BitmapFont = Assets.fonts.AddFont(name, url, size, SMOOTHFONT +flags)

			If setDefault
				If flags & BOLDFONT
					Assets.fonts.baseFontBold = font
				ElseIf flags & ITALICFONT
					Assets.fonts.baseFontItalic = font
				ElseIf name = "smalldefault"
					Assets.fonts.baseFontSmall = font
				Else
					Assets.fonts.baseFont = font
				EndIf
			EndIf
		EndIf
	End Function


	'could also be in a different file - just register to the special event
	Function onLoadColors:Int( triggerEvent:TEventBase )
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) Then Return 0

		'groups
		If triggerEvent.isTrigger("resources.onLoad.COLORS")
			Local listName:String = xmlLoader.xml.FindValue(childNode, "name", "colorList")
			Local list:TList = CreateList()
			'add list to assets
			Assets.Add(TAsset.CreateBaseAsset(list, listName, "TLIST"))

			For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
				EventManager.triggerEvent( TEventSimple.Create("resources.onLoad.COLOR", New TData.AddObject("node", child).AddObject("xmlLoader", xmlLoader).AddObject("list", list) ) )
			Next
		EndIf

		'individual color
		If triggerEvent.isTrigger("resources.onLoad.COLOR")
			Local list:TList	= TList( TEventSimple(triggerEvent).getData().get("list") )
			Local name:String	= Lower( xmlLoader.xml.FindValue(childNode, "name", "") )
			Local r:Int			= xmlLoader.xml.FindValueInt(childNode, "r", 0)
			Local g:Int			= xmlLoader.xml.FindValueInt(childNode, "g", 0)
			Local b:Int			= xmlLoader.xml.FindValueInt(childNode, "b", 0)
			Local a:Int			= xmlLoader.xml.FindValueFloat(childNode, "a", 1.0)

			'if a list was given - add to that group
			If list Then list.addLast(TColor.Create(r,g,b,a))

			'add the color asset if name given (special colors have names :D)
			If name <> "" Then Assets.Add(TAsset.CreateBaseAsset(TColor.Create(r,g,b,a), name, "TCOLOR"))
		EndIf
	End Function


	'could also be in a different file - just register to the special event
	Function onLoadRooms:Int( triggerEvent:TEventBase )
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) Then Return 0


		'for every single room
		Local values_room:TMap = TMap(xmlLoader.values.ValueForKey("rooms"))
		If values_room = Null Then values_room = CreateMap() ;

		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
'			if child.getType() <> XML_ELEMENT_NODE then continue
			Local room:TMap		= CreateMap()
			Local owner:Int		= xmlLoader.xml.FindValueInt(child, "owner", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")
			Local id:String		= xmlLoader.xml.FindValue(child, "id", "")

			'emit loader event for loading screen
			'self.doLoadElement("load rooms", name, "load room")

			room.Insert("name",		name + String(owner))
			room.Insert("owner",	String(owner))
			room.Insert("roomname", name)
			room.Insert("fake", 	xmlLoader.xml.FindValue(child, "fake", "0") )
			room.Insert("screen", 	xmlLoader.xml.FindValue(child, "screen", "screen_credits") )
			Local subNode:TxmlNode = Null

			'load tooltips
			subNode = xmlLoader.xml.FindChild(child, "tooltip")
			If subNode <> Null
				room.Insert("tooltip", 	xmlLoader.xml.FindValue(subNode, "text", "") )
				room.Insert("tooltip2", xmlLoader.xml.FindValue(subNode, "description", "") )
			Else
				room.Insert("tooltip", 	"" )
				room.Insert("tooltip2", "" )
			EndIf

			'hotspots
			Local hotSpots:TList = CreateList()
			subNode = xmlLoader.xml.FindChild(child, "hotspots")

			If subNode
				For Local hotSpotNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
					If Not hotSpotNode Then Continue
					Local hotspot:TMap = CreateMap()

					hotspot.Insert("name", 				 xmlLoader.xml.FindValue(hotSpotNode, "name", "") )
					hotspot.Insert("tooltiptext", 		 xmlLoader.xml.FindValue(hotSpotNode, "tooltiptext", "") )
					hotspot.Insert("tooltipdescription", xmlLoader.xml.FindValue(hotSpotNode, "tooltipdescription", "") )
					hotspot.Insert("x", 				 xmlLoader.xml.FindValue(hotSpotNode, "x", -1) )
					hotspot.Insert("y", 				 xmlLoader.xml.FindValue(hotSpotNode, "x", -1) )
					hotspot.Insert("floor", 			 xmlLoader.xml.FindValue(hotSpotNode, "floor", -1) )
					hotspot.Insert("width", 			 xmlLoader.xml.FindValue(hotSpotNode, "width", 0) )
					hotspot.Insert("height", 			 xmlLoader.xml.FindValue(hotSpotNode, "height", 0) )
					hotspot.Insert("bottomy", 			 xmlLoader.xml.FindValue(hotSpotNode, "bottomy", 0) )

					hotSpots.addLast(hotspot)
				Next
			EndIf
			room.Insert("hotspots", hotSpots )

			'load door settings
			subNode = xmlLoader.xml.FindChild(child, "door")
			If subNode
				room.Insert("x", 		xmlLoader.xml.FindValue(subNode, "x", -1) )
				room.Insert("floor",	xmlLoader.xml.FindValue(subNode, "floor", -1) )
				room.Insert("doorslot",	xmlLoader.xml.FindValue(subNode, "doorslot", -1) )
				room.Insert("doortype", xmlLoader.xml.FindValue(subNode, "doortype", -1) )
				room.Insert("doorwidth", xmlLoader.xml.FindValue(subNode, "doorwidth", -1) )
			Else
				room.Insert("x", "-1" )
				room.Insert("floor", "0" )
				room.Insert("xpos", "-1")
				room.Insert("doorslot",	"-1")
				room.Insert("doortype", "-1")
				room.Insert("doorwidth", "-1")
			EndIf
			Local key:String = Name + owner + id
			values_room.Insert(key, TAsset.CreateBaseAsset(room, key, "ROOMDATA"))
			'TDevHelper.log("XmlLoader.LoadRooms()", "inserted room: " + Name, LOG_LOADING | LOG_DEBUG, TRUE)
			'print "rooms: "+Name + owner
		Next
		Assets.Add(TAsset.CreateBaseAsset(values_room, "rooms", "TMAP"))

	End Function


	Function onLoadNewsGenres:Int(triggerEvent:TEventBase)
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics(triggerEvent, childNode, xmlLoader) Then Return 0

		Local values_newsgenre:TMap = TMap(xmlLoader.Values.ValueForKey("newsgenres"))
		If values_newsgenre = Null Then values_newsgenre = CreateMap() ;

		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
			Local genre:TMap	= CreateMap()

			Local id:Int		= xmlLoader.xml.FindValueInt(child, "id", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")

			genre.Insert("id", String(id))
			genre.Insert("name", Name)

			Local subNode:TxmlNode = Null
			subNode = xmlLoader.xml.FindChild(child, "audienceAttractions")

			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				Local attrId:String = xmlLoader.xml.FindValue(subNodeChild, "id", "-1")
				Local Value:String = xmlLoader.xml.FindValue(subNodeChild, "value", "0.7")

				genre.Insert(attrId, Value)
			Next
			Local key:String = String(id)
			values_newsgenre.Insert(key, TAsset.CreateBaseAsset(genre, key, "NEWSGENREDATA"))
			'TDevHelper.log("XmlLoader.onLoadNewsGenres()", "inserted newsgenre: " + Name, LOG_LOADING | LOG_DEBUG, TRUE)
		Next

		Assets.Add(TAsset.CreateBaseAsset(values_newsgenre, "newsgenres", "TMAP"))

	End Function


	Function onLoadGenres:Int( triggerEvent:TEventBase )
		Local childNode:TxmlNode = Null
		Local xmlLoader:TXmlLoader = Null
		If Not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) Then Return 0

		Local values_genre:TMap = TMap(xmlLoader.Values.ValueForKey("genres"))
		If values_genre = Null Then values_genre = CreateMap()

		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childNode)
			Local genre:TMap = CreateMap()

			Local id:Int		= xmlLoader.xml.FindValueInt(child, "id", -1)
			Local name:String	= xmlLoader.xml.FindValue(child, "name", "unknown")

			genre.Insert("id",			String(id))
			genre.Insert("name",		name)
			genre.Insert("outcomeMod",	String(xmlLoader.xml.FindValueFloat(child, "outcome-mod", -1)))
			genre.Insert("reviewMod",	String(xmlLoader.xml.FindValueFloat(child, "review-mod", -1)))
			genre.Insert("speedMod",	String(xmlLoader.xml.FindValueFloat(child, "speed-mod", -1)))

			Local subNode:TxmlNode = Null

			subNode = xmlLoader.xml.FindChild(child, "timeMods")
			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				Local time:String = xmlLoader.xml.FindValue(subNodeChild, "time", "-1")
				genre.Insert("timeMod_" + time, 	xmlLoader.xml.FindValue(subNodeChild, "value", "") )
			Next


			subNode = xmlLoader.xml.FindChild(child, "audienceAttractions")
			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				Local id:String = xmlLoader.xml.FindValue(subNodeChild, "id", "-1")
				Local Value:String = xmlLoader.xml.FindValue(subNodeChild, "value", "0.7")

				genre.Insert(id, value)
			Next
			Local key:String = String(id)
			values_genre.Insert(key, TAsset.CreateBaseAsset(genre, key, "GENREDATA"))
			'TDevHelper.log("XmlLoader.onLoadGenres()", "inserted genre: " + name, LOG_LOADING | LOG_DEBUG, TRUE)
		Next

		Assets.Add(TAsset.CreateBaseAsset(values_genre, "genres", "TMAP"))
	End Function
End Type
TResourceLoaders.Create()