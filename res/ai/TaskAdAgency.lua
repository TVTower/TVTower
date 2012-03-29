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
	self.MoviePurchaseJob = JobCheckSpots:new()
end

function TaskAdAgency:GetNextJobInTargetRoom()
	if (self.MoviePurchaseJob.Status ~= JOB_STATUS_DONE) then
		return self.MoviePurchaseJob
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobCheckSpots = AIJob:new{
	CurrentSpotIndex = 0;
}

function JobCheckSpots:Prepare()
	self.CurrentSpotIndex = 0
end

function JobCheckSpots:Tick()
	local spotId = TVT.sa_getSpot(self.CurrentSpotIndex)
	local spot = Spot:new()
	spot.Initialize(spotId)
	
	self.CurrentSpotIndex++;
end

function JobCheckSpots:AppraiseSpot(spot)
	MinAudience
	AverageAudience
	MaxAudience
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Spot = SLFDataObject:new{
	self.Id = -1;
	self.Audience = -1;
	self.SpotToSend = -1;
	self.SpotMaxDays = -1;
	self.SpotProfit = -1;
	self.SpotPenalty = -1;
	self.SpotTargetgroup = "";
}

function Spot:Initialize(spotId)
	self.Id = spotId
	self.Audience = TVT.SpotAudience(spotId)
	self.SpotToSend = TVT.SpotToSend(spotId)
	self.SpotMaxDays = TVT.SpotMaxDays(spotId)
	self.SpotProfit = TVT.SpotProfit(spotId)
	self.SpotPenalty = TVT.SpotPenalty(spotId)
	self.SpotTargetgroup = TVT.SpotTargetgroup(spotId)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<