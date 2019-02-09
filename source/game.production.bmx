SuperStrict
Import "game.world.worldtime.bmx"
Import "game.production.productionconcept.bmx"
Import "game.programme.newsevent.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.programmecollection.bmx"
Import "game.stationmap.bmx"
Import "game.room.base.bmx"
Import "game.popularity.person.bmx"


Type TProductionCollection Extends TGameObjectCollection
	Field latestProductionByRoom:TMap = CreateMap()
	Global _instance:TProductionCollection

	'override
	Function GetInstance:TProductionCollection()
		if not _instance then _instance = new TProductionCollection
		return _instance
	End Function


	'override to _additionally_ store latest production on a
	'per-room-basis
	Method Add:int(obj:TGameObject)
		local p:TProduction = TProduction(obj)
		if p
			local roomGUID:string = p.studioRoomGUID
			if roomGUID <> ""
				'if the production is newer than a potential previous
				'production, replace the previous with the new one
				local previousP:TProduction = GetProductionByRoom(roomGUID)
				if previousP and previousP.startDate < p.startDate
					latestProductionByRoom.Insert(roomGUID, p)
				endif
			endif
		endif

		super.Add(obj)
	End Method


	Method GetProductionByRoom:TProduction(roomGUID:string)
		local p:TProduction = TProduction(latestProductionByRoom.ValueForKey(roomGUID))
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProductionCollection:TProductionCollection()
	Return TProductionCollection.GetInstance()
End Function




Type TProduction Extends TOwnedGameObject
	Field productionConcept:TProductionConcept
	Field producerName:string
	'in which room was/is this production recorded (might no longer
	'be a studio!)
	Field studioRoomGUID:string
	'0 = waiting, 1 = running, 2 = finished, 3 = aborted/paused
	Field status:Int = 0
	'start of shooting
	Field startDate:Double
	'end of shooting
	Field endDate:Double

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

	Field producedLicenceGUID:string

	Global DEV_luckEnabled:int = True
	Global DEV_InformPerson:int = True


	Method GenerateGUID:string()
		return "production-"+id
	End Method


	Method SetProductionConcept(concept:TProductionConcept)
		productionConcept = concept

		if productionConcept
			owner = productionConcept.owner
		else
			owner = 0
		endif
	End Method


	Method GetProductionTimeMod:Float()
		'non player owned productions use "Player0"
		return productionTimeMod ..
		       * GameConfig.GetModifier("Production.ProductionTimeMod") ..
		       * GameConfig.GetModifier("Production.ProductionTimeMod.player"+Max(0, owner))
	End Method


	Method IsInProduction:int()
		return status = 1
	End Method


	Method IsProduced:int()
		return status = 2
	End Method


	Method SetStudio:int(studioGUID:string)
		studioRoomGUID = studioGUID
		return True
	End Method


	'returns a modificator to a script's intrinsic values (speed, review..)
	Method GetProductionValueMod:Float()
		local value:Float
		'=== BASE ===s
		'if perfectly matching "expectations", we would have a mod of 1.0

		'add script genre fits (up to 20%)
		value :+ 0.2 * scriptGenreFit

		'basic cast fit
		'we assume an average of "10" to result in "no modification"
		'-> value added: -0.02 - 0.18
		value :+ 0.2 * (castFit - 0.1)
		'the more complex a cast is (more people = more complex)
		'the more it adds
		'-> value added: 0 - 0.2
		value :+ 0.2 * castFit * castComplexity

		'production company quality decides about result too
		'quality:  0.0 to 1.0 (fully experienced)
		'          but might be a bit higher (qualityMod)
		'we assume an average of "40" to result in "no modification"
		'-> value added: -0.12 - 0.18
		value :+ 0.3 * (productionCompanyQuality - 0.4)

		value = Max(0, value)

		'value now: about 0 - 1.24

		'=== MODIFIERS ===
		'sympathy of the cast influences result a bit
		value :* (0.8 + 0.2 * castSympathyMod)


		'it is important to set the production priority according
		'to the genre
		value :* 1.0 + 0.4 * (effectiveFocusPointsMod - 0.4)

		'more spent focus points "always" leads to a better product
		value :+ 0.01 * productionConcept.GetEffectiveFocusPoints()


		return value
	End Method


	Method PayProduction:int()
		'already paid rest?
		if productionConcept.IsBalancePaid() then return True
		'something missing?
		if not productionConcept.IsProduceable() then return False


		'if invalid owner or finance not existing, skip payment and
		'just set the prodcuction as paid
		if productionConcept.owner > 0 and GetPlayerFinance(productionConcept.owner)
			'for now: forced payment
			GetPlayerFinance(productionConcept.owner).PayProductionStuff(productionConcept.GetTotalCost() - productionConcept.GetDepositCost(), True)

			'TODO: auto-sell the production?
			'      and give back deposit payment?
			'if not GetPlayerFinance(productionConcept.owner).PayProductionStuff(productionConcept.GetTotalCost() - productionConcept.GetDepositCost())
				'return False
			'endif
		endif

		if productionConcept.PayBalance() then return True

		return False
	End Method


	Method Start:TProduction()
		startDate = GetWorldTime().GetTimeGone()
		endDate = startDate + productionConcept.GetBaseProductionTime() * 3600
		TLogger.Log("TProduction.Start", "Starting production ~q"+productionConcept.GetTitle()+"~q. Production: "+ GetWorldTime().GetFormattedDate(startDate) + "  -  " + GetWorldTime().GetFormattedDate(endDate), LOG_DEBUG)

		status = 1

		'calculate costs
		productionConcept.CalculateCosts()


		'=== 1. CALCULATE BASE PRODUCTION VALUES ===

		'=== 1.1 CALCULATE FITS ===

		'=== 1.1.1 GENRE ===
		'Compare genre definition with script values (expected vs real)
		scriptGenreFit = productionConcept.script.CalculateGenreCriteriaFit()

		'=== 1.1.2 CAST ===
		'Calculate how the selected cast fits to their assigned jobs
		castFit = productionConcept.CalculateCastFit()
		castComplexity = productionConcept.CalculateCastComplexity()

		'=== 1.1.3 PRODUCTIONCOMPANY ===
		'Calculate how the selected company does its job at all
		productionCompanyQuality = productionConcept.productionCompany.GetQuality()


		'=== 1.2 INDIVIDUAL IMPROVEMENTS ===

		'=== 1.2.1 CAST SYMPATHY ===
		'improve cast job by "sympathy" (they like your channel, so they
		'do a slightly better job)
		castSympathyMod = 1.0 + productionConcept.CalculateCastSympathy()

		'=== 1.2.2 MODIFY PRODUCTION VALUE ===
		effectiveFocusPoints = productionConcept.CalculateEffectiveFocusPoints()
		effectiveFocusPointsMod = 1.0 + productionConcept.GetEffectiveFocusPointsRatio()

		TLogger.Log("TProduction.Start()", "scriptGenreFit:           " + scriptGenreFit, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "castFit:                  " + castFit, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "castComplexity:           " + castComplexity, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "castSympathyMod:          " + castSympathyMod, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "effectiveFocusPoints:     " + effectiveFocusPoints, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "effectiveFocusPointsMod:  " + effectiveFocusPointsMod, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "productionCompanyQuality: " + productionCompanyQuality, LOG_DEBUG)



		'=== 2. PRODUCTION EFFECTS ===
		'modify production time (longer by random chance?)


		'=== 3. BLOCK STUDIO ===
		'set studio blocked
		if studioRoomGUID and GetRoomBaseByGUID(studioRoomGUID)
			'time in seconds
			'also add 5 minutes to avoid people coming into the studio
			'in the break between two productions
			local productionTime:int = (endDate - startDate) + 600
			productionTime :* GetProductionTimeMod()
			GetRoomBaseByGUID(studioRoomGUID).SetBlocked(productionTime, TRoomBase.BLOCKEDSTATE_SHOOTING)
			GetRoomBaseByGUID(studioRoomGUID).blockedText = productionConcept.GetTitle()
		endif


		'emit an event so eg. network can recognize the change
		EventManager.triggerEvent(TEventSimple.Create("production.start", null, self))

		return self
	End Method


	Method Abort:TProduction()
		status = 3

		TLogger.Log("TProduction.Abort()", "Aborted shooting.", LOG_DEBUG)

		'emit an event so eg. network can recognize the change
		EventManager.triggerEvent(TEventSimple.Create("production.abort", null, self))

		return self
	End Method


	Method Finalize:TProduction()
		'already finalized before
		if status = 2 then return self

		status = 2

		TLogger.Log("TProduction.Finalize()", "Finished shooting.", LOG_DEBUG)

		'pay for the production (balance cost)
		PayProduction()


		'=== 1. PRODUCTION EFFECTS ===
		'- modify production values (random..)
		'- cast:
		'- - levelups / skill adjustments / XP gain
		'- - adding the job (if not done automatically) so it becomes
		'    specialized for this kind of production somewhen

		'=== 1.1 PRODUCTION VALUES ===
		productionValueMod = GetProductionValueMod()
		productionPriceMod = 1.0

		if DEV_luckEnabled
			'by 5% chance increase value and 5% chance to decrease
			'- so bad productions create a superior programme (or even worse)
			'- or blockbusters fail for unknown reasons (or get even better)
			local luck:int = RandRange(0,100)
			if luck < 5
				productionValueMod :* RandRange(120,135)/100.0
			elseif luck > 95
				productionValueMod :* RandRange(65,75)/100.0
			endif

			'by 5% chance increase or lower price regardless of value
			luck = RandRange(0,100)
			if luck < 5
				productionPriceMod :+ RandRange(5,20)/100.0
			elseif luck > 95
				productionPriceMod :- RandRange(5,20)/100.0
			endif
		endif

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


		TLogger.Log("TProduction.Finalize()", "ProductionValueMod    : "+GetProductionValueMod(), LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "ProductionValueMod end: "+productionValueMod, LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "ProductionPriceMod    : "+productionPriceMod, LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "CastFameMod           : "+castFameMod, LOG_DEBUG)


		'=== 1.2 CAST ===
		'change skills of the actors / director / ...



		'=== 2. PROGRAMME CREATION ===
		local programmeData:TProgrammeData = new TProgrammeData
		Local programmeGUID:string = "customProduction-"+"-"+productionConcept.script.GetGUID()+"-"+GetGUID()
		programmeData.SetGUID("data-"+programmeGUID)

		if producerName
			if not programmeData.extra then programmeData.extra = new TData
			programmeData.extra.AddString("producerName", producerName)
		endif

		'=== 2.1 PROGRAMME BASE PROPERTIES ===
		FillProgrammeDataByScript(programmeData, productionConcept.script)
		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK")
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		programmeData.releaseTime = GetWorldTime().GetTimeGone()
		programmeData.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
		programmeData.producedByPlayerID = owner
		programmeData.dataType = productionConcept.script.scriptLicenceType

		programmeData.SetFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION, True)
		'enable mandatory flags
		programmeData.SetFlag(productionConcept.script.flags, True)
		'randomly enable optional flags
		if productionConcept.script.flagsOptional > 0
			For local i:int = 1 until TVTProgrammeDataFlag.count
				local optionalFlag:int = TVTProgrammeDataFlag.GetAtIndex(i)
				if productionConcept.script.flagsOptional & optionalFlag > 0
					'do not enable X-Rated for live productions when
					'live time is not in the night
					if optionalFlag = TVTProgrammeDataFlag.XRATED
						if productionConcept.liveTime <= 22 and productionConcept.liveTime >= 6
							programmeData.SetFlag(optionalFlag, True)
						endif
					else
						programmeData.SetFlag(optionalFlag, True)
					endif
				endif
			Next
		endif

		'add flags given in script
		For local i:int = 1 to TVTBroadcastMaterialSourceFlag.count
			local flag:int = TVTBroadcastMaterialSourceFlag.GetAtIndex(i)
			if productionConcept.script.productionBroadcastFlags & flag
				programmeData.broadcastFlags :| flag
			endif
		Next

		'add broadcast limits
		programmeData.SetBroadcastLimit(productionConcept.script.productionBroadcastLimit)



		'use the defined liveHour, the production is then ready on the
		'next day
		if productionConcept.script.IsLive()
			local nowDay:int = GetWorldTime().GetDay( programmeData.releaseTime )
			'move to next day if live show is in less than 2 hours
			if GetWorldTime().GetTimeGone() - programmeData.releaseTime < 2*3600
				programmeData.releaseTime = GetWorldTime().MakeTime(0, nowDay +1, productionConcept.liveTime, 0, 0)
			else
				programmeData.releaseTime = GetWorldTime().MakeTime(0, nowDay, productionConcept.liveTime, 0, 0)
			endif
		endif
		if productionPriceMod <> 1.0
			programmeData.SetModifier("price", productionPriceMod)
		endif


		'=== 2.2 PROGRAMME PRODUCTION PROPERTIES ===
		programmeData.review = MathHelper.Clamp(productionValueMod * productionConcept.script.review *scriptPotentialMod, 0, 1.0)
		programmeData.speed = MathHelper.Clamp(productionValueMod * productionConcept.script.speed *scriptPotentialMod, 0, 1.0)
		programmeData.outcome = MathHelper.Clamp(productionValueMod * productionConcept.script.outcome *scriptPotentialMod, 0, 1.0)
		'modify outcome by castFameMod ("attractors/startpower")
		programmeData.outcome = MathHelper.Clamp(programmeData.outcome * castFameMod, 0, 1.0)

		if producerName
			if not programmeData.extra then programmeData.extra = new TData
			programmeData.extra.AddString("producerName", producerName)
		endif


		'=== 2.3 PROGRAMME CAST ===
		For local castIndex:int = 0 until Min(productionConcept.cast.length, productionConcept.script.cast.length)
			local p:TProgrammePersonBase = productionConcept.cast[castIndex]
			local job:TProgrammePersonJob = productionConcept.script.cast[castIndex]
			if not p or not job then continue


			if DEV_InformPerson
				'person is now capable of doing this job
				p.SetJob(job.job)
			endif
			programmeData.AddCast(new TProgrammePersonJob.Init(p.GetGUID(), job.job))

			if DEV_InformPerson
				'inform person and adjust its popularity
				if TProgrammePerson(p)
					local popularity:TPersonPopularity = TPersonPopularity(TProgrammePerson(p).GetPopularity())
					if popularity
						local params:TData = new TData
						params.AddNumber("time", GetWorldTime().GetTimeGone())
						params.AddNumber("quality", programmeData.GetQualityRaw())
						params.AddNumber("job", job.job)

						popularity.FinishProgrammeProduction(params)
					endif
				endif
			endif
		Next


		'=== 2.4 PROGRAMME LICENCE ===
		local programmeLicence:TProgrammeLicence = new TProgrammeLicence
		programmeLicence.SetGUID(programmeGUID)
		programmeLicence.SetData(programmeData)
		programmeLicence.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
		programmeLicence.licenceType = productionConcept.script.scriptLicenceType

		'add flags given in script
		For local i:int = 1 to TVTProgrammeLicenceFlag.count
			local flag:int = TVTProgrammeLicenceFlag.GetAtIndex(i)
			if productionConcept.script.productionLicenceFlags & flag
				programmeLicence.licenceFlags :| flag
			endif
		Next


		local addLicence:TProgrammeLicence = programmeLicence
		if programmeLicence.IsEpisode()
			'set episode according to script-episode-index
			programmeLicence.episodeNumber = productionConcept.script.GetParentScript().GetSubScriptPosition(productionConcept.script) + 1

			local parentLicence:TProgrammeLicence = CreateParentalLicence(programmeLicence, TVTProgrammeLicenceType.SERIES)
			'add the episode
			if parentLicence
				'add licence at the position of the defined episode no.
				parentLicence.AddSubLicence(programmeLicence, programmeLicence.episodeNumber - 1)
				addLicence = parentLicence

				'fill that licence with episode specific data
				'(averages, cast, country of production)
				FillParentalLicence(parentLicence)

				GetProgrammeDataCollection().Add(parentLicence.data)
				GetProgrammeLicenceCollection().AddAutomatic(parentLicence)
			else
				debugstop
				Throw "Failed to create parentLicence"
			endif
		endif
		GetProgrammeDataCollection().Add(programmeLicence.data)
		GetProgrammeLicenceCollection().AddAutomatic(programmeLicence)

		'set owner of licence (and sublicences)
		if owner
			'ignore current level (else you can start production and
			'increase reach until production finish)
			addLicence.SetLicencedAudienceReachLevel(1)
			addLicence.SetOwner(owner)
		endif

		'update programme data so it informs cast, releases to cinema etc
		programmeData.Update()

rem
print "produziert: " + programmeLicence.GetTitle() + "  (Preis: "+programmeLicence.GetPrice(1)+")"
if programmeLicence.IsEpisode()
	print "Serie besteht nun aus den Folgen:"
	For local epIndex:int = 0 until addLicence.subLicences.length
		if addLicence.subLicences[epIndex]
			print "- subLicences["+epIndex+"] = " + addLicence.subLicences[epIndex].episodeNumber+" | " + addLicence.subLicences[epIndex].GetTitle()
		else
			print "- subLicences["+epIndex+"] = /"
		endif
	Next
endif
endrem

		'=== 3. INFORM / REMOVE SCRIPT ===
		'inform production company
		productionConcept.productionCompany.FinishProduction(programmeData.GetID())

		'inform script about a done production based on the script
		'(parental script is already informed on creation of its licence)
		productionConcept.script.FinishProduction(programmeLicence.GetID())

		if owner and GetPlayerProgrammeCollection(owner)
			'if the script does not allow further productions, it is finished
			'and should be removed from the player

			'series: remove parent if it is finished now
			if productionConcept.script.HasParentScript()
				local parentScript:TScript = productionConcept.script.GetParentScript()
				if parentScript.IsProduced()
					GetPlayerProgrammeCollection(owner).RemoveScript(parentscript, False)
				endif
			endif
			'single scripts
			GetPlayerProgrammeCollection(owner).RemoveScript(productionConcept.script, False)
		endif

		'=== 4. ADD TO PLAYER ===
		'add licence (or its header-licence)

		if owner and GetPlayerProgrammeCollection(owner)
			GetPlayerProgrammeCollection(owner).AddProgrammeLicence(addLicence, False)
			'done by AddProgrammeLicence already - if successful
			'GetPlayerProgrammeCollection(owner)._programmeLicences = null 'cache
		endif


		'=== 5. REMOVE PRODUCTION CONCEPT ===
		'now only the production itself knows about the concept
		if owner and GetPlayerProgrammeCollection(owner)
			GetPlayerProgrammeCollection(owner).RemoveProductionConcept(productionConcept)
		endif
		GetProductionConceptCollection().Remove(productionConcept)

		'store resulting licence
		producedLicenceGUID = programmeLicence.GetGUID()

		'emit an event so eg. network can recognize the change
		EventManager.triggerEvent(TEventSimple.Create("production.finalize", new TData.Add("programmelicence", programmeLicence), self))

		return self
	End Method


	Method CreateParentalLicence:TProgrammeLicence(programmeLicence:TProgrammeLicence, parentLicenceType:int)

		if productionConcept.script = productionConcept.script.GetParentScript() then Throw "script and parent same : IsEpisode() failed."

		'check if there is already a licence
		'attention: for series this should NOT contain the productionGUID
		'           as this differs for each episode and would lead to a
		'           individual series header for each produced episode
		local parentProgrammeGUID:string = "customProduction-header-"+productionConcept.script.GetParentScript().GetGUID()
		local parentLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(parentProgrammeGUID)


		'create new licence if needed
		if not parentLicence
			parentLicence = new TProgrammeLicence
			parentLicence.SetGUID(parentProgrammeGUID)
			parentLicence.SetData(new TProgrammeData)
			'optional
			parentLicence.GetData().SetGUID("data-"+parentProgrammeGUID)

			'some basic data for the header of series/collections
			parentLicence.GetData().distributionChannel = TVTProgrammeDistributionChannel.TV
			parentLicence.GetData().setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
			parentLicence.GetData().producedByPlayerID = programmeLicence.GetData().producedByPlayerID
			parentLicence.GetData().SetFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION, True)

			'fill with basic data (title, description, ...)
			FillProgrammeDataByScript(parentLicence.GetData(), productionConcept.script.GetParentScript())

			if parentLicenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.data.dataType = TVTProgrammeDataType.SERIES
			elseif parentLicenceType = TVTProgrammeLicenceType.COLLECTION
				parentLicence.licenceType = TVTProgrammeLicenceType.COLLECTION
				parentLicence.data.dataType = TVTProgrammeDataType.COLLECTION
			else
				print "UNKNOWN LICENCE TYPE GIVEN: "+parentLicenceType+". Fail back to series"
				parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.data.dataType = TVTProgrammeDataType.SERIES
			endif
		else
			'we already created the parental licence before

			'configured at all?
			if productionConcept.script.GetParentScript().usedInProgrammeID
				'differs to GUID of parent?
				if productionConcept.script.GetParentScript().usedInProgrammeID <> parentLicence.GetID()
					Throw "CreateParentalLicence() failed: another programme is already assigned to the parent script."
				endif
			endif
		endif

		return parentLicence
	End Method


	'refill data with current information (cast, avg ratings)
	Method FillParentalLicence(parentLicence:TProgrammeLicence)
		'inform parental script about the usage, also increases
		'production count if all episodes are produced (at least +1 than
		'the series production count)
		productionConcept.script.GetParentScript().FinishProduction(parentLicence.GetID())

		local parentData:TProgrammeData = parentLicence.GetData()


		local countries:string[]
		local releaseTime:Long = -1
		For local subLicence:TProgrammeLicence = eachin parentLicence.subLicences
			local c:string = subLicence.GetData().country
			if not StringHelper.InArray(c, countries) then countries :+ [c]

			if releaseTime = -1
				releaseTime = subLicence.GetData().releaseTime
			else
				releaseTime = Min(releaseTime, subLicence.GetData().releaseTime)
			endif
		Next
		if countries.length = 0 then countries :+ ["UNK"]
		parentData.country = " / ".Join(countries)
		parentData.releaseTime = releaseTime

		'=== CAST ===
		'only list "visible" persons: HOST, ACTOR, SUPPORTINGACTOR, GUEST, REPORTER
		local seriesCast:TProgrammePersonBase[]
		local seriesJobs:TProgrammePersonJob[]
		local jobFilter:int = TVTProgrammePersonJob.HOST | ..
		                      TVTProgrammePersonJob.ACTOR | ..
		                      TVTProgrammePersonJob.SUPPORTINGACTOR | ..
		                      TVTProgrammePersonJob.GUEST | ..
		                      TVTProgrammePersonJob.REPORTER
		parentData.ClearCast()
		For local subLicence:TProgrammeLicence = eachin parentLicence.subLicences
			For local job:TProgrammePersonJob = EachIn subLicence.GetData().GetCast()
				'only add visible ones
				if job.job & jobFilter <= 0 then continue
				'add if that person is not listed with the same job yet
				'(ignore multiple roles)
				if not parentData.HasCast(job, False)
					parentData.AddCast(new TProgrammePersonJob.Init(job.personGUID, job.job))
				endif
			Next
		Next

		'=== RATINGS ===
		parentData.review = 0
		parentData.speed = 0
		parentData.outcome = 0
		local subLicenceCount:int = parentLicence.GetSubLicenceCount()
		if subLicenceCount > 0
			For local subLicence:TProgrammeLicence = eachin parentLicence.subLicences
				parentData.review :+ subLicence.GetData().review
				parentData.speed :+ subLicence.GetData().speed
				parentData.outcome :+ subLicence.GetData().outcome
			Next
			parentData.review :/ subLicenceCount
			parentData.speed :/ subLicenceCount
			parentData.outcome :/ subLicenceCount
		endif
	End Method


	Function FillProgrammeDataByScript(programmeData:TProgrammeData, script:TScript)
		programmeData.description = script.description.Copy()
		if script.customTitle
			programmeData.title = new TLocalizedString.Set(script.customTitle)
		else
			programmeData.title = script.title.Copy()
		endif
		if script.customDescription
			programmeData.description = new TLocalizedString.Set(script.customDescription)
		else
			programmeData.description = script.description.Copy()
		endif

		programmeData.blocks = script.GetBlocks()
		programmeData.flags = script.flags
		programmeData.genre = script.mainGenre
		if script.subGenres
			For local sg:int = EachIn script.subGenres
				if sg = 0 then continue
				programmeData.subGenres :+ [sg]
			Next
		endif
	End Function


	Method Update:int()
		Select status
			'already finished
			case 2
				return False
			'aborted / paused
			case 3
				return False
			'not yet started
			case 0
				return False
			'in production
			case 1
				if GetWorldTime().GetTimeGone() > endDate
					Finalize()
					return True
				endif
		End Select

		return False
	End Method
End Type