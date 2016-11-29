SuperStrict
Import "game.newsagency.sports.bmx"
Import "game.stationmap.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "Dig/base.util.mersenne.bmx"


'=== SOCCER ===
Type TNewsEventSport_Soccer extends TNewsEventSport
	Global teamsPerLeague:int = 6
	'name | abbreviation | singular/plural 
	Global teamPrefixes:string[] = ["Fussballverein|FV|s",..
	                                "Fussballfreunde|FF|p", ..
	                                "Hallenkicker|HK|p", ..
	                                "Freizeitkicker|FK|p", ..
	                                "Spielvereinigung|SpVgg|p", ..
	                                "1. Fussballclub|1.FC|s", ..
	                                "2. Fussballclub|2.FC|s", ..
	                                "Ballsportfreunde|BSV|p", ..
	                                "Sportverein|SV|s", ..
	                                "Kickers|K|p", ..
	                                "Dynamo|D|s", ..
	                                "Barfuss|Bf|s", ..
	                                "Bolzclub|BC|s", ..
	                                "Fussballclub|FC|s", ..
	                                "Fussballsportverein|FSV|s", ..
	                                "Werksportverein|WSV|s" ..
	                               ]

	Method New()
		name = "SOCCER"
	End Method


	Method Initialize:TNewsEventSport_Soccer()
		Super.Initialize()
		return self
	End Method


	Method CreateDefaultLeagues:int()
		local soccerConfig:TData = GetStationMapCollection().GetSportData("soccer", new TData)
		'create 4 leagues (if not overridden)
		local leagueCount:Int = soccerConfig.GetInt("leagueCount", 4)

		CreateLeagues( leagueCount )

		for local i:int = 1 to leagueCount
			local l:TNewsEventSportLeague_Soccer = TNewsEventSportLeague_Soccer(GetLeagueAtIndex(i-1))
			l.name = soccerConfig.GetData("league"+i).GetString("name", i+". Liga")
			l.nameShort = soccerConfig.GetData("league"+i).GetString("nameShort", i+". L")
		Next
	End Method


	Function CreateMatch:TNewsEventSportMatch_Soccer()
		return new TNewsEventSportMatch_Soccer
	End Function


	Method CreateTeam:TNewsEventSportTeam(prefix:String="", cityName:string="", teamName:string="", teamNameInitials:string="")
		if not prefix then prefix = teamPrefixes[RandRange(0, teamPrefixes.length-1)]

		local team:TNewsEventSportTeam = new TNewsEventSportTeam
		local teamPrefix:string[] = prefix.Split("|")


		if cityName 
			team.city = cityName
		else
			'fall back to teamname if someone forgot to define a city
			team.city = teamName
		endif
		if teamName
			team.name = teamName
		else
			team.name = team.city
		endif

		local capitalLetters:string = teamNameInitials
		if capitalLetters = ""
			'method 1 - only capital letters
			rem
			For local ch:int = EachIn teamNames[i]
				if (ch>=Asc("A") And ch<=Asc("Z")) then capitalLetters :+ Chr(ch)
			Next
			endrem
			'method 2 - name-parts ("Bad |Klein|grunda" = "BKG")
			For local part:string = EachIn team.name.split("|")
				if not part then continue 'happens for second part in "bla|"
				capitalLetters :+ Chr(StringHelper.UCFirst(part)[0])
			Next
		endif

		team.nameInitials = capitalLetters
		'clean potential "splitters" (now we created "capital letters")
		team.city = team.city.replace("|","")
		team.name = team.name.replace("|","")

		team.clubName = teamPrefix[0]
		team.clubNameInitials = teamPrefix[1]
		if teamPrefix.length < 3 or teamPrefix[2] = "s" 
			team.clubNameSingular = True
		else
			team.clubNameSingular = False
		endif

		return team
	End Method


	Method CreateLeagues(leagueCount:int)
		'select and fill teams
		local allUsedCityNames:string[]
		local countryCodes:string[] = GetPersonGenerator().GetCountryCodes()
		local emptyData:TData = new TData
		local predefinedSportData:TData = GetStationMapCollection().GetSportData("soccer", emptyData)
'print predefinedSportData.ToString()
		
		For local leagueIndex:int = 0 until leagueCount
			local cityNames:string[]
			local predefinedLeagueData:TData = predefinedSportData.GetData("league"+(leagueIndex+1), emptyData)

			For local i:int = 0 until teamsPerLeague
				local cityName:string
				'skip random name generation, if a team is defined already
				local predefinedTeamData:TData = predefinedLeagueData.GetData("team"+(i+1), emptyData)
				cityName = predefinedTeamData.GetString("name")
				

				if cityName = ""
					local tries:int = 0
					repeat
						cityName = GetStationMapCollection().GenerateCity("|") 'split parts
						tries :+ 1
					until not StringHelper.InArray(cityName, allUsedCityNames) or tries > 1000
					if tries > 1000 then cityName = "unknown-"+Millisecs()+"-" + RandRange(0,100000)
				endif
				cityNames :+ [cityName]
				allUsedCityNames :+ [cityName]
			Next


			local teams:TNewsEventSportTeam[]
			For local i:int = 0 until cityNames.length
				'use predefined data if possible
				local predefinedTeamData:TData = predefinedLeagueData.GetData("team"+(i+1), emptyData)

				local team:TNewsEventSportTeam
				team = CreateTeam(predefinedTeamData.GetString("prefix", ""), ..
				                  predefinedTeamData.GetString("city", cityNames[i]), ..
				                  predefinedTeamData.GetString("name", ""), ..
				                  predefinedTeamData.GetString("nameInitials", "") ..
				                 )
				teams :+ [team]
				'give them some basic attributes
				team.RandomizeBasicStats(leagueIndex)

'print "league="+(leagueIndex+1)+"  team="+(i+1)+"  name=" + team.name+"  city="+team.city+"  nameInitials="+team.nameInitials+"  clubName="+team.clubName+"  clubNameInitials="+team.clubNameInitials

				For local j:int = 0 to (11+3) '0 is trainer, 3 is reserve
					local cCode:string = "de"
					if RandRange(0, 10) < 3 then cCode = countryCodes[ RandRange(0, countryCodes.length-1) ]

					local p:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(cCode, TPersonGenerator.GENDER_MALE)
					local member:TNewsEventsportTeamMember = new TNewsEventsportTeamMember.Init( p.firstName, p.lastName, p.countryCode, p.gender, True)
					if j <> 0
						team.AddMember( member )
					else
						team.SetTrainer( member )
					endif
				Next
			Next
			

			local league:TNewsEventSportLeague_Soccer = new TNewsEventSportLeague_Soccer
			league.Init((leagueIndex+1) + ". " + GetLocale("SOCCER_LEAGUE"), leagueIndex+".", teams)
			league.matchesPerTimeSlot = 2
			if leagueIndex = 0
				league.timeSlots = [ ..
				                    "0_16", "0_20", ..
				                    "2_16", "2_20", ..
				                    "4_16", "4_20", ..
				                    "5_16", "5_20" ..
				                   ]
				league.seasonStartDay = 14
				league.seasonStartMonth = 8
			elseif leagueIndex > 0
				league.timeSlots = [ ..
				                    "0_14", "0_18", ..
				                    "2_14", "2_18", ..
				                    "4_14", "4_18", ..
				                    "5_14", "5_18" ..
				                   ]
				league.seasonStartDay = 29
				league.seasonStartMonth = 7
			endif

			AddLeague( league )
		Next
	End Method
End Type



Type TNewsEventSportLeague_Soccer extends TNewsEventSportLeague
	Method New()
		seasonStartMonth = 8
		seasonStartDay = 14
		matchesPerTimeSlot = 2
	End Method


	Method Custom_CreateUpcomingMatches:int()
		TNewsEventSport_Soccer.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_Soccer.CreateMatch)
	End Method


	Method GetFirstMatchTime:Long(time:Long)
		'take year of the given time and use the defined months for a
		'soccer season
		'match time: 14. 8. - 14.5. (1. Liga)
		'match time: 29. 7. -       (3. Liga)
		Return GetWorldTime().MakeRealTime(GetWorldTime().GetYear(time), seasonStartMonth, seasonStartDay, 0, 0)
	End Method


	'override
	'2 matches per "time slot" instead of 1
	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Long = 0, isPlayoffSeason:int=0)
		'time = GetNextMatchStartTime(time)

		if not season then season = GetCurrentSeason()
'if isPlayoffSeason
'	print "AssignMatchTimes PLAYOFFS: " + GetWorldTime().GetFormattedDate(time)
'else
'	print "AssignMatchTimes: " + GetWorldTime().GetFormattedDate(time)
'endif
		local matches:int = 1
		For local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			m.SetMatchTime(time)
'			if GetWorldTime().GetTimeGone() < time
'				print "   "+ name+ "  match: "+GetWorldTime().GetFormattedDate(m.matchTime) + "  gameday="+ (GetWorldTime().GetDaysRun(m.matchTime)+1) + "  " + m.GetNameShort()
'			endif

			'every x-th match we increase time - so matches get "grouped"
			if isPlayoffSeason or (matches > 1 and matches mod matchesPerTimeSlot = 0)
				'also append some minutes, es we would not move forward
				'without (same time returned again and again)
				'print "      get next time"
				time = GetNextMatchStartTime(time + 10 * 60)
			endif

			matches :+1
		Next
	End Method
End Type




Type TNewsEventSportMatch_Soccer extends TNewsEventSportMatch
	Function CreateMatch:TNewsEventSportMatch_Soccer()
		return new TNewsEventSportMatch_Soccer
	End Function


	Method GetReport:string()
		local matchText:string = GetLocale("SPORT_TEAMREPORT_MATCHRESULT")

		'make first char uppercase
		matchText = StringHelper.UCFirst( ReplacePlaceholders(matchText) )
		return matchText
	End Method


	Method GetLiveReportShort:string(mode:string="", time:Long=-1)
		if time = -1 then time = GetWorldTime().GetTimeGone()
		local timeGone:Int = Max(0, time - GetMatchTime())
		local matchTime:Int = timeGone
		if timeGone >= breakTime
			'currently within a break?
			if timeGone <= breakTime + breakDuration
				matchTime = breakTime
			else
				matchTime :- breakDuration
			endif
		endif
		
		local usePoints:int[] = GetMatchScore(matchTime)
		local result:string

		for local i:int = 0 until usePoints.length
			if result <> ""
				result :+ " : "
				if mode = "INITIALS"
					result :+ usePoints[i] + "] " + teams[i].GetTeamInitials()
				else
					result :+ usePoints[i] + "] " + teams[i].GetTeamNameShort()
				endif
			else
				if mode = "INITIALS"
					result :+ teams[i].GetTeamInitials() + " [" + usePoints[i]
				else
					result :+ teams[i].GetTeamNameShort() + " [" + usePoints[i]
				endif
			endif
		Next
		return result
	End Method
	

	Method GetReportShort:string(mode:string="")
		local result:string

		for local i:int = 0 until points.length
			if result <> ""
				result :+ " : "
				if mode = "INITIALS"
					result :+ points[i] + "] " + teams[i].GetTeamInitials()
				else
					result :+ points[i] + "] " + teams[i].GetTeamNameShort()
				endif
			else
				if mode = "INITIALS"
					result :+ teams[i].GetTeamInitials() + " [" + points[i]
				else
					result :+ teams[i].GetTeamNameShort() + " [" + points[i]
				endif
			endif
		Next
		return result

		'return teams[0].nameInitials + " " + points[0]+" : " + points[1] + " " + teams[1].nameInitials
	End Method


	Method GetFinalScoreText:string()
		'only show halftime points if someone scored something
		local showHalfTimePoints:int = False
		for local i:int = 0 until points.length
			if points[i] <> 0 then showHalfTimePoints = true
		Next

		if showHalfTimePoints
			return Super.GetFinalScoreText()+" (" + StringHelper.JoinIntArray(":", GetMatchScore(duration/2)) + ")"
		else
			return Super.GetFinalScoreText()
		endif
	End Method
	
End Type