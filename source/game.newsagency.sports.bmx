SuperStrict
Import "game.world.worldtime.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.helper.bmx"
Import "game.programme.programmeperson.base.bmx"




Type TNewsEventSportCollection extends TGameObjectCollection
	Field leagues:TMap = new TMap
	Field matches:TMap = new TMap
	Global _instance:TNewsEventSportCollection


	Function GetInstance:TNewsEventSportCollection()
		if not _instance then _instance = new TNewsEventSportCollection
		return _instance
	End Function


	Method Initialize:TNewsEventSportCollection()
		Super.Initialize()
		return self
	End Method


	Method GetByGUID:TNewsEventSport(GUID:String)
		Return TNewsEventSport( Super.GetByGUID(GUID) )
	End Method


	Method AddLeague(league:TNewsEventSportLeague)
		leagues.Insert(league.GetGUID(), league)
	End Method


	Method GetLeagueByGUID:TNewsEventSportLeague(guid:string)
		return TNewsEventSportLeague( leagues.ValueForKey(guid) )
	End Method


	Method AddMatch(match:TNewsEventSportMatch)
		matches.Insert(match.GetGUID(), match)
	End Method


	Method GetMatchByGUID:TNewsEventSportMatch(guid:string)
		return TNewsEventSportMatch( matches.ValueForKey(guid) )
	End Method


	Method InitializeAll:int()
		For local sport:TNewsEventSport = EachIn entries.Values()
			sport.Initialize()
		Next
	End Method


	Method CreateAllLeagues:int()
		For local sport:TNewsEventSport = EachIn entries.Values()
			sport.CreateDefaultLeagues()
		Next
	End Method


	Method UpdateAll:int()
		For local sport:TNewsEventSport = EachIn entries.Values()
			sport.Update()
			rem
			local nextMatchTime:Long = sport.GetNextMatchTime()
			if nextMatchTime <> -1
				print "sport: "+sport.name+"  nextMatch at " + (GetWorldTime().GetDaysRun(nextMatchTime)+1)+"/"+GetWorldTime().GetFormattedTime(nextMatchTime)
			else
				print "sport: "+sport.name+"  NO next match"
			endif
			endrem
		Next
	End Method


	Method StartAll:int( time:Long = -1 )
		if time = -1 then time = GetWorldTime().GetTimeGone()

		For local sport:TNewsEventSport = EachIn entries.Values()
			sport.StartSeason(time)
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetNewsEventSportCollection:TNewsEventSportCollection()
	Return TNewsEventSportCollection.GetInstance()
End Function




Type TNewsEventSport extends TGameObject
	'the league of the sport
	Field leagues:TNewsEventSportLeague[]
	'0 = unknown, 1 = running, 2 = finished
	Field playoffsState:int = 0
	'for each league-to-league connection we create a fake season
	'for the playoffs
	Field playoffSeasons:TNewsEventSportSeason[]
	Field playOffStartTime:Long
	Field playOffEndTime:Long
	Field name:string = "unknown"


	Method GenerateGUID:string()
		return "NewsEventSport-"+id
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

		return self
	End Method


	Method CreateDefaultLeagues:int()
		print "override in custom sport"
	End Method

	
	'updates all leagues of this sport
	Method Update:int()
		'=== regular league matches ===
		For local l:TNewsEventSportLeague = Eachin leagues
			l.Update()
		Next
		if IsSeasonFinished() and playoffsState = 0
			CreatePlayoffSeasons()
			'delay by at least 1 day
			AssignPlayoffTimes( Long(GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH))

			StartPlayoffs()

			?debug
			For local season:TNewsEventSportSeason = EachIn playoffSeasons
				print name+":  playoff matches: " + GetWorldTime().GetFormattedGameDate(season.GetNextMatchTime()) + "   -   " + GetWorldTime().GetFormattedGameDate(season.GetLastMatchTime())
			Next
			?
		endif

		'=== playoff matches ===
		if playoffsState = 1
			if not UpdatePlayoffs()
				'move loosing teams one lower, winners one higher
				FinishPlayoffs()
			endif
		endif

		'start next season if needed
		if ReadyForNextSeason() then StartSeason()
	End Method


	Method UpdatePlayoffs:int()
		local matchesRun:int = 0
		local matchesToCome:int = 0

		local leagueNumber:int = 0
		For local season:TNewsEventSportSeason = EachIn playoffSeasons
			leagueNumber :+ 1
			if not season.upcomingMatches then continue

			For local nextMatch:TNewsEventSportMatch = EachIn season.upcomingMatches
				if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					season.updateTime = nextMatch.GetMatchTime()

					'invalidate table
					season.InvalidateLeaderboard()

					season.upcomingMatches.Remove(nextMatch)
					nextMatch.Run()
					season.doneMatches.AddLast(nextMatch)

					EventManager.triggerEvent(TEventSimple.Create("Sport.Playoffs.RunMatch", New TData.addNumber("matchTime", nextMatch.GetMatchTime()).add("match", nextMatch).Add("season", season).AddNumber("leagueIndex", leagueNumber -1), Self))
		
					matchesRun :+ 1
				'else
				'	print "now: " + GetWorldTime().GetFormattedDate()+"  match: " + GetWorldTime().GetFormattedDate( nextMatch.GetMatchTime())
				endif
			Next

			matchesToCome :+ season.upcomingMatches.Count()
		Next

		'finish playoffs?
		if matchesToCome = 0 then return False

		return True
	End Method


	Method StartPlayoffs()
		For local season:TNewsEventSportSeason = EachIn playoffSeasons
			season.Start( Long(GetWorldTime().GetTimeGone()) )
		Next

		playoffsState = 1

		EventManager.triggerEvent(TEventSimple.Create("Sport.StartPlayoffs", new TData.AddNumber("time", GetWorldTime().GetTimeGone()), Self))
	End Method


	Method FinishPlayoffs()
		For local season:TNewsEventSportSeason = EachIn playoffSeasons
			season.Finish( Long(GetWorldTime().GetTimeGone()) )
		Next

		local leagueWinners:TNewsEventSportTeam[leagues.length]
		local leagueLoosers:TNewsEventSportTeam[leagues.length]
		local playoffWinners:TNewsEventSportTeam[leagues.length]

		'move the last of #1 one down
		'move the first of #2 one up
		For local i:int = 0 until leagues.length-1
			local looser:TNewsEventSportTeam = leagues[i].GetCurrentSeason().GetTeamAtRank( -1 )
			local winner:TNewsEventSportTeam = leagues[i+1].GetCurrentSeason().GetTeamAtRank( 1 )

			leagues[i].ReplaceNextSeasonTeam(looser, winner)
			leagues[i+1].ReplaceNextSeasonTeam(winner, looser)
			'print "Liga: "+(i+1)+"->"+(i+2)
			'print "  abstieg: "+looser.name
			'print "  aufstieg: "+winner.name
		Next

		'set winner of relegation to #1
		'set looser of relegation to #2
		For local i:int = 0 until playoffSeasons.length -1
			'i=0 => playoff between league 0 and league 1
			local looser:TNewsEventSportTeam = playoffSeasons[i].GetTeamAtRank( -1 )
			local winner:TNewsEventSportTeam = playoffSeasons[i].GetTeamAtRank( 1 )

			local winnerMovesUp:int = leagues[i].GetNextSeasonTeamIndex(winner) = -1
			local looserMovesDown:int = leagues[i+1].GetNextSeasonTeamIndex(looser) = -1

			?debug
			local in1:string, in2:string
			for local t:TNewsEventSportLeagueRank = Eachin leagues[i].GetCurrentSeason().data.GetLeaderboard()
				in1 :+ t.team.name+" / "
			next
			for local t:TNewsEventSportLeagueRank = Eachin leagues[i+1].GetCurrentSeason().data.GetLeaderboard()
				in2 :+ t.team.name+" / "
			next

			print "Relegation: "+(i+1)+"->"+(i+2)
			print "  in "+(i+1)+": " + in1
			print "  in "+(i+2)+": " + in2
			if winnerMovesUp
				print "  abstieg: "+looser.name
				print "  aufstieg: "+winner.name
			else
				print "  bleibt in "+i+": "+winner.name
				print "  bleibt in "+(i+1)+": "+looser.name
			endif
			?

			'only switch teams if possible for both leagues
			'else you would add a team to two leagues
			if winnerMovesUp 'and looserMovesDown
				if leagues[i].ReplaceNextSeasonTeam(looser, winner)
					'print "league " + i+": replaced "+looser.name+" with " + winner.name
					if not leagues[i+1].ReplaceNextSeasonTeam(winner, looser)
						'print "could not replace next season team in league"+(i+1)
					endif
				else
					'print "could not replace next season team in league"+i
				
				endif
			endif

'			print "EVENT fuer Playoffs losschicken, Gewinner/Verlierer nur wenn Ligawechsel"
		Next

		playoffsState = 2

		EventManager.triggerEvent(TEventSimple.Create("Sport.FinishPlayoffs", new TData.AddNumber("time", GetWorldTime().GetTimeGone()), Self))
	End Method


	Method CreatePlayoffSeasons()
		'we need leagues-1 seasons (1->2, 2->3, loosers of league 3 stay)
		playoffSeasons = new TNewsEventSportSeason[ leagues.length - 1 ]
		playOffStartTime = GetWorldTime().GetTimeGone()
		For local i:int = 0 to playoffSeasons.length -1
			playoffSeasons[i] = new TNewsEventSportSeason.Init("", self.GetGUID())
			'mark as playoff season
			playoffSeasons[i].seasonType = TNewsEventSportSeason.SEASONTYPE_PLAYOFF

			'add second to last of first league
			playoffSeasons[i].AddTeam( leagues[i].GetCurrentSeason().GetTeamAtRank( -2 ) )
			'add second placed team of next league
			playoffSeasons[i].AddTeam( leagues[i+1].GetCurrentSeason().GetTeamAtRank( 2 ) )
'print "playoff #"+i+"  add from loosers in league "+i+": "+ leagues[i].GetCurrentSeason().GetTeamAtRank( -2 ).name
'print "playoff #"+i+"  add from winners in league "+(i+1)+": "+ leagues[i+1].GetCurrentSeason().GetTeamAtRank( 2 ).name
	
			playoffSeasons[i].data.matchPlan = new TNewsEventSportMatch[playoffSeasons[i].GetMatchCount()]

			CreateMatchSets(playoffSeasons[i].GetMatchCount(), playoffSeasons[i].GetTeams(), playoffSeasons[i].data.matchPlan, CreateMatch)

			for local match:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
'print "playoff #"+i+"  match: " + match.teams[0].name + " - " + match.teams[1].name 
				playoffSeasons[i].upcomingMatches.addLast(match)

				GetNewsEventSportCollection().AddMatch(match)
			next
		Next
	End Method


	Method AssignPlayoffTimes(time:Long = 0)
		local allPlayOffsTime:Long = time

		'playoff times use the "upper leagues" starting times
		local matches:int = 0
		For local i:int = 0 until playoffSeasons.length
			'reset time so all playoff-"seasons" start at the same time
			time = allPlayOffsTime
			'if time = 0 then time = leagues[i].GetNextMatchStartTime(time, True)

			local playoffsTime:Long = leagues[i].GetNextMatchStartTime(time, True)
			leagues[i].AssignMatchTimes(playoffSeasons[i], playoffsTime, True)

			?debug
				print " Create matches: League "+(i+1)+"->"+(i+2)
				local mIndex:int = 0
				For local m:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
					mIndex :+1
					print "  match #"+RSet(mIndex,2).Replace(" ", "0")+": "+ m.teams[0].nameInitials+"-"+m.teams[1].nameInitials
				Next
			?
		Next
	End Method	


	Method StartSeason:int(time:Long = 0)
		?debug
			print "Start Season: " + TTypeId.ForObject(self).Name()+"   time "+GetWorldTime().GetFormattedDate(time)
		?

		if time = 0 then time = GetWorldTime().GetTimeGone()

		for local l:TNewsEventSportLeague = Eachin leagues
			l.StartSeason(time)
			?debug
				print name+":  season matches: " + GetWorldTime().GetFormattedGameDate(l.GetNextMatchTime()) + "   -   " + GetWorldTime().GetFormattedGameDate(l.GetLastMatchTime())
			?
		Next

		EventManager.triggerEvent(TEventSimple.Create("Sport.StartSeason", new TData.AddNumber("time", time), Self))
	End Method


	Method FinishSeason()
		?debug
			print "Finish Season: " + TTypeId.ForObject(self).Name()
		?

		for local l:TNewsEventSportLeague = Eachin leagues
			l.FinishSeason()
		Next
		EventManager.triggerEvent(TEventSimple.Create("Sport.FinishSeason", null, Self))
	End Method


	Method ReadyForNextSeason:int()
		return IsSeasonFinished() and ArePlayoffsFinished()
	End Method


	Method IsSeasonStarted:int()
		for local l:TNewsEventSportLeague = Eachin leagues
			if not l.IsSeasonStarted() then return False
		Next
		return True
	End Method


	Method IsSeasonFinished:int()
		for local l:TNewsEventSportLeague = Eachin leagues
			if not l.IsSeasonFinished() then return False
		Next
		return True
	End Method


	Method ArePlayoffsRunning:int()
		return playoffsState = 1
	End Method


	Method ArePlayoffsFinished:int()
		return playoffsState = 2
	End Method
	

	Method AddLeague:TNewsEventSport(league:TNewsEventSportLeague)
		leagues :+ [league]
		league.sportGUID = self.GetGUID()
		league._leaguesIndex = leagues.length-1

		GetNewsEventSportCollection().AddLeague(league)

		EventManager.triggerEvent(TEventSimple.Create("Sport.AddLeague", New TData.add("league", league), Self))
	End Method


	Method ContainsLeague:int(league:TNewsEventSportLeague)
		For local l:TNewsEventSportLeague = EachIn leagues
			if l = league then return True
		Next
		return False
	End Method


	Method GetLeagueAtIndex:TNewsEventSportLeague(index:int)
		if index < 0 or index >= leagues.length then return Null
		return leagues[index]
	End Method


	Method GetLeagueByGUID:TNewsEventSportLeague(leagueGUID:string)
		for local l:TNewsEventSportLeague = EachIn leagues
			if l.GetGUID() = leagueGUID then return l
		next
		return null
	End Method


	Method GetMatchNameShort:string(match:TNewsEventSportMatch)
		return match.GetNameShort()
	End Method


	Method GetMatchReport:string(match:TNewsEventSportMatch)
		return match.GetReport()
	End Method


	Method GetNextMatchTime:Long()
		local lowestTime:long = -1
		For local league:TNewsEventSportLeague = EachIn leagues
			local lowestLeagueMatchTime:Long = league.GetNextMatchTime()
			if lowestTime = -1 or lowestLeagueMatchTime < lowestTime
				lowestTime = lowestLeagueMatchTime
			endif
		Next
		return lowestTime
	End Method


	Method GetFirstMatchTime:Long()
		local lowestTime:long = -1
		For local league:TNewsEventSportLeague = EachIn leagues
			local lowestLeagueMatchTime:Long = league.GetFirstMatchTime()
			if lowestTime = -1 or lowestLeagueMatchTime < lowestTime
				lowestTime = lowestLeagueMatchTime
			endif
		Next
		return lowestTime
	End Method
	

	Method GetLastMatchTime:Long()
		local latestTime:long = -1
		For local league:TNewsEventSportLeague = EachIn leagues
			local latestLeagueMatchTime:Long = league.GetLastMatchTime()
			if latestTime = -1 or latestLeagueMatchTime > latestTime
				latestTime = latestLeagueMatchTime
			endif
		Next
		return latestTime
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		local result:TNewsEventSportMatch[]
		For local l:TNewsEventSportLeague = EachIn leagues
			result :+ l.GetUpcomingMatches(minTime, maxTime)
		Next

		return result
	End Method


	Method GetUpcomingPlayoffMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		local result:TNewsEventSportMatch[]
		For local l:TNewsEventSportSeason = EachIn playoffSeasons
			result :+ l.GetUpcomingMatches(minTime, maxTime)
		Next

		return result
	End Method


	'helper: creates a "round robin"-matchset (all vs all)
	Function CreateMatchSets(matchCount:int, teams:TNewsEventSportTeam[], matchPlan:TNewsEventSportMatch[], createMatchFunc:TNewsEventSportMatch())
		if not createMatchFunc then createMatchFunc = CreateMatch

		local useTeams:TNewsEventSportTeam[] = teams[ .. teams.length]
		local useTeamIndices:int[] = new int[teams.length]
		local ghostTeam:TNewsEventSportTeam
		'if odd we add a ghost team
		if teams.length mod 2 = 1
			ghostTeam = new TNewsEventSportTeam
			useTeams :+ [ghostTeam]
		endif

		For local i:int = 0 until useTeams.length
			useTeamIndices[i] = i
		Next

		?debug
			print "CreateMatchSets:"
			print "  teams: "+teams.length
			print "  useTeams: "+useTeams.length
			print "  matchCount: "+matchCount
			For local i:int = 0 until useTeams.length
				useTeams[i].nameInitials = i
				if useTeams[i] = ghostTeam then useTeams[i].nameInitials = "G"
			Next
		?

		local teamAIndices:int[matchCount]
		local teamBIndices:int[matchCount]
		local matchNumber:int = 0


		'approach described here: http://spvgkade.de/ssonst/ssa0.html?haupt=Son&sub=PaT&sub=Root
		'results in: 1-4, 3-2   4-3, 2-1   2-4, 1-3
		for local roundNumber:int = 1 to useTeams.length-1
			for local roundMatchNumber:int = 1 to useTeams.length/2
				matchNumber :+ 1

				local GR:int = roundNumber mod 2 = 0
				local UR:int = roundNumber mod 2 = 1
				local team1Index:int
				local team2Index:int

				if roundNumber mod 2 = 0
					if roundMatchNumber = 1
						team1Index = useTeams.length - roundMatchNumber + 1
						team2Index = (useTeams.length + roundNumber)/2 - roundMatchNumber + 1
					else
						team1Index = (useTeams.length + roundNumber)/2 + roundMatchNumber - useTeams.length
						team2Index = (useTeams.length + roundNumber)/2 - roundMatchNumber + 1
						if team1Index < 1 then team1Index = team1Index + (useTeams.length-1)
					endif
				else
					if roundMatchNumber=1
						team1Index = (1 + roundNumber)/2 + roundMatchNumber - 1
						team2Index = useTeams.length + roundMatchNumber - 1
					else
						team1Index = (1 + roundNumber)/2 + roundMatchNumber - 1
						team2Index = (1 + roundNumber)/2 - roundMatchNumber + useTeams.length
						if team2Index > (useTeams.length-1) then team2Index = team2Index - (useTeams.length-1)
					endif
				endif

				'swap home/away
				if roundMatchNumber mod 2 = 0
					local tmp:int = team1Index
					team1Index = team2Index
					team2Index = tmp
				endif

				'home
				teamAIndices[ matchNumber-1 ] = team1Index-1
				teamBIndices[ matchNumber-1 ] = team2Index-1
				'away
				teamAIndices[ matchNumber-1 + matchCount/2 ] = team2Index-1
				teamBIndices[ matchNumber-1 + matchCount/2 ] = team1Index-1

				'print roundNumber+"/"+matchNumber+": " + team1Index + " - " + team2Index
			next
		next


		rem
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

		for local matchIndex:int = 0 until teamAIndices.length
			local teamA:TNewsEventSportTeam = useTeams[ teamAIndices[matchIndex] ]
			local teamB:TNewsEventSportTeam = useTeams[ teamBIndices[matchIndex] ]

			'skip matches with the ghost team
			if teamA = ghostTeam or teamB = ghostTeam then continue

			local match:TNewsEventSportMatch = createMatchFunc()
			match.matchNumber = matchIndex
			match.AddTeams( [teamA, teamB] )

			matchPlan[matchIndex] = match
			'print (teamA.nameInitials)+"-"+(teamB.nameInitials) + "  " + (teamAIndices[matchIndex]+1) +"-"+(teamBIndices[matchIndex]+1)
		Next

		?debug
		print " Create matches"
		local mIndex:int = 0
		For local m:TNewsEventSportMatch = EachIn matchPlan
			mIndex :+1
			print "  match #"+RSet(mIndex,2).Replace(" ", "0")+": "+ m.teams[0].nameInitials+"-"+m.teams[1].nameInitials
		Next
		?
	End Function


	Method GetMatchByGUID:TNewsEventSportMatch(guid:string)
	End Method


	Function CreateMatch:TNewsEventSportMatch()
		return new TNewsEventSportMatch
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
	


	Method InvalidateLeaderboard:int()
		_leaderboard = new TNewsEventSportLeagueRank[0]
	End Method


	Method SetTeams:int(teams:TNewsEventSportTeam[])
		'create reference to the array!
		'(modification to original modifies here too)
		'Maybe we should copy it?
		self.teams = teams
		return True
	End Method


	Method AddTeam:int(team:TNewsEventSportTeam)
		teams :+ [team]
		return True
	End Method


	Method GetTeams:TNewsEventSportTeam[]()
		return teams
	End Method


	Method GetTeamIndex:int(team:TNewsEventSportTeam)
		For local i:int = 0 until teams.length
			if teams[i] = team then return i
		Next
		return -1
	End Method


	Method GetTeamRank:int(team:TNewsEventSportTeam, upToMatchTime:Long = 0)
		local board:TNewsEventSportLeagueRank[] = GetLeaderboard(upToMatchTime)
		for local rankIndex:int = 0 until board.length
			if board[rankIndex].team = team then return rankIndex + 1
		Next
		return -1
	End Method
	

	Method GetTeamAtRank:TNewsEventSportTeam(rank:int, upToMatchTime:Long = 0)
		local board:TNewsEventSportLeagueRank[] = GetLeaderboard(upToMatchTime)
		if rank < 0
			return board[ board.length + rank ].team
		else
			return board[ rank - 1 ].team
		endif
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchTime:Long = 0)
		'return cache if possible
		if _leaderboard and _leaderboard.length = teams.length
			if upToMatchTime <> 0 or upToMatchTime = _leaderboardMatchTime
				return _leaderboard
			endif
		endif
		
		_leaderboard = new TNewsEventSportLeagueRank[teams.length]
		_leaderboardMatchTime = upToMatchTime

		'sum up the scores of each team in the matches
		For local match:TNewsEventSportMatch = EachIn matchPlan
			'create entries for all teams
			'ignore whether they played already or not
			for local team:TNewsEventSportTeam = Eachin match.teams
				local teamIndex:int = GetTeamIndex(team)
				'team not in the league?
				if teamIndex = -1 then continue

				if not _leaderboard[teamIndex]
					_leaderboard[teamIndex] = new TNewsEventSportLeagueRank
					_leaderboard[teamIndex].team = team
				endif
			Next

			'add scores

			'check if it is run somewhen in the past
			if not match.IsRun() then continue
			'upToMatchTime = 0 means, no limit on match time
			if upToMatchTime <> 0 and match.GetMatchTime() > upToMatchTime then continue

			for local team:TNewsEventSportTeam = Eachin match.teams
				local teamIndex:int = GetTeamIndex(team)
				'team not in the league?
				if teamIndex = -1 then continue

				_leaderboard[teamIndex].score :+ match.GetScore(team)
			Next
		Next

		'sort the leaderboard
		if _leaderboard.length > 1 then _leaderboard.sort(False)
		return _leaderboard
	End Method
End Type




Type TNewsEventSportSeason extends TGameObject
	Field data:TNewsEventSportSeasonData = new TNewsEventSportSeasonData
	Field started:int = False
	Field finished:int = True
	Field updateTime:Long 
	Field part:int = 0
	Field partMax:int = 2

	'contains to-come matches ordered according their matchTime
	Field upcomingMatches:TList
	'contains matches already run
	Field doneMatches:TList

	'for playoffs, this is empty
	Field leagueGUID:string
	Field sportGUID:string

	Field seasonType:int = 1
	Const SEASONTYPE_NORMAL:int = 1
	Const SEASONTYPE_PLAYOFF:int = 2


	Method GenerateGUID:string()
		return "NewsEventSportSeason-"+id
	End Method


	Method Init:TNewsEventSportSeason(leagueGUID:string, sportGUID:string)
		doneMatches = CreateList()
		upcomingMatches = CreateList()

		self.leagueGUID = leagueGUID
		self.sportGUID = sportGUID

		return self
	End Method


	Method Start(time:Long)
		data.startTime = time
		finished = False
		started = True

		'set all ranks to 0
		For local team:TNewsEventSportTeam = EachIn data.teams
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
	

	Method InvalidateLeaderboard:int()
		data.InvalidateLeaderboard()
	End Method


	Method SetTeams:int(teams:TNewsEventSportTeam[])
		local result:int = data.SetTeams(teams)

		'inform teams about the league
		For local team:TNewsEventSportTeam = EachIn data.teams
			team.AssignLeague(leagueGUID)
		Next

		return result
	End Method


	Method AddTeam:int(team:TNewsEventSportTeam)
		return data.AddTeam(team)
	End Method


	Method GetTeams:TNewsEventSportTeam[]()
		return data.GetTeams()
	End Method


	Method GetTeamAtRank:TNewsEventSportTeam(rank:int)
		return data.GetTeamAtRank(rank)
	End Method


	Method GetTeamRank:int(team:TNewsEventSportTeam, upToMatchTime:Long=0)
		return data.GetTeamRank(team, upToMatchTime)
	End Method


	Method RefreshTeamStats(upToMatchTime:Long=0)
		RefreshRanks(upToMatchTime)
		For local t:TNewsEventSportTeam = EachIn data.teams
			t.UpdateStats()
		Next
	End Method
	

	'assign the ranks of the given time as "current ranks" to the teams
	Method RefreshRanks(upToMatchTime:Long=0)
		local board:TNewsEventSportLeagueRank[] = data.GetLeaderboard(upToMatchTime)
		For local rankIndex:int = 0 until board.length
			board[rankIndex].team.currentRank = rankIndex+1
		Next
	End Method


	Method GetNextMatchTime:Long()
		local lowestTime:long = -1
		For local nextMatch:TNewsEventSportMatch = EachIn upcomingMatches
			if lowestTime = -1 or nextMatch.GetMatchTime() < lowestTime
				lowestTime = nextMatch.GetMatchTime()
			endif
		Next
		return lowestTime
	End Method


	Method GetFirstMatchTime:Long()
		local list:TList = doneMatches
		if list.Count() = 0 then list = upcomingMatches

		local lowestTime:long = -1
		For local nextMatch:TNewsEventSportMatch = EachIn list
			if lowestTime = -1 or nextMatch.GetMatchTime() < lowestTime
				lowestTime = nextMatch.GetMatchTime()
			endif
		Next
		return lowestTime
	End Method


	Method GetLastMatchTime:Long()
		local latestTime:long = -1
		For local nextMatch:TNewsEventSportMatch = EachIn upcomingMatches
			if latestTime = -1 or nextMatch.GetMatchTime() > latestTime
				latestTime = nextMatch.GetMatchTime()
			endif
		Next
		return latestTime
	End Method


	Method GetMatchCount:int(teamSize:int = -1)
		if teamSize = -1 then teamSize = GetTeams().length
		'each team fights all other teams - this means we need
		'(teams * (teamsAmount-1))/2 different matches

		'*2 to get "home" and "guest" matches
		return 2 * (teamSize * (teamSize-1)) / 2
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		local result:TNewsEventSportMatch[]
		For local match:TNewsEventSportMatch = EachIn upcomingMatches
			if match.GetMatchTime() < minTime then continue
			if maxTime <> -1 and match.GetMatchTime() > maxTime then continue

			result :+ [match]
		Next
		return result
	End Method
End Type


	

Type TNewsEventSportLeague extends TGameObject
	Field name:string
	Field nameShort:string

	'defines when matches take places
	'0 = monday, 2 = wednesday ...
	Field timeSlots:string[] = [ ..
	                            "0_14", "0_20", ..
	                            "2_14", "2_20", ..
	                            "4_14", "4_20", ..
	                            "5_14", "5_20" ..
	                           ]

	Field seasonJustBegun:int = False
    Field seasonStartMonth:int = 8
    Field seasonStartDay:int = 14
	Field matchesPerTimeSlot:int = 2

	'store all seasons of that league
	Field pastSeasons:TNewsEventSportSeasonData[]
	Field currentSeason:TNewsEventSportSeason
	'teams in then nex season (maybe after relegation matches)
	Field nextSeasonTeams:TNewsEventSportTeam[]

	'guid of the parental sport
	Field sportGUID:string = ""
	'index of this league in the parental sport
	Field _leaguesIndex:int = 0
	
	'callbacks
	Field _onRunMatch:int(league:TNewsEventSportLeague, match:TNewsEventSportMatch) {nosave}
	Field _onStartSeason:int(league:TNewsEventSportLeague) {nosave}
	Field _onFinishSeason:int(league:TNewsEventSportLeague) {nosave}
	Field _onFinishSeasonPart:int(league:TNewsEventSportLeague, part:int) {nosave}
	Field _onStartSeasonPart:int(league:TNewsEventSportLeague, part:int) {nosave}


	Method Init:TNewsEventSportLeague(name:string, nameShort:string, initialSeasonTeams:TNewsEventSportTeam[])
		self.name = name
		self.nameShort = nameShort
		self.nextSeasonTeams = initialSeasonTeams
	
		return self
	End Method


	Method GetNextSeasonTeamIndex:int(team:TNewsEventSportTeam)
		For local i:int = 0 until nextSeasonTeams.length
			if nextSeasonTeams[i] and nextSeasonTeams[i] = team then return i
		Next
		return -1
	End Method


	Method ReplaceNextSeasonTeam:int(oldTeam:TNewsEventSportTeam, newTeam:TNewsEventSportTeam)
		local nextSeasonTeamIndex:int = GetNextSeasonTeamIndex(oldTeam)
		if nextSeasonTeamIndex >= 0
			nextSeasonTeams[nextSeasonTeamIndex] = newTeam
			return True
		endif
		return False
	End Method


	Method AddNextSeasonTeam:int(team:TNewsEventSportTeam)
		if not team then return false
		nextSeasonTeams :+ [team]
		return True
	End Method


	Method RemoveNextSeasonTeam:int(team:TNewsEventSportTeam)
		local newNextSeasonTeams:TNewsEventSportTeam[]
		For local t:TNewsEventSportTeam = EachIn nextSeasonTeams
			if team = t then continue
			newNextSeasonTeams :+ [t]
		Next
		nextSeasonTeams = newNextSeasonTeams
		return True
	End Method
	

	Method GetNextMatchTime:Long()
		return GetCurrentSeason().GetNextMatchTime()
	End Method


	Method GetFirstMatchTime:Long()
		return GetCurrentSeason().GetFirstMatchTime()
	End Method


	Method GetLastMatchTime:Long()
		return GetCurrentSeason().GetLastMatchTime()
	End Method

	
	'playoffs should ignore season breaks (season end / winter break)


	Method GetNextMatchStartTime:Long(time:Long = 0, ignoreSeasonBreaks:int = False)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		local weekday:int = GetWorldTime().GetWeekday( time )
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
		For local t:string = EachIn timeSlots
			local information:string[] = t.Split("_")
			local weekdayIndex:int = int(information[0]) mod 7
			local hour:int = 0
			if information.length > 1 then hour = int(information[1])

			'the same day => next possible hour
			if GetWorldTime().GetWeekday(time) = weekdayIndex
				'earlier or at least before xx:05
				if GetWorldTime().GetDayHour(time) < hour or (GetWorldTime().GetDayHour(time) = hour and GetWorldTime().GetDayMinute(time) < 5)
					matchDay = 0
					matchHour = hour
					exit
				endif
			endif

			'future day => earliest hour that day
			if GetWorldTime().GetWeekday(time) < weekdayIndex
				matchDay = weekdayIndex - GetWorldTime().GetWeekday(time)
				matchHour = hour
'if name = "Regionalliga" then print "  future day "+matchDay+" at " + matchHour+":00"+ "   " + t +"  weekdayIndex="+weekdayIndex +"  weekday="+GetWorldTime().GetWeekday(time)
				exit
			endif
				
			if matchHour <> -1 then exit
		Next
		'if nothing was found yet, we might have had a time after the
		'last time slot -- so use the first one
		if matchHour = -1 and timeSlots.length > 0
			local information:string[] = timeSlots[0].Split("_")
			matchDay = GetWorldTime().GetDaysPerWeek() + int(information[0]) - GetWorldTime().GetWeekday(time)
			matchHour = 0
			if information.length > 1 then matchHour = int(information[1])
'if name = "Regionalliga" then print "  next week at day "+matchDay+" at " + matchHour+":00"
		endif



		local matchTime:Long = 0
		'match time: 14. 8. - 14.5.
		'winter break: 21.12. - 21.1.


		local firstDayStartHour:int = 0
		if timeSlots.length > 0
			local firstTime:string[] = timeSlots[0].Split("_")
			if firstTime.length > 1 then firstDayStartHour = int(firstTime[1])
		endif


		'always start at xx:05 (eases the pain for programmes)
		matchTime = GetWorldTime().MakeTime(0, GetWorldTime().GetDay(time) + matchDay, matchHour, 5)

		'check if we are in winter now
		if not ignoreSeasonBreaks
			local winterBreak:int = False
			local monthCode:int = int((RSet(GetWorldTime().GetMonth(matchTime),2) + RSet(GetWorldTime().GetDayOfMonth(matchTime),2)).Replace(" ", 0))
			'from 5th of december
			if 1220 < monthCode then winterBreak = True
			'disabled - else we start maybe in april because 22th of january
			'might be right after the latest hour of the game day
			'till 22th of january
			'if  122 > monthCode then winterBreak = True

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
				'calculate next possible match time (after winter break)
				matchTime = GetNextMatchStartTime(t)
'if name = "Regionalliga" then print "   -> winterbreak delay"
			endif
		endif
		
		seasonJustBegun = False

'if name = "Regionalliga" then print "   -> day="+GetWorldTime().GetDay(matchTime) +"  " +GetWorldTime().GetDayName(GetWorldTime().GetWeekday(matchTime))+" ["+GetWorldTime().GetWeekday(matchTime)+"]  at "+GetWorldTime().GetFormattedTime(matchTime)

		return matchTime
	End Method


	Method GetDoneMatchesCount:int()
		if GetCurrentSeason() and GetCurrentSeason().doneMatches
			return GetCurrentSeason().doneMatches.Count()
		endif
		return 0
	End Method


	Method GetUpcomingMatchesCount:int()
		if GetCurrentSeason() and GetCurrentSeason().upcomingMatches
			return GetCurrentSeason().upcomingMatches.Count()
		endif
		return 0
	End Method


	Method GetCurrentSeason:TNewsEventSportSeason()
		return currentSeason
	End Method


	Method GetSport:TNewsEventSport()
		if sportGUID then return GetNewsEventSportCollection().GetByGUID(sportGUID)
		return null
	End Method


	Method Update:int(time:Long = 0)
		if not GetCurrentSeason() then return False
		if GetCurrentSeason().upcomingMatches.Count() = 0 then return False

		if time = 0 then time = Long(GetWorldTime().GetTimeGone())

		'starting a new group?
rem
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

		local matchesRun:int = 0
'		if startingMatchGroup
			'if _onStartMatchGroup then _onStartMatchGroup(self, nextMatch.GetMatchTime())
			'EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartMatchGroup", New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match), Self))

			local endingMatchTime:Long
			local runMatches:TNewsEventSportMatch[]
			For local nextMatch:TNewsEventSportMatch = EachIn GetCurrentSeason().upcomingMatches
				if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					GetCurrentSeason().updateTime = nextMatch.GetMatchTime()

					'invalidate table
					GetCurrentSeason().InvalidateLeaderboard()

					'begin season half ?
					if GetCurrentSeason().doneMatches.Count() = 0
						StartSeasonPart(1)
					elseif GetCurrentSeason().upcomingMatches.Count() = GetCurrentSeason().doneMatches.Count()
						StartSeasonPart(2)
					endif

					RunMatch(nextMatch)

					'finished season part ?
					if GetCurrentSeason().upcomingMatches.Count() = GetCurrentSeason().doneMatches.Count()
						FinishSeasonPart(1)
					endif

					runMatches :+ [nextMatch]

					endingMatchTime = max(endingMatchTime, nextMatch.GetMatchTime())
					matchesRun :+ 1
				endif
			Next

			if runMatches.length > 0
				'refresh team stats for easier retrieval
				GetCurrentSeason().RefreshTeamStats(endingMatchTime)
			
				if endingMatchTime = 0 then endingMatchTime = GetWorldTime().GetTimeGone()
				EventManager.triggerEvent(TEventSimple.Create("SportLeague.FinishMatchGroup", New TData.add("matches", runMatches).AddNumber("time", endingMatchTime).Add("season", GetCurrentSeason()), Self))
			endif
'		endif

		'finish season?
		if GetCurrentSeason().upcomingMatches.Count() = 0
			if not IsSeasonFinished()
				'season 2/2 => also finishs whole season
				FinishSeasonPart(2)
			endif
			return False
		endif
		
		return matchesRun
	End Method


	Method StartSeason:int(time:Long = 0)
		seasonJustBegun = True

		if time = 0 then time = Long(GetWorldTime().GetTimeGone())

		'archive old season
		if currentSeason then pastSeasons :+ [currentSeason.data]

		'create and start new season
		currentSeason = new TNewsEventSportSeason.Init(self.GetGUID(), sportGUID)
		currentSeason.Start(time)

		'set teams
		if nextSeasonTeams.length > 0
			currentSeason.SetTeams(nextSeasonTeams)
		else
			Throw "next season teams missing"
		endif

		'let each one play versus each other
		'print "Create Upcoming Matches"
		CreateUpcomingMatches()
		'print "Assign Match Times"
		local seasonStart:Long = GetSeasonStartTime(time)
'print "SeasonStart: "  + GetworldTime().GetFormattedDate(seasonStart) +"  now=" +GetworldTime().GetFormattedDate(time)
		AssignMatchTimes(currentSeason, GetNextMatchStartTime(seasonStart))
		'sort the upcoming matches by match time (ascending)
		currentSeason.upcomingMatches.Sort(true, SortMatchesByTime)

		'debug
		'For local m:TNewsEventSportMatch = EachIn upcomingMatches
		'	print "  match #"+RSet(m.matchNumber,2).Replace(" ", "0")+": "+ m.teams[0].nameShort+"-"+m.teams[1].nameShort +"   d:"+GetWorldTime().GetDaysRun(m.GetMatchTime())+".  "+.GetWorldTime().GetFormattedDate(m.GetMatchTime())
		'Next

		if _onStartSeason then _onStartSeason(self)

		EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartSeason", new TData.AddNumber("time", time), Self))
	End Method


	Method FinishSeason:int()
		if not GetCurrentSeason() then return False
		GetCurrentSeason().Finish(GetCurrentSeason().updateTime)

		if _onFinishSeason then _onFinishSeason(self)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.FinishSeason", new TData.AddNumber("time", GetCurrentSeason().updateTime), Self))
	End Method


	Method StartSeasonPart:int(part:int)
		if not GetCurrentSeason() then return False
		GetCurrentSeason().part = part

		if _onStartSeasonPart then _onStartSeasonPart(self, part)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.StartSeasonPart", new TData.AddNumber("part", part).AddNumber("time", GetCurrentSeason().updateTime), Self))
	End Method


	Method FinishSeasonPart:int(part:int)
		if _onFinishSeasonPart then _onFinishSeasonPart(self, part)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.FinishSeasonPart", new TData.AddNumber("part", part).AddNumber("time", GetCurrentSeason().updateTime), Self))
		if GetCurrentSeason() and part = GetCurrentSeason().partMax then FinishSeason()
	End Method
	

	Method IsSeasonStarted:int()
		if not GetCurrentSeason() then return False

		return GetCurrentSeason().started
	End Method
	

	Method IsSeasonFinished:int()
		if not GetCurrentSeason() then return False

		return GetCurrentSeason().finished
	End Method


	Method GetMatchProgress:Float()
		if not GetCurrentSeason() then return 0.0
		
		if GetCurrentSeason().upcomingMatches.Count() = 0 then return 1.0
		if GetCurrentSeason().doneMatches.Count() = 0 then return 0.0
		return GetCurrentSeason().doneMatches.Count() / (GetCurrentSeason().doneMatches.Count() + GetCurrentSeason().upcomingMatches.Count())
	End Method


	Method GetTeamCount:int()
		return GetCurrentSeason().GetTeams().length
	End Method


	Method GetMatchCount:int()
		return GetCurrentSeason().GetMatchCount()
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long = -1)
		return GetCurrentSeason().GetUpcomingMatches(minTime, maxTime)
	End Method


	Method CreateUpcomingMatches:int()
		if not GetCurrentSeason() then return False

		'setup match plan array (if not done)
		if not GetCurrentSeason().data.matchPlan then GetCurrentSeason().data.matchPlan = new TNewsEventSportMatch[GetCurrentSeason().GetMatchCount()]
		local matchPlan:TNewsEventSportMatch[] = GetCurrentSeason().data.matchPlan

'		TNewsEventSport_Soccer.CreateMatchSets(GetCurrentSeason().GetMatchCount(), GetCurrentSeason().GetTeams(), GetCurrentSeason().data.matchPlan, TNewsEventSport_Soccer.CreateMatch)
		Custom_CreateUpcomingMatches()

		for local match:TNewsEventSportMatch = EachIn GetCurrentSeason().data.matchPlan
			GetCurrentSeason().upcomingMatches.addLast(match)

			GetNewsEventSportCollection().AddMatch(match)
		next		
	End Method


	Method Custom_CreateUpcomingMatches:int() abstract


	'adjust the given time if the first match of a season cannot start
	'before a given time
	Method GetSeasonStartTime:Long(time:Long)
		return time
	End Method
	

	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Long = 0, isPlayoffSeason:int = False)
		if time = 0 then time = GetNextMatchStartTime(time)
		if not season then season = GetCurrentSeason()

		For local m:TNewsEventSportMatch = EachIn season.data.matchPlan
			m.SetMatchTime(time)
			time = GetNextMatchStartTime(time)
		Next
	End Method
	

	Function SortMatchesByTime:int(o1:object, o2:object)
		local m1:TNewsEventSportMatch = TNewsEventSportMatch(o1)
		local m2:TNewsEventSportMatch = TNewsEventSportMatch(o2)

		if m1 and not m2 then return 1
		if not m1 and m2 then return -1
		if not m1 and not m2 then return 0

		if m1.GetMatchTime() < m2.GetMatchTime() then return -1 
		if m1.GetMatchTime() > m2.GetMatchTime() then return 1
		return 0 
	End Function


	Method RunMatch:int(match:TNewsEventSportMatch, matchTime:Long = -1)
		if not match then return False
		if not GetCurrentSeason() or GetCurrentSeason().finished then return False

		'override match start time
		if matchTime <> -1 then match.SetMatchTime(matchTime)

		GetCurrentSeason().upcomingMatches.Remove(match)
		match.Run()
		GetCurrentSeason().doneMatches.AddLast(match)

		if _onRunMatch then _onRunMatch(self, match)
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.RunMatch", New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match).Add("season", GetCurrentSeason()), Self))

		return True
	End Method


	Method GetLastMatch:TNewsEventSportMatch()
		if not GetCurrentSeason() then return null
		if not GetCurrentSeason().doneMatches or GetCurrentSeason().doneMatches.Count() = 0 then return null
		return TNewsEventSportMatch(GetCurrentSeason().doneMatches.Last())
	End Method


	Method GetNextMatch:TNewsEventSportMatch()
		if not GetCurrentSeason() then return null
		if not GetCurrentSeason().upcomingMatches or GetCurrentSeason().upcomingMatches.Count() = 0 then return null
		return TNewsEventSportMatch(GetCurrentSeason().upcomingMatches.First())
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchTime:Long = 0)
		If not GetCurrentSeason() then return null

		return GetCurrentSeason().data.GetLeaderboard(upToMatchTime)
	End Method
End Type



Type TNewsEventSportLeagueRank
	Field score:int
	Field team:TNewsEventSportTeam

	Method Compare:int(o:object)
		local other:TNewsEventSportLeagueRank = TNewsEventSportLeagueRank(o)
		if other
			if score > other.score then return 1
			if score < other.score then return -1
		endif
		return Super.Compare(other)
	End Method
End Type



Type TNewsEventSportMatch extends TGameObject
	Field teams:TNewsEventSportTeam[]
	Field points:int[]
	'csv-like score entries: "time,teamIndex,score|time,teamIndex,score..."
	'custom sports might also do: "time,teamIndex,score,memberIndex|..."
	Field scores:string
	Field scoresArray:string[] {nosave}
	Field duration:int = 90*60 'in seconds
	'when the match takes place
	Field matchTime:Long
	'when a potential break takes place
	Field breakTimes:int[] = [45*60]
	Field breakDuration:int = 15*60

	Field sportName:string

	Field matchNumber:int
	Field matchState:int = STATE_NORMAL
	Const STATE_NORMAL:int = 0
	Const STATE_RUN:int = 1


	Method Run:int()
		AdjustDurationAndBreakTimes()

		CalculateTotalScore()

		'distribute scores along the match time
		FillScores()
		
		matchState = STATE_RUN
	End Method


	Method AdjustDurationAndBreakTimes()
		local overtime:int = 60 * BiasedRandRange(0,8, 0.3)
		duration :+ overtime

		if breakTimes.length > 0
			local breakTime:int = duration / breakTimes.length
			local overtimePart:int = overtime / breakTimes.length
			for local i:int = 0 until breakTimes.length
				breakTimes[i] = breakTime + overtimePart
				'prepend previous breaktime
				'ex. [0] = 30+2  [1] = 30+3 + 32   [2] = 30+2 + 65 ... 
				if i > 0 then breakTimes[i] :+ breakTimes[i-1]
			Next
			'add rest of overtime to last break
			breakTimes[breakTimes.length-1] :+ (overtime - overtimePart*breakTimes.length)
		endif
	End Method


	Method CalculateTotalScore()
		'calculate total scores
		For local i:int = 0 until points.length
			points[i] = BiasedRandRange(0, 8, 0.18)
		Next
	End Method


	Method FillScores()
		scoresArray = new String[0]
		local scoresArrayIndex:int = 0

		For local teamIndex:int = 0 until points.length
			if points[teamIndex] <= 0 then continue

			'resize so that all scores fit
			scoresArray = scoresArray[ .. scoresArray.length + points[teamIndex] ]

			For local point:int = 0 until points[teamIndex]
				'store time as "000123" so it string-sorts correctly
				scoresArray[ scoresArrayIndex ] = RSet(RandRange(0, duration),6).Replace(" ", "0") + "," + teamIndex + ",1"
				scoresArrayIndex :+ 1
			Next
		Next
		scores = "|".Join(scoresArray)

		scoresArray.Sort(True)
		scores = "|".Join(scoresArray)
	End Method


	Function CreateMatch:TNewsEventSportMatch()
		return new TNewsEventSportMatch
	End Function


	Method AddTeam(team:TNewsEventSportTeam)
		teams :+ [team]
		points = points[ .. points.length + 1]
	End Method


	Method AddTeams(teams:TNewsEventSportTeam[])
		self.teams :+ teams
		points = points[ .. points.length + teams.length]
	End Method


	Method SetMatchTime(time:Long)
		matchTime = time
	End Method


	Method GetMatchTime:Long()
		return matchTime
	End Method


	Method GetMatchEndTime:Long()
		return matchTime + duration + GetTotalBreakTime()
	End Method


	Method GetTotalBreakTime:int()
		local res:int
		For local i:int = 0 until breakTimes.length
			res :+ breakTimes[i]
		Next
		return res
	End Method
	

	Method GetScore:int(team:TNewsEventSportTeam)
		if not IsRun() then return 0

		if GetRank(team) = 1 then return GetWinnerScore()
		return GetLooserScore()
	End Method


	Method GetRank:int(team:TNewsEventSportTeam)
		if not IsRun() then return 0

		local rank:int = 1
		For local i:int = 0 until teams.length
			if teams[i] <> team then continue
			
			'count better ranked teams
			For local j:int = 0 until teams.length
				if i = j then continue
				if points[j] > points[i] then rank :+ 1
			Next
		Next
		return rank
	End Method


	Method IsRun:int()
		return matchState = STATE_RUN
'		if matchTime = -1 then return False
'		return matchTime < time
	End Method


	Method HasLooser:int()
		if not IsRun() then return False
		if not points or points.length = 0 then return False

		'check if one of the teams has less points than the others
		local lastPoint:int = points[0]
		for local point:int = EachIn points
			if point <> lastPoint then return True
		Next
		return False
	End Method


	Method HasWinner:int()
		if not IsRun() then return False
		return GetWinner() <> -1
	End Method


	Method GetWinner:int()
		if not IsRun() then return -1
		if not points or points.length = 0 then return -1

		'check if one of the teams has most points
		local bestPoint:int = points[0]
		local bestPointCount:int = 0
		local bestTeam:int = 0
		if points.length > 1
			for local i:int = 1 until points.length
				if points[i] = bestPoint
					bestPointCount :+ 1
				elseif points[i] > bestPoint
					bestPoint = points[i]
					bestPointCount = 0
					bestTeam = i
				endif
			Next
		endif

		if bestPointCount = 0 then return bestTeam
		return -1
	End Method


	Method GetWinnerScore:int()
		return 2
	End Method


	Method GetDrawGameScore:int()
		return 1
	End Method


	Method GetLooserScore:int()
		return 0
	End Method
	

	Method GetNameShort:string()
		local result:string
		for local i:int = 0 until points.length
			if result <> "" then result :+ " - "
			result :+ teams[i].GetTeamNameShort()
		Next
		return result
	End Method


	Method GetReport:string()
		return "override GetReport()"
	End Method

	Method GetLiveReportShort:string(mode:string="", time:Long=-1)
		return "override GetLiveReportShort()"
	End Method

	Method GetReportShort:string(mode:string="")
		return "override GetReportShort()"
	End Method


	Method GetMatchTimeGone:int(time:Long=-1)
		if time = -1 then time = GetWorldTime().GetTimeGone()
		local timeGone:Int = Max(0, time - GetMatchTime())
		local matchTime:Int = timeGone

		For local i:int = 0 until breakTimes.length
			if timeGone >= breakTimes[i]
				'currently within a break?
				if timeGone <= breakTimes[i] + breakDuration
					matchTime = breakTimes[i]
				else
					matchTime :- breakDuration
				endif
			else
				'did not reach that breaktime yet
				exit
			endif
		Next
		return matchTime
	End Method

	
	Method GetMatchResultText:string()
		local singularPlural:string = "P"
		if teams[0].clubNameSingular then singularPlural = "S"

		local result:string = ""

		if points[0] > points[1]
			if sportName <> ""
				result = GetRandomLocale2(["SPORT_"+sportName+"_TEAMREPORT_MATCHWIN_" + singularPlural, "SPORT_TEAMREPORT_MATCHWIN_" + singularPlural])
			else
				result = GetRandomLocale("SPORT_TEAMREPORT_MATCHWIN_" + singularPlural)
			endif
		elseif points[0] < points[1]
			if sportName <> ""
				result = GetRandomLocale2(["SPORT_"+sportName+"_TEAMREPORT_MATCHLOOSE_" + singularPlural, "SPORT_TEAMREPORT_MATCHLOOSE_" + singularPlural])
			else
				result = GetRandomLocale("SPORT_TEAMREPORT_MATCHLOOSE_" + singularPlural)
			endif
		else
			if sportName <> ""
				result = GetRandomLocale2(["SPORT_"+sportName+"_TEAMREPORT_MATCHDRAW_" + singularPlural, "SPORT_TEAMREPORT_MATCHDRAW_" + singularPlural])
			else
				result = GetRandomLocale("SPORT_TEAMREPORT_MATCHDRAW_" + singularPlural)
			endif
		endif

		return result
	End Method


	Method GetMatchScore:int[](matchTime:int)
		if not scoresArray then scoresArray = scores.split("|")

		local matchScore:int[] = new Int[points.length]
		For local scoreEntry:string = EachIn scoresArray
			local scoreParts:string[] = scoreEntry.split(",")
			'invalid or not yet happened
			if scoreParts.length < 3 or int(scoreParts[0]) > matchTime then continue

			local teamIndex:int = int(scoreParts[1])
			if teamIndex < 0 or teamIndex >= matchScore.length then continue

			matchScore[teamIndex] :+ int(scoreParts[2])
		Next

		return matchScore
	End Method


	Method GetFinalScoreText:string()
		return StringHelper.JoinIntArray(":", points)
	End Method


	Method ReplacePlaceholders:string(value:string)
		local result:string = value
		if result.Find("%MATCHRESULT%") >= 0
			result = result.Replace("%MATCHRESULT%", GetMatchResultText() )
		endif

		if result.Find("%MATCHSCORE") >= 0
			for local i:int = 1 to teams.length
				if result.Find("%MATCHSCORE"+i) >= 0
					local points:int = GetScore( teams[i-1] )
					if points = 1
						result = result.Replace("%MATCHSCORE"+i+"TEXT%", points + " " + GetLocale("SCORE_POINT") )
					else
						result = result.Replace("%MATCHSCORE"+i+"TEXT%", points + " " + GetLocale("SCORE_POINTS") )
					endif

					result = result.Replace("%MATCHSCORE"+i+"%", points)
				endif
			Next
		endif

		if result.Find("%MATCHSCOREMAX") >= 0
			local points:int = GetWinnerScore()
			result = result.Replace("%MATCHSCOREMAX%", points)
			if points = 1
				result = result.Replace("%MATCHSCOREMAXTEXT%", points + " " + GetLocale("SCORE_POINT"))
			else
				result = result.Replace("%MATCHSCOREMAXTEXT%", points + " " + GetLocale("SCORE_POINTS"))
			endif
		endif

		if result.Find("%MATCHSCOREDRAWGAME") >= 0
			local points:int = GetDrawGameScore()
			result = result.Replace("%MATCHSCOREDRAWGAME%", points)
			if points = 1
				result = result.Replace("%MATCHSCOREDRAWGAMETEXT%", points + " " + GetLocale("SCORE_POINT"))
			else
				result = result.Replace("%MATCHSCOREDRAWGAMETEXT%", points + " " + GetLocale("SCORE_POINTS"))
			endif
		endif

		if result.Find("%MATCHKIND%") >= 0
			if RandRange(0,10) < 7
				result = result.Replace("%MATCHKIND%", GetRandomLocale("SPORT_TEAMREPORT_MATCHKIND"))
			else
				result = result.Replace("%MATCHKIND%", "")
			endif
		endif

		for local i:int = 1 to teams.length
			if result.Find("%TEAM"+i) < 0 then continue

			 teams[i-1].FillPlaceholders(result, string(i))
		Next

		if result.Find("%FINALSCORE%") >= 0
			result = result.Replace("%FINALSCORE%", GetFinalScoreText())
		endif

		result = result.Replace("%PLAYTIMEMINUTES%", int(duration / 60) )

		result = result.Trim().Replace("  ", " ") 'remove space if no team article...
		
		return result
	End Method
End Type




Type TNewsEventSportTeam
	'eg. "Exampletown"
	Field city:string
	'eg. "Saxony Exampletown"
	Field name:string
	'eg. "SE"
	Field nameInitials:string
	'eg. "Football club"
	Field clubName:string
	'eg. "Goalies"
	Field clubNameSuffix:string
	'eg. "FC"
	Field clubNameInitials:string
	'eg. "G"
	Field clubNameSuffixInitials:string
	'if singular, in German the "Der" is used, else "Die"
	'-> "Der Klub" (the club), "Die Kicker" (the kickers)
	Field clubNameSingular:int

	Field members:TNewsEventSportTeamMember[]
	Field trainer:TNewsEventSportTeamMember

	Field statsPower:Float = -1
	Field statsAttractivity:Float = -1
	Field statsSkill:Float = -1
	'start values
	Field statsAttractivityBase:Float = 0.5
	Field statsPowerBase:Float = 0.5
	Field statsSkillBase:Float = 0.4

	Field currentRank:int = 0
	Field leagueGUID:string
	Field sportGUID:string


	Method SetTrainer:TNewsEventSportTeam(trainer:TNewsEventSportTeamMember)
		self.trainer = trainer
	End Method


	Method GetTrainer:TNewsEventSportTeamMember()
		return trainer
	End Method


	Method AddMember:TNewsEventSportTeam(member:TNewsEventSportTeamMember)
		members :+ [member]
	End Method


	Method GetMemberAtIndex:TNewsEventSportTeamMember(index:int)
		if index < 0 then index = members.length + index '-1 = last one
		if index < 0 or index >= members.length then return Null
		return members[index]
	End Method


	Method GetCity:string()
		return city
	End Method


	Method GetTeamName:string()
		if clubNameSuffix and clubName
			return clubName + " " + name + " " + clubNameSuffix
		elseif clubNameSuffix and not clubName
			return name + " " + clubNameSuffix
		else
			return clubName + " " + name
		endif
	End Method


	Method GetTeamNameShort:string()
		'no short name possible for "Cityname Sharks"
		if clubNameSuffix
			return GetTeamName()
		else
			return clubNameInitials + " " + name
		endif
	End Method


	Method GetTeamInitials:string()
		return clubNameInitials + nameInitials + clubNameSuffixInitials
	End Method


	Method RandomizeBasicStats(leagueIndex:int = 0)
		local leagueMod:int = (leagueIndex = 0)*10 + (leagueIndex = 1)*6 + (leagueIndex = 2)*4 - (leagueIndex = 3)*4
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
		return (THelper.logisticFunction(1.0 - percentage/zeroPercentage, 1.0, 4 ) - 0.5) * 2

		'-0.00001 to avoid "-0.00000000" for percentage=zeroPercentage
	'	return -sgn(percentage-0.5 - 0.00001) * 5*(1 - 1.0/((percentage - 0.5)^2+1))
	End Function


	Method GetAttractivity:Float()
		if statsAttractivity = -1
			'basic attractivity
			statsAttractivity = statsAttractivityBase

			local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			if league
				Select league._leaguesIndex
					case 0   statsAttractivity :+ 0.40
					case 1   statsAttractivity :+ 0.15
					case 2   statsAttractivity :- 0.05
					default  statsAttractivity :- 0.20
				End Select

				if currentRank <> 0
					statsAttractivity :+ 0.2 * GetDistributionCurveValue(float(currentRank) / league.GetTeamCount(), 0.6)

					'first and last get extra bonus/penalty
					if currentRank = 1 then statsAttractivity :+ 0.1
					if currentRank = league.GetTeamCount() then statsAttractivity :- 0.05
				endif
			endif
			statsAttractivity = MathHelper.Clamp(statsAttractivity, 0.0, 1.0)
		endif

		return statsAttractivity
	End Method


	Method GetPower:Float()
		if statsPower = -1
			statsPower = statsPowerBase
			local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			if league
				Select league._leaguesIndex
					case 0   statsPower :+ 0.40
					case 1   statsPower :+ 0.15
					case 2   statsPower :- 0.05
					default  statsPower :- 0.15
				End Select
				if currentRank <> 0
					statsPower :+ 0.2 * GetDistributionCurveValue(float(currentRank) / league.GetTeamCount(), 0.7)
				endif
			endif

			statsPower = MathHelper.Clamp(statsPower, 0.0, 1.0)
		endif

		return statsPower
	End Method


	Method GetSkill:Float()
		if statsSkill = -1
			statsSkill = statsSkillBase
			local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			if league
				Select league._leaguesIndex
					case 0   statsSkill :+ 0.40
					case 1   statsSkill :+ 0.15
					case 2   statsSkill :- 0.05
					default  statsSkill :- 0.15
				End Select

				if currentRank <> 0
					'adjusted and negated formula of f(x) = 1/((x+a)^2+1)
					'a=displacement, adjustment:  to have "after displacement" become negative
					'adjusted is f(x) = -sgn(x+a) * 1/((x+a)^2+1)
					'statsSkill :+ 0.2 * -sgn((currentRank - league.GetTeamCount()/3.0)) + (1 - 1/((currentRank - league.GetTeamCount()/3.0)^2 + 1))

					statsSkill :+ 0.2 * GetDistributionCurveValue(float(currentRank) / league.GetTeamCount(), 0.6)
				endif
			endif

			'print Lset(GetTeamName(), 15)+": statsSkill="+ statsSkill
			statsSkill = MathHelper.Clamp(statsSkill, 0.0, 1.0)
		endif

		return statsSkill
	End Method
	

	Method AssignLeague(leagueGUID:string)
		self.leagueGUID = leagueGUID
	End Method


	Method AssignSport(sportGUID:string)
		self.sportGUID = sportGUID
	End Method


	Method GetLeague:TNewsEventSportLeague()
		if not leagueGUID then return null

		'try to find league the easy way
		local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
		if league then return league

		'try it the indirect way
		if not sportGUID then return null

		local sport:TNewsEventSport = GetNewsEventSportCollection().GetByGUID(sportGUID)
		if sport then return sport.GetLeagueByGUID(leagueGUID)

		return null
	End Method


	Method FillPlaceholders(value:string var, teamIndex:string="")
		if value.Find("%TEAM"+teamIndex+"%") >= 0
			if RandRange(0,100) < 75
				value = value.Replace("%TEAM"+teamIndex+"%", GetTeamName())
			else
				value = value.Replace("%TEAM"+teamIndex+"%", clubNameInitials +" "+ name)
			endif
		endif
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

		if value.Find("%TEAM"+teamIndex+"ARTICLE") >= 0
			if clubNameSingular
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE1%", GetLocale("SPORT_TEAMNAME_S_VARIANT_A") )
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE2%", GetLocale("SPORT_TEAMNAME_S_VARIANT_B") )
			else
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE1%", GetLocale("SPORT_TEAMNAME_P_VARIANT_A") )
				value = value.Replace("%TEAM"+teamIndex+"ARTICLE2%", GetLocale("SPORT_TEAMNAME_P_VARIANT_B") )
			endif
		endif

	End Method
End Type




Type TNewsEventSportTeamMember Extends TProgrammePersonBase
	Field teamGUID:string

	Method Init:TNewsEventSportTeamMember(firstName:string, lastName:string, countryCode:string, gender:int = 0, fictional:int = False)
		self.firstName = firstName
		self.lastName = lastName
		self.SetGUID("sportsman-"+id)
		self.countryCode = countryCode
		self.gender = gender
		self.fictional = fictional
		return self
	End Method


	Method AssignTeam(teamGUID:string)
		self.teamGUID = teamGUID
	End Method
End Type