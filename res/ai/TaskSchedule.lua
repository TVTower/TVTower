-- File: TaskSchedule
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskSchedule"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME
	c.BudgetWeigth = 0
	c.BasePriority = 10
	c.TodayMovieSchedule = {}
	c.TomorrowMovieSchedule = {}
	c.TodaySpotSchedule = {}
	c.TomorrowSpotSchedule = {}
	c.SpotInventory = {}
	c.SpotRequisition = {}
	c.Player = nil
end)


function TaskSchedule:typename()
	return "TaskSchedule"
end


function TaskSchedule:Activate()
	-- Was getan werden soll:
	self.AnalyzeScheduleJob = JobAnalyzeSchedule()
	self.AnalyzeScheduleJob.ScheduleTask = self

	self.FulfillRequisitionJob = JobFulfillRequisition()
	self.FulfillRequisitionJob.ScheduleTask = self

	self.EmergencyScheduleJob = JobEmergencySchedule()
	self.EmergencyScheduleJob.ScheduleTask = self

	self.ScheduleJob = JobSchedule()
	self.ScheduleJob.ScheduleTask = self

	self.Player = _G["globalPlayer"]
	self.SpotRequisition = self.Player:GetRequisitionsByOwner(_G["TASK_SCHEDULE"])
end


function TaskSchedule:GetNextJobInTargetRoom()
	--debugMsg("GetNextJobInTargetRoomX")
	if (self.AnalyzeScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyzeScheduleJob
	elseif (self.FulfillRequisitionJob.Status ~= JOB_STATUS_DONE) then
		return self.FulfillRequisitionJob
	elseif (self.EmergencyScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.EmergencyScheduleJob
	elseif (self.ScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ScheduleJob
	end

	self:SetWait()
end


function TaskSchedule:FixDayAndHour(day, hour)
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
end


--returns a list/table of upcoming programme licences
function TaskSchedule:GetUpcomingProgrammesLicenceList(startHoursBefore, endHoursAfter)
	local currentLicenceList = {}

	if (startHoursBefore == nil) then startHoursBefore = 0 end
	if (endHoursAfter == nil) then endHoursAfter = 12 end
	startHoursBefore = 0
	endHoursAfter = 12

	local dayBegin = WorldTime.GetDay()
	local hourBegin = WorldTime.GetDayHour() + startHoursBefore
	local dayEnd = WorldTime.GetDay()
	local hourEnd = WorldTime.GetDayHour() + endHoursAfter

	dayBegin, hourBegin = self:FixDayAndHour(dayBegin, hourBegin)
	dayEnd, hourEnd = self:FixDayAndHour(dayEnd, hourEnd)


	--fetch all upcoming objects, last param = true, so only programmes
	--are returned, no infomercials
	local response = TVT.of_GetBroadcastMaterialInTimeSpan(TVT.Constants.BroadcastMaterialType.PROGRAMME, dayBegin, hourBegin, dayEnd, hourEnd, false, true)
	plannedProgrammes = response.DataArray()

	for i, broadcastMaterial in ipairs(plannedProgrammes) do
		local licence = MY.GetProgrammeCollection().GetProgrammeLicence(broadcastMaterial.GetReferenceID())
		if (licence ~= nil) then
			table.insert(currentLicenceList, licence)
		end
	end

	return currentLicenceList
end


-- helper function: find element in list "l" via function f(v)
function TaskSchedule:GetLicenceFromTable(licenceID, l)
	for _, v in ipairs(l) do
		if v.GetReferenceID() == licenceID then
			return v
		end
	end
	return nil
end

function TaskSchedule:GetMaxAudiencePercentage(day, hour)
-- neue Fassung...
-- Eventuell mit ein wenig "Unsicherheit" versehen (schon in Blitzmax)
	return TVT.getPotentialAudiencePercentage(day, hour)

-- alte Fassung...
--[[
	if hour == 0 then
		return 11.40 / 100
	elseif hour == 1 then
		return 6.50 / 100
	elseif hour == 2 then
		return 3.80 / 100
	elseif hour == 3 then
		return 3.60 / 100
	elseif hour == 4 then
		return 2.25 / 100
	elseif hour == 5 then
		return 3.45 / 100
	elseif hour == 6 then
		return 3.25 / 100
	elseif hour == 7 then
		return 4.45 / 100
	elseif hour == 8 then
		return 5.05 / 100
	elseif hour == 9 then
		return 5.60 / 100
	elseif hour == 10 then
		return 5.85 / 100
	elseif hour == 11 then
		return 6.70 / 100
	elseif hour == 12 then
		return 7.85 / 100
	elseif hour == 13 then
		return 9.10 / 100
	elseif hour == 14 then
		return 10.20 / 100
	elseif hour == 15 then
		return 10.90 / 100
	elseif hour == 16 then
		return 11.45 / 100
	elseif hour == 17 then
		return 14.10 / 100
	elseif hour == 18 then
		return 22.95 / 100
	elseif hour == 19 then
		return 33.45 / 100
	elseif hour == 20 then
		return 38.70 / 100
	elseif hour == 21 then
		return 37.60 / 100
	elseif hour == 22 then
		return 28.60 / 100
	elseif hour == 23 then
		return 18.80 / 100
	end
]]--
end

-- Returns an assumption about potential audience for the given hour and
-- (optional) broadcast
-- without given broadcast, an average quality for the hour is used
function TaskSchedule:GuessedAudienceForHourAndLevel(day, hour, broadcast)
	--requesting audience for the current broadcast?
	if (WorldTime.GetDay() == day and WorldTime.GetDayHour() == hour and WorldTime.GetDayMinute() >= 5) then
		return MY.GetProgrammePlan().GetAudience()
	end
	
	local level = self:GetQualityLevel(day, hour) --Welchen Qualitätslevel sollte ein Film/Werbung um diese Uhrzeit haben
	local globalPercentageByHour = self:GetMaxAudiencePercentage(day, hour) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
	local averageMovieQualityByLevel = self:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels
	local broadcastQuality = 0
	local riskyness = 0.60 -- 1.0 means assuming to get all

	--TODO: check advertisements (audience lower than with programmes)
	if (broadcast ~= nil) then
		broadcastQuality = 0.75 * broadcast.GetQuality() + 0.25 * averageMovieQualityByLevel
	else
		broadcastQuality = 1.0 * averageMovieQualityByLevel
	end
	
	--Formel: Filmqualität * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	--TODO: Auchtung! Muss eventuell an die neue Quotenberechnung angepasst werden
	local guessedAudience = riskyness * broadcastQuality * globalPercentageByHour * MY.GetMaxAudience()

	--debugMsg("GuessedAudienceForHourAndLevel - Hour: " .. hour .. "  Level: " .. level .. "  globalPercentageByHour: " .. globalPercentageByHour .. "  averageMovieQualityByLevel: " .. averageMovieQualityByLevel .. "  broadcastQuality: " .. broadcastQuality .. "  MaxAudience: " .. MY.GetMaxAudience() .."  guessedAudience: " .. guessedAudience)
	--debugMsg("GuessedAudienceForHourAndLevel - Hour: " .. hour .. "  Level: " .. level .. "  globalPercentageByHour: " .. globalPercentageByHour .. "  averageMovieQualityByLevel: " .. averageMovieQualityByLevel .. "  broadcastQuality: " .. broadcastQuality .. "  MaxAudience: " .. MY.GetMaxAudience() .."  guessedAudience: " .. guessedAudience)
	return guessedAudience
end

function TaskSchedule:GetQualityLevel(day, hour)
	local maxAudience = self:GetMaxAudiencePercentage(day, hour)
	if (maxAudience <= 0.05) then
		return 1 --Nachtprogramm
	elseif (maxAudience <= 0.10) then
		return 2 --Mitternacht + Morgen
	elseif (maxAudience <= 0.15) then
		return 3 -- Nachmittag
	elseif (maxAudience <= 0.25) then
		return 4 -- Vorabend / Spät
	else
		return 5 -- Primetime
	end
end

--TODO später dynamisieren
function TaskSchedule:GetAverageMovieQualityByLevel(level)
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

-- add the requirement for a (new) specific ad contract
-- - each time the same requirement (level, audience) is requested,
--   its priority increases
-- - as soon as the requirement is fulfilled (new contract signed), it
--   might get placed (if possible)
function TaskSchedule:AddSpotRequisition(guessedAudience, level, day, hour)
	local slotReq = SpotSlotRequisition()
	slotReq.Day = day;
	slotReq.Hour = hour;
	slotReq.Minute = 55; -- xx:55 faengt die Werbung an
	slotReq.GuessedAudience = guessedAudience
	slotReq.Level = level

	-- increase priority if guessedAudience/level is requested again
--	debugMsg("Erhöhe Bedarf an Spots des Levels " .. level .. " (Audience: " .. guessedAudience .. ") für Sendeplatz " .. day .. "/" .. hour .. ":55")
	for k,v in pairs(self.SpotRequisition) do
		if (v.Level == level and math.floor(v.GuessedAudience/2500) <= math.floor(guessedAudience/2500)) then
--		if (v.Level == level) then
			v.Count = v.Count + 1
			if (v.Priority < 5) then
				v.Priority = v.Priority + 1
			end
			table.insert(v.SlotReqs, slotReq)
			return
		end
	end

	local requisition = SpotRequisition()
	requisition.TaskId = _G["TASK_ADAGENCY"]
	requisition.TaskOwnerId = _G["TASK_SCHEDULE"]
	requisition.Priority = 3
	requisition.Level = level
	requisition.GuessedAudience = guessedAudience
	requisition.Count = 1
	requisition.SlotReqs = {}
	table.insert(requisition.SlotReqs, slotReq)
	table.insert(self.SpotRequisition, requisition)
	self.Player:AddRequisition(requisition)
end

--function TaskSchedule:GetMovieByLevel
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobAnalyzeSchedule"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil;
	c.Step = 1
end)

function JobAnalyzeSchedule:typename()
	return "JobAnalyzeSchedule"
end

function JobAnalyzeSchedule:Prepare(pParams)
	--debugMsg("Analysiere Programmplan")
	self.Step = 1
end

function JobAnalyzeSchedule:Tick()
	if self.Step == 1 then
		self:Analyze()
		self.Status = JOB_STATUS_DONE
	end

	self.Step = self.Step + 1
end

function JobAnalyzeSchedule:Analyze()
	--debugMsg("A1")
	for k,v in pairs(self.ScheduleTask) do
--		v:RecalcPriority()
	end
	--debugMsg("A2")
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobFulfillRequisition"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil
	c.SpotSlotRequisitions = nil
end)

function JobFulfillRequisition:typename()
	return "JobFulfillRequisition"
end

function JobFulfillRequisition:Prepare(pParams)
	--debugMsg("Erfülle Änderungs-Anforderungen an den Programmplan!")

	self.Player = _G["globalPlayer"]
	self.SpotSlotRequisitions = self.Player:GetRequisitionsByTaskId(_G["TASK_SCHEDULE"])
end

function JobFulfillRequisition:Tick()
	local gameDay = WorldTime.GetDay()
	local gameHour = WorldTime.GetDayHour()
	local gameMinute = WorldTime.GetDayMinute()

	--check the upcoming advertisements

	for key, value in pairs(self.SpotSlotRequisitions) do
		if (value.ContractId ~= -1) then
			local contract = TVT.of_getAdContractByID(value.ContractId)

			if (contract ~= nil) then
				debugMsg("Setze Werbespot: " .. value.Day .. "/" .. value.Hour .. ":" .. value.Minute .. "  contract: " .. contract.GetTitle() .. " [" .. contract.GetID() .."]  MinAud: " .. contract.GetMinAudience())
				if (value.Day > gameDay or (value.Day == gameDay and value.Hour > gameHour) or (value.Day == gameDay and value.Hour == gameHour and value.Minute > gameMinute)) then
					local result = TVT.of_setAdvertisementSlot(contract, value.Day, value.Hour) --Setzt den neuen Eintrag
					if (result < 0) then debugMsg("###### ERROR 2: " .. value.Day .. "/" .. value.Hour .. ":55  contractID:" .. value.ContractId .. "   Result: " .. result) end
				else
					debugMsg("Setze Werbespot: Zu spät dran. Geplant:" .. value.Day .. "/" .. value.Hour .. ":" .. value.Minute .. "  Zeit:" .. gameHour .. ":" .. gameMinute .. "  contract: " .. contract.GetTitle() .. " [" .. contract.GetID() .."]")
				end
			end
			value:Complete()
		end
	end

	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobEmergencySchedule"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil
	c.SlotsToCheck = 8 --4,
	c.testCase = 0
end)

function JobEmergencySchedule:typename()
	return "JobEmergencySchedule"
end

function JobEmergencySchedule:Prepare(pParams)
	--debugMsg("Prüfe ob dringende Programm- und Werbeplanungen notwendig sind")
	if (unitTestMode) then
		self:UnitTest()
	end
end

function JobEmergencySchedule:Tick()
	if (self.testCase > 3) then
		return nil
	end

	if self:CheckEmergencyCase(self.SlotsToCheck) then
		self:FillIntervals(self.SlotsToCheck)
		self.testCase = self.testCase + 1
	end

	self.Status = JOB_STATUS_DONE
end

-- checks for empty slots (ad/programme) on the given day/hour
function JobEmergencySchedule:CheckEmergencyCase(howManyHours, day, hour)
	local fixedDay, fixedHour = 0
	local currentDay = day
	local currentHour = hour
	if (currentDay == nil) then currentDay = WorldTime.GetDay() end
	if (currentHour == nil) then currentHour = WorldTime.GetDayHour() end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)
		local programme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		if (programme == nil) then
			--debugMsg("CheckEmergencyCase: Programme - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)
		local ad = MY.GetProgrammePlan().GetAdvertisement(fixedDay, fixedHour)
		if (ad == nil) then
			--debugMsg("CheckEmergencyCase: Ad - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	return false
end

-- fills empty slots for the given amount of hours
function JobEmergencySchedule:FillIntervals(howManyHours)
	--Aufgabe: So schnell wie möglich die Lücken füllen
	--Zuschauerberechnung: ZuschauerquoteAufGrundderStunde * Programmquali * MaximalzuschauerproSpieler

	local fixedDay, fixedHour = 0
	local currentDay = WorldTime.GetDay()
	local currentHour = WorldTime.GetDayHour()

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)
		--debugMsg("FillIntervals --- Tag: " .. fixedDay .. " - Stunde: " .. fixedHour)

		--Werbung: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local ad = MY.GetProgrammePlan().GetAdvertisement(fixedDay, fixedHour)
		if (ad == nil) then
			self:SetContractOrTrailerToEmptyBlock(nil, fixedDay, fixedHour)
		end

		--Film: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local programme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		if (programme == nil) then
			self:SetMovieOrInfomercialToEmptyBlock(fixedDay, fixedHour)
		end
	end
end

function JobEmergencySchedule:SetContractOrTrailerToEmptyBlock(choosenSpot, day, hour)
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)
	local level = self.ScheduleTask:GetQualityLevel(fixedDay, fixedHour)

	local previousProgramme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
	local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedDay, fixedHour, previousProgramme)

	local currentSpotList = self:GetFittingSpotList(guessedAudience, false, true, level, fixedDay, fixedHour)


	if (choosenSpot == nil) then
		if (table.count(currentSpotList) == 0) then
			--Neue Anfoderung stellen: Passenden Werbevertrag abschließen (für die Zukunft)
		--	debugMsg("Melde Bedarf für Spots bis " .. guessedAudience .. " Zuschauer an.")
		--	local requisition = SpotRequisition()
		--	requisition.guessedAudience = guessedAudience
		--	local player = _G["globalPlayer"]
		--	player:AddRequisition(requisition)
			currentSpotList = self:GetFittingSpotList(guessedAudience, true, false)
		end

		local filteredCurrentSpotList = self:FilterSpotList(currentSpotList)
		local choosenSpot = self:GetBestMatchingSpot(filteredCurrentSpotList)
	end

	if (choosenSpot ~= nil) then
		debugMsg("Setze Werbespot (Notfallplan): " .. fixedDay .. "/" .. fixedHour .. ":55  contract: " .. choosenSpot.GetTitle() .. " [" ..choosenSpot.GetID() .."]  MinAud: " .. choosenSpot.GetMinAudience())
--		local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(choosenSpot.GetID()), fixedDay, fixedHour)
		local result = TVT.of_setAdvertisementSlot(choosenSpot, fixedDay, fixedHour)
	else
		--nochmal ohne Filter!
		choosenSpot = self:GetBestMatchingSpot(currentSpotList)
		if (choosenSpot ~= nil) then
			debugMsg("Setze Werbespot (Notfallplan - ungefiltert): " .. fixedDay .. "/" .. fixedHour .. ":55  Name: " .. choosenSpot.GetTitle())
			local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(choosenSpot.GetID()), fixedDay, fixedHour)
		else
			debugMsg("Keinen Werbespot (Notfallplan - ungefiltert) gefunden: " .. fixedDay .. "/" .. fixedHour .. ":55")
		end
	end
end

function JobEmergencySchedule:SetMovieOrInfomercialToEmptyBlock(day, hour)
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)

	local level = self.ScheduleTask:GetQualityLevel(fixedDay, fixedHour)
	--debugMsg("Quality-Level: " .. level .. " (" .. fixedHour .. ")")
	local licenceList = nil
	local choosenLicence = nil
	
	licenceList = self:GetFilteredProgrammeLicenceList(level, level, 0, fixedDay)		
	--Bedarf erhöhen
	
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level, 1, 0, fixedDay) end	
	if level <= 2 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(0, fixedDay) end
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level, 1, 1, fixedDay) end
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(0, fixedDay) end	
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level+1, 1, 1, fixedDay) end
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(1, fixedDay) end
	if level <= 4 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(0, fixedDay) end
	if level <= 4 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(1, fixedDay) end
	
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level, 1, 3, fixedDay) end
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level+1, 1, 3, fixedDay) end
	if TVT.of_getProgrammeLicenceCount() < 4 then
		if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level+1, 1, 5, fixedDay) end
	end
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level+2, 1, 1, fixedDay) end
	if TVT.of_getProgrammeLicenceCount() < 4 then
		if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level+2, 1, 6, fixedDay) end
	end
	if (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(3, fixedDay) end

	if (table.count(licenceList) == 1) then
		choosenLicence = table.first(licenceList)
	elseif (table.count(licenceList) > 1) then
		local sortMethod = function(a, b)
			return a.GetAttractiveness() > b.GetAttractiveness()
		end
		table.sort(licenceList, sortMethod)
		choosenLicence = table.first(licenceList)
	end

	if (choosenLicence ~= nil) then
		debugMsg("Setze Film: ".. fixedDay .. "/" .. fixedHour .. ":05  Lizenz: " .. choosenLicence.GetTitle() .. "  quality: " .. choosenLicence.GetQuality())
		TVT.of_setProgrammeSlot(choosenLicence, fixedDay, fixedHour)
	else
		debugMsg("Kein Film gefunden: " .. fixedDay .. "/" .. fixedHour ..":05")
	end
end

function JobEmergencySchedule:GetFilteredProgrammeLicenceList(maxLevel, level, maxRerunsToday, day)
	for i = maxLevel,level,-1 do
		programmeList = self:GetProgrammeLicenceList(i, maxRerunsToday, day)
		if (table.count(programmeList) > 0) then
	--		debugMsg("GetFilteredProgrammeLicenceList: maxLevel: " .. maxLevel .. "   level: " .. level .. "   maxRerunsToday: " .. maxRerunsToday .. " currLevel: " .. i)
			break
		end
	end
	return programmeList
end

function JobEmergencySchedule:GetProgrammeLicenceList(level, maxRerunsToday, day)
	local currentLicenceList = {}

	for i=0,MY.GetProgrammeCollection().GetProgrammeLicenceCount()-1 do
		local licence = MY.GetProgrammeCollection().GetProgrammeLicenceAtIndex(i)
		if ( licence ~= nil and licence.isNewBroadcastPossible() == 1) then
			-- TVT.PrintOut("licence is broadcastable: " .. licence.GetTitle() .. "   " .. licence.isNewBroadcastPossible() .. "  " .. licence.GetData().IsControllable())
			if licence.GetQualityLevel() == level then
				local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
				--debugMsg("GetProgrammeLicenceList: " .. i .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday)
				if (sentAndPlannedToday <= maxRerunsToday) then
					--debugMsg("Lizenz: " .. licence.GetTitle() .. " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality())
					table.insert(currentLicenceList, licence)
				end
			end
		end
	end

	return currentLicenceList
end


function JobEmergencySchedule:GetInfomercialLicenceList(maxRerunsToday, day)
	local currentLicenceList = {}

	for i = 0,MY.GetProgrammeCollection().GetAdContractCount()-1 do
		local licence = MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if ( licence ~= nil) then
			local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
			--debugMsg("GetProgrammeLicenceList: " .. i .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday)
			if (sentAndPlannedToday <= maxRerunsToday) then
				--debugMsg("Lizenz: " .. licence.GetTitle() .. " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality())
				table.insert(currentLicenceList, licence)
			end
		end
	end

	return currentLicenceList
end

-- get a list of spots fitting the given requirements
-- - if there is no spot available, the requirements are lowered and
--   and a request for new spot contracts is created
function JobEmergencySchedule:GetFittingSpotList(guessedAudience, noBroadcastRestrictions, lookForRequisition, requisitionLevel, day, hour)
	local currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.8, false, noBroadcastRestrictions)
	if (table.count(currentSpotList) == 0) then
		currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.6, false, noBroadcastRestrictions)
		if (table.count(currentSpotList) == 0) then
			--Bedarf an passenden Spots anmelden.
			if (lookForRequisition) then
				self.ScheduleTask:AddSpotRequisition(guessedAudience, requisitionLevel, day, hour)
			end
			currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.4, false, noBroadcastRestrictions)
			if (table.count(currentSpotList) == 0) then
				currentSpotList = self:GetMatchingSpotList(guessedAudience, 0, false, noBroadcastRestrictions)
				if (table.count(currentSpotList) == 0) then
					currentSpotList = self:GetMatchingSpotList(guessedAudience, 0, true, noBroadcastRestrictions)
				end
			end
		end
	end
	return currentSpotList;
end

function JobEmergencySchedule:GetMatchingSpotList(guessedAudience, minFactor, noAudienceRestrictions, noBroadcastRestrictions)
	local currentSpotList = {}
	for i = 0, TVT.of_getAdContractCount() - 1 do
		local contract = TVT.of_getAdContractAtIndex(i)

		--only add contracts
		if (contract ~= nil) then
			local minAudience = contract.GetMinAudience()
			--debugMsg("GetMatchingSpotList - MinAud: " .. minAudience .. " <= " .. guessedAudience)
			if ((minAudience <= guessedAudience) and (minAudience >= guessedAudience * minFactor)) or noAudienceRestrictions then
				local count = MY.GetProgrammePlan().GetAdvertisementsSent(contract, -1, 23, 1)
				--debugMsg("GetMatchingSpotList: " .. contract.GetTitle() .. ". SpotsSent: " .. count)
				if (count < contract.GetSpotCount() or noBroadcastRestrictions) then
					table.insert(currentSpotList, contract)
				end
			end
		end
	end
	return currentSpotList
end

function JobEmergencySchedule:FilterSpotList(spotList)
	local currentSpotList = {}
	for k,v in pairs(spotList) do
		if v.SendMinimalBlocksToday() > 0 then --TODO: Die Anzahl der bereits geplanten Sendungen von MinBlocksToday abziehen
			table.insert(currentSpotList, v)
		end
	end
	--TODO: Optimum hinzufügen
	if (table.count(currentSpotList) > 0) then
		return currentSpotList
	else
		return spotList
	end
end

function JobEmergencySchedule:GetBestMatchingSpot(spotList)
	local bestAcuteness = -1
	local bestSpot = nil

	for k,v in pairs(spotList) do
		local acuteness = v.GetAcuteness()
		if (bestAcuteness < acuteness) then
			bestAcuteness = acuteness
			bestSpot = v
		end
	end

	return bestSpot
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobSchedule"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.ScheduleTask = nil
end)

function JobSchedule:typename()
	return "JobSchedule"
end

function JobSchedule:Prepare(pParams)
	--debugMsg("Schaue Programmplan an")
end

function JobSchedule:Tick()
	debugMsg("JobSchedule:Tick()  " .. WorldTime.GetDayHour()..":"..WorldTime.GetDayMinute())

	--optimize existing schedule
	--==========================

	-- replace ads with trailers if ads have to high requirements
	-- also replace ads with better performing ones
	local fixedDay, fixedHour = 0
	local currentDay = WorldTime.GetDay()
	local currentHour = WorldTime.GetDayHour()

	--rate of "ad-MinAudience / guessedAudience". Ads below get replaced
	--with trailers 
	local replaceBadAdsWithTrailerRatePrimeTime = 0.05
	local replaceBadAdsWithTrailerRateDay = 0.20
	local replaceBadAdsWithTrailerRateNight = 0.30
	for i = currentHour, currentHour + 12 do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)

		-- increase trailer rate during night
		local replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRateDay
		if (fixedHour >= 1 and fixedHour <= 7) then
			replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRateNight
		elseif (fixedHour >= 19 and fixedHour <= 23) then
			replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRatePrimeTime
		end


		local choosenBroadcastSource = nil
		local choosenBroadcastLog = ""
		local currentBroadcastMaterial = MY.GetProgrammePlan().GetAdvertisement(fixedDay, fixedHour)
		
		local sendTrailer = false
		local sendTrailerReason = ""
		local sendAd = true

		local previousProgramme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedDay, fixedHour, previousProgramme)
	

		-- send a trailer:
		-- ===============
		-- (to avoid outages ... later stages might set an advertisement
		--  instead)
		
		-- send trailer: if nothing is send
		if (currentBroadcastMaterial == nil) then
			sendTrailerReason = "no ad"
			sendTrailer = true
		-- send trailer: if a planned advertisement is not satisfiable
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
			local adContract = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
			if (previousProgramme ~= nil and adContract ~= nil) then
				if guessedAudience < adContract.GetMinAudience() then
					sendTrailerReason = "unsatisfiable ad (aud "..math.floor(guessedAudience) .. "  <  minAud " .. adContract.GetMinAudience() .. ")"
					sendTrailer = true
				end
			end
		-- send trailer: if there is a better one available?
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1) then
			local upcomingProgrammesLicences = self.ScheduleTask:GetUpcomingProgrammesLicenceList()
			local licenceID = currentBroadcastMaterial.GetReferenceID()
			-- is the trailer of the past?
			if (not self.ScheduleTask:GetLicenceFromTable(licenceID, upcomingProgrammesLicences)) then
				-- is there something planned in the future?
				if (table.count(upcomingProgrammesLicences) > 0) then 
					sendTrailerReason = "better trailer (of upcoming)"
					sendTrailer = true
				end
			end
		end


		-- find better suiting ad
		-- ======================
		local minAudienceFactor = 0.6
		-- during afternoon/evening prefer ads (lower ad requirements)
		if fixedHour >= 14 and fixedHour < 24 then minAudienceFactor = 0.3 end
		-- during primetime, send ad at up to all cost?
		if fixedHour >= 19 and fixedHour <= 23 then minAudienceFactor = 0.05 end

		local betterAdContractList = self.ScheduleTask.EmergencyScheduleJob:GetMatchingSpotList(guessedAudience, minAudienceFactor, false, false)
		if (table.count(betterAdContractList) > 0) then
--if fixedHour >= 19 and fixedHour <= 23 then
--	debugMsg( fixedHour..":55  " .. table.count(betterAdContractList) .. "  guessed: "..guessedAudience .. "  minAudFac: "..  minAudienceFactor)
--end
			local oldAdContract
			local oldMinAudience = 0
			if (currentBroadcastMaterial and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
				oldAdContract = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
				if (oldAdContract ~= nil) then
					oldMinAudience = oldAdContract.GetMinAudience()
				end
			end

			-- fetch best fitting spot (most emerging one)
			local newAdContract = self.ScheduleTask.EmergencyScheduleJob:GetBestMatchingSpot(betterAdContractList)
			local oldAudienceCoverage = 1.0
			local newAudienceCoverage = 1.0 --a 0-guessedAudience is always covered by 100%
			if oldAdContract == nil then oldAudienceCoverage = 0 end
			if guessedAudience > 0 then
				newAudienceCoverage = newAdContract.GetMinAudience() / guessedAudience
				oldAudienceCoverage = oldMinAudience / guessedAudience
			end
			local audienceCoverageIncrease = newAudienceCoverage - oldAudienceCoverage
--if fixedHour >= 19 and fixedHour <= 23 then
--	debugMsg( fixedHour..":55  newAudienceCoverage: ".. newAudienceCoverage .. "  replaceBadAdsWithTrailerRate: "..  replaceBadAdsWithTrailerRate .. "  audienceCoverageIncrease: ".. audienceCoverageIncrease)
--end

			-- if new spot only covers <x% of guessed Audience, do not place
			-- an ad, better place a trailer
			-- replace "minAudience=0"-spots with trailers!
			if (newAudienceCoverage > replaceBadAdsWithTrailerRate) then
				-- only different spots - and when audience requirement is at better
				if (newAdContract ~= oldAdContract and audienceCoverageIncrease > 0) then
					choosenBroadcastSource = newAdContract
					choosenBroadcastLog = "Setze Werbespot (optimiert): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. newAdContract.GetTitle() .. " [" .. newAdContract.GetID() .."]  MinAud: " .. newAdContract.GetMinAudience() .. " (vorher: " .. oldMinAudience .. ")"
					sendTrailer = false
				end
			else
				-- only place a trailer, if previous is an advertisement
				if (oldSpot ~= nil) then
					sendTrailerReason = "new ad below ReplaceWithTrailerRate"
					sendTrailer = true
				end
			end

			-- no ad contract found but having an old one?
			if (choosenBroadcastSource == nil and oldAdContract) then
				sendAd = false
				sendTrailer = false
				choosenBroadcastSource = oldAdContract
				--debugMsg("Belasse alten Werbespot: " .. fixedDay .. "/" ..fixedHour .. ":55  " .. oldAdContract.GetTitle())
			end
		end


		-- avoid outage and set to send a trailer in all cases
		if (choosenBroadcastSource == nil and (currentBroadcastMaterial ~= nil)) then
			sendTrailer = true
			sendTrailerReason = "avoid outage"
		end
		

		-- send a trailer
		-- ==============
		if (sendTrailer == true) then
			local upcomingProgrammesLicences = self.ScheduleTask:GetUpcomingProgrammesLicenceList()

			local oldTrailer
			if (currentBroadcastMaterial and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1) then
				oldTrailer = TVT.of_getProgrammeLicenceByID( currentBroadcastMaterial.GetReferenceID() )
			end

			-- old trailer no longer promoting upcoming programme?
			local reuseOldTrailer = false
			if (oldTrailer ~= nil) then
				reuseOldTrailer = true
				--not in the upcoming list?
				if (self.ScheduleTask:GetLicenceFromTable(oldTrailer.GetID(), upcomingProgrammesLicences) ~= nil) then
					reuseOldTrailer = false
				end
			end

			if (reuseOldTrailer == false) then 
				-- look for upcoming programmes
				if (table.count(upcomingProgrammesLicences) == 0) then
					-- nothing found: use a random one
					upcomingProgrammesLicences = { TVT.of_getProgrammeLicenceAtIndex( math.random(0, TVT.of_getAdContractCount()-1) ) }
				end

				if (table.count(upcomingProgrammesLicences) > 0) then
					local choosenLicence = upcomingProgrammesLicences[ math.random( #upcomingProgrammesLicences ) ]
					if (choosenLicence ~= nil) then
						choosenBroadcastSource = choosenLicence
						choosenBroadcastLog = "Setze Trailer: " .. fixedDay .. "/" .. fixedHour .. ":55  " .. choosenLicence.GetTitle() .. "  Reason: " .. sendTrailerReason
					end
				end
			else
				-- reuse the old trailer
				if (reuseOldTrailer) then
					sendAd = false
					sendTrailer = false
					choosenBroadcastSource = oldTrailer
					--debugMsg("Belasse alten Trailer: " .. fixedDay .. "/" ..fixedHour .. ":55  " .. oldTrailer.GetTitle())
				end
			end
		end


		-- avoid outage
		-- ============
		-- send a random ad spot if nothing else is available
		if (choosenBroadcastSource == nil and currentBroadcastMaterial == nil) then
			choosenBroadcastSource = TVT.of_getAdContractAtIndex( math.random(0, TVT.of_getAdContractCount()-1) )
			choosenBroadcastLog = "Setze Werbespot (Alternativlosigkeit): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. choosenBroadcastSource.GetTitle() .. " [" ..choosenBroadcastSource.GetID() .."]  MinAud: " .. choosenBroadcastSource.GetMinAudience()
		end


		-- set new material
		-- ================
		if (choosenBroadcastSource ~= nil) then
			local result = TVT.of_setAdvertisementSlot(choosenBroadcastSource, fixedDay, fixedHour)
			if (result > 0) then
				debugMsg(choosenBroadcastLog)
			end
		end
	end



	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<