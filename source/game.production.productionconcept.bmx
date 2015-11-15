SuperStrict
Import "game.production.script.bmx"
Import "game.production.productioncompany.base.bmx"
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
Type TProductionConcept Extends TGameObject
	Field script:TScript

	'each assigned person (directors, actors, ...)
	Field cast:TProgrammePersonBase[]

	Field productionCompany:TProductionCompanyBase
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

		if script
			if script.isFictional()
				if not TProductionFocusFictionalProgramme(productionFocus)
					productionFocus = new TProductionFocusFictionalProgramme.CopyFrom(productionFocus)
				endif
			else
				if not TProductionFocusBase(productionFocus)
					productionFocus = new TProductionFocusBase.CopyFrom(productionFocus)
				endif
			endif
		else
			'reset
			productionFocus = new TProductionFocusBase
		endif
			

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetScript", new TData.Add("script", script), Self ) )

		'resize cast space
		Initialize()
	End Method


	Method SetProductionCompany(productionCompany:TProductionCompanyBase)
		'skip if no change is needed
		if self.productionCompany = productionCompany then return


		self.productionCompany = productionCompany

		'init if not done
		if not productionFocus then Initialize()
		if productionCompany
			productionFocus.SetFocusPointsMax( productionCompany.GetFocusPoints() )
		else
			productionFocus.SetFocusPointsMax( 0 )
		endif

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetProductionCompany", new TData.Add("productionCompany", productionCompany), Self ) )
	End Method


	Method GetCast:TProgrammePersonBase(castIndex:int)
		if not cast or castIndex >= cast.length or castIndex < 0 then return Null
		return cast[castIndex]
	End Method
		

	Method SetCast:int(castIndex:int, person:TProgrammePersonBase)
		if not cast or castIndex >= cast.length or castIndex < 0 then return False
		'skip if nothing to do
		if cast[castIndex] = person then return False

		cast[castIndex] = person

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetCast", new TData.AddNumber("castIndex", castIndex).Add("person", person), Self ) )

		return True
	End Method


	Method GetProductionFocus:int(focusIndex:int)
		if not productionFocus or focusIndex > productionFocus.GetFocusAspectCount() or focusIndex < 1 then return False
		return productionFocus.GetFocus(focusIndex)
	End Method
		

	Method SetProductionFocus:int(focusIndex:int, value:int)
		if not productionCompany then return False
		
		if not productionFocus or focusIndex > productionFocus.GetFocusAspectCount() or focusIndex < 1 then return False
		'skip if nothing to do
		if productionFocus.GetFocus(focusIndex) = value then return False

		productionFocus.SetFocus(focusIndex, value)
		'maybe some limitation corrected the value
		value = productionFocus.GetFocus(focusIndex)

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetProductionFocus", new TData.AddNumber("focusIndex", focusIndex).AddNumber("value", value), Self ) )

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
		if not productionCompany then return False
		if not productionFocus or productionFocus.GetFocusPointsMax() = 0 then return False
		return productionFocus.GetFocusPointsSet() = productionFocus.GetFocusPointsMax()
	End Method	
End Type




Type TProductionFocusBase
	Field coulisse:int
	Field outfitAndMask:int
	Field team:int
	Field productionSpeed:int
	Field focusPointsMax:int = -1
	global focusAspectCount:int = 4


	Method Initialize:int()
		coulisse = 0
		outfitAndMask = 0
		team = 0
		productionSpeed = 0
	End Method


	Method CopyFrom:TProductionFocusBase(source:TProductionFocusBase)
		if not source then Initialize()

		coulisse = source.coulisse
		outfitAndMask = source.outfitAndMask
		team = source.team
		productionSpeed = source.productionSpeed
		focusPointsMax = source.focusPointsMax

		return self
	End Method


	Method SetFocus(index:int, value:int)
		Select index
			case 1
				SetCoulisse(value)
			case 2
				SetOutfitAndMask(value)
			case 3
				SetTeam(value)
			case 4
				SetProductionSpeed(value)
		End Select
		'emit event with corrected value (via GetFocus())
		EventManager.triggerEvent( TEventSimple.Create("ProductionFocus.SetFocus", new TData.AddNumber("focusIndex", index).AddNumber("value", GetFocus(index)), Self ) )
	End Method


	Method GetFocus:int(index:int)
		Select index
			case 1
				return GetCoulisse()
			case 2
				return GetOutfitAndMask()
			case 3
				return GetTeam()
			case 4
				return GetProductionSpeed()
		End Select
		return -1
	End Method


	Method SetCoulisse(value:int)
		'reset old, so GetFocusPointsLeft() returns correct value
		coulisse = 0
		coulisse = MathHelper.Clamp(value, 0, Min(coulisse + GetFocusPointsLeft(), 10))
	End Method


	Method SetOutfitAndMask(value:int)
		'reset old, so GetFocusPointsLeft() returns correct value
		outfitAndMask = 0
		outfitAndMask = MathHelper.Clamp(value, 0, Min(outfitAndMask + GetFocusPointsLeft(), 10))
	End Method


	Method SetTeam(value:int)
		'reset old, so GetFocusPointsLeft() returns correct value
		team = 0
		team = MathHelper.Clamp(value, 0, Min(GetFocusPointsLeft(), 10))
	End Method
	

	Method SetProductionSpeed(value:int)
		'reset old, so GetFocusPointsLeft() returns correct value
		productionSpeed = 0
		productionSpeed = MathHelper.Clamp(value, 0, Min(GetFocusPointsLeft(), 10))
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
		local result:int = 0

		For local i:int = 1 to GetFocusAspectCount()
			result :+ GetFocus(i)
		Next

		return result
	End Method


	Method GetFocusPointsLeft:int()
		return GetFocusPointsMax() - GetFocusPointsSet()
	End Method


	Method ClampFocusPoints()
		if GetFocusPointsSet() = 0 then return
		
		'clamp values
		'if more points are spend than allowed, subtract one by one
		'from all aspects until point maximum is no longer beat
		local trimPoints:int = GetFocusPointsSet() - GetFocusPointsMax()
		While trimPoints > 0
			For local i:int = GetFocusAspectCount() until 0 step -1
				trimPoints = GetFocusPointsSet() - GetFocusPointsMax()
				if trimPoints <= 0 then exit

				if GetFocus(i) <= 0 then continue

				SetFocus(i, GetFocus(i) - 1)
			Next
		Wend
	End Method


	Method SetFocusPointsMax(maxValue:int)
		focusPointsMax = maxValue

		ClampFocusPoints()
	End Method
	

	Method GetFocusPointsMax:int()
		'without limit, each focus aspect can contain 10 points
		'if focusPointsMax < 0 then focusPointsMax = GetFocusAspectCount() * 10
		'set to 0
		if focusPointsMax < 0 then focusPointsMax = 0
		return focusPointsMax
	End Method


	Method GetFocusAspectCount:int()
		return focusAspectCount
	End Method
End Type


'focus set for 
Type TProductionFocusFictionalProgramme extends TProductionFocusBase
	Field stunts:int
	Field vfxAndSfx:int
	global focusAspectCount:int = 6


	Method Initialize:int()
		Super.Initialize()
		stunts = 0
		vfxAndSfx = 0

		focusAspectCount = TProductionFocusBase.focusAspectCount + 2
	End Method


	Method CopyFrom:TProductionFocusFictionalProgramme(source:TProductionFocusBase)
		Super.CopyFrom(source)

		local mySource:TProductionFocusFictionalProgramme = TProductionFocusFictionalProgramme(source)
		if mySource
			stunts = mySource.stunts
			vfxAndSfx = mySource.vfxAndSfx
		endif

		return self
	End Method


	Method SetFocus(index:int, value:int)
		Select index
			case TProductionFocusBase.focusAspectCount + 1
				SetStunts(value)
			case TProductionFocusBase.focusAspectCount + 2
				SetVfxAndSfx(value)
		End Select

		'emit event
		Super.SetFocus(index, value)
	End Method


	Method GetFocus:int(index:int)
		Select index
			case TProductionFocusBase.focusAspectCount + 1
				return GetStunts()
			case TProductionFocusBase.focusAspectCount + 2
				return GetVfxAndSfx()

			default
				return Super.GetFocus(index)
		End Select
	End Method
			

	Method SetStunts(value:int)
		'reset old, so GetFocusPointsLeft() returns correct value
		stunts = 0
		stunts = MathHelper.Clamp(value, 0, Min(GetFocusPointsLeft(), 10))
	End Method


	Method SetVfxAndSfx(value:int)
		'reset old, so GetFocusPointsLeft() returns correct value
		vfxAndSfx = 0
		vfxAndSfx = MathHelper.Clamp(value, 0, Min(GetFocusPointsLeft(), 10))
	End Method


	Method GetStunts:int()
		return stunts
	End Method


	Method GetVfxAndSfx:int()
		return vfxAndSfx
	End Method


	'override so it uses this types global
	Method GetFocusAspectCount:int()
		return focusAspectCount
	End Method
End Type

