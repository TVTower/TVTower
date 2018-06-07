Rem
	====================================================================
	SpriteFrameAnimationLoader extension for Registry utility
	====================================================================

	Allows loading of "spriteFrameAnimation" and "spriteFrameAnimations"
	in config files.

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
Import "base.gfx.sprite.frameanimation.bmx"

'register this loader
new TRegistrySpriteFrameAnimationLoader.Init()


'===== LOADER IMPLEMENTATION =====
'loader caring about "<spriteframeanimations>"-types
Type TRegistrySpriteFrameAnimationLoader extends TRegistryBaseLoader
	Field _createdDefaults:int = FALSE

	Method Init:Int()
		name = "SpriteFrameAnimation"
		'only handle the collections (spriteframeanimation_s)
		resourceNames = "spriteframeanimations"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'needed?
		_createdDefaults = TRUE
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown spriteFrameAnimationCollection")
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		local children:TData[]

		local fieldNames:String[]
		fieldNames :+ ["currentAnimationName", "guid", "copyGuid"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
			if childNode.GetName().ToLower() = "spriteframeanimation"
				local childData:TData = new TData
				local childFieldNames:String[]
				childFieldNames :+ ["name", "flags"]
				childFieldNames :+ ["frames", "framesTime", "frameTimer"]
				childFieldNames :+ ["repeatTimes", "paused", "randomness"]
				childFieldNames :+ ["currentImageFrame", "currentFrame"]
				TXmlHelper.LoadValuesToData(childNode, childData, childFieldNames)
				children :+ [childData]
			endif
		Next
		if children.length > 0 then data.Add("animations", children)

		return data
	End Method


	Method LoadFromConfig:TSpriteFrameAnimationCollection(data:TData, resourceName:string)
		'only return collections, not single animations
		'indicate that the loading was successful
		local collection:TSpriteFrameAnimationCollection

		'try to copy an already existing collection
		if data.GetString("copyguid")
			'print "copying: " + data.GetString("copyguid")
			collection = GetSpriteFrameAnimationCollectionFromRegistry(data.GetString("copyGuid"))
			if collection then collection = collection.copy()
			'if not collection then print " ... failed"
		'add to registry to make it accessible for "copyGuild"
		elseif data.GetString("guid")
			collection = new TSpriteFrameAnimationCollection.InitFromData(data)
			GetRegistry().Set(data.GetString("guid"), collection)
		endif

		if not collection
			TLogger.log("TRegistrySpriteFrameAnimationLoader.LoadFromConfig()", "Failed to load collection from data set.", LOG_ERROR)
			return null
		endif

		return collection
	End Method
End Type


'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetSpriteFrameAnimationCollectionFromRegistry:TSpriteFrameAnimationCollection(name:string, defaultNameOrSpriteFrameAnimationCollection:object = Null)
	Return TSpriteFrameAnimationCollection( GetRegistry().Get(name, defaultNameOrSpriteFrameAnimationCollection, "spriteframeanimationcollection") )
End Function
