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
	Field cast:TProgrammePersonBase[]

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
		if script 
			cast = new TProgrammePersonBase[ script.cast.length ]
		endif
		if not productionFocus then productionFocus = new TProductionFocusBase

	End Method
	

	Method SetScript(script:TScript)
		self.script = script

		'resize cast space
		Initialize()
	End Method


	Method SetCast:int(castIndex:int, person:TProgrammePersonBase)
		if not cast or castIndex >= cast.length then return False
		cast[castIndex] = person
		return True
	End Method

	Method IsComplete:int()
		if not script then return False
		if not IsCastComplete() then return False
		if not IsFocusPointsComplete() then return False

		return True
	End Method


	Method IsCastComplete:int()
		if not script then return False
		For local i:int = 0 to cast.length
			if not cast[i] then return False
		Next
		return True
	End Method


	Method IsFocusPointsComplete:int()
		if not productionFocus then return False
		return productionFocus.GetFocusPointsSet() < productionFocus.GetFocusPointsSet()
	End Method	
End Type




Type TProductionFocusBase
	Field coulisse:int
	Field outfitAndMask:int
	Field team:int
	Field productionSpeed:int


	Method Initialize:int()
		coulisse = 0
		outfitAndMask = 0
		team = 0
		productionSpeed = 0
	End Method


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


	Method Initialize:int()
		Super.Initialize()
		stunts = 0
		vfxAndSfx = 0
	End Method
		

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