-- File: CommonObjects
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper

function CheckMovieBuyConditions(licence, maxPrice, maxPricePerBlock, minQuality)
	local price = licence.GetPrice(TVT.ME)
	if maxPrice ~= nil and (price > maxPrice) then return false; end
	if maxPricePerBlock~=nil and maxPricePerBlock > 0 and price / licence.GetBlocksTotal(2) > maxPricePerBlock then return false; end
	if (minQuality ~= nil) and (licence.GetQuality() < minQuality) then return false; end
	return true
end


function GetDefaultProgrammeQualityByHour(hour)
	if hour == 0 then
		return 0.09
	elseif hour == 1 then
		return 0.08
	elseif hour >= 2 and hour <= 5 then
		return 0.04
	elseif hour >= 6 and hour <= 8 then
		return 0.09
	elseif hour >= 9 and hour <= 11 then
		return 0.10
	elseif hour >= 12 and hour <= 14 then
		return 0.12
	elseif hour >= 14 and hour <= 16 then
		return 0.13
	elseif hour >= 17 and hour <= 19 then
		return 0.18
	elseif hour >= 20 and hour <= 22 then
		return 0.23
	elseif hour >= 23 then
		return 0.18
	end
	return 0.00
end


function FilterAdContractsByMinAudience(contractList, minAudienceMin, minAudienceMax, forbiddenIDs)
	local filteredList = {}

	if contractList ~= nil then
		if type(minAudienceMin) == "number" or minAudienceMin == nil then
			minAudienceMin = TVT.audiencePredictor.GetAudienceWithPopulation(tonumber(minAudienceMin))
		end
		if type(minAudienceMax) == "number" or minAudienceMax == nil then
			minAudienceMax = TVT.audiencePredictor.GetAudienceWithPopulation(tonumber(minAudienceMax))
		end
		local minAudienceMinSum = minAudienceMin.GetTotalSum()
		local minAudienceMaxSum = minAudienceMax.GetTotalSum()

--debugMsg("FilterAdContractsByMinAudience(list, " .. minAudienceMinSum .. " - " .. minAudienceMaxSum)
		for k,v in pairs(contractList) do
			local addIt = true

			local contractMinAudience = v.GetMinAudience(TVT.ME)
			local reqMinAudience = minAudienceMinSum
			local reqMaxAudience = minAudienceMaxSum
			-- adjust guessed audience if only specific target groups count
			if (v.GetLimitedToTargetGroup() > 0) then
				reqMinAudience = minAudienceMin.GetTotalValue( v.GetLimitedToTargetGroup())
				reqMaxAudience = minAudienceMax.GetTotalValue( v.GetLimitedToTargetGroup())
			end

			if addIt and contractMinAudience < reqMinAudience then addIt = false end
			--always add spots that could/should be finished
			if not addIt and v.GetDaysLeft(-1) == 0 and v.GetSpotsToSend() == 1 then addIt = true end
			if addIt and contractMinAudience > reqMaxAudience then addIt = false end

			if addIt and table.contains(forbiddenIDs, v.GetID()) then addIt = false end

			if addIt then table.insert(filteredList, v)	end
		end
	end
	return filteredList
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SpotRequisition"] = class(Requisition, function(c)
	Requisition.init(c)	-- must init base!
	c.TaskId = _G["TASK_ADAGENCY"]
	c.TaskOwnerId = nil
	c.Priority = 5
	c.Count = 0
	c.GuessedAudience = nil
	c.FulfilledCount = 0
	c.Level = -1
	c.SlotReqs = nil
end)

function SpotRequisition:typename()
	return "SpotRequisition"
end

function SpotRequisition:CheckActuality()
	if (self.Done) then return false end

	local removeList = {}
	for k,v in pairs(self.SlotReqs) do
		if (v:CheckActuality() == false) or v.level ~= self.Level then
			table.insert(removeList, v)
		end
	end

	for k,v in pairs(removeList) do
		table.removeElement(self.SlotReqs, v)
		self.Count = self.Count - 1
	end

	if (self.Count > 0) then
		return true
	else
		self:Complete()
		return false
	end
end

function SpotRequisition:Complete()
	self.Done = true
	local player = _G["globalPlayer"]
	player:RemoveRequisition(self)
end


function SpotRequisition:RemoveSlotRequisitionByTime(day, hour)
	local removeList = {}
	local oldCount = self.Count

	for k,v in pairs(self.SlotReqs) do
		if v.Day == day and v.Hour == hour then
			table.insert(removeList, v)
		end
	end

	for k,v in pairs(removeList) do
		table.removeElement(self.SlotReqs, v)
		self.Count = self.Count - 1
		--reduce priority but stay at least at 3 (see default initialization)
		self.Priority = math.max(3, self.Priority - 1)
	end

	return oldCount - self.Count
end


function SpotRequisition:UseThisContract(contract)
	--debugMsg("SpotRequisition:UseThisContract - Start")
	--Als Folge der erfüllten Anforderung, werden nun Anforderungen an den Programmplan gestellt
	local conCount = contract.GetSpotCount()

	local player = _G["globalPlayer"]
	for k,v in pairs(self.SlotReqs) do
		if (self.FulfilledCount >= self.Count) then --Es werden keine weiteren SpotSlots benötigt um die Anforderung zu erfüllen
		--	debugMsg("SpotRequisition:UseThisContract - Complete")
			self:Complete()
			return
		end

		v.TaskId = _G["TASK_SCHEDULE"]
		v.TaskOwnerId = _G["TASK_ADAGENCY"]
		--debugMsg("SpotRequisition:UseThisContract - id: " .. contract:GetID() .. " --- " .. v.Day .. "/" .. v.Hour .. " # " .. v.TaskId)
		v.ContractId = contract:GetID()
		player:AddRequisition(v)
		self.FulfilledCount = self.FulfilledCount + 1
	end
	--debugMsg("SpotRequisition:UseThisContract - End")
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SpotSlotRequisition"] = class(Requisition, function(c)
	Requisition.init(c)	-- must init base!
	c.TaskId = nil
	c.requisitionID = c.typename()
	c.Priority = 3
	c.Day = -1
	c.Hour = -1
	-- the ad contract which should be placed at the given time
	c.ContractId = -1
	-- the programme/infomercial broadcasted at that time
	c.broadcastMaterialGUID = ""
	-- the audience estimated at that time
	c.guessedAudience = nil
	-- the audience level estimated at that time
	c.level = -1
end)


function SpotSlotRequisition:typename()
	return "SpotSlotRequisition"
end


function SpotSlotRequisition:CheckActuality()
	if (self.Done) then return false end
	-- a requisition gets invalid as soon as the corresponding broadcast-
	-- material changed (eg. licence vanished somehow)
	--TODO this code needs to refactored; requisitions are modified while scheduling; they are not really bound to a single programme slot
	--after lua engine refactoring, all requisitions were cancelled by this snippet
	--	if self.broadcastMaterialGUID ~= nil and self.broadcastMaterialGUID ~= "" then
	--		if TVT.IsBroadcastMaterialInProgrammePlan(self.broadcastMaterialGUID, self.Day, self.Hour) == 0 then
	--			self:Complete()
	--			return false
	--		end
	--	end

	-- spot slot requisitions get outdated 2 hours after their "planned" time
	if (self.Day >= TVT.GetDay() or ( self.Day == TVT.GetDay() and self.Hour + 2 > TVT.GetDayHour())) then
		return true
	else
		self:Complete()
		return false
	end
end


function SpotSlotRequisition:Complete()
	self.Done = true
	local player = _G["globalPlayer"]
	player:RemoveRequisition(self)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BuyProgrammeLicencesRequisition"] = class(Requisition, function(c)
	Requisition.init(c)	-- must init base!
	c.TaskId = nil
	c.TaskOwnerId = nil
	c.requisitionID = c.typename()
	c.Priority = 5
	-- amount of licence requisitions
	c.Count = 0
	-- individual licence requisitions
	c.licenceReqs = nil
end)

function BuyProgrammeLicencesRequisition:typename()
	return "BuyProgrammeLicencesRequisition"
end


function BuyProgrammeLicencesRequisition:AddLicenceReq(req)
	if req == nil then return; end

	if self.licenceReqs == nil then self.licenceReqs = {}; end
	table.insert(self.licenceReqs, req)

	self.Count = table.count(self.licenceReqs)
end


function BuyProgrammeLicencesRequisition:CheckActuality()
	if (self.Done) then return false; end
	if self.licenceReqs == nil then return false; end

	local removeList = {}
	for k,v in pairs(self.licenceReqs) do
		if (v:CheckActuality() == false) then
			table.insert(removeList, v)
		end
	end

	local oldCount = table.count(self.licenceReqs)
	for k,v in pairs(removeList) do
		table.removeElement(self.licenceReqs, v)
	end
	self.Count = table.count(self.licenceReqs)
	if oldCount == self.Count and table.count(removeList) > 0 then
		logWithLevel(LOG_ERROR, LOG_ERROR, "!!!! FAILED to remove from self.licenceReqs")
	end

	if (self.Count > 0) then
		return true
	else
		self:Complete()
		return false
	end
end

function BuyProgrammeLicencesRequisition:Complete()
	self.Done = true
	local player = _G["globalPlayer"]
	player:RemoveRequisition(self)
end


-- remove all requisitions for a given reason (eg. "STARTPROGRAMME")
function BuyProgrammeLicencesRequisition:RemoveLicenceRequisitionByReason(reason)
	local removeList = {}
	local oldCount = self.Count

	for k,v in pairs(self.licenceReqs) do
		if v.reason == reason then
			table.insert(removeList, v)
		end
	end

	for k,v in pairs(removeList) do
		table.removeElement(self.licenceReqs, v)
		self.Count = self.Count - 1
		--reduce priority but stay at least at 5 (see default initialization)
		self.Priority = math.max(5, self.Priority - 1)
	end

	return oldCount - self.Count
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BuySingleProgrammeLicenceRequisition"] = class(Requisition, function(c)
	Requisition.init(c)	-- must init base!
	c.requisitionID = c.typename()
	c.Priority = 3
	c.categories = nil
	c.minPrice = 0
	c.maxPrice = -1
	c.minQuality = 0
	c.maxQuality = -1
	c.lifeTime = -1
end)


function BuySingleProgrammeLicenceRequisition:typename()
	return "BuySingleProgrammeLicenceRequisition"
end


function BuySingleProgrammeLicenceRequisition:CheckActuality()
	if (self.Done) then return false end
	-- requisitions get outdated after their lifetime ends
	if (self.lifeTime < 0 or self.lifeTime >= tonumber(TVT.GetTimeGoneInSeconds())) then
		return true
	else
		self:Complete()
		return false
	end
end


function BuySingleProgrammeLicenceRequisition:Complete()
	self.Done = true
	local player = _G["globalPlayer"]
	player:RemoveRequisition(self)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIToolsClass"] = class(KIObjekt)

function AIToolsClass:typename()
	return "AIToolsClass"
end


--TODO später dynamisieren
function AIToolsClass:GetAverageBroadcastQualityByLevel(level)
	if (level == 1) then
		return 0.04 --Nachtprogramm
	elseif (level == 2) then
		return 0.09 --Mitternacht + Morgen
	elseif (level == 3) then
		return 0.13 -- Nachmittag
	elseif (level == 4) then
		return 0.18 -- Vorabend / Spät
	elseif (level == 5) then
		return 0.23 -- Primetime
	end
	return 0.00
end

--currently hard coded by hour (see old implementation below
--in the long run a statistic by weekday+hour for reachable audience percentage would be nice
function AIToolsClass:GetAudienceQualityLevel(day, hour)
	if hour > 22 or hour <=1 then
		return 4
	elseif hour >=19 then
		return 5
	elseif hour >=15 then
		return 4
	elseif hour >= 10 then
		return 3
	elseif hour >= 6 then
		return 2
	else
		return 1
	end
end

--prevent many uncached calls to BMX for determining audience level
--[[
--TODO Problem der Überlappung der MinAudience bei Level 4 und 5 (z.T. gleiche Anforderungen - doppelte Verträge)
function AIToolsClass:GetAudienceQualityLevel(day, hour)
	local maxAudience = self:GetMaxAudiencePercentage(day, hour)
	if (maxAudience <= 0.04) then
		return 1 --Nachtprogramm (2-6)
	elseif (maxAudience <= 0.12) then
		return 2 --Mitternacht + Morgen
	elseif (maxAudience <= 0.20) then
		return 3 -- Nachmittag
	elseif (maxAudience <= 0.33) then
		return 4 -- Vorabend / Spät
	else
		return 5 -- Primetime
	end
end


function AIToolsClass:GetMaxAudiencePercentage(day, hour)
	--debugMsg("AITools:GetMaxAudiencePercentage("..day ..", "..hour..") = " .. TVT.getPotentialAudiencePercentage(day,hour))
	return TVT.getPotentialAudiencePercentage(day, hour)
end
--]]

--TODO this cannot be done without context (all existing licences)
function AIToolsClass:GetBroadcastQualityLevel(broadcastMaterial, count)
	if broadcastMaterial == nil then return 0 end
	--TODO raw-QualityLevel!! also consider number of licences und average quality!!
	local quality = broadcastMaterial:GetQuality() * 100
	if count > 144 then
		if quality > 60 then
			return 5
		elseif quality > 50 then
			return 4
		elseif quality > 35 then
			return 3
		elseif quality > 25 then
			return 2
--		elseif quality > 15 then
--			return 1
		else
			return 0
		end
	elseif count > 96 then
		if quality > 50 then
			return 5
		elseif quality > 35 then
			return 4
		elseif quality > 20 then
			return 3
		elseif quality > 15 then
			return 2
		elseif quality > 10 then
			return 1
		else
			return 0
		end
	elseif count > 48 then
		if quality > 35 then
			return 5
		elseif quality > 22 then
			return 4
		elseif quality > 15 then
			return 3
		elseif quality > 10 then
			return 2
		else
			return 1
		end
	else
		if quality > 20 then
			return 5
		elseif quality > 15 then
			return 4
		elseif quality > 10 then
			return 3
		elseif quality > 5 then
			return 2
		else
			return 1
		end
	end
end


function AIToolsClass:GetBroadcastAttraction(broadcastMaterialSource, day, hour, forPlayer)
	if broadcastMaterialSource == nil then return 0 end

	if forPlayer == nil then forPlayer = _G["globalPlayer"] end

	-- how much does time affect the attraction (horror/infomercials at night)
	local timeMod = 1.0
	-- how much does the audience like a genre/flag
	local audienceMod = 1.0
	-- how much likes the player to send this kind of programme/infomercial
	local playerMod = 1.0


	-- infomercials?
	if broadcastMaterialSource.IsAdContract() == 1 then
		audienceMod = 0.55
		--infomercials are more appreciated during night and morning
		--and less during afternoon/primetime
		if hour ~= nil then
			if hour >= 0 and hour <= 7 then timeMod = 1.07 end
			if hour >=10 and hour <=12 then timeMod = 1.05 end
			if hour >=13 and hour <=16 then timeMod = 0.95 end
			if hour >=17 and hour <=23 then timeMod = 0.85 end
		end

		--[[
		-- higher during early hours
		if level <= 2 then choosenInfomercialValue = choosenInfomercialValue * 1.2; end
		-- even more during night
		if level <= 1 then choosenInfomercialValue = choosenInfomercialValue * 1.2; end
		-- lower during evening
		if level >= 4 then choosenInfomercialValue = choosenInfomercialValue * 0.80; end
		-- even lower for prime time
		if level >= 5 then choosenInfomercialValue = choosenInfomercialValue * 0.80; end
		--]]

		-- modify attraction by a player-individual modifier.
		playerMod = forPlayer.Strategy.GetInfomercialWeight()

	-- paid programming?
	elseif broadcastMaterialSource.IsProgrammeLicence() == 1 and broadcastMaterialSource.HasDataFlag(TVT.Constants.ProgrammeDataFlag.PAID) == 1 then
		audienceMod = 0.75
		--infomercials are more appreciated during night and morning
		--and less during afternoon/primetime
		if hour ~= nil then
			if hour >= 0 and hour <=14 then timeMod = 1.10 end
			if hour >=20 and hour <=22 then timeMod = 0.90 end
		end
	end

	-- "GetQuality()" already contains topicality-influence for infomercials
	-- and programmes
	-- return playerMod * timeMod * audienceMod * (broadcastMaterialSource.GetQuality() * broadcastMaterialSource.GetProgrammeTopicality())
	local quality = broadcastMaterialSource.GetQuality()
	--for custom live productions quality data is not yet available...
	if broadcastMaterialSource:IsLive() then quality = math.max(quality, 0.3) end
	local result = playerMod * timeMod * audienceMod * quality

	--TODO Anzahl Lizenzen, Durchschnittsqualität, Genre (Sendezeit) berücksichtigen

	if broadcastMaterialSource.IsProgrammeLicence() == 1 then
		local relTop = broadcastMaterialSource:GetRelativeTopicality()
		if relTop == 1 then
			result = result * 1.5
		else
			result = result * relTop
			if (forPlayer.blocksCount > 56) or hour > 16 then
				result = result * relTop
			end
		end
		local timesShown = broadcastMaterialSource:GetTimesBroadcasted(forPlayer)
		if timesShown >= 7 then
			result=result * 0.3
		elseif timesShown >= 5 then
			result=result * 0.6
		elseif timesShown >= 3 then
			result=result * 0.8
		elseif timesShown == 0 then
			result=result * 1.3
			local minHour = 19
			if forPlayer.coverage > 0.4 then minHour = 16 end
			if hour < minHour or hour > 22 then
				--TODO make genre dependent; many blocks - new cheap stuff also earlier 
				if broadcastMaterialSource:GetTopicality() > 0.6 then
					result= result * 0.3
				end
			end 
		end
--		if hour > 18 and broadcastMaterialSource:GetGenre() == TVT.Constants.ProgrammeGenre.Animation then
--			result = result * 0.5
--		end
		if TVT.Constants.AwardType.CULTURE == forPlayer.currentAwardType then
			if broadcastMaterialSource.data:IsCulture() > 0 then
				result = result * 3
			end
		end
	end
	return result
end

function AIToolsClass:GetNumberOfSlots(player, contract, minAudience)
	local achieved = -1
	local goodFit = -1
	if player.Stats ~= nil and player.Stats.BroadcastStatistics~=nil then
		local st = player.Stats.BroadcastStatistics.hourlyProgrammeAudience
		if st ~=nil then
			achieved = 0
			goodFit = 0
			local threshold = tonumber(tostring(TVT.GetDay()-1).."00")
			local tg=0
			local sum =0
			for k,v in pairs(st) do
				if tonumber(k) < threshold then
					local aud = v.Audience
					tg=contract.GetLimitedToTargetGroup()
					sum = aud.GetTotalValue(tg)

					if sum > minAudience then
						achieved = achieved + 1
						if sum * 0.5 < minAudience then
							goodFit = goodFit + 1
						end
					end
				end
			end
		end
	end
	return achieved, goodFit
end

--[[
function AIToolsClass:GetMaxAudiencePercentageByLevel(level)
	if level == 1 then
		return 0.0347
	elseif level == 2 then
		return 0.0666
	elseif level == 3 then
		return 0.1161
	elseif level == 4 then
		return 0.2088
	elseif level == 5 then
		return 0.3459
	end
	return 0.00
end
]]--
AITools = AIToolsClass()
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<