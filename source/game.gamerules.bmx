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

	'maximum level a news genre abonnement can have
	Field maxAbonnementLevel:Int = 3
	'how many movies can be carried in suitcase
	Field maxProgrammeLicencesInSuitcase:Int = 12
	'how many movies can a player have per filter ("genre")
	Field maxProgrammeLicencesPerFilter:Int = 15
	'how many contracts can a player collection store
	Field maxContracts:int = 10
	'how many contracts of the same contractBase can exist at the
	'same time? (0 disables any limit)
	Field maxContractInstances:int = 1
	'how many scripts can be carried in suitcase
	Field maxScriptsInSuitcase:int = 10
	'is the amount of user owned scripts limited?
	Field maxScripts:int = -1
	'how many shopping lists could be exist at the same time?
	Field maxShoppingLists:int = 5
	'speed of the world (1.0 means "normal", 2.0 = double as fast)
	'speed is used for figures, elevator, ...
	Field worldSpeed:float = 1.0

	'maximum price (profit/penalty) for a single adspot
	Field maxAdContractPricePerSpot:int = 1000000

	Field startProgrammeAmount:int = 0

	'penalty to pay if a player sends an xrated movie at the wrong time
	Field sentXRatedPenalty:int = 25000

	'does the boss has to get visited daily?
	Field dailyBossVisit:int = True

	Field devConfig:TData = new TData
End Type

Global GameRules:TGameRules = new TGameRules