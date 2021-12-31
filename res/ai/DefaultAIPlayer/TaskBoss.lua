-- File: TaskBoss
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskBoss"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_BOSS"]
	c.TargetRoom = TVT.ROOM_BOSS_PLAYER_ME
	c.BudgetWeight = 0
	c.BasePriority = 1
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0

	c.GuessCreditAvailable = 100000
	c.TryToGetCredit = 0
	c.TryToRepayCredit = 0
	c.LastMoodLevel = 5
end)


function TaskBoss:typename()
	return "TaskBoss"
end


function TaskBoss:Activate()
	-- Was getan werden soll:
	self.CheckCreditJob = JobCheckCredit()
	self.CheckCreditJob.Task = self
end


function TaskBoss:GetNextJobInTargetRoom()
	if (self.CheckCreditJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckCreditJob
	end

	self:SetDone()
end


function TaskBoss:BeforeBudgetSetup()
	self:CalculateFixedCosts()
	self.InvestmentPriority = 0

	local money = TVT.GetMoney()
	local credit = MY.GetCredit(-1)
	if (money - credit) > 350000 then
		if credit > 100000 then
			self.NeededInvestmentBudget = credit / 5
			self.InvestmentPriority = 1
		elseif credit > 0 then
			self.NeededInvestmentBudget = credit
			self.InvestmentPriority = 1
		else
			self.NeededInvestmentBudget = 0
			self.CurrentInvestmentPriority = 0
		end
	elseif (money - credit) > 100000 then
		self.NeededInvestmentBudget = credit / 10
		self.InvestmentPriority = 1
	elseif (credit > 0) then
		self.NeededInvestmentBudget = 10000
	else
		self.NeededInvestmentBudget = 0
	end
end


function TaskBoss:OnMoneyChanged(value, reason, reference)
	reason = tonumber(reason)
	if (reason == TVT.Constants.PlayerFinanceEntryType.CREDIT_TAKE) then
		self:CalculateFixedCosts()
	elseif (reason == TVT.Constants.PlayerFinanceEntryType.CREDIT_REPAY) then
		self:CalculateFixedCosts()
	end
end


-- update value of fixed costs (eg. credit interest)
function TaskBoss:CalculateFixedCosts()
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
	if TVT.GetMoney() < 0 then
		-- ATTENTION: money might change until "tick()", we could handle
		-- it but this behaviour seems more "natural" (to not see the
		-- money change in time)
		-- negative balance typically when the day begins (fixed costs, failed contracts);
		-- try to achieve positive balance with minimal budget for buying news items
		self.Task.TryToGetCredit = math.min( math.abs(TVT.GetMoney()) + 100000, TVT.bo_getCreditAvailable() )
	end
	if self.Task.NeededInvestmentBudget > 0 then
		self.Task.TryToRepayCredit = math.max(0, math.min(TVT.GetMoney(), self.Task.NeededInvestmentBudget))
	end


	self.Task.GuessCreditAvailable = TVT.bo_getCreditAvailable()
	self.Task.LastMoodLevel = TVT.bo_getBossMoodlevel()
end


function JobCheckCredit:Tick()
	if self.Task.LastMoodLevel < 3 then
		TVT.addToLog("TODO: Boss in bad mood: " .. self.Task.LastMoodLevel)
	end

	-- REPAY credit
	if self.Task.TryToRepayCredit > 0 then
		local repay = self.Task.TryToRepayCredit
		if repay > MY.GetCredit(-1) then
			repay = MY.GetCredit(-1)
		end

		if TVT.bo_doRepayCredit(repay) == TVT.RESULT_OK then
			self.Task.TryToRepayCredit = self.Task.TryToRepayCredit - repay
			-- adjust budget
			self.Task.NeededInvestmentBudget = self.Task.NeededInvestmentBudget - repay
--			debugMsg("Repaid " .. repay .. " from credit to boss.")
		else
			debugMsg("FAILED to repay " .. repay .. " from credit to boss.")
		end

	-- TAKE credit
	elseif self.Task.TryToGetCredit > 0 then
		local credit = self.Task.TryToGetCredit
		if credit > self.Task.GuessCreditAvailable then
			credit = self.Task.GuessCreditAvailable
		end

		if credit > 0 then
			if TVT.bo_doTakeCredit(credit) == TVT.RESULT_OK then
--				debugMsg("Took a credit of " .. credit .." from boss.")
			else
				debugMsg("FAILED to get credit of " .. credit .." from boss.")
			end

			self.Task.TryToGetCredit = math.max(0, self.Task.TryToGetCredit - credit)
		end
	end
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--TODO: Auf schlechte Stimmung reagieren
