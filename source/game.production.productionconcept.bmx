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
Type TProductionConcept Extends TOwnedGameObject
	Field script:TScript
	'storing the position/order in the studio saves the hassle of storing
	'this information in a "scriptOrder"-Collection
	Field studioSlot:int = -1


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


	Method Initialize:TProductionConcept(owner:int, script:TScript)
		SetOwner(owner)

		'set script and reset production focus / cast
		SetScript(script)

		return self
	End Method


	Method Reset()
		'reset cast
		if script then cast = new TProgrammePersonBase[ script.cast.length ]

		productionFocus = new TProductionFocusBase
	End Method
	

	Method SetScript(script:TScript)
		self.script = script
		'resize cast space / focus
		Reset()

		if script
			if script.isFictional()
				if not productionFocus.IsFictional() then productionFocus.EnableFictional(true)
			else
				if productionFocus.IsFictional() then productionFocus.EnableFictional(false)
			endif
		endif

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetScript", new TData.Add("script", script), Self ) )
	End Method


	Method SetProductionCompany(productionCompany:TProductionCompanyBase)
		'skip if no change is needed
		if self.productionCompany = productionCompany then return


		self.productionCompany = productionCompany

		'init if not done
		if not productionFocus then productionFocus = new TProductionFocusBase
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


	Method GetTotalCost:int()
		local result:int
		result :+ GetCastCost()
		result :+ GetProductionCost()
		return result
	End Method


	Method GetCastCost:int()
		local result:int = 0
		For local i:int = 0 until cast.length
			if not cast[i] then continue

			result :+ cast[i].GetBaseFee( script.cast[i].job, script.blocks)
		Next
		return result
	End Method


	Method GetProductionCost:int()
		if productionCompany
			local fee:int = productionCompany.GetFee(script.owner)

			'each set point costs a bit more than the previous
			local focusPoints:int = productionFocus.GetFocusPointsSet()
			For local i:int = 1 until focusPoints
				fee :+ 500*i
			Next
			return fee
		endif

		return 0
	End Method


	Method GetBaseProductionTime:int()
		local base:int = 12 * 60
		if productionFocus
			'SPEED
			'point decrease:
			'1/10 = 90min
			'2/10 = 175min (90 + 85) 
			'3/10 = 255min (90 + 85 + 80) 
			'... 
			local speedPoints:int = productionFocus.GetFocus(TVTProductionFocus.PRODUCTION_SPEED)
			For local i:int = 0 until speedPoints
				base :- Max(0, 90 - 5*i)
			Next

			'TEAM (good teams work a bit more efficient)
			local teamPoints:int = productionFocus.GetFocus(TVTProductionFocus.TEAM)
			For local i:int = 0 until teamPoints
				base :- Max(0, 25 - 2*i)
			Next

			'POINTS ADD TO TIME !
			local focusPoints:int = productionFocus.GetFocusPointsSet()
			'ignore points without penalty
			focusPoints :- (teamPoints + speedPoints)
			if focusPoints > 0
				For local i:int = 0 until focusPoints
					base :+ (10 + i*5)
				Next
			endif
		endif
		'round minutes to hours
		return floor(base/60)
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
	Field focusPoints:int[]
	Field focusPointsMax:int = -1
	Field activeFocusIndices:int[]
	global focusAspectCount:int = 4


	Method New()
		Initialize()
	End Method

	Method Initialize:int()
		focusPoints = new Int[6]

		EnableFictional(false)
	End Method


	Method EnableFictional:int(bool:int = true)
		if bool
			activeFocusIndices = [TVTProductionFocus.COULISSE, ..
			                      TVTProductionFocus.OUTFIT_AND_MASK, ..
			                      TVTProductionFocus.VFX_AND_SFX, ..
			                      TVTProductionFocus.STUNTS, ..
			                      ..
			                      TVTProductionFocus.TEAM, ..
			                      TVTProductionFocus.PRODUCTION_SPEED ..
			                     ]
		else
			activeFocusIndices = [TVTProductionFocus.COULISSE, ..
			                      TVTProductionFocus.OUTFIT_AND_MASK, ..
			                      ..
			                      TVTProductionFocus.TEAM, ..
			                      TVTProductionFocus.PRODUCTION_SPEED ..
			                     ]
		endif
	End Method


	Method IsFictional:int()
		return (activeFocusIndices.length = 6)
	End Method
	

	Method SetFocus:int(index:int, value:int)
		if focusPoints.length < index or index < 1 then return False

		'reset old, so GetFocusPointsLeft() returns correct value
		focusPoints[index -1] = 0
		focusPoints[index -1] = MathHelper.Clamp(value, 0, Min(focusPoints[index -1] + GetFocusPointsLeft(), 10))

		'emit event with corrected value (via GetFocus())
		EventManager.triggerEvent( TEventSimple.Create("ProductionFocus.SetFocus", new TData.AddNumber("focusIndex", index).AddNumber("value", GetFocus(index)), Self ) )
		return True
	End Method


	Method GetFocus:int(index:int)
		if focusPoints.length < index or index < 1 then return -1

		return focusPoints[index -1]
	End Method


	Method GetOrderedFocusIndices:int[]()
		return activeFocusIndices
	End Method


	Method GetFocusPointsSet:int()
		local result:int = 0

		For local focusIndex:int = EachIn activeFocusIndices
			result :+ GetFocus(focusIndex)
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
			For local i:int = activeFocusIndices.length-1 to 0 step -1
				trimPoints = GetFocusPointsSet() - GetFocusPointsMax()
				if trimPoints <= 0 then exit

				local focusIndex:int = activeFocusIndices[i]
				if GetFocus( focusIndex ) <= 0 then continue

				SetFocus(focusIndex, GetFocus(focusIndex) - 1)
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
		return activeFocusIndices.length
	End Method
End Type




Type TProductionConceptFilter
	Field requiredOwners:int[]
	Field forbiddenOwners:int[]
	Field scriptGUID:string

	
	Method DoesFilter:Int(concept:TProductionConcept)
		if not concept then return False

		if scriptGUID
			if not concept.script then return False
			if scriptGUID <> concept.script.GetGUID() then return False
		endif

		'check if owner is one of the owners required for the filter
		'if not, filter failed
		if requiredOwners.length > 0
			local hasOwner:int = False
			for local owner:int = eachin requiredOwners
				if owner = concept.owner then hasOwner = True;exit
			Next
			if not hasOwner then return False
		endif

		'check if owner is one of the forbidden owners
		'if so, filter fails
		if forbiddenOwners.length > 0
			for local owner:int = eachin forbiddenOwners
				if owner = concept.owner then return False
			Next
		endif
	
	End Method
End Type