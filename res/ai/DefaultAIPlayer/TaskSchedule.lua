-- File: TaskSchedule
-- File: TaskSchedule
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskSchedule"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME
	c.BudgetWeight = 0
	c.BasePriority = 10
	c.TodayMovieSchedule = {}
	c.TomorrowMovieSchedule = {}
	c.TodaySpotSchedule = {}
	c.TomorrowSpotSchedule = {}
	c.SpotInventory = {}
	c.SpotRequisition = {}
	c.Player = nil

	-- one entry per hour
	--[[
    c.guessedAudienceAccuracy = {}
    c.guessedAudienceAccuracyCount = {}
    for i=1, 24 do
      c.guessedAudienceAccuracy[i] = 0
      c.guessedAudienceAccuracyCount[i] = 0
    end
    ]]--
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
	if (self.AnalyzeScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyzeScheduleJob
	elseif (self.FulfillRequisitionJob.Status ~= JOB_STATUS_DONE) then
		return self.FulfillRequisitionJob
	elseif (self.EmergencyScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.EmergencyScheduleJob
	elseif (self.ScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ScheduleJob
	end

	--self:SetWait()
	self:SetDone()
end


function TaskSchedule:FixDayAndHour(day, hour)
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
end


function TaskSchedule:GetInfomercialLicenceList(maxRerunsToday, day)
	local currentLicenceList = {}

	for i = 0,MY.GetProgrammeCollection().GetAdContractCount()-1 do
		local licence = MY.GetProgrammeCollection().GetAdContractAtIndex(i)
		if ( licence ~= nil) then
			local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
			--debugMsg("GetProgrammeLicenceList: " .. i .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday)
			if (sentAndPlannedToday <= maxRerunsToday or maxRerunsToday < 0) then
				--debugMsg("Lizenz: " .. licence.GetTitle() .. " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality())
				table.insert(currentLicenceList, licence)
			end
		end
	end

	-- sort the list by highest PerViewerRevenue
	local sortMethod = function(a, b)
		return a.GetPerViewerRevenue() > b.GetPerViewerRevenue()
	end
	table.sort(currentLicenceList, sortMethod)

	return currentLicenceList
end


function TaskSchedule:GetMovieOrInfomercialForBlock(day, hour)
	local fixedDay, fixedHour = self:FixDayAndHour(day, hour)

	local level = self:GetQualityLevel(fixedDay, fixedHour)
	--debugMsg("Quality-Level: " .. level .. " (" .. fixedHour .. ")")
	local licenceList = nil
	local choosenLicence = nil
	
	licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level, level, 0, fixedDay, fixedHour)		
	--TODO: raise interest in this level if not enough licences are available

	--use worse programmes if you cannot choose from a big pool
	if TVT.of_getProgrammeLicenceCount() < 6 then
		level = level + 2
	end
	
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level, 1, 0, fixedDay, fixedHour) end	
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(0, fixedDay) end
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 1, fixedDay, fixedHour) end
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(1, fixedDay) end	
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 2, fixedDay, fixedHour) end
	if level <= 3 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(2, fixedDay) end
	if level <= 4 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(1, fixedDay) end
	if level <= 4 and (table.count(licenceList) == 0) then licenceList = self:GetInfomercialLicenceList(2, fixedDay) end
	
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 3, fixedDay, fixedHour) end
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+2, 1, 3, fixedDay, fixedHour) end
	if TVT.of_getProgrammeLicenceCount() < 4 then
		if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+1, 1, 5, fixedDay, fixedHour) end
	end
	if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+2, 1, 1, fixedDay, fixedHour) end
	if TVT.of_getProgrammeLicenceCount() < 4 then
		if (table.count(licenceList) == 0) then licenceList = self.EmergencyScheduleJob:GetFilteredProgrammeLicenceList(level+2, 1, 6, fixedDay, fixedHour) end
	end

	-- still nothing found, try to fetch an infomercial
	-- with a really high repeat-amount
	if (table.count(licenceList) == 0) then
		licenceList = self:GetInfomercialLicenceList(6, fixedDay)
	end

	if (table.count(licenceList) == 1) then
		choosenLicence = table.first(licenceList)
	elseif (table.count(licenceList) > 1) then
		local sortMethod = function(a, b)
			return a.GetQuality()*a.GetProgrammeTopicality() > b.GetQuality()*b.GetProgrammeTopicality()
		end
		table.sort(licenceList, sortMethod)
		choosenLicence = table.first(licenceList)
	end
	
	return choosenLicence
end

--returns a list/table of upcoming programme licences
function TaskSchedule:GetUpcomingProgrammesLicenceList(startHoursBefore, endHoursAfter)
	local currentLicenceList = {}

	if (startHoursBefore == nil) then startHoursBefore = 0 end
	if (endHoursAfter == nil) then endHoursAfter = 12 end

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


--returns a list/table of available contracts
-- hoursFromNow: hours to add to current time (past contracts are already
--               removed from player collection then)
-- includePlannedEnds: whether to include contracts which are planned
--                     to be finished in that time
-- onlyInfomercials: whether to only include contracts allowing infomercials
function TaskSchedule:GetAvailableContractsList(hoursFromNow, includePlannedEnds, onlyInfomercials)
	--defaults
	if (hoursFromNow == nil) then hoursFromNow = 0 end
	if (includePlannedEnds == nil) then includePlannedEnds = true end
	if (onlyInfomercials == nil) then onlyInfomercials = false end

	local day = WorldTime.GetDay()
	local hour = WorldTime.GetDayHour() + hoursFromNow
	day, hour = self:FixDayAndHour(day, hour)

	--fetch all contracts, insert all "available" to a list
	local response = TVT.of_getAdContracts()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end

	local allContracts = response.DataArray()
	local possibleContracts = {}

	for i, contract in ipairs(allContracts) do
		--repeat loop allows to use "break" to go to next entry
		repeat
			if contract == nil then break end
			--contract does not allow infomercials
			if onlyInfomercials and contract.IsInfomercialAllowed() == 0 then break end
			--contract ends earlier
			if contract.GetDaysLeft(day) < 0 then break end
			--contract might end earlier (all needed slots planned
			--before the designated time)
			if not includePlannedEnds and contract.GetSpotCount() <= MY.GetProgrammePlan().GetAdvertisementsPlanned(contract, day, hour, true) then break end

			table.insert(possibleContracts, contract)
		until true
	end

	return possibleContracts
end


-- helper function: find element in list "l" via function f(v)
function TaskSchedule:GetBroadcastSourceFromTable(referenceID, l)
	for _, v in ipairs(l) do
		if v.GetReferenceID() == referenceID then
			return v
		end
	end
	return nil
end

function TaskSchedule:GetMaxAudiencePercentage(day, hour)
	-- Eventuell mit ein wenig "Unsicherheit" versehen (schon in Blitzmax)
	return TVT.getPotentialAudiencePercentage(day, hour)
end

-- Returns an assumption about potential audience for the given hour and
-- (optional) broadcast
-- without given broadcast, an average quality for the hour is used
function TaskSchedule:GuessedAudienceForHourAndLevel(day, hour, broadcast, guessCurrentHour)
	if (guessCurrentHour == nil) then guessCurrentHour = true; end
	
	--requesting audience for the current broadcast?
	if (guessCurrentHour == false) and (WorldTime.GetDay() == day and WorldTime.GetDayHour() == hour and WorldTime.GetDayMinute() >= 5) then
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
	return guessedAudience
end

function TaskSchedule:GetQualityLevel(day, hour)
	local maxAudience = self:GetMaxAudiencePercentage(day, hour)
	if (maxAudience <= 0.06) then
		return 1 --Nachtprogramm
	elseif (maxAudience <= 0.12) then
		return 2 --Mitternacht + Morgen
	elseif (maxAudience <= 0.18) then
		return 3 -- Nachmittag
	elseif (maxAudience <= 0.24) then
		return 4 -- Vorabend / Spät
	else
		return 5 -- Primetime
	end
end

--TODO später dynamisieren
function TaskSchedule:GetAverageMovieQualityByLevel(level)
	if (level == 1) then
		return 0.04 --Nachtprogramm
	elseif (level == 2) then
		return 0.10 --Mitternacht + Morgen
	elseif (level == 3) then
		return 0.15 -- Nachmittag
	elseif (level == 4) then
		return 0.20 -- Vorabend / Spät
	elseif (level == 5) then
		return 0.25 -- Primetime
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
	slotReq.Minute = 55; -- xx:55 adspots start
	slotReq.GuessedAudience = guessedAudience
	slotReq.Level = level

	-- increase priority if guessedAudience/level is requested again
	debugMsg("Raise demand on spots of level " .. level .. " (Audience: " .. math.ceil(guessedAudience) .. "). " .. day .. "/" .. hour .. ":55")
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

function TaskSchedule:FixAdvertisement(day, hour)
	if (TVT.GetAdContractCount() <= 1) and (TVT.GetProgrammeLicenceCount() <= 0)  then 
		debugMsg("FixAdvertisement: " .. day .."/".. hour .. ":55 - NOT POSSIBLE, not enough adcontracts (>1) or licences.")
	else
		debugMsg("FixAdvertisement: " .. day .."/".. hour .. ":55")

		--increase importance of schedule task!
		self.SituationPriority = 75

		-- assign player (if called from outside, this is not set yet)
		self.Player = _G["globalPlayer"]
		-- should start schedule then
		self.Player:ForceNextTask()
	end
end

function TaskSchedule:_FixImminentOutage(day, hour, minute, situationPriority)
	if (TVT.GetAdContractCount() <= 0) and (TVT.GetProgrammeLicenceCount() <= 0) then 
		debugMsg("FixImminentOutage: " .. day .."/".. hour .. ":" .. minute .. " - NOT POSSIBLE, not enough adcontracts or licences.")
	else
		debugMsg("FixImminentOutage: " .. day .."/".. hour .. ":" .. minute)

		--increase importance of schedule task!
		self.SituationPriority = situationPriority

		-- assign player (if called from outside, this is not set yet)
		self.Player = _G["globalPlayer"]
		-- should start schedule then
		self.Player:ForceNextTask()
	end
end

function TaskSchedule:FixImminentAdOutage(day, hour)
	-- the further away, the lower the priority
	self:_FixImminentOutage(day, hour, "55", 65 - math.min(20, 5 * (hour - WorldTime.GetDayHour() + 1)))
end

function TaskSchedule:FixImminentProgrammeOutage(day, hour)
	-- the further away, the lower the priority
	self:_FixImminentOutage(day, hour, "05", 75 - math.min(20, 5 * (hour - WorldTime.GetDayHour() + 1)))
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
				debugMsg("Set advertisement: " .. value.Day .. "/" .. value.Hour .. ":" .. value.Minute .. "  contract: " .. contract.GetTitle() .. " [" .. contract.GetID() .."]  MinAud: " .. contract.GetMinAudience() .. "  acuteness: " .. contract.GetAcuteness())
				local result = TVT.of_setAdvertisementSlot(contract, value.Day, value.Hour) --Setzt den neuen Eintrag
				if (result == TVT.RESULT_WRONGROOM) then
					debugMsg("Set advertisement: failed - wrong room.")
				elseif (result == TVT.RESULT_FAILED) then
					debugMsg("Set advertisement: corresponding contract not found.")
				elseif (result == TVT.RESULT_SKIPPED) then
					debugMsg("Set advertisement: skipped, already placed at this spot.")
				elseif (result == TVT.RESULT_NOTALLOWED) then
					debugMsg("Set advertisement: too late / not allowed.")
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
	c.SlotsToCheck = 18
	--c.testCase = 0
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
	--if (self.testCase > 3) then
	--	return nil
	--end

	if self:CheckEmergencyCase(self.SlotsToCheck) then
		self:FillIntervals(self.SlotsToCheck)
		--self.testCase = self.testCase + 1
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
			-- Add new requisition for the future: sign fitting contract
			--[[
			debugMsg"Signal need for spots with audience of " .. guessedAudience .. ".")
			local requisition = SpotRequisition()
			requisition.guessedAudience = guessedAudience
			local player = _G["globalPlayer"]
			player:AddRequisition(requisition)
			]]--

			-- this time ignore broadcast limits (spot 5 of 3)
			--currentSpotList = self:GetFittingSpotList(guessedAudience, true, false)

			currentSpotList = self:GetFittingSpotList(guessedAudience * 0.5, true, false)
			if (table.count(currentSpotList) == 0) then
				currentSpotList = self:GetFittingSpotList(guessedAudience * 0.1, true, false)
			end
		end

		local filteredCurrentSpotList = self:FilterSpotList(currentSpotList, day, hour)
		local choosenSpot = self:GetBestMatchingSpot(filteredCurrentSpotList)
	end

	if (choosenSpot ~= nil) then
		debugMsg("Set advertisement (emergency plan): " .. fixedDay .. "/" .. fixedHour .. ":55  contract: " .. choosenSpot.GetTitle() .. " [" ..choosenSpot.GetID() .."]  MinAud: " .. choosenSpot.GetMinAudience() .. "  acuteness: " .. choosenSpot.GetAcuteness())
		local result = TVT.of_setAdvertisementSlot(choosenSpot, fixedDay, fixedHour)
	else
		--choose spot without any audience requirements
		local currentSpotList = self:GetFittingSpotList(0, false, false, 0, fixedDay, fixedHour)
		--remove ads without left spots 
		local filteredCurrentSpotList = self:FilterSpotList(currentSpotList, fixedDay, fixedHour)

		choosenSpot = self:GetBestMatchingSpot(filteredCurrentSpotList)
		if (choosenSpot ~= nil) then
			debugMsg("Set advertisement (emergency plan - unfiltered): " .. fixedDay .. "/" .. fixedHour .. ":55  contract: " .. choosenSpot.GetTitle() .. "  acuteness: " .. choosenSpot.GetAcuteness())
			local result = TVT.of_setAdvertisementSlot(choosenSpot, fixedDay, fixedHour)
		else
			debugMsg("Set advertisement (emergency plan - unfiltered): " .. fixedDay .. "/" .. fixedHour .. ":55  NONE FOUND")
		end
	end
end



function JobEmergencySchedule:SetMovieOrInfomercialToEmptyBlock(day, hour)
	local choosenLicence = self.ScheduleTask:GetMovieOrInfomercialForBlock(day, hour)
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)

	if (choosenLicence == nil) then
		debugMsg("No Programme / Infomercial found. Choosing a random infomercial: " .. fixedDay .. "/" .. fixedHour ..":05")
		local licenceList = self.ScheduleTask:GetInfomercialLicenceList(-1, fixedDay)
		if table.count(licenceList) > 0 then
			choosenLicence = table.first(licenceList)
		end
	end

	if (choosenLicence ~= nil) then
		debugMsg("Set Programme: ".. fixedDay .. "/" .. fixedHour .. ":05  licence: " .. choosenLicence.GetTitle() .. "  quality: " .. choosenLicence.GetQuality())
		TVT.of_setProgrammeSlot(choosenLicence, fixedDay, fixedHour)
	else
		debugMsg("Set Programme: " .. fixedDay .. "/" .. fixedHour ..":05  NO PROGRAMME FOUND")
	end
end


function JobEmergencySchedule:GetFilteredProgrammeLicenceList(maxLevel, level, maxRerunsToday, day, hour)
	for i = maxLevel,level,-1 do
		programmeList = self:GetProgrammeLicenceList(i, maxRerunsToday, day, hour)
		if (table.count(programmeList) > 0) then
	--		debugMsg("GetFilteredProgrammeLicenceList: maxLevel: " .. maxLevel .. "   level: " .. level .. "   maxRerunsToday: " .. maxRerunsToday .. " currLevel: " .. i)
			break
		end
	end
	return programmeList
end

function JobEmergencySchedule:GetProgrammeLicenceList(level, maxRerunsToday, day, hour)
	local allLicences = {}
	local useableLicences = {}
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)

	-- add every licence broadcastable at the given time
	for i=0,TVT.of_getProgrammeLicenceCount()-1 do
		local licence = TVT.of_getProgrammeLicenceAtIndex(i)
		if (licence ~= nil) then
			local addIt = true
			-- ignore collection/series headers
			if ( licence.GetSubLicenceCount() > 0 ) then addIt = false; end
			-- ignore when exceeding broadcast limits
			if ( licence.isExceedingBroadcastLimit() == 1 ) then addIt = false; end
			-- ignore programme licences not allowed for that time
			if ( licence.CanBroadcastAtTime(TVT.Constants.BroadcastMaterialType.PROGRAMME, fixedDay, fixedHour) ~= 1 ) then addIt = false; end
			-- skip xrated programme during daytime
			if (licence.GetData().IsXRated() == 1) and (fixedHour < 22 and fixedHour + licence.data.GetBlocks() > 5) then addIt = false; end
			-- skip if no new broadcast is possible (controllable and available)
			if (licence.isNewBroadcastPossible() == 0) then addIt = false; end
			
			if ( addIt == true ) then
				table.insert(allLicences, licence)
			end
		end
	end


	for k,licence in pairs(allLicences) do
		if licence.GetQualityLevel() == level then
			local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
			if (sentAndPlannedToday <= maxRerunsToday) then
				--debugMsg("GetProgrammeLicenceList: " .. licence.GetTitle() .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday .. " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality())
				table.insert(useableLicences, licence)
			else
				--debugMsg("GetProgrammeLicenceList: " .. licence.GetTitle() .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday ..  " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality() .. "   failed Runs " .. maxRerunsToday)
			end
		--else
			--local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(licence.GetID(), day, 1)
			--debugMsg("GetProgrammeLicenceList: " .. licence.GetTitle() .. " - " .. sentAndPlannedToday .. " <= " .. maxRerunsToday ..  " - A:" .. licence.GetAttractiveness() .. " Qa:" .. licence.GetQualityLevel() .. " Qo:" .. licence.GetQuality() .. " T:" .. licence.GetTopicality() .. "   failed level " .. level)
		end
	end

	return useableLicences
end



-- get a list of spots fitting the given requirements
-- - if there is no spot available, the requirements are lowered and
--   and a request for new spot contracts is created
function JobEmergencySchedule:GetFittingSpotList(guessedAudience, noBroadcastRestrictions, lookForRequisition, requisitionLevel, day, hour)
	-- 0.8, 0.6 ... lowers how "near" the minAudience should be at
	-- the guessed audience
	local currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.8, false, noBroadcastRestrictions)
	if (table.count(currentSpotList) == 0) then
		currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.6, false, noBroadcastRestrictions)
		if (table.count(currentSpotList) == 0) then
			--Bedarf an passenden Spots anmelden.
			if (lookForRequisition) then
				-- only do this, if we do not have some older but "lower"
				-- ads available
				local allSpotsBelow = self:GetMatchingSpotList(guessedAudience, 0, true, false)
				local allSpotsBelowCount = 0
				if allSpotsBelow ~= nil then
					allSpotsBelowCount = table.count(allSpotsBelow)
				end

				if allSpotsBelowCount <= 4 then
					self.ScheduleTask:AddSpotRequisition(guessedAudience, requisitionLevel, day, hour)
				else
					debugMsg("GetFittingSpotList: skip adding spot requisition, enough lower adcontracts available (" .. allSpotsBelowCount .."x)")
				end
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
	local currentDay = WorldTime.GetDay()
	for i = 0, TVT.of_getAdContractCount() - 1 do
		local contract = TVT.of_getAdContractAtIndex(i)

		--only add contracts
		if (contract ~= nil) then
			local minAudience = contract.GetMinAudience()
			--debugMsg("GetMatchingSpotList - MinAud: " .. minAudience .. " <= " .. guessedAudience)
			if ((minAudience <= guessedAudience) and (minAudience >= guessedAudience * minFactor)) or noAudienceRestrictions then
				local count = MY.GetProgrammePlan().GetAdvertisementsPlanned(contract, -1, -1, 1)
				--debugMsg("GetMatchingSpotList: " .. contract.GetTitle() .. ". SpotsPlanned: " .. count)
	
				if (count < contract.GetSpotCount() or noBroadcastRestrictions) then
					table.insert(currentSpotList, contract)
				end
			end
		end
	end
	return currentSpotList
end

function JobEmergencySchedule:FilterSpotList(spotList, day, hour)
	local fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(day, hour)

	local currentSpotList = {}
	for k,v in pairs(spotList) do
		if v.SendMinimalBlocksToday() > 0 then
			-- only add, if there is another spot left
			local count = MY.GetProgrammePlan().GetAdvertisementsPlanned(contract, day, hour, 1)
			if (count < contract.GetSpotCount()) then
				table.insert(currentSpotList, v)
			end
		end
	end
	--TODO: Optimum hinzufügen
	if (table.count(currentSpotList) > 0) then
		return currentSpotList
	else
		return spotList
	end
end


-- returns the most acute adcontract of the given list
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


function JobEmergencySchedule:GetBroadcastTypeCount(slotType, broadcastType, day)
	if (slotType) == nil then return 0 end

	local result = 0

	if (day == nil) then
		day = WorldTime.GetDay()
	end
	if (broadcastType) == nil then
		broadcastType = 0
	end
	
	for hour = 0, 23 do
		local currentBroadcastMaterial
		if slotType == TVT.Constants.BroadcastMaterialType.ADVERTISEMENT then
			currentBroadcastMaterial = MY.GetProgrammePlan().GetAdvertisement(day, hour)
		elseif slotType == TVT.Constants.BroadcastMaterialType.PROGRAMME then
			currentBroadcastMaterial = MY.GetProgrammePlan().GetProgramme(day, hour)
		end

		if (currentBroadcastMaterial ~= nil) then
			if (currentBroadcastMaterial.isType(broadcastType) == 1) then
				result = result + 1
			end
		end
	end
	return result
end


function JobEmergencySchedule:GetTrailerCount(day)
	return self:GetBroadcastTypeCount(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT, TVT.Constants.BroadcastMaterialType.PROGRAMME, day)
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


function JobSchedule:GetUsedSlotsCount(beginDay, beginHour, hours, printIt)
	local slotsFound = 0
    for i=0, hours-1 do
		fixedDay, fixedHour = FixDayAndHour(beginDay, beginHour + i)
		local currentBroadcastMaterial = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		if (currentBroadcastMaterial ~= nil) then
			if (printIt == true) then debugMsg(fixedDay.."/"..fixedHour..":05") end
			slotsFound = slotsFound + 1
		else
			if (printIt == true) then debugMsg(fixedDay.."/"..fixedHour..":05 EMPTY") end
		end
	end
	return slotsFound
end


function JobSchedule:GetBestAvailableInfomercial(hour)
	-- fetch all contracts still available at that time
	-- (assume "all planned" to be run successful then - which
	--  means the contract is gone then)
	local availableInfomercialLicences = self.ScheduleTask:GetAvailableContractsList(hour, false, true)

	-- sort by PerViewerRevenue and quality (because of attactivity/topicality)
	local sortMethod = function(a, b)
		return a.GetPerViewerRevenue() * a.GetQuality() > b.GetPerViewerRevenue() * b.GetQuality()
	end

	table.sort(availableInfomercialLicences, sortMethod)

	if table.count(availableInfomercialLicences) > 0 then
		return table.first(availableInfomercialLicences)
	end
	return nil
end


function JobSchedule:OptimizeAdSchedule()
	debugMsg("OptimizeAdSchedule()")

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

	-- do not send more than X trailers a day
	-- if reaching that limit, keep sending "low requirement" ad spots
	local totalTrailerCount = self.ScheduleTask.EmergencyScheduleJob:GetTrailerCount(currentDay)
	local totalTrailerMax = 6
	local placedTrailerCount = 0 

	for i = currentHour, currentHour + 12 do
		fixedDay, fixedHour = self.ScheduleTask:FixDayAndHour(currentDay, i)

		-- increase trailer rate during night
		local replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRateDay
		if (fixedHour >= 1 and fixedHour <= 7) then
			replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRateNight
		elseif (fixedHour >= 19 and fixedHour <= 23) then
			replaceBadAdsWithTrailerRate = replaceBadAdsWithTrailerRatePrimeTime
		end
		-- without programme, we cannot send trailers
		if TVT.of_getProgrammeLicenceCount() <= 1 then replaceBadAdsWithTrailerRate = 0 end


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
		-- a) outage / no ad
		-- b) not satisfiable advertisement
		-- c) replace existing trailer with better one


		-- a)
		-------------
		-- send trailer: if nothing is send
		-- ignore trailer limit here
		if (currentBroadcastMaterial == nil) then
			sendTrailerReason = "no ad"
			sendTrailer = true

		-- b)
		-------------
		-- send trailer: if a planned advertisement is not satisfiable
		-- take care of trailer limit!
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
			if totalTrailerCount < totalTrailerMax then
				local adContract = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
				if (previousProgramme ~= nil and adContract ~= nil) then
					if guessedAudience < adContract.GetMinAudience() then
						sendTrailerReason = "unsatisfiable ad (aud "..math.floor(guessedAudience) .. "  <  minAud " .. adContract.GetMinAudience() .. ")"
						sendTrailer = true
					end
				end
			end

		-- c)
		-------------
		-- send trailer: if there is a better one available?
		-- ignore trailer limit here (replacing trailer with trailer)
		elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1) then
			local upcomingProgrammesLicences = self.ScheduleTask:GetUpcomingProgrammesLicenceList()
			local licenceID = currentBroadcastMaterial.GetReferenceID()
			-- is the trailer of the past?
			if (not self.ScheduleTask:GetBroadcastSourceFromTable(licenceID, upcomingProgrammesLicences)) then
				-- is there something planned in the future?
				if (table.count(upcomingProgrammesLicences) > 0) then 
					sendTrailerReason = "better trailer (of upcoming programme)"
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
		-- if we do not have any programme, allow every audience factor...
		if TVT.of_getProgrammeLicenceCount() <= 1 then minAudienceFactor = 0 end

		local betterAdContractList = self.ScheduleTask.EmergencyScheduleJob:GetMatchingSpotList(guessedAudience, minAudienceFactor, false, false)
		if (table.count(betterAdContractList) > 0) then
			local oldAdContract
			local oldMinAudience = 0
			if (currentBroadcastMaterial ~= nil and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
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
				--if the old ad would not get satisfied, it does not cover anything 
				if oldAudienceCoverage > 1 then oldAudienceCoverage = -1 end
			end
			local audienceCoverageIncrease = newAudienceCoverage - oldAudienceCoverage

			-- if new spot only covers <x% of guessed Audience, do not place
			-- an ad, better place a trailer
			-- replace "minAudience=0"-spots with trailers!
			if (newAudienceCoverage > replaceBadAdsWithTrailerRate) then
				-- only different spots - and when audience requirement is at better
				if (newAdContract ~= oldAdContract and audienceCoverageIncrease > 0) then
					choosenBroadcastSource = newAdContract
					choosenBroadcastLog = "Set ad (optimized): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. newAdContract.GetTitle() .. " [" .. newAdContract.GetID() .."]  MinAud: " .. newAdContract.GetMinAudience() .. " (vorher: " .. oldMinAudience .. ")"
					sendTrailer = false
				end
			else
				-- only place a trailer, if previous is an advertisement
				-- take care of trailer limit here
				if (oldSpot ~= nil and totalTrailerCount < totalTrailerMax) then
					sendTrailerReason = "new ad below ReplaceWithTrailerRate"
					sendTrailer = true
				end
			end

			-- no ad contract found but having an old one?
			if (choosenBroadcastSource == nil and oldAdContract ~= nil) then
				sendAd = false
				sendTrailer = false
				choosenBroadcastSource = oldAdContract
				--debugMsg("Belasse alten Werbespot: " .. fixedDay .. "/" ..fixedHour .. ":55  " .. oldAdContract.GetTitle())
			end
		end


		-- avoid outage and set to send a trailer in all cases
		if (choosenBroadcastSource == nil and currentBroadcastMaterial == nil and sendTrailer ~= true) then
			sendTrailer = true
			sendTrailerReason = "avoid outage"
		end
		

		-- send a trailer
		-- ==============
		if (sendTrailer == true) then
			local upcomingProgrammesLicences = self.ScheduleTask:GetUpcomingProgrammesLicenceList()

			local oldTrailer
			if (currentBroadcastMaterial ~= nil and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1) then
				oldTrailer = TVT.of_getProgrammeLicenceByID( currentBroadcastMaterial.GetReferenceID() )
			end

			-- old trailer no longer promoting upcoming programme?
			local reuseOldTrailer = false
			if (oldTrailer ~= nil) then
				reuseOldTrailer = true
				--not in the upcoming list?
				if (self.ScheduleTask:GetBroadcastSourceFromTable(oldTrailer.GetID(), upcomingProgrammesLicences) ~= nil) then
					reuseOldTrailer = false
				end
			end

			if (reuseOldTrailer == false) then 
				-- look for upcoming programmes
				if (table.count(upcomingProgrammesLicences) == 0) then
					-- nothing found: use a random one (if possible)
					if TVT.of_getProgrammeLicenceCount() > 0 then
						local choosenLicence = TVT.of_getProgrammeLicenceAtIndex( math.random(0, TVT.of_getProgrammeLicenceCount()-1) )
						if choosenLicence.IsNewBroadcastPossible() then
							upcomingProgrammesLicences = { choosenLicence }
						end
					end
				end

				if (table.count(upcomingProgrammesLicences) > 0) then
					local choosenLicence = upcomingProgrammesLicences[ math.random( #upcomingProgrammesLicences ) ]
					if (choosenLicence ~= nil) then
						choosenBroadcastSource = choosenLicence
						choosenBroadcastLog = "Set trailer: " .. fixedDay .. "/" .. fixedHour .. ":55  " .. choosenLicence.GetTitle() .. "  Reason: " .. sendTrailerReason
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
			if TVT.of_getAdContractCount() > 0 then
				choosenBroadcastSource = TVT.of_getAdContractAtIndex( math.random(0, TVT.of_getAdContractCount()-1) )
				choosenBroadcastLog = "Set ad (no alternative): " .. fixedDay .. "/" .. fixedHour .. ":55  " .. choosenBroadcastSource.GetTitle() .. " [" ..choosenBroadcastSource.GetID() .."]  MinAud: " .. choosenBroadcastSource.GetMinAudience()
			end
		end


		-- set new material
		-- ================
		if (choosenBroadcastSource ~= nil) then
			local result = TVT.of_setAdvertisementSlot(choosenBroadcastSource, fixedDay, fixedHour)
			if (result > 0) then
				debugMsg(choosenBroadcastLog)
			end
		end

		-- refresh trailer count for next hour
		totalTrailerCount = self.ScheduleTask.EmergencyScheduleJob:GetTrailerCount(currentDay)
	end
end



function JobSchedule:OptimizeProgrammeSchedule()
	debugMsg("OptimizeProgrammeSchedule()")

	-- a) replace infomercials with programme during primetime
	-- b) replace infomercials with ones providing higher income
	-- c) replace infomercials with "potentially obsolete contracts then
	local fixedDay, fixedHour = 0
	local currentDay = WorldTime.GetDay()
	local currentHour = WorldTime.GetDayHour()

	local i = currentHour
	local hasToOptimizePlan = 5 -- how many times to try

	while hasToOptimizePlan > 0 do
		while i <= currentHour + 12 do
			fixedDay, fixedHour = FixDayAndHour(currentDay, i)

			local choosenBroadcastSource = nil
			local choosenBroadcastLog = ""
			local currentBroadcastMaterial = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
			local sendInfomercial = false
			local sendInfomercialReason = ""
			local sendProgramme = true
			local sendProgrammeReason = ""

			local previousBroadcastMaterial = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour - 1)
			local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedDay, fixedHour, previousBroadcastMaterial)

			-- fetch best possible infomercial for that hour
			local bestInfomercial = self:GetBestAvailableInfomercial(i - currentHour)

			-- send an infomercial:
			-- ===============
			-- (to avoid outages ... later stages might set an programme
			--  instead)
			
			-- send infomercial: if nothing is send
			if (currentBroadcastMaterial == nil) then
				--debugMsg("OptimizeProgrammeSchedule: EMPTY slot " .. fixedDay.."/"..fixedHour..":05")
				sendInfomercialReason = "nothing to send yet"
				-- mark hour to be replaceable with a normal programme
				sendProgramme = true
				sendInfomercial = true
			-- send infomercial: if there might be a better one available?
			elseif (currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
				--debugMsg("OptimizeProgrammeSchedule: INFOMCERIAL slot " .. fixedDay.."/"..fixedHour..":05")
				sendInfomercial = true
			end


			-- find better suiting programme
			-- =============================
			-- during primetime, send programme at up to all cost?
			-- TODO


			-- place best fitting infomercial
			if sendInfomercial == true then
				local oldInfomercial = nil
				if (currentBroadcastMaterial ~= nil and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.ADVERTISEMENT) == 1) then
					oldInfomercial = TVT.of_getAdContractByID( currentBroadcastMaterial.GetReferenceID() )
				end

				-- have to send infomercial, but do not have one yet?
				if oldInfomercial == nil and bestInfomercial ~= nil then
					choosenBroadcastSource = bestInfomercial
					choosenBroadcastLog = "Set infomercial (outage): " .. fixedDay .. "/" .. fixedHour .. ":55  \"" .. bestInfomercial.GetTitle() .. "\" [" .. bestInfomercial.GetID() .."]  CPM: " .. bestInfomercial.GetPerViewerRevenue()

					sendInfomercial = false
				-- having already none, but the other one is better
				elseif oldInfomercial ~= nil and bestInfomercial ~= nil then
					choosenBroadcastSource = bestInfomercial
					choosenBroadcastLog = "Set infomercial (optimized): " .. fixedDay .. "/" .. fixedHour .. ":55 \"" .. bestInfomercial.GetTitle() .. "\" [" .. bestInfomercial.GetID() .."]  CPM:" .. bestInfomercial.GetPerViewerRevenue() .."  (previous: \"" .. oldInfomercial.GetTitle() .. "\"  CPM:" .. oldInfomercial.GetPerViewerRevenue() ..")"

					sendInfomercial = false
				end

				-- no new infomercial assigned, keep the old one
				if (choosenBroadcastSource == nil and oldInfomercial ~= nil) then
					choosenBroadcastSource = oldInfomercial
					choosenBroadcastLog = "Keep infomercial: " .. fixedDay .. "/" .. fixedHour .. ":55 \"" .. oldInfomercial.GetTitle() .. "\" [" .. oldInfomercial.GetID() .."]  CPM:" .. oldInfomercial.GetPerViewerRevenue() .."  (previous: \"" .. oldInfomercial.GetTitle() .. "\"  CPM:" .. oldInfomercial.GetPerViewerRevenue() ..")"
					--debugMsg("Keep old infomercial: " .. fixedDay .. "/" ..fixedHour .. ":55  \"" .. oldInfomercial.GetTitle().."\"")

					sendInfomercial = false
				end
			end


			-- send a programme
			-- ================
			-- only send something if there is no other real programme at
			-- that slot already
			if (sendProgramme == true) then
				local sendNewProgramme = true
				sendProgrammeReason = "Daytime"

				if currentBroadcastMaterial ~= nil and currentBroadcastMaterial.isType(TVT.Constants.BroadcastMaterialType.PROGRAMME) == 1 then
					--debugMsg("OptimizeProgrammeSchedule: PROGRAMME slot " .. fixedDay.."/"..fixedHour..":05")

					sendNewProgramme = false

					-- avoid running the same programme each after another
					if previousBroadcastMaterial ~= nil and previousBroadcastMaterial.GetSource() == currentBroadcastMaterial.GetSource() then
						sendNewProgramme = true
						sendProgrammeReason = "Avoid duplicate" 
					end

					-- avoid running the same programme too often a day
					if sendNewProgramme == false then
						local sentAndPlannedToday = TVT.of_GetBroadcastMaterialInProgrammePlanCount(currentBroadcastMaterial.GetReferenceID(), fixedDay, 1)
						if sentAndPlannedToday >= 3 and TVT.of_getProgrammeLicenceCount() >= 3 then
							sendNewProgramme = true
							sendProgrammeReason = "Run too often: "..sentAndPlannedToday
						end
					end
				end

				if sendNewProgramme == true then
					if (fixedHour >= 9 or fixedHour <= 1) then
						local broadcastSource = self.ScheduleTask:GetMovieOrInfomercialForBlock(fixedDay, fixedHour)
						--convert source to material so we know the type
						--as we are only interested in programmes here
						if broadcastSource ~= nil then 
							local broadcastMaterialType = MY.GetProgrammeCollection().GetBroadcastMaterialType(broadcastSource)
							if broadcastMaterialType == TVT.Constants.BroadcastMaterialType.PROGRAMME then
								choosenBroadcastSource = broadcastSource
								choosenBroadcastLog = "Set programme licence: " .. fixedDay .. "/" .. fixedHour .. ":05. Title: \"" .. broadcastSource.GetTitle() .. "\"  Reason: " .. sendProgrammeReason
							end
						end
					end
				end
			end


			-- nothing valid found? Fall back to infomercial
			if (currentBroadcastMaterial == nil and choosenBroadcastSource == nil) then
				if bestInfomercial ~= nil then
					debugMsg("OptimizeProgrammeSchedule: Fall back to infomercial \"" .. choosenBroadcastSource.GetTitle() .. "\" for "..fixedDay .."/" .. fixedHour .. ":05. Already placed")
					choosenBroadcastSource = bestInfomercial
					choosenBroadcastLog = "Set infomercial (emergency): " .. fixedDay .. "/" .. fixedHour .. ":55  \"" .. bestInfomercial.GetTitle() .. "\" [" .. bestInfomercial.GetID() .."]  CPM: " .. bestInfomercial.GetPerViewerRevenue()
				else
					debugMsg("OptimizeProgrammeSchedule: Fall back to infomercial not possible for "..fixedDay .."/" .. fixedHour .. ":05. NO best infomercial availe")
				end
			else
				--debugMsg("OptimizeProgrammeSchedule: Found something existing or new for "..fixedDay .."/" .. fixedHour .. ":05")
			end


			-- set new material
			-- ================
			if (choosenBroadcastSource ~= nil) then
				--debugMsg("OptimizeProgrammeSchedule: Placing broadcast \"" .. choosenBroadcastSource.GetTitle() .. "\" source for "..fixedDay .."/" .. fixedHour .. ":05")
				-- skip placement if nothing changes
				if (currentBroadcastMaterial ~= nil and currentBroadcastMaterial.HasSource(choosenBroadcastSource) == 1) then
					-- already having it
					--debugMsg("OptimizeProgrammeSchedule: Skip placing broadcast \"" .. choosenBroadcastSource.GetTitle() .. "\" source for "..fixedDay .."/" .. fixedHour .. ":05. Already placed")
				else
					local result = TVT.of_setProgrammeSlot(choosenBroadcastSource, fixedDay, fixedHour)
					if (result > 0) then
						debugMsg(choosenBroadcastLog)
						-- skip other now occupied slots
						local response = TVT.of_getProgrammeSlot(fixedDay, fixedHour)
						if ((response.result ~= TVT.RESULT_WRONGROOM) and (response.result ~= TVT.RESULT_NOTFOUND)) then
							i = i + response.data.GetBlocks() - 1

							currentBroadcastMaterial = response.data
						end
					else
						local response = TVT.of_getProgrammeSlot(fixedDay, fixedHour)
						local mat = response.data
						debugMsg("OptimizeProgrammeSchedule: Failed to PLACE broadcast \"" .. choosenBroadcastSource.GetTitle() .. "\" source for "..fixedDay .."/" .. fixedHour .. ":05.")
						if mat ~= nil then
							debugMsg("   " .. mat.GetTitle() .. "   ref=" .. mat.GetReferenceID() .."   curr=" .. currentBroadcastMaterial.GetReferenceID() .. "  choosen="..choosenBroadcastSource.GetID())
						elseif currentBroadcastMaterial then
							debugMsg("   ---   ref= /    curr=" .. currentBroadcastMaterial.GetReferenceID())
						else
							debugMsg("   ---   ref= /    curr= /")
						end
					end
				end
			elseif (currentBroadcastMaterial == nil) then
				debugMsg("OptimizeProgrammeSchedule: Failed to find a broadcast source for "..fixedDay .."/" .. fixedHour .. ":05.")
			end

			--move to next hour
			i = i + 1
		end

		-- still outages left? repeat process, if possible
		if hasToOptimizePlan > 0 then 
			if self:GetUsedSlotsCount(currentDay, currentHour, 12) == 12 then
				hasToOptimizePlan = 0
			else
				debugMsg("OptimizeProgrammeSchedule: NOT all slots used." .. self:GetUsedSlotsCount(currentDay, currentHour, 12, true))
			end

			if TVT.GetAdContractCount() == 0 and TVT.GetProgrammeLicenceCount() == 0 then
				debugMsg("OptimizeProgrammeSchedule: Cannot fill outage slots, no licences or adcontracts available.")
				hasToOptimizePlan = 0
			end
		end

		hasToOptimizePlan = hasToOptimizePlan - 1
	end
end

function JobSchedule:Tick()
	--debugMsg("JobSchedule:Tick()  " .. WorldTime.GetDayHour()..":"..WorldTime.GetDayMinute())

	--optimize existing schedule
	--==========================

	self:OptimizeProgrammeSchedule()
	self:OptimizeAdSchedule()


	--only tick one time
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<