Rem
	====================================================================
	BitmapFontLoader extension for Registry utility
	====================================================================

	Allows loading of "font" in config files.

	Contrary to other loaders this class does not insert entries
	to the Registry but to the FontManager.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2019 Ronny Otto, digidea.de

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

		If nodeTypeName.Equals("bitmapfonts", False)
			Local childNode:TxmlNode = TxmlNode(node.GetFirstChild())
			While childNode
				'skip other elements than "bitmapfont"
				If Not childNode.GetName().Equals("bitmapfont", False)
					childNode = childNode.NextSibling()
					Continue
				EndIf

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData 
					childNode = childNode.NextSibling()
					Continue
				EndIf

				'add each font to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					new TRegistryUnloadedResource.Init(resName, "bitmapfont", childData)..
				)

				childNode = childNode.NextSibling()
			Wend
			return Null
		endif

		'=== HANDLE "<BITMAPFONT>" ===
		local fieldNames:String[] = ["name", "url", "size", "default", "flags", "lineHeightModifier", "spaceWidthModifier", "chardWidthModifier", "fixedCharWidth"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)
		'process given relative-url
		data.AddString("url", loader.GetURI(data.GetString("url", "")))

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
'		return data.GetString("name","unknown bitmapfont")
		return data.GetString(keyNameLS,"unknown bitmapfont")
	End Method


	Method LoadFromConfig:TBitmapFont(data:TData, resourceName:string)
		Local name:String = GetNameFromConfig(data).ToLower()
		Local url:String = data.GetString("url", "")
		Local flagsString:String = data.GetString("flags", "")
		Local size:Float = Int(data.GetFloat("size", 10.0) * 64 + 0.5)/64.0 'round to 64th / freetype2's 26.6 encoding
		Local setDefault:Int= data.GetBool("default", False)

		'=== COMPUTE FLAGS ===
		Local flags:Int = SMOOTHFONT
		If flagsString <> ""
			Local flagsArray:String[] = flagsString.split(",")
			For Local flag:String = EachIn flagsArray
				flag = Upper(flag.Trim())
				If flag = "BOLDFONT" Then flags = flags + BOLDFONT
				If flag = "ITALICFONT" Then flags = flags + ITALICFONT
				If flag = "NOSMOOTH" Then flags = flags - SMOOTHFONT
			Next
		EndIf

		If name="" Or url=""
			if url = ""
				TLogger.Log("TRegistryBitmapFontLoader.LoadFromConfig()", "Url is missing.", LOG_ERROR)
			else
				TLogger.Log("TRegistryBitmapFontLoader.LoadFromConfig()", "Name is missing.", LOG_ERROR)
			endif
			'indicate fail
			Return Null
		EndIf

		'=== ADD / CREATE THE FONT ===
		Local font:TBitmapFont = GetBitmapFontManager().Add(name, url, size, flags, True, data.GetInt("fixedCharWidth",-1), data.GetFloat("charWidthModifier", 1.0))

		'=== SET DEFAULTS ===
		If setDefault
			' load defaults only when definition is "pure", so to load
			' an italic font it must be "ITALICFONT" only, not 
			' "ITALICFONT + BOLDFONT" (bold italic)!
			If flags & BOLDFONT And not (flags & ITALICFONT)
				GetBitmapFontManager().baseFontBold = font
			ElseIf flags & ITALICFONT And not (flags & BOLDFONT)
				GetBitmapFontManager().baseFontItalic = font
			ElseIf name.ToLower() = "defaultsmall" or name.ToLower() = "smalldefault"
				GetBitmapFontManager().baseFontSmall = font
			ElseIf not GetBitmapFontManager().baseFont or (not (flags & BOLDFONT) and not (flags & ITALICFONT))
				GetBitmapFontManager().baseFont = font
				'also set as imagefont
				if font.FImageFonts.length > 0
					SetImageFont(font.FImageFonts[0])
				Else
					SetImageFont(Null)
				EndIf
			EndIf
		EndIf

		'=== ADJUST SETTINGS ===
		font.lineHeightModifier = data.GetFloat("lineHeightModifier", font.lineHeightModifier)
		font.spaceWidthModifier = data.GetFloat("spaceWidthModifier", font.spaceWidthModifier)

		'indicate that the loading was successful
		return font
	End Method
End Type
