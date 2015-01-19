'A TScriptTemplate is the template of each TScript, it contains
'min/max-values, random texts to choose from when creating a script out
'of it etc.

SuperStrict
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.string.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx" 'to access type-constants
Import "game.programme.programmeperson.bmx" 'to access TProgrammePersonJob


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
		Return TScriptTemplate( Super.GetRandom() )
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetScriptTemplateCollection:TScriptTemplateCollection()
	Return TScriptTemplateCollection.GetInstance()
End Function




Type TScriptTemplate Extends TNamedGameObject
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field scriptType:Int = 0
	Field genre:Int
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

	'Variables are used to replace certain %KEYWORDS% in title or
	'description. They are stored as "%KEYWORD%"=>TLocalizedString
	Field variables:TMap
	'placeHolderVariables contain TLocalizedString-objects which are used
	'to replace a specific palceholder. This allows to reuse the exact same
	'random variable for descendants (episodes refering to the same
	'keyword) instead of returning other random elements ("option1|option2")
	Field placeHolderVariables:TMap

	'contains all to fill jobs
	Field cast:TProgrammePersonJob[]
	'contains jobs which could get randomly added during generation
	'of the real script
	Field randomCast:TProgrammePersonJob[]

	'limit the guests to specific job types
	Field allowedGuestTypes:int	= 0

	Field requiredStudioSize:Int = 1
	Field requireAudience:Int = 0
	Field coulisseType1:Int	= -1
	Field coulisseType2:Int	= -1
	Field coulisseType3:Int = -1

	Field targetGroup:Int = -1
	'flags contains bitwise encoded things like xRated, paid, trash ...
	Field flags:Int = 0

	'scripts of series are parent of episode scripts
	Field parentScriptTemplateGUID:string = ""
	'all associated child scripts (episodes)
	Field subScriptTemplates:TScriptTemplate[]


	'override to add another generic naming
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "scripttemplate-"+id
		self.GUID = GUID
	End Method


	Method hasFlag:Int(flag:Int)
		Return flags & flag
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	'override
	Method GetTitle:string()
		if title then return title.Get()
		return ""
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
		if not placeHolderVariables then placeHolderVariables = CreateMap()
		placeHolderVariables.insert(key, obj)
	End Method


	Method GetPlaceHolderVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True)
		local result:TLocalizedString
		if placeHolderVariables then result = TLocalizedString(placeHolderVariables.ValueForKey(key))

		if not result and createDefault
			result = new TLocalizedString
			result.Set(defaultValue)
		endif
		return result
	End Method


	Method AddVariable(key:string, obj:object)
		if not variables then variables = CreateMap()
		variables.insert(key, obj)
	End Method


	Method GetVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True)
		local result:TLocalizedString
		if variables then result = TLocalizedString(variables.ValueForKey(key))

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
		local result:TLocalizedString = new TLocalizedString

		'for each defined language we check for existant placeholders
		'which then get replaced by a random string stored in the
		'variable with the same name
		For local lang:string = EachIn text.GetLanguageKeys()
			local value:string = text.Get(lang)
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
					'store the reduced variant
					AddPlaceHolderVariable(placeHolder, replacement)

					'store the replacement in the value
					value = value.replace(placeHolder, replacement.Get(lang))
				endif
			Next
			
			result.Set(value, lang)
		Next
	
		return result
	End Method	

	'override default method to add subscripttemplates
	Method SetOwner:int(owner:int=0)
		self.owner = owner

		'do the same for all children
		For local scriptTemplate:TScriptTemplate = eachin subScriptTemplates
			scriptTemplate.SetOwner(owner)
		Next
		return TRUE
	End Method


	'returns a title with all placeholders replaced
	Method GenerateFinalTitle:TLocalizedString()
		return _ReplacePlaceholders(title)
	End Method


	'returns a description with all placeholders replaced
	Method GenerateFinalDescription:TLocalizedString()
		return _ReplacePlaceholders(description)
	End Method


	Method AddCast:int(job:TProgrammePersonJob)
		if HasCast(job) then return False
		cast :+ [job]
		return True 
	End Method


	Method HasCast:int(job:TProgrammePersonJob)
		'do not check job against jobs in the list, as only the
		'content might be the same but the job a duplicate
		For local doneJob:TProgrammePersonJob = EachIn cast
			if job.person <> doneJob.person then continue 
			if job.job <> doneJob.job then continue 
			if job.role <> doneJob.role then continue

			return True
		Next
		return False
	End Method


	Method AddRandomCast:int(job:TProgrammePersonJob)
		if HasRandomCast(job) then return False
		randomCast :+ [job]
		return True 
	End Method


	Method HasRandomCast:int(job:TProgrammePersonJob)
		For local doneJob:TProgrammePersonJob = EachIn randomCast
			if job.person <> doneJob.person then continue 
			if job.job <> doneJob.job then continue 
			if job.role <> doneJob.role then continue

			return True
		Next
		return False
	End Method


	'returns the "final" cast ... required + some random
	Method GetCast:TProgrammePersonJob[]()
		local result:TProgrammePersonJob[]

		For local job:TProgrammePersonJob = EachIn cast
			result :+ [job]
		next
		'instead of "adding random" ones (and having to care for
		'"already added?") we add all of them to an array and remove
		'random ones....this avoids using too much "random" numbers

		'try to avoid as much randoms as possible (weight to min)
		'but this still allows for "up to all"
		local randomCastAmount:int = WeightedRandRange(0, randomCast.length, 0.1)
		local allRandomCast:TProgrammePersonJob[]
		For local job:TProgrammePersonJob = EachIn randomCast
			allRandomCast :+ [job]
		next
		For local i:int = 0 until randomCastAmount
			local castIndex:int = RandRange(0, allRandomCast.length-1)
			'add cast
			result :+ [allRandomCast[castIndex]]
			'remove selected cast from random ones
			allRandomCast = allRandomCast[..castIndex] + allRandomCast[castIndex+1..]
		Next

		return result
	End Method


	Method GetRawCast:TProgrammePersonJob[]()
		return cast
	End Method


	Method GetRawRandomCast:TProgrammePersonJob[]()
		return randomCast
	End Method


	Method GetCastAtIndex:TProgrammePersonJob(index:int=0)
		if index < 0 or index >= cast.length then return null
		return cast[index]
	End Method
	

	Method GetRandomCastAtIndex:TProgrammePersonJob(index:int=0)
		if index < 0 or index >= randomCast.length then return null
		return randomCast[index]
	End Method


	Method GetSubScriptTemplateCount:int()
		return subScriptTemplates.length
	End Method


	Method GetSubScriptTemplateAtIndex:TScriptTemplate(arrayIndex:int=1)
		if arrayIndex > subScriptTemplates.length or arrayIndex < 0 then return null
		return subScriptTemplates[arrayIndex]
	End Method


	Method GetParentScriptTemplate:TScriptTemplate()
		if not parentScriptTemplateGUID then return self
		return GetScriptTemplateCollection().GetByGUID(parentScriptTemplateGUID)
	End Method


	Method GetSubScriptTemplatePosition:int(scriptTemplate:TScriptTemplate)
		'find my position and add 1
		For local i:int = 0 to GetSubScriptTemplateCount() - 1
			if GetSubScriptTemplateAtIndex(i) = scriptTemplate then return i
		Next
		return 0
	End Method


	'returns the next scriptTemplate of a scriptTemplates parent subScriptTemplates
	Method GetNextSubScriptTemplate:TScriptTemplate()
		if not parentScriptTemplateGUID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentScriptTemplate().GetSubScriptTemplatePosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentScriptTemplate().GetSubScriptTemplateCount() then nextArrayIndex = 0

		return GetParentScriptTemplate().GetSubScriptTemplateAtIndex(nextArrayIndex)
	End Method


	Method AddSubScriptTemplate:int(scriptTemplate:TScriptTemplate)
		'=== ADJUST SCRIPT TYPES ===

		'so subScriptTemplates can ask for sibling scripts
		scriptTemplate.parentScriptTemplateGUID = self.GetGUID()

		'add to array of subScriptTemplates
		subScriptTemplates :+ [scriptTemplate]
		Return TRUE
	End Method


	Method IsLive:int()
		return HasFlag(TVTProgrammeFlag.LIVE)
	End Method


	Method IsAnimation:Int()
		return HasFlag(TVTProgrammeFlag.ANIMATION)
	End Method
	
	
	Method IsCulture:Int()
		return HasFlag(TVTProgrammeFlag.CULTURE)
	End Method	
		
	
	Method IsCult:Int()
		return HasFlag(TVTProgrammeFlag.CULT)
	End Method
	
	
	Method IsTrash:Int()
		return HasFlag(TVTProgrammeFlag.TRASH)
	End Method
	
	Method IsBMovie:Int()
		return HasFlag(TVTProgrammeFlag.BMOVIE)
	End Method
	
	
	Method IsXRated:int()
		return HasFlag(TVTProgrammeFlag.XRATED)
	End Method


	Method IsPaid:int()
		return HasFlag(TVTProgrammeFlag.PAID)
	End Method


	Method SetOutcomeRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		outcomeMin = minValue
		outcomeMax = maxValue
		outcomeSlope = slope
	End Method


	Method SetReviewRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		reviewMin = minValue
		reviewMax = maxValue
		reviewSlope = slope
	End Method


	Method SetSpeedRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		speedMin = minValue
		speedMax = maxValue
		speedSlope = slope
	End Method


	Method SetPotentialRange(minValue:Float, maxValue:Float=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		potentialMin = minValue
		potentialMax = maxValue
		potentialSlope = slope
	End Method


	Method SetBlocksRange(minValue:Int, maxValue:Int=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		blocksMin = minValue
		blocksMax = maxValue
		blocksSlope = slope
	End Method


	Method SetPriceRange(minValue:Int, maxValue:Int=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		priceMin = minValue
		priceMax = maxValue
		priceSlope = slope
	End Method


	Method SetEpisodesRange(minValue:Int, maxValue:Int=-1.0, slope:Float=0.5)
		if maxValue = -1.0 then maxValue = minValue
		episodesMin = minValue
		episodesMax = maxValue
		episodesSlope = slope
	End Method


	Method GetOutcome:Float()
		return 0.001 * WeightedRandRange(1000*outcomeMin, 1000*outcomeMax, outcomeSlope)
	End Method


	Method GetReview:Float()
		return 0.001 * WeightedRandRange(1000*reviewMin, 1000*reviewMax, reviewSlope)
	End Method


	Method GetSpeed:Float()
		return 0.001 * WeightedRandRange(1000*speedMin, 1000*speedMax, speedSlope)
	End Method


	Method GetPotential:Float()
		return 0.001 * WeightedRandRange(1000*potentialMin, 1000*potentialMax, potentialSlope)
	End Method


	Method GetBlocks:Int()
		return WeightedRandRange(blocksMin, blocksMax, blocksSlope)
	End Method

	
	Method GetEpisodes:Int()
		return WeightedRandRange(episodesMin, episodesMax, episodesSlope)
	End Method
	

	Method GetPrice:Int()
		local value:int = WeightedRandRange(priceMin, priceMax, priceSlope)
		'round to next "100" block
		value = Int(Floor(value / 100) * 100)

		Return value
	End Method


	Method isSeries:int()
		return (scriptType & TVTProgrammeLicenceType.SERIES)
	End Method


	Method isEpisode:int()
		return (scriptType & TVTProgrammeLicenceType.EPISODE)
	End Method


	'returns the genre of a script - if a group, the one used the most
	'often is returned
	Method GetGenre:int()
		if GetSubScriptTemplateCount() = 0 then return genre

		local genres:int[]
		local bestGenre:int=0
		For local scriptTemplate:TScriptTemplate = eachin subScriptTemplates
			local genre:int = scriptTemplate.GetGenre()
			if genre > genres.length-1 then genres = genres[..genre+1]
			genres[genre]:+1
		Next
		For local i:int = 0 to genres.length-1
			if genres[i] > bestGenre then bestGenre = i
		Next

		return bestGenre
	End Method


	Method GetGenreString:String(_genre:Int=-1)
		If _genre < 0 Then _genre = self.genre
		'eg. PROGRAMME_GENRE_ACTION
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetGenreStringID(_genre))
	End Method
End Type