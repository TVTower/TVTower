Rem
	===========================================================
	code for programme-objects (movies, ..) in programme planning
	===========================================================
ENDREM
SuperStrict
Import "game.programme.programmedata.bmx"
Import "game.newsagency.sports.soccer.bmx"


Type TSportsHeaderProgrammeData Extends TSportsProgrammeData {_exposeToLua}
	Field descriptionAirTimeHint:TLocalizedString
	Field descriptionAiredHint:TLocalizedString
	Field finalDescription:String {nosave}
	Field matchesStarted:Int = False
	Field matchesStartTime:Long = -1
	Field matchesFinished:Int = False
	Field matchesRun:Int = 0
	Field matchesFinishTime:Long = -1
	Field matchProgress:Float = -1
	Field lastMatchStartTime:Long = -1
	Field lastMatchStarted:Int = False

	Method GenerateGUID:String()
		Return "broadcastmaterialsource-sportsheaderprogrammedata-"+id
	End Method


	Method UpdateLive:Int(calledAfterbroadCast:Int) override
		'do no longer display "live hint" once the last match started

		If lastMatchStartTime = -1
			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			If league Then lastMatchStartTime = league.GetLastMatchTime()
		EndIf

		If not lastMatchStarted and lastMatchStartTime < GetWorldTime().GetTimeGone()
			SetFlag(TVTProgrammeDataFlag.LIVE, False)
			SetFlag(TVTProgrammeDataFlag.LIVEONTAPE, True)

			lastMatchStarted = True
			return True
		EndIf
	End Method


	'override
	Method IsLive:Int()
		return not lastMatchStarted
	End Method


	'override
	Method HasDynamicData:Int()
		Return Not matchesFinished
	End Method

	'override
	Method UpdateDynamicData:Int()
		If Not HasDynamicData() Then Return True

		'did the first match start?
		If Not matchesStarted
			If matchesStartTime = -1
				Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
				If league Then matchesStartTime = league.GetFirstMatchTime()
			EndIf

			If matchesStartTime < GetWorldTime().GetTimeGone()
				matchesStarted = True
				finalDescription = ""
			EndIf
		EndIf


		'stay dynamic until last match ends
		If Not matchesFinished
			finalDescription = ""

			Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
			If matchesFinishTime = -1 And league
				Local b:Int = blocks
				Local lastMatch:TNewsEventSportMatch = league.GetLastMatch()
				If lastMatch Then b = Max(blocks, Int(Ceil(lastMatch.duration/ Double(TWorldTime.HOURLENGTH))))

				matchesFinishTime = league.GetLastMatchEndTime()
				'no longer than the blocks define ?
				matchesFinishTime = Min(league.GetLastMatchEndTime(), league.GetLastMatchTime() + b * TWorldTime.HOURLENGTH)
		'		print league.GetLastMatchEndTime() +"     " + league.GetLastMatchTime()
			EndIf

			If matchesFinishTime < GetWorldTime().GetTimeGone()
				matchesFinished = True
				Return True
			EndIf
		EndIf
		Return False
	End Method


	Method GetDescription:String()
		'create live state texts
		If Not finalDescription
			If Not descriptionProcessed
				descriptionProcessed = _ParseScriptExpressions(description)
			EndIf

			If matchesFinished
				finalDescription = "|i|("+GetLocale("LIVE_ON_TAPE")+", " + GetLocale("ALL_MATCHES_FINISHED") + "|/i|)~n" + descriptionProcessed.Get()

			ElseIf matchesStarted
				Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
				If Not league Then Return descriptionProcessed.Get()

				Local totalMatches:Int = league.GetMatchCount()
				'doneMatches would only include finally run ... we want also
				'started ones
				'local runMatches:int = league.GetDoneMatchesCount()
				Local run:Int = totalMatches - league.GetUpcomingMatchesCount()
				'only update if value gets bigger (maybe we update an old
				'programme delayed and right after the new session started)
				If matchesRun < run Then matchesRun = run

				finalDescription = "|i|("+GetLocale("X_OF_Y_LIVE_MATCHES_ALREADY_STARTED").Replace("%X%", matchesRun).Replace("%Y%", totalMatches)+"|/i|)~n" + descriptionProcessed.Get()
				If descriptionAirTimeHint
'repair old savegames which contain already match times
'-> TODO: REMOVE in 2020 or later
If descriptionAirTimeHint.Get().Find(":00") > 0
	descriptionAirtimeHint.Set(StringHelper.UCFirst(GetRandomLocalizedString("SPORT_PROGRAMME_MATCH_TIMES").Get()))
EndIf
					'append match times of UPCOMING matches
'					if run = 0
						'DO sort them - so earlier weekdays are first
						local matchTimes:string = _GetLeagueMatchTimes(league, True, True)
						'while the last match is running this will be empty
						'(it is no longer "upcoming" !
						if matchTimes
							finalDescription :+ "~n~n" + descriptionAirTimeHint.Get() + ": " + _GetLeagueMatchTimes(league, True, True)
						endif
'					else
						'do NOT sort them - so next match's weekday is first
'						finalDescription :+ "~n~n" + descriptionAirTimeHint.Get() + _GetLeagueMatchTimes(league, True, False)
'					endif
				EndIf
			Else 'if not matchesStarted
				finalDescription = descriptionProcessed.Get()
				If descriptionAirTimeHint
					Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
					If league
						local matchTimes:string = _GetLeagueMatchTimes(league, True, True)
						'while the last match is running this will be empty
						'(it is no longer "upcoming" !
						if matchTimes
							finalDescription :+ "~n~n" + descriptionAirTimeHint.Get() + _GetLeagueMatchTimes(league, True, True)
						endif
					endif
				EndIf
			EndIf
'				finalDescription = descriptionProcessed.Get()
		EndIf
		Return finalDescription
	End Method
End Type




Type TSportsProgrammeData Extends TProgrammeData {_exposeToLua}
	Field matchGUID:String
	Field leagueGUID:String
	Field dynamicTexts:Int = False
	Field matchEndTime:Long = -1
	Field matchTime:Long = -1


	Method GenerateGUID:String()
		Return "broadcastmaterialsource-sportsprogrammedata-"+id
	End Method


	Method GetTitle:String()
		If title
			'replace placeholders and and cache the result
			If Not titleProcessed
				If dynamicTexts
					Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
					Local foundTitle:Int = False
					Local leagueText:String
					For Local t:TNewsEventSportTeam = EachIn match.teams
						If Not leagueGUID
							leagueGUID =  t.leagueGUID
							leagueText = "%LEAGUENAMESHORT%: "
						Else If leagueGUID <> t.leagueGUID
							leagueGUID = ""
							leagueText = GetLocale("SPORT_PLAYOFFS_SHORT")+": "
							Exit
						EndIf
					Next

					'show score in title once it is or was running
					If match And match.GetMatchTime() <= GetWorldTime().GetTimeGone()
						'still running?
						If match.GetMatchEndTime() >= GetWorldTime().GetTimeGone()
							title.Set(leagueText + "%MATCHLIVEREPORTSHORT%", -1 )
							foundTitle = True
						Else
							title.Set(leagueText + "%MATCHREPORTSHORT%", -1 )
							foundTitle = True
						EndIf
					EndIf

					If Not foundtitle
						title.Set(leagueText + "%MATCHNAMESHORT%", -1 )
					EndIf
				EndIf

				titleProcessed = _ParseScriptExpressions(title)
			EndIf
			Return titleProcessed.Get()
		EndIf
		Return ""
	End Method


	Method GetDescription:String()
		If description
			'replace placeholders and and cache the result
			If Not descriptionProcessed
				If dynamicTexts
					'skip choosing a description if there is already one
					'this avoids having a random "text" on eeach dynamic text
					'refresh
					If not description.HasLanguageID( TLocalization.currentLanguageID )
						If leagueGUID
							description.Set( GetLocale("SPORT_PROGRAMME_MATCH_OF_LEAGUEX")+"~n"+GetRandomLocale("SPORT_PROGRAMME_MATCH_DESCRIPTION") , TLocalization.currentLanguageID )
						Else
							description.Set( GetLocale("SPORT_PROGRAMME_PLAYOFF_MATCH")+"~n"+GetRandomLocale("SPORT_PROGRAMME_MATCH_DESCRIPTION") , TLocalization.currentLanguageID )
						EndIf
					EndIf
				EndIf

				descriptionProcessed = _ParseScriptExpressions(description)
			EndIf

			If Not IsLive()
				Return "|i|("+GetRandomLocale("LIVE_ON_TAPE")+": " + GetLocale("GAMEDAY")+" "+ GetWorldTime().GetFormattedDate(GetMatchTime(), "g, h:i") + " " + GetLocale("OCLOCK")+")|/i|~n" + descriptionProcessed.Get()
			Else
				Return descriptionProcessed.Get()
			EndIf
		EndIf
		Return ""
	End Method


	Function _replaceSportInformation:String(text:String, sport:TNewsEventSport, localeID:Int = -1)
		If Not sport Then Return text

		Local result:String = text
		result = result.Replace("%SPORTNAME%", GetLocalizedString("SPORT_"+sport.name).get(localeID))
		Return result
	End Function


	Function _GetLeagueMatchTimes:String(league:TNewsEventSportLeague, onlyUpcoming:Int = False, sortByWeekDay:Int=True, localeID:Int = -1)
		If localeID < 0 Then localeID = TLocalization.GetCurrentLanguageID()

		Local matchTimes:String
		Local lastWeekdayIndex:Int = -1
		Local thisWeekdayCount:Int = 0
		Local usedTimeSlots:String[] = league.GetTimeSlots(True, onlyUpcoming, False)
		For Local slot:String = EachIn usedTimeSlots
			Local information:String[] = slot.Split("_")
			Local weekdayIndex:Int = Int(information[0])
			Local hour:Int = 0
			If information.length > 1 Then hour = Int(information[1])

			If lastWeekdayIndex <> weekdayIndex
				If matchTimes <> "" Then matchTimes :+ " / "
				matchTimes :+ "|b|"+GetLocalizedString("WEEK_SHORT_" + GetWorldTime().GetDayName(weekdayIndex)).get(localeID)+"|/b| "
				lastWeekdayIndex = weekdayIndex
				thisWeekdayCount = 0
			Else
				thisWeekdayCount :+ 1
			EndIf

			If thisWeekdayCount >= 1 Then matchTimes :+ ", "

'				matchTimes :+ RSet(hour,2).Replace(" ","0") + ":00"
			matchTimes :+ hour + ":00"
		Next
		Return matchTimes
	End Function


	Function _replaceLeagueInformation:String(text:String, league:TNewsEventSportLeague, localeID:Int = -1)
		If Not league Then Return text

		Local result:String = text
		result = result.Replace("%SEASONYEARSTART%", GetWorldTime().GetYear(league.GetNextMatchTime()))
		result = result.Replace("%LEAGUENAME%", league.name)
		result = result.Replace("%LEAGUENAMESHORT%", league.nameShort)

		If result.Find("%MATCHCOUNT%") >= 0
			result = result.Replace("%MATCHCOUNT%", league.GetUpcomingMatches(GetWorldTime().GetTimeGone(), -1).length)
		EndIf

		If result.Find("%MATCHTIMES%") >= 0
			result = result.Replace("%MATCHTIMES%", _GetLeagueMatchTimes(league, False, True, localeID))
		EndIf

		If result.Find("%UPCOMINGMATCHTIMES%") >= 0
			result = result.Replace("%UPCOMINGMATCHTIMES%", _GetLeagueMatchTimes(league, True, True, localeID))
		EndIf

		Return result
	End Function


	Function _replaceMatchInformation:String(text:String, match:TNewsEventSportMatch, localeID:Int = -1)
		If Not match Then Return text

		Local result:String = text
		result = result.Replace("%MATCHNAMESHORT%", match.GetNameShort() )

		If result.Find("%MATCHREPORT") >= 0
			result = result.Replace("%MATCHREPORT%", match.GetReport() )
			result = result.Replace("%MATCHREPORTSHORT%", match.GetReportShort() )
		EndIf
		If result.Find("%MATCHLIVEREPORT") >= 0
			result = result.Replace("%MATCHLIVEREPORTSHORT%", match.GetLiveReportShort("", -1) )
		EndIf

		Return result
	End Function


	Function _replaceTeamInformation:String(text:String, team:TNewsEventSportTeam, teamNumber:Int=1, localeID:Int = -1)
		If Not team Then Return text

		Local result:String = text

		Local league:TNewsEventSportLeague = team.GetLeague()
		If league
			result = result.Replace("%TEAM"+teamNumber+"RANK%", league.GetCurrentSeason().GetTeamRank(team))
			'handled by "match.ReplacePlaceholders" too
			team.FillPlaceholders(result, String(teamNumber))
		EndIf

		Return result
	End Function


	Method _ParseScriptExpressions:TLocalizedString(text:TLocalizedString, createCopy:Int = True) override
		text = Super._ParseScriptExpressions(text, createCopy)

		'add sports information

		'TODO: replace with "function calls / expressions"
		'      context TProgrammeData -> TSportsHeaderProgrammeData

		Local league:TNewsEventSportLeague = GetNewsEventSportCollection().GetLeagueByGUID(leagueGUID)
		Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		Local sport:TNewsEventSport
		If league Then sport = league.GetSport()

		For Local langID:Int = EachIn text.GetLanguageIDs()
			Local s:String = text.Get(langID)
			Local sNew:String = s
			
			If league
				sNew = _replaceLeagueInformation(sNew, league, langID)
			EndIf

			If sport
				sNew = _replaceSportInformation(sNew, sport, langID)
			EndIf

			If match
				sNew = _replaceMatchInformation(sNew, match, langID)
				If sNew.Find("%TEAM") >= 0
					For Local teamIndex:Int = 0 Until match.teams.length
						sNew = _replaceTeamInformation(sNew, match.teams[teamIndex], teamIndex+1, langID)
					Next
				EndIf
			EndIf
			
			if sNew <> s
				text.Set(sNew, langID)
			EndIf
		Next
		
		Return text
	End Method


	Method AssignSportLeague(league:TNewsEventSportLeague)
		leagueGUID = league.GetGUID()
	End Method


	Method AssignSportMatch(match:TNewsEventSportMatch)
		matchGUID = match.GetGUID()
	End Method


	Method GetMatchEndTime:Long()
		If matchEndTime = -1
			Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
			If match Then matchEndTime = match.GetMatchEndTime()
		EndIf
		Return matchEndTime
	End Method


	Method GetMatchTime:Long()
		If matchTime = -1
			Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
			If match Then matchTime = match.GetMatchTime()
		EndIf
		Return matchTime
	End Method


	Method IsMatchFinished:Int()
		If matchEndTime = -1 Then GetMatchEndTime()

		If matchEndTime <> -1
			Return matchEndTime <= GetWorldTime().GetTimeGone()
		EndIf

		Return False
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcome:Float()
		Return Self.outcome
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetOutcomeTV:Float()
		If Not matchGUID Then Return Self.outcomeTV
		Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		If Not match Then Return Self.outcomeTV

		'modify by "attractivity" of a match
		Local attractivityMod:Float = 0.0
		Local highestScore:Int = 0
		Local lowestScore:Int = -1
		For Local teamIndex:Int = 0 Until match.teams.length
			attractivityMod :+ match.teams[teamIndex].GetAttractivity()
			highestScore = Max(highestScore, match.points[teamIndex])
			If lowestScore = -1 Then lowestScore = match.points[teamIndex]
			lowestScore = Min(lowestScore, match.points[teamIndex])
		Next
		If match.teams.length > 0
			attractivityMod :/ match.teams.length
		Else
			attractivityMod = 1.0
		EndIf

		'game got more exciting ?
		If lowestScore <> highestScore And highestScore > 0
			'eg. 0 : 1
			If lowestScore = 0 And highestScore = 1 Then attractivityMod :+ 0.05
			'eg. 1 : 2
			If lowestScore/highestScore > 0.5 Then attractivityMod :+ 0.05
			'eg. 3 : 4
			If lowestScore/highestScore > 0.75 Then attractivityMod :+ 0.05
		EndIf


		Return MathHelper.Clamp(Self.outcomeTV * attractivityMod, 0.0, 1.0)
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetSpeed:Float()
		If Not matchGUID Then Return Self.speed
		Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		If Not match Then Return Self.speed

		'modify by "power" of the teams
		Local powerMod:Float = 0.0
		For Local team:TNewsEventSportTeam = EachIn match.teams
			powerMod :+ team.GetPower()
		Next
		If match.teams.length > 0
			powerMod :/ match.teams.length
		Else
			powerMod = 1.0
		EndIf

		Return MathHelper.Clamp(Self.speed * powerMod, 0.0, 1.0)
	End Method


	'returns a value from 0.0 - 1.0 (0-100%)
	Method GetReview:Float()
		If Not matchGUID Then Return Self.review
		Local match:TNewsEventSportMatch = GetNewsEventSportCollection().GetMatchByGUID(matchGUID)
		If Not match Then Return Self.review

		'modify by "skill" of the teams ("good soccer technics")
		Local skillMod:Float = 0.0
		For Local team:TNewsEventSportTeam = EachIn match.teams
			skillMod :+ team.GetSkill()
		Next
		If match.teams.length > 0
			skillMod :/ match.teams.length
		Else
			skillMod = 1.0
		EndIf

		Return MathHelper.Clamp(Self.review * skillMod, 0.0, 1.0)
	End Method


	Method GetReleaseTime:Long()
		Return releaseTime
	End Method


	Method GetCinemaReleaseTime:Long()
		Return releaseTime
	End Method


	'only useful for cinematic movies
	Method GetProductionStartTime:Long()
		Return releaseTime
	End Method

Rem
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


	Method UpdateLive:Int(calledAfterbroadCast:Int) override
		Super.UpdateLive(False)

		'refresh processedTitle (recreated on request)
		titleProcessed = Null
		descriptionProcessed = Null
	End Method

	'override
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		Super.doFinishBroadcast(playerID, broadcastType)
	End Method
End Type
