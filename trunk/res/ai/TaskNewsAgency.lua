-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskNewsAgency = AITask:new{
	TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME;
	BudgetWeigth = 3;
	BasePriority = 8
}

function TaskNewsAgency:typename()
	return "TaskNewsAgency"
end

function TaskNewsAgency:Activate()
	debugMsg(">>> Starte Task 'TaskNewsAgency'")
	-- Was getan werden soll:
	self.NewsAgencyAbonnementsJob = JobNewsAgencyAbonnements:new()
	self.NewsAgencyAbonnementsJob.Task = self
	
	self.NewsAgencyJob = JobNewsAgency:new()
end

function TaskNewsAgency:GetNextJobInTargetRoom()
	if (self.NewsAgencyAbonnementsJob.Status ~= JOB_STATUS_DONE) then
		return self.NewsAgencyAbonnementsJob
	end
	if (self.NewsAgencyJob.Status ~= JOB_STATUS_DONE) then
		return self.NewsAgencyJob
	end
	
	self:SetDone()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobNewsAgencyAbonnements = AIJob:new{
	Task = nil
}

function JobNewsAgencyAbonnements:Prepare(pParams)
	debugMsg("Prüfe/Schließe Nachrichtenabonnements")	
end

function JobNewsAgencyAbonnements:Tick()
	local abonnementBudget = self.Task.BudgetWholeDay * 0.5
	local abonnementCount = (abonnementBudget - (abonnementBudget % 10000)) / 10000
	
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_POLITICS, self:GetAbonnementLevel(abonnementCount, 1))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_SHOWBIZ, self:GetAbonnementLevel(abonnementCount, 2))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_SPORT, self:GetAbonnementLevel(abonnementCount, 3))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_TECHNICS, self:GetAbonnementLevel(abonnementCount, 4))
	MY.SetNewsAbonnement(TVT.NEWS_GENRE_CURRENTS, self:GetAbonnementLevel(abonnementCount, 5))
	
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
JobNewsAgency = AIJob:new{
	Newslist = null
}

function JobNewsAgency:Prepare(pParams)
	debugMsg("Bewerte/Kaufe Nachrichten")
	self.Newslist = self.GetNewsList()
end

function JobNewsAgency:Tick()
	--TODO: EInfache Lösung	
	if (table.count(self.Newslist) > 0) then
		debugMsg("Kaufe Nachricht: " .. self.Newslist[1].news.title .. " (" .. self.Newslist[1].id .. ") - Slot: 1 - Preis: " .. self.Newslist[1].news.ComputePrice())
		TVT.ne_doNewsInPlan(0)
		TVT.ne_doNewsInPlan(0, self.Newslist[1].id)
	end
	if (table.count(self.Newslist) > 1) then
		debugMsg("Kaufe Nachricht: " .. self.Newslist[2].news.title .. " (" .. self.Newslist[2].id .. ") - Slot: 2 - Preis: " .. self.Newslist[2].news.ComputePrice())
		TVT.ne_doNewsInPlan(1)
		TVT.ne_doNewsInPlan(1, self.Newslist[2].id)
	end
	if (table.count(self.Newslist) > 2) then
		debugMsg("Kaufe Nachricht: " .. self.Newslist[3].news.title .. " (" .. self.Newslist[3].id .. ") - Slot: 3 - Preis: " .. self.Newslist[3].news.ComputePrice())
		TVT.ne_doNewsInPlan(2)
		TVT.ne_doNewsInPlan(2, self.Newslist[3].id)
	end
	self.Status = JOB_STATUS_DONE
end

function JobNewsAgency:GetNewsList()
	local currentNewsList = {}	
	
	for i = 0, MY.ProgrammePlan.GetNewsCount() - 1 do
		local news = MY.ProgrammePlan.GetNewsFromList(i)
		if (news.IsReadyToPublish() == 1) then
			table.insert(currentNewsList, news)
		end
	end
	
	local sortMethod = function(a, b)
		return a.news.GetAttractiveness() > b.news.GetAttractiveness()
	end
	table.sort(currentNewsList, sortMethod)	
	
	return currentNewsList
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<