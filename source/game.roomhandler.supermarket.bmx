SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.player.base.bmx"
Import "game.screen.supermarket.bmx"
Import "game.screen.supermarket.production.bmx"
Import "game.screen.supermarket.presents.bmx"
Import "common.misc.dialogue.bmx"



Type RoomHandler_SuperMarket extends TRoomHandler
	Global _eventListeners:TEventListenerBase[]
	Global _instance:RoomHandler_SuperMarket


	Function GetInstance:RoomHandler_SuperMarket()
		if not _instance then _instance = new RoomHandler_SuperMarket
		return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		'reset/initialize screens (event connection etc.)
		TScreenHandler_Supermarket.GetInstance().Initialize()
		TScreenHandler_SupermarketProduction.GetInstance().Initialize()
		TScreenHandler_SupermarketPresents.GetInstance().Initialize()


		'=== REGISTER HANDLER ===

		RegisterHandler()


		'=== CREATE ELEMENTS ===


		' === REGISTER EVENTS ===

		' Remove all registered event listeners
		'EventManager.UnregisterListenersArray(_eventListeners)
		'_eventListeners = new TEventListenerBase[0]

		' Register event listeners
		' None yet
		

		' === REGISTER CALLBACKS ===
		
		' None yet


		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		'

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("supermarket", GetInstance())
	End Method


	Method SetLanguage()
		TScreenHandler_Supermarket.GetInstance().SetLanguage()
		TScreenHandler_SupermarketProduction.GetInstance().SetLanguage()
		TScreenHandler_SupermarketPresents.GetInstance().SetLanguage()
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'at least one handler did something?
		Local result:int = False

		'abort handling dragged elements in the production / present
		'screens (on normal screen maybe dialogue needs to be aborted)
		If TScreenHandler_Supermarket.GetInstance().AbortScreenActions()
			result = True
		EndIf
		If TScreenHandler_SupermarketProduction.GetInstance().AbortScreenActions()
			result = True
		EndIf
		If TScreenHandler_SupermarketPresents.GetInstance().AbortScreenActions()
			result = True
		EndIf

		Return result
	End Method
End Type
