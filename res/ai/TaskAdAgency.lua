-- File: TaskAdAgency
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskAdAgency"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_ADAGENCY;
	c.SpotsInAgency = nil;
	c.BasePriority = 8;
	c.BudgetWeigth = 0
	-- zu Senden
	-- Strafe
	-- Zuschauer
	-- Zeit
end)

function TaskAdAgency:typename()
	return "TaskAdAgency"
end

function TaskAdAgency:Activate()
	debugMsg(">>> Starte Task 'TaskAdAgency'")
	-- Was getan werden soll:
	self.CheckSpots = JobCheckSpots()
	self.CheckSpots.AdAgencyTask = self

	self.AppraiseSpots = AppraiseSpots()
	self.AppraiseSpots.AdAgencyTask = self

	self.SignRequisitedContracts = SignRequisitedContracts()
	self.SignRequisitedContracts.AdAgencyTask = self

	self.SignContracts = SignContracts()
	self.SignContracts.AdAgencyTask = self

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
	end

	self:SetWait()
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
	debugMsg("Schaue Werbeangebote an")
	self.CurrentSpotIndex = 0
end

function JobCheckSpots:Tick()
	while self.Status ~= JOB_STATUS_DONE do
		self:CheckSpot()
	end
end

function JobCheckSpots:CheckSpot()
	local response = TVT.sa_getSpot(self.CurrentSpotIndex)
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		self.Status = JOB_STATUS_DONE
		return
	end

	local spot = TVT.convertToAdContract(response.data)
	if (spot.IsAvailableToSign(TVT.ME) == 1) then
		--debugMsg("Signable")
		local player = _G["globalPlayer"]
		self.AdAgencyTask.SpotsInAgency[self.CurrentSpotIndex] = spot
		player.Stats:AddSpot(spot)
	end

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
	debugMsg("Bewerte/Vergleiche Werbeverträge")
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
	--return nil --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	--debugMsg("AppraiseSpot")
	--debugMsg("===================")
	local player = _G["globalPlayer"]
	local stats = player.Stats
	local score = -1

	if (spot.GetMinAudience() > stats.Audience.MaxValue) then
		--spot.Appraisal = -2
		--debugMsg("zu viele Zuschauer verlangt! " .. spot.Audience .. " / " .. stats.Audience.MaxValue)
		return
	end

	--debugMsg("spot.SpotProfit: " .. spot.SpotProfit .. " ; spot.SpotToSend: " .. spot.SpotToSend)
	local profitPerSpot = spot.GetProfit() / spot.GetSpotCount()
	--debugMsg("profitPerSpot: " .. profitPerSpot .. " ; stats.SpotProfitPerSpotAcceptable.AverageValue: " .. stats.SpotProfitPerSpotAcceptable.AverageValue)
	local financePower = profitPerSpot / stats.SpotProfitPerSpotAcceptable.AverageValue
	--debugMsg("financePower1: " .. financePower)
	financePower = CutFactor(financePower, 0.2, 2)
	--debugMsg("financePower: " .. financePower)

	-- 2 = Locker zu schaffen / 0.3 schwierig zu schaffen
	local audienceFactor = stats.Audience.AverageValue / spot.GetMinAudience()
	audienceFactor = CutFactor(audienceFactor, 0.3, 2)
	--debugMsg("audienceFactor: " .. audienceFactor .. " ; stats.Audience.AverageValue: " .. stats.Audience.AverageValue .. " ; spot.Audience:" .. spot.Audience)

	-- 2 = Risiko und Strafe sind im Verhältnis gering  / 0.3 = Risiko und Strafe sind Verhältnis hoch
	local riskFactor = stats.SpotPenalty.AverageValue / spot.GetPenalty()
	riskFactor = CutFactor(riskFactor, 0.3, 2)
	riskFactor = riskFactor * audienceFactor
	riskFactor = CutFactor(riskFactor, 0.2, 2)
	--debugMsg("riskFactor: " .. riskFactor .. " ; SpotPenalty: " .. stats.SpotPenalty.AverageValue .. " ; SpotPenalty:" .. spot.SpotPenalty)

	-- 2 leicht zu packen / 0.3 hoher Druck
	local pressureFactor = spot.GetDaysToFinish() / spot.GetSpotCount()
	pressureFactor = CutFactor(pressureFactor, 0.2, 2)
	--debugMsg("pressureFactor: " .. pressureFactor .. " ; SpotMaxDays: " .. spot.SpotMaxDays .. " ; SpotToSend:" .. spot.SpotToSend)

	spot.SetAttractiveness(audienceFactor * riskFactor * pressureFactor)
	--debugMsg("Spot-Attractiveness: ===== " .. spot.GetAttractiveness() .. " ===== ; financePower: " .. financePower .. " ; audienceFactor: " .. audienceFactor .. " ; riskFactor: " .. riskFactor .. " ; pressureFactor: " .. pressureFactor)

	--debugMsg("===================")

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
	debugMsg("Unterschreibe benötigte Werbeverträge")
	self.CurrentSpotIndex = 0

	self.Player = _G["globalPlayer"]
	self.SpotRequisitions = self.Player:GetRequisitionsByTaskId(_G["TASK_ADAGENCY"])
end

function SignRequisitedContracts:Tick()
	--debugMsg("SignRequisitedContracts")

	--Sortieren
	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end
	--RONNY: Achtung, es muss ueberprueft werden, ob die Liste NULL-
	--       Eintraege enthaelt (evtl "verschwunden", oder durch einen
	--       "Refill"-Aufruf nicht mehr beim Makler zu haben.)
	--       Dach kann sortiert werden, ohne "Null-Zugriffe" innerhalb
	--       der Sortiermethode.
	for i=#self.AdAgencyTask.SpotsInAgency,1,-1 do
		if self.AdAgencyTask.SpotsInAgency[i] == nil then
			--TVT.PrintOut("======== ENTFERNE UNGUELTIGEN WERBEVERTRAG ========")
			table.remove(self.AdAgencyTask.SpotsInAgency, i)
		end
	end
	
	table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)

	for k,requisition in pairs(self.SpotRequisitions) do
		local neededSpotCount = requisition.Count

		local guessedAudience = AITools:GuessedAudienceForLevel(requisition.Level)
		local minGuessedAudience = (guessedAudience * 0.8)

		local signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.8))
		if (signedContracts == 0) then
			signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))
			if (signedContracts == 0) then
				guessedAudience = guessedAudience + 5000 -- Die 5000 sind einfach ein Erfahrungswert, denn es gibt kaum kleinere Werbeverträge... die Sinnhaftigkeit sollte nochmal geprüft werden
				signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))
				if (signedContracts == 0) then
					guessedAudience = guessedAudience + 5000 -- Die 5000 sind einfach ein Erfahrungswert, denn es gibt kaum kleinere Werbeverträge... die Sinnhaftigkeit sollte nochmal geprüft werden
					signedContracts = self:SignMatchingContracts(requisition, guessedAudience, self:GetMinGuessedAudience(guessedAudience, 0.6))
				end
			end
		end
	end

	self.Status = JOB_STATUS_DONE
end

function SignRequisitedContracts:GetMinGuessedAudience(guessedAudience, minFactor)
	if (guessedAudience < 10000) then
		return 0
	else
		return (guessedAudience * minFactor)
	end
end

function SignRequisitedContracts:SignMatchingContracts(requisition, guessedAudience, minguessedAudience)
	local signed = 0
	local buyedContracts = {}

	for key, value in pairs(self.AdAgencyTask.SpotsInAgency) do
		if MY.GetProgrammeCollection().GetAdContractCount() >= 8 then break end

		local minAudience = value.GetMinAudience()

		if ((minAudience < guessedAudience) and (minAudience > minguessedAudience)) then
			--Passender Spot... also kaufen
			debugMsg("Schließe Werbevertrag: " .. value.GetTitle() .. " (" .. value.GetID() .. ") weil benötigt. Level: " .. requisition.Level)
			TVT.addToLog("Schließe Werbevertrag: " .. value.GetTitle() .. " (" .. value.GetID() .. ") weil benötigt. Level: " .. requisition.Level)
			TVT.sa_doBuySpot(value.GetID())
			requisition:UseThisContract(value)
			table.insert(buyedContracts, value)
			signed = signed + 1
			--neededSpotCount = neededSpotCount - value.GetSpotCount()
		end

		--if (neededSpotCount <= 0) then
		--	self.Player:RemoveRequisition(requisition)
		--else
		--	requisition.Count = neededSpotCount
		--end
	end

	if (table.count(buyedContracts) > 0) then
		debugMsg("Entferne " .. table.count(buyedContracts) .. " abgeschlossene Werbeverträge aus der Shop-Liste.")
		table.removeCollection(self.AdAgencyTask.SpotsInAgency, buyedContracts)
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
	debugMsg("Unterschreibe lukrative Werbeverträge")
	self.CurrentSpotIndex = 0
end

function SignContracts:Tick()
	--debugMsg("SignContracts")

	--Sortieren
	local sortMethod = function(a, b)
		return a.GetAttractiveness() > b.GetAttractiveness()
	end
	table.sort(self.AdAgencyTask.SpotsInAgency, sortMethod)

	local openSpots = self:GetCommonRequisition()
	--debugMsg("openSpots: " .. openSpots)

	-- only sign contracts if we haven't enough unsent ad-spots

	--Ronny: umgestellt und "Notwendigkeitsfilter" von GetCommonRequisition hier eingebunden
	--if (openSpots > 0) then
	if (openSpots < 8) then
		for key, value in pairs(self.AdAgencyTask.SpotsInAgency) do
			if MY.GetProgrammeCollection().GetAdContractCount() >= TVT.Rules.maxContracts then break end
			if (openSpots > 0) then
				openSpots = openSpots - value.GetSpotCount()
				debugMsg("Schließe Werbevertrag: " .. value.GetTitle() .. " (" .. value.GetID() .. ")")
				TVT.sa_doBuySpot(value.GetID())
			end
		end
	end

	self.Status = JOB_STATUS_DONE
end

--returns amount of unsent adcontract-spots
function SignContracts:GetCommonRequisition()
	local unsentSpots = 0

	for i = 0, MY.GetProgrammeCollection().GetAdContractCount() - 1 do
		local contract = MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if (contract.isSuccessful() ~= 1) then
			unsentSpots = unsentSpots + contract.GetSpotsToSend()
		end
	end
	--debugMsg("unsentSpots: " .. unsentSpots)
--RONNY:	Das ergibt wenig Sinn fuer mich, bei "weniger als 8" offenen
--			Werbeaustrahlungen limitiert man die notwendigen Spots?
--			Falls es so gemeint ist: Wenn ich mehr als 8 Spots habe, brauche
--			ich keine neuen holen - dann sollte dies bei der entsprechenden
--			Funktion gefiltert werden, nicht bei einem "counter"
--	if (unsentSpots > 8) then
--		return 0
--	else
--		return 8 - unsentSpots
--	end
--DESWEGEN:
	return unsentSpots
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<