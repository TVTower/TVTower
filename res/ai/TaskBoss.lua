-- File: TaskBoss
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskBoss"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_BOSS_PLAYER_ME
	c.BudgetWeigth = 0
	c.BasePriority = 2
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0
	
	c.GuessCreditAvailable = 100000
	c.TryToGetCredit = 0
	c.LastMoodLevel = 5
end)

function TaskBoss:typename()
	return "TaskBoss"
end

function TaskBoss:Activate()
	debugMsg(">>> Starte Task 'TaskBoss'")
	-- Was getan werden soll:
	self.CheckCreditJob = JobCheckCredit()
	self.CheckCreditJob.Task = self
end

function TaskBoss:GetNextJobInTargetRoom()
	if (self.CheckCreditJob.Status == JOB_STATUS_DONE) then
		self:SetWait() --Wenn der Einkauf geklappt hat... muss nichs weiter gemacht werden.
	end

	if (self.CheckCreditJob.Status ~= JOB_STATUS_DONE) then			
		return self.CheckCreditJob
	end

	self:SetWait()
end

function TaskBoss:BeforeBudgetSetup()
	self:SetFixedCosts()

	local money = MY.GetCredit()
	local credit = MY.GetCredit()
	if (money - credit) > 500000 then	
		local credit = MY.GetCredit()
		if credit > 100000 then
			self.NeededInvestmentBudget = 100000
			self.InvestmentPriority = 1
		elseif credit > 0 then
			self.NeededInvestmentBudget = credit
			self.InvestmentPriority = 1
		else
			self.NeededInvestmentBudget = 0
			self.InvestmentPriority = 0
			self.CurrentInvestmentPriority = 0
		end
	else
		self.NeededInvestmentBudget = 0
		self.InvestmentPriority = 0
	end
end

function TaskBoss:OnMoneyChanged(value, reason, reference)
	if (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.CREDIT_TAKE)) then
		self:SetFixedCosts()
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.CREDIT_REPAY)) then
		self:SetFixedCosts()
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_CREDITINTEREST)) then
		self.FixedCosts = value	
	end
end

function TaskBoss:SetFixedCosts()
	self.FixedCosts = MY.GetCreditInterest()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobCheckCredit"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobCheckCredit:typename()
	return "JobCheckCredit"
end

function JobCheckCredit:Prepare(pParams)

end

function JobCheckCredit:Tick()
	self.Task.LastMoodLevel = TVT.bo_getBossMoodlevel()
	if self.Task.LastMoodLevel < 3 then
		TVT.addToLog("TODO: BOss hat schlechte Laune: " .. self.Task.LastMoodLevel)
	end

	self.Task.GuessCreditAvailable = TVT.bo_getCreditAvailable()

	if self.Task.TryToGetCredit > 0 then
		local credit = self.Task.TryToGetCredit
		if credit > self.Task.GuessCreditAvailable then
			credit = self.Task.GuessCreditAvailable
			if credit > 0 then
				TVT.bo_doTakeCredit(credit)
				TVT.addToLog("Nehme Kredit auf: " .. credit)
			end
		end
	end
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--TODO: Auf schlechte Stimmung reagieren