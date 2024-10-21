Rem
	====================================================================
	Class for handling application localization
	====================================================================

	Eases the process of localization.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2024 Ronny Otto, digidea.de

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
Import "base.util.directorytree.bmx"
Import "base.util.mersenne.bmx"
Import "base.util.string.bmx"


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


	'Returns true if one of the languages contains the key
	'nothing was found
	Function HasString:Int(Key:String, group:String = Null)
		if currentLanguage and currentLanguage.Has(key, group)
			Return True
		EndIf
		if defaultLanguage and defaultLanguage.Has(key, group)
			Return True
		EndIf
		Return False
	End Function


	'Returns the value for the specified key, or the given key if
	'nothing was found
	Function GetString:String(Key:String, group:String = Null, useLanguage:TLocalizationLanguage = Null)
		if not useLanguage Then useLanguage = currentLanguage
		
		'skip "has"-check without a default
		if not defaultLanguage
			if not useLanguage then Return Key
		elseif defaultLanguage <> useLanguage
			if useLanguage.Has(Key, group)
				Return useLanguage.Get(Key, group).replace("\n", Chr(13))
			else
				Return defaultLanguage.Get(Key, group).replace("\n", Chr(13))
			endif
		endif

		If Not useLanguage Then Return ""
		Return useLanguage.Get(Key, group).replace("\n", Chr(13))
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


		local keyLower:String = key.ToLower()
		local hasMain:Int = language.HasRaw(keyLower)
		local availableAlternatives:Int = 0
		local subKey:string = ""

		Repeat
			subKey = keyLower + (availableAlternatives + 1)

			'alternative existing?
			if language.HasRaw(subKey)
				availableAlternatives :+ 1
				continue
			endif
			
			exit
		Forever

		if hasMain
			if availableAlternatives = 0
				return language.GetRaw(keyLower).replace("\n", Chr(13))
			else
				local index:int = RandRange(0, availableAlternatives)
				if index = 0
					return language.GetRaw(keyLower).replace("\n", Chr(13))
				else
					return language.GetRaw(keyLower + index).replace("\n", Chr(13))
				endif
			endif
		else
			if availableAlternatives = 0
				return key
			else
				return language.GetRaw(keyLower + (1 + RandRange(0, availableAlternatives-1))).replace("\n", Chr(13))
			endif
		endif
	End Function


	Function _GetRandomString2:string(language:TLocalizationLanguage, keys:string[], limit:int=-1)
		if not language
			if keys.length > 0 then return keys[0]
			return ""
		endif

		local availableStrings:string[4]
		local availableStringsCount:int = 0
		local subKey:string

		for local k:string = EachIn keys
			local availableSubKeys:int = 0
			local foundEntry:int =  False
			local kLS:string = k.ToLower()
			

			Repeat
				'append a number except for first
				if availableSubKeys > 0 
					subKey = kLS + availableSubKeys
				else
					subKey = kLS
				endif
				if language.HasRaw(subKey)
					availableSubKeys :+1
					availableStringsCount :+ 1
					if availableStrings.length <= availableSubKeys
						availableStrings = availableStrings[.. availableStrings.length + 4]
					endif
					availableStrings[availableStringsCount-1] = subKey
					continue
				else
					'stop searching if nothing was found for this "key+number"
					if availableSubKeys > 0 then exit
				endif

				availableSubKeys :+ 1
			Forever
		Next

		'found no more entries
		if availableStringsCount > 0
			if availableStringsCount = 1
				return language.GetRaw(availableStrings[0]).replace("\n", Chr(13))
			else
				return language.GetRaw(availableStrings[RandRange(0, availableStringsCount-1)]).replace("\n", Chr(13))
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
		if languages.length < languageID or languageID < 0 then return ""
		return languages[languageID].languageCode
	End Function


	Function SetDefaultLanguage:Int(languageCode:String)
		local langID:Int = GetLanguageID(languageCode)
		if langID >= 0
			defaultLanguage = languages[langID]
			defaultLanguageID = langID

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


	Function LoadLanguageURI(uri:String, languageCode:string="")
		AddLanguage(TLocalizationLanguage.Create(uri, languageCode))
	End Function
	
	
	Function LoadLanguages(baseDirectory:String)
		Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit()
		dirTree.ScanDir(baseDirectory, True)
		For Local directory:String = EachIn dirTree.GetDirectories()
			TLocalization.LoadLanguageFiles(directory+"/*.txt")
		Next
	End Function


	'Loads all resource files according to the filter (for example: myfile*.txt will load myfile_en.txt, myfile_de.txt etc.)
	Function LoadLanguageFiles(filter:String)
		For Local file:String = EachIn GetLanguageFiles(filter)
			LoadLanguageURI(file)
		Next
	End Function


	Function LoadLanguageDirectories(baseDirectory:String)
		'load in all files from the directory and subdirectories
		Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit()
		dirTree.SetIncludeFileEndings(Null)
		dirTree.SetExcludeFileNames(["*"])
		dirTree.ScanDir(baseDirectory, True)

		For Local directory:String = EachIn dirTree.GetDirectories()
			LoadLanguageURI(directory)
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
Function HasLocale:Int(key:string)
	return TLocalization.HasString(key)
End Function

'convenience helper function
Function GetLocale:string(key:string)
	return TLocalization.GetString(key)
End Function

'convenience helper function
Function GetLocale:string(key:string, language:TLocalizationLanguage)
	return TLocalization.GetString(key, Null, language)
End Function

'convenience helper function
Function GetLocale:string(key:string, languageCode:String)
	return TLocalization.GetString(key, Null, TLocalization.GetLanguage(languageCode))
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
	Function Create:TLocalizationLanguage(uri:String, languageCode:String = Null)
		Local lang:TLocalizationLanguage
		
		local filesToLoad:String[]
		Select FileType(uri)
			Case FILETYPE_FILE
				filesToLoad = [uri]

				If languageCode = Null
					languageCode = TLocalization.GetLanguageCodeFromFilename(uri)
					If not languageCode Then Throw "No language was specified for loading the resource file and the language could not be detected from the filename itself.~r~nPlease specify the language or use the format ~qname_language.extension~q for the resource files."
				EndIf

			Case FILETYPE_DIR
				'load in all files from the directory and subdirectories
				Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit()
				dirTree.SetIncludeFileEndings(["txt"])
				'skip some special readme file?
				'dirTree.SetExcludeFileNames(["_readme"])
				dirTree.ScanDir(uri, True)

				filesToLoad = dirTree.GetFiles()

				If languageCode = Null
					languageCode = StripAll(uri)
				EndIf

			Default
				'no language to load
				Print "File/Folder ~q" + uri + "~q not found."
				Return Null
		End Select

		'extend existing?
		if languageCode
			lang = TLocalization.GetLanguage(languageCode)
		EndIf
		If not lang
			lang = New TLocalizationLanguage
			lang.languageCode = languageCode
		endif
		
		
		For local fileToLoad:String = EachIn filesToLoad
			'load definitions
			Local content:string = LoadText(fileToLoad)
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
		Next

		Return lang
	End Function


	'Gets the value for the specified key
	Method Get:String(Key:String, group:String = Null)
		Local ret:Object

		If group Then key = group + "::" + Key
		key = lower(key)

		ret = map.ValueForKey(key)

		If ret = Null 'empty strings or not existing?
			If not HasRaw(key) Then Return Key
			Return ""
		Else
			Return String(ret)
		EndIf
	End Method


	'Gets the value for the specified key
	Method GetRaw:String(Key:String, group:String = Null)
		Local ret:Object

		If group Then key = group + "::" + Key

		ret = map.ValueForKey(key)

		If ret = Null 'empty strings or not existing?
			If not HasRaw(key) Then Return Key
			Return ""
		Else
			Return String(ret)
		EndIf
	End Method


	Method Has:int(key:string, group:String = Null)
		If group Then key = group + "::" + Key

		return map.Contains(lower(key))
	End Method


	Method HasRaw:int(key:string)
		return map.Contains(key)
	End Method


	'return amount of sub keys ("key" => "key1", "key2","key3")
	Method HasSub:int(key:string, group:string = Null)
		If group Then key = group + "::" + key
		key = lower(key)

		local availableStrings:int = 0
		local found:int = 0
		local subKey:string = ""
		repeat
			subKey = Key
			if availableStrings > 0 then subKey :+ availableStrings
			if map.Contains(subKey)
				found :+ 1
			elseif availableStrings <> 0
				exit
			endif
			availableStrings :+ 1
		until found > 10

		return found
	End Method
End Type




Type TLocalizedString
	'storing an individual ID array instead of a sparse array containing
	'all languages even if not set, allows to only store the "used"
	'translations.
	Field valueStrings:String[]
	Field valueLangIDs:Int[]
	'current value
	Field valueCached:string {nosave}
	'language of the current value (which might still be "empty" on purpose)
	Field valueCachedLanguageID:Int = -1 {nosave}
	'cache for calculated "random groups" sizes amongst the languages ("ape|beaver|camel|"
	Field _maxRandomValues:Short = 0 {nosave}
	Field _minRandomValues:Short = 0 {nosave}
	

	Method New(s:String)
		Set(s, -1)
	End Method


	Method Copy:TLocalizedString()
		local c:TLocalizedString = New TLocalizedString

		c.valueStrings = self.valueStrings[ .. ]
		c.valueLangIDs = self.valueLangIDs[ .. ]
		c.valueCached = self.valueCached
		c.valueCachedLanguageID = self.valueCachedLanguageID

		return c
	End Method


	Method ToString:string()
		local r:string = ""
		For local i:int = 0 until valueLangIDs.length
			r :+ TLocalization.GetLanguageCode( valueLangIDs[i] ) + ": ~q" + valueStrings[i] + "~q~n"
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
		
		'invalidate variants count cache
		'(gets recalulated if required in GetRandom())
		_minRandomValues = 0
		_maxRandomValues = 0

		'refresh cache
		if languageCodeID = valueCachedLanguageID
			self.valueCached = value
		endif
		return self
	End Method


	Method Get:String(languageCodeID:Int = -1, returnDefault:int = True)
		if languageCodeID = -1 then languageCodeID = TLocalization.currentLanguageID

		'not cached yet?
		if valueCachedLanguageID <> languageCodeID
			local langIndex:Int = GetLanguageIndex(languageCodeID)
			local result:String

			'fetch value
			if langIndex >= 0
				result = valueStrings[langIndex]
rem
			else
				print "UNKNOWN LANGUAGE ID: " + languageCodeID +"   current="+TLocalization.currentLanguageID
				for local i:int = 0 until valueLangIDs.length
					print "   knowing: " + valueLangIDs[i] + " (" + TLocalization.GetLanguageCode(valueLangIDs[i])+")"
				next
endrem
			endif
			if not result and returnDefault
				'fetch value of "default language" if possible
				'but if it is not defined, try to use the first possible
				'value
				local defaultIndex:Int = GetLanguageIndex(TLocalization.defaultLanguageID)
				If defaultIndex < 0 Then defaultIndex = valueStrings.length -1
				
				if defaultIndex >= 0
					result = valueStrings[defaultIndex]
				endif
			endif

			valueCachedLanguageID = languageCodeID
			valueCached = result
		endif

		return valueCached
	End Method




	'Create a new TLocalizedString only containing a single value per
	'language extracted from a chain of values per language
	'("ape|beaver|camel|dog" -> "beaver")
	Method CopyRandom:TLocalizedString(limitElementsToChoseFrom:Int = True, defaultValue:string = "MISSING")
		'loop through languages and calculate maximum amount of
		'random values -> this gets our "reference count" if something
		'is missing
		If _minRandomValues = 0 or _maxRandomValues = 0
			_minRandomValues = 1
			_maxRandomValues = 1
			For local langID:Int = EachIn self.GetLanguageIDs()
				Local value:String = self.Get( langID )
				Local randomValues:Short = 1 'at least one is always there
				For local i:int = 0 until value.length
					if value[i] = Asc("|")
						randomValues :+ 1
					EndIf
				Next
				
				If _minRandomValues = 1 or randomValues < _minRandomValues
					_minRandomValues = randomValues
				EndIf
				If _maxRandomValues < randomValues
					_maxRandomValues = randomValues
				EndIf
			Next
		EndIf


		'is there even a choice to make?
		If _maxRandomValues > 1 
			Local result:TLocalizedString = new TLocalizedString
			'decide which random portion we want
			local useRandom:int
			if limitElementsToChoseFrom
				useRandom = RandRange(0, _minRandomValues - 1)
			Else
				useRandom = RandRange(0, _maxRandomValues - 1)
			EndIf

			For local langID:Int = EachIn GetLanguageIDs()
				'iterate over the values elements until the desired element
				'is found or end of string reached
				Local value:String = Get( langID )
				Local randomElementNumber:int
				Local lastSplitterPos:Int = -1
				Local foundValue:Int
				For local i:int = 0 to value.length 'so +1 after string end
					'end reached or splitter found?
					If i = value.length or value[i] = Asc("|")
						If randomElementNumber = useRandom
							'eg the string is just "|", so 0th and 1st element
							'are both "" (empty)
							If (i - lastSplitterPos) <= 0
								result.set("", langID)
							Else
								result.set(value[lastSplitterPos+1 .. i], langID)
							EndIf
							foundValue = True
							exit 'done looping over this locale's string
						EndIf
						randomElementNumber :+ 1
						lastSplitterPos = i
					EndIf
				Next
				'if random index is bigger than the amount of options for
				'this locale, set the default as resulting value for this
				'language
				If not limitElementsToChoseFrom and Not foundValue
					result.set(defaultValue, langID)
				EndIf
			Next
			
			Return result
		Else
			Return self.Copy()
		EndIf

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


	Method GetLanguageID:int(languageCode:string)
		For local i:int = EachIn valueLangIDs
			if TLocalization.languages[ valueLangIDs[i] ].languageCode = languageCode then return i
		Next
		return -1
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
	
	
	Method GetLanguageCodes:String[]()
		Local codes:String[] = new String[valueLangIDs.length]
		Local langCount:Int
		For local i:int = EachIn valueLangIDs
			local code:String = TLocalization.GetLanguageCode(i)
			if code
				codes[langCount] = code
				langCount :+ 1
			endif
		Next
		if langCount <> codes.length Then codes = codes[.. langCount]
		Return codes
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

			valueCachedLanguageID = -1
		endif
		return self
	End Method
	
	
	Method UCFirstAllEntries()
		For local i:int = EachIn valueLangIDs
			Set(StringHelper.UCFirst(Get(i), i))
		Next
	End Method
End Type
