
-- ##### HISTORY #####
-- 09.04.2008 Manuel
-- CHG: Die Entscheidungsberechnung für den Kauf eines Filmes befindet sich nun in einem experimentellen Alpha-Stadium. Es sollte nun eigentlich ein Film eingekauft werden,
--           was aber mit der Meldung "Unhandled Memory Exception ErrorDumping profile information" fehlschlägt.
-- 08.04.2008 Manuel
-- FIX: Viele, viele Bugs die den Einkaufablauf von Filmen verhinderten
-- CHG: Die Qualityformel ist jetzt unabhänig von den geschätzten Zuschauerzahlen, diese sind erst bei der Sendeplatzauswahl wichtig
-- CHG: Erweiterung der DecidePurchase-Methode
-- 29.03.2008 Manuel
-- NEW: Filmangebotsüberprüfung (pro Tick überprüft die KI einen Film aus dem Angebot)
-- NEW: Filmqualitätsberechnung
-- NEW: Sender-Niveau-Berechnung (einfache Logik die anhand von Geldstand und Filmangebot bestimmt, welche Niveau ein Film mitbringen muss um z.B. ins Abendprogramm zu kommen )
-- 31.12.2007 Manuel
-- CHG: Debug-Ausgaben sind nun ausschaltbar für eine eventuelle Demo-Version Silverster 2007
-- CHG: Anpassung an das neue Verhalten von OnDayBegins()
-- 20.12.2007 Manuel
-- +++++ V 0.2: Task-, Job- und Geldmanagement sowie Priorisierung grundlgend abgeschlossen
-- NEW: Es sind jetzt fast alle Task-Hüllen drin. Der Spieler läuft schon fleißig durch die Gegend
-- 19.12.2007 Manuel
-- NEW: Task- und Jobverwaltung ausgebaut
-- FIX: self-Variablen-Fix bei der Budgetberechnung
-- 18.12.2007 Manuel
-- NEW: Das nun errechnete Gesamtbudget für den Tag wird jetzt auf die einzelnen Bereiche wie Filmkauf, Senderkauf, Geschenke nach einem Schlüssel usw. aufgeteilt
-- NEW: Die Tasks sorgen nun dafür, dass der Spieler automatisch in den richtigen Raum läuft. Ist dieser erreicht, wird die eigentliche Aufgabe angegangen.
-- FIX: Unzählige Fehler von falschen Methodenaufrufen ohne Doppelpunkt und self-Fehler korrigiert
-- 13.12.2007 Manuel
-- CHG: Budget-Berechnung weiter entwickelt
-- CHG: Integration des SLF (Simple Lua Framework)
-- 10.12.2007 Manuel
-- NEW: Erste Implementierung der Gesamtbudget-Abschätzung
-- 29.11.2007 Manuel
-- +++++ V 0.1: KI-Testphase begonnen

-- ##### ENTSCHEIDUNGEN #####
-- Das Budget nähert sich stetig dem letzttägigen Umsatz an. Der Geldstand hat einen gewissen Einfluss darauf.

-- ##### TASK-START-PRIORITÄT #####
-- MoviePurchase			8
-- MovieAuction			7
-- NewsAgency			8
-- Archive				3
-- AdAgency			8
-- Scheduling			10
-- CheckStations			3
-- BrownnoseBetty			2
-- FinanceBalancing		5

-- ##### INCLUDES #####
dofile("res/ai/SLF.lua")

-- ##### KONSTANTEN #####
APP_VERSION			= "0.3.D"

TASK_MOVIEPURCHASE	= "MoviePurchase"
TASK_NEWSAGENCY		= "NewsAgency"
TASK_ARCHIVE		= "Archive"
TASK_ADAGENCY		= "AdAgency"
TASK_SCHEDULING		= "Scheduling"
TASK_STATIONS		= "Stations"
TASK_BETTY			= "Betty"
TASK_BOSS			= "Boss"


KI_STATUS_RUN		= "run"

JOB_STATUS_NEW		= "new"
JOB_STATUS_REDO		= "redo"
JOB_STATUS_RUN		= "run"
JOB_STATUS_DONE		= "done"

TASK_STATUS_OPEN	= "T_open"
TASK_STATUS_RUN		= "T_run"
TASK_STATUS_DONE	= "T_done"

TODAY_BUDGET		= "T"
OLD_BUDGET_1		= "1"
OLD_BUDGET_2		= "2"
OLD_BUDGET_3		= "3"

PROGRAM_MOVIE		= "movie"
PROGRAM_SERIES		= "series"

PROGRAM_TYPE_DAY	= "day"
PROGRAM_TYPE_EVENING= "evening"
PROGRAM_TYPE_NIGHT	= "night"

-- ##### GLOBALS #####
globalIDCounter = 0
globalBrain = nil
globalMovieManager = nil
globalTemp = 0
globalKIStatus = KI_STATUS_RUN

-- ##### INITIALIZE #####
print("Player " .. ME .. ": Load... Lua-Standard-KI V" .. APP_VERSION .. " - by Manuel Voegele")

-- ##### SINGLETON #####
function getBrain()
	if globalBrain == nil then globalBrain = TVTBrain:new() end
	return globalBrain
end

function getMovieManager()
	if globalMovieManager == nil then globalMovieManager = TVTMovieMagager:new() end
	return globalMovieManager
end

-- ##### KLASSEN #####
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTObjekt = SLFObject:new()			-- Erbt aus dem Basic-Objekt des Frameworks
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTDataObjekt = SLFDataObject:new()	-- Erbt aus dem DataObjekt des Frameworks
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTBudgetManager = TVTDataObjekt:new{
TodayStartWealth = 0;
BudgetMinimum = 0;
BudgetHistory = {};
}

function TVTBudgetManager:typename()
	return "TVTBudgetManager"
end

function TVTBudgetManager:initialize()
	-- Diese Methode simuliert die Werte der vergangenen Tage, da sich die Budgetberechnung auf die vergangenen Tage bezieht
	local playerMoney = TVT.GetPlayerMoney(ME)
	local startBudget = math.round(playerMoney * 0.8)

	self.BudgetHistory = {}
	self.BudgetHistory[OLD_BUDGET_3] = startBudget
	self.BudgetHistory[OLD_BUDGET_2] = startBudget
	self.BudgetHistory[OLD_BUDGET_1] = startBudget
	self.BudgetHistory[TODAY_BUDGET] = startBudget

	self.TodayStartWealth = playerMoney		-- Legt fest, dass man gestern den gleichen Geldstand hatte

	self.BudgetMinimum = math.round(playerMoney / 5)	-- Legt das Budget-Minimum fest
end

function TVTBudgetManager:CalculateBudget()
	-- Diese Methode wird immer zu Beginn des Tages aufgerufen
	self.BudgetHistory[OLD_BUDGET_3] = self.BudgetHistory[OLD_BUDGET_2]
	self.BudgetHistory[OLD_BUDGET_2] = self.BudgetHistory[OLD_BUDGET_1]
	self.BudgetHistory[OLD_BUDGET_1] = self.BudgetHistory[TODAY_BUDGET]

	-- Gestrigte Werte
	local YesterdayBudget = self.BudgetHistory[TODAY_BUDGET]
	local YesterdayWealth = self.TodayStartWealth	-- den gestrigen Wert zwischenspeichern

	-- Aktueller Geldstand
	self.TodayStartWealth = TVT.GetPlayerMoney(ME)

	local YesterdayTurnOver = self.TodayStartWealth - (YesterdayWealth - YesterdayBudget) -- Gestriger Umsatz
	-- TODO: Anstatt dem YesterdayBudget kann man auc die tatsächtlichen gestrigen Ausgaben anführen.

	-- Berechne aktuelles Budget
	local myBudget = self:CalculateAverageBudget(self.TodayStartWealth, YesterdayTurnOver)

	-- Minimal-Budget prüfen
	if myBudget < self.BudgetMinimum then
		myBudget = self.BudgetMinimum
	end

	-- TODO: Kredit ja/nein --- Zurückzahlen ja/nein

	self:AllocateBudgetToTaks(myBudget)

	-- Neuer History-Eintrag
	self.BudgetHistory[TODAY_BUDGET] = myBudget
end

function TVTBudgetManager:CalculateAverageBudget(pCurrentWealth, pTurnOver)
	--SendToChat("A1.1: " .. pTurnOver); SendToChat("AX.1: " .. self.BudgetHistory[OLD_BUDGET_1]); SendToChat("AX.2: " .. self.BudgetHistory[OLD_BUDGET_2]); SendToChat("AX.3: " .. self.BudgetHistory[OLD_BUDGET_3])

	local TempSum = ((pTurnOver * 4) + (self.BudgetHistory[OLD_BUDGET_1] * 3) + (self.BudgetHistory[OLD_BUDGET_2] * 2) + (self.BudgetHistory[OLD_BUDGET_3] * 1)) / 10
	if pCurrentWealth > (TempSum / 2) then
		TempSum = TempSum + (pCurrentWealth * ((math.random(10)-1)/100)) -- TODO: Zufallswert wird durch Level und Risikoreichtum bestimmt
	end
	return math.round(TempSum, -3)
end

function TVTBudgetManager:AllocateBudgetToTaks(pBudget)
	local BudgetUnits = 0

	for k,v in pairs(getBrain().TaskList) do
		BudgetUnits = BudgetUnits + v.BudgetWeigth
	end

	local BudgetUnit = pBudget / BudgetUnits

	for k,v in pairs(getBrain().TaskList) do
		v.Budget = math.round(v.BudgetWeigth * BudgetUnit)
		v.BudgetWholeDay = v.Budget
		--debugMsg(v:typename() .. ": " .. v.Budget)
	end

end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTMovieMagager = TVTDataObjekt:new{
DayMovieMinLimit = nil;
EveningMovieMinLimit = nil;
MovieMaxLimit = nil;
DaySeriesMinLimit = nil;
EveningSeriesMinLimit = nil;
SeriesMaxLimit = nil
}

function TVTMovieMagager:typename()
	return "TVTMovieMagager"
end

function TVTMovieMagager:NiveauCheck(pMovies)
	local MovieBudget = getBrain().TaskList[TASK_MOVIEPURCHASE].BudgetWholeDay
	local maxPrice = MovieBudget / 2;
	local maxQualityMovies = 0;
	local minQualityMovies = 0;
	local maxQualitySeries = 0;
	local minQualitySeries = 0;

	self.MovieMaxLimit = maxPrice
	self.SeriesMaxLimit = maxPrice

	--debugMsg("Anzahl Filme: " .. table.count(pMovies))

	for k,v in pairs(pMovies) do
		if (v.Price <= maxPrice) then -- Preisgrenze
			--debugMsg("im Rahmen: " .. v.Price .. " / " .. maxPrice)
			if (v.ProgramType == PROGRAM_MOVIE) then
				if (v.BaseQuality > maxQualityMovies) then
					maxQualityMovies = v.BaseQuality
				end
				if ((v.BaseQuality < minQualityMovies) or (minQualityMovies == 0)) then
					minQualityMovies = v.BaseQuality
				end
			elseif (v.ProgramType == PROGRAM_SERIES) then
				if (v.BaseQuality > maxQualitySeries) then
					maxQualitySeries = v.BaseQuality
				end
				if ((v.BaseQuality < minQualitySeries) or (minQualitySeries == 0)) then
					minQualitySeries = v.BaseQuality
				end
			end
		else
			--debugMsg("zu teuer: " .. v.Price .. " / " .. maxPrice)
		end
	end

	--debugMsg("***")
	--debugMsg("maxQualityMovies: " .. maxQualityMovies)
	--debugMsg("minQualityMovies: " .. minQualityMovies)
	--debugMsg("maxQualitySeries: " .. maxQualitySeries)
	--debugMsg("minQualitySeries: " .. minQualitySeries)
	--debugMsg("***")

	local ScopeMovies = maxQualityMovies - minQualityMovies
	self.EveningMovieMinLimit = math.round(minQualityMovies + (ScopeMovies * 0.75))
	self.DayMovieMinLimit = math.round(minQualityMovies + (ScopeMovies * 0.4))

	local ScopeSeries = maxQualitySeries - minQualitySeries
	self.EveningSeriesMinLimit = math.round(minQualitySeries + (ScopeSeries * 0.75))
	self.DaySeriesMinLimit = math.round(minQualitySeries + (ScopeSeries * 0.4))

	--debugMsg("============")
	--debugMsg("EveningMovieMinLimit: " .. self.EveningMovieMinLimit)
	--debugMsg("DayMovieMinLimit: " .. self.DayMovieMinLimit)
	--debugMsg("============")
	--dddd = true
	--debugMsg("============" .. dddd)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTBrain = TVTDataObjekt:new{
CurrentTask = nil;
Budget = nil;
}

function TVTBrain:typename()
	return "TVTBrain"
end

function TVTBrain:initialize()
	globalBrain = self;

	debugMsg("Initialisiere KI ...")
	math.randomseed(TVT.getMillisecs())

	self.Budget = TVTBudgetManager:new()

	self.TaskList = {}
	self.TaskList[TASK_MOVIEPURCHASE]	= TVTMoviePurchase:new()
	self.TaskList[TASK_NEWSAGENCY]		= TVTNewsAgency:new()
	self.TaskList[TASK_ADAGENCY]		= TVTAdAgency:new()
	self.TaskList[TASK_SCHEDULING]		= TVTScheduling:new()
	self.TaskList[TASK_STATIONS]		= TVTStations:new()
	self.TaskList[TASK_BETTY]			= TVTBettyTask:new()
	self.TaskList[TASK_BOSS]			= TVTBossTask:new()
	self.TaskList[TASK_ARCHIVE]			= TVTArchive:new()

	--self:PlanThisDay()
end

function TVTBrain:PlanThisDay()
	debugMsg("Budgetberechnung")
	self.Budget:CalculateBudget()
end

function TVTBrain:OnReachRoom()
	self.CurrentTask:OnReachRoom()
end

function TVTBrain:Tick()
	if self.CurrentTask == nil then
		self.CurrentTask = self:SelectTask()
		self.CurrentTask:Do()
	else
		if self.CurrentTask.sStatus == TASK_STATUS_DONE then
			self.CurrentTask = self:SelectTask()
			self.CurrentTask:Do()
		else

			self.CurrentTask:Tick()
		end
	end
end

function TVTBrain:SelectTask()

	local BestPrio = -1
	local BestTask = nil

	for k,v in pairs(self.TaskList) do
		v:RecalcPriority()
		if (BestPrio < v.CurrentPriority) then
			BestPrio = v.CurrentPriority
			BestTask = v
		end
	end

	BestTask = self.TaskList[TASK_MOVIEPURCHASE]
	BestTask.sStatus = TASK_STATUS_OPEN
	return BestTask
end

function TVTBrain:RegulateNiveau(allmovies)

end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTTask = TVTDataObjekt:new{
Id = "";
sStatus = TASK_STATUS_OPEN;
TargetRoom = "";
BudgetWeigth = 0;
Budget = 0;
BudgetWholeDay = 0;
CurrentJob = nil;
BasePriority = 0;
CurrentPriority = 0;
SituationPriority = 0;
LastDone = 0;
StartTask = 0;
TickCounter = 0
}

function TVTTask:typename()
	return "TVTTask"
end

function TVTTask:OnReachRoom()
	if (self.CurrentJob ~= nil) then
		self.CurrentJob:OnReachRoom()
	end
end

function TVTTask:Do()
	--SendToChat("Do Task: " .. self:typename() .. "; Prio: " .. self.CurrentPriority)
	if TVT.GetPlayerRoom() ~= self.TargetRoom then
		self.CurrentJob = self:getJobGoto()
		self.CurrentJob:Do()
	else
		if (self.sStatus == TASK_STATUS_OPEN) then
			self.sStatus = TASK_STATUS_RUN
			self.StartTask = TVT.GetTime()
			self.TickCounter = 0;
		end
		self:InnerDo()
	end
end

function TVTTask:InnerDo()
	--kann überschrieben werden, ist im STandard aber leer.
end

function TVTTask:Tick()
	if (self.CurrentJob == nil) then
		self.TickCounter = self.TickCounter + 1
		self:Do() --Von vorne anfangen
	else
		if self.CurrentJob.sStatus == JOB_STATUS_DONE then
			self.CurrentJob = nil
			--SendToChat("----- Alter Job fertig")
			--SendToChat("----- Neuer Task!")
			self.TickCounter = self.TickCounter + 1
			self:Do() --Von vorne anfangen
		else
			--SendToChat("----- Job-Tick")
			self.CurrentJob:Tick() --Fortsetzen
		end
	end
end

function TVTTask:getJobGoto()
	local aJob = TVTJobGoToRoom:new()
	aJob.TargetRoom = self.TargetRoom
	return aJob
end

function TVTTask:RecalcPriority()
	local Ran1 = math.random(4)
	local Ran2 = math.random(4)
	local TimeDiff = TVT.GetTime() - self.LastDone
	self.CurrentPriority = self.SituationPriority + (self.BasePriority * (8+Ran1)) + (TimeDiff / 10 * (self.BasePriority - 2 + Ran2))
end

function TVTTask:SetDone()
	self.sStatus = TASK_STATUS_DONE
	self.SituationPriority = 0
	self.LastDone = TVT.GetTime()
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTMoviePurchase = TVTTask:new{
NiveauChecked = false;
MovieCount = 0;
CheckMode = 0;
MovieList = nil
}

MP_MODE_ALL = "all"
MP_MODE_CHECK = "check"
MP_MODE_SOME = "some"


function TVTMoviePurchase:typename()
	return "TVTMoviePurchase"
end

function TVTMoviePurchase:initialize()
	self.Id = TASK_MOVIEPURCHASE
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 7
	self.BasePriority = 8
	self.TargetRoom = ROOM_MOVIEAGENCY
end

function TVTMoviePurchase:ChooseMode()
	--Mögliche Modi:
	--0 - Alle Filme überprüfen
	--1 - Bedarf befriedigen
	--2 - Niveau justieren

	if (self.NiveauChecked == false) then
		self.NiveauChecked = true
		return MP_MODE_CHECK --Niveau justieren
	else
		return MP_MODE_ALL --TODO
	end
end

function TVTMoviePurchase:InnerDo()
	local movieID = 0
	local currProgram = nil

	-- Erster Durchlauf
	if (self.TickCounter == 0) then
		self.MovieList = {}
		self.CheckMode = self:ChooseMode()
		self.MovieCount = md_getMovieCount()
		debugMsg("Mode: " .. self.CheckMode)
	end

	if ((self.CheckMode == MP_MODE_ALL) or (self.CheckMode == MP_MODE_CHECK)) then --Alle checken
		--debugMsg("Filme: " .. table.count(self.MovieList))
		if (self.TickCounter <= self.MovieCount - 1) then
			movieID = md_getMovie(self.TickCounter)
			debugMsg("MovieCheck: " .. self.TickCounter + 1 .. "/" .. self.MovieCount )
			currProgram = TVTProgram:new()
			currProgram:Initialize(movieID)
			self.MovieList[movieID] = currProgram
		else
			if (self.CheckMode == MP_MODE_CHECK) then
				getMovieManager():NiveauCheck(self.MovieList)
			end
			self:DecidePurchase()
			self:SetDone()
		end
	elseif (self.CheckMode == MP_MODE_SOME) then
		--erstmal nichts
	end
end

function TVTMoviePurchase:DayBudgetPerBlock()
	--debugMsg("DayBudgetPerBlock: " .. (self.BudgetWholeDay / 100 * 3.65))
	return self.BudgetWholeDay / 100 * 3.65
end

function TVTMoviePurchase:EveningBudgetPerBlock()
	--debugMsg("EveningBudgetPerBlock: " .. (self.BudgetWholeDay / 100 * 5.86))
	return self.BudgetWholeDay / 100 * 5.86
end

function TVTMoviePurchase:NightBudgetPerBlock()
	--debugMsg("NightBudgetPerBlock: " .. (self.BudgetWholeDay / 100 * 2.32))
	return self.BudgetWholeDay / 100 * 2.32
end

function TVTMoviePurchase:DecidePurchase()

	-- Filme nach Preis/Leistung sortieren
	table.sort(self.MovieList, MovieSort)

	-- Bedarf abdecken (TODO)

	-- Gute Filme checken
	for k,v in pairs(self.MovieList) do
		if (v:ReadyToPurchase() == true) then
			v:FindType()
			if (v.TimeType == PROGRAM_TYPE_EVENING) then
				if (v:MetaPricePerBlock() <= self:EveningBudgetPerBlock()) then
					--debugMsg("kaufen!: " .. v:PricePerQualityPoint())
					if (v:PricePerQualityPoint() < 150) then --TODO
						md_doBuyMovie(v.Id)
						debugMsg("gekauft e")
					end
				end
			elseif (v.TimeType == PROGRAM_TYPE_DAY) then
				if (v:MetaPricePerBlock() <= self:DayBudgetPerBlock()) then
					--debugMsg("kaufen!: " .. v:PricePerQualityPoint())
					if (v:PricePerQualityPoint() < 150) then --TODO
						md_doBuyMovie(v.Id)
						debugMsg("gekauft d")
					end
				end
			elseif (v.TimeType == PROGRAM_TYPE_NIGHT) then
				if (v:MetaPricePerBlock() <= self:NightBudgetPerBlock()) then
					--debugMsg("kaufen!: " .. v:PricePerQualityPoint())
					if (v:PricePerQualityPoint() < 150) then --TODO
						md_doBuyMovie(v.Id)
						debugMsg("gekauft n")
					end
				end
			end
		end
	end
end

MovieSort = function(movie1, movie2)
	if (movie1:ReadyToPurchase() > movie2:ReadyToPurchase()) then
		return true
	else
		return false
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTNewsAgency = TVTTask:new()

function TVTNewsAgency:typename()
	return "TVTNewsAgency"
end

function TVTNewsAgency:initialize()
	self.Id = TASK_NEWSAGENCY
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 1.5
	self.BasePriority = 8
	self.TargetRoom = ROOM_NEWSAGENCY_PLAYER_ME
end

function TVTNewsAgency:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Nachrichten checken: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTAdAgency = TVTTask:new()

function TVTAdAgency:typename()
	return "TVTAdAgency"
end

function TVTAdAgency:initialize()
	self.Id = TASK_ADAGENCY
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 0
	self.BasePriority = 8
	self.TargetRoom = ROOM_ADAGENCY
end

function TVTAdAgency:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Werbung checken: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTScheduling = TVTTask:new()

function TVTScheduling:typename()
	return "TVTScheduling"
end

function TVTScheduling:initialize()
	self.Id = TASK_SCHEDULING
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 0
	self.BasePriority = 10
	self.TargetRoom = ROOM_OFFICE_PLAYER_ME
end

function TVTScheduling:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Programme planen: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTStations = TVTTask:new()

function TVTStations:typename()
	return "TVTStations"
end

function TVTStations:initialize()
	self.Id = TASK_STATIONS
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 2
	self.BasePriority = 3
	self.TargetRoom = ROOM_OFFICE_PLAYER_ME
end

function TVTStations:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Sendemasten prüfen: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTBettyTask = TVTTask:new()

function TVTBettyTask:typename()
	return "TVTBettyTask"
end

function TVTBettyTask:initialize()
	self.Id = TASK_BETTY
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 1
	self.BasePriority = 2
	self.TargetRoom = ROOM_BETTY
end

function TVTBettyTask:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Betty besuchen: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTBossTask = TVTTask:new()

function TVTBossTask:typename()
	return "TVTBossTask"
end

function TVTBossTask:initialize()
	self.Id = TASK_BOSS
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 0
	self.BasePriority = 5
	self.TargetRoom = ROOM_BOSS_PLAYER_ME
end

function TVTBossTask:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Den Boss nach Geld fragen: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTArchive = TVTTask:new()

function TVTArchive:typename()
	return "TVTArchive"
end

function TVTArchive:initialize()
	self.Id = TASK_ARCHIVE
	self.sStatus = JOB_STATUS_NEW
	self.BudgetWeigth = 0
	self.BasePriority = 3
	self.TargetRoom = ROOM_ARCHIVE_PLAYER_ME
end

function TVTArchive:InnerDo()
	if ((self.StartTask + 2) < TVT.GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Filme archivieren: " .. (self.StartTask + 3) .. " : " .. TVT.GetTime())
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTJob = TVTDataObjekt:new{
Id = "";
sStatus = JOB_STATUS_NEW;
StartJob = 0;
ActiveCheck = 0;
StartParams = nil;
}

function TVTJob:typename()
	return "TVTJob"
end

function TVTJob:OnReachRoom()
	debugMsg("Implementiere mich: " .. type(self))
end

function TVTJob:Do(pParams)
	self.StartParams = pParams
	self.StartJob = TVT.GetTime()
	self.ActiveCheck = TVT.GetTime()
	self:InnerDo()
end

function TVTJob:InnerDo(pParams)
	debugMsg("Implementiere mich: " .. type(self))
end

function TVTJob:Tick()

end

function TVTJob:ReDoCheck(pWait)
	if ((self.ActiveCheck + pWait) < TVT.GetTime()) then
		debugMsg("ReDoCheck")
		self.sStatus = JOB_STATUS_REDO
		self.ActiveCheck = TVT.GetTime()
		self:InnerDo(self.StartParams)
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTJobGoToRoom = TVTJob:new{
TargetRoom = 0
}

function TVTJobGoToRoom:typename()
	return "TVTJobGoToRoom"
end

function TVTJobGoToRoom:OnReachRoom()
	self.sStatus = JOB_STATUS_DONE
end

function TVTJobGoToRoom:InnerDo(pParams)
	if ((self.sStatus == JOB_STATUS_NEW) or (self.sStatus == JOB_STATUS_REDO)) then
		debugMsg("GotoRoom: " .. self.TargetRoom)
		TVT.DoGoToRoom(self.TargetRoom)
		self.sStatus = JOB_STATUS_RUN
	end
end

function TVTJobGoToRoom:Tick()
	self:ReDoCheck(10)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTProgram = TVTDataObjekt:new{
Id = "";
ProgramType = "";
Price = 0;
SeriesCount = 0;
BaseQuality = 0;
TimeType = "";
CalculatedQuality = 0;
Length = 0;
InnerReadyToPurchase = nil
}

function TVTProgram:typename()
	return "TVTProgram"
end

function TVTProgram:Initialize(pId)
	self.Id = pId
	self.SeriesCount = MovieSequels(pId)
	if (self.SeriesCount == 0) then
		self.SeriesCount = 1
	end

	self.Price = MoviePrice(pId)
	self.Length = MovieLength(self.Id)

	if (self.SeriesCount > 1) then
		self.ProgramType = PROGRAM_SERIES
	else
		self.ProgramType = PROGRAM_MOVIE
	end
	self:CalculateBaseQuality()
end

function TVTProgram:CalculateBaseQuality()
	self.BaseQuality = (0.3 * MovieProfit(self.Id) + 0.15 * MovieSpeed(self.Id) + 0.25 * MovieReview(self.Id) + 0.3 * MovieTopicality(self.Id))
end

function TVTProgram:FindType()
	--Die NiveauLimits werden im MovieManager berechnet
	if self.BaseQuality > getMovieManager().DayMovieMinLimit then
		if self.BaseQuality > getMovieManager().EveningMovieMinLimit then
			self.TimeType = PROGRAM_TYPE_EVENING
		else
			self.TimeType = PROGRAM_TYPE_DAY
		end
	else
		self.TimeType = PROGRAM_TYPE_NIGHT
	end
end

function TVTProgram:PricePerBlock()
	local TotalBlocks = (self.Length * self.SeriesCount)
	return self.Price / TotalBlocks
end

function TVTProgram:MetaPricePerBlock()
	--Diese Funktion berechnet den geschätzten Wert eines Filmes
	local topo = MovieTopicality(self.Id)
	local factor = 1

	if (topo > 50) then
		factor = 4
	elseif (topo > 25) then
		factor = 3
	elseif (topo > 12) then
		factor = 2
	end

	local TotalBlocks = (self.Length * self.SeriesCount * factor)
	return self.Price / TotalBlocks
end

function TVTProgram:EvaluatedSendCostPerBlock()
	return self:PricePerBlock() * 0.1
end

function TVTProgram:EvaluatedSendCost()
	return self:EvaluatedSendCostPerBlock() * 0.1
end

function TVTProgram:PricePerQualityPoint()
	return self:PricePerBlock() / self.BaseQuality
end

function TVTProgram:ReadyToPurchase()
	if (self.InnerReadyToPurchase == nil) then
		self.InnerReadyToPurchase = false

		--debugMsg("ABC: " .. MoviePrice(self.Id) .. " - " .. getMovieManager().MovieMaxLimit)
		if (self.ProgramType == PROGRAM_MOVIE) then
			if (MoviePrice(self.Id) <= getMovieManager().MovieMaxLimit) then
				self.InnerReadyToPurchase = true
			else
				self.InnerReadyToPurchase = false
			end
		else
			if (MoviePrice(self.Id) <= getMovieManager().SeriesMaxLimit) then
				self.InnerReadyToPurchase = true
			else
				self.InnerReadyToPurchase = false
			end
		end
	end

	return self.InnerReadyToPurchase
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- ##### EVENTS #####
function OnMoneyChanged()
	--debugMsg("Hey mein Geld hat sich geaendert")
end

function OnChat(message)
	--debugMsg("chat: " .. message)
	globalKIStatus = message
	--getBrain():
end

function OnDayBegins()
	--debugMsg("Guten Morgen, ich schau mal beim Chef vorbei!")
	getBrain():PlanThisDay()
    -- DoGoto(ROOM_BOSS_PLAYER_ME)
end

function OnReachRoom(roomId)
	--debugMsg("Endlich im Raum angekommen")
	getBrain():OnReachRoom()
end

function OnLeaveRoom()
	--debugMsg("Und raus aus dem Zimmer!")
end

function OnMinute(number)
	if globalKIStatus == KI_STATUS_RUN then getBrain():Tick() end
end

function debugMsg(pMessage)
	if ME == 2 then
		TVT.SendToChat(ME .. ": " .. pMessage)
	end
end
