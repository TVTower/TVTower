-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper

function CheckMovieBuyConditions(movie, maxPrice, minQuality)
	if (movie.GetPrice() > maxPrice) then return false end	
	if (minQuality ~= nil) then
		if (movie.getBaseAudienceQuote() < minQuality) then return false end
	end
	return true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Spot = SLFDataObject:new{
	Id = -1;
	Object = nil;
	
	FinanceWeight = -1;
	Pressure = -1;
	SpotsToBroadcast = -1;
	DaysLeft = -1;
	
	Acuteness = -1; --Dringlichkeit
	AcutenessVersionDate = -1;	
	
	Attractiveness = -1;
}

function Spot:Initialize(spotId)
	self.Id = spotId
	self.Object = TVT.getContract(spotId)
end

function Spot:GetMinAudience()
	return self.Object.GetMinAudience()
end

function Spot:GetSpotCount()
	return self.Object.GetSpotCount()
end

function Spot:GetDaysToFinish()
	return self.Object.GetDaysToFinish()
end

function Spot:GetProfit()
	return self.Object.GetProfit()
end

function Spot:GetPenalty()
	return self.Object.GetPenalty()
end

function Spot:GetTargetGroup()
	return self.Object.GetTargetGroup()
end

function Spot:GetFinanceWeight()
	if (self.FinanceWeight == -1) then
		self.FinanceWeight = (self:GetProfit() + self:GetPenalty()) / self:GetSpotCount()
	end
	return self.FinanceWeight
end

function Spot:GetPressure()
	if (self.Pressure == -1) then
		self.Pressure = self:GetSpotCount() / self:GetDaysToFinish() * self:GetDaysToFinish()
	end
	return self.Pressure
end

function Spot:GetAcuteness()
	local day = TVT.getDay()

	if (self.AcutenessVersionDate < day) then
		local spotsBeenSent = TVT.of_getSpotBeenSent(self.Id)
		self.SpotsToBroadcast = self.SpotToSend - spotsBeenSent
		self.DaysLeft = TVT.of_getSpotDaysLeft(self.Id)

		self.Acuteness = self.SpotsToBroadcast / self.DaysLeft * self.DaysLeft * 100
		self.AcutenessVersionDate = day
	end

	return self.Acuteness
end

function Spot:MinBlocksToday()
	local acuteness = self:GetAcuteness()

	if (acuteness >= 100) then
		return math.round(self.SpotsToBroadcast / self.DaysLeft)
	elseif (acuteness >= 70) then
		return 1
	end
end

function Spot:OptimalBlocksToday()
	local acuteness = self:GetAcuteness()

	local optimumCount = math.round(self.SpotsToBroadcast / self.DaysLeft)

	if (acuteness >= 100) and (self.SpotsToBroadcast > optimumCount) then
		optimumCount = optimumCount + 1
	end

	if (acuteness >= 100) then
		return math.round(self.SpotsToBroadcast / self.DaysLeft)
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<