SuperStrict
Import Brl.Map
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.scriptexpression.bmx"
Import "game.gameinformation.base.bmx" 'to access worldtime



'By default templatevariables use the registered variables and placeholders
'but also default ones via GetGameInformation(placeHolder.toLower(), "")
'to fill in the corresponding data.
'so when adding new placeholder-handlers, also check the gameinformation
'system if it is containing them already
Type TTemplateVariables
	'Variables are used to replace certain %KEYWORDS% in title or
	'description. They are stored as "%KEYWORD%"=>TLocalizedString (or "${KEYWORD}"=>TLocalizedString)
	Field variables:TMap
	'no need for a special "isValid" variable as we must have at least
	'a single language id (so length>0)
	Field variablesLanguagesIDs:Int[]
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
		variablesLanguagesIDs = Null
		variables.insert(key, obj)
	End Method


	Method GetVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True, useTime:Long = 0)
		key = key.toLower()

		local result:TLocalizedString
		if variables then result = TLocalizedString(variables.ValueForKey(key))

		'check parent
		if not result
			local parent:TTemplateVariables = GetParentTemplateVariables()
			if parent then result = parent.GetVariableString(key, defaultValue, createDefault)
		endif

		rem
		'WOULD CACHE EVERY REQUEST, not just variables requesting game
		'information. So "The city %STATIONMAP:RANDOMCITY%" would cache
		'for every followup "randomcity"-request in the text, not just
		'for variables referencing it

		'check gameinformation
		if not result and key.Find("%") >= 0
			local gameinformationResult:string = string(GetGameInformation(key.Replace("%", ""), ""))
			if gameinformationResult <> "UNKNOWN_INFORMATION"
				result = new TLocalizedString
				result.Set(gameinformationResult)
			endif
		endif
		endrem

		'only check if there was a variable set for the game information
		'cityname => %STATIONMAP:RANDOMCITY%, so only "cityname" contains
		'a random city then

		'check gameinformation or script expressions
		if result and (result.Get().Find("%") >= 0 or result.Get().Find("${") >= 0)
			local placeHolders:string[] = StringHelper.ExtractPlaceholdersCombined(result.Get(), True)
			local externalResult:string = result.Get()
			local replaced:int = False
			local replacedSomething:int = False
			for local placeHolder:string = EachIn placeHolders
				local replacement:string = ""
				local replaced:int = False
				if not replaced then replaced = ReplaceTextWithGameInformation(placeHolder, replacement, useTime)
				if not replaced then replaced = ReplaceTextWithScriptExpression(placeHolder, replacement)
				'replace if some content was filled in
				'if replaced then print "replacement " + replacement+"   result: "+ externalResult +"  =>  " + externalResult.replace("%"+placeHolder+"%", replacement)
				if replaced
					externalResult = externalResult.replace("%"+placeHolder+"%", replacement)
					externalResult = externalResult.replace("${"+placeHolder+"}", replacement)
					replacedSomething = True
				endif
			Next

			if replacedSomething
				result = new TLocalizedString
				result.Set(externalResult)
			endif
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
		For local langID:Int = EachIn localizedString.GetLanguageIDs()
			local values:string[] = localizedString.Get( langID ).split("|")
			maxRandom = max(maxRandom, values.length - 1)
		Next

		'decide which random portion we want
		local useRandom:int = RandRange(0, maxRandom)

		For local langID:Int = EachIn localizedString.GetLanguageIDs()
			local values:string[] = localizedString.Get( langID ).split("|")
			'if random index is bigger than the array, set the default
			'as resulting value for this language
			if values.length-1 < useRandom
				result.set(defaultValue, langID)
			else
				result.set(values[useRandom], langID)
			endif
		Next

		return result
	End Method
	
	
	Method GetVariablesLanguageIDs:int[]()
		If not variables then Return Null
		
		if not variablesLanguagesIDs or variablesLanguagesIDs.length = 0
			Local result:Int[] = new Int[10]
			Local count:Int = 0
			For local variableValue:TLocalizedString = EachIn variables.values()
				For local langID:Int = EachIn variableValue.GetLanguageIDs()
					If not MathHelper.InIntArray(langID, result)
						count :+ 1
						if result.length <= count then result = result[.. result.length + 5]
						result[count-1] = langID
					EndIf
				Next
			Next
			if result.length > count then result = result[.. count]
			
			variablesLanguagesIDs = result
		endif
		return variablesLanguagesIDs
	End Method


	'global debugReplace:int = False
	Method ReplacePlaceholders:TLocalizedString(text:TLocalizedString, useTime:Long = 0)
		local result:TLocalizedString = text.copy()

		'step 1: - collect all used language IDs
		'          - variant 1:
		'            - from templateVariable instance 
		'            - and from passed "text" TLocalizedString
		'              (so languages need to define the variables but not eg. "<title>")
		'          - variant 2:
		'            - only from passed "text" TLocalizedString
		'              (so languages need to define eg "<title>" but not the variables)
		'step 2: - for all these language IDs the placeholder replacement is done


		'step 1
		Local languageIDs:Int[]
		'variant 1
		If variables
			languageIDs = GetVariablesLanguageIDs()
			For local textLanguageID:Int = EachIn text.GetLanguageIDs()
				If not MathHelper.InIntArray(textLanguageID, languageIDs)
					languageIDs :+ [textLanguageID]
				EndIf
			Next
		Else
			languageIDs = text.GetLanguageIDs()
		EndIf
		'variant 2
		'languageIDs = text.GetLanguageIDs()


		'for each defined language we check for existent placeholders
		'which then get replaced by a random string stored in the
		'variable with the same name
'if debugReplace Then print "ReplacePlaceHolders()"
'if debugReplace 
'	if variables 
'		 print "  variable locales: " + GetVariablesLanguageIDs().length
'	else
'		 print "  variable locales: -"
'	endif

		'do it 20 times, this allows for placeholder definitions within
		'placeholders (at least some of them)!
		For local i:int = 0 until 20
'if debugReplace Then print "  loop "+Rset(i,2)
			local replacedPlaceholdersAllLang:int = 0
			For local langID:int = eachIn languageIDs 'text.GetLanguageIDs()
				local replacedPlaceholdersThisLang:int = 0
				'use result already (to allow recursive-replacement)
				local value:string = result.Get(langID)
				local placeHolders:string[] = StringHelper.ExtractPlaceholdersCombined(value)
'if debugReplace Then print "    langID=" + langID + "  value=" + LSet(value, 15) + "  placeholders="+placeHolders.length

				if placeHolders.length > 0
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
'if debugReplace Then print "      replacement: "+replacement.ToString().Replace("~n", "~~n")
							'if the parent stores this variable (too) then save
							'the placeholder there instead of the children
							'so other children could use the same placeholders
							'(if there is no parent then "self" is returned)
							local parent:TTemplateVariables = GetParentTemplateVariables()
							if parent and parent.GetVariableString(placeHolder, "", False)
								parent.AddPlaceHolderVariable(placeHolder, replacement)
							else
'print "added variable: " + placeHolder + " => " + replacement.Get()
								AddPlaceHolderVariable(placeHolder, replacement)
							endif
							'store the replacement in the value
							value = value.replace(placeHolder, replacement.Get(langID))
'if lang="de" then print "        replace: "+placeHolder+" => " + replacement.Get(lang)
							replacedPlaceholdersThisLang :+ 1
						endif
					Next
				endif
				result.Set(value, langID)
				'save maximum of replaced placeholders amongst all languages
				replacedPlaceholdersAllLang = Max(replacedPlaceholdersAllLang, replacedPlaceholdersThisLang)
'if debugReplace Then print "      result: " + result.ToString().Replace("~n", "~~n    ")
			Next

			'skip further checks (nothing was replaced this loop)
			if replacedPlaceholdersAllLang = 0 then exit
		Next


		'replace common placeholders (%worldtime:year% and so on)
		'loop over "text", but replace in "result"
		For local langID:int = EachIn text.GetLanguageIDs()
			local value:string = result.Get(langID)
			local placeHolders:string[] = StringHelper.ExtractPlaceholdersCombined(value, True)
			for local placeHolder:string = EachIn placeHolders
				local replacement:string = string(GetGameInformation(placeHolder.toLower(), "", null, useTime))
				if replacement <> "UNKNOWN_INFORMATION"
					value = value.replace("${"+placeHolder+"}", replacement)
				endif
			Next

			result.Set(value, langID)
		Next
'if debugReplace then print result.ToString().Replace("~n", "~~n")
		return result
	End Method
End Type