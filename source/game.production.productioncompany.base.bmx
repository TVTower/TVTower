SuperStrict
Import Brl.Math
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.logger.bmx"
Import "Dig/base.util.math.bmx"
Import "game.gameobject.bmx"




Type TProductionCompanyBaseCollection Extends TGameObjectCollection
	Global _instance:TProductionCompanyBaseCollection

	Function GetInstance:TProductionCompanyBaseCollection()
		If Not _instance Then _instance = New TProductionCompanyBaseCollection
		Return _instance
	End Function


	Method GetByGUID:TProductionCompanyBase(GUID:String)
		Return TProductionCompanyBase( Super.GetByGUID(GUID) )
	End Method


	Method GetByID:TProductionCompanyBase(ID:Int)
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




Type TProductionCompanyBase Extends TGameObject
	Field name:String
	'IDs of all done productions
	Field producedProgrammeIDs:Int[]
	Field baseQuality:Float = 0.50
	'price manipulation. varying price but constant "quality"
	Field priceModifier:Float = 1.0
	'quality manipulation. varying quality but constant "price"
	Field qualityModifier:Float = 1.0
	Field channelSympathy:Float[4]
	Field xp:Int = 0
	'a custom xp limit - eg limited by "age" or so
	'cannot be higher than DEFAULT_MAX_XP
	Field maxXP:Int = -1
	Field maxLevel:Int = -1

	Const MAX_XP:Int = 10000
	Const MAX_LEVEL:Int = 20
	'minimum amount of points (added to level 1)
	Const MIN_FOCUSPOINTS:Int = 2
	Const MAX_FOCUSPOINTS:Int = 60


	Method GenerateGUID:String()
		Return "productioncompanybase-"+id
	End Method


	Method GetLevelXPMinimum:Int( level:Int = -1)
		If level = -1 Then level = GetLevel()
		Return level / Float(GetMaxLevel()) * GetMaxXP()
	End Method


	Method GetLevel:Int()
		Return Min(GetMaxLevel(), 1 + GetMaxLevel() * GetExperiencePercentage())
	End Method


	Method SetMaxLevel:Int(level:Int)
		maxLevel = level
	End Method


	Method GetMaxLevel:Int()
		'fix for old savegames / instances of the companies
		If maxXP = 0 then maxLevel = 1

		If maxLevel < 0 Then Return MAX_LEVEL
		Return Min(maxLevel, MAX_LEVEL)
	End Method


	Method GetMaxXP:Int()
		If maxXP < 0 Then Return MAX_XP
		Return Min(maxXP, MAX_XP)
	End Method


	Method SetLevel:Int(level:Int)
		level = Max(1, level)
		'-1 because level 1 is reached with 0 xp
		SetExperience(Int(Float(level-1) / GetMaxLevel() * GetMaxXP()))
	End Method


	Method GetLevelExperiencePercentage:Float()
		Local level:Float = GetExperiencePercentage() * GetMaxLevel()
		' GetExperience() / float(mXP)
		Return level - Int(level)
	End Method


	Method GetFocusPoints:Int()
		Return GetFocusPointsAtLevel( GetLevel() )
	End Method


	Function GetFocusPointsAtLevel:Int(level:Int)
		level = Max(1, level)

		'20 level = 5pt each level
		' 1- 5 get  3 from 16-20	= 5 + 3 = 8
		' 6-10 get  1 from 11-15	= 5 + 1 = 6
		'11-15 give 1 to    6-10	= 5 - 1 = 4
		'16-20 give 3 to    1- 5	= 5 - 3 = 2
		Local result:Int = 0
		If level > 0 Then result :+ Min(5, level   ) * 8
		If level > 5 Then result :+ Min(5, level- 5) * 6
		If level >10 Then result :+ Min(5, level-10) * 4
		If level >15 Then result :+ Min(5, level-15) * 2
		Return Floor(result * (MAX_FOCUSPOINTS - MIN_FOCUSPOINTS)/100.0) + MIN_FOCUSPOINTS
	End Function


	Method SetMaxExperience(value:Int)
		maxXP = value
	End Method


	Method SetExperience(value:Int)
		local oldLevel:Int = GetLevel()
		local oldXP:Int = xp

		value = Max(0, value)
		'limit by individual xp limit
		xp = Min(GetMaxXP(), value)
		
		local newLevel:Int = GetLevel()

		if oldLevel <> newLevel Then OnChangeLevel(oldLevel, newLevel)
		if oldXP <> xp Then OnChangeXP(oldXP, xp)
	End Method


	Method GetExperience:Int()
		Return Max(0, xp)
	End Method


	Method GetExperiencePercentage:Float()
		If GetMaxXP() = 0 Then Return 0.0

		Return GetExperience() / Float(GetMaxXP())
	End Method


	Method GetNextExperienceGain:Int(programmeDataID:Int)
		Return 0
	End Method


	Method SetChannelSympathy:Int(channel:Int, newSympathy:Float)
		If channel < 0 Or channel >= channelSympathy.length Then Return False
		newSympathy = MathHelper.Clamp(newSympathy, -1.0, +1.0)

		channelSympathy[channel -1] = newSympathy
	End Method


	Method GetChannelSympathy:Float(channel:Int)
		If channel < 0 Or channel >= channelSympathy.length Then Return 0.0

		Return channelSympathy[channel -1]
	End Method


	Method FinishProduction:Int(programmeDataID:Int)
		'already added
		If MathHelper.InIntArray(programmeDataID, producedProgrammeIDs) Then Return False

		Local oldExperience:Int = GetExperience()
		Local oldLevel:Int = GetLevel()
		Local oldLevelXP:Float = GetLevelExperiencePercentage()
		Local oldXP:Float = GetExperiencePercentage()

		'add programme
		producedProgrammeIDs :+ [programmeDataID]
		'gain some xp
		SetExperience(GetExperience() + GetNextExperienceGain(programmeDataID))
		TLogger.Log("TProductionCompany", "Finish production and gained experience. Experience: "+ oldExperience +"->"+GetExperience() + "   Level: " + oldLevel+"->"+GetLevel() +"   LevelXP: " + MathHelper.NumberToString(oldLevelXP*100,2)+"->"+MathHelper.NumberToString(GetLevelExperiencePercentage()*100,2)+"%" +"   XP: "+MathHelper.NumberToString(oldXP*100,2)+"->"+MathHelper.NumberToString(GetExperiencePercentage()*100,2)+"%", LOG_DEBUG)

		Return True
	End Method


	'base might differ depending on sympathy for channel
	Method GetFee:Int(channel:Int=-1)
		Local sympathyMod:Float = 1.0
		'modify by up to 50% ...
		If channel >= 0 Then sympathyMod :- 0.5 * GetChannelSympathy(channel)

		Local xpMod:Float = 1.0
		'up to "* 100" -> 100% xp means 2000*100 = 200000
		xpMod :+ 100 * GetExperiencePercentage()

		Return sympathyMod * priceModifier * (20000 + Floor(Int(10000 * xpMod)/100)*100)
	End Method


	Method GetQuality:Float()
		'quality is based on base quality and an experience based quality
		Local q:Float = 0.25 * baseQuality + 0.75 * GetExperiencePercentage()
		'modified by an individual modifier
		Return Max(0.0, Min(1.0, qualityModifier * q))
	End Method
	
	
	Method OnChangeXP:Int(oldXP:Int, newXP:Int)
		Return True
	End Method


	Method OnChangeLevel:Int(oldLevel:Int, newLevel:Int)
		Return True
	End Method
End Type
