SuperStrict
Import "game.programme.programmeperson.base.bmx"
Import "game.programme.programmedata.bmx"
Import "game.popularity.person.bmx"
Import "basefunctions.bmx"
Import "Dig/base.util.figuregenerator.bmx"
Import "Dig/base.util.persongenerator.bmx"

rem
Type TProgrammePersonCollection extends TProgrammePersonBaseCollection
	Global _instance:TProgrammePersonCollection


	Function GetInstance:TProgrammePersonCollection()
		if not _instance then _instance = new TProgrammePersonCollection
		return _instance
	End Function


	Method GetByGUID:TProgrammePersonBase(GUID:String)
		local result:TProgrammePersonBase
		result = TProgrammePersonBase(insignificant.ValueForKey(GUID))
		if not result
			result = TProgrammePersonBase(celebrities.ValueForKey(GUID))
		endif
		return result
	End Method

	Method GetInsignificantByGUID:TProgrammePersonBase(GUID:String)
		Return TProgrammePersonBase(insignificant.ValueForKey(GUID))
	End Method

	Method GetCelebrityByGUID:TProgrammePerson(GUID:String)
		Return TProgrammePerson(celebrities.ValueForKey(GUID))
	End Method


	Method GetRandomCelebrity:TProgrammePerson(array:TProgrammePerson[] = null)
		if array = Null or array.length = 0 then array = GetAllCelebritiesAsArray()
		If array.length = 0 Then Return Null

		'randRange - so it is the same over network
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllCelebritiesAsArray:TProgrammePerson[]()
		local array:TProgrammePerson[]
		'create a full array containing all elements
		For local obj:TProgrammePerson = EachIn celebrities.Values()
			array :+ [obj]
		Next
		return array
	End Method
End Type
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProgrammePersonCollection:TProgrammePersonCollection()
	Return TProgrammePersonCollection.GetInstance()
End Function
endrem

Function GetProgrammePerson:TProgrammePerson(guid:string)
	Return TProgrammePerson(TProgrammePersonBaseCollection.GetInstance().GetByGUID(guid))
End Function


'loaded on import of the module
EventManager.registerListenerFunction("programmepersonbase.onFinishProduction", onProgrammePersonBaseFinishesProduction)

'convert "insignifants" to "celebrities"
Function onProgrammePersonBaseFinishesProduction:int(triggerEvent:TEventBase)

	local p:TProgrammePersonBase = TProgrammePersonBase(triggerEvent.GetSender())
	if not p then return false

	'we cannot convert a non-fictional "insignificant" as we cannot
	'create random birthday dates for a real person...
	if not p.fictional then return False

	if not p.canLevelUp then return false

	'jobsDone is increased _after_ finishing the production,
	'so "jobsDone <= 2" will be true until the 3rd production is finishing
	if p.GetJobsDone(0) <= 2 then return False


	'do not work with the given person, but fetch it freshly from the
	'collection - so multiple "finishesProductions" (with person objects
	'instead of GUIDs!) wont trigger the conversion multiple times
	local currentPerson:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID(p.GetGUID())
	if not currentPerson
		TLogger.Log("onProgrammePersonBaseFinishesProduction()", "Person "+p.GetFullName()+"  " + p.GetGUID()+" not found.", LOG_ERROR)
		return False
	endif

	'skip celebrities
	if TProgrammePerson(currentPerson) then return False

	'skip failed conversions
	local celeb:TProgrammePersonBase = ConvertInsignificantToCelebrity(currentPerson)
	if not TProgrammePerson(celeb) then return False

	GetProgrammePersonBaseCollection().RemoveInsignificant(currentPerson)
	GetProgrammePersonBaseCollection().AddCelebrity(celeb)
End Function



Function CreateRandomInsignificantPerson:TProgrammePersonBase(countryCode:string, gender:int=0)
	local p:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(countryCode, gender)
	if not p then return null

	local person:TProgrammePersonBase = new TProgrammePersonBase

	person.firstName = p.firstName
	person.lastName = p.lastName
	person.countryCode = p.countryCode
	person.fictional = true
	person.bookable = true
	person.canLevelUp = true

	'avoid others of same name
	GetPersonGenerator().ProtectDataset(p)

	GetProgrammePersonBaseCollection().AddInsignificant(person)

	return person
End Function


Function ConvertInsignificantToCelebrity:TProgrammePersonBase(insignifant:TProgrammePersonBase)
	'already done
	if TProgrammePerson(insignifant) then return insignifant

	local person:TProgrammePerson = new TProgrammePerson
	TProgrammePerson(THelper.TakeOverObjectValues(insignifant, person))

	'give random stats
	person.SetRandomAttributes()

	'gain experience and fetch earliest production date
	local earliestProduction:int = -1


	For local programmeDataGUID:string = EachIn person.GetProducedProgrammes()
		person.GainExperienceForProgramme(programmeDataGUID)

		local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeDataGUID)

		if earliestProduction = -1
			earliestProduction = programmeData.GetYear()
		else
			earliestProduction = Min(programmeData.GetYear(), earliestProduction)
		endif
	Next

	'no production found - or invalid data contained - or not enough produced
	if earliestProduction < 0 or person.GetProducedProgrammes().length < 3
		return insignifant
	endif


	'maybe first movie was done at age of 10 - 40
	'also avoid days 29,30,31 - not possible in all months
	person.dayOfBirth = (earliestProduction - RandRange(10,40))+"-"+RandRange(1,12)+"-"+RandRange(1,28)

	'TODO:
	'Wenn GetAge > 50 dann mit Chance (steigend bis zu 100%)
	'einen Todeszeitpunkt festlegen?
	'NUR bei fiktiven Personen!
	'Dazu brauchen wir die "letzte Produktion" als Minimaldatum (plus
	'ein "Mindestalter" damit wir keine jungen Menschen sterben lassen)

	'emit event so eg. news agency could react to it ("new star is born")
	EventManager.triggerEvent(TEventSimple.Create("programmeperson.newCelebrity", null, person))

	'print "new Star is born: " + person.GetFullName() +", "+person.GetAge()+"years, born " + GetWorldTime().GetFormattedDate( GetWorldTime().GetTimeGoneFromString(person.dayOfBirth))

	return person
End Function




'a person connected to a programme - directors, writers, actors...
Type TProgrammePerson extends TProgrammePersonBase
	field dayOfBirth:string	= "0000-00-00"
	field dayOfDeath:string	= "0000-00-00"
	field debut:Int	= 0
	'income +, reviews +++, bonus in some genres (drama!)
	'directors, musicians: how good is he doing his "craftmanships"
	field skill:float = 0.0
	'income +, speed +++, bonus in some genres (action)
	Field power:float = 0.0
	'income +, speed +++, bonus in some genres (comedy)
	Field humor:float = 0.0
	'income +, reviews ++, bonus in some genres (love, drama, comedy)
	Field charisma:float = 0.0
	'income ++, speed +, bonus in some genres (erotic, love, action)
	Field appearance:float = 0.0
	'income +++
	'how famous is this person?
	field fame:float = 0.0
	'of interest for shows or special events / trigger for news / 0-1.0
	field scandalizing:float = 0.0
	'price manipulation. varying price but constant "quality"
	field priceModifier:Float = 1.0
	'at which genres this person is doing his best job
	'TODO: maybe change this later to a general genreExperience-Container
	'which increases over time
	field topGenre1:Int = 0
	field topGenre2:Int = 0
	field calculatedTopGenreCache:int = 0 {nosave}
	'cache popularity (possible because the person exists the whole game)
	Field _popularity:TPopularity {nosave}

	field figure:TFigureGeneratorFigure
	field figureImage:TImage {nosave}
	'tried to create it?
	field figureImageCreationFailed:int = False {nosave}

	'array containing GUIDs of all programmes
	Field producedProgrammes:string[] {nosave}
	Field producedProgrammesCached:int = False {nosave}

	Field channelSympathy:Float[4]

	'each job has its own xp, xp[0] is used for "general xp"
	Field xp:int[] = [0]
	Const MAX_XP:int = 10000

	Global PersonsGainExperienceForProgrammes:int = True


	Method GenerateGUID:string()
		return "programmeperson-"+id
	End Method


	Method GetTopGenre:Int()
		'if there was no topGenre defined...
		if topGenre1 <= 0
			if calculatedTopGenreCache > 0 then return calculatedTopGenreCache


			local genres:int[]
			local bestGenre:int=0
			For local guid:string = EachIn GetProducedProgrammes()
				local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(guid)
				if not programmeData then continue

				local genre:int = programmeData.GetGenre()
				if genre > genres.length-1 then genres = genres[..genre+1]
				genres[genre]:+1
				For local i:int = 0 to genres.length-1
					if genres[i] > bestGenre then bestGenre = i
				Next
			Next

			if bestGenre >= 0 then calculatedTopGenreCache = bestGenre

			return calculatedTopGenreCache
		endif

		return topGenre1
	End Method



	Method GetProducedGenreCount:Int(genre:int)
		local count:int = 0
		For local guid:string = EachIn GetProducedProgrammes()
			local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(guid)
			if not programmeData then continue

			if programmeData.GetGenre() = genre then count :+ 1
		Next

		return count
	End Method


	Method GetAttribute:float(attributeID:int)
		Select attributeID
			case TVTProgrammePersonAttribute.SKILL
				return skill
			case TVTProgrammePersonAttribute.POWER
				return power
			case TVTProgrammePersonAttribute.HUMOR
				return humor
			case TVTProgrammePersonAttribute.CHARISMA
				return charisma
			case TVTProgrammePersonAttribute.APPEARANCE
				return appearance
			case TVTProgrammePersonAttribute.FAME
				return fame
			case TVTProgrammePersonAttribute.SCANDALIZING
				return scandalizing
			default
				print "ProgrammePerson: unhandled attributeID "+attributeID
				return 0
		End Select
	End Method


	Method SetRandomAttributes:int(onlyEmpty:int=False)
		'reset attributes, so they get all refilled
		if not onlyEmpty
			skill = 0
			power = 0
			humor = 0
			charisma = 0
			appearance = 0
			fame = 0
			scandalizing = 0
			priceModifier = 0
		endif

		'base values
		if skill = 0 then skill = BiasedRandRange(0,100, 0.1) / 100.0
		if power = 0 then power = BiasedRandRange(0,100, 0.1) / 100.0
		if humor = 0 then humor = BiasedRandRange(0,100, 0.1) / 100.0
		if charisma = 0 then charisma = BiasedRandRange(0,100, 0.1) / 100.0
		'given at birth (or by a doctor :-))
		if appearance = 0 then appearance = BiasedRandRange(0,100, 0.2) / 100.0

		'things which might change later on
		if fame = 0 then fame = BiasedRandRange(0,50, 0.1) / 100.0
		if scandalizing = 0 then scandalizing = BiasedRandRange(0,25, 0.2) / 100.0

		if priceModifier = 0 then priceModifier = 0.85 + 0.3*(RandRange(0,100) / 100.0)
	End Method


	Method SetDayOfBirth:Int(date:String="")
		if date = ""
			date = "0000-00-00"
		else
			local parts:string[] = date.split("-")
			if parts.length < 2 then parts :+ ["01"]
			if parts.length < 3 then parts :+ ["01"]
			date = "-".Join(parts)
		endif

		self.dayOfBirth = date
	End Method


	Method SetDayOfDeath:Int(date:String="")
		if date = ""
			date = "0000-00-00"
		else
			local parts:string[] = date.split("-")
			if parts.length < 2 then parts :+ ["01"]
			if parts.length < 3 then parts :+ ["01"]
			date = "-".Join(parts)
		endif

		self.dayOfDeath = date
	End Method


	'override
	'the base fee when engaged
	'base might differ depending on sympathy for channel
	Method GetBaseFee:Int(jobID:int, blocks:int, channel:int=-1)
		'1 = 1, 2 = 1.75, 3 = 2.5, 4 = 3.25, 5 = 4 ...
		local blocksMod:Float = 0.25 + blocks * 0.75
		local sympathyMod:Float = 1.0
		local xpMod:Float = 1.0
		local baseFee:Int = 0
		local dynamicFee:Int = 0

		Select jobID
			case TVTProgrammePersonJob.ACTOR,..
			     TVTProgrammePersonJob.SUPPORTINGACTOR, ..
			     TVTProgrammePersonJob.HOST

				'attributes: 0 - 6.0
				local attributeMod:float = (power + humor + charisma + appearance + 2*skill)
				'attributes: 0 - 12.0  (alternative: "* 1-2")
				attributeMod :* 1.0 + (fame*0.8 + scandalizing*0.2)

				'sympathy: modify by up to 25% ...
				if channel >= 0 then sympathyMod = 1.0 - 0.25 * GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetExperiencePercentage(jobID)

				if jobID = TVTProgrammePersonJob.ACTOR
					baseFee = 11000
					dynamicFee = 38000 * attributeMod
				elseif jobID = TVTProgrammePersonJob.SUPPORTINGACTOR
					baseFee = 6500
					dynamicFee = 14000 * attributeMod
				elseif jobID = TVTProgrammePersonJob.HOST
					baseFee = 3500
					dynamicFee = 18500 * attributeMod
				endif

			case TVTProgrammePersonJob.DIRECTOR,..
			     TVTProgrammePersonJob.SCRIPTWRITER

				'attributes: 0 - 6.0
				local attributeMod:float = (2 * power + 0.75 * humor + 1.25 * charisma + 0.5 * appearance + 2*skill)
				'attributes: 0 - 13.2  (alternative: "* 1-2.2")
				attributeMod :* 1.0 + (fame*1.1 + scandalizing*0.1)

				'sympathy: modify by up to 25% ...
				if channel >= 0 then sympathyMod = 1.0 - 0.25 * GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetExperiencePercentage(jobID)

				if jobID = TVTProgrammePersonJob.DIRECTOR
					baseFee = 13500
					dynamicFee = 22500 * attributeMod
				elseif jobID = TVTProgrammePersonJob.SCRIPTWRITER
					baseFee = 5000
					dynamicFee = 7500 * attributeMod
				endif

			case TVTProgrammePersonJob.MUSICIAN
				'attributes: 0 - 6.0
				local attributeMod:float = (1.25 * power + 0.5 * humor + 1.5 * charisma + 1.0 * appearance + 1.75*skill)
				'attributes: 0 - 18  (alternative: "* 1-3")
				attributeMod :* 1.0 + (fame*1.5 + scandalizing*0.5)

				'sympathy: modify by up to 30% ...
				if channel >= 0 then sympathyMod = 1.0 - 0.30 * GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetExperiencePercentage(jobID)

				baseFee = 9000
				dynamicFee = 24500 * attributeMod

			case TVTProgrammePersonJob.REPORTER
				'attributes: 0 - 6.0
				local attributeMod:float = (1.25 * power + 0.25 * humor + 1.5 * charisma + 0.5 * appearance + 2.5*skill)
				'attributes: 0 - 9.0  (alternative: "* 1-1.5")
				attributeMod :* 1.0 + (fame*0.4 + scandalizing*0.1)

				'sympathy: modify by up to 50% ...
				if channel >= 0 then sympathyMod = 1.0 - 0.50 * GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetExperiencePercentage(jobID)

				baseFee = 4000
				dynamicFee = 6500 * attributeMod

			case TVTProgrammePersonJob.GUEST
				'attributes: 0 - 1.9
				local attributeMod:Float = humor*0.3 + charisma*0.3 + appearance*0.3 + skill
				'attributes: 0 - 6.65  (alternative: "* 1-3.5")
				attributeMod :* 1.0 + (fame*2 + scandalizing*0.5)

				'sympathy: modify by up to 50% ...
				if channel >= 0 then sympathyMod = 1.0 - 0.5 * GetChannelSympathy(channel)

				'xp: up to "50% of XP"
				xpMod :+ 0.5 * GetExperiencePercentage(jobID)

				baseFee = 1500
				dynamicFee = 6000 * attributeMod
			default
				'print "FEE for jobID="+jobID+" not defined."
				'dynamic fee: 0 - 380
				'attributes: 0 - 2.1
				local attributeMod:Float = humor*0.1 + charisma*0.4 + appearance*0.4 + 1.2 * skill
				'attributes: 0 - 4.83  (alternative: "* 1-2.3")
				attributeMod :* 1.0 + (fame*1.1 + scandalizing*0.2)

				'modify by up to 25% ...
				if channel >= 0 then sympathyMod = 1.0 - 0.25 * GetChannelSympathy(channel)

				'xp: up to "25% of XP"
				xpMod :+ 0.25 * GetExperiencePercentage(jobID)

				baseFee = 3000
				dynamicFee = 7000 * attributeMod
		End Select

		local fee:float = baseFee
		'incorporate the dynamic fee amount
		fee :+ dynamicFee * xpMod * sympathyMod * priceModifier
		'incorporate the block amount modifier
		fee :* blocksMod
		'round to next "1000" block
		'fee = Int(Floor(fee / 1000) * 1000)
		'round to "beautiful" (100, ..., 1000, 1250, 1500, ..., 2500)
		fee = TFunctions.RoundToBeautifulValue(fee)
		return fee
	End Method


	'override to extend with xp gain + send out events
	Method FinishProduction:int(programmeDataGUID:string, job:int)
		local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeDataGUID)
		'skip headers (series/collections)
		if not programmeData or programmeData.IsHeader() then return False
		'skip gaining if already done
		'this is checked as "GetProducedProgramme()" also contains
		'new entries already - so an "not inArray" would fail
		'if programmeData.HasLifecycleStep(TVTProgrammeLifecycleStep.PRODUCTION_FINISHED) then return False
		if programmeData.finishedProductionForCast then return False


		Super.FinishProduction(programmeDataGUID, job:int)

		GainExperienceForProgramme(programmeDataGUID)

		'add programme (do not just add, as this destroys desc-sort)
		producedProgrammesCached = False
		'producedProgrammes :+ [programmeDataGUID]

		'reset cached calculations
		calculatedTopGenreCache = -1
	End Method


	'refresh cache (for newly converted "insignifants" or after a savegame)
	Method GetProducedProgrammes:String[]()
		if not producedProgrammesCached
			producedProgrammes = new String[0]

			'fill up with already finished
			'ordered by release date
			local releasedData:TList = GetProgrammeDataCollection().GetFinishedProductionProgrammeDataList()

			if releasedData.Count() > 1
				'latest production on top (list is copied then)
				releasedData = releasedData.reversed()
			endif

			For local programmeData:TProgrammeData = EachIn releasedData
				if not programmeData.HasCastPerson(self.GetGUID()) then continue
				'skip "paid programming" (kind of live programme)
				if programmeData.HasFlag(TVTProgrammeDataFlag.PAID) then continue


				'instead of adding episodes, we add the series
				if programmeData.parentGUID
					'skip if already added
					if StringHelper.InArray(programmeData.parentGUID, producedProgrammes)
						continue
					endif
					producedProgrammes :+ [programmeData.parentGUID]
				else
					producedProgrammes :+ [programmeData.GetGUID()]
				endif
			Next
			producedProgrammesCached = True
		endif
		return producedProgrammes
	End Method


	Method GetPopularity:TPopularity()
		if not _popularity
			_popularity = GetPopularityManager().GetByGUID(GetGUID())
			if not _popularity
				_popularity = TPersonPopularity.Create(GetGUID(), BiasedRandRange(-10, 10, fame), BiasedRandRange(-25, 25, fame))
				GetPopularityManager().AddPopularity(_popularity)
			endif
		endif
		return _popularity
	End Method


	'override
	Method GetPopularityValue:Float()
		return GetPopularity().Popularity
	End Method


	Method SetChannelSympathy:int(channel:int, newSympathy:float)
		if channel < 0 or channel >= channelSympathy.length then return False

		channelSympathy[channel -1] = newSympathy
	End Method


	Method GetChannelSympathy:float(channel:int)
		if channel < 0 or channel >= channelSympathy.length then return 0.0

		return channelSympathy[channel -1]
	End Method


	Method GetCountryCode:string()
		return countryCode
	End Method


	Method GetCountry:string()
		if countryCode <> ""
			return GetLocale("COUNTRY_CODE_"+countryCode)
		else
			return ""
		endif
	End Method


	Method GetCountryLong:string()
		if countryCode <> ""
			return GetLocale("COUNTRY_NAME_"+countryCode)
		else
			return ""
		endif
	End Method


	Method GetSkill:Float()
		return skill
	End Method


	Method GetPower:Float()
		return power
	End Method


	Method GetHumor:Float()
		return humor
	End Method


	Method GetCharisma:Float()
		return charisma
	End Method


	Method GetAppearance:Float()
		return appearance
	End Method


	Method GetFame:Float()
		return fame
	End Method


	Method GetScandalizing:Float()
		return scandalizing
	End Method


	Method SetExperience(job:int, value:int)
		'limit experience
		value = MathHelper.Clamp(value, 0, MAX_XP)

		local jobIndex:int = TVTProgrammePersonJob.GetIndex(job)
		if xp.length <= jobIndex then xp = xp[ .. jobIndex + 1]
		xp[jobIndex] = value

		'recalculate total (average)
		if job <> 0 then SetExperience(0, GetExperience(0))
	End Method


	Method GetExperience:int(job:int)
		local jobIndex:int = TVTProgrammePersonJob.GetIndex(job)
		if xp.length <= jobIndex then return 0


		'total avg requested
		if job <= 0
			if xp.length = 0 then xp = xp[.. 1]

			local jobs:int = 0
			for local jobXP:int = EachIn xp
				if jobXP > 0
					jobs :+ 1
					xp[0] :+ jobXP
				endif
			Next
			if jobs > 0 then xp[0] :/ jobs

			return xp[0]
		endif

		return xp[jobIndex]
	End Method


	Method GetExperiencePercentage:Float(job:int)
		return GetExperience(job) / float(MAX_XP)
	End Method


	Method GetNextExperienceGain:int(job:int, programmeData:TProgrammeData)
		'5 perfect movies would lead to a 100% experienced person
		local baseGain:float = ((1.0/5) * MAX_XP) * programmeData.GetQualityRaw()
		'series episodes do not get that much exp
		if programmeData.IsEpisode() then baseGain :* 0.5

		local jobXP:int = GetExperience(job)

		'the more XP we have, the harder it gets
		if jobXP <  500 then return 1.0 * baseGain
		if jobXP < 1000 then return 0.8 * baseGain
		if jobXP < 2500 then return 0.6 * baseGain
		if jobXP < 5000 then return 0.4 * baseGain
		return 0.2 * baseGain
	End Method


	Method GainExperienceForProgramme(programmeDataGUID:string)
		local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeDataGUID)
		if not programmeData then return
		if not PersonsGainExperienceForProgrammes then return

		'gain experience for each done job
		local creditedJobs:int[]
		For local job:TProgrammePersonJob = EachIn programmeData.GetCast()
			if job.personGUID <> self.GetGUID() then continue
			'already gained experience for this job (eg. multiple roles
			'played by one actor)
			if MathHelper.InIntArray(job.job, creditedJobs) then continue

			creditedJobs :+ [job.job]
			SetExperience(job.job, GetExperience(job.job) + GetNextExperienceGain(job.job, programmeData))
		Next
	End Method


	'override
	Method GetAge:int()
		if dayOfBirth = "0000-00-00" then return Super.GetAge()

		local dob:Long = GetWorldTime().GetTimeGoneFromString(dayOfBirth)
		'no dob was given
		if dob = 0 then return Super.GetAge()

		local now:Long = GetWorldTime().GetTimeGone()
		if now < dob then return 0

		return GetWorldTime().GetYear( now - dob)
	End Method


	Method GetDOB:long()
		return GetWorldTime().GetTimeGoneFromString(dayOfBirth)
	End Method


	'override
	Method IsBorn:int()
		local dob:Long = GetWorldTime().GetTimeGoneFromString(dayOfBirth)
		'no dob was given
		if dob = 0 then return Super.Isborn()

		return GetWorldTime().GetTimeGone() > dob
	End Method


	'override
	Method IsAlive:int()
		return IsBorn()
	End Method


	Method GetFigure:TFigureGeneratorFigure()
		if not figure
			if not faceCode
				local ageFlag:int = 1 'young
				if GetAge() > 50
					ageFlag = 2
					if Rand(100) < 20 then ageFlag = 1 'make younger
				endif

				local genderFlag:int = 0 'random
				if gender = TVTPersonGender.MALE then genderFlag = 1
				if gender = TVTPersonGender.FEMALE then genderFlag = 2

				local skinTone:int = 0 'random
				local randomSkin:int = Rand(100)
				Select countryCode.ToLower()
					'asian
					case "jap", "kor", "vn", "cn", "th"
						skinTone = 1
						if randomSkin < 5 then skinTone = 3 'caucasian
					'african
					case "br", "ar", "gh", "sa", "mz", "mex", "ind", "pak"
						skinTone = 2
						if randomSkin < 5 then skinTone = 3 'caucasian
					'caucasian
					case "ca", "swe", "no", "fi", "ru", "dk", "d", "de", "fr", "it", "uk", "cz", "pl", "nl", "sui", "aut", "aus"
						skinTone = 3
						if randomSkin < 5
							skinTone = 2
						elseif randomSkin < 10
							skinTone = 1
						endif
					'caucasian or african and some asian
					case "us", "usa"
						if randomSkin > 50
							skinTone = 3
						elseif randomSkin > 10
							skinTone = 2
						else
							skinTone = 1
						endif
					default
						if randomSkin < 10      'asian
							skinTone = 3
						elseif randomSkin < 50  'african
							skinTone = 2
						else                    'most actors are caucasian
							skinTone = 1
						endif
				End Select

				figure = TFigureGenerator.GenerateFigure(skinTone, genderFlag, ageFlag)
				faceCode = figure.GetFigureCode()
			else
				figure = TFigureGenerator.GenerateFigureFromCode(faceCode)
			endif
		endif
		return figure
	End Method


	Method GetFigureImage:TImage()
		if not GetFigure() then return Null
		if not figureImage and not figureImageCreationFailed
			figureImage = GetFigure().GenerateImage()
			if not figureImage then figureImageCreationFailed = True
		endif
		return figureImage
	End Method
End Type