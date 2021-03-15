'A TScriptTemplate is the template of each TScript, it contains
'min/max-values, random texts to choose from when creating a script out
'of it etc.

SuperStrict
Import "Dig/base.util.math.bmx"
Import "common.misc.templatevariables.bmx"
Import "game.production.script.base.bmx"
Import "game.gameconstants.bmx" 'to access type-constants
Import "game.world.worldtime.bmx" 'to access world time
Import "game.person.base.bmx"
Import "game.programme.programmerole.bmx"


Type TScriptTemplateCollection Extends TGameObjectCollection
	Global _instance:TScriptTemplateCollection


	Function GetInstance:TScriptTemplateCollection()
		if not _instance then _instance = new TScriptTemplateCollection
		return _instance
	End Function


	Method Initialize:TScriptTemplateCollection()
		Super.Initialize()

		return self
	End Method


	Method GetByID:TScriptTemplate(ID:int)
		Return TScriptTemplate( Super.GetByID(ID) )
	End Method


	Method GetByGUID:TScriptTemplate(GUID:String)
		Return TScriptTemplate( Super.GetByGUID(GUID) )
	End Method


	Method SearchByPartialGUID:TScriptTemplate(GUID:String)
		Return TScriptTemplate( Super.SearchByPartialGUID(GUID) )
	End Method


	Method GetRandom:TScriptTemplate()
		return TScriptTemplate(super.GetRandom())
	End Method


	Method GetRandomByFilter:TScriptTemplate(skipNotAvailable:int = True, skipEpisodes:int = True, containsKeywords:string="", avoidIDs:int[] = null)
		'instead of using "super.GetRandom" we use a custom variant
		'to NOT return episodes...
		local array:TScriptTemplate[]
		'create a full array containing all elements
		For local obj:TScriptTemplate = EachIn entries.Values()
			'skip episode scripts
			if skipEpisodes and obj.scriptLicenceType = TVTProgrammeLicenceType.EPISODE then continue
			'skip not available ones (eg. limit of productions reached)
			if skipNotAvailable and not obj.IsAvailable() then continue

			'skip if not containing given keywords
			if containsKeywords
				local allKeywordsFound:int = True
				For local k:string = EachIn containsKeywords.split(",")
					if obj.keywords.Find(k.Trim()) < 0
						allKeywordsFound = False
						exit
					endif
				Next
				if not allKeywordsFound then continue
			endif

			if avoidIDs and MathHelper.InIntArray(obj.GetID(), avoidIDs) then continue

			array :+ [obj]
		Next
		if array.length = 0 then return Null
		if array.length = 1 then return array[0]

		Return array[(randRange(0, array.length-1))]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetScriptTemplateCollection:TScriptTemplateCollection()
	Return TScriptTemplateCollection.GetInstance()
End Function




Type TScriptTemplate Extends TScriptBase
	'for random generation we split into "min, max" and weighting/slope
	'ratings
	Field outcomeMin:Float, outcomeMax:Float, outcomeSlope:Float
	Field reviewMin:Float, reviewMax:Float, reviewSlope:Float
	Field speedMin:Float, speedMax:Float, speedSlope:Float
	Field potentialMin:Float, potentialMax:Float, potentialSlope:Float

	Field priceMin:int, priceMax:int, priceSlope:Float
	Field blocksMin:int, blocksMax:int, blocksSlope:Float
	'this values define how much of potentially available episodes will
	'get generated for a resulting TScript
	Field episodesMin:int, episodesMax:int, episodesSlope:Float

	'defines if the script is only available from/to/in a specific date
	Field available:int = True
	Field availableScript:string = ""
	Field availableYearRangeFrom:int = -1
	Field availableYearRangeTo:int = -1

	Field templateVariables:TScriptTemplateVariables = null

	'contains all to fill jobs
	Field jobs:TPersonProductionJob[]
	'contains jobs which could get randomly added during generation
	'of the real script
	Field randomJobs:TPersonProductionJob[]

	'limit the guests to specific job types
	Field allowedGuestTypes:int	= 0

	Field studioSizeMin:Int=1
	Field studioSizeMax:int=1
	Field studioSizeSlope:Float=0.5

	Field requireAudience:Int = 0
	Field coulisseType1:Int	= -1
	Field coulisseType2:Int	= -1
	Field coulisseType3:Int = -1

	Field targetGroup:Int = -1

	'stores all TScripts using this base template
	Field usedForScripts:Int[]
	'defines a limit of how often it can be used as base for scripts
	Field usedForScriptsLimit:int = -1

	'manipulators for the production using a script
	Field productionTimeMin:Int = -1
	Field productionTimeMax:Int = -1
	Field productionTimeSlope:Float = 0.5
	'defined in TScriptBase already
	'Field productionTime:Int = -1
	'Field productionTimeMod:Float = 1.0

	Field keywords:string


	Method GenerateGUID:string()
		return "scripttemplate-"+id
	End Method


	'reset things used for random data
	'like placeholders (which are stored there so that children could
	'reuse it)
	Method Reset:int()
		if templateVariables then templateVariables.Reset()
	End Method


	Method GetParentScript:TScriptTemplate()
		if not parentScriptID then return self
		return GetScriptTemplateCollection().GetByID(parentScriptID)
	End Method


	'override
	'return the title without replacing placeholders
	Method GetTitleObj:TLocalizedString()
		return title
	End Method


	'return the description without replacing placeholders
	Method GetDescriptionObj:TLocalizedString()
		return description
	End Method


	'returns a title with all placeholders replaced
	Method GenerateFinalTitle:TLocalizedString()
		if not templateVariables then return title
		return templateVariables.ReplacePlaceholders(title)
	End Method


	'returns a description with all placeholders replaced
	Method GenerateFinalDescription:TLocalizedString()
		if not templateVariables then return description
		return templateVariables.ReplacePlaceholders(description)
	End Method


	Method IsAvailable:int()
		'=== generic availability ===

		'field "available" = false ?
		if not available then return False

		if availableYearRangeFrom > 0 and GetWorldTime().GetYear() < availableYearRangeFrom then return False
		if availableYearRangeTo > 0 and GetWorldTime().GetYear() > availableYearRangeTo then return False

		'a special script expression defines custom rules for adcontracts
		'to be available or not
		if availableScript and not GetScriptExpression().Eval(availableScript)
			return False
		endif


		'=== specific availability ===
		if GetUsedForScriptsLimit() > 0 and GetUsedForScriptsCount() >= GetUsedForScriptsLimit() then return False

		return True
	End Method


	Method GetProductionTime:Int()
		If productionTimeMin >= 0 And productionTimeMax >= 0
			return BiasedRandRange(productionTimeMin, productionTimeMax, productionTimeSlope)
		Endif

		Return productionTime
	End Method


	Method GetUsedForScriptsLimit:int()
		return usedForScriptsLimit
	End Method


	Method GetUsedForScriptsCount:int()
		If not usedForScripts then return 0
		Return usedForScripts.length
	End Method
	
	
	Method IsUsedForScript:int(scriptID:Int)
		If not usedForScripts then return False
		For local i:Int = eachIn usedForScripts
			if i = scriptID then return True
		Next
		Return False
	End Method


	Method AddUsedForScript:Int(scriptID:int)
		if IsUsedForScript(scriptID) Then Return False

		usedForScripts :+ [scriptID]
		Return True
	End Method


	'set a job to the specific index
	'the index must be existing already
	Method SetJobAtIndex:int(index:int=0, job:TPersonProductionJob)
		if index < 0 or index > jobs.length -1 then return false
		jobs[index] = job
		return True
	End Method


	'set a job to the specific index
	'the index must be existing already
	Method SetRandomJobAtIndex:int(index:int=0, job:TPersonProductionJob)
		if index < 0 or index > randomJobs.length -1 then return false
		randomJobs[index] = job
		return True
	End Method


	Method AddJob:int(job:TPersonProductionJob)
		if HasJob(job) then return False
		jobs :+ [job]
		return True
	End Method


	Method HasJob:int(job:TPersonProductionJob)
		For local doneJob:TPersonProductionJob = EachIn jobs
			if job = doneJob then return True
		Next
		return False
	End Method


	Method AddRandomJob:int(job:TPersonProductionJob)
		if HasRandomJob(job) then return False
		randomJobs :+ [job]
		return True
	End Method


	Method HasRandomJob:int(job:TPersonProductionJob)
		For local doneJob:TPersonProductionJob = EachIn randomJobs
			if doneJob = job then Return True
		Next
		Return False
	End Method


	Method HasSimilarRandomJob:int(job:TPersonProductionJob)
		For local doneJob:TPersonProductionJob = EachIn randomJobs
			if job.personID <> doneJob.personID then continue
			if job.job <> doneJob.job then continue
			if job.roleID <> doneJob.roleID then continue

			return True
		Next
		return False
	End Method


	'creates a NEW set of job instances!
	Method GetFinalJobs:TPersonProductionJob[]()
		local result:TPersonProductionJob[] = jobs[ .. ] 'copy jobs into result

		'try to avoid as much randoms as possible (weight to min)
		'but this still allows for "up to all"
		local randomJobsAmount:int = BiasedRandRange(0, randomJobs.length, 0.15)
		If randomJobsAmount = 0
			'nothing to do
		ElseIf randomJobsAmount = 1
			result :+ [randomJobs[RandRange(0, randomJobs.length-1)]]
		Else
			'shuffle all potentially available jobs and take the first
			'x elements
			local shuffledRandomJobs:TPersonProductionJob[] = randomJobs[ .. ] 'copy
			Local shuffleIndex:Int
			Local shuffleTmp:TPersonProductionJob
			For Local i:Int = shuffledRandomJobs.length-1 To 0 Step -1
				shuffleIndex = RandRange(0, shuffledRandomJobs.length-1)
				shuffleTmp = shuffledRandomJobs[i]
				shuffledRandomJobs[i] = shuffledRandomJobs[shuffleIndex]
				shuffledRandomJobs[shuffleIndex] = shuffleTmp
			Next
			
			For local i:int = 0 until randomJobsAmount
				'add job
				result :+ [shuffledRandomJobs[i]]
			Next
		EndIf
		
		
		'convert instances to new copies (to avoid modification of the
		'template jobs)
		For local i:int = 0 until result.length
			result[i] = result[i].Copy()
		Next


		'assign missing roles to actors
		local actorFlag:int = TVTPersonJob.ACTOR | TVTPersonJob.SUPPORTINGACTOR
		local usedRoleIDs:Int[]
		'collect already used role guids
		For local job:TPersonProductionJob = Eachin result
			if not(job.job & actorFlag) then continue
			if job.roleID <> "" then usedRoleIDs :+ [job.roleID]
		Next

		'fill in a free role (if required)
		For local job:TPersonProductionJob = Eachin result
			if job.job & actorFlag = 0 then continue

			if job.roleID = 0
				local filter:TProgrammeRoleFilter
				if job.country <> "" or job.gender > 0
					filter = new TProgrammeRoleFilter
					if job.country <> "" then filter.SetAllowedCountries( [job.country] )
					if job.gender > 0 then filter.SetGender(job.gender)
				endif

				local role:TProgrammeRole
				'20% to reuse an existing role (saves space and RAM)
				if RandRange(0,100) < 20
					local tries:int = 0
					repeat
						role = GetProgrammeRoleCollection().GetRandomByFilter(filter)
						'already used?
						if role and MathHelper.InIntArray(role.GetID(), usedRoleIDs)
							role = Null
						endif
						tries :+ 1
					Until role or tries > 10
					'if role Then print "reuse role: " + role.firstName +" " + role.lastName + "  gender="+role.gender+"  country="+role.countryCode + "  jobCountry="+job.country +"  jobGender="+job.gender
				endif

				If not role
					role = GetProgrammeRoleCollection().CreateRandomRole(job.country, job.gender)
				EndIf

				'assign the role
				job.roleID = role.GetID()
				'and assign the gender definition
				job.gender = role.gender
				usedRoleIDs :+ [role.GetID()]
			endif
		Next

		return result
	End Method


	Method GetRawJobs:TPersonProductionJob[]()
		return jobs
	End Method


	Method GetRawRandomJobs:TPersonProductionJob[]()
		return randomJobs
	End Method


	Method GetJobAtIndex:TPersonProductionJob(index:int=0)
		if index < 0 or index >= jobs.length then return null
		return jobs[index]
	End Method


	Method GetRandomJobAtIndex:TPersonProductionJob(index:int=0)
		if index < 0 or index >= randomJobs.length then return null
		return randomJobs[index]
	End Method


	Method CreateTemplateVariables:TScriptTemplateVariables()
		if not templateVariables then templateVariables = new TScriptTemplateVariables
		templateVariables.SetParentID( self.parentScriptID )

		return templateVariables
	End Method


	'limit values to the given clamps + sort them
	Function _LimitValues(minValue:Float var, maxValue:Float var, clampMin:Float = 0.0, clampMax:Float = 1.0)
		minValue = MathHelper.Clamp(minValue, 0.0, 1.0)
		maxValue = MathHelper.Clamp(maxValue, 0.0, 1.0)
	End Function


	Method SetOutcomeRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		MathHelper.SortValues(minValue, maxValue)
		_LimitValues(minValue, maxValue, 0.0, 1.0)

		outcomeMin = minValue
		outcomeMax = maxValue
		outcomeSlope = slope
	End Method


	Method SetReviewRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		MathHelper.SortValues(minValue, maxValue)
		_LimitValues(minValue, maxValue, 0.0, 1.0)

		reviewMin = minValue
		reviewMax = maxValue
		reviewSlope = slope
	End Method


	Method SetSpeedRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		MathHelper.SortValues(minValue, maxValue)
		_LimitValues(minValue, maxValue, 0.0, 1.0)

		speedMin = minValue
		speedMax = maxValue
		speedSlope = slope
	End Method


	Method SetPotentialRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		MathHelper.SortValues(minValue, maxValue)
		_LimitValues(minValue, maxValue, 0.0, 1.0)

		potentialMin = minValue
		potentialMax = maxValue
		potentialSlope = slope
	End Method


	Method SetBlocksRange(minValue:Int, maxValue:Int=-1, slope:Float=0.5)
		if maxValue = -1 then maxValue = minValue
		MathHelper.SortIntValues(minValue, maxValue)
		minValue = max(1, minValue)
		maxValue = max(1, maxValue)

		blocksMin = minValue
		blocksMax = maxValue
		blocksSlope = slope
	End Method


	Method SetPriceRange(minValue:Int, maxValue:Int=-1, slope:Float=0.5)
		if maxValue = -1 then maxValue = minValue
		MathHelper.SortIntValues(minValue, maxValue)
		minValue = max(1, minValue)
		maxValue = max(1, maxValue)

		priceMin = minValue
		priceMax = maxValue
		priceSlope = slope
	End Method


	Method SetEpisodesRange(minValue:Int, maxValue:Int=-1.0, slope:Float=0.5)
		if maxValue = -1 then maxValue = minValue
		MathHelper.SortIntValues(minValue, maxValue)
		minValue = max(1, minValue)
		maxValue = max(1, maxValue)

		episodesMin = minValue
		episodesMax = maxValue
		episodesSlope = slope
	End Method


	Method SetStudioSizeRange(minValue:int=1, maxValue:int=-1, slope:Float=0.5)
		if maxValue = -1 then maxValue = minValue
		MathHelper.SortIntValues(minValue, maxValue)
		minValue = max(1, minValue)
		maxValue = max(1, maxValue)

		if maxValue = -1 then maxValue = minValue
		studioSizeMin = minValue
		studioSizeMax = maxValue
		studioSizeSlope = slope
	End Method


	Method GetOutcome:Float()
		return 0.001 * BiasedRandRange(int(1000*outcomeMin), int(1000*outcomeMax), outcomeSlope)
	End Method


	Method GetReview:Float()
		return 0.001 * BiasedRandRange(int(1000*reviewMin), int(1000*reviewMax), reviewSlope)
	End Method


	Method GetSpeed:Float()
		return 0.001 * BiasedRandRange(int(1000*speedMin), int(1000*speedMax), speedSlope)
	End Method


	Method GetPotential:Float()
		return 0.001 * BiasedRandRange(int(1000*potentialMin), int(1000*potentialMax), potentialSlope)
	End Method


	Method GetBlocks:Int()
		return BiasedRandRange(blocksMin, blocksMax, blocksSlope)
	End Method


	Method GetEpisodes:Int()
		return BiasedRandRange(episodesMin, episodesMax, episodesSlope)
	End Method


	Method GetStudioSize:Int()
		return BiasedRandRange(studioSizeMin, studioSizeMax, studioSizeSlope)
	End Method


	Method GetPrice:Int()
		local value:int = BiasedRandRange(priceMin, priceMax, priceSlope)
		'round to next "100" block
		value = Int(Floor(value / 100) * 100)

		Return value
	End Method
End Type




Type TScriptTemplateVariables extends TTemplateVariables
	Field parentID:int
	Field parent:TScriptTemplate {nosave}


	Method GetParentTemplateVariables:TTemplateVariables()
		if parentID and not parent
			parent = GetScriptTemplateCollection().GetByID(parentID)
		endif

		if parent then return parent.templateVariables
		return Null
	End Method


	Method SetParent(parent:TScriptTemplate)
		if parent
			parentID = parent.GetID()
			self.parent = parent
		else
			parentID = 0
			self.parent = null
		endif
	End Method


	Method SetParentID(id:int)
		parent = null
		parentID = id
	End Method
End Type
