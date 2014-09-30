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
		dirTree.AddExcludeFileNames(["database", "database_v2"])
		'add that database.xml - old v2 first
		dirTree.AddFile(dbDirectory+"/database_v2.xml")
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


			local cast:TProgrammePersonJob[]
			For local p:TProgrammePerson = EachIn GetPersonsFromString(directorsRaw, TProgrammePersonJob.JOB_DIRECTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TProgrammePersonJob.JOB_DIRECTOR)]
			Next
			For local p:TProgrammePerson = EachIn GetPersonsFromString(actorsRaw, TProgrammePersonJob.JOB_ACTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TProgrammePersonJob.JOB_ACTOR)]
			Next

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			local movieLicence:TProgrammeLicence = new TProgrammeLicence
			movieLicence.SetData(TProgrammeData.Create("", localizeTitle, localizeDescription, cast, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_MOVIE))

			'convert old genre definition to new one
			convertV2genreToV3(movieLicence.data)
			
			'add to collection (it is sorted automatically)
			GetProgrammeLicenceCollection().AddAutomatic(movieLicence)

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


			local cast:TProgrammePersonJob[]
			For local p:TProgrammePerson = EachIn GetPersonsFromString(directorsRaw, TProgrammePersonJob.JOB_DIRECTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TProgrammePersonJob.JOB_DIRECTOR)]
			Next
			For local p:TProgrammePerson = EachIn GetPersonsFromString(actorsRaw, TProgrammePersonJob.JOB_ACTOR)
				cast :+ [new TProgrammePersonJob.Init(p, TProgrammePersonJob.JOB_ACTOR)]
			Next

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")

			'create a licence for that series - with title and series description
			local seriesLicence:TProgrammeLicence = new TProgrammeLicence
			'sets the "overview"-data of the series as series header
			seriesLicence.SetData(TProgrammeData.Create("", localizeTitle, localizeDescription, cast, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_SERIES))

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
					For local p:TProgrammePerson = EachIn GetPersonsFromString(directorsRaw, TProgrammePersonJob.JOB_DIRECTOR)
						cast :+ [new TProgrammePersonJob.Init(p, TProgrammePersonJob.JOB_DIRECTOR)]
					Next
					For local p:TProgrammePerson = EachIn GetPersonsFromString(actorsRaw, TProgrammePersonJob.JOB_ACTOR)
						cast :+ [new TProgrammePersonJob.Init(p, TProgrammePersonJob.JOB_ACTOR)]
					Next

					local localizeTitle:TLocalizedString = new TLocalizedString
					localizeTitle.Set(title, "de")
					local localizeDescription:TLocalizedString = new TLocalizedString
					localizeDescription.Set(description, "de")

					local episodeLicence:TProgrammeLicence = new TProgrammeLicence
					episodeLicence.SetData(TProgrammeData.Create("", localizeTitle, localizeDescription, cast, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_EPISODE))
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
				profit	= 30 * xml.FindValueFloat(nodeChild,"profit", 0)
				penalty	= 30 * xml.FindValueFloat(nodeChild,"penalty", 0)
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

				'creates a TProgrammeLicence of the found entry.
				'If the entry contains "episodes", they get loaded too
				local licence:TProgrammeLicence
				licence = LoadV3ProgrammeLicenceFromNode(nodeProgramme, xml)

				if licence
					if licence.isMovie()
						moviesCount :+ 1
						totalMoviesCount :+ 1
					elseif licence.isSeries()
						seriesCount :+ 1
						totalSeriesCount :+ 1
					endif

					GetProgrammeLicenceCollection().AddAutomatic(licence)
				endif
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
			"fix_price", "duration", "profit", "penalty", ..
			"pro_pressure_groups", "contra_pressure_groups" ..
		])
			

'aktivieren, wenn Datenbank Eintraege enthaelt, die infomercials erlauben
'				adContract.infomercialAllowed = data.GetBool("infomercial", adContract.infomercialAllowed)
'				adContract.quality = data.GetBool("quality", adContract.quality)
		adContract.quality = 0.5

		adContract.spotCount = data.GetInt("repetitions", adContract.spotcount)
		adContract.fixedPrice = data.GetInt("fix_price", adContract.fixedPrice)
		adContract.daysToFinish = data.GetInt("duration", adContract.daysToFinish)
		adContract.proPressureGroups = data.GetInt("pro_pressure_groups", adContract.proPressureGroups)
		adContract.contraPressureGroups = data.GetInt("contra_pressure_groups", adContract.contraPressureGroups)
		adContract.profitBase = data.GetFloat("profit", adContract.profitBase)
		adContract.penaltyBase = data.GetFloat("penalty", adContract.penaltyBase)
	

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
		adContract.minImageBase = 0.01 * data.GetFloat("min_image", adContract.minImageBase*100.0)
		adContract.limitedToTargetGroup = data.GetInt("target_group", adContract.limitedToTargetGroup)
		adContract.limitedToProgrammeGenre = data.GetInt("allowed_genre", adContract.limitedToProgrammeGenre)
		adContract.limitedToProgrammeType = data.GetInt("allowed_programme_type", adContract.limitedToProgrammeType)
		adContract.forbiddenProgrammeGenre = data.GetInt("prohibited_genre", adContract.forbiddenProgrammeGenre)
		adContract.forbiddenProgrammeType = data.GetInt("prohibited_programme_type", adContract.forbiddenProgrammeType)
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
		local programmeType:int = TXmlHelper.FindValueInt(node,"product", 0)
		local programmeData:TProgrammeData
		local programmeLicence:TProgrammeLicence

		'=== PROGRAMME DATA ===
		'try to fetch an existing licence with the entries GUID
		'TODO: SPLIT LICENCES FROM DATA
		programmeLicence = GetProgrammeLicenceCollection().GetByGUID(GUID)
		if not programmeLicence
			'try to clone the parent's data - if that fails, create
			'a new instance
			if parentLicence then programmeData = TProgrammeData(THelper.CloneObject(parentLicence.data))
			if not programmeData then programmeData = new TProgrammeData

			programmeData.GUID = GUID
			programmeData.title = new TLocalizedString
			programmeData.description = new TLocalizedString

			programmeLicence = new TProgrammeLicence
		else
			programmeData = programmeLicence.GetData()
			if not programmeData then Throw "Loading V3 Programme from XML: Existing programmeLicence without data found."
		endif


		'=== ADD PROGRAMME DATA TO LICENCE ===
		'this just overrides the existing data - even if identical
		programmeLicence.SetData(programmeData)

		
		'=== LOCALIZATION DATA ===
		programmeData.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(node, "title")) )
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
		programmeData.priceModifier = data.GetFloat("price_mod", programmeData.priceModifier)
		programmeData.flags = data.GetInt("flags", programmeData.flags)

		programmeData.genre = data.GetInt("maingenre", programmeData.genre)
		programmeData.subGenre = data.GetInt("subgenre", programmeData.subGenre)

		'for movies/series set a releaseDay until we have that
		'in the db.
		if not parentLicence
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
			'if person was defined
			if member
				Select memberFunction
					case TProgrammePersonJob.JOB_ACTOR
						programmeData.AddCast(new TProgrammePersonJob.Init(member, TProgrammePersonJob.JOB_ACTOR))
					case TProgrammePersonJob.JOB_DIRECTOR
						programmeData.AddCast(new TProgrammePersonJob.Init(member, TProgrammePersonJob.JOB_DIRECTOR))
				End Select
			endif
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


		'=== LICENCE TYPE ===
		'the licenceType is adjusted as soon as "AddData" was used
		'so correct it if needed
		Select programmeType
			case 1	 programmeData.programmeType = TProgrammeData.TYPE_MOVIE
			case 2	 programmeData.programmeType = TProgrammeData.TYPE_SERIES
			case 4	 programmeData.programmeType = TProgrammeData.TYPE_EPISODE
		End Select


		
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
			programmeData.programmeType = TProgrammeData.TYPE_MOVIE
			print "Series with 0 episodes found. Converted to movie: "+programmeLicence.GetTitle()
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


		return programmeLicence
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
				data.SetFlag(TProgrammeData.FLAG_LIVE)
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
				data.SetFlag(TProgrammeData.FLAG_TRASH)
			case 17 'old SHOW
				data.genre = TVTProgrammeGenre.Undefined_Show
			case 18 'old MONUMENTAL
				data.genre = TVTProgrammeGenre.Monumental
			case 19 'TProgrammeData.GENRE_FILLER 'TV films etc.
				data.genre = TVTProgrammeGenre.Undefined
			case 20 'old CALLINSHOW
				data.genre = TVTProgrammeGenre.Undefined
				data.SetFlag(TProgrammeData.FLAG_PAID)
			default
				data.genre = TVTProgrammeGenre.Undefined
		End Select
	End Function


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