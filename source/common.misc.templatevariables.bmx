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
	'known languageIDs used in the variables-map
	'(length always >0 as at least 1 language id has to be set)
	Field variablesLanguagesIDs:Int[]

	'Variables are used to replace certain keywords in expressions
	'(like "${KEYWORD}") in a given text (eg. a script's title or description)
	'They can contain variations ("Ape|Beaver|Camel")
	'They are stored as "VARIABLE"=>TLocalizedString
	Field variables:TMap

	'Variables resolved already ("Camel" instead of "Ape|Beaver|Camel")
	'This allows to reuse the exact same random variable for descendants
	'(eg. episodes refering to the same variable) instead of returning
	'other random elements ("Ape|Beaver|Camel")
	'They are stored as "VARIABLE"=>TLocalizedString
	Field variablesResolved:TMap


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


		If Not v.variablesResolved
			self.variablesResolved = Null
		Else
			self.variablesResolved = New TMap
			For local key:Object = EachIn v.variablesResolved.Keys()
				local ls:TLocalizedString = TLocalizedString(v.variablesResolved.ValueForKey(key))
				If not ls
					Throw "TTemplateVariables: Unsupported content in variablesResolved."
				EndIf
				self.variablesResolved.Insert(key, ls.Copy())
			Next
		EndIf
		Return Self
	End Method

	
	Method Copy:TTemplateVariables()
		local c:TTemplateVariables = New TTemplateVariables
		Return c.CopyFrom(self)
	End Method
		

	Method Reset()
		variablesResolved = null
	End Method
	
	
	Method GetVariablesAsText:String()
		If Not variables Then Return ""
		
		Local result:TStringBuilder = new TStringBuilder()

		For local key:Object = EachIn variables.Keys()
			local v:TLocalizedString = TLocalizedString(variables.ValueForKey(key))
			if not v then continue
			result.appendLine(string(key)+"=>(" + v.ToString().Replace("~n", " // ") + ")")
		Next
		return result.ToString()
	End Method


	Method GetResolvedVariablesAsText:String()
		If Not variables Then Return ""
		
		Local result:TStringBuilder = new TStringBuilder()

		if variablesResolved
			For local key:Object = EachIn variablesResolved.Keys()
				local v:TLocalizedString = TLocalizedString(variablesResolved.ValueForKey(key))
				if not v then continue
				result.appendLine(string(key)+"=>(" + v.ToString().Replace("~n", " // ") + ")")
			Next
		EndIf
		return result.ToString()
	End Method


	Method AddResolvedVariable(key:string, obj:object, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf

		If not variablesResolved
			variablesResolved = CreateMap()
		EndIf

		variablesResolved.insert(key, obj)
	End Method

rem
	'return a "multi language"-string for the given key/variable
	'If instance does not contain it, a potential parent is asked.
	'This allows a shared parent to define values for the children.
	Method GetResolvedVariable:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf

		'search if individually resolved
		Local result:TLocalizedString
		If variablesResolved
			result = TLocalizedString(variablesResolved.ValueForKey(key))
		EndIf
		'a parent could have it resolved ("more generic")
		If Not result
			Local parent:TTemplateVariables = GetParentTemplateVariables()
			If parent
				result = parent.GetResolvedVariable(key, defaultValue, createDefault, keyIsLowerCase)
			EndIf
		EndIf

		If Not result And createDefault
			result = New TLocalizedString(defaultValue)
		endif
		return result
	End Method
endrem


	Method AddVariable(key:string, obj:object, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf
		if not variables then variables = CreateMap()
		variablesLanguagesIDs = Null
		
		'remove a previously resolved one IF the added one already
		'exists and DIFFERS to the new one
		If self.variablesResolved and self.variablesResolved.Contains(key)
			Local oldObj:Object = variables.ValueForKey(obj)
			If oldObj <> obj
				self.variablesResolved.Remove(key)
			EndIf
		EndIf
		
		variables.insert(key, obj)
	End Method
	
rem
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
endrem


	Method HasVariable:Int(key:String, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf
		Return variables.Contains(key)
	End Method
	


	'Return the TLocalizedString placed for the given variable / key 
	Method GetVariable:TLocalizedString(key:String, defaultValue:string = "", addDefaultIfMissing:int = True, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf
		
		Local value:TLocalizedString
		If variables 
			value = TLocalizedString(variables.ValueForKey(key))
		EndIf

		'in case of "null" we check if the key exists at all
		'and if not, create one with the default value 
		'(and add the variable if allowed)
		if not value and variables.Contains(key)
			value = New TLocalizedString(defaultValue)
		
			if addDefaultIfMissing
				AddVariable(key, value, True)
			EndIf
		EndIf
		
		Return value
	End Method
	
	
	Method GetResolvedVariable:TLocalizedString(key:String, useTime:Long = 0, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf
		
		Local result:TLocalizedString
		
		'already resolved?
		If variablesResolved 
			result = TLocalizedString(variablesResolved.ValueForKey(key))
		EndIf	
		If not result
			local parent:TTemplateVariables = GetParentTemplateVariables()
			If parent
				result = parent.GetResolvedVariable(key, useTime, True)
			EndIf
		EndIf

		'need to resolve now?
		If not result
			'only resolve for the instance knowing the variable
			'prioritize "parents" if they know the variable too as this
			'will mean other children do not need to resolve then
			If not HasVariable(key, True)
				local parent:TTemplateVariables = GetParentTemplateVariables()
				If parent and parent.HasVariable(key, True)
					result = parent.ResolveVariable(key, useTime)
				EndIf

			Else
				result = self.ResolveVariable(key, useTime)
			EndIf			
			
			'if result is now null then parent failed to resolve and self
			'did not contain the variable
		EndIf
		
		Return result
	End Method
	
	
	Method ResolveVariable:TLocalizedString(keyLower:String, useTime:Long = 0)
		'select one of the choices in the variable (eg. "Ape|Beaver|Camel")
		'and store it as resolved variable too, so on next request this
		'same resolved one is returned)
		
		If Not HasVariable(keyLower, True)
			Return Null
		EndIf

		Local result:TLocalizedString = GetVariable(keyLower, "", False, True).CopyRandom()
		AddResolvedVariable(keyLower, result)

		return result
	End Method


	Method GetVariableString_DEPRECATED:TLocalizedString(key:string, defaultValue:string="", createDefault:int = True, useTime:Long = 0, keyIsLowerCase:Int = False)
		If Not keyIsLowerCase 
			key = key.toLower()
		EndIf

		local result:TLocalizedString
		if variables 
			result = TLocalizedString(variables.ValueForKey(key))
		endif

		'check parent
		if not result
			local parent:TTemplateVariables = GetParentTemplateVariables()
			if parent then result = parent.GetVariableString_DEPRECATED(key, defaultValue, createDefault, useTime, True)
		endif

		'rem
		'WOULD CACHE EVERY REQUEST, not just variables requesting game
		'information. So "The city %STATIONMAP:RANDOMCITY%" would cache
		'for every followup "randomcity"-request in the text, not just
		'for variables referencing it

		'check gameinformation
		'if not result and key.Find("%") >= 0
		'	local gameinformationResult:string = string(GetGameInformation(key.Replace("%", ""), ""))
		'	if gameinformationResult <> "UNKNOWN_INFORMATION"
		'		result = new TLocalizedString
		'		result.Set(gameinformationResult)
		'	endif
		'endif
		'endrem

		'only check if there was a variable set for the game information
		'cityname => %STATIONMAP:RANDOMCITY%, so only "cityname" contains
		'a random city then

		'check gameinformation or script expressions
		if result
			local t:String = result.Get()
			
			if (t.Find("%") >= 0 or t.Find("${") >= 0)
				local placeholders:string[] = StringHelper.ExtractPlaceholdersCombined(t, True)
				local externalResult:string = t
				local replaced:int = False
				local replacedSomething:int = False
				for local placeholder:string = EachIn placeholders
					local replacement:string = ""
					replaced = False
					if not replaced then replaced = ReplaceTextWithGameInformation(placeholder, replacement, useTime)
					if not replaced then replaced = ReplaceTextWithScriptExpression(placeholder, replacement)
					'replace if some content was filled in
					'if replaced then print "replacement " + replacement+"   result: "+ externalResult +"  =>  " + externalResult.replace("%"+placeholder+"%", replacement)
					if replaced
						ReplacePlaceholderInText_DEPRECATED(externalResult, placeholder, replacement)
						replacedSomething = True
					endif
				Next

				if replacedSomething
					result = new TLocalizedString
					result.Set(externalResult)
				endif
			EndIf
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
	Function ReplacePlaceholderInText_DEPRECATED:String(text:String var, placeholder:String, replacement:String)
		text = text.replace("%"+placeholder+"%", replacement)
		text = text.replace("${"+placeholder+"}", replacement)
	End Function
	
	

	'replace all placeholders in the given TLocalizedString
	Method ReplacePlaceholders_DEPRECATED:TLocalizedString(text:TLocalizedString, useTime:Long = 0)
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
						'replacement = GetResolvedVariable(placeholder, "", False)
						replacement = GetResolvedVariable(placeholder, usetime, False)
						'check if the variable is defined (this leaves global
						'placeholders like %ACTOR% intact even without further
						'variable definition)
						if not replacement then replacement = GetVariableString_DEPRECATED(placeholder, "", False)
						'only use ONE option out of the group ("option1|option2|option3")
						if replacement
							replacement = GetRandomFromLocalizedString( replacement )

							'if the parent stores this variable (too) then save
							'the placeholder there instead of the children
							'so other children could use the same placeholders
							'(if there is no parent then "self" is returned)
							local parent:TTemplateVariables = GetParentTemplateVariables()
							if parent and parent.GetVariableString_DEPRECATED(placeholder, "", False)
								parent.AddResolvedVariable(placeholder, replacement)
							else
								AddResolvedVariable(placeholder, replacement)
							endif
							'store the replacement in the value
							ReplacePlaceholderInText_DEPRECATED(value, placeholder, replacement.Get(langID))
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
					ReplacePlaceholderInText_DEPRECATED(value, placeholder, replacement)
				endif
			Next

			result.Set(value, langID)
		Next

		return result
	End Method
End Type
