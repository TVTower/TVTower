-- ##### INCLUDES #####
-- use slash for directories - windows accepts it, linux needs it
-- or maybe package.config:sub(1,1)
dofile("res/ai/AIEngine.lua")
dofile("res/ai/CommonObjects.lua")
dofile("res/ai/BudgetManager.lua")
dofile("res/ai/TaskMovieDistributor.lua")
dofile("res/ai/TaskNewsAgency.lua")
dofile("res/ai/TaskAdAgency.lua")
dofile("res/ai/TaskSchedule.lua")

-- ##### GLOBALS #####
aiIsActive = true

TASK_MOVIEDISTRIBUTOR	= "MovieDistributor"
TASK_NEWSAGENCY		= "NewsAgency"
TASK_ARCHIVE		= "Archive"
TASK_ADAGENCY		= "AdAgency"
TASK_SCHEDULE		= "Schedule"
TASK_STATIONS		= "Stations"
TASK_BETTY			= "Betty"
TASK_BOSS			= "Boss"

PROGRAM_MOVIE		= "movie"
PROGRAM_SERIES		= "series"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DefaultAIPlayer = AIPlayer:new{
	CurrentTask = nil;
	Budget = nil;
	Stats = nil
}

function DefaultAIPlayer:typename()
	return "DefaultAIPlayer"
end

function DefaultAIPlayer:initializePlayer()
	debugMsg("Initialisiere DefaultAIPlayer-KI ...")
	self.Stats = BusinessStats:new()
	self.Stats:Initialize()
	
	self.Budget = BudgetManager:new()
	self.Budget:Initialize()
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	self.TaskList[TASK_MOVIEDISTRIBUTOR]	= TaskMovieDistributor:new()
	--self.TaskList[TASK_NEWSAGENCY]		= TaskNewsAgency:new()
	--self.TaskList[TASK_ADAGENCY]		= TaskAdAgency:new()
	--self.TaskList[TASK_SCHEDULE]		= TaskSchedule:new()
	--self.TaskList[TASK_STATIONS]		= TVTStations:new()
	--self.TaskList[TASK_BETTY]			= TVTBettyTask:new()
	--self.TaskList[TASK_BOSS]			= TVTBossTask:new()
	--self.TaskList[TASK_ARCHIVE]			= TVTArchive:new()
end

function DefaultAIPlayer:TickAnalyse()
	self.Stats:ReadStats()
end

function DefaultAIPlayer:OnDayBegins()
	self.Stats:OnDayBegins()
	self.Budget:CalculateBudget()
	
	for k,v in pairs(self.TaskList) do
		v:OnDayBegins()
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
BusinessStats = SLFDataObject:new{
	Audience = nil;
	SpotProfit = nil;
	SpotProfitPerSpot = nil;
	SpotProfitPerSpotAcceptable = nil;
	SpotPenalty = nil;
	MoviePricePerBlockAcceptable = nil;
	SeriesPricePerBlockAcceptable = nil;
	MovieQualityAcceptable = nil;
	SeriesQualityAcceptable = nil;
	
	ProgramQualityLevel1 = nil;
	ProgramQualityLevel2 = nil;
	ProgramQualityLevel3 = nil;
	ProgramQualityLevel4 = nil;
	ProgramQualityLevel5 = nil;
}

function BusinessStats:Initialize()
	self.Audience = StatisticEvaluator:new()
	self.SpotProfit = StatisticEvaluator:new()
	self.SpotProfitPerSpot = StatisticEvaluator:new()
	self.SpotProfitPerSpotAcceptable = StatisticEvaluator:new()
	self.SpotPenalty = StatisticEvaluator:new()
	self.MoviePricePerBlockAcceptable = StatisticEvaluator:new()
	self.SeriesPricePerBlockAcceptable = StatisticEvaluator:new()
	self.MovieQualityAcceptable = StatisticEvaluator:new()
	self.SeriesQualityAcceptable = StatisticEvaluator:new()
	
	self.ProgramQualityLevel1 = StatisticEvaluator:new()
	self.ProgramQualityLevel2 = StatisticEvaluator:new()
	self.ProgramQualityLevel3 = StatisticEvaluator:new()
	self.ProgramQualityLevel4 = StatisticEvaluator:new()
	self.ProgramQualityLevel5 = StatisticEvaluator:new()
end

function BusinessStats:OnDayBegins()
	self.Audience:Adjust()
	self.SpotProfit:Adjust()
	self.SpotProfitPerSpot:Adjust()
	self.SpotProfitPerSpotAcceptable:Adjust()
	self.SpotPenalty:Adjust()
	self.MoviePricePerBlockAcceptable:Adjust()
	self.SeriesPricePerBlockAcceptable:Adjust()
	self.MovieQualityAcceptable:Adjust()
	self.SeriesQualityAcceptable:Adjust()
	
	self.ProgramQualityLevel1:Adjust()
	self.ProgramQualityLevel2:Adjust()
	self.ProgramQualityLevel3:Adjust()
	self.ProgramQualityLevel4:Adjust()
	self.ProgramQualityLevel5:Adjust()
end

function BusinessStats:ReadStats()	
	local currentAudience = TVT.getPlayerAudience()
	if (currentAudience == 0) then
		return;
	end
	
	--debugMsg("currentAudience: " .. currentAudience)
	self.Audience:AddValue(currentAudience)
	--debugMsg("Stats: " .. self.Audience.AverageValue .. " (" .. self.Audience.MinValue .. " - " .. self.Audience.MaxValue .. ")")
end

function BusinessStats:AddSpot(spot)
	self.SpotProfit:AddValue(spot.SpotProfit)
	self.SpotProfitPerSpot:AddValue(spot.SpotProfit / spot.SpotToSend)
	if (spot.Audience < globalPlayer.Stats.Audience.MaxValue) then
		self.SpotProfitPerSpotAcceptable:AddValue(spot.SpotProfit / spot.SpotToSend)
	end
	self.SpotPenalty:AddValue(spot.SpotPenalty)
end

function BusinessStats:AddMovie(movie)
	local maxPrice = globalPlayer.TaskList[TASK_MOVIEDISTRIBUTOR].BudgetWholeDay / 2
	if (movie:CheckConditions(maxPrice)) then -- Preisgrenze
		if (movie.ProgramType == PROGRAM_MOVIE) then
			self.MovieQualityAcceptable:AddValue(movie.Quality)
			self.MoviePricePerBlockAcceptable:AddValue(movie.PricePerBlock)
		elseif (movie.ProgramType == PROGRAM_SERIES) then
			self.SeriesQualityAcceptable:AddValue(movie.Quality)
			self.SeriesPricePerBlockAcceptable:AddValue(movie.PricePerBlock)
		end			
	end
end

function BusinessStats:GetAverageQualityByLevel(level)

end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- ###################################################################################################
-- Events die aus dem BlitzBasic-Programm aufgerufen werden
-- ###################################################################################################

function getAIPlayer()
	if globalPlayer == nil then
		globalPlayer = DefaultAIPlayer:new()
		_G["globalPlayer"] = globalPlayer --Macht "GlobalPlayer" als globale Variable verfügbar auch in eingebundenen Dateien
	end
	return globalPlayer
end

-- ##### EVENTS #####
function OnMoneyChanged()
end

function OnChat(message)
	if (message == "stop") then
		aiIsActive = false
		debugMsg("AI stopped!")
	elseif (message == "start") then
		aiIsActive = true
		debugMsg("AI started!")
	end
end

function OnDayBegins()
	if (aiIsActive) then
		getAIPlayer():OnDayBegins()
	end
end

function OnReachRoom(roomId)
	if (aiIsActive) then
		getAIPlayer():OnReachRoom()
	end
end

function OnLeaveRoom()
end

function OnMinute(number)	
	if (aiIsActive) then
		getAIPlayer():Tick()
	end
end