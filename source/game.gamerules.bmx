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

	'how much love with betty is needed so she would give you the master
	'key for all the rooms in the building
	Field bettyLoveToGetMasterKey:Float = 0.75

	'maximum level a news genre abonnement can have
	Field maxAbonnementLevel:Int = 3
	'how many movies can be carried in suitcase
	Field maxProgrammeLicencesInSuitcase:Int = 12
	'how many movies can a player have per filter ("genre")
	Field maxProgrammeLicencesPerFilter:Int = 60
	'how many contracts can a player collection store
	Field maxContracts:int = 10
	'how many contracts of the same contractBase can exist at the
	'same time? (0 disables any limit)
	Field maxContractInstances:int = 1
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

	'pixelsp er "second"
	Field elevatorSpeed:int = 160
	'how long in MS to wait until closing the door
	Field elevatorWaitAtFloorTime:int = 1500

	'how many time an original room owner waits until he re-rents a room
	'which got free again (no longer used as additional studio)
	Field roomReRentTime:int = 12*3600

	'if disabled, player is allowed to place a live programme
	'also at later times (eg. 2 hours later)
	Field onlyExactLiveProgrammeTimeAllowedInProgrammePlan:int = False

	'percentage of the gametime when in a room (default = 100%)
	'use a lower value, to slow down the game then (movement + time)
	Field InRoomTimeSlowDownMod:Float = 1.0

	'maximum price (profit/penalty) for a single adspot
	Field maxAdContractPricePerSpot:int = 1000000

	Field startProgrammeAmount:int = 0

	'penalty to pay if a player sends an xrated movie at the wrong time
	Field sentXRatedPenalty:int = 25000

	'does the boss has to get visited daily?
	Field dailyBossVisit:int = True

	'time a station needs to get constructed
	'value in hours
	'set to default on start (game.game.bmx prepareNewGame())
	Field stationConstructionTime:int = -1
	Field stationConstructionTimeDefault:int = 0

	Field devConfig:TData = new TData
End Type

Global GameRules:TGameRules = new TGameRules