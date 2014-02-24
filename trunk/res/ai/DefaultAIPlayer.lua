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
if (unitTestMode) then
	dofile("res/ai/UnitTests.lua")
end

-- ##### GLOBALS #####
aiIsActive = true

TASK_MOVIEDISTRIBUTOR	= "MovieDistributor"
TASK_NEWSAGENCY	= "NewsAgency"
TASK_ARCHIVE		= "Archive"
TASK_ADAGENCY		= "AdAgency"
TASK_SCHEDULE		= "Schedule"
TASK_STATIONS		= "Stations"
TASK_BETTY		= "Betty"
TASK_BOSS			= "Boss"

_G["TASK_MOVIEDISTRIBUTOR"] = TASK_MOVIEDISTRIBUTOR
_G["TASK_NEWSAGENCY"] = TASK_NEWSAGENCY
_G["TASK_ARCHIVE"] = TASK_ARCHIVE
_G["TASK_ADAGENCY"] = TASK_ADAGENCY
_G["TASK_SCHEDULE"] = TASK_SCHEDULE
_G["TASK_STATIONS"] = TASK_STATIONS
_G["TASK_BETTY"] = TASK_BETTY
_G["TASK_BOSS"] = TASK_BOSS

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DefaultAIPlayer = AIPlayer:new{
	CurrentTask = nil;
	Budget = nil;
	Stats = nil;
	Requisitions = nil
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

	self.Requisitions = {}
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	self.TaskList[TASK_MOVIEDISTRIBUTOR]	= TaskMovieDistributor:new()
	self.TaskList[TASK_NEWSAGENCY]		= TaskNewsAgency:new()
	self.TaskList[TASK_ADAGENCY]		= TaskAdAgency:new()
	self.TaskList[TASK_SCHEDULE]		= TaskSchedule:new()

	--self.TaskList[TASK_STATIONS]		= TVTStations:new()
	--self.TaskList[TASK_BETTY]			= TVTBettyTask:new()
	--self.TaskList[TASK_BOSS]			= TVTBossTask:new()
	--self.TaskList[TASK_ARCHIVE]			= TVTArchive:new()

	--TODO: WarteTask erstellen. Gehört aber in AIEngine
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

function DefaultAIPlayer:AddRequisition(requisition)
	table.insert(self.Requisitions, requisition)
end

function DefaultAIPlayer:RemoveRequisition(requisition)
	local index = table.getIndex(self.Requisitions, requisition)
	if (index ~= -1) then
		table.remove(self.Requisitions, index)
	end
end

function DefaultAIPlayer:GetRequisitionPriority(taskId)
	local prio = 0

	for k,v in pairs(self.Requisitions) do
		if (v:CheckActuality() and v.TaskId == taskId) then
			prio = prio + v.Priority
		end
	end

	return prio
end

function DefaultAIPlayer:GetRequisitionsByTaskId(taskId)
	local result = {}

	for k,v in pairs(self.Requisitions) do
		if (v:CheckActuality() and v.TaskId == taskId) then
			table.insert(result, v)
		end
	end

	return result
end

function DefaultAIPlayer:GetRequisitionsByOwner(taskId)
	local result = {}

	for k,v in pairs(self.Requisitions) do
		if (v:CheckActuality() and v.TaskOwnerId == taskId) then
			table.insert(result, v)
		end
	end

	return result
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

function BusinessStats:typename()
	return "BusinessStats"
end

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
	local currentAudience = MY.GetAudience()
	if (currentAudience == 0) then
		return;
	end

	--debugMsg("currentAudience: " .. currentAudience)
	self.Audience:AddValue(currentAudience)
	--debugMsg("Stats: " .. self.Audience.AverageValue .. " (" .. self.Audience.MinValue .. " - " .. self.Audience.MaxValue .. ")")
end

function BusinessStats:AddSpot(spot)
	self.SpotProfit:AddValue(spot.GetProfit())
	self.SpotProfitPerSpot:AddValue(spot.GetProfit() / spot.GetSpotCount())
	if (spot.GetMinAudience() < globalPlayer.Stats.Audience.MaxValue) then
		self.SpotProfitPerSpotAcceptable:AddValue(spot.GetProfit() / spot.GetSpotCount())
	end
	self.SpotPenalty:AddValue(spot.GetPenalty())
end

function BusinessStats:AddMovie(licence)
--RON
--TVT.PrintOut("RON: AddMovie")

	local maxPrice = globalPlayer.TaskList[TASK_MOVIEDISTRIBUTOR].BudgetWholeDay / 2
	if (CheckMovieBuyConditions(licence, maxPrice)) then -- Preisgrenze
		local quality = licence.GetQuality(0)
		if licence.getData() ~= nil and licence.IsMovie() then
			self.MovieQualityAcceptable:AddValue(quality)
			self.MoviePricePerBlockAcceptable:AddValue(licence:GetPricePerBlock())
		else
			self.SeriesQualityAcceptable:AddValue(quality)
			self.SeriesPricePerBlockAcceptable:AddValue(licence:GetPricePerBlock())
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
	TVT.addToLog("OnDayBegins")
	if (aiIsActive) then
		debugMsg("OnDayBegins!")
		getAIPlayer():OnDayBegins()
	end
end

function OnReachRoom(roomId)
	if (aiIsActive) then
		getAIPlayer():OnReachRoom(roomId)
	end
end

function OnLeaveRoom()
end

function OnSave()
	SLFManager.StoreDefinition.Player = getAIPlayer()
	return SLFManager.save()
end

function OnLoad(data)
	SLFManager.load(data)
end

function FixDayAndHour2(day, hour)
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
end

function OnMinute(number)
	if (aiIsActive) then
		getAIPlayer():Tick()
	end

	--Zum Test
	if (number == "4") then
		local task = getAIPlayer().TaskList[TASK_SCHEDULE]
		local guessedAudience = task:GuessedAudienceForHourAndLevel(Game.GetHour())

		local fixedDay, fixedHour = FixDayAndHour2(Game.GetDay(), Game.GetHour())
		local programme = MY.ProgrammePlan.GetProgramme(fixedDay, fixedHour)

		-- RON: changed as "programme" is NIL if not existing/placed
		local averageMovieQualityByLevel = 0
		if ( programme ~= nil) then
			averageMovieQualityByLevel = programme.GetQuality(0) -- Die Durchschnittsquote dieses Qualitätslevels
		end

		local level = task:GetQualityLevel(Game.GetHour()) --Welchen Qualitätslevel sollte ein Film/Werbung um diese Uhrzeit haben
		local globalPercentageByHour = task:GetMaxAudiencePercentageByHour(Game.GetHour()) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
		--local averageMovieQualityByLevel = task:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels
		local guessedAudience2 = averageMovieQualityByLevel * globalPercentageByHour * MY.GetMaxAudience()

		if ( programme ~= nil) then
			TVT.addToLog("LUA-Audience (" .. programme.GetID() .. ") : " .. math.round(guessedAudience2) .. " => averageMovieQualityByLevel (" .. averageMovieQualityByLevel .. ") ; globalPercentageByHour (" .. globalPercentageByHour .. ")")
		else
			TVT.addToLog("LUA-Audience (NO PROG) : " .. math.round(guessedAudience2) .. " => averageMovieQualityByLevel (" .. averageMovieQualityByLevel .. ") ; globalPercentageByHour (" .. globalPercentageByHour .. ")")
		end
	end
end

--TVTMoviePurchase
--	BudgetWeigth = 7
--	BasePriority = 8

--TVTNewsAgency
--	BudgetWeigth = 3
--	BasePriority = 8

--TVTAdAgency
--	BudgetWeigth = 0
--	BasePriority = 8

--TVTScheduling
--	BudgetWeigth = 0
--	BasePriority = 10

--TVTStations
--	BudgetWeigth = 2
--	BasePriority = 3

--TVTBettyTask
--	BudgetWeigth = 1
--	BasePriority = 2

--TVTBossTask
--	BudgetWeigth = 0
--	BasePriority = 5

--TVTArchive
--	BudgetWeigth = 0
--	BasePriority = 3


--TVT.addLog(text)