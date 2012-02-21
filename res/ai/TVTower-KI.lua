-- ##### HISTORY #####
-- 31.12.2007 Manuel
-- - CHG: Debug-Ausgaben sind nun ausschaltbar für die Demo-Version Silverster 2007
-- - CHG: Anpassung an das neue Verhalten von OnDayBegins()
-- 20.12.2007 Manuel
-- +++++ V 0.2: Task-, Job- und Geldmanagement sowie Priorisierung grundlgend abgeschlossen
-- NEW: Es sind jetzt fast alle Task-Hüllen drin. Der Spieler läuft schon fleißig durch die Gegend
-- 19.12.2007 Manuel
-- - NEW: Task- und Jobverwaltung ausgebaut
-- - FIX: self-Variablen-Fix bei der Budgetberechnung
-- 18.12.2007 Manuel
-- - NEW: Das nun errechnete Gesamtbudget für den Tag wird jetzt auf die einzelnen Bereiche wie Filmkauf, Senderkauf, Geschenke nach einem Schlüssel usw. aufgeteilt
-- - NEW: Die Tasks sorgen nun dafür, dass der Spieler automatisch in den richtigen Raum läuft. Ist dieser erreicht, wird die eigentliche Aufgabe angegangen.
-- - FIX: Unzählige Fehler von falschen Methodenaufrufen ohne Doppelpunkt und self-Fehler korrigiert
-- 13.12.2007 Manuel
-- - CHG: Budget-Berechnung weiter entwickelt
-- - CHG: Integration des SLF (Simple Lua Framework)
-- 10.12.2007 Manuel
-- - NEW: Erste Implementierung der Gesamtbudget-Abschätzung
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
APP_VERSION			= "0.2"

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

-- ##### GLOBALS #####
globalIDCounter = 0
globalBrain = nil
globalTemp = 0
globalKIStatus = KI_STATUS_RUN

-- ##### INITIALIZE #####
print("Player " .. ME .. ": Load... Lua-Standard-KI V" .. APP_VERSION .. " - by Manuel Voegele")

-- ##### SINGLETON #####
function getBrain()
	if globalBrain == nil then globalBrain = TVTBrain:new() end
	return globalBrain
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
	local playerMoney = GetPlayerMoney(ME)
	local startBudget = math.round(playerMoney / 3)

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
	self.TodayStartWealth = GetPlayerMoney(ME)

	local YesterdayTurnOver = self.TodayStartWealth - (YesterdayWealth - YesterdayBudget) -- Gestriger Umsatz
	-- TODO: Anstatt dem YesterdayBudget kann man auc die tatsächtlichen gestrigen Ausgaben anführen.

	-- Berechne aktuelles Budget
	local myBudget = self:CalculateAverageBudget(self.TodayStartWealth, YesterdayTurnOver)

	-- Minimal-Budget prüfen
	if myBudget < self.BudgetMinimum then
		myBudget = self.BudgetMinimum
	end

	-- TODO: Kredit ja/nein --- Zurückzahlen ja/nein

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

	local BudgetUnit = myBudget / BudgetUnits

	for k,v in pairs(getBrain().TaskList) do
		v.Budget = v.BudgetWeigth * BudgetUnit
	end
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
	math.randomseed(GetMillisecs())

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

	BestTask.sStatus = TASK_STATUS_OPEN
	return BestTask
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTTask = TVTDataObjekt:new{
Id = "";
sStatus = TASK_STATUS_OPEN;
TargetRoom = "";
BudgetWeigth = 0;
Budget = 0;
CurrentJob = nil;
BasePriority = 0;
CurrentPriority = 0;
SituationPriority = 0;
LastDone = 0;
StartTask = 0;
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
	if GetPlayerRoom() ~= self.TargetRoom then
		self.CurrentJob = self:getJobGoto()
		self.CurrentJob:Do()
	else
		if (self.sStatus == TASK_STATUS_OPEN) then
			self.sStatus = TASK_STATUS_RUN
			self.StartTask = GetTime()
		end
		self:InnerDo()
	end
end

function TVTTask:InnerDo()
	--kann überschrieben werden, ist im STandard aber leer.
end

function TVTTask:Tick()
	if (self.CurrentJob == nil) then
		self:Do()
	else
		if self.CurrentJob.sStatus == JOB_STATUS_DONE then
			self.CurrentJob = nil
			--SendToChat("----- Alter Job fertig")
			--SendToChat("----- Neuer Task!")
			self:Do()
		else
			--SendToChat("----- Job-Tick")
			self.CurrentJob:Tick()
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
	local TimeDiff = GetTime() - self.LastDone
	self.CurrentPriority = self.SituationPriority + (self.BasePriority * (8+Ran1)) + (TimeDiff / 10 * (self.BasePriority - 2 + Ran2))
end

function TVTTask:SetDone()
	self.sStatus = TASK_STATUS_DONE
	self.SituationPriority = 0
	self.LastDone = GetTime()
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TVTMoviePurchase = TVTTask:new()

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

function TVTMoviePurchase:InnerDo()
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Filme kaufen: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	self.BudgetWeigth = 3
	self.BasePriority = 8
	self.TargetRoom = ROOM_NEWSAGENCY_PLAYER_ME
end

function TVTNewsAgency:InnerDo()
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Nachrichten checken: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Werbung checken: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Programme planen: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Sendemasten prüfen: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Betty besuchen: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Den Boss nach Geld fragen: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	if ((self.StartTask + 2) < GetTime()) then
		self:SetDone()
	end
	debugMsg("Aktion - Filme archivieren: " .. (self.StartTask + 3) .. " : " .. GetTime())
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
	self.StartJob = GetTime()
	self.ActiveCheck = GetTime()
	self:InnerDo()
end

function TVTJob:InnerDo(pParams)
	debugMsg("Implementiere mich: " .. type(self))
end

function TVTJob:Tick()

end

function TVTJob:ReDoCheck(pWait)
	if ((self.ActiveCheck + pWait) < GetTime()) then
		debugMsg("ReDoCheck")
		self.sStatus = JOB_STATUS_REDO
		self.ActiveCheck = GetTime()
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
		DoGoToRoom(self.TargetRoom)
		self.sStatus = JOB_STATUS_RUN
	end
end

function TVTJobGoToRoom:Tick()
	self:ReDoCheck(10)
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
	--if ME == 2 then
--		SendToChat(ME .. ": " .. pMessage)
	--end
end
