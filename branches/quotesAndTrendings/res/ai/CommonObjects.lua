-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper

function CheckMovieBuyConditions(movie, maxPrice, minQuality)
	if (movie.GetPrice() > maxPrice) then return false end	
	if (minQuality ~= nil) then
		if (movie.GetQuality(0) < minQuality) then return false end
	end
	return true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SpotRequisition = Requisition:new{
	TaskId = _G["TASK_ADAGENCY"];
	Priority = 5;
	Count = 0;
	FulfilledCount = 0;
	Level = -1;
	SlotReqs = nil
}

function SpotRequisition:typename()
	return "SpotRequisition"
end

function SpotRequisition:CheckActuality()
	if (self.Done) then return false end

	local removeList = {}
	for k,v in pairs(self.SlotReqs) do
		if (v:CheckActuality() == false) then
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
SpotSlotRequisition = Requisition:new{
	TaskId = nil;
	Priority = 3;
	Day = -1;
	Hour = -1;
	ContractId = -1;
}

function SpotSlotRequisition:typename()
	return "SpotSlotRequisition"
end

function SpotSlotRequisition:CheckActuality()
	if (self.Done) then return false end

	if (self.Day >= Game.GetDay() or ( self.Day == Game.GetDay() and self.Hour + 2 > Game.GetHour())) then
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
AIToolsClass = KIObjekt:new{
}

function AIToolsClass:typename()
	return "AITools"
end

function AIToolsClass:GetAverageMovieQualityByLevel(level)
	if (level == 1) then
		return 0.03 --Nachtprogramm
	elseif (level == 2) then
		return 0.08 --Mitternacht + Morgen
	elseif (level == 3) then
		return 0.13 -- Nachmittag
	elseif (level == 4) then
		return 0.18 -- Vorabend / Spät
	elseif (level == 5) then
		return 0.22 -- Primetime
	end
end

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
end

function AIToolsClass:GuessedAudienceForLevel(level)	
	--debugMsg("GuessedAudienceForLevel - level: " .. level)
	local globalPercentageByHour = self:GetMaxAudiencePercentageByLevel(level) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
	--debugMsg("globalPercentageByHour: " .. globalPercentageByHour)
	local averageMovieQualityByLevel = self:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels

	--Formel: Filmqualität * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	local guessedAudience = averageMovieQualityByLevel * globalPercentageByHour * MY.GetMaxAudience()	
	
	--debugMsg("GuessedAudienceForLevel: " .. guessedAudience .. " = averageMovieQualityByLevel (" .. averageMovieQualityByLevel .. ") * globalPercentageByHour (" .. globalPercentageByHour .. ") *  MY.GetMaxAudience() (" .. MY.GetMaxAudience() .. ")")
	
	return guessedAudience
end

AITools = AIToolsClass:new()
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<