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
End Type


Type TVTNewsEffect {_exposeToLua}
	Const NONE:int = 0
	Const CHANGEMAXAUDIENCE:int = 1
	Const CHANGETREND:int = 2
	Const TERRORISTATTACK:int = 4
End Type


'"product" in the DB
Type TVTProgrammeType {_exposeToLua}
	Const UNDEFINED:int = 0
	Const MOVIE:int = 1
	Const SERIES:int = 2
	Const EPISODE:int = 3
	Const SHOW:int = 4
	Const REPORTAGE:int = 5
	Const COMMERCIAL:int = 6
	Const EVENT:int = 7
	Const MISC:int = 8

	Const count:int = 9


	Function GetAtIndex:int(index:int)
		'each index has a const, so just return index
		return index
	End Function
	
	
	Function GetTypeString:String(typeKey:int = 0)
		Select typeKey
			case 1  return "movie"
			case 2  return "series"
			case 3  return "episode"
			case 4  return "show"
			case 5  return "reportage"
			case 6  return "commercial"
			case 7  return "event"
			case 8  return "misc"
			case 0  return "undefined"
			default return "undefined"
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
	Const ShowPolitics:int = 101	'Polit-Talks
	Const ShowMusic:int = 102		'Musik-Sendungen

	'Event-Genre 200+
	Const Event:int	= 200			'allgemeine "Ereignisse"
	Const EventPolitics:int = 201	'Wahlen, Große Reden, Bundestagsdebatte
	Const EventMusic:int = 202		'AC/DC-Konzert
	Const EventSport:int = 203		'Fussball WM, Olymische Spiele
	Const EventShowbiz:int = 204	'Oscarverleihung, Golden Globes, Gala-Abend
 
	'Reportage-Genre 300+
	Const Feature:int = 300
	Const FeatureYellowPress:int = 301


	Function GetAtIndex:int(index:int)
		if index >= 1 and index <= 18 then return index
		if index >= 100 and index <= 102 then return index
		if index >= 200 and index <= 204 then return index
		if index >= 300 and index <= 301 then return index
		return 0
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
			case ShowMusic				return "show_music"
			case ShowPolitics			return "show_politics"
			'Event-Genre 200+
			case Event					return "event"
			case EventPolitics			return "event_politics"
			case EventMusic				return "event_music"
			case EventSport				return "event_sport"
			case EventShowbiz			return "event_showbiz"
			'Reportage-Genre 300+
			case Feature				return "feature"
			case FeatureYellowPress		return "feature_yellowpress"

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
	Const SERIES:Int = 256

	Const count:int = 9


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function	
End Type


Type TVTProgrammeLicenceType {_exposeToLua}
	Const UNKNOWN:int    = 1
	Const EPISODE:int    = 2
	Const SERIES:int     = 4
	Const MOVIE:int      = 8
	Const COLLECTION:int = 16


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
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
			case ALL         return "all"
			default          return "all"
		End Select
	End Function
End Type


Type TVTPressureGroup {_exposeToLua}
	Const None:int = 0
	Const SmokerLobby:int = 1
	Const AntiSmoker:int = 2
	Const ArmsLobby:int = 4
	Const Pacifists:int = 8
	Const Capitalists:int = 16
	Const Communists:int = 32
End Type


Type TVTPersonGender {_exposeToLua}
	Const UNDEFINED:int = 0
	Const MALE:int = 1
	Const FEMALE:int = 2
End Type


Type TVTProgrammePersonJob {_exposeToLua}
	Const UNKNOWN:int = 0
	Const DIRECTOR:int = 1
	Const ACTOR:int = 2
	Const WRITER:int = 4
	Const MODERATOR:int = 8 'hosts
	Const MUSICIAN:int = 16
	Const SUPPORTINGACTOR:int = 32
	Const GUEST:int = 64 'show guest or prominent show candidate
	Const REPORTER:int = 128


	Function GetAtIndex:int(index:int = 0)
		if index <= 0 then return 0
		return 2^(index-1)
	End Function

	
	Function GetAsString:string(key:int)
		Select key
			case 0		return "unknown"
			case 1		return "director"
			case 2		return "actor"
			case 4		return "writer"
			case 8		return "moderator"
			case 16		return "musician"
			case 32		return "supportingactor"
			case 64		return "guest"
			case 128	return "reporter"
			default		return "invalidjob"
		End Select
	End Function
End Type
