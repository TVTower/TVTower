--naive support by assistant:
--  set ad with maximum income at the start of the broadcast
--  check news "just" before the news broadcast
function OnMinute(number)
	if number == "6" then
		TVT:DoGoToRoom(TVT.ROOM_OFFICE_PLAYER_ME) --implicitly check ads
	elseif number == "48" then
		TVT:DoGoToRoom(TVT.ROOM_NEWSAGENCY_PLAYER_ME) --implicitly update news
	end
end


--check ad at startup
function OnInit()
	TVT:doLeaveRoom(1)
	TVT:DoGoToRoom(TVT.ROOM_OFFICE_PLAYER_ME)
end

--one task per room, so the room determines what to do
function OnEnterRoom(roomId)
	local room = tonumber(roomId)
	if room == TVT.ROOM_OFFICE_PLAYER_ME then
		updateCurrentAd()
	elseif room == TVT.ROOM_NEWSAGENCY_PLAYER_ME then
		updateNewsBroadcast()
	end

	TVT:doLeaveRoom(1)
end


--#### in office check for best existing ad for the current slot
function updateCurrentAd()
	local day = TVT:GetDay()
	local hour = TVT:GetDayHour()
	local response = TVT:of_getAdContracts()
	local allContracts = {}
	local weights = {}

	--sort contracts by income
	for i, contract in ipairs(response:DataArray()) do
		if (contract ~= nil) then
			table.insert(allContracts, contract)
			weights[ contract:GetID() ] = (contract:GetProfit(-1) / contract:GetBlocks(0))
		end
	end
	local sortMethod = function(a, b)
		return weights[ a:GetID() ] > weights[ b:GetID() ]
	end
	table.sort(allContracts, sortMethod)

	--try each contract until one passes
	for k,v in pairs(allContracts) do
		result = TVT:of_setAdvertisementSlot(v, day, hour)
		if result == TVT.RESULT_OK then
			if TVT:CurrentAdvertisementRequirementsPassed() > 0 then
				--log("set ad "..v:GetTitle())
				return
			end
		end
	end
end


--#### in news agency, replace news with best available - no budget considerations
function updateNewsBroadcast()
	-- fetch a list of all news sorted by attractivity
	local newsList = GetNewsList()
	local CurrentBudget = 100000

	-- loop over all 3 slots
	for slot=1,3 do
		if (table.count(newsList) > 0) then
			local selectedNews = nil

			-- find the best one we can afford
			for i, news in ipairs(newsList) do
				price = news.GetPrice(TVT.ME)
				if (CurrentBudget >= price or news:IsPaid() == 1) then
					--skip setting if already done
					local existingNews = TVT:ne_getBroadcastedNews(slot-1).data

					-- we cannot compare objects generally, as their
					-- memory adress is different
					if existingNews == news then

					else
						if (news:IsPaid() == 1) then
							--log("- filling slot "..slot..". Re-use news: '" .. news.GetTitle() .. "'.")
						else
							--log("- filling slot "..slot..". Buying news: '" .. news.GetTitle() .. "' - Price: " .. price)
						end
						TVT.ne_doNewsInPlan(slot-1, news:GetGUID())
					end

					selectedNews = news

					-- remove from list, so next slot wont use that again
					table.remove(newsList, i)
				end
				-- do not search any longer
				if selectedNews ~= nil then break end
			end
		else
			--log("- filling slot "..slot..". No news available, skipping slot.")
		end
	end
end

-- retrieve a list of news candidates sorted by attractivity
function GetNewsList()
	local paidBonus = 0
	local currentNewsList = {}
	-- fetch all news, insert all available to a list
	-- fetch available ones
	local response = TVT.ne_getAllAvailableNews()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end
	local allNews = response.DataArray()
	for i, news in ipairs(allNews) do
		if news ~= nil then
			table.insert(currentNewsList, news)
		end
	end

	-- fetch news show news
	response = TVT:ne_getAllBroadcastedNews()
	if ((response.result == TVT.RESULT_WRONGROOM) or (response.result == TVT.RESULT_NOTFOUND)) then
		return {}
	end
	local broadcastedNews = response.DataArray()
	-- "pairs", not "ipairs" as the result might contains empty slots
	-- which "ipairs" does not like
	for i, news in pairs(broadcastedNews) do
		if news ~= nil then
			table.insert(currentNewsList, news)
		end
	end

	-- sort by attractivity modifed by paid-state-bonus
	-- precache complex weight calculation
	local weights = {}
	for k,v in pairs(currentNewsList) do
		local weight = v:GetQuality() * v:GetTopicality() * (1.0 + v:IsPaid() * paidBonus)
		weights[ v:GetID() ] = weight
	end
	local sortMethod = function(a, b)
		return weights[ a:GetID() ] > weights[ b:GetID() ]
	end
	table.sort(currentNewsList, sortMethod)


	return currentNewsList
end



--print to console
function log(message)
	TVT.PrintOut(message)
end

--helper from SLF.lua
table.count = function(pTable)
	if pTable == nil then return 0 end
	local Count = 0
	for k,v in pairs(pTable) do Count = Count + 1 end
	return Count
end


-- #### UNUSED EVENTS CALLED FROM THE GAME
function OnCreate()
end
function OnBossCalls(latestTimeString)
end
function OnBossCallsForced()
end
function OnMoneyChanged(value, reasonID, reference)	
end
function OnChat(message)
end
function OnDayBegins()
end
function OnLeaveRoom()
end
function OnReachTarget()
end
function OnReachRoom(roomId)
end
function OnBeginEnterRoom(roomId, result)
end
function OnSave()
	return ""
end
function OnLoad(data)
end
function OnRealTimeSecond(millisecondsPassed)
end
function OnTick(timeGone, ticksGone)
end
function OnMalfunction()
end