SuperStrict
Import "Dig/base.gfx.gui.bmx"
Import "common.misc.datasheet.bmx"
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.roomagency.bmx"


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

		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			if not room then continue
			'ignore never-rentable rooms
			if room.IsFake() or room.IsFreeHold() then continue

			if not sign.imageCache
				sign.imageCache = sign.GenerateCacheImage( GetSpriteFromRegistry(sign.imageBaseName + Max(0, sign.door.GetOwner())) )
			endif

			local x:int = 42 + (sign.door.doorSlot-1) * 179 
			local y:int = 40 + (13 - sign.door.onFloor) * 23

			if THelper.MouseIn(x,y, sign.imageCache.GetWidth(), sign.imageCache.GetHeight())
				hoveredRoom =  TRoomDoor(sign.door).GetRoom()

				if MouseManager.IsClicked(1)
					selectedRoom = null
					'only select the room if it is allowed
					if (mode = MODE_RENT and hoveredRoom.IsRentable()) or ..
					   (mode = MODE_CANCELRENT and hoveredRoom.GetOwner() = GetPlayerBase().playerID)
						selectedRoom = hoveredRoom
					endif

					'handled button hit
					MouseManager.ResetKey(1)
				endif
				
				exit
			endif
		Next


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
		local outer:TRectangle = new TRectangle.Init(30,10, 740, 366)
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
		if mode = MODE_RENT
			GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(GetLocale("ROOM_OVERVIEW")+": " + GetLocale("SELECT_ROOM_TO_RENT"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		else
			GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(GetLocale("ROOM_OVERVIEW")+": " + GetLocale("SELECT_ROOM_TO_CANCEL"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, contentH - titleH , "2")

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

		local oldCol:TColor = new TColor.Get()
		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			if not room then continue
		
			if not sign.imageCache
				sign.imageCache = sign.GenerateCacheImage( GetSpriteFromRegistry(sign.imageBaseName + Max(0, sign.door.GetOwner())) )
			endif

			local x:int = 42 + (sign.door.doorSlot-1) * 179 
			local y:int = 40 + (13 - sign.door.onFloor) * 23

			if mode = MODE_RENT
				if room and not room.IsRentable()
					SetAlpha oldCol.a * 0.75
				endif
			elseif mode = MODE_CANCELRENT
				if room and room.GetOwner() <> GetPlayerBase().playerID
					SetAlpha oldCol.a * 0.75
				endif
			endif

			'ignore never-rentable rooms
			if room.IsFake() or room.IsFreeHold() then SetAlpha oldCol.a * 0.3


			sign.imageCache.Draw(x,y)

			if room = selectedRoom
				SetBlend LIGHTBLEND
				SetAlpha 0.15
				SetColor 255,210,190
				sign.imageCache.Draw(x,y)
				SetBlend ALPHABLEND
				oldCol.SetRGBA()
			endif
			if room = hoveredRoom
				SetBlend LIGHTBLEND
				SetAlpha 0.10
				sign.imageCache.Draw(x,y)
				SetBlend ALPHABLEND
				oldCol.SetRGBA()
			endif
				

			oldCol.SetRGBA()
		Next

		GuiManager.Draw( LS_roomagency_board )

		if hoveredRoom
			DrawRoomSheet(hoveredRoom, 400,50)
		endif
 	End Method


 	Method UpdateRoomSheet(room:TRoomBase, x:int, y:int)
 	End Method
 	

 	Method DrawRoomSheet(room:TRoomBase, x:int, y:int, align:int = 0)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 340
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local title:string = room.GetDescription(1)
		local currentPlayerID:int = GetPlayerBaseCollection().playerID
		local finance:TPlayerFinance = GetPlayerFinance(currentPlayerID)
		local canAfford:int = finance and finance.canAfford( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) )

		'=== PANEL ===
		local skin:TDatasheetSkin = GetDatasheetSkin("RoomDatasheet")

		'== where to draw
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()

		'== calculate special area heights
		local titleH:int = 18, descriptionH:int = 80, ownerInfoH:int = 60
		local splitterHorizontalH:int = 6
		local boxH:int = 0, boxAreaH:int = 0
		local boxAreaPaddingY:int = 4
		local ownerInfo:int = True

		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(title, contentW - 10, 100))

		'== box area
		boxH = skin.GetBoxSize(80, -1, "", "spotsPlanned", "neutral").GetY()
		'contains 1 line of boxes
		boxAreaH = 1 * boxH + boxAreaPaddingY

		'== total height
		sheetHeight = titleH + descriptionH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		if ownerInfo
			'there is a splitter between description and owner info...
			sheetHeight :+ splitterHorizontalH
			sheetHeight :+ ownerInfoH
		endif


		
		'=== RENDER ===
	
		'== title area
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			if titleH <= 18
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH
		
		'== description area
		skin.RenderContent(contentX, contentY, contentW, descriptionH, "2")
		'hier abhaengig von floor/doorslot/... Zufallstexte verteilen
		'bzw. "cachen"
		'der Text sollte "x.000 Miete pro Spieltag und eine einmalige Provision von y.000"
		'enthalten, um die unteren Zahlen zu erklaeren
		skin.fontNormal.drawBlock("Wohl dimensionierter Raum der Größe "+ room.GetSize()+". Günstig nahe dem Supermarkt gelegen und für nur " + MathHelper.DottedValue(room.GetRentForPlayer(currentPlayerID)) +" Miete/Spieltag verfügbar.~nBei Unterzeichnung wird eine einmalige Zahlung von "+ MathHelper.DottedValue( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) ) +" Euro fällig.", contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
		contentY :+ descriptionH

		if ownerInfo
			local ownerInfo:string = room.GetDescription(1, True)
			local ownerInfo2:string = room.GetDescription(2, True)
			if ownerInfo2 then ownerInfo :+ "~n" + ownerInfo2

			local ownerRerentInfo:string
			local rerentalTime:Long = Max(0, room.GetRerentalTime() - GetWorldTime().GetTimeGone())
			if room.IsRented()
				ownerRerentInfo = GetLocale("IN_XTIME_AFTER_CANCELLATION")
				rerentalTime = room.GetRerentalWaitingTime()
			else
				ownerRerentInfo = GetLocale("IN_XTIME")
			endif
			local hours:int = rerentalTime / 3600
			local minutes:int = (rerentalTime - hours*3600) / 60
			local timeString:string = RSet(hours,2).Replace(" ","0")+":"+RSet(minutes,2).Replace(" ","0")
			if hours > 1
				timeString = timeString + " " + GetLocale("HOURS")
			elseif hours = 1
				timeString = timeString + " " + GetLocale("HOUR")
			else
				if minutes <> 1
					timeString = minutes + " " + GetLocale("MINUTES")
				else
					timeString = minutes + " " + GetLocale("MINUTE")
				endif
			endif
			ownerRerentInfo = ownerRerentInfo.Replace("%X%", timeString)
			

			'splitter
			skin.RenderContent(contentX, contentY, contentW, splitterHorizontalH, "1")
			contentY :+ splitterHorizontalH

			'owner info
			skin.RenderContent(contentX, contentY, contentW, ownerInfoH, "2")

			local leftWidth:int  = (contentW - 10) * 0.6
			local leftRightSplitter:int = 10
			local rightWidth:int = (contentW - 10) - leftWidth - leftRightSplitter
			skin.fontNormal.drawBlock("|b|"+GetLocale("ORIGINAL_TENANT")+":|/b|~n" + ownerInfo, contentX + 5, contentY + 3, leftWidth, ownerInfoH - 3, null, skin.textColorNeutral)
			skin.fontNormal.drawBlock("|b|"+GetLocale("RERENT")+":|/b|~n" + ownerRerentInfo, contentX + 5 + leftWidth + leftRightSplitter, contentY + 3, rightWidth, ownerInfoH - 3, null, skin.textColorNeutral)

			rem
Aehnlich wie bei "Cast" fuer Raeume mit Vorbesitzer anzeigen:

Vorbesitzer: XYZ
             Name so und so
             Bezieht Raum wieder in X Stunden
			endrem
			contentY :+ ownerInfoH
		endif

		'== bars / messages / boxes area
		'background for bars + messages + boxes
		skin.RenderContent(contentX, contentY, contentW, boxAreaH, "1_bottom")

		'boxes have a top-padding
		contentY :+ boxAreaPaddingY

		'== draw boxes
		skin.RenderBox(contentX + 5, contentY, 50, -1, room.GetSize(), "roomSize", "neutral", skin.fontBold)
		skin.RenderBox(contentX + 5 + 54 +52, contentY, 110, -1, MathHelper.DottedValue( room.GetRentForPlayer(currentPlayerID) ) +" |color=90,90,90|/ Tag|/color|", "moneyRepetitions", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		if canAfford
			skin.RenderBox(contentX + 5 + 168 +52, contentY, 90, -1, MathHelper.DottedValue( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) ), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		else
			skin.RenderBox(contentX + 5 + 168 +52, contentY, 90, -1, MathHelper.DottedValue( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) ), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
		endif


		'=== DEBUG ===
		If TVTDebugInfos
			'begin at the top ...again
			contentY = y + skin.GetContentY()
			local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(contentX, contentY, contentW, sheetHeight - skin.GetContentPadding().GetTop() - skin.GetContentPadding().GetBottom())
			SetColor 255,255,255
			SetAlpha oldAlpha

			skin.fontBold.drawBlock("Raum: "+room.GetDescription(), contentX + 5, contentY, contentW - 10, 28)
			contentY :+ 28
			skin.fontNormal.draw("Name: "+room.GetName(), contentX + 5, contentY)
			contentY :+ 12	
			skin.fontNormal.draw("Besitzer: "+room.GetOwner(), contentX + 5, contentY)
			contentY :+ 12	
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
 	End Method


	Method RemoveAllRoomboardGuiElements:int()
		'
	End Method
End Type
