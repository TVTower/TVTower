-- File: DefaultAIPlayer
-- ============================
-- Autoren: Manuel Vögele (STARS_crazy@gmx.de)
--          Ronny Otto
-- Version: 25.05.2016

APP_VERSION = "1.4"

-- ##### INCLUDES #####
-- use slash for directories - windows accepts it, linux needs it
-- or maybe package.config:sub(1,1)
dofile("res/ai/DefaultAIPlayer/AIEngine.lua")
dofile("res/ai/DefaultAIPlayer/CommonObjects.lua")
dofile("res/ai/DefaultAIPlayer/BudgetManager.lua")
dofile("res/ai/DefaultAIPlayer/Strategy.lua")
dofile("res/ai/DefaultAIPlayer/TaskMovieDistributor.lua")
dofile("res/ai/DefaultAIPlayer/TaskNewsAgency.lua")
dofile("res/ai/DefaultAIPlayer/TaskAdAgency.lua")
dofile("res/ai/DefaultAIPlayer/TaskSchedule.lua")
dofile("res/ai/DefaultAIPlayer/TaskStationMap.lua")
dofile("res/ai/DefaultAIPlayer/TaskBoss.lua")
dofile("res/ai/DefaultAIPlayer/TaskRoomBoard.lua")
if (unitTestMode) then
	dofile("res/ai/DefaultAIPlayer/UnitTests.lua")
end

-- ##### GLOBALS #####
aiIsActive = true

TASK_MOVIEDISTRIBUTOR	= "MovieDistributor"
TASK_NEWSAGENCY			= "NewsAgency"
TASK_ARCHIVE			= "Archive"
TASK_ADAGENCY			= "AdAgency"
TASK_SCHEDULE			= "Schedule"
TASK_STATIONMAP			= "StationMap"
TASK_BETTY				= "Betty"
TASK_BOSS				= "Boss"
TASK_ROOMBOARD			= "RoomBoard"

_G["TASK_MOVIEDISTRIBUTOR"] = TASK_MOVIEDISTRIBUTOR
_G["TASK_NEWSAGENCY"] = TASK_NEWSAGENCY
_G["TASK_ARCHIVE"] = TASK_ARCHIVE
_G["TASK_ADAGENCY"] = TASK_ADAGENCY
_G["TASK_SCHEDULE"] = TASK_SCHEDULE
_G["TASK_STATIONMAP"] = TASK_STATIONMAP
_G["TASK_BETTY"] = TASK_BETTY
_G["TASK_BOSS"] = TASK_BOSS
_G["TASK_ROOMBOARD"] = TASK_ROOMBOARD

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["DefaultAIPlayer"] = class(AIPlayer, function(c)
	AIPlayer.init(c)	-- must init base!
	c.CurrentTask = nil
	c.Strategy = nil
	--c.Budget = nil  --darf nicht überschrieben werden
	--c.Stats = nil  --darf nicht überschrieben werden
	--c.Requisitions = nil  --darf nicht überschrieben werden
	
	c.Ventruesome = 5 --Risikofreude = 1 - 10
	c.NewsPriority = 5
	c.BrainSpeed = 1 --Wie schnell handelt die KI = 1-3 (Aktionen pro Tick)
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
	--self.NameX = "zzz"

	--TODO: Strategie und Charakter festlegen
	--Waghalsigkeit 3-8
	self.Ventruesome = math.random(3,8)
	--Interesse an News/Geldausgabe fuer News
	self.NewsPriority = math.random(3,8)
	--Handlungsgeschwindigkeit 2-4
	self.BrainSpeed = math.random(2,4)
	self.Strategy = DefaultStrategy()
end

function DefaultAIPlayer:resume()
	if (self.Strategy == nil) then
		infoMsg(self:typename() .. ": Resume Strategy")
		self.Strategy = DefaultStrategy()
	end
	
	if (self.Ventruesome == 0) then
		self.Ventruesome = 5
	end
	if (self.BrainSpeed == 0) then
		self.BrainSpeed = 1
	end
	
	self:CleanUp()
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	self.TaskList[TASK_MOVIEDISTRIBUTOR]	= TaskMovieDistributor()
	self.TaskList[TASK_NEWSAGENCY]			= TaskNewsAgency()
	self.TaskList[TASK_ADAGENCY]			= TaskAdAgency()
	self.TaskList[TASK_SCHEDULE]			= TaskSchedule()
	self.TaskList[TASK_STATIONMAP]			= TaskStationMap()
	self.TaskList[TASK_BOSS]				= TaskBoss()
	self.TaskList[TASK_ROOMBOARD]			= TaskRoomBoard()
	
	
	--self.TaskList[TASK_STATIONMAP].InvestmentPriority = 12
	--self.TaskList[TASK_STATIONMAP].NeededInvestmentBudget = 10000
	
	--self.TaskList[TASK_BETTY]			= TVTBettyTask()
	--self.TaskList[TASK_ARCHIVE]			= TVTArchive()

	--TODO: WarteTask erstellen. Gehört aber in AIEngine
end

function DefaultAIPlayer:TickAnalyse()
	self.Stats:ReadStats()
end


function DefaultAIPlayer:OnGameBegins()
	self.Strategy:Start(self)
end


function DefaultAIPlayer:OnDayBegins()
	--just in case we missed a "OnGameBegins"
	self.Strategy:Start(self)

	self.Stats:OnDayBegins()

	--Strategie vorher anpassen / Aufgabenparameter anpassen
	for k,v in pairs(self.TaskList) do
		v:AdjustmentsForNextDay()
	end	
	
	self.Budget:CalculateNewDayBudget()

	for k,v in pairs(self.TaskList) do
		v:OnDayBegins()
	end
	
	self:CleanUp()
end

function DefaultAIPlayer:OnMoneyChanged(value, reason, reference)
	self.Budget:OnMoneyChanged(value, reason, reference)
	for k,v in pairs(self.TaskList) do
		v:OnMoneyChanged(value, reason, reference)
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

function DefaultAIPlayer:GetNextEnemyId()
	--TODO: Erzfeind ermitteln und als Hauptziel zurückliefern	
	local result = -1	
	repeat
		result = math.random(1, 4)
	until result ~= TVT.ME	
	return result
end

function DefaultAIPlayer:CleanUp()
	infoMsg(self:typename() .. ": CleanUp")
	
	infoMsg("Requisitions (before): " .. table.count(self.Requisitions))	
	
	local tempList = table.copy(self.Requisitions)
	
	for k,v in pairs(tempList) do
		if (not v:CheckActuality()) then
			table.remove(self.Requisitions, index)
			infoMsg("Requisition removed")
		end
	end
	
	infoMsg("Requisitions (after): " .. table.count(self.Requisitions))	
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
	local currentAudience = MY.GetProgrammePlan().GetAudience()
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
		if licence.getData() ~= nil and licence.IsSingle() then
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
function OnBossCalls(latestWorldTime)
	infoMsg("Boss calls me! " .. latestWorldTime)
end

function OnBossCallsForced()
	infoMsg("Boss calls me NOW!")
end


function OnMoneyChanged(value, reason, reference)	
	if (aiIsActive) then
		getAIPlayer():OnMoneyChanged(value, reason, reference)
	end
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
		debugMsg("KI-Event: OnDayBegins")
		getAIPlayer():OnDayBegins()
	end
end


function OnProgrammeLicenceAuctionGetOutbid(licence, bid, bidderID)
	--todo
	debugMsg("TODO: you have been outbid on auction: " .. licence.GetTitle())
end

function OnProgrammeLicenceAuctionWin(licence, bid)
	--todo
	debugMsg("TODO: Won auction: " .. licence.GetTitle())
end

function OnPublicAuthoritiesConfiscateProgrammeLicence(confiscatedLicence, targetLicence)
	--todo
	debugMsg("Programme licence confiscated: " .. confiscatedLicence.GetTitle())
end

function OnLeaveRoom()
	--debugMsg("OnLeaveRoom")
end

-- figure approached the target room - will try to open the door soon
function OnReachRoom(roomId)
	--debugMsg("OnReachRoom" .. roomId)
end

-- figure is now trying to enter this room ("open door")
function OnBeginEnterRoom(roomId, result)
	--debugMsg("OnBeginEnterRoom" .. roomId .. " result=" .. result)
	if (aiIsActive) then
		getAIPlayer():OnBeginEnterRoom(roomId, result)
	end
end

-- figure is now in this room
function OnEnterRoom(roomId)
	--debugMsg("OnEnterRoom " .. roomId)
	if (aiIsActive) then
		getAIPlayer():OnEnterRoom(roomId)
	end
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


function OnRealTimeSecond(millisecondsPassed)
	--if (aiIsActive) then
		--getAIPlayer():Tick()
	--end
end


function OnTick(timeGone)
	--debugMsg("tick" .. timeGone)
	if (aiIsActive) then
		-- the faster the brain, the more it does per tick
		for i=1,getAIPlayer().BrainSpeed do
			getAIPlayer():Tick()
		end
	end
end


function OnMinute(number)
	--param "number" is passed as string
	number = tonumber(number)

	if number == 6 then 
		local task = getAIPlayer().TaskList[_G["TASK_SCHEDULE"]]
		if task then
			local broadcast = TVT.GetCurrentAdvertisement()
			if broadcast ~= nil then
				-- only for ads
				if broadcast.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) then
					local audience = MY.GetProgrammePlan().GetAudience()
					if audience < TVT.GetCurrentAdvertisementMinAudience() then
						debugMsg("ProgrammeBegin: FixAdvertisement " .. WorldTime.GetDayHour() .. ":55 !!!   minAudience=" .. TVT.GetCurrentAdvertisementMinAudience() .. " < " .. audience)
						task:FixAdvertisement(WorldTime.GetDay(), WorldTime.GetDayHour())
					end
				end
			end
		end
	end
--	debugMsg("OnMinute " .. number)
--	if (aiIsActive) then
--		getAIPlayer():Tick()
--	end

	--Zum Test
	--[[
	if (number == "4") then
		local task = getAIPlayer().TaskList[TASK_SCHEDULE]
		local guessedAudience = task:GuessedAudienceForHourAndLevel(WorldTime.GetDayHour())

		local fixedDay, fixedHour = FixDayAndHour(Worldtime.GetDay(), Worldtime.GetDayHour())
		local programme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)

		-- RON: changed as "programme" is NIL if not existing/placed
		local averageMovieQualityByLevel = 0
		if ( programme ~= nil) then
			averageMovieQualityByLevel = programme.GetQuality(0) -- Die Durchschnittsquote dieses Qualitätslevels
		end

		local level = task:GetQualityLevel(WorldTime.GetDayHour()) --Welchen Qualitätslevel sollte ein Film/Werbung um diese Uhrzeit haben
		local globalPercentageByHour = task:GetMaxAudiencePercentageByHour(WorldTime.GetDayHour()) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
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

function OnMalfunction()
	infoMsg("OnMalfunction1")
	local task = getAIPlayer().TaskList[_G["TASK_SCHEDULE"]]
	task.SituationPriority = 10
	infoMsg("OnMalfunction2")
end

--TVTMoviePurchase
--	BudgetWeight = 7
--	BasePriority = 8

--TVTNewsAgency
--	BudgetWeight = 3
--	BasePriority = 8

--TVTAdAgency
--	BudgetWeight = 0
--	BasePriority = 8

--TVTScheduling
--	BudgetWeight = 0
--	BasePriority = 10

--TVTStations
--	BudgetWeight = 2
--	BasePriority = 3

--TVTBettyTask
--	BudgetWeight = 1
--	BasePriority = 2

--TVTBossTask
--	BudgetWeight = 0
--	BasePriority = 5

--TVTArchive
--	BudgetWeight = 0
--	BasePriority = 3


--TVT.addLog(text)