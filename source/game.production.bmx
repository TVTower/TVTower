SuperStrict
Import "game.world.worldtime.bmx"
Import "game.production.productionconcept.bmx"
Import "game.programme.newsevent.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.stationmap.bmx"


Type TProductionCollection Extends TGameObjectCollection
	Field latestProductionByRoom:TMap = CreateMap()
	Global _instance:TProductionCollection
	
	'override
	Function GetInstance:TProductionCollection()
		if not _instance then _instance = new TProductionCollection
		return _instance
	End Function


	'override to _additionally_ store latest production on a
	'per-room-basis
	Method Add:int(obj:TGameObject)
		local p:TProduction = TProduction(obj)
		if p
			local roomGUID:string = p.studioRoomGUID
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




Type TProduction Extends TOwnedGameObject
	Field productionConcept:TProductionConcept
	'in which room was/is this production recorded (might no longer
	'be a studio!)
	Field studioRoomGUID:string
	'0 = waiting, 1 = running, 2 = finished, 3 = aborted/paused
	Field status:Int = 0
	'start of shooting
	Field startDate:Double
	'end of shooting
	Field endDate:Double

	Field scriptGenreFit:Float = -1.0
	Field castFit:Float = -1.0
	Field castSympathyMod:Float = 1.0
	Field productionValueMod:Float = 1.0
	Field effectiveFocusPointsMod:Float = 1.0


	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "production-"+id
		self.GUID = GUID
	End Method


	Method SetProductionConcept(concept:TProductionConcept)
		productionConcept = concept
	End Method


	Method IsInProduction:int()
		return status = 1
	End Method


	Method IsProduced:int()
		return status = 2
	End Method


	Method SetStudio:int(studioGUID:string)
		studioRoomGUID = studioGUID
		return True
	End Method


	'returns a modificator to a script's intrinsic values (speed, review..)
	Method GetProductionValueMod:Float()
		local value:Float
		value = 0.4 * scriptGenreFit + 0.5 * castFit

		'sympathy of the cast influences result a bit
		value :+ 0.1 * (castSympathyMod - 1.0)

		'it is important to set the production priority according
		'to the genre
		value :* 1.00 * effectiveFocusPointsMod

		return value
	End Method


	Method Start:TProduction()
		print "start production"
		startDate = GetWorldTime().GetTimeGone()
		endDate = startDate + productionConcept.GetBaseProductionTime() * 3600

		status = 1



		'=== 1. CALCULATE BASE PRODUCTION VALUES ===

		'=== 1.1 CALCULATE FITS ===

		'=== 1.1.1 GENRE ===
		'Compare genre definition with script values (expected vs real)
		scriptGenreFit = productionConcept.script.CalculateGenreCriteriaFit() 

		'=== 1.1.2 CAST ===
		'Calculate how the selected cast fits to their assigned jobs
		castFit = productionConcept.CalculateCastFit() 


		'=== 1.2 INDIVIDUAL IMPROVEMENTS ===

		'=== 1.2.1 CAST SYMPATHY ===
		'improve cast job by "sympathy" (they like your channel, so they
		'do a slightly better job)
		castSympathyMod = 1.0 + productionConcept.CalculateCastSympathy()

		'=== 1.2.2 MODIFY PRODUCTION VALUE ===
		effectiveFocusPointsMod = 1.0 + productionConcept.GetEffectiveFocusPointsRatio()

		rem
		print "---------"
		print "scriptGenreFit:          " + scriptGenreFit
		print "castFit:                 " + castFit
		print "castSympathyMod:         " + castSympathyMod
		print "effectiveFocusPointsMod: " + effectiveFocusPointsMod
		endrem



		'=== 2. PRODUCTION EFFECTS ===
		'modify production time (longer by random chance?)

		return self
	End Method


	Method Abort:TProduction()
		print "abort production"

		status = 3

		return self
	End Method


	Method Finalize:TProduction()
		status = 2

		print "Dreharbeiten beendet - Programm herstellen"

		'inform script about a done production based on the script
		productionConcept.script.productionCount :+ 1
		'same for the concept itself
		productionConcept.SetFlag(TVTProductionConceptFlag.PRODUCED, true)


		'=== 1. PRODUCTION EFFECTS ===
		'- modify production values (random..)
		'- cast:
		'- - levelups / skill adjustments / XP gain
		'- - adding the job (if not done automatically) so it becomes
		'    specialized for this kind of production somewhen

		'=== 1.1 PRODUCTION VALUES ===
		local productionValueMod:Float = GetProductionValueMod()
		'by 5% chance increase value and 5% chance to decrease
		'- so bad productions create a superior programme (or even worse)
		'- or blockbusters fail for unknown reasons (or get even better)
		if RandRange(0,100) < 5 then productionValueMod = Max(productionValueMod*1.5, productionValueMod + RandRange(5,35)/100.0)
		if RandRange(0,100) < 5 then productionValueMod = Min(productionValueMod*0.5, productionValueMod - RandRange(5,35)/100.0)
		print "Produktionswert: "+GetProductionValueMod()
		print "Produktionswert end: "+productionValueMod

		'by 5% chance increase or lower price regardless of value
		local productionPriceMod:Float = 1.0
		if RandRange(0,100) < 5 then productionPriceMod :+ RandRange(5,35)/100.0
		if RandRange(0,100) < 5 then productionPriceMod :- RandRange(5,35)/100.0
		
		

		'=== 1.2 CAST ===
		'change skills of the actors / director / ...



		'=== 2. PROGRAMME CREATION ===
		local programmeData:TProgrammeData = new TProgrammeData
		programmeData.GUID = "data-customProduction-"+GetGUID()

		'=== 2.1 PROGRAMME BASE PROPERTIES ===
		'TODO: custom title/description
		'TODO: country = senderkarten "kuerzel"!
		programmeData.title = productionConcept.script.title.Copy()
		programmeData.description = productionConcept.script.description.Copy()
		programmeData.country = GetStationMapCollection().config.GetString("nameShort", "UNK")
		programmeData._year = GetWorldTime().GetYear()
		programmeData.distributionChannel = 0
		programmeData.blocks = productionConcept.script.GetBlocks()
		programmeData.available = true
		if productionConcept.script.IsLive()
			if programmeData.liveTime <= 0 then productionConcept.liveTime
		endif
		if priceModifier <> 1.0
			programmeData.SetModifier("price", priceModifier)
		endif
		programmeData.flags = productionConcept.script.flags
		programmeData.genre = productionConcept.script.mainGenre
		if productionConcept.script.subGenres
			For local sg:int = EachIn productionConcept.script.subGenres
				if sg = 0 then continue
				programmeData.subGenres :+ [sg]
			Next
		endif

		'=== 2.2 PROGRAMME CAST ===
		For local castIndex:int = 0 until productionConcept.cast.length
			local p:TProgrammePersonBase = productionConcept.cast[castIndex]
			local job:TProgrammePersonJob = productionConcept.script.cast[castIndex]
			if not p or not job then continue

			'person is now capable of doing this job
			p.SetJob(job.job)
			programmeData.AddCast(new TProgrammePersonJob.Init(p.GetGUID(), job.job))
		Next

		'=== 2.3 PROGRAMME PRODUCTION PROPERTIES ===
		programmeData.review = productionValueMod * productionConcept.script.review
		programmeData.speed = productionValueMod * productionConcept.script.speed
		programmeData.outcome = productionValueMod * productionConcept.script.outcome
		

		'=== 2.3 PROGRAMME LICENCE ===
		'todo: parentlicence - serien 
		local programmeLicence:TProgrammeLicence = new TProgrammeLicence
		programmeLicence.GUID = "customProduction-"+GetGUID()
		programmeLicence.SetData(programmeData)
		programmeLicence.available = true

print "produziert: " + programmeLicence.GetTitle()
		
		'=== 3. ADD TO PLAYER ===
		'if owner then ...


		return self
	End Method


	Method Update:int()
		Select status
			'already finished
			case 2
				return False
			'aborted / paused
			case 3
				return False
			'not yet started
			case 0
				return False
			'in production
			case 1
				if GetWorldTime().GetTimeGone() > endDate
					Finalize()
					return True
				endif
		End Select

		return False
	End Method
End Type