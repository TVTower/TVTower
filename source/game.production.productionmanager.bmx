SuperStrict
Import "game.production.productionconcept.bmx"
Import "game.production.productioncompany.bmx"
Import "game.production.bmx"
Import "game.room.bmx"


Type TProductionManager
	'contains all production concepts with state "production ready"
	'once one starts productions in a studio
	Field productionsToProduce:TList = CreateList()
	Field liveProductions:TList = CreateList()
	
	'all amateurs currently available in castings
	Field currentAvailableAmateurs:TPersonBase[]

	Global _instance:TProductionManager
	Global _eventListeners:TEventListenerBase[]
	Global createdEnvironment:int = False


	Function GetInstance:TProductionManager()
		if not _instance then _instance = new TProductionManager
		return _instance
	End Function


	Method Initialize()
		productionsToProduce.Clear()
		liveProductions.Clear()

		'create on initialization rather than in "new()" as new is only
		'called once per "application run" (compared to "every game")
		CreateProductionCompanies()
	End Method


	Method New()
		if not createdEnvironment

			'=== REGISTER EVENTS ===
			EventManager.UnregisterListenersArray(_eventListeners)
			_eventListeners = new TEventListenerBase[0]
			'resize news genres when loading an older savegame
			_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onSavegameLoad) ]
			'update manager at certain times:
			'xx:05 - BEFORE broadcasts are logged in (and used in audience calculations)
			'_eventListeners :+ [ EventManager.registerListenerFunction( GameEventKeys.Broadcasting_BeforeStartAllProgrammeBlockBroadcasts, onStartProgrammeBlockBroadcasts) ]
			'xx:54 - AFTER broadcasts have run
			'_eventListeners :+ [ EventManager.registerListenerFunction( Broadcasting_AfterFinishAllProgrammeBlockBroadcasts, onFinishProgrammeBlockBroadcasts) ]
			'xx:yy - to check if there has to be an special event during
			'        running productions
			_eventListeners :+ [ EventManager.registerListenerFunction( GameEventKeys.Game_onMinute, onGameMinute) ]
			
			'no need to react to bankruptcy / changed players 
			'(to abort running productions)
			'as this should be done by the player TGame.ResetPlayer() 
			'_eventListeners :+ [ EventManager.registerListenerFunction( GameEventKeys.Game_SetPlayerBankruptBegin, onSetPlayerBankruptBegin) ]

			createdEnvironment = true
		endif
	End Method


	Function onSavegameLoad:int(triggerEvent:TEventBase)
		if GetProductionCompanyBaseCollection().GetCount() = 0
			CreateProductionCompanies()
		endif

		'repair old savegames (<= v0.7)
		local savedSaveGameVersion:Int = triggerEvent.GetData().GetInt("saved_savegame_version")
		local currentSaveGameVersion:Int = triggerEvent.GetData().GetInt("current_savegame_version")
		if savedSaveGameVersion = 13
			'all production steps need to be fixed
			For Local p:TProduction = EachIn GetInstance().productionsToProduce
				Select p.productionStep
					'case 0
					'	'the same TVTProductionStep.NOT_STARTED
					case 1
						p.productionStep = TVTProductionStep.SHOOTING
						if not p._designatedProgrammeLicence
							p._designatedProgrammeLicence = p.GetProducedLicence()
							if p._designatedProgrammeLicence
								TLogger.Log("Savegae", "TProductionManager.onSavegameLoad reassigned _designatedProgrammeLicence for ~q"+p.productionConcept.GetTitle()+"~q.", LOG_DEBUG)
							endif
						endif
						if not p._designatedProgrammeLicence
							p._designatedProgrammeLicence = p.GenerateProgrammeLicence()
							p.producedLicenceID = p._designatedProgrammeLicence.GetID()
							TLogger.Log("Savegae", "TProductionManager.onSavegameLoad recreated _designatedProgrammeLicence for ~q"+p.productionConcept.GetTitle()+"~q.", LOG_DEBUG)
						endif
					case 2
						p.productionStep = TVTProductionStep.FINISHED
					case 3
						p.productionStep = TVTProductionStep.ABORTED
				End Select
			Next
		endif
	End Function


	Function onGameMinute:Int(triggerEvent:TEventBase)
		'TODO: (selten und) zufaellig laufende Produktionen unterbrechen ?

		'update every 4 hours at x:10
		Local time:Long = triggerEvent.GetData().GetLong("time")
		If GetWorldTime().GetDayMinute(time) = 10 and GetWorldTime().GetDayHour(time) mod 4 = 0
			GetInstance().UpdateCurrentlyAvailableAmateurs()
		EndIf
	End Function


	Function CreateProductionCompanies:int()
		'remove old ones
		GetProductionCompanyBaseCollection().Initialize()

		'create a basic companie existing "forever on level 1"
		local c:TProductionCompany = new TProductionCompany
		c.name = GetLocale("JOB_AMATEURS")
		c.SetExperience( 0 )
		c.SetMaxExperience( 0 )
		c.SetMaxLevel( 1 )
		GetProductionCompanyBaseCollection().Add(c)


		'create some companies
		local cnames:string[] = ["Digidea", "Berlin Film", "Movie World", "Los Krawallos", "Motion Gems", "Screen Jewel"]
		local levelXP:int = TProductionCompanyBase.MAX_XP / TProductionCompanyBase.MAX_LEVEL
		local cxp:int[] = [0, 0, 0, 1*levelXP, 1*levelXP, 2*levelXP, 3*levelXP]
		'shuffle XP's so they shuffle levels each start
		Local shuffleIndex:Int
		Local shuffleTmp:Int
		For Local i:Int = cxp.length-1 To 0 Step -1
			shuffleIndex = RandRange(0, cxp.length-1)
			shuffleTmp = cxp[i]
			cxp[i] = cxp[shuffleIndex]
			cxp[shuffleIndex] = shuffleTmp
		Next

		For local i:int = 0 until cnames.length
			local c:TProductionCompany = new TProductionCompany
			c.name = cnames[i]
			'c.SetExperience( BiasedRandRange(0, int(0.35 * TProductionCompanyBase.MAX_XP), 0.25) )
			c.SetExperience( cxp[i] + BiasedRandRange(0, int(0.5 * levelXP), 0.25) )
			GetProductionCompanyBaseCollection().Add(c)
		Next
	End Function


	Method Update:int()
		UpdateLiveProductions()
		UpdateProductions()
	End Method


	Method PayProductionConceptDeposit:int(productionConcept:TProductionConcept)
		if not productionConcept then return False

		return productionConcept.PayDeposit()
	End Method


	Method PayProduction:int(productionConcept:TProductionConcept)
		if not productionConcept then return False

		return productionConcept.PayBalance()
	End Method


	'returns first found production in the given room/studio
	Method GetProductionInStudio:TProduction(roomID:Int)
		For local production:TProduction = EachIn productionsToProduce
			if production.studioRoomID <> roomID then continue

			return production
		Next
		return null
	End Method


	Method AbortProduction:int(production:TProduction)
		liveProductions.Remove(production)

		if production.Abort()
			return productionsToProduce.Remove(production)
		endif
	End Method


	Method StartLiveProductionInStudio:Int(productionID:Int)
		'any live production can only happen if the studio it is to
		'be shot in - is available (rented). Other productions in there
		'will be "paused" for the time of the shooting

		Local production:TProduction = GetLiveProduction(productionID)
		If not production then Return False
		If not production.productionConcept.script.IsLive() Then Return False

		'ensure shooting takes place in owned studio
		If production.studioRoomID > 0
			Local room:TRoom = GetRoomCollection().Get(production.studioRoomID)
			If Not room Or room.owner <> production.owner Or room.GetName() <> "studio"
				production.studioRoomID = 0
			EndIf
		EndIf
		'TODO ensure studio matches requirements (size); if no appropriate studio exists then abort production (toast message)
		'if information is missing (eg old savegame), or the original studio is not owned anymore
		'assign first  possible studio
		If production.studioRoomID = 0 And production.owner > 0
			Local firstStudio:TRoomBase = GetRoomCollection().GetFirstByDetails("", "studio", production.owner)
			If firstStudio
				production.studioRoomID = firstStudio.GetID()
			EndIf
		EndIf

		Local otherProduction:TProduction = GetProductionInStudio(production.studioRoomID)
		If otherProduction and otherProduction <> production
			'no need to calculate "real" time here - add some minutes
			'local t:Long = production.productionConcept.script.GetBlocks() * TWorldTime.HOURLENGTH)
			'or exacly continue our broadcast finishes?
			Local t:Long = (production.productionConcept.script.GetBlocks()-1) * TWorldTime.HOURLENGTH + 50 * TWorldTime.MINUTELENGTH
			TLogger.Log("TProductionManager.StartLiveProductionInStudio()", "Pausing current production ~q"+otherProduction.productionConcept.GetTitle()+"~q for live shooting of ~q" + production.productionConcept.GetTitle() +"~q.", LOG_DEBUG)
			otherProduction.SetPaused(True, t)
		EndIf

		'start live shooting
		production.BeginShooting()
	End Method


	'start the production in the given studio
	'returns amount of productions in that studio
	Method StartProductionInStudio:int(roomID:Int, script:TScript)
		if not roomID then return False

'print "StartProductionInStudio " + script.Gettitle()

		'- abort productions (stop shooting in this room)
		'- cleanup (remove potentially existing previous productions
		'  of that script)
		'- fetch all concepts in that studio
		'- create productions of all concepts "ready to produce"
		'- start shooting of first production

		'abort current production
		For local production:TProduction = EachIn productionsToProduce
			if production.studioRoomID <> roomID then continue

			if production.IsInProduction()
				production.Abort()
				print "aborted shooting of "+production.productionConcept.GetTitle()
			endif
		Next


		'update list of to produce productions in that studio
		Local productionCount:Int = RefreshProductionsToProduceInStudio(roomID, script)

		'actually start the production
		'- first hit production (with that script) is the one we should
		'  start
		'- other productions are produced once the first one is finished
		For local production:TProduction = EachIn productionsToProduce
			'skip productions of other studios
			if production.studioRoomID <> roomID then continue

			'series? skip if not an episode of this serie
			if production.productionConcept.script.GetParentScript().IsSeries()
				if productionCount > 1 and production.productionConcept.script.parentScriptID <> script.GetID() then continue
			else
				if production.productionConcept.script <> script then continue
			endif

			production.Start()

			'start the FIRST production only!
			return productionCount
		Next

		return productionCount
	End Method


	Method GetProductionsToProduceInStudioCount:Int(roomID:Int)
		Local productionCount:int = 0
		For local production:TProduction = EachIn productionsToProduce
			'skip productions of other studios
			if production.studioRoomID <> roomID then continue

			productionCount :+ 1
		Next

		Return productionCount
	End Method


	rem
	Method GetQueuedProductionByProductionConceptID:TProduction(productionConceptID:int)
		For local production:TProduction = EachIn productionsToProduce
			if production.productionConcept.GetID() = productionConceptID Then return production
		Next
		Return Null
	End Method


	Method GetLiveProductionByProductionConceptID:TProduction(productionConceptID:int)
		For local production:TProduction = EachIn liveProductions
			if production.productionConcept.GetID() = productionConceptID Then return production
		Next
		Return Null
	End Method
	
	
	Method GetManagedProductionByProductionConceptID:TProduction(productionConceptID:int)
		For local production:TProduction = EachIn productionsToProduce
			if production.productionConcept.GetID() = productionConceptID Then return production
		Next
		For local production:TProduction = EachIn liveProductions
			if production.productionConcept.GetID() = productionConceptID Then return production
		Next
		Return Null
	End Method
	endrem
	
	
	Method GetLiveProductionByProgrammeLicenceID:TProduction(programmeLicenceID:Int)
		For Local production:TProduction = EachIn liveProductions
			If Not production._designatedProgrammeLicence Then Continue
			If production.producedLicenceID = programmeLicenceID Then Return production
		Next
		Return Null
	End Method


	Method GetLiveProduction:TProduction(productionID:Int)
		For Local production:TProduction = EachIn liveProductions
			If production.GetID() = productionID Then Return production
		Next
		Return Null
	End Method


	Method RefreshProductionsToProduceInStudio:Int(roomID:Int, script:TScript)
		'amount of productions in this studio
		Local productionCount:int = 0


		'cleanup (remove productions of this script - add them again later)
		local removeProductions:TProduction[]
		For local production:TProduction = EachIn productionsToProduce
			if production.productionConcept.script <> script then continue

			removeProductions :+ [production]
		Next
		For local production:TProduction = EachIn removeProductions
			productionsToProduce.Remove(production)
		Next


		local productionConcepts:TProductionConcept[]
		if script.IsSeries()
			productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScripts(script.subScripts)
		else
			productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScript(script)
		endif


		For local productionConcept:TProductionConcept = EachIn productionConcepts
			'skip already started concepts
			if productionConcept.IsProductionStarted() then continue
			'skip not-produceable concepts
			if not productionConcept.IsProduceable() then continue

			local production:TProduction = new TProduction
			production.SetProductionConcept(productionConcept)
			production.SetStudio(roomID)

			productionsToProduce.AddLast(production)
			productionCount :+ 1
		Next


		'sort productions by "slots"
		if productionCount > 0
			SortList(productionsToProduce, True, SortProductionsByStudioSlot)
		endif

		return productionCount
	End Method


	Function SortProductionsByStudioSlot:int(o1:object, o2:object)
		local p1:TProduction = TProduction(o1)
		local p2:TProduction = TProduction(o2)
		if not p2 or not p2.productionConcept or not p2.productionConcept.script then return -1
		if not p1 or not p1.productionConcept or not p1.productionConcept.script then return 1

		'slots are equal
		if p1.productionConcept.studioSlot = -1 and p2.productionConcept.studioSlot = -1
			'sort by their position in the parent script / episode number
			return p1.productionConcept.script.GetEpisodeNumber() - p2.productionConcept.script.GetEpisodeNumber()
		else
			return p1.productionConcept.studioSlot - p2.productionConcept.studioSlot
		endif
	End Function


	'returns amateurs interested in the given job
	'- uses "currentAvailableAmateurs" not from "all amateurs"
	'- persons are returned "in order" (top to bottom)
	'- no randomness is used
	'- call UpdateCurrentlyAvailableAmateurs() to randomize
	Method GetCurrentAvailableAmateurs:TPersonBase[](filterToJobID:Int, filterToGenderID:Int, minAge:Int, amateursToInclude:Int, minAmountUninterestedAmateurs:Int = 0)
		'load up to X persons with interest in the given job
		'additionally load X persons without interest in the given job
		Local amateursInterested:TPersonBase[] = new TPersonBase[amateursToInclude]
		Local amateursUninterested:TPersonBase[] = new TPersonBase[amateursToInclude]
		Local amateursInterestedAdded:Int = 0
		Local amateursUninterestedAdded:Int = 0
		Local result:TPersonBase[] = new TPersonBase[amateursToInclude]

		For Local i:int = 0 Until currentAvailableAmateurs.length
			if filterToGenderID > 0 and currentAvailableAmateurs[i].gender <> filterToGenderID then continue
			'amateurs do not have any "age" yet
			'if minAge > 0 and currentAvailableAmateurs[i].GetAge() < minAge then continue

			If currentAvailableAmateurs[i].HasPreferredJob(filterToJobID)
				if amateursInterestedAdded < amateursToInclude
					amateursInterested[amateursInterestedAdded] = currentAvailableAmateurs[i]
					amateursInterestedAdded :+ 1
				endif
			Else
				if amateursUninterestedAdded < amateursToInclude
					amateursUninterested[amateursUninterestedAdded] = currentAvailableAmateurs[i]
					amateursUninterestedAdded :+ 1
				endif
			EndIf
			if amateursUninterestedAdded > amateursToInclude and amateursInterestedAdded > amateursToInclude
				exit
			endif
		Next
		

		'iterate through interested until "toInclude - minimumUninterested"
		'is reached (or not enough interested are existing
		local addInterestedCount:Int = Min(amateursInterestedAdded, amateursToInclude - minAmountUninterestedAmateurs)
		Local added:Int
		For local i:int = 0 until addInterestedCount
			'print "adding: interested " + amateursInterested[i].GetFullName() + "  " + bin(amateursInterested[i]._preferredJobs) + "   has="+amateursInterested[i].HasPreferredJob(filterToJobID)
			result[added] = amateursInterested[i]
			added :+ 1
		Next

		'add uninterested (as much as needed to fill "amateursToinclude")
		Local addUninterestedCount:Int = Min(amateursUninterestedAdded, amateursToInclude - addInterestedCount)
		For local i:int = 0 until addUninterestedCount
			'print "adding: uninterested " + amateursUninterested[i].GetFullName() + "  " + bin(amateursUninterested[i]._preferredJobs) + "   has="+amateursUninterested[i].HasPreferredJob(filterToJobID)
			result[added] = amateursUninterested[i]
			added :+ 1
		Next
		
		Return result
	End Method


	Method GetCastAmateurCandidates:TPersonBase[](filterToJobID:Int, filterToGenderID:Int, minAge:Int, amateursToInclude:Int)
		Local persons:TPersonBase[] = new TPersonBase[amateursToInclude]
		Local personsAdded:Int = 0


		Local amountWithoutJob:Int = (amateursToInclude * 3) / 10
		if amateursToInclude > 1 then amountWithoutJob :+ 1

		local amateursWithJob:TPersonBase[] = GetPersonBaseCollection().GetRandomInsignificants(currentAvailableAmateurs, amateursToInclude - amountWithoutJob, True, True, filtertoJobID, filterToGenderID, True, "", null)
		local amateursWithJobIDs:Int[] = new Int[amateursWithJob.length]
		For local i:int = 0 until amateursWithJob.length
			amateursWithJobIDs[i] = amateursWithJob[i].id
		Next
		'no job restrictions but other persons than the ones with job
		local amateursWithoutJob:TPersonBase[] = GetPersonBaseCollection().GetRandomInsignificants(currentAvailableAmateurs, amountWithoutJob, True, True, 0, filterToGenderID, True, "", null, amateursWithJobIDs)


		For local i:int = 0 until amateursWithJob.length + amateursWithoutJob.length
			Local amateur:TPersonBase
			if i < amateursWithJob.length
				amateur = amateursWithJob[i]
			else
				amateur = amateursWithoutJob[i - amateursWithJob.length]
			endif
			
			If amateur
				'custom production not possible with real persons...
				'also the person must be bookable for productions (maybe retired?)
				If Not amateur.IsAlive() Then continue
				If Not amateur.IsFictional() Then continue
				if Not amateur.IsBookable() Then continue

				if not amateur.HasJob(filterToJobID) and amateur.GetJobCount() >= 4 then continue 

				amateur.SetJob(filterToJobID, True)

				persons[personsAdded] = amateur
				personsAdded :+ 1
			EndIf
		Next

		Return persons
	End Method
	

	Method GetCastCelebrityCandidates:TPersonBase[](filterToJobID:Int, filterToGenderID:Int, minAge:Int)
		Local persons:TPersonBase[10]
		Local personsAdded:Int = 0
		
		Local personsList:TObjectList = GetPersonBaseCollection().GetCastableCelebritiesList()
		For Local person:TPersonBase = EachIn personsList
			'custom production not possible with real persons...
			If Not person.IsFictional() Then Continue
			'also the person must be bookable for productions (maybe retired?)
			If Not person.IsBookable() Then Continue
			If Not person.IsAlive() Then Continue


			If filterToGenderID > 0 And person.gender <> filterToGenderID Then Continue

			'we also want to avoid "children" (only available for celebs)
			If minAge >= 0 and person.GetAge() < minAge And person.GetAge() <> -1 Then Continue

			If filterToJobID = 0 Or person.HasJob(filterToJobID)
				if personsAdded = persons.length then persons = persons[.. persons.length + 10]

				persons[personsAdded] = person
				personsAdded :+ 1
			EndIf
		Next
		
		if persons.length = personsAdded
			Return persons
		Else
			Return persons[.. personsAdded]
		EndIf
	End Method
	

	Method GetCastCandidates:TPersonBase[](filterToJobID:Int, filterToGenderID:Int, minAge:Int, amateursToInclude:Int = 0, minAmountUninterestedAmateurs:Int = 0, prependAmateurs:Int = True)
		Local persons:TPersonBase[]

		'fill in available celebs
		persons = GetCastCelebrityCandidates(filterToJobID, filterToGenderID, minAge)

		'add amateurs/laymen at the top/bottom 
		if amateursToInclude > 0
			Local amateurs:TPersonBase[] = GetCurrentAvailableAmateurs(filterToJobID, filterToGenderID, minAge, amateursToInclude, minAmountUninterestedAmateurs)
			if prependAmateurs
				persons = amateurs + persons
			else
				persons = persons + amateurs
			endif
		endif

		Return persons
	End Method
	

	Method UpdateLiveProductions:Int()
		local removeProductions:TProduction[]

		'check if one of the productions is in live production now
		For local production:TProduction = EachIn liveProductions
			production.Update()
			if production.IsProduced() or production.IsAborted()
				removeProductions :+ [production]
			endif
		Next
		'remove all productions which finished
		For local production:TProduction = EachIn removeProductions
			liveProductions.Remove(production)
		Next
	End Method
	
	
	
	'ensure that for each job + gender enough insignificants/amateurs
	'are available ("interested" in the jobs)
	Method UpdateCurrentlyAvailableAmateurs()
		'- fetch all amateurs
		'- count existing per preferred job/gender (and repair if needed
		'- ensure minimum of X per job/gender exist (create if needed)
		'- shuffle the array so any "fetch from top to down" results
		'  in a varying result (but the same until the next "shuffle")

		Local desiredAmountPerJobGender:int = 5
		

		'1.) fetch all amateurs
		'    all fictional, bookable, no job restriction, no gender restriction, alive, no country restriction
		currentAvailableAmateurs = GetPersonBaseCollection().GetFilteredInsignificantsArray(True, True, 0, -1, True, "", null, null)
		'remove celebs? -> should not be needed


		'2.) count existing and repair missing preferences
		'done a bit more "complicated" to allow a more dynamic amount of
		'genders, not just undefined/male/female 
		Local preferredJobCount:Int[] = new Int[ TVTPersonJob.CAST_IDs.length * (TVTPersonGender.count + 1)]
		For Local p:TPersonBase = EachIn currentAvailableAmateurs
			local jobIndex:Int = 0

			'repair missing preferences - and add 1 up to 3 of them
			if p._preferredJobs = 0 
				p.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)
				Local chance:Int = RandRange(0, 100)
				If chance < 10 Then p.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)
				If chance < 20 Then	p.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)
			endif
			
			
			For Local jobID:int = EachIn TVTPersonJob.CAST_IDs
				if p.HasPreferredJob(jobID)
					'all genders for the "generic" count
					preferredJobCount[jobIndex] :+ 1
					'also store count for each gender
					if p.gender >= 1 and p.gender <= TVTPersonGender.count
						preferredJobCount[jobIndex + p.gender*TVTPersonJob.CAST_IDs.length] :+ 1
					endif
				endif
				jobIndex :+ 1
			Next
		Next
		'debug output
		rem
		print "amateurs: " + currentAvailableAmateurs.length
		print "cast jobs: " + TVTPersonJob.CAST_IDs.length
		print "preferredJobCount.length = " + preferredJobCount.length
		For local jobIndex:int = 0 to TVTPersonJob.CAST_IDs.length - 1
			local jobID:int = TVTPersonJob.CAST_IDs[jobIndex]
			Local countDetails:String
			For local genderIndex:Int = 1 to TVTPersonGender.count
				if countDetails then countDetails :+ ", "
				countDetails :+ TVTPersonGender.GetAsString( genderIndex ) + "=" + preferredJobCount[jobIndex + genderIndex*TVTPersonJob.CAST_IDs.length]
			Next
			print "job="+TVTPersonJob.GetAsString(jobID) + "  count=" + preferredJobCount[jobIndex] + " (" + countDetails + ")"
		Next
		endrem


		'3.) fill up missing / ensure enough persons prefer a job
		Local countryCode:String = GetStationMapCollection().config.GetString("nameShort", "Unk")
		Local newAmateurs:TPersonBase[10]
		Local newAmateursIndex:Int = 0
		If not GetPersonGenerator().HasProvider(countryCode)
			countryCode = GetPersonGenerator().GetRandomCountryCode()
		EndIf
		rem
		For Local jobIndex:int = 0 until TVTPersonJob.CAST_IDs.length
			If preferredJobCount[jobIndex] < desiredAmountPerJobGender
				For local addCount:int = 0 until (desiredAmountPerJobGender - preferredJobCount[jobIndex])
					local useCountryCode:String = countryCode
					'try to use "map specific names"
					If RandRange(0,100) < 20
						useCountryCode = GetPersonGenerator().GetRandomCountryCode()
					EndIf

					local amateur:TPersonBase = GetPersonBaseCollection().CreateRandom(countryCode, -1)
					Local jobID:int = TVTPersonJob.CAST_IDs[jobIndex]
					amateur.SetPreferredJob(jobID, True)
					'enable 1-2 other (or the same again) randomly
					Local chance:Int = RandRange(0, 100)
					If chance < 10 Then amateur.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)
					If chance < 20 Then	amateur.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)
					
					if newAmateursIndex >= newAmateurs.length then newAmateurs = newAmateurs[.. newAmateursIndex + 10]
					newAmateurs[newAmateursIndex] = amateur
					newAmateursIndex :+ 1

					'also increase count for the gender specific count now
					preferredJobCount[jobIndex + amateur.gender * (TVTPersonJob.CAST_IDs.length)] :+ 1
				Next
			EndIf
		Next
		endrem
		
		For Local genderIndex:Int = 1 to TVTPersonGender.count
			For Local jobIndex:int = 0 until TVTPersonJob.CAST_IDs.length
				local index:int = jobIndex + genderIndex * TVTPersonJob.CAST_IDs.length
				If preferredJobCount[index] < desiredAmountPerJobGender
					For local addCount:int = 0 until (desiredAmountPerJobGender - preferredJobCount[index])
						local useCountryCode:String = countryCode
						'try to use "map specific names"
						If RandRange(0,100) < 20
							useCountryCode = GetPersonGenerator().GetRandomCountryCode()
						EndIf

						local amateur:TPersonBase = GetPersonBaseCollection().CreateRandom(useCountryCode, TVTPersonGender.GetAtIndex(genderIndex))
						Local jobID:int = TVTPersonJob.CAST_IDs[jobIndex]
						amateur.SetPreferredJob(jobID, True)
						'enable 1-2 other (or the same again) randomly
						Local chance:Int = RandRange(0, 100)
						If chance < 10 Then amateur.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)
						If chance < 20 Then	amateur.SetPreferredJob(TVTPersonJob.CAST_IDs[RandRange(0, TVTPersonJob.CAST_IDs.length-1)], True)

						if newAmateursIndex >= newAmateurs.length then newAmateurs = newAmateurs[.. newAmateursIndex + 10]
						newAmateurs[newAmateursIndex] = amateur
						newAmateursIndex :+ 1
					Next
				EndIf
			Next
		Next
		'add new amateurs to the existing ones
		'no "+ 1" as newAmateursIndex is "nextAmateursIndex" already 
		'currentAvailableAmateurs :+ newAmateurs[.. newAmateursIndex + 1]
		currentAvailableAmateurs :+ newAmateurs[.. newAmateursIndex]

		For Local i:int = 0 Until currentAvailableAmateurs.length
			if not currentAvailableAmateurs[i] then throw "empty " + i
		Next


		'4.) Shuffle entries to allow a bit variation in top-down
		'    retrievals (iterating through array)
		For Local a:int = 0 To currentAvailableAmateurs.length - 2
			Local b:int = RandRange( a, currentAvailableAmateurs.length - 1)
			Local p:TPersonBase = currentAvailableAmateurs[a]
			currentAvailableAmateurs[a] = currentAvailableAmateurs[b]
			currentAvailableAmateurs[b] = p
		Next
	End Method		

	
	Method UpdateProductions:int()
		local finishedProductions:TProduction[]

		'check if one of the (pre)productions is finished now
		For local production:TProduction = EachIn productionsToProduce
			production.Update()
			
			If production.IsProduced()
				finishedProductions :+ [production]

			'normally preproductions are only for live, but that might
			'change so better check for it too
			ElseIf production.IsPreProductionDone() and production.productionConcept.script.IsLive()
				finishedProductions :+ [production]

				If Not liveProductions.Contains(production)
					liveProductions.AddLast(production)
				EndIf
			EndIf
		Next


		'remove finished ones and start follow ups of the used studio
		'(extra step to avoid concurrent list modification)
		local startedProductions:int = 0
		For local production:TProduction = EachIn finishedProductions
			productionsToProduce.Remove(production)

			'fetch next production of that script and start its shooting
			local nextProduction:TProduction
			For local p:TProduction = EachIn productionsToProduce
				if p.studioRoomID <> production.studioRoomID then continue
				If p.IsProduced() or production.IsInPreProduction() then continue

				nextProduction = p
				exit
			Next
			if nextProduction
				Local reduceProductionTimeFactor:Int = 2
				If productionsToProduce.count() = 1 Then reduceProductionTimeFactor = 1
				nextProduction.Start(reduceProductionTimeFactor)
				
				startedProductions :+ 1
			endif
		Next
		
		

		return startedProductions
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return singleton instance
Function GetProductionManager:TProductionManager()
	Return TProductionManager.GetInstance()
End Function