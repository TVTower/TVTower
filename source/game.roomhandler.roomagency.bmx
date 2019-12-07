SuperStrict
Import "Dig/base.gfx.gui.bmx"
Import "Dig/base.gfx.tooltip.base.bmx"
Import "common.misc.datasheet.bmx"
Import "game.roomhandler.base.bmx"
Import "game.misc.roomboardsign.bmx"
Import "game.roomagency.bmx"
Import "game.player.bmx"


'RoomAgency
Type RoomHandler_RoomAgency extends TRoomHandler
	'show room board?
	Field mode:int = 0
	Field selectedRoom:TRoomBase
	Field hoveredRoom:TRoomBase
	Field hoveredSign:TRoomBoardSign
	Field roomContractTexts:TMap = new TMap

	Global roomboardTooltip:TTooltip

	Global _confirmActionTooltip:TTooltipBase

	Global LS_roomagency_board:TLowerString = TLowerString.Create("roomagency")
	Global _eventListeners:TEventListenerBase[]
	Global _instance:RoomHandler_RoomAgency

	Const MODE_NONE:int = 0
	Const MODE_SELECTROOM:int = 1


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
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

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
		roomboardTooltip = null

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
		'invalidate cached texts
		if i.selectedRoom = room then i.roomContractTexts.Remove(room.GetGUID())
		if i.hoveredRoom = room then i.roomContractTexts.Remove(room.GetGUID())

		if i.selectedRoom
			'selected the room of another player
			if i.selectedRoom.GetOwner() > 0 and i.selectedRoom.GetOwner() <> GetPlayerBase().playerID
				i.selectedRoom = null
			'selected unrented one which cannot get rented
			elseif not i.selectedRoom.IsRented() and not i.selectedRoom.IsRentable()
				i.selectedRoom = null
			endif
		endif
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
		If THelper.MouseIn(0,0,230,325)
			If not roomboardTooltip
				roomboardTooltip = TTooltip.Create(GetLocale("ROOM_OVERVIEW"), GetLocale("CANCEL_OR_RENT_ROOMS"), 70, 120, 0, 0)
				roomboardTooltip._minContentWidth = 150
			endif

			roomboardTooltip.enabled = 1
			roomboardTooltip.Hover()
			GetGameBase().cursorstate = 1
			If MOUSEMANAGER.IsClicked(1) and not GetPlayer().GetFigure().IsChangingRoom()
				GetGameBase().cursorstate = 0

				mode = MODE_SELECTROOM

				'handled left click
				MouseManager.SetClickHandled(1)
			endif
		EndIf
		If roomboardTooltip Then roomboardTooltip.Update()


		if mode = MODE_SELECTROOM
			UpdateRoomBoard()
		else
			'Update dialogue
		endif

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllGuiElements()

			'no mouse reset - we still want to leave the room
		endif
	End Method


	Method Render()
		SetColor(255,255,255)

		If roomboardTooltip Then roomboardTooltip.Render()

		if mode = MODE_SELECTROOM
			RenderRoomBoard()
		else
			'Dialogue
		endif
 	End Method


 	'=== ROOMBOARD ===


 	Method UpdateRoomBoard()
		hoveredRoom = null
		hoveredSign = null

		local playerID:int = GetPlayerBase().playerID

		For local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			if not room then continue
			'ignore never-rentable rooms
			if room.IsFake() or room.IsFreeHold() then continue

			'other players rooms
			if room.GetOwner() > 0 and room.GetOwner() <> playerID and not room.IsRentable() then continue
			'disabled: make "not yet free"-rooms hoverable
			'if room.GetOwner() <= 0 and not room.IsRentable() then continue

			if not sign.imageCache
				sign.imageCache = sign.GenerateCacheImage( GetSpriteFromRegistry(sign.imageBaseName + Max(0, sign.door.GetOwner())) )
			endif

			local x:int = 42 + (sign.door.doorSlot-1) * 179
			local y:int = 40 + (13 - sign.door.onFloor) * 23

			if THelper.MouseIn(x,y, sign.imageCache.GetWidth(), sign.imageCache.GetHeight())
				hoveredRoom = TRoomDoor(sign.door).GetRoom()
				hoveredSign = sign

				'if room.IsRentable() or (room.IsRented() and room.GetOwner() = playerID) and MouseManager.IsClicked(1)
				if MouseManager.IsClicked(1)

					'only select/confirm the room if it is allowed
					if (hoveredRoom.GetOwner() <= 0 and hoveredRoom.IsRentable()) or ..
					   (hoveredRoom.GetOwner() = playerID)
						'confirmation click
						if selectedRoom = hoveredRoom
							'BeginRoomRent/CancelRoomRental will set
							'selectedRoom to null (to avoid having things
							'selected which are no longer selectable)
							'-> use a custom variable
							local useRoom:TRoomBase = selectedroom
							local doneSomething:int = False
							'rent the room
							if useRoom.GetOwner() <> playerID
								if GetRoomAgency().BeginRoomRental(useRoom, GetPlayerBase().playerID)
									useRoom.SetUsedAsStudio(True)
									doneSomething = True
								endif
							else
								'cancel the rent
								if GetRoomAgency().CancelRoomRental(useRoom, GetPlayerBase().playerID)
									useRoom.SetUsedAsStudio(False)
									doneSomething = True
								endif
							endif

							'handled it (might be "False" if player had
							'not enough money)
							if doneSomething = True
								selectedRoom = null
								'hoveredRoom = null
								'hoveredSign = null
								_confirmActionTooltip = null
							endif

						'select click
						else
							selectedRoom = hoveredRoom

							if not _confirmActionTooltip and selectedRoom
								_confirmActionTooltip = new TGUITooltipBase.Initialize("Unknown mode", "", new TRectangle.Init(0,0,-1,-1))
								_confirmActionTooltip.SetOption(TTooltipBase.OPTION_MANUAL_HOVER_CHECK, true)
								if not _confirmActionTooltip.parentArea then _confirmActionTooltip.parentArea = new TRectangle
								_confirmActionTooltip.parentArea.Init(x, y, sign.imageCache.GetWidth()-3, sign.imageCache.GetHeight()-3)
								_confirmActionTooltip.offset = new TVec2D.Init(0, 0)
								'avoid dwelling, just show it
								_confirmActionTooltip.SetStep(TTooltipBase.STEP_ACTIVE)

								if selectedRoom.GetOwner() <> playerID
									_confirmActionTooltip.SetTitle(StringHelper.UCFirst(GetLocale("CONFIRM")))
									_confirmActionTooltip.SetContent(StringHelper.UCFirst(GetLocale("CLICK_AGAIN_TO_RENT")))
								else
									_confirmActionTooltip.SetTitle(StringHelper.UCFirst(GetLocale("CONFIRM")))
									_confirmActionTooltip.SetContent(StringHelper.UCFirst(GetLocale("CLICK_AGAIN_TO_CANCEL_RENT")))
								endif
							endif
						endif
					else
						selectedRoom = null
						_confirmActionTooltip = null
					endif

					'handled left click
					MouseManager.SetClickHandled(1)
				endif

				exit
			endif
		Next


		If selectedRoom and (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			selectedRoom = null
			_confirmActionTooltip = null

			'avoid clicks
			'remove right click - to avoid leaving the room
			MouseManager.SetClickHandled(2)
		EndIf



		if _confirmActionTooltip
			'update hovered state
			_confirmActionTooltip.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED, selectedRoom <> null)
			_confirmActionTooltip.Update()
		endif


		GuiManager.Update( LS_roomagency_board )

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllRoomboardGuiElements()

			mode = MODE_NONE

			'no mouse reset - we still want to leave the room
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
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(GetLocale("ROOM_OVERVIEW")+": " + GetLocale("CANCEL_OR_RENT_ROOMS"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
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

			if room
				if room.GetOwner() <= 0 and not room.IsRentable()
					SetAlpha oldCol.a * 0.60
				elseif room.GetOwner() = GetPlayerBase().playerID and room.IsFreehold()
					SetAlpha oldCol.a * 0.60
				endif
			endif

			'ignore never-rentable rooms
			if room.IsFake() or room.IsFreeHold() then SetAlpha oldCol.a * 0.25


			if room.IsBlocked()
				SetColor 255,240,220
				sign.imageCache.Draw(x,y)
				oldCol.SetRGB()
			else
				sign.imageCache.Draw(x,y)
			endif


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

		if _confirmActionTooltip
			_confirmActionTooltip.Render()
		endif

		GuiManager.Draw( LS_roomagency_board )

		if hoveredSign
			local signX:int = 42 + (hoveredSign.door.doorSlot-1) * 179
			local signY:int = 40 + (13 - hoveredSign.door.onFloor) * 23
			local sheetW:int = 340
			local sheetX:int, sheetY:int
			if signX + hoveredSign.imageCache.GetWidth() + sheetW < GetGraphicsManager().GetWidth()
				sheetX = signX + hoveredSign.imageCache.GetWidth()
			else
				sheetX = signX - sheetW
			endif
			'-80 and -215 are arbitrary offsets as we do not know the
			'height of a sheet in advance
			'10 and 366 are limits of the outer "panel"
			sheetY = Max(10, Min(366+10 -215, signY -80))

			DrawRoomSheet(hoveredRoom, sheetX, sheetY)
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

		if not room.IsFreeHold() and room.IsRented()
			ownerInfo = False
		endif

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
		local t:string = ""

		local adText:string = string(roomContractTexts.ValueForKey(room.GetGUID()))
		'create advertisement text and cache it
		if not adText
			'search for an interesting room near this one
			local door:TRoomDoorBase = GetRoomDoorBaseCollection().GetMainDoorToRoom(room.id)
			local neighbourRoom:TRoomBase
			if door
				local interestingRooms:TRoomBase[] = [  GetRoomBaseCollection().GetFirstByDetails("", "supermarket") ..
				                                      , GetRoomBaseCollection().GetFirstByDetails("", "scriptagency") ..
				                                      , GetRoomBaseCollection().GetFirstByDetails("office", "", GetPlayerBaseCollection().playerID) ..
				                                     ]
				for local interestingRoom:TRoomBase = EachIn interestingRooms
					local interestingDoor:TRoomDoorBase = GetRoomDoorBaseCollection().GetMainDoorToRoom(interestingRoom.id)
					if not interestingDoor then continue

					'same floor or one floor above/below
					if Abs(door.onFloor - interestingDoor.onFloor) <= 1
						neighbourRoom = interestingRoom
					endif

					'found one to advertise with
					if neighbourRoom then exit
				next
			endif

			adText = GetRandomLocale2(["ROOMAGENCY_SIZE"+room.GetSize()+"_TEXT", "ROOMAGENCY_SIZE_TEXT"]).REPLACE("%SIZE%", room.GetSize())
			if adText then adText :+ " "
			if neighbourRoom
				adText :+ GetRandomLocale2(["ROOMAGENCY_ROOM_"+neighbourRoom.name+"_IN_RANGE_TEXT", "ROOMAGENCY_ROOM_X_IN_RANGE_TEXT"]).REPLACE("%X%", neighbourRoom.GetDescription())
				if adText then adText :+ " "
			endif

			if room.GetOwner() <= 0
				if not room.IsRented() ' and room.IsRentable()
					adText :+ GetLocale("ROOMAGENCY_AVAILABLE_FOR_RENT_OF_X_PER_DAY").Replace("%X%", MathHelper.DottedValue(room.GetRentForPlayer(currentPlayerID)) +" "+GetLocale("CURRENCY"))
				else
					adText :+ "~n~n" + GetRandomLocale("ROOMAGENCY_ROOM_CURRENTLY_NOT_AVAILABLE_BUT_THIS_MIGHT_CHANGE")
				endif
			endif
			roomContractTexts.Insert(room.GetGUID(), adText)
		endif
		t :+ adText
		if adText then t :+ "~n"

		if room.IsRentable() and room.GetOwner() <> currentPlayerID
			t :+ GetLocale("ROOMAGENCY_SIGNING_WILL_COST_A_SINGLE_PAYMENT_OF_X").Replace("%X%", MathHelper.DottedValue( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) ) +" "+GetLocale("CURRENCY"))
		endif
		skin.fontNormal.drawBlock(t, contentX + 5, contentY + 3, contentW - 10, descriptionH - 3, null, skin.textColorNeutral)
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
		if room.GetOwner() = currentPlayerID
			skin.RenderBox(contentX + 5 + 148 +52, contentY, 110, -1, MathHelper.DottedValue( room.GetRentForPlayer(currentPlayerID) ) +" |color=90,90,90|/ "+ GetLocale("DAY") +"|/color|", "moneyRepetitions", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		'only show prices for rentable rooms
		elseif room.IsRentable()
			skin.RenderBox(contentX + 5 + 54 +52, contentY, 110, -1, MathHelper.DottedValue( room.GetRentForPlayer(currentPlayerID) ) +" |color=90,90,90|/ "+ GetLocale("DAY") +"|/color|", "moneyRepetitions", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			if canAfford
				skin.RenderBox(contentX + 5 + 168 +52, contentY, 90, -1, MathHelper.DottedValue( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) ), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + 168 +52, contentY, 90, -1, MathHelper.DottedValue( GetRoomAgency().GetCourtageForOwner(room, currentPlayerID) ), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER, "bad")
			endif
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
			skin.fontNormal.draw("IsRentable: "+room.IsRentable(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("IsRented: "+room.IsRented(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("IsUsedAsStudio: "+room.IsUsedAsStudio(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("RerentalTime: "+room.GetRerentalTime(), contentX + 5, contentY)
			contentY :+ 12
			skin.fontNormal.draw("Rerental in: "+(GetWorldTime().GetTimegone()-room.GetRerentalTime())+" s", contentX + 5, contentY)
			contentY :+ 12
		endif

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
 	End Method


	Method RemoveAllRoomboardGuiElements:int()
		'
	End Method
End Type
