-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskNewsAgency = AITask:new{
	TargetRoom = TVT.ROOM_NEWSAGENCY_PLAYER_ME;
	BudgetWeigth = 3
}

function TaskNewsAgency:typename()
	return "TaskNewsAgency"
end

function TaskNewsAgency:Activate()
	debugMsg("Starte Task 'TaskNewsAgency'")
	-- Was getan werden soll:
	--self.MoviePurchaseJob = nil-- JobMoviePurchase:new()
end

function TaskNewsAgency:GetNextJobInTargetRoom()
	if (self.MoviePurchaseJob.Status ~= JOB_STATUS_DONE) then
		return self.MoviePurchaseJob
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobNewsAgency = AIJob:new{
}

function JobNewsAgency:Prepare(pParams)

end

function JobNewsAgency:Tick()

end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<