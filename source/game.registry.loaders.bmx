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
new TRegistryColorLoader.Init()
new TRegistryRoomLoader.Init()
new TRegistryNewsGenresLoader.Init()
new TRegistryProgrammeDataModsLoader.Init()



'===== COLOR LOADER =====
'loader caring about "<color>"-types (and "<colors>"-groups)
Type TRegistryColorLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "Color"
		'we also load each image as sprite
		resourceNames = "color|colors"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		'=== HANDLE "<COLORS>" ===
		if node.GetName().toLower() = "colors"
			Local listName:String = TXmlHelper.FindValue(node, "name", "colorList")

			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				if childNode.GetName().ToLower() <> "color" then continue

				local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				if not childData then continue

				'add listname to each configuration - if not done yet
				childData.AddString("list", childData.GetString("list", listName))

				'add each color to "ToLoad"-list
				local resName:string = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					new TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "color", childData)..
				)
			Next
			return Null
		endif

		'=== HANDLE "<COLOR>" ===
		local fieldNames:String[] = ["name", "r", "g", "b", "a", "list"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown color")
	End Method


	Method LoadFromConfig:TColor(data:TData, resourceName:string)
		Local listName:string = data.getString("list")
		Local name:String = data.GetString("name")
		Local r:Int	= data.GetInt("r", 0)
		Local g:Int	= data.GetInt("g", 0)
		Local b:Int	= data.GetInt("b", 0)
		Local a:Int	= data.GetFloat("a", 1.0)

		local color:TPlayerColor = TPlayerColor.Create(r,g,b,a)
		'if a listname was given - try to add to that group
		If listName <> ""
			local list:TList = TList(GetRegistry().Get(listName, null))
			'if list is not existing: create it
			if not list
				list = CreateList()
				GetRegistry().Set(listName, list)
			Endif
			'add
			list.addLast(color)
		EndIf
		'add the color as extra registry entry if name given
		'(special colors have names :D)
		If name <> "" Then GetRegistry().Set(name, color)

		'indicate that the loading was successful
		return color
	End Method
End Type




'===== ROOM LOADER =====
'loader caring about "<room>"-types (and "<rooms>"-groups)
Type TRegistryRoomLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "Room"
		'we also load each image as sprite
		resourceNames = "room|rooms"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		'=== HANDLE "<ROOMS>" ===
		if node.GetName().toLower() = "rooms"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				if childNode.GetName().ToLower() <> "room" then continue

				local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				if not childData then continue

				'add each room to "ToLoad"-list
				local resName:string = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					new TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "room", childData)..
				)
			Next
			return Null
		endif

		'=== HANDLE "<ROOM>" ===
		'steps:
		'	1. room configuration
		'	2. tooltips
		'	3. hotspots
		'	4. door
		Local subNode:TxmlNode = Null

		'1. room configuration
		local fieldNames:String[] = ["owner", "name", "id", "fake", "screen", "list"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)


		'2. load tooltips
		Local tooltipData:TData = new TData
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
			For Local hotSpotNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				'skip other elements
				if hotspotNode.GetName().ToLower() <> "hotspot" then continue

				Local hotspotData:TData = new TData
				local hotspotFields:string[]
				hotspotFields :+ ["name", "tooltiptext", "tooltipdescription"]
				hotspotFields :+ ["x", "y", "floor", "width", "height", "bottomy"]
				TXmlHelper.LoadValuesToData(hotspotNode, hotspotData, hotspotFields)

				'add hotspot data to list of hotspots
				hotSpots.addLast(hotspotData)
			Next
		EndIf
		'add hotspot list
		data.Add("hotspots", hotSpots)


		'4. load door settings
		subNode = TXmlHelper.FindChild(node, "door")
		local doorData:TData = new TData
		'this is the default value for rooms without doors
		doorData.Add("floor", "0")
		If subNode
			local doorFields:string[] = ["x", "floor", "doorslot", "doortype", "doorwidth", "doortooltip"]
			TXmlHelper.LoadValuesToData(subNode, doorData, doorFields)
		EndIf
		'add door configuration
		data.Add("door", doorData)


		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown room")
	End Method


	Method LoadFromConfig:TData(data:TData, resourceName:string)
		Local roomData:TData = new TData
		Local owner:Int	= data.GetInt("owner", -1)
		Local name:String = data.GetString("name", "unknown")
		Local id:String	= data.GetString("id", "")

		roomData.AddString("name",	name + owner)
		roomData.AddString("owner",	owner)
		roomData.AddString("roomname", name)
		roomData.AddString("fake", data.GetBool("fake", False))
		roomData.AddString("screen", data.GetString("screen", "screen_credits"))

		'load tooltips
		local tooltipData:TData = TData(data.Get("tooltip", new TData))
		roomData.AddString("tooltip", tooltipData.GetString("text"))
		roomData.AddString("tooltip2", tooltipData.GetString("description"))

		'load hotspots
		roomData.Add("hotspots", TList(data.Get("hotspots", CreateList())))

		local doorData:TData = TData(data.Get("door", new TData))
		'load door settings
		roomData.AddNumber("x", doorData.GetInt("x", -1000))
		roomData.AddNumber("floor",	 doorData.GetInt("floor", -1))
		roomData.AddNumber("doorslot", doorData.GetInt("doorslot", -1))
		roomData.AddNumber("doortype", doorData.GetInt("doortype", -1))
		roomData.AddNumber("doorwidth", doorData.GetInt("doorwidth", -1))
		roomData.AddBoolString("doortooltip", doorData.GetBool("doortooltip", True))

		'fetch/create the rooms config container
		local roomsMap:TMap = TMap(GetRegistry().Get("rooms"))
		if not roomsMap
			roomsMap = CreateMap()
			GetRegistry().Set("rooms", roomsMap)
		EndIf

		'add the room configuration to the container
		Local key:String = Name + owner + id
		roomsMap.Insert(key, roomData)
		'TLogger.log("XmlLoader.LoadRooms()", "inserted room: " + Name, LOG_LOADING | LOG_DEBUG, TRUE)

		'indicate that the loading was successful
		return roomData
	End Method
End Type




'===== NEWS GENRE LOADER =====
'loader caring about "<newsgenre>"-types (and "<newsgenres>"-groups)
Type TRegistryNewsGenresLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "Newsgenres"
		'we also load each image as sprite
		resourceNames = "newsgenre|newsgenres"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		'=== HANDLE "<NEWSGENRES>" ===
		if node.GetName().toLower() = "newsgenres"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				if childNode.GetName().ToLower() <> "newsgenre" then continue

				local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				if not childData then continue

				'add each entry to "ToLoad"-list
				local resName:string = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					new TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "newsgenre", childData)..
				)
			Next
			return Null
		endif

		'=== HANDLE "<NEWSGENRE>" ===
		local fieldNames:String[] = ["id", "name"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		Local subNode:TxmlNode = TXmlHelper.FindChild(node, "audienceAttractions")
		if not subNode then return Null

		local audienceAttractions:TMap = CreateMap()
		For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
			Local attrId:String = TXmlHelper.FindValue(subNodeChild, "id", "-1")
			Local men:String = TXmlHelper.FindValue(subNodeChild, "men", "")
			Local women:String = TXmlHelper.FindValue(subNodeChild, "women", "")
			local all:string  = TXmlHelper.FindValue(subNodeChild, "value", "0.7")
			if men = "" then men = all
			if women = "" then women = all
			audienceAttractions.Insert(attrId+"_men", men)
			audienceAttractions.Insert(attrId+"_women", women)
		Next
		'add attractions to data set
		data.Add("audienceAttractions", audienceAttractions)

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown newsgenre")
	End Method


	Method LoadFromConfig:TMap(data:TData, resourceName:string)
		local newsGenre:TMap = CreateMap()
		local id:int = data.GetInt("id", -1)
		newsGenre.Insert("id", string(id))
		newsGenre.Insert("name", data.GetString("name", "unknown"))

		local audienceAttractions:TMap = TMap(data.Get("audienceAttractions", CreateMap()))
		For local key:string = eachin audienceAttractions.Keys()
			newsGenre.Insert(key, AudienceAttractions.ValueForKey(key) )
		Next


		'fetch/create the newsgenres container
		local newsGenresMap:TMap = TMap(GetRegistry().Get("newsgenres"))
		if not newsGenresMap
			newsGenresMap = CreateMap()
			'add the genres container to the registry
			GetRegistry().Set("newsgenres", newsGenresMap)
		endif

		'add the newsgenre to the container
		newsGenresMap.Insert(string(id), newsGenre)

		'indicate that the loading was successful
		return newsGenre
	End Method
End Type




'===== (PROGRAMME) GENRE / FLAGS LOADER =====
'loader caring about:
'- <genres>, <genre>, <flags>, <flag>, <programmedatamods>
Type TRegistryProgrammeDataModsLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "ProgrammeDataMods"
		resourceNames = "programmedatamods|genre|genres|flag|flags"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		'=== HANDLE "<PROGRAMMEDATAMODS>" ===
		if node.GetName().toLower() = "programmedatamods"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				if childNode.GetName().ToLower() <> "genres" and childNode.GetName().ToLower() <> "flags" then continue

				GetConfigFromXML(loader, childNode)
			Next
		endif
		

		'=== HANDLE "<GENRES>" ===
		if node.GetName().toLower() = "genres" or node.GetName().toLower() = "flags"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				if childNode.GetName().ToLower() <> "genre" and childNode.GetName().ToLower() <> "flag" then continue

				local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				if not childData then continue

				'add each entry to "ToLoad"-list
				local resName:string = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					new TRegistryUnloadedResource.Init(GetNameFromConfig(childData), childNode.GetName().ToLower(), childData)..
				)
			Next
			return Null
		endif


		'=== HANDLE "<GENRE>" ===
		local fieldNames:String[] = ["id", "name"]
		fieldNames :+ ["outcomeMod|outcome-mod", "reviewMod|review-mod", "speedMod|speed-mod"]
		fieldNames :+ ["goodFollower", "badFollower"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)
		data.Add("nodeName", node.GetName().ToLower())

		Local subNode:TxmlNode

		'load timeMods
		subNode = TXmlHelper.FindChild(node, "timeMods")
		if not subNode then return Null

		local timeMods:TMap = CreateMap()
		For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
			Local time:String = TXmlHelper.FindValue(subNodeChild, "time", "-1")
			Local Value:String = TXmlHelper.FindValue(subNodeChild, "value", "")
			timeMods.Insert(time, value)
		Next
		'add timemods to data set
		data.Add("timeMods", timeMods)


		'load audienceAttractions
		subNode = TXmlHelper.FindChild(node, "audienceAttractions")
		if not subNode then return Null

		local audienceAttractions:TMap = CreateMap()
		For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
			Local attrId:String = TXmlHelper.FindValue(subNodeChild, "id", "-1")
			Local men:String = TXmlHelper.FindValue(subNodeChild, "men", "")
			Local women:String = TXmlHelper.FindValue(subNodeChild, "women", "")
			Local all:String = TXmlHelper.FindValue(subNodeChild, "value", "0.7")
			if men = "" then men = all
			if women = "" then women = all
			audienceAttractions.Insert(attrId+"_men", men)
			audienceAttractions.Insert(attrId+"_women", women)
		Next
		'add attractions to data set
		data.Add("audienceAttractions", audienceAttractions)


		'load castAttributes
		subNode = TXmlHelper.FindChild(node, "castAttributes")
		if subNode
			local castAttributes:TMap = null
			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				if not castAttributes then castAttributes = CreateMap()
				Local jobID:int = TVTProgrammePersonJob.GetByString(subNodeChild.GetName().ToLower())
				Local attributeID:int = TVTProgrammePersonAttribute.GetByString(TXmlHelper.FindValue(subNodeChild, "attribute", ""))
				Local value:String = TXmlHelper.FindValue(subNodeChild, "value", "1.0")

				if jobID = TVTProgrammePersonJob.UNKNOWN then continue
				if attributeID = TVTProgrammePersonAttribute.NONE then continue

				castAttributes.Insert(jobID+"_"+attributeID, value)
			Next
			'add attractions to data set
			if castAttributes then data.Add("castAttributes", castAttributes)
		endif



		'load focusPointPriorities
		subNode = TXmlHelper.FindChild(node, "focusPointPriorities")
		if subNode
			local focusPointPriorities:TMap = null
			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				if not focusPointPriorities then focusPointPriorities = CreateMap()
				Local focusPointID:int = TVTProductionFocus.GetByString(subNodeChild.GetName().ToLower())
				Local value:String = TXmlHelper.FindValue(subNodeChild, "value", "1.0")

				if focusPointID = TVTProductionFocus.NONE then continue

				focusPointPriorities.Insert(string(focusPointID), value)
			Next
			'add priorities to data set
			if focusPointPriorities then data.Add("focusPointPriorities", focusPointPriorities)
		endif

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		if data.GetString("nodeName") = "genre"
			return data.GetString("name","unknown programme genre mod")
		else
			return data.GetString("name","unknown programme flag mod")
		endif
	End Method


	Method LoadFromConfig:TMap(data:TData, resourceName:string)
		local programmeDataMod:TMap = CreateMap()
		local id:int = data.GetInt("id", -1)
		programmeDataMod.Insert("id", string(id))
		programmeDataMod.Insert("name", data.GetString("name", "unknown"))

		programmeDataMod.Insert("outcomeMod", data.GetString("outcomeMod", -1))
		programmeDataMod.Insert("reviewMod", data.GetString("reviewMod", -1))
		programmeDataMod.Insert("speedMod", data.GetString("speedMod", -1))

		If data.GetString("goodFollower") <> ""
			local followers:string[] = data.GetString("goodFollower").split(",")
			For local i:int = 0 until followers.length
				if int(followers[i]) = followers[i].trim() then continue
				local follower:int = TVTProgrammeGenre.GetByString(followers[i])
				if follower = TVTProgrammeGenre.UNDEFINED
					print "INVALID GOODFOLLOWER GENRE: "+followers[i]
				endif
				followers[i] = follower
			Next
			programmeDataMod.Insert("goodFollower", ListFromArray(followers))
		EndIf

		If data.GetString("badFollower") <> ""
			local followers:string[] = data.GetString("badFollower").split(",")
			For local i:int = 0 until followers.length
				if int(followers[i]) = followers[i].trim() then continue
				local follower:int = TVTProgrammeGenre.GetByString(followers[i])
				if follower = TVTProgrammeGenre.UNDEFINED
					print "INVALID BADFOLLOWER GENRE: "+followers[i]
				endif
				followers[i] = follower
			Next
			programmeDataMod.Insert("badFollower", ListFromArray(followers))
		EndIf

		local timeMods:TMap = TMap(data.Get("timeMods", CreateMap()))
		For local key:string = eachin timeMods.Keys()
			programmeDataMod.Insert("timeMod_" + key, timeMods.ValueForKey(key) )
		Next

		local audienceAttractions:TMap = TMap(data.Get("audienceAttractions", CreateMap()))
		For local key:string = eachin audienceAttractions.Keys()
			programmeDataMod.Insert(key, AudienceAttractions.ValueForKey(key) )
		Next


		'fetch/create the genres container
		local modMap:TMap

		if resourceName.ToLower() = "genre"
			modMap = TMap(GetRegistry().Get("genres"))
			if not modMap
				modMap = CreateMap()
				'add the genres container to the registry
				GetRegistry().Set("genres", modMap)
			endif
		elseif resourceName.ToLower() = "flag"
			modMap = TMap(GetRegistry().Get("flags"))
			if not modMap
				modMap = CreateMap()
				'add the genres container to the registry
				GetRegistry().Set("flags", modMap)
			endif
		endif

		'add the genre to the container
		modMap.Insert(string(id), programmeDataMod)

		'indicate that the loading was successful
		return programmeDataMod
	End Method
End Type
