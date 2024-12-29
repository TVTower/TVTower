SuperStrict
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.directorytree.bmx"
Import "Dig/base.util.xmlhelper.bmx"
Import "Dig/base.util.hashes.bmx"
Import "Dig/base.util.mersenne.bmx"

Import "game.achievements.bmx"
Import "game.production.scripttemplate.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"
Import "game.person.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "game.gameconstants.bmx"
Import "game.database.localizer.bmx"


Type TDatabaseLoader
	Field programmeRolesCount:Int, totalProgrammeRolesCount:Int
	Field scriptTemplatesCount:Int, totalscriptTemplatesCount:Int
	Field moviesCount:Int, totalMoviesCount:Int
	Field seriesCount:Int, totalSeriesCount:Int
	Field newsCount:Int, totalNewsCount:Int
	Field totalNewsGenreCount:Int[][2]
	Field achievementCount:Int, totalAchievementCount:Int
	Field contractsCount:Int, totalContractsCount:Int
	Field personsBaseCount:Int, totalPersonsBaseCount:Int
	Field personsCount:Int, totalPersonsCount:Int

	Field loadError:String = ""

	Field releaseDayCounter:Int = 0
	Field stopWatchAll:TStopWatch = New TStopWatch.Init()
	Field stopWatch:TStopWatch = New TStopWatch.Init()

	Field allowedNewsCreators:String
	Field skipNewsCreators:String
	Field allowedAchievementCreators:String
	Field skipAchievementCreators:String
	Field allowedScriptCreators:String
	Field skipScriptCreators:String
	Field allowedPersonCreators:String
	Field skipPersonCreators:String
	Field allowedAdCreators:String
	Field skipAdCreators:String
	Field allowedProgrammeCreators:String
	Field skipProgrammeCreators:String
	Field config:TData = New TData
	Global metaData:TData = New TData
	Global XMLErrorCount:Int


	'contains custom "fictional" overriding the base one
	Global _personDetailKeys:String[]
	Global _personAttributeBaseKeys:String[]
	Global _personCommonDetailKeys:String[]
	Global _newsEventDataKeys:String[]
	Global _newsEventAvailabilityKeys:String[]
	Global _achievementDataKeys:String[]
	Global _adContractDataKeys:String[]
	Global _adContractAvailabilityKeys:String[]
	Global _adContractConditionKeys:String[]
	Global _programmeLicenceDataKeys:String[]
	Global _programmeLicenceDataTimeFieldsKeys:String[]
	Global _programmeLicenceDataGroupsKeys:String[]	
	Global _programmeLicenceRatingsKeys:String[]

	Method New()
		allowedAdCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_ADS_CREATED_BY", "*").Split(",")
			allowedAdCreators :+ " "+Trim(s).ToLower()+" "
		Next

		skipAdCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_ADS_CREATED_BY", "").Split(",")
			skipAdCreators :+ " "+Trim(s).ToLower()+" "
		Next

		allowedProgrammeCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_PROGRAMMES_CREATED_BY", "*").Split(",")
			allowedProgrammeCreators :+ " "+Trim(s).ToLower()+" "
		Next

		skipProgrammeCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_PROGRAMMES_CREATED_BY", "").Split(",")
			skipProgrammeCreators :+ " "+Trim(s).ToLower()+" "
		Next

		allowedNewsCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_NEWS_CREATED_BY", "*").Split(",")
			allowedNewsCreators :+ " "+Trim(s).ToLower()+" "
		Next

		skipNewsCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_NEWS_CREATED_BY", "").Split(",")
			skipNewsCreators :+ " "+Trim(s).ToLower()+" "
		Next

		allowedScriptCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_SCRIPTS_CREATED_BY", "*").Split(",")
			allowedScriptCreators :+ " "+Trim(s).ToLower()+" "
		Next

		skipScriptCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_SCRIPTS_CREATED_BY", "").Split(",")
			skipScriptCreators :+ " "+Trim(s).ToLower()+" "
		Next

		allowedAchievementCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_ACHIEVEMENTS_CREATED_BY", "*").Split(",")
			allowedAchievementCreators :+ " "+Trim(s).ToLower()+" "
		Next

		skipAchievementCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_ACHIEVEMENTS_CREATED_BY", "").Split(",")
			skipAchievementCreators :+ " "+Trim(s).ToLower()+" "
		Next

		allowedPersonCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_PERSONS_CREATED_BY", "*").Split(",")
			allowedPersonCreators :+ " "+Trim(s).ToLower()+" "
		Next

		skipPersonCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_PERSONS_CREATED_BY", "").Split(",")
			skipPersonCreators :+ " "+Trim(s).ToLower()+" "
		Next
	End Method


	Method IsAllowedUser:Int(username:String, dataType:String)
		Local allowed:String
		Local skip:String

		username = username.ToLower().Replace("unknown", "*")
		username = username.Trim()
		If username = "" Then username = "*"

		Select dataType.ToLower()
			Case "adcontract"
				allowed = allowedAdCreators
				skip = skipAdCreators
			Case "programmelicence"
				allowed = allowedProgrammeCreators
				skip = skipProgrammeCreators
			Case "news", "newsevent"
				allowed = allowedNewsCreators
				skip = skipNewsCreators
			Case "script", "scripttemplate"
				allowed = allowedScriptCreators
				skip = skipScriptCreators
			Case "person", "insignificantpeople"
				allowed = allowedPersonCreators
				skip = skipPersonCreators
			Case "achievement"
				allowed = allowedAchievementCreators
				skip = skipAchievementCreators
		EndSelect

		'all allowed? -> check "skip"
		If allowed.Find(" * ") >= 0
			'cannot skip all when loading all
			If skip.Find(" * ") >= 0
				Print "ALLOWED * and SKIPPED * ... not possible. Type: "+dataType+". Allowing ALL creators for this type."
				Return True
			EndIf

			If skip.Find(" "+username+" ") >= 0
				Print "all allowed but skipping: " +username + "   " + skip.Find(" "+username+" ")
				Return False
			EndIf
			Return True
		'only selected allowed
		Else
			If allowed.Find(" "+username+" ") >= 0 Then Return True
			Return False
			Print "not all allowed    username="+username+"    allowed="+allowed +"   skipped="+skip
		EndIf
		Return False
	End Method


	Method LoadDir(dbDirectory:String, required:Int = False)
		'build file list of xml files in the given directory
		Local dirTree:TDirectoryTree = New TDirectoryTree.SimpleInit()
		dirTree.SetIncludeFileEndings(["xml"])
		'exclude some files as we add it by default to load it
		'as the first files / specific order (as they do not require
		'others - this avoids "extending X"-log-entries)
		dirTree.SetExcludeFileNames(["database_scripts", "database_people", "database_roles", "database_people_fictional", "database_ads", "database_programmes", "database_programmes_fictional", "database_news"])
		'exclude localization directories - will be processed by SetLanguage
		dirTree.SetExcludeDirectoryNames(["lang", "lang_original"])

		'add the rest of available files in the given dir
		'(this also sorts the files)
		dirTree.ScanDir(dbDirectory)

		'add that files at the top
		'(in reversed order as each is added at top of the others!)
		dirTree.AddFile(dbDirectory+"/database_achievements.xml", True) 'last
		dirTree.AddFile(dbDirectory+"/database_programmes_fictional.xml", True)
		dirTree.AddFile(dbDirectory+"/database_programmes.xml", True)
		dirTree.AddFile(dbDirectory+"/database_news.xml", True)
		dirTree.AddFile(dbDirectory+"/database_ads.xml", True)
		dirTree.AddFile(dbDirectory+"/database_scripts.xml", True)
		dirTree.AddFile(dbDirectory+"/database_roles.xml", True)
		dirTree.AddFile(dbDirectory+"/database_people_fictional.xml", True)
		dirTree.AddFile(dbDirectory+"/database_people.xml", True) 'first


		Local fileURIs:String[] = dirTree.GetFiles()
		Local validURIs:Int = 0
		'loop over all filenames
		For Local fileURI:String = EachIn fileURIs
			'skip non-existent files
			If FileType(fileURI) <> 1 Then Continue
			validURIs :+ 1
			Load(fileURI)
		Next

		If required Or validURIs > 0
			TLogger.Log("TDatabase.Load()", "Loaded from "+validURIs + " DBs. Found " + totalSeriesCount + " series, " + totalMoviesCount + " movies, " + totalPersonsBaseCount+"/"+totalPersonsCount +" basePersons/persons, " + totalContractsCount + " advertisements, " + totalNewsCount + " news, " + totalProgrammeRolesCount + " roles in scripts, " + totalScriptTemplatesCount + " script templates and "+ totalAchievementCount+" achievements. Loading time: " + stopWatchAll.GetTime() + "ms", LOG_LOADING)
			Local newsGenreString:String = "initial news templates (unique/reusable): "
			For Local i:Int = 0 Until TVTNewsGenre.count
				newsGenreString :+ (TVTNewsGenre.GetAsString(i) + " ("+totalNewsGenreCount[i][0]+"/"+totalNewsGenreCount[i][1]+") ")
			Next
			TLogger.Log("TDatabase.Load()",newsGenreString, LOG_LOADING)
		EndIf

		If required And (totalSeriesCount = 0 Or totalMoviesCount = 0 Or totalNewsCount = 0 Or totalContractsCount = 0)
			Notify "Important data is missing:  series:"+totalSeriesCount+"  movies:"+totalMoviesCount+"  news:"+totalNewsCount+"  adcontracts:"+totalContractsCount
		EndIf

		LoadDatabaseLocalizations(dbDirectory)

		'fix potentially corrupt data
		FixLoadedData()
	End Method


	Function LoadDatabaseLocalizations(dbDirectory:String)
		Local langDir:String = dbDirectory+"/lang/"
		Local dbl:TDatabaseLocalizer = GetDatabaseLocalizer()
		Local toStore:TPersonLocalization[] = new TPersonLocalization[100]

		For Local l:TLocalizationLanguage = EachIn TLocalization.languages
			Local code:String = l.languageCode
			Local file:String = langDir + code+".xml"
			If FileType(file) = 1
				Local xml:TXmlHelper = TXmlHelper.Create(file)
				Local allGlobalVars:TxmlNode = xml.FindRootChildLC("globalvariables")
				If allGlobalVars
					Local gvl:TLocalizationLanguage = dbl.getGlobalVariables(code)
					If Not gvl
						gvl = new TLocalizationLanguage
						gvl.languageCode = code
						dbl.globalVariables.insert(code, gvl)
					EndIf
					Local varName:String
					Local value:String
					For Local varNode:TxmlNode = EachIn xml.GetNodeChildElements(allGlobalVars)
						varName = varNode.getName().toLower()
						value = varNode.getContent()
						If varName And value Then gvl.map.insert(varName, value)
					Next
				EndIf

				Local nodeAllPersons:TxmlNode
				nodeAllPersons = xml.FindRootChildLC("persons")
				Local index:Int = 0
				Local personCollection:TPersonBaseCollection = GetPersonBaseCollection()
				For Local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
					If nodePerson.getName() <> "person" Then Continue
					Local data:TData = New TData
					xml.LoadValuesToData(nodePerson, data, ["guid","first_name", "last_name", "nick_name", "title"])
					Local guid:String=data.GetString("guid")
					If guid
						Local person:TPersonBase = personCollection.GetByGUID(guid)
						If person
							Local personToStore:TPersonLocalization = new TPersonLocalization
							personToStore.id = person.id
							personToStore.firstName=data.GetString("first_name","")
							personToStore.lastName=data.GetString("last_name","")
							personToStore.nickName=data.GetString("nick_name","")
							personToStore.title=data.GetString("title","")
							if toStore.length <= index Then toStore = toStore[.. index + 50]
							toStore[index] = personToStore
							index:+1
						EndIf
					EndIf
				Next
				If index > 0 Then dbl.persons.insert(code, toStore[..index])

				Local nodeAllRoles:TxmlNode
				nodeAllRoles = xml.FindRootChildLC("programmeroles")
				If Not nodeAllRoles Then nodeAllRoles = xml.FindRootChildLC("roles")
				index = 0
				For Local nodeRole:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllRoles)
					If nodeRole.getName() <> "programmerole" And nodeRole.getName() <> "role" Then Continue
					Local data:TData = New TData
					xml.LoadValuesToData(nodeRole, data, ["guid","first_name", "last_name", "nick_name", "title"])
					Local guid:String=data.GetString("guid")
					If guid
						Local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(guid)
						If role
							Local roleToStore:TPersonLocalization = new TPersonLocalization
							roleToStore.id = role.id
							roleToStore.firstName=data.GetString("first_name","")
							roleToStore.lastName=data.GetString("last_name","")
							roleToStore.nickName=data.GetString("nick_name","")
							roleToStore.title=data.GetString("title","")
							if toStore.length <= index Then toStore = toStore[.. index + 50]
							toStore[index] = roleToStore
							index:+ 1
						EndIf
					EndIf
				Next
				If index > 0 Then dbl.roles.insert(code, toStore[..index])
			EndIf
		Next
	End Function


	Function MXMLErrorCallback(message:Byte Ptr)
		Local s:String = string.FromCString(message)
		TLogger.Log("TDatabase.Load()", "mxml-Error: " + s, LOG_ERROR + LOG_XML)
		'not multithreaded "xml loading" ready!
		XMLErrorCount :+ 1
	End Function


	Method Load(fileURI:String)
		config.Add("currentFileURI", fileURI)
		'register our own mxml error printer:
		XMLSetErrorCallback(MXMLErrorCallback)
		
		Local oldXMLErrorCount:Int = XMLErrorCount 'not multithread ready!
		Local xml:TXmlHelper = TXmlHelper.Create(fileURI)

		'reset "per database" variables
		moviesCount = 0
		seriesCount = 0
		newsCount = 0
		achievementCount = 0
		contractsCount = 0
		personsCount = 0
		personsBaseCount = 0
		scriptTemplatesCount = 0
		If totalNewsGenreCount.length < TVTNewsGenre.count
			totalNewsGenreCount = []
			For Local i:Int = 0 Until TVTNewsGenre.count
				totalNewsGenreCount :+ [[0, 0]]
			Next
		EndIf
		'recognize version (if versionNode is Null, defaultValue -1 is returned
		Local versionNode:TxmlNode = xml.FindRootChildLC("version")
		Local version:Int = xml.FindValueIntLC(versionNode, "value", -1)
		If oldXMLErrorCount < XMLErrorCount
			TLogger.Log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - INVALID XML FILE." , LOG_LOADING)
		Else
			'load according to version
			Select version
				Case -1	TLogger.Log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - MISSING VERSION ATTRIBUTE." , LOG_LOADING)
				Case 3	LoadV3(xml)
				Default	TLogger.Log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - UNHANDLED VERSION." , LOG_LOADING)
			End Select
		EndIf
		
		'de-register our own mxml error printer:
		XMLSetErrorCallback(null)
	End Method



	Method LoadV3:Int(xml:TXmlHelper)
		stopWatch.Init()

		'===== IMPORT ALL PERSONS =====
		'so they can get referenced properly
		Local nodeAllPersons:TxmlNode
		'insignificant (non prominent) people
		nodeAllPersons = xml.FindRootChildLC("insignificantpeople")
		For Local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
			If nodePerson.getName() <> "person" Then Continue

			'param false = load as insignificant
			If LoadV3PersonBaseFromNode(nodePerson, xml, False)
				personsBaseCount :+ 1
				totalPersonsBaseCount :+ 1
			EndIf
		Next

		'celebrities (they have more details)
		nodeAllPersons = xml.FindRootChildLC("celebritypeople")
		For Local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
			If nodePerson.getName() <> "person" Then Continue

			'param true = load as celebrity
			If LoadV3PersonBaseFromNode(nodePerson, xml, True)
				personsCount :+ 1
				totalPersonsCount :+ 1
			EndIf
		Next


		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====
		Local nodeAllAds:TxmlNode = xml.FindRootChildLC("allads")
		If nodeAllAds
			For Local nodeAd:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllAds)
				If nodeAd.getName() <> "ad" Then Continue

				LoadV3AdContractBaseFromNode(nodeAd, xml)
			Next
		EndIf


		'===== IMPORT ALL NEWS EVENTS =====
		Local nodeAllNews:TxmlNode = xml.FindRootChildLC("allnews")
		If nodeAllNews
			For Local nodeNews:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllNews)
				If nodeNews.getName() <> "news" Then Continue

				LoadV3NewsEventTemplateFromNode(nodeNews, xml)
			Next
		EndIf

		'===== IMPORT ALL PROGRAMME ROLES =====
		Local nodeAllRoles:TxmlNode = xml.FindRootChildLC("programmeroles")
		If nodeAllRoles
			For Local nodeRole:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllRoles)
				If nodeRole.getName() <> "programmerole" Then Continue

				LoadV3ProgrammeRoleFromNode(nodeRole, xml)
			Next
		EndIf


		'===== IMPORT ALL PROGRAMMES (MOVIES/SERIES) =====
		'ATTENTION: LOAD PERSONS FIRST !!
		Local nodeAllProgrammes:TxmlNode = xml.FindRootChildLC("allprogrammes")
		If nodeAllProgrammes
			For Local nodeProgramme:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllProgrammes)
				If nodeProgramme.getName() <> "programme" Then Continue

				'creates a TProgrammeLicence of the found entry.
				'If the entry contains "episodes", they get loaded too
				Local licence:TProgrammeLicence
				licence = LoadV3ProgrammeLicenceFromNode(nodeProgramme, xml)

				If licence
					If licence.isSingle()
						moviesCount :+ 1
						totalMoviesCount :+ 1
					ElseIf licence.isSeries()
						seriesCount :+ 1
						totalSeriesCount :+ 1
					EndIf

					'add children
					For Local sub:TProgrammeLicence = EachIn licence.subLicences
						If Not GetProgrammeLicenceCollection().AddAutomatic(sub)
							TLogger.Log("TDatabase.Load()", "Failed to ~qAddAutomatic()~q. Licence = " + sub.GetGUID(), LOG_LOADING)
						EndIf
					Next

					If Not GetProgrammeLicenceCollection().AddAutomatic(licence)
						TLogger.Log("TDatabase.Load()", "Failed to ~qAddAutomatic()~q. Licence = " + licence.GetGUID(), LOG_LOADING)
					EndIf
					Rem
					if GetWorldTime().GetYear(licence.GetData().releaseTime) > 1985 and licence.IsAvailable()
						print licence.GetTitle() +"   is released: "+ GetWorldTime().GetFormattedDate(licence.GetData().releaseTime)+"  available:"+licence.IsAvailable() +" isReleased:"+licence.IsReleased() +" isLive:"+licence.GetData().IsLive() +"  relTime:"+ (GetWorldTime().GetTimeGone() >= licence.GetData().releaseTime)
						For local sub:TProgrammeLicence = eachin licence.subLicences
							if sub.isAvailable() then print "episode ~q"+sub.GetTitle()+" is available"
						Next
					endif
					endrem
				EndIf
			Next
		EndIf


		'===== IMPORT ALL SCRIPT (TEMPLATES) =====
		Local nodeAllScriptTemplates:TxmlNode = xml.FindRootChildLC("scripttemplates")
		If nodeAllScriptTemplates
			For Local nodeScriptTemplate:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllScriptTemplates)
				If nodeScriptTemplate.getName() <> "scripttemplate" Then Continue

				LoadV3ScriptTemplateFromNode(nodeScriptTemplate, xml)
			Next
		EndIf



		'===== IMPORT ALL ACHIEVEMENTS =====
		Local nodeAllAchievements:TxmlNode = xml.FindRootChildLC("allachievements")
		If nodeAllAchievements
			For Local nodeAchievement:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllAchievements)
				If nodeAchievement.getName() <> "achievement" Then Continue

				LoadV3AchievementFromNode(nodeAchievement, xml)
			Next
		EndIf


		TLogger.Log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 3). Found " + seriesCount + " series, " + moviesCount + " movies, " + personsBaseCount + "/" + personsCount +" basePersons/persons, " + contractsCount + " advertisements, " + newsCount + " news, " + achievementCount+" achievements, "+ scriptTemplatesCount+" script templates. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method




	'=== HELPER ===
	'migrate script expressions
	Global convertSB:TStringBuilder = New TStringBuilder()
	Global convertOldNewMap:TStringMap = New TStringMap


	Function ConvertOldScriptExpression:Int(templateVariables:TTemplateVariables, changedSomething:Int Var)
		If Not templateVariables Then Return 0
		
		Local changeCount:Int = 0
		If templateVariables.variables
			For Local ls:TLocalizedString = EachIn templateVariables.variables.Values()
				changeCount :+ ConvertOldScriptExpression(ls, changedSomething)
			Next
		EndIf
		If templateVariables.variablesResolved
			For Local ls:TLocalizedString = EachIn templateVariables.variablesResolved.Values()
				changeCount :+ ConvertOldScriptExpression(ls, changedSomething)
			Next
		EndIf

		changedSomething = (changeCount > 0)
		Return changeCount
	End Function


	Function ConvertOldScriptExpression:Int(ls:TLocalizedString, changedSomething:Int Var)

		Local changeCount:Int = 0
		For local i:Int = 0 until ls.valueStrings.length
			changedSomething = False
			Local newS:String = ConvertOldScriptExpression(ls.valueStrings[i], changedSomething)
			if changedSomething
				ls.valueStrings[i] = newS
				changeCount :+ 1
			EndIf
		Next
		changedSomething = (changeCount > 0)
		Return changeCount
	End Function


	Function ConvertOldScriptExpression:String(expression:string, changedSomething:Int Var)
		Return ConvertOldScriptExpression(expression, convertOldNewMap, convertSB, changedsomething)
	End function


	Function ConvertOldScriptExpression:String(expression:string, oldNewMapping:TStringMap, scriptExpressionConverterSB:TStringBuilder, changedSomething:Int Var)
		changedsomething = False
		'store old so we can identify if it was changed during conversion
		Local expressionBefore:String = expression
		
		'type 1: [1|Full] ... only in cast
		'type 2: %PERSONGENERATOR_NAME(country,gender)%
		'type 3: %WORLDTIME:wrongSubCommandName%
		'type 4: %variable%
		'type 5: %person|1|Full%  -- not in use in _our_ db files

		'type 1:
		'-------
		For local i:int = 0 until 15
			if expression.Find("["+i) >= 0
				expression = expression.Replace("["+i+"|Full]", "${.self:~qcast~q:"+i+":~qfullname~q}")
				expression = expression.Replace("["+i+"|First]", "${.self:~qcast~q:"+i+":~qfirstname~q}")
				expression = expression.Replace("["+i+"|Last]", "${.self:~qcast~q:"+i+":~qlastname~q}")
				expression = expression.Replace("["+i+"|Nick]", "${.self:~qcast~q:"+i+":~qnickname~q}")
			EndIf

			'role(name) assumption is that NUMBER corrensponds to job INDEX (0=director, 1..x=actors)
			if expression.Find("%ROLENAME"+i) >= 0
				expression = expression.Replace("%ROLENAME"+i+"%", "${.self:~qrole~q:"+(i)+":~qfirstname~q}")
			EndIf
			if expression.Find("%ROLE"+i) >= 0
				expression = expression.Replace("%ROLE"+i+"%", "${.self:~qrole~q:"+(i)+":~qfullname~q}")
			EndIf
		Next

			
		'type 2:
		'-------
		'replace %PERSONGENERATOR_...
		local personGenPos:Int = expression.Find("%PERSONGENERATOR_")
		if personGenPos >= 0
			While personGenPos >= 0
				Local personGenEndPos:Int = expression.Find(")%", personGenPos)
				Local sub:String = expression[personGenPos .. personGenEndPos + 2]
				sub = sub.replace("%PERSONGENERATOR_", "${.persongenerator:~q")
				sub = sub.replace("(","~q:~q")
				sub = sub.replace(",","~q:")
				sub = sub.replace(")%","}")
				sub = sub.replace("unk", "") 'remove "unknown" country code 
				expression = expression[0 .. personGenPos] + sub +  expression[personGenEndPos + 2 ..]

				'search next
				personGenPos = expression.Find("%PERSONGENERATOR_")
			Wend
		EndIf
		
		'replace sport stuff:
		If expression.Find("%TEAM")>=0
			expression = expression.Replace("%TEAM1NAMEINITIALS%", "${.self:~qsportteam~q:0:~qteaminitials~q}")
			expression = expression.Replace("%TEAM2NAMEINITIALS%", "${.self:~qsportteam~q:1:~qteaminitials~q}")
			expression = expression.Replace("%TEAM1RANK%", "${.self:~qsportteam~q:0:~qleaguerank~q}")
			expression = expression.Replace("%TEAM2RANK%", "${.self:~qsportteam~q:1:~qleaguerank~q}")
			expression = expression.Replace("%TEAM1TRAINERSHORT%", "${.self:~qsportteam~q:0:~qtrainer~q:~qlastname~q}")
			expression = expression.Replace("%TEAM2TRAINERSHORT%", "${.self:~qsportteam~q:1:~qtrainer~q:~qlastname~q}")
			expression = expression.Replace("%TEAM1TRAINER%", "${.self:~qsportteam~q:0:~qtrainer~q:~qfullname~q}")
			expression = expression.Replace("%TEAM2TRAINER%", "${.self:~qsportteam~q:1:~qtrainer~q:~qfullname~q}")
			expression = expression.Replace("%TEAM1STARSHORT%", "${.self:~qsportteam~q:0:~qmember~q:~qforward~q:~qlastname~q}")
			expression = expression.Replace("%TEAM2STARSHORT%", "${.self:~qsportteam~q:1:~qmember~q:~qforward~q:~qlastname~q}")
			expression = expression.Replace("%TEAM1STAR%", "${.self:~qsportteam~q:0:~qmember~q:~qforward~q:~qfullname~q}")
			expression = expression.Replace("%TEAM2STAR%", "${.self:~qsportteam~q:1:~qmember~q:~qforward~q:~qfullname~q}")
			expression = expression.Replace("%TEAM1KEEPERSHORT%", "${.self:~qsportteam~q:0:~qmember~q:~qkeeper~q:~qlastname~q}")
			expression = expression.Replace("%TEAM2KEEPERSHORT%", "${.self:~qsportteam~q:1:~qmember~q:~qkeeper~q:~qlastname~q}")
			expression = expression.Replace("%TEAM1KEEPER%", "${.self:~qsportteam~q:0:~qmember~q:~qkeeper~q:~qfullname~q}")
			expression = expression.Replace("%TEAM2KEEPER%", "${.self:~qsportteam~q:1:~qmember~q:~qkeeper~q:~qfullname~q}")
			expression = expression.Replace("%TEAM1NAME%", "${.self:~qsportteam~q:0:~qteamname~q}")
			expression = expression.Replace("%TEAM2NAME%", "${.self:~qsportteam~q:1:~qteamname~q}")
			expression = expression.Replace("%TEAM1CITY%", "${.self:~qsportteam~q:0:~qcity~q}")
			expression = expression.Replace("%TEAM2CITY%", "${.self:~qsportteam~q:1:~qcity~q}")
			expression = expression.Replace("%TEAM1ARTICLE1% %TEAM1NAME%", "${.self:~qsportteam~q:0:~qteamnamewitharticle~q}")
			expression = expression.Replace("%TEAM1ARTICLE2% %TEAM1NAME%", "${.self:~qsportteam~q:0:~qteamnamewitharticle~q:2}")
			expression = expression.Replace("%TEAM2ARTICLE1% %TEAM2NAME%", "${.self:~qsportteam~q:1:~qteamnamewitharticle~q}")
			expression = expression.Replace("%TEAM2ARTICLE2% %TEAM2NAME%", "${.self:~qsportteam~q:1:~qteamnamewitharticle~q:2}")
			expression = expression.Replace("%TEAM2ARTICLE2% %TEAM2%", "${.self:~qsportteam~q:1:~qteamnamewitharticle~q:2}")
			expression = expression.Replace("%TEAM1ARTICLE1%", "${.self:~qsportteam~q:0:~qteamnamearticle~q}")
			expression = expression.Replace("%TEAM1ARTICLE2%", "${.self:~qsportteam~q:0:~qteamnamearticle~q:2}")
			expression = expression.Replace("%TEAM2ARTICLE1%", "${.self:~qsportteam~q:1:~qteamnamearticle~q}")
			expression = expression.Replace("%TEAM2ARTICLE2%", "${.self:~qsportteam~q:1:~qteamnamearticle~q:2}")
		EndIf
		expression = expression.Replace("%FINALSCORE%", "${.self:~qsportmatch~q:~qfinalscoretext~q}")
		expression = expression.Replace("%SPORTNAME%", "${.self:~qsport~q:~qname~q}")
		expression = expression.Replace("%LEAGUENAME%", "${.self:~qsportleague~q:~qname~q}")
		expression = expression.Replace("%LEAGUENAMESHORT%", "${.self:~qsportleague~q:~qnameshort~q}")
		expression = expression.Replace("%SEASONYEARSTART%", "${.worldtime:~qyear~q:${.self:~qsportleague~q:~qgetfirstmatchtime~q}}")
		expression = expression.Replace("%UPCOMINGMATCHTIMESFORMATTED%", "${.self:~qsportleague~q:~qupcomingmatchtimesformatted~q}")
		If expression.Find("%MATCH")>=0
			expression = expression.Replace("%MATCHCOUNT%", "${.self:~qsportleague~q:~qmatchcount~q}")
			expression = expression.Replace("%MATCHTIMESFORMATTED%", "${.self:~qsportleague~q:~qmatchtimesformatted~q}")
			expression = expression.Replace("%MATCHNAMESHORT%", "${.self:~qsportmatch~q:~qnameshort~q}")
			expression = expression.Replace("%MATCHREPORT%", "${.self:~qsportmatch~q:~qreportshort~q}")
			expression = expression.Replace("%MATCHREPORTSHORT%", "${.self:~qsportmatch~q:~qreportshort~q}")
			expression = expression.Replace("%MATCHLIVEREPORTSHORT%", "${.self:~qsportmatch~q:~qlivereportshort~q}")
			expression = expression.Replace("%MATCHRESULT%", "${.self:~qsportmatch~q:~qresulttext~q}")
			expression = expression.Replace("%MATCHSCOREMAXTEXT%", "${.neq:${.self:~qsportmatch~q:~qwinnerscore~q}:1:~q${.locale:~qSCORE_POINTS~q}~q:~q${.locale:~qSCORE_POINT~q}~q}")
			expression = expression.Replace("%MATCHKIND%", "${.lte:7:${.random:10}:~q${.locale:~qSPORT_TEAMREPORT_MATCHKIND~q:~q~q:1}~q:~q~q}")
			expression = expression.Replace("%MATCHSCORE1TEXT%", "${.self:~qsportmatch~q:~qscore~q:0} ${.neq:${.self:~qsportmatch~q:~qscore~q:0}:1:~q${.locale:~qSCORE_POINTS~q}~q:~q${.locale:~qSCORE_POINT~q}~q}")
			expression = expression.Replace("%MATCHSCORE2TEXT%", "${.self:~qsportmatch~q:~qscore~q:1} ${.neq:${.self:~qsportmatch~q:~qscore~q:1}:1:~q${.locale:~qSCORE_POINTS~q}~q:~q${.locale:~qSCORE_POINT~q}~q}")
			expression = expression.Replace("%MATCHSCOREDRAWGAMETEXT%", "${.self:~qsportmatch~q:~qdrawgamescore~q} ${.gte:${.self:~qsportmatch~q:~qdrawgamescore~q}:2:~q${.locale:~qSCORE_POINTS~q}~q:~q${.locale:~qSCORE_POINT~q}~q}")
		EndIf
		expression = expression.Replace("%PLAYTIMEMINUTES%", "${.self:~qsportmatch~q:~qplaytimeminutes~q}")

		
		
		


		'type 3:
		'-------
		'replace renamed subcommands
		if expression.Find("%WORLDTIME") >= 0
			expression = expression.Replace("%WORLDTIME:GAMEDAY%", "${.worldtime:~qdayplaying~q}")
			'officially only used in kieferer.xml - stock exchange news
			expression = expression.Replace("%WORLDTIME:GERMANCURRENCY%", "${.if:${.worldtime:~qyear~q}>=2002:~qEuro~q:~q${.if:${.worldtime:~qyear~q}>=1990:~qDM~q:~qMark~q}~q}")
			'not used in official dbs (so only in potential user databases)
			expression = expression.Replace("%WORLDTIME:GERMANCAPITAL%", "${.if:${.worldtime:~qyear~q}>=1990:~qBerlin~q:~qBonn~q}")
		EndIf
		

		'in type 4 we "return", so update changed information here
		If expressionBefore <> expression
			changedSomething = True
		EndIf


		'type 4:
		'-------

		'check if at least 2 "%" (old expression sign) exist
		local percentCount:Int
		For local i:int = 0 until expression.length
			if expression[i] = Asc("%") 
				percentCount :+ 1
			endif
			if percentCount >= 2 then exit
		Next
		if percentCount < 2 Then Return expression


		if not scriptExpressionConverterSB Then scriptExpressionConverterSB = New TStringBuilder()
		scriptExpressionConverterSB.SetLength(0)

		Local expressionStartPos:Int = -1
		Local ch:Int
		Local appendChar:Int = True
		For local i:int = 0 until expression.length
			ch = expression[i]
			if ch = Asc("%")
				'expression started and end found? - interpret it
				if expressionStartPos >= 0
					scriptExpressionConverterSB.Append("${")
					'local identifier:String = expression[expressionStartPos +1 .. i]
					local identifierLS:String = expression[expressionStartPos +1 .. i].ToLower()
					If oldNewMapping.Contains(identifierLS)
						scriptExpressionConverterSB.Append( oldNewMapping.ValueForKey(identifierLS) )
					Else
						'prepend a "." to make it a function call, replace ":" with "_"
						'-> "STATIONMAP:RANDOMCITY" becomes ".stationmap:~qrandomcity~q"
						if identifierLS.Find(":") > 0
							scriptExpressionConverterSB.Append("." + expression[expressionStartPos +1 .. i].Replace(":", ":~q"))
							scriptExpressionConverterSB.Append("~q")
						else
							scriptExpressionConverterSB.Append(expression[expressionStartPos +1 .. i])
						endif
					EndIf
					scriptExpressionConverterSB.Append("}")
					expressionStartPos = -1

					changedSomething = True

				'start found
				else
					expressionStartPos = i
				endif

				'do not add this % char to the result...
				continue
			EndIf

			'outside of an expression?
			If expressionStartPos < 0
				scriptExpressionConverterSB.AppendChar(ch)
			EndIf

			'non-expression-allowed char found?
			If expressionStartPos >= 0
				if not (..
					ch = Asc(":") ..                    ' DOUBLE COLON --- STATIONMAP:BLA
					Or ch = Asc("_") ..                 ' UNDERSCORE
					Or ( ch >= 48 And ch <= 57 ) ..     ' NUMBER
					Or ( ch >= 65 And ch <= 90 ) ..     ' UPPERCASE
					Or ( ch >= 97 And ch <= 122 ) ..    ' LOWERCASE
					)
				
					scriptExpressionConverterSB.Append(expression[expressionStartPos .. i +1]) 'add all the "invalid expression"-stuff we found until now
					expressionStartPos = -1
				EndIf
			endif
		Next

		'print "~q"+expression+"~q  =>  ~q" + scriptExpressionConverterSB.ToString() + "~q"
		
		return scriptExpressionConverterSB.ToString()
	End Function


	Function ConvertOldAvailableScript:String(expression:string)
		'skip if the expression contains ${ already.
		'yes, this also converts "4 > 10" (at least tries to...,)
		if expression.Find("${") >= 0 Then Return expression

		'sample scripts (used in the DBs at the time of writing this) 
		'TIME_YEAR=2017
		'TIME_YEAR=1987 && TIME_MONTH=1
		'TIME_YEAR=1987 && TIME_WEEKDAY=0 && TIME_HOUR>=12
		'TIME_MONTH=1 || TIME_MONTH=7
		
		
		'split by "||" or "&&" connectors:
		Local parts:String[]
		Local connectors:String[]
		if expression.Find("||") >= 0 or expression.Find("&&") >= 0
			local lastPos:Int
			local pos:Int
			Repeat
				pos = expression.Find("||", lastPos)
				If pos = -1 
					pos = expression.Find("&&", lastPos)
				EndIf
				
				If pos >= 0
					parts :+ [expression[lastPos .. pos-1].Trim()]
					connectors :+ [expression[pos .. pos + 2]]
					lastPos = pos + 2 '|| and && have a length of 2
				EndIf
			Until pos = -1
			'append missing parts
			parts :+ [expression[lastPos ..].Trim()]
		Else
			parts = [expression]
		EndIf
		
		'instead of trying to play smart we simply replace hardcoded strings...
		For Local i:int = 0 until parts.length
			'ensure to replace "DAYxxx" before "DAY", same for "YEAR"
			parts[i] = parts[i].Replace("TIME_DAYSPLAYED", "${.worldtime:~qdaysplayed~q}")
			parts[i] = parts[i].Replace("TIME_DAYOFMONTH", "${.worldtime:~qdayofmonth~q}")
			parts[i] = parts[i].Replace("TIME_DAYOFYEAR", "${.worldtime:~qdayofyear~q}")
			parts[i] = parts[i].Replace("TIME_DAY", "${.worldtime:~qday~q}")
			parts[i] = parts[i].Replace("TIME_YEARSPLAYED", "${.worldtime:~qyearsplayed~q}")
			parts[i] = parts[i].Replace("TIME_YEAR", "${.worldtime:~qyear~q}")
			parts[i] = parts[i].Replace("TIME_HOUR", "${.worldtime:~qhour~q}")
			parts[i] = parts[i].Replace("TIME_MINUTE", "${.worldtime:~qminute~q}")
			parts[i] = parts[i].Replace("TIME_WEEKDAY", "${.worldtime:~qweekday~q}")
			parts[i] = parts[i].Replace("TIME_SEASON", "${.worldtime:~qseason~q}")
			parts[i] = parts[i].Replace("TIME_MONTH", "${.worldtime:~qmonth~q}")
			parts[i] = parts[i].Replace("TIME_ISNIGHT", "${.worldtime:~qisnight~q}")
			parts[i] = parts[i].Replace("TIME_ISDAWN", "${.worldtime:~qisdawn~q}")
			parts[i] = parts[i].Replace("TIME_ISDAY", "${.worldtime:~qisday~q}")
			parts[i] = parts[i].Replace("TIME_ISDUSK", "${.worldtime:~qisdusk~q}")
			
			parts[i] = parts[i].Replace("}=", "}==") 'replace single "=" sign
		Next
		
		'reconnect things

		if connectors.length = 0
			'ensure to at least wrap it one time! 
			Return "${" + parts[0] + "}"
		ElseIf connectors.length = parts.length - 1 'a CONN b CONN c -> 3 elements, 2 connectors)
			convertSB.SetLength(0)
			convertSB.Append("${")
			For local i:int = 0 until connectors.length
				If connectors[i] = "&&"
					convertSB.append("${.and:")
				Else 'Elseif connectors[i] = "||" - already ensured to only contain && or ||
					convertSB.append("${.or:")
				EndIf

				convertSB.append(parts[i])
				convertSB.append(":")
				convertSB.append(parts[i+1])
				convertSB.append("}")
			Next
			convertSB.append("}")
			Return convertSB.ToString()
		Else
			TLogger.Log("TDatabaseLoader.ConvertOldAvailableScript", "Failed to convert script ~q"+expression+"~q, incorrect expression / too few connectors.", LOG_ERROR)
			Return ""
		Endif
		
	End Function


	Method LoadV3PersonBaseFromNode:TPersonBase(node:TxmlNode, xml:TXmlHelper, isCelebrity:Int=True)
		Local GUID:String = xml.FindValueLC(node,"guid", "")

		'fetch potential meta data
		Local mData:TData = LoadV3PersonBaseMetaDataFromNode(GUID, node, xml, isCelebrity)
		If mData Then metaData.Add(GUID, mData )

		'skip forbidden users (DEV)
		If Not IsAllowedUser(mData.GetString("createdBy"), "person") Then Return Null

		'try to fetch an existing one
		Local person:TPersonBase = GetPersonBaseCollection().GetByGUID(GUID)
		'if the person existed, remove it from all lists and later add
		'it back to the one then suiting. this allows other 
		'database.xml's to morph a insignificant person into a celebrity
		If person
			GetPersonBaseCollection().Remove(person)
			TLogger.Log("LoadV3PersonBaseFromNode()", "Extending PersonBase ~q" + person.GetFullName() + "~q. GUID=" + person.GetGUID(), LOG_XML)
		Else
			person = New TPersonBase
			person.GUID = GUID
		EndIf

		'convert to celebrity if required
		If isCelebrity And Not person.IsCelebrity()
			UpgradePersonBaseData(person)
			person.SetFlag(TVTPersonFlag.CELEBRITY, True)
		EndIf


		'=== COMMON DETAILS ===
		Local data:TDataCSK = New TDataCSK
		If Not _personCommonDetailKeys
			_personCommonDetailKeys = [..
				"first_name", "last_name", "nick_name", "title", "fictional", "levelup", "country", ..
				"job", "gender", "generator", "face_code", "bookable", "castable" ..
			]
		EndIf		
		xml.LoadValuesToDataCSK(node, data, _personCommonDetailKeys)
		
		'country codes:
		'https://en.wikipedia.org/wiki/List_of_ITU_letter_codes


		Local generator:String = data.GetString("generator", "")
		Local p:TPersonGeneratorEntry
		If generator
			p = GetPersonGenerator().GetUniqueDatasetFromString(generator)
			If p
				person.firstName = p.firstName
				person.lastName = p.lastName
				person.countryCode = p.countryCode.ToUpper()
			Else
				person.firstName = GUID
			EndIf

			person.SetFlag(TVTPersonFlag.FICTIONAL, True)
		EndIf

		'override with given ones
		person.firstName = data.GetString("first_name", person.firstName)
		person.lastName = data.GetString("last_name", person.lastName)
		person.nickName = data.GetString("nick_name", person.nickName)
		person.title = data.GetString("title", person.title)
		person.SetFlag(TVTPersonFlag.FICTIONAL, data.GetBool("fictional", person.IsFictional()) )
		'fallback for old database syntax
		person.SetFlag(TVTPersonFlag.CASTABLE, data.GetBool("bookable", person.IsCastable()) )
		person.SetFlag(TVTPersonFlag.CASTABLE, data.GetBool("castable", person.IsCastable()) )
		'cast filtering is mainly done using the bookable flag - not castable implies not bookable
		If Not person.IsCastable() Then person.SetFlag(TVTPersonFlag.BOOKABLE, false )
		person.SetFlag(TVTPersonFlag.CAN_LEVEL_UP, data.GetBool("levelup", person.CanLevelUp()) )
		person.SetJob(data.GetInt("job"))
		person.countryCode = data.GetString("country", person.countryCode).ToUpper()
		person.gender = data.GetInt("gender", person.gender)
		person.faceCode = data.GetString("face_code", person.faceCode)

		'avoid that other persons with that name are generated
		If p
			'take over new name
			p.firstName = person.firstName
			p.lastName = person.lastName
			GetPersonGenerator().ProtectDataset(p)

			'print "generated person : " + person.firstName+" " + person.lastName+" ("+person.countryCode+")" +" GUID="+GUID
		EndIf


		'=== CELEBRITY SPECIFIC DATA ===
		'only for celebrities
		If person.IsCelebrity()
			local pd:TPersonPersonalityData = TPersonPersonalityData(person.GetPersonalityData())
			If not pd 
				person.SetPersonalityData( new TPersonPersonalityData.CopyFromBase( person.GetPersonalityData() ) )
				pd = TPersonPersonalityData(person.GetPersonalityData())
			EndIf


			'=== DETAILS ===
			Local nodeDetails:TxmlNode = xml.FindChildLC(node, "details")
			data.Clear()
			If not _personDetailKeys
				_personDetailKeys = [..
					"gender", "birthday", "deathday", "country", "fictional", "job", "face_code"..
				]
			EndIf
			xml.LoadValuesToDataCSK(nodeDetails, data, _personDetailKeys)

			person.gender = data.GetInt("gender", person.gender)
			person.countryCode = data.GetString("country", person.countryCode).ToUpper()
			pd.SetDayOfBirth( data.GetString("birthday", pd.dayOfBirth) )
			pd.SetDayOfDeath( data.GetString("deathday", pd.dayOfDeath) )
			person.SetJob( data.GetInt("job", person.GetJobs()) )
			'can be defined in "details" or as "<name>" tag
			person.SetFlag(TVTPersonFlag.FICTIONAL, data.GetInt("fictional", person.IsFictional()) )
			person.faceCode = data.GetString("face_code", person.faceCode)

			'=== DATA ===
			Local nodeData:TxmlNode = xml.FindChildLC(node, "data")
			data.Clear()
			If not _personAttributeBaseKeys
				_personAttributeBaseKeys = [ ..
					"price_mod", "topgenre", "affinity", "popularity", "popularity_target" ..
				]
			EndIf
			'copy base attribute keys at the end of a newer and bigger array
			'which stores extended attributes then
			local attributeKeys:String[] = _personAttributeBaseKeys[-(TVTPersonPersonalityAttribute.count * 3)..]
			local attributeIndex:int = 0
			For local i:int = 1 to TVTPersonPersonalityAttribute.count
				local attributeID:Int = TVTPersonPersonalityAttribute.GetAtIndex(i)
				attributeKeys[attributeIndex + 0] = TVTPersonPersonalityAttribute.GetAsString(attributeID)
				attributeKeys[attributeIndex + 1] = attributeKeys[attributeIndex + 0] + "_min"
				attributeKeys[attributeIndex + 2] = attributeKeys[attributeIndex + 0] + "_max"
				attributeIndex :+ 3
			Next
			xml.LoadValuesToDataCSK(nodeData, data, attributeKeys)

			if TPersonProductionData(person.GetProductionData())
				TPersonProductionData(person.GetProductionData()).topGenre = data.GetInt("topgenre", TPersonProductionData(person.GetProductionData()).topGenre)
			EndIf
			
			'0 would mean: cuts price to 0
			If person.GetProductionData().priceModifier = 0 Then person.GetProductionData().priceModifier = 1.0
			person.GetProductionData().priceModifier = data.GetFloat("price_mod", person.GetProductionData().priceModifier)

			if TPersonProductionData(person.GetProductionData())
				TPersonProductionData(person.GetProductionData()).topGenre = data.GetInt("topgenre", TPersonProductionData(person.GetProductionData()).topGenre)
			EndIf


			'ATTRIBUTES
			'create attributes:
			'- for fictional characters
			'- when DB entry defines stuff (do as soon as db defines an attribute

			Local a:TPersonPersonalityAttributes
			For local i:int = 1 to TVTPersonPersonalityAttribute.count
				Local attributeID:Int = TVTPersonPersonalityAttribute.GetAtIndex(i)

				'reuse attributeKeys array
				'Local attributeText:String = TVTPersonPersonalityAttribute.GetAsString(attributeID)
				'Local dbMinValue:Float = data.GetFloat(sb.Append(attributeText).Append("_min").ToString(), -1)
				'Local dbMaxValue:Float = data.GetFloat(sb.Append(attributeText).Append("_max").ToString(), -1)
				local attributeKeyIndex:int = (i-1) * 3
				Local attributeText:String = attributeKeys[attributeKeyIndex]
				Local dbMinValue:Float = data.GetFloat(attributeKeys[attributeKeyIndex + 1], -1)
				Local dbMaxValue:Float = data.GetFloat(attributeKeys[attributeKeyIndex + 2], -1)

				Local dbValue:Float = data.GetFloat(attributeText, -1)

				'only fill attribute if at least a part is defined here
				If not (dbMinValue >= 0 or dbMaxValue >= 0 or dbValue >= 0) Then Continue

				if not a
					'generate if needed, but no randomization
					if not pd.HasAttributes() then pd.InitAttributes(False)
					a = pd.GetAttributes()
				endif

				'The getters automatically generate and randomize the attribute
				'so this is not needed for now
				'If not a.Has(attributeID, -1, -1) Then a.Randomize(attributeID, -1, -1)

				local minValue:Float = 100 * a.GetMin(attributeID, -1, -1)
				local maxValue:Float = 100 * a.GetMax(attributeID, -1, -1)
				local value:Float = 100 * a.Get(attributeID, -1, -1)

				'override with DB definitions (except they are "0")
				'randomized ranges must be adapted accordingly
				If dbMinValue >= 0
					minValue = Min(100, dbMinValue)
					maxValue = Max(maxValue, minValue)
				EndIf
				If dbMaxValue > 0
					maxValue = Min(100, dbMaxValue)
					minValue = Min(maxValue, minValue)
				EndIf
				If dbValue > 0
					value = Min(100, dbValue)
					minValue = Min(value, minValue)
					maxValue = Max(value, maxValue)
				EndIf

				'assign values again
				a.SetMin(0.01 * minValue, attributeID, -1, -1)
				a.SetMax(0.01 * maxValue, attributeID, -1, -1)
				a.Set(0.01 * value, attributeID, -1, -1)

				'print TVTPersonPersonalityAttribute.GetAsString(attributeID) + "  variables: " + value +" ("+minValue+" - " + maxValue+")  attribute: "  +a.Get(attributeID, -1, -1) +" (" + a.GetMin(attributeID, -1, -1) +" - " + a.GetMax(attributeID, -1, -1) +")   direct: " +  a.attributes[attributeID-1].Get() +" ("+ a.attributes[attributeID-1].GetMin() + " - " + a.attributes[attributeID-1].GetMax()+")" + "   hasValue="+hasValue+" hasMinValue="+hasMinValue+" hasMaxValue="+hasMaxValue
			Next
			'ensure all fictional persons have attributes
			If person.IsFictional()
				if not pd.HasAttributes() then pd.InitAttributes(False)
			EndIf

			'HINT: disable this if attributes are to generate on first
			'request to them (so randomized values differ each game)

			'fill not given attributes with random data
			If pd.HasAttributes()
				For local i:int = 1 to TVTPersonPersonalityAttribute.count
					Local attributeID:Int = TVTPersonPersonalityAttribute.GetAtIndex(i)
					If Not pd.GetAttributes().Has(attributeID, -1, -1)
'						If 
						pd.GetAttributes().Randomize(attributeID, -1, -1)
					EndIf
				Next
				pd.GetAttributes().RandomizeAffinity()
			EndIf
			
			If data.Has("affinity")
				If not pd.HasAttributes() then pd.InitAttributes(False)
				pd.GetAttributes().SetAffinity(0.01 * data.GetFloat("affinity"), -1, -1)
			EndIf


			'POPULARITY
			'create after attributes are defined - popularity might
			'depend on them (eg "fame")
			'create/override popularity
			if data.GetInt("popularity", -1000) <> -1000 or data.GetInt("popularity_target", -1000) <> -1000
				local popularityValue:Int = data.GetInt("popularity", -1000) 
				local popularityTarget:Int = data.GetInt("popularity_target", -1000) 
				pd.CreatePopularity(popularityValue, popularityTarget, person)
			endif
		EndIf


		'=== ADD TO COLLECTION ===
		'we removed the person from all lists already, now add it back
		'to the ones it suits
		GetPersonBaseCollection().Add(person)
		
		Return person
	End Method


	Method LoadV3NewsEventTemplateFromNode:TNewsEventTemplate(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValueLC(node,"guid", "")
		Local threadId:String = xml.FindValueLC(node,"thread_guid", "")
		Local doAdd:Int = True

		'fetch potential meta data
		Local mData:TData = LoadV3NewsEventMetaDataFromNode(GUID, node, xml)
		If mData Then metaData.Add(GUID, mData )

		'skip forbidden users (DEV)
		If Not IsAllowedUser(mData.GetString("createdBy"), "newsevent") Then Return Null

		'try to fetch an existing one
		Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(GUID)
		If Not newsEventTemplate
			newsEventTemplate = New TNewsEventTemplate
			newsEventTemplate.title = New TLocalizedString
			newsEventTemplate.description = New TLocalizedString
			newsEventTemplate.GUID = GUID
			newsEventTemplate.threadId = threadId
		Else
			doAdd = False

			TLogger.Log("LoadV3NewsEventTemplateFromNodeFromNode()", "Extending newsEventTemplate ~q"+newsEventTemplate.GetTitle()+"~q. GUID="+newsEventTemplate.GetGUID(), LOG_XML)
		EndIf

		'=== LOCALIZATION DATA ===
		newsEventTemplate.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		newsEventTemplate.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )

		'news type according to TVTNewsType - InitialNews, FollowingNews...
		newsEventTemplate.newsType = xml.FindValueIntLC(node,"type", 0)


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		Local data:TDataCSK = New TDataCSK
		'price and topicality are outdated
		If Not _newsEventDataKeys
			_newsEventDataKeys = [..
				"genre", "price", "quality", "quality_min", "quality_max", "quality_slope", ..
				"available", "flags", "keywords", "happen_time", "min_subscription_level" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(nodeData, data, _newsEventDataKeys)

		newsEventTemplate.flags = data.GetInt("flags", newsEventTemplate.flags)
		newsEventTemplate.genre = data.GetInt("genre", newsEventTemplate.genre)
		newsEventTemplate.keywords = data.GetString("keywords", newsEventTemplate.keywords).ToLower()
		newsEventTemplate.minSubscriptionLevel = data.GetInt("min_subscription_level", newsEventTemplate.minSubscriptionLevel)

		Local available:Int = data.GetBool("available", Not newsEventTemplate.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		newsEventTemplate.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'topicality is "quality" here
		newsEventTemplate.quality = 0.01 * data.GetFloat("quality", 100 * newsEventTemplate.quality)
		newsEventTemplate.qualityMin = 0.01 * data.GetFloat("quality_min", 100 * newsEventTemplate.qualityMin)
		newsEventTemplate.qualityMax = 0.01 * data.GetFloat("quality_max", 100 * newsEventTemplate.qualityMax)
		newsEventTemplate.qualitySlope = 0.01 * data.GetFloat("quality_slope", 100 * newsEventTemplate.qualitySlope)

		'price is "priceModifier" here (so add 1.0 until that is done in DB)
		Local priceMod:Float = data.GetFloat("price", 0)
		If priceMod = 0 Then priceMod = 1.0 'invalid data given
		newsEventTemplate.SetModifier("price", data.GetFloat("price", newsEventTemplate.GetModifier("price")))

		Local happenTimeString:String = data.GetString("happen_time", "")
		If happenTimeString
			Local happenTimeParams:Int[] = StringHelper.StringToIntArray(happenTimeString, ",")
			If happenTimeParams.length > 0
				If happenTimeParams[0] = 0
					newsEventTemplate.happenTime = 0
				ElseIf happenTimeParams[0] <> -1
					'GetWorldTime().CalcTime_Auto(-1, happenTimeParams[0], happenTimeParams[1 ..] )
					Local useParams:Int[] = [-1,-1,-1,-1,-1,-1,-1,-1]
					For Local i:Int = 1 Until happenTimeParams.length
						useParams[i-1] = happenTimeParams[i]
					Next
					newsEventTemplate.happenTime = GetWorldTime().CalcTime_Auto(-1, happenTimeParams[0], useParams )
				EndIf
			EndIf
		EndIf



		'=== AVAILABILITY ===
		If not _newsEventAvailabilityKeys
			_newsEventAvailabilityKeys = [..
				"script", "year_range_from", "year_range_to" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(xml.FindChildLC(node, "availability"), data, _newsEventAvailabilityKeys)
		newsEventTemplate.availableScript = data.GetString("script", newsEventTemplate.availableScript)
		newsEventTemplate.availableYearRangeFrom = data.GetInt("year_range_from", newsEventTemplate.availableYearRangeFrom)
		newsEventTemplate.availableYearRangeTo = data.GetInt("year_range_to", newsEventTemplate.availableYearRangeTo)

		If newsEventTemplate.availableScript
			newsEventTemplate.availableScript = ConvertOldAvailableScript(newsEventTemplate.availableScript)

			Local parsedToken:SToken
			Local result:Int = GameScriptExpression.ParseToTrue(newsEventTemplate.availableScript, newsEventTemplate, parsedToken)
			if parsedToken.id = TK_ERROR
				TLogger.Log("DB", "Script of NewsEventTemplate ~q" + newsEventTemplate.GetGUID() + "~q contains errors:", LOG_WARNING)
				TLogger.Log("DB", "Script: " + newsEventTemplate.availableScript, LOG_WARNING)
				TLogger.Log("DB", "Error : " + parsedToken.GetValueText(), LOG_WARNING)
			EndIf
		EndIf



		'=== TARGETGROUP ATTRACTIVITY MOD ===
		newsEventTemplate.targetGroupAttractivityMod = GetV3TargetgroupAttractivityModFromNode(newsEventTemplate.targetGroupAttractivityMod, node, xml)



		'=== EFFECTS ===
		LoadV3EffectsFromNode(newsEventTemplate, node, xml)



		'=== MODIFIERS ===
		LoadV3ModifiersFromNode(newsEventTemplate, node, xml)



		'=== VARIABLES ===
		Local nodeVariables:TxmlNode = xml.FindChildLC(node, "variables")
		For Local nodeVariable:TxmlNode = EachIn xml.GetNodeChildElements(nodeVariables)
			'each variable is stored as a localizedstring
			Local varName:String = nodeVariable.getName()
			If Not varName Then Continue

			Local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)
			If Not varString Then Continue

			'create if missing
			newsEventTemplate.CreateTemplateVariables()
			newsEventTemplate.templateVariables.AddVariable(varName, varString)
		Next



		'=== ADD TO COLLECTION ===
		If doAdd
			GetNewsEventTemplateCollection().Add(newsEventTemplate)
			If newsEventTemplate.newsType <> TVTNewsType.FollowingNews
				newsCount :+ 1
				Local count:Int[] = totalNewsGenreCount[newsEventTemplate.genre]
				If newsEventTemplate.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)
					'ignore in count
				ElseIf newsEventTemplate.HasFlag(TVTNewsFlag.UNIQUE_EVENT)
					count[0]:+ 1
				Else
					count[1]:+ 1
				EndIf
			EndIf
			totalNewsCount :+ 1
		EndIf

		Return newsEventTemplate
	End Method


	Method LoadV3AchievementFromNode:TAchievement(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValueLC(node,"guid", "")
		Local doAdd:Int = True

		'fetch potential meta data
		Local mData:TData = LoadV3AchievementElementsMetaDataFromNode(GUID, node, xml)
		If mData Then metaData.Add(GUID, mData )

		'try to fetch an existing one
		Local achievement:TAchievement = GetAchievementCollection().GetAchievement(GUID)
		If Not achievement
			achievement = New TAchievement
			achievement.title = New TLocalizedString
			achievement.text = New TLocalizedString
			achievement.GUID = GUID
		Else
			doAdd = False

			If xml.GetNodeChildElements(node).Count() > 0
				TLogger.Log("LoadV3AchievementFromNode()", "Extending achievement ~q"+achievement.GetTitle()+"~q. GUID="+achievement.GetGUID(), LOG_XML)
			EndIf
		EndIf

		'=== LOCALIZATION DATA ===
		achievement.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		achievement.text.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "text")) )

		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChildLC(node, "data")
		Local data:TDataCSK = New TDataCSK
		If Not _achievementDataKeys
			_achievementDataKeys = [..
				"flags", "category", "group", "index", "sprite_finished", "sprite_unfinished" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(nodeData, data, _achievementDataKeys)

		achievement.flags = data.GetInt("flags", achievement.flags)
		achievement.group = data.GetInt("group", achievement.group)
		achievement.index = data.GetInt("index", achievement.index)
		achievement.category = data.GetInt("category", achievement.category)
		achievement.spriteFinished = data.GetString("sprite_finished", achievement.spriteFinished)
		achievement.spriteUnfinished = data.GetString("sprite_unfinished", achievement.spriteUnfinished)


		'=== TASKS ===
		Local nodeTasks:TxmlNode = xml.FindChildLC(node, "tasks")
		For Local nodeElement:TxmlNode = EachIn xml.GetNodeChildElements(nodeTasks)
			If nodeElement.getName().ToLower() <> "task" Then Continue

			LoadV3AchievementElementFromNode("task", achievement, nodeElement, xml)
		Next


		'=== REWARDS ===
		Local nodeRewards:TxmlNode = xml.FindChildLC(node, "rewards")
		For Local nodeElement:TxmlNode = EachIn xml.GetNodeChildElements(nodeRewards)
			If nodeElement.getName().ToLower() <> "reward" Then Continue

			LoadV3AchievementElementFromNode("reward", achievement, nodeElement, xml)
		Next


		'debug
		Rem
		print "==== ACHIEVEMENT ===="
		print achievement.GetTitle()+ " ("+achievement.GetGUID()+")"
		print "  tasks: "+achievement.taskGUIDs.length
		print "  rewards: "+achievement.rewardGUIDs.length
		endrem


		'=== ADD TO COLLECTION ===
		If doAdd
			GetAchievementCollection().AddAchievement(achievement)
			achievementCount :+ 1
			totalAchievementCount :+ 1
		EndIf

		Return achievement
	End Method



	Method LoadV3AchievementElementFromNode:Int(elementName:String="task", source:TAchievement, node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValueLC(node,"guid", "")

		'fetch potential meta data
		Local mData:TData = LoadV3AchievementElementsMetaDataFromNode(GUID, node, xml)
		If mData Then metaData.Add(GUID, mData )

		Local reuseExisting:Int = False

		'skip forbidden users (DEV)
		If Not IsAllowedUser(mData.GetString("createdBy"), "achievement") Then Return Null


		'try to fetch an existing one
		Local element:TAchievementBaseType
		If elementName = "task"
			element = GetAchievementCollection().GetTask(GUID)
		ElseIf elementName = "reward"
			element = GetAchievementCollection().GetReward(GUID)
		EndIf
		If element
			reuseExisting = True

			If xml.GetNodeChildElements(node).Count() > 0
				TLogger.Log("LoadV3AchievementElementFromNode()", "Extending achievement "+elementName+" ~q"+element.GetTitle()+"~q. GUID="+element.GetGUID(), LOG_XML)
			EndIf
		EndIf


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChildLC(node, "data")
		Local data:TData = New TData
		xml.LoadAllValuesToData(nodeData, data)
		'check if the element has all needed configurations
		'for now this is only "type"
		If Not reuseExisting
			If Not data.Has("type") Then ThrowNodeError("DB: <"+elementName+"> is missing ~qtype~q.", nodeData)
		EndIf

		Local elementType:String = data.GetString("type")
		If Not element And Not elementType Then Return False


		If Not element
			element = GetAchievementCollection().CreateElement(elementName+"::"+elementType, data)
			If Not element Then Return False
		EndIf


		If Not reuseExisting
			If Not element.title Then element.title = New TLocalizedString
			If Not element.text Then element.text = New TLocalizedString
			element.SetGUID( GUID )
		EndIf


		'=== LOCALIZATION DATA ===
		If element
			element.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
			element.text.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "text")) )
		EndIf


		If elementName = "task"
			source.AddTask( GUID )
			GetAchievementCollection().AddTask( element )
		ElseIf elementName = "reward"
			source.AddReward( GUID )
			GetAchievementCollection().AddReward( element )
		EndIf


		Return True
	End Method


	Method LoadV3AdContractBaseFromNode:TAdContractBase(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValueLC(node,"guid", "")
		Local doAdd:Int = True

		'fetch potential meta data
		Local mData:TData = LoadV3AdContractBaseMetaDataFromNode(GUID, node, xml)
		If mData Then metaData.Add(GUID, mData )

		'skip forbidden users (DEV)
		If Not IsAllowedUser(mData.GetString("createdBy"), "adcontract") Then Return Null

		'try to fetch an existing one
		Local adContract:TAdContractBase = GetAdContractBaseCollection().GetByGUID(GUID)
		If Not adContract
			adContract = New TAdContractBase
			adContract.title = New TLocalizedString
			adContract.description = New TLocalizedString
			adContract.GUID = GUID
		Else
			doAdd = False
			TLogger.Log("LoadV3AdContractBaseFromNode()", "Extending adContract ~q"+adContract.GetTitle()+"~q. GUID="+adContract.GetGUID(), LOG_XML)
		EndIf



		'=== LOCALIZATION DATA ===
		adContract.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		adContract.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'ad type according to TVTAdContractType - Normal, Ingame, ...
		adContract.adType = xml.FindValueIntLC(node,"type", 0)


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChildLC(node, "data")
		Local data:TDataCSK = New TDataCSK
		If Not _adContractDataKeys
			_adContractDataKeys = [..
				"infomercial", "quality", "repetitions", "fix_price", "duration", ..
			   "profit", "penalty", "pro_pressure_groups", "contra_pressure_groups", ..
			   "infomercial_profit", "fix_infomercial_profit", ..
			   "year_range_from", "year_range_to", "available", "blocks", "type" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(nodeData, data, _adContractDataKeys)

		adContract.infomercialAllowed = data.GetBool("infomercial", adContract.infomercialAllowed)
		adContract.quality = 0.01 * data.GetFloat("quality", adContract.quality * 100.0)

		Local available:Int = data.GetBool("available", Not adContract.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		adContract.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'old -> now stored in "availability
		adContract.availableYearRangeFrom = data.GetInt("year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = data.GetInt("year_range_to", adContract.availableYearRangeTo)

		adContract.adType = data.GetInt("type", adContract.adType)

		adContract.blocks = data.GetInt("blocks", adContract.blocks)
		adContract.spotCount = data.GetInt("repetitions", adContract.spotcount)
		adContract.fixedPrice = data.GetBool("fix_price", adContract.fixedPrice)
		adContract.daysToFinish = data.GetInt("duration", adContract.daysToFinish)
		adContract.proPressureGroups = data.GetInt("pro_pressure_groups", adContract.proPressureGroups)
		adContract.contraPressureGroups = data.GetInt("contra_pressure_groups", adContract.contraPressureGroups)
		adContract.profitBase = data.GetFloat("profit", adContract.profitBase)
		adContract.penaltyBase = data.GetFloat("penalty", adContract.penaltyBase)
		adContract.infomercialProfitBase = data.GetFloat("infomercial_profit", adContract.infomercialProfitBase)
		adContract.fixedInfomercialProfit = data.GetFloat("fix_infomercial_profit", adContract.fixedInfomercialProfit)
		'without data, fall back to 10% of profitBase
		If adContract.infomercialProfitBase = 0 Then adContract.infomercialProfitBase = adContract.profitBase * 0.1



		'=== AVAILABILITY ===
		If Not _adContractAvailabilityKeys
			_adContractAvailabilityKeys = [..
				"script", "year_range_from", "year_range_to" ..
			]
		EndIf		
		'do not reset "data" before - it contains the pressure groups
		xml.LoadValuesToDataCSK(xml.FindChildLC(node, "availability"), data, _adContractAvailabilityKeys)
		adContract.availableScript = data.GetString("script", adContract.availableScript)
		adContract.availableYearRangeFrom = data.GetInt("year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = data.GetInt("year_range_to", adContract.availableYearRangeTo)

		If adContract.availableScript
			adContract.availableScript = ConvertOldAvailableScript(adContract.availableScript)
		
			Local parsedToken:SToken
			Local result:Int = GameScriptExpression.ParseToTrue(adContract.availableScript, adContract, parsedToken)
			if parsedToken.id = TK_ERROR
				TLogger.Log("DB", "Script of AdContract ~q" + adContract.GetGUID() + "~q contains errors:", LOG_WARNING)
				TLogger.Log("DB", "Script: " + adContract.availableScript, LOG_WARNING)
				TLogger.Log("DB", "Error : " + parsedToken.GetValueText(), LOG_WARNING)
			EndIf
		EndIf


		'=== CONDITIONS ===
		Local nodeConditions:TxmlNode = xml.FindChildLC(node, "conditions")
		If Not _adContractConditionKeys
			_adContractConditionKeys = [..
				"min_audience", "min_image", "max_image", "target_group", ..
				"allowed_programme_flag", "allowed_genre", ..
				"prohibited_programme_flag", "prohibited_genre" ..
			]
		EndIf
		'do not reset "data" before - it contains the pressure groups
		xml.LoadValuesToDataCSK(nodeConditions, data, _adContractConditionKeys)
		'0-100% -> 0.0 - 1.0
		adContract.minAudienceBase = 0.01 * data.GetFloat("min_audience", adContract.minAudienceBase*100.0)
		adContract.minImage = 0.01 * data.GetFloat("min_image", adContract.minImage*100.0)
		adContract.maxImage = 0.01 * data.GetFloat("max_image", adContract.maxImage*100.0)
		adContract.limitedToTargetGroup = data.GetInt("target_group", adContract.limitedToTargetGroup)
		adContract.limitedToProgrammeGenre = data.GetInt("allowed_genre", adContract.limitedToProgrammeGenre)
		adContract.limitedToProgrammeFlag = data.GetInt("allowed_programme_flag", adContract.limitedToProgrammeFlag)
		adContract.forbiddenProgrammeGenre = data.GetInt("prohibited_genre", adContract.forbiddenProgrammeGenre)
		adContract.forbiddenProgrammeFlag = data.GetInt("prohibited_programme_flag", adContract.forbiddenProgrammeFlag)
		'if only one group
		'adContract.proPressureGroups = data.GetInt("pro_pressure_groups", adContract.proPressureGroups)
		'adContract.contraPressureGroups = data.GetInt("contra_pressure_groups", adContract.contraPressureGroups)
		Rem
		for multiple groups:
		local proPressureGroups:String[] = data.GetString("pro_pressure_groups", "").Split(" ")
		For local group:string = EachIn proPressureGroups
			if not adContract.HasProPressureGroup(int(group))
				adContract.proPressureGroups :+ [int(group)]
			endif
		Next
		...
		endrem


		'=== EFFECTS ===
		LoadV3EffectsFromNode(adContract, node, xml)



		'=== MODIFIERS ===
		LoadV3ModifiersFromNode(adContract, node, xml)



		'=== ADD TO COLLECTION ===
		If doAdd
			GetAdContractBaseCollection().Add(adContract)
			contractsCount :+ 1
			totalContractsCount :+ 1
		EndIf

		Return adContract
	End Method


	Method LoadV3ProgrammeLicenceFromNode:TProgrammeLicence(node:TxmlNode, xml:TXmlHelper, parentLicence:TProgrammeLicence = Null)
		Local GUID:String = TXmlHelper.FindValueLC(node,"guid", "")
		'referencing an already existing programmedata? Or just use "data-GUID"
		Local dataGUID:String = TXmlHelper.FindValueLC(node,"programmedata_guid", "data-"+GUID)
		'forgot to prepend "data-" ?
		If dataGUID.Find("data-") <> 0 Then dataGUID = "data-"+dataGUID

		'fetch potential meta data
		Local mData:TData = LoadV3ProgrammeLicenceMetaDataFromNode(GUID, node, xml, parentLicence)
		If mData Then metaData.Add(GUID, mData )

		'skip if not "all" are allowed (no creator data available)
		If Not IsAllowedUser(mData.GetString("createdBy"), "programmelicence") Then Return Null



		Local programmeData:TProgrammeData
		Local programmeLicence:TProgrammeLicence
		Local existed:Int

		'=== PROGRAMME DATA ===
		'try to fetch an existing licence with the entries GUID
		programmeLicence = GetProgrammeLicenceCollection().GetByGUID(GUID)

		'check if we reuse an existing programmedata (for series
		'episodes we cannot rely on existence of licences, as they
		'all get added at the end, not on load of an episode)
		programmeData = GetProgrammeDataCollection().GetByGUID(dataGUID)
		If programmeData
			TLogger.Log("LoadV3ProgrammeLicenceFromNode()", "Extending programmeLicence's data ~q"+programmeData.GetTitle()+"~q. dataGUID="+dataGUID+"  GUID="+GUID, LOG_XML)
			'unset cached title again
'			programmeData.titleProcessed = null
			existed = True
		EndIf


		'try to reuse existing configurations or use default ones if no
		'licence/data existed
		Local productType:Int = TVTProgrammeProductType.MOVIE
		If programmeData Then productType = programmeData.productType
		productType = TXmlHelper.FindValueIntLC(node,"product", productType)

		Local licenceType:Int = -1
		If programmeLicence Then licenceType = programmeLicence.licenceType
		licenceType = TXmlHelper.FindValueIntLC(node,"licence_type", licenceType)


		'episode or single element of a collection?
		'(single movies without parent are converted later on)
		If licenceType = -1
			If parentLicence
				If parentLicence.IsSeries()
					Print "autocorrect: "+GUID+" to EPISODE"
					licenceType = TVTProgrammeLicenceType.EPISODE
				Else
					Print "autocorrect: "+GUID+" to SINGLE"
					licenceType = TVTProgrammeLicenceType.SINGLE
				EndIf
			EndIf
		EndIf




		If Not programmeLicence
			If Not programmeData
				'try to clone the parent's data - if that fails, create a new instance;
				'Attention: do not clone target group attractivity as it contains structs.
				'Currently, struct data cannot be cloned with clone().
				'For a series this means that the episodes' attractivity would be 0.0
				'for all target groups due to default struct values.
				If parentLicence programmeData = TProgrammeData(THelper.CloneObject(parentLicence.data, "id targetGroupAttractivityMod"))
				'if failed, create new data
				If Not programmeData Then programmeData = New TProgrammeData

				programmeData.GUID = dataGUID
				programmeData.title = New TLocalizedString
				'programmeData.originalTitle = New TLocalizedString
				programmeData.description = New TLocalizedString
				programmeData.titleProcessed = Null
				programmeData.descriptionProcessed = Null
				programmeData.dataType = 0
			Else
				'reuse old one
				productType = programmeData.productType
			EndIf

			programmeLicence = New TProgrammeLicence
			programmeLicence.GUID = GUID
		Else
			programmeData = programmeLicence.GetData()
			If Not programmeData Then Throw "Loading V3 Programme from XML: Existing programmeLicence without data found."
			TLogger.Log("LoadV3ProgrammeLicenceFromNode()", "Extending programmeLicence ~q"+programmeLicence.GetTitle()+"~q. GUID="+programmeLicence.GetGUID(), LOG_XML)
			'unset cached title again
'			programmeData.titleProcessed = null
		EndIf


		'=== REPAIR INCORRECT DB ===
		'when loading an episode the parentLicenceGUID gets assigned
		'_after_ finished loading the episode data - so if it is set
		'already, this means it got loaded at least to a series before
		'=======
		'ATTENTION: does not work once the DB splits between data and licence!
		'=======
		If parentLicence And programmeLicence.parentLicenceGUID And parentLicence.GetGUID() <> programmeLicence.parentLicenceGUID
			programmeLicence = New TProgrammeLicence
			programmeLicence.GUID = GUID + "-parent-" + parentLicence.GetGUID()
			TLogger.Log("LoadV3ProgrammeLicenceFromNode()", "Auto-corrected duplicate programmelicence: ~q"+programmeLicence.GUID+"~q.", LOG_LOADING)
		EndIf


		'=== ADD PROGRAMME DATA TO LICENCE ===
		'this just overrides the existing data - even if identical
		programmeLicence.SetData(programmeData)


		'=== LOCALIZATION DATA ===
		programmeData.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		'programmeData.originalTitle.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "originalTitle")) )
		programmeData.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChildLC(node, "data")
		Local data:TDataCSK = New TDataCSK
		If Not _programmeLicenceDataKeys
			_programmeLicenceDataKeys = [..
				"country", "distribution", "blocks", "maingenre", "subgenre", ..
				"price_mod", "available", "flags", "licence_flags", ..
				"broadcast_time_slot_start", "broadcast_time_slot_end", ..
				"broadcast_limit", "licence_broadcast_limit", ..
				"broadcast_flags", "licence_broadcast_flags" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(nodeData, data, _programmeLicenceDataKeys)

		programmeData.country = data.GetString("country", programmeData.country)

		programmeData.distributionChannel = data.GetInt("distribution", programmeData.distributionChannel)
		programmeData.blocks = MathHelper.clamp(data.GetInt("blocks", programmeData.blocks), 1, 12)

		programmeData.broadcastTimeSlotStart = MathHelper.clamp(data.GetInt("broadcast_time_slot_start", programmeData.broadcastTimeSlotStart), 0, 23)
		programmeData.broadcastTimeSlotEnd = MathHelper.clamp(data.GetInt("broadcast_time_slot_end", programmeData.broadcastTimeSlotEnd), 0, 23)
		If programmeData.broadcastTimeSlotStart = programmeData.broadcastTimeSlotEnd
			programmeData.broadcastTimeSlotStart = -1
			programmeData.broadcastTimeSlotEnd = -1
		EndIf
		'define same for licence (override later if needed)
		programmeLicence.broadcastTimeSlotStart = programmeData.broadcastTimeSlotStart
		programmeLicence.broadcastTimeSlotEnd = programmeData.broadcastTimeSlotEnd


		programmeData.SetBroadcastLimit(data.GetInt("broadcast_limit", programmeData.broadcastLimit))
		'if not given - disable and fallback to programmeData limit then
		programmeLicence.SetBroadcastLimit(data.GetInt("licence_broadcast_limit", -1))


		programmeData.SetBroadcastFlag(data.GetInt("broadcast_flags", 0))
		'if defined, it overrides (replaces) the data defined broadcast flags 
		'we need to set all flags then as "modified" (manually set)
		Local licenceBroadcastFlags:int = data.GetInt("licence_broadcast_flags", -1)
		if licenceBroadcastFlags >= 0 
			If not programmeLicence.broadcastFlags 
				programmeLicence.broadcastFlags = new TTriStateIntBitmask
			Else
				programmeLicence.broadcastFlags.Reset()
			EndIf
			'mark all settings as manually set
			programmeLicence.broadcastFlags.SetAllModified()
			'activate the flag
			programmeLicence.broadcastFlags.Set(data.GetInt("licence_broadcast_flags"), True)
		endif


		programmeLicence.SetLicenceFlag(data.GetInt("licence_flags", 0))

		'TODO discuss - is it a good idea to use this flag for both licence AND data?
		'data flag has precedence; data not available - licence not available
		'availability effect turns both flags on, but only licence flag off
		Local available:Int = data.GetBool("available", Not programmeData.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		programmeData.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)
		programmeLicence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'compatibility: load price mod from "price_mod" first... later
		'override with "modifiers"-data
		programmeData.SetModifier("price", data.GetFloat("price_mod", programmeData.GetModifier("price")))

		programmeData.SetFlag(data.GetInt("flags", 0))

		programmeData.genre = data.GetInt("maingenre", programmeData.genre)
		For Local sg:String = EachIn data.GetString("subgenre", "").split(",")
			If Trim(sg) = "" Then Continue
			If Int(sg) < 0 Then Continue

			If Not MathHelper.InIntArray(Int(sg), programmeData.subGenres)
				programmeData.subGenres :+ [Int(sg)]
			EndIf
		Next


		'=== RELEASE INFORMATION ===
		Local releaseData:TDataCSK = New TDataCSK
		'try to load it from the "<data>" block
		'(this is done to allow the old v3-"year" definition)
		If Not _programmeLicenceDataTimeFieldsKeys
			_programmeLicenceDataTimeFieldsKeys = [..
				"year", "year_relative", "year_relative_min", "year_relative_max", ..
				"day", "day_random_min", "day_random_max", "day_random_slope", ..
				"hour", "hour_random_min", "hour_random_max", "hour_random_slope" ..
			]
		EndIf	
		xml.LoadValuesToDataCSK(nodeData, releaseData, _programmeLicenceDataTimeFieldsKeys)
		'override data by a <releaseTime> block
		Local releaseTimeNode:TxmlNode = xml.FindChildLC(node, "releasetime")
		If releaseTimeNode
			xml.LoadValuesToDataCSK(releaseTimeNode, releaseData, _programmeLicenceDataTimeFieldsKeys)
		EndIf

		'convert various time definitions to an absolute time
		'(this relies on "GetWorldTime()" being initialized already with
		' the game time)
		programmeData.releaseTime = CreateReleaseTime(releaseData, programmeData.releaseTime)
		If programmeData.releaseTime <= 0
			TLogger.Log("TDatabase.CreateReleaseTime()", "Failed to create releaseTime for ~q"+programmeData.GetTitle()+"~q. (GUID: ~q"+GUID+"~q.)", LOG_ERROR)
		EndIf

		'=== STAFF ===
		Local nodeStaff:TxmlNode = xml.FindChildLC(node, "staff")
		For Local nodeMember:TxmlNode = EachIn xml.GetNodeChildElements(nodeStaff)
			If nodeMember.getName().ToLower() <> "member" Then Continue

			Local memberIndex:Int = xml.FindValueIntLC(nodeMember, "index", -1)
			Local memberFunction:Int = xml.FindValueIntLC(nodeMember, "function", 0)
			Local memberGenerator:String = xml.FindValueLC(nodeMember, "generator", "")
			Local jobRoleGUID:String = xml.FindValueLC(nodeMember, "role_guid", "")
			Local jobRoleID:Int = 0
			If jobRoleGUID
				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(jobRoleGUID)
				If role
					jobRoleID = role.GetID()
				EndIf
			EndIf
			Local memberGUID:String = nodeMember.GetContent().Trim()

			Local member:TPersonBase
			If memberGUID Then member = GetPersonBaseCollection().GetByGUID(memberGUID)
			'create a person so jobs could get added to persons
			'which are created after that programme
			If Not member
				member = New TPersonBase
				Local memberFictional:Int = True
				If mdata Then memberFictional = mdata.GetInt("fictional", 0)
				member.SetFlag(TVTPersonFlag.FICTIONAL, memberFictional)

				If memberGenerator
					'generator is "countrycode1 countrycode2, gender, levelup"
					Local parts:String[] = memberGenerator.Split(",")
					Local levelUp:Int = False
					If parts.length >= 3 And Int(parts[2]) = 1 Then levelUp = True
					Local p:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDatasetFromString(memberGenerator)
					If p
						'avoid that other persons with that name are generated
						GetPersonGenerator().ProtectDataset(p)
						member.firstName = p.firstName
						member.lastName = p.lastName
						member.countryCode = p.countryCode.ToUpper()
					EndIf
				EndIf


				If Not memberGUID
					memberGUID = "person-created"
					memberGUID :+ "-" + LSet(Hashes.MD5(member.firstName + member.lastName), 12)
					memberGUID :+ "-" + StringHelper.UTF8toISO8859(member.firstName).Replace(".", "").Replace(" ","-")
					memberGUID :+ "-" + StringHelper.UTF8toISO8859(member.lastName).Replace(".", "").Replace(" ","-")
				EndIf

				If Not memberGenerator And member.firstName = ""
					member.firstName = memberGUID
				EndIf

				'if memberGenerator
				'	print "generated person : " + member.firstName+" " + member.lastName +" ("+member.countryCode+")" + " GUID="+memberGUID
				'endif

				member.SetGUID(memberGUID)
				GetPersonBaseCollection().Add(member)
			EndIf

			'member now is capable of doing this job
			member.SetJob(memberFunction)

			'add cast
			programmeData.AddCast(New TPersonProductionJob.Init(member.GetID(), memberFunction, member.gender, member.countryCode, jobRoleID), memberIndex)
		Next



		'=== GROUPS ===
		Local nodeGroups:TxmlNode = xml.FindChildLC(node, "groups")
		data.Clear()
		If Not _programmeLicenceDataGroupsKeys
			_programmeLicenceDataGroupsKeys = [..
				"target_groups", "pro_pressure_groups", "contra_pressure_groups" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(nodeGroups, data, _programmeLicenceDataGroupsKeys)
		programmeData.targetGroups = data.GetInt("target_groups", programmeData.targetGroups)
		programmeData.proPressureGroups = data.GetInt("pro_pressure_groups", programmeData.proPressureGroups)
		programmeData.contraPressureGroups = data.GetInt("contra_pressure_groups", programmeData.contraPressureGroups)



		'=== TARGETGROUP ATTRACTIVITY MOD ===
		programmeData.targetGroupAttractivityMod = GetV3TargetgroupAttractivityModFromNode(programmeData.targetGroupAttractivityMod, node, xml)


		'=== EFFECTS ===
		'TODO discuss parent effects are copied, if they are wanted only in one episode
		'then define them only there
		If parentLicence Then programmeLicence.effects = parentLicence.CopyEffects()
		'TODO discuss - should effects be part of licence or data
		'I think, the effects should depend only on the licence and not be propagated
		LoadV3EffectsFromNode(programmeLicence, node, xml)



		'=== MODIFIERS ===
		'take over modifiers from parent (if episode)
		LoadV3ModifiersFromNode(programmeData, node, xml)



		'=== RATINGS ===
		Local nodeRatings:TxmlNode = xml.FindChildLC(node, "ratings")
		data.Clear()
		If Not _programmeLicenceRatingsKeys
			_programmeLicenceRatingsKeys = [..
				"critics", "speed", "outcome" ..
			]
		EndIf
		xml.LoadValuesToDataCSK(nodeRatings, data, _programmeLicenceRatingsKeys)
		programmeData.review = 0.01 * data.GetFloat("critics", programmeData.review*100)
		programmeData.speed = 0.01 * data.GetFloat("speed", programmeData.speed*100)
		programmeData.outcome = 0.01 * data.GetFloat("outcome", programmeData.outcome*100)

		'auto repair outcome for non-custom productions
		'(eg. predefined ones from the DB)
		If Not programmeData.IsAPlayersCustomProduction() Then programmeData.FixOutcome()



		'=== PRODUCT TYPE ===
		programmeData.productType = productType



		'=== LICENCE TYPE ===
		'the licenceType is adjusted as soon as "AddData" was used
		'so correct it if needed
		If parentLicence And licenceType = TVTProgrammeLicenceType.UNKNOWN
			licenceType = TVTProgrammeLicenceType.EPISODE
		EndIf
		programmeLicence.licenceType = licenceType
		programmeData.dataType = licenceType

		'=== EPISODES ===
		Local nodeEpisodes:TxmlNode = xml.FindChildLC(node, "children")
		For Local nodeEpisode:TxmlNode = EachIn xml.GetNodeChildElements(nodeEpisodes)
			'skip other elements than programme data
			If nodeEpisode.getName().ToLower() <> "programme" Then Continue

			'if until now the licence type was not defined, define it now
			'-> collections cannot get autorecognized, they NEED to get
			'   defined correctly
			If licenceType = -1
				Print "autocorrect: "+GUID+" to SERIES HEADER"
				licenceType = TVTProgrammeLicenceType.SERIES
				programmeData.dataType = TVTProgrammeDataType.SERIES
			EndIf

			'recursively load the episode - parent is the new programmeLicence
			Local episodeLicence:TProgrammeLicence = LoadV3ProgrammeLicenceFromNode(nodeEpisode, xml, programmeLicence)

			'the episodeNumber is currently not needed, as we
			'autocalculate it by the position in the xml-episodes-list
			'local episodeNumber:int = xml.FindValueIntLC(nodeEpisode, "index", -1)
			Local episodeNumber:Int = -1

			'only add episode if not already done
			If programmeLicence = episodeLicence.GetParentLicence()
				TLogger.Log("LoadV3ProgrammeLicenceFromNode()","Episode: ~q"+episodeLicence.GetTitle()+"~q already added to series: ~q"+episodeLicence.GetParentLicence().GetTitle()+"~q. Skipped.", LOG_XML)
				Continue
			EndIf

			'inform if we add an episode again
			If episodeLicence.GetParentLicence() And episodeLicence.parentLicenceGUID
				TLogger.Log("LoadV3ProgrammeLicenceFromNode()","Episode: ~q"+episodeLicence.GetTitle()+"~q already has parent: ~q"+episodeLicence.GetParentLicence().GetTitle()+"~q. Multi-usage intended?", LOG_XML)
			EndIf

			'mark the parent licence/data to be a "header"
			programmeLicence.data.dataType = TVTProgrammeDataType.SERIES
			programmeLicence.licenceType = TVTProgrammeLicenceType.SERIES

			'add the episode
			programmeLicence.AddSubLicence(episodeLicence, episodeNumber)
		Next

		If programmeLicence.isSeries() And programmeLicence.GetSubLicenceCount() = 0
			programmeLicence.licenceType = TVTProgrammeLicenceType.SINGLE
			programmeLicence.data.dataType = TVTProgrammeDataType.SINGLE
			TLogger.Log("LoadV3ProgrammeLicenceFromNode()","Series with 0 episodes found. Converted to single: "+programmeLicence.GetTitle(), LOG_XML)
		EndIf

		If programmeLicence.licenceType = -1 And programmeLicence.GetSubLicenceCount() = 0
			programmeLicence.licenceType = TVTProgrammeLicenceType.SINGLE
			programmeLicence.data.dataType = TVTProgrammeDataType.SINGLE
			TLogger.Log("LoadV3ProgrammeLicenceFromNode()","Licence without licenceType=-1 found.  Converted to single: "+programmeLicence.GetTitle(), LOG_XML)
		EndIf


		Rem
		for multiple groups:
		local proPressureGroups:String[] = data.GetString("pro_pressure_groups", "").Split(" ")
		For local group:string = EachIn proPressureGroups
			if not adContract.HasProPressureGroup(int(group))
				adContract.proPressureGroups :+ [int(group)]
			endif
		Next
		endrem

		'=== ADD PROGRAMMEDATA TO COLLECTION ===
		'when reaching this point, nothing stopped the creation of this
		'licence ... so add this specific programmeData to the global
		'data collection
		GetProgrammeDataCollection().Add(programmeData)

		If Not existed
			programmeLicence.SetOwner(TOwnedGameObject.OWNER_NOBODY)
		EndIf

		If GameRules.randomizeLicenceAttributes
			RandomizeLicenceData(programmeLicence)
		EndIf
		Return programmeLicence
	End Method

	Method RandomizeLicenceData:Int(licence:TProgrammeLicence)
		If licence and licence.GetSubLicenceCount() = 0
			local data:TProgrammeData = licence.GetData()
			If data
				local reviewOld:Float = data.review
				local speedOld:Float = data.speed
				local outcomeOld:Float = data.outcome
				local priceOld:Float = data.getModifier("price")

				local reviewNew:Float  = MathHelper.clamp(rndValue(reviewOld, "REVIEW"))
				local speedNew:Float   = MathHelper.clamp(rndValue(speedOld, "SPEED"))
				'outcome may not be defined (0) in which case it is interpreted differently
				'hence old value or new value 0 must not lead to a change
				local outcomeNew:Float = MathHelper.clamp(rndValue(outcomeOld, "OUTCOME", 0, False))
				local priceNew:Float   = MathHelper.clamp(rndValue(priceOld, "PRICE", 1), 0.1, 2)

				rem
				TLogger.Log("DB","randomizing " +licence.getTitle(), LOG_DEBUG)
				TLogger.Log("DB","  review : " + reviewOld + " -> " + reviewNew, LOG_DEBUG)
				TLogger.Log("DB","  speed  : " + speedOld + " -> " + speedNew, LOG_DEBUG)
				TLogger.Log("DB","  outcome: " + outcomeOld + " -> " + outcomeNew, LOG_DEBUG)
				TLogger.Log("DB","  price: " + priceOld + " -> " + priceNew, LOG_DEBUG)
				endrem

				data.review = reviewNew
				data.speed = speedNew
				data.outcome = outcomeNew
				data.setModifier("price", priceNew)
			EndIF
		Endif
		Function rndValue:Float(oldValue:Float, key:String, rndType:Int = 0, zeroChangeAllowed:Int=True)
			Local base:Int = GameRules.devConfig.GetInt("DEV_DATABASE_LICENCE_RANDOM_"+key, 0)
			If base > 0
				Local newValue:Float
				If rndType = 0
					base = (1.05 - (abs(0.5 - oldValue) / 0.5)) * base
				EndIf
				newValue = oldValue + (RandRange(0, base * 2) - base) * 0.01
				If zeroChangeAllowed Or (oldValue > 0 and newValue > 0) Then return newValue
			EndIf
			return oldValue
		EndFunction
	End Method

	Method LoadV3ScriptTemplateFromNode:TScriptTemplate(node:TxmlNode, xml:TXmlHelper, parentScriptTemplate:TScriptTemplate = Null)
		Local GUID:String = TXmlHelper.FindValue(node,"guid", "")
		Local scriptProductType:Int = TXmlHelper.FindValueIntLC(node,"product", 1)
		Local oldType:Int = TXmlHelper.FindValueIntLC(node,"type", TVTProgrammeLicenceType.SINGLE)
		Local scriptLicenceType:Int = TXmlHelper.FindValueIntLC(node,"licence_type", oldType)
		Local index:Int = TXmlHelper.FindValueIntLC(node,"index", 0)
		Local scriptTemplate:TScriptTemplate

		'fetch potential meta data
		Local mData:TData = LoadV3ScriptTemplateMetaDataFromNode(GUID, node, xml, parentScriptTemplate)
		If mData Then metaData.Add(GUID, mData )

		'skip forbidden users (DEV)
		If Not IsAllowedUser(mData.GetString("createdBy"), "adcontract") Then Return Null

		'=== SCRIPTTEMPLATE DATA ===
		'try to fetch an existing template with the entries GUID
		scriptTemplate = GetScriptTemplateCollection().GetByGUID(GUID)
		If Not scriptTemplate
			'try to clone the parent, if that fails, create a new instance
			If parentScriptTemplate
				scriptTemplate = TScriptTemplate(THelper.CloneObject(parentScriptTemplate, "id guid jobs"))
				'#440 optional flags are not propagated to episode templates
				scriptTemplate.flagsOptional = 0
				'jobs must not be cloned, the same instances must be used for all templates, so that random roles are propagated
				scriptTemplate.jobs = parentScriptTemplate.jobs[ .. ] 'complete copy of the array
			EndIf
			If Not scriptTemplate
				scriptTemplate = New TScriptTemplate
			EndIf

			scriptTemplate.GUID = GUID
			scriptTemplate.title = New TLocalizedString
			scriptTemplate.description = New TLocalizedString
			'DO NOT reuse certain parts of the parent (getters take
			'care of this already)
			scriptTemplate.templateVariables = Null
			scriptTemplate.subScripts = New TScriptTemplate[0]
			scriptTemplate.parentScriptID = 0
		EndIf

		If parentScriptTemplate
			scriptTemplate.parentScriptID = parentScriptTemplate.GetID()
		EndIf


		'=== LOCALIZATION DATA ===
		scriptTemplate.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		scriptTemplate.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )



		'=== DATA ELEMENTS ===
		Local nodeData:TxmlNode
		Local data:TData


		'=== DATA: GENRES ===
		nodeData = xml.FindChildLC(node, "genres")
		data = New TData
		xml.LoadValuesToData(nodeData, data, ["mainGenre", "subGenres"])
		scriptTemplate.mainGenre = data.GetInt("mainGenre", scriptTemplate.mainGenre)
		For Local sg:String = EachIn data.GetString("subGenres", "").split(",")
			'skip empty or "undefined" genres
			If Int(sg) = 0 Then Continue
			If Not MathHelper.InIntArray(Int(sg), scriptTemplate.subGenres)
				scriptTemplate.subGenres :+ [Int(sg)]
			EndIf
		Next



		'=== DATA: RATINGS - OUTCOME ===
		nodeData = xml.FindChildLC(node, "outcome")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Float = 0.01 * data.GetInt("value", Int(100 * scriptTemplate.outcomeMin))
			scriptTemplate.SetOutcomeRange(value, value, 0.5)
		Else
			scriptTemplate.SetOutcomeRange( ..
				0.01 * data.GetInt("min", Int(100 * scriptTemplate.outcomeMin)), ..
				0.01 * data.GetInt("max", Int(100 * scriptTemplate.outcomeMax)), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.outcomeSlope)) ..
			)
		EndIf

		'=== DATA: RATINGS - REVIEW ===
		nodeData = xml.FindChildLC(node, "review")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Float = 0.01 * data.GetInt("value", Int(100 * scriptTemplate.reviewMin))
			scriptTemplate.SetReviewRange(value, value, 0.5)
		Else
			scriptTemplate.SetReviewRange( ..
				0.01 * data.GetInt("min", Int(100 * scriptTemplate.reviewMin)), ..
				0.01 * data.GetInt("max", Int(100 * scriptTemplate.reviewMax)), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.reviewSlope)) ..
			)
		EndIf

		'=== DATA: RATINGS - SPEED ===
		nodeData = xml.FindChildLC(node, "speed")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Float = 0.01 * data.GetInt("value", Int(100 * scriptTemplate.speedMin))
			scriptTemplate.SetSpeedRange(value, value, 0.5)
		Else
			scriptTemplate.SetSpeedRange( ..
				0.01 * data.GetInt("min", Int(100 * scriptTemplate.speedMin)), ..
				0.01 * data.GetInt("max", Int(100 * scriptTemplate.speedMax)), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.speedSlope)) ..
			)
		EndIf

		'=== DATA: RATINGS - POTENTIAL ===
		nodeData = xml.FindChildLC(node, "potential")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Float = 0.01 * data.GetInt("value", Int(100 * scriptTemplate.potentialMin))
			scriptTemplate.SetPotentialRange(value, value, 0.5)
		Else
			scriptTemplate.SetPotentialRange( ..
				0.01 * data.GetInt("min", Int(100 * scriptTemplate.potentialMin)), ..
				0.01 * data.GetInt("max", Int(100 * scriptTemplate.potentialMax)), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.potentialSlope)) ..
			)
		EndIf


		'=== DATA: BLOCKS ===
		nodeData = xml.FindChildLC(node, "blocks")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Int = data.GetInt("value", scriptTemplate.blocksMin)
			scriptTemplate.SetBlocksRange(value, value, 0.5)
		Else
			scriptTemplate.SetBlocksRange( ..
				data.GetInt("min", scriptTemplate.blocksMin), ..
				data.GetInt("max", scriptTemplate.blocksMax), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.blocksSlope)) ..
			)
		EndIf

		'=== DATA: PRICE ===
		nodeData = xml.FindChildLC(node, "price")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Int = data.GetInt("value", scriptTemplate.priceMin)
			scriptTemplate.SetPriceRange(value, value, 0.5)
		Else
			scriptTemplate.SetPriceRange( ..
				data.GetInt("min", scriptTemplate.priceMin), ..
				data.GetInt("max", scriptTemplate.priceMax), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.priceSlope)) ..
			)
		EndIf

		'=== DATA: STUDIO SIZE ===
		nodeData = xml.FindChildLC(node, "studio_size")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Int = data.GetInt("value", scriptTemplate.studioSizeMin)
			scriptTemplate.SetStudioSizeRange(value, value, 0.5)
		Else
			scriptTemplate.SetStudioSizeRange( ..
				data.GetInt("min", scriptTemplate.studioSizeMin), ..
				data.GetInt("max", scriptTemplate.studioSizeMin), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.studioSizeSlope)) ..
			)
		EndIf

		'=== DATA: PRODUCTION TIME ===
		nodeData = xml.FindChildLC(node, "production_time")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			scriptTemplate.productionTime =  TWorldTime.MINUTELENGTH * data.GetInt("value", int(scriptTemplate.productionTime / TWorldTime.MINUTELENGTH))
		Else
			'we cannot simply place the min/max as default as "-1 / TWorldTime.MINUTELENGTH" results in 0 ...
			local pTMin:Int = data.GetInt("min", -1)
			local pTMax:Int = data.GetInt("max", -1)
			if pTMin >= 0 Then scriptTemplate.productionTimeMin = TWorldTime.MINUTELENGTH * pTMin
			if pTMax >= 0 Then scriptTemplate.productionTimeMax = TWorldTime.MINUTELENGTH * pTMax
			scriptTemplate.productionTimeSlope = 0.01 * data.GetFloat("slope", 100 * scriptTemplate.productionTimeSlope)
		EndIf

		'=== DATA: JOBS ===
		nodeData = xml.FindChildLC(node, "jobs")
		For Local nodeJob:TxmlNode = EachIn xml.GetNodeChildElements(nodeData)
			If nodeJob.getName() <> "job" Then Continue

			'the job index is only relevant to children/episodes in the
			'case of a partially overridden cast

			Local jobIndex:Int = xml.FindValueIntLC(nodeJob, "index", -1)
			Local jobFunction:Int = xml.FindValueIntLC(nodeJob, "function", 0)
			Local jobRequired:Int = xml.FindValueIntLC(nodeJob, "required", 0)
			Local jobGender:Int = xml.FindValueIntLC(nodeJob, "gender", 0)
			Local jobCountry:String = xml.FindValueLC(nodeJob, "country", "")
			'for actor jobs this defines if a specific role is defined
			Local jobRoleGUID:String = xml.FindValueLC(nodeJob, "role_guid", "")
			Local jobRandomRole:Int = xml.FindValueIntLC(nodeJob, "random_role", 0)
			Local jobPreselectCast:String = xml.FindValueLC(nodeJob, "person", "")

			If jobRandomRole
				jobRandomRole = 1
				'overriding job must be reset on child reset!
				If parentScriptTemplate Then jobRandomRole = 2
				jobRoleGUID=""
			EndIf
			Local jobRoleID:Int = 0
			If jobRoleGUID
				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(jobRoleGUID)
				If Not role
					role = New TProgrammeRole
					role.SetGUID(GUID)
					GetProgrammeRoleCollection().Add(role)
				EndIf
				jobRoleID = role.GetID()
			EndIf

			'create a job without an assigned person
			Local job:TPersonProductionJob = New TPersonProductionJob.Init(0, jobFunction, jobGender, jobCountry, jobRoleID)
			job.randomRole = jobRandomRole
			job.preselectCast = jobPreselectCast
			If jobRequired = 0
				'check if the job has to override an existing one
				If jobIndex >= 0 And scriptTemplate.GetRandomJobAtIndex(jobIndex)
					scriptTemplate.SetRandomJobAtIndex(jobIndex, job)
				Else
					scriptTemplate.AddRandomJob(job)
				EndIf
			Else
				'check if the job has to override an existing one
				If jobIndex >= 0 And scriptTemplate.GetJobAtIndex(jobIndex)
					scriptTemplate.SetJobAtIndex(jobIndex, job)
				Else
					scriptTemplate.AddJob(job)
				EndIf
			EndIf
		Next


		'=== VARIABLES ===
		'create if missing, create even without "<variables>" as the script
		'might reference parental variables
		scriptTemplate.CreateTemplateVariables()

		Local nodeVariables:TxmlNode = xml.FindChildLC(node, "variables")
		For Local nodeVariable:TxmlNode = EachIn xml.GetNodeChildElements(nodeVariables)
			'each variable is stored as a localizedstring
			Local varName:String = nodeVariable.getName()
			Local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)

			'skip invalid
			If Not varName Or Not varString Then Continue

			scriptTemplate.templateVariables.AddVariable(varName, varString)
		Next


		'=== SCRIPT - PRODUCT TYPE ===
		scriptTemplate.scriptProductType = scriptProductType

		'=== SCRIPT - LICENCE TYPE ===
		If parentScriptTemplate And scriptLicenceType = TVTProgrammeLicenceType.UNKNOWN
			scriptLicenceType = TVTProgrammeLicenceType.EPISODE
		EndIf
		scriptTemplate.scriptLicenceType = scriptLicenceType


		'=== SCRIPT - MISC ===
		nodeData = xml.FindChildLC(node, "data")
		data = New TData
		xml.LoadValuesToData(nodeData, data, [..
			"scriptflags", "flags", "flags_optional", "keywords", "studio_size", ..
			"production_broadcast_flags", "production_licence_flags", "production_broadcast_limit", ..
			"live_date", "live_time", ..
			"target_groups", "target_groups_optional", ..
			"broadcast_time_slot_start", "broadcast_time_slot_end", ..
			"production_limit", "production_time_mod", ..
			"available"..
		])
		scriptTemplate.scriptFlags = data.GetInt("scriptflags", scriptTemplate.scriptFlags)
		If Not data.GetInt("available", True)
			scriptTemplate.setScriptFlag(TVTScriptFlag.NOT_AVAILABLE, True)
		EndIf

		scriptTemplate.flags = data.GetInt("flags", scriptTemplate.flags)
		scriptTemplate.flagsOptional = data.GetInt("flags_optional", scriptTemplate.flagsOptional)
		scriptTemplate.liveDateCode = data.GetString("live_date", scriptTemplate.liveDateCode)
		scriptTemplate.broadcastTimeSlotStart = data.GetInt("broadcast_time_slot_start", scriptTemplate.broadcastTimeSlotStart)
		scriptTemplate.broadcastTimeSlotEnd = data.GetInt("broadcast_time_slot_end", scriptTemplate.broadcastTimeSlotEnd)
		
		scriptTemplate.targetGroup = data.GetInt("target_groups", scriptTemplate.targetGroup)
		scriptTemplate.targetGroupOptional = data.GetInt("target_groups_optional", scriptTemplate.targetGroupOptional)

		If data.Has("studio_size")
			scriptTemplate.studioSizeMin = data.GetInt("studio_size")
			scriptTemplate.studioSizeMax = data.GetInt("studio_size")
			scriptTemplate.studioSizeSlope = 0.5
		Endif

		scriptTemplate.keywords = data.GetString("keywords", scriptTemplate.keywords).Trim()

		scriptTemplate.productionLimit = data.GetInt("production_limit", scriptTemplate.productionLimit)
		scriptTemplate.productionLimitMax = scriptTemplate.productionLimit

		scriptTemplate.productionBroadcastFlags = data.GetInt("production_broadcast_flags", scriptTemplate.productionBroadcastFlags)
		scriptTemplate.productionLicenceFlags = data.GetInt("production_licence_flags", scriptTemplate.productionLicenceFlags)
		scriptTemplate.SetProductionBroadcastLimit( data.GetInt("production_broadcast_limit", scriptTemplate.GetProductionBroadcastLimit()) )

		scriptTemplate.productionTimeModBase = 0.01 * data.GetFloat("production_time_mod", 100*scriptTemplate.productionTimeModBase)

		'=== AVAILABILITY ===
		xml.LoadValuesToData(xml.FindChildLC(node, "availability"), data, [..
			"script", "year_range_from", "year_range_to" ..
		])
		scriptTemplate.availableScript = data.GetString("script", scriptTemplate.availableScript)
		scriptTemplate.availableYearRangeFrom = data.GetInt("year_range_from", scriptTemplate.availableYearRangeFrom)
		scriptTemplate.availableYearRangeTo = data.GetInt("year_range_to", scriptTemplate.availableYearRangeTo)

		If scriptTemplate.availableScript
			scriptTemplate.availableScript = ConvertOldAvailableScript(scriptTemplate.availableScript)

			Local parsedToken:SToken
			Local result:Int = GameScriptExpression.ParseToTrue(scriptTemplate.availableScript, scriptTemplate, parsedToken)
			if parsedToken.id = TK_ERROR
				TLogger.Log("DB", "Script of ScriptTemplate ~q" + scriptTemplate.GetGUID() + "~q contains errors:", LOG_WARNING)
				TLogger.Log("DB", "Script: " + scriptTemplate.availableScript, LOG_WARNING)
				TLogger.Log("DB", "Error : " + parsedToken.GetValueText(), LOG_WARNING)
			EndIf
		EndIf

		Rem
			auto correction cannot be done this way, as a show could
			be also defined having multiple episodes or a reportage
		'correct if contains episodes or is episode
		if scriptTemplate.GetSubScriptTemplateCount() > 0
			scriptTemplate.scriptLicenceType = TVTProgrammeLicenceType.SERIES
		else
			'defined a parent - must be a episode
			if scriptTemplate.parentScriptTemplateGUID <> ""
				scriptTemplate.scriptLicenceType = TVTProgrammeLicenceType.EPISODE
			elseif
			if scriptTemplate.parentScriptTemplateGUID <> ""
			endif
		endif
		endrem

		'read modifiers
		Local nodeModifiers:TxmlNode = xml.FindChildLC(node, "programme_data_modifiers")
		For Local nodeModifier:TxmlNode = EachIn xml.GetNodeChildElements(nodeModifiers)
			If nodeModifier.getName() <> "modifier" Then Continue

			Local modifierData:TData = New TData
			xml.LoadAllValuesToData(nodeModifier, modifierData)
			'check if the modifier has all needed definitions
			If Not modifierData.Has("name") Then ThrowNodeError("DB: <modifier> is missing ~qname~q.", nodeModifier)
			If Not modifierData.Has("value") Then ThrowNodeError("DB: <modifier> is missing ~qvalue~q.", nodeModifier)

			if not scriptTemplate.programmeDataModifiers then scriptTemplate.programmeDataModifiers = new TData
			scriptTemplate.programmeDataModifiers.Add(modifierData.GetString("name"), modifierData.GetFloat("value"))
			'source.SetModifier(modifierData.GetString("name"), modifierData.GetFloat("value"))
		Next

		'=== TARGETGROUP ATTRACTIVITY MOD ===
		scriptTemplate.targetGroupAttractivityMod = GetV3TargetgroupAttractivityModFromNode(null, node, xml)

		'=== EPISODES ===
		'load children _after_ element is configured
		Local nodeChildren:TxmlNode = xml.FindChildLC(node, "children")
		For Local nodeChild:TxmlNode = EachIn xml.GetNodeChildElements(nodeChildren)
			'skip other elements than scripttemplate
			If nodeChild.getName() <> "scripttemplate" Then Continue

			'recursively load the child script - parent is the new scriptTemplate
			Local childScriptTemplate:TScriptTemplate = LoadV3ScriptTemplateFromNode(nodeChild, xml, scriptTemplate)
			'the childIndex is currently not needed, as we autocalculate
			'it by the position in the xml-episodes-list
			'local childIndex:int = xml.FindValueIntLC(nodechild, "index", 1)

			'add the child
			scriptTemplate.AddSubScript(childScriptTemplate)
		Next


		'=== DATA: EPISODES ===
		'load episode data only after creating the children as these values must
		'not be propagated to the children
		nodeData = xml.FindChildLC(node, "episodes")
		data = xml.LoadValuesToData(nodeData, New TData, ["min", "max", "slope", "value"])
		If data.GetInt("value", -1) >= 0
			Local value:Int = data.GetInt("value", scriptTemplate.episodesMin)
			scriptTemplate.SetEpisodesRange(value, value, 0.5)
		Else
			scriptTemplate.SetEpisodesRange( ..
				data.GetInt("min", scriptTemplate.episodesMin), ..
				data.GetInt("max", scriptTemplate.episodesMax), ..
				0.01 * data.GetInt("slope", Int(100 * scriptTemplate.episodesSlope)) ..
			)
		EndIf


		'=== EFFECTS ===
		'add effects after processing the children
		'as script template does not extend TBroadcastMaterialSourceBase,
		'propagating parent effects is to big an effort here
		'it will be done when creating the script from the template
		'at this point each template gets exactly the effects defined in the database
		Local nodeEffects:TxmlNode = xml.FindChildLC(node, "effects")
		If nodeEffects
			Local tmpSource:TBroadcastMaterialSourceBase = new TBroadcastMaterialSourceBase()
			LoadV3EffectsFromNode(tmpSource, node, xml)
			If tmpSource.effects Then scriptTemplate.effects = tmpSource.effects.Copy()
			'If scriptTemplate.effects Then print scriptTemplate.GetTitle() +" has effects"
		EndIf

		'=== ADD TO COLLECTION ===
		GetScriptTemplateCollection().Add(scriptTemplate)

		If Not parentScriptTemplate
			scriptTemplatesCount :+ 1
			totalScriptTemplatesCount :+ 1
		EndIf

		Return scriptTemplate
	End Method



	Method LoadV3ProgrammeRoleFromNode:TProgrammeRole(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = TXmlHelper.FindValue(node,"guid", "")
		Local role:TProgrammeRole

		'fetch potential meta data
		Local mData:TData = LoadV3ProgrammeRoleMetaDataFromNode(GUID, node, xml)
		If mData Then metaData.Add(GUID, mData )

		'try to fetch an existing template with the entries GUID
		role = GetProgrammeRoleCollection().GetByGUID(GUID)
		If Not role
			role = New TProgrammeRole
			role.SetGUID(GUID)
		EndIf

		role.Init(..
			TXmlHelper.FindValue(node, "first_name", role.firstname), ..
			TXmlHelper.FindValue(node, "last_name", role.lastname), ..
			TXmlHelper.FindValue(node, "nick_name", role.nickname), ..
			TXmlHelper.FindValue(node, "title", role.title), ..
			TXmlHelper.FindValue(node, "country", role.countryCode).ToUpper(), ..
			TXmlHelper.FindValueIntLC(node, "gender", role.gender), ..
			TXmlHelper.FindValueIntLC(node, "fictional", role.fictional) ..
		)

		'=== ADD TO COLLECTION ===
		GetProgrammeRoleCollection().Add(role)

		programmeRolesCount :+ 1
		totalProgrammeRolesCount :+ 1

		Return role
	End Method


	Method GetV3TargetgroupAttractivityModFromNode:TAudience(audience:TAudience, node:TxmlNode,xml:TXmlHelper)
		Local tgAttractivityNode:TxmlNode = xml.FindChildLC(node, "targetgroupattractivity")
		If Not tgAttractivityNode Then Return audience

		Local data:TData = New TData
		Local searchData:String[TVTTargetGroup.baseGroupCount*3] '2 genders + "both"
		Local searchIndex:Int = 0
		For Local tgID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			Local base:String = TVTTargetGroup.GetAsString( tgID )
			searchData[searchIndex+0] = base
			searchData[searchIndex+1] = base + "_male"
			searchData[searchIndex+2] = base + "_female"
			searchIndex :+ 3
		Next
		xml.LoadValuesToData(tgAttractivityNode, data, searchData)

		'loop over all genders (all, male, female) and assign found numbers
		'- making sure to start with "all" allows assign "base", then
		'  specific (if desired)
		If Not audience Then audience = New TAudience.Set(1.0, 1.0)
		For Local genderIndex:Int = 0 To TVTPersonGender.count
			Local genderID:Int = TVTPersonGender.GetAtIndex(genderIndex)
			Local genderString:String = TVTpersonGender.GetAsString( genderID )

			For Local tgID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
				Local tgName:String = TVTTargetGroup.GetAsString(tgID)
				Local key:String = tgName+"_"+genderString
				If genderIndex = 0 Then key = tgName
				'to avoid falling back to "1.0" on "female|male" while
				'generic was set correctly before, we check if the key
				'was found in the XML
				If data.Has(key)
					audience.SetGenderValue(tgID, data.GetFloat(key, 1.0), genderID)
				EndIf
			Next
		Next
		Return audience
	End Method


	Method LoadV3EffectsFromNode(source:TBroadcastMaterialSourceBase, node:TxmlNode,xml:TXmlHelper)
		Local nodeEffects:TxmlNode = xml.FindChildLC(node, "effects")
		For Local nodeEffect:TxmlNode = EachIn xml.GetNodeChildElements(nodeEffects)
			If nodeEffect.getName() <> "effect" Then Continue

			Local effectData:TData = New TData
			Rem
			'old approach: load only defined ones
			xml.LoadValuesToData(nodeEffect, effectData, [..
				"trigger", "type", ..
				"probability", ..
				"news", "parameter2", "parameter3", "parameter4", "parameter5", ..
				"trigger_news", "trigger_parameter2", "trigger_parameter3", "trigger_parameter4", "trigger_parameter5" ..
			])
			endrem
			'new approach: load every thing and let the effect
			'              decide whether something is missing
			xml.LoadAllValuesToData(nodeEffect, effectData)
			'check if the effect has all needed configurations
			For Local f:String = EachIn ["trigger", "type"]
				If Not effectData.Has(f) Then ThrowNodeError("DB: <effects> is missing ~q" + f+"~q.", nodeEffect)
			Next

			source.AddEffectByData(effectData)
		Next
	End Method


	Method LoadV3ModifiersFromNode(source:TBroadcastMaterialSourceBase, node:TxmlNode,xml:TXmlHelper)
		'reuses existing (parent) modifiers and overrides it with custom
		'ones
		Local nodeModifiers:TxmlNode = xml.FindChildLC(node, "modifiers")
		For Local nodeModifier:TxmlNode = EachIn xml.GetNodeChildElements(nodeModifiers)
			If nodeModifier.getName() <> "modifier" Then Continue

			Local modifierData:TData = New TData
			xml.LoadAllValuesToData(nodeModifier, modifierData)
			'check if the modifier has all needed definitions
			For Local f:String = EachIn ["name", "value"]
				If Not modifierData.Has(f) Then ThrowNodeError("DB: <modifier> is missing ~q" + f+"~q.", nodeModifier)
			Next

			source.SetModifier(modifierData.GetString("name"), modifierData.GetFloat("value"))
		Next
	End Method


	'=== META DATA FUNCTIONS ===
	Method LoadV3CreatorMetaDataFromNode:TData(GUID:String, data:TData, node:TxmlNode, xml:TXmlHelper)
		data.Add("creator", TXmlHelper.FindValueIntLC(node,"creator", 0))
		data.Add("createdBy", TXmlHelper.FindValueLC(node,"created_by", ""))
		Return data
	End Method


	Method LoadV3ProgrammeRoleMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetProgrammeRoleCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf
		Return data
	End Method


	Method LoadV3ScriptTemplateMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper, parentScriptTemplate:TScriptTemplate = Null)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetScriptTemplateCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf
		Return data
	End Method


	Method LoadV3ProgrammeLicenceMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper, parentLicence:TProgrammeLicence = Null)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetProgrammeLicenceCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf
		Return data
	End Method


	Method LoadV3PersonBaseMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper, isCelebrity:Int=True)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetPersonBaseCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf

		rem
		'also load the original name if possible
		xml.LoadValuesToData(node, data, [..
			"first_name_original", "last_name_original", "nick_name_original", ..
			"imdb", "tmdb" ..
		])
		endrem

		Return data
	End Method


	Method LoadV3NewsEventMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetNewsEventCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf
		Return data
	End Method


	Method LoadV3AchievementElementsMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetAchievementCollection().GetAchievement(GUID) And ..
		   Not GetAchievementCollection().GetTask(GUID) And ..
		   Not GetAchievementCollection().GetReward(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf
		Return data
	End Method


	Method LoadV3AdContractBaseMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetAdContractBaseCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf
		Return data
	End Method


	Function CreateReleaseTime:Long(releaseData:TDataCSK, oldReleaseTime:Long)
		Local releaseYear:Int = releaseData.GetInt("year", 0)
		Local releaseYearRelative:Int = releaseData.GetInt("year_relative", 0)
		Local releaseYearRelativeMin:Int = releaseData.GetInt("year_relative_min", 0)
		Local releaseYearRelativeMax:Int = releaseData.GetInt("year_relative_max", 0)

		Local releaseDay:Int = releaseData.GetInt("day", -1)
		Local releaseHour:Int = MathHelper.Clamp(releaseData.GetInt("hour", -1), 0, 23)

		Local releaseDayRandomMin:Int = Max(0,releaseData.GetInt("day_random_min", 0))
		Local releaseDayRandomMax:Int = Max(0,releaseData.GetInt("day_random_max", 0))
		Local releaseDayRandomSlope:Float = MathHelper.Clamp(releaseData.GetFloat("day_random_slope", 0.5), 0.0, 1.0)
		Local releaseHourRandomMin:Int = MathHelper.Clamp(releaseData.GetInt("hour_random_min", 0), 0, 23)
		Local releaseHourRandomMax:Int = MathHelper.Clamp(releaseData.GetInt("hour_random_max", 0), 0, 23)
		Local releaseHourRandomSlope:Float = MathHelper.Clamp(releaseData.GetFloat("hour_random_slope", 0.5), 0.0, 1.0)

		'do not sort (relative) years here as original valus are interpreted below
		'and a sort could mix that up (eg min=2000, max=0 -> information
		'about "not before year 2000" is lost)
		'MathHelper.SortIntValues(releaseYearRelativeMin, releaseYearRelativeMax)
		MathHelper.SortIntValues(releaseDayRandomMin, releaseDayRandomMax)
		MathHelper.SortIntValues(releaseHourRandomMin, releaseHourRandomMax)


		'no year definition? use the given one
		If releaseYear = 0 And releaseYearRelative = 0 And oldReleaseTime > 0
			Return oldReleaseTime
		EndIf


		'= YEAR =
		If releaseYear = 0 Then releaseYear = GetWorldTime().GetYear() + releaseYearRelative
		'no upper limit given? Only minimum has to be considered
		If releaseYearRelativeMax = 0
			releaseYear = Max(releaseYearRelativeMin, releaseYear)
		'upper limit known? Limit between minimum (known or not) and maximum
		Else
			releaseYear = MathHelper.Clamp(releaseYear, releaseYearRelativeMin, releaseYearRelativeMax)
		EndIf

		'= DAY =
		'if no fixed day was defined then use a random one.
		'defaults to day 1
		If releaseDay = -1
			If releaseDayRandomMin <> 0 And releaseDayRandomMax <> 0
				releaseDay = BiasedRandRange(releaseDayRandomMin, releaseDayRandomMax, releaseDayRandomSlope)
			Else
				releaseDay = 1 'first day as default
			EndIf
		EndIf

		'= HOUR =
		'if no fixed hour was defined then use a random one.
		'defaults to midnight (0)
		If releaseHour = -1
			If releaseHourRandomMin <> 0 And releaseHourRandomMax <> 0
				releaseHour = BiasedRandRange(releaseHourRandomMin, releaseHourRandomMax, releaseHourRandomSlope)
			Else
				releaseHour = 1 'first day as default
			EndIf
		EndIf

		'= TIME =
		'local releaseTime:String = ":".Join([string(releaseYear), string(releaseYearRelative), string(releaseYearMin), string(releaseYearMax), string(releaseDay), string(releaseHour)])
		Return GetWorldTime().GetTimeGoneForGameTime(releaseYear, releaseDay-1, releaseHour, 0, 0)
	End Function


	Method FixLoadedData()
		FixPersonsDayOfBirth()
	End Method


	Method FixPersonsDayOfBirth()
		'=== CHECK BIRTHDATES ===
		'persons might have been used in productions not matching their hardcoded day-of-birth
		'(fictional) person should have a minimal age

		Local minAgeCast:Int = 5
		Local minAgeAdultCast:Int = 18
		'maximum *additional* years added when adjusting the the age
		Local adjustAgeRandomYears:Int = 15

		For Local person:TPersonBase = EachIn GetPersonBaseCollection().entries.Values()
			'ignore persons without a given date of birth
			If not person.HasCustomPersonality() or person.GetPersonalityData().GetDOB() <= 0 Then Continue

			Local dob:Long = person.GetPersonalityData().GetDOB()
			Local dobYear:Int = GetWorldTime().GetYear( dob )
			Local adjustAge:Int = 0
			Local adjustAgeReason:String = ""
			For Local programmeDataID:Int = EachIn person.GetProductionData().GetProducedProgrammeIDs()
				Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByID(programmeDataID)
				If Not programmeData
					TLogger.Log("TDatabase.FixLoadedDate()", "No ProgrammeData found for ID ~q"+programmeDataID+"~q.", LOG_ERROR)
					Continue
				EndIf
				Local prodYear:Int = programmeData.GetYear()
				If prodYear - (dobYear - adjustAge) >= minAgeAdultCast Then Continue
				If person.IsFictional() And hasAdultProperty(person.GetID(), programmeData)
					adjustAge = minAgeAdultCast - (prodYear - dobYear - adjustAge)
					adjustAge = RandRange(adjustAge, adjustAge + adjustAgeRandomYears)
					adjustAgeReason = "... should have been adult for production of "+programmeData.GetTitle() + " in "+prodYear+"."
				ElseIf programmeData.GetProductionStartTime() - dob < 0
					adjustAge = minAgeCast - (prodYear - dobYear - adjustAge)
					adjustAge = RandRange(adjustAge, adjustAge + adjustAgeRandomYears)
					adjustAgeReason = "... was not born for production of "+programmeData.GetTitle() + " in "+prodYear+"."
				EndIf
			Next

			If adjustAge > 0
				'we are able to correct non-fictional ones
				If person.IsFictional()
					person.GetPersonalityData().dayOfBirth = (dobYear - adjustAge) + "-" + GetWorldTime().GetMonth(dob) + "-" + GetWorldTime().GetDayOfYear(dob)
					Local dobYearNew:Int = GetWorldTime().GetYear( person.GetPersonalityData().GetDOB() )
					TLogger.Log("TDatabase.FixLoadedData()", "Adjusted DOB of person ~q"+person.GetFullName()+"~q (GUID=~q"+person.getGUID()+"~q). Was "+dobYear+" and is now "+dobYearNew+". "+ adjustAgeReason, LOG_LOADING | LOG_WARNING)
				Else
					TLogger.Log("TDatabase.FixLoadedData()", "Cannot adjust DOB of person ~q"+person.GetFullName()+"~q (GUID=~q"+person.getGUID()+"~q). Person is non-fictional, so DOB should be correct. "+adjustAgeReason, LOG_LOADING | LOG_WARNING)
				EndIf
			EndIf
		Next
		Function hasAdultProperty:Int(personId:Int, data:TProgrammeData)
			'cast should be adult for director/writer, erotic, horror and xrated
			If data.HasCastPerson(personId, TVTPersonJob.DIRECTOR | TVTPersonJob.SCRIPTWRITER) Then Return True
			If data.GetGenre() = TVTProgrammeGenre.Erotic Then Return True
			If data.HasSubGenre(TVTProgrammeGenre.Erotic) Then Return True
			If data.GetGenre() = TVTProgrammeGenre.Horror Then Return True
			If data.HasSubGenre(TVTProgrammeGenre.Horror) Then Return True
			If data.IsXrated() Then Return True
			Return False
		End Function
	End Method



	Method ThrowNodeError(err:String, node:TxmlNode)
		Local error:String
		error :+ "ERROR~n"
		error :+ err + "~n"
?Not bmxng
		error :+ "File: ~q" + config.GetString("currentFileURI") + "~q  Line:" + node.getLineNumber() +" ~n"
?bmxng
		error :+ "File: ~q" + config.GetString("currentFileURI") + "~q~n"
?
		error :+ "- - - -~n"
		error :+ node.ToString()+"~n"
		error :+ "- - - -~n"
		Throw(error)
	End Method


	Function convertV2genreToV3:Int(data:TProgrammeData)
		Select data.genre
			Case 0 'old ACTION
				data.genre = TVTProgrammeGenre.Action
			Case 1 'old THRILLER
				data.genre = TVTProgrammeGenre.Thriller
			Case 2 'old SCIFI
				data.genre = TVTProgrammeGenre.SciFi
			Case 3 'old COMEDY
				data.genre = TVTProgrammeGenre.Comedy
			Case 4 'old HORROR
				data.genre = TVTProgrammeGenre.Horror
			Case 5 'old LOVE
				data.genre = TVTProgrammeGenre.Romance
			Case 6 'old EROTIC
				data.genre = TVTProgrammeGenre.Erotic
			Case 7 'old WESTERN
				data.genre = TVTProgrammeGenre.Western
			Case 8 'old LIVE
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TVTProgrammeDataFlag.LIVE)
			Case 9 'old KIDS
				data.genre = TVTProgrammeGenre.Family
			Case 10 'old CARTOON
				data.genre = TVTProgrammeGenre.Animation
			Case 11 'old MUSIC
				data.genre = TVTProgrammeGenre.Undefined
			Case 12 'old SPORT
				data.genre = TVTProgrammeGenre.Undefined
			Case 13 'old CULTURE
				data.genre = TVTProgrammeGenre.Undefined
			Case 14 'old FANTASY
				data.genre = TVTProgrammeGenre.Fantasy
			Case 15 'old YELLOWPRESS
				'hier sind nur "Trash"-Programme drin
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TVTProgrammeDataFlag.TRASH)
			Case 17 'old SHOW
				data.genre = TVTProgrammeGenre.Show
			Case 18 'old MONUMENTAL
				data.genre = TVTProgrammeGenre.Monumental
			Case 19 'TProgrammeData.GENRE_FILLER 'TV films etc.
				data.genre = TVTProgrammeGenre.Undefined
			Case 20 'old CALLINSHOW
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TVTProgrammeDataFlag.PAID)
			Default
				data.genre = TVTProgrammeGenre.Undefined
		End Select
	End Function


	'load a localized string from the given node
	'only adds "non empty" strings
	'ex.:
	'<title>
	' <de>bla</de>
	'<title>
	Function GetLocalizedStringFromNode:TLocalizedString(node:TxmlNode)
		If Not node Then Return Null

		Local localized:TLocalizedString
		Local childNodes:TList = TxmlHelper.GetNodeChildElements(node)
		'if no languages were used:
		'<var1>
		'  <de>bla</de>
		'  <en>bla</en>
		'</var>
		'then use the
		'node itself so you can use a global value
		'<var1>bla</var1> 
		If childNodes.Count() = 0
			childNodes.Addlast(node)
		EndIf
		
		For Local nodeLangEntry:TxmlNode = EachIn childNodes
			'do not trim, as this corrupts variables like "<de> %WORLDTIME:YEAR%</de>" (with space!)
			Local value:String = nodeLangEntry.getContent().Replace("~~n", "~n") '.Trim()
			

			Local migratedScriptExpression:Int
			Global migratedScriptExpressionCount:Int
			'if value.find("%town%") >= 0 Then Print "Check: " + value
			value = ConvertOldScriptExpression(value, migratedScriptExpression)
			if migratedScriptExpression
				migratedScriptExpressionCount :+ 1
				'print "migrated script expression: #"+ migratedScriptExpressionCount +" => " + value
			EndIf
			

			Local languageID:Int = -1
			If nodeLangEntry = node 'global definition?
				languageID = TLocalization.defaultLanguageID
			ElseIf nodeLangEntry.GetName().ToLower() = "all"
				languageId = -2 'same base value for all default languages
			Else
				languageID = TLocalization.GetLanguageID( nodeLangEntry.GetName().ToLower() )
			EndIf

			If languageID <> -1
				If Not localized Then localized = New TLocalizedString
				If languageID = -2
					localized.Set(value, TLocalization.GetLanguageID("en"))
					localized.Set(value, TLocalization.GetLanguageID("de"))
					localized.Set(value, TLocalization.GetLanguageID("pl"))
				Else
					localized.Set(value, languageID)
				EndIf
			Else
				TLogger.Log("TDATABASE.LOAD()", "Found and ignored localization entry for unsupported language " + nodeLangEntry.GetName().ToLower(), LOG_LOADING|LOG_WARNING)
			EndIf
		Next

		Return localized
	End Function
End Type




Function LoadDatabase(dbDirectory:String, required:Int = False, loader:TDatabaseLoader = Null)
	If Not loader Then loader = New TDatabaseLoader
	loader.LoadDir(dbDirectory, required)
End Function


Function LoadDB(files:String[] = Null, baseURI:String="", loader:TDatabaseLoader = Null)
	If Not loader Then loader = New TDatabaseLoader
	If files = Null
		loader.LoadDir(baseURI + "res/database/Default")
	Else
		For Local f:String = EachIn files
			loader.Load(baseURI + "res/database/Default/"+f)
		Next
	EndIf
End Function
