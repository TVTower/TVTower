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

	c.RecognizedTerrorLevel = false
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
end

function TaskRoomBoard:GetNextJobInTargetRoom()
	if (self.ChangeRoomSignsJob.Status ~= JOB_STATUS_DONE) then
		return self.ChangeRoomSignsJob
	end

--	self:SetWait()
	self:SetDone()
end

function TaskRoomBoard:getSituationPriority()
	-- situation is normal if we do not know about terror (needs
	-- visit of the news agency and a higher level)
	if (not self.RecognizedTerrorLevel) then
		return 0
	end

	-- fix broken savegames (got one with values of 40.000.000)
	-- which therefor get unbelievable high priorities
	self.FRDubanTerrorLevel = math.clamp(self.FRDubanTerrorLevel, -10, 10)
	self.VRDubanTerrorLevel = math.clamp(self.VRDubanTerrorLevel, -10, 10)

	local maxTerrorLevel = math.max(self.FRDubanTerrorLevel, self.VRDubanTerrorLevel)
	if maxTerrorLevel >= 3 then
		self.SituationPriority = math.max(self.SituationPriority, maxTerrorLevel * 8)
	end

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
	--kiMsg("Starte JobChangeRoomSigns")
end

function JobChangeRoomSigns:Tick()
    for index = 0, TVT.rb_GetSignCount() - 1, 1 do
		local response = TVT.rb_GetSignAtIndex(index)
		if response.result == TVT.RESULT_OK then
			local sign = response.data
			if (sign ~= nil and sign.GetOwner() == TVT.ME) then
				--Noch am richtigen Platz?
				if sign.IsAtOriginalPosition() == 0 then
					kiMsg("Haenge Raumschild (" .. sign.GetOwnerName() .. ") wieder an den richtigen Platz: " .. sign.GetSlot() .. "/" .. sign.GetFloor() .. " -> " .. sign.GetOriginalSlot() .. "/" .. sign.GetOriginalFloor())
					--wieder alles in Ordnung bringen
					TVT.rb_SwitchSignPositions(sign.GetSlot(), sign.GetFloor(), sign.GetOriginalSlot(), sign.GetOriginalFloor())
				end
			end
		end
    end

	--TODO: Gerichtsvollzieher auf den Gegner hetzen
	--TODO: Schilder absichtlich durcheinander bringen

	local player = _G["globalPlayer"]

	if self.Task.FRDubanTerrorLevel >= 2 then
		local sign = TVT.rb_GetFirstSignOfRoom(TVT.ROOM_FRDUBAN).data
		local enemyId = player:GetNextEnemyId()
		local roomId = self:GetEnemyRoomId(enemyId)
		local roomSign = TVT.rb_GetFirstSignOfRoom(roomId).data
		TVT.rb_SwitchSigns(sign, roomSign)
		kiMsg("Verschiebe FRDuban-Schild auf Raum " .. roomId .. " (" .. roomSign.GetOwnerName() ..") des Spielers " .. enemyId )
	end

	if self.Task.VRDubanTerrorLevel >= 2 then
		local sign = TVT.rb_GetFirstSignOfRoom(TVT.ROOM_VRDUBAN).data
		local enemyId = player:GetNextEnemyId()
		local roomId = self:GetEnemyRoomId(enemyId)
		local roomSign = TVT.rb_GetFirstSignOfRoom(roomId).data
		TVT.rb_SwitchSigns(sign, roomSign)
		kiMsg("Verschiebe  VRDuban-Schild auf Raum " .. roomId .. " (" .. roomSign.GetOwnerName() ..") des Spielers " .. enemyId )
	end

	-- handled the situation "for now"
	self.Task.SituationPriority = 0
	self.Task.RecognizedTerrorLevel = false

	self.Status = JOB_STATUS_DONE
end

function JobChangeRoomSigns:GetEnemyRoomId(playerId)
	local random = math.random(1, 100)
	if (random <= 50) then
		return TVT.GetOfficeIdOfPlayer(playerId)
	elseif (random <= 75) then
		return TVT.GetNewsAgencyIdOfPlayer(playerId)
	elseif (random <= 90) then
		return TVT.GetBossOfficeIdOfPlayer(playerId)
	elseif (random <= 100) then
		return TVT.GetArchiveIdOfPlayer(playerId)
	end
	--TODO: Später sind vielleicht Studios noch sinnvoll.
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<