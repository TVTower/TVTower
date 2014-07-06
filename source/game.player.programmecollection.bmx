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



Type TPlayerProgrammeCollectionCollection
	Field plans:TPlayerProgrammeCollection[]
	Global _instance:TPlayerProgrammeCollectionCollection


	Function GetInstance:TPlayerProgrammeCollectionCollection()
		if not _instance then _instance = new TPlayerProgrammeCollectionCollection
		return _instance
	End Function


	Method Set:int(playerID:int, plan:TPlayerProgrammeCollection)
		if playerID <= 0 then return False
		if playerID > plans.length then plans = plans[.. playerID]
		plans[playerID-1] = plan
	End Method


	Method Get:TPlayerProgrammeCollection(playerID:int)
		if playerID <= 0 or playerID > plans.length then return null
		return plans[playerID-1]
	End Method
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
	Field programmeLicences:TList			= CreateList()
	Field movieLicences:TList				= CreateList()
	Field seriesLicences:TList				= CreateList()
	Field collectionLicences:TList			= CreateList()
	Field news:TList						= CreateList()
	Field adContracts:TList					= CreateList()
	Field suitcaseProgrammeLicences:TList	= CreateList()	'objects not available directly but still owned
	Field suitcaseAdContracts:TList			= CreateList()	'objects in the suitcase but not signed
	Global fireEvents:int					= TRUE			'FALSE to avoid recursive handling (network)


	Method Create:TPlayerProgrammeCollection(owner:int)
		GetPlayerProgrammeCollectionCollection().Set(owner, self)
		self.owner = owner
		Return self
	End Method


	Method ClearLists()
		programmeLicences.Clear()
		movieLicences.Clear()
		seriesLicences.Clear()
		adContracts.Clear()
		suitcaseProgrammeLicences.Clear()
		suitcaseAdContracts.Clear()
	End Method


	Method GetMovieLicenceCount:Int() {_exposeToLua}
		Return movieLicences.count()
	End Method


	Method GetSeriesLicenceCount:Int() {_exposeToLua}
		Return seriesLicences.count()
	End Method


	Method GetProgrammeLicenceCount:Int() {_exposeToLua}
		Return programmeLicences.count()
	End Method


	Method GetAdContractCount:Int() {_exposeToLua}
		Return adContracts.count()
	End Method


	'returns a freshly created broadcast material
	'=====
	'recognized materialSources: TProgrammeLicende, TAdContract
	Method GetBroadcastMaterial:TBroadcastMaterial(materialSource:object)
		local broadcastMaterial:TBroadcastMaterial = null

		'check if we find something valid
		if TProgrammeLicence(materialSource)
			local licence:TProgrammeLicence = TProgrammeLicence(materialSource)
			'stop if we do not own this licence
			if not HasProgrammeLicence(licence) then Return Null

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


	'removes AdContract from Collection (Advertising-Menu in Programmeplanner)
	Method RemoveAdContract:int(contract:TAdContract)
		If not contract then return False
		if adContracts.Remove(contract)
			'remove this contract from the global contracts list too
			GetAdContractCollection().Remove(contract)

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeAdContract", new TData.add("adcontract", contract), self ) )
		endif
	End Method


	Method AddAdContract:Int(contract:TAdContract)
		If not contract then return FALSE

		if contract.sign( owner ) and not adContracts.contains(contract)
			adContracts.AddLast(contract)
			'if stored in suitcase ...remove it from there as we signed it
			suitcaseAdContracts.Remove(contract)

			'emit an event so eg. network can recognize the change
			If fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.addAdContract", new TData.add("adcontract", contract), self ) )
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


	Method HasUnsignedAdContractInSuitcase:int(contract:TAdContract)
		If not contract then return FALSE
		return suitcaseAdContracts.contains(contract)
	End Method


	'used when adding a contract to the suitcase
	Method AddUnsignedAdContractToSuitcase:int(contract:TAdContract)
		If not contract then return FALSE
		'do not add if already "full"
		if suitcaseAdContracts.count() >= GameRules.maxContracts then return FALSE

		'add a special block-object to the suitcase
		suitcaseAdContracts.AddLast(contract)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.addUnsignedAdContractToSuitcase", new TData.add("adcontract", contract), self))

		return TRUE
	End Method


	Method RemoveUnsignedAdContractFromSuitcase:int(contract:TAdContract)
		if not suitcaseAdContracts.Contains(contract) then return FALSE
		suitcaseAdContracts.Remove(contract)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.removeUnsignedAdContractFromSuitcase", new TData.add("adcontract", contract), self))
		return TRUE
	End Method


	'readd programmes from suitcase to player's list of available programmes
	Method ReaddProgrammeLicencesFromSuitcase:int()
		For Local obj:TProgrammeLicence = EachIn suitcaseProgrammeLicences
			RemoveProgrammeLicenceFromSuitcase(obj)
		Next
		return TRUE
	End Method


	Method HasProgrammeLicenceInSuitcase:int(programmeLicence:TProgrammeLicence)
		If not programmeLicence then return FALSE
		return suitcaseProgrammeLicences.contains(programmeLicence)
	End Method


	Method AddProgrammeLicenceToSuitcase:int(programmeLicence:TProgrammeLicence)
		'do not add if already "full"
		if suitcaseProgrammeLicences.count() >= GameRules.maxContracts then return FALSE

		'if owner differs, check if we have to buy
		if owner <> programmeLicence.owner
			if not programmeLicence.buy(owner) then return FALSE
		endif

		programmeLicences.remove(programmeLicence)
		movieLicences.remove(programmeLicence)
		seriesLicences.remove(programmeLicence)

		suitcaseProgrammeLicences.AddLast(programmeLicence)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.addProgrammeLicenceToSuitcase", new TData.add("programmeLicence", programmeLicence), self))

		return TRUE
	End Method


	Method RemoveProgrammeLicenceFromSuitcase:int(licence:TProgrammeLicence)
		if not suitcaseProgrammeLicences.Contains(licence) then return FALSE

		If licence.isMovie() Then movieLicences.AddLast(licence)
		if licence.isSeries() then seriesLicences.AddLast(licence)
		if licence.isCollection() then collectionLicences.AddLast(licence)
		programmeLicences.AddLast(licence)

		suitcaseProgrammeLicences.Remove(licence)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.removeProgrammeLicenceFromSuitcase", new TData.add("programmeLicence", licence), self))
		return TRUE
	End Method


	Method RemoveProgrammeLicence:Int(licence:TProgrammeLicence, sell:int=FALSE)
		If licence = Null Then Return False

		if sell and not licence.sell() then return FALSE

		'Print "RON: PlayerCollection.RemoveProgrammeLicence: sell="+sell+" title="+licence.GetTitle()
		programmeLicences.remove(licence)
		movieLicences.remove(licence)
		seriesLicences.remove(licence)
		'remove from suitcase too!
		suitcaseProgrammeLicences.remove(licence)

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.removeProgrammeLicence", new TData.add("programmeLicence", licence).addNumber("sell", sell), self))
	End Method


	Method AddProgrammeLicence:Int(licence:TProgrammeLicence, buy:int=FALSE)
		If not licence then return FALSE

		if licence.isEpisode()
			TLogger.log("TPlayerProgrammeCollection.AddProgrammeLicence", "Adding skipped: licence is a series episode", LOG_WARNING)
			return FALSE
		endif

		'if owner differs, check if we have to buy or got that gifted
		'at program start or through special event...
		if owner <> licence.owner
			if buy
				if not licence.buy(owner) then return FALSE
			else
				licence.SetOwner(owner)
			endif
		endif

		'Print "RON: PlayerCollection.AddProgrammeLicence: buy="+buy+" title="+Licence.title

		If licence.isMovie() Then movieLicences.AddLast(licence)
		if licence.isSeries() then seriesLicences.AddLast(licence)
		if licence.isCollection() then collectionLicences.AddLast(licence)
		programmeLicences.AddLast(licence)

		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.addProgrammeLicence", new TData.add("programmeLicence", licence).addNumber("buy", buy), self))
		return TRUE
	End Method


	Method GetRandomProgrammeLicence:TProgrammeLicence(serie:Int = 0) {_exposeToLua}
		If serie Then Return Self.GetRandomSerieLicence()
		Return Self.GetRandomMovieLicence()
	End Method


	Method GetRandomMovieLicence:TProgrammeLicence() {_exposeToLua}
		if movieLicences.count() = 0 then return NULL
		Return TProgrammeLicence(movieLicences.ValueAtIndex(rand(0, movieLicences.count() - 1)))
	End Method


	Method GetRandomSerieLicence:TProgrammeLicence() {_exposeToLua}
		if seriesLicences.count() = 0 then return NULL
		Return TProgrammeLicence(seriesLicences.ValueAtIndex(rand(0, seriesLicences.count() - 1)))
	End Method


	Method GetRandomAdContract:TAdContract() {_exposeToLua}
		Return TAdContract(adContracts.ValueAtIndex(rand(0, adContracts.count() - 1)))
	End Method


	'get programmeLicence by index number in list - useful for lua-scripts
	Method GetProgrammeLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0) {_exposeToLua}
		Return TProgrammeLicence(programmeLicences.ValueAtIndex(arrayIndex))
	End Method


	'get movie licence by index number in list - useful for lua-scripts
	Method GetMovieLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0) {_exposeToLua}
		Return TProgrammeLicence(movieLicences.ValueAtIndex(arrayIndex))
	End Method


	'get series by index number in list - useful for lua-scripts
	Method GetSeriesLicenceAtIndex:TProgrammeLicence(arrayIndex:Int=0) {_exposeToLua}
		Return TProgrammeLicence(seriesLicences.ValueAtIndex(arrayIndex))
	End Method


	'get contract by index number in list - useful for lua-scripts
	Method GetAdContractAtIndex:TAdContract(arrayIndex:Int=0) {_exposeToLua}
		Return TAdContract(adContracts.ValueAtIndex(arrayIndex))
	End Method


	Method GetProgrammeGenreCount:int(genre:int, includeMovies:int=TRUE, includeSeries:int=TRUE) {_exposeToLua}
		local amount:int = 0
		if includeMovies
			For local licence:TProgrammeLicence = eachin movieLicences
				if licence.GetGenre() = genre then amount:+1
			Next
		endif
		if includeSeries
			For local licence:TProgrammeLicence = eachin seriesLicences
				if licence.GetGenre() = genre then amount:+1
			Next
		endif
		return amount
	End Method


	Method HasProgrammeLicence:int(licence:TProgrammeLicence) {_exposeToLua}
		if licence.isEpisode()
			return programmeLicences.contains(licence.parentLicence)
		else
			return programmeLicences.contains(licence)
		endif
	End Method


	Method HasAdContract:int(Contract:TAdContract) {_exposeToLua}
		return adContracts.contains(contract)
	End Method


	Method HasNews:int(newsObject:TNews) {_exposeToLua}
		return news.contains(newsObject)
	End Method


	Method GetProgrammeLicence:TProgrammeLicence(id:Int) {_exposeToLua}
		For Local licence:TProgrammeLicence = EachIn programmeLicences
			If licence.id = id Then Return licence
		Next
		Return Null
	End Method


	Method GetAdContract:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn adContracts
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method GetAdContractByBase:TAdContract(id:Int) {_exposeToLua}
		For Local contract:TAdContract=EachIn adContracts
			If contract.base.id = id Then Return contract
		Next
		Return Null
	End Method


	Method GetMovieLicences:Object[]() {_exposeToLua}
		Return movieLicences.toArray()
	End Method


	Method GetSeriesLicences:Object[]() {_exposeToLua}
		Return seriesLicences.toArray()
	End Method


	Method GetProgrammeLicences:Object[]() {_exposeToLua}
		Return programmeLicences.toArray()
	End Method


	Method GetAdContracts:Object[]() {_exposeToLua}
		Return adContracts.toArray()
	End Method


	'returns the amount of news currently available
	Method GetNewsCount:Int() {_exposeToLua}
		Return news.count()
	End Method


	'returns the block with the given id
	Method GetNews:TNews(id:Int) {_exposeToLua}
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

		if fireEvents then EventManager.registerEvent(TEventSimple.Create("programmecollection.addNews", new TData, newsObject))

		return TRUE
	End Method


	Method RemoveNews:int(newsObject:TNews) {_exposeToLua}
		'remove from list
		if news.remove(newsObject)
			'run cleanup
			newsObject.Remove()

			'emit an event so eg. network can recognize the change
			if fireEvents then EventManager.registerEvent( TEventSimple.Create( "programmecollection.removeNews", new TData, newsObject ) )
			return TRUE
		endif
		return FALSE
	End Method
End Type