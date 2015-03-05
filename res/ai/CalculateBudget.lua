-- File: CalculateBudget
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskCalculateBudget"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = nil
end)

function TaskCalculateBudget:typename()
	return "TaskCalculateBudget"
end

function TaskCalculateBudget:Activate()
end

function TaskCalculateBudget:GetNextJobInTargetRoom()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
