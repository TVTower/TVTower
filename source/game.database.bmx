SuperStrict
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.directorytree.bmx"
Import "Dig/base.util.xmlhelper.bmx"
Import "Dig/base.util.hashes.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.string2intarray.bmx"

Import "game.achievements.bmx"
Import "game.production.scripttemplate.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"
Import "game.person.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "game.gameconstants.bmx"
Import "game.database.localizer.bmx"



Enum EDBDataTypes
	ADCONTRACT
	PROGRAMMELICENCE
	NEWS
	NEWSEVENT
	SCRIPT
	SCRIPTTEMPLATE
	PERSON
	INSIGNIFICANTPEOPLE
	ACHIEVEMENT
	PROGRAMMEROLE
End Enum


Type TDBEntryMetaData
	Field createdBy:String
	Field creator:Int
	Field fictional:Int
End Type


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
	Global metaDataNew:TTreeMap<String, TDBEntryMetaData> = New TTreeMap<String, TDBEntryMetaData>
	Global XMLErrorCount:Int

	Global _programmeLicenceDataTimeFieldsKeys:String[]

	Method New()
		allowedAdCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_ADS_CREATED_BY", "*").ToLower().Split(",")
			allowedAdCreators :+ " " + s + " "
		Next

		skipAdCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_ADS_CREATED_BY", "").ToLower().Split(",")
			skipAdCreators :+ " " + s + " "
		Next

		allowedProgrammeCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_PROGRAMMES_CREATED_BY", "*").ToLower().Split(",")
			allowedProgrammeCreators :+ " " + s + " "
		Next

		skipProgrammeCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_PROGRAMMES_CREATED_BY", "").ToLower().Split(",")
			skipProgrammeCreators :+ " " + s + " "
		Next

		allowedNewsCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_NEWS_CREATED_BY", "*").ToLower().Split(",")
			allowedNewsCreators :+ " " + s + " "
		Next

		skipNewsCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_NEWS_CREATED_BY", "").ToLower().Split(",")
			skipNewsCreators :+ " " + s + " "
		Next

		allowedScriptCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_SCRIPTS_CREATED_BY", "*").ToLower().Split(",")
			allowedScriptCreators :+ " " + s + " "
		Next

		skipScriptCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_SCRIPTS_CREATED_BY", "").ToLower().Split(",")
			skipScriptCreators :+ " " + s + " "
		Next

		allowedAchievementCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_ACHIEVEMENTS_CREATED_BY", "*").ToLower().Split(",")
			allowedAchievementCreators :+ " " + s + " "
		Next

		skipAchievementCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_ACHIEVEMENTS_CREATED_BY", "").ToLower().Split(",")
			skipAchievementCreators :+ " " + s + " "
		Next

		allowedPersonCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_PERSONS_CREATED_BY", "*").ToLower().Split(",")
			allowedPersonCreators :+ " " + s + " "
		Next

		skipPersonCreators = ""
		For Local s:String = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_PERSONS_CREATED_BY", "").ToLower().Split(",")
			skipPersonCreators :+ " " + s + " "
		Next
	End Method


	Method IsAllowedUser:Int(username:String, dataType:EDBDataTypes)
		Local allowed:String
		Local skip:String

		username = username.ToLower().Replace("unknown", "*")
		username = username.Trim()
		If username = "" Then username = "*"

		Select dataType
			Case EDBDataTypes.ADCONTRACT
				allowed = allowedAdCreators
				skip = skipAdCreators
			Case EDBDataTypes.PROGRAMMELICENCE
				allowed = allowedProgrammeCreators
				skip = skipProgrammeCreators
			Case EDBDataTypes.NEWS, EDBDataTypes.NEWSEVENT
				allowed = allowedNewsCreators
				skip = skipNewsCreators
			Case EDBDataTypes.SCRIPT, EDBDataTypes.SCRIPTTEMPLATE
				allowed = allowedScriptCreators
				skip = skipScriptCreators
			Case EDBDataTypes.PERSON, EDBDataTypes.INSIGNIFICANTPEOPLE, EDBDataTypes.PROGRAMMEROLE
				allowed = allowedPersonCreators
				skip = skipPersonCreators
			Case EDBDataTypes.ACHIEVEMENT
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
				Local rootNode:TxmlNode = xml.GetRootNode()
				Local allGlobalVars:TxmlNode = xml.FindChild(rootNode, "globalvariables")
				If allGlobalVars
					Local gvl:TLocalizationLanguage = dbl.getGlobalVariables(code)
					If Not gvl
						gvl = new TLocalizationLanguage
						gvl.languageCode = code
						dbl.globalVariables.insert(code, gvl)
					EndIf
					Local varName:String
					Local value:String
					Local varNode:TxmlNode = TxmlNode(allGlobalVars.GetFirstChild())
					While varNode
						value = varNode.getContent()
						If value
							varName = varNode.getName().toLower()
							gvl.map.insert(varName, value)
						EndIf
						varNode = varNode.NextSibling()
					Wend
				EndIf

				Local nodeAllPersons:TxmlNode = xml.FindChild(rootNode, "persons")
				If nodeAllPersons
					Local index:Int = 0
					Local personCollection:TPersonBaseCollection = GetPersonBaseCollection()
					Local nodePerson:TxmlNode = TxmlNode(nodeAllPersons.GetFirstChild())
					While nodePerson
						If Not nodePerson.GetName().Equals("person", False)
						'If Not TXmlHelper.AsciiNamesLCAreEqual("person", nodePerson.getName())
							nodePerson = nodePerson.NextSibling()
							continue
						EndIf

						Local guid:String = xml.FindValue(nodePerson, "guid")
						If guid
							Local person:TPersonBase = personCollection.GetByGUID(guid)
							If person
								Local personToStore:TPersonLocalization = new TPersonLocalization
								personToStore.id = person.id
								personToStore.firstName = xml.FindValue(nodePerson, "first_name", "")
								personToStore.lastName = xml.FindValue(nodePerson, "last_name","")
								personToStore.nickName = xml.FindValue(nodePerson, "nick_name","")
								personToStore.title = xml.FindValue(nodePerson, "title","")
								if toStore.length <= index Then toStore = toStore[.. index + 50]
								toStore[index] = personToStore
								index:+1
							EndIf
						EndIf

						nodePerson = nodePerson.NextSibling()
					Wend
					If index > 0 Then dbl.persons.insert(code, toStore[..index])
				EndIf

				Local nodeAllRoles:TxmlNode = xml.FindChild(rootNode, "programmeroles")
				If Not nodeAllRoles Then nodeAllRoles = xml.FindChild(rootNode, "roles")

				If nodeAllRoles
					Local index:Int = 0
					Local nodeRole:TxmlNode = TXmlNode(nodeAllRoles.GetFirstChild())
					While nodeRole
						Local nodeRoleName:String = nodeRole.GetName()
						If Not nodeRoleName.Equals("programmerole", False) And ..
						   Not nodeRoleName.Equals("role", False)

							nodeRole = nodeRole.NextSibling()
							Continue
						EndIf

						Local guid:String = xml.FindValue(nodeRole, "guid")
						If guid
							Local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(guid)
							If role
								Local roleToStore:TPersonLocalization = new TPersonLocalization
								roleToStore.id = role.id
								roleToStore.firstName = xml.FindValue(nodeRole, "first_name","")
								roleToStore.lastName = xml.FindValue(nodeRole, "last_name","")
								roleToStore.nickName = xml.FindValue(nodeRole, "nick_name","")
								roleToStore.title = xml.FindValue(nodeRole, "title","")
								if toStore.length <= index Then toStore = toStore[.. index + 50]
								toStore[index] = roleToStore
								index:+ 1
							EndIf
						EndIf

						nodeRole = nodeRole.NextSibling()
					Wend
					If index > 0 Then dbl.roles.insert(code, toStore[..index])
				EndIf
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
		config.AddString("currentFileURI", fileURI)
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
		programmeRolesCount = 0
		If totalNewsGenreCount.length < TVTNewsGenre.count
			totalNewsGenreCount = []
			For Local i:Int = 0 Until TVTNewsGenre.count
				totalNewsGenreCount :+ [[0, 0]]
			Next
		EndIf
		Local rootNode:TxmlNode = xml.GetRootNode()
		'recognize version (if versionNode is Null, defaultValue -1 is returned
		Local versionNode:TxmlNode = xml.FindChild(rootNode, "version")
		Local version:Int = xml.FindValueInt(versionNode, "value", -1)
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

		Local rootNode:TxmlNode = xml.GetRootNode()

		'===== IMPORT ALL PERSONS =====
		'insignificant (non prominent) people
		'so they can get referenced properly
		Local nodeAllInsignificantPersons:TxmlNode = xml.FindChild(rootNode, "insignificantpeople")
		If nodeAllInsignificantPersons
			Local nodePerson:TxmlNode = TxmlNode(nodeAllInsignificantPersons.GetFirstChild())
			While nodePerson
				If nodePerson.getName() <> "person" 
					nodePerson = nodePerson.NextSibling()
					Continue
				EndIf

				'param false = load as insignificant
				If LoadV3PersonBaseFromNode(nodePerson, xml, False)
					personsBaseCount :+ 1
					totalPersonsBaseCount :+ 1
				EndIf

				nodePerson = nodePerson.NextSibling()
			Wend
		EndIf

		'celebrities (they have more details)
		Local nodeAllCelebrityPersons:TxmlNode = xml.FindChild(rootNode, "celebritypeople")
		If nodeAllCelebrityPersons
			Local nodePerson:TxmlNode = TxmlNode(nodeAllCelebrityPersons.GetFirstChild())
			While nodePerson
				If nodePerson.getName() <> "person" 
					nodePerson = nodePerson.NextSibling()
					Continue
				EndIf

				'param false = load as insignificant
				If LoadV3PersonBaseFromNode(nodePerson, xml, True)
					personsBaseCount :+ 1
					totalPersonsCount :+ 1
				EndIf

				nodePerson = nodePerson.NextSibling()
			Wend
		EndIf


		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====
		Local nodeAllAds:TxmlNode = xml.FindChild(rootNode, "allads")
		If nodeAllAds
			Local nodeAd:TxmlNode = TxmlNode(nodeAllAds.GetFirstChild())
			While nodeAd
				If nodeAd.getName() = "ad"
					LoadV3AdContractBaseFromNode(nodeAd, xml)
				EndIf

				nodeAd = nodeAd.NextSibling()
			Wend
		EndIf


		'===== IMPORT ALL NEWS EVENTS =====
		Local nodeAllNews:TxmlNode = xml.FindChild(rootNode, "allnews")
		If nodeAllNews
			Local nodeNews:TxmlNode = TxmlNode(nodeAllNews.GetFirstChild())
			While nodeNews
				If nodeNews.getName() = "news"
					LoadV3NewsEventTemplateFromNode(nodeNews, xml)
				EndIf
				
				nodeNews = nodeNews.NextSibling()
			Wend
		EndIf


		'===== IMPORT ALL PROGRAMME ROLES =====
		Local nodeAllRoles:TxmlNode = xml.FindChild(rootNode, "programmeroles")
		If nodeAllRoles
			Local nodeRole:TxmlNode = TxmlNode(nodeAllRoles.GetFirstChild())
			While nodeRole
				If nodeRole.getName() = "programmerole" 
					LoadV3ProgrammeRoleFromNode(nodeRole, xml)
				EndIf
				
				nodeRole = nodeRole.NextSibling()
			Wend
		EndIf


		'===== IMPORT ALL PROGRAMMES (MOVIES/SERIES) =====
		'ATTENTION: LOAD PERSONS FIRST !!
		Local nodeAllProgrammes:TxmlNode = xml.FindChild(rootNode, "allprogrammes")
		If nodeAllProgrammes
			Local nodeProgramme:TxmlNode = TxmlNode(nodeAllProgrammes.GetFirstChild())
			While nodeProgramme
				If nodeProgramme.getName() <> "programme" 
					nodeProgramme = nodeProgramme.NextSibling()
					Continue
				EndIf

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
				
				nodeProgramme = nodeProgramme.NextSibling()
			Wend
		EndIf


		'===== IMPORT ALL SCRIPT (TEMPLATES) =====
		Local nodeAllScriptTemplates:TxmlNode = xml.FindChild(rootNode, "scripttemplates")
		If nodeAllScriptTemplates
			Local nodeScriptTemplate:TxmlNode = TxmlNode(nodeAllScriptTemplates.GetFirstChild())
			While nodeScriptTemplate
				If nodeScriptTemplate.getName() = "scripttemplate" 
					LoadV3ScriptTemplateFromNode(nodeScriptTemplate, xml)
				EndIf
				
				nodeScriptTemplate = nodeScriptTemplate.NextSibling()
			Wend
		EndIf



		'===== IMPORT ALL ACHIEVEMENTS =====
		Local nodeAllAchievements:TxmlNode = xml.FindChild(rootNode, "allachievements")
		If nodeAllAchievements
			Local nodeAchievement:TxmlNode = TxmlNode(nodeAllAchievements.GetFirstChild())
			While nodeAchievement
				If nodeAchievement.getName() = "achievement" 
					LoadV3AchievementFromNode(nodeAchievement, xml)
				EndIf
				
				nodeAchievement = nodeAchievement.NextSibling()
			Wend
		EndIf


		TLogger.Log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 3). Found " + seriesCount + " series, " + moviesCount + " movies, " + personsBaseCount + "/" + personsCount +" basePersons/persons, " + contractsCount + " advertisements, " + newsCount + " news, " + achievementCount+" achievements, "+ scriptTemplatesCount+" script templates. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method


	Method LoadV3PersonBaseFromNode:TPersonBase(node:TxmlNode, xml:TXmlHelper, isCelebrity:Int=True)
		Local GUID:String = xml.FindValue(node, "guid", "")
		'try loading an existing entry (in case of extension)
		Local person:TPersonBase = GetPersonBaseCollection().GetByGUID(GUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, person <> Null)


		'=== HANDLE NEW/EXTENSION ===
		'if the person existed, remove it from all lists and later add
		'it back to the one then suiting. this allows other 
		'database.xml's to morph a insignificant person into a celebrity
		If person
			GetPersonBaseCollection().Remove(person)
			TLogger.Log("LoadV3PersonBaseFromNode()", "Extending PersonBase ~q" + person.GetFullName() + "~q. GUID=" + person.GetGUID(), LOG_XML)
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.PERSON) Then Return Null

			person = New TPersonBase
			person.GUID = GUID
		EndIf

		'convert to celebrity if required
		If isCelebrity And Not person.IsCelebrity()
			UpgradePersonBaseData(person)
			person.SetFlag(TVTPersonFlag.CELEBRITY, True)
		EndIf


		'=== COMMON DETAILS ===
		Local generator:String = xml.FindValue(node, "generator")
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
		person.firstName = xml.FindValue(node, "first_name", person.firstName)
		person.lastName = xml.FindValue(node, "last_name", person.lastName)
		person.nickName = xml.FindValue(node, "nick_name", person.nickName)
		person.title = xml.FindValue(node, "title", person.title)
		person.SetFlag(TVTPersonFlag.FICTIONAL, GetBool(xml.FindValue(node, "fictional"), person.IsFictional()))
		'fallback for old database syntax
		person.SetFlag(TVTPersonFlag.CASTABLE, GetBool(xml.FindValue(node, "bookable"), person.IsCastable()))
		person.SetFlag(TVTPersonFlag.CASTABLE, GetBool(xml.FindValue(node, "castable"), person.IsCastable()))
		'cast filtering is mainly done using the bookable flag - not castable implies not bookable
		If Not person.IsCastable() Then person.SetFlag(TVTPersonFlag.BOOKABLE, false )
		person.SetFlag(TVTPersonFlag.CAN_LEVEL_UP, GetBool(xml.FindValue(node, "levelup"), person.CanLevelUp()))
		person.SetJob(xml.FindValueInt(node, "job", 0)) 'for now it must be defined all time, else: ", person._jobs))"
		person.countryCode = xml.FindValue(node, "country", person.countryCode).ToUpper()
		person.gender = xml.FindValueInt(node, "gender", person.gender)
		person.faceCode = xml.FindValue(node, "face_code", person.faceCode)

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
			Local nodeDetails:TxmlNode = xml.FindChild(node, "details")
			person.gender = xml.FindValueInt(nodeDetails, "gender", person.gender)
			person.countryCode = xml.FindValue(nodeDetails, "country", person.countryCode).ToUpper()
			pd.SetDayOfBirth( xml.FindValue(nodeDetails, "birthday", pd.dayOfBirth) )
			pd.SetDayOfDeath( xml.FindValue(nodeDetails, "deathday", pd.dayOfDeath) )
			person.SetJob( xml.FindValueInt(nodeDetails, "job", person.GetJobs()) )
			person.SetFlag(TVTPersonFlag.FICTIONAL, xml.FindValueInt(nodeDetails, "fictional", person.IsFictional()) )
			person.faceCode = xml.FindValue(nodeDetails, "face_code", person.faceCode)

			'=== DATA ===
			Local nodeData:TxmlNode = xml.FindChild(node, "data")
			If TPersonProductionData(person.GetProductionData())
				Local ppd:TPersonProductionData = TPersonProductionData(person.GetProductionData())
				ppd.topGenre = xml.FindValueInt(nodeData, "topgenre", ppd.topGenre)
			EndIf
			
			'0 would mean: cuts price to 0
			If person.GetProductionData().priceModifier = 0 Then person.GetProductionData().priceModifier = 1.0
			person.GetProductionData().priceModifier = xml.FindValueFloat(nodeData, "price_mod", person.GetProductionData().priceModifier)


			'ATTRIBUTES
			'create attributes:
			'- for fictional characters
			'- when DB entry defines stuff (do as soon as db defines an attribute

			Local a:TPersonPersonalityAttributes
			For local i:int = 1 to TVTPersonPersonalityAttribute.count
				Local attributeID:Int = TVTPersonPersonalityAttribute.GetAtIndex(i)
				Local attributeText:String = TVTPersonPersonalityAttribute.GetAsString(attributeID)

				'only fill attribute if at least a part is (correctly)
				'defined here (all values must be positive)
				Local dbValue:Float = xml.FindValueFloat(nodeData, attributeText, -1)
				Local dbMinValue:Float = xml.FindValueFloat(nodeData, attributeText + "_min", -1)
				Local dbMaxValue:Float = xml.FindValueFloat(nodeData, attributeText + "_max", -1)
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
			
			Local affinityValue:Float
			If xml.TryFindValueFloat(nodeData, "affinity", affinityValue)
				If not pd.HasAttributes() then pd.InitAttributes(False)
				pd.GetAttributes().SetAffinity(0.01 * affinityValue, -1, -1)
			EndIf


			'POPULARITY
			'create after attributes are defined - popularity might
			'depend on them (eg "fame")
			'create/override popularity
			Local popularityValue:Int = xml.FindValueInt(nodeData, "popularity", -1000)
			Local popularityTargetValue:Int = xml.FindValueInt(nodeData, "popularity_target", -1000)
			If popularityValue <> -1000 or popularityTargetValue <> -1000
				pd.CreatePopularity(popularityValue, popularityTargetValue, person)
			EndIf
		EndIf


		'=== ADD TO COLLECTION ===
		'we removed the person from all lists already, now add it back
		'to the ones it suits
		GetPersonBaseCollection().Add(person)
		
		Return person
	End Method


	Method LoadV3NewsEventTemplateFromNode:TNewsEventTemplate(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValue(node, "guid", "")
		Local threadId:String = xml.FindValue(node,"thread_guid", "")
		Local doAdd:Int = True

		'try loading an existing entry (in case of extension)
		Local newsEventTemplate:TNewsEventTemplate = GetNewsEventTemplateCollection().GetByGUID(GUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, newsEventTemplate <> Null)


		'=== HANDLE NEW/EXTENSION ===
		If newsEventTemplate
			doAdd = False

			TLogger.Log("LoadV3NewsEventTemplateFromNodeFromNode()", "Extending newsEventTemplate ~q"+newsEventTemplate.GetTitle()+"~q. GUID="+newsEventTemplate.GetGUID(), LOG_XML)
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.NEWSEVENT) Then Return Null

			newsEventTemplate = New TNewsEventTemplate
			newsEventTemplate.title = New TLocalizedString
			newsEventTemplate.description = New TLocalizedString
			newsEventTemplate.GUID = GUID
			newsEventTemplate.threadId = threadId
		EndIf


		'=== LOCALIZATION DATA ===
		newsEventTemplate.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		newsEventTemplate.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )

		'news type according to TVTNewsType - InitialNews, FollowingNews...
		newsEventTemplate.newsType = xml.FindValueInt(node, "type", 0)


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		newsEventTemplate.flags = xml.FindValueInt(nodeData, "flags", newsEventTemplate.flags)
		newsEventTemplate.genre = xml.FindValueInt(nodeData, "genre", newsEventTemplate.genre)
		newsEventTemplate.keywords = xml.FindValue(nodeData, "keywords", newsEventTemplate.keywords).ToLower()
		newsEventTemplate.minSubscriptionLevel = xml.FindValueInt(nodeData, "min_subscription_level", newsEventTemplate.minSubscriptionLevel)

		Local available:Int = xml.FindValueBool(nodeData, "available", Not newsEventTemplate.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		newsEventTemplate.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'topicality is "quality" here
		newsEventTemplate.quality = 0.01 * xml.FindValueFloat(nodeData, "quality", 100 * newsEventTemplate.quality)
		newsEventTemplate.qualityMin = 0.01 * xml.FindValueFloat(nodeData, "quality_min", 100 * newsEventTemplate.qualityMin)
		newsEventTemplate.qualityMax = 0.01 * xml.FindValueFloat(nodeData, "quality_max", 100 * newsEventTemplate.qualityMax)
		newsEventTemplate.qualitySlope = 0.01 * xml.FindValueFloat(nodeData, "quality_slope", 100 * newsEventTemplate.qualitySlope)

		'price is "priceModifier" here (so add 1.0 until that is done in DB)
		Local priceMod:Float
		If Not xml.TryFindValueFloat(nodeData, "price", priceMod) 'no valid data given
			priceMod = 1.0
		Endif
		newsEventTemplate.SetModifier("price", priceMod)

		Local happenTimeString:String = xml.FindValue(nodeData, "happen_time", "")
		If happenTimeString
			Local happenTimeParams:Int[] = StringHelper.StringToIntArray(happenTimeString, Asc(","))
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
		Local availabilityNode:TxmlNode = xml.FindChild(node, "availability")
		newsEventTemplate.availableScript = xml.FindValue(availabilityNode, "script", newsEventTemplate.availableScript)
		newsEventTemplate.availableYearRangeFrom = xml.FindValueInt(availabilityNode, "year_range_from", newsEventTemplate.availableYearRangeFrom)
		newsEventTemplate.availableYearRangeTo = xml.FindValueInt(availabilityNode, "year_range_to", newsEventTemplate.availableYearRangeTo)

		If newsEventTemplate.availableScript
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
		Local nodeVariables:TxmlNode = xml.FindChild(node, "variables")
		If nodeVariables
			Local nodeVariable:TxmlNode = TxmlNode(nodeVariables.GetFirstChild())
			While nodeVariable
				'each variable is stored as a localizedstring
				Local varName:String = nodeVariable.getName()
				If Not varName 
					nodeVariable = nodeVariable.NextSibling()
					Continue
				EndIf

				Local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)
				If Not varString
					nodeVariable = nodeVariable.NextSibling()
					Continue
				EndIf

				'create if missing
				newsEventTemplate.CreateTemplateVariables()
				newsEventTemplate.templateVariables.AddVariable(varName, varString)

				nodeVariable = nodeVariable.NextSibling()
			Wend
		EndIf


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
		Local GUID:String = xml.FindValue(node, "guid", "")
		Local doAdd:Int = True

		'try loading an existing entry (in case of extension)
		Local achievement:TAchievement = GetAchievementCollection().GetAchievement(GUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, achievement <> Null)


		'=== HANDLE NEW/EXTENSION ===
		If achievement
			doAdd = False
			
			' has at least one child ?
			If node.GetFirstChild()
				TLogger.Log("LoadV3AchievementFromNode()", "Extending achievement ~q"+achievement.GetTitle()+"~q. GUID="+achievement.GetGUID(), LOG_XML)
			EndIf
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.ACHIEVEMENT) Then Return Null

			achievement = New TAchievement
			achievement.title = New TLocalizedString
			achievement.text = New TLocalizedString
			achievement.GUID = GUID
		EndIf


		'=== LOCALIZATION DATA ===
		achievement.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		achievement.text.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "text")) )


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		achievement.flags = xml.FindValueInt(nodeData, "flags", achievement.flags)
		achievement.group = xml.FindValueInt(nodeData, "group", achievement.group)
		achievement.index = xml.FindValueInt(nodeData, "index", achievement.index)
		achievement.category = xml.FindValueInt(nodeData, "category", achievement.category)
		achievement.spriteFinished = xml.FindValue(nodeData, "sprite_finished", achievement.spriteFinished)
		achievement.spriteUnfinished = xml.FindValue(nodeData, "sprite_unfinished", achievement.spriteUnfinished)


		'=== TASKS ===
		Local nodeTasks:TxmlNode = xml.FindChild(node, "tasks")
		If nodeTasks
			Local nodeElement:TxmlNode = TxmlNode(nodeTasks.GetFirstChild())
			While nodeElement
				If nodeElement.GetName().Equals("task", False)
'				If TXmlHelper.AsciiNamesLCAreEqual("task", nodeElement.getName())
					LoadV3AchievementElementFromNode("task", achievement, nodeElement, xml)
				EndIf
				
				nodeElement = nodeElement.NextSibling()
			Wend
		EndIf


		'=== REWARDS ===
		Local nodeRewards:TxmlNode = xml.FindChild(node, "rewards")
		If nodeRewards
			Local nodeElement:TxmlNode = TxmlNode(nodeRewards.GetFirstChild())
			While nodeElement
				If nodeElement.GetName().Equals("reward", False)
'				If TXmlHelper.AsciiNamesLCAreEqual("reward", nodeElement.getName())
					LoadV3AchievementElementFromNode("reward", achievement, nodeElement, xml)
				EndIf
				
				nodeElement = nodeElement.NextSibling()
			Wend
		EndIf


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
		Local GUID:String = xml.FindValue(node, "guid", "")
		Local doAdd:Int = True

		'try loading an existing entry (in case of extension)
		Local achievement:TAchievement = GetAchievementCollection().GetAchievement(GUID)
		Local reuseExisting:Int = False


		'=== CREATE/FETCH META DATA ===
		Local hasAchievementOrTaskOrReward:Int
		If achievement Or GetAchievementCollection().GetTask(GUID) Or GetAchievementCollection().GetReward(GUID)
			hasAchievementOrTaskOrReward = True
		EndIf
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, hasAchievementOrTaskOrReward)


		'=== HANDLE NEW/EXTENSION ===
		If achievement
			doAdd = False
			
			' has at least one child ?
			If node.GetFirstChild()
				TLogger.Log("LoadV3AchievementFromNode()", "Extending achievement ~q"+achievement.GetTitle()+"~q. GUID="+achievement.GetGUID(), LOG_XML)
			EndIf
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.ACHIEVEMENT) Then Return Null

			achievement = New TAchievement
			achievement.title = New TLocalizedString
			achievement.text = New TLocalizedString
			achievement.GUID = GUID
		EndIf


		'try to fetch an existing subelement
		Local element:TAchievementBaseType
		If elementName = "task"
			element = GetAchievementCollection().GetTask(GUID)
		ElseIf elementName = "reward"
			element = GetAchievementCollection().GetReward(GUID)
		EndIf
		If element
			reuseExisting = True

			' has at least one child ?
			If node.GetFirstChild()
				TLogger.Log("LoadV3AchievementElementFromNode()", "Extending achievement "+elementName+" ~q"+element.GetTitle()+"~q. GUID="+element.GetGUID(), LOG_XML)
			EndIf
		EndIf


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
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
		Local GUID:String = xml.FindValue(node, "guid", "")
		Local doAdd:Int = True

		'try loading an existing entry (in case of extension)
		Local adContract:TAdContractBase = GetAdContractBaseCollection().GetByGUID(GUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, adContract <> Null)


		'=== HANDLE NEW/EXTENSION ===
		If adContract
			doAdd = False

			TLogger.Log("LoadV3AdContractBaseFromNode()", "Extending adContract ~q"+adContract.GetTitle()+"~q. GUID="+adContract.GetGUID(), LOG_XML)
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.ADCONTRACT) Then Return Null

			adContract = New TAdContractBase
			adContract.title = New TLocalizedString
			adContract.description = New TLocalizedString
			adContract.GUID = GUID
		EndIf


		'=== LOCALIZATION DATA ===
		adContract.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		adContract.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )

		'ad type according to TVTAdContractType - Normal, Ingame, ...
		adContract.adType = xml.FindValueInt(node,"type", 0)


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		adContract.infomercialAllowed = xml.FindValueBool(nodeData, "infomercial", adContract.infomercialAllowed)
		adContract.quality = 0.01 * xml.FindValueFloat(nodeData, "quality", adContract.quality * 100.0)

		Local available:Int = xml.FindValueBool(nodeData, "available", Not adContract.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		adContract.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'old -> now stored in "availability
		adContract.availableYearRangeFrom = xml.FindValueInt(nodeData, "year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = xml.FindValueInt(nodeData, "year_range_to", adContract.availableYearRangeTo)

		adContract.adType = xml.FindValueInt(nodeData, "type", adContract.adType)

		adContract.blocks = xml.FindValueInt(nodeData, "blocks", adContract.blocks)
		adContract.spotCount = xml.FindValueInt(nodeData, "repetitions", adContract.spotcount)
		adContract.fixedPrice = xml.FindValueBool(nodeData, "fix_price", adContract.fixedPrice)
		adContract.daysToFinish = xml.FindValueInt(nodeData, "duration", adContract.daysToFinish)
		adContract.proPressureGroups = xml.FindValueInt(nodeData, "pro_pressure_groups", adContract.proPressureGroups)
		adContract.contraPressureGroups = xml.FindValueInt(nodeData, "contra_pressure_groups", adContract.contraPressureGroups)
		adContract.profitBase = xml.FindValueFloat(nodeData, "profit", adContract.profitBase)
		adContract.penaltyBase = xml.FindValueFloat(nodeData, "penalty", adContract.penaltyBase)
		adContract.infomercialProfitBase = xml.FindValueFloat(nodeData, "infomercial_profit", adContract.infomercialProfitBase)
		adContract.fixedInfomercialProfit = xml.FindValueFloat(nodeData, "fix_infomercial_profit", adContract.fixedInfomercialProfit)
		'without data, fall back to 10% of profitBase
		If adContract.infomercialProfitBase = 0 Then adContract.infomercialProfitBase = adContract.profitBase * 0.1


		'=== AVAILABILITY ===
		Local availabilityNode:TxmlNode = xml.FindChild(node, "availability")
		adContract.availableScript = xml.FindValue(availabilityNode, "script", adContract.availableScript)
		adContract.availableYearRangeFrom = xml.FindValueInt(availabilityNode, "year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = xml.FindValueInt(availabilityNode, "year_range_to", adContract.availableYearRangeTo)

		If adContract.availableScript
			Local parsedToken:SToken
			Local result:Int = GameScriptExpression.ParseToTrue(adContract.availableScript, adContract, parsedToken)
			if parsedToken.id = TK_ERROR
				TLogger.Log("DB", "Script of AdContract ~q" + adContract.GetGUID() + "~q contains errors:", LOG_WARNING)
				TLogger.Log("DB", "Script: " + adContract.availableScript, LOG_WARNING)
				TLogger.Log("DB", "Error : " + parsedToken.GetValueText(), LOG_WARNING)
			EndIf
		EndIf


		'=== CONDITIONS ===
		Local nodeConditions:TxmlNode = xml.FindChild(node, "conditions")
		adContract.minAudienceBase = 0.01 * xml.FindValueFloat(nodeConditions, "min_audience", adContract.minAudienceBase*100.0)
		adContract.minImage = 0.01 * xml.FindValueFloat(nodeConditions, "min_image", adContract.minImage*100.0)
		adContract.maxImage = 0.01 * xml.FindValueFloat(nodeConditions, "max_image", adContract.maxImage*100.0)
		adContract.limitedToTargetGroup = xml.FindValueInt(nodeConditions, "target_group", adContract.limitedToTargetGroup)
		adContract.limitedToProgrammeGenre = xml.FindValueInt(nodeConditions, "allowed_genre", adContract.limitedToProgrammeGenre)
		adContract.limitedToProgrammeFlag = xml.FindValueInt(nodeConditions, "allowed_programme_flag", adContract.limitedToProgrammeFlag)
'		adContract.forbiddenProgrammeGenre = xml.FindValueInt(nodeConditions, "prohibited_genre", adContract.forbiddenProgrammeGenre)
		adContract.forbiddenProgrammeFlag = xml.FindValueInt(nodeConditions, "prohibited_programme_flag", adContract.forbiddenProgrammeFlag)


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
		Local GUID:String = xml.FindValue(node, "guid", "")
		'referencing an already existing programmedata? Or just use "data-GUID"
		Local dataGUID:String = TXmlHelper.FindValue(node,"programmedata_guid", "data-" + GUID)
		'forgot to prepend "data-" ?
		If dataGUID.Find("data-") <> 0 Then dataGUID = "data-" + dataGUID

		Local existed:Int

		'try loading an existing entry (in case of extension)
		Local programmeLicence:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID(GUID)
		'check if we reuse an existing programmedata (for series
		'episodes we cannot rely on existence of licences, as they
		'all get added at the end, not on load of an episode)
		Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(dataGUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, programmeLicence <> Null)


		'=== HANDLE NEW/EXTENSION ===
		If programmeLicence
			existed = True

			TLogger.Log("LoadV3ProgrammeLicenceFromNode()", "Extending programmeLicence's data ~q"+programmeData.GetTitle()+"~q. dataGUID="+dataGUID+"  GUID="+GUID, LOG_XML)
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.PROGRAMMELICENCE) Then Return Null
		EndIf


		'=== PROGRAMME DATA ===
		'try to reuse existing configurations or use default ones if no
		'licence/data existed
		Local productType:Int = TVTProgrammeProductType.MOVIE
		If programmeData Then productType = programmeData.productType
		productType = TXmlHelper.FindValueInt(node,"product", productType)

		Local licenceType:Int = -1
		If programmeLicence Then licenceType = programmeLicence.licenceType
		licenceType = TXmlHelper.FindValueInt(node,"licence_type", licenceType)


		'episode or single element of a collection?
		'(single movies without parent are converted later on)
		If licenceType = -1
			If parentLicence
				If parentLicence.IsSeries()
					TLogger.Log("LoadV3ProgrammeLicenceFromNode()", "Auto-corrected " + GUID + " to EPISODE.", LOG_XML)
					licenceType = TVTProgrammeLicenceType.EPISODE
				Else
					TLogger.Log("LoadV3ProgrammeLicenceFromNode()", "Auto-corrected " + GUID + " to SINGLE.", LOG_XML)
					licenceType = TVTProgrammeLicenceType.SINGLE
				EndIf
			EndIf
		EndIf



		If Not programmeLicence
			If Not programmeData
				'try to clone the parent's data - if that fails, create a new instance;
				If parentLicence 
					programmeData = TProgrammeData(THelper.CloneObject(parentLicence.data, ["id", "guid", "title", "description", "titleprocessed", "descriptionprocessed"]))
				EndIf
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
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		programmeData.country = xml.FindValue(nodeData, "country", programmeData.country)

		programmeData.distributionChannel = xml.FindValueInt(nodeData, "distribution", programmeData.distributionChannel)
		programmeData.blocks = MathHelper.clamp(xml.FindValueInt(nodeData, "blocks", programmeData.blocks), 1, 12)

		programmeData.broadcastTimeSlotStart = MathHelper.clamp(xml.FindValueInt(nodeData, "broadcast_time_slot_start", programmeData.broadcastTimeSlotStart), 0, 23)
		programmeData.broadcastTimeSlotEnd = MathHelper.clamp(xml.FindValueInt(nodeData, "broadcast_time_slot_end", programmeData.broadcastTimeSlotEnd), 0, 23)
		If programmeData.broadcastTimeSlotStart = programmeData.broadcastTimeSlotEnd
			programmeData.broadcastTimeSlotStart = -1
			programmeData.broadcastTimeSlotEnd = -1
		EndIf
		'define same for licence (override later if needed)
		programmeLicence.broadcastTimeSlotStart = programmeData.broadcastTimeSlotStart
		programmeLicence.broadcastTimeSlotEnd = programmeData.broadcastTimeSlotEnd


		programmeData.SetBroadcastLimit(xml.FindValueInt(nodeData, "broadcast_limit", programmeData.broadcastLimit))
		'if not given - disable and fallback to programmeData limit then
		programmeLicence.SetBroadcastLimit(xml.FindValueInt(nodeData, "licence_broadcast_limit", -1))


		programmeData.SetBroadcastFlag(xml.FindValueInt(nodeData, "broadcast_flags", 0))
		'if defined, it overrides (replaces) the data defined broadcast flags 
		'we need to set all flags then as "modified" (manually set)
		Local licenceBroadcastFlags:int = xml.FindValueInt(nodeData, "licence_broadcast_flags", -1)
		if licenceBroadcastFlags >= 0 
			If not programmeLicence.broadcastFlags 
				programmeLicence.broadcastFlags = new TTriStateIntBitmask
			Else
				programmeLicence.broadcastFlags.Reset()
			EndIf
			'mark all settings as manually set
			programmeLicence.broadcastFlags.SetAllModified()
			'activate the flag
			programmeLicence.broadcastFlags.Set(licenceBroadcastFlags, True)
		endif


		programmeLicence.SetLicenceFlag(xml.FindValueInt(nodeData, "licence_flags", 0))

		'TODO discuss - is it a good idea to use this flag for both licence AND data?
		'data flag has precedence; data not available - licence not available
		'availability effect turns both flags on, but only licence flag off
		Local available:Int = xml.FindValueBool(nodeData, "available", Not programmeData.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		programmeData.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)
		programmeLicence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'compatibility: load price mod from "price_mod" first... later
		'override with "modifiers"-data
		programmeData.SetModifier("price", xml.FindValueFloat(nodeData, "price_mod", programmeData.GetModifier("price")))

		programmeData.SetFlag(xml.FindValueInt(nodeData, "flags", 0))

		programmeData.genre = xml.FindValueInt(nodeData, "maingenre", programmeData.genre)
		

		Local subGenres:String = xml.FindValue(nodeData, "subgenre", "")
		If subGenres
			For Local sg:Int = EachIn New TIntSpliterator(subGenres, Asc(","), True)
				'skip invalid ones (0 is allowed!)
				If sg < 0 Then Continue

				'only add non-duplicates
				If Not MathHelper.InIntArray(sg, programmeData.subGenres)
					programmeData.subGenres :+ [sg]
				EndIf
			Next
		EndIf

		'=== RELEASE INFORMATION ===
		'TODO: remove TData-usage here and ensure all are either
		'      in this block OR <releaseTime> (no mixing / overrides)
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
		Local releaseTimeNode:TxmlNode = xml.FindChild(node, "releasetime")
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
		Local nodeStaff:TxmlNode = xml.FindChild(node, "staff")
		If nodeStaff
			Local nodeMember:TxmlNode = TxmlNode(nodeStaff.GetFirstChild())
			While nodeMember
				If Not nodeMember.GetName().Equals("member", False)
'				If Not TXmlHelper.AsciiNamesLCAreEqual("member", nodeMember.getName()) 
					nodeMember = nodeMember.NextSibling()
					Continue
				EndIf

				Local memberIndex:Int = xml.FindValueInt(nodeMember, "index", -1)
				Local memberFunction:Int = xml.FindValueInt(nodeMember, "function", 0)
				Local memberGenerator:String = xml.FindValue(nodeMember, "generator", "")
				Local jobRoleGUID:String = xml.FindValue(nodeMember, "role_guid", "")
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
					If mdata Then memberFictional = mdata.fictional
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

				nodeMember = nodeMember.NextSibling()
			Wend
		EndIf


		'=== GROUPS ===
		Local nodeGroups:TxmlNode = xml.FindChild(node, "groups")
		programmeData.targetGroups = xml.FindValueInt(nodeGroups, "target_groups", programmeData.targetGroups)
		programmeData.proPressureGroups = xml.FindValueInt(nodeGroups, "pro_pressure_groups", programmeData.proPressureGroups)
		programmeData.contraPressureGroups = xml.FindValueInt(nodeGroups, "contra_pressure_groups", programmeData.contraPressureGroups)



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
		Local nodeRatings:TxmlNode = xml.FindChild(node, "ratings")
		programmeData.review = 0.01 * xml.FindValueFloat(nodeRatings, "critics", programmeData.review*100)
		programmeData.speed = 0.01 * xml.FindValueFloat(nodeRatings, "speed", programmeData.speed*100)
		programmeData.outcome = 0.01 * xml.FindValueFloat(nodeRatings, "outcome", programmeData.outcome*100)

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
		Local nodeEpisodes:TxmlNode = xml.FindChild(node, "children")
		If nodeEpisodes
			Local nodeEpisode:TxmlNode = TxmlNode(nodeEpisodes.GetFirstChild())
			While nodeEpisode
				'skip other elements than programme data
				If Not nodeEpisode.GetName().Equals("programme", False)
'				If Not TXmlHelper.AsciiNamesLCAreEqual("programme", nodeEpisode.getName()) 
					nodeEpisode = nodeEpisode.NextSibling()
					Continue
				EndIf

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
				'local episodeNumber:int = xml.FindValueInt(nodeEpisode, "index", -1)
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

				nodeEpisode = nodeEpisode.NextSibling()
			Wend
		EndIf

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
		Local GUID:String = xml.FindValue(node, "guid", "")

		'try loading an existing entry (in case of extension)
		Local scriptTemplate:TScriptTemplate = GetScriptTemplateCollection().GetByGUID(GUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, scriptTemplate <> Null)


		'=== HANDLE NEW/EXTENSION ===
		If scriptTemplate
			TLogger.Log("LoadV3ScriptTemplateFromNode()", "Extending scriptTemplate's data ~q"+scriptTemplate.GetTitle()+"~q. GUID="+GUID, LOG_XML)
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.SCRIPTTEMPLATE) Then Return Null
		EndIf



		'=== SCRIPTTEMPLATE DATA ===
		Local scriptProductType:Int = TXmlHelper.FindValueInt(node,"product", 1)
		Local oldType:Int = TXmlHelper.FindValueInt(node,"type", TVTProgrammeLicenceType.SINGLE)
		Local scriptLicenceType:Int = TXmlHelper.FindValueInt(node,"licence_type", oldType)
		Local index:Int = TXmlHelper.FindValueInt(node,"index", 0)

		If Not scriptTemplate
			'try to clone the parent, if that fails, create a new instance
			If parentScriptTemplate
				scriptTemplate = TScriptTemplate(THelper.CloneObject(parentScriptTemplate, ["id", "guid", "jobs", "templatevariables", "subscripts", "title", "description"]))
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
		nodeData = xml.FindChild(node, "genres")
		scriptTemplate.mainGenre = xml.FindValueInt(nodeData, "mainGenre", scriptTemplate.mainGenre)

		Local subGenres:String = xml.FindValue(nodeData, "subGenres", "")
		If subGenres
			For Local sg:Int = EachIn New TIntSpliterator(subGenres, Asc(","))
				'skip empty or "undefined" genres
				If sg = 0 Then Continue
				'only add non-duplicates
				If Not MathHelper.InIntArray(sg, scriptTemplate.subGenres)
					scriptTemplate.subGenres :+ [sg]
				EndIf
			Next
		EndIf


		'=== DATA: RATINGS - OUTCOME ===
		nodeData = xml.FindChild(node, "outcome")
		Local outcomeValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If outcomeValue >= 0
			'inherit?
			'Local value:Float = 0.01 * Max(outcomeValue, Int(100 * scriptTemplate.outcomeMin))
			Local value:Float = 0.01 * outcomeValue
			scriptTemplate.SetOutcomeRange(value, value, 0.5)
		Else
			scriptTemplate.SetOutcomeRange( ..
				0.01 * xml.FindValueInt(nodeData, "min", Int(100 * scriptTemplate.outcomeMin)), ..
				0.01 * xml.FindValueInt(nodeData, "max", Int(100 * scriptTemplate.outcomeMax)), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.outcomeSlope)) ..
			)
		EndIf

		'=== DATA: RATINGS - REVIEW ===
		nodeData = xml.FindChild(node, "review")
		Local reviewValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If reviewValue >= 0
			'inherit?
			'Local value:Float = 0.01 * Max(reviewValue, Int(100 * scriptTemplate.reviewMin))
			Local value:Float = 0.01 * reviewValue
			scriptTemplate.SetReviewRange(value, value, 0.5)
		Else
			scriptTemplate.SetReviewRange( ..
				0.01 * xml.FindValueInt(nodeData, "min", Int(100 * scriptTemplate.reviewMin)), ..
				0.01 * xml.FindValueInt(nodeData, "max", Int(100 * scriptTemplate.reviewMax)), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.reviewSlope)) ..
			)
		EndIf

		'=== DATA: RATINGS - SPEED ===
		nodeData = xml.FindChild(node, "speed")
		Local speedValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If speedValue >= 0
			'inherit?
			'Local value:Float = 0.01 * Max(speedValue, Int(100 * scriptTemplate.speedMin))
			Local value:Float = 0.01 * speedValue
			scriptTemplate.SetSpeedRange(value, value, 0.5)
		Else
			scriptTemplate.SetSpeedRange( ..
				0.01 * xml.FindValueInt(nodeData, "min", Int(100 * scriptTemplate.speedMin)), ..
				0.01 * xml.FindValueInt(nodeData, "max", Int(100 * scriptTemplate.speedMax)), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.speedSlope)) ..
			)
		EndIf

		'=== DATA: RATINGS - POTENTIAL ===
		nodeData = xml.FindChild(node, "potential")
		Local potentialValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If potentialValue >= 0
			'inherit?
			'Local value:Float = 0.01 * Max(potentialValue, Int(100 * scriptTemplate.potentialMin))
			Local value:Float = 0.01 * potentialValue
			scriptTemplate.SetPotentialRange(value, value, 0.5)
		Else
			scriptTemplate.SetPotentialRange( ..
				0.01 * xml.FindValueInt(nodeData, "min", Int(100 * scriptTemplate.potentialMin)), ..
				0.01 * xml.FindValueInt(nodeData, "max", Int(100 * scriptTemplate.potentialMax)), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.potentialSlope)) ..
			)
		EndIf


		'=== DATA: BLOCKS ===
		nodeData = xml.FindChild(node, "blocks")
		Local blocksValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If blocksValue >= 0
			'inherit?
			'blocksValue = Max(blocksValue, scriptTemplate.blocksMin)
			scriptTemplate.SetBlocksRange(blocksValue, blocksValue, 0.5)
		Else
			scriptTemplate.SetBlocksRange( ..
				xml.FindValueInt(nodeData, "min", scriptTemplate.blocksMin), ..
				xml.FindValueInt(nodeData, "max", scriptTemplate.blocksMax), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.blocksSlope)) ..
			)
		EndIf

		'=== DATA: PRICE ===
		nodeData = xml.FindChild(node, "price")
		Local priceValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If priceValue >= 0
			'inherit?
			'priceValue = Max(priceValue, scriptTemplate.priceMin)
			scriptTemplate.SetPriceRange(priceValue, priceValue, 0.5)
		Else
			scriptTemplate.SetPriceRange( ..
				xml.FindValueInt(nodeData, "min", scriptTemplate.priceMin), ..
				xml.FindValueInt(nodeData, "max", scriptTemplate.priceMax), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.priceSlope)) ..
			)
		EndIf

		'=== DATA: STUDIO SIZE ===
		nodeData = xml.FindChild(node, "studio_size")
		Local studioSizeValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If studioSizeValue >= 0
			'inherit?
			'studioSizeValue = Max(studioSizeValue, scriptTemplate.studioSizeMin)
			scriptTemplate.SetStudioSizeRange(studioSizeValue, studioSizeValue, 0.5)
		Else
			scriptTemplate.SetStudioSizeRange( ..
				xml.FindValueInt(nodeData, "min", scriptTemplate.studioSizeMin), ..
				xml.FindValueInt(nodeData, "max", scriptTemplate.studioSizeMin), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.studioSizeSlope)) ..
			)
		EndIf

		'=== DATA: PRODUCTION TIME ===
		nodeData = xml.FindChild(node, "production_time")
		Local productionTimeValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If productionTimeValue >= 0
			'inherit?
			'productionTimeValue = Max(productionTimeValue, int(scriptTemplate.productionTime / TWorldTime.MINUTELENGTH))
			scriptTemplate.productionTime =  TWorldTime.MINUTELENGTH * productionTimeValue
		Else
			'we cannot simply place the min/max as default as "-1 / TWorldTime.MINUTELENGTH" results in 0 ...
			local pTMin:Int = xml.FindValueInt(nodeData, "min", -1)
			local pTMax:Int = xml.FindValueInt(nodeData, "max", -1)
			if pTMin >= 0 Then scriptTemplate.productionTimeMin = TWorldTime.MINUTELENGTH * pTMin
			if pTMax >= 0 Then scriptTemplate.productionTimeMax = TWorldTime.MINUTELENGTH * pTMax
			scriptTemplate.productionTimeSlope = 0.01 * xml.FindValueFloat(nodeData, "slope", 100 * scriptTemplate.productionTimeSlope)
		EndIf

		'=== DATA: JOBS ===
		nodeData = xml.FindChild(node, "jobs")
		If nodeData
			Local nodeJob:TxmlNode = TxmlNode(nodeData.GetFirstChild())
			While nodeJob
				'skip other elements than job
				If Not nodeJob.GetName().Equals("job", False)
'				If Not TXmlHelper.AsciiNamesLCAreEqual("job", nodeJob.getName())
					nodeJob = nodeJob.NextSibling()
					Continue
				EnDIf

				'the job index is only relevant to children/episodes in the
				'case of a partially overridden cast

				Local jobIndex:Int = xml.FindValueInt(nodeJob, "index", -1)
				Local jobFunction:Int = xml.FindValueInt(nodeJob, "function", 0)
				Local jobRequired:Int = xml.FindValueInt(nodeJob, "required", 0)
				Local jobGender:Int = xml.FindValueInt(nodeJob, "gender", 0)
				Local jobCountry:String = xml.FindValue(nodeJob, "country", "")
				'for actor jobs this defines if a specific role is defined
				Local jobRoleGUID:String = xml.FindValue(nodeJob, "role_guid", "")
				Local jobRandomRole:Int = xml.FindValueInt(nodeJob, "random_role", 0)
				Local jobPreselectCast:String = xml.FindValue(nodeJob, "person", "")

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

				nodeJob = nodeJob.NextSibling()
			Wend
		EndIf

		'=== VARIABLES ===
		'create if missing, create even without "<variables>" as the script
		'might reference parental variables
		scriptTemplate.CreateTemplateVariables()

		Local nodeVariables:TxmlNode = xml.FindChild(node, "variables")
		If nodeVariables
			Local nodeVariable:TxmlNode = TxmlNode(nodeVariables.GetFirstChild())
			While nodeVariable
				'each variable is stored as a localizedstring
				Local varName:String = nodeVariable.getName()
				Local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)
				'skip invalid
				If Not varName Or Not varString
					nodeVariable = nodeVariable.NextSibling()
					Continue
				EndIf

				scriptTemplate.templateVariables.AddVariable(varName, varString)

				nodeVariable = nodeVariable.NextSibling()
			Wend
		EndIf


		'=== SCRIPT - PRODUCT TYPE ===
		scriptTemplate.scriptProductType = scriptProductType

		'=== SCRIPT - LICENCE TYPE ===
		If parentScriptTemplate And scriptLicenceType = TVTProgrammeLicenceType.UNKNOWN
			scriptLicenceType = TVTProgrammeLicenceType.EPISODE
		EndIf
		scriptTemplate.scriptLicenceType = scriptLicenceType


		'=== SCRIPT - MISC ===
		nodeData = xml.FindChild(node, "data")
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
		Local availabilityNode:TXmlNode = xml.FindChild(node, "availability")
		scriptTemplate.availableScript = xml.FindValue(availabilityNode, "script", scriptTemplate.availableScript)
		scriptTemplate.availableYearRangeFrom = xml.FindValueInt(availabilityNode, "year_range_from", scriptTemplate.availableYearRangeFrom)
		scriptTemplate.availableYearRangeTo = xml.FindValueInt(availabilityNode, "year_range_to", scriptTemplate.availableYearRangeTo)

		If scriptTemplate.availableScript
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
		Local nodeModifiers:TxmlNode = xml.FindChild(node, "programme_data_modifiers")
		If nodeModifiers
			Local nodeModifier:TxmlNode = TxmlNode(nodeModifiers.GetFirstChild())
			While nodeModifier
				'skip other elements than "modifier"
				If Not nodeModifier.GetName().Equals("modifier", False)
					nodeModifier = nodeModifier.NextSibling()
					continue
				EndIf
		
				Local modifierData:TData = New TData
				xml.LoadAllValuesToData(nodeModifier, modifierData)
				'check if the modifier has all needed definitions
				If Not modifierData.Has("name") Then ThrowNodeError("DB: <modifier> is missing ~qname~q.", nodeModifier)
				If Not modifierData.Has("value") Then ThrowNodeError("DB: <modifier> is missing ~qvalue~q.", nodeModifier)

				if not scriptTemplate.programmeDataModifiers then scriptTemplate.programmeDataModifiers = new TData
				scriptTemplate.programmeDataModifiers.AddFloat(modifierData.GetString("name"), modifierData.GetFloat("value"))
				'source.SetModifier(modifierData.GetString("name"), modifierData.GetFloat("value"))
				
				nodeModifier = nodeModifier.NextSibling()
			Wend
		EndIf

		'=== TARGETGROUP ATTRACTIVITY MOD ===
		scriptTemplate.targetGroupAttractivityMod = GetV3TargetgroupAttractivityModFromNode(null, node, xml)

		'=== EPISODES ===
		'load children _after_ element is configured
		Local nodeChildren:TxmlNode = xml.FindChild(node, "children")
		If nodeChildren
			Local nodeChild:TxmlNode = TxmlNode(nodeChildren.GetFirstChild())
			While nodeChild
				'skip other elements than "scripttemplate"
				If Not nodeChild.GetName().Equals("scripttemplate", False)
					nodeChild = nodeChild.NextSibling()
					continue
				EndIf

				'recursively load the child script - parent is the new scriptTemplate
				Local childScriptTemplate:TScriptTemplate = LoadV3ScriptTemplateFromNode(nodeChild, xml, scriptTemplate)
				'the childIndex is currently not needed, as we autocalculate
				'it by the position in the xml-episodes-list
				'local childIndex:int = xml.FindValueInt(nodechild, "index", 1)

				'add the child
				scriptTemplate.AddSubScript(childScriptTemplate)

				nodeChild = nodeChild.NextSibling()
			Wend
		EndIf

		'=== DATA: EPISODES ===
		'load episode data only after creating the children as these values must
		'not be propagated to the children
		nodeData = xml.FindChild(node, "episodes")
		Local episodesValue:Int = xml.FindValueInt(nodeData, "value", -1)
		If episodesValue >= 0
			'inherit?
			'episodesValue = Max(episodesValue, scriptTemplate.episodesMin)
			scriptTemplate.SetEpisodesRange(episodesValue, episodesValue, 0.5)
		Else
			scriptTemplate.SetEpisodesRange( ..
				xml.FindValueInt(nodeData, "min", scriptTemplate.episodesMin), ..
				xml.FindValueInt(nodeData, "max", scriptTemplate.episodesMax), ..
				0.01 * xml.FindValueInt(nodeData, "slope", Int(100 * scriptTemplate.episodesSlope)) ..
			)
		EndIf


		'=== EFFECTS ===
		'add effects after processing the children
		'as script template does not extend TBroadcastMaterialSourceBase,
		'propagating parent effects is to big an effort here
		'it will be done when creating the script from the template
		'at this point each template gets exactly the effects defined in the database
		Local nodeEffects:TxmlNode = xml.FindChild(node, "effects")
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
		Local GUID:String = xml.FindValue(node, "guid", "")

		'try loading an existing entry (in case of extension)
		Local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(GUID)


		'=== CREATE/FETCH META DATA ===
		Local mData:TDBEntryMetaData = GetMetaData(GUID, node, xml, role <> Null)


		'=== HANDLE NEW/EXTENSION ===
		If role
			TLogger.Log("LoadV3ProgrammeRoleFromNode()", "Extending programmeRole's data ~q"+role.GetTitle()+"~q. GUID="+GUID, LOG_XML)
		Else
			'skip forbidden users (DEV)
			If Not IsAllowedUser(mData.createdBy, EDBDataTypes.PROGRAMMEROLE) Then Return Null

			role = New TProgrammeRole
			role.SetGUID(GUID)
		EndIf


		role.Init(..
			TXmlHelper.FindValue(node, "first_name", role.firstname), ..
			TXmlHelper.FindValue(node, "last_name", role.lastname), ..
			TXmlHelper.FindValue(node, "nick_name", role.nickname), ..
			TXmlHelper.FindValue(node, "title", role.title), ..
			TXmlHelper.FindValue(node, "country", role.countryCode).ToUpper(), ..
			TXmlHelper.FindValueInt(node, "gender", role.gender), ..
			TXmlHelper.FindValueInt(node, "fictional", role.fictional) ..
		)

		'=== ADD TO COLLECTION ===
		GetProgrammeRoleCollection().Add(role)

		programmeRolesCount :+ 1
		totalProgrammeRolesCount :+ 1

		Return role
	End Method


	Method GetV3TargetgroupAttractivityModFromNode:TAudience(audience:TAudience, node:TxmlNode,xml:TXmlHelper)
		Local tgAttractivityNode:TxmlNode = xml.FindChild(node, "targetgroupattractivity")
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
		Local nodeEffects:TxmlNode = xml.FindChild(node, "effects")
		If Not nodeEffects Then Return
		
		Local nodeEffect:TxmlNode = TxmlNode(nodeEffects.GetFirstChild())
		While nodeEffect
			'skip other elements than "effect"
			If Not nodeEffect.GetName().Equals("effect", False)
'			If Not TXmlHelper.AsciiNamesLCAreEqual("effect", nodeEffect.getName())
				nodeEffect = nodeEffect.NextSibling()
				Continue
			EndIf

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
			If Not effectData.Has("trigger") Then ThrowNodeError("DB: <effects> is missing ~qtrigger~q.", nodeEffect)
			If Not effectData.Has("type") Then ThrowNodeError("DB: <effects> is missing ~qtype~q.", nodeEffect)

			source.AddEffectByData(effectData)
			
			nodeEffect = nodeEffect.NextSibling()
		Wend
	End Method


	Method LoadV3ModifiersFromNode(source:TBroadcastMaterialSourceBase, node:TxmlNode,xml:TXmlHelper)
		'reuses existing (parent) modifiers and overrides it with custom
		'ones
		Local nodeModifiers:TxmlNode = xml.FindChild(node, "modifiers")
		If not nodeModifiers Then Return

		Local nodeModifier:TxmlNode = TxmlNode(nodeModifiers.GetFirstChild())
		While nodeModifier
			'skip other elements than "modifier"
			If Not nodeModifier.GetName().Equals("effect", False)
				nodeModifier = nodeModifier.NextSibling()
				Continue
			EndIf


			'check if the modifier has all needed definitions
			Local name:String = xml.FindValue(nodeModifier, "name", "")
			Local value:Float = xml.FindValueFloat(nodeModifier, "name", -12345.0)
			If Not name Then ThrowNodeError("DB: <modifier> is missing ~qname~q.", nodeModifier)
			If value = -12345.0 Then ThrowNodeError("DB: <modifier> is missing ~qvalue~q.", nodeModifier)

			source.SetModifier(name, value)
			
			nodeModifier = nodeModifier.NextSibling()
		Wend
	End Method


	'=== META DATA FUNCTIONS ===
	Method LoadV3CreatorMetaDataFromNode:TDBEntryMetaData(GUID:String, mData:TDBEntryMetaData, node:TxmlNode, xml:TXmlHelper)
		mData.creator = TXmlHelper.FindValueInt(node,"creator", 0)
		mData.createdBy = TXmlHelper.FindValue(node,"created_by", "")
		Return mData
	End Method


	Method GetMetaData:TDBEntryMetaData(GUID:String, node:TXmlNode, xml:TXmlHelper, isExistingEntry:Int = False)
		Local mData:TDBEntryMetaData
		If Not metaDataNew.TryGetValue(GUID, mData)
			mData = New TDBEntryMetaData
			metaDataNew[GUID] = mData
		EndIf
		'only assign creator data for new entries ("non overridden")
		If Not isExistingEntry
			mData = LoadV3CreatorMetaDataFromNode(GUID, mData, node, xml)
		EndIf
		Return mData
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


	Method GetBool:Int(value:String, defaultValue:Int = False)
		'special behaviour: ""/empty returns default Value
		'(but by default this is "False")
		If Not value Then Return defaultValue

		If value.Equals("true", False) or value.Equals("yes")
			Return True
		EndIf
		'also allow "1" / "1.00000" or "33"
		If Int(value) >= 1 Then Return True

		Return False
	End Method


	'load a localized string from the given node
	'only adds "non empty" strings
	'ex.:
	'<title>
	' <de>bla</de>
	'<title>
	Function GetLocalizedStringFromNode:TLocalizedString(node:TxmlNode)
		If Not node Then Return Null

		Local localized:TLocalizedString
		'if no languages were used:
		'<var1>
		'  <de>bla</de>
		'  <en>bla</en>
		'</var>
		'then use the
		'node itself so you can use a global value
		'<var1>bla</var1> 
		Local nodeLangEntry:TxmlNode = TxmlNode(node.GetFirstChild())
		If not nodeLangEntry
			_ExtractLangForLocalizedString(node, localized, TLocalization.defaultLanguageID)
		Else
			While nodeLangEntry
				Local nodeLangEntryName:String = nodeLangEntry.GetName()
				If nodeLangEntryName.Equals("all", False)
				'If TXmlHelper.AsciiNamesLCAreEqual("all", nodeLangEntryName)
					'same base value for all default languages
					_ExtractLangForLocalizedString(nodeLangEntry, localized, -2)
				Else
					Local languageID:Int = TLocalization.GetLanguageID( nodeLangEntryName.ToLower() )
					_ExtractLangForLocalizedString(nodeLangEntry, localized, languageID)
				EndIf
				
				nodeLangEntry = nodeLangEntry.NextSibling()
			Wend
		EndIf

		Function _ExtractLangForLocalizedString(nodeLangEntry:TxmlNode, localized:TLocalizedString var, languageID:Int = -1)
			'do not trim, as this corrupts variables like "<de> %WORLDTIME:YEAR%</de>" (with space!)
			Local value:String = nodeLangEntry.getContent().Replace("~~n", "~n") '.Trim()

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
		End Function

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
