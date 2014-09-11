SuperStrict
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.directorytree.bmx"
Import "Dig/base.util.xmlhelper.bmx"

Import "game.programme.programmelicence.bmx"
Import "game.programme.adcontract.bmx"
Import "game.programme.newsevent.bmx"


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

			local actors:TProgrammePerson[] = GetPersonsFromString(actorsRaw, TProgrammePerson.JOB_ACTOR)
			local directors:TProgrammePerson[] = GetPersonsFromString(directorsRaw, TProgrammePerson.JOB_DIRECTOR)

			local movieLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
			movieLicence.AddData(TProgrammeData.Create(title, description, actors, directors, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_MOVIE))

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

			local actors:TProgrammePerson[] = GetPersonsFromString(actorsRaw, TProgrammePerson.JOB_ACTOR)
			local directors:TProgrammePerson[] = GetPersonsFromString(directorsRaw, TProgrammePerson.JOB_DIRECTOR)

			'create a licence for that series - with title and series description
			local seriesLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
			'add the "overview"-data of the series
			seriesLicence.AddData(TProgrammeData.Create(title, description, actors, directors, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_SERIES))

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

					local actors:TProgrammePerson[] = GetPersonsFromString(actorsRaw, TProgrammePerson.JOB_ACTOR)
					local directors:TProgrammePerson[] = GetPersonsFromString(directorsRaw, TProgrammePerson.JOB_DIRECTOR)

					local episodeLicence:TProgrammeLicence = TProgrammeLicence.Create(title, description)
					episodeLicence.AddData(TProgrammeData.Create(title, description, actors, directors, land, year, releaseDayCounter mod GetWorldTime().GetDaysPerYear(), livehour, Outcome, review, speed, priceModifier, Genre, duration, xrated, refreshModifier, wearoffModifier, TProgrammeData.TYPE_EPISODE))
					'add that episode to the series licence
					seriesLicence.AddSubLicence(episodeLicence)
				EndIf
			Next

			seriesCount :+ 1
			totalSeriesCount :+ 1
		Next

'rem
		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====

		nodeParent = xml.FindRootChild("allads")
		For nodeChild = EachIn TXmlHelper.GetNodeChildElements(nodeParent)
			If nodeChild.getName() <> "ad" then continue

			title       = xml.FindValue(nodeChild,"title", "unknown title")
			description = xml.FindValue(nodeChild,"description", "")
			targetgroup = xml.FindValueInt(nodeChild,"targetgroup", 0)
			spotcount	= xml.FindValueInt(nodeChild,"repetitions", 1)
			'0-50% -> 0.0 - 0.5
			minaudience	= 0.5 * float(xml.FindValueInt(nodeChild,"minaudience", 0)) /255.0
			'0-50% -> 0.0 - 0.5
			minimage	= 0.5 * float(xml.FindValueInt(nodeChild,"minimage", 0)) /255.0
			fixedPrice = xml.FindValueInt(nodeChild,"fixedprice", 0)
			if fixedPrice
				profit	= xml.FindValueInt(nodeChild,"profit", 0)
				penalty	= xml.FindValueInt(nodeChild,"penalty", 0)
			else
				'0-100% -> 0.0 - 1.0
				profit	= xml.FindValueInt(nodeChild,"profit", 0) / 255.0
				profit	= 255*4 * profit 'adjust to current changes
				'0-100% -> 0.0 - 1.0
				penalty	= xml.FindValueInt(nodeChild,"penalty", 0) / 255.0
				penalty	= 255*4 * penalty 'adjust to current changes
			endif
			daystofinish= xml.FindValueInt(nodeChild,"duration", 1)

			local localizeTitle:TLocalizedString = new TLocalizedString
			localizeTitle.Set(title, "de")
			local localizeDescription:TLocalizedString = new TLocalizedString
			localizeDescription.Set(description, "de")
			
			local ad:TAdContractBase = new TAdContractBase.Create("", localizeTitle, localizeDescription, daystofinish, spotcount, targetgroup, minaudience, minimage, fixedPrice, profit, penalty)
if title = "Aeroswift" then print title+": "+ad.profitBase+", " + ad.minAudienceBase + "  (old)"
if title = "La Baguette" then print title+": "+ad.profitBase+", " + ad.penaltyBase +"  " + ad.minAudienceBase + "  (old)"
			'print "contract: "+title+ " " + contractscount
			contractsCount :+ 1
			totalContractsCount :+ 1
		Next
'endrem

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

		'===== IMPORT ALL ADVERTISEMENTS / CONTRACTS =====
		local nodeAllAds:TxmlNode = xml.FindRootChild("allads")
		if nodeAllAds
			local adContract:TAdContractBase
			For local nodeAd:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(nodeAllAds)
				If nodeAd.getName() <> "ad" then continue

				local GUID:String = xml.FindValue(nodeAd,"id", "")
				'try to fetch an existing one
				adContract = GetAdContractBaseCollection().GetByGUID(GUID)
				if not adContract
					adContract = new TAdContractBase
					adContract.title = new TLocalizedString
					adContract.description = new TLocalizedString
				endif
				
				'read in data
				adContract.title.Append( GetLocalizedStringFromNode(xml.FindElementNode(nodeAd, "title")) )
				adContract.description.Append( GetLocalizedStringFromNode(xml.FindElementNode(nodeAd, "description")) )

				'=== DATA ===
				local nodeData:TxmlNode = xml.FindElementNode(nodeAd, "data")
				local data:TData = new TData
				xml.LoadValuesToData(nodeData, data, [..
					"infomercial", "quality", "repetitions", ..
					"fixed_price", "duration", "profit", "penalty", ..
					"pro_pressure_group", "contra_pressure_group" ..
				])
					

'aktivieren, wenn Datenbank Eintraege enthaelt, die infomercials erlauben
'				adContract.infomercialAllowed = data.GetBool("infomercial", adContract.infomercialAllowed)
'				adContract.quality = data.GetBool("quality", adContract.quality)
				adContract.infomercialAllowed = data.GetBool("infomercial", adContract.infomercialAllowed)
				adContract.quality = 0.5

				adContract.spotCount = data.GetInt("repetitions", adContract.spotcount)
				adContract.fixedPrice = data.GetInt("fixed_price", adContract.fixedPrice)
				adContract.daysToFinish = data.GetInt("duration", adContract.daysToFinish)

'ueberpruefen wann korrekt in neuer DB gespeichert
'dann "if"-unterscheidung nicht mehr notwendig
				If adContract.fixedPrice
					adContract.profitBase = data.GetInt("profit", adContract.profitBase)
					adContract.penaltyBase = data.GetInt("penalty", adContract.penaltyBase)
				Else
					adContract.profitBase = data.GetInt("profit", adContract.profitBase * 250)/250.0
					adContract.penaltyBase = data.GetInt("penalty", adContract.penaltyBase * 250)/250.0
				endif

				'TODO
				'adContract.proPressureGroup = data.GetInt("pro_pressure_group", adContract.pro_pressure_group)
				'adContract.contraPressureGroup = data.GetInt("contra_pressure_group", adContract.contra_pressure_group)
			

				'=== CONDITIONS ===
				local nodeConditions:TxmlNode = xml.FindElementNode(nodeAd, "conditions")
				xml.LoadValuesToData(nodeData, data, [..
					"min_audience", "min_image", "target_group" ..
				])
'aktivieren, wenn DB korrigiert (50% der Werte)
				'0-100% -> 0.0 - 1.0
'				adContract.minAudienceBase = 0.01 * data.GetInt("min_audience", adContract.minAudienceBase*100)
'				adContract.minImageBase = 0.01 * data.GetInt("min_image", adContract.minImageBase*100)
				adContract.minAudienceBase = 0.01 * int(0.5 * data.GetInt("min_audience", adContract.minAudienceBase * 200))
				adContract.minImageBase = 0.01 * int(0.5 * data.GetInt("min_image", adContract.minImageBase * 200))
				adContract.targetGroup = data.GetInt("target_group", adContract.targetGroup)

				'TODO:
				'<allowed_genre>1</allowed_genre>
				'<prohibited_genre>2</prohibited_genre>
				'<allowed_programme_type>3</allowed_programme_type>
				'<prohibited_programme_type>4</prohibited_programme_type>

if adcontract.title.Get() = "Aeroswift"
	print adcontract.title.Get() +":  "+adContract.profitBase+", " + adContract.minAudienceBase
endif
			rem
				local proPressureGroups:String[] = data.GetString("pro_pressure_groups", "").Split(" ")
				For local group:string = EachIn proPressureGroups
					if not adContract.HasProPressureGroup(int(group))
						adContract.proPressureGroups :+ [int(group)]
					endif
				Next
				local contraPressureGroups:String[] = data.GetString("contra_pressure_groups", "").Split(" ")
				For local group:string = EachIn contraPressureGroups
					if not adContract.HasContraPressureGroup(int(group))
						adContract.contraPressureGroups :+ [int(group)]
					endif
				Next
				endrem

				'add to collection
		'		GetAdContractBaseCollection().Add(adContract)

				'print "contract: "+title+ " " + contractscount
				contractsCount :+ 1
				totalContractsCount :+ 1
			Next
		endif

		TLogger.log("TDatabase.Load()", "Loaded DB ~q" + xml.filename + "~q (version 3). Found " + seriesCount + " series, " + moviesCount + " movies, " + contractsCount + " advertisements, " + newsCount + " news. loading time: " + stopWatch.GetTime() + "ms", LOG_LOADING)
	End Method



	'=== HELPER ===

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