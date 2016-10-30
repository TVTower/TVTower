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
		local respo = TVT.rb_GetSignAtIndex(index)		
		local sign = TVT.rb_GetSignAtIndex(index).data		
		if (sign.GetOwner() == TVT.ME) then
			--Noch am richtigen Platz?
			if not sign.IsAtOriginalPosition() then
				--wieder alles in Ordnung bringen
				TVT.rb_SwitchSignPositions(sign.GetSlot(), sign.GetFloor(), sign.GetOriginalSlot(), sign.GetOriginalFloor())
				kiMsg("Eigenes Raumschild (" .. sign .. ") wieder an den richtigen Platz gehängt")
			end
		end
    end
		
	--TODO: Gerichtsvollzieher auf den Gegner hetzen
	--TODO: Schilder absichtlich durcheinander bringen
	
	if self.Task.FRDubanTerrorLevel >= 3 then
		local sign = TVT.rb_GetFirstSignOfRoom(TVT.ROOM_FRDUBAN).data
		local player = _G["globalPlayer"]
		local enemyId = player.GetNextEnemyId()
		local roomId = self:GetEnemyRoomId(enemyId)
		local roomSign = TVT.rb_GetFirstSignOfRoom(roomId).data
		TVT.rb_SwitchSigns(sign, roomSign)
		--TVT.rb_SwitchSignsByID(sign:GetID(), roomSign:GetID())
		kiMsg("Verschiebe FRDuban-Schild auf Raum " .. roomId .. " des Spielers " .. enemyId )
	end
	
	if self.Task.VRDubanTerrorLevel >= 3 then
		local sign = TVT.rb_GetFirstSignOfRoom(TVT.ROOM_VRDUBAN).data
		local player = _G["globalPlayer"]
		local enemyId = player.GetNextEnemyId()
		local roomId = self:GetEnemyRoomId(enemyId)
		local roomSign = TVT.rb_GetFirstSignOfRoom(roomId).data
		TVT.rb_SwitchSigns(sign, roomSign)
		kiMsg("Verschiebe  VRDuban-Schild auf Raum " .. roomId .. " des Spielers " .. enemyId )
	end
	
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