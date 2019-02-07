REM
	===========================================================
	code for PlayerProgrammeCollection
	===========================================================
ENDREM
SuperStrict
Import "game.gamerules.bmx"
Import "game.gameobject.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.broadcastmaterial.advertisement.bmx"
Import "game.production.script.bmx"
Import "game.production.productionconcept.bmx"



Type TPlayerProgrammeCollectionCollection
	Field plans:TPlayerProgrammeCollection[]
	Global _instance:TPlayerProgrammeCollectionCollection
	Global _eventListeners:TLink[0]


	Function GetInstance:TPlayerProgrammeCollectionCollection()
		if not _instance then _instance = new TPlayerProgrammeCollectionCollection
		return _instance
	End Function


	Method New()
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'informing _old_ instances of the various roomhandlers
		_eventListeners :+ [ EventManager.registerListenerFunction( "SaveGame.OnLoad", onSaveGameLoad ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "StationMap.onRecalculateAudienceSum", onRecalculateStationMapAudienceSum ) ]
	End Method


	Method Set:int(playerID:int, plan:TPlayerProgrammeCollection)
		if playerID <= 0 then return False
		if playerID > plans.length then plans = plans[.. playerID]
		plans[playerID-1] = plan
	End Method


	Method Get:TPlayerProgrammeCollection(playerID:int)
		if playerID <= 0 or playerID > plans.length then return null
		return plans[playerID-1]
	End Method


	Method InitializeAll:int()
		For local obj:TPlayerProgrammeCollection = eachin plans
			obj.Initialize()
		Next
	End Method


	Method Initialize:int()
		InitializeAll()
	End Method


	Function onSaveGameLoad:int( triggerEvent:TEventBase )
		'invalidate caches
		For local obj:TPlayerProgrammeCollection = eachin GetInstance().plans
			obj._programmeLicences = null
		Next
	End Function


	'scale down trailer mods according to an increased reach
	Function onRecalculateStationMapAudienceSum:int( triggerEvent:TEventBase )
		local owner:int = TOwnedGameObject(triggerEvent.GetSender()).GetOwner()
		local collection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner)
		if not collection then return False

		'only interested in an audience increase!
		local reach:int = triggerEvent.GetData().GetInt("reach", 0)
		local reachBefore:int = triggerEvent.GetData().GetInt("reachBefore", 0)
		if reach <= reachBefore then return False


		local trailerEffectivenessScale:Float = 1.0
		if reach = 0
			'it is no longer worth a bit
			trailerEffectivenessScale = 0
		else
			trailerEffectivenessScale = reachBefore/float(reach)
		endif
'		print "trailerEffectivenessScale: "+ trailerEffectivenessScale

		'loop over all licences: series, episodes, collection entries..
		For local licence:TProgrammeLicence = EachIn collection.GetProgrammeLicences()
'			print "scaling down: " + licence.GetTitle()
			'only scale if there was a trailerMod existing before
			'(save some memory and savegame space)
			if licence.data.GetTrailerMod(owner, False)
'				print "  before: " + licence.data.GetTrailerMod(owner, True).ToStringPercentage(2)

				licence.data.GetTrailerMod(owner).MultiplyFloat(trailerEffectivenessScale)

'				print "   after: " + licence.data.GetTrailerMod(owner, True).ToStringPercentage(2)
			endif
		Next

	End Function
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerProgrammeCollectionCollection:TPlayerProgrammeCollectionCollection()
	Return TPlayerProgrammeCollectionCollection.GetInstance()
End Function
'return specific collection
Function GetPlayerProgrammeCollection:TPlayerProgrammeCollection(playerID:int)
	Return TPlayerProgrammeCollectionCollection.GetInstance().Get(playerID)
End Function




'holds all Programmes a player possesses
Type TPlayerProgrammeCollection extends TOwnedGameObject {_exposeToLua="selected"}
	'containing all broadcastable licences (movies, episodes and collection
	'entries)
	Field _programmeLicences:TList = CreateList() {nosave}

	Field singleLicences:TList = CreateList()
	Field seriesLicences:TList = CreateList()
	Field collectionLicences:TList = CreateList()
	Field news:TList = CreateList()
	Field scripts:TList = CreateList()
	Field adContracts:TList = CreateList()
	'production concepts for productions
	Field productionConcepts:TList = CreateList()
	'scripts in the suitcase
	Field suitcaseScripts:TList = CreateList()
	'scripts in our studios
	Field studioScripts:TList = CreateList()
	'objects not available directly but still owned
	Field suitcaseProgrammeLicences:TList = CreateList()
	'objects in the suitcase but not signed
	Field suitcaseAdContracts:TList	= CreateList()
	Field justAddedProgrammeLicences:TList = CreateList() {nosave}
	'FALSE to avoid recursive handling (network)
	Global fireEvents:int = TRUE
	Global _eventListeners:TLink[]


	Method Create:TPlayerProgrammeCollection(owner:int)
		GetPlayerProgrammeCollectionCollection().Set(owner, self)
		self.owner = owner
		Return self
	End Method


	Method GenerateGUID:string()
		return "playerprogrammecollection-"+id
	End Method


	Method Initialize:Int()
		'invalidate
		_programmeLicences = null

		singleLicences.Clear()
		seriesLicences.Clear()
		adContracts.Clear()
		scripts.Clear()
		productionConcepts.Clear()
		studioScripts.Clear()
		suitcaseScripts.Clear()
		suitcaseProgrammeLicences.Clear()
		suitcaseAdContracts.Clear()
		justAddedProgrammeLicences.Clear()
		news.Clear()

		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
		_eventListeners :+ [ EventManager.registerListenerMethod( "programmeproduction.onFinish", self, "onFinishProgrammeProduction" ) ]

	End Method


	'invalidate cache (new episodes added to series)
	Method onFinishProgrammeProduction:int( triggerEvent:TEventBase )
		'invalidate
		_programmeLicences = null
	End Method


	Method GetSingleLicenceCount:Int() {_exposeToLua}
		Return singleLicences.count()
	End Method


	Method GetSeriesLicenceCount:Int() {_exposeToLua}
		Return seriesLicences.count()
	End Method


	Method GetProgrammeLicenceCount:Int() {_exposeToLua}
		Return GetProgrammeLicences().count()
	End Method


	Method GetAdContractCount:Int() {_exposeToLua}
		Return adContracts.count()
	End Method


	Method GetScriptCount:Int() {_exposeToLua}
		Return scripts.count()
	End Method


	Method GetProductionConceptCount:Int() {_exposeToLua}
		Return productionConcepts.count()
	End Method


	Method GetFilteredProductionConceptCount:Int(filter:TProductionConceptFilter) {_exposeToLua}
		local count:int = 0
		For local pc:TProductionConcept = EachIn productionConcepts
			if filter.DoesFilter(pc) then count :+ 1
		Next
		return count
	End Method


	Method GetSuitcaseProgrammeLicenceCount:int() {_exposeToLua}
		return suitcaseProgrammeLicences.count()
	End Method


	Method GetSuitcaseProgrammeLicencesArray:TProgrammeLicence[]() {_exposeToLua}
		'would return an array of type "object[]"
		'Return suitcaseProgrammeLicences.toArray()

		local result:TProgrammeLicence[ suitcaseProgrammeLicences.Count() ]
		local pos:int = 0
		For local p:TProgrammeLicence = eachin suitcaseProgrammeLicences
			result[pos] = p
			pos :+ 1
		Next
		return result
	End Method


	'returns a freshly created broadcast material
	'=====
	'recognized materialSources: TProgrammeLicende, TAdContract
	Method GetBroadcastMaterial:TBroadcastMaterial(materialSource:object)
		local broadcastMaterial:TBroadcastMaterial = null

		'check if we find something valid
		if TProgrammeLicence(materialSource)
			local licence:TProgrammeLicence = TProgrammeLicence(materialSource)
			'stop if we do not own this licence (and not in suitcase now)
			if not HasProgrammeLicence(licence) then Return Null
			'do not allow broadcast of an "header"
			'TODO: check possibility for "series trailer"
			if licence.GetSubLicenceCount() > 0 then Return Null

			'set broadcast material
			broadcastMaterial = TProgramme.Create(licence)
		elseif TAdContract(materialSource)
			local contract:TAdContract = TAdContract(materialSource)
			'stop if we do not own this licence
			if not HasAdContract(contract) then Return Null

			'set broadcast material
			broadcastMaterial = new TAdvertisement.Create(contract)
		endif
		return broadcastMaterial
	End Method


	Method GetBroadcastMaterialType:int(materialSource:object) {_exposeToLua}
		if TProgrammeLicence(materialSource) then return TVTBroadcastMaterialType.PROGRAMME
		if TAdContract(materialSource) then return TVTBroadcastMaterialType.ADVERTISEMENT
		if TNewsShow(materialSource) then return TVTBroadcastMaterialType.NEWSSHOW
		if TNews(materialSource) then return TVTBroadcastMaterialType.NEWS

		return TVTBroadcastMaterialType.UNKNOWN
	End Method

	'=== ADCONTRACTS ===

	'removes AdContract from Collection (Advertising-Menu in Programmeplanner)
	Method RemoveAdContract:int(contract:TAdContract)
		If not contract then return False
		if adContracts.Remove(contract)
			'remove this contract from the global contracts list too
			GetAdContractCollection().Remove(contract)

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.triggerEvent( TEventSimple.Create( "programmecollection.removeAdContract", new TData.add("adcontract", contract), self ) )
		endif
	End Method


	Method AddAdContract:Int(contract:TAdContract, forceAdd:int = False)
		If not contract then return False
		if adContracts.contains(contract) then return False

		if contract.sign(owner, -1, forceAdd)
			adContracts.AddLast(contract)
			'if stored in suitcase ...remove it from there as we signed it
			suitcaseAdContracts.Remove(contract)

			'emit an event so eg. network can recognize the change
			If fireEvents then EventManager.triggerEvent( TEventSimple.Create( "programmecollection.addAdContract", new TData.add("adcontract", contract), self ) )
			return TRUE
		else
			return FALSE
		endif
	End Method


	Method GetUnsignedAdContractFromSuitcase:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract = EachIn suitcaseAdContracts
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method GetUnsignedAdContractFromSuitcaseByGUID:TAdContract(guid:string) {_exposeToLua}
		For Local contract:TAdContract = EachIn suitcaseAdContracts
			If contract.GetGUID() = guid Then Return contract
		Next
		Return Null
	End Method


	Method HasUnsignedAdContractInSuitcase:int(contract:TAdContract)
		If not contract then return FALSE
		return suitcaseAdContracts.contains(contract)
	End Method


	'used when adding a contract to the suitcase
	Method AddUnsignedAdContractToSuitcase:int(contract:TAdContract)
		If not contract then return FALSE
		'do not add if already "full"
		if suitcaseAdContracts.count() >= GameRules.adContractsPerPlayerMax then return FALSE

		'add a special block-object to the suitcase
		suitcaseAdContracts.AddLast(contract)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.addUnsignedAdContractToSuitcase", new TData.add("adcontract", contract), self))

		return TRUE
	End Method


	Method RemoveUnsignedAdContractFromSuitcase:int(contract:TAdContract)
		if not suitcaseAdContracts.Contains(contract) then return FALSE
		suitcaseAdContracts.Remove(contract)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeUnsignedAdContractFromSuitcase", new TData.add("adcontract", contract), self))
		return TRUE
	End Method


	'=== PROGRAMMELICENCES ===

	'readd programmes from suitcase to player's list of available programmes
	Method ReaddProgrammeLicencesFromSuitcase:int()
		For local l:TProgrammeLicence = EachIn suitcaseProgrammeLicences.Copy()
			if not RemoveProgrammeLicenceFromSuitcase( l )
				TLogger.Log("ReaddProgrammeLicencesFromSuitcase", "Failed to Remove licence ~q"+ l.GetTitle()+"~q ["+l.GetGUID()+"] from suitcase.", LOG_ERROR | LOG_DEBUG)
			endif
		Next
		return TRUE
	End Method


	Method HasProgrammeLicenceInSuitcase:int(programmeLicence:TProgrammeLicence)
		If not programmeLicence then return FALSE
		return suitcaseProgrammeLicences.contains(programmeLicence)
	End Method


	Method AddProgrammeLicenceToSuitcase:int(programmeLicence:TProgrammeLicence)
		if programmeLicence.HasParentLicence()
			TLogger.Log("AddProgrammeLicenceToSuitcase", "Adding of sublicences to suitcase is not allowed", LOG_DEBUG)
			return FALSE
		endif

		'do not add if already "full"
		if suitcaseProgrammeLicences.count() >= GameRules.maxProgrammeLicencesInSuitcase
			TLogger.Log("AddProgrammeLicenceToSuitcase", "Not enough space to add licence to suitcase", LOG_DEBUG)
			return FALSE
		endif

		if not programmeLicence.IsOwnedByPlayer(owner)
			if not programmeLicence.IsOwnedByVendor()
				print "TODO: buying licence from other owner: "+ programmeLicence.owner+" =/= " + owner
			endif
			if not programmeLicence.buy(owner) then return FALSE
		endif

		singleLicences.remove(programmeLicence)
		seriesLicences.remove(programmeLicence)
		collectionLicences.remove(programmeLicence)

		'invalidate
		_programmeLicences = null

		suitcaseProgrammeLicences.AddLast(programmeLicence)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.addProgrammeLicenceToSuitcase", new TData.add("programmeLicence", programmeLicence), self))

		return TRUE
	End Method


	Method ClearJustAddedProgrammeLicences:Int()
		justAddedProgrammeLicences.Clear()
	End Method


	Method RemoveProgrammeLicenceFromSuitcase:int(licence:TProgrammeLicence)
		if not suitcaseProgrammeLicences.Contains(licence) then return FALSE

		if licence.HasParentLicence()
			'just remove, without adding
			suitcaseProgrammeLicences.Remove(licence)
			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeProgrammeLicenceFromSuitcase", new TData.add("programmeLicence", licence), self))

			TLogger.Log("RemoveProgrammeLicenceFromSuitcase", "Removed an sublicence from suitcase", LOG_DEBUG)
			return FALSE
		endif

		if AddProgrammeLicence(licence, FALSE)
			suitcaseProgrammeLicences.Remove(licence)

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeProgrammeLicenceFromSuitcase", new TData.add("programmeLicence", licence), self))

			return True
		else
			return False
		endif
	End Method


	Method RemoveProgrammeLicence:Int(licence:TProgrammeLicence, sell:int=FALSE)
		If licence = Null Then Return False
		'do not allow removal of episodes/collection elements (should get removed via header)
		If licence.HasParentLicence() then return False
		'not owning
		if not HasProgrammeLicence(licence) and not HasProgrammeLicenceInSuitcase(licence) then return False

		if sell and not licence.sell() then return FALSE


		'avoid others benefit from our trailers and remove bonus for
		'this and sublicences
		'-> is automatically done on "SetOwner" (so when giving back to licence pool)
		'licence.RemoveTrailerMod()


		'Print "RON: PlayerCollection.RemoveProgrammeLicence: sell="+sell+" title="+licence.GetTitle()
		singleLicences.remove(licence)
		seriesLicences.remove(licence)
		'remove from suitcase too!
		suitcaseProgrammeLicences.remove(licence)
		'remove from justAddedProgrammeLicences too!
		justAddedProgrammeLicences.Remove(licence)

		'invalidate
		_programmeLicences = null

		'set unused again (give back to pool), do this regardless of
		'"sell" result
		'refills broadcast limits, optionally refreshes topicality etc.
		licence.GiveBackToLicencePool()


		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeProgrammeLicence", new TData.add("programmeLicence", licence).addNumber("sell", sell), self))

		return True
	End Method


	Method AddProgrammeLicence:Int(licence:TProgrammeLicence, buy:int=FALSE)
		If not licence then return FALSE
		'do not allow adding of episodes / collection-elements
		'(should get added via header)
		If licence.parentLicenceGUID
			TLogger.Log("AddProgrammeLicence", "Cannot add licence ~q"+licence.GetTitle()+"~q ["+licence.GetGUID()+"] to programme collection. Licence has parentLicenceGUID set.", LOG_ERROR | LOG_DEBUG)
			return False
		endif

		'already added (to archive, not suitcase)
		if HasProgrammeLicence(licence) then return False

		'if owner differs, check if we have to buy or got that gifted
		'at program start or through special event...
		if owner <> licence.owner
			if buy
				if not licence.buy(owner) then return FALSE
			else
				licence.SetOwner(owner)
			endif
		endif

		'Print "RON: PlayerCollection.AddProgrammeLicence: buy="+buy+" title="+Licence.GetTitle()

		If licence.isSingle() Then singleLicences.AddLast(licence)
		if licence.isSeries() then seriesLicences.AddLast(licence)
		if licence.isCollection() then collectionLicences.AddLast(licence)

		'invalidate
		_programmeLicences = null

		justAddedProgrammeLicences.AddLast(licence)

		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.addProgrammeLicence", new TData.add("programmeLicence", licence).addNumber("buy", buy), self))
		return TRUE
	End Method


	'=== SCRIPTS  ===

	Method HasScriptInStudio:int(script:TScript)
		If not script then return FALSE
		return studioScripts.contains(script)
	End Method


	Method HasScriptInSuitcase:int(script:TScript)
		If not script then return FALSE
		return suitcaseScripts.contains(script)
	End Method


	'move all scripts from suitcase to player's list of archived scripts
	Method MoveScriptsFromSuitcaseToArchive:int()
		For Local obj:TScript = EachIn suitcaseScripts
			MoveScriptFromSuitcaseToArchive(obj)
		Next
		return TRUE
	End Method


	Method MoveScriptFromArchiveToSuitcase:int(script:TScript)
		if not scripts.Contains(script) then return False
		if suitcaseScripts.contains(script) then return False

		suitcaseScripts.AddLast(script)
		scripts.Remove(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.MoveScriptFromArchiveToSuitcase", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif

		return TRUE
	End Method


	Method MoveScriptFromSuitcaseToArchive:int(script:TScript)
		if not suitcaseScripts.Contains(script) then return False
		if scripts.contains(script) then return False

		scripts.AddLast(script)
		suitcaseScripts.Remove(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.MoveScriptFromSuitcaseToArchive", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif

		return TRUE
	End Method


	Method MoveScriptFromStudioToSuitcase:int(script:TScript)
		if not studioScripts.Contains(script) then return False
		if suitcaseScripts.contains(script) then return False

		'do not add if already "full"
		if not CanMoveScriptToSuitcase() then return False

		suitcaseScripts.AddLast(script)
		studioScripts.Remove(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.MoveScriptFromStudioToSuitcase", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif
		return TRUE
	End Method


	Method MoveScriptFromSuitcaseToStudio:int(script:TScript)
		if not suitcaseScripts.Contains(script) then return False
		if studioScripts.contains(script) then return False

		studioScripts.AddLast(script)
		suitcaseScripts.Remove(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.MoveScriptFromSuitcaseToStudio", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif
		return TRUE
	End Method


	Method MoveScriptFromStudioToArchive:int(script:TScript)
		if not studioScripts.Contains(script) then return False
		if scripts.contains(script) then return False

		scripts.AddLast(script)
		studioScripts.Remove(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.MoveScriptFromStudioToArchive", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif
		return TRUE
	End Method


	Method CanMoveScriptToSuitcase:int() {_exposeToLua}
		return GameRules.maxScriptsInSuitcase <= 0 or suitcaseScripts.count() < GameRules.maxScriptsInSuitcase
	End Method


	Method AddScriptToSuitcase:int(script:TScript)
		if not CanMoveScriptToSuitcase() then return FALSE

		if not script.IsOwnedByPlayer(owner)
			if not script.IsOwnedByVendor()
				print "TODO: buying script from other owner: "+ script.owner+" =/= " + owner
			endif
			if not script.buy(owner) then return FALSE
		endif

		'maybe we already owned it before - so it is stored already
		'in the various scripts lists
		scripts.remove(script)
		studioScripts.remove(script)

		suitcaseScripts.AddLast(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.addScriptToSuitcase", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif

		return TRUE
	End Method



	Method RemoveScriptFromSuitcase:int(script:TScript)
		if not suitcaseScripts.Contains(script) then return FALSE

		if scripts.contains(script)
			TLogger.Log("RemoveScriptFromSuitcase()", "Trying to remove script from suitcase while it is still in the list of scripts.", LOG_WARNING)
		else
			scripts.AddLast(script)
		endif

		suitcaseScripts.Remove(script)

		'emit an event so eg. network can recognize the change
		if fireEvents
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeScriptFromSuitcase", new TData.add("script", script), self))
			EventManager.triggerEvent(TEventSimple.Create("programmecollection.moveScript", new TData.add("script", script), self))
		endif

		return TRUE
	End Method


	'totally remove a script from the collection
	Method RemoveScript:Int(script:TScript, sell:int=FALSE)
		If script = Null Then Return False

		if sell
			if not script.sell() then return FALSE
		endif

		'sold or "destroyed" script, so destroy its production concepts too
		DestroyProductionConceptsByScript(script)

		scripts.remove(script)
		studioScripts.remove(script)
		'remove from suitcase too!
		suitcaseScripts.remove(script)


		'set unused again (give back to pool), do this regardless of
		'"sell" result
		'refills production limits, optionally makes it no longer
		'tradeable etc.
		script.GiveBackToScriptPool()


		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeScript", new TData.add("script", script).addNumber("sell", sell), self))
	End Method


	Method AddScript:Int(script:TScript, buy:int=FALSE)
		If not script then return FALSE

		'if owner differs, check if we have to buy or got that gifted
		'at program start or through special event...
		if owner <> script.owner
			if buy
				if not script.buy(owner) then return FALSE
			else
				script.SetOwner(owner)
			endif
		endif

		scripts.AddLast(script)

		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.addScript", new TData.add("script", script).addNumber("buy", buy), self))
		return TRUE
	End Method


	'=== PRODUCTION CONCEPTS  ===
	Method CanCreateProductionConcept:Int(script:TScript) {_exposeToLua}
		'do not allow more concepts than the rules say!
		return GetProductionConceptCollection().GetProductionConceptsByScript(script).length  < GameRules.maxProductionConceptsPerScript
	End Method


	Method CreateProductionConcept:Int(script:TScript)
		if not script then return False
		if not CanCreateProductionConcept(script)
			'emit event to inform others (eg. for ingame warning)
			EventManager.triggerEvent( TEventSimple.Create("programmecollection.onCreateProductionConceptFailed", new TData.AddNumber("productionConceptCount", GetProductionConceptCollection().GetProductionConceptsByScript(script).length).AddNumber("playerID", owner)) )

			return False
		endif

		AddProductionConcept( new TProductionConcept.Initialize(owner, script) )
		return True
	End Method


	Method AddProductionConcept:Int(productionConcept:TProductionConcept)
		if not productionConcept then return False
		if productionConcepts.contains(productionConcept) then return False

		if owner <> productionConcept.owner
			productionConcept.SetOwner(owner)
		endif

		GetProductionConceptCollection().Add(productionConcept)
		productionConcepts.AddLast(productionConcept)

		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.addProductionConcept", new TData.add("productionConcept", productionConcept), self))
		return TRUE
	End Method


	'remove from PlayerProgrammeCollection _AND_ "ProductionConceptCollection"
	Method DestroyProductionConcept:Int(productionConcept:TProductionConcept)
		'failed to remove from programme collection ?
		if not RemoveProductionConcept(productionConcept) then return False
		'failed to remove from production concept collection ?
		if not GetProductionConceptCollection().Remove(productionConcept) then return False

		'emit event to inform others
		if fireEvents then EventManager.triggerEvent( TEventSimple.Create("programmecollection.destroyProductionConcept", new TData.Add("productionConcept", productionConcept), self))

		return True
	End Method


	'remove a production conept from the collection
	'ATTENTION: it is then still in "ProductionConceptCollection" !
	Method RemoveProductionConcept:Int(productionConcept:TProductionConcept)
		if productionConcept = Null then return False
		if not productionConcepts.remove(productionConcept) then Return False

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.removeProductionConcept", new TData.add("productionConcept", productionConcept), self))

		return True
	End Method


	'destroy all production concepts of a given script
	'HINT: they are also removed from ProductionConceptCollection !
	Method DestroyProductionConceptsByScript:Int(script:TScript)
		local remove:TProductionConcept[]
		For local pc:TProductionConcept = EachIn productionConcepts
			if pc.script = script then remove :+ [pc]
		Next

		'search for episodes
		local removedSubs:int = 0
		if script.GetSubScriptCount() > 0
			for local subScript:TScript = Eachin script.subScripts
				removedSubs :+ DestroyProductionConceptsByScript(subScript)
			next
		endif

		'finally remove a potentially found concept
		For local pc:TProductionConcept = EachIn remove
			DestroyProductionConcept(pc)
		Next

		return remove.length + removedsubs
	End Method


	'remove all production concepts of a given script
	'ATTENTION: they are then still in the ProductionConceptCollection !
	Method RemoveProductionConceptsByScript:Int(script:TScript)
		local remove:TProductionConcept[]
		For local pc:TProductionConcept = EachIn productionConcepts
			if pc.script = script then remove :+ [pc]
		Next

		For local pc:TProductionConcept = EachIn remove
			RemoveProductionConcept(pc)
		Next
	End Method


	'=== GETTERS ===

	Method GetRandomProgrammeLicence:TProgrammeLicence()
		'do not expose to LUA/AI - uses RandRange()

		if GetProgrammeLicenceCount() = 0 then return NULL
		Return TProgrammeLicence(GetProgrammeLicences().ValueAtIndex(RandRange(0, GetProgrammeLicences().Count() - 1)))
	End Method


	Method GetRandomSingleLicence:TProgrammeLicence()
		'do not expose to LUA/AI - uses RandRange()

		if singleLicences.count() = 0 then return NULL
		Return TProgrammeLicence(singleLicences.ValueAtIndex(RandRange(0, singleLicences.count() - 1)))
	End Method


	Method GetRandomSeriesLicence:TProgrammeLicence()
		'do not expose to LUA/AI - uses RandRange()

		if seriesLicences.count() = 0 then return NULL
		Return TProgrammeLicence(seriesLicences.ValueAtIndex(RandRange(0, seriesLicences.count() - 1)))
	End Method


	Method GetRandomAdContract:TAdContract()
		'do not expose to LUA/AI - uses RandRange()

		if adContracts.count() = 0 then return NULL
		Return TAdContract(adContracts.ValueAtIndex(RandRange(0, adContracts.count() - 1)))
	End Method


	Method GetRandomScript:TScript() {_exposeToLua}
		'do not expose to LUA/AI - uses RandRange()

		if scripts.count() = 0 then return Null
		Return TScript(scripts.ValueAtIndex(RandRange(0, scripts.count() - 1)))
	End Method


	'get programmeLicence by index number in list - useful for lua-scripts
	Method GetSuitcaseProgrammeLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0)
		if arrayIndex < 0 or arrayIndex >= suitcaseProgrammeLicences.Count() then return Null
		Return TProgrammeLicence(suitcaseProgrammeLicences.ValueAtIndex(arrayIndex))
	End Method


	'get programmeLicence by index number in list - useful for lua-scripts
	Method GetSuitcaseProgrammeLicenceByGUID:TProgrammeLicence(guid:string)
		For local licence:TProgrammeLicence = EachIn suitcaseProgrammeLicences
			if licence.GetGUID() = guid then return licence
		Next
		return Null
	End Method


	'get programmeLicence by index number in list - useful for lua-scripts
	Method GetProgrammeLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0) {_exposeToLua}
		if arrayIndex < 0 or arrayIndex >= GetProgrammeLicenceCount() then return Null
		Return TProgrammeLicence(GetProgrammeLicences().ValueAtIndex(arrayIndex))
	End Method


	'get single licence by index number in list - useful for lua-scripts
	Method GetSingleLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0) {_exposeToLua}
		if arrayIndex < 0 or arrayIndex >= singleLicences.Count() then return Null
		Return TProgrammeLicence(singleLicences.ValueAtIndex(arrayIndex))
	End Method


	'get series by index number in list - useful for lua-scripts
	Method GetSeriesLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0) {_exposeToLua}
		if arrayIndex < 0 or arrayIndex >= seriesLicences.Count() then return Null
		Return TProgrammeLicence(seriesLicences.ValueAtIndex(arrayIndex))
	End Method


	'get contract by index number in list - useful for lua-scripts
	Method GetAdContractAtIndex:TAdContract(arrayIndex:Int=0) {_exposeToLua}
		if arrayIndex < 0 or arrayIndex >= adContracts.Count() then return Null
		Return TAdContract(adContracts.ValueAtIndex(arrayIndex))
	End Method


	'get script by index number in list - useful for lua-scripts
	Method GetScriptAtIndex:TScript(arrayIndex:Int=0) {_exposeToLua}
		if arrayIndex < 0 or arrayIndex >= scripts.Count() then return Null
		Return TScript(scripts.ValueAtIndex(arrayIndex))
	End Method


	'get production concept by index number in list - useful for lua-scripts
	Method GetProductionConceptAtIndex:TProductionConcept(arrayIndex:Int=0) {_exposeToLua}
		if arrayIndex < 0 or arrayIndex >= productionConcepts.Count() then return Null
		Return TProductionConcept(productionConcepts.ValueAtIndex(arrayIndex))
	End Method


	Method GetLicencesByFilter:TProgrammeLicence[](filter:TProgrammeLicenceFilter)
		local result:TProgrammeLicence[]
'		local lists:TList[] = [GetProgrammeLicences(), GetSeriesLicences(), GetCollectionLicences()]
'		For local l:TList = EachIn lists
'			For local licence:TProgrammeLicence = EachIn l
			For local licence:TProgrammeLicence = EachIn GetProgrammeLicences()
				'add to result set
				if filter.DoesFilter(licence) then result :+ [licence]
			Next
'		Next
		return result
	End Method


	Method GetFilteredLicenceCount:int(filter:TProgrammeLicenceFilter, includeLicenceTypes:int=-1)
		local amount:int = 0
		if includeLicenceTypes = -1
			includeLicenceTypes = TVTProgrammeLicenceType.SINGLE | TVTProgrammeLicenceType.COLLECTION | TVTProgrammeLicenceType.SERIES
		endif

		local lists:TList[]
		if includeLicenceTypes & TVTProgrammeLicenceType.SINGLE then lists :+ [singleLicences]
		if includeLicenceTypes & TVTProgrammeLicenceType.SERIES then lists :+ [seriesLicences]
		if includeLicenceTypes & TVTProgrammeLicenceType.COLLECTION then lists :+ [collectionLicences]

		if not filter
			For local l:TList = EachIn lists
				amount :+ l.Count()
			Next
		else
			For local l:TList = EachIn lists
				For local licence:TProgrammeLicence = eachin l
					if filter.DoesFilter(licence) then amount:+ 1
				Next
			Next
		endif
		return amount
	End Method


	Method GetProgrammeGenresCount:int(genres:int[], includeLicenceTypes:int = -1) {_exposeToLua}
		local amount:int = 0
		if includeLicenceTypes = -1
			includeLicenceTypes = TVTProgrammeLicenceType.SINGLE | TVTProgrammeLicenceType.COLLECTION | TVTProgrammeLicenceType.SERIES
		endif

		local lists:TList[]
		if includeLicenceTypes & TVTProgrammeLicenceType.SINGLE then lists :+ [singleLicences]
		if includeLicenceTypes & TVTProgrammeLicenceType.SERIES then lists :+ [seriesLicences]
		if includeLicenceTypes & TVTProgrammeLicenceType.COLLECTION then lists :+ [collectionLicences]

		For local l:TList = EachIn lists
			For local licence:TProgrammeLicence = eachin l
				For local genre:int = eachin genres
					if licence.GetGenre() = genre
						amount:+1
						continue
					endif
				Next
			Next
		Next
		return amount
	End Method


	Method HasBroadcastMaterial:int(obj:TBroadcastMaterial) {_exposeToLua}
		if TProgramme(obj)
			return HasProgrammeLicence( TProgramme(obj).licence )
		elseif TAdvertisement(obj)
			return HasAdContract( TAdvertisement(obj).contract )
		elseif TNews(obj)
			return HasNewsEvent( TNews(obj).newsEvent )
		endif
		return False
	End Method


	Method HasProgrammeLicence:int(licence:TProgrammeLicence) {_exposeToLua}
		return GetProgrammeLicences().contains(licence)
	End Method


	Method HasAdContract:int(Contract:TAdContract) {_exposeToLua}
		return adContracts.contains(contract)
	End Method


	Method HasScript:int(script:TScript) {_exposeToLua}
		return scripts.contains(script)
	End Method


	Method HasNews:int(newsObject:TNews) {_exposeToLua}
		return news.contains(newsObject)
	End Method


	Method HasNewsEvent:int(newsEvent:TNewsEvent) {_exposeToLua}
		For local n:TNews = EachIn news
			if n.newsEvent = newsEvent then return True
		Next
		return False
	End Method


	Method GetProgrammeLicence:TProgrammeLicence(id:Int) {_exposeToLua}
		For Local licence:TProgrammeLicence = EachIn GetProgrammeLicences()
			If licence.id = id Then Return licence
		Next
		Return Null
	End Method


	Method GetProgrammeLicenceByGUID:TProgrammeLicence(GUID:String) {_exposeToLua}
		For Local licence:TProgrammeLicence = EachIn GetProgrammeLicences()
			If licence.GetGUID() = GUID Then Return licence
		Next
		Return Null
	End Method


	Method GetAdContract:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn adContracts
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method GetAdContractByGUID:TAdContract(guid:string) {_exposeToLua}
		For Local contract:TAdContract=EachIn adContracts
			If contract.GetGUID() = guid Then Return contract
		Next
		Return Null
	End Method


	Method GetAdContractByBase:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn adContracts
			If contract.base.id = id Then Return contract
		Next
		Return Null
	End Method


	Method GetScript:TScript(id:Int) {_exposeToLua}
		For Local script:TScript = EachIn scripts
			If script.id = id Then Return script
		Next
		Return Null
	End Method


	Method GetProductionConcept:TProductionConcept(guid:string) {_exposeToLua}
		For Local pc:TProductionConcept = EachIn productionConcepts
			If pc.GetGUID() = guid Then Return pc
		Next
		Return Null
	End Method


	Method GetProductionConcepts:TList() {_exposeToLua}
		Return productionConcepts
	End Method


	Method GetSingleLicences:TList() {_exposeToLua}
		Return singleLicences
	End Method


	Method GetSeriesLicences:TList() {_exposeToLua}
		Return seriesLicences
	End Method


	Method GetCollectionLicences:TList() {_exposeToLua}
		Return collectionLicences
	End Method


	Method GetProgrammeLicences:TList() {_exposeToLua}
		if not _programmeLicences
			_programmeLicences = CreateList()
			local lists:TList[] = [singleLicences, seriesLicences, collectionLicences]

			For local list:TList = EachIn lists
				For local l:TProgrammeLicence = EachIn list
					'add single elements (movies, documentations)
					if l.GetSubLicenceCount() = 0
						_programmeLicences.AddLast(l)
					'add episodes
					else
						'add header of series/collection too!
						_programmeLicences.AddLast(l)

						For local subL:TProgrammeLicence = EachIn l.subLicences
							_programmeLicences.AddLast(subL)
						Next
					endif
				Next
			Next
		endif
		return _programmeLicences
	End Method


	Method GetAdContractsArray:TAdContract[]() {_exposeToLua}
		Return TAdContract[](adContracts.toArray())
	End Method


	Method GetAdContracts:TList() {_exposeToLua}
		Return adContracts
	End Method


	Method GetScripts:TList() {_exposeToLua}
		Return scripts
	End Method


	Method GetScriptsCount:Int() {_exposeToLua}
		Return scripts.count()
	End Method


	Method GetNewsArray:TNews[]() {_exposeToLua}
		'would return an array of type "object[]"
		'Return news.toArray()

		local result:TNews[ news.Count() ]
		local pos:int = 0
		For local n:TNews = eachin news
			result[pos] = n
			pos :+ 1
		Next
		return result
	End Method


	'returns the amount of news currently available
	Method GetNewsCount:Int() {_exposeToLua}
		Return news.count()
	End Method


	'returns the news with the given GUID or Null if not found
	Method GetNews:TNews(GUID:string) {_exposeToLua}
		For Local obj:TNews = EachIn news
			If obj.GetGUID() = GUID Then Return obj
		Next
		Return Null
	End Method


	'returns the block with the given id
	Method GetNewsByID:TNews(id:Int) {_exposeToLua}
		For Local obj:TNews = EachIn news
			If obj.id = id Then Return obj
		Next
		Return Null
	End Method


	'returns the newsblock at a specific position in the list
	Method GetNewsAtIndex:TNews(arrayIndex:Int=0) {_exposeToLua}
		'out of bounds?
		if arrayIndex < 0 OR arrayIndex > news.count()-1 then return Null

		Return TNews( news.ValueAtIndex(arrayIndex) )
	End Method


	Method AddNews:int(newsObject:TNews) {_private} 'do not expose to Lua.
		'skip adding if existing already
		if news.contains(newsObject)
			TLogger.log("TPlayerProgrammeCollection.AddNews", "Adding skipped: already containing news ~q"+newsObject.getTitle()+"~q", LOG_WARNING)
			return FALSE
		endif

		newsObject.owner = owner
		news.AddLast(newsObject)

		if fireEvents then EventManager.triggerEvent(TEventSimple.Create("programmecollection.addNews", new TData.Add("news", newsObject), self))

		return TRUE
	End Method


	Method RemoveNews:int(newsObject:TNews) {_exposeToLua}
		'remove from list
		if news.remove(newsObject)
			'run cleanup
			newsObject.Remove()

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.triggerEvent( TEventSimple.Create( "programmecollection.removeNews", new TData.Add("news", newsObject), self ) )
			return TRUE
		endif
		return FALSE
	End Method
End Type