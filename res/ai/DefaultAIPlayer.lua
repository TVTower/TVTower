-- ##### INCLUDES #####
dofile("res\\ai\\AIEngine.lua")
dofile("res\\ai\\TaskMoviePurchase.lua")

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
	Budget = nil
}

function DefaultAIPlayer:typename()
	return "DefaultAIPlayer"
end

function DefaultAIPlayer:initializePlayer()
	debugMsg("Initialisiere DefaultAIPlayer-KI ...")
end

function DefaultAIPlayer:initializeTasks()
	self.TaskList = {}
	self.TaskList[TASK_MOVIEPURCHASE]	= TaskMoviePurchase:new()
	--self.TaskList[TASK_NEWSAGENCY]		= TVTNewsAgency:new()
	--self.TaskList[TASK_ADAGENCY]		= TVTAdAgency:new()
	--self.TaskList[TASK_SCHEDULING]		= TVTScheduling:new()
	--self.TaskList[TASK_STATIONS]		= TVTStations:new()
	--self.TaskList[TASK_BETTY]			= TVTBettyTask:new()
	--self.TaskList[TASK_BOSS]			= TVTBossTask:new()
	--self.TaskList[TASK_ARCHIVE]			= TVTArchive:new()
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