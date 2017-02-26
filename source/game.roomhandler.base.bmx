SuperStrict
Import Brl.Map
Import "game.gameconfig.bmx"
Import "game.figure.bmx"
Import "game.player.base.bmx"
Import "game.room.base.bmx"
Import "common.misc.screen.bmx"


Type TRoomHandlerCollection
	Field handlers:TMap = CreateMap()
	'instead of a temporary variable
	Global currentHandler:TRoomHandler

	Global _instance:TRoomHandlerCollection
	Global _eventListeners:TLink[]


	Function GetInstance:TRoomHandlerCollection()
		if not _instance then _instance = new TRoomHandlerCollection
		return _instance
	End Function


	'initialize all handlers and register events
	'called _before_ starting a game
	'called _before_ loading a savegame (-> old instances!)
	Method Initialize:int()
		'=== initialize all known handlers ===
		local initHandlers:TRoomHandler[]
		For local o:object = EachIn handlers.Values()
			'skip if already added
			local exists:int = False
			for local h:TRoomHandler = EachIn initHandlers
				if h = o then exists = True; exit
			next
			if exists then continue

			if TRoomHandler(o) then initHandlers :+ [TRoomHandler(o)]
		Next

		For local h:TRoomHandler = EachIn initHandlers
			h.Initialize()
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction( "room.onUpdate", onHandleRoom ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "room.onDraw", onHandleRoom ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "room.onBeginEnter", onHandleRoom ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "room.onFinishLeave", onHandleRoom ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "figure.onTryLeaveRoom", onHandleFigureInRoom ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "figure.onForcefullyLeaveRoom", onHandleFigureInRoom ) ]

		_eventListeners :+ [ EventManager.registerListenerFunction( "Language.onSetLanguage", onSetLanguage ) ]
		'== handle savegame loading ==
		'informing _old_ instances of the various roomhandlers
		_eventListeners :+ [ EventManager.registerListenerFunction( "SaveGame.OnBeginLoad", onSaveGameBeginLoad ) ]
		'informing _new_ instances of the various roomhandlers
		_eventListeners :+ [ EventManager.registerListenerFunction( "SaveGame.OnLoad", onSaveGameLoad ) ]
	End Method


	Method SetHandler(roomName:string, handler:TRoomHandler)
		handlers.insert(roomName, handler)
	End Method


	Method GetHandler:TRoomHandler(roomName:string = "")
		return TRoomHandler(handlers.ValueForKey(roomName))
	End Method





	'=== EVENTS FOR ALL HANDLERS ===
	
	Function onSetLanguage:int( triggerEvent:TEventBase )
		For local handler:TRoomHandler = EachIn GetInstance().handlers.Values()
			handler.SetLanguage()
		Next
	End Function
	

	'called _before_ a game (and its data) gets loaded
	Function onSaveGameBeginLoad:int( triggerEvent:TEventBase )
		For local handler:TRoomHandler = EachIn GetInstance().handlers.Values()
			handler.onSaveGameBeginLoad( triggerEvent )
		Next
	End Function


	'called _after_ a game (and its data) got loaded
	Function onSaveGameLoad:int( triggerEvent:TEventBase )
		TLogger.Log("TRoomHandlerCollection", "Savegame loaded - reassigning handlers", LOG_DEBUG | LOG_SAVELOAD)
		local oldHandlers:TRoomHandler[]
		For local o:object = EachIn GetInstance().handlers.Values()
			'skip if already added
			local exists:int = False
			for local h:TroomHandler = EachIn oldHandlers
				if h = o then exists = True; exit
			next
			if exists then continue

			if TRoomHandler(o) then oldHandlers :+ [TRoomHandler(o)]
		Next
		'request each handler to re-assign (the new instance of the handler)
		'ATTENTION: this allows to handle this individually for each
		'           handler. The alternative (storing a "handle:string"-
		'           property in each handler) would lead to problems
		'           as soon as some offices have varying handlers
		'           or a handler wants to take care of multiply rooms 
		GetInstance().handlers.Clear()

		For local handler:TRoomHandler = EachIn oldHandlers
			'this modifies "GetInstance().handlers"
			if handler then handler.RegisterHandler()
		Next

		'inform the (new) handlers
		For local handler:TRoomHandler = EachIn GetInstance().handlers.Values()
			handler.onSaveGameLoad( triggerEvent )
		Next
	End Function


	'=== EVENTS FOR INDIVIDUAL HANDLERS ===
	Function onHandleFigureInRoom:int( triggerEvent:TEventBase )
		local room:TRoomBase = TRoomBase( triggerEvent.GetReceiver())
		if not room then print "onHandleFigureInRoom: room stored elsewhere: "+triggerEvent._trigger.toLower()
		if not room then return 0

		currentHandler = GetInstance().GetHandler(room.name)
		if not currentHandler then return False

		Select triggerEvent._trigger.toLower()
			case "figure.ontryleaveroom"
				currentHandler.onTryLeaveRoom( triggerEvent )
			case "figure.onforcefullyleaveroom"
				currentHandler.onForcefullyLeaveRoom( triggerEvent )
		End Select
	End Function

	
	Function onHandleRoom:int( triggerEvent:TEventBase )
		local room:TRoomBase = TRoomBase( triggerEvent.GetSender())
		if not room then print "onHandleRoom: room stored elsewhere: "+triggerEvent._trigger.toLower()
		if not room then return 0

		currentHandler = GetInstance().GetHandler(room.name)
		if not currentHandler then return False
		
		Select triggerEvent._trigger.toLower()
			case "room.onupdate"
				if KeyManager.IsHit(KEY_ESCAPE)
					if currentHandler.AbortScreenActions()
						KeyManager.ResetKey(KEY_ESCAPE)
						KeyManager.BlockKey(KEY_ESCAPE, 150)
					endif
				endif
				currentHandler.onUpdateRoom( triggerEvent )
			case "room.ondraw"
				currentHandler.onDrawRoom( triggerEvent )
			case "room.onbeginenter"
				currentHandler.onEnterRoom( triggerEvent )
			case "room.onfinishleave"
				currentHandler.onLeaveRoom( triggerEvent )
		End Select
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomHandlerCollection:TRoomHandlerCollection()
	Return TRoomHandlerCollection.GetInstance()
End Function




Type TRoomHandler
	Method onUpdateRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onDrawRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onLeaveRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onEnterRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onTryLeaveRoom:int( triggerEvent:TEventBase ); return True; End Method
	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase ); return True; End Method
	Method onSaveGameLoad:int( triggerEvent:TEventBase ); return True; End Method
	'called during initialization and after savegame loading
	Method RegisterHandler:int() abstract
	'called to create all needed things (GUI) AND Reset
	Method Initialize:int() abstract
	'called to return to default state
	'Method Reset() abstract

	Method onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		'only handle the players figure
		if TFigure(triggerEvent.GetSender()) <> GetPlayerBase().figure then return False
		AbortScreenActions()
		return True
	End Method


	'call this function if the visual user actions need to get aborted
	Method AbortScreenActions:Int()
		return False
	End Method


	Method SetLanguage(); End Method


	'special events for screens used in rooms - only this event has the room as sender
	'screen.onScreenUpdate/Draw is more general purpose
	'returns the event listener links
	Function _RegisterScreenHandler:TLink[](updateFunc:int(triggerEvent:TEventBase), drawFunc:int(triggerEvent:TEventBase), screen:TScreen)
		local links:TLink[]
		if screen
			links :+ [ EventManager.registerListenerFunction( "room.onScreenUpdate", updateFunc, screen ) ]
			links :+ [ EventManager.registerListenerFunction( "room.onScreenDraw", drawFunc, screen ) ]
		endif
		return links
	End Function


	Function GetObservedFigure:TFigureBase()
		local figure:TFigureBase = TFigureBase(GetPlayerBase().GetFigure())
		'if we observe another figure, return this one
		if TFigureBase(GameConfig.GetObservedObject())
			return TFigureBase(GameConfig.GetObservedObject())
		else
			return TFigureBase(GetPlayerBase().GetFigure())
		endif
	End Function
	

	'returns wheather we observe a player and the player is in the given
	'room
	Function CheckPlayerInRoom:int(roomName:string, allowChangingRoom:int = true)
		local figure:TFigure = TFigure(GetPlayerBase().GetFigure())
		'if we observe another figure, return false as this check returns
		'wheather the player is the observed one and in a room
		if GameConfig.GetObservedObject() and figure <> GameConfig.GetObservedObject() then return False
		if not figure then return False

		'check if we are in the correct room
		If not allowChangingRoom and figure.isChangingRoom() Then Return False
		If not figure.inRoom Then Return False
		if figure.inRoom.name <> roomName then return FALSE
		return TRUE
	End Function
	

	Function CheckObservedFigureInRoom:int(roomName:string, allowChangingRoom:int = true)
		local figure:TFigure = TFigure(GameConfig.GetObservedObject())
		'when not observing someone, fall back to the players figure
		if not figure then figure = TFigure(GetPlayerBase().GetFigure())
		if not figure then return False

		'check if we are in the correct room
		If not allowChangingRoom and figure.isChangingRoom() Then Return False
		If not figure.inRoom Then Return False
		if figure.inRoom.name <> roomName then return FALSE
		return TRUE
	End Function


	Function IsRoomOwner:Int(figure:TFigure, room:TRoom)
		if not room then print "IsRoomOwner: room-object is null.";return False
		if not figure then print "IsRoomOwner: figure-object is null.";return False

		if not figure.playerID then return False

		return figure.playerID = room.owner
	End Function


	Function IsObservedFiguresRoom:int(room:TRoomBase)
		if not room then return False
		
		local figure:TFigure = TFigure(GameConfig.GetObservedObject())
		'when not observing someone, fall back to the players figure
		if not figure then figure = TFigure(GetPlayerBase().GetFigure())
		if not figure then return False

		'if a figure does not have a playerID it does not necessarily own
		'the room (postman, janitor ...)
		return (figure.playerID > 0) and figure.playerID = room.owner
	End Function


	Function IsPlayersRoom:int(room:TRoomBase)
		if not room then return False
		return GetPlayerBase().playerID = room.owner
	End Function


	Function IsObservedFigure:int(figure:TFigureBase)
		if not figure then return false
		return GameConfig.IsObserved(figure) or GetPlayerBaseCollection().playerID = figure.playerID
	End Function
End Type
