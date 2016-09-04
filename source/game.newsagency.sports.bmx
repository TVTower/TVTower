SuperStrict
Import "game.world.worldtime.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "game.programme.programmeperson.base.bmx"

Type TNewsEventSportCollection extends TGameObjectCollection
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


	Method UpdateAll:int()
		For local sport:TNewsEventSport = EachIn entries.Values()
			sport.Update()
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


	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = "NewsEventSport-"+id
		self.GUID = GUID
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
			AssignPlayoffTimes( GetWorldTime().GetTimeGone() + GetWorldTime().DAYLENGTH)

			StartPlayoffs()
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

		For local season:TNewsEventSportSeason = EachIn playoffSeasons
			if not season.upcomingMatches then continue

			For local nextMatch:TNewsEventSportMatch = EachIn season.upcomingMatches
				if nextMatch.GetMatchTime() < GetWorldTime().GetTimeGone()
					season.updateTime = nextMatch.GetMatchTime()

					'invalidate table
					season.InvalidateLeaderboard()

					season.upcomingMatches.Remove(nextMatch)
					nextMatch.Run()
					season.doneMatches.AddLast(nextMatch)

					matchesRun :+ 1
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
			season.Start( GetWorldTime().GetTimeGone() )
		Next

		playoffsState = 1

		EventManager.triggerEvent(TEventSimple.Create("Sport.StartPlayoffs", new TData.AddNumber("time", GetWorldTime().GetTimeGone()), Self))
	End Method


	Method FinishPlayoffs()
		For local season:TNewsEventSportSeason = EachIn playoffSeasons
			season.Finish( GetWorldTime().GetTimeGone() )
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
'			print "Liga: "+(i+1)+"->"+(i+2)
'			print "  abstieg: "+looser.name
'			print "  aufstieg: "+winner.name
		Next

		'set winner of relegation to #1
		'set looser of relegation to #2
		For local i:int = 0 until playoffSeasons.length -1
			local looser:TNewsEventSportTeam = playoffSeasons[i].GetTeamAtRank( -1 )
			local winner:TNewsEventSportTeam = playoffSeasons[i+1].GetTeamAtRank( 1 )

			'print "Relegation: "+(i+1)+"->"+(i+2)
			'print "  abstieg: "+looser.name
			'print "  aufstieg: "+winner.name

			'only switch teams if possible for both leagues
			'else you would add a team to two leagues
			if leagues[i].ReplaceNextSeasonTeam(looser, winner)
				if not leagues[i+1].ReplaceNextSeasonTeam(winner, looser)
					leagues[i].ReplaceNextSeasonTeam(winner, looser)
					print "could not replace next season team"
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
			playoffSeasons[i] = new TNewsEventSportSeason.Init()
			'mark as playoff season
			playoffSeasons[i].seasonType = TNewsEventSportSeason.SEASONTYPE_PLAYOFF

			'add second to last of first league
			playoffSeasons[i].AddTeam( leagues[i].GetCurrentSeason().GetTeamAtRank( -2 ) )
			'add second placed team of next league
			playoffSeasons[i].AddTeam( leagues[i+1].GetCurrentSeason().GetTeamAtRank( 2 ) )
	
			playoffSeasons[i].data.matchPlan = new TNewsEventSportMatch[playoffSeasons[i].GetMatchCount()]

			CreateMatchSets(playoffSeasons[i].GetMatchCount(), playoffSeasons[i].GetTeams(), playoffSeasons[i].data.matchPlan, CreateMatch)

			for local match:TNewsEventSportMatch = EachIn playoffSeasons[i].data.matchPlan
				playoffSeasons[i].upcomingMatches.addLast(match)
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
			leagues[i].AssignMatchTimes(playoffSeasons[i], playoffsTime)

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


	Method GetMatchReport:string(match:TNewsEventSportMatch)
		return match.GetReport()
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long)
		local result:TNewsEventSportMatch[]
		For local l:TNewsEventSportLeague = EachIn leagues
			result :+ l.GetUpcomingMatches(minTime, MaxTime)
		Next

		return result
	End Method


	Method GetUpcomingPlayoffMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long)
		local result:TNewsEventSportMatch[]
		For local l:TNewsEventSportSeason = EachIn playoffSeasons
			result :+ l.GetUpcomingMatches(minTime, MaxTime)
		Next

		return result
	End Method


	'helper: creates a "round robin"-matchset (all vs all)
	Function CreateMatchSets(matchCount:int, teams:TNewsEventSportTeam[], matchPlan:TNewsEventSportMatch[], createMatchFunc:TNewsEventSportMatch())
		'based on the description (which took it from the "championship
		'manager forum") at:
		'http://www.blitzmax.com/Community/post.php?topic=51796&post=578319

		if not createMatchFunc then createMatchFunc = CreateMatch

		local useTeams:TNewsEventSportTeam[] = teams[ .. teams.length]
		local ghostTeam:TNewsEventSportTeam
		'if odd we add a ghost team
		if teams.length mod 2 = 1
			ghostTeam = new TNewsEventSportTeam
			useTeams :+ [ghostTeam]
		endif

		?debug
			print "CreateMatchSets:"
			print "  teams: "+teams.length
			print "  useTeams: "+useTeams.length
			print "  matchCount: "+matchCount
			For local i:int = 0 until useTeams.length
				useTeams[i].nameInitials = i+1
				if useTeams[i] = ghostTeam then useTeams[i].nameInitials = "G"
			Next
		?

		local matchIndex:int = 0
		local loopLength:int = useTeams.length - 1
		'loop over all teams (fight versus all other teams)
		For local opponentNumber:int = 1 to loopLength
			'we have to shift around all entries except the first one
			'so "first team" is always the same, all others shift their
			'position one step to the right on each loop
			'1) 1 2 3 4
			'2) 1 4 2 3
			'3) 1 3 4 2
			useTeams = useTeams[.. 1] + useTeams[useTeams.length-1 ..] + useTeams[1 .. useTeams.length -1]


			?debug
				local shifted:string = ""
				for local j:int = 0 until useTeams.length
					if shifted<>"" then shifted :+ " "
					shifted :+ useTeams[j].nameInitials
				next
				print "shifted: "+shifted
			?

			'setup: 1st vs last, 2nd vs last-1, 3rd vs last-2 ...
			'skip match when playing vs the dummy/ghost team
			For local teamOffset:int = 0 until ceil(useTeams.length/2)
				local teamA:TNewsEventSportTeam = useTeams[0 + teamOffset]
				local teamB:TNewsEventSportTeam = useTeams[useTeams.length-1 - teamOffset]
				'skip matches with the ghost team
				if teamA = ghostTeam or teamB = ghostTeam then continue

				?debug
					print " -> "+Rset(matchIndex,2)+"/" + matchCount+") " + teamA.nameInitials +" - " + teamB.nameInitials
					print " <- "+Rset(matchIndex+ matchCount/2,2)+"/" + matchCount+") " + teamB.nameInitials +" - " + teamA.nameInitials
				?

				'create an entry for home and away matches
				'switch every second game so the first team does not get
				'a home match everytime
				local matchA:TNewsEventSportMatch = createMatchFunc()
				local matchB:TNewsEventSportMatch = createMatchFunc()
				if matchIndex mod 2 = 0 
					matchA.AddTeams( [teamA, teamB] )
					matchB.AddTeams( [teamB, teamA] )
				else
					matchA.AddTeams( [teamB, teamA] )
					matchB.AddTeams( [teamA, teamB] )
				endif

				'home match
				matchPlan[matchIndex] = matchA
				'away match
				matchPlan[matchIndex + matchCount/2] = matchB

				matchA.matchNumber = matchIndex
				matchB.matchNumber = matchIndex + matchCount/2

				matchIndex :+ 1
			Next
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
			return _leaderboard
		endif
		
		_leaderboard = new TNewsEventSportLeagueRank[teams.length]

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




Type TNewsEventSportSeason
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

	Field seasonType:int = 1
	Const SEASONTYPE_NORMAL:int = 1
	Const SEASONTYPE_PLAYOFF:int = 2
	


	Method Init:TNewsEventSportSeason()
		doneMatches = CreateList()
		upcomingMatches = CreateList()

		return self
	End Method


	Method Start(time:Long)
		data.startTime = time
		finished = False
		started = True
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
		return data.SetTeams(teams)
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
	

	Method GetMatchCount:int(teamSize:int = -1)
		if teamSize = -1 then teamSize = GetTeams().length
		'each team fights all other teams - this means we need
		'(teams * (teamsAmount-1))/2 different matches

		'*2 to get "home" and "guest" matches
		return 2 * (teamSize * (teamSize-1)) / 2
	End Method


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long)
		local result:TNewsEventSportMatch[]
		For local match:TNewsEventSportMatch = EachIn upcomingMatches
			if match.GetMatchTime() < minTime then continue
			if match.GetMatchTime() > maxTime then continue

			result :+ [match]
		Next
	End Method
End Type


	

Type TNewsEventSportLeague
	Field name:string
	Field nameShort:string

	'store all seasons of that league
	Field pastSeasons:TNewsEventSportSeasonData[]
	Field currentSeason:TNewsEventSportSeason
	'teams in then nex season (maybe after relegation matches)
	Field nextSeasonTeams:TNewsEventSportTeam[]
	
	'callbacks
	Field _onRunMatch:int(league:TNewsEventSportLeague, match:TNewsEventSportMatch)
	Field _onStartSeason:int(league:TNewsEventSportLeague)
	Field _onFinishSeason:int(league:TNewsEventSportLeague)
	Field _onFinishSeasonPart:int(league:TNewsEventSportLeague, part:int)
	Field _onStartSeasonPart:int(league:TNewsEventSportLeague, part:int)


	Method Init:TNewsEventSportLeague(name:string, nameShort:string, initialSeasonTeams:TNewsEventSportTeam[])
		self.name = name
		self.nameShort = nameShort
		self.nextSeasonTeams = initialSeasonTeams
		
		return self
	End Method


	Method ReplaceNextSeasonTeam:int(oldTeam:TNewsEventSportTeam, newTeam:TNewsEventSportTeam)
		For local i:int = 0 until nextSeasonTeams.length
			if not nextSeasonTeams[i] or nextSeasonTeams[i] <> oldTeam then continue

			nextSeasonTeams[i] = newTeam
			return True
		Next
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
	

	'playoffs should ignore season breaks (season end / winter break)
	Method GetNextMatchStartTime:Long(time:Long = 0, ignoreSeasonBreaks:int = False)
		if time = 0 then time = Long(GetWorldTime().GetTimeGone())
		return time + 3600
	End Method


	Method GetCurrentSeason:TNewsEventSportSeason()
		return currentSeason
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
				if endingMatchTime = 0 then endingMatchTime = GetWorldTime().GetTimeGone()
				EventManager.triggerEvent(TEventSimple.Create("SportLeague.FinishMatchGroup", New TData.add("matches", runMatches).AddNumber("time", endingMatchTime), Self))
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
		if time = 0 then time = Long(GetWorldTime().GetTimeGone())

		'archive old season
		if currentSeason then pastSeasons :+ [currentSeason.data]

		'create and start new season
		currentSeason = new TNewsEventSportSeason.Init()
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
		local seasonStart:Long = GetFirstMatchTime(time)
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


	Method GetUpcomingMatches:TNewsEventSportMatch[](minTime:Long, maxTime:Long)
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
		next		
	End Method


	Method Custom_CreateUpcomingMatches:int() abstract


	'adjust the given time if the first match of a season cannot start
	'before a given time
	Method GetFirstMatchTime:Long(time:Long)
		return time
	End Method
	

	Method AssignMatchTimes(season:TNewsEventSportSeason, time:Long = 0)
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
		EventManager.triggerEvent(TEventSimple.Create("SportLeague.RunMatch", New TData.addNumber("matchTime", match.GetMatchTime()).add("match", match), Self))

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
		if not other then return Super.Compare(other)

		if score > other.score
			return 1
		elseif score < other.score
			return -1
		else
			return 0
		endif
	End Method
End Type



Type TNewsEventSportMatch
	Field teams:TNewsEventSportTeam[]
	Field points:int[]
	Field duration:int = 90*60 'in seconds
	'when the match takes place
	Field matchTime:Long
	Field matchNumber:int
	Field matchState:int = STATE_NORMAL
	Const STATE_NORMAL:int = 0
	Const STATE_RUN:int = 1


	Method Run:int()
		duration = duration + 60 * BiasedRandRange(0,8, 0.3)
		For local i:int = 0 until points.length
			points[i] = BiasedRandRange(0, 8, 0.18)
		Next
		matchState = STATE_RUN
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
	

	Method GetScore:int(team:TNewsEventSportTeam)
		if not IsRun() then return 0

		if GetRank(team) = 1 then return GetWinnerScore()
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


	Method GetReport:string()
		return "override GetReport()"
	End Method

	Method GetReportShort:string()
		return "override GetReportShort()"
	End Method
End Type




Type TNewsEventSportTeam
	'eg. "Exampletown"
	Field city:string
	'eg. "FC Exampletown"
	Field name:string
	'eg. "FCE"
	Field nameInitials:string
	'eg. "Football club"
	Field clubName:string
	'eg. "FC"
	Field clubNameInitials:string
	'if singular, in German the "Der" is used, else "Die"
	'-> "Der Klub" (the club), "Die Kicker" (the kickers)
	Field clubNameSingular:int

	Field members:TNewsEventSportTeamMember[]
	Field trainer:TNewsEventSportTeamMember


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
End Type




Type TNewsEventSportTeamMember Extends TProgrammePersonBase

	Method Init:TNewsEventSportTeamMember(firstName:string, lastName:string, countryCode:string, gender:int = 0, fictional:int = False)
		self.firstName = firstName
		self.lastName = lastName
		self.SetGUID("sportsman-"+id)
		self.countryCode = countryCode
		self.gender = gender
		self.fictional = fictional
		return self
	End Method
End Type