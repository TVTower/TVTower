'A TScriptTemplate is the template of each TScript, it contains
'min/max-values, random texts to choose from when creating a script out
'of it etc.

SuperStrict
Import "Dig/base.util.math.bmx"
Import "game.production.script.base.bmx"
Import "game.gameconstants.bmx" 'to access type-constants
Import "game.programme.programmeperson.base.bmx" 'to access TProgrammePersonJob
Import "game.gameinformation.base.bmx" 'to access worldtime


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


	Method GetByGUID:TScriptTemplate(GUID:String)
		Return TScriptTemplate( Super.GetByGUID(GUID) )
	End Method

	
	Method GetRandom:TScriptTemplate()
		return TScriptTemplate(super.GetRandom())
	End Method


	Method GetRandomByFilter:TScriptTemplate(skipNotAvailable:int = True, skipEpisodes:int = True)
		'instead of using "super.GetRandom" we use a custom variant
		'to NOT return episodes...
		local array:TScriptTemplate[]
		'create a full array containing all elements
		For local obj:TScriptTemplate = EachIn entries.Values()
			'skip episode scripts
			if skipEpisodes and obj.scriptLicenceType = TVTProgrammeLicenceType.EPISODE then continue
			'skip not available ones (eg. limit of productions reached)
			if skipNotAvailable and not obj.IsAvailable() then continue

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
	Field availableYearRangeFrom:int = -1
	Field availableYearRangeTo:int = -1

	'Variables are used to replace certain %KEYWORDS% in title or
	'description. They are stored as "%KEYWORD%"=>TLocalizedString
	Field variables:TMap
	'placeHolderVariables contain TLocalizedString-objects which are used
	'to replace a specific palceholder. This allows to reuse the exact same
	'random variable for descendants (episodes refering to the same
	'keyword) instead of returning other random elements ("option1|option2")
	Field placeHolderVariables:TMap

	'contains all to fill jobs
	Field jobs:TProgrammePersonJob[]
	'contains jobs which could get randomly added during generation
	'of the real script
	Field randomJobs:TProgrammePersonJob[]
	'contains jobs with randomly assigned jobs
	'so the script knows what to reset in jobs/randomJobs after usage
	Field randomAssignedRoles:TProgrammePersonJob[]

	'limit the guests to specific job types
	Field allowedGuestTypes:int	= 0

	Field studioSizeMin:Int, studioSizeMax:int, studioSizeSlope:Float

	Field requireAudience:Int = 0
	Field coulisseType1:Int	= -1
	Field coulisseType2:Int	= -1
	Field coulisseType3:Int = -1

	Field targetGroup:Int = -1

	Field productionLimit:int = -1
	Field productionTimes:int = 0


	'reset things used for random data
	'like placeholders (which are stored there so that children could
	'reuse it)
	Method Reset:int()
		placeHolderVariables = null
		'reset previously stored randomly assigned roles
		if randomAssignedRoles
			for local job:TProgrammePersonJob = EachIn randomAssignedRoles
				job.roleGUID = ""
			Next
			randomAssignedRoles = new TProgrammePersonJob[0]
		endif
	End Method
	

	'override to add another generic naming
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "scripttemplate-"+id
		self.GUID = GUID
	End Method


	Method GetParentScript:TScriptTemplate()
		if not parentScriptGUID then return self
		return GetScriptTemplateCollection().GetByGUID(parentScriptGUID)
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


	Method AddPlaceHolderVariable(key:string, obj:object)
		key = key.toLower()

		if not placeHolderVariables then placeHolderVariables = CreateMap()
		placeHolderVariables.insert(key, obj)
	End Method


	Method GetPlaceHolderVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True)
		key = key.toLower()

		local result:TLocalizedString
		if placeHolderVariables then result = TLocalizedString(placeHolderVariables.ValueForKey(key))

		if not result and parentScriptGUID <> ""
			local parent:TScriptTemplate = GetParentScript()
			if parent <> self then result = parent.GetPlaceholderVariableString(key, defaultValue, createDefault)
		endif
		
		if not result and createDefault
			result = new TLocalizedString
			result.Set(defaultValue)
		endif
		return result
	End Method


	Method AddVariable(key:string, obj:object)
		key = key.toLower()
		if not variables then variables = CreateMap()
		variables.insert(key, obj)
	End Method


	Method GetVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True)
		key = key.toLower()

		local result:TLocalizedString
		if variables then result = TLocalizedString(variables.ValueForKey(key))

		if not result and parentScriptGUID <> ""
			local parent:TScriptTemplate = GetParentScript()
			if parent <> self then result = parent.GetVariableString(key, defaultValue, createDefault)
		endif

		if not result and createDefault
			result = new TLocalizedString
			result.Set(defaultValue)
		endif
		return result
	End Method


	Method _GetRandomFromLocalizedString:TLocalizedString(localizedString:TLocalizedString, defaultValue:string = "MISSING")
		local result:TLocalizedString = new TLocalizedString
		if not localizedString
			result.set(defaultValue)
			return result
		endif
		
		'loop through languages and calculate maximum amount of
		'random values -> this gets our "reference count" if something
		'is missing
		local maxRandom:int = 0
		For local lang:string = EachIn localizedString.GetLanguageKeys()
			local values:string[] = localizedString.Get(lang).split("|")
			maxRandom = max(maxRandom, values.length - 1)
		Next

		'decide which random portion we want
		local useRandom:int = RandRange(0, maxRandom)

		For local lang:string = EachIn localizedString.GetLanguageKeys()
			local values:string[] = localizedString.Get(lang).split("|")
			'if random index is bigger than the array, set the default
			'as resulting value for this language
			if values.length-1 < useRandom
				result.set(defaultValue, lang)
			else
				result.set(values[useRandom], lang)
			endif
		Next
		
		return result
	End Method


	Method _ReplacePlaceholders:TLocalizedString(text:TLocalizedString)
		local result:TLocalizedString = text.copy()

		'do it 3 times, this allows for placeholder definitions within
		'placeholders (at least some of them)!
		for local i:int = 0 to 2
			'for each defined language we check for existent placeholders
			'which then get replaced by a random string stored in the
			'variable with the same name
			For local lang:string = EachIn text.GetLanguageKeys()
				'use result already (to allow recursive-replacement)
				local value:string = result.Get(lang)
				local placeHolders:string[] = StringHelper.ExtractPlaceholders(value, "%")

				local replacement:TLocalizedString
				for local placeHolder:string = EachIn placeHolders
					'check if there is already a placeholder variable stored
					replacement = GetPlaceholderVariableString(placeHolder, "", False)
					'check if the variable is defined (this leaves global
					'placeholders like %ACTOR% intact even without further
					'variable definition)
					if not replacement then replacement = GetVariableString(placeHolder, "", False)
					'only use ONE option out of the group ("option1|option2|option3")
					if replacement
						replacement = _GetRandomFromLocalizedString( replacement )
						'if the parent stores this variable (too) then save
						'the placeholder there instead of the children
						'so other children could use the same placeholders
						'(if there is no parent then "self" is returned)
						if GetParentScript().GetVariableString(placeHolder, "", False)
							GetParentScript().AddPlaceHolderVariable(placeHolder, replacement)
						else
							AddPlaceHolderVariable(placeHolder, replacement)
						endif
						'store the replacement in the value
						value = value.replace(placeHolder, replacement.Get(lang))
					endif
				Next
				
				result.Set(value, lang)
			Next
		Next


		'replace common placeholders (%GAMEYEAR% and so on)
		'loop over "text", but replace in "result"
		For local lang:string = EachIn text.GetLanguageKeys()
			local value:string = result.Get(lang)
			local placeHolders:string[] = StringHelper.ExtractPlaceholders(value, "%")
			for local placeHolder:string = EachIn placeHolders
				local replacement:string = placeHolder
				Select placeHolder.toLower()
					case "%gameyear%"
						replacement = string(GetGameInformation("worldtime", "gameyear"))
				End Select

				value = value.replace(placeHolder, replacement)
			Next

			result.Set(value, lang)
		Next
	
		return result
	End Method	


	'returns a title with all placeholders replaced
	Method GenerateFinalTitle:TLocalizedString()
		return _ReplacePlaceholders(title)
	End Method


	'returns a description with all placeholders replaced
	Method GenerateFinalDescription:TLocalizedString()
		return _ReplacePlaceholders(description)
	End Method


	Method IsAvailable:int()
		if GetProductionLimit() > 0 and GetProductionTimes() >= GetProductionLimit() then return False
		return True
	End Method


	Method GetProductionLimit:int()
		return productionLimit
	End Method


	Method GetProductionTimes:int()
		return productionTimes
	End Method


	Method SetProductionTimes(times:int)
		productionTimes = times
	End Method


	Method FinishProduction(programmeLicenceGUID:string)
		SetProductionTimes( GetProductionTimes() + 1)
	End Method
		

	'set a job to the specific index
	'the index must be existing already
	Method SetJobAtIndex:int(index:int=0, job:TProgrammePersonJob)
		if index < 0 or index > jobs.length -1 then return false
		jobs[index] = job 
		return True
	End Method


	'set a job to the specific index
	'the index must be existing already
	Method SetRandomJobAtIndex:int(index:int=0, job:TProgrammePersonJob)
		if index < 0 or index > randomJobs.length -1 then return false
		randomJobs[index] = job 
		return True
	End Method


	Method AddJob:int(job:TProgrammePersonJob)
		if HasJob(job) then return False
		jobs :+ [job]
		return True 
	End Method


	Method HasJob:int(job:TProgrammePersonJob)
		For local doneJob:TProgrammePersonJob = EachIn jobs
			if job = doneJob then return True
		Next
		return False
	End Method


	Method AddRandomJob:int(job:TProgrammePersonJob)
		if HasRandomJob(job) then return False
		randomJobs :+ [job]
		return True 
	End Method


	Method HasRandomJob:int(job:TProgrammePersonJob)
		For local doneJob:TProgrammePersonJob = EachIn randomJobs
			if job.personGUID <> doneJob.personGUID then continue 
			if job.job <> doneJob.job then continue 
			if job.roleGUID <> doneJob.roleGUID then continue

			return True
		Next
		return False
	End Method


	'returns the "final" cast ... required + some random
	Method GetJobs:TProgrammePersonJob[]()
		local result:TProgrammePersonJob[]

		For local job:TProgrammePersonJob = EachIn jobs
			result :+ [job]
		next
		'instead of "adding random" ones (and having to care for
		'"already added?") we add all of them to an array and remove
		'random ones....this avoids using too much "random" numbers

		'try to avoid as much randoms as possible (weight to min)
		'but this still allows for "up to all"
		local randomJobsAmount:int = WeightedRandRange(0, randomJobs.length, 0.1)
		local allRandomJobs:TProgrammePersonJob[]
		For local job:TProgrammePersonJob = EachIn randomJobs
			allRandomJobs :+ [job]
		next
		For local i:int = 0 until randomJobsAmount
			local jobIndex:int = RandRange(0, allRandomJobs.length-1)
			'add job
			result :+ [allRandomJobs[jobIndex]]
			'remove selected cast from random ones
			allRandomJobs = allRandomJobs[..jobIndex] + allRandomJobs[jobIndex+1..]
		Next

		'assign missing roles to actors
		local actorFlag:int = TVTProgrammePersonJob.ACTOR | TVTProgrammePersonJob.SUPPORTINGACTOR
		local usedRoleGUIDs:string[]
		'collect already used role guids
		For local job:TProgrammePersonJob = Eachin result
			if not(job.job & actorFlag) then continue
			if job.roleGUID <> "" then usedRoleGUIDs :+ [job.roleGUID]
		Next

		'fill in a free guid (if possible)
		For local job:TProgrammePersonJob = Eachin result
			if job.job & actorFlag = 0 then continue

			if job.roleGUID = ""
				local filter:TProgrammeRoleFilter
				if job.country <> "" or job.gender > 0
					filter = new TProgrammeRoleFilter
					if job.country <> "" then filter.SetAllowedCountries( [job.country] )
					if job.gender > 0 then filter.SetGender(job.gender)
				endif

				local validRoleGUID:string = ""
				local tries:int = 0
				local role:TProgrammeRole
				repeat
					role = GetProgrammeRoleCollection().GetRandomByFilter(filter)

					'nothing found for filter -> next try without a filter
					if not role and filter then filter = null; continue

					if role then validRoleGUID = role.GetGUID()
					'reset guid again if in array
					if tries < 50 and StringHelper.InArray(validRoleGUID, usedRoleGUIDs)
						validRoleGUID = ""
					endif
					tries :+ 1
				until validRoleGUID
				'assign the role
				job.roleGUID = validRoleGUID
				usedRoleGUIDs :+ [validRoleGUID]

				'mark the job for having a randomly assigned role
				randomAssignedRoles :+ [job]
			endif
		Next
		

		return result
	End Method


	Method GetRawJobs:TProgrammePersonJob[]()
		return jobs
	End Method


	Method GetRawRandomJobs:TProgrammePersonJob[]()
		return randomJobs
	End Method


	Method GetJobAtIndex:TProgrammePersonJob(index:int=0)
		if index < 0 or index >= jobs.length then return null
		return jobs[index]
	End Method
	

	Method GetRandomJobAtIndex:TProgrammePersonJob(index:int=0)
		if index < 0 or index >= randomJobs.length then return null
		return randomJobs[index]
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
		return 0.001 * WeightedRandRange(int(1000*outcomeMin), int(1000*outcomeMax), outcomeSlope)
	End Method


	Method GetReview:Float()
		return 0.001 * WeightedRandRange(int(1000*reviewMin), int(1000*reviewMax), reviewSlope)
	End Method


	Method GetSpeed:Float()
		return 0.001 * WeightedRandRange(int(1000*speedMin), int(1000*speedMax), speedSlope)
	End Method


	Method GetPotential:Float()
		return 0.001 * WeightedRandRange(int(1000*potentialMin), int(1000*potentialMax), potentialSlope)
	End Method


	Method GetBlocks:Int()
		return WeightedRandRange(blocksMin, blocksMax, blocksSlope)
	End Method

	
	Method GetEpisodes:Int()
		return WeightedRandRange(episodesMin, episodesMax, episodesSlope)
	End Method


	Method GetStudioSize:Int()
		return WeightedRandRange(studioSizeMin, studioSizeMax, studioSizeSlope)
	End Method	


	Method GetPrice:Int()
		local value:int = WeightedRandRange(priceMin, priceMax, priceSlope)
		'round to next "100" block
		value = Int(Floor(value / 100) * 100)

		Return value
	End Method
End Type