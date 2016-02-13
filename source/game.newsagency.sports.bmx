SuperStrict
Import "game.world.worldtime.bmx"
Import "Dig/base.util.mersenne.bmx"


Type TNewsEventSport
	'update every (game)second
	Field updateInterval:int
	'time of last update
	Field updateTime:Long = 0
	'the league of the sport
	Field leagues:TNewsEventSportLeague[]


	Method Update:int()
		if updateTime = 0 then updateTime = GetWorldTime().GetTimeGone()

		local updated:int = False
		While updateTime + updateInterval < GetWorldTime().GetTimeGone()
			NextMatchDay()
			
			updateTime :+ updateInterval
			updated = True
		endif

		return updated
	End Method


	Method StartSeason()
		for local l:TNewsEventSportLeague = Eachin leagues
			l.StartSeason()
		Next
	End Method


	Method NextMatchDay()
		for local l:TNewsEventSportLeague = Eachin leagues
			l.NextMatchDay()
		Next
	End Method
	

	Method AddLeague:TNewsEventSport(league:TNewsEventSportLeague)
		leagues :+ [league]
	End Method


	Method GetLeagueAtIndex:TNewsEventSportLeague(index:int)
		if index < 0 or index >= leagues.length then return Null
		return leagues[index]
	End Method
End Type


	

Type TNewsEventSportLeague
	Field name:string
	Field nameShort:string
	'all matches are stored in "sets" (eg. 4 matches on a day)
	Field upcomingMatchSets:TNewsEventSportMatchSet[]
	Field doneMatchSets:TNewsEventSportMatchSet[]
	Field teams:TNewsEventSportTeam[]
	'cache
	Field _leaderboard:TNewsEventSportLeagueRank[] {nosave}


	Method Init:TNewsEventSportLeague(name:string, nameShort:string, teams:TNewsEventSportTeam[] = null)
		self.name = name
		self.nameShort = nameShort
		self.teams = teams
		return self
	End Method


	Method StartSeason:int()
		doneMatchSets = new TNewsEventSportMatchSet[0]

		'let each one play versus each other
		CreateUpcomingMatches()
	End Method


	Method GetMatchDays:int()
		'each team fights all other teams - this means we need
		'teamsAmount-1 different days/times for matches

		'*2 to get two seasons
		return 2 * (teams.length - 1)
	End Method


	Method CreateUpcomingMatches()
		'based on the description (which took it from the "championship
		'manager forum") at:
		'http://www.blitzmax.com/Community/post.php?topic=51796&post=578319
	
		local useTeams:TNewsEventSportTeam[] = teams[ .. teams.length]
		local ghostTeam:TNewsEventSportTeam
		'if odd we add a ghost team
		if teams.length mod 2 = 1
			ghostTeam = new TNewsEventSportTeam
			useTeams :+ [ghostTeam]
		endif
			

		'2 halfs per season
		local matchDays:int = GetMatchDays() / 2
		upcomingMatchSets = new TNewsEventSportMatchSet[ 2 * matchDays ]

		'matches per day is the half of the teams size (so each one
		'is fighting another one in the team)
		local matchesPerDay:int = useTeams.length / 2

		For local day:int = 0 until matchDays
			'we also have to shift around all entries except the first one
			if day > 0
				useTeams = useTeams[.. 1] + useTeams[useTeams.length-1 ..] + useTeams[1 .. useTeams.length -1]
			endif

			'debug
			rem
			local order:string
			For local t:TNewsEventSportTeam = EachIn useTeams
				order :+ t.nameShort+" "
			Next
			print "day: " +day + " order: "+ order
			endrem


			For local matchOfDay:int = 0 until matchesPerDay
				'most left of the array fights the most right one,
				'then second left fights the second most right one ...

				local matchA:TNewsEventSportMatch = new TNewsEventSportMatch
				local matchB:TNewsEventSportMatch = new TNewsEventSportMatch

				local teamA:TNewsEventSportTeam = useTeams[0 + matchOfDay]
				local teamB:TNewsEventSportTeam = useTeams[teams.length-1 - matchOfDay]
				'skip matches with the ghost team
				if teamA = ghostTeam or teamB = ghostTeam then continue

				'create an entry for home and away matches
				'switch every second game so the first team does not get
				'a home match everytime
				if day mod 2 = 0 or matchOfDay > 0 
					matchA.AddTeams( [teamA, teamB] )
					matchB.AddTeams( [teamB, teamA] )
				else
					matchA.AddTeams( [teamB, teamA] )
					matchB.AddTeams( [teamA, teamB] )
				endif
				if not upcomingMatchSets[day] then upcomingMatchSets[day] = new TNewsEventSportMatchSet
				if not upcomingMatchSets[day + matchDays] then upcomingMatchSets[day + matchDays] = new TNewsEventSportMatchSet
				upcomingMatchSets[day].AddMatch(matchA)
				upcomingMatchSets[day + matchDays].AddMatch(matchB)
			Next
		Next
	End Method


	Method NextMatchDay:int()
		if upcomingMatchSets.length = 0 then return False

		'invalidate table
		_leaderboard = new TNewsEventSportLeagueRank[0]
		
		local currentMatchSet:TNewsEventSportMatchSet = upcomingMatchSets[0]

		upcomingMatchSets = upcomingMatchSets[1 .. ]

		For local match:TNewsEventSportMatch = EachIn currentMatchSet.matches
			match.Run()
		Next

		doneMatchSets :+ [currentMatchSet]
	End Method


	Method GetOnMatchDay:int()
		if not doneMatchSets then return -1
		return doneMatchSets.length
	End Method


	Method GetLastMatchSet:TNewsEventSportMatchSet()
		if not doneMatchSets or doneMatchSets.length = 0 then return null
		return doneMatchSets[ doneMatchSets.length-1 ]
	End Method


	Method GetNextMatchSet:TNewsEventSportMatchSet()
		if not upcomingMatchSets or upcomingMatchSets.length = 0 then return null
		return upcomingMatchSets[0]
	End Method


	Method GetLeaderboard:TNewsEventSportLeagueRank[](upToMatchDay:int=-1)
		'return cache if possible
		if _leaderboard and _leaderboard.length = teams.length
			return _leaderboard
		endif
		
		_leaderboard = new TNewsEventSportLeagueRank[teams.length]

		'sum up the scores of each team in the matches
		local runMatchDays:int = 0
		For local matchSet:TNewsEventSportMatchSet = EachIn doneMatchSets
			'upToMatchDay = 1 means, only first day (day0) is calculated
			if upToMatchDay >= 0 and runMatchDays >= upToMatchDay then continue
			runMatchDays :+ 1
			For local match:TNewsEventSportMatch = EachIn matchSet.matches
				for local team:TNewsEventSportTeam = Eachin match.teams
					local teamIndex:int = GetTeamIndex(team)
					'team not in the league?
					if teamIndex = -1 then continue

					if not _leaderboard[teamIndex]
						_leaderboard[teamIndex] = new TNewsEventSportLeagueRank
						_leaderboard[teamIndex].team = team
					endif
					_leaderboard[teamIndex].score :+ match.GetScore(team)
				Next
			Next
		Next

		'sort the leaderboard
		_leaderboard.sort(False)
		return _leaderboard
	End Method


	Method GetTeamIndex:int(team:TNewsEventSportTeam)
		For local i:int = 0 until teams.length
			if teams[i] = team then return i
		Next
		return -1
	End Method


	Method AddTeam:TNewsEventSportLeague(team:TNewsEventSportTeam)
		teams :+ [team]
	End Method


	Method GetTeamAtIndex:TNewsEventSportTeam(index:int)
		if index < 0 or index >= teams.length then return Null
		return teams[index]
	End Method
End Type



Type TNewsEventSportLeagueRank
	Field score:int
	Field team:TNewsEventSportTeam

	Method Compare:int(o:object)
		local other:TNewsEventSportLeagueRank = TNewsEventSportLeagueRank(o)
		if not other then return 1

		if score > other.score
			return 1
		elseif score < other.score
			return -1
		else
			return 0
		endif
	End Method
End Type




Type TNewsEventSportMatchSet
	Field matches:TNewsEventSportMatch[]

	Method AddMatch(match:TNewsEventSportMatch)
		matches :+ [match]
	End Method
End Type




Type TNewsEventSportMatch
	Field teams:TNewsEventSportTeam[]
	Field points:int[]


	Method Run:int()
		For local i:int = 0 until points.length
			points[i] = BiasedRandRange(0, 8, 0.18)
		Next
	End Method


	Method AddTeam(team:TNewsEventSportTeam)
		teams :+ [team]
		points = points[ .. points.length + 1]
	End Method


	Method AddTeams(teams:TNewsEventSportTeam[])
		self.teams :+ teams
		points = points[ .. points.length + teams.length]
	End Method


	Method GetScore:int(team:TNewsEventSportTeam)
		if GetRank(team) = 1 then return GetWinnerScore()
	End Method


	Method GetRank:int(team:TNewsEventSportTeam)
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


	Method HasLooser:int()
		if not points or points.length = 0 then return False

		'check if one of the teams has less points than the others
		local lastPoint:int = points[0]
		for local point:int = EachIn points
			if point <> lastPoint then return True
		Next
		return False
	End Method


	Method HasWinner:int()
		return GetWinner() <> -1
	End Method


	Method GetWinner:int()
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
End Type




Type TNewsEventSportTeam
	Field name:string = "" 
	Field nameShort:string = ""
	Field city:string = ""
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
		if index < 0 or index >= members.length then return Null
		return members[index]
	End Method
End Type




Type TNewsEventSportTeamMember
	Field lastName:string
	Field firstName:string

	Method Init:TNewsEventSportTeamMember(firstName:string, lastName:string)
		self.firstName = firstName
		self.lastName = lastName
		return self
	End Method
End Type