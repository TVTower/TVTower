-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskStationMap"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME
	c.BudgetWeigth = 0
	c.BasePriority = 0
	--c.InvestmentPriority = 2
	c.NeededInvestmentBudget = 250000
	c.InvestmentWeigth = 3
end)

function TaskStationMap:typename()
	return "TaskStationMap"
end

function TaskStationMap:Activate()
	debugMsg(">>> Starte Task 'TaskStationMap'")
	-- Was getan werden soll:
	self.BuyStationJob = JobBuyStation()
	self.BuyStationJob.Task = self
end

function TaskStationMap:GetNextJobInTargetRoom()
	if (self.BuyStationJob.Status ~= JOB_STATUS_DONE) then
		return self.BuyStationJob
	end

	self.BasePriority = 0
	self:SetWait()
end

function TaskStationMap:BudgetSetup()
	if self.UseInvestment then
		self.BasePriority = 15
	else
		self.BasePriority = 0
	end
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
	--debugMsg("Prüfe Stationenkauf")
end

function JobBuyStation:Tick()
	debugMsg("Prüfe Stationenkauf! Verfügbares Budget: " .. self.Task.CurrentBudget)
	
	local bestOffer = nil
	local bestAttraction = 0
	
	for i = 1, 30 do
		local tempStation = MY.GetStationMap().getTemporaryStation(math.random(35, 560), math.random(1, 375))
		local price = tempStation.getPrice()
		local pricePerViewer = tempStation.getReachIncrease() / price
				
		--debugMsg("Prüfe Station " .. i .. "  " .. tempStation.pos.GetIntX() .. "/" .. tempStation.pos.GetIntY() .. " - R: " .. tempStation.getReach() .. " - Inc: " .. tempStation.getReachIncrease() .. " - Price: " .. tempStation.getPrice() .. " F: " .. pricePerViewer)
		
		if price <= self.Task.CurrentBudget and tempStation.getReachIncrease() > 5000 then -- Liegt im Budget und lohnt sich minimal
			local priceDiff = self.Task.CurrentBudget - price
			local attraction = pricePerViewer - (priceDiff / self.Task.CurrentBudget / 10)
			--debugMsg("Attraction: " .. attraction .. "     -> " .. pricePerViewer .. " - (" .. priceDiff .. " / " .. self.Task.CurrentBudget .. " / 10)")
		
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
		local price = bestOffer.getPrice()
		debugMsg("Kaufe Station " .. bestOffer.pos.GetIntX() .. "/" .. bestOffer.pos.GetIntY() .. " Inc: " .. bestOffer.getReachIncrease() .. " => Price: " .. price)
		TVT.addToLog("Kaufe Station " .. bestOffer.pos.GetIntX() .. "/" .. bestOffer.pos.GetIntY() .. " Inc: " .. bestOffer.getReachIncrease() .. " => Price: " .. price)
		TVT.of_buyStation(bestOffer.pos.GetIntX(), bestOffer.pos.GetIntY())
		self.Task:PayFromBudget(price)
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<