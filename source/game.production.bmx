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
		If Not _instance Then _instance = New TProductionCollection
		Return _instance
	End Function


	'override to _additionally_ store latest production on a
	'per-room-basis
	Method Add:Int(obj:TGameObject)
		Local p:TProduction = TProduction(obj)
		If p
			Local roomGUID:String = p.studioRoomGUID
			If roomGUID <> ""
				'if the production is newer than a potential previous
				'production, replace the previous with the new one
				Local previousP:TProduction = GetProductionByRoom(roomGUID)
				If previousP And previousP.startDate < p.startDate
					latestProductionByRoom.Insert(roomGUID, p)
				EndIf
			EndIf
		EndIf

		Super.Add(obj)
	End Method


	Method GetProductionByRoom:TProduction(roomGUID:String)
		Local p:TProduction = TProduction(latestProductionByRoom.ValueForKey(roomGUID))
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProductionCollection:TProductionCollection()
	Return TProductionCollection.GetInstance()
End Function




Type TProduction Extends TOwnedGameObject
	Field productionConcept:TProductionConcept
	Field producerName:String
	'use negative numbers for custom producers, and positive
	'for players
	Field producerID:Int
	'in which room was/is this production recorded (might no longer
	'be a studio!)
	Field studioRoomGUID:String
	'0 = waiting, 1 = running, 2 = finished, 3 = aborted/paused
	Field status:Int = 0
	'start of shooting
	Field startDate:Long
	'end of shooting
	Field endDate:Long

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

	Field producedLicenceGUID:String

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


	Method IsInProduction:Int()
		Return status = 1
	End Method


	Method IsProduced:Int()
		Return status = 2
	End Method


	Method SetStudio:Int(studioGUID:String)
		studioRoomGUID = studioGUID
		Return True
	End Method


	'returns a modificator to a script's intrinsic values (speed, review..)
	Method GetProductionValueMod:Float()
		Local value:Float
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


		Return value
	End Method


	Method PayProduction:Int()
		'already paid rest?
		If productionConcept.IsBalancePaid() Then Return True
		'something missing?
		If Not productionConcept.IsProduceable() Then Return False


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


	Method Start:TProduction()
		startDate = GetWorldTime().GetTimeGone()
		endDate = startDate + productionConcept.GetBaseProductionTime()
		TLogger.Log("TProduction.Start", "Starting production ~q"+productionConcept.GetTitle()+"~q. Production: "+ GetWorldTime().GetFormattedDate(startDate) + "  -  " + GetWorldTime().GetFormattedDate(endDate), LOG_DEBUG)

		status = 1

		'calculate costs
		productionConcept.CalculateCosts()
		TLogger.Log("TProduction.Start", "Costs calculated", LOG_DEBUG)


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
		If Not productionConcept.productionCompany
			TLogger.Log("TProduction.Start", "productionConcept.productionCompany NULL !!!!!", LOG_DEBUG)
		EndIf
		productionCompanyQuality = productionConcept.productionCompany.GetQuality()


		'=== 1.2 INDIVIDUAL IMPROVEMENTS ===

		'=== 1.2.1 CAST SYMPATHY ===
		'improve cast job by "sympathy" (they like your channel, so they
		'do a slightly better job)
		castSympathyMod = 1.0 + productionConcept.CalculateCastSympathy(True)

		'=== 1.2.2 MODIFY PRODUCTION VALUE ===
		effectiveFocusPoints = productionConcept.CalculateEffectiveFocusPoints(True)
		effectiveFocusPointsMod = 1.0 + productionConcept.GetEffectiveFocusPointsRatio(True)

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
		If studioRoomGUID And GetRoomBaseByGUID(studioRoomGUID)
			'time in milliseconds
			Local productionTime:Long = (endDate - startDate)
			If productionTime > 0
				'also add 5 minutes to avoid people coming into the studio
				'in the break between two productions
				productionTime :+ 300 * TWorldTime.SECONDLENGTH

				productionTime :* GetProductionTimeMod()

				If productionConcept.script.IsLive()
					GetRoomBaseByGUID(studioRoomGUID).SetBlocked(productionTime, TRoomBase.BLOCKEDSTATE_PREPRODUCTION)
				Else
					GetRoomBaseByGUID(studioRoomGUID).SetBlocked(productionTime, TRoomBase.BLOCKEDSTATE_SHOOTING)
				EndIf
				GetRoomBaseByGUID(studioRoomGUID).blockedText = productionConcept.GetTitle()
			EndIf
		EndIf


		'emit an event so eg. network can recognize the change
		TriggerBaseEvent(GameEventKeys.Production_Start, Null, Self)

		Return Self
	End Method


	Method Abort:TProduction()
		status = 3

		TLogger.Log("TProduction.Abort()", "Aborted shooting.", LOG_DEBUG)

		'emit an event so eg. network can recognize the change
		TriggerBaseEvent(GameEventKeys.Production_Abort, Null, Self)

		Return Self
	End Method


	Method Finalize:TProduction()
		'already finalized before
		If status = 2 Then Return Self

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


		TLogger.Log("TProduction.Finalize()", "ProductionValueMod    : "+GetProductionValueMod(), LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "ProductionValueMod end: "+productionValueMod, LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "ProductionPriceMod    : "+productionPriceMod, LOG_DEBUG)
		TLogger.Log("TProduction.Finalize()", "CastFameMod           : "+castFameMod, LOG_DEBUG)


		'=== 1.2 CAST ===
		'change skills of the actors / director / ...



		'=== 2. PROGRAMME CREATION ===
		Local programmeData:TProgrammeData = New TProgrammeData
		Local programmeGUID:String = "customProduction-"+"-"+productionConcept.script.GetGUID()+"-"+GetGUID()
		programmeData.SetGUID("data-"+programmeGUID)

		If producerName
			If Not programmeData.extra Then programmeData.extra = New TData
			programmeData.extra.AddString("producerName", producerName)
		EndIf

		If producerID <> 0
			If Not programmeData.extra Then programmeData.extra = New TData
			programmeData.extra.AddInt("producerID", producerID)
		EndIf

		'=== 2.1 PROGRAMME BASE PROPERTIES ===
		FillProgrammeData(programmeData, productionConcept)
		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK")
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		programmeData.releaseTime = GetWorldTime().GetTimeGone()
		If productionConcept.script.IsLive()
			'programmeData.releaseTime = productionConcept.script.GetLiveTime(-1, 0)

			programmeData.releaseTime = productionConcept.GetLiveTime()
			'inform script about the latest live time used
			productionConcept.script.lastLiveTime = programmeData.releaseTime
		EndIf
		programmeData.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, False)
		programmeData.producedByPlayerID = owner
		programmeData.dataType = productionConcept.script.scriptLicenceType

		programmeData.SetFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION, True)
		'enable mandatory flags
		programmeData.SetFlag(productionConcept.script.flags, True)
		'randomly enable optional flags
		If productionConcept.script.flagsOptional > 0
			For Local i:Int = 1 Until TVTProgrammeDataFlag.count
				Local optionalFlag:Int = TVTProgrammeDataFlag.GetAtIndex(i)
				If productionConcept.script.flagsOptional & optionalFlag > 0
					'do not enable X-Rated for live productions when
					'live time is not in the night
					If optionalFlag = TVTProgrammeDataFlag.XRATED
						If productionConcept.script.liveTime <= 22 And productionConcept.script.liveTime >= 6
							programmeData.SetFlag(optionalFlag, True)
						EndIf
					Else
						programmeData.SetFlag(optionalFlag, True)
					EndIf
				EndIf
			Next
		EndIf


		programmeData.broadcastTimeSlotStart = productionConcept.script.broadcastTimeSlotStart
		programmeData.broadcastTimeSlotEnd = productionConcept.script.broadcastTimeSlotEnd


		'add flags given in script
		For Local i:Int = 1 To TVTBroadcastMaterialSourceFlag.count
			Local flag:Int = TVTBroadcastMaterialSourceFlag.GetAtIndex(i)
			If productionConcept.script.productionBroadcastFlags & flag
				programmeData.broadcastFlags :| flag
			EndIf
		Next

		'add broadcast limits
		programmeData.SetBroadcastLimit(productionConcept.script.productionBroadcastLimit)

		If productionPriceMod <> 1.0
			programmeData.SetModifier("price", productionPriceMod)
		EndIf


		'=== 2.2 PROGRAMME PRODUCTION PROPERTIES ===
		programmeData.review = MathHelper.Clamp(productionValueMod * productionConcept.script.review *scriptPotentialMod, 0, 1.0)
		programmeData.speed = MathHelper.Clamp(productionValueMod * productionConcept.script.speed *scriptPotentialMod, 0, 1.0)
		programmeData.outcome = MathHelper.Clamp(productionValueMod * productionConcept.script.outcome *scriptPotentialMod, 0, 1.0)
		'modify outcome by castFameMod ("attractors/startpower")
		programmeData.outcome = MathHelper.Clamp(programmeData.outcome * castFameMod, 0, 1.0)

		If producerName
			If Not programmeData.extra Then programmeData.extra = New TData
			programmeData.extra.AddString("producerName", producerName)
		EndIf


		'=== 2.3 PROGRAMME CAST ===
		For Local castIndex:Int = 0 Until Min(productionConcept.cast.length, productionConcept.script.jobs.length)
			Local p:TPersonBase = productionConcept.cast[castIndex]
			Local job:TPersonProductionJob = productionConcept.script.jobs[castIndex]
			If Not p Or Not job Then Continue


			If DEV_InformPerson
				'person is now capable of doing this job
				p.SetJob(job.job)
			EndIf
			programmeData.AddCast(New TPersonProductionJob.Init(p.GetID(), job.job))

			If DEV_InformPerson
				'inform person and adjust its popularity (if it has some)
				Local popularity:TPersonPopularity = TPersonPopularity(p.GetPopularity())
				If popularity
					Local params:TData = New TData
					params.AddNumber("time", GetWorldTime().GetTimeGone())
					params.AddNumber("quality", programmeData.GetQualityRaw())
					params.AddNumber("job", job.job)

					popularity.FinishProgrammeProduction(params)
				EndIf
			EndIf
		Next


		'=== 2.4 PROGRAMME LICENCE ===
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


		'for collections and episodes this is the "header", for single
		'elements this is "self"
		Local parentLicence:TProgrammeLicence = programmeLicence
		If programmeLicence.IsEpisode()
			'set episode according to script-episode-index
			programmeLicence.episodeNumber = productionConcept.script.GetParentScript().GetSubScriptPosition(productionConcept.script) + 1

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
				DebugStop
				Throw "Failed to create parentLicence"
			EndIf
		EndIf
		GetProgrammeDataCollection().Add(programmeLicence.data)
		GetProgrammeLicenceCollection().AddAutomatic(programmeLicence)

		'set owner of licence (and sublicences)
		If owner
			'ignore current level (else you can start production and
			'increase reach until production finish)
			parentLicence.SetLicencedAudienceReachLevel(1)
			parentLicence.SetOwner(owner)
		EndIf

		'update programme data so it informs cast, releases to cinema etc
		programmeData.Update()

Rem
print "produziert: " + programmeLicence.GetTitle() + "  (Preis: "+programmeLicence.GetPrice(1)+")"
if programmeLicence.IsEpisode()
	print "Serie besteht nun aus den Folgen:"
	For local epIndex:int = 0 until parentLicence.subLicences.length
		if parentLicence.subLicences[epIndex]
			print "- subLicences["+epIndex+"] = " + parentLicence.subLicences[epIndex].episodeNumber+" | " + parentLicence.subLicences[epIndex].GetTitle()
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

		If owner And GetPlayerProgrammeCollection(owner)
			'if the script does not allow further productions, it is finished
			'and should be removed from the player

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

		'=== 4. ADD TO PLAYER ===
		'add licence (and its header-licence)

		If owner And GetPlayerProgrammeCollection(owner)
			if parentLicence <> programmeLicence
				'only adds if not already added
				GetPlayerProgrammeCollection(owner).AddProgrammeLicence(parentLicence, False)
			endif
			GetPlayerProgrammeCollection(owner).AddProgrammeLicence(programmeLicence, False)
		EndIf


		'=== 5. REMOVE PRODUCTION CONCEPT ===
		'now only the production itself knows about the concept
		If owner And GetPlayerProgrammeCollection(owner)
			GetPlayerProgrammeCollection(owner).RemoveProductionConcept(productionConcept)
		EndIf
		GetProductionConceptCollection().Remove(productionConcept)

		'store resulting licence
		producedLicenceGUID = programmeLicence.GetGUID()

		'emit an event so eg. network can recognize the change
		TriggerBaseEvent(GameEventKeys.Production_Finalize, New TData.Add("programmelicence", programmeLicence), Self)

		Return Self
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
			parentLicence.GetData().producedByPlayerID = programmeLicence.GetData().producedByPlayerID
			parentLicence.GetData().SetFlag(TVTProgrammeDataFlag.CUSTOMPRODUCTION, True)

			'fill with basic data (title, description, ...)
			FillProgrammeData(parentLicence.GetData(), productionConcept, productionConcept.script.GetParentScript(), True)

			If parentLicenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.data.dataType = TVTProgrammeDataType.SERIES
			ElseIf parentLicenceType = TVTProgrammeLicenceType.COLLECTION
				parentLicence.licenceType = TVTProgrammeLicenceType.COLLECTION
				parentLicence.data.dataType = TVTProgrammeDataType.COLLECTION
			Else
				Print "UNKNOWN LICENCE TYPE GIVEN: "+parentLicenceType+". Fail back to series"
				parentLicence.licenceType = TVTProgrammeLicenceType.SERIES
				parentLicence.data.dataType = TVTProgrammeDataType.SERIES
			EndIf
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

		programmeData.genre = script.mainGenre
		If script.subGenres
			For Local sg:Int = EachIn script.subGenres
				If sg = 0 Then Continue
				programmeData.subGenres :+ [sg]
			Next
		EndIf
	End Function


	Method Update:Int()
		Select status
			'already finished
			Case 2
				Return False
			'aborted / paused
			Case 3
				Return False
			'not yet started
			Case 0
				Return False
			'in production
			Case 1
				If GetWorldTime().GetTimeGone() >= endDate
					Finalize()
					Return True
				EndIf
		End Select

		Return False
	End Method
End Type