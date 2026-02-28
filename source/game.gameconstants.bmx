Rem
	====================================================================
	File contains game specific constants.

	Keep this in sync with the external database so exports wont
	break things apart.
	====================================================================
EndRem
SuperStrict

Import "basefunctions.bmx"

Global VersionDate:String = "unknown"
Global VersionString:String = ""
Global CopyrightString:String = ""

Global TVTPlayerCount:Int = 4

Global TVTDebugInfo:Int = False
Global TVTGhostBuildingScrollMode:Int = False

'delegate - replace GetFormattedCurrency by TFunctions.GetFormattedCurrency
Function GetFormattedCurrency:String(money:Long)
	Return TFunctions.GetFormattedCurrency(money)
EndFunction

'collection of all constants types (so it could be exposed
'to LUA in one step)
Type TVTGameConstants {_exposeToLua}
	Field AchievementCategory:TVTAchievementCategory = New TVTAchievementCategory
	Field MessageCategory:TVTMessageCategory = New TVTMessageCategory

	Field AdContractType:TVTAdContractType = New TVTAdContractType

	Field NewsType:TVTNewsType = New TVTNewsType
	Field NewsGenre:TVTNewsGenre = New TVTNewsGenre
	Field GameObjectEffect:TVTGameModifierBase = New TVTGameModifierBase

	Field BroadcastMaterialType:TVTBroadcastMaterialType = New TVTBroadcastMaterialType
	Field BroadcastMaterialSourceFlag:TVTBroadcastMaterialSourceFlag = New TVTBroadcastMaterialSourceFlag

	Field PlayerFinanceEntryType:TVTPlayerFinanceEntryType = New TVTPlayerFinanceEntryType

	Field ProgrammeProductType:TVTProgrammeProductType = New TVTProgrammeProductType
	Field ProgrammeState:TVTProgrammeState = New TVTProgrammeState
	Field ProgrammeGenre:TVTProgrammeGenre = New TVTProgrammeGenre
	Field ProgrammeDataFlag:TVTProgrammeDataFlag = New TVTProgrammeDataFlag
	Field ProgrammeLicenceFlag:TVTProgrammeLicenceFlag = New TVTProgrammeLicenceFlag
	Field ProgrammeLicenceType:TVTProgrammeLicenceType = New TVTProgrammeLicenceType
	Field ProgrammeDistributionChannel:TVTProgrammeDistributionChannel = New TVTProgrammeDistributionChannel

	Field ProductionConceptFlag:TVTProductionConceptFlag = New TVTProductionConceptFlag

	Field StationFlag:TVTStationFlag = New TVTStationFlag

	Field NewsFlag:TVTNewsFlag = New TVTNewsFlag

	Field TargetGroup:TVTTargetGroup = New TVTTargetGroup
	Field PressureGroup:TVTPressureGroup = New TVTPressureGroup

	Field PersonGender:TVTPersonGender = New TVTPersonGender
	'castable, celebrity
	Field PersonFlag:TVTPersonFlag = New TVTPersonFlag
	'job (politician, musician) 
	Field PersonJob:TVTPersonJob = New TVTPersonJob
	'charisma, humor, ...
	Field PersonPersonalityAttribute:TVTPersonPersonalityAttribute = New TVTPersonPersonalityAttribute

	Field ProductionFocus:TVTProductionFocus = New TVTProductionFocus

	Field AwardType:TVTAwardType = New TVTAwardType

	Field StationType:TVTStationType = New TVTStationType
	
	Field RoomFlag:TVTRoomFlag = new TVTRoomFlag
	Field RoomDoorFlag:TVTRoomDoorFlag = new TVTRoomDoorFlag
	Field BuildingTargetType:TVTBuildingTargetType = new TVTBuildingTargetType
	Field FigureTargetFlag:TVTFigureTargetFlag = New TVTFigureTargetFlag
End Type
Global GameConstants:TVTGameConstants = New TVTGameConstants




Type TVTAchievementCategory {_exposeToLua}
	Const ALL:Int = 0
	Const PROGRAMMES:Int = 1
	Const NEWS:Int = 2
	Const STATIONMAP:Int = 4
	Const MISC:Int = 8

	Const count:Int = 4


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case   1	Return 1
			Case   2	Return 2
			Case   4	Return 3
			Case   8	Return 4
		End Select
		Return 0
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case ALL           Return "all"

			Case PROGRAMMES    Return "programmes"
			Case NEWS          Return "news"
			Case STATIONMAP    Return "stationmap"
			Case MISC          Return "misc"

			Default
				'loop through all entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTStationType {_exposeToLua}
	Const UNKNOWN:Int = 0
	Const ANTENNA:Int = 1
	Const CABLE_NETWORK_UPLINK:Int = 2
	Const SATELLITE_UPLINK:Int = 3

	Const count:Int = 3


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return index
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case   1	Return 1
			Case   2	Return 2
			Case   3	Return 3
		End Select
		Return 0
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "unknown"

		Select key
			Case UNKNOWN              Return "unknown"

			Case ANTENNA              Return "antenna"
			Case CABLE_NETWORK_UPLINK Return "cable_network_uplink"
			Case SATELLITE_UPLINK     Return "satellite_uplink"

			Default                   Return "unknown"
		End Select
	End Function
End Type




Type TVTMessageCategory {_exposeToLua}
	Const ALL:Int = 0
	Const MONEY:Int = 1
	Const AWARDS:Int = 2
	Const ACHIEVEMENTS:Int = 4
	Const MISC:Int = 8

	Const count:Int = 4


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case   1	Return 1
			Case   2	Return 2
			Case   4	Return 3
			Case   8	Return 4
		End Select
		Return 0
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case ALL           Return "all"

			Case MONEY         Return "money"
			Case AWARDS        Return "awards"
			Case ACHIEVEMENTS  Return "achievements"
			Case MISC          Return "misc"

			Default
				'loop through all entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTStationFlag {_exposeToLua}
	Const NONE:Int = 0
	Const PAID:Int = 1
	'fixed prices are kept during refresh
	Const FIXED_PRICE:Int = 2
	Const SELLABLE:Int = 4
	Const ACTIVE:Int = 8
	'someone gifted it
	Const GRANTED:Int = 16
	Const NO_RUNNING_COSTS:Int = 32
	Const NO_AGING:Int = 64
	'paid without governmental allowance
	Const ILLEGAL:Int = 128
	Const SHUTDOWN:Int = 256
	Const AUTO_RENEW_PROVIDER_CONTRACT:Int = 512
	Const WARNED_OF_ENDING_CONTRACT:Int = 1024
	Const UPDATE1:Int = 2048
	Const UPDATE2:Int = 4096
	Const UPDATE3:Int = 8192

	Const count:Int = 14


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case    1	Return 1
			Case    2	Return 2
			Case    4	Return 3
			Case    8	Return 4
			Case   16	Return 5
			Case   32	Return 6
			Case   64	Return 7
			Case  128	Return 8
			Case  256	Return 9
			Case  512	Return 10
			Case 1024	Return 11
			Case 2048	Return 12
			Case 4096   Return 13
			Case 8192   Return 14
		End Select
		Return 0
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case NONE                         Return "none"

			Case PAID                         Return "paid"
			Case FIXED_PRICE                  Return "fixed_price"
			Case SELLABLE                     Return "sellable"
			Case ACTIVE                       Return "active"
			Case GRANTED                      Return "granted"
			Case NO_AGING                     Return "no_aging"
			Case NO_RUNNING_COSTS             Return "no_running_costs"
			Case ILLEGAL                      Return "illegal"
			Case SHUTDOWN                     Return "shutdown"
			Case AUTO_RENEW_PROVIDER_CONTRACT Return "auto_renew_provider_contract"
			Case WARNED_OF_ENDING_CONTRACT    Return "warned_of_ending_contract"
			Case UPDATE1                      Return "update1"
			Case UPDATE2                      Return "update2"
			Case UPDATE3                      Return "update3"

			Default
				'loop through all entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTNewsType {_exposeToLua}
	Const InitialNews:Int = 0
	Const InitialNewsByInGameEvent:Int = 1
	Const FollowingNews:Int = 2
	'news with a planned/scripted "happenedtime"
	Const TimedNews:Int = 3
End Type




Type TVTAdContractType {_exposeToLua}
	Const NORMAL:Int = 0
	'only reachable for special events (game start, or by a news trigger)
	Const INGAME:Int = 1
End Type





Type TVTNewsGenre {_exposeToLua}
	Const POLITICS_ECONOMY:Int = 0
	Const SHOWBIZ:Int = 1
	Const SPORT:Int = 2
	Const TECHNICS_MEDIA:Int = 3
	Const CURRENTAFFAIRS:Int = 4
	Const CULTURE:Int = 5
	Const count:Int = 6


	Function GetAtIndex:Int(index:Int)
		'each index has a const, so just return index
		Return index
	End Function


	Function GetAsString:String(key:Int)
		Select key
			Case POLITICS_ECONOMY	Return "politics_economy"
			Case SHOWBIZ            Return "showbiz"
			Case SPORT              Return "sport"
			Case TECHNICS_MEDIA     Return "technics_media"
			Case CURRENTAFFAIRS     Return "currentaffairs"
			Case CULTURE            Return "culture"
			Default                 Return "unknown"
		End Select
	End Function
End Type



Type TVTProductionFocus {_exposeToLua}
	Const NONE:Int = 0
	Const COULISSE:Int = 1
	Const OUTFIT_AND_MASK:Int = 2
	Const TEAM:Int = 3
	Const PRODUCTION_SPEED:Int = 4
	Const VFX_AND_SFX:Int = 5
	Const STUNTS:Int = 6
	Const count:Int = 6


	Function GetAtIndex:Int(index:Int)
		'each index has a const, so just return index
		Return index
	End Function


	Function GetAsString:String(key:Int)
		Select key
			Case COULISSE           Return "coulisse"
			Case OUTFIT_AND_MASK    Return "outfit_and_mask"
			Case TEAM               Return "team"
			Case PRODUCTION_SPEED   Return "production_speed"
			Case VFX_AND_SFX        Return "vfx_and_sfx"
			Case STUNTS             Return "stunts"
			Default                 Return "unknown"
		End Select
	End Function



	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "coulisse"          Return COULISSE
			Case "outfit_and_mask"   Return OUTFIT_AND_MASK
			Case "team"              Return TEAM
			Case "production_speed"  Return PRODUCTION_SPEED
			Case "vfx_and_sfx"       Return VFX_AND_SFX
			Case "stunts"            Return STUNTS
			Default                  Return NONE
		End Select
	End Function
End Type



Type TVTPersonPersonalityAttribute {_exposeToLua}
	Const NONE:Int = 0
	Const POWER:Int = 1
	Const HUMOR:Int = 2
	Const CHARISMA:Int = 3
	Const APPEARANCE:Int = 4
	Const FAME:Int = 5
	Const SCANDALIZING:Int = 6
	Const count:Int = 6


	Function GetAtIndex:Int(index:Int)
		'each index has a const, so just return index
		Return index
	End Function


	Function GetAsString:String(key:Int)
		Select key
			Case POWER          Return "power"
			Case HUMOR          Return "humor"
			Case CHARISMA       Return "charisma"
			Case APPEARANCE     Return "appearance"
			Case FAME           Return "fame"
			Case SCANDALIZING   Return "scandalizing"
			Default             Return "unknown"
		End Select
	End Function



	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "power"        Return POWER
			Case "humor"        Return HUMOR
			Case "charisma"     Return CHARISMA
			Case "appearance"   Return APPEARANCE
			Case "fame"         Return FAME
			Case "scandalizing" Return SCANDALIZING
			Default             Return NONE
		End Select
	End Function
End Type


Type TVTGameModifierBase {_exposeToLua}
	Const NONE:Int = 0
	Const CHANGE_AUDIENCE:Int = 1
	Const CHANGE_TREND:Int = 2
	Const TERRORIST_ATTACK:Int = 4
End Type



Type TVTBroadcastMaterialSourceFlag {_exposeToLua}
	Const UNKNOWN:Int = 0
	'3rd party material might be uncontrollable for the players
	Const THIRD_PARTY_MATERIAL:Int = 1
	Const NOT_CONTROLLABLE:Int = 2
	Const BROADCAST_FIRST_TIME:Int = 4
	'special = Programme->Trailer, Ad->Infomercial
	Const BROADCAST_FIRST_TIME_SPECIAL:Int = 8
	Const BROADCAST_FIRST_TIME_DONE:Int = 16
	Const BROADCAST_FIRST_TIME_SPECIAL_DONE:Int = 32

	'is the material not available at all?
	Const NOT_AVAILABLE:Int = 64
	'expose price of the material - eg. not-yet-aired custom productions
	Const HIDE_PRICE:Int = 128

	Const BROADCAST_LIMIT_ENABLED:Int = 256

	'material never changes from LIVE To LIVEONTAPE
	Const ALWAYS_LIVE:Int = 512

	Const IGNORE_PLAYERDIFFICULTY:Int = 1024
	Const IGNORED_BY_BETTY:Int = 2048
	Const IGNORED_BY_AWARDS:Int = 4096

	'news could be exclusive (investigation done by one tv channel)
	Const EXCLUSIVE_TO_ONE_OWNER:Int = 8192

	'was live_time_fixed, flag was removed
	Const OBSOLETE_CAN_BE_REASSIGNED:Int = 16384

	'keep broadcast time restriction on begin of first broadcast?
	Const KEEP_BROADCAST_TIME_SLOT_ENABLED_ON_BROADCAST:Int = 32768

	Const count:Int = 16


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case     1	Return 1
			Case     2	Return 2
			Case     4	Return 3
			Case     8	Return 4
			Case    16	Return 5
			Case    32	Return 6
			Case    64	Return 7
			Case   128	Return 8
			Case   256	Return 9
			Case   512	Return 10
			Case  1024	Return 11
			Case  2048	Return 12
			Case  4096	Return 13
			Case  8192	Return 14
			Case 16384	Return 15
			Case 32768	Return 16
		End Select
		Return 0
	End Function
End Type



Type TVTBroadcastMaterialType {_exposeToLua}
	Const UNKNOWN:Int      = 1
	Const PROGRAMME:Int    = 2
	Const ADVERTISEMENT:Int= 4
	Const NEWS:Int         = 8
	Const NEWSSHOW:Int     = 16
End Type



Type TVTBroadcastMaterialSourceType {_exposeToLua}
	Const UNKNOWN:Int          = 1
	Const PROGRAMMELICENCE:Int = 2
	Const ADCONTRACT:Int       = 3
	Const NEWS:Int             = 4
End Type



'to ease access to "comparisons" without knowing
'the licence object itself
Type TVTProgrammeDistributionChannel {_exposeToLua}
	Const UNKNOWN:Int    = 0
	Const CINEMA:Int     = 1
	Const TV:Int         = 2 'produced for TV
	Const VIDEO:Int      = 3 'direct to video/dvd/br... (often B-Movies)
	Const count:Int      = 3


	Function GetAtIndex:Int(index:Int = 0)
		Return index
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case CINEMA      Return "cinema"
			Case TV          Return "tv"
			Case VIDEO       Return "video"
			Default          Return "unknown"
		End Select
	End Function
End Type


'same IDs for now
Type TVTProgrammeDataType Extends TVTProgrammeLicenceType {_exposeToLua}
End Type


'to ease access to "comparisons" without knowing
'the licence object itself
Type TVTProgrammeLicenceType {_exposeToLua}
	Const UNKNOWN:Int            = 0
	Const SINGLE:Int             = 1 'eg. movies, one-time-events...
	Const EPISODE:Int            = 2 'episodes of a series
	Const SERIES:Int             = 3 'header of series
	Const COLLECTION:Int         = 4 'header of collections
	Const COLLECTION_ELEMENT:Int = 5 'elements of collections
	Const FRANCHISE:Int          = 6 'header of franchises ("SAW", "Indiana Jones", ...)


	Function GetAtIndex:Int(index:Int = 0)
		Return index
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case EPISODE             Return "episode"
			Case SERIES              Return "series"
			Case SINGLE              Return "single"
			Case COLLECTION          Return "collection"
			Case COLLECTION_ELEMENT  Return "collection_element"
			Case FRANCHISE           Return "franchise"
			Default                  Return "unknown"
		End Select
	End Function
End Type




Type TVTScriptFlag {_exposeToLua}
	Const NONE:Int = 0
	Const TRADEABLE:Int = 1
	'give back to vendor AND SELL it
	Const SELL_ON_REACHING_PRODUCTIONLIMIT:Int = 2
	'give back to vendor WITHOUT SELLING it
	Const REMOVE_ON_REACHING_PRODUCTIONLIMIT:Int = 4
	'when given to pool/vendor, the limits are refreshed to max
	Const POOL_REFILLS_PRODUCTIONLIMITS:Int = 8
	'when given to pool/vendor, the speed/critics are randomized a bit
	Const POOL_RANDOMIZES_ATTRIBUTES:Int = 16
	'when given to pool/vendor, the licence will not be buyable again
	Const POOL_REMOVES_TRADEABILITY:Int = 32
'currently unused!
	'is the script title/description editable?
	Const TEXTS_EDITABLE:Int = 64
'currently unused!
	'more expensive
	Const REQUIRE_AUDIENCE_DURING_PRODUCTION:Int = 128
	Const NOT_AVAILABLE:Int = 256

	Const count:Int = 9


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case   1	Return 1
			Case   2	Return 2
			Case   4	Return 3
			Case   8	Return 4
			Case  16	Return 5
			Case  32	Return 6
			Case  64	Return 7
			Case 128	Return 8
			Case 256	Return 9
		End Select
		Return 0
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case TRADEABLE                            Return "tradeable"
			Case SELL_ON_REACHING_PRODUCTIONLIMIT     Return "sell_on_reaching_productionlimit"
			Case REMOVE_ON_REACHING_PRODUCTIONLIMIT   Return "remove_on_reaching_productionlimit"
			Case POOL_REFILLS_PRODUCTIONLIMITS        Return "pool_refills_productionlimits"
			Case POOL_RANDOMIZES_ATTRIBUTES           Return "pool_randomizes_attributes"
			Case POOL_REMOVES_TRADEABILITY            Return "pool_removes_tradeability"
			Case TEXTS_EDITABLE                       Return "texts_editable"
			Case REQUIRE_AUDIENCE_DURING_PRODUCTION   Return "require_audience_during_production"
			Case NOT_AVAILABLE                        Return "not_available"

			Default
				'loop through all entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("none")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type




Type TVTProgrammeLicenceFlag {_exposeToLua}
	Const NONE:Int = 0
	Const TRADEABLE:Int = 1
	'give back to vendor AND SELL it
	Const SELL_ON_REACHING_BROADCASTLIMIT:Int = 2
	'give back to vendor WITHOUT SELLING it
	Const REMOVE_ON_REACHING_BROADCASTLIMIT:Int = 4
	'when given to pool/vendor, the broadcast limits are refreshed to max
	Const LICENCEPOOL_REFILLS_BROADCASTLIMITS:Int = 8
	'when given to pool/vendor, the topicality is refreshed to max
	Const LICENCEPOOL_REFILLS_TOPICALITY:Int = 16
	'when given to pool/vendor, the licence will not be buyable again
	Const LICENCEPOOL_REMOVES_TRADEABILITY:Int = 32

	Const count:Int = 6


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case   1	Return 1
			Case   2	Return 2
			Case   4	Return 3
			Case   8	Return 4
			Case  16	Return 5
			Case  32	Return 6
		End Select
		Return 0
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case TRADEABLE                            Return "tradeable"
			Case SELL_ON_REACHING_BROADCASTLIMIT      Return "sell_on_reaching_broadcastlimit"
			Case REMOVE_ON_REACHING_BROADCASTLIMIT    Return "remove_on_reaching_broadcastlimit"
			Case LICENCEPOOL_REFILLS_BROADCASTLIMITS  Return "licencepool_refills_broadcastlimits"
			Case LICENCEPOOL_REFILLS_TOPICALITY       Return "licencepool_refills_topicality"
			Case LICENCEPOOL_REMOVES_TRADEABILITY     Return "licencepool_removes_tradeability"

			Default
				'loop through all entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("none")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type



'"product" in the DB
Type TVTProgrammeProductType {_exposeToLua}
	Const UNDEFINED:Int = 0         '0
	Const MOVIE:Int = 1             '1	'movies (fictional)
	Const SERIES:Int = 2            '2  'series with a "story" (fictional)
	Const SHOW:Int = 3              '3
	Const FEATURE:Int = 4           '4  'reportages
	Const INFOMERCIAL:Int = 5       '5
	Const EVENT:Int = 6             '6
	Const MISC:Int = 7              '7

	Const count:Int = 7


	Function GetAtIndex:Int(index:Int)
		'each index has a const, so just return index
		Return index
	End Function


	Function GetAsString:String(typeKey:Int = 0)
		Select typeKey
			Case MOVIE           Return "movie"
			Case SERIES          Return "series"
			Case SHOW            Return "show"
			Case FEATURE         Return "feature"
			Case INFOMERCIAL     Return "infomercial"
			Case EVENT           Return "event"
			Case MISC            Return "misc"
			Default              Return "undefined"
		End Select
	End Function
End Type




Type TVTPlayerFinanceEntryType {_exposeToLua}
	Const UNDEFINED:Int = 0                     '0

	Const CREDIT_REPAY:Int = 11                 '1
	Const CREDIT_TAKE:Int = 12                  '2

	Const PAY_STATION:Int = 21                  '3
	Const SELL_STATION:Int = 22                 '4
	Const PAY_STATIONFEES:Int = 23              '5
	Const PAY_BROADCASTPERMISSION:Int = 24      '6

	Const SELL_MISC:Int = 31                    '7
	Const PAY_MISC:Int = 32                     '8
	Const GRANTED_BENEFITS:Int = 33             '9

	Const SELL_PROGRAMMELICENCE:Int = 41        '10
	Const PAY_PROGRAMMELICENCE:Int = 42         '11
	Const PAYBACK_AUCTIONBID:Int = 43           '12
	Const PAY_AUCTIONBID:Int = 44               '13

	Const EARN_CALLERREVENUE:Int = 51           '14
	Const EARN_INFOMERCIALREVENUE:Int = 52      '15
	Const EARN_ADPROFIT:Int = 53                '16
	Const EARN_SPONSORSHIPREVENUE:Int = 54      '17
	Const PAY_PENALTY:Int = 55                  '18

	Const PAY_SCRIPT:Int = 61                   '19
	Const SELL_SCRIPT:Int = 62                  '20
	Const PAY_RENT:Int = 63                     '21
	Const PAY_PRODUCTIONSTUFF:Int = 64          '22

	Const PAY_NEWS:Int = 71                     '23
	Const PAY_NEWSAGENCIES:Int = 72             '24

	Const PAY_CREDITINTEREST:Int = 81           '25
	Const PAY_DRAWINGCREDITINTEREST:Int = 82    '26
	Const EARN_BALANCEINTEREST:Int = 83         '27


	Const CHEAT:Int = 1000                      '28

	Const count:Int = 29                        'index 0 - 28

	'groups
	Const GROUP_NEWS:Int = 1
	Const GROUP_PROGRAMME:Int = 2
	Const GROUP_DEFAULT:Int = 3
	Const GROUP_PRODUCTION:Int = 4
	Const GROUP_STATION:Int = 5

	Const groupCount:Int = 5


	Function GetAtIndex:Int(index:Int)
		If index >= 11 And index <= 12 Then Return index
		If index >= 21 And index <= 24 Then Return index
		If index >= 31 And index <= 32 Then Return index
		If index >= 41 And index <= 44 Then Return index
		If index >= 51 And index <= 55 Then Return index
		If index >= 61 And index <= 64 Then Return index
		If index >= 71 And index <= 72 Then Return index
		If index >= 81 And index <= 83 Then Return index
		If index = 1000 Then Return index
		Return 0
	End Function


	Function GetGroupAtIndex:Int(index:Int)
		If index >= 1 And index <= 5 Then Return index
		Return GROUP_DEFAULT
	End Function


	'returns a textual version of the id
	Function GetAsString:String(key:Int)
		Select key
			Case CREDIT_REPAY               Return "credit_repay"
			Case CREDIT_TAKE                Return "credit_take"

			Case PAY_STATION                Return "pay_station"
			Case SELL_STATION               Return "sell_station"
			Case PAY_STATIONFEES            Return "pay_stationfees"
			Case PAY_BROADCASTPERMISSION    Return "pay_broadcastpermission"

			Case SELL_MISC                  Return "sell_misc"
			Case PAY_MISC                   Return "pay_misc"
			Case GRANTED_BENEFITS           Return "granted_benefits"

			Case SELL_PROGRAMMELICENCE      Return "sell_programmelicence"
			Case PAY_PROGRAMMELICENCE       Return "pay_programmelicence"
			Case PAYBACK_AUCTIONBID         Return "payback_auctionbid"
			Case PAY_AUCTIONBID             Return "pay_auctionbid"

			Case EARN_CALLERREVENUE         Return "earn_callerrevenue"
			Case EARN_INFOMERCIALREVENUE    Return "earn_infomercialrevenue"
			Case EARN_ADPROFIT              Return "earn_adprofit"
			Case EARN_SPONSORSHIPREVENUE    Return "earn_sponsorshiprevenue"
			Case PAY_PENALTY                Return "pay_penalty"

			Case PAY_SCRIPT                 Return "pay_script"
			Case SELL_SCRIPT                Return "sell_script"
			Case PAY_RENT                   Return "pay_rent"
			Case PAY_PRODUCTIONSTUFF        Return "pay_productionstuff"

			Case PAY_NEWS                   Return "pay_news"
			Case PAY_NEWSAGENCIES           Return "pay_newsagencies"

			Case PAY_CREDITINTEREST         Return "pay_creditinterest"
			Case PAY_DRAWINGCREDITINTEREST  Return "pay_drawingcreditinterest"
			Case EARN_BALANCEINTEREST       Return "earn_balanceinterest"

			Case CHEAT					    Return "cheat"
			Case UNDEFINED				    Return "undefined"
			Default						    Return "undefined"
		End Select
	End Function


	'returns the group an finance type belongs to
	Function GetGroup:Int(typeKey:Int)
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
				Return GROUP_PRODUCTION
			Case PAY_NEWS, PAY_NEWSAGENCIES
				Return GROUP_NEWS
			Case PAY_CREDITINTEREST,..
			     PAY_DRAWINGCREDITINTEREST, ..
			     EARN_BALANCEINTEREST
				Return GROUP_DEFAULT
			Default
				Return GROUP_DEFAULT
		End Select
	End Function


	'returns a textual version of the group id
	Function GetGroupAsString:String(key:Int)
		Select key
			Case GROUP_NEWS                 Return "group_news"
			Case GROUP_PROGRAMME            Return "group_programme"
			Case GROUP_DEFAULT              Return "group_default"
			Case GROUP_PRODUCTION           Return "group_production"
			Case GROUP_STATION              Return "group_station"
			Default                         Return "group_default"
		End Select
	End Function
End Type




Type TVTProgrammeGenre {_exposeToLua}
	Const Undefined:Int = 0

	'Movie-Genre 1+
	Const Adventure:Int = 1
	Const Action:Int = 2
	Const Animation:Int = 3
	Const Crime:Int = 4
	Const Comedy:Int = 5
	Const Documentary:Int = 6
	Const Drama:Int = 7
	Const Erotic:Int = 8
	Const Family:Int = 9
	Const Fantasy:Int = 10
	Const History:Int = 11
	Const Horror:Int = 12
	Const Monumental:Int = 13
	Const Mystery:Int = 14
	Const Romance:Int = 15
	Const SciFi:Int = 16
	Const Thriller:Int = 17
	Const Western:Int = 18

	'ATTENTION:
	'appending new show/event genres needs adjustments in
	'game.programme.programmelicence.bmx: TProgrammeLicenceFilter.Init()

	'Show-Genre 100+
	Const Show:Int = 100			'Shows in general
	Const Show_Politics:Int = 101	'Polit-Talks
	Const Show_Music:Int = 102		'Music shows ("Best of the 50s")
	Const Show_Talk:Int = 103		'Generic talks ("smalltalk")
	Const Show_Game:Int = 104		'Game shows (Quizzes, Wheel of Luck, Guess the Price)

	'Event-Genre 200+
	Const Event:Int	= 200			'generic events
	Const Event_Politics:Int = 201	'Votings, Speeches, Debates
	Const Event_Music:Int = 202		'AC/DC-conzert
	Const Event_Sport:Int = 203		'Soccer-WM, Olympic Games
	Const Event_Showbiz:Int = 204	'Oscars, Golden Globes, red-carpet-events

	'Reportage-Genre 300+
	Const Feature:Int = 300
	Const Feature_YellowPress:Int = 301

	'internal genres
	Const Infomercial:Int = 400		'an advertisement in a programme slot
	Const NewsSpecial:Int = 401		'a news special made out of a news

	Const genreMaximum:Int = 401


	Function GetKey:Int(index:Int)
		Select index
			Case 1   Return Adventure
			Case 2   Return Action
			Case 3   Return Animation
			Case 4   Return Crime
			Case 5   Return Comedy
			Case 6   Return Documentary
			Case 7   Return Drama
			Case 8   Return Erotic
			Case 9   Return Family
			Case 10  Return Fantasy
			Case 11  Return History
			Case 12  Return Horror
			Case 13  Return Monumental
			Case 14  Return Mystery
			Case 15  Return Romance
			Case 16  Return SciFi
			Case 17  Return Thriller
			Case 18  Return Western
			'Show-Genre 100+
			Case 19  Return Show
			Case 20  Return Show_Music
			Case 21  Return Show_Politics
			Case 22  Return Show_Talk
			Case 23  Return Show_Game
			'Event-Genre 200+
			Case 24  Return Event
			Case 25  Return Event_Politics
			Case 26  Return Event_Music
			Case 27  Return Event_Sport
			Case 28  Return Event_Showbiz
			'Feature-Genre 300+
			Case 29  Return Feature
			Case 30  Return Feature_YellowPress
			'Internal-Genre 300+
			Case 31  Return Infomercial
			Case 32  Return NewsSpecial

			Case  0  Return Undefined
			Default  Return Undefined
		End Select
	End Function
	
	
	'new entries MUST be added at the BOTTOM to keep numbers for
	'old savegames intact
	Function GetIndex:Int(key:Int)
		Select key
			Case Adventure				Return 1
			Case Action					Return 2
			Case Animation				Return 3
			Case Crime					Return 4
			Case Comedy					Return 5
			Case Documentary			Return 6
			Case Drama					Return 7
			Case Erotic					Return 8
			Case Family					Return 9
			Case Fantasy				Return 10
			Case History				Return 11
			Case Horror					Return 12
			Case Monumental				Return 13
			Case Mystery				Return 14
			Case Romance				Return 15
			Case SciFi					Return 16
			Case Thriller				Return 17
			Case Western				Return 18
			'Show-Genre 100+
			Case Show					Return 19
			Case Show_Music				Return 20
			Case Show_Politics			Return 21
			Case Show_Talk			    Return 22
			Case Show_Game			    Return 23
			'Event-Genre 200+
			Case Event					Return 24
			Case Event_Politics			Return 25
			Case Event_Music			Return 26
			Case Event_Sport			Return 27
			Case Event_Showbiz          Return 28
			'Feature-Genre 300+
			Case Feature                Return 29
			Case Feature_YellowPress    Return 30
			'Internal-Genre 300+
			Case Infomercial            Return 31
			Case NewsSpecial            Return 32

			Case Undefined				Return 0
			Default						Return 0
		End Select
	End Function


	Function GetGroupKey:Int(key:Int)
		If key >= 0 And key <= 18 Then Return -1
		If key >= 100 And key <= 104 Then Return 100
		If key >= 200 And key <= 204 Then Return 200
		If key >= 300 And key <= 301 Then Return 300
		If key >= 400 And key <= 401 Then Return 400
		Return -1
	End Function


	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "adventure"            Return ADVENTURE
			Case "action"               Return ACTION
			Case "animation"            Return ANIMATION
			Case "crime"                Return CRIME
			Case "comedy"               Return COMEDY
			Case "documentary"          Return DOCUMENTARY
			Case "drama"                Return DRAMA
			Case "erotic"               Return EROTIC
			Case "family"               Return FAMILY
			Case "fantasy"              Return FANTASY
			Case "history"              Return HISTORY
			Case "horror"               Return HORROR
			Case "monumental"           Return MONUMENTAL
			Case "mystery"              Return MYSTERY
			Case "romance"              Return ROMANCE
			Case "scifi"                Return SCIFI
			Case "thriller"             Return THRILLER
			Case "western"              Return WESTERN
			'show-genre 100+
			Case "show"                 Return SHOW
			Case "show_music"		    Return SHOW_MUSIC
			Case "show_politics"	    Return SHOW_POLITICS
			Case "show_talk"	        Return SHOW_TALK
			Case "show_game"	        Return SHOW_GAME
			'event-genre 200+
			Case "event"                Return EVENT
			Case "event_politics"       Return EVENT_POLITICS
			Case "event_music"          Return EVENT_MUSIC
			Case "event_sport"          Return EVENT_SPORT
			Case "event_showbiz"        Return EVENT_SHOWBIZ
			'reportage-genre 300+
			Case "feature"              Return FEATURE
			Case "feature_yellowpress"  Return FEATURE_YELLOWPRESS
			'internal-genre 400+
			Case "infomercial"          Return Infomercial
			Case "newsspecial"          Return NewsSpecial

			Default                     Return UNDEFINED
		End Select
	End Function


	'returns a textual version of the id
	Function GetAsString:String(key:Int)
		Select key
			Case Adventure				Return "adventure"
			Case Action					Return "action"
			Case Animation				Return "animation"
			Case Crime					Return "crime"
			Case Comedy					Return "comedy"
			Case Documentary			Return "documentary"
			Case Drama					Return "drama"
			Case Erotic					Return "erotic"
			Case Family					Return "family"
			Case Fantasy				Return "fantasy"
			Case History				Return "history"
			Case Horror					Return "horror"
			Case Monumental				Return "monumental"
			Case Mystery				Return "mystery"
			Case Romance				Return "romance"
			Case SciFi					Return "scifi"
			Case Thriller				Return "thriller"
			Case Western				Return "western"
			'Show-Genre 100+
			Case Show					Return "show"
			Case Show_Music				Return "show_music"
			Case Show_Politics			Return "show_politics"
			Case Show_Talk			    Return "show_talk"
			Case Show_Game			    Return "show_game"
			'Event-Genre 200+
			Case Event					Return "event"
			Case Event_Politics			Return "event_politics"
			Case Event_Music			Return "event_music"
			Case Event_Sport			Return "event_sport"
			Case Event_Showbiz          Return "event_showbiz"
			'Feature-Genre 300+
			Case Feature                Return "feature"
			Case Feature_YellowPress    Return "feature_yellowpress"
			'Internal-Genre 300+
			Case Infomercial            Return "infomercial"
			Case NewsSpecial            Return "newsspecial"

			Case Undefined				Return "undefined"
			Default
Rem
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
				Return "undefined"
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
	'Produced by players or programme production companies
	Const CUSTOMPRODUCTION:Int = 1024
	'these programmes are hidden from the planner selection
	Const INVISIBLE:Int = 2048
	'a previously "live" programme is now only a "recorded live programme"
	Const LIVEONTAPE:Int = 4096
	'flag that no remake should be produced
	Const NOREMAKE:Int = 8192

	Const count:Int = 13


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case LIVE       Return "live"
			Case ANIMATION  Return "animation"
			Case CULTURE    Return "culture"
			Case CULT       Return "cult"
			Case TRASH      Return "trash"
			Case BMOVIE     Return "bmovie"
			Case XRATED     Return "xrated"
			Case PAID       Return "paid"
			Case SERIES     Return "series"
			Case SCRIPTED   Return "scripted"
			Case INVISIBLE  Return "invisible"
			Case LIVEONTAPE Return "liveontape"
			Case NOREMAKE   Return "noremake"
			Default
				'loop through all flag-entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type


Type TVTProgrammeLifecycleStep
	Const NONE:Int = 0

	Const PREPRODUCTION_STARTED:Int = 1
	Const PREPRODUCTION_FINISHED:Int = 2
	Const PRODUCTION_STARTED:Int = 4
	Const PRODUCTION_FINISHED:Int = 8

	'for live-programme even preproduction is done then
	Const RELEASE_STARTED:Int = 16
	'if a programme is no longer sold, broadcastable on TV, ...
	Const RELEASE_FINISHED:Int = 32
	'for now cinema cannot be live (ignore "experiments")
	Const RELEASE_TO_CINEMA_STARTED:Int = 64
	Const RELEASE_TO_CINEMA_FINISHED:Int = 128
	Const RELEASE_TO_RETAIL_STARTED:Int = 256
	Const RELEASE_TO_RETAIL_FINISHED:Int = 512
	'might be live, so PRODUCTION_FINISHED is not set here
	Const RELEASE_TO_TV_STARTED:Int = 1024
	Const RELEASE_TO_TV_FINISHED:Int = 2048


	'returns a textual version of the id
	Function GetAsString:String(key:Int)
		Select key
			Case NONE                        Return "none"
			Case PREPRODUCTION_STARTED       Return "preproduction_started"
			Case PREPRODUCTION_FINISHED      Return "preproduction_finished"
			Case PRODUCTION_STARTED          Return "production_started"
			Case PRODUCTION_FINISHED         Return "production_finished"
			Case RELEASE_STARTED             Return "release_started"
			Case RELEASE_FINISHED            Return "release_finished"
			Case RELEASE_TO_CINEMA_STARTED   Return "release_to_cinema_started"
			Case RELEASE_TO_CINEMA_FINISHED  Return "release_to_cinema_finished"
			Case RELEASE_TO_RETAIL_STARTED   Return "release_to_retail_started"
			Case RELEASE_TO_RETAIL_FINISHED  Return "release_to_retail_finished"
			Case RELEASE_TO_TV_STARTED       Return "release_to_tv_started"
			Case RELEASE_TO_TV_FINISHED      Return "release_to_tv_finished"
			Default                          Return "none"
		End Select
	End Function
End Type


Type TVTRoomFlag
	Const NONE:Int = 0

	'can this room be used as a studio?
	Const USABLE_AS_STUDIO:Int = 1
	'is it used as studio now?
	Const USED_AS_STUDIO:Int = 2
	'can this room be rented or is it still occupied?
	Const IS_RENTED:Int = 4
	'can this room be rented at all or is it in possession of the owner?
	'use this for office, news room, boss, archive, movieagency, adagency...
	Const FREEHOLD:Int = 8
	'forbid more occupants than one (eg. room plan)?
	Const RESTRICT_TO_SINGLE_OCCUPANT:Int = 16
	'is this a room or just a "plan" or "view"
	Const FAKE_ROOM:Int = 32
	'can the rental state of a room be changed in this moment
	'(eg. an object in the room blocks rental cancelation)
	Const RENTAL_CHANGE_BLOCKED:Int = 64
	'room/view can be entered by anybody at any time
	'even if the figures would "disallow each other"
	Const NEVER_RESTRICT_OCCUPANT_NUMBER:Int = 128
End Type


Type TVTRoomDoorFlag
	Const NONE:Int = 0

	'can this room door be "targeted/clicked" while on a different floor?
	'if not, then only the "coordinates" are used instead of "entering"
	'at the end
	Const ONLY_TARGETABLE_ON_SAME_FLOOR:Int = 1
	Const SHOW_TOOLTIP:Int = 2
	Const TOOLTIP_ONLY_ON_SAME_FLOOR:Int = 4
End Type


Type TVTBuildingTargetType
	Const NONE:Int = 0
	Const DOOR:Int = 1
	Const HOTSPOT:Int = 2
End Type


Type TVTFigureTargetFlag
	Const NONE:Int = 0
	Const SET_FIGURE_UNCONTROLLABLE:Int = 1
	Const MUST_BE_IN_BUILDING_TO_START:Int = 2
	Const CREATED_BY_DEVSHORTCUT:Int = 4
End Type



Type TVTProgrammeLifecycleFlag
	Const NONE:Int = 0

	Const RELEASES_TO_CINEMA:Int = 1
	Const RELEASES_TO_VIDEOSTORE:Int = 2
	Const RELEASES_TO_RETAIL:Int = 4
	Const RELEASES_TO_TV:Int = 8

	Const ALL:Int = 1 | 2 | 4 | 8
End Type




Type TVTProgrammeState {_exposeToLua}
	Const NONE:Int = 0
	Const IN_PRODUCTION:Int = 1
	Const IN_CINEMA:Int = 2
	Const RELEASED:Int = 3

	Const count:Int = 4


	Function GetAtIndex:Int(index:Int)
		If index >= 0 And index < count Then Return index
		Return 0
	End Function


	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "none"            Return NONE
			Case "in_production"   Return IN_PRODUCTION
			Case "in_cinema"       Return IN_CINEMA
			Case "released"        Return RELEASED
			Default                Return NONE
		End Select
	End Function


	'returns a textual version of the id
	Function GetAsString:String(key:Int)
		Select key
			Case NONE           Return "none"
			Case IN_PRODUCTION  Return "in_production"
			Case IN_CINEMA      Return "in_cinema"
			Case RELEASED       Return "released"
			Default             Return "none"
		End Select
	End Function
End Type





Type TVTProductionStep {_exposeToLua}
	Const NOT_STARTED:Int = 0
	Const PREPRODUCTION:int = 1
	Const PREPRODUCTION_DONE:int = 2
	Const SHOOTING:int = 3
	Const SHOOTING_DONE:int = 4
	Const FINISHED:Int = 5
	Const ABORTED:Int = 6

	Const count:Int = 7


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return index
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case NOT_STARTED        Return "not_started"
			Case PREPRODUCTION      Return "preproduction"
			Case PREPRODUCTION_DONE Return "preproduction_done"
			Case SHOOTING           Return "shooting"
			Case SHOOTING_DONE      Return "shooting_done"
			Case FINISHED           Return "finished"
			Case ABORTED            Return "aborted"
			Default                 Return "unknown_step"
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
	Const PRODUCTION_FINISHED:Int = 16
	'started production (or preproduction)?
	Const PRODUCTION_STARTED:Int = 32

	Const count:Int = 6


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case LIVE                 Return "live"
			Case CALLIN_COMPETITION   Return "callincompetition"
			Case DEPOSIT_PAID         Return "depositpaid"
			Case BALANCE_PAID         Return "balancepaid"
			Case PRODUCTION_FINISHED  Return "production_finished"
			Case PRODUCTION_STARTED   Return "production_started"
			Default
				'loop through all flag-entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type



Type TVTNewsFlag {_exposeToLua}
	Const SEND_IMMEDIATELY:Int = 1
	'can the event happen again - or only once?
	'eg. dynamically created weather news should set this flag
	'UNUSED IN TNewsEvent -> should belong to TNewsEventTemplate
	Const UNIQUE_EVENT:Int = 2
	'can the "happening" get skipped ("happens later")
	'eg. if no player listens to the genre
	'news like "terrorist will attack" happen in all cases => unskippable
	Const UNSKIPPABLE:Int = 4
	'ignore players' news genre abonnement levels when sending a news 
	'event to them
	Const IGNORE_ABONNEMENTS:Int = 8
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
	'mark if "happen" was processed
	Const HAPPENING_PROCESSED:Int = 512 

	Const count:Int = 9


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "none"

		Select key
			Case SEND_IMMEDIATELY     Return "send_immediately"
			Case UNIQUE_EVENT         Return "unique_event"
			Case UNSKIPPABLE          Return "unskippable"
			Case IGNORE_ABONNEMENTS   Return "ignore_abonnements"
			Case KEEP_TICKER_TIME     Return "keep_ticker_time"
			Case RESET_TICKER_TIME    Return "reset_ticker_time"
			Case RESET_HAPPEN_TIME    Return "reset_happen_time"
			Case SPECIAL_EVENT        Return "special_event"
			Case HAPPENING_PROCESSED  Return "happening_processed"


			Default
				'loop through all flag-entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
End Type



Type TVTTargetGroup {_exposeToLua}
	Const ALL:Int = 0				'0
	Const CHILDREN:Int = 1			'1
	Const TEENAGERS:Int = 2			'2
	Const HOUSEWIVES:Int = 4		'3
	Const EMPLOYEES:Int = 8			'4
	Const UNEMPLOYED:Int = 16		'5
	Const MANAGERS:Int = 32			'6
	Const PENSIONERS:Int = 64		'7
	Const WOMEN:Int = 128			'8
	Const MEN:Int = 256				'9
	'amount of target groups
	Const count:Int = 9
	'without women/men
	Const baseGroupCount:Int = 7
	Global baseGroupIDs:int[]


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	'only returns an index for "nonmixed" target groups
	Function GetIndex:Int(key:Int)
		Select key
			Case CHILDREN    Return 1
			Case TEENAGERS   Return 2
			Case HOUSEWIVES  Return 3
			Case EMPLOYEES   Return 4
			Case UNEMPLOYED  Return 5
			Case MANAGERS    Return 6
			Case PENSIONERS  Return 7
			Case WOMEN       Return 8
			Case MEN         Return 9
		End Select
	End Function


	'returns an array of all hit indexes
	Function GetIndexes:Int[](key:Int = 0)
		If key < 0 Then Return [0]

		Select key
			Case CHILDREN    Return [1]
			Case TEENAGERS   Return [2]
			Case HOUSEWIVES  Return [3]
			Case EMPLOYEES   Return [4]
			Case UNEMPLOYED  Return [5]
			Case MANAGERS    Return [6]
			Case PENSIONERS  Return [7]
			Case WOMEN       Return [8]
			Case MEN         Return [9]
			Default
				'loop through all targetGroup-entries and add them if contained
				Local result:Int[]
				Local index:Int = 0
				Local subID:Int
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					 subID = GetAtIndex(i)
					If key & subID Then result :+ [i]
				Next
				If result.length = 0 Then result = [0]
				Return result
		End Select
	End Function


	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "children"    Return CHILDREN
			Case "teenagers"   Return TEENAGERS
			Case "housewives"  Return HOUSEWIVES
			Case "employees"   Return EMPLOYEES
			Case "unemployed"  Return UNEMPLOYED
			Case "managers"    Return MANAGERS
			Case "pensioners"  Return PENSIONERS
			Case "women"       Return WOMEN
			Case "men"         Return MEN
			Default            Return ALL
		End Select
	End Function


	Function GetIndexAsString:String(index:Int = 0)
		If index <= 0 Then Return "all"

		Select index
			Case 1  Return "children"
			Case 2  Return "teenagers"
			Case 3  Return "housewives"
			Case 4  Return "employees"
			Case 5  Return "unemployed"
			Case 6  Return "managers"
			Case 7  Return "pensioners"
			Case 8  Return "women"
			Case 9  Return "men"
		End Select
	End Function
	

	Function GetAsString:String(key:Int = 0)
		If key < 0 Then Return "all"

		Select key
			Case CHILDREN    Return "children"
			Case TEENAGERS   Return "teenagers"
			Case HOUSEWIVES  Return "housewives"
			Case EMPLOYEES   Return "employees"
			Case UNEMPLOYED  Return "unemployed"
			Case MANAGERS    Return "managers"
			Case PENSIONERS  Return "pensioners"
			Case WOMEN       Return "women"
			Case MEN         Return "men"
			Default
				'loop through all targetGroup-entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "all"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function
	
	
	Function GetBaseGroupIDs:Int[]()
		If baseGroupIDs.length = 0
			baseGroupIDs = new Int[baseGroupCount]
			For Local i:Int = 1 To baseGroupCount
				baseGroupIDs[i-1] = GetAtIndex(i)
			Next
		EndIf
		Return baseGroupIDs
	End Function	
End Type




Type TVTPressureGroup {_exposeToLua}
	Const NONE:Int = 0				'0
	Const SMOKERLOBBY:Int = 1		'1
	Const ANTISMOKER:Int = 2		'2
	Const ARMSLOBBY:Int = 4			'3
	Const PACIFISTS:Int = 8			'4
	Const CAPITALISTS:Int = 16		'5
	Const COMMUNISTS:Int = 32		'6
	Const count:Int = 6


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(key:Int)
		Select key
			Case   1   Return 1
			Case   2   Return 2
			Case   4   Return 3
			Case   8   Return 4
			Case  16   Return 5
			Case  32   Return 6
		End Select
		Return 0
	End Function


	'returns an array of all hit indexes
	Function GetIndexes:Int[](key:Int = 0)
		If key < 0 Then Return [0]

		Select key
			Case SMOKERLOBBY  Return [1]
			Case ANTISMOKER   Return [2]
			Case ARMSLOBBY    Return [3]
			Case PACIFISTS    Return [4]
			Case CAPITALISTS  Return [5]
			Case COMMUNISTS   Return [6]
			Default
				'loop through all targetGroup-entries and add them if contained
				Local result:Int[]
				Local index:Int = 0
				Local subID:Int
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					 subID = GetAtIndex(i)
					If key & subID Then result :+ [i]
				Next
				If result.length = 0 Then result = [0]
				Return result
		End Select
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case SMOKERLOBBY  Return "smokerlobby"
			Case ANTISMOKER   Return "antismoker"
			Case ARMSLOBBY    Return "armslobby"
			Case PACIFISTS    Return "pacifists"
			Case CAPITALISTS  Return "capitalists"
			Case COMMUNISTS   Return "communists"
			Default
				'loop through all pressure group-entries and add them if contained
				Local result:String
				Local index:Int = 0
				'do NOT start with 0 ("all")
				For Local i:Int = 1 To count
					index = GetAtIndex(i)
					If key & index Then result :+ GetAsString(index) + ","
				Next
				If result = "" Then Return "none"
				'remove last comma
				Return result[.. result.length-1]
		End Select
	End Function


	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "smokerlobby" Return SMOKERLOBBY
			Case "antismoker"  Return ANTISMOKER
			Case "armslobby"   Return ARMSLOBBY
			Case "pacifists"   Return PACIFISTS
			Case "capitalists" Return CAPITALISTS
			Case "communists"  Return COMMUNISTS
			Default            Return NONE
		End Select
	End Function
End Type




'don't feel attacked by this naming! "UNDEFINED" includes
'transgenders, maybe transsexuals, unknown lifeforms ... just
'everything which is not called by a male or female pronoun
Type TVTPersonGender {_exposeToLua}
	Const UNDEFINED:Int = 0
	Const MALE:Int = 1
	Const FEMALE:Int = 2
	Const count:Int = 2


	Function GetAtIndex:Int(index:Int = 0)
		Return index
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case MALE    Return "male"
			Case FEMALE  Return "female"
			Default      Return "undefined"
		End Select
	End Function
End Type



Type TVTPersonFlag {_exposeToLua}
	Const UNKNOWN:Int = 0			'not counted...
	Const ACTIVE:Int = 1			'1
	Const FICTIONAL:Int = 2			'2
	' can this person become a celebrity?
	Const CAN_LEVEL_UP:Int = 4		'3
	' can this person _theoretically_ be casted for a production, talkshow guests...
	' (this allows disabling show-guests like "the queen" - which might
	' be guest in an older show)
	Const CASTABLE:Int = 8			'4
	' can this person booked _now_ (eg temporarily not available)
	Const BOOKABLE:Int = 16			'5
	Const CELEBRITY:Int = 32		'6
	Const count:Int = 6				'-> flag amount


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function


	Function GetIndex:Int(flag:Int)
		Select flag
			Case   1	Return 1
			Case   2	Return 2
			Case   4	Return 3
			Case   8	Return 4
			Case  16	Return 5
			Case  32	Return 6
			End Select
		Return 0
	End Function


	Function GetAll:Int[](key:Int)
		Local all:Int[]
		If key < 0 Then Return all

		For Local i:Int = 1 To count
			If key & GetAtIndex(i) Then all :+ [GetAtIndex(i)]
		Next
		Return all
	End Function


	Function GetAsString:String(key:Int)
		Select key
			Case 0		Return "unknown"
			Case 1		Return "active"
			Case 2		Return "fictional"
			Case 4		Return "can_level_up"
			Case 8		Return "castable"
			Case 16		Return "bookable"
			Case 32		Return "celebrity"
			Default		Return "invalidflag"
		End Select
	End Function


	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "unknown"         Return UNKNOWN
			Case "active"          Return ACTIVE
			Case "fictional"       Return FICTIONAL
			Case "can_leve_lup"    Return CAN_LEVEL_UP
			Case "castable"        Return CASTABLE
			Case "bookable"        Return BOOKABLE
			Case "celebrity"       Return CELEBRITY
			Default                Return UNKNOWN
		End Select
	End Function
End Type




Type TVTPersonJob {_exposeToLua}
	Const UNKNOWN:Int = 0			'not counted...
	'CAST / used in custom production
	Const DIRECTOR:Int = 1			'1
	Const ACTOR:Int = 2				'2
	Const SCRIPTWRITER:Int = 4		'3
	Const HOST:Int = 8				'4	"moderators"
	Const MUSICIAN:Int = 16			'5
	Const SUPPORTINGACTOR:Int = 32	'6
	Const GUEST:Int = 64			'7	show guest or prominent show candidate
	Const REPORTER:Int = 128		'8

	Const POLITICIAN:Int = 256		'1   9
	Const PAINTER:Int = 512			'3  10
	Const WRITER:Int = 1024			'4  11
	Const MODEL:Int = 2048			'5  12
	Const SPORTSMAN:Int = 4096		'6  13

	Global CAST_IDs:Int[] = [1,2,4,8,16,32,64,128]
	Global CAST_INDICES:Int[] = [1,2,3,4,5,6,7,8]
	Global CAST_MASK:Int = 1+2+4+8+16+32+64+128
	Global VISIBLECAST_IDs:Int[] = [2,8,16,32,64,128]
	Global VISIBLECAST_INDICES:Int[] = [2,4,5,6,7,8]
	Global VISIBLECAST_MASK:Int = 2+8+16+32+64+128
	Const castCount:Int = 8			'-> 8 production / cast jobs
	Const count:Int = 13			'-> 13 total jobs


	Function GetAtIndex:Int(index:Int = 0)
		If index <= 0 Then Return 0
		Return 1 Shl (index-1)
	End Function

	
	Function GetCastJobAtIndex:Int(index:Int)
		If index <= 0 Then Return 0
		If index > castCount Then Return 0

		Return 1 Shl (index-1)
	End Function


	Function IsCastJobIndex:Int(index:Int)
		If index <= 0 Then Return False
		If index > castCount Then Return False
		Return True
	End Function


	Function IsCastJob:Int(job:Int)
		Return IsCastJobIndex( GetIndex(job) )
	End Function


	Function GetIndex:Int(job:Int)
		Select job
			Case    1	Return 1
			Case    2	Return 2
			Case    4	Return 3
			Case    8	Return 4
			Case   16	Return 5
			Case   32	Return 6
			Case   64	Return 7
			Case  128	Return 8
			Case  512	Return 9
			Case 1024	Return 10
			Case 2048	Return 11
			Case 4096	Return 12
		End Select
		Return 0
	End Function
	
	
	Function GetCastJobs:Int[]()
		Return CAST_IDs
	End Function

	
	Function GetCastJobIndices:Int[]()
		Return CAST_INDICES
	End Function


	Function GetAll:Int[](key:Int)
		Local all:Int[]
		If key < 0 Then Return all

		For Local i:Int = 1 To count
			If key & GetAtIndex(i) Then all :+ [GetAtIndex(i)]
		Next
		Return all
	End Function


	Function GetAsString:String(key:Int, singularForm:Int = True)
		If singularForm
			Select key
				Case 0		Return "unknown"
				Case 1		Return "director"
				Case 2		Return "actor"
				Case 4		Return "scriptwriter"
				Case 8		Return "host"
				Case 16		Return "musician"
				Case 32		Return "supportingactor"
				Case 64		Return "guest"
				Case 128	Return "reporter"
				Case 256	Return "politician"
				Case 512	Return "painter"
				Case 1024	Return "writer"
				Case 2048	Return "model"
				Case 4096	Return "sportsman"				
				Default		Return "invalidjob"
			End Select
		Else
			Select key
				Case 0		Return "unknown"
				Case 1		Return "directors"
				Case 2		Return "actors"
				Case 4		Return "scriptwriters"
				Case 8		Return "hosts"
				Case 16		Return "musicians"
				Case 32		Return "supportingactors"
				Case 64		Return "guests"
				Case 128	Return "reporters"
				Case 256	Return "politicians"
				Case 512	Return "painters"
				Case 1024	Return "writers"
				Case 2048	Return "models"
				Case 4096	Return "sportsmen"				
				Default		Return "invalidjob"
			End Select
		EndIf
	End Function


	Function GetByString:Int(keyString:String = "")
		Select keyString.toLower()
			Case "unknown"         Return UNKNOWN
			Case "director"        Return DIRECTOR
			Case "actor"           Return ACTOR
			Case "scriptwriter"    Return SCRIPTWRITER
			Case "host"            Return HOST
			Case "musician"        Return MUSICIAN
			Case "supportingactor" Return SUPPORTINGACTOR
			Case "guest"           Return GUEST
			Case "reporter"        Return REPORTER
			Case "politician"      Return POLITICIAN
			Case "painter"         Return PAINTER
			Case "writer"          Return WRITER
			Case "model"           Return REPORTER
			Case "sportsman"       Return SPORTSMAN
			Default                Return UNKNOWN
		End Select
	End Function


	Function GetCastJobImportanceMod:Float(key:Int)
		Select key
			Case UNKNOWN
				Return 0.1
			Case DIRECTOR
				Return 0.8
			Case ACTOR
				Return 1.0
			Case SCRIPTWRITER
				Return 0.4
			Case HOST
				Return 1.0
			Case MUSICIAN
				Return 0.4
			Case SUPPORTINGACTOR
				Return 0.3
			Case GUEST
				Return 0.3
			Case REPORTER
				Return 0.8
			Default
				Local result:Float
				Local index:Int = 0
				Local c:Int = 0
				'do NOT start with 0 ("unknown")
				For Local i:Int = 1 To castCount
					index = GetAtIndex(i)
					If key & index
						result :+ GetCastJobImportanceMod(index)
						c :+ 1
					EndIf
				Next
				If c > 0
					result :/ c
				EndIf
				Return result
		End Select
	End Function
End Type




Type TVTAwardType {_exposeToLua}
	Const UNDEFINED:Int = 0
	Const NEWS:Int = 1
	Const CULTURE:Int = 2
	Const AUDIENCE:Int = 3
	Const CUSTOMPRODUCTION:Int = 4
	Const count:Int = 4


	Function GetAtIndex:Int(index:Int = 0)
		Return index
	End Function


	Function GetAsString:String(key:Int = 0)
		Select key
			Case NEWS              Return "news"
			Case CULTURE           Return "culture"
			Case AUDIENCE          Return "audience"
			Case CUSTOMPRODUCTION  Return "customproduction"
			Default                Return "undefined"
		End Select
	End Function
End Type

Type TVTMissionDifficulty
	Const NONE:Int = 0
	Const EASY:Int = 1
	Const NORMAL:Int = 2
	Const HARD:Int = 3
	Const HARDER:Int = 4
	Const HARDEST:Int = 5
End Type
