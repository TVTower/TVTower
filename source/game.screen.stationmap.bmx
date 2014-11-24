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


	Function Init()
		'remove background from stationmap screen
		'(we draw the map and then the screen bg)
		local stationMapScreen:TInGameScreen = TInGameScreen(ScreenCollection.GetScreen("screen_office_stationmap"))
		if stationMapScreen
			stationMapBackgroundSpriteName = stationMapScreen.backgroundSpriteName
			stationMapScreen.backgroundSpriteName = ""
		endif
	
		'StationMap-GUIcomponents
		'position gets recalculated during drawing (so it can move with the panel)
		'also add 2 pixels to width because of "inset effect"
		stationMapBuyButton = new TGUIButton.Create(new TVec2D.Init(610, 110), new TVec2D.Init(170, 28), "", "STATIONMAP")
		stationMapBuyButton.spriteName = "gfx_gui_button.datasheet"
		EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapBuy, stationMapBuyButton )
		EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapBuy, stationMapBuyButton )

		stationMapSellButton = new TGUIButton.Create(new TVec2D.Init(610, 345), new TVec2D.Init(170, 28), "", "STATIONMAP")
		stationMapSellButton.disable()
		stationMapSellButton.spriteName = "gfx_gui_button.datasheet"
		EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapSell, stationMapSellButton )
		EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapSell, stationMapSellButton )

		'we have to refresh the gui station list as soon as we remove or add a station
		EventManager.registerListenerFunction( "stationmap.removeStation",	OnChangeStationMapStation )
		EventManager.registerListenerFunction( "stationmap.addStation",	OnChangeStationMapStation )

		stationList = new TGUISelectList.Create(new TVec2D.Init(610,233), new TVec2D.Init(174, 120), "STATIONMAP")
		EventManager.registerListenerFunction( "GUISelectList.onSelectEntry", OnSelectEntry_StationMapStationList, stationList )

		'player enters station map screen - set checkboxes according to station map config
		EventManager.registerListenerFunction("screen.onEnter", onEnterStationMapScreen, ScreenCollection.GetScreen("screen_office_stationmap"))


		For Local i:Int = 0 To 3
			stationMapShowStations[i] = new TGUICheckBox.Create(new TVec2D.Init(520, 30 + i*25), new TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
			stationMapShowStations[i].SetChecked(True, False)
			stationMapShowStations[i].ShowCaption(False)
			stationMapShowStations[i].data.AddNumber("playerNumber", i+1)
			'register checkbox changes
			EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, stationMapShowStations[i])
		Next

		'inform if language changes
		EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage)


		TRoomHandler._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, ScreenCollection.GetScreen("screen_office_stationmap") )

		SetLanguage()
	End Function


	Function onSetLanguage:int(triggerEvent:TEventBase)
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
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local currTextWidth:int
		local buttonY:int = 0

		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
	
		'selected a map
		If stationMapMode = 1 ' and stationMapSelectedStation
			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_buystationdata"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()

			buttonY = currY

			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_empty"); sprite.DrawArea(currX, currY, -1, stationMapBuyButton.rect.GetH())
			currY :+ stationMapBuyButton.rect.GetH()
		else
			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_splitter"); sprite.DrawArea(currX, currY, -1, 5)
			currY :+ 5
			buttonY = currY

			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_empty"); sprite.DrawArea(currX, currY, -1, stationMapBuyButton.rect.GetH())
			currY :+ stationMapBuyButton.rect.GetH()
		endif

		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		'move buy button accordingly
		stationMapBuyButton.rect.position.SetXY(x + 16, buttonY)

		'=== TEXTS ===

		'adjust currX/currY so position is within "border"
		currY = y + 8
		currX = x + 7 

		local textColor:TColor = TColor.CreateGrey(25)
		'default is size "12" so resize to 13
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetLocale("PURCHASE_STATION"), currX + 8, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 17

		If stationMapMode = 1 and stationMapSelectedStation
			'align to content portion (icon higher than text area)
			currY :+ 5 'top content padding
			currY :+ 4

			fontNormal.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getReach(), 2), currX + 34, currY, 48, 17, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
			fontNormal.drawBlock(TFunctions.DottedValue(stationMapSelectedStation.getReachIncrease()), currX + 115, currY, 60, 17, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 27	'next icon row

			'fetch financial state of room owner (not player - so take care
			'if the player is allowed to do this)
			local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(room.owner, -1)
			if not finance or finance.canAfford(stationMapSelectedStation.GetPrice())
				'TFunctions.DottedValue(GetPrice())
				fontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getPrice(), 2, 0), currX + 115, currY, 60, 17, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
			else
				'TFunctions.DottedValue(GetPrice())
				fontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getPrice(), 2, 0), currX + 115, currY, 60, 17, ALIGN_RIGHT_CENTER, TColor.Create(200,0,0), 0,1,1.0,True, True)
			endif
			currY :+ 27	'next icon row
		EndIf
	End Function


	Function _DrawStationMapSellPanel:Int(x:Int,y:Int, room:TRoom)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local currTextWidth:int
		local buttonY:int = 0
		local listY:int = 0

		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		'area of the list
		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_content_top"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		listY = currY

		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_content_middle"); sprite.DrawArea(currX, currY, -1, stationList.rect.GetH())
		currY :+ stationList.rect.GetH()

		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_content_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		local stationDataY:int = currY
		
		'show data when a station is selected, else show a hint
		'do this to avoid "jumping" panels as it is visually "Bottom aligned"
		If stationMapMode = 2 ' and stationMapSelectedStation
			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_sellstationdata"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()

			buttonY = currY

			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_empty"); sprite.DrawArea(currX, currY, -1, stationMapBuyButton.rect.GetH())
			currY :+ stationMapBuyButton.rect.GetH()
		else
			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_splitter"); sprite.DrawArea(currX, currY, -1, 5)
			currY :+ 5

			'height of the stationdata minus the splitter
			local keepItConstantHeight:int = GetSpriteFromRegistry("gfx_narrowdatasheet_sellstationdata").GetHeight() - sprite.GetHeight()
			buttonY = currY + keepItConstantHeight

			sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_empty")
			sprite.DrawArea(currX, currY, -1, stationMapBuyButton.rect.GetH() + keepItConstantHeight)
			currY :+ stationMapBuyButton.rect.GetH() + keepItConstantHeight
		endif

		sprite = GetSpriteFromRegistry("gfx_narrowdatasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== MOVE GUI ELEMENTS ===
		stationMapSellButton.rect.position.SetXY(x + 16, buttonY)
		stationList.rect.position.SetXY(x + 13, listY)


		'=== TEXTS ===

		'adjust currX/currY so position is within "border"
		currY = y + 8
		currX = x + 7 

		local textColor:TColor = TColor.CreateGrey(25)
		'default is size "12" so resize to 13
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetLocale("ACQUIRED_PROPERTY"), currX + 8, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 17

		If stationMapMode = 2 and stationMapSelectedStation
			'directly move to the station data area
			currY = stationDataY

			'align to content portion (icon higher than text area)
			currY :+ 5 'top content padding
			currY :+ 4

			fontNormal.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getReach(), 2), currX + 34, currY, 48, 17, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
			'attention: SELL price
			fontBold.drawBlock(TFunctions.convertValue(stationMapSelectedStation.getSellPrice(), 2, 0), currX + 115, currY, 60, 17, ALIGN_RIGHT_CENTER, textColor, 0,1,1.0,True, True)
			currY :+ 27	'next icon row
		EndIf
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


		GUIManager.Draw("STATIONMAP")

		For Local i:Int = 0 To 3
			SetColor 100, 100, 100
			DrawRect(544, 32 + i * 25, 15, 18)
			GetPlayerCollection().Get(i+1).color.SetRGB()
			DrawRect(545, 33 + i * 25, 13, 16)
		Next
		SetColor 255, 255, 255
		GetBitmapFontManager().baseFont.drawBlock(GetLocale("SHOW_PLAYERS")+":", 460, 15, 100, 20, new TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)

		'draw stations and tooltips
		GetPlayerCollection().Get(room.owner).GetStationMap().Draw()

		'also draw the station used for buying/searching
		If stationMapMouseoverStation then stationMapMouseoverStation.Draw()
		'also draw the station used for buying/searching
		If stationMapSelectedStation then stationMapSelectedStation.Draw(true)

		'draw a kind of tooltip over a mouseoverStation
		if stationMapMouseoverStation then stationMapMouseoverStation.DrawInfoTooltip()
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
				local finance:TPlayerFinance = GetPlayerFinanceCollection().Get(GetPlayerCollection().Get().playerID, -1)
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

		'different owner or not paid
		if stationMapSelectedStation
			if stationMapSelectedStation.owner <> GetPlayerCollection().playerID or not stationMapSelectedStation.paid
				button.disable()
			else
				button.enable()
			endif
		endif


		if stationMapMode=2
			button.SetValue(GetLocale("SELL_STATION"))
			button.enable()
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
			sprite = GetSpriteFromRegistry("gfx_list_icon_antenna.on")
		else
			sprite = GetSpriteFromRegistry("gfx_list_icon_antenna.off")
		endif


		'draw with different color according status
		if station.IsActive()
			'draw antenna
			sprite.Draw(Int(item.GetScreenX() + 5), item.GetScreenY() + 0.5*(item.rect.getH() - sprite.GetHeight()))
			item.GetFont().draw(item.GetValue(), Int(item.GetScreenX() + 5 + sprite.GetWidth() + 5), Int(item.GetScreenY() + 2 + 0.5*(item.rect.getH()- item.GetFont().getHeight(item.value))), item.valueColor)
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