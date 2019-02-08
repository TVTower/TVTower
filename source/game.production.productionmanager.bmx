SuperStrict
Import "game.production.productionconcept.bmx"
Import "game.production.productioncompany.bmx"
Import "game.production.bmx"


Type TProductionManager
	'contains all production concepts with state "production ready"
	'once one starts productions in a studio
	Field productionsToProduce:TList = CreateList()

	Global _instance:TProductionManager
	Global _eventListeners:TLink[]
	Global createdEnvironment:int = False


	Function GetInstance:TProductionManager()
		if not _instance then _instance = new TProductionManager
		return _instance
	End Function


	Method Initialize()
		productionsToProduce.Clear()

		'create on initialization rather than in "new()" as new is only
		'called once per "application run" (compared to "every game")
		CreateProductionCompanies()
	End Method


	Method New()
		if not createdEnvironment

			'=== REGISTER EVENTS ===
			EventManager.unregisterListenersByLinks(_eventListeners)
			_eventListeners = new TLink[0]

			'resize news genres when loading an older savegame
			_eventListeners :+ [ EventManager.registerListenerFunction( "SaveGame.OnLoad", onSavegameLoad) ]

			createdEnvironment = true
		endif
	End Method


	Function onSavegameLoad:int(triggerEvent:TEventBase)
		if GetProductionCompanyBaseCollection().GetCount() = 0
			CreateProductionCompanies()
		endif
	End Function


	Function CreateProductionCompanies:int()
		'remove old ones
		GetProductionCompanyBaseCollection().Initialize()

		'create a basic companie existing "forever on level 1"
		local c:TProductionCompany = new TProductionCompany
		c.name = GetLocale("JOB_AMATEURS")
		c.SetExperience( 0 )
		c.SetMaxExperience( 0 )
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
	Method GetProductionInStudio:TProduction(roomGUID:string)
		For local production:TProduction = EachIn productionsToProduce
			if production.studioRoomGUID <> roomGUID then continue

			return production
		Next
		return null
	End Method


	Method AbortProduction:int(production:TProduction)
		if production.Abort()
			return productionsToProduce.Remove(production)
		endif
	End Method


	'start the production in the given studio
	'returns amount of productions
	Method StartProductionInStudio:int(roomGUID:string, script:TScript)
		if not roomGUID then return False

		'- abort productions (stop shooting in this room)
		'- cleanup (remove potentially existing previous productions
		'  of that script)
		'- fetch all concepts in that studio
		'- create productions of all concepts "ready to produce"
		'- start shooting of first production


		'abort current production
		For local production:TProduction = EachIn productionsToProduce
			if production.studioRoomGUID <> roomGUID then continue

			if production.IsInProduction()
				production.Abort()
				print "aborted shooting of "+production.productionConcept.GetTitle()
			endif
		Next


		'cleanup
		local removeProductions:TProduction[]
		For local production:TProduction = EachIn productionsToProduce
			if production.productionConcept.script <> script then continue

			removeProductions :+ [production]
		Next
		For local production:TProduction = EachIn removeProductions
			productionsToProduce.Remove(production)
		Next

		local productionCount:int = 0
		local productionConcepts:TProductionConcept[]
		if script.IsSeries()
			productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScripts(script.subScripts)
		else
			productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScript(script)
		endif

		For local productionConcept:TProductionConcept = EachIn productionConcepts
			'skip produced concepts
			if productionConcept.IsProduced() then continue
			'skip not-produceable concepts
			if not productionConcept.IsProduceable() then continue

			local production:TProduction = new TProduction
			production.SetProductionConcept(productionConcept)
			production.SetStudio(roomGUID)

			productionsToProduce.AddLast(production)
			productionCount :+ 1
		Next

		'sort productions by "slots"
		if productionCount > 0
			SortList(productionsToProduce, True, SortProductionsByStudioSlot)
		endif
		'debug
		for local prod:TProduction = eachin productionsToProduce
			print prod.productionConcept.GetTitle()+ "  ep:" + prod.productionConcept.script.GetEpisodeNumber()+"  slot:"+prod.productionConcept.studioSlot
		Next


		'actually start the production
		'- first hit production (with that script) is the one we should
		'  start
		'- other productions are produced once the first one is finished
		For local production:TProduction = EachIn productionsToProduce
			'series? skip if not an episode of this serie
			if production.productionConcept.script.GetParentScript().IsSeries()
				if production.productionConcept.script.parentScriptID <> script.GetID() then continue
			else
				if production.productionConcept.script <> script then continue
			endif
			if production.studioRoomGUID <> roomGUID then continue

			production.Start()

			'start the FIRST production only!
			return productionCount
		Next

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


	Method UpdateProductions:int()
		local finishedProductions:TProduction[]
		'check if one of the productions is finished now
		For local production:TProduction = EachIn productionsToProduce
			production.Update()

			if production.IsProduced() then finishedProductions :+ [production]
		Next

		'remove finished ones and start follow ups of the used studio
		'(extra step to avoid concurrent list modification)
		local startedProductions:int = 0
		For local production:TProduction = EachIn finishedProductions
			productionsToProduce.Remove(production)

			'fetch next production of that script and start its shooting
			local nextProduction:TProduction
			For local p:TProduction = EachIn productionsToProduce
				if p.studioRoomGUID <> production.studioRoomGUID then continue

				nextProduction = p
				exit
			Next
			if nextProduction
				nextProduction.Start()
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