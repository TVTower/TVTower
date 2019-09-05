Rem
	====================================================================
	Class for handling application localization
	====================================================================

	Eases the process of localization.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import BRL.Retro
Import BRL.Map


Type TLocalization
	Global languages:TLocalizationLanguage[]
	Global languageIDMap:string[] '0="en", 1="de" ...
	Global currentLanguage:TLocalizationLanguage
	Global currentLanguageID:Int = -1
	Global defaultLanguage:TLocalizationLanguage
	Global defaultLanguageID:Int = -1
	Global languagesCount:int = 0


	Function GetStringWithParams:string(Key:string, group:string = Null, params:string[] = null)
		if params = null then Return GetString(Key, group)

		local result:string = GetString(Key, group)
		For local i:int = 0 until Len(params)
			result = result.replace("%"+(i+1), params[i])
		Next
		Return result
	End Function


	'Returns the value for the specified key, or the given key if
	'nothing was found
	Function GetString:String(Key:String, group:String = Null)
		'skip "has"-check without a default
		if not defaultLanguage
			if not currentLanguage then Return Key
		elseif defaultLanguage <> currentLanguage
			if currentLanguage.Has(Key, group)
				Return currentLanguage.Get(Key, group).replace("\n", Chr(13))
			else
				Return defaultLanguage.Get(Key, group).replace("\n", Chr(13))
			endif
		endif

		Return currentLanguage.Get(Key, group).replace("\n", Chr(13))
	End Function


	'Returns the value for the specified key, or the given key if
	'nothing was found
	Function GetLocalizedString:TLocalizedString(Key:String, group:String = Null)
		local ls:TLocalizedString = new TLocalizedString
		For local i:int = 0 until languages.length
			ls.Set(languages[i].Get(Key, group).replace("\n", Chr(13)), i)
		Next

		return ls
	End Function


	Function GetRandomString2:String(Keys:String[], limit:int=-1)
		'skip "has"-check without a defaultLanguage
		if not defaultLanguage
			if not currentLanguage
				if Keys.length > 0 then Return Keys[0]
				Return ""
			endif
		elseif defaultLanguage <> currentLanguage
			'check if current language offers something, if not
			'fall back to defaultLanguage
			local hasOne:int = False
			for local k:string = EachIn Keys
				if currentLanguage.HasSub(k) then hasOne = true;exit
			next
			if hasOne
				Return _GetRandomString2(currentLanguage, Keys)
			else
				Return _GetRandomString2(defaultLanguage, Keys)
			endif
		endif
		Return _GetRandomString2(currentLanguage, Keys)
	End Function


	Function GetRandomString:String(Key:String, limit:int=-1)
		'skip "has"-check without a defaultLanguage
		if not defaultLanguage
			if not currentLanguage then Return Key
		elseif defaultLanguage <> currentLanguage
			if currentLanguage.HasSub(Key)
				Return _GetRandomString(currentLanguage, Key)
			else
				Return _GetRandomString(defaultLanguage, Key)
			endif
		endif

		Return _GetRandomString(currentLanguage, Key)
	End Function



	'Returns the value for the specified key, or the given key if
	'nothing was found
	Function GetRandomLocalizedString:TLocalizedString(Key:String, group:String = Null)
		local ls:TLocalizedString = new TLocalizedString
		For local i:int = 0 until languages.length
			'skip default ones
			local res:string = _GetRandomString(languages[i], Key)
			if res = key then continue
			ls.Set(res.replace("\n", Chr(13)), i)
		Next

		return ls
	End Function


	Function _GetRandomString:string(language:TLocalizationLanguage, key:string, limit:int=-1)
		if not language then return key

		local availableStrings:int = 1
		local subKey:string = ""
		Repeat
			subKey = Key
			if availableStrings > 0 then subKey :+ availableStrings
			if language.Get(subKey) <> subKey
				availableStrings :+1
				continue
			endif

			if availableStrings = 1
				return language.Get(Key).replace("\n", Chr(13))
			else
				return language.Get(Key + Rand(1, availableStrings-1)).replace("\n", Chr(13))
			endif
		Forever
	End Function


	Function _GetRandomString2:string(language:TLocalizationLanguage, keys:string[], limit:int=-1)
		if not language
			if keys.length > 0 then return keys[0]
			return ""
		endif

		local availableStrings:string[]
		local subKey:string
		for local k:string = EachIn keys
			local availableSubKeys:int = 0
			local foundEntry:int =  False
			Repeat
				subKey = k
				'append a number except for first
				if availableSubKeys > 0 then subKey :+ availableSubKeys
				if language.Get(subKey) <> subKey
					availableSubKeys :+1
					availableStrings :+ [subKey]
					continue
				else
					'stop searching if nothing was found for this "key+number"
					if availablesubKeys > 0 then exit
				endif


				availableSubKeys :+ 1
			Forever
		Next

		'found no more entries
		if availableStrings.length > 0
			if availableStrings.length = 1
				return language.Get(availableStrings[0]).replace("\n", Chr(13))
			else
				return language.Get(availableStrings[Rand(0, availableStrings.length-1)]).replace("\n", Chr(13))
			endif
		endif

		if keys.length > 0
			return keys[0]
		else
			return ""
		endif
	End Function


	Function GetLanguage:TLocalizationLanguage(languageCode:string)
		for local l:TLocalizationLanguage = EachIn languages
			if l.languageCode = languageCode then return l
		next
		return null
	End Function


	Function AddLanguage:int(language:TLocalizationLanguage)
		if not GetLanguage(language.languageCode)
			languagesCount :+ 1
			languages :+ [language]
			languageIDMap :+ [language.languageCode]
		endif
	End Function


	Function GetLanguageID:int(languageCode:string)
		for local i:int = 0 until languageIDMap.length
			if languageIDMap[i] = languageCode then return i
		next
		return -1
	End Function


	Function GetLanguageCode:String(languageID:Int)
		if languages.length < languageID then return ""
		return languages[languageID].languageCode
	End Function


	Function SetDefaultLanguage:Int(languageCode:String)
		local lang:TLocalizationLanguage = GetLanguage(languageCode)

		if lang
			defaultLanguage = lang
			Return True
		else
			Return False
		endif
	End Function


	'Returns the current language
	Function GetDefaultLanguageCode:String()
		if defaultLanguage then return defaultLanguage.languageCode
		return ""
	End Function


	Function SetCurrentLanguage:Int(languageCode:String)
		local langID:Int = GetLanguageID(languageCode)
		if langID >= 0
			currentLanguage = languages[langID]
			currentLanguageID = langID

			Return True
		else
			Return False
		endif
	End Function


	'Returns the current language
	Function GetCurrentLanguageCode:String()
		if currentLanguage then return currentLanguage.languageCode
		return ""
	End Function


	Function GetCurrentLanguageID:Int()
		return currentLanguageID
	End Function


	Function LoadLanguageFile(file:String, languageCode:string="")
		AddLanguage(TLocalizationLanguage.Create(file))
	End Function


	'Loads all resource files according to the filter (for example: myfile*.txt will load myfile_en.txt, myfile_de.txt etc.)
	Function LoadLanguageFiles(filter:String)
		For Local file:String = EachIn GetLanguageFiles(filter)
			LoadLanguageFile(file)
		Next
	End Function


	'Detects the language of a resource file
	Function GetLanguageCodeFromFilename:String(filename:String)
		Local lastpos:Int = 0
		Local Pos:Int = Instr(filename, "_")

		'Look for the last occurence of "_"
		While Pos > 0
			lastpos = Pos
			Pos = Instr(filename, "_", lastpos + 1)
		Wend

		If lastpos > 0
			Pos = Instr(filename, "_", lastpos + 1)
			If Pos > 0 then Return Mid(filename, lastpos + 1, Pos - lastpos - 1)

			Pos = Instr(filename, ".", lastpos + 1)
			If Pos > 0 then Return Mid(filename, lastpos + 1, Pos - lastpos - 1)

			Return Mid(filename, lastpos + 1)
		EndIf

		Return Null
	End Function


	'Returns all language files according to the filter
	Function GetLanguageFiles:TList(filter:String)
		Local ret:TList = New TList
		Local Pos:Int = Instr(filter, "*")

		If Pos > 0

			Local prefix:String = Left(filter, Pos - 1)
			Local suffix:String = Mid(filter, Pos + 1)

			Local dir:String = ExtractDir(filter)
			Local dir_content:String[] = LoadDir(dir)

			prefix = Mid(prefix, dir.length + 1)
			If Left(prefix, 1) = "/" Or Left(prefix, 1) = "\" Then prefix = Mid(prefix, 2)

			For Local file:String = EachIn dir_content
				If file.length >= prefix.length and Left(file, prefix.length) = prefix
					If file.length >= prefix.length + suffix.length and Right(file, suffix.length) = suffix
						ret.AddLast(dir + "/" + file)
					EndIf
				EndIf
			Next
		EndIf

		Return ret
	End Function


	Function PrintCurrentTranslationState(compareLang:string="tr")
		'DE contains everythign
		local master:TLocalizationLanguage = GetLanguage("de")
		local compare:TLocalizationLanguage = GetLanguage(compareLang)

		print "=== LANGUAGE FILES ============="
		print "AVAILABLE:"
		print "----------"
		for local k:string = EachIn master.map.Keys()
			if compare.Get(k) = k then continue

			print master.languageCode+" |"+ k + " = " +master.Get(k)
			print compare.languageCode+" |"+ k + " = " +compare.Get(k)
			print Chr(8203) 'zero width space, else it skips "~n"
		Next
		print "~t"
		print "MISSING:"
		print "--------"
		for local k:string = EachIn master.map.Keys()
			if compare.Get(k) <> k then continue

			print master.languageCode+" |"+ k + " = " +master.Get(k)
			print compare.languageCode+" |"+ k + " = "
			print Chr(8203) 'zero width space, else it skips "~n"
		Next

		print "================================"
	End Function


	'Releases all resources used by the localization class
	Function Dispose()
		languages = Null
		languageIDMap = Null
		currentLanguage = Null
		defaultLanguage = Null
		currentLanguageID = -1
		defaultLanguageID = -1
	End Function
End Type


'convenience helper function
Function GetLocale:string(key:string)
	return TLocalization.getString(key)
End Function


Function GetRandomLocale:string(baseKey:string)
	return TLocalization.GetRandomString(baseKey)
End Function

Function GetRandomLocale2:string(baseKeys:string[])
	return TLocalization.GetRandomString2(baseKeys)
End Function


Function GetLocalizedString:TLocalizedString(key:string)
	return TLocalization.GetLocalizedString(key)
End Function


Function GetRandomLocalizedString:TLocalizedString(key:string)
	return TLocalization.GetRandomLocalizedString(key)
End Function




Type TLocalizationLanguage
	Field map:TMap = CreateMap()
	Field languageCode:string = ""


	'Opens a resource file and loads the content into memory
	Function Create:TLocalizationLanguage(filename:String, languageCode:String = Null)
		If languageCode = Null
			languageCode = TLocalization.GetLanguageCodeFromFilename(filename)
			If not languageCode Then Throw "No language was specified for loading the resource file and the language could not be detected from the filename itself.~r~nPlease specify the language or use the format ~qname_language.extension~q for the resource files."
		EndIf


		Local lang:TLocalizationLanguage = New TLocalizationLanguage
		lang.languageCode = languageCode

		'load definitions
		Local content:string = LoadText(filename)
		Local line:string =""
		Local Key:String
		Local value:String
		Local Pos:Int = 0
		Local group:String = ""

		For line = EachIn content.Split(chr(10))
			'comments
			if Left(line, 2) = "//" then continue

			'groups
			If Left(line, 1) = "[" and Right(line, 1) = "]"
				group = Mid(line, 2, line.length - 2).Trim()
			EndIf

			Pos = Instr(line, "=")
			If Pos > 0
				Key = Left(line, Pos - 1).Trim()
				value = Mid(line, Pos + 1).Trim()
			EndIf

			'skip corrupt keys
			If Key = "" then continue

			'unescape + new line or tab
			value = value.replace("\\", "\").replace("\n", "~n").replace("\t", "~t")

			If group <> ""
				'insert as "groupname::key"
				lang.map.Insert(lower(group + "::" + Key), value)
				'insert as key if "key" was not defined before
				If not lang.map.ValueForKey(Key) Then lang.map.Insert(lower(Key), value)
			Else
				lang.map.Insert(lower(Key), value)
			EndIf
		Next
		Return lang
	End Function


	'Gets the value for the specified key
	Method Get:String(Key:String, group:String = Null)
		Local ret:Object

		If group Then key = group + "::" + Key

		ret = map.ValueForKey(lower(key))

		If ret = Null
			Return Key
		Else
			Return String(ret)
		EndIf
	End Method


	Method Has:int(key:string, group:String = Null)
		If group Then key = group + "::" + Key

		return map.Contains(lower(key))
	End Method


	'return amount of sub keys ("key" => "key1", "key2","key3")
	Method HasSub:int(key:string, group:string = Null)
		If group Then key = group + "::" + key
		key = lower(key)

		local availableStrings:int = 1
		local found:int = 0
		local subKey:string = ""
		repeat
			subKey = Key
			if availableStrings > 0 then subKey :+ availableStrings
			if map.Contains(subKey)
				availableStrings :+ 1
				found :+ 1
			elseif availableStrings <> 0
				exit
			endif
		until found > 10

		return availableStrings
	End Method
End Type




Type TLocalizedString
	'storing an individual ID array instead of a sparse array containing
	'all languages even if not set, allows to only store the "used"
	'translations.
	Field valueStrings:String[]
	Field valueLangIDs:Int[]
	'current value
	Field value:string {nosave}
	'boolean if the value was set (might still be "empty" on purpose)
	Field valueSet:Int = False {nosave}


	Method Copy:TLocalizedString()
		local c:TLocalizedString = New TLocalizedString

		c.valueStrings = self.valueStrings[ .. ]
		c.valueLangIDs = self.valueLangIDs[ .. ]
		c.value = self.value
		c.valueSet = self.valueSet

		return c
	End Method


	Method ToString:string()
		local r:string = ""
		For local i:int = 0 until valueLangIDs.length
			r :+ TLocalization.GetLanguageCode( valueLangIDs[i] ) + ": " + valueStrings[i] + "~n"
		Next
		return r
	End Method


	'to ease "setting" (mystring.set(value)) the language
	'comes after the value.
	Method Set:TLocalizedString(value:String, languageCodeID:Int = - 1)
		if languageCodeID = -1 then languageCodeID = TLocalization.currentLanguageID
		local langIndex:int = GetLanguageIndex(languageCodeID)

		'not added yet?
		if langIndex = -1
			valueStrings = valueStrings[.. valueStrings.length + 1]
			valueLangIDs = valueLangIDs[.. valueLangIDs.length + 1]

			langIndex = valueLangIDs.length - 1
			valueLangIDs[langIndex] = languageCodeID
		endif

		valueStrings[langIndex] = value

		if languageCodeID = TLocalization.currentLanguageID
			self.value = value
			self.valueSet = True
		endif
		return self
	End Method


	Method Get:String(languageCodeID:Int = -1, returnDefault:int = True)
		if languageCodeID = -1 then languageCodeID = TLocalization.currentLanguageID

		if not valueSet or languageCodeID <> TLocalization.currentLanguageID
			local langIndex:Int = GetLanguageIndex(languageCodeID)
			if langIndex >= 0
				value = valueStrings[langIndex]
			else
rem
				print "UNKNOWN LANGUAGE ID: " + languageCodeID +"   current="+TLocalization.currentLanguageID
				for local i:int = 0 until valueLangIDs.length
					print "   knowing: " + valueLangIDs[i] + " (" + TLocalization.GetLanguageCode(valueLangIDs[i])+")"
				next
endrem
				value = ""
			endif

			if not value and returnDefault
				local defaultIndex:Int = GetLanguageIndex(TLocalization.defaultLanguageID)
				if defaultIndex >= 0 and valueStrings.length <= defaultIndex
					value = valueStrings[TLocalization.defaultLanguageID]
				endif
			endif

			valueSet = True
		endif

		return value
	End Method


	Method Replace:TLocalizedString(source:string, replacement:string)
		For local i:int = 0 until valueStrings.length
			valueStrings[i] = valueStrings[i].replace(source, replacement)
		Next
		return self
	End Method


	Method ReplaceLocalized:TLocalizedString(source:string, replacement:TLocalizedString)
		For local i:int = 0 until valueStrings.length
			valueStrings[i] = valueStrings[i].replace(source, replacement.Get( valueLangIDs[i] ))
		Next
		return self
	End Method


	Method HasLanguageID:int(languageID:Int)
		For local i:int = EachIn valueLangIDs
			if i = languageID then return True
		Next
		return False
	End Method


	Method HasLanguageCode:int(languageCode:string)
		For local i:int = EachIn valueLangIDs
			if TLocalization.languages[ valueLangIDs[i] ].languageCode = languageCode then return True
		Next
		return False
	End Method


	Method GetFirstLanguageID:Int()
		if valueLangIDs.length = 0 then return -1
		return valueLangIDs[0]
	End Method


	Method GetFirstLanguageCode:string()
		if valueLangIDs.length = 0 then return ""
		return TLocalization.languages[ valueLangIDs[0] ].languageCode
	End Method


	Method GetLanguageIndex:Int(languageID:Int)
		For local i:int = 0 until valueLangIDs.length
			if valueLangIDs[i] = languageID then return i
		Next
		return -1
	End Method


	Method GetLanguageIDs:Int[]()
		return valueLangIDs
	End Method


	Method SerializeTLocalizedStringToString:string()
		local s:string = ""
		'save the locale code as the ID might differ on clients with
		'different installed locales

		'concencate all into one string
		'de::TextGerman::en::TextEnglish::...
		For local i:Int = 0 until valueLangIDs.length
			if s <> "" then s :+ "::"
			s :+ TLocalization.languages[ valueLangIDs[i] ].languageCode.replace("\","\\").replace(":", "\:")
			s :+ "::"
			s :+ valueStrings[i].replace("\","\\").replace(":", "\:")
		Next
		return s
	End Method


	Method DeSerializeTLocalizedStringFromString(text:String)
		local vars:string[] = text.split("::")
		local languageCode:string, value:string
		local mode:int = 0
		For local s:string = EachIn vars
			s = s.replace("\:", ":").replace("\\", "\")
			if mode = 0
				languageCode = s
				mode :+ 1
			else
				value = s
				mode = 0

				'translate language code back into the currently used
				'ID

				Set(value, TLocalization.GetLanguageID(languageCode))
			endif
		Next
	End Method


	Method Append:TLocalizedString(other:TLocalizedString)
		if other
			For local i:int = 0 until other.valueLangIDs.length
				'this might overwrite previous values of the same language
				Set(other.valueStrings[i], other.valueLangIDs[i])
			Next

			valueSet = False
		endif
		return self
	End Method
End Type