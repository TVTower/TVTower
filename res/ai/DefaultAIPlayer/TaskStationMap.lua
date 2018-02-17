-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskStationMap"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_STATIONMAP"]
	c.TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME
	c:ResetDefaults()
end)

function TaskStationMap:typename()
	return "TaskStationMap"
end

function TaskStationMap:ResetDefaults()
	self.BudgetWeight = 3
	self.BasePriority = 1
	self.NeededInvestmentBudget = 350000
	self.InvestmentPriority = 8
end

function TaskStationMap:Activate()
	-- Was getan werden soll:
	self.AdjustStationInvestmentJob = JobAdjustStationInvestment()
	self.AdjustStationInvestmentJob.Task = self
	
	self.BuyStationJob = JobBuyStation()
	self.BuyStationJob.Task = self
end

function TaskStationMap:GetNextJobInTargetRoom()
	if (self.BuyStationJob.Status == JOB_STATUS_DONE) then
		self:SetWait() --Wenn der Einkauf geklappt hat... muss nichs weiter gemacht werden.
	end

	if (self.BuyStationJob.Status ~= JOB_STATUS_DONE) then			
		return self.BuyStationJob
	elseif (self.AdjustStationInvestmentJob.Status ~= JOB_STATUS_DONE) then
		return self.AdjustStationInvestmentJob		
	end

--	self:SetWait()
	self:SetDone()
end

function TaskStationMap:BeforeBudgetSetup()
	self:SetFixedCosts()
end

function TaskStationMap:BudgetSetup()
	if self.UseInvestment then
		debugMsg("+++ Investition in TaskStationMap!")
		self.SituationPriority = 15
	end
end

function TaskStationMap:OnMoneyChanged(value, reason, reference)
	if (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_STATION)) then
		self:PayFromBudget(value)
		self:SetFixedCosts()
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.SELL_STATION)) then
		self:PayFromBudget(value)
		self:SetFixedCosts()
	elseif (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_STATIONFEES)) then
		self.FixedCosts = value
		--self.FixedCostsBudget = self.FixedCostsBudget - value
	end
end

function TaskStationMap:SetFixedCosts()
	self.FixedCosts = MY.GetStationMap().CalculateStationCosts()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobAdjustStationInvestment"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobAdjustStationInvestment:typename()
	return "JobAdjustStationInvestment"
end

function JobAdjustStationInvestment:Prepare(pParams)

end

function JobAdjustStationInvestment:Tick()
	debugMsg("JobAdjustStationInvestment: currentBudget=" .. self.Task.CurrentBudget .. "  neededInvestmentBudget"..NeededInvestmentBudget)
	if (self.Task.CurrentBudget < NeededInvestmentBudget) then
		self.Task.NeededInvestmentBudget = math.round(self.Task.NeededInvestmentBudget * 0.85 ) -- Nach jeder Überprüfung immer ein kleines bisschen günstiger.
	end

	-- require a minimum investment
	self.Task.NeededInvestmentBudget = math.max(400000, self.Task.NeededInvestmentBudget)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBuyStation"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobBuyStation:typename()
	return "JobBuyStation"
end

function JobBuyStation:Prepare(pParams)
	debugMsg("JobBuyStation: Prepare checking stations! current budget:" .. self.Task.CurrentBudget)
	-- ignore budgets and just buy a station if there is some need
	-- the more stations we have, the less likely this is called
	local player = _G["globalPlayer"]
	local ignoreBudgetChance = 100 - (8-player.ExpansionPriority)*math.min(TVT.of_getStationCount(TVT.ME)-1,10)
	debugMsg("  ignoreBudgetChance: " ..ignoreBudgetChance)
	if MY.GetMoney() > 1000000 and math.random(0,100) < ignoreBudgetChance then
		self.Task.CurrentBudget = (0.35 + 0.06*player.ExpansionPriority) * MY.GetMoney()
		debugMsg("  raised current budget to " .. self.Task.CurrentBudget .." to buy a station because 'we want it'.")
	end

	if (self.Task.CurrentBudget < self.Task.NeededInvestmentBudget) then
		debugMsg(" Cancel ... budget lower than needed investment budget")
		self:SetCancel()
	end
end

function JobBuyStation:SetCancel()
	self.Status = JOB_STATUS_DONE
	--call parent
	--AIJob.SetCancel(self)
end

function JobBuyStation:Tick()
	debugMsg("JobBuyStation: Checking stations! current budget:" .. self.Task.CurrentBudget)
	
	local bestOffer = nil
	local bestAttraction = 0
	
	for i = 1, 30 do
		local tempStation = MY.GetStationMap().GetTemporaryAntennaStation(math.random(35, 560), math.random(1, 375))
				
		debugMsg(" - Station " .. i .. "  at " .. tempStation.pos.GetIntX() .. "," .. tempStation.pos.GetIntY() .. ".  reach: " .. tempStation.GetReach() .. "  exclusive/increase: " .. tempStation.GetExclusiveReach() .. "  price: " .. tempStation.GetPrice() .. "  F: " .. (tempStation.GetExclusiveReach() / tempStation.GetPrice()))

		--filter criterias
		--0) skip checks if there is no tempstation
		if tempStation == nil then
			-- debugMsg("tempStation is nil!")
		--1) price to high
		elseif tempStation.GetPrice() > self.Task.CurrentBudget then
			tempStation = nil
		--2) relative increase to low (at least 20% required)
		elseif tempStation.GetRelativeExclusiveReach() < 0.25 then
			tempStation = nil

		--3) absolute increase too low
		--elseif tempStation.GetExclusiveReach() < 1500 then
		--	tempStation = nil

		--4)  reach to low (at least 75.000 required)
		elseif tempStation.GetReach() < 75000 then
			tempStation = nil
		end

		
		-- Liegt im Budget und lohnt sich minimal -> erfuellt Kriterien
		if tempStation ~= nil then
			local price = tempStation.GetPrice()
			local pricePerViewer = tempStation.GetExclusiveReach() / price
			local priceDiff = self.Task.CurrentBudget - price
			local attraction = pricePerViewer - (priceDiff / self.Task.CurrentBudget / 10)
			debugMsg("   attraction: " .. attraction .. "  |  ".. pricePerViewer .. " - (" .. priceDiff .. " / currentBudget: " .. self.Task.CurrentBudget)
		
			if bestOffer == nil then
				bestOffer = tempStation
			end
			if attraction > bestAttraction then
				bestOffer = tempStation
				bestAttraction = attraction
			end
		end		
	end
	
	if bestOffer ~= nil then
		local price = bestOffer.GetPrice()
		debugMsg(" Buying Station at " .. bestOffer.pos.GetIntX() .. "," .. bestOffer.pos.GetIntY() .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. price)
		TVT.of_buyAntennaStation(bestOffer.pos.GetIntX(), bestOffer.pos.GetIntY())
		self.Task:PayFromBudget(price)
		
		--next investment sum should be a bit bigger (TODO: make dependend from budget)
		local newBudget = math.round(((self.Task.NeededInvestmentBudget * 1.5) + (price * 2))/2)
		if (newBudget < self.Task.NeededInvestmentBudget * 1.15) then
			self.Task.NeededInvestmentBudget = self.Task.NeededInvestmentBudget * 1.15
		else
			self.Task.NeededInvestmentBudget = newBudget
		end
		debugMsg(" Next channel buy when reaching investment budget of " .. self.Task.NeededInvestmentBudget)
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<