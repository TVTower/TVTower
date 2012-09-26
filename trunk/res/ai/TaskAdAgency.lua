-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskAdAgency = AITask:new{	
	TargetRoom = TVT.ROOM_ADAGENCY;
	SpotsInAgency = nil;
	BudgetWeigth = 1 --TODO: Nach dem TEST auf 0 REDUZIEREN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	-- zu Senden
	-- Strafe
	-- Zuschauer
	-- Zeit
}

function TaskAdAgency:typename()
	return "TaskAdAgency"
end

function TaskAdAgency:Activate()
	debugMsg("Starte Task 'TaskAdAgency'")
	-- Was getan werden soll:
	self.CheckSpots = JobCheckSpots:new()
	self.CheckSpots.AdAgencyTask = self
	
	self.AppraiseSpots = AppraiseSpots:new()
	self.AppraiseSpots.AdAgencyTask = self
	
	self.SignContracts = SignContracts:new()
	self.SignContracts.AdAgencyTask = self	
	
	self.SpotsInAgency = {}
end

function TaskAdAgency:GetNextJobInTargetRoom()
	if (self.CheckSpots.Status ~= JOB_STATUS_DONE) then
		return self.CheckSpots
	elseif (self.AppraiseSpots.Status ~= JOB_STATUS_DONE) then
		return self.AppraiseSpots
	elseif (self.SignContracts.Status ~= JOB_STATUS_DONE) then	
		return self.SignContracts
	end
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
end

function JobCheckSpots:CheckSpot()

	local spotId = TVT.sa_getSpot(self.CurrentSpotIndex)
	if (spotId == -2) then
		self.Status = JOB_STATUS_DONE
		return
	end	

	local spot = Spot:new()
	spot:Initialize(spotId)

	local player = _G["globalPlayer"]
	self.AdAgencyTask.SpotsInAgency[self.CurrentSpotIndex] = spot
	player.Stats:AddSpot(spot)
	self.CurrentSpotIndex = self.CurrentSpotIndex + 1
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
AppraiseSpots = AIJob:new{
	CurrentSpotIndex = 0;
	AdAgencyTask = nil
}

function AppraiseSpots:Prepare(pParams)
	debugMsg("Bewerte Werbespotangebote")
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
	
	if (spot:GetMinAudience() > stats.Audience.MaxValue) then
		--spot.Appraisal = -2
		--debugMsg("zu viele Zuschauer verlangt! " .. spot.Audience .. " / " .. stats.Audience.MaxValue)
		return
	end
	
	--debugMsg("spot.SpotProfit: " .. spot.SpotProfit .. " ; spot.SpotToSend: " .. spot.SpotToSend)
	local profitPerSpot = spot:GetProfit() / spot:GetSpotCount()
	--debugMsg("profitPerSpot: " .. profitPerSpot .. " ; stats.SpotProfitPerSpotAcceptable.AverageValue: " .. stats.SpotProfitPerSpotAcceptable.AverageValue)
	local financePower = profitPerSpot / stats.SpotProfitPerSpotAcceptable.AverageValue	
	--debugMsg("financePower1: " .. financePower)
	financePower = CutFactor(financePower, 0.2, 2)
	--debugMsg("financePower: " .. financePower)

	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen	
	local audienceFactor = stats.Audience.AverageValue / spot:GetMinAudience()
	audienceFactor = CutFactor(audienceFactor, 0.3, 2)
	--debugMsg("audienceFactor: " .. audienceFactor .. " ; stats.Audience.AverageValue: " .. stats.Audience.AverageValue .. " ; spot.Audience:" .. spot.Audience)

	-- 2 = Risiko und Strafe sind im Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactor = stats.SpotPenalty.AverageValue / spot:GetPenalty()
	riskFactor = CutFactor(riskFactor, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)
	--debugMsg("riskFactor: " .. riskFactor .. " ; SpotPenalty: " .. stats.SpotPenalty.AverageValue .. " ; SpotPenalty:" .. spot.SpotPenalty)
		
	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactor = spot:GetDaysToFinish() / spot:GetSpotCount()
	pressureFactor = CutFactor(pressureFactor, 0.2, 2)
	--debugMsg("pressureFactor: " .. pressureFactor .. " ; SpotMaxDays: " .. spot.SpotMaxDays .. " ; SpotToSend:" .. spot.SpotToSend)
		
	spot.Attractiveness = audienceFactor * riskFactor * pressureFactor
	debugMsg("Spot-Attractiveness: ===== " .. spot.Attractiveness .. " ===== ; financePower: " .. financePower .. " ; audienceFactor: " .. audienceFactor .. " ; riskFactor: " .. riskFactor .. " ; pressureFactor: " .. pressureFactor)
	
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
SignContracts = AIJob:new{
	CurrentSpotIndex = 0;
	AdAgencyTask = nil
}

function SignContracts:Prepare(pParams)
	debugMsg("Unterschreibe Werbeverträge")
	self.CurrentSpotIndex = 0
end

function SignContracts:Tick()	
	debugMsg("SignContracts")
	
	--Sortieren
	local sortMethod = function(a, b)
		return a.Attractiveness > b.Attractiveness
	end	
	table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)
	
	
	for key, value in pairs(self.AdAgencyTask.SpotsInAgency) do
		--debugMsg(key .. " : " .. value.Attractiveness)
	end	
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<