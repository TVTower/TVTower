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
	Global currentLanguage:TLocalizationLanguage
	Global fallbackLanguage:TLocalizationLanguage
	Global languages:TMap = CreateMap()
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
		'skip "has"-check without a fallback
		if not fallbackLanguage
			if not currentLanguage then Return Key
		elseif fallbackLanguage <> currentLanguage
			if currentLanguage.Has(Key, group)
				Return currentLanguage.Get(Key, group).replace("\n", Chr(13))
			else
				Return fallbackLanguage.Get(Key, group).replace("\n", Chr(13))
			endif
		endif

		Return currentLanguage.Get(Key, group).replace("\n", Chr(13))
	End Function


	'Returns the value for the specified key, or the given key if
	'nothing was found
	Function GetLocalizedString:TLocalizedString(Key:String, group:String = Null)
		local ls:TLocalizedString = new TLocalizedString
		For local lang:TLocalizationLanguage = EachIn languages.Values()
			ls.Set(lang.Get(Key, group).replace("\n", Chr(13)), lang.languageCode)
		Next

		return ls
	End Function


	Function GetRandomString2:String(Keys:String[], limit:int=-1)
		'skip "has"-check without a fallback
		if not fallbackLanguage
			if not currentLanguage
				if Keys.length > 0 then Return Keys[0]
				Return ""
			endif
		elseif fallbackLanguage <> currentLanguage
			'check if current language offers something, if not
			'fall back to fallbackLanguage
			local hasOne:int = False
			for local k:string = EachIn Keys
				if currentLanguage.HasSub(k) then hasOne = true;exit
			next
			if hasOne
				Return _GetRandomString2(currentLanguage, Keys)
			else
				Return _GetRandomString2(fallbackLanguage, Keys)
			endif
		endif
		Return _GetRandomString2(currentLanguage, Keys)
	End Function
	

	Function GetRandomString:String(Key:String, limit:int=-1)
		'skip "has"-check without a fallback
		if not fallbackLanguage
			if not currentLanguage then Return Key
		elseif fallbackLanguage <> currentLanguage
			if currentLanguage.HasSub(Key)
				Return _GetRandomString(currentLanguage, Key)
			else
				Return _GetRandomString(fallbackLanguage, Key)
			endif
		endif

		Return _GetRandomString(currentLanguage, Key)
	End Function



	'Returns the value for the specified key, or the given key if
	'nothing was found
	Function GetRandomLocalizedString:TLocalizedString(Key:String, group:String = Null)
		local ls:TLocalizedString = new TLocalizedString
		For local lang:TLocalizationLanguage = EachIn languages.Values()
			'skip default ones
			local res:string = _GetRandomString(lang, Key)
			if res = key then continue
			ls.Set(res.replace("\n", Chr(13)), lang.languageCode)

			'ls.Set(_GetRandomString(lang, Key).replace("\n", Chr(13)), lang.languageCode)
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
		return TLocalizationLanguage(languages.ValueForKey(languageCode))
	End Function


	Function AddLanguage:int(language:TLocalizationLanguage)
		if not languages.ValueForKey(language.languageCode)
			languagesCount :+ 1
		endif
		languages.insert(language.languageCode, language)
	End Function


	Function SetFallbackLanguage:Int(languageCode:String)
		local lang:TLocalizationLanguage = GetLanguage(languageCode)

		if lang
			fallbackLanguage = lang
			TLocalizedString.defaultLanguage = languageCode
			Return True
		else
			Return False
		endif
	End Function


	'Returns the current language
	Function GetFallbackLanguageCode:String()
		if fallbackLanguage then return fallbackLanguage.languageCode
		return ""
	End Function
	

	Function SetCurrentLanguage:Int(languageCode:String)
		local lang:TLocalizationLanguage = GetLanguage(languageCode)

		if lang
			currentLanguage = lang
			TLocalizedString.SetCurrentLanguage(languageCode)

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
		languages.Clear()
		languages = Null
		currentLanguage = Null
		fallbackLanguage = Null
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
	Field values:TMap = CreateMap()
	Global fallbackLanguage:string = "de"
	Global defaultLanguage:string = "en"
	Global currentLanguage:string = "de"
	Global _nilNode:TNode = New TNode._parent

	Method Copy:TLocalizedString()
		local c:TLocalizedString = New TLocalizedString

		Local node:TNode = values._FirstNode()
		While node And node <> _nilNode
			c.values.insert(node._key, node._value)
			node = node.NextNode()
		Wend

		'For local k:string = EachIn values.Keys()
		'	c.values.insert(k, values.ValueForKey(k))
		'Next

		return c
	End Method


	Method ToString:string()
		local r:string = ""
		For local key:string = EachIn values.Keys()
			r :+ key+": " + string(values.ValueForKey(key))+"~n"
		Next
		return r
	End Method
	

	Function SetCurrentLanguage(language:String)
		currentLanguage = language
	End Function


	'Returns the current language
	Function GetCurrentLanguage:String()
		if currentLanguage then return currentLanguage
		return ""
	End Function


	'to ease "setting" (mystring.set(value)) the language
	'comes after the value.
	Method Set:TLocalizedString(value:String, language:object=null)
		if not language then language = defaultLanguage
		values.insert(language, value)
		return self
	End Method


	Method Get:String(language:object=null, returnDefault:int = True)
		if not language then language = currentLanguage
		local value:object = values.ValueForKey(language)
		if value
			return string(value)
		elseif returnDefault
			value = values.ValueForKey(defaultLanguage)
			if value
				return string(value)
			elseif fallbackLanguage <> defaultLanguage
				value = values.ValueForKey(fallbackLanguage)
				if value
					return string(value)
				endif
			endif
		endif
		return ""
	End Method


	Method Replace:TLocalizedString(source:string, replacement:string)
		Local node:TNode = values._FirstNode()
		While node And node <> _nilNode
			node._value = string(node._value).replace(source, replacement)
			node = node.NextNode()
		Wend
		return self
	End Method


	Method ReplaceLocalized:TLocalizedString(source:string, replacement:TLocalizedString)
		Local node:TNode = values._FirstNode()
		While node And node <> _nilNode
			node._value = string(node._value).replace(source, replacement.Get(node._key))
			node = node.NextNode()
		Wend
		return self
	End Method


	Method HasLanguageKey:int(key:string)
		for local k:string = EachIn values.Keys()
			if k = key then return True
		next
		return False
	End Method


	Method GetFirstLanguageKey:string()
		for local k:string = EachIn values.Keys()
			return k
		next
	End Method
		

	Method GetLanguageKeys:string[]()
		local keys:string[]
		for local k:string = EachIn values.Keys()
			keys :+ [k]
		next
		return keys
	End Method


	Method SerializeTLocalizedStringToString:string()
		local s:string = ""
		'concencate all into one string
		'de::TextGerman::en::TextEnglish::...
		For local language:string = EachIn values.Keys()
			if s <> "" then s :+ "::"
			s :+ language.replace("\","\\").replace(":", "\:")
			s :+ "::"
			s :+ string(values.ValueForKey(language)).replace("\","\\").replace(":", "\:")
		Next
		return s
	End Method


	Method DeSerializeTLocalizedStringFromString(text:String)
		local vars:string[] = text.split("::")
		local language:string, value:string
		local mode:int = 0
		For local s:string = EachIn vars
			s = s.replace("\:", ":").replace("\\", "\")
			if mode = 0
				language = s
				mode :+ 1
			else
				value = s
				mode = 0
				Set(value, language)
			endif
		Next
	End Method


	Method Append:TLocalizedString(other:TLocalizedString)
		if other
			Local node:TNode = other.values._FirstNode()
			While node And node <> _nilNode
				'this might overwrite previous values of the same language
				Set(string(node._value), node._key)

				node = node.NextNode()
			Wend
		endif
		return self
	End Method
End Type