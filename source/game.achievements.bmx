SuperStrict
Import "game.achievements.base.bmx"

Import "game.broadcast.audienceresult.bmx"
Import "game.broadcast.base.bmx"
Import "game.world.worldtime.bmx"
Import "game.player.finance.bmx"

Type TAchievementTask_ReachAudience extends TAchievementTask
	Field minAudienceAbsolute:Int = -1
	Field minAudienceQuote:Float = -1.0
	Field limitToGenres:int = 0
	Field limitToFlags:int = 0
	'use -1 to ignore time
	Field checkHour:int = -1
	Field checkMinute:int = -1
	

	Method Init:TAchievementTask(config:object)
		local configData:TData = TData(config)
		if not configData then return null

		minAudienceAbsolute = configData.GetInt("minAudienceAbsolute", minAudienceAbsolute)
		minAudienceQuote = configData.GetFloat("minAudienceQuote", minAudienceQuote)

		limitToGenres = configData.GetInt("limitToGenres", limitToGenres)
		limitToFlags = configData.GetInt("limitToFlags", limitToFlags)

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



Type TAchievementReward_Money extends TAchievementReward
	Field money:int
	
	'override
	Method GetTitle:string()
		local t:string = Super.GetTitle()
		if not t then t = GetLocale("YOU_GET_X_MONEY_FOR_COMPLETING_THE_ACHIEVEMENT")
		return Super.GetTitle().Replace("%MONEY%", money)
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



local achievement:TAchievement = new TAchievement
local audienceConfig:TData = new TData.AddNumber("minAudienceAbsolute", 100000)
local moneyConfig:TData = new TData.AddNumber("money", 50000)

achievement.AddTask( new TAchievementTask_ReachAudience.Init(audienceConfig) )
achievement.AddReward( new TAchievementReward_Money.Init(moneyConfig) )
GetAchievementCollection().Add(achievement)