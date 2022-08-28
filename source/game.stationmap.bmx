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
Import "game.player.difficulty.bmx"
Import "game.player.color.bmx"
Import "game.player.finance.bmx"
Import "game.publicimage.bmx"
Import "game.pressuregroup.bmx"
Import "basefunctions.bmx"
Import "common.misc.numericpairinterpolator.bmx"
Import "game.gameeventkeys.bmx"
Import "game.world.worldtime.bmx"



'parent of all stationmaps
Type TStationMapCollection
	Field sections:TStationMapSection[]
	'section name of all satellite uplinks
	Field satelliteUplinkSectionName:String

	'list of stationmaps
	Field stationMaps:TStationMap[0]
	Field antennaStationRadius:Int = ANTENNA_RADIUS_NOT_INITIALIZED
	Field population:Int = 0 'remove
	'satellites currently in orbit
	Field satellites:TList
	Field cableNetworks:TList
	'the original density map
	Field populationImageOriginalSprite:TSprite {nosave}
	Field populationImageOriginal:TImage {nosave}
	'the adjusted density map (only show "high pop"-areas)
	Field populationImageOverlay:TImage {nosave}
	Field populationImageSections:TImage {nosave}

	Field config:TData = New TData
	Field cityNames:TData = New TData
	Field sportsData:TData = New TData

	'when were last population/receiver-share-values measurements done?
	Field lastCensusTime:Long = -1
	Field nextCensusTime:Long = -1

	Field mapConfigFile:String = ""
	'caches
	Field _currentPopulationAntennaShare:Double = -1 {nosave}
	Field _currentPopulationCableShare:Double = -1 {nosave}
	Field _currentPopulationSatelliteShare:Double = -1 {nosave}
rem
	Field _sectionNames:String[] {nosave}
	Field _sectionISO3116Codes:String[] {nosave}
endrem
	'attention: the interpolation function hook is _not_ saved in the
	'           savegame
	'           So make sure to tackle this when saving share data!
	Field populationAntennaShareData:TNumericPairInterpolator {nosave}
	Field populationCableShareData:TNumericPairInterpolator {nosave}
	Field populationSatelliteShareData:TNumericPairInterpolator {nosave}


	'how people can receive your TV broadcast
	Global populationReceiverMode:Int = 2
	'Mode 1: they all receive via satellites, cable network and antenna
	'        if you covered all with satellites no antennas are needed
	'        100% with satellites = 100% with antenna
	Const RECEIVERMODE_SHARED:Int = 1
	'Mode 2: some receive via satellite, some via cable ...
	'        "populationCable|Satellite|AntennaShare" are used to describe
	'        how many percents of the population are reachable via cable,
	'        satellite, ...
	Const RECEIVERMODE_EXCLUSIVE:Int = 2
	Const ANTENNA_RADIUS_NOT_INITIALIZED:Int = -1

	'difference between screen0,0 and pixmap
	'->needed movement to have population-pixmap over country
	Global populationMapOffset:TVec2D = New TVec2D.Init(0, 0)
	Global _initDone:Int = False
	Global _instance:TStationMapCollection


	Method New()
		If Not _initDone
			'handle savegame loading (reload the map configuration)
			EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onSaveGameLoad)
			'handle <stationmapdata>-area in loaded xml files
			EventManager.registerListenerFunction(TRegistryLoader.eventKey_OnLoadResourceFromXML, onLoadStationMapData, Null, "STATIONMAPDATA")
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

		'optional:
		'stationMaps = new TStationMap[0]


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
rem
		_sectionNames = Null
		_sectionISO3116Codes = Null
endrem
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


		For Local stationMap:TStationMap = EachIn stationMaps
			stationMap.RecalculateAudienceSum()
		Next


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


	Method GetAntennaAudienceSum:Int(playerID:Int)
		Local result:Int
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaAudienceSum(playerID)
		Next
		Return result
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


	Method GetCableNetworkByGUID:TStationMap_CableNetwork(guid:String)
		For Local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			If cableNetwork.GetGUID() = guid Then Return cableNetwork
		Next

		Return Null
	End Method


	'summary: returns maximum audience reached with the given uplinks
	Method GetCableNetworkUplinkAudienceSum:Int(stations:TList)
		Local result:Int
		For Local station:TStationCableNetworkUplink = EachIn stations
			result :+ station.GetReach()
		Next
		Return result
	End Method


	Method GetCableNetworkUplinkAudienceSum:Int(playerID:Int)
		Local map:TStationMap = GetMap(playerID, False)
		If Not map Then Return 0
		Return GetCableNetworkUplinkAudienceSum(map.stations)
	End Method


	Method GetSatelliteUplinkAudienceSum:Int(stations:TList)
		Local result:Int
		For Local satLink:TStationSatelliteUplink = EachIn stations
			result :+ satLink.GetReach()
		'	result :+ satLink.GetExclusiveReach()
		Next
		Return result
	End Method


	Method GetSatelliteUplinkAudienceSum:Int(playerID:Int)
		Local map:TStationMap = GetMap(playerID, False)
		If Not map Then Return 0
		Return GetSatelliteUplinkAudienceSum(map.stations)
	End Method


	Method GetSatelliteCount:Int()
		Return satellites.Count()
	End Method


	Method GetSatelliteAtIndex:TStationMap_Satellite(index:Int)
		If satellites.count() <= index Or index < 0 Then Return Null

		Return TStationMap_Satellite( satellites.ValueAtIndex(index) )
	End Method


	Method GetSatelliteByGUID:TStationMap_Satellite(guid:String)
		For Local satellite:TStationMap_Satellite = EachIn satellites
			If satellite.GetGUID() = guid Then Return satellite
		Next

		Return Null
	End Method


	Method GetSatelliteIndexByGUID:Int(guid:String)
		Local i:Int = 0
		For Local satellite:TStationMap_Satellite = EachIn satellites
			i :+ 1
			If satellite.GetGUID() = guid Then Return i
		Next
		Return -1
	End Method


	Function GetSatelliteUplinksCount:Int(stations:TList, onlyActive:Int = False)
		Local result:Int
		For Local station:TStationSatelliteUplink = EachIn stations
			'skip inactive?
			if onlyActive and not station.IsActive() Then continue
			result :+ 1
		Next
		Return result
	End Function


	Function GetCableNetworkUplinksInSectionCount:Int(stations:TList, sectionName:String, onlyActive:Int = False)
		Local result:Int

		For Local station:TStationCableNetworkUplink = EachIn stations
			If station.GetSectionName() = sectionName
				'skip inactive?
				if onlyActive and not station.IsActive() Then continue
				result :+ 1
			EndIf
		Next
		Return result
	End Function


	Method GetTotalChannelExclusiveAudience:Int(channelNumber:Int)
		Local result:Int
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetExclusiveAntennaAudienceSum(channelNumber)
		Next
		Return result
	End Method


	Method GetTotalShareAudience:Int(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'return ".total" if you want to know what the "total amount" is
		'(so the sum of different people all "include channels" reach together)
		
		'return ".shared" if you want to know the population the 
		'"include channels" share between each other (exclusive to the 
		'excluded channels)
		Return GetTotalShare(includeChannelMask, excludeChannelMask).shared
	End Method


	Method GetTotalShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare

		If populationReceiverMode = RECEIVERMODE_SHARED
			Throw "GetTotalShare: Todo"

		ElseIf populationReceiverMode =  RECEIVERMODE_EXCLUSIVE

			'either
			'ATTENTION: contains only cable and antenna
			For Local section:TStationMapSection = EachIn sections
				result :+ section.GetReceiverShare(includeChannelMask, excludeChannelMask)
			Next
			'or:
			'result :+ GetTotalAntennaShare(channelNumbers, withoutChannelNumbers)
			'result :+ GetTotalCableNetworkShare(channelNumbers, withoutChannelNumbers)

			'add Satellite shares
			result :+ GetTotalSatelliteReceiverShare(includeChannelMask, excludeChannelMask)
		EndIf

		Return result
	End Method


	Method GetTotalAntennaReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaReceiverShare(includeChannelMask, excludeChannelMask)
		Next

		Return result
	End Method


	Method GetTotalCableNetworkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Local result:SStationMapPopulationShare
		For Local section:TStationMapSection = EachIn sections
			result :+ section.GetCableNetworkReceiverShare(includeChannelMask, excludeChannelMask)
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
				Local uplink:TStationSatelliteUplink = TStationSatelliteUplink( GetStationMap(channelID).GetSatelliteUplinkBySatellite(satellite) )
				If uplink and uplink.CanBroadcast()
					includedChannelsUsingThisSatellite :+ 1
				EndIf
			ElseIf excludeChannelMask.Has(channelID) And satellite.IsSubscribedChannel(channelID)
				Local uplink:TStationSatelliteUplink = TStationSatelliteUplink( GetStationMap(channelID).GetSatelliteUplinkBySatellite(satellite) )
				If uplink and uplink.CanBroadcast()
					excludedChannelsUsingThisSatellite :+ 1
				EndIf
			EndIf
		Next


		If includedChannelsUsingThisSatellite > 0
			Local reach:Int = satellite.GetReach()
			'total - if at least _one_ channel uses the satellite
			result.total = reach

			'all included channels need to have an uplink ("and" instead of "or" connection)
			If includedChannelsUsingThisSatellite = includeChannelMask.GetEnabledCount()
				'as soon as one "excluded" has an uplink there, we know
				'the "included" won't be exclusive
				'(with only 1 satellite you cannot only use 50% of it)
				If excludedChannelsUsingThisSatellite = 0
					result.shared = reach
				EndIf
			EndIf
		EndIf

		return result 
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetTotalSatelliteReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
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
				'check if other map sections have an opacque pixel there too (ambiguity!)
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

	'override
	Method GetSprite:TSprite()
		If Not populationImageOriginalSprite Then populationImageOriginalSprite = New TSprite.InitFromImage(populationImageOriginal, "populationImageOriginalSprite")
		Return populationImageOriginalSprite
	End Method


	Method CalculateTotalAntennaStationReach:Int(stationX:Int, stationY:Int, radius:Int = -1)
		Local result:Int = 0
		For Local section:TStationMapSection = EachIn sections
			result :+ section.CalculateAntennaStationReach(stationX, stationY, radius)
		Next
		Return result
	End Method


	Method CalculateTotalAntennaAudienceIncrease:Int(stations:TList, X:Int=-1000, Y:Int=-1000, radius:Int = -1)
		Local result:Int = 0
		For Local section:TStationMapSection = EachIn sections
			result :+ section.CalculateAntennaAudienceIncrease(stations, X, Y, radius)
		Next
		Return result
	End Method


	Method CalculateTotalAntennaAudienceDecrease:Int(stations:TList, station:TStationAntenna)
		Local result:Int = 0
		For Local section:TStationMapSection = EachIn sections
			result :+ section.CalculateAntennaAudienceDecrease(stations, station)
		Next
		Return result
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
			print "year="+y+"  antenna="+ Rset(MathHelper.NumberToString(a*100,1),5)+"%"+"  cable="+Rset(MathHelper.NumberToString(c*100,1),5)+"%"+"  satellite="+RSet(MathHelper.NumberToString(s,1),5)+"%"+ "   sum="+RSet(MathHelper.NumberToString(sum*100,1),6)+"%"
		Next
		end
		endrem

		Function YearTime:Long(year:Int)
'		return year
			Return GetWorldTime().MakeTime(year, 0, 0, 0, 0)
		End Function

		Return True
	End Method


	'=== EVENT HANDLERS ===

	'as soon as a station gets active (again), the sharemap has to get
	'regenerated (for a correct audience calculation)
	Function onSetStationActiveState:Int(triggerEvent:TEventBase)
		Local station:TStationBase = TStationBase(triggerEvent.GetSender())
		If Not station Then Return False

		'invalidate (cached) share data of surrounding sections
		For Local s:TStationMapSection = EachIn GetInstance().GetSectionsConnectedToStation(station)
			s.InvalidateData()
		Next

		'set the owning stationmap to "changed" so only this single
		'audience sum only gets recalculated (saves cpu time)
		GetInstance().GetMap(station.owner).reachInvalid = True
		
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

		_instance.LoadMapFromXML()

		'Ronny: no longer needed as recalculation is done automatically
		'       with a variable set to "false" on init.
		'maybe we got a borked up savegame which skipped recalculation
		'_instance.RecalculateMapAudienceSums(True)

		Local savedSaveGameVersion:Int = triggerEvent.GetData().GetInt("saved_savegame_version")
		'pre 0.7.2
		'contained a bug making antennas ignoring last col and last row of
		'population pixels
		If savedSaveGameVersion < 17
			TLogger.Log("TStationMapCollection", "Invalidating antenna reaches for enforced recalculation", LOG_DEBUG | LOG_SAVELOAD)
			'invalidate (cached) share data of surrounding sections
			For Local s:TStationMap = EachIn _instance.stationMaps
				For Local a:TStationAntenna = EachIn s.stations
					a.reachMax = -1
					a.reachExclusiveMax = -1
				Next
			Next
		EndIf
		'pre 0.7.3
		If savedSaveGameVersion < 18
			TLogger.Log("TStationMapCollection", "Ensuring initial cable network shares are set", LOG_DEBUG | LOG_SAVELOAD)
			For Local c:TStationMap_CableNetwork = EachIn _instance.cableNetworks
				c.populationShare = 1.0
			Next
		EndIf

		Return True
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
		registryLoader.LoadSingleResourceFromXML(densityNode, Null, True, New TData.AddString("name", "map_PopulationDensity"))
		registryLoader.LoadSingleResourceFromXML(surfaceNode, Null, True, New TData.AddString("name", "map_Surface"))

		'older savegames might contain a config which has the data converted
		'to key->value[] arrays instead of values being overridden on each load.
		'so better just clear the config
		_instance.config = New TData
		_instance.cityNames = New TData
		If sportsDataNode Then _instance.sportsData = New TData

		TXmlHelper.LoadAllValuesToData(configNode, _instance.config)
		TXmlHelper.LoadAllValuesToData(cityNamesNode, _instance.cityNames)
		If sportsDataNode
			TXmlHelper.LoadAllValuesToData(sportsDataNode, _instance.sportsData)
		EndIf

		'=== LOAD STATES ===
		'only if not done before
		'ATTENTION: overriding current sections will remove broadcast
		'           permissions as this is called _after_ a savegame
		'           got loaded!
		If _instance.sections.Length = 0
			'remove old states
			'_instance.ResetSections()

			'find and load states configuration
			Local statesNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "states")
			If Not statesNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <map><states>-area.")

			For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(statesNode)
				Local name:String	= TXmlHelper.FindValue(child, "name", "")
				Local iso3116Code:String = TXmlHelper.FindValue(child, "iso3116code", "")
				Local sprite:String	= TXmlHelper.FindValue(child, "sprite", "")
				Local pos:SVec2I	= New SVec2I( TXmlHelper.FindValueInt(child, "x", 0), TXmlHelper.FindValueInt(child, "y", 0) )

				Local pressureGroups:Int = TXmlHelper.FindValueInt(child, "pressureGroups", -1)
				Local sectionConfig:TData
				Local sectionConfigNode:TxmlNode = TXmlHelper.FindChild(child, "config")
				If sectionConfigNode
					sectionConfig = New TData
 					TXmlHelper.LoadAllValuesToData(sectionConfigNode, sectionConfig)
				EndIf
				'override config if pressureGroups are defined already
				If pressureGroups >= 0 Then sectionConfig.AddInt("pressureGroups", pressureGroups)

				'add state section if data is ok
				If name<>"" And sprite<>""
					_instance.AddSection( New TStationMapSection.Create(pos, name, iso3116Code, sprite, sectionConfig) )
				EndIf
			Next
			
			'calculate positions (now all sprites are loaded)
			For Local s:TStationMapSection = EachIn _instance.sections
				'validate if defined via XML
				If s.uplinkPos 
					If Not s.IsValidUplinkPos(s.uplinkPos.GetX(), s.uplinkPos.GetY())
						TLogger.Log("TStationMapCollection.onLoadStationMapData()", "Invalid / Ambiguous uplink position for state ~q" + s.name+"~q.", LOG_DEBUG)
						s.uplinkPos = Null
					EndIf
				EndIf
					
				s.GetLocalUplinkPos()
			Next
		Else
			'at least renew / fix properties written in the potentially
			'more current config file

			'find and load states configuration
			Local statesNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "states")
			If Not statesNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <map><states>-area.")

			For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(statesNode)
				Local name:String	= TXmlHelper.FindValue(child, "name", "")
				Local iso3116Code:String = TXmlHelper.FindValue(child, "iso3116code", "")

				local existingSection:TStationMapSection = _instance.GetSectionByName(name)
				If existingSection
					existingsection.iso3116Code = iso3116Code
				EndIf
			Next
		EndIf


		_instance.LoadPopulationShareData()

		'=== CREATE SATELLITES / CABLE NETWORKS ===
		If Not _instance.satellites Or _instance.satellites.Count() = 0 Then _instance.ResetSatellites()
		If Not _instance.cableNetworks Or _instance.cableNetworks.Count() = 0 Then _instance.ResetCableNetworks()

		Return True
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
		AssignPressureGroups()

		'dynamic antenna radius depending on start year (start antenna reach)
		Local map:TStationMap = GetStationMap(1, True)
		'coordinates from game.game.bmx PreparePlayerStep1
		Local station:TStationBase = map.GetTemporaryAntennaStation(310,260)
		If station And antennaStationRadius = ANTENNA_RADIUS_NOT_INITIALIZED
			antennaStationRadius = 50
			For Local r:Int = 20 To 50
				TStationAntenna(station).radius = r
				If station.getReach(True) > GameRules.stationInitialIntendedReach
					antennaStationRadius = r
					Exit
				EndIf
			Next
			If station.getReach(True) < GameRules.stationInitialIntendedReach
				'player will get cable, reduce station radius
				antennaStationRadius = 40
			EndIf
		EndIf

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
		Local pix:TPixmap = CreatePixmap(Int(srcPix.width + populationMapOffset.X), Int(srcPix.height + populationMapOffset.Y), srcPix.format)
		pix.ClearPixels(0)
		pix.paste(srcPix, Int(populationMapOffset.X), Int(populationMapOffset.Y))

		Local maxBrightnessPop:Int = TStationMapSection.GetPopulationForBrightness(0)
		Local minBrightnessPop:Int = TStationMapSection.GetPopulationForBrightness(255)

		'read all inhabitants of the map
		'normalize the population map so brightest becomes 255
		Local i:Int, j:Int, c:Int, s:Int = 0
		population = 0
		For j = 0 To pix.height-1
			For i = 0 To pix.width-1
				c = pix.ReadPixel(i, j)
				If ARGB_ALPHA(pix.ReadPixel(i, j)) = 0 Then Continue
				Local brightness:Int = ARGB_RED(c)
				Local pixelPopulation:Int = TStationMapSection.GetPopulationForBrightness( brightness )

				'store pixel with lower alpha for lower population
				'-20 is the base level to avoid colorization of "nothing"
				Local brightnessRate:Float = Min(1.0, 2 * pixelPopulation / Float(maxBrightnessPop))
				If brightnessRate < 0.1
					brightnessRate = 0
				Else
					brightnessRate :* (1.0 - brightness/255.0)
					brightnessRate = brightnessRate^0.25
				EndIf

				pix.WritePixel(i,j, ARGB_Color(Int(brightnessRate*255), Int((1.0-brightnessRate)*255), 0, 0))
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

		TLogger.Log("TGetStationMapCollection().AssignPressureGroups", "Assigned pressure groups to sections of the map not containing predefined ones.", LOG_DEBUG | LOG_LOADING)
	End Method


	Method Add:Int(map:TStationMap)
		'check boundaries
		If map.owner < 1 Then Return False

		'resize if needed
		If map.owner > stationMaps.Length Then stationMaps = stationMaps[ .. map.owner+1]

		'add to array array - zerobased
		stationMaps[map.owner-1] = map

		Return True
	End Method


	Method Remove:Int(map:TStationMap)
		'check boundaries
		If map.owner < 1 Or map.owner > stationMaps.Length Return False
		'remove from array - zero based
		stationMaps[map.owner-1] = Null

		'invalidate caches / antenna maps
		For Local section:TStationMapSection = EachIn sections
			section.InvalidateData()
			'pre-create data already
			section.GetAntennaShareGrid()
		Next

		Return True
	End Method


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
			nextCensusTime = GetWorldTime().Maketime(0, GetWorldTime().GetDay()+1, 0,0,0)
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


	Method GetPopulation:Int()
		Return population
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
		Local lastLaunchTime:Long = GetWorldTime().MakeTime(1983, 1,1, 0,0)
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

		Local satLink:TStationSatelliteUplink = TStationSatelliteUplink( map.GetSatelliteUplinkBySatellite(satellite) )
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

		Local lastLaunchTime:Long = GetWorldTime().MakeTime(1982, 1,1, 0,0)
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

		Local cableLink:TStationCableNetworkUplink = TStationCableNetworkUplink( map.GetCableNetworkUplinkStationByCableNetwork(cableNetwork) )
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

	Method GetSection:TStationMapSection(X:Int,Y:Int)
		For Local section:TStationMapSection = EachIn sections
			Local sprite:TSprite = section.GetShapeSprite()
			If Not sprite Then Continue

			If section.rect.containsXY(X,Y)
				If Not sprite._pix Then sprite._pix = sprite.GetPixmap()
				If PixelIsOpaque(sprite._pix, Int(X-section.rect.GetX()), Int(Y-section.rect.GetY())) > 0
					Return section
				EndIf
			EndIf
		Next

		Return Null
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
Rem
	Method GetSectionNames:String[]()
		If _sectionNames = Null
			_sectionNames = New String[ sections.Length ]
			For Local i:Int = 0 Until sections.Length
				_sectionNames[i] = sections[i].name.ToLower()
			Next
		EndIf

		Return _sectionNames
	End Method


	Method GetSectionISO3166Codes:String[]()
		If _sectionISO3116Codes = Null
			_sectionISO3116Codes = New String[ sections.Length ]
			For Local i:Int = 0 Until sections.Length
				_sectionISO3116Codes[i] = sections[i].iso3116Code.ToLower()
			Next
		EndIf

		Return _sectionISO3116Codes
	End Method
EndRem

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
	

	'returns sections "nearby" a station (connection not guaranteed as
	'check of a circle-antenna is based on two rects intersecting or not)
	Method GetSectionsConnectedToStation:TStationMapSection[](station:TStationBase)
		If Not station Then Return New TStationMapSection[0]

		'GetInstance()._regenerateMap = True
		If TStationAntenna(station)
			Local radius:Int = TStationAntenna(station).radius
			Local stationRect:TRectangle = New TRectangle.Init(station.X - radius, station.Y - radius, 2*radius, 2*radius)
			Local result:TStationMapSection[] = New TStationMapSection[sections.Length]
			Local added:Int = 0

			For Local section:TStationMapSection = EachIn sections
				If Not section.rect.IntersectRect(stationRect) Then Continue

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
			section.shapeSprite.Draw(section.rect.GetX(), section.rect.GetY())
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


	Method RemoveSectionFromPopulationSectionImage:Int(section:TStationMapSection)
		Local startX:Int = Int(Max(0, section.rect.GetX()))
		Local startY:Int = Int(Max(0, section.rect.GetY()))
		Local endX:Int = Int(Min(populationImageSections.width, section.rect.GetX2()))
		Local endY:Int = Int(Min(populationImageSections.height, section.rect.GetY2()))
		Local pix:TPixmap = LockImage(populationImageSections)
		Local emptyCol:Int = ARGB_Color(0, 0,0,0)

		Local sectionPix:TPixmap
		Local sprite:TSprite = section.GetShapeSprite()
		If Not sprite Then Return False
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()

		For Local X:Int = startX Until endX
			For Local Y:Int = startY Until endY
				If PixelIsOpaque(sprite._pix, Int(X-section.rect.GetX()), Int(Y-section.rect.GetY())) > 0
					pix.WritePixel(X,Y, emptyCol)
				EndIf
			Next
		Next

		Return True
	End Method


	Method CalculateSectionsPopulation:Int()
		'copy the original image - start with a "full population map"
		populationImageSections = LoadImage( LockImage(populationImageOriginal) )

		For Local section:TStationMapSection = EachIn sections
			section.GeneratePopulationImage(populationImageSections)
			section.CalculatePopulation()
			'remove the generated section population image from the map
			'population image
			RemoveSectionFromPopulationSectionImage(section)
		Next
		
		Return True
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




Type TStationMap Extends TOwnedGameObject {_exposeToLua="selected"}
	'select whose players stations we want to see
	Field showStations:Int[4]
	'and what types we want to show
	Field showStationTypes:Int[3]
	'maximum audience possible
	Field reach:Int = 0
	'audience reached before last change
	Field reachBefore:Int = 0
	'maximum audience reached in this game for now
	Field reachMax:Int = 0
	Field reachInvalid:Int = True {nosave}
	Field cheatedMaxReach:Int = False
	'all stations of the map owner
	Field stations:TList = CreateList()
	'amount of stations added per type
	Field stationsAdded:Int[4]
	Field sectionBroadcastPermissions:TMap

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
		stations.Clear()
		reachInvalid = True
		reach = 0
		reachBefore = 0
		reachMax = 0
		sectionBroadcastPermissions = New TMap
		showStations = [1,1,1,1]
		showStationTypes = [1,1,1]
		cheatedMaxReach = False
		stationsAdded = New Int[4]
		
		Return True
	End Method


	Method DoCensus()
		reachInvalid = True
		'refresh station reach
		For Local station:TStationBase = EachIn stations
			station.GetReach(True)
		Next
	End Method


	Method SetSectionBroadcastPermission:Int(sectionName:String, bool:Int=True )
		If Not sectionBroadcastPermissions Then sectionBroadcastPermissions = New TMap
		sectionBroadcastPermissions.Insert(sectionName, String(bool))
		
		Return True
	End Method


	Method GetSectionBroadcastPermission:Int(sectionName:String, bool:Int=True )
		If Not sectionBroadcastPermissions Then Return False
		Return Int(String(sectionBroadcastPermissions.ValueForKey(sectionName)))
	End Method


	'returns the maximum reach of the stations on that map
	Method GetReach:Int() {_exposeToLua}
		If reachInvalid Then RecalculateAudienceSum()

		Return Max(0, Self.reach)
	End Method


	Function GetReachLevel:Int(reach:Int)
		'put this into GameRules?
		If reach < 2500000
			Return 1
		ElseIf reach < 2500000 * 2 '5mio
			Return 2
		ElseIf reach < 2500000 * 5 '12,5 mio
			Return 3
		ElseIf reach < 2500000 * 9 '22,5 mio
			Return 4
		ElseIf reach < 2500000 * 14 '35 mio
			Return 5
		ElseIf reach < 2500000 * 20 '50 mio
			Return 6
		ElseIf reach < 2500000 * 28 '70 mio
			Return 7
		ElseIf reach < 2500000 * 40 '100 mio
			Return 8
		ElseIf reach < 2500000 * 60 '150 mio
			Return 9
		ElseIf reach < 2500000 * 100 '250 mio
			Return 10
		Else
			Return 11
		EndIf
	End Function


	Method GetCoverage:Float() {_exposeToLua}
		Return Float(GetReach()) / Float(GetStationMapCollection().getPopulation())
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryAntennaStation:TStationBase(X:Int, Y:Int)  {_exposeToLua}
		Local station:TStation = New TStation
		station.radius = GetStationMapCollection().antennaStationRadius

		Return station.Init(X, Y, -1, owner)
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryCableNetworkUplinkStation:TStationBase(cableNetworkIndex:Int)  {_exposeToLua}
		Return GetTemporaryCableNetworkUplinkStationByCableNetwork( GetStationMapCollection().GetCableNetworkAtIndex(cableNetworkIndex) )
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryCableNetworkUplinkStationByCableNetwork:TStationBase(cableNetwork:TStationMap_CableNetwork)
		If Not cableNetwork Or Not cableNetwork.launched Then Return Null
		Local station:TStationCableNetworkUplink = New TStationCableNetworkUplink

		station.providerGUID = cableNetwork.getGUID()

		Local mapSection:TStationMapSection = GetStationMapCollection().GetSectionByName(cableNetwork.sectionName)
		If Not mapSection Then Return Null

		Local stationPos:TVec2I = New TVec2I.CopyFrom(mapSection.rect.position).AddVec( mapSection.GetLocalUplinkPos() )
		station.Init(stationPos.X, stationPos.Y, -1, owner)
		station.SetSectionName(mapSection.name)
		station.SetSectionISO3116Code(mapSection.iso3116Code)
		'now we know how to calculate population
		station.RefreshData()
		
		Return station
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporarySatelliteUplinkStation:TStationBase(satelliteIndex:Int)  {_exposeToLua}
		Local station:TStationSatelliteUplink = New TStationSatelliteUplink
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteAtIndex(satelliteIndex)
		If Not satellite Or Not satellite.launched Then Return Null

		station.providerGUID = satellite.getGUID()

		'TODO: satellite positions ?
		Return station.Init(10,430 - satelliteIndex*50, -1, owner)
	End Method


	Method GetTemporarySatelliteUplinkStationBySatelliteGUID:TStationBase(satelliteGUID:String)  {_exposeToLua}
		Local station:TStationSatelliteUplink = New TStationSatelliteUplink
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		If Not satellite Or Not satellite.launched Then Return Null

		station.providerGUID = satellite.getGUID()

		'TODO: satellite positions
		'-> some satellites are foreign ones
		Local satelliteIndex:Int = GetStationMapCollection().GetSatelliteIndexByGUID(station.providerGUID)

		Return station.Init(10, 430 - satelliteIndex*50, -1, owner)
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
				If antenna.X <> X Or antenna.Y <> Y Then Continue
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
	Method GetStationsBySectionName:TStationBase[](sectionName:String, stationType:Int=0) {_exposeToLua}
		Local result:TStationBase[5]
		Local found:Int = 0 
		For Local station:TStationBase = EachIn stations
			If stationType >0 And station.stationType <> stationType Then Continue
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


	Method GetCableNetworkUplinkStationBySectionName:TStationBase(sectionName:String)
		For Local station:TStationBase = EachIn stations
			If station.stationType <> TVTStationType.CABLE_NETWORK_UPLINK Then Continue
			If station.GetSectionName() = sectionName Then Return station
		Next
		Return Null
	End Method


	Method GetCableNetworkUplinkStationByCableNetwork:TStationBase(cableNetwork:TStationMap_CableNetwork)
		For Local station:TStationCableNetworkUplink = EachIn stations
			If station.providerGUID = cableNetwork.GetGUID() Then Return station
		Next
		Return Null
	End Method


	Method GetSatelliteUplinkBySatellite:TStationBase(satellite:TStationMap_Satellite)
		For Local station:TStationSatelliteUplink = EachIn stations
			If station.providerGUID = satellite.GetGUID() Then Return station
		Next
		Return Null
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


	Method HasCableNetworkUplink:Int(station:TStationCableNetworkUplink)
		Return stations.contains(station)
'		For local s:TStationCableNetworkLink = EachIn stations
'			if s = station then return True
'		Next
'		return False
	End Method


	Method HasStation:Int(station:TStationBase)
		Return stations.contains(station)
	End Method


	Method GetRandomAntennaCoordinateOnMap:SVec2I(checkBroadcastPermission:Int=True, requiredBroadcastPermissionState:Int=True)
		Local X:Int = Rand(35, 560)
		Local Y:Int = Rand(1, 375)
		Local station:TStationBase = GetTemporaryAntennaStation(X, Y)
		If station.GetPrice() < 0 Then Return Null
		
		If checkBroadcastPermission And GetStationMapCollection().GetSection(X,Y).HasBroadcastPermission(owner, TVTStationType.ANTENNA) <> requiredBroadcastPermissionState Then Return Null
		 
		Return New SVec2I(X,Y)
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
		Local oldReachLevel:Int = GetReachLevel(GetReach())
		cheatedMaxReach = True
		reach = GetStationMapCollection().population

		For Local s:TStationMapSection = EachIn GetStationMapCollection().sections
			s.InvalidateData()
		Next

		If GetReachLevel(reach) <> oldReachLevel
			TriggerBaseEvent(GameEventKeys.StationMap_OnChangeReachLevel, New TData.addInt("reachLevel", GetReachLevel(reach)).AddInt("oldReachLevel", oldReachLevel), Self )
		EndIf

		Return True
	End Method


	Method CalculateTotalAntennaAudienceIncrease:Int(X:Int=-1000, Y:Int=-1000, radius:Int = -1)
		Return GetStationMapCollection().CalculateTotalAntennaAudienceIncrease(stations, X, Y, radius)
	End Method


	'returns maximum audience a player's stations cover
	Method RecalculateAudienceSum:Int() {_exposeToLua}
		'cannot simply call GetReach() because it can call RecalculateAudienceSum()
		'reachBefore = GetReach()
		reachBefore = self.reach

		If cheatedMaxReach
			reach = GetStationMapCollection().population
		Else
			If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
				Throw "RecalculateAudienceSum: Todo"
			ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
				reach =  GetStationMapCollection().GetAntennaAudienceSum(owner)
				reach :+ GetStationMapCollection().GetCableNetworkUplinkAudienceSum(stations)
				reach :+ GetStationMapCollection().GetSatelliteUplinkAudienceSum(stations)
				'print "RON: antenna["+owner+"]: " + GetStationMapCollection().GetAntennaAudienceSum(owner) + "   cable["+owner+"]: " + GetStationMapCollection().GetCableNetworkUplinkAudienceSum(stations) +"   satellite["+owner+"]: " + GetStationMapCollection().GetSatelliteUplinkAudienceSum(stations) + "   recalculated: " + reach
			EndIf
		EndIf

		reachMax = Max(reach, reachMax)
		'current reach is updated now
		reachInvalid = False

		'attention: this check only works as long as reaches cannot
		'stay the same but their "target group shares" change (so selling
		'a station where only men reside and buying one with only female
		'kids and seniors)
		If reachBefore <> reach
			'inform others about new audience reach
			TriggerBaseEvent(GameEventKeys.StationMap_OnRecalculateAudienceSum, New TData.AddInt("reach", reach).AddInt("reachBefore", reachBefore).AddInt("playerID", owner), Self )
			'inform others about a change of the reach level
			If GetReachLevel(reach) <> GetReachLevel(reachBefore)
				TriggerBaseEvent(GameEventKeys.StationMap_OnChangeReachLevel, New TData.AddInt("reachLevel", GetReachLevel(reach)).AddInt("oldReachLevel", GetReachLevel(reachBefore)), Self )
			EndIf
		EndIf

		Return reach
	End Method


	'returns additional audience when placing a station at the given coord
	Method CalculateAntennaAudienceIncrease:Int(X:Int, Y:Int, radius:Int = -1 ) {_exposeToLua}
		'LUA scripts pass a default radius of "0" if they do not pass a variable at all
		If radius <= 0 Then radius = GetStationMapCollection().antennaStationRadius
		Return GetStationMapCollection().CalculateTotalAntennaAudienceIncrease(stations, X, Y, radius)
	End Method


	'returns audience loss when selling a station at the given coord
	'param is station (not coords) to avoid ambiguity of multiple
	'stations at the same spot
	Method CalculateAntennaAudienceDecrease:Int(station:TStationAntenna) {_exposeToLua}
		Return GetStationMapCollection().CalculateTotalAntennaAudienceDecrease(stations, station)
	End Method


	'buy a new antenna station at the given coordinates
	Method BuyAntennaStation:Int(X:Int, Y:Int)
		Return AddStation( GetTemporaryAntennaStation( X, Y ), True )
	End Method


	'buy a new cable network station at the given coordinates
	Method BuyCableNetworkUplinkStationByMapSection:Int(mapSection:TStationMapSection)
		If Not mapSection Then Return False

		BuyCableNetworkUplinkStationBySectionName(mapSection.name)
	End Method


	'buy a new cable network station at the given coordinates
	Method BuyCableNetworkUplinkStationBySectionName:Int(sectionName:String, autoUpdateContract:Int = False)
		'find first cable network operating in that section
		Local index:Int = 0
		For Local cableNetwork:TStationMap_CableNetwork = EachIn GetStationMapCollection().cableNetworks
			If cableNetwork.sectionName = sectionName
				Local tmp:TStationBase = GetTemporaryCableNetworkUplinkStation( index )
				tmp.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT,autoUpdateContract)
				Return AddStation(tmp, True )
			EndIf
			index :+ 1
		Next
		Return False
	End Method


	'buy a new cable network link for the give cableNetwork
	Method BuyCableNetworkUplinkStation:Int(cableNetworkIndex:Int)
		Return AddStation( GetTemporaryCableNetworkUplinkStation( cableNetworkIndex ), True )
	End Method


	'buy a new satellite station at the given coordinates
	Method BuySatelliteUplinkStation:Int(satelliteIndex:Int, autoUpdateContract:Int = False)
		Local tmp:TStationBase = GetTemporarySatelliteUplinkStation( satelliteIndex )
		tmp.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT,autoUpdateContract)
		Return AddStation(tmp, True )
	End Method


	Method CanAddStation:Int(station:TStationBase)
		'only one network per section and player allowed
		If TStationCableNetworkUplink(station) And GetCableNetworkUplinkStationBySectionName(station.GetSectionName()) Then Return False

		'TODO: ask if the station is ok with it (eg. satlink asks satellite first)
		'for now:
		'only add sat links if station can subscribe to satellite
		Local provider:TStationMap_BroadcastProvider
		If TStationSatelliteUplink(station)
			provider = GetStationMapCollection().GetSatelliteByGUID(station.providerGUID)
			If Not provider Then Return False

		ElseIf TStationCableNetworkUplink(station)
			provider = GetStationMapCollection().GetCableNetworkByGUID(station.providerGUID)
			If Not provider Then Return False

		EndIf

		If provider
			If provider.IsSubscribedChannel(owner) Then Return False
			If provider.CanSubscribeChannel(owner, -1) <= 0 Then Return False
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
		TLogger.Log("TStationMap.AddStation", "Player"+owner+" buys broadcasting station ["+station.GetTypeName()+"] in section ~q" + station.GetSectionName() +"~q for " + station.price + " Euro (reach +" + station.GetReach(True) + ")", LOG_DEBUG)

		'sign potential contracts (= add connections)
		station.SignContract( -1 )

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

		If sell And Not station.sell() Then Return False

		stations.Remove(station)

		If sell
			TLogger.Log("TStationMap.RemoveStation", "Player "+owner+" sells broadcasting station for " + station.getSellPrice() + " Euro (had a reach of " + station.GetReach() + ")", LOG_DEBUG)
		Else
			TLogger.Log("TStationMap.RemoveStation", "Player "+owner+" trashes broadcasting station for 0 Euro (had a reach of " + station.GetReach() + ")", LOG_DEBUG)
		EndIf

		'cancel potential contracts (= remove connections)
		station.CancelContracts()

		'inform the station about the removal
		station.OnRemoveFromMap()


		'invalidate (cached) share data of surrounding sections
		For Local s:TStationMapSection = EachIn GetStationMapCollection().GetSectionsConnectedToStation(station)
			s.InvalidateData()
		Next
		'set the owning stationmap to "changed" so only this single
		'audience sum only gets recalculated (saves cpu time)
		reachInvalid = True

		'require recalculation
		RecalculateAudienceSum()

		'when station is sold, audience will decrease,
		'while a buy will not increase the current audience but the
		'next block (news or programme)
		'-> handled in main.bmx with a listener to "stationmap.removeStation"

		'emit an event so eg. network can recognize the change
		If fireEvents 
			TriggerBaseEvent(GameEventKeys.StationMap_RemoveStation, New TData.Add("station", station), Self)
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
		If reachInvalid Then RecalculateAudienceSum()

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
	'location at the station map
	'for satellites it is the "starting point", for cable networks and
	'antenna stations a point in the section / state
	Field X:Int {_exposeToLua="readonly"}
	Field Y:Int {_exposeToLua="readonly"}

	'audience reachable with current stationtype share
	Field reach:Int	= -1
	'maximum audience if all would use that type
	Field reachMax:Int = -1
	'reach of just this station without others in range
	Field reachExclusiveMax:Int = -1

	Field price:Int	= -1

	Field providerGUID:String {_exposeToLua}

	'daily costs for "running" the station
	Field runningCosts:Int = -1
	Field owner:Int = 0
	'time at which the station was bought
	Field built:Long = 0
	'time at which the station gets active (again)
	Field activationTime:Long = -1
	Field name:String = ""
	Field stationType:Int = 0
	Field _sectionName:String = "" {nosave}
	Field _sectionISO3116Code:String = "" {nosave}
	'various settings (paid, fixed price, sellable, active...)
	Field _flags:Int = 0

	Field listSpriteNameOn:String = "gfx_datasheet_icon_antenna.on"
	Field listSpriteNameOff:String = "gfx_datasheet_icon_antenna.off"


	Method Init:TStationBase( X:Int, Y:Int, price:Int=-1, owner:Int)
		Self.owner = owner
		Self.X = X
		Self.Y = Y

		Self.price = price
		Self.built = GetWorldTime().GetTimeGone()
		Self.activationTime = -1

		Self.SetFlag(TVTStationFlag.FIXED_PRICE, (price <> -1))
		'by default each station could get sold
		Self.SetFlag(TVTStationFlag.SELLABLE, True)

		Self.RefreshData()

		Return Self
	End Method


	Method GenerateGUID:String()
		Return "stationbase-"+id
	End Method


	'refresh the station data
	Method refreshData() {_exposeToLua}
		GetReach(True)
		GetExclusiveReach(True)
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


	'potentially reachable
	Method GetReachMax:Int(refresh:Int=False) Abstract {_exposeToLua}


	'get the reach of that station
	Method GetReach:Int(refresh:Int=False) Abstract {_exposeToLua}


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) Abstract {_exposeToLua}


	'get the relative reach increase of that station
	Method GetRelativeExclusiveReach:Float(refresh:Int=False) {_exposeToLua}
		Local r:Float = GetReach(refresh)
		If r = 0 Then Return 0

		Return GetExclusiveReach(refresh) / r
	End Method


	Method GetSectionName:String(refresh:Int=False) {_exposeToLua}
		If _sectionName <> "" And Not refresh Then Return _sectionName

		Local hoveredSection:TStationMapSection = GetStationMapCollection().GetSection(X, Y)
		If hoveredSection 
			_sectionName = hoveredSection.name
			_sectionISO3116Code = hoveredSection.iso3116Code
		EndIf

		Return _sectionName
	End Method


	Method GetSectionISO3166Code:String(refresh:Int=False) {_exposeToLua}
		If _sectionISO3116Code <> "" And Not refresh Then Return _sectionISO3116Code

		Local hoveredSection:TStationMapSection = GetStationMapCollection().GetSection(X, Y)
		If hoveredSection 
			_sectionName = hoveredSection.name
			_sectionISO3116Code = hoveredSection.iso3116Code
		EndIf

		Return _sectionISO3116Code
	End Method


	Method GetProvider:TStationMap_BroadcastProvider()
		If Not providerGUID Then Return Null
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


	Method RenewContract:Int(duration:Long)
		'reset warning state
		SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, False)

		Return True
	End Method


	Method CanSignContract:Int(duration:Long) {_exposeToLua}
		Return True
	End Method


	Method SignContract:Int(duration:Long)
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

		Local r:Int = GetReach()
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


	'override
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
				SetActivationTime( GetWorldTime().MakeTime(0, 0, GetWorldTime().GetHour(built) + constructionTime + 1, 0))
			'this hour (+construction hours) at xx:05
			Else
				SetActivationTime( GetWorldTime().MakeTime(0, 0, GetWorldTime().GetHour(built) + constructionTime, 5, 0))
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
					RenewContract( GetProvider().GetDefaultSubscribedChannelDuration() )
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


	Method SetSectionName:Int(sectionName:String)
		Self._sectionName = sectionName
	End Method


	Method SetSectionISO3116Code:Int(sectionISO3116Code:String)
		Self._sectionISO3116Code = sectionISO3116Code
	End Method


	Method CanSubscribeToProvider:Int(duration:Long)
		Return True
	End Method


	Method NextReachLevelProbable:Int(owner:Int, newStationReach:Int)
		Local stationMap:TStationMap = GetStationMap(owner)
		Local actualCurrentReach:Int = stationMap.GetReach()
		Local currTime:Long = GetWorldTime().GetTimeGone()
		'add up reach of all stations about to be built
		Local estimatedReachIncrease:Int = newStationReach
		For Local station:TStationBase = EachIn GetStationMap(owner).stations
			If Not station.isActive() And station.GetActivationTime() > currTime
				estimatedReachIncrease :+ station.getExclusiveReach()
			EndIf
		Next
		Return stationMap.GetReachLevel(actualCurrentReach) < stationMap.GetReachLevel(actualCurrentReach + estimatedReachIncrease)
	End Method


	Method DrawInfoTooltip()
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
		Local showPermissionPriceText:Int
		Local cantGetSectionPermissionReason:Int = 1
		Local cantGetProviderPermissionReason:Int = 1
		Local isNextReachLevelProbable:Int = False
		Local showPriceInformation:Int = False

		If Not HasFlag(TVTStationFlag.PAID)
			cantGetProviderPermissionReason = CanSubscribeToProvider(1)
			isNextReachLevelProbable = NextReachLevelProbable(owner, GetExclusiveReach())
			showPriceInformation = True

			If section And section.NeedsBroadcastPermission(owner, stationType)
				showPermissionPriceText = Not section.HasBroadcastPermission(owner, stationType)
				cantGetSectionPermissionReason = section.CanGetBroadcastPermission(owner)
			EndIf
		EndIf
			

		Local priceSplitH:Int = 8
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" ) - 2
		Local tooltipW:Int = 190
		Local tooltipH:Int = textH * 3 + 10 + 5

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

		If showPermissionPriceText > 0 Or cantGetSectionPermissionReason <= 0 Or isNextReachLevelProbable
			tooltipW :+ 40
		EndIf

		Local tooltipX:Int = X - tooltipW/2
		Local tooltipY:Int = Y - GetOverlayOffsetY() - tooltipH - 5

		'move below station if at screen top
		If tooltipY < 10 Then tooltipY = Y + GetOverlayOffsetY() + 5
		tooltipX = MathHelper.Clamp(tooltipX, 20, GetGraphicsManager().GetWidth() - tooltipW)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0
		
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local font:TBitmapFont = GetBitmapFontManager().baseFont

		Local textY:Int = tooltipY+5
		Local textX:Int = tooltipX+5
		Local textW:Int = tooltipW-10
		Local iso:String = GetSectionISO3166Code()
		fontBold.DrawSimple( GetLocale("MAP_COUNTRY_"+iso+"_LONG") + " (" + GetLocale("MAP_COUNTRY_"+iso+"_SHORT")+")", textX, textY, New SColor8(250,200,100), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH + 5

		font.Draw(GetLocale("REACH")+": ", textX, textY)
		fontBold.DrawBox(TFunctions.convertValue(GetReach(), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		textY:+ textH

		If stationType = TVTStationType.ANTENNA
			font.Draw(GetLocale("INCREASE")+": ", textX, textY)
			fontBold.DrawBox(TFunctions.convertValue(GetExclusiveReach(), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			textY:+ textH
		EndIf

		If GetConstructionTime() > 0
			font.Draw(GetLocale("CONSTRUCTION_TIME")+": ", textX, textY)
			fontBold.DrawBox(GetConstructionTime()+"h", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			textY:+ textH
		EndIf


		If cantGetSectionPermissionReason = -1
			font.Draw(GetLocale("CHANNEL_IMAGE")+" ("+GetLocale("STATIONMAP_SECTION_NAME")+"): ", textX, textY)
			fontBold.DrawBox(MathHelper.NumberToString(section.broadcastPermissionMinimumChannelImage,2)+" %", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,150,150))
			textY:+ textH
		EndIf
		If cantGetProviderPermissionReason = -1
			Local minImage:Float
			Local provider:TStationMap_BroadcastProvider = GetProvider()
			If provider Then minImage = provider.minimumChannelImage

			font.Draw(GetLocale("CHANNEL_IMAGE")+" ("+GetLocale("PROVIDER")+"): ", textX, textY)
			fontBold.DrawBox(MathHelper.NumberToString(minImage,2)+" %", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,150,150))
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
				fontBold.DrawBox(TFunctions.DottedValue(GetBuyPrice()) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
				textY:+ textH

				font.Draw(GetLocale("BROADCAST_PERMISSION")+": ", textX, textY)
				fontBold.DrawBox(TFunctions.DottedValue(section.GetBroadcastPermissionPrice(owner, stationType)) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
				textY:+ textH

				'always request the _current_ (refreshed) price
				totalPrice = GetStationMap(owner).GetTotalStationBuyPrice(Self)
			EndIf

			font.Draw(GetLocale("PRICE")+": ", textX, textY)
			If Not GetPlayerFinance(owner).CanAfford(totalPrice)
				fontBold.DrawBox(TFunctions.DottedValue(totalPrice) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255,150,150))
			Else
				fontBold.DrawBox(TFunctions.DottedValue(totalPrice) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			EndIf
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
		Local tooltipW:Int = textW + 10
		Local tooltipH:Int = textH * 2 + 10 + 5
		Local tooltipX:Int = X - tooltipW/2
		Local tooltipY:Int = Y - GetOverlayOffsetY() - tooltipH

		'move below station if at screen top
		If tooltipY < 20 Then tooltipY = Y + GetOverlayOffsetY() + 10 +10
		tooltipX = Max(20, tooltipX)
		tooltipX = Min(585 - tooltipW, tooltipX)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX, tooltipY, tooltipW, tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0

		Local textY:Int = tooltipY + 5
		Local textX:Int = tooltipX + 5
		GetBitmapFontManager().baseFontBold.DrawSimple(textCaption, textX, textY, New SColor8(255,190,80), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH + 5

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




'compatibility for now
'Todo: DEPRECATED, remove in v0.8 or later (last in use at 0.6)
Type TStation Extends TStationAntenna {_exposeToLua="selected"}
	Method Init:TStation(X:Int, Y:Int, price:Int=-1, owner:Int) Override
		Super.Init(X, Y, price, owner)
		Return Self
	End Method
End Type




Type TStationAntenna Extends TStationBase {_exposeToLua="selected"}
	Field radius:Int = 0 {_exposeToLua="readonly"}


	Method New()
		radius = GetStationMapCollection().antennaStationRadius

		stationType = TVTStationType.ANTENNA

		listSpriteNameOn = "gfx_datasheet_icon_antenna.on"
		listSpriteNameOff = "gfx_datasheet_icon_antenna.off"
	End Method


	Method Init:TStationAntenna(X:Int, Y:Int, price:Int=-1, owner:Int) Override
		Super.Init(X, Y, price, owner)
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


	Method GetRect:TRectangle()
		Return New TRectangle.Init(X - radius, Y - radius, 2*radius, 2*radius)
	End Method


	Method GetReachMax:Int(refresh:Int=False) Override {_exposeToLua}
		'not cached?
		If reachMax < 0 Or refresh
			reachMax = GetStationMapCollection().CalculateTotalAntennaStationReach(X, Y, radius)
			runningCosts = -1 'ensure running costs are calculated again
		EndIf
		Return reachMax
	End Method


	'reachable with current stationtype share
	Method GetReach:Int(refresh:Int=False) Override {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			Return GetReachMax(refresh)

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			'more exact approach (if SHARES DIFFER between sections) would be to
			'find split the area into all covered sections and calculate them
			'individually - then sum them up for the total reach amount

			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			If Not section Or section.populationAntennaShare < 0
				Return GetReachMax(refresh) * GetStationMapCollection().GetCurrentPopulationAntennaShare()
			Else
				Return GetReachMax(refresh) * section.populationAntennaShare
			EndIf
		EndIf

		Return GetReachMax(refresh)
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) Override {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			'as stations might broadcast to other sections too (crossing
			'borders) you cannot ignore stations in sections which are
			'covered by satellites/cable networks
			'so you will have to check _all_ covered sections

			'easiest approach: calculate reach "WITH - WITHOUT" station
			'TODO
			Throw "TStationAntenna.GetExclusiveReach() TODO"

			'not cached yet?
			If reachExclusiveMax < 0 Or refresh
				reachExclusiveMax = GetStationMap(owner).CalculateAntennaAudienceIncrease(X, Y, radius)
			EndIf

			Return reachExclusiveMax

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			'not cached yet?
			If reachExclusiveMax < 0 Or refresh
				If GetStationMap(owner).HasStation(Self)
					reachExclusiveMax = GetStationMap(owner).CalculateAntennaAudienceDecrease(Self)
				Else
					reachExclusiveMax = GetStationMap(owner).CalculateAntennaAudienceIncrease(X, Y, radius)
				EndIf
			EndIf

			'this is NOT correct - as the other sections (overlapping)
			'might have other antenna share values
			'-> better replace that once we settled to a specific
			'   variant - exclusive or not - and multiply with a individual
			'   receiverShare-Map for all the pixels covered by the antenna
			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			If Not section Or section.populationAntennaShare < 0
				Return reachExclusiveMax * GetStationMapCollection().GetCurrentPopulationAntennaShare()
			Else
				Return reachExclusiveMax * section.populationAntennaShare
			EndIf

			Return reachExclusiveMax
		EndIf

		Return reachExclusiveMax
	End Method

	'base price for buy price and maintenance costs
	'extracted in order to apply separate modifiers
	Method _BuyPriceBase:Int()
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

		Local buyPrice:Int = 0

		'construction costs
		If Not IsShutdown()
			Local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)
			'government-dependent costs
			'section specific costs for bought land + bureaucracy costs
			buyPrice :+ section.GetPropertyAquisitionCosts(TVTStationType.ANTENNA)
			'section government costs, changes over time (dynamic reach)
			buyPrice :+ 0.20 * GetReach(True)
			'government sympathy adjustments (-10% to +10%)
			'price :+ 0.1 * (-1 + 2*channelSympathy) * price
			buyPrice :* 1.0 + (0.1 * (1 - 2*channelSympathy))

			'fixed construction costs
			'building costs for "hardware" (more expensive than sat/cable)
			buyPrice :+ 0.20 * GetStationMapCollection().CalculateTotalAntennaStationReach(X, Y, 20)
		EndIf
		Return buyPrice
	End Method

	'override
	Method GetBuyPrice:Int() {_exposeToLua}
		Local buyPrice:Int = _BuyPriceBase()
		If buyPrice < 0 return buyPrice

		buyPrice :* GetPlayerDifficulty(owner).antennaBuyPriceMod
		'no further costs

		'round it to 25000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 25000)) * 25000 )

		Return buyPrice
	End Method


	'override
	Method GetCurrentRunningCosts:Int() {_exposeToLua}
		If HasFlag(TVTStationFlag.NO_RUNNING_COSTS) Then Return 0

		Local result:Int = 0
		Local difficulty:TPlayerDifficulty=GetPlayerDifficulty(owner)

		'== ADD STATIC RUNNING COSTS ==
		result :+ Ceil(_BuyPriceBase() / 5.0)
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


	'override
	Method GetOverlayOffsetY:Int()
		Return radius
	End Method


	Method Draw(selected:Int=False)
		Local sprite:TSprite = Null
		Local oldAlpha:Float = GetAlpha()

		If selected
			'white border around the colorized circle
			SetAlpha 0.25 * oldAlpha
			DrawOval(X - radius - 2, Y - radius -2, 2 * (radius + 2), 2 * (radius + 2))

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
		DrawOval(X - radius, Y - radius, 2 * radius, 2 * radius)
		color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
		DrawOval(X - radius + 2, Y - radius + 2, 2 * (radius - 2), 2 * (radius - 2))


		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(X, Y + 1, -1, ALIGN_CENTER_CENTER)
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


	Method Init:TStationCableNetworkUplink(X:Int, Y:Int, price:Int=-1, owner:Int) Override
		Super.Init(X, Y, price, owner)

		Return Self
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


	Method GetProvider:TStationMap_BroadcastProvider()
		If Not providerGUID Then Return Null
		Return GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
	End Method


	'override
	Method CanActivate:Int()
		Local provider:TStationMap_BroadcastProvider = GetProvider()
		If Not provider Then Return False

		If Not provider.IsLaunched() Then Return False
		If Not provider.IsSubscribedChannel(Self.owner) Then Return False

		Return True
	End Method


	Method RenewContract:Int(duration:Long)
		If Not providerGUID Then Return False 'Throw "Renew CableNetworkUplink without valid cable network guid."

		'inform cable network
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
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

		Return Super.RenewContract(duration)
	End Method


	Method CanSubscribeToProvider:Int(duration:Long)
		If Not providerGUID Then Return False

		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		If cableNetwork Then Return cableNetwork.CanSubscribeChannel(Self.owner, duration)

		Return True
	End Method


	'override to check if already subscribed
	Method CanSignContract:Int(duration:Long)  {_exposeToLua}
		If Not Super.CanSignContract(duration) Then Return False

		If CanSubscribeToProvider(duration) <= 0 Then Return False

		Return True
	End Method


	'override to add satellite connection
	Method SignContract:Int(duration:Long)
		If Not providerGUID Then Throw "Sign to CableNetworkLink without valid cable network guid."
		If Not CanSignContract(duration) Then Return False

		'inform cable network
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		If cableNetwork
			If duration < 0 Then duration = cableNetwork.GetDefaultSubscribedChannelDuration()
			If Not cableNetwork.SubscribeChannel(Self.owner, duration )
				Return False
			EndIf
		EndIf

		Return Super.SignContract(duration)
	End Method


	'override to remove satellite connection
	Method CancelContracts:Int()
		'inform cableNetwork
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		If cableNetwork
			If Not cableNetwork.UnsubscribeChannel(owner)
				Return False
			EndIf
		EndIf

		Return Super.CancelContracts()
	End Method


	Method GetSubscriptionTimeLeft:Long()
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		If Not cableNetwork Then Return 0

		Local endTime:Long = cableNetwork.GetSubscribedChannelEndTime(owner)
		If endTime < 0 Then Return 0

		Return endTime - GetWorldTime().GetTimeGone()
	End Method


	Method GetSubscriptionProgress:Float()
		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		If Not cableNetwork Then Return 0

		Local startTime:Long = cableNetwork.GetSubscribedChannelStartTime(owner)
		Local duration:Long = cableNetwork.GetSubscribedChannelDuration(owner)
		If duration < 0 Then Return 0

		Return MathHelper.Clamp(Float((GetworldTime().GetTimeGone() - startTime) / Double(duration)), 0.0, 1.0)
	End Method


	'override
	Method GetBuyPrice:Int() {_exposeToLua}
'		If price >= 0 And Not refresh Then Return price

		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
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
			buyPrice :+ 0.10 * GetReach(True)
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
		If providerGUID
			Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
			If cableNetwork
				result :+ cableNetwork.GetDailyFee(owner)
			EndIf
		EndIf

		'maintenance costs for the uplink to the cable network
		result :+ maintenanceCosts

		Result:* GetPlayerDifficulty(owner).cableNetworkDailyCostsMod
		return result
	End Method


	Method GetReachMax:Int(refresh:Int=False) Override {_exposeToLua}
		If reachMax <= 0 Or refresh
			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
			If section Then reachMax = section.GetPopulation()
		EndIf

		Return reachMax
	End Method


	Method GetReach:Int(refresh:Int=False) Override {_exposeToLua}
		'always return the uplinks' reach - so it stays dynamically
		'without the hassle of manual "cache refreshs"
		'If reach >= 0 And Not refresh Then Return reach

		Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		If Not cableNetwork Then Return 0

		Return cableNetwork.GetReach(refresh)
	End Method


	'reached audience not shared with other stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			'not cached yet?
			If reachExclusiveMax < 0 Or refresh
				Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
				If Not cableNetwork
					reachExclusiveMax = 0
					Return reachExclusiveMax
				EndIf

				'satellites
				'if a satellite covers the section, then no increase will happen
				If GetStationMap(owner).GetSatelliteUplinksCount()
					reachExclusiveMax = 0
					Return reachExclusiveMax
				EndIf
				'cable networks
				'if there is another cable network covering the same section,
				'then no increase will happen
				'if reach is calculated for self while already added,
				'check if another is existing too
				Local cableNetworks:Int = GetStationMap(owner).GetCableNetworkUplinksInSectionCount(GetSectionName())
				If GetStationMap(owner).HasCableNetworkUplink(Self) And cableNetworks > 1
					reachExclusiveMax = 0
					Return reachExclusiveMax
				ElseIf cableNetworks > 0
					reachExclusiveMax = 0
					Return reachExclusiveMax
				EndIf

				reachExclusiveMax = cableNetwork.GetReach()

				'subtract section population for all antennas in that area
				Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
				reachExclusiveMax :- section.GetAntennaAudienceSum( owner )
			EndIf

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
			If Not cableNetwork
				reachExclusiveMax = 0
			Else
				reachExclusiveMax = cableNetwork.GetReach(refresh)
			EndIf
		EndIf

		Return reachExclusiveMax
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
				DrawImage(section.GetSelectedImage(), section.rect.GetX(), section.rect.GetY())

				SetAlpha Float(0.2 * Sin(Time.GetAppTimeGone()/4) * oldA) + 0.3
				SetBlend LightBlend
				section.GetHighlightBorderSprite().Draw(section.rect.GetX(), section.rect.GetY())
				SetColor(oldCol)
				SetAlpha(oldA)
				SetBlend AlphaBlend
			EndIf

			If hovered
				'SetAlpha Float(0.3 * Sin(Time.GetAppTimeGone()/4) * oldColor.a) + 0.15
				SetColor 255,255,255
				SetAlpha 0.15
				SetBlend LightBlend
				DrawImage(section.GetHoveredImage(), section.rect.GetX(), section.rect.GetY())

				SetAlpha 0.4
				SetBlend LightBlend
				section.GetHighlightBorderSprite().Draw(section.rect.GetX(), section.rect.GetY())
				SetColor(oldCol)
				SetAlpha(oldA)
				SetBlend AlphaBlend
			EndIf
		Else
			SetAlpha oldA * 0.3
			color.SetRGB()
			'color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
			section.GetShapeSprite().Draw(section.rect.GetX(), section.rect.GetY())
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
		color.SetRGB()
		'TODO: section hervorheben
		color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
		'TODO: section hervorheben


		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(X, Y + 1, -1, ALIGN_CENTER_CENTER)
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


	Method Init:TStationSatelliteUplink(X:Int, Y:Int, price:Int=-1, owner:Int) Override
		Super.Init(X, Y, price, owner)

		Return Self
	End Method


	'override
	Method GenerateGUID:String()
		Return "station-satellite-uplink-"+id
	End Method


	'override
	Method GetLongName:String() {_exposeToLua}
		If Not providerGUID
			Return GetLocale("UNUSED_TRANSMITTER")
		Else
			Return GetName()
		EndIf
'		if GetName() then return GetTypeName() + " " + GetName()
'		return GetTypeName()
	End Method


	'override
	Method GetName:String() {_exposeToLua}
		If providerGUID
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
			If satellite Then Return GetLocale("SATUPLINK_TO_X").Replace("%X%", satellite.name)
		EndIf
		Return Super.GetName()
	End Method


	'override
	Method GetTypeName:String() {_exposeToLua}
		Return GetLocale("SATELLITE_UPLINK")
	End Method


	Method GetProvider:TStationMap_BroadcastProvider()
		If Not providerGUID Then Return Null
		Return GetStationMapCollection().GetSatelliteByGUID(providerGUID)
	End Method


	'override
	Method CanActivate:Int()
		Local provider:TStationMap_BroadcastProvider = GetProvider()
		If Not provider Then Return False

		If Not provider.IsLaunched() Then Return False
		If Not provider.IsSubscribedChannel(Self.owner) Then Return False

		Return True
	End Method


	Method RenewContract:Int(duration:Long)
		If Not providerGUID Then Return False 'Throw "Renew a Satellitelink to map without valid satellite guid."

		'inform satellite
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
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

		Return Super.RenewContract(duration)
	End Method


	Method CanSubscribeToProvider:Int(duration:Long)
		If Not providerGUID Then Return False

		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		If satellite Then Return satellite.CanSubscribeChannel(Self.owner, duration)

		Return True
	End Method


	'override to check if already subscribed
	Method CanSignContract:Int(duration:Long) {_exposeToLua}
		If Not Super.CanSignContract(duration) Then Return False

		If CanSubscribeToProvider(duration) <= 0 Then Return False

		Return True
	End Method


	'override to add satellite connection
	Method SignContract:Int(duration:Long)
		If Not providerGUID Then Throw "Signing a Satellitelink to map without valid satellite guid."
		If Not CanSignContract(duration) Then Return False

		'inform satellite
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		If satellite
			If duration < 0 Then duration = satellite.GetDefaultSubscribedChannelDuration()
			If Not satellite.SubscribeChannel(Self.owner, duration )
				TLogger.Log("TStationSatelliteUplink.SignContract()", "Failed to subscribe to channel.", LOG_ERROR)
			EndIf
		EndIf

		If IsShutDown() Then Resume()

		Return Super.SignContract(duration)
	End Method


	'override to remove satellite connection
	Method CancelContracts:Int()
		'inform satellite
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		If satellite
			satellite.UnsubscribeChannel(owner)
		EndIf

		Return Super.CancelContracts()
	End Method


	Method GetSubscriptionTimeLeft:Long()
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		If Not satellite Then Return 0

		Local endTime:Long = satellite.GetSubscribedChannelEndTime(owner)
		If endTime < 0 Then Return 0

		Return endTime - GetWorldTime().GetTimeGone()
	End Method


	Method GetSubscriptionProgress:Float()
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
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
		If providerGUID
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
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
		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
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
			'section government costs, changes over time (dynamic reach)
			buyPrice :+ 0.10 * GetReach(True)
			'government sympathy adjustments (-10% to +10%)
			'buyPrice :+ 0.1 * (-1 + 2*channelSympathy) * price
			buyPrice :* 1.0 + (0.1 * (1 - 2*channelSympathy))

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


	Method GetReachMax:Int(refresh:Int=False) Override {_exposeToLua}
		If reachMax < 0 Or refresh
			reachMax = GetStationMapCollection().GetPopulation()
		EndIf

		Return reachMax
	End Method


	Method GetReach:Int(refresh:Int=False) Override {_exposeToLua}
		'always return the satellite's reach - so it stays dynamically
		'without the hassle of manual "cache refreshs"
		'If reach >= 0 And Not refresh Then Return reach

		Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		If Not satellite Then Return 0

		Return satellite.GetReach()
	End Method


	'reached audience not shared with other stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) Override {_exposeToLua}
		'not cached yet?
		If reachExclusiveMax < 0 Or refresh
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
			If Not satellite
				reachExclusiveMax = 0
			Else
				reachExclusiveMax = satellite.GetExclusiveReach()
			EndIf
		EndIf
		Return reachExclusiveMax
	End Method


	Method Draw(selected:Int=False)
		'For now sat links are invisble
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
	Field iso3116code:String
	Field populationImage:TImage {nosave}
	Field populationMap:Int[,] {nosave}
	Field population:Int = -1
	Field populationCableShare:Float = -1
	Field populationSatelliteShare:Float = -1
	Field populationAntennaShare:Float = -1
	'grid/array/mapmap containing bitmask-coded information for "used" pixels
	Field antennaShareGrid:Byte[] = Null {nosave}
	Field antennaShareGridValid:Int = False {nosave}
	Field antennaShareGridWidth:Int {nosave}
	Field antennaShareGridHeight:Int {nosave}
	'Field antennaShareMapImage:TImage {nosave}
	Field shareCache:TStringMap = New TStringMap {nosave}
	Field calculationMutex:TMutex = CreateMutex() {nosave}
	Field shareCacheMutex:TMutex = CreateMutex() {nosave}
	Field antennaShareMutex:TMutex = CreateMutex() {nosave}


	Method New()
		channelSympathy = New Float[4]
		broadcastPermissionsGiven = New Int[4]
	End Method


	Method Create:TStationMapSection(pos:SVec2I, name:String, iso3116code:String, shapeSpriteName:String, config:TData = Null)
		Self.shapeSpriteName = shapeSpriteName
		Self.rect = New TRectangle.Init(pos.X, pos.Y, 0, 0)
		Self.name = name
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


	Method InvalidateData()
		LockMutex(shareCacheMutex)
			shareCache = New TStringMap
		UnlockMutex(shareCacheMutex)
		
		LockMutex(antennaShareMutex)
			'we could simply assign a new grid - or iterate over all
			'fields and set them to 0
			'For local i:int = 0 until (antennaShareGridWidth * antennaShareGridHeight)
			'	antennaShareGrid[i] = 0
			'Next
			'antennaShareGrid = new Byte[antennaShareGrid.length]
			antennaShareGridValid = False
		UnlockMutex(antennaShareMutex)
	End Method
	


	Method LoadShapeSprite()
		shapeSprite = GetSpriteFromRegistry(shapeSpriteName)
		'resize rect
		rect.dimension.SetXY(shapeSprite.area.GetW(), shapeSprite.area.GetH())
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
			Local sourcePix:TPixmap = LockImage(GetSpriteFromRegistry("map_Surface").GetImage())
			Local pix:TPixmap = ExtractPixmapFromPixmap(sourcePix, shapePix, rect.GetIntX(), rect.GetIntY())
			disabledOverlay = LoadImage( AdjustPixmapSaturation(pix, 0.20) )
			'disabledOverlay = ConvertToSingleColor( disabledOverlay, $FF999999 )
		EndIf
		Return disabledOverlay
	End Method


	Method GetEnabledOverlay:TImage()
		If Not enabledOverlay
			Local shapePix:TPixmap = LockImage(GetShapeSprite().GetImage())
			Local sourcePix:TPixmap = LockImage(GetSpriteFromRegistry("map_Surface").GetImage())
			Local pix:TPixmap = ExtractPixmapFromPixmap(sourcePix, shapePix, rect.GetIntX(), rect.GetIntY())
			enabledOverlay = LoadImage( pix )
		EndIf
		Return enabledOverlay
	End Method
	
	
	Method IsValidUplinkPos:Int(localX:Int, localY:Int)
		Local mapX:Int = rect.GetX() + localX 
		Local mapY:Int = rect.GetY() + localY
		Local IsValid:Int = False

		Local sprite:TSprite = GetShapeSprite()
		If Not sprite Then Return False
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()

		'check if that spot collides with another state
		If PixelIsOpaque(sprite._pix, localX, localy)
			IsValid = True

			For Local otherSection:TStationMapSection = EachIn GetStationMapCollection().sections
				If Self = otherSection Then Continue

				Local otherLocalX:Int = mapX - otherSection.rect.GetX()
				Local otherLocalY:Int = mapY - otherSection.rect.GetY()
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
	
	
	Method GetLocalUplinkPos:TVec2I()
		If Not uplinkPos
			'try center of section first
			Local localX:Int = rect.GetXCenter() - rect.GetX()
			Local localY:Int = rect.GetYCenter() - rect.GetY()
			'check if that spot collides with another state
			If Not IsValidUplinkPos(localX, localY)
				Local mapPos:SVec2I = GetStationMapCollection().GetRandomAntennaCoordinateInSection(Self, False)
				'make local position
				uplinkPos = New TVec2I(mapPos.X - rect.position.GetIntX(), mapPos.Y - rect.position.GetIntY())
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
		If stationType = TVTStationType.ANTENNA And GetStationMapCollection().antennaStationRadius >= 32
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
		Local tooltipW:Int = 190
		Local tooltipH:Int = textH * 4 + 10 + 5
		Local tooltipX:Int = MouseManager.X - tooltipW/2
		Local tooltipY:Int = MouseManager.Y - tooltipH - 5
'		Local tooltipX:Int = rect.GetXCenter() - tooltipW/2
'		Local tooltipY:Int = rect.GetYCenter() - tooltipH - 5


		Local permissionOK:Int = Not NeedsBroadcastPermission(channelID, stationType) Or HasBroadcastPermission(channelID, stationType)
		Local imageOK:Int = ReachesMinimumChannelImage(channelID)
		Local providerOK:Int = GetStationMapCollection().GetCableNetworksInSectionCount(Self.name, True) > 0

		'move below station if at screen top
		If tooltipY < 10 Then tooltipY = MouseManager.Y + 25
'		If tooltipY < 10 Then tooltipY = 10
		tooltipX = MathHelper.Clamp(tooltipX, 20, GetGraphicsManager().GetWidth() - tooltipW - 20)

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()

		SetAlpha oldA * 0.5
		If Not providerOK Or Not permissionOK Or Not imageOK
			SetColor 75,0,0
		Else
			SetColor 0,0,0
		EndIf
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor(oldCol)
		SetAlpha(oldA)

		Local textY:Int = tooltipY+5
		Local textX:Int = tooltipX+5
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
			fontBold.DrawBox(MathHelper.NumberToString(GetPublicImage(channelID).GetAverageImage(), 2)+"% < "+MathHelper.NumberToString(broadcastPermissionMinimumChannelImage, 2)+"%", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, New SColor8(255, 150, 150))
		Else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		EndIf
		textY:+ textH
	End Method


	Method GeneratePopulationImage:Int(sourcePopulationImage:TImage)
		Local startX:Int = Int(Max(0, rect.GetX()))
		Local startY:Int = Int(Max(0, rect.GetY()))
		Local endX:Int = Int(Min(sourcePopulationImage.width, rect.GetX2()))
		Local endY:Int = Int(Min(sourcePopulationImage.height, rect.GetY2()))
		Local sourcePix:TPixmap = LockImage(sourcePopulationImage)

		If Not populationImage Then populationImage = LoadImage( CreatePixmap(rect.GetIntW(), rect.GetIntH(), sourcePix.format) )
		Local pix:TPixmap = LockImage(populationImage)
		pix.ClearPixels(0)

		Local sectionPix:TPixmap
		Local sprite:TSprite = GetShapeSprite()
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()

		'copy whats left on the sections image
		For Local X:Int = startX Until endX
			For Local Y:Int = startY Until endY
				If PixelIsOpaque(sprite._pix, Int(X-rect.GetX()), Int(Y-rect.GetY())) > 0
					pix.WritePixel(Int(X-rect.GetX()), Int(Y-rect.GetY()), sourcePix.ReadPixel(X, Y) )
				EndIf
			Next
		Next
	End Method


	Method CalculatePopulation:Int()
'		If not TryLockMutex(calculationMutex)
'			Notify "CalculatePopulation: concurrent access found!"
			LockMutex(calculationMutex)
'		EndIf

		populationMap = New Int[populationImage.width, populationImage.height]

		'generate map out of the populationImage
		'and also sum up population
		population = 0
		Local pix:TPixmap = LockImage(populationImage)
		Local c:Int
		Local skipped:Int = 0
		For Local X:Int = 0 Until populationImage.width
			For Local Y:Int = 0 Until populationImage.height
				c = pix.ReadPixel(X, Y)
				If ARGB_ALPHA(pix.ReadPixel(X, Y)) = 0 Then Continue
				Local brightness:Int = ARGB_RED(c)
				populationMap[X, Y] = TStationMapSection.GetPopulationForBrightness( brightness )

				population :+ populationMap[X, Y]
			Next
		Next
		
		UnlockMutex(calculationMutex)
		
		Return population
	End Method


	Method GetPopulation:Int()
		If population < 0 Then CalculatePopulation()
		Return population
	End Method


	Private
	Function GeneratePositionKey:Long(X:Int, Y:Int)
		Return Long(X) Shl 32 | Long(Y)
	End Function
	Public


	'returns the shared amount of audience between channels
	Method GetShareAudience:Int(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetReceiverShare(includeChannelMask, excludeChannelMask).shared
	End Method


	Method GetPopulationCableShareRatio:Float()
		If populationCableShare < 0 Then Return GetStationMapCollection().GetCurrentPopulationCableShare()
		Return populationCableShare
	End Method

	Method GetPopulationAntennaShareRatio:Float()
		If populationAntennaShare < 0 Then Return GetStationMapCollection().GetCurrentPopulationAntennaShare()
		Return populationAntennaShare
	End Method

	Method GetPopulationSatelliteShareRatio:Float()
		If populationSatelliteShare < 0 Then Return GetStationMapCollection().GetCurrentPopulationSatelliteShare()
		Return populationSatelliteShare
	End Method


	'summary: returns maximum audience a player reaches with satellites
	'         in this section
	Method GetSatelliteAudienceSum:Int()
		Return population * GetPopulationSatelliteShareRatio()
	End Method


	'summary: returns maximum audience a player reaches with cable 
	'         networks in this section
	Method GetCableNetworkAudienceSum:Int()
		Return population * GetPopulationCableShareRatio()
	End Method


	'summary: returns maximum audience a player reaches with antennas
	Method GetAntennaAudienceSum:Int(playerID:Int)
		'passing only the playerID and no other playerIDs is returning
		'the playerID's audience (with share/total being useless)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = New SChannelMask()
		Return GetAntennaReceiverShare( includeChannelMask, excludeChannelMask ).total
	End Method


	Method GetExclusiveAntennaAudienceSum:Int(playerID:Int)
		Local includeChannelMask:SChannelMask = New SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = includeChannelMask.Negated()
		Return GetAntennaReceiverShare(includeChannelMask, excludeChannelMask).total
	End Method


	Method GetAntennaShareGrid:Byte[]()
		If Not antennaShareGridValid Or Not antennaShareGrid Or antennaShareGrid.Length = 0
			LockMutex(antennaShareMutex)

			antennaShareGrid = New Byte[populationImage.width * populationImage.height]
			antennaShareGridWidth = populationImage.width
			antennaShareGridHeight = populationImage.height

			Local antennaStationRadius:Int = GetStationMapCollection().antennaStationRadius
			Local antennaStationRadiusSquared:Int = antennaStationRadius * antennaStationRadius
			Local shapeSprite:TSprite = GetShapeSprite()
			If Not shapeSprite._pix Then shapeSprite._pix = shapeSprite.GetPixmap()
			Local circleRectX:Int, circleRectY:Int, circleRectX2:Int, circleRectY2:Int
			Local shareMask:TStationMapShareMask
			Local posX:Int = 0
			Local posY:Int = 0
			Local stationX:Int = 0
			Local stationY:Int = 0
			Local shareKey:Long
			For Local map:TStationMap = EachIn GetStationMapCollection().stationMaps
				'Local ownerMask:Byte = GetMaskIndex(map.owner)
				Local ownerMask:Byte = (1 Shl (map.owner-1))

				If map.cheatedMaxReach
					'insert the players bitmask-number into the field
					'and if there is already one ... add the number
					For posX = 0 To populationImage.width-1
						For posY = 0 To populationImage.height-1
							'left the topographic borders ?
							If Not PixelIsOpaque(shapeSprite._pix, posX, posY) > 0 Then Continue

							Local index:Int = posY * antennaShareGridWidth + posX
							'adjust mask
							antennaShareGrid[index] :| ownerMask
						Next
					Next
				Else

					'only handle antennas, no cable network/satellite!
					'For Local station:TStationBase = EachIn stationmap.stations
					For Local station:TStationAntenna = EachIn map.stations
						'skip inactive or shutdown stations
						If Not station.CanBroadcast() Then Continue
						
						'skip if outside
'						if station.pos.x + antennaStationRadius < rect.GetX() Then Continue
'						if station.pos.y + antennaStationRadius < rect.GetY() Then Continue
'						if station.pos.x - antennaStationRadius >= rect.GetX2() Then Continue
'						if station.pos.y - antennaStationRadius >= rect.GetY2() Then Continue

						'mark the area within the stations circle

						'local coordinate (within section)
						stationX = station.X - rect.GetX()
						stationY = station.Y - rect.GetY()

						'stay within the section
						circleRectX = Max(0, stationX - antennaStationRadius)
						circleRectY = Max(0, stationY - antennaStationRadius)
						circleRectX2 = Min(stationX + antennaStationRadius, rect.GetW()-1)
						circleRectY2 = Min(stationY + antennaStationRadius, rect.GetH()-1)

						For posX = circleRectX To circleRectX2
							For posY = circleRectY To circleRectY2
								'left the circle?
								If CalculateDistanceSquared( posX - stationX, posY - stationY ) > antennaStationRadiusSquared Then Continue
								'If ((posX - stationX)*(posX - stationX) + (posY - stationY)*(posY - stationY)) > antennaStationRadiusSquared Then Continue
								'left the topographic borders ?
								
								If Not PixelIsOpaque(shapeSprite._pix, posX, posY) > 0 Then Continue

								Local index:Int = posY * antennaShareGridWidth + posX
								antennaShareGrid[index] :| ownerMask
							Next
						Next
					Next
				EndIf
			Next

			antennaShareGridValid = True
			UnlockMutex(antennaShareMutex)
		EndIf
		Return antennaShareGrid
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

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			Throw "GetShare: TODO"
			'result.Add( GetMixedShare(channelMask) )
		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			result :+ GetAntennaReceiverShare(includeChannelMask, excludeChannelMask)
			result :+ GetCableNetworkReceiverShare(includeChannelMask, excludeChannelMask)
		EndIf
		Return result
	End Method


	Method GetCableNetworkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'no need to copy when not using a Type but a struct
		'Return GetCableNetworkPopulationShare(includeChannelMask, excludeChannelMask).Copy().MultiplyFactor(GetPopulationCableShareRatio())
		Return GetCableNetworkPopulationShare(includeChannelMask, excludeChannelMask).MultiplyFactor(GetPopulationCableShareRatio())
	End Method


	Method GetAntennaReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'no need to copy when not using a Type but a struct
		'Return GetAntennaPopulationShare(includeChannelMask, excludeChannelMask).Copy().MultiplyFactor(GetPopulationAntennaShareRatio())
		Return GetAntennaPopulationShare(includeChannelMask, excludeChannelMask).MultiplyFactor(GetPopulationAntennaShareRatio())
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
	Method GetCableNetworkPopulationShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		If includeChannelMask.value = 0 Then Return New SStationMapPopulationShare

		'=== CHECK CACHE ===
		'if already cached, save time...

		'== GENERATE KEY ==
		Local cacheKey:String = "cablenetwork"
		cacheKey :+ "_"+includeChannelMask.value
		cacheKey :+ "_"+excludeChannelMask.value
		
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
		If includeChannelMask.value = 0 Then Return New SStationMapPopulationShare

		Local result:TStationMapPopulationShare

		'=== CHECK CACHE ===
		'if already cached, save time...

		'== GENERATE KEY ==
		Local cacheKey:String = "antennas_"
		cacheKey :+ "_"+includeChannelMask.value
		cacheKey :+ "_"+excludeChannelMask.value

		'== LOAD CACHE ==
		If shareCache
			LockMutex(shareCacheMutex)
			result = TStationMapPopulationShare(shareCache.ValueForKey(cacheKey))
			UnlockMutex(shareCacheMutex)
		EndIf


		'== GENERATE CACHE ==
		If Not result
			result = New TStationMapPopulationShare

			Local shareGrid:Byte[] = GetAntennaShareGrid()
			LockMutex(antennaShareMutex) 'to savely iterate over values()
			For Local mapX:Int = 0 Until antennaShareGridWidth 
				For Local mapY:Int = 0 Until antennaShareGridHeight
					Local index:Int = mapY * antennaShareGridWidth + mapX
					Local mask:Byte = shareGrid[index]
					'skip if none of our interested is here
					If includeChannelMask.HasNone(mask) Then Continue
					'skip if one of the to exclude is here
					If Not excludeChannelMask.HasNone(mask) Then Continue

					'someone has a station there
					'-> check already done in the skip above
					'If ((mapMask.mask & includeChannelMask) <> 0)
						result.value.total :+ populationmap[mapX, mapY]
					'EndIf
					'all searched have a station there
					If (mask & includeChannelMask.value) = includeChannelMask.value
						result.value.shared :+ populationmap[mapX, mapY]
					EndIf
				Next
			Next
			UnlockMutex(antennaShareMutex)

			'store new cached data
			If shareCache
				LockMutex(shareCacheMutex)
				shareCache.insert(cacheKey, result )
				UnlockMutex(shareCacheMutex)
			EndIf

			'print "ANTENNA uncached: "+cacheKey
			'print "ANTENNA share:  total="+int(result.value.total)+"  share="+int(result.value.shared)
		Else
			'print "ANTENNA cached: "+cacheKey
			'print "ANTENNA share:  total="+int(result.value.total)+"  share="+int(result.value.shared)
		EndIf

		Return result.value
	End Method



	'params of advanced types (no ints, strings, bytes) are automatically
	'passed "by reference" (change it here, and it is changed globally)
	Method _FillAntennaPoints(map:TLongMap, stationX:Int, stationY:Int, radius:Int, color:Int)
		Local stationRect:TRectangle = New TRectangle.Init(stationX - radius, stationY - radius, 2*radius, 2*radius)
		'find minimal rectangle/intersection between section and station
		Local sectionStationIntersectRect:TRectangle = rect.IntersectRect(stationRect)
		'no intersection, nothing to do then?
		If Not sectionStationIntersectRect Then Return

		'convert world coordinate to local coords
		sectionStationIntersectRect.position.AddX( -rect.GetX() )
		sectionStationIntersectRect.position.AddY( -rect.GetY() )
		stationX :- rect.GetX()
		stationY :- rect.GetY()

		Local result:Int = 0
		Local radiusSquared:Int = radius * radius
		Local sprite:TSprite = GetShapeSprite()
		If Not sprite Then Return
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()

		For Local posX:Int = sectionStationIntersectRect.GetX() To sectionStationIntersectRect.getX2()
			For Local posY:Int = sectionStationIntersectRect.GetY() To sectionStationIntersectRect.getY2()
				'left the circle?
				If CalculateDistanceSquared( posX - stationX, posY - stationY ) > radiusSquared Then Continue
				'If CalculateDistance( posX - stationX, posY - stationY ) > radius Then Continue
				'left the topographic borders ?
				If Not PixelIsOpaque(sprite._pix, posX, posY) > 0 Then Continue

				map.Insert(GeneratePositionKey(posX, posY), New TStationMapAntennaPoint(posX , posY, color))
			Next
		Next
	End Method


	'summary: returns a stations maximum audience reach
	Method CalculateAntennaStationReach:Int(stationX:Int, stationY:Int, radius:Int = -1)
		If radius < 0 Then radius = GetStationMapCollection().antennaStationRadius

		'might be negative - if ending before the sections rect
		Local stationRect:TRectangle = New TRectangle.Init(stationX - radius, stationY - radius, 2*radius, 2*radius)
		'find minimal rectangle/intersection between section and station
		Local sectionStationIntersectRect:TRectangle = rect.IntersectRect(stationRect)
		'skip if section and station do not share a pixel
		If Not sectionStationIntersectRect Then Return 0

		'move world to local coords
		sectionStationIntersectRect.position.AddX( -rect.GetX() )
		sectionStationIntersectRect.position.AddY( -rect.GetY() )
		stationX :- rect.GetX()
		stationY :- rect.GetY()

Rem
print name
print "  rect: " + rect.ToString()
print "  stationRect: " + stationRect.ToString()
print "  sprite: " + GetShapeSprite().GetWidth()+","+GetShapeSprite().GetHeight()
print "  sectionStationIntersectRect: " + sectionStationIntersectRect.ToString()
endrem

		' calc sum for current coord
		Local result:Int = 0
		Local radiusSquared:Int = radius * radius
		Local sprite:TSprite = GetShapeSprite()
		If Not sprite Then Return 0
		If Not sprite._pix Then sprite._pix = sprite.GetPixmap()


		For Local posX:Int = sectionStationIntersectRect.GetX() To sectionStationIntersectRect.getX2()
			For Local posY:Int = sectionStationIntersectRect.GetY() To sectionStationIntersectRect.getY2()
				'left the circle?
				If CalculateDistanceSquared( posX - stationX, posY - stationY ) > radiusSquared Then Continue
				'If CalculateDistance( posX - stationX, posY - stationY ) > radius Then Continue
				'left the topographic borders ?
				If Not PixelIsOpaque(sprite._pix, posX, posY) > 0 Then Continue
				result :+ populationmap[posX, posY]
			Next
		Next

		Return result
	End Method


	Method CalculateAntennaAudienceDecrease:Int(stations:TList, removeStation:TStationAntenna)
		If Not removeStation Then Return 0
		'if station is not hitting the section
		If Not removeStation.GetRect().Intersects(rect) Then Return 0

		Local Points:TLongMap = New TLongMap
		Local result:Int = 0

		'mark the station points of the to remove as "2"
		'mark all others (except the given one) as "1"
		'-> then count on all spots still "2"

		Self._FillAntennaPoints(Points, Int(removeStation.X), Int(removeStation.Y), removeStation.radius, 2)

		'overwrite with stations owner already has (with value "1")
		'count points with value "2" at the end
		For Local station:TStationAntenna = EachIn stations
			'DO NOT SKIP INACTIVE/SHUTDOWN STATIONS !!
			'decreases are for estimations - so they should include
			'non-finished stations too
			'If Not station.CanBroadcast() Then Continue

			'exclude the station to remove...
			If station = removeStation Then Continue

			'skip antennas not overlapping the station to remove
			If Not station.GetRect().Intersects(removeStation.GetRect()) Then Continue

			Self._FillAntennaPoints(Points, Int(station.X), Int(station.Y), station.radius, 1)
		Next

		'count all "still 2" spots
		For Local point:TStationMapAntennaPoint = EachIn points.Values()
			If point.value = 2
				result :+ populationmap[point.X, point.Y]
			EndIf
		Next
		Return result
	End Method


	Method CalculateAntennaAudienceIncrease:Int(stations:TList, stationX:Int=-1000, stationY:Int=-1000, radius:Int = -1)
		If radius < 0 Then radius = GetStationMapCollection().antennaStationRadius
		If stationX = -1000 And stationY = -1000
			stationX = MouseManager.X
			stationY = MouseManager.Y
		EndIf


		'might be negative - if ending before the sections rect
		Local stationRect:TRectangle = New TRectangle.Init(stationX - radius, stationY - radius, 2*radius, 2*radius)
		'skip if section and station do not share a pixel
		If Not rect.Intersects(stationRect) Then Return 0


		Local Points:TLongMap = New TLongMap
		Local result:Int = 0

		'add "new" station which may be bought - mark points as ""
		Self._FillAntennaPoints(Points, stationX, stationY, radius, 2)

		'overwrite with stations owner already has (with value "1")
		'count points with value "2" at the end
		For Local station:TStationAntenna = EachIn stations
			'DO NOT SKIP INACTIVE/SHUTDOWN STATIONS !!
			'increases are for estimations - so they should include
			'non-finished stations too
			'If Not station.CanBroadcast() Then Continue

			'skip antennas outside of the section
			If Not station.GetRect().Intersects(rect) Then Continue

			'skip antennas not overlapping the station to add
			If Not station.GetRect().Intersects(stationRect) Then Continue

			Self._FillAntennaPoints(Points, Int(station.X), Int(station.Y), station.radius, 1)
		Next

		'all points still "2" are what will be added in addition to existing ones
		For Local point:TStationMapAntennaPoint = EachIn points.Values()
			If point.value = 2
				result :+ populationmap[point.X, point.Y]
			EndIf
		Next
		Return result
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


	'Function GetMaskIndex:Int(number:Int)
	'	Return 1 shl (number-1)
	'End Function
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

	Field exclusiveReach:Int = -1
	'potentially reachable Max
	Field reachMax:Int = -1

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


	Method CanSubscribeChannel:Int(channelID:Int, duration:Long=-1) {_exposeToLua}
		If minimumChannelImage > 0 And minimumChannelImage > GetPublicImage(channelID).GetAverageImage() Then Return -1
		If channelMax >= 0 And subscribedChannels.Length >= channelMax Then Return -2

		Return 1
	End Method


	Method SubscribeChannel:Int(channelID:Int, duration:Long, force:Int=False)
		If Not force And CanSubscribeChannel(channelID, duration) <> 1 Then Return False

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


	Method GetReach:Int(refresh:Int=False) {_exposeToLua}
		Return 0
	End Method


	Method GetSetupFee:Int(channelID:Int) {_exposeToLua}
		Local channelSympathy:Float = GetPressureGroupsChannelSympathy(channelID)
		Local price:Int

		price = setupFeeBase
		'add a cpm (costs per mille) approach - reach changes over time
		price :+ 0.25 * GetReach()/1000

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
		price :+ 0.10 * GetReach()

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
		For Local i:Int = 0 Until subscribedChannels.Length
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


	Method GetReachMax:Int(refresh:Int=False) {_exposeToLua}
		'not cached?
		If reachMax < 0 Or refresh
			If Not sectionName Then Return 0

			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
			If Not section Then Return 0

			reachMax = section.GetPopulation()
		EndIf
		Return reachMax
	End Method


	Method GetReach:Int(refresh:Int = False) {_exposeToLua}
		Local result:Int
		
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			result = GetReachMax()

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
			If Not section Then Return 0

			'this allows individual cablenetworkReceiveRatios for the
			'sections (eg bad infrastructure for cables or expensive)
			result = section.GetCableNetworkAudienceSum()
		EndIf
		
		'multiply with the percentage of users selecting THIS network
		'over other cable providers (eg only provider 1 offers it in the
		'city or street)
		result :* populationShare
		
		Return result
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
	'disabled: just assume they reach the whole country
	'the population reachable because of orbit position
	'Field populationImage:TImage {nosave}
	'Field populationMap:int[,] {nosave}

	'name without revision
	Field brandName:String

	Field nextImageReductionTime:Long = -1
	Field nextImageReductionValue:Float = 0.97
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


	Method GetReachMax:Int(refresh:Int=False) {_exposeToLua}
		'not cached?
		If reachMax < 0 Or refresh
			reachMax = GetStationMapCollection().GetPopulation()
		EndIf
		Return reachMax
	End Method


	Method GetReach:Int(refresh:Int = False) {_exposeToLua}
		Local result:Int

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			result = GetReachMax(refresh)

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			'sum up all sections
			'this allows individual satelliteReceiveRatios for the sections
			For Local s:TStationMapSection = EachIn GetStationMapCollection().sections
				result :+ s.GetSatelliteAudienceSum()
			Next
		EndIf

		'multiply with the percentage of users selecting THIS satellite
		'over other satellites (assume all satellites cover the complete
		'map)
		result :* populationShare

		Return result
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
'		If exclusiveReach >= 0 And Not refresh Then Return exclusiveReach

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			exclusiveReach = GetReach(refresh)

			'satellites
			'as only ONE sat could get received the same time, we can
			'ignore others

			'cable networks
			'TODO: subtract audiences _exclusive_ to antennas

			'antennas
			'TODO: subtract antennas
			Return exclusiveReach

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			exclusiveReach = GetReach(refresh)
		Else

			exclusiveReach = 0
		EndIf

		Return exclusiveReach
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
		TLogger.Log("Satellite.Launch", "Launching satellite ~q"+name+"~q. Reach: " + GetReach() +"  Date: " + GetWorldTime().GetFormattedGameDate(launchTime) +"  Death: " + GetWorldTime().GetFormattedGameDate(deathTime), LOG_DEBUG)

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


			If minimumChannelImage > 0.1 And nextImageReductionTime < GetWorldTime().GetTimeGone()
				If nextImageReductionTime > 0
					Local oldMinimumChannelImage:Float = minimumChannelImage
					minimumChannelImage :* nextImageReductionValue
					'avoid reducing very small values for ever and ever
 					If minimumChannelImage <= 0.1 Then minimumChannelImage = 0
					'inform others (eg. for news)
					TriggerBaseEvent(GameEventKeys.Satellite_OnReduceMinimumChannelImage, New TData.AddFloat("minimumChannelImage", minimumChannelImage).AddFloat("oldMinimumChannelImage", oldMinimumChannelImage), Self )
				EndIf

				nextImageReductionTime = GetWorldTime().ModifyTime(-1, 0, 0, Int(RandRange(20,30)))
				nextImageReductionValue = nextImageReductionValue^2
			EndIf
		EndIf
	End Method
End Type





Struct SChannelMask
	Field ReadOnly value:Int
	
	Method New(value:Int)
		Self.value = value
	End Method
	

	Method Set:SChannelMask(channelID:Int, enable:Int = True)
		'activate the bit for a given channelID
		'each channel corresponds to an index/position
		'id1 = mask 1, id2 = mask 2
		'id3 = mask 4, id4 = mask 8 ...

		Return New SChannelMask( value | (enable Shl (channelID-1)) )
	End Method
	

	Method Has:Int(channelID:Int)
		'each channel corresponds to an index/position
		'id1 = mask 1, id2 = mask 2
		'id3 = mask 4, id4 = mask 8 ...

		Return value & (1:Int Shl (channelID-1)) <> 0
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
		Return New SChannelMask( ~value )
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
			if Has(i) 
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
