-- ============================
-- === AI Engine ===
-- ============================
-- Authors: Manuel Vögele (STARS_crazy@gmx.de)
--          Ronny Otto


-- ##### INCLUDES #####
-- this is defined by the game engine if called from there
-- else the file was opened via a direct call
if CURRENT_WORKING_DIR == nil and debug.getinfo(2, "S") then
	CURRENT_WORKING_DIR = debug.getinfo(2, "S").source:sub(2):match("(.*[/\\])") or "."
	package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'
end

--require "SLF" -- load SFL.lua
dofile("res/ai/CommonAI/SLF.lua")

-- ##### GLOBALS #####
globalPlayer = nil
unitTestMode = false

currentDebugMsgDepth = 0

-- ##### CONSTANTS #####
TASK_STATUS_OPEN	= "T_open"
TASK_STATUS_PREPARE	= "T_prepare"
TASK_STATUS_RUN		= "T_run"
TASK_STATUS_IDLE	= "T_idle"
TASK_STATUS_DONE	= "T_done"
TASK_STATUS_CANCEL	= "T_cancel"

JOB_STATUS_NEW		= "J_new"
JOB_STATUS_REDO		= "J_redo"
JOB_STATUS_RUN		= "J_run"
JOB_STATUS_DONE		= "J_done"
JOB_STATUS_CANCEL	= "J_cancel"

LOG_OFF				= 0
LOG_ERROR			= 1
LOG_INFO			= 2
LOG_DEBUG			= 3
LOG_TRACE			= 4
LOG_TASK_DEF_LEVEL	= LOG_INFO
LOG_JOB_START_LEVEL = LOG_DEBUG

-- ##### CLASSES #####
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["KIObjekt"] = class(SLFObject, function(c)		-- Erbt aus dem Basic-Objekt des Frameworks
	SLFObject.init(c)	-- must init base!
end)
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["KIDataObjekt"] = class(SLFDataObject, function(c)	-- Erbt aus dem DataObjekt des Frameworks
	SLFDataObject.init(c)	-- must init base!
end)
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIPlayer"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.CurrentTask = nil
	c.WorldTicks = 0
	c.minutesGone = 0
end)


function AIPlayer:typename()
	return "AIPlayer"
end


function AIPlayer:initialize()
	math.randomseed(tonumber(TVT.GetMillisecsString()))

	self:initializePlayer()

	self.TaskList = {}
	self:initializeTasks()
end


function AIPlayer:initializePlayer()
	--Zum überschreiben
end


function AIPlayer:initializeTasks()
	--Zum überschreiben
end


-- try to run the given taskID
function AIPlayer:ForceTask(taskID, priority)
	local player = _G["globalPlayer"]
	if player == nil then
		return
	end

	local task = self.TaskList[ taskID ]
	if task ~= nil then
		if self.CurrentTask ~= nil and self.CurrentTask.SituationPriority > priority then
			priority = self.CurrentTask.SituationPriority + 10
			self:LogInfo("ForceTask: " .. taskID .. " with adjusted priority " .. priority)
		else
			self:LogInfo("ForceTask: " .. taskID .. " with priority " .. priority)
		end
		task.SituationPriority = priority
		player:ForceNextTask()
	end
end


--stop a current task and start the next one
function AIPlayer:ForceNextTask()
	self:LogDebug("ForceNextTask")
	if self.CurrentTask ~= nil then
		local nextTask = self:SelectTask()
		local nextTaskName = ""
		if (nextTask ~= nil) then
			nextTaskName = nextTask:typename()
			-- inform task about being a forced one
			nextTask.assignmentType = 1

			local cancelTask = true

			if nextTaskName == self.CurrentTask:typename() then
				-- not "already doing something" (like in between of choosing
				-- programme licences)
				if self.CurrentTask.Status == TASK_STATUS_PREPARE or
				   self.CurrentTask.Status == TASK_STATUS_OPEN then
					cancelTask = false
				end
			else
				-- only cancel if still in preparation (moving to the tasks
				-- target room)
				cancelTask = true
				if self.CurrentTask.Status ~= TASK_STATUS_PREPARE and
				   self.CurrentTask.Status ~= TASK_STATUS_OPEN then
					cancelTask = false
				end
			end
			-- cancel old one
			if cancelTask then
				self:LogDebug("ForceNextTask: Cancel current task...")
				self.CurrentTask:SetAbort()

				--assign next task only when cancelling the old one
				self.CurrentTask = nextTask
				self.CurrentTask.Status = TASK_STATUS_OPEN
				--leave room in case new task in same room (otherwise no onReachTarget)
				if(TVT.doLeaveRoom(false) == TVT.RESULT_FAILED) then
					self:LogDebug("Failed leaving room normally. Forcefully leaving the room now!")
					TVT.doLeaveRoom(true)
				end
				--activate it
				self.CurrentTask:CallActivate()
				--start the next job of the new task
				self.CurrentTask:StartNextJob()
			end
		else
			self:LogInfo("ForceNextTask() failed: no follow up task found...")
		end
	end
end


function AIPlayer:Tick()
	-- update every 5 ticks
	if self.WorldTicks % 5 == 0 then
		-- inform game about our priorities
		-- do it here, to have a "live priority view"
		local tasksPrioOrdered = SortTasksByPrio(self.TaskList)
		local taskNumber = 0
		local player = _G["globalPlayer"]

		for k,v in pairs(tasksPrioOrdered) do
			taskNumber = taskNumber + 1
			MY.SetAIStringData("tasklist_name" .. taskNumber, v:typename())
			MY.SetAIStringData("tasklist_priority" .. taskNumber, math.round(v.CurrentPriority,1))
			MY.SetAIStringData("tasklist_basepriority" .. taskNumber, math.round(v.BasePriority,1))
			MY.SetAIStringData("tasklist_situationpriority" .. taskNumber, math.round(v:getSituationPriority(),1))
			MY.SetAIStringData("tasklist_requisitionpriority" .. taskNumber, math.round(player:GetRequisitionPriority(v.Id),1))
		end
		MY.SetAIStringData("tasklist_count", taskNumber)

		-- current task
		if self.CurrentTask ~= nil then
			MY.SetAIStringData("currentTask",  self.CurrentTask.typename() )
			MY.SetAIStringData("currentTaskStatus",  self.CurrentTask.Status )
			MY.SetAIStringData("currentTaskAssignmentType", self.CurrentTask.assignmentType )
			if self.CurrentTask.CurrentJob ~= nil then
				MY.SetAIStringData("currentTaskJob",  self.CurrentTask.CurrentJob.typename() )
				MY.SetAIStringData("currentTaskJobStatus",  self.CurrentTask.CurrentJob.Status )
			end
		else
			MY.SetAIStringData("currentTask",  "NONE" )
			MY.SetAIStringData("currentTaskStatus",  "0" )
			MY.SetAIStringData("currentTaskAssignmentType", 0)
			MY.SetAIStringData("currentTaskJob",  "NONE" )
			MY.SetAIStringData("currentTaskJobStatus",  "0" )
		end

		--budget
		MY.SetAIStringData("budget_investmentsavings", math.round(self.Budget.InvestmentSavings, 1))
		MY.SetAIStringData("budget_savingpart", math.round(self.Budget.SavingParts, 4))
		MY.SetAIStringData("budget_extrafixedcostssavingspercentage", math.round(self.Budget.ExtraFixedCostsSavingsPercentage, 4))

		taskNumber = 0
		for k,v in pairs(self.TaskList) do
			if v.RequiresBudgetHandling == true then
				taskNumber = taskNumber + 1
				MY.SetAIStringData("budget_task_name" .. taskNumber, v:typename())
				MY.SetAIStringData("budget_task_currentbudget" .. taskNumber, math.round(v.CurrentBudget,1))
				MY.SetAIStringData("budget_task_budgetmaximum" .. taskNumber, math.round(v.BudgetMaximum(),1))
				MY.SetAIStringData("budget_task_budgetwholeday" .. taskNumber, math.round(v.BudgetWholeDay,1))
				local fixCosts = v.FixedCosts
				if fixCosts == nil then fixCosts = -1 end
				MY.SetAIStringData("budget_task_fixcosts" .. taskNumber, math.round(fixCosts,1))
			end
		end
		MY.SetAIStringData("budget_task_count", taskNumber)
	end

	self:TickAnalyse()
	self:TickProcessTask()
end


function AIPlayer:TickProcessTask()
	-- start new tasks or continue the current
	if (self.CurrentTask == nil)  then
		self:BeginNewTask()
	else
		if self.CurrentTask.Status == TASK_STATUS_DONE or self.CurrentTask.Status == TASK_STATUS_CANCEL then
			-- wait until the NEXT task has a certain priority (idle a bit)
			local tasksPrioOrdered = SortTasksByPrio(self.TaskList)
			local nextTask = tasksPrioOrdered[1] -- 0 = current, 1 = next
			if nextTask ~= nil and nextTask.CurrentPriority >= self.startTaskAtPriority then
				self:BeginNewTask()
			end
		else
			local nowTime = os.clock()
			self.CurrentTask:Tick()
			self.CurrentTask.TicksTotalTime = self.CurrentTask.TicksTotalTime + (os.clock() - nowTime)
		end
	end
end


function AIPlayer:TickAnalyse()
	--Zum überschreiben
end


function AIPlayer:BeginNewTask()
	--TODO: Warte-Task einfügen, wenn sich ein Task wiederholt
	self.CurrentTask = self:SelectTask()
	self.CurrentTask.Status = TASK_STATUS_OPEN
	self.minutesGone = TVT:GetTimeGoneInMinutes()
	if self.CurrentTask == nil then
		logWithLevel(LOG_ERROR, LOG_ERROR, "AIPlayer:BeginNewTask - task is nil... " )
	else
		self.CurrentTask.StartTask = 0
		self.CurrentTask:CallActivate()
		self.CurrentTask:StartNextJob()
	end
end


function AIPlayer:SelectTask()
	local BestPrio = -1
	local BestTask = nil

	--[[
	for k,v in pairs(self.TaskList) do
		v:RecalcPriority()
		if (BestPrio < v.CurrentPriority) then
			BestPrio = v.CurrentPriority
			BestTask = v
		end
	end
	]]

	local tasksPrioOrdered = SortTasksByPrio(self.TaskList)
	BestTask = table.first(tasksPrioOrdered)

	return BestTask
end


function AIPlayer:OnDayBegins()
	--Zum überschreiben
end


function AIPlayer:OnBeginEnterRoom(roomId, result)
	self.CurrentTask:OnBeginEnterRoom(roomId, result)
end


function AIPlayer:OnEnterRoom(roomId)
	self.CurrentTask:OnEnterRoom(roomId)
end


function AIPlayer:OnReachTarget()
	self.CurrentTask:OnReachTarget()
end


function AIPlayer:OnMoneyChanged(value, reason, reference)
	--override in player
end


function AIPlayer:OnWonAward(award)
	--override in player
end


function AIPlayer:OnAchievementCompleted(achievement)
	--override in player
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Ein Task repräsentiert eine zu erledigende KI-Aufgabe die sich üblicherweise wiederholt. Diese kann wiederum aus verschiedenen Jobs bestehen
_G["AITask"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	-- Ronny: Id seems unused for now
	c.Id = c:typename() --nil -- Der eindeutige Name des Tasks
	c.Status = TASK_STATUS_OPEN -- Der Status der Aufgabe
	c.CurrentJob = nil -- Welcher Job wird aktuell bearbeitet und bei jedem Tick benachrichtigt
	c.BasePriority = 0 -- Grundlegende Priorität der Aufgabe (zwischen 1 und 10)
	c.SituationPriority = 0 -- Dieser Wert kann sich ändern, wenn besondere Ereignisse auftreten, die von einer bestimmen Aufgabe eine höhere Priorität erfordert. Üblicherweise zwischen 0 und 10. Hat aber kein Maximum
	c.CurrentPriority = 0 -- Berechnet: Aktuelle Priorität dieser Aufgabe
	c.LastDoneWorldTicks = 0 -- WorldTicks, wann der Task zuletzt abgeschlossen wurde
	c.LastDone = 0 -- Zeit, wann der Task zuletzt abgeschlossen wurde
	c.StartTaskWorldTicks = 0 -- WorldTicks, wann der Task zuletzt gestartet wurde
	c.StartTask = 0 -- Zeit, wann der Task zuletzt gestartet wurde
	c.TickCounter = 0 -- Gibt die Anzahl der Ticks an seit dem der Task läuft
	c.TicksTotalTime = 0 -- Time the ticks needed since task start
	c.MaxTicks = 30 --Wie viele Ticks darf der Task maximal laufen?
	c.IdleTill = -1 --Zeit bis zu der nichts gemacht werden soll.
	c.TargetRoom = -1 -- Zielraumes; überschreiben wenn Task in einem Raum erledigt werden muss
	c.TargetID = -1 -- Ziel-ID; überschreiben wenn Task an einer bestimmten Stelle (z.B. Hotspot) erledigt werden muss

	c.RequiresBudgetHandling = true
	c.CurrentBudget = 0 -- Wie viel Geld steht der KI noch zur Verfügung um diese Aufgabe zu erledigen.
	c.BudgetWholeDay = 0 -- Wie hoch war das Budget das die KI für diese Aufgabe an diesem Tag einkalkuliert hat.
	c.BudgetWeight = 0 -- Wie viele Budgetanteile verlangt diese Aufgabe vom Gesamtbudget?

	c.InvestmentPriority = 0 -- Wie wichtig sind die Investitionen in diesen Bereich?
	c.CurrentInvestmentPriority = 0 -- Wie ist die Prio aktuell? InvestmentPriority wird jede Runde aufaddiert.
	c.NeededInvestmentBudget = -1 -- Wie viel Geld benötigt die KI für eine Großinvestition
	c.UseInvestment = false

	-- 1 = added via ForceNextTask?
	-- 2 = added via another task (forcefully)?
	c.assignmentType = 0

	c.FixedCosts = nil

	c.LogLevel = LOG_TASK_DEF_LEVEL
end)


function AITask:typename()
	return "AITask"
end


function AITask:ResetDefaults()
	--kann überschrieben werden
end


function AITask:getBudgetUnits()
	return self.BudgetWeight
end


function AITask:getStrategicPriority()
	return 1.0
end


function AITask:getSituationPriority()
	return self.SituationPriority
end


function AITask:getWorldTicks()
	local player = _G["globalPlayer"]
	if player == nil then
		self:LogError("_G[\"globalPlayer\"] is NIL!")
		return 0
	end
	return player.WorldTicks
end


function AITask:GetFixedCosts()
	if self.FixedCosts == nil then self:CalculateFixedCosts() end
	return self.FixedCosts
end


function AITask:CalculateFixedCosts()
	self.FixedCosts = 0
end


function AITask:PayFromBudget(value)
	self.CurrentBudget = self.CurrentBudget - value
end


function AITask:resume()
	-- Ronny 16.10.2016: should no longer be needed as the AI now stores
	-- its external objects in "TVT.*"
	if self.InvalidDataObject then
		if self.Status == TASK_STATUS_PREPARE or self.Status == TASK_STATUS_RUN then
			self:LogError(type(self) .. ": InvalidDataObject resume => TASK_STATUS_OPEN")
			self.Status = TASK_STATUS_OPEN
		end
		self.InvalidDataObject = false
		table.removeKey(self, "InvalidDataObject");
	end
end


function AITask:CallActivate()
	self.TickCounter = 0
	self.TicksTotalTime = 0
	self:InitializeMaxTicks()
	debugMsgDepth(-10)
	self:LogInfo("### Starting task '" .. self:typename() .. "'! (Prio: " .. self.CurrentPriority .."). MaxTicks: " .. self.MaxTicks)
	debugMsgDepth(1)
	self:Activate()
end


--override if you need more ticks
function AITask:InitializeMaxTicks()
	self.MaxTicks = math.random(15, 25)
end


function AITask:Activate()
	self:LogError("Please implement me... " .. type(self))
end


function AITask:AdjustmentsForNextDay()
	self.CurrentInvestmentPriority = self.CurrentInvestmentPriority + self.InvestmentPriority
	--override in actual implementation
end


function AITask:OnDayBegins()
	--override in actual implementation
end

--Wird aufgerufen, wenn der Task zur Bearbeitung ausgewaehlt wurde (NICHT UEBERSCHREIBEN!)
function AITask:StartNextJob()
	self:LogTrace("StartNextJob")

	--local roomNumber = TVT.GetPlayerRoom()
	--self:LogTrace("Player-Raum: " .. roomNumber .. " - Target-Raum: " .. self.TargetRoom)

	-- Do not check the player room anymore. The GoToJob already has the information if the target is reached...
	-- only then its status is "done"
	-- if TVT.GetPlayerRoom() ~= self.TargetRoom then --sorgt dafür, dass der Spieler in den richtigen Raum geht!
	if self.Status == TASK_STATUS_OPEN then
		self.Status = TASK_STATUS_PREPARE
		self.CurrentJob = self:getGotoJob()
	elseif self.Status == TASK_STATUS_PREPARE and self.CurrentJob~=nil and self.CurrentJob.Status ~= JOB_STATUS_DONE then
		-- go to has failed - try again?
	else
		if self.StartTask == 0 then
			self.StartTaskWorldTicks = self:getWorldTicks()
			self.StartTask = getPlayer().minutesGone
		end
		self.Status = TASK_STATUS_RUN

		local oldJob = self.CurrentJob
		if oldJob ~= nil then
			oldJob:OnCancel()
			oldJob:Stop()
		end
		self.CurrentJob = self:GetNextJobInTargetRoom()

		if (self.Status == TASK_STATUS_DONE) or (self.Status == TASK_STATUS_CANCEL) then
			return
		end
	end

	if self.CurrentJob ~= null then
		self.CurrentJob:Start()
	end
end


function AITask:Tick()
	--sometimes a figure is stuck in the adagency... we cancel jobs in
	--that case
	if (self.Status == TASK_STATUS_OPEN) then
		self:LogError(self:typename()..": Status OPEN! Darf nicht sein!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		self:SetDone()
	end

	-- have to idle?
	if (self.Status == TASK_STATUS_IDLE) then
		self:LogTrace("idling ... ")
		if (self.IdleTill <= getPlayer().minutesGone) then
			self.IdleTill = -1
			self.Status = TASK_STATUS_RUN
		end
	elseif (self.Status == TASK_STATUS_RUN) then
		self.TickCounter = self.TickCounter + 1
		if (self.TickCounter > self.MaxTicks) then
			self:LogTrace("MaxTickCount: " .. self.TickCounter .. " > " .. self.MaxTicks)
			self:TooMuchTicks()
		end
	end

	if ((self.Status == TASK_STATUS_RUN) or (self.Status == TASK_STATUS_PREPARE)) then
		if (self.CurrentJob == nil) then
			self:LogTrace("----- Kein Job da - Neuen Starten")
			self:StartNextJob() --Von vorne anfangen
		else
			if self.CurrentJob.Status == JOB_STATUS_CANCEL then
				self.CurrentJob:OnCancel()
				self.CurrentJob:Stop()
				self.CurrentJob = nil
				self:SetCancel()
				return
			elseif self.CurrentJob.Status == JOB_STATUS_DONE then
				self.CurrentJob:OnDone()
				self.CurrentJob:Stop()
				self.CurrentJob = nil
				self:LogTrace("----- Alter Job ist fertig - Neuen Starten")
				self:StartNextJob() --Von vorne anfangen
			else
				self.CurrentJob:CallTick() --Fortsetzen
			end
		end
	end
end


function AITask:GetNextJobInTargetRoom()
	error("Task:GetNextJobInTargetRoom() not implemented.")
end


function AITask:getGotoJob()
	local aJob = AIJobGoToRoom()
	aJob.Task = self
	aJob.TargetRoom = self.TargetRoom
	aJob.TargetID = self.TargetID
	return aJob
end

function AITask:getMinutesSinceLastDone()
	return getPlayer().minutesGone - self.LastDone
end


function AITask:RecalcPriority()
	if (self.LastDone == 0) then self.LastDone = getPlayer().minutesGone end
	if (self.LastDoneWorldTicks == 0) then self.LastDoneWorldTicks = self:getWorldTicks() end

	local player = _G["globalPlayer"]
	local Ran1 = math.random(75, 125) / 100
	local TimeDiff = math.round(getPlayer().minutesGone - self.LastDone)
	local TicksDiff = math.round(self:getWorldTicks() - self.LastDoneWorldTicks)
	local requisitionPriority = player:GetRequisitionPriority(self.Id)

	local calcPriority = (self.BasePriority + self:getSituationPriority()) * Ran1 + requisitionPriority
	local timeFactor = (20 + TimeDiff) / 20
	local ticksFactor = (20 + TicksDiff) / 20

	local strategicPriority = self:getStrategicPriority()
	local timePriority = strategicPriority  * calcPriority * timeFactor
	local ticksPriority = strategicPriority  * calcPriority * ticksFactor

	self.CurrentPriority = math.max(timePriority, ticksPriority)

	-- if the target room is blocked then reduce priority
	-- reduction of up to 80% is possible
	--   0 minutes or less being  0%
	--  10 minutes or less being 20%
	--  40 minutes or more being 80%
	if self.TargetRoom > 0 then
		local blockedMinutes = TVT.TimeToMinutes( TVT.GetRoomBlockedTimeString(self.TargetRoom) )
		--TODO once the log level is changed for a task, these log messages would constantly appear
		--self:LogTrace("PRIO: Target room ".. self.TargetRoom ..". blockedMinutes " .. blockedMinutes)
		if blockedMinutes >= 1 then
			--self:LogDebug("PRIO: Target room is blocked too long, reducing priority. " .. math.max(0.2, 1.0 - 0.02*blockedMinutes))
			self.CurrentPriority = math.max(0.2, 1.0 - 0.02*blockedMinutes)
		end
	end

	--self:LogTrace("Task: " .. self:typename() .. " - BasePriority: " .. self.BasePriority .." - SituationPriority: " .. self:getSituationPriority() .. " - Ran1 : " .. Ran1 .. "  RequisitionPriority: " .. requisitionPriority)
	--self:LogTrace("Task: " .. self:typename() .. " - Prio: " .. self.CurrentPriority .. "  (time: " .. timePriority .." | ticks: " .. ticksPriority ..") - TimeDiff:" .. TimeDiff .. "  TicksDiff:" .. TicksDiff.." (tF: " ..timeFactor .." | cP: " .. calcPriority .. ")")
end


function AITask:TooMuchTicks()
	self:LogInfo("... waited long enough.")
	self:SetDone()
end


function AITask:SetIdle(idleMinutes)
	if idleMinutes > 0 then
		self.IdleTill = getPlayer().minutesGone + idleMinutes
		self:LogDebug("idling for " .. idleMinutes .. " minutes")
		self.Status = TASK_STATUS_IDLE
	end
end


function AITask:SetDone()
	debugMsgDepth(-10)
	self:LogInfo("### Task finished!")
	local player = _G["globalPlayer"]
	self.Status = TASK_STATUS_DONE
	self.SituationPriority = 0
	self.LastDone = getPlayer().minutesGone
	self.LastDoneWorldTicks = self:getWorldTicks()


	if(TVT.doLeaveRoom(false) == TVT.RESULT_FAILED) then
		self:LogDebug("Failed leaving room normally. Forcefully leaving the room now!")
		TVT.doLeaveRoom(true)
	end

	-- reset back
	self.assignmentType = 0
end

--no priority modification
function AITask:SetAbort()
	debugMsgDepth(-10)
	self:LogInfo("<<< Task aborted!")
	self.Status = TASK_STATUS_CANCEL

	-- reset back
	self.assignmentType = 0
end

--with priority modification
function AITask:SetCancel()
	debugMsgDepth(-10)
	self:LogInfo("<<< Task cancelled!")
	self.Status = TASK_STATUS_CANCEL
	self.SituationPriority = self.SituationPriority / 2

	-- reset back
	self.assignmentType = 0
end


function AITask:OnEnterRoom(roomId)
	if (self.CurrentJob ~= nil) then
		self.CurrentJob:OnEnterRoom(roomId)
	end
end


function AITask:OnBeginEnterRoom(roomId, result)
	if (self.CurrentJob ~= nil) then
		self.CurrentJob:OnBeginEnterRoom(roomId, result)
	end
end


function AITask:OnReachTarget()
	if (self.CurrentJob ~= nil) then
		self.CurrentJob:OnReachTarget()
	end
end


function AITask:BeforeBudgetSetup()
end


function AITask:BudgetSetup()
end


function AITask:BudgetMaximum()
	return -1
end


function AITask:OnMoneyChanged(value, reason, reference)
	--Zum überschreiben
end

--convenience log methods for tasks
function AITask:LogError(message)
	self:Log(LOG_ERROR, message)
end

function AITask:LogInfo(message)
	self:Log(LOG_INFO, message)
end

function AITask:LogDebug(message)
	self:Log(LOG_DEBUG, message)
end

function AITask:LogTrace(message)
	self:Log(LOG_TRACE, message)
end

function AITask:Log(level, message)
	logWithLevel(self.LogLevel, level, message)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIJob"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.Id = ""
	c.Status = JOB_STATUS_NEW
	c.StartJob = 0
	c.LastCheck = 0
	c.StartJobWorldTicks = 0
	c.LastCheckWorldTicks = 0
	c.Ticks = 0
	c.TicksTotalTime = 0
	c.TickMaxTime = 0
	c.StartParams = nil
	c.jobStartTime = 0
	c.LogStartLevel = LOG_JOB_START_LEVEL
	c.LogDoneLevel = LOG_OFF -- actually also remove comment where used - too many calculations
	c.LogLevel = nil
end)

function AIJob:typename()
	return "AIJob"
end


function AIJob:getWorldTicks()
	local player = _G["globalPlayer"]
	return player.WorldTicks
end


function AIJob:resume()
	if self.InvalidDataObject then
		if self.Status == JOB_STATUS_REDO or self.Status == JOB_STATUS_RUN then
			self:LogError(self:typename() .. ": InvalidDataObject resume => JOB_STATUS_NEW")
			self.Status = JOB_STATUS_NEW
		end
		self.InvalidDataObject = false
		table.removeKey(self, "InvalidDataObject");
	end
end


function AIJob:Start(pParams)
	self:Log(self.LogStartLevel, "Job " .. self:typename() .. " started.")
	debugMsgDepth(1)
	self:OnStart()

	self.jobStartTime = os.clock()
	self.StartParams = pParams
	self.StartJob = getPlayer().minutesGone
	self.LastCheck = self.StartJob
	self.StartJobWorldTicks = 0
	self.LastCheckWorldTicks = 0
	self.TicksTotalTime = 0
	self.TickMaxTime = 0
	self.Ticks = 0

	self:Prepare(pParams)
end


function AIJob:Stop(pParams)
	self:OnStop()
end


function AIJob:Prepare(pParams)
	self:LogError("Implementiere mich: " .. type(self))
end


function AIJob:CallTick()
	self.Ticks = self.Ticks + 1

	local nowTime = os.clock()
	self:Tick()
	local timeGone = (os.clock() - nowTime)

	self.TickMaxTime = math.max(timeGone, self.TickMaxTime)
	self.TicksTotalTime = self.TicksTotalTime + timeGone
end


function AIJob:Tick()
	--Kann ueberschrieben werden
end


function AIJob:ReDoCheck(minutesWait, ticksWait)
	local timeGone = getPlayer().minutesGone
	local ticks = self:getWorldTicks()
	if ((self.LastCheckWorldTicks + ticksWait) < ticks or (self.LastCheck + minutesWait) < timeGone) then
		self:LogDebug("ReDoCheck: (time: " .. self.LastCheck .. " + " .. minutesWait .. " < " .. timeGone .."    ticks: " ..self.LastCheckWorldTicks .. " + " .. ticksWait .." < " .. ticks)
		self.Status = JOB_STATUS_REDO
		self.LastCheckWorldTicks = ticks
		self.LastCheck = timeGone
		self:Prepare(self.StartParams)
	end
end


function AIJob:OnStart()
	--Kann ueberschrieben werden
end


function AIJob:OnStop()
	--Kann ueberschrieben werden
end


function AIJob:OnDone()
	debugMsgDepth(-1)
	--self:Log(self.LogDoneLevel, "Job " .. self:typename() .. " done. Duration=" .. string.format("%.4f", (1000 * (os.clock() - self.jobStartTime))) .. "ms  TickCount=" .. self.Ticks .. "  TickTime=" .. string.format("%.4f", 1000 * self.TicksTotalTime) .."ms  TickMax=" .. string.format("%.4f", 1000 * self.TickMaxTime))
end


function AIJob:OnCancel()
	debugMsgDepth(-1)
	self:LogInfo("Job " .. self:typename() .. " cancelled. Duration=" .. string.format("%.4f", (1000 * (os.clock() - self.jobStartTime))) .. "ms  TickCount=" .. self.Ticks .. "  TickTime=" .. string.format("%.4f", 1000 * self.TicksTotalTime) .."ms  TickMax=" .. string.format("%.4f", 1000 * self.TickMaxTime))
end


function AIJob:OnBeginEnterRoom(roomId, result)
	--Kann überschrieben werden
	--wird aufgerufen, sobald die Figur versucht den Raum zu betreten
	--roomId = der Raum
	--result = Ergebnis des Versuchs. Bspweise TVT.RESULT_INUSE (besetzt)
end


function AIJob:OnEnterRoom(roomId)
	--Kann überschrieben werden
	--wird aufgerufen, sobald die Figur IM Raum ist
end


function AIJob:OnReachTarget()
	--Kann überschrieben werden
	--wird aufgerufen, sobald die Figur ihr Ziel erreicht
end


function AIJob:SetCancel()
	self:LogError("SetCancel(): Implementiere mich: " .. type(self))
end

--convenience log methods for jobs
function AIJob:LogError(message)
	self:Log(LOG_ERROR, message)
end

function AIJob:LogInfo(message)
	self:Log(LOG_INFO, message)
end

function AIJob:LogDebug(message)
	self:Log(LOG_DEBUG, message)
end

function AIJob:LogTrace(message)
	self:Log(LOG_TRACE, message)
end

function AIJob:Log(level, message)
	logWithLevel(self:GetLogLevel(), level, message)
end

--calculate inherited log level from task if job log level is not explicitly defined
function AIJob:GetLogLevel()
	if self.LogLevel == nil then
		if self.Task ~= nil and self.Task.LogLevel ~=nil then
			self.LogLevel = self.Task.LogLevel
		else
			logWithLevel(LOG_ERROR, LOG_ERROR, self:typename().." log level undefined")
			self.LogLevel = LOG_OFF
		end
	end
	return self.LogLevel
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIIdleJob"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
	c.IdleTime = 0
	c.IdleTicks = 0
	c.IdleTill = -1
	c.IdleTillWorldTicks = -1
end)

function AIIdleJob:typename()
	return "AIIdleJob"
end


function AIIdleJob:SetIdleTime(t)
	self.IdleTime = t
end


function AIIdleJob:SetIdleTicks(ticks)
	self.IdleTicks = ticks
end

--override
function AIIdleJob:Start(pParams)
	if (self.IdleTime ~= 0) then
		self.IdleTill = getPlayer().minutesGone + self.IdleTime
		self:LogDebug("Set self.IdleTill = " .. self.IdleTill)
	end
	if (self.IdleTicks ~= 0) then
		self.IdleTillWorldTicks = self:getWorldTicks() + self.IdleTicks
		self:LogDebug("Set self.IdleTillWorldTicks = " .. self.IdleTillWorldTicks)
	end
end


function AIIdleJob:getWorldTicks()
	local player = _G["globalPlayer"]
	return player.WorldTicks
end


function AIIdleJob:Prepare(pParams)
	if ((self.Status == JOB_STATUS_NEW) or (self.Status == TASK_STATUS_PREPARE) or (self.Status == JOB_STATUS_REDO)) then
		self.Status = JOB_STATUS_RUN
	end
end


function AIIdleJob:Tick()
	--TODO set false again if AI is more competitive
	local finishedIdling = true
	if (self.IdleTill == -1) and (self.IdleTillWorldTicks == -1) then
		finishedIdling = true
	elseif (self.IdleTill ~= -1) and ((self.IdleTill - getPlayer().minutesGone) <= 0) then
		finishedIdling = true
	elseif (self.IdleTillWorldTicks ~= -1) and ((self.IdleTillWorldTicks - self:getWorldTicks()) <= 0) then
		finishedIdling = true
	end

	if finishedIdling == true then
		self:LogDebug("Finished idling ...")
		self.Status = JOB_STATUS_DONE
		return
	else
		self:LogTrace("Idling ...")
	end
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIJobGoToRoom"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
	c.TargetRoom = -1
	c.TargetID = -1
	c.IsWaiting = false
	c.CheckRoomBlocked = false
	c.WaitSince = -1
	c.WaitSinceWorldTicks = -1
	c.WaitTill = -1
	c.WaitTillWorldTicks = -1
	c.LogStartLevel = LOG_OFF
end)

function AIJobGoToRoom:typename()
	return "AIJobGoToRoom"
end


function AIJobGoToRoom:OnBeginEnterRoom(roomId, result)
	local resultId = tonumber(result)
	if (resultId == TVT.RESULT_INUSE) then
		if (self.IsWaiting) then
			self:LogDebug( TVT.ME .. " BeginEnterRoom: Room still in use. Will continue to wait...a bit. Waiting time: " .. self.WaitTill .. "/" .. getPlayer().minutesGone .."  ticks=" .. self.WaitTillWorldTicks .. "/" .. self:getWorldTicks() .. ")")
		elseif (self:ShouldIWait()) then
			self.IsWaiting = true
			self.WaitSince = getPlayer().minutesGone
			self.WaitSinceWorldTicks = self:getWorldTicks()
			self.WaitTill = self.WaitSince + 3 + (self.Task.CurrentPriority / 6)
			self.WaitTillWorldTicks = self.WaitSinceWorldTicks + 3 + (self.Task.CurrentPriority / 6)
			if ((self.WaitTill - self.WaitSince) > 20) then
				self.WaitTill = self.WaitSince + 20
			end
			if ((self.WaitTillWorldTicks - self.WaitSinceWorldTicks) > 20) then
				self.WaitTillWorldTicks = self.WaitSinceWorldTicks + 20
			end
			self:LogDebug("BeginEnterRoom: Room occupied! Will wait a bit. Waiting time: " .. self.WaitTill .. "/" .. getPlayer().minutesGone .."  /  ticks: " .. self.WaitTillWorldTicks .. "/" .. self:getWorldTicks() .. ")")
		else
			self:LogInfo("BeginEnterRoom: Room occupied! Won't wait this time.")
			self.Status = JOB_STATUS_CANCEL
			self.Task:SetCancel()
		end
	elseif(resultId == TVT.RESULT_NOTALLOWED) then
		local blockedMinutes = TVT.TimeToMinutes( TVT.GetRoomBlockedTimeString(roomId) )
		--if blocked shorter than 10 minutes, we will wait
		if TVT.IsRoomBlocked(roomId) == 1 and blockedMinutes <= 10 then
			self:LogInfo("BeginEnterRoom: Room blocked short enough! ... waiting a bit. Blocked for " .. blockedMinutes .. " minute(s).")
		else
			self:LogInfo("BeginEnterRoom: Room enter forbidden or room blocked and waiting time too long: " .. blockedMinutes .. " minute(s).")
			self.Status = JOB_STATUS_CANCEL
			self.Task:SetCancel()
		end
	elseif(resultId == TVT.RESULT_NOKEY) then
		self:LogInfo("BeginEnterRoom: Room locked! Need a key to enter. Cancelled task.")
		self.Status = JOB_STATUS_CANCEL
		self.Task:SetCancel()
	elseif(resultId == TVT.RESULT_OK) then
		self:LogDebug("BeginEnterRoom: Entering allowed. roomId: " .. roomId)
	end
end


function AIJobGoToRoom:OnEnterRoom(roomId)
	self:LogInfo("AIJobGoToRoom: Entering roomId: " .. roomId)
	self.Status = JOB_STATUS_DONE
end


function AIJobGoToRoom:ShouldIWait()
	if (self.Task.CurrentPriority >= 60) then
		return true
	elseif (self.Task.CurrentPriority >= 30) then
		local randVal = math.random(0, self.Task.CurrentPriority)
		if (randVal >= 20) then
			return true
		else
			return false
		end
	else
		return false
	end
end


--override
function AIJobGoToRoom:OnReachTarget()
	self.CheckRoomBlocked = true

	-- if we reached the target, try to go to our target room again
	-- maybe we were on an intermediate step - or failed to enter the 
	-- room as it was occupied
	if self.TargetRoom > 0 then
		if (self.Status == JOB_STATUS_REDO) or (self.Status == JOB_STATUS_RUN) then
			if TVT.isRoomUnused(self.TargetRoom) == TVT.RESULT_INUSE then
				self:LogTrace("OnReachTarget - Skip going in, still used")
			else
				self:LogTrace("OnReachTarget - GoToRoom again")
				TVT.DoGoToRoom(self.TargetRoom)
			end
		end
	else
		self.Status = JOB_STATUS_DONE
	end
end


function AIJobGoToRoom:Prepare(pParams)
	self.CheckRoomBlocked = false
	if (self.TargetRoom > 0 and self.TargetID <= 0) then
		local tID = TVT:GetTargetIDToRoomID(self.TargetRoom)
		if tID ~= TVT.RESULT_NOTFOUND then
			self.TargetID = tID
		else
			self:LogError("Failed fetching missing TargetID for room ".. self.TargetRoom)
		end
	end

	if self.TargetID <= 0 then
		--no need to go anywhere
		self.Status = JOB_STATUS_DONE
	elseif ((self.Status == JOB_STATUS_NEW) or (self.Status == TASK_STATUS_PREPARE) or (self.Status == JOB_STATUS_REDO)) then
		self:LogTrace("DoGoToTarget: " .. self.TargetRoom .. " => " .. self.Status)
		local goToRoomResult = TVT.DoGoToTarget(self.TargetID)
		if goToRoomResult <= 0 then
			self:LogTrace("DoGoToRoom: failed, eg. not allowed to do so.")
		elseif self.Status ~= JOB_STATUS_REDO and self.TargetRoom > 0 and TVT.isRoomUnused(self.TargetRoom) == -1 then
			--task was possibly started when already being in the target room
			--isRoomUnused has the special return value -1 for being in the room yourself
			self:LogTrace("Already in target room.")
			self.Status = JOB_STATUS_DONE
		else
			self.Status = JOB_STATUS_RUN
		end
	end
end


function AIJobGoToRoom:Tick()
	if (self.IsWaiting and self.TargetRoom > 0 ) then
		self:LogTrace("AIJobGoToRoom:Tick ... waiting")
		if (TVT.isRoomUnused(self.TargetRoom) == 1) then
			self:LogTrace("Room is unused now")
			self.IsWaiting = false
			TVT.DoGoToRoom(self.TargetRoom)
		elseif ((self.WaitTill - getPlayer().minutesGone) <= 0 or (self.WaitTillWorldTicks - self:getWorldTicks()) <= 0) then
			self:LogInfo("Room is still used. I do not want to wait any longer.")
			self.IsWaiting = false
			self.Status = JOB_STATUS_CANCEL
		else
			self:LogTrace("Waiting to enter the room. Waiting till time: " .. self.WaitTill .. "/" .. getPlayer().minutesGone .. "  /  ticks: " .. self.WaitTillWorldTicks .. "/" .. self:getWorldTicks() .. ".")
		end
	-- while walking / going by elevator
	elseif (self.Status ~= JOB_STATUS_DONE) then
		-- check if room is blocked - if so, abort task
		--TODO set CheckRoomBlocked to true initially and set it to false once the elevator is entered
		if (self.TargetRoom >= 0) and self.CheckRoomBlocked and TVT.IsRoomBlocked(self.TargetRoom) == 1 then
			local blockedMinutes = TVT.TimeToMinutes( TVT.GetRoomBlockedTimeString(self.TargetRoom) )
			if blockedMinutes <= 10 then
				self:LogInfo("Target room is blocked but soon reopening.")
			else
				self:LogInfo("Target room is blocked ... cancelling task.")
				self.Status = JOB_STATUS_CANCEL
				self.Task:SetCancel()
			end
		end

		self:ReDoCheck(10, 10)
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>> BROADCAST STATS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BroadcastStatistics"] = class(SLFDataObject, function(c)
	SLFDataObject.init(c)	-- must init base!

	-- storage for attraction types of news/programmes for 0-23
	c.hourlyNewsAttraction = {}
	c.hourlyProgrammeAttraction = {}

	c.hourlyNewsAudience = {}
	c.hourlyProgrammeAudience = {}
end)

function BroadcastStatistics:typename()
	return "BroadcastStatistics"
end


function BroadcastStatistics:AddBroadcast(day, hour, broadcastTypeID, attraction, audience)
	local currentI = tostring(day) .. string.format("%02d", hour)

	if broadcastTypeID == TVT.Constants.BroadcastMaterialType.NEWSSHOW then
		-- remove everything older than yesterday
		local lastDaysI = tonumber(tostring(day-1).."00")

		for k,v in pairs(self.hourlyNewsAudience) do
			if tonumber(k) < lastDaysI then
				self.hourlyNewsAudience[k] = nil
			end
		end
		for k,v in pairs(self.hourlyNewsAttraction) do
			if tonumber(k) < lastDaysI then
				self.hourlyNewsAttraction[k] = nil
			end
		end

		self.hourlyNewsAttraction[currentI] = attraction
		self.hourlyNewsAudience[currentI] = audience
		return true
	elseif broadcastTypeID == TVT.Constants.BroadcastMaterialType.PROGRAMME then
		-- remove everything older than yesterday
		local lastDaysI = tonumber(tostring(day-1).."00")
		for k,v in pairs(self.hourlyProgrammeAudience) do
			if tonumber(k) < lastDaysI then
				self.hourlyProgrammeAudience[k] = nil
			end
		end
		for k,v in pairs(self.hourlyProgrammeAttraction) do
			if tonumber(k) < lastDaysI then
				self.hourlyProgrammeAttraction[k] = nil
			end
		end

		self.hourlyProgrammeAttraction[currentI] = attraction
		self.hourlyProgrammeAudience[currentI] = audience
		return true
	end
	logWithLevel(LOG_ERROR, LOG_ERROR, "   -> ADDING FAILED at " .. currentI .. "  unknown broadcastTypeID " .. broadcastTypeID)
end


--TODO is it really the type that is interesting for the attraction, genre instead? ??
function BroadcastStatistics:GetAttraction(day, hour, broadcastType)
	local currentI = tostring(day) .. string.format("%02d", hour)
	if broadcastType == TVT.Constants.BroadcastMaterialType.NEWSSHOW then
		return self.hourlyNewsAttraction[currentI]
	elseif broadcastType == TVT.Constants.BroadcastMaterialType.PROGRAMME then
		--debugMsg("   -> GET PROG at " .. currentI)
		--for k,v in pairs(self.hourlyProgrammeAttraction) do
		--	debugMsg("      existing: " .. k)
		--end
		return self.hourlyProgrammeAttraction[currentI]
	end
end


function BroadcastStatistics:GetAudience(hour, broadcastType)
	local currentI = tostring(day) .. string.format("%02d", hour)
	if broadcastType == TVT.Constants.BroadcastMaterialType.NEWSSHOW then
		return self.hourlyNewsAudience[currentI]
	elseif broadcastType == TVT.Constants.BroadcastMaterialType.PROGRAMME then
		return self.hourlyNewsAudience[currentI]
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>> STATISTIC EVALUATOR >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["StatisticEvaluator"] = class(SLFDataObject, function(c)
	SLFDataObject.init(c)		-- must init base!
	c.TotalMinValue = -1		-- minimum value
	c.TotalMaxValue = -1		-- maximum value
	c.MinValue = -1				-- minimum value since last Adjust() call
	c.MaxValue = -1				-- maximum value since last Adjust() call
	c.AverageValue = -1			-- average value since last Adjust() call
	c.CurrentValue = -1			-- last set value


	c.TotalSum = 0			-- sum of all added values
	c.Values = 0			-- amount of added values
	c.adjustTimes = 0		-- times Adjust() was called
	c._MinMaxSet = false	-- were Min and Max values set?
end)


function StatisticEvaluator:typename()
	return "StatisticEvaluator"
end


-- sums up the values collected before as a single "averaged" value
function StatisticEvaluator:Adjust()
	self._MinMaxSet = true

	if self.Values > 0 then
		self.TotalSum = self.AverageValue

		self.Values = 1
	end

	self.MinValue = self.AverageValue
	self.MaxValue = self.AverageValue

	-- do not reset "CurrentValue"!
	--self.CurrentValue = -1

	self.adjustTimes = self.adjustTimes + 1
end


function StatisticEvaluator:AddValue(value)
	if value == nil then
		logWithLevel(LOG_ERROR, LOG_ERROR, "########## StatisticEvaluator:AddValue - NIL VALUE #############")
		return
	end


	--if just adjusted then set new min/max
	if not self._MinMaxSet then
		self.MinValue = value
		self.MaxValue = value

		self._MinMaxSet = true
	end

	if value < self.MinValue then self.MinValue = value; end
	if value > self.MaxValue then self.MaxValue = value; end
	if value < self.TotalMinValue then self.TotalMinValue = value; end
	if value > self.TotalMaxValue then self.TotalMaxValue = value; end

	self.Values = self.Values + 1
	self.CurrentValue = value
	self.TotalSum = self.TotalSum + value

	-- keep up to 3 decimals
	self.AverageValue = math.round(self.TotalSum / self.Values, 3)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["Requisition"] = class(SLFDataObject, function(c)
	SLFDataObject.init(c)	-- must init base!
	c.TaskId = nil
	c.TaskOwnerId = nil
	c.RequisitionId = nil
	c.Priority = 0 -- 10 = hoch 1 = gering
	c.Done = false
	c.reason = nil
end)


function Requisition:typename()
	return "Requisition"
end


function Requisition:CheckActuality()
	return true
end


function Requisition:Complete()
	self.Done = true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function RecalculateTasksPrio(tasks)
	for k,v in pairs(tasks) do
		v:RecalcPriority()
	end
end


function SortTasksByPrio(tasks)
	RecalculateTasksPrio(tasks)

	local sortTable = {}
	for k,v in pairs(tasks) do
		table.insert(sortTable, v)
	end
	local sortMethod = function(a, b)
		return a.CurrentPriority > b.CurrentPriority
	end
	table.sort(sortTable, sortMethod)
	return sortTable
end


function SortTasksByInvestmentPrio(tasks)
	RecalculateTasksPrio(tasks)

	local sortTable = {}
	for k,v in pairs(tasks) do
		table.insert(sortTable, v)
	end
	local sortMethod = function(a, b)
		return a.CurrentInvestmentPriority > b.CurrentInvestmentPriority
	end
	table.sort(sortTable, sortMethod)
	return sortTable
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


function getPlayer()
	return _G["globalPlayer"]
end

--[[
function kiMsg(pMessage, allPlayers)
	if allPlayers ~= nil then
		TVT.PrintOut("P" .. TVT.ME ..": " .. pMessage)
	elseif TVT.ME == 2 then --Nur Debugausgaben von Spieler 2
		TVT.PrintOut(pMessage)
	end
	TVT.addToLog(pMessage)
end

function infoMsg(pMessage)
	if TVT.ME == 2 then --Nur Debugausgaben von Spieler 2
		--TVT.PrintOut(pMessage)
		--TVT.SendToChat(TVT.ME .. ": " .. pMessage)
	end
end
--]]

function debugMsgDepth(change)
	currentDebugMsgDepth = math.max(0, currentDebugMsgDepth + change)
end


function debugMsg(pMessage, allPlayers)
	if pMessage == nil then return end

	if currentDebugMsgDepth > 0 then
		pMessage = string.rep("  ", currentDebugMsgDepth) .. pMessage
	end

	if allPlayers ~= nil then
		TVT.PrintOut("P" .. TVT.ME ..": " .. pMessage)
	elseif TVT.ME == 2 then --Nur Debugausgaben von Spieler 2
		--TVT.PrintOutDebug(pMessage)
		--TVT.PrintOut(pMessage)
		--TVT.SendToChat(TVT.ME .. ": " .. pMessage)
	end
	TVT.addToLog(pMessage)
end

--main log method - write message if given level should be logged
function logWithLevel(currentLogLevel, messageLogLevel, message)
	if currentLogLevel ~= nil then
		if messageLogLevel ~= nil then
			if message~=nil then
				if messageLogLevel == LOG_ERROR then message = "ERROR: " .. message end
				if messageLogLevel > LOG_OFF and messageLogLevel <= currentLogLevel then
					debugMsg(message)
				end
			end
		else
			debugMsg("Error: message log level not defined " .. debug.traceback())
		end
	else
		debugMsg("Error: current log level not defined " .. debug.traceback())
	end
end


function CutFactor(factor, minValue, maxValue)
	if (factor > maxValue) then
		return maxValue
	elseif (factor < minValue) then
		return minValue
	else
		return factor
	end
end


function math.clamp( n, min, max )
	return n > max and max or n < min and min or n
end


function FixDayAndHour(day, hour)
	if day == nil then
		print(debug.traceback())
	end
	if hour == nil then hour = 0; end

	local moduloHour = hour % 24
	--local moduloHour = hour
	--if (hour > 23) then
	--	moduloHour = hour % 24
	--end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour

	--[[
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
	--]]
end



-- enhancing list
-- from http://www.lua.org/pil/11.4.html
--[[
function List.new ()
	return {first = 0, last = -1}
end


function List.pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end


function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end


function List.popleft (list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end


function List.popright (list)
  local last = list.last
  if list.first > last then error("list is empty") end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end
]]
