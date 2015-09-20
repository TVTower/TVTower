SuperStrict
Import "game.production.script.bmx"
Import "game.programme.programmeperson.base.bmx"


Type TProductionConceptCollection Extends TGameObjectCollection
	Global _instance:TProductionConceptCollection
	
	'override
	Function GetInstance:TProductionConceptCollection()
		if not _instance then _instance = new TProductionConceptCollection
		return _instance
	End Function


	Method GetProductionConceptsByScript:TProductionConcept[](script:TScript)
		local result:TProductionConcept[]
		For local pc:TProductionConcept = EachIn self
			if pc.script = script then result :+ [pc]
		Next
		return result
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetProductionConceptCollection:TProductionConceptCollection()
	Return TProductionConceptCollection.GetInstance()
End Function




'describes:
'- what to produce (script)
'- with whom to produce (cast)
'- how to produce (focus points)
Type TProductionConcept
	Field script:TScript

	'each assigned person (directors, actors, ...)
	Field cast:TProgrammePersonJob[]

	Field productionFocus:TProductionFocusBase

	Field additionalBudget:Int

	Field niveau:Float = 0.0
	Field innovation:Float = 0.0
	
	'optional for shows
	Field targetGroup:Int = -1
	'live = more risk, more expensive, more speed
	Field live:Int = false
	'bonus like CallIn-Show. review--
	Field callInCompetition:Int = False
	'the higher the more speed
	Field trophyMoney:Int = 0


	Method Initialize:int()
		'reset cast, focus, ...
	End Method
	

	Method SetScript(script:TScript)
		self.script = script
	End Method


	Method IsComplete:int()
		return False
	End Method
End Type




Type TProductionFocusBase
	Field coulisse:int
	Field outfitAndMask:int
	Field team:int
	Field productionSpeed:int

	Method SetCoulisse(value:int)
		coulisse = MathHelper.Clamp(value, 0, 10)
	End Method


	Method SetOutfitAndMask(value:int)
		outfitAndMask = MathHelper.Clamp(value, 0, 10)
	End Method


	Method SetTeam(value:int)
		team = MathHelper.Clamp(value, 0, 10)
	End Method
	

	Method SetProductionSpeed(value:int)
		productionSpeed = MathHelper.Clamp(value, 0, 10)
	End Method


	Method GetCoulisse:int()
		return coulisse
	End Method


	Method GetOutfitAndMask:int()
		return outfitAndMask
	End Method


	Method GetTeam:int()
		return team
	End Method


	Method GetProductionSpeed:int()
		return productionSpeed
	End Method


	Method GetFocusPointsSet:int()
		return coulisse + outfitAndMask + team + productionSpeed
	End Method


	Method GetFocusPointsMax:int()
		return 4 * 10
	End Method
End Type


'focus set for 
Type TProductionFocusFictionalProgramme extends TProductionFocusBase
	Field stunts:int
	Field vfxAndSfx:int


	Method SetStunts(value:int)
		stunts = MathHelper.Clamp(value, 0, 10)
	End Method


	Method SetVfxAndSfx(value:int)
		vfxAndSfx = MathHelper.Clamp(value, 0, 10)
	End Method


	Method GetStunts:int()
		return stunts
	End Method


	Method GetVfxAndSfx:int()
		return vfxAndSfx
	End Method


	Method GetFocusPointsSet:int()
		return Super.GetFocusPointsSet() + stunts + vfxAndSfx
	End Method


	Method GetFocusPointsMax:int()
		return Super.GetFocusPointsMax() + 2*10
	End Method
End Type