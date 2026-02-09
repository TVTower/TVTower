SuperStrict
Import "game.newsagency.sports.bmx"
Import "game.stationmap.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "Dig/base.util.mersenne.bmx"


'=== ICE HOCKEY ===
Type TNewsEventSport_IceHockey extends TNewsEventSport
	Global teamsPerLeague:int = 4
	'name | abbreviation | singular/plural 
	Global teamPrefixes:string[] = ["Tiger|T|p",..
	                                "Eispiraten|EP|p", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "1. Eishockeyclub|1.EHC|s", ..
	                                "2. Eishockeyclub|2.EHC|s", ..
	                                "Bullyfreunde|BF|p", ..
	                                "Puckpiraten|PP|p", ..
	                                "Wildcats|WC|p", ..
	                                "Eagles|E|p", ..
	                                "Schlittschuhsport|SS|s", ..
	                                "Goalers|G|s", ..
	                                "Eisfeen|EF|p", ..
	                                "", ..
	                                "" ..
	                               ]

	Global teamSuffixes:string[] = ["",..
	                                "", ..
	                                "Sharks|S|p", ..
	                                "Pinguins|P|p", ..
	                                "Warriors|W|p", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "", ..
	                                "Powerplay|PP|s", ..
	                                "Face-Off|FO|s" ..
	                               ]

	Method New()
		name = "ICEHOCKEY"
	End Method


	Method Initialize:TNewsEventSport_IceHockey()
		Super.Initialize()
		return self
	End Method


	Method CreateDefaultLeagues:int()
		local mapConfig:TData = GetStationMapCollection().GetSportData("icehockey", new TData)

		'create 4 leagues (if not overridden)
		local leagueCount:Int = mapConfig.GetInt("leagueCount", 4)

		CreateLeagues( leagueCount )

		for local i:int = 1 to leagueCount
			local l:TNewsEventSportLeague_IceHockey = TNewsEventSportLeague_IceHockey(GetLeagueAtIndex(i-1))
			l.name = mapConfig.GetData("league"+i).GetString("name", i+". Liga")
			l.nameShort = mapConfig.GetData("league"+i).GetString("nameShort", i+". L")
		Next
	End Method


	Method GenerateRandomTeamMembers:Int(team:TNewsEventSportTeam) override
		GenerateRandomTeamMembers(team, 6, 3)
	End Method



	Function CreateMatch:TNewsEventSportMatch_IceHockey()
		return new TNewsEventSportMatch_IceHockey
	End Function


	Method CreateTeam:TNewsEventSportTeam(prefix:String="", suffix:String="", cityName:string="", teamName:string="", teamNameInitials:string="")
		local prefixIndex:int = 0
		if not prefix or not suffix then prefixIndex = RandRange(0, teamPrefixes.length-1)

		if not prefix then prefix = teamPrefixes[prefixIndex]
		if not suffix then suffix = teamSuffixes[prefixIndex]

		local team:TNewsEventSportTeam = new TNewsEventSportTeam
		local teamPrefix:string[] = prefix.Split("|")
		local teamSuffix:string[] = suffix.Split("|")


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
		team.clubNameSuffix = teamSuffix[0]
		if teamPrefix.length >= 2
			team.clubNameInitials = teamPrefix[1]
			if teamPrefix.length < 3 or teamPrefix[2] = "s" 
				team.clubNameSingular = True
			else
				team.clubNameSingular = False
			endif
		endif
		if teamSuffix.length >= 2
			team.clubNameSuffixInitials = teamSuffix[1]
			if teamSuffix.length < 3 or teamSuffix[2] = "s" 
				team.clubNameSingular = True
			else
				team.clubNameSingular = False
			endif
		endif

		return team
	End Method


	Method CreateLeagues(leagueCount:int)
		'select and fill teams
		local allUsedCityNames:string[]
		local countryCodes:string[] = GetPersonGenerator().GetCountryCodes()
		local emptyData:TData = new TData
		local predefinedSportData:TData = GetStationMapCollection().GetSportData("icehockey", emptyData)
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


			local teams:TNewsEventSportTeam[] = New TNewsEventSportTeam[ cityNames.length ]
			For local i:int = 0 until cityNames.length
				'use predefined data if possible
				local predefinedTeamData:TData = predefinedLeagueData.GetData("team"+(i+1), emptyData)
				local team:TNewsEventSportTeam
				team = CreateTeam(predefinedTeamData.GetString("prefix", ""), ..
				                  predefinedTeamData.GetString("suffix", ""), ..
				                  predefinedTeamData.GetString("city", cityNames[i]), ..
				                  predefinedTeamData.GetString("name", ""), ..
				                  predefinedTeamData.GetString("nameInitials", "") ..
				                 )
				'give them some basic attributes
				team.RandomizeBasicStats(leagueIndex)
				'tell the team what sport it is doing
				team.AssignSport(self.GetID())

'print "league="+(leagueIndex+1)+"  team="+(i+1)+"  name=" + team.name+"  city="+team.city+"  nameInitials="+team.nameInitials+"  clubName="+team.clubName+"  clubNameInitials="+team.clubNameInitials

				For local j:int = 0 to (6+3) '0 is trainer, 3 is reserve
					local cCode:string = "de"
					if RandRange(0, 10) < 3 then cCode = countryCodes[ RandRange(0, countryCodes.length-1) ]

					local p:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(cCode, TPersonGenerator.GENDER_MALE)
					local member:TPersonBase = new TPersonBase( p.firstName, p.lastName, p.countryCode, p.gender, True)
					'assume 50% are not interested in TV shows / custom productions
					If RandRange(0, 100) < 50
						member.SetFlag(TVTPersonFlag.CASTABLE, False)
					EndIf
					'give the person sports specific data (team assignment is done separately)
					member.AddData("sports_" + self.name, New TPersonSportBaseData)

					if j <> 0
						team.AddMember( member )
					else
						team.SetTrainer( member )
					endif
				Next
				teams[i] = team
			Next
			GetNewsEventSportCollection().AddTeams( teams )

			local league:TNewsEventSportLeague_IceHockey = new TNewsEventSportLeague_IceHockey
			league.Init((leagueIndex+1) + ". " + GetLocale("ICEHOCKEY_LEAGUE"), leagueIndex+".", teams)
			league.matchesPerTimeSlot = 2
			if leagueIndex = 0
				league.timeSlots = [ ..
				                    "1_15", "1_19", ..
				                    "3_15", "3_19", ..
				                    "6_15", "6_19" ..
				                   ]
				league.seasonStartDay = 16
				league.seasonStartMonth = 9
			elseif leagueIndex > 0
				league.timeSlots = [ ..
				                    "2_14", "2_18", ..
				                    "4_14", "4_18", ..
				                    "0_14", "0_18" ..
				                   ]
				league.seasonStartDay = 16
				league.seasonStartMonth = 9
			endif
			
			AddLeague( league )
		Next
	End Method
End Type



Type TNewsEventSportLeague_IceHockey extends TNewsEventSportLeague
	Method New()
		seasonStartMonth = 9
		seasonStartDay = 16
		matchesPerTimeSlot = 3
	End Method


	Method Custom_CreateUpcomingMatches:int()
		TNewsEventSport_IceHockey.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_IceHockey.CreateMatch)
	End Method
	

	Method GetSeasonStartTime:Long(time:Long)
		'take year of the given time and use the defined months for a
		'hockey season
		'match time: 16. 9. - 26.2. (1. Liga)
		Local thisYear:Long = GetWorldTime().GetTimeGoneForRealDate(GetWorldTime().GetYear(time), seasonStartMonth, seasonStartDay)
		If thisYear < time 
			Return thisYear + GetWorldTime().GetYearLength()
		Else
			Return thisYear
		EndIf
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


	Method GetNextMatchStartTime:Long(time:Long = 0, ignoreSeasonBreaks:int = False)
		'ice hockey does not have a season break
		local matchTime:Long = Super.GetNextMatchStartTime(time, True)
		return matchTime
	End Method
End Type




Type TNewsEventSportMatch_IceHockey extends TNewsEventSportMatch
	'0 = normal, 1 = after overtime, 2 = after penalty
	Field scoreType:int = 0


	Method New()
		duration = 60 * TWorldTime.MINUTELENGTH
		breakTimes = [int(1 * 20 * TWorldTime.MINUTELENGTH), int(2 * 20 * TWorldTime.MINUTELENGTH)]
		breakDuration = 15 * TWorldTime.MINUTELENGTH
	End Method
	

	Function CreateMatch:TNewsEventSportMatch_IceHockey()
		return new TNewsEventSportMatch_IceHockey
	End Function


	'override to make it a bit longer
	Method GetMatchEndTime:Long()
		'in ice hockey time is stopped for each "special event" (injuries, etc)
		'so the "ending time" is often 2-2.5h after begin while the game
		'duration is 60 minutes + 2*15 min for breaks
		return matchTime + duration + GetTotalBreakTime() + (0.5 * duration)
	End Method


	'override for higher scores
	Method CalculateTotalScore()
		'calculate total scores
		For local i:int = 0 until points.length
			points[i] = BiasedRandRange(0, 8, 0.30)
		Next

		local equal:int = False
		local currPoint:int = -1
		For local i:int = 0 until points.length
			if currPoint = points[i]
				equal = true
				exit
			endif
			currPoint = points[i]
		Next

		scoreType = RandRange(0, 2)

		if equal
			points[ RandRange(0, points.length-1) ] :+ 1
		endif
	End Method


	Method GetReport:string() override
		local matchText:string = GetLocale("SPORT_TEAMREPORT_MATCHRESULT")

		'make first char uppercase
		matchText = StringHelper.UCFirst( matchText )
		return matchText
	End Method


	Method GetLiveReportShort:string(mode:string="", time:Long=-1) override
		local matchTime:Int = GetMatchTimeGone(time)
		
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
	

	Method GetReportShort:string(mode:string="") override
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
			return Super.GetFinalScoreText()+" (" + StringHelper.IntArrayToString(GetMatchScore(duration/2), ":") + ")"
		else
			return Super.GetFinalScoreText()
		endif
	End Method


	Method GetWinnerScore:int()
		'regular match time
		if scoreType = 0 then return 3
		'overtime
		if scoreType = 1 then return 2
		'penalty
		if scoreType = 2 then return 2

		return 0
	End Method


	Method GetDrawGameScore:int()
		Throw "Drawgame in IceHockey sim - not allowed"
		return 0
	End Method


	Method GetLooserScore:int()
		'regular match time
		if scoreType = 0 then return 0
		'overtime
		if scoreType = 1 then return 1
		'penalty
		if scoreType = 2 then return 1

		return 0
	End Method
End Type
