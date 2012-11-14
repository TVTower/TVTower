Import brl.Retro
Import brl.map
SuperStrict


Type Localization
   Global currentLanguage:String
   Global supportedLanguages:TList
   Global Resources:TList

   'Set the current language
   Function SetLanguage:Int(language:String)

      For Local lang:String = EachIn supportedLanguages
         If language = lang Then
            currentLanguage = language
            Return True
         EndIf
      Next

      Return False

   End Function


   'Returns the current language
   Function Language:String()
      Return currentLanguage
   End Function


   'Adds a comma separated list of languages to the supported languages list
   Function AddLanguages:int(languages:String)
      Local Pos:Int = Instr(languages, ",")
      If Pos = 0
			supportedLanguages.AddLast(languages.Trim())
			Return 0
      EndIf

      While Pos > 0
         supportedLanguages.AddLast(Left(languages, Pos - 1).Trim())
         languages = Mid(languages, Pos + 1)
         Pos = Instr(languages, ",")
      Wend

      supportedLanguages.AddLast(languages.Trim())
   End Function


   'Loads the specified resource file into memory (faster, memory used)
   Function LoadResource(filename:String)
      LocalizationMemoryResource.open(filename)
   End Function


   'Loads all resource files according to the filter (for example: myfile*.txt will load myfile_en.txt, myfile_de.txt etc.)
   Function LoadResources(filter:String)
      For Local file:String = EachIn GetResourceFiles(filter)
         LoadResource(file)
      Next
   End Function

	Function GetStringWithParams:string(Key:string, group:string = Null, params:string[] = null)
		local result:string = Localization.GetString(Key, group)
		if params = null then return result

		For local i:int = 0 until Len(params)
			result = result.replace("%"+(i+1), params[i])
		Next
	End Function

   'Returns the value for the specified key, or an empty string if the key was not found
   Function GetString:String(Key:String, group:String = Null)
      Local ret:String = ""

      For Local r:LocalizationMemoryResource = EachIn resources
         If r.language <> currentLanguage Then Continue
         ret = r.GetString(Key, group)
         If ret <> Null Then Return ret.replace("\n", Chr(13))
      Next

      Return ret
   End Function


   'Detects the language of a resource file
   Function GetLanguageFromFilename:String(filename:String)
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


   'Returns all resource files according to the filter
   Function GetResourceFiles:TList(filter:String)
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


   'Releases all resources used by the Localization Module
   Function Dispose()
      For Local r:LocalizationMemoryResource = EachIn Resources
         r.Close()
      Next
      Resources.Clear()
      Resources = Null
      supportedLanguages = Null
   End Function
End Type

'Initialize
Localization.Resources = New TList
Localization.supportedLanguages = New TList

function GetLocale:string(key:string)
	return Localization.getString(key)
end Function



'resource type (loads the resource file in the memory, faster access, increased memory usage) ----------------
Type LocalizationMemoryResource
   Field language:String
   Field _link:TLink

   Field map:TMap

   'Opens a resource file and loads the content into memory
   Function open:LocalizationMemoryResource(filename:String, language:String = Null)
		If language = Null Then
			language = Localization.GetLanguageFromFilename(filename)
			If language = Null Then Throw "No language was specified for loading the resource file and the language could not be detected from the filename itself.~r~nPlease specify the language or use the format ~qname_language.extension~q for the resource files."
		EndIf

		local content:string = LoadText(filename)

		Local r:LocalizationMemoryResource = New LocalizationMemoryResource
		r.language	= language
		r.map			= New TMap
		r._link		= Localization.resources.AddLast(r)

		local line:string =""
		Local Key:String
		Local value:String
		Local Pos:Int = 0
		Local group:String = ""

		For line = EachIn content.Split(chr(10))
			if Left(line, 2) = "//" then print "comment:"+line;continue

			If Left(line, 1) = "[" and Right(line, 1) = "]"
				group = Mid(line, 2, line.length - 2).Trim()
			EndIf

			Pos = Instr(line, "=")
			If Pos > 0
				Key = Left(line, Pos - 1).Trim()
				value = Mid(line, Pos + 1).Trim()
			EndIf

			If Key <> Null and Key <> "" Then
				If group <> Null and group <> ""
					r.map.Insert( lower(group + "::" + Key), value )
					If r.map.ValueForKey(Key) = Null Then r.map.Insert( lower(Key), value )
				Else
					r.map.Insert( lower(Key), value )
				EndIf
			EndIf
		Next
		Return r
	End Function


   'Gets the value for the specified key
   Method GetString:String(Key:String, group:String = Null)
      Local ret:Object

      If group <> Null Then
         ret = map.ValueForKey( lower(group + "::" + Key) )
      Else
         ret = map.ValueForKey( lower(Key) )
      EndIf

      If ret = Null Then Return Key
      Return String(ret)
   End Method


   'Releases the used memory
   Method Close()
      If _link <> Null Then _link.Remove()
      If map <> Null Then map.Clear()
   End Method


   'If there are no references to this resource, the object will be deleted automatically
   Method Delete()
      Close()
   End Method

End Type