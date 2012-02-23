-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
TaskMoviePurchase = AITask:new{
	NiveauChecked = false;
	MovieCount = 0;
	CheckMode = 0;
	MovieList = nil;
	TargetRoom = TVT.ROOM_MOVIEAGENCY;
	MoviePurchaseJob = nil
}

function TaskMoviePurchase:typename()
	return "TaskMoviePurchase"
end

function TaskMoviePurchase:Activate()
	debugMsg("Starte Task 'TaskMoviePurchase'")
	-- Was getan werden soll:
	self.MoviePurchaseJob = nil-- JobMoviePurchase:new()
end

function TaskMoviePurchase:GetNextJobInTargetRoom()
	if (self.MoviePurchaseJob.Status ~= JOB_STATUS_DONE) then
		return self.MoviePurchaseJob
	end
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
JobMoviePurchase = AIJob:new{
	bla = 1
}

function JobMoviePurchase:Prepare()

end

function JobMoviePurchase:Tick()

end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<