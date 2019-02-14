SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.math.bmx"
Import "game.gameobject.bmx"
Import "game.player.finance.bmx"
Import "game.player.base.bmx"
Import "basefunctions.bmx" 'dottedValue
Import "game.production.scripttemplate.bmx"
Import "game.broadcast.genredefinition.movie.bmx"
Import "game.gamescriptexpression.base.bmx"
'to access datasheet-functions
Import "common.misc.datasheet.bmx"



Type TScriptCollection Extends TGameObjectCollection
	'stores "languagecode::name"=>"used by id" connections
	Field protectedTitles:TStringMap = new TStringMap
	'=== CACHE ===
	'cache for faster access

	'holding used scripts
	Field _usedScripts:TList = CreateList() {nosave}
	Field _availableScripts:TList = CreateList() {nosave}
	Field _parentScripts:TList = CreateList() {nosave}

	Global _instance:TScriptCollection


	Function GetInstance:TScriptCollection()
		if not _instance then _instance = new TScriptCollection
		return _instance
	End Function


	Method Initialize:TScriptCollection()
		Super.Initialize()
		return self
	End Method


	Method _InvalidateCaches()
		_usedScripts = Null
		_availableScripts = Null
		_parentScripts = Null
	End Method


	Method Add:int(obj:TGameObject)
		local script:TScript = TScript(obj)
		if not script then return False

		_InvalidateCaches()
		'add child scripts too
		For local subScript:TScript = EachIn script.subScripts
			Add(subScript)
		Next

		'protect title
		If not script.HasParentScript()
			AddTitleProtection(script.customTitle, script.GetID())
			AddTitleProtection(script.title, script.GetID())
		EndIf

		return Super.Add(script)
	End Method


	Method Remove:int(obj:TGameObject)
		local script:TScript = TScript(obj)
		if not script then return False

		_InvalidateCaches()
		'remove child scripts too
		For local subScript:TScript = EachIn script.subScripts
			Remove(subScript)
		Next

		'unprotect title
		If not script.HasParentScript()
			RemoveTitleProtection(script.customTitle)
			RemoveTitleProtection(script.title)
		EndIf

		return Super.Remove(script)
	End Method


	Method GetByID:TScript(ID:int)
		Return TScript( Super.GetByID(ID) )
	End Method


	Method GetByGUID:TScript(GUID:String)
		Return TScript( Super.GetByGUID(GUID) )
	End Method


	Method GenerateFromTemplate:TScript(templateOrTemplateGUID:object)
		local template:TScriptTemplate
		if TScriptTemplate(templateOrTemplateGUID)
			template = TScriptTemplate(templateOrTemplateGUID)
		else
			template = GetScriptTemplateCollection().GetByGUID( string(templateOrTemplateGUID) )
			if not template then return Null
		endif

		local script:TScript = TScript.CreateFromTemplate(template)
		script.SetOwner(TOwnedGameObject.OWNER_NOBODY)
		Add(script)
		return script
	End Method


	Method GenerateFromTemplateID:TScript(ID:int)
		local template:TScriptTemplate = GetScriptTemplateCollection().GetByID( ID )
		if not template then return Null

		return GenerateFromTemplate(template)
	End Method


	Method GenerateRandom:TScript(avoidTemplateIDs:int[])
		local template:TScriptTemplate
		if not avoidTemplateIDs or avoidTemplateIDs.length = 0
			template = GetScriptTemplateCollection().GetRandomByFilter(True, True)
		else
			local foundValid:int = False
			local tries:int = 0

			template = GetScriptTemplateCollection().GetRandomByFilter(True, True, "", avoidTemplateIDs)
			'get a random one, ignore avoid IDs
			if not template and avoidTemplateIDs and avoidTemplateIDs.length > 0
				print "TScriptCollection.GenerateRandom() - warning. No available template found (avoid-list too big?). Trying an avoided entry."
				template = GetScriptTemplateCollection().GetRandomByFilter(True, True)
			endif
			'get a random one, ignore availability
			if not template
				print "TScriptCollection.GenerateRandom() - failed. No available template found (avoid-list too big?). Using an unfiltered entry."
				template = GetScriptTemplateCollection().GetRandomByFilter(False, True)
			endif
		endif

		local script:TScript = TScript.CreateFromTemplate(template)
		script.SetOwner(TOwnedGameObject.OWNER_NOBODY)
		Add(script)

		return script
	End Method


	Method GetRandomAvailable:TScript(avoidTemplateIDs:int[] = null)
		'if no script is available, create (and return) some a new one
		if GetAvailableScriptList().Count() = 0 then return GenerateRandom(avoidTemplateIDs)

		'fetch a random script
		if not avoidTemplateIDs or avoidTemplateIDs.length = 0
			return TScript(GetAvailableScriptList().ValueAtIndex(randRange(0, GetAvailableScriptList().Count() - 1)))
		else
			local possibleScripts:TScript[]
			for local s:TScript = EachIn GetAvailableScriptList()
				if not s.basedOnScriptTemplateID or not MathHelper.InIntArray(s.basedOnScriptTemplateID, avoidTemplateIDs)
					possibleScripts :+ [s]
				endif
			next
			if possibleScripts.length = 0 then return GenerateRandom(avoidTemplateIDs)

			return possibleScripts[ randRange(0, possibleScripts.length - 1) ]
		endif
	End Method


	Method GetTitleProtectedByID:int(title:object)
		if TLocalizedString(title)
			local lsTitle:TLocalizedString = TLocalizedString(title)
			for local langCode:string = EachIn lsTitle.GetLanguageKeys()
				return int(string(protectedTitles.ValueForKey(langCode + "::" + lsTitle.Get(langCode).ToLower())))
			next
		elseif string(title) <> ""
			return int(string((protectedTitles.ValueForKey("custom::" + string(title).ToLower()))))
		endif
	End Method


	Method IsTitleProtected:int(title:object)
		if TLocalizedString(title)
			local lsTitle:TLocalizedString = TLocalizedString(title)
			for local langCode:string = EachIn lsTitle.GetLanguageKeys()
				if protectedTitles.Contains(langCode + "::" + lsTitle.Get(langCode).ToLower()) then return True
			next
		elseif string(title) <> ""
			if protectedTitles.Contains("custom::" + string(title).ToLower()) then return True
		endif
		return False
	End Method


	'pass string or TLocalizedString
	Method AddTitleProtection(title:object, scriptID:int)
		if TLocalizedString(title)
			local lsTitle:TLocalizedString = TLocalizedString(title)
			for local langCode:string = EachIn lsTitle.GetLanguageKeys()
				protectedTitles.Insert(langCode + "::" + lsTitle.Get(langCode).ToLower(), string(scriptID))
			next
		elseif string(title) <> ""
			protectedTitles.insert("custom::" + string(title).ToLower(), string(scriptID))
		endif
	End Method


	'pass string or TLocalizedString
	Method RemoveTitleProtection(title:object)
		if TLocalizedString(title)
			local lsTitle:TLocalizedString = TLocalizedString(title)
			for local langCode:string = EachIn lsTitle.GetLanguageKeys()
				protectedTitles.Remove(langCode + "::" + lsTitle.Get(langCode).ToLower())
			next
		elseif string(title) <> ""
			protectedTitles.Remove("custom::" + string(title).ToLower())
		endif
	End Method


	'returns (and creates if needed) a list containing only available
	'and unused scripts.
	'Scripts of episodes and other children are ignored
	Method GetAvailableScriptList:TList()
		if not _availableScripts
			_availableScripts = CreateList()
			For local script:TScript = EachIn GetParentScriptList()
				'skip used scripts (or scripts already at the vendor)
				if script.IsOwned() then continue
				'skip scripts not available yet (or anymore)
				'(eg. they are obsolete now, or not yet possible)
				if not script.IsAvailable() then continue
				if not script.IsTradeable() then continue

				'print "GetAvailableScriptList: add " + script.GetTitle() ' +"   owned="+script.IsOwned() + "  available="+script.IsAvailable() + "  tradeable="+script.IsTradeable()
				_availableScripts.AddLast(script)
			Next
		endif
		return _availableScripts
	End Method


	'returns (and creates if needed) a list containing only used scripts.
	Method GetUsedScriptList:TList()
		if not _usedScripts
			_usedScripts = CreateList()
			For local script:TScript = EachIn entries.Values()
				'skip unused scripts
				if not script.IsOwned() then continue

				_usedScripts.AddLast(script)
			Next
		endif
		return _usedScripts
	End Method


	'returns (and creates if needed) a list containing only parental scripts
	Method GetParentScriptList:TList()
		if not _parentScripts
			_parentScripts = CreateList()
			For local script:TScript = EachIn entries.Values()
				'skip scripts containing parent information or episodes
				if script.scriptLicenceType = TVTProgrammeLicenceType.EPISODE then continue
				if script.HasParentScript() then continue

				_parentScripts.AddLast(script)
			Next
		endif
		return _parentScripts
	End Method


	Method SetScriptOwner:int(script:TScript, owner:int)
		if script.owner = owner then return False

		script.owner = owner
		'reset only specific caches, so script gets in the correct list
		_usedScripts = Null
		_availableScripts = Null

		return True
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetScriptCollection:TScriptCollection()
	Return TScriptCollection.GetInstance()
End Function




Type TScript Extends TScriptBase {_exposeToLua="selected"}
	Field ownProduction:Int	= false

	Field newsTopicGUID:string = ""
	Field newsGenre:int

	Field outcome:Float	= 0.0
	Field review:Float = 0.0
	Field speed:Float = 0.0
	Field potential:Float = 0.0

	'cast contains various jobs but with no "person" assigned in it, so
	'it is more a "job" definition (+role in the case of actors)
	Field cast:TProgrammePersonJob[]

	'See TVTProgrammePersonJob
	Field allowedGuestTypes:int	= 0

	Field requiredStudioSize:Int = 1
	'more expensive
	Field requireAudience:Int = 0

	Field targetGroup:Int = -1

	Field price:Int	= 0
	Field blocks:Int = 0

	'if the script is a clone of something, basedOnScriptID contains
	'the ID of the original script.
	'This is used for "shows" to be able to use different values of
	'outcome/speed/price/... while still having a connecting link
	Field basedOnScriptID:int = 0
	'template this script is based on (this allows to avoid that too
	'many scripts are based on the same script template on the same time)
	Field basedOnScriptTemplateID:int = 0


	Method GenerateGUID:string()
		return "script-"+id
	End Method


	Function CreateFromTemplate:TScript(template:TScriptTemplate)
		local script:TScript = new TScript
		script.title = template.GenerateFinalTitle()
		if GetScriptCollection().IsTitleProtected(script.title)
			print "script title in use: " + script.title.Get()

			'use another random one
			local tries:int = 0
			local validTitle:int = False
			For local i:int = 0 until 5
				script.title = template.GenerateFinalTitle()
				if not GetScriptCollection().IsTitleProtected(script.title)
					validTitle = True
					exit
				endif
			Next
			'no random one available or most already used
			if not validTitle
				'remove numbers
				for local langCode:string = EachIn script.title.GetLanguageKeys()
					local numberfreeTitle:string = script.title.Get(langCode)
					local hashPos:int = numberfreeTitle.FindLast("#")
					if hashPos > 2 '"sometext" + space + hash means > 2
						local numberS:string = numberFreetitle[hashPos+1 .. ]
						if numberS = string(int(numberS)) 'so "#123hashtag"
							numberfreeTitle = numberfreetitle[.. hashPos-1] 'remove space before too
						endif

						script.title.Set(numberfreeTitle, langCode)
					endif
				next

				'append number
				local titleCopy:TLocalizedString = script.title.Copy()
				'start with "2" to avoid "title #1"
				local number:int = 2
				repeat
					for local langCode:string = EachIn script.title.GetLanguageKeys()
						script.title.Set(titleCopy.Get() + " #"+number, langCode)
					next
					number :+ 1
				until not GetScriptCollection().IsTitleProtected(script.title)
			endif
		EndIf
		script.description = template.GenerateFinalDescription()

		script.outcome = template.GetOutcome()
		script.review = template.GetReview()
		script.speed = template.GetSpeed()
		script.potential = template.GetPotential()
		script.blocks = template.GetBlocks()
		script.price = template.GetPrice()

		script.flags = template.flags
		script.flagsOptional = template.flagsOptional

		script.scriptFlags = template.scriptFlags
		'mark tradeable
		script.SetScriptFlag(TVTScriptFlag.TRADEABLE, True)

		script.scriptLicenceType = template.scriptLicenceType
		script.scriptProductType = template.scriptProductType

		script.mainGenre = template.mainGenre
		'add genres
		For local subGenre:int = EachIn template.subGenres
			script.subGenres :+ [subGenre]
		Next

		'replace placeholders as we know the cast / roles now
		script.title = script._ReplacePlaceholders(script.title)
		script.description = script._ReplacePlaceholders(script.description)


		'add children
		For local subTemplate:TScriptTemplate = EachIn template.subScripts
			local subScript:TScript = TScript.CreateFromTemplate(subTemplate)
			if subScript then script.AddSubScript(subScript)
		Next
		script.basedOnScriptTemplateID = template.GetID()

		'this would GENERATE a new block of jobs (including RANDOM ones)
		'- for single scripts we could use that jobs
		'- for parental scripts we use the jobs of the children
		if template.subScripts.length = 0
			script.cast = template.GetJobs()
		else
			'for now use this approach
			'and dynamically count individual cast count by using
			'Max(script-cast-count, max-of-subscripts-cast-count)
			script.cast = template.GetJobs()
			rem
			local myCastCountAll:int[] = new Int[TVTProgrammePersonJob.count]
			local myCastCountMale:int[] = new Int[TVTProgrammePersonJob.count]
			local myCastCountFemale:int[] = new Int[TVTProgrammePersonJob.count]
			local subCastCountAll:int[] = new Int[TVTProgrammePersonJob.count]
			local subCastCountMale:int[] = new Int[TVTProgrammePersonJob.count]
			local subCastCountFemale:int[] = new Int[TVTProgrammePersonJob.count]
			local allCastCountAll:int[] = new Int[TVTProgrammePersonJob.count]
			local allCastCountMale:int[] = new Int[TVTProgrammePersonJob.count]
			local allCastCountFemale:int[] = new Int[TVTProgrammePersonJob.count]

			For local j:TProgrammePersonJob = EachIn script.cast
				'increase count for each associated job
				For local jobIndex:int = 1 to TVTProgrammePersonJob.count
					local jobID:int = TVTProgrammePersonJob.GetAtIndex(jobIndex)
					if jobID & j.job = 0 then continue

					if j.gender = 0
						myCastCountAll[jobIndex-1] :+ 1
					elseif j.gender = TVTPersonGender.MALE
						myCastCountMale[jobIndex-1] :+ 1
					elseif j.gender = TVTPersonGender.FEMALE
						myCastCountFemale[jobIndex-1] :+ 1
					endif
				Next
			Next

			'do the same for all subs
			For local subScript:TScript = EachIn script.subScripts
				For local j:TProgrammePersonJob = EachIn script.cast
					'increase count for each associated job
					For local jobIndex:int = 1 to TVTProgrammePersonJob.count
						local jobID:int = TVTProgrammePersonJob.GetAtIndex(jobIndex)
						if jobID & j.job = 0 then continue

						if j.gender = 0
							subCastCountAll[jobIndex-1] :+ 1
						elseif j.gender = TVTPersonGender.MALE
							subCastCountMale[jobIndex-1] :+ 1
						elseif j.gender = TVTPersonGender.FEMALE
							subCastCountFemale[jobIndex-1] :+ 1
						endif
					Next
				Next

				'keep the biggest cast count of all subscripts
				For local jobIndex:int = 1 to TVTProgrammePersonJob.count
					allCastCountAll[jobIndex-1] = Max(allCastCountAll[jobIndex-1], subCastCountAll[jobIndex-1])
					allCastCountMale[jobIndex-1] = Max(allCastCountMale[jobIndex-1], subCastCountMale[jobIndex-1])
					allCastCountFemale[jobIndex-1] = Max(allCastCountFemale[jobIndex-1], subCastCountFemale[jobIndex-1])
				Next
			Next
			endrem
		endif


		'reset the state of the template
		'without that, the following scripts created with this template
		'as base will get the same title/description
		template.Reset()

		return script
	End Function


	'override
	Method HasParentScript:int()
		return parentScriptID > 0
	End Method


	'override
	Method GetParentScript:TScript()
		if parentScriptID then return GetScriptCollection().GetByID(parentScriptID)
		return self
	End Method


	Method _ReplacePlaceholders:TLocalizedString(text:TLocalizedString)
		local result:TLocalizedString = text.copy()

		'for each defined language we check for existent placeholders
		'which then get replaced by a random string stored in the
		'variable with the same name
		For local lang:string = EachIn text.GetLanguageKeys()
			local value:string = text.Get(lang)
			local placeHolders:string[] = StringHelper.ExtractPlaceholders(value, "%", True)
			if placeHolders.length = 0 then continue

			local actorsFetched:int = False
			local actors:TProgrammePersonJob[]
			local replacement:string = ""
			for local placeHolder:string = EachIn placeHolders
				local replaced:int = False
				replacement = ""
				Select placeHolder.toUpper()
					case "ROLENAME1", "ROLENAME2", "ROLENAME3", "ROLENAME4", "ROLENAME5", "ROLENAME6", "ROLENAME7"
						if not actorsFetched
							actors = GetSpecificCast(TVTProgrammePersonJob.ACTOR | TVTProgrammePersonJob.SUPPORTINGACTOR)
							actorsFetched = True
						endif

						'local actorNum:int = int(placeHolder.toUpper().Replace("%ROLENAME", "").Replace("%",""))
						local actorNum:int = int(chr(placeHolder[8]))
						if actorNum > 0
							if actors.length > actorNum and actors[actorNum].roleGUID <> ""
								local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(actors[actorNum].roleGUID)
								if role then replacement = role.GetFirstName()
							endif
							'gender neutral default
							if replacement = ""
								Select actorNum
									case 1	replacement = "Robin"
									case 2	replacement = "Alex"
									default	replacement = "Jamie"
								End Select
							endif
							replaced = True
						endif
					case "ROLE1", "ROLE2", "ROLE3", "ROLE4", "ROLE5", "ROLE6", "ROLE7"
						if not actorsFetched
							actors = GetSpecificCast(TVTProgrammePersonJob.ACTOR | TVTProgrammePersonJob.SUPPORTINGACTOR)
							actorsFetched = True
						endif

						'local actorNum:int = int(placeHolder.toUpper().Replace("%ROLE", "").Replace("%",""))
						local actorNum:int = int(chr(placeHolder[4]))
						if actorNum > 0
							if actors.length > actorNum and actors[actorNum].roleGUID <> ""
								local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(actors[actorNum].roleGUID)
								if role then replacement = role.GetFullName()
							endif
							'gender neutral default
							if replacement = ""
								Select actorNum
									case 1	replacement = "Robin Mayer"
									case 2	replacement = "Alex Hulley"
									default	replacement = "Jamie Larsen"
								End Select
							endif
							replaced = True
						endif

					case "GENRE"
						replacement = GetMainGenreString()
						replaced = True
					case "EPISODES"
						replacement = GetMainGenreString()
						replaced = True

					default
						if not replaced then replaced = ReplaceTextWithGameInformation(placeHolder, replacement)
						if not replaced then replaced = ReplaceTextWithScriptExpression(placeHolder, replacement)
				End Select

				'replace if some content was filled in
				if replaced then value = value.replace("%"+placeHolder+"%", replacement)
			Next

			result.Set(value, lang)
		Next

		return result
	End Method


	'override
	Method FinishProduction(programmeLicenceID:int)
		Super.FinishProduction(programmeLicenceID)

		if basedOnScriptTemplateID
			local template:TScriptTemplate = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
			if template then template.FinishProduction(programmeLicenceID)
		endif
	End Method


	Method GetScriptTemplate:TScriptTemplate()
		if not basedOnScriptTemplateID then return Null

		return GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
	End Method


	'override default method to add subscripts
	Method SetOwner:int(owner:int=0)
		GetScriptCollection().SetScriptOwner(self, owner)

		Super.SetOwner(owner)

		return TRUE
	End Method


	Method SetBasedOnScriptID(ID:int)
		self.basedOnScriptID = ID
	End Method


	Method GetSpecificCastCount:int(job:int, limitPersonGender:int=-1, limitRoleGender:int=-1, ignoreSubScripts:int = False)
		local result:int = 0
		For local j:TProgrammePersonJob = EachIn cast
			'skip roles with wrong gender
			if limitRoleGender >= 0 and j.roleGUID
				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(j.roleGUID)
				if role and role.gender <> limitRoleGender then continue
			endif
			'skip persons with wrong gender
			if limitPersonGender >= 0 and j.gender <> limitPersonGender then continue

			'current job is one of the given job(s)
			if job & j.job then result :+ 1
		Next

		'override with maximum found in subscripts
		if not ignoreSubscripts and subScripts
			For local subScript:TScript = EachIn subScripts
				result = Max(result, subScript.GetSpecificCastCount(job, limitPersonGender, limitRoleGender))
			Next
		endif

		return result
	End Method


	Method GetCast:TProgrammePersonJob[]()
		return cast
	End Method


	Method GetSpecificCast:TProgrammePersonJob[](job:int, limitPersonGender:int=-1, limitRoleGender:int=-1)
		local result:TProgrammePersonJob[]
		For local j:TProgrammePersonJob = EachIn cast
			'skip roles with wrong gender
			if limitRoleGender >= 0 and j.roleGUID
				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(j.roleGUID)
				if role and role.gender <> limitRoleGender then continue
			endif
			'skip persons with wrong gender
			if limitPersonGender >= 0 and j.gender <> limitPersonGender then continue

			'current job is one of the given job(s)
			if job & j.job then result :+ [j]
		Next
		return result
	End Method


	Method GetOutcome:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 then return outcome

		'script for a package or scripts
		Local value:Float
		For local s:TScript = eachin subScripts
			value :+ s.GetOutcome()
		Next
		return value / subScripts.length
	End Method


	Method GetReview:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 then return review

		'script for a package or scripts
		Local value:Float
		For local s:TScript = eachin subScripts
			value :+ s.GetReview()
		Next
		return value / subScripts.length
	End Method


	Method GetSpeed:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 then return speed

		'script for a package or scripts
		Local value:Float
		For local s:TScript = eachin subScripts
			value :+ s.GetSpeed()
		Next
		return value / subScripts.length
	End Method


	Method GetPotential:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 then return potential

		'script for a package or scripts
		Local value:Float
		For local s:TScript = eachin subScripts
			value :+ s.GetPotential()
		Next
		return value / subScripts.length
	End Method


	Method GetBlocks:Int() {_exposeToLua}
		return blocks
	End Method


	Method GetEpisodeNumber:Int() {_exposeToLua}
		if self <> GetParentScript() then return GetParentScript().GetSubScriptPosition(self) + 1

		return 0
	End Method


	Method GetEpisodes:Int() {_exposeToLua}
		If isSeries() then return GetSubScriptCount()

		return 0
	End Method


	Method GetPrice:Int() {_exposeToLua}
		local value:int
		'single-script
		if GetSubScriptCount() = 0
			value = price
		'script for a package or scripts
		else
			For local script:TScript = eachin subScripts
				value :+ script.GetPrice()
			Next
			value :* 0.75
		endif

		'round to next "100" block
		value = Int(Floor(value / 100) * 100)

		Return value
	End Method

	'mixes main and subgenre criterias
	Method CalculateTotalGenreCriterias(totalReview:float var, totalSpeed:float var, totalOutcome:float var)
		Local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinition(mainGenre)
		if not genreDefinition
			TLogger.Log("TScript.CalculateTotalGenreCriterias()", "script with wrong movie genre definition, criteria calculation failed.", LOG_ERROR)
			return
		endif

		totalOutcome = genreDefinition.OutcomeMod
		totalReview = genreDefinition.ReviewMod
		totalSpeed = genreDefinition.SpeedMod

		'build subgenre-averages
		local subGenreDefinition:TMovieGenreDefinition
		local subGenreCount:int
		local subGenreOutcome:Float, subGenreReview:Float, subGenreSpeed:Float
		For local i:int = 0 until subGenres.length
			subGenreDefinition = GetMovieGenreDefinition(i)
			if not subGenreDefinition then continue

			subGenreOutcome :+ subGenreDefinition.OutcomeMod
			subGenreReview :+ subGenreDefinition.ReviewMod
			subGenreSpeed :+ subGenreDefinition.SpeedMod
			subGenreCount :+ 1
		Next
		if subGenreCount > 1
			subGenreOutcome :/ subGenreCount
			subGenreReview :/ subGenreCount
			subGenreSpeed :/ subGenreCount
		endif

		'mix maingenre and subgenres by 60:40
		if subGenreCount > 0
			'if main genre ignores outcome, ignore for subgenres too!
			if totalOutcome > 0
				totalOutcome = totalOutcome*0.6 + subGenreOutcome*0.4
			endif
			totalReview = totalReview*0.6 + subGenreReview*0.4
			totalSpeed = totalSpeed*0.6 + subGenreSpeed*0.4
		endif
	End Method


	'returns the criteria-congruence
	'(is review-speed-outcome weight of script the same as in the genres)
	'a value of 1.0 means a perfect match (eg. x*50% speed, x*20% outcome
	' and x*30% review)
	Method CalculateGenreCriteriaFit:Float()
		'Fetch corresponding genre definition, with this we are able to
		'see what values are "expected" for this genre.

		local reviewGenre:Float, speedGenre:Float, outcomeGenre:Float
		CalculateTotalGenreCriterias(reviewGenre, speedGenre, outcomeGenre)

		'scale to total of 100%
		local resultTotal:Float = reviewGenre + speedGenre + outcomeGenre
		reviewGenre :/ resultTotal
		speedGenre :/ resultTotal
		outcomeGenre :/ resultTotal

		rem
		reviewGenre = 0.5
		speedGenre = 0.3
		outcomeGenre = 0.2

		'100% fit
		review = 0.4
		speed = 0.24
		outcome = 0.16
		endrem

		'scale to biggest property
		local maxPropertyScript:Float, maxPropertyGenre:Float
		if outcomeGenre > 0
			maxPropertyScript = Max(review, Max(speed, outcome))
			maxPropertyGenre = Max(reviewGenre, Max(speedGenre, outcomeGenre))
		else
			maxPropertyScript = Max(review, speed)
			maxPropertyGenre = Max(reviewGenre, speedGenre)
		endif
		if maxPropertyGenre = 0 or MathHelper.AreApproximatelyEqual(maxPropertyScript, maxPropertyGenre)
			return 1
		endif

		local scaleFactor:Float = maxPropertyGenre / maxPropertyScript
		local distanceReview:Float = Abs(reviewGenre - review*scaleFactor)
		local distanceSpeed:Float = Abs(speedGenre - speed*scaleFactor)
		local distanceOutcome:Float = Abs(outcomeGenre - outcome*scaleFactor)
		'ignore outcome ?
		if outcomeGenre = 0 then distanceOutcome = 0

		rem
		'print "maxPropertyGenre:   "+maxPropertyGenre
		'print "maxPropertyScript:  "+maxPropertyScript
		print "mainGenre:          "+mainGenre
		print "scaleFactor:        "+scaleFactor
		print "review:             "+review + "  genre:" + reviewGenre
		print "speed:              "+speed + "  genre:" + speedGenre
		print "Review Abweichung:  "+distanceReview
		print "Speed Abweichung:   "+distanceSpeed
		if outcomeGenre > 0
			print "Outcome Abweichung:   "+distanceOutcome
		endif
		print "ergebnis:           "+(1.0 - (distanceReview + distanceSpeed + distanceOutcome))
		endrem

		return 1.0 - (distanceReview + distanceSpeed + distanceOutcome)
	End Method


	Method Sell:int()
		local finance:TPlayerFinance = GetPlayerFinance(owner,-1)
		if not finance then return False

		finance.SellScript(GetPrice(), self)

		'set unused again

		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		local finance:TPlayerFinance = GetPlayerFinance(playerID)
		if not finance then return False

		If finance.PayScript(getPrice(), self)
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method GiveBackToScriptPool:int()
		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		'remove tradeability?
		'(eg. for "exclusively written for player X scripts")
		if HasScriptFlag(TVTScriptFlag.POOL_REMOVES_TRADEABILITY)
			SetScriptFlag(TVTScriptFlag.TRADEABLE, False)
		endif


		'remove tradeability for partially produced series
		if GetSubScriptCount() > 0 and GetProductionsCount() > 0
			SetScriptFlag(TVTScriptFlag.TRADEABLE, False)
		endif


		'refill production limits - or disable tradeability
		'TODO
		rem
		if GetProductionBroadcastLimit() > 0 and (isExceedingBroadcastLimit() or GetSublicenceExceedingBroadcastLimitCount() > 0 )
			if HasScriptFlag(TVTScriptFlag.POOL_REFILLS_PRODUCTIONLIMITS)
				SetProductionLimit(broadcastLimitMax)
			else
				setScriptFlag(TVTProgrammeLicenceFlag.TRADEABLE, False)
			endif
		endif
		endrem


		'randomize attributes?
		if HasScriptFlag(TVTScriptFlag.POOL_RANDOMIZES_ATTRIBUTES)
			local template:TScriptTemplate
			if basedOnScriptTemplateID then template = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
			if template
				outcome = template.GetOutcome()
				review = template.GetReview()
				speed = template.GetSpeed()
				potential = template.GetPotential()
				blocks = template.GetBlocks()
				price = template.GetPrice()
			endif
		endif


		'do the same for all children
		For local subScript:TScript = EachIn subScripts
			subScript.GiveBackToScriptPool()
		Next

		'inform others about a now unused licence
		EventManager.triggerEvent( TEventSimple.Create("Script.onGiveBackToScriptPool", null, self))

		return True
	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 310
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("script")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		Local showMsgEarnInfo:Int = False
		Local showMsgLiveInfo:Int = False
		Local showMsgBroadcastLimit:Int = False

		If IsPaid() then showMsgEarnInfo = True
		If IsLive() then showMsgLiveInfo = True
		If HasProductionBroadcastLimit() then showMsgBroadcastLimit= True


		local title:string
		if not isEpisode()
			title = GetTitle()
		else
			title = GetParentScript().GetTitle()
		endif

		'can player afford this licence?
		local canAfford:int = False
		'possessing player always can
		if GetPlayerBaseCollection().playerID = owner
			canAfford = True
		'if it is another player... just display "can afford"
		elseif owner > 0
			canAfford = True
		'not our licence but enough money to buy ?
		else
			local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBaseCollection().playerID)
			if finance and finance.canAfford(GetPrice())
				canAfford = True
			endif
		endif


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, subtitleH:int = 16, genreH:int = 16, descriptionH:int = 70, castH:int=50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, msgH:int = 0, barH:int = 0
		local msgAreaH:int = 0, boxAreaH:int = 0, barAreaH:int = 0
		local boxAreaPaddingY:int = 4, msgAreaPaddingY:int = 4, barAreaPaddingY:int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", null, ALIGN_CENTER_CENTER).GetY()
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))

		'message area
		If showMsgEarnInfo then msgAreaH :+ msgH
		If showMsgLiveInfo then msgAreaH :+ msgH
		If showMsgBroadcastLimit then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		if msgAreaH > 0 then msgAreaH :+ 2* msgAreaPaddingY


		'bar area starts with padding, ends with padding and contains
		'also contains 3 bars
		barAreaH = 2 * barAreaPaddingY + 3 * (barH + 2)

		'box area
		'contains 1 line of boxes + padding at the top
		boxAreaH = 1 * boxH
		if msgAreaH = 0 then boxAreaH :+ boxAreaPaddingY

		'total height
		sheetHeight = titleH + genreH + descriptionH + castH + barAreaH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		if isEpisode() then sheetHeight :+ subtitleH
		'there is a splitter between description and cast...
		sheetHeight :+ splitterHorizontalH


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			if titleH <= 18
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH


		'=== SUBTITLE AREA ===
		if isEpisode()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			'episode num/max + episode title
			skin.fontNormal.drawBlock((GetParentScript().GetSubScriptPosition(self)+1) + "/" + GetParentScript().GetSubScriptCount() + ": " + GetTitle(), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		endif


		'=== COUNTRY / YEAR / GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		local genreString:string = GetMainGenreString()
		'avoid "Action-Undefined" and "Show-Show"
		if scriptProductType <> TVTProgrammeProductType.UNDEFINED and scriptProductType <> TVTProgrammeProductType.SERIES
			if (TVTProgrammeProductType.GetAsString(scriptProductType) <> TVTProgrammeGenre.GetAsString(mainGenre))
				if not(TVTProgrammeProductType.GetAsString(scriptProductType) = "feature" and TVTProgrammeGenre.GetAsString(mainGenre).Find("feature")>=0)
					genreString :+ " / " +GetProductionTypeString()
				endif
			endif
		endif
		if IsSeries()
			genreString :+ " / " + GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubScriptCount())
		endif

		skin.fontNormal.drawBlock(genreString, contentX + 5, contentY, contentW - 10, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ genreH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.drawBlock(GetDescription(), contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH


		'splitter
		skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
		contentY :+ splitterHorizontalH


		'=== CAST AREA ===
		skin.RenderContent(contentX, contentY, contentW, castH, "2")

		'cast
		local cast:string = ""

		For local i:int = 1 to TVTProgrammePersonJob.count
			local jobID:int = TVTProgrammePersonJob.GetAtIndex(i)
			'call with "false" to return maximum required persons within
			'sub scripts too
			local requiredPersons:int = GetSpecificCastCount(jobID,-1,-1, False)
			if requiredPersons <= 0 then continue

			if cast <> "" then cast :+ ", "

			local requiredPersonsMale:int = GetSpecificCastCount(jobID, TVTPersonGender.MALE)
			local requiredPersonsFemale:int = GetSpecificCastCount(jobID, TVTPersonGender.FEMALE)
			requiredPersons = Max(requiredPersons, requiredPersonsMale + requiredPersonsFemale)

			if requiredPersons = 1
				cast :+ "|b|"+requiredPersons+"x|/b| "+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, True))
			else
				cast :+ "|b|"+requiredPersons+"x|/b| "+GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(jobID, False))
			endif


			local requiredDetails:string = ""
			if requiredPersonsMale > 0
				'write amount if multiple genders requested for this job type
				if requiredPersonsMale <> requiredPersons
					requiredDetails :+ requiredPersonsMale+"x "+GetLocale("MALE")
				else
					requiredDetails :+ GetLocale("MALE")
				endif
			endif
			if requiredPersonsFemale > 0
				if requiredDetails <> "" then requiredDetails :+ ", "
				'write amount if multiple genders requested for this job type
				if requiredPersonsFemale <> requiredPersons
					requiredDetails :+ requiredPersonsFemale+"x "+GetLocale("FEMALE")
				else
					requiredDetails :+ GetLocale("FEMALE")
				endif
			endif
			if requiredPersons - (requiredPersonsMale + requiredPersonsFemale) > 0
				'write amount if genders for this job type were defined
				if requiredPersonsMale > 0 or requiredPersonsFemale > 0
					if requiredDetails <> "" then requiredDetails :+ ", "
					requiredDetails :+ (requiredPersons - (requiredPersonsMale + requiredPersonsFemale))+"x "+GetLocale("UNDEFINED")
				endif
			endif
			if requiredDetails <> ""
				cast :+ " (" + requiredDetails + ")"
			endif
		Next

rem
		local requiredDirectors:int = GetSpecificCastCount(TVTProgrammePersonJob.DIRECTOR)
		local requiredStarRoleActorFemale:int = GetSpecificCastCount(TVTProgrammePersonJob.ACTOR, TVTPersonGender.FEMALE)
		local requiredStarRoleActorMale:int = GetSpecificCastCount(TVTProgrammePersonJob.ACTOR, TVTPersonGender.MALE)
		local requiredStarRoleActors:int = GetSpecificCastCount(TVTProgrammePersonJob.ACTOR)

		if requiredDirectors > 0 then cast :+ "|b|"+requiredDirectors+"x|/b| "+GetLocale("MOVIE_DIRECTOR")
		if cast <> "" then cast :+ ", "

		if requiredStarRoleActors > 0
			local requiredStars:int = requiredStarRoleActorMale + requiredStarRoleActorFemale
			cast :+ "|b|"+requiredStars+"x|/b| "+GetLocale("MOVIE_LEADINGACTOR")

			local actorDetails:string = ""
			if requiredStarRoleActorMale > 0
				actorDetails :+ requiredStarRoleActorMale+"x "+GetLocale("MALE")
			endif
			if requiredStarRoleActorFemale > 0
				if actorDetails <> "" then actorDetails :+ ", "
				actorDetails :+ requiredStarRoleActorFemale+"x "+GetLocale("FEMALE")
			endif
			if requiredStarRoleActors - (requiredStarRoleActorMale + requiredStarRoleActorFemale)  > 0
				if actorDetails <> "" then actorDetails :+ ", "
				actorDetails :+ requiredStarRoleActors+"x "+GetLocale("UNDEFINED")
			endif

			cast :+ " (" + actorDetails + ")"
		endif
endrem

		if cast <> ""
			'render director + cast (offset by 3 px)
			contentY :+ 3

			'max width of cast word - to align their content properly
			local captionWidth:int = skin.fontSemiBold.getWidth(GetLocale("MOVIE_CAST")+":")
			skin.fontSemiBold.drawBlock(GetLocale("MOVIE_CAST")+":", contentX + 5, contentY, contentW, castH, null, skin.textColorNeutral)
			skin.fontNormal.drawBlock(cast, contentX + 5 + captionWidth + 5, contentY , contentW  - 10 - captionWidth - 5, castH, null, skin.textColorNeutral)

			contentY:+ castH - 3
		else
			contentY:+ castH
		endif


		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + boxes
		skin.RenderContent(contentX, contentY, contentW, barAreaH + msgAreaH + boxAreaH, "1_bottom")


		'===== DRAW RATINGS / BARS =====

		'bars have a top-padding
		contentY :+ barAreaPaddingY
		'speed
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetSpeed())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'critic/review
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetReview())
		skin.fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'potential
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetPotential())
		skin.fontSemiBold.drawBlock(GetLocale("SCRIPT_POTENTIAL"), contentX + 5 + 200 + 5, contentY, 75, 15, null, skin.textColorLabel)
		contentY :+ barH + 2


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY

		If showMsgLiveInfo
			'TODO
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, "TODO: " + getLocale("LIVE_BROADCAST"), "runningTime", "bad", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		if showMsgBroadcastLimit
			'TODO
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, "TODO: " + getLocale("BROASCAST_LIMIT"), "spotsPlanned", "warning", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		endif

		If showMsgEarnInfo
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", "***"), "money", "good", skin.fontSemiBold, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		'if there is a message then add padding to the bottom
		if msgAreaH > 0 then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		'if msgAreaH = 0 then contentY :+ boxAreaPaddingY
		contentY :+ boxAreaPaddingY
		'blocks
		skin.RenderBox(contentX + 5, contentY, 47, -1, GetBlocks(), "duration", "neutral", skin.fontBold)
		'price
		if canAfford
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, MathHelper.DottedValue(GetPrice()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		else
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, MathHelper.DottedValue(GetPrice()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
		endif
		contentY :+ boxH


		'=== DEBUG ===
		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.drawBlock("Drehbuch: "+GetTitle(), contentX + 5, contentY, contentW - 10, 28)
			contentY :+ 28
			skin.fontNormal.draw("Tempo: "+MathHelper.NumberToString(GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Kritik: "+MathHelper.NumberToString(GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Potential: "+MathHelper.NumberToString(GetPotential(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Preis: "+GetPrice(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("IsProduced: "+IsProduced(), contentX + 5, contentY)
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)

		'=== X-Rated Overlay ===
		If IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_overlay_xrated").Draw(contentX + sheetWidth, y, -1, ALIGN_RIGHT_TOP)
		Endif
	End Method
End Type