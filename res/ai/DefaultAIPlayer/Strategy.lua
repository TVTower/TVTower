-- File: Strategy.lua
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIStrategy"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
--	c.TodayStartAccountBalance = 0 -- Kontostand zu Beginn des Tages

	c.startProgrammeAmount = 4
	c.initDone = false

	-- adjusts attraction of an infomercial when it comes to decide
	-- on what to broadcast
	c.infomercialWeight = 0.85
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


function AIStrategy:GetInfomercialWeight()
	-- this could be game-day / progress specific
	return self.infomercialWeight
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

	if playerAI.Ventruesome > 7 then
		self.startProgrammeAmount = 5
	elseif playerAI.Ventruesome >= 5 then
		self.startProgrammeAmount = 6
	else
		self.startProgrammeAmount = 7
	end

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
	--handle differently
	--playerAI.Budget.SavingParts = 0.6
end


function BeginExpandStrategy:Finalize(playerAI)
	playerAI.TaskList[TASK_MOVIEDISTRIBUTOR]:ResetDefaults()
	playerAI.TaskList[TASK_STATIONMAP]:ResetDefaults()
	playerAI.Budget:ResetDefaults()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<