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
	self.BudgetWeight = 4
	self.BasePriority = 1
	self.NeededInvestmentBudget = 280000
	self.InvestmentPriority = 8

	if(self.FixedCosts == nil) then self.FixedCosts = 0 end

	self.knownAntennaPositions = {}
	self.knownSatelliteUplinks = {}
	self.knownCableNetworkUplinks = {}
	self.maxAllowedCredit = 250000
end


function TaskStationMap:Activate()
	self.AnalyseStationMarketJob = JobAnalyseStationMarket()
	self.AnalyseStationMarketJob.Task = self

	self.AdjustStationInvestmentJob = JobAdjustStationInvestment()
	self.AdjustStationInvestmentJob.Task = self

	self.BuyStationJob = JobBuyStation()
	self.BuyStationJob.Task = self
	--self.LogLevel = LOG_TRACE
end


function TaskStationMap:GetNextJobInTargetRoom()
	if (self.AnalyseStationMarketJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyseStationMarketJob
--	elseif (self.BuyStationJob.Status == JOB_STATUS_DONE) then
--		self:SetWait() --Wenn der Einkauf geklappt hat... muss nichs weiter gemacht werden.
	end

	if (self.BuyStationJob.Status ~= JOB_STATUS_DONE) then
		--buy only if there is no credit
		if (MY.GetCredit(-1) <= self.maxAllowedCredit) then
			self:LogTrace("considering station buy")
			return self.BuyStationJob
		else
			self.BuyStationJob.Status = JOB_STATUS_DONE
		end
	elseif (self.AdjustStationInvestmentJob.Status ~= JOB_STATUS_DONE) then
		return self.AdjustStationInvestmentJob
	end

--	self:SetWait()

	--is successful only when in the room!
	self:CalculateFixedCosts()
	self:SetDone()
end


function TaskStationMap:BeforeBudgetSetup()
	local player = _G["globalPlayer"]
	local stats = player.Stats.MovieQuality
	local movieCount = 0
	if stats ~= nil then
		movieCount = stats.Values
	end
	local totalReach = player.totalReach

	--TODO do not buy stations when you have a credit
	if (MY.GetCredit(-1) > self.maxAllowedCredit) and (totalReach == nil or totalReach > 850000) then
		self.InvestmentPriority = 0
	elseif (movieCount < 30) and (totalReach == nil or totalReach > 1300000) then
		self.InvestmentPriority = 4
	else
		self.InvestmentPriority = 8
	end

	--prevent buying stations if there are not enough movies
	if movieCount < 20 or self.InvestmentPriority == 0 then
		self.BudgetWeight = 0
	else
		self.BudgetWeight = 4
		if totalReach == nil then
			--should not happen
		elseif totalReach < 2000000 then
			self.BudgetWeight = 8
		elseif movieCount < 30 and totalReach > 4400000 and totalReach < 5000000 then
			self.BudgetWeight = 0
		end
	end
end


function TaskStationMap:BudgetSetup()
	if self.UseInvestment then
		self:LogInfo("+++ Investition in TaskStationMap!")
		self.SituationPriority = 15
	end
end


function TaskStationMap:OnMoneyChanged(value, reason, reference)
	--ensure fixed costs are recalculated
	reason = tonumber(reason)
	if (reason == TVT.Constants.PlayerFinanceEntryType.PAY_STATION) then
		self:PayFromBudget(value)
		self.SituationPriority = 50
	elseif (reason == TVT.Constants.PlayerFinanceEntryType.SELL_STATION) then
		self:PayFromBudget(value)
		self.SituationPriority = 50
	end
end


function TaskStationMap:CalculateFixedCosts()
	local tmp = TVT.of_GetStationCosts()
	if tmp >= 0 then self.FixedCosts = tmp end
end


function TaskStationMap:GetAverageStationRunningCostPerPerson()
	local totalCost = 0
	local totalReach = 0
	local stationCount = TVT.of_getStationCount(TVT.ME)

	self:LogTrace("TaskStationMapJob.GetAverageStationRunningCostPerPerson")
	self:LogTrace("Owning " .. stationCount .. " stations.")
	if stationCount > 0 then
		for stationIndex = 0, stationCount-1 do
			local station = TVT.of_getStationAtIndex(i, stationIndex)
			if station ~= nil then
				totalCost = totalCost + station.GetRunningCosts()
				totalReach = totalReach + station.GetExclusiveReach(false)
				--totalReach = totalReach + station.GetReach(false)
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
			self:LogTrace("JobAnalyseStationMarket: player " .. i .. " has " .. stationCount .. " stations.")
			if stationCount > 0 then
				for stationIndex = 0, stationCount-1 do
					local station = TVT.of_getStationAtIndex(i, stationIndex)
					if station ~= nil then

						if station.IsAntenna() == 1 then
							--store x,y and owner
							table.insert(positions, {station.x, station.y, i})
							self:LogTrace("JobAnalyseStationMarket: player " .. i .. " has an antenna at " .. station.x .."/".. station.y)
						elseif station.IsCableNetworkUplink() == 1 then
							table.insert(cableNetworkUplinkProviders, {station.providerGUID})
						elseif station.IsSatelliteUplink() == 1 then
							table.insert(satelliteUplinkProviders, {station.providerGUID})
						end
					end
				end
				self:LogDebug("JobAnalyseStationMarket: player " .. i .. " has " .. table.count(positions) .." antennas.")
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
	local stats = player.Stats.MovieQuality
	local movieCount = 0
	if stats ~= nil then
		movieCount = stats.Values
	end
	player.totalReach = MY.GetMaxAudience()
	if player.totalReach < 2500000 and movieCount < 20 then
		self.Task.maxReachIncrease = 2400000 - player.totalReach
	elseif player.totalReach < 5000000 and movieCount < 30 then
		self.Task.maxReachIncrease = 4800000 - player.totalReach
	else
		self.Task.maxReachIncrease = 99000000
	end

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
	self:LogTrace("  before adjust: currentBudget=" .. self.Task.CurrentBudget .. "  neededInvestmentBudget"..self.Task.NeededInvestmentBudget)

	-- lower needed value each time we check
	if (self.Task.CurrentBudget < self.Task.NeededInvestmentBudget) then
		self.Task.NeededInvestmentBudget = math.round(self.Task.NeededInvestmentBudget * 0.85 )
	end

	-- require a minimum investment
	self.Task.NeededInvestmentBudget = math.max(300000, self.Task.NeededInvestmentBudget)

	self:LogTrace("  after adjust: currentBudget=" .. self.Task.CurrentBudget .. "  neededInvestmentBudget"..self.Task.NeededInvestmentBudget)

	self.Status = JOB_STATUS_DONE
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
	-- ignore budgets and just buy a station if there is some need
	-- the more stations we have, the less likely this is called
	local player = _G["globalPlayer"]
	local ignoreBudgetChance = 100 - (8-player.ExpansionPriority)*math.min(TVT.of_getStationCount(TVT.ME)-1,10)
	self:LogTrace("  ignoreBudgetChance: " ..ignoreBudgetChance)

	local moneyExcludingFixedCosts = TVT.GetMoney() - player.Budget.CurrentFixedCosts
	--TODO make constant player character dependent
	if moneyExcludingFixedCosts > 800000 and math.random(0,100) < ignoreBudgetChance then
		self.Task.CurrentBudget = (0.4 + 0.06*player.ExpansionPriority) * moneyExcludingFixedCosts
		self:LogDebug("  raised current budget to " .. self.Task.CurrentBudget .." to buy a station because 'we want it'.")
	end

	local totalReach = player.totalReach
	if totalReach~=nil and totalReach < 800000 and moneyExcludingFixedCosts > 300000  then
		self.Task.CurrentBudget = moneyExcludingFixedCosts
	end

	if (self.Task.CurrentBudget < self.Task.NeededInvestmentBudget) then
		self:LogDebug(" Cancel ... budget lower than needed investment budget")
		self:SetCancel()
	end

	local hour = TVT.GetDayHour()
	if hour > 14 then
		self:LogDebug(" Cancel ... no buying if too little of the day is left: ".. hour)
		self:SetCancel()
	end
end

function JobBuyStation:SetCancel()
	self.Status = JOB_STATUS_DONE
	--call parent
	--AIJob.SetCancel(self)
end

function JobBuyStation:GetAttraction(tempStation)
	local price = tempStation.GetTotalBuyPrice()
	local exclusiveReach = tempStation.GetExclusiveReach(false)
	local pricePerViewer = price / exclusiveReach / 5 + tempStation.GetRunningCosts() / exclusiveReach
	local priceDiff = self.Task.CurrentBudget - price
	--little influence by the amount of how well the budget is "used"
	--to avoid buying too many stations (upkeep!)
	local attraction = 1 / pricePerViewer * (0.9 + 0.1 * math.max(0, (price / self.Task.CurrentBudget)))
	--TODO do not buy if reach increase is too small
	if exclusiveReach < 100000 then
		attraction = 0
	end
	self:LogTrace("    -> attraction: " .. attraction .. "  |  ".. pricePerViewer .. " - (" .. priceDiff .. " / currentBudget: " .. self.Task.CurrentBudget .. ")")
	return attraction, price, exclusiveReach
end


function JobBuyStation:GetBestCableNetworkOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local bestSectionName = ""
	local player = _G["globalPlayer"]

	local networkCount = TVT.of_getCableNetworkCount()

	self:LogDebug("Cablenetworks to check: " .. networkCount)

	if networkCount > 0 then
		for i = 0, networkCount-1 do
			local cableNetwork = TVT.of_GetCableNetworkAtIndex(i)

			-- ignore if we already are clients of this provider
			-- ignore non-launched and not available for player
			if cableNetwork~=nil and cableNetwork.IsSubscribedChannel(TVT.ME) == 0 and cableNetwork.IsLaunched() == 1 and cableNetwork.IsActive() == 1 then
				local tempStation = TVT.of_GetTemporaryCableNetworkUplinkStation(i)
				if tempStation then
					local attraction, price, exclusiveReach = self:GetAttraction(tempStation)
					if (bestOffer == nil or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReach < self.Task.maxReachIncrease then
						bestOffer = tempStation
						bestAttraction = attraction
						bestSectionName = cableNetwork.sectionName
					end
				end
			end
		end
	end
	if bestOffer then
		self:LogDebug(" - best cable network " .. bestOffer.GetName() .."  reach: " .. bestOffer.GetReach(false) .. "  exclusive/increase: " .. bestOffer.GetExclusiveReach(false) .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetExclusiveReach(false) / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
	else
		self:LogTrace(" - no best cable network found")
	end
	return bestOffer, bestAttraction, bestSectionName
end


function JobBuyStation:GetBestSatelliteOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local bestIndex = -1
	local player = _G["globalPlayer"]

	local satCount = TVT.of_getSatelliteCount()
	self:LogDebug("Satellites to check: " .. satCount)

	if satCount > 0 then
		for i = 0, satCount-1 do
			local satellite = TVT.of_GetSatelliteAtIndex(i)
			-- ignore if we already are clients of this provider
			-- ignore non-launched and not available for player
			if satellite.IsSubscribedChannel(TVT.ME) == 0 and satellite.IsLaunched() == 1 and satellite.IsActive() == 1 then
				local tempStation = TVT.of_GetTemporarySatelliteUplinkStation(i)
				if tempStation then
					local attraction, price, exclusiveReach = self:GetAttraction(tempStation)

					if (bestOffer == nil or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReach < self.Task.maxReachIncrease then
						bestOffer = tempStation
						bestAttraction = attraction
						bestIndex = i
					end
				end
			end
		end
	end
	if bestOffer ~= nil then
		self:LogDebug(" - best satellite " .. bestOffer.GetName() .."  reach: " .. bestOffer.GetReach(false) .. "  exclusive/increase: " .. bestOffer.GetExclusiveReach(false) .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetExclusiveReach(false) / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
	else
		self:LogTrace(" - no best satellite found")
	end
	return bestOffer, bestAttraction, bestIndex
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
	-- 3) add Z random spots (10) in states we have broadcast permissions
	--    so that we try to keep prices low even with high budget
	-- 4) lookup at _similar_ positions (add some random...)

	local stationPositions = {}
	local maxToCheck = 50 -- +some random
	local minimumRequiredRandoms = 10
	local minimumRequiredRandomsWithPermission = 10

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

	for i = 1, minimumRequiredRandomsWithPermission do
		local vec2i = TVT.of_GetRandomAntennaCoordinateInPlayerSections()
		if vec2i ~= nil then
			local x = vec2i.GetX()
			local y = vec2i.GetY()
			local newKey =  x .. "_" .. y
			stationPositions[newKey] = {x, y}
		end
	end


	-- 4)
		--for i = 1, 50 do
		--	local tempStation = TVT.of_GetTemporaryAntennaStation(math.random(35, 560), math.random(1, 375))
	local tablePos = 0
	for key,value in pairs(stationPositions) do
		tablePos = tablePos + 1
		local x = value[1] + math.random(-5,5)
		local y = value[2] + math.random(-5,5)
		local otherOwner = 0
		if table.count(value) > 2 then otherOwner = value[3] end
		local tempStation = TVT.of_GetTemporaryAntennaStation(x, y)

		local stationString = "tempStation is nil"
		if tempStation ~= nil then
			stationString = "Station " .. tablePos .. "  at " .. x .. "," .. y .. ".  owner: " .. otherOwner .. "  reach: " .. tempStation.GetReach(false) .. "  exclusive/increase: " .. tempStation.GetExclusiveReach(false) .. "  price: " .. tempStation.GetBuyPrice() .. " (incl.fees: " .. tempStation.GetTotalBuyPrice() ..")  F: " .. (tempStation.GetExclusiveReach(false) / tempStation.GetPrice()) .. "  buyPrice: " .. tempStation.GetBuyPrice()
		end

		--filter criterias
		--0) skip checks if there is no tempstation
		if tempStation == nil then
			self:LogTrace(stationString)

		--1) outside
		elseif tempStation.GetPrice() < 0 then
			self:LogTrace(stationString .. " -> outside of map!")
			tempStation = nil

		--2) price to high
		elseif tempStation.GetPrice() > self.Task.CurrentBudget then
			self:LogTrace(stationString .. " -> too expensive!")
			tempStation = nil

		--3) relative increase to low (at least 35% required)
		elseif tempStation.GetRelativeExclusiveReach(false) < 0.35 then
			self:LogTrace(stationString .. " -> not enough relative reach increase!")
			tempStation = nil

		--4) absolute increase too low
		--elseif tempStation.GetExclusiveReach(false) < 1500 then
		--	tempStation = nil

		--5)  reach to low (at least 75.000 required)
		elseif tempStation.GetReach(false) < 75000 then
			self:LogTrace(stationString .. " -> not enough absolute reach!")
			tempStation = nil

		else
			self:LogTrace(stationString .. " -> OK!")
		end


		-- Liegt im Budget und lohnt sich minimal -> erfuellt Kriterien
		if tempStation ~= nil then
			local attraction, price, exclusiveReach = self:GetAttraction(tempStation)

			-- raise attraction a bit if there is somebody else already
			if otherOwner > 0 then attraction = attraction * 1.10 end
			-- raise attraction (even further) if AI's enemy is there
			if otherOwner == player:GetArchEnemyId() then attraction = attraction * 1.06 end
			if (bestOffer == nil or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReach < self.Task.maxReachIncrease then
				bestOffer = tempStation
				bestOffer = tempStation
				bestAttraction = attraction
			end
		end
	end

	return bestOffer, bestAttraction
end


function JobBuyStation:Tick()
	local player = _G["globalPlayer"]

	local bestAntennaOffer, bestAntennaAttraction = self:GetBestAntennaOffer()
	local bestCableNetworkOffer, bestCableAttraction, bestCableSectionName = self:GetBestCableNetworkOffer()
	local bestSatelliteOffer, bestSatAttraction, bestSatIndex = self:GetBestSatelliteOffer()

	local bestOffer = bestAntennaOffer
	local bestAttraction = bestAntennaAttraction
	if bestCableAttraction > bestAttraction then
		bestOffer = bestCableNetworkOffer
		bestAttraction = bestCableAttraction
	end
	if bestSatAttraction > bestAttraction then
		bestOffer = bestSatelliteOffer
	end

	if bestOffer ~= nil then
		local price = bestOffer.GetTotalBuyPrice()
		if bestOffer == bestAntennaOffer then
			self:LogInfo("Buying antenna station in " .. bestOffer.GetSectionName(false) .. " at " .. bestOffer.x .. "," .. bestOffer.y .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach(false) .. "  price: " .. price)
			TVT.of_buyAntennaStation(bestOffer.x, bestOffer.y)
		elseif bestOffer == bestSatelliteOffer then
			self:LogInfo("Contracting satellite uplink " .. bestOffer.GetLongName() .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach(false) .. "  price: " .. price)
			TVT.of_buySatelliteStation(bestSatIndex)
		elseif bestOffer == bestCableNetworkOffer then
			self:LogInfo("Contracting cable network uplink " .. bestOffer.GetLongName() .. ".  exclusive/increase: " .. bestOffer.GetExclusiveReach(false) .. "  price: " .. price)
			TVT.of_buyCableNetworkStation(bestCableSectionName)
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
		self:LogDebug(" Next channel buy when reaching investment budget of " .. self.Task.NeededInvestmentBudget)
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<