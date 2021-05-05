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

		'if information is missing (eg old savegame) assign first 
		'possible studio
		if production.studioRoomID = 0 and production.owner > 0
			local firstStudio:TRoomBase = GetRoomCollection().GetFirstByDetails("", "studio", production.owner)
			if firstStudio
				production.studioRoomID = firstStudio.GetID()
			endif
		endif

		
		local otherProduction:TProduction = GetProductionInStudio(production.studioRoomID)
		If otherProduction and otherProduction <> production
			'no need to calculate "real" time here - add some minutes
			'local t:Long = production.productionConcept.script.GetBlocks() * TWorldTime.HOURLENGTH)
			'or exacly continue our broadcast finishes?
			local t:Long = (production.productionConcept.script.GetBlocks()-1) * TWorldTime.HOURLENGTH + 50 * TWorldTime.MINUTELENGTH
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
				If productionsToProduce.count = 1 Then reduceProductionTimeFactor = 1
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