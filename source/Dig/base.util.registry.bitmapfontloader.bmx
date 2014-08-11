REM
	===========================================================
	class to load fonts from xml configs, ...
	===========================================================

	Contrary to other loaders this class does not insert entries
	to the Registry but to the FontManager.

ENDREM
SuperStrict
Import BRL.PNGLoader
Import "base.util.registry.bmx"
Import "base.gfx.bitmapfont.bmx"
'register this loader
new TRegistryBitmapFontLoader.Init()


'===== LOADER IMPLEMENTATION =====
'loader caring about "<bitmapfont>"-types (and "<bitmapfonts>"-groups)
Type TRegistryBitmapFontLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "BitmapFont"
		'we also load each image as sprite
		resourceNames = "bitmapfont|bitmapfonts"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
		'hier fontmanager-default font ueberschreiben ?!
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		'=== HANDLE "<BITMAPFONTS>" ===
		Local nodeTypeName:String = TXmlHelper.FindValue(node, "name", node.GetName())

		if nodeTypeName.toLower() = "bitmapfonts"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				if childNode.GetName().ToLower() <> "bitmapfont" then continue

				local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				if not childData then continue

				'add each font to "ToLoad"-list
				local resName:string = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					new TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "bitmapfont", childData)..
				)
			Next
			return Null
		endif

		'=== HANDLE "<BITMAPFONT>" ===
		local fieldNames:String[] = ["name", "url", "size", "default", "flags", "lineHeightModifier", "spaceWidthModifier"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)
		'process given relative-url
		data.AddString("url", loader.GetURI(data.GetString("url", "")))

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown bitmapfont")
	End Method


	Method LoadFromConfig:int(data:TData, resourceName:string)
		Local name:String = GetNameFromConfig(data).ToLower()
		Local url:String = data.GetString("url", "")
		Local flagsString:String = data.GetString("flags", "")
		Local size:Int = data.GetInt("size", 10)
		Local setDefault:Int= data.GetBool("default", False)

		'=== COMPUTE FLAGS ===
		Local flags:Int = 0
		If flagsString <> ""
			Local flagsArray:String[] = flagsString.split(",")
			For Local flag:String = EachIn flagsArray
				flag = Upper(flag.Trim())
				If flag = "BOLDFONT" Then flags = flags + BOLDFONT
				If flag = "ITALICFONT" Then flags = flags + ITALICFONT
			Next
		EndIf

		If name="" Or url="" Then Return False

		'=== ADD / CREATE THE FONT ===
		Local font:TBitmapFont = GetBitmapFontManager().Add(name, url, size, SMOOTHFONT + flags)

		'=== SET DEFAULTS ===
		If setDefault
			If flags & BOLDFONT
				GetBitmapFontManager().baseFontBold = font
			ElseIf flags & ITALICFONT
				GetBitmapFontManager().baseFontItalic = font
			ElseIf name = "smalldefault"
				GetBitmapFontManager().baseFontSmall = font
			Else
				GetBitmapFontManager().baseFont = font
			EndIf
		EndIf

		'=== ADJUST SETTINGS ===
		font.lineHeightModifier = data.GetFloat("lineHeightModifier", font.lineHeightModifier)
		font.spaceWidthModifier = data.GetFloat("spaceWidthModifier", font.spaceWidthModifier)

		'indicate that the loading was successful
		return True
	End Method
End Type