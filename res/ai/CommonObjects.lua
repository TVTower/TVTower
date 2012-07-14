-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Movie = SLFDataObject:new{
	Id = -1;
	Sequels = -1;
	Genre = -1;
	Length = -1;
	XRated = -1;
	Profit = -1;
	Speed = -1;
	Review = -1;
	Topicality = -1;
	Price = -1;
	PricePerBlock = -1;
	Quality = -1;
	ProgramType = nil;
	Attractiveness = -1;
	Level = -1;
}

function Movie:Initialize(movieId)
	-- ronny: hier ueberlegen, ob nicht besser
	-- das film-objekt selbst ausreicht und dann halt movie.GetXXX
	self.Id = movieId
	m = DB.GetProgramme(movieId)
	self.Sequels = m.GetEpisodeCount()
	self.Genre = m.GetGenre()
	self.Length = m.GetBlocks()
	self.XRated = m.GetXRated()
	self.Profit = m.GetOutcome()
	self.Speed = m.getSpeed()
	self.Review = m.getReview()
	self.Topicality = m.getTopicality()
	self.Price = m.getPrice()

	self.Quality = m.getBaseAudienceQuote(movieId)
	--self.Quality = (0.3 * self.Profit + 0.15 * self.Speed + 0.25 * self.Review + 0.3 * self.Topicality)
	self.PricePerBlock = self.Price / self.Length

	-- ronny: hier gaenge auch: if (m.isMovie()) then
	-- und bei speicherung des objektes auch in anderen Scriptbereichen...
	if (self.Sequels > 0) then
		self.ProgramType = PROGRAM_SERIES
	else
		self.ProgramType = PROGRAM_MOVIE
	end

	if self.Quality > 20 then
		self.Level = 5
	elseif self.Quality > 15 then
		self.Level = 4
	elseif self.Quality > 10 then
		self.Level = 3
	elseif self.Quality > 5 then
		self.Level = 2
	else
		self.Level = 1
	end

	--debugMsg("Movie-Quality: " .. self.Quality .. " - ProgramType: " .. self.ProgramType .. " - Genre: " .. self.Genre)
end

function Movie:CheckConditions(maxPrice, minQuality)
	if (self.Price > maxPrice) then	return false end
	if (minQuality ~= nil) then
		if (self.Quality < minQuality) then return false end
	end
	return true
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
	Attractiveness = -1;

	Acuteness = -1; --Dringlichkeit
	AcutenessVersionDate = -1;
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

	self.SpotsToBroadcast = -1
	self.DaysLeft = -1
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