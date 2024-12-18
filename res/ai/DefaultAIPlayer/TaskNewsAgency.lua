-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskNewsAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_NEWSAGENCY"]
	c.TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME
	c.BudgetWeight = 2
	c.BasePriority = 7
	c.AbonnementBudget = 0

	-- store current abonnement fees (only fetchable while in news studio)
	-- player starts with a single genre
	c.newsAbonnementFees = {}
	c.newsAbonnementFees[TVT.Constants.NewsGenre.CURRENTAFFAIRS] = TVT.GetNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS, 1)
	c.newsAbonnementFees[TVT.Constants.NewsGenre.POLITICS_ECONOMY] = 0
	c.newsAbonnementFees[TVT.Constants.NewsGenre.SPORT] = 0
	c.newsAbonnementFees[TVT.Constants.NewsGenre.SHOWBIZ] = 0
	c.newsAbonnementFees[TVT.Constants.NewsGenre.TECHNICS_MEDIA] = 0
	c.newsAbonnementFees[TVT.Constants.NewsGenre.CULTURE] = 0
	c.newsAbonnementTotalFees = c.newsAbonnementFees[TVT.Constants.NewsGenre.CURRENTAFFAIRS]

	c.newsGenrePriority = {
	                        TVT.Constants.NewsGenre.CURRENTAFFAIRS,
	                        TVT.Constants.NewsGenre.POLITICS_ECONOMY,
	                        TVT.Constants.NewsGenre.SPORT,
	                        TVT.Constants.NewsGenre.SHOWBIZ,
	                        TVT.Constants.NewsGenre.TECHNICS_MEDIA,
	                        TVT.Constants.NewsGenre.CULTURE
	                      }
end)


function TaskNewsAgency:typename()
	return "TaskNewsAgency"
end


function TaskNewsAgency:Activate()
	self.hour = getPlayer().hour

	-- sub tasks => jobs
	self.CheckEventNewsJob = JobCheckEventNews()
	self.CheckEventNewsJob.Task = self

	self.NewsAgencyAbonnementsJob = JobNewsAgencyAbonnements()
	self.NewsAgencyAbonnementsJob.Task = self

	self.NewsAgencyJob = JobNewsAgency()
	self.NewsAgencyJob.Task = self

	--self.LogLevel = LOG_TRACE
end


function TaskNewsAgency:GetNextJobInTargetRoom()
	if (self.CheckEventNewsJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckEventNewsJob
	end
	if (self.NewsAgencyAbonnementsJob.Status ~= JOB_STATUS_DONE) then
		return self.NewsAgencyAbonnementsJob
	end
	if (self.NewsAgencyJob.Status ~= JOB_STATUS_DONE) then
		return self.NewsAgencyJob
	end

	local taskTime = getPlayer().minutesGone - self.StartTask
	if taskTime < 7 then
		self:SetIdle(7-taskTime)
	else
		self:SetDone()
	end
end


--override
function TaskNewsAgency:getStrategicPriority()
	-- adjust priority according to player character
	local player = getPlayer()
	local result = 0.9
	if player.NewsPriority > 7 then
		result = 1.25
	elseif player.NewsPriority >= 6 then
		result = 1.15
	elseif player.NewsPriority >= 5 then
		result = 1.0
	end

	-- MODIFIERS

	-- increased priority if the news-sammy is to award
	if player.currentAwardType == TVT.Constants.AwardType.NEWS then
		result = 1.25
	end

	return result
end


function TaskNewsAgency:UpdateNewsAbonnementFees()
	-- can only update if in the news studio
	if TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS) ~= TVT.RESULT_WRONGROOM then
		self.newsAbonnementFees[TVT.Constants.NewsGenre.CURRENTAFFAIRS] = TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS)
		self.newsAbonnementFees[TVT.Constants.NewsGenre.POLITICS_ECONOMY] = TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.POLITICS_ECONOMY)
		self.newsAbonnementFees[TVT.Constants.NewsGenre.SPORT] = TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.SPORT)
		self.newsAbonnementFees[TVT.Constants.NewsGenre.SHOWBIZ] = TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.SHOWBIZ)
		self.newsAbonnementFees[TVT.Constants.NewsGenre.TECHNICS_MEDIA] =  TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.TECHNICS_MEDIA)
		self.newsAbonnementFees[TVT.Constants.NewsGenre.CULTURE] = TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.CULTURE)
		self.newsAbonnementTotalFees = TVT.ne_getTotalNewsAbonnementFees()
	end
end


function TaskNewsAgency:BeforeBudgetSetup()
	self:CalculateFixedCosts()

	-- adjust budget weighting according to player character
	local player = getPlayer()

	if player.NewsPriority > 7 then
		self.BudgetWeight = 4
	elseif player.NewsPriority >= 6 then
		self.BudgetWeight = 3
	elseif player.NewsPriority >= 5 then
		self.BudgetWeight = 2
	else
		self.BudgetWeight = 1
	end

	-- MODIFIERS

	-- increased priority if the news-sammy is to award
	if player.currentAwardType == TVT.Constants.AwardType.NEWS then
		self.BudgetWeight = 4
	end
end


function TaskNewsAgency:BudgetSetup()
	-- calculate abonnement budget
	-- to have at least news, we need a minimum budget to be able to sub-
	-- scribe to current affairs
	local baseFee = TVT.GetNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS, 1)
	local tempAbonnementBudget = math.max(baseFee, self.BudgetWholeDay * 0.45)
	--TODO ensure abonnement bugdet is not subtracted multiple times over the day
	self.AbonnementBudget = tempAbonnementBudget
	self.CurrentBudget = self.CurrentBudget - self.AbonnementBudget
	self:LogTrace("BudgetSetup: AbonnementBudget: " .. self.AbonnementBudget .. "   - CurrentBudget: " .. self.CurrentBudget)
end


function TaskNewsAgency:BudgetMaximum()
	local player = getPlayer()
	local money = player.money
	if money <= 500000 or player.gameDay < 2 then
		return math.max(50000, math.floor(money / 10))
	elseif money < 1000000 then
		return math.max(110000, math.floor(money / 10))
	elseif money < 2000000 then
		return math.max(225000, math.floor(money / 10))
	elseif money > 7000000 and player.coverage > 0.5 then
		return 1000000
	else
		return 300000
	end
end


function TaskNewsAgency:OnMoneyChanged(value, reason, reference)
	reason = tonumber(reason)
	if (reason == TVT.Constants.PlayerFinanceEntryType.PAY_NEWS) then
		self:PayFromBudget(math.abs(value))
		self:CalculateFixedCosts()
	elseif (reason == TVT.Constants.PlayerFinanceEntryType.PAY_NEWSAGENCIES) then
		self:PayFromBudget(math.abs(value))
		self:CalculateFixedCosts()
	end
end


--override
function TaskNewsAgency:CalculateFixedCosts()
	self.FixedCosts = self.newsAbonnementTotalFees
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobCheckEventNews"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobCheckEventNews:typename()
	return "JobCheckEventNews"
end

function JobCheckEventNews:Prepare(pParams)

end

function JobCheckEventNews:Tick()
	local terrorLevel = TVT.ne_getTerroristAggressionLevel(-1)
	local maxTerrorLevel = TVT.ne_getTerroristAggressionLevelMax()
	local levelDiff = maxTerrorLevel - terrorLevel

	local vrLevel = TVT.ne_getTerroristAggressionLevel(0)
	local frLevel = TVT.ne_getTerroristAggressionLevel(1)

	local player = getPlayer()
	local checkSignsTask = player.TaskList[TASK_CHECKSIGNS]
	local roomBoardTask = player.TaskList[TASK_ROOMBOARD]

	if checkSignsTask ~= nil then
		if checkSignsTask.terrorLevel > terrorLevel then
			checkSignsTask.checkStudio = 1
		end
		checkSignsTask.terrorLevel = terrorLevel
	end
	if roomBoardTask ~= nil then
		-- mark the situation of a soon happening attack
		if levelDiff < 2 then
			roomBoardTask.RecognizedTerrorLevel = true
		end
		roomBoardTask.FRDubanTerrorLevel = vrLevel
		roomBoardTask.VRDubanTerrorLevel = frLevel
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobNewsAgencyAbonnements"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)


function JobNewsAgencyAbonnements:typename()
	return "JobNewsAgencyAbonnements"
end


function JobNewsAgencyAbonnements:Prepare(pParams)
	-- update current fees
	self.Task:UpdateNewsAbonnementFees()
end


function JobNewsAgencyAbonnements:Tick()
	local availableBudget = self.Task.AbonnementBudget

	local oldFees = self.Task.newsAbonnementTotalFees


	-- loop over all genres and try to subscribe as much as possible
	local newSubscriptionLevels = {}
	-- start with level 0
	for genreIndex, genreID in ipairs(self.Task.newsGenrePriority) do
		newSubscriptionLevels[genreID] = 0
	end
	local budgetLeft = true
	local tempAvailableBudget = availableBudget
	-- do NEVER stop abonnements to current affairs
	-- so budget must be minimimum at level 1
	tempAvailableBudget = math.max(tempAvailableBudget, TVT.GetNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS, 1))

	-- fill a "plan" (allows optimization before real adjustment is done)
	while budgetLeft == true do
		budgetLeft = false
		for genreIndex, genreID in ipairs(self.Task.newsGenrePriority) do

			local nextLevel = newSubscriptionLevels[genreID] + 1
			local nextLevelFee = TVT.GetNewsAbonnementFee(genreID, nextLevel)
			if nextLevel <= 3 and tempAvailableBudget >= nextLevelFee then
				if tempAvailableBudget >= nextLevelFee then
					budgetLeft = true
				end
				newSubscriptionLevels[genreID] = nextLevel
				tempAvailableBudget = tempAvailableBudget - nextLevelFee
			end
		end
	end

	local player = getPlayer()
	--TODO raise on day before award?; randomize
	if player.currentAwardType == TVT.Constants.AwardType.CULTURE then
		if newSubscriptionLevels[TVT.Constants.NewsGenre.CULTURE] == 0 then
			newSubscriptionLevels[TVT.Constants.NewsGenre.CULTURE] = 1
		end
	end

	local preventDowngrade = false
	local player = getPlayer()
	if player.Budget.CurrentFixedCosts > 300000 or oldFees < 40000 then
		self:LogDebug(" preventing downgrade") 
		preventDowngrade = true
	end
	local preventUpgrade = false

	-- finally adjust levels
	for genreIndex, genreID in ipairs(self.Task.newsGenrePriority) do
		local oldLevel = TVT.ne_getNewsAbonnement(genreID)
		local newFee = TVT.GetNewsAbonnementFee(genreID, newSubscriptionLevels[i])
		local newLevel = newSubscriptionLevels[genreID]
		if oldLevel > newLevel and (self.Task.hour < 21 or preventDowngrade) then
			--TODO subscriptions must be optimized anyway - permanent changes make no sense
			--once the fixed costs reach a certain level, unsubscribing does not save much
			self:LogDebug("no cancelling of subscription before 22 o'clock") 
		elseif oldLevel < newLevel and (self.Task.hour > 7 or self.Task.hour == 0 or preventUpgrade) then
			--TODO exclude 0 to prevent expensive early subscription after game start
			self:LogDebug("no subscription upgrade after 8 o'clock") 
		elseif oldLevel ~= newLevel then
			TVT.ne_setNewsAbonnement(genreID, newSubscriptionLevels[genreID])
			if(oldLevel < newLevel) then 
				preventUpgrade = true
			else 
				preventDowngrade = true
			end
			self:LogInfo("Changing genre " ..genreID.. " abonnement level from " .. oldLevel .. " to " .. newSubscriptionLevels[genreID] .. " (new level=" .. TVT.ne_getNewsAbonnement(genreID) .. ")")
		else
			self:LogTrace("Keeping genre " ..genreID.. " abonnement level at " .. oldLevel)
		end
	end

	-- update current fees
	self.Task:UpdateNewsAbonnementFees()


	-- subract new expenses
	local newFees = self.Task.newsAbonnementTotalFees
	if newFees ~= oldFees then
		self:LogDebug("Adjusted news budget by " .. (newFees - oldFees) .. ". CurrentBudget=" .. self.Task.CurrentBudget)
		self.Task.CurrentBudget = self.Task.CurrentBudget - (newFees - oldFees)
	else
		self:LogTrace("News budget stays the same. CurrentBudget=" .. self.Task.CurrentBudget)
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobNewsAgency"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)


function JobNewsAgency:typename()
	return "JobNewsAgency"
end


function JobNewsAgency:Prepare(pParams)
end


function JobNewsAgency:Tick()
	local price = 0

	-- fetch a list of all news, sorted by attractivity
	-- and modified by a bonus for already paid news (so a news
	-- is preferred if just a bit less good but already paid)
	local newsList = self.GetNewsList(0.2)

	if self.Task.CurrentBudget < 0 then
		local player = getPlayer()
		if player.Budget.CurrentFixedCosts > 120000 and player.money > 150000 then
			--TODO with high fixed costs often there is a negative budget although there is money
			self:LogDebug("raised news budget because there is money")
			self.Task.CurrentBudget = 50000
		end
	end

	-- loop over all 3 slots
	for slot=1,3 do
		if (table.count(newsList) > 0) then
			local selectedNews = nil

			-- find the best one we can afford
			for i, news in ipairs(newsList) do
				price = news.GetPrice(TVT.ME)
				if (self.Task.CurrentBudget >= price or news.IsPaid() == 1) then
					--skip setting if already done
					local existingNews = TVT.ne_getBroadcastedNews(slot-1).data

					-- we cannot compare objects generally, as their
					-- memory adress is different
					if existingNews == news then
						self:LogTrace("- SKIP filling slot "..slot..". Already set there.")
					else
						if (news.IsPaid() == 1) then
							self:LogTrace("- filling slot "..slot..". Re-use news: '" .. news.GetTitle() .. "'.")
						else
							self:LogTrace("- filling slot "..slot..". Buying news: '" .. news.GetTitle() .. "' - Price: " .. price)
						end
						TVT.ne_doNewsInPlan(slot-1, news.GetGUID())
						--self.Task:PayFromBudget(price)
					end

					selectedNews = news

					-- remove from list, so next slot wont use that again
					table.remove(newsList, i)
				end
				-- do not search any longer
				if selectedNews ~= nil then break end
			end
		else
			self:LogTrace("- filling slot "..slot..". No news available, skipping slot.")
		end
	end

	self.Status = JOB_STATUS_DONE
end


-- retrieve a (attractivity sorted) list of news candidates
-- paidBonus	defines bonus percentage to attractivity of already paid
--              news
function JobNewsAgency:GetNewsList(paidBonus)
	local currentNewsList = {}

	if (paidBonus == nil) then
		paidBonus = 0.1 --10%
	end
	paidBonus = tonumber(paidBonus)


	-- fetch all news, insert all available to a list
	-- fetch available ones
	local response = TVT.ne_getAllAvailableNews()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end
	local allNews = response.DataArray()
	for i, news in ipairs(allNews) do
		if news ~= nil then
			table.insert(currentNewsList, news)
		end
	end

	-- fetch news show news
	response = TVT.ne_getAllBroadcastedNews()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end
	local broadcastedNews = response.DataArray()
	-- "pairs", not "ipairs" as the result might contains empty slots
	-- which "ipairs" does not like
	for i, news in pairs(broadcastedNews) do
		if news ~= nil then
			table.insert(currentNewsList, news)
		end
	end

	local cultureAward = 0
	if getPlayer().currentAwardType == TVT.Constants.AwardType.CULTURE then
		cultureAward = 1
	end 

	-- sort by attractivity modifed by paid-state-bonus
	-- precache complex weight calculation
	local weights = {}
	for k,v in pairs(currentNewsList) do
		local weight = v.GetAttractiveness() * (1.0 + v.IsPaid() * paidBonus)
		if cultureAward == 1 and v.GetGenre() == TVT.Constants.NewsGenre.CULTURE then
			weight = weight * 3
		end
		weights[ v.GetID() ] = weight
	end

	-- sort
	local sortMethod = function(a, b)
		return weights[ a.GetID() ] > weights[ b.GetID() ]
	end
	table.sort(currentNewsList, sortMethod)


	return currentNewsList
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<