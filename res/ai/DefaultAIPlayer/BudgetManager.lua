-- File: BudgetManager
TIME_TODAY		= "T"
TIME_OLDDAY_1	= "1"
TIME_OLDDAY_2	= "2"
TIME_OLDDAY_3	= "3"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BudgetManager"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	-- previous days budgets
	c.BudgetHistory = {}
	-- previous days account balances
	c.AccountBalanceHistory = {}
	-- money to save for investments
	c.InvestmentSavings = 0
	-- budget at the time of last call to "UpdateBudget"
	c.BudgetOnLastUpdateBudget = 0


	c:ResetDefaults()
end)


function BudgetManager:typename()
	return "BudgetManager"
end


function BudgetManager:ResetDefaults()
	-- Minimum value of the budgets
	self.BudgetMinimum = 0
	-- Maximum value of the budget
	self.BudgetMaximum = 0
	-- Percentage of the budget to save for investments
	self.SavingParts = 0.3
	-- Percentage to add on fixed costs "to make sure it is enough"
	self.ExtraFixedCostsSavingsPercentage = 0.5
end


function BudgetManager:Initialize()
	-- Right at start there are no empirical values for required budgets
	-- so assume the same for all of them. Budget equals to XX% of
	-- capital at begin of the game
	local playerMoney = MY.GetMoney()
	local startBudget = math.round(playerMoney * 0.90)


	-- initialize budget history
	self.BudgetHistory = {}
	self.BudgetHistory[TIME_OLDDAY_3] = startBudget
	self.BudgetHistory[TIME_OLDDAY_2] = startBudget
	self.BudgetHistory[TIME_OLDDAY_1] = startBudget
	self.BudgetHistory[TIME_TODAY] = startBudget


	-- initialize account history
	self.AccountBalanceHistory = {}
	self.AccountBalanceHistory[TIME_OLDDAY_3] = playerMoney
	self.AccountBalanceHistory[TIME_OLDDAY_2] = playerMoney
	self.AccountBalanceHistory[TIME_OLDDAY_1] = playerMoney
	self.AccountBalanceHistory[TIME_TODAY] = playerMoney


	-- define minimal and maximal budget
	self.BudgetMinimum = math.round(playerMoney * 0.4)
	self.BudgetMaximum = math.round(playerMoney * 0.8)
end


-- Method is run at the begin of each day
function BudgetManager:CalculateNewDayBudget()
	debugMsg("=== Budget day " .. TVT.GetDaysRun() .. " ===")
	debugMsg(string.left("Account balance:", 25, true) .. string.right(MY.GetMoney(), 10, true))

	-- postpone empirical budget values one day backwards (new one incoming)
	self.BudgetHistory[TIME_OLDDAY_3] = self.BudgetHistory[TIME_OLDDAY_2]
	self.BudgetHistory[TIME_OLDDAY_2] = self.BudgetHistory[TIME_OLDDAY_1]
	self.BudgetHistory[TIME_OLDDAY_1] = self.BudgetHistory[TIME_TODAY]

	-- postpone account values one day backwards (new one incoming)
	self.AccountBalanceHistory[TIME_OLDDAY_3] = self.AccountBalanceHistory[TIME_OLDDAY_2]
	self.AccountBalanceHistory[TIME_OLDDAY_2] = self.AccountBalanceHistory[TIME_OLDDAY_1]
	self.AccountBalanceHistory[TIME_OLDDAY_1] = self.AccountBalanceHistory[TIME_TODAY]

	-- update current values
	self.AccountBalanceHistory[TIME_TODAY] = MY.GetMoney()
	self.BudgetMinimum = self.BudgetMinimum * 1.01
	self.BudgetMaximum = self.AccountBalanceHistory[TIME_TODAY] * 0.95


	-- yesterdays turnover
	-- TODO: instead of self.BudgetHistory[TIME_OLDDAY_1] one could use the real
	--       expenses of yesterday.
	local YesterdayTurnOver = self.AccountBalanceHistory[TIME_TODAY] - (self.AccountBalanceHistory[TIME_OLDDAY_1] - self.BudgetHistory[TIME_OLDDAY_1])


	-- find new budget for today (based on experience/history)
	self.BudgetHistory[TIME_TODAY] = self:CalculateAverageBudget(self.AccountBalanceHistory[TIME_TODAY], YesterdayTurnOver)
	self.BudgetHistory[TIME_TODAY] = math.clamp(self.BudgetHistory[TIME_TODAY], self.BudgetMinimum, self.BudgetMaximum)

	self:UpdateBudget(self.BudgetHistory[TIME_TODAY])
	debugMsg("======")
end


function BudgetManager:UpdateBudget(pBudget)
	-- increase chances to go to boss for a credit
	local player = _G["globalPlayer"]
	local bossTask = player.TaskList[TASK_BOSS]
	if bossTask ~= nil and bossTask.GuessCreditAvailable > 0 then
		if MY.GetMoney() < 100000 then
			bossTask.SituationPriority = 5
		elseif MY.GetMoney() < 0 then
			bossTask.SituationPriority = 15
		end
	end

	debugMsg(string.left("Planned budget:", 25, true) .. string.right(pBudget, 10, true))
	self:CutInvestmentSavingIfNeeded(pBudget)

	-- split budget across the different tasks
	self:AllocateBudgetToTasks(pBudget)

	self.BudgetOnLastUpdateBudget = pBudget
end


function BudgetManager:CutInvestmentSavingIfNeeded(pBudget)
	local player = _G["globalPlayer"]

	-- saved too much? Use savings or take credit
	if (pBudget * 0.8) < self.InvestmentSavings then
		debugMsg("Cutting investment savings: " .. self.InvestmentSavings .. ". Budget only at " .. pBudget .. ". Savings getting halved." )
		self.InvestmentSavings = self.InvestmentSavings / 2
	end

	-- saved too much? Use savings or take credit
	if (pBudget * 0.6) < self.InvestmentSavings then
		debugMsg("Totally get rid of investment savings. Savings: " .. self.InvestmentSavings .. ". Budget only at " .. pBudget .. ".")
		self.InvestmentSavings = 0
	end

	return savings
end


function BudgetManager:CalculateAverageBudget(pCurrentAccountBalance, pTurnOver)
	--debugMsg("A1.1: " .. pTurnOver); debugMsg("AX.1: " .. self.BudgetHistory[TIME_OLDDAY_1]); debugMsg("AX.2: " .. self.BudgetHistory[TIME_OLDDAY_2]); debugMsg("AX.3: " .. self.BudgetHistory[TIME_OLDDAY_3])

	-- sum all experiences/history values, weight by a factor and divide by 10. (4 + 3 + 2 + 1) / 10
	local TempSum = ((pTurnOver * 4) + (self.BudgetHistory[TIME_OLDDAY_1] * 3) + (self.BudgetHistory[TIME_OLDDAY_2] * 2) + (self.BudgetHistory[TIME_OLDDAY_3] * 1)) / 10
	-- is current account balance big enough to finance the calculated budget?
	if pCurrentAccountBalance > (TempSum / 2) then
		-- increase budget by 0-9%
		-- TODO: adjust random value by "level" and riskyness (individual character)
		TempSum = TempSum + (pCurrentAccountBalance * ((math.random(10)-1)/100))
	end
	return math.round(TempSum, -3)
end


function BudgetManager:AllocateBudgetToTasks(pBudget)
	local player = _G["globalPlayer"]

	-- inform tasks about budget calculation
	for k,v in pairs(player.TaskList) do
		v:BeforeBudgetSetup()
	end


	-- sum up amount of budget units and sum up fix costs
	local budgetUnits = 0
	local allFixedCostsSavings = 0
	for k,v in pairs(player.TaskList) do
		budgetUnits = budgetUnits + v:getBudgetUnits()
		debugMsg(string.left(v:typename() .. " fix", 25, true) .. string.right(v:GetFixedCosts(), 10, true))
		allFixedCostsSavings = allFixedCostsSavings + v:GetFixedCosts()
	end
	if budgetUnits == 0 then budgetUnits = 1 end


	debugMsg(string.left("Fixed costs:", 25, true) .. string.right(allFixedCostsSavings, 10, true))
	--TODO: character riskyness defines how much to save "extra"
	allFixedCostsSavings = allFixedCostsSavings * (1 + self.ExtraFixedCostsSavingsPercentage)
	debugMsg(string.left("Fixed costs + reserve:", 25, true) .. string.right(allFixedCostsSavings, 10, true))


	-- Increase savings and define real budget to spend.
	local tempBudget = pBudget - self.InvestmentSavings - allFixedCostsSavings
	-- Save a bit
	self.InvestmentSavings = self.InvestmentSavings + math.round(tempBudget * self.SavingParts)
	-- define final budget
	local realBudget = pBudget - self.InvestmentSavings - allFixedCostsSavings
	debugMsg(string.left("Savings:", 25, true) .. string.right(self.InvestmentSavings, 10, true))
	debugMsg(string.left("Final budget:", 25, true) .. string.right(realBudget, 10, true))
	debugMsg(string.right("=======", 35, true))


	-- assign budgets to tasks
	local budgetUnitValue = realBudget / budgetUnits
	for k,v in pairs(player.TaskList) do
		v.CurrentBudget = math.round(v.BudgetWeight * budgetUnitValue)
		if v.BudgetMaximum() >= 0 then
			v.CurrentBudget = math.min(v.CurrentBudget, v.BudgetMaximum())
		end
		v.BudgetWholeDay = v.CurrentBudget
	end


	-- check for investments
	local investTask = self:GetTaskForInvestment(player.TaskList)
	if (investTask ~= nil) then
--		debugMsg(investTask:typename() .. "- Use Investment: " .. self.InvestmentSavings)
		investTask.CurrentBudget = investTask.CurrentBudget + self.InvestmentSavings
		investTask.UseInvestment = true
		investTask.CurrentInvestmentPriority = 0
	end

	-- inform tasks for final budgets
	debugMsg("Budget split:")
	for k,v in pairs(player.TaskList) do
		v.BudgetWholeDay = v.CurrentBudget
		v:BudgetSetup()
		if v.RequiresBudgetHandling == nil or v.RequiresBudgetHandling then
			debugMsg(string.left(v:typename(), 25, true) .. string.right(v.BudgetWholeDay, 10, true))
		end
	end
end


function BudgetManager:GetTaskForInvestment(tasks)
	local taskSorted = SortTasksByInvestmentPrio(tasks)
	local rank = 1
	local highestPrio = nil

	for k,v in pairs(taskSorted) do
		if highestPrio == nil then
			highestPrio = v
			if self:IsTaskReadyForInvestment(v, rank) then
				return v
			end
		else
			if self:IsTaskReadyForInvestment(v, rank, highestPrio) then
				return v
			end
		end
		rank = rank + 1
		if rank > 3 then return nil end
	end
	return nil
end


function BudgetManager:IsTaskReadyForInvestment(task, rank, highestPrioTask)
	if rank == nil then rank = 1 end

	-- 1. condition: enough money saved for this task
	if (self.InvestmentSavings + task.BudgetWholeDay) >= task.NeededInvestmentBudget then
		-- 2. condition: priority is high enough
		if task.CurrentInvestmentPriority >= rank * 10 then
			-- 3. condition: Distance to top priority task isn't too big
			local prioOfHighest = task.CurrentInvestmentPriority
			if highestPrioTask ~= nil then
				prioOfHighest = highestPrioTask.CurrentInvestmentPriority
			end

			if prioOfHighest - task.CurrentInvestmentPriority <= 30 then
				-- 4. condition: Savings / required invest of the top task <= 0.8
				if highestPrioTask ~= nil then
					if (self.InvestmentSavings / highestPrioTask.NeededInvestmentBudget <= 0.8) then
						return true
					end
				else
					return true
				end
			end
		end
	end
	return false
end


function BudgetManager:OnMoneyChanged(value, reason, reference)
	reason = tonumber(reason)
	value = tonumber(value)

	if (reference ~= nil) then
		debugMsg("$$ Money changed (" .. TVT.Constants.PlayerFinanceEntryType.GetAsString(reason) ..") : " .. value .. " for \"" .. reference:GetTitle() .. "\"")
	else
		debugMsg("$$ Money changed (" .. TVT.Constants.PlayerFinanceEntryType.GetAsString(reason) ..") : " .. value)
	end


	-- renewal of budget required?
	local renewBudget = false
	-- unplanned costs
	if (reason == TVT.Constants.PlayerFinanceEntryType.PAY_PENALTY) then renewBudget = true end
	-- or income
	if (reason == TVT.Constants.PlayerFinanceEntryType.CHEAT) then renewBudget = true end
	if (value > 0) then renewBudget = true end


	if renewBudget == true then
		-- do not allow a negative profit
		local todaysProfit = math.max(0, MY.GetFinance(-1).GetCurrentProfit())
		local budgetNow = self:CalculateAverageBudget(MY.GetMoney(), todaysProfit)

		--update budget when at least 15.000 Euro difference since last
		--adjustment
		if math.abs(self.BudgetOnLastUpdateBudget - budgetNow) > 15000 then
			--debugMsg("Profit today: " .. todaysProfit)
			--debugMsg("Budget now: " .. budgetNow)
			--self:UpdateBudget(todaysProfit)
			self:UpdateBudget(budgetNow)

			self.BudgetOnLastUpdateBudget = budgetNow
		end
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
