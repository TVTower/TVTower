SuperStrict
Import "game.gameobject.bmx"
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.data.xmlstorage.bmx"


Type TPlayerDifficultyCollection Extends TGameObjectCollection
	Field _initializedDefaults:int = False {nosave} 'initialize each time
	Global _basePath:String = ""
	Global _instance:TPlayerDifficultyCollection


	Function GetInstance:TPlayerDifficultyCollection()
		if not _instance then _instance = new TPlayerDifficultyCollection

		return _instance
	End Function


	Method InitializeDefaults:int()
		Local dataLoader:TDataXmlStorage = New TDataXmlStorage
		dataLoader.setRootNodeKey("difficulties")
		local difficultyConfig:TData = dataLoader.Load(_basePath+"config/gamesettings/default.xml")

		local easy:TPlayerDifficulty = ReadDifficultyData("easy", difficultyConfig)
		local normal:TPlayerDifficulty = ReadDifficultyData("normal", difficultyConfig)
		local hard:TPlayerDifficulty = ReadDifficultyData("hard", difficultyConfig)
		Add(easy)
		Add(normal)
		Add(hard)

		_initializedDefaults = True

		Function ReadDifficultyData:TPlayerDifficulty(level:String, data:TData)
			local result:TPlayerDifficulty = new TPlayerDifficulty
			local spec:TData=data.getData(level)
			local def:TData=data.getData("defaults")
			if not spec then spec = def 'level info may be empty -> spec=null

			result.SetGUID(level)
			result.difficultyVersion = 1
			result.startMoney = ReadInt("startMoney", spec, def, 0, 5000000)
			result.startCredit = ReadInt("startCredit", spec, def, 0, 5000000)
			result.creditAvailableOnGameStart = ReadInt("creditAvailableOnGameStart", spec, def, 0, 10000000)
			result.creditBaseValue = ReadInt("creditBaseValue", spec, def, 0, 100000)
			result.interestRateCredit = ReadFloat("interestRateCredit", spec, def, 0.0, 0.3)
			result.interestRatePositiveBalance = ReadFloat("interestRatePositiveBalance", spec, def, 0.0, 0.3)
			result.interestRateNegativeBalance = ReadFloat("interestRateNegativeBalance", spec, def, 0.0, 0.3)
			result.programmePriceMod = ReadFloat("programmePriceMod", spec, def, 0.1, 5.0)
			result.programmeTopicalityCutMod = ReadFloat("programmeTopicalityCutMod", spec, def, 0.5, 2.0)
			result.newsItemPriceMod = ReadFloat("newsItemPriceMod", spec, def, 0.1, 5.0)
			result.roomRentMod = ReadFloat("roomRentMod", spec, def, 0.1, 5.0)
			result.productionTimeMod = ReadFloat("productionTimeMod", spec, def, 0.1, 5.0)
			result.sentXRatedPenalty = ReadInt("sentXRatedPenalty", spec, def, 0, 500000)
			result.sentXRatedConfiscateRisk = ReadInt("sentXRatedConfiscateRisk", spec, def, 0, 100)
			result.adcontractPriceMod = ReadFloat("adcontractPriceMod", spec, def, 0.1, 5.0)
			result.adcontractProfitMod = ReadFloat("adcontractProfitMod", spec, def, 0.1, 5.0)
			result.adcontractPenaltyMod = ReadFloat("adcontractPenaltyMod", spec, def, 0.1, 5.0)
			result.adcontractInfomercialProfitMod = ReadFloat("adcontractInfomercialProfitMod", spec, def, 0.1, 5.0)
			result.adcontractLimitedTargetgroupMod = ReadFloat("adcontractLimitedTargetgroupMod", spec, def, 1.0, 5.0)
			result.adcontractLimitedGenreMod = ReadFloat("adcontractLimitedGenreMod", spec, def, 1.0, 5.0)
			result.adcontractLimitedProgrammeFlagMod = ReadFloat("adcontractLimitedProgrammeFlagMod", spec, def, 1.0, 5.0)
			result.adcontractRawMinAudienceMod = ReadFloat("adcontractRawMinAudienceMod", spec, def, 0.1, 5.0)

			result.antennaBuyPriceMod = ReadFloat("antennaBuyPriceMod", spec, def, 0.1, 5.0)
			result.antennaConstructionTime = ReadInt("antennaConstructionTime", spec, def, 0, 10)
			result.antennaDailyCostsMod = ReadFloat("antennaDailyCostsMod", spec, def, 0.1, 5)
			result.antennaDailyCostsIncrease = ReadFloat("antennaDailyCostsIncrease", spec, def, 0.0, 0.5)
			result.antennaDailyCostsIncreaseMax = ReadFloat("antennaDailyCostsIncreaseMax", spec, def, 0.0, 5.0)
			result.cableNetworkBuyPriceMod = ReadFloat("cableNetworkBuyPriceMod", spec, def, 0.1, 5.0)
			result.cableNetworkConstructionTime = ReadInt("cableNetworkConstructionTime", spec, def, 0, 10)
			result.cableNetworkDailyCostsMod = ReadFloat("cableNetworkDailyCostsMod", spec, def, 0.1, 5)
			result.satelliteBuyPriceMod = ReadFloat("satelliteBuyPriceMod", spec, def, 0.1, 5.0)
			result.satelliteConstructionTime = ReadInt("satelliteConstructionTime", spec, def, 0, 10)
			result.satelliteDailyCostsMod = ReadFloat("satelliteDailyCostsMod", spec, def, 0.1, 5)
			result.broadcastPermissionPriceMod = ReadFloat("broadcastPermissionPriceMod", spec, def, 0.1, 5.0)
			result.restartingPlayerMoneyRatio = ReadFloat("restartingPlayerMoneyRatio", spec, def, 0.1, 2.0)

			result.renovationBaseCost = ReadInt("renovationBaseCost", spec, def, 0, 200000)
			result.renovationTimeMod = ReadFloat("renovationTimeMod", spec, def, 0.1, 5)
			return result
		End Function
		Function ReadInt:Int(key:String, spec:TData, def:TData, minValue:Int, maxValue:Int)
			local result:Int = spec.getInt(key, def.getInt(key))
			result = Min(Max(minValue,result),maxValue)
			return result
		End Function
		Function ReadFloat:Float(key:String, spec:TData, def:TData, minValue:Float, maxValue:Float)
			local result:Float = spec.getFloat(key, def.getFloat(key))
			result = Min(Max(minValue,result),maxValue)
			return result
		End Function
	End Method


	Method GetByGUID:TPlayerDifficulty(GUID:String)
		'setup easy/normal/hard with current-versions-data
		'this will override potentially "loaded" variants
		'from savegames
		if not _initializedDefaults then InitializeDefaults()

		local diff:TPlayerDifficulty = TPlayerDifficulty( Super.GetByGUID(GUID) )
		'fall back to "normal" if requested (maybe individual) was not found
		'-> eg. older savegames without difficulty stored
		if not diff then diff = TPlayerDifficulty( Super.GetByGUID("normal") )

		return diff
	End Method


	Method AddToPlayer:int(playerID:int, difficulty:TPlayerDifficulty)
		entries.Insert(string(playerID), difficulty)
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerDifficultyCollection:TPlayerDifficultyCollection()
	Return TPlayerDifficultyCollection.GetInstance()
End Function


Function GetPlayerDifficulty:TPlayerDifficulty(GUID:string)
	Return TPlayerDifficultyCollection.GetInstance().GetByGUID(GUID)
End Function

Function GetPlayerDifficulty:TPlayerDifficulty(player:Int)
	Return GetPlayerDifficulty(String(player))
End Function



Type TPlayerDifficulty extends TGameObject
	'version of the difficulty object for determining migration strategy when loading a game
	Field difficultyVersion:int = 0
	Field startMoney:int
	Field startCredit:int
	Field creditAvailableOnGameStart:int
	Field creditBaseValue:int
	Field interestRateCredit:Float
	Field interestRatePositiveBalance:Float
	Field interestRateNegativeBalance:Float
	Field programmePriceMod:Float = 1.0
	Field programmeTopicalityCutMod:Float = 1.0
	Field newsItemPriceMod:Float
	Field roomRentmod:Float = 1.0
	Field productionTimeMod:Float
	Field sentXRatedPenalty:int
	Field sentXRatedConfiscateRisk:int
	Field adcontractPriceMod:Float
	Field adcontractProfitMod:Float
	Field adcontractPenaltyMod:Float
	Field adcontractInfomercialProfitMod:Float
	Field adcontractLimitedTargetgroupMod:Float
	Field adcontractLimitedGenreMod:Float
	Field adcontractLimitedProgrammeFlagMod:Float
	Field adcontractRawMinAudienceMod:Float
	Field antennaBuyPriceMod:Float
	Field antennaConstructionTime:int
	Field antennaDailyCostsMod:Float
	Field antennaDailyCostsIncrease:Float
	Field antennaDailyCostsIncreaseMax:Float
	Field cableNetworkBuyPriceMod:Float
	Field cableNetworkConstructionTime:int
	Field cableNetworkDailyCostsMod:Float
	Field satelliteBuyPriceMod:Float
	Field satelliteConstructionTime:int
	Field satelliteDailyCostsMod:Float
	Field broadcastPermissionPriceMod:Float
	Field restartingPlayerMoneyRatio:Float
	Field renovationBaseCost:int
	Field renovationTimeMod:Float

	Method GenerateGUID:string()
		return "playerdifficulty-"+id
	End Method
End Type
