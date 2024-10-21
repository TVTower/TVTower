SuperStrict
Import Brl.Map
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.scriptexpression_ng.bmx"



'By default templatevariables use registered variables and expressions
'to fill in the corresponding data.
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
	
	
	Method HasVariable:Int(key:String, keyIsLowerCase:Int = False)
		If Not variables Then Return False
		
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
End Type
