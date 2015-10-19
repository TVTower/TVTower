-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskNewsAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME
	c.BudgetWeight = 3
	c.BasePriority = 8
	c.AbonnementBudget = 0
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

	self:SetWait()
end

--override
function TaskNewsAgency:getStrategicPriority()
	-- adjust priority according to player character
	local player = _G["globalPlayer"]
	if player.NewsPriority > 7 then
		return 1.25
	elseif player.NewsPriority >= 6 then
		return 1.15
	elseif player.NewsPriority >= 5 then
		return 1.0
	end

	return 0.9
end


function TaskNewsAgency:BeforeBudgetSetup()
	self:SetFixedCosts()

	-- adjust budget weighting according to player character
	local player = _G["globalPlayer"]

	if player.NewsPriority > 7 then
		self.BudgetWeight = 6 
	elseif player.NewsPriority >= 6 then
		self.BudgetWeight = 5 
	elseif player.NewsPriority >= 5 then
		self.BudgetWeight = 4 
	else
		self.BudgetWeight = 2
	end 
end

function TaskNewsAgency:BudgetSetup()
	local tempAbonnementBudget = self.BudgetWholeDay * 0.55
	self.AbonnementBudget = (tempAbonnementBudget - (tempAbonnementBudget % 10000))
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
		return 250000
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
	self.FixedCosts = MY.GetNewsAbonnementFees()
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
	debugMsg("Schau nach Terror-News")
end

function JobCheckEventNews:Tick()
	local terrorLevel = TVT.ne_getTerroristAggressionLevel()
	local maxTerrorLevel = TVT.ne_getTerroristAggressionLevelMax()

	if terrorLevel >= 4 then
		kiMsg("Terroranschlag geplant! Terror-Level: " .. terrorLevel)
	end	
	
	local player = _G["globalPlayer"] --Zugriff die globale Variable
	if player.TaskList[TASK_ROOMBOARD] ~= nil then
		local roomBoardTask = player.TaskList[TASK_ROOMBOARD]	
		if terrorLevel >= 2 then	
			roomBoardTask.SituationPriority = terrorLevel * terrorLevel						
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
	--debugMsg("Prüfe/Schließe Nachrichtenabonnements")
end

function JobNewsAgencyAbonnements:Tick()
	-- how many different abonnements could we sign?
	local abonnementCount = self.Task.AbonnementBudget / 10000

	--set abonnements for all available news genres
	for i = 0, TVT.Constants.NewsGenre.count - 1 do
		local level = self:GetAbonnementLevel(abonnementCount, i)
		MY.SetNewsAbonnement(TVT.Constants.NewsGenre.GetAtIndex(i), level)
		debugMsg("Bestelle Nachrichtenabonnement: " .. TVT.Constants.NewsGenre.GetAtIndex(i) .. " Level: " .. level)
	end
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
	--debugMsg("Bewerte/Kaufe Nachrichten")
	self.Newslist = self.GetNewsList()
end

function JobNewsAgency:Tick()
	--TODO: EInfache Lösung
	local price = 0

	if (table.count(self.Newslist) > 0) then
		price = self.Newslist[1].GetPrice()
		if (self.Task.CurrentBudget >= price) then			
			debugMsg("Kaufe Nachricht: " .. self.Newslist[1].GetTitle() .. " (" .. self.Newslist[1].GetID() .. ") - Slot: 1 - Preis: " .. price)
			TVT.addToLog("Kaufe Nachricht: " .. self.Newslist[1].GetTitle() .. " (" .. self.Newslist[1].GetID() .. ") - Slot: 1 - Preis: " .. price)
			TVT.ne_doNewsInPlan(0)
			TVT.ne_doNewsInPlan(0, self.Newslist[1].GetID())
			--self.Task:PayFromBudget(price)
		end
	end
	if (table.count(self.Newslist) > 1) then
		price = self.Newslist[2].GetPrice()
		if (self.Task.CurrentBudget >= price) then
			debugMsg("Kaufe Nachricht: " .. self.Newslist[2].GetTitle() .. " (" .. self.Newslist[2].GetID() .. ") - Slot: 2 - Preis: " .. price)
			TVT.addToLog("Kaufe Nachricht: " .. self.Newslist[2].GetTitle() .. " (" .. self.Newslist[2].GetID() .. ") - Slot: 2 - Preis: " .. price)
			TVT.ne_doNewsInPlan(1)
			TVT.ne_doNewsInPlan(1, self.Newslist[2].GetID())
			--self.Task:PayFromBudget(price)
		end
	end
	if (table.count(self.Newslist) > 2) then
		price = self.Newslist[3].GetPrice()
		if (self.Task.CurrentBudget >= price) then
			debugMsg("Kaufe Nachricht: " .. self.Newslist[3].GetTitle() .. " (" .. self.Newslist[3].GetID() .. ") - Slot: 3 - Preis: " .. price)
			TVT.addToLog("Kaufe Nachricht: " .. self.Newslist[3].GetTitle() .. " (" .. self.Newslist[3].GetID() .. ") - Slot: 3 - Preis: " .. price)
			TVT.ne_doNewsInPlan(2)
			TVT.ne_doNewsInPlan(2, self.Newslist[3].GetID())
			--self.Task:PayFromBudget(price)
		end
	end
	self.Status = JOB_STATUS_DONE
end

function JobNewsAgency:GetNewsList()
	local currentNewsList = {}

	for i = 0, MY.GetProgrammeCollection().GetNewsCount() - 1 do
		local news = MY.GetProgrammeCollection().GetNewsAtIndex(i)
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