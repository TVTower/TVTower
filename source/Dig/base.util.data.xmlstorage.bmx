Rem
	====================================================================
	Data container xml storage
	====================================================================

	Class to store/retrieve TData-objects from and to xml files.
	

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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
Import "base.util.data.bmx"
Import "base.util.xmlhelper.bmx"
Import "base.util.time.bmx" 'to save savetime in file



Type TDataXmlStorage
	'defines which key->value pairs have to get ignored during
	'saving (avoids saving "secret" keys) 
	Field ignoreKeysStartingWith:string = "DEV_"
	'the tag to use to save the data
	'eg. "config" results in: <config><key /><key2 /></config>
	Field rootNodeKey:TLowerString = TLowerString.Create("data")


	Method Load:TData(file:string)
		local helper:TXmlHelper = TXmlHelper.Create(file)
		local configNode:TXmlNode = helper.FindElementNodeLS(null, rootNodeKey)
		'if no configuration was found, return null (not a new TData)
		if not configNode then return null

		local result:TData = new TData
		_LoadValueFromXml(helper, configNode, result)
		return result
	End Method


	'overwrites a storage or creates a new one
	Method Save:int(file:string, settingsData:TData)
		'make sure we get a new file
		deleteFile(file)
		local helper:TXmlHelper = TXmlHelper.Create(file, rootNodeKey.orig)

		helper.GetRootNode().SetAttribute("saved", Time.GetSystemTime("%d.%m.%Y %H:%M"))

		'kick off the recursive saving
		_SaveValueToXml(helper, null, rootNodeKey, settingsData, 0)

		helper.xmlDoc.saveFile(file)
	End Method


	'loads key->value into the given data-variable
	Method _LoadValueFromXml:int(xmlHelper:TXmlHelper, startingNode:TXmlNode = null, data:TData var)
		local key:String
		local value:object

		'loop through children of node
		For local node:TXmlNode = eachin xmlHelper.GetNodeChildElements(startingNode)
			key = node.GetName()

			If xmlHelper.GetNodeChildElements(node).Count() > 0
				local subData:TData = new TData
				_LoadValueFromXml(xmlHelper, node, subData)
				value = subData
			Else
				If xmlHelper.HasAttribute(node, "value")
					value = xmlHelper.GetAttribute(node, "value")
				Else
					value = node.getContent()
				EndIf
			EndIf
			data.Add(key, value)
		Next
	End Method
	

	Method _SaveValueToXml:int(xmlHelper:TXmlHelper, startingNode:TXmlNode = null, key:TLowerString, value:object, indentionLevel:int = 0)
		'skip nulled data
		if not value then return False

		'set to root node if none was given
		if not startingNode then startingNode = xmlHelper.GetRootNode()
		if not startingNode then return False

		'check if node exists already, if not create it (if  allowed)
		local node:TXmlNode = xmlHelper.FindElementNodeLS(startingNode, key)
		if not node
			'skip entry if the key starts with a forbidden phrase
			'-> eg. to skip writing "Default-Dev-Values" to user settings
			if ignoreKeysStartingWith <> ""
				'if key.toLower().find(ignoreKeysStartingWith.toLower()) = 0 then return False
				if key.StartsWithLower(ignoreKeysStartingWith) then return False
			endif
			
			'add indention
			For local i:int = 0 until indentionLevel
				startingNode.addContent("~t")
			Next
			'add node
			node = startingNode.addChild(key.orig)
			'add newline
			startingNode.addContent("~n")
		endif

		'for data blocks call function recursively to fill in the data
		if TData(value)
			'add newline
			node.addContent("~n")
			For local childKey:TLowerString = eachin TData(value).data.Keys()
				_SaveValueToXml(xmlHelper, node, childKey, TData(value).data.ValueForKey(childKey), indentionLevel + 1)
			Next
			'add indention
			For local i:int = 0 until indentionLevel
				node.addContent("~t")
			Next
			Return True
		endif

		'try to replace the existing value (or attribute)
		'by default everything is stored as <key value="x" /> except TData
		local writeAttribute:int = True
		'if there is already content (eg. text) then overwrite this
		if node.GetContent() <> "" then writeAttribute = False
		'data blocks have to get written as content
		if TData(value) then writeAttribute = False
		
		if writeAttribute
			if TDoubleData(value)
				if TDoubleData(value).value = int(TDoubleData(value).value)
					xmlHelper.FindElementNodeLS(node, key).setAttribute("value", int(TDoubleData(value).value))
				elseif TDoubleData(value).value = long(TDoubleData(value).value)
					xmlHelper.FindElementNodeLS(node, key).setAttribute("value", long(TDoubleData(value).value))
				else
					xmlHelper.FindElementNodeLS(node, key).setAttribute("value", TDoubleData(value).value)
				endif
			else
				xmlHelper.FindElementNodeLS(node, key).setAttribute("value", string(value))
			endif
		else
			xmlHelper.FindElementNodeLS(node, key).setContent(string(value))
		endif
	End Method


	Method SetRootNodeKey:int(key:object)
		if TLowerString(key) then
			rootNodeKey = TLowerString(key)
		else
			rootNodeKey = TLowerString.Create(String(key))
		end if
	End Method


	Method SetIgnoreKeysStartingWith(keyStart:string)
		ignoreKeysStartingWith = keyStart
	End Method
End Type
