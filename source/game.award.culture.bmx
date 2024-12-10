SuperStrict
Import "Dig/base.util.event.bmx"
Import "game.award.base.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.broadcastmaterial.programme.bmx"

TAwardCollection.AddAwardCreatorFunction(TVTAwardType.GetAsString(TVTAwardType.CULTURE), TAwardCulture.CreateAwardCulture )


'AwardCulture:
'Send the most culture-linked things on your channel.
'Score is given for:
'- broadcasting culture programmes
'- broadcasting culture news
Type TAwardCulture extends TAward
	Field cultureBoost:Float = 0.1

	'how important are news for the award
	Global newsWeight:float = 0.25

	Global _eventListeners:TEventListenerBase[]


	Method New()
		awardType = TVTAwardType.CULTURE

		priceMoney = 40000
		priceImage = 1.5
		'for now this is 75/10000 so 0.75% but this is an absolute value 
		priceBettyLove = 75


		'=== REGISTER EVENTS ===
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'scan news shows for culture news
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcasting_BeforeFinishAllNewsShowBroadcasts, onBeforeFinishAllNewsShowBroadcasts) ]
		'scan programmes for culture-flag
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcasting_BeforeFinishAllProgrammeBlockBroadcasts, onBeforeFinishAllProgrammeBlockBroadcasts) ]
	End Method


	Function CreateAwardCulture:TAwardCulture()
		return new TAwardCulture
	End Function


	'override
	Method GenerateGUID:string()
		return "awardculture-"+id
	End Method


	'override to add boost-information
	Method GetRewardText:string()
		local result:string = Super.GetRewardText()
		if result then result :+ "~n"

		local valueStr:string = "|color=0,125,0|+" + MathHelper.NumberToString(cultureBoost*100, 2, True)+"%|/color|"
		local timeStr:string = " (" + GetLocale("FOR_X_HOURS").Replace("%X%", 24) + ")"
		result :+ chr(9654) + " " +StringHelper.UCFirst(GetLocale("ATTRACTIVITY"))+": "+GetLocale("PROGRAMME_FLAG_CULTURE")+" " + valueStr + timeStr
		return result
	End Method


	'override
	'add temporary culture-boost
	Method Finish:int(overrideWinnerID:Int = -1) override
		'If desired the winner value could be adjusted by the love betty
		'already feels for that player (diminishing returns ...)
		'if winningPlayerID > 0
		'	priceBettyLove = Ceil((1.0 - GetBetty().GetInLovePercentage(winningPlayerID)) * priceBettyLove) 
		'endif

		if not Super.Finish(overrideWinnerID) then return False


		if winningPlayerID > 0
			'add modifier for programmes with flag "culture"
			local modifier:TGameModifierBase = GetGameModifierManager().Create("Modifier.GameConfig")
			modifier.SetLongRunngingWithUndo()
			local mConfig:TData = new TData
			mConfig.AddString("name", "CultureBoost.Programme")
			mConfig.AddString("modifierKey", "Attractivity.ProgrammeDataFlag.player"+winningPlayerID+"."+TVTProgrammeDataFlag.CULTURE)
			mConfig.AddFloat("value", 0.1)
			mConfig.AddBool("relative", True)

			'activate for 1 day
			local mTimeCondition:TGameModifierCondition_TimeLimit = new TGameModifierCondition_TimeLimit
			mTimeCondition.SetTimeBegin( GetWorldTime().GetTimeGone() )
			mTimeCondition.SetTimeEnd( GetWorldTime().GetTimeGone() + 1 * TWorldTime.DAYLENGTH )

			modifier.Init(mConfig)
			modifier.AddCondition(mTimeCondition)
			GetGameModifierManager().Add( modifier )


			'same for culture-news
			modifier = GetGameModifierManager().Create("Modifier.GameConfig")
			modifier.SetLongRunngingWithUndo()
			mConfig = new TData
			mConfig.AddString("name", "CultureBoost.News")
			mConfig.AddString("modifierKey", "Attractivity.NewsGenre.player"+winningPlayerID+"."+TVTNewsGenre.CULTURE)
			mConfig.AddFloat("value", 0.1)
			mConfig.AddBool("relative", True)

			'simple reuse time condition of programmes (shared condition)

			modifier.Init(mConfig)
			modifier.AddCondition(mTimeCondition)
			GetGameModifierManager().Add( modifier )
		endif

		return True
	End Method


	Function onBeforeFinishAllNewsShowBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardCulture = TAwardCulture(GetAwardCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))
		For local newsShow:TNewsShow = Eachin broadcasts
			local score:int = CalculateNewsShowScore(newsShow)
			if score = 0 then continue

			currentAward.AdjustScore(newsShow.owner, score)
		Next
	End Function


	Function onBeforeFinishAllProgrammeBlockBroadcasts:int(triggerEvent:TEventBase)
		local currentAward:TAwardCulture = TAwardCulture(GetAwardCollection().GetCurrentAward())
		if not currentAward then return False

		local broadcasts:TBroadcastMaterial[] = TBroadcastMaterial[](triggerEvent.GetData().Get("broadcasts"))

		For local broadcastMaterial:TBroadcastMaterial = Eachin broadcasts
			'only material which ends now ? So a 5block culture would get
			'ignored if ending _after_ award time
			'if broadcastMaterial.currentBlockBroadcasting <> broadcastMaterial.GetBlocks()

			local score:int = CalculateProgrammeScore(broadcastMaterial)
			if score = 0 then continue

			currentAward.AdjustScore(broadcastMaterial.owner, score)
		Next
	End Function


	Function CalculateProgrammeScore:int(broadcastMaterial:TBroadcastMaterial)
		'for now only handle "programmes", not "infomercials"
		local programme:TProgramme = TProgramme(broadcastMaterial)
		if not programme or programme.owner < 0 then return 0
		'not of interest for us?
		if programme.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_AWARDS) then return 0


		'calculate score:
		'a perfect culture programme would give 1000 points (plus personal
		'taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- "Live" increases score
		'- "Trash/BMovie" decrease score

		'only interested in culture-programmes
		if not programme.data.HasFlag(TVTProgrammeDataFlag.CULTURE) then return 0

		local points:Float = 1000 * broadcastMaterial.GetQuality()
		local pointsMod:Float = 1.0

		if programme.data.HasFlag(TVTProgrammeDataFlag.LIVE) then pointsMod :+ 0.1
		if programme.data.HasFlag(TVTProgrammeDataFlag.TRASH) then pointsMod :- 0.1
		if programme.data.HasFlag(TVTProgrammeDataFlag.BMOVIE) then pointsMod :- 0.1
		if programme.data.HasFlag(TVTProgrammeDataFlag.PAID) then pointsMod :- 0.2

		'divide by block count so each block adds some points
		points :/ programme.GetBlocks()

		'calculate final score
		return int(ceil(Max(0, points * pointsMod)))
	End Function


	Function CalculateNewsShowScore:int(newsShow:TNewsShow)
		if not newsShow
			TLogger.Log("TAwardNews.CalculateNewsShowScore()", "No valid TNewsSow-material given.", LOG_ERROR)
			return 0
		endif
		if newsShow.owner < 0 then return 0


		'calculate score:
		'a perfect culture news would give 1000 points (plus personal
		'taste points)
		'- topicality<1.0 and rawQuality<1.0 reduce points -> GetQuality()
		'- no need to handle multiple slots - each culture news brings
		'  score, no average building needed

		local allPoints:Float = 0.0
		For local i:int = 0 until newsShow.news.length
			local news:TNews = TNews(newsShow.news[i])
			if not news or news.GetGenre() <> TVTNewsGenre.CULTURE then continue
			'not of interest for us?
			if news.SourceHasBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORED_BY_AWARDS) then continue

			local newsPoints:Float = 1000 * news.GetQuality() * TNewsShow.GetNewsSlotWeight(i)
			local newsPointsMod:Float = 1.0

			'jury likes good news - and dislikes the really bad ones
			if news.GetNewsEvent().GetQualityRaw() >= 0.2
				newsPointsMod :+ 0.2
			else
				newsPointsMod :- 0.2
			endif

			allPoints :+ Max(0, newsPoints * newsPointsMod)
		Next

		'calculate final score
		'news have only a small influence
		return int(ceil(newsWeight * allPoints))
	End Function
End Type