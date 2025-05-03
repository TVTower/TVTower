-- File: TaskAdAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskAdAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_ADAGENCY"]
	c.TargetRoom = TVT.ROOM_ADAGENCY
	c.SpotsInAgency = nil
	-- keep adagency task a bit lower priority: when adcontracts get
	-- requested by the schedule task, this already adds to end priority
	-- via "requisition priority"
	c.BasePriority = 3
	c.BudgetWeight = 0

	--budget handling for fixedCosts
	c.RequiresBudgetHandling = true
	--Strafen
	c.Penalties = {}

	-- zu Senden
	-- Zuschauer
	-- Zeit
end)

function TaskAdAgency:typename()
	return "TaskAdAgency"
end

function TaskAdAgency:Activate()
	-- Was getan werden soll:
	self.CheckSpots = JobCheckSpots()
	self.CheckSpots.Task = self

	self.AppraiseSpots = AppraiseSpots()
	self.AppraiseSpots.Task = self

	self.SignRequisitedContracts = SignRequisitedContracts()
	self.SignRequisitedContracts.Task = self

	self.SignContracts = SignContracts()
	self.SignContracts.Task = self

	self.SpotsInAgency = {}
	--self.LogLevel = LOG_TRACE
end


function TaskAdAgency:GetNextJobInTargetRoom()
	if (MY.GetProgrammeCollection().GetAdContractCount() >= TVT.Rules.adContractsPerPlayerMax) then
		self:SetDone()
		return nil
	elseif (self.CheckSpots.Status ~= JOB_STATUS_DONE) then
		return self.CheckSpots
	elseif (self.AppraiseSpots.Status ~= JOB_STATUS_DONE) then
		return self.AppraiseSpots
	elseif (self.SignRequisitedContracts.Status ~= JOB_STATUS_DONE) then
		return self.SignRequisitedContracts
	elseif (self.SignContracts.Status ~= JOB_STATUS_DONE) then
		return self.SignContracts
	end

	self:SetDone()
end


function TaskAdAgency:getStrategicPriority()
	local adCount = MY.GetProgrammeCollection().GetAdContractCount()

	-- we cannot sign new contracts at the ad agency - make the task
	-- not important for now
	if adCount >= TVT.Rules.adContractsPerPlayerMax then
		return 0.0
	elseif adCount >= 8 then
		--TODO more sophisticated - not only count but count for different levels
		return 0.3
	end
	return 1.0
end


function TaskAdAgency:OnMoneyChanged(value, reason, reference)
	--naive statistics on contracts with penalty
	--increase count with each penalty paid and consequently reduce attractiveness for this spot
	--start counting on day 4, in the first days failures are not "systematic"
	reason = tonumber(reason)
	if reason == TVT.Constants.PlayerFinanceEntryType.PAY_PENALTY and getPlayer().gameDay > 4 then
		if self.Penalties == nil then self.Penalties = {} end
		--reference.id --id is different for each contract instance
		local id = reference:GetTitle() 
		local entry = self.Penalties[id]
		if entry == nil then
			entry = {
				title = reference:GetTitle();
				penaltyCount = 0;
				penaltySum = 0;
			}
			self.Penalties[id] = entry
		end
		entry.penaltyCount = entry.penaltyCount + 1
		entry.penaltySum = entry.penaltySum + value
		self:LogInfo("pay ad penalty: " .. entry.title .. " - count "..entry.penaltyCount .." penalty sum "..entry.penaltySum)
	end
end


function TaskAdAgency.GetAllAdContracts()
	local response = TVT.sa_getSignedAdContracts()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end
	local allContracts = {}

	for i, contract in ipairs(response.DataArray()) do
		--only add contracts
		if (contract ~= nil) then
			-- local addIt = true
			-- if ... checks ... are any required?

			table.insert(allContracts, contract)
		end
	end
	return allContracts
end





function TaskAdAgency.SortAdContractsByAttraction(list, penalties)
	if (table.count(list) > 1) then
		-- precache complex weight calculation
		local weights = {}
		if penalties == nil then penalties = {} end
		for k,v in pairs(list) do
			--is a single number for attraction possible?
			--profit/penalty per audience is not a good indicator!!
			--TODO compare different weight functions
			--weights[ v.GetID() ] = (0.5 + 0.5*(0.9^v.GetSpotCount())) * v.GetProfitCPM(TVT.ME) * (0.8 + 0.2 * 1.0/v.GetPenaltyCPM(TVT.ME))
			--weights[ v.GetID() ] = (0.5 + 0.5*(0.9^v.GetSpotCount())) * v.GetProfit(TVT.ME) * (0.8 + 0.2 * 1.0/v.GetPenalty(TVT.ME))
			--ignore penalty but make spot count more important (increases risk as well)
			local count = v.GetSpotCount()
			local profit = v.GetProfit(TVT.ME)
			local id = v.GetID()
			if count > 3 and 2 * profit < v.GetPenalty(TVT.ME) then
				--ignore high risk ad
				weights[ id ] = 0
			else
				weights[ id ] = (0.5 + 0.5*(0.85^(count-1)) * profit / count)
			end
			local penalty = penalties[v.GetTitle()]
			if penalty ~= nil then
				weights[ id ] = weights[ id ] / (1.5 ^ penalty.penaltyCount)
			end
		end

		-- sort
		local sortMethod = function(a, b)
			if a == nil then return false end
			if b == nil then return true end
			return weights[ a.GetID() ] > weights[ b.GetID() ]
		end
		table.sort(list, sortMethod)
	end

	return list
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobCheckSpots"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentSpotIndex = 0
	c.Task = nil
end)

function JobCheckSpots:typename()
	return "JobCheckSpots"
end

function JobCheckSpots:Prepare(pParams)
	self.CurrentSpotIndex = 0
end

function JobCheckSpots:Tick()
	while self.Status ~= JOB_STATUS_DONE do
		self:CheckSpot()

		-- checked last spot?
		if self.CurrentSpotIndex >= TVT.sa_getSpotCount() then
			self.Status = JOB_STATUS_DONE
		end
	end
end

function JobCheckSpots:CheckSpot()
	local response = TVT.sa_getSpot(self.CurrentSpotIndex)
	if (response.result == TVT.RESULT_WRONGROOM) then
		self.Status = JOB_STATUS_DONE
		return
	end


	if (response.result == TVT.RESULT_OK) then
		local adContract = response.data
		if (adContract.IsAvailableToSign(TVT.ME) == 1) then
			local player = getPlayer()
			self.Task.SpotsInAgency[self.CurrentSpotIndex] = adContract
			player.Stats:AddSpot(adContract)
		end
	end

	-- continue with next spot, even with TVT.RESULT_NOT_ALLOWED (channel
	-- image not satisfied or another requirement)
	self.CurrentSpotIndex = self.CurrentSpotIndex + 1
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AppraiseSpots"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentSpotIndex = 0;
	c.Task = nil
end)

function AppraiseSpots:typename()
	return "AppraiseSpots"
end

function AppraiseSpots:Prepare(pParams)
	self.CurrentSpotIndex = 0
end

function AppraiseSpots:Tick()
	while self.Status ~= JOB_STATUS_DONE do
		self:AppraiseCurrentSpot()
	end
end

function AppraiseSpots:AppraiseCurrentSpot()
	local spot = self.Task.SpotsInAgency[self.CurrentSpotIndex]
	self.CurrentSpotIndex = self.CurrentSpotIndex + 1
	if (spot ~= nil) then
		self:AppraiseSpot(spot)
	elseif self.CurrentSpotIndex >= #self.Task.SpotsInAgency then
		self.Status = JOB_STATUS_DONE
	end
end

function AppraiseSpots:AppraiseSpot(spot)
	self:LogTrace("===================")
	self:LogTrace("AppraiseSpot: " .. spot.GetTitle() )
	local player = getPlayer()
	local stats = player.Stats
	local score = -1
	local spotMinAudience = spot.GetMinAudience(TVT.ME)

	--TODO WIP make problematic ads unattractive
	-- for now we do not modify our stats if they are special spots
	if (spot.GetLimitedToProgrammeGenre() > 0) or (spot.GetLimitedToProgrammeFlag() > 0) or (spot.GetForbiddenProgrammeFlag() > 0) then
		self:LogTrace("  no special spots please")
		spot.SetAttractivenessString("-1")
		return
	end

--[[
	--TODO more sophisticated max audience says only so much if all programmes have low topicality
	if (spotMinAudience > (stats.Audience.MaxValue + stats.Audience.TotalMaxValue) * 0.4) then
		self:LogTrace("  too much audience! " .. spotMinAudience .. " / " .. stats.Audience.MaxValue)
		spot.SetAttractivenessString("-1")
		return
	end
--]]

	local spotCount = spot.GetSpotCount()
	local profitPerSpot = spot.GetProfit(TVT.ME) / spotCount
	local penaltyPerSpot = spot.GetPenalty(TVT.ME) / spotCount

	-- PROFIT
	-- 2 = paid well, 0.2 = way below average
	local profitFactorRaw = profitPerSpot / stats.SpotProfitPerSpot.AverageValue
	local profitFactor = CutFactor(profitFactorRaw, 0.2, 2)


	-- PENALTY
	-- 2 = low penalty, 0.2 = way too high penalty
	local penaltyFactorRaw = 1.0 / (penaltyPerSpot / stats.SpotPenaltyPerSpot.AverageValue)
	penaltyFactorRaw = penaltyFactorRaw / (1.1 ^ (spotCount - 1))
	local penaltyFactor = CutFactor(penaltyFactorRaw, 0.2, 2)


	-- REQUIREMENTS
	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen
	local audienceFactorRaw = stats.Audience.AverageValue / spotMinAudience
	local audienceFactor = CutFactor(audienceFactorRaw, 0.3, 2)

	if audienceFactor < 0.5 and player.blocksCount < 72 and spotCount > 3 then audienceFactor = 0 end

	--TODO nicht die Anzahl der Tage sind interessant sondern die Anzahl der potentiellen Slots
	-- DURATION / TIME CONSTRAINTS
	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactorRaw = spot.GetDaysToFinish() / spotCount
	local pressureFactor = CutFactor(pressureFactorRaw, 0.2, 2)

	local paidPenaltyFactor = 1
	if self.Task.Penalties ~= nil then
		local entry = self.Task.Penalties[spot.GetTitle()]
		if entry ~=nil then paidPenaltyFactor =  1 / (1.25 ^ entry.penaltyCount) end
	end
	
--[[
	-- RISK / PENALTY
	-- 2 = Risiko und Strafe sind im Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactorRaw = profitFactor
	local riskFactor = CutFactor(riskFactorRaw, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)
--]]

	-- RESULTING ATTRACTION
	spot.SetAttractivenessString(tostring(audienceFactor * (profitFactor * penaltyFactor) * pressureFactor * paidPenaltyFactor))
--[[
	self:LogTrace("  Contract:  Spots=" .. spot.GetSpotsToSend() .."  days=" .. spot.GetDaysToFinish() .."  Audience=" .. spot.GetMinAudience(TVT.ME) .. "  Profit=" .. spot.GetProfit(TVT.ME) .." (per spot=" .. profitPerSpot .. ")  Penalty=" .. spot.GetPenalty(TVT.ME) .." (per spot=" .. penaltyPerSpot ..")")
	self:LogTrace("  Stats:     Avg.PerSpot Profit=" .. stats.SpotProfitPerSpot.AverageValue .. "  Penalty=" .. stats.SpotPenaltyPerSpot.AverageValue .."  Audience(Avg)=" .. stats.Audience.AverageValue)
	self:LogTrace("  Factors:   profit=" .. profitFactor .. "  (raw=" .. profitFactor .. ")  audience=" .. audienceFactor .. " (raw="..audienceFactorRaw ..")")
	self:LogTrace("             penalty=" .. penaltyFactor .. " (raw=" .. penaltyFactorRaw..")  pressure=" .. pressureFactor .. " (raw=" .. pressureFactorRaw ..")")
	self:LogTrace("  Attractiveness = " .. spot.GetAttractiveness())
	self:LogTrace("===================")
--]]
	--financeBase

	-- Je höher der Gewinn desto besser
	-- Je höher die Strafe desto schlechter
	-- Je geringer die benötigten Zuschauer desto besser
	-- Je weniger Spots desto besser
	-- Je mehr Zeit desto besser
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SignRequisitedContracts"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentSpotIndex = 0
	c.Task = nil
end)

function SignRequisitedContracts:typename()
	return "SignRequisitedContracts"
end

function SignRequisitedContracts:Prepare(pParams)
	self.CurrentSpotIndex = 0
	self.maxAudience = MY.GetChannelReceivers()
	self.highAudienceFactor = 0.08
	self.avgAudienceFactor = 0.045
	self.lowAudienceFactor = 0.003

	self.Player = getPlayer()
	if self.Player.blocksCount < 72 then self.lowAudienceFactor = 0.0025 end
	self.SpotRequisitions = self.Player:GetRequisitionsByTaskId(_G["TASK_ADAGENCY"])
end

function SignRequisitedContracts:Tick()
	if (self.Task.SpotsInAgency ~= nil) then
		--sort
		local sortMethod = function(a, b)
			return a.GetAttractiveness() > b.GetAttractiveness()
		end

		-- loop over all contracts and remove the ones no longer available
		for i=#self.Task.SpotsInAgency,1,-1 do
			if self.Task.SpotsInAgency[i] == nil then
				table.remove(self.Task.SpotsInAgency, i)
			end
		end

		table.sort(self.Task.SpotsInAgency, sortMethod)
	end

	local sortTable = {}
	for k,v in pairs(self.SpotRequisitions) do
		table.insert(sortTable, v)
	end
	if self.Player.hour > 10 then
		local sortMethod = function(a, b)
			return a.Level > b.Level
 		end
		table.sort(sortTable, sortMethod)
	end

	for k,requisition in pairs(sortTable) do
		if (requisition.Hour ~= nil and requisition.Level > 4 and self.Player.hour > requisition.Hour - 1) then
			self:LogDebug("discarding requisition - to late to complete")
			--self.Player:RemoveRequisition(requisition)
			--TODO check req removal
			--requisition:RemoveSlotRequisitionByTime(self.Player.day, self.Player.hour - 1)
			requisition:RemoveSlotRequisitionByTime(self.Player.day, self.Player.hour - 2)
		end
		local neededSpotCount = requisition.Count
		local guessedAudience = requisition.GuessedAudience

		self:LogDebug("  process ad requisition:  neededSpots="..neededSpotCount .."  guessedAudience="..math.floor(guessedAudience.GetTotalSum()))
		-- 0.9 and 0.7 may be too strict for finding contracts
		local signedContracts
		if requisition.Level < 4 or self.Player.hour < 21 then
			if requisition.Level < 4  and self.Player.blocksCount > 48 then
				--for lower level often aggregated req. (min of guesses), so accept contracts with higher audience
				signedContracts = self:SignMatchingContracts(requisition, self:GetMinGuessedAudience(guessedAudience, 1.25), self:GetMinGuessedAudience(guessedAudience, 0.75), 0)
			else
				signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.75), 0)
			end
	--TODO prevent signing rubbish contract
	--		if (signedContracts == 0 and tonumber(guessedAudience.GetTotalSum()) > 5000) then
			if (signedContracts == 0) then
				signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6), 1)
			end
		end
		if (signedContracts == 0 and requisition.Level > 4 and self.Player.hour > 17) then
			signedContracts = self:SignMatchingContracts(requisition, self:GetMinGuessedAudience(guessedAudience, 0.7), self:GetMinGuessedAudience(guessedAudience, 0.5), 2)
		end
	end
	self.Status = JOB_STATUS_DONE
end



function SignRequisitedContracts:GetMinGuessedAudience(guessedAudience, minFactor)
	if minFactor == 1.0 then
		return guessedAudience
	end

	if (guessedAudience.GetTotalSum() < 1000) then
		return TVT.audiencePredictor.GetEmptyAudience()
	else
		return guessedAudience.Copy().MultiplyString(tostring(minFactor))
	end
end


function SignRequisitedContracts:SignMatchingContracts(requisition, guessedAudience, minGuessedAudience, fallBackMode)
	local signed = 0
	local boughtContracts = {}
	local neededSpotCount = requisition.Count

	if (neededSpotCount <= 0) then
		self:LogError("SignMatchingContracts() with requisition.Count=0.")
		return 0
	end

	--TODO check existing contracts!!

	local availableList = self.Task.SpotsInAgency
	local filteredList = {}
	if table.count(availableList) > 0 then
		filteredList = FilterAdContractsByMinAudience(availableList, minGuessedAudience, guessedAudience)
		-- sort by spot count (less is better) and profit
		filteredList = TaskAdAgency.SortAdContractsByAttraction(filteredList, self.Task.Penalties)
	end
	--TODO log with guard
--[[
	self:LogTrace("sort contractlist for " .. math.floor(minGuessedAudience.GetTotalSum()) .. " - " .. math.floor(guessedAudience.GetTotalSum()) .. "  entries=" .. table.count(filteredList))
	for key, adContract in pairs(filteredList) do
		self:LogTrace(" - " .. adContract.GetTitle() .. "   minAudience=" .. adContract.GetMinAudience(TVT.ME) .. "  spots=" .. adContract.GetSpotCount() .. "  profit=" .. adContract.GetProfit(TVT.ME))
	end
--]]
	--TODO do not sign really low audience contracts!
	--raise min audience to certain level or prevent requisition
	local veryHighAudience = self.maxAudience * 0.105
	local highAudience = self.maxAudience * self.highAudienceFactor
	local avgAudience = self.maxAudience * self.avgAudienceFactor
	local lowAudience = self.maxAudience * self.lowAudienceFactor
	local tooLow = false
	local easy = false
	local avg = false
	local hard = false
	local veryhard = false
	local maxTopBlocks = self.Player.maxTopicalityBlocksCount
	local blocks = self.Player.blocksCount
	local audienceTotal = guessedAudience:GetTotalSum()
	if audienceTotal > veryHighAudience then
		veryhard = true
	end
	if audienceTotal > highAudience then
		hard = true
	elseif audienceTotal > avgAudience then
		avg = true
	elseif audienceTotal < lowAudience and fallBackMode > 0 then
		tooLow = true
	else
		easy = true
	end

	for key, adContract in pairs(filteredList) do
		-- do not try to get more contracts than allowed
		if MY.GetProgrammeCollection().GetAdContractCount() >= TVT.Rules.adContractsPerPlayerMax then break end

		local doSign = false
		local spotCount = adContract.GetSpotCount()
		local spotsLeft = spotCount - neededSpotCount
		local targetGroup = adContract.GetLimitedToTargetGroup()

		--self:LogInfo("considering " .. adContract.getTitle() .. " " .. adContract.GetMinAudience(TVT.ME))
		if tooLow == true then
			self:LogDebug("ignoring fallback requisition for audience".. audienceTotal)
		elseif targetGroup == 1 then
			self:LogDebug("ignoring children contract")
		elseif targetGroup == 32 and (veryhard == true or spotCount > 2 or spotsLeft > 0) then
			self:LogDebug("ignoring manager contract")
		elseif adContract.GetLimitedToProgrammeGenre() > 0 or adContract.GetLimitedToProgrammeFlag() > 0 or adContract.GetForbiddenProgrammeFlag() > 0 then
			self:LogDebug("ignoring contract with genre limit")
		elseif blocks < 72 and easy ~= true and spotCount > 4 then
			self:LogDebug("ignoring contract with too many blocks")
		elseif veryhard == true and self.Player.coverage > 0.9 and spotCount > 1 then
			self:LogDebug("ignoring very hard contracts on high coverage")
		elseif spotsLeft <= 0 then
			doSign = true
		elseif veryhard == true and self.Player.coverage > 0.9 then
			self:LogDebug("ignoring very hard contracts on high coverage")
		elseif neededSpotCount == 1 and requisition.Priority < 3 then
			self:LogDebug("ignore requisition - only one spot with low priority")
		else
			--TODO use achieved rather than daysleft
			--local achievedPerDayCount, achievedPerDayGoodFit = AITools:GetNumberOfSlots(self.Player, adContract, adContract.GetMinAudience(TVT.ME))
			local daysToFinish = adContract.GetDaysToFinish()
			if spotCount > 3 and adContract.GetProfit(-1) * 2 < adContract.GetPenalty(-1) then
				--do not sign if penalty ratio is too high
			elseif hard == true then
				--TODO achievedSpots also for hard?
				if maxTopBlocks < 8 then
					daysToFinish = daysToFinish -1
				end
				if fallBackMode == 0 then
					--always sign still causes too many penalties - randomize
					if self.Player.difficulty ~= "hard" and spotsLeft < 2 and spotsLeft < daysToFinish and math.random(0,100) > 60 then doSign = true end
				elseif fallBackMode == 1 then
					if spotsLeft < 2 and spotsLeft < daysToFinish and math.random(0,100) > 30 then doSign = true end
				else
					if spotsLeft < 3 and spotsLeft < daysToFinish then doSign = true end
				end
			elseif avg == true then
				if spotsLeft < 4 and spotsLeft < daysToFinish * 1.5 then doSign = true end
				--if spotsLeft <= achievedPerDayGoodFit then doSign = true end
			else
				--TODO even for easy contracs too many spots left may be harmful
				if spotsLeft < 4 and spotsLeft < daysToFinish * 2 then doSign = true end
				--if spotsLeft <= achievedPerDayGoodFit then doSign = true end
			end
		end

		--TODO optimize - only certain target groups are really dangerous
		--if (requisition.Level ~=nil and requisition.Level > 4 and adContract.GetLimitedToTargetGroup() > 0) then maxSurplusSpots = 0 end

		if doSign == true then
			local minGuessedAudienceValue = minGuessedAudience.GetTotalValue(adContract.GetLimitedToTargetGroup())
			local guessedAudienceValue = guessedAudience.GetTotalValue(adContract.GetLimitedToTargetGroup())
			self:LogInfo("   Signing a \"necessary\" contract: " .. adContract.GetTitle() .. " (" .. adContract.GetID() .. "). Level: " .. requisition.Level .. "  NeededSpots: " .. neededSpotCount.. "  spotCount: " .. spotCount .."  guessedAudience=" .. math.floor(minGuessedAudienceValue) .. " - " .. math.floor(guessedAudienceValue) .." (total="..math.floor(guessedAudience.GetTotalSum()).. ")" )
			TVT.sa_doBuySpot(adContract.GetID())
			requisition:UseThisContract(adContract)
			table.insert(boughtContracts, adContract)
			signed = signed + 1

			-- remove available spots from the total amount of
			-- spots needed for this requirements
			neededSpotCount = neededSpotCount - spotCount
		end

		if (neededSpotCount <= 0) then
			self.Player:RemoveRequisition(requisition)
			-- do not sign any other contract for this requisition
			break
		else
			requisition.Count = neededSpotCount
		end
	end

	local boughtCount = table.count(boughtContracts)
	if (boughtCount > 0) then
		self:LogTrace("  -> Remove " .. boughtCount .. " signed contracts from the agency-contract-list.")
		table.removeCollection(self.Task.SpotsInAgency, boughtContracts)
	end

	return signed
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SignContracts"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentSpotIndex = 0
	c.Task = nil
	c.ownedContracts = nil
end)


function SignContracts:typename()
	return "SignContracts"
end


--self.SpotRequisition = self.Player:GetRequisitionsByOwner(_G["TASK_SCHEDULE"])
function SignContracts:Prepare(pParams)
	self.CurrentSpotIndex = 0
	self.lowAudienceFactor = 0.005
	self.maxAudience = MY.GetChannelReceivers()
	self.ownedContracts = {};
	--heuristic for licence max price - possible income per spot
	local maxIncomePerSpot = 0
	for i=0, (MY.GetProgrammeCollection().GetAdContractCount() - 1)
	do
		oc =  MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if oc ~= nil  then
			vc = self:newOwnedContract(oc)
			if vc.incomePerSpot > maxIncomePerSpot then maxIncomePerSpot = vc.incomePerSpot end
			table.insert(self.ownedContracts, vc)
		end
	end
	self.player = getPlayer()
	if (self.player.maxIncomePerSpot==nil or self.player.maxIncomePerSpot < maxIncomePerSpot) then self.player.maxIncomePerSpot = maxIncomePerSpot end
end


function SignContracts:newOwnedContract (c)
	local t =
	{
		title = "CONTRACT";
		minAudience = 0;
		spots = 0;
		planned = 0;
		incomePerSpot = 0;
		targetGroup = 0;
		daysLeft = 0;
	}
	t.title = c.GetTitle()
	t.minAudience = c.GetTotalMinAudience(TVT.ME)
	t.targetGroup = c.GetLimitedToTargetGroup()
	t.spots = c.getSpotsToSend()
	t.planned = c.getSpotsPlanned()
	t.incomePerSpot = c.GetProfit(TVT.ME) / c.getSpotCount()
	t.daysLeft = c.GetDaysLeft(-1)
	--t.spotsPerDay = t.spots / (0.7 * c:GetDaysLeft())
	return t;
end

-- sign "good contracts"
-- so contracts next to required ones
function SignContracts:Tick()
	if (self.Task.SpotsInAgency == nil) then return 0 end

	-- only sign contracts if we haven't enough unsent ad-spots
	local openSpots = self:GetUnsentSpotCount()
	local contractsAllowed = TVT.Rules.adContractsPerPlayerMax - MY.GetProgrammeCollection().GetAdContractCount()-1
	local haveLow = false

	local signedContracts = TaskAdAgency.GetAllAdContracts()
	--count penalty for failed contracts as fixed costs
	local fixedCosts = 0
	local player = getPlayer()
	if player.hour > 19 or player.coverage > 0.9 then
		local threshold = 0
--		if player.coverage > 0.9 then threshold = 1 end
		for key, contract in pairs(signedContracts) do
			if contract ~= nil then
				if contract:GetDaysLeft(-1) <= threshold then fixedCosts = fixedCosts + contract.getPenalty(TVT.ME)/2 end
			end
		end
	end
	self.Task.FixedCosts = fixedCosts

	--TODO open spots count must not be too low (e.g. due to low audience contracts)
	--otherwise good average audience contracts cannot be signed without requisition
	if openSpots < 18 and contractsAllowed > 0 then
		-- do not be too risky and avoid a non achieveable audience requirement
		local filteredList = FilterAdContractsByMinAudience(self.Task.SpotsInAgency,  0.002 * self.maxAudience, 0.1 * self.maxAudience, forbiddenIDs)
		-- sort it
		filteredList = TaskAdAgency.SortAdContractsByAttraction(filteredList, self.Task.Penalties)

		--iterate over the available contracts
		for key, contract in pairs(filteredList) do
			-- skip contracts requiring too much
			if self:ShouldSignContract(contract) == 1 then
				local result = TVT.sa_doBuySpot(contract.GetID())
				if result == TVT.RESULT_OK then
					openSpots = openSpots + contract.GetSpotCount()
					contractsAllowed = contractsAllowed - 1
					table.insert(self.ownedContracts, self:newOwnedContract(contract))
					contract.SetAttractivenessString("-0.5")--for marking contract obtained as "good" rather than "required" in debug screen

					self:LogInfo("Signed a \"good\" contract: " .. contract.GetTitle() .. ". MinAudience: " .. contract.GetMinAudience(TVT.ME))

				else
					self:LogError("FAILED signing a \"good\" contract: " .. contract.GetTitle() .. ". MinAudience: " .. contract.GetMinAudience(TVT.ME) .. ". Failure code: " .. result)
				end
				if openSpots <= 0 or contractsAllowed <= 0 then break end
			else
				self:LogDebug("contract rejected (e.g. found similar contract): " .. contract.getTitle())
			end
		end
	end

	-- loop over all contracts and remove the ones no longer available
	for i=#self.Task.SpotsInAgency,1,-1 do
		if self.Task.SpotsInAgency[i] == nil then
			table.remove(self.Task.SpotsInAgency, i)
		end
	end

	self.Status = JOB_STATUS_DONE
end

--TODO CHECK should sign
--explicitly look for prime spots (one or two extra for late high audience)
function SignContracts:ShouldSignContract(contract)
	local spotMinAudience = contract.GetTotalMinAudience(TVT.ME)

	local spotCount = contract.GetSpotCount()
	local achieved = 0
	local similar = 5
	local achievedOnlyDuringPrime = true
	local targetGroup = contract.GetLimitedToTargetGroup()
	local maxAllowed = 4
	if targetGroup == 1 then --children
		maxAllowed = 0
	elseif targetGroup == 2 or targetGroup == 32 then -- teenagers, managers
		maxAllowed = 2
	elseif contract.GetLimitedToProgrammeGenre() > 0 or contract.GetLimitedToProgrammeFlag() > 0 or contract.GetForbiddenProgrammeFlag() > 0 then
		maxAllowed = 0
	end

	if spotCount <= maxAllowed then
		achieved, similar, achievedOnlyDuringPrime = self:AnalyzeGoodContract(contract, spotMinAudience)
		self:LogInfo("  found interesting regular spot " .. " "..contract.GetTitle().." ".. achieved.." ".. similar .." ".. contract.getAttractiveness())
		if achieved > 0 and achieved > (spotCount-2) then
			if achievedOnlyDuringPrime then
				if self.player.hour > 20 then return 0 end
				if targetGroup > 0 and spotCount > 3 then return 0 end
				if self.player.blocksCount < 48 and spotCount > 2 then return 0 end
				if (self.player.maxTopicalityBlocksCount < 4 or self.player.money < 500000) and spotCount > 1 then return 0 end
				if self.player.coverage > 0.75 and spotMinAudience > self.maxAudience * 0.11 then return 0 end
				--TODO few max top too many spots ->no
			end
			if targetGroup == 32 and achieved < spotCount then return 0 end
			if similar < spotCount then
				return 1
			end
		end
	end
	return 0
end

function SignContracts:AnalyzeGoodContract(contract, minAudience)
	local achieved = 0
	local unsentSimilar = 0
	local achivedOnlyInPrime = true
	--TODO check if only achieved during prime time
	if self.player.Stats ~= nil and self.player.Stats.BroadcastStatistics~=nil then
		local st = self.player.Stats.BroadcastStatistics.hourlyProgrammeAudience
		local yesterday = TVT.GetDay()-1
		if st ~=nil then
			for k,v in pairs(st) do
				local key = tonumber(k)
				local hour = key % 100
				local day = (key-hour)/100
				if day == yesterday then

					local aud = v.Audience
					local sum = aud.GetTotalValue(tg)
					if sum >= minAudience and sum * 0.6 < minAudience then
						achieved = achieved +1
						if hour < 19 then achivedOnlyInPrime = false end
					end
				end
			end
		end
	end
	if achieved > 0 then
		for k, owned in pairs (self.ownedContracts) do
			self:LogTrace("  checking owned contract " .. owned.title.." "..owned.spots.." "..owned.planned.." "..owned.minAudience )
			if owned.minAudience <= minAudience and owned.minAudience >= minAudience * 0.75 then
				unsentSimilar = unsentSimilar + (owned.spots-owned.planned)
			end
			if minAudience <= owned.minAudience and minAudience >= owned.minAudience * 0.75 then
				unsentSimilar = unsentSimilar + (owned.spots-owned.planned)
			end
			--TODO check for contracts in danger
		end
	end
	return achieved, unsentSimilar, achivedOnlyInPrime
end

--returns amount of unsent adcontract-spots
function SignContracts:GetUnsentSpotCount()
	local unsentSpots = 0

	for i = 0, MY.GetProgrammeCollection().GetAdContractCount() - 1 do
		local contract = MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if (contract~=nil and contract.IsCompleted() ~= 1) then
			unsentSpots = unsentSpots + contract.GetSpotsToSend()
		end
	end

	return unsentSpots
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
