-- File: TaskCheckSigns
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskCheckSigns"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_CHECKSIGNS"]
	c.BudgetWeight = 0
	c.BasePriority = 1
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0

	--no budget to spare
	c.RequiresBudgetHandling = false

	c.terrorLevel = 0
	c.checkStudio = 0
end)

function TaskCheckSigns:typename()
	return "TaskCheckSigns"
end

function TaskCheckSigns:Activate()
	-- Was getan werden soll:
	self.CheckRoomSignsJob = JobCheckRoomSigns()
	self.CheckRoomSignsJob.Task = self
	self.TargetRoom = -1
	--determine target id on every task execution (current floor elevator)
	self.TargetID = TVT:getTargetID("elevatorplan", -1, TVT:getFigureFloor(), 0)

	--self.LogLevel = LOG_TRACE
end

function TaskCheckSigns:GetNextJobInTargetRoom()
	if (self.CheckRoomSignsJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckRoomSignsJob
	end

	self:SetDone()
end

function TaskCheckSigns:getSituationPriority()
	if self.terrorLevel >= 2 then
		self.SituationPriority = math.max(self.SituationPriority, self.terrorLevel)
	elseif self.checkStudio ~=nil and self.checkStudio > 0 then
		self.SituationPriority = 5
	end

	return self.SituationPriority
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobCheckRoomSigns"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobCheckRoomSigns:typename()
	return "JobCheckRoomSigns"
end

function JobCheckRoomSigns:Prepare(pParams)

end

function JobCheckRoomSigns:Tick()
	local scheduleRoomBoardTask = false
	local forceChangeSigns = false
	local rentableStudioSize = 0
	local rentableStudieId = 0
	for index = 0, TVT.ep_GetSignCount() - 1, 1 do
		local response = TVT.ep_GetSignAtIndex(index)
		if response.result == TVT.RESULT_OK then
			local sign = response.data
			if sign ~= nil then
				local rentableSignSize = TVT.ep_IsRentableStudio(sign)
				if rentableSignSize > rentableStudioSize then
					rentableStudioSize = rentableSignSize
					rentableStudieId = sign:GetRoomId()
				end
				--Noch am richtigen Platz?
				if sign.IsAtOriginalPosition() == 0 then
					if sign.GetOwner() == TVT.ME then
						scheduleRoomBoardTask = true
						self:LogInfo("own room in danger - need to go to the room board")
						break
					elseif TVT:isRoomPotentialStudio(sign:GetRoomId()) == TVT.RESULT_OK then
						--just guess - one of the changed signs is a potential studio
						--fix just in case
						scheduleRoomBoardTask = true
						self:LogInfo("potential attempt to gain new studio - need to go to the room board")
						break
					end
				end
			end
		end
	end

	--trigger changing enemy room signs
	if scheduleRoomBoardTask == false and self.Task.terrorLevel >=3 then
		if math.random(0,100) > 70 then
			scheduleRoomBoardTask = true
			forceChangeSigns = true
		end
	end

	if rentableStudioSize > getPlayer().maxStudioSize then
		local ra = getPlayer().TaskList[_G["TASK_ROOMAGENCY"]]
		if ra ~= nil then
			self:LogInfo("set studio in roomagency task")
			ra.studioToRent = rentableStudieId
			ra.studioSize = rentableStudioSize
		end
	else
		self.checkStudio = 0
	end

	if scheduleRoomBoardTask == true then
		local player = getPlayer()
		local sc = player.TaskList[_G["TASK_SCHEDULE"]]
		local rb = player.TaskList[_G["TASK_ROOMBOARD"]]
		if sc ~= nil and rb ~= nil then
			sc.SituationPriority = 500
			rb.SituationPriority = 10
			rb.forceChangeSigns = forceChangeSigns
		else
			self:LogError("did not find tasks for raising priority")
		end
	end

	-- handled the situation "for now"
	self.Task.SituationPriority = 0
	self.Task.terrorLevel = 0

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<