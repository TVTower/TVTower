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

	Method GenerateGUID:string()
		return "broadcastmaterialsource-sportsprogrammedata-"+id
	End Method


	Method GetTitle:string()
		if title
			'replace placeholders and and cache the result
			if not titleProcessed
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
				descriptionProcessed = new TLocalizedString
				descriptionProcessed.Set( _LocalizeContent(description.Get()) )
			endif
			return descriptionProcessed.Get()
		endif
		return ""
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




	Method Update:int()
		Super.Update()

		'change title/text when match finishes
		print "Tore / ... hinzufuegen"
	End Method


	'override
	'called as soon as the last block of a programme ends
	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		Super.doFinishBroadcast(playerID, broadcastType)

		print "finish broadcast"
	End Method
End Type