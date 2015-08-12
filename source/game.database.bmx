SuperStrict
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.directorytree.bmx"
Import "Dig/base.util.xmlhelper.bmx"

Import "game.production.scripttemplate.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"
Import "game.programme.programmeperson.bmx"
Import "game.gameconstants.bmx"


Type TDatabaseLoader
	Field programmeRolesCount:Int, totalProgrammeRolesCount:Int
	Field scriptTemplatesCount:Int, totalscriptTemplatesCount:Int
	Field moviesCount:Int, totalMoviesCount:Int
	Field seriesCount:Int, totalSeriesCount:Int
	Field newsCount:Int, totalNewsCount:Int
	Field contractsCount:Int, totalContractsCount:Int

	Field loadError:String = ""

	Field releaseDayCounter:int = 0
	Field stopWatchAll:TStopWatch = new TStopWatch.Init()
	Field stopWatch:TStopWatch = new TStopWatch.Init()

	Field allowedAdCreators:string
	Field skipAdCreators:string
	Field allowedProgrammeCreators:string
	Field skipProgrammeCreators:string
	Field config:TData = New TData

	Method New()
		allowedAdCreators = ""
		For local s:string = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_ADS_CREATED_BY", "*").Split(",")
			allowedAdCreators :+ " "+trim(s).ToLower()+" " 
		Next

		skipAdCreators = ""
		For local s:string = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_ADS_CREATED_BY", "").Split(",")
			skipAdCreators :+ " "+trim(s).ToLower()+" " 
		Next

		allowedProgrammeCreators = ""
		For local s:string = EachIn GameRules.devConfig.GetString("DEV_DATABASE_LOAD_PROGRAMMES_CREATED_BY", "*").Split(",")
			allowedProgrammeCreators :+ " "+trim(s).ToLower()+" " 
		Next

		skipProgrammeCreators = ""
		For local s:string = EachIn GameRules.devConfig.GetString("DEV_DATABASE_SKIP_PROGRAMMES_CREATED_BY", "").Split(",")
			skipProgrammeCreators :+ " "+trim(s).ToLower()+" "
		Next
	End Method


	Method IsAllowedUser:Int(username:string, dataType:string)
		local allowed:string
		local skip:string

		username = username.ToLower().replace("unknown", "*")
		username = username.Trim()
		if username = "" then username = "*"
		
		Select dataType.ToLower()
			case "adcontract"
				allowed = allowedAdCreators
				skip = skipAdCreators
			case "programmelicence"
				allowed = allowedProgrammeCreators
				skip = skipProgrammeCreators
		EndSelect

		'all allowed? -> check "skip"
		if allowed.Find(" * ") >= 0
			'cannot skip all when loading all
			if skip.Find(" * ") >= 0
				print "ALLOWED * and SKIPPED * ... not possible. Type: "+dataType+". Allowing ALL creators for this type."
				Return True
			endif
			
			if skip.Find(" "+username+" ") >= 0
				print "all allowed but skipping: " +username + "   " + skip.Find(" "+username+" ")
				Return False
			endif
			return True
		'only selected allowed
		else
			if allowed.Find(" "+username+" ") >= 0 then Return True
			return False
			print "not all allowed    username="+username+"    allowed="+allowed +"   skipped="+skip
		endif
		return False
	End Method


	Method LoadDir(dbDirectory:string)
		'build file list of xml files in the given directory
		local dirTree:TDirectoryTree = new TDirectoryTree.Init(dbDirectory, ["xml"], null, ["*"])
		'exclude "database.xml" as we add it by default to load it
		'as the first file
		dirTree.AddIncludeFileNames(["*"])
		'dirTree.AddExcludeFileNames(["database", "database_v2"])
		'add that database.xml - old v2 first
		'dirTree.AddFile(dbDirectory+"/database_v2.xml")
		'dirTree.AddFile(dbDirectory+"/database.xml")

		'add the rest of available files in the given dir
		dirTree.ScanDir()

		local fileURIs:String[] = dirTree.GetFiles()
		'loop over all filenames
		for local fileURI:String = EachIn fileURIs
			'skip non-existent files
			if filesize(fileURI) = 0 then continue
			
			Load(fileURI)
		Next

		TLogger.log("TDatabase.Load()", "Loaded from "+fileURIs.length + " DBs. Found " + totalSeriesCount + " series, " + totalMoviesCount + " movies, " + totalContractsCount + " advertisements, " + totalNewsCount + " news, " + totalProgrammeRolesCount + " roles in scripts, " + totalScriptTemplatesCount + " script templates. Loading time: " + stopWatchAll.GetTime() + "ms", LOG_LOADING)

		if totalSeriesCount = 0 or totalMoviesCount = 0 or totalNewsCount = 0 or totalContractsCount = 0
			Notify "Important data is missing:  series:"+totalSeriesCount+"  movies:"+totalMoviesCount+"  news:"+totalNewsCount+"  adcontracts:"+totalContractsCount
		endif
	End Method


	Method Load(fileURI:string)
		config.AddString("currentFileURI", fileURI)
	
		local xml:TXmlHelper = TXmlHelper.Create(fileURI)
		'reset "per database" variables
		moviesCount = 0
		seriesCount = 0
		newsCount = 0
		contractsCount = 0

		'recognize version
		local versionNode:TxmlNode = xml.FindRootChild("version")
		'by default version number is "2"
		local version:int = 2
		if versionNode then version = xml.FindValueInt(versionNode, "value", 2)
		
		'load according to version
		Select version
'			case 2	LoadV2(xml)
			case 2	TLogger.log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - version 2 is deprecated. Upgrade to V3 please." , LOG_LOADING)
			case 3	LoadV3(xml)
			Default	TLogger.log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - UNKNOWN VERSION." , LOG_LOADING)
		End Select
	End Method


rem
	Method LoadV2:Int(xml:TXmlHelper)
		stopWatch.Init()

		Local title:String
		Local description:String
		Local directors:TProgrammePersonBase[], directorsRaw:String
		Local actors:TProgrammePersonBase[], actorsRaw:String
		Local land:String
		Local year:Int
		Local Genre:Int
		Local duration:Int
		Local xrated:Int
		Local priceModifier:Float
		Local review:Float
		Local speed:Float
		Local Outcome:Float
		Local livehour:Int
		Local refreshModifier:float = 1.0
		Local wearoffModifier:float = 1.0

		Local daystofinish:Int
		Local spotcount:Int
		Local targetgroup:Int
		Local minimage:Float
		Local minaudience:Float
		Local fixedPrice:Int
		Local profit:Float
		Local penalty:Float
		local price:Float
		Local quality:Float

		local nodeParent:TxmlNode
		local nodeChild:TxmlNode
		local nodeEpisode:TxmlNode


		'===== IMPORT ALL MOVIES =====

		'Print "reading movies from database"
		nodeParent = xml.FindRootChild("allmovies")
		for nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "movie" then continue

			'skip if not "all" are allowed (no creator data available)
			if not IsAllowedUser("*", "programmelicence") then continue

			title       = xml.FindValue(nodeChild,"title", "unknown title")
			description = xml.FindValue(nodeChild,"description", "23")
			actorsRaw   = xml.FindValue(nodeChild,"actors", "")
			directorsRaw= xml.FindValue(nodeChild,"director", "")
			land        = xml.FindValue(nodeChild,"country", "UNK")
			year 		= xml.FindValueInt(nodeChild,"year", 1900)
			Genre 		= xml.FindValueInt(nodeChild,"genre", 0 )
			duration    = xml.FindValueInt(nodeChild,"blocks", 2)
			xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
			review 		= xml.FindValueInt(nodeChild,"critics", 0) / 255.0
			speed 		= xml.FindValueInt(nodeChild,"speed", 0) / 255.0
			Outcome 	= xml.FindValueInt(nodeChild,"outcome", 0) / 255.0
			livehour 	= xml.FindValueInt(nodeChild,"time", 0)
			'modifiers
			priceModifier = xml.FindValueInt(nodeChild,"price", 255) / 255.0 /1.5 'normalize to "normal = 1.0", original values are bit higher
			refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
			wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
			If duration < 0 Or duration > 12 Then duration =1

			'print title+": priceModifier="+priceModifier+"  review="+review+"  speed="+speed+"  Outcome="+outcome


			local cast:TProgrammePersonJob[]
			For local p:TProgrammePerson = EachIn GetPersonsFromString(directorsRaw, TVTProgrammePersonJob.DIRECTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TVTProgrammePersonJob.DIRECTOR)]
			Next
			For local p:TProgrammePerson = EachIn GetPersonsFromString(actorsRaw, TVTProgrammePersonJob.ACTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TVTProgrammePersonJob.ACTOR)]
			Next

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			local modifiers:TData = new TData
			modifiers.AddNumber("price", priceModifier)
			modifiers.AddNumber("refresh", refreshModifier)
			modifiers.AddNumber("wearoff", wearoffModifier)
			
			local movieLicence:TProgrammeLicence = new TProgrammeLicence
			movieLicence.SetData(TProgrammeData.Create("", localizeTitle, localizeDescription, cast, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, modifiers, Genre, duration, xrated, TVTProgrammeProductType.MOVIE))

			'convert old genre definition to new one
			convertV2genreToV3(movieLicence.data)
			
			'add to collection (it is sorted automatically)
			GetProgrammeLicenceCollection().AddAutomatic(movieLicence)
			movieLicence.SetOwner(TOwnedGameObject.OWNER_NOBODY)

			releaseDaycounter:+1
			moviesCount :+1
			totalMoviesCount :+ 1
		Next


		'===== IMPORT ALL SERIES INCLUDING EPISODES =====

		nodeParent = xml.FindRootChild("allseries")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "serie" then continue

			'skip if not "all" are allowed (no creator data available)
			if not IsAllowedUser("*", "programmelicence") then continue

			'load series main data - in case episodes miss data
			title       = xml.FindValue(nodeChild,"title", "unknown title")
			description = xml.FindValue(nodeChild,"description", "")
			actorsRaw   = xml.FindValue(nodeChild,"actors", "")
			directorsRaw= xml.FindValue(nodeChild,"director", "")
			land        = xml.FindValue(nodeChild,"country", "UNK")
			year 		= xml.FindValueInt(nodeChild,"year", 1900)
			Genre 		= xml.FindValueInt(nodeChild,"genre", 0)
			duration    = xml.FindValueInt(nodeChild,"blocks", 2)
			xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
			priceModifier = xml.FindValueInt(nodeChild,"price", 255) / 255.0 /1.5 'normalize to "normal = 1.0"
			review 		= xml.FindValueInt(nodeChild,"critics", -1) / 255.0
			speed 		= xml.FindValueInt(nodeChild,"speed", -1) / 255.0
			Outcome 	= xml.FindValueInt(nodeChild,"outcome", -1) / 255.0
			livehour 	= xml.FindValueInt(nodeChild,"time", -1)
			refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
			wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
			If duration < 0 Or duration > 12 Then duration =1


			local cast:TProgrammePersonJob[]
			For local p:TProgrammePersonBase = EachIn GetPersonsFromString(directorsRaw, TVTProgrammePersonJob.DIRECTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TVTProgrammePersonJob.DIRECTOR)]
			Next
			For local p:TProgrammePersonBase = EachIn GetPersonsFromString(actorsRaw, TVTProgrammePersonJob.ACTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TVTProgrammePersonJob.ACTOR)]
			Next

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			local modifiers:TData = new TData
			modifiers.AddNumber("price", priceModifier)
			modifiers.AddNumber("refresh", refreshModifier)
			modifiers.AddNumber("wearoff", wearoffModifier)

			'create a licence for that series - with title and series description
			local seriesLicence:TProgrammeLicence = new TProgrammeLicence
			'sets the "overview"-data of the series as series header
			seriesLicence.SetData(TProgrammeData.Create("", localizeTitle, localizeDescription, cast, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, modifiers, Genre, duration, xrated, TVTProgrammeProductType.SERIES))

			'convert old genre definition to new one
			convertV2genreToV3(seriesLicence.data)

			releaseDaycounter:+1

			'load episodes
			Local EpisodeNum:Int = 0
			For nodeEpisode = EachIn TXmlHelper.GetNodeChildElements(nodeChild)
				If nodeEpisode.getName() = "episode"
					EpisodeNum	= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
					title      	= xml.FindValue(nodeEpisode,"title", title)
					description = xml.FindValue(nodeEpisode,"description", description)
					actorsRaw   = xml.FindValue(nodeEpisode,"actors", actorsRaw)
					directorsRaw= xml.FindValue(nodeEpisode,"director", directorsRaw)
					land        = xml.FindValue(nodeEpisode,"country", land)
					year 		= xml.FindValueInt(nodeEpisode,"year", year)
					Genre 		= xml.FindValueInt(nodeEpisode,"genre", Genre)
					duration    = xml.FindValueInt(nodeEpisode,"blocks", duration)
					xrated 		= xml.FindValueInt(nodeEpisode,"xrated", xrated)
					priceModifier = xml.FindValueInt(nodeEpisode,"price", priceModifier * 255 * 1.5) / 255.0 /1.5 'normalize to "normal = 1.0"
					review 		= xml.FindValueInt(nodeEpisode,"critics", review) / 255.0
					speed 		= xml.FindValueInt(nodeEpisode,"speed", speed) / 255.0
					Outcome 	= xml.FindValueInt(nodeEpisode,"outcome", Outcome) / 255.0
					livehour	= xml.FindValueInt(nodeEpisode,"time", livehour)
					refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", refreshModifier)
					wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", wearoffModifier)


					local cast:TProgrammePersonJob[]
					For local p:TProgrammePersonBase = EachIn GetPersonsFromString(directorsRaw, TVTProgrammePersonJob.DIRECTOR)
						cast :+ [new TProgrammePersonJob.Init(p, TVTProgrammePersonJob.DIRECTOR)]
					Next
					For local p:TProgrammePersonBase = EachIn GetPersonsFromString(actorsRaw, TVTProgrammePersonJob.ACTOR)
						cast :+ [new TProgrammePersonJob.Init(p, TVTProgrammePersonJob.ACTOR)]
					Next

					local localizeTitle:TLocalizedString = new TLocalizedString
					localizeTitle.Set(title, "de")
					local localizeDescription:TLocalizedString = new TLocalizedString
					localizeDescription.Set(description, "de")

					local modifiers:TData = new TData
					modifiers.AddNumber("price", priceModifier)
					modifiers.AddNumber("refresh", refreshModifier)
					modifiers.AddNumber("wearoff", wearoffModifier)

					local episodeLicence:TProgrammeLicence = new TProgrammeLicence
					episodeLicence.SetData(TProgrammeData.Create("", localizeTitle, localizeDescription, cast, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, modifiers, Genre, duration, xrated, TVTProgrammeProductType.SERIES))
					'add that episode to the series licence
					seriesLicence.AddSubLicence(episodeLicence)

					'convert old genre definition to new one
					convertV2genreToV3(episodeLicence.data)

					'add episode to global collection (it is sorted automatically)
					GetProgrammeLicenceCollection().AddAutomatic(episodeLicence)
				EndIf
			Next

			'add to collection (it is sorted automatically)
			GetProgrammeLicenceCollection().AddAutomatic(seriesLicence)
			seriesLicence.SetOwner(TOwnedGameObject.OWNER_NOBODY)

			seriesCount :+ 1
			totalSeriesCount :+ 1
		Next


		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====

		nodeParent = xml.FindRootChild("allads")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "ad" then continue

			'skip if not "all" are allowed (no creator data available)
			if not IsAllowedUser("*", "adcontract") then continue

			title       = xml.FindValue(nodeChild,"title", "unknown title")
			description = xml.FindValue(nodeChild,"description", "")
			targetgroup = xml.FindValueInt(nodeChild,"targetgroup", 0)
			spotcount	= xml.FindValueInt(nodeChild,"repetitions", 1)
			'0-50% -> 0.0 - 0.5
			minaudience	= xml.FindValueInt(nodeChild,"minaudience", 0) /255.0
			minimage	= xml.FindValueInt(nodeChild,"minimage", 0) /255.0
			fixedPrice = xml.FindValueInt(nodeChild,"fixedprice", 0)
			if fixedPrice
				profit	= xml.FindValueInt(nodeChild,"profit", 0)
				penalty	= xml.FindValueInt(nodeChild,"penalty", 0)
			else
				'30 is the factor the old v2-values got multiplied with
				'after normalizing - so do this to make them comparable
				profit	= 30 * xml.FindValueFloat(nodeChild,"profit", 0)
				penalty	= 30 * xml.FindValueFloat(nodeChild,"penalty", 0)
			endif
			daystofinish= xml.FindValueInt(nodeChild,"duration", 1)

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			'convert targetgroup to v3
			targetGroup = TVTTargetGroup.GetAtIndex(targetGroup)
			
			local ad:TAdContractBase = new TAdContractBase.Create("", localizeTitle, localizeDescription, daystofinish, spotcount, targetgroup, minaudience, minimage, fixedPrice, profit, penalty)

			contractsCount :+ 1
			totalContractsCount :+ 1
		Next


		'===== IMPORT ALL NEWS INCLUDING EPISODES =====
		Local newsEvent:TNewsEvent

		nodeParent		= xml.FindRootChild("allnews")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "news" then continue
			'load series main data
			title       = xml.FindValue(nodeChild,"title", "unknown newstitle")
			description	= xml.FindValue(nodeChild,"description", "")
			genre		= xml.FindValueInt(nodeChild,"genre", 0)
			quality		= 0.01 * 3.0/8.0 * xml.FindValueFloat(nodeChild,"topicality", 0)
			price		= 1.0 + 0.01 * 3.0/8.0 * xml.FindValueFloat(nodeChild,"price", 0)

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")
					
			newsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, Genre, quality, price, TVTNewsType.InitialNews)
			GetNewsEventCollection().Add(newsEvent)

			'load episodes
			Local EpisodeNum:Int = 0
			For nodeEpisode = EachIn TXmlHelper.GetNodeChildElements(nodeChild)
				If nodeEpisode.getName() <> "episode" then continue
				EpisodeNum		= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
				title			= xml.FindValue(nodeEpisode,"title", "unknown Newstitle")
				description		= xml.FindValue(nodeEpisode,"description", "")
				genre			= xml.FindValueInt(nodeEpisode,"genre", genre)
				quality			= 0.01 * 3.0/8.0 * xml.FindValueFloat(nodeEpisode,"topicality", quality * 100 * 8.0/3.0)
				price			= 1.0 + 0.01 * 3.0/8.0 * xml.FindValueFloat(nodeEpisode,"price", (price-1.0) * 100 * 8.0/3.0)

				local localizeTitle:TLocalizedString = new TLocalizedString
				localizeTitle.Set(title, "de")
				local localizeDescription:TLocalizedString = new TLocalizedString
				localizeDescription.Set(description, "de")

				'in V2 triggeredNews are of type "followingNews" !
				local triggeredNewsEvent:TNewsEvent = new TNewsEvent.Init("", localizeTitle, localizeDescription, Genre, quality, price, TVTNewsType.FollowingNews)
				GetNewsEventCollection().Add(triggeredNewsEvent)

				'add the found episode as a triggereffect to the news
				newsEvent.AddHappenEffect(new TNewsEffect_TriggerNews.Init(triggeredNewsEvent.GetGUID()))

				'set the found episode as current newsEvent, so the next
				'episode gets added as triggereffect to that news episode then
				newsEvent = triggeredNewsEvent

				totalnewscount :+1
			Next

			newsCount :+ 1
			totalNewsCount :+ 1
		Next
		TLogger.log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 2). Found " + seriesCount + " series, " + moviesCount + " movies, " + contractsCount + " advertisements, " + newsCount + " news. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method
endrem

	Method LoadV3:Int(xml:TXmlHelper)
		stopWatch.Init()

		'===== IMPORT ALL PERSONS =====
		'so they can get referenced properly
		local nodeAllPersons:TxmlNode
		'insignificant (non prominent) people
		nodeAllPersons = xml.FindRootChild("insignificantpeople")
		For local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
			If nodePerson.getName() <> "person" then continue

			'param false = load as insignificant
			LoadV3ProgrammePersonBaseFromNode(nodePerson, xml, FALSE)
		Next

		'celebrities (they have more details)
		nodeAllPersons = xml.FindRootChild("celebritypeople")
		For local nodePerson:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllPersons)
			If nodePerson.getName() <> "person" then continue

			'param true = load as celebrity
			LoadV3ProgrammePersonBaseFromNode(nodePerson, xml, TRUE)
		Next
		

		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====
		local nodeAllAds:TxmlNode = xml.FindRootChild("allads")
		if nodeAllAds
			For local nodeAd:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllAds)
				If nodeAd.getName() <> "ad" then continue

				LoadV3AdContractBaseFromNode(nodeAd, xml)
			Next
		endif


		'===== IMPORT ALL NEWS EVENTS =====
		local nodeAllNews:TxmlNode = xml.FindRootChild("allnews")
		if nodeAllNews
			For local nodeNews:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllNews)
				If nodeNews.getName() <> "news" then continue

				LoadV3NewsEventFromNode(nodeNews, xml)
			Next
		endif


		'===== IMPORT ALL PROGRAMMES (MOVIES/SERIES) =====
		'!!!!
		'attention: LOAD PERSONS FIRST !!
		'!!!!
		local nodeAllProgrammes:TxmlNode = xml.FindRootChild("allprogrammes")
		if nodeAllProgrammes
			For local nodeProgramme:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllProgrammes)
				If nodeProgramme.getName() <> "programme" then continue

				'creates a TProgrammeLicence of the found entry.
				'If the entry contains "episodes", they get loaded too
				local licence:TProgrammeLicence
				licence = LoadV3ProgrammeLicenceFromNode(nodeProgramme, xml)

				if licence
					if licence.isSingle()
						moviesCount :+ 1
						totalMoviesCount :+ 1
					elseif licence.isSeries()
						seriesCount :+ 1
						totalSeriesCount :+ 1
					endif

					'add children
					For local sub:TProgrammeLicence = EachIn licence.subLicences
						GetProgrammeLicenceCollection().AddAutomatic(sub)
					Next
					
					GetProgrammeLicenceCollection().AddAutomatic(licence)
				endif
			Next
		endif


		'===== IMPORT ALL PROGRAMME ROLES =====
		local nodeAllRoles:TxmlNode = xml.FindRootChild("programmeroles")
		if nodeAllRoles
			For local nodeRole:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllRoles)
				If nodeRole.getName() <> "programmerole" then continue

				LoadV3ProgrammeRoleFromNode(nodeRole, xml)
			Next
		endif


		'===== IMPORT ALL SCRIPT (TEMPLATES) =====
		local nodeAllScriptTemplates:TxmlNode = xml.FindRootChild("scripttemplates")
		if nodeAllScriptTemplates
			For local nodeScriptTemplate:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllScriptTemplates)
				If nodeScriptTemplate.getName() <> "scripttemplate" then continue

				LoadV3ScriptTemplateFromNode(nodeScriptTemplate, xml)
			Next
		endif


		TLogger.log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 3). Found " + seriesCount + " series, " + moviesCount + " movies, " + contractsCount + " advertisements, " + newsCount + " news. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method



	'=== HELPER ===

	Method LoadV3ProgrammePersonBaseFromNode:TProgrammePersonBase(node:TxmlNode, xml:TXmlHelper, isCelebrity:int=True)
		local GUID:String = xml.FindValue(node,"id", "")

		'fetch potential meta data
		LoadV3ProgrammePersonBaseMetaDataFromNode(GUID, node, xml, isCelebrity)

		'try to fetch an existing one
		local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID(GUID)
		'if the person existed, remove it from all lists and later add
		'it back to the one defined by "isCelebrity"
		'this allows other database.xml's to morph a insignificant
		'person into a celebrity
		if person
			GetProgrammePersonBaseCollection().RemoveInsignificant(person)
			GetProgrammePersonBaseCollection().RemoveCelebrity(person)

			'convert to celebrity if required
			if isCelebrity and not TProgrammePerson(person)
				local newPerson:TProgrammePerson
				person = TProgrammePerson(THelper.TakeOverObjectValues(person, newPerson))
			endif
		else
			if isCelebrity
				person = new TProgrammePerson
			else
				person = new TProgrammePersonBase
			endif
			
			person.GUID = GUID
		endif


		'=== COMMON DETAILS ===
		local data:TData = new TData
		xml.LoadValuesToData(node, data, [..
			"first_name", "last_name", "nick_name", "fictional", "levelup" ..
		])

		person.firstName = data.GetString("first_name", person.firstName)
		person.lastName = data.GetString("last_name", person.lastName)
		person.nickName = data.GetString("nick_name", person.nickName)
		person.fictional = data.GetInt("fictional", person.fictional)
		person.canLevelUp = data.GetInt("levelup", person.canLevelUp)


		'=== CELEBRITY SPECIFIC DATA ===
		'only for celebrities
		if TProgrammePerson(person)
			'create a celebrity to avoid casting each time
			local celebrity:TProgrammePerson = TProgrammePerson(person)


			'=== DETAILS ===
			local nodeDetails:TxmlNode = xml.FindElementNode(node, "details")
			data = new TData
			'contains custom fictional overriding the base one
			xml.LoadValuesToData(nodeDetails, data, [..
				"gender", "birthday", "deathday", "country", "fictional" ..
			])
			celebrity.gender = data.GetInt("gender", celebrity.gender)
			celebrity.SetDayOfBirth( data.GetString("birthday", celebrity.dayOfBirth) )
			celebrity.SetDayOfDeath( data.GetString("deathday", celebrity.dayOfDeath) )
			celebrity.country = data.GetString("country", celebrity.country)
			celebrity.fictional = data.GetInt("fictional", celebrity.fictional)
			

			'=== DATA ===
			local nodeData:TxmlNode = xml.FindElementNode(node, "data")
			data = new TData
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
			if celebrity.priceModifier = 0 then celebrity.priceModifier = 1.0
			celebrity.power = 0.01 * data.GetFloat("power", 100*celebrity.power)
			celebrity.humor = 0.01 * data.GetFloat("humor", 100*celebrity.humor)
			celebrity.charisma = 0.01 * data.GetFloat("charisma", 100*celebrity.charisma)
			celebrity.appearance = 0.01 * data.GetFloat("appearance", 100*celebrity.appearance)
			celebrity.topGenre1 = data.GetInt("topgenre1", celebrity.topGenre1)
			celebrity.topGenre2 = data.GetInt("topgenre2", celebrity.topGenre2)
		endif


		'=== ADD TO COLLECTION ===
		'we removed the person from all lists already, now add it back
		'to the one we wanted 
		if isCelebrity
			GetProgrammePersonBaseCollection().AddCelebrity(person)
		else
			GetProgrammePersonBaseCollection().AddInsignificant(person)
		endif

		return person
	End Method


	Method LoadV3NewsEventFromNode:TNewsEvent(node:TxmlNode, xml:TXmlHelper)
		local GUID:String = xml.FindValue(node,"id", "")
		local doAdd:int = True

		'fetch potential meta data
		LoadV3NewsEventMetaDataFromNode(GUID, node, xml)

		'try to fetch an existing one
		local newsEvent:TNewsEvent = GetNewsEventCollection().GetByGUID(GUID)
		if not newsEvent
			newsEvent = new TNewsEvent
			newsEvent.title = new TLocalizedString
			newsEvent.description = new TLocalizedString
			newsEvent.GUID = GUID
		else
			doAdd = False
		endif
		
		'=== LOCALIZATION DATA ===
		newsEvent.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		newsEvent.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )

		'news type according to TVTNewsType - InitialNews, FollowingNews...
		newsEvent.newsType = xml.FindValueInt(node,"type", 0)


		'=== DATA ===
		local nodeData:TxmlNode = xml.FindElementNode(node, "data")
		local data:TData = new TData
		xml.LoadValuesToData(nodeData, data, [..
			"genre", "price", "topicality" ..
		])
			
		newsEvent.genre = data.GetInt("genre", newsEvent.genre)
		'topicality is "quality" here
		newsEvent.quality = 0.01 * data.GetFloat("topicality", 100 * newsEvent.quality)
		'price is "priceModifier" here (so add 1.0 until that is done in DB)
		newsEvent.priceModifier = 1.0 + 0.01 * data.GetFloat("price", 100 * (newsEvent.priceModifier-1.0))
	

		'=== CONDITIONS ===
		local nodeConditions:TxmlNode = xml.FindElementNode(node, "conditions")
		data = new TData
		xml.LoadValuesToData(nodeConditions, data, [..
			"year_range_from", "year_range_to" ..
		])
		newsEvent.availableYearRangeFrom = data.GetInt("year_range_from", newsEvent.availableYearRangeFrom)
		newsEvent.availableYearRangeTo = data.GetInt("year_range_to", newsEvent.availableYearRangeTo)


		'=== EFFECTS ===
		local nodeEffects:TxmlNode = xml.FindElementNode(node, "effects")
		For local nodeEffect:TxmlNode = EachIn xml.GetNodeChildElements(nodeEffects)
			If nodeEffect.getName() <> "effect" then continue

			local effectData:TData = new TData
			xml.LoadValuesToData(nodeEffect, effectData, [..
				"type", "parameter1", "parameter2", "parameter3", ..
				"parameter4", "parameter5" ..
			])
			'parameter1 = GUID
			'parameter2-5 = param 1-4 of effect
			newsEvent.AddEffectByData(effectData)
		Next
	

		'=== ADD TO COLLECTION ===
		if doAdd
			GetNewsEventCollection().Add(newsEvent)
			if newsEvent.newsType <> TVTNewsType.FollowingNews
				newsCount :+ 1
			endif
			totalNewsCount :+ 1
		endif

		return newsEvent
	End Method	


	Method LoadV3AdContractBaseFromNode:TAdContractBase(node:TxmlNode, xml:TXmlHelper)
		local GUID:String = xml.FindValue(node,"id", "")
		local doAdd:int = True

		'fetch potential meta data
		local metaData:TData = LoadV3AdContractBaseMetaDataFromNode(GUID, node, xml)

		'skip forbidden users (DEV)
		if not IsAllowedUser(metaData.GetString("createdBy"), "adcontract") then return Null

		'try to fetch an existing one
		local adContract:TAdContractBase = GetAdContractBaseCollection().GetByGUID(GUID)
		if not adContract
			adContract = new TAdContractBase
			adContract.title = new TLocalizedString
			adContract.description = new TLocalizedString
			adContract.GUID = GUID
		else
			doAdd = False
		endif
		
		'=== LOCALIZATION DATA ===
		adContract.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		adContract.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'=== DATA ===
		local nodeData:TxmlNode = xml.FindElementNode(node, "data")
		local data:TData = new TData
		xml.LoadValuesToData(nodeData, data, [..
			"infomercial", "quality", "repetitions", ..
			"fix_price", "duration", "profit", "penalty", ..
			"pro_pressure_groups", "contra_pressure_groups", ..
			"infomercial_profit", "fix_infomercial_profit", ..
			"year_range_from", "year_range_to" ..
		])

		adContract.infomercialAllowed = data.GetBool("infomercial", adContract.infomercialAllowed)
		adContract.quality = 0.01 * data.GetFloat("quality", adContract.quality * 100.0)

		'old -> now stored in "availability
		adContract.availableYearRangeFrom = data.GetInt("year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = data.GetInt("year_range_to", adContract.availableYearRangeTo)

		adContract.spotCount = data.GetInt("repetitions", adContract.spotcount)
		adContract.fixedPrice = data.GetInt("fix_price", adContract.fixedPrice)
		adContract.daysToFinish = data.GetInt("duration", adContract.daysToFinish)
		adContract.proPressureGroups = data.GetInt("pro_pressure_groups", adContract.proPressureGroups)
		adContract.contraPressureGroups = data.GetInt("contra_pressure_groups", adContract.contraPressureGroups)
		adContract.profitBase = data.GetFloat("profit", adContract.profitBase)
		adContract.penaltyBase = data.GetFloat("penalty", adContract.penaltyBase)
		adContract.infomercialProfitBase = data.GetFloat("infomercial_profit", adContract.infomercialProfitBase)
		adContract.fixedInfomercialProfit = data.GetFloat("fix_infomercial_profit", adContract.fixedInfomercialProfit)
		'without data, fall back to 10% of profitBase 
		if adContract.infomercialProfitBase = 0 then adContract.infomercialProfitBase = adContract.profitBase * 0.1


		'=== AVAILABILITY ===
		'do not reset "data" before - it contains the pressure groups
		xml.LoadValuesToData(xml.FindElementNode(node, "availability"), data, [..
			"script", "year_range_from", "year_range_to" ..
		])
		adContract.availableScript = data.GetString("script", adContract.availableScript)
		adContract.availableYearRangeFrom = data.GetInt("year_range_from", adContract.availableYearRangeFrom)
		adContract.availableYearRangeTo = data.GetInt("year_range_to", adContract.availableYearRangeTo)

		'=== CONDITIONS ===
		local nodeConditions:TxmlNode = xml.FindElementNode(node, "conditions")
		'do not reset "data" before - it contains the pressure groups
		xml.LoadValuesToData(nodeConditions, data, [..
			"min_audience", "min_image", "target_group", ..
			"allowed_programme_type", "allowed_genre", ..
			"prohibited_genre", "prohibited_programme_type" ..
		])
		'0-100% -> 0.0 - 1.0
		adContract.minAudienceBase = 0.01 * data.GetFloat("min_audience", adContract.minAudienceBase*100.0)
		adContract.minImage = 0.01 * data.GetFloat("min_image", adContract.minImage*100.0)
		adContract.limitedToTargetGroup = data.GetInt("target_group", adContract.limitedToTargetGroup)
		adContract.limitedToProgrammeGenre = data.GetInt("allowed_genre", adContract.limitedToProgrammeGenre)
		adContract.limitedToProgrammeType = data.GetInt("allowed_programme_type", adContract.limitedToProgrammeType)
		adContract.limitedToProgrammeFlag = data.GetInt("allowed_programme_flag", adContract.limitedToProgrammeFlag)
		adContract.forbiddenProgrammeGenre = data.GetInt("prohibited_genre", adContract.forbiddenProgrammeGenre)
		adContract.forbiddenProgrammeType = data.GetInt("prohibited_programme_type", adContract.forbiddenProgrammeType)
		adContract.forbiddenProgrammeFlag = data.GetInt("prohibited_programme_flag", adContract.forbiddenProgrammeFlag)
		'if only one group
		adContract.proPressureGroups = data.GetInt("pro_pressure_groups", adContract.proPressureGroups)
		adContract.contraPressureGroups = data.GetInt("contra_pressure_groups", adContract.contraPressureGroups)
		rem
		for multiple groups: 
		local proPressureGroups:String[] = data.GetString("pro_pressure_groups", "").Split(" ")
		For local group:string = EachIn proPressureGroups
			if not adContract.HasProPressureGroup(int(group))
				adContract.proPressureGroups :+ [int(group)]
			endif
		Next
		...
		endrem


		'=== ADD TO COLLECTION ===
		if doAdd
			GetAdContractBaseCollection().Add(adContract)
			contractsCount :+ 1
			totalContractsCount :+ 1
		endif

		return adContract
	End Method


	Method LoadV3ProgrammeLicenceFromNode:TProgrammeLicence(node:TxmlNode, xml:TXmlHelper, parentLicence:TProgrammeLicence = Null)
		local GUID:String = TXmlHelper.FindValue(node,"id", "")

		'fetch potential meta data
		local metaData:TData = LoadV3ProgrammeLicenceMetaDataFromNode(GUID, node, xml, parentLicence)
	
		local productType:int = TXmlHelper.FindValueInt(node,"product", TVTProgrammeProductType.MOVIE)
		'old type - stay compatible with old v3-db
		local oldType:int = TXmlHelper.FindValueInt(node,"type", TVTProgrammeLicenceType.SINGLE)
		local licenceType:int = TXmlHelper.FindValueInt(node,"licence_type", oldType)
		local programmeData:TProgrammeData
		local programmeLicence:TProgrammeLicence

		'skip if not "all" are allowed (no creator data available)
		if not IsAllowedUser(metaData.GetString("createdBy"), "programmelicence") then return Null


		'=== PROGRAMME DATA ===
		'try to fetch an existing licence with the entries GUID
		'TODO: SPLIT LICENCES FROM DATA
		programmeLicence = GetProgrammeLicenceCollection().GetByGUID(GUID)
		if not programmeLicence
			'try to clone the parent's data - if that fails, create
			'a new instance
			if parentLicence then programmeData = TProgrammeData(THelper.CloneObject(parentLicence.data, "id"))
			if not programmeData
				programmeData = new TProgrammeData
			else
				'reuse old one
				productType = programmeData.productType
			endif

			programmeData.GUID = "data-"+GUID
			programmeData.title = new TLocalizedString
			programmeData.originalTitle = new TLocalizedString
			programmeData.description = new TLocalizedString

			programmeLicence = new TProgrammeLicence
			programmeLicence.GUID = GUID
		else
			programmeData = programmeLicence.GetData()
			if not programmeData then Throw "Loading V3 Programme from XML: Existing programmeLicence without data found."
		endif


		'=== ADD PROGRAMME DATA TO LICENCE ===
		'this just overrides the existing data - even if identical
		programmeLicence.SetData(programmeData)

		
		'=== LOCALIZATION DATA ===
		programmeData.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		programmeData.originalTitle.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "originalTitle")) )
		programmeData.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'=== DATA ===
		local nodeData:TxmlNode = xml.FindElementNode(node, "data")
		local data:TData = new TData
		xml.LoadValuesToData(nodeData, data, [..
			"country", "year", "distribution", "blocks", ..
			"maingenre", "subgenre", "time", "price_mod", ..
			"flags" ..
		])
		programmeData.country = data.GetString("country", programmeData.country)
		programmeData.year = data.GetInt("year", programmeData.year)
		programmeData.distributionChannel = data.GetInt("distribution", programmeData.distributionChannel)
		programmeData.blocks = data.GetInt("blocks", programmeData.blocks)
		programmeData.liveHour = data.GetInt("time", programmeData.liveHour)
		'compatibility: load price mod from "price_mod" first... later
		'override with "modifiers"-data
		programmeData.SetModifier("price", data.GetFloat("price_mod", programmeData.GetModifier("price")))

		programmeData.flags = data.GetInt("flags", programmeData.flags)

		programmeData.genre = data.GetInt("maingenre", programmeData.genre)
		For local sg:string = EachIn data.GetString("subgenre", "").split(",")
			if sg = "" then continue
			if not THelper.IntArrayContainsNumber(programmeData.subGenres, int(sg))
				programmeData.subGenres :+ [int(sg)]
			endif
		Next

		'for movies/series set a releaseDay until we have that
		'in the db.
		if not parentLicence
			releaseDayCounter :+ 1
			programmeData.SetReleaseTime(releaseDayCounter mod GetWorldTime().GetDaysPerYear())
		endif


		'=== STAFF ===
		local nodeStaff:TxmlNode = xml.FindElementNode(node, "staff")
		For local nodeMember:TxmlNode = EachIn xml.GetNodeChildElements(nodeStaff)
			If nodeMember.getName() <> "member" then continue

			local memberIndex:int = xml.FindValueInt(nodeMember, "index", 0)
			local memberFunction:int = xml.FindValueInt(nodeMember, "function", 0)
			local memberGUID:string = nodeMember.GetContent()

			local member:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID(memberGUID)
			'if person was defined add the given job
			if member Then programmeData.AddCast(new TProgrammePersonJob.Init(memberGUID, memberFunction))
		Next


		'=== GROUPS ===
		local nodeGroups:TxmlNode = xml.FindElementNode(node, "groups")
		data = new TData
		xml.LoadValuesToData(nodeData, data, [..
			"target_groups", "pro_pressure_groups", "contra_pressure_groups" ..
		])
		programmeData.targetGroups = data.GetInt("target_groups", programmeData.targetGroups)
		programmeData.proPressureGroups = data.GetInt("pro_pressure_groups", programmeData.proPressureGroups)
		programmeData.contraPressureGroups = data.GetInt("contra_pressure_groups", programmeData.contraPressureGroups)



		'=== RATINGS ===
		local nodeRatings:TxmlNode = xml.FindElementNode(node, "ratings")
		data = new TData
		xml.LoadValuesToData(nodeRatings, data, [..
			"critics", "speed", "outcome" ..
		])
		programmeData.review = 0.01 * data.GetFloat("critics", programmeData.review*100)
		programmeData.speed = 0.01 * data.GetFloat("speed", programmeData.speed*100)
		programmeData.outcome = 0.01 * data.GetFloat("outcome", programmeData.outcome*100)


		'=== MODIFIERS ===
		'reuses existing (parent) modifiers and overrides it with custom
		'ones
		local nodeModifiers:TxmlNode = xml.FindElementNode(node, "modifiers")
		For local nodeModifier:TxmlNode = EachIn xml.GetNodeChildElements(nodeModifiers)
			If nodeModifier.getName() <> "modifier" then continue

			local modKey:string = xml.FindValue(nodeModifier, "name", "mod")
			local modValue:Float = xml.FindValueFloat(nodeModifier, "value", programmeData.GetModifier(modKey))

			programmeData.SetModifier(modKey, modValue)
		Next


		'=== PRODUCT TYPE ===
		programmeData.productType = productType

		'=== LICENCE TYPE ===
		'the licenceType is adjusted as soon as "AddData" was used
		'so correct it if needed
		if parentLicence and licenceType = TVTProgrammeLicenceType.UNKNOWN
			licenceType = TVTProgrammeLicenceType.EPISODE
		endif
		programmeLicence.licenceType = licenceType


		
		'=== EPISODES ===
		local nodeEpisodes:TxmlNode = xml.FindElementNode(node, "children")
		For local nodeEpisode:TxmlNode = EachIn xml.GetNodeChildElements(nodeEpisodes)
			'skip other elements than programme data
			If nodeEpisode.getName() <> "programme" then continue

			'recursively load the episode - parent is the new programmeLicence
			local episodeLicence:TProgrammeLicence = LoadV3ProgrammeLicenceFromNode(nodeEpisode, xml, programmeLicence)

			'the episodeNumber is currently not needed, as we
			'autocalculate it by the position in the xml-episodes-list
			'local episodeNumber:int = xml.FindValueInt(nodeEpisode, "index", 1)

			'add the episode
			programmeLicence.AddSubLicence(episodeLicence)

'			print programmeLicence.isSeries() +"  " +programmeLicence.GetSubLicenceCount()
		Next

		if programmeLicence.isSeries() and programmeLicence.GetSubLicenceCount() = 0
			programmeLicence.licenceType = TVTProgrammeLicenceType.SINGLE
			print "Series with 0 episodes found. Converted to single: "+programmeLicence.GetTitle()
		endif

		
		rem
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
		'also set the programme as "finished" and inform cast (for level ups)
		For local job:TProgrammePersonJob = eachIn programmeData.GetCast()
			local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetByGUID( job.personGUID )
			if person then person.FinishProduction(programmeData.GetGUID())
		Next


		programmeLicence.SetOwner(TOwnedGameObject.OWNER_NOBODY)

		return programmeLicence
	End Method


	Method LoadV3ScriptTemplateFromNode:TScriptTemplate(node:TxmlNode, xml:TXmlHelper, parentScriptTemplate:TScriptTemplate = Null)
		local GUID:String = TXmlHelper.FindValue(node,"guid", "")
		local scriptProductType:int = TXmlHelper.FindValueInt(node,"product", 1)
		local oldType:int = TXmlHelper.FindValueInt(node,"type", TVTProgrammeLicenceType.SINGLE)
		local scriptLicenceType:int = TXmlHelper.FindValueInt(node,"licence_type", oldType)
		local index:int = TXmlHelper.FindValueInt(node,"index", 0)
		local scriptTemplate:TScriptTemplate

		'fetch potential meta data
		LoadV3ScriptTemplateMetaDataFromNode(GUID, node, xml, parentScriptTemplate)

		'=== SCRIPTTEMPLATE DATA ===
		'try to fetch an existing template with the entries GUID
		scriptTemplate = GetScriptTemplateCollection().GetByGUID(GUID)
		if not scriptTemplate
			'try to clone the parent, if that fails, create a new instance
			if parentScriptTemplate then scriptTemplate = TScriptTemplate(THelper.CloneObject(parentScriptTemplate, "id"))
			if not scriptTemplate
				scriptTemplate = new TScriptTemplate
			endif

			scriptTemplate.GUID = GUID
			scriptTemplate.title = new TLocalizedString
			scriptTemplate.description = new TLocalizedString
			'DO NOT reuse certain parts of the parent (getters take
			'care of this already)
			scriptTemplate.variables = null
			scriptTemplate.placeHolderVariables = null
			scriptTemplate.subScripts = new TScriptTemplate[0]
			scriptTemplate.parentScriptGUID = ""
		endif


		'=== LOCALIZATION DATA ===
		scriptTemplate.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		scriptTemplate.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )



		'=== DATA ELEMENTS ===
		local nodeData:TxmlNode
		local data:TData


		'=== DATA: GENRES ===
		nodeData = xml.FindElementNode(node, "genres")
		data = new TData
		xml.LoadValuesToData(nodeData, data, ["mainGenre", "subGenres"])
		scriptTemplate.mainGenre = data.GetInt("mainGenre", 0)
		For local sg:string = EachIn data.GetString("subGenres", "").split(",")
			if sg = "" then continue
			if not THelper.IntArrayContainsNumber(scriptTemplate.subGenres, int(sg))
				scriptTemplate.subGenres :+ [int(sg)]
			endif
		Next



		'=== DATA: RATINGS - OUTCOME ===
		nodeData = xml.FindElementNode(node, "outcome")
		data = xml.LoadValuesToData(nodeData, new TData, ["min", "max", "slope", "value"])
		if data.GetInt("value", -1) >= 0
			local value:Float = 0.01 * data.GetInt("value", 100 * scriptTemplate.outcomeMin)
			scriptTemplate.SetOutcomeRange(value, value, 0.5)
		else
			scriptTemplate.SetOutcomeRange( ..
				0.01 * data.GetInt("min", 100 * scriptTemplate.outcomeMin), ..
				0.01 * data.GetInt("max", 100 * scriptTemplate.outcomeMax), ..
				0.01 * data.GetInt("slope", 100 * scriptTemplate.outcomeSlope) ..
			)
		endif

		'=== DATA: RATINGS - REVIEW ===
		nodeData = xml.FindElementNode(node, "review")
		data = xml.LoadValuesToData(nodeData, new TData, ["min", "max", "slope", "value"])
		if data.GetInt("value", -1) >= 0
			local value:Float = 0.01 * data.GetInt("value", 100 * scriptTemplate.reviewMin)
			scriptTemplate.SetReviewRange(value, value, 0.5)
		else
			scriptTemplate.SetReviewRange( ..
				0.01 * data.GetInt("min", 100 * scriptTemplate.reviewMin), ..
				0.01 * data.GetInt("max", 100 * scriptTemplate.reviewMax), ..
				0.01 * data.GetInt("slope", 100 * scriptTemplate.reviewSlope) ..
			)
		endif

		'=== DATA: RATINGS - SPEED ===
		nodeData = xml.FindElementNode(node, "speed")
		data = xml.LoadValuesToData(nodeData, new TData, ["min", "max", "slope", "value"])
		if data.GetInt("value", -1) >= 0
			local value:Float = 0.01 * data.GetInt("value", 100 * scriptTemplate.speedMin)
			scriptTemplate.SetSpeedRange(value, value, 0.5)
		else
			scriptTemplate.SetSpeedRange( ..
				0.01 * data.GetInt("min", 100 * scriptTemplate.speedMin), ..
				0.01 * data.GetInt("max", 100 * scriptTemplate.speedMax), ..
				0.01 * data.GetInt("slope", 100 * scriptTemplate.speedSlope) ..
			)
		endif

		'=== DATA: RATINGS - POTENTIAL ===
		nodeData = xml.FindElementNode(node, "potential")
		data = xml.LoadValuesToData(nodeData, new TData, ["min", "max", "slope", "value"])
		if data.GetInt("value", -1) >= 0
			local value:Float = 0.01 * data.GetInt("value", 100 * scriptTemplate.potentialMin)
			scriptTemplate.SetPotentialRange(value, value, 0.5)
		else
			scriptTemplate.SetPotentialRange( ..
				0.01 * data.GetInt("min", 100 * scriptTemplate.potentialMin), ..
				0.01 * data.GetInt("max", 100 * scriptTemplate.potentialMax), ..
				0.01 * data.GetInt("slope", 100 * scriptTemplate.potentialSlope) ..
			)
		endif


		'=== DATA: BLOCKS ===
		nodeData = xml.FindElementNode(node, "blocks")
		data = xml.LoadValuesToData(nodeData, new TData, ["min", "max", "slope", "value"])
		if data.GetInt("value", -1) >= 0
			local value:Int = data.GetInt("value", scriptTemplate.blocksMin)
			scriptTemplate.SetBlocksRange(value, value, 0.5)
		else
			scriptTemplate.SetBlocksRange( ..
				data.GetInt("min", scriptTemplate.blocksMin), ..
				data.GetInt("max", scriptTemplate.blocksMax), ..
				0.01 * data.GetInt("slope", 100 * scriptTemplate.blocksSlope) ..
			)
		endif

		'=== DATA: PRICE ===
		nodeData = xml.FindElementNode(node, "price")
		data = xml.LoadValuesToData(nodeData, new TData, ["min", "max", "slope", "value"])
		if data.GetInt("value", -1) >= 0
			local value:Int = data.GetInt("value", scriptTemplate.priceMin)
			scriptTemplate.SetPriceRange(value, value, 0.5)
		else
			scriptTemplate.SetPriceRange( ..
				data.GetInt("min", scriptTemplate.priceMin), ..
				data.GetInt("max", scriptTemplate.priceMax), ..
				0.01 * data.GetInt("slope", 100 * scriptTemplate.priceSlope) ..
			)
		endif


		'=== DATA: JOBS ===
		nodeData = xml.FindElementNode(node, "jobs")
		For local nodeJob:TxmlNode = EachIn xml.GetNodeChildElements(nodeData)
			If nodeJob.getName() <> "job" then continue

			'the job index is only relevant to children/episodes in the
			'case of a partially overridden cast

			local jobIndex:int = xml.FindValueInt(nodeJob, "index", -1)
			local jobFunction:int = xml.FindValueInt(nodeJob, "function", 0)
			local jobRequired:int = xml.FindValueInt(nodeJob, "required", 0)
			local jobGender:int = xml.FindValueInt(nodeJob, "gender", 0)
			local jobCountry:string = xml.FindValue(nodeJob, "country", "")
			'for actor jobs this defines if a specific role is defined
			local jobRoleGUID:string = xml.FindValue(nodeJob, "role_guid", "")

			'create a job without an assigned person
			local job:TProgrammePersonJob = new TProgrammePersonJob.Init("", jobFunction, jobGender, jobCountry, jobRoleGUID)
			if jobRequired = 0
				'check if the job has to override an existing one
				if jobIndex >= 0 and scriptTemplate.GetRandomJobAtIndex(jobIndex)
					scriptTemplate.SetRandomJobAtIndex(jobIndex, job)
				else
					scriptTemplate.AddRandomJob(job)
				endif
			else
				'check if the job has to override an existing one
				if jobIndex >= 0 and scriptTemplate.GetJobAtIndex(jobIndex)
					scriptTemplate.SetJobAtIndex(jobIndex, job)
				else
					scriptTemplate.AddJob(job)
				endif
			endif
		Next


		'=== VARIABLES ===
		local nodeVariables:TxmlNode = xml.FindElementNode(node, "variables")
		For local nodeVariable:TxmlNode = EachIn xml.GetNodeChildElements(nodeVariables)
			'each variable is stored as a localizedstring
			local varName:string = nodeVariable.getName()
			local varString:TLocalizedString = GetLocalizedStringFromNode(nodeVariable)

			'skip invalid
			if not varName or not varString then continue

			scriptTemplate.AddVariable("%"+varName+"%", varString)
		Next
		
		
		'=== EPISODES ===
		local nodeChildren:TxmlNode = xml.FindElementNode(node, "children")
		For local nodeChild:TxmlNode = EachIn xml.GetNodeChildElements(nodeChildren)
			'skip other elements than scripttemplate
			If nodeChild.getName() <> "scripttemplate" then continue

			'recursively load the child script - parent is the new scriptTemplate
			local childScriptTemplate:TScriptTemplate = LoadV3ScriptTemplateFromNode(nodeChild, xml, scriptTemplate)

			'the childIndex is currently not needed, as we autocalculate
			'it by the position in the xml-episodes-list
			'local childIndex:int = xml.FindValueInt(nodechild, "index", 1)

			'add the child
			scriptTemplate.AddSubScript(childScriptTemplate)
		Next



		'=== SCRIPT - PRODUCT TYPE ===
		scriptTemplate.scriptProductType = scriptProductType

		'=== SCRIPT - LICENCE TYPE ===
		if parentScriptTemplate and scriptLicenceType = TVTProgrammeLicenceType.UNKNOWN
			scriptLicenceType = TVTProgrammeLicenceType.EPISODE
		endif
		scriptTemplate.scriptLicenceType = scriptLicenceType

		rem
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

		'=== ADD TO COLLECTION ===
		GetScriptTemplateCollection().Add(scriptTemplate)

		scriptTemplatesCount :+ 1
		totalScriptTemplatesCount :+ 1

		return scriptTemplate
	End Method



	Method LoadV3ProgrammeRoleFromNode:TProgrammeRole(node:TxmlNode, xml:TXmlHelper)
		local GUID:String = TXmlHelper.FindValue(node,"guid", "")
		local role:TProgrammeRole

		'fetch potential meta data
		LoadV3ProgrammeRoleMetaDataFromNode(GUID, node, xml)

		'try to fetch an existing template with the entries GUID
		role = GetProgrammeRoleCollection().GetByGUID(GUID)
		if not role
			role = new TProgrammeRole
			role.SetGUID(GUID)
		endif

		role.Init(..
			TXmlHelper.FindValue(node, "first_name", role.firstname), ..
			TXmlHelper.FindValue(node, "last_name", role.lastname), ..
			TXmlHelper.FindValue(node, "title", role.title), ..
			TXmlHelper.FindValue(node, "country", role.country), ..
			TXmlHelper.FindValueInt(node, "gender", role.gender), ..
			TXmlHelper.FindValueInt(node, "fictional", role.fictional) ..
		)

		'=== ADD TO COLLECTION ===
		GetProgrammeRoleCollection().Add(role)

		programmeRolesCount :+ 1
		totalProgrammeRolesCount :+ 1

		return role
	End Method



	'=== META DATA FUNCTIONS ===
	Method LoadV3CreatorMetaDataFromNode:TData(GUID:string, data:TData, node:TxmlNode, xml:TXmlHelper)
		data.AddNumber("creator", TXmlHelper.FindValueInt(node,"creator", 0))
		data.AddString("createdBy", TXmlHelper.FindValue(node,"created_by", ""))
		return data
	End Method
	
	
	Method LoadV3ProgrammeRoleMetaDataFromNode:TData(GUID:string, node:TxmlNode, xml:TXmlHelper)
		local data:TData = new TData
		'only set creator if it is the "non overridden" one
		if not GetProgrammeRoleCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		endif
		return data
	End Method


	Method LoadV3ScriptTemplateMetaDataFromNode:TData(GUID:string, node:TxmlNode, xml:TXmlHelper, parentScriptTemplate:TScriptTemplate = Null)
		local data:TData = new TData
		'only set creator if it is the "non overridden" one
		if not GetScriptTemplateCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		endif
		return data
	End Method


	Method LoadV3ProgrammeLicenceMetaDataFromNode:TData(GUID:string, node:TxmlNode, xml:TXmlHelper, parentLicence:TProgrammeLicence = Null)
		local data:TData = new TData
		'only set creator if it is the "non overridden" one
		if not GetProgrammeLicenceCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		endif
		return data
	End Method


	Method LoadV3ProgrammePersonBaseMetaDataFromNode:TData(GUID:string, node:TxmlNode, xml:TXmlHelper, isCelebrity:int=True)
		local data:TData = new TData
		'only set creator if it is the "non overridden" one
		if not GetProgrammePersonBaseCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		endif
		return data
	End Method


	Method LoadV3NewsEventMetaDataFromNode:TData(GUID:string, node:TxmlNode, xml:TXmlHelper)
		local data:TData = new TData
		'only set creator if it is the "non overridden" one
		if not GetNewsEventCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		endif
		return data
	End Method


	Method LoadV3AdContractBaseMetaDataFromNode:TData(GUID:string, node:TxmlNode, xml:TXmlHelper)
		local data:TData = new TData
		'only set creator if it is the "non overridden" one
		if not GetAdContractBaseCollection().GetByGUID(GUID)
			data = LoadV3CreatorMetaDataFromNode(GUID, data, node, xml)
		endif
		return data
	End Method
	

	Function convertV2genreToV3:int(data:TProgrammeData)
		Select data.genre
			case 0 'old ACTION
				data.genre = TVTProgrammeGenre.Action
			case 1 'old THRILLER
				data.genre = TVTProgrammeGenre.Thriller
			case 2 'old SCIFI
				data.genre = TVTProgrammeGenre.SciFi
			case 3 'old COMEDY
				data.genre = TVTProgrammeGenre.Comedy
			case 4 'old HORROR
				data.genre = TVTProgrammeGenre.Horror
			case 5 'old LOVE
				data.genre = TVTProgrammeGenre.Romance
			case 6 'old EROTIC
				data.genre = TVTProgrammeGenre.Erotic
			case 7 'old WESTERN
				data.genre = TVTProgrammeGenre.Western
			case 8 'old LIVE
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TVTProgrammeFlag.LIVE)
			case 9 'old KIDS
				data.genre = TVTProgrammeGenre.Family
			case 10 'old CARTOON
				data.genre = TVTProgrammeGenre.Animation
			case 11 'old MUSIC
				data.genre = TVTProgrammeGenre.Undefined
			case 12 'old SPORT
				data.genre = TVTProgrammeGenre.Undefined
			case 13 'old CULTURE
				data.genre = TVTProgrammeGenre.Undefined
			case 14 'old FANTASY
				data.genre = TVTProgrammeGenre.Fantasy
			case 15 'old YELLOWPRESS
				'hier sind nur "Trash"-Programme drin
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TVTProgrammeFlag.TRASH)
			case 17 'old SHOW
				data.genre = TVTProgrammeGenre.Show
			case 18 'old MONUMENTAL
				data.genre = TVTProgrammeGenre.Monumental
			case 19 'TProgrammeData.GENRE_FILLER 'TV films etc.
				data.genre = TVTProgrammeGenre.Undefined
			case 20 'old CALLINSHOW
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TVTProgrammeFlag.PAID)
			default
				data.genre = TVTProgrammeGenre.Undefined
		End Select
	End Function


	Function GetPersonsFromString:TProgrammePersonBase[](personsString:string="", job:int=0)
		local personsStringArray:string[] = personsString.split(",")
		local personArray:TProgrammePersonBase[]

		For local personString:string = eachin personsStringArray
			'split first and lastName
			local _name:string[] = personString.split(" ")
			local name:string[]
			'remove " "-strings
			for local i:int = 0 to _name.length-1
				if _name[i].trim() = "" then continue
				name = name[..name.length+1]
				name[name.length-1] = _name[i]
			Next

			'ignore "unknown" actors
			if name.length <= 0 or name[0] = "XXX" then continue

			local firstName:string = name[0]
			local lastName:string = ""
			'add rest to lastname
			For local i:int = 1 to name.length - 1
				lastName:+ name[i]+" "
			Next
			'trim last space
			lastName = lastName[..lastName.length-1]

			'check if the person already exists
			local person:TProgrammePersonBase = GetProgrammePersonBaseCollection().GetCelebrityByName(firstName, lastName)
			if not person
				'create as celebrity
				person = new TProgrammePerson
				person.SetFirstName(firstName)
				person.SetLastName(lastName)
			endif
			person.AddJob(job)

			'add person
			personArray :+ [person]
		Next
		return personArray
	End Function


	'load a localized string from the given node
	'only adds "non empty" strings
	'ex.:
	'<title>
	' <de>bla</de>
	'<title>
	Function GetLocalizedStringFromNode:TLocalizedString(node:TxmlNode)
		if not node then return Null

		local foundEntry:int = True
		local localized:TLocalizedString = new TLocalizedString
		For local nodeLangEntry:TxmlNode = EachIn TxmlHelper.GetNodeChildElements(node)
			local language:String = nodeLangEntry.GetName().ToLower()
			local value:String = nodeLangEntry.getContent().Trim()

			if value <> ""
				localized.Set(value, language)
				foundEntry = True
			endif
		Next

		if not foundEntry then return Null 
		return localized
	End Function
End Type




Function LoadDatabase(dbDirectory:String)
	local loader:TDatabaseLoader = new TDatabaseLoader
	loader.LoadDir(dbDirectory)
End Function