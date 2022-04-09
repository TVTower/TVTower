-- File: TaskNewsAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskStationMap"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_STATIONMAP"]
	c.TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME
	c:ResetDefaults()

	c.intendedAntennaPositions = {}
end)


function TaskStationMap:typename()
	return "TaskStationMap"
end


function TaskStationMap:ResetDefaults()
	self.BudgetWeight = 4
	self.BasePriority = 1
	self.NeededInvestmentBudget = 250000
	self.InvestmentPriority = 8

	if(self.FixedCosts == nil) then self.FixedCosts = 0 end

	--do not reset intendedPositions - calculatedOnlyOnce!
	--self.intendedAntennaPositions = {}

	--old analysis
	--self.knownAntennaPositions = {}
	--self.knownSatelliteUplinks = {}
	--self.knownCableNetworkUplinks = {}
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
		return self.BuyStationJob
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

	--TODO cleanup - no investmentPriority anymore
	if movieCount < 12 and  (totalReach == nil or totalReach > 850000) then
		self.InvestmentPriority = 0
	elseif (movieCount < 24) and (totalReach == nil or totalReach > 1300000) then
		self.InvestmentPriority = 4
	else
		self.InvestmentPriority = 8
	end

	if self.InvestmentPriority == 0 then
		self.BudgetWeight = 0
	else
		self.BudgetWeight = 4
		if totalReach == nil then
			--should not happen
		elseif totalReach < 2000000 then
			self.BudgetWeight = 8
		--elseif movieCount < 30 and totalReach > 4400000 and totalReach < 5000000 then
		--	self.BudgetWeight = 0
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
	-- one could do this on each audience calculation but this is a rather
	-- complex function needing  some execution time

	--TODO refresh less often
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

	if TVT.of_getStationCount(TVT.ME) < 30 and (self.Task.intendedAntennaPositions == nil or table.count(self.Task.intendedAntennaPositions) == 0) then
		self:determineIntendedPositions()
	end

	--try without analysing market
	--self:determineKnownPositions()

	self.Status = JOB_STATUS_DONE
end

function JobAnalyseStationMarket:determineIntendedPositions()
	self:LogInfo("determining the positions of all antennas to be built in the future")
	local startStation = TVT.of_getStationAtIndex(TVT.ME, 0)
	if startStation ~= nil then
		if startStation.IsAntenna() == 1 then
			local radius = startStation.radius
			--reduce radius - small overlap but decrease missed areas between 3 antennas
			if radius < 30 then
				radius = radius -1
			elseif radius < 40 then
				radius = radius -2
			elseif radius < 50 then
				radius = radius -3
			elseif radius < 60 then
				radius = radius -4
			elseif radius < 70 then
				radius = radius -5
			else
				radius = radius -6
			end
			local d = 2 * radius

			--dx and dy are the deltas for the next antenna center in the same row
			local dx = math.random(radius+radius/2,d)
			local dy = math.sqrt(4 * radius ^ 2 - dx ^ 2)

			--da and db are the deltas for the center of the start antenna in the next but one row
			--(antenna centers "alternate")
			local da = 0
			local db = math.sqrt(3) * d

			if dx < d then
				da = math.sqrt( (3 * d ^ 2 )/( ((1.0*dx)/(1.0*dy))^2+ 1) )
				db = ((1.0*dx)/(1.0*dy))*da
			end

			dy=math.floor(dy)
			da=math.floor(da)
			db=math.floor(db)

			--deltaX and deltaY are the deltas for the center of the start antenna in the next row
			--the row whose center is "off" by radius
			local deltaX = 0
			if dx > dy then
				deltaX = math.floor((dx - da) / 2)
			else
				deltaX = math.floor((da - dx) / 2)
			end
			local deltaY = math.floor((db + dy) / 2 )

			local positionTable = {}
			local foundCount = 1
			local startX = startStation.x
			local startY = startStation.y
			--create rows upwards
			while foundCount > 0 do
				foundCount = self:insertIntendedPositionsRow(startX, startY, dx, dy, positionTable)
				startX = startX + deltaX
				startY = startY + deltaY
				foundCount = foundCount+ self:insertIntendedPositionsRow(startX, startY, dx, dy, positionTable)
				startX = startX + deltaX
				startY = startY + deltaY
			end

			foundCount = 1
			startX = startStation.x - deltaX
			startY = startStation.y - deltaY
			--create rows downwards
			while foundCount > 0 do
				foundCount = self:insertIntendedPositionsRow(startX, startY, dx, dy, positionTable)
				startX = startX - deltaX
				startY = startY - deltaY
				foundCount = foundCount + self:insertIntendedPositionsRow(startX, startY, dx, dy, positionTable)
				startX = startX - deltaX
				startY = startY - deltaY
			end
			self.Task.intendedAntennaPositions = positionTable
			self:LogInfo("found ".. table.count(positionTable) .. " antennas")
		else
			self:LogError("start station is not an antenna")
		end
	else
		self:LogError("no start station found")
	end
end

function JobAnalyseStationMarket:insertIntendedPositionsRow(startX, startY, xDelta, yDelta, positions)
	local foundCount = 0
	local x = startX
	local y = startY

	while x > 0 and y > 0 do
		if self:insertIntendedPosition(x, y, positions) == 1 then foundCount=foundCount + 1 end
		x = x - xDelta
		y = y - yDelta
	end

	x = startX + xDelta
	y = startY + yDelta
	while x < 800 and y < 800 do --TODO map size
		if self:insertIntendedPosition(x, y, positions) == 1 then foundCount=foundCount + 1 end
		x = x + xDelta
		y = y + yDelta
	end
	return foundCount
end

function JobAnalyseStationMarket:insertIntendedPosition(x, y, positions)
	local tempStation = TVT.of_GetTemporaryAntennaStation(x, y)
	if tempStation ~= nil then
		local price  = tempStation.GetPrice()
		if price >= 0 then
			table.insert(positions, { x = tempStation.x, y = tempStation.y })

--[[
			local reach = tempStation.GetReach(false)
			local exclusiveReach = tempStation.GetExclusiveReach(false)
			local relativeExclusiveReach = exclusiveReach / reach
			stationString = "Station at " .. x .. "," .. y .. "  reach: " .. reach .. "  exclusive/increase: " .. exclusiveReach .. "  price: " .. price .. " (incl.fees: " .. tempStation.GetTotalBuyPrice() ..")  F: " .. (exclusiveReach / price) .. "  buyPrice: " .. tempStation.GetBuyPrice()
			self:LogInfo(stationString)
			--buying immediately for checking positions
			--TVT.of_buyAntennaStation(tempStation.x, tempStation.y)
			--TVT.sleep(40) --sleep necessary in my environment to prevent seg fault
]]--
			return 1
		end
	end
	return 0
end

--Old function determining all players' antenna positions for determining cancidates
--[[
function JobAnalyseStationMarket:determineKnownPositions()
	-- fetch positions of other players stations, cable network uplinks
	-- and satellite uplinks
	-- reset known
	self.Task.knownAntennaPositions = {}
	self.Task.knownCableNetworkUplinks = {}
	self.Task.knownSatelliteUplinks = {}

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
end
]]--
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
	if self.Task.CurrentBudget > 0 and moneyExcludingFixedCosts > 350000 and math.random(0,100) < ignoreBudgetChance then
		--self.Task.CurrentBudget = (0.4 + 0.06*player.ExpansionPriority) * moneyExcludingFixedCosts
		self.Task.CurrentBudget = moneyExcludingFixedCosts
		self:LogDebug("  raised current budget to " .. self.Task.CurrentBudget .." to buy a station because 'we want it'.")
	end

	local totalReach = player.totalReach
	if totalReach~=nil and totalReach < 800000 and moneyExcludingFixedCosts > 300000  then
		self.Task.CurrentBudget = moneyExcludingFixedCosts
	end

	--TODO not considering the investment budget has the advantage of faster purchase
	--if (self.Task.CurrentBudget < self.Task.NeededInvestmentBudget) then
	local neededBudget = 250000
	if self.Task.fixedCosts ~= nil then
		neededBudget = neededBudget + self.Task.fixedCosts / 4
	end
	if (self.Task.CurrentBudget < neededBudget) then
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
	--when including permission, overlapping stations in the same area are bought
	--but when not including; stations in other states win - and budget does not suffice
	--local price = tempStation.GetTotalBuyPrice()
	local price = tempStation.GetBuyPrice()
	local exclusiveReach = tempStation.GetExclusiveReach(false)
	local pricePerViewer = (price / exclusiveReach) / 5 + tempStation.GetRunningCosts() / exclusiveReach
	local priceDiff = self.Task.CurrentBudget - price
	--little influence by the amount of how well the budget is "used"
	--to avoid buying too many stations (upkeep!)
	local attraction = 1 / pricePerViewer * (0.9 + 0.1 * math.max(0, (price / self.Task.CurrentBudget)))
	self:LogTrace("    -> attraction before" .. attraction .." rc"..tempStation.GetRunningCosts())
	if tempStation.GetTotalBuyPrice() > self.Task.CurrentBudget then
		attraction = -1
	elseif attraction < 1 then
		attraction = -2
	elseif exclusiveReach < 100000 then
		attraction = attraction * 0.5
	elseif tempStation:CanSignContract(-1) == 0 then
		attraction = -3
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
					if (bestOffer == nil and attraction > 0 or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReach < self.Task.maxReachIncrease then
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

	self:LogInfo("trying to find best of ".. table.count(self.Task.intendedAntennaPositions) .." antenna positions")

	local removeFromIntendedPositions = {}

	for k,pos in pairs(self.Task.intendedAntennaPositions) do
		local x = pos.x
		local y = pos.y
		local tempStation = TVT.of_GetTemporaryAntennaStation(x, y)

		local stationString = "tempStation is nil"
		local reach = 0
		local exclusiveReach = 0
		local price = -1
		local relativeExclusiveReach = 0
		if tempStation ~= nil then
			reach = tempStation.GetReach(false)
			exclusiveReach = tempStation.GetExclusiveReach(false)
			if exclusiveReach < 2000 then table.insert(removeFromIntendedPositions, pos) end
			relativeExclusiveReach = exclusiveReach / reach
			price = tempStation.GetPrice()
			stationString = "Station at " .. x .. "," .. y .. "  reach: " .. reach .. "  exclusive/increase: " .. exclusiveReach .. "  price: " .. price .. " (incl.fees: " .. tempStation.GetTotalBuyPrice() ..")  F: " .. (exclusiveReach / price) .. "  buyPrice: " .. tempStation.GetBuyPrice()
		end

		--filter criterias
		--0) skip checks if there is no tempstation
		if tempStation == nil then
			self:LogTrace(stationString)

		--1) outside
		elseif price < 0 then
			self:LogTrace(stationString .. " -> outside of map!")
			tempStation = nil

		--2) price to high
		elseif price > self.Task.CurrentBudget then
			self:LogTrace(stationString .. " -> too expensive!")
			tempStation = nil

		--4) absolute increase too low
		elseif exclusiveReach < 20000 then
			tempStation = nil

		--5)  reach to low (at least 75.000 required)
		elseif reach < 75000 then
			self:LogTrace(stationString .. " -> not enough absolute reach!")
			tempStation = nil

		else
			self:LogTrace(stationString .. " -> OK!")
		end


		-- Liegt im Budget und lohnt sich minimal -> erfuellt Kriterien
		if tempStation ~= nil then
			local attraction, price, exclusiveReach = self:GetAttraction(tempStation)

			if (bestOffer == nil or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReach < self.Task.maxReachIncrease then
				bestOffer = tempStation
				bestOffer = tempStation
				bestAttraction = attraction
			end
		end
	end

	if table.count(removeFromIntendedPositions) > 0 then
		self:LogDebug("removing from intendedPositions ".. table.count(self.Task.intendedAntennaPositions))
		for k, pos in pairs(removeFromIntendedPositions) do
			self:LogDebug("removing  ".. pos.x .. " "..pos.y)
			table.removeElement(self.Task.intendedAntennaPositions, pos)
		end
		self:LogDebug("new count ".. table.count(self.Task.intendedAntennaPositions))
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
	if bestCableAttraction > bestAttraction and bestCableAttraction > 0 then
		bestOffer = bestCableNetworkOffer
		bestAttraction = bestCableAttraction
	end
	if bestSatAttraction > bestAttraction and bestSatAttraction > 0 then
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
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<