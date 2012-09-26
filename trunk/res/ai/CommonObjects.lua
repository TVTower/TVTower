-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper
Movie = SLFDataObject:new{
	Id = -1;
	PricePerBlock = -1;
	Quality = -1;
	Attractiveness = -1; --Dieser Wert wird von außen gesetzt... und hängt von den Bewertungskriterien des Spielers ab
	Object = nil;
}

function Movie:Initialize(movieId)
	self.Id = movieId	
	self.Object = TVT.GetProgramme(movieId)
	
	--debugMsg("Movie-Quality: " .. self.GetQuality() .. " - ProgramType: " .. self.ProgramType .. " - Genre: " .. self.Genre)
end

function Movie:GetSequels()
	return self.Object.GetEpisodeCount()
end

function Movie:GetGenre()
	return self.Object.GetGenre()
end

function Movie:GetLength()
	return self.Object.GetBlocks()
end

function Movie:GetXRated()
	return self.Object.GetXRated()
end

function Movie:GetProfit()
	return self.Object.GetOutcome()
end

function Movie:GetSpeed()
	return self.Object.getSpeed()
end

function Movie:GetReview()
	return self.Object.getReview()
end

function Movie:GetTopicality()
	return self.Object.getTopicality()
end

function Movie:GetPrice()
	return self.Object.getPrice()
end

function Movie:IsMovie()
	return self.Object.isMovie()
end

function Movie:GetQuality()
	if (self.Quality == -1) then
		self.Quality = self.Object.getBaseAudienceQuote(self.Id)
	end
	return self.Quality
end

function Movie:GetPricePerBlock()
	if (self.PricePerBlock == -1) then
		self.PricePerBlock = self:GetPrice() / self:GetLength()
	end
	return self.PricePerBlock
end

function Movie:GetLevel()
	if (self.Level == -1) then
		local quality = self:GetQuality()
		--debugMsg("GetQuality: " .. quality)
		if quality > 20 then
			self.Level = 5
		elseif quality > 15 then
			self.Level = 4
		elseif quality > 10 then
			self.Level = 3
		elseif quality > 5 then
			self.Level = 2
		else
			self.Level = 1
		end
	end
	return self.Level
end

function Movie:CheckConditions(maxPrice, minQuality)
	if (self:GetPrice() > maxPrice) then return false end
	if (minQuality ~= nil) then
		if (self:GetQuality() < minQuality) then return false end
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