REM
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
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "game.player.finance.bmx"
Import "basefunctions.bmx"

'parent of all stationmaps
Type TStationMapCollection
	'list of stationmaps
	Field stationMaps:TStationMap[4]
	'map containing bitmask-coded information for "used" pixels
	Field shareMap:TMap = Null {nosave}
	Field shareCache:TMap = Null {nosave}
	Field stationRadius:Int = 15
	Field population:Int = 0 {nosave}
	Field populationmap:Int[,] {nosave}
	Field populationMapSize:TPoint = new TPoint.Init() {nosave}

	Field mapConfigFile:string = ""

	'difference between screen0,0 and pixmap
	'->needed movement to have population-pixmap over country
	Global populationMapOffset:TPoint = new TPoint.Init(20, 10)
	Global _initDone:int = FALSE
	Global _instance:TStationMapCollection


	Method New()
		_instance = self

		if not _initDone
			'to refresh share map on buy/sell of stations
			EventManager.registerListenerFunction( "stationmap.addStation",	onChangeStations )
			EventManager.registerListenerFunction( "stationmap.removeStation",	onChangeStations )

			'handle savegame loading (reload the map configuration)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)
			'handle <stationmapdata>-area in loaded xml files
			EventManager.registerListenerFunction("RegistryLoader.onLoadResourceFromXML", onLoadStationMapData, null, "STATIONMAPDATA" )

			_initdone = TRUE
		Endif
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TStationMapCollection", "Savegame loaded - reloading map data", LOG_DEBUG | LOG_SAVELOAD)

		_instance.LoadMapFromXML()
	End Function


	'run when an xml contains an <stationmapdata>-area
	Function onLoadStationMapData:int(triggerEvent:TEventBase)
		Local mapDataRootNode:TxmlNode = TxmlNode(triggerEvent.GetData().Get("xmlNode"))
		Local registryLoader:TRegistryLoader = TRegistryLoader(triggerEvent.GetSender())
		if not mapDataRootNode or not registryLoader then return FALSE

		Local densityNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "densitymap")
		If not densityNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><densitymap>-entry.")

		Local surfaceNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "surface")
		If not surfaceNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <stationmapdata><surface>-entry.")

		'directly load the given resources
		registryLoader.LoadSingleResourceFromXML(densityNode, TRUE, new TData.AddString("name", "map_PopulationDensity"))
		registryLoader.LoadSingleResourceFromXML(surfaceNode, TRUE, new TData.AddString("name", "map_Surface"))

		'=== LOAD STATES ===
		'remove old states
		TStationMapSection.Reset()

		'find and load states configuration
		Local statesNode:TxmlNode = TXmlHelper.FindChild(mapDataRootNode, "states")
		If not statesNode Then Throw("File ~q"+_instance.mapConfigFile+"~q misses the <map><states>-area.")

		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(statesNode)
			Local name:String	= TXmlHelper.FindValue(child, "name", "")
			Local sprite:String	= TXmlHelper.FindValue(child, "sprite", "")
			Local pos:TPoint	= new TPoint.Init( TXmlHelper.FindValueInt(child, "x", 0), TXmlHelper.FindValueInt(child, "y", 0) )
			'add state section if data is ok
			If name<>"" And sprite<>""
				New TStationMapSection.Create(pos,name, sprite).add()
			Endif
		Next
	End Function


	'load a map configuration from a specific xml file
	'eg. "germany.xml"
	'we use xmlLoader so image ressources in the file get autoloaded
	Method LoadMapFromXML:int(xmlFile:string="")
		if xmlFile <> "" then mapConfigFile = xmlFile

		Local start:Int = MilliSecs()

		'=== LOAD XML CONFIG ===
		local registryLoader:TRegistryLoader = new TRegistryLoader
		registryLoader.LoadFromXML(mapConfigFile, TRUE)
		TLogger.Log("TStationMapCollection.LoadMapFromXML", "config parsed", LOG_LOADING)

		'=== INIT MAP DATA ===
		CreatePopulationMap()

		Return True
	End Method


	Method CreatePopulationMap()
		local start:int = Millisecs()
		Local srcPix:TPixmap = GetPixmapFromRegistry("map_PopulationDensity")
		if not srcPix
			TLogger.Log("TStationMapCollection.CreatePopulationMap", "pixmap ~qmap_PopulationDensity~q is missing.", LOG_LOADING)
			Throw("TStationMap: ~qmap_PopulationDensity~q missing.")
			return
		endif

		'move pixmap so it overlays the rest
		Local pix:TPixmap = CreatePixmap(srcPix.width + populationMapOffset.x, srcPix.height + populationMapOffset.y, srcPix.format)
		pix.ClearPixels(0)
		pix.paste(srcPix, populationMapOffset.x, populationMapOffset.y)

		populationMap = new Int[pix.width + 20, pix.height + 20]
		populationMapSize.SetXY(pix.width, pix.height)

		'read all inhabitants of the map
		Local i:Int, j:Int, c:int, s:int = 0
		population = 0
		For j = 0 To pix.height-1
			For i = 0 To pix.width-1
				c = pix.ReadPixel(i, j)
				If ARGB_ALPHA(pix.ReadPixel(i, j)) = 0 Then Continue
				populationmap[i, j] = getPopulationForBrightness( ARGB_RED(c) )
				population:+ populationmap[i, j]
			Next
		Next
		TLogger.Log("TStationMapCollection.CreatePopulationMap", "calculated a population of:" + population + " in "+(MilliSecs()-start)+"ms", LOG_LOADING)
	End Method


	Method Add:int(map:TStationMap)
		'check boundaries
		If map.owner < 1 or map.owner > stationMaps.length return FALSE
		'add to array array - zerobased
		stationMaps[map.owner-1] = map
		return TRUE
	End Method


	Method Remove:int(map:TStationMap)
		'check boundaries
		If map.owner < 1 or map.owner > stationMaps.length return FALSE
		'remove from array - zero based
		stationMaps[map.owner-1] = Null
		return TRUE
	End Method


	'return the stationmap of other players
	'do not expose to Lua... else they get access to buy/sell
	Method GetMap:TStationMap(playerID:Int)
		'check boundaries
		If playerID < 1 or playerID > stationMaps.length
			Throw "StationMapCollection.GetMap: playerID ~q"+playerID+"~q is out of bounds."
		Endif

		'remove until not thrown for ages
		If stationMaps[playerID-1] and stationMaps[playerID-1].owner <> playerID
			Throw("StationMapCollection: station order corrupt?!")
		EndIf

		'zero based
		Return stationMaps[playerID-1]
	End Method


	'returns the average reach of all stationmaps
	Method GetAverageReach:int()
		local reach:int = 0
		local mapCount:int = 0
		For local map:TStationMap = eachin stationMaps
			reach :+ map.GetReach()
			mapCount :+ 1
		Next
		return reach/mapCount
	End Method


	Method GenerateShareMap:Int()
		'reset values
		shareMap = New TMap
		'reset cache here too
		shareCache = New TMap

		'define locals outside of that for loops...
		Local posX:Int		= 0
		Local posY:Int		= 0
		Local stationX:Int	= 0
		Local stationY:Int	= 0
		Local mapKey:String	= ""
		Local mapValue:TPoint = Null
		Local rect:TRectangle = new TRectangle.Init(0,0,0,0)
		For Local stationmap:TStationMap = EachIn stationMaps
			For Local station:TStation = EachIn stationmap.stations
				'mark the area within the stations circle
				posX = 0
				posY = 0
				stationX = Max(0, station.pos.x)
				stationY = Max(0, station.pos.y)
				Rect.position.SetXY( Max(stationX - stationRadius,stationRadius), Max(stationY - stationRadius,stationRadius) )
				Rect.dimension.SetXY( Min(stationX + stationRadius, Self.populationMapSize.x-stationRadius), Min(stationY + stationRadius, Self.populationMapSize.y-stationRadius) )

				For posX = Rect.getX() To Rect.getW()
					For posY = Rect.getY() To Rect.getH()
						' left the circle?
						If Self.calculateDistance( posX - stationX, posY - stationY ) > stationRadius Then Continue

						'insert the players bitmask-number into the field
						'and if there is already one ... add the number
						mapKey = posX+","+posY
						mapValue = new TPoint.Init(posX,posY, getMaskIndex(stationmap.owner) )
						If shareMap.Contains(mapKey)
							mapValue.z = Int(mapValue.z) | Int(TPoint(shareMap.ValueForKey(mapKey)).z)
						EndIf
						shareMap.Insert(mapKey, mapValue)
					Next
				Next
			Next
		Next
	End Method



	'returns the shared amount of audience between players
	Method GetShareAudience:Int(playerIDs:Int[], withoutPlayerIDs:Int[]=Null)
		Return GetShare(playerIDs, withoutPlayerIDs).x
	End Method


	Method GetSharePercentage:Float(playerIDs:Int[], withoutPlayerIDs:Int[]=Null)
		Return GetShare(playerIDs, withoutPlayerIDs).z
	End Method


	'returns a share between players, encoded in a tpoint containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Method GetShare:TPoint(playerIDs:Int[], withoutPlayerIDs:Int[]=Null)
		If playerIDs.length <1 Then Return new TPoint.Init(0,0,0.0)
		If Not withoutPlayerIDs Then withoutPlayerIDs = New Int[0]
		Local cacheKey:String = ""
		For Local i:Int = 0 To playerIDs.length-1
			cacheKey:+ "_"+playerIDs[i]
		Next
		cacheKey:+"_without_"
		For Local i:Int = 0 To withoutPlayerIDs.length-1
			cacheKey:+ "_"+withoutPlayerIDs[i]
		Next

		'if already cached, save time...
		If shareCache And shareCache.contains(cacheKey) Then Return TPoint(shareMap.ValueForKey(cacheKey))

		Local map:TMap				= GetShareMap()
		Local result:TPoint			= new TPoint.Init(0,0,0.0)
		Local share:Int				= 0
		Local total:Int				= 0
		Local playerFlags:Int[]
		Local allFlag:Int			= 0
		Local withoutPlayerFlags:Int[]
		Local withoutFlag:Int		= 0
		playerFlags					= playerFlags[.. playerIDs.length]
		withoutPlayerFlags			= withoutPlayerFlags[.. withoutPlayerIDs.length]

		For Local i:Int = 0 To playerIDs.length-1
			'player 1=1, 2=2, 3=4, 4=8 ...
			playerFlags[i]	= getMaskIndex( playerIDs[i] )
			allFlag :| playerFlags[i]
		Next

		For Local i:Int = 0 To withoutPlayerIDs.length-1
			'player 1=1, 2=2, 3=4, 4=8 ...
			withoutPlayerFlags[i]	= getMaskIndex( withoutPlayerIDs[i] )
			withoutFlag :| withoutPlayerFlags[i]
		Next


		Local someoneUsesPoint:Int	= False
		Local allUsePoint:Int		= False
		For Local mapValue:TPoint = EachIn map.Values()
			someoneUsesPoint		= False
			allUsePoint				= False

			'we need to check if one on our ignore list is there
				'no need to do this individual, we can just check the groupFlag
				Rem
				local someoneUnwantedUsesPoint:int	= FALSE
				for local i:int = 0 to withoutPlayerFlags.length-1
					if int(mapValue.z) & withoutPlayerFlags[i]
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
				For Local i:Int = 0 To playerFlags.length-1
					If Int(mapValue.z) & playerFlags[i] Then someoneUsesPoint = True;Exit
				Next
			EndIf
			'someone has a station there
			If someoneUsesPoint Then total:+ populationmap[mapValue.x, mapValue.y]
			'all searched have a station there
			If allUsePoint Then share:+ populationmap[mapValue.x, mapValue.y]
		Next
		result.setXY(share, total)
		If total = 0 Then result.z = 0.0 Else result.z = Float(share)/Float(total)
Rem
		print "total: "+total
		print "share:"+share
		print "result:"+result.z
		print "allFlag:"+allFlag
		print "cache:"+cacheKey
		print "--------"
endrem
'TODO: Schauen wieso der Cache-Wert fuer die Quotenberechnung nicht funktioniert
		'add to cache...
		'shareCache.insert(cacheKey, result )

		Return result
	End Method


	Method _FillPoints(map:TMap Var, x:Int, y:Int, color:Int)
		Local posX:Int = 0, posY:Int = 0
		x = Max(0, x)
		y = Max(0, y)
		' innerhalb des Bildes?
		For posX = Max(x - stationRadius,stationRadius) To Min(x + stationRadius, populationMapSize.x-stationRadius)
			For posY = Max(y - stationRadius,stationRadius) To Min(y + stationRadius, populationMapSize.y-stationRadius)
				' noch innerhalb des Kreises?
				If Self.calculateDistance( posX - x, posY - y ) <= stationRadius
					map.Insert(String((posX) + "," + (posY)), new TPoint.Init((posX) , (posY), color ))
				EndIf
			Next
		Next
	End Method


	Method CalculateAudienceIncrease:Int(stations:TList, _x:Int, _y:Int)
		Local Points:TMap = New TMap
		Local returnValue:Int = 0

		'add "new" station which may be bought
		If _x = 0 And _y = 0 Then _x = MouseManager.x; _y = MouseManager.y
		Self._FillPoints(Points, _x,_y, ARGB_Color(255, 0, 255, 255))

		'overwrite with stations owner already has - red pixels get overwritten with white,
		'count red at the end for increase amount
		For Local _Station:TStation = EachIn stations
			If THelper.IsIn(_x,_y, _station.pos.x - 2*stationRadius, _station.pos.y - 2 * stationRadius, 4*stationRadius, 4*stationRadius)
				Self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
			EndIf
		Next

		For Local point:TPoint = EachIn points.Values()
			If ARGB_Red(point.z) = 0 And ARGB_Blue(point.z) = 255
				returnvalue:+ populationmap[point.x, point.y]
			EndIf
		Next
		Return returnvalue
	End Method


	'summary: returns maximum audience a player has
	Method RecalculateAudienceSum:Int(stations:TList)
		Local Points:TMap = New TMap
		For Local _Station:TStation = EachIn stations
			Self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
		Next
		Local returnValue:Int = 0

		For Local point:TPoint = EachIn points.Values()
			If ARGB_Red(point.z) = 255 And ARGB_Blue(point.z) = 255
				returnValue:+ populationmap[point.x, point.y]
			EndIf
		Next
		Return returnValue
	End Method


	Method GetPopulation:int()
		return population
	End Method


	'summary: returns a stations maximum audience reach
	Method CalculateStationReach:Int(x:Int, y:Int)
		Local posX:Int, posY:Int
		Local returnValue:Int = 0
		' calc sum for current coord
		' min/max = everytime within boundaries
		For posX = Max(x - stationRadius,stationRadius) To Min(x + stationRadius, populationMapSize.x - stationRadius)
			For posY = Max(y - stationRadius,stationRadius) To Min(y + stationRadius, populationMapSize.y - stationRadius)
				' still within the circle?
				If calculateDistance( posX - x, posY - y ) <= stationRadius
					returnvalue:+ populationmap[posX, posY]
				EndIf
			Next
		Next
		Return returnValue
	End Method


	'summary: returns calculated distance between 2 points
	Function calculateDistance:Double(x1:Int, x2:Int)
		Return Sqr((x1*x1) + (x2*x2))
	End Function


	Function getMaskIndex:Int(number:Int)
		Local t:Int = 1
		For Local i:Int = 1 To number-1
			t:*2
		Next
		Return t
	End Function


	Function getPopulationForBrightness:Int(value:Int)
		value = Max(5, 255-value)
		value = (value*value)/255 '2 times so low values are getting much lower
		value:* 0.649

		If value > 110 Then value :* 2.0
		If value > 140 Then value :* 1.9
		If value > 180 Then value :* 1.3
		If value > 220 Then value :* 1.1	'population in big cities
		Return 26.0 * value					'population in general
	End Function


	Method GetShareMap:TMap()
		If Not shareMap Then GenerateShareMap()
		Return shareMap
	End Method


	'someone sold or bought a station, call shareMap-Generator
	Function onChangeStations:Int( triggerEvent:TEventBase )
		_instance.GenerateShareMap()
	End Function
End Type
Global StationMapCollection:TStationMapCollection = New TStationMapCollection



Type TStationMap {_exposeToLua="selected"}
	'select whose players stations we want to see
	Field showStations:Int[4]
	'maximum audience possible
	Field reach:Int	= 0
	Field owner:int	= 0
	'all stations of the map owner
	Field stations:TList = CreateList()

	'FALSE to avoid recursive handling (network)
	Global fireEvents:Int = True


	Function Create:TStationMap(playerID:int)
		Local obj:TStationMap = New TStationMap
		obj.owner = playerID
		obj.showStations = [1,1,1,1]

		StationMapCollection.Add(obj)

		Return obj
	End Function


	'returns the maximum reach of the stations on that map
	Method getReach:Int() {_exposeToLua}
		Return Self.reach
	End Method


	Method getCoverage:Float() {_exposeToLua}
		Return Float(getReach()) / Float(StationMapCollection.getPopulation())
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method getTemporaryStation:TStation(x:Int,y:Int)  {_exposeToLua}
		Return TStation.Create(new TPoint.Init(x,y),-1, StationMapCollection.stationRadius, owner)
	End Method


	'return a station at the given coordinates (eg. used by network)
	Method getStation:TStation(x:Int=0,y:Int=0) {_exposeToLua}
		Local pos:TPoint = new TPoint.Init(x, y)
		For Local station:TStation = EachIn stations
			If Not station.pos.isSame(pos) Then Continue
			Return station
		Next
		Return Null
	End Method


	'returns a station of a player at a given position in the list
	Function getStationFromList:TStation(playerID:Int=-1, position:Int=0) {_exposeToLua}
		Local stationMap:TStationMap = StationMapCollection.GetMap(playerID)
		If Not stationMap Then Return Null
		'out of bounds?
		If position < 0 Or position >= stationMap.stations.count() Then Return Null

		Return TStation( stationMap.stations.ValueAtIndex(position) )
	End Function


	'returns the amount of stations a player has
	Method getStationCount:Int(playerID:Int=-1) {_exposeToLua}
		If playerID = owner Then Return stations.count()

		Local stationMap:TStationMap = StationMapCollection.GetMap(playerID)
		If Not stationMap Then Return Null

		Return stationMap.getStationCount(playerID)
	End Method


	'returns maximum audience a player's stations cover
	Method RecalculateAudienceSum:Int() {_exposeToLua}
		reach = StationMapCollection.RecalculateAudienceSum(stations)
		return reach
	End Method


	'returns additional audience when placing a station at the given coord
	Method CalculateAudienceIncrease:Int(x:Int, y:Int) {_exposeToLua}
		return StationMapCollection.CalculateAudienceIncrease(stations, x, y)
	End Method


	'buy a new station at the given coordinates
	Method BuyStation:Int(x:Int,y:Int)
		Return AddStation( getTemporaryStation( x, y ), True )
	End Method


	'sell a station at the given position in the list
	Method SellStation:Int(position:Int)
		Local station:TStation = getStationFromList(position)
		If station Then Return RemoveStation(station, True)
		return False
	End Method


	Method AddStation:Int(station:TStation, buy:Int=False)
		If Not station Then Return False

		'try to buy it (does nothing if already done)
		If buy And Not station.Buy(owner) Then Return False
		'set to paid in all cases
		station.paid = True

		stations.AddLast(station)

		'recalculate audience of channel
		RecalculateAudienceSum()

		TLogger.Log("TStationMap.AddStation", "Player"+owner+" buys broadcasting station for " + station.price + " Euro (increases reach by " + station.reach + ")", LOG_DEBUG)

		'emit an event so eg. network can recognize the change
		If fireEvents Then EventManager.registerEvent( TEventSimple.Create( "stationmap.addStation", new TData.add("station", station), Self ) )

		Return True
	End Method


	Method RemoveStation:Int(station:TStation, sell:Int=False)
		If Not station Then Return False

		'check if we try to sell our last station...
		If stations.count() = 1
			EventManager.triggerEvent(TEventSimple.Create("StationMap.onTrySellLastStation", new TData.addNumber("playerID", owner), self))
			Return False
		EndIf

		If sell And Not station.sell() Then Return False

		stations.Remove(station)

		If sell
			TLogger.Log("TStationMap.AddStation", "Player"+owner+" sells broadcasting station for " + station.getSellPrice() + "Euro (had a reach of " + station.reach + ")", LOG_DEBUG)
		Else
			TLogger.Log("TStationMap.AddStation", "Player"+owner+" trashes broadcasting station for 0 Euro (had a reach of " + station.reach + ")", LOG_DEBUG)
		EndIf

		'recalculate audience of channel
		RecalculateAudienceSum()

		'when station is sold, audience will decrease,
		'while a buy will not increase the current audience but the next block
		'parent.ComputeAudience( TRUE )
		Print "TODO@Manuel: recompute Audience when station is sold"

		'emit an event so eg. network can recognize the change
		If fireEvents Then EventManager.registerEvent( TEventSimple.Create( "stationmap.removeStation", new TData.add("station", station), Self ) )

		Return True
    End Method


	Method CalculateStationCosts:Int()
		Local costs:Int = 0
		For Local Station:TStation = EachIn stations
			costs:+1000 * Ceil(station.price / 50000) ' price / 50 = cost
		Next
		if costs = 0 then Throw "CalculateStationCosts: Player without stations (or station costs) was found."
		Return costs
	End Method


	Method Update()
		'
	End Method


	Method DrawStations()
		For Local _Station:TStation = EachIn stations
			_Station.Draw()
		Next
	End Method


	'draw a players stationmap
	Method Draw()
		SetColor 255,255,255

		'draw all stations from all players (except filtered)
		For local map:TStationMap = eachin StationMapCollection.stationMaps
			'show stations is zero based
			If Not showStations[map.owner-1] Then Continue
			map.DrawStations()
		Next
	End Method
End Type



'Stationmap
'provides the option to buy new stations
'functions are calculation of audiencesums and drawing of stations
Type TStation Extends TGameObject {_exposeToLua="selected"}
	Field pos:TPoint
	Field reach:Int				= -1
	Field reachIncrease:Int		= -1		'increase of reach at when bought
	Field price:Int				= -1
	Field fixedPrice:Int		= False		'fixed prices are kept during refresh
	Field owner:Int				= 0
	Field paid:Int				= False
	Field built:Int				= 0			'time at which the
	Field radius:Int			= 0
	Field federalState:String	= ""


	Function Create:TStation( pos:TPoint, price:Int=-1, radius:Int, owner:Int)
		Local obj:TStation = New TStation
		obj.owner		= owner
		obj.pos			= pos
		obj.price		= price
		obj.radius		= radius
		obj.built		= GetGameTime().getTimeGone()

		obj.fixedPrice	= (price <> -1)
		obj.refreshData()
		'print "pos "+pos.getIntX()+","+pos.getIntY()+" preis:"+obj.getPrice()+" reach:"+obj.getReach()
		Return obj
	End Function


	'refresh the station data
	Method refreshData() {_exposeToLua}
		getReach(True)
		getReachIncrease(True)
		getPrice( Not fixedPrice )
	End Method


	'returns the age in days
	Method getAge:Int()
		Return GetGameTime().GetDay() - GetGameTime().GetDay(Self.built)
	End Method


	'get the reach of that station
	Method getReach:Int(refresh:Int=False) {_exposeToLua}
		If reach >= 0 And Not refresh Then Return reach
		reach = StationMapCollection.CalculateStationReach(pos.x, pos.y)

		Return reach
	End Method


	Method getReachIncrease:Int(refresh:Int=False) {_exposeToLua}
		If reachIncrease >= 0 And Not refresh Then Return reachIncrease

		if owner <= 0
			Print "getReachIncrease: owner is not a player."
			Return 0
		EndIf

		reachIncrease = StationMapCollection.GetMap(owner).CalculateAudienceIncrease(pos.x, pos.y)

		Return reachIncrease
	End Method


	'if nobody needs that info , remove the method
	Method GetHoveredMapSection:TStationMapSection()
		Return TStationMapSection.get(Self.pos.x, Self.pos.y)
	End Method


	Method getFederalState:String(refresh:Int=False) {_exposeToLua}
		If federalState <> "" And Not refresh Then Return federalState

		Local hoveredSection:TStationMapSection = TStationMapSection.get(Self.pos.x, Self.pos.y)
		If hoveredSection Then federalState = hoveredSection.name

		Return federalState
	End Method


	Method getSellPrice:Int(refresh:Int=False) {_exposeToLua}
		'price is multiplied by an age factor of 0.75-0.95
		Local factor:Float = Max(0.75, 0.95 - Float(getAge())/1.0)
		If price >= 0 And Not refresh Then Return Int(price * factor / 10000) * 10000

		Return Int( getPrice(refresh) * factor / 10000) * 10000
	End Method


	Method getPrice:Int(refresh:Int=False) {_exposeToLua}
		If price >= 0 And Not refresh Then Return price
		price = Max( 25000, Int(Ceil(getReach() / 10000)) * 25000 )

		Return price
	End Method


	Method Sell:Int()
		If Not GetPlayerFinanceCollection().Get(owner) Then Return False

		If GetPlayerFinanceCollection().Get(owner).SellStation( getSellPrice() )
			owner = 0
			Return True
		EndIf
		Return False
	End Method


	Method Buy:Int(playerID:Int)
		If paid Then Return True
		If Not GetPlayerFinanceCollection().Get(playerID) Then Return False

		If GetPlayerFinanceCollection().Get(playerID).PayStation( getPrice() )
			owner = playerID
			paid = True
			Return True
		EndIf
		Return False
	End Method


	Method DrawInfoTooltip()
		Local textH:Int =  GetBitmapFontManager().baseFontBold.getHeight( "Tg" )
		Local tooltipW:Int = 180
		Local tooltipH:Int = textH * 4 + 10 + 5
		Local tooltipX:Int = pos.x +20 - tooltipW/2
		Local tooltipY:Int = pos.y - radius - tooltipH

		'move below station if at screen top
		If tooltipY < 20 Then tooltipY = pos.y+radius + 10 +10
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
		GetBitmapFontManager().baseFontBold.drawStyled( getLocale("MAP_COUNTRY_"+getFederalState()), textX, textY, TColor.Create(255,255,0), 2)
		textY:+ textH + 5

		GetBitmapFontManager().baseFont.draw(GetLocale("RANGE")+": ", textX, textY)
		GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(getReach(), 2), textX, textY, textW, 20, new TPoint.Init(ALIGN_RIGHT), colorWhite)
		textY:+ textH

		GetBitmapFontManager().baseFont.draw(GetLocale("INCREASE")+": ", textX, textY)
		GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(getReachIncrease(), 2), textX, textY, textW, 20, new TPoint.Init(ALIGN_RIGHT), colorWhite)
		textY:+ textH

		GetBitmapFontManager().baseFont.draw(GetLocale("PRICE")+": ", textX, textY)
		GetBitmapFontManager().baseFontBold.drawBlock(TFunctions.convertValue(getPrice(), 2), textX, textY, textW, 20, new TPoint.Init(ALIGN_RIGHT), colorWhite)

	End Method


	Method Draw(selected:Int=False)
		Local sprite:TSprite = Null
		Local oldAlpha:Float = GetAlpha()

		If selected
			'white border around the colorized circle
			SetAlpha 0.25 * oldAlpha
			DrawOval(pos.x - radius -2, pos.y - radius -2 ,radius*2+4,radius*2+4)

			SetAlpha Min(0.9, Max(0,Sin(MilliSecs()/3)) + 0.5 ) * oldAlpha
		Else
			SetAlpha 0.4 * oldAlpha
		EndIf

		Select owner
			Case 1,2,3,4	TColor.GetByOwner(owner).SetRGB()
							sprite = GetSpriteFromRegistry("stationmap_antenna"+owner)
			Default			SetColor 255, 255, 255
							sprite = GetSpriteFromRegistry("stationmap_antenna0")
		End Select
		DrawOval(pos.x - radius, pos.y - radius, 2 * radius, 2 * radius)

		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(pos.x, pos.y + radius - sprite.area.GetH() - 2, -1, new TPoint.Init(ALIGN_CENTER, ALIGN_TOP))
	End Method
End Type




Type TStationMapSection
	Field rect:TRectangle
	Field sprite:TSprite
	Field spriteName:string
	Field name:String
	Global sections:TList = CreateList()


	Method Create:TStationMapSection(pos:TPoint, name:String, spriteName:string)
		Self.spriteName = spriteName
		Self.rect = new TRectangle.Init(pos.x,pos.y, 0, 0)
		Self.name = name
		Self.sprite = sprite
		Return Self
	End Method


	Method LoadSprite()
		sprite = GetSpriteFromRegistry(spriteName)
		'resize rect
		rect.dimension.SetXY(sprite.area.GetW(), sprite.area.GetH())
	End Method


	Function get:TStationMapSection(x:Int,y:Int)
		For Local section:TStationMapSection = EachIn sections
			if not section.sprite then section.LoadSprite()
			if not section.sprite then continue

			If section.rect.containsXY(x,y)
				If section.sprite.PixelIsOpaque(x-section.rect.getX(), y-section.rect.getY()) > 0
					Return section
				EndIf
			EndIf
		Next
		Return Null
	End Function


	Function Reset:int()
		sections = CreateList()
	End Function


	Method Add()
		sections.addLast(Self)
	End Method
End Type