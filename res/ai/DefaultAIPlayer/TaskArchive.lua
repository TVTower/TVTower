_G["TaskArchive"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_ARCHIVE"]
	c.TargetRoom = TVT.ROOM_ARCHIVE_PLAYER_ME
	c.BudgetWeight = 0
	c.BasePriority = 1
	c.NeededInvestmentBudget = 0
	c.InvestmentPriority = 0

	c.Player = nil

	--no budget to spare
	c.RequiresBudgetHandling = false

	c.latestSaleOnDay = -1
end)

function TaskArchive:typename()
	return "TaskArchive"
end

function TaskArchive:Activate()
	self.Player = getPlayer()

	self.SellMoviesJob = JobSellMovies()
	self.SellMoviesJob.Task = self
	--self.LogLevel = LOG_TRACE
end

function TaskArchive:GetNextJobInTargetRoom()
	--nur einmal am Tag verkaufen, ausser im Notfall
	if self.latestSaleOnDay >= TVT.GetDay() then
		self:LogDebug("was here today, already")
	elseif (self.SellMoviesJob.Status ~= JOB_STATUS_DONE) then
		return self.SellMoviesJob
	end

	--self:SetWait()
	self:SetDone()
end


-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


_G["JobSellMovies"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil

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
			planned = -1;
			quality = 0;
			timesRun = 0;
			licence = nil;
		}
		t.Title = licence.GetTitle()
		t.GUID = licence.GetGUID()
		t.referenceId = licence.GetReferenceID()
		t.Id = licence.GetID()
		t.relativeTopicality = licence.GetRelativeTopicality()
		t.maxTopicality = licence.GetMaxTopicality()
		t.planned = licence.isPlanned()
		t.quality = licence.GetQualityRaw() * t.maxTopicality
		t.timesRun = licence:GetTimesBroadcasted(TVT.ME)
		t.licence = licence
		return t;
	end

	--fetch licences
	local nArchive = TVT.ar_GetProgrammeLicenceCount()
	local toSell = self.Task.Player.licencesToSell
	local toSellCount = table.count(toSell)
	self:LogDebug("# archived licences: "..nArchive.. ", marked for selling (including episodes) "..toSellCount)

	local movies = {}
	local case = {}
	local allIds = {}
	for i=0, (nArchive-1)
	do
		m = TVT.convertToProgrammeLicence(TVT.ar_GetProgrammeLicence(i).data)
		if m ~= nil and m.isAvailable() == 1 then
			table.insert(allIds, m.GetReferenceID())
			--ignore episodes/collection-elements
			if m.HasParentLicence()==0 then
				vm = newarchivedMovie(m)
				self:LogTrace("# found "..vm.Title.." (guid="..vm.GUID.."  id="..vm.Id.."), planned: "..tostring(vm.planned))
				if table.contains(toSell, vm.referenceId) then
					if vm.relativeTopicality > 0.99 then
						self:LogInfo("  placing "..vm.Title.." (max topicality "..vm.maxTopicality.. ", times run " ..vm.timesRun ..") into suitcase for selling")
						table.insert(case, vm)
					end
				else
					table.insert(movies,vm)
				end
			end
		end
	end

	--remove elements already sold
	for i=#toSell, 0, -1
	do
		if not table.contains(allIds, toSell[i]) then
			table.remove(toSell, i)
		end
	end

	local reach = self.Task.Player.totalReach
	local minLicenceCount = 35
	if reach == nil then
		-- should not happen
	elseif reach < 2300000 then
		minLicenceCount = 20
	elseif reach < 4700000 then
		minLicenceCount = 25
	end

	local newLicenceToSell = false
	--check if licence should be sold
	if table.count(movies) - toSellCount > minLicenceCount then
		local licenceToSell = self:determineLicenceToSell(movies, toSell)
		if licenceToSell ~= nil then
			newLicenceToSell = true
		end
	end

	self:LogDebug("# selected for suitcase: "..#case.. ", # marked for selling: " ..#toSell)
	-- move licences to suitcase
	for i=1, #case do
		ec = TVT.ar_AddProgrammeLicenceToSuitcaseByGUID(case[i].GUID)
		if ec == TVT.RESULT_OK then
			self:LogDebug("  put "..case[i].Title.." in suitcase, OK")

			self.Task.Player.programmeLicencesInArchiveCount = math.max(0, self.Task.Player.programmeLicencesInArchiveCount - 1)
			self.Task.Player.programmeLicencesInSuitcaseCount = self.Task.Player.programmeLicencesInSuitcaseCount + 1
		else
			self:LogError("# put "..case[i].Title.." in suitcase, errorcode: "..ec)
		end
	end

	self.Status = JOB_STATUS_DONE

	-- if there is something to sell, send figure to movie dealer now
	if table.count(case) > 0 or newLicenceToSell == true then
		--set day only if something is to be sold
		self.Task.latestSaleOnDay = TVT.GetDay()

		if self.Task.Player ~= nil then
			local t = self.Task.Player.TaskList[_G["TASK_MOVIEDISTRIBUTOR"]]
			if t ~= nil then
				self:LogDebug("# increasing SituationPriority for movie distributor task")
				t.SituationPriority = 150 --arbitrary value, maybe needs higher one
			end
		end
	end
end

function JobSellMovies:determineLicenceToSell(movies, toSell)
	local licenceToSell = nil
	local rnd = math.random(0,100)

	if rnd > 50 then
		local sortMethod = function(a, b)
			return a.quality < b.quality
		end
		table.sort(movies, sortMethod)
		local worstLicence = table.first(movies)
		self:LogDebug("worst licence (quality) ".. worstLicence.Title .."; planned "..worstLicence.planned )
	
		if worstLicence.timesRun >= 7 then
			licenceToSell = worstLicence
		end
	else
		local sortMethod = function(a, b)
			return a.maxTopicality < b.maxTopicality
		end
		table.sort(movies, sortMethod)
		local worstLicence = table.first(movies)
		self:LogDebug("worst licence (maxTopicality)".. worstLicence.Title .."; planned "..worstLicence.planned )
	
		if worstLicence.maxTopicality < 0.25 then
			licenceToSell = worstLicence
		end
	end

	if licenceToSell ~= nil then
		self:LogInfo("mark worst licence for selling: "..licenceToSell.Title)
		table.insert(toSell, licenceToSell.referenceId)

		local childCount =  licenceToSell.licence:GetSubLicenceCount()
		if childCount > 0 then
			for i=0, (childCount-1)
			do
				local child = licenceToSell.licence:GetSubLicenceAtIndex(i)
				if child ~= nil then
					table.insert(toSell, child:GetReferenceID())
				end
			end
		end

		table.removeElement(movies, licenceToSell)
	end
	return licenceToSell
end