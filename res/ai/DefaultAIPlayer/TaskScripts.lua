-- ##### CONSTANTS #####
PROD_STATUS_BUY              = "buy"
PROD_STATUS_GET_CONCEPTS     = "concept" --also used for checking studio state - if scripts need to be purchased
PROD_STATUS_SUPERMARKET      = "supermarket"
PROD_STATUS_START_PRODUCTION = "produce"
SAMMY_SIT_PRIORITY = 2

--TODO buy and keep good scripts for Sammy

-- File: TaskScripts
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["TaskScripts"] = class(AITask, function(c)
	AITask.init(c)	-- must init base!
	c.Id = _G["TASK_SCRIPTS"]
	c.BudgetWeight = 0
	c.BasePriority = 0
	c.PriorityBackup = c.BasePriority

	--TODO true - buying and paying production
	c.RequiresBudgetHandling = false
	c.prodStatus = PROD_STATUS_GET_CONCEPTS --check state on activation
	c.producedForSammy = false
	c.neededStudioSize = 1
end)

function TaskScripts:typename()
	return "TaskScripts"
end

function TaskScripts:Activate()
	self.JobBuyScript = JobBuyScript()
	self.JobBuyScript.Task = self
	self.JobGetConcepts = JobGetConcepts()
	self.JobGetConcepts.Task = self
	self.JobPlanProduction = JobPlanProduction()
	self.JobPlanProduction.Task = self
	self.JobStartProduction = JobStartProduction()
	self.JobStartProduction.Task = self
	self.awardType = ""

	if getPlayer().nextAwardType == TVT.Constants.AwardType.CULTURE or getPlayer().currentAwardType == TVT.Constants.AwardType.CULTURE then
		self.awardType = "culture"
	end

	--depending on state: buy script/bring to studio and get list/supermarket/start production
	if self.prodStatus == PROD_STATUS_BUY then
		self.TargetRoom = TVT.ROOM_SCRIPTAGENCY
	elseif self.prodStatus == PROD_STATUS_GET_CONCEPTS then
		self.TargetRoom = self:GetStudioId()
	elseif self.prodStatus == PROD_STATUS_SUPERMARKET then
		self.TargetRoom = TVT.ROOM_SUPERMARKET
	elseif self.prodStatus == PROD_STATUS_START_PRODUCTION then
		self.TargetRoom = self:GetStudioId()
	end

	--self.LogLevel = LOG_TRACE
end

function TaskScripts:GetStudioId()
	if self.neededStudioSize ~= nil then
		local studios = TVT.GetRoomsByDetails("studio", TVT.ME)
		for k,v in pairs(studios) do
			--self:LogInfo(v.id .." ".. v.GetSize().." "..self.neededStudioSize)
			if v.GetSize() >= self.neededStudioSize then
				return v.id
			end
		end
	end
	return TVT.GetFirstRoomByDetails("studio", TVT.ME).id
end

function TaskScripts:GetNextJobInTargetRoom()
	--depending on state: buy script/bring to studio and get list/supermarket/start production
	if (self.prodStatus == PROD_STATUS_BUY and self.JobBuyScript.Status ~= JOB_STATUS_DONE) then
		return self.JobBuyScript
	elseif (self.prodStatus == PROD_STATUS_GET_CONCEPTS and self.JobGetConcepts.Status ~= JOB_STATUS_DONE) then
		return self.JobGetConcepts
	elseif (self.prodStatus == PROD_STATUS_SUPERMARKET and self.JobPlanProduction.Status ~= JOB_STATUS_DONE) then
		return self.JobPlanProduction
	elseif (self.prodStatus == PROD_STATUS_START_PRODUCTION and self.JobStartProduction.Status ~= JOB_STATUS_DONE) then
		return self.JobStartProduction
	else
		self:LogInfo("  found nothing to do - status: " ..self.prodStatus)
	end

	self:SetDone()
end

function TaskScripts:getStrategicPriority()
	if getPlayer().hour > 18 then
		return 0.0
	elseif getPlayer().currentAwardType == TVT.Constants.AwardType.CUSTOMPRODUCTION or getPlayer().nextAwardType == TVT.Constants.AwardType.CULTURE then
		if self.producedForSammy == false then
			self.SituationPriority = SAMMY_SIT_PRIORITY
			if self.awardType == "culture" and self.prodStatus == PROD_STATUS_BUY then
				--no special strategic priority
			else
				return 5.0
			end
		end
	else
		self.producedForSammy = false
	end
	return 1.0
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobBuyScript"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobBuyScript:typename()
	return "JobBuyScript"
end

function JobBuyScript:Prepare(pParams)
	local player = getPlayer()
	local blocks = player.blocksCount
	self.scriptMaxPrice = 30000
	self.minPotential = 0.2
	self.minAttractivity = 0.35
	self.maxJobCount = 4
	if blocks > 64 then
		self.maxJobCount = 6
		self.Task.BasePriority = 0.15
		self.scriptMaxPrice = 1300000
		self.minPotential = 0.3
		self.minAttractivity = 0.65
	elseif blocks > 48 then
		self.maxJobCount = 5
		self.Task.BasePriority = 0.07
		self.scriptMaxPrice = 100000
		self.minPotential = 0.25
		self.minAttractivity = 0.55
	else
		self.scriptMaxPrice = 0	
	end
	if self.Task.awardType == "culture" then
		self.scriptMaxPrice = 300000
	end
	if self.Task.SituationPriority == SAMMY_SIT_PRIORITY then
		self.minPotential = self.minPotential - 0.1
		self.minAttractivity = self.minAttractivity - 0.1
	end
	if self.Task.minAttractivityMulti == nil then self.Task.minAttractivityMulti = self.minAttractivity end
	self.scriptMaxPrice =  math.min(self.scriptMaxPrice, player.money)
	self:LogDebug("  maxPrice  ".. self.scriptMaxPrice .. " minPotential "..self.minPotential)
end

function JobBuyScript:Tick()
	local response = TVT:da_getScripts()
	if response.result == TVT.RESULT_OK then
		local scripts = response.data
		local count = scripts:Count()
		
		local scCopy = {}
		for i=0, (count-1)
		do
			local script= scripts:ValueAtIndex(i)
			if script ~= nil then
				table.insert(scCopy, script)
			end
		end

		local sortByAttractivity = function(a, b)
			return self:getAttractivity(a) > self:getAttractivity(b)
		end

		table.sort(scCopy, sortByAttractivity)

		for k,script in pairs(scCopy) do
			if self:canBuy(script) == true then
				self:LogInfo("  buying script ".. script:getTitle().." attractivity ".. self:getAttractivity(script))
				TVT:da_buyScript(script)
				--less idling for remaining jobs
				self.Task.PriorityBackup = self.Task.BasePriority
				self.Task.BasePriority = self.Task.BasePriority * 5
				self.Task.prodStatus = PROD_STATUS_GET_CONCEPTS
				self.Task.neededStudioSize = script.requiredStudioSize
				if script:GetProductionLimit() > 1 then
					self.Task.minAttractivityMulti = self:getAttractivity(script)
				end 
				break
			end
		end
	end
	self.Task:SetDone()
	self.Status = JOB_STATUS_DONE
end

function JobBuyScript:getAttractivity(script)
	local potential = script:GetPotential()
	if script.isCulture() then potential = potential * 2 end

	if potential < self.minPotential then
		return -1
	else
		local attractivity = 0.4 * (script:GetSpeed() + script:GetReview()) + 0.2 * potential
		local genre = script:GetMainGenre()
		if genre == TVT.Constants.ProgrammeGenre.Horror then attractivity = attractivity * 0.75 end
		--if script:IsAlwaysLive() > 0 then attractivity = attractivity * 1.25 end
		return attractivity
	end
end

function JobBuyScript:canBuy(script)
	local cultureOverride = 0
	local player=getPlayer()
	local studioSize = player.maxStudioSize
	if self.Task.awardType == "culture" then
		if script:IsCulture() > 0 then
			cultureOverride = 1
		else
			return false
		end
	end

	--hard restrictions
	if script.requiredStudioSize > studioSize then
		return false
	elseif script:GetPrice() > self.scriptMaxPrice then
		return false
	elseif script:IsLive() > 0 and script:IsAlwaysLive() == 0 then
		return false
	elseif TVT:da_getJobCount(script) > self.maxJobCount and cultureOverride == 0 then
		return false
	elseif script:HasBroadcastTimeSlot() > 0 then
		return false
	elseif script:GetProductionLimit() > 1 and player.coverage < 0.15 then
		return false
	elseif script:IsSeries() == 1 then
		--TODO buy series only if enough money and not too much credit!!
		if self.scriptMaxPrice > 100000 then
			--not tested if check state fallback works for series with many episodes
			if script:GetEpisodes() > 8 then
				return false
			end
		else
			return false
		end
	end
	local attractivity = self:getAttractivity(script)

	--less hard restrictions
	if attractivity < self.minAttractivity then
		return false
	end
	if script:GetProductionLimit() > 1 and self.Task.minAttractivityMulti ~= nil and attractivity < self.Task.minAttractivityMulti then
		return false
	end 

	return true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobGetConcepts"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobGetConcepts:typename()
	return "JobGetConcepts"
end

function JobGetConcepts:Prepare(pParams)

end

function JobGetConcepts:Tick()
	local response = TVT:st_dropScriptAndGetConcepts()
	if response == TVT.RESULT_OK then
		self.Task.prodStatus = PROD_STATUS_SUPERMARKET
	elseif response == TVT.RESULT_NOTFOUND then
		--indicator that no script was in the studio - buy new one
		self.Task.prodStatus = PROD_STATUS_BUY
	else
		self:LogInfo("problem dropping script in studio")
	end
	self.Task:SetDone()
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobPlanProduction"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobPlanProduction:typename()
	return "JobPlanProduction"
end

function JobPlanProduction:Prepare(pParams)
	local player = getPlayer()
	local receivers = player.totalReceivers
	local blocks = player.blocksCount
	local money = player.money
	local credit = MY.GetCredit(-1)
	local lastDayProfit = player.Budget:GetLastDayProfit()
	local fixedCosts = player.Budget.CurrentFixedCosts

	--TODOin AI-code handle series budget better
	self.MaxBudget = 140000
	if money - credit < -1000000 then
		self.MaxBudget = 0
	elseif self.Task.awardType ~= "culture" and (player.money < 200000) then
		self.MaxBudget = 0
	elseif player.coverage > 0.1 and player.coverage < 0.2 then
		if money > 2000000 then
			self.MaxBudget = 1000000
		else
			self.MaxBudget = 600000
		end
	elseif player.coverage > 0.2 and player.coverage < 0.5 then
		if money > 3000000 then
			self.MaxBudget = 1500000
		else
			self.MaxBudget = 1000000
		end
	elseif player.coverage > 0.5 then
		if money > 7000000 then
			self.MaxBudget = 3000000
		else
			self.MaxBudget = 2000000
		end
	end
	--self:LogInfo("production budget is "..self.MaxBudget)
end

function JobPlanProduction:Tick()
	if self.MaxBudget > 0 then
		local response = TVT:sm_PlanProduction(self.MaxBudget, 0.7)
		if response == TVT.RESULT_OK then
			self.Task.prodStatus = PROD_STATUS_START_PRODUCTION
		else
			self:LogInfo("problem planning production")
		end
	else
		self:LogInfo(" no budget for planning production")
	end
	self.Task:SetDone()
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["JobStartProduction"] = class(AIJob, function(c)
	AIJob.init(c)	-- must init base!
	c.Task = nil
end)

function JobStartProduction:typename()
	return "JobStartProduction"
end

function JobStartProduction:Prepare(pParams)

end

function JobStartProduction:Tick()
	local response = TVT:st_StartProduction()
	if response == TVT.RESULT_OK then
		--restore original priority after production start
		self.Task.BasePriority = self.Task.PriorityBackup
		self:LogInfo("Start production")
	else
		self:LogInfo("problem starting production")
	end
	self.SituationPriority = 0
	self.producedForSammy = true
	--check state
	self.Task.prodStatus = PROD_STATUS_GET_CONCEPTS
	self.Task:SetDone()
	self.Status = JOB_STATUS_DONE
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
