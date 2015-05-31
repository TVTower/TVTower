Rem
	====================================================================
	File contains game specific constants.

	Keep this in sync with the external database so exports wont
	break things apart.
	====================================================================
EndRem	
SuperStrict


Global TVTDebugInfos:int = False
Global TVTDebugQuoteInfos:int = False	
Global TVTGhostBuildingScrollMode:int = False

'collection of all constants types (so it could be exposed
'to LUA in one step)
Type TVTGameConstants {_exposeToLua}
	Field NewsType:TVTNewsType = new TVTNewsType
	Field NewsHandling:TVTNewsHandling = new TVTNewsHandling
	Field NewsGenre:TVTNewsGenre = new TVTNewsGenre
	Field NewsEffect:TVTNewsEffect = new TVTNewsEffect

	Field PlayerFinanceEntryType:TVTPlayerFinanceEntryType = new TVTPlayerFinanceEntryType

	Field ProgrammeProductType:TVTProgrammeProductType = new TVTProgrammeProductType
	Field ProgrammeGenre:TVTProgrammeGenre = new TVTProgrammeGenre 
	Field ProgrammeFlag:TVTProgrammeFlag = new TVTProgrammeFlag 
	Field ProgrammeLicenceType:TVTProgrammeLicenceType = new TVTProgrammeLicenceType 

	Field TargetGroup:TVTTargetGroup = new TVTTargetGroup 
	Field PressureGroup:TVTPressureGroup = new TVTPressureGroup 

	Field PersonGender:TVTPersonGender = new TVTPersonGender 
	Field ProgrammePersonJob:TVTProgrammePersonJob = new TVTProgrammePersonJob
End Type
Global GameConstants:TVTGameConstants = New TVTGameConstants




Type TVTNewsType {_exposeToLua}
	Const InitialNews:int = 0
	Const InitialNewsByInGameEvent:int = 1
	Const FollowingNews:int = 2
End Type




Type TVTNewsHandling {_exposeToLua}
	Const FixMessage:Int = 1
	Const DynamicMessage:Int = 2
End Type




Type TVTNewsGenre {_exposeToLua}
	Const POLITICS_ECONOMY:int = 0
	Const SHOWBIZ:int = 1
	Const SPORT:int = 2
	Const TECHNICS_MEDIA:int = 3
	Const CURRENTAFFAIRS:int = 4
	Const count:int = 5


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
			default                 return "unknown"
		end select
	End Function
End Type




Type TVTNewsEffect {_exposeToLua}
	Const NONE:int = 0
	Const CHANGEMAXAUDIENCE:int = 1
	Const CHANGETREND:int = 2
	Const TERRORISTATTACK:int = 4
End Type





'to ease access to "comparisons" without knowing
'the licence object itself
Type TVTProgrammeLicenceType {_exposeToLua}
	Const UNKNOWN:int    = 0
	Const SINGLE:int     = 1 'eg. movies, one-time-events...
	Const EPISODE:int    = 2 'episodes of a series
	Const SERIES:int     = 3 'header of series
	Const COLLECTION:int = 4 'header of collections
	Const FRANCHISE:int  = 5 'header of franchises ("SAW", "Indiana Jones", ...)


	Function GetAtIndex:int(index:int = 0)
		return index
	End Function


	Function GetAsString:String(key:int = 0)
		Select key
			case EPISODE     return "episode"
			case SERIES      return "series"
			case SINGLE      return "single"
			case COLLECTION  return "collection"
			case FRANCHISE   return "franchise"
			default          return "unknown"
		End Select
	End Function
End Type




'"product" in the DB
Type TVTProgrammeProductType {_exposeToLua}
	Const UNDEFINED:int = 0         '0
	Const MOVIE:int = 1             '1	'movies
	Const SERIES:int = 2            '2  'series with a "story"
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

	Const SELL_MISC:int = 31                    '6
	Const PAY_MISC:int = 32                     '7

	Const SELL_PROGRAMMELICENCE:int = 41        '8
	Const PAY_PROGRAMMELICENCE:int = 42         '9
	Const PAYBACK_AUCTIONBID:int = 43           '10
	Const PAY_AUCTIONBID:int = 44               '11

	Const EARN_CALLERREVENUE:int = 51           '12
	Const EARN_INFOMERCIALREVENUE:int = 52      '13
	Const EARN_ADPROFIT:int = 53                '14
	Const EARN_SPONSORSHIPREVENUE:int = 54      '15
	Const PAY_PENALTY:int = 55                  '16

	Const PAY_SCRIPT:int = 61                   '17
	Const SELL_SCRIPT:int = 62                  '18
	Const PAY_RENT:int = 63                     '19
	Const PAY_PRODUCTIONSTUFF:int = 64          '20

	Const PAY_NEWS:int = 71                     '21
	Const PAY_NEWSAGENCIES:int = 72             '22

	Const PAY_CREDITINTEREST:int = 81           '23
	Const PAY_DRAWINGCREDITINTEREST:int = 82    '24
	Const EARN_BALANCEINTEREST:int = 83         '25
	
	Const CHEAT:int = 1000                      '26

	Const count:int = 27                        'index 0 - 26

	'groups
	Const GROUP_NEWS:int = 1
	Const GROUP_PROGRAMME:int = 2
	Const GROUP_DEFAULT:int = 3
	Const GROUP_PRODUCTION:int = 4
	Const GROUP_STATION:int = 5

	Const groupCount:int = 5


	Function GetAtIndex:int(index:int)
		if index >= 11 and index <= 12 then return index
		if index >= 21 and index <= 23 then return index
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

			case SELL_MISC                  return "sell_misc"
			case PAY_MISC                   return "pay_misc"

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
			Case PAY_STATION, SELL_STATION, PAY_STATIONFEES
				Return GROUP_STATION
			Case SELL_MISC, PAY_MISC
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

	'Show-Genre 100+
	Const Show:int = 100			'Shows Allgemein
	Const Show_Politics:int = 101	'Polit-Talks
	Const Show_Music:int = 102		'Musik-Sendungen

	'Event-Genre 200+
	Const Event:int	= 200			'allgemeine "Ereignisse"
	Const Event_Politics:int = 201	'Wahlen, Große Reden, Bundestagsdebatte
	Const Event_Music:int = 202		'AC/DC-Konzert
	Const Event_Sport:int = 203		'Fussball WM, Olymische Spiele
	Const Event_Showbiz:int = 204	'Oscarverleihung, Golden Globes, Gala-Abend
 
	'Reportage-Genre 300+
	Const Feature:int = 300
	Const Feature_YellowPress:int = 301

	Const genreMaximum:Int = 301


	Function GetAtIndex:int(index:int)
		if index >= 1 and index <= 18 then return index
		if index >= 100 and index <= 102 then return index
		if index >= 200 and index <= 204 then return index
		if index >= 300 and index <= 301 then return index
		return 0
	End Function

	Function GetByString:int(keyString:string = "")
		Select keyString.toLower()	
			case "adventure"		return ADVENTURE
			case "action"			return ACTION
			case "animation"		return ANIMATION
			case "crime"			return CRIME
			case "comedy"			return COMEDY
			case "documentary"		return DOCUMENTARY
			case "drama"			return DRAMA
			case "erotic"			return EROTIC
			case "family"			return FAMILY
			case "fantasy"			return FANTASY
			case "history"			return HISTORY
			case "horror"			return HORROR
			case "monumental"		return MONUMENTAL
			case "mystery"			return MYSTERY
			case "romance"			return ROMANCE
			case "scifi"			return SCIFI
			case "thriller"			return THRILLER
			case "western"			return WESTERN
			'show-genre 100+
			case show				return SHOW
			case show_music			return SHOW_MUSIC
			case show_politics		return SHOW_POLITICS
			'event-genre 200+
			case event					return EVENT
			case event_politics			return EVENT_POLITICS
			case event_music			return EVENT_MUSIC
			case event_sport			return EVENT_SPORT
			case event_showbiz			return EVENT_SHOWBIZ
			'reportage-genre 300+
			case feature				return FEATURE
			case feature_yellowpress	return FEATURE_YELLOWPRESS

			case undefined			return UNDEFINED
			default					return UNDEFINED
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
			case Event_Showbiz			return "event_showbiz"
			'Reportage-Genre 300+
			case Feature				return "feature"
			case Feature_YellowPress	return "feature_yellowpress"

			case Undefined				return "undefined"
			default						return "undefined"
		End Select
	End Function
End Type




Type TVTProgrammeFlag {_exposeToLua}
	'Genereller Quotenbonus!
	Const LIVE:Int = 1
	'Bonus bei Kindern / Jugendlichen. Malues bei Rentnern / Managern.
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

	Const count:int = 10


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function	


	Function GetAsString:String(key:int = 0)
		Select key
			case LIVE      return "live"
			case ANIMATION return "animation"
			case CULTURE   return "culture"
			case CULT      return "cult"
			case TRASH     return "trash"
			case BMOVIE    return "bmovie"
			case XRATED    return "xrated"
			case PAID      return "paid"
			case SERIES    return "series"
			case SCRIPTED  return "scripted"
			default        return "none"
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
			default          return "all"
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

	
	Function GetAsString:String(key:int = 0)
		Select key
			case SMOKERLOBBY  return "smokerlobby"
			case ANTISMOKER   return "antismoker"
			case ARMSLOBBY    return "armslobby"
			case PACIFISTS    return "pacifists"
			case CAPITALISTS  return "capitalists"
			case COMMUNISTS   return "communists"
			default           return "none"
		End Select
	End Function
End Type




Type TVTPersonGender {_exposeToLua}
	Const UNDEFINED:int = 0
	Const MALE:int = 1
	Const FEMALE:int = 2


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
		return 2^(index-1)
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
End Type
