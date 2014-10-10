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
	'speed of the world (1.0 means "normal", 2.0 = double as fast)
	'speed is used for figures, elevator, ...
	Field worldSpeed:float = 1.0

	'x coordinate figures are when "offscreen" (left the building)
	Field offscreenX:int = -200
	'maximum price (profit/penalty) for a single adspot
	Field maxAdContractPricePerSpot:int = 1000000

	'penalty to pay if a player sends an xrated movie at the wrong time
	Field sentXRatedPenalty:int = 25000

	'does the boss has to get visited daily?
	Field dailyBossVisit:int = True
End Type

Global GameRules:TGameRules = new TGameRules