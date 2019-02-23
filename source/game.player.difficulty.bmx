SuperStrict
Import "game.gameobject.bmx"


Type TPlayerDifficultyCollection Extends TGameObjectCollection
	Field _initializedDefaults:int = False {nosave} 'initialize each time
	Global _instance:TPlayerDifficultyCollection


	Function GetInstance:TPlayerDifficultyCollection()
		if not _instance then _instance = new TPlayerDifficultyCollection

		return _instance
	End Function


	Method InitializeDefaults:int()
		local easy:TPlayerDifficulty = new TPlayerDifficulty
		easy.SetGUID("easy")
		easy.startMoney = 750000
		easy.startCredit = 250000
		easy.creditMaximum = 600000
		easy.programmePriceMod = 0.75
		easy.roomRentMod = 0.80
		easy.advertisementProfitMod = 1.25
		easy.stationmapPriceMod = 0.80
		easy.adjustRestartingPlayersToOtherPlayersMod = 1.25


		local normal:TPlayerDifficulty = new TPlayerDifficulty
		normal.SetGUID("normal")
		normal.startMoney = 250000
		normal.startCredit = 500000
		normal.creditMaximum = 600000
		normal.programmePriceMod = 1.0
		normal.roomRentMod = 1.0
		normal.advertisementProfitMod = 1.0
		normal.stationmapPriceMod = 1.0
		normal.adjustRestartingPlayersToOtherPlayersMod = 1.0


		local hard:TPlayerDifficulty = new TPlayerDifficulty
		hard.SetGUID("hard")
		hard.startMoney = 0
		hard.startCredit = 500000
		hard.creditMaximum = 500000
		hard.programmePriceMod = 1.1
		hard.roomRentMod = 1.15
		hard.advertisementProfitMod = 0.9
		hard.stationmapPriceMod = 1.15
		hard.adjustRestartingPlayersToOtherPlayersMod = 0.85


		Add(easy)
		Add(normal)
		Add(hard)

		_initializedDefaults = True
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




Type TPlayerDifficulty extends TGameObject
	Field startMoney:int
	Field startCredit:int
	Field creditMaximum:int
	Field programmePriceMod:Float = 1.0
	Field roomRentmod:Float = 1.0
	Field advertisementProfitMod:Float = 1.0
	Field stationmapPriceMod:Float = 1.0
	Field adjustRestartingPlayersToOtherPlayersMod:Float = 1.0

	Method GenerateGUID:string()
		return "playerdifficulty-"+id
	End Method
End Type
