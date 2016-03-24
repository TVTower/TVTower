SuperStrict
Import "game.world.worldtime.bmx"
Import "game.production.productionconcept.bmx"
Import "game.programme.newsevent.bmx"
Import "game.programme.programmelicence.bmx"


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
	Field productionValueMod:Float = 1.0


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


	Method Start:TProduction()
		print "start production"
		startDate = GetWorldTime().GetTimeGone()
		endDate = startDate + productionConcept.GetBaseProductionTime() * 3600

		status = 1


		'=== CALCULATE BASE PRODUCTION VALUES ===

		'=== CALCULATE FITS ===
		'do that in advance (with current actor skills)

		'Fetch corresponding genre definition, with this we are able to
		'see what values are "expected" for this genre.
		'Depending on the "fit" of actors, directors, ... values are
		'modified then.
		'Each script contains some values for review, speed, ...
		'which get modified by the "fit" (good ++, bad --)
		scriptGenreFit = productionConcept.script.CalculateGenreCriteriaFit() 
		print "scriptGenreFit:" +scriptGenreFit

		castFit = productionConcept.CalculateCastFit() 
		print "castFit:" +castFit
		

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

		'1) production effects
		'- modify production values (longer production time, random..)
		'- cast:
		'- - levelups / skill adjustments / XP gain
		'- - adding the job (if not done automatically) so it becomes
		'    specialized for this kind of production somewhen
		'
		'2) programme creation:
		'- programme data
		'- programme licence
		'- adding licence to player collection!


		'=== 1. PRODUCTION EFFECTS ===
		'productionValueMod ...


		'calculate

		'change skills of the actors / director / ...

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