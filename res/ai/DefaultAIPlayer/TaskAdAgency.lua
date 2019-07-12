-- File: TaskAdAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskAdAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_ADAGENCY"]
	c.TargetRoom = TVT.ROOM_ADAGENCY
	c.SpotsInAgency = nil;
	-- keep adagency task a bit lower priority: when adcontracts get
	-- requested by the schedule task, this already adds to end priority
	-- via "requisition priority"
	c.BasePriority = 3
	c.BudgetWeight = 0
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
	debugMsg("AppraiseSpot: " .. spot.GetTitle() )
	debugMsg("===================")
	local player = _G["globalPlayer"]
	local stats = player.Stats
	local score = -1

	-- for now we do not modify our stats if they are special spots
	if (spot.GetLimitedToTargetGroup() > 0) or (spot.GetLimitedToGenre() > 0) or (spot.GetLimitedToProgrammeFlag() > 0) then
		return
	end

	if (spot.GetMinAudience(TVT.ME) > stats.Audience.MaxValue) then
		--spot.Appraisal = -2
		debugMsg("  zu viele Zuschauer verlangt! " .. spot.GetMinAudience(TVT.ME) .. " / " .. stats.Audience.MaxValue)
		return
	end

	local profitPerSpot = spot.GetProfit(TVT.ME) / spot.GetSpotCount()
	local financePowerRaw = profitPerSpot / stats.SpotProfitPerSpotAcceptable.AverageValue
	local financePower = CutFactor(financePowerRaw, 0.2, 2)
	debugMsg("  profit=" .. spot.GetProfit(TVT.ME) .. " (".. profitPerSpot.."/spot)  SpotsToSend=" .. spot.GetSpotsToSend() .."  stats.SpotProfitPerSpotAcceptable(Avg)=" .. stats.SpotProfitPerSpotAcceptable.AverageValue)
	debugMsg("  financePower=" .. financePowerRaw .. "  financePower(cut)=" .. financePower)

	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen
	local audienceFactor = stats.Audience.AverageValue / spot.GetMinAudience(TVT.ME)
	audienceFactor = CutFactor(audienceFactor, 0.3, 2)
	debugMsg("  audienceFactor=" .. audienceFactor .. "  stats.Audience(Avg)=" .. stats.Audience.AverageValue .. "  spot.GetMinAudience()=" .. spot.GetMinAudience(TVT.ME))

	-- 2 = Risiko und Strafe sind im Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactor = stats.SpotPenalty.AverageValue / spot.GetPenalty(TVT.ME)
	riskFactor = CutFactor(riskFactor, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)
	debugMsg("  riskFactor=" .. riskFactor .. "  SpotPenalty(Avg)= " .. stats.SpotPenalty.AverageValue .. "  spot.GetPenalty()=" .. spot.GetPenalty(TVT.ME))

	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactor = spot.GetDaysToFinish() / spot.GetSpotCount()
	debugMsg("  pressureFactor=" .. pressureFactor .. "  pressureFactor(cut)=" .. CutFactor(pressureFactor, 0.2, 2) .. "  daysToFinish=" .. spot.GetDaysToFinish() .. "  spotsToSend=" .. spot.GetSpotsToSend())
	pressureFactor = CutFactor(pressureFactor, 0.2, 2)

	spot.SetAttractiveness(audienceFactor * riskFactor * pressureFactor)
	debugMsg("  spot-attractiveness=" .. spot.GetAttractiveness() .. "  (financePower=" .. financePower .. "  audienceFactor=" .. audienceFactor .. "  riskFactor=" .. riskFactor .. "  pressureFactor=" .. pressureFactor ..")")

	debugMsg("===================")

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
		--Sortieren
		local sortMethod = function(a, b)
			return a.GetAttractiveness() > b.GetAttractiveness()
		end
		--RONNY: Achtung, es muss ueberprueft werden, ob die Liste NULL-
		--       Eintraege enthaelt (evtl "verschwunden", oder durch einen
		--       "Refill"-Aufruf nicht mehr beim Makler zu haben.)
		--       Danach kann sortiert werden, ohne "Null-Zugriffe" innerhalb
		--       der Sortiermethode.
		for i=#self.AdAgencyTask.SpotsInAgency,1,-1 do
			if self.AdAgencyTask.SpotsInAgency[i] == nil then
				--TVT.PrintOut("======== ENTFERNE UNGUELTIGEN WERBEVERTRAG ========")
				table.remove(self.AdAgencyTask.SpotsInAgency, i)
			end
		end

		table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)
	end

	for k,requisition in pairs(self.SpotRequisitions) do
		-- old savegames? convert to new audience-object-approach
		if type(requisition.GuessedAudience) == "number" then
			requisition.GuessedAudience = TVT.audiencePredictor.GetEmptyAudience().InitWithBreakdown(requisition.GuessedAudience)
		end

		local neededSpotCount = requisition.Count
		local guessedAudience = requisition.GuessedAudience

		debugMsg(" AdAgencyTick - requisition: Spots="..neededSpotCount .."  Audience="..math.floor(guessedAudience.GetTotalSum()))
		local signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.8))
		if (signedContracts == 0) then
			signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))
			if (signedContracts == 0) then
				signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.5))
				if (signedContracts == 0) then
					signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.4))
				end
			end
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
		return guessedAudience.Copy().MultiplyFloat(minFactor)
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

	for key, adContract in pairs(self.AdAgencyTask.SpotsInAgency) do
		-- do not try to get more contracts than allowed
		if MY.GetProgrammeCollection().GetAdContractCount() >= TVT.Rules.adContractsPerPlayerMax then break end

		local contractDoable = true
		-- skip limited programme genres
		-- TODO: get breakdown of audience and compare this then
		if (adContract.GetLimitedToGenre() > 0 or adContract.GetLimitedToProgrammeFlag() > 0 ) then
			contractDoable = false
			debugMsg("contract NOT DOABLE: " .. adContract.GetTitle() .. "  targetgroup="..adContract.GetLimitedToTargetGroup() .."  genre="..adContract.GetLimitedToGenre() .. "  flags=" .. adContract.GetLimitedToProgrammeFlag())
		end

		if (contractDoable) then
			-- this value is already taking care of target group limits
			local minAudienceValue = adContract.GetMinAudience()
			local minGuessedAudienceValue = minGuessedAudience.GetTotalValue( adContract.GetLimitedToTargetGroup() )
			local guessedAudienceValue = guessedAudience.GetTotalValue( adContract.GetLimitedToTargetGroup() )


			-- the more we need, the more likely we could finish even more
			local maxSurplusSpots = math.floor(0.5 * requisition.Count)
			if requisition.level == 5 then
				maxSurplusSpots = math.max( maxSurplusSpots, math.random(0,1))
			elseif requisition.level == 4 then
				maxSurplusSpots = math.max( maxSurplusSpots, math.random(1,2))
			else
				maxSurplusSpots = math.max( maxSurplusSpots, math.random(2,3))
			end

			-- skip if contract requires too many spots for the given level
			if adContract.GetSpotCount() > requisition.Count + maxSurplusSpots then
				--debugMsg("   Skipping a \"necessary\" contract (too many spots: " .. adContract.GetSpotCount() .. " > ".. requisition.Count .." + "..maxSurplusSpots .. "): " .. adContract.GetTitle() .. " (" .. adContract.GetID() .. "). Level: " .. requisition.Level .. "  NeededSpots: " .. neededSpotCount.. "  MinAudience: " .. minAudienceValue .. "  GuessedAudience: " .. math.floor(minGuessedAudience.GetTotalSum()) .. " - " .. math.floor(guessedAudience.GetTotalSum()))
			-- sign if audience requirements are OK
			elseif ((minAudienceValue < guessedAudienceValue) and (minAudienceValue > minGuessedAudienceValue)) then
				--Passender Spot... also kaufen
				debugMsg("   Signing a \"necessary\" contract: " .. adContract.GetTitle() .. " (" .. adContract.GetID() .. "). Level: " .. requisition.Level .. "  NeededSpots: " .. neededSpotCount.. "  MinAudienceValue: " .. minAudienceValue .. "  GuessedAudience: " .. math.floor(minGuessedAudienceValue) .. " - " .. math.floor(guessedAudienceValue) .." (total="..math.floor(guessedAudience.GetTotalSum())..")")
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

	if openSpots < 8 and contractsAllowed > 0 then
		--sort by attractiveness
		local sortMethod = function(a, b)
			if a == nil then
				return false
			elseif b == nil then
				return true
			end
			return a.GetAttractiveness() > b.GetAttractiveness()
		end
		table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)


		--iterate over the available contracts
		for key, value in pairs(self.AdAgencyTask.SpotsInAgency) do
			if TVT.sa_doBuySpot(value.GetID()) == TVT.RESULT_OK then
				openSpots = openSpots - value.GetSpotCount()
				contractsAllowed = contractsAllowed - 1

				TVT.addToLog("Signed a \"good\" contract: " .. value.GetTitle() .. " (" .. value.GetID() .. "). MinAudience: " .. value.GetMinAudience())

				if openSpots <= 0 or contractsAllowed <= 0 then break end
			else
				TVT.addToLog("Failed signing a \"good\" contract: " .. value.GetTitle() .. " (" .. value.GetID() .. "). MinAudience: " .. value.GetMinAudience())
			end
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