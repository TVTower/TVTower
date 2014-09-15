SuperStrict
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.directorytree.bmx"
Import "Dig/base.util.xmlhelper.bmx"

Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"
Import "game.gameconstants.bmx"


Type TDatabaseLoader
	Field moviesCount:Int, totalMoviesCount:Int
	Field seriesCount:Int, totalSeriesCount:Int
	Field newsCount:Int, totalNewsCount:Int
	Field contractsCount:Int, totalContractsCount:Int

	Field loadError:String = ""

	Field releaseDayCounter:int = 0
	Field stopWatchAll:TStopWatch = new TStopWatch.Init()
	Field stopWatch:TStopWatch = new TStopWatch.Init()


	Method LoadDir(dbDirectory:string)
		'build file list of xml files in the given directory
		local dirTree:TDirectoryTree = new TDirectoryTree.Init(dbDirectory, ["xml"], null, ["*"])
		'exclude "database.xml" as we add it by default to load it
		'as the first file
		dirTree.AddIncludeFileNames(["*"])
		dirTree.AddExcludeFileNames(["database"])
		'add that database.xml
		dirTree.AddFile(dbDirectory+"/database.xml")
		'add the rest of available files in the given dir
		dirTree.ScanDir()

		local fileURIs:String[] = dirTree.GetFiles()
		'loop over all filenames
		for local fileURI:String = EachIn fileURIs
			'skip non-existent files
			if filesize(fileURI) = 0 then continue
			
			Load(fileURI)
		Next

		TLogger.log("TDatabase.Load()", "Loaded from "+fileURIs.length + " DBs. Found " + totalSeriesCount + " series, " + totalMoviesCount + " movies, " + totalContractsCount + " advertisements, " + totalNewsCount + " news. loading time: " + stopWatchAll.GetTime() + "ms", LOG_LOADING)

		if totalSeriesCount = 0 or totalMoviesCount = 0 or totalNewsCount = 0 or totalContractsCount = 0
			Notify "Important data is missing:  series:"+totalSeriesCount+"  movies:"+totalMoviesCount+"  news:"+totalNewsCount+"  adcontracts:"+totalContractsCount
		endif
	End Method


	Method Load(fileURI:string)
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
			case 2	LoadV2(xml)
			case 3	LoadV3(xml)
			Default	TLogger.log("TDatabase.Load()", "CANNOT LOAD DB ~q" + fileURI + "~q (version "+version+") - UNKNOWN VERSION." , LOG_LOADING)
		End Select
	End Method



	Method LoadV2:Int(xml:TXmlHelper)
		stopWatch.Init()

		Local title:String
		Local description:String
		Local directors:TProgrammePerson[], directorsRaw:String
		Local actors:TProgrammePerson[], actorsRaw:String
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

		Local quality:Float

		local nodeParent:TxmlNode
		local nodeChild:TxmlNode
		local nodeEpisode:TxmlNode


		'===== IMPORT ALL MOVIES =====

		'Print "reading movies from database"
		nodeParent = xml.FindRootChild("allmovies")
		for nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "movie" then continue

			title       = xml.FindValue(nodeChild,"title", "unknown title")
			description = xml.FindValue(nodeChild,"description", "23")
			actorsRaw   = xml.FindValue(nodeChild,"actors", "")
			directorsRaw= xml.FindValue(nodeChild,"director", "")
			land        = xml.FindValue(nodeChild,"country", "UNK")
			year 		= xml.FindValueInt(nodeChild,"year", 1900)
			Genre 		= xml.FindValueInt(nodeChild,"genre", 0 )
			duration    = xml.FindValueInt(nodeChild,"blocks", 2)
			xrated 		= xml.FindValueInt(nodeChild,"xrated", 0)
			priceModifier = xml.FindValueInt(nodeChild,"price", 255) / 255.0 /1.5 'normalize to "normal = 1.0", original values are bit higher
			review 		= xml.FindValueInt(nodeChild,"critics", 0) / 255.0
			speed 		= xml.FindValueInt(nodeChild,"speed", 0) / 255.0
			Outcome 	= xml.FindValueInt(nodeChild,"outcome", 0) / 255.0
			livehour 	= xml.FindValueInt(nodeChild,"time", 0)
			refreshModifier	= xml.FindValueFloat(nodeChild,"refreshModifier", 1.0)
			wearoffModifier	= xml.FindValueFloat(nodeChild,"wearoffModifier", 1.0)
			If duration < 0 Or duration > 12 Then duration =1

			'print title+": priceModifier="+priceModifier+"  review="+review+"  speed="+speed+"  Outcome="+outcome

			local actors:TProgrammePerson[] = GetPersonsFromString(actorsRaw, TProgrammePersonBase.JOB_ACTOR)
			local directors:TProgrammePerson[] = GetPersonsFromString(directorsRaw, TProgrammePersonBase.JOB_DIRECTOR)

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			local movieLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
			movieLicence.AddData(TProgrammeData.Create("", localizeTitle, localizeDescription, actors, directors, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_MOVIE))

			releaseDaycounter:+1
			moviesCount :+1
			totalMoviesCount :+ 1
		Next


		'===== IMPORT ALL SERIES INCLUDING EPISODES =====

		nodeParent = xml.FindRootChild("allseries")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "serie" then continue

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

			local actors:TProgrammePerson[] = GetPersonsFromString(actorsRaw, TProgrammePersonBase.JOB_ACTOR)
			local directors:TProgrammePerson[] = GetPersonsFromString(directorsRaw, TProgrammePersonBase.JOB_DIRECTOR)

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			'create a licence for that series - with title and series description
			local seriesLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
			'add the "overview"-data of the series
			seriesLicence.AddData(TProgrammeData.Create("", localizeTitle, localizeDescription, actors, directors, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_SERIES))

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

					local actors:TProgrammePerson[] = GetPersonsFromString(actorsRaw, TProgrammePersonBase.JOB_ACTOR)
					local directors:TProgrammePerson[] = GetPersonsFromString(directorsRaw, TProgrammePersonBase.JOB_DIRECTOR)

					local localizeTitle:TLocalizedString = new TLocalizedString
					localizeTitle.Set(title, "de")
					local localizeDescription:TLocalizedString = new TLocalizedString
					localizeDescription.Set(description, "de")

					local episodeLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
					episodeLicence.AddData(TProgrammeData.Create("", localizeTitle, localizeDescription, actors, directors, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_EPISODE))
					'add that episode to the series licence
					seriesLicence.AddSubLicence(episodeLicence)
				EndIf
			Next

			seriesCount :+ 1
			totalSeriesCount :+ 1
		Next


		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====

		nodeParent = xml.FindRootChild("allads")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "ad" then continue

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
				profit	= 30 * xml.FindValueInt(nodeChild,"profit", 0)
				penalty	= 30 * xml.FindValueInt(nodeChild,"penalty", 0)
			endif
			daystofinish= xml.FindValueInt(nodeChild,"duration", 1)

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")
			
			local ad:TAdContractBase = new TAdContractBase.Create("", localizeTitle, localizeDescription, daystofinish, spotcount, targetgroup, minaudience, minimage, fixedPrice, profit, penalty)

			contractsCount :+ 1
			totalContractsCount :+ 1
		Next


		'===== IMPORT ALL NEWS INCLUDING EPISODES =====

		nodeParent		= xml.FindRootChild("allnews")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "news" then continue
			'load series main data
			title       = xml.FindValue(nodeChild,"title", "unknown newstitle")
			description	= xml.FindValue(nodeChild,"description", "")
			genre		= xml.FindValueInt(nodeChild,"genre", 0)
			quality		= xml.FindValueInt(nodeChild,"topicality", 0)
			local price:int		= xml.FindValueInt(nodeChild,"price", 0)
			Local parentNewsEvent:TNewsEvent = TNewsEvent.Create(title, description, Genre, quality, price)

			'load episodes
			Local EpisodeNum:Int = 0
			For nodeEpisode = EachIn TXmlHelper.GetNodeChildElements(nodeChild)
				If nodeEpisode.getName() = "episode"
					EpisodeNum		= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
					title			= xml.FindValue(nodeEpisode,"title", "unknown Newstitle")
					description		= xml.FindValue(nodeEpisode,"description", "")
					genre			= xml.FindValueInt(nodeEpisode,"genre", genre)
					quality			= xml.FindValueInt(nodeEpisode,"topicality", quality)
					price			= xml.FindValueInt(nodeEpisode,"price", price)
					parentNewsEvent.AddEpisode(title,description, Genre, EpisodeNum,quality, price)
					totalnewscount :+1
				EndIf
			Next

			newsCount :+ 1
			totalNewsCount :+ 1
		Next
		TLogger.log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 2). Found " + seriesCount + " series, " + moviesCount + " movies, " + contractsCount + " advertisements, " + newsCount + " news. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method


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


		'===== IMPORT ALL PROGRAMMES (MOVIES/SERIES) =====
		'!!!!
		'attention: LOAD PERSONS FIRST !!
		'!!!!
		local nodeAllProgrammes:TxmlNode = xml.FindRootChild("allprogrammes")
		if nodeAllProgrammes
			local programmeData:TProgrammeData
			For local nodeProgramme:TxmlNode = EachIn xml.GetNodeChildElements(nodeAllProgrammes)
				If nodeProgramme.getName() <> "programme" then continue

				'creates a TProgrammeData and a TProgrammeLicence
				'of the found entry. If the entry contains "episodes"
				'they get loaded too
				LoadV3ProgrammeDataFromNode(nodeProgramme, xml)
			Next
		endif

		TLogger.log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 3). Found " + seriesCount + " series, " + moviesCount + " movies, " + contractsCount + " advertisements, " + newsCount + " news. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method



	'=== HELPER ===

	Method LoadV3ProgrammePersonBaseFromNode:TProgrammePersonBase(node:TxmlNode, xml:TXmlHelper, isCelebrity:int=True)
		local GUID:String = xml.FindValue(node,"id", "")
		'try to fetch an existing one
		local person:TProgrammePersonBase = GetProgrammePersonCollection().GetByGUID(GUID)
		'if the person existed, remove it from all lists and later add
		'it back to the one defined by "isCelebrity"
		'this allows other database.xml's to morph a insignificant
		'person into a celebrity
		if person
			GetProgrammePersonCollection().RemoveInsignificant(person)
			GetProgrammePersonCollection().RemoveCelebrity(person)
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
			"first_name", "last_name", "nick_name" ..
		])

		person.firstName = data.GetString("first_name", person.firstName)
		person.lastName = data.GetString("last_name", person.lastName)
		person.nickName = data.GetString("nick_name", person.nickName)


		'=== CELEBRITY SPECIFIC DATA ===
		'only for celebrities
		if TProgrammePerson(person)
			'create a celebrity to avoid casting each time
			local celebrity:TProgrammePerson = TProgrammePerson(person)


			'=== DETAILS ===
			local nodeDetails:TxmlNode = xml.FindElementNode(node, "details")
			data = new TData
			xml.LoadValuesToData(nodeDetails, data, [..
				"gender", "birthday", "deathday", "country" ..
			])
			celebrity.gender = data.GetInt("gender", celebrity.gender)
			celebrity.SetDayOfBirth( data.GetString("birthday", celebrity.dayOfBirth) )
			celebrity.SetDayOfDeath( data.GetString("deathday", celebrity.dayOfDeath) )
			celebrity.country = data.GetString("country", celebrity.country)
			

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
			celebrity.prominence = 0.01 * data.GetFloat("prominence", 100*celebrity.prominence)
		endif


		'=== ADD TO COLLECTION ===
		'we removed the person from all lists already, now add it back
		'to the one we wanted 
		if isCelebrity
			GetProgrammePersonCollection().AddCelebrity(person)
		else
			GetProgrammePersonCollection().AddInsignificant(person)
		endif

		return person
	End Method
	

	Method LoadV3AdContractBaseFromNode:TAdContractBase(node:TxmlNode, xml:TXmlHelper)
		local GUID:String = xml.FindValue(node,"id", "")
		local doAdd:int = True
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
			"fixed_price", "duration", "profit", "penalty", ..
			"pro_pressure_group", "contra_pressure_group" ..
		])
			

'aktivieren, wenn Datenbank Eintraege enthaelt, die infomercials erlauben
'				adContract.infomercialAllowed = data.GetBool("infomercial", adContract.infomercialAllowed)
'				adContract.quality = data.GetBool("quality", adContract.quality)
		adContract.quality = 0.5

		adContract.spotCount = data.GetInt("repetitions", adContract.spotcount)
		adContract.fixedPrice = data.GetInt("fixed_price", adContract.fixedPrice)
		adContract.daysToFinish = data.GetInt("duration", adContract.daysToFinish)
		adContract.proPressureGroup = data.GetInt("pro_pressure_group", adContract.proPressureGroup)
		adContract.contraPressureGroup = data.GetInt("contra_pressure_group", adContract.contraPressureGroup)
		adContract.profitBase = data.GetInt("profit", adContract.profitBase)
		adContract.penaltyBase = data.GetInt("penalty", adContract.penaltyBase)
	

		'=== CONDITIONS ===
		local nodeConditions:TxmlNode = xml.FindElementNode(node, "conditions")
		xml.LoadValuesToData(nodeConditions, data, [..
			"min_audience", "min_image", "target_group", ..
			"allowed_programme_type", "allowed_genre", ..
			"prohibited_genre", "prohibited_programme_type" ..
		])
		'0-100% -> 0.0 - 1.0
		adContract.minAudienceBase = 0.01 * data.GetFloat("min_audience", adContract.minAudienceBase*100.0)
		adContract.minImageBase = 0.01 * data.GetFloat("min_image", adContract.minImageBase*100.0)
		adContract.limitedToTargetGroup = data.GetInt("target_group", adContract.limitedToTargetGroup)
		adContract.limitedToProgrammeGenre = data.GetInt("allowed_genre", adContract.limitedToProgrammeGenre)
		adContract.limitedToProgrammeType = data.GetInt("allowed_programme_type", adContract.limitedToProgrammeType)
		adContract.forbiddenProgrammeGenre = data.GetInt("prohibited_genre", adContract.forbiddenProgrammeGenre)
		adContract.forbiddenProgrammeType = data.GetInt("prohibited_programme_type", adContract.forbiddenProgrammeType)
		'if only one group
		adContract.proPressureGroup = data.GetInt("pro_pressure_group", adContract.proPressureGroup)
		adContract.contraPressureGroup = data.GetInt("contra_pressure_group", adContract.contraPressureGroup)
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
	

	Method LoadV3ProgrammeDataFromNode:TProgrammeData(node:TxmlNode, xml:TXmlHelper, parentLicence:TProgrammeLicence = Null)
		local GUID:String = TXmlHelper.FindValue(node,"id", "")
		local doAdd:int = True
		local programmeData:TProgrammeData
		local programmeLicence:TProgrammeLicence = new TProgrammeLicence

		'try to fetch an existing one
		programmeData = GetProgrammeDataCollection().GetByGUID(GUID)
		if programmeData
			doAdd = False
		else
			'try to clone the parent's data - if that fails, create
			'a new instance
			if parentLicence then programmeData = TProgrammeData(THelper.CloneObject(parentLicence.data))
			if not programmeData then programmeData = new TProgrammeData

			programmeData.GUID = GUID
			programmeData.title = new TLocalizedString
			programmeData.description = new TLocalizedString
		endif

		
		'=== LOCALIZATION DATA ===
		programmeData.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
		programmeData.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "description")) )


		'=== DATA ===
		local nodeData:TxmlNode = xml.FindElementNode(node, "data")
		local data:TData = new TData
		xml.LoadValuesToData(nodeData, data, [..
			"country", "year", "distribution", "blocks", ..
			"maingenre", "subgenre", "time", "price_mod" ..
		])
		programmeData.country = data.GetString("country", programmeData.country)
		programmeData.year = data.GetInt("year", programmeData.year)
		'programmeData.distribution = data.GetInt("distribution", programmeData.distribution)
		programmeData.blocks = data.GetInt("blocks", programmeData.blocks)
		programmeData.liveHour = data.GetInt("time", programmeData.liveHour)
		programmeData.priceModifier = data.GetFloat("price_mod", programmeData.priceModifier)

'GENRES BRAUCHEN UEBERARBEITUNG - die sind NICHT MEHR DIE GLEICHEN
'wie bei der alten Datenbank. Bspweise ist Klasterisk von "genre=10"
'zu "genre=3 flag-animation" geworden
		'programmeData.genre = data.GetInt("maingenre", programmeData.genre)
		'multiple subgenres?
		'programmeData.subGenre = data.GetInt("subgenre", programmeData.subgenre)

		'for movies/series set a releaseDay until we have that
		'in the db.
		if not parentLicence or node.GetName().ToLower() <> "episode"
			releaseDayCounter :+ 1
			programmeData.releaseDay = releaseDayCounter mod GetWorldTime().GetDaysPerYear()
		endif


		'=== STAFF ===
		local nodeStaff:TxmlNode = xml.FindElementNode(node, "staff")
		For local nodeMember:TxmlNode = EachIn xml.GetNodeChildElements(nodeStaff)
			If nodeMember.getName() <> "member" then continue

			local memberIndex:int = xml.FindValueInt(nodeMember, "index", 0)
			local memberFunction:int = xml.FindValueInt(nodeMember, "function", 0)
			local memberGUID:string = nodeMember.GetContent()

			local member:TProgrammePersonBase = GetProgrammePersonCollection().GetByGUID(memberGUID)
			if member
				Select memberFunction
					case TProgrammePersonBase.JOB_ACTOR
						programmeData.actors :+ [member]
					case TProgrammePersonBase.JOB_DIRECTOR
						programmeData.directors :+ [member]
				End Select
			endif
		Next


		'=== FLAGS ===
		local nodeFlags:TxmlNode = xml.FindElementNode(node, "flags")
		For local nodeFlag:TxmlNode = EachIn xml.GetNodeChildElements(nodeFlags)
			If nodeFlag.getName() <> "member" then continue

			Select nodeFlag.GetContent().ToLower()
				case "fsk18"
					programmeData.SetFlag(TProgrammeData.FLAG_XRATED, True)
				case "animation"
					programmeData.SetFlag(TProgrammeData.FLAG_ANIMATION, True)
			End Select
		Next

		'=== GROUPS ===


		'=== RATINGS ===
		local nodeRatings:TxmlNode = xml.FindElementNode(node, "ratings")
		data = new TData
		xml.LoadValuesToData(nodeRatings, data, [..
			"critics", "speed", "outcome" ..
		])

'solange DB "buggy" Daten bei den Episoden enthaelt (critics und speed
'sind "0", wenn keine Angaben in der DB getroffen worden - also die Serien-
'information uebernommen werden sollten
if parentLicence
		local review:Float = 0.01 * data.GetFloat("critics", 0)
		if review > 0 then programmeData.review = review
		local speed:Float = 0.01 * data.GetFloat("speed", 0)
		if speed > 0 then programmeData.speed = speed
else
		programmeData.review = 0.01 * data.GetFloat("critics", programmeData.review*100)
		programmeData.speed = 0.01 * data.GetFloat("speed", programmeData.review*100)
endif
		programmeData.outcome = 0.01 * data.GetFloat("outcome", programmeData.outcome*100)



		'=== EPISODES ===
		local nodeEpisodes:TxmlNode = xml.FindElementNode(node, "episodes")
		local episodesFound:int = False
		For local nodeEpisode:TxmlNode = EachIn xml.GetNodeChildElements(nodeEpisodes)
			'skip other elements than episode
			If nodeEpisode.getName() <> "episode" then continue

			'recursively load the episode - parent is the new programmeLicence
			local episodeData:TProgrammeData = LoadV3ProgrammeDataFromNode(nodeEpisode, xml, programmeLicence)
			if episodeData then episodesFound = True

			'the episodeNumber is currently not needed, as we
			'autocalculate it by the position in the xml-episodes-list
			'local episodeNumber:int = xml.FindValueInt(nodeEpisode, "index", 1)

			'1) create a licence for this episode
			'2) add the found data (also adds TProgrammeData to collection)
			'3) add the episode to the programmeLicence
			local episodeLicence:TProgrammeLicence = new TProgrammeLicence
			episodeLicence.AddData(episodeData)

'TODO: FUEHRT Noch zu absturz, da die Serienlizenz noch nicht hinterlegt
'wird - und die wuerde hinzugefuegt werden, obwohl sie keine "data" hat
'-> deswegen loeschen wir alle serien am ende dieser funktion bis
'endgueltig umgestellt wird
			'this also adds the episode to the "global licence list" 
			programmeLicence.AddSubLicence(episodeLicence)
		Next


		'=== PROGRAMME TYPE ===
		'set type of the programmeData
		if programmeLicence.GetSubLicenceCount() > 0
			programmeData.programmeType = TProgrammeData.TYPE_SERIES
		elseif parentLicence and node.GetName().ToLower() = "episode"
			programmeData.programmeType = TProgrammeData.TYPE_EPISODE
		else
			programmeData.programmeType = TProgrammeData.TYPE_MOVIE
		endif


rem
'Ansatz fuer GenreV2-zu.GenreV3
		newGenre:int = -1
		Select programmeData.maingenre
			case 0 'TProgrammeData.GENRE_ACTION
				newGenre = TVTProgrammeGenre.Action
			case 1 'TProgrammeData.GENRE_THRILLER
				newGenre = TVTProgrammeGenre.Thriller
			case 2 'TProgrammeData.GENRE_SCIFI
				newGenre = TVTProgrammeGenre.SciFi
			case 3 'TProgrammeData.GENRE_COMEDY
				newGenre = TVTProgrammeGenre.Comedy
			case 4 'TProgrammeData.GENRE_HORROR
				newGenre = TVTProgrammeGenre.Horror
			case 5 'TProgrammeData.GENRE_LOVE
				newGenre = TVTProgrammeGenre.Romance
			case 6 'TProgrammeData.GENRE_EROTIC
				newGenre = TVTProgrammeGenre.Erotic
			case 7 'TProgrammeData.GENRE_WESTERN
				newGenre = TVTProgrammeGenre.Western
			case 8 'TProgrammeData.GENRE_LIVE
				'waere nun ein "Flag"
			case 9 'TProgrammeData.GENRE_KIDS
				newGenre = TVTProgrammeGenre.Family
			case 10 'TProgrammeData.GENRE_CARTOON
			'only 2 entries were "MUSIC"
			case 11 'TProgrammeData.GENRE_MUSIC
				newGenre = TVTProgrammeGenre.Undefined
			case 12 'TProgrammeData.GENRE_SPORT
			case 13 'TProgrammeData.GENRE_CULTURE
			case 14 'TProgrammeData.GENRE_FANTASY
				newGenre = TVTProgrammeGenre.Fantasy
			case 15 'TProgrammeData.GENRE_YELLOWPRESS
				'hier sind nur "Trash"-Programme drin
				newGenre = TVTProgrammeGenre.Undefined
			case 16 'TProgrammeData.GENRE_NEWS
				'unused
			case 17 'TProgrammeData.GENRE_SHOW
			case 18 'TProgrammeData.GENRE_MONUMENTAL
				newGenre = TVTProgrammeGenre.Monumental
			case 19 'TProgrammeData.GENRE_FILLER 'TV films etc.
				newGenre = TVTProgrammeGenre.Undefined
			case 20 'TProgrammeData.GENRE_CALLINSHOW
		End Select
		if newGenre >= 0 then programmeData.mainGenre = newGenre

		
			case TVTProgrammeGenre.Undefined:int = 0


 			case TVTProgrammeGenre.Adventure:int = 1
			case TVTProgrammeGenre.Animation:int = 3
			case TVTProgrammeGenre.Biography:int = 4
			case TVTProgrammeGenre.Crime:int = 5
			case TVTProgrammeGenre.Documentary:int = 7
			case TVTProgrammeGenre.Drama:int = 8
			case TVTProgrammeGenre.History:int = 12
			case TVTProgrammeGenre.Mystery:int = 15
			case TVTProgrammeGenre.War:int = 19
		End Select
endrem

		
		rem
		for multiple groups: 
		local proPressureGroups:String[] = data.GetString("pro_pressure_groups", "").Split(" ")
		For local group:string = EachIn proPressureGroups
			if not adContract.HasProPressureGroup(int(group))
				adContract.proPressureGroups :+ [int(group)]
			endif
		Next
		endrem

		'add to collection
		if doAdd
			'falls es eine serie war, entferne den automatisch erzeugten
			'eintrag - bis wir final auf v3 umstellen
			GetProgrammeLicenceCollection().RemoveSeries(programmeLicence)

			'add the data to the datacollection
			'GetProgrammeDataCollection().Add(programmeData)

			'add the data to the licence
			'this also adds the licence to the licenceCollection
			'programmeLicence.AddData(programmeData)
			
			if programmeData.programmeType = TProgrammeData.TYPE_MOVIE
				moviesCount :+ 1
				totalMoviesCount :+ 1
			elseif programmeData.programmeType = TProgrammeData.TYPE_SERIES
				seriesCount :+ 1
				totalSeriesCount :+ 1
			endif
		endif

		return programmeData
	End Method


	Function GetPersonsFromString:TProgrammePerson[](personsString:string="", job:int=0)
		local personsStringArray:string[] = personsString.split(",")
		local personArray:TProgrammePerson[]

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
			local person:TProgrammePerson = GetProgrammePersonCollection().GetCelebrityByName(firstName, lastName)
			if not person
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