-- ##### EVENTS #####
function OnMoneyChanged()
debugMsg("1");
end

function OnChat(message)
debugMsg("2");
end

function OnDayBegins()
debugMsg("3");
end

function OnReachRoom(roomId)
debugMsg("4");
end

function OnLeaveRoom()
debugMsg("5");
end

function OnMinute(number)
debugMsg("6");
end

function debugMsg(pMessage)
	if ME == 2 then --Nur Debugausgaben von Spieler 2
		SendToChat(ME .. ": " .. pMessage)
	end
end