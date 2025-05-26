-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- File: TaskMovieDistributor
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

_G["TaskMovieDistributor"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_MOVIEDISTRIBUTOR"]
	c.TargetRoom = TVT.ROOM_MOVIEAGENCY
	c.MoviesAtDistributor = nil
	c.MoviesAtAuctioneer = nil
	c.NiveauChecked = false
	c.CheckMode = 0
	c.MovieList = nil
	c.BuyStartProgrammeJob = nil
	c.BuyRequisitedLicencesJob = nil
	c.CheckMoviesJob = nil
	c.AppraiseMovies = nil
	c.CurrentBargainBudget = 0
	c.MovieQuality = nil
	c:ResetDefaults()
end)

function TaskMovieDistributor:typename()
	return "TaskMovieDistributor"
end


--override to assign more ticks
function TaskMovieDistributor:InitializeMaxTicks()
	AITask.InitializeMaxTicks(self) -- "." and "self" as param!

	self.MaxTicks = math.max(self.MaxTicks, 40)
end


function TaskMovieDistributor:ResetDefaults()
	self.BudgetWeight = 8
	self.BasePriority = 3
	self.NeededInvestmentBudget = 75000
	self.InvestmentPriority = 6
end

function TaskMovieDistributor:Activate()
	self.MovieQuality = StatisticEvaluator()

	--init movie count for task's decisions
	local player = getPlayer()
	local stats = player.Stats.MovieQuality
	self.blocksCount = player.blocksCount

	-- Was getan werden soll:
	self.BuyStartProgrammeJob = JobBuyStartProgramme()
	self.BuyStartProgrammeJob.Task = self

	self.BuyRequisitedLicencesJob = JobBuyRequisitedLicences()
	self.BuyRequisitedLicencesJob.Task = self

	self.CheckMoviesJob = JobCheckMovies()
	self.CheckMoviesJob.Task = self

	self.AppraiseMovies = JobAppraiseMovies()
	self.AppraiseMovies.Task = self

	self.BuyMovies = JobBuyMovies()
	self.BuyMovies.Task = self

	self.BidAuctions = JobBidAuctions()
	self.BidAuctions.Task = self

	self.MoviesAtDistributor = {}
	self.MoviesAtAuctioneer = {}

	--self.LogLevel = LOG_TRACE

	self:LogDebug("    Task information: CurrentBudget=" .. self.CurrentBudget .. "  CurrentBargainBudget=" .. self.CurrentBargainBudget .. "  blocksOwned=" .. self.blocksCount .. "  startProgrammeAmount=" .. player.Strategy.startProgrammeAmount)

	--added entry for movie selling
	self.SellSuitcaseLicences = JobSellSuitcaseLicences()
	self.SellSuitcaseLicences.Task = self
end


function TaskMovieDistributor:GetNextJobInTargetRoom()
	--added entry for programme licence selling, needs to come first
	--add "existence check" to skip errors in older savegames not knowing
	--the new job
	if (self.SellSuitcaseLicences ~= nil and self.SellSuitcaseLicences.Status ~= JOB_STATUS_DONE) then
		return self.SellSuitcaseLicences
	-- Check for "nice to have" licences
	elseif (self.CheckMoviesJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckMoviesJob
	elseif (self.BuyStartProgrammeJob.Status ~= JOB_STATUS_DONE) then
		return self.BuyStartProgrammeJob
	elseif (self.BuyRequisitedLicencesJob.Status ~= JOB_STATUS_DONE) then
		return self.BuyRequisitedLicencesJob

	elseif (self.AppraiseMovies.Status ~= JOB_STATUS_DONE) then
		return self.AppraiseMovies
	else
		if getPlayer().coverage > 0.7 then
			if (self.BidAuctions.Status ~= JOB_STATUS_DONE) then
				return self.BidAuctions
			elseif (self.BuyMovies.Status ~= JOB_STATUS_DONE) then
				return self.BuyMovies
			end
		else
			if (self.BuyMovies.Status ~= JOB_STATUS_DONE) then
				return self.BuyMovies
			elseif (self.BidAuctions.Status ~= JOB_STATUS_DONE) then
				return self.BidAuctions
			end
		end
	end
	self:SetDone()
end


function TaskMovieDistributor:getStrategicPriority()
	self:LogTrace("TaskMovieDistributor:getStrategicPriority")

	-- no money to buy things? skip even looking...
	if getPlayer().money <= 50000 then
		return 0.0
	elseif getPlayer().hour > 18 then
		return 0.5
	end
	return 1.0
end

function TaskMovieDistributor:BeforeBudgetSetup()
	local player = getPlayer()
	local totalReceivers = player.totalReceivers
	local maxTopBlocks = player.maxTopicalityBlocksCount
	local blocks = player.blocksCount

	self.BudgetWeight = 8
	if blocks >= 36 and (totalReceivers==nil or totalReceivers  <= 2500000) then
		--reduce budget for buying antenna
		self.BudgetWeight = 2
	elseif maxTopBlocks < 8 then
		--do not reduce budget
	elseif maxTopBlocks >= 12 then
		self.BudgetWeight = 1
	elseif blocks >= 120 then
		self.BudgetWeight = 2
	elseif blocks >= 75 then
		self.BudgetWeight = 6
	end
end

function TaskMovieDistributor:BudgetSetup()
	-- Tagesbudget für gute Angebote ohne konkreten Bedarf
	--TODO was self.BudgetWholeDay / 2, preventing buying good movies; problem to solve is recalculation of budget...
	--late in the game use saved money - prevent buying "bad" programmes
	local player=getPlayer()
	if player.coverage > 0.9 and player.money > 20000000 then self.BudgetWholeDay = self.BudgetWholeDay + 6000000 end
	self.CurrentBargainBudget = self.BudgetWholeDay
end


function TaskMovieDistributor:OnMoneyChanged(value, reason, reference)
	if (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_PROGRAMMELICENCE)) then
		--self:PayFromBudget(value)
		--self.CurrentBargainBudget = self.CurrentBargainBudget - value
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.SELL_PROGRAMMELICENCE)) then
		--Wird im Budgetmanager neu verteilt
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_AUCTIONBID)) then
		--self:PayFromBudget(value)	Wird unten gemacht, damit der Kontostand gleich aktuell ist. Muss man mal Debuggen
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAYBACK_AUCTIONBID)) then
		self.CurrentBudget = self.CurrentBudget + value -- Zurück zahlen
	end
end

function TaskMovieDistributor:IsErotic(prog)
	if prog:GetGenre() == TVT.Constants.ProgrammeGenre.Erotic then
		return true
	elseif prog.data:HasSubGenre(TVT.Constants.ProgrammeGenre.Erotic) > 0 then
		return true
	else
		return false
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBuyStartProgramme"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentMovieIndex = 0
	c.Task = nil
	c.AllMoviesChecked = false
end)


function JobBuyStartProgramme:typename()
	return "JobBuyStartProgramme"
end


function JobBuyStartProgramme:Prepare(pParams)
end


function JobBuyStartProgramme:Tick()
	local player = getPlayer()

	local movieBlocksNeeded = -1
	if player.blocksCount ~= nil then
		movieBlocksNeeded = player.Strategy.startProgrammeAmount * 2.5 - player.blocksCount
	end
	if movieBlocksNeeded <= 0 then
		self.Status = JOB_STATUS_DONE
		return True
	end

	local licencesResponse = TVT.md_getProgrammeLicences()
	if ((licencesResponse.result == TVT.RESULT_WRONGROOM) or (licencesResponse.result == TVT.RESULT_NOTFOUND)) then
		self.Status = JOB_STATUS_DONE
		return True
	end
	local budget = player.money

	local movies = TVT.convertToProgrammeLicences(licencesResponse.data)
	local goodMovies = {}
	-- sort lowest first
	local sortByPrice = function(a, b)
		return a:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME) < b:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME)
	end

	local allowSeries = True

	-- add "okay" movies to the list of candidates
	for k,v in pairs(movies) do
		--TODO improve rules for startprogramme ("bad" qualtiy OK if very new and price OK...; handle series differently?)
		local pricePerBlock = v:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME)
		local isSeries = v:IsSeries()
		if isSeries > 0 and allowSeries == False then
			self:LogDebug("IGNORING PROGRAMME (series) "..v:getTitle())
--		elseif v:GetQuality() < 0.07 or v:GetQualityRaw() < 0.18 then
--			--avoid the absolute trash :-)
--			self:LogDebug("IGNORING PROGRAMME (quality) "..v:getTitle())
		elseif v:GetQuality() < 0.07 or v:GetQualityRaw() < 0.15 then
			--avoid the absolute trash :-)
			self:LogDebug("IGNORING PROGRAMME (quality) "..v:getTitle())
		elseif v.GetData().IsTrash() > 0 then
			self:LogDebug("IGNORING PROGRAMME (trash) "..v:getTitle())
		elseif (v:isPaid() > 0 or v:getTopicality() < 0.15 or v:GetGenre() == TVT.Constants.ProgrammeGenre.Horror or self.Task:IsErotic(v)) then
			--prevent other problematic start programmes: call-in, horror, too old
			self:LogDebug("IGNORING PROGRAMME (old, genre) "..v:getTitle())
		elseif pricePerBlock > 50000 then
			self:LogDebug("IGNORING PROGRAMME (price) "..v:getTitle() .. " ".. pricePerBlock)
		elseif math.random(0,10) > 8 then
			-- ignore randomly
			self:LogDebug("IGNORING PROGRAMME (random) "..v:getTitle())
		else
			if isSeries > 0 then allowSeries = False end
			table.insert(goodMovies, v)
		end
	end
	table.sort(goodMovies, sortByPrice)


	local buyStartMovies = {}
	for k,v in pairs(goodMovies) do
		local price = v:GetPrice(TVT.ME)
		-- stop iteration if getting low on budget
		if budget < price then break end
		table.insert(buyStartMovies, v)
		budget = budget - price
	end

	local boughtCount = 0
	for k,v in pairs(buyStartMovies) do
		--Fairness - leave licences for other players
		--TODO find a better way to ensure all AIs have access to a "good" start programme
		--Always buy the least bad programme, so at least one licence is bought on every visit?
		--Change offers more often during the opening show?
		if boughtCount > 3 then break end

		local price = v:GetPrice(TVT.ME)
		self:LogInfo("Buying start programme licence: " .. v:GetTitle() .. " price=" .. price)
		TVT.md_doBuyProgrammeLicence(v:GetId())

		--attention: we subtract from the overall "buying programme" budget!
		self.Task:PayFromBudget(price)
		self.Task.CurrentBargainBudget = self.Task.CurrentBargainBudget - price
		boughtCount = boughtCount + 1
	end

	self.Status = JOB_STATUS_DONE
	--as long as start programme is not complete, skip the other jobs
	self:LogDebug("skipping regular buying and auctions")
	self.Task.AppraiseMovies.Status = JOB_STATUS_DONE
	self.Task.BuyMovies.Status = JOB_STATUS_DONE
	self.Task.BidAuctions.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBuyRequisitedLicences"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Id = c.typename()
	c.Task = nil
end)

function JobBuyRequisitedLicences:typename()
	return "JobBuyStartProgramme"
end

function JobBuyRequisitedLicences:Prepare(pParams)
end

function JobBuyRequisitedLicences:Tick()
	local player = getPlayer()
	local qualityStats = self.Task.MovieQuality
	local qualityGate = (2 * qualityStats.AverageValue + qualityStats.MinValue) / 3

	-- try to fulfill the requisitions

	-- fetch all (also outdated) requisitions
	local buyLicencesRequisitions = player:GetRequisitionsByTaskId(_G["TASK_MOVIEDISTRIBUTOR"], true)
	-- fetch all available licences
	local licencesResponse = TVT.md_getProgrammeLicences()
	if ((licencesResponse.result == TVT.RESULT_WRONGROOM) or (licencesResponse.result == TVT.RESULT_NOTFOUND)) then
		self.Status = JOB_STATUS_DONE
		return True
	end
	local availableLicences = TVT.convertToProgrammeLicences(licencesResponse.data)


	-- sort by attractivity/price
	local sortByAttractivity = function(a, b)
		--TODO check if price should be involved
		--return a:GetQuality() * a:GetPrice(TVT.ME) < b:GetQuality() * b:GetPrice(TVT.ME)
		return a:GetQuality() > b:GetQuality()
	end


	for k,buyLicencesReq in pairs(buyLicencesRequisitions) do
		-- loop over all buy-licences-requisitions (which each could
		-- contain multiple entries)
		if buyLicencesReq.requisitionID ~= nil and buyLicencesReq.requisitionID == "BuyProgrammeLicencesRequisition" then
			-- delete old ones (also removes in-actual singleLicenceReqs)
			if not buyLicencesReq:CheckActuality() then
				self:LogInfo("buyLicencesReq outdated")
				player:RemoveRequisition(buyLicencesReq)

			-- process others
			else
				--- loop over all single licence requisitions in the group
				for buySingleLicenceReqKey, buySingleLicenceReq in pairs(buyLicencesReq.licenceReqs) do
					-- collect fitting licences
					local relevantLicences = {}
					for licenceKey, licence in pairs(availableLicences) do
						local valid = true
						local price = licence:GetPrice(TVT.ME)
						if valid and price < buySingleLicenceReq.minPrice then valid = false; end
						if valid and price > buySingleLicenceReq.maxPrice and buySingleLicenceReq.maxPrice > 0 then valid = false; end
						if valid and licence:getQuality() < qualityGate then valid = false; end 
						if valid and licence:isPaid() > 0 then valid = false; end

						if valid then
							table.insert(relevantLicences, licence)
						end
					end
					-- sort by quality/price
					table.sort(relevantLicences, sortByAttractivity)

					-- buy best one
					local licence = table.first(relevantLicences)
					if licence ~= nil then
						if TVT.md_doBuyProgrammeLicence(licence:GetId()) == TVT.RESULT_OK then
							self:LogInfo("Bought requisition programme licence: " .. licence:GetTitle() .. " (" .. licence:GetId() .. ") - Price: " .. licence:GetPrice(TVT.ME))
							buySingleLicenceReq:Complete()
						else
							self:LogError("Buying requisition programme licence FAILED: " .. licence:GetTitle() .. " (" .. licence:GetId() .. ") - Price: " .. licence:GetPrice(TVT.ME))
						end

						--TODO really remove? - another req. might match the licence
						-- remove from the available licences so it is not
						-- tried to get bought again. Remove even if buy failed!
						table.removeElement(availableLicences, licence)
					end
				end
			end
		end
	end


	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobCheckMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentMovieIndex = 0
	c.CurrentAuctionIndex = 0
	c.Task = nil
	c.AllMoviesChecked = false
	c.AllAuctionsChecked = false
end)

function JobCheckMovies:typename()
	return "JobCheckMovies"
end

function JobCheckMovies:Prepare(pParams)
	self.CurrentMovieIndex = 0
	--calculate quality gate based on owned licences
	local qualityStats = self.Task.MovieQuality
	local maxTopBlocks = getPlayer().maxTopicalityBlocksCount
	for i=0, (TVT.GetProgrammeLicenceCount()-1)
	do
		local movie = TVT.GetProgrammeLicenceAtIndex(i)
		if movie.isAvailable() > 0 and movie.hasParentLicence() < 1 then
			--ensure buying licences if there are no fresh movies
			if maxTopBlocks > 0 then
				qualityStats:AddValue(movie.getQualityRaw()*movie.getMaxTopicality())
			else
				qualityStats:AddValue(movie.getQuality())
			end
		end
	end
	--store quality data in player statistics
	getPlayer().Stats.MovieQuality = qualityStats
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
	self.Task.MoviesAtDistributor[self.CurrentMovieIndex] = licence

	local player = getPlayer()
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
	self.Task.MoviesAtAuctioneer[self.CurrentAuctionIndex] = licence
	self.CurrentAuctionIndex = self.CurrentAuctionIndex + 1
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobAppraiseMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentMovieIndex = 0
	c.CurrentAuctionIndex = 0
	c.Task = nil

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
	self.CurrentMovieIndex = 0
	self.CurrentAuctionIndex = 0
	self:AdjustMovieNiveau()

	--skip checking
	if self.Task.CurrentBudget <= 0 and self.Task.CurrentBargainBudget <= 0 then
		self.Status = JOB_STATUS_DONE
	end
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
	local player = getPlayer()
	local stats = player.Stats
	local movieBudget = self.Task.BudgetWholeDay

	if self.Task.blocksCount > 72 and player.coverage < 0.8 then
		movieBudget = movieBudget * 0.7
	end

	local maxQualityMovies = stats.MovieQualityAcceptable.MaxValue
	local minQualityMovies = stats.MovieQualityAcceptable.MinValue
	local maxQualitySeries = stats.SeriesQualityAcceptable.MaxValue
	local minQualitySeries = stats.SeriesQualityAcceptable.MinValue

	--TODO check - price restriction lowers quality
	if self.Task.blocksCount > 100 then
		self.MovieMaxPrice = movieBudget * 0.75
		self.SeriesMaxPrice = movieBudget * 0.9
		if player.coverage > 0.8 then self.SeriesMaxPrice =  math.max(movieBudget, player.money / 2.5) end
	else
		self.MovieMaxPrice = movieBudget
		self.SeriesMaxPrice = movieBudget
	end

	self.MaxPricePerBlock = -1
	if self.Task.blocksCount < 96 and player.money > 4000000 then
		--restarted player, do not limit price per block
	else
		if (player.maxIncomePerSpot ~=nil and player.maxIncomePerSpot > 0) then self.MaxPricePerBlock = player.maxIncomePerSpot end
	end
	--TODO factor risk sensitive/depend on difficulty
	--TODO make dynamic, increase if enough money/reach/available blocks
	local maxTopBlocks = player.maxTopicalityBlocksCount
	if maxTopBlocks > 6 then
		self.MaxPricePerBlock = self.MaxPricePerBlock * 1.3
		movieBudget = movieBudget * 0.7
	else
		self.MaxPricePerBlock = self.MaxPricePerBlock * 2
	end
	if player.coverage > 0.9 and self.MaxPricePerBlock > 0 then self.MaxPricePerBlock = self.MaxPricePerBlock * 1.5 end

	--TODO check quality gates
	local ScopeMovies = maxQualityMovies - minQualityMovies
	self.PrimetimeMovieMinQuality = math.max(0, math.round(minQualityMovies + (ScopeMovies * 0.70)))
	self.DayMovieMinQuality = math.max(0, math.round(minQualityMovies + (ScopeMovies * 0.25)))

	local ScopeSeries = maxQualitySeries - minQualitySeries
	self.PrimetimeSeriesMinQuality = math.max(0, math.round(minQualitySeries + (ScopeSeries * 0.70)))
	self.DaySeriesMinQuality = math.max(0, math.round(minQualitySeries + (ScopeSeries * 0.25)))

	self:LogDebug("Adjusted movies niveau:  MovieMaxPrice=" .. math.floor(self.MovieMaxPrice) .."  PrimetimeMovieMinQuality=" .. self.PrimetimeMovieMinQuality .. "  DayMovieMinQuality=" .. self.DayMovieMinQuality .. " MaxPricePerBlock=".. self.MaxPricePerBlock)
	self:LogDebug("         series niveau:  SeriesMaxPrice=" .. math.floor(self.SeriesMaxPrice) .."  PrimetimeSeriesMinQuality=" .. self.PrimetimeSeriesMinQuality .. "  DaySeriesMinQuality=" .. self.DaySeriesMinQuality)
end


function JobAppraiseMovies:AppraiseCurrentMovie()
	local movie = self.Task.MoviesAtDistributor[self.CurrentMovieIndex]
	self.CurrentMovieIndex = self.CurrentMovieIndex + 1
	if (movie ~= nil) then
		self:AppraiseMovie(movie)
	elseif self.CurrentMovieIndex >= #self.Task.MoviesAtDistributor then
		self.AllMoviesChecked = true
	end
end


function JobAppraiseMovies:AppraiseCurrentAuction()
	local movie = self.Task.MoviesAtAuctioneer[self.CurrentAuctionIndex]
	self.CurrentAuctionIndex = self.CurrentAuctionIndex + 1
	if (movie ~= nil) then
		self:AppraiseMovie(movie)
	elseif self.CurrentAuctionIndex >= #self.Task.MoviesAtAuctioneer then
		self.AllAuctionsChecked = true
	end
end


-- sets attractiveness of licences ... if fitting
function JobAppraiseMovies:AppraiseMovie(licence)
	self:LogDebug("AppraiseMovie \"" .. licence:GetTitle() .. "\"")
	debugMsgDepth(1)
	local player = getPlayer()
	local stats = player.Stats
	local pricePerBlockStats = nil
	local qualityStats = nil
	local myMoviesQuality = self.Task.MovieQuality

	-- reset attractiveness, if it fits to the CURRENT conditions, it
	-- gets updated accordingly
	licence.SetAttractivenessString("0")

	local qualityGate = myMoviesQuality.AverageValue
	-- raise quality gate once a certail level is reached
	if player.coverage > 0.5 then
		if licence:IsSingle() == 1 then
			qualityGate = myMoviesQuality.MaxValue * 0.8
		else
			qualityGate = myMoviesQuality.MaxValue * 0.9
		end
	elseif self.Task.blocksCount > 75 then
		qualityGate = (qualityGate + myMoviesQuality.MaxValue) / 2
	end

	-- satisfied basic requirements?
	if (licence.IsSingle() == 1) then
		if (CheckMovieBuyConditions(licence, self.MovieMaxPrice, self.MaxPricePerBlock, qualityGate)) then
			pricePerBlockStats = stats.MoviePricePerBlockAcceptable
			qualityStats = stats.MovieQualityAcceptable
		else
			self:LogDebug("CheckMovieBuyConditions (single licence) not met. price: " .. licence.GetPrice(TVT.ME) .. " > " .. self.MovieMaxPrice .." or quality: " .. string.format("%.4f", licence.GetQuality()) .. " < " .. string.format("%.4f", qualityGate) )
			debugMsgDepth(-1)
			return
		end
	else
		if (CheckMovieBuyConditions(licence, self.SeriesMaxPrice, self.MaxPricePerBlock, qualityGate)) then
			pricePerBlockStats = stats.SeriesPricePerBlockAcceptable
			qualityStats = stats.SeriesQualityAcceptable
		else
			self:LogDebug("CheckMovieBuyConditions (series) not met. price: " .. licence.GetPrice(TVT.ME) .. " > " .. self.SeriesMaxPrice .." or quality: " .. string.format("%.4f", licence.GetQuality()) .. " < " .. string.format("%.4f", qualityGate) )
			debugMsgDepth(-1)
			return
		end
	end

	--TODO Statistik über alle gesehenen Filme, angebotene Filme, Filme die die Kriterien erfüllen, meine Filme?

	-- the cheaper the better; due to extreme range of price per block, a good move will always have a low factor
	-- you would have to calculate the factor based on movies in the same quality range
	local financeFactor = 1.0
--	if pricePerBlockStats.AverageValue > 0 then financeFactor = ((pricePerBlockStats.MaxValue + pricePerBlockStats.AverageValue)/ 2) / licence:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME) ; end
--	financeFactor = CutFactor(financeFactor, 0.1, 3)

	-- the higher the quality the better (using quality gate yields low values later on)
	local qualityFactor = 1.0
	if qualityStats.AverageValue > 0 then qualityFactor = licence:GetQuality() / qualityStats.AverageValue; end
	qualityFactor = CutFactor(qualityFactor, 0.1, 3)

	if licence.GetData().IsXRated() > 0 and qualityFactor < 1.9 then
		qualityFactor = qualityFactor * 0.6
	end
	if licence.GetData().IsCulture() > 0 then
		qualityFactor = qualityFactor * 1.3
	end
	if licence.GetData().IsTrash() > 0 then
		qualityFactor = qualityFactor * 0.75
	end
	if licence.isLive() > 0 and (licence.isSingle() ~= 1 or licence.isAlwaysLive() == 0) then
		--TODO do not buy live licences
		qualityFactor = qualityFactor * 0
	end

	if (licence.isPaid() > 0 ) then
		-- TODO call in bad for the image; maybe later if the sender image is high enough?
	else
		licence.SetAttractivenessString(tostring(financeFactor * qualityFactor))
	end


	--self:LogTrace("licence '"..licence.getTitle().."': pricePerBlock=" .. licence:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME) .." (".. licence:GetPricePerBlock(1, TVT.Constants.BroadcastMaterialType.PROGRAMME) .."  avg=" .. string.format("%.4f", pricePerBlockStats.AverageValue) ..")  quality=" .. string.format("%.4f", licence:GetQuality()) .. " (avg=" .. string.format("%.4f", qualityStats.AverageValue) ..")  qualityFactor=" .. string.format("%.4f", qualityFactor) .. "  financeFactor=" .. string.format("%.4f", financeFactor)  .."  => attractiveness=" .. string.format("%.4f", licence:GetAttractiveness()))
	debugMsgDepth(-1)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBuyMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobBuyMovies:typename()
	return "JobBuyMovies"
end

function JobBuyMovies:Prepare(pParams)
	--TODO nicht zufällig, sondern nach bestimmtem Kriterium?
	if (self.Task.MoviesAtDistributor ~= nil) then
		local sortFunction
		local sortMethod = math.random(0,2)
		--TODO solange die Auswahl noch nicht groß ist nach Preis (Qualität muss ja ohnehin hoch genug sein)
		if self.Task.blocksCount > 0 and self.Task.blocksCount < 96 then sortMethod = 1 end
		if getPlayer().coverage > 0.35 then sortMethod = 2 end
		if sortMethod == 0 then
			self:LogTrace("sort by quality")
			sortFunction = function(a, b)
				return a:GetQuality() > b:GetQuality()
			end
		elseif sortMethod == 1 then 
			self:LogTrace("sort by price per block")
			sortFunction = function(a, b)
				return a:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME) < b:GetPricePerBlock(TVT.ME, TVT.Constants.BroadcastMaterialType.PROGRAMME)
			end
		else
			self:LogTrace("sort attractiveness")
			sortFunction = function(a, b)
				return a:getAttractiveness() > b:getAttractiveness()
			end
		end
		table.sort(self.Task.MoviesAtDistributor, sortFunction)
	end
end

function JobBuyMovies:Tick()
	-- skip checks without money
	if (self.Task.CurrentBudget < 0) then
		self.Status = JOB_STATUS_DONE
		return
	end

	local movies = self.Task.MoviesAtDistributor
	--TODO not many licences - do not spend everything on new one
	local maxPrice = self.Task.CurrentBargainBudget
	local blocksCount = self.Task.blocksCount
	local player = getPlayer()
	if blocksCount > 0 and blocksCount < 72 then
		if maxPrice > 250000 then
			maxPrice = maxPrice * 0.5
		elseif maxPrice > 150000 then
			maxPrice = maxPrice * 0.7
		end
		--TODO max price added to deal with restarting after bankruptcy
		--problematic for series (price per block would be better), good threshold hard to determine
		if player.money > 4000000 then
			if blocksCount < 36 then 
				maxPrice = math.min(maxPrice*2, 600000)
			elseif blocksCount < 64 then 
				maxPrice = math.min(maxPrice*2, 1200000)
			end
		else
			if blocksCount < 36 then
				maxPrice = math.min(maxPrice, 300000)
			elseif blocksCount < 64 then 
				maxPrice = math.min(maxPrice, 600000)
			end
		end
	end

	local seriesOverBudgetOk = 1

	if player.maxTopicalityBlocksCount > 12 and math.random(1, 10) > 5 then
		--TODO more sophisticated version
		--do not always buy something
	elseif (movies ~= nil) then
		for k,v in pairs(movies) do
			if (self:shouldBuyMovie(v) == 1) then
				local doBuy = 1
				local priceToPay = v:GetPrice(TVT.ME)
				if priceToPay > self.Task.CurrentBudget or priceToPay > maxPrice then doBuy = 0 end
				if player.coverage > 0.75 and v:isSingle() ~= 1 and priceToPay < player.money / 2.5 and seriesOverBudgetOk == 1 then
					seriesOverBudgetOk = 0
					doBuy = 1
				end
				if doBuy == 1 then
					self:LogInfo("Buying licence: " .. v:GetTitle() .. " (" .. v:GetId() .. ") - Price: " .. priceToPay)
					TVT.md_doBuyProgrammeLicence(v:GetId())

					self.Task:PayFromBudget(priceToPay)
					self.Task.CurrentBargainBudget = self.Task.CurrentBargainBudget - priceToPay

					--do not spend all available money, if there are enough max-top blocks
					--saves money for antennas
					if blocksCount > 72 and player.maxTopicalityBlocksCount > 10 and player.money < 25000000 then
						self.Task.CurrentBudget = 0
					end
				end
			end
		end
	else
		self:LogError("Movieagency does not offer any licences.")
	end
	self.Status = JOB_STATUS_DONE
end

function JobBuyMovies:shouldBuyMovie(movie)
	--TODO more sophisticated bias for choosing movie genre
	if movie:GetAttractiveness() > 1 then
		local genre = movie:GetGenre()
		if self.Task:IsErotic(movie) and math.random(0,500) > 1 then
			return 0
		end
		if genre == TVT.Constants.ProgrammeGenre.Horror and math.random(0,100) > 25 then
			return 0
		end
		if genre == TVT.Constants.ProgrammeGenre.SciFi and math.random(0,100) > 25 then
			return 0
		end
		if genre == TVT.Constants.ProgrammeGenre.Animation and math.random(0,100) > 25 then
			return 0
		end
		return 1
	else
		return 0
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBidAuctions"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)


function JobBidAuctions:typename()
	return "JobBidAuctions"
end


function JobBidAuctions:Prepare(pParams)
	local sortMethod = function(a, b)
		return a:GetAttractiveness() > b:GetAttractiveness()
	end
	table.sort(self.Task.MoviesAtAuctioneer, sortMethod)
end


function JobBidAuctions:Tick()
	local bid = 1
	--TODO prevent bidding too early on
	if self.Task.CurrentBudget < 0 then
		--no money 
		bid = 0
	elseif math.random(10,16) >= getPlayer().hour then
		--too early in the day
		bid = 0
	elseif self.Task.blocksCount < 24 then
		--ensure base licence collection before bidding
		bid = 0
	end
	if bid == 0 then
		self.Status = JOB_STATUS_DONE
		return
	end

	local movies = self.Task.MoviesAtAuctioneer

	--TODO: Check how many licences we need

	for k,v in pairs(movies) do
		local price = v:GetPrice(TVT.ME)
		local auctionIndex = TVT.md_getAuctionProgrammeLicenceBlockIndex(v:GetId())
		if auctionIndex >= 0 then
			local nextBid = TVT.md_GetAuctionProgrammeLicenceNextBid(auctionIndex)
			local currentBidder = TVT.md_GetAuctionProgrammeLicenceHighestBidder(auctionIndex)
			self:LogDebug("auction: " .. v:GetTitle() .."   price=" .. price .."  nextBid=" .. nextBid .. "  currentBidder=" .. currentBidder)

			if currentBidder ~= TVT.ME then
				--TODO maybe pay higher price if you really want a licence
				if (nextBid <= self.Task.CurrentBudget and nextBid <= price) then
					-- daily budget for good offers without direct need
					if (nextBid <= self.Task.CurrentBargainBudget) then
						--TODO genre bias analogous to movies
						--TODO live only of sending on live time supported
						if (v:GetAttractiveness() > 1) then
							self:LogInfo("[Licence auction] placing bet for: " .. v:GetTitle() .. " (id=" .. v:GetId() .. ", price=" .. price ..", attractivity=" .. v:GetAttractiveness() .. ", quality=" ..v:GetQuality() ..")")
							TVT.md_doBidAuctionProgrammeLicence(v:GetId())

							self.Task:PayFromBudget(nextBid)
							self.Task.CurrentBargainBudget = self.Task.CurrentBargainBudget - nextBid
						else
							self:LogDebug("[Licence auction] too low attractivity: " .. v:GetTitle() .. " (" .. v:GetId() .. ") - Price: " .. nextBid .." - Attractivity: " .. v:GetAttractiveness())
						end
					end
				end
			end
		end
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobSellSuitcaseLicences"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)


function JobSellSuitcaseLicences:typename()
	return "JobSellSuitcaseLicences"
end


function JobSellSuitcaseLicences:Prepare(pParams)

end


function JobSellSuitcaseLicences:Tick()
	--sell content of suitcase
	local myPC = MY:GetProgrammeCollection()
	local nCase = myPC:GetSuitcaseProgrammeLicenceCount()
	local case = myPC:GetSuitcaseProgrammeLicencesArray()
	self:LogDebug("md case has: "..#case)

	--for i=1, #case do self:LogDebug("md case "..i.." : "..tostring(case[i])) end
	if case ~= nil and #case > 0 then
		self:LogInfo("attempting licence sale")
		for i=1,#case
		do
			local v = case[i]
			if v ~= nil
			then
				err = TVT.md_doSellProgrammeLicence(v:GetId())
				if err == 1 then
					self:LogInfo("sold "..v:GetTitle())
				else
					self:LogError("sale failed for "..v:GetTitle() .. " with error code: "..err)
				end

				local player = getPlayer()
				player.programmeLicencesInSuitcaseCount = math.max(0, player.programmeLicencesInSuitcaseCount - 1)
			else
				self:LogError("md sale: nil value")
			end
		end
	else
		self:LogTrace("md: empty suitcase") 
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
