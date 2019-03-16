Rem
	====================================================================
	SpriteLoader extension for Registry utility
	====================================================================

	Allows loading of "sprites" in config files.

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
Import "base.util.registry.bmx"
Import "base.util.registry.imageloader.bmx"

'register this loader
new TRegistrySpriteLoader.Init()


'===== LOADER IMPLEMENTATION =====
'loader caring about "<sprite>"-types
Type TRegistrySpriteLoader extends TRegistryImageLoader
	Method Init:Int()
		name = "Sprite"
		'we also load each image as sprite
		resourceNames = "sprite|spritepack|image"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		if _createdDefaults then return FALSE

		local img:TImage = TImage(GetRegistry().GetDefault("image"))
		if not img then return FALSE

		local sprite:TSprite = new TSprite.InitFromImage(img, "defaultsprite")
		'try to find a nine patch pattern
		sprite.EnableNinePatch()

		GetRegistry().SetDefault("sprite", sprite)
		GetRegistry().SetDefault("spritepack", sprite.parent)

		_createdDefaults = TRUE
	End Method


	'override image config loader - to add children (sprites) support
	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = Super.GetConfigFromXML(loader, node)


		local fieldNames:String[]
		fieldNames :+ ["name", "id"]
		fieldNames :+ ["x", "y", "w", "h"]
		fieldNames :+ ["offsetLeft", "offsetTop", "offsetRight", "offsetBottom"]
		fieldNames :+ ["paddingLeft", "paddingTop", "paddingRight", "paddingBottom"]
		fieldNames :+ ["r", "g", "b"]
		fieldNames :+ ["frames|f"]
		fieldNames :+ ["ninepatch", "tilemode"]
		fieldNames :+ ["rotated"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		'are there sprites defined ("children")
		Local childrenNode:TxmlNode = TXmlHelper.FindChild(node, "children")
		If not childrenNode then return data

		local childrenData:TData[]
		For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(childrenNode)
			'load child config into a new data
			local childData:TData = new TData
			TXmlHelper.LoadValuesToData(childNode, childData, fieldNames)

			'add child data
			childrenData :+ [childData]
		Next
		if len(childrenData)>0 then data.Add("childrenData", childrenData)

		return data
	End Method


	Method LoadFromConfig:object(data:TData, resourceName:string)
		resourceName = resourceName.ToLower()

		if resourceName = "sprite" then return LoadSpriteFromConfig(data)

		'also create sprites from images
		if resourceName = "image" then return LoadSpriteFromConfig(data)

		if resourceName = "spritepack" then return LoadSpritePackFromConfig(data)
	End Method



	Method LoadSpriteFromConfig:TSprite(data:TData)
		'create the sprite (name)
		'+ create a spritepack (name+"_pack") if no "parent"-spritepack
		'  is contained in the dataset
		local sprite:TSprite = new TSprite.InitFromConfig(data)
		if not sprite
			TLogger.Log("TRegistrySpriteLoader.LoadSpriteFromConfig()", "File ~q"+data.GetString("url")+"~q could not be loaded as sprite.", LOG_ERROR)
			return Null
		endif

		'add to registry
		GetRegistry().Set(GetNameFromConfig(data), sprite)

		'load potential new sprites from scripts
		LoadScriptResults(data, sprite)

		'indicate that the loading was successful
		return sprite
	End Method



	Method LoadSpritePackFromConfig:TSpritePack(data:TData)
		local url:string = data.GetString("url")
		if url = ""
			TLogger.Log("TRegistrySpriteLoader.LoadSpritePackFromConfig()", "Url is missing.", LOG_ERROR)
			return Null
		endif

		'Print "LoadSpritePackResource: "+data.GetString("name") + " ["+url+"]"

		'use path of the XML file if possible
		if FileType(url) <> FILETYPE_FILE and data.GetString("_xmlSource")
			local sourcePath:string = ExtractDir(data.GetString("_xmlSource"))
			if FileType(sourcePath +"/" + url) = FILETYPE_FILE
				url = sourcePath +"/" + url
			endif
		endif


		Local img:TImage = LoadImage(url, data.GetInt("flags", 0))
		'just return - so requests to the sprite should be using the
		'registries "default sprite" (if registry is used)
		if not img
			TLogger.Log("TRegistrySpriteLoader.LoadSpritePackFromConfig()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
			return Null
		endif

		Local spritePack:TSpritePack = new TSpritePack.Init(img, data.GetString("name"))
		'add spritepack to asset
		GetRegistry().Set(spritePack.name, spritePack)

		'add children
		local childrenData:TData[] = TData[](data.Get("childrenData"))

		For local childData:TData = eachin childrenData
			'add spritepack as parent
			childData.Add("parent", spritePack)

			Local sprite:TSprite = new TSprite
			sprite.InitFromConfig(childData)

			GetRegistry().Set(childData.GetString("name"), sprite)
		Next

		'load potential new sprites from scripts
		LoadScriptResults(data, spritePack)

		'indicate that the loading was successful
		return spritePack
	End Method


	'OVERWRITTEN to add support for TSprite and TSpritepack
	'running a script configured with values contained in a data-object
	'objects are directly created within the function and added to
	'the registry
	Function RunScriptData:int(data:TData, parent:object)
		local dest:String = data.GetString("dest").toLower()
		local src:String = data.GetString("src")
		local color:TColor = TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b"))

		Select data.GetString("do").toUpper()
			'Create a colorized copy of the given image
			case "COLORIZECOPY"
				local useParent:object = parent
				'sprite instead of spritepack as source requested?
				if src
					Local srcSprite:TSprite = TSpritepack(useParent).GetSprite(src)
					if srcSprite
						useParent = srcSprite
					endif
				endif

				local parentImage:TImage
				If TImage(useParent) then parentImage = TImage(useParent)
				If TSpritePack(useParent) then parentImage = TSpritePack(useParent).image
				If TSprite(useParent) then parentImage = TSprite(useParent).GetImage()

				'check prerequisites
				If dest = "" or not parentImage then return FALSE

				local img:Timage = ColorizeImageCopy(parentImage, color)
				if not img then return FALSE
				'add to registry
				if TImage(useParent)
					GetRegistry().Set(dest, img)
				elseif TSpritePack(useParent)
					GetRegistry().Set(dest, new TSpritePack.Init(img, dest))
				elseif TSprite(useParent)
					GetRegistry().Set(dest, new TSprite.InitFromImage(img, dest))
				endif


			'Copy the given Sprite on the spritesheet (spritepack image)
			case "COPYSPRITE"
				'check prerequisites
				If dest = "" Or src = "" then return FALSE
				if not TSpritepack(parent) then return FALSE
				Local srcSprite:TSprite = TSpritepack(parent).GetSprite(src)
				Local destSprite:TSprite = TSpritepack(parent).GetSprite(dest)
				if srcSprite and destSprite
					destSprite.SetImageContent(srcSprite.GetImage(), color)
				endif


			'Create a new sprite copied from another one
			case "ADDCOPYSPRITE"
				'check prerequisites
				If dest = "" Or src = "" then return FALSE
				If not TSpritepack(parent) then return FALSE

				Local srcSprite:TSprite = TSpritepack(parent).GetSprite(src)

				Local x:Int = data.GetInt("x", int(srcSprite.area.GetX()))
				Local y:Int = data.GetInt("y", int(srcSprite.area.GetY()))
				Local w:Int = data.GetInt("w", int(srcSprite.area.GetW()))
				Local h:Int = data.GetInt("h", int(srcSprite.area.GetH()))

				Local offsetTop:Int = data.GetInt("offsetTop", int(srcSprite.offset.GetTop()))
				Local offsetLeft:Int = data.GetInt("offsetLeft", int(srcSprite.offset.GetLeft()))
				Local offsetBottom:Int = data.GetInt("offsetBottom", int(srcSprite.offset.GetBottom()))
				Local offsetRight:Int = data.GetInt("offsetRight", int(srcSprite.offset.GetRight()))
				Local frames:Int = data.GetInt("frames", srcSprite.frames)

				'create a copy of the sprite, copy the src image to it
				'and add to registry
				local sprite:TSprite = new TSprite.Init(..
											TSpritepack(parent), ..
											dest, ..
											new TRectangle.Init(x,y,w,h), ..
											new TRectangle.SetTLBR(offsetTop, offsetLeft, offsetBottom, offsetRight), ..
											frames ..
										)
				sprite.SetImageContent(srcSprite.GetImage(), color)

				GetRegistry().Set(dest, sprite)


			Default
				Throw "sprite script contains unknown command: ~q"+data.GetString("do")+"~q"
		End Select
	End Function
End Type


'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetSpritePackFromRegistry:TSpritePack(name:string, defaultNameOrSpritePack:object = Null)
	Return TSpritePack( GetRegistry().Get(name, defaultNameOrSpritePack, "spritepack") )
End Function


Function GetSpriteFromRegistry:TSprite(name:string, defaultNameOrSprite:object = Null)
	Return TSprite( GetRegistry().Get(name, defaultNameOrSprite, "sprite") )
End Function


Function GetSpriteGroupFromRegistry:TSprite[](baseName:string, defaultNameOrSprite:object = Null)
	local sprite:TSprite
	local result:TSprite[]
	local number:int = 1
	local maxNumber:int = 1000
	repeat
		'do not use "defaultType" or "defaultObject" - we want to know
		'if there is an object with this name
		sprite = TSprite( GetRegistry().Get(baseName+number) )
		number :+1

		if sprite then result :+ [sprite]
	until sprite = null or number >= maxNumber

	'add default one if nothing was found
	if result.length = 0 and defaultNameOrSprite <> null
		if TSprite(defaultNameOrSprite)
			result :+ [TSprite(defaultNameOrSprite)]
		elseif string(defaultNameOrSprite) <> ""
			sprite = TSprite( GetRegistry().Get(string(defaultNameOrSprite), null, "sprite") )
			if sprite then result :+ [sprite]
		endif
	endif


	Return result
End Function