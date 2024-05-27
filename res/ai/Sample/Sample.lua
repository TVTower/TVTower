--[[
	TVT.*** functions:
	defined in "source/game.ai.bmx" as "TLuaFunctions"

	Events:
	defined in "source/game.ai.base.bmx"
]]--


-- on the very first start of a game, each figure is send to a
-- specific spot in the building. you cannot control it until it
-- reaches that spot ... so we use a helper variable to send it
-- to the boss right after start
visitBossAtStart = true



 
-- #### EVENTS CALLED FROM THE GAME
function OnCreate()
	TVT.PrintOut("Sample AI file loaded for player #" .. TVT.ME)
end

function OnBossCalls(latestTimeString)
	TVT.PrintOut("Boss calls me! " .. latestTimeString)
end


function OnBossCallsForced()
	TVT.PrintOut("Boss calls me NOW!")
end


function OnMoneyChanged(value, reasonID, reference)	
	TVT.PrintOut("My money has changed value=".. value .. " reasonID="..reasonID)
end


function OnChat(message)
	TVT.PrintOut("Someone send m a chat message: " .. message)
end


function OnDayBegins()
	TVT.PrintOut("ohhh, a new day begins " .. TVT.GetFormattedTime("H:i"))
	TVT.SendToChat("Guten Morgen, ich schau mal beim Chef vorbei!")
	-- does not work that way - not controllable at the very first
	-- start, so this only works for days > 1
	TVT.doGoToRoom(TVT.ROOM_BOSS_PLAYER_ME)
end


function OnLeaveRoom()
	TVT.PrintOut("OnLeaveRoom")
end

-- figure approached the target room - will try to open the door soon
function OnReachRoom(roomId)
	TVT.PrintOut("OnReachRoom roomId=" .. roomId)
end

-- figure is now trying to enter this room ("open door")
function OnBeginEnterRoom(roomId, result)
	TVT.PrintOut("OnBeginEnterRoom" .. roomId .. " result=" .. result)
end

-- figure is now in this room
function OnEnterRoom(roomId)
	TVT.PrintOut("OnEnterRoom " .. roomId)

	-- IMPORTANT ... we must convert to a number before!!
	if tonumber(roomId) == TVT.ROOM_BOSS_PLAYER_ME then
		TVT.SendToChat("Nix neues vom Chef, ab ins Buero!")
		TVT.doGoToRoom(TVT.ROOM_OFFICE_PLAYER_ME)
	end

	-- wir muessen "tonumber()" nutzen, da parameter automatisch als
	-- string bzw "object" von TVTower/Blitzmax uebergeben werden
	if tonumber(roomId) == TVT.ROOM_OFFICE_PLAYER_ME then
		-- rufe die Funktion von TVTower auf
		-- -1, -1 = aktueller Tag, aktuelle Stunde
		local request = TVT.of_getAdvertisementSlot(-1, -1)
		local result = request.result
		local ad = request.data
		--wichtig: als Zahl ansprechen
		if result == TVT.RESULT_OK then
			if ad ~= nil then
				TVT.SendToChat("aktuelle Werbung: " .. ad.GetTitle())
			end
		else
			TVT.SendToChat("Abfrage fehlgeschlagen. Grund: " .. result)
		end
	end
end

-- figure is now at the desired target
function OnReachTarget()
	TVT.PrintOut("OnReachTarget")

	-- this is called each time a figure reaches its target
	-- -> eg. the specific spot in the building at the game start
	if visitBossAtStart == true then
		TVT.SendToChat("Erzwungenen Startpunkt erreicht, nun zum Chef!")
		TVT.doGoToRoom(TVT.ROOM_BOSS_PLAYER_ME)
		visitBossAtStart = false
	end
end


function OnSave()
	TVT.PrintOut("Game is saved - returning serialized data")
	return "1234"
end


function OnLoad(data)
	TVT.PrintOut("Should deserialize now from this data: " .. data)
end


function OnRealTimeSecond(millisecondsPassed)
	--TVT.PrintOut("a real time second passed")
end


function OnTick(timeGone, ticksGone)
	--TVT.PrintOut("OnTick  time:" .. timeGone .." ticks:" .. ticksGone)
end


function OnMinute(number)
	--TVT.PrintOut("A ingame minute passed")
end


function OnMalfunction()
	TVT.PrintOut("Ooops I forgot to send something!")
end