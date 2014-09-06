SuperStrict
'to access players current financial situation
Import "game.player.finance.bmx"
'to recognize players broadcasts in events
Import "game.player.programmeplan.bmx"
'to be able to send out toastmessages
Import "game.toastmessage.bmx"
'to access room data
Import "game.room.base.bmx"
'to access player data
Import "game.player.base.bmx"


Type TPlayerBossCollection
	Field bosses:TPlayerBoss[4]
	'playerID of player who sits in front of the screen
	'adjust this TOO when switching players
	Field playerID:Int = 1
	Global _instance:TPlayerBossCollection


	Function GetInstance:TPlayerBossCollection()
		if not _instance then _instance = new TPlayerBossCollection
		return _instance
	End Function


	Method Set:int(id:int=-1, boss:TPlayerBoss)
		If id = -1 Then id = playerID
		if id <= 0 Then return False

		If bosses.length < id Then bosses = bosses[..id+1]
		bosses[id-1] = boss

		'inform the boss about the new id
		if boss then boss.playerID = id
	End Method


	Method Get:TPlayerBoss(id:Int=-1)
		If id = -1 Then id = playerID
		If Not IsBoss(id) Then Return Null

		Return bosses[id-1]
	End Method


	Method GetCount:Int()
		return bosses.length
	End Method


	Method IsBoss:Int(number:Int)
		Return (number > 0 And number <= bosses.length And bosses[number-1] <> Null)
	End Method
	
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerBossCollection:TPlayerBossCollection()
	Return TPlayerBossCollection.GetInstance()
End Function
'return specific player boss
Function GetPlayerBoss:TPlayerBoss(playerID:int=-1)
	Return TPlayerBossCollection.GetInstance().Get(playerID)
End Function




'class containing information/values for the player's boss
Type TPlayerBoss
	'in which mood is the boss?
	Field mood:Int = 0
	'does the player have to visit the boss?
	Field awaitingPlayerVisit:Int = False
	'time the player has to visit the boss
	Field awaitingPlayerVisitTillTime:Long = 0
	'did the player accept and is on his way to the boss?
	Field awaitingPlayerAccepted:Int = False
	'did the boss create a toastmessage already?
	Field announcedAwaitingPlayerVisit:Int = False
	
	'in the case of the player sends a favorite movie, this might
	'brighten the mood of the boss
	Field favoriteMovieGUID:String = ""
	'things the boss wants to talk about
	Field talkSubjects:TPlayerBossTalkSubjects[]
	Field playerID:int = -1

	'event listeners - so we can remove them at the end
	Field _registeredListeners:TList = CreateList() {nosave}


	Method New()
		RegisterEvents()
	End Method

	Method Delete()
		UnRegisterEvents()
	End Method


	Method RegisterEvents:Int()
		EventManager.registerListenerMethod("broadcasting.finish", self, "onFinishBroadcasting")
		EventManager.registerListenerMethod("player.onEnterRoom", self, "onPlayerEnterRoom")
		EventManager.registerListenerMethod("player.onLeaveRoom", self, "onPlayerLeaveRoom")
		'instead of updating the boss way to often, we update each
		'boss once a ingame minute
		EventManager.registerListenerMethod("Game.OnMinute", self, "onGameMinute")
	End Method


	Method UnRegisterEvents:Int()
		For local link:TLink = EachIn _registeredListeners
			'variant a: link.Remove()
			'variant b: we never know if there happens something else
			EventManager.unregisterListenerByLink(link)
		Next
	End Method


	'=== EVENTS THE BOSS LISTENS TO ===
	Method onGameMinute:Int(triggerEvent:TEventSimple)
		Local minute:Int = triggerEvent.GetData().GetInt("minute",-1)
		Local hour:Int = triggerEvent.GetData().GetInt("hour",-1)
		Local day:Int = triggerEvent.GetData().GetInt("day",-1)

		'=== CHECK IF BOSS WANTS TO SEE PLAYER ===
		'await the player each day at 16:00
		If minute = 0 and hour = 16 and not awaitingPlayerVisit
			awaitingPlayerVisit = True
		EndIf
	

		'call the player if needed
		If awaitingPlayerVisit and not announcedAwaitingPlayerVisit
			CallPlayer()
		EndIf
	End Method

	
	Method onFinishBroadcasting:Int(triggerEvent:TEventSimple)
		'not interested in other channels ?!
		local programmePlan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not programmePlan or programmePlan.owner <> playerID then return False

		local broadcastMaterial:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("broadcastMaterial"))
		local broadcastedAsType:Int = triggerEvent.GetData().GetInt("broadcastedAsType",-1)

		'register malfunctions
		If not broadcastMaterial
			if broadcastedAsType = TBroadcastMaterial.TYPE_NEWSSHOW
				talkSubjects :+ [new TPlayerBossTalkSubjects.InitNewsMalfunctionSubject(broadcastMaterial)]
			elseif broadcastedAsType = TBroadcastMaterial.TYPE_PROGRAMME
				talkSubjects :+ [new TPlayerBossTalkSubjects.InitProgrammeMalfunctionSubject(broadcastMaterial)]
			endif
		endif
	End Method


	'called as soon as a player leaves the boss' room
	Method onPlayerLeaveRoom:Int(triggerEvent:TEventSimple)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room then return False
		'wrong room?
		if room.name <> "chief" or room.owner <> playerID then return False

		'only interested in the visit of the own player
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		if not player or playerID <> player.playerID then return False


		'reset boss announcement so boss can announce again
		announcedAwaitingPlayerVisit = False
	End Method

	
	'called as soon as a player enters the boss' room
	Method onPlayerEnterRoom:Int(triggerEvent:TEventSimple)
		local room:TRoomBase = TRoomBase(triggerEvent.GetReceiver())
		if not room then return False
		'wrong room?
		if room.name <> "chief" or room.owner <> playerID then return False

		'only interested in the visit of the own player
		local player:TPlayerBase = TPlayerBase(triggerEvent.GetSender())
		if not player or playerID <> player.playerID then return False

		'no longer await the visit of this player
		awaitingPlayerVisit = False


		'TODO: generate talks - for now, just remove what we collected
		print "TODO: GENERATE BOSS DIALOGUE !"

		local foundProgrammeMalfunctions:int = 0
		local foundNewsMalfunctions:int = 0
		For local subject:TPlayerBossTalkSubjects = EachIn talkSubjects
			if subject.subjectType = subject.TYPE_PROGRAMME_MALFUNCTION then foundProgrammeMalfunctions :+1
			if subject.subjectType = subject.TYPE_NEWS_MALFUNCTION then foundNewsMalfunctions :+1
		Next
		if foundProgrammeMalfunctions > 0 then print "TODO: TALK ABOUT "+foundProgrammeMalfunctions+"x MALFUNCTIONS."
		if foundNewsMalfunctions > 0 then print "TODO: TALK ABOUT "+foundNewsMalfunctions+"x MALFUNCTIONS."

		'just clear the talk subjects
		talkSubjects = new TPlayerBossTalkSubjects[0]
	End Method
	


	'call this method to request the player to visit the boss
	'-> this creates an event the game listens to and creates
	'   a toastmessage in the case of the active player, so they can react
	Method CallPlayer:Int()
		'give the player 2 hrs
		awaitingPlayerVisitTillTime = GetWorldTime().GetTimeGone() + 7200
		announcedAwaitingPlayerVisit = True
		awaitingPlayerAccepted = False

		'send out event that the boss wants to see his player
		EventManager.triggerEvent(TEventSimple.Create("playerboss.onCallPlayer", new TData.AddNumber("latestTime", awaitingPlayerVisitTillTime), Self, GetPlayerBaseCollection().Get(playerID)))
	End Method


	'call this so the boss knows: player is on his way to the boss
	'even if it could take a bit longer because of elevator and so on
	Method InformPlayerAcceptedCall:Int()
		awaitingPlayerAccepted = True
	End Method
End Type




Type TPlayerBossTalkSubjects
	Field subjectType:Int = 0
	'store specific objects in it
	'- broadcastmaterial
	'- audienceresults ...
	Field subjectObject:object
	Field changeMoodAmount:Int = 0

	'did the boss recognize that the player sent a malfunction?
	Const TYPE_PROGRAMME_MALFUNCTION:Int = 1
	Const TYPE_NEWS_MALFUNCTION:Int = 2
	'boss wants you to payback some credit
	Const TYPE_NEED_TO_PAYBACK_CREDIT:Int = 3
	Const TYPE_SENT_FAVORITE_PROGRAMME:Int = 4
	Const TYPE_WON_PRICE:Int = 5


	Method InitProgrammeMalfunctionSubject:TPlayerBossTalkSubjects(broadcastMaterial:TBroadcastMaterial)
		subjectType = TYPE_PROGRAMME_MALFUNCTION
		subjectObject = broadcastMaterial
		changeMoodAmount :- 5
		return self
	End Method

	Method InitNewsMalfunctionSubject:TPlayerBossTalkSubjects(broadcastMaterial:TBroadcastMaterial)
		subjectType = TYPE_NEWS_MALFUNCTION
		subjectObject = broadcastMaterial
		changeMoodAmount :- 2
		return self
	End Method
End Type