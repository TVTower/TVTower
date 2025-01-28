SuperStrict
Import "game.world.worldtime.bmx"
Import "game.production.productionconcept.bmx"
Import "game.programme.newsevent.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.programmecollection.bmx"
Import "game.stationmap.bmx"
Import "game.room.base.bmx"
Import "game.popularity.person.bmx"

rem
Type TProductionCollection Extends TGameObjectCollection
	Field latestProductionByRoomID:TIntMap = new TIntMap
	Global _instance:TProductionCollection

	'override
	Function GetInstance:TProductionCollection()
		If Not _instance Then _instance = New TProductionCollection
		Return _instance
	End Function


	'override to _additionally_ store latest production on a
	'per-room-basis
	Method Add:Int(obj:TGameObject)
		Local p:TProduction = TProduction(obj)
		If p
			If p.studioRoomID
				'if the production is newer than a potential previous
				'production, replace the previous with the new one
				Local previousP:TProduction = GetProductionCollection().GetProductionByRoomID(p.studioRoomID)
				If previousP And previousP.startTime < p.startTime
					latestProductionByRoomID.Insert(p.studioRoomID, p)
				EndIf
			EndIf
		EndIf

		Super.Add(obj)
	End Method


	Method GetProductionByRoomID:TProduction(roomID:Int)
		Local p:TProduction = TProduction(latestProductionByRoomID.ValueForKey(roomID))
	End Method


	Method GetProductionByProducedProgrammeLicenceID:TProduction(programmeLicenceID:Int)
		For local p:TProduction = EachIn entries.Values()
			if p.producedLicenceID = programmeLicenceID Then return p
		Next
		Return Null
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProductionCollection:TProductionCollection()
	Return TProductionCollection.GetInstance()
End Function
endrem



Type TProduction Extends TOwnedGameObject
	Field productionConcept:TProductionConcept
	'in which room was/is this production recorded (might no longer
	'be a studio!)
	Field studioRoomID:Int
	'TVTProductionStep (in_preproduction, finished, ...)
	Field productionStep:Int = 0
	'if > 0 this is the time until which the production is paused/interrupted
	Field pauseStartTime:Long = 0
	Field pauseDuration:Long = 0
	Field paused:Int = False
	'start of shooting / preproduction
	Field startTime:Long = -1
	'end of shooting / preproduction
	Field endTime:Long = -1

	Field scriptGenreFit:Float = -1.0
	Field productionCompanyQuality:Float = 0.0
	Field castFit:Float = -1.0
	Field castComplexity:Float = 0.0
	Field castSympathyMod:Float = 1.0
	Field castFameMod:Float = 1.0
	Field effectiveFocusPointsMod:Float = 1.0
	Field effectiveFocusPoints:Float = 1.0
	Field scriptPotentialMod:Float = 1.0
	Field productionValueMod:Float = 1.0
	Field productionTimeMod:Float = 1.0
	Field productionPriceMod:Float = 1.0

	Field producedLicenceID:Int
	'the programme licence once the production is finished
	'this is cleared after finalizing the production
	'so ensure to add it to the corresponding collections
	Field _designatedProgrammeLicence:TProgrammeLicence

	Global DEV_luckEnabled:Int = True
	Global DEV_InformPerson:Int = True


	Method GenerateGUID:String()
		Return "production-"+id
	End Method


	Method SetProductionConcept(concept:TProductionConcept)
		productionConcept = concept

		If productionConcept
			owner = productionConcept.owner
		Else
			owner = 0
		EndIf
	End Method


	Method GetProductionTimeMod:Float()
		'non player owned productions use "Player0"
		Return productionTimeMod ..
		       * GameConfig.GetModifier("Production.ProductionTimeMod") ..
		       * GameConfig.GetModifier("Production.ProductionTimeMod.player"+Max(0, owner))
	End Method


	Method IsInPreProduction:Int()
		If productionStep = TVTProductionStep.PREPRODUCTION Then Return True
		
		Return False
	End Method


	Method IsPreProductionDone:Int()
		If productionStep = TVTProductionStep.PREPRODUCTION_DONE Then Return True
		
		Return False
	End Method


	Method IsShooting:Int()
		If productionStep = TVTProductionStep.SHOOTING Then Return True
		
		Return False
	End Method


	Method IsInProduction:Int()
		If productionStep = TVTProductionStep.PREPRODUCTION Then Return True
		If productionStep = TVTProductionStep.PREPRODUCTION_DONE Then Return True
		If productionStep = TVTProductionStep.SHOOTING Then Return True
		
		Return False
	End Method


	Method IsAborted:Int()
		Return productionStep = TVTProductionStep.ABORTED
	End Method


	Method IsProduced:Int()
		Return productionStep = TVTProductionStep.FINISHED
	End Method


	Method IsPaused:Int()
		Return paused = True
	End Method


	Method SetPaused:Int(paused:Int = True, pauseDuration:Long)
		self.paused = paused
		self.pauseStartTime = GetWorldTime().GetTimeGone()
		self.pauseDuration = pauseDuration
	End Method


	Method ExtendPause:Int(pauseExtension:Long)
		If not IsPaused()
			SetPaused(True, pauseExtension)
		Else
			self.pauseDuration :+ pauseDuration
		EndIf
	End Method


	Method SetStudio:Int(studioID:Int)
		studioRoomID = studioID
		Return True
	End Method


	'returns a modificator to a script's intrinsic values (speed, review..)
	Method GetProductionValueMod:Float()
		Local value:Float
		'=== BASE ===s
		'if perfectly matching "expectations", we would have a mod of 1.0

		'add script genre fits (up to 25%)
		value :+ 0.25 * scriptGenreFit

		'basic cast fit
		'we assume an average of "10%" to result in "no modification"
		'-> value added: -0.025 - 0.225
		value :+ 0.25 * (castFit - 0.1)
		'the more complex a cast is (more people = more complex)
		'the more it adds
		'-> value added: 0 - 0.2
		value :+ 0.2 * castFit * castComplexity

		'production company quality decides about result too
		'quality:  0.0 to 1.0 (fully experienced)
		'          but might be a bit higher (qualityMod)
		'we assume an average of "20%" to result in "no modification"
		'-> value added: -0.06 - 0.24
		value :+ 0.3 * (productionCompanyQuality - 0.2)

		value = Max(0, value)

		'value now: about 0 - 0.915

		'=== MODIFIERS ===
		'sympathy of the cast influences result a bit
		value :* (0.8 + 0.2 * castSympathyMod)


		'it is important to set the production priority according
		'to the genre
		value :* 1.0 + 0.4 * (effectiveFocusPointsMod - 0.4)

		'more spent focus points "always" leads to a better product
		value :+ 0.01 * productionConcept.GetEffectiveFocusPoints()


		Return value
	End Method


	Method PayProduction:Int()
		'already paid rest?
		If productionConcept.IsBalancePaid() Then Return True
		'something missing?
		If Not productionConcept.IsProduceable() and not IsProduced() Then Return False


		'if invalid owner or finance not existing, skip payment and
		'just set the prodcuction as paid
		If productionConcept.owner > 0 And GetPlayerFinance(productionConcept.owner)
			'for now: forced payment
			GetPlayerFinance(productionConcept.owner).PayProductionStuff(productionConcept.GetTotalCost() - productionConcept.GetDepositCost(), True)

			'TODO: auto-sell the production?
			'      and give back deposit payment?
			'if not GetPlayerFinance(productionConcept.owner).PayProductionStuff(productionConcept.GetTotalCost() - productionConcept.GetDepositCost())
				'return False
			'endif
		EndIf

		If productionConcept.PayBalance() Then Return True

		Return False
	End Method
	
	
	Method BlockStudio(bool:Int = True)
		Local room:TRoomBase = GetRoomBase(studioRoomID) 
		if room
			If bool
				'time in milliseconds
				'use max of now and startTime - just in case production
				'is continued
				Local productionTime:Long = (endTime - Max(startTime, GetWorldTime().GetTimeGone()))
				If productionTime > 0
					'round production time so block is till next xx:x5
					'to avoid people entering the studio before next 
					'production starts (production manager checks in 5
					'minute interval)
					local effectiveEndTime:Long = GetWorldTime().GetTimeGone() + productionTime
					Local minutesTillNextUpdate:Int = 5 - (GetWorldTime().GetDayMinute(effectiveEndTime) mod 5)
					if minutesTillNextUpdate <> 5
						productionTime :+ minutesTillNextUpdate * TWorldTime.MINUTELENGTH
					endif

					If productionConcept.script.IsLive() and not IsPreProductionDone()
						room.SetBlocked(productionTime, TRoomBase.BLOCKEDSTATE_PREPRODUCTION, False)
					Else
						room.SetBlocked(productionTime, TRoomBase.BLOCKEDSTATE_SHOOTING, False)
					EndIf
					room.blockedText = productionConcept.GetTitle()
					If productionConcept.script And productionConcept.script.GetParentScript() And productionConcept.script<>productionConcept.script.GetParentScript()
						Local parent:TScript = productionConcept.script.GetParentScript()
						room.blockedText:+ "~n(" + parent.GetTitle()
						If parent.subScripts
							Local index:Int = -1
							For Local i:Int = 0 To parent.subScripts.length
								If productionConcept.script = parent.subScripts[i]
									index=i
									Exit
								EndIf
							Next
							If index>=0
								room.blockedText:+ " " + (index+1) + "/" + parent.subScripts.length
							EndIf
						EndIf
						room.blockedText:+ ")"
					EndIf
				EndIf
			Else
				'remove block
				room.SetBlocked(0, TRoomBase.BLOCKEDSTATE_NONE, False)
			EndIf
		EndIf
	End Method
	
	
	Method GetProductionTime:Long(reduceProductionTimeFactor:Int = 0)
		'calculate production times
		'when producing several episodes in a row setting up and cleaning
		'the studio can be done faster; the factor is expected to be 0, 1 or 2
		Local productionTime:Long = productionConcept.GetBaseProductionTime()
		If productionTime > 24 * TWorldTime.HOURLENGTH
			reduceProductionTimeFactor :* 3
		Else If productionTime > 12 * TWorldTime.HOURLENGTH
			reduceProductionTimeFactor :* 2
		Else If productionTime < 2 * TWorldTime.HOURLENGTH
			reduceProductionTimeFactor = 0
		Else If productionTime < 3 * TWorldTime.HOURLENGTH
			reduceProductionTimeFactor = Min(1, reduceProductionTimeFactor)
		End if
		productionTime :- reduceProductionTimeFactor * TWorldTime.HOURLENGTH
		
		Return productionTime
	End Method


	Method ScheduleStart:TProduction(scheduledStartTime:Long, reduceProductionTimeFactor:Int = 0, overrideEndTime:Long = -1)
		If productionStep <> TVTProductionStep.NOT_STARTED 
			TLogger.Log("TProduction.ScheduleStart", "Cannot schedule production start: ~q" + productionConcept.GetTitle() +"~q. Already started.", LOG_ERROR)
			Return Null
		EndIf

		TLogger.Log("TProduction.ScheduleStart", "Scheduling production start: ~q" + productionConcept.GetTitle() +"~q. Start at " + GetWorldTime().GetFormattedGameDate(scheduledStartTime)+".", LOG_DEBUG)
		startTime = scheduledStartTime
		endTime = overrideEndTime

		'maybe this means we already begin shooting ?
		UpdateProductionStep()
		
		Return self
	End Method
	

	Method Start:TProduction(reduceProductionTimeFactor:Int = 0, overrideEndTime:Long = -1)
		If productionStep <> TVTProductionStep.NOT_STARTED 
			TLogger.Log("TProduction.Start", "Starting production failed: ~q" + productionConcept.GetTitle() +"~q. Already started.", LOG_ERROR)
			Return Null
		Else
			TLogger.Log("TProduction.Start", "Starting production: ~q" + productionConcept.GetTitle() +"~q.", LOG_DEBUG)
		EndIf

		If Not productionConcept.productionCompany
			TLogger.Log("TProduction.Start", "Cannot Start production. productionConcept.productionCompany NULL !!!!!", LOG_ERROR)
			Return Null
		EndIf


		productionConcept.SetFlag(TVTProductionConceptFlag.PRODUCTION_STARTED, True)


		Local isLiveProduction:Int = productionConcept.script.IsLive()
		'TODO check what is needed for Live
		If isLiveProduction
'			productionConcept.SetLiveTime( productionConcept.GetPlannedLiveTime() )
			'print "Starte Preproduktion: Livezeit = " + production.productionConcept.GetLiveTimeText()
		EndIf


		Local productionTime:Long = GetProductionTime(reduceProductionTimeFactor)
		startTime = GetWorldTime().GetTimeGone()
		'modify production time by mod (TODO: add random plus minus?)
		endTime = startTime + productionTime * GetProductionTimeMod()
		'print "Produktionszeit = " + productionTime+" * "+GetProductionTimeMod()
		'round end time to next xx:x5 to avoid people entering
		'the studio before next production starts (production
		'manager checks in 5 minute interval)
		Local minutesTillNextUpdate:Int = 5 - (GetWorldTime().GetDayMinute(endTime) mod 5)
		if minutesTillNextUpdate <> 5
			endTime :+ minutesTillNextUpdate * TWorldTime.MINUTELENGTH
		endif


		'if a manual endTime is defined, adjust production time accordingly
		'just in case a later code line utilizes this information
		If overrideEndTime >= 0
			endTime = overrideEndTime
			productionTime = Max(0, endTime - startTime)
		EndIf 


		'calculate costs
		productionConcept.CalculateCosts()

		_designatedProgrammeLicence = GenerateProgrammeLicence()
		producedLicenceID = _designatedProgrammeLicence.GetID()

		'emit an event so eg. network can recognize the change
		TriggerBaseEvent(GameEventKeys.Production_Start, Null, Self)

		if isLiveProduction
			BeginPreProduction()
			UpdateProductionStep()
		else
			BeginShooting()
			UpdateProductionStep()
		EndIf

		If productionConcept.script.effects 
			productionConcept.script.effects.update("productionStart", new TData().addInt("playerID", productionConcept.script.owner))
		EndIf

		Return Self
	End Method
	
	
	Method BeginPreProduction:Int()
		If productionStep <> TVTProductionStep.NOT_STARTED Then Return False

		'set studio blocked / update block state
		BlockStudio(True)

		productionStep = TVTProductionStep.PREPRODUCTION
		
		_designatedProgrammeLicence.data.SetState(TVTProgrammeState.IN_PRODUCTION)
		_designatedProgrammeLicence.data.Update()

		TLogger.Log("TProduction.BeginPreProduction()", "Beginning preproduction: ~q" + productionConcept.GetTitle() +"~q", LOG_DEBUG)
		Return True
	End Method


	Method FinishPreProduction:Int()
		If productionStep <> TVTProductionStep.PREPRODUCTION Then Return False
		productionStep = TVTProductionStep.PREPRODUCTION_DONE


		'pay for the production (balance cost)
		If GameRules.payLiveProductionInAdvance
			PayProduction()
		EndIf


		if productionConcept.script.IsLive()
			'make a "placeable" licence (so live pogramme can be planned)
			AddProgrammeLicence()
			'move upcoming production concepts to the left by one slot
			GetProductionConceptCollection().ShiftProductionConceptSlotsByScript(productionConcept.script, -1, productionConcept.studioSlot)
		EndIf


		'emit an event so eg. network can recognize the change
		'or game can display an ingame toast message
		TriggerBaseEvent(GameEventKeys.Production_FinishPreproduction, New TData.Add("programmelicence", _designatedProgrammeLicence), Self)

		TLogger.Log("TProduction.FinishPreProduction()", "Finishing preproduction: ~q" + productionConcept.GetTitle() +"~q", LOG_DEBUG)
		Return True
	End Method
	
	
	Method BeginShooting:Int()
		If productionStep <> TVTProductionStep.NOT_STARTED and productionStep <> TVTProductionStep.PREPRODUCTION_DONE Then Return False

		'now live programme knows when it actually ends...
		If _designatedProgrammeLicence.IsLive()
			startTime = GetWorldTime().GetTimeGone()
			'production starting 20:05
			'1 block : ends at 20:55
			'2 blocks: ends at 21:55
			'ATTENTION: ensure it ends at xx:x5 (as the production 
			'           manager updates in 5 minute intervals)
			Local endMinute:Int = 55
			If _designatedProgrammeLicence.IsEpisode() And _designatedProgrammeLicence.HasBroadcastLimit() ..
				And _designatedProgrammeLicence.GetData() And _designatedProgrammeLicence.GetData().GetBroadcastLimit() = 1
				'#1295 use minute 50, so that finalize sets parent licence tradeable in time for
				'for the removeOnBroadCastLimit check to have the correct licence state
				endMinute = 50
			EndIf
			endTime = GetWorldtime().GetTimeGoneForGameTime(0, 0, GetWorldTime().GetHour(startTime) + (productionConcept.script.GetBlocks()-1), endMinute)
		EndIf

		_designatedProgrammeLicence.data.SetState(TVTProgrammeState.IN_PRODUCTION)
		_designatedProgrammeLicence.data.Update()

		'set studio blocked / update block state
		BlockStudio(True)

		productionStep = TVTProductionStep.SHOOTING

		'calculate mods and values used right when doing the actual
		'production (so not during a possibly 24h earlier done preproduction)
		FixProductionValues()
		'productionValueMod depends on production value which depends on
		'scriptGenreFit - which is calculated in FixProductionValues()
		FixProductionMods()

		'define speed, critics ... based on current cast values, script ...
		FixProgrammeDataValues()

		TLogger.Log("TProduction.BeginShooting()", "Beginning shooting: ~q" + productionConcept.GetTitle() +"~q. Production: "+ GetWorldTime().GetFormattedDate(startTime) + "  -  " + GetWorldTime().GetFormattedDate(endTime), LOG_DEBUG)
		Return True
	End Method
	
	
	Method FinishShooting:Int()
		If productionStep <> TVTProductionStep.SHOOTING Then Return False
		productionStep = TVTProductionStep.SHOOTING_DONE

		TLogger.Log("TProduction.FinishShooting()", "Finishing shooting: ~q" + productionConcept.GetTitle() +"~q", LOG_DEBUG)
		Return True
	End Method
	

	Method Finalize:TProduction()
		'already finalized before
		If productionStep <> TVTProductionStep.SHOOTING_DONE Then Return Self

		'adjust status
		productionStep = TVTProductionStep.FINISHED
		productionConcept.SetFlag(TVTProductionConceptFlag.PRODUCTION_FINISHED, True)


		'pay for the production (balance cost)
		If not GameRules.payLiveProductionInAdvance or not productionConcept.IsBalancePaid()
			PayProduction()
		EndIf


		'inform cast
		For Local castIndex:Int = 0 Until Min(productionConcept.cast.length, productionConcept.script.jobs.length)
			Local p:TPersonBase = productionConcept.cast[castIndex]
			Local job:TPersonProductionJob = productionConcept.script.jobs[castIndex]
			If Not p Or Not job Then Continue

			If DEV_InformPerson
				'person is now capable of doing this job
				p.SetJob(job.job)

				'inform person and adjust its popularity (if it has some)
				Local popularity:TPersonPopularity = TPersonPopularity(p.GetPopularity())
				If popularity
					Local params:TData = New TData
					params.AddNumber("time", GetWorldTime().GetTimeGone())
					params.AddNumber("quality", _designatedProgrammeLicence.data.GetQualityRaw())
					params.AddNumber("job", job.job)

					popularity.FinishProgrammeProduction(params)
				EndIf
			EndIf
		Next

		'fix release time (non live) now
		'fix BEFORE AddProgrammeLicence() so that series headers can
		'adjust their releaseTime accordingly
		if not productionConcept.script.IsLive()
			_designatedProgrammeLicence.data.releaseTime = GetWorldTime().GetTimeGone()
		endif

		'non-live gets added after finishing the production
		if not productionConcept.script.IsLive()
			AddProgrammeLicence()
		endif

		'update programme data so it releases to cinema etc (if needed)
		_designatedProgrammeLicence.data.Update()


		'=== 3. INFORM / REMOVE SCRIPT ===
		'inform production company
		productionConcept.productionCompany.FinishProduction(_designatedProgrammeLicence.data.GetID())

		'inform script about a done production based on the script
		'(parental script is already informed on creation of its licence)
		productionConcept.script.FinishProduction(_designatedProgrammeLicence.GetID())


		'if the script does not allow further productions, it is finished
		'and should be removed from the player
		If owner And GetPlayerProgrammeCollection(owner)
			'series: remove parent if it is finished now
			If productionConcept.script.HasParentScript()
				Local parentScript:TScript = productionConcept.script.GetParentScript()
				If parentScript.IsProduced()
					GetPlayerProgrammeCollection(owner).RemoveScript(parentscript, False)
				EndIf
			EndIf
			'single scripts? done all allowed?
			If Not productionConcept.script.CanGetProducedCount()
				GetPlayerProgrammeCollection(owner).RemoveScript(productionConcept.script, False)
			EndIf
		EndIf
		

		'set a finished series licence tradeable
		'(regardless of owner - might be a non-player)
		If productionConcept.script.HasParentScript()
			Local parentScript:TScript = productionConcept.script.GetParentScript()
			If parentScript and parentScript.IsProduced() and parentScript.isSeries()
				local licence:TProgrammeLicence = GetProgrammeLicenceCollection().Get(parentScript.usedInProgrammeID)
				If licence
					licence.setLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, True)
				EndIf
			EndIf
		EndIf


		'=== 3. REMOVE PRODUCTION CONCEPT ===
		'now only the production itself knows about the concept
		If owner And GetPlayerProgrammeCollection(owner)
			GetPlayerProgrammeCollection(owner).RemoveProductionConcept(productionConcept)
		EndIf
		GetProductionConceptCollection().Remove(productionConcept)

		'move upcoming production concepts to the left by one slot (for live productions this is done after preproduction)
		If not productionConcept.script.IsLive()
			GetProductionConceptCollection().ShiftProductionConceptSlotsByScript(productionConcept.script, -1, productionConcept.studioSlot)
		Endif


		'emit an event so eg. network can recognize the change
		TriggerBaseEvent(GameEventKeys.Production_Finalize, New TData.Add("programmelicence", _designatedProgrammeLicence), Self)

		'do not keep it referenced in TProduction afterwards
		_designatedProgrammeLicence = Null

		Return Self
	End Method


	Method Abort:TProduction()
		productionStep = TVTProductionStep.ABORTED

		TLogger.Log("TProduction.Abort()", "Aborted shooting.", LOG_DEBUG)

		'emit an event so eg. network can recognize the change
		TriggerBaseEvent(GameEventKeys.Production_Abort, Null, Self)

		Return Self
	End Method



	'Generates programmedata without individual review, speed, ... values
	Method GenerateProgrammeData:TProgrammeData()
		'TLogger.Log("TProduction.GenerateProgrammeData()", "Generating programme data.", LOG_DEBUG)


		'=== 1. PROGRAMME CREATION ===
		Local programmeData:TProgrammeData = New TProgrammeData

		If Not programmeData.extra Then programmeData.extra = New TData
		programmeData.extra.AddInt("productionID", self.GetID())
		programmeData.extra.addInt("scriptID", productionConcept.script.GetId())

		If owner <> 0 Then programmeData.extra.AddInt("producerID", owner)

		'=== 2. PROGRAMME BASE PROPERTIES ===
		FillProgrammeData(programmeData, productionConcept)
		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK")
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		programmeData.releaseTime = -1 'release time is on "finish"
		If productionConcept.script.IsLive()
			programmeData.releaseTime = productionConcept.GetLiveTime()
		EndIf
		programmeData.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
		programmeData.dataType = productionConcept.script.scriptLicenceType

		programmeData.SetFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION, True)
		'enable mandatory flags
		programmeData.SetFlag(productionConcept.script.flags, True)

		'check is done here again (and also in GetFinalFlags()) as
		'the script might have changed "liveTime" - so we check it again
		'here
		'do not enable X-Rated for live productions when
		'live time is not in the night
		if productionConcept.script.flags & TVTProgrammeDataFlag.XRATED
			If not productionConcept.script.CanBeXRated()
				programmeData.SetFlag(TVTProgrammeDataFlag.XRATED, False)
			EndIf
		Endif

		If productionConcept.script.targetGroup > 0
			programmeData.SetTargetGroup(productionConcept.script.targetGroup, True)
		EndIf


		'add broadcast limits
		programmeData.SetBroadcastLimit(productionConcept.script.productionBroadcastLimit)

		'=== 3. PROGRAMME CAST ===
		For Local castIndex:Int = 0 Until Min(productionConcept.cast.length, productionConcept.script.jobs.length)
			Local p:TPersonBase = productionConcept.cast[castIndex]
			Local job:TPersonProductionJob = productionConcept.script.jobs[castIndex]
			If Not p Or Not job Then Continue

			If job.roleID
				'transfer role to licence cast for potential variable substitution
				programmeData.AddCast(New TPersonProductionJob.Init(p.GetID(), job.job, job.gender, job.country, job.roleId))
			Else
				programmeData.AddCast(New TPersonProductionJob.Init(p.GetID(), job.job))
			EndIF
		Next

		Return programmeData
	End Method


	'Generate a licence 
	'also generate the licence's programmedata without individual review, speed, ... values
	'(fill these in on "BeginShooting()")
	Method GenerateProgrammeLicence:TProgrammeLicence()
		'TLogger.Log("TProduction.GenerateProgrammeLicence()", "Generating programme licence.", LOG_DEBUG)

		Local programmeGUID:String = "customProduction-"+"-"+productionConcept.script.GetGUID()+"-"+GetGUID()

		Local programmeData:TProgrammeData = GenerateProgrammeData()
		programmeData.SetGUID("data-"+programmeGUID)

		Local programmeLicence:TProgrammeLicence = New TProgrammeLicence
		programmeLicence.SetGUID(programmeGUID)
		programmeLicence.SetData(programmeData)
		programmeLicence.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
		programmeLicence.licenceType = productionConcept.script.scriptLicenceType

		'add flags given in script
		For Local i:Int = 1 To TVTProgrammeLicenceFlag.count
			Local flag:Int = TVTProgrammeLicenceFlag.GetAtIndex(i)
			If productionConcept.script.productionLicenceFlags & flag
				programmeLicence.licenceFlags :| flag
			EndIf
		Next

		'add broadcast flags to both Licence and programme data
		For Local i:Int = 1 To TVTBroadcastMaterialSourceFlag.count
			Local flag:Int = TVTBroadcastMaterialSourceFlag.GetAtIndex(i)
			If productionConcept.script.productionBroadcastFlags & flag
				'setBroadcastFlag creates "broadcastFlags" if required
				programmeLicence.SetBroadcastFlag(flag)
				programmeData.SetBroadcastFlag(flag)
			EndIf
		Next

		If productionConcept.script.IsLive()
			programmeData.releaseTime = productionConcept.script.fixedLiveTime
		End If
		programmeLicence.broadcastTimeSlotStart = productionConcept.script.broadcastTimeSlotStart
		programmeLicence.broadcastTimeSlotEnd = productionConcept.script.broadcastTimeSlotEnd
		programmeData.broadcastTimeSlotStart = productionConcept.script.broadcastTimeSlotStart
		programmeData.broadcastTimeSlotEnd = productionConcept.script.broadcastTimeSlotEnd

		If productionConcept.script.programmeDataModifiers
			if not programmeData.modifiers Then programmeData.modifiers = New TData
			programmeData.modifiers.Append(productionConcept.script.programmeDataModifiers)
		EndIf
		If productionConcept.script.effects
			programmeLicence.effects = productionConcept.script.effects.Copy()
			programmeLicence.effects.removeList("productionStart")
			Local remainingTriggers:Int = programmeLicence.effects.RemoveOrphans()
			If Not remainingTriggers Then programmeLicence.effects = Null
		EndIf
		Return programmeLicence
	End Method
	
	
	Method AddProgrammeLicence()
		'add licence (and its header-licence)
		'for collections and episodes this is the "header", for single
		'elements this is "self"
		Local parentLicence:TProgrammeLicence = _designatedProgrammeLicence
		Local programmeLicence:TProgrammeLicence = _designatedProgrammeLicence
		If programmeLicence.IsEpisode()
			Local parentScript:TScript = productionConcept.script.GetParentScript()
			if not parentScript
				TLogger.Log("AddProgrammeLicence()", "parentScript not existing!", LOG_ERROR)
				Throw("AddProgrammeLicence(): parentScript not existing!")
			endif
			'set episode according to script-episode-index
			programmeLicence.episodeNumber = parentScript.GetSubScriptPosition(productionConcept.script) + 1

			parentLicence = CreateParentalLicence(programmeLicence, TVTProgrammeLicenceType.SERIES)
			'add the episode
			If parentLicence
				'add licence at the position of the defined episode no.
				parentLicence.AddSubLicence(programmeLicence, programmeLicence.episodeNumber - 1)

				'fill that licence with episode specific data
				'(averages, cast, country of production)
				FillParentalLicence(parentLicence)

				GetProgrammeDataCollection().Add(parentLicence.data)
				GetProgrammeLicenceCollection().AddAutomatic(parentLicence)
			Else
				TLogger.Log("AddProgrammeLicence()", "Failed to create parentLicence!", LOG_ERROR)
				Throw "Failed to create parentLicence"
			EndIf
		EndIf

		'make sure release date for live programmes (alwaysLive) is set
		If programmeLicence.isLive() And programmeLicence.getData() and programmeLicence.getData().releaseTime < 0
			programmeLicence.getData().releaseTime = GetWorldTime().GetTimeGone()
		EndIf

		'difficulty price modifier shall not apply to custom productions
		If programmeLicence.IsAPlayersCustomProduction() Then programmeLicence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, True)

		GetProgrammeDataCollection().Add(programmeLicence.data)
		GetProgrammeLicenceCollection().AddAutomatic(programmeLicence)


		'set owner of licence (and sublicences)
		If owner
			'ignore current level (else you can start production and
			'increase reach until production finish)
			parentLicence.SetLicencedAudienceReachLevel(1)
			parentLicence.SetOwner(owner)
		EndIf


		If owner And GetPlayerProgrammeCollection(owner)
			if parentLicence <> programmeLicence
				'only adds if not already added
				GetPlayerProgrammeCollection(owner).AddProgrammeLicence(parentLicence, False)
			endif
			GetPlayerProgrammeCollection(owner).AddProgrammeLicence(programmeLicence, False)
		EndIf
	End Method


	
	Method GetProducedLicence:TProgrammeLicence()
		If _designatedProgrammeLicence
			Return _designatedProgrammeLicence
		ElseIf producedLicenceID
			Return GetProgrammeLicenceCollection().Get(producedLicenceID)
		endif
		Return Null
	End Method


	Method FixProgrammeDataValues:Int()
		if not _designatedProgrammeLicence then Return False
		
		Local pd:TProgrammeData = _designatedProgrammeLicence.data
		
		If productionPriceMod <> 1.0
			pd.SetModifier("price", productionPriceMod)
		EndIf
		
		'=== 3.2 PROGRAMME PRODUCTION PROPERTIES ===
		pd.review = MathHelper.Clamp(productionValueMod * productionConcept.script.review *scriptPotentialMod, 0, 1.0)
		pd.speed = MathHelper.Clamp(productionValueMod * productionConcept.script.speed *scriptPotentialMod, 0, 1.0)
		pd.outcome = MathHelper.Clamp(productionValueMod * productionConcept.script.outcome *scriptPotentialMod, 0, 1.0)
		'modify outcome by castFameMod ("attractors/startpower")
		pd.outcome = MathHelper.Clamp(pd.outcome * castFameMod, 0, 1.0)
	End Method
	
	
	Method FixProductionMods()
		'=== 1. PRODUCTION EFFECTS ===
		'- modify production values (random..)
		'- cast:
		'- - levelups / skill adjustments / XP gain
		'- - adding the job (if not done automatically) so it becomes
		'    specialized for this kind of production somewhen

		'=== 1. PRODUCTION VALUES ===
		productionValueMod = GetProductionValueMod()
		productionPriceMod = 1.0

		If DEV_luckEnabled
			'by 5% chance increase value and 5% chance to decrease
			'- so bad productions create a superior programme (or even worse)
			'- or blockbusters fail for unknown reasons (or get even better)
			Local luck:Int = RandRange(0,100)
			If luck < 5
				productionValueMod :* RandRange(120,135)/100.0
			ElseIf luck > 95
				productionValueMod :* RandRange(65,75)/100.0
			EndIf

			'by 5% chance increase or lower price regardless of value
			luck = RandRange(0,100)
			If luck < 5
				productionPriceMod :+ RandRange(5,20)/100.0
			ElseIf luck > 95
				productionPriceMod :- RandRange(5,20)/100.0
			EndIf
		EndIf

		'custom productions are sellable right after production, and
		'really "young" productions are too expensive, which is why
		'we lower the price at all


		'star power bonus
		'this is calculated at the end, as this is some kind of
		'"advertising bonus" for the outcome-portion
		'local castFameMod:Float = productionConcept.CalculateCastFameMod()
		castFameMod = productionConcept.CalculateCastFameMod()


		'script improvements by the director or experienced actors
		scriptPotentialMod = productionConcept.CalculateScriptPotentialMod()

rem
		TLogger.Log("TProduction.FixProductionMods()", "ProductionValueMod    : "+GetProductionValueMod(), LOG_DEBUG)
		'TLogger.Log("TProduction.FixProductionMods()", "ProductionValueMod end: "+productionValueMod, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionMods()", "ProductionPriceMod    : "+productionPriceMod, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionMods()", "CastFameMod           : "+castFameMod, LOG_DEBUG)
endrem
	End Method
	
	
	Method FixProductionValues()
		'=== 1. CALCULATE BASE PRODUCTION VALUES ===

		'=== 1.1 CALCULATE FITS ===

		'=== 1.1.1 GENRE ===
		'Compare genre definition with script values (expected vs real)
		scriptGenreFit = productionConcept.CalculateScriptGenreFit(True)

		'=== 1.1.2 CAST ===
		'Calculate how the selected cast fits to their assigned jobs
		castFit = productionConcept.CalculateCastFit(True)
		castComplexity = productionConcept.CalculateCastComplexity(True)

		'=== 1.1.3 PRODUCTIONCOMPANY ===
		'Calculate how the selected company does its job at all
		productionCompanyQuality = productionConcept.productionCompany.GetQuality()


		'=== 1.2 INDIVIDUAL IMPROVEMENTS ===

		'=== 1.2.1 CAST SYMPATHY ===
		'improve cast job by "sympathy" (they like your channel, so they
		'do a slightly better job)
		castSympathyMod = 1.0 + productionConcept.CalculateCastSympathy(True)

		'=== 1.2.2 MODIFY PRODUCTION VALUE ===
		effectiveFocusPoints = productionConcept.CalculateEffectiveFocusPoints(True)
		effectiveFocusPointsMod = 1.0 + productionConcept.GetEffectiveFocusPointsRatio(True)

rem
		TLogger.Log("TProduction.FixProductionValues()", "scriptGenreFit:           " + scriptGenreFit, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionValues()", "castFit:                  " + castFit, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionValues()", "castComplexity:           " + castComplexity, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionValues()", "castSympathyMod:          " + castSympathyMod, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionValues()", "effectiveFocusPoints:     " + effectiveFocusPoints, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionValues()", "effectiveFocusPointsMod:  " + effectiveFocusPointsMod, LOG_DEBUG)
		TLogger.Log("TProduction.FixProductionValues()", "productionCompanyQuality: " + productionCompanyQuality, LOG_DEBUG)
endrem
	End Method


	Method CreateParentalLicence:TProgrammeLicence(programmeLicence:TProgrammeLicence, parentLicenceType:Int)

		If productionConcept.script = productionConcept.script.GetParentScript() Then Throw "script and parent same : IsEpisode() failed."

		'check if there is already a licence
		'attention: for series this should NOT contain the productionGUID
		'           as this differs for each episode and would lead to a
		'           individual series header for each produced episode
		Local parentProgrammeGUID:String = "customProduction-header-"+productionConcept.script.GetParentScript().GetGUID()
		Local parentLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(parentProgrammeGUID)


		'create new licence if needed
		If Not parentLicence
			parentLicence = New TProgrammeLicence
			parentLicence.SetGUID(parentProgrammeGUID)
			parentLicence.SetData(New TProgrammeData)
			'optional
			parentLicence.GetData().SetGUID("data-"+parentProgrammeGUID)

			'some basic data for the header of series/collections
			parentLicence.GetData().distributionChannel = TVTProgrammeDistributionChannel.TV
			parentLicence.GetData().setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
			'first "episode" is defining "who" did the custom production
			'(if mixed producers happen, a "getProducerPlayerIDs()" must
			' be created which then iterates over all child elements)
			if programmeLicence.GetData().extra
				if not parentLicence.GetData().extra then parentLicence.GetData().extra = new TData
				if programmeLicence.GetData().extra.Has("producerID")
					parentLicence.GetData().extra.AddInt("producerID", programmeLicence.GetData().extra.GetInt("producerID"))
				endif
				if programmeLicence.GetData().extra.Has("productionID")
					parentLicence.GetData().extra.AddInt("productionID", programmeLicence.GetData().extra.GetInt("productionID"))
				endif
			endif
			'store first produced child negatively (maybe useful information) ?
			'for now parents do not get a production ID (as there is no 
			'production done - but for the child elements)
			'parentLicence.GetData().productionID = - self.GetID() 
			parentLicence.GetData().SetFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION, True)

			'difficulty price modifier shall not apply to custom productions
			If parentLicence.IsAPlayersCustomProduction() Then parentLicence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, True)

			'if the template header does not define all licence flags, the ones
			'set for the header heavily depend on the production order of episodes!
			parentLicence.licenceFlags = programmeLicence.licenceFlags

			'fill with basic data (title, description, ...)
			FillProgrammeData(parentLicence.GetData(), productionConcept, productionConcept.script.GetParentScript(), True)

			If parentLicenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.data.dataType = TVTProgrammeDataType.SERIES
			ElseIf parentLicenceType = TVTProgrammeLicenceType.COLLECTION
				parentLicence.licenceType = TVTProgrammeLicenceType.COLLECTION
				parentLicence.data.dataType = TVTProgrammeDataType.COLLECTION
			Else
				'unknown licence type. Fall back to series
				parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.data.dataType = TVTProgrammeDataType.SERIES
			EndIf
			'a series is not tradeable until shooting is finished
			if parentLicence.isSeries() Then parentLicence.setLicenceFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
		Else
			'we already created the parental licence before

			'configured at all?
			If productionConcept.script.GetParentScript().usedInProgrammeID
				'differs to GUID of parent?
				If productionConcept.script.GetParentScript().usedInProgrammeID <> parentLicence.GetID()
					Throw "CreateParentalLicence() failed: another programme is already assigned to the parent script."
				EndIf
			EndIf
		EndIf

		Return parentLicence
	End Method


	'refill data with current information (cast, avg ratings)
	Method FillParentalLicence(parentLicence:TProgrammeLicence)
		'inform parental script about the usage, also increases
		'production count if all episodes are produced (at least +1 than
		'the series production count)
		productionConcept.script.GetParentScript().FinishProduction(parentLicence.GetID())

		Local parentData:TProgrammeData = parentLicence.GetData()


		Local countries:String[]
		Local releaseTime:Long = -1
		For Local subLicence:TProgrammeLicence = EachIn parentLicence.subLicences
			Local c:String = subLicence.GetData().country
			If Not StringHelper.InArray(c, countries) Then countries :+ [c]

			If releaseTime = -1
				releaseTime = subLicence.GetData().releaseTime
			Else
				releaseTime = Min(releaseTime, subLicence.GetData().releaseTime)
			EndIf
		Next
		If countries.length = 0 Then countries :+ ["UNK"]
		parentData.country = " / ".Join(countries)
		parentData.releaseTime = releaseTime

		'=== CAST ===
		'only list "visible" persons: HOST, ACTOR, SUPPORTINGACTOR, GUEST, REPORTER
		Local seriesCast:TPersonBase[]
		Local seriesJobs:TPersonProductionJob[]
		Local jobFilter:Int = TVTPersonJob.HOST | ..
		                      TVTPersonJob.ACTOR | ..
		                      TVTPersonJob.SUPPORTINGACTOR | ..
		                      TVTPersonJob.GUEST | ..
		                      TVTPersonJob.REPORTER
		parentData.ClearCast()
		For Local subLicence:TProgrammeLicence = EachIn parentLicence.subLicences
			For Local job:TPersonProductionJob = EachIn subLicence.GetData().GetCast()
				'only add visible ones
				If job.job & jobFilter <= 0 Then Continue
				'add if that person is not listed with the same job yet
				'(ignore multiple roles)
				If Not parentData.HasCast(job, False)
					parentData.AddCast(New TPersonProductionJob.Init(job.personID, job.job))
				EndIf
			Next
		Next

		'=== RATINGS ===
		parentData.review = 0
		parentData.speed = 0
		parentData.outcome = 0
		Local subLicenceCount:Int = parentLicence.GetSubLicenceCount()
		If subLicenceCount > 0
			For Local subLicence:TProgrammeLicence = EachIn parentLicence.subLicences
				parentData.review :+ subLicence.GetData().review
				parentData.speed :+ subLicence.GetData().speed
				parentData.outcome :+ subLicence.GetData().outcome
			Next
			parentData.review :/ subLicenceCount
			parentData.speed :/ subLicenceCount
			parentData.outcome :/ subLicenceCount
		EndIf
	End Method


	'pass "isSeriesHeader = True" when filling programme data for a series
	'header (as the passed productionConcept is of one of the episodes
	'which might have a custom title/description)
	Function FillProgrammeData(programmeData:TProgrammeData, productionConcept:TProductionConcept, script:TScript = Null, isSeriesHeader:Int = False)
		If script = Null Then script = productionConcept.script

		If isSeriesHeader And script.customTitle
			programmeData.title = New TLocalizedString.Set(script.customTitle)
		ElseIf Not isSeriesHeader And productionConcept.customTitle
			programmeData.title = New TLocalizedString.Set(productionConcept.customTitle)
		Else
			programmeData.title = script.title.Copy()
		EndIf
		If isSeriesHeader And productionConcept.customDescription
			programmeData.description = New TLocalizedString.Set(script.customDescription)
		ElseIf Not isSeriesHeader And productionConcept.customDescription
			programmeData.description = New TLocalizedString.Set(productionConcept.customDescription)
		Else
			programmeData.description = script.description.Copy()
		EndIf

		programmeData.blocks = script.GetBlocks()
		programmeData.flags = script.flags
		If script.targetGroupAttractivityMod Then programmeData.targetGroupAttractivityMod = script.targetGroupAttractivityMod

		programmeData.genre = script.mainGenre
		If script.subGenres
			For Local sg:Int = EachIn script.subGenres
				If sg = 0 Then Continue
				programmeData.subGenres :+ [sg]
			Next
		EndIf
	End Function



	Method UpdateProductionStep:Int()
		'check in UpdateProductionStep() as below might alter pause state
		'but is calling UpdateProductionStep() recursively if needed
		If IsPaused()
				'ignore milliseconds/seconds difference
			If pauseDuration = 0 or (pauseStartTime + pauseDuration)/TWorldTime.MINUTELENGTH <= GetWorldTime().GetTimeGone()/TWorldTime.MINUTELENGTH
'			If pauseDuration = 0 or pauseStartTime + pauseDuration <= GetWorldTime().GetTimeGone()
				'when no longer paused - refresh blocking information with new end time
				endTime = endTime + pauseDuration
				BlockStudio()
				SetPaused(False, 0)
			EndIf
		EndIf
		If IsPaused() then Return False

		
		Select productionStep
			Case TVTProductionStep.NOT_STARTED
				If startTime >= 0 and GetWorldTime().GetTimeGone()/TWorldTime.MINUTELENGTH >= startTime/TWorldTime.MINUTELENGTH
					'pass "endTime" as it might already be set to 
					'a value <> -1 on a ScheduleStart() call
					Start(0, endTime)

					Return UpdateProductionStep()
				EndIf
				Return False
			Case TVTProductionStep.ABORTED
				Return False
			Case TVTProductionStep.FINISHED
				Return False


			Case TVTProductionStep.PREPRODUCTION
				'TODO abort live production if live time reached but preproduction is not yet done
				rem
				If productionConcept.script.fixedLiveTime >= 0 and productionConcept.script.fixedLiveTime < GetWorldTime().GetTimeGone()
					'preproduction not finished but live time reached - abort
					Abort()
					Return UpdateProductionStep()
				EndIf
				endrem
				'finished preproduction?
				'ignore milliseconds/seconds difference
				If GetWorldTime().GetTimeGone()/TWorldTime.MINUTELENGTH >= (endTime + pauseDuration)/TWorldTime.MINUTELENGTH
				'If GetWorldTime().GetTimeGone() >= endTime + pauseDuration
					FinishPreProduction()

					'maybe next step is also fulfilled
					Return UpdateProductionStep()
				EndIf
				Return False


			Case TVTProductionStep.PREPRODUCTION_DONE
				'live productions should not start themselves
				'alwaysLive is started on airing, fixed live time is started by production manager's UpdateLiveProductions
				Return False


			'in production
			Case TVTProductionStep.SHOOTING
				'ignore milliseconds/seconds difference
				If GetWorldTime().GetTimeGone()/TWorldTime.MINUTELENGTH >= endTime/TWorldTime.MINUTELENGTH
				'If GetWorldTime().GetTimeGone() >= finalEndTime
					FinishShooting()

					'maybe next step is also fulfilled
					Return UpdateProductionStep()
				EndIf
				Return False
				
			
			Case TVTProductionStep.SHOOTING_DONE
				Finalize()

				Return True
		End Select

		Return False
	End Method
	

	Method Update:Int()
		local result:Int = UpdateProductionStep()

		Return result
	End Method
End Type
