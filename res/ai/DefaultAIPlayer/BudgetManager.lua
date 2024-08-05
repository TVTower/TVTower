-- File: BudgetManager

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BudgetManager"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	-- money to save for investments
	c.InvestmentSavings = 0
	-- budget at the time of last call to "UpdateBudget"
	c.BudgetOnLastUpdateBudget = 0
	c.CurrentFixedCosts = 0

	c.CurrentIncome = 0
	c.CurrentExpense = 0
	c.LastDayProfit = 0

	c:ResetDefaults()
end)

function BudgetManager:Log(message)
	logWithLevel(LOG_INFO, self.CurrentLogLevel, message)
end

function BudgetManager:typename()
	return "BudgetManager"
end


function BudgetManager:ResetDefaults()
	-- Percentage of the budget to save for investments
	self.SavingParts = 0.0
	-- Percentage to add on fixed costs "to make sure it is enough"
	self.ExtraFixedCostsSavingsPercentage = 0
	self.IgnoreMoneyChange = false
end


function BudgetManager:Initialize()
end

function BudgetManager:GetLastDayProfit()
	if self.LastDayProfit ~= nil then
		return self.LastDayProfit
	end
	return 0
end


-- Method is run at the begin of each day
function BudgetManager:CalculateNewDayBudget()
	if self.CurrentIncome == nil then
		self.CurrentIncome = 0
		self.CurrentExpense = 0
	end
	self.LastDayProfit = self.CurrentIncome - self.CurrentExpense
	self.CurrentIncome = 0
	self.CurrentExpense = 0

	--reset obsolete fields
	self.SavingParts = 0.0
	self.ExtraFixedCostsSavingsPercentage = 0
	self.InvestmentSavings = 0


	self.IgnoreMoneyChange = true
	self.CurrentLogLevel = LOG_INFO
	local money = getPlayer().money
	self:Log("=== Budget day " .. (TVT.GetDaysRun() + 1) .. " ===")
	self:Log(string.left("Account balance:", 25, true) .. string.right(money, 10, true))

	self:UpdateBudget(money)
	self:Log("======")
	self.IgnoreMoneyChange = false
end


function BudgetManager:UpdateBudget(money)
	--TODO move to Task itself?
	-- increase chances to go to boss for a credit
	local player = getPlayer()
	local bossTask = player.TaskList[TASK_BOSS]
	if bossTask ~= nil and bossTask.GuessCreditAvailable > 0 then
		if money < 100000 then
			bossTask.SituationPriority = 5
		elseif money <= 0 and player.hour > 5 then
			bossTask.SituationPriority = 15
		end
	end

	self:Log(string.left("Planned budget:", 25, true) .. string.right(money, 10, true))

	-- split budget across the different tasks
	self:AllocateBudgetToTasks(money)

	self.BudgetOnLastUpdateBudget = money
end

function BudgetManager:AllocateBudgetToTasks(money)
	local player = getPlayer()

	-- inform tasks about budget calculation
	for k,v in pairs(player.TaskList) do
		v:BeforeBudgetSetup()
	end

	-- sum up amount of budget units and sum up fix costs
	local budgetUnits = 0
	local allFixedCostsSavings = 0
	for k,v in pairs(player.TaskList) do
		budgetUnits = budgetUnits + v:getBudgetUnits()
		local taskFixCosts = v:GetFixedCosts()
		if taskFixCosts > 0 then
			self:Log(string.left(v:typename() .. " fix", 25, true) .. string.right(taskFixCosts, 10, true))
		end
		allFixedCostsSavings = allFixedCostsSavings + taskFixCosts
	end
	if budgetUnits == 0 then budgetUnits = 1 end

	self.CurrentFixedCosts = allFixedCostsSavings

	self:Log(string.left("Fixed costs:", 25, true) .. string.right(allFixedCostsSavings, 10, true))

	local hour = TVT:GetDayHour() -- player hour not updated yet
	local hourPart = 0
	if hour > 7 then
		hourPart = math.min(24, 4 + hour)/24
	end
	local safetyNet = 0
	if player.coverage ~= nil then
		if player.coverage > 0.6 then safetyNet = allFixedCostsSavings * 0.3 end
		if player.coverage > 0.8 then safetyNet = allFixedCostsSavings * 0.6 end
	end
	allFixedCostsSavings = safetyNet + math.round(allFixedCostsSavings * hourPart)

	self:Log(string.left("F.C.+reserve (for hour):", 25, true) .. string.right(allFixedCostsSavings, 10, true))

	-- define final budget
	local realBudget = money - allFixedCostsSavings
	self:Log(string.left("Savings:", 25, true) .. string.right(self.InvestmentSavings, 10, true))
	self:Log(string.left("Final budget:", 25, true) .. string.right(realBudget, 10, true))
	self:Log(string.right("=======", 35, true))


	local tasksForSurplusBudget = {}
	local surplusUnits = 0
	local surplusBudget = 0
	-- assign budgets to tasks
	local budgetUnitValue = realBudget / budgetUnits
	for k,v in pairs(player.TaskList) do
		--TODO subtract from budget what was already used up today
		--however this leaves unassigned money...
		--local alreadyUsed = v.BudgetWholeDay - v.CurrentBudget
		local maxBudget = v.BudgetMaximum()
		v.CurrentBudget = math.round(v.BudgetWeight * budgetUnitValue)
		if maxBudget >= 0 and v.CurrentBudget > maxBudget then
			surplusBudget = v.CurrentBudget - maxBudget
			v.CurrentBudget = maxBudget
		else 
			surplusUnits = surplusUnits + v:getBudgetUnits()
			table.insert(tasksForSurplusBudget, v)
		end
		v.BudgetWholeDay = v.CurrentBudget
	end

	if surplusBudget > 0 then
		local budgetUnitValue = surplusBudget / surplusUnits
		for k,v in pairs(tasksForSurplusBudget) do
			v.CurrentBudget = v.CurrentBudget + math.round(v.BudgetWeight * budgetUnitValue)
			v.BudgetWholeDay = v.CurrentBudget
		end
	end

	-- inform tasks for final budgets
	self:Log("Budget split:")
	for k,v in pairs(player.TaskList) do
		v.BudgetWholeDay = v.CurrentBudget
		v:BudgetSetup()
		if v.RequiresBudgetHandling == nil or v.RequiresBudgetHandling then
			self:Log(string.left(v:typename(), 25, true) .. string.right(v.BudgetWholeDay, 10, true))
		end
	end
end

function BudgetManager:OnMoneyChanged(value, reason, reference)
	if self.IgnoreMoneyChange == true then return end

	reason = tonumber(reason)
	self.CurrentLogLevel=LOG_DEBUG

	if (reference ~= nil) then
		self:Log("$$ Money changed (" .. TVT.Constants.PlayerFinanceEntryType.GetAsString(reason) ..") : " .. value .. " for \"" .. reference:GetTitle() .. "\"")
	else
		self:Log("$$ Money changed (" .. TVT.Constants.PlayerFinanceEntryType.GetAsString(reason) ..") : " .. value)
	end


	-- renewal of budget required?
	local renewBudget = false
	-- unplanned costs
	if (reason == TVT.Constants.PlayerFinanceEntryType.PAY_PENALTY) then renewBudget = true end
	-- or income
	if (reason == TVT.Constants.PlayerFinanceEntryType.CHEAT) then renewBudget = true end
	if (value > 0) then renewBudget = true end


	if renewBudget == true then
		local budgetNow = getPlayer().money

		--update budget when at least 15.000 Euro difference since last
		--adjustment
		if math.abs(self.BudgetOnLastUpdateBudget - budgetNow) > 15000 then
			self:UpdateBudget(budgetNow)

			self.BudgetOnLastUpdateBudget = budgetNow
		end
	end

	if self.CurrentIncome ~= nil then
		if value > 0 then 
			self.CurrentIncome = self.CurrentIncome + value
		else
			self.CurrentExpense = self.CurrentExpense - value
		end
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
