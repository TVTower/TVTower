REM
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "game.programme.programmedata.bmx"
Import "game.newsagency.sports.soccer.bmx"


Type TSportsProgrammeData extends TProgrammeData {_exposeToLua}
	Field matchGUID:string
	Field leagueGUID:string
	Field dynamicTexts:int = False
	Field matchEndTime:Long = -1


	Method GenerateGUID:string()
		return "broadcastmaterialsource-sportsprogrammedata-"+id
	End Method


	Method GetTitle:string()
		if title
			'replace placeholders and and cache the result
			if not titleProcessed
				if dynamicTexts
					local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
					local foundTitle:int = False 
					local leagueText:string
					for local t:TNewsEventSportTeam = EachIn match.teams
						if not leagueGUID
							leagueGUID =  t.leagueGUID
							leagueText = "%LEAGUENAMESHORT%: "
						else if leagueGUID <> t.leagueGUID
							leagueGUID = ""
							leagueText = GetLocale("SPORT_PLAYOFFS_SHORT")+": "
							exit
						endif
					next
						
					'show score in title once it is or was running
					if match and match.GetMatchTime() <= GetWorldTime().GetTimeGone()
						'still running?
						if match.GetMatchEndTime() >= GetWorldTime().GetTimeGone()
							title.Set(leagueText + "%MATCHLIVEREPORTSHORT%", null )
							foundTitle = True
						else
							title.Set(leagueText + "%MATCHREPORTSHORT%", null )
							foundTitle = True
						endif
					endif

					if not foundtitle
						title.Set(leagueText + "%MATCHNAMESHORT%", null )
					endif
				endif

				titleProcessed = _ReplacePlaceholdersInLocalizedString(title)
			endif
			return titleProcessed.Get()
		endif
		return ""
	End Method


	Method GetDescription:string()
		if description
			'replace placeholders and and cache the result
			if not descriptionProcessed
				if dynamicTexts
					if leagueGUID
						description.Set( GetLocale("SPORT_PROGRAMME_MATCH_OF_LEAGUEX")+"~n"+GetRandomLocale("SPORT_PROGRAMME_MATCH_DESCRIPTION") , null )
					else
						description.Set( GetLocale("SPORT_PROGRAMME_PLAYOFF_MATCH")+"~n"+GetRandomLocale("SPORT_PROGRAMME_MATCH_DESCRIPTION") , null )
					endif
				endif

				descriptionProcessed = _ReplacePlaceholdersInLocalizedString(description)
			endif
			return descriptionProcessed.Get()
		endif
		return ""
	End Method


	Function _replaceSportInformation:string(text:string, sport:TNewsEventSport, locale:string="")
		if not sport then return text

		local result:string = text
		result = result.replace("%SPORTNAME%", GetLocalizedString("SPORT_"+sport.name).get(locale))
		return result
	End Function


	Function _replaceLeagueInformation:string(text:string, league:TNewsEventSportLeague, locale:string="")
		if not league then return text

		local result:string = text
		result = result.replace("%SEASONYEARSTART%", GetWorldTime().GetYear(league.GetNextMatchTime()))
		result = result.replace("%LEAGUENAME%", league.name)
		result = result.replace("%LEAGUENAMESHORT%", league.nameShort)

		if result.Find("%MATCHCOUNT%") >= 0
			result = result.replace("%MATCHCOUNT%", league.GetUpcomingMatches(long(GetWorldTime().GetTimeGone()), -1).length)
		endif

		if result.Find("%MATCHTIMES%") >= 0
			local matchTimes:string
			local lastWeekdayIndex:int = -1
			local thisWeekdayCount:int = 0
			for local slot:string = eachIn league.timeSlots
				local information:string[] = slot.Split("_")
				local weekdayIndex:int = int(information[0])
				local hour:int = 0
				if information.length > 1 then hour = int(information[1])

				if lastWeekdayIndex <> weekdayIndex
					if matchTimes <> "" then matchTimes :+ " / "
					matchTimes :+ "|b|"+GetLocalizedString("WEEK_SHORT_" + GetWorldTime().GetDayName(weekdayIndex)).get(locale)+"|/b| "
					lastWeekdayIndex = weekdayIndex
					thisWeekdayCount = 0
				else
					thisWeekdayCount :+ 1
				endif

				if thisWeekdayCount >= 1 then matchTimes :+ ", "

				matchTimes :+ hour+":00"
			Next
			result = result.replace("%MATCHTIMES%", matchTimes)
		endif

		return result
	End Function


	Function _replaceMatchInformation:string(text:string, match:TNewsEventSportMatch, locale:string="")
		if not match then return text

		local result:string = text
		result = result.replace("%MATCHNAMESHORT%", match.GetNameShort() )

		if result.Find("%MATCHREPORT") >= 0
			result = result.replace("%MATCHREPORT%", match.GetReport() )
			result = result.replace("%MATCHREPORTSHORT%", match.GetReportShort() )
		endif
		if result.Find("%MATCHLIVEREPORT") >= 0
			result = result.replace("%MATCHLIVEREPORTSHORT%", match.GetLiveReportShort("", -1) )
		endif
		
		return result
	End Function


	Function _replaceTeamInformation:string(text:string, team:TNewsEventSportTeam, teamNumber:int=1, locale:string="")
		if not team then return text

		local result:string = text

		local league:TNewsEventSportLeague = team.GetLeague()
		if league
			result = result.replace("%TEAM"+teamNumber+"RANK%", league.GetCurrentSeason().GetTeamRank(team))
			'handled by "match.ReplacePlaceholders" too
			team.FillPlaceholders(result, string(teamNumber))
		endif

		return result
	End Function
	

	Method _ReplacePlaceholdersInString:string(content:string)
		local result:string = Super._ReplacePlaceholdersInString(content)

		local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
		if league
			result = _replaceLeagueInformation(result, league, TLocalization.GetCurrentLanguageCode())

			local sport:TNewsEventSport = league.GetSport()
			if sport then result = _replaceSportInformation(result, sport, TLocalization.GetCurrentLanguageCode())
		endif

		local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		if match
			result = _replaceMatchInformation(result, match, TLocalization.GetCurrentLanguageCode())

			if result.Find("%TEAM") >= 0
				for local teamIndex:int = 0 until match.teams.length
					result = _replaceTeamInformation(result, match.teams[teamIndex], teamIndex+1, TLocalization.GetCurrentLanguageCode())
				next
			endif
		endif

		return result
	End Method
	

	Method AssignSportMatch(match:TNewsEventSportMatch)
		matchGUID = match.GetGUID()
	End Method


	Method GetMatchEndTime:Long()
		if matchEndTime = -1
			local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
			if match then matchEndTime = match.GetMatchEndTime()
		endif
		return matchEndTime
	End Method


	Method IsMatchFinished:int()
		if matchEndTime = -1 then GetMatchEndTime()

		if matchEndTime <> -1
			return matchEndTime <= GetWorldTime().GetTimeGone()
		endif
		
		return False
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcome:Float()
		return self.outcome
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcomeTV:Float()
		if not matchGUID then return self.outcomeTV
		local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		if not match then return self.outcomeTV

		'modify by "attractivity" of a match
		local attractivityMod:Float = 0.0
		local highestScore:int = 0
		local lowestScore:int = -1
		for local teamIndex:int = 0 until match.teams.length
			attractivityMod :+ match.teams[teamIndex].GetAttractivity()
			highestScore = max(highestScore, match.points[teamIndex])
			if lowestScore = -1 then lowestScore = match.points[teamIndex]
			lowestScore = min(lowestScore, match.points[teamIndex])
		next
		if match.teams.length > 0
			attractivityMod :/ match.teams.length
		else
			attractivityMod = 1.0
		endif

		'game got more exciting ?
		if lowestScore <> highestScore and highestScore > 0
			'eg. 0 : 1
			if lowestScore = 0 and highestScore = 1 then attractivityMod :+ 0.05
			'eg. 1 : 2
			if lowestScore/highestScore > 0.5 then attractivityMod :+ 0.05
			'eg. 3 : 4
			if lowestScore/highestScore > 0.75 then attractivityMod :+ 0.05
		endif
		

		return MathHelper.Clamp(self.outcomeTV * attractivityMod, 0.0, 1.0)
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetSpeed:Float()
		if not matchGUID then return self.speed
		local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		if not match then return self.speed

		'modify by "power" of the teams
		local powerMod:Float = 0.0
		for local team:TNewsEventSportTeam = EachIn match.teams
			powerMod :+ team.GetPower()
		next
		if match.teams.length > 0
			powerMod :/ match.teams.length
		else
			powerMod = 1.0
		endif

		return MathHelper.Clamp(self.speed * powerMod, 0.0, 1.0)
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetReview:Float()
		if not matchGUID then return self.review
		local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		if not match then return self.review

		'modify by "skill" of the teams ("good soccer technics")
		local skillMod:Float = 0.0
		for local team:TNewsEventSportTeam = EachIn match.teams
			skillMod :+ team.GetSkill()
		next
		if match.teams.length > 0
			skillMod :/ match.teams.length
		else
			skillMod = 1.0
		endif

		return MathHelper.Clamp(self.review * skillMod, 0.0, 1.0)
	End Method


	Method GetReleaseTime:Long()
		return releaseTime
	End Method


	Method GetCinemaReleaseTime:Long()
		return releaseTime
	End Method


	'only useful for cinematic movies
	Method GetProductionStartTime:Long()
		return releaseTime
	End Method

rem
	'override
	Method IsAvailable:int()
		'live programme is available 10 days before

		if IsLive()
			if GetWorldTime().GetDay() + 10 >= GetWorldTime().GetDay(releaseTime)
				return True
			else
				return False
			endif
		endif

		if not isReleased() then return False

		return Super.IsAvailable()
	End Method
endrem


	Method UpdateLive:int()
		Super.UpdateLive()

		'refresh processedTitle (recreated on request)
		titleProcessed = null
		descriptionProcessed = null
	End Method


	'override to reduce topicality if the game is finished now
	Method GetMaxTopicality:Float()
		'not yet aired?
		if IsLive() or not IsMatchFinished() then Super.GetMaxTopicality()

		local endTime:Long = GetMatchEndTime()
		if endTime = -1 then return Super.GetMaxTopicality()

		'hours would be more suiting ("after 24hrs") but harder to remember
		'so a "after midnight" decrease sounds more suiting
		local daysSinceMatch:int = Max(0, GetWorldTime().GetDay() - GetWorldTime().GetDay(endTime))
		'day 0 => 1  |  day 1 => 0.5  |  day 2 => 0.33  |  day 3 => 0.25
		'return 1.0/(daysSinceMatch+1) * Super.GetMaxTopicality()
		'Allows a more fine grained setup for this small amount of days
		'-> reduction until day 4
		Select daysSinceMatch
			Case 0	return 1.00 * Super.GetMaxTopicality()
			Case 1	return 0.80 * Super.GetMaxTopicality()
			Case 2	return 0.65 * Super.GetMaxTopicality()
			Case 3	return 0.55 * Super.GetMaxTopicality()
			Default	return 0.50 * Super.GetMaxTopicality()
		EndSelect
	End Method


	'override
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		Super.doFinishBroadcast(playerID, broadcastType)
	End Method
End Type