-- File: DefaultAIPlayer
-- ============================
-- Autoren: Manuel Vögele (STARS_crazy@gmx.de)
--          Ronny Otto
-- Version: 06.07.2019

_G["APP_VERSION"] = "1.8"

-- this is defined by the game engine if called from there
-- else the file was opened via a direct call
if CURRENT_WORKING_DIR == nil and debug.getinfo(2, "S") then
	CURRENT_WORKING_DIR = debug.getinfo(2, "S").source:sub(2):match("(.*[/\\])") or "."
	package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'
end

-- ##### INCLUDES #####
-- use slash for directories - windows accepts it, linux needs it
-- or maybe package.config:sub(1,1)
--[[
require "AIEngine"
require "CommonObjects"
require "BudgetManager"
require "Strategy"
require "TaskMovieDistributor"
require "TaskNewsAgency"
require "TaskAdAgency"
require "TaskSchedule"
require "TaskStationMap"
require "TaskBoss"
require "TaskRoomBoard"
require "TaskArchive"
if (unitTestMode) then require "UnitTests" end
]]
--
dofile("res/ai/CommonAI/AIEngine.lua")

local scriptPath = "res/ai/DefaultAIPlayer/"
--local scriptPath = ""
dofile(scriptPath .. "CommonObjects.lua")
dofile(scriptPath .. "BudgetManager.lua")
dofile(scriptPath .. "Strategy.lua")
dofile(scriptPath .. "TaskMovieDistributor.lua")
dofile(scriptPath .. "TaskNewsAgency.lua")
dofile(scriptPath .. "TaskAdAgency.lua")
dofile(scriptPath .. "TaskSchedule.lua")
dofile(scriptPath .. "TaskStationMap.lua")
dofile(scriptPath .. "TaskBoss.lua")
dofile(scriptPath .. "TaskRoomBoard.lua")
dofile(scriptPath .. "TaskCheckSigns.lua")
dofile(scriptPath .. "TaskArchive.lua")
dofile(scriptPath .. "TaskScripts.lua")
if (unitTestMode) then
	dofile(scriptPath .. "UnitTests.lua")
end
--]]

--TODO log levels for "global" functions in this file, replace debugMsg

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
TASK_CHECKSIGNS			= "CheckSigns"
TASK_SCRIPTS			= "Scripts"

_G["TASK_MOVIEDISTRIBUTOR"] = TASK_MOVIEDISTRIBUTOR
_G["TASK_NEWSAGENCY"] = TASK_NEWSAGENCY
_G["TASK_ARCHIVE"] = TASK_ARCHIVE
_G["TASK_ADAGENCY"] = TASK_ADAGENCY
_G["TASK_SCHEDULE"] = TASK_SCHEDULE
_G["TASK_STATIONMAP"] = TASK_STATIONMAP
_G["TASK_BETTY"] = TASK_BETTY
_G["TASK_BOSS"] = TASK_BOSS
_G["TASK_ROOMBOARD"] = TASK_ROOMBOARD
_G["TASK_CHECKSIGNS"] = TASK_CHECKSIGNS
_G["TASK_SCRIPTS"] = TASK_SCRIPTS

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["DefaultAIPlayer"] = class(AIPlayer, function(c)
	AIPlayer.init(c)	-- must init base!
	c.Strategy = nil
	--c.Budget = nil  --darf nicht überschrieben werden
	--c.Stats = nil  --darf nicht überschrieben werden
	--c.Requisitions = nil  --darf nicht überschrieben werden

	c.LastStationMapMarketAnalysis = 0
	c.LogLevel = LOG_INFO
end)

function DefaultAIPlayer:typename()
	return "DefaultAIPlayer"
end

function DefaultAIPlayer:LogInfo(message)
	logWithLevel(self.LogLevel, LOG_INFO, message)
end

function DefaultAIPlayer:LogDebug(message)
	logWithLevel(self.LogLevel, LOG_DEBUG, message)
end

function DefaultAIPlayer:initParameters()
	if self.hour == nil then
		self.hour = TVT:GetDayHour()
		self.minute = TVT:GetDayMinute()
		self.gameDay = TVT:GetDaysRun() + 1
		self.minutesGone = TVT:GetTimeGoneInMinutes()
	end
	self.money = TVT:GetMoney()

	if (self.Ventruesome == nil or self.Ventruesome <= 0) then
		--Waghalsigkeit 3-8
		self.Ventruesome = math.random(3,8)
	end
	if (self.NewsPriority == nil or self.NewsPriority <= 0) then
		--Interesse an News/Geldausgabe fuer News
		self.NewsPriority = math.random(3,8)
	end
	if (self.ExpansionPriority == nil or self.ExpansionPriority <= 0) then
		self.ExpansionPriority = math.random(3,8)
	end
	if (self.BrainSpeed == nil or self.BrainSpeed <= 0) then
		--Handlungsgeschwindigkeit
		self.BrainSpeed = math.random(4,6)
	end
	--eagerness to start the next task
	if (self.startTaskAtPriority == nil or self.startTaskAtPriority <= 0) then
		self.startTaskAtPriority = math.random(17,25)
	end

	--for checking that the same parameters are still used after loading a saved game
	self:LogDebug("initializing ".. self.Ventruesome.. " ".. self.NewsPriority .." ".. self.ExpansionPriority .." " .. self.BrainSpeed)
end

function DefaultAIPlayer:initializePlayer()
	self:LogInfo("Initialisiere DefaultAIPlayer-KI ...")
	self.Stats = BusinessStats()
	self.Stats:Initialize()
	self.Budget = BudgetManager()
	self.Budget:Initialize()
	self.Requisitions = {}
	--self.NameX = "zzz"

	self:initParameters()

	--strategy of the player
	self.Strategy = DefaultStrategy()

	--TODO if saving is too low, boss credit will not be repaid (budget for boss task?
	--if it is too big, not enough money is available for movies (investment savings?) 
	-- budget saving from 10-30%
	--self.Budget.SavingParts = 0.1 + 0.05 * math.random(0,4)
	self.Budget.SavingParts = 0
	-- extra safety add-to-fixed-costs from 40-70%
	--self.Budget.ExtraFixedCostsSavingsPercentage = 0.4 + 0.10 * math.random(0,3)
	self.Budget.ExtraFixedCostsSavingsPercentage = 0

	self.archEnemyID = -1

	self.programmeLicencesInSuitcaseCount = 0
	self.programmeLicencesInArchiveCount = 0
	self.licencesToSell = {}
	self.blocksCount = 0
	self.maxTopicalityBlocksCount = 0

	self.currentAwardType = -1
	self.currentAwardStartTime = -1
	self.currentAwardEndTime = -1
	self.nextAwardType = -1
	self.nextAwardStartTime = -1
	self.nextAwardEndTime = -1
end

function DefaultAIPlayer:resume()
	-- during loading in of a savegame, this might be used by other
	-- elements, so better set it already
	_G["globalPlayer"] = self

	if (self.Strategy == nil) then
		self:LogInfo(self:typename() .. ": Resume Strategy")
		self.Strategy = DefaultStrategy()
	end

	if (self.TaskList[TASK_CHECKSIGNS] == nil) then
		self.TaskList[TASK_CHECKSIGNS] = TaskCheckSigns()
	end
	if (self.TaskList[TASK_SCRIPTS] == nil) then
		self.TaskList[TASK_SCRIPTS] = TaskScripts()
	end
	if self.licencesToSell == nil then
		self.licencesToSell = {}
		self.blocksCount = 0
		self.maxTopicalityBlocksCount = 0
	end

	self:initParameters()

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
	self.TaskList[TASK_CHECKSIGNS]			= TaskCheckSigns()
	self.TaskList[TASK_ARCHIVE]				= TaskArchive()
	self.TaskList[TASK_SCRIPTS]				= TaskScripts()
	--when adding new tasks, they may have to be added in "resume" as well (save game compatibility)

	--self.TaskList[TASK_BETTY]			= TVTBettyTask()

	--TODO: WarteTask erstellen. Gehört aber in AIEngine
end


function DefaultAIPlayer:TickAnalyse()
	self.Stats:ReadStats()
end


function DefaultAIPlayer:OnGameBegins()
	self.Strategy:Start(self)

	--LOAD COMPATIBILITY
	if (self.Stats.SpotProfit == nil) then
		--spot statistics were renamed - prevent NPE
		self.Stats.SpotProfit = StatisticEvaluator()
		self.Stats.SpotProfitPerSpot = StatisticEvaluator()
		self.Stats.SpotPenalty = StatisticEvaluator()
		self.Stats.SpotPenaltyPerSpot = StatisticEvaluator()
		self.Stats.MovieQuality = StatisticEvaluator()
	end
	--END LOAD COMPATIBILITY

	if self.LogLevel >= LOG_DEBUG then
		self:LogDebug("--------------------")
		local se = StatisticEvaluator()
		for j = 0, 3 do
			self:LogInfo("run " .. j)
			for i = 0, 2 do
				se:AddValue(1 + i*2)
				self:LogDebug("added " .. i .. ".  AverageValue=" .. se.AverageValue .. "  minValue=" .. se.MinValue .. "  maxValue=" .. se.MaxValue .. "  TotalSum=" .. se.TotalSum .. "  CurrentValue=" .. se.CurrentValue .. "  Values=" .. se.Values)
			end
			se:Adjust()
			self:LogDebug("adjusted.  AverageValue=" .. se.AverageValue .. "  minValue=" .. se.MinValue .. "  maxValue=" .. se.MaxValue .. "  TotalSum=" .. se.TotalSum .. "  CurrentValue=" .. se.CurrentValue .. "  Values=" .. se.Values)
		end
		self:LogDebug("--------------------")
	end
end


function DefaultAIPlayer:OnInit()
	self.Strategy:Start(self)

	--on start, schedule should be high priority
	playerAI.TaskList[TASK_SCHEDULE].SituationPriority = 25
end


function DefaultAIPlayer:OnDayBegins()
	--ensure money value is correct for all onDayBegins-calls
	self.money = TVT:GetMoney()
	self.difficulty = MY.difficultyGUID
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


-- a player just went bankrupt
function DefaultAIPlayer:OnPlayerGoesBankrupt(playerID)
	playerID = tonumber(playerID)
	if playerID < 1 or playerID > 4 then
		return
	end

	-- reset quality stats
	for hour=1, 24 do
		self.Stats.playerProgrammeQualities[playerID][hour] = StatisticEvaluator()
	end
end


function DefaultAIPlayer:OnMoneyChanged(value, reason, reference)
	value = tonumber(value)
	--multiple fixed-costs events trigger unnecessary calls; but modifying the current value would result
	--in invalid value (after onDayBegins)
	self.money = TVT:GetMoney()
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


function DefaultAIPlayer:RemoveRequisitionByReason(reason)
	if self.Requisitions == nil then return; end

	local removeList = {}
	for k,v in pairs(self.Requisitions) do
		if v.reason and v.reason == reason then
			table.insert(removeList, v)
		end
	end

	for k,v in pairs(removeList) do
		self.RemoveRequisition(v)
	end
end


function DefaultAIPlayer:GetRequisitionPriority(taskId)
	local prio = 0
	for k,v in pairs(self.Requisitions) do
		if (v.TaskId == taskId and v:CheckActuality()) then
			prio = prio + v.Priority
		end
	end

	return prio
end


function DefaultAIPlayer:GetRequisitionsByTaskId(taskId, ignoreActuality)
	local result = {}

	for k,v in pairs(self.Requisitions) do
		if (v.TaskId == taskId and (v:CheckActuality() or ignoreActuality == true)) then
			table.insert(result, v)
		end
	end

	return result
end


function DefaultAIPlayer:GetRequisitionsByOwner(TaskOwnerId, ignoreActuality)
	local result = {}

	for k,v in pairs(self.Requisitions) do
		if (v.TaskOwnerId == TaskOwnerId and (v:CheckActuality() or ignoreActuality == true)) then
			table.insert(result, v)
		end
	end

	return result
end


function DefaultAIPlayer:GetArchEnemyId()
	-- TODO - change arch enemy according to a channels performance?
	if not self.archEnemyID or self.archEnemyID <= 0 then
		self.archEnemyID = -1
		repeat
			self.archEnemyID = math.random(1, 4)
		until self.archEnemyID ~= TVT.ME
	end
	return self.archEnemyID
end


function DefaultAIPlayer:GetNextEnemyId()
	local result = -1
	repeat
		-- +50% chance to return the arch enemy
		result = math.random(1, 4 + 4)
	until result ~= TVT.ME
	if result > 4 then result = self:GetArchEnemyId() end

	return result
end

function DefaultAIPlayer:CleanUp()
	self:LogDebug(self:typename() .. ": CleanUp")

	self:LogDebug("Requisitions (before): " .. table.count(self.Requisitions))

	local tempList = table.copy(self.Requisitions)

	for k,v in pairs(tempList) do
		if (not v:CheckActuality()) then
			table.remove(self.Requisitions, index)
			self:LogDebug("Requisition removed")
		end
	end

	local day = TVT.GetDay() - 2
	for hour = 0, 23 do
		MY:RemoveAIData("guessedaudience_" .. day .."_".. hour)
	end

	self:LogDebug("Requisitions (after): " .. table.count(self.Requisitions))
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["LicencePerformance"] = class(SLFDataObject, function(c)
	SLFDataObject.init(c)	-- must init base!
	c.idToDataMap = {};

end)

function LicencePerformance:typename()
	return "LicencePerformance"
end

function LicencePerformance:addData(hour, broadcast, audienceResult)
	if broadcast~=nil then
		local src=broadcast:getSource()
		if broadcast.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1 then
			local licence = broadcast.licence
			if (licence ~= nil and licence:GetRelativeTopicality() > 0.97) then
				--use referenceID for easy integration with archive task
				local licenceId = licence.GetReferenceID()
				--aggreagate series results (easier for selling, more genre data in one place)
				if licence:HasParentLicence() > 0 then
					local parent = licence:GetParentLicence()
					if parent ~= nil then
						licenceId = parent.GetReferenceID()
					end
				end
				local data = self.idToDataMap[licenceId]
				if data == nil then
					data = {
						licenceId = licenceId;
						genre = licence.GetGenre(); --for potential genre performance analysis
						best = -2; --global best quote
						worst = 2; --global worst quote
						hourAvg = {}; --quote per hour (genre performance)
					}
					self.idToDataMap[licenceId] = data
				end
				local quote = audienceResult.GetAudienceQuotePercentage(-1)
				if data.best < quote then
					data.best = quote
				end
				if data.worst > quote then
					data.worst = quote
				end
				local ha = data.hourAvg[hour]
				if (ha == nil) then
					data.hourAvg[hour] = quote
				else
					--favouring current value is OK
					data.hourAvg[hour] = (ha + quote)/2.0
				end
			end
		end
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BusinessStats"] = class(SLFDataObject, function(c)
	SLFDataObject.init(c)	-- must init base!
	c.Audience = nil;
	c.BroadcastStatistics = nil;
	c.SpotProfit = nil;
	c.SpotProfitPerSpot = nil;
	c.SpotPenalty = nil;
	c.SpotPenaltyPerSpot = nil;
	c.MoviePricePerBlockAcceptable = nil;
	c.SeriesPricePerBlockAcceptable = nil;
	c.MovieQualityAcceptable = nil;
	c.SeriesQualityAcceptable = nil;
	c.PerformanceData = nil

	c.playerProgrammeQualities = {}
	for playerID=1, 4 do
		c.playerProgrammeQualities[playerID] = {}
		for hour=1, 24 do --need to be 1 based
			c.playerProgrammeQualities[playerID][hour] = nil
		end
	end

	c.lastStatsReadMinute = -1
end)

function BusinessStats:typename()
	return "BusinessStats"
end

function BusinessStats:Initialize()
	self.Audience = StatisticEvaluator()
	self.BroadcastStatistics = BroadcastStatistics()
	self.SpotProfit = StatisticEvaluator()
	self.SpotProfitPerSpot = StatisticEvaluator()
	self.SpotPenalty = StatisticEvaluator()
	self.SpotPenaltyPerSpot = StatisticEvaluator()
	self.MoviePricePerBlockAcceptable = StatisticEvaluator()
	self.SeriesPricePerBlockAcceptable = StatisticEvaluator()
	self.MovieQualityAcceptable = StatisticEvaluator()
	self.SeriesQualityAcceptable = StatisticEvaluator()
	if self.PerformanceData == nil then
		self.PerformanceData = LicencePerformance()
	end

	self.playerProgrammeQualities = {}
	for playerID=1, 4 do
		self.playerProgrammeQualities[playerID] = {}
		for hour=1, 24 do --need to be 1 based
			self.playerProgrammeQualities[playerID][hour] = StatisticEvaluator()
		end
	end
end

function BusinessStats:OnDayBegins()
	self.Audience:Adjust()
	self.SpotProfit:Adjust()
	self.SpotProfitPerSpot:Adjust()
	self.SpotPenalty:Adjust()
	self.SpotPenaltyPerSpot:Adjust()
	self.MoviePricePerBlockAcceptable:Adjust()
	self.SeriesPricePerBlockAcceptable:Adjust()
	self.MovieQualityAcceptable:Adjust()
	self.SeriesQualityAcceptable:Adjust()

	for playerID=1, 4 do
		for hour=1, 24 do --need to be 1 based
			self.playerProgrammeQualities[playerID][hour]:Adjust()
		end
	end
end

function BusinessStats:ReadStats()
	local player = getAIPlayer()
	local hour = player.hour
	local minute = player.minute
	if self.lastStatsReadMinute ~= minute then
		-- read in new audience stats
		if minute == 0 then
			--local currentBroadcast = TVT.GetCurrentNewsShow()
			local currentAudience = TVT.GetCurrentNewsAudience().GetTotalSum()
			local currentAttraction = TVT.GetCurrentNewsAudienceAttraction()
			self.BroadcastStatistics:AddBroadcast(TVT.GetDay(), hour, TVT.Constants.BroadcastMaterialType.NEWSSHOW, currentAttraction, currentAudience)
		end
		if minute == 5 then
			--TODO store genre attraction based on max topicality
			local currentBroadcast = TVT.GetCurrentProgramme()
			--debugMsg("top "..currentBroadcast.getSource().GetTopicality() .." "..currentBroadcast.getSource().GetMaxTopicality().." "..currentBroadcast.getSource().getGenre())
			local currentAudienceResult = TVT.GetCurrentProgrammeAudienceResult()
			local currentAudience = currentAudienceResult.Audience.GetTotalSum()
			local currentAttraction = TVT.GetCurrentProgrammeAudienceAttraction()
			self.BroadcastStatistics:AddBroadcast(TVT.GetDay(), hour, TVT.Constants.BroadcastMaterialType.PROGRAMME, currentAttraction, currentAudience)

			if self.PerformanceData == nil then
				self.PerformanceData = LicencePerformance()
			end
			self.PerformanceData:addData(hour, currentBroadcast, currentAudienceResult)


			self.Audience:AddValue(currentAudience)
			--debugMsg("BusinessStats: Audience (current="..self.Audience.CurrentValue.."  avg=" .. self.Audience.AverageValue .. "  min/max=" .. self.Audience.MinValue .. " - " .. self.Audience.MaxValue .. ")")


			-- add current broadcast qualities to statistics
			local task = player.TaskList[_G["TASK_SCHEDULE"]]
			if task ~= nil then
				for playerID=1, 4 do
					local quality = TVT.GetCurrentProgrammeQuality(playerID)
					-- attention: hour+1 as tables are 1 based
					self.playerProgrammeQualities[playerID][hour + 1]:AddValue(quality)
				end
			end
		end

		self.lastStatsReadMinute = minute
	end
end


function BusinessStats:AddSpot(spot)
	local profit = spot.GetProfit(TVT.ME)
	local penalty = spot.GetPenalty(TVT.ME)

	self.SpotProfit:AddValue(profit)
	self.SpotProfitPerSpot:AddValue(profit / spot.GetSpotCount())

	self.SpotPenalty:AddValue(penalty)
	self.SpotPenaltyPerSpot:AddValue(penalty / spot.GetSpotCount())
end


function BusinessStats:AddMovie(licence)
	local maxPrice = globalPlayer.TaskList[TASK_MOVIEDISTRIBUTOR].BudgetWholeDay * 0.75
	--add licences suiting to our potential limits
	if (CheckMovieBuyConditions(licence, maxPrice)) then
		if licence ~= nil then
			if licence.IsSingle() == 1 then
				self.MovieQualityAcceptable:AddValue( licence.GetQuality() )
				self.MoviePricePerBlockAcceptable:AddValue(licence:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME))
			else
				self.SeriesQualityAcceptable:AddValue( licence.GetQuality() )
				self.SeriesPricePerBlockAcceptable:AddValue(licence:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME))
			end
		end
	end
end


function BusinessStats:GetAverageQualityByHour(playerID, hour)
	local dayStats = self.playerProgrammeQualities[playerID]
	if dayStats then
		-- default is "-1", so check that too
		if dayStats[hour + 1] ~= nil and dayStats[hour + 1].AverageValue >= 0 then
			return dayStats[hour + 1].AverageValue
		end
	end

	-- return default values if no stats were found
	return GetDefaultProgrammeQualityByHour(hour)
end


function BusinessStats:GetAverageQualityByLevel(level)
	-- todo: if still needed - sum up all averages of hours belonging to
	--       a level
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- ###################################################################################################
-- Events die aus dem BlitzMax-Programm aufgerufen werden
-- ###################################################################################################

function getAIPlayer()
	if globalPlayer == nil then
		globalPlayer = DefaultAIPlayer()
		globalPlayer:initialize()

		globalPlayer.logs = {}
		_G["globalPlayer"] = globalPlayer --Macht "GlobalPlayer" als globale Variable verfügbar auch in eingebundenen Dateien
	end
	return globalPlayer
end

-- ##### EVENTS #####

function OnBossCalls(latestTimeString)
	--debugMsg("Boss calls me! " .. latestTimeString)
end

function OnBossCallsForced()
	--debugMsg("Boss calls me NOW!")
end

function OnPlayerGoesBankrupt(playerID)
	getAIPlayer():OnPlayerGoesBankrupt(playerID)
end


function OnMoneyChanged(value, reason, reference)
	if (aiIsActive) then
		getAIPlayer():OnMoneyChanged(value, reason, reference)
	end
end

function OnChat(fromID, message, chatType)
	debugMsg("got a message: " .. message .. "  sub:".. message:sub(0, 4))

	if (message:sub(0, 4) == "CMD_") then
		OnCommand( message:sub(5) )
	else
		debugMsg("got a message: " .. message)
		if (message == "stop") then
			aiIsActive = false
			--debugMsg("AI stopped!")
		elseif (message == "start") then
			aiIsActive = true
			--debugMsg("AI started!")
		end
	end
end


function OnCommand(command)
	local data = split(command, " ")
	local command

	if table.count(data) > 0 then
		command = data[1]
		debugMsg("  command: " .. command)
	end

	if (command == "forcetask") then
		if table.count(data) > 2 then
			local taskID = data[2]
			local priority = tonumber(data[3])
			getAIPlayer():ForceTask(taskID, priority)
			debugMsg("command forcetask executed.")
		else
			debugMsg("command forcetask failed: data missing.")
		end
	elseif (command == "visitBoss") then
		TVT.SendToChat("Go to boss now")
		TVT.DoGoToRoom(TVT.ROOM_BOSS_PLAYER_ME)
	elseif (message == "start") then
		aiIsActive = true
		--debugMsg("AI started!")
	end
end

function OnGameBegins()
	debugMsg("AI-Event: OnGameBegins")
	getAIPlayer():OnGameBegins()
end


function OnDayBegins()
	if (aiIsActive) then
		debugMsg("AI-Event: OnDayBegins")
		getAIPlayer():OnDayBegins()
	end

	for i=0, #globalPlayer.logs do
		debugMsg(globalPlayer.logs[i])
	end
	--reset
	globalPlayer.logs = {}
end


function OnInit()
	if (aiIsActive) then
		getAIPlayer():OnInit()
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


function OnAchievementCompleted(achievement)
	--debugMsg("OnAchievementCompleted")
	if (aiIsActive) then
		getAIPlayer():OnAchievementCompleted(achievement)
	end
end


function OnWonAward(award)
	--debugMsg("OnWonAward")
	if (aiIsActive) then
		getAIPlayer():OnWonAward(award)
	end
end


function OnLeaveRoom()
	--debugMsg("OnLeaveRoom")
end

-- figure approached the target room - will try to open the door soon
function OnReachRoom(roomId)
	roomId = tonumber(roomId) --incoming roomId is "string"
	--debugMsg("OnReachRoom" .. roomId)
end

-- figure is now trying to enter this room ("open door")
-- this is used for "gotoRoom"-jobs to decide weather to wait or not
-- at an occupied room
function OnBeginEnterRoom(roomId, result)
	roomId = tonumber(roomId) --incoming roomId is "string"

	--debugMsg("OnBeginEnterRoom" .. roomId .. " result=" .. result)
	if (aiIsActive) then
		getAIPlayer():OnBeginEnterRoom(roomId, result)
	end
end

-- figure is now in this room
function OnEnterRoom(roomId)
	roomId = tonumber(roomId) --incoming roomId is "string"

	if (aiIsActive) then
		local player = getAIPlayer()
		player:OnEnterRoom(roomId)

		-- when visiting the boss or betty, update sammy information
		if roomId == TVT.ROOM_BOSS_PLAYER_ME then
			--debugMsg("Visiting my boss", true)

			player.currentAwardType = TVT.bo_GetCurrentAwardType()
			player.currentAwardStartTime = tonumber(TVT.bo_GetCurrentAwardStartTimeString())
			player.currentAwardEndTime = tonumber(TVT.bo_GetCurrentAwardEndTimeString())

			player.nextAwardType = TVT.bo_GetNextAwardType()
			player.nextAwardStartTime = tonumber(TVT.bo_GetNextAwardStartTimeString())
			player.nextAwardEndTime = tonumber(TVT.bo_GetNextAwardEndTimeString())
		end
	end
	
	-- prepone next "onTick" as we are ready to do something now
	--TVT.ScheduleNextOnTick()
	-- alternative: 
	-- already start with the current task (run 1 TickProcessTask()
	--if (aiIsActive) then
	--	player:Tick()
	--end
end

-- figure is now at the desired target
function OnReachTarget(target, targetText)
	--debugMsg("OnReachTarget")
	if (aiIsActive) then
		getAIPlayer():OnReachTarget()
	end
end

-- called when forced by game logic to do the next task
function OnForceNextTask(timeGone)
	debugMsg("OnForceNextTask")
	if (aiIsActive) then
		getAIPlayer():ForceNextTask()
	end
end

-- called before "reloading" a script
function OnSaveState(timeGone)
	debugMsg("Serializing AI data")
	SLFManager.StoreDefinition.Player = getAIPlayer()
	return SLFManager:save()
end

function OnLoadState(data)
	SLFManager:load(data)
	if SLFManager.LoadedData.Player:typename() == "DefaultAIPlayer" then
		debugMsg("Successfully restored AI state!")
		_G["globalPlayer"] = SLFManager.LoadedData.Player
	else
		debugMsg("Restoring AI state failed!")
	end
	local player = _G["globalPlayer"]

	player.hour = TVT:GetDayHour()
	player.minute = TVT:GetDayMinute()
	player.gameDay = TVT:GetDaysRun() + 1
	player.minutesGone = TVT:GetTimeGoneInMinutes()
	player.money = TVT:GetMoney()
end

-- called when "saving" a game
function OnSave(timeGone)
	return OnSaveState()
end

function OnLoad(data)
	OnLoadState(data)
end


function OnRealTimeSecond(millisecondsPassed)
	--if (aiIsActive) then
		--getAIPlayer():Tick()
	--end
end


-- called by main loop or AI thread within blitzmax code
function Update()
	debugMsg("next count = "  .. TVT.GetNextEventCount())

	-- AI deactivated / (game) paused?
	if TVT.IsActive() == 0 then
		return
	end

	-- process all happened events

--	local nextEvent
--	if MY.GetNextEventCount() > 0 then
	local nextEvent = TVT.PopNextEvent()
	if nextEvent == nil then
--		MY.sleep(1)
		debugMsg("next is nil")
		return false
	else
		debugMsg("next is OK")
	end

--	while nextEvent do
	--	debugMsg("nextEvent: name=" .. nextEvent.name .. "  data=" .. nextEvent.data)

		--if nextEvent.name ...

		--OnTick
		--OnMinute
		--	...

		--nextEvent = MY.PopNextEvent()
--	end
	return
end


function OnTick(realTimeGone, gameTimeGone, systemTicks, totalTicks)
	--systemTicks = ticks by the system alone (here: "onMinute")
	--totalTicks = ticks by system, "real time second" and AI-scheduled ticks
	--debugMsg("OnTick  gameTime:" .. gameTimeGone .." realTime:" .. realTimeGone .. "  systemTicks:" .. systemTicks .. "  totalTicks:" .. totalTicks .."  gameMinute:" .. TVT.GetDayMinuteForTime(gameTimeGone) .. "  mainThread's gameMinute:" .. TVT.GetDayMinute())
	getAIPlayer().WorldTicks = tonumber(totalTicks)


	if (aiIsActive) then
		-- run tick analyze (read/save stats)
		-- also run 1 TickProcessTask()
		getAIPlayer():Tick()

		-- 1 Task processing is done already in "Tick()"
		-- with higher brain speed there is a higher chance
		-- for doing another tick
		if math.random(1,10) <= getAIPlayer().BrainSpeed then
			getAIPlayer():TickProcessTask()
		end
	end
end


function OnMinute(number)
	--param "number" is passed as string
	local player = getAIPlayer()
	local minute = tonumber(number)
	player.minute = minute
	player.minutesGone = player.minutesGone + 1
	if minute == 0 then
		player.hour = TVT:GetDayHour()
		if player.hour == 0 then
			player.gameDay = TVT:GetDaysRun() + 1
		end
	end

	-- on xx:06 check if there is an unsatisfiable ad planned for this
	-- hour
	if minute == 6 then
		local task = player.TaskList[_G["TASK_SCHEDULE"]]
		if task then
			if TVT:CurrentAdvertisementRequirementsPassed() == TVT.RESULT_FAILED then
				--debugMsg("#recognized failing ad")
				task.SituationPriority = 200
				if player.CurrentTask ~= nil and player.CurrentTask.typename() ~= task.typename() then
					player:ForceNextTask()
				end
			end

			--TODO handle outage as well (should not happen with current scheduling)
			--local broadcast = TVT.GetCurrentAdvertisement()
			--if broadcast ~= nil then...
			--if broadcast.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1 then
		end
	end
end

function OnMalfunction()
	debugMsg("OnMalfunction")
	local task = getAIPlayer().TaskList[_G["TASK_SCHEDULE"]]
	task.SituationPriority = 10
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