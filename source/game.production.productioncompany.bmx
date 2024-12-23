SuperStrict
Import "game.production.productioncompany.base.bmx"
Import "game.programme.programmedata.bmx"
Import "game.gameeventkeys.bmx"


Type TProductionCompany extends TProductionCompanyBase
	'override
	Method GetNextExperienceGain:int(programmeDataID:int)
		local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID(programmeDataID)
		if not programmeData then return 0

		'100 perfect productions would lead to a 100% experienced company
		local baseGain:float = 100 * programmeData.GetQualityRaw()

		local currentXP:int = GetExperience()

		'the more XP we have, the harder it gets
		if currentXP <  500 then return 1.0 * baseGain
		if currentXP < 1000 then return 0.8 * baseGain
		if currentXP < 2500 then return 0.6 * baseGain
		if currentXP < 5000 then return 0.4 * baseGain
		return 0.2 * baseGain
	End Method


	'override
	Method OnChangeLevel:Int(oldLevel:Int, newLevel:Int)
		TriggerBaseEvent(GameEventKeys.ProductionCompany_OnChangeLevel, new TData.Add("oldLevel", oldLevel).Add("newLevel", newLevel), Self )

		Return True
	End Method


	'override
	Method OnChangeXP:Int(oldXP:Int, newXP:Int)
		TriggerBaseEvent(GameEventKeys.ProductionCompany_OnChangeXP, new TData.Add("oldXP", oldXP).Add("newXP", newXP), Self )

		Return True
	End Method

End Type
