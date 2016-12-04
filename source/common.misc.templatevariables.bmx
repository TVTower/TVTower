SuperStrict
Import Brl.Map
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string.bmx"
Import "game.gameinformation.base.bmx" 'to access worldtime



'By default templatevariables use the registered variables and placeholders
'but also default ones via GetGameInformation(placeHolder.toLower(), "")
'to fill in the corresponding data.
'so when adding new placeholder-handlers, also check the gameinformation
'system if it is containing them already
Type TTemplateVariables
	'Variables are used to replace certain %KEYWORDS% in title or
	'description. They are stored as "%KEYWORD%"=>TLocalizedString
	Field variables:TMap
	'placeHolderVariables contain TLocalizedString-objects which are used
	'to replace a specific palceholder. This allows to reuse the exact same
	'random variable for descendants (episodes refering to the same
	'keyword) instead of returning other random elements ("option1|option2")
	Field placeHolderVariables:TMap

	'override this in CUSTOM variable types to return the parental TTemplateVariables 
	Method GetParentTemplateVariables:TTemplateVariables()
		return null
	End Method


	Method Reset()
		placeHolderVariables = null
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

		if not result
			local parent:TTemplateVariables = GetParentTemplateVariables()
			if parent then result = parent.GetPlaceholderVariableString(key, defaultValue, createDefault)
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

		if not result
			local parent:TTemplateVariables = GetParentTemplateVariables()
			if parent then result = parent.GetVariableString(key, defaultValue, createDefault)
		endif

		if not result and createDefault
			result = new TLocalizedString
			result.Set(defaultValue)
		endif
		return result
	End Method


	Method GetRandomFromLocalizedString:TLocalizedString(localizedString:TLocalizedString, defaultValue:string = "MISSING")
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


	Method ReplacePlaceholders:TLocalizedString(text:TLocalizedString)
		local result:TLocalizedString = text.copy()
'print "ReplacePlaceholders: "+ text.Get()
		'for each defined language we check for existent placeholders
		'which then get replaced by a random string stored in the
		'variable with the same name
		For local lang:string = EachIn text.GetLanguageKeys()
			'do it 4 times, this allows for placeholder definitions within
			'placeholders (at least some of them)!
			local replacedPlaceholders:int = 0
			for local i:int = 0 to 3
				'use result already (to allow recursive-replacement)
				local value:string = result.Get(lang)
				local placeHolders:string[] = StringHelper.ExtractPlaceholders(value, "%")

				if placeHolders.length > 0
'if lang="de" then print "  "+lang+"  run "+i
'if lang="de" then print "   -> value = " + value
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
							replacement = GetRandomFromLocalizedString( replacement )

							'if the parent stores this variable (too) then save
							'the placeholder there instead of the children
							'so other children could use the same placeholders
							'(if there is no parent then "self" is returned)
							local parent:TTemplateVariables = GetParentTemplateVariables()
							if parent and parent.GetVariableString(placeHolder, "", False)
								parent.AddPlaceHolderVariable(placeHolder, replacement)
							else
								AddPlaceHolderVariable(placeHolder, replacement)
							endif
							'store the replacement in the value
							value = value.replace(placeHolder, replacement.Get(lang))
'if lang="de" then print "        replace: "+placeHolder+" => " + replacement.Get(lang)
							replacedPlaceHolders :+ 1
						endif
					Next
				endif
				
				result.Set(value, lang)
'if placeHolders.length > 0
'	if lang="de" then print "   <- value = " + value
'endif
				'skip further checks (0 placeholders or all possible replaced)
				if placeHolders.length = 0 or (placeHolders.length > 0 and replacedPlaceHolders = 0)
					exit
				endif
			Next
		Next


		'replace common placeholders (%worldtime:year% and so on)
		'loop over "text", but replace in "result"
		For local lang:string = EachIn text.GetLanguageKeys()
			local value:string = result.Get(lang)
			local placeHolders:string[] = StringHelper.ExtractPlaceholders(value, "%", True)
			for local placeHolder:string = EachIn placeHolders
				local replacement:string = string(GetGameInformation(placeHolder.toLower().replace("%", ""), ""))
				if replacement = "UNKNOWN_INFORMATION"
					replacement = placeHolder
				endif

				value = value.replace("%"+placeHolder+"%", replacement)
			Next

			result.Set(value, lang)
		Next
	
		return result
	End Method
End Type