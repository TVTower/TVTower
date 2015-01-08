-- File: TaskMovieDistributor
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskMovieDistributor"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.MoviesAtDistributor = nil
	c.MoviesAtAuctioneer = nil
	c.NiveauChecked = false
	c.MovieCount = 0
	c.CheckMode = 0
	c.BudgetWeigth = 7
	c.BasePriority = 8
	c.MovieList = nil
	c.TargetRoom = TVT.ROOM_MOVIEAGENCY
	c.CheckMoviesJob = nil
	c.AppraiseMovies = nil
	c.CurrentBargainBudget = 0
	c.NeededInvestmentBudget = 150000
	c.InvestmentPriority = 2	
end)

function TaskMovieDistributor:typename()
	return "TaskMovieDistributor"
end

function TaskMovieDistributor:Activate()
	debugMsg(">>> Starte Task 'TaskMovieDistributor'")

	-- Was getan werden soll:
	self.CheckMoviesJob = JobCheckMovies()
	self.CheckMoviesJob.MovieDistributorTask = self

	self.AppraiseMovies = JobAppraiseMovies()
	self.AppraiseMovies.MovieDistributorTask = self

	self.BuyMovies = JobBuyMovies()
	self.BuyMovies.MovieDistributorTask = self
	
	self.BidAuctions = JobBidAuctions()
	self.BidAuctions.MovieDistributorTask = self

	self.MoviesAtDistributor = {}
	self.MoviesAtAuctioneer = {}
end

function TaskMovieDistributor:GetNextJobInTargetRoom()
	if (self.CheckMoviesJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckMoviesJob
	elseif (self.AppraiseMovies.Status ~= JOB_STATUS_DONE) then
		return self.AppraiseMovies
	--elseif (self.BuyMovies.Status ~= JOB_STATUS_DONE) then
		--return self.BuyMovies
	elseif (self.BidAuctions.Status ~= JOB_STATUS_DONE) then
		return self.BidAuctions		
	end

	self:SetWait()
end

function TaskMovieDistributor:BudgetSetup()
	self.CurrentBargainBudget = self.BudgetWholeDay / 2 -- Tagesbudget für gute Angebote ohne konkreten Bedarf
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobCheckMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentMovieIndex = 0
	c.CurrentAuctionIndex = 0
	c.MovieDistributorTask = nil
	c.AllMoviesChecked = false
	c.AllAuctionsChecked = false
end)

function JobCheckMovies:typename()
	return "JobCheckMovies"
end

function JobCheckMovies:Prepare(pParams)
	debugMsg("Schaue Filmangebot an")
	self.CurrentMovieIndex = 0
end

function JobCheckMovies:Tick()
	while self.Status ~= JOB_STATUS_DONE and not self.AllMoviesChecked do
		self:CheckMovie()		
	end
	
	while self.Status ~= JOB_STATUS_DONE and not self.AllAuctionsChecked do
		self:CheckAuction()
	end		

	self.Status = JOB_STATUS_DONE
end

function JobCheckMovies:CheckMovie()
	local response = TVT.md_getProgrammeLicence(self.CurrentMovieIndex)
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		self.AllMoviesChecked = true
		return
	end

	local licence = TVT.convertToProgrammeLicence(response.data)	
	self.MovieDistributorTask.MoviesAtDistributor[self.CurrentMovieIndex] = licence

	local player = _G["globalPlayer"]
	player.Stats:AddMovie(licence)

	self.CurrentMovieIndex = self.CurrentMovieIndex + 1
end

function JobCheckMovies:CheckAuction()
	local response = TVT.md_getAuctionProgrammeLicence(self.CurrentAuctionIndex)
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		self.AllAuctionsChecked = true
		return
	end

	local licence = TVT.convertToProgrammeLicence(response.data)
	self.MovieDistributorTask.MoviesAtAuctioneer[self.CurrentAuctionIndex] = licence
	self.CurrentAuctionIndex = self.CurrentAuctionIndex + 1
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobAppraiseMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentMovieIndex = 0
	c.CurrentAuctionIndex = 0
	c.MovieDistributorTask = nil

	c.MovieMaxPrice = -1
	c.PrimetimeMovieMinQuality = -1
	c.DayMovieMinQuality = -1

	c.SeriesMaxPrice = -1
	c.PrimetimeSeriesMinQuality = -1
	c.DaySeriesMinQuality = -1
	
	c.AllMoviesChecked = false
	c.AllAuctionsChecked = false	
end)

function JobAppraiseMovies:typename()
	return "JobAppraiseMovies"
end

function JobAppraiseMovies:Prepare(pParams)
	debugMsg("Bewerte/Vergleiche Filme")
	self.CurrentMovieIndex = 0
	self.CurrentAuctionIndex = 0
	self:AdjustMovieNiveau()
end

function JobAppraiseMovies:Tick()
	while self.Status ~= JOB_STATUS_DONE and not self.AllMoviesChecked do
		self:AppraiseCurrentMovie()
	end
	
	while self.Status ~= JOB_STATUS_DONE and not self.AllAuctionsChecked do
		self:AppraiseCurrentAuction()
	end
	
	self.Status = JOB_STATUS_DONE
end

function JobAppraiseMovies:AdjustMovieNiveau()
	local player = _G["globalPlayer"]
	local stats = player.Stats
	local movieBudget = self.MovieDistributorTask.BudgetWholeDay
	local maxPrice = movieBudget / 2;

	local maxQualityMovies = stats.MovieQualityAcceptable.MaxValue;
	local minQualityMovies = stats.MovieQualityAcceptable.MinValue;
	local maxQualitySeries = stats.SeriesQualityAcceptable.MaxValue;
	local minQualitySeries = stats.SeriesQualityAcceptable.MinValue;

	self.MovieMaxPrice = maxPrice
	self.SeriesMaxPrice = maxPrice

	local ScopeMovies = maxQualityMovies - minQualityMovies
	self.PrimetimeMovieMinQuality = math.round(minQualityMovies + (ScopeMovies * 0.75))
	self.DayMovieMinQuality = math.round(minQualityMovies + (ScopeMovies * 0.4))

	local ScopeSeries = maxQualitySeries - minQualitySeries
	self.PrimetimeSeriesMinQuality = math.round(minQualitySeries + (ScopeSeries * 0.75))
	self.DaySeriesMinQuality = math.round(minQualitySeries + (ScopeSeries * 0.4))
end

function JobAppraiseMovies:AppraiseCurrentMovie()
	local movie = self.MovieDistributorTask.MoviesAtDistributor[self.CurrentMovieIndex]
	if (movie ~= nil) then
		self:AppraiseMovie(movie)
		self.CurrentMovieIndex = self.CurrentMovieIndex + 1
	else
		self.AllMoviesChecked = true
	end
end

function JobAppraiseMovies:AppraiseCurrentAuction()
	local movie = self.MovieDistributorTask.MoviesAtAuctioneer[self.CurrentAuctionIndex]
	if (movie ~= nil) then
		self:AppraiseMovie(movie)
		self.CurrentAuctionIndex = self.CurrentAuctionIndex + 1
	else
		self.AllAuctionsChecked = true
	end
end

function JobAppraiseMovies:AppraiseMovie(licence)
	local player = _G["globalPlayer"]
	local stats = player.Stats
	local pricePerBlockStats = nil
	local qualityStats = nil
--RON
--TVT.PrintOut("RON: AppraiseMovie")
	--Allgemeine Minimalvorraussetzungen erfüllt?
	if (licence.IsMovie()) then
		if (CheckMovieBuyConditions(licence, self.MovieMaxPrice, self.DayMovieMinQuality)) then
			pricePerBlockStats = stats.MoviePricePerBlockAcceptable
			qualityStats = stats.MovieQualityAcceptable
		else
			return
		end
	else
		if (CheckMovieBuyConditions(licence, self.SeriesMaxPrice, self.DaySeriesMinQuality)) then
			pricePerBlockStats = stats.SeriesPricePerBlockAcceptable
			qualityStats = stats.SeriesQualityAcceptable
		else
			return
		end
	end

	-- Je günstiger desto besser
	local financeFactor = licence:GetPricePerBlock() / pricePerBlockStats.AverageValue
	financeFactor = CutFactor(financeFactor, 0.2, 2)
	--debugMsg("licence.GetPricePerBlock: " .. licence.GetPricePerBlock() .. " ; pricePerBlockStats.AverageValue: " .. pricePerBlockStats.AverageValue)

	-- Je qualitativ hochwertiger desto besser	
	local qualityFactor = licence.GetQuality(0) / qualityStats.AverageValue
	qualityFactor = CutFactor(qualityFactor, 0.2, 2)
	--debugMsg("licence.Quality: " .. licence.Quality .. " ; qualityStats.AverageValue: " .. qualityStats.AverageValue)
	licence.SetAttractiveness(financeFactor * qualityFactor)
	--debugMsg("MovieLicence-Attractiveness: ===== " .. licence.GetAttractiveness() .. " ===== ; financeFactor: " .. financeFactor .. " ; qualityFactor: " .. qualityFactor)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBuyMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.MovieDistributorTask = nil
end)

function JobBuyMovies:typename()
	return "JobBuyMovies"
end

function JobBuyMovies:Prepare(pParams)
	debugMsg("Kaufe Filme")

	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end
	table.sort(self.MovieDistributorTask.MoviesAtDistributor, sortMethod)
end

function JobBuyMovies:Tick()
	local movies = self.MovieDistributorTask.MoviesAtDistributor

	--TODO: Prüfen wie viele Filme überhaupt gebraucht werden

	for k,v in pairs(movies) do
		if (v:GetPrice() <= self.MovieDistributorTask.CurrentBudget) then
			if (v:GetPrice() <= self.MovieDistributorTask.CurrentBargainBudget) then -- Tagesbudget für gute Angebote ohne konkreten Bedarf
				if (v.GetAttractiveness() > 1) then
					--debugMsg("Kaufe Film: " .. v.GetId() .. " - Attraktivität: ".. v.GetAttractiveness() .. " - Preis: " .. v:GetPrice() .. " - Qualität: " .. v.GetQuality(0))
					debugMsg("Kaufe Film: " .. v.GetTitle() .. " (" .. v.GetId() .. ") - Preis: " .. v:GetPrice())
					TVT.addToLog("Kaufe Film: " .. v.GetTitle() .. " (" .. v.GetId() .. ") - Preis: " .. v:GetPrice())
					TVT.md_doBuyProgrammeLicence(v.GetId())
					
					self.MovieDistributorTask:PayFromBudget(v:GetPrice())
					self.MovieDistributorTask.CurrentBargainBudget = self.MovieDistributorTask.CurrentBargainBudget - v:GetPrice()
				end
			end
		end
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBidAuctions"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.MovieDistributorTask = nil
end)

function JobBidAuctions:typename()
	return "JobBuyMovies"
end

function JobBidAuctions:Prepare(pParams)
	debugMsg("Biete auf Auktionen")

	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end
	table.sort(self.MovieDistributorTask.MoviesAtAuctioneer, sortMethod)
end

function JobBidAuctions:Tick()
	local movies = self.MovieDistributorTask.MoviesAtAuctioneer

	--TODO: Prüfen wie viele Filme überhaupt gebraucht werden

	for k,v in pairs(movies) do
		if (v:GetPrice() <= self.MovieDistributorTask.CurrentBudget) then
			if (v:GetPrice() <= self.MovieDistributorTask.CurrentBargainBudget) then -- Tagesbudget für gute Angebote ohne konkreten Bedarf				
				if (v.GetAttractiveness() > 1) then
					--debugMsg("Kaufe Film: " .. v.GetId() .. " - Attraktivität: ".. v.GetAttractiveness() .. " - Preis: " .. v:GetPrice() .. " - Qualität: " .. v.GetQuality(0))
					debugMsg("Biete auf Auktion: " .. v.GetTitle() .. " (" .. v.GetId() .. ") - Preis: " .. v:GetPrice())
					TVT.addToLog("Biete auf Auktion: " .. v.GetTitle() .. " (" .. v.GetId() .. ") - Preis: " .. v:GetPrice())
					TVT.md_doBidAuctionProgrammeLicence(v.GetId())
					
					self.MovieDistributorTask:PayFromBudget(v:GetPrice())
					self.MovieDistributorTask.CurrentBargainBudget = self.MovieDistributorTask.CurrentBargainBudget - v:GetPrice()
				end
			end
		end
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<