-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskAdAgency = AITask:new{	
	TargetRoom = TVT.ROOM_ADAGENCY;
	SpotsInAgency = nil;
	BasePriority = 8;
	BudgetWeigth = 0
	-- zu Senden
	-- Strafe
	-- Zuschauer
	-- Zeit
}

function TaskAdAgency:typename()
	return "TaskAdAgency"
end

function TaskAdAgency:Activate()
	debugMsg(">>> Starte Task 'TaskAdAgency'")
	-- Was getan werden soll:
	self.CheckSpots = JobCheckSpots:new()
	self.CheckSpots.AdAgencyTask = self
	
	self.AppraiseSpots = AppraiseSpots:new()
	self.AppraiseSpots.AdAgencyTask = self
	
	self.SignRequisitedContracts = SignRequisitedContracts:new()
	self.SignRequisitedContracts.AdAgencyTask = self		
	
	self.SignContracts = SignContracts:new()
	self.SignContracts.AdAgencyTask = self	
	
	self.SpotsInAgency = {}
end

function TaskAdAgency:GetNextJobInTargetRoom()
	if (MY.ProgrammeCollection.GetContractCount() >= 8) then
		self:SetDone()
		return nil
	elseif (self.CheckSpots.Status ~= JOB_STATUS_DONE) then
		return self.CheckSpots
	elseif (self.AppraiseSpots.Status ~= JOB_STATUS_DONE) then
		return self.AppraiseSpots
	elseif (self.SignRequisitedContracts.Status ~= JOB_STATUS_DONE) then	
		return self.SignRequisitedContracts		
	elseif (self.SignContracts.Status ~= JOB_STATUS_DONE) then	
		return self.SignContracts
	end
	
	self:SetDone()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobCheckSpots = AIJob:new{
	CurrentSpotIndex = 0;
	AdAgencyTask = nil
}

function JobCheckSpots:typename()
	return "JobCheckSpots"
end

function JobCheckSpots:Prepare(pParams)
	debugMsg("Schaue Werbeangebote an")
	self.CurrentSpotIndex = 0
end

function JobCheckSpots:Tick()
	self:CheckSpot()
	self:CheckSpot()
	self:CheckSpot()
end

function JobCheckSpots:CheckSpot()
	local spotId = TVT.sa_getSpot(self.CurrentSpotIndex)
	if ((spotId == -2) or (spotId == -8)) then
		self.Status = JOB_STATUS_DONE
		return
	end	

	local spot = TVT.GetContract(spotId)
	
	if (spot.IsAvailableToSign() == 1) then
		--debugMsg("Signable")
		local player = _G["globalPlayer"]
		self.AdAgencyTask.SpotsInAgency[self.CurrentSpotIndex] = spot
		player.Stats:AddSpot(spot)	
	end
	
	self.CurrentSpotIndex = self.CurrentSpotIndex + 1
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
AppraiseSpots = AIJob:new{
	CurrentSpotIndex = 0;
	AdAgencyTask = nil
}

function AppraiseSpots:Prepare(pParams)
	debugMsg("Bewerte/Vergleiche Werbeverträge")
	self.CurrentSpotIndex = 0
end

function AppraiseSpots:Tick()
	self:AppraiseCurrentSpot()
	self:AppraiseCurrentSpot()
end

function AppraiseSpots:AppraiseCurrentSpot()
	local spot = self.AdAgencyTask.SpotsInAgency[self.CurrentSpotIndex]
	if (spot ~= nil) then
		self:AppraiseSpot(spot)
		self.CurrentSpotIndex = self.CurrentSpotIndex + 1
	else
		self.Status = JOB_STATUS_DONE		
	end
end

function AppraiseSpots:AppraiseSpot(spot)
	--return nil --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	--debugMsg("AppraiseSpot")
	--debugMsg("===================")
	local player = _G["globalPlayer"]
	local stats = player.Stats
	local score = -1	
	
	if (spot.GetMinAudience() > stats.Audience.MaxValue) then
		--spot.Appraisal = -2
		--debugMsg("zu viele Zuschauer verlangt! " .. spot.Audience .. " / " .. stats.Audience.MaxValue)
		return
	end
	
	--debugMsg("spot.SpotProfit: " .. spot.SpotProfit .. " ; spot.SpotToSend: " .. spot.SpotToSend)
	local profitPerSpot = spot.GetProfit() / spot.GetSpotCount()
	--debugMsg("profitPerSpot: " .. profitPerSpot .. " ; stats.SpotProfitPerSpotAcceptable.AverageValue: " .. stats.SpotProfitPerSpotAcceptable.AverageValue)
	local financePower = profitPerSpot / stats.SpotProfitPerSpotAcceptable.AverageValue	
	--debugMsg("financePower1: " .. financePower)
	financePower = CutFactor(financePower, 0.2, 2)
	--debugMsg("financePower: " .. financePower)

	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen	
	local audienceFactor = stats.Audience.AverageValue / spot.GetMinAudience()
	audienceFactor = CutFactor(audienceFactor, 0.3, 2)
	--debugMsg("audienceFactor: " .. audienceFactor .. " ; stats.Audience.AverageValue: " .. stats.Audience.AverageValue .. " ; spot.Audience:" .. spot.Audience)

	-- 2 = Risiko und Strafe sind im Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactor = stats.SpotPenalty.AverageValue / spot.GetPenalty()
	riskFactor = CutFactor(riskFactor, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)
	--debugMsg("riskFactor: " .. riskFactor .. " ; SpotPenalty: " .. stats.SpotPenalty.AverageValue .. " ; SpotPenalty:" .. spot.SpotPenalty)
		
	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactor = spot.GetDaysToFinish() / spot.GetSpotCount()
	pressureFactor = CutFactor(pressureFactor, 0.2, 2)
	--debugMsg("pressureFactor: " .. pressureFactor .. " ; SpotMaxDays: " .. spot.SpotMaxDays .. " ; SpotToSend:" .. spot.SpotToSend)
		
	spot.SetAttractiveness(audienceFactor * riskFactor * pressureFactor)
	--debugMsg("Spot-Attractiveness: ===== " .. spot.GetAttractiveness() .. " ===== ; financePower: " .. financePower .. " ; audienceFactor: " .. audienceFactor .. " ; riskFactor: " .. riskFactor .. " ; pressureFactor: " .. pressureFactor)
	
	--debugMsg("===================")
	
	--financeBase
	
	-- Je höher der Gewinn desto besser
	-- Je höher die Strafe desto schlechter
	-- Je geringer die benötigten Zuschauer desto besser
	-- Je weniger Spots desto besser
	-- Je mehr Zeit desto besser
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SignRequisitedContracts = AIJob:new{
	CurrentSpotIndex = 0;
	AdAgencyTask = nil
}

function SignRequisitedContracts:Prepare(pParams)
	debugMsg("Unterschreibe benötigte Werbeverträge")
	self.CurrentSpotIndex = 0
	
	self.Player = _G["globalPlayer"]
	self.SpotRequisitions = self.Player:GetRequisitionsByTaskId(_G["TASK_ADAGENCY"])	
end

function SignRequisitedContracts:Tick()	
	--debugMsg("SignRequisitedContracts")
	
	--Sortieren
	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end	
	table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)	
	
	for k,requisition in pairs(self.SpotRequisitions) do
		local neededSpotCount = requisition.Count
		
		local guessedAudience = AITools:GuessedAudienceForLevel(requisition.Level)
		local minGuessedAudience = (guessedAudience * 0.8)
				
		local signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.8))
		if (signedContracts == 0) then		
			signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))
			if (signedContracts == 0) then
				guessedAudience = guessedAudience + 5000 -- Die 5000 sind einfach ein Erfahrungswert, denn es gibt kaum kleinere Werbeverträge... die Sinnhaftigkeit sollte nochmal geprüft werden								
				signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))					
				if (signedContracts == 0) then
					guessedAudience = guessedAudience + 5000 -- Die 5000 sind einfach ein Erfahrungswert, denn es gibt kaum kleinere Werbeverträge... die Sinnhaftigkeit sollte nochmal geprüft werden
					signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))									
				end
			end
		end
	end	
	
	self.Status = JOB_STATUS_DONE
end

function SignRequisitedContracts:GetMinGuessedAudience(guessedAudience, minFactor)
	if (guessedAudience < 10000) then
		return 0
	else
		return (guessedAudience * minFactor)
	end
end

function SignRequisitedContracts:SignMatchingContracts(requisition, guessedAudience, minguessedAudience)
	local signed = 0
	local buyedContracts = {}
	
	for key, value in pairs(self.AdAgencyTask.SpotsInAgency) do
		if MY.ProgrammeCollection.GetContractCount() >= 8 then break end
	
		local minAudience = value.GetMinAudience()
	
		if ((minAudience < guessedAudience) and (minAudience > minguessedAudience)) then
			--Passender Spot... also kaufen
			debugMsg("Schließe Werbevertrag: " .. value.contractBase.title .. " (" .. value.GetID() .. ") weil benötigt. Level: " .. requisition.Level)
			TVT.sa_doBuySpot(value.GetID())
			requisition:UseThisContract(value)
			table.insert(buyedContracts, value)			
			signed = signed + 1			
			--neededSpotCount = neededSpotCount - value.GetSpotCount()
		end
		
		--if (neededSpotCount <= 0) then
		--	self.Player:RemoveRequisition(requisition)
		--else
		--	requisition.Count = neededSpotCount
		--end		
	end
	
	if (table.count(buyedContracts) > 0) then
		debugMsg("Entferne " .. table.count(buyedContracts) .. " abgeschlossene Werbeverträge aus der Shop-Liste.")
		table.removeCollection(self.AdAgencyTask.SpotsInAgency, buyedContracts)
	end
	
	return signed
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SignContracts = AIJob:new{
	CurrentSpotIndex = 0;
	AdAgencyTask = nil
}
--self.SpotRequisition = self.Player:GetRequisitionsByOwner(_G["TASK_SCHEDULE"])
function SignContracts:Prepare(pParams)
	debugMsg("Unterschreibe lukrative Werbeverträge")
	self.CurrentSpotIndex = 0
end

function SignContracts:Tick()	
	--debugMsg("SignContracts")
	
	--Sortieren
	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end	
	table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)
	
	local openSpots = self:GetCommonRequisition()
	--debugMsg("openSpots: " .. openSpots)
	if (openSpots > 0) then
		for key, value in pairs(self.AdAgencyTask.SpotsInAgency) do
			if MY.ProgrammeCollection.GetContractCount() >= 8 then break end
			if (openSpots > 0) then
				openSpots = openSpots - value.GetSpotCount()
				debugMsg("Schließe Werbevertrag: " .. value.contractBase.title .. " (" .. value.GetID() .. ")")
				TVT.sa_doBuySpot(value.GetID())				
			end
		end	
	end
	
	self.Status = JOB_STATUS_DONE
end

function SignContracts:GetCommonRequisition()
	local unsendedSpots = 0

	for i = 0, MY.ProgrammeCollection.GetContractCount() - 1 do
		local contract = MY.ProgrammeCollection.GetContractFromList(i)
		local count = MY.ProgrammePlan.GetContractBroadcastCount(contract.id, 1, 0)
		--debugMsg("GetMatchingSpotList: " .. contract.title .. " - " .. count)			
		
		if (count < contract.GetSpotCount()) then
			unsendedSpots = unsendedSpots + (contract.GetSpotCount() - count)
		end
	end
	--debugMsg("unsendedSpots: " .. unsendedSpots)
	if (unsendedSpots > 8) then
		return 0
	else
		return 8 - unsendedSpots
	end
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<