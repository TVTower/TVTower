Rem
	===========================================================
	code for stationmap and broadcasting stations
	===========================================================
ENDREM
SuperStrict
Import "Dig/base.util.xmlhelper.bmx"
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.time.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.framework.entity.bmx"
Import "game.gamerules.bmx"
Import "game.player.color.bmx"
Import "game.player.finance.bmx"
Import "game.publicimage.bmx"
Import "basefunctions.bmx"


'parent of all stationmaps
Type TStationMapCollection
	Field sections:TList = CreateList()
	'list of stationmaps
	Field stationMaps:TStationMap[0]
	Field antennaStationRadius:Int = 20
	Field population:int = 0 'remove
	'satellites currently in orbit
	Field satellites:TList
	'the original density map
	Field populationImageOriginalSprite:TSprite {nosave}
	Field populationImageOriginal:TImage {nosave}
	'the adjusted density map (only show "high pop"-areas)
	Field populationImageOverlay:TImage {nosave}
	Field populationImageSections:TImage {nosave}

	Field config:TData = New TData
	Field cityNames:TData = New TData
	Field sportsData:TData = New TData

	Field mapConfigFile:String = ""
	'does the shareMap has to get regenerated during the next
	'update cycle?
	Field _regenerateMap:Int = False

	Field defaultPopulationAntennaShare:Float = 0.8
	Field defaultPopulationCableShare:Float = 0.1
	Field defaultPopulationSatelliteShare:Float = 0.1


	REM
	ANTENNAS:
	http://www.spiegel.de/spiegel/print/d-13508831.html
	-> 1984 50% of 22 Mio western households via (collective antenna

	CABLE NETWORK
	cable network share development
	https://de.wikipedia.org/wiki/Kabelfernsehnetz
	-> 1986:     (1,53 Mio households)
	-> 1994:     (15 Mio households)
	-> 1995: 65% (15,8 Mio households)
	             75,1% Mecklenburg-Vorpommern
	             74,4% Brandenburg
	             --
	             56,9% Sachsen-Anhalt
	             61,4% Schleswig-Holstein
	-> 2017: 70% (22 Mio households)

	Medienrecht im Kontext standortrechtlicher...
	-> https://books.google.de/books?id=Lk2PDkNeCtEC&pg=PA126&lpg=PA126&dq=kabel+anschlussdichte+schleswig-holstein&source=bl&ots=wQjD6Yzvny&sig=LzuAyh3Oj4sxJMv4pHQBO43T8fU&hl=de&sa=X&ved=0ahUKEwia0P2KjbnXAhVB2KQKHWKnACkQ6AEIQTAF#v=onepage&q=kabel%20anschlussdichte%20schleswig-holstein&f=false
	-> 1993:	house-			possible	reached of
				holds			reach		possible
				  325.000		99,1%		60,8% 	Bremen        		p.119		(60,8% of 99,1% of 325.000 = 196.000 households )
				  800.000		99,5%		57,8% 	Hamburg       		p.121
				2.448.000		62,7%		67,4% 	Hessen        		p.122
											???   	Niedersachsen 		p.123-124 ??
				  438.000		59,8%		67,2%	Saarland      		p.125
				1.128.000		77,3%		57,1%	Schleswig-Holstein	p.126
				1.098.000		75%			75,6	Brandenburg			p.126		(75% = only connectable households here = 275.000) 
				  816.000		31,3%		68%		Mecklenburg-Vorpommern	p.127
				  

	http://www.kabelanschluss.eu/in-deutschland.html
	-> 1982  2% in Germany
	-> 1990 31% 
	-> 2015 70%

	http://www.bpb.de/gesellschaft/medien/deutsche-fernsehgeschichte-in-ost-und-west/245730/einfuehrung-des-kabelfernsehens
	-> 1990 31% / 8,1 Mio households
	-> 1995      15,8 Mio (including GDR federal states - "neue Bundeslaender")

	SATELLITES
	satellites "TV-Sat 1", "TV-Sat 2", "Télécom 1", "Télécom 2" in second half of 80s
	(GDR: receiving of western satellites forbidden: sat dishes mounted "non-orientable")
	astra since 1988
	END REM

	
	'how people can receive your TV broadcast
	Global populationReceiverMode:int = 2
	'Mode 1: they all receive via satellites, cable network and antenna
	'        if you covered all with satellites no antennas are needed
	'        100% with satellites = 100% with antenna
	Const RECEIVERMODE_SHARED:int = 1
	'Mode 2: some receive via satellite, some via cable ...
	'        "populationCable|Satellite|AntennaShare" are used to describe
	'        how many percents of the population are reachable via cable,
	'        satellite, ... 
	Const RECEIVERMODE_EXCLUSIVE:int = 2
	
	'difference between screen0,0 and pixmap
	'->needed movement to have population-pixmap over country
	Global populationMapOffset:TVec2D = New TVec2D.Init(0, 0)
	Global _initDone:Int = False
	Global _instance:TStationMapCollection


	Method New()
		If Not _initDone
			'handle savegame loading (reload the map configuration)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			'handle <stationmapdata>-area in loaded xml files
			EventManager.registerListenerFunction("RegistryLoader.onLoadResourceFromXML", onLoadStationMapData, Null, "STATIONMAPDATA" )
			'handle activation of stations
			EventManager.registerListenerFunction("station.onSetActive", onSetStationActiveState)
			EventManager.registerListenerFunction("station.onSetInactive", onSetStationActiveState)

			_initdone = True
		EndIf
	End Method


	Function GetInstance:TStationMapCollection()
		If Not _instance Then _instance = New TStationMapCollection
		Return _instance
	End Function


	Method Initialize:Int()
		For Local map:TStationMap = EachIn stationMaps
			map.Initialize()
		Next

		'remove all sections
		ResetSections()

		'remove and recreate all satellites
		ResetSatellites()
		
		'optional:
		'stationMaps = new TStationMap[0]
	End Method


	Method GenerateAntennaShareMaps:Int()
		for local section:TStationMapSection = EachIn sections
			section.GenerateAntennaShareMap()
		next
	End Method


	Method GetAntennaAudienceSum:int(stations:TList)
		local result:int
		For local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaAudienceSum(stations)
		Next
		return result
	End Method


	Method GetCableNetworkAudienceSum:int(stations:TList)
		local result:int
		for local station:TStationCableNetwork = EachIn stations
			local section:TStationMapSection = GetSectionByName(station.GetSectionName())
			if section then result :+ section.GetCableNetworkAudienceSum()
		next
		return result
	End Method


	Method GetSatelliteLinkAudienceSum:int(stations:TList)
		local result:int
		for local satLink:TStationSatelliteLink = EachIn stations
			result :+ satLink.GetExclusiveReach()
		next
		return result
	End Method


	Method GetSatelliteAtIndex:TStationMap_Satellite(index:int)
		if satellites.count() <= index or index < 0 then return Null

		return TStationMap_Satellite( satellites.ValueAtIndex(index) )
	End Method


	Method GetSatelliteByGUID:TStationMap_Satellite(guid:string)
		For local satellite:TStationMap_Satellite = EachIn satellites
			if satellite.GetGUID() = guid then return satellite
		Next

		return null
	End Method
	

	Function GetSatelliteLinksCount:int(stations:TList)
		local result:int
		for local station:TStationSatelliteLink = EachIn stations
			result :+ 1
		next
		return result
	End Function


	Function GetCableNetworksInSectionCount:int(stations:TList, sectionName:string)
		local result:int

		for local station:TStationCableNetwork = EachIn stations
			if station.sectionName = sectionName
				result :+ 1
			endif
		next
		return result
	End Function


	Method GetTotalChannelExclusiveAudience:Int(channelNumber:int)
		local result:int
		For local section:TStationMapSection = EachIn sections 
			result :+ section.GetChannelExclusiveAudience(channelNumber)
		Next
		return result
	End Method
	

	Method GetTotalShareAudience:Int(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		Return GetTotalShare(channelNumbers, withoutChannelNumbers).x
	End Method


	Method GetTotalSharePercentage:Float(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		Return GetTotalShare(channelNumbers, withoutChannelNumbers).z
	End Method


	'override
	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		'all sections: sum up X, sum up Y build average in Z
		local result:TVec3D = new TVec3D.Init(0,0,0)

		For local section:TStationMapSection = EachIn sections
			If RECEIVERMODE_SHARED
				Throw "GetShare: Todo"
				'result.AddVec( section.GetMixedShare(channelNumbers, withoutChannelNumbers) )
			ElseIf RECEIVERMODE_EXCLUSIVE
				result.AddVec( section.GetAntennaShare(channelNumbers, withoutChannelNumbers) )
				result.AddVec( section.GetCableNetworkShare(channelNumbers, withoutChannelNumbers) )
				result.AddVec( section.GetSatelliteShare(channelNumbers, withoutChannelNumbers) )
			EndIf
		Next
		If result.y = 0 Then result.z = 0.0 Else result.z = result.x/result.y

		return result
	End Method

	
	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetTotalShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		local result:TVec3D = new TVec3D.Init(0,0,0)
		'either
		For local section:TStationMapSection = EachIn sections
			result.AddVec( section.GetShare(channelNumbers, withoutChannelNumbers) )
		Next
		'or:
		'result.AddVec( GetTotalAntennaShare(channelNumbers, withoutChannelNumbers) )
		'result.AddVec( GetTotalCableNetworkShare(channelNumbers, withoutChannelNumbers) )
		'result.AddVec( GetTotalSatelliteShare(channelNumbers, withoutChannelNumbers) )

		if result.y > 0 then result.z = result.x / result.y
		return result
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetTotalAntennaShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		local result:TVec3D = new TVec3D.Init(0,0,0)
		For local section:TStationMapSection = EachIn sections
			result.AddVec( section.GetAntennaShare(channelNumbers, withoutChannelNumbers) )
		Next
		If result.y = 0 Then result.z = 0.0 Else result.z = result.x/result.y
			
		return result
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetTotalCableNetworkShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		local result:TVec3D = new TVec3D.Init(0,0,0)
		For local section:TStationMapSection = EachIn sections
			result.AddVec( section.GetCableNetworkShare(channelNumbers, withoutChannelNumbers) )
		Next
		If result.y = 0 Then result.z = 0.0 Else result.z = result.x/result.y
			
		return result
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetTotalSatelliteShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		local result:TVec3D = new TVec3D.Init(0,0,0)
		For local section:TStationMapSection = EachIn sections
			result.AddVec( section.GetSatelliteShare(channelNumbers, withoutChannelNumbers) )
		Next
		If result.y = 0 Then result.z = 0.0 Else result.z = result.x/result.y
			
		return result
	End Method
	

	'override
	Method GetSprite:TSprite()
		if not populationImageOriginalSprite then populationImageOriginalSprite = new TSprite.InitFromImage(populationImageOriginal, "populationImageOriginalSprite")
		return populationImageOriginalSprite
	End Method


	Method CalculateTotalAntennaStationReach:Int(stationX:Int, stationY:Int, radius:int = -1)
		local result:int = 0
		For local section:TStationMapSection = EachIn sections
			result :+ section.CalculateAntennaStationReach(stationX, stationY, radius)
		Next
		return result
	End Method


	Method CalculateTotalAntennaAudienceIncrease:Int(stations:TList, x:Int=-1000, y:Int=-1000, radius:int = -1)
		local result:int = 0
		For local section:TStationMapSection = EachIn sections
			result :+ section.CalculateAntennaAudienceIncrease(stations, x, y, radius)
		Next
		return result
	End Method
		

	Method CalculateTotalAntennaAudienceDecrease:Int(stations:TList, station:TStationAntenna)
		local result:int = 0
		For local section:TStationMapSection = EachIn sections
			result :+ section.CalculateAntennaAudienceDecrease(stations, station)
		Next
		return result
	End Method


	'=== EVENT HANDLERS ===

	'as soon as a station gets active (again), the sharemap has to get
	'regenerated (for a correct audience calculation)
	Function onSetStationActiveState:int(triggerEvent:TEventBase)
		GetInstance()._regenerateMap = True
		'also set the owning stationmap to "changed" so only this single
		'audience sum only gets recalculated (saves cpu time)
		Local station:TStationBase = TStationBase(triggerEvent.GetSender())
		If station Then GetInstance().GetMap(station.owner).changed = True
	End Function


	'run when loading finished
	Function onSaveGameLoad:int(triggerEvent:TEventBase)
		TLogger.Log("TStationMapCollection", "Savegame loaded - reloading map data", LOG_DEBUG | LOG_SAVELOAD)

		_instance.LoadMapFromXML()
	End Function


	'run when an xml contains an <stationmapdata>-area
	Function onLoadStationMapData:Int(triggerEvent:TEventBase)
		Local mapDataRootNode:TxmlNode = TxmlNode(triggerEvent.GetData().Get("xmlNode"))
		Local registryLoader:TRegistryLoader = TRegistryLoader(triggerEvent.GetSender())
		If Not mapDataRootNode Or Not registryLoader Then Return False

		Local densityNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "densitymap")
		If Not densityNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><densitymap>-entry.")

		Local surfaceNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "surface")
		If Not surfaceNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><surface>-entry.")

		Local configNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "config")
		If Not configNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><config>-entry.")

		Local cityNamesNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "citynames")
		If Not cityNamesNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><citynames>-entry.")

		Local sportsDataNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "sports")
		'not mandatory
		'If Not sportsDataNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><sports>-entry.")

		'directly load the given resources
		registryLoader.LoadSingleResourceFromXML(densityNode, True, New TData.AddString("name", "map_PopulationDensity"))
		registryLoader.LoadSingleResourceFromXML(surfaceNode, True, New TData.AddString("name", "map_Surface"))

		TXmlHelper.LoadAllValuesToData(configNode, _instance.config)
		TXmlHelper.LoadAllValuesToData(cityNamesNode, _instance.cityNames)
		if sportsDataNode
			TXmlHelper.LoadAllValuesToData(sportsDataNode, _instance.sportsData)
		endif

		'=== LOAD STATES ===
		'remove old states
		_instance.ResetSections()

		'find and load states configuration
		Local statesNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "states")
		If Not statesNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <map><states>-area.")

		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(statesNode)
			Local name:String	= TXmlHelper.FindValue(child, "name", "")
			Local sprite:String	= TXmlHelper.FindValue(child, "sprite", "")
			Local pos:TVec2D	= New TVec2D.Init( TXmlHelper.FindValueInt(child, "x", 0), TXmlHelper.FindValueInt(child, "y", 0) )
			'add state section if data is ok
			If name<>"" And sprite<>""
				_instance.AddSection( New TStationMapSection.Create(pos,name, sprite) )
			EndIf
		Next


		'=== CREATE SATELLITES ===
		'_instance.ResetSatellites()
	End Function


	'load a map configuration from a specific xml file
	'eg. "germany.xml"
	'we use xmlLoader so image ressources in the file get autoloaded
	Method LoadMapFromXML:Int(xmlFile:String="", baseUri:String = "")
		If xmlFile <> "" Then mapConfigFile = xmlFile

		'=== LOAD XML CONFIG ===
		Local registryLoader:TRegistryLoader = New TRegistryLoader
		registryLoader.baseURI = baseURI
		registryLoader.LoadFromXML(mapConfigFile, True)
		'TLogger.Log("TGetStationMapCollection().LoadMapFromXML", "config parsed", LOG_LOADING)

		'=== INIT MAP DATA ===
		CreatePopulationMaps()
		GenerateAntennaShareMaps()

		Return True
	End Method


	Method CreatePopulationMaps()
		Local stopWatch:TStopWatch = New TStopWatch.Init()
		Local srcPix:TPixmap = GetPixmapFromRegistry("map_PopulationDensity")
		If Not srcPix
			TLogger.Log("TGetStationMapCollection().CreatePopulationMap", "pixmap ~qmap_PopulationDensity~q is missing.", LOG_LOADING)
			Throw("TStationMap: ~qmap_PopulationDensity~q missing.")
			Return
		EndIf

		'move pixmap so it overlays the rest
		Local pix:TPixmap = CreatePixmap(Int(srcPix.width + populationMapOffset.x), Int(srcPix.height + populationMapOffset.y), srcPix.format)
		pix.ClearPixels(0)
		pix.paste(srcPix, Int(populationMapOffset.x), Int(populationMapOffset.y))

		local maxBrightnessPop:int = TStationMapSection.GetPopulationForBrightness(0)
		local minBrightnessPop:int = TStationMapSection.GetPopulationForBrightness(255)

		'read all inhabitants of the map
		'normalize the population map so brightest becomes 255
		Local i:Int, j:Int, c:Int, s:Int = 0
		population = 0
		For j = 0 To pix.height-1
			For i = 0 To pix.width-1
				c = pix.ReadPixel(i, j)
				If ARGB_ALPHA(pix.ReadPixel(i, j)) = 0 Then Continue
				local brightness:int = ARGB_RED(c)
				local pixelPopulation:int = TStationMapSection.GetPopulationForBrightness( brightness )

				'store pixel with lower alpha for lower population
				'-20 is the base level to avoid colorization of "nothing"
				local brightnessRate:Float = Min(1.0, 2 * pixelPopulation / float(maxBrightnessPop))
				if brightnessRate < 0.1
					brightnessRate = 0
				else
					brightnessRate :* (1.0 - brightness/255.0)
					brightnessRate = brightnessRate^0.25
				endif

				pix.WritePixel(i,j, ARGB_Color(brightnessRate*255, (1.0-brightnessRate)*255, 0, 0))
'				pix.WritePixel(i,j, ARGB_Color(255, int(brightnessRate*255), int(brightnessRate*255), int(0.2 * brightnessRate*255)))

				population :+ pixelPopulation
			Next
		Next	


		'store original
		populationImageOriginal = LoadImage(srcPix)
		'load the manipulated population image
		populationImageOverlay = LoadImage(pix)

		'create sections image and calculate population of each section
		CalculateSectionsPopulation()

		TLogger.Log("TGetStationMapCollection().CreatePopulationMap", "calculated a population of:" + population + " in "+stopWatch.GetTime()+"ms", LOG_DEBUG | LOG_LOADING)
	End Method


	Method Add:Int(map:TStationMap)
		'check boundaries
		If map.owner < 1 Then Return False

		'resize if needed
		If map.owner > stationMaps.length Then stationMaps = stationMaps[ .. map.owner+1]

		'add to array array - zerobased
		stationMaps[map.owner-1] = map
		Return True
	End Method


	Method Remove:Int(map:TStationMap)
		'check boundaries
		If map.owner < 1 Or map.owner > stationMaps.length Return False
		'remove from array - zero based
		stationMaps[map.owner-1] = Null

		'invalidate caches
		'shareCache.Clear()
		'shareMap.Clear()
		GenerateAntennaShareMaps()
		
		Return True
	End Method


	'return the stationmap of other channels
	'do not expose to Lua... else they get access to buy/sell
	Method GetMap:TStationMap(channelNumber:Int, createIfMissing:Int = False)
		'check boundaries
		If channelNumber < 1 Or (Not createIfMissing And channelNumber > stationMaps.length)
			Throw "GetStationMapCollection().GetMap: channelNumber ~q"+channelNumber+"~q is out of bounds."
		EndIf

		'create if missing
		If (channelNumber > stationMaps.length Or Not stationMaps[channelNumber-1]) And createIfMissing
			Add(TStationMap.Create(channelNumber))
		EndIf
		
		'zero based
		Return stationMaps[channelNumber-1]
	End Method


	'returns the average reach of all stationmaps
	Method GetAverageReach:Int()
		Local reach:Int = 0
		Local mapCount:Int = 0
		For Local map:TStationMap = EachIn stationMaps
			'skip empty maps
			'TODO: what happens with satellites?
			'if map.GetStationCount() = 0 then continue
			
			reach :+ map.GetReach()
			mapCount :+ 1
		Next
		if mapCount = 0 then return 0
		Return reach/mapCount
	End Method


	Method GetSportData:TData(sport:string, defaultData:TData = null)
		return sportsData.GetData(sport, defaultData)
	End Method


	Method GenerateCity:String(glue:String="")
		Local part1:String[] = cityNames.GetString("part1").Split(", ")
		Local part2:String[] = cityNames.GetString("part2").Split(", ")
		Local part3:String[] = cityNames.GetString("part3").Split(", ")
		if part1.length = 0 then return "part1Missing-Town"
		if part2.length = 0 then return "part2Missing-Town"
		if part3.length = 0 then return "part3Missing-Town"

		Local result:String = ""
		'use part 1?
		If part1.length > 0 and RandRange(0,100) < 35
			result :+ StringHelper.UCFirst(part1[RandRange(0, part1.length-1)])
		EndIf

		'no prefix, or " " or "-" (Bad Blaken, Alt-Drueben)
		If Not result Or Chr(result[result.length-1]) = " " Or Chr(result[result.length-1]) = "-"
			If result <> "" Then result :+ glue
			result :+ StringHelper.UCFirst(part2[RandRange(0, part2.length-1)])
		Else
			If result <> "" Then result :+ glue
			result :+ part2[RandRange(0, part2.length-1)]
		EndIf

		If RandRange(0,100) < 35
			result :+ glue
			result :+ part3[RandRange(0, part3.length-1)]
		EndIf

		if result.trim() = "" then return "partsMissing-Town"

		Return result
	End Method


	Method UpdateSatellites()
		if not satellites then ResetSatellites()
		if not satellites then return
		
		for local s:TStationMap_Satellite = EachIn satellites
			s.Update()
		next
	End Method


	Method Update:Int()
		UpdateSatellites()
	
		'update all stationmaps (and their stations)
		For Local i:Int = 0 Until stationMaps.length
			If Not stationMaps[i] Then Continue

			stationMaps[i].Update()
		Next


		'refresh the share map and refresh max audience sum
		'as soon as one of the stationmap changed
		If _regenerateMap
			GenerateAntennaShareMaps()

			'recalculate the audience sums of all changed maps
			'maybe generalize it (recalculate ALL as soon as map
			'gets regenerated)
			'this individual way saves calculation time (only do what
			'is needed)
			Local m:TStationMap
			For Local i:Int = 1 To stationMaps.length
				m = GetMap(i)
				If Not m Then Continue
				
				If m.changed
					m.RecalculateAudienceSum()
					'we handled the changed flag
					m.changed = False
				EndIf
			Next

			'we handled regenerating the map
			_regenerateMap = False
		EndIf
	End Method


	Method GetPopulation:Int()
		Return population
	End Method


	'=== SATELLITES (the launched ones) ===
	Method ResetSatellites:Int()
		if satellites and satellites.Count() > 0
			'avoid concurrent list modification and remove from list
			'by iterating over an array copy
			local satArray:TStationMap_Satellite[] = new TStationMap_Satellite[ satellites.Count() ]
			local i:int
			For local satellite:TStationMap_Satellite = EachIn satellites
				satArray[i] = satellite
				i :+ 1
			Next
			For local satellite:TStationMap_Satellite = EachIn satArray
				RemoveSatellite(satellite)
			Next
		endif
		'create new list (or empty it)
		satellites = CreateList()

		'TODO: init from map-config-file!

		'create some satellites
		local satNames:string[] = ["Alpha", "Orion", "MoSat", "Astro", "Dig", "Olymp", "Strata", "Solus"]
		'shuffle names a bit
		Local shuffleIndex:Int
		Local shuffleTmp:string
		For Local i:Int = satNames.length-1 To 0 Step -1
			shuffleIndex = RandRange(0, satNames.length-1)
			shuffleTmp = satNames[i]
			satNames[i] = satNames[shuffleIndex]
			satNames[shuffleIndex] = shuffleTmp
		Next		

		Local lastLaunchTime:Long = GetWorldTime().MakeTime(1982, 1,1, 0,0)
		Local satNumber:int = 0
		For local satName:string = EachIn satNames
			local satellite:TStationMap_Satellite = new TStationMap_Satellite
			satellite.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(18,28), RandRange(1,28), 0)
			satellite.name = satName
			satellite.quality = RandRange(50,100)
			satellite.feeMod = RandRange(80,120) / 100.0
			satellite.priceMod = RandRange(80,120) / 100.0

			if satNumber = 0
				satellite.minImage = RandRange(5,15) / 100.0
			elseif satNumber <= 2
				satellite.minImage = RandRange(10,20) / 100.0
			else
				satellite.minImage = RandRange(10,35) / 100.0
			endif

			satNumber :+ 1

			AddSatellite(satellite)

			lastLaunchTime = satellite.launchTime
		Next
		
	End Method


	Method AddSatellite:int(satellite:TStationMap_Satellite)
		if satellites.AddLast(satellite)
			'recalculate shared audience percentage between satellites
			UpdateSatelliteShares()

			'inform others
			EventManager.triggerEvent( TEventSimple.Create( "StationMapCollection.addSatellite", New TData.Add("satellite", satellite), Self ) )
			return True
		endif

		return False
	End Method


	Method RemoveSatellite:int(satellite:TStationMap_Satellite)
		if satellites.Remove(satellite)
			'recalculate shared audience percentage between satellites
			UpdateSatelliteShares()

			'inform others
			EventManager.triggerEvent( TEventSimple.Create( "StationMapCollection.removeSatellite", New TData.Add("satellite", satellite), Self ) )
			return True
		endif

		return False
	End Method


	Method OnLaunchSatellite:int(satellite:TStationMap_Satellite)
		'recalculate shared audience percentage between satellites
		UpdateSatelliteShares()
	End Method


	Method UpdateSatelliteShares:int()
		if not satellites or satellites.Count() = 0 then return False

		local bestQuality:Float = 0
		local worstQuality:Float = 0
		local avgQuality:Float = 0
		local qualitySum:Float = 0
		local firstFound:int = False
		local activeSatCount:int = 0

		For local satellite:TStationMap_Satellite = EachIn satellites
			if not satellite.IsLaunched() then continue

			if not firstFound
				bestQuality = satellite.quality
				worstQuality = satellite.quality
			endif
			
			if bestQuality > satellite.quality then bestQuality = satellite.quality 
			if worstQuality < satellite.quality then worstQuality = satellite.quality
			qualitySum :+ satellite.quality

			activeSatCount :+ 1
		Next
		'skip further processing if there is no active satellite
		if activeSatCount = 0 then return False

		avgQuality = qualitySum / activeSatCount

		'what's the worth of a quality point?
		local sharePart:Float = 1.0 / qualitySum

		'spread share
		print "UpdateSatelliteShares:"
		For local satellite:TStationMap_Satellite = EachIn satellites
			if not satellite.IsLaunched() then continue

			satellite.oldPopulationShare = satellite.populationShare
			satellite.populationShare = MathHelper.Clamp(sharePart * satellite.quality, 0.0, 1.0)
			print "  satellite: "+satellite.name+ "  share: " + satellite.oldPopulationShare +" -> " + satellite.populationShare
		Next

		return True
	End Method


	Method RemoveSatelliteLinkFromSatellite:int(satellite:TStationMap_Satellite, owner:int)
		local map:TStationMap = GetMap(owner)
		if not map then return False

		local satLink:TStationSatelliteLink = TStationSatelliteLink( map.GetSatelliteLinkBySatellite(satellite) )
		if not satLink then return False

		'do not sell it directly but just "shutdown" (so contracts can get renewed)
		satLink.ShutDown()
	End Method


	'=== SECTIONS ===

	Method GetSection:TStationMapSection(x:Int,y:Int)
		For Local section:TStationMapSection = EachIn sections
			If Not section.GetSprite() Then Continue

			If section.rect.containsXY(x,y)
				If section.GetSprite().PixelIsOpaque(Int(x-section.rect.getX()), Int(y-section.rect.getY())) > 0
					Return section
				EndIf
			EndIf
		Next
		Return Null
	End Method


	Method GetSectionByName:TStationMapSection(name:string)
		name = name.ToLower()
		For Local section:TStationMapSection = EachIn sections
			if section.name.ToLower() = name then return section
		Next
		return null
	End Method


	Method GetSectionByListPosition:TStationMapSection(position:int)
		return TStationMapSection(sections.ValueAtIndex(position))
	End Method


	Method GetSectionCount:int()
		return sections.Count()
	End Method


	Method GetSectionNames:string[]()
		local names:string[] = new String[ sections.Count() ]
		For Local i:int = 0 until sections.Count()
			names[i] = TStationMapSection(sections.ValueAtIndex(i)).name.ToLower()
		Next
		return names
	End Method


	Method DrawAllSections()
		If Not sections Then Return
		Local oldA:Float = GetAlpha()
		SetAlpha oldA * 0.8
		For Local section:TStationMapSection = EachIn sections
			If Not section.sprite Then Continue
			section.sprite.Draw(section.rect.getx(), section.rect.gety())
		Next
		SetAlpha oldA
	End Method
	

	Method ResetSections:Int()
		sections = CreateList()
	End Method


	Method AddSection(section:TStationMapSection)
		sections.addLast(section)
	End Method


	Method RemoveSectionFromPopulationSectionImage:int(section:TStationMapSection)
		local startX:int = int(Max(0, section.rect.GetX()))
		local startY:int = int(Max(0, section.rect.GetY()))
		local endX:int = int(Min(populationImageSections.width, section.rect.GetX2()))
		local endY:int = int(Min(populationImageSections.height, section.rect.GetY2()))
		local pix:TPixmap = LockImage(populationImageSections)
		local emptyCol:int = ARGB_Color(0, 0,0,0)

		For local x:int = startX until endX
			For local y:int = startY until endY
				If section.GetSprite().PixelIsOpaque(Int(x-section.rect.getX()), Int(y-section.rect.getY())) > 0
					pix.WritePixel(x,y, emptyCol)
				endif
			Next
		Next
	End Method



	Method CalculateSectionsPopulation:int()
		'copy the original image - start with a "full population map"
		populationImageSections = LoadImage( LockImage(populationImageOriginal) )

		For local section:TStationMapSection = eachIn sections
			section.GeneratePopulationImage(populationImageSections)
			section.CalculatePopulation()
			'remove the generated section population image from the map
			'population image
			RemoveSectionFromPopulationSectionImage(section)
		Next
	End Method
	
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetStationMapCollection:TStationMapCollection()
	Return TStationMapCollection.GetInstance()
End Function

Function GetStationMap:TStationMap(playerID:Int, createIfMissing:Int = False)
	Return TStationMapCollection.GetInstance().GetMap(playerID, createIfMissing)
End Function




Type TStationMap extends TOwnedGameObject {_exposeToLua="selected"}
	'select whose players stations we want to see
	Field showStations:Int[4]
	'and what types we want to show
	Field showStationTypes:Int[3]
	'maximum audience possible
	Field reach:Int	= 0
	Field cheatedMaxReach:int = False
	'all stations of the map owner
	Field stations:TList = CreateList()
	'amount of stations added per type
	Field stationsAdded:int[4]
	Field changed:Int = False

	'FALSE to avoid recursive handling (network)
	Global fireEvents:Int = True


	Function Create:TStationMap(playerID:Int)
		Local obj:TStationMap = New TStationMap
		obj.SetOwner(playerID)

		obj.Initialize()

		GetStationMapCollection().Add(obj)

		Return obj
	End Function


	Method Initialize:Int()
		changed = False
		stations.Clear()
		reach = 0
		showStations = [1,1,1,1]
		showStationTypes = [1,1,1]
	End Method


	'returns the maximum reach of the stations on that map
	Method GetReach:Int() {_exposeToLua}
		Return Self.reach
	End Method


	Method GetCoverage:Float() {_exposeToLua}
		Return Float(getReach()) / Float(GetStationMapCollection().getPopulation())
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryAntennaStation:TStationBase(x:Int,y:Int)  {_exposeToLua}
		local station:TStation = new TStation
		station.radius = GetStationMapCollection().antennaStationRadius

		Return station.Init(New TVec2D.Init(x,y),-1, owner)
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryCableNetworkStation:TStationBase(stateName:string)  {_exposeToLua}
		local mapSection:TStationMapSection = GetStationMapCollection().GetSectionByName(stateName)
		if not mapSection then return null
		
		local station:TStationBase = new TStationCableNetwork
		Return station.Init(New TVec2D.Init(mapSection.rect.GetXCenter(), mapSection.rect.GetYCenter()),-1, owner)
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporarySatelliteStation:TStationBase(satelliteIndex:int)  {_exposeToLua}
		local station:TStationSatelliteLink = new TStationSatelliteLink
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteAtIndex(satelliteIndex)
		if not satellite or not satellite.launched then return Null

		station.satelliteGUID = satellite.getGUID()

		'TODO: satellite positions

		Return station.Init(New TVec2D.Init(10,10),-1, owner)
	End Method


	Method GetTemporarySatelliteStationBySatelliteGUID:TStationBase(satelliteGUID:string)  {_exposeToLua}
		local station:TStationSatelliteLink = new TStationSatelliteLink
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite or not satellite.launched then return Null

		station.satelliteGUID = satellite.getGUID()

		'TODO: satellite positions

		Return station.Init(New TVec2D.Init(10,10),-1, owner)
	End Method


	'return a station at the given coordinates (eg. used by network)
	Method GetStationsByXY:TStationBase[](x:Int=0,y:Int=0) {_exposeToLua}
		Local res:TStationBase[]
		Local pos:TVec2D = New TVec2D.Init(x, y)
		For Local station:TStationBase = EachIn stations
			If Not station.pos.isSame(pos) Then Continue
			res :+ [station]
		Next
		Return res
	End Method


	Method GetStation:TStationBase(stationGUID:String) {_exposeToLua}
		For Local station:TStationBase = EachIn stations
			If station.GetGUID() = stationGUID Then Return station
		Next
		Return Null
	End Method


	'returns a station of a player at a given position in the list
	Method GetStationAtIndex:TStationBase(arrayIndex:Int=-1) {_exposeToLua}
		'out of bounds?
		If arrayIndex < 0 Or arrayIndex >= stations.count() Then Return Null

		Return TStationBase( stations.ValueAtIndex(arrayIndex) )
	End Method


	'returns all stations of a player in a given section
	Method GetStationsBySectionName:TStationBase[](sectionName:string, stationType:int=0) {_exposeToLua}
		local result:TStationBase[]
		For local station:TStationBase = EachIn stations
			if stationType >0 and station.stationType <> stationType then continue
			if station.sectionName = sectionName then result :+ [station]
		Next

		Return result
	End Method


	Method GetCableNetworkBySectionName:TStationBase(sectionName:string)
		For local station:TStationBase = EachIn stations
			if station.stationType <> TVTStationType.CABLE_NETWORK then continue
			if station.sectionName = sectionName then return station
		Next
		return null
	End Method


	Method GetSatelliteLinkBySatellite:TStationBase(satellite:TStationMap_Satellite)
		For local station:TStationSatelliteLink = EachIn stations
			if station.satelliteGUID = satellite.GetGUID() then return station
		Next
		return Null
	End Method

	'returns the amount of stations a player has
	Method GetStationCount:Int(stationType:int=0) {_exposeToLua}
		if stationType = 0
			Return stations.count()
		else
			local result:int = 0 
			for local s:TStationBase = EachIn stations
				if s.stationType = stationType then result :+ 1
			next
			return result
		endif
	End Method


	Method GetSatelliteLinksCount:int()
		return TStationMapCollection.GetSatelliteLinksCount(stations)
	End Method


	Method GetCableNetworksInSectionCount:int(sectionName:string)
		return TStationMapCollection.GetCableNetworksInSectionCount(stations, sectionName)
	End Method


	Method HasCableNetwork:int(station:TStationCableNetwork)
		return stations.contains(station)
'		For local s:TStationCableNetwork = EachIn stations
'			if s = station then return True
'		Next
		return False
	End Method


	Method HasStation:int(station:TStationBase)
		return stations.contains(station)
	End Method
	

	Method CheatMaxAudience:int()
		cheatedMaxReach = true
		reach = GetStationMapCollection().population
		GetStationMapCollection().GenerateAntennaShareMaps()
		return True
	End Method


	Method CalculateTotalAntennaAudienceIncrease:Int(x:Int=-1000, y:Int=-1000, radius:int = -1)
		return GetStationMapCollection().CalculateTotalAntennaAudienceIncrease(stations, x, y, radius)
	End Method


	'returns maximum audience a player's stations cover
	Method RecalculateAudienceSum:Int() {_exposeToLua}
		local reachBefore:int = reach

		if cheatedMaxReach
			reach = GetStationMapCollection().population
		else
			If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
				Throw "RecalculateAudienceSum: Todo"
			ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
				reach =  GetStationMapCollection().GetAntennaAudienceSum(stations)
				reach :+ GetStationMapCollection().GetCableNetworkAudienceSum(stations)
				reach :+ GetStationMapCollection().GetSatelliteLinkAudienceSum(stations)
			EndIf
		endif

		'inform others
		EventManager.triggerEvent( TEventSimple.Create( "StationMap.onRecalculateAudienceSum", New TData.addNumber("reach", reach).AddNumber("reachBefore", reachBefore), Self ) )

		Return reach
	End Method


	'returns additional audience when placing a station at the given coord
	Method CalculateAntennaAudienceIncrease:Int(x:Int, y:Int, radius:int = -1 ) {_exposeToLua}
		'LUA scripts pass a default radius of "0" if they do not pass a variable at all
		if radius <= 0 then radius = GetStationMapCollection().antennaStationRadius
		Return GetStationMapCollection().CalculateTotalAntennaAudienceIncrease(stations, x, y, radius)
	End Method
	

	'returns audience loss when selling a station at the given coord
	'param is station (not coords) to avoid ambiguity of multiple
	'stations at the same spot
	Method CalculateAntennaAudienceDecrease:Int(station:TStationAntenna) {_exposeToLua}
		Return GetStationMapCollection().CalculateTotalAntennaAudienceDecrease(stations, station)
	End Method


	'buy a new antenna station at the given coordinates
	Method BuyAntennaStation:Int(x:Int,y:Int)
		Return AddStation( GetTemporaryAntennaStation( x, y ), True )
	End Method


	'buy a new cable network station at the given coordinates
	Method BuyCableNetworkStationByMapSection:Int(mapSection:TStationMapSection)
		if not mapSection then return False

		Return AddStation( GetTemporaryCableNetworkStation( mapSection.name ), True )
	End Method


	'buy a new cable network station at the given coordinates
	Method BuyCableNetworkStation:Int(stateName:string)
		Return AddStation( GetTemporaryCableNetworkStation( stateName ), True )
	End Method


	'buy a new satellite station at the given coordinates
	Method BuySatelliteStation:Int(satelliteNumber:int)
		Return AddStation( GetTemporarySatelliteStation( satelliteNumber ), True )
	End Method


	'sell a station at the given position in the list
	Method SellStation:Int(position:Int)
		Local station:TStationBase = getStationAtIndex(position)
		If station Then Return RemoveStation(station, True)
		Return False
	End Method


	Method AddStation:Int(station:TStationBase, buy:Int=False)
		If Not station Then Return False

		'only one network per section and player allowed
		if TStationCableNetwork(station) and GetCableNetworkBySectionName(station.sectionName) then Return False


		'try to buy it (does nothing if already done)
		If buy And Not station.Buy(owner) Then Return False
		'set to paid in all cases
		station.SetFlag(TVTStationFlag.PAID, True)

		'so station names "grow"
		stationsAdded[station.stationType] :+ 1

		'give it a name
		if station.name = "" then station.name = "#"+stationsAdded[station.stationType]

		stations.AddLast(station)

		'DO NOT refresh the share map as ths would increase potential
		'audience in this moment. Generate it as soon as a station gets
		'"ready" (before next audience calculation - means xx:04 or xx:59)
		'GetStationMapCollection().GenerateAntennaShareMaps()

		'ALSO DO NOT recalculate audience of channel
		'RecalculateAudienceSum()

		TLogger.Log("TStationMap.AddStation", "Player"+owner+" buys broadcasting station ["+station.GetTypeName()+"] in section ~q" + station.GetSectionName() +"~q for " + station.price + " Euro (reach +" + station.getReach(True) + ")", LOG_DEBUG)

		'inform the station about the add (eg. remove connections)
		station.OnAddToMap()

		'emit an event so eg. network can recognize the change
		If fireEvents Then EventManager.triggerEvent( TEventSimple.Create( "stationmap.addStation", New TData.add("station", station), Self ) )

		Return True
	End Method


	Method RemoveStation:Int(station:TStationBase, sell:Int=False, forcedRemoval:Int=False)
		If Not station Then Return False

		If Not forcedRemoval
			'not allowed to sell this station
			If Not station.HasFlag(TVTStationFlag.SELLABLE) Then Return False

			'check if we try to sell our last station...
			If stations.count() = 1
				EventManager.triggerEvent(TEventSimple.Create("StationMap.onTrySellLastStation", Null, Self))
				Return False
			EndIf
		EndIf

		If sell And Not station.sell() Then Return False

		stations.Remove(station)

		If sell
			TLogger.Log("TStationMap.AddStation", "Player"+owner+" sells broadcasting station for " + station.getSellPrice() + " Euro (had a reach of " + station.reach + ")", LOG_DEBUG)
		Else
			TLogger.Log("TStationMap.AddStation", "Player"+owner+" trashes broadcasting station for 0 Euro (had a reach of " + station.reach + ")", LOG_DEBUG)
		EndIf

		'inform the station about the removal (eg. remove connections)
		station.OnRemoveFromMap()

		'refresh the share map (needed for audience calculations)
		GetStationMapCollection().GenerateAntennaShareMaps()
		'recalculate audience of channel
		RecalculateAudienceSum()

		'when station is sold, audience will decrease,
		'while a buy will not increase the current audience but the
		'next block (news or programme)
		'-> handled in main.bmx with a listener to "stationmap.removeStation"

		'emit an event so eg. network can recognize the change
		If fireEvents Then EventManager.triggerEvent(TEventSimple.Create("StationMap.removeStation", New TData.add("station", station), Self))

		Return True
    End Method


	Method CalculateStationCosts:Int() {_exposeToLua}
		Local costs:Int = 0
		For Local Station:TStationBase = EachIn stations
			costs :+ station.GetRunningCosts()
		Next
		Return costs
	End Method


	Method GetShowStation:int(channelNumber:int)
		if channelNumber > showStations.length or channelNumber <= 0 then return False

		Return showStations[channelNumber-1]
	End Method


	Method SetShowStation(channelNumber:int, enable:int)
		if channelNumber > showStations.length or channelNumber <= 0 then return

		showStations[channelNumber-1] = enable
	End Method


	Method GetShowStationType:int(stationType:int)
		if stationType > showStationTypes.length or stationType <= 0 then return False

		Return showStationTypes[stationType-1]
	End Method


	Method SetShowStationType(stationType:int, enable:int)
		if stationType > showStationTypes.length or stationType <= 0 then return

		showStationTypes[stationType-1] = enable
	End Method
	

	Method Update()
		'delete unused
		if GetStationMapCollection().stationMaps.length < showStations.length
			showStations = showStations[.. GetStationMapCollection().stationMaps.length + 1]
		'add new one (show them by default)
		elseif GetStationMapCollection().stationMaps.length > showStations.length
			local add:int = GetStationMapCollection().stationMaps.length - showStations.length

			showStations = showStations[.. showStations.length + add]

			For local i:int = 0 until add
				showStations[showStations.length - 1 - i] = 1
			Next
		endif
	
		UpdateStations()
	End Method


	Method UpdateStations()
		For Local station:TStationBase = EachIn stations
			station.Update()
		Next
	End Method


	'eg. a cable network might tint the topography images
	Method DrawStationBackgrounds(stationTypes:int[] = null)
		if stationTypes and stationTypes.length < TVTStationType.count then stationTypes = stationTypes[.. TVTStationType.count]

		For Local station:TStationBase = EachIn stations
			'ignore unwanted stations
			if stationTypes and stationTypes[station.stationType-1] = 0 then continue
			station.DrawBackground()
		Next
	End Method


	Method DrawStations(stationTypes:int[] = null)
		if stationTypes and stationTypes.length < TVTStationType.count then stationTypes = stationTypes[.. TVTStationType.count]

		For Local station:TStationBase = EachIn stations
			'ignore unwanted stations
			if stationTypes and stationTypes[station.stationType-1] = 0 then continue
			station.Draw()
		Next
	End Method


	'draw a players stationmap
	Method Draw()
		SetColor 255,255,255

		'draw all stations from all players (except filtered)
		For local map:TStationMap = eachin GetStationMapCollection().stationMaps
			If Not GetShowStation(map.owner) Then Continue
			map.DrawStationBackgrounds(showStationTypes)
		Next
		For local map:TStationMap = eachin GetStationMapCollection().stationMaps
			If Not GetShowStation(map.owner) Then Continue
			map.DrawStations(showStationTypes)
		Next
	End Method
End Type




Type TStationBase Extends TOwnedGameObject {_exposeToLua="selected"}
	'location at the station map
	'for satellites it is the "starting point", for cable networks and
	'antenna stations a point in the section / state
	Field pos:TVec2D = New TVec2D {_exposeToLua}

	Field reach:Int	= -1
	'increase of reach at when bought
	Field reachIncrease:Int = -1
	'decrease of reach when bought (= increase in that state)
	Field reachDecrease:Int = -1
	Field price:Int	= -1
	'daily costs for "running" the station
	Field runningCosts:int = -1
	Field owner:Int = 0
	'time at which the station was bought
	Field built:Double = 0
	'time at which the station gets active (again)
	Field activationTime:Double = -1
	Field sectionName:String = "" {nosave}
	Field name:string = ""
	Field stationType:int = 0
	'various settings (paid, fixed price, sellable, active...)
	Field _flags:Int = 0

	Field listSpriteNameOn:string = "gfx_datasheet_icon_antenna.on"
	Field listSpriteNameOff:string = "gfx_datasheet_icon_antenna.off"


	Method Init:TStationBase( pos:TVec2D, price:Int=-1, owner:Int)
		self.owner = owner
		if pos then self.pos = pos

		self.price = price
		self.built = GetWorldTime().getTimeGone()
		self.activationTime = -1

		self.SetFlag(TVTStationFlag.FIXED_PRICE, (price <> -1))
		'by default each station could get sold
		self.SetFlag(TVTStationFlag.SELLABLE, True)

		self.RefreshData()

		'save on compution for "initial states"
		self.reachDecrease = reachIncrease

		Return self
	End Method


	Method GenerateGUID:string()
		return "stationbase-"+id
	End Method


	Method OnAddToMap:int()
		'stub
	End Method
	

	Method OnRemoveFromMap:int()
		'stub
	End Method


	'refresh the station data
	Method refreshData() {_exposeToLua}
		GetReach(True)
		GetReachIncrease(True)
		'save on compution for "initial states" - do it on "create"
		'GetReachDecrease(True)
		GetPrice( Not HasFlag(TVTStationFlag.FIXED_PRICE) )
	End Method


	Method HasFlag:Int(flag:Int)
		Return _flags & flag
	End Method


	Method SetFlag(flag:Int, enable:Int=True)
		If enable
			_flags :| flag
		Else
			_flags :& ~flag
		EndIf
	End Method


	'returns the age in days
	Method GetAge:Int()
		Return GetWorldTime().GetDay() - GetWorldTime().GetDay(Self.built)
	End Method


	'returns the age in minutes
	Method GetAgeInMinutes:Int()
		Return (GetWorldTime().GetTimeGone() - Self.built) / 60
	End Method


	Method GetActivationTime:Double()
		Return activationTime
	End Method


	'get the reach of that station
	Method GetReach:Int(refresh:Int=False) abstract {_exposeToLua}


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) abstract {_exposeToLua}


	Method GetReachIncrease:Int(refresh:Int=False) {_exposeToLua}
		If reachIncrease >= 0 And Not refresh Then Return reachIncrease
		If owner <= 0 then Return 0

		reachIncrease = GetExclusiveReach(refresh)

		return reachIncrease
	End Method


	Method GetReachDecrease:Int(refresh:Int=False) {_exposeToLua}
		If reachDecrease >= 0 And Not refresh Then Return reachDecrease
		If owner <= 0 then Return 0

		reachDecrease = GetExclusiveReach(refresh)

		Return reachDecrease
	End Method


	'get the relative reach increase of that station
	Method GetRelativeReachIncrease:Int(refresh:Int=False) {_exposeToLua}
		Local r:Float = getReach(refresh)
		If r = 0 Then Return 0

		Return getReachIncrease(refresh) / r
	End Method


	Method GetSectionName:String(refresh:Int=False) {_exposeToLua}
		If sectionName <> "" And Not refresh Then Return sectionName

		Local hoveredSection:TStationMapSection = GetStationMapCollection().GetSection(Int(pos.x), Int(pos.y))
		If hoveredSection Then sectionName = hoveredSection.name

		Return sectionName
	End Method


	Method GetSellPrice:Int(refresh:Int=False) {_exposeToLua}
		'price is multiplied by an age factor of 0.75-0.95
		Local factor:Float = Max(0.75, 0.95 - Float(getAge())/1.0)
		If price >= 0 And Not refresh Then Return Int(price * factor / 10000) * 10000

		Return Int( getPrice(refresh) * factor / 10000) * 10000
	End Method


	Method GetPrice:Int(refresh:Int=False) {_exposeToLua}
		If price >= 0 And Not refresh Then Return price
		if GetReach() <= 0 then return 0
		price = Max( 30000, Int(Ceil(GetReach() / 10000)) * 30000 )

		Return price
	End Method


	Method GetName:string()
		return name
	End Method


	Method GetTypeName:string()
		return "stationbase"
	End Method


	Method GetLongName:string()
		if GetName() then return GetTypeName() + " " + GetName()
		return GetTypeName()
	End Method


	Method IsActive:Int()
		Return HasFlag(TVTStationFlag.ACTIVE)
	End Method


	'set time a station begins to work (broadcast)
	Method SetActivationTime:Int(activationTime:Double = -1)
		If activationTime < 0 Then activationTime = GetWorldTime().GetTimeGone()
		Self.activationTime = activationTime

		If activationTime < GetWorldTime().GetTimeGone() Then SetActive()
	End Method


	Method CanActivate:int()
		return True
	End Method
	

	'set time a station begins to work (broadcast)
	Method SetActive:Int(force:int = False)
		If IsActive() Then Return False
		If not force and not CanActivate() Then Return False

		Self.activationTime = GetWorldTime().GetTimeGone()
		SetFlag(TVTStationFlag.ACTIVE, True)

		'inform others (eg. to recalculate audience)
		EventManager.triggerEvent(TEventSimple.Create("station.onSetActive", Null, Self))
	End Method


	Method SetInactive:Int()
		If Not IsActive() Then Return False

		SetFlag(TVTStationFlag.ACTIVE, False)

		'inform others (eg. to recalculate audience)
		EventManager.triggerEvent(TEventSimple.Create("station.onSetInactive", Null, Self))
	End Method


	Method GetConstructionTime:Int()
		If GameRules.stationConstructionTime = 0 Then Return 0

		Local r:Int = GetReach()
		If r < 500000
			Return 1 * GameRules.stationConstructionTime
		ElseIf r < 1000000
			Return 2 * GameRules.stationConstructionTime
		ElseIf r < 2500000
			Return 3 * GameRules.stationConstructionTime
		ElseIf r < 5000000
			Return 4 * GameRules.stationConstructionTime
		Else
			Return 5 * GameRules.stationConstructionTime
		EndIf
	End Method


	Method GetRunningCosts:int() {_exposeToLua}
		return 0
	End Method


	Method Sell:Int()
		If Not GetPlayerFinance(owner) Then Return False

		If GetPlayerFinance(owner).SellStation( getSellPrice() )
			owner = 0
			Return True
		EndIf
		Return False
	End Method


	Method Buy:Int(playerID:Int)
		'set activation time (and refresh built time)
		built = GetWorldTime().GetTimeGone()

		Local constructionTime:Int = GetConstructionTime()
		'do not allow negative values as a "ready now" is not possible
		'because it affects broadcasted audience then.
		'if constructionTime <  0
		'	SetActivationTime( GetWorldTime().GetTimeGone()-1)
		'else
			If constructionTime <  0 Then constructionTime = 0

			constructionTime :+ 1

			'next hour (+construction hours) at xx:00
			If GetWorldTime().GetDayMinute(built + constructionTime*3600) >= 5
				SetActivationTime( GetWorldTime().MakeTime(0, 0, GetWorldTime().GetHour(built + constructionTime*3600), 0))
			'this hour (+construction hours) at xx:05
			Else
				SetActivationTime( GetWorldTime().MakeTime(0, 0, GetWorldTime().GetHour() + (constructionTime-1), 5, 0))
			EndIf
		'endif


		If HasFlag(TVTStationFlag.PAID) Then Return True
		If Not GetPlayerFinance(playerID) Then Return False

		If GetPlayerFinance(playerID).PayStation( getPrice() )
			owner = playerID
			SetFlag(TVTStationFlag.PAID, True)

			Return True
		EndIf

		Return False
	End Method


	Method Update:Int()
		'check if it becomes ready
		If Not IsActive()
			'TODO: if wanted, check for RepairStates or such things

			If CanActivate() and GetActivationTime() < GetWorldTime().GetTimeGone()
				SetActive()
			EndIf
		EndIf
	End Method


	'how much a potentially drawn sprite is offset (eg. for a boundary
	'circle like for antennas)
	Method GetOverlayOffsetY:int()
		return 0
	End Method


	Method SetSectionName:int(sectionName:string)
		self.sectionName = sectionName
	End Method


	Method DrawInfoTooltip()
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" )
		Local tooltipW:Int = 180
		Local tooltipH:Int = textH * 4 + 10 + 5
		If GetConstructionTime() > 0
			tooltipH :+ textH
		EndIf

		Local tooltipX:Int = pos.x +20 - tooltipW/2
		Local tooltipY:Int = pos.y - GetOverlayOffsetY() - tooltipH

		'move below station if at screen top
		If tooltipY < 20 Then tooltipY = pos.y + GetOverlayOffsetY() + 10 +10
		tooltipX = Max(20,tooltipX)
		tooltipX = Min(585-tooltipW,tooltipX)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0

		Local textY:Int = tooltipY+5
		Local textX:Int = tooltipX+5
		Local textW:Int = tooltipW-10
		Local colorWhite:TColor = TColor.Create(255,255,255)
		GetBitmapFontManager().baseFontBold.drawStyled( getLocale("MAP_COUNTRY_"+GetSectionName()), textX, textY, TColor.Create(255,255,0), 2)
		textY:+ textH + 5

		GetBitmapFontManager().baseFont.draw(GetLocale("REACH")+": ", textX, textY)
		GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(GetReach(), 2), textX, textY, textW, 20, New TVec2D.Init(ALIGN_RIGHT), colorWhite)
		textY:+ textH

		GetBitmapFontManager().baseFont.draw(GetLocale("INCREASE")+": ", textX, textY)
		GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(GetReachIncrease(), 2), textX, textY, textW, 20, New TVec2D.Init(ALIGN_RIGHT), colorWhite)
		textY:+ textH

		If GetConstructionTime() > 0
			GetBitmapFontManager().baseFont.draw(GetLocale("CONSTRUCTION_TIME")+": ", textX, textY)
			GetBitmapFontManager().baseFontBold.drawBlock(GetConstructionTime()+"h", textX, textY, textW, 20, New TVec2D.Init(ALIGN_RIGHT), colorWhite)
			textY:+ textH
		EndIf

		GetBitmapFontManager().baseFont.draw(GetLocale("PRICE")+": ", textX, textY)
		GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(getPrice(), 2), textX, textY, textW, 20, New TVec2D.Init(ALIGN_RIGHT), colorWhite)
	End Method


	Method DrawActivationTooltip()
		Local textCaption:String = getLocale("STATION_UNDER_CONSTRUCTION")
		Local textContent:String = GetLocale("READY_AT_TIME_X")
		Local readyTime:String = GetWorldTime().GetFormattedTime(GetActivationTime())
		'prepend day if it does not finish today
		If GetWorldTime().GetDay() < GetWorldTime().GetDay(GetActivationTime())
			readyTime = GetWorldTime().GetFormattedDay(GetWorldTime().GetDaysRun(GetActivationTime()) +1) + " " + readyTime
			textContent = GetLocale("READY_AT_DAY_X")
		EndIf
		textContent = textContent.Replace("%TIME%", readyTime)


		Local textH:Int = GetBitmapFontManager().baseFontBold.getHeight( "Tg" )
		Local textW:Int = GetBitmapFontManager().baseFontBold.getWidth(textCaption)
		textW = Max(textW, GetBitmapFontManager().baseFont.getWidth(textContent))
		Local tooltipW:Int = textW + 10
		Local tooltipH:Int = textH * 2 + 10 + 5
		Local tooltipX:Int = pos.x - tooltipW/2
		Local tooltipY:Int = pos.y - GetOverlayOffsetY() - tooltipH

		'move below station if at screen top
		If tooltipY < 20 Then tooltipY = pos.y + GetOverlayOffsetY() + 10 +10
		tooltipX = Max(20,tooltipX)
		tooltipX = Min(585-tooltipW,tooltipX)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0

		Local textY:Int = tooltipY+5
		Local textX:Int = tooltipX+5
		Local colorWhite:TColor = TColor.Create(255,255,255)
		GetBitmapFontManager().baseFontBold.drawStyled(textCaption, textX, textY, TColor.Create(255,255,0), 2)
		textY:+ textH + 5

		GetBitmapFontManager().baseFont.draw(textContent, textX, textY)
		textY:+ textH
	End Method


	Method DrawBackground(selected:Int=False, hovered:int=False)
		'
	End Method


	Method Draw(selected:Int=False)
		'
	End Method
End Type




'compatibility for now
Type TStation Extends TStationAntenna {_exposeToLua="selected"}
	'override
	Method Init:TStation( pos:TVec2D, price:Int=-1, owner:Int)
		Super.Init(pos, price, owner)
		return self
	End Method
End Type




Type TStationAntenna Extends TStationBase {_exposeToLua="selected"}
	Field radius:Int = 0


	Method New()
		radius = GetStationMapCollection().antennaStationRadius

		listSpriteNameOn = "gfx_datasheet_icon_antenna.on"
		listSpriteNameOff = "gfx_datasheet_icon_antenna.off"
	End Method


	'override
	Method Init:TStationAntenna( pos:TVec2D, price:Int=-1, owner:Int)
		Super.Init(pos, price, owner)
		stationType = TVTStationType.ANTENNA
		return self
	End Method


	'override
	Method GenerateGUID:string()
		return "station-antenna-"+id
	End Method


	'override
	Method GetTypeName:string()
		return GetLocale("STATION")
	End Method


	Method GetRect:TRectangle()
		return new TRectangle.Init(pos.x - radius, pos.y - radius, 2*radius, 2*radius)
	End Method


	Method GetReach:Int(refresh:Int=False) {_exposeToLua}
		If reach >= 0 And Not refresh Then Return reach

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			reach = GetStationMapCollection().CalculateTotalAntennaStationReach(Int(pos.x), Int(pos.y), radius)

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			reach = GetStationMapCollection().CalculateTotalAntennaStationReach(Int(pos.x), Int(pos.y), radius)

			'more exact approach (if SHARES DIFFER between sections) would be to
			'find split the area into all covered sections and calculate them
			'individually - then sum them up for the total reach amount

			local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			if not section or section.populationAntennaShare < 0
				reach :* GetStationMapCollection().defaultPopulationAntennaShare
			else
				reach :* section.populationAntennaShare
			endif
		EndIf

		Return reach
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			'as stations might broadcast to other sections too (crossing
			'borders) you cannot ignore stations in sections which are
			'covered by satellites/cable networks
			'so you will have to check _all_ covered sections

			'easiest approach: calculate reach "WITH - WITHOUT" station
			'TODO
			Throw "TStationAntenna.GetExclusiveReach() TODO"

			local exclusiveReach:int = GetStationMap(owner).CalculateAntennaAudienceIncrease(Int(pos.x), Int(pos.y), radius)
			return exclusiveReach
		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			local exclusiveReach:int
			If GetStationMap(owner).HasStation(self)
				exclusiveReach = GetStationMap(owner).CalculateAntennaAudienceDecrease(self)
			Else
				exclusiveReach = GetStationMap(owner).CalculateAntennaAudienceIncrease(Int(pos.x), Int(pos.y), radius)
			EndIf

			'this is NOT correct - as the other sections (overlapping)
			'might have other antenna share values
			'-> better replace that once we settled to a specific
			'   variant - exclusive or not - and multiply with a individual
			'   receiverShare-Map for all the pixels covered by the antenna
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			if not section or section.populationAntennaShare < 0
				exclusiveReach :* GetStationMapCollection().defaultPopulationAntennaShare
			else
				exclusiveReach :* section.populationAntennaShare
			endif
			return exclusiveReach
		EndIf

		return 0
	End Method
	

	'get the relative reach increase of that station
	Method GetRelativeReachIncrease:Int(refresh:Int=False) {_exposeToLua}
		Local r:Float = getReach(refresh)
		If r = 0 Then Return 0

		Return getReachIncrease(refresh) / r
	End Method


	'override
	Method GetRunningCosts:int() {_exposeToLua}
		if HasFlag(TVTStationFlag.NO_RUNNING_COSTS) then return 0
		
		local result:int = 0

		'== ADD STATIC RUNNING COSTS ==
		if runningCosts = -1
			rem
			                       daily costs
				   price       old    static   dynamic
				  100000      2000      3000      2000        2^1.2 =   2.30 =   2
				  250000      5000      7500      6000        5^1.2 =   6.90 =   6
				  500000     10000     15000     15000       10^1.2 =  15.85 =  15
				 1000000     20000     30000     36000       20^1.2 =  36.41 =  36
				 2500000     50000     75000    109000       50^1.2 = 109.34 = 109
				 5000000    100000    150000    251000      100^1.2 = 251.19 = 251
				10000000    200000    300000    577000      200^1.2 = 577.08 = 577
				25000000    500000    750000   1732000      500^1.2 =1732.86 =1732
			endrem
			'dynamic
			'runningCosts = 1000 * Floor(Ceil(price / 50000.0)^1.2)

			'static
			runningCosts = 1500 * ceil(price / 50000.0)
		endif
		result :+ runningCosts


		'== ADD RELATIVE MAINTENANCE COSTS ==
		if GameRules.stationIncreaseDailyMaintenanceCosts
			'the older a station gets, the more the running costs will be
			'(more little repairs and so on)
			'2% per day
			local maintenanceCostsPercentage:int = GameRules.stationDailyMaintenanceCostsPercentage * GetAge()
			'negative values deactivate the limit, positive once limit it
			if GameRules.stationDailyMaintenanceCostsPercentageTotalMax >= 0
				maintenanceCostsPercentage = Min(maintenanceCostsPercentage, GameRules.stationDailyMaintenanceCostsPercentageTotalMax)
			endif

			'1000 is "block size"
			result = 1000*int( (result * (1.0 + maintenanceCostsPercentage))/1000 )
		endif

		return result
	End Method


	'override
	Method GetOverlayOffsetY:int()
		return radius
	End Method
	

	Method Draw(selected:Int=False)
		Local sprite:TSprite = Null
		Local oldAlpha:Float = GetAlpha()

		If selected
			'white border around the colorized circle
			SetAlpha 0.25 * oldAlpha
			DrawOval(pos.x - radius - 2, pos.y - radius -2, 2 * (radius + 2), 2 * (radius + 2))

			SetAlpha Float(Min(0.9, Max(0,Sin(Time.GetAppTimeGone()/3)) + 0.5 ) * oldAlpha)
		Else
			SetAlpha 0.4 * oldAlpha
		EndIf

		Local color:TColor
		Select owner
			Case 1,2,3,4	color = TPlayerColor.GetByOwner(owner)
							sprite = GetSpriteFromRegistry("stationmap_antenna"+owner)
			Default			color = TColor.clWhite
							sprite = GetSpriteFromRegistry("stationmap_antenna0")
		End Select
		color.SetRGB()
		DrawOval(pos.x - radius, pos.y - radius, 2 * radius, 2 * radius)
		color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
		DrawOval(pos.x - radius + 2, pos.y - radius + 2, 2 * (radius - 2), 2 * (radius - 2))


		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(pos.x, pos.y + 1, -1, ALIGN_CENTER_CENTER)
	End Method
End Type




Type TStationCableNetwork extends TStationBase
	Field sectionHighlightBorderImage:TImage {nosave}
	Field sectionHoveredImage:TImage {nosave}
	Field sectionSelectedImage:TImage {nosave}


	Method New()
		listSpriteNameOn = "gfx_datasheet_icon_cable_network.on"
		listSpriteNameOff = "gfx_datasheet_icon_cable_network.off"
	End Method

	
	'override
	Method Init:TStationCableNetwork( pos:TVec2D, price:Int=-1, owner:Int)
		Super.Init(pos, price, owner)
		stationType = TVTStationType.CABLE_NETWORK
		return self
	End Method


	'override
	Method GenerateGUID:string()
		return "station-cable_network-"+id
	End Method


	'override
	Method GetTypeName:string()
		return GetLocale("CABLE_NETWORK")
	End Method


	Method GetLongName:string()
		return GetLocale("MAP_COUNTRY_"+GetSectionName())
	End Method


	'override
	Method GetRunningCosts:int() {_exposeToLua}
		if HasFlag(TVTStationFlag.NO_RUNNING_COSTS) then return 0
		
		local result:int = 0

		'== ADD STATIC RUNNING COSTS ==
		if runningCosts = -1
			rem
			                       daily costs
				   price       old    static   dynamic
				  100000      2000      3000      2000        2^1.2 =   2.30 =   2
				  250000      5000      7500      6000        5^1.2 =   6.90 =   6
				  500000     10000     15000     15000       10^1.2 =  15.85 =  15
				 1000000     20000     30000     36000       20^1.2 =  36.41 =  36
				 2500000     50000     75000    109000       50^1.2 = 109.34 = 109
				 5000000    100000    150000    251000      100^1.2 = 251.19 = 251
				10000000    200000    300000    577000      200^1.2 = 577.08 = 577
				25000000    500000    750000   1732000      500^1.2 =1732.86 =1732
			endrem
			'dynamic
			'runningCosts = 1000 * Floor(Ceil(price / 50000.0)^1.2)

			'static
			runningCosts = 1500 * ceil(price / 50000.0)
		endif
		result :+ runningCosts


		'== ADD RELATIVE MAINTENANCE COSTS ==
		if GameRules.stationIncreaseDailyMaintenanceCosts
			'the older a station gets, the more the running costs will be
			'(more little repairs and so on)
			'2% per day
			local maintenanceCostsPercentage:int = GameRules.stationDailyMaintenanceCostsPercentage * GetAge()
			'negative values deactivate the limit, positive once limit it
			if GameRules.stationDailyMaintenanceCostsPercentageTotalMax >= 0
				maintenanceCostsPercentage = Min(maintenanceCostsPercentage, GameRules.stationDailyMaintenanceCostsPercentageTotalMax)
			endif

			'1000 is "block size"
			result = 1000*int( (result * (1.0 + maintenanceCostsPercentage))/1000 )
		endif

		return result
	End Method


	'override
	Method SetSectionName:int(sectionName:string)
		local mapSection:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
		if mapSection
			local x:int = mapSection.rect.GetXCenter() - mapSection.rect.GetX()
			local y:int = mapSection.rect.GetYCenter() - mapSection.rect.GetY()
			While not mapSection.GetSprite().PixelIsOpaque(x, y)
				x = RandRange(0, mapSection.GetSprite().GetWidth()-1)
				y = RandRange(0, mapSection.GetSprite().GetHeight()-1)
			Wend
			self.pos.SetXY(mapSection.rect.GetX() + x, mapSection.rect.GetY() + y)
		endif

		local result:int = Super.SetSectionName(sectionName)
'
		'now we know how to calculate population
		'-> could get disabled as it is done during getpopulation-checks already
		self.RefreshData()

		return result
	End Method


	Method GetReach:Int(refresh:Int=False) {_exposeToLua}
		If reach >= 0 And Not refresh Then Return reach
		if not sectionName then return 0
		
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			reach = GetStationMapCollection().GetSectionByName(sectionName).GetPopulation()

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			reach = GetStationMapCollection().GetSectionByName(sectionName).GetPopulation()

			local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			if not section or section.populationCableShare < 0
				reach :* GetStationMapCollection().defaultPopulationCableShare
			else
				reach :* section.populationCableShare
			endif
		EndIf

		Return reach
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			'satellites
			'if a satellite covers the section, then no increase will happen
			if GetStationMap(owner).GetSatelliteLinksCount()
				return 0
			endif
			'cable networks
			'if there is another cable netwoth satellite covers the
			'section, then no increase will happen
			'if reach is calculated for self while already added,
			'check if another is existing too
			local cableNetworks:int = GetStationMap(owner).GetCableNetworksInSectionCount(sectionName)
			if GetStationMap(owner).HasCableNetwork(self) and cableNetworks > 1
				return 0
			elseif cableNetworks > 0
				return 0
			endif


			local exclusiveReach:int = GetStationMapCollection().GetSectionByName(sectionName).GetPopulation()

			'subtract section population for all antennas in that area
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
			exclusiveReach :- section.GetAntennaAudienceSum( GetStationMap(owner).stations )

			return exclusiveReach

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			return GetReach(refresh)
		EndIf

		return 0
	End Method


	Method DrawBackground(selected:Int=False, hovered:Int=False)
		local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
		if not section then return

		Local oldColor:TColor = new TColor.get()
		Local color:TColor
		Select owner
			Case 1,2,3,4	color = TPlayerColor.GetByOwner(owner)
			Default			color = TColor.clWhite
		End Select


		if selected or hovered
			if not sectionHighlightBorderImage
				sectionHighlightBorderImage = ConvertToOutLine( section.GetSprite().GetImage(), 5, 0.5, $FFFFFFFF , 9 )
				blurPixmap(LockImage( sectionHighlightBorderImage ), 0.5)
			endif
			if not sectionHoveredImage
				sectionHoveredImage = ConvertToSingleColor( section.GetSprite().GetImage(), $FFFFFFFF )
			endif
			if not sectionSelectedImage
				sectionSelectedImage = ConvertToSingleColor( section.GetSprite().GetImage(), $FF000000 )
			endif

			if selected
				SetColor 255,255,255
				SetAlpha 0.3
				DrawImage(sectionSelectedImage, section.rect.GetX(), section.rect.GetY())

				SetAlpha Float(0.2 * Sin(Time.GetAppTimeGone()/4) * oldColor.a) + 0.3
				SetBlend LightBlend
				DrawImage(sectionHighlightBorderImage, section.rect.GetX()-9, section.rect.GetY()-9)
				oldColor.SetRGBA()
				SetBlend AlphaBlend
			endif

			if hovered
				'SetAlpha Float(0.3 * Sin(Time.GetAppTimeGone()/4) * oldColor.a) + 0.15
				SetColor 255,255,255
				SetAlpha 0.15
				SetBlend LightBlend
				DrawImage(sectionHoveredImage, section.rect.GetX(), section.rect.GetY())

				SetAlpha 0.4
				SetBlend LightBlend
				DrawImage(sectionHighlightBorderImage, section.rect.GetX()-9, section.rect.GetY()-9)
				oldColor.SetRGBA()
				SetBlend AlphaBlend
			endif
		else
			SetAlpha oldColor.a * 0.3
			color.SetRGB()
			'color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
			section.GetSprite().Draw(section.rect.GetX(), section.rect.GetY())
			oldColor.SetRGBA()
		endif
	
	End Method

	
	Method Draw(selected:Int=False)
		Local sprite:TSprite = Null
		Local oldAlpha:Float = GetAlpha()

		If selected
			'white border around the hovered map section
			SetAlpha 0.25 * oldAlpha

			SetAlpha Float(Min(0.9, Max(0,Sin(Time.GetAppTimeGone()/3)) + 0.5 ) * oldAlpha)
		Else
			SetAlpha 0.4 * oldAlpha
		EndIf

		Local color:TColor
		Select owner
			Case 1,2,3,4	color = TPlayerColor.GetByOwner(owner)
							sprite = GetSpriteFromRegistry("stationmap_antenna"+owner)
			Default			color = TColor.clWhite
							sprite = GetSpriteFromRegistry("stationmap_antenna0")
		End Select
		color.SetRGB()
		'TODO: section hervorheben
		color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
		'TODO: section hervorheben


		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(pos.x, pos.y + 1, -1, ALIGN_CENTER_CENTER)
	End Method
End Type




Type TStationSatelliteLink extends TStationBase
	Field satelliteGUID:string
	'if a link was shut down, this value holds the satellite GUID
	'so we can easily resume the link
	Field oldSatelliteGUID:string

	 
	Method New()
		listSpriteNameOn = "gfx_datasheet_icon_satellite.on"
		listSpriteNameOff = "gfx_datasheet_icon_satellite.off"
	End Method

	
	'override
	Method Init:TStationSatelliteLink( pos:TVec2D, price:Int=-1, owner:Int)
		Super.Init(pos, price, owner)
		stationType = TVTStationType.SATELLITE
		return self
	End Method


	'override
	Method GenerateGUID:string()
		return "station-satellitelink-"+id
	End Method


	Method GetName:string()
		if satelliteGUID
			local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
			if satellite then return GetLocale("SATLINK_TO_X").Replace("%X%", satellite.name)
		endif
		return Super.GetName()
	End Method


	'override
	Method GetTypeName:string()
		return GetLocale("SATELLITE")
	End Method


	'override
	Method CanActivate:int()
		if not satelliteGUID then return False
		
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite then return False

		if not satellite.launched then return False
		if not satellite.IsSubscribedChannel(self.owner) then return False
		
		return True
	End Method


	Method ShutDown:int()
		'already shutdown
		if oldSatelliteGUID then return False
		
		SetInactive()
		oldSatelliteGUID = satelliteGUID

		return True
	End Method


	Method Resume:int()
		'already resumed
		if satelliteGUID then return False
		
		SetActive()

		satelliteGUID = oldSatelliteGUID
		oldSatelliteGUID = ""

		return True
	End Method


	'override to add satellite connection
	Method OnAddToMap:int()
		if not satelliteGUID then Throw "Adding Satellitelink to map without valid satellite guid."

		'inform satellite
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if satellite
			satellite.SubscribeChannel(self.owner, GetWorldTime().GetYearLength() )
		endif
	End Method


	'override to remove satellite connection
	Method OnRemoveFromMap:int()
		'inform satellite
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if satellite 
			satellite.UnsubscribeChannel(self.owner)
		endif
	End Method


	'override
	Method GetRunningCosts:int() {_exposeToLua}
		if HasFlag(TVTStationFlag.NO_RUNNING_COSTS) then return 0
		
		local result:int = 0

		'== ADD STATIC RUNNING COSTS ==
		if runningCosts = -1
			'static
			runningCosts = 17500 * ceil(price / 50000.0)
		endif
		result :+ runningCosts


		'== ADD RELATIVE MAINTENANCE COSTS ==
		'no maintenance costs at all

		return result
	End Method


	Method GetSubscriptionTimeLeft:Long()
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite then return 0

		local endTime:long = satellite.GetSubscribedChannelEndTime(owner)
		if endTime < 0 then return 0

		return GetWorldTime().GetTimeGone() - endTime
	End Method


	Method GetSubscriptionProgress:Float()
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite then return 0

		local startTime:long = satellite.GetSubscribedChannelStartTime(owner)
		local duration:int = satellite.GetSubscribedChannelDuration(owner)
		if duration < 0 then return 0

		return MathHelper.Clamp((GetworldTime().GetTimeGone() - startTime) / float(duration), 0.0, 1.0)
	End Method


	'override
	Method GetSellPrice:Int(refresh:Int=False) {_exposeToLua}
		'sell price = cancel costs
		'cancel costs depend on the days a contract has left
		Local factor:Float = (1.0 - GetSubscriptionProgress())^2

		Return Int( GetPrice(refresh) * factor / 10000) * 10000
	End Method


	'override
	Method GetPrice:Int(refresh:Int=False) {_exposeToLua}
		If price >= 0 And Not refresh Then Return price
		if GetReach() <= 0 then return 0
		'price for initial satellite link costs is way lower than for other
		'items
		price = Max( 10000, Int(Ceil(GetReach() / 50000)) * 10000 )

		Return price
	End Method


	Method GetReach:Int(refresh:Int=False) {_exposeToLua}
		'always return the satellite's reach - so it stays dynamically
		'without the hassle of manual "cache refreshs" 
		'If reach >= 0 And Not refresh Then Return reach

		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite then return 0
		
		reach = satellite.GetReach()

		return reach
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite then return 0

		return satellite.GetExclusiveReach()
rem
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			local exclusiveReach:int
			For local sectionKey:string = EachIn sectionsCovered
				local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionKey)
				if not section then continue
				
				'if reach is calculated for self while already added,
				'check if another is existing too
				local satellites:int = GetStationMap(owner).GetSatellitesInSectionCount(sectionKey)
				if GetStationMap(owner).HasStation(self) and satellites > 1
					continue
				elseif satellites > 0
					continue
				endif

				'cable networks
				'if there is a cable network covering one of the sections
				'then it cannot be exclusive there
				if GetStationMap(owner).GetCableNetworksInSectionCount(sectionName)
					continue
				endif


				exclusiveReach :+ section.GetPopulation()

				'subtract section population for all antennas in that area
				exclusiveReach :- section.GetAntennaAudienceSum( GetStationMap(owner).stations )
			Next
			return exclusiveReach

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			local exclusiveReach:int
			For local sectionKey:string = EachIn sectionsCovered
				local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionKey)
				if not section then continue

				if section.populationSatelliteShare < 0
					exclusiveReach :+ section.GetPopulation() * GetStationMapCollection().defaultPopulationSatelliteShare
				else
					exclusiveReach :+ section.GetPopulation() * section.populationSatelliteShare
				endif

			Next
			return exclusiveReach
		EndIf
endrem
		return 0
	End Method
	

	Method Draw(selected:Int=False)
		'For now sat links are invisble
	End Method
End Type




Type TStationMapSection
	Field rect:TRectangle
	Field sprite:TSprite {nosave}
	Field spriteName:String
	Field name:String
	Field populationImage:TImage {nosave}
	Field populationMap:int[,] {nosave}
	Field population:int = -1
	Field populationCableShare:Float = -1
	Field populationSatelliteShare:Float = -1
	Field populationAntennaShare:Float = -1
	'map containing bitmask-coded information for "used" pixels
	Field antennaShareMap:TMap = Null {nosave}
	'Field antennaShareMapImage:TImage {nosave}
	Field shareCache:TMap = Null {nosave}


	Method Create:TStationMapSection(pos:TVec2D, name:String, spriteName:String)
		Self.spriteName = spriteName
		Self.rect = New TRectangle.Init(pos.x,pos.y, 0, 0)
		Self.name = name
		LoadSprite()
		Return Self
	End Method


	Method LoadSprite()
		sprite = GetSpriteFromRegistry(spriteName)
		'resize rect
		rect.dimension.SetXY(sprite.area.GetW(), sprite.area.GetH())
	End Method


	Method GetSprite:TSprite()
		if not sprite then LoadSprite()
		return sprite
	End Method


	Method GeneratePopulationImage:int(sourcePopulationImage:TImage)
		local startX:int = int(Max(0, rect.GetX()))
		local startY:int = int(Max(0, rect.GetY()))
		local endX:int = int(Min(sourcePopulationImage.width, rect.GetX2()))
		local endY:int = int(Min(sourcePopulationImage.height, rect.GetY2()))
		local sourcePix:TPixmap = LockImage(sourcePopulationImage)

		if not populationImage then populationImage = LoadImage( CreatePixmap(rect.GetIntW(), rect.GetIntH(), sourcePix.format) )
		Local pix:TPixmap = LockImage(populationImage)
		pix.ClearPixels(0)

		'copy whats left on the sections image
		For local x:int = startX until endX
			For local y:int = startY until endY
				If GetSprite().PixelIsOpaque(Int(x-rect.getX()), Int(y-rect.getY())) > 0
					pix.WritePixel(x-rect.getX(), y-rect.getY(), sourcePix.ReadPixel(x, y) )
				endif
			Next
		Next
	End Method


	Method CalculatePopulation:int()
	
		populationMap = New Int[populationImage.width, populationImage.height]
	
		'generate map out of the populationImage
		'and also sum up population
		population = 0
		local pix:TPixmap = LockImage(populationImage)
		local c:int
		local skipped:int = 0
		For local x:int = 0 until populationImage.width
			For local y:int = 0 until populationImage.height
				c = pix.ReadPixel(x, y)
				If ARGB_ALPHA(pix.ReadPixel(x, y)) = 0 Then Continue
				local brightness:int = ARGB_RED(c)
				populationMap[x, y] = TStationMapSection.GetPopulationForBrightness( brightness )

				population :+ populationMap[x, y]
			Next
		Next
		return population
	End Method
	

	Method GetPopulation:int()
		if population < 0 then CalculatePopulation()
		return population
	End Method


	Method GenerateAntennaShareMap:Int()
		'reset values
		antennaShareMap = New TMap
		'reset cache here too
		shareCache = New TMap

		'local antennaShareMapPix:TPixmap = CreatePixmap(populationImage.width, populationImage.height, LockImage(populationImage).format)
		'antennaShareMapPix.ClearPixels(0)

		local stations:TStationBase[][]
		For local map:TStationMap = EachIn GetStationMapCollection().stationMaps 
			_FillAntennaShareMap(map, map.stations)
		Next

		'antennaShareMapImage = LoadImage(antennaShareMapPix)
		return True
	End Method
	

	Method _FillAntennaShareMap:Int(stationMap:TStationMap, stations:TList)
		'define locals outside of that for loops...
		Local posX:Int		= 0
		Local posY:Int		= 0
		Local stationX:Int	= 0
		Local stationY:Int	= 0
		Local mapKey:String	= ""
		Local mapValue:TVec3D = Null
		Local circleRect:TRectangle = New TRectangle.Init(0,0,0,0)
		local antennaStationRadius:int = GetStationMapCollection().antennaStationRadius


		if stationmap.cheatedMaxReach
			'insert the players bitmask-number into the field
			'and if there is already one ... add the number
			For posX = 0 To populationImage.height-1
				For posY = 0 To populationImage.width-1
					'left the topographic borders ?
					If not GetSprite().PixelIsOpaque(posX, posY) > 0 then continue

					mapKey = posX+","+posY
					mapValue = New TVec3D.Init(posX,posY, getMaskIndex(stationmap.owner) )
					If antennaShareMap.Contains(mapKey)
						mapValue.z = Int(mapValue.z) | Int(TVec3D(antennaShareMap.ValueForKey(mapKey)).z)
					EndIf
					antennaShareMap.Insert(mapKey, mapValue)

					'antennaShareMapPix.WritePixel(posX, posY, ARGB_Color(255, mapValue.z*30, mapValue.z*30, mapValue.z*30) )
				Next
			Next
		else
			'only handle antennas, no cable network/satellite!
			'For Local station:TStationBase = EachIn stationmap.stations
			For Local station:TStationAntenna = EachIn stations
				'skip inactive stations
				If Not station.IsActive() Then Continue

				'mark the area within the stations circle

				'local coordinate (within section)
				stationX = station.pos.x - rect.GetX()
				stationY = station.pos.y - rect.GetY()
				'stay within the section
				circleRect.position.SetXY( Max(0, stationX - antennaStationRadius), Max(0, stationY - antennaStationRadius) )
				circleRect.dimension.SetXY( Min(stationX + antennaStationRadius, rect.GetW()-1), Min(stationY + antennaStationRadius, rect.GetH()-1) )

				posX = 0
				posY = 0
				For posX = circleRect.getX() To circleRect.getW()
					For posY = circleRect.getY() To circleRect.getH()
						'left the circle?
						If Self.calculateDistance( posX - stationX, posY - stationY ) > antennaStationRadius Then Continue
						'left the topographic borders ?
						If not GetSprite().PixelIsOpaque(posX, posY) > 0 then continue


						'insert the players bitmask-number into the field
						'and if there is already one ... add the number
						mapKey = posX+","+posY
						mapValue = New TVec3D.Init(posX,posY, getMaskIndex(station.owner) )
						If antennaShareMap.Contains(mapKey)
							mapValue.z = Int(mapValue.z) | Int(TVec3D(antennaShareMap.ValueForKey(mapKey)).z)
						EndIf
						antennaShareMap.Insert(mapKey, mapValue)

						'antennaShareMapPix.WritePixel(posX, posY, ARGB_Color(255, Min(mapValue.z*60,255), (int(mapValue.z)&4 > 0)*80, (int(mapValue.z)&4 > 16)*80) )
					Next
				Next
			Next
		endif
	End Method



	'returns the shared amount of audience between channels
	Method GetShareAudience:Int(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		Return GetShare(channelNumbers, withoutChannelNumbers).x
	End Method


	Method GetSharePercentage:Float(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		Return GetShare(channelNumbers, withoutChannelNumbers).z
	End Method


	Method GetChannelAudience:Int(channelNumber:int)
		return GetShare([channelNumber], null).x
	End Method


	Method GetChannelExclusiveAudience:Int(channelNumber:int)
		local without:int[]
		for local i:int = 1 until 4
			if i <> channelNumber then without :+ [i]
		next
		return GetShare([channelNumber], without).x
	End Method


	Method GetAntennaShareMap:TMap()
		If Not antennaShareMap Then GenerateAntennaShareMap()
		Return antennaShareMap
	End Method
	

	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		local result:TVec3D = new TVec3D.Init(0,0,0)
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			Throw "GetShare: TODO"
			'result.AddVec( GetMixedShare(channelNumbers, withoutChannelNumbers) )
		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			result.AddVec( GetAntennaShare(channelNumbers, withoutChannelNumbers) )
			result.AddVec( GetCableNetworkShare(channelNumbers, withoutChannelNumbers) )
			result.AddVec( GetSatelliteShare(channelNumbers, withoutChannelNumbers) )
		EndIf
		if result.y > 0 then result.z = result.x / result.y
		return result
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetCableNetworkShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		return new TVec3D.Init(0,0,0)
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetSatelliteShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		return new TVec3D.Init(0,0,0)
	End Method
	

	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetAntennaShare:TVec3D(channelNumbers:Int[], withoutChannelNumbers:Int[]=Null)
		If channelNumbers.length <1 Then Return New TVec3D.Init(0,0,0.0)
		If Not withoutChannelNumbers Then withoutChannelNumbers = New Int[0]

		Local result:TVec3D

		'=== CHECK CACHE ===
		'if already cached, save time...

		'== GENERATE KEY ==
		Local cacheKey:String = ""
		For Local i:Int = 0 To channelNumbers.length-1
			cacheKey:+ "_"+channelNumbers[i]
		Next
		If withoutChannelNumbers.length > 0
			cacheKey:+"_without_"
			For Local i:Int = 0 To withoutChannelNumbers.length-1
				cacheKey:+ "_"+withoutChannelNumbers[i]
			Next
		EndIf

		'== LOAD CACHE ==
		If shareCache And shareCache.contains(cacheKey)
			result = TVec3D(shareCache.ValueForKey(cacheKey))
		EndIf


		'== GENERATE CACHE ==
		If Not result
			result = _CalculateShare(GetAntennaShareMap(), channelNumbers, withoutChannelNumbers)
			'store new cached data
			If shareCache Then shareCache.insert(cacheKey, result )

			'print "uncached: "+cacheKey
			'print "share:  total="+int(result.y)+"  share="+int(result.x)+"  share="+(result.z*100)+"%"
		else
			'print "cached: "+cacheKey
			'print "share:  total="+int(result.y)+"  share="+int(result.x)+"  share="+(result.z*100)+"%"
		EndIf


		Return result
	End Method


	Method _CalculateShare:TVec3D(shareMap:TMap, channelNumbers:int[], withoutChannelNumbers:int[]=Null)
		Local result:TVec3D = New TVec3D.Init(0,0,0.0)
		Local share:Int	= 0
		Local total:Int	= 0
		Local channelFlags:Int[]
		Local allFlag:Int = 0
		Local withoutChannelFlags:Int[]
		Local withoutFlag:Int = 0
		channelFlags = channelFlags[.. channelNumbers.length]
		withoutChannelFlags = withoutChannelFlags[.. withoutChannelNumbers.length]

		For Local i:Int = 0 To channelNumbers.length-1
			'channel 1=1, 2=2, 3=4, 4=8 ...
			channelFlags[i] = getMaskIndex( channelNumbers[i] )
			allFlag :| channelFlags[i]
		Next

		For Local i:Int = 0 To withoutChannelNumbers.length-1
			'channel 1=1, 2=2, 3=4, 4=8 ...
			withoutChannelFlags[i] = getMaskIndex( withoutChannelNumbers[i] )
			withoutFlag :| withoutChannelFlags[i]
		Next


		Local someoneUsesPoint:Int = False
		Local allUsePoint:Int = False
		For Local mapValue:TVec3D = EachIn shareMap.Values()
			someoneUsesPoint = False
			allUsePoint = False

			'we need to check if one on our ignore list is there
				'no need to do this individual, we can just check the groupFlag
				Rem
				local someoneUnwantedUsesPoint:int	= FALSE
				for local i:int = 0 to withoutChannelFlags.length-1
					if int(mapValue.z) & withoutChannelFlags[i]
						someoneUnwantedUsesPoint = true
						exit
					endif
				Next
				if someoneUnwantedUsesPoint then continue
				endrem
			If Int(mapValue.z) & withoutFlag Then Continue

			'as we have multiple flags stored in AllFlag, we have to
			'compare the result to see if all of them hit,
			'if only one of it hits, we just check for <>0
			If (Int(mapValue.z) & allFlag) = allFlag
				allUsePoint = True
				someoneUsesPoint = True
			Else
				For Local i:Int = 0 To channelFlags.length-1
					If Int(mapValue.z) & channelFlags[i] Then someoneUsesPoint = True;Exit
				Next
			EndIf
			'someone has a station there
			If someoneUsesPoint Then total:+ populationmap[mapValue.x, mapValue.y]
			'all searched have a station there
			If allUsePoint Then share:+ populationmap[mapValue.x, mapValue.y]
		Next
		result.setXY(share, total)
		If total = 0 Then result.z = 0.0 Else result.z = Float(share)/Float(total)

		return result
	End Method
	

	'params of advanced types (no ints, strings, bytes) are automatically
	'passed "by reference" (change it here, and it is changed globally)
	Method _FillAntennaPoints(map:TMap, stationX:Int, stationY:Int, radius:int, color:Int)
		local stationRect:TRectangle = New TRectangle.Init(stationX - radius, stationY - radius, 2*radius, 2*radius)
		'find minimal rectangle/intersection between section and station
		local sectionStationIntersectRect:TRectangle = rect.IntersectRect(stationRect)
		'no intersection, nothing to do then?
		if not sectionStationIntersectRect then return

		'convert world coordinate to local coords
		sectionStationIntersectRect.position.AddX( -rect.GetX() )
		sectionStationIntersectRect.position.AddY( -rect.GetY() )
		stationX :- rect.GetX()
		stationY :- rect.GetY()

		Local result:Int = 0
		For local posX:int = sectionStationIntersectRect.getX() To sectionStationIntersectRect.getX2()-1
			For local posY:int = sectionStationIntersectRect.getY() To sectionStationIntersectRect.getY2()-1
				'left the circle?
				If CalculateDistance( posX - stationX, posY - stationY ) > radius Then Continue
				'left the topographic borders ?
				If not GetSprite().PixelIsOpaque(posX, posY) > 0 then continue

				map.Insert(String(posX + "," + posY), New TVec3D.Init((posX) , (posY), color ))
			Next
		Next
	End Method


	'summary: returns a stations maximum audience reach
	Method CalculateAntennaStationReach:Int(stationX:Int, stationY:Int, radius:int = -1)
		if radius < 0 then radius = GetStationMapCollection().antennaStationRadius

		'might be negative - if ending before the sections rect
		local stationRect:TRectangle = New TRectangle.Init(stationX - radius, stationY - radius, 2*radius, 2*radius)
		'find minimal rectangle/intersection between section and station
		local sectionStationIntersectRect:TRectangle = rect.IntersectRect(stationRect)
		'skip if section and station do not share a pixel
		if not sectionStationIntersectRect then return 0

		'move world to local coords
		sectionStationIntersectRect.position.AddX( -rect.GetX() )
		sectionStationIntersectRect.position.AddY( -rect.GetY() )
		stationX :- rect.GetX()
		stationY :- rect.GetY()

rem
print name
print "  rect: " + rect.ToString()
print "  stationRect: " + stationRect.ToString()
print "  sprite: " + GetSprite().GetWidth()+","+GetSprite().GetHeight()
print "  sectionStationIntersectRect: " + sectionStationIntersectRect.ToString()
endrem		

		' calc sum for current coord
		Local result:Int = 0
		For local posX:int = sectionStationIntersectRect.getX() To sectionStationIntersectRect.getX2()-1
			For local posY:int = sectionStationIntersectRect.getY() To sectionStationIntersectRect.getY2()-1
				'left the circle?
				If CalculateDistance( posX - stationX, posY - stationY ) > radius Then Continue
				'left the topographic borders ?
				If not GetSprite().PixelIsOpaque(posX, posY) > 0 then continue
				result :+ populationmap[posX, posY]
			Next
		Next

		Return result
	End Method


	Method CalculateAntennaAudienceDecrease:Int(stations:TList, removeStation:TStationAntenna)
		If Not removeStation Then Return 0
		'if station is not hitting the section
		if not removeStation.GetRect().Intersects(rect) then Return 0

		Local Points:TMap = New TMap
		Local result:Int = 0

		'mark the station to removed as "red"
		'mark all others (except the given one) as "white"
		'-> then count on all spots "just red" and not "white"
		
		Self._FillAntennaPoints(Points, Int(removeStation.pos.x), Int(removeStation.pos.y), removeStation.radius, ARGB_Color(255, 0, 255, 255))

		'overwrite with stations owner already has - red pixels get
		'overwritten with white, count red at the end for decrease amount
		For Local station:TStationAntenna = EachIn stations
			'DO NOT SKIP INACTIVE STATIONS !!
			'decreases are for estimations - so they should include
			'non-finished stations too
			'If Not station.IsActive() Then Continue

			'exclude the station to remove...
			If station = removeStation Then Continue

			'skip antennas not overlapping the station to remove
			if not station.GetRect().Intersects(removeStation.GetRect()) then continue

			Self._FillAntennaPoints(Points, Int(station.pos.x), Int(station.pos.y), station.radius, ARGB_Color(255, 255, 255, 255))
		Next

		'count all "exclusively blue" spots
		For Local point:TVec3D = EachIn points.Values()
			If ARGB_Red(Int(point.z)) = 0 'And ARGB_Blue(point.z) = 255
				result :+ populationmap[point.x, point.y]
			EndIf
		Next
		Return result
	End Method
	

	Method CalculateAntennaAudienceIncrease:Int(stations:TList, stationX:Int=-1000, stationY:Int=-1000, radius:int = -1)
		if radius < 0 then radius = GetStationMapCollection().antennaStationRadius
		If stationX = -1000 And stationY = -1000
			stationX = MouseManager.x
			stationY = MouseManager.y
		endif


		'might be negative - if ending before the sections rect
		local stationRect:TRectangle = New TRectangle.Init(stationX - radius, stationY - radius, 2*radius, 2*radius)
		'skip if section and station do not share a pixel
		if not rect.Intersects(stationRect) then return 0


		Local Points:TMap = New TMap
		Local result:Int = 0

		'add "new" station which may be bought
		Self._FillAntennaPoints(Points, stationX, stationY, radius, ARGB_Color(255, 0, 255, 255))

		'overwrite with stations owner already has - red pixels get
		'overwritten with white, count red at the end for increase amount
		For Local station:TStationAntenna = EachIn stations
			'DO NOT SKIP INACTIVE STATIONS !!
			'increases are for estimations - so they should include
			'non-finished stations too
			'If Not station.IsActive() Then Continue

			'skip antennas outside of the section
			if not station.GetRect().Intersects(rect) then continue

			'skip antennas not overlapping the station to add
			if not station.GetRect().Intersects(stationRect) then continue

			Self._FillAntennaPoints(Points, Int(station.pos.x), Int(station.pos.y), station.radius, ARGB_Color(255, 255, 255, 255))
		Next

		For Local point:TVec3D = EachIn points.Values()
			If ARGB_Red(Int(point.z)) = 0 And ARGB_Blue(Int(point.z)) = 255
				result :+ populationmap[point.x, point.y]
			EndIf
		Next
		Return result
	End Method
	

	'summary: returns maximum audience a player reaches with a cablenetwork
	Method GetCableNetworkAudienceSum:Int()
		if populationCableshare < 0
			return population * GetStationMapCollection().defaultPopulationCableShare
		else
			return population * populationCableShare
		endif
	End Method


	'summary: returns maximum audience a player reaches with a cablenetwork
	Method GetSatelliteAudienceSum:Int()
		if populationSatelliteShare < 0
			return population * GetStationMapCollection().defaultPopulationSatelliteShare
		else
			return population * populationSatelliteShare
		endif
	End Method
	

	'summary: returns maximum audience a player reaches with antennas
	Method GetAntennaAudienceSum:Int(stations:TList)
		Local Points:TMap = New TMap
		Local result:Int = 0
		
		For Local station:TStationAntenna = EachIn stations
			'skip inactive stations
			If Not station.IsActive() Then Continue

			'skip antennas outside of the section
			if not station.GetRect().Intersects(rect) then continue

			Self._FillAntennaPoints(Points, Int(station.pos.x), Int(station.pos.y), station.radius, ARGB_Color(255, 255, 255, 255))
		Next

		For Local point:TVec3D = EachIn points.Values()
			If ARGB_Red(Int(point.z)) = 255 And ARGB_Blue(Int(point.z)) = 255
				result :+ populationMap[point.x, point.y]
			EndIf
		Next

		if populationAntennaShare < 0
			Return result * GetStationMapCollection().defaultPopulationAntennaShare
		else
			Return result * populationAntennaShare
		endif
	End Method


	Function GetPopulationForBrightness:Int(value:Int)
		'attention: we use Ints, so values < 16 (sqrt 255) will be 0!
		value = Max(5, 255-value)
		value = (value*value)/255 '2 times so low values are getting much lower
		value:* 0.649

		If value > 110 Then value :* 2.0
		If value > 140 Then value :* 1.9
		If value > 180 Then value :* 1.3
		If value > 220 Then value :* 1.1	'population in big cities
		Return 26.0 * value					'population in general
	End Function


	Function getMaskIndex:Int(number:Int)
		Local t:Int = 1
		For Local i:Int = 1 To number-1
			t:*2
		Next
		Return t
	End Function
	

	'summary: returns calculated distance between 2 points
	Function calculateDistance:Double(x1:Int, x2:Int)
		Return Sqr((x1*x1) + (x2*x2))
	End Function
End Type




'excuse naming scheme but "TSatellite" is ambiguous for "stationtypes"
Type TStationMap_Satellite extends TEntityBase
	Field name:string

	'minimum image needed to be able to subscribe
	Field minImage:Float

	'limit for currently subscribed channels
	Field channelMax:int
	'channelIDs for channels currently subscribed to the satellite
	Field subscribedChannels:int[]
	'when do their contracts start and end?
	Field subscribedChannelsStartTime:Long[]
	Field subscribedChannelsDuration:Int[]
	
	
	Field launched:int = False
	Field launchTime:long
	Field lifeTime:long = -1
	'eg. signal strength
	'used to evaluate which satellite the people would prefer
	'when comparing them (-> populationShare)
	'satellites could get upgrades by sat company for higher quality
	'or wear off...
	Field quality:int = 100

	Field feeMod:Float = 1.0
	Field priceMod:Float = 1.0

	'how many of the people in reach are reachable at all
	'eg. adjusted their dishes to receive the satellite
	'    -> this might change over time (more channels on a "better"
	'       satellite)
	Field populationShare:Float = 0.0
	'to see whether it increased or not
	Field oldPopulationShare:Float = 0.0
	'disabled: just assume they reach the whole country
	'the population reachable because of orbit position
	'Field populationImage:TImage {nosave}
	'Field populationMap:int[,] {nosave}

	Field exclusiveReach:Int = -1
	Field reach:Int = -1


	'override
	Method GenerateGUID:string()
		return "stationmap-satellite-"+id
	End Method


	Method GetReach:Int(refresh:int = False) {_exposeToLua}
		If reach >= 0 And Not refresh Then Return reach
	
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			reach = GetStationMapCollection().GetPopulation()

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			reach = GetStationMapCollection().GetPopulation()
			reach :* GetStationMapCollection().defaultPopulationSatelliteShare
		EndIf

		reach :* populationShare

		Return reach
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
'		If exclusiveReach >= 0 And Not refresh Then Return exclusiveReach

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			exclusiveReach = GetStationMapCollection().GetPopulation()

			'satellites
			'as only ONE sat could get received the same time, we can
			'ignore others

			'cable networks
			'TODO: subtract audiences _exclusive_ to antennas

			'antennas
			'TODO: subtract antennas
			return exclusiveReach

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			exclusiveReach = GetReach(refresh)
		Else

			exclusiveReach = 0
		EndIf

		return exclusiveReach
	End Method


	Method GetSubscribedChannelIndex:int(channelID:int)
		For local i:int = 0 until subscribedChannels.length
			if subscribedChannels[i] = channelID then return i
		Next
		return -1
	End Method


	Method GetSubscribedChannelStartTime:Long(channelID:int)
		local i:int = GetSubscribedChannelIndex(channelID)
		if i = -1 then return -1

		return subscribedChannelsStartTime[i]
	End Method


	Method GetSubscribedChannelEndTime:Long(channelID:int)
		local i:int = GetSubscribedChannelIndex(channelID)
		if i = -1 then return -1

		return subscribedChannelsStartTime[i] + subscribedChannelsDuration[i]
	End Method


	Method GetSubscribedChannelDuration:Long(channelID:int)
		local i:int = GetSubscribedChannelIndex(channelID)
		if i = -1 then return -1

		return subscribedChannelsDuration[i]
	End Method


	Method IsSubscribedChannel:int(channelID:int)
		For local i:int = EachIn subscribedChannels
			if i = channelID then return True
		Next
		return False
	End Method


	Method CanSubscribeChannel:int(channelID:int, duration:Int=-1)
		if minImage > 0 and minImage > GetPublicImage(channelID).GetAverageImage() then return -1
		if channelMax >= 0 and subscribedChannels.length >= channelMax then return -2

		return 1
	End Method


	Method SubscribeChannel:int(channelID:int, duration:Int=-1, force:Int=False)
		if IsSubscribedChannel(channelID) then return False
		if not force and CanSubscribeChannel(channelID, duration) <> 1 then return False

		subscribedChannels :+ [channelID]
		subscribedChannelsStartTime :+ [Long(GetWorldTime().GetTimeGone())]
		subscribedChannelsDuration :+ [duration]

		return True
	End Method


	Method UnsubscribeChannel:int(channelID:int)
		local index:int = -1
		For local i:int = 0 until subscribedChannels.length
			if i = channelID then index = i
		Next
		if index = -1 then return False

		subscribedChannels = subscribedChannels[.. index] + subscribedChannels[index ..]
		subscribedChannelsStartTime = subscribedChannelsStartTime[.. index] + subscribedChannelsStartTime[index ..]
		subscribedChannelsDuration = subscribedChannelsDuration[.. index] + subscribedChannelsDuration[index ..]

		return True
	End Method
	

	Method IsActive:int()
		'for now we only check "launched" but satellites could need a repair...
		return launched
	End Method


	Method IsLaunched:int()
		return launched
	End Method


	Method Launch:int()
		if launched then return False

		launched = True

		GetStationMapCollection().OnLaunchSatellite(self)

		print "Launching satellite ~q"+name+"~q. Reach:" + GetReach()

		return True
	End Method
		

	Method Update()
		if not launched
			if launchTime < GetWorldTime().GetTimeGone()
				Launch()
			endif
		endif

		For local i:int = 0 until subscribedChannels.length
			if subscribedChannels[i] and subscribedChannelsDuration[i] >= 0
				if subscribedChannelsStartTime[i] + subscribedChannelsDuration[i] < GetWorldTime().GetTimeGone()
					local channelID:int = subscribedChannels[i]

					UnsubscribeChannel(channelID)

					'(indirectly) inform concerning stationlink
					GetStationMapCollection().RemoveSatelliteLinkFromSatellite(self, channelID)
				endif
			endif
		Next
	End Method
End Type