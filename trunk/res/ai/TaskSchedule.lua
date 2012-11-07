-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskSchedule = AITask:new{	
	TargetRoom = TVT.ROOM_OFFICE_PLAYER_ME;
	BudgetWeigth = 0;
	TodayMovieSchedule = {};
	TomorrowMovieSchedule = {};
	TodaySpotSchedule = {};
	TomorrowSpotSchedule = {};
	SpotInventory = {};
}

function TaskSchedule:typename()
	return "TaskSchedule"
end

function TaskSchedule:Activate()
	debugMsg("Starte Task 'TaskSchedule'")
	-- Was getan werden soll:
	self.AnalyzeScheduleJob = JobAnalyzeSchedule:new()
	self.AnalyzeScheduleJob.ScheduleTask = self	
	
	self.EmergencySchuduleJob = JobEmergencySchedule:new()
	self.EmergencySchuduleJob.ScheduleTask = self	
	
	self.ScheduleJob = JobSchedule:new()
	self.ScheduleJob.ScheduleTask = self	
end

function TaskSchedule:GetNextJobInTargetRoom()
	debugMsg("GetNextJobInTargetRoomX")
	if (self.AnalyzeScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyzeScheduleJob
	elseif (self.EmergencySchuduleJob.Status ~= JOB_STATUS_DONE) then
		return self.EmergencySchuduleJob					
	elseif (self.ScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ScheduleJob	
	end
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
	CurrentHour = -1
}

function JobEmergencySchedule:Prepare(pParams)
	debugMsg("Prüfe ob dringende Programm- und Werbeplanungen notwendig sind")
end

function JobEmergencySchedule:Tick()
	if self:CheckImperatively() then
		self:FillIntervals()
	end
end

function JobEmergencySchedule:CheckImperatively()
	--TODO über Tagesgrenzen hinweg
	self.CurrentHour = TVT:Hour()
				
	for i=self.CurrentHour,self.CurrentHour+self.SlotsToCheck do
		local programme = MY.ProgrammePlan.GetActualProgramme(i)
		if (programme == nil) then
			return true
		end
	end
	
	for i=self.CurrentHour,self.CurrentHour+self.SlotsToCheck do
		local contract = MY.ProgrammePlan.GetActualContract(i)
		if (adblock == nil) then
			return true
		end
	end	
end

function JobEmergencySchedule:FillIntervals()	
	--Aufgabe: So schnell wie möglich die Lücken füllen
	--Zuschauerberechnung: ZuschauerquoteAufGrundderStunde * Programmquali * MaximalzuschauerproSpieler

	--debugMsg("for: " .. self.CurrentHour .. ", " .. self.CurrentHour+self.SlotsToCheck .. "(" .. self.CurrentHour .. ", " .. self.SlotsToCheck .. ")" )
	for i=self.CurrentHour,self.CurrentHour+self.SlotsToCheck do
		local currentDay = TVT:Day() --Ist eben so im BlitzMaxCode.
		
		--Werbung: Prüfen ob ne Lücke existiert, wenn ja => füllen
		local contract = MY.ProgrammePlan.GetActualContract(i, currentDay)
		if (contract == nil) then			
			self:SetContractToEmptyBlock(currentDay, i)	
		end			
		
		--Film: Prüfen ob ne Lücke existiert, wenn ja => füllen		
		local programme = MY.ProgrammePlan.GetActualProgramme(i, currentDay)
		if (programme == nil) then
			self:SetMovieToEmptyBlock(currentDay, i)
		end		
	end	
end

function JobEmergencySchedule:SetContractToEmptyBlock(day, hour)
	local level = self.ScheduleTask:GetQualityLevel(hour)
	local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(hour)
		
	local currentSpotList = self:GetSpotList(guessedAudience, 0.8)
	if (table.count(currentSpotList) == 0) then
		currentSpotList = self:GetSpotList(guessedAudience, 0.6)
		if (table.count(currentSpotList) == 0) then
			currentSpotList = self:GetSpotList(guessedAudience, 0.4)
			if (table.count(currentSpotList) == 0) then
				currentSpotList = self:GetSpotList(guessedAudience, 0)
			end					
		end		
	end
	
	currentSpotList = self:FilterSpotList(currentSpotList)
	local choosenSpot = self:GetBestMatchingSpot(currentSpotList)
	if (choosenSpot ~= nil) then
		debugMsg("Setze Spot! Tag: " .. day .. " - Stunde: " .. hour .. " Name: " .. choosenSpot.title)
		local result = TVT.of_doSpotInPlan(day, hour, choosenSpot.Id)
	end		
end

function JobEmergencySchedule:SetMovieToEmptyBlock(day, hour)
	local level = self.ScheduleTask:GetQualityLevel(hour)	
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
		debugMsg("Setze Film! Tag: " .. day .. " - Stunde: " .. hour .. " Programm: " .. choosenProgramme.title)
		TVT.of_doMovieInPlan(day, hour, choosenProgramme.Id)
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

function JobEmergencySchedule:GetSpotList(guessedAudience, minFactor)
	local currentSpotList = {}
	for i=0,MY.ProgrammeCollection.GetContractCount()-1 do
		local contract = MY.ProgrammeCollection.GetContractFromList(i)
		local minAudience = contract.GetMinAudience()
		if (minAudience < guessedAudience) and (minAudience > guessedAudience * minFactor) then
			table.insert(currentSpotList, contract)
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
JobSchedule = AIJob:new{
	ScheduleTask = nil
}

function JobSchedule:Prepare(pParams)
	debugMsg("Schaue Programmplan an")
end

function JobSchedule:Tick()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<