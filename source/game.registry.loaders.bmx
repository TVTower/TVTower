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

			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				If childNode.GetName().ToLower() <> "color" Then Continue

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData Then Continue

				'add listname to each configuration - if not done yet
				childData.AddString("list", childData.GetString("list", listName))

				'add each color to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "color", childData)..
				)
			Next
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

		Local color:TPlayerColor = TPlayerColor.Create(r,g,b,a)
		'if a listname was given - try to add to that group
		If listName <> ""
			Local list:TList = TList(GetRegistry().Get(listName, Null))
			'if list is not existing: create it
			If Not list
				list = CreateList()
				GetRegistry().Set(listName, list)
			EndIf
			'add
			list.addLast(color)
		EndIf
		'add the color as extra registry entry if name given
		'(special colors have names :D)
		If name <> "" Then GetRegistry().Set(name, color)

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
		If node.GetName().toLower() = "rooms"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				If childNode.GetName().ToLower() <> "room" Then Continue

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData Then Continue

				'add each room to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "room", childData)..
				)
			Next
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
			For Local hotSpotNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				'skip other elements
				If hotspotNode.GetName().ToLower() <> "hotspot" Then Continue

				Local hotspotData:TData = New TData
				Local hotspotFields:String[]
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
		If subNode
			Local doorData:TData = New TData
			Local doorFields:String[] = ["x", "floor", "doorslot", "doortype", "doorwidth", "doortooltip"]
			TXmlHelper.LoadValuesToData(subNode, doorData, doorFields)
			'add door configuration
			data.Add("door", doorData)
		EndIf


		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		Return data.GetString("name","unknown room")
	End Method


	Method LoadFromConfig:TData(data:TData, resourceName:String)
		Local roomData:TData = New TData
		Local owner:Int	= data.GetInt("owner", -1)
		Local name:String = data.GetString("name", "unknown")
		Local id:String	= data.GetString("id", "")

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

		Local doorData:TData = TData(data.Get("door"))
		If doorData
			roomData.AddNumber("hasDoorData", True)
			'load door settings
			roomData.AddNumber("x", doorData.GetInt("x", -1000))
			roomData.AddNumber("floor",	 doorData.GetInt("floor", -1))
			roomData.AddNumber("doorslot", doorData.GetInt("doorslot", -1))
			roomData.AddNumber("doortype", doorData.GetInt("doortype", -1))
			roomData.AddNumber("doorwidth", doorData.GetInt("doorwidth", -1))
			roomData.AddBoolString("doortooltip", doorData.GetBool("doortooltip", True))
		Else
			roomData.AddNumber("hasDoorData", False)
		EndIf

		'fetch/create the rooms config container
		Local roomsMap:TMap = TMap(GetRegistry().Get("rooms"))
		If Not roomsMap
			roomsMap = CreateMap()
			GetRegistry().Set("rooms", roomsMap)
		EndIf

		'add the room configuration to the container
		Local key:String = Name + owner + id
		roomsMap.Insert(key, roomData)
		'TLogger.log("XmlLoader.LoadRooms()", "inserted room: " + Name, LOG_LOADING | LOG_DEBUG, TRUE)

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
		If node.GetName().toLower() = "newsgenres"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				If childNode.GetName().ToLower() <> "newsgenre" Then Continue

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData Then Continue

				'add each entry to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(GetNameFromConfig(childData), "newsgenre", childData)..
				)
			Next
			Return Null
		EndIf

		'=== HANDLE "<NEWSGENRE>" ===
		Local fieldNames:String[] = ["id", "name"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		Local subNode:TxmlNode = TXmlHelper.FindChild(node, "audienceAttractions")
		If Not subNode Then Return Null

		Local audienceAttractions:TMap = CreateMap()
		For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
			Local attrId:String = TXmlHelper.FindValue(subNodeChild, "id", "-1")
			Local men:String = TXmlHelper.FindValue(subNodeChild, "men", "")
			Local women:String = TXmlHelper.FindValue(subNodeChild, "women", "")
			Local all:String  = TXmlHelper.FindValue(subNodeChild, "value", "0.7")
			If men = "" Then men = all
			If women = "" Then women = all
			audienceAttractions.Insert(attrId+"_men", men)
			audienceAttractions.Insert(attrId+"_women", women)
		Next
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
		If node.GetName().toLower() = "programmedatamods"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				If childNode.GetName().ToLower() <> "genres" And childNode.GetName().ToLower() <> "flags" Then Continue

				GetConfigFromXML(loader, childNode)
			Next
		EndIf
		

		'=== HANDLE "<GENRES>" ===
		If node.GetName().toLower() = "genres" Or node.GetName().toLower() = "flags"
			For Local childNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
				'skip other elements
				If childNode.GetName().ToLower() <> "genre" And childNode.GetName().ToLower() <> "flag" Then Continue

				Local childData:TData = GetConfigFromXML(loader, childNode)
				'skip invalid configurations
				If Not childData Then Continue

				'add each entry to "ToLoad"-list
				Local resName:String = GetNameFromConfig(childData)
				TRegistryUnloadedResourceCollection.GetInstance().Add(..
					New TRegistryUnloadedResource.Init(GetNameFromConfig(childData), childNode.GetName().ToLower(), childData)..
				)
			Next
			Return Null
		EndIf


		'=== HANDLE "<GENRE>" ===
		Local fieldNames:String[] = ["id", "name"]
		fieldNames :+ ["outcomeMod|outcome-mod", "reviewMod|review-mod", "speedMod|speed-mod"]
		fieldNames :+ ["goodFollower", "badFollower"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)
		data.Add("nodeName", node.GetName().ToLower())

		Local subNode:TxmlNode

		'load timeMods
		subNode = TXmlHelper.FindChild(node, "timeMods")
		If Not subNode Then Return Null

		Local timeMods:TMap = CreateMap()
		For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
			Local time:String = TXmlHelper.FindValue(subNodeChild, "time", "-1")
			Local Value:String = TXmlHelper.FindValue(subNodeChild, "value", "")
			timeMods.Insert(time, value)
		Next
		'add timemods to data set
		data.Add("timeMods", timeMods)


		'load audienceAttractions
		subNode = TXmlHelper.FindChild(node, "audienceAttractions")
		If Not subNode Then Return Null

		Local audienceAttractions:TMap = CreateMap()
		For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
			Local attrId:String = TXmlHelper.FindValue(subNodeChild, "id", "-1")
			Local men:String = TXmlHelper.FindValue(subNodeChild, "men", "")
			Local women:String = TXmlHelper.FindValue(subNodeChild, "women", "")
			Local all:String = TXmlHelper.FindValue(subNodeChild, "value", "0.7")
			If men = "" Then men = all
			If women = "" Then women = all
			audienceAttractions.Insert(attrId+"_men", men)
			audienceAttractions.Insert(attrId+"_women", women)
		Next
		'add attractions to data set
		data.Add("audienceAttractions", audienceAttractions)


		'load castAttributes
		subNode = TXmlHelper.FindChild(node, "castAttributes")
		If subNode
			Local castAttributes:TMap = Null
			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				If Not castAttributes Then castAttributes = CreateMap()
				Local jobID:Int = TVTProgrammePersonJob.GetByString(subNodeChild.GetName().ToLower())
				Local attributeID:Int = TVTProgrammePersonAttribute.GetByString(TXmlHelper.FindValue(subNodeChild, "attribute", ""))
				Local value:String = TXmlHelper.FindValue(subNodeChild, "value", "0.0")

				If jobID = TVTProgrammePersonJob.UNKNOWN Then Continue
				If attributeID = TVTProgrammePersonAttribute.NONE Then Continue

				'limit values to -1.0 - +1.0
				value = String( MathHelper.Clamp(Float(value), -1.0 , 1.0) )

				castAttributes.Insert(jobID+"_"+attributeID, value)
			Next
			'add attractions to data set
			If castAttributes Then data.Add("castAttributes", castAttributes)
		EndIf



		'load focusPointPriorities
		subNode = TXmlHelper.FindChild(node, "focusPointPriorities")
		If subNode
			Local focusPointPriorities:TMap = Null
			For Local subNodeChild:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(subNode)
				If Not focusPointPriorities Then focusPointPriorities = CreateMap()
				Local focusPointID:Int = TVTProductionFocus.GetByString(subNodeChild.GetName().ToLower())
				Local value:String = TXmlHelper.FindValue(subNodeChild, "value", "1.0")

				If focusPointID = TVTProductionFocus.NONE Then Continue

				focusPointPriorities.Insert(String(focusPointID), value)
			Next
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

		programmeDataMod.Insert("castAttributes", data.Get("castAttributes"))
		programmeDataMod.Insert("focusPointPriorities", data.Get("focusPointPriorities"))

		If data.GetString("goodFollower") <> ""
			Local followers:String[] = data.GetString("goodFollower").split(",")
			For Local i:Int = 0 Until followers.length
				If Int(followers[i]) = followers[i].Trim() Then Continue
				Local follower:Int = TVTProgrammeGenre.GetByString(followers[i])
				If follower = TVTProgrammeGenre.UNDEFINED
					Print "INVALID GOODFOLLOWER GENRE: "+followers[i]
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
					Print "INVALID BADFOLLOWER GENRE: "+followers[i]
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
End Type
