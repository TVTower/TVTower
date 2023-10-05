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
	Field entriesCount:Int = -1

	'factor by what an infomercial topicality DECREASES by sending it
	Field infomercialWearoffFactor:Float = 1.25
	'factor by what an infomercial topicality INCREASES on a new day
	Field infomercialRefreshFactor:Float = 1.3

	Global _instance:TAdContractBaseCollection


	Function GetInstance:TAdContractBaseCollection()
		If Not _instance Then _instance = New TAdContractBaseCollection
		Return _instance
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
		If GUID.Trim() = "" Then Return Null

		GUID = GUID.ToLower()

		'find first hit
		For Local ad:TAdContractBase = EachIn entries.Values()
			If ad.GetGUID().ToLower().Find(GUID) >= 0
				Return ad
			EndIf
		Next

		Return Null
	End Method


	'this is not guaranteed to be unique!
	Method GetByTitle:TAdContractBase(title:String, languageCode:String="")
		Local langID:Int = TLocalization.currentLanguageID
		If languageCode Then langID = TLocalization.GetLanguageID(languageCode)
		For Local base:TAdContractBase = EachIn entries.Values()
			If base.title.Get(langID) = title Then Return base
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
		If entriesCount >= 0 Then Return entriesCount

		entriesCount = 0
		For Local base:TAdContractBase = EachIn entries.Values()
			entriesCount :+1
		Next
		Return entriesCount
	End Method


	Method GetRandom:TAdContractBase(array:TAdContractBase[] = Null)
		If array = Null Or array.length = 0 Then array = GetAllAsArray()
		If array.length = 0 Then Return Null
		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetRandomNormalByFilter:TAdContractBase(filter:TAdContractBaseFilter, returnUnfilteredOnError:Int = True)
		Local contracts:TAdContractBase[]

		For Local contract:TAdContractBase = EachIn entries.Values()
			If contract.adType <> TVTAdContractType.NORMAL Then Continue
			If Not filter.DoesFilter(contract) Then Continue

			'add it to candidates list
			contracts :+ [contract]
		Next

		If contracts.length = 0
			If returnUnfilteredOnError
				Print "AdContractBaseCollection: GetRandomNormalByFilter without results! Returning Random without filter."
			Else
				'no need to debug print something - as the param is
				'manually set to false...
				'print "AdContractBaseCollection: GetRandomNormalByFilter without results! Returning NULL."
				Return Null
			EndIf
		EndIf

		Return GetRandom(contracts)
	End Method


	Method GetRandomByFilter:TAdContractBase(filter:TAdContractBaseFilter, returnUnfilteredOnError:Int = True)
		Local contracts:TAdContractBase[]

		For Local contract:TAdContractBase = EachIn entries.Values()
			If Not filter.DoesFilter(contract) Then Continue

			'add it to candidates list
			contracts :+ [contract]
		Next

		If contracts.length = 0
			If returnUnfilteredOnError
				Print "AdContractBaseCollection: GetRandomByFilter without results! Returning Random without filter."
			Else
				'no need to debug print something - as the param is
				'manually set to false...
				'print "AdContractBaseCollection: GetRandomByFilter without results! Returning NULL."
				Return Null
			EndIf
		EndIf

		Return GetRandom(contracts)
	End Method


	Method GetAllAsArray:TAdContractBase[]()
		Local array:TAdContractBase[]
		'create a full array containing all elements
		For Local obj:TAdContractBase = EachIn entries.Values()
			array :+ [obj]
		Next
		Return array
	End Method


	Method Remove:Int(obj:TAdContractBase)
		If obj.GetGuid() And entries.Remove(obj.GetGUID())
			'invalidate count
			entriesCount = -1

			Return True
		EndIf

		Return False
	End Method


	Method Add:Int(obj:TAdContractBase)
		entries.Insert(obj.GetGUID(), obj)
		'invalidate count
		entriesCount = -1

		Return True
	End Method


	Method RefreshInfomercialTopicalities:Int() {_private}
		For Local base:TAdContractBase = EachIn entries.Values()
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
		If Not _instance Then _instance = New TAdContractCollection
		Return _instance
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


	Method Remove:Int(obj:TAdContract)
		Return list.Remove(obj)
	End Method


	Method Add:Int(obj:TAdContract)
		'only add once
		If list.contains(obj) Then Return False

		list.AddLast(obj)
		Return True
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractCollection:TAdContractCollection()
	Return TAdContractCollection.GetInstance()
End Function





'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase Extends TBroadcastMaterialSource {_exposeToLua}
	'days to fullfill a (signed) contract
	Field daysToFinish:Int = 0
	'spots to send
	Field spotCount:Int = 1
	'block length
	Field blocks:Int = 1
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
	'minimum channel image base value (real value calculated on sign)
	Field minImage:Float
	'maximum channel image base value (real value calculated on sign)
	Field maxImage:Float
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
	Field infomercialAllowed:Int = True
	'topicality for this contract base (all adcontracts of this base
	'share this topicality !)
	Field infomercialTopicality:Float = 1.0
	Field infomercialMaxTopicality:Float = 1.0
	Field infomercialProfitBase:Int = 0
	'keep the profit the same for all audience requirements
	Field fixedInfomercialProfit:Int = True
	'if set, this defines a range in which the advertisement can come up
	Field availableYearRangeFrom:Int = -1
	Field availableYearRangeTo:Int = -1

	'special expression defining whether a contract is available for
	'ad vendor or not (eg. "YEAR > 2000" or "YEARSPLAYED > 2")
	Field availableScript:String = ""

	'defines the type of the ad according to TVTAdContractType
	'only adType 0 is generically available in the game
	Field adType:Int = 0

	'array of contract guids using this base at the moment
	Field currentlyUsedByContracts:String[]

	'TODO: store in BroadcastInformationProvider
	Field timesBroadcastedAsInfomercial:Int[] = [0]

	Rem
		modifiers:
		"topicality:infomercialWearoff"
		  changes how much an infomercial loses topicality during sending it
		"topicality:infomercialRefresh"
		  changes how much an infomercial "regenerates" on topicality per day
	endrem
	Global modKeyTopicality_infomercialRefreshLS:TLowerString = New TLowerString.Create("topicality::infomercialRefresh")
	Global modKeyTopicality_infomercialWearoffLS:TLowerString = New TLowerString.Create("topicality::infomercialWearoff")


	Method GenerateGUID:String()
		Return "broadcastmaterialsource-adcontractbase-"+id
	End Method


	Method GetMaterialSourceType:Int() {_exposeToLua}
		Return TVTBroadcastMaterialSourceType.ADCONTRACT
	End Method


	Method Create:TAdContractBase(GUID:String, title:TLocalizedString, description:TLocalizedString, daysToFinish:Int, spotCount:Int, targetgroup:Int, minAudience:Float, minImage:Float, maxImage:Float, fixedPrice:Int, profit:Float, penalty:Float)
		Self.SetGUID(GUID)
		Self.title = title
		Self.description = description
		Self.daysToFinish = daysToFinish
		Self.spotCount = spotCount
		Self.limitedToTargetGroup = targetGroup
		Self.minAudienceBase = minAudience
		Self.minImage = minImage
		Self.maxImage = maxImage
		Self.fixedPrice = fixedPrice
		Self.profitBase	= profit
		Self.penaltyBase = penalty

		GetAdContractBaseCollection().Add(Self)

		Return Self
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local a1:TAdContractBase = TAdContractBase(o1)
		Local a2:TAdContractBase = TAdContractBase(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		If a1.GetTitle().ToLower() = a2.GetTitle().ToLower()
			Return a1.minAudienceBase > a2.minAudienceBase
		ElseIf a1.GetTitle().ToLower() > a2.GetTitle().ToLower()
			Return 1
		EndIf
		Return -1
	End Function


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(value:Float = -1)
		If value < 0 Then value = minAudienceBase
		Return MathHelper.Clamp(value, 0.0, 1.0)
	End Method


	'returns the non rounded minimum audience
	'@playerID          playerID = -1 to use the avg audience maximum
	'@getTotalAudience  avoid breaking down audience if a target group limit is set up
	Method GetRawMinAudienceForPlayer:Int(playerID:Int, getTotalAudience:Int = False, audience:Int=-1)
		Local useAudience:Int = audience
		If audience < 0
			If playerID <= 0
				useAudience = GetStationMapCollection().GetAverageReach()
			Else
				useAudience = GetStationMap(playerID).GetReach()
			EndIf
		EndIf

		If Not getTotalAudience
			'if limited to specific target group ... break audience down
			'to this specific group
			If GetLimitedToTargetGroup() > 0
				useAudience :* AudienceManager.GetTargetGroupPercentage(GetLimitedToTargetGroup())
			EndIf
		EndIf

		Local result:Int = GetMinAudiencePercentage() * useAudience

		result :* GetPlayerDifficulty(playerID).adcontractRawMinAudienceMod

		Return result
	End Method


	'Gets minimum needed audience in absolute numbers
	Method GetMinAudienceForPlayer:Int(playerID:Int, getTotalAudience:Int = False, audience:Int=-1)
		Return TFunctions.RoundToBeautifulValue( GetRawMinAudienceForPlayer(playerID, getTotalAudience, audience) )
	End Method


	Method IsAvailable:Int()
		'field "available" = false ?
		If Not Super.IsAvailable() Then Return False

		'skip contracts not available in this game year
		If availableYearRangeFrom > 0 And GetWorldTime().GetYear() < availableYearRangeFrom Then Return False
		If availableYearRangeTo > 0 And GetWorldTime().GetYear() > availableYearRangeTo Then Return False

		'a special script expression defines custom rules for adcontracts
		'to be available or not
		If availableScript And Not GetScriptExpression().Eval(availableScript)
			Return False
		EndIf

		Return True
	End Method


	'playerID < 0 means "get all"
	Method GetTimesBroadcastedAsInfomercial:Int(playerID:Int = -1)
		If playerID >= timesBroadcastedAsInfomercial.length Then Return 0
		If playerID >= 0 Then Return timesBroadcastedAsInfomercial[playerID]

		Local result:Int = 0
		For Local i:Int = 0 Until timesBroadcastedAsInfomercial.length
			result :+ timesBroadcastedAsInfomercial[i]
		Next
		Return result
	End Method


	Method SetTimesBroadcastedAsInfomercial:Int(times:Int, playerID:Int)
		If playerID < 0 Then playerID = 0

		'resize array if player has no entry yet
		If playerID >= timesBroadcastedAsInfomercial.length
			timesBroadcastedAsInfomercial = timesBroadcastedAsInfomercial[.. playerID + 1]
		EndIf

		timesBroadcastedAsInfomercial[playerID] = times
	End Method


	Method GetBlocks:Int(broadcastType:Int = 0) {_exposeToLua}
		Return blocks
	End Method


	'override
	Method GetQuality:Float() {_exposeToLua}
		Return quality
	End Method


	'when used as programme
	Method GetProgrammeTopicality:Float() {_exposeToLua}
		Return GetInfomercialTopicality()
	End Method


	Method GetInfomercialTopicality:Float() {_exposeToLua}
		Return infomercialTopicality
	End Method


	Method GetMaxInfomercialTopicality:Float() {_exposeToLua}
		Return infomercialMaxTopicality
	End Method


	Method GetInfomercialRefreshModifier:Float()
		Return GetModifier(modKeyTopicality_infomercialRefreshLS)
	End Method


	Method GetInfomercialWearoffModifier:Float()
		Return GetModifier(modKeyTopicality_infomercialWearoffLS)
	End Method


	Method CutInfomercialTopicality:Int(cutModifier:Float=1.0) {_private}
		'for the calculation we need to know what to cut, not what to keep
		Local toCut:Float =  (1.0 - cutModifier)
		Local minimumRelativeCut:Float = 0.10 '10%
		Local minimumAbsoluteCut:Float = 0.10 '10%

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


	Method RefreshInfomercialTopicality:Int(refreshModifier:Float=1.0) {_private}
		Local minimumRelativeRefresh:Float = 1.10 '110%
		Local minimumAbsoluteRefresh:Float = 0.10 '10%

		refreshModifier :* GetAdContractBaseCollection().infomercialRefreshFactor
		refreshModifier :* GetInfomercialRefreshModifier()

		refreshModifier = Max(refreshModifier, minimumRelativeRefresh)

		infomercialTopicality :+ Max(infomercialTopicality * (refreshModifier-1.0), minimumAbsoluteRefresh)
		infomercialTopicality = MathHelper.Clamp(infomercialTopicality, 0, GetMaxInfomercialTopicality())

		Return infomercialTopicality
	End Method


	Method IsLimitedToProgrammeGenre:Int(genre:Int) {_exposeToLua}
		Return GetLimitedToProgrammeGenre() = genre
	End Method

	Method GetLimitedToProgrammeGenre:Int() {_exposeToLua}
		Return limitedToProgrammeGenre
	End Method


	Method IsLimitedToProgrammeFlag:Int(flag:Int) {_exposeToLua}
		Return (GetLimitedToProgrammeFlag() & flag) > 0
	End Method

	Method GetLimitedToProgrammeFlag:Int() {_exposeToLua}
		Return limitedToProgrammeFlag
	End Method



	Method IsLimitedToTargetGroup:Int(targetGroup:Int) {_exposeToLua}
		Return (GetLimitedToTargetGroup() & targetGroup) > 0
	End Method

	Method GetLimitedToTargetGroup:Int() {_exposeToLua}
		'with no required audience, we cannot limit to target groups
		'except hmm ... we want that at least 1 of the target group
		'is watching
		If GetMinAudiencePercentage() = 0 Then Return 0

		Return Max(0, limitedToTargetGroup)
	End Method


	Method SetLimitedToTargetGroup:Int(group:Int, enable:Int=True)
		If enable
			limitedToTargetGroup = GetLimitedToTargetGroup() | group
		Else
			limitedToTargetGroup = GetLimitedToTargetGroup() & ~group
		EndIf
	End Method


	Method GetProPressureGroups:Int()
		Return Max(0, proPressureGroups)
	End Method


	Method HasProPressureGroup:Int(group:Int) {_exposeToLua}
		Return (GetProPressureGroups() & group) > 0
	End Method


	Method SetProPressureGroup:Int(group:Int, enable:Int=True)
		If enable
			proPressureGroups = GetProPressureGroups() | group
		Else
			proPressureGroups = GetProPressureGroups() & ~group
		EndIf
	End Method


	Method GetContraPressureGroups:Int()
		Return Max(0, contraPressureGroups)
	End Method


	Method HasContraPressureGroup:Int(group:Int) {_exposeToLua}
		Return (GetContraPressureGroups() & group) > 0
	End Method


	Method SetContraPressureGroup:Int(group:Int, enable:Int=True)
		If enable
			contraPressureGroups = GetContraPressureGroups() | group
		Else
			contraPressureGroups = GetContraPressureGroups() & ~group
		EndIf
	End Method


	Method IsCurrentlyUsedByContract:Int(contractGUID:String)
		For Local guid:String = EachIn currentlyUsedByContracts
			If guid = contractGUID Then Return True
		Next
		Return False
	End Method


	Method AddCurrentlyUsedByContract:Int(contractGUID:String)
		'skip if already used
		If IsCurrentlyUsedByContract(contractGUID) Then Return False

		currentlyUsedByContracts :+ [contractGUID]

		Return True
	End Method


	Method RemoveCurrentlyUsedByContract:Int(contractGUID:String)
		'skip if already not existent
		If Not IsCurrentlyUsedByContract(contractGUID) Then Return False

		Local newArray:String[]
		For Local guid:String = EachIn currentlyUsedByContracts
			If guid <> contractGUID Then newArray :+ [contractGUID]
		Next
		currentlyUsedByContracts = newArray

		Return True
	End Method


	Method GetCurrentlyUsedByContractCount:Int()
		Return currentlyUsedByContracts.length
	End Method
End Type




'the useable contract for advertisements used in the playercollections
Type TAdContract Extends TBroadcastMaterialSource {_exposeToLua="selected"}
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
	Field adAgencyClassification:Int = 0

	'for statistics
	Field stateTime:Long = -1
	Field state:Int = 0


	Const PRICETYPE_PROFIT:Int = 1
	Const PRICETYPE_PENALTY:Int = 2
	Const PRICETYPE_INFOMERCIALPROFIT:Int = 3
	'same as in TBroadcastMaterialBase
	Const STATE_OK:Int = 1
	Const STATE_FAILED:Int = 2


	Method GenerateGUID:String()
		Return "broadcastmaterialsource-adcontract-"+id
	End Method


	'create UNSIGNED (adagency)
	Method Create:TAdContract(baseContract:TAdContractBase)
		SetBase(baseContract)

		GetAdContractCollection().Add(Self)
		Return Self
	End Method


	Method SetBase(baseContract:TAdContractBase)
		'decrease used counter if needed
		If Self.base Then Self.base.RemoveCurrentlyUsedByContract( GetGUID() )
		'increase used counter of new contract
		If baseContract Then baseContract.AddCurrentlyUsedByContract( GetGUID() )

		Self.base = baseContract
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		If a1.GetTitle().ToLower() = a2.GetTitle().ToLower()
			Return a1.base.minAudienceBase > a2.base.minAudienceBase
		ElseIf a1.GetTitle().ToLower() > a2.GetTitle().ToLower()
			Return 1
		EndIf
		Return -1
	End Function


	Function SortByClassification:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1
		If a1.adAgencyClassification = a2.adAgencyClassification
			Return a1.GetTitle() > a2.GetTitle()
		EndIf
        Return a1.adAgencyClassification - a2.adAgencyClassification
	End Function


	Function SortByProfit:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1
		If a1.GetProfit() = a2.GetProfit()
			Return a1.GetTitle() > a2.GetTitle()
		EndIf
        Return a1.GetProfit() - a2.GetProfit()
	End Function


	'sort by _absolute_ minAudience. So 60.000 "men" is < 90.000 "all"
	Function SortByMinAudience:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		If a1.GetMinAudience() = a2.GetMinAudience()
			Return a1.GetTitle() > a2.GetTitle()
		EndIf
        Return a1.GetMinAudience() - a2.GetMinAudience()
	End Function


	'sort by _absolute_ minAudience. So 60.000 "men" is > 90.000 "all" (50% men of 90.000 = 45.000)
	Function SortByMinAudienceRelative:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		'calculate the value as if population consists only of the targetgroup
		Local relativeAudience1:Int = a1.GetMinAudience()/AudienceManager.GetTargetGroupPercentage(a1.GetLimitedToTargetGroup())
		Local relativeAudience2:Int = a2.GetMinAudience()/AudienceManager.GetTargetGroupPercentage(a2.GetLimitedToTargetGroup())

		If relativeAudience1 = relativeAudience2
			Return a1.GetTitle() > a2.GetTitle()
		EndIf
        Return relativeAudience1 - relativeAudience2
	End Function


	Function SortByDaysLeft:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		If a1.GetDaysLeft() = a2.GetDaysLeft()
			Return a1.GetTitle() > a2.GetTitle()
		EndIf
        Return a1.GetDaysLeft() - a2.GetDaysLeft()
	End Function


	Function SortBySpotsToSend:Int(o1:Object, o2:Object)
		Local a1:TAdContract = TAdContract(o1)
		Local a2:TAdContract = TAdContract(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		If a1.GetSpotsSent() = a2.GetSpotsSent()
			Return a1.GetTitle() > a2.GetTitle()
		EndIf
        Return a1.GetSpotsToSend() - a2.GetSpotsToSend()
	End Function


	Method SetSpotsSent:Int(value:Int)
		If spotsSent = value Then Return False

		spotsSent = value
		'emit an event so eg. ContractList-caches can get recreated
		TriggerBaseEvent(GameEventKeys.AdContract_OnSetSpotsSent, Null, Self)

		Return True
	End Method


	Method GetPerViewerRevenueForPlayer:Float(playerID:Int)
		If Not IsInfomercialAllowed() Then Return 0.0

		Local result:Float = 0.0

		'calculate
		result = GetInfomercialProfitForPlayer(playerID)
		'cut down to the price of 1 viewer (assume a CPM price)
		result :* 0.001

		'less revenue with less topicality
		'by default think of no topicality at
		Local topicalityDecrease:Float = 1.0
		If base.GetMaxInfomercialTopicality() > 0
			topicalityDecrease = 1.0 - (base.infomercialTopicality / base.GetMaxInfomercialTopicality())
		EndIf
		'cut by maximum 90%
		result :* (0.1 + 0.9 * (1.0 - topicalityDecrease))

		Return result
	End Method


	'what to earn each hour for each viewer
	'(broadcasted as "infomercial")
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		Return GetPerViewerRevenueForPlayer(owner)
	End Method


	'overwrite method from base
	Method GetTitle:String() {_exposeToLua}
		If Not title And base Then Return base.GetTitle()

		Return Super.GetTitle()
	End Method


	'overwrite method from base
	Method GetDescription:String() {_exposeToLua}
		If Not description And base Then Return base.GetDescription()

		Return Super.GetDescription()
	End Method


	'overwrite method from base
	Method GetBlocks:Int(broadcastType:Int = 0) {_exposeToLua}
		Return base.GetBlocks()
	End Method


	'sign the contract -> calculate values and change owner
	Method Sign:Int(owner:Int, day:Int=-1, skipChecks:Int = False)
		If Self.owner = owner Then Return False

		If Not skipChecks
			'run checks if sign is allowed
			If Not IsAvailableToSign(owner) Then Return False
		EndIf

		Self.owner = owner
		Self.profit	= GetProfitForPlayer(owner, True)
		Self.penalty = GetPenaltyForPlayer(owner, True)
		Self.infomercialProfit = GetInfomercialProfitForPlayer(owner, True)
		Self.minAudience = GetMinAudienceForPlayer(owner, True)
		Self.totalMinAudience = GetTotalMinAudienceForPlayer(owner, True)

		If day < 0 Then day = GetWorldTime().GetDay()
		Self.daySigned = day

		'TLogger.log("TAdContract.Sign", "Player "+owner+" signed a contract.  Profit: "+profit+",  Penalty: "+penalty+ ",  MinAudience: "+minAudience+",  Title: "+GetTitle(), LOG_DEBUG)
		Return True
	End Method


	'returns whether a contract could get signed
	'ATTENTION: AI could use this to check if a player is able to
	'sign this (fulfills certain maybe not visible factors).
	'so it exposes some kind of information
	Method IsAvailableToSign:Int(playerID:Int) {_exposeToLua}
		'not enough channel image?
		If GetMinImage() > 0 And 0.01*GetPublicImageCollection().Get(playerID).GetAverageImage() < GetMinImage() Then Return False
		'or too much?
		If GetMaxImage() > 0 And 0.01*GetPublicImageCollection().Get(playerID).GetAverageImage() > GetMaxImage() Then Return False

		Return (Not IsSigned())
	End Method


	'override
	Method IsAvailable:Int() {_exposeToLua}
		'once we created a contract out of the base, the base availability
		'should no longer matter
		'- eg. gamestart-advertisement
		'- adcontracts are available from 1985-1986, if checking their
		'  availability after signing in 1986 will result in FALSE in
		'  begin of 1987 while it should be broadcastable then
		'if not base.IsAvailable() then return False

		Return Super.IsAvailable()
	End Method


	Method IsSigned:Int() {_exposeToLua}
		Return (owner > 0 And daySigned >= 0)
	End Method


	Method IsCompleted:Int() {_exposeToLua}
		Return state = STATE_OK
	End Method


	Method IsFailed:Int() {_exposeToLua}
		Return state = STATE_FAILED
	End Method


	'returns whether the contract was fulfilled and can get finished
 	Method CanComplete:Int()
		'already finished / failed?
		If state = STATE_OK Or state = STATE_FAILED Then Return False

 		Return (base.spotCount <= spotsSent)
 	End Method


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(dbvalue:Float = -1) {_exposeToLua}
		Return base.GetMinAudiencePercentage(dbvalue)
	End Method


	'the quality is higher for "better paid" advertisements with
	'higher audience requirements... no cheap "car seller" ad :D
	Method GetRawQualityForPlayer:Float(playerID:Int) {_exposeToLua}
		Local quality:Float = 0.05

		Local minA:Int = GetMinAudienceForPlayer(playerID, False)
		'TODO: switch to Percentages + modifiers for TargetGroup-Limits
		If minA >   1000 Then quality :+ 0.01		'+0.06
		If minA >   5000 Then quality :+ 0.025		'+0.085
		If minA >  10000 Then quality :+ 0.05		'+0.135
		If minA >  50000 Then quality :+ 0.075		'+0.21
		If minA > 250000 Then quality :+ 0.1		'+0.31
		If minA > 750000 Then quality :+ 0.19		'+0.5
		If minA >1500000 Then quality :+ 0.25		'+0.75
		If minA >5000000 Then quality :+ 0.25		'+1.00

		'a portion of the resulting quality is based on the "better"
		'advertisements (minAudience and minImage)
		quality = 0.70 * base.GetQuality() + 0.15 * quality + 0.15 * GetMinImage()

		'modify according to dev-balancing
		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG"))
		If devConfig
			quality :* devConfig.GetFloat("DEV_ADCONTRACT_RAWQUALITY_MOD", 1.0)
		EndIf

		Return MathHelper.Clamp(quality, 0.01, 1.0)
	End Method


	Method GetRawQuality:Float() {_exposeToLua}
		Return GetRawQualityForPlayer(owner)
	End Method


	Method GetQualityForPlayer:Float(playerID:Int)
		Local quality:Float = GetRawQualityForPlayer(playerID)

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
		Return GetQualityForPlayer(owner)
	End Method


	Method IsInfomercialAllowed:Int() {_exposeToLua}
		Return base.infomercialAllowed
	End Method


	Method Remove:Int() Override
		'set contract base unused
		base.RemoveCurrentlyUsedByContract( GetGUID() )
	End Method


	'call this to set the contract failed (and pay a penalty)
	Method Fail:Int(time:Long=0)
		'send out event for potential listeners (eg. ingame notification)
		TriggerBaseEvent(GameEventKeys.AdContract_OnFail, New TData.AddLong("time", time), Self)

		'pay penalty
		GetPlayerFinance(owner, GetWorldTime().GetDay(time)).PayPenalty(GetPenalty(), Self)

		'store for statistics
		stateTime = time
		state = STATE_FAILED

		'clean up (eg. decrease usage counter)
		Remove()
	End Method


	'call this to set the contract successful and finished (and earn profit)
	Method Finish:Int(time:Long=0)
		'if state = STATE_OK then Throw "Double Finish !!"
		If Not state = STATE_OK
			'send out event for potential listeners (eg. ingame notification)
			TriggerBaseEvent(GameEventKeys.AdContract_OnFinish, New TData.AddLong("time", time), Self)

			'give money
			GetPlayerFinance(owner, GetWorldTime().GetDay(time)).EarnAdProfit(GetProfit(), Self)

			'store for statistics
			stateTime = time
			state = STATE_OK
		EndIf

		'clean up (eg. decrease usage counter)
		Remove()
	End Method


	'if targetgroup is set, the price is doubled
	Method GetProfitForPlayer:Int(playerID:Int, invalidateCache:Int = False)
		'already calculated and data for owner requested
		If Not invalidateCache
			If owner > 0 And owner = playerID And profit >= 0 Then Return profit
		EndIf

		Local result:Int = CalculatePricesForPlayer(base.profitBase, playerID, PRICETYPE_PROFIT) * GetSpotCount()

		Return result
	End Method


	'if targetgroup is set, the price is doubled
	Method GetProfit:Int(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return GetProfitForPlayer(playerID, False)
	End Method


	Method GetProfitCPM:Float(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return 1000 * GetProfitForPlayer(playerID, False) / GetMinAudienceForPlayer(playerID)
	End Method


	Method GetInfomercialProfitForPlayer:Int(playerID:Int, invalidateCache:Int = False)
		'already calculated and data for owner requested
		If Not invalidateCache
			If owner > 0 And owner = playerID And infomercialProfit >= 0 Then Return infomercialProfit
		EndIf

		Local result:Float
		'return fixed or calculated profit
		If base.fixedInfomercialProfit
			result = base.infomercialProfitBase
		Else
			result = CalculatePricesForPlayer(base.infomercialProfitBase, playerID, PRICETYPE_INFOMERCIALPROFIT)
		EndIf

		Return result
	End Method


	Method GetInfomercialProfit:Int(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return GetInfomercialProfitForPlayer(playerID, False)
	End Method


	'returns the penalty for this contract
	Method GetPenaltyForPlayer:Int(playerID:Int, invalidateCache:Int = False)
		'already calculated and data for owner requested
		If Not invalidateCache
			If owner > 0 And owner = playerID And penalty >= 0 Then Return penalty
		EndIf

		Local result:Int = CalculatePricesForPlayer(base.penaltyBase, playerID, PRICETYPE_PENALTY) * GetSpotCount()

		Return result
	End Method


	'returns the penalty for this contract
	Method GetPenalty:Int(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return GetPenaltyForPlayer(playerID, False)
	End Method


	Method GetPenaltyCPM:Float(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return 1000 * GetPenaltyForPlayer(playerID, False) / GetMinAudienceForPlayer(playerID)
	End Method


	Function GetCPM:Double(baseCPM:Double, marketShare:Float)
		'factor for income per spot decreases with increasing market share
		'30% off base when reaching all viewers
		return baseCPM * (1 - 0.3 * marketShare)
	End Function


	'calculate prices (profits, penalties...)
	Method CalculatePricesForPlayer:Int(baseValue:Float=0, playerID:Int, priceType:Int = 0)
		'=== FIXED PRICE ===
		'ad is with fixed price - only available without minimum restriction
		If base.fixedPrice
			'print self.base.title.Get() + " has fixed price : "+ int(baseValue * GetSpotCount()) + " base:"+int(baseprice) + " profitbase:"+base.profitBase +" penaltyBase:"+base.penaltyBase
			'basePrice is a precalculated value (eg. 1000 euro)
			Return baseValue
		EndIf

		Local population:Int = 1000
		Local minAudience:Int = GetTotalMinAudienceForPlayer(playerID)
		Local reach:Int = population
		If playerID > 0 
			population = GetStationMapCollection().GetPopulation()
			reach = GetStationMap(playerID, True).GetReach()
		EndIf

		'=== DYNAMIC PRICE ===
		Local difficulty:TPlayerDifficulty = GetPlayerDifficulty(playerID)
		Local devPriceMod:Float = difficulty.adcontractPriceMod
		Local limitedToGenreMultiplier:Float = difficulty.adcontractLimitedGenreMod
		Local limitedToProgrammeFlagMultiplier:Float = difficulty.adcontractLimitedProgrammeFlagMod
		Local limitedToTargetGroupMultiplier:Float = difficulty.adcontractLimitedTargetgroupMod

		Local price:Float


		price = GetCPM(baseValue, Float(reach) / population)

		'multiply by amount of "1000 viewers"-blocks (ignoring targetGroups)
		price :* Max(1, minAudience/1000)
		'multiply by amount of "1000 viewers"-blocks (_not_ ignoring targetGroups)
		'price :* Max(1, getMinAudience(playerID)/1000)

		'adjust by a balancing factor
		price :* devPriceMod

		'specific targetgroups change price
		Local targetGroups:Int = GetLimitedToTargetGroup()
		If targetGroups > 0 and limitedToTargetGroupMultiplier > 1
			Local percentBonus:Float = ((1 - AudienceManager.GetTargetGroupPercentage(targetGroups)) * (limitedToTargetGroupMultiplier - 1))
			price :* (1 + percentBonus)
		EndIf
		'limiting to specific genres change the price too
		If GetLimitedToProgrammeGenre() > 0 Then price :* limitedToGenreMultiplier
		'limiting to specific flags change the price too
		If GetLimitedToProgrammeFlag() > 0 Then price :* limitedToProgrammeFlagMultiplier

		'adjust by a player difficulty
		If priceType = PRICETYPE_PROFIT
			price :* difficulty.adcontractProfitMod
		ElseIf priceType = PRICETYPE_PENALTY
			price :* difficulty.adcontractPenaltyMod
		ElseIf priceType = PRICETYPE_INFOMERCIALPROFIT
			price :* difficulty.adcontractInfomercialProfitMod
		EndIf

		'print GetTitle()+": minAud%="+GetMinAudiencePercentage() +"  price=" +price +"  rawAud="+getRawMinAudienceForPlayer(playerID) +"  targetGroup="+GetLimitedToTargetGroup()

		'return "beautiful" prices
		Return TFunctions.RoundToBeautifulValue(price)
	End Method


	'returns the non rounded minimum audience
	'@playerID          playerID = -1 to use the avg audience maximum
	'@getTotalAudience  avoid breaking down audience if a target group limit is set up
	Method GetRawMinAudienceForPlayer:Int(playerID:Int, getTotalAudience:Int = False, audience:Int=-1)
		Return base.GetRawMinAudienceForPlayer(playerID, getTotalAudience, audience)
	End Method


	Method GetRawMinAudience:Int(playerID:Int=-1, getTotalAudience:Int = False) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return GetRawMinAudienceForPlayer(playerID, getTotalAudience)
	End Method


	'Gets minimum needed audience in absolute numbers
	Method GetMinAudienceForPlayer:Int(playerID:Int, invalidateCache:Int = False)
		'skip calculation if already calculated
		If Not invalidateCache
			If owner > 0 And playerId = owner And minAudience >=0 Then Return minAudience
		EndIf

		Return base.GetMinAudienceForPlayer(playerID)
	End Method


	Method GetMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return GetMinAudienceForPlayer(playerID)
	End Method


	'returns the non rounded minimum audience
	Method GetTotalRawMinAudienceForPlayer:Int(playerID:Int)
		Return GetRawMinAudienceForPlayer(playerID, True)
	End Method


	Method GetTotalRawMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = owner
		Return GetTotalRawMinAudienceForPlayer(playerID)
	End Method


	'Gets minimum needed audience in absolute numbers (ignoring
	'targetgroup limits)
	Method GetTotalMinAudienceForPlayer:Int(playerID:Int, invalidateCache:Int = False)
		'skip calculation if already calculated
		If Not invalidateCache
			If owner > 0 And owner = playerID And totalMinAudience >=0 Then Return totalMinAudience
		EndIf

		Return TFunctions.RoundToBeautifulValue( GetTotalRawMinAudienceForPlayer(playerID) )
	End Method


	Method GetTotalMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		Return GetTotalMinAudienceForPlayer(owner, False)
	End Method


	'days left for sending all contracts from today
	Method GetDaysLeft:Int(currentDay:Int = -1) {_exposeToLua}
		If daySigned < 0
			Return base.daysToFinish
		Else
			If currentDay < 0 Then currentDay = GetWorldTime().GetDay()
			Return ( base.daysToFinish - (currentDay - daySigned) )
		EndIf
	End Method


	Method GetEndTime:Long() {_exposeToLua}
		If daySigned < 0
			Return GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay() + base.daysToFinish + 1, 0,0)
		Else
			Return GetWorldTime().GetTimeGoneForGameTime(0, daySigned + base.daysToFinish + 1, 0,0)
		EndIf
	End Method


	Method GetStartTime:Long() {_exposeToLua}
		If daySigned < 0
			Return GetWorldTime().GetTimeGone()
		Else
			Return GetWorldTime().GetTimeGoneForGameTime(0, daySigned, 0,0)
		EndIf
	End Method


	Method GetDaySigned:Int() {_exposeToLua}
		Return daySigned
	End Method


	'time left for sending all contract-spots from now
	Method GetTimeLeft:Long() {_exposeToLua}
		Return GetEndTime() - GetWorldTime().GetTimeGone()
	End Method


	'time left for sending all contract-spots from now
	Method GetTimeLeft:Long(now:Long) {_exposeToLua}
		If now < 0 Then now = GetWorldTime().GetTimeGone()

		Return GetEndTime() - now
	End Method


	Method GetTimeGonePercentage:Float() {_exposeToLua}
		If daySigned < 0 Then Return 0.0
		Return 1.0 - GetTimeLeft() / Float(GetEndTime() - GetStartTime())
	End Method


	Method GetTimeGonePercentage:Float(now:Long)
		If daySigned < 0 Then Return 0.0
		Return 1.0 - GetTimeLeft(now) / Float(GetEndTime() - GetStartTime())
	End Method


	'get the contract (to access its ID or title by its GetXXX() )
	Method GetBase:TAdContractBase() {_exposeToLua}
		Return base
	End Method


	Method GetSpotsToSendPercentage:Float() {_exposeToLua}
		Return GetSpotsToSend() / Float(GetSpotCount())
	End Method


	'amount of spots still missing
	Method GetSpotsToSend:Int() {_exposeToLua}
		Return (base.spotCount - spotsSent)
	End Method


	Method SetSpotsPlanned:Int(value:Int)
		spotsPlanned = value
	End Method


	'amount of spots planned (adjusted by programmeplanner)
	Method GetSpotsPlanned:Int() {_exposeToLua}
		Return spotsPlanned
	End Method


	'amount of spots which have already been successfully broadcasted
	Method GetSpotsSent:Int() {_exposeToLua}
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


	Method GetMaxImage:Float() {_exposeToLua}
		Return base.maxImage
	End Method


	Method IsLimitedToTargetGroup:Int(targetGroup:Int) {_exposeToLua}
		Return base.IsLimitedtoTargetGroup(targetGroup)
	End Method

	Method GetLimitedToTargetGroup:Int() {_exposeToLua}
		Return base.GetLimitedToTargetGroup()
	End Method


	Method GetLimitedToTargetGroupString:String(group:Int=-1) {_exposeToLua}
		'if no group given, use the one of the object
		If group < 0 Then group = GetLimitedToTargetGroup()

		If group > 0 ' And group <= TVTTargetGroup.GetAtIndex(TVTTargetGroup.count)
			'Local targetGroups:String[] = TVTTargetGroup.GetAsString(group).split(",")
			'For Local targetGroupString:int = EachIn targetGroupStrings
			'	targetGroupStrings :+ [GetLocale("TARGETGROUP_" + targetGroupString)]
			'Next
			Local targetGroupIDs:Int[] = TVTTargetGroup.GetIndexes(group)
			Local targetGroupStrings:String[]
			For Local tgIndex:int = EachIn targetGroupIDs
				Local col:SColor8 = GameConfig.GetTargetGroupColor(tgIndex)
				'Local colorBox:String = "|color="+col.r+","+col.g+","+col.b+"|"+Chr(9632)+"|/color|"
				'targetGroupStrings :+ [colorBox + GetLocale("TARGETGROUP_" + TVTTargetGroup.GetIndexAsString(tgIndex)) + colorBox]
				'targetGroupStrings :+ ["|color="+col.r+","+col.g+","+col.b+"|"+Chr(9654)+"|/color| " + GetLocale("TARGETGROUP_" + TVTTargetGroup.GetIndexAsString(tgIndex)) +" |sprite=gfx_targetGroup_"+TVTTargetGroup.GetIndexAsString(tgIndex)+",13,13|"]
				targetGroupStrings :+ ["|color="+col.r+","+col.g+","+col.b+"|"+Chr(9654)+"|/color| " + GetLocale("TARGETGROUP_" + TVTTargetGroup.GetIndexAsString(tgIndex))]
			Next
			Return ", ".join(targetGroupStrings)
		Else
			Return GetLocale("TARGETGROUP_NONE")
		EndIf
	End Method


	Method IsLimitedToProgrammeGenre:Int(genre:Int) {_exposeToLua}
		Return base.IsLimitedToProgrammeGenre(genre)
	End Method

	Method GetLimitedToProgrammeGenre:Int() {_exposeToLua}
		Return base.GetLimitedToProgrammeGenre()
	End Method


	Method GetLimitedToProgrammeGenreString:String(genre:Int=-1) {_exposeToLua}
		'if no genre given, use the one of the object
		If genre < 0 Then genre = base.limitedToProgrammeGenre
		If genre < 0 Then Return ""

		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(genre))
	End Method


	Method IsLimitedToProgrammeFlag:Int(flag:Int) {_exposeToLua}
		Return base.IsLimitedToProgrammeFlag(flag)
	End Method

	Method GetLimitedToProgrammeFlag:Int() {_exposeToLua}
		Return base.GetLimitedToProgrammeFlag()
	End Method


	Method GetLimitedToProgrammeFlagString:String(flag:Int=-1) {_exposeToLua}
		'if no flag was given, use the one of the object
		If flag < 0 Then flag = base.limitedToProgrammeFlag
		If flag < 0 Then Return ""


		Local flags:String[] = TVTProgrammeDataFlag.GetAsString(flag).split(",")
		Local flagStrings:String[]
		For Local f:String = EachIn flags
			flagStrings :+ [GetLocale("PROGRAMME_FLAG_"+f)]
		Next
		Return ", ".join(flagStrings)
	End Method



	Method ShowSheet:Int(x:Int,y:Int, align:Float=0.5, showMode:Int=0, forPlayerID:Int=-1, minAudienceHightlightType:Int=0)
		'set default mode
		If showMode = 0 Then showMode = TVTBroadcastMaterialType.ADVERTISEMENT

		If KeyManager.IsDown(KEY_LALT) Or KeyManager.IsDown(KEY_RALT)
			If showMode = TVTBroadcastMaterialType.PROGRAMME
				showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			Else
				showMode = TVTBroadcastMaterialType.PROGRAMME
			EndIf
		EndIf

		If showMode = TVTBroadcastMaterialType.PROGRAMME
			ShowInfomercialSheet(x, y, align, forPlayerID)
		ElseIf showMode = TVTBroadcastMaterialType.ADVERTISEMENT
			ShowAdvertisementSheet(x, y, align, forPlayerID, minAudienceHightlightType)
		EndIf
	End Method


	Method ShowInfomercialSheet:Int(x:Int, y:Int, align:Float=0.5, forPlayerID:Int)
		'=== PREPARE VARIABLES ===
		If forPlayerID <= 0 Then forPlayerID = owner

		Local sheetWidth:Int = 330
		Local sheetHeight:Int = 0 'calculated later
		x = x - align*sheetWidth

		Local skin:TDatasheetSkin = GetDatasheetSkin("infomercial")
		Local contentW:Int = skin.GetContentW(sheetWidth)
		Local contentX:Int = x + skin.GetContentY()
		Local contentY:Int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		Local titleH:Int = 18, genreH:Int = 16, descriptionH:Int = 70
		Local barH:Int = 0, msgH:Int = 0
		Local msgAreaH:Int = 0, barAreaH:Int = 0
		Local barAreaPaddingY:Int = 4, msgAreaPaddingY:Int = 4

		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).GetBoxHeight(GetTitle(), contentW - 10, 100))

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", Null, ALIGN_CENTER_CENTER).y
		barH = skin.GetBarSize(100, -1).y

		'bar area
		'bar area starts with padding, ends with padding and contains 2
		'bars
		barAreaH = 2 * barAreaPaddingY + 2 * (barH+1)

		'message area
		'show earn message
		If forPlayerID > 0 Then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		If msgAreaH > 0 Then msgAreaH :+ msgAreaPaddingY
		'if nothing comes after the messages, add bottom padding
		If msgAreaH > 0 And barAreaH=0 Then msgAreaH :+ msgAreaPaddingY

		'total height
		sheetHeight = titleH + genreH + descriptionH + msgAreaH + barAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()



		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		if titleH <= 18
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(GetTitle(), contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		else
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(GetTitle(), contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		endif
		contentY :+ titleH


		'=== GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		skin.fontNormal.DrawBox(GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL"), contentX + 5, contentY - 1, contentW - 10, genreH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		contentY :+ genreH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(GetLocale("AD_INFOMERCIAL"), contentX + 5, contentY + 1, contentW - 10, descriptionH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		contentY :+ descriptionH


		'=== BARS + MESSAGES ===
		'background for messages + boxes
		skin.RenderContent(contentX, contentY, contentW, msgAreaH + barAreaH , "1_bottom")

		'=== BARS ===
		'bars have a top-padding
		contentY :+ barAreaPaddingY

		'quality
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetRawQualityForPlayer(forPlayerID))
		skin.fontSmallCaption.DrawSimple(GetLocale("AD_QUALITY"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 1

		'topicality
		skin.RenderBar(contentX + 5, contentY, 200, 12, base.GetInfomercialTopicality(), 1.0)
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_TOPICALITY"), contentX + 5 + 200 + 5, contentY - 2, skin.textColorLabel,  EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 1


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		If msgAreaH > 0 Then contentY :+ msgAreaPaddingY

		If forPlayerID > 0
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			Local revenue:String = GetFormattedCurrency(Int(1000 * GetPerViewerRevenueForPlayer(forPlayerID)))
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").Replace("%PROFIT%", revenue), "money", "good", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		'if there is a message then add padding to the bottom
		'if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		If TVTDebugInfo
			'begin at the top ...again
			contentY = y + skin.GetContentY()

			Local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.DrawSimple("Dauerwerbesendung: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14
			skin.fontNormal.DrawSimple("TKP: "+Int(1000*GetPerViewerRevenueForPlayer(forPlayerID)) +" Eur  ("+MathHelper.NumberToString(GetPerViewerRevenueForPlayer(forPlayerID),4)+" Eur/Zuschauer)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Aktualitaet: "+MathHelper.NumberToString(base.GetInfomercialTopicality()*100,2)+"%", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Qualitaet roh: "+MathHelper.NumberToString(GetRawQualityForPlayer(forPlayerID)*100,2)+"%", contentX + 5, contentY)
			contentY :+ 12
		skin.fontNormal.DrawSimple("Qualitaet wahrgenommen: "+MathHelper.NumberToString(GetQualityForPlayer(forPlayerID)*100,2)+"%", contentX + 5, contentY)
		EndIf


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	Method ShowAdvertisementSheet:Int(x:Int,y:Int, align:Float=0.5, forPlayerID:Int, minAudienceHightlightType:int = 0)
		'=== PREPARE VARIABLES ===
		If forPlayerID <= 0 Then forPlayerID = owner

		Local sheetWidth:Int = 330
		Local sheetHeight:Int = 0 'calculated later
		x = x - align*sheetWidth

		Local skin:TDatasheetSkin = GetDatasheetSkin("advertisement")
		Local contentW:Int = skin.GetContentW(sheetWidth)
		Local contentX:Int = x + skin.GetContentY()
		Local contentY:Int = y + skin.GetContentY()

		Local daysLeft:Int = GetDaysLeft()
		'if unsigned, use DaysToFinish
		If owner <= 0 Then daysLeft = GetDaysToFinish()
		Local imageText:String


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		Local titleH:Int = 18, descriptionH:Int = 70
		Local boxH:Int = 0, msgH:Int = 0
		Local msgAreaH:Int = 0, boxAreaH:Int = 0
		Local boxAreaPaddingY:Int = 4, msgAreaPaddingY:Int = 4

		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).GetBoxHeight(GetTitle(), contentW - 10, 100))

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "targetGroupLimited", "warning", Null, ALIGN_CENTER_CENTER).y
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").y

		'box area
		'box area starts with padding, ends with padding and contains
		'2 lines of boxes
		boxAreaH = 2 * boxAreaPaddingY + 2 * boxH

		'message area
		If GetLimitedToTargetGroup() > 0 Then msgAreaH :+ msgH
		If GetLimitedToProgrammeGenre() >= 0 Then msgAreaH :+ msgH
		If GetLimitedToProgrammeFlag() > 0 Then msgAreaH :+ msgH
		'warn if short of time or finished/failed
		If daysLeft <= 1 Or IsCompleted()
			msgAreaH :+ msgH
		EndIf

		'only show image hint when NOT signed (after signing the image
		'is not required anymore)
		If owner <= 0 And GetMinImage() > 0 And 0.01*GetPublicImage( GetObservedPlayerID() ).GetAverageImage() < GetMinImage()
			Local requiredImage:String = MathHelper.NumberToString(GetMinImage()*100,2)
			Local channelImage:String = MathHelper.NumberToString(GetPublicImage( GetObservedPlayerID() ).GetAverageImage(),2)
			imageText = getLocale("AD_CHANNEL_IMAGE_TOO_LOW").Replace("%IMAGE%", requiredImage).Replace("%CHANNELIMAGE%", channelImage)

			msgAreaH :+ msgH
		ElseIf owner <= 0 And GetMaxImage() > 0 And 0.01*GetPublicImage( GetObservedPlayerID() ).GetAverageImage() > GetMaxImage()
			Local requiredMaxImage:String = MathHelper.NumberToString(GetMaxImage()*100,2)
			Local channelImage:String = MathHelper.NumberToString(GetPublicImage( GetObservedPlayerID() ).GetAverageImage(),2)
			imageText = getLocale("AD_CHANNEL_IMAGE_TOO_HIGH").Replace("%IMAGE%", requiredMaxImage).Replace("%CHANNELIMAGE%", channelImage)

			msgAreaH :+ msgH
		EndIf
		'if there are messages, add padding of messages
		If msgAreaH > 0 Then msgAreaH :+ 2* msgAreaPaddingY

		'total height
		sheetHeight = titleH + descriptionH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()



		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		if titleH <= 18
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(GetTitle(), contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		else
			GetBitmapFont("default", 13, BOLDFONT).DrawBox(GetTitle(), contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		endif
		contentY :+ titleH


		'=== CONTENT AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(GetDescription(), contentX + 5, contentY + 1, contentW - 10, descriptionH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		contentY :+ descriptionH


		'=== MESSAGES ===
		'background for messages + boxes
		skin.RenderContent(contentX, contentY, contentW, msgAreaH + boxAreaH , "1_bottom")
		'if there is a message then add padding to the begin
		If msgAreaH > 0 Then contentY :+ msgAreaPaddingY

		'warn if special target group
		If GetLimitedToTargetGroup() > 0
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_TARGETGROUP")+": "+GetLimitedToTargetGroupString(), "targetGroupLimited", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		If GetLimitedToProgrammeGenre() >= 0
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_PLEASE_GENRE_X").Replace("%GENRE%", GetLimitedToProgrammeGenreString()), "warning", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		If GetLimitedToProgrammeFlag() > 0
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_PLEASE_FLAG").Replace("%FLAG%", GetLimitedToProgrammeFlagString()), "warning", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		'only show image hint when NOT signed (after signing the image is not required anymore)
		If imageText
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, imageText, "warning", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		If IsCompleted()
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("ADCONTRACT_FINISHED"), "ok", "good", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		ElseIf daysLeft <= 1
			Select daysLeft
				Case 1	skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_SEND_TILL_TOMORROW"), "warning", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
				Case 0	skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("AD_SEND_TILL_MIDNIGHT"), "warning", "warning", skin.fontNormal, ALIGN_CENTER_CENTER)
				Default skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("ADCONTRACT_FAILED"), "warning", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			EndSelect
			contentY :+ msgH
		EndIf
		'if there is a message then add padding to the bottom
		If msgAreaH > 0 Then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding
		contentY :+ boxAreaPaddingY


		'=== BOX LINE 1 ===
		'days left for this contract
		If IsCompleted()
			skin.RenderBox(contentX + 5, contentY, 100, -1, "---", "runningTime", "neutral", skin.fontBold)
		ElseIf daysLeft > 1 
			skin.RenderBox(contentX + 5, contentY, 100, -1, daysLeft +" "+ getLocale("DAYS"), "runningTime", "neutral", skin.fontBold)
		ElseIf daysLeft = 0
			skin.RenderBox(contentX + 5, contentY, 100, -1, daysLeft +" "+ getLocale("DAYS"), "runningTime", "badHint", skin.fontBold)
		ElseIf daysLeft = 1
			skin.RenderBox(contentX + 5, contentY, 100, -1, daysLeft +" "+ getLocale("DAY"), "runningTime", "neutral", skin.fontBold)
		Else
			skin.RenderBox(contentX + 5, contentY, 100, -1, "---", "runningTime", "neutral", skin.fontBold)
		EndIf

		'spots successfully sent
		If owner < 0
			'show how many we have to send
			skin.RenderBox(contentX + 5 + 104, contentY, 96, -1, GetSpotCount() + "x", "spotsAired", "neutral", skin.fontBold)
		Else
			skin.RenderBox(contentX + 5 + 104, contentY, 96, -1, GetSpotsSent() + "/" + GetSpotCount(), "spotsAired", "neutral", skin.fontBold)
		EndIf

		'planned
		If owner > 0
			skin.RenderBox(contentX + 5 + 204, contentY, 96, -1, GetSpotsPlanned() + "/" + GetSpotCount(), "spotsPlanned", "neutral", skin.fontBold)
		EndIf


		'=== BOX LINE 2 ===
		contentY :+ boxH

		'minAudience
		If minAudienceHightlightType = 1
			skin.RenderBox(contentX + 5, contentY, 100, -1, TFunctions.convertValue(GetMinAudienceForPlayer(forPlayerID), 2), "minAudience", "goodHint", skin.fontBold)
		ElseIf minAudienceHightlightType = -1
			skin.RenderBox(contentX + 5, contentY, 100, -1, TFunctions.convertValue(GetMinAudienceForPlayer(forPlayerID), 2), "minAudience", "badHint", skin.fontBold)
		Else
			skin.RenderBox(contentX + 5, contentY, 100, -1, TFunctions.convertValue(GetMinAudienceForPlayer(forPlayerID), 2), "minAudience", "neutral", skin.fontBold)
		EndIf
			If KeyManager.IsDown(KEY_LSHIFT) Or KeyManager.IsDown(KEY_RSHIFT)
			'penalty per spot
			skin.RenderBox(contentX + 5 + 104, contentY, 96, -1, TFunctions.convertValue(GetPenaltyForPlayer(forPlayerID)/GetSpotCount(), 2), "money", "bad", skin.fontBold, ALIGN_RIGHT_CENTER)
			'profit per spot
			skin.RenderBox(contentX + 5 + 204, contentY, 96, -1, TFunctions.convertValue(GetProfitForPlayer(forPlayerID)/GetSpotCount(), 2), "money", "good", skin.fontBold, ALIGN_RIGHT_CENTER)
		Else
			'penalty
			skin.RenderBox(contentX + 5 + 104, contentY, 96, -1, TFunctions.convertValue(GetPenaltyForPlayer(forPlayerID), 2), "money", "bad", skin.fontBold, ALIGN_RIGHT_CENTER)
			'profit
			skin.RenderBox(contentX + 5 + 204, contentY, 96, -1, TFunctions.convertValue(GetProfitForPlayer(forPlayerID), 2), "money", "good", skin.fontBold, ALIGN_RIGHT_CENTER)
		EndIf


		'=== DEBUG ===
		If TVTDebugInfo
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			Local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.DrawSimple("Werbung: "+GetTitle(), contentX + 5, contentY)
			contentY :+ 14
			If base.fixedPrice
				skin.fontNormal.DrawSimple("Fester Profit: "+GetProfitForPlayer(forPlayerID) + "  (profitBase: "+MathHelper.NumberToString(base.profitBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.DrawSimple("Feste Strafe: "+GetPenaltyForPlayer(forPlayerID) + "  (penaltyBase: "+MathHelper.NumberToString(base.penaltyBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
			Else
				skin.fontNormal.DrawSimple("Dynamischer Profit: "+GetProfitForPlayer(forPlayerID) + "  (profitBase: "+MathHelper.NumberToString(base.profitBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.DrawSimple("Dynamische Strafe: "+GetPenaltyForPlayer(forPlayerID) + "  (penaltyBase: "+MathHelper.NumberToString(base.penaltyBase,2)+")", contentX + 5, contentY)
				contentY :+ 12
			EndIf
			skin.fontNormal.DrawSimple("Spots zu senden "+GetSpotsToSend()+" von "+GetSpotCount(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Spots: "+GetSpotsSent()+" gesendet, "+GetSpotsPlanned()+" geplant", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Zuschaueranforderung: "+GetMinAudienceForPlayer(forPlayerID) + "  ("+MathHelper.NumberToString(GetMinAudiencePercentage()*100,2)+"%)", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("SenderImage: " + MathHelper.NumberToString(GetMinImage()*100,2)+"%" +" - " + MathHelper.NumberToString(GetMaxImage()*100,2)+"%", contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Zielgruppe: " + GetLimitedToTargetGroup() + " (" + GetLimitedToTargetGroupString() + ")", contentX + 5, contentY)
			contentY :+ 12
			If GetLimitedToProgrammeGenre() >= 0
				skin.fontNormal.DrawSimple("Genre: " + GetLimitedToProgrammeGenre() + " ("+ GetLimitedToProgrammeGenreString() + ")", contentX + 5, contentY)
			Else
				skin.fontNormal.DrawSimple("Genre: " + GetLimitedToProgrammeGenre() + " (keine Einschraenkung)", contentX + 5, contentY)
			EndIf
			contentY :+ 12
			skin.fontNormal.DrawSimple("Vertraege mit dieser Werbung: " + base.GetCurrentlyUsedByContractCount(), contentX + 5, contentY)
			'contentY :+ 12
			'skin.fontNormal.draw("Verfuegbarkeitszeitraum: --- noch nicht integriert ---", contentX + 5, contentY)
			contentY :+ 12
			If owner > 0
				skin.fontNormal.DrawSimple("Tage bis Vertragsende: "+GetDaysLeft() + " (Sekunden: "+ GetTimeLeft()+")", contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.DrawSimple("Unterschrieben: "+owner, contentX + 5, contentY)
				contentY :+ 12
			Else
				skin.fontNormal.DrawSimple("Laufzeit: "+GetDaysToFinish(), contentX + 5, contentY)
				contentY :+ 12
				skin.fontNormal.DrawSimple("Unterschrieben: nicht unterschrieben (owner="+owner+")", contentX + 5, contentY)
				contentY :+ 12
			EndIf
		EndIf

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Method


	'=== LISTENERS ===
	'methods called when special events happen

	'override
	Method doFinishBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'=== EFFECTS ===
		'trigger broadcastEffects
		Local effectParams:TData = New TData.Add("source", Self).AddInt("playerID", playerID)

		'send as advertisement
		If broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast - after "onFinishBroadcasting"-call)
			If base.GetTimesBroadcasted() = 0
				If Not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE)
					base.UpdateEffects("broadcastFirstTimeDone", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_DONE, True)
				EndIf
			EndIf

			If base.effects Then base.effects.Update("broadcastDone", effectParams)

		'send as infomercial
		ElseIf broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			If base.GetTimesBroadcastedAsInfomercial() = 0
				If Not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE)
					base.UpdateEffects("broadcastFirstTimeInfomercialDone", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL_DONE, True)
				EndIf
			EndIf

			base.UpdateEffects("broadcastInfomercialDone", effectParams)
		EndIf
	End Method

	'override
	'called as soon as a advertisement of this contract is
	'broadcasted. If playerID = -1 then this effects might target
	'"all players" (depends on implementation)
	Method doBeginBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'trigger broadcastEffects
		Local effectParams:TData = New TData.Add("contract", Self).AddInt("playerID", playerID)

		'send as advertisement?
		If broadcastType = TVTBroadcastMaterialType.ADVERTISEMENT
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			If base.GetTimesBroadcasted() = 0
				If Not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME)
					base.UpdateEffects("broadcastFirstTime", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME, True)
				EndIf
			EndIf

			If base.effects Then base.effects.Update("broadcast", effectParams)

		ElseIf broadcastType = TVTBroadcastMaterialType.PROGRAMME
			'if nobody broadcasted till now (times are adjusted on
			'finishBroadcast while this is called on beginBroadcast)
			If base.GetTimesBroadcastedAsInfomercial() = 0
				If Not base.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL)
					base.UpdateEffects("broadcastFirstTimeInfomercial", effectParams)
					base.setBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_FIRST_TIME_SPECIAL, True)
				EndIf
			EndIf

			base.UpdateEffects("broadcastInfomercial", effectParams)
		EndIf
	End Method



	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method

	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method SetAttractivenessString(value:String) {_exposeToLua}
		SetAttractiveness(Float(value))
	End Method

	'expose commented out because of above mentioned brl.reflection bug
	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) '{_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie hoch ist das finanzielle Gewicht pro Spot?
	'Wird dafür gebraucht um die Wichtigkeit des Spots zu bewerten
	Method GetFinanceWeight:Float() {_exposeToLua}
		Return (Self.GetProfit() + Self.GetPenalty()) / Self.GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (Gesamt)
	Method GetPressure:Float() {_exposeToLua}
		Return GetTimeLeft() / GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (tatsächlich / aktuell)
	Method GetCurrentPressure:Float() {_exposeToLua}
		Return GetTimeLeft() / GetSpotsToSend()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie dringend ist es diese Spots zu senden
	Method GetAcuteness:Float() {_exposeToLua}
		'no "acuteness" for obsolete contracts
		If Self.getDaysLeft() < 0 Then Return 0

		'base value is audience which typically corrensponds to profit
		Local result:Float = getMinAudiencePercentage() * 100
		'min audience for target groups needs to be scaled 
		If IsLimitedToTargetGroup(TVTTargetGroup.CHILDREN) Then result:* 6
		If IsLimitedToTargetGroup(TVTTargetGroup.TEENAGERS) Then result:* 5
		If IsLimitedToTargetGroup(TVTTargetGroup.HOUSEWIVES) Then result:* 4
		If IsLimitedToTargetGroup(TVTTargetGroup.EMPLOYEES) Then result:* 4
		If IsLimitedToTargetGroup(TVTTargetGroup.UNEMPLOYED) Then result:* 3
		If IsLimitedToTargetGroup(TVTTargetGroup.MANAGERS) Then result:* 7
		If IsLimitedToTargetGroup(TVTTargetGroup.PENSIONERS) Then result:* 4
		If IsLimitedToTargetGroup(TVTTargetGroup.WOMEN) Then result:* 2
		If IsLimitedToTargetGroup(TVTTargetGroup.MEN) Then result:* 2
		'aim at one spot per day left
		If Self.getDaysLeft() < Self.getSpotsToSend() Then result:* 2
		If Self.getSpotsToSend() = 1 Then result:* 2
		'big effort on last day
		If Self.getDaysLeft() = 0 And GetWorldTime().getHour() > 5 Then result:* 4
		'the more spots sent the worse failing will be (other spots wasted)
		If GetSpotsToSendPercentage() < 1 Then result:/ (1-GetSpotsToSendPercentage())
		'TODO consider profit/penalty more directly?
		'TODO acuteness really as bmx function or rather part of player strategy (fast money vs best audience)
		Return result
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie viele Spots sollten heute mindestens gesendet werden
	Method SendMinimalBlocksToday:Int() {_exposeToLua}
		Local spotsToBroadcast:Int = Self.GetSpotsToSend()
		Local daysLeft:Int = Self.GetDaysLeft() + 1
		'no "blocks" for obsolete contracts
		If daysLeft <= 0 Or spotsToBroadcast <= 0 Then Return 0

		'Local acuteness:Float = self.GetAcuteness() / self.GetSpotsToSend() 'reduce to time-acuteness
		'print GetTitle()+"   spotsToBroadcast: " + spotsToBroadcast+"  acuteness:" + acuteness +"  daysLeft: " + daysLeft

		' send at least 1 spot per day except you have really much time
		If (daysLeft >= 3)
			Return 1
		Else
			Return Ceil(spotsToBroadcast / Float(daysLeft))
		EndIf
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type




'a filter for adcontract(base)s
Type TAdContractBaseFilter
	Field minAudienceMin:Float = -1.0
	Field minAudienceMax:Float = -1.0
	Field minImageMin:Float = -1.0
	Field minImageMax:Float = -1.0
	Field maxImageMin:Float = -1.0
	Field maxImageMax:Float = -1.0
	Field currentlyUsedByContractsLimitMin:Int = -1
	Field currentlyUsedByContractsLimitMax:Int = -1
	Field limitedToProgrammeGenres:Int[]
	Field limitedToTargetGroups:Int[]
	Field checkAvailability:Int = True
	'by default we only allow "normal" ads
	Field adType:Int = 0
	Field skipLimitedProgrammeGenre:Int = False
	Field skipLimitedTargetGroup:Int = False
	Field forbiddenContractGUIDs:String[]


	Global filters:TList = CreateList()


	Function Add:TAdContractBaseFilter(filter:TAdContractBaseFilter)
		filters.AddLast(filter)

		Return filter
	End Function


	Method SetAudience:TAdContractBaseFilter(minAudienceQuote:Float=-1.0, maxAudienceQuote:Float=-1.0)
		minAudienceMin = minAudienceQuote
		minAudienceMax = maxAudienceQuote
		Return Self
	End Method


	Method SetMinImageRange:TAdContractBaseFilter(minImageMin:Float=-1.0, minImageMax:Float=-1.0)
		Self.minImageMin = minImageMin
		Self.minImageMax = minImageMax
		Return Self
	End Method


	Method SetMaxImageRange:TAdContractBaseFilter(maxImageMin:Float=-1.0, maxImageMax:Float=-1.0)
		Self.maxImageMin = maxImageMin
		Self.maxImageMax = maxImageMax
		Return Self
	End Method


	Method SetCurrentlyUsedByContractsLimit:TAdContractBaseFilter(minLimit:Int = -1, maxLimit:Int = -1)
		currentlyUsedByContractsLimitMin = minLimit
		currentlyUsedByContractsLimitMax = maxLimit
		Return Self
	End Method


	Method SetLimitedToTargetGroup:TAdContractBaseFilter(groups:Int[])
		limitedToTargetGroups = groups
		Return Self
	End Method


	Method SetLimitedToProgrammeGenre:TAdContractBaseFilter(genres:Int[])
		limitedToProgrammeGenres = genres
		Return Self
	End Method


	Method SetSkipLimitedToProgrammeGenre:TAdContractBaseFilter(bool:Int = True)
		skipLimitedProgrammeGenre = bool
		Return Self
	End Method


	Method SetSkipLimitedToTargetGroup:TAdContractBaseFilter(bool:Int = True)
		skipLimitedTargetGroup = bool
		Return Self
	End Method


	Method IsForbiddenContractGUID:Int(guid:String)
		If forbiddenContractGUIDs.length = 0 Then Return False

		guid = guid.ToLower()
		For Local forbiddenGUID:String = EachIn forbiddenContractGUIDs
			If forbiddenGUID = guid Then Return True
		Next
		Return False
	End Method


	Method AddForbiddenContractGUID:Int(guid:String)
		If Not IsForbiddenContractGUID(guid)
			forbiddenContractGUIDs :+ [guid.ToLower()]
			Return True
		Else
			Return False
		EndIf
	End Method


	Function GetCount:Int()
		Return filters.Count()
	End Function


	Function GetAtIndex:TAdContractBaseFilter(index:Int)
		Return TAdContractBaseFilter(filters.ValueAtIndex(index))
	End Function


	Method ToString:String()
		Local result:String = ""
		result :+ "Audience: " + MathHelper.NumberToString(100*minAudienceMin,2)+" - "+MathHelper.NumberToString(100 * minAudienceMax, 2)+"%"
		result :+ "  "
		result :+ "MinImage: " + MathHelper.NumberToString(minImageMin,2)+" - "+MathHelper.NumberToString(minImageMax, 2)
		result :+ "MaxImage: " + MathHelper.NumberToString(maxImageMin,2)+" - "+MathHelper.NumberToString(maxImageMax, 2)
		Return result
	End Method


	'checks if the given adcontract fits into the filter criteria
	Method DoesFilter:Int(contract:TAdContractBase)
		If Not contract Then Return False

		'skip contracts not available (year or by script expression)
		If checkAvailability And Not contract.IsAvailable() Then Return False

		'skip contracts of the wrong type
		If adType >= 0 And contract.adType <> adType Then Return False


		If minAudienceMin >= 0 And contract.minAudienceBase < minAudienceMin Then Return False
		If minAudienceMax >= 0 And contract.minAudienceBase > minAudienceMax Then Return False

		If minImageMin >= 0 And contract.minImage < minImageMin Then Return False
		If minImageMax >= 0 And contract.minImage > minImageMax Then Return False

		If maxImageMin >= 0 And contract.maxImage < maxImageMin Then Return False
		If maxImageMax >= 0 And contract.maxImage > maxImageMax Then Return False


		'limited simultaneous usage ?
		'-> 1 - 3 means contracts with 1,2 or 3 contracts using it
		'-> 0 - 0 means contracts with no contracts using it
		If currentlyUsedByContractsLimitMin >= 0 And contract.GetCurrentlyUsedByContractCount() < currentlyUsedByContractsLimitMin Then Return False
		If currentlyUsedByContractsLimitMax >= 0 And contract.GetCurrentlyUsedByContractCount() > currentlyUsedByContractsLimitMax Then Return False


		'first check if we have to check for limits
		If skipLimitedProgrammeGenre And contract.limitedToProgrammeGenre >= 0 Then Return False
		If skipLimitedTargetGroup And contract.limitedToTargetGroup > 0 Then Return False


		'limited to one of the defined target groups?
		If limitedToTargetGroups And limitedToTargetGroups.length > 0
			For Local group:Int = EachIn limitedToTargetGroups
				If contract.limitedToTargetGroup = group Then Return True
			Next
			Return False
		EndIf

		'limited to one of the defined programme genre?
		If limitedToProgrammeGenres And limitedToProgrammeGenres.length > 0
			For Local genre:Int = EachIn limitedToProgrammeGenres
				If contract.limitedToProgrammeGenre = genre Then Return True
			Next
			Return False
		EndIf


		'forbidden one? (eg. to avoid fetching the same again)
		If forbiddenContractGUIDs.length > 0
			If IsForbiddenContractGUID(contract.GetGUID()) Then Return False
		EndIf


		Return True
	End Method
End Type