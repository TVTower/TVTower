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
Import "Dig/base.util.longintmap.bmx"
Import "Dig/base.util.time.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.framework.entity.bmx"
Import "game.gamerules.bmx"
Import "game.player.difficulty.bmx"
Import "game.player.color.bmx"
Import "game.player.finance.bmx"
Import "game.publicimage.bmx"
Import "game.pressuregroup.bmx"
Import "basefunctions.bmx"
Import "common.misc.numericpairinterpolator.bmx"
Import "game.gameeventkeys.bmx"
Import "game.world.worldtime.bmx"
Import "game.stationmap.densitydata.bmx"


'parent of all stationmaps
Type TStationMapCollection
	Field mapInfo:TStationMapInfo {nosave}

	Field sections:TStationMapSection[]
	'section name of all satellite uplinks
	Field satelliteUplinkSectionName:String

	'list of stationmaps
	Field stationMaps:TStationMap[0]
	'radius in "kilometers"
	Field antennaStationRadius:Int = ANTENNA_RADIUS_NOT_INITIALIZED
	
	Field population:Int = 0 'remove
	'satellites currently in orbit
	Field satellites:TList
	Field cableNetworks:TList

	Field config:TData = New TData
	Field cityNames:TData = New TData
	Field sportsData:TData = New TData

	'when were last population/receiver-share-values measurements done?
	Field lastCensusTime:Long = -1
	Field nextCensusTime:Long = -1

	Field mapConfigFile:String = ""
	'caches
	'the adjusted density map (only show "high pop"-areas)
	Field _populationDensityOverlay:TImage {nosave}
	Field _currentPopulationAntennaShare:Double = -1 {nosave}
	Field _currentPopulationCableShare:Double = -1 {nosave}
	Field _currentPopulationSatelliteShare:Double = -1 {nosave}
	'attention: the interpolation function hook is _not_ saved in the
	'           savegame
	'           So make sure to tackle this when saving share data!
	Field populationAntennaShareData:TNumericPairInterpolator {nosave}
	Field populationCableShareData:TNumericPairInterpolator {nosave}
	Field populationSatelliteShareData:TNumericPairInterpolator {nosave}
	
	'surface (boundaries) for complete map, not just single sections
	Field surfaceData:TStationMapSurfaceData {nosave}

	Const ANTENNA_RADIUS_NOT_INITIALIZED:Int = -1

	Global _initDone:Int = False
	Global _instance:TStationMapCollection


	Method New()
		If Not _initDone
			'handle savegame loading (reload the map configuration)
			EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onSaveGameLoad)
			'handle activation of stations
			EventManager.registerListenerFunction(GameEventKeys.Station_OnSetActive, onSetStationActiveState)
			EventManager.registerListenerFunction(GameEventKeys.Station_OnSetInactive, onSetStationActiveState)
			'handle activation of broadcast providers
			EventManager.registerListenerFunction(GameEventKeys.BroadcastProvider_OnLaunch, onSetBroadcastProviderActiveState)
			EventManager.registerListenerFunction(GameEventKeys.BroadcastProvider_OnSetActive, onSetBroadcastProviderActiveState)
			EventManager.registerListenerFunction(GameEventKeys.BroadcastProvider_OnSetInactive, onSetBroadcastProviderActiveState)

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

		'remove and recreate all satellites and cable networks
		ResetSatellites()
		ResetCableNetworks()


		population:Int = 0
		config = New TData
		cityNames = New TData
		sportsData = New TData
		lastCensusTime = -1
		nextCensusTime = -1
		mapConfigFile = ""
		'caches
		_currentPopulationAntennaShare = -1
		_currentPopulationCableShare = -1
		_currentPopulationSatelliteShare = -1
	End Method


	Method GetMapName:String()
		Return config.GetString("name", "UNKNOWN")
	End Method


	Method GetMapISO3166Code:String()
		Return config.GetString("iso3166code", "UNK")
	End Method


	'Percentage of receipients using an antenna
	'return a (cached) value of the current share
	Method GetCurrentPopulationAntennaShare:Double()
		If _currentPopulationAntennaShare < 0
			_currentPopulationAntennaShare = GetPopulationAntennaShare()
		EndIf
		Return _currentPopulationAntennaShare
	End Method


	'Percentage of receipients using a cable network uplink
	'return a (cached) value of the current share
	Method GetCurrentPopulationCableShare:Double()
		If _currentPopulationCableShare < 0
			_currentPopulationCableShare = GetPopulationCableShare()
		EndIf
		Return _currentPopulationCableShare
	End Method


	'Percentage of receipients using a satellite dish / uplink
	'return a (cached) value of the current share
	Method GetCurrentPopulationSatelliteShare:Double()
		If _currentPopulationSatelliteShare < 0
			_currentPopulationSatelliteShare = GetPopulationSatelliteShare()
		EndIf
		Return _currentPopulationSatelliteShare
	End Method


	'returns the antenna share for the given screen coordinate
	Method GetPopulationAntennaShare:Float(dataX:Int, dataY:Int)
		Local section:TStationMapSection = GetSectionByDataXY(dataX, dataY)
		If section then Return section.GetPopulationAntennaShareRatio()

		Return GetCurrentPopulationAntennaShare()
	End Method


	Method GetPopulationAntennaShare:Double(time:Long = -1)
		If Not populationAntennaShareData Then LoadPopulationShareData()

		If time = -1 Then time = GetWorldTime().GetTimeGone()

		Return populationAntennaShareData.GetInterpolatedValue( time )
	End Method


	Method GetPopulationCableShare:Double(time:Long = -1)
		If Not populationCableShareData Then LoadPopulationShareData()

		If time = -1 Then time = GetWorldTime().GetTimeGone()

		Return populationCableShareData.GetInterpolatedValue( time )
	End Method


	Method GetPopulationSatelliteShare:Double(time:Long = -1)
		If Not populationSatelliteShareData Then LoadPopulationShareData()

		If time = -1 Then time = GetWorldTime().GetTimeGone()

		Return populationSatelliteShareData.GetInterpolatedValue( time )
	End Method


	Method GetLastCensusTime:Long()
		Return lastCensusTime
	End Method


	Method GetNextCensusTime:Long()
		Return nextCensusTime
	End Method


	Method DoCensus()
		'reset caches
		_currentPopulationAntennaShare = -1
		_currentPopulationCableShare = -1
		_currentPopulationSatelliteShare = -1

		'generate cache if needed reach-values
		UpdateSections()

		For Local section:TStationMapSection = EachIn sections
			section.DoCensus()
		Next

		For Local stationMap:TStationMap = EachIn stationMaps
			stationMap.DoCensus()
		Next

		'also update shares (incorporate tech upgrades of satellites etc)
		UpdateCableNetworkSharesAndQuality()
		UpdateSatelliteSharesAndQuality()

		'if no census was done, do as if it was done right on game start
		If lastCensusTime = -1
			lastCensusTime = GetWorldTime().GetTimeStart()
		Else
			lastCensusTime = GetWorldTime().GetTimeGone()
		EndIf
	End Method


	Method GetAveragePopulationAntennaShare:Float()
		If Not sections Or sections.Length = 0 Then Return 0

		Local result:Float
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetPopulationAntennaShareRatio()
			Rem
			if section.populationAntennaShare < 0
				result :+ GetCurrentPopulationAntennaShare()
			else
				result :+ section.populationAntennaShare
			endif
			endrem
		Next
		Return result / sections.Length
	End Method


	Method GetAveragePopulationCableShare:Float()
		If Not sections Or sections.Length = 0 Then Return 0

		Local result:Float
		For Local section:TStationMapSection = EachIn sections
			If section.populationCableShare < 0
				result :+ GetCurrentPopulationCableShare()
			Else
				result :+ section.populationCableShare
			EndIf
		Next
		Return result / sections.Length
	End Method


	Method GetAveragePopulationSatelliteShare:Float()
		If Not sections Or sections.Length = 0 Then Return 0

		Local result:Float
		For Local section:TStationMapSection = EachIn sections
			If section.populationSatelliteShare < 0
				result :+ GetCurrentPopulationSatelliteShare()
			Else
				result :+ section.populationSatelliteShare
			EndIf
		Next
		Return result / sections.Length
	End Method


	Method GetSatelliteUplinkSectionName:String()
		If Not satelliteUplinkSectionName
			If Not sections Or sections.Length = 0 Then Return ""

			Local randomSection:TStationMapSection = TStationMapSection(sections[RandRange(0, sections.Length-1)])
			If randomSection
				satelliteUplinkSectionName = randomSection.name
			EndIf
		EndIf
		Return satelliteUplinkSectionName
	End Method


	'return population reached by this antenna taking into consideration
	'whether to exclude/ignore own or other channels' antennas
	'(this ignores cable networks and satellites as receiver type is distinct)
	Method GetAntennaPopulation:int(densityX:Int, densityY:int, radius:Int, owner:Int, alreadyBuilt:Int = True, exclusiveToOwnChannel:Int = False, exclusiveToOtherChannels:Int = False)
		If not surfaceData Then Throw "TStationMapCollection.GetAntennaExclusivePopulation: Cannot calculate population without surface data"

		Local result:Int

		'data is "densitydata based"!
		'ensure rect fits into surfaceData AND densityData
		'circle coordinates are "local" to mapInfo.densityData
		Local circleRectX:Int = Max(0, densityX - radius)
		Local circleRectY:Int = Max(0, densityY - radius)
		Local circleRectX2:Int = Min(densityX + radius, Min(surfaceData.width-1, mapInfo.densityData.width-1))
		Local circleRectY2:Int = Min(densityY + radius, Min(surfaceData.height-1, mapInfo.densityData.height-1))
		Local radiusSquared:Int = radius * radius

		Local antennaLayers:TStationMapAntennaLayer[4]
		Local otherAntennaLayersUsed:int
		
		'no owner specified?
		If owner = 0
			exclusiveToOwnChannel = False
			exclusiveToOtherChannels = False
		Endif

		'iterate over all players and fetch layers (if needed
		for local i:int = 1 to 4
			If (exclusiveToOwnChannel and i = owner) or (exclusiveToOtherChannels and i <> owner)
				antennaLayers[i-1] = GetStationMap(i)._GetAllAntennasLayer()
			EndIf
		Next
		
		Local checkValue:Int = 0 'nobody there
		if alreadyBuilt Then checkValue = 1 'only this very antenna is there
	
		'data window and circle do not overlap?
		If circleRectX2 < circleRectX Then Return 0
		If circleRectY2 < circleRectY Then Return 0

rem
		For Local posX:Int = circleRectX To circleRectX2
			For Local posY:Int = circleRectY To circleRectY2
				'left the circle?
				If CalculateDistanceSquared(posX - densityX, posY - densityY) > radiusSquared Then Continue
endrem
		For local posX:Int = circleRectX until circleRectX2
			'calculate height of the circle"slice"
			Local circleLocalX:Int = posX - densityX
			Local currentCircleH:Int = sqr(radiusSquared - circleLocalX * circleLocalX)

			For local posY:Int = Max(densityY - currentCircleH, circleRectY) until Min(densityY + currentCircleH, circleRectY2)

				'left the topographic borders ?
				'coords are local to (complete map) surfaceData
				If surfaceData.data[posY * surfaceData.width + posX] = 0 Then Continue


				'owner already broadcasting with more than this looked
				'up antenna (in case of already "owned")?
				If exclusiveToOwnChannel 
					If antennaLayers[owner-1].data[posY * antennaLayers[owner-1].width + posX] > checkValue Then Continue
				EndIf
				'others broadcasting there?
				If exclusiveToOtherChannels
					if 1<>owner and antennaLayers[0] and antennaLayers[0].data[posY * antennaLayers[0].width + posX] > 0 Then Continue
					if 2<>owner and antennaLayers[1] and antennaLayers[1].data[posY * antennaLayers[1].width + posX] > 0 Then Continue
					if 3<>owner and antennaLayers[2] and antennaLayers[2].data[posY * antennaLayers[2].width + posX] > 0 Then Continue
					if 4<>owner and antennaLayers[3] and antennaLayers[3].data[posY * antennaLayers[3].width + posX] > 0 Then Continue
				EndIf
				
				result :+ mapInfo.densityData.data[posY * mapInfo.densityData.width + posX]
			Next
		Next		
		Return result
	End Method



	Method GetAntennaReceivers:Int(dataX:Int, dataY:Int, radius:Int)
		Local share:Float = GetPopulationAntennaShare(dataX, dataY)
		'owner is 0 here ... as we ignore other stations anyways
		Return GetAntennaPopulation(dataX, dataY, radius, 0) * share
	End Method


	Method GetAntennaReceivers:Int(playerID:Int)
		Local result:Int
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaReceivers(playerID)
		Next
		Return result
	End Method


	'return population covered with antennas of the specified player
	Method GetAntennaPopulation:Int(playerID:Int)
		Local result:Int
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaPopulation(playerID)
		Next
		Return result
	End Method


	'return receivers only reached by the specified channel/player
	'(this ignores cable networks and satellites as receiver type is distinct)
	Method GetChannelExclusiveAntennaReceivers:Int(playerID:Int)
		Local result:Int
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetChannelExclusiveAntennaReceivers(playerID)
		Next
		Return result
	End Method


	Method GetFirstCableNetworkBySection:TStationMap_CableNetwork(section:TStationMapSection)
		If Not section Then Return Null
		Return GetFirstCableNetworkBySectionName(section.name)
	End Method


	Method GetFirstCableNetworkBySectionName:TStationMap_CableNetwork(sectionName:String)
		If cableNetworks.count() = 0 Then Return Null

		For Local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			If cableNetwork.sectionName = sectionName Then Return cableNetwork
		Next

		Return Null
	End Method


	Method GetCableNetworksInSectionCount:Int(sectionName:String, onlyLaunched:Int=True)
		Local result:Int = 0

		For Local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			If cableNetwork.sectionName = sectionName
				If Not onlyLaunched Or cableNetwork.IsLaunched() Then result :+ 1
			EndIf
		Next

		Return result
	End Method


	Method GetCableNetworkCount:Int()
		Return cableNetworks.Count()
	End Method


	Method GetCableNetworkAtIndex:TStationMap_CableNetwork(index:Int)
		If cableNetworks.count() <= index Or index < 0 Then Return Null

		Return TStationMap_CableNetwork( cableNetworks.ValueAtIndex(index) )
	End Method


	Method GetCableNetwork:TStationMap_CableNetwork(cableNetworkGUID:String)
		For Local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			If cableNetwork.GetGUID() = cableNetworkGUID Then Return cableNetwork
		Next

		Return Null
	End Method


	Method GetCableNetwork:TStationMap_CableNetwork(cableNetworkID:Int)
		For Local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			If cableNetwork.GetID() = cableNetworkID Then Return cableNetwork
		Next

		Return Null
	End Method


	'summary: returns receiver count ("possible audience") reached with the given cable network uplinks
	Method GetCableNetworkUplinkReceivers:Int(stations:TObjectList)
		Local result:Int
		For Local station:TStationCableNetworkUplink = EachIn stations
			result :+ station.GetReceivers()
		Next
		Return result
	End Method


	'summary: returns maximum cable network receivers reached by the given player
	Method GetCableNetworkUplinkReceivers:Int(playerID:Int)
		Local map:TStationMap = GetMap(playerID)
		If Not map Then Return 0
		Return GetCableNetworkUplinkReceivers(map.stations)
	End Method


	'summary: returns population reached with the given cable network uplinks
	Method GetCableNetworkUplinkPopulation:Int(stations:TObjectList)
		Local result:Int
		For Local station:TStationCableNetworkUplink = EachIn stations
			result :+ station.GetPopulation()
		Next
		Return result
	End Method


	'summary: returns maximum cable network population reached by the given player
	Method GetCableNetworkUplinkPopulation:Int(playerID:Int)
		Local map:TStationMap = GetMap(playerID)
		If Not map Then Return 0
		Return GetCableNetworkUplinkPopulation(map.stations)
	End Method


	'summary: returns maximum receivers reached with the given satellite uplinks
	Method GetSatelliteUplinkReceivers:Int(stations:TObjectList)
		Local result:Int
		For Local satLink:TStationSatelliteUplink = EachIn stations
			result :+ satLink.GetReceivers()
		Next
		Return result
	End Method


	'summary: returns maximum satellite receivers/audience reached by the given player
	Method GetSatelliteUplinkReceivers:Int(playerID:Int)
		Local map:TStationMap = GetMap(playerID)
		If Not map Then Return 0
		Return GetSatelliteUplinkReceivers(map.stations)
	End Method


	'summary: returns population reached with the given satellite uplinks
	Method GetSatelliteUplinkPopulation:Int(stations:TObjectList)
		Local result:Int
		'Attention: satellites share population (but they do not 
		'share receivers) so do NOT simply sum up "GetPopulation()"
		'
		'"GetExclusivePopulation()" would return population the uplink
		'covers without any other station (so also antennas) which means
		'it is also not of use.
		'
		'All satellites have the same population but each section has
		'their own "share" on how many people have chosen to use sat
		'uplinks (compared to cable or antennas) 
		'
		'As long as at least ONE satellite uplink is existing, the
		'possible population is the sum of all sections' sat uplink population
		'(if somewhen uplinks do not reach all sections, then all reached
		'sections need to be collected (without duplicates) and then
		'their covered population needs to be sum'd up)
		
		Local hasUplink:Int = False
		For local s:TStationSatelliteUplink = EachIn stations
			hasUplink = True
			exit
		Next
		
		If hasUplink
			For Local section:TStationMapSection = EachIn sections
				result :+ section.GetSatelliteUplinkPopulation()
			Next
		EndIf

		Return result
	End Method


	'summary: returns population reached with the given satellite uplinks
	Method GetSatelliteUplinkPopulation:Int(playerID:Int)
		Local map:TStationMap = GetMap(playerID)
		If Not map Then Return 0
		Return GetSatelliteUplinkPopulation(map.stations)
	End Method


	Method GetSatelliteCount:Int()
		Return satellites.Count()
	End Method


	Method GetSatelliteAtIndex:TStationMap_Satellite(index:Int)
		If satellites.count() <= index Or index < 0 Then Return Null

		Return TStationMap_Satellite( satellites.ValueAtIndex(index) )
	End Method


	Method GetSatellite:TStationMap_Satellite(satelliteGUID:String)
		For Local satellite:TStationMap_Satellite = EachIn satellites
			If satellite.GetGUID() = satelliteGUID Then Return satellite
		Next

		Return Null
	End Method


	Method GetSatellite:TStationMap_Satellite(satelliteID:Int)
		For Local satellite:TStationMap_Satellite = EachIn satellites
			If satellite.GetID() = satelliteID Then Return satellite
		Next

		Return Null
	End Method


	Method GetSatelliteIndex:Int(satelliteID:String)
		Local i:Int = 0
		For Local satellite:TStationMap_Satellite = EachIn satellites
			i :+ 1
			If satellite.GetID() = satelliteID Then Return i
		Next
		Return -1
	End Method


	Function GetSatelliteUplinksCount:Int(stations:TObjectList, onlyActive:Int = False, includeShutdown:Int = False)
		Local result:Int
		For Local station:TStationSatelliteUplink = EachIn stations
			'skip inactive or shut down ones?
			if onlyActive and not station.IsActive() Then continue
			if not includeShutdown and station.IsShutdown() Then continue
			result :+ 1
		Next
		Return result
	End Function


	Function GetCableNetworkUplinksInSectionCount:Int(stations:TObjectList, sectionName:String, onlyActive:Int = False, includeShutdown:Int = False)
		Local result:Int

		For Local station:TStationCableNetworkUplink = EachIn stations
			'skip inactive or shut down ones?
			if onlyActive and not station.IsActive() Then continue
			if not includeShutdown and station.IsShutdown() Then continue

			If station.GetSectionName() = sectionName
				result :+ 1
			EndIf
		Next
		Return result
	End Function


	'Returns amount of stations linked to a specific provider
	'(eg. satellite uplinks to a specific satellite)
	Function GetStationsToProviderCount:Int(stations:TObjectList, providerID:Int, includeActive:Int = False, includeShutdown:Int = False)
		Local result:Int

		For Local station:TStationCableNetworkUplink = EachIn stations
			'skip inactive or shut down ones?
			if not includeActive and station.IsActive() Then continue
			if not includeShutdown and station.IsShutdown() Then continue

			If station.providerID = providerID
				result :+ 1
			EndIf
		Next
		Return result
	End Function


	Method GetChannelExclusiveReceivers:Int(channelNumber:Int)
		Local result:Int
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetChannelExclusiveReceivers(channelNumber)
		Next
		Return result
	End Method


	'receivers in the whole map
	Method GetReceivers:Int()
		Local receiverShare:Float
		receiverShare :+ GetCurrentPopulationAntennaShare()
		receiverShare :+ GetCurrentPopulationSatelliteShare()
		receiverShare :+ GetCurrentPopulationCableShare()
		Return receiverShare * GetPopulation()
	End Method


	'receivers of a channel
	Method GetReceivers:Int(channelNumber:Int)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(channelNumber)
		'empty exclude mask as we are not looking for EXCLUSIVE receivers,
		'we just want to know the total amount for the channel
		Return GetReceiverShare(New SChannelMask().Set(channelNumber), Null).shared
	End Method


	'receivers of a specified channel/group of channel without to-exclude channels
	Method GetReceivers:Int(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'return ".total" if you want to know what the "total amount" is
		'(so the sum of different people all "include channels" reach together)
		
		'return ".shared" if you want to know the population the 
		'"include channels" share between each other (exclusive to the 
		'excluded channels)
		Return GetReceiverShare(includeChannelMask, excludeChannelMask).shared
	End Method


	Method GetReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare

		'either
		'ATTENTION: contains only cable and antenna
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetReceiverShare(includeChannelMask, excludeChannelMask)
		Next

		Return result
	End Method


	Method GetAntennaReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaReceiverShare(includeChannelMask, excludeChannelMask)
		Next

		Return result
	End Method


	Method GetCableNetworkUplinkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetCableNetworkUplinkReceiverShare(includeChannelMask, excludeChannelMask)
		Next

		Return result
	End Method


	'returns a share between channels, encoded in a SStationMapPopulationShare
	Method GetSatelliteUplinkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetSatellitesReceiverShare(includeChannelMask, excludeChannelMask)
	End Method
	

	'returns a share between channels, encoded in a SStationMapPopulationShare
	Method GetSatellitesReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		'no channel requested?
		If includeChannelMask.value = 0 Then Return result

		For Local satellite:TStationMap_Satellite = EachIn satellites
			Local satResult:SStationMapPopulationShare = GetSatelliteReceiverShare(satellite, includeChannelMask, excludeChannelMask)

			If satResult.total > 0
				result.total :+ satResult.total
				result.shared :+ satResult.shared
			EndIf

		Next

		Return result
	End Method


	Method GetSatelliteReceiverShare:SStationMapPopulationShare(satellite:TStationMap_Satellite, includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		Local includedChannelsUsingThisSatellite:Int = 0
		Local excludedChannelsUsingThisSatellite:Int = 0
		
		If not satellite Then return result

		'count how many of the "mentioned" channels have at least
		'one active uplink there
		For Local channelID:Int = 1 To stationMaps.Length
			If includeChannelMask.Has(channelID) And satellite.IsSubscribedChannel(channelID)
				Local uplink:TStationSatelliteUplink = TStationSatelliteUplink( GetStationMap(channelID).GetSatelliteUplink(satellite) )
				If uplink and uplink.CanBroadcast()
					includedChannelsUsingThisSatellite :+ 1
				EndIf
			ElseIf excludeChannelMask.Has(channelID) And satellite.IsSubscribedChannel(channelID)
				Local uplink:TStationSatelliteUplink = TStationSatelliteUplink( GetStationMap(channelID).GetSatelliteUplink(satellite) )
				If uplink and uplink.CanBroadcast()
					excludedChannelsUsingThisSatellite :+ 1
				EndIf
			EndIf
		Next


		If includedChannelsUsingThisSatellite > 0
			Local receivers:Int = satellite.GetReceivers()
			'total - if at least _one_ channel uses the satellite
			result.total = receivers

			'all included channels need to have an uplink ("and" instead of "or" connection)
			If includedChannelsUsingThisSatellite = includeChannelMask.GetEnabledCount()
				'as soon as one "excluded" has an uplink there, we know
				'the "included" won't be exclusive
				'(with only 1 satellite you cannot only use 50% of it)
				If excludedChannelsUsingThisSatellite = 0
					result.shared = receivers
				EndIf
			EndIf
		EndIf

		return result 
	End Method


	Method GetRandomAntennaCoordinateInSections:SVec2I(sectionNames:String[], allowSectionCrossing:Int = True)
		If sectionNames.Length = 0 Then Return Null

		Local sectionName:String = sectionNames[ Rand(0, sectionNames.Length-1) ]
		Return GetRandomAntennaCoordinateInSection(sectionName, allowSectionCrossing)
	End Method


	Method GetRandomAntennaCoordinateInSections:SVec2I(sections:TStationMapSection[], allowSectionCrossing:Int = True)
		If sections.Length = 0 Then Return Null

		Local section:TStationMapSection = sections[ Rand(0, sections.Length-1) ]
		Return GetRandomAntennaCoordinateInSection(section, allowSectionCrossing)
	End Method
	

	Method GetRandomAntennaCoordinateInSection:SVec2I(sectionName:String, allowSectionCrossing:Int = True)
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
		Return GetRandomAntennaCoordinateInSection(section)
	End Method

	Method GetRandomAntennaCoordinateInSection:SVec2I(section:TStationMapSection, allowSectionCrossing:Int = True)
		If Not section Then Return Null 

		Local found:Int = False
		Local mapX:Int = 0
		Local mapY:Int = 0
		Local tries:Int = 0

		Local sectionPix:TPixmap
		Local sprite:TSprite = section.GetShapeSprite()
		If Not sprite Then Return New SVec2I(-1, -1)
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()

		Repeat
			'find random spot on "map"
			mapX = RandRange(section.rect.GetIntX(), section.rect.GetIntX2())
			mapY = RandRange(section.rect.GetIntY(), section.rect.GetIntY2())

			'check if spot in local space is on an opaque/colliding pixel
			If PixelIsOpaque(sprite._pix, mapX - section.rect.GetIntX(), mapY - section.rect.GetIntY()) > 0
				found = True
				'check if other map sections have an opaque pixel there too (ambiguity!)
				If Not allowSectionCrossing
					For Local otherSection:TStationMapSection = EachIn sections
						If section = otherSection Then Continue
						Local otherLocalX:Int = Int(mapX - otherSection.rect.GetX())
						Local otherLocalY:Int = Int(mapY - otherSection.rect.GetY())
						Local otherSprite:TSprite = otherSection.GetShapeSprite()
						If otherSprite 
							If Not otherSprite._pix Then otherSprite._pix = otherSprite.GetPixmap()

							If otherLocalX >= 0 And otherLocalY >= 0 And otherLocalX < otherSection.rect.GetIntW() And otherLocalY < otherSection.rect.GetIntH()
								If PixelIsOpaque(otherSprite._pix, otherLocalX, otherLocalY) > 0
									found = False
									'print "try # " + tries + "  " + section.name +": other section " + otherSection.name + " is opaque too!!   xy="+(x - section.rect.GetIntX())+", "+(y - section.rect.GetIntY()) + "   otherXY="+otherX+", "+otherY
								EndIf
							EndIf
						EndIf
					Next
				EndIf
			EndIf
			tries :+ 1
		Until found Or tries > 1000

		If tries > 1000 
			TLogger.Log("GetRandomAntennaCoordinateInSection()", "Failed to find a valid random section point in < 1000 tries.", LOG_ERROR)
			Return New SVec2I(-1, -1)
		EndIf
		
		If found
			Return New SVec2I(mapX, mapY)
		EndIf
		
		Return New SVec2I(-1, -1)
	End Method


	Method GetOverlappingAntennas:TStationAntenna[](antenna:TStationAntenna)
		Local result:TStationAntenna[]
		For Local map:TStationMap = EachIn stationMaps
			result :+ map.GetOverlappingAntennas(antenna)
		Next
		Return result
	End Method


	Method GetPopulationDensityOverlayRawPixmap:TPixmap(emphasizePopulation:int = False)
		Local pix:TPixmap = CreatePixmap(mapInfo.densityData.width, mapInfo.densityData.height, PF_RGBA8888)
		pix.ClearPixels(0)
		Local maxPop:Float = mapInfo.densityData.maxPopulationDensity
		if maxPop = 0 Then maxPop = 100
		For local x:Int = 0 until mapInfo.densityData.width
			For local y:Int = 0 until mapInfo.densityData.height
				Local value:Int = 255 * mapInfo.densityData.data[y * mapInfo.densityData.width + x] / maxPop
				Local layerColor:Int = (Int(255*(value<>0) * $1000000) + Int(value * $10000) + Int(value * $100) + Int(value))
				If emphasizePopulation 
					value = Min((3*value)^1.2, 255) 
					layerColor = (Int(((value>0)*55 + Min(1.5*value^1.5, 200)) * $1000000) + Int(value * $10000) + Int(value * $100) + Int(value))
				EndIf
				pix.WritePixel(x, y, layerColor)
			Next
		Next
		Return pix
	End Method
	

	Method GetPopulationDensityOverlay:TImage()
		If Not _populationDensityOverlay Or _populationDensityOverlay.width <> mapInfo.screenMapSize.x Or _populationDensityOverlay.height <> mapInfo.screenMapSize.y
			'scale data to screen size -> already done by directly using the scaled data
			'_populationDensityOverlay = LoadImage(ResizePixmap(pix, Int(pix.width * mapInfo.densityDataScreenScale), Int(pix.height * mapInfo.densityDataScreenScale)))
			'_populationDensityOverlay = LoadImage(GetPopulationDensityOverlayRaxPixmap(True))
			Local pix:TPixmap = GetPopulationDensityOverlayRawPixmap(True)
			'Local newX:Int = mapInfo.screenMapSize.x 'OR: Int(pix.width * mapInfo.densityDataScreenScale + 0.5)
			'Local newY:Int = mapInfo.screenMapSize.y 'OR: Int(pix.height * mapInfo.densityDataScreenScale + 0.5)
			_populationDensityOverlay = LoadImage(ResizePixmap(pix, mapInfo.screenMapSize.x, mapInfo.screenMapSize.y))
		EndIf
		Return _populationDensityOverlay
	End Method
	
	
	Method GetPopulationDensityOverlayXY:SVec2I()
		Return new SVec2I(mapInfo.surfaceScreenOffset.x + mapInfo.densityDataOnSurfaceOffset.x, mapInfo.surfaceScreenOffset.y + mapInfo.densityDataOnSurfaceOffset.y)
	End Method
	

	Method LoadPopulationShareData:Int()
		Rem
		ANTENNAS:
		http://www.spiegel.de/spiegel/print/d-13508831.html
		-> 1984 50% of 22 Mio western households via (collective antenna)

		CABLE NETWORK
		cable network share development
		-> this is _potential_ reach, not numbers actually using cable
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


		https://www.bpb.de/system/files/dokument_pdf/NuN_14_Medienausstattung%20Fernsehnutzung.pdf
		-> 1990 60% antenna    7% satellite   34% cable
		-> 2000  5% antenna   45% satellite   50% cable


		SATELLITES
		satellites "TV-Sat 1", "TV-Sat 2", "Télécom 1", "Télécom 2" in second half of 80s
		(GDR: receiving of western satellites forbidden: sat dishes mounted "non-orientable")
		astra since 1988


		Anteile der verschiedenen Übertragungswege* an den TV-Haushalten in Deutschland von 2008 bis 2017
		(paid content - accessed via university)
		https://de.statista.com/statistik/daten/studie/180632/umfrage/anteil-der-tv-haushalte-mit-satellitenempfang-in-deutschland-seit-2005/


		Anzahl der Kabel-TV-Haushalte in Deutschland von 2008 bis 2017 (in Millionen)
		(paid content - accessed via university)
		https://de.statista.com/statistik/daten/studie/203096/umfrage/anzahl-der-kabelanschluesse-in-deutschland-seit-2008/
		END REM

		populationAntennaShareData = New TNumericPairInterpolator
		populationCableShareData = New TNumericPairInterpolator
		populationSatelliteShareData = New TNumericPairInterpolator

		'ATTENTION: sum MUST be <= 100%
		'give it a start for interpolating from "unknown" to "known" data
		populationAntennaShareData.insert(YearTime(1955), 0.20)
		populationCableShareData.insert(YearTime(1955), 0.00)
		populationSatelliteShareData.insert(YearTime(1955), 0.00)

		'includes dvb't
		populationAntennaShareData.insert(YearTime(1982), 0.46)
		populationAntennaShareData.insert(YearTime(1990), 0.60)
		populationAntennaShareData.insert(YearTime(2000), 0.07) '0.05
		populationAntennaShareData.insert(YearTime(2008), 0.11)
		populationAntennaShareData.insert(YearTime(2012), 0.12)
		populationAntennaShareData.insert(YearTime(2017), 0.07)

		populationSatelliteShareData.insert(YearTime(1982), 0.00)
		populationSatelliteShareData.insert(YearTime(1984), 0.01)
		populationSatelliteShareData.insert(YearTime(1990), 0.07)
		populationSatelliteShareData.insert(YearTime(2000), 0.36)
		populationSatelliteShareData.insert(YearTime(2005), 0.41) '0.44 '16,4 mio households
		populationSatelliteShareData.insert(YearTime(2008), 0.39) '0.42 '16,4 mio households
		populationSatelliteShareData.insert(YearTime(2013), 0.42) '0.46 '16,4 mio households
		populationSatelliteShareData.insert(YearTime(2015), 0.43) '0.47 '17,7 mio households
		populationSatelliteShareData.insert(YearTime(2017), 0.42) '0.46

		populationCableShareData.insert(YearTime(1982), 0.02)
		populationCableShareData.insert(YearTime(1986), 0.07)
		populationCableShareData.insert(YearTime(1990), 0.31)
'		populationCableShareData.insert(YearTime(1993), 0.60)
'		populationCableShareData.insert(YearTime(1995), 0.65) '= 15,8 Mio Households
		populationCableShareData.insert(YearTime(2000), 0.47) '0.50
		populationCableShareData.insert(YearTime(2008), 0.49) '0.52
		populationCableShareData.insert(YearTime(2011), 0.47) '0.50
		populationCableShareData.insert(YearTime(2015), 0.45)
		populationCableShareData.insert(YearTime(2017), 0.44)

		Rem
		'debug output
		For local y:int = 1980 to 2017
			local t:Long = YearTime(y)
			local a:Double = populationAntennaShareData.GetInterpolatedValue(t)
			local c:Double = populationCableShareData.GetInterpolatedValue(t)
			local s:Double = populationSatelliteShareData.GetInterpolatedValue(t)
			local sum:Double = a + c + s
			print "year="+y+"  antenna="+ Rset(TFunctions.LocalizedNumberToString(a*100,1),5)+"%"+"  cable="+Rset(TFunctions.LocalizedNumberToString(c*100,1),5)+"%"+"  satellite="+RSet(TFunctions.LocalizedNumberToString(s,1),5)+"%"+ "   sum="+RSet(TFunctions.LocalizedNumberToString(sum*100,1),6)+"%"
		Next
		end
		endrem

		Function YearTime:Long(year:Int)
'		return year
			Return GetWorldTime().GetTimeGoneForGameTime(year, 0, 0, 0, 0)
		End Function

		Return True
	End Method


	'=== EVENT HANDLERS ===

	'as soon as a station gets active (again), the sharemap has to get
	'regenerated (for a correct audience calculation)
	'also stationmaps can recalculate their reaches
	Function onSetStationActiveState:Int(triggerEvent:TEventBase)
		Local station:TStationBase = TStationBase(triggerEvent.GetSender())
		If Not station Then Return False

		'invalidate (cached) share data of surrounding sections
		For Local s:TStationMapSection = EachIn GetInstance().GetSectionsConnectedToStation(station)
			s.InvalidateData()
		Next

		'inform owning stationmap (so eg. to invalidate reach-calculation
		'caches)
		If triggerEvent.GetEventKey() = GameEventKeys.Station_OnSetActive
			GetStationMap(station.owner).OnChangeStationActiveState(station, True)
		ElseIf triggerEvent.GetEventKey() = GameEventKeys.Station_OnSetInactive
			GetStationMap(station.owner).OnChangeStationActiveState(station, False)
		EndIf
	
		Return True
	End Function


	'as soon as a broadcast provider (cable network, satellite) gets
	'inactive/active (again) caches have to get regenerated
	Function onSetBroadcastProviderActiveState:Int(triggerEvent:TEventBase)
		Local broadcastProvider:TStationMap_BroadcastProvider = TStationMap_BroadcastProvider(triggerEvent.GetSender())
		If Not broadcastProvider Then Return False

		'refresh cached count statistics
		If TStationMap_CableNetwork(broadcastProvider) Then _instance.RefreshSectionsCableNetworkCount()

		Return True
	End Function


	'run when loading finished
	Function onSaveGameLoad:Int(triggerEvent:TEventBase)
		TLogger.Log("TStationMapCollection", "Savegame loaded - reloading map data", LOG_DEBUG | LOG_SAVELOAD)

		'reload map configuration
		_instance.LoadMapFromXML()

		Local savedSaveGameVersion:Int = triggerEvent.GetData().GetInt("saved_savegame_version")
		'pre 0.7.3
		If savedSaveGameVersion < 18
			TLogger.Log("TStationMapCollection", "Ensuring initial cable network shares are set", LOG_DEBUG | LOG_SAVELOAD)
			For Local c:TStationMap_CableNetwork = EachIn _instance.cableNetworks
				c.populationShare = 1.0
			Next
		EndIf

		'initialize caches in particular for AI threads
		For Local map:TStationMap = EachIn _instance.stationMaps
			map._antennasLayer = Null
			map._GetAllAntennasLayer()
		Next

		Return True
	End Function


	Method LoadMapInformation(baseURI:String, mapDensityDataURI:String, mapCountryOffsetX:Int, mapCountryOffsetY:Int, mapSurfaceImageURI:String)
		local fullDensityDataURI:String = mapDensityDataURI
		local fullSurfaceImageURI:String = mapSurfaceImageURI
		'make it an absolute url if required
		If StripDir(fullDensityDataURI) = fullDensityDataURI
			fullDensityDataURI = baseURI + "/" + fullDensityDataURI
		EndIf
		If StripDir(fullSurfaceImageURI) = fullSurfaceImageURI
			fullSurfaceImageURI = baseURI + "/" + fullSurfaceImageURI
		EndIf
		'print "LoadMapInformation("+baseURI+")"
		'print "  fullDensityDataURI = " + fullDensityDataURI
		'print "  fullSurfaceImageURI = " + fullSurfaceImageURI
		'print "  currentDir = " + currentDir()

		Local stopWatch:TStopWatch = New TStopWatch.Init()
		self.mapInfo = New TStationMapInfo(fullDensityDataURI, New SVec2I(mapCountryOffsetX, mapCountryOffsetY), fullSurfaceImageURI)
		TLogger.Log("TStationMapCollection.LoadMapInformation", "Loaded Map information (population = " + mapInfo.densityData.totalPopulation+") in "+stopWatch.GetTime()+"ms", LOG_DEBUG | LOG_LOADING)

		'calculate stretch factors and configure used screen size
		'TODO: Werte aus XML entnehmen (topo_design_width, topo_design_height)
		mapInfo.SetScreenMapSize(509, 371)
	End Method
	

	'load a map configuration from a specific xml file
	'eg. "germany.xml"
	'we use xmlLoader so image ressources in the file get autoloaded
	Method LoadMapFromXML:Int(xmlFile:String="", baseUri:String = "")
		If xmlFile <> "" Then mapConfigFile = xmlFile

		If not mapConfigFile
			TLogger.Log("TStationMapCollection.LoadFromXML", "No file defined for loading.", LOG_ERROR)
			Throw("TStationMapCollection.LoadFromXML: No file defined for loading.")
		EndIf

		Local fullXMLFileURI:String = mapConfigFile
		If ExtractDir(baseURI) Then fullXMLFileURI = ExtractDir(baseURI) + "/" + mapConfigFile

		If FileType(fullXMLFileURI) <> FILETYPE_FILE
			TLogger.Log("TStationMapCollection.LoadFromXML", "File ~q"+fullXMLFileURI+"~q not found.", LOG_ERROR)
			Throw("TStationMapCollection.LoadFromXML: File ~q"+fullXMLFileURI+"~q not found.")
		EndIf

		Local xmlHelper:TXmlHelper = TXmlHelper.Create(fullXMLFileURI, "", False)
		Local rootNode:TxmlNode = xmlHelper.GetRootNode()
		

		'check nodes existence
		Local resourcesNode:TxmlNode = GetNodeOrThrow(rootNode, "resources", xmlFile, "Misses the <resources>-entry.")
		Local xmlStationMapNode:TxmlNode = GetNodeOrThrow(rootNode, "stationmap", xmlFile, "Misses the <stationmap>-entry.")
		Local surfaceNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "surface", xmlFile, "Misses the <stationmap><surface>-entry.")
		Local configNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "config", xmlFile, "Misses the <stationmap><config>-entry.")
		Local cityNamesNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "citynames", xmlFile, "Misses the <stationmap><citynames>-entry.")
		Local sportsDataNode:TxmlNode = TXmlHelper.FindChild(xmlStationMapNode, "sports") 'sports data is not mandatory, so simple findChild will do
		Local startAntennaNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "startantenna", xmlFile, "Misses the <stationmap><startantenna>-entry.")
		Local densityDataNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "densitydata", xmlFile, "Misses the <stationmap><densitydata>-entry.")

		'check data
		Local densityData:TData = TXmlHelper.LoadAllValuesToData(densityDataNode, New TData)
		if densityData.GetString("url", "") = "" then Throw("File ~q"+xmlFile+"~q misses the or a valid <stationmap><densitydata url>-entry.")
		Local surfaceData:TData = TXmlHelper.LoadAllValuesToData(surfaceNode, New TData)
		if surfaceData.GetString("url", "") = "" then Throw("File ~q"+xmlFile+"~q misses the or a valid <stationmap><surface url>-entry.")


		'load sprites/section images
		Local registryLoader:TRegistryLoader = New TRegistryLoader
		registryLoader.baseURI = baseURI
		registryLoader.LoadSingleResourceFromXML(resourcesNode, Null, True)


		'load the map information / density data
		Local mapConfigBaseURI:String = baseURI
		If ExtractDir(mapConfigFile) and ExtractDir(baseURI)
			mapConfigBaseURI = ExtractDir(baseURI) + "/" + ExtractDir(mapConfigFile)
		ElseIf ExtractDir(mapConfigFile)
			mapConfigBaseURI = ExtractDir(mapConfigFile)
		EndIf
		LoadMapInformation(mapConfigBaseURI, densityData.GetString("url"), densityData.GetInt("offset_x", 0), densityData.GetInt("offset_y", 0), surfaceData.GetString("url"))

		mapInfo.startAntennaSurfacePos = New SVec2I(TXmlHelper.FindValueInt(startAntennaNode, "surface_x", 0), TXmlHelper.FindValueInt(startAntennaNode, "surface_y", 0))

	
		'older savegames might contain a config which has the data converted
		'to key->value[] arrays instead of values being overridden on each load.
		'so better just clear the config
		self.config = New TData
		self.cityNames = New TData
		If sportsDataNode Then _instance.sportsData = New TData

		TXmlHelper.LoadAllValuesToData(configNode, self.config)
		TXmlHelper.LoadAllValuesToData(cityNamesNode, self.cityNames)
		If sportsDataNode
			TXmlHelper.LoadAllValuesToData(sportsDataNode, self.sportsData)
		EndIf


		'=== LOAD STATES ===
		'only if not done before
		'ATTENTION: overriding current sections will remove broadcast
		'           permissions as this is called _after_ a savegame
		'           got loaded!
		If self.sections.Length = 0
			'remove old states
			'_instance.ResetSections()

			'find and load states configuration
			Local statesNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "states", xmlFile, "Misses the <stationmap><states>-entry.")
			Local sectionID:Int = 1
			Local childNode:TxmlNode = TxmlNode(statesNode.GetFirstChild())
			While childNode
				Local name:String = TXmlHelper.FindValue(childNode, "name", "")
				Local iso3116Code:String = TXmlHelper.FindValue(childNode, "iso3116code", "")
				Local sprite:String	= TXmlHelper.FindValue(childNode, "sprite", "")
				Local pos:SVec2I = New SVec2I( TXmlHelper.FindValueInt(childNode, "x", 0), TXmlHelper.FindValueInt(childNode, "y", 0) )

				Local pressureGroups:Int = TXmlHelper.FindValueInt(childNode, "pressureGroups", -1)
				Local sectionConfig:TData
				Local sectionConfigNode:TxmlNode = TXmlHelper.FindChild(childNode, "config")
				If sectionConfigNode
					sectionConfig = TXmlHelper.LoadAllValuesToData(sectionConfigNode, New TData)
				EndIf
				'override config if pressureGroups are defined already
				If pressureGroups >= 0
					sectionConfig.AddInt("pressureGroups", pressureGroups)
				EndIf

				'add state section if data is ok
				If name And sprite
					self.AddSection( New TStationMapSection.Create(pos, name, iso3116Code, sectionID, sprite, sectionConfig) )
					sectionID :+ 1
				EndIf
				
				childNode = childNode.NextSibling()
			Wend
			
			'calculate positions (now all sprites are loaded)
			For Local s:TStationMapSection = EachIn self.sections
				'validate if defined via XML
				If s.uplinkPos 
					If Not s.IsValidUplinkPos(s.uplinkPos.GetX(), s.uplinkPos.GetY())
						TLogger.Log("TStationMapCollection.onLoadStationMapData()", "Invalid / Ambiguous uplink position for state ~q" + s.name+"~q. x="+s.uplinkPos.GetX()+" y="+s.uplinkPos.GetY(), LOG_DEBUG)
						s.uplinkPos = Null
					EndIf
				EndIf
					
				s.GetUplinkPos()
			Next
		Else
			'at least renew / fix properties written in the potentially
			'more current config file

			'find and load states configuration
			Local statesNode:TxmlNode = GetNodeOrThrow(xmlStationMapNode, "states", xmlFile, "Misses the <stationmap><states>-entry.")
			Local childNode:TxmlNode = TxmlNode(statesNode.GetFirstChild())
			While childNode
				Local name:String = TXmlHelper.FindValue(childNode, "name", "")
				Local iso3116Code:String = TXmlHelper.FindValue(childNode, "iso3116code", "")

				local existingSection:TStationMapSection = self.GetSectionByName(name)
				If existingSection
					existingsection.iso3116Code = iso3116Code
				EndIf
				
				childNode = childNode.NextSibling()
			Wend
		EndIf

		'fill in sectionIDs so caches can use them (do it for new and loaded games)
		Local sectionID:Int = 1
		For local section:TStationMapSection = EachIn _instance.sections
			section.sectionID = sectionID
			sectionID :+ 1
		Next
		TLogger.Log("TStationMapCollection.onLoadStationMapData()", "Generated section IDs.", LOG_LOADING)


		self.LoadPopulationShareData()


		'=== CREATE SATELLITES / CABLE NETWORKS ===
		If Not _instance.satellites Or _instance.satellites.Count() = 0 Then _instance.ResetSatellites()
		If Not _instance.cableNetworks Or _instance.cableNetworks.Count() = 0 Then _instance.ResetCableNetworks()


		'=== INIT MAP DATA ===
		CreatePopulationMaps()
		AssignPressureGroups()

		'dynamic antenna radius depending on start year (start antenna reach)
		Local dataX:Int = mapInfo.SurfaceXToDataX(GetStationMapCollection().mapInfo.startAntennaSurfacePos.x)
		Local dataY:Int = mapInfo.SurfaceYToDataY(GetStationMapCollection().mapInfo.startAntennaSurfacePos.y)
		If antennaStationRadius = ANTENNA_RADIUS_NOT_INITIALIZED
			Local receivers:Int
			antennaStationRadius = 50
			For Local r:Int = 20 To 50
				receivers = GetStationMapCollection().GetAntennaReceivers(dataX, dataY, r)
				If receivers > GameRules.stationInitialIntendedReach
					antennaStationRadius = r
					Exit
				EndIf
			Next
			If receivers < GameRules.stationInitialIntendedReach
				'player will get cable, reduce station radius
				antennaStationRadius = 45
			EndIf
		EndIf
		
		'if antennas become too big (eg late start year) then disable need to
		'buy broadcast permissions for antennas
		GameRules.antennaStationsRequireBroadcastPermission = True
		If GameRules.antennaStationsRequireBroadcastPermissionUntilRadius > 0
			If antennaStationRadius > GameRules.antennaStationsRequireBroadcastPermissionUntilRadius
				TLogger.Log("TStationMapCollection.LoadFromXML", "Adjust GameRules - antennas do not require broadcast permissions in sections.", LOG_DEBUG)
				GameRules.antennaStationsRequireBroadcastPermission = False
			EndIf
		EndIf

		Function GetNodeOrThrow:TXmlNode(parentNode:TxmlNode, nodeName:String, configFile:String, errorMessage:String)
			Local node:TxmlNode = TXmlHelper.FindChild(parentNode, nodeName)
			If Not node 
				TLogger.Log("TStationMapCollection.LoadFromXML", "Problem in file ~q" + configFile + "~q. " + errorMessage, LOG_ERROR)
				Throw("TStationMapCollection.LoadFromXML: Problem in file ~q" + configFile + "~q. " + errorMessage)
			EndIf
			
			Return node
		End Function

		Return True
	End Method


	Method CreatePopulationMaps()
		Local stopWatch:TStopWatch = New TStopWatch.Init()

		CalculateSectionsPopulation()
		TLogger.Log("TStationMapCollection.CreatePopulationMap", "calculated a population of:" + population + " in "+stopWatch.GetTime()+"ms", LOG_DEBUG | LOG_LOADING)
	End Method


	Method AssignPressureGroups()
		For Local section:TStationMapSection = EachIn sections
			If section.pressureGroups = 0
				'1-2 pressure groups
				'it is possible to have two times the same group ...
				'resulting in only one being used
				For Local i:Int = 0 Until RandRange(1,2)
					section.SetPressureGroups(TVTPressureGroup.GetAtIndex(RandRange(1, TVTPressureGroup.count)), True)
				Next
			EndIf
		Next

		TLogger.Log("GetStationMapCollection().AssignPressureGroups", "Assigned pressure groups to sections of the map not containing predefined ones.", LOG_DEBUG | LOG_LOADING)
	End Method


	Method GetMap:TStationMap(playerID:Int)
		if playerID < 1 or playerID > stationMaps.length Then Return Null
		Return stationMaps[playerID-1]
	End Method


	Method AddMap:Int(map:TStationMap)
		'check boundaries
		If map.owner < 1 Then Return False

		'resize if needed
		If map.owner > stationMaps.Length Then stationMaps = stationMaps[ .. map.owner+1]

		'add to array array - zerobased
		stationMaps[map.owner-1] = map

		Return True
	End Method


	Method RemoveMap:Int(map:TStationMap)
		'check boundaries
		If map.owner < 1 Or map.owner > stationMaps.Length Return False
		'remove from array - zero based
		stationMaps[map.owner-1] = Null

		'invalidate caches / antenna maps
		For Local section:TStationMapSection = EachIn sections
			section.InvalidateData()
			'pre-create data already
			'section.GetAntennaShareGrid()
		Next

		Return True
	End Method

rem
	'return the stationmap of other channels
	'do not expose to Lua... else they get access to buy/sell
	Method GetMap:TStationMap(channelNumber:Int, createIfMissing:Int = False)
		'check boundaries
		If channelNumber < 1 Or (Not createIfMissing And channelNumber > stationMaps.Length)
			Throw "GetStationMapCollection().GetMap: channelNumber ~q"+channelNumber+"~q is out of bounds."
		EndIf

		'create if missing
		If (channelNumber > stationMaps.Length Or Not stationMaps[channelNumber-1]) And createIfMissing
			Add(TStationMap.Create(channelNumber))
		EndIf

		'zero based
		Return stationMaps[channelNumber-1]
	End Method
endrem

	'returns the average reach of all stationmaps
	Method GetAverageReceivers:Int()
		Local reach:Int = 0
		Local mapCount:Int = 0
		For Local map:TStationMap = EachIn stationMaps
			'skip empty maps
			'TODO: what happens with satellites?
			'if map.GetStationCount() = 0 then continue

			reach :+ map.GetReceivers()
			mapCount :+ 1
		Next
		If mapCount = 0 Then Return 0
		Return reach/mapCount
	End Method


	Method GetSportData:TData(sport:String, defaultData:TData = Null)
		Return sportsData.GetData(sport, defaultData)
	End Method


	Method GenerateCity:String(glue:String="")
		Local part1:String[] = cityNames.GetString("part1").Split(", ")
		Local part2:String[] = cityNames.GetString("part2").Split(", ")
		Local part3:String[] = cityNames.GetString("part3").Split(", ")
		If part1.Length = 0 Then Return "part1Missing-Town"
		If part2.Length = 0 Then Return "part2Missing-Town"
		If part3.Length = 0 Then Return "part3Missing-Town"

		Local result:String = ""
		'use part 1?
		If part1.Length > 0 And RandRange(0,100) < 35
			result :+ StringHelper.UCFirst(part1[RandRange(0, part1.Length-1)])
		EndIf

		'no prefix, or " " or "-" (Bad Blaken, Alt-Drueben)
		If Not result Or Chr(result[result.Length-1]) = " " Or Chr(result[result.Length-1]) = "-"
			If result <> "" Then result :+ glue
			result :+ StringHelper.UCFirst(part2[RandRange(0, part2.Length-1)])
		Else
			If result <> "" Then result :+ glue
			result :+ part2[RandRange(0, part2.Length-1)]
		EndIf

		If RandRange(0,100) < 35
			result :+ glue
			result :+ part3[RandRange(0, part3.Length-1)]
		EndIf

		If result.Trim() = "" Then Return "partsMissing-Town"

		Return result
	End Method


	Method UpdateSections()
		'if not sections then return
		'for local s:TStationMapSection = EachIn sections
		'next
	End Method


	Method UpdateSatellites()
		If Not satellites Then ResetSatellites()
		If Not satellites Then Return

		Local toRemove:TStationMap_Satellite[]

		For Local s:TStationMap_Satellite = EachIn satellites
			s.Update()

			If s.deathDecided And s.deathTime < GetWorldTime().GetTimeGone()
				If Not toRemove
					toRemove = [s]
				Else
					toRemove :+ [s]
				EndIf
			EndIf
		Next

		If toRemove And toRemove.Length > 0
			For Local s:TStationMap_Satellite = EachIn toRemove
				RemoveSatellite(s)
			Next
		EndIf
	End Method


	Method UpdateCableNetworks()
		If Not cableNetworks Then ResetCableNetworks()
		If Not cableNetworks Then Return

		For Local s:TStationMap_CableNetwork = EachIn cableNetworks
			s.Update()
		Next
	End Method


	Method UpdateSatelliteSubscriptions()
		If Not satellites Then Return

		For Local s:TStationMap_Satellite = EachIn satellites
			s.UpdateSubscriptions()
		Next
	End Method


	Method UpdateCableNetworkSubscriptions()
		If Not cableNetworks Then Return

		For Local c:TStationMap_CableNetwork = EachIn cableNetworks
			c.UpdateSubscriptions()
		Next
	End Method


	Method Update:Int()
		'repair broken census times in DEV patch savegames
		If nextCensusTime > 0 And nextCensusTime > GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH * 1
			TLogger.Log("TStationMapCollection.Update()", "Repaired broken DEV Patch census time.", LOG_DEBUG)
			nextCensusTime = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay()+1, 0,0,0)
		EndIf

		'refresh stats ?
		If nextCensusTime < 0 Or nextCensusTime < GetWorldTime().GetTimegone()
			DoCensus()
			'every day?
			nextCensusTime = GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH * 1
		EndIf

		'update (eg. launch)
		UpdateSatellites()
		UpdateCableNetworks()

		UpdateSections()

		'update all stationmaps (and their stations)
		For Local i:Int = 0 Until stationMaps.Length
			If Not stationMaps[i] Then Continue

			stationMaps[i].Update()
		Next

		'update subscriptions (eg. ended contracts -> channel unsubscription)
		UpdateSatelliteSubscriptions()
		UpdateCableNetworkSubscriptions()
		
		Return True
	End Method


	'return population of the whole map
	Method GetPopulation:Int()
		Return population
	End Method


	'return "theoretically covered" population by stations of a channel/player
	'(a satellite already covers 100% of the population albeit not all 
	'beneath will have a TV nor use that specific satellite (uplink))
	Method GetPopulation:Int(playerID:Int)
		Return GetStationMap(playerID).GetPopulation()
	End Method


	'=== SATELLITES (the launched ones) ===
	Method ResetSatellites:Int()
		If satellites And satellites.Count() > 0
			'avoid concurrent list modification and remove from list
			'by iterating over an array copy
			Local satArray:TStationMap_Satellite[] = New TStationMap_Satellite[ satellites.Count() ]
			Local i:Int
			For Local satellite:TStationMap_Satellite = EachIn satellites
				satArray[i] = satellite
				i :+ 1
			Next
			For Local satellite:TStationMap_Satellite = EachIn satArray
				RemoveSatellite(satellite)
			Next
		EndIf
		'create new list (or empty it)
		satellites = CreateList()

		'TODO: init from map-config-file!

		'create some satellites
		Local satNames:String[] = ["Alpha", "Orion", "MoSat", "Astro", "Dig", "Olymp", "Strata", "Solus"]
		'shuffle names a bit
		Local shuffleIndex:Int
		Local shuffleTmp:String
		For Local i:Int = satNames.Length-1 To 0 Step -1
			shuffleIndex = RandRange(0, satNames.Length-1)
			shuffleTmp = satNames[i]
			satNames[i] = satNames[shuffleIndex]
			satNames[shuffleIndex] = shuffleTmp
		Next

		'create up to 3 satellites
		Local lastLaunchTime:Long = GetWorldTime().GetTimeGoneForGameTime(1983, 1,1, 0,0)
		For Local satNumber:Int = 0 Until Min(3, satNames.Length)
			Local satName:String = satNames[satNumber]
			Local launchTime:Long = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(0,1), RandRange(1,2), 0)
			Local satellite:TStationMap_Satellite = CreateRandomSatellite(satName, launchTime)

			AddSatellite(satellite)

			lastLaunchTime = satellite.launchTime
		Next

		Return True
	End Method


	Method CreateRandomSatellite:TStationMap_Satellite(brandName:String, launchTime:Long, revision:Int = 1)
		Local satellite:TStationMap_Satellite = New TStationMap_Satellite
		satellite.launchTime = launchTime
'			satellite.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(18,28), RandRange(1,28), 0)
		satellite.brandName = brandName
		satellite.name = brandName
		If revision > 1 Then satellite.name :+ " " + revision
		satellite.quality = RandRange(85,100)
		satellite.dailyFeeMod = RandRange(90,110) / 100.0
		satellite.setupFeeMod = RandRange(80,120) / 100.0
		satellite.dailyFeeBase = RandRange(75,110) * 1000
		satellite.setupFeeBase = RandRange(125,175) * 1000

		If revision <= 1
			satellite.minimumChannelImage = RandRange(20,30)
		ElseIf revision <= 3
			satellite.minimumChannelImage = RandRange(15,25)
		Else
			satellite.minimumChannelImage = RandRange(10,15)
		EndIf

		'local year:int = GetWorldTime().GetYear(launchTime)
		'if year >= 1990
		'	satellite.minimumChannelImage = RandRange(10,20)
		'...

		Return satellite
	End Method


	Method AddSatellite:Int(satellite:TStationMap_Satellite)
		If satellites.AddLast(satellite)
			'recalculate shared audience percentage between satellites
			UpdateSatelliteSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_AddSatellite, New TData.Add("satellite", satellite), Self )
			Return True
		EndIf

		Return False
	End Method


	Method RemoveSatellite:Int(satellite:TStationMap_Satellite)
		If satellites.Remove(satellite)
			'inform satellite about death (to cancel contracts/uplinks)
			satellite.Die()

			'recalculate shared audience percentage between satellites
			UpdateSatelliteSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_RemoveSatellite, New TData.Add("satellite", satellite), Self )
			Return True
		EndIf

		Return False
	End Method


	Method OnLaunchSatellite:Int(satellite:TStationMap_Satellite)
		TriggerBaseEvent(GameEventKeys.StationMapCollection_LaunchSatellite, New TData.Add("satellite", satellite), Self )

		'recalculate shared audience percentage between satellites
		UpdateSatelliteSharesAndQuality()
		
		Return True
	End Method


	Method OnLetDieSatellite:Int(satellite:TStationMap_Satellite)
		TriggerBaseEvent(GameEventKeys.StationMapCollection_LetDieSatellite, New TData.Add("satellite", satellite), Self )

		TLogger.Log("TStationMapCollection", "Let die satellite ~q"+satellite.name+"~q", LOG_DEBUG)

		'create another satellite ("follow up" revision)
		Local nextSatellite:TStationMap_Satellite = CreateRandomSatellite(satellite.brandName, GetWorldTime().ModifyTime(-1, 0, 0, 0, RandRange(0,30)), satellite.revision + 1)
		AddSatellite(nextSatellite)

		Return True
	End Method


	Method UpdateSatelliteSharesAndQuality:Int()
		If Not satellites Or satellites.Count() = 0 Then Return False

		Local bestChannelCount:Int = 0
		Local worstChannelCount:Int = 0
		Local avgChannelCount:Float = 0
		Local channelCountSum:Int = 0

		Local bestQuality:Int = 0
		Local worstQuality:Int = 0
		Local avgQuality:Float = 0
		Local qualitySum:Int = 0
		Local firstFound:Int = False
		Local activeSatCount:Int = 0
		For Local satellite:TStationMap_Satellite = EachIn satellites
			If Not satellite.IsLaunched() Then Continue

			Local subscribedChannelCount:Int = satellite.GetSubscribedChannelCount()

			If Not firstFound
				firstFound = True
				bestQuality = satellite.quality
				worstQuality = satellite.quality

				bestChannelCount = subscribedChannelCount
				worstChannelCount = subscribedChannelCount
			EndIf

			bestQuality = Max(bestQuality, satellite.quality)
			worstQuality = Min(worstQuality, satellite.quality)
			qualitySum :+ satellite.quality

			bestChannelCount = Max(bestChannelCount, subscribedChannelCount)
			worstChannelCount = Min(worstChannelCount, subscribedChannelCount)
			channelCountSum :+ subscribedChannelCount

			activeSatCount :+ 1
		Next
		'skip further processing if there is no active satellite
		If activeSatCount = 0 Then Return False

		avgQuality = qualitySum / activeSatCount
		avgChannelCount = channelCountSum / activeSatCount

		'what's the worth of a quality point / channel?
		Local sharePartQuality:Float = 1.0 / qualitySum
		Local sharePartChannelCount:Float = 1.0 / channelCountSum

		'spread share across satellites
		'set best quality to 100% and adjust all others accordingly
'		print "UpdateSatelliteSharesAndQuality:"
'		print "  best quality="+bestQuality
		For Local satellite:TStationMap_Satellite = EachIn satellites
			'ignore if not launched
			'share is not affected if not launched
			'quality is "perceived quality" (by audience) so also not affected
			If Not satellite.IsLaunched() Then Continue

			satellite.oldPopulationShare = satellite.populationShare

			'min 40% influence of quality
			'max 60% of subscribed channel count
			'weight is depending on how many channels use satellites
			If bestChannelCount > 0
				Local bestChannelWeight:Float = 0.6 * bestChannelCount/4.0 '4 = player count
				satellite.populationShare = MathHelper.Clamp((1.0 - bestChannelWeight) * (sharePartQuality * satellite.quality) + bestChannelWeight * (sharePartChannelCount * satellite.GetSubscribedChannelCount()), 0.0, 1.0)
			Else
				satellite.populationShare = MathHelper.Clamp(sharePartQuality * satellite.quality, 0.0, 1.0)
			EndIf

			satellite.oldQuality = satellite.quality
			satellite.quality = MathHelper.Clamp(100 * satellite.quality / Float(bestQuality), 0.0, 100.0)

'			print "  satellite: "+Lset(satellite.name, 12)+ "  share: " + satellite.oldPopulationShare +" -> " + satellite.populationShare +"   quality: " + satellite.oldQuality +" -> " + satellite.quality
		Next

		Return True
	End Method


	Method RemoveSatelliteUplinkFromSatellite:Int(satellite:TStationMap_Satellite, linkOwner:Int)
		Local map:TStationMap = GetMap(linkOwner)
		If Not map Then Return False

		Local satLink:TStationSatelliteUplink = TStationSatelliteUplink( map.GetSatelliteUplink(satellite) )
		If Not satLink Then Return False


		Rem
		'variant A - keep "uplink"
		satLink.providerGUID = ""
		'force running costs recalculation
		satLink.runningCosts = -1

		'do not sell it directly but just "shutdown"
		'(so new contracts with this uplink can get created)
		satLink.ShutDown()
		endrem

		'variant B - just sell the uplink
		Return map.SellStation(satLink)
	End Method




	'=== CABLE NETWORKS (the providers) ===
	Method ResetCableNetworks:Int()
		If cableNetworks And cableNetworks.Count() > 0
			'avoid concurrent list modification and remove from list
			'by iterating over an array copy
			Local cnArray:TStationMap_CableNetwork[] = New TStationMap_CableNetwork[ cableNetworks.Count() ]
			Local i:Int
			For Local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
				cnArray[i] = cableNetwork
				i :+ 1
			Next
			For Local cableNetwork:TStationMap_CableNetwork = EachIn cnArray
				RemoveCableNetwork(cableNetwork)
			Next
		EndIf
		'create new list (or empty it)
		cableNetworks = CreateList()

		'TODO: init from map-config-file!

		'create some networks
		Local cnNames:String[] = ["Kabel %name%", "Verbund %name%", "Tele %name%", "%name% Kabel", "FK %name%"]

		Local lastLaunchTime:Long = GetWorldTime().GetTimeGoneForGameTime(1982, 1,1, 0,0)
		Local cnNumber:Int = 0

		For Local section:TStationMapSection = EachIn sections
			Local cableNetwork:TStationMap_CableNetwork = New TStationMap_CableNetwork
			'shorter and shorter amounts
			If cnNumber < sections.Length/4
				cableNetwork.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(5,9), RandRange(1,28), 0)
			ElseIf cnNumber < sections.Length/2
				cableNetwork.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(3,6), RandRange(1,28), 0)
			Else
				cableNetwork.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(2,4), RandRange(1,28), 0)
			EndIf
			'still includes potential place holders!
			cableNetwork.name = cnNames[RandRange(0, cnNames.Length-1)]
			cableNetwork.quality = RandRange(95,110)
			cableNetwork.dailyFeeMod = RandRange(90,110) / 100.0
			cableNetwork.setupFeeMod = RandRange(80,120) / 100.0
			cableNetwork.dailyFeeBase = RandRange(50,75) * 1000
			cableNetwork.setupFeeBase = RandRange(175,215) * 1000
			cableNetwork.sectionName = section.name
			cableNetwork.sectionISO3116Code = section.iso3116Code
			If cnNumber = 0
				cableNetwork.minimumChannelImage = RandRange(5,10)
			ElseIf cnNumber <= 3
				cableNetwork.minimumChannelImage = RandRange(8,16)
			ElseIf cnNumber <= 6
				cableNetwork.minimumChannelImage = RandRange(14,25)
			Else
				cableNetwork.minimumChannelImage = RandRange(23,37)
			EndIf
			cnNumber :+ 1

			AddCableNetwork(cableNetwork)

			lastLaunchTime = cableNetwork.launchTime

			'add federal state name for cable providers etc (else this
			'is only appended when using GetName() instead of ".name"
			cableNetwork.name = cableNetwork.GetName()
			'update immediately, otherwise the network is not launched for the first player
			cableNetwork.Update()
		Next

		Return True
	End Method


	Method AddCableNetwork:Int(cableNetwork:TStationMap_CableNetwork)
		If cableNetworks.AddLast(cableNetwork)
			'recalculate shared audience percentage between cable networks
			UpdateCableNetworkSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_AddCableNetwork, New TData.Add("cableNetwork", cableNetwork), Self )
			Return True
		EndIf

		Return False
	End Method


	Method RemoveCableNetwork:Int(cableNetwork:TStationMap_CableNetwork)
		If cableNetworks.Remove(cableNetwork)
			'recalculate shared audience percentage between cable networks
			UpdateCableNetworkSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_RemoveCableNetwork, New TData.Add("cableNetwork", cableNetwork), Self )
			Return True
		EndIf

		Return False
	End Method


	Method OnLaunchCableNetwork:Int(cableNetwork:TStationMap_CableNetwork)
		'recalculate shared audience percentage between cable networks
		UpdateCableNetworkSharesAndQuality()

		Return True
	End Method


	Method RefreshSectionsCableNetworkCount:Int()
		For Local section:TStationMapSection = EachIn sections
			section.activeCableNetworkCount = 0
			section.cableNetworkCount = 0

			For Local otherCableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
				If otherCableNetwork.sectionName = section.name
					section.cableNetworkCount :+ 1
					If otherCableNetwork.IsActive()
						section.activeCableNetworkCount :+ 1
					EndIf
				EndIf
			Next
		Next

		Return True
	End Method


	Method UpdateCableNetworkSharesAndQuality:Int()
		If Not cableNetworks Or cableNetworks.Count() = 0 Then Return False

		'for now just ensure all cable networks are set to 100%
		'(no competition for now - only 1 network per section)
		For Local cablenetwork:TStationMap_CableNetwork = EachIn cableNetworks
			If Not cablenetwork.IsLaunched() Then Continue
			
			cablenetwork.populationShare = 1.0
		Next

'todo
Rem
		For local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			if not cableNetwork.IsLaunched() then continue

			local bestQuality:Int = 0
			local worstQuality:Int = 0
			local avgQuality:Float = 0
			local qualitySum:Int = 0
			local firstFound:int = False
			local activeCableNetworkCount:int = 0

			'compare with other networks in the same section
			For local otherCableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
				if not otherCableNetwork.IsLaunched() then continue

				local found:int = False
				For local sectionName:string = EachIn cableNetwork.sectionNames
					if otherCableNetwork.HasSection()
						found = true
						exit
					endif
				Next

				'ignore unconnected ones
				if not found then continue

				if not firstFound
					bestQuality = cableNetwork.quality
					worstQuality = cableNetwork.quality
				endif

				if bestQuality > cableNetwork.quality then bestQuality = cableNetwork.quality
				if worstQuality < cableNetwork.quality then worstQuality = cableNetwork.quality
				qualitySum :+ cableNetwork.quality

				activeCableNetworkCount :+ 1
			Next
			'skip further processing if there is no active networks
			if activeCableNetworkCount = 0 then continue

			avgQuality = qualitySum / activeSatCount

			'what's the worth of a quality point?
			local sharePart:Float = 1.0 / qualitySum

			'spread share across networks
			'set best quality to 100% and adjust all others accordingly

			For local satellite:TStationMap_Satellite = EachIn satellites
				'ignore if not launched
				'share is not affected if not launched
				'quality is "perceived quality" (by audience) so also not affected
				if not satellite.IsLaunched() then continue

				satellite.oldPopulationShare = satellite.populationShare
				satellite.populationShare = MathHelper.Clamp(sharePart * satellite.quality, 0.0, 1.0)

				satellite.oldQuality = satellite.quality
				satellite.quality = 100 * floor(MathHelper.Clamp(satellite.quality / float(bestQuality), 0.0, 1.0) + 0.5)

				print "  satellite: "+satellite.name+ "  share: " + satellite.oldPopulationShare +" -> " + satellite.populationShare +"   quality: " + satellite.oldQuality +" -> " + satellite.quality
			Next
		Next
endrem

		Return True
	End Method


	Method RemoveCableNetworkUplinkFromCableNetwork:Int(cableNetwork:TStationMap_CableNetwork, linkOwner:Int)
		Local map:TStationMap = GetMap(linkOwner)
		If Not map Then Return False

		Local cableLink:TStationCableNetworkUplink = TStationCableNetworkUplink( map.GetCableNetworkUplink(cableNetwork) )
		If Not cableLink Then Return False

		Rem
		'variant A - keep "uplink"
		cableLink.providerGUID = ""
		'force running costs recalculation
		cableLink.runningCosts = -1

		'do not sell it directly but just "shutdown" (so contracts can get renewed)
		cableLink.ShutDown()
		endrem

		'variant B - just sell the uplink
		Return map.SellStation(cableLink)
	End Method



	Method RemoveUplinkFromBroadcastProvider:Int(broadcastProvider:TStationMap_BroadcastProvider, uplinkOwner:Int)
		If TStationMap_Satellite(broadcastProvider)
			Return RemoveSatelliteUplinkFromSatellite(TStationMap_Satellite(broadcastProvider), uplinkOwner)
		ElseIf TStationMap_CableNetwork(broadcastProvider)
			Return RemoveCableNetworkUplinkFromCableNetwork(TStationMap_CableNetwork(broadcastProvider), uplinkOwner)
		EndIf

		Return False
	End Method


	'=== SECTIONS ===

	Method GetSectionBySurfaceXY_old:TStationMapSection(surfaceX:Int,surfaceY:Int)
		For Local section:TStationMapSection = EachIn sections
			Local sprite:TSprite = section.GetShapeSprite()
			If Not sprite Then Continue

			If section.rect.containsXY(surfaceX, surfaceY)
				If Not sprite._pix Then sprite._pix = sprite.GetPixmap()
				If PixelIsOpaque(sprite._pix, Int(surfaceX - section.rect.x), Int(surfaceY - section.rect.y)) > 0
					Return section
				EndIf
			EndIf
		Next

		Return Null
	End Method


	Method GetSectionBySurfaceXY:TStationMapSection(surfaceX:Int, surfaceY:Int)
		Local dataX:Int = GetStationMapCollection().mapInfo.SurfaceXToDataX(surfaceX)
		Local dataY:Int = GetStationMapCollection().mapInfo.SurfaceYToDataY(surfaceY)
		
		Return GetSectionByDataXY(dataX, dataY)
	End Method


	Method GetSectionByDataXY:TStationMapSection(dataX:Int, dataY:Int)
		If dataX < 0 Or dataX >= self.surfaceData.width Then Return Null
		If dataY < 0 Or dataY >= self.surfaceData.height Then Return Null

		Local sectionID:Int = self.surfaceData.data[dataY * self.surfaceData.width + dataX]
		if sectionID <= 0 or sectionID > self.sections.length then Return Null

		'first section is at [0], so ID is here like "index + 1"
		Return self.sections[sectionID - 1]
	End Method


	Method GetSectionByName:TStationMapSection(name:String)
		name = name.ToLower()
		For Local section:TStationMapSection = EachIn sections
			If section.name.ToLower() = name Then Return section
		Next

		Return Null
	End Method


	Method GetSectionByListPosition:TStationMapSection(position:Int)
		If position >= 0 And position < sections.Length
			Return TStationMapSection(sections[position])
		Else
			Return Null
		EndIf
	End Method


	Method GetSectionCount:Int()
		Return sections.Length
	End Method


	Method GetSectionISO3166Code:String(name:String)
		name = name.ToLower()
		For Local section:TStationMapSection = EachIn sections
			If section.name.ToLower() = name 
				Return section.iso3116Code
			EndIf
		Next

		Return Null
	End Method


	Method GetSectionsFiltered:TStationMapSection[](channelID:Int=-1, checkBroadcastPermission:Int=True, requiredBroadcastPermissionState:Int=True, stationType:Int=-1)
		Local filteredSections:TStationMapSection[] = New TStationMapSection[sections.Length]
		Local used:Int = 0
		For Local section:TStationMapSection = EachIn Self.sections
			If (checkBroadcastPermission And section.NeedsBroadcastPermission(channelID, stationType))
				If section.HasBroadcastPermission(channelID, stationType) <> requiredBroadcastPermissionState Then Continue
			EndIf
			filteredSections[used] = section
			
			used :+ 1
		Next

		If used <> filteredSections.Length
			Return filteredSections[.. used]
		Else
			Return filteredSections
		EndIf
	End Method
	

	Method GetSectionsConnectedToAntenna:TStationMapSection[](x:Int, y:int, radius:Int)
		Local circleRectX:Int = Max(0, x - radius)
		Local circleRectY:Int = Max(0, y - radius)
		Local circleRectX2:Int = Min(x + radius, surfaceData.width-1)
		Local circleRectY2:Int = Min(y + radius, surfaceData.height-1)
		Local radiusSquared:Int = radius * radius
		'station coordinates in "surface coordinates"
		'TODO:
		'Local stationRect:SRectI = New SRectI(mapInfo.DataXToSurfaceX(station.X - radius), mapInfo.DataYToSurfaceY(station.Y - radius), mapInfo.DataToScreen(2*radius), mapInfo.DataToScreen(2*radius))
		Local stationRect:SRectI = New SRectI(circleRectX, circleRectY, circleRectX2 - circleRectX, circleRectY2 - circleRectY)
		local result:TStationMapSection[]

		For Local section:TStationMapSection = EachIn sections
			'skip sections absolutely not hit
			If Not stationRect.Intersects(Int(section.rect.x), Int(section.rect.y), Int(section.rect.w), Int(section.rect.h)) Then Continue
			
			Local sectionHit:Int = False
			'check exactly
			For local posX:Int = circleRectX until circleRectX2
				'calculate height of the circle"slice"
				Local circleLocalX:Int = posX - x
				Local currentCircleH:Int = sqr(radiusSquared - circleLocalX * circleLocalX)

				For local posY:Int = Max(y - currentCircleH, circleRectY) until Min(y + currentCircleH, circleRectY2)
					'within the topographic borders ?
					If posX < section._surfaceData.width and posY < section._surfaceData.height and section._surfaceData.data[posY * section._surfaceData.width + posX] > 1
						result :+ [section]
						sectionHit = True
						exit
					EndIf
				Next
				if sectionHit Then exit
			Next
		Next
		Return result
	End Method


	'returns sections "nearby" a station (connection not guaranteed as
	'check of a circle-antenna is based on two rects intersecting or not)
	Method GetSectionsConnectedToStation:TStationMapSection[](station:TStationBase)
		If Not station Then Return New TStationMapSection[0]

		'GetInstance()._regenerateMap = True
		If TStationAntenna(station)
			Local radius:Int = TStationAntenna(station).radius
			'station coordinates in "surface coordinates"
			Local stationRect:SRectI = New SRectI(mapInfo.DataXToSurfaceX(station.X - radius), mapInfo.DataYToSurfaceY(station.Y - radius), mapInfo.DataToScreen(2*radius), mapInfo.DataToScreen(2*radius))
			Local result:TStationMapSection[] = New TStationMapSection[sections.Length]
			Local added:Int = 0

			For Local section:TStationMapSection = EachIn sections
				If Not stationRect.Intersects(Int(section.rect.x), Int(section.rect.y), Int(section.rect.w), Int(section.rect.h)) Then Continue

				result[added] = section
				added :+ 1
			Next
			If added < result.Length Then result = result[.. added]
			Return result

		ElseIf TStationCableNetworkUplink(station)
			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(station.GetSectionName())
			If section Then Return [section]

		ElseIf TStationSatelliteUplink(station)
			'all
			Local result:TStationMapSection[] = New TStationMapSection[sections.Length]
			Local added:Int = 0
			For Local section:TStationMapSection = EachIn sections
				result[added] = section
				added :+ 1
			Next
			Return result
		Else
			Throw "GetSectionsConnectedToStation: unhandled station type"
		EndIf

		Return New TStationMapSection[0]
	End Method


	Method DrawAllSections()
		If Not sections Then Return
		Local oldA:Float = GetAlpha()
		SetAlpha oldA * 0.8
		For Local section:TStationMapSection = EachIn sections
			If Not section.GetShapeSprite() Then Continue
			section.shapeSprite.Draw(section.rect.x, section.rect.y)
		Next
		SetAlpha oldA
	End Method


	Method ResetSections()
		sections = New TStationMapSection[0]
	End Method


	Method AddSection(section:TStationMapSection)
		sections :+ [section]
		'inform others
		TriggerBaseEvent(GameEventKeys.StationMapCollection_AddSection, New TData.Add("section", section), Self )
	End Method


	Method CalculateSectionsPopulation:Int()
		'extract canvas data from sections
		'0. calculate stretch factor "screen design based sections" vs "density data"
		'   as the section collision images are based on a "base / design screen dimension"
		'-> this is already done when "SetScreenMapSize()" is called 
		'   during init()
		'1. sort sections by area to repair potential overlaps with least
		'   effect on small sections
		'2. fetch collision image / borders and stretch it to the size of the DensityData 
		'3. create a (local coord) surface layer out of the stretched image
		'   only add what is not yet occupied already by an other section

		'regarding 3.:
		'Sections might overlap if not properly done.
		'To repair this we add all sections to a canvas and then
		'use the canvas to check if points on a section are already in use
		'by previously processed sections
		'-> any potential overlap is now "removed" from this section
		'ATTENTION: the order of the sections decides which one gets 
		'           the overlap added!


		'== 1. Sort Sections ==
		'order sections by "size" - so that smaller sections less likely
		'remove overlap (removed overlap in relation to area is much 
		'higher there -> bigger impact!)
		local sortedSections:TIntMap = New TIntMap
		For Local section:TStationMapSection = EachIn sections
			Local sectionSprite:TSprite = section.GetShapeSprite()
			if sectionSprite
				local sectionPix:TPixmap = sectionSprite.GetPixmap() 
				local sectionPixArea:Int = sectionPix.width * sectionPix.height
				local key:Int = sectionPixArea 'smaller key for smaller areas -> process first!
				While sortedSections.contains(key)
					key :-1
				Wend
				sortedSections.Insert(key, section)
			EndIf
		Next

	
		'reset surface data
		'to know the actual surface width we have to find out 
		'the maximum of all section borders
		Local sectionsMaxX:Int
		Local sectionsMaxY:Int
		For Local section:TStationMapSection = EachIn sortedSections.Values()
			if sectionsMaxX = 0
				sectionsMaxX = Int(section.rect.x + section.rect.w)
				sectionsMaxY = Int(section.rect.y + section.rect.h)
			else
				sectionsMaxX = Max(sectionsMaxX, Int(section.rect.x + section.rect.w))
				sectionsMaxY = Max(sectionsMaxY, Int(section.rect.y + section.rect.h))
			endif
		Next
		'print sectionsMaxX+", " + sectionsMaxY + "  ->  " + mapInfo.SurfaceXToDataX(sectionsMaxX) + ", " + mapInfo.SurfaceYToDataY(sectionsMaxY)
		self.surfaceData = New TStationMapSurfaceData(mapInfo.SurfaceXToDataX(sectionsMaxX), mapInfo.SurfaceYToDataY(sectionsMaxY))

		'For Local section:TStationMapSection = EachIn sections
		For Local section:TStationMapSection = EachIn sortedSections.Values()
			'print "processing " +section.name
			'== 2. fetch and stretch collision images ==
			Local sectionSprite:TSprite = section.GetShapeSprite()
			if not sectionSprite Then Throw "no section sprite found"
			'scale image to density data
			local sectionPix:TPixmap = sectionSprite.GetPixmap() 
			local scaledPix:TPixmap = ResizePixmap(sectionPix, Int(sectionPix.width / mapInfo.densityDataScreenScale), Int(sectionPix.height / mapInfo.densityDataScreenScale))
			
			'scale screen offsets to data offsets
			'section rects are local to "station map surface/topo map"
			section.densityDataOffsetX = mapInfo.SurfaceXToDataX(Int(section.rect.x))
			section.densityDataOffsetY = mapInfo.SurfaceYToDataY(Int(section.rect.y))

			'== 3. Cut already used "points" (overlap) ==
			Local usedWidth:Int = 0
			Local usedHeight:Int = 0
			For local x:int = 0 until scaledPix.width
				For local y:int = 0 until scaledPix.height
					'clear pixels which are used by other sections already
					
					'default value is 0, so we only need to set values
					'for "opaque pixels" 
					If PixelIsOpaque(scaledPix, x, y)
						'the surface pixmap might be a bit of compared to
						'the density map - so ensure we can access the data
						'array correctly
						Local surfaceDataX:Int = x + section.densityDataOffsetX
						Local surfaceDataY:Int = y + section.densityDataOffsetY
						'clear if already used by other sections
						If surfaceDataX >= 0 and surfaceDataY >= 0 and surfaceDataX < self.surfaceData.width and surfaceDataY < self.surfaceData.height and self.surfaceData.data[surfaceDataY * self.surfaceData.width + surfaceDataX] > 0
							scaledpix.WritePixel(x, y, 0)
						Else
							usedWidth = Max(x, usedWidth)
							usedHeight = Max(y, usedHeight)
						EndIf
					EndIf
				Next
			Next

			'add to total surface so next section can use this information already
			self.surfaceData.SetDataFromPixmap(scaledPix, section.densityDataOffsetX, section.densityDataOffsetY, section.sectionID)

			'load in as sections surface data
			section.SetSurfaceData( New TStationMapSurfaceData(usedWidth, usedHeight).SetDataFromPixmap(scaledPix) )
			
			'SavePixmapPNG(section._surfaceData.ToPixmap(), "section_"+section.GetName()+".png")
		Next
		
		'SavePixmapPNG(self.surfaceData.ToPixmap(), "surfaceData.png")
		'SavePixmapPNG(GetPopulationDensityOverlayRawPixmap(False), "populationdensity_raw.png")
		'SavePixmapPNG(GetPopulationDensityOverlayRawPixmap(True), "populationdensity_raw_enhanced.png")
		
		'TODO:
		'Nicht von Bundeslaendern belegete "Bevoelkerungsdichte" null setzen?

		'count complete density layer instead?
		'self.population = -1
		'self.population = self.GetPopulation()

		'only count population in the sections (so incorrect boundaries
		'lead to missing population)
		self.population = 0
		For Local section:TStationMapSection = EachIn sections
			self.population :+ section.GetPopulation()
		Next

rem
		'https://datacommons.org/place/nuts/DEG?hl=de -> dort Bundeslaender eintippen
		local expectedPop:Int[]
		expectedPop :+ [569396] 'Bremen
		expectedPop :+ [3443000] 'Berlin
		expectedPop :+ [1774000] 'Hamburg
		expectedPop :+ [10744921] 'bawue
		expectedPop :+ [12510331] 'bayern
		expectedPop :+ [1022585] 'saarland
		expectedPop :+ [4012675] 'rheinlandpfalz
		expectedPop :+ [6061951] 'hessen
		expectedPop :+ [2249882] 'thueringen
		expectedPop :+ [4168732] 'sachsen
		expectedPop :+ [2356219] 'sachsenanhalt
		expectedPop :+ [7928815] 'niedersachsen
		expectedPop :+ [2832027] 'schleswigholstein
		expectedPop :+ [2511525] 'brandenburg
		expectedPop :+ [17872763] 'nrw
		expectedPop :+ [1651216] 'meckpom

		local i:int = 0
		For Local section:TStationMapSection = EachIn sections
			TLogger.Log("TStationMapCollection.CalculateSectionsPopulation", "Section " + section.name + " population = " + section.GetPopulation() +"    eurostat = " + expectedPop[i]+"  " + Left((100 * expectedPop[i]/float(section.GetPopulation()) - 100 ),5)+"%)", LOG_DEBUG | LOG_LOADING)
			i :+ 1
		Next
endrem
		Return True
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetStationMapCollection:TStationMapCollection()
	Return TStationMapCollection.GetInstance()
End Function

Function GetStationMap:TStationMap(playerID:Int)
	Return TStationMapCollection.GetInstance().GetMap(playerID)
End Function




Type TStationMapInfo
	'offset of surface to screen (if the topo image starts not at 0,0)
	Field surfaceScreenOffset:SVec2I
	'offset of the density data to the surface/map ("topo image")
	Field densityDataOnSurfaceOffset:SVec2I
	Field densityData:TStationMapDensityData
	'how big is the visual topography of the map?
	Field screenMapSize:SVec2I
	'scale factor "screen vs density data"
	Field densityDataScreenScale:Float = 1.0
	'maximum dimension of the density data set
	Field densityDataMaxDim:Int = 1500
	'where to place first player antenna
	Field startAntennaSurfacePos:SVec2I

	Field surfaceImage:TImage


	Method New(densityDataURI:String, densityDataOnSurfaceOffset:SVec2I, surfaceImageURI:String)
		self.densityDataOnSurfaceOffset = densityDataOnSurfaceOffset
		self.densityData = New TStationMapDensityData(densityDataURI)
		self.surfaceImage = LoadImage(surfaceImageURI)
		If not surfaceImage then Throw "TStationMapInfo: Cannot load image " + surfaceImageURI

		'register as sprite
		local sprite:TSprite = new TSprite.InitFromImage(surfaceImage, "map_Surface")
		GetRegistry().Set("map_Surface", sprite)

	End Method


	Method GenerateDensityDataImage:TImage(emphasizeHigh:Int = False, markPopulatedOnly:Int = False, scaleToScreenSize:Int = False)
		Local img:TImage = GenerateDensityDataImage(densityData, emphasizeHigh, markPopulatedOnly)
		if scaleToScreenSize
			img = LoadImage(ResizePixmap(LockImage(img), screenMapSize.x, screenMapSize.y))
		EndIf
		Return img
	End Method 	

	
	Function GenerateDensityDataImage:TImage(densityData:TStationMapDensityData, emphasizeHigh:int = False, markPopulatedOnly:Int = False)
		Local pix:TPixmap = CreatePixmap(densityData.width, densityData.height, PF_RGBA8888)
		Local scaleFactor:Float = 255.0 / densityData.maxPopulationDensity
		pix.ClearPixels(0)
		For local pixX:Int = 0 until pix.width
			For local pixY:Int = 0 until pix.height
				local v:Int = densityData[pixX,pixY]
				if v > 0
					If markPopulatedOnly
						pix.WritePixel(pixX,pixY, New SColor8(255, 255, 255).ToARGB())
					ElseIf emphasizeHigh
						v = Min(255, 255 * (v/Float(densityData.maxPopulationDensity)^0.85 * 1.4)) 
						pix.WritePixel(pixX,pixY, New SColor8(255, 255, 255, v).ToARGB())
					Else
						v = Min(255, v * scaleFactor)
						pix.WritePixel(pixX,pixY, New SColor8(255, 255, 255, v).ToARGB())
					EndIf
				EndIf
			Next
		Next
		Return LoadImage(pix)
	End Function


	'scale values from data to screen
	Method DataToScreen:Int(dataValue:Int, alwaysRoundUp:Int = False)
		If alwaysRoundUp
			Return Ceil(dataValue * densityDataScreenScale)
		Else
			Return Int(dataValue * densityDataScreenScale + 0.5)
		EndIf
	End Method

	'scale values from screen to data
	Method ScreenToData:Int(screenValue:Int)
		Return screenValue / densityDataScreenScale
	End Method


	'convert a given data x coordinate to a screen x coordinate
	Method DataXToScreenX:Int(x:Int)
		Return x * densityDataScreenScale + surfaceScreenOffset.x + densityDataOnSurfaceOffset.x
	End Method

	'convert a given data y coordinate to a screen y coordinate
	Method DataYToScreenY:Int(y:Int)
		Return y * densityDataScreenScale + surfaceScreenOffset.y + densityDataOnSurfaceOffset.y
	End Method

	'convert a given data x coordinate to a surface x coordinate
	Method DataXToSurfaceX:Int(x:Int)
		Return x * densityDataScreenScale + densityDataOnSurfaceOffset.x
	End Method

	'convert a given data y coordinate to a surface y coordinate
	Method DataYToSurfaceY:Int(y:Int)
		Return y * densityDataScreenScale + densityDataOnSurfaceOffset.y
	End Method


	'convert a given screen x coordinate to a data x coordinate
	'(eg. mouse clicks) 
	Method ScreenXToDataX:Int(x:Int)
		Return (x - surfaceScreenOffset.x - densityDataOnSurfaceOffset.x) / densityDataScreenScale
	End Method

	'convert a given screen y coordinate to a data y coordinate
	'(eg. mouse clicks) 
	Method ScreenYToDataY:Int(y:Int)
		Return (y - surfaceScreenOffset.y - densityDataOnSurfaceOffset.y) / densityDataScreenScale
	End Method


	'convert a given surface/topo x coordinate to a data x coordinate
	Method SurfaceXToDataX:Int(x:Int)
		Return (x - densityDataOnSurfaceOffset.x) / densityDataScreenScale
	End Method

	'convert a given surface/topo y coordinate to a data y coordinate
	Method SurfaceYToDataY:Int(y:Int)
		Return (y - densityDataOnSurfaceOffset.y) / densityDataScreenScale
	End Method


	'convert a given screen x coordinate to a surface/topo x coordinate
	Method ScreenXToSurfaceX:Int(x:Int)
		Return x - surfaceScreenOffset.x
	End Method

	'convert a given screen y coordinate to a surface/topo y coordinate
	Method ScreenYToSurfaceY:Int(y:Int)
		Return y - surfaceScreenOffset.y
	End Method	
	
	
	Method SetScreenMapSize:Int(x:Int, y:Int)
		if x = screenMapSize.x and y = screenMapSize.y Then Return False

		screenMapSize = New SVec2I(x,y)

		ResizeDensityData()
		
		Return True
	End Method
	
	
	Method ResizeDensityData()
		'we need to stretch the density map it to have the same "aspect-ratio" than the screen map
		'because this makes "circular antennas" placed on the topo map to be also
		'round shaped on the density map
		Local densityDataNewW:Int = densityData.GetRawWidth() 'Raw .. original sizes (and aspect ratio)
		Local densityDataNewH:Int = densityData.GetRawHeight()

		'scale down height or width
		Local screenMapAspectRatio:Float = screenMapSize.x/Float(screenMapSize.y)
		Local densityDataAspectRatio:Float = densityDataNewW/Float(densityDataNewH)
		Local densityDataAspectScaleFactor:Float = densityDataAspectRatio/screenMapAspectRatio
		If densityDataNewW > densityDataNewH
			densityDataNewW = densityDataNewW * densityDataAspectScaleFactor
		Else
			densityDataNewH = densityDataNewH * densityDataAspectScaleFactor
		EndIf

		TLogger.Log("ResizeDensityData()", "Orig: " + densityData.width+", " + densityData.height, LOG_DEBUG)
		TLogger.Log("ResizeDensityData()", "Aspect ratio adjusted: " + densityDataNewW+", " + densityDataNewH, LOG_DEBUG)

		'scale densityData down to a handle-able size (avoid too many points to calculate)
		If densityData.height > densityData.width
			If densityData.height > densityDataMaxDim
				densityDataNewW = Int(densityData.width * (Float(densityDataMaxDim)/densityData.height) + 0.5)
				densityDataNewH = densityDataMaxDim
			EndIf
		Else
			If densityData.width > densityDataMaxDim
				densityDataNewH = Int(densityData.height * (Float(densityDataMaxDim)/densityData.width) + 0.5)
				densityDataNewW = densityDataMaxDim
			EndIf
		EndIf
		TLogger.Log("ResizeDensityData()", "Max dim adjusted: " + densityDataNewW+", " + densityDataNewH, LOG_DEBUG)


		'stretch density data to new dimensions
		densityData.Stretch(densityDataNewW, densityDataNewH)

		'calculate pixel-kilometer factor
		densityDataScreenScale = screenMapSize.x / Float(densityData.width)
		
		TLogger.Log("ResizeDensityData()", "Stretched: " + densityData.width+", " + densityData.height, LOG_DEBUG)
		TLogger.Log("ResizeDensityData()", "Scale: " + densityDataScreenScale, LOG_DEBUG)
	End Method
End Type




Type TStationMap Extends TOwnedGameObject {_exposeToLua="selected"}
	'select whose players stations we want to see
	Field showStations:Int[4]
	'and what types we want to show
	Field showStationTypes:Int[3]

	'record store: maximum audience reached in this game for now
	Field reachedPopulationMax:Int = 0
	'record store: maximum receivers reached in this game for now
	Field reachedReceiversMax:Int = 0
	'all stations of the map owner
	Field stations:TObjectList = new TObjectList
	'amount of stations added per type
	Field stationsAdded:Int[4]
	
	'The simple sum of "antenna/cable/satellite" can be > than the map's
	'population (because a satellite already covers 100% of the map for
	'now - or a cable network covers a section which contains antennas).
	'This is why a separate reachedPopulation storage is required
	Field _reachedPopulation:Int = 0
	Field _reachedAntennaPopulation:Int = 0
	Field _reachedCableNetworkUplinkPopulation:Int = 0
	Field _reachedSatelliteUplinkPopulation:Int = 0
	Field _reachedReceivers:Int = 0
	Field _reachedAntennaReceivers:Int = 0
	Field _reachedCableNetworkUplinkReceivers:Int = 0
	Field _reachedSatelliteUplinkReceivers:Int = 0
	'need to recalculate?
	Field _reachesInvalid:Int = True {nosave}

	'Caches and lookup tables
	Field _stationsById:TIntMap {nosave}
	Field _antennasLayer:TStationMapAntennaLayer {nosave}

	'FALSE to avoid recursive handling (network)
	Global fireEvents:Int = True


	Method New(playerID:Int)
		SetOwner(playerID)
		Initialize()
		'do that manually
		'GetStationMapCollection().AddMap(obj)
	End Method
		

	Method Initialize:Int()
		stations.Clear()
		_stationsById = Null
		_antennasLayer = Null
		_reachesInvalid = True
		showStations = [1,1,1,1]
		showStationTypes = [1,1,1]
		stationsAdded = New Int[4]
		
		_reachedPopulation = 0
		_reachedAntennaPopulation = 0
		_reachedCableNetworkUplinkPopulation = 0
		_reachedSatelliteUplinkPopulation = 0
		_reachedReceivers = 0
		_reachedAntennaReceivers = 0
		_reachedCableNetworkUplinkReceivers = 0
		_reachedSatelliteUplinkReceivers = 0

		reachedPopulationMax = 0
		reachedReceiversMax = 0

		Return True
	End Method
	
	
	Method InvalidateReaches:Int()
		self._reachesInvalid = True
	End Method


	Method OnChangeStationActiveState:Int(station:TStationBase, setToActive:Int)
		'mark population sum cache to get recalculated (saves cpu time)
		InvalidateReaches()

		If TStationAntenna(station)
			Local antenna:TStationAntenna = TStationAntenna(station)

			If station.IsActive()
				'mark antenna area as used by an (additional) antenna
				'(only if layer is already created - else it automatically
				' adds this antenna already) 
				If _antennasLayer
					_GetAllAntennasLayer().AddAntenna(antenna.x, antenna.y, antenna.radius)
				EndIf

				
				'update overlapping antennas information for all affected
				'stations
				Local overlappingAntennas:TStationAntenna[] = GetOverlappingAntennas(antenna)
				If overlappingAntennas
					For Local otherAntenna:TStationAntenna = EachIn overlappingAntennas
						otherAntenna._AddOverlappedAntenna(antenna.GetID())
					Next
				EndIf
				'set them all in one
				antenna._SetOverlappedAntennas(overlappingAntennas)
				
			Else
				'mark antenna area as no longer used by an antenna
				_GetAllAntennasLayer().RemoveAntenna(antenna.x, antenna.y, antenna.radius)
			EndIf
		EndIf
	End Method


	Method DoCensus()
		InvalidateReaches()
	End Method


	Method _GetAllAntennasLayer:TStationMapAntennaLayer()
		If Not _antennasLayer
			If CurrentThread() <> MainThread()
				throw "TStationMap._GetAllAntennasLayer: cache was not initialized by the main thread"
			Else
				Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
	
				'place antenna directly over densityData (offset = 0)
				Local tmp:TStationMapAntennaLayer = New TStationMapAntennaLayer(GetStationMapCollection().surfaceData, 0, 0)
	
				'fill in all currently existing antennas
				For Local antenna:TStationAntenna = EachIn stations
					If antenna.IsActive()
						tmp.AddAntenna(antenna.x, antenna.y, antenna.radius)
					EndIf
				Next
				_antennasLayer=tmp
			EndIf
		EndIf
		
		Return _antennasLayer
	End Method
	
	
	'returns additional population covered when placing a station at the given coord
	'(only a fraction of it uses antennas - multiply with AntennaShare to get
	' the effective value)
	Method GetAddedAntennaPopulation:Int(dataX:Int, dataY:Int, radius:Int = 0) {_exposeToLua}
		'LUA scripts pass a default radius of "0" if they do not pass a variable at all
		If radius <= 0 Then radius = GetStationMapCollection().antennaStationRadius

		Return _GetAllAntennasLayer().GetAddedAntennaPopulation(dataX, dataY, radius, GetStationMapCollection().mapInfo)
	End Method


	'returns loss of covered population when removing a station at the given coord
	'(only a fraction of it uses antennas - multiply with AntennaShare to get
	' the effective value)
	Method GetRemovedAntennaPopulation:Int(dataX:Int, dataY:Int, radius:Int = 0)
		'LUA scripts pass a default radius of "0" if they do not pass a variable at all
		If radius <= 0 Then radius = GetStationMapCollection().antennaStationRadius
		Return _GetAllAntennasLayer().GetRemovedAntennaPopulation(dataX, dataY, radius, GetStationMapCollection().mapInfo)
	End Method


	'returns additional receivers when placing a station at the given coord
	Method GetAddedAntennaReceivers:Int(dataX:Int, dataY:Int, radius:Int = 0 ) {_exposeToLua}
		Local antennaShare:Float = GetPopulationAntennaShare(dataX, dataY)
		Return GetAddedAntennaPopulation(dataX, dataY, radius) * antennaShare
	End Method


	'returns receiver loss when selling a station at the given coord
	'param is station (not coords) to avoid ambiguity of multiple
	'stations at the same spot
	Method GetRemovedAntennaReceivers:Int(station:TStationAntenna) {_exposeToLua}
		Local antennaShare:Float = GetPopulationAntennaShare(station.x, station.y)
		Return GetRemovedAntennaPopulation(station.x, station.y, station.radius) * antennaShare
	End Method


	'returns the maximum receivers amount of the stations on that map
	'(receivers = people who could watch TV at all - via the defined receiver types (antennas, cable..))
	Method GetReceivers:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return _GetReachedReceivers()
	End Method

	
	'returns the maximum population of the stations on that map
	'(population = all people, audience = people who could watch TV at all)
	Method GetPopulation:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return _GetReachedPopulation()
	End Method


	Method _GetReachedPopulation:Int()
		Return Max(0, self._reachedPopulation)
	End Method


	Method _GetReachedReceivers:Int()
		Return Max(0, Self._reachedAntennaReceivers + Self._reachedSatelliteUplinkReceivers + Self._reachedCableNetworkUplinkReceivers)
	End Method


	'returns the maximum population reached (only) that map via antennas
	'(population = all people, audience = people who could watch TV at all)
	Method GetAntennaPopulation:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return Max(0, Self._reachedAntennaPopulation)
	End Method


	'returns the maximum receiver amount reached (only) that map via cablenetwork uplinks
	'(population = all people, receivers = people who could watch TV via some installed antenna)
	Method GetAntennaReceivers:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return Max(0, Self._reachedAntennaReceivers)
	End Method



	'returns the maximum population reached (only) that map via satellite uplinks
	'(population = all people, audience = people who could watch TV at all)
	Method GetSatelliteUplinkPopulation:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return Max(0, Self._reachedSatelliteUplinkPopulation)
	End Method


	'returns the maximum receiver amount reached (only) that map via cablenetwork uplinks
	'(population = all people, receivers = people who could watch TV via the uplinks)
	Method GetSatelliteUplinkReceivers:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return Max(0, Self._reachedSatelliteUplinkReceivers)
	End Method


	'returns the maximum population reached (only) that map via cablenetwork uplinks
	'(population = all people, audience = people who could watch TV at all)
	Method GetCableNetworkUplinkPopulation:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return Max(0, Self._reachedCableNetworkUplinkPopulation)
	End Method


	'returns the maximum receiver amount reached (only) that map via cablenetwork uplinks
	'(population = all people, receivers = people who could watch TV via the uplinks)
	Method GetCableNetworkUplinkReceivers:Int() {_exposeToLua}
		If _reachesInvalid Then RecalculateReaches()

		Return Max(0, Self._reachedCableNetworkUplinkReceivers)
	End Method


	Function GetReceiverLevel:Int(receivers:Int)
		'put this into GameRules?
		If receivers < 2500000
			Return 1
		ElseIf receivers < 2500000 * 2 '5mio
			Return 2
		ElseIf receivers < 2500000 * 5 '12,5 mio
			Return 3
		ElseIf receivers < 2500000 * 9 '22,5 mio
			Return 4
		ElseIf receivers < 2500000 * 14 '35 mio
			Return 5
		ElseIf receivers < 2500000 * 20 '50 mio
			Return 6
		ElseIf receivers < 2500000 * 28 '70 mio
			Return 7
		ElseIf receivers < 2500000 * 40 '100 mio
			Return 8
		ElseIf receivers < 2500000 * 60 '150 mio
			Return 9
		ElseIf receivers < 2500000 * 100 '250 mio
			Return 10
		Else
			Return 11
		EndIf
	End Function

	Function GetReceiversForLevel:Int(level:Int)
		'put this into GameRules?
		Select level
			Case 1
				Return 0
			Case 2
				Return 2500000
			Case 3
				Return 2500000 * 2 '5mio
			Case 4
				Return 2500000 * 5 '12,5 mio
			Case 5 
				Return 2500000 * 9 '22,5 mio
			Case 6
				Return 2500000 * 14 '35 mio
			Case 7
				Return 2500000 * 20 '50 mio
			Case 8
				Return 2500000 * 28 '70 mio
			Case 9
				Return 2500000 * 40 '100 mio
			Case 10
				Return 2500000 * 60 '150 mio
			Default
				Return 2500000 * 100 '250 mio
		EndSelect
	End Function

	Method GetPopulationCoverage:Float() {_exposeToLua}
		Return Float(GetPopulation()) / Float(GetStationMapCollection().GetPopulation())
	End Method


	Method GetReceiverCoverage:Float() {_exposeToLua}
		Return Float(GetReceivers()) / Float(GetStationMapCollection().GetReceivers())
	End Method


	'return all antenna stations covering the given coordinates
	Method GetAntennasByXY:TStationAntenna[](X:Int, Y:Int, exactPosition:Int = True) {_exposeToLua}
		Local res:TStationAntenna[]
		For Local antenna:TStationAntenna = EachIn stations
			If exactPosition 
				If antenna.X <> X Or antenna.Y <> Y Then Continue
			Else
				'x,y outside of station-circle?
				If antenna.radius < Sqr((X - antenna.X)^2 + (Y - antenna.Y)^2) Then Continue
			EndIf
			res :+ [antenna]
		Next
		Return res
	End Method


	'returns best suiting antenna (x,y must be station position or "in range")
	Method GetAntennaByXY:TStationAntenna(X:Int, Y:Int, exactPosition:Int = True) {_exposeToLua}
		Local best:TStationAntenna
		Local bestDistanceSquared:Int = -1
		
		'For antenna stations it chooses the one containing the given
		'coordinate in its "circle" and being the nearest position wise
		
		For Local antenna:TStationAntenna = EachIn stations
			If exactPosition
				If antenna.X = X And antenna.Y = Y Then Return antenna
			Else
				'or x,y outside of station-circle?
				Local distanceSquared:Int = (X - antenna.X)^2 + (Y - antenna.Y)^2
				If antenna.radius^2 < distanceSquared Then Continue
				
				If distanceSquared < bestDistanceSquared Or bestDistanceSquared = -1
					bestDistanceSquared = distanceSquared
					best = antenna
				EndIf
			EndIf
		Next
		Return best
	End Method


	Method GetOverlappingAntennas:TStationAntenna[](antenna:TStationAntenna)
		Local result:TStationAntenna[]
		If Not antenna then Return result
		
		For Local otherAntenna:TStationAntenna = EachIn stations
			if otherAntenna = antenna Then Continue

			'Local distX:Int = Abs(antenna.x - otherAntenna.x)
			'Local distY:Int = Abs(antenna.y - otherAntenna.y)
			'if distX > antenna.radius and distX > otherAntenna.radius Then Continue 

			'(r1−r2)^2 >= (x1−x2)^2+(y1−y2)^2
'			if (antenna.radius - otherAntenna.radius) * (antenna.radius - otherAntenna.radius) >= (antenna.x - otherAntenna.x) * (antenna.x - otherAntenna.x) + (antenna.y - otherAntenna.y) * (antenna.y - otherAntenna.y)
			Local circleDist:Int = sqr((antenna.x - otherAntenna.x) * (antenna.x - otherAntenna.x) + (antenna.y - otherAntenna.y) * (antenna.y - otherAntenna.y))
			if circleDist < antenna.radius + otherAntenna.radius
				result :+ [otherAntenna]
			EndIf
		Next
		
		Return result
	End Method



	Method GetStation:TStationBase(stationID:Int)
		'generate LUT if needed
		If Not _stationsById
			Self._stationsById = New TIntMap
			For Local station:TStationBase = EachIn stations
				Self._stationsById.Insert(station.GetID(), station)
			Next
		EndIf
		
		Return TStationBase(Self._stationsById.ValueForKey(stationID))
	End Method
	
	
	Method GetStation:TStationBase(stationGUID:String)
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
	Method GetStationsBySectionName:TStationBase[](sectionName:String, stationType:Int=0)
		Local result:TStationBase[5]
		Local found:Int = 0 
		For Local station:TStationBase = EachIn stations
			If stationType > 0 And station.stationType <> stationType Then Continue
			If station.GetSectionName() = sectionName 
				If found >= result.Length Then result = result[.. result.Length + 5]
				result[found] = station
				found :+ 1
			EndIf
		Next
		If found <> result.Length
			result = result[.. found]
		EndIf
		Return result
	End Method


	Method GetCableNetworkUplink:TStationBase(sectionName:String)
		For Local station:TStationBase = EachIn stations
			If station.stationType <> TVTStationType.CABLE_NETWORK_UPLINK Then Continue
			If station.GetSectionName() = sectionName Then Return station
		Next
		Return Null
	End Method


	Method GetCableNetworkUplink:TStationBase(cableNetworkID:Int)
		For Local station:TStationCableNetworkUplink = EachIn stations
			If station.providerID = cableNetworkID Then Return station
		Next
		Return Null
	End Method


	Method GetCableNetworkUplink:TStationBase(cableNetwork:TStationMap_CableNetwork)
		If Not cableNetwork Then Return Null
		Return GetCableNetworkUplink(cableNetwork.GetID())
	End Method


	Method GetSatelliteUplink:TStationBase(satelliteID:Int)
		For Local station:TStationSatelliteUplink = EachIn stations
			If station.providerID = satelliteID Then Return station
		Next
		Return Null
	End Method


	Method GetSatelliteUplink:TStationBase(satellite:TStationMap_Satellite)
		If Not satellite Then Return Null
		Return GetSatelliteUplink(satellite.GetID())
	End Method


	'returns the amount of stations a player has
	Method GetStationCount:Int(stationType:Int=0) {_exposeToLua}
		If stationType = 0
			Return stations.count()
		Else
			Local result:Int = 0
			For Local s:TStationBase = EachIn stations
				If s.stationType = stationType Then result :+ 1
			Next
			Return result
		EndIf
	End Method


	Method GetSatelliteUplinksCount:Int(onlyActive:Int = False)
		Return TStationMapCollection.GetSatelliteUplinksCount(stations, onlyActive)
	End Method


	Method GetCableNetworkUplinksInSectionCount:Int(sectionName:String, onlyActive:Int = False)
		Return TStationMapCollection.GetCableNetworkUplinksInSectionCount(stations, sectionName, onlyActive)
	End Method


	Method GetStationsToProviderCount:Int(providerID:Int, includeActive:Int = False, includeShutdown:Int = False)
		Return TStationMapCollection.GetStationsToProviderCount(stations, providerID, includeActive, includeShutdown)
	End Method


	Method HasStation:Int(station:TStationBase)
		Return stations.contains(station)
	End Method


	Method GetRandomAntennaCoordinateOnMap:SVec2I(checkBroadcastPermission:Int=True, requiredBroadcastPermissionState:Int=True)
		Local dataX:Int = Rand(35, GetStationMapCollection().mapInfo.densityData.width)
		Local dataY:Int = Rand(1, GetStationMapCollection().mapInfo.densityData.height)
		Local station:TStationAntenna = New TStationAntenna.Init(new SVec2I(dataX, dataY), owner)
		If station.GetPrice() < 0 Then Return New SVec2I(-1,-1)
		
		If checkBroadcastPermission And GetStationMapCollection().GetSectionByDataXY(dataX, dataY).HasBroadcastPermission(owner, TVTStationType.ANTENNA) <> requiredBroadcastPermissionState Then Return Null
		 
		Return New SVec2I(dataX, dataY)
	End Method
	

	Method GetRandomAntennaCoordinateInPlayerSections:SVec2I()
		Local sections:TStationMapSection[] = GetStationMapCollection().GetSectionsFiltered(owner, True, True, TVTStationType.ANTENNA)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSections(sections)
	End Method


	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSections:SVec2I(sections:TStationMapSection[], allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSections(sections, allowSectionCrossing)
	End Method


	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSections:SVec2I(sectionNames:String[], allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSections(sectionNames, allowSectionCrossing)
	End Method


	'specific section
	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSection:SVec2I(sectionName:String, allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSection(sectionName, allowSectionCrossing)
	End Method


	'specific section
	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSection:SVec2I(section:TStationMapSection, allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSection(section, allowSectionCrossing)
	End Method


	Method CheatMaxAudience:Int()
		throw "Todo: reimplement CheatMaxAudience"
		rem
		Local reachLevelBefore:Int = GetReachLevel(GetPopulation())
		cheatedMaxReach = True
		reach = GetStationMapCollection().population

		For Local s:TStationMapSection = EachIn GetStationMapCollection().sections
			s.InvalidateData()
		Next

		If GetReachLevel(reach) <> reachLevelBefore
			TriggerBaseEvent(GameEventKeys.StationMap_OnChangeReachLevel, New TData.addInt("reachLevel", GetReachLevel(reach)).AddInt("reachLevelBefore", reachLevelBefore), Self )
		EndIf

		Return True
		endrem
	End Method
	
	
	'recalculates a player's stations covered population (and additionally caches receivers counts)
	'internal method without side effects like sending events
	Method _RecalculateReaches()
		'sum of this can be > a maps population (eg antenna in bavaria + cable network in bavaria > bavaria's population)
		self._reachedAntennaPopulation = GetStationMapCollection().GetAntennaPopulation(owner)
		self._reachedCableNetworkUplinkPopulation = GetStationMapCollection().GetCableNetworkUplinkPopulation(stations)
		self._reachedSatelliteUplinkPopulation = GetStationMapCollection().GetSatelliteUplinkPopulation(stations)

		'so coverage of all potential station types needs to be calculated individually
		'
		'as soon as:
		'- a satellite is used, whole map's population is reached
		'- a cable network is used, antenna population of the section can be ignored
		'- only antennas are used, their covered population is the total population
		self._reachedPopulation = 0
		if self._reachedSatelliteUplinkPopulation > 0
			'do NOT use "= self._reachedSatelliteUplinkPopulation" as 
			'this value depends on the satellite share on the sections
			self._reachedPopulation = GetStationMapCollection().GetPopulation()
		ElseIf self._reachedCableNetworkUplinkPopulation > 0
			For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
				If section.GetCableNetworkUplinkPopulation() > 0
					self._reachedPopulation :+ section.GetPopulation()
				Else
					self._reachedPopulation :+ section.GetAntennaPopulation(owner)
				EndIf
			Next
		Else
			self._reachedPopulation = self._reachedAntennaPopulation
		EndIf
		

		self._reachedAntennaReceivers = GetStationMapCollection().GetAntennaReceivers(owner)
		self._reachedCableNetworkUplinkReceivers = GetStationMapCollection().GetCableNetworkUplinkReceivers(stations)
		self._reachedSatelliteUplinkReceivers = GetStationMapCollection().GetSatelliteUplinkReceivers(stations)
		'ATTENTION: You cannot simply call GetReceivers() because it can
		'           call RecalculateReaches() -> so call the internal one instead
		self._reachedReceivers = self._GetReachedReceivers()

		'update record
		self.reachedPopulationMax = Max(self.reachedPopulationMax, self._GetReachedPopulation())
		'TODO geht das nicht schief, wenn die Antennenreichweite sinkt?
		self.reachedReceiversMax = Max(self.reachedReceiversMax, self._GetReachedReceivers())

		'current calculation is done now
		self._reachesInvalid = False
	End Method
	

	'recalculates a player's stations covered population (and additionally caches receivers counts)
	'this method also emits events if reaches change 
	Method RecalculateReaches()
		'store value before calculations
		Local reachedReceiversBefore:Int = self._reachedReceivers 
		
		'call actual calculations
		_RecalculateReaches()

		'attention: this check only works as long as reaches cannot
		'stay the same but their "target group shares" change (so selling
		'a station where only men reside and buying one with only female
		'kids and seniors)
		If reachedReceiversBefore <> self._reachedReceivers
			'inform others about new audience reach
			TriggerBaseEvent(GameEventKeys.StationMap_OnRecalculateAudienceSum, New TData.AddInt("reach", self._reachedReceivers).AddInt("reachBefore", reachedReceiversBefore).AddInt("playerID", owner), Self )
			'inform others about a change of the reach level
			Local reachLevel:Int = TStationMap.GetReceiverLevel(self._reachedReceivers)
			Local reachLevelBefore:Int = TStationMap.GetReceiverLevel(reachedReceiversBefore)
			If reachLevel <> reachLevelBefore
				TriggerBaseEvent(GameEventKeys.StationMap_OnChangeReachLevel, New TData.AddInt("reachLevel", reachLevel).AddInt("reachLevelBefore", reachLevelBefore), Self )
			EndIf
		EndIf
	End Method


	'returns the antenna share for the given data coordinate
	Method GetPopulationAntennaShare:Float(dataX:Int, dataY:Int)
		Return GetStationMapCollection().GetPopulationAntennaShare(dataX, dataY)
	End Method


	Method CanAddStation:Int(station:TStationBase)
		'only one network per section and player allowed
		If TStationCableNetworkUplink(station) And GetCableNetworkUplink(station.GetSectionName()) Then Return False

		'TODO: ask if the station is ok with it (eg. satlink asks satellite first)
		'for now:
		'only add sat links if station can subscribe to satellite
		Local provider:TStationMap_BroadcastProvider
		If TStationSatelliteUplink(station)
			provider = GetStationMapCollection().GetSatellite(station.providerID)
			If Not provider Then Return False

		ElseIf TStationCableNetworkUplink(station)
			provider = GetStationMapCollection().GetCableNetwork(station.providerID)
			If Not provider Then Return False

		EndIf

		If provider
			If provider.IsSubscribedChannel(owner) Then Return False
			If provider.CanSubscribeChannel(owner) <= 0 Then Return False
		EndIf

		Return True
	End Method


	'sell a station at the given position in the list
	Method SellStationAtPosition:Int(position:Int)
		Return SellStation( getStationAtIndex(position) )
	End Method


	Method SellStation:Int(station:TStationBase)
		If station Then Return RemoveStation(station, True)
		Return False
	End Method


	Method GetTotalStationBuyPrice:Int(station:TStationBase)
		If Not station Then Return 0

		Return station.GetTotalBuyPrice()
	End Method


	Method AddStation:Int(station:TStationBase, buy:Int=False)
		If Not station Then Return False

		''check if placement is allowed/possible
		If Not CanAddStation(station) Then Return False


		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(station.GetSectionName())
		Local buyPermission:Int = False
		Local totalPrice:Int = GetTotalStationBuyPrice(station)
		'check if there is a governmental broadcast/build permission
		'also allow "granted" to be in another section?
		If Not station.HasFlag(TVTStationFlag.ILLEGAL) ' and not station.HasFlag(TVTStationFlag.GRANTED)
			'stations without assigned section cannot have a permission...
			If section And section.NeedsBroadcastPermission(owner, station.stationType) And Not section.HasBroadcastPermission(owner)
				buyPermission = True
			EndIf
		EndIf


		'try to buy it (does nothing if already done)
		If buy
			'check if we can pay both things
			If section And buyPermission
				'fail if permission is needed but cannot get obtained
				If section.NeedsBroadcastPermission(owner, station.stationType) And Not section.HasBroadcastPermission(owner, station.stationType)
					If Not section.CanGetBroadcastPermission(owner) Then Return False
				EndIf
				If Not GetPlayerFinance(owner).CanAfford(totalPrice) Then Return False
			EndIf

			'if needed buy the permission
			If section And buyPermission And Not section.HasBroadcastPermission(owner, station.stationType)
				If Not section.BuyBroadcastPermission(owner, station.stationType, -1)
					Return False
				EndIf
			EndIf

			'(try to) buy the actual station
			If Not station.Buy(owner) Then Return False
		EndIf


		'set to paid in all cases
		station.SetFlag(TVTStationFlag.PAID, True)

		'so station names "grow"
		stationsAdded[station.stationType] :+ 1

		'give it a name
		If station.name = "" Then station.name = "#"+stationsAdded[station.stationType]

		stations.AddLast(station)

		'DO NOT refresh the share map as ths would increase potential
		'audience in this moment. Generate it as soon as a station gets
		'"ready" (before next audience calculation - means xx:04 or xx:59)
		'GetStationMapCollection().GenerateShareMaps()

		'ALSO DO NOT recalculate audience of channel
		'RecalculateAudienceSum()
		TLogger.Log("TStationMap.AddStation", "Player"+owner+" buys broadcasting station ["+station.GetTypeName()+"] in section ~q" + station.GetSectionName() + "~q for " + station.price + " Euro (population=" + station.GetPopulation() + ", receivers=" + station.GetReceivers() + ")", LOG_DEBUG)

		'sign potential contracts (= add connections)
		station.SignContract()

		'inform the station
		station.OnAddToMap()

		'emit an event so eg. network can recognize the change
		If fireEvents 
			TriggerBaseEvent(GameEventKeys.Stationmap_AddStation, New TData.Add("station", station), Self )
		EndIf

		Return True
	End Method


	Method RemoveStation:Int(station:TStationBase, sell:Int=False, forcedRemoval:Int=False)
		If Not station Then Return False

		If Not forcedRemoval
			'not allowed to sell this station
			If Not station.HasFlag(TVTStationFlag.SELLABLE) Then Return False

			'check if we try to sell our last station...
			If stations.count() = 1
				TriggerBaseEvent(GameEventKeys.StationMap_OnTrySellLastStation, Null, Self)
				Return False
			EndIf
		EndIf

		If sell And Not station.sell() And Not forcedRemoval Then Return False

		stations.Remove(station)

		If sell
			TLogger.Log("TStationMap.RemoveStation", "Player "+owner+" sells broadcasting station for " + station.getSellPrice() + " Euro (receivers=" + station.GetReceivers() + ", population=" + station.GetPopulation()+")", LOG_DEBUG)
		Else
			TLogger.Log("TStationMap.RemoveStation", "Player "+owner+" trashes broadcasting station for 0 Euro (receivers=" + station.GetReceivers() + ", population=" + station.GetPopulation()+")", LOG_DEBUG)
		EndIf

		'cancel potential contracts (= remove connections)
		station.CancelContracts()

		'inform the station about the removal
		station.OnRemoveFromMap()

		if station.IsActive() and TStationAntenna(station)
			Local antenna:TStationAntenna = TStationAntenna(station)

			'mark antenna area as no longer used by an antenna
			_GetAllAntennasLayer().RemoveAntenna(antenna.x, antenna.y, antenna.radius)

			'remove from "overlapped" stations:
			if antenna._overlappedAntennaIDs
				For local overlappedAntennaID:Int = EachIn antenna._overlappedAntennaIDs
					Local overlappedAntenna:TStationAntenna = TStationAntenna(GetStation(overlappedAntennaID))
					if overlappedAntenna Then overlappedAntenna._RemoveOverlappedAntenna(antenna.GetID())
				Next
				antenna._SetOverlappedAntennas(Null)
			EndIf
		EndIf


		'invalidate (cached) share data of surrounding sections
		For Local s:TStationMapSection = EachIn GetStationMapCollection().GetSectionsConnectedToStation(station)
			s.InvalidateData()
		Next
		'set the owning stationmap to "changed" so only this single
		'population reach gets recalculated (saves cpu time)
		InvalidateReaches()

		'when station is sold, audience will decrease,
		'while a buy will not increase the current audience but the
		'next block (news or programme)
		'-> handled in main.bmx with a listener to "stationmap.removeStation"

		'emit an event so eg. network can recognize the change
		If fireEvents
			'explicitly trigger an event that will be processed by the main thread only
			'TriggerBaseEvent(GameEventKeys.StationMap_RemoveStation, New TData.Add("station", station), Self, Null, 1)
			EventManager.RegisterEvent(TEventBase.Create(GameEventKeys.StationMap_RemoveStation, New TData.Add("station", station), Self))
		EndIf

		Return True
    End Method


	Method CalculateStationCosts:Int() {_exposeToLua}
		Local costs:Int = 0
		For Local Station:TStationBase = EachIn stations
			costs :+ station.GetRunningCosts()
		Next
		Return costs
	End Method


	Method GetShowStation:Int(channelNumber:Int)
		If channelNumber > showStations.Length Or channelNumber <= 0 Then Return False

		Return showStations[channelNumber-1]
	End Method


	Method SetShowStation(channelNumber:Int, enable:Int)
		If channelNumber > showStations.Length Or channelNumber <= 0 Then Return

		showStations[channelNumber-1] = enable
	End Method


	Method GetShowStationType:Int(stationType:Int)
		If stationType > showStationTypes.Length Or stationType <= 0 Then Return False

		Return showStationTypes[stationType-1]
	End Method


	Method SetShowStationType(stationType:Int, enable:Int)
		If stationType > showStationTypes.Length Or stationType <= 0 Then Return

		showStationTypes[stationType-1] = enable
	End Method


	Method Update:Int()
		If self._reachesInvalid Then self.RecalculateReaches()

		'delete unused
		If GetStationMapCollection().stationMaps.Length < showStations.Length
			showStations = showStations[.. GetStationMapCollection().stationMaps.Length + 1]
		'add new one (show them by default)
		ElseIf GetStationMapCollection().stationMaps.Length > showStations.Length
			Local Add:Int = GetStationMapCollection().stationMaps.Length - showStations.Length

			showStations = showStations[.. showStations.Length + Add]

			For Local i:Int = 0 Until Add
				showStations[showStations.Length - 1 - i] = 1
			Next
		EndIf

		UpdateStations()
	End Method


	Method UpdateStations()
		For Local station:TStationBase = EachIn stations
			station.Update()
		Next
	End Method


	'eg. a cable network might tint the topography images
	Method DrawStationBackgrounds(stationTypes:Int[] = Null)
		If stationTypes And stationTypes.Length < TVTStationType.count Then stationTypes = stationTypes[.. TVTStationType.count]

		For Local station:TStationBase = EachIn stations
			'ignore unwanted stations
			If stationTypes And stationTypes[station.stationType-1] = 0 Then Continue
			station.DrawBackground()
		Next
	End Method


	Method DrawStations(stationTypes:Int[] = Null)
		If stationTypes And stationTypes.Length < TVTStationType.count Then stationTypes = stationTypes[.. TVTStationType.count]

		For Local station:TStationBase = EachIn stations
			'ignore unwanted stations
			If stationTypes And stationTypes[station.stationType-1] = 0 Then Continue
			station.Draw()
		Next
	End Method


	'draw a players stationmap
	Method Draw()
		SetColor 255,255,255

		'draw all stations from all players (except filtered)
		For Local map:TStationMap = EachIn GetStationMapCollection().stationMaps
			If Not GetShowStation(map.owner) Then Continue
			map.DrawStationBackgrounds(showStationTypes)
		Next
		For Local map:TStationMap = EachIn GetStationMapCollection().stationMaps
			If Not GetShowStation(map.owner) Then Continue
			map.DrawStations(showStationTypes)
		Next
	End Method
End Type




Type TStationBase Extends TOwnedGameObject {_exposeToLua="selected"}
	'location in relation to the density data 0,0
	'for satellites it is the "starting point", for cable networks and
	'antenna stations a point in the section / state
	Field x:Int {_exposeToLua="readonly"}
	Field y:Int {_exposeToLua="readonly"}

	Field price:Int	= -1

	Field providerID:Int {_exposeToLua="readonly"}

	'daily costs for "running" the station
	Field runningCosts:Int = -1
	Field owner:Int = 0
	'time at which the station was bought
	Field built:Long = 0
	'time at which the station gets active (again)
	Field activationTime:Long = -1
	Field name:String = ""
	Field stationType:Int = 0
	'various settings (paid, fixed price, sellable, active...)
	Field _flags:Int = 0
	
	Field listSpriteNameOn:String = "gfx_datasheet_icon_antenna.on"
	Field listSpriteNameOff:String = "gfx_datasheet_icon_antenna.off"


	'CACHES
	'======
	'section data
	Field _cache_SectionName:String = "" {nosave}
	Field _cache_SectionISO3116Code:String = "" {nosave}

	'population shares/fractions:
	'these values can be recreated "on the fly" and multiplying them
	'with the complete maps' population will result in the
	'population of interest
	'multiply again with station-type specific receiver shares and you get
	'the receiver amounts of interest.
	'-> changes to the maps' population will automatically change the
	'stations values without requiring recalculation.

	'fraction of complete maps' population covered
	Field _cache_PopulationShare:Float = -1 {nosave}
	'fraction of complete maps' population covered station exclusively (no others) 
	Field _cache_StationExclusivePopulationShare:Float = -1 {nosave}
	'fraction of complete maps' population covered channel exclusively (subtract other same-station-type stations of owner/channel) 
	'so to say the "increase" added through this station
	Field _cache_ChannelExclusivePopulationShare:Float = -1 {nosave}
	Field _cache_revision:Int = 0 {nosave}


	Method Init:TStationBase(dataPos:SVec2I, owner:Int)
		Self.owner = owner
		Self.x = dataPos.x
		Self.y = dataPos.y

		Self.price = -1
		Self.built = GetWorldTime().GetTimeGone()
		Self.activationTime = -1

		Self.SetFlag(TVTStationFlag.FIXED_PRICE, (price <> -1))
		'by default each station could get sold
		Self.SetFlag(TVTStationFlag.SELLABLE, True)

		Return Self
	End Method


	Method GenerateGUID:String()
		Return "stationbase-"+id
	End Method


	Method HasFlag:Int(flag:Int)
		Return (_flags & flag) <> 0
	End Method


	Method SetFlag(flag:Int, enable:Int=True)
		If enable
			_flags :| flag
		Else
			_flags :& ~flag
		EndIf
	End Method


	'returns the age in days
	Method GetAgeInDays:Int()
		Return GetWorldTime().GetDay() - GetWorldTime().GetDay(Self.built)
	End Method


	'returns the age
	Method GetAge:Long()
		Return GetWorldTime().GetTimeGone() - Self.built
	End Method


	Method GetActivationTime:Long()
		Return activationTime
	End Method
	
	
	Method SetPosition(dataX:Int, dataY:Int)
		'nothing to do?
		if self.x = dataX and self.y = dataY Then Return
		
		self.x = dataX
		self.y = dataY

		_InvalidateSectionDataCache()
		_InvalidatePopulationShareCache()
	End Method
	
	
	Method SetProvider(providerID:Int)
		'nothing to do?
		if self.providerID = providerID Then Return
		
		self.providerID = providerID
		
		_InvalidatePopulationShareCache()
	End Method


	Method _InvalidatePopulationShareCache()
		self._cache_PopulationShare = -1
		self._cache_ChannelExclusivePopulationShare = -1
		self._cache_StationExclusivePopulationShare = -1

		self._cache_revision :+ 1
	End Method
	

	'returns percentage of receivers amongst the population
	'this is a station type specific implementation
	Method GetPopulationReceiverShare:Float() abstract {_exposeToLua}
	
	'(set flags to True to pay attention to certain exclusiveness)
	'this is a station type specific implementation
	Method GetPopulationShare:Float(exclusiveToOwnChannel:Int = False, exclusiveToOtherChannels:Int = False) abstract


	'population covered by the station
	'(only stations of same type are taken into consideration - types are distinct)
	Method GetPopulation:Int() {_exposeToLua}
		If self._cache_PopulationShare < 0
			self._cache_PopulationShare = GetPopulationShare(False, False)
		EndIf
		Return self._cache_PopulationShare * GetStationMapCollection().GetPopulation()
	End Method


	'population not shared with stations owned by other channels/other players
	'(only stations of same type are taken into consideration - types are distinct)
	Method GetChannelExclusivePopulation:Int() {_exposeToLua}
		If self._cache_ChannelExclusivePopulationShare < 0
			self._cache_ChannelExclusivePopulationShare = GetPopulationShare(False, True)
		EndIf
		Return self._cache_ChannelExclusivePopulationShare * GetStationMapCollection().GetPopulation()
	End Method
		

	'population not shared with other stations owned by the same channel/player
	'(only stations of same type are taken into consideration - types are distinct)
	Method GetStationExclusivePopulation:Int() {_exposeToLua}
		If self._cache_StationExclusivePopulationShare < 0
			self._cache_StationExclusivePopulationShare = GetPopulationShare(True, False)
		EndIf
		Return self._cache_StationExclusivePopulationShare * GetStationMapCollection().GetPopulation()
	End Method


	'receivers covered by the station
	'(only stations of same type are taken into consideration - types are distinct)
	Method GetReceivers:Int() {_exposeToLua}
		Return GetPopulation() * GetPopulationReceiverShare()
	End Method


	'receivers not shared with stations owned by other channels/other players
	'(only stations of same type are taken into consideration - types are distinct)
	Method GetChannelExclusiveReceivers:Int() {_exposeToLua}
		Return GetChannelExclusivePopulation() * GetPopulationReceiverShare()
	End Method
		

	'receivers not shared with other stations owned by the same channel/player
	'(only stations of same type are taken into consideration - types are distinct)
	Method GetStationExclusiveReceivers:Int() {_exposeToLua}
		Return GetStationExclusivePopulation() * GetPopulationReceiverShare()
	End Method


	'TODO: still needed? (can be retrieved "by hand" via GetChannelExclusivePopulation()/GetPopulation()
	'get the relative population increase of that station
	Method GetRelativeExclusivePopulation:Float() {_exposeToLua}
		'fill cache if needed
		If self._cache_ChannelExclusivePopulationShare < 0 Then GetChannelExclusivePopulation()
		Return self._cache_ChannelExclusivePopulationShare
	End Method


	'TODO: still needed? (can be retrieved "by hand" via GetChannelExclusiveReceivers()/GetReceivers()
	'get the relative receiver increase of that station
	Method GetRelativeExclusiveReceivers:Float() {_exposeToLua}
		Return GetRelativeExclusivePopulation() * GetPopulationReceiverShare()
	End Method
	

	Method _InvalidateSectionDataCache:Int()
		self._cache_SectionName = ""
		self._cache_SectionISO3116Code = ""
	End Method
	
	
	Method _FillSectionDataCache:Int()
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByDataXY(self.x, self.y)
		If section 
			_cache_SectionName = section.name
			_cache_SectionISO3116Code = section.iso3116Code
		'Else
		'	print "Station " + GetName() + " outside of section: " + self.x + "," + self.y
		'	end
		EndIf
	End Method
	

	Method GetSectionName:String() {_exposeToLua}
		If Not _cache_SectionName Then _FillSectionDataCache()

		Return _cache_SectionName
	End Method


	Method GetSectionISO3166Code:String() {_exposeToLua}
		If Not _cache_SectionISO3116Code Then _FillSectionDataCache()
		
		Return _cache_SectionISO3116Code
	End Method


	Method GetProvider:TStationMap_BroadcastProvider()
		Return Null 'no provider defined for base stations (and antennas)
	End Method


	Method GetSellPrice:Int() {_exposeToLua}
		'price decreasing with age
		Local offer:Int = Int((0.8 - 0.1 * GetAgeInDays()) * GetPrice())
		'waste removal costs
		Local minPrice:Int = -GetPrice()/2

		Return Max(offer, minPrice)
	End Method


	'what was paid for it?
	Method GetPrice:Int() {_exposeToLua}
		If price < 0 Then Return GetBuyPrice()
		Return price
	End Method


	'current price
	Method GetBuyPrice:Int() {_exposeToLua}
		Return 0
	End Method


	'price including potential permission fees
	Method GetTotalBuyPrice:Int() {_exposeToLua}
		Local buyPrice:Int = GetBuyPrice()

		'check if there is a governmental broadcast/build permission
		'also allow "granted" to be in another section?
		If Not HasFlag(TVTStationFlag.ILLEGAL) ' and not HasFlag(TVTStationFlag.GRANTED)
			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			'stations without assigned section cannot have a permission...
			If section And section.NeedsBroadcastPermission(owner, stationType) And Not section.HasBroadcastPermission(owner, stationType)
				buyPrice :+ section.GetBroadcastPermissionPrice(owner, stationType)
			EndIf
		EndIf
		Return buyPrice
	End Method


	Method GetName:String() {_exposeToLua}
		Return name
	End Method


	Method GetTypeName:String() {_exposeToLua}
		Return "stationbase"
	End Method


	Method GetLongName:String() {_exposeToLua}
		If GetName() Then Return GetTypeName() + " " + GetName()
		Return GetTypeName()
	End Method


	Method CanBroadcast:Int() {_exposeToLua}
		Return HasFlag(TVTStationFlag.ACTIVE) And Not HasFlag(TVTStationFlag.SHUTDOWN)
	End Method


	Method IsActive:Int() {_exposeToLua}
		Return HasFlag(TVTStationFlag.ACTIVE)
	End Method


	Method IsShutdown:Int() {_exposeToLua}
		Return HasFlag(TVTStationFlag.SHUTDOWN)
	End Method


	Method IsCableNetworkUplink:Int() {_exposeToLua}
		Return stationType = TVTStationType.CABLE_NETWORK_UPLINK
	End Method


	Method IsSatelliteUplink:Int() {_exposeToLua}
		Return stationType = TVTStationType.SATELLITE_UPLINK
	End Method


	Method IsAntenna:Int() {_exposeToLua}
		Return stationType = TVTStationType.ANTENNA
	End Method


	'set time a station begins to work (broadcast)
	Method SetActivationTime(activationTime:Long = -1)
		If activationTime < 0 Then activationTime = GetWorldTime().GetTimeGone()
		Self.activationTime = activationTime

		If activationTime < GetWorldTime().GetTimeGone() Then SetActive()
	End Method


	Method CanActivate:Int()
		Return True
	End Method


	'set time a station begins to work (broadcast)
	Method SetActive:Int(force:Int = False)
		If IsActive() Then Return False
		If Not force And Not CanActivate() Then Return False

		Self.activationTime = GetWorldTime().GetTimeGone()
		SetFlag(TVTStationFlag.ACTIVE, True)

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.Station_OnSetActive, Null, Self)

		Return True
	End Method


	Method SetInactive:Int()
		If Not IsActive() Then Return False

		SetFlag(TVTStationFlag.ACTIVE, False)

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.Station_OnSetInactive, Null, Self)
	End Method


	Method ShutDown:Int()
		If HasFlag(TVTStationFlag.SHUTDOWN) Then Return False

		SetFlag(TVTStationFlag.SHUTDOWN, True)

		'inform others (eg. to refresh list content)
		TriggerBaseEvent(GameEventKeys.Station_OnShutdown, Null, Self)

		Return True
	End Method


	Method Resume:Int()
		If Not HasFlag(TVTStationFlag.SHUTDOWN) Then Return False

		SetFlag(TVTStationFlag.SHUTDOWN, False)

		'inform others (eg. to refresh list content)
		TriggerBaseEvent(GameEventKeys.Station_OnResume, Null, Self)

		Return True
	End Method


	Method RenewContract:Int()
		Return RenewContractOverDuration(-1)
	End Method


	Method RenewContractOverDuration:Int(duration:Long)
		'reset warning state
		SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, False)

		Return True
	End Method

	
	Method CanSignContract:Int() {_exposeToLua}
		Return CanSignContractOverDuration(-1)
	End Method


	Method CanSignContractOverDuration:Int(duration:Long)
		Return True
	End Method


	Method SignContract:Int()
		Return SignContractOverDuration(-1)
	End Method


	Method SignContractOverDuration:Int(duration:Long)
		'reset warning state
		SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, False)

		runningCosts = -1

		Return True
	End Method


	Method CancelContracts:Int()
		Return True
	End Method


	'override to add satellite connection
	Method OnAddToMap:Int()
		Return True
	End Method


	'override to remove satellite connection
	Method OnRemoveFromMap:Int()
		Return True
	End Method


	Method GetSubscriptionTimeLeft:Long()
		Return 0
	End Method


	Method GetSubscriptionProgress:Float()
		Return 0
	End Method


	Method GetConstructionTime:Int()
		Local difficulty:TPlayerDifficulty = GetPlayerDifficulty(owner)
		Local constructionTime:int
		If isAntenna()
			constructionTime = difficulty.antennaConstructionTime
		ElseIf IsCableNetworkUplink()
			constructionTime = difficulty.cableNetworkConstructionTime
		Else
			constructionTime = difficulty.satelliteConstructionTime
		EndIf

		If constructionTime = 0 Then Return 0

		if IsShutDown()
			Return 1 * constructionTime
		endif

		Local r:Int = GetPopulation()
		If r < 500000
			Return 1 * constructionTime
		ElseIf r < 1000000
			Return 2 * constructionTime
		ElseIf r < 2500000
			Return 3 * constructionTime
		ElseIf r < 5000000
			Return 4 * constructionTime
		Else
			Return 5 * constructionTime
		EndIf
	End Method


	Method GetCurrentRunningCosts:Int() {_exposeToLua}
		Return 0
	End Method


	Method GetRunningCosts:Int() {_exposeToLua}
		If runningCosts = -1
			runningCosts = GetCurrentRunningCosts()
		EndIf

		Return runningCosts
	End Method


	Method Sell:Int()
		If Not GetPlayerFinance(owner) Then Return False

		If GetPlayerFinance(owner).SellStation( getSellPrice() )
'after selling
'			owner = 0
			Return True
		EndIf
		Return False
	End Method


	Method Buy:Int(playerID:Int)
		'fixate running costs
		runningCosts = -1
		GetRunningCosts()
	
		'set activation time (and refresh built time)
		built = GetWorldTime().GetTimeGone()

		Local constructionTime:Int = GetConstructionTime()
		'do not allow negative values as a "ready now" is not possible
		'because it affects broadcasted audience then.
		'if constructionTime <  0
		'	SetActivationTime( GetWorldTime().GetTimeGone()-1)
		'else
			If constructionTime <  0 Then constructionTime = 0

			'next hour (+construction hours) at xx:00
			If GetWorldTime().GetDayMinute(built + constructionTime * TWorldTime.HOURLENGTH) >= 5
				SetActivationTime( GetWorldTime().GetTimeGoneForGameTime(0, 0, GetWorldTime().GetHour(built) + constructionTime + 1, 0))
			'this hour (+construction hours) at xx:05
			Else
				SetActivationTime( GetWorldTime().GetTimeGoneForGameTime(0, 0, GetWorldTime().GetHour(built) + constructionTime, 5, 0))
			EndIf
		'endif

		If HasFlag(TVTStationFlag.PAID) Then Return True
		If Not GetPlayerFinance(playerID) Then Return False
		Local price:Int = GetBuyPrice()
		If price < 0 Then Return False

		If GetPlayerFinance(playerID).PayStation( price )
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
			If CanActivate() And GetActivationTime() <= GetWorldTime().GetTimeGone()
				If Not SetActive()
					TLogger.Log("TStationBase.Update()", "Failed to activate " + GetGUID(), LOG_ERROR)
				EndIf
			EndIf
		EndIf

		'antennas do not have a subscriptionprogress - ignore them
		If GetSubscriptionProgress() > 0
			'automatically refresh subscriptions?
			If HasFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT)
				If GetSubscriptionTimeLeft() <= 0 And GetProvider()
					RenewContractOverDuration( GetProvider().GetDefaultSubscribedChannelDuration() )
				EndIf
			'inform others that contract ends soon ?
			ElseIf Not HasFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT)
				If GetSubscriptionTimeLeft() <= TWorldTime.DAYLENGTH
					SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, True)
					'inform others
					TriggerBaseEvent(GameEventKeys.Station_OnContractEndsSoon, Null, Self )
				EndIf
			EndIf
		EndIf
	End Method


	'how much a potentially drawn sprite is offset (eg. for a boundary
	'circle like for antennas)
	Method GetOverlayOffsetY:Int()
		Return 0
	End Method


	Method CanSubscribeToProvider:Int() {_exposeToLua}
		Return CanSubscribeToProviderOverDuration(-1)
	End Method


	Method CanSubscribeToProviderOverDuration:Int(duration:Long)
		Return True
	End Method


	Function NextReachLevelProbable:Int(owner:Int, newStationReceivers:Int)
		Local stationMap:TStationMap = GetStationMap(owner)
		Local currentReceivers:Int = stationMap.GetReceivers()
		Local currTime:Long = GetWorldTime().GetTimeGone()
		'add up reach of all stations about to be built
		Local estimatedReceiverIncrease:Int = newStationReceivers
		For Local station:TStationBase = EachIn stationMap.stations
			If Not station.isActive() And station.GetActivationTime() > currTime
				estimatedReceiverIncrease :+ station.GetStationExclusiveReceivers()
			EndIf
		Next
		Return TStationMap.GetReceiverLevel(currentReceivers) < TStationMap.GetReceiverLevel(currentReceivers + estimatedReceiverIncrease)
	End Function


	Method DrawInfoTooltip()
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
		Local showPermissionPriceText:Int
		Local cantGetSectionPermissionReason:Int = 1
		Local cantGetProviderPermissionReason:Int = 1
		Local isNextReachLevelProbable:Int = False
		Local showPriceInformation:Int = False

		If Not HasFlag(TVTStationFlag.PAID)
			cantGetProviderPermissionReason = CanSubscribeToProvider()
			isNextReachLevelProbable = NextReachLevelProbable(owner, GetStationExclusiveReceivers())
			showPriceInformation = True

			If section And section.NeedsBroadcastPermission(owner, stationType)
				showPermissionPriceText = Not section.HasBroadcastPermission(owner, stationType)
				cantGetSectionPermissionReason = section.CanGetBroadcastPermission(owner)
			EndIf
		EndIf

		Local priceSplitH:Int = 8
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" ) - 2
		Local tooltipW:Int = 225
		Local tooltipH:Int = textH * 5 + 10 + 2

		If showPriceInformation Then tooltipH :+ priceSplitH

		'show build time?
		If GetConstructionTime() > 0 Then tooltipH :+ textH
		'display increase?
		If stationType = TVTStationType.ANTENNA Then tooltipH :+ textH
		'display required channel image for permission?
		If cantGetSectionPermissionReason <= 0 Then tooltipH :+ textH
		'display required channel image for provider?
		If cantGetProviderPermissionReason <= 0 Then tooltipH :+ textH
		'display broadcast permission price?
		If showPermissionPriceText > 0
			tooltipH :+ 2*textH
		EndIf
		'warn about potential reach level increase?
		If isNextReachLevelProbable Then tooltipH :+ textH

		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Local screenX:Int = mapInfo.DataXToScreenX(self.x)
		Local screenY:Int = mapInfo.DataYToScreenY(self.y)
		Local tooltipX:Int = screenX - tooltipW/2
		Local tooltipY:Int = screenY - GetOverlayOffsetY() - tooltipH - 10

		'move below station if at screen top
		If tooltipY < 10 Then tooltipY = screenY + GetOverlayOffsetY() + 10
		tooltipX = MathHelper.Clamp(tooltipX, 20, GetGraphicsManager().GetWidth() - tooltipW)

		Local oldAlpha:Float = GetAlpha()

		SetColor 0,0,0
		SetAlpha oldAlpha * 0.5
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0
		GetSpriteFromRegistry("gfx_datasheet_border").DrawArea(tooltipX-8, tooltipY-8, tooltipW+20, tooltipH+20)		

		SetColor 255,255,255
		SetAlpha oldAlpha

		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local font:TBitmapFont = GetBitmapFontManager().baseFont

		Local textY:Int = tooltipY+2
		Local textX:Int = tooltipX+3
		Local textW:Int = tooltipW-8
		Local iso:String = GetSectionISO3166Code()
		fontBold.DrawSimple( GetLocale("MAP_COUNTRY_"+iso+"_LONG") + " (" + GetLocale("MAP_COUNTRY_"+iso+"_SHORT")+")", textX, textY, New SColor8(250,200,100), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH

		font.Draw(GetLocale("POPULATION")+": ", textX, textY, New SColor8(255,255,255, 180))
		fontBold.DrawBox(TFunctions.convertValue(GetPopulation(), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,255,255, 180))
		textY:+ textH + 5

		font.Draw(GetLocale("REACH")+":", textX, textY)
		Select stationType
			case TVTStationType.ANTENNA
				font.DrawBox(TFunctions.LocalizedNumberToString(section.GetPopulationAntennaShareRatio()*100, 1)+"%", textX, textY-1, 0.65 * textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,255,255,200))
			case TVTStationType.CABLE_NETWORK_UPLINK
				font.DrawBox(TFunctions.LocalizedNumberToString(section.GetPopulationCableShareRatio()*100, 1)+"%", textX, textY-1, 0.65 * textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,255,255,200))
			case TVTStationType.SATELLITE_UPLINK
				font.DrawBox(TFunctions.LocalizedNumberToString(section.GetPopulationSatelliteShareRatio()*100, 1)+"%", textX, textY-1, 0.65 * textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,255,255,200))
		End Select
		fontBold.DrawBox(TFunctions.convertValue(GetReceivers(), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		textY:+ textH

		If stationType = TVTStationType.ANTENNA
			Local exclusiveReceivers:Int = GetStationExclusiveReceivers()
			Local increasePercentage:Float = exclusiveReceivers / Float(GetStationMap(owner).GetReceivers())
			font.Draw(GetLocale("INCREASE")+":", textX, textY)
			font.DrawBox("+"+TFunctions.LocalizedNumberToString(increasePercentage*100, 1)+"%", textX, textY-1, 0.65 * textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,255,255,200))
			fontBold.DrawBox(TFunctions.convertValue(exclusiveReceivers, 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			textY:+ textH
		EndIf

		If GetConstructionTime() > 0
			font.Draw(GetLocale("CONSTRUCTION_TIME")+": ", textX, textY)
			fontBold.DrawBox(GetConstructionTime()+"h", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			textY:+ textH
		EndIf


		If cantGetSectionPermissionReason = -1
			font.Draw(GetLocale("CHANNEL_IMAGE")+" ("+GetLocale("STATIONMAP_SECTION_NAME")+"): ", textX, textY)
			fontBold.DrawBox(TFunctions.LocalizedNumberToString(section.broadcastPermissionMinimumChannelImage,2)+" %", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,150,150))
			textY:+ textH
		EndIf
		If cantGetProviderPermissionReason = -1
			Local minImage:Float
			Local provider:TStationMap_BroadcastProvider = GetProvider()
			If provider Then minImage = provider.minimumChannelImage

			font.Draw(GetLocale("CHANNEL_IMAGE")+" ("+GetLocale("PROVIDER")+"): ", textX, textY)
			fontBold.DrawBox(TFunctions.LocalizedNumberToString(minImage,2)+" %", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,150,150))
			textY:+ textH
		EndIf

		If showPriceInformation
			textY:+ priceSplitH

			Local totalPrice:Int
			If Not showPermissionPriceText
				'always request the _current_ (refreshed) price
				totalPrice = GetBuyPrice()
			Else
				font.Draw(GetTypeName()+": ", textX, textY)
				fontBold.DrawBox(GetFormattedCurrency(GetBuyPrice()) , textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
				textY:+ textH

				font.Draw(GetLocale("BROADCAST_PERMISSION")+": ", textX, textY)
				fontBold.DrawBox(GetFormattedCurrency(section.GetBroadcastPermissionPrice(owner, stationType)), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
				textY:+ textH

				'always request the _current_ (refreshed) price
				totalPrice = GetStationMap(owner).GetTotalStationBuyPrice(Self)
			EndIf

			font.Draw(GetLocale("PRICE")+": ", textX, textY)
			If Not GetPlayerFinance(owner).CanAfford(totalPrice)
				fontBold.DrawBox(GetFormattedCurrency(totalPrice), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,150,150))
			Else
				fontBold.DrawBox(GetFormattedCurrency(totalPrice), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			EndIf
			textY:+ textH
			font.Draw(GetLocale("RUNNING_COSTS")+": ", textX, textY)
			fontBold.DrawBox(GetFormattedCurrency(GetCurrentRunningCosts()), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf

		If isNextReachLevelProbable
			textY:+ textH
			SetColor 255,150,150
			font.Draw(GetLocale("AUDIENCE_REACH_LEVEL_WILL_INCREASE"), textX, textY)
			SetColor 255,255,255
		EndIf

	End Method


	Method DrawActivationTooltip()
		Local textCaption:String = GetLocale("X_UNDER_CONSTRUCTION").Replace("%X%", GetTypeName())
		Local textContent:String = GetLocale("READY_AT_TIME_X")
		Local readyTime:String = GetWorldTime().GetFormattedTime(GetActivationTime())
		'prepend day if it does not finish today
		If GetWorldTime().GetDay() < GetWorldTime().GetDay(GetActivationTime())
			readyTime = GetWorldTime().GetFormattedDay(GetWorldTime().GetDaysRun(GetActivationTime()) +1) + " " + readyTime
			textContent = GetLocale("READY_AT_DAY_X")
		EndIf
		textContent = textContent.Replace("%TIME%", readyTime)


		Local textH:Int = GetBitmapFontManager().baseFontBold.GetMaxCharHeight(True)
		Local textW:Int = GetBitmapFontManager().baseFontBold.GetWidth(textCaption)
		textW = Max(textW, GetBitmapFontManager().baseFont.GetWidth(textContent))
		Local tooltipW:Int = textW + 8
		Local tooltipH:Int = textH * 2

		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Local screenX:Int = mapInfo.DataXToScreenX(self.x)
		Local screenY:Int = mapInfo.DataYToScreenY(self.y)
		Local tooltipX:Int = screenX - tooltipW/2
		Local tooltipY:Int = screenY - GetOverlayOffsetY() - tooltipH

		'move below station if at screen top
		If tooltipY < 20 Then tooltipY = Y + GetOverlayOffsetY() + 10 +10
		tooltipX = Max(20, tooltipX)
		tooltipX = Min(585 - tooltipW, tooltipX)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX, tooltipY, tooltipW, tooltipH)
		SetAlpha 1.0
		SetColor 200,200,200
		DrawLine(tooltipX, tooltipY, tooltipX + tooltipW, tooltipY)
		DrawLine(tooltipX, tooltipY + tooltipH, tooltipX + tooltipW, tooltipY + tooltipH)
		DrawLine(tooltipX, tooltipY + 1, tooltipX, tooltipY + tooltipH - 1)
		DrawLine(tooltipX + tooltipW, tooltipY + 1, tooltipX + tooltipW, tooltipY + tooltipH - 1)
		SetColor 255,255,255
		SetAlpha 1.0

		Local textY:Int = tooltipY + 2
		Local textX:Int = tooltipX + 3
		GetBitmapFontManager().baseFontBold.DrawSimple(textCaption, textX, textY, New SColor8(255,190,80), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH

		GetBitmapFontManager().baseFont.Draw(textContent, textX, textY)
		textY:+ textH
	End Method


	Method DrawBackground(selected:Int=False, hovered:Int=False)
		'
	End Method


	Method Draw(selected:Int=False)
		'
	End Method
End Type




Type TStationAntenna Extends TStationBase {_exposeToLua="selected"}
	Field radius:Int = 0 {_exposeToLua="readonly"}
	'ids of antennas (of all players) overlapping with this one
	Field _overlappedAntennaIDs:Int[]
	Global highlightColor:TColor = New TColor

	Method New()
		radius = GetStationMapCollection().antennaStationRadius

		stationType = TVTStationType.ANTENNA

		listSpriteNameOn = "gfx_datasheet_icon_antenna.on"
		listSpriteNameOff = "gfx_datasheet_icon_antenna.off"
	End Method


	Method Init:TStationAntenna(dataPos:SVec2I, owner:Int) Override
		Super.Init(dataPos, owner)
		Return Self
	End Method


	Method GenerateGUID:String() override
		Return "station-antenna-"+id
	End Method


	Method GetTypeName:String() override
		Return GetLocale("STATION")
	End Method


	Method GetLongName:String() override {_exposeToLua}
		Local n:String = GetName()
		If n 
			'n = n.replace("#", "")
			'n = "#" + RSet(n, 4).Replace(" ", "0")
			'Return n + " " + GetLocale("MAP_COUNTRY_" + GetSectionISO3166Code() + "_SHORT")
			'Return LSet(n,6) + GetLocale("MAP_COUNTRY_" + GetSectionISO3166Code() + "_SHORT")
			Return GetTypeName() + " " + n + " ("+GetLocale("MAP_COUNTRY_" + GetSectionISO3166Code() + "_SHORT")+")"
		EndIf
		Return GetTypeName()
	End Method


	Method GetMapRect:SRectI()
		Return New SRectI(X - radius, Y - radius, 2*radius, 2*radius)
	End Method


	Method _GetOverlappedAntennaIndex:Int(antennaID:Int)
		If not _overlappedAntennaIDs Then Return -1
		
		For Local i:Int = 0 until _overlappedAntennaIDs.length
			if _overlappedAntennaIDs[i] = antennaID Then Return i
		Next
		Return -1
	End Method


	Method _RemoveOverlappedAntenna:Int(antennaID:Int)
		local removeIndex:int = _GetOverlappedAntennaIndex(antennaID)
		If removeIndex < 0 Then Return False
		
		_overlappedAntennaIDs = _overlappedAntennaIDs[.. removeIndex] + _overlappedAntennaIDs[removeIndex + 1 ..]
		
		'exclusive-cache is invalid now
		_InvalidatePopulationShareCache()
	End Method
	
	
	Method _AddOverlappedAntenna:Int(antennaID:Int)
		If _GetOverlappedAntennaIndex(antennaID) >= 0 then Return False

		If not _overlappedAntennaIDs 
			_overlappedAntennaIDs = [antennaID]
		Else
			_overlappedAntennaIDs :+ [antennaID]
		EndIf

		'exclusive-cache is invalid now
		_InvalidatePopulationShareCache()
	End Method


	Method _SetOverlappedAntennas:Int(antennas:TStationAntenna[])
		If not antennas
			_overlappedAntennaIDs = Null
		Else
			_overlappedAntennaIDs = New Int[antennas.length]
			For Local i:Int = 0 until _overlappedAntennaIDs.length
				_overlappedAntennaIDs[i] = antennas[i].GetID()
			Next
		EndIf
	End Method


	'returns percentage of receivers amongst the population
	Method GetPopulationReceiverShare:Float() override {_exposeToLua}
		'Normally the share could be different for the parts of the
		'antenna being outside of the section. So this
		'approach here is a simplification to avoid overly complex
		'calculations. 
	
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
		If Not section Or section.populationAntennaShare < 0
			Return GetStationMapCollection().GetCurrentPopulationAntennaShare()
		Else
			Return section.populationAntennaShare
		EndIf
	End Method

	
	'(set flags to True to pay attention to certain exclusiveness)
	'this is a station type specific implementation
	Method GetPopulationShare:Float(exclusiveToOwnChannel:Int = False, exclusiveToOtherChannels:Int = False) override {_exposeToLua}
		Local share:Float
		share = GetStationMapCollection().GetAntennaPopulation(self.x, self.y, self.radius, self.owner, self.IsActive(), exclusiveToOwnChannel, exclusiveToOtherChannels)
		share :/ GetStationMapCollection().GetPopulation()
		Return share
	End Method


	Method SetRadius(r:Int)
		'nothing to do?
		if self.radius = r Then Return
		
		self.radius = r

		_InvalidatePopulationShareCache()
	End Method


	'base price for buy price and maintenance costs
	'extracted in order to apply separate modifiers
	Method _BasePrice:Int(forBuying:Int)
		'If HasFlag(TVTStationFlag.FIXED_PRICE) and price >= 0 Then Return price

		'price corresponds to "possibly reachable" not actually reached
		'persons...
		'so during changes between antenna-satellite-cable the price
		'"effectivity" changes.

		'when refreshing also check for a new section name (might be a
		'to-place-station)
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
		'return an odd price (if someone sees it...)
		If Not section Then Return -1337

		Local basePrice:Int = 0

		'construction costs
		If Not IsShutdown()
			Local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)
			'government-dependent costs
			'section specific costs for bought land + bureaucracy costs
			basePrice :+ section.GetPropertyAquisitionCosts(TVTStationType.ANTENNA)
			'section government costs, changes over time (dynamic reach)
			basePrice :+ 0.35 * GetReceivers()
			'government sympathy adjustments (-10% to +10%)
			'price :+ 0.1 * (-1 + 2*channelSympathy) * price
			basePrice :* 1.0 + (0.1 * (1 - 2*channelSympathy))

			'fixed construction costs
			'building costs for "hardware" (more expensive than sat/cable)
			'TODO find concept for a price calculation that works well for buy price an running costs for
			' * many small antennas with high population share in early start years
			' * few large antennas with small population share in later sart years
			' this proposal uses a much smaller "fix" portion for the running costs
			' otherwise running costs for later start years would be much too high for antennas to be profitable
			If forBuying
				basePrice :+ 75000*1.02^radius
			Else
				basePrice :+ 25000*1.02^radius
			EndIf
		EndIf
		Return basePrice
	End Method


	Method GetBuyPrice:Int() override {_exposeToLua}
		Local buyPrice:Int = _BasePrice(True)
		If buyPrice < 0 return buyPrice

		buyPrice :* GetPlayerDifficulty(owner).antennaBuyPriceMod
		'no further costs

		'round it to 25000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 25000)) * 25000 )

		Return buyPrice
	End Method


	Method GetCurrentRunningCosts:Int() override {_exposeToLua}
		If HasFlag(TVTStationFlag.NO_RUNNING_COSTS) Then Return 0

		Local result:Int = 0
		Local difficulty:TPlayerDifficulty=GetPlayerDifficulty(owner)

		'== ADD STATIC RUNNING COSTS ==
		result :+ Ceil(_BasePrice(False) / 5.0)
		result :* difficulty.antennaDailyCostsMod
		'== ADD RELATIVE MAINTENANCE COSTS ==
		Local maintenanceCostPercentage:Float=difficulty.antennaDailyCostsIncrease
		if maintenanceCostPercentage > 0
			'the older a station gets, the more the running costs will be
			'(more little repairs and so on)
			maintenanceCostPercentage = Min(difficulty.antennaDailyCostsIncreaseMax, maintenanceCostPercentage * GetAgeInDays())
			result :* (1.0 + maintenanceCostPercentage)
		endif

		result = 1000 * int (result / 1000)
		Return result
	End Method


	Method GetOverlayOffsetY:Int() override
		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Return mapInfo.DataToScreen(self.radius, True)
	End Method


	Method Draw(selected:Int=False)
		Local sprite:TSprite = Null
		Local oldAlpha:Float = GetAlpha()
		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		'ensure 25,1 becomes 26 -> always round up to eas showing "overlaps"
		Local screenRadius:Int = mapInfo.DataToScreen(self.radius, True)
		Local screenX:Int = mapInfo.DataXToScreenX(self.x)
		Local screenY:Int = mapInfo.DataYToScreenY(self.y)
		If selected
			'white border around the colorized circle
			SetAlpha 0.25 * oldAlpha
			DrawOval(screenX - screenRadius - 2, screenY - screenRadius -2, 2 * (screenRadius + 2), 2 * (screenRadius + 2))

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
		DrawOval(screenX - screenRadius, screenY - screenRadius, 2 * screenRadius, 2 * screenRadius)
		highlightColor.CopyFrom(color).Mix(TColor.clWhite, 0.75).SetRGB()
		DrawOval(screenX - screenRadius + 2, screenY - screenRadius + 2, 2 * (screenRadius - 2), 2 * (screenRadius - 2))


		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(screenX, screenY + 1, -1, ALIGN_CENTER_CENTER)
	End Method
End Type




Type TStationCableNetworkUplink Extends TStationBase {_exposeToLua="selected"}
	Field hardwareCosts:Int = 65000
	Field maintenanceCosts:Int = 15000


	Method New()
		listSpriteNameOn = "gfx_datasheet_icon_cable_network_uplink.on"
		listSpriteNameOff = "gfx_datasheet_icon_cable_network_uplink.off"

		stationType = TVTStationType.CABLE_NETWORK_UPLINK
	End Method


	'override but return different station type
	Method Init:TStationCableNetworkUplink(dataPos:SVec2I, owner:Int) Override
		Super.Init(dataPos, owner)

		Return Self
	End Method


	'init cable network uplink with given cableNetwork
	Method Init:TStationCableNetworkUplink(cableNetwork:TStationMap_CableNetwork, owner:Int, autoUpdateContract:Int) 
		If not cableNetwork then Throw "TStationCableNetworkUplink.Init() failed. No valid cable network given."
		If not cableNetwork.launched then Throw "TStationCableNetworkUplink.Init() failed. Cable network not launched."

		Local mapSection:TStationMapSection = GetStationMapCollection().GetSectionByName(cableNetwork.sectionName)
		If not mapSection then Throw "TStationCableNetworkUplink.Init() failed. no valid section assigned to cable network."

		'uplinkPos is "screen based", init() wants "data based"
		Local uplinkPos:TVec2I = mapSection.GetUplinkPos()
		Local dataX:Int = GetStationMapCollection().mapInfo.ScreenXToDataX( Int(mapSection.rect.x) + uplinkPos.x )
		Local dataY:Int = GetStationMapCollection().mapInfo.ScreenYToDataY( Int(mapSection.rect.y) + uplinkPos.y )

		Super.Init(new SVec2I(dataX, dataY), owner)
	
		SetProvider(cableNetwork.getID())
		SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT, autoUpdateContract)

		Return self
	End Method


	'init cable network uplink with given cableNetwork defined by id
	Method Init:TStationCableNetworkUplink(cableNetworkID:Int, owner:Int, autoUpdateContract:Int) 
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(cableNetworkID)

		Return Init(cableNetwork, owner, autoUpdateContract)
	End Method

	'init cable network uplink with the first cable network found in the in the section
	Method Init:TStationCableNetworkUplink(section:TStationMapSection, owner:Int, autoUpdateContract:Int = True)
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetFirstCableNetworkBySection(section)

		Return Init(cableNetwork, owner, autoUpdateContract)
	End Method

	'init cable network uplink with the first cable network found in the in the section defined by section name
	Method Init:TStationCableNetworkUplink(sectionName:String, owner:Int, autoUpdateContract:Int = True)
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetFirstCableNetworkBySectionName(sectionName)

		Return Init(cableNetwork, owner, autoUpdateContract)
	End Method


	'override
	Method GenerateGUID:String()
		Return "station-cable_network-uplink-"+id
	End Method


	'override
	Method GetTypeName:String() {_exposeToLua}
		Return GetLocale("CABLE_NETWORK_UPLINK")
	End Method


	Method GetLongName:String() {_exposeToLua}
		Return GetLocale("MAP_COUNTRY_"+GetSectionISO3166Code()+"_LONG")
	End Method


	Method GetProvider:TStationMap_BroadcastProvider() override
		If Not providerID Then Return Null
		Return GetStationMapCollection().GetCableNetwork(providerID)
	End Method


	'override
	Method CanActivate:Int()
		Local provider:TStationMap_BroadcastProvider = GetProvider()
		If Not provider Then Return False

		If Not provider.IsLaunched() Then Return False
		If Not provider.IsSubscribedChannel(Self.owner) Then Return False

		Return True
	End Method


	Method RenewContractOverDuration:Int(duration:Long) override
		If Not providerID Then Return False 'Throw "Renew CableNetworkUplink without valid cable network guid."

		'inform cable network
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If cableNetwork
			Rem
			'subtract time left from planned duration
			local extendAmount:Long = duration - GetSubscriptionTimeLeft()
			if extendAmount > 0
				if not cableNetwork.ExtendSubscribedChannelDuration(self.owner, extendAmount )
					return False
				endif
				print "renewed cable network contract"
			endif
			endrem

			'subscribe or resubscribe if needed
			'-> contrary to "ExtendSubscribedChannelDuration" this resets
			'   SubscriptionProgress (and contract start time)
			If Not cableNetwork.SubscribeChannel(Self.owner, duration )
				Return False
			EndIf

			'fetch new running costs (no setup fees)
			runningCosts = - 1
		EndIf

		Return Super.RenewContractOverDuration(duration)
	End Method


	Method CanSubscribeToProviderOverDuration:Int(duration:Long) override
		If Not providerID Then Return False

		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If cableNetwork Then Return cableNetwork.CanSubscribeChannelOverDuration(Self.owner, duration)

		Return True
	End Method


	'override to check if already subscribed
	Method CanSignContractOverDuration:Int(duration:Long) override
		If Not Super.CanSignContractOverDuration(duration) Then Return False

		If CanSubscribeToProviderOverDuration(duration) <= 0 Then Return False

		Return True
	End Method


	'override to add satellite connection
	Method SignContractOverDuration:Int(duration:Long) override
		If Not providerID Then Throw "Sign to CableNetworkLink without valid cable network id."
		If Not CanSignContractOverDuration(duration) Then Return False

		'inform cable network
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If cableNetwork
			If duration < 0 Then duration = cableNetwork.GetDefaultSubscribedChannelDuration()
			If Not cableNetwork.SubscribeChannel(Self.owner, duration )
				Return False
			EndIf
		EndIf

		Return Super.SignContractOverDuration(duration)
	End Method


	'override to remove satellite connection
	Method CancelContracts:Int()
		'inform cableNetwork
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If cableNetwork
			If Not cableNetwork.UnsubscribeChannel(owner)
				Return False
			EndIf
		EndIf

		Return Super.CancelContracts()
	End Method


	Method GetSubscriptionTimeLeft:Long()
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If Not cableNetwork Then Return 0

		Local endTime:Long = cableNetwork.GetSubscribedChannelEndTime(owner)
		If endTime < 0 Then Return 0

		Return endTime - GetWorldTime().GetTimeGone()
	End Method


	Method GetSubscriptionProgress:Float()
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If Not cableNetwork Then Return 0

		Local startTime:Long = cableNetwork.GetSubscribedChannelStartTime(owner)
		Local duration:Long = cableNetwork.GetSubscribedChannelDuration(owner)
		If duration < 0 Then Return 0

		Return MathHelper.Clamp(Float((GetworldTime().GetTimeGone() - startTime) / Double(duration)), 0.0, 1.0)
	End Method


	'override
	Method GetBuyPrice:Int() {_exposeToLua}
'		If price >= 0 And Not refresh Then Return price

		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If Not cableNetwork Then Return 0

		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
		If Not section
			TLogger.Log("TStationCableNetworkUplink.GetBuyPrice()", "Cablenetwork without section.", LOG_ERROR)
			Return -1337
		EndIf

		Local buyPrice:Int = 0

		'construction costs
		If Not IsShutdown()
			Local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)

			'government-dependent costs
			'section specific costs for bought land + bureaucracy costs
			buyPrice :+ section.GetPropertyAquisitionCosts(TVTStationType.CABLE_NETWORK_UPLINK)
			'section government costs, changes over time (dynamic reach)
			buyPrice :+ 0.10 * GetReceivers()
			'government sympathy adjustments (-10% to +10%)
			'price :+ 0.1 * (-1 + 2*channelSympathy) * price
			buyPrice :* 1.0 + (0.1 * (1 - 2*channelSympathy))

			'fixed building costs
			'building costs for "hardware"
			buyPrice :+ hardwareCosts
		EndIf


		'cable network provider costs
		buyPrice :+ cableNetwork.GetSetupFee(owner)

		buyPrice :* GetPlayerDifficulty(owner).cableNetworkBuyPriceMod
		'round it to 5000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 5000)) * 5000 )

		Return buyPrice
	End Method


	'override
	Method GetSellPrice:Int() {_exposeToLua}
		'sell price = cancel costs
		'cancel costs depend on the days a contract has left

		Local expense:Int
		'pay the provider for canceling earlier
		expense = (1.0 - GetSubscriptionProgress())^2 * 3 * GetRunningCosts()
		
		Return -expense
	End Method


	'override
	Method GetCurrentRunningCosts:Int() {_exposeToLua}
		If HasFlag(TVTStationFlag.NO_RUNNING_COSTS) Then Return 0

		Local result:Int

		'add specific costs
		If providerID
			Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
			If cableNetwork
				result :+ cableNetwork.GetDailyFee(owner)
			EndIf
		EndIf

		'maintenance costs for the uplink to the cable network
		result :+ maintenanceCosts

		Result:* GetPlayerDifficulty(owner).cableNetworkDailyCostsMod
		return result
	End Method


	'returns percentage of receivers amongst the population
	Method GetPopulationReceiverShare:Float() override {_exposeToLua}
		'Normally the share could be different for the parts of the
		'antenna being outside of the section. So this
		'approach here is a simplification to avoid overly complex
		'calculations. 
	
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
		If Not section Or section.populationCableShare < 0
			Return GetStationMapCollection().GetCurrentPopulationCableShare()
		Else
			Return section.populationCableShare
		EndIf
	End Method

	
	'(set flags to True to pay attention to certain exclusiveness)
	'this is a station type specific implementation
	Method GetPopulationShare:Float(exclusiveToOwnChannel:Int = False, exclusiveToOtherChannels:Int = False) override {_exposeToLua}
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
		If Not section Then Return 0.0

		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(providerID)
		If Not cableNetwork Then Return 0.0


		'require to be the only uplink of the channel in the section?
		If exclusiveToOwnChannel
			'for now we also count "currently build" ones but ignore shut 
			'down elements
			Local ourCableNetworks:Int = GetStationMap(owner).GetStationsToProviderCount(providerID, False, False)
			If ourCableNetworks > 1
				Return 0.0
			'this is the only one - or a new one
			'-> it is exclusive to the channel
			'Elseif GetStationMap(owner).HasStation(Self) 
			'Else
				'nothing to do
			EndIf
		EndIf
		'non-exclusive if at least one is subscribed
		If exclusiveToOtherChannels
			For local i:int = 1 to 4
				if i = owner Then continue

				If cableNetwork.IsSubscribedChannel(i)
					Return 0.0
				EndIf
			Next
		EndIf

		Return Float(section.GetPopulation()) / GetStationMapCollection().GetPopulation()
	End Method


	Method GetOverlayOffsetY:Int() override
		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Return mapInfo.DataToScreen(15, True)
	End Method


	Method DrawBackground(selected:Int=False, hovered:Int=False)
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
		If Not section Then Return

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		Local color:TColor
		Select owner
			Case 1,2,3,4	color = TPlayerColor.GetByOwner(owner)
			Default			color = TColor.clWhite
		End Select


		If selected Or hovered
			If selected
				SetColor 255,255,255
				SetAlpha 0.3
				DrawImage(section.GetSelectedImage(), section.rect.x, section.rect.y)

				SetAlpha Float(0.2 * Sin(Time.GetAppTimeGone()/4) * oldA) + 0.3
				SetBlend LightBlend
				section.GetHighlightBorderSprite().Draw(section.rect.x, section.rect.y)
				SetColor(oldCol)
				SetAlpha(oldA)
				SetBlend AlphaBlend
			EndIf

			If hovered
				'SetAlpha Float(0.3 * Sin(Time.GetAppTimeGone()/4) * oldColor.a) + 0.15
				SetColor 255,255,255
				SetAlpha 0.15
				SetBlend LightBlend
				DrawImage(section.GetHoveredImage(), section.rect.x, section.rect.y)

				SetAlpha 0.4
				SetBlend LightBlend
				section.GetHighlightBorderSprite().Draw(section.rect.x, section.rect.y)
				SetColor(oldCol)
				SetAlpha(oldA)
				SetBlend AlphaBlend
			EndIf
		Else
			SetAlpha oldA * 0.3
			color.SetRGB()
			'color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
			section.GetShapeSprite().Draw(section.rect.x, section.rect.y)
			SetColor(oldCol)
			SetAlpha(oldA)
		EndIf

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
		'TODO: section hervorheben
		'SetColor(Int(0.25 * color.r + 0.75 * 255), Int(0.25 * color.g + 0.75 * 255), Int(0.25 * color.b + 0.75 * 255))
		'TODO: section hervorheben


		SetColor 255,255,255
		SetAlpha OldAlpha

		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Local screenX:Int = mapInfo.DataXToScreenX(self.x)
		Local screenY:Int = mapInfo.DataYToScreenY(self.y)
		sprite.Draw(screenX, screenY + 1, -1, ALIGN_CENTER_CENTER)
	End Method
End Type




Type TStationSatelliteUplink Extends TStationBase {_exposeToLua="selected"}
	Field hardwareCosts:Int = 95000
	Field maintenanceCosts:Int = 25000


	Method New()
		listSpriteNameOn = "gfx_datasheet_icon_satellite_uplink.on"
		listSpriteNameOff = "gfx_datasheet_icon_satellite_uplink.off"

		stationType = TVTStationType.SATELLITE_UPLINK
	End Method

	'override but return different station type
	Method Init:TStationSatelliteUplink(dataPos:SVec2I, owner:Int) Override
		Super.Init(dataPos, owner)

		Return Self
	End Method

		
	Method Init:TStationSatelliteUplink(satellite:TStationMap_Satellite, owner:Int, autoUpdateContract:Int) 
		If not satellite then Throw "TStationSatelliteUplink.Init() failed. No valid satellite given."
		If not satellite.launched then Throw "TStationSatelliteUplink.Init() failed. Satellite not launched."

		Super.Init(new SVec2I(10, 10), owner)
		
		SetProvider(satellite.getID())
		SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT, autoUpdateContract)

		Return self
	End Method


	'override
	Method GenerateGUID:String()
		Return "station-satellite-uplink-"+id
	End Method


	'override
	Method GetLongName:String() {_exposeToLua}
		If Not providerID
			Return GetLocale("UNUSED_TRANSMITTER")
		Else
			Return GetName()
		EndIf
	End Method


	'override
	Method GetName:String() {_exposeToLua}
		If providerID
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
			If satellite Then Return GetLocale("SATUPLINK_TO_X").Replace("%X%", satellite.name)
		EndIf
		Return Super.GetName()
	End Method


	'override
	Method GetTypeName:String() {_exposeToLua}
		Return GetLocale("SATELLITE_UPLINK")
	End Method


	Method GetProvider:TStationMap_BroadcastProvider() override
		If Not providerID Then Return Null
		Return GetStationMapCollection().GetSatellite(providerID)
	End Method


	'override
	Method CanActivate:Int()
		Local provider:TStationMap_BroadcastProvider = GetProvider()
		If Not provider Then Return False

		If Not provider.IsLaunched() Then Return False
		If Not provider.IsSubscribedChannel(Self.owner) Then Return False

		Return True
	End Method


	Method RenewContractOverDuration:Int(duration:Long) override
		If Not providerID Then Return False 'Throw "Renew a Satellitelink to map without valid satellite guid."

		'inform satellite
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If satellite
			Rem
			'subtract time left from planned duration
			local extendAmount:Long = duration - GetSubscriptionTimeLeft()
			if extendAmount > 0
				if not satellite.ExtendSubscribedChannelDuration(self.owner, extendAmount )
					return False
				endif
			endif
			endrem
			'subscribe or resubscribe if needed
			'-> contrary to "ExtendSubscribedChannelDuration" this resets
			'   SubscriptionProgress (and contract start time)
			If Not satellite.SubscribeChannel(Self.owner, duration )
				Return False
			EndIf

			'fetch new running costs (no setup fees)
			runningCosts = - 1
		EndIf

		Return Super.RenewContractOverDuration(duration)
	End Method


	Method CanSubscribeToProviderOverDuration:Int(duration:Long) override
		If Not providerID Then Return False

		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If satellite Then Return satellite.CanSubscribeChannelOverDuration(Self.owner, duration)

		Return True
	End Method


	'override to check if already subscribed
	Method CanSignContractOverDuration:Int(duration:Long) override
		If Not Super.CanSignContractOverDuration(duration) Then Return False

		If CanSubscribeToProviderOverDuration(duration) <= 0 Then Return False

		Return True
	End Method


	'override to add satellite connection
	Method SignContractOverDuration:Int(duration:Long) override
		If Not providerID Then Throw "Signing a Satellitelink to map without valid satellite id."
		If Not CanSignContractOverDuration(duration) Then Return False

		'inform satellite
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If satellite
			If duration < 0 Then duration = satellite.GetDefaultSubscribedChannelDuration()
			If Not satellite.SubscribeChannel(Self.owner, duration )
				TLogger.Log("TStationSatelliteUplink.SignContract()", "Failed to subscribe to channel.", LOG_ERROR)
			EndIf
		EndIf

		If IsShutDown() Then Resume()

		Return Super.SignContractOverDuration(duration)
	End Method


	'override to remove satellite connection
	Method CancelContracts:Int()
		'inform satellite
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If satellite
			satellite.UnsubscribeChannel(owner)
		EndIf

		Return Super.CancelContracts()
	End Method


	Method GetSubscriptionTimeLeft:Long()
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If Not satellite Then Return 0

		Local endTime:Long = satellite.GetSubscribedChannelEndTime(owner)
		If endTime < 0 Then Return 0

		Return endTime - GetWorldTime().GetTimeGone()
	End Method


	Method GetSubscriptionProgress:Float()
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If Not satellite Then Return 0

		Local startTime:Long = satellite.GetSubscribedChannelStartTime(owner)
		Local duration:Long = satellite.GetSubscribedChannelDuration(owner)
		If duration < 0 Then Return 0

		Return MathHelper.Clamp(Float((GetWorldTime().GetTimeGone() - startTime) / Double(duration)), 0.0, 1.0)
	End Method


	'override
	Method GetSellPrice:Int() {_exposeToLua}
		'sell price = cancel costs
		'cancel costs depend on the days a contract has left

		Local expense:Int
		'pay the provider for cancelingearlier
		expense = (1.0 - GetSubscriptionProgress())^2 * 3 * GetRunningCosts()

		Return -expense
	End Method


	'override
	Method GetCurrentRunningCosts:Int() {_exposeToLua}
		If HasFlag(TVTStationFlag.NO_RUNNING_COSTS) Then Return 0

		Local result:Int

		'add specific costs
		If providerID
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
			If satellite
				result :+ satellite.GetDailyFee(owner)
			EndIf
		EndIf

		'maintenance costs for the uplink to the satellite
		result :+ maintenanceCosts

		result:* GetPlayerDifficulty(owner).satelliteDailyCostsMod
		Return result
	End Method


	'override
	Method GetBuyPrice:Int() {_exposeToLua}
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If Not satellite Then Return 0


		'all sat uplinks are build in the same section
		Local uplinkSectionName:String = GetStationMapCollection().GetSatelliteUplinkSectionName()
		If Not uplinkSectionName Then Throw "no section choosen for satellite uplinks."

		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( uplinkSectionName )
		If Not section
			TLogger.Log("TStationSatelliteUplink.GetBuyPrice()", "Satellite Uplink without assigned section.", LOG_ERROR)
			Return -1337
		EndIf

		Local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)

		Local buyPrice:Int = 0

		'construction costs
		If Not IsShutdown()
			'government-dependent costs
			'section specific costs for bought land + bureaucracy costs
			buyPrice :+ section.GetPropertyAquisitionCosts(TVTStationType.SATELLITE_UPLINK)

			'reach increase in later years would make satellites very cheap compared to
			'cable (having reach 5Mio, broadcast permission 10Mio) and antenna
			'to compensate for that the dynamic purchase costs rise with coverage
			'the factor 4 is used to reach a reasonable maximum price
			'population 80 Mio, reach 1 Mio, reachFactor "irrelevant", dynamic price 500K
			'population 80 Mio, reach 5 Mio, reachFactor 0.25, dynamic price 1.75Mio
			'population 80 Mio, reach 10 Mio,reachFactor 0.5,  dynamic price 6Mio
			'the last seems to be about the maximum reach of the satellites in Germany (3 Satellites)
			Local receivers:Float = Float(GetReceivers())
			Local receiversFactor:Float = 4 * receivers / GetPopulation()
			buyPrice :+ (0.1 + receiversFactor) * receivers

			'government sympathy adjustments (-10% to +10%)
			buyPrice :* 1.0 + (0.1 * (1 - 2 * channelSympathy))

			'fixed building costs
			'building costs for "hardware" (big sat dish)
			buyPrice :+ hardwareCosts
		EndIf


		'costs for the satellite provider
		buyPrice :+ satellite.GetSetupFee(owner)

		buyPrice :* GetPlayerDifficulty(owner).satelliteBuyPriceMod
		'round it to 5000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 5000)) * 5000 )


		Return buyPrice
	End Method




	'returns percentage of receivers amongst the population
	Method GetPopulationReceiverShare:Float() override {_exposeToLua}
		'always return the satellite's value - so it stays dynamically
		'without the hassle of manual "cache refreshs"

		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If Not satellite Then Return 0.0

		Return Float(satellite.GetReceivers()) / satellite.GetPopulation()
	End Method

	
	'(set flags to True to pay attention to certain exclusiveness)
	'this is a station type specific implementation
	Method GetPopulationShare:Float(exclusiveToOwnChannel:Int = False, exclusiveToOtherChannels:Int = False) override {_exposeToLua}
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite(providerID)
		If Not satellite Then Return 0.0

		'require to be the only uplink of the channel in the section?
		If exclusiveToOwnChannel
			Local ourSatellitUplinks:Int = GetStationMap(owner).GetStationsToProviderCount(providerID, False, False)
			If ourSatellitUplinks > 1
				Return 0.0
			'this is the only one - or a new one
			'-> it is exclusive to the channel
			'Elseif GetStationMap(owner).HasStation(Self) 
			'Else
				'nothing to do
			EndIf
		EndIf
		'non-exclusive if at least one is subscribed
		If exclusiveToOtherChannels
			For local i:int = 1 to 4
				if i = owner Then continue

				If satellite.IsSubscribedChannel(i)
					Return 0.0
				EndIf
			Next
		EndIf

		Return Float(satellite.GetPopulation()) / GetStationMapCollection().GetPopulation()
	End Method
	

	Method Draw(selected:Int=False)
		'For now sat links are invisible
	End Method
End Type




Type TStationMapSection
	Field rect:TRectangle
	Field shapeSprite:TSprite {nosave}
	Field shapeSpriteName:String
	Field enabledOverlay:TImage {nosave}
	Field disabledOverlay:TImage {nosave}
	Field highlightBorderSprite:TSprite {nosave}
	Field hoveredImage:TImage {nosave}
	Field selectedImage:TImage {nosave}
	Field densityDataOffsetX:Int {nosave}
	Field densityDataOffsetY:Int {nosave}

	'the government of this section is influenced a bit by
	'pressure groups / lobbies / parties
	Field pressureGroups:Int

	Field broadcastPermissionPrice:Int = -1
	Field broadcastPermissionMinimumChannelImage:Float = 0
	Field broadcastPermissionsGiven:Int[4]

	Field cableNetworkCount:Int = 0
	Field activeCableNetworkCount:Int = 0

	'sympathy of the section's government for the individual channels
	Field channelSympathy:Float[]
	
	'(local) position inside the section
	Field uplinkPos:TVec2I

	Field name:String
	Field sectionID:Int
	Field iso3116code:String
	Field populationMap:Int[,] {nosave}
	Field population:Int = -1
	Field populationCableShare:Float = -1
	Field populationSatelliteShare:Float = -1
	Field populationAntennaShare:Float = -1
	'Field antennaShareMapImage:TImage {nosave}
	Field shareCache:TIntMap = New TIntMap {nosave}
	Field calculationMutex:TMutex = CreateMutex() {nosave}
	Field shareCacheMutex:TMutex = CreateMutex() {nosave}
	Field antennaShareMutex:TMutex = CreateMutex() {nosave}
	Field updateDataMutex:TMutex = CreateMutex() {nosave}

	'Caches
	'data reference for surface data of this section
	Field _surfaceData:TStationMapSurfaceData {nosave}

	Method New()
		channelSympathy = New Float[4]
		broadcastPermissionsGiven = New Int[4]
	End Method


	Method Create:TStationMapSection(pos:SVec2I, name:String, iso3116code:String, sectionID:Int, shapeSpriteName:String, config:TData = Null)
		Self.shapeSpriteName = shapeSpriteName
		Self.rect = New TRectangle.Init(pos.X, pos.Y, 0, 0)
		Self.name = name
		Self.sectionID = sectionID
		Self.iso3116code = iso3116code
		LoadShapeSprite()

		If config
			If config.Has("pressureGroups") 
				pressureGroups = config.GetInt("pressureGroups")
			EndIf
			If config.Has("broadcastPermissionPrice") 
				broadcastPermissionPrice = config.GetInt("broadcastPermissionPrice")
			EndIf
			If config.Has("broadcastPermissionMinimumChannelImage") 
				broadcastPermissionMinimumChannelImage = config.GetFloat("broadcastPermissionMinimumChannelImage")
			EndIf

			If config.Has("uplinkX") And config.Has("uplinkY")
				uplinkPos = New TVec2I(config.GetInt("uplinkX"), config.GetInt("uplinkY"))
			EndIf
		EndIf

		Return Self
	End Method
	
	
	Method SetSurfaceData(surfaceData:TStationMapSurfaceData)
		self._surfaceData = surfaceData
	End Method
	
	
	Method InvalidateData()
		LockMutex(shareCacheMutex)
			shareCache.Clear()
			'shareCache = New TIntMap
		UnlockMutex(shareCacheMutex)
	End Method
	

	Method LoadShapeSprite()
		shapeSprite = GetSpriteFromRegistry(shapeSpriteName)
		'resize rect
		rect.SetWH(Int(shapeSprite.area.w), Int(shapeSprite.area.h))
	End Method


	Method GetShapeSprite:TSprite()
		If Not shapeSprite Then LoadShapeSprite()
		Return shapeSprite
	End Method


	Method GetHighlightBorderSprite:TSprite()
		If Not highlightBorderSprite
			Local highlightBorderImage:TImage = ConvertToOutLine( GetShapeSprite().GetImage(), 5, 0.5, $FFFFFFFF , 9 )
			blurPixmap(LockImage( highlightBorderImage ), 0.5)

			highlightBorderSprite = New TSprite.InitFromImage(highlightBorderImage, "highlightBorderImage")
			highlightBorderSprite.offset = New SRectI(9,9,0,0)
		EndIf
		Return highlightBorderSprite
	End Method


	Method GetHoveredImage:TImage()
		If Not hoveredImage
			'create a pure white variant of the shape
			hoveredImage = ConvertToSingleColor( GetShapeSprite().GetImage(), $FFFFFFFF )
		EndIf
		Return hoveredImage
	End Method


	Method GetSelectedImage:TImage()
		If Not selectedImage
			selectedImage = ConvertToSingleColor( GetShapeSprite().GetImage(), $FF000000 )
		EndIf
		Return selectedImage
	End Method


	Method GetDisabledOverlay:TImage()
		If Not disabledOverlay
			Local shapePix:TPixmap = LockImage(GetShapeSprite().GetImage())
			Local sourcePix:TPixmap = GetStationMapCollection().mapInfo.surfaceImage.Lock(0, True, False)
			Local pix:TPixmap = ExtractPixmapFromPixmap(sourcePix, shapePix, rect.GetIntX(), rect.GetIntY())
			disabledOverlay = LoadImage( AdjustPixmapSaturation(pix, 0.20) )
			'disabledOverlay = ConvertToSingleColor( disabledOverlay, $FF999999 )
		EndIf
		Return disabledOverlay
	End Method


	Method GetEnabledOverlay:TImage()
		If Not enabledOverlay
			Local shapePix:TPixmap = LockImage(GetShapeSprite().GetImage())
			Local sourcePix:TPixmap = GetStationMapCollection().mapInfo.surfaceImage.Lock(0, True, False)
			Local pix:TPixmap = ExtractPixmapFromPixmap(sourcePix, shapePix, rect.GetIntX(), rect.GetIntY())
			enabledOverlay = LoadImage( pix )
		EndIf
		Return enabledOverlay
	End Method
	
	
	Method IsValidUplinkPos:Int(localX:Int, localY:Int)
		Local mapX:Int = rect.x + localX 
		Local mapY:Int = rect.y + localY
		Local IsValid:Int = False
		Local sprite:TSprite = GetShapeSprite()
		If Not sprite Then Return False
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()

		'check if that spot collides with another state
		If PixelIsOpaque(sprite._pix, localX, localy)
			IsValid = True

			For Local otherSection:TStationMapSection = EachIn GetStationMapCollection().sections
				If Self = otherSection Then Continue

				Local otherLocalX:Int = mapX - otherSection.rect.x
				Local otherLocalY:Int = mapY - otherSection.rect.y
				Local otherSprite:TSprite = otherSection.GetShapeSprite()
				If otherSprite 
					If Not otherSprite._pix Then otherSprite._pix = otherSprite.GetPixmap()

					If otherLocalX >= 0 And otherLocalY >= 0 And otherLocalX < otherSection.rect.GetIntW() And otherLocalY < otherSection.rect.GetIntH()
						If PixelIsOpaque(otherSprite._pix, otherLocalX, otherLocalY) > 0
							IsValid = False
						EndIf
					EndIf
				EndIf
			Next
		EndIf
		Return IsValid
	End Method
	
	
	Method GetUplinkPos:TVec2I()
		If Not uplinkPos
			'try center of section first
			Local localX:Int = rect.GetXCenter() - rect.x
			Local localY:Int = rect.GetYCenter() - rect.y
			'check if that spot collides with another state
			If Not IsValidUplinkPos(localX, localY)
				Local mapPos:SVec2I = GetStationMapCollection().GetRandomAntennaCoordinateInSection(Self, False)
				'make local position
				uplinkPos = New TVec2I(mapPos.X - rect.GetIntX(), mapPos.Y - rect.GetIntY())
			Else
				uplinkPos = New TVec2I(localX, localY)
			EndIf
		EndIf
		Return uplinkPos
	End Method


	Method DoCensus()
		'refresh stats (cable, sat, antenna share, ... maybe target
		'groups share)
	End Method
	
	
	Method GetName:String()
		Return name
	End Method


	Method GetISO3166Code:String()
		Return iso3116Code
	End Method


	'ID might be a combination of multiple groups
	Method SetPressureGroups:Int(pressureGroupID:Int, enable:Int=True)
		If enable
			pressureGroups :| pressureGroupID
		Else
			pressureGroups :& ~pressureGroupID
		EndIf
	End Method


	Method GetPressureGroups:Int()
		Return pressureGroups
	End Method


	Method HasPressureGroups:Int(pressureGroupID:Int)
		Return pressureGroups & pressureGroupID
	End Method


	Method GetPressureGroupsChannelSympathy:Float(channelID:Int)
		If pressureGroups = 0 Then Return 0
		Return GetPressureGroupCollection().GetChannelSympathy(channelID, pressureGroups)
	End Method


	Method BuyBroadcastPermission:Int(channelID:Int, stationType:Int = -1, price:Int = -1)
		If Not NeedsBroadcastPermission(channelID, stationType) Then Return False
		If HasBroadcastPermission(channelID, stationType) Then Return False

		If price = -1 Then price = GetBroadcastPermissionPrice(channelID, stationType)
		If GetPlayerFinance(channelID) And GetPlayerFinance(channelID).PayBroadcastPermission( price )
			TLogger.Log("StationMap", "Player " + channelID + " bought broadcast permission for ~q"+GetLocale("MAP_COUNTRY_"+GetISO3166Code()+"_LONG")+"~q.", LOG_DEBUG)

			SetBroadcastPermission(channelID, True, stationType)
			Return True
		EndIf
		Return False
	End Method


	'returns whether a channel needs a permission for the given station type
	'or not - regardless of whether the channel HAS one or not
	Method NeedsBroadcastPermission:Int(channelID:Int, stationType:Int = -1)
		If stationType = TVTStationType.ANTENNA And Not GameRules.antennaStationsRequireBroadcastPermission
			return False
		EndIf
		Return True
	End Method


	Method HasBroadcastPermission:Int(channelID:Int, stationType:Int = -1)
		If channelID < 1 Or channelID > broadcastPermissionsGiven.Length Then Return 0
		Return broadcastPermissionsGiven[channelID-1]
	End Method


	Method SetBroadcastPermission(channelID:Int, bool:Int, stationType:Int = -1)
		If channelID < 1 Or channelID > broadcastPermissionsGiven.Length Then Return
		broadcastPermissionsGiven[channelID-1] = bool
		If bool and broadCastPermissionMinimumChannelImage > 0
			Local count:Int = 0
			For Local i:Int = 0 To broadCastPermissionsGiven.length
				If broadCastPermissionsGiven[i] = True Then count:+ 1
			Next
			If count >= 2 Then broadCastPermissionMinimumChannelImage = 0
		Endif
	End Method


	Method GetChannelSympathy:Float(channelID:Int)
		If channelID < 1 Or channelID > channelSympathy.Length Then Return 0
		Return channelSympathy[channelID-1]
	End Method


	Method SetChannelSympathy(channelID:Int, value:Float)
		If channelID < 1 Or channelID > channelSympathy.Length Then Return
		channelSympathy[channelID-1] = MathHelper.Clamp(value, -1.0, 1.0)
	End Method


	Method GetBroadcastPermissionPrice:Int(channelID:Int, stationType:Int=-1)
		'fixed price
		If broadcastPermissionPrice <> -1 Then Return broadcastPermissionPrice
		Local difficulty:TPlayerDifficulty = GetPlayerDifficulty(channelID)

		'calculate based on population (maybe it changes)
		'or some other effects
		Local result:Int = GetPopulation()/25000 * 25000

		'adjust by sympathy (up to 25% discount or 25% on top)
		result :- 0.25 * result * GetChannelSympathy(channelID)
		result :* difficulty.broadcastPermissionPriceMod
		Return result
	End Method


	Method GetPropertyAquisitionCosts:Int(stationType:Int=-1)
		Select stationType
			Case TVTStationType.ANTENNA
				Return 35000
			Case TVTStationType.CABLE_NETWORK_UPLINK
				Return 30000
			Case TVTStationType.SATELLITE_UPLINK
				Return 50000
			Default
				Return 0
		End Select
	End Method


	Method ReachesMinimumChannelImage:Int(channelID:Int)
		If GetPublicImage(channelID).GetAverageImage() < broadcastPermissionMinimumChannelImage Then Return False

		Return True
	End Method


	Method CanGetBroadcastPermission:Int(channelID:Int)
		If Not ReachesMinimumChannelImage(channelID) Then Return -1

		Return True
	End Method


	Method DrawChannelStatusTooltip(channelID:Int, stationType:Int = -1)
		Local priceSplitH:Int = 8
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" )

		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Local screenX:Int = mapInfo.DataXToScreenX(Int(rect.x) + self.GetUplinkPos().x)
		Local screenY:Int = mapInfo.DataYToScreenY(Int(rect.y) + self.GetUplinkPos().y)

		Local stationTypeTooltipOffset:Int = 15
		if stationType = TVTStationType.CABLE_NETWORK_UPLINK Then stationTypeTooltipOffset = 5

		Local tooltipW:Int = 225
		Local tooltipH:Int = textH * 4 + 10 + 2
		Local tooltipX:Int = screenX - tooltipW/2
		Local tooltipY:Int = screenY - tooltipH - stationTypeTooltipOffset

		'move below station if at screen top
		If tooltipY < 10 Then tooltipY = screenY + 25 + stationTypeTooltipOffset
		'avoid going outside of the map
		tooltipX = MathHelper.Clamp(tooltipX, 20, GetGraphicsManager().GetWidth() - tooltipW - 20)



		Local permissionOK:Int = Not NeedsBroadcastPermission(channelID, stationType) Or HasBroadcastPermission(channelID, stationType)
		Local imageOK:Int = ReachesMinimumChannelImage(channelID)
		Local providerOK:Int = GetStationMapCollection().GetCableNetworksInSectionCount(Self.name, True) > 0

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldAlpha:Float = GetAlpha()

		SetAlpha oldAlpha * 0.5
		If Not providerOK Or Not permissionOK Or Not imageOK
			SetColor 75,0,0
		Else
			SetColor 0,0,0
		EndIf
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0
		GetSpriteFromRegistry("gfx_datasheet_border").DrawArea(tooltipX-8, tooltipY-8, tooltipW+20, tooltipH+20)		

		SetAlpha oldAlpha


		Local textY:Int = tooltipY+2
		Local textX:Int = tooltipX+3
		Local textW:Int = tooltipW-10
		Local iso:String = GetISO3166Code()
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		fontBold.DrawSimple( GetLocale("MAP_COUNTRY_"+iso+"_LONG") + " (" + GetLocale("MAP_COUNTRY_"+iso+"_SHORT")+")", textX, textY, New SColor8(250,200,100), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH + 5

		'broadcast permission
		GetBitmapFontManager().baseFont.draw(GetLocale("CABLE_NETWORKS")+": ", textX, textY)
		If Not providerOK
			fontBold.DrawBox("0", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255, 150, 150))
		Else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		textY:+ textH

		'broadcast permission
		GetBitmapFontManager().baseFont.draw(GetLocale("BROADCAST_PERMISSION")+": ", textX, textY)
		If Not permissionOK
			fontBold.DrawBox(TFunctions.convertValue(GetBroadcastPermissionPrice(channelID, stationType), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		Else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		textY:+ textH

		GetBitmapFontManager().baseFont.Draw(GetLocale("CHANNEL_IMAGE")+": ", textX, textY)
		If Not imageOK
			fontBold.DrawBox(TFunctions.LocalizedNumberToString(GetPublicImage(channelID).GetAverageImage(), 2)+"% < "+TFunctions.LocalizedNumberToString(broadcastPermissionMinimumChannelImage, 2)+"%", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255, 150, 150))
		Else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		textY:+ textH
	End Method


	Method GetPopulation:Int()
		If population < 0
			LockMutex(updateDataMutex)
				If not _surfaceData Then Throw "TStationMapSection: Cannot calculate population without surface data"
				population = 0
				
				Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
				'ensure x fits into surfaceData AND densityData
				Local limitedWidth:Int = Min(_surfaceData.width, mapInfo.densityData.width - densityDataOffsetX)
				Local limitedHeight:Int = Min(_surfaceData.height, mapInfo.densityData.height - densityDataOffsetY)

				For local x:int = 0 until limitedWidth
					For local y:int = 0 until limitedHeight
						'check if inside topography
						If _surfaceData.data[y * _surfaceData.width + x] > 0
							population :+ mapInfo.densityData.data[(y + densityDataOffsetY) * mapInfo.densityData.width + (x + densityDataOffsetX)]
						EndIf
					Next
				Next
			UnlockMutex(updateDataMutex)
		EndIf
		Return population
	End Method


	'returns the shared amount of audience between channels
	Method GetShareAudience:Int(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetReceiverShare(includeChannelMask, excludeChannelMask).shared
	End Method


	'returns the cable network share for the section
	Method GetPopulationCableShareRatio:Float()
		If populationCableShare < 0 Then Return GetStationMapCollection().GetCurrentPopulationCableShare()
		Return populationCableShare
	End Method

	'returns the antenna share for the section
	Method GetPopulationAntennaShareRatio:Float()
		If populationAntennaShare < 0 Then Return GetStationMapCollection().GetCurrentPopulationAntennaShare()
		Return populationAntennaShare
	End Method

	'returns the satellite share for the section
	Method GetPopulationSatelliteShareRatio:Float()
		If populationSatelliteShare < 0 Then Return GetStationMapCollection().GetCurrentPopulationSatelliteShare()
		Return populationSatelliteShare
	End Method


	'summary: returns maximum population a player reaches with satellites
	'         in this section
	Method GetSatelliteUplinkPopulation:Int()
		Return population * GetPopulationSatelliteShareRatio()
	End Method


	'summary: returns maximum receiver count a player reaches with satellites 
	'         in this section
	Method GetSatelliteUplinkReceivers:Int()
		'for now this is the same as for population
		'TODO: a satellite could have a kind of "expansion stage" or
		'      broadcast "window" (x,y,w,h over stationmap) and thus
		'      a custom modifier telling how much of the area is "covered"
		Return population * GetPopulationSatelliteShareRatio()
	End Method


	'summary: returns maximum population a player reaches with cable 
	'         networks in this section
	Method GetCableNetworkUplinkPopulation:Int()
		Return population * GetPopulationCableShareRatio()
	End Method


	'summary: returns maximum receiver count a player reaches with cable 
	'         networks in this section
	Method GetCableNetworkUplinkReceivers:Int()
		'for now this is the same as for population
		'TODO: a network could have a kind of "expansion stage" and thus
		'      a custom modifier telling how much of the area is "covered"
		Return population * GetPopulationCableShareRatio()
	End Method


	'summary: returns maximum amount of recievers a player reaches with antennas
	Method GetAntennaReceivers:Int(playerID:Int)
		'passing only the playerID and no other playerIDs is returning
		'the playerID's audience (with share/total being useless)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = New SChannelMask()
		Return GetAntennaReceiverShare( includeChannelMask, excludeChannelMask ).total
	End Method


	'summary: returns maximum population a player reaches with antennas
	Method GetAntennaPopulation:Int(playerID:Int)
		'passing only the playerID and no other playerIDs is returning
		'the playerID's audience (with share/total being useless)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = New SChannelMask()
		Return GetAntennaPopulationShare( includeChannelMask, excludeChannelMask ).total
	End Method


	Method GetAntennaExclusivePopulation:int(densityX:Int, densityY:int, radius:Int, owner:Int, alreadyBuilt:Int = True)
		If not _surfaceData Then Throw "TStationMapSection: Cannot calculate population without surface data"

		Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
		Local result:Int

		'data is "densitydata based"!
		'ensure rect fits into surfaceData AND densityData
		'circle coordinates are "local" to mapInfo.densityData
		Local circleRectX:Int = Max(0, densityX + self.densityDataOffsetX - radius)
		Local circleRectY:Int = Max(0, densityY + self.densityDataOffsetY - radius)
		Local circleRectX2:Int = Min(densityX + self.densityDataOffsetX + radius, Min(_surfaceData.width-1, mapInfo.densityData.width-1))
		Local circleRectY2:Int = Min(densityY + self.densityDataOffsetY + radius, Min(_surfaceData.height-1, mapInfo.densityData.height-1))
		Local radiusSquared:Int = radius * radius

		Local ownerAntennaLayer:TStationMapAntennaLayer = GetStationMap(owner)._GetAllAntennasLayer()
		Local otherAntennaLayers:TStationMapAntennaLayer[3]
		Local otherAntennaLayersUsed:int
		for local i:int = 1 to 4
			if owner <> i
				otherAntennaLayers[otherAntennaLayersUsed] = GetStationMap(i)._GetAllAntennasLayer()
				otherAntennaLayersUsed :+ 1
			EndIf
		Next
		Local checkValue:Int = 0 'nobody there
		if alreadyBuilt Then checkValue = 1 'only this very antenna is there
	
rem
		For Local posX:Int = circleRectX To circleRectX2
			For Local posY:Int = circleRectY To circleRectY2
				'left the circle?
				If CalculateDistanceSquared(posX - densityX, posY - densityY) > radiusSquared Then Continue
endrem
		For local posX:Int = circleRectX until circleRectX2
			'calculate height of the circle"slice"
			Local circleLocalX:Int = posX - densityX
			Local currentCircleH:Int = sqr(radiusSquared - circleLocalX * circleLocalX)

			For local posY:Int = Max(densityY - currentCircleH, circleRectY) until Min(densityY + currentCircleH, circleRectY2)

				'left the topographic borders ?
				'coords are local to _surfaceData
				If _surfaceData.data[(posY - self.densityDataOffsetY) * _surfaceData.width + (posX - self.densityDataOffsetX)] = 0 Then Continue

				Local layerDataIndex:Int = posY * ownerAntennaLayer.width + posX
				
				'owner already broadcasting with more than this
				'looked up antenna (in case of already "owned")?
				if ownerAntennaLayer and ownerAntennaLayer.data[posY * ownerAntennaLayer.width + posX] > checkValue Then Continue
				'others broadcasting there?
				if otherAntennaLayers[0] and otherAntennaLayers[0].data[posY * otherAntennaLayers[0].width + posX] > 0 Then Continue
				if otherAntennaLayers[1] and otherAntennaLayers[1].data[posY * otherAntennaLayers[1].width + posX] > 0 Then Continue
				if otherAntennaLayers[2] and otherAntennaLayers[2].data[posY * otherAntennaLayers[2].width + posX] > 0 Then Continue
				
				result :+ mapInfo.densityData.data[posY * mapInfo.densityData.width + posX]
			Next
		Next
		return result
	End Method


	'returns a share between channels
	'includeChannelMask contains "channels of interest" (unset are not excluded!)
	'excludeChannelMask contains "channels not allowed"
	'
	'Ex. including "channel 1 and 2" but excluding "3" will only take 
	'    areas into consideration which 1+2 share but "3" does not occupy
	'    Others, like "4" are ignored
	'    (but includeChannelMask would still have "3" and "4" unset, 
	'    this is why an "excludeChannelMask" is needed 
	'Ex. include=(1)   and exclude=(0    ) to get total reach for player 1
	'Ex. include=(1)   and exclude=(2+4+8) to getexclusive reach for player 1
	'Ex. include=(1+2) and exclude=(0    ) to get reach player 1 and 2 have together
	Method GetReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		result :+ GetAntennaReceiverShare(includeChannelMask, excludeChannelMask)
		result :+ GetCableNetworkUplinkReceiverShare(includeChannelMask, excludeChannelMask)
		result :+ GetSatelliteUplinkReceiverShare(includeChannelMask, excludeChannelMask)

		Return result
	End Method


	Method GetSatelliteUplinkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetSatelliteUplinkPopulationShare(includeChannelMask, excludeChannelMask).MultiplyFactor(GetPopulationSatelliteShareRatio())
	End Method


	Method GetCableNetworkUplinkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'no need to copy when not using a Type but a struct
		'Return GetCableNetworkPopulationShare(includeChannelMask, excludeChannelMask).Copy().MultiplyFactor(GetPopulationCableShareRatio())
		Return GetCableNetworkUplinkPopulationShare(includeChannelMask, excludeChannelMask).MultiplyFactor(GetPopulationCableShareRatio())
	End Method


	Method GetAntennaReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'no need to copy when not using a Type but a struct
		'Return GetAntennaPopulationShare(includeChannelMask, excludeChannelMask).Copy().MultiplyFactor(GetPopulationAntennaShareRatio())
		Return GetAntennaPopulationShare(includeChannelMask, excludeChannelMask).MultiplyFactor(GetPopulationAntennaShareRatio())
	End Method


	'return receivers only reached by the specificied channel/player 
	Method GetChannelExclusiveReceivers:Int(playerID:Int)
		Local result:Int
		result :+ GetChannelExclusiveAntennaReceivers(playerID)
		result :+ GetChannelExclusiveCableNetworkUplinkReceivers(playerID)
		result :+ GetChannelExclusiveSatelliteUplinkReceivers(playerID)
		return result
	End Method


	'return receivers only reached by the specified channel/player via antennas
	'(this ignores cable networks and satellites as receiver type is distinct)
	Method GetChannelExclusiveAntennaReceivers:Int(playerID:Int)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = includeChannelMask.Negated()
		Return GetAntennaReceiverShare(includeChannelMask, excludeChannelMask).total
	End Method


	'return receivers only reached by the specified channel/player via cable networks
	'(this ignores antennas and satellites as receiver type is distinct)
	Method GetChannelExclusiveCableNetworkUplinkReceivers:Int(playerID:Int)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = includeChannelMask.Negated()
		Return GetCableNetworkUplinkReceiverShare(includeChannelMask, excludeChannelMask).total
	End Method


	'return receivers only reached by the specified channel/player via satellite uplinks
	'(this ignores antennas and cable networks as receiver type is distinct)
	Method GetChannelExclusiveSatelliteUplinkReceivers:Int(playerID:Int)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = includeChannelMask.Negated()
		Return GetSatelliteUplinkReceiverShare(includeChannelMask, excludeChannelMask).total
	End Method


	'returns a share between channels
	'includeChannelMask contains "channels of interest" (unset are not excluded!)
	'excludeChannelMask contains "channels not allowed"
	'
	'Ex. including "channel 1 and 2" but excluding "3" will only take 
	'    areas into consideration which 1+2 share but "3" does not occupy
	'    Others, like "4" are ignored
	'    (but includeChannelMask would still have "3" and "4" unset, 
	'    this is why an "excludeChannelMask" is needed 
	'Ex. include=(1)   and exclude=(0    ) to get total reach for player 1
	'Ex. include=(1)   and exclude=(2+4+8) to get exclusive reach for player 1
	'Ex. include=(1+2) and exclude=(0    ) to get reach player 1 and 2 have together
	Method GetSatelliteUplinkPopulationShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		If includeChannelMask.value = 0 Then Return New SStationMapPopulationShare

		'=== CHECK CACHE ===
		'if already cached, save time...

		'== GENERATE KEY ==
		Local cacheKey:Int = Int(TVTStationType.SATELLITE_UPLINK & 255) Shl 24 | Int(includeChannelMask.value & 255) Shl 16 | Int(excludeChannelMask.value & 255) Shl 8
		
		Local result:TStationMapPopulationShare

		'== LOAD CACHE ==
		If shareCache
			LockMutex(shareCacheMutex)
			result = TStationMapPopulationShare(shareCache.ValueForKey(cacheKey))
			UnlockMutex(shareCacheMutex)
		EndIf
		
		
		'== GENERATE CACHE ==
		If Not result
			Local includedChannelsWithUplink:Int = 0
			Local excludedChannelsWithUplink:Int = 0

			'count how many of the "mentioned" channels have at least
			'one active uplink there
			For Local channelID:Int = 1 To GetStationMapCollection().stationMaps.Length
				If includeChannelMask.Has(channelID)
					If GetStationMap(channelID).GetSatelliteUplinksCount( True ) > 0
						includedChannelsWithUplink :+ 1
					EndIf
				ElseIf excludeChannelMask.Has(channelID)
					If GetStationMap(channelID).GetSatelliteUplinksCount( True ) > 0
						excludedChannelsWithUplink :+ 1
					Endif
				EndIf
			Next

			result = New TStationMapPopulationShare
			If includedChannelsWithUplink > 0
				'total - if at least _one_ channel uses a satellite
				result.value.total = population

				'all included channels neet to have an uplink ("and" instead of "or" connection)
				If includedChannelsWithUplink = includeChannelMask.GetEnabledCount()
					'as soon as one "excluded" has an uplink, we know
					'the "included" won't be exclusive
					If excludedChannelsWithUplink = 0
						result.value.shared = population
					EndIf
				EndIf
			EndIf

			'store new cached data
			If shareCache 
				LockMutex(shareCacheMutex)
				shareCache.insert(cacheKey, result)
				UnlockMutex(shareCacheMutex)
			EndIf
		EndIf

		Return result.value
	End Method

	'returns a share between channels
	'includeChannelMask contains "channels of interest" (unset are not excluded!)
	'excludeChannelMask contains "channels not allowed"
	'
	'Ex. including "channel 1 and 2" but excluding "3" will only take 
	'    areas into consideration which 1+2 share but "3" does not occupy
	'    Others, like "4" are ignored
	'    (but includeChannelMask would still have "3" and "4" unset, 
	'    this is why an "excludeChannelMask" is needed 
	'Ex. include=(1)   and exclude=(0    ) to get total reach for player 1
	'Ex. include=(1)   and exclude=(2+4+8) to get exclusive reach for player 1
	'Ex. include=(1+2) and exclude=(0    ) to get reach player 1 and 2 have together
	Method GetCableNetworkUplinkPopulationShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		If includeChannelMask.value = 0 Then Return New SStationMapPopulationShare

		'=== CHECK CACHE ===
		'if already cached, save time...

		'== GENERATE KEY ==
'		Local cacheKey:String = New TStringBuilder().Append("cablenetwork").Append("_").Append(includeChannelMask.value).Append("_").Append(excludeChannelMask.value).ToString()
'		Local cacheKey:String = "cablenetwork"+"_"+includeChannelMask.value+"_"+excludeChannelMask.value
							 'cablenetwork                                           care only first for first 8 channels         care only first for 8 channels
		Local cacheKey:Int = Int(TVTStationType.CABLE_NETWORK_UPLINK & 255) Shl 24 | Int(includeChannelMask.value & 255) Shl 16 | Int(excludeChannelMask.value & 255) Shl 8
		
		Local result:TStationMapPopulationShare

		'== LOAD CACHE ==
		If shareCache
			LockMutex(shareCacheMutex)
			result = TStationMapPopulationShare(shareCache.ValueForKey(cacheKey))
			UnlockMutex(shareCacheMutex)
		EndIf


		'== GENERATE CACHE ==
		If Not result
			Local includedChannelsWithCableNetwork:Int = 0
			Local excludedChannelsWithCableNetwork:Int = 0

			'count how many of the "mentioned" channels have at least
			'one active uplink there
			For Local channelID:Int = 1 To GetStationMapCollection().stationMaps.Length
				If includeChannelMask.Has(channelID)
					If GetStationMap(channelID).GetCableNetworkUplinksInSectionCount( name, True ) > 0
						includedChannelsWithCableNetwork :+ 1
					EndIf
				ElseIf excludeChannelMask.Has(channelID)
					If GetStationMap(channelID).GetCableNetworkUplinksInSectionCount( name, True ) > 0
						excludedChannelsWithCableNetwork :+ 1
					Endif
				EndIf
			Next

			result = New TStationMapPopulationShare
			If includedChannelsWithCableNetwork > 0
				'total - if at least _one_ channel uses a cable network
				result.value.total = population

				'all included channels neet to have an uplink ("and" instead of "or" connection)
				If includedChannelsWithCableNetwork = includeChannelMask.GetEnabledCount()
					'as soon as one "excluded" has an uplink there, we know
					'the "included" won't be exclusive
					'(with only 1 network you cannot only use 50% of it)
					If excludedChannelsWithCableNetwork = 0
						result.value.shared = population
					EndIf
				EndIf
			EndIf

			'store new cached data
			If shareCache 
				LockMutex(shareCacheMutex)
				shareCache.insert(cacheKey, result)
				UnlockMutex(shareCacheMutex)
			EndIf

			'print "CABLE uncached: "+cacheKey
			'local dbgString:String = "ChannelMask: incl=" + LSet(includeChannelMask.ToString(), 12) + "  excl=" + LSet(excludeChannelMask.ToString(), 12)
			'dbgString :+ "  channelsWithCableNetwork: " + includedChannelsWithCableNetwork + " included, " + excludedChannelsWithCableNetwork + " excluded"
			'dbgString :+ "  -> CABLE share:  total="+LSet(result.value.total, 8) + "  shared="+LSet(result.value.shared, 8)
			'print dbgString
		Else
			'print "CABLE cached: "+cacheKey
			'local dbgString:String = "ChannelMask: incl=" + LSet(includeChannelMask.ToString(), 12) + "  excl=" + LSet(excludeChannelMask.ToString(), 12)
			'dbgString :+ "  -> CABLE share:  total="+LSet(result.value.total, 8) + "  shared="+LSet(result.value.shared, 8)
			'print dbgString
		EndIf

		Return result.value
	End Method


	'returns a share between channels
	'includeChannelMask contains "channels of interest" (unset are not excluded!)
	'excludeChannelMask contains "channels not allowed" (at the points of the antenna)
	'
	'Ex. including "channel 1 and 2" but excluding "3" will only take 
	'    areas into consideration which 1+2 share but "3" does not occupy
	'    Others, like "4" are ignored
	'    (but includeChannelMask would still have "3" and "4" unset, 
	'    this is why an "excludeChannelMask" is needed 
	'Ex. include=(1)   and exclude=(0    ) to get total reach for player 1
	'Ex. include=(1)   and exclude=(2+4+8) to get exclusive reach for player 1
	'Ex. include=(1+2) and exclude=(0    ) to get reach player 1 and 2 have together
	Method GetAntennaPopulationShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'if there is nothing to include, simply return an empty share
		If includeChannelMask.value = 0 Then Return New SStationMapPopulationShare

		'store existing station maps (so non-existing can be excluded)
		Local map1:TStationMap = GetStationMap(1)
		Local map2:TStationMap = GetStationMap(2)
		Local map3:TStationMap = GetStationMap(3)
		Local map4:TStationMap = GetStationMap(4)
		'if there is none existing yet, simply return an empty share
		'If not (map1 or map2 or map3 or map4) Then Return New SStationMapPopulationShare

		Local result:TStationMapPopulationShare


		'=== CHECK CACHE ===
		'if already cached, save time...

		'== GENERATE KEY ==
							 'antenna                                   care only first for first 8 channels         care only first for 8 channels
		Local cacheKey:Int = Int(TVTStationType.ANTENNA & 255) Shl 24 | Int(includeChannelMask.value & 255) Shl 16 | Int(excludeChannelMask.value & 255) Shl 8


		'== LOAD CACHE ==
		If shareCache
			LockMutex(shareCacheMutex)
			result = TStationMapPopulationShare(shareCache.ValueForKey(cacheKey))
			UnlockMutex(shareCacheMutex)
		EndIf

		'== GENERATE CACHE ==
		If Not result
			'antenna layers are placed directly (no offset) over densityData
			'(but might have a different width/height)
			Local antennaLayer1:TStationMapAntennaLayer
			Local antennaLayer2:TStationMapAntennaLayer
			Local antennaLayer3:TStationMapAntennaLayer
			Local antennaLayer4:TStationMapAntennaLayer
			Local referenceLayer:TStationMapAntennaLayer
			If map1 Then antennaLayer1 = map1._GetAllAntennasLayer()
			If map2 Then antennaLayer2 = map2._GetAllAntennasLayer()
			If map3 Then antennaLayer3 = map3._GetAllAntennasLayer()
			If map4 Then antennaLayer4 = map4._GetAllAntennasLayer()
			If antennaLayer1 and not referenceLayer Then referenceLayer = antennaLayer1
			If antennaLayer2 and not referenceLayer Then referenceLayer = antennaLayer2
			If antennaLayer3 and not referenceLayer Then referenceLayer = antennaLayer3
			If antennaLayer4 and not referenceLayer Then referenceLayer = antennaLayer4

			'if there is no antenna layer at all, simply return an empty share
			If Not referenceLayer Then Return New SStationMapPopulationShare


			result = New TStationMapPopulationShare

			Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo

			'only read as far as the intersection of all data layer "rects"
			'allow
			'antennaLayer: no offset, coord local to densityData (same 0,0)
			Local antennaLayerRect:SRectI = New SRectI(0, 0, referenceLayer.width, referenceLayer.height)
			'densityLayer: no offset
			Local densityDataRect:SRectI = New SRectI(0, 0, mapInfo.densityData.width, mapInfo.densityData.height)
			'section surface/topography: local to surface but contains densityDataOffsetX/Y
			'surfaceData is already scaled to density data size, 
			'densityDataOffsets are scaled too 
			Local surfaceDataRect:SRectI = New SRectI(densityDataOffsetX, densityDataOffsetY, _surfaceData.width, _surfaceData.height)
			Local effectiveRect:SRectI = antennaLayerRect.IntersectRect(densityDataRect).IntersectRect(surfaceDataRect)
			rem
			'debug values:
			print self.GetName()
			print "  antennaLayerRect:" + antennaLayerRect.x+", " + antennaLayerRect.y + ", " + antennaLayerRect.w + ", " + antennaLayerRect.h
			print "  densityDataRect:" + densityDataRect.x+", " + densityDataRect.y + ", " + densityDataRect.w + ", " + densityDataRect.h
			print "  surfaceDataRect:" + surfaceDataRect.x+", " + surfaceDataRect.y + ", " + surfaceDataRect.w + ", " + surfaceDataRect.h
			print "  effectiveRect:" + effectiveRect.x+", " + effectiveRect.y + ", " + effectiveRect.w + ", " + effectiveRect.h
			endrem
			For Local mapX:Int = effectiveRect.x Until effectiveRect.x + effectiveRect.w
				For Local mapY:Int = effectiveRect.y Until effectiveRect.y + effectiveRect.h
					'ensure point is within topography of the section
					'surfacedata is "local" to the section, so subtract
					'x1, y1 to start at the datas "0,0"
					If _surfaceData.data[(mapY-densityDataOffsetY) * _surfaceData.width + (mapX-densityDataOffsetX)] = 0 Then Continue

					Local index:Int = mapY * referenceLayer.width + mapX
					Local mask:Byte
					mask :+ (antennaLayer1 and antennaLayer1.data[index] > 0) * 1
					mask :+ (antennaLayer2 and antennaLayer2.data[index] > 0) * 2
					mask :+ (antennaLayer3 and antennaLayer3.data[index] > 0) * 4
					mask :+ (antennaLayer4 and antennaLayer4.data[index] > 0) * 8

					'skip if none of our interested is here
					If includeChannelMask.HasNone(mask) Then Continue
					'skip if one of the to exclude is here
					If Not excludeChannelMask.HasNone(mask) Then Continue

					local popAtPoint:Int = mapInfo.densityData.data[mapY * mapInfo.densityData.width + mapX]

					'someone has a station there
					'-> check already done in the skip above
					'If ((mapMask.mask & includeChannelMask) <> 0)
						result.value.total :+ popAtPoint
					'EndIf
					'all searched have a station there
					If (mask & includeChannelMask.value) = includeChannelMask.value
						result.value.shared :+ popAtPoint
					EndIf
				Next
			Next

			'store new cached data
			If shareCache
				LockMutex(shareCacheMutex)
				shareCache.insert(cacheKey, result )
				UnlockMutex(shareCacheMutex)
			EndIf

			'print "ANTENNA uncached: section=" + LSet(GetName(), 15) + " key="+LSet(string(cacheKey),10) + " | share.total="+int(result.value.total)+"  share.shared="+int(result.value.shared)
		'Else
		'	print "ANTENNA   cached: section=" + LSet(GetName(), 15) + " key="+LSet(string(cacheKey),10) + " | share.total="+int(result.value.total)+"  share.shared="+int(result.value.shared)
		EndIf
		UnlockMutex(antennaShareMutex)

		Return result.value
	End Method
End Type


'when just comparing lengths ... we could also skip doing the
'square root calculation
'marking it "inline" speeds up calculation A LOT (when called very often)
Function CalculateDistanceSquared:Long(x1:Int, x2:Int) Inline
	Return (x1*x1) + (x2*x2)
End Function

'summary: returns calculated distance between 2 points
'marking it "inline" speeds up calculation A LOT (when called very often)
Function CalculateDistance:Double(x1:Int, x2:Int) Inline
	Return Sqr((x1*x1) + (x2*x2))
End Function




Type TStationMapShareMask
	Field X:Int
	Field Y:Int
	Field mask:Int
	
	Method New(X:Int, Y:Int, mask:Int)
		Self.X = X
		Self.Y = Y
		Self.mask = mask
	End Method
End Type




Type TStationMapAntennaPoint
	Field X:Int
	Field Y:Int
	Field value:Int
	
	Method New(X:Int, Y:Int, value:Int)
		Self.X = X
		Self.Y = Y
		Self.value = value
	End Method
End Type




Type TStationMapPopulationShare
	Field value:SStationMapPopulationShare
End Type




Struct SStationMapPopulationShare
	Field shared:Int 'in people
	Field total:Int 'in people
	
	Method GetShareRatio:Float()
		If total = 0 Then Return 0
		Return shared/total
	End Method
	
	
	Method Copy:SStationMapPopulationShare()
		Local c:SStationMapPopulationShare
		c.shared = Self.shared
		c.total = Self.total
		Return c
	End Method
	
	
	Method Add:SStationMapPopulationShare(other:SStationMapPopulationShare)
		Self.shared :+ other.shared
		Self.total :+ other.total
	End Method
	

	Method MultiplyFactor:SStationMapPopulationShare(factor:Float)
		Self.shared :* factor
		Self.total :* factor
		Return Self
	End Method


    Method Operator :+(other:SStationMapPopulationShare)
		Self.shared :+ other.shared
		Self.total :+ other.total
    End Method
End Struct



'cable network, satellite ... providers which allows booking of
'channel capacity
Type TStationMap_BroadcastProvider Extends TEntityBase {_exposeToLua="selected"}
	Field name:String

	'minimum image needed to be able to subscribe
	Field minimumChannelImage:Float
	'the lobbies behind the satellite owner - so their standing
	'with a channel affects prices/fees
	Field pressureGroups:Int

	'limit for currently subscribed channels
	Field channelMax:Int = 5
	'channelIDs for channels currently subscribed to the satellite
	Field subscribedChannels:Int[]
	'when do their contracts start and end?
	Field subscribedChannelsStartTime:Long[]
	Field subscribedChannelsDuration:Long[]

	Field launched:Int = False
	Field launchTime:Long
	Field lifeTime:Long = -1
	'eg. signal strength
	'used to evaluate which satellite the people would prefer
	'when comparing them (-> populationShare)
	'satellites could get upgrades by sat company for higher quality
	'or wear off...
	Field quality:Int = 100
	'to see whether it increased or not (increase if "best" satellite
	'stops working and quality lowers)
	Field oldQuality:Int = 100

	'costs
	Field dailyFeeMod:Float = 1.0
	Field setupFeeMod:Float = 1.0
	Field setupFeeBase:Int = 500000
	Field dailyFeeBase:Int = 75000

	Field listSpriteNameOn:String = "gfx_datasheet_icon_antenna.on"
	Field listSpriteNameOff:String = "gfx_datasheet_icon_antenna.off"


	Method GetName:String() {_exposeToLua}
		Return name
	End Method


	'ID might be a combination of multiple groups
	Method SetPressureGroups:Int(pressureGroupID:Int, enable:Int=True)
		If enable
			pressureGroups :| pressureGroupID
		Else
			pressureGroups :& ~pressureGroupID
		EndIf
	End Method


	Method GetPressureGroups:Int()
		Return pressureGroups
	End Method


	Method HasPressureGroups:Int(pressureGroupID:Int)
		Return pressureGroups & pressureGroupID
	End Method


	Method GetPressureGroupsChannelSympathy:Float(channelID:Int)
		If pressureGroups = 0 Then Return 0
		Return GetPressureGroupCollection().GetChannelSympathy(channelID, pressureGroups)
	End Method


	Method GetSubscribedChannelIndex:Int(channelID:Int)
		For Local i:Int = 0 Until subscribedChannels.Length
			If subscribedChannels[i] = channelID Then Return i
		Next
		Return -1
	End Method


	Method GetSubscribedChannelStartTime:Long(channelID:Int)
		Local i:Int = GetSubscribedChannelIndex(channelID)
		If i = -1 Then Return -1

		Return subscribedChannelsStartTime[i]
	End Method


	Method GetSubscribedChannelEndTime:Long(channelID:Int)
		Local i:Int = GetSubscribedChannelIndex(channelID)
		If i = -1 Then Return -1

		Return subscribedChannelsStartTime[i] + subscribedChannelsDuration[i]
	End Method


	Method GetSubscribedChannelDuration:Long(channelID:Int)
		Local i:Int = GetSubscribedChannelIndex(channelID)
		If i = -1 Then Return -1

		Return subscribedChannelsDuration[i]
	End Method


	Method ExtendSubscribedChannelDuration:Long(channelID:Int, extendBy:Int)
		Local i:Int = GetSubscribedChannelIndex(channelID)
		If i = -1 Then Return -1

		subscribedChannelsDuration[i] :+ extendBy
		Return True
	End Method


	Method GetDefaultSubscribedChannelDuration:Long()
		'return 0.25 * GetWorldTime().GetYearLength()
		Return GetWorldTime().GetYearLength()
	End Method


	Method GetSubscribedChannelCount:Int() {_exposeToLua}
		If Not subscribedChannels Then Return 0
		Return subscribedChannels.Length
	End Method


	Method IsSubscribedChannel:Int(channelID:Int) {_exposeToLua}
		For Local i:Int = EachIn subscribedChannels
			If i = channelID Then Return True
		Next
		Return False
	End Method


	Method CanSubscribeChannel:Int(channelID:Int) {_exposeToLua}
		Return CanSubscribeChannelOverDuration(channelID, -1)
	End Method


	Method CanSubscribeChannelOverDuration:Int(channelID:Int, duration:Long)
		If minimumChannelImage > 0 And minimumChannelImage > GetPublicImage(channelID).GetAverageImage() Then Return -1
		If channelMax >= 0 And subscribedChannels.Length >= channelMax Then Return -2

		Return 1
	End Method


	Method SubscribeChannel:Int(channelID:Int, duration:Long, force:Int=False)
		If Not force And CanSubscribeChannelOverDuration(channelID, duration) <> 1 Then Return False

		If duration < 0 Then duration = GetDefaultSubscribedChannelDuration()

		If IsSubscribedChannel(channelID)
			Local i:Int = GetSubscribedChannelIndex(channelID)
			If i = -1 Then Return -1

			subscribedChannelsStartTime[i] = GetWorldTime().GetTimeGone()
			subscribedChannelsDuration[i] = duration

		Else
			subscribedChannels :+ [channelID]
			subscribedChannelsStartTime :+ [GetWorldTime().GetTimeGone()]
			subscribedChannelsDuration :+ [duration]
		EndIf
		If minimumChannelImage > 0 and GetSubscribedChannelCount() > 1 Then minimumChannelImage = 0

		Return True
	End Method


	Method UnsubscribeChannel:Int(channelID:Int)
		Local index:Int = -1
		For Local i:Int = 0 Until subscribedChannels.Length
			If subscribedChannels[i] = channelID Then index = i
		Next
		'if index = -1 
		'	print "UnubscribeChannel("+channelID+"): not subscribed."
		'else
		'	print "UnubscribeChannel("+channelID+"): unsubscribed."
		'endif
		If index = -1 Then Return False

		subscribedChannels = subscribedChannels[.. index] + subscribedChannels[index+1 ..]
		subscribedChannelsStartTime = subscribedChannelsStartTime[.. index] + subscribedChannelsStartTime[index+1 ..]
		subscribedChannelsDuration = subscribedChannelsDuration[.. index] + subscribedChannelsDuration[index+1 ..]


		Return True
	End Method


	'population covered (reachable people if all in area would use that provider)
	Method GetPopulation:Int() Abstract {_exposeToLua}


	'get amount of exclusively reachable population with this provider
	Method GetExclusivePopulation:Int() Abstract {_exposeToLua}


	'get amount of receivers reached with this provider
	Method GetReceivers:Int() Abstract {_exposeToLua}


	'get amount of exclusive receivers with this provider
	Method GetExclusiveReceivers:Int() Abstract {_exposeToLua}


	Method GetSetupFee:Int(channelID:Int) {_exposeToLua}
		Local channelSympathy:Float = GetPressureGroupsChannelSympathy(channelID)
		Local price:Int

		price = setupFeeBase
		'add a cpm (costs per mille) approach - reach changes over time
		price :+ 0.25 * GetReceivers()/1000

		'adjust by individual mod
		price :* setupFeeMod

		'-25% to +25% to price depending on sympathy
		'price :+ 0.25 * (-1 + 2*channelSympathy) * price
		price :* 1.0 + (0.25 * (1 - 2*channelSympathy))

		'round it to 5000-steps
		price = Max(0 , Int(Ceil(price / 5000)) * 5000 )

		Return price
	End Method


	'similar to "running costs"
	Method GetDailyFee:Int(channelID:Int) {_exposeToLua}
		Local channelSympathy:Float = GetPressureGroupsChannelSympathy(channelID)
		Local price:Int

		price = dailyFeeBase
		'add a cpm (costs per mille) approach - reach changes over time
		price :+ 0.10 * GetReceivers()

		'adjust by individual mod
		price :* dailyFeeMod

		'-25% to +25% to price depending on sympathy
		price :+ 0.25 * price * (1.0 - channelSympathy)

		'round it to 5000-steps
		price = Max(0 , Int(Ceil(price / 5000)) * 5000 )

		Return price
	End Method


	Method IsActive:Int() {_exposeToLua}
		'for now we only check "launched" but satellites could need a repair...
		Return launched
	End Method


	Method IsLaunched:Int() {_exposeToLua}
		Return launched
	End Method


	Method Launch:Int()
		If launched Then Return False

		launched = True

		'inform others
		TriggerBaseEvent(GameEventKeys.BroadcastProvider_OnLaunch, Null, Self)

		Return True
	End Method


	Method SetActive:Int(force:Int = False)
		If IsActive() Then Return False

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.BroadcastProvider_OnSetActive, Null, Self)
	End Method


	Method SetInactive:Int()
		If Not IsActive() Then Return False

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.BroadcastProvider_OnSetInactive, Null, Self)
	End Method


	Method Update:Int()
		If Not launched
			If launchTime < GetWorldTime().GetTimeGone()
				Launch()
			EndIf
		EndIf
	End Method
	
	
	Method CancelSubscription:Int(channelID:Int)
		'(indirectly) inform concerning stationlink
		GetStationMapCollection().RemoveUplinkFromBroadcastProvider(Self, channelID)

		'RON: already done via "RemoveUplinkFromBroadcastProvider" above
		'finally unsubscripe (do _after_ uplink removal
		'as else a uplink identification via channelID would fail)
		'UnsubscribeChannel(channelID)
	End Method


	'run extra so you could update station (and its subscription) after
	'a launch/start of the provider but before it removes uplinks
	Method UpdateSubscriptions:Int()
		'process array backwards because it may be shortened by cancelSubscription
		For Local i:Int = subscribedChannels.Length-1 To 0 Step -1
			If subscribedChannels[i] And subscribedChannelsDuration[i] >= 0
				If subscribedChannelsStartTime[i] + subscribedChannelsDuration[i] < GetWorldTime().GetTimeGone()
					Local channelID:Int = subscribedChannels[i]
					CancelSubscription(channelID)
				EndIf
			EndIf
		Next
	End Method
End Type




'excuse naming scheme but "TCableNetwork" is ambiguous for "stationtypes"
Type TStationMap_CableNetwork Extends TStationMap_BroadcastProvider {_exposeToLua="selected"}
	'how many of the people in reach are reachable at all
	'eg. some villages are less easy to reach with cable so this
	'section has a lower share
	'or competitors in the same section take away some people
	'(cable is "exclusive")
	Field populationShare:Float = 1.0

	'operators
	Field sectionName:String {_exposeToLua}
	Field sectionISO3116Code:String {_exposeToLua}


	'override
	Method GenerateGUID:String()
		Return "stationmap-cablenetwork-"+id
	End Method


	Method GetPopulation:Int() override {_exposeToLua}
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
		If Not section Then Return 0

		Return section.GetCableNetworkUplinkPopulation()
	End Method


	Method GetExclusivePopulation:Int() override {_exposeToLua}
		'for now there only exists one cable network provider
		'per section/federal state
		'so there is no need to check for coexisting ones.
		Return GetPopulation()
	End Method


	Method GetReceivers:Int() override {_exposeToLua}
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
		If Not section Then Return 0

		Local result:Int
		'this allows individual cablenetworkReceiveRatios for the
		'sections (eg bad infrastructure for cables or expensive)
		result = section.GetCableNetworkUplinkReceivers()
		
		'multiply with the percentage of users selecting THIS network
		'over other cable providers (eg only provider 1 offers it in the
		'city or street)
		result :* populationShare

		Return result
	End Method


	Method GetExclusiveReceivers:Int() override {_exposeToLua}
		'for now there only exists one cable network provider
		'per section/federal state
		'so there is no need to check for coexisting ones.
		Return GetReceivers()
	End Method



	Method GetName:String() {_exposeToLua}
		Return name.Replace("%name%", GetLocale("MAP_COUNTRY_"+sectionISO3116Code+"_LONG"))
	End Method


	'override
	Method Launch:Int()
		If Not Super.Launch() Then Return False

		GetStationMapCollection().OnLaunchCableNetwork(Self)
		TLogger.Log("CableNetwork.Launch", "Launching cable network ~q"+GetName()+"~q. Date: " + GetWorldTime().GetFormattedGameDate(launchTime), LOG_DEBUG)

		Return True
	End Method
End Type




'excuse naming scheme but "TSatellite" is ambiguous for "stationtypes"
Type TStationMap_Satellite Extends TStationMap_BroadcastProvider {_exposeToLua="selected"}
	'how many of the people in reach are reachable at all
	'eg. adjusted their dishes to receive the satellite
	'    -> this might change over time (more channels on a "better"
	'       satellite)
	Field populationShare:Float = 0.0
	'to see whether it increased or not
	Field oldPopulationShare:Float = 0.0

	'name without revision
	Field brandName:String

	Field nextTechUpgradeTime:Long = -1
	Field nextTechUpgradeValue:Int = 0
	Field techUpgradeSpeed:Int
	Field deathTime:Long = -1
	'is death decided (no further changes possible)
	'this allows ancestors/other revisions to get launched then
	Field deathDecided:Int = False
	'version of the satellite
	Field revision:Int = 1


	Method New()
		techUpgradeSpeed = BiasedRandRange(75,125, 0.5) '75-125%

		listSpriteNameOn = "gfx_datasheet_icon_satellite_uplink.on"
		listSpriteNameOff = "gfx_datasheet_icon_satellite_uplink.off"
	End Method


	'override
	Method GenerateGUID:String()
		Return "stationmap-satellite-"+id
	End Method


	Method GetPopulation:Int() override {_exposeToLua}
		Return GetStationMapCollection().GetPopulation()
	End Method


	Method GetExclusivePopulation:Int() override {_exposeToLua}
		'multiply with the percentage of people selecting THIS satellite
		'over other satellites (assume all satellites cover the complete
		'map)
		'(Others would, if all had to watch over satellite, choose a different satellite)

		Return GetPopulation() * populationShare
	End Method


	Method GetReceivers:Int() override {_exposeToLua}
		Local result:Int

		'sum up receivers (choosing to watch via satellite) of all sections
		'this allows individual satelliteReceiveRatios for the sections
		For Local s:TStationMapSection = EachIn GetStationMapCollection().sections
			result :+ s.GetSatelliteUplinkReceivers()
		Next

		'multiply with the percentage of people selecting THIS satellite
		'over other satellites (assume all satellites cover the complete
		'map)
		result :* populationShare

		Return result
	End Method


	Method GetExclusiveReceivers:Int() override {_exposeToLua}
		'people can only receive one satellite at a time - so receiver
		'count is already exclusive
		Return GetReceivers()
	End Method


	'override
	Method GetDefaultSubscribedChannelDuration:Long()
		If deathTime <= 0 Then Return Super.GetDefaultSubscribedChannelDuration()
		'days are rounded down, so they always are lower than the real life time
		Local daysToDeath:Int = (deathTime - GetWorldTime().GetTimeGone()) / TWorldTime.DAYLENGTH

		Return Min(Super.GetDefaultSubscribedChannelDuration(), daysToDeath * TWorldTime.DAYLENGTH)
	End Method


	'override
	Method Launch:Int()
		If Not Super.Launch() Then Return False

		'set death to be somewhere in 8-12 years
		deathTime = GetWorldTime().ModifyTime(launchTime, RandRange(8,12), 0, 0, RandRange(200,800))

		GetStationMapCollection().OnLaunchSatellite(Self)
		TLogger.Log("Satellite.Launch", "Launching satellite ~q"+name+"~q. Receivers: " + GetReceivers() +"  Population: " + GetPopulation()+"  Date: " + GetWorldTime().GetFormattedGameDate(launchTime) +"  Death: " + GetWorldTime().GetFormattedGameDate(deathTime), LOG_DEBUG)

		Return True
	End Method
	
	
	Method Die:Int()
		'cancel all subscriptions / sat uplinks 
		For Local i:Int = 0 Until subscribedChannels.Length
			If subscribedChannels[i]
				Local channelID:Int = subscribedChannels[i]
				CancelSubscription(channelID)
			EndIf
		Next
	
		TLogger.Log("Satellite.Die", "Stopping satellite ~q"+name+"~q. Launch: " + GetWorldTime().GetFormattedGameDate(launchTime) +"  Death: " + GetWorldTime().GetFormattedGameDate(deathTime), LOG_DEBUG)
	End Method


	Method Update:Int()
		Super.Update()

		'no research, death ... if already decided to stop soon
		If IsLaunched() And Not deathDecided
			'death in <3 days?
			If deathTime - 3*TWorldTime.dayLength < GetWorldTime().GetTimeGone()
				deathDecided = True
				GetStationMapCollection().OnLetDieSatellite(Self)
			EndIf

			If nextTechUpgradeTime < GetWorldTime().GetTimeGone()
				If nextTechUpgradeTime > 0
					quality :+ nextTechUpgradeValue
					'inform others (eg. for news)
					TriggerBaseEvent(GameEventKeys.Satellite_OnUpgradeTech, New TData.AddInt("quality", quality).Addint("oldQuality", quality - nextTechUpgradeValue), Self )
					'print "satellite " + name +" upgraded technology " + (quality - nextTechUpgradeValue) +" -> " + quality
				EndIf

				nextTechUpgradeTime = GetWorldTime().ModifyTime(-1, 0, 0, Int(RandRange(250,350) * 100.0/techUpgradeSpeed))
				nextTechUpgradeValue = BiasedRandRange(10, 25, 0.2) * 100.0/techUpgradeSpeed
			EndIf
		EndIf
	End Method
End Type



'Container for a data array to allow sharing the array without
'caring for references to it (array copies on resize)
Type TStationMapSurfaceData
	Field data:Byte[]
	Field width:Int
	Field height:Int
	
	Method New(width:Int, height:Int)
		self.width = width
		self.height = height
		self.data = New Byte[width*height]
	End Method


	Method New(pix:TPixmap)
		self.data = New Byte[pix.width * pix.height]
		self.width = pix.width
		self.height = pix.height
		SetDataFromPixmap(pix)
	End Method
	

	Method SetDataFromPixmap:TStationMapSurfaceData(pix:TPixmap, offsetX:Int = 0, offsetY:Int = 0, value:int = 1)
		'bigger images are allowed - but pixels are skipped!
		'If width < pix.width + offsetX or height < pix.height + offsetY 
		'	Throw "SetDataFrompixmap: Pix too big. pix=" + pix.width+","+pix.height+"  offset="+offsetX+","+offsetY+"  own="+width+","+height
		'EndIf
		 
		If pix.format = PF_RGBA8888
			For local x:int = 0 until pix.width
				For local y:int = 0 until pix.height
					Local pixelPtr:Byte Ptr = pix.pixels + (y * pix.pitch + x * 4)
					'alpha
					If pixelPtr[3] <= 0 Then Continue

					'default value is 0, so we only need to set values
					'for "opaque pixels" 
					'avoid exceeding data container
					if x + offsetX < width and y + offsetY < height Then data[(y + offsetY) * width + (x + offsetX)] = value
				Next
			Next
		Else
			Throw "DataFromPixmap: only PF_RGBA8888 format supported"
		EndIf
		Return Self
	End Method
	

	Method ToPixmap:TPixmap()
		Local pix:TPixmap = CreatePixmap(self.width, self.height, PF_RGBA8888)
		pix.ClearPixels(0)
		For local x:Int = 0 until width
			For local y:Int = 0 until height
				Local value:Byte = data[y * width + x]
'				Local layerColor:Int = (Int(255*(value<>0) * $1000000) + Int(value * $10000) + Int(value * $100) + Int(value))
				Local layerColor:Int = (Int((value<>0)*255 * $1000000) + Int(value * $10000) + Int(value * $100) + Int(value))
				pix.WritePixel(x, y, layerColor)
			Next
		Next
		return pix
	End Method

	Method ToPixmap:TPixmap(valueColor:SColor8)
		Local pix:TPixmap = CreatePixmap(self.width, self.height, PF_RGBA8888)
		pix.ClearPixels(0)
		For local x:Int = 0 until width
			For local y:Int = 0 until height
				Local value:Byte = data[y * width + x]
				pix.WritePixel(x, y, (Int((value<>0)*valueColor.a * $1000000) + Int(valueColor.r * $10000) + Int(valueColor.g * $100) + Int(valueColor.b)))
			Next
		Next
		return pix
	End Method
End Type



'Container to hold amount of a player's antennas broadcasting on specific
'spots/coordinates
Type TStationMapAntennaLayer
	Field data:Int[]
	Field width:Int
	Field height:Int
	'offset from density data origin
	Field offsetX:Int
	Field offsetY:Int
	'surface of a section or the map itself (wrapped in a type so
	'references can be reused)
	Field surfaceData:TStationMapSurfaceData
	
	
	'Method New()
	'	Throw "TStationMapAntennaLayer: Only use New(surfaceData, offsetX, offsetY)"
	'End Method


	Method New(surfaceData:TStationMapSurfaceData, offsetX:Int = 0, offsetY:Int = 0)
		self.surfaceData = surfaceData
		self.offsetX = offsetX
		self.offsetY = offsetY
		self.data = New Int[surfaceData.data.length]
		self.width = surfaceData.width
		self.height = surfaceData.height
	End Method


	Method _SetValue:Int(x:Int, y:Int, radius:Int, value:Int)
		'make coords local
		x :- offsetX
		y :- offsetY
		
		'stay within the section
		Local circleRectX:Int = Max(0, x - radius)
		Local circleRectY:Int = Max(0, y - radius)
		Local circleRectX2:Int = Min(x + radius, surfaceData.width-1)
		Local circleRectY2:Int = Min(y + radius, surfaceData.height-1)
		Local radiusSquared:Int = radius * radius
rem
		For Local posX:Int = circleRectX To circleRectX2
			For Local posY:Int = circleRectY To circleRectY2
				'left the circle?
				If CalculateDistanceSquared(posX - x, posY - y) > radiusSquared Then Continue
endrem
		For local posX:Int = circleRectX until circleRectX2
			'calculate height of the circle"slice"
			Local circleLocalX:Int = posX - x
			Local currentCircleH:Int = sqr(radiusSquared - circleLocalX * circleLocalX)

			For local posY:Int = Max(y - currentCircleH, circleRectY) until Min(y + currentCircleH, circleRectY2)

				'If ((posX - x)*(posX - x) + (posY - y)*(posY - y)) > radiusSquared Then Continue

				'left the topographic borders ?
				If surfaceData.data[posY * width + posX] = 0 Then Continue

				data[posY * width + posX] :+ value
			Next
		Next
	End Method

	
	Method AddAntenna:Int(x:Int, y:Int, radius:Int)
		_SetValue(x, y, radius, +1)
	End Method


	Method RemoveAntenna:Int(x:Int, y:Int, radius:Int)
		_SetValue(x, y, radius, -1)
	End Method
	

	Method GetRemovedAntennaPopulation:Int(x:Int, y:Int, radius:Int, mapInfo:TStationMapInfo)
		'check how many points would go from 1 down to 0
		'as only values "inside" the topography/surfaceData will be > 1
		'we do not need to check for this part

		'make coords local
		x :- offsetX
		y :- offsetY
		
		'stay within the section
		Local circleRectX:Int = Max(0, x - radius)
		Local circleRectY:Int = Max(0, y - radius)
		Local circleRectX2:Int = Min(x + radius, surfaceData.width-1)
		Local circleRectY2:Int = Min(y + radius, surfaceData.height-1)
		Local radiusSquared:Int = radius * radius
		
		Local lostPopulation:Int = 0
rem
		For Local posX:Int = circleRectX To circleRectX2
			For Local posY:Int = circleRectY To circleRectY2
				'left the circle?
				If CalculateDistanceSquared(posX - x, posY - y) > radiusSquared Then Continue
endrem
		For local posX:Int = circleRectX until circleRectX2
			'calculate height of the circle"slice"
			Local circleLocalX:Int = posX - x
			Local currentCircleH:Int = sqr(radiusSquared - circleLocalX * circleLocalX)

			For local posY:Int = Max(y - currentCircleH, circleRectY) until Min(y + currentCircleH, circleRectY2)

				'If ((posX - x)*(posX - x) + (posY - y)*(posY - y)) > radiusSquared Then Continue

				If data[posY * width + posX] = 1
					'surface data is "somewhere" over the density data,
					'so ensure to adjust coordinates by offset
					lostPopulation :+ mapInfo.densityData.data[(posY + offsetY) * mapInfo.densityData.width + (posX + offsetX)]
				EndIf
			Next
		Next
		
		Return lostPopulation
	End Method
	

	Method GetAddedAntennaPopulation:Int(dataX:Int, dataY:Int, radius:Int, mapInfo:TStationMapInfo)
		'check how many points would go from 0 to 1
		'AND are inside the topography/surfaceData

		'make coords local
		dataX :- offsetX
		dataY :- offsetY
		
		'stay within the section
		Local circleRectX:Int = Max(0, dataX - radius)
		Local circleRectY:Int = Max(0, dataY - radius)
		Local circleRectX2:Int = Min(dataX + radius, surfaceData.width-1)
		Local circleRectY2:Int = Min(dataY + radius, surfaceData.height-1)
		Local radiusSquared:Int = radius * radius
		
		Local gainedPopulation:Int = 0
Rem
		For Local posX:Int = circleRectX To circleRectX2
			For Local posY:Int = circleRectY To circleRectY2
				'left the circle?
				If CalculateDistanceSquared(posX - dataX, posY - dataY) > radiusSquared Then Continue
EndRem
		For local posX:Int = circleRectX until circleRectX2
			'calculate height of the circle"slice"
			Local circleLocalX:Int = posX - dataX
			Local currentCircleH:Int = sqr(radiusSquared - circleLocalX * circleLocalX)

			For local posY:Int = Max(dataY - currentCircleH, circleRectY) until Min(dataY + currentCircleH, circleRectY2)

				'If ((posX - x)*(posX - x) + (posY - y)*(posY - y)) > radiusSquared Then Continue

				If data[posY * width + posX] = 0
					'check if inside topography
					If surfaceData.data[posY * surfaceData.width + posX] > 0
						'surface data is "somewhere" over the density data,
						'so ensure to adjust coordinates by offset
						gainedPopulation :+ mapInfo.densityData.data[(posY + offsetY) * mapInfo.densityData.width + (posX + offsetX)]
					EndIf
				EndIf
			Next
		Next
		
		Return gainedPopulation
	End Method


	Method ToPixmap:TPixmap(blackAndWhiteOnly:Int = False)
		Local pix:TPixmap = CreatePixmap(self.width, self.height, PF_RGBA8888)
		pix.ClearPixels(0)
		For local x:Int = 0 until width
			For local y:Int = 0 until height
				Local value:Byte = data[y * width + x]
'				Local layerColor:Int = (Int(255*(value<>0) * $1000000) + Int(value * $10000) + Int(value * $100) + Int(value))
				Local layerColor:Int = (Int((value<>0)*255 * $1000000) + Int(value * $10000) + Int(value * $100) + Int(value))
				if blackAndWhiteOnly Then layerColor = $ff000000 + $00ffffff*(value<>0)
				
				pix.WritePixel(x, y, layerColor)
			Next
		Next
		return pix
	End Method
End Type



Struct SChannelMask
	Field ReadOnly value:Int
	
	Method New(value:Int)
		Self.value = value
	End Method
	

	Method Set:SChannelMask(channelID:Int, enable:Int = True)
		If enable
			Return New SChannelMask( value | (1 Shl (channelID-1)) )
		Else
			Return New SChannelMask( value & ~(1 Shl (channelID-1)) )
		EndIf
	End Method
	

	Method Has:Int(channelID:Int)
		Return value & (1 Shl (channelID-1)) <> 0
	End Method


	'returns if none of the mask hits
	Method HasNone:Int(mask:Int)
		Return mask & value = 0
	End Method


	'return if at least one of the mask hits
	Method HasOne:Int(mask:Int)
		Return (mask & value) <> 0
	End Method


	Method HasAll:Int(mask:Int)
		Return (value & mask) = mask
	End Method


	Method Negated:SChannelMask()
		'ignore all channels > 8
		Return New SChannelMask( ~value & 255)
	End Method
	
	
	Method GetEnabledCount:Int()
		'counts bits set in the mask
		Local count:Int
		Local mask:Int = value
		
		While mask
			mask = mask & (mask - 1)
			count:+ 1
		Wend
		
		Return count
	End Method
	

	Method ToString:String()
		Local res:String
		For local i:int = 1 to 4
			if value & (1 Shl (i-1)) <> 0 'Has(i) 
				if res 
					res :+ ", " + i
				else
					res :+ i
				endif
			endif
		Next
				
		Return "(" + res + ")"
	End Method
End Struct
