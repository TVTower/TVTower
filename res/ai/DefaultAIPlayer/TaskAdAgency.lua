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
	self.CheckSpots.AdAgencyTask = self

	self.AppraiseSpots = AppraiseSpots()
	self.AppraiseSpots.AdAgencyTask = self

	self.SignRequisitedContracts = SignRequisitedContracts()
	self.SignRequisitedContracts.AdAgencyTask = self

	self.SignContracts = SignContracts()
	self.SignContracts.AdAgencyTask = self

	self.IdleJob = AIIdleJob()
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

	-- we cannot sign new contracts at the ad agency - make the task
	-- not important for now
	if MY.GetProgrammeCollection().GetAdContractCount() >= TVT.Rules.adContractsPerPlayerMax then
		return 0.0
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
			weights[ v.GetID() ] = (0.5 + 0.5*(0.9^v.GetSpotCount())) * v.GetProfitCPM(TVT.ME) * (0.8 + 0.2 * 1.0/v.GetPenaltyCPM(TVT.ME))
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
	c.AdAgencyTask = nil
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
			self.AdAgencyTask.SpotsInAgency[self.CurrentSpotIndex] = adContract
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
	c.AdAgencyTask = nil
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
	local spot = self.AdAgencyTask.SpotsInAgency[self.CurrentSpotIndex]
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

	-- for now we do not modify our stats if they are special spots
	if (spot.GetLimitedToTargetGroup() > 0) or (spot.GetLimitedToProgrammeGenre() > 0) or (spot.GetLimitedToProgrammeFlag() > 0) then
		return
	end

	if (spot.GetMinAudience(TVT.ME) > stats.Audience.MaxValue) then
		--spot.Appraisal = -2
--		debugMsg("  too much audience! " .. spot.GetMinAudience(TVT.ME) .. " / " .. stats.Audience.MaxValue)
		return
	end


	local profitCPMPerSpot = spot.GetProfitCPM(TVT.ME) / spot.GetSpotCount()
	local penaltyCPMPerSpot = spot.GetPenaltyCPM(TVT.ME) / spot.GetSpotCount()

	-- PROFIT
	-- 2 = paid well, 0.2 = way below average
	local profitFactorRaw = profitCPMPerSpot / stats.SpotProfitCPMPerSpotAcceptable.AverageValue
	local profitFactor = CutFactor(profitFactorRaw, 0.2, 2)


	-- PENALTY
	-- 2 = low penalty, 0.2 = way too high penalty
	local penaltyFactorRaw = 1.0 / (penaltyCPMPerSpot / stats.SpotPenaltyCPMPerSpotAcceptable.AverageValue)
	local penaltyFactor = CutFactor(penaltyFactorRaw, 0.2, 2)


	-- REQUIREMENTS
	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen
	local audienceFactorRaw = stats.Audience.AverageValue / spot.GetMinAudience(TVT.ME)
	if audienceFactorRaw == nil then debugMsg("AUDIENCE NIL ... " .. stats.Audience.AverageValue) end
	local audienceFactor = CutFactor(audienceFactorRaw, 0.3, 2)


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
	debugMsg("  Contract:  Spots=" .. spot.GetSpotsToSend() .."  days=" .. spot.GetDaysToFinish() .."  Audience=" .. spot.GetMinAudience(TVT.ME) .. "  Profit=" .. spot.GetProfit(TVT.ME) .." (CPM/spot=" .. profitCPMPerSpot .. ")  Penalty=" .. spot.GetPenalty(TVT.ME) .." (CPM/spot=" .. penaltyCPMPerSpot ..")")
	debugMsg("  Stats:     Avg.PerSpotAcceptible Profit=" .. stats.SpotProfitCPMPerSpotAcceptable.AverageValue .. "  Penalty=" .. stats.SpotPenaltyCPMPerSpotAcceptable.AverageValue .."  Audience(Avg)=" .. stats.Audience.AverageValue)
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
	c.AdAgencyTask = nil
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

	if (self.AdAgencyTask.SpotsInAgency ~= nil) then
		--sort
		local sortMethod = function(a, b)
			return a.GetAttractiveness() > b.GetAttractiveness()
		end

		-- loop over all contracts and remove the ones no longer available
		for i=#self.AdAgencyTask.SpotsInAgency,1,-1 do
			if self.AdAgencyTask.SpotsInAgency[i] == nil then
				table.remove(self.AdAgencyTask.SpotsInAgency, i)
			end
		end

		table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)
	end

	for k,requisition in pairs(self.SpotRequisitions) do
		local neededSpotCount = requisition.Count
		local guessedAudience = requisition.GuessedAudience

		debugMsg(" AdAgencyTick - requisition:  neededSpots="..neededSpotCount .."  guessedAudience="..math.floor(guessedAudience.GetTotalSum()))
		local signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.9))
		if (signedContracts == 0) then
			signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.7))
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


function SignRequisitedContracts:SignMatchingContracts(requisition, guessedAudience, minGuessedAudience)
	local signed = 0
	local boughtContracts = {}
	local neededSpotCount = requisition.Count

	if (neededSpotCount <= 0) then
		errorMsg("AI ERROR: SignMatchingContracts() with requisition.Count=0.", true)
		return 0
	end


	local availableList = self.AdAgencyTask.SpotsInAgency
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
		if requisition.level == 5 then
			maxSurplusSpots = math.max( maxSurplusSpots, math.random(0,1))
		elseif requisition.level == 4 then
			maxSurplusSpots = math.max( maxSurplusSpots, math.random(1,2))
		else
			maxSurplusSpots = math.max( maxSurplusSpots, math.random(2,3))
		end
		-- max add the amount of the base requisition
		maxSurplusSpots = math.min(maxSurplusSpots, requisition.Count)


		-- skip if contract requires too many spots for the given level
		if adContract.GetSpotCount() > neededSpotCount + maxSurplusSpots then
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
		table.removeCollection(self.AdAgencyTask.SpotsInAgency, boughtContracts)
	end

	return signed
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SignContracts"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.CurrentSpotIndex = 0
	c.AdAgencyTask = nil
end)


function SignContracts:typename()
	return "SignContracts"
end


--self.SpotRequisition = self.Player:GetRequisitionsByOwner(_G["TASK_SCHEDULE"])
function SignContracts:Prepare(pParams)
	--debugMsg("Sign lucrative ad contracts")
	self.CurrentSpotIndex = 0
end


-- sign "good contracts"
-- so contracts next to required ones
function SignContracts:Tick()
	if (self.AdAgencyTask.SpotsInAgency == nil) then return 0 end

	-- only sign contracts if we haven't enough unsent ad-spots
	local openSpots = self:GetUnsentSpotCount()
	local contractsAllowed = TVT.Rules.adContractsPerPlayerMax - MY.GetProgrammeCollection().GetAdContractCount()


	-- check if we have a low end contract
	if contractsAllowed > 0 then
		local signedContracts = TaskAdAgency.GetAllAdContracts()
		local lowAudience = 0.02 * MY.GetMaxAudience()
		local haveLow = false
		for key, contract in pairs(signedContracts) do
			if contract.GetMinAudience(TVT.ME) < lowAudience then
				haveLow = true
				break
			end
		end
	end

	-- sign an emergency contract to at least have something to broadcast
	-- as infomercial if we do not have enough programme licences (or
	-- money to buy some)	-- try to find a contract with not too much spots / requirements
	if (not haveLow or openSpots < 4) and contractsAllowed > 0 then
		local availableList = table.copy(self.AdAgencyTask.SpotsInAgency)
		availableList = TaskAdAgency.SortAdContractsByAttraction(availableList)

		local filteredList = FilterAdContractsByMinAudience(availableList, nil, 0.02 * MY.GetMaxAudience(), forbiddenIDs)
		if table.count(filteredList) > 0 then
			local contract = table.first(filteredList)

			local result = TVT.sa_doBuySpot(contract.GetID())
			if result == TVT.RESULT_OK then
				openSpots = openSpots - contract.GetSpotCount()
				contractsAllowed = contractsAllowed - 1

				debugMsg("Signed an \"low audience\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME))
			else
				debugMsg("FAILED signing an \"low audience\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME) .. ". Failure code: " .. result)
			end


			-- loop over all contracts and remove the ones no longer available
			for i=#self.AdAgencyTask.SpotsInAgency,1,-1 do
				if self.AdAgencyTask.SpotsInAgency[i] == nil then
					table.remove(self.AdAgencyTask.SpotsInAgency, i)
				end
			end
		end
	end



	if openSpots < 8 and contractsAllowed > 0 then
		-- do not be too risky and avoid a non achieveable audience requirement
		local filteredList = FilterAdContractsByMinAudience(self.AdAgencyTask.SpotsInAgency, nil, 0.15 * MY.GetMaxAudience(), forbiddenIDs)
		-- sort it
		filteredList = TaskAdAgency.SortAdContractsByAttraction(filteredList)

		--iterate over the available contracts
		for key, contract in pairs(filteredList) do
			-- skip contracts requiring too much

			local result = TVT.sa_doBuySpot(contract.GetID())
			if result == TVT.RESULT_OK then
				openSpots = openSpots - contract.GetSpotCount()
				contractsAllowed = contractsAllowed - 1

				debugMsg("Signed a \"good\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME))

				if openSpots <= 0 or contractsAllowed <= 0 then break end
			else
				debugMsg("FAILED signing a \"good\" contract: " .. contract.GetTitle() .. " (" .. contract.GetID() .. "). MinAudience: " .. contract.GetMinAudience(TVT.ME) .. ". Failure code: " .. result)
			end
		end
	end

	-- loop over all contracts and remove the ones no longer available
	for i=#self.AdAgencyTask.SpotsInAgency,1,-1 do
		if self.AdAgencyTask.SpotsInAgency[i] == nil then
			table.remove(self.AdAgencyTask.SpotsInAgency, i)
		end
	end

	self.Status = JOB_STATUS_DONE
end


--returns amount of unsent adcontract-spots
function SignContracts:GetUnsentSpotCount()
	local unsentSpots = 0

	for i = 0, MY.GetProgrammeCollection().GetAdContractCount() - 1 do
		local contract = MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if (contract.IsCompleted() ~= 1) then
			unsentSpots = unsentSpots + contract.GetSpotsToSend()
		end
	end

	return unsentSpots
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<