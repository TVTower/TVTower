SuperStrict
'to access players current financial situation
Import "game.player.finance.bmx"
'to recognize players broadcasts in events
Import "game.player.programmeplan.bmx"
'to be able to send out toastmessages
Import "game.toastmessage.bmx"


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
	End Method


	Method UnRegisterEvents:Int()
		For local link:TLink = EachIn _registeredListeners
			'variant a: link.Remove()
			'variant b: we never know if there happens something else
			EventManager.unregisterListenerByLink(link)
		Next
	End Method


	'=== EVENTS THE BOSS LISTENS TO ===

	Method onFinishBroadcasting:Int(triggerEvent:TEventSimple)
		'not interested in other channels ?!
		local programmePlan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		if not programmePlan or programmePlan.owner <> playerID then return False

		local broadcastMaterial:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("broadcastMaterial"))


		rem
		'toastmessage example
		'only send out messages for the active player!
		if self <> GetPlayerBossCollection().Get() then return False

		local toast:TGameToastMessage = new TGameToastMessage
		toast.SetMessageType(0)
		toast.SetCaption("Boss: Was zum Teufel?")
		toast.SetText("Sendeausfall ?!")
		'close after 5 ingame minutes
		toast.SetCloseAtWorldTime(GetWorldTime().GetTimeGone() + 300)
		'or close after 10 seconds
		toast.SetLifeTime(10)
		GetToastMessageCollection().AddMessage(toast, "TOPLEFT")
		end rem
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
End Type