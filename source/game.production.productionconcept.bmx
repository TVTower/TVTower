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




Type TProductionConcept
	Field script:TScript

	Field directors:TProgrammePersonBase[]
	Field hosts:TProgrammePersonBase[]
	Field reporters:TProgrammePersonBase[]
	Field starActors:TProgrammePersonBase[]
	Field actors:TProgrammePersonBase[]
	Field musicians:TProgrammePersonBase[]

	'0=keines, 1=klein, 2=mittel, 3=groß
	Field audienceSize:int

	Field coulisseType1Id:string
	Field coulisseType2Id:string
	Field coulisseType3Id:string

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
End Type