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
		if not currentLanguage then return Key
		
		Return currentLanguage.Get(Key, group).replace("\n", Chr(13))
	End Function


	Function GetRandomString:String(Key:String, limit:int=-1)
		if not currentLanguage then return Key

		local availableStrings:int = 1
		local subKey:string = ""
		Repeat
			subKey = Key
			if availableStrings > 0 then subKey :+ availableStrings
			if currentLanguage.Get(subKey) <> subKey
				availableStrings :+1
				continue
			endif

			if availableStrings = 1
				return currentLanguage.Get(Key).replace("\n", Chr(13))
			else
				return currentLanguage.Get(Key + Rand(1, availableStrings-1)).replace("\n", Chr(13))
			endif
		Forever
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


	Function SetCurrentLanguage:Int(language:String)
		local lang:TLocalizationLanguage = GetLanguage(language)

		if lang
			currentLanguage = lang
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


	'Releases all resources used by the localization class
	Function Dispose()
		languages.Clear()
		languages = Null
		currentLanguage = Null
	End Function
End Type


'convenience helper function
Function GetLocale:string(key:string)
	return TLocalization.getString(key)
End Function


Function GetRandomLocale:string(baseKey:string)
	return TLocalization.GetRandomString(baseKey)
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
End Type




Type TLocalizedString
	Field values:TMap = CreateMap()
	Global defaultLanguage:string = "de"
	Global currentLanguage:string = "de"


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
	Method Set:int(value:String, language:String="")
		if language="" then language = defaultLanguage
		values.insert(language, value)
	End Method


	Method Get:String(language:String="")
		if language="" then language = currentLanguage
		if values.Contains(language)
			return string(values.ValueForKey(language))
		else
			return string(values.ValueForKey(defaultLanguage))
		endif
	End Method


	Method SerializeToString:string()
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


	Method DeSerializeFromString(text:String)
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
rem
	Method SerializeToString:string()
		local s:string = ""
		'concencate all into one string
		'de::TextGerman::en::TextEnglish::...
		local q:string = "~~"
		For local language:string = EachIn values.Keys()
			if s <> "" then s :+ "::"
			s :+ language.replace(q,q+q).replace(":", q+":")
			s :+ "::"
			s :+ string(values.ValueForKey(language)).replace(q,q+q).replace(":", q+":")
		Next
		return s
	End Method


	Method DeSerializeFromString(text:String)
		local vars:string[] = text.split("::")
		local language:string, value:string
		local mode:int = 0
		local q:string = "~~"
		For local s:string = EachIn vars
			s = s.replace(q+":", ":").replace(q+q, q)
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
endrem

	Method Append:Int(other:TLocalizedString)
		if not other then return False

		For local language:String = EachIn other.values.Keys()
			'this might overwrite previous values of the same language
			Set(string(other.values.ValueForKey(language)), language)
		Next
		return True
	End Method
End Type