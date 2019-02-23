Rem
	====================================================================
	File contains game specific constants.

	Keep this in sync with the external database so exports wont
	break things apart.
	====================================================================
EndRem
SuperStrict

Global VersionDate:String = "unknown"
Global VersionString:String = ""
Global CopyrightString:String = ""

Global TVTPlayerCount:int = 4



Global TVTDebugInfos:int = False
Global TVTDebugQuoteInfos:int = False
Global TVTDebugModifierInfos:int = False
Global TVTDebugProgrammePlan:int = False
Global TVTGhostBuildingScrollMode:int = False


'collection of all constants types (so it could be exposed
'to LUA in one step)
Type TVTGameConstants {_exposeToLua}
	Field AchievementCategory:TVTAchievementCategory = new TVTAchievementCategory
	Field MessageCategory:TVTMessageCategory = new TVTMessageCategory

	Field AdContractType:TVTAdContractType = new TVTAdContractType

	Field NewsType:TVTNewsType = new TVTNewsType
	Field NewsGenre:TVTNewsGenre = new TVTNewsGenre
	Field GameObjectEffect:TVTGameModifierBase = new TVTGameModifierBase

	Field BroadcastMaterialType:TVTBroadcastMaterialType = new TVTBroadcastMaterialType
	Field BroadcastMaterialSourceFlag:TVTBroadcastMaterialSourceFlag = new TVTBroadcastMaterialSourceFlag

	Field PlayerFinanceEntryType:TVTPlayerFinanceEntryType = new TVTPlayerFinanceEntryType

	Field ProgrammeProductType:TVTProgrammeProductType = new TVTProgrammeProductType
	Field ProgrammeState:TVTProgrammeState = new TVTProgrammeState
	Field ProgrammeGenre:TVTProgrammeGenre = new TVTProgrammeGenre
	Field ProgrammeDataFlag:TVTProgrammeDataFlag = new TVTProgrammeDataFlag
	Field ProgrammeLicenceFlag:TVTProgrammeLicenceFlag = new TVTProgrammeLicenceFlag
	Field ProgrammeLicenceType:TVTProgrammeLicenceType = new TVTProgrammeLicenceType
	Field ProgrammeDistributionChannel:TVTProgrammeDistributionChannel = new TVTProgrammeDistributionChannel

	Field ProductionConceptFlag:TVTProductionConceptFlag = new TVTProductionConceptFlag

	Field StationFlag:TVTStationFlag = new TVTStationFlag

	Field NewsFlag:TVTNewsFlag = new TVTNewsFlag

	Field TargetGroup:TVTTargetGroup = new TVTTargetGroup
	Field PressureGroup:TVTPressureGroup = new TVTPressureGroup

	Field PersonGender:TVTPersonGender = new TVTPersonGender
	Field ProgrammePersonJob:TVTProgrammePersonJob = new TVTProgrammePersonJob
	Field ProgrammePersonAttribute:TVTProgrammePersonAttribute = new TVTProgrammePersonAttribute

	Field ProductionFocus:TVTProductionFocus = new TVTProductionFocus

	Field AwardType:TVTAwardType = new TVTAwardType

	Field StationType:TVTStationType = new TVTStationType
End Type
Global GameConstants:TVTGameConstants = New TVTGameConstants




Type TVTAchievementCategory {_exposeToLua}
	Const ALL:int = 0
	Const PROGRAMMES:int = 1
	Const NEWS:int = 2
	Const STATIONMAP:int = 4
	Const MISC:int = 8

	Const count:int = 4


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case   1	return 1
			case   2	return 2
			case   4	return 3
			case   8	return 4
		End Select
		return 0
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case ALL           return "all"

			case PROGRAMMES    return "programmes"
			case NEWS          return "news"
			case STATIONMAP    return "stationmap"
			case MISC          return "misc"

			default
				'loop through all entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTStationType {_exposeToLua}
	Const UNKNOWN:int = 0
	Const ANTENNA:int = 1
	Const CABLE_NETWORK_UPLINK:int = 2
	Const SATELLITE_UPLINK:int = 3

	Const count:int = 3


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return index
	End Function


	Function GetIndex:int(key:int)
		Select key
			case   1	return 1
			case   2	return 2
			case   3	return 3
		End Select
		return 0
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "unknown"

		Select key
			case UNKNOWN              return "unknown"

			case ANTENNA              return "antenna"
			case CABLE_NETWORK_UPLINK return "cable_network_uplink"
			case SATELLITE_UPLINK     return "satellite_uplink"

			default                   return "unknown"
		End Select
	End Function
End Type




Type TVTMessageCategory {_exposeToLua}
	Const ALL:int = 0
	Const MONEY:int = 1
	Const AWARDS:int = 2
	Const ACHIEVEMENTS:int = 4
	Const MISC:int = 8

	Const count:int = 4


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case   1	return 1
			case   2	return 2
			case   4	return 3
			case   8	return 4
		End Select
		return 0
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case ALL           return "all"

			case MONEY         return "money"
			case AWARDS        return "awards"
			case ACHIEVEMENTS  return "achievements"
			case MISC          return "misc"

			default
				'loop through all entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTStationFlag {_exposeToLua}
	Const NONE:int = 0
	Const PAID:Int = 1
	'fixed prices are kept during refresh
	Const FIXED_PRICE:Int = 2
	Const SELLABLE:Int = 4
	Const ACTIVE:Int = 8
	'someone gifted it
	Const GRANTED:int = 16
	Const NO_RUNNING_COSTS:int = 32
	Const NO_AGING:int = 64
	'paid without governmental allowance
	Const ILLEGAL:int = 128
	Const SHUTDOWN:int = 256
	Const AUTO_RENEW_PROVIDER_CONTRACT:int = 512
	Const WARNED_OF_ENDING_CONTRACT:int = 1024
	Const UPDATE1:int = 2048
	Const UPDATE2:int = 4096
	Const UPDATE3:int = 8192

	Const count:int = 14


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case    1	return 1
			case    2	return 2
			case    4	return 3
			case    8	return 4
			case   16	return 5
			case   32	return 6
			case   64	return 7
			case  128	return 8
			case  256	return 9
			case  512	return 10
			case 1024	return 11
			case 2048	return 12
			case 4096   return 13
			case 8192   return 14
		End Select
		return 0
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case NONE                         return "none"

			case PAID                         return "paid"
			case FIXED_PRICE                  return "fixed_price"
			case SELLABLE                     return "sellable"
			case ACTIVE                       return "active"
			case GRANTED                      return "granted"
			case NO_AGING                     return "no_aging"
			case NO_RUNNING_COSTS             return "no_running_costs"
			case ILLEGAL                      return "illegal"
			case SHUTDOWN                     return "shutdown"
			case AUTO_RENEW_PROVIDER_CONTRACT return "auto_renew_provider_contract"
			case WARNED_OF_ENDING_CONTRACT    return "warned_of_ending_contract"
			case UPDATE1                      return "update1"
			case UPDATE2                      return "update2"
			case UPDATE3                      return "update3"

			default
				'loop through all entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTNewsType {_exposeToLua}
	Const InitialNews:int = 0
	Const InitialNewsByInGameEvent:int = 1
	Const FollowingNews:int = 2
	'news with a planned/scripted "happenedtime"
	Const TimedNews:int = 3
End Type




Type TVTAdContractType {_exposeToLua}
	Const NORMAL:int = 0
	'only reachable for special events (game start, or by a news trigger)
	Const INGAME:int = 1
End Type





Type TVTNewsGenre {_exposeToLua}
	Const POLITICS_ECONOMY:int = 0
	Const SHOWBIZ:int = 1
	Const SPORT:int = 2
	Const TECHNICS_MEDIA:int = 3
	Const CURRENTAFFAIRS:int = 4
	Const CULTURE:int = 5
	Const count:int = 6


	Function GetAtIndex:int(index:int)
		'each index has a const, so just return index
		return index
	End Function


	Function GetAsString:String(key:Int)
		select key
			case POLITICS_ECONOMY	return "politics_economy"
			case SHOWBIZ            return "showbiz"
			case SPORT              return "sport"
			case TECHNICS_MEDIA     return "technics_media"
			case CURRENTAFFAIRS     return "currentaffairs"
			case CULTURE            return "culture"
			default                 return "unknown"
		end select
	End Function
End Type



Type TVTProductionFocus {_exposeToLua}
	Const NONE:int = 0
	Const COULISSE:int = 1
	Const OUTFIT_AND_MASK:int = 2
	Const TEAM:int = 3
	Const PRODUCTION_SPEED:int = 4
	Const VFX_AND_SFX:int = 5
	Const STUNTS:int = 6
	Const count:int = 6


	Function GetAtIndex:int(index:int)
		'each index has a const, so just return index
		return index
	End Function


	Function GetAsString:String(key:Int)
		select key
			case COULISSE           return "coulisse"
			case OUTFIT_AND_MASK    return "outfit_and_mask"
			case TEAM               return "team"
			case PRODUCTION_SPEED   return "production_speed"
			case VFX_AND_SFX        return "vfx_and_sfx"
			case STUNTS             return "stunts"
			default                 return "unknown"
		end select
	End Function



	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "coulisse"          return COULISSE
			case "outfit_and_mask"   return OUTFIT_AND_MASK
			case "team"              return TEAM
			case "production_speed"  return PRODUCTION_SPEED
			case "vfx_and_sfx"       return VFX_AND_SFX
			case "stunts"            return STUNTS
			default                  return NONE
		End Select
	End Function
End Type



Type TVTProgrammePersonAttribute {_exposeToLua}
	Const NONE:int = 0
	Const SKILL:int = 1
	Const POWER:int = 2
	Const HUMOR:int = 3
	Const CHARISMA:int = 4
	Const APPEARANCE:int = 5
	Const FAME:int = 6
	Const SCANDALIZING:int = 7
	Const count:int = 7


	Function GetAtIndex:int(index:int)
		'each index has a const, so just return index
		return index
	End Function


	Function GetAsString:String(key:Int)
		select key
			case SKILL          return "skill"
			case POWER          return "power"
			case HUMOR          return "humor"
			case CHARISMA       return "charisma"
			case APPEARANCE     return "appearance"
			case FAME           return "fame"
			case SCANDALIZING   return "scandalizing"
			default             return "unknown"
		end select
	End Function



	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "skill"        return SKILL
			case "power"        return POWER
			case "humor"        return HUMOR
			case "charisma"     return CHARISMA
			case "appearance"   return APPEARANCE
			case "fame"         return FAME
			case "scandalizing" return SCANDALIZING
			default             return NONE
		End Select
	End Function
End Type


Type TVTGameModifierBase {_exposeToLua}
	Const NONE:int = 0
	Const CHANGE_AUDIENCE:int = 1
	Const CHANGE_TREND:int = 2
	Const TERRORIST_ATTACK:int = 4
End Type



Type TVTBroadcastMaterialSourceFlag {_exposeToLua}
	Const UNKNOWN:int = 0
	'3rd party material might be uncontrollable for the players
	Const THIRD_PARTY_MATERIAL:int = 1
	Const NOT_CONTROLLABLE:int = 2
	Const BROADCAST_FIRST_TIME:int = 4
	'special = Programme->Trailer, Ad->Infomercial
	Const BROADCAST_FIRST_TIME_SPECIAL:int = 8
	Const BROADCAST_FIRST_TIME_DONE:int = 16
	Const BROADCAST_FIRST_TIME_SPECIAL_DONE:int = 32

	'is the material not available at all?
	Const NOT_AVAILABLE:int = 64
	'expose price of the material - eg. not-yet-aired custom productions
	Const HIDE_PRICE:int = 128

	Const HAS_BROADCAST_LIMIT:int = 256

	'material never changes from LIVE To LIVEONTAPE
	Const ALWAYS_LIVE:int = 512

	Const IGNORE_PLAYERDIFFICULTY:int = 1024
	Const IGNORED_BY_BETTY:int = 2048
	Const IGNORED_BY_AWARDS:int = 4096

	'news could be exclusive (investigation done by one tv channel)
	Const EXCLUSIVE_TO_ONE_OWNER:Int = 8192

	Const count:int = 14


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case    1	return 1
			case    2	return 2
			case    4	return 3
			case    8	return 4
			case   16	return 5
			case   32	return 6
			case   64	return 7
			case  128	return 8
			case  256	return 9
			case  512	return 10
			case 1024	return 11
			case 2048	return 12
			case 4096	return 13
			case 8192	return 14
		End Select
		return 0
	End Function
End Type



Type TVTBroadcastMaterialType {_exposeToLua}
	Const UNKNOWN:int      = 1
	Const PROGRAMME:int    = 2
	Const ADVERTISEMENT:int= 4
	Const NEWS:int         = 8
	Const NEWSSHOW:int     = 16
End Type




'to ease access to "comparisons" without knowing
'the licence object itself
Type TVTProgrammeDistributionChannel {_exposeToLua}
	Const UNKNOWN:int    = 0
	Const CINEMA:int     = 1
	Const TV:int         = 2 'produced for TV
	Const VIDEO:int      = 3 'direct to video/dvd/br... (often B-Movies)
	Const count:int      = 3


	Function GetAtIndex:int(index:int = 0)
		return index
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case CINEMA      return "cinema"
			case TV          return "tv"
			case VIDEO       return "video"
			default          return "unknown"
		End Select
	End Function
End Type


'same IDs for now
Type TVTProgrammeDataType extends TVTProgrammeLicenceType {_exposeToLua}
End Type


'to ease access to "comparisons" without knowing
'the licence object itself
Type TVTProgrammeLicenceType {_exposeToLua}
	Const UNKNOWN:int            = 0
	Const SINGLE:int             = 1 'eg. movies, one-time-events...
	Const EPISODE:int            = 2 'episodes of a series
	Const SERIES:int             = 3 'header of series
	Const COLLECTION:int         = 4 'header of collections
	Const COLLECTION_ELEMENT:int = 5 'elements of collections
	Const FRANCHISE:int          = 6 'header of franchises ("SAW", "Indiana Jones", ...)


	Function GetAtIndex:int(index:int = 0)
		return index
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case EPISODE             return "episode"
			case SERIES              return "series"
			case SINGLE              return "single"
			case COLLECTION          return "collection"
			case COLLECTION_ELEMENT  return "collection_element"
			case FRANCHISE           return "franchise"
			default                  return "unknown"
		End Select
	End Function
End Type




Type TVTScriptFlag {_exposeToLua}
	Const NONE:int = 0
	Const TRADEABLE:int = 1
	'give back to vendor AND SELL it
	Const SELL_ON_REACHING_PRODUCTIONLIMIT:int = 2
	'give back to vendor WITHOUT SELLING it
	Const REMOVE_ON_REACHING_PRODUCTIONLIMIT:int = 4
	'when given to pool/vendor, the limits are refreshed to max
	Const POOL_REFILLS_PRODUCTIONLIMITS:int = 8
	'when given to pool/vendor, the speed/critics are randomized a bit
	Const POOL_RANDOMIZES_ATTRIBUTES:int = 16
	'when given to pool/vendor, the licence will not be buyable again
	Const POOL_REMOVES_TRADEABILITY:int = 32

	Const count:int = 6


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case   1	return 1
			case   2	return 2
			case   4	return 3
			case   8	return 4
			case  16	return 5
			case  32	return 6
		End Select
		return 0
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case TRADEABLE                            return "tradeable"
			case SELL_ON_REACHING_PRODUCTIONLIMIT     return "sell_on_reaching_productionlimit"
			case REMOVE_ON_REACHING_PRODUCTIONLIMIT   return "remove_on_reaching_productionlimit"
			case POOL_REFILLS_PRODUCTIONLIMITS        return "pool_refills_productionlimits"
			case POOL_RANDOMIZES_ATTRIBUTES           return "pool_randomizes_attributes"
			case POOL_REMOVES_TRADEABILITY            return "pool_removes_tradeability"

			default
				'loop through all entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("none")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTProgrammeLicenceFlag {_exposeToLua}
	Const NONE:int = 0
	Const TRADEABLE:int = 1
	'give back to vendor AND SELL it
	Const SELL_ON_REACHING_BROADCASTLIMIT:int = 2
	'give back to vendor WITHOUT SELLING it
	Const REMOVE_ON_REACHING_BROADCASTLIMIT:int = 4
	'when given to pool/vendor, the broadcast limits are refreshed to max
	Const LICENCEPOOL_REFILLS_BROADCASTLIMITS:int = 8
	'when given to pool/vendor, the topicality is refreshed to max
	Const LICENCEPOOL_REFILLS_TOPICALITY:int = 16
	'when given to pool/vendor, the licence will not be buyable again
	Const LICENCEPOOL_REMOVES_TRADEABILITY:int = 32

	Const count:int = 6


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case   1	return 1
			case   2	return 2
			case   4	return 3
			case   8	return 4
			case  16	return 5
			case  32	return 6
		End Select
		return 0
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case TRADEABLE                            return "tradeable"
			case SELL_ON_REACHING_BROADCASTLIMIT      return "sell_on_reaching_broadcastlimit"
			case REMOVE_ON_REACHING_BROADCASTLIMIT    return "remove_on_reaching_broadcastlimit"
			case LICENCEPOOL_REFILLS_BROADCASTLIMITS  return "licencepool_refills_broadcastlimits"
			case LICENCEPOOL_REFILLS_TOPICALITY       return "licencepool_refills_topicality"
			case LICENCEPOOL_REMOVES_TRADEABILITY     return "licencepool_removes_tradeability"

			default
				'loop through all entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("none")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type



'"product" in the DB
Type TVTProgrammeProductType {_exposeToLua}
	Const UNDEFINED:int = 0         '0
	Const MOVIE:int = 1             '1	'movies (fictional)
	Const SERIES:int = 2            '2  'series with a "story" (fictional)
	Const SHOW:int = 3              '3
	Const FEATURE:int = 4           '4  'reportages
	Const INFOMERCIAL:int = 5       '5
	Const EVENT:int = 6             '6
	Const MISC:int = 7              '7

	Const count:int = 7


	Function GetAtIndex:int(index:int)
		'each index has a const, so just return index
		return index
	End Function


	Function GetAsString:String(typeKey:int = 0)
		Select typeKey
			case MOVIE           return "movie"
			case SERIES          return "series"
			case SHOW            return "show"
			case FEATURE         return "feature"
			case INFOMERCIAL     return "infomercial"
			case EVENT           return "event"
			case MISC            return "misc"
			default              return "undefined"
		End Select
	End Function
End Type




Type TVTPlayerFinanceEntryType {_exposeToLua}
	Const UNDEFINED:int = 0                     '0

	Const CREDIT_REPAY:int = 11                 '1
	Const CREDIT_TAKE:int = 12                  '2

	Const PAY_STATION:int = 21                  '3
	Const SELL_STATION:int = 22                 '4
	Const PAY_STATIONFEES:int = 23              '5
	Const PAY_BROADCASTPERMISSION:int = 24      '6

	Const SELL_MISC:int = 31                    '7
	Const PAY_MISC:int = 32                     '8
	Const GRANTED_BENEFITS:int = 33             '9

	Const SELL_PROGRAMMELICENCE:int = 41        '10
	Const PAY_PROGRAMMELICENCE:int = 42         '11
	Const PAYBACK_AUCTIONBID:int = 43           '12
	Const PAY_AUCTIONBID:int = 44               '13

	Const EARN_CALLERREVENUE:int = 51           '14
	Const EARN_INFOMERCIALREVENUE:int = 52      '15
	Const EARN_ADPROFIT:int = 53                '16
	Const EARN_SPONSORSHIPREVENUE:int = 54      '17
	Const PAY_PENALTY:int = 55                  '18

	Const PAY_SCRIPT:int = 61                   '19
	Const SELL_SCRIPT:int = 62                  '20
	Const PAY_RENT:int = 63                     '21
	Const PAY_PRODUCTIONSTUFF:int = 64          '22

	Const PAY_NEWS:int = 71                     '23
	Const PAY_NEWSAGENCIES:int = 72             '24

	Const PAY_CREDITINTEREST:int = 81           '25
	Const PAY_DRAWINGCREDITINTEREST:int = 82    '26
	Const EARN_BALANCEINTEREST:int = 83         '27


	Const CHEAT:int = 1000                      '28

	Const count:int = 29                        'index 0 - 28

	'groups
	Const GROUP_NEWS:int = 1
	Const GROUP_PROGRAMME:int = 2
	Const GROUP_DEFAULT:int = 3
	Const GROUP_PRODUCTION:int = 4
	Const GROUP_STATION:int = 5

	Const groupCount:int = 5


	Function GetAtIndex:int(index:int)
		if index >= 11 and index <= 12 then return index
		if index >= 21 and index <= 24 then return index
		if index >= 31 and index <= 32 then return index
		if index >= 41 and index <= 44 then return index
		if index >= 51 and index <= 55 then return index
		if index >= 61 and index <= 64 then return index
		if index >= 71 and index <= 72 then return index
		if index >= 81 and index <= 83 then return index
		if index = 1000 then return index
		return 0
	End Function


	Function GetGroupAtIndex:int(index:int)
		if index >= 1 and index <= 5 then return index
		return GROUP_DEFAULT
	End Function


	'returns a textual version of the id
	Function GetAsString:string(key:int)
		Select key
			case CREDIT_REPAY               return "credit_repay"
			case CREDIT_TAKE                return "credit_take"

			case PAY_STATION                return "pay_station"
			case SELL_STATION               return "sell_station"
			case PAY_STATIONFEES            return "pay_stationfees"
			case PAY_BROADCASTPERMISSION    return "pay_broadcastpermission"

			case SELL_MISC                  return "sell_misc"
			case PAY_MISC                   return "pay_misc"
			case GRANTED_BENEFITS           return "granted_benefits"

			case SELL_PROGRAMMELICENCE      return "sell_programmelicence"
			case PAY_PROGRAMMELICENCE       return "pay_programmelicence"
			case PAYBACK_AUCTIONBID         return "payback_auctionbid"
			case PAY_AUCTIONBID             return "pay_auctionbid"

			case EARN_CALLERREVENUE         return "earn_callerrevenue"
			case EARN_INFOMERCIALREVENUE    return "earn_infomercialrevenue"
			case EARN_ADPROFIT              return "earn_adprofit"
			case EARN_SPONSORSHIPREVENUE    return "earn_sponsorshiprevenue"
			case PAY_PENALTY                return "pay_penalty"

			case PAY_SCRIPT                 return "pay_script"
			case SELL_SCRIPT                return "sell_script"
			case PAY_RENT                   return "pay_rent"
			case PAY_PRODUCTIONSTUFF        return "pay_productionstuff"

			case PAY_NEWS                   return "pay_news"
			case PAY_NEWSAGENCIES           return "pay_newsagencies"

			case PAY_CREDITINTEREST         return "pay_creditinterest"
			case PAY_DRAWINGCREDITINTEREST  return "pay_drawingcreditinterest"
			case EARN_BALANCEINTEREST       return "earn_balanceinterest"

			case CHEAT					    return "cheat"
			case UNDEFINED				    return "undefined"
			default						    return "undefined"
		End Select
	End Function


	'returns the group an finance type belongs to
	Function GetGroup:int(typeKey:int)
		Select typeKey
			Case CREDIT_REPAY, CREDIT_TAKE
				Return GROUP_DEFAULT
			Case PAY_STATION, SELL_STATION, PAY_STATIONFEES, PAY_BROADCASTPERMISSION
				Return GROUP_STATION
			Case SELL_MISC, PAY_MISC
				Return GROUP_DEFAULT
			Case GRANTED_BENEFITS
				Return GROUP_DEFAULT
			Case SELL_PROGRAMMELICENCE, ..
			     PAY_PROGRAMMELICENCE, ..
			     EARN_CALLERREVENUE, ..
			     EARN_INFOMERCIALREVENUE, ..
			     EARN_SPONSORSHIPREVENUE, ..
			     EARN_ADPROFIT, ..
			     PAY_AUCTIONBID, ..
			     PAYBACK_AUCTIONBID, ..
				 PAY_PENALTY
				Return GROUP_PROGRAMME
			Case PAY_SCRIPT, SELL_SCRIPT, PAY_PRODUCTIONSTUFF, PAY_RENT
				return GROUP_PRODUCTION
			Case PAY_NEWS, PAY_NEWSAGENCIES
				return GROUP_NEWS
			Case PAY_CREDITINTEREST,..
			     PAY_DRAWINGCREDITINTEREST, ..
			     EARN_BALANCEINTEREST
				return GROUP_DEFAULT
			Default
				return GROUP_DEFAULT
		End Select
	End Function


	'returns a textual version of the group id
	Function GetGroupAsString:string(key:int)
		Select key
			case GROUP_NEWS                 return "group_news"
			case GROUP_PROGRAMME            return "group_programme"
			case GROUP_DEFAULT              return "group_default"
			case GROUP_PRODUCTION           return "group_production"
			case GROUP_STATION              return "group_station"
			default                         return "group_default"
		End Select
	End Function
End Type




Type TVTProgrammeGenre {_exposeToLua}
	Const Undefined:int = 0

	'Movie-Genre 1+
	Const Adventure:int = 1
	Const Action:int = 2
	Const Animation:int = 3
	Const Crime:int = 4
	Const Comedy:int = 5
	Const Documentary:int = 6
	Const Drama:int = 7
	Const Erotic:int = 8
	Const Family:int = 9
	Const Fantasy:int = 10
	Const History:int = 11
	Const Horror:int = 12
	Const Monumental:int = 13
	Const Mystery:int = 14
	Const Romance:int = 15
	Const SciFi:int = 16
	Const Thriller:int = 17
	Const Western:int = 18

	'ATTENTION:
	'appending new show/event genres needs adjustments in
	'game.programme.programmelicence.bmx: TProgrammeLicenceFilter.Init()

	'Show-Genre 100+
	Const Show:int = 100			'Shows in general
	Const Show_Politics:int = 101	'Polit-Talks
	Const Show_Music:int = 102		'Music shows ("Best of the 50s")
	Const Show_Talk:int = 103		'Generic talks ("smalltalk")
	Const Show_Game:int = 104		'Game shows (Quizzes, Wheel of Luck, Guess the Price)

	'Event-Genre 200+
	Const Event:int	= 200			'generic events
	Const Event_Politics:int = 201	'Votings, Speeches, Debates
	Const Event_Music:int = 202		'AC/DC-conzert
	Const Event_Sport:int = 203		'Soccer-WM, Olympic Games
	Const Event_Showbiz:int = 204	'Oscars, Golden Globes, red-carpet-events

	'Reportage-Genre 300+
	Const Feature:int = 300
	Const Feature_YellowPress:int = 301

	'internal genres
	Const Infomercial:int = 400		'an advertisement in a programme slot
	Const NewsSpecial:int = 401		'a news special made out of a news

	Const genreMaximum:Int = 401


	Function GetAtIndex:int(index:int)
		if index >= 0 and index <= 18 then return index
		if index >= 100 and index <= 104 then return index
		if index >= 200 and index <= 204 then return index
		if index >= 300 and index <= 301 then return index
		if index >= 400 and index <= 401 then return index
		return -1
	End Function


	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "adventure"            return ADVENTURE
			case "action"               return ACTION
			case "animation"            return ANIMATION
			case "crime"                return CRIME
			case "comedy"               return COMEDY
			case "documentary"          return DOCUMENTARY
			case "drama"                return DRAMA
			case "erotic"               return EROTIC
			case "family"               return FAMILY
			case "fantasy"              return FANTASY
			case "history"              return HISTORY
			case "horror"               return HORROR
			case "monumental"           return MONUMENTAL
			case "mystery"              return MYSTERY
			case "romance"              return ROMANCE
			case "scifi"                return SCIFI
			case "thriller"             return THRILLER
			case "western"              return WESTERN
			'show-genre 100+
			case "show"                 return SHOW
			case "show_music"		    return SHOW_MUSIC
			case "show_politics"	    return SHOW_POLITICS
			case "show_game"	        return SHOW_GAME
			'event-genre 200+
			case "event"                return EVENT
			case "event_politics"       return EVENT_POLITICS
			case "event_music"          return EVENT_MUSIC
			case "event_sport"          return EVENT_SPORT
			case "event_showbiz"        return EVENT_SHOWBIZ
			'reportage-genre 300+
			case "feature"              return FEATURE
			case "feature_yellowpress"  return FEATURE_YELLOWPRESS
			'internal-genre 400+
			case "infomercial"          return Infomercial
			case "newsspecial"          return NewsSpecial

			default                     return UNDEFINED
		End Select
	End Function


	'returns a textual version of the id
	Function GetAsString:string(key:int)
		Select key
			case Adventure				return "adventure"
			case Action					return "action"
			case Animation				return "animation"
			case Crime					return "crime"
			case Comedy					return "comedy"
			case Documentary			return "documentary"
			case Drama					return "drama"
			case Erotic					return "erotic"
			case Family					return "family"
			case Fantasy				return "fantasy"
			case History				return "history"
			case Horror					return "horror"
			case Monumental				return "monumental"
			case Mystery				return "mystery"
			case Romance				return "romance"
			case SciFi					return "scifi"
			case Thriller				return "thriller"
			case Western				return "western"
			'Show-Genre 100+
			case Show					return "show"
			case Show_Music				return "show_music"
			case Show_Politics			return "show_politics"
			'Event-Genre 200+
			case Event					return "event"
			case Event_Politics			return "event_politics"
			case Event_Music			return "event_music"
			case Event_Sport			return "event_sport"
			case Event_Showbiz          return "event_showbiz"
			'Feature-Genre 300+
			case Feature                return "feature"
			case Feature_YellowPress    return "feature_yellowpress"
			'Internal-Genre 300+
			case Infomercial            return "infomercial"
			case NewsSpecial            return "newsspecial"

			case Undefined				return "undefined"
			default
rem
'needs "bitmask"-id-numbers (genre 1, 2, 4, ...)
'until not changed the following is not useable
				'loop through all flag-entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to genreMaximum
					index = GetAtIndex(i)
					if index = 0 then continue
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "undefined"
				'remove last comma
				return result[.. result.length-1]
endrem
				return "undefined"
		End Select
	End Function
End Type




Type TVTProgrammeDataFlag {_exposeToLua}
	'Genereller Quotenbonus!
	Const LIVE:Int = 1
	'Bonus bei Kindern / Jugendlichen. Malus bei Rentnern / Managern.
	Const ANIMATION:Int = 2
	'Bonus bei Betty und bei Managern
	Const CULTURE:Int = 4
	'Verringert die Nachteile des Filmalters. Bonus bei Rentnern.
	'Höhere Serientreue bei Serien.
	Const CULT:Int = 8
	'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern und
	'Managern. Trash läuft morgens und mittags gut => Bonus!
	Const TRASH:Int = 16
	'Nochmal deutlich verringerter Preis. Verringert die Nachteile des
	'Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen
	'Zielgruppen. Bonus in der Nacht!
	Const BMOVIE:Int = 32
	'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, (Männer).
	'Kleiner Malus für Kinder, Hausfrauen, Rentner, (Frauen).
	Const XRATED:Int = 64
	'Call-In-Shows
	Const PAID:Int = 128
	'Ist ne Serie! Vielleicht besser als den ProgrammeType... so kann
	'auch ne Reportage ne Serie sein.
	'-> SERIES bedeutet hier, dass es etwas zusammengehoeriges ist
	'   also klassische Serien, oder so "Dokusoaps"
	Const SERIES:Int = 256
	'Scripted-Shows/Series/Reportages ... Trash-TV!
	Const SCRIPTED:Int = 512
	'Scripted-Shows/Series/Reportages ... Trash-TV!
	Const CUSTOMPRODUCTION:Int = 1024
	'these programmes are hidden from the planner selection
	Const INVISIBLE:Int = 2048
	'a previously "live" programme is now only a "recorded live programme"
	Const LIVEONTAPE:Int = 4096

	Const count:int = 12


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case LIVE       return "live"
			case ANIMATION  return "animation"
			case CULTURE    return "culture"
			case CULT       return "cult"
			case TRASH      return "trash"
			case BMOVIE     return "bmovie"
			case XRATED     return "xrated"
			case PAID       return "paid"
			case SERIES     return "series"
			case SCRIPTED   return "scripted"
			case INVISIBLE  return "invisible"
			case LIVEONTAPE return "liveontape"
			default
				'loop through all flag-entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type


Type TVTProgrammeLifecycleStep
	Const NONE:int = 0

	Const PREPRODUCTION_STARTED:int = 1
	Const PREPRODUCTION_FINISHED:int = 2
	Const PRODUCTION_STARTED:int = 4
	Const PRODUCTION_FINISHED:int = 8

	'for live-programme even preproduction is done then
	Const RELEASE_STARTED:int = 16
	'if a programme is no longer sold, broadcastable on TV, ...
	Const RELEASE_FINISHED:int = 32
	'for now cinema cannot be live (ignore "experiments")
	Const RELEASE_TO_CINEMA_STARTED:int = 64
	Const RELEASE_TO_CINEMA_FINISHED:int = 128
	Const RELEASE_TO_RETAIL_STARTED:int = 256
	Const RELEASE_TO_RETAIL_FINISHED:int = 512
	'might be live, so PRODUCTION_FINISHED is not set here
	Const RELEASE_TO_TV_STARTED:int = 1024
	Const RELEASE_TO_TV_FINISHED:int = 2048


	'returns a textual version of the id
	Function GetAsString:string(key:int)
		Select key
			case NONE                        return "none"
			case PREPRODUCTION_STARTED       return "preproduction_started"
			case PREPRODUCTION_FINISHED      return "preproduction_finished"
			case PRODUCTION_STARTED          return "production_started"
			case PRODUCTION_FINISHED         return "production_finished"
			case RELEASE_STARTED             return "release_started"
			case RELEASE_FINISHED            return "release_finished"
			case RELEASE_TO_CINEMA_STARTED   return "release_to_cinema_started"
			case RELEASE_TO_CINEMA_FINISHED  return "release_to_cinema_finished"
			case RELEASE_TO_RETAIL_STARTED   return "release_to_retail_started"
			case RELEASE_TO_RETAIL_FINISHED  return "release_to_retail_finished"
			case RELEASE_TO_TV_STARTED       return "release_to_tv_started"
			case RELEASE_TO_TV_FINISHED      return "release_to_tv_finished"
			default                          return "none"
		End Select
	End Function
End Type


Type TVTRoomFlag
	Const NONE:int = 0

	'can this room be used as a studio?
	Const USABLE_AS_STUDIO:int = 1
	'is it used as studio now?
	Const USED_AS_STUDIO:int = 2
	'can this room be rented or is it still occupied?
	Const IS_RENTED:int = 4
	'can this room be rented at all or is it in possession of the owner?
	'use this for office, news room, boss, archive, movieagency, adagency...
	Const FREEHOLD:int = 8
	'forbid more occupants than one (eg. room plan)?
	Const RESTRICT_TO_SINGLE_OCCUPANT:int = 16
	'is this a room or just a "plan" or "view"
	Const FAKE_ROOM:int = 32
End Type



Type TVTProgrammeLifecycleFlag
	Const NONE:int = 0

	Const RELEASES_TO_CINEMA:int = 1
	Const RELEASES_TO_VIDEOSTORE:int = 2
	Const RELEASES_TO_RETAIL:int = 4
	Const RELEASES_TO_TV:int = 8

	Const ALL:int = 1 | 2 | 4 | 8
End Type




Type TVTProgrammeState {_exposeToLua}
	Const NONE:int = 0
	Const IN_PRODUCTION:int = 1
	Const IN_CINEMA:int = 2
	Const RELEASED:int = 3

	Const count:int = 4


	Function GetAtIndex:int(index:int)
		if index >= 0 and index < count then return index
		return 0
	End Function


	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "none"            return NONE
			case "in_production"   return IN_PRODUCTION
			case "in_cinema"       return IN_CINEMA
			case "released"        return RELEASED
			default                return NONE
		End Select
	End Function


	'returns a textual version of the id
	Function GetAsString:string(key:int)
		Select key
			case NONE           return "none"
			case IN_PRODUCTION  return "in_production"
			case IN_CINEMA      return "in_cinema"
			case RELEASED       return "released"
			default             return "none"
		End Select
	End Function
End Type



Type TVTProductionConceptFlag {_exposeToLua}
	'live = more risk, more expensive, more speed
	Const LIVE:Int = 1
	'bonus like CallIn-Show. review
	Const CALLIN_COMPETITION:Int = 2
	'deposit payment paid?
	Const DEPOSIT_PAID:Int = 4
	'rest of total payment paid?
	Const BALANCE_PAID:Int = 8
	'finished shooting of this production?
	Const PRODUCED:Int = 16

	Const count:int = 4


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case LIVE               return "live"
			case CALLIN_COMPETITION return "callincompetition"
			case DEPOSIT_PAID       return "depositpaid"
			case BALANCE_PAID       return "balancepaid"
			case PRODUCED           return "produced"
			default
				'loop through all flag-entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type



Type TVTNewsFlag {_exposeToLua}
	Const SEND_IMMEDIATELY:Int = 1
	'can the event happen again - or only once?
	'eg. dynamically created weather news should set this flag
	Const UNIQUE_EVENT:Int = 2
	'can the "happening" get skipped ("happens later")
	'eg. if no player listens to the genre
	'news like "terrorist will attack" happen in all cases => unskippable
	Const UNSKIPPABLE:Int = 4
	'send the news event to all players, regardless of their abonnement
	'level
	Const SEND_TO_ALL:Int = 8
	'keep time for next initial/start news of the very same genre (genre
	'ticker). By default an added news delays next one of a genre
	Const KEEP_TICKER_TIME:Int = 16
	'forcefully reset to the next ticker time - useful for follow up news
	'which would else not reset that time
	Const RESET_TICKER_TIME:Int = 32
	'reset a "initial" happen time once it was used the first time
	Const RESET_HAPPEN_TIME:Int = 64
	'mark news as something special (eg. to emphasize it graphically)
	Const SPECIAL_EVENT:Int = 128
	'invisible events do not create "news" - they only run their "happen"
	'effects
	Const INVISIBLE_EVENT:Int = 256

	Const count:int = 8


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "none"

		Select key
			case SEND_IMMEDIATELY  return "send_immediately"
			case UNIQUE_EVENT      return "unique_event"
			case UNSKIPPABLE       return "unskippable"
			case SEND_TO_ALL       return "send_to_all"
			case KEEP_TICKER_TIME  return "keep_ticker_time"
			case RESET_TICKER_TIME return "reset_ticker_time"
			case RESET_HAPPEN_TIME return "reset_happen_time"
			case SPECIAL_EVENT     return "special_event"


			default
				'loop through all flag-entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type



Type TVTTargetGroup {_exposeToLua}
	Const ALL:int = 0				'0
	Const CHILDREN:int = 1			'1
	Const TEENAGERS:int = 2			'2
	Const HOUSEWIVES:int = 4		'3
	Const EMPLOYEES:int = 8			'4
	Const UNEMPLOYED:int = 16		'5
	Const MANAGER:int = 32			'6
	Const PENSIONERS:int = 64		'7
	Const WOMEN:int = 128			'8
	Const MEN:int = 256				'9
	'amount of target groups
	Const count:int = 9
	'without women/men
	Const baseGroupCount:int = 7

	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	'returns an array of all hit indexes
	Function GetIndexes:int[](key:int = 0)
		if key < 0 then return [0]

		Select key
			case CHILDREN    return [1]
			case TEENAGERS   return [2]
			case HOUSEWIVES  return [3]
			case EMPLOYEES   return [4]
			case UNEMPLOYED  return [5]
			case MANAGER     return [6]
			case PENSIONERS  return [7]
			case WOMEN       return [8]
			case MEN         return [9]
			default
				'loop through all targetGroup-entries and add them if contained
				local result:int[]
				local index:int = 0
				local subID:int
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					 subID = GetAtIndex(i)
					if key & subID then result :+ [i]
				Next
				if result.length = 0 then result = [0]
				return result
		End Select
	End Function


	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "children"    return CHILDREN
			case "teenagers"   return TEENAGERS
			case "housewives"  return HOUSEWIVES
			case "employees"   return EMPLOYEES
			case "unemployed"  return UNEMPLOYED
			case "manager"     return MANAGER
			case "pensioners"  return PENSIONERS
			case "women"       return WOMEN
			case "men"         return MEN
			default            return ALL
		End Select
	End Function


	Function GetAsString:String(key:int = 0)
		if key < 0 then return "all"

		Select key
			case CHILDREN    return "children"
			case TEENAGERS   return "teenagers"
			case HOUSEWIVES  return "housewives"
			case EMPLOYEES   return "employees"
			case UNEMPLOYED  return "unemployed"
			case MANAGER     return "manager"
			case PENSIONERS  return "pensioners"
			case WOMEN       return "women"
			case MEN         return "men"
			default
				'loop through all targetGroup-entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "all"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTPressureGroup {_exposeToLua}
	Const NONE:int = 0				'0
	Const SMOKERLOBBY:int = 1		'1
	Const ANTISMOKER:int = 2		'2
	Const ARMSLOBBY:int = 4			'3
	Const PACIFISTS:int = 8			'4
	Const CAPITALISTS:int = 16		'5
	Const COMMUNISTS:int = 32		'6
	Const count:int = 6


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function


	Function GetIndex:int(key:int)
		Select key
			case   1   return 1
			case   2   return 2
			case   4   return 3
			case   8   return 4
			case  16   return 5
			case  32   return 6
		End Select
		return 0
	End Function


	'returns an array of all hit indexes
	Function GetIndexes:int[](key:int = 0)
		if key < 0 then return [0]

		Select key
			case SMOKERLOBBY  return [1]
			case ANTISMOKER   return [2]
			case ARMSLOBBY    return [3]
			case PACIFISTS    return [4]
			case CAPITALISTS  return [5]
			case COMMUNISTS   return [6]
			default
				'loop through all targetGroup-entries and add them if contained
				local result:int[]
				local index:int = 0
				local subID:int
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					 subID = GetAtIndex(i)
					if key & subID then result :+ [i]
				Next
				if result.length = 0 then result = [0]
				return result
		End Select
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case SMOKERLOBBY  return "smokerlobby"
			case ANTISMOKER   return "antismoker"
			case ARMSLOBBY    return "armslobby"
			case PACIFISTS    return "pacifists"
			case CAPITALISTS  return "capitalists"
			case COMMUNISTS   return "communists"
			default
				'loop through all pressure group-entries and add them if contained
				local result:string
				local index:int = 0
				'do NOT start with 0 ("all")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index then result :+ GetAsString(index) + ","
				Next
				if result = "" then return "none"
				'remove last comma
				return result[.. result.length-1]
		End Select
	End Function


	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "smokerlobby" return SMOKERLOBBY
			case "antismoker"  return ANTISMOKER
			case "armslobby"   return ARMSLOBBY
			case "pacifists"   return PACIFISTS
			case "capitalists" return CAPITALISTS
			case "communists"  return COMMUNISTS
			default            return NONE
		End Select
	End Function
End Type




'don't feel attacked by this naming! "UNDEFINED" includes
'transgenders, maybe transsexuals, unknown lifeforms ... just
'everything which is not called by a male or female pronoun
Type TVTPersonGender {_exposeToLua}
	Const UNDEFINED:int = 0
	Const MALE:int = 1
	Const FEMALE:int = 2
	Const count:int = 2


	Function GetAtIndex:int(index:int = 0)
		return index
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case MALE    return "male"
			case FEMALE  return "female"
			default      return "undefined"
		End Select
	End Function
End Type




Type TVTProgrammePersonJob {_exposeToLua}
	Const UNKNOWN:int = 0			'not counted...
	Const DIRECTOR:int = 1			'1
	Const ACTOR:int = 2				'2
	Const SCRIPTWRITER:int = 4		'3
	Const HOST:int = 8				'4	"moderators"
	Const MUSICIAN:int = 16			'5
	Const SUPPORTINGACTOR:int = 32	'6
	Const GUEST:int = 64			'7	show guest or prominent show candidate
	Const REPORTER:int = 128		'8
	Const count:int = 8				'-> 8 jobs


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 1 shl (index-1)
		'return 2^(index-1)
	End Function


	Function GetIndex:int(job:int)
		Select job
			case   1	return 1
			case   2	return 2
			case   4	return 3
			case   8	return 4
			case  16	return 5
			case  32	return 6
			case  64	return 7
			case 128	return 8
		End Select
		return 0
	End Function


	Function GetAll:int[](key:int)
		local all:int[]
		if key < 0 then return all

		for local i:int = 1 to count
			if key & GetAtIndex(i) then all :+ [GetAtIndex(i)]
		next
		return all
	End Function


	Function GetAsString:string(key:int, singularForm:int = True)
		if singularForm
			Select key
				case 0		return "unknown"
				case 1		return "director"
				case 2		return "actor"
				case 4		return "scriptwriter"
				case 8		return "host"
				case 16		return "musician"
				case 32		return "supportingactor"
				case 64		return "guest"
				case 128	return "reporter"
				default		return "invalidjob"
			End Select
		else
			Select key
				case 0		return "unknown"
				case 1		return "directors"
				case 2		return "actors"
				case 4		return "scriptwriters"
				case 8		return "hosts"
				case 16		return "musicians"
				case 32		return "supportingactors"
				case 64		return "guests"
				case 128	return "reporters"
				default		return "invalidjob"
			End Select
		endif
	End Function


	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()
			case "unknown"         return UNKNOWN
			case "director"        return DIRECTOR
			case "actor"           return ACTOR
			case "scriptwriter"    return SCRIPTWRITER
			case "host"            return HOST
			case "musician"        return MUSICIAN
			case "supportingactor" return SUPPORTINGACTOR
			case "guest"           return GUEST
			case "reporter"        return REPORTER
			default                return UNKNOWN
		End Select
	End Function


	Function GetJobImportanceMod:Float(key:int)
		Select key
			Case UNKNOWN
				return 0.1
			Case DIRECTOR
				return 0.8
			Case ACTOR
				return 1.0
			Case SCRIPTWRITER
				return 0.4
			Case HOST
				return 1.0
			Case MUSICIAN
				return 0.4
			Case SUPPORTINGACTOR
				return 0.3
			Case GUEST
				return 0.3
			Case REPORTER
				return 0.8
			Default
				local result:float
				local index:int = 0
				local count:int = 0
				'do NOT start with 0 ("unknown")
				For local i:int = 1 to count
					index = GetAtIndex(i)
					if key & index
						result :+ GetJobImportanceMod(index)
						count :+ 1
					endif
				Next
				if count > 0
					result :/ count
				endif
				return result
		End Select
	End Function
End Type




Type TVTAwardType {_exposeToLua}
	Const UNDEFINED:int = 0
	Const NEWS:int = 1
	Const CULTURE:int = 2
	Const AUDIENCE:int = 3
	Const CUSTOMPRODUCTION:int = 4
	Const count:int = 4


	Function GetAtIndex:int(index:int = 0)
		return index
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case NEWS              return "news"
			case CULTURE           return "culture"
			case AUDIENCE          return "audience"
			case CUSTOMPRODUCTION  return "customproduction"
			default                return "undefined"
		End Select
	End Function
End Type