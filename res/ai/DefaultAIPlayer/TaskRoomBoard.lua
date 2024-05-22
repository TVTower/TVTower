-- File: TaskRoomBoard
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskRoomBoard"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_ROOMBOARD"]
	c.TargetRoom = TVT.ROOM_ROOMBOARD
	c.BudgetWeight = 0
	c.BasePriority = 0
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0

	--no budget to spare
	c.RequiresBudgetHandling = false

	c.RecognizedTerrorLevel = false
	c.forceChangeSigns = false
	c.FRDubanTerrorLevel = 0 --FR Duban Terroristen
	c.VRDubanTerrorLevel = 0 --VR Duban Terroristen
end)

function TaskRoomBoard:typename()
	return "TaskRoomBoard"
end

function TaskRoomBoard:Activate()
	-- Was getan werden soll:
	self.ChangeRoomSignsJob = JobChangeRoomSigns()
	self.ChangeRoomSignsJob.Task = self
	--self.LogLevel = LOG_TRACE

	--TODO abort task without going to the room
	local minSinceLastDone = self:getMinutesSinceLastDone()
	--self:LogInfo("roomBoard " .. minSinceLastDone)
	if minSinceLastDone < 120 and self.SituationPriority < 20 then
		self:SetCancel()
	end
	
end

function TaskRoomBoard:GetNextJobInTargetRoom()
	if (self.ChangeRoomSignsJob.Status ~= JOB_STATUS_DONE) then
		return self.ChangeRoomSignsJob
	end

	self:SetDone()
end

function TaskRoomBoard:getSituationPriority()
	return self.SituationPriority
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobChangeRoomSigns"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobChangeRoomSigns:typename()
	return "JobChangeRoomSigns"
end

function JobChangeRoomSigns:Prepare(pParams)

end

function JobChangeRoomSigns:Tick()
	for index = 0, TVT.rb_GetSignCount() - 1, 1 do
		local response = TVT.rb_GetSignAtIndex(index)
		if response.result == TVT.RESULT_OK then
			local sign = response.data
			if (sign ~= nil and sign.GetOwner() == TVT.ME) then
				--Noch am richtigen Platz?
				if sign.IsAtOriginalPosition() == 0 then
					self:LogInfo("Haenge Raumschild (" .. sign.GetOwnerName() .. ") wieder an den richtigen Platz: " .. sign.GetSlot() .. "/" .. sign.GetFloor() .. " -> " .. sign.GetOriginalSlot() .. "/" .. sign.GetOriginalFloor())
					--wieder alles in Ordnung bringen
					TVT.rb_SwitchSignPositions(sign.GetSlot(), sign.GetFloor(), sign.GetOriginalSlot(), sign.GetOriginalFloor())
				end
			end
		end
	end

	--TODO: Gerichtsvollzieher auf den Gegner hetzen
	--TODO: Schilder absichtlich durcheinander bringen

	if self.Task.forceChangeSigns == false then
		if self.Task.RecognizedTerrorLevel == true and math.random(0,100) > 70 then
			self.Task.forceChangeSigns = true
		end
	end

	if self.Task.forceChangeSigns == true then
		local player = getPlayer()
		local sign
		local name
		if self.Task.FRDubanTerrorLevel >= 2 then
			sign = TVT.rb_GetFirstSignOfRoom(TVT.ROOM_FRDUBAN).data
			name = "FRDuban"
		else
			sign = TVT.rb_GetFirstSignOfRoom(TVT.ROOM_VRDUBAN).data
			name = "VRDuban"
		end
		local enemyId = player:GetNextEnemyId()
		local roomId = self:GetEnemyRoomId(enemyId)
		local roomSign = TVT.rb_GetFirstSignOfRoom(roomId).data
		if roomSign ~=nil then
			TVT.rb_SwitchSigns(sign, roomSign)
			self:LogDebug("Verschiebe "..name.."-Schild auf Raum " .. roomId .. " (" .. roomSign.GetOwnerName() ..") des Spielers " .. enemyId )
		else
			self:LogError("Raumschild von enemyId "..enemyId.." nicht ermittelbar")
		end
	end

	-- handled the situation "for now"
	self.Task.SituationPriority = 0
	self.Task.RecognizedTerrorLevel = false
	self.Task.forceChangeSigns = false 

	self.Status = JOB_STATUS_DONE
end

function JobChangeRoomSigns:GetEnemyRoomId(playerId)
	local random = math.random(1, 100)
	if (random <= 50) then
		return TVT.GetOfficeIdOfPlayer(playerId)
	elseif (random <= 75) then
		return TVT.GetNewsAgencyIdOfPlayer(playerId)
	elseif (random <= 90) then
		return TVT.GetArchiveIdOfPlayer(playerId)
	elseif (random <= 100) then
		return TVT.GetBossOfficeIdOfPlayer(playerId)
	end
	--TODO: Später sind vielleicht Studios noch sinnvoll.
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<