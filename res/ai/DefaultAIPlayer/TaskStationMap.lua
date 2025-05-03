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

function TaskStationMap:getStrategicPriority()
	self:LogTrace("TaskStationMap:getStrategicPriority")
	if getPlayer().hour > 17 then
		return 0.0
	end
	return 1.0
end

function TaskStationMap:ResetDefaults()
	self.BudgetWeight = 4
	self.BasePriority = 1
	self.NeededInvestmentBudget = 250000
	self.InvestmentPriority = 8
	self.LastDaySell = -1

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

	self.SellStationJob = JobSellStation()
	self.SellStationJob.Task = self

	if self.antennaCalculationCount == nil then
		self.antennaCalculationCount = 0
	end
	if self.antennaCalculationCount == 0 and table.count(self.intendedAntennaPositions) > 0 then
		self.antennaCalculationCount = 1
	end
	--self.LogLevel = LOG_TRACE
end


function TaskStationMap:GetNextJobInTargetRoom()
	if (self.AnalyseStationMarketJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyseStationMarketJob
	end

	if (self.BuyStationJob.Status ~= JOB_STATUS_DONE) then
		return self.BuyStationJob
	elseif (self.AdjustStationInvestmentJob.Status ~= JOB_STATUS_DONE) then
		return self.AdjustStationInvestmentJob
	elseif (self.SellStationJob.Status ~= JOB_STATUS_DONE) then
		return self.SellStationJob
	end

	--is successful only when in the room!
	self:CalculateFixedCosts()

	local taskTime = getPlayer().minutesGone - self.StartTask
	if taskTime < 7 then
		self:SetIdle(7-taskTime)
	else
		self:SetDone()
	end
end


function TaskStationMap:BeforeBudgetSetup()
	local player = getPlayer()
	local maxTopBlocks = player.maxTopicalityBlocksCount
	local blocks = player.blocksCount
	local totalReceivers = player.totalReceivers

	if blocks < 36 and (totalReceivers == nil or totalReceivers > 1200000) then
		self.BudgetWeight = 0
	elseif blocks < 50 and (totalReceivers == nil or totalReceivers > 5000000) then
		self.BudgetWeight = 4
	elseif maxTopBlocks > 6 then
		self.BudgetWeight = 12
	else
		self.BudgetWeight = 8
	end

	if self.maxReceiverIncrease ~=nil and self.maxReceiverIncrease < 0  then
		self.BudgetWeight = 0
	end
end


function TaskStationMap:BudgetSetup()
end


function TaskStationMap:OnMoneyChanged(value, reason, reference)
	--ensure fixed costs are recalculated
	reason = tonumber(reason)
	if (reason == TVT.Constants.PlayerFinanceEntryType.PAY_STATION) then
		self:PayFromBudget(math.abs(value))
		self.SituationPriority = 50
	elseif (reason == TVT.Constants.PlayerFinanceEntryType.SELL_STATION) then
		self:PayFromBudget(-math.abs(value))
		self.SituationPriority = 50
	end
end


function TaskStationMap:CalculateFixedCosts()
	local tmp = TVT.of_GetStationCosts()
	if tmp >= 0 then self.FixedCosts = tmp end
end


function TaskStationMap:GetAverageStationRunningCostPerPerson()
	local totalCost = 0
	local totalReceivers = 0
	local stationCount = TVT.of_getStationCount(TVT.ME)

	self:LogTrace("TaskStationMapJob.GetAverageStationRunningCostPerPerson")
	self:LogTrace("Owning " .. stationCount .. " stations.")
	if stationCount > 0 then
		for stationIndex = 0, stationCount-1 do
			local station = TVT.of_getStationAtIndex(i, stationIndex)
			if station ~= nil then
				totalCost = totalCost + station.GetRunningCosts()
				totalReceivers = totalReceivers + station.GetStationExclusiveReceivers()
			end
		end
	end

	return totalCost / totalReceivers
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
	local player = getPlayer()
	-- one could do this on each audience calculation but this is a rather
	-- complex function needing  some execution time

	--TODO refresh less often
	TVT.audiencePredictor.RefreshMarkets()
	player.LastStationMapMarketAnalysis = player.WorldTicks
	local blocks = player.blocksCount
	player.totalReceivers = TVT:getReceivers()
	self.Task.maxReceiverIncrease = 99000000

	--movie prices do not increas so much anymore...
	--[[
	if movieCount < 12 then
		if player.totalReceivers < 2500000 then
			self.Task.maxReceiverIncrease = 2400000 - player.totalReceivers
		else
			self.Task.maxReceiverIncrease = 0
		end
	elseif movieCount < 24 then
		if player.totalReceivers < 5000000 then
			self.Task.maxReceiverIncrease = 4800000 - player.totalReceivers
		else
			self.Task.maxReceiverIncrease = 0
		end
	end
	--]]

	local mapTotalReceivers = TVT:of_getMapReceivers()
	player.coverage = 0.018
	if mapTotalReceivers > 0 then --guard against error return value
		player.coverage = player.totalReceivers / mapTotalReceivers
	end

	--TODO if coverage is high enough, use random positions rather than systematicall "all possible"
	if player.money > 10000000 and player.coverage > 0.15 and blocks < 144 then
		--player bankrupt - do not by stations too fast
		self.Task.maxReceiverIncrease = -1
	elseif player.coverage > 0.94 then
		self.Task.maxReceiverIncrease = -1
	elseif self.Task.intendedAntennaPositions == nil or table.count(self.Task.intendedAntennaPositions) < 7 then
		self:determineIntendedPositions()
	end

	self.Status = JOB_STATUS_DONE
end

function JobAnalyseStationMarket:determineIntendedPositions()
	self:LogInfo("determining the positions of all antennas to be built in the future")
	local startStation = self:getBaseAntennaParameters()
	if startStation.radius < 0 then return end
	local radius = startStation.radius
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
	
	local mapWidth = TVT.of_getMapWidth()
	local mapHeight = TVT.of_getMapHeight()

	local positionTable = {}
	local sectionCount = {}
	local foundCount = 1
	local startX = startStation.x
	local startY = startStation.y
	--create rows upwards
	while foundCount > 0 do
		foundCount = self:insertIntendedPositionsRow(startX, startY, mapWidth, mapHeight, dx, dy, positionTable, sectionCount)
		startX = startX + deltaX
		startY = startY + deltaY
	end

	foundCount = 1
	startX = startStation.x - deltaX
	startY = startStation.y - deltaY
	--create rows downwards
	while foundCount > 0 do
		foundCount = self:insertIntendedPositionsRow(startX, startY, mapWidth, mapHeight, dx, dy, positionTable, sectionCount)
		startX = startX - deltaX
		startY = startY - deltaY
	end

	foundCount = table.count(positionTable)
	if foundCount > 15 then
		self.Task.antennaCalculationCount = self.Task.antennaCalculationCount + 1
		self.Task.intendedAntennaPositions = positionTable
		self.Task.antennasPerSection = sectionCount
		self:LogInfo("found ".. foundCount .. " antennas")
	end
end

function JobAnalyseStationMarket:getBaseAntennaParameters()
	local startStation = TVT.of_getStationAtIndex(TVT.ME, 0)
	local antennaCount = TVT.of_getStationCount(TVT.ME)

	if startStation ~= nil and startStation.IsAntenna() == 1 and antennaCount < 3 then
		self:LogDebug("using coordinates of initial antenna")
	else
		local x = math.random(100,300)
		local y = math.random(100,300)
		startStation = TVT.of_GetTemporaryAntennaStation(x,y)
		self:LogDebug("using random coordinates "..x.." "..y)
	end

	if startStation == nil then return {x=-1; y=-1; radius = -1} end

	--reduce radius - small overlap but decrease missed areas between 3 antennas
	local radius = startStation.radius
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

	return {x=startStation.x; y=startStation.y; radius = radius}
end

function JobAnalyseStationMarket:insertIntendedPositionsRow(startX, startY, limitX, limitY, xDelta, yDelta, positions, sectionCount)
	local foundCount = 0
	local x = startX
	local y = startY

	while x > 0 and y > 0 do
		if self:insertIntendedPosition(x, y, positions, sectionCount) == 1 then foundCount=foundCount + 1 end
		x = x - xDelta
		y = y - yDelta
	end

	x = startX + xDelta
	y = startY + yDelta
	while x < limitX and y < limitY do --limitX/Y is map width/height
		if self:insertIntendedPosition(x, y, positions, sectionCount) == 1 then foundCount=foundCount + 1 end
		x = x + xDelta
		y = y + yDelta
	end
	return foundCount
end

function JobAnalyseStationMarket:insertIntendedPosition(x, y, positions, sectionCount)
	local permissionPrice = TVT.of_GetBroadCastPermisionCosts(x, y)
	if permissionPrice > -2 then
		--no full initialization - we are only interested in the section name
		local tempStation = TVT.of_GetTemporaryAntennaStation(x, y)
		table.insert(positions, { x = tempStation.x, y = tempStation.y })
		local sectionName = tempStation:GetSectionName()
		local count = sectionCount[sectionName]
		if count == nil then
			sectionCount[sectionName] = 1
		else
			sectionCount[sectionName] = count + 1
		end

--[[
		tempStation.refreshData()
		local receivers = tempStation.GetReceivers()
		local exclusiveReceivers = tempStation.GetStationExclusiveReceivers()
		local relativeExclusiveReceivers = exclusiveReceivers / receivers
		stationString = "Station at " .. x .. "," .. y .. "  receivers: " .. receivers .. "  exclusive/increase: " .. exclusiveReceivers .. "  price: " .. price .. " (incl.fees: " .. tempStation.GetTotalBuyPrice() ..")  F: " .. (exclusiveReceivers / price) .. "  buyPrice: " .. tempStation.GetBuyPrice()
		self:LogInfo(stationString)
		--buying immediately for checking positions
		--TVT.of_buyAntennaStation(tempStation.x, tempStation.y)
		--TVT.sleep(40) --sleep necessary in my environment to prevent seg fault
]]--
		return 1
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
	local player = getPlayer()
	local ignoreBudgetChance = 100 - (8-player.ExpansionPriority)*math.min(TVT.of_getStationCount(TVT.ME)-1,10)
	self:LogTrace("  ignoreBudgetChance: " ..ignoreBudgetChance)

	local moneyExcludingFixedCosts = player.money - player.Budget.CurrentFixedCosts
	--TODO make constant player character dependent
	if self.Task.CurrentBudget > 0 and moneyExcludingFixedCosts > 350000 and math.random(0,100) < ignoreBudgetChance then
		--self.Task.CurrentBudget = (0.4 + 0.06*player.ExpansionPriority) * moneyExcludingFixedCosts
		self.Task.CurrentBudget = moneyExcludingFixedCosts
		self:LogDebug("  raised current budget to " .. self.Task.CurrentBudget .." to buy a station because 'we want it'.")
	end

	local totalReceivers = player.totalReceivers
	local neededBudget = 250000
	if totalReceivers~=nil and totalReceivers < 1200000 and moneyExcludingFixedCosts > 150000  then
		self.Task.CurrentBudget = moneyExcludingFixedCosts
		neededBudget = 150000
	end

	--TODO not considering the investment budget has the advantage of faster purchase
	--if (self.Task.CurrentBudget < self.Task.NeededInvestmentBudget) then
	if self.Task.fixedCosts ~= nil then
		neededBudget = neededBudget + self.Task.fixedCosts / 8
	end
	if (self.Task.CurrentBudget < neededBudget) then
		self:LogDebug(" Cancel ... budget lower than needed investment budget")
		self:SetCancel()
	end

	local hour = player.hour
	if hour > 14 then
		self:LogDebug(" Cancel ... no buying if too little of the day is left: ".. hour)
		self:SetCancel()
	end
	self.Task.CurrentBudget = math.min(self.Task.CurrentBudget, moneyExcludingFixedCosts)
	--TODO do no spend all money on one task run
	self.purchaseCount = 0
end

function JobBuyStation:SetCancel()
	self.Status = JOB_STATUS_DONE
	--call parent
	--AIJob.SetCancel(self)
end

function JobBuyStation:GetAttraction(tempStation)
	--when including permission, overlapping stations in the same area are bought
	--but when not including; stations in other states win - and budget does not suffice
	local totalprice = tempStation.GetTotalBuyPrice()
	local price = tempStation.GetBuyPrice()
	if totalprice > price and self.Task.antennasPerSection then
		local antennaCount = self.Task.antennasPerSection[tempStation.GetSectionName()]
		if antennaCount ~= nil then
			price = price + (1.0 / antennaCount) * (totalprice - price)
		end
	end
	local exclusiveReceivers = tempStation.GetStationExclusiveReceivers()
	local runningCosts = tempStation.GetRunningCosts()
	local pricePerViewer = (price / exclusiveReceivers) / 5 + runningCosts / exclusiveReceivers
	local priceDiff = self.Task.CurrentBudget - price
	--little influence by the amount of how well the budget is "used"
	--to avoid buying too many stations (upkeep!)
	local attraction = 1 / pricePerViewer * (0.9 + 0.1 * math.max(0, (price / self.Task.CurrentBudget)))
	self:LogTrace("    -> attraction before" .. attraction .." rc " .. runningCosts)
	if tempStation:CanSignContract() == 0 then
		attraction = -3
	elseif totalprice > self.Task.CurrentBudget then
		attraction = -1
	elseif attraction < 1 then
		attraction = -2
	elseif exclusiveReceivers < 100000 then
		attraction = attraction * 0.5
	end
	self:LogTrace("    -> attraction: " .. attraction .. "  |  ".. pricePerViewer .. " - (" .. priceDiff .. " / currentBudget: " .. self.Task.CurrentBudget .. ")")
	return attraction, totalprice, exclusiveReceivers
end


function JobBuyStation:GetBestCableNetworkOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local bestSectionName = ""
	local player = getPlayer()

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
					local attraction, price, exclusiveReceivers = self:GetAttraction(tempStation)
					if (bestOffer == nil and attraction > 0 or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReceivers < self.Task.maxReceiverIncrease then
						bestOffer = tempStation
						bestAttraction = attraction
						bestSectionName = cableNetwork.sectionName
					end
				end
			end
		end
	end
	if bestOffer then
		self:LogDebug(" - best cable network " .. bestOffer.GetName() .."  receivers: " .. bestOffer.GetReceivers() .. "  exclusive/increase: " .. bestOffer.GetStationExclusiveReceivers() .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetStationExclusiveReceivers() / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
	else
		self:LogTrace(" - no best cable network found")
	end
	return bestOffer, bestAttraction, bestSectionName
end


function JobBuyStation:GetBestSatelliteOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local bestIndex = -1
	local player = getPlayer()

	local satCount = TVT.of_getSatelliteCount()
	self:LogDebug("Satellites to check: " .. satCount)

	if satCount > 0 then
		for i = 0, satCount-1 do
			local satellite = TVT.of_GetSatelliteAtIndex(i)
			-- ignore if we already are clients of this provider
			-- ignore non-launched and not available for player
			if satellite~=nil and satellite.IsSubscribedChannel(TVT.ME) == 0 and satellite.IsLaunched() == 1 and satellite.IsActive() == 1 then
				local tempStation = TVT.of_GetTemporarySatelliteUplinkStation( i )
				if tempStation then
					local attraction, price, exclusiveReceivers = self:GetAttraction(tempStation)

					if (bestOffer == nil or attraction > bestAttraction) and price < self.Task.CurrentBudget and exclusiveReceivers < self.Task.maxReceiverIncrease then
						bestOffer = tempStation
						bestAttraction = attraction
						bestIndex = i
					end

					--if you can afford a satellite TAKE IT
					if (bestOffer == nil and attraction > -3 and price < player.money and player.hour < 7 and exclusiveReceivers < self.Task.maxReceiverIncrease) then
						bestOffer = tempStation
						bestAttraction = 3
						bestIndex = i
					end
				end
			end
		end
	end
	if bestOffer ~= nil then
		self:LogDebug(" - best satellite " .. bestOffer.GetName() .."  receivers: " .. bestOffer.GetReceivers() .. "  exclusive/increase: " .. bestOffer.GetStationExclusiveReceivers() .. "  price: " .. bestOffer.GetBuyPrice() .. " (incl.fees: " .. bestOffer.GetTotalBuyPrice() ..")  F: " .. (bestOffer.GetStationExclusiveReceivers() / bestOffer.GetPrice()) .. "  buyPrice: " .. bestOffer.GetBuyPrice() )
	else
		self:LogTrace(" - no best satellite found")
	end
	return bestOffer, bestAttraction, bestIndex
end


function JobBuyStation:GetBestAntennaOffer()
	local bestOffer = nil
	local bestAttraction = 0
	local bestPosition = nil
	local player = getPlayer()

	self:LogInfo("trying to find best of ".. table.count(self.Task.intendedAntennaPositions) .." antenna positions")

	local removeFromIntendedPositions = {}
	local budget = self.Task.CurrentBudget
	local coverage = player.coverage

	for k,pos in pairs(self.Task.intendedAntennaPositions) do
		local x = pos.x
		local y = pos.y
		local permissionPrice = TVT.of_GetBroadCastPermisionCosts(x, y)
		if permissionPrice < 0 then
			--self:LogTrace("no chance for buying" ..x .." ".. y.." "..permissionPrice)
		elseif permissionPrice > budget then
			--self:LogTrace("no chance for buying, too expensive")
		else
			local tempStation = TVT.of_GetTemporaryAntennaStation(x, y)

			local stationString = "tempStation is nil"
			local receivers = 0
			local exclusiveReceivers = 0
			local price = -1
			local relativeExclusiveReceivers = 0
			if tempStation ~= nil then
				price = tempStation.GetTotalBuyPrice()
				if price <= budget then
					receivers = tempStation.GetReceivers()
					exclusiveReceivers = tempStation.GetStationExclusiveReceivers()
					relativeExclusiveReceivers = exclusiveReceivers / receivers
					stationString = "Station at " .. x .. "," .. y .. "  receivers: " .. receivers .. "  exclusive/increase: " .. exclusiveReceivers .. " (incl.fees: " .. price ..")  F: " .. (exclusiveReceivers / price)
				else
					stationString = "tempStation is too expensive"
				end
			end

			--filter criterias
			if tempStation == nil then
				self:LogTrace(stationString)
				pos = nil -- prevent removing a position where a station should be
			elseif price < 0 then
				self:LogTrace(stationString .. " -> outside of map!")
				tempStation = nil
			elseif price > budget then
				--do nothing - no further checks no eliminating position
			elseif exclusiveReceivers / receivers < 0.7 then
				self:LogTrace(stationString .. " -> not enough exclusive receivers!")
				tempStation = nil
			--TODO make dynamic
			elseif coverage > 0.7 and tempStation:GetRunningCosts() / exclusiveReceivers > 0.395 then
				self:LogInfo(stationString .. " -> running costs too high!")
				tempStation = nil
			elseif tempStation:GetRunningCosts() / exclusiveReceivers > 0.595 then
				self:LogInfo(stationString .. " -> running costs too high!")
				tempStation = nil
			else
				self:LogTrace(stationString .. " -> OK!")
			end

			if tempStation == nil then
				table.insert(removeFromIntendedPositions, pos)
			elseif price <= budget then
			-- Liegt im Budget und lohnt sich minimal -> erfuellt Kriterien
				local attraction, price, exclusiveReceivers = self:GetAttraction(tempStation)

				if (bestOffer == nil or attraction > bestAttraction) and price <= budget and exclusiveReceivers < self.Task.maxReceiverIncrease then
					bestOffer = tempStation
					bestOffer = tempStation
					bestAttraction = attraction
					bestPosition = pos
				end
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

	return bestOffer, bestAttraction, bestPosition
end


function JobBuyStation:Tick()
	local player = getPlayer()

	local bestAntennaOffer, bestAntennaAttraction, bestAntennaPosition = self:GetBestAntennaOffer()
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
		bestAttraction = bestSatAttraction
	end

	if bestAttraction < 0 then bestOffer = nil end

	if bestOffer ~= nil then
		local price = bestOffer.GetTotalBuyPrice()
		local exclusiveReceivers = bestOffer.GetStationExclusiveReceivers()
		if bestOffer == bestAntennaOffer then
			local buyResult = TVT.of_buyAntennaStation(bestOffer.x, bestOffer.y)
			if buyResult == TVT.RESULT_OK then
				self:LogInfo("Buying antenna station in " .. bestOffer.GetSectionName() .. " at " .. bestOffer.x .. "," .. bestOffer.y .. ".  exclusive/increase: " .. exclusiveReceivers .. "  price: " .. price)
				table.removeElement(self.Task.intendedAntennaPositions, bestAntennaPosition)
			end
		elseif bestOffer == bestSatelliteOffer then
			self:LogInfo("Contracting satellite uplink " .. bestOffer.GetLongName() .. ".  exclusive/increase: " .. exclusiveReceivers .. "  price: " .. price)
			TVT.of_buySatelliteStation(bestSatIndex)
		elseif bestOffer == bestCableNetworkOffer then
			self:LogInfo("Contracting cable network uplink " .. bestOffer.GetLongName() .. ".  exclusive/increase: " .. exclusiveReceivers .. "  price: " .. price)
			TVT.of_buyCableNetworkStation(bestCableSectionName)
		end

		-- Wir brauchen noch ein "Fixkostenbudget" fuer Kabelnetze/Satelliten

		self.Task:PayFromBudget(price)
		self.Task.maxReceiverIncrease = self.Task.maxReceiverIncrease - exclusiveReceivers
		self.purchaseCount = self.purchaseCount + 1
	end

	if bestOffer == nil or self.Task.maxReceiverIncrease < 1000000 or self.Task.CurrentBudget < 300000 or self.purchaseCount >= 3 or getPlayer().minutesGone - self.Task.StartTask > 20 then
		self.Status = JOB_STATUS_DONE
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobSellStation"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobSellStation:typename()
	return "JobSellStation"
end

function JobSellStation:Prepare(pParams)
end

function JobSellStation:Tick()
	local player = getPlayer()
	local threshold = 0.6
	if player.coverage > 0.7 then threshold = 0.4 end
	if player.coverage > 0.20 and player.gameDay ~= self.Task.LastDaySell then
		local worstAntenna = nil
		local worstCost = 0
		local currentCost = 0
		local stationCount = TVT.of_getStationCount(TVT.ME)

		if stationCount > 0 then
			for stationIndex = 0, stationCount-1 do
				local station = TVT.of_getStationAtIndex(TVT.ME, stationIndex)
				if station ~= nil then
					currentCost = station.GetRunningCosts() / station.GetStationExclusiveReceivers()
					if currentCost > worstCost then
						worstCost = currentCost
						worstAntenna = stationIndex
					end
				end
			end
		end
		--TODO make dynamic
		if worstCost > threshold then
			if TVT.of_sellStation(worstAntenna) == TVT.RESULT_OK then
				self:LogInfo("successfully sold expensive station")
			else
				self:LogInfo("failed to sell expensive station ")
			end
		end
		self.Task.LastDaySell = player.gameDay
	end
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
