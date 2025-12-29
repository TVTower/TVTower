SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.award.base.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.broadcastmaterial.programme.bmx"

TAwardCollection.AddAwardCreatorFunction(TVTAwardType.GetAsString(TVTAwardType.CUSTOMPRODUCTION), TAwardCustomProduction.CreateAwardCustomProduction )


'AwardCustomProduction:
'Produce the best programmes of all channels.
'Score is given for:
'- the best of the productions done within the time
Type TAwardCustomProduction extends TAward
	Field bestLicences:TProgrammeLicence[]
	Global _eventListeners:TEventListenerBase[]


	Method New()
		awardType = TVTAwardType.CUSTOMPRODUCTION

		priceMoney = 50000
		priceImage = 1.5

		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'listen to finished productions
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Production_Finalize, onProductionFinalize) ]
	End Method


	Function CreateAwardCustomProduction:TAwardCustomProduction()
		return new TAwardCustomProduction
	End Function


	'override
	Method GenerateGUID:string()
		return "awardcustomproduction-"+id
	End Method


	Method GetDuration:Long() override
		if duration = -1
			'2days
			duration = GetWorldTime().GetTimeGoneForGameTime(0, 2, 0, 0)
		endif
		return duration
	End Method


	Method Finish:int(overrideWinnerID:Int = -1) override
		local result:int = Super.Finish(overrideWinnerID)

		'remove links to best productions
		bestLicences = null

		return result
	End Method


	Method UpdateBestScore(licence:TProgrammeLicence)
		if not licence then return

		local score:int = CalculateProgrammeLicenceScore(licence)
		local currentScore:int = GetScore(licence.owner)
		if score > currentScore
			'store new best licence
			if bestLicences.length < licence.owner then bestLicences = bestLicences[.. licence.owner]
			bestLicences[licence.owner-1] = licence
			'print "Awards: new best licence for #"+licence.owner+": " + licence.GetTitle()

			'adjust score
			AdjustScore(licence.owner, score - currentScore)
		endif
	End Method


	Function onProductionFinalize:int(triggerEvent:TEventBase)
		local currentAward:TAwardCustomProduction = TAwardCustomProduction(GetAwardCollection().GetCurrentAward())
		if not currentAward then return False

		local licence:TProgrammeLicence = TProgrammeLicence(triggerEvent.GetData().Get("programmelicence"))
		if not licence or licence.owner <= 0 then return False

		currentAward.UpdateBestScore(licence)
	End Function



	Function CalculateProgrammeLicenceScore:int(licence:TProgrammeLicence)
		if not licence or licence.owner < 0 then return 0
		'not of interest for us?
		if not licence.data.isAPlayersCustomProduction() then return 0
		'only check for custom production if winner could be
		'one of the generic programme producers too
		'if not licence.data.isCustomProduction() then return 0

		'calculate score:
		'a perfect production would give 100 points (plus personal
		'taste points)
		'- rawQuality as aging is not important for fresh productions
		'- "Trash/BMovie/PAID" decrease score
		'- "Culture" is adding a bit (jury likes culture!)
		'- good "review" values are adding too ("more intelligent story")

		local points:Float = 100 * licence.GetQualityRaw()
		local pointsMod:Float = 1.0

		if licence.HasFlag(TVTProgrammeDataFlag.TRASH) then pointsMod :- 0.075
		if licence.HasFlag(TVTProgrammeDataFlag.BMOVIE) then pointsMod :- 0.075
		if licence.HasFlag(TVTProgrammeDataFlag.PAID) then pointsMod :- 0.1
		if licence.HasFlag(TVTProgrammeDataFlag.CULTURE) then pointsMod :+ 0.075
		if licence.GetReview() > 0.5 then pointsMod :+ 0.05
		if licence.GetReview() > 0.75 then pointsMod :+ 0.05
		if licence.GetReview() > 0.90 then pointsMod :+ 0.05

		'calculate final score
		return int(ceil(Max(0, points * pointsMod)))
	End Function
End Type