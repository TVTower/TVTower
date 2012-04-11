-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskAdAgency = AITask:new{
	TargetRoom = TVT.ROOM_ADAGENCY;
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
	self.AdAgencyJob = JobCheckSpots:new()
end

function TaskAdAgency:GetNextJobInTargetRoom()
	if (self.AdAgencyJob.Status ~= JOB_STATUS_DONE) then
		return self.AdAgencyJob
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobCheckSpots = AIJob:new{
	CurrentSpotIndex = 0;
}

function JobCheckSpots:Prepare()
	--debugMsg("CheckSpot Prepare")
	self.CurrentSpotIndex = 0
end

function JobCheckSpots:Tick()
	--debugMsg("CheckSpot Tick")
	--debugMsg("CheckSpot: " .. self.CurrentSpotIndex)
	local spotId = TVT.sa_getSpot(self.CurrentSpotIndex)
	if (spotId == -2) then
		self.Status = JOB_STATUS_DONE
	end	
	--debugMsg("CheckSpot Tick - SpotId: " .. spotId)
	local spot = Spot:new()
	spot:Initialize(spotId)
	self:AppraiseSpot(spot)
	
	self.CurrentSpotIndex = self.CurrentSpotIndex + 1
end

function JobCheckSpots:AppraiseSpot(spot)
--[[
	local stats = globalPlayer.Stats
	local score = -1
	
	if (spot.Audience > stats.MaxAudience) then
		spot.Appraisal = -2
		return
	end
	
	local financeBase = spot.SpotProfit / self.SpotToSend

	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen	
	local audienceFactor = stats.AverageAudience / spot.Audience	
	audienceFactor = CutFactor(audienceFactor, 0.3, 2)

	-- 2 = Risiko und Strafe sind Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactor = spot.SpotProfit / spot.SpotPenalty
	riskFactor = CutFactor(riskFactor, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)	
		
	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactor = self.SpotMaxDays / self.SpotToSend
	pressureFactor = CutFactor(pressureFactor, 0.3, 2)
]]--
	
	
	
	
	--financeBase
	
	-- Je höher der Gewinn desto besser
	-- Je höher die Strafe desto schlechter
	-- Je geringer die benötigten Zuschauer desto besser
	-- Je weniger Spots desto besser
	-- Je mehr Zeit desto besser
	
	--self.Attractiveness = 
	
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Spot = SLFDataObject:new{
	Id = -1;
	Audience = -1;
	SpotToSend = -1;
	SpotMaxDays = -1;
	SpotProfit = -1;
	SpotPenalty = -1;
	SpotTargetgroup = "";
	
	Appraisal = -1;
	FinanceWeight = -1;
}

function Spot:Initialize(spotId)
	self.Id = spotId
	self.Audience = TVT.SpotAudience(spotId)
	self.SpotToSend = TVT.SpotToSend(spotId)
	self.SpotMaxDays = TVT.SpotMaxDays(spotId)
	self.SpotProfit = TVT.SpotProfit(spotId)
	self.SpotPenalty = TVT.SpotPenalty(spotId)
	self.SpotTargetgroup = TVT.SpotTargetgroup(spotId)
	
	self.FinanceWeight = (self.SpotProfit + self.SpotPenalty) / self.SpotToSend
	self.Pressure = self.SpotToSend / self.SpotMaxDays * self.SpotMaxDays
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<