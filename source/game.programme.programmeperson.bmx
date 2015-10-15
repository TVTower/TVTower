SuperStrict
Import "game.programme.programmeperson.base.bmx"
Import "game.programme.programmedata.bmx"

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
	if p.jobsDone <= 2 then return False


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

	GetProgrammePersonBaseCollection().RemoveInsignificant(currentPerson)
	currentPerson = ConvertInsignificantToCelebrity(currentPerson)
	GetProgrammePersonBaseCollection().AddCelebrity(currentPerson)
End Function




Function ConvertInsignificantToCelebrity:TProgrammePersonBase(insignifant:TProgrammePersonBase)
	'already done
	if TProgrammePerson(insignifant) then return insignifant
	
	local person:TProgrammePerson = new TProgrammePerson
	TProgrammePerson(THelper.TakeOverObjectValues(insignifant, person))

	'give random stats
	person.skill = RandRange(0,10) / 100.0
	person.power = RandRange(0,10) / 100.0
	person.humor = RandRange(0,10) / 100.0
	person.charisma = RandRange(0,10) / 100.0
	person.appearance = RandRange(0,10) / 100.0
	person.fame = RandRange(0,10) / 100.0
	person.scandalizing = RandRange(0,10) / 100.0
	person.priceModifier = 0.85 + 0.3*(RandRange(0,100) / 100.0)

	'gain experience and fetch earliest production date
	local earliestProduction:int = -1


	For local programmeDataGUID:string = EachIn person.GetProducedProgrammes()
		local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeDataGUID)
		person.xp :+ person.GetNextExperienceGain(programmeData)

		if earliestProduction = -1
			earliestProduction = programmeData.year
		else
			earliestProduction = Min(programmeData.year, earliestProduction)
		endif
	Next

	'no production found - or invalid data contained - or not enough produced
	if earliestProduction < 0 or person.GetProducedProgrammes().length < 3
		return insignifant
	endif


	'maybe first movie was done at age of 5 - 40
	'also avoid days 29,30,31 - not possible in all months
	person.dayOfBirth = (earliestProduction - RandRange(5,40))+"-"+RandRange(1,12)+"-"+RandRange(1,28)

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
	field gender:int = 0
	field debut:Int	= 0	
	field country:string = ""
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
	'price manipulation. varying price but constant "quality" 
	field priceModifier:Float = 1.0
	'of interest for shows or special events / trigger for news / 0-1.0
	field scandalizing:float = 0.0
	'at which genres this person is doing his best job
	'TODO: maybe change this later to a general genreExperience-Container
	'which increases over time
	field topGenre1:Int = 0
	field topGenre2:Int = 0
	field calculatedTopGenreCache:int = 0 {nosave}

	'array containing GUIDs of all programmes 
	Field producedProgrammes:string[] {nosave}
	Field producedProgrammesCached:int = False {nosave}

	Field channelSympathy:Float[4]

	Field xp:int = 0
	Const MAX_XP:int = 10000


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
	Method GetBaseFee:Int(jobID:int, channel:int=-1)
		Select jobID
			case TVTProgrammePersonJob.ACTOR, TVTProgrammePersonJob.SUPPORTINGACTOR 
				'TODO: überarbeiten
				'(50 - 650)
				local sum:float = 50 + 100*(power + humor + charisma + appearance + 2*skill)
				Local factor:Float = 1.0 + (fame*0.8 + scandalizing*0.2)

				local sympathyMod:Float = 1.0
				'modify by up to 50% ...
				if channel >= 0 then sympathyMod :- 0.5 * GetChannelSympathy(channel)

				local xpMod:Float = 1.0
				'up to "* 100" -> 100% xp means 2000*100 = 200000
				xpMod :+ 100 * GetExperiencePercentage()

				if jobID = TVTProgrammePersonJob.ACTOR
					Return sympathyMod * (3000 + Floor(Int(100 * sum * factor * xpMod * priceModifier)/100)*100)
				else
					Return sympathyMod * (1500 + Floor(Int(45 * sum * factor * xpMod * priceModifier)/100)*100)
				endif

			case TVTProgrammePersonJob.GUEST
				'TODO: überarbeiten
				local sum:float = 100 + 200*(fame*2 + scandalizing*0.5 + humor*0.3 + charisma*0.3 + appearance*0.3 + skill)

				local sympathyMod:Float = 1.0
				'modify by up to 50% ...
				if channel >= 0 then sympathyMod :- 0.5 * GetChannelSympathy(channel)

				Return sympathyMod * (100 + Floor(Int(sum * priceModifier)/100)*100)
			default
				print "FEE for jobID="+jobID+" not defined."
				return 15000
		End Select
	End Method

	
	'override to extend with xp gain + send out events
	Method FinishProduction:int(programmeDataGUID:string)
		Super.FinishProduction(programmeDataGUID)
		
		local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeDataGUID)
		'already added
		if StringHelper.InArray(programmeDataGUID, producedProgrammes, False) then return False

		'gain experience
		xp :+ GetNextExperienceGain(programmeData)
		

		'add programme
		producedProgrammes :+ [programmeDataGUID]

		producedProgrammesCached = True

		'reset cached calculations
		calculatedTopGenreCache = -1
	End Method


	'refresh cache (for newly converted "insignifants" or after a savegame)
	Method GetProducedProgrammes:String[]()
		if not producedProgrammesCached
			'fill up with already finished
			For local programmeData:TProgrammeData = EachIn GetProgrammeDataCollection().entries.Values()
				if not programmeData.HasCastPerson(self.GetGUID()) then continue
				'skip "paid programming" (kind of live programme)
				if programmeData.HasFlag(TVTProgrammeDataFlag.PAID) then continue

				if programmeData.IsReleased() or programmeData.IsInProduction() or programmeData.IsInCinema()
					producedProgrammes :+ [programmeData.GetGUID()]
				endif
			Next
			producedProgrammesCached = True
		endif
		return producedProgrammes
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
		return country
	End Method


	Method GetCountry:string()
		if country <> ""
			return GetLocale("COUNTRY_CODE_"+country)
		else
			return ""
		endif
	End Method
	

	Method GetCountryLong:string()
		if country <> ""
			return GetLocale("COUNTRY_NAME_"+country)
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

	
	Method GetExperience:int()
		return xp
	End Method


	Method GetExperiencePercentage:Float()
		return xp / float(MAX_XP)
	End Method


	Method GetNextExperienceGain:int(programmeData:TProgrammeData)
		'10 perfect movies would lead to a 100% experienced person
		local baseGain:float = 1000 * programmeData.GetQualityRaw()

		'the more XP we have, the harder it gets
		if xp <  500 then return 1.0 * baseGain
		if xp < 1000 then return 0.8 * baseGain
		if xp < 2500 then return 0.6 * baseGain
		if xp < 5000 then return 0.4 * baseGain
		return 0.2 * baseGain
	End Method


	'override
	Method GetAge:int()
		local dob:Long = GetWorldTime().GetTimeGoneFromString(dayOfBirth)
		'no dob was given
		if dob = 0 then return Super.GetAge()

		local now:Long = GetWorldTime().GetTimeGone()
		if now < dob then return 0

		return GetWorldTime().GetYear( now - dob)
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
End Type