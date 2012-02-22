-- ============================
-- === AI Engine ===
-- ============================
-- Autor: Manuel Vögele (STARS_crazy@gmx.de)

-- ##### HISTORY #####
-- 22.02.2012 Manuel
-- Ein paar Methoden umbenannt
-- 13.12.2007 Manuel
-- NEW: SLFDataObject eingefügt
-- 12.12.2007 Manuel
-- +++++ Library erstellt +++++

-- ##### INCLUDES #####
dofile("SLF.lua")

-- ##### KONSTANTEN #####
TASK_STATUS_OPEN	= "T_open"
TASK_STATUS_PREPARE	= "T_prepare"
TASK_STATUS_RUN		= "T_run"
TASK_STATUS_DONE	= "T_done"

JOB_STATUS_NEW		= "J_new"
JOB_STATUS_REDO		= "J_redo"
JOB_STATUS_RUN		= "J_run"
JOB_STATUS_DONE		= "J_done"

-- ##### KONSTANTEN #####
globalKIPlayer = nil

-- ##### KLASSEN #####
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
KIObjekt = SLFObject:new()			-- Erbt aus dem Basic-Objekt des Frameworks
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
KIDataObjekt = SLFDataObject:new()	-- Erbt aus dem DataObjekt des Frameworks
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
AIPlayer = KIDataObjekt:new{
	CurrentTask = nil;
}

function AIPlayer:typename()
	return "KIPlayer"
end

function AIPlayer:initialize()
	globalKIPlayer = self;

	math.randomseed(GetMillisecs())
	
	self:initializePlayer()

	self.TaskList = {}
	self:initializeTasks()
end

function AIPlayer:initializePlayer()
	--Zum �berschreiben
end

function AIPlayer:initializeTasks()
	--Zum �berschreiben
end

function AIPlayer:ValidateRound()
	--Zum �berschreiben
end

function AIPlayer:Tick()	
	if self.CurrentTask == nil then
		self:BeginNewTask()
	else
		if self.CurrentTask.sStatus == TASK_STATUS_DONE then
			self:BeginNewTask()
		else
			self.CurrentTask:Tick()
		end
	end
end

function AIPlayer:BeginNewTask()
	self.CurrentTask = self:SelectTask()
	self.CurrentTask.sStatus = TASK_STATUS_OPEN
	self.CurrentTask:Start()
end

function AIPlayer:SelectTask()
	local BestPrio = -1
	local BestTask = nil

	for k,v in pairs(self.TaskList) do
		v:RecalcPriority()
		if (BestPrio < v.CurrentPriority) then
			BestPrio = v.CurrentPriority
			BestTask = v
		end
	end

	return BestTask
end

function AIPlayer:OnReachRoom()
	self.CurrentTask:OnReachRoom()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Ein Task repr�sentiert eine zu erledigende KI-Aufgabe die sich �blicherweise wiederholt. Diese kann wiederum aus verschiedenen Jobs bestehen
AITask = KIDataObjekt:new{
	Id = "";
	Status = TASK_STATUS_OPEN;
	CurrentJob = nil;
	BasePriority = 0;
	CurrentPriority = 0;
	SituationPriority = 0;
	LastDone = 0;
	StartTask = 0;
	TickCounter = 0;
	TargetRoom = 0
}

function AITask:typename()
	return "AITask"
end

--Wird aufgerufen, wenn der Task zur Bearbeitung ausgew�hlt wurde (NICHT �BERSCHREIBEN!)
function AITask:StartNextJob()
	if GetPlayerRoom() ~= self.TargetRoom then --sorgt daf�r, dass der Spieler in den richtigen Raum geht!
		self.Status = TASK_STATUS_PREPARE
		self.CurrentJob = self:getGotoJob()		
	else
		self.Status = TASK_STATUS_RUN
		self.StartTask = GetTime()
		self.TickCounter = 0;
		self:CurrentJob = self:GetNextJobInTargetRoom()
	end
	
	self.CurrentJob:Start()
end

function AITask:Tick()
	if (self.Status == TASK_STATUS_RUN) then
		self.TickCounter = self.TickCounter + 1
	end

	if (self.CurrentJob == nil) then		
		self:StartNextJob() --Von vorne anfangen
	else
		if self.CurrentJob.Status == JOB_STATUS_DONE then
			self.CurrentJob = nil
			--SendToChat("----- Alter Job ist fertig - Neuen Starten")
			self:StartNextJob() --Von vorne anfangen
		else
			--SendToChat("----- Job-Tick")
			self.CurrentJob:Tick() --Fortsetzen
		end
	end
end

function AITask:GetNextJobInTargetRoom()
	error("Muss noch implementiert werden")
end

function AITask:getGotoJob()
	local aJob = KIJobGoToRoom:new()
	aJob.TargetRoom = self.TargetRoom
	return aJob
end

function AITask:RecalcPriority()
	local Ran1 = math.random(4)
	local Ran2 = math.random(4)
	local TimeDiff = GetTime() - self.LastDone
	self.CurrentPriority = self.SituationPriority + (self.BasePriority * (8+Ran1)) + (TimeDiff / 10 * (self.BasePriority - 2 + Ran2))
end

function AITask:SetDone()
	debugMsg("Done!")
	self.sStatus = TASK_STATUS_DONE
	self.SituationPriority = 0
	self.LastDone = GetTime()
end

function AITask:OnReachRoom()
	if (self.CurrentJob ~= nil) then		
		self:OnReachRoom()
	end
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
KIJob = KIDataObjekt:new{
	Id = "";
	Status = JOB_STATUS_NEW;
	StartJob = 0;
	LastCheck = 0;
	StartParams = nil;
}

function KIJob:typename()
	return "KIJob"
end

function KIJob:Start(pParams)
	self.StartParams = pParams
	self.StartJob = GetTime()
	self.LastCheck = GetTime()
	self:Prepare()
end

function KIJob:Prepare(pParams)
	debugMsg("Implementiere mich: " .. type(self))
end

function KIJob:Tick()
	--Kann �berschrieben werden
end

function KIJob:ReDoCheck(pWait)
	if ((self.LastCheck + pWait) < GetTime()) then
		debugMsg("ReDoCheck")
		self.Status = JOB_STATUS_REDO
		self.LastCheck = GetTime()
		self:Prepare(self.StartParams)
	end
end

function KIJob:OnReachRoom()
	--Kann �berschrieben werden
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
KIJobGoToRoom = KIJob:new{
	TargetRoom = 0
}

function KIJobGoToRoom:typename()
	return "KIJobGoToRoom"
end

function KIJobGoToRoom:OnReachRoom()
	self.sStatus = JOB_STATUS_DONE
end

function KIJobGoToRoom:Prepare(pParams)
	if ((self.sStatus == JOB_STATUS_NEW) or (self.sStatus == JOB_STATUS_REDO)) then
		debugMsg("GotoRoom: " .. self.TargetRoom)
		DoGoToRoom(self.TargetRoom)
		self.sStatus = JOB_STATUS_RUN
	end
end

function KIJobGoToRoom:Tick()
	self:ReDoCheck(10)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<