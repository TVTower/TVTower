-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskNewsAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME
	c.BudgetWeigth = 3
	c.BasePriority = 8
	c.AbonnementBudget = 0
end)

function TaskNewsAgency:typename()
	return "TaskNewsAgency"
end

function TaskNewsAgency:Activate()
	debugMsg(">>> Starte Task 'TaskNewsAgency'")
	-- Was getan werden soll:
	self.NewsAgencyAbonnementsJob = JobNewsAgencyAbonnements()
	self.NewsAgencyAbonnementsJob.Task = self

	self.NewsAgencyJob = JobNewsAgency()
	self.NewsAgencyJob.Task = self
end

function TaskNewsAgency:GetNextJobInTargetRoom()
	if (self.NewsAgencyAbonnementsJob.Status ~= JOB_STATUS_DONE) then
		return self.NewsAgencyAbonnementsJob
	end
	if (self.NewsAgencyJob.Status ~= JOB_STATUS_DONE) then
		return self.NewsAgencyJob
	end

	self:SetWait()
end

function TaskNewsAgency:BudgetSetup()
	local tempAbonnementBudget = self.BudgetWholeDay * 0.55
	self.AbonnementBudget = (tempAbonnementBudget - (tempAbonnementBudget % 10000))
	self.CurrentBudget = self.CurrentBudget - self.AbonnementBudget
	--debugMsg("BudgetSetup: AbonnementBudget: " .. self.AbonnementBudget .. "   - CurrentBudget: " .. self.CurrentBudget)
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
	debugMsg("Prüfe/Schließe Nachrichtenabonnements")
end

function JobNewsAgencyAbonnements:Tick()
	local abonnementCount = self.Task.AbonnementBudget / 10000

	MY.SetNewsAbonnement(TVT.NEWS_GENRE_POLITICS, self:GetAbonnementLevel(abonnementCount, TVT.NEWS_GENRE_POLITICS))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_SHOWBIZ, self:GetAbonnementLevel(abonnementCount, TVT.NEWS_GENRE_SHOWBIZ))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_SPORT, self:GetAbonnementLevel(abonnementCount, TVT.NEWS_GENRE_SPORT))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_TECHNICS, self:GetAbonnementLevel(abonnementCount, TVT.NEWS_GENRE_TECHNICS))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_CURRENTS, self:GetAbonnementLevel(abonnementCount, TVT.NEWS_GENRE_CURRENTS))

	--self.Task.CurrentBudget = self.Task.CurrentBudget - (abonnementCount * 10000)

	self.Status = JOB_STATUS_DONE
end

function JobNewsAgencyAbonnements:GetAbonnementLevel(abonnementCount, dividend)
	--debugMsg("dividend: " .. dividend .. " (" .. abonnementCount .. ")")
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
	c.Newslist = null
	c.Task = nil
end)

function JobNewsAgency:typename()
	return "JobNewsAgency"
end

function JobNewsAgency:Prepare(pParams)
	debugMsg("Bewerte/Kaufe Nachrichten")
	self.Newslist = self.GetNewsList()
end

function JobNewsAgency:Tick()
	--TODO: EInfache Lösung
	local price = 0

	if (table.count(self.Newslist) > 0) then
		price = self.Newslist[1].newsEvent.ComputePrice()
		if (self.Task.CurrentBudget >= price) then
			debugMsg("Kaufe Nachricht: " .. self.Newslist[1].GetTitle() .. " (" .. self.Newslist[1].id .. ") - Slot: 1 - Preis: " .. price)
			TVT.ne_doNewsInPlan(0)
			TVT.ne_doNewsInPlan(0, self.Newslist[1].id)
			self.Task.CurrentBudget = self.Task.CurrentBudget - price
		end
	end
	if (table.count(self.Newslist) > 1) then
		price = self.Newslist[2].newsEvent.ComputePrice()
		if (self.Task.CurrentBudget >= price) then
			debugMsg("Kaufe Nachricht: " .. self.Newslist[2].GetTitle() .. " (" .. self.Newslist[2].id .. ") - Slot: 2 - Preis: " .. price)
			TVT.ne_doNewsInPlan(1)
			TVT.ne_doNewsInPlan(1, self.Newslist[2].id)
			self.Task.CurrentBudget = self.Task.CurrentBudget - price
		end
	end
	if (table.count(self.Newslist) > 2) then
		price = self.Newslist[3].newsEvent.ComputePrice()
		if (self.Task.CurrentBudget >= price) then
			debugMsg("Kaufe Nachricht: " .. self.Newslist[3].GetTitle() .. " (" .. self.Newslist[3].id .. ") - Slot: 3 - Preis: " .. price)
			TVT.ne_doNewsInPlan(2)
			TVT.ne_doNewsInPlan(2, self.Newslist[3].id)
			self.Task.CurrentBudget = self.Task.CurrentBudget - price
		end
	end
	self.Status = JOB_STATUS_DONE
end

function JobNewsAgency:GetNewsList()
	local currentNewsList = {}

	for i = 0, MY.ProgrammeCollection.GetNewsCount() - 1 do
		local news = MY.ProgrammeCollection.GetNewsAtIndex(i)
		if (news.IsReadyToPublish() == 1) then
			table.insert(currentNewsList, news)
		end
	end

	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end
	table.sort(currentNewsList, sortMethod)

	return currentNewsList
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<