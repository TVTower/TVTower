Rem
	===========================================================
	GUI Input box
	===========================================================

	Code contains multiple loaders for objects configured in xml.

	The code seems to do more than needed (loading config and in
	another step add this config to the registry) but this is done
	to add the ability to load from other sources than XML.
End Rem
SuperStrict
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.color.bmx"
Import "game.gameconstants.bmx"
Import "game.player.color.bmx"

'register the loaders
New TRegistryColorLoader.Init()
New TRegistryRoomLoader.Init()
New TRegistryNewsGenresLoader.Init()
New TRegistryProgrammeDataModsLoader.Init()



'===== COLOR LOADER =====
'loader caring about "<color>"-types (and "<colors>"-groups)
Type TRegistryColorLoader Extends TRegistryBaseLoader
	Method Init:Int()
		name = "Color"
		'we also load each image as sprite
		resourceNames = "color|colors"
		If Not registered Then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local data:TData = New TData

		'=== HANDLE "<COLORS>" ===
		If node.GetName().toLower() = "colors"
			Local listName:String = TXmlHelper.FindValue(node, "name", "colorList")

			Local childNode:TxmlNode = TxmlNode(node.GetFirstChild())
			While childNode
				'skip other elements than color
				If Not TXmlHelper.AsciiNamesLCAreEqual("color", childNode.GetName())
					childNode = childNode.NextSibling()
					Continue
				EndIf

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData
					childNode = childNode.NextSibling()
					Continue
				EndIf

				'add listname to each configuration - if not done yet
				childData.AddString("list", childData.GetString("list", listName))

				'add each color to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(resName, "color", childData)..
				)
				
				childNode = childNode.NextSibling()
			Wend
			Return Null
		EndIf

		'=== HANDLE "<COLOR>" ===
		Local fieldNames:String[] = ["name", "r", "g", "b", "a", "list"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		Return data.GetString("name","unknown color")
	End Method


	Method LoadFromConfig:TColor(data:TData, resourceName:String)
		Local listName:String = data.getString("list")
		Local name:String = data.GetString("name")
		Local r:Int	= data.GetInt("r", 0)
		Local g:Int	= data.GetInt("g", 0)
		Local b:Int	= data.GetInt("b", 0)
		Local a:Int	= data.GetFloat("a", 1.0)

		Local color:TColor = TColor.Create(r,g,b,a)
		'if a listname was given - try to add to that group
		If listName <> ""
			Local list:TList = TList(GetRegistry().Get(listName))
			'if list is not existing: create it
			If Not list
				list = CreateList()
				GetRegistry().Set(listName, list)
			EndIf
			'add
			list.addLast(color)

			'add the color as extra registry entry if name given
			'(special colors have names :D)
			If name <> "" Then GetRegistry().Set(listName+"::"+name, color)
		Else
			'add the color as extra registry entry if name given
			'(special colors have names :D)
			If name <> "" Then GetRegistry().Set(name, color)
		EndIf

		'indicate that the loading was successful
		Return color
	End Method
End Type




'===== ROOM LOADER =====
'loader caring about "<room>"-types (and "<rooms>"-groups)
Type TRegistryRoomLoader Extends TRegistryBaseLoader
	Method Init:Int()
		name = "Room"
		'we also load each image as sprite
		resourceNames = "room|rooms"
		If Not registered Then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local data:TData = New TData

		'=== HANDLE "<ROOMS>" ===
		If TXmlHelper.AsciiNamesLCAreEqual("rooms", node.GetName())
			Local childNode:TxmlNode = TxmlNode(node.GetFirstChild())
			While childNode
				'skip other elements than "room"
				If Not TXmlHelper.AsciiNamesLCAreEqual("room", childNode.GetName())
					childNode = childNode.NextSibling()
					Continue
				EndIf

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData
					childNode = childNode.NextSibling()
					Continue
				EndIf

				'add each room to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "room", childData)..
				)

				childNode = childNode.NextSibling()
			Wend
			Return Null
		EndIf

		'=== HANDLE "<ROOM>" ===
		'steps:
		'	1. room configuration
		'	2. tooltips
		'	3. hotspots
		'	4. door
		Local subNode:TxmlNode = Null

		'1. room configuration
		Local fieldNames:String[] = ["owner", "name", "id", "flags", "size", "screen"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)


		'2. load tooltips
		Local tooltipData:TData = New TData
		subNode = TXmlHelper.FindChild(node, "tooltip")
		If subNode
			TXmlHelper.LoadValuesToData(subNode, tooltipData, ["text", "description"])
		Else
			tooltipData.AddString("text", "").AddString("description", "")
		EndIf
		data.Add("tooltip", tooltipData)


		'3. load hotspots
		Local hotSpots:TList = CreateList()
		subNode = TXmlHelper.FindChild(node, "hotspots")

		If subNode
			Local hotSpotNode:TxmlNode = TxmlNode(subNode.GetFirstChild())
			While hotSpotNode
				'skip other elements than "hotspot"
				If Not TXmlHelper.AsciiNamesLCAreEqual("hotspot", hotspotNode.GetName())
					hotSpotNode = hotSpotnode.NextSibling()
					Continue
				EndIf

				Local hotspotData:TData = New TData
				Local hotspotFields:String[]
				hotspotFields :+ ["name", "tooltiptext", "tooltipdescription"]
				hotspotFields :+ ["x", "y", "floor", "width", "height", "bottomy"]
				TXmlHelper.LoadValuesToData(hotspotNode, hotspotData, hotspotFields)

				'add hotspot data to list of hotspots
				hotSpots.addLast(hotspotData)

				hotSpotNode = hotSpotnode.NextSibling()
			Wend
		EndIf
		'add hotspot list
		data.Add("hotspots", hotSpots)


		'4. load door(s) settings
		Local doorsList:TObjectList = New TObjectList
		data.Add("doors", doorsList)

		Local doorNode:TxmlNode = TxmlNode(node.GetFirstChild())
		While doorNode
			'skip other elements than "door"
			If Not TXmlHelper.AsciiNamesLCAreEqual("door", doorNode.GetName())
				doorNode = doorNode.NextSibling()
				Continue
			EndIf

			Local doorData:TData = New TData
			Local doorFields:String[] = ["x", "floor", "doorslot", "doortype", "doorwidth", "doorheight", "doorstopoffset", "flags"]
			TXmlHelper.LoadValuesToData(doorNode, doorData, doorFields)
			'add door configuration
			doorsList.AddLast(doorData)

			doorNode = doorNode.NextSibling()
		Wend

		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		Return data.GetString("name","unknown room")
	End Method


	Method LoadFromConfig:TData(data:TData, resourceName:String)
		Local roomData:TData = New TData
		Local owner:Int	= data.GetInt("owner", -1)
		Local name:String = data.GetString("name", "unknown")
		Local roomUID:Int	= data.GetInt("roomUID", -1)

		roomData.AddString("name",	name + owner)
		roomData.AddString("owner",	owner)
		roomData.AddString("roomname", name)
		roomData.AddNumber("flags", data.GetInt("flags", 0))
		roomData.AddNumber("size", data.GetInt("size", 1))
		roomData.AddString("screen", data.GetString("screen", "screen_credits"))

		'load tooltips
		Local tooltipData:TData = TData(data.Get("tooltip", New TData))
		roomData.AddString("tooltip", tooltipData.GetString("text"))
		roomData.AddString("tooltip2", tooltipData.GetString("description"))

		'load hotspots
		roomData.Add("hotspots", TList(data.Get("hotspots", CreateList())))

		Local doorFloor:Int = -1
		Local doorX:Int = -1000
		Local doorCount:Int = 0
		Local doorsList:TObjectList = TObjectList(data.Get("doors"))
		If doorsList
			Local roomDataDoorsList:TObjectList
			For local doorData:TData = EachIn doorsList
				doorCount :+ 1

				'config has at least one door 
				If Not roomDataDoorsList
					roomDataDoorsList = new TObjectList
					roomData.Add("doors", roomDataDoorsList)
				EndIf

				'load door settings
				'here you can override / boundary check values
				'(for multiple doors the last door defines floor and x)
				doorFloor = doorData.GetInt("floor", -1)
				doorX = doorData.GetInt("x", -1000)

				Local roomDataDoorData:TData = new TData
				roomDataDoorData.AddInt("x", doorX)
				roomDataDoorData.AddInt("width", doorData.GetInt("doorwidth", -1))
				roomDataDoorData.AddInt("height", doorData.GetInt("doorheight", -1))
				roomDataDoorData.AddInt("onFloor", doorFloor)
				roomDataDoorData.AddInt("doorSlot", doorData.GetInt("doorslot", -1))
				roomDataDoorData.AddInt("doorType", doorData.GetInt("doortype", -1))
				roomDataDoorData.AddInt("stopOffset", doorData.GetInt("doorstopoffset", 0))
				roomDataDoorData.AddInt("doorFlags", doorData.GetInt("flags", 0))

				roomDataDoorsList.AddLast(roomDataDoorData)
			Next
		EndIf

		'fetch/create the rooms config container
		Local roomsMap:TMap = TMap(GetRegistry().Get("rooms"))
		If Not roomsMap
			roomsMap = CreateMap()
			GetRegistry().Set("rooms", roomsMap)
		EndIf

		'add the room configuration to the container
		Local key:String = Name + "_" + owner + "_" + doorX + "_" + doorFloor + "_" + roomUID
		roomsMap.Insert(key, roomData)
		'TLogger.log("XmlLoader.LoadRooms()", "inserted room=" + Name + "  key=" + key + "  doors=" + doorCount + "." , LOG_LOADING | LOG_DEBUG, TRUE)

		'indicate that the loading was successful
		Return roomData
	End Method
End Type




'===== NEWS GENRE LOADER =====
'loader caring about "<newsgenre>"-types (and "<newsgenres>"-groups)
Type TRegistryNewsGenresLoader Extends TRegistryBaseLoader
	Method Init:Int()
		name = "Newsgenres"
		'we also load each image as sprite
		resourceNames = "newsgenre|newsgenres"
		If Not registered Then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local data:TData = New TData

		'=== HANDLE "<NEWSGENRES>" ===
		If TXmlHelper.AsciiNamesLCAreEqual("newsgenres", node.GetName())
			Local childNode:TxmlNode = TxmlNode(node.GetFirstChild())
			While childNode
				'skip other elements than "newsgenre"
				If Not TXmlHelper.AsciiNamesLCAreEqual("newsgenre", childNode.GetName())
					childNode = childNode.NextSibling()
					Continue
				EndIf

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData 
					childNode = childNode.NextSibling()
					Continue
				EndIf

				'add each entry to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "newsgenre", childData)..
				)

				childNode = childNode.NextSibling()
			Wend
			Return Null
		EndIf

		'=== HANDLE "<NEWSGENRE>" ===
		Local fieldNames:String[] = ["id", "name"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		Local subNode:TxmlNode = TXmlHelper.FindChild(node, "audienceAttractions")
		If Not subNode Then Return Null


		Local audienceAttractions:TMap = CreateMap()
		Local subNodeChild:TxmlNode = TxmlNode(subNode.GetFirstChild())
		While subNodeChild
			Local attrId:String = TXmlHelper.FindValue(subNodeChild, "id", "-1")
			Local men:String = TXmlHelper.FindValue(subNodeChild, "men", "")
			Local women:String = TXmlHelper.FindValue(subNodeChild, "women", "")
			Local all:String  = TXmlHelper.FindValue(subNodeChild, "value", "0.7")
			If men = "" Then men = all
			If women = "" Then women = all
			audienceAttractions.Insert(attrId+"_men", men)
			audienceAttractions.Insert(attrId+"_women", women)
			
			subNodeChild = subNodeChild.NextSibling()
		Wend
		'add attractions to data set
		data.Add("audienceAttractions", audienceAttractions)

		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		Return data.GetString("name","unknown newsgenre")
	End Method


	Method LoadFromConfig:TMap(data:TData, resourceName:String)
		Local newsGenre:TMap = CreateMap()
		Local id:Int = data.GetInt("id", -1)
		newsGenre.Insert("id", String(id))
		newsGenre.Insert("name", data.GetString("name", "unknown"))

		Local audienceAttractions:TMap = TMap(data.Get("audienceAttractions", CreateMap()))
		For Local key:String = EachIn audienceAttractions.Keys()
			newsGenre.Insert(key, AudienceAttractions.ValueForKey(key) )
		Next


		'fetch/create the newsgenres container
		Local newsGenresMap:TMap = TMap(GetRegistry().Get("newsgenres"))
		If Not newsGenresMap
			newsGenresMap = CreateMap()
			'add the genres container to the registry
			GetRegistry().Set("newsgenres", newsGenresMap)
		EndIf

		'add the newsgenre to the container
		newsGenresMap.Insert(String(id), newsGenre)

		'indicate that the loading was successful
		Return newsGenre
	End Method
End Type




'===== (PROGRAMME) GENRE / FLAGS LOADER =====
'loader caring about:
'- <genres>, <genre>, <flags>, <flag>, <programmedatamods>
Type TRegistryProgrammeDataModsLoader Extends TRegistryBaseLoader
	Method Init:Int()
		name = "ProgrammeDataMods"
		resourceNames = "programmedatamods|genre|genres|flag|flags"
		If Not registered Then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local data:TData = New TData

		'=== HANDLE "<PROGRAMMEDATAMODS>" ===
		If TXmlHelper.AsciiNamesLCAreEqual("programmedatamods", node.GetName())
			Local childNode:TxmlNode = TxmlNode(node.GetFirstChild())
			While childNode
				'skip other elements than "genres" or "flags" (plural)
				Local childNodeName:String = childNode.GetName()
				If Not TXmlHelper.AsciiNamesLCAreEqual("genres", childNodeName) and ..
				   Not TXmlHelper.AsciiNamesLCAreEqual("flags", childNodeName)
					childNode = childNode.NextSibling()
					Continue
				EndIf

				GetConfigFromXML(loader, childNode)

				childNode = childNode.NextSibling()
			Wend
		EndIf
		

		'=== HANDLE "<GENRES>" ===
		Local nodeName:String = node.GetName()
		If TXmlHelper.AsciiNamesLCAreEqual("genres", nodeName) Or ..
		   TXmlHelper.AsciiNamesLCAreEqual("flags", nodeName)
			Local childNode:TxmlNode = TxmlNode(node.GetFirstChild())
			While childNode
				'skip other elements than "genre" or "flag" (singular)
				Local childNodeName:String = childNode.GetName()
				If Not TXmlHelper.AsciiNamesLCAreEqual("genre", childNodeName) and ..
				   Not TXmlHelper.AsciiNamesLCAreEqual("flag", childNodeName)
					childNode = childNode.NextSibling()
					Continue
				EndIf

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData
					childNode = childNode.NextSibling()
					Continue
				EndIf

				If TXmlHelper.AsciiNamesLCAreEqual("genre", childNodeName)
					Local genreId:Int=childData.GetInt("id",-1)
					If genreId < 0 Then HandleError("missing genre id")
					If genreId > 0
						Local genre:String = childData.getString("name","*")
						If TVTProgrammeGenre.GetByString(genre) <> genreId Then HandleError("wrong genre name " + genre)
					EndIf
				EndIf

				'add each entry to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(resName, childNode.GetName().ToLower(), childData)..
				)
				
				childNode = childNode.NextSibling()
			Wend
			Return Null
		EndIf


		'=== HANDLE "<GENRE>" ===
		Local fieldNames:String[] = [..
			"id", "name", ..
			"outcomeMod|outcome-mod", "reviewMod|review-mod", "speedMod|speed-mod", "refreshMod|refresh-mod", "wearoffMod|wearoff-mod", ..
			"goodFollower", "badFollower" ..
			]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)
		data.Add("nodeName", node.GetName().ToLower())

		Local subNode:TxmlNode

		'load timeMods
		subNode = TXmlHelper.FindChild(node, "timeMods")
		If Not subNode Then Return Null

		Local timeMods:TMap = CreateMap()
		Local subNodeChild:TxmlNode = TxmlNode(subNode.GetFirstChild())
		While subNodeChild
			Local time:String = TXmlHelper.FindValue(subNodeChild, "time", "-1")
			Local Value:String = TXmlHelper.FindValue(subNodeChild, "value", "")
			timeMods.Insert(time, value)
			
			subNodeChild = subNodeChild.NextSibling()
		Wend
		'add timemods to data set
		data.Add("timeMods", timeMods)


		'load audienceAttractions
		subNode = TXmlHelper.FindChild(node, "audienceattractions")
		If Not subNode Then Return Null

		Local audienceAttractions:TMap = CreateMap()
		subNodeChild = TxmlNode(subNode.GetFirstChild())
		While subNodeChild
			Local attrId:String = TXmlHelper.FindValue(subNodeChild, "id", "-1")
			If TVTTargetGroup.GetByString(attrId) = TVTTargetGroup.ALL
				HandleError("unknown audienceAttraction group "+ attrId)
			EndIf
			Local men:String = TXmlHelper.FindValue(subNodeChild, "men", "")
			Local women:String = TXmlHelper.FindValue(subNodeChild, "women", "")
			Local all:String = TXmlHelper.FindValue(subNodeChild, "value", "0.7")
			If men = "" Then men = all
			If women = "" Then women = all
			audienceAttractions.Insert(attrId+"_men", men)
			audienceAttractions.Insert(attrId+"_women", women)
			
			subNodeChild = subNodeChild.NextSibling()
		Wend
		'add attractions to data set
		data.Add("audienceAttractions", audienceAttractions)


		'load castAttributes
		subNode = TXmlHelper.FindChild(node, "castattributes")
		If subNode
			Local castAttributes:TMap = Null
			subNodeChild = TxmlNode(subNode.GetFirstChild())
			While subNodeChild
				If Not castAttributes Then castAttributes = CreateMap()
				Local jobName:String = subNodeChild.GetName()
				Local jobID:Int = TVTPersonJob.GetByString(jobName.ToLower())
				'appearance, charisma,...
				Local attributeName:String = TXmlHelper.FindValue(subNodeChild, "attribute", "")
				Local attributeID:Int = TVTPersonPersonalityAttribute.GetByString(attributeName)
				Local value:String = TXmlHelper.FindValue(subNodeChild, "value", "0.0")

				If jobID = TVTPersonJob.UNKNOWN
					HandleError("unknown job for castAttributes: "+ jobName)
				EndIf 
				If attributeID = TVTPersonPersonalityAttribute.NONE
					HandleError("unknown attribute for castAttributes: "+ attributeName)
				EndIf

				'limit values to -1.0 - +1.0
				value = String( MathHelper.Clamp(Float(value), -1.0 , 1.0) )

				castAttributes.Insert(jobID+"_"+attributeID, value)

				subNodeChild = subNodeChild.NextSibling()
			Wend
			'add attractions to data set
			If castAttributes Then data.Add("castAttributes", castAttributes)
		EndIf



		'load focusPointPriorities
		subNode = TXmlHelper.FindChild(node, "focuspointpriorities")
		If subNode
			Local focusPointPriorities:TMap = Null
			Local subNodeChild:TxmlNode = TxmlNode(subNode.GetFirstChild())
			While subNodeChild
				Local focusPointName:String = subNodeChild.GetName()
				Local focusPointID:Int = TVTProductionFocus.GetByString(focusPointName)
				'TODO no clamping of value!?
				Local value:String = TXmlHelper.FindValue(subNodeChild, "value", "1.0")
				
				If focusPointID = TVTProductionFocus.NONE
					HandleError("unknown focuspoint: "+ focusPointName)
				EndIf

				If Not focusPointPriorities Then focusPointPriorities = CreateMap()
				focusPointPriorities.Insert(String(focusPointID), value)
				
				subNodeChild = subNodeChild.NextSibling()
			Wend
			'add priorities to data set
			If focusPointPriorities Then data.Add("focusPointPriorities", focusPointPriorities)
		EndIf

		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		If data.GetString("nodeName") = "genre"
			Return data.GetString("name","unknown programme genre mod")
		Else
			Return data.GetString("name","unknown programme flag mod")
		EndIf
	End Method


	Method LoadFromConfig:TMap(data:TData, resourceName:String)
		Local programmeDataMod:TMap = CreateMap()
		Local id:Int = data.GetInt("id", -1)
		programmeDataMod.Insert("id", String(id))
		programmeDataMod.Insert("name", data.GetString("name", "unknown"))

		programmeDataMod.Insert("outcomeMod", data.GetString("outcomeMod", -1))
		programmeDataMod.Insert("reviewMod", data.GetString("reviewMod", -1))
		programmeDataMod.Insert("speedMod", data.GetString("speedMod", -1))
		programmeDataMod.Insert("refreshMod", data.GetString("refreshMod", -1))
		programmeDataMod.Insert("wearoffMod", data.GetString("wearoffMod", -1))

		programmeDataMod.Insert("castAttributes", data.Get("castAttributes"))
		programmeDataMod.Insert("focusPointPriorities", data.Get("focusPointPriorities"))

		If data.GetString("goodFollower") <> ""
			Local followers:String[] = data.GetString("goodFollower").split(",")
			For Local i:Int = 0 Until followers.length
				If Int(followers[i]) = followers[i].Trim() Then Continue
				Local follower:Int = TVTProgrammeGenre.GetByString(followers[i])
				If follower = TVTProgrammeGenre.UNDEFINED
					HandleError("invalid good follower: "+followers[i])
				EndIf
				followers[i] = follower
			Next
			programmeDataMod.Insert("goodFollower", ListFromArray(followers))
		EndIf

		If data.GetString("badFollower") <> ""
			Local followers:String[] = data.GetString("badFollower").split(",")
			For Local i:Int = 0 Until followers.length
				If Int(followers[i]) = followers[i].Trim() Then Continue
				Local follower:Int = TVTProgrammeGenre.GetByString(followers[i])
				If follower = TVTProgrammeGenre.UNDEFINED
					HandleError("invalid bad follower: "+followers[i])
				EndIf
				followers[i] = follower
			Next
			programmeDataMod.Insert("badFollower", ListFromArray(followers))
		EndIf

		Local timeMods:TMap = TMap(data.Get("timeMods", CreateMap()))
		For Local key:String = EachIn timeMods.Keys()
			programmeDataMod.Insert("timeMod_" + key, timeMods.ValueForKey(key) )
		Next


		Local audienceAttractions:TMap = TMap(data.Get("audienceAttractions", New TMap))
		For Local key:String = EachIn audienceAttractions.Keys()
			programmeDataMod.Insert(key, AudienceAttractions.ValueForKey(key) )
		Next


		'fetch/create the genres container
		Local modMap:TMap

		If resourceName.ToLower() = "genre"
			modMap = TMap(GetRegistry().Get("genres"))
			If Not modMap
				modMap = CreateMap()
				'add the genres container to the registry
				GetRegistry().Set("genres", modMap)
			EndIf
		ElseIf resourceName.ToLower() = "flag"
			modMap = TMap(GetRegistry().Get("flags"))
			If Not modMap
				modMap = CreateMap()
				'add the genres container to the registry
				GetRegistry().Set("flags", modMap)
			EndIf
		EndIf

		'add the genre to the container
		modMap.Insert(String(id), programmeDataMod)

		'indicate that the loading was successful
		Return programmeDataMod
	End Method

	Function HandleError(message:String)
		'throw "TRegistryProgrammeDataModsLoader: " + message
		TLogger.log("TRegistryProgrammeDataModsLoader", message , LOG_LOADING | LOG_ERROR, TRUE)
	EndFunction
End Type
