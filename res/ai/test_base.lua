inOfficeFake = ROOM_OFFICE_PLAYER_ME

function OnMoneyChanged()
	--SendToChat("Hey mein Geld hat sich geaendert")
end

function OnDayBegins()
	TVT.SendToChat("Guten Morgen, ich schau mal beim Chef vorbei!")
	TVT.DoGoToRoom(ROOM_BOSS_PLAYER_ME)
end

function OnReachRoom(roomId)
	--SendToChat("Endlich im Raum angekommen")
end

function OnChat(chatvalue)
	TVT.SendToChat("mir wurde gesagt:" .. chatvalue)
end

function OnLeaveRoom()
	--SendToChat("Und raus aus dem Zimmer!")
end
--[[
-- wird intern jeder lua als _OnAssignPlayer(playerID) vorangestellt
function OnCreate(playerID)
	playerID = tonumber(playerID)
	TVT.DebugPrint("param : "..playerID)
	--param oder getPlayerID moeglich - eventuell kann die Funktion aber verzichtet werden
		if TVT.getPlayerID()	== 1 then TVT = TVTPlayer1 end
		if playerID				== 2 then TVT = TVTPlayer2 end
		if playerID				== 3 then TVT = TVTPlayer3 end
		if playerID				== 4 then TVT = TVTPlayer4 end
		if TVT == nil then	TVT.DebugPrint("Konnte TVT nicht setzen") end
end
]]

-- Funktion wird einmal pro Spielminute aufgerufen
function OnMinute(number)

-- auskommentieren wenn man alle KI-Spieler testen will
--  if ME ~= 2 then
--   return 0
--  end

	-----------------------------------------------------
	-- Sende Chatnachrichten an Mitspieler
	-----------------------------------------------------
    chatnumber = math.random(1,1000)
    chattext = math.random(1,9)
		--SendToChat( "Quote erwartet: " .. GetEvaluatedAudienceQuote(10025, 22) )

    if (chatnumber >= 300) and (chatnumber <= 303) then
	    if chattext == 1 then TVT.SendToChat("Ich mach Euch alle fertig. Hehe!!") end
	    if chattext == 2 then TVT.SendToChat("Man seid Ihr ein paar Looser!!") end
	    if chattext == 3 then TVT.SendToChat("Ene mene muh und raus bist DU!!") end
	    if chattext == 4 then TVT.SendToChat("In meinem Schatten wird's kalt ;).") end
	    if chattext == 5 then TVT.SendToChat("Wer den Euro nicht ehrt, ist die Zuschauer nicht wert.") end
	    if chattext == 6 then TVT.SendToChat("Bettys Raum hat die ID " .. TVT.GetRoom("betty", 0) ) end
	    if chattext == 7 then TVT.SendToChat("Pech im Spiel, Glück in der Liebe..." ) end
	    if chattext == 8 then TVT.SendToChat("Harr harr, Dein Chef wird dir die Löffel lang ziehen." ) end
	    if chattext == 9 then TVT.SendToChat("Nach mir die Sintflut." ) end
	  end

    -----------------------------------------------------

    --PrintOut("PlayerId: " .. ME .. "  Raum: " .. GetPlayerRoom(ME) .. "  Flur: " .. GetPlayerFloor(ME) .. "  ChatNumber: " .. chatnumber)

	-----------------------------------------------------
	-- Figur hat Zielposition erreicht
	-----------------------------------------------------
    if TVT.GetPlayerPosX(ME) == TVT.GetPlayerTargetPosX(ME) then
      randomnumber = math.random(200,600)

      TVT.SetPlayerTargetPosX(ME, randomnumber)
      if inOfficeFake == ROOM_OFFICE_PLAYER2 then
        TVT.DoGoToRoom(ROOM_OFFICE_PLAYER3)
        inOfficeFake = ROOM_OFFICE_PLAYER3
      else
        TVT.DoGoToRoom(ROOM_OFFICE_PLAYER2)
        inOfficeFake = ROOM_OFFICE_PLAYER2
      end
    end
  return PosX
end
