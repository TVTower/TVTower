PROGRAM_MOVIE		= "movie"
PROGRAM_SERIES		= "series"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskMovieDistributor = AITask:new{
	MoviesAtDistributor = nil;
	NiveauChecked = false;
	MovieCount = 0;
	CheckMode = 0;
	BudgetWeigth = 7;
	MovieList = nil;
	TargetRoom = TVT.ROOM_MOVIEAGENCY;
	CheckMoviesJob = nil;
	AppraiseMovies = nil;
	CurrentBargainBudget = 0
}

function TaskMovieDistributor:typename()
	return "TaskMovieDistributor"
end

function TaskMovieDistributor:Activate()
	debugMsg("Starte Task 'TaskAdAgency'")
	
	-- Was getan werden soll:
	self.CheckMoviesJob = JobCheckMovies:new()
	self.CheckMoviesJob.MovieDistributorTask = self
	
	self.AppraiseMovies = JobAppraiseMovies:new()
	self.AppraiseMovies.MovieDistributorTask = self
	
	self.BuyMovies = JobBuyMovies:new()
	self.BuyMovies.MovieDistributorTask = self		
	
	self.MoviesAtDistributor = {}	
end

function TaskMovieDistributor:GetNextJobInTargetRoom()
	if (self.CheckMoviesJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckMoviesJob
	elseif (self.AppraiseMovies.Status ~= JOB_STATUS_DONE) then
		return self.AppraiseMovies
	elseif (self.BuyMovies.Status ~= JOB_STATUS_DONE) then
		return self.BuyMovies
	end
	
	self:SetDone()
end

function AITask:OnDayBegins()
	self.CurrentBargainBudget = self.BudgetWholeDay / 2 -- Tagesbudget für gute Angebote ohne konkreten Bedarf
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobCheckMovies = AIJob:new{
	CurrentMovieIndex = 0;
	MovieDistributorTask = nil
}

function JobCheckMovies:Prepare()
	debugMsg("Job: CheckMovies")	
	self.CurrentMovieIndex = 0
end

function JobCheckMovies:Tick()
	self:CheckMovie()
	self:CheckMovie()
end

function JobCheckMovies:CheckMovie()	
	local movieId = TVT.md_getMovie(self.CurrentMovieIndex)	
	if (movieId == -2) then
		self.Status = JOB_STATUS_DONE
		return
	end	

	local movie = Movie:new()
	movie:Initialize(movieId)
	local player = _G["globalPlayer"]
	self.MovieDistributorTask.MoviesAtDistributor[self.CurrentMovieIndex] = movie
	
	player.Stats:AddMovie(movie)
	
	self.CurrentMovieIndex = self.CurrentMovieIndex + 1
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobAppraiseMovies = AIJob:new{
	CurrentMovieIndex = 0;
	MovieDistributorTask = nil;
	
	MovieMaxPrice = -1;
	PrimetimeMovieMinQuality = -1;
	DayMovieMinQuality = -1;
	
	SeriesMaxPrice = -1;
	PrimetimeSeriesMinQuality = -1;
	DaySeriesMinQuality = -1		
}

function JobAppraiseMovies:Prepare()
	debugMsg("Job: Appraise Movies")
	self.CurrentMovieIndex = 0
	self:AdjustMovieNiveau()
end

function JobAppraiseMovies:Tick()
	self:AppraiseCurrentMovie()
	self:AppraiseCurrentMovie()
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
		self.Status = JOB_STATUS_DONE		
	end
end

function JobAppraiseMovies:AppraiseMovie(movie)
	--debugMsg("AppraiseMovie")
	local player = _G["globalPlayer"]
	local stats = player.Stats		
	local pricePerBlockStats = nil
	local qualityStats = nil
	
	--Allgemeine Minimalvorraussetzungen erfüllt?
	if (ProgramType == PROGRAM_MOVIE) then
		if (movie:CheckConditions(self.MovieMaxPrice, self.DayMovieMinQuality)) then
			pricePerBlockStats = stats.MoviePricePerBlockAcceptable
			qualityStats = stats.MovieQualityAcceptable		
		else
			return
		end
	else
		if (movie:CheckConditions(self.SeriesMaxPrice, self.DaySeriesMinQuality)) then
			pricePerBlockStats = stats.SeriesPricePerBlockAcceptable
			qualityStats = stats.SeriesQualityAcceptable				
		else
			return
		end
	end	
	
	-- Je günstiger desto besser
	local financeFactor = movie.PricePerBlock / pricePerBlockStats.AverageValue	
	financeFactor = CutFactor(financeFactor, 0.2, 2)
	--debugMsg("movie.PricePerBlock: " .. movie.PricePerBlock .. " ; pricePerBlockStats.AverageValue: " .. pricePerBlockStats.AverageValue)
	
	-- Je qualitativ hochwertiger desto besser
	local qualityFactor = movie.Quality / qualityStats.AverageValue	
	qualityFactor = CutFactor(qualityFactor, 0.2, 2)
	--debugMsg("movie.Quality: " .. movie.Quality .. " ; qualityStats.AverageValue: " .. qualityStats.AverageValue)
		
	movie.Attractiveness = financeFactor * qualityFactor
	--debugMsg("Movie-Attractiveness: ===== " .. movie.Attractiveness .. " ===== ; financeFactor: " .. financeFactor .. " ; qualityFactor: " .. qualityFactor)	
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobBuyMovies = AIJob:new{
	MovieDistributorTask = nil;
}

function JobBuyMovies:Prepare()
	debugMsg("Job: Buy Movies")
	debugMsg("CurrentBudget: " .. self.MovieDistributorTask.CurrentBudget .. " - CurrentBargainBudget: " .. self.MovieDistributorTask.CurrentBargainBudget)
	
	local sortMethod = function(a, b)
		return a.Attractiveness > b.Attractiveness
	end	
	table.sort(self.MovieDistributorTask.MoviesAtDistributor, sortMethod)		
end

function JobBuyMovies:Tick()
	local movies = self.MovieDistributorTask.MoviesAtDistributor

	--TODO: Prüfen wie viele Filme überhaupt gebraucht werden	
	
	for k,v in pairs(movies) do		
		if (v.Price <= self.MovieDistributorTask.CurrentBudget) then
			if (v.Price <= self.MovieDistributorTask.CurrentBargainBudget) then -- Tagesbudget für gute Angebote ohne konkreten Bedarf
				if (v.Attractiveness > 1) then
					debugMsg("Kaufe Film: " .. v.Id .. " - Attraktivität: ".. v.Attractiveness .. " - Preis: " .. v.Price)	
					TVT.md_doBuyMovie(v.Id)
					self.MovieDistributorTask.CurrentBudget = self.MovieDistributorTask.CurrentBudget - v.Price
					self.MovieDistributorTask.CurrentBargainBudget = self.MovieDistributorTask.CurrentBargainBudget - v.Price
				end
			end		
		end
	end
	
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


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
	Attractiveness = -1
}

function Movie:Initialize(movieId)
	self.Id = movieId
	self.Sequels = TVT.MovieSequels(movieId)
	self.Genre = TVT.MovieGenre(movieId)
	self.Length = TVT.MovieLength(movieId)
	self.XRated = TVT.MovieXRated(movieId)
	self.Profit = TVT.MovieProfit(movieId)
	self.Speed = TVT.MovieSpeed(movieId)
	self.Review = TVT.MovieReview(movieId)
	self.Topicality = TVT.MovieTopicality(movieId)
	self.Price = TVT.MoviePrice(movieId)
	
	self.Quality = (0.3 * self.Profit + 0.15 * self.Speed + 0.25 * self.Review + 0.3 * self.Topicality)
	self.PricePerBlock = self.Price / self.Length

	if (self.Sequels > 0) then
		self.ProgramType = PROGRAM_SERIES
	else
		self.ProgramType = PROGRAM_MOVIE
	end		
end

function Movie:CheckConditions(maxPrice, minQuality)
	if (self.Price > maxPrice) then	return false end
	if (minQuality ~= nil) then
		if (self.Quality < minQuality) then return false end	
	end
	return true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<