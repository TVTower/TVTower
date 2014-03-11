-- File: BudgetManager
TODAY_BUDGET		= "T"
OLD_BUDGET_1		= "1"
OLD_BUDGET_2		= "2"
OLD_BUDGET_3		= "3"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BudgetManager"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.TodayStartAccountBalance = 0 -- Kontostand zu Beginn des Tages
	c.BudgetMinimum = 0  -- Minimalbetrag des Budgets
	c.BudgetMaximum = 0  -- Maximalbetrag des Budgets
	c.BudgetHistory = {} -- Die Budgets der letzten Tage	
end)

function BudgetManager:typename()
	return "BudgetManager"
end

function BudgetManager:Initialize()
	-- Da am Anfang auf keine Erfahrungswerte bezüglich der Budgethöhe zurückgegriffen werden kann,
	-- wird für alle vergangenen Tage angenommen, dass es gleich war. Das Budget entspricht erstmal 80% des Startkapitals.
	local playerMoney = MY.GetMoney() --aktueller Geldstand
	local startBudget = math.round(playerMoney * 0.8) --Gesamtbudget das investiert werden soll. Später von der Risikobereitschafts abhängig machen.

	-- Erfahrungswerte für den Anfang mit dem Standardwert initialisieren
	self.BudgetHistory = {}
	self.BudgetHistory[OLD_BUDGET_3] = startBudget
	self.BudgetHistory[OLD_BUDGET_2] = startBudget
	self.BudgetHistory[OLD_BUDGET_1] = startBudget
	self.BudgetHistory[TODAY_BUDGET] = startBudget

	self.TodayStartAccountBalance = playerMoney		-- Legt fest, dass angenommen wird, gestern habe man den gleichen Kontostand gehabt

	self.BudgetMinimum = math.round(playerMoney / 5)	-- Legt das Minimalbudget fest: 50% des Startwertes
	self.BudgetMaximum = math.round(playerMoney * 0.8)  -- Das Maximalbudget entspricht am Anfang 80% des Startwertes
end

function BudgetManager:CalculateBudget() -- Diese Methode wird immer zu Beginn des Tages aufgerufen
	self:CheckInvestments()	

	--Die Erfahrungswerte werden wieder um einen Tag nach hinten verschoben, da ein neuer Erfahrungswert dazukommt
	self.BudgetHistory[OLD_BUDGET_3] = self.BudgetHistory[OLD_BUDGET_2]
	self.BudgetHistory[OLD_BUDGET_2] = self.BudgetHistory[OLD_BUDGET_1]
	self.BudgetHistory[OLD_BUDGET_1] = self.BudgetHistory[TODAY_BUDGET]

	-- Gestrigte Werte
	local YesterdayBudget = self.BudgetHistory[TODAY_BUDGET]
	local YesterdayStartAccountBalance = self.TodayStartAccountBalance	-- den gestrigen Wert zwischenspeichern

	-- Werte nachjustieren
	self.TodayStartAccountBalance = MY.GetMoney() -- Kontostand aktualisieren
	self.BudgetMinimum = self.BudgetMinimum * 1.01
	self.BudgetMaximum = self.TodayStartAccountBalance * 0.95

	local YesterdayTurnOver = self.TodayStartAccountBalance - (YesterdayStartAccountBalance - YesterdayBudget) -- Gestriger Umsatz
	-- TODO: Anstatt dem YesterdayBudget kann man auc die tatsächtlichen gestrigen Ausgaben anführen. (denn im Moment ist es sehr ungenau)

	-- Ermittle ein neues Budget für den heutigen Tag auf Grund der Erfahrungswerte
	local myBudget = self:CalculateAverageBudget(self.TodayStartAccountBalance, YesterdayTurnOver)

	-- Minimal-Budget prüfen
	if myBudget < self.BudgetMinimum then
		myBudget = self.BudgetMinimum
	end

	--Maximal-Budget prüfen
	if myBudget > self.BudgetMaximum then
		myBudget = self.BudgetMaximum
	end

	-- TODO: Kredit ja/nein --- Zurückzahlen ja/nein

	-- Neuer History-Eintrag
	self.BudgetHistory[TODAY_BUDGET] = myBudget

	-- Das Budget auf die Tasks verteilen
	self:AllocateBudgetToTasks(myBudget)
end

function BudgetManager:CheckInvestments()
	local player = _G["globalPlayer"] --Zugriff die globale Variable

	-- Zählen wie viele Budgetanteile es insgesamt gibt
	for k,v in pairs(player.TaskList) do
		v.InvestmentPriority = v.InvestmentPriority + v.BudgetWeigth
	end
	
	--TODO: hier weiter machen
end

function BudgetManager:CalculateAverageBudget(pCurrentAccountBalance, pTurnOver)
	--debugMsg("A1.1: " .. pTurnOver); debugMsg("AX.1: " .. self.BudgetHistory[OLD_BUDGET_1]); debugMsg("AX.2: " .. self.BudgetHistory[OLD_BUDGET_2]); debugMsg("AX.3: " .. self.BudgetHistory[OLD_BUDGET_3])

	-- Alle Erfahrungswerte werden aufsummiert und mit einem Faktor gewichtet und dann durch 10 geteilt. 4 + 3 + 2 + 1 / 10
	local TempSum = ((pTurnOver * 4) + (self.BudgetHistory[OLD_BUDGET_1] * 3) + (self.BudgetHistory[OLD_BUDGET_2] * 2) + (self.BudgetHistory[OLD_BUDGET_3] * 1)) / 10
	if pCurrentAccountBalance > (TempSum / 2) then -- Reicht der aktuelle Kontostand aus, um das errechnete Budget zu finanzieren?
		-- Das Budget wird um 0% bis 9% erhöht
		TempSum = TempSum + (pCurrentAccountBalance * ((math.random(10)-1)/100)) -- TODO: Zufallswert wird durch Level und Risikoreichtum bestimmt
	end
	return math.round(TempSum, -3) --Das ganze wird nun noch gerundet
end

function BudgetManager:AllocateBudgetToTasks(pBudget)
	local player = _G["globalPlayer"] --Zugriff die globale Variable

	-- Zählen wie viele Budgetanteile es insgesamt gibt
	local budgetUnits = 0
	for k,v in pairs(player.TaskList) do
		budgetUnits = budgetUnits + v.BudgetWeigth
	end
	if budgetUnits == 0 then budgetUnits = 1 end	
	
	-- Wert einer Budgeteinheit bestimmen
	local BudgetUnit = pBudget / budgetUnits

	-- Die Budgets zuweisen
	for k,v in pairs(player.TaskList) do
		debugMsg(v:typename() .. "- Altes Budget: " .. v.CurrentBudget .. " / " .. v.BudgetWholeDay)
		v.CurrentBudget = math.round(v.BudgetWeigth * BudgetUnit)
		v.BudgetWholeDay = v.CurrentBudget
		v:BudgetSetup()
		debugMsg(v:typename() .. "- BudgetWholeDay: " .. v.BudgetWholeDay)
	end
end

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
