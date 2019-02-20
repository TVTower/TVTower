-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskNewsAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_NEWSAGENCY"]
	c.TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME
	c.BudgetWeight = 2
	c.BasePriority = 7
	c.AbonnementBudget = 0

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
	-- Was getan werden soll:
	self.CheckEventNewsJob = JobCheckEventNews()
	self.CheckEventNewsJob.Task = self

	self.NewsAgencyAbonnementsJob = JobNewsAgencyAbonnements()
	self.NewsAgencyAbonnementsJob.Task = self

	self.NewsAgencyJob = JobNewsAgency()
	self.NewsAgencyJob.Task = self

	self.IdleJob = AIIdleJob()
	self.IdleJob:SetIdleTicks( math.random(5,15) )
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
	elseif (self.IdleJob ~= nil and self.IdleJob.Status ~= JOB_STATUS_DONE) then
		return self.IdleJob
	end

--	self:SetWait()
	self:SetDone()
end

--override
function TaskNewsAgency:getStrategicPriority()
	-- adjust priority according to player character
	local player = _G["globalPlayer"]
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
		result = result * 1.25
	end

	return result
end


function TaskNewsAgency:BeforeBudgetSetup()
	self:SetFixedCosts()

	-- adjust budget weighting according to player character
	local player = _G["globalPlayer"]

	if player.NewsPriority > 7 then
		self.BudgetWeight = 5
	elseif player.NewsPriority >= 6 then
		self.BudgetWeight = 4
	elseif player.NewsPriority >= 5 then
		self.BudgetWeight = 3
	else
		self.BudgetWeight = 2
	end

	-- MODIFIERS

	-- increased priority if the news-sammy is to award
	if player.currentAwardType == TVT.Constants.AwardType.NEWS then
		self.BudgetWeight = self.BudgetWeight + 1
	end
end

function TaskNewsAgency:BudgetSetup()
	local baseFee = TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS, 1)

	-- calculate abonnement budget
	-- to have at least news, we need a minimum budget to be able to sub-
	-- scribe to current affairs
	local tempAbonnementBudget = math.max(baseFee, self.BudgetWholeDay * 0.45)
	self.AbonnementBudget = tempAbonnementBudget
	self.CurrentBudget = self.CurrentBudget - self.AbonnementBudget
	debugMsg("BudgetSetup: AbonnementBudget: " .. self.AbonnementBudget .. "   - CurrentBudget: " .. self.CurrentBudget)
end

function TaskNewsAgency:BudgetMaximum()
	local money = MY.GetMoney(-1)
	if money <= 500000 then
		return math.max(50000, math.floor(money / 10))
	elseif money < 1000000 then
		return math.max(110000, math.floor(money / 10))
	elseif money < 2000000 then
		return math.max(225000, math.floor(money / 10))
	else
		return 300000
	end
end

function TaskNewsAgency:OnMoneyChanged(value, reason, reference)
	if (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_NEWS)) then
		self:PayFromBudget(value)
		self:SetFixedCosts()
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_NEWSAGENCIES)) then
		self:PayFromBudget(value)
		self:SetFixedCosts()
	end
end

function TaskNewsAgency:SetFixedCosts()
	self.FixedCosts = TVT.ne_getTotalNewsAbonnementFees()
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
	debugMsg("Looking for news about special events")
end

function JobCheckEventNews:Tick()
	local terrorLevel = TVT.ne_getTerroristAggressionLevel(-1)
	local maxTerrorLevel = TVT.ne_getTerroristAggressionLevelMax()

--	if terrorLevel >= 4 then
--		kiMsg("Terroranschlag geplant! Terror-Level: " .. terrorLevel)
--	end

	local player = _G["globalPlayer"] --Zugriff die globale Variable
	if player.TaskList[TASK_ROOMBOARD] ~= nil then
		local roomBoardTask = player.TaskList[TASK_ROOMBOARD]
		if terrorLevel >= 2 then
			roomBoardTask.SituationPriority = terrorLevel * terrorLevel
		end

		-- mark the situation of a soon happening attack
		if terrorLevel >= 1 then
			roomBoardTask.RecognizedTerrorLevel = true
		end

		roomBoardTask.FRDubanTerrorLevel = TVT.ne_getTerroristAggressionLevel(0) --FR Duban Terroristen
		roomBoardTask.VRDubanTerrorLevel = TVT.ne_getTerroristAggressionLevel(1) --VR Duban Terroristen
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
	debugMsg("Adjusting news abonnements")
end

function JobNewsAgencyAbonnements:Tick()
	local availableBudget = self.Task.AbonnementBudget

	local oldFees = TVT.ne_getTotalNewsAbonnementFees()


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
	tempAvailableBudget = math.max(tempAvailableBudget, TVT.ne_getNewsAbonnementFee(TVT.Constants.NewsGenre.CURRENTAFFAIRS, 1))

	-- fill a "plan" (allows optimization before real adjustment is done)
	while budgetLeft == true do
		budgetLeft = false
		for genreIndex, genreID in ipairs(self.Task.newsGenrePriority) do

			local nextLevel = newSubscriptionLevels[genreID] + 1
			local nextLevelFee = TVT.ne_getNewsAbonnementFee(genreID, nextLevel)
			if nextLevel <= 3 and tempAvailableBudget >= nextLevelFee then
				if tempAvailableBudget >= nextLevelFee then
					budgetLeft = true
				end
				newSubscriptionLevels[genreID] = nextLevel
				tempAvailableBudget = tempAvailableBudget - nextLevelFee
			end
		end
	end

	-- finally adjust levels
	for genreIndex, genreID in ipairs(self.Task.newsGenrePriority) do
		local oldLevel = TVT.ne_getNewsAbonnement(genreID)
		local newFee = TVT.ne_getNewsAbonnementFee(genreID, newSubscriptionLevels[i])
		if oldLevel ~= newSubscriptionLevels[genreID] then
			TVT.ne_setNewsAbonnement(genreID, newSubscriptionLevels[genreID])
			debugMsg("- Changing genre " ..genreID.. " abonnement level from " .. oldLevel .. " to " .. newSubscriptionLevels[genreID] .. " (new level=" .. TVT.ne_getNewsAbonnement(genreID) .. ")")
		else
			--debugMsg("- Keeping genre " ..genreID.. " abonnement level at " .. oldLevel)
		end
	end

	local newFees = TVT.ne_getTotalNewsAbonnementFees()

	-- subract new expenses
	if newFees ~= oldFees then
		debugMsg("- Adjusted news budget by " .. (newFees - oldFees) .. ". CurrentBudget=" .. self.Task.CurrentBudget)
		self.Task.CurrentBudget = self.Task.CurrentBudget - (newFees - oldFees)
	else
		--debugMsg("- News budget stays the same. CurrentBudget=" .. self.Task.CurrentBudget)
	end

	self.Status = JOB_STATUS_DONE
end


function JobNewsAgencyAbonnements:GetAbonnementLevel(abonnementCount, dividend)
	if (abonnementCount >= (dividend + 10)) then
		return 3
	elseif (abonnementCount >= (dividend + 5)) then
		return 2
	elseif (abonnementCount >= dividend) then
		return 1
	else
		return 0
	end
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
	debugMsg("Search best news for news show")

	-- RONNY 25.09.2016:
	-- disabled, all news are now returned by
	-- "GetNewsList()" and should be automatically removed from other
	-- slots upon placement

	-- instead of refreshing the news list each time we adjusted a slot
	-- (which might add back a previously send news to the collection which
	--  is still better than the other existing ones)
	-- we just unset all news right before placing the best 3 of them

	--TVT.ne_doRemoveNewsFromPlan(0, "")
	--TVT.ne_doRemoveNewsFromPlan(1, "")
	--TVT.ne_doRemoveNewsFromPlan(2, "")
end

function JobNewsAgency:Tick()
	local price = 0

	-- fetch a list of all news, sorted by attractivity
	-- and modified by a bonus for already paid news (so a news
	-- is preferred if just a bit less good but already paid)
	local newsList = self.GetNewsList(0.2)

	-- loop over all 3 slots
	for slot=1,3,1 do
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
						--debugMsg("- SKIP filling slot "..slot..". Already set there.")
					else
						if (news.IsPaid() == 1) then
							debugMsg("- filling slot "..slot..". Re-use news: \"" .. news.GetTitle() .. "\" (" .. news.GetGUID() .. ")")
						else
							debugMsg("- filling slot "..slot..". Buying news: \"" .. news.GetTitle() .. "\" (" .. news.GetGUID() .. ") "..slot.." - Price: " .. price)
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
			debugMsg("- filling slot "..slot..". No news available, skipping slot.")
		end
	end

	self.Status = JOB_STATUS_DONE
end

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
		table.insert(currentNewsList, news)
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
		table.insert(currentNewsList, news)
	end


	-- sort by attractivity modifed by paid-state-bonus
	local sortMethod = function(a, b)
		return a.GetAttractiveness()*(1.0 + a.IsPaid()*paidBonus) > b.GetAttractiveness()*(1.0 + b.IsPaid()*paidBonus)
	end
	table.sort(currentNewsList, sortMethod)

	return currentNewsList
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<