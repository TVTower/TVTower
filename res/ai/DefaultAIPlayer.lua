-- ##### INCLUDES #####
-- use slash for directories - windows accepts it, linux needs it
-- or maybe package.config:sub(1,1)
dofile("res/ai/AIEngine.lua")
dofile("res/ai/TaskMoviePurchase.lua")
dofile("res/ai/TaskNewsAgency.lua")

-- ##### GLOBALS #####
globalPlayer = nil

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
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	--self.TaskList[TASK_MOVIEPURCHASE]	= TaskMoviePurchase:new()
	self.TaskList[TASK_NEWSAGENCY]		= TaskNewsAgency:new()
	--self.TaskList[TASK_ADAGENCY]		= TVTAdAgency:new()
	--self.TaskList[TASK_SCHEDULING]		= TVTScheduling:new()
	--self.TaskList[TASK_STATIONS]		= TVTStations:new()
	--self.TaskList[TASK_BETTY]			= TVTBettyTask:new()
	--self.TaskList[TASK_BOSS]			= TVTBossTask:new()
	--self.TaskList[TASK_ARCHIVE]			= TVTArchive:new()
end

function DefaultAIPlayer:TickAnalyse()
	self.Stats:ReadStats()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
BusinessStats = SLFDataObject:new{
	MinAudience = -1;	
	AverageAudience = -1;
	MaxAudience = -1;
	
	MinAudienceTemp = 100000000000;
	AverageAudienceTemp = -1;
	MaxAudienceTemp = -1;
	
	TotalAudience = 0;
	AudienceRateScans = 0;
}

function BusinessStats:DayBegin()
	self.MinAudienceTemp = 100000000000
	self.AverageAudienceTemp = -1
	self.MaxAudienceTemp = -1
	self.AudienceRateScans = 0
end

function BusinessStats:ReadStats()
	
	local currentAudience = TVT.getPlayerAudience()
	if (currentAudience == 0) then
		return;
	end
	
	self.AudienceRateScans = self.AudienceRateScans + 1
	
	debugMsg("currentAudience: " .. currentAudience)
	
	if currentAudience < self.MinAudienceTemp then
		self.MinAudience = currentAudience
		self.MinAudienceTemp = currentAudience
	end
	if currentAudience > self.MaxAudienceTemp then
		self.MaxAudience = currentAudience
		self.MaxAudienceTemp = currentAudience
	end	
	
	self.TotalAudience = self.TotalAudience + currentAudience
	self.AverageAudienceTemp = math.round(self.TotalAudience / self.AudienceRateScans, 0)
	self.AverageAudience = self.AverageAudienceTemp
	
	--debugMsg("Stats: " .. self.AverageAudience .. " (" .. self.MinAudience .. " - " .. self.MaxAudience .. ")")
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
end

function OnReachRoom(roomId)
	--getAIPlayer():OnReachRoom()
end

function OnLeaveRoom()
end

function OnMinute(number)
	getAIPlayer():Tick()
end