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

--Mögliche Probleme:
--GetPreviousContractCountById vergleicht nur den Namen des Contracts. Es kann also sein, dass ein Contract der vor mehreren Tagen schon mal gesendet wurde da mit reingerechnet wird.

function TaskSchedule:typename()
	return "TaskSchedule"
end

function TaskSchedule:Activate()
	-- Was getan werden soll:
	self.AnalyzeScheduleJob = JobAnalyzeSchedule()
	self.AnalyzeScheduleJob.ScheduleTask = self

	self.FulfillRequisitionJob = JobFulfillRequisition()
	self.FulfillRequisitionJob.ScheduleTask = self

	self.EmergencySchuduleJob = JobEmergencySchedule()
	self.EmergencySchuduleJob.ScheduleTask = self

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
	elseif (self.EmergencySchuduleJob.Status ~= JOB_STATUS_DONE) then
		return self.EmergencySchuduleJob
	elseif (self.ScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ScheduleJob
	end

	self:SetWait()
end

function TaskSchedule:GetMaxAudiencePercentageByHour(hour)
-- neue Fassung...
-- Eventuell mit ein wenig "Unsicherheit" versehen (schon in Blitzmax)
	return TVT.getPotentialAudiencePercentageForHour(hour)

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

-- Berechnet die Vermutung wie viel Zuschauer wohl zu dieser Stunde wohl erreicht werden können
function TaskSchedule:GuessedAudienceForHourAndLevel(hour)
	local level = self:GetQualityLevel(hour) --Welchen Qualitätslevel sollte ein Film/Werbung um diese Uhrzeit haben
	local globalPercentageByHour = self:GetMaxAudiencePercentageByHour(hour) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
	local averageMovieQualityByLevel = self:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels

	--Formel: Filmqualität * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	--TODO: Auchtung! Muss eventuell an die neue Quotenberechnung angepasst werden
	local guessedAudience = averageMovieQualityByLevel * globalPercentageByHour * MY.GetMaxAudience()
	--debugMsg("GuessedAudienceForHourAndLevel - Hour: " .. hour .. "  Level: " .. level .. "  globalPercentageByHour: " .. globalPercentageByHour .. "  averageMovieQualityByLevel: " .. averageMovieQualityByLevel .. "  guessedAudience: " .. guessedAudience)
	return guessedAudience
end

function TaskSchedule:GetQualityLevel(hour)
	local maxAudience = self:GetMaxAudiencePercentageByHour(hour)
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

TVT.printOut("Erhöhe Bedarf an Spots des Levels " .. level .. " (Audience: " .. guessedAudience .. ") für Sendeplatz " .. day .. "/" .. hour .. ":55")

	-- increase priority if guessedAudience/level is requested again
--	debugMsg("Erhöhe Bedarf an Spots des Levels " .. level .. " (Audience: " .. guessedAudience .. ") für Sendeplatz " .. day .. "/" .. hour .. ":55")
	for k,v in pairs(self.SpotRequisition) do
		if (v.Level == level and v.GuessedAudience <= guessedAudience) then
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

			debugMsg("Setze Werbung in Programmplan: " .. value.Day .. "/" .. value.Hour .. " = " .. value.ContractId)
			if (value.Day > gameDay or (value.Day == gameDay and value.Hour > gameHour) or (value.Day == gameDay and value.Hour == gameHour and value.Minute > gameMinute)) then
				local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(value.ContractId), value.Day, value.Hour) --Setzt den neuen Eintrag
				if (result < 0) then debugMsg("###### ERROR 2: " .. value.Day .. "/" .. value.Hour .. ":55  contractID:" .. value.ContractId .. "   Result: " .. result) end
			else
				debugMsg("Zu spät dran:   geplant:" .. value.Day .. "/" .. value.Hour .. ":" .. value.Minute .. "  Zeit:" .. gameHour .. ":" .. gameMinute .. "  contractID:" .. value.ContractId)
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
TVT.printOut("JobEmergencySchedule:Tick() : Luecke gefunden...fuelle " .. self.SlotsToCheck .. " Luecken auf.")
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
		fixedDay, fixedHour = self:FixDayAndHour(currentDay, i)
		local programme = MY.GetProgrammePlan().GetProgramme(fixedDay, fixedHour)
		if (programme == nil) then
			--debugMsg("CheckEmergencyCase: Programme - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self:FixDayAndHour(currentDay, i)
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
		fixedDay, fixedHour = self:FixDayAndHour(currentDay, i)
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
	local fixedDay, fixedHour = self:FixDayAndHour(day, hour)
	local level = self.ScheduleTask:GetQualityLevel(fixedHour)
	local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedHour)
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
		debugMsg("Setze Dringlichkeits-Spot: " .. choosenSpot.GetTitle() .. " (Tag: " ..fixedDay .. "  Zeit: " .. fixedHour .. ":55  MinAud: " .. choosenSpot.GetMinAudience() .. ")")
		local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(choosenSpot.GetID()), fixedDay, fixedHour)
	else
		local sentTrailer = false
		-- send a trailer if we do not have an ad?
		local upcomingProgrammesLicences = self:GetUpcomingProgrammesLicenceList(false)
		if (table.count(upcomingProgrammesLicences) == 0) then
			upcomingProgrammesLicences = self:GetUpcomingProgrammesLicenceList(true)
		end
		if (table.count(upcomingProgrammesLicences) > 0) then
			local choosenLicence = upcomingProgrammesLicences[ math.random( #upcomingProgrammesLicences ) ]
			--local choosenLicence = table.first(upcomingProgrammesLicences)

			if (choosenLicence ~= nil) then
				local result = TVT.of_setAdvertisementSlot(choosenLicence, fixedDay, fixedHour)
				if (result > 0) then
					sentTrailer = True
				end
			end
		else
			TVT.printOut("no upcoming programme to send trailers for")
		end

		-- trailer not possible, send a normal add (ignoring needs)
		if (sentTrailer == false) then
			--nochmal ohne Filter!
			choosenSpot = self:GetBestMatchingSpot(currentSpotList)
			if (choosenSpot ~= nil) then
				debugMsg("Setze Dringlichkeits-Spot - ungefiltert! Tag: " .. fixedDay .. "  Zeit:" .. fixedHour .. ":55  Name: " .. choosenSpot.GetTitle())
				local result = TVT.of_setAdvertisementSlot(TVT.of_getAdContractByID(choosenSpot.GetID()), fixedDay, fixedHour)
			else
				debugMsg("Keinen Dringlichkeits-Spot gefunden! Tag: " .. fixedDay .. " Zeit: " .. fixedHour .. ":55")
			end
		end
	end
end

function JobEmergencySchedule:SetMovieOrInfomercialToEmptyBlock(day, hour)
	local fixedDay, fixedHour = self:FixDayAndHour(day, hour)

	local level = self.ScheduleTask:GetQualityLevel(fixedHour)
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
	if (table.count(licenceList) == 0) then licenceList = self:GetFilteredProgrammeLicenceList(level+2, 1, 1, fixedDay) end
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
		debugMsg("Setze Film! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour .. " Lizenz: " .. choosenLicence.GetTitle() .. "  quality: " .. choosenLicence.GetQuality())
		TVT.of_setProgrammeSlot(choosenLicence, fixedDay, fixedHour)
	else
		debugMsg("Keinen Film gefunden! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour)
	end
end

function JobEmergencySchedule:GetFilteredProgrammeLicenceList(maxLevel, level, maxRerunsToday, day)
	for i = maxLevel,level,-1 do
		programmeList = self:GetProgrammeLicenceList(i, maxRerunsToday, day)
		if (table.count(programmeList) > 0) then
			debugMsg("GetFilteredProgrammeLicenceList: maxLevel: " .. maxLevel .. "   level: " .. level .. "   maxRerunsToday: " .. maxRerunsToday .. " currLevel: " .. i)
			break
		end
	end
	return programmeList
end

function JobEmergencySchedule:GetProgrammeLicenceList(level, maxRerunsToday, day)
	local currentLicenceList = {}

	for i=0,MY.GetProgrammeCollection().GetProgrammeLicenceCount()-1 do
		local licence = MY.GetProgrammeCollection().GetProgrammeLicenceAtIndex(i)
		if ( licence ~= nil) then
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

function JobEmergencySchedule:GetUpcomingProgrammesLicenceList(checkPastToo)
	local currentLicenceList = {}
	local day = WorldTime.GetDay()
	local hour = WorldTime.GetHour()

	if (checkPastToo ~= true) then
		checkPastToo = false
	end

	--fetch all upcoming objects, last param = true, so only programmes
	--are returned, no infomercials
--	local plannedProgrammes = TVT.of_GetBroadcastMaterialInTimeSpan(TVT.Constants.BroadcastMaterialType.PROGRAMME, day, 0, day+1, 23, false, true)
	local response
	if (checkPastToo == true) then
		response = TVT.of_GetBroadcastMaterialInTimeSpan(TVT.Constants.BroadcastMaterialType.PROGRAMME, day, 0, day+1, 23, false, true)
	else
		response = TVT.of_GetBroadcastMaterialInTimeSpan(TVT.Constants.BroadcastMaterialType.PROGRAMME, day, hour, day+1, 23, false, true)
	end
	--if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
	--	plannedProgrammes = {}
	--else
	--	plannedProgrammes = response.DataArray()
	--end
	plannedProgrammes = response.DataArray()

	for i, broadcastMaterial in ipairs(plannedProgrammes) do
		local licence = MY.GetProgrammeCollection().GetProgrammeLicence(broadcastMaterial.GetReferenceID())
		if (licence ~= nil) then
			table.insert(currentLicenceList, licence)
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
		local minAudience = contract.GetMinAudience()

		--only add contracts
		if (contract ~= nil) then
			--debugMsg("GetMatchingSpotList - MinAud: " .. minAudience .. " < " .. guessedAudience)
			if ((minAudience < guessedAudience) and (minAudience > guessedAudience * minFactor)) or noAudienceRestrictions then
				local count = MY.GetProgrammePlan().GetAdvertisementsSent(contract, -1, 23, 1)
				--debugMsg("GetMatchingSpotList: " .. contract.title .. " - " .. count)
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

function JobEmergencySchedule:FixDayAndHour(day, hour)
	local moduloHour = hour
	if (hour > 23) then
		moduloHour = hour % 24
	end
	local newDay = day + (hour - moduloHour) / 24
	return newDay, moduloHour
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
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<