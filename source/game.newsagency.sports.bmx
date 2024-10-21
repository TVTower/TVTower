SuperStrict
Import "game.world.worldtime.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.helper.bmx"
Import "game.person.base.bmx"
Import "game.gameeventkeys.bmx"




Type TNewsEventSportCollection Extends TGameObjectCollection
	Field leagues:TMap = New TMap
	Field matches:TMap = New TMap
	Global _instance:TNewsEventSportCollection


	Function GetInstance:TNewsEventSportCollection()
		If Not _instance Then _instance = New TNewsEventSportCollection
		Return _instance
	End Function


	Method Initialize:TNewsEventSportCollection()
		Super.Initialize()

		Return Self
	End Method


	Method GetByGUID:TNewsEventSport(GUID:String)
		Return TNewsEventSport( Super.GetByGUID(GUID) )
	End Method


	Method AddLeague(league:TNewsEventSportLeague)
		leagues.Insert(league.GetGUID(), league)
	End Method


	Method GetLeagueByGUID:TNewsEventSportLeague(guid:String)
		Return TNewsEventSportLeague( leagues.ValueForKey(guid) )
	End Method


	Method AddMatch(match:TNewsEventSportMatch)
		matches.Insert(match.GetGUID(), match)
	End Method


	Method GetMatchByGUID:TNewsEventSportMatch(guid:String)
		Return TNewsEventSportMatch( matches.ValueForKey(guid) )
	End Method


	Method InitializeAll:Int()
		if leagues then leagues.clear()
		if matches then matches.clear()

		For Local sport:TNewsEventSport = EachIn entries.Values()
			sport.Initialize()
		Next
	End Method


	Method CreateAllLeagues:Int()
		For Local sport:TNewsEventSport = EachIn entries.Values()
			sport.CreateDefaultLeagues()
		Next
	End Method


	Method UpdateAll:Int()
		For Local sport:TNewsEventSport = EachIn entries.Values()
			sport.Update()
			Rem
			local nextMatchTime:Long = sport.GetNextMatchTime()
			if nextMatchTime <> -1
				print "sport: "+sport.name+"  nextMatch at " + (GetWorldTime().GetDaysRun(nextMatchTime)+1)+"/"+GetWorldTime().GetFormattedTime(nextMatchTime)
			else
				print "sport: "+sport.name+"  NO next match"
			endif
			endrem
		Next
	End Method


	Method StartAll:Int( time:Long = -1 )
		If time = -1 Then time = GetWorldTime().GetTimeGone()

		For Local sport:TNewsEventSport = EachIn entries.Values()
			sport.StartSeason(time)
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetNewsEventSportCollection:TNewsEventSportCollection()
	Return TNewsEventSportCollection.GetInstance()
End Function




Type TNewsEventSport Extends TGameObject
	'the league of the sport
	Field leagues:TNewsEventSportLeague[]
	'0 = unknown, 1 = running, 2 = finished
	Field playoffsState:Int = 0
	'for each league-to-league connection we create a fake season
	'for the playoffs
	Field playoffSeasons:TNewsEventSportSeason[]
	Field playOffStartTime:Long
	Field playOffEndTime:Long
	Field name:String = "unknown"


	Method GenerateGUID:String()
		Return "NewsEventSport-"+id
	End Method


	Method Initialize:TNewsEventSport()
		'For local l:TNewsEventSportLeague = EachIn leagues
		'	l.Initialize()
		'Next
		leagues = leagues[..0]
		playoffsState = 0
		playoffSeasons = playoffSeasons[..0]
		playOffStartTime = 0
		playOffEndTime = 0

		Return Self
	End Method


	Method CreateDefaultLeagues:Int()
		Print "override in custom sport"
	End Method


	'updates all leagues of this sport
	Method Update:Int()
		'=== regular league matches ===
		For Local l:TNewsEventSportLeague = EachIn leagues
			l.Update()
		Next
		If IsSeasonFinished() And playoffsState = 0
			CreatePlayoffSeasons()
			'delay by at least 1 day
			AssignPlayoffTimes(GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH)

			StartPlayoffs()

			?debug
			For Local season:TNewsEventSportSeason = EachIn playoffSeasons
				Print name+":  playoff matches: " + GetWorldTime().GetFormattedGameDate(season.GetNextMatchTime()) + "   -   " + GetWorldTime().GetFormattedGameDate(season.GetLastMatchEndTime())
			Next
			?
		EndIf

		'=== playoff matches ===
		If playoffsState = 1
			If Not UpdatePlayoffs()
				'move loosing teams one lower, winners one higher
				FinishPlayoffs()
			EndIf
		EndIf

		'start next season if needed
		If ReadyForNextSeason() Then StartSeason()
	End Method


	Method UpdatePlayoffs:Int()
		Local matchesRun:Int = 0
		Local matchesToCome:Int = 0

		Local leagueNumber:Int = 0
		For Local season:TNewsEventSportSeason = EachIn playoffSeasons
			leagueNumber :+ 1
			If Not season.upcomingMatches Then Continue

			For Local nextMatch:TNewsEventSportMatch = EachIn season.upcomingMatches
				If nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					season.updateTime = nextMatch.GetMatchTime()

					'invalidate table
					season.InvalidateLeaderboard()

					season.upcomingMatches.Remove(nextMatch)
					nextMatch.Run()
					season.doneMatches.AddLast(nextMatch)

					TriggerBaseEvent(GameEventKeys.Sport_Playoffs_RunMatch, New TData.AddLong("matchTime", nextMatch.GetMatchTime()).Add("match", nextMatch).Add("season", season).AddInt("leagueIndex", leagueNumber -1), Self)

					matchesRun :+ 1
				'else
				'	print "now: " + GetWorldTime().GetFormattedDate()+"  match: " + GetWorldTime().GetFormattedDate( nextMatch.GetMatchTime())
				EndIf
			Next

			matchesToCome :+ season.upcomingMatches.Count()
		Next

		'finish playoffs?
		If matchesToCome = 0 Then Return False

		Return True
	End Method


	Method StartPlayoffs()
		For Local season:TNewsEventSportSeason = EachIn playoffSeasons
			season.Start( GetWorldTime().GetTimeGone() )
		Next

		playoffsState = 1

		TriggerBaseEvent(GameEventKeys.Sport_StartPlayoffs, New TData.AddLong("time", GetWorldTime().GetTimeGone()), Self)
	End Method


	Method FinishPlayoffs()
		For Local season:TNewsEventSportSeason = EachIn playoffSeasons
			season.Finish( GetWorldTime().GetTimeGone() )
		Next

		Local leagueWinners:TNewsEventSportTeam[leagues.length]
		Local leagueLoosers:TNewsEventSportTeam[leagues.length]
		Local playoffWinners:TNewsEventSportTeam[leagues.length]

		'move the last of #1 one down
		'move the first of #2 one up
		For Local i:Int = 0 Until leagues.length-1
			Local looser:TNewsEventSportTeam = leagues[i].GetCurrentSeason().GetTeamAtRank( -1 )
			Local winner:TNewsEventSportTeam = leagues[i+1].GetCurrentSeason().GetTeamAtRank( 1 )

			leagues[i].ReplaceNextSeasonTeam(looser, winner)
			leagues[i+1].ReplaceNextSeasonTeam(winner, looser)
			'print "Liga: "+(i+1)+"->"+(i+2)
			'print "  abstieg: "+looser.name
			'print "  aufstieg: "+winner.name
		Next

		'set winner of relegation to #1
		'set looser of relegation to #2
		For Local i:Int = 0 Until playoffSeasons.length -1
			'i=0 => playoff between league 0 and league 1
			Local looser:TNewsEventSportTeam = playoffSeasons[i].GetTeamAtRank( -1 )
			Local winner:TNewsEventSportTeam = playoffSeasons[i].GetTeamAtRank( 1 )

			Local winnerMovesUp:Int = leagues[i].GetNextSeasonTeamIndex(winner) = -1
			Local looserMovesDown:Int = leagues[i+1].GetNextSeasonTeamIndex(looser) = -1

			?debug
			Local in1:String, in2:String
			For Local t:TNewsEventSportLeagueRank = EachIn leagues[i].GetCurrentSeason().data.GetLeaderboard()
				in1 :+ t.team.name+" / "
			Next
			For Local t:TNewsEventSportLeagueRank = EachIn leagues[i+1].GetCurrentSeason().data.GetLeaderboard()
				in2 :+ t.team.name+" / "
			Next

			Print "Relegation: "+(i+1)+"->"+(i+2)
			Print "  in "+(i+1)+": " + in1
			Print "  in "+(i+2)+": " + in2
			If winnerMovesUp
				Print "  abstieg: "+looser.name
				Print "  aufstieg: "+winner.name
			Else
				Print "  bleibt in "+i+": "+winner.name
				Print "  bleibt in "+(i+1)+": "+looser.name
			EndIf
			?

			'only switch teams if possible for both leagues
			'else you would add a team to two leagues
			If winnerMovesUp 'and looserMovesDown
				If leagues[i].ReplaceNextSeasonTeam(looser, winner)
					'print "league " + i+": replaced "+looser.name+" with " + winner.name
					If Not leagues[i+1].ReplaceNextSeasonTeam(winner, looser)
						'print "could not replace next season team in league"+(i+1)
					EndIf
				Else
					'print "could not replace next season team in league"+i

				EndIf
			EndIf

'			print "EVENT fuer Playoffs losschicken, Gewinner/Verlierer nur wenn Ligawechsel"
		Next

		playoffsState = 2

		TriggerBaseEvent(GameEventKeys.Sport_FinishPlayoffs, New TData.AddLong("time", GetWorldTime().GetTimeGone()), Self)
	End Method


	Method CreatePlayoffSeasons()
		'we need leagues-1 seasons (1->2, 2->3, loosers of league 3 stay)
		playoffSeasons = New TNewsEventSportSeason[ leagues.length - 1 ]
		playOffStartTime = GetWorldTime().GetTimeGone()
		For Local i:Int = 0 To playoffSeasons.length -1
			playoffSeasons[i] = New TNewsEventSportSeason.Init("", Self.GetGUID())
			'mark as playoff season
			playoffSeasons[i].seasonType = TNewsEventSportSeason.SEASONTYPE_PLAYOFF

			'add second to last of first league
			playoffSeasons[i].AddTeam( leagues[i].GetCurrentSeason().GetTeamAtRank( -2 ) )
			'add second placed team of next league
			playoffSeasons[i].AddTeam( leagues[i+1].GetCurrentSeason().GetTeamAtRank( 2 ) )
'print "playoff #"+i+"  add from loosers in league "+i+": "+ leagues[i].GetCurrentSeason().GetTeamAtRank( -2 ).name
'print "playoff #"+i+"  add from winners in league "+(i+1)+": "+ leagues[i+1].GetCurrentSeason().GetTeamAtRank( 2 ).name

			playoffSeasons[i].data.matchPlan = New TNewsEventSportMatch[playoffSeasons[i].GetMatchCount()]

			CreateMatchSets(playoffSeasons[i].GetMatchCount(), playoffSeasons[i].GetTeams(), playoffSeasons[i].data.matchPlan, CreateMatch)

			For Local match:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
'print "playoff #"+i+"  match: " + match.teams[0].name + " - " + match.teams[1].name
				playoffSeasons[i].upcomingMatches.addLast(match)

				GetNewsEventSportCollection().AddMatch(match)
			Next
		Next
	End Method


	Method AssignPlayoffTimes(time:Long = 0)
		Local allPlayOffsTime:Long = time

		'playoff times use the "upper leagues" starting times
		Local matches:Int = 0
		For Local i:Int = 0 Until playoffSeasons.length
			'reset time so all playoff-"seasons" start at the same time
			time = allPlayOffsTime
			'if time = 0 then time = leagues[i].GetNextMatchStartTime(time, True)

			Local playoffsTime:Long = leagues[i].GetNextMatchStartTime(time, True)
			leagues[i].AssignMatchTimes(playoffSeasons[i], playoffsTime, True)

			?debug
				Print " Create matches: League "+(i+1)+"->"+(i+2)
				Local mIndex:Int = 0
				For Local m:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
					mIndex :+1
					Print "  match #"+RSet(mIndex,2).Replace(" ", "0")+": "+ m.teams[0].nameInitials+"-"+m.teams[1].nameInitials
				Next
			?
		Next
	End Method


	Method StartSeason:Int(time:Long = 0)
		?debug
			Print "Start Season: " + TTypeId.ForObject(Self).Name()+"   time "+GetWorldTime().GetFormattedDate(time)
		?

		If time = 0 Then time = GetWorldTime().GetTimeGone()

		For Local l:TNewsEventSportLeague = EachIn leagues
			l.StartSeason(time)
			?debug
				Print name+":  season matches: " + GetWorldTime().GetFormattedGameDate(l.GetNextMatchTime()) + "   -   " + GetWorldTime().GetFormattedGameDate(l.GetLastMatchEndTime())
			?
		Next

		TriggerBaseEvent(GameEventKeys.Sport_StartSeason, New TData.AddLong("time", time), Self)
	End Method


	Method FinishSeason()
		?debug
			Print "Finish Season: " + TTypeId.ForObject(Self).Name()
		?

		For Local l:TNewsEventSportLeague = EachIn leagues
			l.FinishSeason()
		Next
		TriggerBaseEvent(GameEventKeys.Sport_FinishSeason, Null, Self)
	End Method


	Method ReadyForNextSeason:Int()
		Return IsSeasonFinished() And ArePlayoffsFinished()
	End Method


	Method IsSeasonStarted:Int()
		For Local l:TNewsEventSportLeague = EachIn leagues
			If Not l.IsSeasonStarted() Then Return False
		Next
		Return True
	End Method


	Method IsSeasonFinished:Int()
		For Local l:TNewsEventSportLeague = EachIn leagues
			If Not l.IsSeasonFinished() Then Return False
		Next
		Return True
	End Method


	Method ArePlayoffsRunning:Int()
		Return playoffsState = 1
	End Method


	Method ArePlayoffsFinished:Int()
		Return playoffsState = 2
	End Method


	Method AddLeague:TNewsEventSport(league:TNewsEventSportLeague)
		leagues :+ [league]
		league.sportGUID = Self.GetGUID()
		league._leaguesIndex = leagues.length-1

		GetNewsEventSportCollection().AddLeague(league)

		TriggerBaseEvent(GameEventKeys.Sport_AddLeague, New TData.add("league", league), Self)
	End Method


	Method ContainsLeague:Int(league:TNewsEventSportLeague)
		For Local l:TNewsEventSportLeague = EachIn leagues
			If l = league Then Return True
		Next
		Return False
	End Method


	Method GetLeagueAtIndex:TNewsEventSportLeague(index:Int)
		If index < 0 Or index >= leagues.length Then Return Null
		Return leagues[index]
	End Method


	Method GetLeagueByGUID:TNewsEventSportLeague(leagueGUID:String)
		For Local l:TNewsEventSportLeague = EachIn leagues
			If l.GetGUID() = leagueGUID Then Return l
		Next
		Return Null
	End Method


	Method GetMatchNameShort:String(match:TNewsEventSportMatch)
		Return match.GetNameShort()
	End Method


	Method GetMatchReport:String(match:TNewsEventSportMatch)
		Return match.GetReport()
	End Method


	Method GetNextMatchTime:Long()
		Local lowestTime:Long = -1
		For Local league:TNewsEventSportLeague = EachIn leagues
			Local lowestLeagueMatchTime:Long = league.GetNextMatchTime()
			If lowestTime = -1 Or lowestLeagueMatchTime < lowestTime
				lowestTime = lowestLeagueMatchTime
			EndIf
		Next
		Return lowestTime
	End Method


	Method GetFirstMatchTime:Long()
		Local lowestTime:Long = -1
		For Local league:TNewsEventSportLeague = EachIn leagues
			Local lowestLeagueMatchTime:Long = league.GetFirstMatchTime()
			If lowestTime = -1 Or lowestLeagueMatchTime < lowestTime
				lowestTime = lowestLeagueMatchTime
			EndIf
		Next
		Return lowestTime
	End Method


	Method GetLastMatchTime:Long()
		Local latestTime:Long = -1
		For Local league:TNewsEventSportLeague = EachIn leagues
			Local latestLeagueMatchTime:Long = league.GetLastMatchTime()
			If latestTime = -1 Or latestLeagueMatchTime > latestTime
				latestTime = latestLeagueMatchTime
			EndIf
		Next
		Return latestTime
	End Method


	Method GetLastMatchEndTime:Long()
		Local latestTime:Long = -1
		For Local league:TNewsEventSportLeague = EachIn leagues
			Local latestLeagueMatchEndTime:Long = league.GetLastMatchEndTime()
			If latestTime = -1 Or latestLeagueMatchEndTime > latestTime
				latestTime = latestLeagueMatchEndTime
			EndIf
		Next
		Return latestTime
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		Local result:TNewsEventSportMatch[]
		For Local l:TNewsEventSportLeague = EachIn leagues
			result :+ l.GetUpcomingMatches(minTime, maxTime)
		Next

		Return result
	End Method


	Method GetUpcomingPlayoffMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		Local result:TNewsEventSportMatch[]
		For Local l:TNewsEventSportSeason = EachIn playoffSeasons
			result :+ l.GetUpcomingMatches(minTime, maxTime)
		Next

		Return result
	End Method


	'helper: creates a "round robin"-matchset (all vs all)
	Function CreateMatchSets(matchCount:Int, teams:TNewsEventSportTeam[], matchPlan:TNewsEventSportMatch[], createMatchFunc:TNewsEventSportMatch())
		If Not createMatchFunc Then createMatchFunc = CreateMatch

		Local useTeams:TNewsEventSportTeam[] = teams[ .. teams.length]
		Local useTeamIndices:Int[] = New Int[teams.length]
		Local ghostTeam:TNewsEventSportTeam
		'if odd we add a ghost team
		If teams.length Mod 2 = 1
			ghostTeam = New TNewsEventSportTeam
			useTeams :+ [ghostTeam]
		EndIf

		For Local i:Int = 0 Until useTeams.length
			useTeamIndices[i] = i
		Next

		?debug
			Print "CreateMatchSets:"
			Print "  teams: "+teams.length
			Print "  useTeams: "+useTeams.length
			Print "  matchCount: "+matchCount
			For Local i:Int = 0 Until useTeams.length
				useTeams[i].nameInitials = i
				If useTeams[i] = ghostTeam Then useTeams[i].nameInitials = "G"
			Next
		?

		Local teamAIndices:Int[matchCount]
		Local teamBIndices:Int[matchCount]
		Local matchNumber:Int = 0


		'approach described here: http://spvgkade.de/ssonst/ssa0.html?haupt=Son&sub=PaT&sub=Root
		'results in: 1-4, 3-2   4-3, 2-1   2-4, 1-3
		For Local roundNumber:Int = 1 To useTeams.length-1
			For Local roundMatchNumber:Int = 1 To useTeams.length/2
				matchNumber :+ 1

				Local GR:Int = roundNumber Mod 2 = 0
				Local UR:Int = roundNumber Mod 2 = 1
				Local team1Index:Int
				Local team2Index:Int

				If roundNumber Mod 2 = 0
					If roundMatchNumber = 1
						team1Index = useTeams.length - roundMatchNumber + 1
						team2Index = (useTeams.length + roundNumber)/2 - roundMatchNumber + 1
					Else
						team1Index = (useTeams.length + roundNumber)/2 + roundMatchNumber - useTeams.length
						team2Index = (useTeams.length + roundNumber)/2 - roundMatchNumber + 1
						If team1Index < 1 Then team1Index = team1Index + (useTeams.length-1)
					EndIf
				Else
					If roundMatchNumber=1
						team1Index = (1 + roundNumber)/2 + roundMatchNumber - 1
						team2Index = useTeams.length + roundMatchNumber - 1
					Else
						team1Index = (1 + roundNumber)/2 + roundMatchNumber - 1
						team2Index = (1 + roundNumber)/2 - roundMatchNumber + useTeams.length
						If team2Index > (useTeams.length-1) Then team2Index = team2Index - (useTeams.length-1)
					EndIf
				EndIf

				'swap home/away
				If roundMatchNumber Mod 2 = 0
					Local tmp:Int = team1Index
					team1Index = team2Index
					team2Index = tmp
				EndIf

				'home
				teamAIndices[ matchNumber-1 ] = team1Index-1
				teamBIndices[ matchNumber-1 ] = team2Index-1
				'away
				teamAIndices[ matchNumber-1 + matchCount/2 ] = team2Index-1
				teamBIndices[ matchNumber-1 + matchCount/2 ] = team1Index-1

				'print roundNumber+"/"+matchNumber+": " + team1Index + " - " + team2Index
			Next
		Next


		Rem
		'based on the description (which took it from the "championship
		'manager forum") at:
		'http://www.blitzmax.com/Community/post.php?topic=51796&post=578319
		matchNumber = 0
		'loop over all teams (fight versus all other teams)
		For local opponentNumber:int = 1 to useTeams.length - 1
			'we have to shift around all entries except the first one
			'so "first team" is always the same, all others shift their
			'position one step to the right on each loop
			'1) 1 2 3 4
			'2) 1 4 2 3
			'3) 1 3 4 2
			if opponentNumber > 1
				useTeams = useTeams[.. 1] + useTeams[useTeams.length-1 ..] + useTeams[1 .. useTeams.length -1]
				useTeamIndices = useTeamIndices[.. 1] + useTeamIndices[useTeamIndices.length-1 ..] + useTeamIndices[1 .. useTeamIndices.length -1]
			endif

			?debug
			local shifted:string = ""
			for local j:int = 0 until useTeams.length
				if shifted<>"" then shifted :+ " "
				shifted :+ useTeamIndices[j]
			next
			print "shifted: "+shifted
			?

'			'setup: 1st vs last, 2nd vs last-1, 3rd vs last-2 ...
			'skip match when playing vs the dummy/ghost team
			For local teamOffset:int = 0 until ceil(useTeams.length/2)
				matchNumber :+ 1

				local team1Index:int = useTeamIndices[ 0 + teamOffset ]
				local team2Index:int = useTeamIndices[ useTeams.length-1 - teamOffset ]
				'skip matches with the ghost team
				if useTeams[team1Index] = ghostTeam or useTeams[team2Index] = ghostTeam then continue

				'swap home/away
				if teamOffset mod 2 = 0
					local tmp:int = team1Index
					team1Index = team2Index
					team2Index = tmp
				endif

				teamAIndices[ matchNumber-1 ] = team1Index
				teamBIndices[ matchNumber-1 ] = team2Index

				teamAIndices[ matchNumber-1 + matchCount/2 ] = team2Index
				teamBIndices[ matchNumber-1 + matchCount/2 ] = team1Index
			Next
		Next
		endrem

		For Local matchIndex:Int = 0 Until teamAIndices.length
			Local teamA:TNewsEventSportTeam = useTeams[ teamAIndices[matchIndex] ]
			Local teamB:TNewsEventSportTeam = useTeams[ teamBIndices[matchIndex] ]

			'skip matches with the ghost team
			If teamA = ghostTeam Or teamB = ghostTeam Then Continue

			Local match:TNewsEventSportMatch = createMatchFunc()
			match.matchNumber = matchIndex
			match.AddTeams( [teamA, teamB] )

			matchPlan[matchIndex] = match
			'print (teamA.nameInitials)+"-"+(teamB.nameInitials) + "  " + (teamAIndices[matchIndex]+1) +"-"+(teamBIndices[matchIndex]+1)
		Next

		?debug
		Print " Create matches"
		Local mIndex:Int = 0
		For Local m:TNewsEventSportMatch = EachIn matchPlan
			mIndex :+1
			Print "  match #"+RSet(mIndex,2).Replace(" ", "0")+": "+ m.teams[0].nameInitials+"-"+m.teams[1].nameInitials
		Next
		?
	End Function


	Method GetMatchByGUID:TNewsEventSportMatch(guid:String)
	End Method


	Function CreateMatch:TNewsEventSportMatch()
		Return New TNewsEventSportMatch
	End Function
End Type



'data collection for individual seasons
Type TNewsEventSportSeasonData
	'=== regular season data ===
	Field startTime:Long
	Field endTime:Long
	'contains all matches in their _logical_ order (ignoring matchTime)
	Field matchPlan:TNewsEventSportMatch[]
	Field teams:TNewsEventSportTeam[]

	'cache
	Field _leaderboard:TNewsEventSportLeagueRank[] {nosave}
	Field _leaderboardMatchTime:Long = -1 {nosave}

	'=== playoffs data ===
	'store who moved up a league, and who moved down
	'-- not used up to now, move that into a special type
	'   for playoff seasons?
	'Field playoffLosers:TNewsEventSportTeam[]
	'Field playoffWinners:TNewsEventSportTeam[]
	'Field playoffMatchPlan:TNewsEventSportMatch[]



	Method InvalidateLeaderboard:Int()
		_leaderboard = New TNewsEventSportLeagueRank[0]
	End Method


	Method SetTeams:Int(teams:TNewsEventSportTeam[])
		'create reference to the array!
		'(modification to original modifies here too)
		'Maybe we should copy it?
		Self.teams = teams
		Return True
	End Method


	Method AddTeam:Int(team:TNewsEventSportTeam)
		teams :+ [team]
		Return True
	End Method


	Method GetTeams:TNewsEventSportTeam[]()
		Return teams
	End Method


	Method GetTeamIndex:Int(team:TNewsEventSportTeam)
		For Local i:Int = 0 Until teams.length
			If teams[i] = team Then Return i
		Next
		Return -1
	End Method


	Method GetTeamRank:Int(team:TNewsEventSportTeam, upToMatchTime:Long = 0)
		Local board:TNewsEventSportLeagueRank[] = GetLeaderboard(upToMatchTime)
		For Local rankIndex:Int = 0 Until board.length
			If board[rankIndex].team = team Then Return rankIndex + 1
		Next
		Return -1
	End Method


	Method GetTeamAtRank:TNewsEventSportTeam(rank:Int, upToMatchTime:Long = 0)
		Local board:TNewsEventSportLeagueRank[] = GetLeaderboard(upToMatchTime)
		If rank < 0
			Return board[ board.length + rank ].team
		Else
			Return board[ rank - 1 ].team
		EndIf
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchTime:Long = 0)
		'return cache if possible
		If _leaderboard And _leaderboard.length = teams.length
			If upToMatchTime <> 0 Or upToMatchTime = _leaderboardMatchTime
				Return _leaderboard
			EndIf
		EndIf

		_leaderboard = New TNewsEventSportLeagueRank[teams.length]
		_leaderboardMatchTime = upToMatchTime

		'sum up the scores of each team in the matches
		For Local match:TNewsEventSportMatch = EachIn matchPlan
			'create entries for all teams
			'ignore whether they played already or not
			For Local team:TNewsEventSportTeam = EachIn match.teams
				Local teamIndex:Int = GetTeamIndex(team)
				'team not in the league?
				If teamIndex = -1 Then Continue

				If Not _leaderboard[teamIndex]
					_leaderboard[teamIndex] = New TNewsEventSportLeagueRank
					_leaderboard[teamIndex].team = team
				EndIf
			Next

			'add scores

			'check if it is run somewhen in the past
			If Not match.IsRun() Then Continue
			'upToMatchTime = 0 means, no limit on match time
			If upToMatchTime <> 0 And match.GetMatchTime() > upToMatchTime Then Continue

			For Local team:TNewsEventSportTeam = EachIn match.teams
				Local teamIndex:Int = GetTeamIndex(team)
				'team not in the league?
				If teamIndex = -1 Then Continue

				_leaderboard[teamIndex].score :+ match.GetScore(team)
			Next
		Next

		'sort the leaderboard
		If _leaderboard.length > 1 Then _leaderboard.sort(False)
		Return _leaderboard
	End Method
End Type




Type TNewsEventSportSeason Extends TGameObject
	Field data:TNewsEventSportSeasonData = New TNewsEventSportSeasonData
	Field started:Int = False
	Field finished:Int = True
	Field updateTime:Long
	Field part:Int = 0
	Field partMax:Int = 2

	'contains to-come matches ordered according their matchTime
	Field upcomingMatches:TList
	'contains matches already run
	Field doneMatches:TList

	'for playoffs, this is empty
	Field leagueGUID:String
	Field sportGUID:String

	Field seasonType:Int = 1
	Const SEASONTYPE_NORMAL:Int = 1
	Const SEASONTYPE_PLAYOFF:Int = 2


	Method GenerateGUID:String()
		Return "NewsEventSportSeason-"+id
	End Method


	Method Init:TNewsEventSportSeason(leagueGUID:String, sportGUID:String)
		doneMatches = CreateList()
		upcomingMatches = CreateList()

		Self.leagueGUID = leagueGUID
		Self.sportGUID = sportGUID

		Return Self
	End Method


	Method Start(time:Long)
		data.startTime = time
		finished = False
		started = True

		'set all ranks to 0
		For Local team:TNewsEventSportTeam = EachIn data.teams
			team.currentRank = 0
			team.UpdateStats()
		Next

		part = 1
	End Method


	Method Finish(time:Long)
		data.endTime = time
		finished = True
		started = False
		part = 0
	End Method


	Method InvalidateLeaderboard:Int()
		data.InvalidateLeaderboard()
	End Method


	Method SetTeams:Int(teams:TNewsEventSportTeam[])
		Local result:Int = data.SetTeams(teams)

		'inform teams about the league
		For Local team:TNewsEventSportTeam = EachIn data.teams
			team.AssignLeague(leagueGUID)
		Next

		Return result
	End Method


	Method AddTeam:Int(team:TNewsEventSportTeam)
		Return data.AddTeam(team)
	End Method


	Method GetTeams:TNewsEventSportTeam[]()
		Return data.GetTeams()
	End Method


	Method GetTeamAtRank:TNewsEventSportTeam(rank:Int)
		Return data.GetTeamAtRank(rank)
	End Method


	Method GetTeamRank:Int(team:TNewsEventSportTeam, upToMatchTime:Long=0)
		Return data.GetTeamRank(team, upToMatchTime)
	End Method


	Method RefreshTeamStats(upToMatchTime:Long=0)
		RefreshRanks(upToMatchTime)
		For Local t:TNewsEventSportTeam = EachIn data.teams
			t.UpdateStats()
		Next
	End Method


	'assign the ranks of the given time as "current ranks" to the teams
	Method RefreshRanks(upToMatchTime:Long=0)
		Local board:TNewsEventSportLeagueRank[] = data.GetLeaderboard(upToMatchTime)
		For Local rankIndex:Int = 0 Until board.length
			board[rankIndex].team.currentRank = rankIndex+1
		Next
	End Method


	Method GetNextMatchTime:Long()
		Local lowestTime:Long = -1
		For Local nextMatch:TNewsEventSportMatch = EachIn upcomingMatches
			If lowestTime = -1 Or nextMatch.GetMatchTime() < lowestTime
				lowestTime = nextMatch.GetMatchTime()
			EndIf
		Next
		Return lowestTime
	End Method


	Method GetFirstMatchTime:Long()
		Local list:TList = doneMatches
		If list.Count() = 0 Then list = upcomingMatches

		Local lowestTime:Long = -1
		For Local nextMatch:TNewsEventSportMatch = EachIn list
			If lowestTime = -1 Or nextMatch.GetMatchTime() < lowestTime
				lowestTime = nextMatch.GetMatchTime()
			EndIf
		Next
		Return lowestTime
	End Method


	Method GetLastMatchTime:Long()
		Local latestTime:Long = -1
		Local list:TList = upcomingMatches
		If list.Count() = 0 Then list = doneMatches

		For Local nextMatch:TNewsEventSportMatch = EachIn list
			If latestTime = -1 Or nextMatch.GetMatchTime() > latestTime
				latestTime = nextMatch.GetMatchTime()
			EndIf
		Next
		Return latestTime
	End Method


	Method GetLastMatchEndTime:Long()
		Local latestTime:Long = -1
		Local list:TList = upcomingMatches
		If list.Count() = 0 Then list = doneMatches

		For Local nextMatch:TNewsEventSportMatch = EachIn list
			Local endTime:Long = nextMatch.GetMatchEndTime()
			If latestTime = -1 Or endTime > latestTime
				latestTime = endTime
			EndIf
		Next
		Return latestTime
	End Method



	Method GetMatchCount:Int(teamSize:Int = -1)
		If teamSize = -1 Then teamSize = GetTeams().length
		'each team fights all other teams - this means we need
		'(teams * (teamsAmount-1))/2 different matches

		'*2 to get "home" and "guest" matches
		Return 2 * (teamSize * (teamSize-1)) / 2
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		Local result:TNewsEventSportMatch[]
		For Local match:TNewsEventSportMatch = EachIn upcomingMatches
			If match.GetMatchTime() < minTime Then Continue
			If maxTime <> -1 And match.GetMatchTime() > maxTime Then Continue

			result :+ [match]
		Next
		Return result
	End Method
End Type




Type TNewsEventSportLeague Extends TGameObject
	Field name:String
	Field nameShort:String

	'defines when matches take places
	'0 = monday, 2 = wednesday ...
	Field timeSlots:String[] = [ ..
	                            "0_14", "0_20", ..
	                            "2_14", "2_20", ..
	                            "4_14", "4_20", ..
	                            "5_14", "5_20" ..
	                           ]

	Field seasonJustBegun:Int = False
    Field seasonStartMonth:Int = 8
    Field seasonStartDay:Int = 14
	Field matchesPerTimeSlot:Int = 2

	'store all seasons of that league
	Field pastSeasons:TNewsEventSportSeasonData[]
	Field currentSeason:TNewsEventSportSeason
	'teams in then nex season (maybe after relegation matches)
	Field nextSeasonTeams:TNewsEventSportTeam[]

	'guid of the parental sport
	Field sportGUID:String = ""
	'index of this league in the parental sport
	Field _leaguesIndex:Int = 0

	'callbacks
	Field _onRunMatch:Int(league:TNewsEventSportLeague, match:TNewsEventSportMatch) {nosave}
	Field _onStartSeason:Int(league:TNewsEventSportLeague) {nosave}
	Field _onFinishSeason:Int(league:TNewsEventSportLeague) {nosave}
	Field _onFinishSeasonPart:Int(league:TNewsEventSportLeague, part:Int) {nosave}
	Field _onStartSeasonPart:Int(league:TNewsEventSportLeague, part:Int) {nosave}


	Method Init:TNewsEventSportLeague(name:String, nameShort:String, initialSeasonTeams:TNewsEventSportTeam[])
		Self.name = name
		Self.nameShort = nameShort
		Self.nextSeasonTeams = initialSeasonTeams

		Return Self
	End Method


	Method GetNextSeasonTeamIndex:Int(team:TNewsEventSportTeam)
		For Local i:Int = 0 Until nextSeasonTeams.length
			If nextSeasonTeams[i] And nextSeasonTeams[i] = team Then Return i
		Next
		Return -1
	End Method


	Method ReplaceNextSeasonTeam:Int(oldTeam:TNewsEventSportTeam, newTeam:TNewsEventSportTeam)
		Local nextSeasonTeamIndex:Int = GetNextSeasonTeamIndex(oldTeam)
		If nextSeasonTeamIndex >= 0
			nextSeasonTeams[nextSeasonTeamIndex] = newTeam
			Return True
		EndIf
		Return False
	End Method


	Method AddNextSeasonTeam:Int(team:TNewsEventSportTeam)
		If Not team Then Return False
		nextSeasonTeams :+ [team]
		Return True
	End Method


	Method RemoveNextSeasonTeam:Int(team:TNewsEventSportTeam)
		Local newNextSeasonTeams:TNewsEventSportTeam[]
		For Local t:TNewsEventSportTeam = EachIn nextSeasonTeams
			If team = t Then Continue
			newNextSeasonTeams :+ [t]
		Next
		nextSeasonTeams = newNextSeasonTeams
		Return True
	End Method


	Method GetNextMatchTime:Long()
		Return GetCurrentSeason().GetNextMatchTime()
	End Method


	Method GetFirstMatchTime:Long()
		Return GetCurrentSeason().GetFirstMatchTime()
	End Method


	Method GetLastMatchTime:Long()
		Return GetCurrentSeason().GetLastMatchTime()
	End Method


	Method GetLastMatchEndTime:Long()
		Return GetCurrentSeason().GetLastMatchEndTime()
	End Method


	'returns possible, used, yet-to-use timeslots of the matches
	Method GetTimeSlots:String[](onlyWithMatches:Int = True, onlyUpcomingMatches:Int = False, sortSlots:Int = True)
		If Not onlyWithMatches Then Return Self.timeSlots

		Local season:TNewsEventSportSeason = GetCurrentSeason()
		If Not season Then Return Null

		Local result:String[]
		Local lists:TList[]
		If Not onlyUpcomingMatches
			lists = [season.doneMatches, season.upcomingMatches]
		Else
			lists = [season.upcomingMatches]
		EndIf
		For Local l:TList = EachIn lists
			For Local m:TNewsEventSportMatch = EachIn l
				Local matchSlot:String = GetWorldTime().GetWeekDay(m.matchTime) + "_" + RSet(GetWorldTime().GetDayHour(m.matchTime),2).Replace(" ", "0")
				If Not StringHelper.InArray(matchSlot, result)
					result :+ [matchSlot]
				EndIf
				'already using all possible slots? do not look further!
				If result.length = Self.timeSlots.length Then Exit
			Next
		Next
		'sort, so earliest weekday is first, else the first found
		'is the first entry (useful for "upcoming" when in the next days)
		If sortSlots Then result.sort()

		Return result
	End Method


	'playoffs should ignore season breaks (season end / winter break)


	Method GetNextMatchStartTime:Long(time:Long = 0, ignoreSeasonBreaks:Int = False)
		If time = 0 Then time = GetWorldTime().GetTimeGone()
		Local weekday:Int = GetWorldTime().GetWeekday( time )
		'playtimes:
		'0 monday:    x
		'1 tuesday:   -
		'2 wednesday: x
		'3 thursday:  -
		'4 friday:    x
		'5 saturday:  x
		'6 sunday:    -
		Local matchDay:Int = 0
		Local matchHour:Int = -1

		'search the next possible time slot
		For Local t:String = EachIn timeSlots
			Local information:String[] = t.Split("_")
			Local weekdayIndex:Int = Int(information[0]) Mod 7
			Local hour:Int = 0
			If information.length > 1 Then hour = Int(information[1])

			'the same day => next possible hour
			If GetWorldTime().GetWeekday(time) = weekdayIndex
				'earlier or at least before xx:05
				If GetWorldTime().GetDayHour(time) < hour Or (GetWorldTime().GetDayHour(time) = hour And GetWorldTime().GetDayMinute(time) < 5)
					matchDay = 0
					matchHour = hour
					Exit
				EndIf
			EndIf

			'future day => earliest hour that day
			If GetWorldTime().GetWeekday(time) < weekdayIndex
				matchDay = weekdayIndex - GetWorldTime().GetWeekday(time)
				matchHour = hour
'If name = "Regionalliga" Then Print "  future day "+matchDay+" at " + matchHour+":00"+ "   " + t +"  weekdayIndex="+weekdayIndex +"  weekday="+GetWorldTime().GetWeekday(time)
				Exit
			EndIf

			If matchHour <> -1 Then Exit
		Next
		'if nothing was found yet, we might have had a time after the
		'last time slot -- so use the first one
		If matchHour = -1 And timeSlots.length > 0
			Local information:String[] = timeSlots[0].Split("_")
			matchDay = GetWorldTime().GetDaysPerWeek() + Int(information[0]) - GetWorldTime().GetWeekday(time)
			matchHour = 0
			If information.length > 1 Then matchHour = Int(information[1])
'If name = "Regionalliga" Then Print "  next week at day "+matchDay+" at " + matchHour+":00"
		EndIf



		Local matchTime:Long = 0
		'match time: 14. 8. - 14.5.
		'winter break: 21.12. - 21.1.


		Local firstDayStartHour:Int = 0
		If timeSlots.length > 0
			Local firstTime:String[] = timeSlots[0].Split("_")
			If firstTime.length > 1 Then firstDayStartHour = Int(firstTime[1])
		EndIf


		'always start at xx:05 (eases the pain for programmes)
		matchTime = GetWorldTime().GetTimeGoneForGameTime(0, GetWorldTime().GetDay(time) + matchDay, matchHour, 5)

		'check if we are in winter now
		If Not ignoreSeasonBreaks
			Local winterBreak:Int = False
			Local monthCode:Int = Int((RSet(GetWorldTime().GetMonth(matchTime),2) + RSet(GetWorldTime().GetDayOfMonth(matchTime),2)).Replace(" ", 0))
			'from 5th of december
			If 1220 < monthCode Then winterBreak = True
			'disabled - else we start maybe in april because 22th of january
			'might be right after the latest hour of the game day
			'till 22th of january
			'if  122 > monthCode then winterBreak = True

			If winterBreak And Not seasonJustBegun
				Local t:Long
				'next match starts in february
				'take time of 2 months later (either february or march - so
				'guaranteed to be the "next" year - when still in december)
				t = matchTime + GetWorldTime().GetTimeGoneForRealDate(0, 2, 1)
				'set time to "next year" begin of february - use "GetTimeGoneForRealDate"
				'to get the time of the ingame "5th february" (or the next
				'possible day)
				t = GetWorldTime().GetTimeGoneForRealDate(GetWorldTime().GetYear(t), 2, 5)
				'calculate next possible match time (after winter break)
				matchTime = GetNextMatchStartTime(t)
'If name = "Regionalliga" Then Print "   -> winterbreak delay"
			EndIf
		EndIf

		seasonJustBegun = False

'If name = "Regionalliga" Then Print "   -> day="+GetWorldTime().GetDay(matchTime) +"  " +GetWorldTime().GetDayName(GetWorldTime().GetWeekday(matchTime))+" ["+GetWorldTime().GetWeekday(matchTime)+"]  at "+GetWorldTime().GetFormattedTime(matchTime)

		Return matchTime
	End Method


	Method GetDoneMatchesCount:Int()
		If GetCurrentSeason() And GetCurrentSeason().doneMatches
			Return GetCurrentSeason().doneMatches.Count()
		EndIf
		Return 0
	End Method


	Method GetUpcomingMatchesCount:Int()
		If GetCurrentSeason() And GetCurrentSeason().upcomingMatches
			Return GetCurrentSeason().upcomingMatches.Count()
		EndIf
		Return 0
	End Method


	Method GetCurrentSeason:TNewsEventSportSeason()
		Return currentSeason
	End Method


	Method GetSport:TNewsEventSport()
		If sportGUID Then Return GetNewsEventSportCollection().GetByGUID(sportGUID)
		Return Null
	End Method


	Method Update:Int(time:Long = 0)
		If Not GetCurrentSeason() Then Return False
		If GetCurrentSeason().upcomingMatches.Count() = 0 Then Return False

		If time = 0 Then time = GetWorldTime().GetTimeGone()

		'starting a new group?
Rem
		local startingMatchGroup:int = False
		local startingMatchTime:Long
		For local nextMatch:TNewsEventSportMatch = EachIn GetCurrentSeason().upcomingMatches
			if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
				startingMatchTime = nextMatch.GetMatchTime()
				startingMatchGroup = True
print "--starting new group--"
				exit
			endif
		Next
endrem

		Local matchesRun:Int = 0
'		if startingMatchGroup
			'if _onStartMatchGroup then _onStartMatchGroup(self, nextMatch.GetMatchTime())
			'TriggerBaseEvent(GameEventKeys.SportLeague_StartMatchGroup, New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match), Self)

			Local endingMatchTime:Long
			Local runMatches:TNewsEventSportMatch[]
			For Local nextMatch:TNewsEventSportMatch = EachIn GetCurrentSeason().upcomingMatches
				If nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					GetCurrentSeason().updateTime = nextMatch.GetMatchTime()

					'invalidate table
					GetCurrentSeason().InvalidateLeaderboard()

					'begin season half ?
					If GetCurrentSeason().doneMatches.Count() = 0
						StartSeasonPart(1)
					ElseIf GetCurrentSeason().upcomingMatches.Count() = GetCurrentSeason().doneMatches.Count()
						StartSeasonPart(2)
					EndIf

					RunMatch(nextMatch)

					'finished season part ?
					If GetCurrentSeason().upcomingMatches.Count() = GetCurrentSeason().doneMatches.Count()
						FinishSeasonPart(1)
					EndIf

					runMatches :+ [nextMatch]

					endingMatchTime = Max(endingMatchTime, nextMatch.GetMatchTime())
					matchesRun :+ 1
				EndIf
			Next

			If runMatches.length > 0
				'refresh team stats for easier retrieval
				GetCurrentSeason().RefreshTeamStats(endingMatchTime)

				If endingMatchTime = 0 Then endingMatchTime = GetWorldTime().GetTimeGone()
				TriggerBaseEvent(GameEventKeys.SportLeague_FinishMatchGroup, New TData.add("matches", runMatches).AddLong("time", endingMatchTime).Add("season", GetCurrentSeason()), Self)
			EndIf
'		endif

		'finish season?
		If GetCurrentSeason().upcomingMatches.Count() = 0
			If Not IsSeasonFinished()
				'season 2/2 => also finishs whole season
				FinishSeasonPart(2)
			EndIf
			Return False
		EndIf

		Return matchesRun
	End Method


	Method StartSeason:Int(time:Long = 0)
		seasonJustBegun = True

		If time = 0 Then time = GetWorldTime().GetTimeGone()

		'archive old season
		If currentSeason Then pastSeasons :+ [currentSeason.data]

		'create and start new season
		currentSeason = New TNewsEventSportSeason.Init(Self.GetGUID(), sportGUID)
		currentSeason.Start(time)

		'set teams
		If nextSeasonTeams.length > 0
			currentSeason.SetTeams(nextSeasonTeams)
		Else
			Throw "next season teams missing"
		EndIf

		'let each one play versus each other
'Print "Create Upcoming Matches"
		CreateUpcomingMatches()
'Print "Assign Match Times"
		Local seasonStart:Long = GetSeasonStartTime(time)
'Print "SeasonStart: "  + GetworldTime().GetFormattedDate(seasonStart) +"  now=" +GetworldTime().GetFormattedDate(time)
		AssignMatchTimes(currentSeason, GetNextMatchStartTime(seasonStart))
		'sort the upcoming matches by match time (ascending)
		currentSeason.upcomingMatches.Sort(True, SortMatchesByTime)

		'debug
'		For Local m:TNewsEventSportMatch = EachIn currentSeason.upcomingMatches
'			Print "  match #"+RSet(m.matchNumber,2).Replace(" ", "0")+": "+ m.teams[0].GetTeamNameShort()+"-"+m.teams[1].GetTeamNameShort() +"   d:"+GetWorldTime().GetDaysRun(m.GetMatchTime())+".  "+.GetWorldTime().GetFormattedDate(m.GetMatchTime())
'		Next

		If _onStartSeason Then _onStartSeason(Self)

		TriggerBaseEvent(GameEventKeys.SportLeague_StartSeason, New TData.AddLong("time", time), Self)
	End Method


	Method FinishSeason:Int()
		If Not GetCurrentSeason() Then Return False
		GetCurrentSeason().Finish(GetCurrentSeason().updateTime)

		If _onFinishSeason Then _onFinishSeason(Self)
		TriggerBaseEvent(GameEventKeys.SportLeague_FinishSeason, New TData.AddLong("time", GetCurrentSeason().updateTime), Self)
	End Method


	Method StartSeasonPart:Int(part:Int)
		If Not GetCurrentSeason() Then Return False
		GetCurrentSeason().part = part

		If _onStartSeasonPart Then _onStartSeasonPart(Self, part)
		TriggerBaseEvent(GameEventKeys.SportLeague_StartSeasonPart, New TData.AddInt("part", part).AddLong("time", GetCurrentSeason().updateTime), Self)
	End Method


	Method FinishSeasonPart:Int(part:Int)
		If _onFinishSeasonPart Then _onFinishSeasonPart(Self, part)
		TriggerBaseEvent(GameEventKeys.SportLeague_FinishSeasonPart, New TData.AddInt("part", part).AddLong("time", GetCurrentSeason().updateTime), Self)
		If GetCurrentSeason() And part = GetCurrentSeason().partMax Then FinishSeason()
	End Method


	Method IsSeasonStarted:Int()
		If Not GetCurrentSeason() Then Return False

		Return GetCurrentSeason().started
	End Method


	Method IsSeasonFinished:Int()
		If Not GetCurrentSeason() Then Return False

		Return GetCurrentSeason().finished
	End Method


	Method GetMatchProgress:Float()
		If Not GetCurrentSeason() Then Return 0.0

		If GetCurrentSeason().upcomingMatches.Count() = 0 Then Return 1.0
		If GetCurrentSeason().doneMatches.Count() = 0 Then Return 0.0
		Return GetCurrentSeason().doneMatches.Count() / Float(GetCurrentSeason().doneMatches.Count() + GetCurrentSeason().upcomingMatches.Count())
	End Method


	Method GetTeamCount:Int()
		Return GetCurrentSeason().GetTeams().length
	End Method


	Method GetMatchCount:Int()
		Return GetCurrentSeason().GetMatchCount()
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		Return GetCurrentSeason().GetUpcomingMatches(minTime, maxTime)
	End Method


	Method CreateUpcomingMatches:Int()
		If Not GetCurrentSeason() Then Return False

		'setup match plan array (if not done)
		If Not GetCurrentSeason().data.matchPlan Then GetCurrentSeason().data.matchPlan = New TNewsEventSportMatch[GetCurrentSeason().GetMatchCount()]
		Local matchPlan:TNewsEventSportMatch[] = GetCurrentSeason().data.matchPlan

'		TNewsEventSport_Soccer.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_Soccer.CreateMatch)
		Custom_CreateUpcomingMatches()

		For Local match:TNewsEventSportMatch = EachIn GetCurrentSeason().data.matchPlan
			GetCurrentSeason().upcomingMatches.addLast(match)

			GetNewsEventSportCollection().AddMatch(match)
		Next
	End Method


	Method Custom_CreateUpcomingMatches:Int() Abstract


	'adjust the given time if the first match of a season cannot start
	'before a given time
	Method GetSeasonStartTime:Long(time:Long)
		Return time
	End Method


	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Long = 0, isPlayoffSeason:Int = False)
		If time = 0 Then time = GetNextMatchStartTime(time)
		If Not season Then season = GetCurrentSeason()

		For Local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			m.SetMatchTime(time)
			time = GetNextMatchStartTime(time)
		Next
	End Method


	Function SortMatchesByTime:Int(o1:Object, o2:Object)
		Local m1:TNewsEventSportMatch = TNewsEventSportMatch(o1)
		Local m2:TNewsEventSportMatch = TNewsEventSportMatch(o2)

		If Not m1 Then Return -1
		If Not m2 Then Return 1

		If m1.GetMatchTime() < m2.GetMatchTime() Then Return -1
		If m1.GetMatchTime() > m2.GetMatchTime() Then Return 1
		Return 0
	End Function


	Method RunMatch:Int(match:TNewsEventSportMatch, matchTime:Long = -1)
		If Not match Then Return False
		If Not GetCurrentSeason() Or GetCurrentSeason().finished Then Return False

		'override match start time
		If matchTime <> -1 Then match.SetMatchTime(matchTime)

		GetCurrentSeason().upcomingMatches.Remove(match)
		match.Run()
		GetCurrentSeason().doneMatches.AddLast(match)

		If _onRunMatch Then _onRunMatch(Self, match)
		TriggerBaseEvent(GameEventKeys.SportLeague_RunMatch, New TData.AddLong("matchTime", match.GetMatchTime()).Add("match", match).Add("season", GetCurrentSeason()), Self)

		Return True
	End Method


	Method GetLastMatch:TNewsEventSportMatch()
		If Not GetCurrentSeason() Then Return Null
		If Not GetCurrentSeason().doneMatches Or GetCurrentSeason().doneMatches.Count() = 0 Then Return Null
		Return TNewsEventSportMatch(GetCurrentSeason().doneMatches.Last())
	End Method


	Method GetNextMatch:TNewsEventSportMatch()
		If Not GetCurrentSeason() Then Return Null
		If Not GetCurrentSeason().upcomingMatches Or GetCurrentSeason().upcomingMatches.Count() = 0 Then Return Null
		Return TNewsEventSportMatch(GetCurrentSeason().upcomingMatches.First())
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchTime:Long = 0)
		If Not GetCurrentSeason() Then Return Null

		Return GetCurrentSeason().data.GetLeaderboard(upToMatchTime)
	End Method
End Type



Type TNewsEventSportLeagueRank
	Field score:Int
	Field team:TNewsEventSportTeam

	Method Compare:Int(o:Object)
		Local other:TNewsEventSportLeagueRank = TNewsEventSportLeagueRank(o)
		If other
			If score > other.score Then Return 1
			If score < other.score Then Return -1
		EndIf
		Return Super.Compare(other)
	End Method
End Type



Type TNewsEventSportMatch Extends TGameObject
	Field teams:TNewsEventSportTeam[]
	'array containing total points of each team
	Field points:Int[]
	'csv-like score entries: "time,teamIndex,score|time,teamIndex,score..."
	'custom sports might also do: "time,teamIndex,score,memberIndex|..."
	Field scores:String
	'easy to access array of "scores" (to avoid string usage
	Field _scoresTime:Int[] {nosave}
	Field _scoresTeam:Int[] {nosave}
	Field _scoresScore:Int[] {nosave}
	Field duration:Int = 90 * TWorldTime.MINUTELENGTH 'in milliseconds
	'when the match takes place
	Field matchTime:Long
	'when a potential break takes place
	Field breakTimes:Int[] = [45 * TWorldTime.MINUTELENGTH]
	'length of each of the breaks
	Field breakDuration:Int = 15 * TWorldTime.MINUTELENGTH

	Field sportName:String

	Field matchNumber:Int
	Field matchState:Int = STATE_NORMAL
	Const STATE_NORMAL:Int = 0
	Const STATE_RUN:Int = 1


	Method Run:Int()
		AdjustDurationAndBreakTimes()

		CalculateTotalScore()

		'distribute scores along the match time
		FillScores()

		matchState = STATE_RUN
	End Method


	Method AdjustDurationAndBreakTimes()
		Local overtime:Int = BiasedRandRange(0,8, 0.3) * TWorldTime.MINUTELENGTH
		duration :+ overtime

		If breakTimes.length > 0
			Local breakTime:Int = duration / breakTimes.length
			Local overtimePart:Int = overtime / breakTimes.length
			For Local i:Int = 0 Until breakTimes.length
				breakTimes[i] = breakTime + overtimePart
				'prepend previous breaktime
				'ex. [0] = 30+2  [1] = 30+3 + 32   [2] = 30+2 + 65 ...
				If i > 0 Then breakTimes[i] :+ breakTimes[i-1]
			Next
			'add rest of overtime to last break
			breakTimes[breakTimes.length-1] :+ (overtime - overtimePart*breakTimes.length)
		EndIf
	End Method


	Method CalculateTotalScore()
		'calculate total scores
		For Local i:Int = 0 Until points.length
			points[i] = BiasedRandRange(0, 8, 0.18)
		Next
	End Method


	Method FillScores()
		'calculate amount of points so that arrays know their sizes
		Local totalPoints:Int
		For Local teamIndex:Int = 0 Until points.length
			totalPoints :+ points[teamIndex]
		Next

		_scoresTime = New Int[totalPoints]
		_scoresTeam = New Int[totalPoints]
		_scoresScore = New Int[totalPoints]
		
		'generate time stamps of the scores
		For Local pointNumber:Int = 0 Until totalPoints
			_scoresTime[pointNumber] = RandRange(0, duration/1000)
		Next
		'earliest to latest
		_scoresTime.sort(True)

	
		'fill array with one entry per score and team
		'then shuffle them so that order of "scoring" is mixed
		Local scoresTeamIndex:int = 0
		For Local teamIndex:Int = 0 Until points.length
			For Local point:Int = 0 Until points[teamIndex]
				_scoresTeam[scoresTeamIndex] = teamIndex
				scoresTeamIndex :+ 1
			Next
		Next
		'then shuffle them so that order of "scoring" is mixed
		For Local a:int = 0 To totalPoints - 2
			Local b:int = RandRange( a, totalPoints - 1)
			Local team:int = _scoresTeam[a]
			_scoresTeam[a] = _scoresTeam[b]
			_scoresTeam[b] = team
		Next
		
		'by default each score entry is "one point" (basketball would be 1, 2 or 3 then)
		For Local i:int = 0 Until totalPoints
			_scoresScore[i] = 1
		Next

		'serialize them into a string (smaller than the xml-serialization of the arrays)
		Local sb:TStringBuilder = New TStringBuilder
		For local i:int = 0 until totalPoints
			sb.Append(_scoresTime[i])
			sb.Append(",")
			sb.Append(_scoresTeam[i])
			sb.Append(",")
			sb.Append(_scoresScore[i])

			If i < totalPoints -1
				sb.Append("|")
			EndIf
		Next
		self.scores = sb.ToString()
	End Method
	
	
	Method FillScoresFromString:Int(s:String)
		Local entries:String[] = s.split("|")
		local totalPoints:int = entries.length

		_scoresTime = New Int[totalPoints]
		_scoresTeam = New Int[totalPoints]
		_scoresScore = New Int[totalPoints]
		
		For local i:int = 0 until entries.length
			local parts:String[] = entries[i].split(",")
			If parts.length <> 3 Then Return False
			_scoresTime[i] = int(parts[0])
			_scoresTeam[i] = int(parts[1])
			_scoresScore[i] = int(parts[2])
		Next
		Return True
	End Method


	Function CreateMatch:TNewsEventSportMatch()
		Return New TNewsEventSportMatch
	End Function


	Method AddTeam(team:TNewsEventSportTeam)
		teams :+ [team]
		points = points[ .. points.length + 1]
	End Method


	Method AddTeams(teams:TNewsEventSportTeam[])
		Self.teams :+ teams
		points = points[ .. points.length + teams.length]
	End Method


	Method SetMatchTime(time:Long)
		matchTime = time
	End Method


	Method GetMatchTime:Long()
		Return matchTime
	End Method


	Method GetMatchEndTime:Long()
		Return matchTime + duration + GetTotalBreakTime()
	End Method


	Method GetTotalBreakTime:Int()
		Local res:Int
		
		'sum up the breaks
		For Local i:Int = 0 Until breakTimes.length
			res :+ breakDuration 'breakTimes[i]
		Next
		Return res
	End Method


	Method GetScore:Int(team:TNewsEventSportTeam)
		If Not IsRun() Then Return 0

		If GetRank(team) = 1 Then Return GetWinnerScore()
		Return GetLooserScore()
	End Method


	Method GetRank:Int(team:TNewsEventSportTeam)
		If Not IsRun() Then Return 0

		Local rank:Int = 1
		For Local i:Int = 0 Until teams.length
			If teams[i] <> team Then Continue

			'count better ranked teams
			For Local j:Int = 0 Until teams.length
				If i = j Then Continue
				If points[j] > points[i] Then rank :+ 1
			Next
		Next
		Return rank
	End Method


	Method IsRun:Int()
		Return matchState = STATE_RUN
'		if matchTime = -1 then return False
'		return matchTime < time
	End Method


	Method HasLooser:Int()
		If Not IsRun() Then Return False
		If Not points Or points.length = 0 Then Return False

		'check if one of the teams has less points than the others
		Local lastPoint:Int = points[0]
		For Local point:Int = EachIn points
			If point <> lastPoint Then Return True
		Next
		Return False
	End Method


	Method HasWinner:Int()
		If Not IsRun() Then Return False
		Return GetWinner() <> -1
	End Method


	Method GetWinner:Int()
		If Not IsRun() Then Return -1
		If Not points Or points.length = 0 Then Return -1

		'check if one of the teams has most points
		Local bestPoint:Int = points[0]
		Local bestPointCount:Int = 0
		Local bestTeam:Int = 0
		If points.length > 1
			For Local i:Int = 1 Until points.length
				If points[i] = bestPoint
					bestPointCount :+ 1
				ElseIf points[i] > bestPoint
					bestPoint = points[i]
					bestPointCount = 0
					bestTeam = i
				EndIf
			Next
		EndIf

		If bestPointCount = 0 Then Return bestTeam
		Return -1
	End Method


	Method GetWinnerScore:Int()
		Return 2
	End Method


	Method GetDrawGameScore:Int()
		Return 1
	End Method


	Method GetLooserScore:Int()
		Return 0
	End Method


	Method GetNameShort:String()
		Local result:String
		For Local i:Int = 0 Until points.length
			If result <> "" Then result :+ " - "
			result :+ teams[i].GetTeamNameShort()
		Next
		Return result
	End Method


	Method GetReport:String()
		Return "override GetReport()"
	End Method

	Method GetLiveReportShort:String(mode:String="", time:Long=-1)
		Return "override GetLiveReportShort()"
	End Method

	Method GetReportShort:String(mode:String="")
		Return "override GetReportShort()"
	End Method


	Method GetMatchTimeGone:Int(time:Long=-1)
		If time = -1 Then time = GetWorldTime().GetTimeGone()
		Local timeGone:Int = Max(0, time - GetMatchTime())
		Local matchTime:Int = timeGone

		For Local i:Int = 0 Until breakTimes.length
			If timeGone >= breakTimes[i]
				'currently within a break?
				If timeGone <= breakTimes[i] + breakDuration
					matchTime = breakTimes[i]
				Else
					matchTime :- breakDuration
				EndIf
			Else
				'did not reach that breaktime yet
				Exit
			EndIf
		Next
		Return matchTime
	End Method


	Method GetMatchResultText:String()
		Local singularPlural:String = "P"
		If teams[0].clubNameSingular Then singularPlural = "S"

		Local result:String = ""

		If points[0] > points[1]
			If sportName <> ""
				result = GetRandomLocale2(["SPORT_"+sportName+"_TEAMREPORT_MATCHWIN_" + singularPlural, "SPORT_TEAMREPORT_MATCHWIN_" + singularPlural])
			Else
				result = GetRandomLocale("SPORT_TEAMREPORT_MATCHWIN_" + singularPlural)
			EndIf
		ElseIf points[0] < points[1]
			If sportName <> ""
				result = GetRandomLocale2(["SPORT_"+sportName+"_TEAMREPORT_MATCHLOOSE_" + singularPlural, "SPORT_TEAMREPORT_MATCHLOOSE_" + singularPlural])
			Else
				result = GetRandomLocale("SPORT_TEAMREPORT_MATCHLOOSE_" + singularPlural)
			EndIf
		Else
			If sportName <> ""
				result = GetRandomLocale2(["SPORT_"+sportName+"_TEAMREPORT_MATCHDRAW_" + singularPlural, "SPORT_TEAMREPORT_MATCHDRAW_" + singularPlural])
			Else
				result = GetRandomLocale("SPORT_TEAMREPORT_MATCHDRAW_" + singularPlural)
			EndIf
		EndIf

		Return result
	End Method


	Method GetMatchScore:Int[](matchTime:Int)
		'convert matchTime to seconds (from milliseconds)
		matchTime :/ TWorldTime.SECONDLENGTH
	
		If Not _scoresTeam or _scoresTeam.length = 0 
			If Not FillScoresFromString(self.scores)
				Throw "FillScoresFromString: Invalid serialized string ~q"+self.scores+"~q."
			EndIf
		EndIf

		Local matchScore:Int[] = New Int[points.length] 'amount of teams
		For local i:int = 0 until _scoresTime.length 'times of scores gained
			'not yet happened? All further scores did not happen yet too
			If _scoresTime[i] > matchTime Then Exit

			matchScore[_scoresTeam[i]] :+ _scoresScore[i]
		Next

		Return matchScore
	End Method


	Method GetFinalScoreText:String()
		Return StringHelper.JoinIntArray(":", points)
	End Method


	Method ReplacePlaceholders:String(value:String)
		Local result:String = value
		If result.Find("%MATCHRESULT%") >= 0
			result = result.Replace("%MATCHRESULT%", GetMatchResultText() )
		EndIf

		If result.Find("%MATCHSCORE") >= 0
			For Local i:Int = 1 To teams.length
				If result.Find("%MATCHSCORE"+i) >= 0
					Local points:Int = GetScore( teams[i-1] )
					If points = 1
						result = result.Replace("%MATCHSCORE"+i+"TEXT%", points + " " + GetLocale("SCORE_POINT") )
					Else
						result = result.Replace("%MATCHSCORE"+i+"TEXT%", points + " " + GetLocale("SCORE_POINTS") )
					EndIf

					result = result.Replace("%MATCHSCORE"+i+"%", points)
				EndIf
			Next
		EndIf

		If result.Find("%MATCHSCOREMAX") >= 0
			Local points:Int = GetWinnerScore()
			result = result.Replace("%MATCHSCOREMAX%", points)
			If points = 1
				result = result.Replace("%MATCHSCOREMAXTEXT%", points + " " + GetLocale("SCORE_POINT"))
			Else
				result = result.Replace("%MATCHSCOREMAXTEXT%", points + " " + GetLocale("SCORE_POINTS"))
			EndIf
		EndIf

		If result.Find("%MATCHSCOREDRAWGAME") >= 0
			Local points:Int = GetDrawGameScore()
			result = result.Replace("%MATCHSCOREDRAWGAME%", points)
			If points = 1
				result = result.Replace("%MATCHSCOREDRAWGAMETEXT%", points + " " + GetLocale("SCORE_POINT"))
			Else
				result = result.Replace("%MATCHSCOREDRAWGAMETEXT%", points + " " + GetLocale("SCORE_POINTS"))
			EndIf
		EndIf

		If result.Find("%MATCHKIND%") >= 0
			If RandRange(0,10) < 7
				result = result.Replace("%MATCHKIND%", GetRandomLocale("SPORT_TEAMREPORT_MATCHKIND"))
			Else
				result = result.Replace("%MATCHKIND%", "")
			EndIf
		EndIf

		For Local i:Int = 1 To teams.length
			If result.Find("%TEAM"+i) < 0 Then Continue

			 teams[i-1].FillPlaceholders(result, String(i))
		Next

		If result.Find("%FINALSCORE%") >= 0
			result = result.Replace("%FINALSCORE%", GetFinalScoreText())
		EndIf

		result = result.Replace("%PLAYTIMEMINUTES%", Int(duration / TWorldTime.MINUTELENGTH) )

		result = result.Trim().Replace("  ", " ") 'remove space if no team article...

		Return result
	End Method
End Type




Type TNewsEventSportTeam
	'eg. "Exampletown"
	Field city:String
	'eg. "Saxony Exampletown"
	Field name:String
	'eg. "SE"
	Field nameInitials:String
	'eg. "Football club"
	Field clubName:String
	'eg. "Goalies"
	Field clubNameSuffix:String
	'eg. "FC"
	Field clubNameInitials:String
	'eg. "G"
	Field clubNameSuffixInitials:String
	'if singular, in German the "Der" is used, else "Die"
	'-> "Der Klub" (the club), "Die Kicker" (the kickers)
	Field clubNameSingular:Int

	Field members:TNewsEventSportTeamMember[]
	Field trainer:TNewsEventSportTeamMember

	Field statsPower:Float = -1
	Field statsAttractivity:Float = -1
	Field statsSkill:Float = -1
	'start values
	Field statsAttractivityBase:Float = 0.5
	Field statsPowerBase:Float = 0.5
	Field statsSkillBase:Float = 0.4

	Field currentRank:Int = 0
	Field leagueGUID:String
	Field sportGUID:String


	Method SetTrainer:TNewsEventSportTeam(trainer:TNewsEventSportTeamMember)
		Self.trainer = trainer
	End Method


	Method GetTrainer:TNewsEventSportTeamMember()
		Return trainer
	End Method


	Method AddMember:TNewsEventSportTeam(member:TNewsEventSportTeamMember)
		members :+ [member]
	End Method


	Method GetMemberAtIndex:TNewsEventSportTeamMember(index:Int)
		If index < 0 Then index = members.length + index '-1 = last one
		If index < 0 Or index >= members.length Then Return Null
		Return members[index]
	End Method


	Method GetCity:String()
		Return city
	End Method


	Method GetTeamName:String()
		If clubNameSuffix And clubName
			Return clubName + " " + name + " " + clubNameSuffix
		ElseIf clubNameSuffix And Not clubName
			Return name + " " + clubNameSuffix
		Else
			Return clubName + " " + name
		EndIf
	End Method


	Method GetTeamNameShort:String()
		'no short name possible for "Cityname Sharks"
		If clubNameSuffix
			Return GetTeamName()
		Else
			Return clubNameInitials + " " + name
		EndIf
	End Method


	Method GetTeamInitials:String()
		Return clubNameInitials + nameInitials + clubNameSuffixInitials
	End Method


	Method RandomizeBasicStats(leagueIndex:Int = 0)
		Local leagueMod:Int = (leagueIndex = 0)*10 + (leagueIndex = 1)*6 + (leagueIndex = 2)*4 - (leagueIndex = 3)*4
		statsAttractivityBase = RandRange(40, 50 + leagueMod)/100.0
		statsPowerBase = RandRange(35, 50 + leagueMod)/100.0
		statsSkillBase = RandRange(35, 50 + leagueMod)/100.0
	End Method


	Method UpdateStats()
		statsAttractivity = -1
		statsPower = -1
		statsSkill = -1
	End Method


	Function GetDistributionCurveValue:Float(percentage:Float, zeroPercentage:Float)
		Return (THelper.logisticFunction(1.0 - percentage/zeroPercentage, 1.0, 4 ) - 0.5) * 2

		'-0.00001 to avoid "-0.00000000" for percentage=zeroPercentage
	'	return -sgn(percentage-0.5 - 0.00001) * 5*(1 - 1.0/((percentage - 0.5)^2+1))
	End Function


	Method GetAttractivity:Float()
		If statsAttractivity = -1
			'basic attractivity
			statsAttractivity = statsAttractivityBase

			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			If league
				Select league._leaguesIndex
					Case 0   statsAttractivity :+ 0.40
					Case 1   statsAttractivity :+ 0.15
					Case 2   statsAttractivity :- 0.05
					Default  statsAttractivity :- 0.20
				End Select

				If currentRank <> 0
					statsAttractivity :+ 0.2 * GetDistributionCurveValue(Float(currentRank) / league.GetTeamCount(), 0.6)

					'first and last get extra bonus/penalty
					If currentRank = 1 Then statsAttractivity :+ 0.1
					If currentRank = league.GetTeamCount() Then statsAttractivity :- 0.05
				EndIf
			EndIf
			statsAttractivity = MathHelper.Clamp(statsAttractivity, 0.0, 1.0)
		EndIf

		Return statsAttractivity
	End Method


	Method GetPower:Float()
		If statsPower = -1
			statsPower = statsPowerBase
			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			If league
				Select league._leaguesIndex
					Case 0   statsPower :+ 0.40
					Case 1   statsPower :+ 0.15
					Case 2   statsPower :- 0.05
					Default  statsPower :- 0.15
				End Select
				If currentRank <> 0
					statsPower :+ 0.2 * GetDistributionCurveValue(Float(currentRank) / league.GetTeamCount(), 0.7)
				EndIf
			EndIf

			statsPower = MathHelper.Clamp(statsPower, 0.0, 1.0)
		EndIf

		Return statsPower
	End Method


	Method GetSkill:Float()
		If statsSkill = -1
			statsSkill = statsSkillBase
			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			If league
				Select league._leaguesIndex
					Case 0   statsSkill :+ 0.40
					Case 1   statsSkill :+ 0.15
					Case 2   statsSkill :- 0.05
					Default  statsSkill :- 0.15
				End Select

				If currentRank <> 0
					'adjusted and negated formula of f(x) = 1/((x+a)^2+1)
					'a=displacement, adjustment:  to have "after displacement" become negative
					'adjusted is f(x) = -sgn(x+a) * 1/((x+a)^2+1)
					'statsSkill :+ 0.2 * -sgn((currentRank - league.GetTeamCount()/3.0)) + (1 - 1/((currentRank - league.GetTeamCount()/3.0)^2 + 1))

					statsSkill :+ 0.2 * GetDistributionCurveValue(Float(currentRank) / league.GetTeamCount(), 0.6)
				EndIf
			EndIf

			'print Lset(GetTeamName(), 15)+": statsSkill="+ statsSkill
			statsSkill = MathHelper.Clamp(statsSkill, 0.0, 1.0)
		EndIf

		Return statsSkill
	End Method


	Method AssignLeague(leagueGUID:String)
		Self.leagueGUID = leagueGUID
	End Method


	Method AssignSport(sportGUID:String)
		Self.sportGUID = sportGUID
	End Method


	Method GetLeague:TNewsEventSportLeague()
		If Not leagueGUID Then Return Null

		'try to find league the easy way
		Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
		If league Then Return league

		'try it the indirect way
		If Not sportGUID Then Return Null

		Local sport:TNewsEventSport = GetNewsEventSportCollection().GetByGUID(sportGUID)
		If sport Then Return sport.GetLeagueByGUID(leagueGUID)

		Return Null
	End Method


	Method FillPlaceholders(value:String Var, teamIndex:String="")
		If value.Find("%TEAM"+teamIndex+"%") >= 0
			If RandRange(0,100) < 75
				value = value.Replace("%TEAM"+teamIndex+"%", GetTeamName())
			Else
				value = value.Replace("%TEAM"+teamIndex+"%", clubNameInitials +" "+ name)
			EndIf
		EndIf
		value = value.Replace("%TEAM"+teamIndex+"NAMEINITIALS%", GetTeamInitials())
		value = value.Replace("%TEAM"+teamIndex+"NAMESHORT%", GetTeamNameShort())
		value = value.Replace("%TEAM"+teamIndex+"NAME%", GetTeamName())
		value = value.Replace("%TEAM"+teamIndex+"CITY%", GetCity())

		value = value.Replace("%TEAM"+teamIndex+"STAR%", GetMemberAtIndex(-1).GetFullName() )
		value = value.Replace("%TEAM"+teamIndex+"STARSHORT%", GetMemberAtIndex(-1).GetLastName() )
		value = value.Replace("%TEAM"+teamIndex+"KEEPER%", GetMemberAtIndex(0).GetFullName() )
		value = value.Replace("%TEAM"+teamIndex+"KEEPERSHORT%", GetMemberAtIndex(0).GetLastName() )
		value = value.Replace("%TEAM"+teamIndex+"TRAINER%", GetTrainer().GetFullName() )
		value = value.Replace("%TEAM"+teamIndex+"TRAINERSHORT%", GetTrainer().GetLastName() )

		If value.Find("%TEAM"+teamIndex+"ARTICLE") >= 0
			If clubNameSingular
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE1%", GetLocale("SPORT_TEAMNAME_S_VARIANT_A") )
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE2%", GetLocale("SPORT_TEAMNAME_S_VARIANT_B") )
			Else
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE1%", GetLocale("SPORT_TEAMNAME_P_VARIANT_A") )
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE2%", GetLocale("SPORT_TEAMNAME_P_VARIANT_B") )
			EndIf
		EndIf

	End Method
End Type




Type TNewsEventSportTeamMember Extends TPersonBase
	Field teamGUID:String

	Method Init:TNewsEventSportTeamMember(firstName:String, lastName:String, countryCode:String, gender:Int = 0, fictional:Int = False)
		Self.firstName = firstName
		Self.lastName = lastName
		Self.SetGUID("sportsman-"+id)
		Self.countryCode = countryCode
		Self.gender = gender

		Self.SetFlag(TVTPersonFlag.FICTIONAL, fictional)

		Return Self
	End Method


	Method AssignTeam(teamGUID:String)
		Self.teamGUID = teamGUID
	End Method
End Type
