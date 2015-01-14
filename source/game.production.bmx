SuperStrict
Import "game.world.worldtime.bmx"
Import "game.production.productionconcept.bmx"
Import "game.production.script.bmx"
Import "game.broadcastmaterial.news.bmx"


Type TProduction
	Field concept:TProductionConcept
	Field studioId:int
	Field newsTopic:TNews = null
	Field guests:TList
	Field reporters:TList
	Field additionalBudget:Int
	'0 = waiting, 1 = running, 2 = finished
	Field status:Int = 0
	Field endDate:Double


	Method GetScript:TScript()
		Return concept.script
	End Method
	

	Method Start()
		endDate = GetWorldTime().GetTimeGone()
		endDate :+ 500 * 60 '500 minutes
	End Method


	Method Finalize()
		'Local genreDefinition:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(concept.script.genre)

		'change skills of the actors / director / ...
	End Method
End Type