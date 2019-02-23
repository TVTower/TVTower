Rem
	====================================================================
	ImageLoader extension for Registry utility
	====================================================================

	Allows loading of "image" in config files.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import BRL.PNGLoader
Import BRL.JPGLoader
Import "base.util.registry.bmx"
Import "base.gfx.sprite.bmx"

'register this loader
new TRegistryImageLoader.Init()


'loader caring about "<image>"-types
Type TRegistryImageLoader extends TRegistryBaseLoader
	Field _createdDefaults:int = FALSE

	Method Init:Int()
		name = "Image"
		resourceNames = "image|pixmap"
		if not registered then Register()
	End Method



	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		'=== LOAD IMAGE DATA ===
		local data:TData = new TData

		data.Add("url", TXmlHelper.FindValue(node, "url", ""))
		if data.GetString("url") = ""
			TLogger.Log("TRegistryImageLoader.LoadFromXML", "Node ~q<"+node.GetName()+">~q contained no or empty url field. Skipped.", LOG_WARNING)
			Return NULL
		Endif
		'process given relative-url
		data.AddString("url", loader.GetURI(data.GetString("url")))
		'emit loader event for loading screen
		'self.doLoadElement("image resource", _url, "loading", self.currentItemNumber)

		data.Add("name", TXmlHelper.FindValue(node, "name", node.GetName()))
		'use url as name if none was given
		if data.GetString("name") = "" or data.GetString("name").ToUpper() = "IMAGE" then data.Add("name", data.GetString("url"))

		data.AddNumber("flags", GetImageFlags(node))

		'batch load some field names
		local fieldNames:String[]
		fieldNames :+ ["img"]
		fieldNames :+ ["frames|f", "frameW|cellwidth|cw", "frameH|cellheight|ch"]
		fieldNames :+ ["r", "g", "b"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		'direct load or threaded possible?
		'solange threaded n bissl buggy - immer direkt laden
		Local directLoadNeeded:Int = True
		If data.GetInt("r",-1) >= 0 And data.GetInt("g",-1) >= 0 And data.GetInt("b",-1) >= 0 then directLoadNeeded = true
		If TXmlHelper.FindChild(node, "scripts") Then directLoadNeeded = True
		If TXmlHelper.FindChild(node,"colorize") Then directLoadNeeded = True

		'check if there are additional scripts to process the image
		'or create copies
		local scriptsData:TData[] = LoadScriptsDataFromXML(node)
		if len(scriptsData)>0 then data.Add("scriptsData", scriptsData)

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown image")
	End Method


	Method LoadFromConfig:object(data:TData, resourceName:string)
		resourceName = resourceName.ToLower()

		local pixmap:TPixmap = LoadPixmap(data.GetString("url"))
		if not pixmap
			TLogger.Log("TRegistryImageLoader.LoadFromConfig()", "File ~q"+data.GetString("url")+"~q is missing or corrupt.", LOG_ERROR)
			return Null
		endif

		'colorize if needed
		If data.GetInt("r",-1) >= 0 And data.GetInt("g",-1) >= 0 And data.GetInt("r",-1) >= 0
			pixmap = ColorizePixmapCopy( pixmap, TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b")) )
		Endif

		'add to registry
		local name:string = GetNameFromConfig(data)
		if resourceName = "image"
			local img:TImage = LoadImage(pixmap, data.GetInt("flags"))
			if not img
				TLogger.Log("TRegistryImageLoader.LoadFromConfig()", "File ~q"+data.GetString("url")+"~q could not be loaded as image.", LOG_ERROR)
				return Null
			endif

			GetRegistry().Set(name, img)

			'load potential new sprites from scripts
			LoadScriptResults(data, img)

			'indicate that the loading was successful
			return img
		else
			GetRegistry().Set(name, pixmap)
			'indicate that the loading was successful
			return pixmap
		endif
	End Method


	'creates default resources: tpixmap, timage, tsprite
	Method CreateDefaultResource:Int()
		if _createdDefaults then return FALSE

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
		local black:int = ARGB_COLOR(255, 0, 0, 0)
		local white:int = ARGB_COLOR(255, 255, 255, 255)
		local red:int = ARGB_COLOR(255, 255, 0, 0)

		pix.ClearPixels(ARGB_COLOR(0, 0, 0, 0))
		'marks line
		for local i:int= 12 to 18
			pix.WritePixel(i ,  0, black)
			pix.WritePixel(i , 31, black)
			pix.WritePixel(0 ,  i, black)
			pix.WritePixel(31,  i, black)
		Next
		'pattern - 4 rects
		for local i:int = 1 to 10
			for local j:int = 1 to 10
				pix.WritePixel(i    , j, red)
				pix.WritePixel(i+10 , j, white)
				pix.WritePixel(i+20 , j, red)
			Next
			for local j:int = 11 to 20
				pix.WritePixel(i    , j, white)
				pix.WritePixel(i+10 , j, white)
				pix.WritePixel(i+20 , j, white)
			Next
			for local j:int = 21 to 30
				pix.WritePixel(i    , j, red)
				pix.WritePixel(i+10 , j, white)
				pix.WritePixel(i+20 , j, red)
			Next
		Next
		local img:Timage = LoadImage(pix, DYNAMICIMAGE | FILTEREDIMAGE)

		'=== ADD DEFAULTS TO REGISTRY ===
		GetRegistry().SetDefault("pixmap", pix)
		GetRegistry().SetDefault("image", img)

		_createdDefaults = TRUE
	End Method


	Function GetImageFlags:Int(childNode:TxmlNode)
		Local flags:Int = 0
		Local flagsstring:String = TXmlHelper.FindValue(childNode, "flags", "")
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
	End Function


	'parses scripts data of a given node (if <scripts> exists within)
	'returns an array of TData containing script variables
	Function LoadScriptsDataFromXML:TData[](node:TxmlNode)
		Local scripts:TxmlNode = TXmlHelper.FindChild(node, "scripts")
		If not scripts then return Null

		'TLogger.log("TRegistryImageLoader.ParseScripts()", "found script block.", LOG_LOADING | LOG_DEBUG, TRUE)
		local datas:TData[]

		For Local script:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(scripts)
			local data:TData = new TData

			'only add to data if the fields exist in the xml
			local fieldNames:String[]
			fieldNames :+ ["do", "src", "dest"]
			fieldNames :+ ["r", "g", "b"]
			fieldNames :+ ["x", "y", "w", "h"]
			fieldNames :+ ["frames"]
			fieldNames :+ ["offsetTop", "offsetLeft", "offsetBottom", "offsetRight"]
			TXmlHelper.LoadValuesToData(script, data, fieldNames)

			'skip if invalid RGB data is provided
			If data.GetInt("r",-1) < 0 then continue
			If data.GetInt("g",-1) < 0 then continue
			If data.GetInt("b",-1) < 0 then continue

			'add script data
			datas :+ [data]
		Next
		'if there exists valid scriptdata ... return it
		'if len(datas) > 0 then
		return datas
	End Function


	'runs all array children in "scriptsData" of the given dataset
	Method LoadScriptResults:int(data:Tdata, parent:object)
		local scriptsData:TData[] = TData[](data.Get("scriptsData", new TData[0]))
		if not scriptsData or scriptsData.length = 0 then return False

		For local scriptData:TData = eachin scriptsData
			RunScriptData(scriptData, parent)
		Next
		return True
	End Method


	'running a script configured with values contained in a data-object
	'objects are directly created within the function and added to
	'the registry
	Function RunScriptData:int(data:TData, parent:object)
		local dest:String = data.GetString("dest").toLower()
		local color:TColor = TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b"))

		Select data.GetString("do").toUpper()
			'Create a colorized copy of the given image
			case "COLORIZECOPY"
				'check prerequisites
				If dest = "" or not TImage(parent) then return FALSE

				local img:Timage = ColorizeImageCopy(TImage(parent), color)
				'add copied image to registry
				if img then GetRegistry().Set(dest, img)
		End Select
	End Function
End Type


'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetImageFromRegistry:TImage(name:string, defaultNameOrSprite:object = Null)
	Return TImage( GetRegistry().Get(name, defaultNameOrSprite, "image") )
End Function

Function GetPixmapFromRegistry:TPixmap(name:string, defaultNameOrSprite:object = Null)
	Return TPixmap( GetRegistry().Get(name, defaultNameOrSprite, "pixmap") )
End Function