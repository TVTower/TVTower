SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.gameobject.bmx"
Import "game.player.finance.bmx"
Import "game.player.base.bmx"
Import "basefunctions.bmx" 'dottedValue
Import "game.production.scripttemplate.bmx"
'to access datasheet-functions
Import "common.misc.datasheet.bmx"



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
		script.SetOwner(TOwnedGameObject.OWNER_NOBODY)
		Add(script)
		return script
	End Method


	Method GetRandomAvailable:TScript()
		'if no script is available, create (and return) some a new one
		if GetAvailableScriptList().Count() = 0 then return GenerateRandom()

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
				if script.IsOwned() then continue

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




Type TScript Extends TScriptBase {_exposeToLua="selected"}
	Field ownProduction:Int	= false
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

	'if the script is a clone of something, basedOnScriptGUID contains
	'the guid of the original script.
	'This is used for "shows" to be able to use different values of
	'outcome/speed/price/... while still having a connecting link
	Field basedOnScriptGUID:String = ""



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


	'override
	Method GetParentScript:TScript()
		if not parentScriptGUID then return self
		return GetScriptCollection().GetByGUID(parentScriptGUID)
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

		Super.SetOwner(owner)

		return TRUE
	End Method


	Method SetBasedOnScriptGUID(basedOnScriptGUID:string)
		self.basedOnScriptGUID = basedOnScriptGUID
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
		local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(playerID, -1)
		if not finance then return False

		If finance.PayScript(getPrice(), self)
			SetOwner(playerID)
			Return TRUE
		EndIf
		Return FALSE
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
			local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(GetPlayerBaseCollection().playerID, -1)
			if finance and finance.canAfford(GetPrice())
				canAfford = True
			endif		
		endif
		
		
		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, subtitleH:int = 16, genreH:int = 16, descriptionH:int = 70, castH:int=50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, barH:int = 0
		local boxAreaH:int = 0, barAreaH:int = 0
		local boxAreaPaddingY:int = 4, barAreaPaddingY:int = 4

		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))

		'bar area starts with padding, ends with padding and contains
		'also contains 3 bars
		barAreaH = 2 * barAreaPaddingY + 3 * (barH + 2)

		'box area
		'contains 1 line of boxes + padding at the top
		boxAreaH = 1 * boxH + 1 * boxAreaPaddingY

		'total height
		sheetHeight = titleH + genreH + descriptionH + castH + barAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		if isSeries() or isEpisode() then sheetHeight :+ subtitleH
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
		if isSeries()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			skin.fontNormal.drawBlock(GetLocale("SERIES_WITH_X_EPISODES").Replace("%EPISODESCOUNT%", GetSubScriptCount()), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		elseif isEpisode()
			skin.RenderContent(contentX, contentY, contentW, subtitleH, "1")
			'episode num/max + episode title
			skin.fontNormal.drawBlock((GetParentScript().GetSubScriptPosition(self)+1) + "/" + GetParentScript().GetSubScriptCount() + ": " + GetTitle(), contentX + 5, contentY, contentW - 10, genreH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH
		endif


		'=== COUNTRY / YEAR / GENRE AREA ===
		skin.RenderContent(contentX, contentY, contentW, genreH, "1")
		skin.fontNormal.drawBlock(GetMainGenreString(), contentX + 5, contentY, contentW - 10, genreH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
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


		'=== BARS / BOXES AREA ===
		'background for bars + boxes
		skin.RenderContent(contentX, contentY, contentW, barAreaH + boxAreaH, "1_bottom")


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

		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		'if msgAreaH = 0 then contentY :+ boxAreaPaddingY
		contentY :+ boxAreaPaddingY
		'blocks
		skin.RenderBox(contentX + 5, contentY, 47, -1, GetBlocks(), "duration", "neutral", skin.fontBold)
		'price
		if canAfford
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(GetPrice()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		else
			skin.RenderBox(contentX + 5 + 194, contentY, contentW - 10 - 194 +1, -1, TFunctions.DottedValue(GetPrice()), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
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
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)

		'=== X-Rated Overlay ===
		If IsXRated()
			GetSpriteFromRegistry("ggfx_datasheet_overlay_xrated").Draw(contentX + sheetWidth, y, -1, ALIGN_RIGHT_TOP)
		Endif				
	End Method
End Type