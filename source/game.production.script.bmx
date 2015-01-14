SuperStrict
Import "Dig/base.util.localization.bmx"

Type TScript
	Field id:String = ""
	Field owner:int = 0
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field ownProduction:Int	= false
	'0=movie, 1=series, 2=show, 3=report, (4=newsspecial, 5=live)
	Field scriptType:Int = 0
	Field genre:Int = 0
	'News-Genre: Medien/Technik, Politik/Wirtschaft, Showbiz, Sport, Tagesgeschehen ODER flexibel = spezielle News (10)
	Field topic:Int	= 0

	Field outcome:Float	= 0.0
	Field review:Float = 0.0
	Field speed:Float = 0.0
	Field potential:Int	= 0.0

	Field requiredDirectors:Int = 0
	Field requiredHosts:Int = 0
	Field requiredGuests:Int = 0
	Field requiredReporters:Int = 0
	Field requiredStarRoleActorMale:Int	= 0
	Field requiredStarRoleActorFemale:Int = 0
	Field requiredActorMale:Int	= 0
	Field requiredActorFemale:Int = 0
	Field requiredMusicians:Int	= 0

	'0=director, 1=host, 2=actor, 4=musician, 8=intellectual, 16=reporter(, 32=candidate)
	Field allowedGuestTypes:int	= 0

	Field requiredStudioSize:Int = 1
	Field requireAudience:Int = 0
	Field coulisseType1:Int	= -1
	Field coulisseType2:Int	= -1
	Field coulisseType3:Int = -1

	Field targetGroup:Int = -1

	Field price:Int	= 0
	Field episodeScripts:TScript[]
	Field blocks:Int = 0


	Method GetTitle:string()
		if title then return title.Get()
		return ""
	End Method


	Method GetDescription:string()
		if description then return description.Get()
		return ""
	End Method	
End Type