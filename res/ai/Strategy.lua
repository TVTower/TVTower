-- File: Strategy.lua
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIStrategy"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.TodayStartAccountBalance = 0 -- Kontostand zu Beginn des Tages

	--amount to spend for start programme
	c.startProgrammePriceMax = 70000
	c.startProgrammeBudget = 280000
	c.startProgrammeAmount = 4
	c.initDone = false
end)

function AIStrategy:typename()
	return "AIStrategy"
end

function AIStrategy:Start(playerAI)
	--überschreiben
end

function AIStrategy:Finalize(playerAI)
	--überschreiben
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["DefaultStrategy"] = class(AIStrategy, function(c)
	AIStrategy.init(c)	-- must init base!
end)

function DefaultStrategy:typename()
	return "DefaultStrategy"
end


function DefaultStrategy:initialize()
	if playerAI == nil then playerAI = _G["globalPlayer"] end

	-- a risky player (Ventruesome = 10) will spend 25000 less for each
	-- programme, a non-risky one up to 25000 more
	self.startProgrammePriceMax = self.startProgrammePriceMax + 2500 * (5 - playerAI.Ventruesome)

	if playerAI.Ventruesome > 7 then
		self.startProgrammeAmount = 4 
	elseif playerAI.Ventruesome >= 5 then
		self.startProgrammeAmount = 5 
	else
		self.startProgrammeAmount = 6
	end 

	self.startProgrammeBudget = self.startProgrammeAmount * self.startProgrammePriceMax + 8000 * (5 - playerAI.Ventruesome)
	TVT.PrintOut(TVT.ME .. ": startProgramme=" .. self.startProgrammeAmount .. "  priceMax=" .. self.startProgrammePriceMax .. "  totalBudget=" .. self.startProgrammeBudget)

	self.initDone = true
end


function DefaultStrategy:Start(playerAI)
	if not self.initDone then self:initialize() end
end

function DefaultStrategy:Finalize(playerAI)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["BeginExpandStrategy"] = class(AIStrategy, function(c)
	AIStrategy.init(c)	-- must init base!
end)

function BeginExpandStrategy:typename()
	return "BeginExpandStrategy"
end

function BeginExpandStrategy:Start(playerAI)
	playerAI.TaskList[TASK_MOVIEDISTRIBUTOR].InvestmentPriority = 0
	playerAI.TaskList[TASK_STATIONMAP].BasePriority = 3
	playerAI.TaskList[TASK_STATIONMAP].InvestmentPriority = 15
	playerAI.Budget.SavingParts = 0.6
end

function BeginExpandStrategy:Finalize(playerAI)
	playerAI.TaskList[TASK_MOVIEDISTRIBUTOR]:ResetDefaults()
	playerAI.TaskList[TASK_STATIONMAP]:ResetDefaults()
	playerAI.Budget:ResetDefaults()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<