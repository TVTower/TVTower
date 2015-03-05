-- File: Strategy.lua
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIStrategy"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.TodayStartAccountBalance = 0 -- Kontostand zu Beginn des Tages
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

function DefaultStrategy:Start(playerAI)
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