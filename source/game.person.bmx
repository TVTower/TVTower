SuperStrict
Import "game.person.base.bmx"
Import "game.gamerules.bmx"
Import "game.misc.xpcontainer.bmx"
Import "game.programme.programmedata.bmx"
Import "game.programme.programmerole.bmx"
Import "Dig/base.util.figuregenerator.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "game.popularity.person.bmx"

'loaded on import of the module
'EventManager.registerListenerFunction(GameEventKeys.PersonBase_OnStartProduction, onPersonBaseStartsProduction)
EventManager.registerListenerFunction(GameEventKeys.PersonBase_OnFinishProduction, onPersonBaseFinishesProduction)


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

	UpgradeInsignificantToCelebrity(p, False)
End Function


'problematic ambiguous usage of "insignificant"
'insignificant from database do not gain experience but are not shown as "Praktikant"
Function UpgradeInsignificantToCelebrity:Int(p:TPersonBase var, ignoreProductionJobs:Int = True)
	'already done?
	If p.IsCelebrity() Then Return False

	'we cannot convert a non-fictional "insignificant" as we cannot
	'create random birthday dates for a real person...
	If Not p.IsFictional() Then Return False

	If Not p.CanLevelUp() Then Return False

	'make sure the person can store at least basic production data from now on
	If Not p.GetProductionData()
		p.SetProductionData(new TPersonProductionBaseData)
	EndIf

'	person.GetPersonalityData().SetRandomAttributes()
'	person.GetProductionData().SetRandomAttributes()

	'jobsDone is increased _after_ finishing the production,
	'so "jobsDone <= 2" will be true until the 3rd production is finishing
	If Not ignoreProductionJobs
		'check if one job reached the limit ?
		'if total is already below then we can skip the detailed check
		If p.GetTotalProductionJobsDone() < GameRules.UpgradeInsignificantOnProductionJobsCount Then Return False

		local doUpgrade:Int = False
		For local jobID:int = EachIn TVTPersonJob.CAST_IDs
			If p.GetProductionJobsDone(jobID) >= GameRules.UpgradeInsignificantOnProductionJobsCount
				doUpgrade = True
				exit
			EndIf
		Next
		if not doUpgrade Then Return False
	EndIf

	'remove from previous prefiltered lists
	GetPersonBaseCollection().Remove(p)

	p = UpgradePersonBaseData(p)
	p.SetFlag(TVTPersonFlag.CELEBRITY, True)

	'add to now suiting lists
	GetPersonBaseCollection().Add(p)
	
	Return True
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



Function EnsureEnoughCastableCelebritiesPerJob:Int(amount:int, baseCountryCode:String)
	baseCountryCode = baseCountryCode.ToUpper()
	
	Local hasBaseCountryCode:Int = GetPersonGenerator().HasProvider(baseCountryCode)

	'fetch all fictional and bookable celebs
	'onlyFictional, onlyBookable, job, gender, alive, countryCode, forbiddenGUIDs, forbiddenIDs
	local celebrities:TPersonBase[] = GetPersonBaseCollection().GetFilteredCastableCelebritiesArray(True, True, 0, -1, True, "", Null, Null)
	Local castJobIDs:Int[] = TVTPersonJob.GetCastJobs()
	local addedCelebs:TPersonBase[]

	For local jobID:Int = EachIn castJobIDs
		For local genderID:int = EachIn [TVTPersonGender.MALE, TVTPersonGender.FEMALE]
			Local personsFound:Int
			
			For local p:TPersonBase = EachIn celebrities
				if not p.HasJob(jobID) then continue
				if p.gender <> genderID then continue
				
				personsFound :+ 1
				'already found enough?
				if personsFound >= amount Then exit
			Next

			if personsFound < amount
				'also include the newly added ones (might have multiple jobs)
				For local p:TPersonBase = EachIn addedCelebs
					if not p.HasJob(jobID) then continue
					if p.gender <> genderID then continue
					
					personsFound :+ 1
					'already found enough?
					if personsFound >= amount Then exit
				Next
			endif	
			
			if amount - personsFound > 0
				'print "need to create " + (amount - personsFound) + " persons for job " + jobID +" and gender " + genderID

				For local i:int = 0 until (amount - personsFound)
					Local p:TPersonBase

					'90% chance to use baseCountryCode as origin
					if hasBaseCountryCode and RandRange(0, 100) <= 90
						p = GetPersonBaseCollection().CreateRandom(baseCountryCode, genderID)
					else
						p = GetPersonBaseCollection().CreateRandom(GetPersonGenerator().GetRandomCountryCode(), genderID)
					endif
					UpgradeInsignificantToCelebrity(p, True)

					'assign the required job
					p.SetJob(jobID, True)
					'this might set an already enabled job again, so not
					'guaranteed to result in an additional set job
					If RandRange(0, 100) <= 30 then p.SetJob( castJobIDs[RandRange(0, castJobIDs.length - 1)], True)
					If RandRange(0, 100) <= 10 then p.SetJob( castJobIDs[RandRange(0, castJobIDs.length - 1)], True)

					addedCelebs :+ [p]
				Next
			endif
		Next
	Next

	'print "EnsureEnoughCastableCelebritiesPerJob: added " + addedCelebs.length +" new celebs"
	Return addedCelebs.length
End Function


Function GetMainJob:Int(person:TPersonBase)
	Local mainJobID:Int = -1
	Local jobExp:Int=-1
	Local pd:TPersonProductionData=TPersonProductionData(person.GetProductionData())
	For Local jobIndex:Int = 1 To TVTPersonJob.Count
		Local tmpJobID:Int = TVTPersonJob.GetAtIndex(jobIndex)
		If Not person.HasJob(tmpJobID) Then Continue
		Local exp:Int = pd.GetJobExperience(tmpJobID)
		'politicians etc. keep their "job"
		'TODO musicians may be a problem, due to experience change they become actors....
		If exp > jobExp Or (jobIndex > 128 And mainJobID <= 128)
			mainJobID = tmpJobID
			jobExp = exp
		EndIf
	Next
	Return mainJobID
End Function




Type TXPContainer_Job extends TXPContainer
	Method GetValueIndex:Int(key:Int) 
		Return TVTPersonJob.GetIndex(key)
	End Method
	
	Method GetValueKey:Int(index:Int)
		Return TVTPersonJob.GetAtIndex(index)
	End Method

	Method GetEffectivePercentage:Float(key:Int)
		Local jobXP:Float = GetPercentage(key)
		Local result:Float
		Local otherXP:Float
		Local otherWeightMod:Float
		
		'add partial XP of other "also suiting" jobs
		'(an actor can also act as supporting actor ...)
		Select key
			Case TVTPersonJob.GUEST
				'take the best job the person can do
				otherXP  = 1.00 * GetBestPercentage()
				otherWeightMod = 0.9
				'print GetFullName() + " as guest. jobXP=" + jobXP + "  otherXP="+otherXP

			Case TVTPersonJob.ACTOR
				'> 1.0 (so weight mod needs to make sure to stay < 1.0 at the end)
				otherXP  = 0.90 * GetPercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.20 * GetPercentage(TVTPersonJob.MUSICIAN)
				otherWeightMod = 0.75

			Case TVTPersonJob.SUPPORTINGACTOR
				'> 1.0 (so weight mod needs to make sure to stay < 1.0 at the end)
				otherXP  = 0.90 * GetPercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.20 * GetPercentage(TVTPersonJob.MUSICIAN)
				otherWeightMod = 0.60

			Case TVTPersonJob.HOST
				otherXP  = 0.35 * GetPercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.20 * GetPercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.30 * GetPercentage(TVTPersonJob.MUSICIAN)
				otherXP :+ 0.15 * GetPercentage(TVTPersonJob.REPORTER)
				otherWeightMod = 0.4

			Case TVTPersonJob.DIRECTOR
				otherXP  = 0.50 * GetPercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.40 * GetPercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.05 * GetPercentage(TVTPersonJob.HOST)
				otherXP :+ 0.05 * GetPercentage(TVTPersonJob.REPORTER)
				otherWeightMod = 0.2

			Case TVTPersonJob.SCRIPTWRITER
				otherXP  = 0.50 * GetPercentage(TVTPersonJob.DIRECTOR)
				otherXP :+ 0.20 * GetPercentage(TVTPersonJob.ACTOR)
				otherXP :+ 0.15 * GetPercentage(TVTPersonJob.SUPPORTINGACTOR)
				otherXP :+ 0.10 * GetPercentage(TVTPersonJob.MUSICIAN) 'they write songs!
				otherXP :+ 0.05 * GetPercentage(TVTPersonJob.REPORTER)
				otherWeightMod = 0.15

			Default
				otherXP = 0
				otherWeightMod = 0
		End Select

		Return (jobXP + otherWeightMod * (1.0 - jobXP) * otherXP)
	End Method



	Method GetNextGain:Int(key:Int, extra:object, affinity:Float = 0.0)
		local programmeData:TProgrammeData = TProgrammeData(extra)
		if not programmeData then return 0

		'5 perfect movies would lead to a 100% experienced person
		Local baseGain:Float = ((1.0/5) * MAX_XP) * programmeData.GetQualityRaw()
		'series episodes do not get that much exp
		If programmeData.IsEpisode() Then baseGain :* 0.5

		Local xp:Int = Get(key)

		'the more XP we have, the harder it gets
		If xp <  500 Then Return 1.0 * baseGain
		If xp < 1000 Then Return 0.8 * baseGain
		If xp < 2500 Then Return 0.6 * baseGain
		If xp < 5000 Then Return 0.4 * baseGain
		Return (0.2 + 0.25 * affinity) * baseGain
	End Method
End Type




Type TXPContainer_Genre extends TXPContainer
	Method GetValueIndex:Int(key:Int) 
		Return TVTProgrammeGenre.GetIndex(key)
	End Method
	
	Method GetValueKey:Int(index:Int)
		Return TVTProgrammeGenre.GetKey(index)
	End Method

	'takes into consideration OTHER ids too 
	'(eg "actor" for "supportingactor")
	Method GetEffectivePercentage:Float(key:Int)
		Return GetPercentage(key)
	End Method


	Method GetNextGain:Int(key:Int, extra:object, affinity:Float=0.0)
		local programmeData:TProgrammeData = TProgrammeData(extra)
		if not programmeData then return 0

		'5 perfect movies would lead to a 100% experienced person
		Local baseGain:Float = ((1.0/5) * MAX_XP) * programmeData.GetQualityRaw()
		'series episodes do not get that much exp
		If programmeData.IsEpisode() Then baseGain :* 0.5

		Local xp:Int = Get(key)

		'the more XP we have, the harder it gets
		If xp <  500 Then Return 1.0 * baseGain
		If xp < 1000 Then Return 0.8 * baseGain
		If xp < 2500 Then Return 0.6 * baseGain
		If xp < 5000 Then Return 0.4 * baseGain
		Return (0.2 + 0.25 * affinity) * baseGain
	End Method
End Type




Type TPersonProductionData Extends TPersonProductionBaseData
	'at which genres this person is doing his best job
	'if this is NOT set, it calculates a top genre based on previous
	'productions. So you can use this to override any "dynamic" top genres
	Field topGenre:Int = 0
	Field jobXP:TXPContainer_Job = new TXPContainer_Job
	Field genreXP:TXPContainer_Genre = new TXPContainer_Genre

	Field _calculatedTopGenreCache:Int = 0 {nosave}
	Field _producedProgrammesCached:Int = False {nosave}

	Global PersonsGainExperienceForProgrammes:Int = True
	
	
	Method CopyFromBase:TPersonProductionData(base:TPersonProductionBaseData)
		If Not base Then Return self
		
		self.personID = base.personID
		self._person = base._person

		self.jobsDone = base.jobsDone[ .. ]
		self.producedProgrammeIDs = base.producedProgrammeIDs[ .. ]
		self.producingIDs = base.producingIDs[ .. ]
		self.priceModifier = base.priceModifier

		Return self
	End Method
	
	
	'override
	Method GetTopGenre:Int()
		'if there was no topGenre defined...
		If topGenre <= 0
			If _calculatedTopGenreCache > 0 Then Return _calculatedTopGenreCache


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

			If bestGenre >= 0 Then _calculatedTopGenreCache = bestGenre

			Return _calculatedTopGenreCache
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

		'TODO maybe later include genre?
		Local genre:Int = 0
		Local p:TPersonPersonalityBaseData = GetPerson().GetPersonalityData()
		Local power:Float = p.GetAttributeValue(TVTPersonPersonalityAttribute.POWER, jobID, genre)
		Local humor:Float = p.GetAttributeValue(TVTPersonPersonalityAttribute.HUMOR, jobID, genre)
		Local charisma:Float = p.GetAttributeValue(TVTPersonPersonalityAttribute.CHARISMA, jobID, genre)
		Local appearance:Float = p.GetAttributeValue(TVTPersonPersonalityAttribute.APPEARANCE, jobID, genre)
		Local fame:Float = p.GetAttributeValue(TVTPersonPersonalityAttribute.FAME, jobID, genre)
		Local scandalizing:Float = p.GetAttributeValue(TVTPersonPersonalityAttribute.SCANDALIZING, jobID, genre)
		Local experienceModifier:Float = GetEffectiveJobExperiencePercentage(jobID)
		Select jobID
			Case TVTPersonJob.ACTOR,..
			     TVTPersonJob.SUPPORTINGACTOR, ..
			     TVTPersonJob.HOST

				'attributes: 0 - 4.0
				Local attributeMod:Float
				attributeMod :+ power
				attributeMod :+ humor
				attributeMod :+ charisma
				attributeMod :+ appearance
				'attributes: 0 - 8.0
				attributeMod :* 1.0 + (0.8 * fame + 0.2 * scandalizing)

				'sympathy: modify by up to 25% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.25 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * experienceModifier

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

				'attributes: 0 - 6.0
				Local attributeMod:Float
				attributeMod :+ 2.0 * power
				attributeMod :+ 1.0 * humor
				attributeMod :+ 1.50 * charisma
				attributeMod :+ 0.75 * appearance
				'attributes: 0 - 11.2
				attributeMod :* 1.0 + (1.1 * fame + 0.1 * scandalizing)

				'sympathy: modify by up to 25% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.25 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * experienceModifier

				If jobID = TVTPersonJob.DIRECTOR
					baseFee = 13500
					dynamicFee = 22500 * attributeMod
				ElseIf jobID = TVTPersonJob.SCRIPTWRITER
					baseFee = 5000
					dynamicFee = 7500 * attributeMod
				EndIf

			Case TVTPersonJob.MUSICIAN

				'attributes: 0 - 6.0
				Local attributeMod:Float
				attributeMod :+ 1.50 * power
				attributeMod :+ 0.75 * humor
				attributeMod :+ 1.75 * charisma
				attributeMod :+ 1.50 * appearance
				'attributes: 0 - 14.25  (alternative: "* 1-3")
				attributeMod :* 1.0 + (1.5 * fame + 0.5 * scandalizing)

				'sympathy: modify by up to 30% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.30 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * experienceModifier

				baseFee = 9000
				dynamicFee = 24500 * attributeMod

			Case TVTPersonJob.REPORTER

				'attributes: 0 - 6.0
				Local attributeMod:Float
				attributeMod :+ 1.50 * power
				attributeMod :+ 0.50 * humor
				attributeMod :+ 2.00 * charisma
				attributeMod :+ 0.50 * appearance
				'attributes: 0 - 6.75  (alternative: "* 1-1.5")
				attributeMod :* 1.0 + (0.4 * fame + 0.1 * scandalizing)

				'sympathy: modify by up to 50% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.50 * p.GetChannelSympathy(channel)

				'xp: up to "120% of XP"
				xpMod :+ 1.2 * experienceModifier

				baseFee = 4000
				dynamicFee = 6500 * attributeMod

			Case TVTPersonJob.GUEST
				fame = p.GetAttributeValue(TVTPersonPersonalityAttribute.FAME, getMainJob(getPerson()), genre)

				'attributes: 0 - 1.9
				Local attributeMod:Float
				attributeMod :+ 0.60 * power
				attributeMod :+ 0.60 * charisma
				attributeMod :+ 0.50 * appearance
				'attributes: 0 - 5.95  (alternative: "* 1-3.5")
				attributeMod :* 1.0 + (2 * fame + 0.5 * scandalizing)

				'sympathy: modify by up to 50% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.5 * p.GetChannelSympathy(channel)

				'xp: up to "75% of XP"
				xpMod :+ 0.75 * experienceModifier

				baseFee = 3500
				dynamicFee = 9000 * attributeMod

				'higher fame influence of price for guests
				experienceModifier = 0.4 * experienceModifier +  0.4 * fame + 0.2 * scandalizing
			Default

				'print "FEE for jobID="+jobID+" not defined."
				'dynamic fee: 0 - 380
				Local attributeMod:Float
				'attributes: 0 - 2.1
				attributeMod :+ 0.30 * humor
				attributeMod :+ 0.50 * charisma
				attributeMod :+ 0.60 * appearance
				'attributes: 0 - 3.22  (alternative: "* 1-2.3")
				attributeMod :* 1.0 + (1.1 * fame + 0.2 * scandalizing)

				'modify by up to 25% ...
				If channel >= 0 Then sympathyMod = 1.0 - 0.25 * p.GetChannelSympathy(channel)

				'xp: up to "25% of XP"
				xpMod :+ 0.25 * experienceModifier

				baseFee = 3000
				dynamicFee = 7000 * attributeMod
		End Select

		Local fee:Float = feeByExperience(baseFee, dynamicFee * xpMod * sympathyMod * priceModifier, experienceModifier)
		'incorporate the block amount modifier
		fee :* blocksMod
		'round to next "1000" block
		'fee = Int(Floor(fee / 1000) * 1000)
		'round to "beautiful" (100, ..., 1000, 1250, 1500, ..., 2500)
		fee = TFunctions.RoundToBeautifulValue(fee)
		Return fee

		'goal - production early in the game attractive, but later in the game not too cheap
		'increase the fee heavily based on the experience
		'what is the intended growth?
		Function feeByExperience:Float(fee:Float, dynamicFee:Float, xpPercent:Float)
			'Local factor:Float = 1.0045^(300*xpPercent + 30 ) - 1

			'0-1 growing fast, slow
			'Local factor:Float = Sin(xpPercent * 90)

			'0-1 growing slow, fast, slow
			'Local factor:Float = (Sin(xpPercent * 180 - 90) + 1) * 0.5

			'0-2 growing slow, fast, slow
			Local factor:Float = (Sin(xpPercent * 180 - 90) + 1)
			'print xpPercent +" "+factor
			Return fee + dynamicFee * factor
		EndFunction
	End Method
	

	Method _GenerateProducedProgrammesCache:Int()
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
			If programmeData.parentDataID <> 0
				'skip if already added
				If MathHelper.InIntArray(programmeData.parentDataID, producedProgrammeIDs)
					Continue
				EndIf
				producedProgrammeIDs :+ [programmeData.parentDataID]
			Else
				producedProgrammeIDs :+ [programmeData.GetID()]
			EndIf
		Next
		_producedProgrammesCached = True
	End Method


	'refresh cache (for newly converted "insignifants" or after a savegame)
	Method GetProducedProgrammeIDs:Int[]() override
		If Not _producedProgrammesCached
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


	Method GainExperienceForProgramme(programmeDataID:Int)
		Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID( programmeDataID )
		If Not programmeData Then Return
		If Not PersonsGainExperienceForProgrammes Then Return

		'gain experience for each done job
		'TODO update not intuitive on game start for insignificant persons
		'even if they are castable and have a role in an existing licence
		'they gain experience only after the third production
		'(Jonas Becker no job experience after producing a series...)
		'TODO currently non-fictional persons gain experience and have
		'attributes as well - except for fame/scandalizing none should be needed
		'as they cannot appear in custom productions
		Local personID:Int = GetPerson().GetID()
		Local creditedJobs:Int[]
		For Local job:TPersonProductionJob = EachIn programmeData.GetCast()
			If job.personID <> personID Then Continue
			'handle multiple jobFlags
			For Local jobIndex:Int = 1 To TVTPersonJob.castCount
			Local singleJob:Int = TVTPersonJob.GetCastJobAtIndex(jobIndex)
				If (job.job & singleJob) > 0
					'already gained experience for this job (eg. multiple roles
					'played by one actor)
					If MathHelper.InIntArray(singleJob, creditedJobs) Then Continue

					creditedJobs :+ [singleJob]
					'print GetPerson().GetFullName() +" gains XP as " + TVTPersonJob.GetAsString(job.job) +": " + GetJobExperience(job.job) + " + " + GetNextJobExperienceGain(job.job, programmeData)
					SetJobExperience(singleJob, GetJobExperience(singleJob) + GetNextJobExperienceGain(singleJob, programmeData))
				EndIf
			Next
		Next

		'gain experience for genres
		'print GetPerson().GetFullName() +" gains XP for genre " + TVTProgrammeGenre.GetAsString(programmeData.genre) +": " + GetGenreExperience(programmeData.genre) + " + " + GetNextGenreExperienceGain(programmeData.genre, programmeData)
		SetGenreExperience(programmeData.genre, GetNextGenreExperienceGain(programmeData.genre, programmeData))
		For Local subGenre:Int = EachIn programmeData.subGenres
			'subGenres do not give the same amount of XP
			SetGenreExperience(subGenre, int(0.5 * GetNextGenreExperienceGain(subGenre, programmeData)))
			'print GetPerson().GetFullName() +" gains XP for subgenre " + TVTProgrammeGenre.GetAsString(subGenre) +": " + GetGenreExperience(subGenre) + " + " + GetNextGenreExperienceGain(subGenre, programmeData)
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

		'add programme ID? Simply invalidate the cache...
		_producedProgrammesCached = False

		'reset cached calculations
		_calculatedTopGenreCache = -1
	End Method


	'GENRE XP
	Method SetGenreExperience(genreID:Int, value:Int)
		genreXP.Set(genreID, value)
	End Method

	Method GetGenreExperience:Int(genreID:Int)
		Return genreXP.Get(genreID)
	End Method

	Method GetGenreExperiencePercentage:Float(genreID:Int)
		Return genreXP.GetPercentage(genreID)
	End Method

	Method GetEffectiveGenreExperiencePercentage:Float(genreID:Int)
		Return genreXP.GetEffectivePercentage(genreID)
	End Method

	'returns genre with best XP
	Method GetBestGenre:Int()
		Return genreXP.GetBestKey()
	End Method

	'returns best xp value
	Method GetBestGenreExperience:Int()
		Return genreXP.GetBest()
	End Method

	'returns xp percentage of best job
	Method GetBestGenreExperiencePercentage:Float()
		Return genreXP.GetBestPercentage()
	End Method
	
	Method GetNextGenreExperienceGain:Int(genreID:Int, programmeData:TProgrammeData)
		Local affinity:Float = GetPerson().GetPersonalityData().GetAffinityValue(0, genreID)
		Return genreXP.GetNextGain(genreID, programmeData, affinity)
	End Method


	'CONVENIENCE GETTERS/SETTERS
	'JOB XP
	Method SetJobExperience(jobID:Int, value:Int)
		jobXP.Set(jobID, value)
	End Method

	Method GetJobExperience:Int(jobID:Int)
		Return jobXP.Get(jobID)
	End Method

	Method GetJobExperiencePercentage:Float(jobID:Int)
		Return jobXP.GetPercentage(jobID)
	End Method

	Method GetEffectiveJobExperiencePercentage:Float(jobID:Int)
		Return jobXP.GetEffectivePercentage(jobID)
	End Method

	'returns genre with best XP
	Method GetBestJob:Int()
		Return jobXP.GetBestKey()
	End Method

	'returns best xp value
	Method GetBestJobExperience:Int()
		Return jobXP.GetBest()
	End Method

	'returns xp percentage of best job
	Method GetBestJobExperiencePercentage:Float()
		Return jobXP.GetBestPercentage()
	End Method
	
	Method GetNextJobExperienceGain:Int(jobID:Int, programmeData:TProgrammeData)
		Local affinity:Float = GetPerson().GetPersonalityData().GetAffinityValue(jobID, 0)
		Return jobXP.GetNextGain(jobID, programmeData, affinity)
	End Method
End Type




Type TPersonPersonalityData Extends TPersonPersonalityBaseData
	'cache popularity (possible because the person exists the whole game)
	Field _popularity:TPopularity {nosave}

	Field figure:TFigureGeneratorFigure {nosave} 'should be recreateable via faceCode
	Field figureImage:TImage {nosave}
	'tried to create it?
	Field figureImageCreationFailed:Int = False {nosave}
	
	Global PRNG:TXoshiroRandom {nosave}



	Method CopyFromBase:TPersonPersonalityData(base:TPersonPersonalityBaseData)
		If Not base Then Return self
		
		self.dayOfBirth = base.dayOfBirth
		self.dayOfDeath = base.dayOfDeath
		if base.attributes
			self.attributes = base.GetAttributes().Copy()
		endif
	
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

		Local parts:String[] = dayOfBirth.split("-")
		Return GetWorldTime().GetTimeGoneForRealDate(Int(parts[0]),Int(parts[1]),Int(parts[2]))
	End Method


	'override
	Method GetDOD:Long()
		If dayOfDeath = "0000-00-00" or dayOfDeath.length < 10
			dayOfDeath = _FixDate(dayOfDeath)
		EndIf

		Local parts:String[] = dayOfDeath.split("-")
		Return GetWorldTime().GetTimeGoneForRealDate(Int(parts[0]),Int(parts[1]),Int(parts[2]))
	End Method

	
	Method IsDead:Int() override
		Local dod:Long = GetDOD()
		'no dob was given
		If dod = 0 Then Return Super.IsDead()

		Return GetWorldTime().GetTimeGone() < dod
	End MEthod


	Method IsBorn:Int() override
		Local dob:Long = GetDOB()
		'no dob was given
		If dob = 0 Then Return Super.IsBorn()

		Return GetWorldTime().GetTimeGone() > dob
	End Method
	
	
	Method CreatePopularity:TPersonPopularity(popularityValue:Int = -1000, popularityTarget:Int = -1000, person:TPersonBase=Null)
		Local pop:TPersonPopularity
		If Not person
			person = GetPersonBase(personID)

			If Not person
				Throw "cannot create TPersonPopularity without person in person DB: personID="+personID
			EndIf
		EndIf

		Local mainJob:Int = 0
		If person Then mainJob = GetMainJob(person)

		'the more "fame" a person has, the more likely it has some
		'popularity
		local fame:Float = GetAttributeValue(TVTPersonPersonalityAttribute.FAME, mainJob, 0)

		if popularityValue = -1000 then popularityValue = BiasedRandRange(-10, 20, fame)
		popularityValue = Min(Max(popularityValue, -50), 100)

		if popularityTarget = -1000 then popularityTarget = BiasedRandRange(Max(-50, popularityValue - 10), Min(100, popularityValue + 20), fame)
		popularityTarget = Min(Max(popularityTarget, -50), 100)

		pop = TPersonPopularity.Create(personID, popularityValue, popularityTarget)
		pop.referenceGUID = person.GetGUID()

		GetPopularityManager().AddPopularity(pop)
		
		Return pop
	End Method

		
	Method GetPopularity:TPersonPopularity() override
		If Not _popularity
			_popularity = GetPopularityManager().GetByID(personID)
			If Not _popularity Then _popularity = CreatePopularity()
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
				' initialize a custom (global) PRNG with a fixed but individual
				' seed (so the "result" is the same for the given input)
				If not PRNG 
					PRNG = New TXoshiroRandom(p.GetID()) 
				Else
					PRNG.SeedRnd(p.GetID())
				EndIf

				Local ageFlag:Int = 1 'young
				If GetAge() > 50
					ageFlag = 2
					If PRNG.Rand(100) < 20 Then ageFlag = 1 'make younger
				EndIf

				Local genderFlag:Int = 0 'random
				If p.gender = TVTPersonGender.MALE Then genderFlag = 1
				If p.gender = TVTPersonGender.FEMALE Then genderFlag = 2

				Local skinTone:Int = 0 'random
				Local randomSkin:Int = PRNG.Rand(100)
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

				figure = TFigureGenerator.GenerateFigure(skinTone, genderFlag, ageFlag, PRNG)
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
