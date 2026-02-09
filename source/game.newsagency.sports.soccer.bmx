SuperStrict
Import "game.newsagency.sports.bmx"
Import "game.stationmap.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "Dig/base.util.mersenne.bmx"


'=== SOCCER ===
Type TNewsEventSport_Soccer Extends TNewsEventSport
	Global teamsPerLeague:Int = 4
	'name | abbreviation | singular/plural 
	Global teamPrefixes:String[] = ["Fussballverein|FV|s",..
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
		Return Self
	End Method


	Method CreateDefaultLeagues:Int()
		Local soccerConfig:TData = GetStationMapCollection().GetSportData("soccer", New TData)
		'create 4 leagues (if not overridden)
		Local leagueCount:Int = soccerConfig.GetInt("leagueCount", 4)

		CreateLeagues( leagueCount )

		For Local i:Int = 1 To leagueCount
			Local l:TNewsEventSportLeague_Soccer = TNewsEventSportLeague_Soccer(GetLeagueAtIndex(i-1))
			l.name = soccerConfig.GetData("league"+i).GetString("name", i+". Liga")
			l.nameShort = soccerConfig.GetData("league"+i).GetString("nameShort", i+". L")
		Next
	End Method


	Function CreateMatch:TNewsEventSportMatch_Soccer()
		Return New TNewsEventSportMatch_Soccer
	End Function


	Method CreateTeam:TNewsEventSportTeam(prefix:String="", cityName:String="", teamName:String="", teamNameInitials:String="")
		If Not prefix Then prefix = teamPrefixes[RandRange(0, teamPrefixes.length-1)]

		Local team:TNewsEventSportTeam = New TNewsEventSportTeam
		Local teamPrefix:String[] = prefix.Split("|")


		If cityName 
			team.city = cityName
		Else
			'fall back to teamname if someone forgot to define a city
			team.city = teamName
		EndIf
		If teamName
			team.name = teamName
		Else
			team.name = team.city
		EndIf

		Local capitalLetters:String = teamNameInitials
		If capitalLetters = ""
			'method 1 - only capital letters
			Rem
			For local ch:int = EachIn teamNames[i]
				if (ch>=Asc("A") And ch<=Asc("Z")) then capitalLetters :+ Chr(ch)
			Next
			endrem
			'method 2 - name-parts ("Bad |Klein|grunda" = "BKG")
			For Local part:String = EachIn team.name.split("|")
				If Not part Then Continue 'happens for second part in "bla|"
				capitalLetters :+ Chr(StringHelper.UCFirst(part)[0])
			Next
		EndIf

		team.nameInitials = capitalLetters
		'clean potential "splitters" (now we created "capital letters")
		team.city = team.city.Replace("|","")
		team.name = team.name.Replace("|","")

		team.clubName = teamPrefix[0]
		team.clubNameInitials = teamPrefix[1]
		If teamPrefix.length < 3 Or teamPrefix[2] = "s" 
			team.clubNameSingular = True
		Else
			team.clubNameSingular = False
		EndIf

		Return team
	End Method


	Method CreateLeagues(leagueCount:Int)
		'select and fill teams
		Local allUsedCityNames:String[]
		Local countryCodes:String[] = GetPersonGenerator().GetCountryCodes()
		Local emptyData:TData = New TData
		Local predefinedSportData:TData = GetStationMapCollection().GetSportData("soccer", emptyData)
'print predefinedSportData.ToString()
		
		For Local leagueIndex:Int = 0 Until leagueCount
			Local cityNames:String[]
			Local predefinedLeagueData:TData = predefinedSportData.GetData("league"+(leagueIndex+1), emptyData)

			For Local i:Int = 0 Until teamsPerLeague
				Local cityName:String
				'skip random name generation, if a team is defined already
				Local predefinedTeamData:TData = predefinedLeagueData.GetData("team"+(i+1), emptyData)
				cityName = predefinedTeamData.GetString("name")
				

				If cityName = ""
					Local tries:Int = 0
					Repeat
						cityName = GetStationMapCollection().GenerateCity("|") 'split parts
						tries :+ 1
					Until Not StringHelper.InArray(cityName, allUsedCityNames) Or tries > 1000
					If tries > 1000 Then cityName = "unknown-"+MilliSecs()+"-" + RandRange(0,100000)
				EndIf
				cityNames :+ [cityName]
				allUsedCityNames :+ [cityName]
			Next


			local teams:TNewsEventSportTeam[] = New TNewsEventSportTeam[ cityNames.length ]
			For local i:int = 0 until cityNames.length
				'use predefined data if possible
				Local predefinedTeamData:TData = predefinedLeagueData.GetData("team"+(i+1), emptyData)

				Local team:TNewsEventSportTeam
				team = CreateTeam(predefinedTeamData.GetString("prefix", ""), ..
				                  predefinedTeamData.GetString("city", cityNames[i]), ..
				                  predefinedTeamData.GetString("name", ""), ..
				                  predefinedTeamData.GetString("nameInitials", "") ..
				                 )
				'give them some basic attributes
				team.RandomizeBasicStats(leagueIndex)
				'tell the team what sport it is doing
				team.AssignSport(self.GetID())

'print "league="+(leagueIndex+1)+"  team="+(i+1)+"  name=" + team.name+"  city="+team.city+"  nameInitials="+team.nameInitials+"  clubName="+team.clubName+"  clubNameInitials="+team.clubNameInitials

				For Local j:Int = 0 To (11+3) '0 is trainer, 3 is reserve
					Local cCode:String = "de"
					If RandRange(0, 10) < 3 Then cCode = countryCodes[ RandRange(0, countryCodes.length-1) ]

					Local p:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(cCode, TPersonGenerator.GENDER_MALE)
					Local member:TPersonBase = New TPersonBase( p.firstName, p.lastName, p.countryCode, p.gender, True)
					'assume 50% are not interested in TV shows / custom productions
					If RandRange(0, 100) < 50
						member.SetFlag(TVTPersonFlag.CASTABLE, False)
					EndIf
					'give the person sports specific data (team assignment is done separately)
					member.AddData("sports_" + self.name, New TPersonSportBaseData)

					If j <> 0
						team.AddMember( member )
					Else
						team.SetTrainer( member )
					EndIf
				Next
				teams[i] = team
			Next
			GetNewsEventSportCollection().AddTeams( teams )
			

			Local league:TNewsEventSportLeague_Soccer = New TNewsEventSportLeague_Soccer
			league.Init((leagueIndex+1) + ". " + GetLocale("SOCCER_LEAGUE"), leagueIndex+".", teams)
			league.matchesPerTimeSlot = 2
			If leagueIndex = 0
				league.timeSlots = [ ..
				                    "0_16", "0_20", ..
				                    "2_16", "2_20", ..
				                    "4_16", "4_20", ..
				                    "5_16", "5_20" ..
				                   ]
				league.seasonStartDay = 14
				league.seasonStartMonth = 8
			ElseIf leagueIndex > 0
				league.timeSlots = [ ..
				                    "0_14", "0_18", ..
				                    "2_14", "2_18", ..
				                    "4_14", "4_18", ..
				                    "5_14", "5_18" ..
				                   ]
				league.seasonStartDay = 29
				league.seasonStartMonth = 7
			EndIf

			AddLeague( league )
		Next
	End Method

	Method GenerateRandomTeamMembers:Int(team:TNewsEventSportTeam) override
		GenerateRandomTeamMembers(team, 11, 3)
	End Method
End Type



Type TNewsEventSportLeague_Soccer Extends TNewsEventSportLeague
	Method New()
		seasonStartMonth = 8
		seasonStartDay = 14
		matchesPerTimeSlot = 2
	End Method


	Method Custom_CreateUpcomingMatches:Int()
		TNewsEventSport_Soccer.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_Soccer.CreateMatch)
	End Method


	Method GetSeasonStartTime:Long(time:Long)
		'take year of the given time and use the defined months for a
		'soccer season
		'match time: 14. 8. - 14.5. (1. Liga)
		'match time: 29. 7. -       (3. Liga)
		Local thisYear:Long = GetWorldTime().GetTimeGoneForRealDate(GetWorldTime().GetYear(time), seasonStartMonth, seasonStartDay)
		If thisYear < time 
			Return thisYear + GetWorldTime().GetYearLength()
		Else
			Return thisYear
		EndIf
	End Method


	'override
	'2 matches per "time slot" instead of 1
	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Long = 0, isPlayoffSeason:Int=0)
		'time = GetNextMatchStartTime(time)

		If Not season Then season = GetCurrentSeason()

		Local matches:Int = 1
		For Local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			m.SetMatchTime(time)
'			if GetWorldTime().GetTimeGone() < time
'				print "   "+ name+ "  match: "+GetWorldTime().GetFormattedDate(m.matchTime) + "  gameday="+ (GetWorldTime().GetDaysRun(m.matchTime)+1) + "  " + m.GetNameShort()
'			endif

			'every x-th match we increase time - so matches get "grouped"
			If isPlayoffSeason Or (matches > 1 And matches Mod matchesPerTimeSlot = 0)
				'also append some minutes, es we would not move forward
				'without (same time returned again and again)
				'print "      get next time"
				time = GetNextMatchStartTime(time + 10 * 60)
			EndIf

			matches :+1
		Next
	End Method
End Type




Type TNewsEventSportMatch_Soccer Extends TNewsEventSportMatch
	Function CreateMatch:TNewsEventSportMatch_Soccer()
		Return New TNewsEventSportMatch_Soccer
	End Function


	Method GetReport:String() override
		Local matchText:String = GetLocale("SPORT_TEAMREPORT_MATCHRESULT")

		'make first char uppercase
		matchText = StringHelper.UCFirst( matchText )
		Return matchText
	End Method


	Method GetLiveReportShort:String(mode:String="", time:Long=-1) override
		Local matchTime:Int = GetMatchTimeGone(time)
		
		Local usePoints:Int[] = GetMatchScore(matchTime)
		Local result:String

		For Local i:Int = 0 Until usePoints.length
			If result <> ""
				result :+ " : "
				If mode = "INITIALS"
					result :+ usePoints[i] + "] " + teams[i].GetTeamInitials()
				Else
					result :+ usePoints[i] + "] " + teams[i].GetTeamNameShort()
				EndIf
			Else
				If mode = "INITIALS"
					result :+ teams[i].GetTeamInitials() + " [" + usePoints[i]
				Else
					result :+ teams[i].GetTeamNameShort() + " [" + usePoints[i]
				EndIf
			EndIf
		Next
		Return result
	End Method
	

	Method GetReportShort:String(mode:String="") override
		Local result:String

		For Local i:Int = 0 Until points.length
			If result <> ""
				result :+ " : "
				If mode = "INITIALS"
					result :+ points[i] + "] " + teams[i].GetTeamInitials()
				Else
					result :+ points[i] + "] " + teams[i].GetTeamNameShort()
				EndIf
			Else
				If mode = "INITIALS"
					result :+ teams[i].GetTeamInitials() + " [" + points[i]
				Else
					result :+ teams[i].GetTeamNameShort() + " [" + points[i]
				EndIf
			EndIf
		Next
		Return result

		'return teams[0].nameInitials + " " + points[0]+" : " + points[1] + " " + teams[1].nameInitials
	End Method


	Method GetFinalScoreText:String()
		'only show halftime points if someone scored something
		Local showHalfTimePoints:Int = False
		For Local i:Int = 0 Until points.length
			If points[i] <> 0 Then showHalfTimePoints = True
		Next

		If showHalfTimePoints
			Return Super.GetFinalScoreText()+" (" + StringHelper.IntArrayToString(GetMatchScore(duration/2), ":") + ")"
		Else
			Return Super.GetFinalScoreText()
		EndIf
	End Method
	
End Type
