'SuperStrict
'Import "game.player.programmeplan.bmx"
'Import "game.broadcast.audienceresult.bmx"
'Import "game.publicimage.bmx"
'Import "game.figure.bmx"


Type TPlayerCollection extends TPlayerBaseCollection
	Global _registeredEvents:int = False


	Method New()
		if not _registeredEvents
			EventManager.registerListenerFunction("figure.onEnterRoom", OnFigureEnterRoom)
			_registeredEvents = True
		endif
	End Method


	'override - create a PlayerCollection instead of PlayerBaseCollection
	Function GetInstance:TPlayerCollection()
		if not _instance
			_instance = new TPlayerCollection
		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TPlayerCollection(_instance)
			local collection:TPlayerCollection = new TPlayerCollection
			collection.players = _instance.players
			collection.playerID = _instance.playerID
			'now the new collection is the instance
			_instance = collection
		endif
		return TPlayerCollection(_instance)
	End Function


	Method Get:TPlayer(id:Int=-1)
		return TPlayer(Super.Get(id))
	End Method


	Method GetByFigure:TPlayer(figure:TFigure)
		'check all players if this was their figure
		For local player:TPlayer = EachIn players
			if player.figure = figure then return player
		Next
		return null
	End Method


	'override to return "true" only for TPlayer but not TPlayerBase
	Method IsPlayer:Int(number:Int)
		Return (number > 0 And number <= players.length And TPlayer(players[number-1]))
	End Method
	

	Method IsHuman:Int(number:Int)
		Return (IsPlayer(number) And Not TPlayer(Get(number)).GetFigure().IsAI())
	End Method


	'the negative of "isHumanPlayer" - also "no human player" is possible
	Method IsAI:Int(number:Int)
		Return (IsPlayer(number) And TPlayer(Get(number)).GetFigure().IsAI())
	End Method


	Method IsLocalPlayer:Int(number:Int)
		Return IsLocalPlayer(number)
	End Method


	'=== EVENTS ===
	'events
	Function OnFigureEnterRoom:int(triggerEvent:TEventBase)
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or figure.playerID = 0 then return False

		'alternatively search by "playerID" - but maybe we delete that
		'property somewhen
		local player:TPlayer = GetInstance().GetByFigure(figure)
		if not player then return False

		'send out event: player entered room
		local door:object = triggerEvent.GetData().Get("door")
		local room:TRoom = TRoom(triggerEvent.GetData().Get("room"))
		if not room then return False
		EventManager.triggerEvent( TEventSimple.Create("player.onEnterRoom", new TData.Add("door", door), player, room) )
		
	 	'inform player AI that figure entered a room
	 	If player.isAI() Then player.PlayerKI.CallOnEnterRoom(room.id)
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPlayerCollection:TPlayerCollection()
	Return TPlayerCollection.GetInstance()
End Function
'return specific player
Function GetPlayer:TPlayer(playerID:int=-1)
	Return TPlayer(TPlayerCollection.GetInstance().Get(playerID))
End Function



'class holding name, channelname, infos about the figure, programmeplan, programmecollection and so on - from a player
Type TPlayer extends TPlayerBase {_exposeToLua="selected"}
	Field PlayerKI:KI


	Method onLoad:int(triggerEvent:TEventBase)
		if IsAi()
			'reconnect AI engine
			PlayerKI.Start()
			'load savestate
			PlayerKI.CallOnLoad()
		endif
	End Method


	Method GetFigure:TFigure()
		return TFigure(figure)
	End Method


	'returns whether a player contains a player AI
	Method IsAI:Int() {_exposeToLua}
		Return playerKI<>null
	End Method


	Method GetStationMap:TStationMap() {_exposeToLua}
		'fetch from StationMap-list
		local map:TStationMap = GetStationMapCollection().GetMap(playerID)
		'still not existing - create it
		if not map then map = TStationMap.Create(self.playerID)
		return map
	End Method


	'make public image available for AI/Lua
	Method GetPublicImage:TPublicImage()	{_exposeToLua}
		return GetPublicImageCollection().Get(playerID)
	End Method


	Method GetProgrammeCollection:TPlayerProgrammeCollection() {_exposeToLua}
		return GetPlayerProgrammeCollectionCollection().Get(playerID)
	End Method


	Method GetProgrammePlan:TPlayerProgrammePlan() {_exposeToLua}
		return GetPlayerProgrammePlanCollection().Get(playerID)
	End Method


	Method GetMaxAudience:Int() {_exposeToLua}
		Return GetStationMap().GetReach()
	End Method


	Method isInRoom:Int(roomName:String="", checkFromRoom:Int=False) {_exposeToLua}
		If checkFromRoom
			'from room has to be set AND inroom <> null (no building!)
			Return (GetFigure().inRoom And GetFigure().inRoom.Name.toLower() = roomname.toLower()) Or (GetFigure().inRoom And GetFigure().fromRoom And GetFigure().fromRoom.Name.toLower() = roomname.toLower())
		Else
			Return (GetFigure().inRoom And GetFigure().inRoom.Name.toLower() = roomname.toLower())
		EndIf
	End Method


	'creates and returns a player
	'-creates the given playercolor and a figure with the given
	' figureimage, a programmecollection and a programmeplan
	Function Create:TPlayer(playerID:int, Name:String, channelname:String = "", sprite:TSprite, x:Int, onFloor:Int = 13, dx:Int, color:TColor, ControlledByID:Int = 1, FigureName:String = "")
		Local Player:TPlayer = New TPlayer

		Player.Name	= Name
		Player.playerID	= playerID
		Player.color = color.AddToList(True).SetOwner(playerID)
		Player.channelname = channelname
		Player.Figure = New TFigure.Create(FigureName, sprite, x, onFloor, dx, ControlledByID)
		Player.Figure.playerID = playerID

		TPublicImage.Create(Player.playerID)
		new TPlayerProgrammeCollection.Create(playerID)
		new TPlayerProgrammePlan.Create(playerID)

		'create a new boss for the player
		GetPlayerBossCollection().Set(playerID, new TPlayerBoss)

		Player.RecolorFigure(Player.color)

		Player.UpdateFigureBase(0)

		Return Player
	End Function



	Method SetAIControlled(luafile:String="")
		figure.controlledByID = 0
		PlayerKI = new KI.Create(playerID, luafile)
		PlayerKI.Start()
	End Method


	'remove this helper as soon as "player" class gets a single importable
	'file
	Method SendToBoss:Int()
		GetFigure().SendToDoor( TRoomDoor.GetByDetails("boss", playerID), True )

		'inform the boss that the player accepted the call
		GetPlayerBossCollection().Get(playerID).InformPlayerAcceptedCall()
	End Method


	'return which is the highest level for the given genre today
	'(which was active for longer than X game minutes)
	'if the last time a abonnement level was set was before today
	'use the current level value
	Method GetNewsAbonnementDaysMax:Int(genre:Int)
		If genre > 5 Then Return 0 'max 6 categories 0-5

		'not set yet - use the current abonnement
		if newsabonnementsDayMax[genre] = -1
			SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
		endif

		'if level of genre changed - adjust maximum
		if newsabonnementsDayMax[genre] <> newsabonnements[genre]
			'if the "set time" is not the current day, we assume
			'the current abonnement level as maxium
			'eg.: genre set 23:50 - not catched by the "30 min check"
			'also a day change sets maximum even if level is lower than
			'maximum (which is not allowed during day to pay for the best
			'level you had this day)
			if GetWorldTime().GetDay(newsabonnementsSetTime[genre]) < GetWorldTime().GetDay()
				'NOT 0:00 (the time daily costs are computed)
				if GetWorldTime().GetDayMinute() > 0
					SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
				EndIf
			EndIf

			'more than 30 mins gone since last "abonnement set"
			if GetWorldTime().GetTimeGone() - newsabonnementsSetTime[genre] > 30*60
				'only set maximum if the new level is higher than the
				'current days maxmimum.
				if newsabonnementsDayMax[genre] < newsabonnements[genre]
					SetNewsAbonnementDaysMax(genre, newsabonnements[genre])
				EndIf
			EndIf
		EndIf

		return newsabonnementsDayMax[genre]
	End Method


	'sets the current maximum level of a news abonnement level for that day
	Method SetNewsAbonnementDaysMax:Int(genre:Int, level:int)
		If genre > 5 Then Return 0 'max 6 categories 0-5
		newsabonnementsDayMax[genre] = level
	End Method


	'return CURRENT newsAbonnement
	Method GetNewsAbonnement:Int(genre:Int) {_exposeToLua}
		If genre > 5 Then Return 0 'max 6 categories 0-5
		Return Self.newsabonnements[genre]
	End Method


	Method IncreaseNewsAbonnement(genre:Int) {_exposeToLua}
		SetNewsAbonnement( genre, GetNewsAbonnement(genre)+1 )
	End Method


	Method SetNewsAbonnement(genre:Int, level:Int, sendToNetwork:Int = True) {_exposeToLua}
		If level > GameRules.maxAbonnementLevel Then level = 0 'before: Return
		If genre > 5 Then Return 'max 6 categories 0-5
		If newsabonnements[genre] <> level
			newsabonnements[genre] = level
			'set at which time we did this
			newsabonnementsSetTime[genre] = GetWorldTime().GetTimeGone()

			If Game.networkgame And Network.IsConnected And sendToNetwork Then NetworkHelper.SendNewsSubscriptionChange(Self.playerID, genre, level)
		EndIf
	End Method


Rem
	'calculates and returns the percentage of the players audience depending on the maxaudience
	Method GetRelativeAudiencePercentage:Float(playerID:Int) {_exposeToLua}
		Return TAudienceResult.Curr(playerID).AudienceQuote.GetAverage()
	End Method
endrem


	'returns value boss will give as credit
	Method GetCreditAvailable:Int() {_exposeToLua}
		Return Max(0, CreditMaximum - GetFinance().credit)
	End Method


	'returns formatted value of actual money
	Method GetMoneyFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).money, 2)
	End Method


	'attention: when used through LUA without param, the param gets "0"
	'instead of "-1"
	Method GetMoney:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).money
	End Method


	'returns formatted value of actual credit
	Method GetCreditFormatted:String(day:Int=-1)
		Return TFunctions.convertValue(GetFinance(day).credit, 2)
	End Method


	Method GetCredit:Int(day:Int=-1) {_exposeToLua}
		Return GetFinance(day).credit
	End Method
End Type