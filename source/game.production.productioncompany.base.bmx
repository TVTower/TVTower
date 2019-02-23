SuperStrict
Import Brl.Math
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.logger.bmx"
Import "Dig/base.util.math.bmx"
Import "game.gameobject.bmx"




Type TProductionCompanyBaseCollection Extends TGameObjectCollection
	Global _instance:TProductionCompanyBaseCollection

	Function GetInstance:TProductionCompanyBaseCollection()
		if not _instance then _instance = new TProductionCompanyBaseCollection
		return _instance
	End Function


	Method GetByGUID:TProductionCompanyBase(GUID:String)
		Return TProductionCompanyBase( Super.GetByGUID(GUID) )
	End Method


	Method GetByID:TProductionCompanyBase(ID:int)
		Return TProductionCompanyBase( Super.GetByID(ID) )
	End Method


	Method GetRandom:TProductionCompanyBase()
		Return TProductionCompanyBase( Super.GetRandom() )
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProductionCompanyBaseCollection:TProductionCompanyBaseCollection()
	Return TProductionCompanyBaseCollection.GetInstance()
End Function




Type TProductionCompanyBase extends TGameObject
	Field name:string
	'IDs of all done productions
	Field producedProgrammeIDs:Int[]
	Field baseQuality:Float = 0.50
	'price manipulation. varying price but constant "quality"
	Field priceModifier:Float = 1.0
	'quality manipulation. varying quality but constant "price"
	Field qualityModifier:Float = 1.0
	Field channelSympathy:Float[4]
	Field xp:int = 0
	'a custom xp limit - eg limited by "age" or so
	'cannot be higher than DEFAULT_MAX_XP
	Field maxXP:int = -1
	Field maxLevel:int = -1

	Const MAX_XP:int = 10000
	Const MAX_LEVEL:int = 20
	'minimum amount of points (added to level 1)
	Const MIN_FOCUSPOINTS:int = 2
	Const MAX_FOCUSPOINTS:int = 60


	Method GenerateGUID:string()
		return "productioncompanybase-"+id
	End Method

'ProductionCompany: Finished production. experience before: 999  level: 2  LevelXP%:0.998000026   XP%:0.0998999998
 '                                          experience now: 1016  level: 2  LevelXP%:0.0320000648   XP%:0.101599999
	Method GetLevel:int()
		return Min(MAX_LEVEL, 1 + (MAX_LEVEL-1) * GetExperiencePercentage())
	End Method


	Method GetMaxXP:int()
		if maxXP < 0 then return MAX_XP
		return Min(maxXP, MAX_XP)
	End Method


	Method SetLevel:int(level:int)
		level = Max(1, level)
		'-1 because level 1 is reached with 0 xp
		SetExperience(int(Float(level-1) / MAX_LEVEL * MAX_XP))
	End Method


	Method GetLevelExperiencePercentage:Float()
		return GetExperiencePercentage() - floor(GetExperiencePercentage())
	End Method


	Method GetFocusPoints:int()
		return GetFocusPointsAtLevel( GetLevel() )
	End Method


	Function GetFocusPointsAtLevel:int(level:int)
		level = Max(1, level)

		'20 level = 5pt each level
		' 1- 5 get  3 from 16-20	= 5 + 3 = 8
		' 6-10 get  1 from 11-15	= 5 + 1 = 6
		'11-15 give 1 to    6-10	= 5 - 1 = 4
		'16-20 give 3 to    1- 5	= 5 - 3 = 2
		local result:int = 0
		if level > 0 then result :+ Min(5, level   ) * 8
		if level > 5 then result :+ Min(5, level- 5) * 6
		if level >10 then result :+ Min(5, level-10) * 4
		if level >15 then result :+ Min(5, level-15) * 2
		return floor(result * (MAX_FOCUSPOINTS - MIN_FOCUSPOINTS)/100.0) + MIN_FOCUSPOINTS
	End Function


	Method SetMaxExperience(value:int)
		maxXP = value
	End Method


	Method SetExperience(value:int)
		value = Max(0, value)
		'limit by individual xp limit
		xp = Min(GetMaxXP(), value)
	End Method


	Method GetExperience:int()
		return Max(0, xp)
	End Method


	Method GetExperiencePercentage:Float()
		return GetExperience() / float(MAX_XP)
	End Method


	Method GetIndividualExperiencePercentage:Float()
		if GetMaxXP() = 0 then return 1.0

		return GetExperience() / float(GetMaxXP())
	End Method


	Method GetNextExperienceGain:int(programmeDataID:int)
		return 0
	End Method


	Method SetChannelSympathy:int(channel:int, newSympathy:float)
		if channel < 0 or channel >= channelSympathy.length then return False
		newSympathy = MathHelper.Clamp(newSympathy, -1.0, +1.0)

		channelSympathy[channel -1] = newSympathy
	End Method


	Method GetChannelSympathy:float(channel:int)
		if channel < 0 or channel >= channelSympathy.length then return 0.0

		return channelSympathy[channel -1]
	End Method


	Method FinishProduction:int(programmeDataID:int)
		'already added
		if MathHelper.InIntArray(programmeDataID, producedProgrammeIDs) then return False

		local oldExperience:int = GetExperience()
		local oldLevel:int = GetLevel()
		local oldLevelXP:Float = GetLevelExperiencePercentage()
		local oldXP:Float = GetExperiencePercentage()

		'add programme
		producedProgrammeIDs :+ [programmeDataID]
		'gain some xp
		SetExperience(GetExperience() + GetNextExperienceGain(programmeDataID))
		TLogger.Log("TProductionCompany", "Finish production and gained experience. Experience: "+ oldExperience +"->"+GetExperience() + "  level: " + oldLevel+"->"+GetLevel() +"  LevelXP: " + MathHelper.NumberToString(oldLevelXP*100,2)+"->"+MathHelper.NumberToString(GetLevelExperiencePercentage()*100,2)+"%" +"  XP: "+MathHelper.NumberToString(oldXP*100,2)+"->"+MathHelper.NumberToString(GetExperiencePercentage()*100,2)+"%", LOG_DEBUG)

		return True
	End Method


	'base might differ depending on sympathy for channel
	Method GetFee:Int(channel:int=-1)
		local sympathyMod:Float = 1.0
		'modify by up to 50% ...
		if channel >= 0 then sympathyMod :- 0.5 * GetChannelSympathy(channel)

		local xpMod:Float = 1.0
		'up to "* 100" -> 100% xp means 2000*100 = 200000
		xpMod :+ 100 * GetExperiencePercentage()

		Return sympathyMod * priceModifier * (20000 + Floor(Int(10000 * xpMod)/100)*100)
	End Method


	Method GetQuality:Float()
		'quality is based on base quality and an experience based quality
		local q:Float = 0.25 * baseQuality + 0.75 * GetExperiencePercentage()
		'modified by an individual modifier
		return Max(0.0, Min(1.0, qualityModifier * q))
	End Method
End Type
