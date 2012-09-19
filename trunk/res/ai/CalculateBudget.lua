-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskCalculateBudget = AITask:new{
	TargetRoom = nil;
}

function TaskCalculateBudget:typename()
	return "TaskCalculateBudget"
end

function TaskCalculateBudget:Activate()
	debugMsg("Starte Task 'TaskCalculateBudget'")
end

function TaskCalculateBudget:GetNextJobInTargetRoom()
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
