-- File: BudgetManager
TIME_TODAY		= "T"
TIME_OLDDAY_1	= "1"
TIME_OLDDAY_2	= "2"
TIME_OLDDAY_3	= "3"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BudgetManager"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.BudgetHistory = {} -- Die Budgets der letzten Tage
	c.AccountBalanceHistory = {} -- Die Kontostaende der letzten Tage
	c.InvestmentSavings = 0 -- Geld das für Investitionen angespart wird.
	-- budget at the time of last call to "UpdateBudget"
	c.BudgetOnLastUpdateBudget = 0

	
	c:ResetDefaults()
end)

function BudgetManager:typename()
	return "BudgetManager"
end

function BudgetManager:ResetDefaults()
	-- Minimum value of the budgets
	self.BudgetMinimum = 0
	-- Maximum value of the budget 
	self.BudgetMaximum = 0
	-- Percentage of the budget to save for investments
	self.SavingParts = 0.3
	-- Percentage to add on fixed costs "to make sure it is enough"
	self.ExtraFixedCostsSavingsPercentage = 0.5
end

function BudgetManager:Initialize()
	-- Da am Anfang auf keine Erfahrungswerte bezüglich der Budgethöhe zurückgegriffen werden kann,
	-- wird für alle vergangenen Tage angenommen, dass es gleich war. Das Budget entspricht erstmal 80% des Startkapitals.
	local playerMoney = MY.GetMoney() --aktueller Geldstand
	local startBudget = math.round(playerMoney * 0.95) --Gesamtbudget das investiert werden soll. Später von der Risikobereitschafts abhängig machen.

	-- Erfahrungswerte für den Anfang mit dem Standardwert initialisieren
	self.BudgetHistory = {}
	self.BudgetHistory[TIME_OLDDAY_3] = startBudget
	self.BudgetHistory[TIME_OLDDAY_2] = startBudget
	self.BudgetHistory[TIME_OLDDAY_1] = startBudget
	self.BudgetHistory[TIME_TODAY] = startBudget

	self.AccountBalanceHistory = {}
	-- Legt fest, dass angenommen wird, gestern habe man den gleichen Kontostand gehabt
	self.AccountBalanceHistory[TIME_OLDDAY_3] = playerMoney
	self.AccountBalanceHistory[TIME_OLDDAY_2] = playerMoney
	self.AccountBalanceHistory[TIME_OLDDAY_1] = playerMoney
	self.AccountBalanceHistory[TIME_TODAY] = playerMoney

	self.BudgetMinimum = math.round(playerMoney * 0.4)	-- Legt das Minimalbudget fest: 40% des Startwertes
	self.BudgetMaximum = math.round(playerMoney * 0.8)  -- Das Maximalbudget entspricht am Anfang 80% des Startwertes
end


-- Diese Methode wird immer zu Beginn des Tages aufgerufen
function BudgetManager:CalculateNewDayBudget()
	TVT.addToLog("=== Budget Tag " .. WorldTime.GetDaysRun() .. " ===")	

	--Die Erfahrungswerte werden wieder um einen Tag nach hinten verschoben, da ein neuer Erfahrungswert dazukommt
	self.BudgetHistory[TIME_OLDDAY_3] = self.BudgetHistory[TIME_OLDDAY_2]
	self.BudgetHistory[TIME_OLDDAY_2] = self.BudgetHistory[TIME_OLDDAY_1]
	self.BudgetHistory[TIME_OLDDAY_1] = self.BudgetHistory[TIME_TODAY]

	-- preserve account balances of previous days
	self.AccountBalanceHistory[TIME_OLDDAY_3] = self.AccountBalanceHistory[TIME_OLDDAY_2]
	self.AccountBalanceHistory[TIME_OLDDAY_2] = self.AccountBalanceHistory[TIME_OLDDAY_1]
	self.AccountBalanceHistory[TIME_OLDDAY_1] = self.AccountBalanceHistory[TIME_TODAY]

	-- Werte nachjustieren
	self.AccountBalanceHistory[TIME_TODAY] = MY.GetMoney() -- Kontostand aktualisieren
	TVT.addToLog(string.left("Kontostand:", 20, true) .. string.right(self.AccountBalanceHistory[TIME_TODAY], 10, true))
	self.BudgetMinimum = self.BudgetMinimum * 1.01
	self.BudgetMaximum = self.AccountBalanceHistory[TIME_TODAY] * 0.95

	-- Gestriger Umsatz
	local YesterdayTurnOver = self.AccountBalanceHistory[TIME_TODAY] - (self.AccountBalanceHistory[TIME_OLDDAY_1] - self.BudgetHistory[TIME_OLDDAY_1])
	-- TODO: Anstatt dem self.BudgetHistory[TIME_OLDDAY_1] kann man auch die tatsächtlichen gestrigen Ausgaben anführen. (denn im Moment ist es sehr ungenau)

	-- Ermittle ein neues Budget für den heutigen Tag auf Grund der Erfahrungswerte
	-- Neuer History-Eintrag
	self.BudgetHistory[TIME_TODAY] = self:CalculateAverageBudget(self.AccountBalanceHistory[TIME_TODAY], YesterdayTurnOver)
	self.BudgetHistory[TIME_TODAY] = math.clamp(self.BudgetHistory[TIME_TODAY], self.BudgetMinimum, self.BudgetMaximum)

	self:UpdateBudget(self.BudgetHistory[TIME_TODAY])
	TVT.addToLog("======")
end


function BudgetManager:UpdateBudget(pBudget)

	-- TODO: Kredit ja/nein --- Zurückzahlen ja/nein
	-- TODO: Aktuell einfach mal ne maximalen Kredit ausreizen. Es sollte hier auf eine Bewertung "Geldnot", "Investitionsfreude" bzw. auf eine Strategie zurückgegriffen werden.
	local player = _G["globalPlayer"] --Zugriff die globale Variable
	if player.TaskList[TASK_BOSS] ~= nil then
		local bossTask = player.TaskList[TASK_BOSS]
		if bossTask.GuessCreditAvailable > 0 then
			bossTask.TryToGetCredit = 200000
			bossTask.SituationPriority = 2
		end
	end

	TVT.addToLog(string.left("Geplantes Budget:", 20, true) .. string.right(pBudget, 10, true))
	self:CutInvestmentSavingIfNeeded(pBudget)
	
	-- Das Budget auf die Tasks verteilen
	self:AllocateBudgetToTasks(pBudget)

	self.BudgetOnLastUpdateBudget = pBudget
end


function BudgetManager:CutInvestmentSavingIfNeeded(pBudget)
	local player = _G["globalPlayer"] --Zugriff die globale Variable
	
	if (pBudget * 0.8) < self.InvestmentSavings then -- zu viel gespart... Ersparnisse angreifen oder Kredit!!! aufnehmen
		TVT.addToLog("Kürze Ersparnisse: " .. self.InvestmentSavings .. ". Budget aber nur " .. pBudget .. ". Ersparnisse werden halbiert." )
		self.InvestmentSavings = self.InvestmentSavings / 2
	end
	
	if (pBudget * 0.6) < self.InvestmentSavings then -- zu viel gespart... Ersparnisse angreifen oder Kredit!!! aufnehmen
		TVT.addToLog("Streiche Ersparnisse komplett. Ersparnisse " .. self.InvestmentSavings .. ". Budget aber nur " .. pBudget .. ".")
		self.InvestmentSavings = 0
	end

	return savings
end

function BudgetManager:CalculateAverageBudget(pCurrentAccountBalance, pTurnOver)
	--debugMsg("A1.1: " .. pTurnOver); debugMsg("AX.1: " .. self.BudgetHistory[TIME_OLDDAY_1]); debugMsg("AX.2: " .. self.BudgetHistory[TIME_OLDDAY_2]); debugMsg("AX.3: " .. self.BudgetHistory[TIME_OLDDAY_3])

	-- Alle Erfahrungswerte werden aufsummiert und mit einem Faktor gewichtet und dann durch 10 geteilt. 4 + 3 + 2 + 1 / 10
	local TempSum = ((pTurnOver * 4) + (self.BudgetHistory[TIME_OLDDAY_1] * 3) + (self.BudgetHistory[TIME_OLDDAY_2] * 2) + (self.BudgetHistory[TIME_OLDDAY_3] * 1)) / 10
	if pCurrentAccountBalance > (TempSum / 2) then -- Reicht der aktuelle Kontostand aus, um das errechnete Budget zu finanzieren?
		-- Das Budget wird um 0% bis 9% erhöht
		TempSum = TempSum + (pCurrentAccountBalance * ((math.random(10)-1)/100)) -- TODO: Zufallswert wird durch Level und Risikoreichtum bestimmt
	end
	return math.round(TempSum, -3) --Das ganze wird nun noch gerundet
end

function BudgetManager:AllocateBudgetToTasks(pBudget)
	local player = _G["globalPlayer"] --Zugriff die globale Variable

	--Aufgaben hinweisen das Budget berechnet wird
	for k,v in pairs(player.TaskList) do
		v:BeforeBudgetSetup()
	end
	
	local allFixedCostsSavings = 0
	
	-- Zählen wie viele Budgetanteile es insgesamt gibt & Alle Fixkosten zusammen zählen
	local budgetUnits = 0
	for k,v in pairs(player.TaskList) do
		budgetUnits = budgetUnits + v:getBudgetUnits()
		allFixedCostsSavings = allFixedCostsSavings + v.FixedCosts
	end
	
	TVT.addToLog(string.left("Echte Fixkosten:", 20, true) .. string.right(allFixedCostsSavings, 10, true))
	--character riskyness defines how much to save "extra"
	allFixedCostsSavings = allFixedCostsSavings * self.ExtraFixedCostsSavingsPercentage
	TVT.addToLog(string.left("Fixkosten-Reserve:", 20, true) .. string.right(allFixedCostsSavings, 10, true))
	
	if budgetUnits == 0 then budgetUnits = 1 end	
		
	-- Ersparnisse erhöhen und das nun reale Budget bestimmen, dass verteilt werden soll.
	local tempBudget = pBudget - self.InvestmentSavings - allFixedCostsSavings
	self.InvestmentSavings = self.InvestmentSavings + math.round(tempBudget * self.SavingParts) -- Einen Teil ansparen
	local realBudget = pBudget - self.InvestmentSavings - allFixedCostsSavings -- Schließlich echtes Budget bestimmen
	TVT.addToLog(string.left("Sparanteil:", 20, true) .. string.right(self.InvestmentSavings, 10, true))
	TVT.addToLog(string.left("Tagesbudget:", 20, true) .. string.right(realBudget, 10, true))
	TVT.addToLog(string.right("=======", 30, true))
	
	-- Wert einer Budgeteinheit bestimmen
	local budgetUnitValue = realBudget / budgetUnits	
				
	-- Die Budgets den Tasks zuweisen
	for k,v in pairs(player.TaskList) do
		v.CurrentBudget = math.round(v.BudgetWeight * budgetUnitValue)
		if v.BudgetMaximum() >= 0 then
			v.CurrentBudget = math.min(v.CurrentBudget, v.BudgetMaximum())
		end
		v.BudgetWholeDay = v.CurrentBudget							
	end	
	
	-- Auf Investitionen prüfen
	local investTask = self:GetTaskForInvestment(player.TaskList)
	if (investTask ~= nil) then
		TVT.addToLog(investTask:typename() .. "- Use Investment: " .. self.InvestmentSavings)
		investTask.CurrentBudget = investTask.CurrentBudget + self.InvestmentSavings
		investTask.UseInvestment = true
		investTask.CurrentInvestmentPriority = 0
	end
	
	for k,v in pairs(player.TaskList) do
		v.BudgetWholeDay = v.CurrentBudget
		v:BudgetSetup()
		TVT.addToLog(v:typename() .. ": " .. v.BudgetWholeDay)		
	end
end

function BudgetManager:GetTaskForInvestment(tasks)
	local taskSorted = SortTasksByInvestmentPrio(tasks)	
	local rank = 1
	local highestPrio = nil
	
	for k,v in pairs(taskSorted) do
		if highestPrio == nil then
			highestPrio = v
			if self:IsTaskReadyForInvestment(v, rank) then
				return v
			end
		else
			if self:IsTaskReadyForInvestment(v, rank, highestPrio) then
				return v
			end
		end		
		rank = rank + 1
		if rank > 3 then return nil end
	end	
	return nil
end

function BudgetManager:IsTaskReadyForInvestment(task, rank, highestPrioTask)
	--1. Bedingung: Es wurde genug Geld gespart für diesen Task
	if (self.InvestmentSavings + task.BudgetWholeDay) >= task.NeededInvestmentBudget then
		--2. Bedingung: Die Prio muss hoch genug sein.
		if not rank then rank = 1 end
		if task.CurrentInvestmentPriority >= rank * 10 then
			--3. Bedingung: Der Abstand zu Prio des Ersten darf nicht zu groß sein
			local prioOfHighest = task.CurrentInvestmentPriority	
			if highestPrioTask ~= nil then
				prioOfHighest = highestPrioTask.CurrentInvestmentPriority
			end
			
			if prioOfHighest - task.CurrentInvestmentPriority <= 30 then
				--4. Bedingung: Ersparnis / Benötigte Investsumme des Ersten <= 0.8
				if highestPrioTask ~= nil then
					if (self.InvestmentSavings / highestPrioTask.NeededInvestmentBudget <= 0.8) then
						return true
					end
				else
					return true
				end						
			end			
		end
	end
	return false
end


function BudgetManager:OnMoneyChanged(value, reason, reference)
	if (reference ~= nil) then
		TVT.addToLog("$$ Money changed (" .. TVT.Constants.PlayerFinanceEntryType.GetAsString(reason) ..") : " .. value .. " for \"" .. reference:GetTitle() .. "\"")	
	else
		TVT.addToLog("$$ Money changed (" .. TVT.Constants.PlayerFinanceEntryType.GetAsString(reason) ..") : " .. value)
	end

	local renewBudget = false

	-- unplanned costs
	if (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.PAY_PENALTY)) then renewBudget = true end
	-- or income
	if (tostring(reason) == tostring(TVT.Constants.PlayerFinanceEntryType.CHEAT)) then renewBudget = true end
	if (tonumber(value) > 0) then renewBudget = true end


	if renewBudget == true then
		-- do not allow a negative profit
		local todaysProfit = math.max(0, MY.GetFinance(-1).GetCurrentProfit())
		local budgetNow = self:CalculateAverageBudget(MY.GetMoney(), todaysProfit)

		--update budget when at least 15.000 Euro difference since last
		--adjustment
		if math.abs(self.BudgetOnLastUpdateBudget - budgetNow) > 15000 then
			--TVT.addToLog("Profit heute: " .. todaysProfit)
			--TVT.addToLog("budget jetzt: " .. budgetNow)
			--self:UpdateBudget(todaysProfit)
			self:UpdateBudget(budgetNow)

			self.BudgetOnLastUpdateBudget = budgetNow
		end
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
