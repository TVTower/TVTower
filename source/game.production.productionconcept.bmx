SuperStrict
Import "game.production.script.bmx"
Import "game.production.productioncompany.base.bmx"
Import "game.programme.programmeperson.bmx"


Type TProductionConceptCollection Extends TGameObjectCollection
	Global _instance:TProductionConceptCollection
	
	'override
	Function GetInstance:TProductionConceptCollection()
		if not _instance then _instance = new TProductionConceptCollection
		return _instance
	End Function


	'override
	Method GetRandom:TProductionConcept()
		return TProductionConcept( Super.GetRandom() )
	End Method


	Method GetRandomEpisode:TProductionConcept()
		local array:TProductionConcept[]
		'create a full array containing all elements
		For local obj:TProductionConcept = EachIn entries.Values()
			if not obj.script or not obj.script.IsEpisode() then continue
			array :+ [obj]
		Next
		if array.length = 0 then return Null
		if array.length = 1 then return array[0]

		Return array[(randRange(0, array.length-1))]
	End Method
		

	Method GetProductionConceptsByScript:TProductionConcept[](script:TScriptBase)
		local result:TProductionConcept[]
		For local pc:TProductionConcept = EachIn self
			if pc.script = script then result :+ [pc]
		Next
		return result
	End Method


	Method GetProductionConceptsByScripts:TProductionConcept[](scripts:TScriptBase[])
		local result:TProductionConcept[]
		For local script:TScriptBase = EachIn scripts
			result :+ GetProductionConceptsByScript(script)
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

'	Field additionalBudget:Int

'	Field niveau:Float = 0.0
'	Field innovation:Float = 0.0

	'optional for shows
	Field targetGroup:Int = -1
	'the higher the more speed
'	Field trophyMoney:Int = 0

	'depositCostPaid, live, ...
	Field flags:int = 0
	Field liveTime:int = -1

	Field castFit:Float = -1.0
	Field castFameMod:Float = -1.0
	Field castSympathy:Float = 0.0
	Field castSympathyCached:int = False
	'cache calculated vars (values which could get recalculated every-
	'time with the same output regardless of time)
	Field _scriptGenreFit:Float = -1.0 {nosave}
	Field _effectiveFocusPoints:Float = -1.0 {nosave}
	Field _effectiveFocusPointsMax:Float = -1.0 {nosave}

	'storage for precalculated values (eg. costs of actors get higher
	'inbetween)
	Field depositCost:int = -1
	Field totalCost:int = -1


	Method Initialize:TProductionConcept(owner:int, script:TScript)
		SetOwner(owner)

		'set script and reset production focus / cast
		SetScript(script)

		return self
	End Method


	Method Reset()
		'reset cast
		if script then cast = new TProgrammePersonBase[ script.cast.length ]

		ResetCache()

		productionFocus = new TProductionFocusBase
	End Method


	Method ResetCache()
		_scriptGenreFit = -1
		_effectiveFocusPoints = -1
		_effectiveFocusPointsMax = -1
	End Method


	Method SetCustomTitle(value:string)
		if script then script.SetCustomTitle(value)
	End Method


	Method SetCustomDescription(value:string)
		if script then script.SetCustomDescription(value)
	End Method


	Method GetTitle:string()
		if script then return script.GetTitle()
		return ""
	end Method


	Method GetDescription:string()
		if script then return script.GetDescription()
		return ""
	end Method
	

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

		ResetCache()

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

		ResetCache()

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetProductionCompany", new TData.Add("productionCompany", productionCompany), Self ) )
	End Method


	Method hasFlag:Int(flag:Int)
		Return (flags & flag) <> 0
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	Method PayDeposit:int()
		'already paid ?
		if IsDepositPaid() then return False

		'if invalid owner or finance not existing, skip payment and
		'just set the deposit as paid
		if GetPlayerFinance(owner)
			if not GetPlayerFinance(owner).PayProductionStuff(GetDepositCost())
				return False
			endif
		endif

		SetFlag(TVTProductionConceptFlag.DEPOSIT_PAID, True)
		return True
	End Method


	Method PayBalance:int()
		SetFlag(TVTProductionConceptFlag.BALANCE_PAID, True)

		return True
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

		'reset precalculated value
		castFit = -1.0
		castSympathy = 1.0
		castSympathyCached = False

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetCast", new TData.AddNumber("castIndex", castIndex).Add("person", person), Self ) )

		return True
	End Method


	Method GetCastGroup:TProgrammePersonBase[](jobFlag:int, skipEmpty:int = True)
		if not script then return new TProgrammePersonBase[0]

		local res:TProgrammePersonBase[]
		local jobs:TProgrammePersonJob[] = script.GetSpecificCast(jobFlag)
		if not skipEmpty and jobs
			res = new TProgrammePersonBase[jobs.length]
		endif

		'skip further processing with no slots for this specific job
		if not jobs or jobs.length = 0 then	return res


		'loop through all (potentially assigned) cast entries and check
		'whether their job fits to the desired one
		local castIndex:int = 0
		For local i:int = 0 until cast.length
			local job:TProgrammePersonJob = script.cast[i]
			'flawed data?
			if not job then continue
			'skip different jobs
			if (job.job <> jobFlag and jobFlag <> -1) then continue

			if castIndex > res.length then Throw "GetCastGroup(): castIndex("+castIndex+") > res.length("+res.length+")"

			
			if not skipEmpty
				if cast[i]
					res[castIndex] = GetProgrammePersonBaseCollection().GetByGUID(cast[i].GetGUID())
				else
					res[castIndex] = null
				endif

				castIndex :+ 1
			else
				if cast[i]
					local guid:string = cast[i].GetGUID()
					local p:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID(guid)
					res :+ [ GetProgrammePersonBaseCollection().GetByGUID(cast[i].GetGUID()) ]

					castIndex :+ 1
				endif
			endif
		Next
		return res
	End Method


	Method GetCastGroupString:string(jobFlag:int, skipEmpty:int = True, nameOfEmpty:string = "")
		local result:string = ""
		local group:TProgrammePersonBase[] = GetCastGroup(jobFlag, skipEmpty)
		for local i:int = 0 to group.length-1
			if skipEmpty and group[i] = null then continue

			if group[i]
				if result <> "" then result:+ ", "
				result:+ group[i].GetFullName()
			else
				if nameOfEmpty and result <> "" then result:+ ", "
				result:+ nameOfEmpty
			endif
		Next
		return result
	End Method


	'returns the percentage of used to maximum focus points
	Method GetEffectiveFocusPointsRatio:Float()
		'a "drama" production might have VFX-priority of 0.5, each point
		'spent there is only added by 50% to the effective ratio

		if _effectiveFocusPointsMax < 0 then CalculateEffectiveFocusPoints()

		if _effectiveFocusPointsMax > 0 
			return _effectiveFocusPoints / _effectiveFocusPointsMax
		elseif _effectiveFocusPointsMax = 0
			return 0.0
		endif
	End Method
	

	Method CalculateEffectiveFocusPoints:Float(recalculate:int = False)
		if not productionFocus then return 0.0

		if _effectiveFocusPoints >= 0 and not recalculate then return _effectiveFocusPoints

		_effectiveFocusPoints = 0.0
		_effectiveFocusPointsMax = 0.0
		
		Local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinition(script.mainGenre)

		For local focusPointID:int = EachIn productionFocus.GetOrderedFocusIndices()
			'production speed does not add to quality
			if focusPointID = TVTProductionFocus.PRODUCTION_SPEED then continue
			
			if genreDefinition
				_effectiveFocusPoints :+ GetProductionFocus(focusPointID) * genreDefinition.GetFocusPointPriority(focusPointID)
				_effectiveFocusPointsMax :+ TProductionFocusBase.focusPointLimit * genreDefinition.GetFocusPointPriority(focusPointID)

				'print "_effectiveFocusPoints :+ "+GetProductionFocus(focusPointID)+" * "+genreDefinition.GetFocusPointPriority(focusPointID)
				'print "_effectiveFocusPointsMax :+ "+TProductionFocusBase.focusPointLimit+" * "+genreDefinition.GetFocusPointPriority(focusPointID)

			else
				_effectiveFocusPoints :+ GetProductionFocus(focusPointID)
				_effectiveFocusPointsMax :+ TProductionFocusBase.focusPointLimit
			endif
		Next

		return _effectiveFocusPoints
	End Method


	Method CalculateCastSympathy:Float(recalculate:int = False)
		if castSympathyCached and not recalculate then return castSympathy

		if not owner then return 1.0

		local personSympathy:Float = 0.0
		local personCount:int = 0

		For local castIndex:int = 0 until cast.length
			local person:TProgrammePerson = TProgrammePerson(cast[castIndex])
			if person
				personSympathy :+ person.GetChannelSympathy(owner)
			endif
			personCount :+ 1
		Next
		if personCount > 0
			castSympathy = personSympathy / personCount
		else
			personSympathy = 0.0
		endif

		castSympathyCached = True

		return castSympathy
	End Method


	'returns how good or bad the fit of the selected cast is
	Method CalculateCastFit:Float(recalculate:int = False)
		'Calculate how good or bad the fit of the selected cast is
		'- do they know their job?
		'- is it the right genre for them?

		'use already calculated value
		if castFit >= 0 and not recalculate then return castFit
		 
		local castFitSum:Float = 0.0
		local personCount:int = 0
		local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinition(script.mainGenre)


		For local castIndex:int = 0 until cast.length
			local person:TProgrammePersonBase = cast[castIndex]
			if not person then continue

			local personFit:Float = 0.0
			local genreFit:Float = 0.0



			'=== GENRE FIT ===

			'== GENRE FIT #1
			'check if person is experienced in this genre because of
			'already done productions

			'main genre - 96% reached after 10 productions
			'euler strength: 3.0, so for done jobs: 26%, 45%, 59%, ...
			'(it is easier to adopt for a genre than for a job itself)
			local mainGenreFit:Float = THelper.LogisticalInfluence_Euler(Min(1.0, 0.1 * person.GetProducedGenreCount( script.GetMainGenre() )), 3)
			'sub genre
			if script.subGenres and script.subGenres.length > 0
				local subGenreFit:Float = 0.0
				For local genre:int = EachIn script.subGenres
					'96% reached after 8 productions
					subGenreFit :+ THelper.LogisticalInfluence_Euler(Min(1.0, 0.125 * person.GetProducedGenreCount( genre )), 3)
				Next
				subGenreFit :/ script.subGenres.length

				genreFit :+ 0.6 * mainGenreFit + 0.4 * subGenreFit
			else
				genreFit :+ 1.0 * mainGenreFit
			endif


			'== GENRE FIT #2
			'increase fit for top genres (20% genre1, 15% genre2)
			'exception: genre "MISC" ("undefined" / id=0)
			if script.GetMainGenre() <> TVTProgrammeGenre.Undefined
				if TProgrammePerson(person)
					local p:TProgrammePerson = TProgrammePerson(person)
					if p.topGenre1 = script.GetMainGenre() 
						genreFit = Min(1.0, genreFit + 0.20)
					elseif p.topGenre2 = script.GetMainGenre() 
						genreFit = Min(1.0, genreFit + 0.15)
					endif
				endif
			endif
			

			'== GENRE FIT #3
			'increase fit by up to 35% for the persons skill (versatility)
			if TProgrammePerson(person)
				genreFit = Min(1.0, genreFit + 0.35 * TProgrammePerson(person).skill)
			endif



			'=== JOB FIT ===
			local jobsDone:int = 0.10 * person.GetJobsDone(0) + 0.9 * person.GetJobsDone( script.cast[castIndex].job )
			'euler strength: 2.5, so for done jobs: 22%, 39%, 52%, ...
			local jobFit:Float = THelper.LogisticalInfluence_Euler(Min(1.0, 0.1 * jobsDone), 2.5)
			'by 5% chance "switch" effect
			if RandRange(0,100) < 5 then jobFit = 1.0 - jobFit


			'=== ATTRIBUTES - GENRE MOD ===
			'allows to gain bonus from having the right attributes for
			'the desired job, regardless of whether you are experienced
			'in this job or not
			local attributeMod:Float = 1.0
			local attributeCount:int = 0
			if TProgrammePerson(person)
				'loop through all attributes and add their weighted values
				for local i:int = 1 to TVTProgrammePersonAttribute.count
					local attributeID:int = TVTProgrammePersonAttribute.GetAtIndex(i)
					local attributeGenre:Float = genreDefinition.GetCastAttribute(script.cast[castIndex].job, attributeID)
					local attributePerson:Float = TProgrammePerson(person).GetAttribute(attributeID)
					if MathHelper.AreApproximatelyEqual(attributePerson, 0.0) then continue
					if MathHelper.AreApproximatelyEqual(attributeGenre, 0.0) then continue

					attributeMod :+ attributeGenre * attributePerson
					attributeCount :+ 1
				Next
				'calc average
				if attributeCount > 1
					attributeMod :/ attributeCount
				endif
				print person.GetFullname() +" : mod="+attributeMod
			endif
			

			'if the cast defines a specific gender for this position,
			'then we reduce the personFit by up to 20%.
			'This happens for 80% of all "wrong-gender"-assignments.
			'The other 12% have luck - they perfectly seem to fit into
			'that role.
			'And even 8% benefit from being another gender (script writer
			'was wrong then ;-))
			local genderFit:Float = 1.0
			if script.cast[castIndex].gender <> 0
				if person.gender <> script.cast[castIndex].gender
					local luck:int = RandRange(0,100)
					if luck <= 80 '80%
						genderFit = RandRange(1,20)/100.0
					elseif luck <= 88 '8%
						genderFit = RandRange(100,120)/100.0
					else
						'no change
					endif
				endif
			endif
						


			'=== TOTAL FIT ===

			personFit = (0.3 * genreFit + 0.7 * jobFit) * genderFit
			'if the person does not know anything about the done job
			'chances are high for the person not fitting at all
			if not jobFit < 0.1 and RandRange(0,100) < 90
				personFit :* 0.20
			endif
			'a persons maximum fit is 0.75 (without attributes)
			personFit :* 0.75
			'apply attribute mod (so persons with attributes are better)
			personFit :* attributeMod

			'a persons fit depends on its XP
			'so make 50% of the fit dependend from XP
			local xpMod:Float = 0.75
			if TProgrammePerson(person) then xpMod :+ 0.25 * TProgrammePerson(person).GetExperiencePercentage(script.cast[castIndex].job)
			personFit :* xpMod

			'increase lower fits (increases distance from "nobody" to "novice")
			personFit = THelper.LogisticalInfluence_Euler(personFit, 2)

			
			TLogger.Log("TProductionConcept.CalculateCastFit()", " --------------------", LOG_DEBUG)
			TLogger.Log("TProductionConcept.CalculateCastFit()", person.GetFullName() + " [as ~q"+ TVTProgrammePersonJob.GetAsString( script.cast[castIndex].job ) + "~q]", LOG_DEBUG)
			TLogger.Log("TProductionConcept.CalculateCastFit()", "     genreFit:  "+genreFit, LOG_DEBUG)
			TLogger.Log("TProductionConcept.CalculateCastFit()", "       jobFit:  "+jobFit, LOG_DEBUG)
			TLogger.Log("TProductionConcept.CalculateCastFit()", "    genderFit:  "+genderFit, LOG_DEBUG)
			TLogger.Log("TProductionConcept.CalculateCastFit()", " attributeMod:  "+attributeMod, LOG_DEBUG)
			if TProgrammePerson(person)
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (sympathy   :  "+TProgrammePerson(person).GetChannelSympathy(owner)+")", LOG_DEBUG)
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (xp         :  "+(TProgrammePerson(person).GetExperiencePercentage(script.cast[castIndex].job)*100)+"%)", LOG_DEBUG)
			else
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (sympathy   :  --)", LOG_DEBUG)
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (xp         :  --)", LOG_DEBUG)
			endif
			TLogger.Log("TProductionConcept.CalculateCastFit()", "=   personFit:  "+personFit, LOG_DEBUG)

			castFitSum :+ personFit
			personCount :+1
		Next

		if recalculate or castFit < 0
			castFit = castFitSum / personCount
		endif

		return castFit
	End Method


	'returns bonus modificator because of fame/popularity of the cast
	Method CalculateCastFameMod:Float(recalculate:int = False)
		'use already calculated value
		if castFameMod >= 0 and not recalculate then return castFameMod
		 
		local castFameModSum:Float = 0.0
		local personCount:int = 0

		For local castIndex:int = 0 until cast.length
			local person:TProgrammePersonBase = cast[castIndex]
			if not person then continue

			local jobID:int = script.cast[castIndex].job
			local personFameMod:Float = 1.0

			if TProgrammePerson(person)
				personFameMod :+ 0.75 * TProgrammePerson(person).GetFame()
				'really experienced persons benefit from it too (eg.
				'won awards and so on)
				personFameMod :+ 0.25 * TProgrammePerson(person).GetExperiencePercentage(jobID)
			endif

			castFameModSum :+ personFameMod
			personCount :+1
		Next

		if recalculate or castFameMod < 0
			castFameMod = castFameModSum / personCount
		endif

		return castFameMod
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

		productionFocus.SetFocus(focusIndex, value, True)
		'maybe some limitation corrected the value
		value = productionFocus.GetFocus(focusIndex)

		EventManager.triggerEvent( TEventSimple.Create("ProductionConcept.SetProductionFocus", new TData.AddNumber("focusIndex", focusIndex).AddNumber("value", value), Self ) )

		return True
	End Method


	Method CalculateCosts()
		totalCost = GetTotalCost()
		depositCost = GetDepositCost()
	End Method


	Method GetDepositCost:int()
		'return precalculated if existing
		if depositCost >= 0 then return depositCost
		
		return int(0.1 * GetTotalCost())
	End Method


	Method GetTotalCost:int()
		'return precalculated if existing
		if totalCost >= 0 then return totalCost

		local result:int
		result :+ GetCastCost()
		result :+ GetProductionCost()
		return result
	End Method


	Method GetCastCost:int()
		local result:int = 0
		For local i:int = 0 until cast.length
			if not cast[i] then continue

			result :+ cast[i].GetBaseFee( script.cast[i].job, script.GetBlocks())
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
		local base:int = 9 * 60
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

		'live productions are done a bit faster
		if script.IsLive() then base :* 0.5
		
		'round minutes to hours
		return floor(base/60)
	End Method


	Method IsDepositPaid:int()
		return hasFlag(TVTProductionConceptFlag.DEPOSIT_PAID)<>0
	End Method

	Method IsBalancePaid:int()
		return hasFlag(TVTProductionConceptFlag.BALANCE_PAID)<>0
	End Method


	Method IsProduced:int()
		return hasFlag(TVTProductionConceptFlag.PRODUCED)<>0
	End Method


	Method IsUnplanned:int()
		'started production setup already?
		if productionFocus.GetFocusPointsSet() > 0 then return False
		if GetCastGroup(-1).length > 0 then return False

		return True
	End Method


	Method IsPlanned:int()
		if not script then return False
		if not IsCastComplete() then return False
		'focus points not needed to be used at all
		'but one point spent is a must
		if not IsFocusPointsMinimumUsed() then return False
		'if not IsFocusPointsComplete() then return False

		return True
	End Method	


	Method IsGettingPlanned:int()
		if IsUnplanned() then return False
		if IsPlanned() then return False

		return True
	End Method


	Method IsProduceable:int()
		If not IsPlanned() then return False
		'ready to get produced
		if not IsDepositPaid() then return False
		'already produced
		if IsProduced() then return False

		return True
	End Method


	Method IsCastComplete:int()
		if not script then return False
		For local i:int = 0 until cast.length
			if not cast[i] then return False
		Next
		return True
	End Method


	Method IsFocusPointsComplete:int()
		if not productionCompany then return False
		if not productionFocus or productionFocus.GetFocusPointsMax() = 0 then return False
		return productionFocus.GetFocusPointsSet() = productionFocus.GetFocusPointsMax()
	End Method


	Method IsFocusPointsMinimumUsed:int()
		if not productionCompany then return False
		if not productionFocus or productionFocus.GetFocusPointsMax() = 0 then return False
		return productionFocus.GetFocusPointsSet() > 0
	End Method
End Type




Type TProductionFocusBase
	Field focusPoints:int[]
	Field focusPointsMax:int = -1
	Field activeFocusIndices:int[]
	Global focusPointLimit:int = 10


	Method New()
		Initialize()
	End Method

	Method Initialize:int()
		focusPoints = new Int[6]

		EnableFictional(false)
	End Method


	Method EnableFictional:int(bool:int = true)
		'movielike programme
		if bool
			activeFocusIndices = [TVTProductionFocus.COULISSE, ..
			                      TVTProductionFocus.OUTFIT_AND_MASK, ..
			                      TVTProductionFocus.VFX_AND_SFX, ..
			                      TVTProductionFocus.STUNTS, ..
			                      ..
			                      TVTProductionFocus.TEAM, ..
			                      TVTProductionFocus.PRODUCTION_SPEED ..
			                     ]
		'features, documentations...
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
	

	Method SetFocus:int(index:int, value:int, checkLimits:int = True)
		if focusPoints.length < index or index < 1 then return False

		'reset old, so GetFocusPointsLeft() returns correct value
		focusPoints[index -1] = 0
		if checkLimits
			'check a total focus point limit
			focusPoints[index -1] = MathHelper.Clamp(value, 0, Max(0, Min(focusPoints[index -1] + GetFocusPointsLeft(), focusPointLimit)))
		else
			'use the absolute limit
			focusPoints[index -1] = MathHelper.Clamp(value, 0, focusPointLimit)
		endif

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


	'removes focus points 1 by 1 from each focus aspects until they are
	'within a limit
	'so 3,3,3,0,0 with limit 5 becomes 2,1,1,0,0
	Method ClampFocusPoints()
		if GetFocusPointsSet() = 0 then return
		
		'clamp values
		'if more points are spend than allowed, subtract one by one
		'from all aspects until point maximum is no longer beat
		local trimPoints:int = GetFocusPointsSet() - GetFocusPointsMax()
		While trimPoints > 0

			'start at bottom
			For local i:int = activeFocusIndices.length-1 to 0 step -1
				local focusIndex:int = activeFocusIndices[i]

				trimPoints = GetFocusPointsSet() - GetFocusPointsMax()
				if trimPoints <= 0 then exit

				if GetFocus( focusIndex ) <= 0 then continue

				'to avoid removing more than "-1" (if it still exceeds
				'a limit), make sure to use "False" to disable this
				'check
				SetFocus(focusIndex, GetFocus(focusIndex) - 1, False)
			Next
		Wend
	End Method


	Method SetFocusPointsMax(maxValue:int)
		focusPointsMax = maxValue

		ClampFocusPoints()
	End Method
	

	Method GetFocusPointsMax:int()
		'without limit, each focus aspect can contain focusPointLimit(10) points
		'if focusPointsMax < 0 then focusPointsMax = GetFocusAspectCount() * focusPointLimit
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