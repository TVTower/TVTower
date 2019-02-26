SuperStrict
Import "Dig/base.util.data.bmx"

'specific variables shared across the whole game
Type TGameRules {_exposeToLua}
	'how many movies does a player get on a new game
	Field startMovieAmount:Int = 5
	'how many series does a player get on a new game
	Field startSeriesAmount:Int = 1
	'how many contracts a player gets on a new game
	Field startAdAmount:Int = 3

	'if a player goes bankrupt does the restarting one get stations
	'and money according to the average of other players?
	Field adjustRestartingPlayersToOtherPlayers:int = True
	Field adjustRestartingPlayersToOtherPlayersQuote:Float = 1.0
	'percentage of a players properties (programme licences, scripts ..) value
	'which is converted into money
	Field adjustRestartingPlayersToOtherPlayersPropertyCashRatio:Float = 0.25

	'how much love with betty is needed so she would give you the master
	'key for all the rooms in the building
	Field bettyLoveToGetMasterKey:Float = 0.75

	'maximum level a news genre abonnement can have
	Field maxAbonnementLevel:Int = 3
	'how many movies can be carried in suitcase
	Field maxProgrammeLicencesInSuitcase:Int = 12
	'how many movies can a player have per filter ("genre")
	Field maxProgrammeLicencesPerFilter:Int = 60

	'how many scripts can be carried in suitcase
	Field maxScriptsInSuitcase:int = 10
	'is the amount of user owned scripts limited?
	Field maxScripts:int = -1
	'how many production concepts could be "planned" at the same time
	'(per script - for series and shows ...)
	Field maxProductionConceptsPerScript:int = 8

	'speed of the world (1.0 means "normal", 2.0 = double as fast)
	'speed is used for figures, elevator, ...
	Field worldSpeed:float = 1.0
	'0.25*60, 0.5*60, 3*60, 10*60
	Field worldTimeSpeedPresets:Int[] = [15, 30, 180, 600]

	Field globalEntityWorldSpeedFactor:Float = 1.0

	'pixels per "second"
	Field elevatorSpeed:int = 160
	'how long in MS to wait until closing the door
	Field elevatorWaitAtFloorTime:int = 1500
	Field elevatorAnimSpeed:int = 60

	'how many time an original room owner waits until he re-rents a room
	'which got free again (no longer used as additional studio)
	Field roomReRentTime:int = 12*3600

	'if disabled, player is allowed to place a live programme
	'also at later times (eg. 2 hours later)
	Field onlyExactLiveProgrammeTimeAllowedInProgrammePlan:int = False

	'percentage of the gametime when in a room (default = 100%)
	'use a lower value, to slow down the game then (movement + time)
	Field InRoomTimeSlowDownMod:Float = 1.0

	Field startProgrammeAmount:int = 0

	'penalty to pay if a player sends an xrated movie at the wrong time
	Field sentXRatedPenalty:int = 25000

	'does the boss has to get visited daily?
	Field dailyBossVisit:int = True


	'=== ADCONTRACTS ===
	'how many contracts can a player collection store
	Field adContractsPerPlayerMax:int = 12
	'how many contracts of the same contractBase can exist at the
	'same time? (0 disables any limit)
	Field adContractInstancesMax:int = 1
	'maximum price (profit/penalty) for a single adspot
	Field adContractPricePerSpotMax:int = 1000000

	'=== ADAGENCY ===
	Field adagencySortContractsBy:string = "minaudience"
	Field adagencyRefillMode:int = 2

	'=== NEWS STUDIO ===
	Field newsStudioSortNewsBy:string = "age"

	'=== STATIONMAP ===
	'time a station needs to get constructed
	'value in hours
	'set to default (0) on start (game.game.bmx prepareNewGame())
	Field stationConstructionTime:int = 0
	Field cableNetworkConstructionTime:int = 0
	'increase costs by X percent each day after construction of a station?
	Field stationIncreaseDailyMaintenanceCosts:int = False
	Field stationDailyMaintenanceCostsPercentage:Float = 0.02
	Field stationDailyMaintenanceCostsPercentageTotalMax:Float = 0.30


	'=== DEV.xml ===
	Field devConfig:TData = new TData


	Method Reset()
		dailyBossVisit = True
		sentXRatedPenalty = 25000

		elevatorSpeed = 160
		elevatorWaitAtFloorTime = 1500

		stationConstructionTime = 0

		adagencySortContractsBy = "minaudience"
		adagencyRefillMode = 2 'new one

		newsStudioSortNewsBy = "age"

		adContractInstancesMax = 1
		adContractsPerPlayerMax = 12
		adContractPricePerSpotMax = 1000000


		AssignFromData(devConfig)
	End Method


	Method AssignFromData:int(data:TData)
		if not data then return False

		dailyBossVisit = data.GetInt("DEV_DAILY_BOSS_VISIT", dailyBossVisit)

		sentXRatedPenalty = data.GetInt("DEV_SENT_XRATED_PENALTY", sentXRatedPenalty)

		adContractInstancesMax = data.GetInt("DEV_ADCONTRACT_INSTANCES_MAX", adContractInstancesMax)
		adContractsPerPlayerMax = data.GetInt("DEV_ADCONTRACTS_PER_PLAYER_MAX", adContractsPerPlayerMax)
		adContractPricePerSpotMax = data.GetInt("DEV_ADCONTRACT_PRICE_PER_SPOT_MAX", adContractPricePerSpotMax)
		if data.GetInt("DEV_ADCONTRACT_PRICE_PER_SPOT_MAX", 0) > 0
			adContractPricePerSpotMax = data.GetInt("DEV_ADCONTRACT_PRICE_PER_SPOT_MAX")
		endif

		'=== ADAGENCY ===
		adagencySortContractsBy = data.GetString("DEV_ADAGENCY_SORT_CONTRACTS_BY", adagencySortContractsBy).Trim().ToLower()
		adagencyRefillMode = data.GetInt("DEV_ADAGENCY_REFILL_MODE", adagencyRefillMode)

		'=== NEWS STUDIO ===
		newsStudioSortNewsBy = data.GetString("DEV_NEWSSTUDIO_SORT_NEWS_BY", newsStudioSortNewsBy).Trim().ToLower()


		'=== ELEVATOR ===
		elevatorWaitAtFloorTime = Max(1000, Min(2000, data.GetInt("DEV_ELEVATOR_WAITTIME", elevatorWaitAtFloorTime)))
		elevatorSpeed = Max(50, Min(240, data.GetInt("DEV_ELEVATOR_SPEED", elevatorSpeed)))
		elevatorAnimSpeed = Max(30, Min(100, data.GetInt("DEV_ELEVATOR_ANIMSPEED", elevatorAnimSpeed)))


		'=== STATION(MAP) ===
		stationConstructionTime = data.GetInt("DEV_STATION_CONSTRUCTION_TIME", 0)
		stationIncreaseDailyMaintenanceCosts = data.GetBool("DEV_STATION_INCREASE_DAILY_MAINTENANCE_COSTS", stationIncreaseDailyMaintenanceCosts)
		stationDailyMaintenanceCostsPercentage = data.GetFloat("DEV_STATION_DAILY_MAINTENANCE_COSTS_PERCENTAGE", stationDailyMaintenanceCostsPercentage)
		stationDailyMaintenanceCostsPercentageTotalMax = data.GetFloat("DEV_STATION_DAILY_MAINTENANCE_COSTS_PERCENTAGE_TOTAL_MAX", stationDailyMaintenanceCostsPercentageTotalMax)

		return True
	End Method

End Type

Global GameRules:TGameRules = new TGameRules