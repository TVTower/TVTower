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

	self.knownAntennaPositions = {}
	self.knownSatelliteUplinks = {}
	self.knownCableNetworkUplinks = {}
end

function TaskStationMap:Activate()
	self.AnalyseStationMarketJob = JobAnalyseStationMarket()
	self.AnalyseStationMarketJob.Task = self

	self.AdjustStationInvestmentJob = JobAdjustStationInvestment()
	self.AdjustStationInvestmentJob.Task = self

	self.BuyStationJob = JobBuyStation()
	self.BuyStationJob.Task = self
end

function TaskStationMap:GetNextJobInTargetRoom()
	if (self.AnalyseStationMarketJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyseStationMarketJob
--	elseif (self.BuyStationJob.Status == JOB_STATUS_DONE) then
--		self:SetWait() --Wenn der Einkauf geklappt hat... muss nichs weiter gemacht werden.
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


function TaskStationMap:GetAverageStationRunningCostPerPerson()
	local totalCost = 0
	local totalReach = 0
	local stationCount = TVT.of_getStationCount(TVT.ME)

	debugMsg("TaskStationMapJob.GetAverageStationRunningCostPerPerson")
	debugMsg("Owning " .. stationCount .. " stations.")
	if stationCount > 0 then
		for stationIndex = 0, stationCount-1 do
			local station = TVT.of_getStationAtIndex(i, stationIndex)
			if station ~= nil then
				totalCost = totalCost + station.GetRunningCosts()
				totalReach = totalReach + station.GetExclusiveReach()
				--totalReach = totalReach + station.GetReach()
			end
		end
	end

	return totalCost/totalReach
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobAnalyseStationMarket"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobAnalyseStationMarket:typename()
	return "JobAnalyseStationMarket"
end

function JobAnalyseStationMarket:Prepare(pParams)

end

function JobAnalyseStationMarket:Tick()
	debugMsg("JobAnalyseStationMarket: checking stations of other players")

	local player = _G["globalPlayer"]

	-- fetch positions of other players stations, cable network uplinks
	-- and satellite uplinks
	-- reset known
	self.Task.knownAntennaPositions = {}

	for i = 1, 4 do
		local positions = {}
		local cableNetworkUplinkProviders = {}
		local satelliteUplinkProviders = {}
		if i ~= TVT.ME then
			local stationCount = TVT.of_getStationCount(i)
			--debugMsg("JobAnalyseStationMarket: player " .. i .. " has " .. stationCount .. " stations.")
			if stationCount > 0 then
				for stationIndex = 0, stationCount-1 do
					local station = TVT.of_getStationAtIndex(i, stationIndex)
					if station ~= nil then

						if station.IsAntenna() == 1 then
							--store x,y and owner
							table.insert(positions, {station.pos.GetX(), station.pos.GetY(), i})
							--debugMsg("JobAnalyseStationMarket: player " .. i .. " has an antenna at " .. station.pos.GetX() .."/".. station.pos.GetY())
						elseif station.IsCableNetwork() == 1 then
							table.insert(cableNetworkUplinkProviders, {station.providerGUID})
						elseif station.IsSatellite() == 1 then
							table.insert(satelliteUplinkProviders, {station.providerGUID})
						end
					end
				end
				--debugMsg("JobAnalyseStationMarket: player " .. i .. " has " .. table.count(positions) .." antennas.")
			end
		end
		table.insert(self.Task.knownAntennaPositions, positions)
		table.insert(self.Task.knownCableNetworkUplinks, cableNetworkUplinkProviders)
		table.insert(self.Task.knownSatelliteUplinks, satelliteUplinkProviders)
	end


	-- one could do this on each audience calculation but this is a rather
	-- complex function needing  some execution time
	TVT.audiencePredictor.RefreshMarkets()
	player.LastStationMapMarketAnalysis = player.WorldTicks

	self.Status = JOB_STATUS_DONE
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
	debugMsg("JobAdjustStationInvestment: currentBudget=" .. self.Task.CurrentBudget .. "  neededInvestmentBudget"..self.Task.NeededInvestmentBudget)

	-- lower needed value each time we check
	if (self.Task.CurrentBudget < self.Task.NeededInvestmentBudget) then
		self.Task.NeededInvestmentBudget = math.round(self.Task.NeededInvestmentBudget * 0.85 )
	end

	-- require a minimum investment
	self.Task.NeededInvestmentBudget = math.max(300000, self.Task.NeededInvestmentBudget)
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


function JobBuyStation:GetBestCableNetworkOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local player = _G["globalPlayer"]

	debugMsg("Cablenetworks to check: " .. TVT.of_getCableNetworkCount())

	if TVT.of_getCableNetworkCount() > 0 then
		for i = 0, TVT.of_getCableNetworkCount()-1 do
			local cableNetwork = TVT.of_GetCableNetworkAtIndex(i)

			-- ignore if we already are clients of this provider
			-- ignore non-launched and not available for player
			if cableNetwork.IsSubscribedChannel(TVT.ME) == 0 and cableNetwork.IsLaunched() == 1 and cableNetwork.IsActive() == 1 then
				local tempStation = MY.GetStationMap().GetTemporaryCableNetworkUplinkStation(i)
				if tempStation then
					local price = tempStation.GetTotalBuyPrice()
					local pricePerViewer = tempStation.GetExclusiveReach() / price
					local priceDiff = self.Task.CurrentBudget - price
					--little influence by the amount of how well the budget is "used"
					--to avoid buying too many stations (upkeep!)
					local attraction = pricePerViewer * (0.9 + 0.1 * math.max(0, (price / self.Task.CurrentBudget)))

					if bestOffer == nil or attraction > bestAttraction then
						bestOffer = tempStation
						bestAttraction = attraction
					end
				end
			end
		end
	end
	if bestOffer then
		debugMsg(" - best cable network " .. bestOffer.GetName() .."  reach: " .. bestOffer.GetReach() .. "  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetExclusiveReach() / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
	else
		debugMsg(" -> no best cable network found")
	end

	return bestOffer, bestAttraction
end


function JobBuyStation:GetBestSatelliteOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local player = _G["globalPlayer"]

	debugMsg("Satellites to check: " .. TVT.of_getSatelliteCount())

	if TVT.of_getSatelliteCount() > 0 then
		for i = 0, TVT.of_getSatelliteCount()-1 do
			local satellite = TVT.of_GetSatelliteAtIndex(i)
			-- ignore if we already are clients of this provider
			-- ignore non-launched and not available for player
			if satellite.IsSubscribedChannel(TVT.ME) == 0 and satellite.IsLaunched() == 1 and satellite.IsActive() == 1 then
				local tempStation = MY.GetStationMap().GetTemporarySatelliteUplinkStation(i)
				if tempStation then
					local price = tempStation.GetTotalBuyPrice()
					local pricePerViewer = tempStation.GetExclusiveReach() / price
					local priceDiff = self.Task.CurrentBudget - price
					--little influence by the amount of how well the budget is "used"
					--to avoid buying too many stations (upkeep!)
					local attraction = pricePerViewer * (0.9 + 0.1 * math.max(0, (price / self.Task.CurrentBudget)))

					if bestOffer == nil or attraction > bestAttraction then
						bestOffer = tempStation
						bestAttraction = attraction

						debugMsg(" - new best satellite " .. bestOffer.GetName() .."  reach: " .. bestOffer.GetReach() .. "  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetExclusiveReach() / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
						debugMsg("   -> attraction: " .. attraction .. "  |  ".. pricePerViewer .. " - (" .. priceDiff .. " / currentBudget: " .. self.Task.CurrentBudget)
					end
				end
			end
		end
	end
	if bestOffer ~= nil then
		debugMsg(" -> best satellite " .. bestOffer.GetName() .."  reach: " .. bestOffer.GetReach() .. "  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetExclusiveReach() / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
	else
		debugMsg(" -> no best satellite found")
	end
	return bestOffer, bestAttraction
end


function JobBuyStation:GetBestAntennaOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local player = _G["globalPlayer"]

	-- fill a list with potential spots for an antenna
	-- 1) start with positions at which other channels are already
	-- 2) fill list up to X (eg. 50) with random spots
	-- 3) add Y random spots (10) so that even with >50 existing antennas
	--    we still try to find some random ones
	-- 4) lookup at _similar_ positions (add some random...)

	local stationPositions = {}
	local maxToCheck = 50 -- +some random
	local minimumRequiredRandoms = 10

	-- 1)
	for playerKey, playerStations in pairs(self.Task.knownAntennaPositions) do
		for key, stationPosition in pairs( self.Task.knownAntennaPositions[playerKey] ) do
			--this might remove some duplicates
			--(maybe even "round" values to "% 5" or so that nearly similar positions are fetched)
			local newKey = math.floor(stationPosition[1]) .. "_" .. math.floor(stationPosition[2])
			stationPositions[newKey] = stationPosition
		end
	end

	-- 2) + 3)
	local requiredRandoms = math.max(minimumRequiredRandoms, maxToCheck - table.count(stationPositions))
	for i = 1, requiredRandoms do
		local x = math.random(35, 560)
		local y = math.random(1, 375)
		local newKey =  x .. "_" .. y
		stationPositions[newKey] = {x, y}
	end


	-- 4)
		--for i = 1, 50 do
		--	local tempStation = MY.GetStationMap().GetTemporaryAntennaStation(math.random(35, 560), math.random(1, 375))
	local tablePos = 0
	for key,value in pairs(stationPositions) do
		tablePos = tablePos + 1
		local x = value[1] + math.random(-5,5)
		local y = value[2] + math.random(-5,5)
		local otherOwner = 0
		if table.count(value) > 2 then otherOwner = value[3] end
		local tempStation = MY.GetStationMap().GetTemporaryAntennaStation(x, y)

		if tempStation ~= nil then
			debugMsg(" - Station " .. tablePos .. "  at " .. x .. "," .. y .. ".  owner: " .. otherOwner .. "  reach: " .. tempStation.GetReach() .. "  exclusive/increase: " .. tempStation.GetExclusiveReach() .. "  price: " .. tempStation.GetBuyPrice() .. " (incl.fees: " .. tempStation.GetTotalBuyPrice() ..")  F: " .. (tempStation.GetExclusiveReach() / tempStation.GetPrice()) .. "  buyPrice: " .. tempStation.GetBuyPrice() )
		end

		--filter criterias
		--0) skip checks if there is no tempstation
		if tempStation == nil then
			-- debugMsg("tempStation is nil!")
		--1) outside
		elseif tempStation.GetPrice() < 0 then
			debugMsg("    -> outside of map")
			tempStation = nil
		--2) price to high
		elseif tempStation.GetPrice() > self.Task.CurrentBudget then
			debugMsg("    -> too expensive")
			tempStation = nil
		--3) relative increase to low (at least 30% required)
		elseif tempStation.GetRelativeExclusiveReach() < 0.30 then
			debugMsg("    -> not enough reach increase")
			tempStation = nil

		--4) absolute increase too low
		--elseif tempStation.GetExclusiveReach() < 1500 then
		--	tempStation = nil

		--5)  reach to low (at least 75.000 required)
		elseif tempStation.GetReach() < 75000 then
			debugMsg("    -> not enough absolute reach")
			tempStation = nil
		end


		-- Liegt im Budget und lohnt sich minimal -> erfuellt Kriterien
		if tempStation ~= nil then
			-- GetTotalBuyPrice() includes potential fees for a required
			-- permission.
			local price = tempStation.GetTotalBuyPrice()
			local pricePerViewer = tempStation.GetExclusiveReach() / price
			local priceDiff = self.Task.CurrentBudget - price
			--little influence by the amount of how well the budget is "used"
			--to avoid buying too many stations (upkeep!)
			local attraction = pricePerViewer * (0.9 + 0.1 * math.max(0, (price / self.Task.CurrentBudget)))

			-- raise attraction a bit if there is somebody else already
			if otherOwner > 0 then attraction = attraction * 1.10 end
			-- raise attraction (even further) if AI's enemy is there
			if otherOwner == player:GetArchEnemyId() then attraction = attraction * 1.06 end
			debugMsg("    -> attraction: " .. attraction .. "  |  ".. pricePerViewer .. " - (" .. priceDiff .. " / currentBudget: " .. self.Task.CurrentBudget)

			if bestOffer == nil then
				bestOffer = tempStation
			end
			if attraction > bestAttraction then
				bestOffer = tempStation
				bestAttraction = attraction
			end
		end
	end

	return bestOffer, bestAttraction
end


function JobBuyStation:Tick()
	debugMsg("JobBuyStation: Checking stations! current budget:" .. self.Task.CurrentBudget)

	local player = _G["globalPlayer"]

	local bestAntennaOffer, bestAntennaAttraction = self:GetBestAntennaOffer()
	local bestCableNetworkOffer = self:GetBestCableNetworkOffer()
	local bestSatelliteOffer = self:GetBestSatelliteOffer()

	local bestOffer = bestAntennaOffer

	if bestOffer ~= nil then
		local price = bestOffer.GetTotalBuyPrice()
		if bestOffer == bestAntennaOffer then
			debugMsg(" Buying antenna station in " .. bestOffer.GetSectionName() .. " at " .. bestOffer.pos.GetIntX() .. "," .. bestOffer.pos.GetIntY() .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. price)
			TVT.of_buyAntennaStation(bestOffer.pos.GetIntX(), bestOffer.pos.GetIntY())
		elseif bestOffer == bestSatelliteOffer then
			debugMsg(" Contracting satellite uplink " .. bestOffer.GetLongName() .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. price)
			--TVT.of_buyAntennaStation(bestOffer.pos.GetIntX(), bestOffer.pos.GetIntY())
		elseif bestOffer == bestCableNetworkOffer then
			debugMsg(" Contracting cable network uplink " .. bestOffer.GetLongName() .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach() .. "  price: " .. price)
			--TVT.of_buyAntennaStation(bestOffer.pos.GetIntX(), bestOffer.pos.GetIntY())
		end

		-- Wir brauchen noch ein "Fixkostenbudget" fuer Kabelnetze/Satelliten

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