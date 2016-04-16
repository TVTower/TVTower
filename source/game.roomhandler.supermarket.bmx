SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.player.base.bmx"
Import "game.screen.supermarket.production.bmx"



Type RoomHandler_SuperMarket extends TRoomHandler
	Global _eventListeners:TLink[]
	Global _instance:RoomHandler_SuperMarket


	Function GetInstance:RoomHandler_SuperMarket()
		if not _instance then _instance = new RoomHandler_SuperMarket
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		'reset/initialize screens (event connection etc.)
		TScreenHandler_SupermarketProduction.GetInstance().Initialize()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		'handle the "office" itself (not computer etc)
		'using this approach avoids "tooltips" to be visible in subscreens
		_eventListeners :+ _RegisterScreenHandler( onUpdateSupermarket, onDrawSupermarket, ScreenCollection.GetScreen("screen_supermarket") )

		
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
		TScreenHandler_SupermarketProduction.GetInstance().SetLanguage()
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements in the production screen
		TScreenHandler_SupermarketProduction.GetInstance().AbortScreenActions()

		return False
	End Method
	

	Function onDrawSupermarket:int( triggerEvent:TEventBase )

	End Function


	Function onUpdateSupermarket:int( triggerEvent:TEventBase )
		If MOUSEMANAGER.IsClicked(1)
			MOUSEMANAGER.resetKey(1)
			GetGameBase().cursorstate = 0

			ScreenCollection.GoToSubScreen("screen_supermarket_production")
		endif

	End Function
End Type
