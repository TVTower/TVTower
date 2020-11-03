SuperStrict
Import "game.person.base.bmx"
Import "game.gamerules.bmx"
Import "game.programme.programmedata.bmx"
Import "game.programme.programmerole.bmx"
Import "Dig/base.util.figuregenerator.bmx"
Import "Dig/base.util.persongenerator.bmx"

'loaded on import of the module
'EventManager.registerListenerFunction("personbase.onStartProduction", onPersonBaseStartsProduction)
EventManager.registerListenerFunction("personbase.onFinishProduction", onPersonBaseFinishesProduction)


rem
Function onPersonBaseStartsProduction:int(triggerEvent:TEventBase)
	local p:TPersonBase = TPersonBase(triggerEvent.GetSender())
	if not p then Return False
	
	'only interested in persons useable in productions
	if GameRules.onlyFictionalInCustomProduction and not p.IsFictional() Then Return False

	'remove from previous prefiltered lists
	GetPersonBaseCollection().Remove(p)

	'make sure the person can store production data from now on
	If not p.GetProductionData()
		p.SetProductionData(new TPersonProductionBaseData)
print "add productiondata for " + p.GetFullName()
	EndIf

	'add to now suiting lists
	GetPersonBaseCollection().Add(p)
End Function
endrem



'convert "insignifants" to "celebrities"
Function onPersonBaseFinishesProduction:int(triggerEvent:TEventBase)
	local p:TPersonBase = TPersonBase(triggerEvent.GetSender())
	if not p then return false

	'already done?
	if p.IsCelebrity() Then Return False

	'we cannot convert a non-fictional "insignificant" as we cannot
	'create random birthday dates for a real person...
	if not p.IsFictional() then return False

	if not p.CanLevelUp() then return false

	'make sure the person can store at least basic production data from now on
	If not p.GetProductionData()
		p.SetProductionData(new TPersonProductionBaseData)
	EndIf

'	person.GetPersonalityData().SetRandomAttributes()
'	person.GetProductionData().SetRandomAttributes()

	'jobsDone is increased _after_ finishing the production,
	'so "jobsDone <= 2" will be true until the 3rd production is finishing
	If p.GetTotalProductionJobsDone() <= 2 then return False

	'remove from previous prefiltered lists
	GetPersonBaseCollection().Remove(p)

	p = UpgradePersonBaseData(p)
	p.SetFlag(TVTPersonFlag.CELEBRITY, True)

	'add to now suiting lists
	GetPersonBaseCollection().Add(p)
End Function



'when upgrading a "insignificant to a celebrity"
Function UpgradePersonBaseData:TPersonBase(p:TPersonBase)
	local prodBaseData:TPersonProductionBaseData = p.GetProductionData()
	local persBaseData:TPersonPersonalityBaseData = p.GetPersonalityData()

	If not TPersonProductionData(prodBaseData)
		local prodData:TPersonProductionData = new TPersonProductionData
		prodData.CopyFromBase(prodBaseData)
		p.SetProductionData(prodData)
	EndIf

	If not TPersonPersonalityData(persBaseData)
		local persData:TPersonPersonalityData = new TPersonPersonalityData
		persData.CopyFromBase(persBaseData)
		p.SetPersonalityData(persData)
	EndIf
	
	Return p
End Function



Type TPersonProductionData Extends TPersonProductionBaseData
	'at which genres this person is doing his best job
	'if this is NOT set, it calculates a top genre based on previous
	'productions. So you can use this to override any "dynamic" top genres
	Field topGenre:Int = 0
	'each job has its own xp, xp[0] is used for "general xp"
	Field xp:Int[] = [0]

	Field calculatedTopGenreCache:Int = 0 {nosave}
	'array containing GUIDs of all produced programmes
	Field producedProgrammes:String[] {nosave}
	'array containing IDs of all produced programmes
	Field producedProgrammeIDs:Int[] {nosave}
	Field producedProgrammesCached:Int = False {nosave}

	Const MAX_XP:Int = 10000
	Global PersonsGainExperienceForProgrammes:Int = True
	
	
	Method CopyFromBase:TPersonProductionData(base:TPersonProductionBaseData)
		If Not base Then Return self
		
		self.personID = base.personID
		self._person = base._person

		self.jobsDone = base.jobsDone[ .. ]
		self.producingIDs = base.producingIDs[ .. ]
		self.priceModifier = base.priceModifier

		Return self
	End Method
	
	
	'override
	Method GetTopGenre:Int()
		'if there was no topGenre defined...
		If topGenre <= 0
			If calculatedTopGenreCache > 0 Then Return calculatedTopGenreCache


			Local genres:Int[]
			Local bestGenre:Int=0
			For Local programmeID:Int = EachIn GetProducedProgrammeIDs()
				Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID(programmeID)
				If Not programmeData Then Continue

				Local genre:Int = programmeData.GetGenre()
				If genre > genres.length-1 Then genres = genres[..genre+1]
				genres[genre]:+1
				For Local i:Int = 0 To genres.length-1
					If genres[i] > bestGenre Then bestGenre = i
				Next
			Next

			If bestGenre >= 0 Then calculatedTopGenreCache = bestGenre

			Return calculatedTopGenreCache
		EndIf

		Return topGenre
	End Method


	'override
	Method GetProducedGenreCount:Int(genre:Int)
		Local count:Int = 0
		For Local programmeID:Int = EachIn GetProducedProgrammeIDs()
			Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID(programmeID)
			If Not programmeData Then Continue

			If programmeData.GetGenre() = genre Then count :+ 1
		Next

		Return count
	End Method
	

	'override
	'the base fee when engaged
	'base might differ depending on sympathy for channel
	Method GetBaseFee:Int(jobID:Int, blocks:Int, channel:Int=-1)
		'1 = 1, 2 = 1.75, 3 = 2.5, 4 = 3.25, 5 = 4 ...
		Local blocksMod:Float = 0.25 + blocks * 0.75
		Local sympathyMod:Float = 1.0
		Local xpMod:Float = 1.0
		Local baseFee:Int = 0
		Local dynamicFee:Int = 0

		Select jobID
			Case TVTPersonJob.ACTOR,..
			     TVTPersonJob.SUPPORTINGACTOR, ..
			     TVTPersonJob.HOST
				
				local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()

				'attributes: 0 - 6.0
				Local attributeMod:Float = (p.power + p.humor + p.charisma + p.appearance + 2 * p.skill)
				'attributes: 0 - 12.0  (alternative: "* 1-2")
				attributeMod :* 1.0 + (0.8 * p.fame + 0.2 * p.scandalizing)

				'sympathy: modify by up to 25% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.25 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetEffectiveExperiencePercentage(jobID)

				If jobID = TVTPersonJob.ACTOR
					baseFee = 11000
					dynamicFee = 38000 * attributeMod
				ElseIf jobID = TVTPersonJob.SUPPORTINGACTOR
					baseFee = 6500
					dynamicFee = 14000 * attributeMod
				ElseIf jobID = TVTPersonJob.HOST
					baseFee = 3500
					dynamicFee = 18500 * attributeMod
				EndIf

			Case TVTPersonJob.DIRECTOR,..
			     TVTPersonJob.SCRIPTWRITER
				
				local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()

				'attributes: 0 - 6.0
				Local attributeMod:Float = (2 * p.power + 0.75 * p.humor + 1.25 * p.charisma + 0.5 * p.appearance + 2 * p.skill)
				'attributes: 0 - 13.2  (alternative: "* 1-2.2")
				attributeMod :* 1.0 + (1.1 * p.fame + 0.1 * p.scandalizing)

				'sympathy: modify by up to 25% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.25 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetEffectiveExperiencePercentage(jobID)

				If jobID = TVTPersonJob.DIRECTOR
					baseFee = 13500
					dynamicFee = 22500 * attributeMod
				ElseIf jobID = TVTPersonJob.SCRIPTWRITER
					baseFee = 5000
					dynamicFee = 7500 * attributeMod
				EndIf

			Case TVTPersonJob.MUSICIAN

				local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()

				'attributes: 0 - 6.0
				Local attributeMod:Float = (1.25 * p.power + 0.5 * p.humor + 1.5 * p.charisma + 1.0 * p.appearance + 1.75 * p.skill)
				'attributes: 0 - 18  (alternative: "* 1-3")
				attributeMod :* 1.0 + (1.5 * p.fame + 0.5 * p.scandalizing)

				'sympathy: modify by up to 30% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.30 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetEffectiveExperiencePercentage(jobID)

				baseFee = 9000
				dynamicFee = 24500 * attributeMod

			Case TVTPersonJob.REPORTER
				
				local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()

				'attributes: 0 - 6.0
				Local attributeMod:Float = (1.25 * p.power + 0.25 * p.humor + 1.5 * p.charisma + 0.5 * p.appearance + 2.5 * p.skill)
				'attributes: 0 - 9.0  (alternative: "* 1-1.5")
				attributeMod :* 1.0 + (0.4 * p.fame + 0.1 * p.scandalizing)

				'sympathy: modify by up to 50% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.50 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * GetEffectiveExperiencePercentage(jobID)

				baseFee = 4000
				dynamicFee = 6500 * attributeMod

			Case TVTPersonJob.GUEST
				
				local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()

				'attributes: 0 - 1.9
				Local attributeMod:Float = 0.3 * p.humor + 0.3 * p.charisma + 0.3 * p.appearance + p.skill
				'attributes: 0 - 6.65  (alternative: "* 1-3.5")
				attributeMod :* 1.0 + (2 * p.fame + 0.5 * p.scandalizing)

				'sympathy: modify by up to 50% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.5 * p.GetChannelSympathy(channel)

				'xp: up to "75% of XP"
				xpMod :+ 0.75 * GetEffectiveExperiencePercentage(jobID)

				baseFee = 1500
				dynamicFee = 6000 * attributeMod
			Default
				
				local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()

				'print "FEE for jobID="+jobID+" not defined."
				'dynamic fee: 0 - 380
				'attributes: 0 - 2.1
				Local attributeMod:Float = 0.1 * p.humor + 0.4 * p.charisma + 0.4 * p.appearance + 1.2 * p.skill
				'attributes: 0 - 4.83  (alternative: "* 1-2.3")
				attributeMod :* 1.0 + (1.1 * p.fame + 0.2 * p.scandalizing)

				'modify by up to 25% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.25 * p.GetChannelSympathy(channel)

				'xp: up to "25% of XP"
				xpMod :+ 0.25 * GetEffectiveExperiencePercentage(jobID)

				baseFee = 3000
				dynamicFee = 7000 * attributeMod
		End Select

		Local fee:Float = baseFee
		'incorporate the dynamic fee amount
		fee :+ dynamicFee * xpMod * sympathyMod * priceModifier
		'incorporate the block amount modifier
		fee :* blocksMod
		'round to next "1000" block
		'fee = Int(Floor(fee / 1000) * 1000)
		'round to "beautiful" (100, ..., 1000, 1250, 1500, ..., 2500)
		fee = TFunctions.RoundToBeautifulValue(fee)
		Return fee
	End Method
	

	Method _GenerateProducedProgrammesCache:Int()
		producedProgrammes = New String[0]
		producedProgrammeIDs = New Int[0]

		'fill up with already finished
		'ordered by release date
		Local releasedData:TList = GetProgrammeDataCollection().GetFinishedProductionProgrammeDataList()

		If releasedData.Count() > 1
			'latest production on top (list is copied then)
			releasedData = releasedData.reversed()
		EndIf

		For Local programmeData:TProgrammeData = EachIn releasedData
			'skip "paid programming" (kind of live programme)
			If programmeData.HasFlag(TVTProgrammeDataFlag.PAID) Then Continue

			If Not programmeData.HasCastPerson(personID) Then Continue


			'instead of adding episodes, we add the series
			If programmeData.parentGUID
				'skip if already added
				If StringHelper.InArray(programmeData.parentGUID, producedProgrammes)
					Continue
				EndIf
				producedProgrammes :+ [programmeData.parentGUID]

				Local parentData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeData.parentGUID)
				producedProgrammeIDs :+ [parentData.GetID()]
			Else
				producedProgrammes :+ [programmeData.GetGUID()]
				producedProgrammeIDs :+ [programmeData.GetID()]
			EndIf
		Next
		producedProgrammesCached = True
	End Method


	'refresh cache (for newly converted "insignifants" or after a savegame)
	Method GetProducedProgrammes:String[]()
		If Not producedProgrammesCached
			_GenerateProducedProgrammesCache()
		EndIf
		Return producedProgrammes
	End Method


	'refresh cache (for newly converted "insignifants" or after a savegame)
	Method GetProducedProgrammeIDs:Int[]()
		If Not producedProgrammesCached
			_GenerateProducedProgrammesCache()
		EndIf
		Return producedProgrammeIDs
	End Method

	
	Method GetFirstProducedProgrammeID:Int()
		Local earliestYear:Int = -1
		Local earliestID:Int = -1
		For Local programmeDataID:Int = EachIn GetProducedProgrammeIDs()
			Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID(programmeDataID)

			If earliestYear = -1 Or programmeData.GetYear() < earliestYear
				earliestYear = programmeData.GetYear()
				earliestID = programmeData.GetID()
			EndIf
		Next
		Return earliestID
	End Method
	

	Method SetExperience(job:Int, value:Int)
		'limit experience
		value = MathHelper.Clamp(value, 0, MAX_XP)

		Local jobIndex:Int = TVTPersonJob.GetIndex(job)
		If xp.length <= jobIndex Then xp = xp[ .. jobIndex + 1]
		xp[jobIndex] = value

		'recalculate total (average)
		If job <> 0 Then SetExperience(0, GetExperience(0))
	End Method


	Method GetExperience:Int(job:Int)
		Local jobIndex:Int = TVTPersonJob.GetIndex(job)
		If xp.length <= jobIndex Then Return 0


		'total avg requested
		If job <= 0
			If xp.length = 0 Then xp = xp[.. 1]

			Local jobs:Int = 0
			For Local jobXP:Int = EachIn xp
				If jobXP > 0
					jobs :+ 1
					xp[0] :+ jobXP
				EndIf
			Next
			If jobs > 0 Then xp[0] :/ jobs

			Return xp[0]
		EndIf

		Return xp[jobIndex]
	End Method


	'override
	Method GetExperiencePercentage:Float(job:Int)
		Return GetExperience(job) / Float(MAX_XP)
	End Method


	'override
	Method GetEffectiveExperiencePercentage:Float(job:Int)
		Local jobXP:Float = GetExperiencePercentage(job)
		Local result:Float
		Local otherXP:Float
		Local otherWeightMod:Float
		
		'add partial XP of other "also suiting" jobs
		'(an actor can also act as supporting actor ...)
		Select job
			Case TVTPersonJob.GUEST
				'take the best job the person can do
				otherXP  = 1.00 * GetBestJobExperiencePercentage()
				otherWeightMod = 0.9
				'print GetFullName() + " as guest. jobXP=" + jobXP + "  otherXP="+otherXP

			Case TVTPersonJob.ACTOR
				'> 1.0 (so weight mod needs to make sure to stay < 1.0 at the end)
				otherXP  = 0.90 * GetExperiencePercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.20 * GetExperiencePercentage(TVTPersonJob.MUSICIAN)
				otherWeightMod = 0.75

			Case TVTPersonJob.SUPPORTINGACTOR
				'> 1.0 (so weight mod needs to make sure to stay < 1.0 at the end)
				otherXP  = 0.90 * GetExperiencePercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.20 * GetExperiencePercentage(TVTPersonJob.MUSICIAN)
				otherWeightMod = 0.60

			Case TVTPersonJob.HOST
				otherXP  = 0.35 * GetExperiencePercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.20 * GetExperiencePercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.30 * GetExperiencePercentage(TVTPersonJob.MUSICIAN)
				otherXP :+ 0.15 * GetExperiencePercentage(TVTPersonJob.REPORTER)
				otherWeightMod = 0.4

			Case TVTPersonJob.DIRECTOR
				otherXP  = 0.50 * GetExperiencePercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.40 * GetExperiencePercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.05 * GetExperiencePercentage(TVTPersonJob.HOST)
				otherXP :+ 0.05 * GetExperiencePercentage(TVTPersonJob.REPORTER)
				otherWeightMod = 0.2

			Case TVTPersonJob.SCRIPTWRITER
				otherXP  = 0.50 * GetExperiencePercentage(TVTPersonJob.DIRECTOR)
				otherXP :+ 0.20 * GetExperiencePercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.15 * GetExperiencePercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.10 * GetExperiencePercentage(TVTPersonJob.MUSICIAN) 'they write songs!
				otherXP :+ 0.05 * GetExperiencePercentage(TVTPersonJob.REPORTER)
				otherWeightMod = 0.15

			Default
				otherXP = 0
				otherWeightMod = 0
		End Select

		Return (jobXP + otherWeightMod * (1.0 - jobXP) * otherXP)
	End Method


	'returns job with best XP
	Method GetBestJob:Int()
		If xp.length = 0 Then Return 0

		Local bestIndex:Int = -1
		Local bestXP:Int
		For Local jobIndex:Int = 0 Until xp.length
			If bestIndex = -1 Or bestXP < xp[jobIndex] 
				bestIndex = jobIndex
				bestXP = xp[jobIndex]
			EndIf
		Next
		
		Return TVTPersonJob.GetAtIndex(bestIndex)
	End Method


	'returns best xp value
	Method GetBestJobExperience:Int()
		If xp.length = 0 Then Return 0

		Local bestIndex:Int = -1
		Local bestXP:Int
		For Local jobIndex:Int = 0 Until xp.length
			If bestIndex = -1 Or bestXP < xp[jobIndex] 
				bestIndex = jobIndex
				bestXP = xp[jobIndex]
			EndIf
		Next
		
		Return bestXP
	End Method


	'returns xp percentage of best job
	Method GetBestJobExperiencePercentage:Float()
		Return GetBestJobExperience() / Float(MAX_XP)
	End Method


	Method GetNextExperienceGain:Int(job:Int, programmeData:TProgrammeData)
		'5 perfect movies would lead to a 100% experienced person
		Local baseGain:Float = ((1.0/5) * MAX_XP) * programmeData.GetQualityRaw()
		'series episodes do not get that much exp
		If programmeData.IsEpisode() Then baseGain :* 0.5

		Local jobXP:Int = GetExperience(job)

		'the more XP we have, the harder it gets
		If jobXP <  500 Then Return 1.0 * baseGain
		If jobXP < 1000 Then Return 0.8 * baseGain
		If jobXP < 2500 Then Return 0.6 * baseGain
		If jobXP < 5000 Then Return 0.4 * baseGain
		Return 0.2 * baseGain
	End Method


	Method GainExperienceForProgramme(programmeDataID:Int)
		Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID( programmeDataID )
		If Not programmeData Then Return
		If Not PersonsGainExperienceForProgrammes Then Return

		'gain experience for each done job
		Local personID:Int = GetPerson().GetID()
		Local creditedJobs:Int[]
		For Local job:TPersonProductionJob = EachIn programmeData.GetCast()
			If job.personID <> personID Then Continue
			'already gained experience for this job (eg. multiple roles
			'played by one actor)
			If MathHelper.InIntArray(job.job, creditedJobs) Then Continue

			creditedJobs :+ [job.job]
			SetExperience(job.job, GetExperience(job.job) + GetNextExperienceGain(job.job, programmeData))
		Next
	End Method



	'override to extend with xp gain + send out events
	Method FinishProduction:Int(programmeDataID:Int, job:Int)
		Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID( programmeDataID )
		'skip headers (series/collections)
		If Not programmeData Or programmeData.IsHeader() Then Return False
		'skip gaining if already done
		'this is checked as "GetProducedProgramme()" also contains
		'new entries already - so an "not inArray" would fail
		'if programmeData.HasLifecycleStep(TVTProgrammeLifecycleStep.PRODUCTION_FINISHED) then return False
		If programmeData.finishedProductionForCast Then Return False


		Super.FinishProduction(programmeDataID, job:Int)

		GainExperienceForProgramme(programmeDataID)

		'add programme (do not just add, as this destroys desc-sort)
		producedProgrammesCached = False
		'producedProgrammes :+ [programmeDataGUID]

		'reset cached calculations
		calculatedTopGenreCache = -1
	End Method
End Type




Type TPersonPersonalityData Extends TPersonPersonalityBaseData
	'cache popularity (possible because the person exists the whole game)
	Field _popularity:TPopularity {nosave}

	Field figure:TFigureGeneratorFigure {nosave} 'should be recreateable via faceCode
	Field figureImage:TImage {nosave}
	'tried to create it?
	Field figureImageCreationFailed:Int = False {nosave}



	Method CopyFromBase:TPersonPersonalityData(base:TPersonPersonalityBaseData)
		If Not base Then Return self
		
		self.dayOfBirth = base.dayOfBirth
		self.dayOfDeath = base.dayOfDeath
		self.skill = base.skill
		self.power = base.power
		self.humor = base.humor
		self.charisma = base.charisma
		self.appearance = base.appearance
		self.fame = base.fame
		self.scandalizing = base.scandalizing
		self.channelSympathy = base.channelSympathy[ .. ]

		Return self
	End Method


	Method GetEarliestProductionYear:Int()
		Local earliestYear:Int = -1

		If GetPerson().GetProductionData()
			Local earliestID:Int = TPersonProductionData(GetPerson().GetProductionData()).GetFirstProducedProgrammeID()
			If earliestID >= 0
				Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID(earliestID)
				earliestYear = programmeData.GetYear()
			EndIf
		EndIf
		'fall back to current year
		If earliestYear = -1 Then earliestYear = GetWorldTime().GetYear()
		
		Return earliestYear
	End Method


	'override
	Method GetAge:Int()
		Local dob:Long = GetDOB()
		'no dob was given
		If dob = 0 Then Return 0

		Local now:Long = GetWorldTime().GetTimeGone()
		If now < dob Then Return 0

		Return GetWorldTime().GetYear(now - dob)
	End Method


	'override
	Method GetDOB:Long()
		If dayOfBirth = "0000-00-00" or dayOfBirth.length < 10
			dayOfBirth = _FixDate(dayOfBirth)
		EndIf

		Return GetWorldTime().GetTimeGoneFromString(dayOfBirth)
	End Method


	'override
	Method GetDOD:Long()
		If dayOfDeath = "0000-00-00" or dayOfDeath.length < 10
			dayOfDeath = _FixDate(dayOfDeath)
		EndIf

		Return GetWorldTime().GetTimeGoneFromString(dayOfDeath)
	End Method


	Method IsBorn:Int()
		Local dob:Long = GetDOB()
		'no dob was given
		If dob = 0 Then Return Super.IsBorn()

		Return GetWorldTime().GetTimeGone() > dob
	End Method

		
	'overide
	Method GetPopularity:TPersonPopularity()
		If Not _popularity
			_popularity = GetPopularityManager().GetByID(personID)
			If Not _popularity
				_popularity = TPersonPopularity.Create(personID, BiasedRandRange(-10, 10, fame), BiasedRandRange(-25, 25, fame))
				GetPopularityManager().AddPopularity(_popularity)
			EndIf
		EndIf
		Return TPersonPopularity(_popularity)
	End Method


	Method SetChannelSympathy:Int(channel:Int, newSympathy:Float)
		If channel < 0 Or channel >= channelSympathy.length Then Return False

		channelSympathy[channel -1] = newSympathy
	End Method


	Method GetChannelSympathy:Float(channel:Int)
		If channel < 0 Or channel >= channelSympathy.length Then Return 0.0

		Return channelSympathy[channel -1]
	End Method


	Method GetFigure:TFigureGeneratorFigure()
		If Not figure
			local p:TPersonBase = GetPerson()
			If Not p.faceCode
				Local ageFlag:Int = 1 'young
				If GetAge() > 50
					ageFlag = 2
					If Rand(100) < 20 Then ageFlag = 1 'make younger
				EndIf

				Local genderFlag:Int = 0 'random
				If p.gender = TVTPersonGender.MALE Then genderFlag = 1
				If p.gender = TVTPersonGender.FEMALE Then genderFlag = 2

				Local skinTone:Int = 0 'random
				Local randomSkin:Int = Rand(100)
				Select p.countryCode.ToLower()
					'asian
					Case "jap", "kor", "vn", "cn", "th"
						skinTone = 1
						If randomSkin < 5 Then skinTone = 3 'caucasian
					'african
					Case "br", "ar", "gh", "sa", "mz", "mex", "ind", "pak"
						skinTone = 2
						If randomSkin < 5 Then skinTone = 3 'caucasian
					'caucasian
					Case "ca", "swe", "no", "fi", "ru", "dk", "d", "de", "fr", "it", "uk", "cz", "pl", "nl", "sui", "aut", "aus"
						skinTone = 3
						If randomSkin < 5
							skinTone = 2
						ElseIf randomSkin < 10
							skinTone = 1
						EndIf
					'caucasian or african and some asian
					Case "us", "usa"
						If randomSkin > 50
							skinTone = 3
						ElseIf randomSkin > 10
							skinTone = 2
						Else
							skinTone = 1
						EndIf
					Default
						If randomSkin < 10      'asian
							skinTone = 3
						ElseIf randomSkin < 50  'african
							skinTone = 2
						Else                    'most actors are caucasian
							skinTone = 1
						EndIf
				End Select

				figure = TFigureGenerator.GenerateFigure(skinTone, genderFlag, ageFlag)
				p.faceCode = figure.GetFigureCode()
			Else
				figure = TFigureGenerator.GenerateFigureFromCode(p.faceCode)
			EndIf
		EndIf
		Return figure
	End Method


	Method GetFigureImage:Object()
		If Not GetFigure() Then Return Null
		If Not figureImage And Not figureImageCreationFailed
			figureImage = GetFigure().GenerateImage()
			If Not figureImage Then figureImageCreationFailed = True
		EndIf
		Return figureImage
	End Method
End Type