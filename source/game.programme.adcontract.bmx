Rem
	====================================================================
	AdContract data - contracts of broadcastable advertisements
	====================================================================

	The normal contract data is splitted into "contractBase" and
	"contract". So the resulting contract can differ to the raw database
	contract (eg. discounts, special prices...). Also you can have the
	same contract data with different ids ... so multiple incarnations
	of a contract are possible.
EndRem
SuperStrict
'to be able to evaluate scripts
Import "Dig/base.util.scriptexpression.bmx"
Import "game.world.worldtime.bmx"
'to fetch maximum audience
Import "game.stationmap.bmx"
Import "game.publicimage.bmx"
'to access gamerules (definitions)
Import "game.gamerules.bmx"
'to access genres
Import "game.gameconstants.bmx"
'to access player id
Import "game.player.base.bmx"
'to access datasheet-functions
Import "common.misc.datasheet.bmx"

Import "game.broadcastmaterialsource.base.bmx"

'to access programmeplanner information
Import "game.gameinformation.bmx"




Type TAdContractBaseCollection
	Field entries:TMap = CreateMap()
	Field entriesCount:int = -1

	'factor by what an infomercial topicality DECREASES by sending it
	Field infomercialWearoffFactor:float = 1.25
	'factor by what an infomercial topicality INCREASES on a new day
	Field infomercialRefreshFactor:float = 1.3

	Global _instance:TAdContractBaseCollection


	Function GetInstance:TAdContractBaseCollection()
		if not _instance then _instance = new TAdContractBaseCollection
		return _instance
	End Function


	Method Initialize()
		entries.clear()
		entriesCount = -1
	End Method


	Method GetByGUID:TAdContractBase(GUID:String)
		Return TAdContractBase(entries.ValueForKey(GUID))
	End Method


	Method SearchByPartialGUID:TAdContractBase(GUID:String)
		'skip searching if there is nothing to search
		if GUID.trim() = "" then return Null

		GUID = GUID.ToLower()

		'find first hit
		For local ad:TAdContractBase = EachIn entries.Values()
			if ad.GetGUID().ToLower().Find(GUID) >= 0
				return ad
			endif
		Next

		return Null
	End Method


	'this is not guaranteed to be unique!
	Method GetByTitle:TAdContractBase(title:String, language:String="")
		For Local base:TAdContractBase = EachIn entries.Values()
			If base.title.Get(language) = title Then Return base
		Next
		Return Null
	End Method


	Method Get:TAdContractBase(id:Int)
		For Local base:TAdContractBase = EachIn entries.Values()
			If base.id = id Then Return base
		Next
		Return Null
	End Method


	Method GetCount:Int()
		if entriesCount >= 0 then return entriesCount

		entriesCount = 0
		For Local base:TAdContractBase = EachIn entries.Values()
			entriesCount :+1
		Next
		return entriesCount
	End Method


	Method GetRandom:TAdContractBase(array:TAdContractBase[] = null)
		if array = Null or array.length = 0 then array = GetAllAsArray()
		If array.length = 0 Then Return Null
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetRandomNormalByFilter:TAdContractBase(filter:TAdContractBaseFilter, returnUnfilteredOnError:int = True)
		Local contracts:TAdContractBase[]

		For local contract:TAdContractBase = EachIn entries.Values()
			if contract.adType <> TVTAdContractType.NORMAL then continue
			if not filter.DoesFilter(contract) then continue

			'add it to candidates list
			contracts :+ [contract]
		Next

		if contracts.length = 0
			if returnUnfilteredOnError
				print "AdContractBaseCollection: GetRandomNormalByFilter without results! Returning Random without filter."
			else
				'no need to debug print something - as the param is
				'manually set to false...
				'print "AdContractBaseCollection: GetRandomNormalByFilter without results! Returning NULL."
				Return null
			endif
		endif

		Return GetRandom(contracts)
	End Method


	Method GetRandomByFilter:TAdContractBase(filter:TAdContractBaseFilter, returnUnfilteredOnError:int = True)
		Local contracts:TAdContractBase[]

		For local contract:TAdContractBase = EachIn entries.Values()
			if not filter.DoesFilter(contract) then continue

			'add it to candidates list
			contracts :+ [contract]
		Next

		if contracts.length = 0
			if returnUnfilteredOnError
				print "AdContractBaseCollection: GetRandomByFilter without results! Returning Random without filter."
			else
				'no need to debug print something - as the param is
				'manually set to false...
				'print "AdContractBaseCollection: GetRandomByFilter without results! Returning NULL."
				Return null
			endif
		endif

		Return GetRandom(contracts)
	End Method


	Method GetAllAsArray:TAdContractBase[]()
		local array:TAdContractBase[]
		'create a full array containing all elements
		For local obj:TAdContractBase = EachIn entries.Values()
			array :+ [obj]
		Next
		return array
	End Method


	Method Remove:int(obj:TAdContractBase)
		if obj.GetGuid() and entries.Remove(obj.GetGUID())
			'invalidate count
			entriesCount = -1

			return True
		endif

		return False
	End Method


	Method Add:int(obj:TAdContractBase)
		entries.Insert(obj.GetGUID(), obj)
		'invalidate count
		entriesCount = -1

		return True
	End Method


	Method RefreshInfomercialTopicalities:int() {_private}
		For Local base:TAdContractBase = eachin entries.Values()
			base.RefreshInfomercialTopicality()
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractBaseCollection:TAdContractBaseCollection()
	Return TAdContractBaseCollection.GetInstance()
End Function




Type TAdContractCollection
	Field list:TList = CreateList()
	Global _instance:TAdContractCollection


	Function GetInstance:TAdContractCollection()
		if not _instance then _instance = new TAdContractCollection
		return _instance
	End Function


	Method Initialize()
		list.clear()
	End Method


	Method Get:TAdContract(id:Int)
		For Local contract:TAdContract = EachIn list
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method GetByGUID:TAdContract(guid:String)
		For Local contract:TAdContract = EachIn list
			If contract.GetGUID() = guid Then Return contract
		Next
		Return Null
	End Method


	Method Remove:int(obj:TAdContract)
		return list.Remove(obj)
	End Method


	Method Add:int(obj:TAdContract)
		'only add once
		if list.contains(obj) then return False

		list.AddLast(obj)
		return TRUE
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractCollection:TAdContractCollection()
	Return TAdContractCollection.GetInstance()
End Function





'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase extends TBroadcastMaterialSource {_exposeToLua}
	'days to fullfill a (signed) contract
	Field daysToFinish:Int = 0
	'spots to send
	Field spotCount:Int = 1
	'block length
	Field blocks:int = 1
	'target group of the spot
	Field limitedToTargetGroup:Int = -1
	'is the ad broadcasting limit to a specific programme type?
	'eg. "series", "movies"
	Field limitedToProgrammeType:Int = -1
	'is the ad broadcasting limit to a specific programme genre?
	'eg. only "lovestory"
	Field limitedToProgrammeGenre:Int = -1
	'is the ad broadcasting limit to a specific programme flag?
	'eg. "xrated", "live"
	Field limitedToProgrammeFlag:Int = -1
	'is the ad broadcasting not allowed for a specific programme genre?
	'eg. no "lovestory"
	Field forbiddenProgrammeGenre:Int = -1
	'is the ad broadcasting not allowed for a specific programme type?
	'eg. no "series"
	Field forbiddenProgrammeType:Int = -1
	'is the ad broadcasting not allowed for a specific programme flag?
	'eg. no "paid"
	Field forbiddenProgrammeFlag:Int = -1

	'is the ad broadcasting limit to a specific broadcast type?
	'Field limitedToBroadcastType:Int = -1

	'are there a interest groups liking/hating broadcasts of this?
	'eg. anti-nicotin
	Field proPressureGroups:Int = 0
	Field contraPressureGroups:Int = 0

	'minimum audience (real value calculated on sign)
	Field minAudienceBase:Float
	'minimum image base value (real value calculated on sign)
	Field minImage:Float
	'flag wether price is fixed or not
	Field fixedPrice:Int = False
	'base of profit (real value calculated on sign)
	Field profitBase:Float
	'base of penalty (real value calculated on sign)
	Field penaltyBase:Float
	'the quality of the advertisement (cheap one or hollywood style?)
	'also might affect infomercial audience rating
	Field quality:Float = 0.10 'default is 10%
	'=== infomercials / shopping shows ===
	'is the broadcast of an infomercial allowed?
	Field infomercialAllowed:int = TRUE
	'topicality for this contract base (all adcontracts of this base
	'share this topicality !)
	Field infomercialTopicality:float = 1.0
	Field infomercialMaxTopicality:float = 1.0
	Field infomercialProfitBase:int = 0
	'keep the profit the same for all audience requirements
	Field fixedInfomercialProfit:int = True
	'if set, this defines a range in which the advertisement can come up
	Field availableYearRangeFrom:int = -1
	Field availableYearRangeTo:int = -1

	'special expression defining whether a contract is available for
	'ad vendor or not (eg. "YEAR > 2000" or "YEARSPLAYED > 2")
	Field availableScript:string = ""

	'defines the type of the ad according to TVTAdContractType
	'only adType 0 is generically available in the game
	Field adType:int = 0

	'array of contract guids using this base at the moment
	Field currentlyUsedByContracts:string[]

	'TODO: store in BroadcastInformationProvider
	Field timesBroadcastedAsInfomercial:int[] = [0]
	Field _handledFirstTimeBroadcast:int = False
	Field _handledFirstTimeBroadcastAsInfomercial:int = False

	rem
		modifiers:
		"topicality:infomercialWearoff"
		  changes how much an infomercial loses topicality during sending it
		"topicality:infomercialRefresh"
		  changes how much an infomercial "regenerates" on topicality per day
	endrem


	Method GenerateGUID:string()
		return "broadcastmaterialsource-adcontractbase-"+id
	End Method


	Method Create:TAdContractBase(GUID:String, title:TLocalizedString, description:TLocalizedString, daysToFinish:Int, spotCount:Int, targetgroup:Int, minAudience:Float, minImage:Float, fixedPrice:Int, profit:Float, penalty:Float)
		self.SetGUID(GUID)
		self.title = title
		self.description = description
		self.daysToFinish = daysToFinish
		self.spotCount = spotCount
		self.limitedToTargetGroup = targetGroup
		self.minAudienceBase = minAudience
		self.minImage = minImage
		self.fixedPrice = fixedPrice
		self.profitBase	= profit
		self.penaltyBase = penalty

		GetAdContractBaseCollection().Add(self)

		Return self
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local a1:TAdContractBase = TAdContractBase(o1)
		Local a2:TAdContractBase = TAdContractBase(o2)
		If Not a2 Then Return 1

		if a1.GetTitle().ToLower() = a2.GetTitle().ToLower()
			return a1.minAudienceBase > a2.minAudienceBase
		elseif a1.GetTitle().ToLower() > a2.GetTitle().ToLower()
			return 1
		endif
		return -1
	End Function


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(value:Float = -1)
		If value < 0 Then value = minAudienceBase

		'modify according to dev-balancing
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		if devConfig
			value :* devConfig.GetFloat("DEV_ADCONTRACT_MINAUDIENCEPERCENTAGE_MOD", 1.0)
		endif

		Return MathHelper.Clamp(value, 0.0, 1.0)
	End Method


	'returns the non rounded minimum audience
	'@playerID          playerID = -1 to use the avg audience maximum
	'@getTotalAudience  avoid breaking down audience if a target group limit is set up
	Method GetRawMinAudienceForPlayer:Int(playerID:int, getTotalAudience:int = False, audience:int=-1)
		local useAudience:int = audience
		if audience < 0
			if playerID <= 0
				useAudience = GetStationMapCollection().GetAverageReach()
			else
				useAudience = GetStationMap(playerID).GetReach()
			endif
		endif

		if not getTotalAudience
			'if limited to specific target group ... break audience down
			'to this specific group
			if GetLimitedToTargetGroup() > 0
				useAudience :* AudienceManager.GetTargetGroupPercentage(GetLimitedToTargetGroup())
			endif
		endif

		local result:int = GetMinAudiencePercentage() * useAudience

		'DEV: adjust by a balancing factor
		result :* GameRules.devConfig.GetFloat("DEV_ADCONTRACT_RAWMINAUDIENCE_MOD", 1.0)

		Return result
	End Method


	'Gets minimum needed audience in absolute numbers
	Method GetMinAudienceForPlayer:Int(playerID:int, getTotalAudience:int = False, audience:int=-1)
		Return TFunctions.RoundToBeautifulValue( GetRawMinAudienceForPlayer(playerID, getTotalAudience, audience) )
	End Method


	Method IsAvailable:int()
		'field "available" = false ?
		if not super.IsAvailable() then return False

		'skip contracts not available in this game year
		if availableYearRangeFrom > 0 and GetWorldTime().GetYear() < availableYearRangeFrom then return False
		if availableYearRangeTo > 0 and GetWorldTime().GetYear() > availableYearRangeTo then return False

		'a special script expression defines custom rules for adcontracts
		'to be available or not
		if availableScript and not GetScriptExpression().Eval(availableScript)
			return False
		endif

		return True
	End Method


	'playerID < 0 means "get all"
	Method GetTimesBroadcastedAsInfomercial:Int(playerID:int = -1)
		if playerID >= timesBroadcastedAsInfomercial.length then Return 0
		if playerID >= 0 then Return timesBroadcastedAsInfomercial[playerID]

		local result:int = 0
		For local i:int = 0 until timesBroadcastedAsInfomercial.length
			result :+ timesBroadcastedAsInfomercial[i]
		Next
		Return result
	End Method


	Method SetTimesBroadcastedAsInfomercial:Int(times:int, playerID:int)
		if playerID < 0 then playerID = 0

		'resize array if player has no entry yet
		if playerID >= timesBroadcastedAsInfomercial.length
			timesBroadcastedAsInfomercial = timesBroadcastedAsInfomercial[.. playerID + 1]
		endif

		timesBroadcastedAsInfomercial[playerID] = times
	End Method


	Method GetBlocks:int() {_exposeToLua}
		return blocks
	End Method


	Method GetQuality:Float() {_exposeToLua}
		return quality
	End Method


	'when used as programme
	Method GetProgrammeTopicality:Float() {_exposeToLua}
		return GetInfomercialTopicality()
	End Method


	Method GetInfomercialTopicality:Float() {_exposeToLua}
		return infomercialTopicality
	End Method


	Method GetMaxInfomercialTopicality:Float() {_exposeToLua}
		return infomercialMaxTopicality
	End Method


	Method GetInfomercialRefreshModifier:float()
		return GetModifier("topicality::infomercialRefresh")
	End Method


	Method GetInfomercialWearoffModifier:float()
		return GetModifier("topicality::infomercialWearoff")
	End Method


	Method CutInfomercialTopicality:Int(cutModifier:float=1.0) {_private}
		'for the calculation we need to know what to cut, not what to keep
		local toCut:Float =  (1.0 - cutModifier)
		local minimumRelativeCut:Float = 0.10 '10%
		local minimumAbsoluteCut:Float = 0.10 '10%

		'calculate base value (if mod was "1.0" or 100%)
		toCut :* GetAdContractBaseCollection().infomercialWearoffFactor

		'cutModifier can be used to manipulate the resulting cut
		'ex. for night times, for low audience...
		toCut :* GetInfomercialWearoffModifier()

		toCut = Max(toCut, minimumRelativeCut)

		'take care of minimumCut and switch back to "what to cut"
		cutModifier = 1.0 - MathHelper.Clamp(toCut, minimumAbsoluteCut, 1.0)

		infomercialTopicality = MathHelper.Clamp(infomercialTopicality * cutModifier, 0.0, GetMaxInfomercialTopicality())

		Return infomercialTopicality
	End Method


	Method RefreshInfomercialTopicality:Int(refreshModifier:float=1.0) {_private}
		local minimumRelativeRefresh:Float = 1.10 '110%
		local minimumAbsoluteRefresh:Float = 0.10 '10%

		refreshModifier :* GetAdContractBaseCollection().infomercialRefreshFactor
		refreshModifier :* GetInfomercialRefreshModifier()

		refreshModifier = Max(refreshModifier, minimumRelativeRefresh)

		infomercialTopicality :+ Max(infomercialTopicality * (refreshModifier-1.0), minimumAbsoluteRefresh)
		infomercialTopicality = MathHelper.Clamp(infomercialTopicality, 0, GetMaxInfomercialTopicality())

		Return infomercialTopicality
	End Method


	Method GetLimitedToProgrammeGenre:int() {_exposeToLua}
		Return limitedToProgrammeGenre
	End Method


	Method IsLimitedToTargetGroup:int(targetGroup:int) {_exposeToLua}
		Return (GetLimitedToTargetGroup() & targetGroup) > 0
	End Method


	Method GetLimitedToTargetGroup:int() {_exposeToLua}
		'with no required audience, we cannot limit to target groups
		'except hmm ... we want that at least 1 of the target group
		'is watching
		if GetMinAudiencePercentage() = 0 then return 0

		Return Max(0, limitedToTargetGroup)
	End Method


	Method SetLimitedToTargetGroup:int(group:int, enable:int=True)
		If enable
			limitedToTargetGroup = GetLimitedToTargetGroup() | group
		Else
			limitedToTargetGroup = GetLimitedToTargetGroup() & ~group
		EndIf
	End Method


	Method GetProPressureGroups:int()
		return Max(0, proPressureGroups)
	End Method


	Method HasProPressureGroup:Int(group:Int) {_exposeToLua}
		Return (GetProPressureGroups() & group) > 0
	End Method


	Method SetProPressureGroup:int(group:int, enable:int=True)
		If enable
			proPressureGroups = GetProPressureGroups() | group
		Else
			proPressureGroups = GetProPressureGroups() & ~group
		EndIf
	End Method


	Method GetContraPressureGroups:int()
		return Max(0, contraPressureGroups)
	End Method


	Method HasContraPressureGroup:Int(group:Int) {_exposeToLua}
		Return (GetContraPressureGroups() & group) > 0
	End Method


	Method SetContraPressureGroup:int(group:int, enable:int=True)
		If enable
			contraPressureGroups = GetContraPressureGroups() | group
		Else
			contraPressureGroups = GetContraPressureGroups() & ~group
		EndIf
	End Method


	Method IsCurrentlyUsedByContract:int(contractGUID:string)
		For local guid:string = EachIn currentlyUsedByContracts
			if guid = contractGUID then return True
		Next
		return False
	End Method


	Method AddCurrentlyUsedByContract:int(contractGUID:string)
		'skip if already used
		if IsCurrentlyUsedByContract(contractGUID) then return False

		currentlyUsedByContracts :+ [contractGUID]

		return True
	End Method


	Method RemoveCurrentlyUsedByContract:int(contractGUID:string)
		'skip if already not existent
		if not IsCurrentlyUsedByContract(contractGUID) then return False

		local newArray:string[]
		For local guid:String = EachIn currentlyUsedByContracts
			if guid <> contractGUID then newArray :+ [contractGUID]
		Next
		currentlyUsedByContracts = newArray

		return True
	End Method


	Method GetCurrentlyUsedByContractCount:int()
		return currentlyUsedByContracts.length
	End Method
End Type




'the useable contract for advertisements used in the playercollections
Type TAdContract extends TBroadcastMaterialSource {_exposeToLua="selected"}
	'holds raw contract data
	Field base:TAdContractBase = Null
	'how many spots were successfully sent up to now
	Field spotsSent:Int = 0
	'how many spots were planned up to now
	Field spotsPlanned:Int = 0
	'day the contract has been taken from the advertiser-room
	Field daySigned:Int = -1
	'calculated profit value (on sign)
	Field profit:Int = -1
	'calculated penalty value (on sign)
	Field penalty:Int = -1
	'calculated infomercial profit value (on sign)
	Field infomercialProfit:Int = -1
	'calculated minimum audience value (on sign)
	Field minAudience:Int = -1
	'calculated minimum total audience value (on sign)
	Field totalMinAudience:Int = -1
	' KI: Wird nur in der Lua-KI verwendet du die Filme zu bewerten
	Field attractiveness:Float = -1
	'the classification of this contract
	' -1 = cheap filter list
	' 0,1 - lowest daytime + primetime
	' 2,3 - avg daytime + primetime
	' 4,5 - best daytime + primetime
	Field adAgencyClassification:int = 0

	'for statistics
	Field stateTime:Long = -1
	Field state:int = 0


	Const PRICETYPE_PROFIT:int = 1
	Const PRICETYPE_PENALTY:int = 2
	Const PRICETYPE_INFOMERCIALPROFIT:int = 3
	'same as in TBroadcastMaterialBase
	Const STATE_OK:int = 1
	Const STATE_FAILED:int = 2


	Method GenerateGUID:string()
		return "broadcastmaterialsource-adcontract-"+id
	End Method


	'create UNSIGNED (adagency)
	Method Create:TAdContract(baseContract:TAdContractBase)
		SetBase(baseContract)

		GetAdContractCollection().Add(self)
		Return self
	End Method


	Method SetBase(baseContract:TAdContractBase)
		'decrease used counter if needed
		if self.base then self.base.RemoveCurrentlyUsedByContract( GetGUID() )
		'increase used counter of new contract
		if baseContract then baseContract.AddCurrentlyUsedByContract( GetGUID() )

		self.base = baseContract
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1

		if a1.GetTitle().ToLower() = a2.GetTitle().ToLower()
			return a1.base.minAudienceBase > a2.base.minAudienceBase
		elseif a1.GetTitle().ToLower() > a2.GetTitle().ToLower()
			return 1
		endif
		return -1
	End Function


	Function SortByClassification:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1
		if a1.adAgencyClassification = a2.adAgencyClassification
			return a1.GetTitle() > a2.GetTitle()
		endif
        Return a1.adAgencyClassification - a2.adAgencyClassification
	End Function


	Function SortByProfit:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1
		if a1.GetProfit() = a2.GetProfit()
			return a1.GetTitle() > a2.GetTitle()
		endif
        Return a1.GetProfit() - a2.GetProfit()
	End Function


	'sort by _absolute_ minAudience. So 60.000 "men" is < 90.000 "all"
	Function SortByMinAudience:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1

		if a1.GetMinAudience() = a2.GetMinAudience()
			return a1.GetTitle() > a2.GetTitle()
		endif
        Return a1.GetMinAudience() - a2.GetMinAudience()
	End Function


	'sort by _absolute_ minAudience. So 60.000 "men" is > 90.000 "all" (50% men of 90.000 = 45.000)
	Function SortByMinAudienceRelative:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1

		'calculate the value as if population consists only of the targetgroup
		local relativeAudience1:int = a1.GetMinAudience()/AudienceManager.GetTargetGroupPercentage(a1.GetLimitedToTargetGroup())
		local relativeAudience2:int = a2.GetMinAudience()/AudienceManager.GetTargetGroupPercentage(a2.GetLimitedToTargetGroup())

		if relativeAudience1 = relativeAudience2
			return a1.GetTitle() > a2.GetTitle()
		endif
        Return relativeAudience1 - relativeAudience2
	End Function


	Function SortByDaysLeft:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1

		if a1.GetDaysLeft() = a2.GetDaysLeft()
			return a1.GetTitle() > a2.GetTitle()
		endif
        Return a1.GetDaysLeft() - a2.GetDaysLeft()
	End Function


	Function SortBySpotsToSend:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a2 Then Return 1

		if a1.GetSpotsSent() = a2.GetSpotsSent()
			return a1.GetTitle() > a2.GetTitle()
		endif
        Return a1.GetSpotsToSend() - a2.GetSpotsToSend()
	End Function


	Method SetSpotsSent:int(value:int)
		if spotsSent = value then return False

		spotsSent = value
		'emit an event so eg. ContractList-caches can get recreated
		EventManager.triggerEvent(TEventSimple.Create("adContract.onSetSpotsSent", null, Self))

		return True
	End Method


	Method GetPerViewerRevenueForPlayer:Float(playerID:int)
		if not IsInfomercialAllowed() then return 0.0

		local result:float = 0.0

		'calculate
		result = GetInfomercialProfitForPlayer(playerID)
		'cut down to the price of 1 viewer (assume a CPM price)
		result :* 0.001

		'less revenue with less topicality
		'by default think of no topicality at
		local topicalityDecrease:Float = 1.0
		if base.GetMaxInfomercialTopicality() > 0
			topicalityDecrease = 1.0 - (base.infomercialTopicality / base.GetMaxInfomercialTopicality())
		endif
		'cut by maximum 90%
		result :* (0.1 + 0.9 * (1.0 - topicalityDecrease))

		return result
	End Method


	'what to earn each hour for each viewer
	'(broadcasted as "infomercial")
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		return GetPerViewerRevenueForPlayer(owner)
	End Method


	'overwrite method from base
	Method GetTitle:string() {_exposeToLua}
		if not title and base then return base.GetTitle()

		return Super.GetTitle()
	End Method


	'overwrite method from base
	Method GetDescription:string() {_exposeToLua}
		if not description and base then return base.GetDescription()

		return Super.GetDescription()
	End Method


	'overwrite method from base
	Method GetBlocks:int() {_exposeToLua}
		Return base.GetBlocks()
	End Method


	'sign the contract -> calculate values and change owner
	Method Sign:int(owner:int, day:int=-1, skipChecks:int = False)
		if self.owner = owner then return FALSE

		if not skipChecks
			'run checks if sign is allowed
			if not IsAvailableToSign(owner) then return FALSE
		endif

		self.owner = owner
		self.profit	= GetProfitForPlayer(owner, True)
		self.penalty = GetPenaltyForPlayer(owner, True)
		self.infomercialProfit = GetInfomercialProfitForPlayer(owner, True)
		self.minAudience = GetMinAudienceForPlayer(owner, True)
		self.totalMinAudience = GetTotalMinAudienceForPlayer(owner, True)

		If day < 0 Then day = GetWorldTime().GetDay()
		self.daySigned = day

		'TLogger.log("TAdContract.Sign", "Player "+owner+" signed a contract.  Profit: "+profit+",  Penalty: "+penalty+ ",  MinAudience: "+minAudience+",  Title: "+GetTitle(), LOG_DEBUG)
		return TRUE
	End Method


	'returns whether a contract could get signed
	'ATTENTION: AI could use this to check if a player is able to
	'sign this (fulfills certain maybe not visible factors).
	'so it exposes some kind of information
	Method IsAvailableToSign:Int(playerID:int) {_exposeToLua}
		'not enough channel image?
		if GetMinImage() > 0 and 0.01*GetPublicImageCollection().Get(playerID).GetAverageImage() < GetMinImage() then return False

		Return (not IsSigned())
	End Method


	'override
	Method IsAvailable:int() {_exposeToLua}
		'once we created a contract out of the base, the base availability
		'should no longer matter
		'- eg. gamestart-advertisement
		'- adcontracts are available from 1985-1986, if checking their
		'  availability after signing in 1986 will result in FALSE in
		'  begin of 1987 while it should be broadcastable then
		'if not base.IsAvailable() then return False

		return Super.IsAvailable()
	End Method


	Method IsSigned:int() {_exposeToLua}
		return (owner > 0 and daySigned >= 0)
	End Method


	Method IsCompleted:int()
		return state = STATE_OK
	End Method


	Method IsFailed:int()
		return state = STATE_FAILED
	End Method


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(dbvalue:Float = -1) {_exposeToLua}
		return base.GetMinAudiencePercentage(dbvalue)
	End Method


	'the quality is higher for "better paid" advertisements with
	'higher audience requirements... no cheap "car seller" ad :D
	Method GetRawQualityForPlayer:Float(playerID:int) {_exposeToLua}
		Local quality:Float = 0.05

		local minA:int = GetMinAudienceForPlayer(playerID, False)
		'TODO: switch to Percentages + modifiers for TargetGroup-Limits
		if minA >   1000 then quality :+ 0.01		'+0.06
		if minA >   5000 then quality :+ 0.025		'+0.085
		if minA >  10000 then quality :+ 0.05		'+0.135
		if minA >  50000 then quality :+ 0.075		'+0.21
		if minA > 250000 then quality :+ 0.1		'+0.31
		if minA > 750000 then quality :+ 0.19		'+0.5
		if minA >1500000 then quality :+ 0.25		'+0.75
		if minA >5000000 then quality :+ 0.25		'+1.00

		'a portion of the resulting quality is based on the "better"
		'advertisements (minAudience and minImage)
		quality = 0.70 * base.GetQuality() + 0.15 * quality + 0.15 * GetMinImage()

		'modify according to dev-balancing
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		if devConfig
			quality :* devConfig.GetFloat("DEV_ADCONTRACT_RAWQUALITY_MOD", 1.0)
		endif

		Return MathHelper.Clamp(quality, 0.01, 1.0)
	End Method


	Method GetRawQuality:Float() {_exposeToLua}
		Return GetRawQualityForPlayer(owner)
	End Method


	Method GetQualityForPlayer:Float(playerID:int)
		local quality:Float = GetRawQualityForPlayer(playerID)

		'the more the infomercial got repeated, the lower the quality in
		'that moment (^2 increases loss per air)
		'but a "good" infomercial should benefit from being good - so the
		'influence of repetitions gets lower by higher raw quality
		'-> an infomercial with 100% base quality will have at least 25%
		'   of quality no matter how many times it got aired
		'-> infomercials with 0% base quality will cut to up to 75% of
		'   that - resulting in <= 25% quality
		quality :* (0.25 + 0.75 * base.GetInfomercialTopicality() ^ 2)

		'at least 1% quality
		Return MathHelper.Clamp(quality, 0.01, 1.0)
	End Method


	Method GetQuality:Float() {_exposeToLua}
		return GetQualityForPlayer(owner)
	End Method


	Method IsInfomercialAllowed:int() {_exposeToLua}
		return base.infomercialAllowed
	End Method


	Method Remove()
		'set contract base unused
		base.RemoveCurrentlyUsedByContract( GetGUID() )
	End Method


	'call this to set the contract failed (and pay a penalty)
	Method Fail:int(time:Double=0)
		'send out event for potential listeners (eg. ingame notification)
		EventManager.triggerEvent(TEventSimple.Create("adContract.onFail", New TData.addNumber("time", time), Self))

		'pay penalty
		GetPlayerFinance(owner, GetWorldTime().GetDay(time)).PayPenalty(GetPenalty(), self)

		'store for statistics
		stateTime = time
		state = STATE_FAILED

		'clean up (eg. decrease usage counter)
		Remove()
	End Method


	'call this to set the contract successful and finished (and earn profit)
	Method Finish:int(time:Double=0)
		'if state = STATE_OK then Throw "Double Finish !!"
		if not state = STATE_OK
			'send out event for potential listeners (eg. ingame notification)
			EventManager.triggerEvent(TEventSimple.Create("adContract.onFinish", New TData.addNumber("time", time), Self))

			'give money
			GetPlayerFinance(owner, GetWorldTime().GetDay(time)).EarnAdProfit(GetProfit(), self)

			'store for statistics
			stateTime = time
			state = STATE_OK
		endif

		'clean up (eg. decrease usage counter)
		Remove()
	End Method


	'if targetgroup is set, the price is doubled
	Method GetProfitForPlayer:Int(playerID:Int, invalidateCache:int = False)
		'already calculated and data for owner requested
		If not invalidateCache
			if owner > 0 and owner = playerID and profit >= 0 Then Return profit
		EndIf

		local result:int = CalculatePricesForPlayer(base.profitBase, playerID, PRICETYPE_PROFIT) * GetSpotCount()

		'DEV: adjust by a balancing factor
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		if devConfig
			result :* GameRules.devConfig.GetFloat("DEV_ADCONTRACT_PROFIT_MOD", 1.0)
		endif

		return result
	End Method


	'if targetgroup is set, the price is doubled
	Method GetProfit:Int(playerID:Int=-1) {_exposeToLua}
		if playerID < 0 then playerID = owner
		return GetProfitForPlayer(playerID, False)
	End Method


	Method GetInfomercialProfitForPlayer:Int(playerID:Int, invalidateCache:int = False)
		'already calculated and data for owner requested
		If not invalidateCache
			If owner > 0 and owner = playerID and infomercialProfit >= 0 Then Return infomercialProfit
		EndIf

		local result:float
		'return fixed or calculated profit
		if base.fixedInfomercialProfit
			result = base.infomercialProfitBase
		else
			result = CalculatePricesForPlayer(base.infomercialProfitBase, playerID, PRICETYPE_INFOMERCIALPROFIT)
		endif

		'DEV:
		'by which factor do we cut the profit when send as infomercial
		'compared to the profit a single ad would generate
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		if devConfig
			result :* GameRules.devConfig.GetFloat("DEV_ADCONTRACT_INFOMERCIAL_PROFIT_MOD", 1.0)
		endif

		return result
	End Method


	Method GetInfomercialProfit:Int(playerID:Int=-1) {_exposeToLua}
		if playerID < 0 then playerID = owner
		return GetInfomercialProfitForPlayer(playerID, False)
	End Method


	'returns the penalty for this contract
	Method GetPenaltyForPlayer:Int(playerID:Int, invalidateCache:int = False)
		'already calculated and data for owner requested
		If not invalidateCache
			If owner > 0 and owner = playerID and penalty >= 0 Then Return penalty
		EndIf

		local result:int = CalculatePricesForPlayer(base.penaltyBase, playerID, PRICETYPE_PENALTY) * GetSpotCount()

		'DEV: adjust by a balancing factor
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		if devConfig
			result :* GameRules.devConfig.GetFloat("DEV_ADCONTRACT_PENALTY_MOD", 1.0)
		endif

		return result
	End Method


	'returns the penalty for this contract
	Method GetPenalty:Int(playerID:Int=-1) {_exposeToLua}
		if playerID < 0 then playerID = owner
		Return GetPenaltyForPlayer(playerID, False)
	End Method


	Function GetCPM:Double(baseCPM:Double, maxCPM:Double, influence:float)
		'no money - ignore influence
		if baseCPM = 0 then return 0
		'lower cpm means it should not get influenced either
		if baseCPM < maxCPM then return baseCPM

		'at "strength" the logisticalInfluence_Euler changes growth direction
		'so we have to scale back the percentage
		local logisticInfluence:Float =	THelper.LogisticalInfluence_Euler(influence, 3)

		'at least return maxCPM
		return Max(maxCPM, maxCPM + (baseCPM - maxCPM)*(1.0-logisticInfluence))
	End Function


	'calculate prices (profits, penalties...)
	Method CalculatePricesForPlayer:Int(baseValue:Float=0, playerID:Int, priceType:int = 0)
		'=== FIXED PRICE ===
		'ad is with fixed price - only available without minimum restriction
		If base.fixedPrice
			'print self.base.title.Get() + " has fixed price : "+ int(baseValue * GetSpotCount()) + " base:"+int(baseprice) + " profitbase:"+base.profitBase +" penaltyBase:"+base.penaltyBase
			'basePrice is a precalculated value (eg. 1000 euro)
			Return baseValue * GetSpotCount()
		endif

		local population:int = GetStationMapCollection().GetPopulation()
		if population <= 1000
			print "StationMap Population too low: "+population
			population = 1000
		endif


		'=== DYNAMIC PRICE ===
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG", new TData))
		Local devPriceMod:float = devConfig.GetFloat("DEV_ADCONTRACT_PRICE_MOD", 1.0)
		Local limitedToGenreMultiplier:float = devConfig.GetFloat("DEV_ADCONTRACT_LIMITED_GENRE_MULTIPLIER", 1.5)
		Local limitedToProgrammeFlagMultiplier:float = devConfig.GetFloat("DEV_ADCONTRACT_LIMITED_PROGRAMME_FLAG_MULTIPLIER", 1.25)
		Local limitedToTargetGroupMultiplier:float = devConfig.GetFloat("DEV_ADCONTRACT_LIMITED_TARGETGROUP_MULTIPLIER", 1.0)

		local maxCPM:float = GameRules.adContractPricePerSpotMax / Max(1, (population/1000))
		Local price:Float

		local minAudience:int = GetTotalMinAudienceForPlayer(playerID)

'calculate a price/CPM using the "getCPM"-function
'use the already rounded minAudience to avoid a raw audience of
'"15100" which rounds later to 16000 but calculating the cpm-blocks
'leads to 15 instead of 16...
'ATTENTION: use getTotalMinAudience() to base CPM on the rounded
'           value IGNORING potential targetgroup limits. This
'           leads to some kind of "beautified" percentage value.
price = GetCPM(baseValue, maxCPM, minAudience / population)
'multiply by amount of "1000 viewers"-blocks (ignoring targetGroups)
price :* Max(1, minAudience/1000)
		'multiply by amount of "1000 viewers"-blocks (_not_ ignoring targetGroups)
		'price :* Max(1, getMinAudience(playerID)/1000)
		'value cannot be higher than "maxAdContractPricePerSpot"
		if GameRules.adContractPricePerSpotMax > 0
			price = Min(GameRules.adContractPricePerSpotMax, price )
		endif
		'adjust by a balancing factor
		price :* devPriceMod

		'specific targetgroups change price
		If GetLimitedToTargetGroup() > 0 Then price :* limitedToTargetGroupMultiplier
		'limiting to specific genres change the price too
		If GetLimitedToGenre() > 0 Then price :* limitedToGenreMultiplier
		'limiting to specific flags change the price too
		If GetLimitedToProgrammeFlag() > 0 Then price :* limitedToProgrammeFlagMultiplier

		'adjust by a player difficulty
		if priceType = PRICETYPE_PROFIT
			price :* GetPlayerDifficulty(string(playerID)).advertisementProfitMod
		endif

		'print GetTitle()+": minAud%="+GetMinAudiencePercentage() +"  price=" +price +"  rawAud="+getRawMinAudienceForPlayer(playerID) +"  targetGroup="+GetLimitedToTargetGroup()

		'return "beautiful" prices
		Return TFunctions.RoundToBeautifulValue(price)
	End Method


	'returns the non rounded minimum audience
	'@playerID          playerID = -1 to use the avg audience maximum
	'@getTotalAudience  avoid breaking down audience if a target group limit is set up
	Method GetRawMinAudienceForPlayer:Int(playerID:int, getTotalAudience:int = False, audience:int=-1)
		return base.GetRawMinAudienceForPlayer(playerID, getTotalAudience, audience)
	End Method


	Method GetRawMinAudience:Int(playerID:int=-1, getTotalAudience:int = False) {_exposeToLua}
		if playerID < 0 then playerID = owner
		Return GetRawMinAudienceForPlayer(playerID, getTotalAudience)
	End Method


	'Gets minimum needed audience in absolute numbers
	Method GetMinAudienceForPlayer:Int(playerID:int, invalidateCache:int = False)
		'skip calculation if already calculated
		If not invalidateCache
			If owner > 0 and playerId = owner and minAudience >=0 Then Return minAudience
		EndIf

		Return base.GetMinAudienceForPlayer(playerID)
	End Method


	Method GetMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		if playerID < 0 then playerID = owner
		return GetMinAudienceForPlayer(playerID)
	End Method


	'returns the non rounded minimum audience
	Method GetTotalRawMinAudienceForPlayer:Int(playerID:int)
		return GetRawMinAudienceForPlayer(playerID, True)
	End Method


	Method GetTotalRawMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		if playerID < 0 then playerID = owner
		return GetTotalRawMinAudienceForPlayer(playerID)
	End Method


	'Gets minimum needed audience in absolute numbers (ignoring
	'targetgroup limits)
	Method GetTotalMinAudienceForPlayer:Int(playerID:int, invalidateCache:int = False)
		'skip calculation if already calculated
		If not invalidateCache
			If owner > 0 and owner = playerID and totalMinAudience >=0 Then Return totalMinAudience
		EndIf

		Return TFunctions.RoundToBeautifulValue( GetTotalRawMinAudienceForPlayer(playerID) )
	End Method


	Method GetTotalMinAudience:Int(playerID:int=-1) {_exposeToLua}
		return GetTotalMinAudienceForPlayer(owner, False)
	End Method


	'days left for sending all contracts from today
	Method GetDaysLeft:Int(currentDay:int = -1) {_exposeToLua}
		if daySigned < 0
			return base.daysToFinish
		else
			if currentDay < 0 then currentDay = GetWorldTime().GetDay()
			Return ( base.daysToFinish - (currentDay - daySigned) )
		endif
	End Method


	Method GetEndTime:Long() {_exposeToLua}
		if daySigned < 0
			return GetWorldTime().MakeTime(0, GetWorldTime().GetDay() + base.daysToFinish + 1, 0,0)
		else
			return GetWorldTime().MakeTime(0, daySigned + base.daysToFinish + 1, 0,0)
		endif
	End Method


	Method GetStartTime:Long() {_exposeToLua}
		if daySigned < 0
			return GetWorldTime().GetTimeGone()
		else
			return GetWorldTime().MakeTime(0, daySigned, 0,0)
		endif
	End Method


	'time left for sending all contract-spots from now
	Method GetTimeLeft:Long(now:Long = -1) {_exposeToLua}
		if now < 0 then now = GetWorldTime().GetTimeGone()

		Return GetEndTime() - now
	End Method


	Method GetTimeGonePercentage:Float(now:Long = -1) {_exposeToLua}
		if daySigned < 0 then return 0.0
		return 1.0 - GetTimeLeft(now) / float(GetEndTime() - GetStartTime())
	End Method


	'get the contract (to access its ID or title by its GetXXX() )
	Method GetBase:TAdContractBase() {_exposeToLua}
		Return base
	End Method


	'returns whether the contract was fulfilled
	Method isSuccessful:int() {_exposeToLua}
		Return (base.spotCount <= spotsSent)
	End Method


	Method GetSpotsToSendPercentage:Float() {_exposeToLua}
		return GetSpotsToSend() / float(GetSpotCount())
	End Method


	'amount of spots still missing
	Method GetSpotsToSend:int() {_exposeToLua}
		Return (base.spotCount - spotsSent)
	End Method


	Method SetSpotsPlanned:int(value:int)
		spotsPlanned = value
	End Method


	'amount of spots planned (adjusted by programmeplanner)
	Method GetSpotsPlanned:int() {_exposeToLua}
		return spotsPlanned
	End Method


	'amount of spots which have already been successfully broadcasted
	Method GetSpotsSent:int() {_exposeToLua}
		Return spotsSent
	End Method


	'amount of total spots to send
	Method GetSpotCount:Int() {_exposeToLua}
		Return base.spotCount
	End Method


	'total days to send contract from date of sign
	Method GetDaysToFinish:Int() {_exposeToLua}
		Return base.daysToFinish
	End Method


	Method GetMinImage:Float() {_exposeToLua}
		Return base.minImage
	End Method


	Method IsLimitedToTargetGroup:int(targetGroup:int) {_exposeToLua}
		return base.IsLimitedtoTargetGroup(targetGroup)
	End Method

	Method GetLimitedToTargetGroup:Int() {_exposeToLua}
		return base.GetLimitedToTargetGroup()
	End Method


	Method GetLimitedToTargetGroupString:String(group:Int=-1) {_exposeToLua}
		'if no group given, use the one of the object
		if group < 0 then group = GetLimitedToTargetGroup()

		If group > 0 ' And group <= TVTTargetGroup.GetAtIndex(TVTTargetGroup.count)
			local targetGroups:string[] = TVTTargetGroup.GetAsString(group).split(",")
			local targetGroupStrings:string[]
			For local t:string = EachIn targetGroups
				targetGroupStrings :+ [GetLocale("TARGETGROUP_"+t)]
			Next
			return ", ".join(targetGroupStrings)
		else
			Return GetLocale("TARGETGROUP_NONE")
		EndIf
	End Method


	Method GetLimitedToGenre:Int() {_exposeToLua}
		Return base.GetLimitedToProgrammeGenre()
	End Method


	Method GetLimitedToGenreString:String(genre:Int=-1) {_exposeToLua}
		'if no genre given, use the one of the object
		if genre < 0 then genre = base.limitedToProgrammeGenre
		if genre < 0 then return ""

		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(genre))
	End Method


	Method GetLimitedToProgrammeFlag:Int() {_exposeToLua}
		Return base.limitedToProgrammeFlag
	End Method


	Method GetLimitedToProgrammeFlagString:String(flag:Int=-1) {_exposeToLua}
		'if no flag was given, use the one of the object
		if flag < 0 then flag = base.limitedToProgrammeFlag
		if flag < 0 then return ""


		local flags:string[] = TVTProgrammeDataFlag.GetAsString(flag).split(",")
		local flagStrings:string[]
		For local f:string = EachIn flags
			flagStrings :+ [GetLocale("PROGRAMME_FLAG_"+f)]
		Next
		return ", ".join(flagStrings)
	End Method



	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0, forPlayerID:int=-1)
		'set default mode
		if showMode = 0 then showMode = TVTBroadcastMaterialType.ADVERTISEMENT

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TVTBroadcastMaterialType.PROGRAMME
				showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			else
				showMode = TVTBroadcastMaterialType.PROGRAMME
			endif
		Endif

		if showMode = TVTBroadcastMaterialType.PROGRAMME
			ShowInfomercialSheet(x, y, align, forPlayerID)
		elseif showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			ShowAdvertisementSheet(x, y, align, forPlayerID)
		endif
	End Method


	Method ShowInfomercialSheet:Int(x:Int,y:Int, align:int=0, forPlayerID:int)
		'=== PREPARE VARIABLES ===
		if forPlayerID <= 0 then forPlayerID = owner

		local sheetWidth:int = 320
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("infomercial")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, genreH:int = 16, descriptionH:int = 70
		local barH:int = 0, msgH:int = 0
		local msgAreaH:int = 0, barAreaH:int = 0
		local barAreaPaddingY:int = 4, msgAreaPaddingY:int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", null, ALIGN_CENTER_CENTER).GetY()
		barH = skin.GetBarSize(100, -1).GetY()

		'bar area
		'bar area starts with padding, ends with padding and contains 2
		'bars
		barAreaH = 2 * barAreaPaddingY + 2 * (barH+1)

		'message area
		'show earn message
		if forPlayerID > 0 then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ msgAreaPaddingY
		'if nothing comes after the messages, add bottom padding
		if msgAreaH > 0 and barAreaH=0 then msgAreaH :+ msgAreaPaddingY

		'total height
		sheetHeight = titleH + genreH + descriptionH + msgAreaH + barAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()



		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH


		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		skin.fontNormal.drawBlock(GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL"), contentX + 5, contentY -1, contentW - 10, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(getLocale("AD_INFOMERCIAL"), contentX + 5, contentY + 3, contentW - 10, descriptionH, null, skin.textColorNeutral)
		contentY :+ descriptionH


		'=== BARS + MESSAGES ===
		'background for messages + boxes
		skin.RenderContent(contentX, contentY, contentW, msgAreaH + barAreaH , "1_bottom")

		'=== BARS ===
		'bars have a top-padding
		contentY :+ barAreaPaddingY

		'quality
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetRawQualityForPlayer(forPlayerID))
		skin.fontSemiBold.drawBlock(GetLocale("AD_QUALITY"), contentX + 5 + 200 + 5, contentY, 85, 15, null, skin.textColorLabel)
		contentY :+ barH + 1

		'topicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, base.GetInfomercialTopicality(), 1.0)
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY, 85, 15, null, skin.textColorLabel)
		contentY :+ barH + 1


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		if forPlayerID > 0
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = MathHelper.DottedValue(int(1000 * GetPerViewerRevenueForPlayer(forPlayerID)))+CURRENCYSIGN
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), "money", "good", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif

		'if there is a message then add padding to the bottom
		'if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()

			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.draw("Dauerwerbesendung: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14
			skin.fontNormal.draw("TKP: "+int(1000*GetPerViewerRevenueForPlayer(forPlayerID)) +" Eur  ("+MathHelper.NumberToString(GetPerViewerRevenueForPlayer(forPlayerID),4)+" Eur/Zuschauer)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Aktualitaet: "+MathHelper.NumberToString(base.GetInfomercialTopicality()*100,2)+"%", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Qualitaet roh: "+MathHelper.NumberToString(GetRawQualityForPlayer(forPlayerID)*100,2)+"%", contentX + 5, contentY)
			contentY :+ 12
		skin.fontNormal.draw("Qualitaet wahrgenommen: "+MathHelper.NumberToString(GetQualityForPlayer(forPlayerID)*100,2)+"%", contentX + 5, contentY)
		Endif


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	Method ShowAdvertisementSheet:Int(x:Int,y:Int, align:int=0, forPlayerID:int)
		'=== PREPARE VARIABLES ===
		if forPlayerID <= 0 then forPlayerID = owner

		local sheetWidth:int = 320
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("advertisement")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		local daysLeft:int = GetDaysLeft()
		'if unsigned, use DaysToFinish
		if owner <= 0 then daysLeft = GetDaysToFinish()

		local imageText:String
		local daysLeftText:String
		If daysLeft = 1
			daysLeftText = getLocale("AD_SEND_TILL_TOMORROW")
		ElseIf daysLeft = 0
			daysLeftText = getLocale("AD_SEND_TILL_MIDNIGHT")
		Else
			daysLeftText = getLocale("AD_SEND_TILL_TOLATE")
		EndIf


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, descriptionH:int = 70
		local boxH:int = 0, msgH:int = 0
		local msgAreaH:int = 0, boxAreaH:int = 0
		local boxAreaPaddingY:int = 4, msgAreaPaddingY:int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", null, ALIGN_CENTER_CENTER).GetY()
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()

		'box area
		'box area starts with padding, ends with padding and contains
		'2 lines of boxes
		boxAreaH = 2 * boxAreaPaddingY + 2 * boxH

		'message area
		If GetLimitedToTargetGroup() > 0 then msgAreaH :+ msgH
		If GetLimitedToGenre() >= 0 then msgAreaH :+ msgH
		If GetLimitedToProgrammeFlag() > 0 then msgAreaH :+ msgH
		'warn if short of time
		If daysLeft <= 1 then msgAreaH :+ msgH
		'only show image hint when NOT signed (after signing the image
		'is not required anymore)
		If owner <= 0 and GetMinImage() > 0 and 0.01*GetPublicImage( GetObservedPlayerID() ).GetAverageImage() < GetMinImage()
			local requiredImage:string = MathHelper.NumberToString(GetMinImage()*100,2)
			local channelImage:string = MathHelper.NumberToString(GetPublicImage( GetObservedPlayerID() ).GetAverageImage(),2)
			imageText = getLocale("AD_CHANNEL_IMAGE_TOO_LOW").Replace("%IMAGE%", requiredImage).Replace("%CHANNELIMAGE%", channelImage)

			msgAreaH :+ msgH
		endif
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ 2* msgAreaPaddingY

		'total height
		sheetHeight = titleH + descriptionH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()



		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(GetDescription(), contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH


		'=== MESSAGES ===
		'background for messages + boxes
		skin.RenderContent(contentX, contentY, contentW, msgAreaH + boxAreaH , "1_bottom")
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		'warn if special target group
		If GetLimitedToTargetGroup() > 0
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_TARGETGROUP")+": "+GetLimitedToTargetGroupString(), "targetGroupLimited", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		If GetLimitedToGenre() >= 0
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_PLEASE_GENRE_X").Replace("%GENRE%", GetLimitedToGenreString()), "warning", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		If GetLimitedToProgrammeFlag() > 0
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_PLEASE_FLAG").Replace("%FLAG%", GetLimitedToProgrammeFlagString()), "warning", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		'only show image hint when NOT signed (after signing the image is not required anymore)
		If imageText
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, imageText, "warning", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		If daysLeft <= 1
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, daysLeftText, "warning", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding
		contentY :+ boxAreaPaddingY


		'=== BOX LINE 1 ===
		'days left for this contract
		If daysLeft > 1 or daysLeft = 0
			skin.RenderBox(contentX + 5, contentY, 96, -1, daysLeft +" "+ getLocale("DAYS"), "runningTime", "neutral", skin.fontBold)
		Else
			skin.RenderBox(contentX + 5, contentY, 96, -1, daysLeft +" "+ getLocale("DAY"), "runningTime", "neutral", skin.fontBold)
		EndIf

		'spots successfully sent
		if owner < 0
			'show how many we have to send
			skin.RenderBox(contentX + 5 + 100, contentY, 92, -1, GetSpotCount() + "x", "spotsAired", "neutral", skin.fontBold)
		else
			skin.RenderBox(contentX + 5 + 100, contentY, 92, -1, GetSpotsSent() + "/" + GetSpotCount(), "spotsAired", "neutral", skin.fontBold)
		endif

		'planned
		if owner > 0
			skin.RenderBox(contentX + 5 + 196, contentY, 93, -1, GetSpotsPlanned() + "/" + GetSpotCount(), "spotsPlanned", "neutral", skin.fontBold)
		endif


		'=== BOX LINE 2 ===
		contentY :+ boxH

		'minAudience
		skin.RenderBox(contentX + 5, contentY, 96, -1, TFunctions.convertValue(GetMinAudienceForPlayer(forPlayerID), 2), "minAudience", "neutral", skin.fontBold)
		'penalty
		skin.RenderBox(contentX + 5 + 100, contentY, 92, -1, TFunctions.convertValue(GetPenaltyForPlayer(forPlayerID), 2), "money", "bad", skin.fontBold, ALIGN_RIGHT_CENTER)
		'profit
		skin.RenderBox(contentX + 5 + 196, contentY, 93, -1, TFunctions.convertValue(GetProfitForPlayer(forPlayerID), 2), "money", "good", skin.fontBold, ALIGN_RIGHT_CENTER)


		'=== DEBUG ===
		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.draw("Werbung: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14
			if base.fixedPrice
				skin.fontNormal.draw("Fester Profit: "+GetProfitForPlayer(forPlayerID) + "  (profitBase: "+MathHelper.NumberToString(base.profitBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.draw("Feste Strafe: "+GetPenaltyForPlayer(forPlayerID) + "  (penaltyBase: "+MathHelper.NumberToString(base.penaltyBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
			else
				skin.fontNormal.draw("Dynamischer Profit: "+GetProfitForPlayer(forPlayerID) + "  (profitBase: "+MathHelper.NumberToString(base.profitBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.draw("Dynamische Strafe: "+GetPenaltyForPlayer(forPlayerID) + "  (penaltyBase: "+MathHelper.NumberToString(base.penaltyBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
			endif
			skin.fontNormal.draw("Spots zu senden "+GetSpotsToSend()+" von "+GetSpotCount(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Spots: "+GetSpotsSent()+" gesendet, "+GetSpotsPlanned()+" geplant", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Zuschaueranforderung: "+GetMinAudienceForPlayer(forPlayerID) + "  ("+MathHelper.NumberToString(GetMinAudiencePercentage()*100,2)+"%)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("MindestImage: " + MathHelper.NumberToString(base.minImage*100,2)+"%", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Zielgruppe: " + GetLimitedToTargetGroup() + " (" + GetLimitedToTargetGroupString() + ")", contentX + 5, contentY)
			contentY :+ 12
			if GetLimitedToGenre() >= 0
				skin.fontNormal.draw("Genre: " + GetLimitedToGenre() + " ("+ GetLimitedToGenreString() + ")", contentX + 5, contentY)
			else
				skin.fontNormal.draw("Genre: " + GetLimitedToGenre() + " (keine Einschraenkung)", contentX + 5, contentY)
			endif
			contentY :+ 12
			skin.fontNormal.draw("Vertraege mit dieser Werbung: " + base.GetCurrentlyUsedByContractCount(), contentX + 5, contentY)
			'contentY :+ 12
			'skin.fontNormal.draw("Verfuegbarkeitszeitraum: --- noch nicht integriert ---", contentX + 5, contentY)
			contentY :+ 12
			if owner > 0
				skin.fontNormal.draw("Tage bis Vertragsende: "+GetDaysLeft() + " (Sekunden: "+ GetTimeLeft()+")", contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.draw("Unterschrieben: "+owner, contentX + 5, contentY)
				contentY :+ 12
			else
				skin.fontNormal.draw("Laufzeit: "+GetDaysToFinish(), contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.draw("Unterschrieben: nicht unterschrieben (owner="+owner+")", contentX + 5, contentY)
				contentY :+ 12
			endif
		Endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	'=== LISTENERS ===
	'methods called when special events happen

	'override
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		'=== EFFECTS ===
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("source", self).AddNumber("playerID", playerID)

		'send as advertisement
		if broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast - after "onFinishBroadcasting"-call)
			if base.GetTimesBroadcasted() = 0
				If not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE)
					base.effects.Update("broadcastFirstTimeDone", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE, True)
				endif
			endif

			base.effects.Update("broadcastDone", effectParams)

		'send as infomercial
		elseif broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if base.GetTimesBroadcastedAsInfomercial() = 0
				If not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE)
					base.effects.Update("broadcastFirstTimeInfomercialDone", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE, True)
				endif
			endif

			base.effects.Update("broadcastInfomercialDone", effectParams)
		endif
	End Method

	'override
	'called as soon as a advertisement of this contract is
	'broadcasted. If playerID = -1 then this effects might target
	'"all players" (depends on implementation)
	Method doBeginBroadcast(playerID:int = -1, broadcastType:int = 0)
		'trigger broadcastEffects
		local effectParams:TData = new TData.Add("contract", self).AddNumber("playerID", playerID)

		'send as advertisement?
		if broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if base.GetTimesBroadcasted() = 0
				If not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME)
					base.effects.Update("broadcastFirstTime", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME, True)
				endif
			endif

			base.effects.Update("broadcast", effectParams)

		elseif broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			if base.GetTimesBroadcastedAsInfomercial() = 0
				If not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL)
					base.effects.Update("broadcastFirstTimeInfomercial", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL, True)
				endif
			endif

			base.effects.Update("broadcastInfomercial", effectParams)
		endif
	End Method



	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie hoch ist das finanzielle Gewicht pro Spot?
	'Wird dafür gebraucht um die Wichtigkeit des Spots zu bewerten
	Method GetFinanceWeight:float() {_exposeToLua}
		Return (self.GetProfit() + self.GetPenalty()) / self.GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (Gesamt)
	Method GetPressure:float() {_exposeToLua}
		Return GetTimeLeft() / GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (tatsächlich / aktuell)
	Method GetCurrentPressure:float() {_exposeToLua}
		Return GetTimeLeft() / GetSpotsToSend()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie dringend ist es diese Spots zu senden
	Method GetAcuteness:float() {_exposeToLua}
		'no "acuteness" for obsolete contracts
		If self.getDaysLeft() < 0 then return 0

		'multiply by spot count (the more to send in total, the more acute)
		Return self.GetSpotsToSend() * GetSpotsToSendPercentage()  * GetTimeGonePercentage()^3
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie viele Spots sollten heute mindestens gesendet werden
	Method SendMinimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotsToSend()
		local daysLeft:int = self.GetDaysLeft() + 1
		'no "blocks" for obsolete contracts
		If daysLeft <= 0 or spotsToBroadcast <= 0 then return 0

		'Local acuteness:Float = self.GetAcuteness() / self.GetSpotsToSend() 'reduce to time-acuteness
		'print GetTitle()+"   spotsToBroadcast: " + spotsToBroadcast+"  acuteness:" + acuteness +"  daysLeft: " + daysLeft

		' send at least 1 spot per day except you have really much time
		If (daysLeft >= 3)
			Return 1
		Else
			Return ceil(spotsToBroadcast / float(daysLeft))
		Endif
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type




'a filter for adcontract(base)s
Type TAdContractBaseFilter
	Field minAudienceMin:Float = -1.0
	Field minAudienceMax:Float = -1.0
	Field minImageMin:Float = -1.0
	Field minImageMax:Float = -1.0
	Field currentlyUsedByContractsLimitMin:int = -1
	Field currentlyUsedByContractsLimitMax:int = -1
	Field limitedToProgrammeGenres:int[]
	Field limitedToTargetGroups:int[]
	Field checkAvailability:int = True
	'by default we only allow "normal" ads
	Field adType:int = 0
	Field skipLimitedProgrammeGenre:int = False
	Field skipLimitedTargetGroup:int = False
	Field forbiddenContractGUIDs:string[]


	Global filters:TList = CreateList()


	Function Add:TAdContractBaseFilter(filter:TAdContractBaseFilter)
		filters.AddLast(filter)

		return filter
	End Function


	Method SetAudience:TAdContractBaseFilter(minAudienceQuote:float=-1.0, maxAudienceQuote:Float=-1.0)
		minAudienceMin = minAudienceQuote
		minAudienceMax = maxAudienceQuote
		Return self
	End Method


	Method SetImage:TAdContractBaseFilter(minImage:float=-1.0, maxImage:Float=-1.0)
		minImageMin = minImage
		minImageMax = maxImage
		Return self
	End Method


	Method SetCurrentlyUsedByContractsLimit:TAdContractBaseFilter(minLimit:int = -1, maxLimit:int = -1)
		currentlyUsedByContractsLimitMin = minLimit
		currentlyUsedByContractsLimitMax = maxLimit
		Return self
	End Method


	Method SetLimitedToTargetGroup:TAdContractBaseFilter(groups:int[])
		limitedToTargetGroups = groups
		Return self
	End Method


	Method SetLimitedToProgrammeGenre:TAdContractBaseFilter(genres:int[])
		limitedToProgrammeGenres = genres
		Return self
	End Method


	Method SetSkipLimitedToProgrammeGenre:TAdContractBaseFilter(bool:int = True)
		skipLimitedProgrammeGenre = bool
		Return self
	End Method


	Method SetSkipLimitedToTargetGroup:TAdContractBaseFilter(bool:int = True)
		skipLimitedTargetGroup = bool
		Return self
	End Method


	Method IsForbiddenContractGUID:int(guid:string)
		if forbiddenContractGUIDs.length = 0 then return False

		guid = guid.ToLower()
		For local forbiddenGUID:string = EachIn forbiddenContractGUIDs
			if forbiddenGUID = guid then return True
		Next
		return False
	End Method


	Method AddForbiddenContractGUID:int(guid:string)
		if not IsForbiddenContractGUID(guid)
			forbiddenContractGUIDs :+ [guid.ToLower()]
			return True
		else
			return False
		endif
	End Method


	Function GetCount:Int()
		return filters.Count()
	End Function


	Function GetAtIndex:TAdContractBaseFilter(index:int)
		return TAdContractBaseFilter(filters.ValueAtIndex(index))
	End Function


	Method ToString:String()
		local result:string = ""
		result :+ "Audience: " + MathHelper.NumberToString(100*minAudienceMin,2)+" - "+MathHelper.NumberToString(100 * minAudienceMax, 2)+"%"
		result :+ "  "
		result :+ "Image: " + MathHelper.NumberToString(minImageMin,2)+" - "+MathHelper.NumberToString(minImageMax, 2)
		return result
	End Method


	'checks if the given adcontract fits into the filter criteria
	Method DoesFilter:Int(contract:TAdContractBase)
		if not contract then return False

		'skip contracts not available (year or by script expression)
		if checkAvailability and not contract.IsAvailable() then return False

		'skip contracts of the wrong type
		if adType >= 0 and contract.adType <> adType then return False


		if minAudienceMin >= 0 and contract.minAudienceBase < minAudienceMin then return False
		if minAudienceMax >= 0 and contract.minAudienceBase > minAudienceMax then return False

		if minImageMin >= 0 and contract.minImage < minImageMin then return False
		if minImageMax >= 0 and contract.minImage > minImageMax then return False


		'limited simultaneous usage ?
		'-> 1 - 3 means contracts with 1,2 or 3 contracts using it
		'-> 0 - 0 means contracts with no contracts using it
		if currentlyUsedByContractsLimitMin >= 0 and contract.GetCurrentlyUsedByContractCount() < currentlyUsedByContractsLimitMin then return False
		if currentlyUsedByContractsLimitMax >= 0 and contract.GetCurrentlyUsedByContractCount() > currentlyUsedByContractsLimitMax then return False


		'first check if we have to check for limits
		if skipLimitedProgrammeGenre and contract.limitedToProgrammeGenre >= 0 then return False
		if skipLimitedTargetGroup and contract.limitedToTargetGroup > 0 then return False


		'limited to one of the defined target groups?
		if limitedToTargetGroups and limitedToTargetGroups.length > 0
			For local group:int = EachIn limitedToTargetGroups
				if contract.limitedToTargetGroup = group then return True
			Next
			return False
		endif

		'limited to one of the defined programme genre?
		if limitedToProgrammeGenres and limitedToProgrammeGenres.length > 0
			For local genre:int = EachIn limitedToProgrammeGenres
				if contract.limitedToProgrammeGenre = genre then return True
			Next
			return False
		endif


		'forbidden one? (eg. to avoid fetching the same again)
		if forbiddenContractGUIDs.length > 0
			if IsForbiddenContractGUID(contract.GetGUID()) then return False
		endif


		return True
	End Method
End Type