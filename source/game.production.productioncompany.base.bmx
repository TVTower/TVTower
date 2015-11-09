SuperStrict
Import Brl.Math
Import "Dig/base.util.string.bmx"


Type TProductionCompanyBase
	'guids of all done productions
	Field producedProgrammes:String[]
	'price manipulation. varying price but constant "quality" 
	Field priceModifier:Float = 1.0
	Field channelSympathy:Float[4]
	Field xp:int = 0

	Const MAX_XP:int = 10000


	Method SetExperience(value:int)
		xp = value
	End Method


	Method GetExperience:int()
		return xp
	End Method


	Method GetExperiencePercentage:Float()
		return GetExperience() / float(MAX_XP)
	End Method


	Method GetNextExperienceGain:int(programmeDataGUID:string)
		return 0
	End Method	


	Method SetChannelSympathy:int(channel:int, newSympathy:float)
		if channel < 0 or channel >= channelSympathy.length then return False

		channelSympathy[channel -1] = newSympathy
	End Method


	Method GetChannelSympathy:float(channel:int)
		if channel < 0 or channel >= channelSympathy.length then return 0.0

		return channelSympathy[channel -1]
	End Method


	Method FinishProduction:int(programmeDataGUID:string)
		'already added
		if StringHelper.InArray(programmeDataGUID, producedProgrammes, False) then return False

		'add programme
		producedProgrammes :+ [programmeDataGUID]

		'gain some xp
		SetExperience(GetExperience() + GetNextExperienceGain(programmeDataGUID))

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

		Return sympathyMod * (3000 + Floor(Int(50 * xpMod * priceModifier)/100)*100)
	End Method
End Type
	