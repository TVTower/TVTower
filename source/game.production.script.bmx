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
Import "game.gameeventkeys.bmx"
'to access datasheet-functions
Import "common.misc.datasheet.bmx"



Type TScriptCollection Extends TGameObjectCollection
	'stores "languagecode::name"=>"used by id" connections
	Field protectedTitles:TStringMap = New TStringMap
	'=== CACHE ===
	'cache for faster access

	'holding used scripts
	Field _usedScripts:TList {nosave}
	Field _availableScripts:TList {nosave}
	Field _parentScripts:TList {nosave}
	
	Global _instance:TScriptCollection


	Function GetInstance:TScriptCollection()
		If Not _instance Then _instance = New TScriptCollection
		Return _instance
	End Function


	Method Initialize:TScriptCollection()
		Super.Initialize()
		
		_InvalidateCaches()
		If protectedTitles Then protectedTitles.Clear()
		
		Return Self
	End Method


	Method _InvalidateCaches()
		_usedScripts = Null
		_availableScripts = Null
		_parentScripts = Null
	End Method


	Method Add:Int(obj:TGameObject)
		Local script:TScript = TScript(obj)
		If Not script Then Return False

		_InvalidateCaches()
		'add child scripts too
		For Local subScript:TScript = EachIn script.subScripts
			Add(subScript)
		Next

		'protect title
		If Not script.HasParentScript()
			AddTitleProtection(script.title, script.GetID())
		EndIf

		Return Super.Add(script)
	End Method


	Method Remove:Int(obj:TGameObject)
		Local script:TScript = TScript(obj)
		If Not script Then Return False

		_InvalidateCaches()
		'remove child scripts too
		For Local subScript:TScript = EachIn script.subScripts
			Remove(subScript)
		Next

		'unprotect title
		If Not script.HasParentScript()
			RemoveTitleProtection(script.title)
		EndIf

		If script.basedOnScriptTemplateID
			Local template:TScriptTemplate = GetScriptTemplateCollection().getById(script.basedOnScriptTemplateID)
			If template And template.IsUsedForScript(script.GetID())
				template.RemoveUsedForScript(script.GetID())
			Else
				TLogger.log("TScriptCollection.Remove", "Template for script "+script.GetTitle()+ " not found for marking it as unused.", LOG_ERROR)
			EndIf
		EndIf

		Return Super.Remove(script)
	End Method


	Method GetByID:TScript(ID:Int)
		Return TScript( Super.GetByID(ID) )
	End Method


	Method GetByGUID:TScript(GUID:String)
		Return TScript( Super.GetByGUID(GUID) )
	End Method


	Method GenerateFromTemplate:TScript(templateOrTemplateGUID:Object)
		Local template:TScriptTemplate
		If TScriptTemplate(templateOrTemplateGUID)
			template = TScriptTemplate(templateOrTemplateGUID)
		Else
			template = GetScriptTemplateCollection().GetByGUID( String(templateOrTemplateGUID) )
			If Not template Then Return Null
		EndIf

		Local script:TScript = TScript.CreateFromTemplate(template, True)
		script.SetOwner(TOwnedGameObject.OWNER_NOBODY)
		Add(script)
		Return script
	End Method


	Method GenerateFromTemplate:TScript(ID:Int)
		Local template:TScriptTemplate = GetScriptTemplateCollection().GetByID( ID )
		If Not template Then Return Null

		Return GenerateFromTemplate(template)
	End Method


	Method GenerateRandom:TScript(avoidTemplateIDs:Int[])
		Local template:TScriptTemplate
		Local filter:SScriptTemplateFilter = new SScriptTemplateFilter
		filter.biggerStudioAllowedChance = 10 + 5 * (GetWorldTime().GetDaysRun())

		'apart from avoidTemplateIDs, templates from already available scripts should not be used again
		Local availableScriptList:TList = GetAvailableScriptList()
		'presize array in advance instead of adding a new one-entry-array on each for-loop
		Local alreadyAvailable:Int[] = New Int[availableScriptList.Count()]
		Local scIndex:Int = 0
		for local sc:TScript = EachIn availableScriptList
			alreadyAvailable[scIndex] = sc.basedOnScriptTemplateID
			scIndex :+ 1
		Next
		'theoretically list.count() could be higher than actual TScript count (it could contain incompatible objects..)
		If scIndex < alreadyAvailable.length Then alreadyAvailable = alreadyAvailable[..scIndex]

		filter.avoidIDs = avoidTemplateIDs + alreadyAvailable
		filter.skipNotAvailable = True
		'determine candidate
		template = GetScriptTemplateCollection().GetRandomByFilter(filter)
		'get a random one, ignore avoid IDs
		If Not template And filter.avoidIDs And filter.avoidIDs.length > 0
			TLogger.Log("TScriptCollection.GenerateRandom()", "No available template found (avoid-list too big?). Trying an avoided entry.", LOG_WARNING)
			filter.avoidIDs = null
			template = GetScriptTemplateCollection().GetRandomByFilter(filter)
		EndIf
		'get a random one, ignore availability
		If Not template
			TLogger.Log("TScriptCollection.GenerateRandom()", "No available template found (avoid-list too big?). Using an unfiltered entry.", LOG_WARNING)
			filter.skipNotAvailable = True
			template = GetScriptTemplateCollection().GetRandomByFilter(filter)
		EndIf

		If template
			Local script:TScript = TScript.CreateFromTemplate(template,True)
			script.SetOwner(TOwnedGameObject.OWNER_NOBODY)
			Add(script)
			Return script
		EndIf
		'this should never happen - twenty tries and always protected multi-production template is unlikely
		throw "TScriptCollection.GenerateRandom(): could not create a new script"
	End Method


	Method GetRandomAvailable:TScript(avoidTemplateIDs:Int[] = Null)
		Local availableCount:Int = GetAvailableScriptList().Count()
		'if no script is available, create (and return) a new one
		If availableCount = 0 Then Return GenerateRandom(avoidTemplateIDs)

		'with a low chance, create a random script rather than using one from pool
		If availableCount < 10
			If randRange(1,100) > 70 Then Return GenerateRandom(avoidTemplateIDs)
		Else
			If randRange(1,100) > 90 Then Return GenerateRandom(avoidTemplateIDs)
		EndIf

		'fetch a random script
		If Not avoidTemplateIDs Or avoidTemplateIDs.length = 0
			Return TScript(GetAvailableScriptList().ValueAtIndex(randRange(0, GetAvailableScriptList().Count() - 1)))
		Else
			Local possibleScripts:TScript[]
			For Local s:TScript = EachIn GetAvailableScriptList()
				If Not s.basedOnScriptTemplateID Or Not MathHelper.InIntArray(s.basedOnScriptTemplateID, avoidTemplateIDs)
					possibleScripts :+ [s]
				EndIf
			Next
			If possibleScripts.length = 0 Then Return GenerateRandom(avoidTemplateIDs)

			Return possibleScripts[ randRange(0, possibleScripts.length - 1) ]
		EndIf
	End Method


	Method GetTitleProtectedByID:Int(title:Object, contentType:String="script")
		If TLocalizedString(title)
			Local lsTitle:TLocalizedString = TLocalizedString(title)
			For Local langID:Int = EachIn lsTitle.GetLanguageIDs()
				Local key:String = TLocalization.GetLanguageCode(langID) + "::" + lsTitle.Get(langID).ToLower()
				Local title:String = String(protectedTitles.ValueForKey(key))
				Local splitterPos:Int = title.Find("::")
				if splitterPos >= 0 Then Return Int(title[splitterPos + 1 ..])
				Return Int(title)
			Next
		ElseIf String(title) <> ""
			Local key:String = "custom::" + String(title).ToLower()
			Local title:String = String(protectedTitles.ValueForKey(key))
			Local splitterPos:Int = title.Find("::")
			if splitterPos >= 0 Then Return Int(title[splitterPos + 1 ..])
			Return Int(title)
		EndIf
	End Method


	Method IsTitleProtected:Int(title:Object)
		If TLocalizedString(title)
			Local lsTitle:TLocalizedString = TLocalizedString(title)
			For Local langID:Int = EachIn lsTitle.GetLanguageIDs()
				Local key:String = TLocalization.GetLanguageCode(langID) 
				key :+ "::" + lsTitle.Get(langID).ToLower()
				If protectedTitles.Contains(key)
					Return True
				EndIf
			Next
		ElseIf String(title) <> ""
			If protectedTitles.Contains("custom::" + String(title).ToLower())
				Return True
			EndIf
		EndIf
		Return False
	End Method


	'pass string or TLocalizedString
	Method AddTitleProtection(title:Object, ID:Int, contentType:String="script")
		If TLocalizedString(title)
			Local lsTitle:TLocalizedString = TLocalizedString(title)
			For Local langID:Int = EachIn lsTitle.GetLanguageIDs()
				protectedTitles.Insert(TLocalization.GetLanguageCode(langID) + "::" + lsTitle.Get(langID).ToLower(), contentType+"::"+String(ID))
			Next
		ElseIf String(title) <> ""
			protectedTitles.insert("custom::" + String(title).ToLower(), contentType+"::"+String(ID))
		EndIf
	End Method


	'pass string or TLocalizedString
	Method RemoveTitleProtection(title:Object)
		If TLocalizedString(title)
			Local lsTitle:TLocalizedString = TLocalizedString(title)
			For Local langID:Int = EachIn lsTitle.GetLanguageIDs()
				protectedTitles.Remove(TLocalization.GetLanguageCode(langID) + "::" + lsTitle.Get(langID).ToLower())
			Next
		ElseIf String(title) <> ""
			protectedTitles.Remove("custom::" + String(title).ToLower())
		EndIf
	End Method


	'returns (and creates if needed) a list containing only available
	'and unused scripts.
	'Scripts of episodes and other children are ignored
	Method GetAvailableScriptList:TList()
		If Not _availableScripts
			_availableScripts = CreateList()
			For Local script:TScript = EachIn GetParentScriptList()
				'skip used scripts (or scripts already at the vendor)
				If script.IsOwned() Then Continue
				'skip scripts not available yet (or anymore)
				'(eg. they are obsolete now, or not yet possible)
				If Not script.IsAvailable() Then Continue
				If Not script.IsTradeable() Then Continue

				'print "GetAvailableScriptList: add " + script.GetTitle() ' +"   owned="+script.IsOwned() + "  available="+script.IsAvailable() + "  tradeable="+script.IsTradeable()
				_availableScripts.AddLast(script)
			Next
		EndIf
		Return _availableScripts
	End Method


	'returns (and creates if needed) a list containing only used scripts.
	Method GetUsedScriptList:TList()
		If Not _usedScripts
			_usedScripts = CreateList()
			For Local script:TScript = EachIn entries.Values()
				'skip unused scripts
				If Not script.IsOwned() Then Continue

				_usedScripts.AddLast(script)
			Next
		EndIf
		Return _usedScripts
	End Method


	'returns (and creates if needed) a list containing only parental scripts
	Method GetParentScriptList:TList()
		If Not _parentScripts
			_parentScripts = CreateList()
			For Local script:TScript = EachIn entries.Values()
				'skip scripts containing parent information or episodes
				If script.scriptLicenceType = TVTProgrammeLicenceType.EPISODE Then Continue
				If script.HasParentScript() Then Continue

				_parentScripts.AddLast(script)
			Next
		EndIf
		Return _parentScripts
	End Method


	Method SetScriptOwner:Int(script:TScript, owner:Int)
		If script.owner = owner Then Return False

		script.owner = owner
		'reset only specific caches, so script gets in the correct list
		_usedScripts = Null
		_availableScripts = Null

		Return True
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetScriptCollection:TScriptCollection()
	Return TScriptCollection.GetInstance()
End Function




Type TScript Extends TScriptBase {_exposeToLua="selected"}
	Field ownProduction:Int	= False
	
	'custom titles/descriptions allow to adjust a series title
	'or description (what a production concept cannot do)
	Field customTitle:String = ""
	Field customDescription:String = ""
	
	Field newsGenre:Int

	Field outcome:Float	= 0.0
	Field review:Float = 0.0
	Field speed:Float = 0.0
	Field potential:Float = 0.0

	'jobs contains various jobs but with no "person" assigned in it, so
	'it is more a "job" definition (+role in the case of actors)
	Field jobs:TPersonProductionJob[]

	'See TVTPersonJob
	Field allowedGuestTypes:Int	= 0

	Field requiredStudioSize:Int = 1 {_exposeToLua="readonly"}

	Field price:Int	= 0
	Field blocks:Int = 0

	'template this script is based on (this allows to avoid that too
	'many scripts are based on the same script template on the same time)
	Field basedOnScriptTemplateID:Int = 0

	'parent script temporarily stored during title/description creation
	Field _parentScriptTmp:TScript {nosave}
	

	Global spriteNameOverlayXRatedLS:TLowerString = New TLowerString.Create("gfx_datasheet_overlay_xrated")


	Method GenerateGUID:String()
		Return "script-"+id
	End Method


	Function CreateFromTemplate:TScript(template:TScriptTemplate, includingEpisodes:Int)
		Local script:TScript = New TScript

		'assign basic variables (so title/description can use them)

		script.outcome = template.GetOutcome()
		script.review = template.GetReview()
		script.speed = template.GetSpeed()
		script.potential = template.GetPotential()
		script.blocks = template.GetBlocks()
		script.price = template.GetPrice()
		If template.targetGroupAttractivityMod Then script.targetGroupAttractivityMod = template.targetGroupAttractivityMod.Copy()

		script.flags = template.GetFinalFlags()
		script.targetGroup = template.GetFinalTargetGroup()

		script.productionBroadcastFlags = template.productionBroadcastFlags
		script.productionLicenceFlags = template.productionLicenceFlags

		script.broadcastTimeSlotStart = template.broadcastTimeSlotStart
		script.broadcastTimeSlotEnd = template.broadcastTimeSlotEnd
		'complete partially defined slot restriction based on block length
		If script.broadcastTimeSlotStart >= 0 and script.broadcastTimeSlotEnd < 0
			script.broadcastTimeSlotEnd = (script.broadcastTimeSlotStart + script.blocks) mod 24
		EndIF
		If script.broadcastTimeSlotEnd >= 0 and script.broadcastTimeSlotStart < 0
			script.broadcastTimeSlotStart = (script.broadcastTimeSlotEnd + 24 - script.blocks) mod 24
		EndIF

		script.SetProductionLimit( template.GetProductionLimit() )
		script.SetProductionBroadcastLimit( template.GetProductionBroadcastLimit() )

		script.productionTime = template.GetProductionTime()
		script.productionTimeModBase = template.productionTimeModBase

		script.scriptFlags = template.scriptFlags
		'mark tradeable
		script.SetScriptFlag(TVTScriptFlag.TRADEABLE, True)

		script.scriptLicenceType = template.scriptLicenceType
		script.scriptProductType = template.scriptProductType
		
		script.requiredStudioSize = template.GetStudioSize()

		script.mainGenre = template.mainGenre
		'add genres
		For Local subGenre:Int = EachIn template.subGenres
			script.subGenres :+ [subGenre]
		Next

		If template.effects
			script.effects=template.effects.Copy()
		EndIf

		'add children
		If includingEpisodes
			If template.programmeDataModifiers
				if not script.programmeDataModifiers Then script.programmeDataModifiers = New TData
				script.programmeDataModifiers.Append(template.programmeDataModifiers)
			EndIf
			Local mainTemplateEpisodeCount:Int = template.getEpisodes()
			If mainTemplateEpisodeCount > 1 and mainTemplateEpisodeCount < template.subScripts.length
				'if parent restricts the number of episodes - get a subset of templates
				Local pilot:TScriptTemplate = TScriptTemplate(template.subScripts[0])
				Local forceIncludePilot:Int = pilot.episodesMin > 0
				For Local subTemplate:TScriptTemplate = EachIn template.GetSubTemplateSubset(mainTemplateEpisodeCount, forceIncludePilot)
					Local subScript:TScript = TScript.CreateFromTemplate(subTemplate, False)
					If subScript
						_calculateLiveTime(subScript, subTemplate)
						If template.programmeDataModifiers
							if not subScript.programmeDataModifiers Then subScript.programmeDataModifiers = New TData
							subScript.programmeDataModifiers.Append(template.programmeDataModifiers)
						EndIf
						If subTemplate.programmeDataModifiers
							if not subScript.programmeDataModifiers Then subScript.programmeDataModifiers = New TData
							subScript.programmeDataModifiers.Append(subTemplate.programmeDataModifiers)
						EndIf
						script.AddSubScript(subScript)
					EndIf
				Next
			Else
				'disregard parent episode definition; add number of episodes defined by the child script
				For Local subTemplate:TScriptTemplate = EachIn template.subScripts
					Local episodesCount:Int = subTemplate.getEpisodes()
					If episodesCount > 0 '0 episodes are supported - do not always include every episode
						For Local i:Int = 0 until episodesCount
							Local subScript:TScript = TScript.CreateFromTemplate(subTemplate, False)
							If subScript
								_calculateLiveTime(subScript, subTemplate)
								If template.programmeDataModifiers
									if not subScript.programmeDataModifiers Then subScript.programmeDataModifiers = New TData
									subScript.programmeDataModifiers.Append(template.programmeDataModifiers)
								EndIf
								If subTemplate.programmeDataModifiers
									if not subScript.programmeDataModifiers Then subScript.programmeDataModifiers = New TData
									subScript.programmeDataModifiers.Append(subTemplate.programmeDataModifiers)
								EndIf
								script.AddSubScript(subScript)
							EndIf
						Next
					EndIf
				Next
			EndIf

			If script.subScripts
				'#440 propagate final optional header flags to episodes
				'also propagate parent effects
				For Local subScript:TScript = EachIn script.subScripts
					subScript.flags :| script.flags
					If script.effects
						If subScript.effects
							'appending parent effects to existing subscript entries
							Local node:TNode = script.effects.entries._FirstNode()
							While node And node <> TGameModifierGroup._nilNode
								Local l:TList = TList(node._value)
								If Not l Then Continue
								For Local m:TGameModifierBase = EachIn l
									subScript.effects.AddEntry(String(node._key), m)
								Next
								'move on to next node
								node = node.NextNode()
							Wend
						Else
							subScript.effects = script.effects.Copy()
						EndIf
					EndIf
				Next

				'#424 script with children is live (only) if any of the children is live
				'live flag could be optional for a single episode
				script.SetFlag(TVTProgrammeDataFlag.LIVE, False)
				For Local subScript:TScript = EachIn script.subScripts
					If subScript.isLive()
						script.SetFlag(TVTProgrammeDataFlag.LIVE, True)
					EndIF

					If not subScript.CanBeXRated()
						subScript.SetFlag(TVTProgrammeDataFlag.XRATED, False)
					EndIf
				Next
			Else
				If not script.CanBeXRated()
					script.SetFlag(TVTProgrammeDataFlag.XRATED, False)
				EndIf
				_calculateLiveTime(script, template)
			EndIf
		EndIf

		'this would GENERATE a new block of jobs (including RANDOM ones)
		'- for single scripts we could use that jobs
		'- for parental scripts we use the jobs of the children
		If template.subScripts.length = 0
			script.jobs = template.GetFinalJobs()
		Else
			'for now use this approach
			'and dynamically count individual job count by using
			'Max(script-job-count, max-of-subscripts-job-count)
			script.jobs = template.GetFinalJobs()
		EndIf

		script.basedOnScriptTemplateID = template.GetID()
		template.AddUsedForScript(script.GetID())


		'create title and description
		
		If script.subScripts
			'#440 propagate final optional header flags to episodes
			'also propagate parent effects
			For Local subScript:TScript = EachIn script.subScripts
				' sub scripts could be the all same (eg only one child
				' defined but 5 episodes generated).
				' So we need to ensure to reset variables used in title
				' and description generation of the "subscript" (parent
				' variables should be unaffected)
				Local subTemplate:TScriptTemplate = GetScriptTemplateCollection().GetByID(subScript.basedOnScriptTemplateID)
				If subTemplate Then subTemplate.ResetVariables()

				'temporarily make parent script directly available
				subScript._parentScriptTmp = script
				subScript._GenerateTitleFromTemplate()
				subScript._GenerateDescriptionFromTemplate()
				subScript._parentScriptTmp = Null
			Next

			'ensure they use distinct names
			script._EnsureUniqueEpisodeNames()
		EndIf


		'replace script expressions/variables as we know the cast / roles now
		'also ensure title is unique
		script._GenerateTitleFromTemplate()
		script._GenerateDescriptionFromTemplate()

		'reset the state of the template
		'without that, the following scripts created with this template
		'as base will get the same title/description
		template.Reset()
	
		Return script
	End Function
	
	
	Function _calculateLiveTime(script:TScript, template:TScriptTemplate)
		If script.HasFlag(TVTProgrammeDataFlag.LIVE)
			Local alwaysLive:int = script.HasProductionBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE)
			Local liveTime:Long = 0
			If Not alwaysLive
				If template And template.liveDateCode
					Local liveDateCodeParams:Int[] = StringHelper.StringToIntArray(template.liveDateCode, ",")
					If liveDateCodeParams.length > 0 And liveDateCodeParams[0] > 0
						Local useParams:Int[] = [-1,-1,-1,-1,-1,-1,-1,-1]
						For Local i:Int = 1 Until liveDateCodeParams.length
							useParams[i-1] = liveDateCodeParams[i]
						Next
						local t:long = GetWorldTime().CalcTime_Auto(GetWorldTime().GetTimeGone(), liveDateCodeParams[0], useParams)
						'fix to not use any minutes except ":05"
						script.fixedLiveTime = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay(t), GetWorldTime().GetDayHour(t), 5, 0)
					End If
				End If

				'if live time not set - set alswaysLive
				If script.fixedLiveTime < 0 Then script.SetProductionBroadcastFlag(TVTBroadcastMaterialSourceFlag.ALWAYS_LIVE, True)
			End IF
		End If
	End Function

	'override
	Method GetTitle:String() {_exposeToLua}
		' prioritize an optional given custom title 
		' (eg. given by the player in the supermarket)  
		If customTitle Then Return customTitle
		
		' if no title was generated from the template, do so
		' (this evaluates variables and expressions and ensures
		'  that the script title is only used exclusively)
		if not title Then _GenerateTitleFromTemplate()
		
		Return Super.GetTitle()
	End Method


	'override
	Method GetDescription:String()
		' prioritize an optional given custom description 
		' (eg. given by the player in the supermarket)  
		If customDescription Then Return customDescription
	
		' if no description was generated from the template, do so
		' (this evaluates variables and expressions)
		if not description Then _GenerateDescriptionFromTemplate()
	
		Return Super.GetDescription()
	End Method


	'check subscripts for duplicate titles (ensures unique episode names)
	Method _EnsureUniqueEpisodeNames()
		if GetSubScriptCount() > 0
			Local episodeTitles:TList = new TList()
			Local sb:TStringBuilder = New TStringBuilder()
			For Local subScript:TScript = EachIn subScripts
				'try to ensure unique episode names
				Local subTemplate:TScriptTemplate = GetScriptTemplateCollection().getById(subScript.basedOnScriptTemplateID)
				Local foundDuplicate:Int = False

				For Local j:Int = 0 until 10
					foundDuplicate = False
					For Local langID:Int = EachIn subScript.title.GetLanguageIDs()
						Local localizedTitle:String = subScript.title.Get(langID)
						sb.SetLength(0)
						sb.Append(TLocalization.GetLanguageCode(langID))
						sb.Append("::")
						sb.Append(localizedTitle)
						Local key:String = sb.ToLower().ToString()

						If episodeTitles.contains(key)
							foundDuplicate = True
							exit
						EndIf
					Next
					
					if foundDuplicate
						'reset resolved variables (not other expressions)
						If subTemplate Then subTemplate.ResetVariables()
						'reevaluate expressions (but do NOT protect the title)
						subScript._GenerateTitleFromTemplate(False)
					Else
						Exit
					EndIf
				Next
				'if a new title was generated, refresh description too
				if foundDuplicate
					subScript._GenerateDescriptionFromTemplate()

					'add the titles of all languages to the list 
					'so next episode can check against them
					For Local langID:Int = EachIn subScript.title.GetLanguageIDs()
						sb.SetLength(0)
						sb.Append(TLocalization.GetLanguageCode(langID))
						sb.Append("::")
						sb.Append(subScript.title.Get(langID))
						episodeTitles.addLast(sb.ToLower().ToString())
					Next
				endIf
			Next
		EndIf
	End Method


	Method _GenerateDescriptionFromTemplate()
		If not basedOnScriptTemplateID Then Return

		'fetch original title from template
		Local template:TScriptTemplate = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
		If not template Then Return

		Local resultDescription:TLocalizedString
		'replace variables/expressions in it
		resultDescription = _ReplaceScriptExpressions(template.description)
		
		self.description = resultDescription
	End Method

	
	Method _GenerateTitleFromTemplate:Int(skipProtectionCheck:Int = False)
		If not basedOnScriptTemplateID Then Return False

		'fetch original title from template
		Local template:TScriptTemplate = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
		If not template Then Return False

		'define a random seed so any generation generates the same "result"
		'(which allows episodes to fetch parent title/description and when
		' parent _recreates_ its title to now reference an episode title, the
		' other text parts stay the same)
		'TODO! - check if really needed


		Local resultTitle:TLocalizedString
		'replace variables/expressions in it
		resultTitle = _ReplaceScriptExpressions(template.title)
		
		'eg. titles of episodes could have non-unique titles ("Final")
		if skipProtectionCheck 
			self.title = resultTitle
			Return True
		EndIf
		

		If GetScriptCollection().IsTitleProtected(resultTitle)
'			print "script title in use: " + resultTitle.Get()

			'use another random one
			Local tries:Int = 0
			Local validTitle:Int = False
			For Local i:Int = 0 Until 5
				'replace variables/expressions in it
				resultTitle = _ReplaceScriptExpressions(template.title)

				If Not GetScriptCollection().IsTitleProtected(resultTitle)
					validTitle = True
					Exit
				EndIf
			Next
			'no random one available or most already used
			If Not validTitle
				Local langIDs:Int[] = resultTitle.GetLanguageIDs()
				'remove numbers
				For Local langID:Int = EachIn langIDs
					Local numberfreeTitle:String = resultTitle.Get(langID)
					Local hashPos:Int = numberfreeTitle.FindLast("#")
					If hashPos > 2 '"sometext" + space + hash means > 2
						Local numberS:String = numberFreetitle[hashPos+1 .. ]
						If numberS = String(Int(numberS)) 'so "#123hashtag"
							numberfreeTitle = numberfreetitle[.. hashPos-1] 'remove space before too
						EndIf

						resultTitle.Set(numberfreeTitle, langID)
					EndIf
				Next
				'append number
				Local resultTitleCopy:TLocalizedString = resultTitle.Copy()
				'start with "2" to avoid "title #1"
				Local number:Int = 2
				Repeat
					For Local langID:Int = EachIn langIDs
						resultTitle.Set(resultTitleCopy.Get(langID) + " #"+number, langID)
					Next
					number :+ 1
					If number > 10000 Then Throw "TScript.GenerateTitleFromTemplate() - failed to generate title with increased number: " + resultTitle.Get()
				Until Not GetScriptCollection().IsTitleProtected(resultTitle)
			EndIf
		EndIf
		
		self.title = resultTitle
		Return True
	End Method	


	Method SetCustomTitle(value:String)
		customTitle = value
	End Method


	Method SetCustomDescription(value:String)
		customDescription = value
	End Method
	

	'override
	Method HasParentScript:Int()
		Return parentScriptID > 0
	End Method


	'override
	Method GetParentScript:TScript()
		If parentScriptID Then Return GetScriptCollection().GetByID(parentScriptID)
		Return Self
	End Method


	Method _ReplaceScriptExpressions:TLocalizedString(text:TLocalizedString, useTime:Long = 0)
		Local result:TLocalizedString = text.copy()

		For Local langID:Int = EachIn text.GetLanguageIDs()
			Local valueOld:String = text.Get(langID)
			Local context:SScriptExpressionContext = new SScriptExpressionContext(self, langID, Null)
			Local valueNew:TStringBuilder = GameScriptExpression.ParseLocalizedText(valueOld, context)
			If valueOLD <> valueNew.Hash()
				result.Set(valueNew.ToString(), langID)
			EndIf
		Next

		Return result
	End Method


	Function _EnsureRole:TProgrammeRole(actor:TPersonProductionJob, script:TScript = Null)
		Local roleID:Int = actor.roleID
		If roleID <> 0 Then return GetProgrammeRoleCollection().GetByID(roleID)
		Local country:String = actor.country
		If country And country.Contains("$")
			country = GameScriptExpression.ParseLocalizedText(country, new SScriptExpressionContext(script, 0, Null)).ToString()
		EndIf
		'TODO reuse previous role? - see inactive code in TScriptTemplate#GetFinalJobs
		Local role:TProgrammeRole = GetProgrammeRoleCollection().CreateRandomRole(country, actor.gender)
		actor.roleID = role.id
		return role
	End Function


	'override
	Method FinishProduction(programmeLicenceID:Int)
		Super.FinishProduction(programmeLicenceID)

		If basedOnScriptTemplateID
			Local template:TScriptTemplate = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
			If template Then template.FinishProduction(programmeLicenceID)

			'on finishing a multi-production; allow producing the same title again
			If GetProductionLimitMax() > 1 And CanGetProducedCount() <= 0
				GetScriptCollection().RemoveTitleProtection(title)
			EndIf
		EndIf
	End Method


	Method GetScriptTemplate:TScriptTemplate()
		If Not basedOnScriptTemplateID Then Return Null

		Return GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
	End Method


	'override default method to add subscripts
	Method SetOwner:Int(owner:Int=0)
		GetScriptCollection().SetScriptOwner(Self, owner)

		Super.SetOwner(owner)

		Return True
	End Method


	Method GetSpecificJobCount:Int(job:Int, limitPersonGender:Int=-1, limitRoleGender:Int=-1, ignoreSubScripts:Int = False)
		Local result:Int = 0
		For Local j:TPersonProductionJob = EachIn jobs
			'skip roles with wrong gender
			If limitRoleGender >= 0 And j.roleID
				Local role:TProgrammeRole = GetProgrammeRoleCollection().GetByID( j.roleID )
				If role And role.gender <> limitRoleGender Then Continue
			EndIf
			'skip persons with wrong gender
			If limitPersonGender >= 0 And j.gender <> limitPersonGender Then Continue

			'current job is one of the given job(s)
			If job & j.job Then result :+ 1
		Next

		'override with maximum found in subscripts
		If Not ignoreSubscripts And subScripts
			For Local subScript:TScript = EachIn subScripts
				result = Max(result, subScript.GetSpecificJobCount(job, limitPersonGender, limitRoleGender))
			Next
		EndIf

		Return result
	End Method


	Method GetJobs:TPersonProductionJob[]()
		Return jobs
	End Method


	Method GetSpecificJob:TPersonProductionJob[](job:Int, limitPersonGender:Int=-1, limitRoleGender:Int=-1)
		Local result:TPersonProductionJob[]
		For Local j:TPersonProductionJob = EachIn jobs
			'skip roles with wrong gender
			If limitRoleGender >= 0 And j.roleID
				Local role:TProgrammeRole = GetProgrammeRoleCollection().GetByID( j.roleID )
				If role And role.gender <> limitRoleGender Then Continue
			EndIf
			'skip persons with wrong gender
			If limitPersonGender >= 0 And j.gender <> limitPersonGender Then Continue

			'current job is one of the given job(s)
			If job & j.job Then result :+ [j]
		Next
		Return result
	End Method


	Method GetOutcome:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 Then Return outcome

		'script for a package or scripts
		Local value:Float
		For Local s:TScript = EachIn subScripts
			value :+ s.GetOutcome()
		Next
		Return value / subScripts.length
	End Method


	Method GetReview:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 Then Return review

		'script for a package or scripts
		Local value:Float
		For Local s:TScript = EachIn subScripts
			value :+ s.GetReview()
		Next
		Return value / subScripts.length
	End Method


	Method GetSpeed:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 Then Return speed

		'script for a package or scripts
		Local value:Float
		For Local s:TScript = EachIn subScripts
			value :+ s.GetSpeed()
		Next
		Return value / subScripts.length
	End Method


	Method GetPotential:Float() {_exposeToLua}
		'single-script
		If GetSubScriptCount() = 0 Then Return potential

		'script for a package or scripts
		Local value:Float
		For Local s:TScript = EachIn subScripts
			value :+ s.GetPotential()
		Next
		Return value / subScripts.length
	End Method


	Method GetBlocks:Int() override {_exposeToLua}
		Return blocks
	End Method


	Method GetEpisodeNumber:Int() {_exposeToLua}
		If Self <> GetParentScript() Then Return GetParentScript().GetSubScriptPosition(Self) + 1

		Return 0
	End Method


	Method GetEpisodes:Int() {_exposeToLua}
		If isSeries() Then Return GetSubScriptCount()

		Return 0
	End Method


	Method GetSellPrice:Int() {_exposeToLua}
		Return GetPrice()
	End Method


	Method GetPrice:Int() {_exposeToLua}
		Local value:Int
		'single-script
		If GetSubScriptCount() = 0
			value = price
		'script for a package or scripts
		Else
			For Local script:TScript = EachIn subScripts
				value :+ script.GetPrice()
			Next
			value :* 0.75
		EndIf

		'round to next "100" block
		value = Int(Floor(value / 100) * 100)

		Return value
	End Method


	Method CanBeXRated:Int()
		If HasBroadcastTimeSlot()
			'if script.broadcastTimeSlotStart >= 6 and script.broadcastTimeSlotStart + script.GetBlocks() <= 22 and ..
			'eg. 5-22, 5-5, ...
			if broadcastTimeSlotStart <= broadcastTimeSlotEnd 
				If broadcastTimeSlotStart + GetBlocks() >= 6 and broadcastTimeSlotStart <= 22
					Return False
				EndIf
			'eg. 20 - 5
			Else
				If broadcastTimeSlotStart + GetBlocks() <= 22 or broadcastTimeSlotEnd >= 6
					Return False
				EndIf
			EndIf
		EndIf
		
		Return True
	End Method

	'mixes main and subgenre criterias
	Method CalculateTotalGenreCriterias(totalReview:Float Var, totalSpeed:Float Var)
		Local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinition([mainGenre] + subGenres)
		If Not genreDefinition
			TLogger.Log("TScript.CalculateTotalGenreCriterias()", "script with wrong movie genre definition, criteria calculation failed.", LOG_ERROR)
			Return
		EndIf

		totalReview = genreDefinition.ReviewMod
		totalSpeed = genreDefinition.SpeedMod
	End Method


	'returns the criteria-congruence
	'(is review-speed ratio of script the same as in the genres)
	'a value of 1.0 means a perfect match
	'outcome is completely neglected here, because it is a result of the
	'production not an indicator of how well the script fits the genre
	Method CalculateGenreCriteriaFit:Float()
		'Fetch corresponding genre definition, with this we are able to
		'see what values are "expected" for this genre.

		Local reviewGenre:Float, speedGenre:Float
		CalculateTotalGenreCriterias(reviewGenre, speedGenre)

		'scale to total of 100%
		reviewGenre :/ (reviewGenre + speedGenre)
		speedGenre :/ (reviewGenre + speedGenre)
		Local reviewActual:Float = review / (review + speed)
		Local speedActual:Float = speed / (review + speed)

		Local distanceReview:Float = Abs(reviewGenre - reviewActual)
		Local distanceSpeed:Float = Abs(speedGenre - speedActual)

		Rem
		print "mainGenre:          "+mainGenre
		print "review:             "+review + "  scaled:  " + reviewActual + "  genre:" + reviewGenre
		print "speed:              "+speed + "  scaled:  " + speedActual + "  genre:" + speedGenre
		print "distannce review:   "+distanceReview
		print "distance speed:     "+distanceSpeed
		print "genre fit:          "+(1.0 - (distanceReview + distanceSpeed))
		EndRem

		Return 1.0 - (distanceReview + distanceSpeed)
	End Method


	Method Sell:Int()
		Local finance:TPlayerFinance = GetPlayerFinance(owner,-1)
		If Not finance Then Return False

		finance.SellScript(GetSellPrice(), Self)

		'set unused again

		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		Return True
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		Local finance:TPlayerFinance = GetPlayerFinance(playerID)
		If Not finance Then Return False

		If finance.PayScript(GetPrice(), Self)
			SetOwner(playerID)
			Return True
		EndIf
		Return False
	End Method


	Method GiveBackToScriptPool:Int()
		SetOwner( TOwnedGameObject.OWNER_NOBODY )

		'refill production limits if possible
		If HasProductionLimit() and HasScriptFlag(TVTScriptFlag.POOL_REFILLS_PRODUCTIONLIMITS)
			SetProductionLimit( GetProductionLimitMax() )
		endIf


		'remove tradeability?
		'(eg. for "exclusively written for player X scripts")
		If HasScriptFlag(TVTScriptFlag.POOL_REMOVES_TRADEABILITY)
'print "POOL_REMOVES_TRADEABILITY"
			SetScriptFlag(TVTScriptFlag.TRADEABLE, False)
		'remove tradeability for partially produced series
		ElseIf GetSubScriptCount() > 0 And GetProductionsCount() > 0
'print "PARTIALLY PRODUCED"
			SetScriptFlag(TVTScriptFlag.TRADEABLE, False)
		'if still no longer produceable (eg exceeding production limits)
		ElseIf not CanGetProduced()
'print "EXCEEDING PRODUCTION LIMIT"
			SetScriptFlag(TVTScriptFlag.TRADEABLE, False)
		EndIf


		'randomize attributes?
		If HasScriptFlag(TVTScriptFlag.TRADEABLE)
			If HasScriptFlag(TVTScriptFlag.POOL_RANDOMIZES_ATTRIBUTES)
				Local template:TScriptTemplate
				If basedOnScriptTemplateID Then template = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
				If template
					RandomizeBaseAttributes(template)
					blocks = template.GetBlocks()
					price = template.GetPrice()
					flags = template.GetFinalFlags()
					'do not enable X-Rated for live productions when
					'live time is not in the night
					if flags & TVTProgrammeDataFlag.XRATED
						If not CanBeXRated()
							SetFlag(TVTProgrammeDataFlag.XRATED, False)
						EndIf
					Endif

					targetGroup = template.GetFinalTargetGroup()
				EndIf
			EndIf
		EndIf


		'do the same for all children
		For Local subScript:TScript = EachIn subScripts
			subScript.GiveBackToScriptPool()
		Next

		'inform others about a now unused licence
		TriggerBaseEvent(GameEventKeys.Script_OnGiveBackToScriptPool, Null, Self)

		Return True
	End Method


	Method RandomizeBaseAttributes(template:TScriptTemplate = Null)
		If Not template
			If basedOnScriptTemplateID Then template = GetScriptTemplateCollection().GetByID(basedOnScriptTemplateID)
		EndIf

		If template
			outcome = template.GetOutcome()
			review = template.GetReview()
			speed = template.GetSpeed()
			potential = template.GetPotential()
		EndIf
	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:Int=0, studioSize:Int=-1)
		'=== PREPARE VARIABLES ===
		Local sheetWidth:Int = 310
		Local sheetHeight:Int = 0 'calculated later
		If align = -1 Then x = x
		If align = 0 Then x = x - 0.5 * sheetWidth
		If align = 1 Then x = x - sheetWidth

		Local skin:TDatasheetSkin = GetDatasheetSkin("script")
		Local contentW:Int = skin.GetContentW(sheetWidth)
		Local contentX:Int = x + skin.GetContentY()
		Local contentY:Int = y + skin.GetContentY()

		Local showMsgEarnInfo:Int = False
		Local showMsgLiveInfo:Int = False
		Local msgBroadcastLimit:String = getBroadCastLimitDatasheetText(self)
		Local showMsgTimeSlotLimit:Int = False
		'Local showMsgStudioTooSmall:Int = False

		If IsPaid() Then showMsgEarnInfo = True
		If IsLive() Then showMsgLiveInfo = True
		If HasBroadcastTimeSlot() Then showMsgTimeSlotLimit = True
		'If studioSize > 0 and studioSize < self.requiredStudioSize then showMsgStudioTooSmall = True


		Local title:String
		If Not isEpisode()
			title = GetTitle()
		Else
			title = GetParentScript().GetTitle()
		EndIf

		'can player afford this licence?
		Local canAfford:Int = False
		'possessing player always can
		If GetPlayerBaseCollection().playerID = owner
			canAfford = True
		'if it is another player... just display "can afford"
		ElseIf owner > 0
			canAfford = True
		'not our licence but enough money to buy ?
		Else
			Local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBaseCollection().playerID)
			If finance And finance.canAfford(GetPrice())
				canAfford = True
			EndIf
		EndIf


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		Local titleH:Int = 18, subtitleH:Int = 16, genreH:Int = 16, descriptionH:Int = 70, jobsH:Int=50
		Local splitterHorizontalH:Int = 6
		Local boxH:Int = 0, msgH:Int = 0, barH:Int = 0
		Local msgAreaH:Int = 0, boxAreaH:Int = 0, barAreaH:Int = 0
		Local boxAreaPaddingY:Int = 4, msgAreaPaddingY:Int = 4, barAreaPaddingY:Int = 4

		msgH = skin.GetMessageSize(contentW - 10, -1, "", "money", "good", Null, ALIGN_CENTER_CENTER).y
		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").y
		barH = skin.GetBarSize(100, -1).y
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 12, BOLDFONT).GetBoxHeight(title, contentW - 10, 100))

		'message area
		If showMsgEarnInfo Then msgAreaH :+ msgH
		If showMsgLiveInfo Then msgAreaH :+ msgH
		If msgBroadcastLimit Then msgAreaH :+ msgH
		'suits into the live-block
'If showMsgTimeSlotLimit and not showMsgLiveInfo Then msgAreaH :+ msgH
		If showMsgTimeSlotLimit Then msgAreaH :+ msgH
		'If showMsgStudioTooSmall Then msgAreaH :+ msgH
		'if there are messages, add padding of messages
		If msgAreaH > 0 Then msgAreaH :+ 2* msgAreaPaddingY


		'bar area starts with padding, ends with padding and contains
		'also contains 3 bars
		barAreaH = 2 * barAreaPaddingY + 3 * (barH + 2)

		'box area
		'contains 1 line of boxes + padding at the top
		boxAreaH = 1 * boxH
		If msgAreaH = 0 Then boxAreaH :+ boxAreaPaddingY

		'total height
		sheetHeight = titleH + genreH + descriptionH + jobsH + barAreaH + msgAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		If isEpisode() Then sheetHeight :+ subtitleH
		'there is a splitter between description and jobs...
		sheetHeight :+ splitterHorizontalH


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		If titleH <= 18
			GetBitmapFontManager().Get("default", 12, BOLDFONT).DrawBox(title, contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		Else
			GetBitmapFontManager().Get("default", 12, BOLDFONT).DrawBox(title, contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		EndIf
		contentY :+ titleH


		'=== SUBTITLE AREA ===
		If isEpisode()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			'episode num/max + episode title
			skin.fontNormal.DrawBox((GetParentScript().GetSubScriptPosition(Self)+1) + "/" + GetParentScript().GetSubScriptCount() + ": " + GetTitle(), contentX + 5, contentY, contentW - 10, genreH -1, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			contentY :+ subtitleH
		EndIf


		'=== COUNTRY / YEAR / GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		Local genreString:String = GetMainGenreString()
		'avoid "Action-Undefined" and "Show-Show"
		If scriptProductType <> TVTProgrammeProductType.UNDEFINED And scriptProductType <> TVTProgrammeProductType.SERIES
			Local sameType:Int = True
			If (TVTProgrammeProductType.GetAsString(scriptProductType) <> TVTProgrammeGenre.GetAsString(mainGenre))
				If scriptProductType = TVTProgrammeProductType.SHOW And TVTProgrammeGenre.GetGroupKey(mainGenre) <> TVTProgrammeGenre.SHOW Then sameType = False
				If scriptProductType = TVTProgrammeProductType.FEATURE And TVTProgrammeGenre.GetGroupKey(mainGenre) <> TVTProgrammeGenre.FEATURE Then sameType = False
			EndIf

'				If Not(TVTProgrammeProductType.GetAsString(scriptProductType) = "feature" And TVTProgrammeGenre.GetAsString(mainGenre).Find("feature")>=0)
			If Not sameType
				genreString :+ " (" +GetProductionTypeString()+")"
			ElseIf subGenres And GetProductionLimitMax() = 1
				If subGenres.length > 0 Then genreString :+ ", "+ _GetGenreString(subGenres[0])
				If subGenres.length > 1 Then genreString :+ ", "+ _GetGenreString(subGenres[1])
			EndIf
		EndIf
		if IsCulture()
			genreString :+ ", |i|" + GetLocale("PROGRAMME_FLAG_CULTURE") +"|/i|"
		endif
		If IsSeries()
			genreString :+ " / " + GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubScriptCount())
		ElseIf GetProductionLimitMax() > 1
			genreString :+ " / " +  GetProductionLimitMax() + " " +GetLocale("MOVIE_EPISODES")
		EndIf

		skin.fontNormal.DrawBox(genreString, contentX + 5, contentY, contentW - 10, genreH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ genreH


		'=== DESCRIPTION AREA ===
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		skin.fontNormal.DrawBox(GetDescription(), contentX + 5, contentY + 1, contentW - 10, descriptionH - 1, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		contentY :+ descriptionH


		'splitter
		skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
		contentY :+ splitterHorizontalH


		'=== JOBS AREA ===
		skin.RenderContent(contentX, contentY, contentW, jobsH, "2")

		'jobs
		Local jobsText:String = ""

		For Local jobID:Int = EachIn TVTPersonJob.GetCastJobs()
			'call with "false" to return maximum required persons within
			'sub scripts too
			Local requiredPersons:Int = GetSpecificJobCount(jobID,-1,-1, False)
			If requiredPersons <= 0 Then Continue

			If jobsText <> "" Then jobsText :+ ", "

			Local requiredPersonsMale:Int = GetSpecificJobCount(jobID, TVTPersonGender.MALE)
			Local requiredPersonsFemale:Int = GetSpecificJobCount(jobID, TVTPersonGender.FEMALE)
			requiredPersons = Max(requiredPersons, requiredPersonsMale + requiredPersonsFemale)

			If requiredPersons = 1
				jobsText :+ "|b|"+requiredPersons+"x|/b| "+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, True))
			Else
				jobsText :+ "|b|"+requiredPersons+"x|/b| "+GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID, False))
			EndIf


			Local requiredDetails:String = ""
			If requiredPersonsMale > 0
				'write amount if multiple genders requested for this job type
				If requiredPersonsMale <> requiredPersons
					requiredDetails :+ requiredPersonsMale+"x "+GetLocale("MALE")
				Else
					requiredDetails :+ GetLocale("MALE")
				EndIf
			EndIf
			If requiredPersonsFemale > 0
				If requiredDetails <> "" Then requiredDetails :+ ", "
				'write amount if multiple genders requested for this job type
				If requiredPersonsFemale <> requiredPersons
					requiredDetails :+ requiredPersonsFemale+"x "+GetLocale("FEMALE")
				Else
					requiredDetails :+ GetLocale("FEMALE")
				EndIf
			EndIf
			If requiredPersons - (requiredPersonsMale + requiredPersonsFemale) > 0
				'write amount if genders for this job type were defined
				If requiredPersonsMale > 0 Or requiredPersonsFemale > 0
					If requiredDetails <> "" Then requiredDetails :+ ", "
					requiredDetails :+ (requiredPersons - (requiredPersonsMale + requiredPersonsFemale))+"x "+GetLocale("UNDEFINED")
				EndIf
			EndIf
			If requiredDetails <> ""
				jobsText :+ " (" + requiredDetails + ")"
			EndIf
		Next

Rem
		local requiredDirectors:int = GetSpecificCastCount(TVTPersonJob.DIRECTOR)
		local requiredStarRoleActorFemale:int = GetSpecificCastCount(TVTPersonJob.ACTOR, TVTPersonGender.FEMALE)
		local requiredStarRoleActorMale:int = GetSpecificCastCount(TVTPersonJob.ACTOR, TVTPersonGender.MALE)
		local requiredStarRoleActors:int = GetSpecificCastCount(TVTPersonJob.ACTOR)

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

		If jobsText <> ""
			'render director + cast (offset by 3 px)
			skin.fontNormal.DrawBox("|b|"+GetLocale("MOVIE_CAST") + ":|/b| " + jobsText, contentX + 5, contentY , contentW  - 10, jobsH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings)
		EndIf
		contentY:+ jobsH


		'=== BARS / MESSAGES / BOXES AREA ===
		'background for bars + boxes
		skin.RenderContent(contentX, contentY, contentW, barAreaH + msgAreaH + boxAreaH, "1_bottom")


		'===== DRAW RATINGS / BARS =====

		'bars have a top-padding
		contentY :+ barAreaPaddingY
		'speed
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetSpeed())
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_SPEED"), contentX + 5 + 200 + 5, contentY - 3, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 2
		'critic/review
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetReview())
		skin.fontSmallCaption.DrawSimple(GetLocale("MOVIE_CRITIC"), contentX + 5 + 200 + 5, contentY - 3, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 2
		'potential
		skin.RenderBar(contentX + 5, contentY, 200, 12, GetPotential())
		skin.fontSmallCaption.DrawSimple(GetLocale("SCRIPT_POTENTIAL"), contentX + 5 + 200 + 5, contentY - 3, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
		contentY :+ barH + 2


		'=== MESSAGES ===
		'if there is a message then add padding to the begin
		If msgAreaH > 0 Then contentY :+ msgAreaPaddingY

		If showMsgLiveInfo
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLiveTimeText(-1), "runningTime", EDatasheetColorStyle.Bad, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		If showMsgTimeSlotLimit
			if getEpisodes() > 0
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("BROADCAST_TIME_RESTRICTED"), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			Else if productionBroadcastFlags & TVTBroadcastMaterialSourceFlag.KEEP_BROADCAST_TIME_SLOT_ENABLED_ON_BROADCAST > 0
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", GetBroadcastTimeSlotStart()).Replace("%Y%", GetBroadcastTimeSlotEnd()), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			Else
				skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("FIRST_BROADCAST_ONLY_ALLOWED_FROM_X_TO_Y").Replace("%X%", GetBroadcastTimeSlotStart()).Replace("%Y%", GetBroadcastTimeSlotEnd()), "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			EndIf
			contentY :+ msgH
		EndIf

		If msgBroadcastLimit
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, msgBroadcastLimit, "spotsPlanned", EDatasheetColorStyle.Warning, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		If showMsgEarnInfo
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, getLocale("MOVIE_CALLINSHOW").Replace("%PROFIT%", "***"), "money", EDatasheetColorStyle.Good, skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf

		rem
		If showMsgStudioTooSmall
			skin.RenderMessage(contentX+5, contentY, contentW - 9, -1, GetLocale("STUDIO_TOO_SMALL") + ". " + GetLocale("REQUIRED_SIZE_X").Replace("%X%", requiredStudioSize), "roomsize", "bad", skin.fontNormal, ALIGN_CENTER_CENTER)
			contentY :+ msgH
		EndIf
		endrem
		'if there is a message then add padding to the bottom
		If msgAreaH > 0 Then contentY :+ msgAreaPaddingY


		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		'if msgAreaH = 0 then contentY :+ boxAreaPaddingY
		contentY :+ boxAreaPaddingY
		'blocks
		skin.RenderBox(contentX + 5, contentY, 50, -1, GetBlocks(), "duration", EDatasheetColorStyle.Neutral, skin.fontBold)
		'room size
		If studioSize > 0 and studioSize < requiredStudioSize
			skin.RenderBox(contentX + 5 + 1*59, contentY, 45, -1, requiredStudioSize, "roomsize", EDatasheetColorStyle.Bad, skin.fontBold)
		Elseif studioSize > 0 and studioSize >= requiredStudioSize
			skin.RenderBox(contentX + 5 + 1*59, contentY, 45, -1, requiredStudioSize, "roomsize", EDatasheetColorStyle.Good, skin.fontBold)
		Else
			skin.RenderBox(contentX + 5 + 1*59, contentY, 45, -1, requiredStudioSize, "roomsize", EDatasheetColorStyle.Neutral, skin.fontBold)
		Endif
		If IsLive()
			'estimated (no clue about efficiency mods through better
			'production team etc)
			local effectiveProductionDuration:Long = GetBaseProductionDuration()

			skin.RenderBox(contentX + 5 + 2*59 - 5, contentY, 72, -1, TWorldtime.GetHourMinutesLeft(effectiveProductionDuration, 4), "runningTime", EDatasheetColorStyle.Neutral, skin.fontBold)
		EndIf
		'price
		If canAfford
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, MathHelper.DottedValue(GetPrice()), "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER)
		Else
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, MathHelper.DottedValue(GetPrice()), "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
		EndIf
		contentY :+ boxH


		'=== DEBUG ===
		If TVTDebugInfo
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			Local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.DrawBox("Drehbuch: "+GetTitle(), contentX + 5, contentY, contentW - 10, 28, sALIGN_LEFT_TOP, SColor8.White)
			contentY :+ 28
			skin.fontNormal.DrawSimple("Tempo: "+MathHelper.NumberToString(GetSpeed(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Kritik: "+MathHelper.NumberToString(GetReview(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Potential: "+MathHelper.NumberToString(GetPotential(), 4), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("Preis: "+GetPrice(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("IsProduced: "+IsProduced(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("IsTradeable: "+IsTradeable(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("scriptFlags: "+scriptFlags, contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.DrawSimple("owner: "+owner, contentX + 5, contentY)
		EndIf

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)

		'=== X-Rated Overlay ===
		If IsXRated()
			GetSpriteFromRegistry(spriteNameOverlayXRatedLS).Draw(contentX + sheetWidth, y, -1, ALIGN_RIGHT_TOP)
		EndIf

		Function getBroadCastLimitDatasheetText:String(s:TScript)
			local limitMin:int = 1000
			local limitMax:int = -1
			local suffix:String = ""
			local childCount:int = s.getSubScriptCount()
			if childCount > 0
				local limitCount:int = 0
				For local c:TScript = eachin s.subSCripts
					local childLimit:int=c.GetProductionBroadcastLimit()
					if childLimit > 0 'limit 0 for script does not make sense
						limitMin = min(limitMin, childLimit)
						limitMax = max(limitMax, childLimit)
						limitCount :+ 1
					endif
				Next
				if limitCount < childCount then suffix = " ("+limitCount+"/"+childCount+")"
			else
				limitMin = s.GetProductionBroadcastLimit()
				limitMax = limitMin
			endif

			if limitMax <= 0
				'for scripts limit 0 indicates no limit
				return ""
			elseif limitMin = 1 and limitMax = 1
				return getLocale("ONLY_1_BROADCAST_POSSIBLE") + suffix
			elseif limitMin <> limitMax
				return getLocale("ONLY_X_BROADCASTS_POSSIBLE").replace("%X%", limitMin+"-"+limitMax) + suffix
			else
				return getLocale("ONLY_X_BROADCASTS_POSSIBLE").replace("%X%", limitMin) + suffix
			endif
		End Function
	End Method
End Type
