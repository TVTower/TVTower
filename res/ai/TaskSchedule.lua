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
	
	self.ImperativelySchuduleJob = JobImperativelySchudule:new()
	self.ImperativelySchuduleJob.ScheduleTask = self	
	
	self.ScheduleJob = JobSchedule:new()
	self.ScheduleJob.ScheduleTask = self	
end

function TaskSchedule:GetNextJobInTargetRoom()
	debugMsg("GetNextJobInTargetRoomX")
	if (self.AnalyzeScheduleJob.Status ~= JOB_STATUS_DONE) then
		return self.AnalyzeScheduleJob
	elseif (self.ImperativelySchuduleJob.Status ~= JOB_STATUS_DONE) then
		return self.ImperativelySchuduleJob					
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

function TaskSchedule:GetQualityLevel(hour)
	local maxAudience = self:GetMaxAudiencePerHour(hour)
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

function TaskSchedule:GuessedAudienceForHourAndLevel(hour)
	local level = self:GetQualityLevel(hour)
	local globalPercentageByHour = self:GetMaxAudiencePercentageByHour(hour)		
	local averageProgramQualityByLevel = self:GetAverageQualityByLevel(level)
	
	local guessedAudience = globalPercentageByHour * averageProgramQualityByLevel * TVT.getPlayerMaxAudience()
	return guessedAudience
end

--TODO später dynamisieren
function TaskSchedule:GetAverageQualityByLevel(level)
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
		self:ReadMoviesAndSpots()	
	elseif self.Step == 2 then
		self:InitializeInventory()
	elseif self.Step == 3 then
		self:Analyze()
		self.Status = JOB_STATUS_DONE
	end
	
	self.Step = self.Step + 1
end

function JobAnalyzeSchedule:ReadMoviesAndSpots()
	--TODO: Verlangsamen
	--TODO: Movies und Spots die schon mal geladen wurden muss man nicht nochmal laden
	for i=0,23 do
		local movieId = TVT.of_getMovie(-1, i)
		if (movieId ~= 0) then
			local movie = Movie:new()
			movie:Initialize(movieId)		
			self.ScheduleTask.TodayMovieSchedule[i] = movie		
			debugMsg("A1")
		end
	end

	for i=0,23 do
		local spotId = TVT.of_getSpot(-1, i)
		if (spotId ~= 0) then
			local spot = Spot:new()
			spot:Initialize(spotId)
			self.ScheduleTask.TodaySpotSchedule[i] = spot		
			debugMsg("A2")
		end
	end
end

function JobAnalyzeSchedule:InitializeInventory()
	for i=0,TVT.of_getPlayerSpotCount() do
		local spotId = TVT.of_getPlayerSpot(i)
		if (spotId ~= 0) then
			local spot = Spot:new()
			spot:Initialize(spotId)
			self.ScheduleTask.SpotInventory[spotId] = spot
			debugMsg("A3")
		end
	end

	for i=0,TVT.of_getPlayerSpotCount() do
		local spotId = TVT.of_getPlayerSpot(i)
		if (spotId ~= 0) then
			local spot = Spot:new()
			spot:Initialize(spotId)
			self.ScheduleTask.SpotInventory[spotId] = spot
			debugMsg("A4")
		end
	end			
end

function JobAnalyzeSchedule:Analyze()
	--debugMsg("A1")
	for k,v in pairs(self.ScheduleTask) do
		v:RecalcPriority()
	end
	--debugMsg("A2")
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobImperativelySchudule = AIJob:new{
	ScheduleTask = nil,
	SlotsToCheck = 4,
	CurrentHour = -1
}

function JobImperativelySchudule:Prepare(pParams)
	debugMsg("Prüfe ob dringende Programm- und Werveplanungen notwendig sind")
end

function JobImperativelySchudule:Tick()
	if self:CheckImperatively() then
		self:FillIntervals()
	end
end

function JobImperativelySchudule:CheckImperatively()
	--TODO über Tagesgrenzen hinweg
	self.CurrentHour = TVT:Hour()
	
	for i=self.CurrentHour,self.CurrentHour+self.slotsToCheck do
		local movie = self.ScheduleTask.TodayMovieSchedule[i]
		if (movie == nil) then
			return true
		end
	end
	
	for i=self.CurrentHour,self.CurrentHour+self.slotsToCheck do
		local spot = self.ScheduleTask.TodaySpotSchedule[i]
		if (spot == nil) then
			return true
		end
	end	
end

function JobImperativelySchudule:FillIntervals()	
	--Zuschauerberechnung: ZuschauerquoteAufGrundderStunde * Programmquali * MaximalzuschauerproSpieler

	for i=self.CurrentHour,self.CurrentHour+this.slotsToCheck do
		local level = self:GetQualityLevel(hour)
		local guessedAudience = self.ScheduleTask:GuessedAudienceForHourAndLevel(i)
		
		local currentSpotList = self:GetSpotList(guessedAudience, 0.8)
		if (table.count(currentSpotList) == 0) then
			currentSpotList = self:GetSpotList(guessedAudience, 0.6)
		end
		if (table.count(currentSpotList) == 0) then
			currentSpotList = self:GetSpotList(guessedAudience, 0.4)
		end
		if (table.count(currentSpotList) == 0) then
			currentSpotList = self:GetSpotList(guessedAudience, 0)
		end
		
		currentSpotList = FilterSpotList(currentSpotList)
		self:GetBestMatchingSpot(currentSpotList)
		
		local movie = self.ScheduleTask:GetMovieByLevel(level)
		
		--TVT.getEvaluatedAudienceQuote(i, )
		--
		--player.Stats.
	
		local maxAudience = self.ScheduleTask:GetQualityLevel(i)
	
		local movie = self.ScheduleTask.TodayMovieSchedule[i]
		if (movie == nil) then
			return true
		end
	end
	
	for i=self.CurrentHour,self.CurrentHour+this.slotsToCheck do
		local spot = self.ScheduleTask.TodaySpotSchedule[i]
		if (spot == nil) then
			return true
		end
	end	
end

function JobImperativelySchudule:GetSpotList(guessedAudience, minFactor)
	local currentSpotList = {}
	for k,v in pairs(self.ScheduleTask.SpotInventory) do
		if (v.Audience < guessedAudience) and (v.Audience > guessedAudience * minFactor) then
			currentSpotList[k] = v
		end
	end
	return currentSpotList
end

function JobImperativelySchudule:FilterSpotList(spotList)
	local currentSpotList = {}
	for k,v in pairs(spotList) do
		if v.MinBlocksToday() > 0 then
			currentSpotList[k] = v
		end
	end
	if (table.count(currentSpotList) > 0) then
		return currentSpotList
	else
		return spotList
	end		
end

function JobImperativelySchudule:GetBestMatchingSpot(spotList)
	local bestAcuteness = -1
	local bestSpot = nil

	for k,v in pairs(spotList) do
		if (bestAcuteness < v.Acuteness) then
			bestAcuteness = v.Acuteness
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