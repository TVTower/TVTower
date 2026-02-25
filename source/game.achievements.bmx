SuperStrict
Import "game.achievements.base.bmx"

Import "game.broadcast.audienceresult.bmx"
Import "game.broadcast.base.bmx"
Import "game.broadcastmaterial.news.bmx" 'TNewsshow
Import "game.broadcastmaterial.programme.bmx" 'TProgramme
Import "game.world.worldtime.bmx"
Import "game.player.finance.bmx"


Type TAchievementTask_FulfillAchievements extends TAchievementTask
	Field achievementGUIDs:string[]

	Method New()
'print "register fulfill listeners"
		eventListeners :+ [EventManager.registerListenerMethod(GameEventKeys.Achievement_OnComplete, self, "OnCompleteAchievement" )]
	End Method



	'override
	Function CreateNewInstance:TAchievementTask_FulfillAchievements()
		return new TAchievementTask_FulfillAchievements
	End Function


	Method Init:TAchievementTask_FulfillAchievements(config:object)
		local configData:TData = TData(config)
		if not configData then return null

		local num:int = 1
		local achievementGUID:string = configData.GetString("achievementGUID"+num, "")

		While achievementGuid
			achievementGUIDs :+ [achievementGUID]
			achievementGUID = configData.GetString("achievementGUID")
		Wend

		return self
	End Method


	Method OnCompleteAchievement:int(triggerEvent:TEventBase)
		local achievement:TAchievement = TAchievement(triggerEvent.GetSender())
		if not achievement then return False

		local time:long = triggerEvent.GetData().GetLong("time", -1)
		if time < 0 then return False

'print "on completing an achievement"

		local interested:int = False
		For local guid:string = EachIn achievementGUIDs
			if guid <> achievement.GetGUID() then continue

			interested = True
			exit
		Next
		if not interested then return False

		For local playerID:int = 1 to 4
			'player already completed that achievement
			if IsCompleted(playerID, time) or IsFailed(playerID, time) then continue

			Local completing:int = True
			For local guid:string = EachIn achievementGUIDs
				local checkAchievement:TAchievement = GetAchievementCollection().GetAchievement(guid)
				if not checkAchievement then continue

				'if one of the required is failing, we cannot complete
				if not checkAchievement.IsCompleted(playerID, time)
					completing = False
					exit
				endif
			Next

			if completing then SetCompleted(playerID, time)
		Next
	End Method


	'no override needed
	'we only update on achievement completitions
	'Method Update:int(time:long)
End Type




Type TAchievementTask_ReachAudience extends TAchievementTask
	Field minAudienceAbsolute:Int = -1
	Field minAudienceQuote:Float = -1.0
	Field limitToGenres:int = 0
	Field limitToFlags:int = 0
	'use -1 to ignore time
	Field checkHour:int = -1
	Field checkMinute:int = -1


	'override
	Function CreateNewInstance:TAchievementTask_ReachAudience()
		return new TAchievementTask_ReachAudience
	End Function


	'override
	Method GetTitle:string()
		local t:string = Super.GetTitle()
		if minAudienceAbsolute >= 0
			t = t.Replace("%VALUE%", TFunctions.LocalizedDottedValue(minAudienceAbsolute))
		elseif minAudienceQuote >= 0
			t = t.Replace("%VALUE%", TFunctions.LocalizedNumberToString(minAudienceQuote*100.0,2, True)+"%")
		endif
		return t
	End Method


	Method Init:TAchievementTask_ReachAudience(config:object)
		local configData:TData = TData(config)
		if not configData then return null

		minAudienceAbsolute = configData.GetInt("minAudienceAbsolute", minAudienceAbsolute)
		minAudienceQuote = configData.GetFloat("minAudienceQuote", minAudienceQuote)

		limitToGenres = configData.GetInt("limitToGenres", limitToGenres)
		limitToFlags = configData.GetInt("limitToFlags", limitToFlags)

		checkMinute = configData.GetInt("checkMinute", checkMinute)
		checkHour = configData.GetInt("checkHour", checkHour)

		return self
	End Method


	'override
	Method Update:int(time:long)
		'check for completitions
		if checkHour = -1 or GetWorldTime().GetDayHour(time) = checkHour
			if checkMinute = -1 or GetWorldTime().GetDayMinute(time) = checkMinute
				For local playerID:int = 1 to 4
					if IsCompleted(playerID, time) or IsFailed(playerID, time) then continue

					'todo: check genres/flags

					local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult(playerID)
					if not audienceResult or not audienceResult.audience then continue

					'handle defined limits for programmes
					if (limitToGenres or limitToFlags) and checkMinute>=5 and checkMinute<=54
						Local material:TProgramme = TProgramme(GetBroadcastManager().GetCurrentProgrammeBroadcastMaterial(playerID))
						if limitToGenres and (not material or material.licence.GetGenre() <> limitToGenres) then continue
						if limitToFlags and (not material or not material.licence.data.HasFlag(limitToFlags)) then continue
					endif

					if minAudienceAbsolute >= 0 and audienceResult.audience.GetTotalSum() > minAudienceAbsolute
						SetCompleted(playerID, time)
					endif
					if minAudienceQuote >= 0 and audienceResult.GetAudienceQuotePercentage() > minAudienceQuote
						SetCompleted(playerID, time)
					endif
				Next
			endif
		endif

		return Super.Update(time)
	End Method
End Type




Type TAchievementTask_ReachBroadcastArea extends TAchievementTask
	Field minReachAbsolute:Int = -1
	Field minReachPercentage:Float = -1.0


	'override
	Function CreateNewInstance:TAchievementTask_ReachBroadcastArea()
		local instance:TAchievementTask_ReachBroadcastArea = new TAchievementTask_ReachBroadcastArea

		'instead of registering them in "new()" (which is run for the
		'"creator instance" too) we do it here
		instance.RegisterEventListeners()

		return instance
	End Function


	Method RegisterEventListeners:int()
		Super.RegisterEventListeners()

		eventListeners :+ [EventManager.registerListenerMethod(GameEventKeys.StationMap_OnRecalculateAudienceSum, self, "onRecalculateAudienceSum" ) ]

		return True
	End Method


	'override
	Method GetTitle:string()
		local t:string = Super.GetTitle()
		if minReachAbsolute >= 0
			t = t.Replace("%VALUE%", TFunctions.LocalizedDottedValue(minReachAbsolute))
		elseif minReachPercentage >= 0
			t = t.Replace("%VALUE%", TFunctions.LocalizedNumberToString(minReachPercentage*100.0,2, True)+"%")
		endif
		return t
	End Method


	Method Init:TAchievementTask_ReachBroadcastArea(config:object)
		local configData:TData = TData(config)
		if not configData then return null

		minReachAbsolute = configData.GetInt("minReachAbsolute", minReachAbsolute)
		minReachPercentage = configData.GetFloat("minReachPercentage", minReachPercentage)

		return self
	End Method


	Method onRecalculateAudienceSum:int(triggerEvent:TEventBase)
		local map:TStationMap = TStationMap(triggerEvent.GetSender())
		if not map then return False

		local time:Long = GetWorldTime().GetTimeGone()


		if IsCompleted(map.owner, time) or IsFailed(map.owner, time) then return False

		if minReachAbsolute >= 0 and map.GetReceivers() >= minReachAbsolute
			SetCompleted(map.owner, time)
		endif
		if minReachPercentage >= 0 and map.GetReceiverCoverage() >= minReachPercentage
			SetCompleted(map.owner, time)
		endif

		return True
	End Method

	'not needed
	'Method Update:int(time:long)
End Type



Type TAchievementTask_BroadcastNewsShow extends TAchievementTask
	Field genre:int[] = [-1,-1,-1]
	Field minQuality:Float[] = [-1.0, -1.0, -1.0]
	Field maxQuality:Float[] = [-1.0, -1.0, -1.0]
	'news must have given keyword?
	Field keyword:string[] = ["", "", ""]


	'override
	Function CreateNewInstance:TAchievementTask_BroadcastNewsShow()
		local instance:TAchievementTask_BroadcastNewsShow = new TAchievementTask_BroadcastNewsShow

		'instead of registering them in "new()" (which is run for the
		'"creator instance" too) we do it here
		instance.RegisterEventListeners()

		return instance
	End Function


	Method RegisterEventListeners:int()
		Super.RegisterEventListeners()

		eventListeners :+ [EventManager.registerListenerMethod( GameEventKeys.Broadcast_Newsshow_BeginBroadcasting, self, "onNewsShowBeginBroadcasting" ) ]

		return True
	End Method


	'override
	Method GetTitle:string()
		local t:string = Super.GetTitle()

		For local i:int = 1 to 3
			t = t.Replace("%GENRE"+i+"%", GetLocale(TVTNewsGenre.GetAsString(genre[i-1])))
		Next

		return t
	End Method


	Method Init:TAchievementTask_BroadcastNewsShow(config:object)
		local configData:TData = TData(config)
		if not configData then return null

		For local i:int = 1 to 3
			genre[i-1] = configData.GetInt("genre"+i, genre[i-1])

			minQuality[i-1] = configData.GetFloat("minQuality"+i, minQuality[i-1])
			maxQuality[i-1] = configData.GetFloat("maxQuality"+i, maxQuality[i-1])

			keyword[i-1] = configData.GetString("keyword"+i, keyword[i-1])
		Next

		return self
	End Method


	Method onNewsShowBeginBroadcasting:int(triggerEvent:TEventBase)
		local show:TNewsShow = TNewsShow(triggerEvent.GetSender())
		if not show then return False

		local playerID:int = show.owner
		local time:Long = GetWorldTime().GetTimeGone()

		if IsCompleted(playerID, time) or IsFailed(playerID, time) then return False

		local ok:int = True
		For local i:int = 0 to 2
			local news:TNews = TNews(show.news[i])

			'check genres
			if genre[i] >= 0 and ok
				if not news or news.GetGenre() <> genre[i] then ok = False
			endif


			'check minQuality
			if ok and minQuality[i] >= 0 and (not news or news.GetQuality() < minQuality[i]) then ok = False


			'check maxQuality
			if ok and maxQuality[i] >= 0 and (not news or news.GetQuality() > maxQuality[i]) then ok = False


			'check keyword
			if ok and keyword[i] and (not news or not news.GetNewsEvent().HasKeyword(keyword[i])) then ok = False

			if not ok then exit
		Next
		if ok then SetCompleted(playerID, time)

		return ok
	End Method
End Type



Type TAchievementReward_Money extends TAchievementReward
	Field money:int


	'override
	Function CreateNewInstance:TAchievementReward_Money()
		return new TAchievementReward_Money
	End Function


	'override
	Method GetTitle:string()
		local t:string = Super.GetTitle()
		if not t then t = GetFormattedCurrency(money)
		return t
	End Method


	Method Init:TAchievementReward_Money(config:object)
		local configData:TData = TData(config)
		if not configData then return null

		money = configData.GetInt("money", money)

		return self
	End Method


	'overriden
	Method CustomGiveToPlayer:int(playerID:int)
		local finance:TPlayerFinance = GetPlayerFinance(playerID)
		if not finance then return False


		finance.EarnGrantedBenefits(money)
		return True
	End Method
End Type



'=== REGISTER CREATORS ===
'TASKS
GetAchievementCollection().RegisterElement("task::ReachAudience", new TAchievementTask_ReachAudience)
GetAchievementCollection().RegisterElement("task::ReachBroadcastArea", new TAchievementTask_ReachBroadcastArea)
GetAchievementCollection().RegisterElement("task::BroadcastNewsShow", new TAchievementTask_BroadcastNewsShow)
'REWARDS
GetAchievementCollection().RegisterElement("reward::Money", new TAchievementReward_Money)


rem
'=== EXAMPLE ===
local achievement:TAchievement = new TAchievement
local audienceConfig:TData = new TData.AddNumber("minAudienceAbsolute", 100000)
local moneyConfig:TData = new TData.AddNumber("money", 50000)
local task:TAchievementTask = TAchievementCollection.CreateTask("task::ReachAudience", audienceConfig)
local reward:TAchievementReward = TAchievementCollection.CreateReward("reward::Money", moneyConfig)

achievement.SetTitle(new TLocalizedString)
achievement.title.Set("Erreiche 100.000 Zuschauer", "de")
achievement.title.Set("Reach an audience of 100.000", "en")
achievement.AddTask( task.GetGUID() )
achievement.AddReward( reward.GetGUID() )
GetAchievementCollection().AddTask( task )
GetAchievementCollection().AddReward( reward )
GetAchievementCollection().AddAchievement( achievement )
endrem
