-- ##### INCLUDES #####
-- use slash for directories - windows accepts it, linux needs it
-- or maybe package.config:sub(1,1)
dofile("res/ai/AIEngine.lua")
dofile("res/ai/TaskMoviePurchase.lua")
dofile("res/ai/TaskNewsAgency.lua")
dofile("res/ai/TaskAdAgency.lua")

-- ##### GLOBALS #####
TASK_MOVIEPURCHASE	= "MoviePurchase"
TASK_NEWSAGENCY		= "NewsAgency"
TASK_ARCHIVE		= "Archive"
TASK_ADAGENCY		= "AdAgency"
TASK_SCHEDULING		= "Scheduling"
TASK_STATIONS		= "Stations"
TASK_BETTY			= "Betty"
TASK_BOSS			= "Boss"

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
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	--self.TaskList[TASK_MOVIEPURCHASE]	= TaskMoviePurchase:new()
	--self.TaskList[TASK_NEWSAGENCY]		= TaskNewsAgency:new()
	self.TaskList[TASK_ADAGENCY]		= TaskAdAgency:new()
	--self.TaskList[TASK_SCHEDULING]		= TVTScheduling:new()
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
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
BusinessStats = SLFDataObject:new{
	Audience = nil;
	SpotProfit = nil;
}

function BusinessStats:Initialize()
	self.Audience = StatisticEvaluator:new()
	self.SpotProfit = StatisticEvaluator:new()
end

function BusinessStats:OnDayBegins()
	self.Audience:Adjust()
	self.SpotProfit:Adjust()
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
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- ###################################################################################################
-- Events die aus dem BlitzBasic-Programm aufgerufen werden
-- ###################################################################################################

function getAIPlayer()
	if globalPlayer == nil then
		globalPlayer = DefaultAIPlayer:new()
	end
	return globalPlayer
end

-- ##### EVENTS #####
function OnMoneyChanged()
end

function OnChat(message)
end

function OnDayBegins()
	getAIPlayer():OnDayBegins()
end

function OnReachRoom(roomId)
	getAIPlayer():OnReachRoom()
end

function OnLeaveRoom()
end

function OnMinute(number)
	getAIPlayer():Tick()
end