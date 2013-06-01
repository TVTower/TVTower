-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskSchedule = AITask:new{
	TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME;
	BudgetWeigth = 0;
	BasePriority = 10;
	TodayMovieSchedule = {};
	TomorrowMovieSchedule = {};
	TodaySpotSchedule = {};
	TomorrowSpotSchedule = {};
	SpotInventory = {};
}

--Mögliche Probleme:
--GetPreviousContractCountById vergleicht nur den Namen des Contracts. Es kann also sein, dass ein Contract der vor mehreren Tagen schon mal gesendet wurde da mit reingerechnet wird.

function TaskSchedule:typename()
	return "TaskSchedule"
end

function TaskSchedule:Activate()
	debugMsg(">>> Starte Task 'TaskSchedule'")
	-- Was getan werden soll:
	self.AnalyzeScheduleJob = JobAnalyzeSchedule:new()
	self.AnalyzeScheduleJob.ScheduleTask = self

	self.EmergencySchuduleJob = JobEmergencySchedule:new()
	self.EmergencySchuduleJob.ScheduleTask = self

	self.ScheduleJob = JobSchedule:new()
	self.ScheduleJob.ScheduleTask = self
end

function TaskSchedule:GetNextJobInTargetRoom()
	--debugMsg("GetNextJobInTargetRoomX")
	if (self.AnalyzeScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyzeScheduleJob
	elseif (self.EmergencySchuduleJob.Status ~= JOB_STATUS_DONE) then
		return self.EmergencySchuduleJob
	elseif (self.ScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ScheduleJob
	end
	
	self:SetDone()
end

function TaskSchedule:GetMaxAudiencePercentageByHour(hour)
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
end

-- Berechnet die Vermutung wie viel Zuschauer wohl zu dieser Stunde wohl erreicht werden können
function TaskSchedule:GuessedAudienceForHourAndLevel(hour)
	local level = self:GetQualityLevel(hour) --Welchen Qualitätslevel sollte ein Film/Werbung um diese Uhrzeit haben
	local globalPercentageByHour = self:GetMaxAudiencePercentageByHour(hour) -- Die Maximalquote: Entspricht ungefähr "maxAudiencePercentage"
	local averageMovieQualityByLevel = self:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualitätslevels

	--Formel: Filmqualität * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	local guessedAudience = averageMovieQualityByLevel * globalPercentageByHour * MY.GetMaxAudience()
	return guessedAudience
end

function TaskSchedule:GetQualityLevel(hour)
	local maxAudience = self:GetMaxAudiencePercentageByHour(hour)
	if (maxAudience <= 5) then
		return 1 --Nachtprogramm
	elseif (maxAudience <= 10) then
		return 2 --Mitternacht + Morgen
	elseif (maxAudience <= 15) then
		return 3 -- Nachmittag
	elseif (maxAudience <= 25) then
		return 4 -- Vorabend / Spät
	else
		return 5 -- Primetime
	end
end

--TODO später dynamisieren
function TaskSchedule:GetAverageMovieQualityByLevel(level)
	if (level == 1) then
		return 3 --Nachtprogramm
	elseif (level == 2) then
		return 8 --Mitternacht + Morgen
	elseif (level == 3) then
		return 13 -- Nachmittag
	elseif (level == 4) then
		return 18 -- Vorabend / Spät
	elseif (level == 5) then
		return 22 -- Primetime
	end
end

--function TaskSchedule:GetMovieByLevel
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobAnalyzeSchedule = AIJob:new{
	ScheduleTask = nil;
	Step = 1
}

function JobAnalyzeSchedule:Prepare(pParams)
	debugMsg("Analysiere Programmplan")
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
JobEmergencySchedule = AIJob:new{
	ScheduleTask = nil,
	SlotsToCheck = 8, --4,
	testCase = 0
}

function JobEmergencySchedule:Prepare(pParams)
	debugMsg("Prüfe ob dringende Programm- und Werbeplanungen notwendig sind")
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

function JobEmergencySchedule:CheckEmergencyCase(howManyHours, day, hour)
	local fixedDay, fixedHour = 0
	local currentDay = day
	local currentHour = hour
	if (currentDay == nil) then currentDay = TVT:Day() end
	if (currentHour == nil) then currentHour = TVT:Hour() end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self:FixDayAndHour(currentDay, i)
		local programme = MY.ProgrammePlan.GetActualProgramme(fixedHour, fixedDay)
		if (programme == nil) then
			--debugMsg("CheckEmergencyCase: Programme - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self:FixDayAndHour(currentDay, i)
		local adblock = MY.ProgrammePlan.GetActualAdBlock(fixedHour, fixedDay)
		if (adblock == nil) then
			--debugMsg("CheckEmergencyCase: Adblock - " .. fixedHour .. " / " .. fixedDay)
			return true
		end
	end

	return false
end

function JobEmergencySchedule:FillIntervals(howManyHours)
	--Aufgabe: So schnell wie möglich die Lücken füllen
	--Zuschauerberechnung: ZuschauerquoteAufGrundderStunde * Programmquali * MaximalzuschauerproSpieler

	local fixedDay, fixedHour = 0
	local currentDay = TVT:Day()
	local currentHour = TVT:Hour()

	for i = currentHour, currentHour + howManyHours do
		fixedDay, fixedHour = self:FixDayAndHour(currentDay, i)
		--debugMsg("FillIntervals --- Tag: " .. fixedDay .. " - Stunde: " .. fixedHour)

		--Werbung: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local adblock = MY.ProgrammePlan.GetActualAdBlock(fixedHour, fixedDay)
		if (adblock == nil) then
			self:SetContractToEmptyBlock(fixedDay, fixedHour)
		end

		--Film: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local programme = MY.ProgrammePlan.GetActualProgramme(fixedHour, fixedDay)
		if (programme == nil) then
			self:SetMovieToEmptyBlock(fixedDay, fixedHour)
		end
	end
end

function JobEmergencySchedule:GetFittingSpotList(guessedAudience, noBroadcastRestrictions)
	local currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.8, false, noBroadcastRestrictions)
	if (table.count(currentSpotList) == 0) then
		currentSpotList = self:GetMatchingSpotList(guessedAudience, 0.6, false, noBroadcastRestrictions)
		if (table.count(currentSpotList) == 0) then
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

function JobEmergencySchedule:SetContractToEmptyBlock(day, hour)
	local fixedDay, fixedHour = self:FixDayAndHour(day, hour)
	--local level = self.ScheduleTask:GetQualityLevel(fixedHour)
	local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(fixedHour)

	local currentSpotList = self:GetFittingSpotList(guessedAudience, false)
	if (table.count(currentSpotList) == 0) then
		--Neue Anfoderung stellen: Passenden Werbevertrag abschließen (für die Zukunft)
		local requisition = SpotRequisition:new()
		requisition.guessedAudience = guessedAudience
		local player = _G["globalPlayer"]
		player:AddRequisition(requisition)
		currentSpotList = self:GetFittingSpotList(guessedAudience, true)
	end

	local filteredCurrentSpotList = self:FilterSpotList(currentSpotList)
	local choosenSpot = self:GetBestMatchingSpot(filteredCurrentSpotList)
	if (choosenSpot ~= nil) then
		debugMsg("Setze Spot! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour .. " Name: " .. choosenSpot.contractBase.title)
		local result = TVT.of_doSpotInPlan(fixedDay, fixedHour, choosenSpot.Id)
	else
		--nochmal ohne Filter!
		choosenSpot = self:GetBestMatchingSpot(currentSpotList)
		if (choosenSpot ~= nil) then
			debugMsg("Setze Spot - ungefiltert! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour .. " Name: " .. choosenSpot.contractBase.title)
			local result = TVT.of_doSpotInPlan(fixedDay, fixedHour, choosenSpot.Id)		
		else
			debugMsg("Keinen Spot gefunden! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour)
		end
	end
end

function JobEmergencySchedule:SetMovieToEmptyBlock(day, hour)
	local fixedDay, fixedHour = self:FixDayAndHour(day, hour)

	local level = self.ScheduleTask:GetQualityLevel(fixedHour)
	local programmeList = nil
	local choosenProgramme = nil
	for i=level,1,-1 do
		programmeList = self:GetProgrammeList(i)
		if (table.count(programmeList) > 0) then
			break
		end
	end

	if (table.count(programmeList) == 0) then
		for i=level,level+2 do
			programmeList = self:GetProgrammeList(i)
			if (table.count(programmeList) > 0) then
				break
			end
		end
	end

	if (table.count(programmeList) == 1) then
		choosenProgramme = table.first(programmeList)
	elseif (table.count(programmeList) > 1) then
		local sortMethod = function(a, b)
			return a.GetAttractiveness() > b.GetAttractiveness()
		end
		table.sort(programmeList, sortMethod)
		choosenProgramme = table.first(programmeList)
	end

	if (choosenProgramme ~= nil) then
		debugMsg("Setze Film! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour .. " Programm: " .. choosenProgramme.title)
		TVT.of_doMovieInPlan(fixedDay, fixedHour, choosenProgramme.Id)
	else
		debugMsg("Keinen Film gefunden! Tag: " .. fixedDay .. " - Stunde: " .. fixedHour)
	end
end

function JobEmergencySchedule:GetProgrammeList(level)
	local currentProgrammeList = {}
	for i=0,MY.ProgrammeCollection.GetProgrammeCount()-1 do
		local programme = MY.ProgrammeCollection.GetProgrammeFromList(i)
		if programme.GetQualityLevel() == level then
			table.insert(currentProgrammeList, programme)
		end
	end
	return currentProgrammeList
end

function JobEmergencySchedule:GetMatchingSpotList(guessedAudience, minFactor, noAudienceRestrictions, noBroadcastRestrictions)
	local currentSpotList = {}
	for i = 0, MY.ProgrammeCollection.GetContractCount() - 1 do
		local contract = MY.ProgrammeCollection.GetContractFromList(i)
		local minAudience = contract.GetMinAudience()
		if ((minAudience < guessedAudience) and (minAudience > guessedAudience * minFactor)) or noAudienceRestrictions then
			local count = MY.ProgrammePlan.GetContractBroadcastCount(contract.id, 1, 1)
			--debugMsg("GetMatchingSpotList: " .. contract.title .. " - " .. count)
			if (count < contract.GetSpotCount() or noBroadcastRestrictions) then
				table.insert(currentSpotList, contract)
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
JobSchedule = AIJob:new{
	ScheduleTask = nil
}

function JobSchedule:Prepare(pParams)
	debugMsg("Schaue Programmplan an")
end

function JobSchedule:Tick()
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<