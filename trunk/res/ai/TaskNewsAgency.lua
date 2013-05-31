-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskNewsAgency = AITask:new{
	TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME;
	BudgetWeigth = 3
}

function TaskNewsAgency:typename()
	return "TaskNewsAgency"
end

function TaskNewsAgency:Activate()
	debugMsg("Starte Task 'TaskNewsAgency'")
	-- Was getan werden soll:
	self.NewsAgencyAbonnementsJob = JobNewsAgency:new()
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
}

function JobNewsAgencyAbonnements:Prepare(pParams)
	debugMsg("Job: JobNewsAgencyAbonnements")
end

function JobNewsAgencyAbonnements:Tick()
	self.Status = JOB_STATUS_DONE
--GetMyNewsBlocks


--GetNewsAbonnementPrice
	--local abbonnement = MY.GetNewsAbonnement(NEWS_GENRE_POLITICS)
	--MY.GetNewsAbonnement(NEWS_GENRE_SHOWBIZ)
	--MY.GetNewsAbonnement(NEWS_GENRE_SPORT)
	--MY.GetNewsAbonnement(NEWS_GENRE_TECHNICS)
	--MY.GetNewsAbonnement(NEWS_GENRE_CURRENTS)
	--SetNewsAbonnement
	
	--AddNewsBlock
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobNewsAgency = AIJob:new{
	Newslist = null
}

function JobNewsAgency:Prepare(pParams)
	debugMsg("Job: JobNewsAgency")
	self.Newslist = self.GetNewsList()
end

function JobNewsAgency:Tick()
	if (table.count(self.Newslist) > 0) then
		debugMsg("Do news in plan: " .. self.Newslist[1].id .. " -> 1")
		TVT.ne_doNewsInPlan(0)
		TVT.ne_doNewsInPlan(0, self.Newslist[1].id)
	end
	if (table.count(self.Newslist) > 1) then
		debugMsg("Do news in plan: " .. self.Newslist[2].id .. " -> 2")
		TVT.ne_doNewsInPlan(1)
		TVT.ne_doNewsInPlan(1, self.Newslist[2].id)
	end
	if (table.count(self.Newslist) > 2) then
		debugMsg("Do news in plan: " .. self.Newslist[3].id .. " -> 3")
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