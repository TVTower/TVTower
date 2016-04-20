SuperStrict
Import "game.production.productionconcept.bmx"
Import "game.production.productioncompany.bmx"
Import "game.production.bmx"


Type TProductionManager
	'contains all production concepts with state "production ready"
	'once one starts productions in a studio
	Field productionsToProduce:TList = CreateList()

	Global _instance:TProductionManager
	Global createdEnvironment:int = False


	Function GetInstance:TProductionManager()
		if not _instance then _instance = new TProductionManager
		return _instance
	End Function


	Method New()
		if not createdEnvironment
			'create some companies
			local cnames:string[] = ["Movie World", "Picture Fantasy", "UniPics", "Motion Gems", "Screen Jewel"]
			For local i:int = 0 until cnames.length
				local c:TProductionCompany = new TProductionCompany
				c.name = cnames[i]
				c.SetExperience( BiasedRandRange(0, 0.35 * TProductionCompanyBase.MAX_XP, 0.25) )
				GetProductionCompanyBaseCollection().Add(c)
			Next
			createdEnvironment = true
		endif
	End Method
	

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
		For local productionConcept:TProductionConcept = EachIn GetProductionConceptCollection().GetProductionConceptsByScript(script)
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


		'actually start the production
		'- first hit production (with that script) is the one we should
		'  start
		'- other productions are produced once the first one is finished
		For local production:TProduction = EachIn productionsToProduce
			if production.productionConcept.script <> script then continue
			if production.studioRoomGUID <> roomGUID then continue

			production.Start()
		Next

		return productionCount
	End Method


	Function CanCreateProductionOfScript:int(script:TScript)
		if not script then return False
		
		return (script.productionCount + 1) < script.ProductionCountMax
	End Function


	Function SortProductionsByStudioSlot:int(o1:object, o2:object)
		local p1:TProduction = TProduction(o1)
		local p2:TProduction = TProduction(o2)
		if not p2 then return 1
		if not p1 then return -1

		if p1.productionConcept.studioSlot < p2.productionConcept.studioSlot then return 1
		if p1.productionConcept.studioSlot > p2.productionConcept.studioSlot then return -1
		return 0
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