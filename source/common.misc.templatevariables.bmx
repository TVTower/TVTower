SuperStrict
Import Brl.Map
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.scriptexpression.bmx"
Import "game.gameinformation.base.bmx" 'to access worldtime



'By default templatevariables use the registered variables and placeholders
'but also default ones via GetGameInformation(placeholder.toLower(), "")
'to fill in the corresponding data.
'so when adding new placeholder-handlers, also check the gameinformation
'system if it is containing them already
Type TTemplateVariables
	'Variables are used to replace certain %KEYWORD%/${KEYWORD} in title or
	'description. They are stored as "KEYWORD"=>TLocalizedString
	Field variables:TMap
	'no need for a special "isValid" variable as we must have at least
	'a single language id (so length>0)
	Field variablesLanguagesIDs:Int[]
	'placeholderVariables contain TLocalizedString-objects which are used
	'to replace a specific placeholder. This allows to reuse the exact same
	'random variable for descendants (episodes refering to the same
	'keyword) instead of returning other random elements ("option1|option2")
	Field placeholderVariables:TMap

	'override this in CUSTOM variable types to return the parental TTemplateVariables
	Method GetParentTemplateVariables:TTemplateVariables()
		return null
	End Method
	
	
	Method CopyFrom:TTemplateVariables(v:TTemplateVariables)
		If Not v.variables 
			self.variables = Null
		Else
			self.variables = New TMap
			For local key:Object = EachIn v.variables.Keys()
				local ls:TLocalizedString = TLocalizedString(v.variables.ValueForKey(key))
				If not ls
					Throw "TTemplateVariables: Unsupported content in variables."
				EndIf
				self.variables.Insert(key, ls.Copy())
			Next
		EndIf

		If Not v.variablesLanguagesIDs
			self.variablesLanguagesIDs = Null
		Else
			self.variablesLanguagesIDs = v.variablesLanguagesIDs[ .. ]
		EndIf


		If Not v.placeholderVariables
			self.placeholderVariables = Null
		Else
			self.placeholderVariables = New TMap
			For local key:Object = EachIn v.placeholderVariables.Keys()
				local ls:TLocalizedString = TLocalizedString(v.placeholderVariables.ValueForKey(key))
				If not ls
					Throw "TTemplateVariables: Unsupported content in placeholderVariables."
				EndIf
				self.placeholderVariables.Insert(key, ls.Copy())
			Next
		EndIf
		Return Self
	End Method

	
	Method Copy:TTemplateVariables()
		local c:TTemplateVariables = New TTemplateVariables
		Return c.CopyFrom(self)
	End Method
		

	Method Reset()
		placeholderVariables = null
	End Method
	
	
	Method GetContentAsText:String()
		If Not variables Then Return ""
		
		Local result:TStringBuilder = new TStringBuilder()

		For local key:Object = EachIn variables.Keys()
			local v:Object = variables.ValueForKey(key)
			If TLocalizedString(v)
				result.appendLine(string(key)+"=>TLocalizedString")
			Else
				result.appendLine(string(key)+"=>~q"+string(v)+"~q")
			EndIf
		Next
		return result.ToString()
	End Method


	Method AddPlaceHolderVariable(key:string, obj:object)
		key = key.toLower()

		if not placeholderVariables then placeholderVariables = CreateMap()
		placeholderVariables.insert(key, obj)
	End Method


	'return a "multi language"-string for the given key/placeholder
	Method GetPlaceHolderVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True)
		key = key.toLower()

		local result:TLocalizedString
		if placeholderVariables 
			result = TLocalizedString(placeholderVariables.ValueForKey(key))
			'try old version with "%VAR%" tag
			if not result
				result = TLocalizedString(placeholderVariables.ValueForKey("%" + key + "%"))
			endif
		endif
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


	Method AddVariable(key:string, obj:object, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf
		if not variables then variables = CreateMap()
		variablesLanguagesIDs = Null
		variables.insert(key, obj)
	End Method
	
	
	Method GetVariableRawString:String(key:String, defaultValue:string = "", createDefault:int = True, useTime:Long = 0, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf
		
		Local result:String
		Local mapValue:Object
		If variables And variables.ValueForKey(key, mapValue)
			if TLocalizedString(mapValue)
				return TLocalizedString(mapValue).get()
			else
				result = string(mapValue)
			endif
		EndIf

		if not mapValue
			result = defaultValue
			if createDefault
				AddVariable(key, defaultValue, True)
			EndIf
		EndIf
		
		Return result
	End Method


	Method GetVariableString:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True, useTime:Long = 0, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf

		local result:TLocalizedString
		if variables 
			result = TLocalizedString(variables.ValueForKey(key))
			'try old version with "%VAR%" tag
			if not result
				result = TLocalizedString(variables.ValueForKey("%" + key + "%"))
			endif
		endif

		'check parent
		if not result
			local parent:TTemplateVariables = GetParentTemplateVariables()
			if parent then result = parent.GetVariableString(key, defaultValue, createDefault, useTime, True)
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
			local placeholders:string[] = StringHelper.ExtractPlaceholdersCombined(result.Get(), True)
			local externalResult:string = result.Get()
			local replaced:int = False
			local replacedSomething:int = False
			for local placeholder:string = EachIn placeholders
				local replacement:string = ""
				local replaced:int = False
				if not replaced then replaced = ReplaceTextWithGameInformation(placeholder, replacement, useTime)
				if not replaced then replaced = ReplaceTextWithScriptExpression(placeholder, replacement)
				'replace if some content was filled in
				'if replaced then print "replacement " + replacement+"   result: "+ externalResult +"  =>  " + externalResult.replace("%"+placeholder+"%", replacement)
				if replaced
					ReplacePlaceholderInText(externalResult, placeholder, replacement)
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


	'retrieve a TLocalizedString containing a single value per language
	'extracted from another TLocalizedString which contains a chain of
	'values per language ("ape|beaver|camel|dog" -> "beaver")
	'
	'limitElementsToChoseFrom:
	'	True : The language with the least random values limits from what to choose from
	'	False: languages with less random values will be filled with "MISSING"
	Method GetRandomFromLocalizedString:TLocalizedString(localizedString:TLocalizedString, limitElementsToChoseFrom:Int = True)
		Return localizedString.CopyRandom(limitElementsToChoseFrom, "MISSING")
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


	'replace "placeholder" with "replacement" in the given text/string
	Function ReplacePlaceholderInText:String(text:String var, placeholder:String, replacement:String)
		text = text.replace("%"+placeholder+"%", replacement)
		text = text.replace("${"+placeholder+"}", replacement)
	End Function
	
	

	'creates a TLocalizedString containing the final value of a variable in all languages
	Method GetFinalVariableContent:TLocalizedString(variable:String)
	End Method


	'replace all placeholders in the given TLocalizedString
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

		'do it 20 times, this allows for placeholder definitions within
		'placeholders (at least some of them)!
		For local i:int = 0 until 20
			local replacedPlaceholdersAllLang:int = 0
			'as base value for the next recursive round, copy the previous result
			'otherwise replacements in the "default language" would be used for other languages as well
			local langBaseCopy:TLocalizedString = result.copy()
			For local langID:int = eachIn languageIDs 'text.GetLanguageIDs()
				local replacedPlaceholdersThisLang:int = 0
				local value:string = langBaseCopy.Get(langID)
				local placeholders:string[] = StringHelper.ExtractPlaceholdersCombined(value, True)

				if placeholders.length > 0
					local replacement:TLocalizedString
					for local placeholder:string = EachIn placeholders
						'check if there is already a placeholder variable stored
						replacement = GetPlaceholderVariableString(placeholder, "", False)
						'check if the variable is defined (this leaves global
						'placeholders like %ACTOR% intact even without further
						'variable definition)
						if not replacement then replacement = GetVariableString(placeholder, "", False)
						'only use ONE option out of the group ("option1|option2|option3")
						if replacement
							replacement = GetRandomFromLocalizedString( replacement )

							'if the parent stores this variable (too) then save
							'the placeholder there instead of the children
							'so other children could use the same placeholders
							'(if there is no parent then "self" is returned)
							local parent:TTemplateVariables = GetParentTemplateVariables()
							if parent and parent.GetVariableString(placeholder, "", False)
								parent.AddPlaceHolderVariable(placeholder, replacement)
							else
								AddPlaceHolderVariable(placeholder, replacement)
							endif
							'store the replacement in the value
							ReplacePlaceholderInText(value, placeholder, replacement.Get(langID))
							replacedPlaceholdersThisLang :+ 1
						endif
					Next
				endif
				result.Set(value, langID)
				'save maximum of replaced placeholders amongst all languages
				replacedPlaceholdersAllLang = Max(replacedPlaceholdersAllLang, replacedPlaceholdersThisLang)
			Next

			'skip further checks (nothing was replaced this loop)
			if replacedPlaceholdersAllLang = 0 then exit
		Next


		'replace common placeholders (%worldtime:year% and so on)
		'loop over "text", but replace in "result"
		For local langID:int = EachIn text.GetLanguageIDs()
			local value:string = result.Get(langID)
			local placeholders:string[] = StringHelper.ExtractPlaceholdersCombined(value, True)
			for local placeholder:string = EachIn placeholders
				local replacement:string = string(GetGameInformation(placeholder.toLower(), "", null, useTime))
				if replacement <> "UNKNOWN_INFORMATION"
					ReplacePlaceholderInText(value, placeholder, replacement)
				endif
			Next

			result.Set(value, langID)
		Next

		return result
	End Method
End Type
