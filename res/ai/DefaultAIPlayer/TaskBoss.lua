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
	--self.LogLevel = LOG_TRACE
end


function TaskBoss:GetNextJobInTargetRoom()
	if (self.CheckCreditJob.Status ~= JOB_STATUS_DONE) then
		return self.CheckCreditJob
	end

	self:SetDone()
end


function TaskBoss:BeforeBudgetSetup()
	self:CalculateFixedCosts()
	self.InvestmentPriority = 1

	local money = getPlayer().money
	local credit = MY.GetCredit(-1)
	self.NeededInvestmentBudget = credit
	if credit == 0 then
		self.NeededInvestmentBudget = 0
		self.CurrentInvestmentPriority = 0
		self.InvestmentPriority = 0
	elseif (money - credit) > 3000000 then
		if credit > 300000 then
			self.NeededInvestmentBudget = credit / 5
		end
	elseif (money - credit) > 350000 then
		if credit > 100000 then
			self.NeededInvestmentBudget = credit / 5
		end
	elseif (money - credit) > 100000 then
		self.NeededInvestmentBudget = credit / 10
	else
		self.InvestmentPriority = 0
		self.NeededInvestmentBudget = 10000
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
	local player = getPlayer()
	local money = player.money
	local creditAvailable = TVT.bo_getCreditAvailable()
	self.Task.TryToGetCredit = 0
	if money < -30000 and player.hour > 5 then
		-- ATTENTION: money might change until "tick()", we could handle
		-- it but this behaviour seems more "natural" (to not see the
		-- money change in time)
		-- negative balance typically when the day begins (fixed costs, failed contracts);
		-- try to achieve positive balance with minimal budget for buying news items
		self.Task.TryToGetCredit = math.min( math.abs(money) + 100000, creditAvailable)
	end
	if self.Task.NeededInvestmentBudget > 0 then
		self.Task.TryToRepayCredit = math.max(0, math.min(money, self.Task.NeededInvestmentBudget))
	end
	if MY.GetCredit(-1) == 0 and player.hour < 6 then
		self.Task.TryToRepayCredit = 0
		local stationTask = player.TaskList[TASK_STATIONMAP]
		--get credit and increase chance for good investment
		if stationTask ~= nil and stationTask.maxReachIncrease ~=  nil and stationTask.maxReachIncrease < 0 then
			--no credit necessary for station purchase
		else
			self.Task.TryToGetCredit = creditAvailable
		end
	end


	self.Task.GuessCreditAvailable = creditAvailable
	self.Task.LastMoodLevel = TVT.bo_getBossMoodlevel()
end


function JobCheckCredit:Tick()
	if self.Task.LastMoodLevel < 3 then
		self:LogDebug("TODO: Boss in bad mood: " .. self.Task.LastMoodLevel)
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
			self:LogDebug("Repaid " .. repay .. " from credit to boss.")
		else
			self:LogError("FAILED to repay " .. repay .. " from credit to boss.")
		end

	-- TAKE credit
	elseif self.Task.TryToGetCredit > 0 then
		local credit = self.Task.TryToGetCredit
		if credit > self.Task.GuessCreditAvailable then
			credit = self.Task.GuessCreditAvailable
		end

		if credit > 0 then
			if TVT.bo_doTakeCredit(credit) == TVT.RESULT_OK then
				self:LogInfo("Took a credit of " .. credit .." from boss.")
			else
				self:LogError("FAILED to get credit of " .. credit .." from boss.")
			end

			self.Task.TryToGetCredit = math.max(0, self.Task.TryToGetCredit - credit)
		end
	end
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--TODO: Auf schlechte Stimmung reagieren
