-- File: DefaultAIPlayer
-- ============================
-- Autor: Manuel Vögele (STARS_crazy@gmx.de)
-- Version: 22.02.2014

APP_VERSION = "1.3"

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
_G["DefaultAIPlayer"] = class(AIPlayer, function(c)
	AIPlayer.init(c)	-- must init base!
	c.CurrentTask = nil	
	--c.Budget = nil  --darf nicht überschrieben werden
	--c.Stats = nil  --darf nicht überschrieben werden
	--c.Requisitions = nil  --darf nicht überschrieben werden
end)

function DefaultAIPlayer:typename()
	return "DefaultAIPlayer"
end

function DefaultAIPlayer:initializePlayer()
	debugMsg("Initialisiere DefaultAIPlayer-KI ...")
	self.Stats = BusinessStats()
	self.Stats:Initialize()
	self.Budget = BudgetManager()
	self.Budget:Initialize()
	self.Requisitions = {}
	self.NameX = "zzz"
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	self.TaskList[TASK_MOVIEDISTRIBUTOR]	= TaskMovieDistributor()
	self.TaskList[TASK_NEWSAGENCY]		= TaskNewsAgency()
	self.TaskList[TASK_ADAGENCY]		= TaskAdAgency()
	self.TaskList[TASK_SCHEDULE]		= TaskSchedule()

	--self.TaskList[TASK_STATIONS]		= TVTStations()
	--self.TaskList[TASK_BETTY]			= TVTBettyTask()
	--self.TaskList[TASK_BOSS]			= TVTBossTask()
	--self.TaskList[TASK_ARCHIVE]			= TVTArchive()

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
_G["BusinessStats"] = class(SLFDataObject, function(c)
	SLFDataObject.init(c)	-- must init base!
	c.Audience = nil;
	c.SpotProfit = nil;
	c.SpotProfitPerSpot = nil;
	c.SpotProfitPerSpotAcceptable = nil;
	c.SpotPenalty = nil;
	c.MoviePricePerBlockAcceptable = nil;
	c.SeriesPricePerBlockAcceptable = nil;
	c.MovieQualityAcceptable = nil;
	c.SeriesQualityAcceptable = nil;

	c.ProgramQualityLevel1 = nil;
	c.ProgramQualityLevel2 = nil;
	c.ProgramQualityLevel3 = nil;
	c.ProgramQualityLevel4 = nil;
	c.ProgramQualityLevel5 = nil;
end)

function BusinessStats:typename()
	return "BusinessStats"
end

function BusinessStats:Initialize()
	self.Audience = StatisticEvaluator()
	self.SpotProfit = StatisticEvaluator()
	self.SpotProfitPerSpot = StatisticEvaluator()
	self.SpotProfitPerSpotAcceptable = StatisticEvaluator()
	self.SpotPenalty = StatisticEvaluator()
	self.MoviePricePerBlockAcceptable = StatisticEvaluator()
	self.SeriesPricePerBlockAcceptable = StatisticEvaluator()
	self.MovieQualityAcceptable = StatisticEvaluator()
	self.SeriesQualityAcceptable = StatisticEvaluator()

	self.ProgramQualityLevel1 = StatisticEvaluator()
	self.ProgramQualityLevel2 = StatisticEvaluator()
	self.ProgramQualityLevel3 = StatisticEvaluator()
	self.ProgramQualityLevel4 = StatisticEvaluator()
	self.ProgramQualityLevel5 = StatisticEvaluator()
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
		globalPlayer = DefaultAIPlayer()
		globalPlayer:initialize()
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
		infoMsg("AI stopped!")
	elseif (message == "start") then
		aiIsActive = true
		infoMsg("AI started!")
	end
end

function OnDayBegins()
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
	return SLFManager:save()
end

function OnLoad(data)
	SLFManager:load(data)
	if SLFManager.LoadedData.Player:typename() == "DefaultAIPlayer" then
		infoMsg("Successfully Loaded!")
		_G["globalPlayer"] = SLFManager.LoadedData.Player
	else
		infoMsg("Loaded failed!")
	end
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
	--[[
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
	]]--
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