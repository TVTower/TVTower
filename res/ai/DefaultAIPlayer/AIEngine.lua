-- File: AIEngine.lua
-- ============================
-- === AI Engine ===
-- ============================
-- Author: Manuel Vögele (STARS_crazy@gmx.de)
--         Ronny Otto
-- Last modified: 25.09.2016
-- Created at: 12.12.2007

-- ##### INCLUDES #####
dofile("res/ai/DefaultAIPlayer/SLF.lua")

-- ##### GLOBALS #####
globalPlayer = nil
unitTestMode = false

-- ##### KONSTANTEN #####
TASK_STATUS_OPEN	= "T_open"
TASK_STATUS_PREPARE	= "T_prepare"
TASK_STATUS_RUN		= "T_run"
TASK_STATUS_WAIT	= "T_wait"
TASK_STATUS_IDLE	= "T_idle"
TASK_STATUS_DONE	= "T_done"
TASK_STATUS_CANCEL	= "T_cancel"

JOB_STATUS_NEW		= "J_new"
JOB_STATUS_REDO		= "J_redo"
JOB_STATUS_RUN		= "J_run"
JOB_STATUS_DONE		= "J_done"
JOB_STATUS_CANCEL	= "J_cancel"

-- ##### KLASSEN #####
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
end)

function AIPlayer:typename()
	return "AIPlayer"
end

function AIPlayer:initialize()
	math.randomseed(TVT.GetMillisecs())

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
			debugMsg("ForceTask: " .. taskID .. " with adjusted priority " .. priority)
		else
			debugMsg("ForceTask: " .. taskID .. " with priority " .. priority)
		end
		task.SituationPriority = priority
		player:ForceNextTask()
	end
end


--stop a current task and start the next one
function AIPlayer:ForceNextTask()
	debugMsg("ForceNextTask")
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
				   self.CurrentTask.Status == TASK_STATUS_NEW then
					cancelTask = false
				end
			else
				-- only cancel if still in preparation (moving to the tasks
				-- target room)
				cancelTask = true
				if self.CurrentTask.Status ~= TASK_STATUS_PREPARE and
				   self.CurrentTask.Status ~= TASK_STATUS_NEW and
				   self.CurrentTask.Status ~= TASK_STATUS_RUN then
					cancelTask = false
				end
			end
			-- cancel old one
			if cancelTask then
				debugMsg("ForceNextTask: Cancel current task...")
				self.CurrentTask:SetAbort()
			end

			--assign next task
			self.CurrentTask = nextTask
			--activate it
			self.CurrentTask:CallActivate()
			--start the next job of the new task
			self.CurrentTask:StartNextJob()
		else
			debugMsg("ForceNextTask() failed: no follow up task found...")
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
			-- wait until the NEXT task has a priority > 35 (idle a bit)
			local tasksPrioOrdered = SortTasksByPrio(self.TaskList)
			local nextTask = tasksPrioOrdered[1] -- 0 = current, 1 = next
			if nextTask ~= nil and nextTask.CurrentPriority > 35 then
				self:BeginNewTask()
			--else
			--	devMsg("IDLING a bit ...")
			end
		else
			self.CurrentTask:Tick()
		end
	end
end

function AIPlayer:TickAnalyse()
	--Zum überschreiben
end

function AIPlayer:BeginNewTask()
	--TODO: Warte-Task einfügen, wenn sich ein Task wiederholt
	self.CurrentTask = self:SelectTask()
	if self.CurrentTask == nil then
		debugMsg("AIPlayer:BeginNewTask - task is nil... " )
	else
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
	--Zum überschreiben
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
	c.MaxTicks = 30 --Wie viele Ticks darf der Task maximal laufen?
	c.IdleTicks = 10 --Wie viele Ticks soll nichts gemacht werden?
	c.TargetRoom = -1 -- Wie lautet die ID des Standard-Zielraumes? !!! Muss überschrieben werden !!!

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

	c.FixedCosts = 0
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
		debugMsg("_G[\"globalPlayer\"] is NIL!")
		return 0
	end
	return player.WorldTicks
end

function AITask:PayFromBudget(value)
	self.CurrentBudget = self.CurrentBudget - value
end

function AITask:resume()
	-- Ronny 16.10.2016: should no longer be needed as the AI now stores
	-- its external objects in "TVT.*"
	if self.InvalidDataObject then
		if self.Status == TASK_STATUS_PREPARE or self.Status == TASK_STATUS_RUN then
			infoMsg(type(self) .. ": InvalidDataObject resume => TASK_STATUS_OPEN")
			self.Status = TASK_STATUS_OPEN
		end
		self.InvalidDataObject = false
		table.removeKey(self, "InvalidDataObject");
	end
end

function AITask:CallActivate()
	self.MaxTicks = math.random(9, 17)
	self.TickCounter = 0
	debugMsg("### Starte Task '" .. self:typename() .. "'! (Prio: " .. self.CurrentPriority .."). MaxTicks: " .. self.MaxTicks)
	self:Activate()
end

function AITask:Activate()
	debugMsg("Implementiere mich... " .. type(self))
end

function AITask:AdjustmentsForNextDay()
	self.CurrentInvestmentPriority = self.CurrentInvestmentPriority + self.InvestmentPriority
	--kann überschrieben werden
end

function AITask:OnDayBegins()
	--kann überschrieben werden
end

--Wird aufgerufen, wenn der Task zur Bearbeitung ausgewaehlt wurde (NICHT UEBERSCHREIBEN!)
function AITask:StartNextJob()
	--debugMsg("StartNextJob")

	--local roomNumber = TVT.GetPlayerRoom()
	--debugMsg("Player-Raum: " .. roomNumber .. " - Target-Raum: " .. self.TargetRoom)
	if TVT.GetPlayerRoom() ~= self.TargetRoom then --sorgt dafür, dass der Spieler in den richtigen Raum geht!
		self.Status = TASK_STATUS_PREPARE
		self.CurrentJob = self:getGotoJob()
	else
		self.Status = TASK_STATUS_RUN
		self.StartTaskWorldTicks = self:getWorldTicks()
		self.StartTask = WorldTime.GetTimeGoneAsMinute()
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
		debugMsg("Status OPEN! Darf nicht sein!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		debugMsg(self:typename())
		self:SetDone()
	end

	-- have to idle?
	if (self.Status == TASK_STATUS_IDLE) then
		self.idleTicks = self.idleTicks - 1
		debugMsg("idling ... " .. self.idleTicks)
		if (self.idleTicks < 0) then
			self.idleTicks = 0
			self.Status = TASK_STATUS_RUN
		end
	end

	if ((self.Status == TASK_STATUS_RUN) or (self.Status == TASK_STATUS_WAIT)) then
		self.TickCounter = self.TickCounter + 1
		--debugMsg("MaxTickCount: " .. self.TickCounter .. " > " .. self.MaxTicks)
		if (self.TickCounter > self.MaxTicks) then
			self:TooMuchTicks()
		end
	end

	if ((self.Status == TASK_STATUS_RUN) or (self.Status == TASK_STATUS_PREPARE)) then
		if (self.CurrentJob == nil) then
			--debugMsg("----- Kein Job da - Neuen Starten")
			self:StartNextJob() --Von vorne anfangen
		else
			if self.CurrentJob.Status == JOB_STATUS_CANCEL then
				self.CurrentJob = nil
				self:SetCancel()
				return
			elseif self.CurrentJob.Status == JOB_STATUS_DONE then
				self.CurrentJob = nil
				--debugMsg("----- Alter Job ist fertig - Neuen Starten")
				self:StartNextJob() --Von vorne anfangen
			else
				--debugMsg("----- Job-Tick")
				self.CurrentJob:CallTick() --Fortsetzen
			end
		end
	end
end

function AITask:GetNextJobInTargetRoom()
	--return self:getGotoJob()
	error("Muss noch implementiert werden")
end

function AITask:getGotoJob()
	local aJob = AIJobGoToRoom()
	aJob.Task = self
	aJob.TargetRoom = self.TargetRoom
	return aJob
end

function AITask:RecalcPriority()
	if (self.LastDone == 0) then self.LastDone = WorldTime.GetTimeGoneAsMinute() end
	if (self.LastDoneWorldTicks == 0) then self.LastDoneWorldTicks = self:getWorldTicks() end

	local player = _G["globalPlayer"]
	local Ran1 = math.random(75, 125) / 100
	local TimeDiff = math.round(WorldTime.GetTimeGoneAsMinute() - self.LastDone)
	local TicksDiff = math.round(self:getWorldTicks() - self.LastDoneWorldTicks)
	local requisitionPriority = player:GetRequisitionPriority(self.Id)

	local calcPriority = (self.BasePriority + self:getSituationPriority()) * Ran1 + requisitionPriority
	local timeFactor = (20 + TimeDiff) / 20
	local ticksFactor = (20 + TicksDiff) / 20

	local timePriority = self:getStrategicPriority()  * calcPriority * timeFactor
	local ticksPriority = self:getStrategicPriority()  * calcPriority * ticksFactor

	self.CurrentPriority = math.max(timePriority, ticksPriority)

	-- if the target room is blocked then reduce priority
	-- reduction of up to 80% is possible
	--   0 minutes or less being  0%
	--  10 minutes or less being 20%
	--  40 minutes or more being 80%
	if self.TargetRoom > 0 then
		local blockedMinutes = TVT.GetRoomBlockedTime(self.TargetRoom) / 60
		--debugMsg("PRIO: Target room ".. self.TargetRoom ..". blockedMinutes " .. blockedMinutes))
		if blockedMinutes >= 1 then
			--debugMsg("PRIO: Target room is blocked too long, reducing priority. " .. math.max(0.2, 1.0 - 0.02*blockedMinutes))
			self.CurrentPriority = math.max(0.2, 1.0 - 0.02*blockedMinutes)
		end
	end

	--debugMsg("Task: " .. self:typename() .. " - BasePriority: " .. self.BasePriority .." - SituationPriority: " .. self:getSituationPriority() .. " - Ran1 : " .. Ran1 .. "  RequisitionPriority: " .. requisitionPriority)
	--debugMsg("Task: " .. self:typename() .. " - Prio: " .. self.CurrentPriority .. "  (time: " .. timePriority .." | ticks: " .. ticksPriority ..") - TimeDiff:" .. TimeDiff .. "  TicksDiff:" .. TicksDiff.." (tF: " ..timeFactor .." | cP: " .. calcPriority .. ")")
end

function AITask:TooMuchTicks()
	debugMsg("... waited long enough.")
	self:SetDone()
end

function AITask:SetWait()
	debugMsg("Waiting...")
	self.Status = TASK_STATUS_WAIT
end

function AITask:SetIdle(idleTicks)
	idleTicks = idleTicks or 10 --default is 10 ticks
	debugMsg("idling for " .. idleTicks .. " ticks")
	self.Status = TASK_STATUS_IDLE
end

function AITask:SetDone()
	debugMsg("### Task abgeschlossen!")
	local player = _G["globalPlayer"]
	self.Status = TASK_STATUS_DONE
	self.SituationPriority = 0
	self.LastDone = WorldTime.GetTimeGoneAsMinute()
	self.LastDoneWorldTicks = self:getWorldTicks()

	-- reset back
	self.assignmentType = 0
end

--no priority modification
function AITask:SetAbort()
	debugMsg("<<< Task aborted!")
	self.Status = TASK_STATUS_CANCEL

	-- reset back
	self.assignmentType = 0
end

--with priority modification
function AITask:SetCancel()
	debugMsg("<<< Task cancelled!")
	self.Status = TASK_STATUS_CANCEL
	self.SituationPriority = self.SituationPriority / 2

	-- reset back
	self.assignmentType = 0
end

function AITask:OnEnterRoom(roomId)
	--debugMsg("OnEnterRoom!")
	if (self.CurrentJob ~= nil) then
		self.CurrentJob:OnEnterRoom(roomId)
	end
end

function AITask:OnBeginEnterRoom(roomId, result)
	--debugMsg("OnBeginEnterRoom!")
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
	c.StartParams = nil
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
			infoMsg(self:typename() .. ": InvalidDataObject resume => JOB_STATUS_NEW")
			self.Status = JOB_STATUS_NEW
		end
		self.InvalidDataObject = false
		table.removeKey(self, "InvalidDataObject");
	end
end

function AIJob:Start(pParams)
	self.StartParams = pParams
	self.StartJob = WorldTime.GetTimeGoneAsMinute()
	self.LastCheck = WorldTime.GetTimeGoneAsMinute()
	self.StartJobWorldTicks = 0
	self.LastCheckWorldTicks = 0
	self.Ticks = 0
	self:Prepare(pParams)
end

function AIJob:Prepare(pParams)
	debugMsg("Implementiere mich: " .. type(self))
end

function AIJob:CallTick()
	self.Ticks = self.Ticks + 1
	self:Tick()
end

function AIJob:Tick()
	--Kann ueberschrieben werden
end

function AIJob:ReDoCheck(minutesWait, ticksWait)
	if ((self.LastCheckWorldTicks + ticksWait) < self:getWorldTicks() or (self.LastCheck + minutesWait) < WorldTime.GetTimeGoneAsMinute()) then
		--debugMsg("ReDoCheck: (time: " .. self.LastCheck .. " + " .. minutesWait .. " < " .. WorldTime.GetTimeGoneAsMinute() .."    ticks: " ..self.LastCheckWorldTicks .. " + " .. ticksWait .." < " .. self:getWorldTicks())
		self.Status = JOB_STATUS_REDO
		self.LastCheckWorldTicks = self:getWorldTicks()
		self.LastCheck = WorldTime.GetTimeGoneAsMinute()
		self:Prepare(self.StartParams)
	end
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
	debugMsg("SetCancel(): Implementiere mich: " .. type(self))
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
		self.IdleTill = WorldTime.GetTimeGoneAsMinute() + self.IdleTime
		--debugMsg("Set self.IdleTill = " .. self.IdleTill)
	end
	if (self.IdleTicks ~= 0) then
		self.IdleTillWorldTicks = self:getWorldTicks() + self.IdleTicks
		--debugMsg("Set self.IdleTillWorldTicks = " .. self.IdleTillWorldTicks)
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
	local finishedIdling = false
	if (self.IdleTill == -1) and (self.IdleTillWorldTicks == -1) then
		finishedIdling = true
	elseif (self.IdleTill ~= -1) and ((self.IdleTill - WorldTime.GetTimeGoneAsMinute()) <= 0) then
		finishedIdling = true
	elseif (self.IdleTillWorldTicks ~= -1) and ((self.IdleTillWorldTicks - self:getWorldTicks()) <= 0) then
		finishedIdling = true
	end

	if finishedIdling == true then
		--debugMsg("Finished idling ...")
		self.Status = JOB_STATUS_DONE
		return
	else
		--debugMsg("Idling ...")
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIJobGoToRoom"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
	c.TargetRoom = 0
	c.IsWaiting = false
	c.WaitSince = -1
	c.WaitSinceWorldTicks = -1
	c.WaitTill = -1
	c.WaitTillWorldTicks = -1
end)

function AIJobGoToRoom:typename()
	return "AIJobGoToRoom"
end

function AIJobGoToRoom:OnBeginEnterRoom(roomId, result)
	local resultId = tonumber(result)
	if (resultId == TVT.RESULT_INUSE) then
		if (self.IsWaiting) then
			-- debugMsg( TVT.ME .. " BeginEnterRoom: Room still in use. Will continue to wait...a bit. Waiting time: " .. self.WaitTill .. "/" .. WorldTime.GetTimeGoneAsMinute().."  ticks=" .. self.WaitTillWorldTicks .. "/" .. self:getWorldTicks() .. ")")
		elseif (self:ShouldIWait()) then
			self.IsWaiting = true
			self.WaitSince = WorldTime.GetTimeGoneAsMinute()
			self.WaitSinceWorldTicks = self:getWorldTicks()
			self.WaitTill = self.WaitSince + 3 + (self.Task.CurrentPriority / 6)
			self.WaitTillWorldTicks = self.WaitSinceWorldTicks + 3 + (self.Task.CurrentPriority / 6)
			if ((self.WaitTill - self.WaitSince) > 20) then
				self.WaitTill = self.WaitSince + 20
			end
			if ((self.WaitTillWorldTicks - self.WaitSinceWorldTicks) > 20) then
				self.WaitTillWorldTicks = self.WaitSinceWorldTicks + 20
			end
			local rand = math.random(50, 75)
			debugMsg("BeginEnterRoom: Room occupied! Will wait a bit. Moving to pixel " .. rand .. ". Waiting time: " .. self.WaitTill .. "/" .. WorldTime.GetTimeGoneAsMinute().."  /  ticks: " .. self.WaitTillWorldTicks .. "/" .. self:getWorldTicks() .. ")")
			TVT.doGoToRelative(rand)
		else
			debugMsg("BeginEnterRoom: Room occupied! Won't wait this time.")
			self.Status = JOB_STATUS_CANCEL
			self.Task:SetCancel()
		end
	elseif(resultId == TVT.RESULT_NOTALLOWED) then
		local blockedTime = TVT.GetRoomBlockedTime(roomId)
		--if blocked shorter than 10 minutes, we will wait
		if blockedTime == -1 or blockedTime <= 60*10 then
			debugMsg("BeginEnterRoom: Room blocked short enough! ... waiting a bit." .. blockedTime)
		else
			debugMsg("BeginEnterRoom: Room blocked! Waiting time too long: " .. math.floor(blockedTime/60).. " minute(s).")
			self.Status = JOB_STATUS_CANCEL
			self.Task:SetCancel()
		end
	elseif(resultId == TVT.RESULT_NOKEY) then
		debugMsg("BeginEnterRoom: Room locked! Need a key to enter. Cancelled task.")
		self.Status = JOB_STATUS_CANCEL
		self.Task:SetCancel()
	elseif(resultId == TVT.RESULT_OK) then
		--debugMsg("BeginEnterRoom: Entering allowed. roomId: " .. roomId)
	end
end

function AIJobGoToRoom:OnEnterRoom(roomId)
	--debugMsg("EnterRoom: Entering roomId: " .. roomId)
	--debugMsg("AIJobGoToRoom DONE!")
	self.Status = JOB_STATUS_DONE
end

function AIJobGoToRoom:ShouldIWait()
	debugMsg("Warte vor dem Raum... (Prio: " .. self.Task.CurrentPriority .. ")")
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
	-- if we reached the target, just set it again
	if (self.Status == JOB_STATUS_REDO) or (self.Status == JOB_STATUS_RUN) then
		--debugMsg("OnReachTarget - GoToRoom again")
		TVT.DoGoToRoom(self.TargetRoom)
	end
end


function AIJobGoToRoom:Prepare(pParams)
	if ((self.Status == JOB_STATUS_NEW) or (self.Status == TASK_STATUS_PREPARE) or (self.Status == JOB_STATUS_REDO)) then
		--debugMsg("DoGoToRoom: " .. self.TargetRoom .. " => " .. self.Status)
		if TVT.DoGoToRoom(self.TargetRoom) <= 0 then
			--debugMsg("DoGoToRoom: failed, eg. not allowed to do so.")
		else
			self.Status = JOB_STATUS_RUN
		end
	end
end

function AIJobGoToRoom:Tick()
	if (self.IsWaiting) then
		--debugMsg("AIJobGoToRoom:Tick ... waiting")
		if (TVT.isRoomUnused(self.TargetRoom) == 1) then
			--debugMsg("Room is unused now")
			self.IsWaiting = false
			TVT.DoGoToRoom(self.TargetRoom)
		elseif ((self.WaitTill - WorldTime.GetTimeGoneAsMinute()) <= 0 or (self.WaitTillWorldTicks - self:getWorldTicks()) <= 0) then
			debugMsg("Room is still used. I do not want to wait anylonger.")
			self.IsWaiting = false
			self.Status = JOB_STATUS_CANCEL
		else
			--debugMsg("Waiting to enter the room. Waiting till time: " .. self.WaitTill .. "/" .. WorldTime.GetTimeGoneAsMinute() .. "  /  ticks: " .. self.WaitTillWorldTicks .. "/" .. self:getWorldTicks() .. ".")
		end
	-- while walking / going by elevator
	elseif (self.Status ~= JOB_STATUS_DONE) then
		-- check if room is blocked - if so, abort task
		if (self.TargetRoom >= 0) then
			local blockedTime = TVT.GetRoomBlockedTime(self.TargetRoom)
			if blockedTime >= 0 then
				if blockedTime <=  60*10 then
					debugMsg("Target room is blocked but soon reopening.")
				else
					debugMsg("Target room is blocked ... cancelling task.")
					self.Status = JOB_STATUS_CANCEL
					self.Task:SetCancel()
				end
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
	debugMsg("   -> ADDING FAILED at " .. currentI .. "  unknown broadcastTypeID " .. broadcastTypeID)
end

function BroadcastStatistics:GetAttraction(day, hour, broadcastType)
	local currentI = tostring(day) .. string.format("%02d", hour)
	if broadcastType == TVT.Constants.BroadcastMaterialType.NEWSSHOW then
		return self.hourlyNewsAttraction[currentI]
	elseif broadcastType == TVT.Constants.BroadcastMaterialType.PROGRAMME then
--debugMsg("   -> GET PROG at " .. currentI)
	--	for k,v in pairs(self.hourlyProgrammeAttraction) do
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
	SLFDataObject.init(c)	-- must init base!
	c.MinValue = -1
	c.AverageValue = -1
	c.MaxValue = -1
	c.CurrentValue = -1

	c.MinValueTemp = 100000000000000
	c.AverageValueTemp = -1
	c.MaxValueTemp = -1

	c.TotalSum = 0
	c.Values = 0
	c.adjustTimes = 0
end)

function StatisticEvaluator:typename()
	return "StatisticEvaluator"
end

function StatisticEvaluator:Adjust()
	self.MinValueTemp = 100000000000000
	self.AverageValueTemp = -1
	self.MaxValueTemp = -1
	-- if used "before Adjust()" already, set Values to 1, so it
	-- takes the old value into account when calculating the average
	-- (1*old + x*new) / (1+x)
	if self.Values > 0 then
		self.Values = 1
	end
	-- do not reset "CurrentValue"!
	--self.CurrentValue = -1

	self.adjustTimes = self.adjustTimes + 1
end


function StatisticEvaluator:AddValue(value)
if value == nil then
	debugMsg("########## StatisticEvaluator:AddValue - NIL VALUE #############")
	return
end

	self.Values = self.Values + 1

	if value < self.MinValueTemp then
		self.MinValue = value
		self.MinValueTemp = value
	end
	if value > self.MaxValueTemp then
		self.MaxValue = value
		self.MaxValueTemp = value
	end

	self.CurrentValue = value
	self.TotalSum = self.TotalSum + value
	--self.AverageValueTemp = math.round(self.TotalSum / self.Values, 0)
	-- keep up to 3 decimals
	self.AverageValueTemp = math.round(self.TotalSum / self.Values, 3)
	self.AverageValue = self.AverageValueTemp
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

function kiMsg(pMessage, allPlayers)
	if allPlayers ~= nil then
		TVT.PrintOut("P" .. TVT.ME ..": " .. pMessage)
	elseif TVT.ME == 2 then --Nur Debugausgaben von Spieler 2
		TVT.PrintOut(pMessage)
	end
	TVT.addToLog(pMessage)
end

function debugMsg(pMessage, allPlayers)
	if allPlayers ~= nil then
		TVT.PrintOut("P" .. TVT.ME ..": " .. pMessage)
	elseif TVT.ME == 2 then --Nur Debugausgaben von Spieler 2
		--TVT.PrintOutDebug(pMessage)
		TVT.PrintOut(pMessage)
		--TVT.SendToChat(TVT.ME .. ": " .. pMessage)
	end
	TVT.addToLog(pMessage)
end

function infoMsg(pMessage)
	if TVT.ME == 2 then --Nur Debugausgaben von Spieler 2
		TVT.PrintOut(pMessage)
		--TVT.SendToChat(TVT.ME .. ": " .. pMessage)
	end
end

function devMsg(pMessage)
	TVT.PrintOut("== DEV == : " .. pMessage)
	--TVT.SendToChat(TVT.ME .. ": " .. pMessage)
	TVT.addToLog("== DEV == : " .. pMessage)
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
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
end