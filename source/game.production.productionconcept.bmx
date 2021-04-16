SuperStrict
Import "game.production.script.bmx"
Import "game.production.productioncompany.base.bmx"
Import "game.person.bmx"


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


	Method GetProductionConceptCountByScript:Int(script:TScriptBase, includeSubscripts:Int = False)
		local result:Int = 0
		For local pc:TProductionConcept = EachIn self
			if pc.script = script then result :+ 1
		Next
		If includeSubscripts And script.GetSubScriptCount() > 0
			For local subscript:TScriptBase = EachIn script.subScripts
				result :+ GetProductionConceptCountByScript(subscript, includeSubscripts)
			Next
		EndIf
		return result
	End Method


	Method GetProductionConceptCountByScripts:Int(scripts:TScriptBase[], includeSubscripts:Int = False)
		local result:Int
		For local script:TScriptBase = EachIn scripts
			result :+ GetProductionConceptCountByScript(script, includeSubscripts)
		Next
		return result
	End Method


	Method GetProductionConceptsByScript:TProductionConcept[](script:TScriptBase, includeSubscripts:Int = False)
		local result:TProductionConcept[]
		For local pc:TProductionConcept = EachIn self
			if pc.script = script then result :+ [pc]
		Next
		If includeSubscripts and script.GetSubScriptCount() > 0
			For local subscript:TScriptBase = EachIn script.subScripts
				result :+ GetProductionConceptsByScript(subscript, includeSubscripts)
			Next
		EndIf
		return result
	End Method


	Method GetProductionConceptsByScripts:TProductionConcept[](scripts:TScriptBase[], includeSubscripts:Int = False)
		local result:TProductionConcept[]
		For local script:TScriptBase = EachIn scripts
			result :+ GetProductionConceptsByScript(script, includeSubscripts)
		Next
		return result
	End Method


	Method CanCreateProductionConcept:Int(script:TScript) {_exposeToLua}
		If not script then Return False

		'does the script define a specific limit?
		local produceableElements:Int = script.GetCanGetProducedElementsCount()
		if produceableElements = 0 Then Return False
		
		Local currentConceptCount:Int = GetProductionConceptCountByScript(script, True)
	
		'do not allow more concepts than the rules say!
		If currentConceptCount >= GameRules.maxProductionConceptsPerScript Then Return False
		'do not allow more concepts than produceable with the script
		If currentConceptCount >= GetProductionConceptMax(script) Then Return False
	
		Return True
	End Method


	Method GetProductionConceptMax:Int(script:TScript) {_exposeToLua}
		'series?
		If script.GetSubScriptCount() > 0
			Return script.GetSubScriptCount() - script.GetProductionsCount()
		Else
			Return script.CanGetProducedCount()
		endIf
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
	'designated live time of a live broadcast
	Field liveTime:Long = -1

	'each assigned person (directors, actors, ...)
	Field cast:TPersonBase[]

	Field productionCompany:TProductionCompanyBase
	Field productionFocus:TProductionFocusBase
	'the productionconcept's custom title/description will is what
	'the final produc will have as title/description. A script's 
	'custom title/description is used to eg append numbers/years to
	'a script generated from a template
	Field customTitle:string = ""
	Field customDescription:string = ""


	'optional for shows
	Field targetGroup:Int = -1

	'depositCostPaid, live, ...
	Field flags:int = 0

	Field castFit:Float = -1.0
	Field castComplexity:Float = -1.0
	Field castFameMod:Float = -1.0
	Field castSympathy:Float = 0.0
	Field castSympathyCached:int = False

	Field scriptPotentialMod:Float = 1.0
	Field scriptPotentialModCached:int = False

	'cache calculated vars (values which could get recalculated every-
	'time with the same output regardless of time)
	Field _scriptGenreFit:Float = -1.0 {nosave}
	Field _effectiveFocusPoints:Float = -1.0 {nosave}
	Field _effectiveFocusPointsMax:Float = -1.0 {nosave}

	'storage for precalculated values (eg. costs of actors get higher
	'inbetween)
	Field depositCost:int = -1
	Field totalCost:int = -1


	Method GenerateGUID:string()
		return "productionconcept-"+id
	End Method


	Method Initialize:TProductionConcept(owner:int, script:TScript)
		SetOwner(owner)

		'set script and reset production focus / cast
		SetScript(script)

		return self
	End Method


	Method Reset()
		'reset cast
		if script then cast = new TPersonBase[ script.jobs.length ]

		ResetCache()

		productionFocus = new TProductionFocusBase
	End Method


	Method ResetCache()
		_scriptGenreFit = -1
		_effectiveFocusPoints = -1
		_effectiveFocusPointsMax = -1
	End Method


	Method SetCustomTitle(value:string)
		customTitle = value
	End Method


	Method SetCustomDescription(value:string)
		customDescription = value
	End Method


	Method HasCustomTitle:Int()
		return customTitle <> ""
	End Method


	Method HasCustomDescription:Int()
		return customDescription <> ""
	End Method


	Method GetTitle:string()
		If customTitle Then Return customTitle
		If script Then Return script.GetTitle()
		Return ""
	End Method


	Method GetDescription:string()
		If customDescription Then Return customDescription
		If script Then Return script.GetDescription()
		Return ""
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

		ResetCache()

		TriggerBaseEvent(GameEventKeys.ProductionConcept_SetScript, new TData.Add("script", script), Self )
	End Method


	Method GetProductionCompany:TProductionCompanyBase()
		Return self.productionCompany
	End Method 


	Method SetProductionCompany(productionCompany:TProductionCompanyBase, force:Int = False)
		'skip if no change is needed - except forced (eg re-apply focus max)
		if self.productionCompany = productionCompany and not force then return


		self.productionCompany = productionCompany

		'init if not done
		if not productionFocus then productionFocus = new TProductionFocusBase
		if productionCompany
			productionFocus.SetFocusPointsMax( productionCompany.GetFocusPoints() )
		else
			productionFocus.SetFocusPointsMax( 0 )
		endif

		ResetCache()

		TriggerBaseEvent(GameEventKeys.ProductionConcept_SetProductionCompany, new TData.Add("productionCompany", productionCompany), Self )
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


	'returns the time when a production _could_ live broadcast the first
	'time. Parameter "earliestBroadcastTime" can be used to have at least
	'end of a live broadcasting prequel as minimum
	Method GetPlannedLiveTime:Long(earliestBroadcastTime:Long = -1)
		If Not script Then Return -1

		'without given time use the (pre-)production end time
		If earliestBroadcastTime = -1
			earliestBroadcastTime = liveTime

			If earliestBroadcastTime = - 1
				'check script for some last live time - and use that as minimum
				earliestBroadcastTime = Max(script.lastLivetime, GetWorldTime().GetTimeGone())

				If not IsProductionFinished() and script.productionTime > 0
					earliestBroadcastTime :+ script.productionTime * script.productionTimeMod
				EndIf
			EndIf
		EndIf

		'calculate live broadcast time depending on the "time code" in
		'the script
		Return script.GetLiveTime(earliestBroadcastTime, 0)
	End Method


	Method SetLiveTime(time:Long)
		liveTime = time
	End Method


	Method GetLiveTime:Long()
		If liveTime = -1 Then Return GetPlannedLiveTime()
		Return liveTime
	End Method


	Method GetLiveTimeText:String(liveBroadcastTime:Long = -1)
		If liveBroadcastTime = -1
			liveBroadcastTime = liveTime
			If livetime = -1
				liveBroadcastTime = GetPlannedLiveTime( liveBroadcastTime )
			EndIf
		EndIf

		Local plannedLiveTime:Long = script.GetLiveTime( liveBroadcastTime )
		Local plannedLiveTimeStr:String = GetWorldTime().GetFormattedDate( plannedLiveTime )

		Local liveDay:Int = GetWorldTime().GetDay( plannedLiveTime )
		Local nowDay:Int = GetWorldTime().GetDay()

		If script.HasBroadcastTimeSlot()
			If liveDay = nowDay
				Return GetLocale("PLANNED_LIVE_TIMESPAN_TODAY_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( plannedLiveTime ))
			ElseIf liveDay = nowDay + 1
				Return GetLocale("PLANNED_LIVE_TIMESPAN_TOMORROW_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( plannedLiveTime ))
			Else
				Return GetLocale("PLANNED_LIVE_TIMESPAN_IN_Y_DAYS_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( plannedLiveTime )).Replace("%Y%", (liveDay - nowDay))
			EndIf
		Else
			If liveDay = nowDay
				Return GetLocale("PLANNED_LIVE_TIME_TODAY_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( plannedLiveTime ))
			ElseIf liveDay = nowDay + 1
				Return GetLocale("PLANNED_LIVE_TIME_TOMORROW_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( plannedLiveTime ))
			Else
				Return GetLocale("PLANNED_LIVE_TIME_IN_Y_DAYS_FROM_X_OCLOCK").Replace("%X%", GetWorldTime().GetDayHour( plannedLiveTime )).Replace("%Y%", (liveDay - nowDay))
			EndIf
		EndIf
		Return ""
	End Method


	Method PayDeposit:int()
		'already paid ?
		if IsDepositPaid() then return False
		'cannot pay because not planned completely?
		if not IsPlanned() then return False

		'if invalid owner or finance not existing, skip payment and
		'just set the deposit as paid
		if owner > 0 and GetPlayerFinance(owner)
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


	Method GetCastCount:int()
		return cast.length
	End Method


	Method GetCast:TPersonBase(castIndex:int)
		if not cast or castIndex >= cast.length or castIndex < 0 then return Null
		return cast[castIndex]
	End Method


	Method SetCast:int(castIndex:int, person:TPersonBase)
		if not cast or castIndex >= cast.length or castIndex < 0 then return False
		'skip if nothing to do
		if cast[castIndex] = person then return False

		cast[castIndex] = person

		'reset precalculated value
		castFit = -1.0
		castSympathy = 1.0
		castSympathyCached = False

		TriggerBaseEvent(GameEventKeys.ProductionConcept_SetCast, new TData.AddNumber("castIndex", castIndex).Add("person", person), Self )

		return True
	End Method


	Method GetCastGroup:TPersonBase[](jobFlag:int, skipEmpty:int = True)
		if not script then return new TPersonBase[0]

		local res:TPersonBase[]
		local jobs:TPersonProductionJob[] = script.GetSpecificJob(jobFlag)
		if not skipEmpty and jobs
			res = new TPersonBase[jobs.length]
		endif

		'skip further processing with no slots for this specific job
		if not jobs or jobs.length = 0 then	return res


		'loop through all (potentially assigned) cast entries and check
		'whether their job fits to the desired one
		local castIndex:int = 0
		For local i:int = 0 until cast.length
			local job:TPersonProductionJob = script.jobs[i]
			'flawed data?
			if not job then continue
			'skip different jobs
			if (job.job <> jobFlag and jobFlag <> -1) then continue

			if castIndex > res.length then Throw "GetCastGroup(): castIndex("+castIndex+") > res.length("+res.length+")"


			if not skipEmpty
				if cast[i]
					res[castIndex] = GetPersonBaseCollection().GetByID( cast[i].GetID() )
				else
					res[castIndex] = null
				endif

				castIndex :+ 1
			else
				if cast[i]
					res :+ [ GetPersonBaseCollection().GetByID( cast[i].GetID() ) ]

					castIndex :+ 1
				endif
			endif
		Next
		return res
	End Method


	Method GetCastGroupString:string(jobFlag:int, skipEmpty:int = True, nameOfEmpty:string = "")
		local result:string = ""
		local group:TPersonBase[] = GetCastGroup(jobFlag, skipEmpty)
		for local i:int = 0 to group.length-1
			if skipEmpty and group[i] = null then continue

			if group[i]
				if result <> "" then result:+ ", "
				if group[i].IsInsignificant()
					result:+  GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString( jobFlag ) )
				else
					result:+ group[i].GetFullName()
				endif
			else
				if nameOfEmpty and result <> "" then result:+ ", "
				result:+ nameOfEmpty
			endif
		Next
		return result
	End Method


	Method GetEffectiveFocusPoints:Float()
		if _effectiveFocusPoints < 0 then CalculateEffectiveFocusPoints()
		return _effectiveFocusPoints
	End Method


	Method GetEffectiveFocusPointsMax:Float()
		if _effectiveFocusPointsMax < 0 then CalculateEffectiveFocusPoints()
		return _effectiveFocusPointsMax
	End Method


	'returns the percentage of used to maximum focus points
	Method GetEffectiveFocusPointsRatio:Float(recalculate:Int = False)
		'a "drama" production might have VFX-priority of 0.5, each point
		'spent there is only added by 50% to the effective ratio

		if _effectiveFocusPointsMax < 0 or recalculate then CalculateEffectiveFocusPoints(True)

		if _effectiveFocusPointsMax > 0
			return _effectiveFocusPoints / _effectiveFocusPointsMax
		elseif _effectiveFocusPointsMax = 0
			return 0.0
		endif
	End Method
	
	
	'use this to place focus points where needed (eg custom programme 
	'producers could use this)
	'returns amount of unspend points
	Method AssignEffectiveFocusPoints:Int(pointsToSpend:Int)
		Local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinition(script.mainGenre)

		Local indices:Int[] = productionFocus.GetOrderedFocusIndices()
		For local focusPointID:int = EachIn indices
			'production speed does not add to quality
			if focusPointID = TVTProductionFocus.PRODUCTION_SPEED then continue

			local points:Int
			if genreDefinition
				points = ceil(pointsToSpend * genreDefinition.GetFocusPointPriority(focusPointID))
			else
				points = ceil(pointsToSpend * (pointsToSpend / Max(1, (indices.length-1))))
			endif
			points = Min(pointsToSpend, points)
		
			SetProductionFocus(focusPointID, points)
			
			pointsToSpend :- points
		Next
		
		Return pointsToSpend
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


	Method CalculateScriptGenreFit:Float(recalculate:int = False)
		if _scriptGenreFit < 0 Then _scriptGenreFit = script.CalculateGenreCriteriaFit()

		return _scriptGenreFit
	End Method


	'calculate script value modificator
	'good casts could improve a script a bit
	Method CalculateScriptPotentialMod:Float(recalculate:int = False)
		if scriptPotentialModCached and not recalculate then return scriptPotentialMod

		local castXPSum:Float, personCount:int
		For local castIndex:int = 0 until cast.length
			local person:TPersonBase = cast[castIndex]
			if not person then continue

			local job:TPersonProductionJob = script.jobs[castIndex]
			if not job then continue

			'castXP to improve a script depends on
			'- work done (for the given job) and
			'- experience gained
			local jobsDone:int = 1.0 * person.HasJob(job.job) + 0.10 * person.GetTotalProductionJobsDone() + 0.90 * person.GetProductionJobsDone( job.job )
			'euler strength: 2.5, so for done jobs: 22%, 39%, 52%, ...
			local castXP:Float = THelper.LogisticalInfluence_Euler(Min(1.0, 0.1 * jobsDone), 2.5)

			castXP :* 1.0 + 0.15 * person.GetEffectiveJobExperiencePercentage(job.job)

			castXPSum :+ castXP
			personCount :+ 1
		Next
		scriptPotentialModCached = True

		if personCount > 0
			scriptPotentialMod = 1.0 + (castXPSum / personCount) * script.GetPotential()
		else
			scriptPotentialMod = 1.0
		endif

		return scriptPotentialMod
	End Method



	Method CalculateCastSympathy:Float(recalculate:int = False)
		if castSympathyCached and not recalculate then return castSympathy

		if not owner then return 1.0

		local personSympathy:Float = 0.0
		local personCount:int = 0

		For local castIndex:int = 0 until cast.length
			local person:TPersonBase = cast[castIndex]
			If person
				personSympathy :+ person.GetPersonalityData().GetChannelSympathy( owner )
			EndIf
			personCount :+ 1
		Next
		if personCount > 0
			castSympathy = personSympathy / personCount
		else
			castSympathy = 0.0
		endif

		castSympathyCached = True

		return castSympathy
	End Method


	'describes how difficult it is to fit the whole cast
	'the more people, the harder it is (and the higher the value.
	'returns a value between 0.0 and 1.0
	Method CalculateCastComplexity:Float(recalculate:int = False)
		if castComplexity >= 0 and not recalculate then return castComplexity

		'cast size => complexity
		'0 => 0
		'1 => 0.1
		'2 => 0.19
		'3 => ...
		castComplexity = 1.0 - 0.9^cast.length

		return castComplexity
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
			local person:TPersonBase = cast[castIndex]
			if not person then continue
			
			local productionData:TPersonProductionBaseData = person.GetProductionData()
			local personalityData:TPersonPersonalityBaseData = person.GetPersonalityData()
			'amateurs do not have any productionData until their first
			'production finished ...
			If not productionData
				productionData = TPersonProductionBaseData.GetStub()
			EndIf
		
		
			Local genreID:Int =  script.GetMainGenre()
			Local jobID:Int = script.jobs[castIndex].job

			local personFit:Float = 0.0
			local genreFit:Float = 0.0



			'=== GENRE FIT ===

			'== GENRE FIT #1
			'check if person is experienced in this genre because of
			'already done productions

			'main genre - 96% reached after 10 productions
			'euler strength: 3.0, so for done jobs: 26%, 45%, 59%, ...
			'(it is easier to adopt for a genre than for a job itself)
			local mainGenreFit:Float = THelper.LogisticalInfluence_Euler(Min(1.0, 0.1 * productionData.GetProducedGenreCount( script.GetMainGenre() )), 3)
			'sub genre
			if script.subGenres and script.subGenres.length > 0
				local subGenreFit:Float = 0.0
				For local genre:int = EachIn script.subGenres
					'96% reached after 8 productions
					subGenreFit :+ THelper.LogisticalInfluence_Euler(Min(1.0, 0.125 * productionData.GetProducedGenreCount( genre )), 3)
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
				if productionData.GetTopGenre() = script.GetMainGenre()
					genreFit = Min(1.0, genreFit + 0.20)
				endif
			endif



			'=== JOB FIT ===
			local job:TPersonProductionJob = script.jobs[castIndex]
			local jobsDone:int = 1.0 * person.HasJob(job.job) + 0.10 * person.GetTotalProductionJobsDone() + 0.90 * person.GetProductionJobsDone( job.job )
			'euler strength: 2.5, so for done jobs: 22%, 39%, 52%, ...
			local jobFit:Float = THelper.LogisticalInfluence_Euler(Min(1.0, 0.1 * jobsDone), 2.5)
			local jobFitSwitched:Int = (RandRange(0,100) < 5)
			'by 5% chance "switch" effect
			if jobFitSwitched then jobFit = 1.0 - jobFit


			'=== ATTRIBUTES - GENRE MOD ===
			'allows to gain bonus from having the right attributes for
			'the desired job, regardless of whether you are experienced
			'in this job or not
			'a final attributeMod of 1.0 means they are 
			local attributeMod:Float = 0
			local attributeCount:int = 0
			'loop through all attributes and add their weighted values
			for local i:int = 1 to TVTPersonPersonalityAttribute.count
				local attributeID:int = TVTPersonPersonalityAttribute.GetAtIndex(i)
				local attributeGenre:Float = genreDefinition.GetCastAttribute(job.job, attributeID)
				local attributePerson:Float = personalityData.GetAttributeValue(attributeID, jobID, genreID)
				'skip if attribute is not giving bonus or malus for the
				'genre. "0" means it is "as important as others" 
				'(~0 as floats could be "0.00001")
				if MathHelper.AreApproximatelyEqual(attributeGenre, 0.0) then continue

 				attributeMod :+ attributeGenre * attributePerson
				attributeCount :+ 1
				'print person.GetFullName() + ":  " + TVTPersonPersonality.GetAsString(attributeID) + " : personValue="+attributePerson + " genreValue="+attributeGenre
			Next
			'calc average
			if attributeCount > 1 Then attributeMod :/ attributeCount
			'add the attribute bonus/malus
			'we add the 1.0 afterwards to exclude it from "average calc"
			attributeMod = 1.0 + attributeMod


			'if the cast defines a specific gender for this position,
			'then we reduce the personFit by 10-20%.
			'This happens for 80% of all "wrong-gender"-assignments.
			'The other 12% have luck - they perfectly seem to fit into
			'that role.
			'And even 8% benefit from being another gender (script writer
			'was wrong then ;-))
			local genderFit:Float = 1.0
			local genderFitSwitched:Int = False
			if job.gender <> 0
				if person.gender <> job.gender
					local luck:int = RandRange(0,100)
					if luck <= 80 '80%
						genderFit = RandRange(10,20)/100.0
						genderFitSwitched = True
					elseif luck <= 88 '8%
						genderFit = RandRange(110,120)/100.0
						genderFitSwitched = True
					else
						'no change
					endif
				endif
			endif



			'=== TOTAL FIT ===

			personFit = (0.3 * genreFit + 0.7 * jobFit) * genderFit
			'if the person does not know anything about the done job
			'chances are high for the person not fitting at all
			if jobFit < 0.1 and RandRange(0,100) < 85
				personFit :* 0.25
			endif
			'a persons maximum fit is 0.75 (without attributes)
			personFit :* 0.75
			'apply attribute mod (so persons with attributes are better)
			personFit :* attributeMod

			'a persons fit depends on its XP
			'so make 40% of the fit dependend from XP
			'to fit as a show's GUEST it depends on how "good/interesting"
			'you are (depending on your profession)
			personFit = 0.60 * personFit + 0.40 * person.GetEffectiveJobExperiencePercentage(job.job)

			'increase lower fits (increases distance from "nobody" to "novice")
			personFit = THelper.LogisticalInfluence_Euler(personFit, 2)

			
			local attributeDetail1:String
			local attributeDetail2:String
			if person.IsCelebrity()
				for local i:int = 1 to TVTPersonPersonalityAttribute.count
					if i < 4
						attributeDetail1 :+ TVTPersonPersonalityAttribute.GetAsString(i)+ "=" + int(person.GetPersonalityData().GetAttributeValue(i)*100) + "%  "
					else
						attributeDetail2 :+ TVTPersonPersonalityAttribute.GetAsString(i) + "=" + int(person.GetPersonalityData().GetAttributeValue(i)*100) + "%  "
					endif
				Next
			endif

			TLogger.Log("TProductionConcept.CalculateCastFit()", " --------------------", LOG_DEBUG)
			local jobsText:String
			if person._jobs = 0 
				jobsText = "none"
			else
				For local jobID:int = EachIn TVTPersonJob.GetAll(person._jobs)
					if jobsText then jobsText :+ ", "
					jobsText :+ TVTPersonJob.GetAsString(jobID)
				Next
			EndIf
			if person.IsInsignificant()
				TLogger.Log("TProductionConcept.CalculateCastFit()", person.GetFullName() + " [as ~q"+ TVTPersonJob.GetAsString( job.job ) + "~q, amateur, jobs: " + jobsText + "]", LOG_DEBUG)
			else
				TLogger.Log("TProductionConcept.CalculateCastFit()", person.GetFullName() + " [as ~q"+ TVTPersonJob.GetAsString( job.job ) + "~q, professional, jobs: " + jobsText + "]", LOG_DEBUG)
			endif
			TLogger.Log("TProductionConcept.CalculateCastFit()", "     genreFit:  "+genreFit, LOG_DEBUG)
			if jobFitSwitched
				if jobFit < 0.5
					TLogger.Log("TProductionConcept.CalculateCastFit()", "       jobFit:  "+jobFit + " (bad luck)", LOG_DEBUG)
				else
					TLogger.Log("TProductionConcept.CalculateCastFit()", "       jobFit:  "+jobFit + " (good luck)", LOG_DEBUG)
				endif
			else
				TLogger.Log("TProductionConcept.CalculateCastFit()", "       jobFit:  "+jobFit, LOG_DEBUG)
			endif
			if genderFitSwitched
				if genderFit < 0.5
					TLogger.Log("TProductionConcept.CalculateCastFit()", "    genderFit:  "+genderFit + " (bad luck)", LOG_DEBUG)
				else
					TLogger.Log("TProductionConcept.CalculateCastFit()", "    genderFit:  "+genderFit + " (good luck)", LOG_DEBUG)
				endif
			else
				TLogger.Log("TProductionConcept.CalculateCastFit()", "    genderFit:  "+genderFit, LOG_DEBUG)
			endif
			TLogger.Log("TProductionConcept.CalculateCastFit()", " attributeMod:  "+attributeMod + "  " + attributeDetail1 + attributeDetail2, LOG_DEBUG)
			
			if person.HasCustomPersonality()
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (sympathy   :  " + person.GetChannelSympathy(owner)+")", LOG_DEBUG)
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (xp         :  " + (person.GetEffectiveJobExperiencePercentage(job.job)*100)+"%)", LOG_DEBUG)
			else
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (sympathy   :  --)", LOG_DEBUG)
				TLogger.Log("TProductionConcept.CalculateCastFit()", " (xp         :  --)", LOG_DEBUG)
			endif
			TLogger.Log("TProductionConcept.CalculateCastFit()", "=   personFit:  "+personFit, LOG_DEBUG)

			castFitSum :+ personFit
			personCount :+1
		Next

		if recalculate or castFit < 0
			if personCount > 0
				castFit = castFitSum / personCount
			else
				castFit = 0
			endif
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
			local person:TPersonBase = cast[castIndex]
			if not person then continue

			local jobID:int = script.jobs[castIndex].job
			local genreID:Int = script.GetMainGenre()
			local personFameMod:Float = 1.0

			personFameMod :+ 0.75 * person.GetPersonalityData().GetAttributeValue(TVTPersonPersonalityAttribute.FAME, jobID, genreID)
			'really experienced persons benefit from it too (eg.
			'won awards and so on)
			personFameMod :+ 0.25 * person.GetEffectiveJobExperiencePercentage(jobID)

			castFameModSum :+ personFameMod
			personCount :+1
		Next

		if recalculate or castFameMod < 0
			if personCount > 0
				castFameMod = castFameModSum / personCount
			else
				castFameMod = 0
			endif
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

		TriggerBaseEvent(GameEventKeys.ProductionConcept_SetProductionFocus, new TData.AddNumber("focusIndex", focusIndex).AddNumber("value", value), Self )

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

			result :+ cast[i].GetJobBaseFee(script.jobs[i].job, script.GetBlocks(), owner)
		Next
		return result
	End Method


	Method GetProductionCost:int()
		if productionCompany
			local fee:int = productionCompany.GetFee(owner) ' script.owner)

			'each set point costs a bit more than the previous
			local focusPoints:int = productionFocus.GetFocusPointsSet()
			For local i:int = 1 until focusPoints
				fee :+ 500*i
			Next
			return fee
		endif

		return 0
	End Method


	Method GetBaseProductionTime:Long()
		local base:Long = 9 * TWorldTime.HOURLENGTH

		local typeTimeMod:Float = 1.0
		local speedPointTimeMod:Float = 1.0
		local teamPointTimeMod:Float = 1.0
		local blockMinimumMod:Float = 1.0

		'live productions are done a bit faster
		if script.IsLive() then typeTimeMod :* 0.9
		'trash makes production way easier
		if script.IsTrash() then typeTimeMod :* 0.8
		'bmovies are done cheaper too
		if script.IsBMovie() then typeTimeMod :* 0.9
		'non-fiction-stuff (documentaries, sport shows...) are less advanced
		if not script.IsFictional() then typeTimeMod :* 0.9


		if productionFocus
			local speedPoints:int = productionFocus.GetFocus(TVTProductionFocus.PRODUCTION_SPEED)
			' 0 points = 1.0
			' 1 point = 93%
			' 2 points = 87% ...
			'10 points = 50%
			speedPointTimeMod = 0.933 ^ speedPoints


			'TEAM (good teams work a bit more efficient)
			local teamPoints:int = productionFocus.GetFocus(TVTProductionFocus.TEAM)
			' 0 points = 1.0
			' 1 point = 97%
			' 2 points = 94% ...
			'10 points = 75%
			teamPointTimeMod = 0.5 + 0.5 * 0.933 ^ teamPoints


			'with a good team, you can record multiple scenes simultaneously
			'exception for live, no shortcut possible there
			if not script.IsLive()
				blockMinimumMod :* (0.97 ^ teamPoints)
			else
				blockMinimumMod = 1.0
			endif


			'POINTS ADD TO TIME !
			local focusPoints:int = productionFocus.GetFocusPointsSet()
			'ignore points without penalty
			focusPoints :- (teamPoints + speedPoints)
			if focusPoints > 0
				For local i:int = 0 until focusPoints
					if script.IsFictional()
						base :+ (15 + i*7) * TWorldTime.MINUTELENGTH
					else
						base :+ (10 + i*5) * TWorldTime.MINUTELENGTH
					endif
				Next
			endif
		endif

		'if there is something defined (eg for live preproductions)
		'then use this. 
		'Result is rounded to "minutes"!
		if script.productionTime > 0
			base = script.productionTime

			base :* speedPointTimeMod
			base :* teamPointTimeMod
			base :* script.productionTimeMod
		else
			base :* typeTimeMod
			base :* speedPointTimeMod
			base :* teamPointTimeMod
			base :* script.productionTimeMod

			base = Max(base, ceil(script.GetBlocks()*blockMinimumMod) * TWorldTime.HOURLENGTH)
		endif
		'round to minutes (TWorldTime.MINUTELENGTH and base are LONG)
		return TWorldTime.MINUTELENGTH * (base / TWorldTime.MINUTELENGTH)
	End Method


	Method IsDepositPaid:int()
		return hasFlag(TVTProductionConceptFlag.DEPOSIT_PAID)<>0
	End Method

	Method IsBalancePaid:int()
		return hasFlag(TVTProductionConceptFlag.BALANCE_PAID)<>0
	End Method


	Method IsProductionFinished:int()
		return hasFlag(TVTProductionConceptFlag.PRODUCTION_FINISHED)<>0
	End Method


	Method IsProductionStarted:int()
		return hasFlag(TVTProductionConceptFlag.PRODUCTION_STARTED)<>0
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
		'already started producing?
		if IsProductionStarted() then return False
		'if IsProductionFinished() then return False

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
		TriggerBaseEvent(GameEventKeys.ProductionFocus_SetFocus, new TData.AddNumber("focusIndex", index).AddNumber("value", GetFocus(index)), Self )
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