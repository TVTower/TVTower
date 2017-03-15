SuperStrict
Import "Dig/base.gfx.gui.bmx"
Import "common.misc.datasheet.bmx"
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"


'RoomAgency
Type RoomHandler_RoomAgency extends TRoomHandler
	'rental or cancel rental?
	Field mode:int = 0
	Field selectedRoom:TRoomBase
	Field hoveredRoom:TRoomBase

	Global LS_roomagency_board:TLowerString = TLowerString.Create("roomagency")	
	Global _eventListeners:TLink[]
	Global _instance:RoomHandler_RoomAgency

	Const MODE_NONE:int = 0
	Const MODE_RENT:int = 1
	Const MODE_CANCELRENT:int = 2


	Function GetInstance:RoomHandler_RoomAgency()
		if not _instance then _instance = new RoomHandler_RoomAgency
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS =====
		'nothing up to now


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'react to changes (eg. cancel a buy/sell-selection if the selected
		'room changes owner)
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onBeginRental", onBeginOrCancelRoomRental) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onCancelRental", onBeginOrCancelRoomRental) ]

		'local screen:TScreen = ScreenCollection.GetScreen("screen_roomagency")
		'_eventListeners :+ _RegisterScreenHandler( onUpdateRoomAgency, onDrawRoomAgency, screen )

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
		GetRoomHandlerCollection().SetHandler("roomagency", GetInstance())
	End Method


	Method RemoveAllGuiElements:int()
		'
	End Method


	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure or not figure.playerID then return FALSE

		GetInstance().FigureEntersRoom(figure)
	End Method


	Function onBeginOrCancelRoomRental:int( triggerEvent:TEventBase )
		local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		if not room then return False

		local i:RoomHandler_RoomAgency = GetInstance()
		if i.selectedRoom and i.mode = MODE_RENT and not i.selectedRoom.IsRentable() then i.selectedRoom = null
		if i.selectedRoom and i.mode = MODE_CANCELRENT and i.selectedRoom.IsRentable() then i.selectedRoom = null
	End Function



	Method FigureEntersRoom:int(figure:TFigureBase)
		'=== FOR ALL PLAYERS ===

rem
		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'reorder AFTER refilling
			ResetContractOrder()
		endif
endrem
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		Render()
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		Update()
	End Method


	Method Update()
		if Keymanager.IsHit(KEY_TAB)
			if mode = MODE_NONE
				mode = MODE_RENT
			else
				mode = MODE_NONE
			endif
		endif
	
		if mode = MODE_RENT or mode = MODE_CANCELRENT
			UpdateRoomBoard()
		else
			'Update dialogue
		endif

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllGuiElements()
		endif
	End Method


	Method Render()
		SetColor(255,255,255)

		if mode = MODE_RENT or mode = MODE_CANCELRENT
			RenderRoomBoard()
		else
			'Dialogue
		endif

		'draw achievement-sheet
		'if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method


 	'=== ROOMBOARD ===


 	Method UpdateRoomBoard()
		hoveredRoom = null

		If selectedRoom and (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			selectedRoom = null
			MouseManager.ResetKey(2)
			MouseManager.ResetKey(1)
		EndIf


		GuiManager.Update( LS_roomagency_board )

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllRoomboardGuiElements()

			mode = MODE_NONE
		endif
 	End Method


 	Method RenderRoomBoard()
		'=== PANEL ===
		local skin:TDatasheetSkin = GetDatasheetSkin("RoomAgencyBoard")

		'where to draw
		local outer:TRectangle = new TRectangle.Init(25,25, 750, 350)
		'calculate position/size of content elements
		local contentX:int = 0
		local contentY:int = 0
		local contentW:int = 0
		local contentH:int = 0
		local outerSizeH:int = skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		local outerH:int = 0 'size of the "border"
		local titleH:int = 18

		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(GetLocale("ROOM_OVERVIEW"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, contentH - titleH , "2")

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())


		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			if not sign.imageCache
				sign.imageCache = sign.GenerateCacheImage( GetSpriteFromRegistry(sign.imageBaseName + Max(0, sign.door.GetOwner())) )
			endif

			local x:int = 45 + (sign.door.doorSlot-1) * 180 
			local y:int = 50 + (13 - sign.door.onFloor) * 23 
			sign.imageCache.Draw(x,y)
		Next



		GuiManager.Draw( LS_roomagency_board )
 	End Method


	Method RemoveAllRoomboardGuiElements:int()
		'
	End Method
End Type
