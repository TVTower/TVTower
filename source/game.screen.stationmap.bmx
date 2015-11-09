Type TScreenHandler_StationMap
	global stationList:TGUISelectList
	'1=searchBuy, 2=buy, 3=sell
	global stationMapMode:int = 0
	global stationMapActionConfirmed:int = FALSE
	global stationMapSelectedStation:TStation
	global stationMapMouseoverStation:TStation
	global stationMapShowStations:TGUICheckBox[4]
	global stationMapBuyButton:TGUIButton
	global stationMapSellButton:TGUIButton
	global stationMapBackgroundSpriteName:String = ""

	global currentSubRoom:TRoom = null
	global lastSubRoom:TRoom = null

	Global _eventListeners:TLink[]


	Function Initialize:int()
		local screen:TInGameScreen = TInGameScreen(ScreenCollection.GetScreen("screen_office_stationmap"))
		if not screen then return False

		'remove background from stationmap screen
		'(we draw the map and then the screen bg)
		if screen.backgroundSpriteName <> ""
			stationMapBackgroundSpriteName = screen.backgroundSpriteName
			screen.backgroundSpriteName = ""
		endif

		
		'=== create gui elements if not done yet
		if not stationMapBuyButton
			'StationMap-GUIcomponents
			'position gets recalculated during drawing (so it can move with the panel)
			'also add 2 pixels to width because of "inset effect"
			stationMapBuyButton = new TGUIButton.Create(new TVec2D.Init(610, 110), new TVec2D.Init(170, 28), "", "STATIONMAP")
			stationMapBuyButton.spriteName = "gfx_gui_button.datasheet"

			stationMapSellButton = new TGUIButton.Create(new TVec2D.Init(610, 345), new TVec2D.Init(170, 28), "", "STATIONMAP")
			stationMapSellButton.spriteName = "gfx_gui_button.datasheet"

			stationList = new TGUISelectList.Create(new TVec2D.Init(610,233), new TVec2D.Init(174, 105), "STATIONMAP")

			For Local i:Int = 0 To 3
				stationMapShowStations[i] = new TGUICheckBox.Create(new TVec2D.Init(520, 30 + i*25), new TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
				stationMapShowStations[i].ShowCaption(False)
				stationMapShowStations[i].data.AddNumber("playerNumber", i+1)
			Next
		endif


		'=== reset gui element options to their defaults
		stationMapSellButton.disable()
		For Local i:Int = 0 To 3
			stationMapShowStations[i].SetChecked(True, False)
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", OnClick_StationMapBuy, stationMapBuyButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapBuy, stationMapBuyButton ) ] 
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", OnClick_StationMapSell, stationMapSellButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapSell, stationMapSellButton ) ]
		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "GUISelectList.onSelectEntry", OnSelectEntry_StationMapStationList, stationList ) ]
		'player enters station map screen - set checkboxes according to station map config
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onEnter", onEnterStationMapScreen, screen ) ]

		For Local i:Int = 0 To 3
			'register checkbox changes
			_eventListeners :+ [ EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, stationMapShowStations[i]) ]
		Next

		'to update/draw the screen
		_eventListeners :+ TRoomHandler._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, screen )

		'(re-)localize content
		SetLanguage()
	End Function


	Function SetLanguage()
		'stationmap
		if stationMapBuyButton
			stationMapBuyButton.SetCaption(GetLocale("BUY_STATION"))
			stationMapSellButton.SetCaption(GetLocale("SELL_STATION"))
		endif
	End Function


	Function _DrawStationMapBuyPanel:Int(x:Int,y:Int, room:TRoom)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 205
		local sheetHeight:int = 0 'calculated later

		local skin:TDatasheetSkin = GetDatasheetSkin("stationmapPanel")

		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, boxH:int = 0, buttonH:int = 0
		local boxAreaH:int = 0, buttonAreaH:int = 0, bottomAreaH:int = 0
		local boxAreaPaddingY:int = 4, buttonAreaPaddingY:int = 4

		'show boxes? - show them regardless of a selected station
		if stationMapMode = 1
			boxH = skin.GetBoxSize(100, -1, "").GetY()
			boxAreaH = 2 * boxAreaPaddingY + 2* boxH
		endif
		if boxAreaH > 0 then bottomAreaH :+ boxAreaH
		if boxAreaH > 0
			'boxarea contains padding already..
			buttonAreaH = stationMapBuyButton.rect.GetH() + 0*buttonAreaPaddingY
		else
			buttonAreaH = stationMapBuyButton.rect.GetH() + 2*buttonAreaPaddingY
		endif
		bottomAreaH :+ buttonAreaH
		
		'total height
		sheetHeight = titleH + bottomAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		'=== RENDER ===
	
		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetLocale("PURCHASE_STATION"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH


		'=== BOXES / BUTTON AREA ===
		skin.RenderContent(contentX, contentY, contentW, bottomAreaH, "1_bottom")


		'=== BOXES ===
		If stationMapMode = 1
			local canAfford:int = True
			local price:string = "", reach:string = "", reachIncrease:string = ""
			if stationMapSelectedStation
				reach = TFunctions.convertValue(stationMapSelectedStation.getReach(), 2)
				reachIncrease = TFunctions.DottedValue(stationMapSelectedStation.getReachIncrease())
				price = TFunctions.convertValue(stationMapSelectedStation.getPrice(), 2, 0)

				local finance:TPlayerFinance = GetPlayerFinance(room.owner)
				canAfford = (not finance or finance.canAfford(stationMapSelectedStation.GetPrice()))
			endif

			local halfW:int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			contentY :+ boxAreaPaddingY
			skin.RenderBox(contentX + 5, contentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, reachIncrease, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)


			'=== BOX LINE 2 ===
			contentY :+ boxH
			'TODO: Build time for stations?
			if GameRules.stationConstructionTime > 0
				skin.RenderBox(contentX + 5, contentY, 80, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
			endif

			'fetch financial state of room owner (not player - so take care
			'if the player is allowed to do this)
			if canAfford
				skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
			endif
			contentY :+ boxH
		endif


		'=== BUTTON ===
		'move buy button accordingly
		if boxAreaH = 0 then contentY :+ buttonAreaPaddingY
		stationMapBuyButton.rect.dimension.SetX(contentW - 10)
		stationMapBuyButton.rect.position.SetXY(contentX + 5, contentY)
		contentY :+ buttonAreaPaddingY


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function


	Function _DrawStationMapSellPanel:Int(x:Int,y:Int, room:TRoom)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 205
		local sheetHeight:int = 0 'calculated later

		local skin:TDatasheetSkin = GetDatasheetSkin("stationmapPanel")

		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, boxH:int = 0, buttonH:int = 0
		local boxAreaH:int = 0, buttonAreaH:int = 0, listAreaH:int = 0, bottomAreaH:int = 0
		local boxAreaPaddingY:int = 4, buttonAreaPaddingY:int = 4

		listAreaH = stationList.rect.GetH() + 6

		'show boxes in all states (grayed out without selling state)
		boxH = skin.GetBoxSize(100, -1, "").GetY()
		boxAreaH = 2 * boxAreaPaddingY + 2* boxH
		bottomAreaH :+ boxAreaH

		'boxarea contains padding already..
		buttonAreaH = stationMapSellButton.rect.GetH() + 0*buttonAreaPaddingY
		bottomAreaH :+ buttonAreaH
		
		'total height
		sheetHeight = titleH + listAreaH + bottomAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		'=== RENDER ===
	
		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetLocale("ACQUIRED_PROPERTY"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH

		'=== LIST AREA ===
		skin.RenderContent(contentX, contentY, contentW, listAreaH, "2")
		'move list to here...
		if stationList.rect.position.GetX() <> contentX + 5 
			stationList.rect.position.SetXY(contentX + 5, contentY + 3)
			stationList.rect.dimension.SetX(contentW - 10)
		endif
		contentY :+ listAreaH
		
		'=== BOXES / BUTTON AREA ===
		skin.RenderContent(contentX, contentY, contentW, bottomAreaH, "1")


		'=== BOXES ===
		If stationMapMode = 2
			if not stationMapSelectedStation
				SetAlpha GetAlpha() * 0.5
			endif
			local price:string = "", reach:string = "", reachDecrease:string = ""
			if stationMapSelectedStation
				reach = TFunctions.convertValue(stationMapSelectedStation.getReach(), 2)
				reachDecrease = TFunctions.DottedValue(stationMapSelectedStation.getReachDecrease())
				price = TFunctions.convertValue(stationMapSelectedStation.getSellPrice(), 2, 0)
			endif

			local halfW:int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			contentY :+ boxAreaPaddingY
			skin.RenderBox(contentX + 5, contentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, "-"+reachDecrease, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")


			'=== BOX LINE 2 ===
			contentY :+ boxH
			skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			contentY :+ boxH


			if not stationMapSelectedStation
				SetAlpha GetAlpha() * 2.0
			endif
		endif


		'=== BUTTON ===
		if boxAreaH = 0 then contentY :+ buttonAreaPaddingY
		'move buy button accordingly
		stationMapSellButton.rect.dimension.SetX(contentW - 10)
		stationMapSellButton.rect.position.SetXY(contentX + 5, contentY)
		contentY :+ buttonAreaPaddingY


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function


	Function onDrawStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'draw map
		GetSpriteFromRegistry("map_Surface").Draw(0,0)
		'overlay with alpha channel screen
		GetSpriteFromRegistry(stationMapBackgroundSpriteName).Draw(0,0)

		_DrawStationMapBuyPanel(590, 5, room)
		_DrawStationMapSellPanel(590, 150, room)


		'draw stations and tooltips
		GetPlayerCollection().Get(room.owner).GetStationMap().Draw()

		'also draw the station used for buying/searching
		If stationMapMouseoverStation then stationMapMouseoverStation.Draw()
		'also draw the station used for buying/searching
		If stationMapSelectedStation then stationMapSelectedStation.Draw(true)


		GUIManager.Draw("STATIONMAP")

		For Local i:Int = 0 To 3
			SetColor 100, 100, 100
			DrawRect(544, 32 + i * 25, 15, 18)
			GetPlayerCollection().Get(i+1).color.SetRGB()
			DrawRect(545, 33 + i * 25, 13, 16)
		Next
		SetColor 255, 255, 255
		GetBitmapFontManager().baseFont.drawBlock(GetLocale("SHOW_PLAYERS")+":", 460, 15, 100, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)

		'draw a kind of tooltip over a mouseoverStation
		if stationMapMouseoverStation then stationMapMouseoverStation.DrawInfoTooltip()

		'draw activation tooltip for all other stations
		For Local station:TStation = EachIn GetPlayer(room.owner).GetStationMap().Stations
			if stationMapMouseoverStation = station then continue
			if station.IsActive() then continue

			station.DrawActivationTooltip()
		Next
	End Function


	Function onUpdateStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'backup room if it changed
		if currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom
			'if we changed the room meanwhile - we have to rebuild the stationList
			RefreshStationMapStationList()
		endif

		currentSubRoom = room

		GetPlayerCollection().Get(room.owner).GetStationMap().Update()

		'process right click
		if MOUSEMANAGER.isHit(2)
			local reset:int = (stationMapSelectedStation or stationMapMouseoverStation)

			ResetStationMapAction(0)

			if reset then MOUSEMANAGER.ResetKey(2)
		Endif


		'buying stations using the mouse
		'1. searching
		If stationMapMode = 1
			'create a temporary station if not done yet
			if not StationMapMouseoverStation then StationMapMouseoverStation = GetStationMapCollection().getMap(room.owner).getTemporaryStation( MouseManager.x, MouseManager.y )
			local mousePos:TVec2D = new TVec2D.Init( MouseManager.x, MouseManager.y)

			'if the mouse has moved - refresh the station data and move station
			if not StationMapMouseoverStation.pos.isSame( mousePos )
				StationMapMouseoverStation.pos.CopyFrom(mousePos)
				StationMapMouseoverStation.refreshData()
				'refresh state information
				StationMapMouseoverStation.getFederalState(true)
			endif

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if StationMapMouseoverStation.GetHoveredMapSection() and StationMapMouseoverStation.getReach()>0
					StationMapSelectedStation = GetStationMapCollection().getMap(room.owner).getTemporaryStation( StationMapMouseoverStation.pos.x, StationMapMouseoverStation.pos.y )
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if StationMapMouseoverStation.getReach() <= 0 or not StationMapMouseoverStation.GetHoveredMapSection() then StationMapMouseoverStation = null

			if StationMapSelectedStation
				if StationMapSelectedStation.getReach() <= 0 or not StationMapSelectedStation.GetHoveredMapSection() then StationMapSelectedStation = null
			endif
		endif

		GUIManager.Update("STATIONMAP")
	End Function


	Function OnChangeStationMapStation:int( triggerEvent:TEventBase )
		if not currentSubRoom then return FALSE
		'do nothing when not in a roomy

		RefreshStationMapStationList( currentSubRoom.owner )
	End Function


	Function ResetStationMapAction(mode:int=0)
		stationMapMode = mode
		stationMapActionConfirmed = FALSE
		'remove selection
		stationMapSelectedStation = null
		stationMapMouseoverStation = Null

		'reset gui list
		stationList.deselectEntry()
	End Function


	'===================================
	'Stationmap: Connect GUI elements
	'===================================

	Function OnUpdate_StationMapBuy:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().GetFigure().inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		if stationMapMode = 1
			if not stationMapSelectedStation
				button.SetValue(GetLocale("SELECT_LOCATION")+" ...")
				button.disable()
			else
				local finance:TPlayerFinance = GetPlayerFinance(GetPlayerCollection().Get().playerID)
				if finance and finance.canAfford(stationMapSelectedStation.GetPrice())
					button.SetValue(GetLocale("BUY_STATION"))
					button.enable()
				else
					button.SetValue(GetLocale("TOO_EXPENSIVE"))
					button.disable()
				endif
			endif
		else
			button.SetValue(GetLocale("NEW_STATION"))
			button.enable()
		endif
	End Function

	Function OnClick_StationMapBuy:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().GetFigure().inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>1 then ResetStationMapAction(1)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'add the station (and buy it)
			if GetPlayerCollection().Get().GetStationMap().AddStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function


	Function OnClick_StationMapSell:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().GetFigure().inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		'coming from somewhere else... reset first
		if stationMapMode<>2 then ResetStationMapAction(2)

		If stationMapSelectedStation and stationMapSelectedStation.getReach() > 0
			'remove the station (and sell it)
			if GetPlayerCollection().Get().GetStationMap().RemoveStation(stationMapSelectedStation, TRUE)
				ResetStationMapAction(0)
			endif
		EndIf
	End Function

	'enables/disables the button depending on selection
	'sets button label depending on userAction
	Function OnUpdate_StationMapSell:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().GetFigure().inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		if stationMapMode=2
			'different owner or not paid or not sellable
			if stationMapSelectedStation
				if stationMapSelectedStation.owner <> GetPlayerCollection().playerID
					button.disable()
					button.SetValue(GetLocale("WRONG_PLAYER"))
				elseif not stationMapSelectedStation.HasFlag(TStation.FLAG_SELLABLE)
					button.SetValue(GetLocale("UNSELLABLE"))
					button.disable()
				elseif not stationMapSelectedStation.HasFlag(TStation.FLAG_PAID)
					button.SetValue(GetLocale("SELL_STATION"))
					button.disable()
				else
					'save processing for default behaviour
					if not button.IsEnabled()
						button.SetValue(GetLocale("SELL_STATION"))
						button.enable()
					endif
				endif
			endif
		else
			button.SetValue(GetLocale("SELECT_STATION"))
			button.disable()
		endif
	End Function


	'rebuild the stationList - eg. when changed the room (other office)
	Function RefreshStationMapStationList(playerID:int=-1)
		If playerID <= 0 Then playerID = GetPlayerCollection().playerID

		'first fill of stationlist
		stationList.EmptyList()
		'remove potential highlighted item
		stationList.deselectEntry()

		For Local station:TStation = EachIn GetPlayerCollection().Get(playerID).GetStationMap().Stations
			local item:TGUICustomSelectListItem = new TGUICustomSelectListItem.Create(new TVec2D, new TVec2D.Init(100,20), GetLocale("STATION")+" (" + TFunctions.convertValue(station.reach, 2, 0) + ")")
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawValue = DrawMapStationListEntry
			stationList.AddItem( item )
		Next
	End Function


	'custom drawing function for list entries
	Function DrawMapStationListEntry:int(obj:TGUIObject)
		local item:TGUICustomSelectListItem = TGUICustomSelectListItem(obj)
		if not item then return False

		local station:TStation = TStation(item.data.Get("station"))
		if not station then return False

		local sprite:TSprite
		if station.IsActive()
			sprite = GetSpriteFromRegistry("gfx_datasheet_icon_antenna.on")
		else
			sprite = GetSpriteFromRegistry("gfx_datasheet_icon_antenna.off")
		endif


		'draw with different color according status
		if station.IsActive()
			'colorize antenna for "not sellable ones
			if not station.HasFlag(TStation.FLAG_SELLABLE)
				SetColor 120,90,60
				'draw antenna
				sprite.Draw(Int(item.GetScreenX() + 5), item.GetScreenY() + 0.5*(item.rect.getH() - sprite.GetHeight()))
				item.GetFont().draw(item.GetValue(), Int(item.GetScreenX() + 5 + sprite.GetWidth() + 5), Int(item.GetScreenY() + 2 + 0.5*(item.rect.getH()- item.GetFont().getHeight(item.value))))
				SetColor 255,255,255
			else
				'draw antenna
				sprite.Draw(Int(item.GetScreenX() + 5), item.GetScreenY() + 0.5*(item.rect.getH() - sprite.GetHeight()))
				item.GetFont().draw(item.GetValue(), Int(item.GetScreenX() + 5 + sprite.GetWidth() + 5), Int(item.GetScreenY() + 2 + 0.5*(item.rect.getH()- item.GetFont().getHeight(item.value))), item.valueColor)
			endif
		else
			local oldAlpha:float = GetAlpha()
			SetAlpha oldAlpha*0.5
			'draw antenna
			sprite.Draw(Int(item.GetScreenX() + 5), item.GetScreenY() + 0.5*(item.rect.getH() - sprite.GetHeight()))
			item.GetFont().draw(item.GetValue(), Int(item.GetScreenX() + 5 + sprite.GetWidth() + 5), Int(item.GetScreenY() + 2 + 0.5*(item.rect.getH()- item.GetFont().getHeight(item.value))), item.valueColor.copy().AdjustFactor(50))
			SetAlpha oldAlpha
		endif
	End Function
	

	'an entry was selected - make the linked station the currently selected station
	Function OnSelectEntry_StationMapStationList:int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If not senderList then return FALSE

		if not currentSubRoom or not GetPlayerCollection().IsPlayer(currentSubRoom.owner) then return FALSE

		'set the linked station as selected station
		'also set the stationmap's userAction so the map knows we want to sell
		local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		if item
			stationMapSelectedStation = TStation(item.data.get("station"))
			if stationMapSelectedStation
				'force stat refresh (so we can display decrease properly)!
				stationMapSelectedStation.GetReachDecrease(True)
			endif
			stationMapMode = 2 'sell
		endif
	End Function


	'set checkboxes according to stationmap config
	Function onEnterStationMapScreen:int(triggerEvent:TEventBase)
		'only players can "enter screens" - so just use "inRoom"

		For local i:int = 0 to 3
			local show:int = GetStationMapCollection().GetMap(GetPlayerCollection().Get().GetFigure().inRoom.owner).showStations[i]
			stationMapShowStations[i].SetChecked(show)
		Next
	End Function


	Function OnSetChecked_StationMapFilters:int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent._sender)
		if not button then return FALSE

		'ignore clicks if not in the own office
		if GetPlayerCollection().Get().GetFigure().inRoom.owner <> GetPlayerCollection().Get().playerID then return FALSE

		local player:int = button.data.GetInt("playerNumber", -1)
		if not GetPlayerCollection().IsPlayer(player) then return FALSE

		'only set if not done already
		if GetPlayerCollection().Get().GetStationMap().showStations[player-1] <> button.isChecked()
			TLogger.Log("StationMap", "show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
			GetPlayerCollection().Get().GetStationMap().showStations[player-1] = button.isChecked()
		endif
	End Function
End Type