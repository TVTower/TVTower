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

Type TVTNewsType
	const InitialNews:int = 0
	const InitialNewsByInGameEvent:int = 1
	const FollowingNews:int = 2
End Type


Type TVTNewsHandling
	const FixMessage:Int = 1
	const DynamicMessage:Int = 2
End Type


Type TVTNewsGenre
	const Politics_Economy:int = 0
	const ShowBiz:int = 1
	const Sport:int = 2
	const Technics_Media:int = 3
	const CurrentAffairs:int = 4
End Type


Type TVTNewsEffect
	const None:int = 0
	const ChangeMaxAudience:int = 1
	const ChangeTrend:int = 2
	const TerroristAttack:int = 4
End Type


'"product" in the DB
Type TVTProgrammeType
	const Undefined:int = 0
	const Movie:int = 1
	const Series:int = 2
	const Show:int = 3
	const Reportage:int = 4
	const Commercial:int = 5
	const CallIn:int = 6
	const Event:int = 7
	const Misc:int = 8
End Type


Type TVTProgrammeGenre
	const Undefined:int = 0
 
	'Movie-Genre 1+
	const Adventure:int = 1
	const Action:int = 2
	const Animation:int = 3
	const Crime:int = 4
	const Comedy:int = 5
	const Documentary:int = 6
	const Drama:int = 7
	const Erotic:int = 8
	const Family:int = 9
	const Fantasy:int = 10
	const History:int = 11
	const Horror:int = 12
	const Monumental:int = 13
	const Mystery:int = 14
	const Romance:int = 15
	const SciFi:int = 16
	const Thriller:int = 17
	const Western:int = 18

	'Show-Genre 100+
	const Show:int = 100			'Shows Allgemein
	const ShowPolitics:int = 101	'Polit-Talks
	const ShowMusic:int = 102		'Musik-Sendungen

	'Event-Genre 200+
	const Event:int	= 200			'allgemeine "Ereignisse"
	const EventPolitics:int = 201	'Wahlen, Große Reden, Bundestagsdebatte
	const EventMusic:int = 202		'AC/DC-Konzert
	const EventSport:int = 203		'Fussball WM, Olymische Spiele
	const EventShowbiz:int = 204	'Oscarverleihung, Golden Globes, Gala-Abend
 
	'Reportage-Genre 300+
	const Feature:int = 300
	const FeatureYellowPress:int = 301

	'returns a textual version of the id
	Function GetGenreStringID:string(id:int)
		Select id
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


Type TVTProgrammeFlag
	const Live:Int = 1		'Genereller Quotenbonus!
	const Animation:Int = 2	'Bonus bei Kindern / Jugendlichen. Malues bei Rentnern / Managern.
	const Culture:Int = 4	'Bonus bei Betty und bei Managern
	const Cult:Int = 8		'Verringert die Nachteile des Filmalters. Bonus bei Rentnern. Höhere Serientreue bei Serien.
	const Trash:Int = 16	'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern und Managern. Trash läuft morgens und mittags gut => Bonus!
	const BMovie:Int = 32	'Nochmal deutlich verringerter Preis. Verringert die Nachteile des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen Zielgruppen. Bonus in der Nacht!
	const XRated:Int = 64	'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, (Männer). Kleiner Malus für Kinder, Hausfrauen, Rentner, (Frauen).
	const Paid:Int = 128	'Call-In-Shows
	const Series:Int = 256	'Ist ne Serie! Vielleicht besser als den ProgrammeType... so kann auch ne Reportage ne Serie sein.
End Type


Type TVTTargetGroup
	const All:int = 0
	const Children:int = 1
	const Teenagers:int = 2
	const HouseWifes:int = 4
	const Employees:int = 8
	const Unemployed:int = 16
	const Manager:int = 32
	const Pensioners:int = 64
	const Women:int = 128
	const Men:int = 256
End Type


Type TVTPressureGroup
	const None:int = 0
	const SmokerLobby:int = 1
	const AntiSmoker:int = 2
	const ArmsLobby:int = 4
	const Pacifists:int = 8
	const Capitalists:int = 16
	const Communists:int = 32
End Type