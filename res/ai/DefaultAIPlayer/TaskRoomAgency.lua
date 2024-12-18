-- File: TaskRoomAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskRoomAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_ROOMAGENCY"]
	c.TargetRoom = TVT.ROOM_ROOMAGENCY
	c.BudgetWeight = 0
	c.BasePriority = 0
	c.studioToRent = 0
	c.studioSize = 0
end)

function TaskRoomAgency:typename()
	return "TaskRoomAgency"
end

function TaskRoomAgency:Activate()
	self.RentRoomJob = JobRentRoom()
	self.RentRoomJob.Task = self

	--self.LogLevel = LOG_TRACE
end

function TaskRoomAgency:GetNextJobInTargetRoom()
	if (self.RentRoomJob.Status ~= JOB_STATUS_DONE) then
		return self.RentRoomJob
	end

	self:SetDone()
end

function TaskRoomAgency:getSituationPriority()
	if self.studioSize ~=nil and self.studioSize > 0 then
		self.SituationPriority = 10
		self.BasePriority = 1
	else
		self.SituationPriority = 0
		self.BasePriority = 0
	end
	return self.SituationPriority
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobRentRoom"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobRentRoom:typename()
	return "JobRentRoom"
end

function JobRentRoom:Prepare(pParams)

end

function JobRentRoom:Tick()
	if self.Task.studioSize > 0 then
		local result = TVT.ra_rentStudio(self.Task.studioToRent)
		if result == TVT.RESULT_OK then
			local player = getPlayer()
			if player.maxStudioSize < self.Task.studioSize then player.maxStudioSize = self.Task.studioSize end
			self.Task.studioSize = 0
			self.Task.studioToRent = 0
		elseif result == TVT.RESULT_NOTALLOWED then
			self.Task.studioSize = 0
			self.Task.studioToRent = 0
		end
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<