SuperStrict
Import "game.newsagency.sports.bmx"
Import "game.stationmap.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "Dig/base.util.mersenne.bmx"


'=== SOCCER ===
Type TNewsEventSport_Soccer extends TNewsEventSport
	'name | abbreviation | singular/plural 
	Global teamPrefixes:string[] = ["Fussballverein|FV|s",..
	                                "Fussballfreunde|FF|p", ..
	                                "Hallenkicker|HK|p", ..
	                                "Freizeitkicker|FK|p", ..
	                                "Bolzclub|BC|s", ..
	                                "Fussballclub|FC|s", ..
	                                "Fussballsportverein|FSV|s", ..
	                                "Werksportverein|WSV|s" ..
	                               ]

	Function CreateMatch:TNewsEventSportMatch_Soccer()
		return new TNewsEventSportMatch_Soccer
	End Function


	Method CreateLeagues(leagueCount:int)
		'select and fill teams
		local allUsedTeamNames:string[]
		local countryCodes:string[] = GetPersonGenerator().GetCountryCodes()
		
		For local leagueIndex:int = 0 to leagueCount
			local teamNames:string[]

			For local i:int = 0 until 5 '8
				local name:string
				local tries:int = 0
				repeat
					name = GetStationMapCollection().GenerateCity("|") 'split parts
					tries :+ 1
				until not StringHelper.InArray(name, allUsedTeamNames) or tries > 1000
				if tries > 1000 then name = "unknown-"+Millisecs()+"-" + RandRange(0,100000)
				teamNames :+ [name]
				allUsedTeamNames :+ [name]
			Next


			local teams:TNewsEventSportTeam[]
			For local i:int = 0 until teamNames.length
				local team:TNewsEventSportTeam = new TNewsEventSportTeam
				local teamPrefix:string[] = teamPrefixes[RandRange(0, teamPrefixes.length-1)].Split("|")

				local capitalLetters:string = ""
				'method 1 - only capital letters
				rem
				For local ch:int = EachIn teamNames[i]
					if (ch>=Asc("A") And ch<=Asc("Z")) then capitalLetters :+ Chr(ch)
				Next
				endrem
				'method 2 - name-parts ("Bad |Klein|grunda" = "BKG")
				For local part:string = EachIn teamNames[i].split("|")
					capitalLetters :+ Chr(StringHelper.UCFirst(part)[0])
				Next

				team.city = teamNames[i].replace("|","")
				team.name = teamPrefix[0] + " " + teamNames[i].replace("|","")
				team.nameInitials = teamPrefix[1] + capitalLetters
				team.clubName = teamPrefix[0] 
				team.clubNameInitials = teamPrefix[1]
				if teamPrefix.length < 2 or teamPrefix[2] = "s" 
					team.clubNameSingular = True
				else
					team.clubNameSingular = False
				endif

				teams :+ [team]


				For local j:int = 0 to 12 '0 is trainer
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
			league.timeSlots = [20]

			AddLeague( league )
		Next
	End Method
End Type



Type TNewsEventSportLeague_Soccer extends TNewsEventSportLeague
	Field seasonJustBegun:int = False
	Field timeSlots:int[] = [14,20]
	Field matchesPerTimeSlot:int = 2
	Field startDay:int = 9


	Method Custom_CreateUpcomingMatches:int()
		TNewsEventSport_Soccer.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_Soccer.CreateMatch)
	End Method
	

	Method StartSeason:int(time:Double = 0)
		seasonJustBegun = True
		return Super.StartSeason(time)
	End Method


	'override
	'2 matches per "time slot" instead of 1
	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Double = 0)
		if time = 0 then time = GetNextMatchStartTime(time)
		if not season then season = GetCurrentSeason()

		local matches:int = 0
		For local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			matches :+1

			m.SetMatchTime(time)
			'every x-th match we increase time
			if matches mod matchesPerTimeSlot = 0 then time = GetNextMatchStartTime(time)
		Next
	End Method


	Method GetNextMatchStartTime:Double(time:Double = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		local weekday:string = GetWorldTime().GetDayName( GetWorldTime().GetWeekday( GetWorldTime().GetOnDay(time) ) )
		'playtimes:
		'0 monday:    x
		'1 tuesday:   -
		'2 wednesday: x
		'3 thursday:  -
		'4 friday:    x
		'5 saturday:  x
		'6 sunday:    -
		local matchDay:int = 0
		local matchHour:int = -1

		'search the next possible time slot
		For local t:int = EachIn timeSlots
			if GetWorldTime().GetDayHour(time) < t then matchHour = t
			if matchHour <> -1 then exit
		Next
		if matchHour = -1 then matchHour = timeSlots[0]


		Select weekday
			case "FRIDAY"
				'next match on saturday
				if GetWorldTime().GetDayHour(time) >= 20 then matchDay = 1
			case  "SATURDAY", "MONDAY", "WEDNESDAY"
				'next match 2 days later
				if GetWorldTime().GetDayHour(time) >= 20 then matchDay = 2
			Default
				'next day at 14:00
				matchDay = 1
				matchHour = timeSlots[0]
		End Select

		local matchTime:Double = 0
		'match time: 14. 8. - 14.5.
		'winter break: 21.12. - 21.1.

		'first match
		if seasonJustBegun
			matchTime = GetWorldTime().MakeTime(GetWorldTime().Getyear(time), startDay, timeslots[0], 0)
		else
			matchTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(time) + matchDay, matchHour, 0)
		endif

		'check if we are in winter now
		local winterBreak:int = False
		local monthCode:int = int((RSet(GetWorldTime().GetMonth(matchTime),2) + RSet(GetWorldTime().GetDayOfMonth(matchTime),2)).Replace(" ", 0))
		'from 5th of december
		if 1220 < monthCode then winterBreak = True
		'till 22th of january
		if  122 > monthCode then winterBreak = True

		if winterBreak and not seasonJustBegun
			local t:Long
			'next match starts in february
			'take time of 2 months later (either february or march - so
			'guaranteed to be the "next" year - when still in december)
			t = matchTime + GetWorldTime().MakeRealTime(0, 2, 0, 0, 0)
			'set time to "next year" begin of february - use "MakeRealTime"
			'to get the time of the ingame "5th february" (or the next
			'possible day)
			t = GetWorldTime().MakeRealTime(GetWorldTime().GetYear(t), 2, 5, 0, 0)
			'use this time then to calculate the gameday and 14:00hr
			matchTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(t), timeSlots[0], 0)
		endif
		
		seasonJustBegun = False

		return matchTime
	End Method
End Type




Type TNewsEventSportMatch_Soccer extends TNewsEventSportMatch
	Global matchWinS:string[] = ["besiegt dank %TEAM1STAR%", ..
	                            "und Stürmer %TEAM1STAR% gewinnen %MATCHKIND% gegen", ..
	                            "schlägt %MATCHKIND%", ..
	                            "schlägt dank verwandelter Ecke durch %TEAM1STARSHORT% %MATCHKIND%", ..
	                            "besiegt dank gehaltenem Elfmeter von Torwart %TEAM1KEEPERSHORT% %MATCHKIND%", ..
	                            "schlägt dank genialer Paraden von Torwart %TEAM1KEEPERSHORT% %MATCHKIND%", ..
	                            "holt 3 Punkte gegen", ..
	                            "bezwingt" ..
	                           ]
	Global matchWinP:string[] = ["besiegen dank %TEAM1STAR%", ..
	                            "und Stürmer %TEAM1STAR% gewinnen %MATCHKIND% gegen", ..
	                            "schlagen %MATCHKIND%", ..
	                            "schlagen dank verwandelter Ecke durch %TEAM1STARSHORT% %MATCHKIND%", ..
	                            "besiegen dank gehaltenem Elfmeter von Torwart %TEAM1KEEPERSHORT% %MATCHKIND%", ..
	                            "schlagen dank genialer Paraden von Torwart %TEAM1KEEPERSHORT% %MATCHKIND%", ..
	                            "holen 3 Punkte gegen", ..
	                            "bezwingen" ..
	                           ]
	Global matchDrawS:string[] = ["verspielt die Chance auf 3 Punkte gegen", ..
	                             "erreicht nur ein Unentschieden gegen", ..
	                             "holt %MATCHKIND% 1 Punkt gegen" ..
	                            ]
	Global matchDrawP:string[] = ["verspielen die Chance auf 3 Punkte gegen", ..
	                             "erreichen nur ein Unentschieden gegen", ..
	                             "holen %MATCHKIND% 1 Punkt gegen" ..
	                            ]
	Global matchLooseS:string[] = ["unterliegt durch Schusselfehler von Torwart %TEAM1KEEPERSHORT% und %MATCHKIND% gegen", ..
	                               "unterliegt trotz guter Leistungen vom Keeper %TEAM1KEEPERSHORT% %MATCHKIND% gegen", ..
	                               "verliert mit enttäuschtem Torwart %TEAM1KEEPER% %MATCHKIND% gegen", ..
	                               "gibt %MATCHKIND% 3 wertvolle Punkte an", ..
	                               "blamiert sich %MATCHKIND% gegen", ..
	                               "verschenkt %MATCHKIND% 3 Punkte an" ..
	                             ]
	Global matchLooseP:string[] = ["unterliegen durch Schusselfehler von Torwart %TEAM1KEEPERSHORT% und %MATCHKIND% gegen", ..
	                               "unterliegen trotz guter Leistungen vom Keeper %TEAM1KEEPERSHORT% %MATCHKIND% gegen", ..
	                               "verlieren mit enttäuschtem Torwart %TEAM1KEEPER% %MATCHKIND% gegen", ..
	                               "geben %MATCHKIND% 3 wertvolle Punkte an", ..
	                               "blamieren sich %MATCHKIND% gegen", ..
	                               "verschenken %MATCHKIND% 3 Punkte an" ..
	                             ]
	Global matchKind:string[] = ["verdient", ..
	                             "unverdient", ..
	                             "nach %PLAYTIMEMINUTES% Minuten zweifelhaften Fussballs", ..
	                             "nach %PLAYTIMEMINUTES% Min taktischer Zweikämpfe", ..
	                             "nach langen %PLAYTIMEMINUTES% Min Spielzeit", ..
	                             "nach spannenden %PLAYTIMEMINUTES% Minuten Rasensport", ..
	                             "in einem Spektakel von Spiel", ..
	                             "in einer Zitterpartie", ..
	                             "im ausverkauften Stadion", ..
	                             "vor voller Kulisse", ..
	                             "vor skandierenden Zuschauern", ..
	                             "vor frenetischem Publikum", ..
	                             "bei nahezu leerem Fanblock", ..
	                             "vor gefüllten Stadionrängen" ..
	                            ]
	Global matchResult:string = "%TEAMARTICLE1% %TEAM1% %MATCHRESULT% %TEAMARTICLE2% %TEAM2% mit %FINALSCORE%."
	Global teamNameSPText1:string = "der"
	Global teamNameSPText2:string = "den"
	Global teamNamePPText1:string = "die"
	Global teamNamePPText2:string = "die"


	Function CreateMatch:TNewsEventSportMatch_Soccer()
		return new TNewsEventSportMatch_Soccer
	End Function


	Method GetReport:string()
		local matchWin:string[]
		local matchDraw:string[]
		local matchLoose:string[]
		if teams[0].clubNameSingular
			matchWin = matchWinS
			matchDraw = matchDrawS
			matchLoose = matchLooseS
		else
			matchWin = matchWinP
			matchDraw = matchDrawP
			matchLoose = matchLooseP
		endif
			
		local matchResultText:string = ""
		if points[0] > points[1]
			matchResultText = matchWin[RandRange(0, matchWin.length-1)]
		elseif points[0] < points[1]
			matchResultText = matchLoose[RandRange(0, matchLoose.length-1)]
		else
			matchResultText = matchDraw[RandRange(0, matchDraw.length-1)]
		endif
		
			
		local matchText:string = matchResult
		matchText = matchText.Replace("%MATCHRESULT%", matchResultText)
		if RandRange(0,10) < 7
			matchText = matchText.Replace("%MATCHKIND%", matchKind[ RandRange(0, matchKind.length-1) ])
		else
			matchText = matchText.Replace("%MATCHKIND%", "")
		endif
		if RandRange(0,100) < 75
			matchText = matchText.Replace("%TEAM1%", teams[0].name)
		else
			matchText = matchText.Replace("%TEAM1%", teams[0].clubNameInitials +" "+ teams[0].city)
		endif
		matchText = matchText.Replace("%TEAM1SHORT%", teams[0].nameInitials)
		matchText = matchText.Replace("%TEAM1LONG%", teams[0].name)

		if RandRange(0,100) < 75
			matchText = matchText.Replace("%TEAM2%", teams[1].name)
		else
			matchText = matchText.Replace("%TEAM2%", teams[1].clubNameInitials +" "+ teams[1].city)
		endif
		matchText = matchText.Replace("%TEAM2LONG%", teams[1].name)
		matchText = matchText.Replace("%TEAM2SHORT%", teams[1].nameInitials)
		if points[0] <> 0 or points[1] <> 0
			matchText = matchText.Replace("%FINALSCORE%", points[0]+":"+points[1]+" ("+int(Max(0,floor(points[0]/2)-RandRange(0,2)))+":"+int(Max(0,floor(points[1]/2)-RandRange(0,2)))+")")
		else
			matchText = matchText.Replace("%FINALSCORE%", points[0]+":"+points[1])
		endif
		if teams[0].clubNameSingular
			matchText = matchText.Replace("%TEAMARTICLE1%", StringHelper.UCFirst(teamNameSPText1))
		else
			matchText = matchText.Replace("%TEAMARTICLE1%", StringHelper.UCFirst(teamNamePPText1))
		endif
		if teams[1].clubNameSingular
			matchText = matchText.Replace("%TEAMARTICLE2%", teamNameSPText2)
		else
			matchText = matchText.Replace("%TEAMARTICLE2%", teamNamePPText2)
		endif
		matchText = matchText.Replace("%TEAM1STAR%", teams[0].GetMemberAtIndex(-1).GetFullName() )
		matchText = matchText.Replace("%TEAM2STAR%", teams[1].GetMemberAtIndex(-1).GetFullName() )
		matchText = matchText.Replace("%TEAM1STARSHORT%", teams[0].GetMemberAtIndex(-1).GetLastName() )
		matchText = matchText.Replace("%TEAM2STARSHORT%", teams[1].GetMemberAtIndex(-1).GetLastName() )
		matchText = matchText.Replace("%TEAM1KEEPER%", teams[0].GetMemberAtIndex(0).GetFullName() )
		matchText = matchText.Replace("%TEAM2KEEPER%", teams[1].GetMemberAtIndex(0).GetFullName() )
		matchText = matchText.Replace("%TEAM1KEEPERSHORT%", teams[0].GetMemberAtIndex(0).GetLastName() )
		matchText = matchText.Replace("%TEAM2KEEPERSHORT%", teams[1].GetMemberAtIndex(0).GetLastName() )
		matchText = matchText.Replace("%PLAYTIMEMINUTES%", int(duration / 60) )
		matchText = matchText.Trim().Replace("  ", " ") 'remove space if no team article...
		return matchText
	End Method


	Method GetReportShort:string()
		local result:string
		for local i:int = 0 until points.length
			if result <> ""
				result :+ " : "
				result :+ points[i] + " " + teams[i].nameInitials
			else
				result :+ teams[i].nameInitials + " " + points[i]
			endif
		Next
		return result

		'return teams[0].nameInitials + " " + points[0]+" : " + points[1] + " " + teams[1].nameInitials
	End Method
	
End Type