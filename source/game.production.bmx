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
	Field castSympathyMod:Float = 1.0
	Field productionValueMod:Float = 1.0
	Field effectiveFocusPointsMod:Float = 1.0
	'FALSE to avoid recursive handling (network)
	Global fireEvents:int = TRUE
	


	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "production-"+id
		self.GUID = GUID
	End Method


	Method SetProductionConcept(concept:TProductionConcept)
		productionConcept = concept

		if productionConcept
			owner = productionConcept.owner
		else
			owner = 0
		endif
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
		'=== BASE ===
		value = 0.4 * scriptGenreFit + 0.6 * castFit


		'=== MODIFIERS ===
		'sympathy of the cast influences result a bit
		value :* (1.0 + 0.1 * (castSympathyMod - 1.0))
		
		'it is important to set the production priority according
		'to the genre
		value :* 1.00 * effectiveFocusPointsMod

		'production company quality decides about result too
		value :* (1.0 + 0.25 * productionCompanyQuality)


		return value
	End Method


	Method PayProduction:int()
		'already paid rest?
		if productionConcept.IsBalancePaid() then return False

		'if invalid owner or finance not existing, skip payment and
		'just set the prodcuction as paid
		if GetPlayerFinance(productionConcept.owner)
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

		'=== 1.1.3 PRODUCTIONCOMPANY ===
		'Calculate how the selected company does its job at all
		productionCompanyQuality = productionConcept.productionCompany.GetQuality() 


		'=== 1.2 INDIVIDUAL IMPROVEMENTS ===

		'=== 1.2.1 CAST SYMPATHY ===
		'improve cast job by "sympathy" (they like your channel, so they
		'do a slightly better job)
		castSympathyMod = 1.0 + productionConcept.CalculateCastSympathy()

		'=== 1.2.2 MODIFY PRODUCTION VALUE ===
		effectiveFocusPointsMod = 1.0 + productionConcept.GetEffectiveFocusPointsRatio()

 
		TLogger.Log("TProduction.Start()", "scriptGenreFit:           " + scriptGenreFit, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "castFit:                  " + castFit, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "castSympathyMod:          " + castSympathyMod, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "effectiveFocusPointsMod:  " + effectiveFocusPointsMod, LOG_DEBUG)
		TLogger.Log("TProduction.Start()", "productionCompanyQuality: " + productionCompanyQuality, LOG_DEBUG)



		'=== 2. PRODUCTION EFFECTS ===
		'modify production time (longer by random chance?)


		'=== 3. BLOCK STUDIO ===
		'set studio blocked
		if GetRoomBaseByGUID(studioRoomGUID)
			'time in seconds
			'also add 5 minutes to avoid people coming into the studio
			'in the break between two productions
			local productionTime:int = (endDate - startDate) + 600
			GetRoomBaseByGUID(studioRoomGUID).SetBlocked(productionTime, TRoomBase.BLOCKEDSTATE_SHOOTING)
			GetRoomBaseByGUID(studioRoomGUID).blockedText = productionConcept.GetTitle()
		endif


		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("production.start", null, self))

		return self
	End Method


	Method Abort:TProduction()
		status = 3

		TLogger.Log("TProduction.Abort()", "Aborted shooting.", LOG_DEBUG)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("production.abort", null, self))

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
		local productionValueMod:Float = GetProductionValueMod()
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
		local productionPriceMod:Float = 1.0
		luck = RandRange(0,100)
		if luck < 5
			productionPriceMod :+ RandRange(5,20)/100.0
		elseif luck > 95
			productionPriceMod :- RandRange(5,20)/100.0
		endif

		'custom productions are sellable right after production, and
		'really "young" productions are too expensive, which is why
		'we lower the price at all


		'star power bonus
		'this is calculated at the end, as this is some kind of
		'"advertising bonus" for the outcome-portion
		local castFameMod:Float = productionConcept.CalculateCastFameMod()


		TLogger.Log("TProduction.Finalize()", "ProductionValueMod    : "+GetProductionValueMod(), LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "ProductionValueMod end: "+productionValueMod, LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "ProductionPriceMod    : "+ProductionPriceMod, LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "CastFameMod           : "+castFameMod, LOG_DEBUG)


		'=== 1.2 CAST ===
		'change skills of the actors / director / ...



		'=== 2. PROGRAMME CREATION ===
		Local programmeGUID:string = "customProduction-"+productionConcept.script.GetGUID()
		local programmeData:TProgrammeData = new TProgrammeData
		programmeData.SetGUID("data-"+programmeGUID)

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
		programmeData.review = productionValueMod * productionConcept.script.review
		programmeData.speed = productionValueMod * productionConcept.script.speed
		programmeData.outcome = productionValueMod * productionConcept.script.outcome
		'modify outcome by castFameMod ("attractors/startpower")
		programmeData.outcome = Min(1.0, programmeData.outcome * castFameMod)


		'=== 2.3 PROGRAMME CAST ===
		For local castIndex:int = 0 until Min(productionConcept.cast.length, productionConcept.script.cast.length)
			local p:TProgrammePersonBase = productionConcept.cast[castIndex]
			local job:TProgrammePersonJob = productionConcept.script.cast[castIndex]
			if not p or not job then continue

			'person is now capable of doing this job
			p.SetJob(job.job)
			programmeData.AddCast(new TProgrammePersonJob.Init(p.GetGUID(), job.job))

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

			local parentLicence:TProgrammeLicence = CreateParentalLicence(programmeLicence)
			'add the episode
			if parentLicence
				'add licence at the position of the defined episode no.
				parentLicence.AddSubLicence(programmeLicence, programmeLicence.episodeNumber - 1)
				addLicence = parentLicence

				'fill that licence with episode specific data
				'(averages, cast)
				FillParentalLicence(parentLicence)

				GetProgrammeDataCollection().Add(parentLicence.data)
				GetProgrammeLicenceCollection().AddAutomatic(parentLicence)
			endif
		endif
		GetProgrammeDataCollection().Add(programmeLicence.data)
		GetProgrammeLicenceCollection().AddAutomatic(programmeLicence)

		'set owner of licence (and sublicences)
		if owner
			addLicence.SetOwner(owner)
		endif

rem
print "produziert: " + programmeLicence.GetTitle() + "  (Preis: "+programmeLicence.GetPrice()+")"
if programmeLicence.IsEpisode()
	print "Serie besteht nun aus den Folgen:"
	For local epIndex:int = 0 until addLicence.GetSubLicenceCount()
		print "subLicences["+epIndex+"] = " + addLicence.subLicences[epIndex].episodeNumber+" | " + addLicence.subLicences[epIndex].GetTitle()
	Next
endif
endrem
	
		'=== 3. INFORM / REMOVE SCRIPT ===
		'inform production company
		productionConcept.productionCompany.FinishProduction(programmeData.GetGUID())
		
		'inform script about a done production based on the script
		'(parental script is already informed on creation of its licence)
		productionConcept.script.FinishProduction(programmeLicence.GetGUID())

		if owner
			'if the script does not allow further productions, it is finished
			'and should be removed from the player
			if productionConcept.script.GetParentScript().IsProduced()
				GetPlayerProgrammeCollection(owner).RemoveScript(productionConcept.script.GetParentScript(), False)
			else
				'remove finished concepts
			endif
		endif
		
		'=== 4. ADD TO PLAYER ===
		'add licence (or its header-licence)

		if owner and GetPlayerProgrammeCollection(owner)
			GetPlayerProgrammeCollection(owner).AddProgrammeLicence(addLicence, False)
			GetPlayerProgrammeCollection(owner)._programmeLicences = null 'cache
		endif


		'=== 5. REMOVE PRODUCTION CONCEPT ===
		'now only the production itself knows about the concept
		if owner and GetPlayerProgrammeCollection(owner)
			GetPlayerProgrammeCollection(owner).RemoveProductionConcept(productionConcept)
		endif
		GetProductionConceptCollection().Remove(productionConcept)


		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("production.finalize", null, self))

		return self
	End Method


	Method CreateParentalLicence:TProgrammeLicence(programmeLicence:TProgrammeLicence)
		if not programmeLicence.IsEpisode() then return Null
		'TODO: collections

		if productionConcept.script = productionConcept.script.GetParentScript() then Throw "script and parent same : IsEpisode() failed."

		'check if there is a licence already
		local parentProgrammeGUID:string = "customProduction-header-"+productionConcept.script.GetParentScript().GetGUID() 
		local parentLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(parentProgrammeGUID)


		'create new licence if needed
		if not parentLicence
			parentLicence = new TProgrammeLicence
			parentLicence.SetGUID(parentProgrammeGUID)
			parentLicence.SetData(new TProgrammeData)
			'optional
			parentLicence.GetData().SetGUID("data-"+parentProgrammeGUID)
			'fill with basic data (title, description, ...)
			FillProgrammeDataByScript(parentLicence.GetData(), productionConcept.script.GetParentScript())

			parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
			parentLicence.data.dataType = TVTProgrammeDataType.SERIES
		else
			'configured at all?
			if productionConcept.script.GetParentScript().usedInProgrammeGUID
				'differs to GUID of parent?
				if productionConcept.script.GetParentScript().usedInProgrammeGUID <> parentLicence.GetGUID()
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
		productionConcept.script.GetParentScript().FinishProduction(parentLicence.GetGUID())

		local parentData:TProgrammeData = parentLicence.GetData()

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
		if parentLicence.GetSubLicenceCount() > 0
			For local subLicence:TProgrammeLicence = eachin parentLicence.subLicences
				parentData.review :+ subLicence.GetData().review
				parentData.speed :+ subLicence.GetData().speed
				parentData.outcome :+ subLicence.GetData().outcome
			Next
			parentData.review :/ parentLicence.GetSubLicenceCount()
			parentData.speed :/ parentLicence.GetSubLicenceCount()
			parentData.outcome :/ parentLicence.GetSubLicenceCount()
		endif
	End Method


	Function FillProgrammeDataByScript(programmeData:TProgrammeData, script:TScript)
		'TODO: custom title/description
		programmeData.title = script.title.Copy()
		programmeData.description = script.description.Copy()
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