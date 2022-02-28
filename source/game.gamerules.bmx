SuperStrict
Import "Dig/base.util.data.bmx"

'specific variables shared across the whole game
Type TGameRules {_exposeToLua}
	'should a game start with a credit already given
	Field startGameWithCredit:Int = True
	'should licence attributes from the database be randomized
	Field randomizeLicenceAttributes:Int = False

	'how much love with betty is needed so she would give you the master
	'key for all the rooms in the building
	Field bettyLoveToGetMasterKey:Float = 0.75
	
	Field baseProductionTimeHours:Int = 9

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
	
	'(game)time until a news genre subscription increase gets "fixed"
	Field newsSubscriptionIncreaseFixTime:Int = 30 * 60 * 1000 '30 Minutes

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

	'refill movie agency every X Minutes
	Field refillMovieAgencyTimer:Int = 180
	'refill script agency every X Minutes
	Field refillScriptAgencyTimer:Int = 200
	'refill ad agency every X Minutes
	Field refillAdAgencyTimer:Int = 150
	'refill completely on next refill run?
	Field refillAdAgencyPercentage:Float = 0.5

	'how many time an original room owner waits until he re-rents a room
	'which got free again (no longer used as additional studio)
	Field roomReRentTime:Long = 12 * 3600*1000 '12 * TWorldTime.HOURLENGTH

	'if disabled, player is allowed to place a live programme
	'also at later times (eg. 2 hours later)
	Field onlyExactLiveProgrammeTimeAllowedInProgrammePlan:int = False

	'pay live productions already on finish of preproduction (True)
	'or on finish of actual shooting (False)
	Field payLiveProductionInAdvance:Int = False

	'percentage of the gametime when in a room (default = 100%)
	'use a lower value, to slow down the game then (movement + time)
	Field InRoomTimeSlowDownMod:Float = 1.0

	'how many productions (jobs, so theoretically less productions)
	'are required to make a person a celebrity
	Field UpgradeInsignificantOnProductionJobsCount:Int = 3

	'does the boss has to get visited daily?
	Field dailyBossVisit:int = True
	
	Field onlyFictionalInCustomProduction:int = True


	'=== ADCONTRACTS ===
	'how many contracts can a player collection store
	Field adContractsPerPlayerMax:int = 12
	'how many contracts of the same contractBase can exist at the
	'same time? (0 disables any limit)
	Field adContractInstancesMax:int = 1

	'=== ADAGENCY ===
	Field adagencySortContractsBy:string = "minaudience"
	Field adagencyRefillMode:int = 1

	'=== NEWS STUDIO ===
	Field newsStudioSortNewsBy:string = "age"

	'=== STATIONMAP ===
	Field stationInitialIntendedReach:int = 1000000


	'=== DEV.xml ===
	Field devConfig:TData = new TData


	Method Reset()
		dailyBossVisit = True

		elevatorSpeed = 160
		elevatorWaitAtFloorTime = 1500


		adagencySortContractsBy = "minaudience"
		adagencyRefillMode = 2 'new one

		newsStudioSortNewsBy = "age"

		adContractInstancesMax = 1
		adContractsPerPlayerMax = 12


		AssignFromData(devConfig)
	End Method


	Method AssignFromData:int(data:TData)
		if not data then return False

		dailyBossVisit = data.GetInt("DEV_DAILY_BOSS_VISIT", dailyBossVisit)

		adContractInstancesMax = data.GetInt("DEV_ADCONTRACT_INSTANCES_MAX", adContractInstancesMax)
		adContractsPerPlayerMax = data.GetInt("DEV_ADCONTRACTS_PER_PLAYER_MAX", adContractsPerPlayerMax)

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
		stationInitialIntendedReach = data.GetInt("DEV_STATION_INITIAL_INTENDED_REACH", stationInitialIntendedReach)

		return True
	End Method

End Type

Global GameRules:TGameRules = new TGameRules