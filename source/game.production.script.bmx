SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.localization.bmx"
Import "game.gameobject.bmx"
Import "game.player.finance.bmx"
Import "game.player.base.bmx"
Import "game.gameconstants.bmx" 'to access type-constants
Import "basefunctions.bmx" 'dottedValue
Import "game.production.scripttemplate.bmx"

Type TScriptCollection Extends TGameObjectCollection
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
		return Super.Remove(script)
	End Method


	Method GetByGUID:TScript(GUID:String)
		Return TScript( Super.GetByGUID(GUID) )
	End Method


	Method GenerateRandom:TScript()
		local template:TScriptTemplate = GetScriptTemplateCollection().GetRandom()
		local script:TScript = TScript.CreateFromTemplate(template)
		Add(script)
		return script
	End Method


	Method GetRandomAvailable:TScript()
		'if no script is available, create some a new one
		if GetAvailableScriptList().Count() = 0 then GenerateRandom()
		
		'fetch a random script
		return TScript(GetAvailableScriptList().ValueAtIndex(randRange(0, GetAvailableScriptList().Count() - 1)))
	End Method


	'returns (and creates if needed) a list containing only available
	'and unused scripts.
	'Scripts of episodes and other children are ignored 
	Method GetAvailableScriptList:TList()
		if not _availableScripts
			_availableScripts = CreateList()
			For local script:TScript = EachIn GetParentScriptList()
				'skip used scripts (or scripts already at the vendor)
				if script.owner <> 0 then continue

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
				if script.owner = 0 then continue

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
				if script.scriptType = TVTProgrammeType.Episode then continue
				if script.parentScriptGUID <> "" then continue

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
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetScriptCollection:TScriptCollection()
	Return TScriptCollection.GetInstance()
End Function




Type TScript Extends TNamedGameObject {_exposeToLua="selected"}
	Field title:TLocalizedString
	Field description:TLocalizedString
	Field ownProduction:Int	= false
	Field scriptType:Int = 0
	Field genre:Int = 0
	'News-Genre: Medien/Technik, Politik/Wirtschaft, Showbiz, Sport, Tagesgeschehen ODER flexibel = spezielle News (10)
	Field topic:Int	= 0

	Field outcome:Float	= 0.0
	Field review:Float = 0.0
	Field speed:Float = 0.0
	Field potential:Float = 0.0

	'cast contains various jobs but with no "person" assigned in it, so
	'it is more a "job" definition (+role in the case of actors)
	Field cast:TProgrammePersonJob[]

	'0=director, 1=host, 2=actor, 4=musician, 8=intellectual, 16=reporter(, 32=candidate)
	Field allowedGuestTypes:int	= 0

	Field requiredStudioSize:Int = 1
	Field requireAudience:Int = 0
	Field coulisseType1:Int	= -1
	Field coulisseType2:Int	= -1
	Field coulisseType3:Int = -1

	Field targetGroup:Int = -1

	Field price:Int	= 0
	Field blocks:Int = 0
	'flags contains bitwise encoded things like xRated, paid, trash ...
	Field flags:Int = 0

	'if the script is a clone of something, basedOnScriptGUID contains
	'the guid of the original script.
	'This is used for "shows" to be able to use different values of
	'outcome/speed/price/... while still having a connecting link
	Field basedOnScriptGUID:String = ""
	'scripts of series are parent of episode scripts
	Field parentScriptGUID:string = ""
	'all associated child scripts (episodes)
	Field subScripts:TScript[]


	Function CreateFromTemplate:TScript(template:TScriptTemplate)
		local script:TScript = new TScript
		script.title = template.GenerateFinalTitle()
		script.description = template.GenerateFinalDescription()

		script.outcome = template.GetOutcome()
		script.review = template.GetReview()
		script.speed = template.GetSpeed()
		script.potential = template.GetPotential()
		script.blocks = template.GetBlocks()
		script.price = template.GetPrice()
		script.cast = template.GetJobs()

		'replace placeholders as we know the cast / roles now
		script.title = script._ReplacePlaceholders(script.title)
		script.description = script._ReplacePlaceholders(script.description)

		'add children
		For local subTemplate:TScriptTemplate = EachIn template.subScriptTemplates
			local subScript:TScript = TScript.CreateFromTemplate(subTemplate)
			if subScript then script.AddSubScript(subScript)
		Next

		'reset the state of the template
		'without that, the following scripts created with this template
		'as base will get the same title/description
		template.Reset()
		
		return script
	End Function


	'override to add another generic naming
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "script-"+id
		self.GUID = GUID
	End Method


	Method hasFlag:Int(flag:Int) {_exposeToLua}
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


	Method GetDescription:string()
		if description then return description.Get()
		return ""
	End Method


	Method _ReplacePlaceholders:TLocalizedString(text:TLocalizedString)
		local result:TLocalizedString = text.copy()

		'for each defined language we check for existent placeholders
		'which then get replaced by a random string stored in the
		'variable with the same name
		For local lang:string = EachIn text.GetLanguageKeys()
			local value:string = text.Get(lang)
			local placeHolders:string[] = StringHelper.ExtractPlaceholders(value, "%")
			if placeHolders.length = 0 then continue

			local actors:TProgrammePersonJob[] = GetSpecificCast(TVTProgrammePersonJob.ACTOR | TVTProgrammePersonJob.SUPPORTINGACTOR)
			local replacement:string = ""
			for local placeHolder:string = EachIn placeHolders
				replacement = ""
				Select placeHolder.toUpper()
					case "%ROLENAME1%"
						if actors.length > 0 and actors[0].roleGUID <> ""
							local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(actors[0].roleGUID)
							if role then replacement = role.GetFirstName()
						endif
						'gender neutral default
						if replacement = "" then replacement = "Robin"
					case "%ROLENAME2%"
						if actors.length > 1 and actors[1].roleGUID <> ""
							local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(actors[1].roleGUID)
							if role then replacement = role.GetFirstName()
						endif
						'gender neutral default
						if replacement = "" then replacement = "Alex"
					case "%ROLE1%"
						if actors.length > 0 and actors[0].roleGUID <> ""
							local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(actors[0].roleGUID)
							if role then replacement = role.GetFullName()
						endif
						'gender neutral default
						if replacement = "" then replacement = "Robin Mayer"
					case "%ROLE2%"
						if actors.length > 1 and actors[1].roleGUID <> ""
							local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(actors[1].roleGUID)
							if role then replacement = role.GetFullName()
						endif
						'gender neutral default
						if replacement = "" then replacement = "Alex Hulley"
				End Select

				'replace if some content was filled in
				if replacement <> "" then value = value.replace(placeHolder, replacement)
			Next
			
			result.Set(value, lang)
		Next
	
		return result
	End Method	



	'override default method to add sublicences
	Method SetOwner:int(owner:int=0)
		GetScriptCollection().SetScriptOwner(self, owner)

		'do the same for all children
		For local script:TScript = eachin subScripts
			script.SetOwner(owner)
		Next
		return TRUE
	End Method


	Method SetBasedOnScriptGUID(basedOnScriptGUID:string)
		self.basedOnScriptGUID = basedOnScriptGUID
	End Method


	Method GetSubScriptCount:int() {_exposeToLua}
		return subScripts.length
	End Method


	Method GetSubScriptAtIndex:TScript(arrayIndex:int=1) {_exposeToLua}
		if arrayIndex > subScripts.length or arrayIndex < 0 then return null
		return subScripts[arrayIndex]
	End Method


	Method GetParentScript:TScript() {_exposeToLua}
		if not parentScriptGUID then return self
		return GetScriptCollection().GetByGUID(parentScriptGUID)
	End Method


	Method GetSubScriptPosition:int(script:TScript) {_exposeToLua}
		'find my position and add 1
		For local i:int = 0 to GetSubScriptCount() - 1
			if GetSubScriptAtIndex(i) = script then return i
		Next
		return 0
	End Method


	'returns the next script of a scripts parent subscripts
	Method GetNextSubScript:TScript() {_exposeToLua}
		if not parentScriptGUID then return Null

		'find my position and add 1
		local nextArrayIndex:int = GetParentScript().GetSubScriptPosition(self) + 1
		'if we are at the last position, return the first one
		if nextArrayIndex >= GetParentScript().GetSubScriptCount() then nextArrayIndex = 0

		return GetParentScript().GetSubScriptAtIndex(nextArrayIndex)
	End Method


	Method AddSubScript:int(script:TScript)
		'=== ADJUST SCRIPT TYPES ===

		'as each script is individual we easily can set the main script
		'as parent (so subscripts can ask for sibling scripts).
		script.parentScriptGUID = self.GetGUID()

		'add to array of subscripts
		subScripts :+ [script]
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


	Method GetSpecificCastCount:int(job:int, limitGender:int=-1)
		local result:int = 0
		For local j:TProgrammePersonJob = EachIn cast
			'skip roles with wrong gender
			if limitGender >= 0 and j.roleGUID
				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(j.roleGUID)
				if role and role.gender <> limitGender then continue
			endif
			'current job is one of the given job(s)
			if job & j.job then result :+ 1
		Next
		return result
	End Method


	Method GetSpecificCast:TProgrammePersonJob[](job:int, limitGender:int=-1)
		local result:TProgrammePersonJob[]
		For local j:TProgrammePersonJob = EachIn cast
			'skip roles with wrong gender
			if limitGender >= 0 and j.roleGUID
				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(j.roleGUID)
				if role and role.gender <> limitGender then continue
			endif
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


	'returns the genre of a script - if a group, the one used the most
	'often is returned
	Method GetGenre:int() {_exposeToLua}
		if GetSubScriptCount() = 0 then return genre

		local genres:int[]
		local bestGenre:int=0
		For local script:TScript = eachin subScripts
			local genre:int = script.GetGenre()
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
		Return GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(_genre))
	End Method


	Method Sell:int()
		local finance:TPlayerFinance = GetPlayerFinance(owner,-1)
		if not finance then return False

		finance.SellScript(GetPrice(), self)

		'set unused again
		SetOwner(0)

		return TRUE
	End Method


	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int=-1)
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(playerID, -1)
		if not finance then return False

		If finance.PayScript(getPrice(), self)
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
	End Method


	Method isSeries:int() {_exposeToLua}
		return (scriptType & TVTProgrammeLicenceType.SERIES)
	End Method


	Method isEpisode:int() {_exposeToLua}
		return (scriptType & TVTProgrammeLicenceType.EPISODE)
	End Method




	Method ShowSheet:Int(x:Int,y:Int, align:int=0)
		Local fontNormal:TBitmapFont   = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont     = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local currTextWidth:int

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()


		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		if isEpisode() or isSeries()
			sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif
		'country + year + genre
		sprite = GetSpriteFromRegistry("gfx_datasheet_country"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_splitter"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content2"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subScriptRatings"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		sprite = GetSpriteFromRegistry("gfx_datasheet_subScriptAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		
		if isSeries()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubScriptCount()), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		elseif isEpisode()
			'title of "series"
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetParentScript().GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
			'episode num/max + episode title
			fontNormal.drawBlock((GetParentScript().GetSubScriptPosition(self)+1) + "/" + GetParentScript().GetSubScriptCount() + ": " + GetTitle(), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 16
		else ' = if isMovie()
			'default is size "12" so resize to 13
			GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 18
		endif

		fontNormal.drawBlock(GetGenreString(), currX + 6 + 67, currY, 215, 16, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(GetDescription(), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		'splitter
		currY :+ 6

		currY :+ 3	'subcontent (actors/director) start with offset

		'max width of cast word - to align their content properly
		currTextWidth = Int(fontSemiBold.getWidth(GetLocale("MOVIE_CAST")+":"))

		'cast
		local cast:string = ""

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

		if cast <> ""
			fontSemiBold.drawBlock(GetLocale("MOVIE_CAST")+":", currX + 6, currY, 280, 13, null, textColor)
			fontNormal.drawBlock(cast, currX + 6 + 5 + currTextWidth, currY , 280 - 15 - currTextWidth, 45, null, textColor)
		endif
		currY :+ 39
		currY :+ 3 'subcontent end with offset
		currY :+ 1 'end of subcontent area

		'===== DRAW RATINGS / BARS =====
		'captions
		currY :+ 4 'offset of ratings
		fontSemiBold.drawBlock(GetLocale("MOVIE_SPEED"),      currX + 215, currY,      75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("MOVIE_CRITIC"),     currX + 215, currY + 16, 75, 15, null, textLightColor)
		fontSemiBold.drawBlock(GetLocale("SCRIPT_POTENTIAL"),  currX + 215, currY + 32, 75, 15, null, textLightColor)

		'===== DRAW BARS =====

		If GetSpeed() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1, GetSpeed()*200  , 10))
		If GetReview() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 16, GetReview()*200 , 10))
		If GetPotential() > 0.01 Then GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX+8, currY + 1 + 32, GetPotential()*200, 10))
		currY :+ 48

		currY :+ 4 'align to content portion of that line
		'blocks
		fontBold.drawBlock(GetBlocks(), currX + 33, currY, 17, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)

		
		'price
		local finance:TPlayerFinance
		'only check finances if it is no other player (avoids exposing
		'that information to us)
		if owner <= 0 or GetPlayerBaseCollection().playerID = owner
			finance = GetPlayerFinance(GetPlayerBaseCollection().playerID, -1)
		endif
		local canAfford:int = False
		'possessing player always can
		if GetPlayerBaseCollection().playerID = owner
			canAfford = True
		'if it is another player... just display "can afford"
		elseif owner >= 0
			canAfford = True
		'not our licence but enough money to buy
		elseif finance and finance.canAfford(GetPrice())
			canAfford = True
		endif
		
		if canAfford
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
		else
			fontBold.drawBlock(TFunctions.DottedValue(GetPrice()), currX + 227, currY, 55, 15, ALIGN_RIGHT_CENTER, TColor.Create(200,0,0), 0,1,1.0,True, True)
		endif
		currY :+ 15 + 8 'lineheight + bottom content padding

		'=== X-Rated Overlay ===
		If IsXRated()
			GetSpriteFromRegistry("gfx_datasheet_xrated").Draw(currX + GetSpriteFromRegistry("gfx_datasheet_title").GetWidth(), y, -1, ALIGN_RIGHT_TOP)
		Endif

rem
		If TVTDebugInfos
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			local w:int = GetSpriteFromRegistry("gfx_datasheet_title").area.GetW() - 20
			local h:int = Max(120, currY-y)
			DrawRect(currX, y, w,h)
		
			SetColor 255,255,255
			SetAlpha oldAlpha

			local textY:int = y + 5
			fontBold.draw("Programm: "+GetTitle(), currX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Letzte Stunde im Plan: "+latestPlannedEndHour, currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Tempo: "+data.GetSpeed(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Kritik: "+data.GetReview(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Kinokasse: "+data.GetOutcome(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Preismodifikator: "+data.GetModifier("price"), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet roh: "+data.GetQualityRaw()+"  (ohne Alter, Wdh.)", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet: "+data.GetQuality(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Aktualitaet: "+data.GetTopicality()+" von " + data.GetMaxTopicality(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Bloecke: "+data.GetBlocks(), currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Ausgestrahlt: "+data.GetTimesAired(owner)+"x Spieler, "+data.GetTimesAired()+"x alle", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Quotenrekord: "+Long(GetBroadcastStatistic().GetBestAudienceResult(owner, -1).audience.GetSum())+" (Spieler), "+Long(GetBroadcastStatistic().GetBestAudienceResult(-1, -1).audience.GetSum())+" (alle)", currX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Preis: "+GetPrice(), currX + 5, textY)
		Endif
endrem
	End Method
End Type