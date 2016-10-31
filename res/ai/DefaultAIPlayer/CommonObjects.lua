-- File: CommonObjects
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper

function CheckMovieBuyConditions(licence, maxPrice, minQuality)
	if (licence.GetPrice() > maxPrice) then return false end
	if (minQuality ~= nil) then
		if (licence.GetQuality() < minQuality) then return false end
	end
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
	if self.broadcastMaterialGUID ~= nil and self.broadcastMaterialGUID ~= "" then
		if TVT.IsBroadcastMaterialInProgrammePlan(self.broadcastMaterialGUID, self.Day, self.Hour) == 0 then
			self:Complete()
			return false
		end
	end

	-- spot slot requisitions get outdated 2 hours after their "planned" time
	if (self.Day >= WorldTime.GetDay() or ( self.Day == WorldTime.GetDay() and self.Hour + 2 > WorldTime.GetDayHour())) then
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
		devMsg("!!!! FAILED to remove from self.licenceReqs")
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
	if (self.lifeTime < 0 or self.lifeTime >= WorldTime.GetTimeGone()) then
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

function AIToolsClass:GetAverageBroadcastQualityByLevel(level)
	if (level == 1) then
		return 0.08 --Nachtprogramm
	elseif (level == 2) then
		return 0.12 --Mitternacht + Morgen
	elseif (level == 3) then
		return 0.15 -- Nachmittag
	elseif (level == 4) then
		return 0.20 -- Vorabend / Spät
	elseif (level == 5) then
		return 0.26 -- Primetime
	end
	return 0.00
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

function AIToolsClass:GuessedAudienceForLevel(level)
	--debugMsg("GuessedAudienceForLevel - level: " .. level)
	local globalPercentageByHour = self:GetMaxAudiencePercentageByLevel(level) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
	--debugMsg("globalPercentageByHour: " .. globalPercentageByHour)
	local averageBroadcastQualityByLevel = self:GetAverageBroadcastQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels

	--Formel: Filmqualität * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	local guessedAudience = averageBroadcastQualityByLevel * globalPercentageByHour * MY.GetMaxAudience()

	--debugMsg("GuessedAudienceForLevel: " .. guessedAudience .. " = averageBroadcastQualityByLevel (" .. averageBroadcastQualityByLevel .. ") * globalPercentageByHour (" .. globalPercentageByHour .. ") *  MY.GetMaxAudience() (" .. MY.GetMaxAudience() .. ")")

	return guessedAudience
end
]]--
AITools = AIToolsClass()
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<