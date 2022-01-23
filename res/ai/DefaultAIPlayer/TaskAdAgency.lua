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

	--no budget to spare
	c.RequiresBudgetHandling = false

	-- zu Senden
	-- Strafe
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

	self.IdleJob = AIIdleJob()
	self.IdleJob.Task = self
	self.IdleJob:SetIdleTicks( math.random(5,15) )

	self.SpotsInAgency = {}
end


function TaskAdAgency:GetNextJobInTargetRoom()
	if (MY.GetProgrammeCollection().GetAdContractCount() >= 8) then
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

	elseif (self.IdleJob.Status ~= JOB_STATUS_DONE) then
		return self.IdleJob
	end

--	self:SetWait()
	self:SetDone()
end


function TaskAdAgency:getStrategicPriority()
	--debugMsg("TaskAdAgency:getStrategicPriority")

	local adCount = MY.GetProgrammeCollection().GetAdContractCount()

	-- we cannot sign new contracts at the ad agency - make the task
	-- not important for now
	if adCount >= TVT.Rules.adContractsPerPlayerMax then
		return 0.0
	elseif adCount >= 4 then
		--TODO more sophisticated - not only count but count for different levels
		return 0.3
	end
	return 1.0
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





function TaskAdAgency.SortAdContractsByAttraction(list)
	if (table.count(list) > 1) then
		-- precache complex weight calculation
		local weights = {}
		for k,v in pairs(list) do
			--is a single number for attraction possible?
			--profit/penalty per audience is not a good indicator!!
			--weights[ v.GetID() ] = (0.5 + 0.5*(0.9^v.GetSpotCount())) * v.GetProfitCPM(TVT.ME) * (0.8 + 0.2 * 1.0/v.GetPenaltyCPM(TVT.ME))
			weights[ v.GetID() ] = (0.5 + 0.5*(0.9^v.GetSpotCount())) * v.GetProfit(TVT.ME) * (0.8 + 0.2 * 1.0/v.GetPenalty(TVT.ME))
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
	--debugMsg("Schaue Werbeangebote an")
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
			local player = _G["globalPlayer"]
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
	--debugMsg("Bewerte/Vergleiche Werbeverträge")
	self.CurrentSpotIndex = 0
end

function AppraiseSpots:Tick()
	while self.Status ~= JOB_STATUS_DONE do
		self:AppraiseCurrentSpot()
	end
end

function AppraiseSpots:AppraiseCurrentSpot()
	local spot = self.Task.SpotsInAgency[self.CurrentSpotIndex]
	if (spot ~= nil) then
		self:AppraiseSpot(spot)
		self.CurrentSpotIndex = self.CurrentSpotIndex + 1
	else
		self.Status = JOB_STATUS_DONE
	end
end

function AppraiseSpots:AppraiseSpot(spot)
--	debugMsg("AppraiseSpot: " .. spot.GetTitle() )
--	debugMsg("===================")
	local player = _G["globalPlayer"]
	local stats = player.Stats
	local score = -1
	local spotMinAudience = spot.GetMinAudience(TVT.ME)

	--TODO WIP make problematic ads unattractive
	-- for now we do not modify our stats if they are special spots
	if (spot.GetLimitedToTargetGroup() > 0) or (spot.GetLimitedToProgrammeGenre() > 0) or (spot.GetLimitedToProgrammeFlag() > 0) then
		--debugMsg("  no special spots please")
		spot.SetAttractiveness(-1)
		return
	end

	--TODO more sophisticated max audience says only so much if all programmes have low topicality
	if (spotMinAudience > stats.Audience.MaxValue * 0.8) then
		--debugMsg("  too much audience! " .. spotMinAudience .. " / " .. stats.Audience.MaxValue)
		spot.SetAttractiveness(-1)
		return
	end


	local profitPerSpot = spot.GetProfit(TVT.ME) / spot.GetSpotCount()
	local penaltyPerSpot = spot.GetPenalty(TVT.ME) / spot.GetSpotCount()

	-- PROFIT
	-- 2 = paid well, 0.2 = way below average
	local profitFactorRaw = profitPerSpot / stats.SpotProfitPerSpot.AverageValue
	local profitFactor = CutFactor(profitFactorRaw, 0.2, 2)


	-- PENALTY
	-- 2 = low penalty, 0.2 = way too high penalty
	local penaltyFactorRaw = 1.0 / (penaltyPerSpot / stats.SpotPenaltyPerSpot.AverageValue)
	local penaltyFactor = CutFactor(penaltyFactorRaw, 0.2, 2)


	-- REQUIREMENTS
	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen
	local audienceFactorRaw = stats.Audience.AverageValue / spotMinAudience
	if audienceFactorRaw == nil then debugMsg("AUDIENCE NIL ... " .. stats.Audience.AverageValue) end
	local audienceFactor = CutFactor(audienceFactorRaw, 0.3, 2)

	--TODO nicht die Anzahl der Tage sind interessant sondern die Anzahl der potentiellen Slots
	-- DURATION / TIME CONSTRAINTS
	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactorRaw = spot.GetDaysToFinish() / spot.GetSpotCount()
	local pressureFactor = CutFactor(pressureFactorRaw, 0.2, 2)

--[[
	-- RISK / PENALTY
	-- 2 = Risiko und Strafe sind im Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactorRaw = profitFactor
	local riskFactor = CutFactor(riskFactorRaw, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)
--]]

	-- RESULTING ATTRACTION
	spot.SetAttractiveness(audienceFactor * (profitFactor * penaltyFactor) * pressureFactor)
--[[
	debugMsg("  Contract:  Spots=" .. spot.GetSpotsToSend() .."  days=" .. spot.GetDaysToFinish() .."  Audience=" .. spot.GetMinAudience(TVT.ME) .. "  Profit=" .. spot.GetProfit(TVT.ME) .." (per spot=" .. profitPerSpot .. ")  Penalty=" .. spot.GetPenalty(TVT.ME) .." (per spot=" .. penaltyPerSpot ..")")
	debugMsg("  Stats:     Avg.PerSpot Profit=" .. stats.SpotProfitPerSpot.AverageValue .. "  Penalty=" .. stats.SpotPenaltyPerSpot.AverageValue .."  Audience(Avg)=" .. stats.Audience.AverageValue)
	debugMsg("  Factors:   profit=" .. profitFactor .. "  (raw=" .. profitFactor .. ")  audience=" .. audienceFactor .. " (raw="..audienceFactorRaw ..")")
	debugMsg("             penalty=" .. penaltyFactor .. " (raw=" .. penaltyFactorRaw..")  pressure=" .. pressureFactor .. " (raw=" .. pressureFactorRaw ..")")
	debugMsg("  Attractiveness = " .. spot.GetAttractiveness())
	debugMsg("===================")
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
	--debugMsg("Unterschreibe benötigte Werbeverträge")
	self.CurrentSpotIndex = 0

	self.Player = _G["globalPlayer"]
	self.SpotRequisitions = self.Player:GetRequisitionsByTaskId(_G["TASK_ADAGENCY"])
end

function SignRequisitedContracts:Tick()
	--debugMsg("SignRequisitedContracts")

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

	for k,requisition in pairs(self.SpotRequisitions) do
		local neededSpotCount = requisition.Count
		local guessedAudience = requisition.GuessedAudience
		--TODO optimize factors for guessed audience especially for prime time programme
		if requisition.Level == 5 then
			guessedAudience = self:GetMinGuessedAudience(guessedAudience, 0.85)
		end

		debugMsg(" AdAgencyTick - requisition:  neededSpots="..neededSpotCount .."  guessedAudience="..math.floor(guessedAudience.GetTotalSum()))
		-- 0.9 and 0.7 may be too strict for finding contracts
		local signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.8), false)
--TODO prevent signing rubbish contract
--		if (signedContracts == 0 and tonumber(guessedAudience.GetTotalSum()) > 5000) then
		if (signedContracts == 0) then
			signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6), true)
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


function SignRequisitedContracts:SignMatchingContracts(requisition, guessedAudience, minGuessedAudience, isFallback)
	local signed = 0
	local boughtContracts = {}
	local neededSpotCount = requisition.Count

	if (neededSpotCount <= 0) then
		debugMsg("AI ERROR: SignMatchingContracts() with requisition.Count=0.", true)
		return 0
	end


	local availableList = self.Task.SpotsInAgency
	local filteredList = {}
	if table.count(availableList) > 0 then
		filteredList = FilterAdContractsByMinAudience(availableList, minGuessedAudience, guessedAudience)
		-- sort by spot count (less is better) and profit
		filteredList = TaskAdAgency.SortAdContractsByAttraction(filteredList)
	end
--[[
debugMsg("sort contractlist for " .. math.floor(minGuessedAudience.GetTotalSum()) .. " - " .. math.floor(guessedAudience.GetTotalSum()) .. "  entries=" .. table.count(filteredList))
for key, adContract in pairs(filteredList) do
	debugMsg(" - " .. adContract.GetTitle() .. "   minAudience=" .. adContract.GetMinAudience(TVT.ME) .. "  spots=" .. adContract.GetSpotCount() .. "  profit=" .. adContract.GetProfit(TVT.ME))
end
--]]
	for key, adContract in pairs(filteredList) do
		-- do not try to get more contracts than allowed
		if MY.GetProgrammeCollection().GetAdContractCount() >= TVT.Rules.adContractsPerPlayerMax then break end

		-- the more we need, the more likely we could finish even more
		local maxSurplusSpots = math.floor(0.5 * requisition.Count)
		if requisition.Level == 5 then
			--TODO optimize - for prime programmes, surplus count depends on guessed audience!
			if isFallback then
				maxSurplusSpots = math.max( maxSurplusSpots, math.random(0,1))
			else
				maxSurplusSpots = math.random(0,1)
			end
		elseif requisition.Level == 4 then
			maxSurplusSpots = math.max( maxSurplusSpots, math.random(1,2))
		else
			maxSurplusSpots = math.max( maxSurplusSpots, math.random(2,3))
		end
		-- max add the amount of the base requisition
		maxSurplusSpots = math.min(maxSurplusSpots, requisition.Count)

		--TODO optimize - only certain target groups are really dangerous
		if (requisition.Level ~=nil and requisition.Level > 4 and adContract.GetLimitedToTargetGroup() > 0) then maxSurplusSpots = 0 end

		--TODO optimize
		--skip manager and children target group at all - too dangerous
		if (adContract.GetLimitedToTargetGroup() == 1 or adContract.GetLimitedToTargetGroup() == 32) then
		-- skip if contract requires too many spots for the given level
		elseif adContract.GetSpotCount() > neededSpotCount + maxSurplusSpots then
			--debugMsg("   Skipping a \"necessary\" contract (too many spots: " .. adContract.GetSpotCount() .. " > ".. requisition.Count .." + "..maxSurplusSpots .. "): " .. adContract.GetTitle() .. " (" .. adContract.GetID() .. "). Level: " .. requisition.Level .. "  NeededSpots: " .. neededSpotCount.. "  MinAudience: " .. minAudienceValue .. "  GuessedAudience: " .. math.floor(minGuessedAudience.GetTotalSum()) .. " - " .. math.floor(guessedAudience.GetTotalSum()))
		-- sign if audience requirements are OK
		else
			local minGuessedAudienceValue = minGuessedAudience.GetTotalValue(adContract.GetLimitedToTargetGroup())
			local guessedAudienceValue = guessedAudience.GetTotalValue(adContract.GetLimitedToTargetGroup())
			debugMsg("   Signing a \"necessary\" contract: " .. adContract.GetTitle() .. " (" .. adContract.GetID() .. "). Level: " .. requisition.Level .. "  NeededSpots: " .. neededSpotCount.. " (+" .. maxSurplusSpots ..")  spotCount: " .. adContract.GetSpotCount() .."  guessedAudience=" .. math.floor(minGuessedAudienceValue) .. " - " .. math.floor(guessedAudienceValue) .." (total="..math.floor(guessedAudience.GetTotalSum()).. ")" )
			TVT.sa_doBuySpot(adContract.GetID())
			requisition:UseThisContract(adContract)
			table.insert(boughtContracts, adContract)
			signed = signed + 1

			-- remove available spots from the total amount of
			-- spots needed for this requirements
			neededSpotCount = neededSpotCount - adContract.GetSpotCount()
		end

		if (neededSpotCount <= 0) then
			self.Player:RemoveRequisition(requisition)
			-- do not sign any other contract for this requisition
			break
		else
			requisition.Count = neededSpotCount
		end
	end

	if (table.count(boughtContracts) > 0) then
		--debugMsg("  -> Remove " .. table.count(boughtContracts) .. " signed contracts from the agency-contract-list.")
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
	--debugMsg("Sign lucrative ad contracts")
	self.CurrentSpotIndex = 0
	self.lowAudienceFactor = 0.005
	self.ownedContracts = {};
	for i=0, (MY.GetProgrammeCollection().GetAdContractCount() - 1)
	do
		oc =  MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if oc ~= nil  then
			vc = self:newOwnedContract(oc)
			table.insert(self.ownedContracts, vc)
		end
	end
end


function SignContracts:newOwnedContract (c)
	local t =
	{
		title = "CONTRACT";
		minAudience = 0;
		spots = 0;
	}
	t.title = c.GetTitle()
	--debugMsg("  creating entry for ".. t.title)
	t.minAudience = c.GetMinAudience(TVT.ME)
	t.spots = c.getSpotsToSend()
	--debugMsg("  done creating entry for ".. t.title)
	return t;
end

-- sign "good contracts"
-- so contracts next to required ones
function SignContracts:Tick()
	if (self.Task.SpotsInAgency == nil) then return 0 end

	-- only sign contracts if we haven't enough unsent ad-spots
	local openSpots = self:GetUnsentSpotCount()
	local contractsAllowed = TVT.Rules.adContractsPerPlayerMax - MY.GetProgrammeCollection().GetAdContractCount()
	local haveLow = false


	-- check if we have a low end contract
	if contractsAllowed > 0 then
		local signedContracts = TaskAdAgency.GetAllAdContracts()
		local lowAudience = self.lowAudienceFactor * MY.GetMaxAudience()
		local lowUnsent = 0
		for key, contract in pairs(signedContracts) do
			if contract.GetMinAudience(TVT.ME) < lowAudience and contract.GetLimitedToTargetGroup() <= 0  then
				lowUnsent = lowUnsent + contract.GetSpotsToSend()
				if lowUnsent > 2 then
					haveLow = true
					break
				end
			end
		end
	end

	-- sign an emergency contract to at least have something to broadcast
	-- as infomercial if we do not have enough programme licences (or
	-- money to buy some)	-- try to find a contract with not too much spots / requirements
	if (not haveLow or openSpots < 4) and contractsAllowed > 0 then
		local availableList = table.copy(self.Task.SpotsInAgency)
		availableList = TaskAdAgency.SortAdContractsByAttraction(availableList)

		local filteredList = FilterAdContractsByMinAudience(availableList, self.lowAudienceFactor * MY.GetMaxAudience() / 2.5, self.lowAudienceFactor * MY.GetMaxAudience(), forbiddenIDs)
		if table.count(filteredList) > 0 then
			local contract = table.first(filteredList)

			local result = TVT.sa_doBuySpot(contract.GetID())
			if result == TVT.RESULT_OK then
				openSpots = openSpots + contract.GetSpotCount()
				contractsAllowed = contractsAllowed - 1
				table.insert(self.ownedContracts, self:newOwnedContract(contract))
				debugMsg("Signed an \"low audience\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME))
			else
				debugMsg("FAILED signing an \"low audience\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME) .. ". Failure code: " .. result)
			end


			-- loop over all contracts and remove the ones no longer available
			for i=#self.Task.SpotsInAgency,1,-1 do
				if self.Task.SpotsInAgency[i] == nil then
					table.remove(self.Task.SpotsInAgency, i)
				end
			end
		end
	end



	if openSpots < 8 and contractsAllowed > 0 then
		-- do not be too risky and avoid a non achieveable audience requirement
		local filteredList = FilterAdContractsByMinAudience(self.Task.SpotsInAgency, nil, 0.15 * MY.GetMaxAudience(), forbiddenIDs)
		-- sort it
		filteredList = TaskAdAgency.SortAdContractsByAttraction(filteredList)

		--iterate over the available contracts
		for key, contract in pairs(filteredList) do
			-- skip contracts requiring too much
			if self:ShouldSignContract(contract) == 1 then
				local result = TVT.sa_doBuySpot(contract.GetID())
				if result == TVT.RESULT_OK then
					openSpots = openSpots + contract.GetSpotCount()
					contractsAllowed = contractsAllowed - 1
					table.insert(self.ownedContracts, self:newOwnedContract(contract))

					debugMsg("Signed a \"good\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME))

				else
					debugMsg("FAILED signing a \"good\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME) .. ". Failure code: " .. result)
				end
				if openSpots <= 0 or contractsAllowed <= 0 then break end
			else
				-- debugMsg("min audience too low or found similar contract for " .. contract.getTitle())
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
function SignContracts:ShouldSignContract(contract)
	--not enough viewers
	if contract.GetLimitedToTargetGroup() <= 0 and contract.GetMinAudience(TVT.ME) < self.lowAudienceFactor * MY.GetMaxAudience() then
		return 0
	end

	--not attractive
	AppraiseSpots:AppraiseSpot(contract)
	if contract.getAttractiveness() < 0 then
		return 0
	end

	--TODO rather count spots of all similar
	--similar contract already exists
	local contractMin = contract.GetMinAudience(TVT.ME)
	for k, owned in pairs (self.ownedContracts) do
		--debugMsg("  checking owned contract " .. owned.title.." "..owned.spots.." "..owned.minAudience )
		if owned.spots > 2 then
			if owned.minAudience <= contractMin and owned.minAudience >= contractMin * 0.7 then
				return 0
			end
			if contractMin <= owned.minAudience and contractMin >= owned.minAudience * 0.7 then
				return 0
			end
		end
	end
	return 1
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