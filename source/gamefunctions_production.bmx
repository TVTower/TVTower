Type TScript
	Field id:String					= ""
	Field title:string				= ""
	Field description:string		= ""
	Field ownProduction:Int			= false
	Field scriptType:String			= "" '0=movie, 1=series, 2=show, 3=report, (4=newsspecial, 5=live)
	Field genre:Int					= 0
	Field topic:Int					= 0	'Entspricht News-Genre: Medien/Technik, Politik/Wirtschaft, Showbiz, Sport, Tagesgeschehen ODER flexibel = spezielle News (10)

	Field outcome:Float				= 0
	Field review:Float				= 0
	Field speed:Float				= 0
	Field potential:Int				= 0

	Field requireDirector:Int		= 0
	Field requiredHosts:Int			= 0
	Field requiredGuests:Int		= 0
	Field requiredReporters:Int		= 0
	Field requiredStarRoleActorMale:Int		= 0
	Field requiredStarRoleActorFemale:Int	= 0
	Field requiredActorMale:Int		= 0
	Field requiredActorFemale:Int	= 0
	Field requiredMusicians:Int		= 0

	Field allowedGuestTypes:string	= "" '0=director, 1=host, 2=actor, 3=musician, 4=intellectual, 5=reporter(, 6=candidate)

	Field requiredStudioSize:Int	= 1
	Field requireAudience:Int		= 0
	Field coulisseType1:Int			= -1
	Field coulisseType2:Int			= -1
	Field coulisseType3:Int			= -1

	Field targetGroup:Int			= -1

	Field price:Int					= 0
	Field episodes:Int				= 0
	Field blocks:Int				= 0
End Type


Type TProductionConcept
	Field script:TScript

	Field director:TPerson
	Field hosts:TList
	Field reporters:TList
	Field staractors:TList
	Field actors:TList
	Field musicians:TList

	Field audienceSize:int			= 0 '0=keines, 1=klein, 2=mittel, 3=groß

	Field coulisseType1Id:string
	Field coulisseType2Id:string
	Field coulisseType3Id:string

	Field additionalBudget:Int

	Field niveau:Int = 0		'0 - 100
	Field innovation:Int = 0	'0 - 100


	'Optionales für Shows
	Field targetGroup:Int			= -1
	Field live:Int					= false	'mehr Risiko, teurer, mehr Tempo
	Field callInCompetition:Int		= false 'Bonus wie CallIn-Show. Kritik--
	Field trophyMoney:Int			= 0		'je mehr desto mehr Tempo
End Type


Type TProduction
	Field concept:TProductionConcept
	Field studioId:int
	Field newsTopic:TNews			= null
	Field guests:TList
	Field reporters:TList
	Field additionalBudget:Int

	Field status:Int				= 0 '0 = waiting, 1 = running, 2 = finished
	Field endDate:Double

	Method GetScript:TScript()
		Return concept.script
	End Method

	Method Start()
		endDate = GetGameTime().GetTimeGone()
		endDate :+ 500
	End Method

	Method Finalize()
		'Local genreDefinition:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(concept.script.genre)
	End Method


End Type

Type TSkillMap
	Field PowerMod:Int = 1
	Field HumorMod:Int = 1
	Field CharismaMod:Int = 1
	Field EroticAuraMod:Int = 1
	Field CharacterSkillMod:Int = 1
End Type