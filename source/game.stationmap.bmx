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
Import "game.pressuregroup.bmx"
Import "basefunctions.bmx"
Import "common.misc.numericpairinterpolator.bmx"
Import "game.gameeventkeys.bmx"
Import "game.world.worldtime.bmx"



'parent of all stationmaps
Type TStationMapCollection
	Field sections:TStationMapSection[]
	'section name of all satellite uplinks
	Field satelliteUplinkSectionName:string

	'list of stationmaps
	Field stationMaps:TStationMap[0]
	Field antennaStationRadius:Int = ANTENNA_RADIUS_NOT_INITIALIZED
	Field population:int = 0 'remove
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

	'attention: the interpolation function hook is _not_ saved in the
	'           savegame
	'           So make sure to tackle this when saving share data!
	Field populationAntennaShareData:TNumericPairInterpolator {nosave}
	Field populationCableShareData:TNumericPairInterpolator {nosave}
	Field populationSatelliteShareData:TNumericPairInterpolator {nosave}


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
	Const ANTENNA_RADIUS_NOT_INITIALIZED:int = -1

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


		population:int = 0
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


	Method GetMapName:string()
		Return config.GetString("name", "UNKNOWN")
	End Method


	Method GetMapISO3166Code:string()
		Return config.GetString("iso3166code", "UNK")
	End Method


	'Percentage of receipients using an antenna
	'return a (cached) value of the current share
	Method GetCurrentPopulationAntennaShare:Double()
		if _currentPopulationAntennaShare < 0
			_currentPopulationAntennaShare = GetPopulationAntennaShare()
		endif
		return _currentPopulationAntennaShare
	End Method


	'Percentage of receipients using a cable network uplink
	'return a (cached) value of the current share
	Method GetCurrentPopulationCableShare:Double()
		if _currentPopulationCableShare < 0
			_currentPopulationCableShare = GetPopulationCableShare()
		endif
		return _currentPopulationCableShare
	End Method


	'Percentage of receipients using a satellite dish / uplink
	'return a (cached) value of the current share
	Method GetCurrentPopulationSatelliteShare:Double()
		if _currentPopulationSatelliteShare < 0
			_currentPopulationSatelliteShare = GetPopulationSatelliteShare()
		endif
		return _currentPopulationSatelliteShare
	End Method


	Method GetPopulationAntennaShare:Double(time:Long = -1)
		if not populationAntennaShareData then LoadPopulationShareData()

		if time = -1 then time = GetWorldTime().GetTimeGone()

		return populationAntennaShareData.GetInterpolatedValue( time )
	End Method


	Method GetPopulationCableShare:Double(time:Long = -1)
		if not populationCableShareData then LoadPopulationShareData()

		if time = -1 then time = GetWorldTime().GetTimeGone()

		return populationCableShareData.GetInterpolatedValue( time )
	End Method


	Method GetPopulationSatelliteShare:Double(time:Long = -1)
		if not populationSatelliteShareData then LoadPopulationShareData()

		if time = -1 then time = GetWorldTime().GetTimeGone()

		return populationSatelliteShareData.GetInterpolatedValue( time )
	End Method


	Method GetLastCensusTime:long()
		return lastCensusTime
	End Method


	Method GetNextCensusTime:long()
		return nextCensusTime
	End Method


	Method DoCensus()
		'reset caches
		_currentPopulationAntennaShare = -1
		_currentPopulationCableShare = -1
		_currentPopulationSatelliteShare = -1

		'generate cache if needed reach-values
		UpdateSections()

		For local section:TStationMapSection = EachIn sections
			section.DoCensus()
		Next

		For local stationMap:TStationMap = Eachin stationMaps
			stationMap.DoCensus()
		Next

		'also update shares (incorporate tech upgrades of satellites etc)
		UpdateCableNetworkSharesAndQuality()
		UpdateSatelliteSharesAndQuality()


		For local stationMap:TStationMap = Eachin stationMaps
			stationMap.RecalculateAudienceSum()
		Next


		'if no census was done, do as if it was done right on game start
		if lastCensusTime = -1
			lastCensusTime = GetWorldTime().GetTimeStart()
		else
			lastCensusTime = GetWorldTime().GetTimeGone()
		endif
	End Method


	Method GetAveragePopulationAntennaShare:Float()
		if not sections or sections.length = 0 then return 0

		local result:Float
		For local section:TStationMapSection = EachIn sections
			result :+ section.GetPopulationAntennaShareRatio()
			rem
			if section.populationAntennaShare < 0
				result :+ GetCurrentPopulationAntennaShare()
			else
				result :+ section.populationAntennaShare
			endif
			endrem
		Next
		return result / sections.length
	End Method


	Method GetAveragePopulationCableShare:Float()
		if not sections or sections.length = 0 then return 0

		local result:Float
		For local section:TStationMapSection = EachIn sections
			if section.populationCableShare < 0
				result :+ GetCurrentPopulationCableShare()
			else
				result :+ section.populationCableShare
			endif
		Next
		return result / sections.length
	End Method


	Method GetAveragePopulationSatelliteShare:Float()
		if not sections or sections.length = 0 then return 0

		local result:Float
		For local section:TStationMapSection = EachIn sections
			if section.populationSatelliteShare < 0
				result :+ GetCurrentPopulationSatelliteShare()
			else
				result :+ section.populationSatelliteShare
			endif
		Next
		return result / sections.length
	End Method


	Method GetSatelliteUplinkSectionName:string()
		if not satelliteUplinkSectionName
			If Not sections or sections.length = 0 Then Return ""

			local randomSection:TStationMapSection = TStationMapSection(sections[RandRange(0, sections.length-1)])
			if randomSection
				satelliteUplinkSectionName = randomSection.name
			endif
		endif
		return satelliteUplinkSectionName
	End Method


	Method GetAntennaAudienceSum:int(playerID:int)
		local result:int
		For local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaAudienceSum(playerID)
		Next
		return result
	End Method


	Method GetFirstCableNetworkBySectionName:TStationMap_CableNetwork(sectionName:string)
		if cableNetworks.count() = 0 then return Null

		for local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			if cableNetwork.sectionName = sectionName then return cableNetwork
		next

		return null
	End Method


	Method GetCableNetworksInSectionCount:int(sectionName:string, onlyLaunched:int=True)
		local result:int = 0

		for local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			if cableNetwork.sectionName = sectionName
				if not onlyLaunched or cableNetwork.IsLaunched() then result :+ 1
			endif
		next

		return result
	End Method


	Method GetCableNetworkCount:int()
		return cableNetworks.Count()
	End Method


	Method GetCableNetworkAtIndex:TStationMap_CableNetwork(index:int)
		if cableNetworks.count() <= index or index < 0 then return Null

		return TStationMap_CableNetwork( cableNetworks.ValueAtIndex(index) )
	End Method


	Method GetCableNetworkByGUID:TStationMap_CableNetwork(guid:string)
		For local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
			if cableNetwork.GetGUID() = guid then return cableNetwork
		Next

		return null
	End Method


	Method GetCableNetworkUplinkAudienceSum:int(stations:TList)
		local result:int
		for local station:TStationCableNetworkUplink = EachIn stations
			local section:TStationMapSection = GetSectionByName(station.GetSectionName())
			if section then result :+ section.GetCableNetworkAudienceSum()
		next
		return result
	End Method


	Method GetSatelliteUplinkAudienceSum:int(stations:TList)
		local result:int
		for local satLink:TStationSatelliteUplink = EachIn stations
			result :+ satLink.GetReach()
		'	result :+ satLink.GetExclusiveReach()
		next
		return result
	End Method


	Method GetSatelliteCount:int()
		return satellites.Count()
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


	Method GetSatelliteIndexByGUID:int(guid:string)
		local i:int = 0
		For local satellite:TStationMap_Satellite = EachIn satellites
			i :+ 1
			if satellite.GetGUID() = guid then return i
		Next
		return -1
	End Method


	Function GetSatelliteUplinksCount:int(stations:TList)
		local result:int
		for local station:TStationSatelliteUplink = EachIn stations
			result :+ 1
		next
		return result
	End Function


	Function GetCableNetworkUplinksInSectionCount:int(stations:TList, sectionName:string)
		local result:int

		for local station:TStationCableNetworkUplink = EachIn stations
			if station.GetSectionName() = sectionName
				result :+ 1
			endif
		next
		return result
	End Function


	Method GetTotalChannelExclusiveAudience:Int(channelNumber:int)
		local result:int
		For local section:TStationMapSection = EachIn sections
			result :+ section.GetExclusiveAntennaAudienceSum(channelNumber)
		Next
		return result
	End Method


	Method GetTotalShareAudience:Int(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		'return ".total" if you want to know what the "total amount" is
		'(so the sum of different people all "include channels" reach together)
		
		'return ".shared" if you want to know the population the 
		'"include channels" share between each other (exclusive to the 
		'excluded channels)
		Return GetTotalShare(includeChannelMask, excludeChannelMask).shared
	End Method


	Method GetTotalSharePercentage:Float(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetTotalShare(includeChannelMask, excludeChannelMask).populationShareRatio
	End Method


	Method GetTotalShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		local result:SStationMapPopulationShare

		If populationReceiverMode = RECEIVERMODE_SHARED
			Throw "GetTotalShare: Todo"

		ElseIf populationReceiverMode =  RECEIVERMODE_EXCLUSIVE

			'either
			'ATTENTION: contains only cable and antenna
			For local section:TStationMapSection = EachIn sections
				result :+ section.GetReceiverShare(includeChannelMask, excludeChannelMask)
			Next
			'or:
			'result :+ GetTotalAntennaShare(channelNumbers, withoutChannelNumbers)
			'result :+ GetTotalCableNetworkShare(channelNumbers, withoutChannelNumbers)

			'add Satellite shares
			result :+ GetTotalSatelliteReceiverShare(includeChannelMask, excludeChannelMask)
		EndIf

		return result
	End Method


	Method GetTotalAntennaReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		local result:SStationMapPopulationShare
		For local section:TStationMapSection = EachIn sections
			result :+ section.GetAntennaReceiverShare(includeChannelMask, excludeChannelMask)
		Next

		return result
	End Method


	Method GetTotalCableNetworkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		local result:SStationMapPopulationShare
		For local section:TStationMapSection = EachIn sections
			result :+ section.GetCableNetworkReceiverShare(includeChannelMask, excludeChannelMask)
		Next

		return result
	End Method


	'returns a share between channels, encoded in a TVec3D containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetTotalSatelliteReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		local result:SStationMapPopulationShare
		'no channel requested?
		if includeChannelMask.value = 0 then Return result
		
		For local satellite:TStationMap_Satellite = EachIn satellites
			local satResult:SStationMapPopulationShare
			Local channelsUsingThisSatellite:Int = 0
			Local allUseThisSatellite:Int = True
			'amount of non-ignored channels
			Local interestingChannelsCount:Int


			For Local channelID:Int = 1 to stationMaps.length
				'ignore unwanted
				If not includeChannelMask.Has(channelID) Then continue
				'skip if to exclude - exclusive reaches requested
				If excludeChannelMask.Has(channelID) Then continue

				interestingChannelsCount :+ 1
	
				if satellite.IsSubscribedChannel(channelID)
					channelsUsingThisSatellite :+ 1
				else
					allUseThisSatellite = False
				endif
			Next


			local channelUsageRatio:Float
			if channelsUsingThisSatellite > 0
				'print "GetTotalSatelliteShare: " + satellite.name + "   channelsUsingThisSatellite="+channelsUsingThisSatellite +"  reach="+satellite.GetReach()
				'total - if there is at least _one_ channel uses this satellite
				satResult.total = satellite.GetReach()

				'share is only available if we checked some channels
				if interestingChannelsCount > 0
					'share - if _all_ channels use this satellite here
					if allUseThisSatellite
						satResult.shared = satellite.GetReach()
					endif

					'share percentage
					channelUsageRatio = channelsUsingThisSatellite / Float(interestingChannelsCount)
				endif
			endif


			result.total :+ satResult.total
			result.shared :+ satResult.shared
			'total share percentage depends on the reach of a satellite - or its market share
			result.populationShareRatio :+ satellite.populationShare * (channelsUsingThisSatellite / float(interestingChannelsCount))
		Next

		return result
	End Method

	Method GetRandomAntennaCoordinateInSections:SVec2I(sectionNames:String[], allowSectionCrossing:Int = True)
		if sectionNames.length = 0 Then return Null

		local sectionName:String = sectionNames[ Rand(0, sectionNames.length-1) ]
		Return GetRandomAntennaCoordinateInSection(sectionName, allowSectionCrossing)
	End Method


	Method GetRandomAntennaCoordinateInSections:SVec2I(sections:TStationMapSection[], allowSectionCrossing:Int = True)
		if sections.length = 0 Then return Null

		local section:TStationMapSection = sections[ Rand(0, sections.length-1) ]
		Return GetRandomAntennaCoordinateInSection(section, allowSectionCrossing)
	End Method
	

	Method GetRandomAntennaCoordinateInSection:SVec2I(sectionName:String, allowSectionCrossing:Int = True)
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
		Return GetRandomAntennaCoordinateInSection(section)
	End Method

	Method GetRandomAntennaCoordinateInSection:SVec2I(section:TStationMapSection, allowSectionCrossing:Int = True)
		If not section then return Null 

		Local found:Int = False
		Local mapX:Int = 0
		Local mapY:Int = 0
		Local tries:int = 0

		Local sectionPix:TPixmap
		Local sprite:TSprite = section.GetShapeSprite()
		If not sprite Then return new SVec2I(-1, -1)
		If not sprite._pix Then sprite._pix = sprite.GetPixmap()

		Repeat
			'find random spot on "map"
			mapX = RandRange(section.rect.GetIntX(), section.rect.GetIntX2())
			mapY = RandRange(section.rect.GetIntY(), section.rect.GetIntY2())

			'check if spot in local space is on an opaque/colliding pixel
			If PixelIsOpaque(sprite._pix, mapX - section.rect.GetIntX(), mapY - section.rect.GetIntY()) > 0
				found = True
				'check if other map sections have an opacque pixel there too (ambiguity!)
				If not allowSectionCrossing
					For local otherSection:TStationMapSection = EachIn sections
						if section = otherSection then continue
						Local otherLocalX:Int = Int(mapX - otherSection.rect.GetX())
						Local otherLocalY:Int = Int(mapY - otherSection.rect.GetY())
						Local otherSprite:TSprite = otherSection.GetShapeSprite()
						If otherSprite 
							If not otherSprite._pix Then otherSprite._pix = otherSprite.GetPixmap()

							if otherLocalX >= 0 and otherLocalY >= 0 and otherLocalX < otherSection.rect.GetIntW() and otherLocalY < otherSection.rect.GetIntH()
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
		Until found or tries > 1000

		If tries > 1000 
			print "Failed to find a valid random section point in < 1000 tries."
			Return new SVec2I(-1, -1)
		EndIf
		
		If found
			Return new SVec2I(mapX, mapY)
		EndIf
		
		Return new SVec2I(-1, -1)
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


	Method LoadPopulationShareData:int()
		REM
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

		populationAntennaShareData = new TNumericPairInterpolator
		populationCableShareData = new TNumericPairInterpolator
		populationSatelliteShareData = new TNumericPairInterpolator

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

		rem
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

		Function YearTime:Long(year:int)
'		return year
			return GetWorldTime().MakeTime(year, 0, 0, 0, 0)
		End Function

		return True
	End Method


	'=== EVENT HANDLERS ===

	'as soon as a station gets active (again), the sharemap has to get
	'regenerated (for a correct audience calculation)
	Function onSetStationActiveState:int(triggerEvent:TEventBase)
		Local station:TStationBase = TStationBase(triggerEvent.GetSender())
		If not station then return false

		'invalidate (cached) share data of surrounding sections
		for local s:TStationMapSection = eachin GetInstance().GetSectionsConnectedToStation(station)
			s.InvalidateData()
		next

		'set the owning stationmap to "changed" so only this single
		'audience sum only gets recalculated (saves cpu time)
		GetInstance().GetMap(station.owner).reachInvalid = True
		
		Return True
	End Function


	'as soon as a broadcast provider (cable network, satellite) gets
	'inactive/active (again) caches have to get regenerated
	Function onSetBroadcastProviderActiveState:int(triggerEvent:TEventBase)
		Local broadcastProvider:TStationMap_BroadcastProvider = TStationMap_BroadcastProvider(triggerEvent.GetSender())
		If not broadcastProvider then return False

		'refresh cached count statistics
		if TStationMap_CableNetwork(broadcastProvider) then _instance.RefreshSectionsCableNetworkCount()

		Return True
	End Function


	'run when loading finished
	Function onSaveGameLoad:int(triggerEvent:TEventBase)
		TLogger.Log("TStationMapCollection", "Savegame loaded - reloading map data", LOG_DEBUG | LOG_SAVELOAD)

		_instance.LoadMapFromXML()

		'Ronny: no longer needed as recalculation is done automatically
		'       with a variable set to "false" on init.
		'maybe we got a borked up savegame which skipped recalculation
		'_instance.RecalculateMapAudienceSums(True)

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
		registryLoader.LoadSingleResourceFromXML(densityNode, null, True, New TData.AddString("name", "map_PopulationDensity"))
		registryLoader.LoadSingleResourceFromXML(surfaceNode, null, True, New TData.AddString("name", "map_Surface"))

		'older savegames might contain a config which has the data converted
		'to key->value[] arrays instead of values being overridden on each load.
		'so better just clear the config
		_instance.config = new TData
		_instance.cityNames = new TData
		if sportsDataNode then _instance.sportsData = new TData

		TXmlHelper.LoadAllValuesToData(configNode, _instance.config)
		TXmlHelper.LoadAllValuesToData(cityNamesNode, _instance.cityNames)
		if sportsDataNode
			TXmlHelper.LoadAllValuesToData(sportsDataNode, _instance.sportsData)
		endif

		'=== LOAD STATES ===
		'only if not done before
		'ATTENTION: overriding current sections will remove broadcast
		'           permissions as this is called _after_ a savegame
		'           got loaded!
		if _instance.sections.length = 0
			'remove old states
			'_instance.ResetSections()

			'find and load states configuration
			Local statesNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "states")
			If Not statesNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <map><states>-area.")

			For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(statesNode)
				Local name:String	= TXmlHelper.FindValue(child, "name", "")
				Local sprite:String	= TXmlHelper.FindValue(child, "sprite", "")
				Local pos:SVec2I	= New SVec2I( TXmlHelper.FindValueInt(child, "x", 0), TXmlHelper.FindValueInt(child, "y", 0) )

				Local pressureGroups:int = TXmlHelper.FindValueInt(child, "pressureGroups", -1)
				Local sectionConfig:TData
				local sectionConfigNode:TxmlNode = TXmlHelper.FindChild(child, "config")
				if sectionConfigNode
					sectionConfig = new TData
 					TXmlHelper.LoadAllValuesToData(sectionConfigNode, sectionConfig)
				endif
				'override config if pressureGroups are defined already
				if pressureGroups >= 0 then sectionConfig.AddInt("pressureGroups", pressureGroups)

				'add state section if data is ok
				If name<>"" And sprite<>""
					_instance.AddSection( New TStationMapSection.Create(pos, name, sprite, sectionConfig) )
				EndIf
			Next
			
			'calculate positions (now all sprites are loaded)
			For local s:TStationMapSection = EachIn _instance.sections
				'validate if defined via XML
				if s.uplinkPos 
					if not s.IsValidUplinkPos(s.uplinkPos.GetX(), s.uplinkPos.GetY())
						TLogger.Log("TStationMapCollection.onLoadStationMapData()", "Invalid / Ambiguous uplink position for state ~q" + s.name+"~q.", LOG_DEBUG)
						s.uplinkPos = Null
					EndIf
				EndIf
					
				s.GetLocalUplinkPos()
			Next
		endif


		_instance.LoadPopulationShareData()

		'=== CREATE SATELLITES / CABLE NETWORKS ===
		if not _instance.satellites or _instance.satellites.Count() = 0 then _instance.ResetSatellites()
		if not _instance.cableNetworks or _instance.cableNetworks.Count() = 0 then _instance.ResetCableNetworks()

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
		if station and antennaStationRadius = ANTENNA_RADIUS_NOT_INITIALIZED
			antennaStationRadius = 80
			For Local r:Int = 20 to 80
				TStationAntenna(station).radius = r
				If station.getReach(True) > GameRules.stationInitialIntendedReach
					antennaStationRadius = r
					exit
				Endif
			Next
		endif

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

				pix.WritePixel(i,j, ARGB_Color(int(brightnessRate*255), int((1.0-brightnessRate)*255), 0, 0))
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
		For local section:TStationMapSection = EachIn sections
			if section.pressureGroups = 0
				'1-2 pressure groups
				'it is possible to have two times the same group ...
				'resulting in only one being used
				For local i:int = 0 until RandRange(1,2)
					section.SetPressureGroups(TVTPressureGroup.GetAtIndex(RandRange(1, TVTPressureGroup.count)), True)
				Next
			endif
		Next

		TLogger.Log("TGetStationMapCollection().AssignPressureGroups", "Assigned pressure groups to sections of the map not containing predefined ones.", LOG_DEBUG | LOG_LOADING)
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

		'invalidate caches / antenna maps
		for local section:TStationMapSection = EachIn sections
			section.InvalidateData()
			'pre-create data already
			section.GetAntennaShareGrid()
		next

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


	Method UpdateSections()
		'if not sections then return
		'for local s:TStationMapSection = EachIn sections
		'next
	End Method


	Method UpdateSatellites()
		if not satellites then ResetSatellites()
		if not satellites then return

		local toRemove:TStationMap_Satellite[]

		for local s:TStationMap_Satellite = EachIn satellites
			s.Update()

			if s.deathDecided and s.deathTime < GetWorldTime().GetTimeGone()
				if not toRemove
					toRemove = [s]
				else
					toRemove :+ [s]
				endif
			endif
		next

		if toRemove and toRemove.length > 0
			for local s:TStationMap_Satellite = EachIn toRemove
				RemoveSatellite(s)
			next
		endif
	End Method


	Method UpdateCableNetworks()
		if not cableNetworks then ResetCableNetworks()
		if not cableNetworks then return

		for local s:TStationMap_CableNetwork = EachIn cableNetworks
			s.Update()
		next
	End Method


	Method UpdateSatelliteSubscriptions()
		if not satellites then return

		for local s:TStationMap_Satellite = EachIn satellites
			s.UpdateSubscriptions()
		next
	End Method


	Method UpdateCableNetworkSubscriptions()
		if not cableNetworks then return

		for local c:TStationMap_CableNetwork = EachIn cableNetworks
			c.UpdateSubscriptions()
		next
	End Method


	Method Update:Int()
		'repair broken census times in DEV patch savegames
		if nextCensusTime > 0 and nextCensusTime > GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH * 1
			print "repaired broken DEV Patch census time"
			nextCensusTime = GetWorldTime().Maketime(0, GetWorldTime().GetDay()+1, 0,0,0)
		endif

		'refresh stats ?
		if nextCensusTime < 0 or nextCensusTime < GetWorldTime().GetTimegone()
			DoCensus()
			'every day?
			nextCensusTime = GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH * 1
		endif

		'update (eg. launch)
		UpdateSatellites()
		UpdateCableNetworks()

		UpdateSections()

		'update all stationmaps (and their stations)
		For Local i:Int = 0 Until stationMaps.length
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

		'create up to 3 satellites
		Local lastLaunchTime:Long = GetWorldTime().MakeTime(1983, 1,1, 0,0)
		For Local satNumber:int = 0 until Min(3, satNames.length)
			local satName:string = satNames[satNumber]
			local launchTime:Long = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(0,1), RandRange(1,2), 0)
			local satellite:TStationMap_Satellite = CreateRandomSatellite(satName, launchTime)

			AddSatellite(satellite)

			lastLaunchTime = satellite.launchTime
		Next

		Return True
	End Method


	Method CreateRandomSatellite:TStationMap_Satellite(brandName:string, launchTime:Long, revision:int = 1)
		local satellite:TStationMap_Satellite = new TStationMap_Satellite
		satellite.launchTime = launchTime
'			satellite.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(18,28), RandRange(1,28), 0)
		satellite.brandName = brandName
		satellite.name = brandName
		if revision > 1 then satellite.name :+ " " + revision
		satellite.quality = RandRange(85,100)
		satellite.dailyFeeMod = RandRange(90,110) / 100.0
		satellite.setupFeeMod = RandRange(80,120) / 100.0
		satellite.dailyFeeBase = RandRange(75,110) * 1000
		satellite.setupFeeBase = RandRange(125,175) * 1000

		if revision <= 1
			satellite.minimumChannelImage = RandRange(20,30)
		elseif revision <= 3
			satellite.minimumChannelImage = RandRange(15,25)
		else
			satellite.minimumChannelImage = RandRange(10,15)
		endif

		'local year:int = GetWorldTime().GetYear(launchTime)
		'if year >= 1990
		'	satellite.minimumChannelImage = RandRange(10,20)
		'...

		Return satellite
	End Method


	Method AddSatellite:int(satellite:TStationMap_Satellite)
		if satellites.AddLast(satellite)
			'recalculate shared audience percentage between satellites
			UpdateSatelliteSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_AddSatellite, New TData.Add("satellite", satellite), Self )
			return True
		endif

		return False
	End Method


	Method RemoveSatellite:int(satellite:TStationMap_Satellite)
		if satellites.Remove(satellite)
			'recalculate shared audience percentage between satellites
			UpdateSatelliteSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_RemoveSatellite, New TData.Add("satellite", satellite), Self )
			return True
		endif

		return False
	End Method


	Method OnLaunchSatellite:int(satellite:TStationMap_Satellite)
		TriggerBaseEvent(GameEventKeys.StationMapCollection_LaunchSatellite, New TData.Add("satellite", satellite), Self )

		'recalculate shared audience percentage between satellites
		UpdateSatelliteSharesAndQuality()
		
		Return True
	End Method


	Method OnLetDieSatellite:int(satellite:TStationMap_Satellite)
		TriggerBaseEvent(GameEventKeys.StationMapCollection_LetDieSatellite, New TData.Add("satellite", satellite), Self )

		TLogger.Log("TStationMapCollection", "Let die satellite ~q"+satellite.name+"~q", LOG_DEBUG)

		'create another satellite ("follow up" revision)
		local nextSatellite:TStationMap_Satellite = CreateRandomSatellite(satellite.brandName, GetWorldTime().ModifyTime(-1, 0, 0, 0, RandRange(0,30)), satellite.revision + 1)
		AddSatellite(nextSatellite)

		Return True
	End Method


	Method UpdateSatelliteSharesAndQuality:int()
		if not satellites or satellites.Count() = 0 then return False

		local bestChannelCount:Int = 0
		local worstChannelCount:Int = 0
		local avgChannelCount:Float = 0
		local channelCountSum:Int = 0

		local bestQuality:Int = 0
		local worstQuality:Int = 0
		local avgQuality:Float = 0
		local qualitySum:Int = 0
		local firstFound:int = False
		local activeSatCount:int = 0
		For local satellite:TStationMap_Satellite = EachIn satellites
			if not satellite.IsLaunched() then continue

			local subscribedChannelCount:int = satellite.GetSubscribedChannelCount()

			if not firstFound
				firstFound = True
				bestQuality = satellite.quality
				worstQuality = satellite.quality

				bestChannelCount = subscribedChannelCount
				worstChannelCount = subscribedChannelCount
			endif

			bestQuality = Max(bestQuality, satellite.quality)
			worstQuality = Min(worstQuality, satellite.quality)
			qualitySum :+ satellite.quality

			bestChannelCount = Max(bestChannelCount, subscribedChannelCount)
			worstChannelCount = Min(worstChannelCount, subscribedChannelCount)
			channelCountSum :+ subscribedChannelCount

			activeSatCount :+ 1
		Next
		'skip further processing if there is no active satellite
		if activeSatCount = 0 then return False

		avgQuality = qualitySum / activeSatCount
		avgChannelCount = channelCountSum / activeSatCount

		'what's the worth of a quality point / channel?
		local sharePartQuality:Float = 1.0 / qualitySum
		local sharePartChannelCount:Float = 1.0 / channelCountSum

		'spread share across satellites
		'set best quality to 100% and adjust all others accordingly
'		print "UpdateSatelliteSharesAndQuality:"
'		print "  best quality="+bestQuality
		For local satellite:TStationMap_Satellite = EachIn satellites
			'ignore if not launched
			'share is not affected if not launched
			'quality is "perceived quality" (by audience) so also not affected
			if not satellite.IsLaunched() then continue

			satellite.oldPopulationShare = satellite.populationShare

			'min 40% influence of quality
			'max 60% of subscribed channel count
			'weight is depending on how many channels use satellites
			if bestChannelCount > 0
				local bestChannelWeight:Float = 0.6 * bestChannelCount/4.0 '4 = player count
				satellite.populationShare = MathHelper.Clamp((1.0 - bestChannelWeight) * (sharePartQuality * satellite.quality) + bestChannelWeight * (sharePartChannelCount * satellite.GetSubscribedChannelCount()), 0.0, 1.0)
			else
				satellite.populationShare = MathHelper.Clamp(sharePartQuality * satellite.quality, 0.0, 1.0)
			endif

			satellite.oldQuality = satellite.quality
			satellite.quality = MathHelper.Clamp(100 * satellite.quality / float(bestQuality), 0.0, 100.0)

'			print "  satellite: "+Lset(satellite.name, 12)+ "  share: " + satellite.oldPopulationShare +" -> " + satellite.populationShare +"   quality: " + satellite.oldQuality +" -> " + satellite.quality
		Next

		Return True
	End Method


	Method RemoveSatelliteUplinkFromSatellite:int(satellite:TStationMap_Satellite, linkOwner:int)
		local map:TStationMap = GetMap(linkOwner)
		if not map then return False

		local satLink:TStationSatelliteUplink = TStationSatelliteUplink( map.GetSatelliteUplinkBySatellite(satellite) )
		if not satLink then return False


		rem
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
		if cableNetworks and cableNetworks.Count() > 0
			'avoid concurrent list modification and remove from list
			'by iterating over an array copy
			local cnArray:TStationMap_CableNetwork[] = new TStationMap_CableNetwork[ cableNetworks.Count() ]
			local i:int
			For local cableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
				cnArray[i] = cableNetwork
				i :+ 1
			Next
			For local cableNetwork:TStationMap_CableNetwork = EachIn cnArray
				RemoveCableNetwork(cableNetwork)
			Next
		endif
		'create new list (or empty it)
		cableNetworks = CreateList()

		'TODO: init from map-config-file!

		'create some networks
		local cnNames:string[] = ["Kabel %name%", "Verbund %name%", "Tele %name%", "%name% Kabel", "FK %name%"]

		Local lastLaunchTime:Long = GetWorldTime().MakeTime(1982, 1,1, 0,0)
		Local cnNumber:int = 0

		For local section:TStationMapSection = EachIn sections
			local cableNetwork:TStationMap_CableNetwork = new TStationMap_CableNetwork
			'shorter and shorter amounts
			if cnNumber < sections.length/4
				cableNetwork.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(5,9), RandRange(1,28), 0)
			elseif cnNumber < sections.length/2
				cableNetwork.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(3,6), RandRange(1,28), 0)
			else
				cableNetwork.launchTime = GetWorldTime().ModifyTime(lastLaunchTime, 0, RandRange(2,4), RandRange(1,28), 0)
			endif
			'still includes potential place holders!
			cableNetwork.name = cnNames[RandRange(0, cnNames.length-1)]
			cableNetwork.quality = RandRange(95,110)
			cableNetwork.dailyFeeMod = RandRange(90,110) / 100.0
			cableNetwork.setupFeeMod = RandRange(80,120) / 100.0
			cableNetwork.dailyFeeBase = RandRange(50,75) * 1000
			cableNetwork.setupFeeBase = RandRange(175,215) * 1000
			cableNetwork.sectionName = section.name
			if cnNumber = 0
				cableNetwork.minimumChannelImage = RandRange(5,10)
			elseif cnNumber <= 3
				cableNetwork.minimumChannelImage = RandRange(8,16)
			elseif cnNumber <= 6
				cableNetwork.minimumChannelImage = RandRange(14,25)
			else
				cableNetwork.minimumChannelImage = RandRange(23,37)
			endif
			cnNumber :+ 1

			AddCableNetwork(cableNetwork)

			lastLaunchTime = cableNetwork.launchTime

			'add federal state name for cable providers etc (else this
			'is only appended when using GetName() instead of ".name"
			cableNetwork.name = cableNetwork.GetName()
		Next

		Return True
	End Method


	Method AddCableNetwork:int(cableNetwork:TStationMap_CableNetwork)
		if cableNetworks.AddLast(cableNetwork)
			'recalculate shared audience percentage between cable networks
			UpdateCableNetworkSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_AddCableNetwork, New TData.Add("cableNetwork", cableNetwork), Self )
			return True
		endif

		return False
	End Method


	Method RemoveCableNetwork:int(cableNetwork:TStationMap_CableNetwork)
		if cableNetworks.Remove(cableNetwork)
			'recalculate shared audience percentage between cable networks
			UpdateCableNetworkSharesAndQuality()

			'inform others
			TriggerBaseEvent(GameEventKeys.StationMapCollection_RemoveCableNetwork, New TData.Add("cableNetwork", cableNetwork), Self )
			return True
		endif

		return False
	End Method


	Method OnLaunchCableNetwork:int(cableNetwork:TStationMap_CableNetwork)
		'recalculate shared audience percentage between cable networks
		UpdateCableNetworkSharesAndQuality()

		Return True
	End Method


	Method RefreshSectionsCableNetworkCount:int()
		For local section:TStationMapSection = EachIn sections
			section.activeCableNetworkCount = 0
			section.cableNetworkCount = 0

			For local otherCableNetwork:TStationMap_CableNetwork = EachIn cableNetworks
				if otherCableNetwork.sectionName = section.name
					section.cableNetworkCount :+ 1
					if otherCableNetwork.IsActive()
						section.activeCableNetworkCount :+ 1
					endif
				endif
			Next
		Next

		Return True
	End Method


	Method UpdateCableNetworkSharesAndQuality:int()
		if not cableNetworks or cableNetworks.Count() = 0 then return False

'todo
rem
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


	Method RemoveCableNetworkUplinkFromCableNetwork:int(cableNetwork:TStationMap_CableNetwork, linkOwner:int)
		local map:TStationMap = GetMap(linkOwner)
		if not map then return False

		local cableLink:TStationCableNetworkUplink = TStationCableNetworkUplink( map.GetCableNetworkUplinkStationByCableNetwork(cableNetwork) )
		if not cableLink then return False

		rem
		'variant A - keep "uplink"
		cableLink.providerGUID = ""
		'force running costs recalculation
		cableLink.runningCosts = -1

		'do not sell it directly but just "shutdown" (so contracts can get renewed)
		cableLink.ShutDown()
		endrem

		'variant B - just sell the uplink
		return map.SellStation(cableLink)
	End Method



	Method RemoveUplinkFromBroadcastProvider:int(broadcastProvider:TStationMap_BroadcastProvider, uplinkOwner:int)
		If TStationMap_Satellite(broadcastProvider)
			return RemoveSatelliteUplinkFromSatellite(TStationMap_Satellite(broadcastProvider), uplinkOwner)
		ElseIf TStationMap_CableNetwork(broadcastProvider)
			return RemoveCableNetworkUplinkFromCableNetwork(TStationMap_CableNetwork(broadcastProvider), uplinkOwner)
		EndIf

		Return False
	End Method


	'=== SECTIONS ===

	Method GetSection:TStationMapSection(x:Int,y:Int)
		For Local section:TStationMapSection = EachIn sections
			Local sprite:TSprite = section.GetShapeSprite()
			If not sprite Then Continue

			If section.rect.containsXY(x,y)
				If not sprite._pix Then sprite._pix = sprite.GetPixmap()
				If PixelIsOpaque(sprite._pix, Int(x-section.rect.getX()), Int(y-section.rect.getY())) > 0
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

		Return null
	End Method


	Method GetSectionByListPosition:TStationMapSection(position:int)
		If position >= 0 and position < sections.length
			Return TStationMapSection(sections[position])
		Else
			Return Null
		EndIf
	End Method


	Method GetSectionCount:int()
		return sections.length
	End Method


	Method GetSectionNames:string[]()
		local names:string[] = new String[ sections.length ]
		For Local i:int = 0 until sections.length
			names[i] = sections[i].name.ToLower()
		Next

		Return names
	End Method


	Method GetSectionsFiltered:TStationMapSection[](channelID:Int=-1, checkBroadcastPermission:Int=True, requiredBroadcastPermissionState:Int=True, stationType:Int=-1)
		Local filteredSections:TStationMapSection[] = new TStationMapSection[sections.length]
		Local used:Int = 0
		For Local section:TStationMapSection = EachIn self.sections
			If (checkBroadcastPermission and section.NeedsBroadcastPermission(channelID, stationType))
				If section.HasBroadcastPermission(channelID, stationType) <> requiredBroadcastPermissionState Then Continue
			EndIf
			filteredSections[used] = section
			
			used :+ 1
		Next

		if used <> filteredSections.length
			return filteredSections[.. used]
		else
			return filteredSections
		endif
	End Method
	

	'returns sections "nearby" a station (connection not guaranteed as
	'check of a circle-antenna is based on two rects intersecting or not)
	Method GetSectionsConnectedToStation:TStationMapSection[](station:TStationBase)
		if not station then return new TStationMapSection[0]

		'GetInstance()._regenerateMap = True
		if TStationAntenna(station)
			local radius:int = TStationAntenna(station).radius
			local stationRect:TRectangle = New TRectangle.Init(station.x - radius, station.y - radius, 2*radius, 2*radius)
			local result:TStationMapSection[] = new TStationMapSection[sections.length]
			local added:int = 0

			For local section:TStationMapSection = EachIn sections
				if not section.rect.IntersectRect(stationRect) then continue

				result[added] = section
				added :+ 1
			Next
			if added < result.length then result = result[.. added]
			return result

		elseif TStationCableNetworkUplink(station)
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName(station.GetSectionName())
			if section then return [section]

		elseif TStationSatelliteUplink(station)
			'all
			local result:TStationMapSection[] = new TStationMapSection[sections.length]
			local added:int = 0
			For local section:TStationMapSection = EachIn sections
				result[added] = section
				added :+ 1
			Next
			return result
		else
			Throw "GetSectionsConnectedToStation: unhandled station type"
		endif

		return new TStationMapSection[0]
	End Method


	Method DrawAllSections()
		If Not sections Then Return
		Local oldA:Float = GetAlpha()
		SetAlpha oldA * 0.8
		For Local section:TStationMapSection = EachIn sections
			If Not section.GetShapeSprite() Then Continue
			section.shapeSprite.Draw(section.rect.getx(), section.rect.gety())
		Next
		SetAlpha oldA
	End Method


	Method ResetSections()
		sections = new TStationMapSection[0]
	End Method


	Method AddSection(section:TStationMapSection)
		sections :+ [section]
		'inform others
		TriggerBaseEvent(GameEventKeys.StationMapCollection_AddSection, New TData.Add("section", section), Self )
	End Method


	Method RemoveSectionFromPopulationSectionImage:int(section:TStationMapSection)
		local startX:int = int(Max(0, section.rect.GetX()))
		local startY:int = int(Max(0, section.rect.GetY()))
		local endX:int = int(Min(populationImageSections.width, section.rect.GetX2()))
		local endY:int = int(Min(populationImageSections.height, section.rect.GetY2()))
		local pix:TPixmap = LockImage(populationImageSections)
		local emptyCol:int = ARGB_Color(0, 0,0,0)

		Local sectionPix:TPixmap
		Local sprite:TSprite = section.GetShapeSprite()
		If not sprite Then return False
		If not sprite._pix Then sprite._pix = sprite.GetPixmap()

		For local x:int = startX until endX
			For local y:int = startY until endY
				If PixelIsOpaque(sprite._pix, Int(x-section.rect.getX()), Int(y-section.rect.getY())) > 0
					pix.WritePixel(x,y, emptyCol)
				endif
			Next
		Next

		return True
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




Type TStationMap extends TOwnedGameObject {_exposeToLua="selected"}
	'select whose players stations we want to see
	Field showStations:Int[4]
	'and what types we want to show
	Field showStationTypes:Int[3]
	'maximum audience possible
	Field reach:Int	= 0
	Field reachInvalid:int = True {nosave}
	Field cheatedMaxReach:int = False
	'all stations of the map owner
	Field stations:TList = CreateList()
	'amount of stations added per type
	Field stationsAdded:int[4]
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
		reachInvalid = true
		sectionBroadcastPermissions = new TMap
		showStations = [1,1,1,1]
		showStationTypes = [1,1,1]
		cheatedMaxReach = False
		stationsAdded = new Int[4]
		
		Return True
	End Method


	Method DoCensus()
		reachInvalid = true
		'refresh station reach
		For local station:TStationBase = EachIn stations
			station.GetReach(true)
		Next
	End Method


	Method SetSectionBroadcastPermission:int(sectionName:string, bool:int=True )
		if not sectionBroadcastPermissions then sectionBroadcastPermissions = new TMap
		sectionBroadcastPermissions.Insert(sectionName, string(bool))
		
		Return True
	End Method


	Method GetSectionBroadcastPermission:int(sectionName:string, bool:int=True )
		if not sectionBroadcastPermissions then return False
		return int(string(sectionBroadcastPermissions.ValueForKey(sectionName)))
	End Method


	'returns the maximum reach of the stations on that map
	Method GetReach:Int() {_exposeToLua}
		Return Max(0, Self.reach)
	End Method


	Function GetReachLevel:Int(reach:int)
		'put this into GameRules?
		if reach < 2500000
			return 1
		elseif reach < 2500000 * 2 '5mio
			return 2
		elseif reach < 2500000 * 5 '12,5 mio
			return 3
		elseif reach < 2500000 * 9 '22,5 mio
			return 4
		elseif reach < 2500000 * 14 '35 mio
			return 5
		elseif reach < 2500000 * 20 '50 mio
			return 6
		elseif reach < 2500000 * 28 '70 mio
			return 7
		elseif reach < 2500000 * 40 '100 mio
			return 8
		elseif reach < 2500000 * 60 '150 mio
			return 9
		elseif reach < 2500000 * 100 '250 mio
			return 10
		else
			return 11
		endif
	End Function


	Method GetCoverage:Float() {_exposeToLua}
		Return Float(GetReach()) / Float(GetStationMapCollection().getPopulation())
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryAntennaStation:TStationBase(x:Int, y:Int)  {_exposeToLua}
		local station:TStation = new TStation
		station.radius = GetStationMapCollection().antennaStationRadius

		Return station.Init(x, y, -1, owner)
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryCableNetworkUplinkStation:TStationBase(cableNetworkIndex:int)  {_exposeToLua}
		return GetTemporaryCableNetworkUplinkStationByCableNetwork( GetStationMapCollection().GetCableNetworkAtIndex(cableNetworkIndex) )
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporaryCableNetworkUplinkStationByCableNetwork:TStationBase(cableNetwork:TStationMap_CableNetwork)
		if not cableNetwork or not cableNetwork.launched then return Null
		local station:TStationCableNetworkUplink = new TStationCableNetworkUplink

		station.providerGUID = cableNetwork.getGUID()

		local mapSection:TStationMapSection = GetStationMapCollection().GetSectionByName(cableNetwork.sectionName)
		if not mapSection then return Null

		local stationPos:TVec2I = new TVec2I.CopyFrom(mapSection.rect.position).AddVec( mapSection.GetLocalUplinkPos() )
		station.Init(stationPos.x, stationPos.y, -1, owner)
		station.SetSectionName(mapSection.name)
		'now we know how to calculate population
		station.RefreshData()
		
		Return station
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method GetTemporarySatelliteUplinkStation:TStationBase(satelliteIndex:int)  {_exposeToLua}
		local station:TStationSatelliteUplink = new TStationSatelliteUplink
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteAtIndex(satelliteIndex)
		if not satellite or not satellite.launched then return Null

		station.providerGUID = satellite.getGUID()

		'TODO: satellite positions ?
		Return station.Init(10,430 - satelliteIndex*50, -1, owner)
	End Method


	Method GetTemporarySatelliteUplinkStationBySatelliteGUID:TStationBase(satelliteGUID:string)  {_exposeToLua}
		local station:TStationSatelliteUplink = new TStationSatelliteUplink
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(satelliteGUID)
		if not satellite or not satellite.launched then return Null

		station.providerGUID = satellite.getGUID()

		'TODO: satellite positions
		'-> some satellites are foreign ones
		local satelliteIndex:int = GetStationMapCollection().GetSatelliteIndexByGUID(station.providerGUID)

		Return station.Init(10, 430 - satelliteIndex*50, -1, owner)
	End Method


	'return all antenna stations covering the given coordinates
	Method GetAntennasByXY:TStationAntenna[](x:Int, y:Int, exactPosition:Int = True) {_exposeToLua}
		Local res:TStationAntenna[]
		For Local antenna:TStationAntenna = EachIn stations
			If exactPosition 
				If antenna.x <> x or antenna.y <> y Then Continue
			Else
				'x,y outside of station-circle?
				If antenna.radius < Sqr((x - antenna.x)^2 + (y - antenna.y)^2) Then Continue
			EndIf
			res :+ [antenna]
		Next
		Return res
	End Method


	'returns best suiting antenna (x,y must be station position or "in range")
	Method GetAntennaByXY:TStationAntenna(x:Int, y:Int, exactPosition:Int = True) {_exposeToLua}
		Local best:TStationAntenna
		Local bestDistanceSquared:Int = -1
		
		'For antenna stations it chooses the one containing the given
		'coordinate in its "circle" and being the nearest position wise
		
		For Local antenna:TStationAntenna = EachIn stations
			If exactPosition
				If antenna.x <> x or antenna.y <> y Then Continue
			Else
				'or x,y outside of station-circle?
				local distanceSquared:Int = (x - antenna.x)^2 + (y - antenna.y)^2
				If antenna.radius^2 < distanceSquared Then Continue
				
				if distanceSquared < bestDistanceSquared or bestDistanceSquared = -1
					bestDistanceSquared = distanceSquared
					best = antenna
				endif
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
	Method GetStationsBySectionName:TStationBase[](sectionName:string, stationType:int=0) {_exposeToLua}
		local result:TStationBase[5]
		Local found:int = 0 
		For local station:TStationBase = EachIn stations
			if stationType >0 and station.stationType <> stationType then continue
			if station.GetSectionName() = sectionName 
				result[found] = station
				found :+ 1
				if found > result.length then result = result[.. result.length + 5]
			endif
		Next
		if found <> result.length
			result = result[.. found]
		endif
		return result
	End Method


	Method GetCableNetworkUplinkStationBySectionName:TStationBase(sectionName:string)
		For local station:TStationBase = EachIn stations
			if station.stationType <> TVTStationType.CABLE_NETWORK_UPLINK then continue
			if station.GetSectionName() = sectionName then return station
		Next
		return null
	End Method


	Method GetCableNetworkUplinkStationByCableNetwork:TStationBase(cableNetwork:TStationMap_CableNetwork)
		For local station:TStationCableNetworkUplink = EachIn stations
			if station.providerGUID = cableNetwork.GetGUID() then return station
		Next
		return null
	End Method


	Method GetSatelliteUplinkBySatellite:TStationBase(satellite:TStationMap_Satellite)
		For local station:TStationSatelliteUplink = EachIn stations
			if station.providerGUID = satellite.GetGUID() then return station
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


	Method GetSatelliteUplinksCount:int()
		return TStationMapCollection.GetSatelliteUplinksCount(stations)
	End Method


	Method GetCableNetworkUplinksInSectionCount:int(sectionName:string)
		return TStationMapCollection.GetCableNetworkUplinksInSectionCount(stations, sectionName)
	End Method


	Method HasCableNetworkUplink:int(station:TStationCableNetworkUplink)
		return stations.contains(station)
'		For local s:TStationCableNetworkLink = EachIn stations
'			if s = station then return True
'		Next
'		return False
	End Method


	Method HasStation:int(station:TStationBase)
		return stations.contains(station)
	End Method


	Method GetRandomAntennaCoordinateOnMap:SVec2I(checkBroadcastPermission:Int=True, requiredBroadcastPermissionState:Int=True)
		Local x:int = Rand(35, 560)
		Local y:int = Rand(1, 375)
		Local station:TStationBase = GetTemporaryAntennaStation(x, y)
		if station.GetPrice() < 0 then return Null
		
		if checkBroadcastPermission and GetStationMapCollection().GetSection(x,y).HasBroadcastPermission(owner, TVTStationType.ANTENNA) <> requiredBroadcastPermissionState Then Return Null
		 
		Return new SVec2I(x,y)
	End Method
	

	Method GetRandomAntennaCoordinateInPlayerSections:SVec2I()
		local sections:TStationMapSection[] = GetStationMapCollection().GetSectionsFiltered(owner, True, True, TVTStationType.ANTENNA)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSections(sections)
	End Method


	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSections:SVec2I(sections:TStationMapSection[], allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSections(sections, allowSectionCrossing)
	End Method


	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSections:SVec2I(sectionNames:string[], allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSections(sectionNames, allowSectionCrossing)
	End Method


	'specific section
	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSection:SVec2I(sectionName:string, allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSection(sectionName, allowSectionCrossing)
	End Method


	'specific section
	'allowSectionCrossing: sections might have pixels they share... this
	'                      allows these positions to be used
	Method GetRandomAntennaCoordinateInSection:SVec2I(section:TStationMapSection, allowSectionCrossing:Int = True)
		Return GetStationMapCollection().GetRandomAntennaCoordinateInSection(section, allowSectionCrossing)
	End Method


	Method CheatMaxAudience:int()
		local oldReachLevel:int = GetReachLevel(GetReach())
		cheatedMaxReach = true
		reach = GetStationMapCollection().population

		for local s:TStationMapSection = eachin GetStationMapCollection().sections
			s.InvalidateData()
		next

		if GetReachLevel(reach) <> oldReachLevel
			TriggerBaseEvent(GameEventKeys.StationMap_OnChangeReachLevel, New TData.addInt("reachLevel", GetReachLevel(reach)).AddInt("oldReachLevel", oldReachLevel), Self )
		endif

		return True
	End Method


	Method CalculateTotalAntennaAudienceIncrease:Int(x:Int=-1000, y:Int=-1000, radius:int = -1)
		return GetStationMapCollection().CalculateTotalAntennaAudienceIncrease(stations, x, y, radius)
	End Method


	'returns maximum audience a player's stations cover
	Method RecalculateAudienceSum:Int() {_exposeToLua}
		local reachBefore:int = GetReach()
		local oldReachLevel:int = GetReachLevel(reachBefore)

		if cheatedMaxReach
			reach = GetStationMapCollection().population
		else
			If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
				Throw "RecalculateAudienceSum: Todo"
			ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
				reach =  GetStationMapCollection().GetAntennaAudienceSum(owner)
				reach :+ GetStationMapCollection().GetCableNetworkUplinkAudienceSum(stations)
				reach :+ GetStationMapCollection().GetSatelliteUplinkAudienceSum(stations)
				'print "RON: antenna["+owner+"]: " + GetStationMapCollection().GetAntennaAudienceSum(owner) + "   cable["+owner+"]: " + GetStationMapCollection().GetCableNetworkUplinkAudienceSum(stations) +"   satellite["+owner+"]: " + GetStationMapCollection().GetSatelliteUplinkAudienceSum(stations) + "   recalculated: " + reach
			EndIf
		endif
		'current reach is updated now
		reachInvalid = False

		'inform others
		TriggerBaseEvent(GameEventKeys.StationMap_OnRecalculateAudienceSum, New TData.AddInt("reach", reach).AddInt("reachBefore", reachBefore).AddInt("playerID", owner), Self )

		if GetReachLevel(reach) <> oldReachLevel
			TriggerBaseEvent(GameEventKeys.StationMap_OnChangeReachLevel, New TData.AddInt("reachLevel", GetReachLevel(reach)).AddInt("oldReachLevel", oldReachLevel), Self )
		endif


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
	Method BuyAntennaStation:Int(x:Int, y:Int)
		Return AddStation( GetTemporaryAntennaStation( x, y ), True )
	End Method


	'buy a new cable network station at the given coordinates
	Method BuyCableNetworkUplinkStationByMapSection:Int(mapSection:TStationMapSection)
		if not mapSection then return False

		BuyCableNetworkUplinkStationBySectionName(mapSection.name)
	End Method


	'buy a new cable network station at the given coordinates
	Method BuyCableNetworkUplinkStationBySectionName:Int(sectionName:string, autoUpdateContract:Int = False)
		'find first cable network operating in that section
		local index:int = 0
		for local cableNetwork:TStationMap_CableNetwork = Eachin GetStationMapCollection().cableNetworks
			if cableNetwork.sectionName = sectionName
				local tmp:TStationBase = GetTemporaryCableNetworkUplinkStation( index )
				tmp.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT,autoUpdateContract)
				Return AddStation(tmp, True )
			endif
			index :+ 1
		next
		return False
	End Method


	'buy a new cable network link for the give cableNetwork
	Method BuyCableNetworkUplinkStation:Int(cableNetworkIndex:int)
		Return AddStation( GetTemporaryCableNetworkUplinkStation( cableNetworkIndex ), True )
	End Method


	'buy a new satellite station at the given coordinates
	Method BuySatelliteUplinkStation:Int(satelliteIndex:int, autoUpdateContract:Int = False)
		Local tmp:TStationBase = GetTemporarySatelliteUplinkStation( satelliteIndex )
		tmp.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT,autoUpdateContract)
		Return AddStation(tmp, True )
	End Method


	Method CanAddStation:int(station:TStationBase)
		'only one network per section and player allowed
		if TStationCableNetworkUplink(station) and GetCableNetworkUplinkStationBySectionName(station.GetSectionName()) then Return False

		'TODO: ask if the station is ok with it (eg. satlink asks satellite first)
		'for now:
		'only add sat links if station can subscribe to satellite
		local provider:TStationMap_BroadcastProvider
		if TStationSatelliteUplink(station)
			provider = GetStationMapCollection().GetSatelliteByGUID(station.providerGUID)
			if not provider then Return False

		elseif TStationCableNetworkUplink(station)
			provider = GetStationMapCollection().GetCableNetworkByGUID(station.providerGUID)
			if not provider then Return False

		endif

		if provider
			if provider.IsSubscribedChannel(owner) then Return False
			if provider.CanSubscribeChannel(owner, -1) <= 0 then Return False
		endif

		return True
	End Method


	'sell a station at the given position in the list
	Method SellStationAtPosition:Int(position:Int)
		return SellStation( getStationAtIndex(position) )
	End Method


	Method SellStation:Int(station:TStationBase)
		If station Then Return RemoveStation(station, True)
		Return False
	End Method


	Method GetTotalStationBuyPrice:int(station:TStationBase)
		if not station then return 0

		return station.GetTotalBuyPrice()
	End Method


	Method AddStation:Int(station:TStationBase, buy:Int=False)
		If Not station Then Return False

		''check if placement is allowed/possible
		if not CanAddStation(station) then return False


		local section:TStationMapSection = GetStationMapCollection().GetSectionByName(station.GetSectionName())
		local buyPermission:int = False
		local totalPrice:int = GetTotalStationBuyPrice(station)
		'check if there is a governmental broadcast/build permission
		'also allow "granted" to be in another section?
		if not station.HasFlag(TVTStationFlag.ILLEGAL) ' and not station.HasFlag(TVTStationFlag.GRANTED)
			'stations without assigned section cannot have a permission...
			if section and section.NeedsBroadcastPermission(owner, station.stationType) and not section.HasBroadcastPermission(owner)
				buyPermission = true
			endif
		endif


		'try to buy it (does nothing if already done)
		If buy
			'check if we can pay both things
			if section and buyPermission
				'fail if permission is needed but cannot get obtained
				if section.NeedsBroadcastPermission(owner, station.stationType) and not section.HasBroadcastPermission(owner, station.stationType)
					if not section.CanGetBroadcastPermission(owner) then return False
				endif
				if not GetPlayerFinance(owner).CanAfford(totalPrice) then return False
			endif

			'if needed buy the permission
			if section and buyPermission and not section.HasBroadcastPermission(owner, station.stationType)
				if not section.BuyBroadcastPermission(owner, station.stationType, -1)
					return False
				endif
			endif

			'(try to) buy the actual station
			if not station.Buy(owner) Then Return False
		EndIf


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
			TriggerBaseEvent(GameEventKeys.Stationmap_AddStation, New TData.add("station", station), Self )
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
		for local s:TStationMapSection = eachin GetStationMapCollection().GetSectionsConnectedToStation(station)
			s.InvalidateData()
		next
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
			TriggerBaseEvent(GameEventKeys.StationMap_RemoveStation, New TData.add("station", station), Self)
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


	Method Update:int()
		if reachInvalid then RecalculateAudienceSum()

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
	Field x:Int {_exposeToLua="readonly"}
	Field y:Int {_exposeToLua="readonly"}

	'audience reachable with current stationtype share
	Field reach:Int	= -1
	'maximum audience if all would use that type
	Field reachMax:Int = -1
	'reach of just this station without others in range
	Field reachExclusiveMax:Int = -1

	Field price:Int	= -1

	Field providerGUID:string {_exposeToLua}

	'daily costs for "running" the station
	Field runningCosts:int = -1
	Field owner:Int = 0
	'time at which the station was bought
	Field built:Long = 0
	'time at which the station gets active (again)
	Field activationTime:Long = -1
	Field name:string = ""
	Field stationType:int = 0
	Field _sectionName:String = "" {nosave}
	'various settings (paid, fixed price, sellable, active...)
	Field _flags:Int = 0

	Field listSpriteNameOn:string = "gfx_datasheet_icon_antenna.on"
	Field listSpriteNameOff:string = "gfx_datasheet_icon_antenna.off"


	Method Init:TStationBase( x:Int, y:Int, price:Int=-1, owner:Int)
		self.owner = owner
		self.x = x
		self.y = y

		self.price = price
		self.built = GetWorldTime().GetTimeGone()
		self.activationTime = -1

		self.SetFlag(TVTStationFlag.FIXED_PRICE, (price <> -1))
		'by default each station could get sold
		self.SetFlag(TVTStationFlag.SELLABLE, True)

		self.RefreshData()

		Return self
	End Method


	Method GenerateGUID:string()
		return "stationbase-"+id
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
	Method GetReachMax:Int(refresh:Int=False) abstract {_exposeToLua}


	'get the reach of that station
	Method GetReach:Int(refresh:Int=False) abstract {_exposeToLua}


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) abstract {_exposeToLua}


	'get the relative reach increase of that station
	Method GetRelativeExclusiveReach:Float(refresh:Int=False) {_exposeToLua}
		Local r:Float = GetReach(refresh)
		If r = 0 Then Return 0

		Return GetExclusiveReach(refresh) / r
	End Method


	Method GetSectionName:String(refresh:Int=False) {_exposeToLua}
		If _sectionName <> "" And Not refresh Then Return _sectionName

		Local hoveredSection:TStationMapSection = GetStationMapCollection().GetSection(x, y)
		If hoveredSection Then _sectionName = hoveredSection.name

		Return _sectionName
	End Method


	Method GetProvider:TStationMap_BroadcastProvider()
		if not providerGUID then return Null
	End Method


	Method GetSellPrice:Int() {_exposeToLua}
		'price decreasing with age
		Local offer:Int = Int((0.8 - 0.1 * GetAgeInDays()) * GetPrice())
		'waste removal costs
		Local minPrice:Int = -GetPrice()/2

		return Max(offer, minPrice)
	End Method


	'what was paid for it?
	Method GetPrice:Int() {_exposeToLua}
		if price < 0 then return GetBuyPrice()
		return price
	End Method


	'current price
	Method GetBuyPrice:Int() {_exposeToLua}
		return 0
	End Method


	'price including potential permission fees
	Method GetTotalBuyPrice:Int() {_exposeToLua}
		local buyPrice:int = GetBuyPrice()

		'check if there is a governmental broadcast/build permission
		'also allow "granted" to be in another section?
		if not HasFlag(TVTStationFlag.ILLEGAL) ' and not HasFlag(TVTStationFlag.GRANTED)
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			'stations without assigned section cannot have a permission...
			if section and section.NeedsBroadcastPermission(owner, stationType) and not section.HasBroadcastPermission(owner, stationType)
				buyPrice :+ section.GetBroadcastPermissionPrice(owner, stationType)
			endif
		endif
		return buyPrice
	End Method


	Method GetName:string() {_exposeToLua}
		return name
	End Method


	Method GetTypeName:string() {_exposeToLua}
		return "stationbase"
	End Method


	Method GetLongName:string() {_exposeToLua}
		if GetName() then return GetTypeName() + " " + GetName()
		return GetTypeName()
	End Method


	Method CanBroadcast:Int() {_exposeToLua}
		Return HasFlag(TVTStationFlag.ACTIVE) and not HasFlag(TVTStationFlag.SHUTDOWN)
	End Method


	Method IsActive:Int() {_exposeToLua}
		Return HasFlag(TVTStationFlag.ACTIVE)
	End Method


	Method IsShutdown:Int() {_exposeToLua}
		Return HasFlag(TVTStationFlag.SHUTDOWN)
	End Method


	Method IsCableNetworkUplink:int() {_exposeToLua}
		return stationType = TVTStationType.CABLE_NETWORK_UPLINK
	End Method


	Method IsSatelliteUplink:int() {_exposeToLua}
		return stationType = TVTStationType.SATELLITE_UPLINK
	End Method


	Method IsAntenna:int() {_exposeToLua}
		return stationType = TVTStationType.ANTENNA
	End Method


	'set time a station begins to work (broadcast)
	Method SetActivationTime(activationTime:Long = -1)
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
		TriggerBaseEvent(GameEventKeys.Station_OnSetActive, Null, Self)

		return True
	End Method


	Method SetInactive:Int()
		If Not IsActive() Then Return False

		SetFlag(TVTStationFlag.ACTIVE, False)

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.Station_OnSetInactive, Null, Self)
	End Method


	Method ShutDown:int()
		if HasFlag(TVTStationFlag.SHUTDOWN) then return False

		SetFlag(TVTStationFlag.SHUTDOWN, True)

		'inform others (eg. to refresh list content)
		TriggerBaseEvent(GameEventKeys.Station_OnShutdown, Null, Self)

		return True
	End Method


	Method Resume:int()
		if not HasFlag(TVTStationFlag.SHUTDOWN) then return False

		SetFlag(TVTStationFlag.SHUTDOWN, False)

		'inform others (eg. to refresh list content)
		TriggerBaseEvent(GameEventKeys.Station_OnResume, Null, Self)

		return True
	End Method


	Method RenewContract:int(duration:Long)
		'reset warning state
		SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, False)

		return True
	End Method


	Method CanSignContract:int(duration:Long) {_exposeToLua}
		return True
	End Method


	Method SignContract:int(duration:Long)
		'reset warning state
		SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, False)

		runningCosts = -1

		return True
	End Method


	Method CancelContracts:int()
		return True
	End Method


	'override to add satellite connection
	Method OnAddToMap:int()
		return True
	End Method


	'override to remove satellite connection
	Method OnRemoveFromMap:int()
		return True
	End Method


	Method GetSubscriptionTimeLeft:Long()
		return 0
	End Method


	Method GetSubscriptionProgress:Float()
		return 0
	End Method


	Method GetConstructionTime:Int()
		If GameRules.stationConstructionTime = 0 Then Return 0

		'only need to resume...
		if IsShutDown()
			Return 1 * GameRules.stationConstructionTime
		endif

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


	Method GetCurrentRunningCosts:int() {_exposeToLua}
		return 0
	End Method


	'override
	Method GetRunningCosts:int() {_exposeToLua}
		if runningCosts = -1
			runningCosts = GetCurrentRunningCosts()
		endif

		return runningCosts
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

		If GetPlayerFinance(playerID).PayStation( GetBuyPrice() )
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
			If CanActivate() and GetActivationTime() <= GetWorldTime().GetTimeGone()
				if not SetActive()
					print "failed to activate " + GetGUID()
				endif
			EndIf
		EndIf

		'antennas do not have a subscriptionprogress - ignore them
		If GetSubscriptionProgress() > 0
			'automatically refresh subscriptions?
			If HasFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT)
				If GetSubscriptionTimeLeft() <= 0 and GetProvider()
					RenewContract( GetProvider().GetDefaultSubscribedChannelDuration() )
				EndIf
			'inform others that contract ends soon ?
			ElseIf not HasFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT)
				If GetSubscriptionTimeLeft() <= TWorldTime.DAYLENGTH
					SetFlag(TVTStationFlag.WARNED_OF_ENDING_CONTRACT, True)
					'inform others
					TriggerBaseEvent(GameEventKeys.Station_OnContractEndsSoon, null, Self )
				EndIf
			EndIf
		EndIf
	End Method


	'how much a potentially drawn sprite is offset (eg. for a boundary
	'circle like for antennas)
	Method GetOverlayOffsetY:int()
		return 0
	End Method


	Method SetSectionName:int(sectionName:string)
		self._sectionName = sectionName
	End Method


	Method CanSubscribeToProvider:int(duration:Long)
		return True
	End Method


	Method NextReachLevelProbable:Int(owner:Int, newStationReach:Int)
		Local stationMap:TStationMap = GetStationMap(owner)
		Local actualCurrentReach:Int = stationMap.GetReach()
		Local currTime:Long = GetWorldTime().GetTimeGone()
		'add up reach of all stations about to be built
		Local estimatedReachIncrease:Int = newStationReach
		For local station:TStationBase = EachIn GetStationMap(owner).stations
			If Not station.isActive() And station.GetActivationTime() > currTime
				estimatedReachIncrease :+ station.getExclusiveReach()
			EndIf
		Next
		return stationMap.GetReachLevel(actualCurrentReach) < stationMap.GetReachLevel(actualCurrentReach + estimatedReachIncrease)
	End Method


	Method DrawInfoTooltip()
		Local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
		Local showPermissionPriceText:Int
		Local cantGetSectionPermissionReason:Int = 1
		Local cantGetProviderPermissionReason:Int = 1
		Local isNextReachLevelProbable:Int = False
		Local showPriceInformation:Int = False

		if not HasFlag(TVTStationFlag.PAID)
			cantGetProviderPermissionReason = CanSubscribeToProvider(1)
			isNextReachLevelProbable = NextReachLevelProbable(owner, GetExclusiveReach())
			showPriceInformation = True

			if section And section.NeedsBroadcastPermission(owner, stationType)
				showPermissionPriceText = not section.HasBroadcastPermission(owner, stationType)
				cantGetSectionPermissionReason = section.CanGetBroadcastPermission(owner)
			endif
		endif
			

		Local priceSplitH:int = 8
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" )
		Local tooltipW:Int = 190
		Local tooltipH:Int = textH * 3 + 10 + 5

		If showPriceInformation Then tooltipH :+ priceSplitH

		'show build time?
		If GetConstructionTime() > 0 then tooltipH :+ textH
		'display increase?
		If stationType = TVTStationType.ANTENNA then tooltipH :+ textH
		'display required channel image for permission?
		If cantGetSectionPermissionReason <= 0 then tooltipH :+ textH
		'display required channel image for provider?
		If cantGetProviderPermissionReason <= 0 then tooltipH :+ textH
		'display broadcast permission price?
		If showPermissionPriceText > 0
			tooltipH :+ 2*textH
		EndIf
		'warn about potential reach level increase?
		If isNextReachLevelProbable Then tooltipH :+ textH

		If showPermissionPriceText > 0 or cantGetSectionPermissionReason <= 0 or isNextReachLevelProbable
			tooltipW :+ 40
		EndIf

		Local tooltipX:Int = x - tooltipW/2
		Local tooltipY:Int = y - GetOverlayOffsetY() - tooltipH - 5

		'move below station if at screen top
		If tooltipY < 10 Then tooltipY = y + GetOverlayOffsetY() + 5
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
		fontBold.DrawSimple( getLocale("MAP_COUNTRY_"+GetSectionName()), textX, textY, new SColor8(250,200,100), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH + 5

		font.Draw(GetLocale("REACH")+": ", textX, textY)
		fontBold.DrawBox(TFunctions.convertValue(GetReach(), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		textY:+ textH

		if stationType = TVTStationType.ANTENNA
			font.Draw(GetLocale("INCREASE")+": ", textX, textY)
			fontBold.DrawBox(TFunctions.convertValue(GetExclusiveReach(), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			textY:+ textH
		endif

		If GetConstructionTime() > 0
			font.Draw(GetLocale("CONSTRUCTION_TIME")+": ", textX, textY)
			fontBold.DrawBox(GetConstructionTime()+"h", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			textY:+ textH
		EndIf


		If cantGetSectionPermissionReason = -1
			font.Draw(GetLocale("CHANNEL_IMAGE")+" ("+GetLocale("STATIONMAP_SECTION_NAME")+"): ", textX, textY)
			fontBold.DrawBox(MathHelper.NumberToString(section.broadcastPermissionMinimumChannelImage,2)+" %", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, new SColor8(255,150,150))
			textY:+ textH
		EndIf
		If cantGetProviderPermissionReason = -1
			local minImage:Float
			local provider:TStationMap_BroadcastProvider = GetProvider()
			if provider then minImage = provider.minimumChannelImage

			font.Draw(GetLocale("CHANNEL_IMAGE")+" ("+GetLocale("PROVIDER")+"): ", textX, textY)
			fontBold.DrawBox(MathHelper.NumberToString(minImage,2)+" %", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, new SColor8(255,150,150))
			textY:+ textH
		EndIf

		if showPriceInformation
			textY:+ priceSplitH

			local totalPrice:int
			if not showPermissionPriceText
				'always request the _current_ (refreshed) price
				totalPrice = GetBuyPrice()
			else
				font.Draw(GetTypeName()+": ", textX, textY)
				fontBold.DrawBox(TFunctions.DottedValue(GetBuyPrice()) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
				textY:+ textH

				font.Draw(GetLocale("BROADCAST_PERMISSION")+": ", textX, textY)
				fontBold.DrawBox(TFunctions.DottedValue(section.GetBroadcastPermissionPrice(owner, stationType)) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
				textY:+ textH

				'always request the _current_ (refreshed) price
				totalPrice = GetStationMap(owner).GetTotalStationBuyPrice(self)
			endif

			font.Draw(GetLocale("PRICE")+": ", textX, textY)
			if not GetPlayerFinance(owner).CanAfford(totalPrice)
				fontBold.DrawBox(TFunctions.DottedValue(totalPrice) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, new SColor8(255,150,150))
			else
				fontBold.DrawBox(TFunctions.DottedValue(totalPrice) + " " + GetLocale("CURRENCY"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
			endif
		endif

		if isNextReachLevelProbable
			textY:+ textH
			SetColor 255,150,150
			font.Draw(GetLocale("AUDIENCE_REACH_LEVEL_WILL_INCREASE"), textX, textY)
			SetColor 255,255,255
		endif

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
		Local tooltipX:Int = x - tooltipW/2
		Local tooltipY:Int = y - GetOverlayOffsetY() - tooltipH

		'move below station if at screen top
		If tooltipY < 20 Then tooltipY = y + GetOverlayOffsetY() + 10 +10
		tooltipX = Max(20, tooltipX)
		tooltipX = Min(585 - tooltipW, tooltipX)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX, tooltipY, tooltipW, tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0

		Local textY:Int = tooltipY + 5
		Local textX:Int = tooltipX + 5
		GetBitmapFontManager().baseFontBold.DrawSimple(textCaption, textX, textY, new SColor8(255,190,80), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH + 5

		GetBitmapFontManager().baseFont.Draw(textContent, textX, textY)
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
'Todo: DEPRECATED, remove in v0.8 or later (last in use at 0.6)
Type TStation Extends TStationAntenna {_exposeToLua="selected"}
	Method Init:TStation(x:Int, y:Int, price:Int=-1, owner:Int) override
		Super.Init(x, y, price, owner)
		return self
	End Method
End Type




Type TStationAntenna Extends TStationBase {_exposeToLua="selected"}
	Field radius:Int = 0


	Method New()
		radius = GetStationMapCollection().antennaStationRadius

		stationType = TVTStationType.ANTENNA

		listSpriteNameOn = "gfx_datasheet_icon_antenna.on"
		listSpriteNameOff = "gfx_datasheet_icon_antenna.off"
	End Method


	Method Init:TStationAntenna(x:Int, y:Int, price:Int=-1, owner:Int) override
		Super.Init(x, y, price, owner)
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
		return new TRectangle.Init(x - radius, y - radius, 2*radius, 2*radius)
	End Method


	Method GetReachMax:Int(refresh:Int=False) override {_exposeToLua}
		'not cached?
		If reachMax < 0 or refresh
			reachMax = GetStationMapCollection().CalculateTotalAntennaStationReach(x, y, radius)
		endif
		return reachMax
	End Method


	'reachable with current stationtype share
	Method GetReach:Int(refresh:Int=False) override {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			return GetReachMax(refresh)

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			'more exact approach (if SHARES DIFFER between sections) would be to
			'find split the area into all covered sections and calculate them
			'individually - then sum them up for the total reach amount

			local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			if not section or section.populationAntennaShare < 0
				return GetReachMax(refresh) * GetStationMapCollection().GetCurrentPopulationAntennaShare()
			else
				return GetReachMax(refresh) * section.populationAntennaShare
			endif
		EndIf

		return GetReachMax(refresh)
	End Method


	'reached audience not shared with another stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) override {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			'as stations might broadcast to other sections too (crossing
			'borders) you cannot ignore stations in sections which are
			'covered by satellites/cable networks
			'so you will have to check _all_ covered sections

			'easiest approach: calculate reach "WITH - WITHOUT" station
			'TODO
			Throw "TStationAntenna.GetExclusiveReach() TODO"

			'not cached yet?
			if reachExclusiveMax < 0 or refresh
				reachExclusiveMax = GetStationMap(owner).CalculateAntennaAudienceIncrease(x, y, radius)
			endif

			return reachExclusiveMax

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			'not cached yet?
			if reachExclusiveMax < 0 or refresh
				If GetStationMap(owner).HasStation(self)
					reachExclusiveMax = GetStationMap(owner).CalculateAntennaAudienceDecrease(self)
				Else
					reachExclusiveMax = GetStationMap(owner).CalculateAntennaAudienceIncrease(x, y, radius)
				EndIf
			endif

			'this is NOT correct - as the other sections (overlapping)
			'might have other antenna share values
			'-> better replace that once we settled to a specific
			'   variant - exclusive or not - and multiply with a individual
			'   receiverShare-Map for all the pixels covered by the antenna
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
			if not section or section.populationAntennaShare < 0
				return reachExclusiveMax * GetStationMapCollection().GetCurrentPopulationAntennaShare()
			else
				return reachExclusiveMax * section.populationAntennaShare
			endif

			return reachExclusiveMax
		EndIf

		return reachExclusiveMax
	End Method


	'override
	Method GetBuyPrice:Int() {_exposeToLua}
		'If HasFlag(TVTStationFlag.FIXED_PRICE) and price >= 0 Then Return price

		'price corresponds to "possibly reachable" not actually reached
		'persons...
		'so during changes between antenna-satellite-cable the price
		'"effectivity" changes.

		'when refreshing also check for a new section name (might be a
		'to-place-station)
		local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
		'return an odd price (if someone sees it...)
		if not section then return -1337

		local buyPrice:int = 0

		'construction costs
		if not IsShutdown()
			local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)
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
			buyPrice :+ 0.20 * GetStationMapCollection().CalculateTotalAntennaStationReach(x, y, 20)
		endif


		'no further costs


		'round it to 25000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 25000)) * 25000 )


		Return buyPrice
	End Method


	'override
	Method GetCurrentRunningCosts:int() {_exposeToLua}
		if HasFlag(TVTStationFlag.NO_RUNNING_COSTS) then return 0

		local result:int = 0

		'== ADD STATIC RUNNING COSTS ==
		result :+ 5000 * ceil(GetBuyPrice() / 25000.0)

		'== ADD RELATIVE MAINTENANCE COSTS ==
		if GameRules.stationIncreaseDailyMaintenanceCosts
			'the older a station gets, the more the running costs will be
			'(more little repairs and so on)
			'2% per day
			local maintenanceCostsPercentage:int = GameRules.stationDailyMaintenanceCostsPercentage * GetAgeInDays()
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
			DrawOval(x - radius - 2, y - radius -2, 2 * (radius + 2), 2 * (radius + 2))

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
		DrawOval(x - radius, y - radius, 2 * radius, 2 * radius)
		color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
		DrawOval(x - radius + 2, y - radius + 2, 2 * (radius - 2), 2 * (radius - 2))


		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(x, y + 1, -1, ALIGN_CENTER_CENTER)
	End Method
End Type




Type TStationCableNetworkUplink extends TStationBase {_exposeToLua="selected"}
	Field hardwareCosts:int = 65000
	Field maintenanceCosts:int = 15000


	Method New()
		listSpriteNameOn = "gfx_datasheet_icon_cable_network_uplink.on"
		listSpriteNameOff = "gfx_datasheet_icon_cable_network_uplink.off"

		stationType = TVTStationType.CABLE_NETWORK_UPLINK
	End Method


	Method Init:TStationCableNetworkUplink(x:Int, y:Int, price:Int=-1, owner:Int) override
		Super.Init(x, y, price, owner)

		return self
	End Method


	'override
	Method GenerateGUID:string()
		return "station-cable_network-uplink-"+id
	End Method


	'override
	Method GetTypeName:string() {_exposeToLua}
		return GetLocale("CABLE_NETWORK_UPLINK")
	End Method


	Method GetLongName:string() {_exposeToLua}
		return GetLocale("MAP_COUNTRY_"+GetSectionName())
	End Method


	Method GetProvider:TStationMap_BroadcastProvider()
		if not providerGUID then return Null
		return GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
	End Method


	'override
	Method CanActivate:int()
		local provider:TStationMap_BroadcastProvider = GetProvider()
		if not provider then return False

		if not provider.IsLaunched() then return False
		if not provider.IsSubscribedChannel(self.owner) then return False

		return True
	End Method


	Method RenewContract:int(duration:Long)
		if not providerGUID then Return False 'Throw "Renew CableNetworkUplink without valid cable network guid."

		'inform cable network
		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if cableNetwork
			rem
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
			if not cableNetwork.SubscribeChannel(self.owner, duration )
				return False
			endif

			'fetch new running costs (no setup fees)
			runningCosts = - 1
		endif

		return Super.RenewContract(duration)
	End Method


	Method CanSubscribeToProvider:int(duration:Long)
		if not providerGUID then return False

		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if cableNetwork then return cableNetwork.CanSubscribeChannel(self.owner, duration)

		return True
	End Method


	'override to check if already subscribed
	Method CanSignContract:int(duration:Long)  {_exposeToLua}
		if not Super.CanSignContract(duration) then return False

		if CanSubscribeToProvider(duration) <= 0 then return False

		return True
	End Method


	'override to add satellite connection
	Method SignContract:int(duration:Long)
		if not providerGUID then Throw "Sign to CableNetworkLink without valid cable network guid."
		if not CanSignContract(duration) then return False

		'inform cable network
		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if cableNetwork
			if duration < 0 then duration = cableNetwork.GetDefaultSubscribedChannelDuration()
			if not cableNetwork.SubscribeChannel(self.owner, duration )
				return False
			endif
		endif

		return Super.SignContract(duration)
	End Method


	'override to remove satellite connection
	Method CancelContracts:int()
		'inform cableNetwork
		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if cableNetwork
			if not cableNetwork.UnsubscribeChannel(owner)
				return False
			endif
		endif

		return Super.CancelContracts()
	End Method


	Method GetSubscriptionTimeLeft:Long()
		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if not cableNetwork then return 0

		local endTime:long = cableNetwork.GetSubscribedChannelEndTime(owner)
		if endTime < 0 then return 0

		return endTime - GetWorldTime().GetTimeGone()
	End Method


	Method GetSubscriptionProgress:Float()
		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if not cableNetwork then return 0

		local startTime:long = cableNetwork.GetSubscribedChannelStartTime(owner)
		local duration:long = cableNetwork.GetSubscribedChannelDuration(owner)
		if duration < 0 then return 0

		return MathHelper.Clamp(float((GetworldTime().GetTimeGone() - startTime) / Double(duration)), 0.0, 1.0)
	End Method


	'override
	Method GetBuyPrice:Int() {_exposeToLua}
'		If price >= 0 And Not refresh Then Return price

		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if not cableNetwork then return 0

		local section:TStationMapSection = GetStationMapCollection().GetSectionByName( GetSectionName() )
		if not section
			print "Cablenetwork without section."
			return -1337
		endif

		local buyPrice:int = 0

		'construction costs
		if not IsShutdown()
			local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)

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
		endif


		'cable network provider costs
		buyPrice :+ cableNetwork.GetSetupFee(owner)


		'round it to 5000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 5000)) * 5000 )

		Return buyPrice
	End Method


	'override
	Method GetSellPrice:Int() {_exposeToLua}
		'sell price = cancel costs
		'cancel costs depend on the days a contract has left

		local expense:int
		'pay the provider for canceling earlier
		expense = (1.0 - GetSubscriptionProgress())^2 * 3 * GetRunningCosts()
		
		return -expense
	End Method


	'override
	Method GetCurrentRunningCosts:int() {_exposeToLua}
		if HasFlag(TVTStationFlag.NO_RUNNING_COSTS) then return 0

		local result:int

		'add specific costs
		if providerGUID
			local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
			if cableNetwork
				result :+ cableNetwork.GetDailyFee(owner)
			endif
		endif

		'maintenance costs for the uplink to the cable network
		result :+ maintenanceCosts

		return result
	End Method


	Method GetReachMax:Int(refresh:Int=False) override {_exposeToLua}
		if reachMax <= 0 or refresh
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
			if section then reachMax = section.GetPopulation()
		endif

		return reachMax
	End Method


	Method GetReach:Int(refresh:Int=False) override {_exposeToLua}
		'always return the satellite's reach - so it stays dynamically
		'without the hassle of manual "cache refreshs"
		'If reach >= 0 And Not refresh Then Return reach

		local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
		if not cableNetwork then return 0

		return cableNetwork.GetReach(refresh)
	End Method


	'reached audience not shared with other stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) {_exposeToLua}
		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			'not cached yet?
			if reachExclusiveMax < 0 or refresh
				local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
				if not cableNetwork
					reachExclusiveMax = 0
					return reachExclusiveMax
				endif

				'satellites
				'if a satellite covers the section, then no increase will happen
				if GetStationMap(owner).GetSatelliteUplinksCount()
					reachExclusiveMax = 0
					return reachExclusiveMax
				endif
				'cable networks
				'if there is another cable network covering the same section,
				'then no increase will happen
				'if reach is calculated for self while already added,
				'check if another is existing too
				local cableNetworks:int = GetStationMap(owner).GetCableNetworkUplinksInSectionCount(GetSectionName())
				if GetStationMap(owner).HasCableNetworkUplink(self) and cableNetworks > 1
					reachExclusiveMax = 0
					return reachExclusiveMax
				elseif cableNetworks > 0
					reachExclusiveMax = 0
					return reachExclusiveMax
				endif

				reachExclusiveMax = cableNetwork.GetReach()

				'subtract section population for all antennas in that area
				local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
				reachExclusiveMax :- section.GetAntennaAudienceSum( owner )
			endif

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(providerGUID)
			if not cableNetwork
				reachExclusiveMax = 0
			else
				reachExclusiveMax = cableNetwork.GetReach(refresh)
			endif
		EndIf

		return reachExclusiveMax
	End Method


	Method DrawBackground(selected:Int=False, hovered:Int=False)
		local section:TStationMapSection = GetStationMapCollection().GetSectionByName(GetSectionName())
		if not section then return

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		Local color:TColor
		Select owner
			Case 1,2,3,4	color = TPlayerColor.GetByOwner(owner)
			Default			color = TColor.clWhite
		End Select


		if selected or hovered
			if selected
				SetColor 255,255,255
				SetAlpha 0.3
				DrawImage(section.GetSelectedImage(), section.rect.GetX(), section.rect.GetY())

				SetAlpha Float(0.2 * Sin(Time.GetAppTimeGone()/4) * oldA) + 0.3
				SetBlend LightBlend
				section.GetHighlightBorderSprite().Draw(section.rect.GetX(), section.rect.GetY())
				SetColor(oldCol)
				SetAlpha(oldA)
				SetBlend AlphaBlend
			endif

			if hovered
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
			endif
		else
			SetAlpha oldA * 0.3
			color.SetRGB()
			'color.Copy().Mix(TColor.clWhite, 0.75).SetRGB()
			section.GetShapeSprite().Draw(section.rect.GetX(), section.rect.GetY())
			SetColor(oldCol)
			SetAlpha(oldA)
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
		sprite.Draw(x, y + 1, -1, ALIGN_CENTER_CENTER)
	End Method
End Type




Type TStationSatelliteUplink extends TStationBase {_exposeToLua="selected"}
	Field hardwareCosts:int = 95000
	Field maintenanceCosts:int = 25000


	Method New()
		listSpriteNameOn = "gfx_datasheet_icon_satellite_uplink.on"
		listSpriteNameOff = "gfx_datasheet_icon_satellite_uplink.off"

		stationType = TVTStationType.SATELLITE_UPLINK
	End Method


	Method Init:TStationSatelliteUplink(x:Int, y:Int, price:Int=-1, owner:Int) override
		Super.Init(x, y, price, owner)

		return self
	End Method


	'override
	Method GenerateGUID:string()
		return "station-satellite-uplink-"+id
	End Method


	'override
	Method GetLongName:string() {_exposeToLua}
		if not providerGUID
			return GetLocale("UNUSED_TRANSMITTER")
		else
			return GetName()
		endif
'		if GetName() then return GetTypeName() + " " + GetName()
'		return GetTypeName()
	End Method


	'override
	Method GetName:string() {_exposeToLua}
		if providerGUID
			local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
			if satellite then return GetLocale("SATUPLINK_TO_X").Replace("%X%", satellite.name)
		endif
		return Super.GetName()
	End Method


	'override
	Method GetTypeName:string() {_exposeToLua}
		return GetLocale("SATELLITE_UPLINK")
	End Method


	Method GetProvider:TStationMap_BroadcastProvider()
		if not providerGUID then return Null
		return GetStationMapCollection().GetSatelliteByGUID(providerGUID)
	End Method


	'override
	Method CanActivate:int()
		local provider:TStationMap_BroadcastProvider = GetProvider()
		if not provider then return False

		if not provider.IsLaunched() then return False
		if not provider.IsSubscribedChannel(self.owner) then return False

		return True
	End Method


	Method RenewContract:int(duration:Long)
		if not providerGUID then return False 'Throw "Renew a Satellitelink to map without valid satellite guid."

		'inform satellite
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if satellite
			rem
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
			if not satellite.SubscribeChannel(self.owner, duration )
				return False
			endif

			'fetch new running costs (no setup fees)
			runningCosts = - 1
		endif

		return Super.RenewContract(duration)
	End Method


	Method CanSubscribeToProvider:int(duration:Long)
		if not providerGUID then return False

		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if satellite then return satellite.CanSubscribeChannel(self.owner, duration)

		return True
	End Method


	'override to check if already subscribed
	Method CanSignContract:int(duration:Long) {_exposeToLua}
		if not Super.CanSignContract(duration) then return False

		if CanSubscribeToProvider(duration) <= 0 then return False

		return True
	End Method


	'override to add satellite connection
	Method SignContract:int(duration:Long)
		if not providerGUID then Throw "Signing a Satellitelink to map without valid satellite guid."
		if not CanSignContract(duration) then return False

		'inform satellite
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if satellite
			if duration < 0 then duration = satellite.GetDefaultSubscribedChannelDuration()
			if not satellite.SubscribeChannel(self.owner, duration )
				print "sign contract: failed to subscribe to channel"
			endif
		endif

		if IsShutDown() then Resume()

		return Super.SignContract(duration)
	End Method


	'override to remove satellite connection
	Method CancelContracts:int()
		'inform satellite
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if satellite
			satellite.UnsubscribeChannel(owner)
		endif

		return Super.CancelContracts()
	End Method


	Method GetSubscriptionTimeLeft:Long()
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if not satellite then return 0

		local endTime:long = satellite.GetSubscribedChannelEndTime(owner)
		if endTime < 0 then return 0

		return endTime - GetWorldTime().GetTimeGone()
	End Method


	Method GetSubscriptionProgress:Float()
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if not satellite then return 0

		local startTime:long = satellite.GetSubscribedChannelStartTime(owner)
		local duration:Long = satellite.GetSubscribedChannelDuration(owner)
		if duration < 0 then return 0

		return MathHelper.Clamp(Float((GetWorldTime().GetTimeGone() - startTime) / Double(duration)), 0.0, 1.0)
	End Method


	'override
	Method GetSellPrice:Int() {_exposeToLua}
		'sell price = cancel costs
		'cancel costs depend on the days a contract has left

		local expense:int
		'pay the provider for cancelingearlier
		expense = (1.0 - GetSubscriptionProgress())^2 * 3 * GetRunningCosts()

		return -expense
	End Method


	'override
	Method GetCurrentRunningCosts:int() {_exposeToLua}
		if HasFlag(TVTStationFlag.NO_RUNNING_COSTS) then return 0

		local result:int

		'add specific costs
		if providerGUID
			local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
			if satellite
				result :+ satellite.GetDailyFee(owner)
			endif
		endif

		'maintenance costs for the uplink to the satellite
		result :+ maintenanceCosts

		return result
	End Method


	'override
	Method GetBuyPrice:Int() {_exposeToLua}
		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if not satellite then return 0


		'all sat uplinks are build in the same section
		local uplinkSectionName:string = GetStationMapCollection().GetSatelliteUplinkSectionName()
		if not uplinkSectionName then Throw "no section choosen for satellite uplinks."

		local section:TStationMapSection = GetStationMapCollection().GetSectionByName( uplinkSectionName )
		if not section
			print "Satellite Uplink without assigned section."
			return -1337
		endif

		local channelSympathy:Float = section.GetPressureGroupsChannelSympathy(owner)

		local buyPrice:int = 0

		'construction costs
		if not IsShutdown()
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
		endif


		'costs for the satellite provider
		buyPrice :+ satellite.GetSetupFee(owner)


		'round it to 5000-steps
		buyPrice = Max(0 , Int(Ceil(buyPrice / 5000)) * 5000 )


		Return buyPrice
	End Method


	Method GetReachMax:Int(refresh:Int=False) override {_exposeToLua}
		if reachMax < 0 or refresh
			reachMax = GetStationMapCollection().GetPopulation()
		endif

		return reachMax
	End Method


	Method GetReach:Int(refresh:Int=False) override {_exposeToLua}
		'always return the satellite's reach - so it stays dynamically
		'without the hassle of manual "cache refreshs"
		'If reach >= 0 And Not refresh Then Return reach

		local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
		if not satellite then return 0

		return satellite.GetReach()
	End Method


	'reached audience not shared with other stations (antennas, cable, ...)
	Method GetExclusiveReach:Int(refresh:Int=False) override {_exposeToLua}
		'not cached yet?
		if reachExclusiveMax < 0 or refresh
			local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID(providerGUID)
			if not satellite
				reachExclusiveMax = 0
			else
				reachExclusiveMax = satellite.GetExclusiveReach()
			endif
		endif
		return reachExclusiveMax
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
	Field pressureGroups:int

	Field broadcastPermissionPrice:int = -1
	Field broadcastPermissionMinimumChannelImage:Float = 0
	Field broadcastPermissionsGiven:int[4]

	Field cableNetworkCount:int = 0
	Field activeCableNetworkCount:int = 0

	'sympathy of the section's government for the individual channels
	Field channelSympathy:Float[]
	
	'(local) position inside the section
	Field uplinkPos:TVec2I
	
	Field name:String
	Field populationImage:TImage {nosave}
	Field populationMap:int[,] {nosave}
	Field population:int = -1
	Field populationCableShare:Float = -1
	Field populationSatelliteShare:Float = -1
	Field populationAntennaShare:Float = -1
	'grid/array/mapmap containing bitmask-coded information for "used" pixels
	Field antennaShareGrid:Byte[] = Null {nosave}
	Field antennaShareGridValid:Int = False {nosave}
	Field antennaShareGridWidth:int {nosave}
	Field antennaShareGridHeight:int {nosave}
	'Field antennaShareMapImage:TImage {nosave}
	Field shareCache:TStringMap = new TStringMap {nosave}
	Field calculationMutex:TMutex = CreateMutex() {nosave}
	Field shareCacheMutex:TMutex = CreateMutex() {nosave}
	Field antennaShareMutex:TMutex = CreateMutex() {nosave}


	Method New()
		channelSympathy = new Float[4]
		broadcastPermissionsGiven = new Int[4]
	End Method


	Method Create:TStationMapSection(pos:SVec2I, name:String, shapeSpriteName:String, config:TData = null)
		Self.shapeSpriteName = shapeSpriteName
		Self.rect = New TRectangle.Init(pos.x, pos.y, 0, 0)
		Self.name = name
		LoadShapeSprite()

		if config
			If config.Has("pressureGroups") 
				pressureGroups = config.GetInt("pressureGroups")
			EndIf
			If config.Has("broadcastPermissionPrice") 
				broadcastPermissionPrice = config.GetInt("broadcastPermissionPrice")
			EndIf
			If config.Has("broadcastPermissionMinimumChannelImage") 
				broadcastPermissionMinimumChannelImage = config.GetFloat("broadcastPermissionMinimumChannelImage")
			EndIf

			If config.Has("uplinkX") and config.Has("uplinkY")
				uplinkPos = new TVec2I(config.GetInt("uplinkX"), config.GetInt("uplinkY"))
			EndIf
		endif

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
		if not shapeSprite then LoadShapeSprite()
		return shapeSprite
	End Method


	Method GetHighlightBorderSprite:TSprite()
		if not highlightBorderSprite
			local highlightBorderImage:TImage = ConvertToOutLine( GetShapeSprite().GetImage(), 5, 0.5, $FFFFFFFF , 9 )
			blurPixmap(LockImage( highlightBorderImage ), 0.5)

			highlightBorderSprite = new TSprite.InitFromImage(highlightBorderImage, "highlightBorderImage")
			highlightBorderSprite.offset = new SRectI(9,9,0,0)
		endif
		return highlightBorderSprite
	End Method


	Method GetHoveredImage:TImage()
		if not hoveredImage
			'create a pure white variant of the shape
			hoveredImage = ConvertToSingleColor( GetShapeSprite().GetImage(), $FFFFFFFF )
		endif
		return hoveredImage
	End Method


	Method GetSelectedImage:TImage()
		if not selectedImage
			selectedImage = ConvertToSingleColor( GetShapeSprite().GetImage(), $FF000000 )
		endif
		return selectedImage
	End Method


	Method GetDisabledOverlay:TImage()
		if not disabledOverlay
			local shapePix:TPixmap = LockImage(GetShapeSprite().GetImage())
			local sourcePix:TPixmap = LockImage(GetSpriteFromRegistry("map_Surface").GetImage())
			local pix:TPixmap = ExtractPixmapFromPixmap(sourcePix, shapePix, rect.GetIntX(), rect.GetIntY())
			disabledOverlay = LoadImage( AdjustPixmapSaturation(pix, 0.20) )
			'disabledOverlay = ConvertToSingleColor( disabledOverlay, $FF999999 )
		endif
		return disabledOverlay
	End Method


	Method GetEnabledOverlay:TImage()
		if not enabledOverlay
			local shapePix:TPixmap = LockImage(GetShapeSprite().GetImage())
			local sourcePix:TPixmap = LockImage(GetSpriteFromRegistry("map_Surface").GetImage())
			local pix:TPixmap = ExtractPixmapFromPixmap(sourcePix, shapePix, rect.GetIntX(), rect.GetIntY())
			enabledOverlay = LoadImage( pix )
		endif
		return enabledOverlay
	End Method
	
	
	Method IsValidUplinkPos:Int(localX:int, localY:int)
		local mapX:int = rect.GetX() + localX 
		local mapY:int = rect.GetY() + localY
		Local isValid:Int = False

		Local sprite:TSprite = GetShapeSprite()
		If not sprite Then return False
		If not sprite._pix Then sprite._pix = sprite.GetPixmap()

		'check if that spot collides with another state
		If PixelIsOpaque(sprite._pix, localX, localy)
			isValid = True

			For local otherSection:TStationMapSection = EachIn GetStationMapCollection().sections
				if self = otherSection then continue

				Local otherLocalX:Int = mapX - otherSection.rect.GetX()
				Local otherLocalY:Int = mapY - otherSection.rect.GetY()
				Local otherSprite:TSprite = otherSection.GetShapeSprite()
				If otherSprite 
					If not otherSprite._pix Then otherSprite._pix = otherSprite.GetPixmap()

					if otherLocalX >= 0 and otherLocalY >= 0 and otherLocalX < otherSection.rect.GetIntW() and otherLocalY < otherSection.rect.GetIntH()
						If PixelIsOpaque(otherSprite._pix, otherLocalX, otherLocalY) > 0
							isValid = False
						EndIf
					EndIf
				EndIf
			Next
		EndIf
		Return isValid
	End Method
	
	
	Method GetLocalUplinkPos:TVec2I()
		if not uplinkPos
			'try center of section first
			local localX:int = rect.GetXCenter() - rect.GetX()
			local localY:int = rect.GetYCenter() - rect.GetY()
			'check if that spot collides with another state
			If not IsValidUplinkPos(localX, localY)
				Local mapPos:SVec2I = GetStationMapCollection().GetRandomAntennaCoordinateInSection(self, False)
				'make local position
				uplinkPos = new TVec2I(mapPos.x - rect.position.GetIntX(), mapPos.y - rect.position.GetIntY())
			Else
				uplinkPos = new TVec2I(localX, localY)
			EndIf
		endif
		return uplinkPos
	End Method


	Method DoCensus()
		'refresh stats (cable, sat, antenna share, ... maybe target
		'groups share)
	End Method


	'ID might be a combination of multiple groups
	Method SetPressureGroups:int(pressureGroupID:int, enable:int=True)
		If enable
			pressureGroups :| pressureGroupID
		Else
			pressureGroups :& ~pressureGroupID
		EndIf
	End Method


	Method GetPressureGroups:int()
		return pressureGroups
	End Method


	Method HasPressureGroups:int(pressureGroupID:int)
		return pressureGroups & pressureGroupID
	End Method


	Method GetPressureGroupsChannelSympathy:Float(channelID:int)
		if pressureGroups = 0 then return 0
		return GetPressureGroupCollection().GetChannelSympathy(channelID, pressureGroups)
	End Method


	Method BuyBroadcastPermission:int(channelID:int, stationType:int = -1, price:int = -1)
		if not NeedsBroadcastPermission(channelID, stationType) then return False
		if HasBroadcastPermission(channelID, stationType) then return False

		if price = -1 then price = GetBroadcastPermissionPrice(channelID, stationType)
		if GetPlayerFinance(channelID) and GetPlayerFinance(channelID).PayBroadcastPermission( price )
			TLogger.Log("StationMap", "Player " + channelID + " bought broadcast permission for ~q"+GetLocale("MAP_COUNTRY_"+name)+"~q.", LOG_DEBUG)

			SetBroadcastPermission(channelID, True, stationType)
			return True
		endif
		return False
	End Method


	'returns whether a channel needs a permission for the given station type
	'or not - regardless of whether the channel HAS one or not
	Method NeedsBroadcastPermission:int(channelID:int, stationType:int = -1)
		If stationType = TVTStationType.ANTENNA
			Local startYear:Int = GetWorldTime().GetStartYear()
			if startYear > 1996
				return false
			endif
		endif
		return True
	End Method


	Method HasBroadcastPermission:int(channelID:int, stationType:int = -1)
		if channelID < 1 or channelID > broadcastPermissionsGiven.length then return 0
		return broadcastPermissionsGiven[channelID-1]
	End Method


	Method SetBroadcastPermission(channelID:int, bool:int, stationType:int = -1)
		if channelID < 1 or channelID > broadcastPermissionsGiven.length then return
		broadcastPermissionsGiven[channelID-1] = bool
	End Method


	Method GetChannelSympathy:Float(channelID:int)
		if channelID < 1 or channelID > channelSympathy.length then return 0
		return channelSympathy[channelID-1]
	End Method


	Method SetChannelSympathy(channelID:int, value:Float)
		if channelID < 1 or channelID > channelSympathy.length then return
		channelSympathy[channelID-1] = MathHelper.Clamp(value, -1.0, 1.0)
	End Method


	Method GetBroadcastPermissionPrice:int(channelID:int, stationType:int=-1)
		'fixed price
		if broadcastPermissionPrice <> -1 then return broadcastPermissionPrice

		'calculate based on population (maybe it changes)
		'or some other effects
		local result:int = GetPopulation()/25000 * 25000

		'adjust by sympathy (up to 25% discount or 25% on top)
		result :- 0.25 * result * GetChannelSympathy(channelID)

		return result
	End Method


	Method GetPropertyAquisitionCosts:int(stationType:int=-1)
		Select stationType
			case TVTStationType.ANTENNA
				return 35000
			case TVTStationType.CABLE_NETWORK_UPLINK
				return 30000
			case TVTStationType.SATELLITE_UPLINK
				return 50000
			default
				return 0
		End Select
	End Method


	Method ReachesMinimumChannelImage:int(channelID:int)
		if GetPublicImage(channelID).GetAverageImage() < broadcastPermissionMinimumChannelImage then return False

		return True
	End Method


	Method CanGetBroadcastPermission:int(channelID:int)
		if not ReachesMinimumChannelImage(channelID) then return -1

		return True
	End Method


	Method DrawChannelStatusTooltip(channelID:int, stationType:int = -1)
		Local priceSplitH:int = 8
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" )
		Local tooltipW:Int = 190
		Local tooltipH:Int = textH * 4 + 10 + 5
		Local tooltipX:Int = MouseManager.x - tooltipW/2
		Local tooltipY:Int = MouseManager.y - tooltipH - 5
'		Local tooltipX:Int = rect.GetXCenter() - tooltipW/2
'		Local tooltipY:Int = rect.GetYCenter() - tooltipH - 5


		Local permissionOK:int = not NeedsBroadcastPermission(channelID, stationType) or HasBroadcastPermission(channelID, stationType)
		Local imageOK:int = ReachesMinimumChannelImage(channelID)
		Local providerOK:int = GetStationMapCollection().GetCableNetworksInSectionCount(self.name, True) > 0

		'move below station if at screen top
		If tooltipY < 10 Then tooltipY = MouseManager.y + 25
'		If tooltipY < 10 Then tooltipY = 10
		tooltipX = MathHelper.Clamp(tooltipX, 20, GetGraphicsManager().GetWidth() - tooltipW - 20)

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()

		SetAlpha oldA * 0.5
		if not providerOK or not permissionOK or not imageOK
			SetColor 75,0,0
		else
			SetColor 0,0,0
		endif
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor(oldCol)
		SetAlpha(oldA)

		Local textY:Int = tooltipY+5
		Local textX:Int = tooltipX+5
		Local textW:Int = tooltipW-10
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		fontBold.DrawSimple( GetLocale("MAP_COUNTRY_"+name), textX, textY, new SColor8(250,200,100), EDrawTextEffect.Shadow, 0.2)
		textY:+ textH + 5

		'broadcast permission
		GetBitmapFontManager().baseFont.draw(GetLocale("CABLE_NETWORKS")+": ", textX, textY)
		if not providerOK
			fontBold.DrawBox("0", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, new SColor8(255, 150, 150))
		else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		endif
		textY:+ textH

		'broadcast permission
		GetBitmapFontManager().baseFont.draw(GetLocale("BROADCAST_PERMISSION")+": ", textX, textY)
		if not permissionOK
			fontBold.DrawBox(TFunctions.convertValue(GetBroadcastPermissionPrice(channelID, stationType), 2), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		endif
		textY:+ textH

		GetBitmapFontManager().baseFont.Draw(GetLocale("CHANNEL_IMAGE")+": ", textX, textY)
		if not imageOK
			fontBold.DrawBox(MathHelper.NumberToString(GetPublicImage(channelID).GetAverageImage(), 2)+"% < "+MathHelper.NumberToString(broadcastPermissionMinimumChannelImage, 2)+"%", textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, new SColor8(255, 150, 150))
		else
			fontBold.DrawBox(GetLocale("OK"), textX, textY-1, textW, 20, sALIGN_RIGHT_TOP, SColor8.White)
		endif
		textY:+ textH
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

		Local sectionPix:TPixmap
		Local sprite:TSprite = GetShapeSprite()
		If not sprite._pix Then sprite._pix = sprite.GetPixmap()

		'copy whats left on the sections image
		For local x:int = startX until endX
			For local y:int = startY until endY
				If PixelIsOpaque(sprite._pix, Int(x-rect.getX()), Int(y-rect.getY())) > 0
					pix.WritePixel(int(x-rect.getX()), int(y-rect.getY()), sourcePix.ReadPixel(x, y) )
				endif
			Next
		Next
	End Method


	Method CalculatePopulation:int()
'		If not TryLockMutex(calculationMutex)
'			Notify "CalculatePopulation: concurrent access found!"
			LockMutex(calculationMutex)
'		EndIf

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
		
		UnlockMutex(calculationMutex)
		
		return population
	End Method


	Method GetPopulation:int()
		if population < 0 then CalculatePopulation()
		return population
	End Method


	private
	Function GeneratePositionKey:Long(x:Int, y:Int)
		Return Long(x) Shl 32 | Long(y)
	End Function
	public


	'returns the shared amount of audience between channels
	Method GetShareAudience:Int(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetReceiverShare(includeChannelMask, excludeChannelMask).shared
	End Method


	Method GetSharePercentage:Float(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		Return GetReceiverShare(includeChannelMask, excludeChannelMask).populationShareRatio
	End Method


	Method GetPopulationCableShareRatio:Float()
		if populationCableShare < 0 then return GetStationMapCollection().GetCurrentPopulationCableShare()
		return populationCableShare
	End Method

	Method GetPopulationAntennaShareRatio:Float()
		if populationAntennaShare < 0 then return GetStationMapCollection().GetCurrentPopulationAntennaShare()
		return populationAntennaShare
	End Method

	Method GetPopulationSatelliteShareRatio:Float()
		if populationSatelliteShare < 0 then return GetStationMapCollection().GetCurrentPopulationSatelliteShare()
		return populationSatelliteShare
	End Method


	'summary: returns maximum audience a player reach with satellites
	Method GetSatelliteAudienceSum:Int()
		return population * GetPopulationSatelliteShareRatio()
	End Method


	'summary: returns maximum audience a player reach with a cablenetwork
	Method GetCableNetworkAudienceSum:Int()
		return population * GetPopulationCableShareRatio()
	End Method


	'summary: returns maximum audience a player reaches with antennas
	Method GetAntennaAudienceSum:Int(playerID:int)
		'passing only the playerID and no other playerIDs is returning
		'the playerID's audience (with share/total being useless)
		Local includeChannelMask:SChannelMask = new SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = new SChannelMask()
		Return GetAntennaReceiverShare( includeChannelMask, excludeChannelMask ).total
	End Method


	Method GetExclusiveAntennaAudienceSum:Int(playerID:int)
		Local includeChannelMask:SChannelMask = new SChannelMask().Set(playerID)
		Local excludeChannelMask:SChannelMask = includeChannelMask.Negated()
		Return GetAntennaReceiverShare(includeChannelMask, excludeChannelMask).total
	End Method


	Method GetAntennaShareGrid:Byte[]()
		if not antennaShareGridValid or not antennaShareGrid or antennaShareGrid.length = 0
			LockMutex(antennaShareMutex)

			antennaShareGrid = new Byte[populationImage.width * populationImage.height]
			antennaShareGridWidth = populationImage.width
			antennaShareGridHeight = populationImage.height

			Local antennaStationRadius:int = GetStationMapCollection().antennaStationRadius
			Local antennaStationRadiusSquared:int = antennaStationRadius * antennaStationRadius
			Local shapeSprite:TSprite = GetShapeSprite()
			If not shapeSprite._pix Then shapeSprite._pix = shapeSprite.GetPixmap()
			Local circleRectX:Int, circleRectY:Int, circleRectX2:Int, circleRectY2:int
			Local shareMask:TStationMapShareMask
			Local posX:Int = 0
			Local posY:Int = 0
			Local stationX:Int = 0
			Local stationY:Int = 0
			Local shareKey:Long
			For local map:TStationMap = EachIn GetStationMapCollection().stationMaps
				'Local ownerMask:Byte = GetMaskIndex(map.owner)
				Local ownerMask:Byte = (1 shl (map.owner-1))

				if map.cheatedMaxReach
					'insert the players bitmask-number into the field
					'and if there is already one ... add the number
					For posX = 0 To populationImage.width-1
						For posY = 0 To populationImage.height-1
							'left the topographic borders ?
							If not PixelIsOpaque(shapeSprite._pix, posX, posY) > 0 then continue

							Local index:Int = posY * antennaShareGridWidth + posX
							'adjust mask
							antennaShareGrid[index] :| ownerMask
						Next
					Next
				else

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
						stationX = station.x - rect.GetX()
						stationY = station.y - rect.GetY()

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
								
								If not PixelIsOpaque(shapeSprite._pix, posX, posY) > 0 then continue

								Local index:Int = posY * antennaShareGridWidth + posX
								antennaShareGrid[index] :| ownerMask
							Next
						Next
					Next
				endif
			Next

			antennaShareGridValid = True
			UnLockMutex(antennaShareMutex)
		endif
		return antennaShareGrid
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
		local result:SStationMapPopulationShare

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			Throw "GetShare: TODO"
			'result.Add( GetMixedShare(channelMask) )
		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			result :+ GetAntennaReceiverShare(includeChannelMask, excludeChannelMask)
			result :+ GetCableNetworkReceiverShare(includeChannelMask, excludeChannelMask)
		EndIf
		return result
	End Method


	Method GetCableNetworkReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		return GetCableNetworkPopulationShare(includeChannelMask, excludeChannelMask).Copy().MultiplyFactor(GetPopulationCableShareRatio())
	End Method


	Method GetAntennaReceiverShare:SStationMapPopulationShare(includeChannelMask:SChannelMask, excludeChannelMask:SChannelMask)
		return GetAntennaPopulationShare(includeChannelMask, excludeChannelMask).Copy().MultiplyFactor(GetPopulationAntennaShareRatio())
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
			Local channelsWithCableNetwork:Int = 0
			'amount of non-ignored channels
			Local interestingChannelsCount:Int
			Local allHaveCableNetwork:Int = False

			allHaveCableNetwork = True
			For local channelID:int = 1 to GetStationMapCollection().stationMaps.length
				'ignore unwanted
				If not includeChannelMask.Has(channelID) Then continue
				'skip if to exclude - exclusive reaches requested
				If excludeChannelMask.Has(channelID) Then continue

				interestingChannelsCount :+ 1

				if GetStationMap(channelID).GetCableNetworkUplinksInSectionCount( name ) > 0
					channelsWithCableNetwork :+ 1
				else
					allHaveCableNetwork = False
				endif
			Next


			result = new TStationMapPopulationShare
			if channelsWithCableNetwork > 0
				'total - if there is at least _one_ channel uses a cable network here
				result.value.total = population

				'share is only available if we checked some channels
				if interestingChannelsCount > 0
					'share - if _all_ channels use a cable network here
					if allHaveCableNetwork
						result.value.shared = population
					endif

					'share percentage
					result.value.populationShareRatio =  channelsWithCableNetwork / Float(interestingChannelsCount)
				endif
			endif

			'store new cached data
			If shareCache 
				LockMutex(shareCacheMutex)
				shareCache.insert(cacheKey, result)
				UnlockMutex(shareCacheMutex)
			EndIf
			
			'print "CABLE uncached: "+cacheKey
			'print "CABLE share:  total="+int(result.y)+"  share="+int(result.x)+"  share="+(result.z*100)+"%"
		else
			'print "CABLE cached: "+cacheKey
			'print "CABLE share:  total="+int(result.y)+"  share="+int(result.x)+"  share="+(result.z*100)+"%"
		EndIf

		'disabled: GetCableNetworkAudienceSum() already contains the share multiplication)
		'Return result.Copy().MultiplyFactor( Float(GetStationMapCollection().GetCurrentPopulationCableShare()) )
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
			For Local mapX:Int = 0 until antennaShareGridWidth 
				For Local mapY:Int = 0 until antennaShareGridHeight
					Local index:Int = mapY * antennaShareGridWidth + mapX
					Local mask:Byte = shareGrid[index]
					'skip if none of our interested is here
					If includeChannelMask.HasNone(mask) Then Continue
					'skip if one of the to exclude is here
					If not excludeChannelMask.HasNone(mask) Then Continue

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
			'print "ANTENNA share:  total="+int(result.y)+"  share="+int(result.x)+"  share="+(result.z*100)+"%"
		else
			'print "ANTENNA cached: "+cacheKey
			'print "ANTENNA share:  total="+int(result.y)+"  share="+int(result.x)+"  share="+(result.z*100)+"%"
		EndIf

		Return result.value
	End Method



	'params of advanced types (no ints, strings, bytes) are automatically
	'passed "by reference" (change it here, and it is changed globally)
	Method _FillAntennaPoints(map:TLongMap, stationX:Int, stationY:Int, radius:int, color:Int)
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
		Local radiusSquared:int = radius * radius
		Local sprite:TSprite = GetShapeSprite()
		If not sprite Then Return
		If not sprite._pix Then sprite._pix = sprite.GetPixmap()

		For local posX:int = sectionStationIntersectRect.getX() To sectionStationIntersectRect.getX2()-1
			For local posY:int = sectionStationIntersectRect.getY() To sectionStationIntersectRect.getY2()-1
				'left the circle?
				If CalculateDistanceSquared( posX - stationX, posY - stationY ) > radiusSquared Then Continue
				'If CalculateDistance( posX - stationX, posY - stationY ) > radius Then Continue
				'left the topographic borders ?
				If not PixelIsOpaque(sprite._pix, posX, posY) > 0 then continue

				map.Insert(GeneratePositionKey(posX, posY), New TStationMapAntennaPoint(posX , posY, color))
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
print "  sprite: " + GetShapeSprite().GetWidth()+","+GetShapeSprite().GetHeight()
print "  sectionStationIntersectRect: " + sectionStationIntersectRect.ToString()
endrem

		' calc sum for current coord
		Local result:Int = 0
		local radiusSquared:Int = radius * radius
		Local sprite:TSprite = GetShapeSprite()
		If not sprite Then Return 0
		If not sprite._pix Then sprite._pix = sprite.GetPixmap()


		For local posX:int = sectionStationIntersectRect.getX() To sectionStationIntersectRect.getX2()-1
			For local posY:int = sectionStationIntersectRect.getY() To sectionStationIntersectRect.getY2()-1
				'left the circle?
				If CalculateDistanceSquared( posX - stationX, posY - stationY ) > radiusSquared Then Continue
				'If CalculateDistance( posX - stationX, posY - stationY ) > radius Then Continue
				'left the topographic borders ?
				If Not PixelIsOpaque(sprite._pix, posX, posY) > 0 then continue
				result :+ populationmap[posX, posY]
			Next
		Next

		Return result
	End Method


	Method CalculateAntennaAudienceDecrease:Int(stations:TList, removeStation:TStationAntenna)
		If Not removeStation Then Return 0
		'if station is not hitting the section
		if not removeStation.GetRect().Intersects(rect) then Return 0

		Local Points:TLongMap = New TLongMap
		Local result:Int = 0

		'mark the station points of the to remove as "2"
		'mark all others (except the given one) as "1"
		'-> then count on all spots still "2"

		Self._FillAntennaPoints(Points, Int(removeStation.x), Int(removeStation.y), removeStation.radius, 2)

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
			if not station.GetRect().Intersects(removeStation.GetRect()) then continue

			Self._FillAntennaPoints(Points, Int(station.x), Int(station.y), station.radius, 1)
		Next

		'count all "still 2" spots
		For Local point:TStationMapAntennaPoint = EachIn points.Values()
			If point.value = 2
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
			if not station.GetRect().Intersects(rect) then continue

			'skip antennas not overlapping the station to add
			if not station.GetRect().Intersects(stationRect) then continue

			Self._FillAntennaPoints(Points, Int(station.x), Int(station.y), station.radius, 1)
		Next

		'all points still "2" are what will be added in addition to existing ones
		For Local point:TStationMapAntennaPoint = EachIn points.Values()
			If point.value = 2
				result :+ populationmap[point.x, point.y]
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
	Field x:Int
	Field y:Int
	Field mask:Int
	
	Method New(x:Int, y:Int, mask:Int)
		self.x = x
		self.y = y
		self.mask = mask
	End Method
End Type




Type TStationMapAntennaPoint
	Field x:Int
	Field y:Int
	Field value:Int
	
	Method New(x:Int, y:Int, value:Int)
		self.x = x
		self.y = y
		self.value = value
	End Method
End Type




Type TStationMapPopulationShare
	Field value:SStationMapPopulationShare
End Type




Struct SStationMapPopulationShare
	Field shared:Int 'in people
	Field total:Int 'in people
	Field populationShareRatio:Float 'ratio of total population
	
	Method GetShareRatio:Float()
		if total = 0 then return 0
		Return shared/total
	End Method
	
	
	Method Copy:SStationMapPopulationShare()
		local c:SStationMapPopulationShare
		c.shared = self.shared
		c.total = self.total
		c.populationShareRatio = self.populationShareRatio
		return c
	End Method
	
	
	Method Add:SStationMapPopulationShare(other:SStationMapPopulationShare)
		self.shared :+ other.shared
		self.total :+ other.total
		self.populationShareRatio :+ other.populationShareRatio
	End Method
	

	Method MultiplyFactor:SStationMapPopulationShare(factor:Float)
		self.shared :* factor
		self.total :* factor
		self.populationShareRatio :* factor
		Return self
	End Method


    Method Operator :+(other:SStationMapPopulationShare)
		self.shared :+ other.shared
		self.total :+ other.total
		self.populationShareRatio :+ other.populationShareRatio
    End Method
End Struct



'cable network, satellite ... providers which allows booking of
'channel capacity
Type TStationMap_BroadcastProvider extends TEntityBase {_exposeToLua="selected"}
	Field name:string

	'minimum image needed to be able to subscribe
	Field minimumChannelImage:Float
	'the lobbies behind the satellite owner - so their standing
	'with a channel affects prices/fees
	Field pressureGroups:int

	'limit for currently subscribed channels
	Field channelMax:int = 5
	'channelIDs for channels currently subscribed to the satellite
	Field subscribedChannels:int[]
	'when do their contracts start and end?
	Field subscribedChannelsStartTime:Long[]
	Field subscribedChannelsDuration:Long[]

	Field launched:int = False
	Field launchTime:long
	Field lifeTime:long = -1
	'eg. signal strength
	'used to evaluate which satellite the people would prefer
	'when comparing them (-> populationShare)
	'satellites could get upgrades by sat company for higher quality
	'or wear off...
	Field quality:int = 100
	'to see whether it increased or not (increase if "best" satellite
	'stops working and quality lowers)
	Field oldQuality:int = 100

	'costs
	Field dailyFeeMod:Float = 1.0
	Field setupFeeMod:Float = 1.0
	Field setupFeeBase:int = 500000
	Field dailyFeeBase:int = 75000

	Field exclusiveReach:Int = -1
	'potentially reachable Max
	Field reachMax:Int = -1

	Field listSpriteNameOn:string = "gfx_datasheet_icon_antenna.on"
	Field listSpriteNameOff:string = "gfx_datasheet_icon_antenna.off"


	Method GetName:string() {_exposeToLua}
		return name
	End Method


	'ID might be a combination of multiple groups
	Method SetPressureGroups:int(pressureGroupID:int, enable:int=True)
		If enable
			pressureGroups :| pressureGroupID
		Else
			pressureGroups :& ~pressureGroupID
		EndIf
	End Method


	Method GetPressureGroups:int()
		return pressureGroups
	End Method


	Method HasPressureGroups:int(pressureGroupID:int)
		return pressureGroups & pressureGroupID
	End Method


	Method GetPressureGroupsChannelSympathy:Float(channelID:int)
		if pressureGroups = 0 then return 0
		return GetPressureGroupCollection().GetChannelSympathy(channelID, pressureGroups)
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


	Method ExtendSubscribedChannelDuration:Long(channelID:int, extendBy:int)
		local i:int = GetSubscribedChannelIndex(channelID)
		if i = -1 then return -1

		subscribedChannelsDuration[i] :+ extendBy
		return True
	End Method


	Method GetDefaultSubscribedChannelDuration:Long()
		'return 0.25 * GetWorldTime().GetYearLength()
		return GetWorldTime().GetYearLength()
	End Method


	Method GetSubscribedChannelCount:int() {_exposeToLua}
		if not subscribedChannels then return 0
		return subscribedChannels.length
	End Method


	Method IsSubscribedChannel:int(channelID:int) {_exposeToLua}
		For local i:int = EachIn subscribedChannels
			if i = channelID then return True
		Next
		return False
	End Method


	Method CanSubscribeChannel:int(channelID:int, duration:Long=-1) {_exposeToLua}
		if minimumChannelImage > 0 and minimumChannelImage > GetPublicImage(channelID).GetAverageImage() then return -1
		if channelMax >= 0 and subscribedChannels.length >= channelMax then return -2

		return 1
	End Method


	Method SubscribeChannel:int(channelID:int, duration:Long, force:Int=False)
		if not force and CanSubscribeChannel(channelID, duration) <> 1 then return False

		if IsSubscribedChannel(channelID)
			local i:int = GetSubscribedChannelIndex(channelID)
			if i = -1 then return -1

			subscribedChannelsStartTime[i] = GetWorldTime().GetTimeGone()
			subscribedChannelsDuration[i] = duration

		else
			subscribedChannels :+ [channelID]
			subscribedChannelsStartTime :+ [GetWorldTime().GetTimeGone()]
			subscribedChannelsDuration :+ [duration]
		endif

		return True
	End Method


	Method UnsubscribeChannel:int(channelID:int)
		local index:int = -1
		For local i:int = 0 until subscribedChannels.length
			if subscribedChannels[i] = channelID then index = i
		Next
		if index = -1 then return False

		subscribedChannels = subscribedChannels[.. index] + subscribedChannels[index+1 ..]
		subscribedChannelsStartTime = subscribedChannelsStartTime[.. index] + subscribedChannelsStartTime[index+1 ..]
		subscribedChannelsDuration = subscribedChannelsDuration[.. index] + subscribedChannelsDuration[index+1 ..]

		return True
	End Method


	Method GetReach:Int(refresh:Int=False) {_exposeToLua}
		return 0
	End Method


	Method GetSetupFee:Int(channelID:Int) {_exposeToLua}
		local channelSympathy:Float = GetPressureGroupsChannelSympathy(channelID)
		local price:int

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
		local channelSympathy:Float = GetPressureGroupsChannelSympathy(channelID)
		local price:int

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


	Method IsActive:int() {_exposeToLua}
		'for now we only check "launched" but satellites could need a repair...
		return launched
	End Method


	Method IsLaunched:int() {_exposeToLua}
		return launched
	End Method


	Method Launch:int()
		if launched then return False

		launched = True

		'inform others
		TriggerBaseEvent(GameEventKeys.BroadcastProvider_OnLaunch, Null, Self)

		return True
	End Method


	Method SetActive:Int(force:int = False)
		If IsActive() Then Return False

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.BroadcastProvider_OnSetActive, Null, Self)
	End Method


	Method SetInactive:Int()
		If Not IsActive() Then Return False

		'inform others (eg. to recalculate audience)
		TriggerBaseEvent(GameEventKeys.BroadcastProvider_OnSetInactive, Null, Self)
	End Method


	Method Update:int()
		if not launched
			if launchTime < GetWorldTime().GetTimeGone()
				Launch()
			endif
		endif
	End Method


	'run extra so you could update station (and its subscription) after
	'a launch/start of the provider but before it removes uplinks
	Method UpdateSubscriptions:int()
		For local i:int = 0 until subscribedChannels.length
			if subscribedChannels[i] and subscribedChannelsDuration[i] >= 0
				if subscribedChannelsStartTime[i] + subscribedChannelsDuration[i] < GetWorldTime().GetTimeGone()
					local channelID:int = subscribedChannels[i]

					'(indirectly) inform concerning stationlink
					GetStationMapCollection().RemoveUplinkFromBroadcastProvider(self, channelID)

					'finally unsubscripe (do _after_ uplink removal
					'as else a uplink identification via channelID would fail)
					UnsubscribeChannel(channelID)
				endif
			endif
		Next
	End Method
End Type




'excuse naming scheme but "TCableNetwork" is ambiguous for "stationtypes"
Type TStationMap_CableNetwork extends TStationMap_BroadcastProvider {_exposeToLua="selected"}
	'operators
	Field sectionName:string {_exposeToLua}


	'override
	Method GenerateGUID:string()
		return "stationmap-cablenetwork-"+id
	End Method


	Method GetReachMax:Int(refresh:Int=False) {_exposeToLua}
		'not cached?
		If reachMax < 0 or refresh
			if not sectionName then return 0

			local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
			if not section then return 0

			reachMax = section.GetPopulation()
		endif
		return reachMax
	End Method


	Method GetReach:Int(refresh:Int=False) {_exposeToLua}
		local result:int

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			result = GetReachMax()

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			result = GetReachMax()
			local section:TStationMapSection = GetStationMapCollection().GetSectionByName(sectionName)
			if not section then return 0

			if section.populationCableShare < 0
				result :* GetStationMapCollection().GetCurrentPopulationCableShare()
			else
				result :* section.populationCableShare
			endif
		EndIf

		Return result
	End Method


	Method GetName:string() {_exposeToLua}
		return name.replace("%name%", GetLocale("MAP_COUNTRY_"+sectionName))
	End Method


	'override
	Method Launch:int()
		if not Super.Launch() then return False

		GetStationMapCollection().OnLaunchCableNetwork(self)
		TLogger.Log("CableNetwork.Launch", "Launching cable network ~q"+GetName()+"~q. Reach: " + GetReach() +"  Date: " + GetWorldTime().GetFormattedGameDate(launchTime), LOG_DEBUG)

		return True
	End Method
End Type




'excuse naming scheme but "TSatellite" is ambiguous for "stationtypes"
Type TStationMap_Satellite extends TStationMap_BroadcastProvider {_exposeToLua="selected"}
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
	Field brandName:string

	Field nextImageReductionTime:Long = -1
	Field nextImageReductionValue:Float = 0.97
	Field nextTechUpgradeTime:Long = -1
	Field nextTechUpgradeValue:int = 0
	Field techUpgradeSpeed:int
	Field deathTime:Long = -1
	'is death decided (no further changes possible)
	'this allows ancestores/other revisions to get launched then
	Field deathDecided:int = False
	'version of the satellite
	Field revision:int = 1


	Method New()
		techUpgradeSpeed = BiasedRandRange(75,125, 0.5) '75-125%

		listSpriteNameOn = "gfx_datasheet_icon_satellite_uplink.on"
		listSpriteNameOff = "gfx_datasheet_icon_satellite_uplink.off"
	End Method


	'override
	Method GenerateGUID:string()
		return "stationmap-satellite-"+id
	End Method


	Method GetReachMax:Int(refresh:Int=False) {_exposeToLua}
		'not cached?
		If reachMax < 0 or refresh
			reachMax = GetStationMapCollection().GetPopulation()
		endif
		return reachMax
	End Method


	Method GetReach:Int(refresh:int = False) {_exposeToLua}
		local result:int

		If TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_SHARED
			result = GetReachMax(refresh)

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			'sum up all sections
			'this allows individual satelliteReceiveRatios for the sections
			for local s:TStationMapSection = EachIn GetStationMapCollection().sections
				result :+ s.GetSatelliteAudienceSum()
			next
			'result = GetStationMapCollection().GetPopulation()
			'result :* GetStationMapCollection().GetCurrentPopulationSatelliteShare()
		EndIf

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
			return exclusiveReach

		ElseIf TStationMapCollection.populationReceiverMode = TStationMapCollection.RECEIVERMODE_EXCLUSIVE
			exclusiveReach = GetReach(refresh)
		Else

			exclusiveReach = 0
		EndIf

		return exclusiveReach
	End Method


	'override
	Method GetDefaultSubscribedChannelDuration:Long()
		if deathTime <= 0 then return Super.GetDefaultSubscribedChannelDuration()
		'days are rounded down, so they always are lower than the real life time
		local daysToDeath:int = (deathTime - GetWorldTime().GetTimeGone()) / TWorldTime.DAYLENGTH

		return Min(Super.GetDefaultSubscribedChannelDuration(), daysToDeath * TWorldTime.DAYLENGTH)
	End Method


	'override
	Method Launch:int()
		if not Super.Launch() then return False

		'set death to be somewhere in 8-12 years
		deathTime = GetWorldTime().ModifyTime(launchTime, RandRange(8,12), 0, 0, RandRange(200,800))

		GetStationMapCollection().OnLaunchSatellite(self)
		TLogger.Log("Satellite.Launch", "Launching satellite ~q"+name+"~q. Reach: " + GetReach() +"  Date: " + GetWorldTime().GetFormattedGameDate(launchTime) +"  Death: " + GetWorldTime().GetFormattedGameDate(deathTime), LOG_DEBUG)

		return True
	End Method



	Method Update:int()
		Super.Update()

		'no research, death ... if already decided to stop soon
		if IsLaunched() and not deathDecided
			'death in <3 days?
			if deathTime - 3*TWorldTime.dayLength < GetWorldTime().GetTimeGone()
				deathDecided = True
				GetStationMapCollection().OnLetDieSatellite(self)
			endif

			if nextTechUpgradeTime < GetWorldTime().GetTimeGone()
				if nextTechUpgradeTime > 0
					quality :+ nextTechUpgradeValue
					'inform others (eg. for news)
					TriggerBaseEvent(GameEventKeys.Satellite_OnUpgradeTech, New TData.AddInt("quality", quality).Addint("oldQuality", quality - nextTechUpgradeValue), Self )
					'print "satellite " + name +" upgraded technology " + (quality - nextTechUpgradeValue) +" -> " + quality
				endif

				nextTechUpgradeTime = GetWorldTime().ModifyTime(-1, 0, 0, int(RandRange(250,350) * 100.0/techUpgradeSpeed))
				nextTechUpgradeValue = BiasedRandRange(10, 25, 0.2) * 100.0/techUpgradeSpeed
			endif


			if minimumChannelImage > 0.1 and nextImageReductionTime < GetWorldTime().GetTimeGone()
				if nextImageReductionTime > 0
					local oldMinimumChannelImage:Float = minimumChannelImage
					minimumChannelImage :* nextImageReductionValue
					'avoid reducing very small values for ever and ever
 					if minimumChannelImage <= 0.1 then minimumChannelImage = 0
					'inform others (eg. for news)
					TriggerBaseEvent(GameEventKeys.Satellite_OnReduceMinimumChannelImage, New TData.AddFloat("minimumChannelImage", minimumChannelImage).AddFloat("oldMinimumChannelImage", oldMinimumChannelImage), Self )
				endif

				nextImageReductionTime = GetWorldTime().ModifyTime(-1, 0, 0, int(RandRange(20,30)))
				nextImageReductionValue = nextImageReductionValue^2
			endif
		endif
	End Method
End Type





Struct SChannelMask
	Field Readonly value:Int
	
	Method New(value:Int)
		self.value = value
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
		Local mask:int = value
		
		While mask
			mask = mask & (mask - 1)
			count:+ 1
		Wend
		
		Return count
	End Method
End Struct
