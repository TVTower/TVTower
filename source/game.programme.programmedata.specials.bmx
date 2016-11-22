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

					'show score in title once it is or was running
					if match and match.GetMatchTime() <= GetWorldTime().GetTimeGone()
						'still running?
						if match.GetMatchEndTime() >= GetWorldTime().GetTimeGone()
							title.Set("%MATCHLIVEREPORTSHORT%", null )
							foundTitle = True
						else
							title.Set("%MATCHREPORTSHORT%", null )
							foundTitle = True
						endif
					endif

					if not foundtitle
						title.Set("%MATCHNAMESHORT%", null )
					endif
				endif

				titleProcessed = new TLocalizedString
				titleProcessed.Set( _LocalizeContent(title.Get()) )
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
					description.Set( GetRandomLocale("SPORT_PROGRAMME_MATCH_DESCRIPTION") , null )
				endif

				descriptionProcessed = new TLocalizedString
				descriptionProcessed.Set( _LocalizeContent(description.Get()) )
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

		if result.Find("%MATCHCOUNT%") >= 0
			result = result.replace("%MATCHCOUNT%", league.GetUpcomingMatches(GetWorldTime().GetTimeGone(), -1).length)
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
	

	Method _LocalizeContent:string(content:string)
		local result:string = Super._LocalizeContent(content)

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


	Method IsMatchFinished:int()
		return False
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcome:Float()
		return self.outcome
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcomeTV:Float()
		return self.outcomeTV
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetSpeed:Float()
		return self.speed
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetReview:Float()
		return self.review
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


	'override
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		Super.doFinishBroadcast(playerID, broadcastType)
	End Method
End Type