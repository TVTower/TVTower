_G["TaskArchive"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_ARCHIVE"]
	c.TargetRoom = TVT.ROOM_ARCHIVE_PLAYER_ME
	c.BudgetWeight = 0
	c.BasePriority = 2
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0

	c.Player = nil

	--no budget to spare
	c.RequiresBudgetHandling = false

	c.latestSaleOnDay = -1
	c.emergencySale = false --todo: festlegen wann/ob der Notfall ist
end)

function TaskArchive:typename()
	return "TaskArchive"
end

function TaskArchive:Activate()
	self.Player = _G["globalPlayer"]

	self.SellMoviesJob = JobSellMovies()
	self.SellMoviesJob.Task = self
end

function TaskArchive:GetNextJobInTargetRoom()
	--nur einmal am Tag verkaufen, ausser im Notfall
	if self.latestSaleOnDay >= WorldTime.GetDay() and not self.emergencySale
	then
		debugMsg(timetostring().." archive Task, been here done that")
	elseif (self.SellMoviesJob.Status ~= JOB_STATUS_DONE) then
		debugMsg("return SellMoviesJob")
		return self.SellMoviesJob
	end

	self.emergencySale = false
	self:SetWait()
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


_G["JobSellMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
	-- sell movies which lost max topicality (so permanent) above these values
	c.MaxTopicalityLossTreshold = 0.75
	c.emergencyMaxTopicalityLossTreshold = 0.4

end)

function JobSellMovies:typename()
	return "JobSellMovies"
end

function JobSellMovies:Prepare(pParams)
	--refresh stats
	self.Task.Player.programmeLicencesInArchiveCount = TVT.ar_GetProgrammeLicenceCount()
	self.Task.Player.programmeLicencesInSuitcaseCount = TVT.ar_GetSuitcaseProgrammeLicenceCount()
end


function JobSellMovies:Tick()
	function newarchivedMovie (licence)
		local t =
		{
			Title = "N/A";
			GUID = "";
			Id = -1;
			TopicalityLoss = 1;
			MaxTopicalityLoss = 0;
			planned = -1;
			price = 0;
			licence = nil;
		}
		t.Title = licence.GetTitle()
		t.GUID = licence.GetGUID()
		t.Id = licence.GetID()
		t.TopicalityLoss = 1.0 - licence.GetRelativeTopicality()
		t.MaxTopicalityLoss = licence.GetRelativeMaxTopicalityLoss()
		t.planned = licence.isPlanned()
		t.price = licence.GetPrice(TVT.ME)
		t.licence = licence
		return t;
	end

	debugMsg("archive: Sell movies job started")
	--ins archiv wenn nach mitternacht (oben)

	self.Task.latestSaleOnDay = WorldTime.GetDay()


	--fetch licences
	local nArchive = TVT.ar_GetProgrammeLicenceCount()
	debugMsg ("# archived licences: "..nArchive)
	local movies = {};
	for i=0, (nArchive-1)
	do
		m = TVT.convertToProgrammeLicence(TVT.ar_GetProgrammeLicence(i).data)
		--ignore episodes/collection-elements
		if m ~= nil and m.HasParentLicence()==0 then
			vm = newarchivedMovie(m)
			debugMsg("# found "..vm.Title.." (guid="..vm.GUID.."  id="..vm.Id..") ".." "..vm.price..",  TopicalityLoss="..string.format("%.4f", vm.TopicalityLoss*100).."% (Max="..string.format("%.2f", vm.MaxTopicalityLoss*100).."%), planned: "..tostring(vm.planned))
			table.insert(movies,vm)
		end
	end


	-- check licences
	debugMsg("# checking single/series licences: "..#movies)
	-- filter by topicality, ignore planned
	-- in emergency raise bar to keep programme
	-- keep expensive ones (except their maximum topicality is too low)
	local useMaxTopicalityLossTreshold = self.MaxTopicalityLossTreshold
	if self.Task.emergencySale then useMaxTopicalityLossTreshold = self.emergencyMaxTopicalityLossTreshold end
	local case = {}
	for k,v in pairs (movies) do
		if v == nil then debugMsg("# ERROR: movie #" .. k.." is nil") end
		local sellIt = false
		-- sell when topicality will never raise enough again ("burned")
		if v.MaxTopicalityLoss > useMaxTopicalityLossTreshold then sellIt = true end
		-- sell when broadcasted too much and "maxtopicalityloss" wont
		-- change that much anymore
		if not sellIt and v.licence.GetMaxTopicality() < 0.2 and v.licence.GetTimesBroadcasted(TVT.ME) > 15 then sellIt = true end

		-- keep when planned
		if sellIt and v.planned > 0 then sellIt = false end

		if sellIt then
			debugMsg("# mark for suitcase: "..v.Title)
			table.insert(case,v)
		end
	end


	debugMsg("# selected for suitcase: "..#case)
	-- move licences to suitcase
	for i=1, #case do
		ec = TVT.ar_AddProgrammeLicenceToSuitcaseByGUID(case[i].GUID)
		if ec == 1 then
			debugMsg("# put "..case[i].Title.." in suitcase, OK")

			self.Task.Player.programmeLicencesInArchiveCount = math.max(0, self.Task.Player.programmeLicencesInArchiveCount - 1)
			self.Task.Player.programmeLicencesInSuitcaseCount = self.Task.Player.programmeLicencesInSuitcaseCount + 1
		else
			debugMsg("# put "..case[i].Title.." in suitcase, errorcode: "..ec)
		end
	end

	self.Status = JOB_STATUS_DONE

	-- if there is something to sell, send figure to movie dealer now
	if table.count(case) > 0 then
		if self.Task.Player ~= nil then
			local t = self.Task.Player.TaskList[_G["TASK_MOVIEDISTRIBUTOR"]]
			if t ~= nil then
				debugMsg("# increasing SituationPriority for movie distributor task")
				t.SituationPriority = 150 --arbitrary value, maybe needs higher one
			end
		end
	end
	debugMsg("archive: Sell movies job done")
end

function timetostring()
	local t = ""
	t = "Day: "..WorldTime.GetDay()..", "..WorldTime.GetDayHour().." : "..WorldTime.GetDayMinute()
	return t
end
