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
Import "game.programme.programmeperson.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "game.gameconstants.bmx"


Type TDatabaseLoader
	Field programmeRolesCount:Int, totalProgrammeRolesCount:Int
	Field scriptTemplatesCount:Int, totalscriptTemplatesCount:Int
	Field moviesCount:Int, totalMoviesCount:Int
	Field seriesCount:Int, totalSeriesCount:Int
	Field newsCount:Int, totalNewsCount:Int
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
		dirTree.SetExcludeFileNames(["database_people", "database_ads", "database_programmes", "database_news"])

		'add the rest of available files in the given dir
		'(this also sorts the files)
		dirTree.ScanDir(dbDirectory)

		'add that files at the top
		'(in reversed order as each is added at top of the others!)
		dirTree.AddFile(dbDirectory+"/database_achievements.xml", True) '5
		dirTree.AddFile(dbDirectory+"/database_programmes.xml", True) '4
		dirTree.AddFile(dbDirectory+"/database_news.xml", True) '3
		dirTree.AddFile(dbDirectory+"/database_ads.xml", True) '2
		dirTree.AddFile(dbDirectory+"/database_people.xml", True) '1


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
		EndIf

		If required And (totalSeriesCount = 0 Or totalMoviesCount = 0 Or totalNewsCount = 0 Or totalContractsCount = 0)
			Notify "Important data is missing:  series:"+totalSeriesCount+"  movies:"+totalMoviesCount+"  news:"+totalNewsCount+"  adcontracts:"+totalContractsCount
		EndIf


		'fix potentially corrupt data
		FixLoadedData()
	End Method


	Method Load(fileURI:String)
		config.AddString("currentFileURI", fileURI)

		Local xml:TXmlHelper = TXmlHelper.Create(fileURI)
		'reset "per database" variables
		moviesCount = 0
		seriesCount = 0
		newsCount = 0
		achievementCount = 0
		contractsCount = 0
		personsCount = 0
		personsBaseCount = 0

		'recognize version
		Local versionNode:TxmlNode = xml.FindRootChild("version")
		'by default version number is "2"
		Local version:Int = 2
		If versionNode Then version = xml.FindValueInt(versionNode, "value", 2)

		'load according to version
		Select version
'			case 2	LoadV2(xml)
			Case 2	TLogger.Log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - version 2 is deprecated. Upgrade to V3 please." , LOG_LOADING)
			Case 3	LoadV3(xml)
			Default	TLogger.Log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - UNKNOWN VERSION." , LOG_LOADING)
		End Select
	End Method


	Method LoadV3:Int(xml:TXmlHelper)
		stopWatch.Init()

		'===== IMPORT ALL PERSONS =====
		'so they can get referenced properly
		Local nodeAllPersons:TxmlNode
		'insignificant (non prominent) people
		nodeAllPersons = xml.FindRootChild("insignificantpeople")
		For Local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
			If nodePerson.getName() <> "person" Then Continue

			'param false = load as insignificant
			If LoadV3ProgrammePersonBaseFromNode(nodePerson, xml, False)
				personsBaseCount :+ 1
				totalPersonsBaseCount :+ 1
			EndIf
		Next

		'celebrities (they have more details)
		nodeAllPersons = xml.FindRootChild("celebritypeople")
		For Local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
			If nodePerson.getName() <> "person" Then Continue

			'param true = load as celebrity
			If LoadV3ProgrammePersonBaseFromNode(nodePerson, xml, True)
				personsCount :+ 1
				totalPersonsCount :+ 1
			EndIf
		Next


		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====
		Local nodeAllAds:TxmlNode = xml.FindRootChild("allads")
		If nodeAllAds
			For Local nodeAd:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllAds)
				If nodeAd.getName() <> "ad" Then Continue

				LoadV3AdContractBaseFromNode(nodeAd, xml)
			Next
		EndIf


		'===== IMPORT ALL NEWS EVENTS =====
		Local nodeAllNews:TxmlNode = xml.FindRootChild("allnews")
		If nodeAllNews
			For Local nodeNews:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllNews)
				If nodeNews.getName() <> "news" Then Continue

				LoadV3NewsEventTemplateFromNode(nodeNews, xml)
			Next
		EndIf


		'===== IMPORT ALL PROGRAMMES (MOVIES/SERIES) =====
		'ATTENTION: LOAD PERSONS FIRST !!
		Local nodeAllProgrammes:TxmlNode = xml.FindRootChild("allprogrammes")
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


		'===== IMPORT ALL PROGRAMME ROLES =====
		Local nodeAllRoles:TxmlNode = xml.FindRootChild("programmeroles")
		If nodeAllRoles
			For Local nodeRole:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllRoles)
				If nodeRole.getName() <> "programmerole" Then Continue

				LoadV3ProgrammeRoleFromNode(nodeRole, xml)
			Next
		EndIf


		'===== IMPORT ALL SCRIPT (TEMPLATES) =====
		Local nodeAllScriptTemplates:TxmlNode = xml.FindRootChild("scripttemplates")
		If nodeAllScriptTemplates
			For Local nodeScriptTemplate:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllScriptTemplates)
				If nodeScriptTemplate.getName() <> "scripttemplate" Then Continue

				LoadV3ScriptTemplateFromNode(nodeScriptTemplate, xml)
			Next
		EndIf



		'===== IMPORT ALL ACHIEVEMENTS =====
		Local nodeAllAchievements:TxmlNode = xml.FindRootChild("allachievements")
		If nodeAllAchievements
			For Local nodeAchievement:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllAchievements)
				If nodeAchievement.getName() <> "achievement" Then Continue

				LoadV3AchievementFromNode(nodeAchievement, xml)
			Next
		EndIf


		TLogger.Log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 3). Found " + seriesCount + " series, " + moviesCount + " movies, " + personsBaseCount + "/" + personsCount +" basePersons/persons, " + contractsCount + " advertisements, " + newsCount + " news, " + achievementCount+" achievements. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method



	'=== HELPER ===

	Method LoadV3ProgrammePersonBaseFromNode:TProgrammePersonBase(node:TxmlNode, xml:TXmlHelper, isCelebrity:Int=True)
		Local GUID:String = xml.FindValue(node,"id", "")

		'fetch potential meta data
		Local mData:TData = LoadV3ProgrammePersonBaseMetaDataFromNode(GUID, node, xml, isCelebrity)
		If mData Then metaData.Add(GUID, mData )

		'skip forbidden users (DEV)
		If Not IsAllowedUser(mData.GetString("createdBy"), "person") Then Return Null

		'try to fetch an existing one
		Local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID(GUID)
		'if the person existed, remove it from all lists and later add
		'it back to the one defined by "isCelebrity"
		'this allows other database.xml's to morph a insignificant
		'person into a celebrity
		If person
			GetProgrammePersonBaseCollection().RemoveInsignificant(person)
			GetProgrammePersonBaseCollection().RemoveCelebrity(person)

			'convert to celebrity if required
			If isCelebrity And Not TProgrammePerson(person)
				person = ConvertInsignificantToCelebrity(person)
			EndIf
			TLogger.Log("LoadV3ProgrammePersonBaseFromNode()", "Extending programmePersonBase ~q"+person.GetFullName()+"~q. GUID="+person.GetGUID(), LOG_XML)
		Else
			If isCelebrity
				person = New TProgrammePerson
			Else
				person = New TProgrammePersonBase
			EndIf

			person.GUID = GUID
		EndIf


		'=== COMMON DETAILS ===
		Local data:TData = New TData
		xml.LoadValuesToData(node, data, [..
			"first_name", "last_name", "nick_name", "fictional", "levelup", "country", ..
			"job", "gender", "generator", "face_code", "bookable" ..
		])


		Local generator:String = data.GetString("generator", "")
		Local p:TPersonGeneratorEntry
		If generator
			p = GetPersonGenerator().GetUniqueDatasetFromString(generator)
			If p
				person.firstName = p.firstName
				person.lastName = p.lastName
				person.countryCode = p.countryCode
			Else
				person.firstName = GUID
			EndIf

			person.fictional = True
		EndIf

		'override with given ones
		person.firstName = data.GetString("first_name", person.firstName)
		person.lastName = data.GetString("last_name", person.lastName)
		person.nickName = data.GetString("nick_name", person.nickName)
		person.fictional = data.GetBool("fictional", person.fictional)
		person.bookable = data.GetBool("bookable", person.bookable)
		person.countryCode = data.GetString("country", person.countryCode)
		person.canLevelUp = data.GetInt("levelup", person.canLevelUp)
		person.SetJob(data.GetInt("job", person.job))
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
		If TProgrammePerson(person)
			'create a celebrity to avoid casting each time
			Local celebrity:TProgrammePerson = TProgrammePerson(person)

			'=== IMAGES ===
			Local nodeImages:TxmlNode = xml.FindChild(node, "images")
			data = New TData
			'contains custom fictional overriding the base one
			xml.LoadValuesToData(nodeImages, data, [..
				"face_code" ..
			])
			celebrity.faceCode = data.GetString("face_code", celebrity.faceCode)


			'=== DETAILS ===
			Local nodeDetails:TxmlNode = xml.FindChild(node, "details")
			data = New TData
			'contains custom "fictional" overriding the base one
			xml.LoadValuesToData(nodeDetails, data, [..
				"gender", "birthday", "deathday", "country", "fictional", ..
				"job" ..
			])
			celebrity.gender = data.GetInt("gender", celebrity.gender)
			celebrity.SetDayOfBirth( data.GetString("birthday", celebrity.dayOfBirth) )
			celebrity.SetDayOfDeath( data.GetString("deathday", celebrity.dayOfDeath) )
			celebrity.countryCode = data.GetString("country", celebrity.countryCode)
			celebrity.fictional = data.GetInt("fictional", celebrity.fictional)
			celebrity.SetJob( data.GetInt("job", celebrity.job) )

			'=== DATA ===
			Local nodeData:TxmlNode = xml.FindChild(node, "data")
			data = New TData
			xml.LoadValuesToData(nodeData, data, [..
				"skill", "fame", "scandalizing", "price_mod", ..
				"power", "humor", "charisma", "appearance", ..
				"topgenre1", "topgenre2", "prominence"..
			])
			celebrity.skill = 0.01 * data.GetFloat("skill", 100*celebrity.skill)
			celebrity.fame = 0.01 * data.GetFloat("fame", 100*celebrity.fame)
			celebrity.scandalizing = 0.01 * data.GetFloat("scandalizing", 100*celebrity.scandalizing)
			celebrity.priceModifier = 0.01 * data.GetFloat("price_mod", 100*celebrity.priceModifier)
			'0 would mean: cuts price to 0
			If celebrity.priceModifier = 0 Then celebrity.priceModifier = 1.0
			celebrity.power = 0.01 * data.GetFloat("power", 100*celebrity.power)
			celebrity.humor = 0.01 * data.GetFloat("humor", 100*celebrity.humor)
			celebrity.charisma = 0.01 * data.GetFloat("charisma", 100*celebrity.charisma)
			celebrity.appearance = 0.01 * data.GetFloat("appearance", 100*celebrity.appearance)
			celebrity.topGenre1 = data.GetInt("topgenre1", celebrity.topGenre1)
			celebrity.topGenre2 = data.GetInt("topgenre2", celebrity.topGenre2)
			'TODO: prominence - manual popularity indicator?

			'fill not given attributes with random data
			If celebrity.fictional Then celebrity.SetRandomAttributes(True)
		EndIf


		'=== ADD TO COLLECTION ===
		'we removed the person from all lists already, now add it back
		'to the one we wanted
		If isCelebrity
			GetProgrammePersonBaseCollection().AddCelebrity(person)
		Else
			GetProgrammePersonBaseCollection().AddInsignificant(person)
		EndIf

		Return person
	End Method


	Method LoadV3NewsEventTemplateFromNode:TNewsEventTemplate(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValue(node,"id", "")
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
		Else
			doAdd = False

			TLogger.Log("LoadV3NewsEventTemplateFromNodeFromNode()", "Extending newsEventTemplate ~q"+newsEventTemplate.GetTitle()+"~q. GUID="+newsEventTemplate.GetGUID(), LOG_XML)
		EndIf

		'=== LOCALIZATION DATA ===
		newsEventTemplate.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		newsEventTemplate.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )

		'news type according to TVTNewsType - InitialNews, FollowingNews...
		newsEventTemplate.newsType = xml.FindValueInt(node,"type", 0)


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		Local data:TData = New TData
		'price and topicality are outdated
		xml.LoadValuesToData(nodeData, data, [..
			"genre", "price", "quality", "available", "flags", ..
			"keywords", "happen_time", "min_subscription_level" ..
		])

		newsEventTemplate.flags = data.GetInt("flags", newsEventTemplate.flags)
		newsEventTemplate.genre = data.GetInt("genre", newsEventTemplate.genre)
		newsEventTemplate.keywords = data.GetString("keywords", newsEventTemplate.keywords).ToLower()
		newsEventTemplate.minSubscriptionLevel = data.GetInt("min_subscription_level", newsEventTemplate.minSubscriptionLevel)

		Local available:Int = data.GetBool("available", Not newsEventTemplate.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		newsEventTemplate.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'topicality is "quality" here
		newsEventTemplate.quality = 0.01 * data.GetFloat("quality", 100 * newsEventTemplate.quality)
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
					'GetWorldTime().CalcTime_Auto( happenTimeParams[0], happenTimeParams[1 ..] )
					Local useParams:Int[] = [-1,-1,-1,-1,-1,-1,-1,-1]
					For Local i:Int = 1 Until happenTimeParams.length
						useParams[i-1] = happenTimeParams[i]
					Next
					newsEventTemplate.happenTime = GetWorldTime().CalcTime_Auto( happenTimeParams[0], useParams )
				EndIf
			EndIf
		EndIf



		'=== CONDITIONS ===
		Local nodeConditions:TxmlNode = xml.FindChild(node, "conditions")
		data = New TData
		xml.LoadValuesToData(nodeConditions, data, [..
			"year_range_from", "year_range_to" ..
		])
		newsEventTemplate.availableYearRangeFrom = data.GetInt("year_range_from", newsEventTemplate.availableYearRangeFrom)
		newsEventTemplate.availableYearRangeTo = data.GetInt("year_range_to", newsEventTemplate.availableYearRangeTo)

		'=== AVAILABILITY ===
		xml.LoadValuesToData(xml.FindChild(node, "availability"), data, [..
			"script", "year_range_from", "year_range_to" ..
		])
		newsEventTemplate.availableScript = data.GetString("script", newsEventTemplate.availableScript)
		newsEventTemplate.availableYearRangeFrom = data.GetInt("year_range_from", newsEventTemplate.availableYearRangeFrom)
		newsEventTemplate.availableYearRangeTo = data.GetInt("year_range_to", newsEventTemplate.availableYearRangeTo)

		If newsEventTemplate.availableScript
			If Not GetScriptExpression().IsValid(newsEventTemplate.availableScript)
				TLogger.Log("DB", "Script of NewsEventTemplate ~q" + newsEventTemplate.GetGUID() + "~q contains errors:", LOG_WARNING)
				TLogger.Log("DB", GetScriptExpression()._error, LOG_WARNING)
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
		For Local nodeVariable:TxmlNode = EachIn xml.GetNodeChildElements(nodeVariables)
			'each variable is stored as a localizedstring
			Local varName:String = nodeVariable.getName()
			Local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)

			'skip invalid
			If Not varName Or Not varString Then Continue

			'create if missing
			newsEventTemplate.CreateTemplateVariables()
			newsEventTemplate.templateVariables.AddVariable("%"+varName+"%", varString)
		Next



		'=== ADD TO COLLECTION ===
		If doAdd
			GetNewsEventTemplateCollection().Add(newsEventTemplate)
			If newsEventTemplate.newsType <> TVTNewsType.FollowingNews
				newsCount :+ 1
			EndIf
			totalNewsCount :+ 1
		EndIf

		Return newsEventTemplate
	End Method


	Method LoadV3AchievementFromNode:TAchievement(node:TxmlNode, xml:TXmlHelper)
		Local GUID:String = xml.FindValue(node,"id", "")
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
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		Local data:TData = New TData
		xml.LoadValuesToData(nodeData, data, [ ..
			"flags", "category", "group", "index", ..
			"sprite_finished", "sprite_unfinished" ..
		])

		achievement.flags = data.GetInt("flags", achievement.flags)
		achievement.group = data.GetInt("group", achievement.group)
		achievement.index = data.GetInt("index", achievement.index)
		achievement.category = data.GetInt("category", achievement.category)
		achievement.spriteFinished = data.GetString("sprite_finished", achievement.spriteFinished)
		achievement.spriteUnfinished = data.GetString("sprite_unfinished", achievement.spriteUnfinished)


		'=== TASKS ===
		Local nodeTasks:TxmlNode = xml.FindChild(node, "tasks")
		For Local nodeElement:TxmlNode = EachIn xml.GetNodeChildElements(nodeTasks)
			If nodeElement.getName() <> "task" Then Continue

			LoadV3AchievementElementFromNode("task", achievement, nodeElement, xml)
		Next


		'=== REWARDS ===
		Local nodeRewards:TxmlNode = xml.FindChild(node, "rewards")
		For Local nodeElement:TxmlNode = EachIn xml.GetNodeChildElements(nodeRewards)
			If nodeElement.getName() <> "reward" Then Continue

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
		Local GUID:String = xml.FindValue(node,"id", "")

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
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		Local data:TData = New TData
		xml.LoadAllValuesToData(nodeData, data)
		'check if the element has all needed configurations
		'for now this is only "type"
		If Not reuseExisting
			For Local f:String = EachIn ["type"]
				If Not data.Has(f) Then ThrowNodeError("DB: <"+elementName+"> is missing ~q" + f+"~q.", nodeData)
			Next
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
		Local GUID:String = xml.FindValue(node,"id", "")
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
		adContract.adType = xml.FindValueInt(node,"type", 0)


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		Local data:TData = New TData
		xml.LoadValuesToData(nodeData, data, [..
			"infomercial", "quality", "repetitions", ..
			"fix_price", "duration", "profit", "penalty", ..
			"pro_pressure_groups", "contra_pressure_groups", ..
			"infomercial_profit", "fix_infomercial_profit", ..
			"year_range_from", "year_range_to", ..
			"available", "blocks", "type" ..
		])

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
		'do not reset "data" before - it contains the pressure groups
		xml.LoadValuesToData(xml.FindChild(node, "availability"), data, [..
			"script", "year_range_from", "year_range_to" ..
		])
		adContract.availableScript = data.GetString("script", adContract.availableScript)
		adContract.availableYearRangeFrom = data.GetInt("year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = data.GetInt("year_range_to", adContract.availableYearRangeTo)

		If adContract.availableScript
			If Not GetScriptExpression().IsValid(adContract.availableScript)
				TLogger.Log("DB", "Script of AdContract ~q" + adContract.GetGUID() + "~q contains errors:", LOG_WARNING)
				TLogger.Log("DB", GetScriptExpression()._error, LOG_WARNING)
			EndIf
		EndIf


		'=== CONDITIONS ===
		Local nodeConditions:TxmlNode = xml.FindChild(node, "conditions")
		'do not reset "data" before - it contains the pressure groups
		xml.LoadValuesToData(nodeConditions, data, [..
			"min_audience", "min_image", "max_image", "target_group", ..
			"allowed_programme_type", "allowed_programme_flag", "allowed_genre", ..
			"prohibited_programme_type", "prohibited_programme_flag", "prohibited_genre" ..
		])
		'0-100% -> 0.0 - 1.0
		adContract.minAudienceBase = 0.01 * data.GetFloat("min_audience", adContract.minAudienceBase*100.0)
		adContract.minImage = 0.01 * data.GetFloat("min_image", adContract.minImage*100.0)
		adContract.maxImage = 0.01 * data.GetFloat("max_image", adContract.maxImage*100.0)
		adContract.limitedToTargetGroup = data.GetInt("target_group", adContract.limitedToTargetGroup)
		adContract.limitedToProgrammeGenre = data.GetInt("allowed_genre", adContract.limitedToProgrammeGenre)
		adContract.limitedToProgrammeType = data.GetInt("allowed_programme_type", adContract.limitedToProgrammeType)
		adContract.limitedToProgrammeFlag = data.GetInt("allowed_programme_flag", adContract.limitedToProgrammeFlag)
		adContract.forbiddenProgrammeGenre = data.GetInt("prohibited_genre", adContract.forbiddenProgrammeGenre)
		adContract.forbiddenProgrammeType = data.GetInt("prohibited_programme_type", adContract.forbiddenProgrammeType)
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
		Local GUID:String = TXmlHelper.FindValue(node,"id", "")
		'referencing an already existing programmedata? Or just use "data-GUID"
		Local dataGUID:String = TXmlHelper.FindValue(node,"programmedata_id", "data-"+GUID)
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
		productType = TXmlHelper.FindValueInt(node,"product", productType)

		Local licenceType:Int = -1
		If programmeLicence Then licenceType = programmeLicence.licenceType
		licenceType = TXmlHelper.FindValueInt(node,"licence_type", licenceType)


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
				'try to clone the parent's data - if that fails, create
				'a new instance
				If parentLicence Then programmeData = TProgrammeData(THelper.CloneObject(parentLicence.data, "id"))
				'if failed, create new data
				If Not programmeData Then programmeData = New TProgrammeData

				programmeData.GUID = dataGUID
				programmeData.title = New TLocalizedString
				programmeData.originalTitle = New TLocalizedString
				programmeData.description = New TLocalizedString
				programmeData.titleProcessed = Null
				programmeData.descriptionProcessed = Null

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
		programmeData.originalTitle.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "originalTitle")) )
		programmeData.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'=== DATA ===
		Local nodeData:TxmlNode = xml.FindChild(node, "data")
		Local data:TData = New TData
		xml.LoadValuesToData(nodeData, data, [..
			"country", "distribution", "blocks", ..
			"maingenre", "subgenre", "price_mod", ..
			"available", "flags", "licence_flags", ..
			"broadcast_time_slot_start", "broadcast_time_slot_end", ..
			"broadcast_limit", "data_broadcast_limit", "licence_broadcast_limit", ..
			"broadcast_flags", "data_broadcast_flags", "licence_broadcast_flags" ..
		]) 'also allow a "<live>" block
		'], ["live"]) 'also allow a "<live>" block

		programmeData.country = data.GetString("country", programmeData.country)

		programmeData.distributionChannel = data.GetInt("distribution", programmeData.distributionChannel)
		programmeData.blocks = data.GetInt("blocks", programmeData.blocks)

		programmeData.broadcastTimeSlotStart = data.GetInt("broadcast_time_slot_start", programmeData.broadcastTimeSlotStart)
		programmeData.broadcastTimeSlotEnd = data.GetInt("broadcast_time_slot_end", programmeData.broadcastTimeSlotEnd)
		If programmeData.broadcastTimeSlotStart = programmeData.broadcastTimeSlotEnd
			programmeData.broadcastTimeSlotStart = -1
			programmeData.broadcastTimeSlotEnd = -1
		EndIf

		'both get the same limit (except individually configured)
		programmeData.SetBroadcastLimit( data.GetInt("data_broadcast_limit", data.GetInt("broadcast_imit", programmeData.broadcastLimit)) )
		programmeLicence.SetBroadcastLimit( data.GetInt("licence_broadcast_limit", data.GetInt("broadcast_limit", programmeLicence.broadcastLimit)) )

		'both get the same flags (except individually configured)
		programmeData.broadcastFlags = data.GetInt("data_broadcast_flags", data.GetInt("broadcast_flags", programmeData.broadcastFlags))
		programmeLicence.broadcastFlags = data.GetInt("licence_broadcast_flags", data.GetInt("broadcast_flags", programmeLicence.broadcastFlags))

		programmeLicence.licenceFlags = data.GetInt("licence_flags", programmeLicence.licenceFlags)

		Local available:Int = data.GetBool("available", Not programmeData.hasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE))
		programmeData.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)
		programmeLicence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE, Not available)

		'compatibility: load price mod from "price_mod" first... later
		'override with "modifiers"-data
		programmeData.SetModifier("price", data.GetFloat("price_mod", programmeData.GetModifier("price")))

		programmeData.flags = data.GetInt("flags", programmeData.flags)

		programmeData.genre = data.GetInt("maingenre", programmeData.genre)
		For Local sg:String = EachIn data.GetString("subgenre", "").split(",")
			If Trim(sg) = "" Then Continue
			If Int(sg) < 0 Then Continue

			If Not MathHelper.InIntArray(Int(sg), programmeData.subGenres)
				programmeData.subGenres :+ [Int(sg)]
			EndIf
		Next


		'=== RELEASE INFORMATION ===
		Local releaseData:TData = New TData
		Local timeFields:String[] = [..
			"year", "year_relative", "year_relative_min", "year_relative_max", ..
			"day", "day_random_min", "day_random_max", "day_random_slope", ..
			"hour", "hour_random_min", "hour_random_max", "day_random_slope" ..
		]
		'try to load it from the "<data>" block
		'(this is done to allow the old v3-"year" definition)
		xml.LoadValuesToData(nodeData, releaseData, timeFields)
		'override data by a <releaseTime> block
		Local releaseTimeNode:TxmlNode = xml.FindChild(node, "releaseTime")
		If releaseTimeNode
			xml.LoadValuesToData(releaseTimeNode, releaseData, timeFields)
		EndIf

		'convert various time definitions to an absolute time
		'(this relies on "GetWorldTime()" being initialized already with
		' the game time)
		programmeData.releaseTime = CreateReleaseTime(releaseData, programmeData.releaseTime)
		If programmeData.releaseTime = 0
			Print "Failed to create releaseTime for ~q"+programmeData.GetTitle()+"~q (GUID: ~q"+GUID+"~q."
		EndIf

		'=== STAFF ===
		Local nodeStaff:TxmlNode = xml.FindChild(node, "staff")
		For Local nodeMember:TxmlNode = EachIn xml.GetNodeChildElements(nodeStaff)
			If nodeMember.getName() <> "member" Then Continue

			Local memberIndex:Int = xml.FindValueInt(nodeMember, "index", 0)
			Local memberFunction:Int = xml.FindValueInt(nodeMember, "function", 0)
			Local memberGenerator:String = xml.FindValue(nodeMember, "generator", "")
			Local memberGUID:String = nodeMember.GetContent().Trim()

			Local member:TProgrammePersonBase
			If memberGUID Then member = GetProgrammePersonBaseCollection().GetByGUID(memberGUID)
			'create a simple person so jobs could get added to persons
			'which are created after that programme
			If Not member
				member = New TProgrammePersonBase
				member.fictional = True

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
						member.countryCode = p.countryCode
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

				'add if we have a valid guid now
				If memberGUID
					member.SetGUID(memberGUID)
					GetProgrammePersonBaseCollection().AddInsignificant(member)
				EndIf
			EndIf

			'member now is capable of doing this job
			member.SetJob(memberFunction)
			'add cast
			programmeData.AddCast(New TProgrammePersonJob.Init(memberGUID, memberFunction))
		Next



		'=== GROUPS ===
		Local nodeGroups:TxmlNode = xml.FindChild(node, "groups")
		data = New TData
		xml.LoadValuesToData(nodeGroups, data, [..
			"target_groups", "pro_pressure_groups", "contra_pressure_groups" ..
		])
		programmeData.targetGroups = data.GetInt("target_groups", programmeData.targetGroups)
		programmeData.proPressureGroups = data.GetInt("pro_pressure_groups", programmeData.proPressureGroups)
		programmeData.contraPressureGroups = data.GetInt("contra_pressure_groups", programmeData.contraPressureGroups)



		'=== TARGETGROUP ATTRACTIVITY MOD ===
		programmeData.targetGroupAttractivityMod = GetV3TargetgroupAttractivityModFromNode(programmeData.targetGroupAttractivityMod, node, xml)


		'=== EFFECTS ===
		LoadV3EffectsFromNode(programmeData, node, xml)



		'=== MODIFIERS ===
		'take over modifiers from parent (if episode)
		If parentLicence Then programmeData.effects = parentLicence.data.effects.Copy()
		LoadV3ModifiersFromNode(programmeData, node, xml)



		'=== RATINGS ===
		Local nodeRatings:TxmlNode = xml.FindChild(node, "ratings")
		data = New TData
		xml.LoadValuesToData(nodeRatings, data, [..
			"critics", "speed", "outcome" ..
		])
		programmeData.review = 0.01 * data.GetFloat("critics", programmeData.review*100)
		programmeData.speed = 0.01 * data.GetFloat("speed", programmeData.speed*100)
		programmeData.outcome = 0.01 * data.GetFloat("outcome", programmeData.outcome*100)

		'auto repair outcome for non-custom productions
		'(eg. predefined ones from the DB)
		If Not programmeData.IsCustomProduction() Then programmeData.FixOutcome()



		'=== PRODUCT TYPE ===
		programmeData.productType = productType



		'=== LICENCE TYPE ===
		'the licenceType is adjusted as soon as "AddData" was used
		'so correct it if needed
		If parentLicence And licenceType = TVTProgrammeLicenceType.UNKNOWN
			licenceType = TVTProgrammeLicenceType.EPISODE
		EndIf
		programmeLicence.licenceType = licenceType



		'=== EPISODES ===
		Local nodeEpisodes:TxmlNode = xml.FindChild(node, "children")
		For Local nodeEpisode:TxmlNode = EachIn xml.GetNodeChildElements(nodeEpisodes)
			'skip other elements than programme data
			If nodeEpisode.getName() <> "programme" Then Continue

			'if until now the licence type was not defined, define it now
			'-> collections cannot get autorecognized, they NEED to get
			'   defined correctly
			If licenceType = -1
				Print "autocorrect: "+GUID+" to SERIES HEADER"
				licenceType = TVTProgrammeLicenceType.SERIES
			EndIf

			'recursively load the episode - parent is the new programmeLicence
			Local episodeLicence:TProgrammeLicence = LoadV3ProgrammeLicenceFromNode(nodeEpisode, xml, programmeLicence)

			'the episodeNumber is currently not needed, as we
			'autocalculate it by the position in the xml-episodes-list
			'local episodeNumber:int = xml.FindValueInt(nodeEpisode, "index", -1)
			Local episodeNumber:Int = -1

			'only add episode if not already done
			If programmeLicence = episodeLicence.GetParentLicence()
				TLogger.Log("LoadV3ProgrammeLicenceFromNode()","Episode: ~q"+episodeLicence.GetTitle()+"~q already added to series: ~q"+episodeLicence.GetParentLicencE().GetTitle()+"~q. Skipped.", LOG_XML)
				Continue
			EndIf

			'inform if we add an episode again
			If episodeLicence.GetParentLicence() And episodeLicence.parentLicenceGUID
				TLogger.Log("LoadV3ProgrammeLicenceFromNode()","Episode: ~q"+episodeLicence.GetTitle()+"~q already has parent: ~q"+episodeLicence.GetParentLicencE().GetTitle()+"~q. Multi-usage intended?", LOG_XML)
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

		Return programmeLicence
	End Method


	Method LoadV3ScriptTemplateFromNode:TScriptTemplate(node:TxmlNode, xml:TXmlHelper, parentScriptTemplate:TScriptTemplate = Null)
		Local GUID:String = TXmlHelper.FindValue(node,"guid", "")
		Local scriptProductType:Int = TXmlHelper.FindValueInt(node,"product", 1)
		Local oldType:Int = TXmlHelper.FindValueInt(node,"type", TVTProgrammeLicenceType.SINGLE)
		Local scriptLicenceType:Int = TXmlHelper.FindValueInt(node,"licence_type", oldType)
		Local index:Int = TXmlHelper.FindValueInt(node,"index", 0)
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
			If parentScriptTemplate Then scriptTemplate = TScriptTemplate(THelper.CloneObject(parentScriptTemplate, "id"))
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
		data = New TData
		xml.LoadValuesToData(nodeData, data, ["mainGenre", "subGenres"])
		scriptTemplate.mainGenre = data.GetInt("mainGenre", 0)
		For Local sg:String = EachIn data.GetString("subGenres", "").split(",")
			'skip empty or "undefined" genres
			If Int(sg) = 0 Then Continue
			If Not MathHelper.InIntArray(Int(sg), scriptTemplate.subGenres)
				scriptTemplate.subGenres :+ [Int(sg)]
			EndIf
		Next



		'=== DATA: RATINGS - OUTCOME ===
		nodeData = xml.FindChild(node, "outcome")
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
		nodeData = xml.FindChild(node, "review")
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
		nodeData = xml.FindChild(node, "speed")
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
		nodeData = xml.FindChild(node, "potential")
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
		nodeData = xml.FindChild(node, "blocks")
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
		nodeData = xml.FindChild(node, "price")
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


		'=== DATA: JOBS ===
		nodeData = xml.FindChild(node, "jobs")
		For Local nodeJob:TxmlNode = EachIn xml.GetNodeChildElements(nodeData)
			If nodeJob.getName() <> "job" Then Continue

			'the job index is only relevant to children/episodes in the
			'case of a partially overridden cast

			Local jobIndex:Int = xml.FindValueInt(nodeJob, "index", -1)
			Local jobFunction:Int = xml.FindValueInt(nodeJob, "function", 0)
			Local jobRequired:Int = xml.FindValueInt(nodeJob, "required", 0)
			Local jobGender:Int = xml.FindValueInt(nodeJob, "gender", 0)
			Local jobCountry:String = xml.FindValue(nodeJob, "country", "")
			'for actor jobs this defines if a specific role is defined
			Local jobRoleGUID:String = xml.FindValue(nodeJob, "role_guid", "")

			'create a job without an assigned person
			Local job:TProgrammePersonJob = New TProgrammePersonJob.Init("", jobFunction, jobGender, jobCountry, jobRoleGUID)
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

		Local nodeVariables:TxmlNode = xml.FindChild(node, "variables")
		For Local nodeVariable:TxmlNode = EachIn xml.GetNodeChildElements(nodeVariables)
			'each variable is stored as a localizedstring
			Local varName:String = nodeVariable.getName()
			Local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)

			'skip invalid
			If Not varName Or Not varString Then Continue

			scriptTemplate.templateVariables.AddVariable("%"+varName+"%", varString)
		Next


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
			"scriptflags", "flags", "flags_optional", "keywords", ..
			"productionBroadcastFlags", "productionLicenceFlags", "productionBroadcastLimit" ..
		])
		scriptTemplate.scriptFlags = data.GetInt("scriptflags", scriptTemplate.scriptFlags)

		scriptTemplate.flags = data.GetInt("flags", scriptTemplate.flags)
		scriptTemplate.flagsOptional = data.GetInt("flags_optional", scriptTemplate.flagsOptional)

		scriptTemplate.keywords = data.GetString("keywords", scriptTemplate.keywords).Trim()

		scriptTemplate.productionBroadcastFlags = data.GetInt("productionBroadcastFlags", scriptTemplate.productionBroadcastFlags)
		scriptTemplate.productionLicenceFlags = data.GetInt("productionLicenceFlags", scriptTemplate.productionLicenceFlags)
		scriptTemplate.productionBroadcastLimit = data.GetInt("productionBroadcastLimit", scriptTemplate.productionBroadcastLimit)


		'=== AVAILABILITY ===
		xml.LoadValuesToData(xml.FindChild(node, "availability"), data, [..
			"script", "year_range_from", "year_range_to" ..
		])
		scriptTemplate.availableScript = data.GetString("script", scriptTemplate.availableScript)
		scriptTemplate.availableYearRangeFrom = data.GetInt("year_range_from", scriptTemplate.availableYearRangeFrom)
		scriptTemplate.availableYearRangeTo = data.GetInt("year_range_to", scriptTemplate.availableYearRangeTo)


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


		'=== EPISODES ===
		'load children _after_ element is configured
		Local nodeChildren:TxmlNode = xml.FindChild(node, "children")
		For Local nodeChild:TxmlNode = EachIn xml.GetNodeChildElements(nodeChildren)
			'skip other elements than scripttemplate
			If nodeChild.getName() <> "scripttemplate" Then Continue

			'recursively load the child script - parent is the new scriptTemplate
			Local childScriptTemplate:TScriptTemplate = LoadV3ScriptTemplateFromNode(nodeChild, xml, scriptTemplate)

			'the childIndex is currently not needed, as we autocalculate
			'it by the position in the xml-episodes-list
			'local childIndex:int = xml.FindValueInt(nodechild, "index", 1)

			'add the child
			scriptTemplate.AddSubScript(childScriptTemplate)
		Next


		'=== ADD TO COLLECTION ===
		GetScriptTemplateCollection().Add(scriptTemplate)

		scriptTemplatesCount :+ 1
		totalScriptTemplatesCount :+ 1

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
			TXmlHelper.FindValue(node, "title", role.title), ..
			TXmlHelper.FindValue(node, "country", role.countryCode), ..
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
		For Local tgIndex:Int = 1 To TVTTargetGroup.baseGroupCount '1-7
			searchData[searchIndex+0] = TVTTargetGroup.GetAsString( TVTTargetGroup.GetAtIndex(tgIndex) )
			searchData[searchIndex+1] = TVTTargetGroup.GetAsString( TVTTargetGroup.GetAtIndex(tgIndex) ) +"_male"
			searchData[searchIndex+2] = TVTTargetGroup.GetAsString( TVTTargetGroup.GetAtIndex(tgIndex) ) +"_female"
			searchIndex :+ 3
		Next
		xml.LoadValuesToData(tgAttractivityNode, data, searchData)

		'loop over all genders (all, male, female) and assign found numbers
		'- making sure to start with "all" allows assign "base", then
		'  specific (if desired)
		If Not audience Then audience = New TAudience.InitValue(1.0, 1.0)
		For Local genderIndex:Int = 0 To TVTPersonGender.count
			Local genderID:Int = TVTPersonGender.GetAtIndex(genderIndex)
			Local genderString:String = TVTpersonGender.GetAsString( genderID )

			For Local tgIndex:Int = 1 To TVTTargetGroup.baseGroupCount '1-7
				Local tgID:Int = TVTTargetGroup.GetAtIndex(tgIndex)
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
		Local nodeModifiers:TxmlNode = xml.FindChild(node, "modifiers")
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
		data.AddNumber("creator", TXmlHelper.FindValueInt(node,"creator", 0))
		data.AddString("createdBy", TXmlHelper.FindValue(node,"created_by", ""))
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


	Method LoadV3ProgrammePersonBaseMetaDataFromNode:TData(GUID:String, node:TxmlNode, xml:TXmlHelper, isCelebrity:Int=True)
		Local data:TData = metaData.GetData(GUID)
		If Not data Then data = New TData

		'only set creator if it is the "non overridden" one
		If Not GetProgrammePersonBaseCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		EndIf

		'also load the original name if possible
		xml.LoadValuesToData(node, data, [..
			"first_name_original", "last_name_original", "nick_name_original", ..
			"imdb", "tmdb" ..
		])


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


	Function CreateReleaseTime:Long(releaseData:TData, oldReleaseTime:Long)
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

		MathHelper.SortIntValues(releaseYearRelativeMin, releaseYearRelativeMax)
		MathHelper.SortIntValues(releaseDayRandomMin, releaseDayRandomMax)
		MathHelper.SortIntValues(releaseHourRandomMin, releaseHourRandomMax)


		'no year definition? use the given one
		If releaseYear = 0 And releaseYearRelative = 0 And oldReleaseTime <> 0
			Return oldReleaseTime
		EndIf


'alles in einen string packen und folgende Berechnungen "bei Bedarf"
'ausfuehren

		'= YEAR =
		If releaseYear = 0 Then releaseYear = GetWorldTime().GetYear() + releaseYearRelative
		If releaseYearRelativeMax = 0 Then releaseYearRelativeMax = releaseYear
		releaseYear = MathHelper.Clamp(releaseYear, releaseYearRelativeMin, releaseYearRelativeMax)

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
		Return GetWorldTime().MakeTime(releaseYear, releaseDay, releaseHour, 0, 0)
	End Function


	Method FixLoadedData()
		FixPersonsDayOfBirth()
	End Method


	Method FixPersonsDayOfBirth()
		'=== CHECK BIRTHDATES ===
		'persons might have been used in productions dated earlier than
		'their hardcoded day-of-birth

		'only TProgrammePerson have a DOB, so we could skip insignificants
		For Local person:TProgrammePerson = EachIn GetProgrammePersonBaseCollection().celebrities.Values()
			'ignore persons without a given date of birth
			If person.GetDOB() <= 0 Then Continue


			'loop through all known productions and find earliest date
			Local earliestProductionData:TProgrammeData
			For Local programmeDataGUID:String = EachIn person.GetProducedProgrammes()
				Local programmeData:TProgrammeData = GetProgrammeDataCollection().GetByGUID(programmeDataGUID)
				If Not programmeData
					TLogger.Log("TDatabase.FixLoadedDate()", "No ProgrammeData found for GUID ~q"+programmeDataGUID+"~q.", LOG_ERROR)
					Continue
				EndIf

				If Not earliestProductionData Or programmeData.GetYear() < earliestProductionData.GetYear()
					earliestProductionData = programmeData
				EndIf
			Next

			'no production found
			If Not earliestProductionData Then Continue

			'person should be at least 5 years (fictional)
			Local dobYear:Int = GetWorldTime().GetYear( person.GetDOB() )
			Local ageOnProduction:Int = earliestProductionData.GetProductionStartTime() - person.GetDOB()
			Local ageOnProductionYears:Int = earliestProductionData.GetYear() - dobYear
			Local adjustAge:Int = False

			'in "time", not years - so babies are possible (eg. actors)
			If ageOnProduction <= 0
				TLogger.Log("TDatabase.FixLoadedData()", "Person ~q"+person.GetFullName()+"~q (GUID=~q"+person.getGUID()+"~q) is born in "+dobYear+". Impossible to have produced ~q"+earliestProductionData.GetTitle()+" in "+earliestProductionData.GetYear()+".", LOG_LOADING | LOG_WARNING)
				adjustAge = True
			ElseIf ageOnProductionYears < 5
				'too young director or scriptwriter
				If earliestProductionData.HasCastPerson(person.GetGUID(), TVTProgrammePersonJob.DIRECTOR | TVTProgrammePersonJob.SCRIPTWRITER)
					TLogger.Log("TDatabase.FixLoadedData()", "Person ~q"+person.GetFullName()+"~q (GUID=~q"+person.getGUID()+"~q) is born in "+dobYear+". Impossible to have produced ~q"+earliestProductionData.GetTitle()+" in "+earliestProductionData.GetYear()+". Directors and Scriptwriters need to be at least 5 years old.", LOG_LOADING | LOG_WARNING)
					adjustAge = True
				EndIf
			EndIf

			If adjustAge
				'we are able to correct non-fictional ones
				If person.fictional
					person.dayOfBirth = (earliestProductionData.GetYear() - RandRange(5,25)) + "-" + GetWorldTime().GetMonth(person.GetDOB()) + "-" + GetWorldTime().GetDayOfYear(person.GetDOB())
					Local dobYearNew:Int = GetWorldTime().GetYear( person.GetDOB() )
					TLogger.Log("TDatabase.FixLoadedData()", "Adjusted DOB of person ~q"+person.GetFullName()+"~q (GUID=~q"+person.getGUID()+"~q). Was "+dobYear+" and is now "+dobYearNew+".", LOG_LOADING | LOG_WARNING)
				Else
					TLogger.Log("TDatabase.FixLoadedData()", "Cannot adjust DOB of person ~q"+person.GetFullName()+"~q (GUID=~q"+person.getGUID()+"~q). Person is non-fictional, so DOB should be correct.", LOG_LOADING | LOG_WARNING)
				EndIf
			EndIf
		Next
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

		Local foundEntry:Int = True
		Local localized:TLocalizedString = New TLocalizedString
		For Local nodeLangEntry:TxmlNode = EachIn TxmlHelper.GetNodeChildElements(node)
			Local language:String = nodeLangEntry.GetName().ToLower()
			Local languageID:Int = TLocalization.GetLanguageID(language)
			'do not trim, as this corrupts variables like "<de> %WORLDTIME:YEAR%</de>" (with space!)
			Local value:String = nodeLangEntry.getContent() '.Trim()

			If value <> ""
				localized.Set(value, languageID)
				foundEntry = True
			EndIf
		Next

		If Not foundEntry Then Return Null
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