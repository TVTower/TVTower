SuperStrict
Import "game.world.worldtime.bmx"
Import "game.production.productionconcept.bmx"
Import "game.production.script.bmx"
Import "game.broadcastmaterial.news.bmx"

Type TProductionCollection Extends TGameObjectCollection
	Field latestProductionByRoom:TMap = CreateMap()
	Global _instance:TProductionCollection
	
	'override
	Function GetInstance:TProductionCollection()
		if not _instance then _instance = new TProductionCollection
		return _instance
	End Function


	'override to store latest production on a per-room-basis
	Method Add:int(obj:TGameObject)
		local p:TProduction = TProduction(obj)
		if p
			local roomGUID:string = p.studioGUID
			if roomGUID <> ""
				'if the production is newer than a potential previous
				'production, replace the previous with the new one 
				local previousP:TProduction = GetProductionByRoom(roomGUID)
				if previousP and previousP.startDate < p.startDate
					latestProductionByRoom.Insert(roomGUID, p)
				endif
			endif
		endif

		super.Add(obj)
	End Method


	Method GetProductionByRoom:TProduction(roomGUID:string)
		local p:TProduction = TProduction(latestProductionByRoom.ValueForKey(roomGUID))
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProductionCollection:TProductionCollection()
	Return TProductionCollection.GetInstance()
End Function




Type TProduction Extends TGameObject
	Field concept:TProductionConcept
	'in which room was/is this production recorded (might no longer
	'be a studio!)
	Field studioGUID:string
	Field newsTopic:TNews = null
	Field guests:TList
	Field reporters:TList
	Field additionalBudget:Int
	'0 = waiting, 1 = running, 2 = finished
	Field status:Int = 0
	Field startDate:Double
	Field endDate:Double


	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "production-"+id
		self.GUID = GUID
	End Method


	Method GetScript:TScript()
		Return concept.script
	End Method
	

	Method Start()
		startDate = GetWorldTime().GetTimeGone()
		endDate = startDate + 500 * 60 '500 minutes
	End Method


	Method Finalize()
		'Local genreDefinition:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(concept.script.genre)

		'change skills of the actors / director / ...
	End Method
End Type