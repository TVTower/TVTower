_G["TaskArchive"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.TargetRoom = TVT.ROOM_ARCHIVE_PLAYER_ME
	c.BudgetWeight = 0
	c.BasePriority = 2
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0

	c.latestSaleOnDay = -1	
	c.emergencySale = false --todo: festlegen wann/ob der Notfall ist
end)

function TaskArchive:typename()
	return "TaskArchive"
end

function TaskArchive:Activate()
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
	c.FreshnessTreshold = 1.0	--change to sell movies with more/less Topicalty should be 0.8, changed for debug
	c.emergencyFreshnessTreshold = 1
	
end)

function JobSellMovies:typename()
	return "JobSellMovies"
end

function JobSellMovies:Prepare(pParams)

end


function JobSellMovies:Tick()
	function newarchivedMovie (a,b,c,d,e)
		local t = 
		{
			Title = "N/A";
			Id = -1;
			Freshness = 1;
			planned = -1;
			price = 0;
		}
		t.Title = a
		t.Id = b
		t.Freshness = c
		t.planned = d
		t.price = e
		return t;
	end

	debugMsg("archive Job entered")
	--ins archiv wenn nach mitternacht (oben)
	
	self.Task.latestSaleOnDay = WorldTime.GetDay()	
	
	--filmliste getten
	local nArchive = TVT.ar_GetProgrammeLicenceCount()
	--debugMsg ("# archived movies: "..nArchive)
	local movies = {};
	for i=0, (nArchive-1)
	do
		m = TVT.convertToProgrammeLicence(TVT.ar_GetProgrammeLicence(i).data)
		if m ~= nil then
			vm = newarchivedMovie(m.GetTitle(),m.GetId(),(m.GetTopicality() / m.GetMaxTopicality()),m.isPlanned(),m.GetPrice(TVT.ME))
			debugMsg("found "..vm.Title.." ("..vm.Id..") ".." "..vm.price..", "..(vm.Freshness*100).."%, planned: "..tostring(vm.planned))
			table.insert(movies,vm)
		end
	end
	--debugMsg("movies in archive: "..#movies)

	--Nach aktualität filtern, keine eingeplanten, im Notfall Schwelle fürs Behalten erhöhen, ganz teure immer behalten
	local treshold = self.FreshnessTreshold
	if self.Task.emergencySale then treshold = self.emergencyFreshnessTreshold end
	local case = {}
	for k,v in pairs (movies) 
	do
		if v == nil then debugMsg("archive error: movie is nil") end
		if (v.Freshness < self.FreshnessTreshold) and (v.planned ==  0) and (v.price < 100000)
		then
			debugMsg("archive: mark "..v.Title.." for suitcase")
			table.insert(case,v)
		end
	end
	
	debugMsg("archive: "..#case.." selected")

	--in koffer legen
	for i=1, #case
	do
		ec = TVT.ar_AddProgrammeLicenceToSuitcase(case[i].Id)  --braucht id, nicht position
		debugMsg("put "..case[i].Title.." in suitcase, errorcode: "..ec)
	end	
	
	self.Status = JOB_STATUS_DONE	
	--debugMsg("archive done")
	--leave archive klappt noch nicht
	--im md: verkaufen

	-- send figure to movie dealer now
	local player = _G["globalPlayer"]
	if player ~= nil then 
		local task = player.TaskList[_G["TASK_MOVIEDISTRIBUTOR"]]
		if task ~= nil then
			debugMsg("Increasing SituationPriority for movie distributor task")
			task.SituationPriority = 150 --arbitrary value, maybe needs higher one
		end
	end
end

function timetostring()
	local t = ""
	t = "Day: "..WorldTime.GetDay()..", "..WorldTime.GetDayHour().." : "..WorldTime.GetDayMinute()
	return t
end
