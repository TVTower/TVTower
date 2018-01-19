SuperStrict
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"
Import "common.misc.gamegui.bmx"
Import "game.screen.base.bmx"
Import "game.stationmap.bmx"
Import "game.player.bmx"
Import "game.room.base.bmx"
Import "game.roomhandler.base.bmx"




Type TGameGUIBasicStationmapPanel extends TGameGUIAccordeonPanel
	Field selectedStation:TStationBase
	Field list:TGUISelectList
	Field actionButton:TGUIButton
	Field cancelButton:TGUIButton
	Field tooltips:TTooltipBase[]

	Field listExtended:int = False
	Field detailsBackgroundH:int
	Field listBackgroundH:int
	Field localeKey_NewItem:string = "NEW_ITEM"
	Field localeKey_BuyItem:string = "BUY_ITEM"
	Field localeKey_SellItem:string = "SELL_ITEM"
	
	Field _eventListeners:TLink[]
	Field headerColor:TColor = new TColor.Create(75,75,75)
	Field subHeaderColor:TColor = new TColor.Create(115,115,115)


	Method Create:TGameGUIBasicStationmapPanel(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		actionButton = new TGUIButton.Create(new TVec2D.Init(0, 0), new TVec2D.Init(150, 28), "", "STATIONMAP")
		actionButton.spriteName = "gfx_gui_button.datasheet"

		cancelButton = new TGUIButton.Create(new TVec2D.Init(145, 0), new TVec2D.Init(30, 28), "X", "STATIONMAP")
		cancelButton.caption.color = TColor.clRed.copy()
		cancelButton.spriteName = "gfx_gui_button.datasheet"

		list = new TGUISelectList.Create(new TVec2D.Init(610,133), new TVec2D.Init(178, 100), "STATIONMAP")
		'scroll by one entry at a time
		list.scrollItemHeightPercentage = 1.0
		list.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)


		cancelButton.SetParent(self)
		actionButton.SetParent(self)
		list.SetParent(self)

		'panel handles them (similar to a child - but with manual draw/update calls)
		GuiManager.Remove(cancelButton)
		GuiManager.Remove(actionButton)
		GuiManager.Remove(list)


		tooltips = New TTooltipBase[5]
		For local i:int = 0 until tooltips.length
			tooltips[i] = new TGUITooltipBase.Initialize("", "", new TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = new TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = new TVec2D.Init(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onClick", self, "OnClickActionButton", actionButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onClick", self, "OnClickCancelButton", cancelButton ) ]
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "GUISelectList.onSelectEntry", self, "OnSelectEntryList", list ) ]

		return self
	End Method


	Method SetLanguage()
		local strings:string[] = [GetLocale("REACH"), GetLocale("Increase"), GetLocale("CONSTRUCTION_TIME"), GetLocale("RUNNING_COSTS"), GetLocale("PRICE")]
		strings = strings[.. tooltips.length]

		For local i:int = 0 until tooltips.length
			if tooltips[i] then tooltips[i].SetContent(strings[i])
		Next
	End Method


	Method OnClickActionButton:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if not TScreenHandler_StationMap.currentSubRoom or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE

		If TScreenHandler_StationMap.IsInBuyActionMode()
			If TScreenHandler_StationMap.selectedStation and TScreenHandler_StationMap.selectedStation.GetReach() > 0
				'add the station (and buy it)
				if GetStationMap( GetPlayerBase().playerID ).AddStation(TScreenHandler_StationMap.selectedStation, TRUE)
					ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
				endif
			EndIf

		elseif TScreenHandler_StationMap.IsInSellActionMode()
			If TScreenHandler_StationMap.selectedStation and TScreenHandler_StationMap.selectedStation.GetReach() > 0
				'remove the station (and sell it)
				if GetStationMap( GetPlayerBase().playerID ).RemoveStation(TScreenHandler_StationMap.selectedStation, TRUE)
					ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
				endif
			EndIf

		else
			'open up satellite selection frame for the satellite link panel
			if GetBuyActionMode() = TScreenHandler_StationMap.MODE_BUY_SATELLITE
				TScreenHandler_StationMap.satelliteSelectionFrame.Open()
			EndIf

			ResetActionMode( GetBuyActionMode() )
		endif

		return True
	End Method


	Method OnClickCancelButton:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if not TScreenHandler_StationMap.currentSubRoom or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE

		ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
	End Method


	'an entry was selected - make the linked station the currently selected station
	Method OnSelectEntryList:int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If not senderList then return FALSE

		if not TScreenHandler_StationMap.currentSubRoom or not GetPlayerBaseCollection().IsPlayer(TScreenHandler_StationMap.currentSubRoom.owner) then return FALSE

		'set the linked station as selected station
		'also set the stationmap's userAction so the map knows we want to sell
		local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		if item
			TScreenHandler_StationMap.selectedStation = TStationBase(item.data.get("station"))
			if TScreenHandler_StationMap.selectedStation
				'force stat refresh (so we can display decrease properly)!
				TScreenHandler_StationMap.selectedStation.GetReachDecrease(True)
			endif

			SetActionMode( GetSellActionMode() )
		endif
	End Method


	Method SetActionMode(mode:int)
		TScreenHandler_StationMap.SetActionMode(mode)
	End Method


	Method ResetActionMode(mode:int=0)
		TScreenHandler_StationMap.ResetActionMode(mode)

		'remove selection
		TScreenHandler_StationMap.selectedStation = null

		'reset gui list
		list.deselectEntry()
	End Method


	Method GetBuyActionMode:int()
		return TScreenHandler_StationMap.MODE_NONE
	End Method


	Method GetSellActionMode:int()
		return TScreenHandler_StationMap.MODE_NONE
	End Method


	Method RefreshList(playerID:int=-1)
		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		'first fill of stationlist
		list.EmptyList()
		'remove potential highlighted item
		list.deselectEntry()

		'keep them sorted the way we added the stations
		list.setListOption(GUILIST_AUTOSORT_ITEMS, False)
	End Method


	'override to resize list accordingly
	Method onStatusAppearanceChange:Int()
		Super.onStatusAppearanceChange()

		list.Resize(GetContentScreenWidth()- 2, -1)
	End Method
	

	Method Update:int()
		if isOpen
			'move list to here...
			if list.rect.position.GetX() <> 2
				list.SetPosition(2, GetHeaderHeight() + 3 )
'local tt:TTypeID = TTypeId.ForObject(self)
'print tt.name() + "   " + GetContentScreenWidth()
				'list.rect.dimension.SetX(GetContentScreenWidth() - 23)
				'resizing is done when status changes
'				list.Resize(GetContentScreenWidth() - 23, -1)
			endif

			'adjust list size if needed
			local listH:int = listBackgroundH - 6
			if listBackgroundH > 0 and list.GetHeight() <> listH
				list.Resize(-1, listH)
'				list.RecalculateElements()
			endif

			
			actionButton.SetPosition(5, GetHeaderHeight() + GetBodyHeight() - 34 )
			cancelButton.SetPosition(5 + 150, GetHeaderHeight() + GetBodyHeight() - 34 )

			UpdateActionButton()

			list.Update()
			actionButton.Update()
			cancelButton.Update()
		endif


		'update count in title
		if TScreenHandler_StationMap.currentSubRoom 
			SetValue( GetHeaderValue() )
		endif


		For local t:TTooltipBase = EachIn tooltips
			t.Update()
		Next


		'call update after button updates so mouse events are properly
		'emitted
		Super.Update()
	End Method


	Method UpdateActionButton:int()
		'ignore clicks if not in the own office
		if not TScreenHandler_StationMap.currentSubRoom or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE

		If TScreenHandler_StationMap.IsInBuyActionMode()
			if not TScreenHandler_StationMap.selectedStation
				if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_SATELLITE
					actionButton.SetValue(GetLocale("SELECT_SATELLITE")+" ...")
				else
					actionButton.SetValue(GetLocale("SELECT_LOCATION")+" ...")
				endif
				actionButton.disable()
			else
				local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
				if finance and finance.canAfford(TScreenHandler_StationMap.selectedStation.GetPrice())
					actionButton.SetValue(GetLocale( localeKey_BuyItem))
					actionButton.enable()
				else
					actionButton.SetValue(GetLocale("TOO_EXPENSIVE"))
					actionButton.disable()
				endif
			endif

		ElseIf TScreenHandler_StationMap.IsInSellActionMode()
			'different owner or not paid or not sellable
			if TScreenHandler_StationMap.selectedStation
				if TScreenHandler_StationMap.selectedStation.owner <> GetPlayerBase().playerID
					actionButton.disable()
					actionButton.SetValue(GetLocale("WRONG_PLAYER"))
				elseif not TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.SELLABLE)
					actionButton.SetValue(GetLocale("UNSELLABLE"))
					actionButton.disable()
				elseif not TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.PAID)
					actionButton.SetValue(GetLocale( localeKey_SellItem ))
					actionButton.disable()
				else
					actionButton.SetValue(GetLocale( localeKey_SellItem ))
					actionButton.enable()
				endif
			endif

		Else
			actionButton.SetValue(GetLocale( localeKey_NewItem ))
			actionButton.enable()
		EndIf

		return True
	End Method


	'override
	Method DrawBody()
		'draw nothing if not open
		if not isOpen then return

		
		local skin:TDatasheetSkin = GetSkin()
		if skin
			local contentX:int = GetScreenX()
			local contentY:int = GetScreenY()
			local contentW:int = GetScreenWidth()
			local currentY:int = contentY + GetHeaderHeight()


			DrawBodyContent(contentX, contentY, contentW, currentY)


			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_NONE
				cancelButton.Hide()
				actionButton.Resize(contentW - 10, -1)
			else
				actionButton.Resize(150, -1)
				cancelButton.Show()
			endif

		endif

		list.Draw()
		actionButton.Draw()
		cancelButton.Draw()


		For local t:TTooltipBase = EachIn tooltips
			t.Render()
		Next

	End Method


	Method DrawBodyContent(contentX:int, contentY:int, contentW:int, contentH:int)
		'by default draw nothing
	End Method
End Type




Type TGameGUIAntennaPanel extends TGameGUIBasicStationmapPanel
	Method Create:TGameGUIAntennaPanel(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		localeKey_NewItem = "NEW_STATION"
		localeKey_BuyItem = "BUY_STATION"
		localeKey_SellItem = "SELL_STATION"

		'=== register custom event listeners
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]

		return self
	End Method


	'override
	Method GetBuyActionMode:int()
		return TScreenHandler_StationMap.MODE_BUY_STATION
	End Method


	'override
	Method GetSellActionMode:int()
		return TScreenHandler_StationMap.MODE_SELL_STATION
	End Method


	'===================================
	'EVENTS: Connect GUI elements
	'===================================


	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:int=-1)
		Super.RefreshList(playerID)

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		local listContentWidth:int = list.GetContentScreenWidth()
		For Local station:TStationAntenna = EachIn GetStationMap(playerID).Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create(new TVec2D, new TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:string()
		return GetLocale( "STATIONS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.ANTENNA)
	End Method


	Method DrawBodyContent(contentX:int,contentY:int,contentW:int,currentY:int)
		local skin:TDatasheetSkin = GetSkin()
		if not skin then return
		
		local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		local boxAreaH:int = 0
		local showDetails:int = False
		if selectedStation then showDetails = True
		if TScreenHandler_StationMap.actionMode = GetSellActionMode() then showDetails = True
		if TScreenHandler_StationMap.actionMode = GetBuyActionMode() then showDetails = True

		'update information
		detailsBackgroundH = actionButton.GetScreenHeight() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*2)
		listBackgroundH = GetBodyHeight() - detailsBackgroundH
		
		skin.RenderContent(contentX, currentY, contentW, listBackgroundH, "2")
		skin.RenderContent(contentX, currentY + listBackgroundH, contentW, detailsBackgroundH, "1_top")


		'=== LIST ===
		currentY :+ listBackgroundH
	

		'=== BOXES ===
		if TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			local price:string = "", reach:string = "", reachChange:string = "", runningCost:string =""
			local headerText:string
			local subHeaderText:string
			local canAfford:int = True
			local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation

			Select TScreenHandler_StationMap.actionMode
				case TScreenHandler_StationMap.MODE_SELL_STATION
					if selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue( -1 * selectedStation.GetReachDecrease() )
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						endif
					endif

				case TScreenHandler_StationMap.MODE_BUY_STATION
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					if selectedStation
						subHeaderText = GetLocale("MAP_COUNTRY_"+selectedStation.GetSectionName())

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						endif

						local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (not finance or finance.canAfford(selectedStation.GetPrice()))
					endif
			End Select


			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, headerColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.drawBlock(subHeaderText, contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			local halfW:int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			endif
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)


			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			if TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				if GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				endif
			endif

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_STATION
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				if canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
				endif
			endif
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH
		endif

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TGameGUICableNetworkPanel extends TGameGUIBasicStationmapPanel
	Field selectedStation:TStationBase


	Method Create:TGameGUICableNetworkPanel(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		localeKey_NewItem = "NEW_CABLE_NETWORK"
		localeKey_BuyItem = "BUY_CABLE_NETWORK"
		localeKey_SellItem = "SELL_CABLE_NETWORK"


		'=== register custom event listeners
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]

		return self
	End Method


	'override
	Method GetBuyActionMode:int()
		return TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK
	End Method


	'override
	Method GetSellActionMode:int()
		return TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK
	End Method



	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:int=-1)
		Super.RefreshList(playerID)

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		local listContentWidth:int = list.GetContentScreenWidth()
		For Local station:TStationCableNetwork = EachIn GetStationMap(playerID).Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create(new TVec2D, new TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:string()
		return GetLocale( "CABLE_NETWORKS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.CABLE_NETWORK)
	End Method


	Method DrawBodyContent(contentX:int,contentY:int,contentW:int,currentY:int)
		local skin:TDatasheetSkin = GetSkin()
		if not skin then return
		
		local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		local boxAreaH:int = 0
		local showDetails:int = False
		if selectedStation then showDetails = True
		if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK then showDetails = True
		if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK then showDetails = True

		'update information
		detailsBackgroundH = actionButton.GetScreenHeight() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*2)
		listBackgroundH = GetBodyHeight() - detailsBackgroundH
		
		skin.RenderContent(contentX, currentY, contentW, listBackgroundH, "2")
		skin.RenderContent(contentX, currentY + listBackgroundH, contentW, detailsBackgroundH, "1_top")


		'=== LIST ===
		currentY :+ listBackgroundH
	

		'=== BOXES ===
		if TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			local price:string = "", reach:string = "", reachChange:string = "", runningCost:string =""
			local headerText:string
			local subHeaderText:string
			local canAfford:int = True
			local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation

			Select TScreenHandler_StationMap.actionMode
				case TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK
					if selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						endif
					endif

				case TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					if selectedStation
						subHeaderText = GetLocale("MAP_COUNTRY_"+selectedStation.GetSectionName())

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						endif

						local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (not finance or finance.canAfford(selectedStation.GetPrice()))
					endif
			End Select


			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, headerColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.drawBlock(subHeaderText, contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			local halfW:int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			if TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			endif
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			if TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				if GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				endif
			endif

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_STATION
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				if canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
				endif
			endif
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH
		endif

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TGameGUISatellitePanel extends TGameGUIBasicStationmapPanel
	Field selectedStation:TStationBase


	Method Create:TGameGUISatellitePanel(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		localeKey_NewItem = "NEW_SATELLITE_UPLINK"
		localeKey_BuyItem = "BUY_SATELLITE_UPLINK"
		localeKey_SellItem = "SELL_SATELLITE_UPLINK"


		'=== register custom event listeners
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]

		return self
	End Method


	'override
	Method GetBuyActionMode:int()
		return TScreenHandler_StationMap.MODE_BUY_SATELLITE
	End Method


	'override
	Method GetSellActionMode:int()
		return TScreenHandler_StationMap.MODE_SELL_SATELLITE
	End Method



	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:int=-1)
		Super.RefreshList(playerID)

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		local listContentWidth:int = list.GetContentScreenWidth()
		For Local station:TStationSatelliteLink = EachIn GetStationMap(playerID).Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create(new TVec2D, new TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:string()
		return GetLocale( "SATELLITE_UPLINKS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.SATELLITE)
	End Method


	Method DrawBodyContent(contentX:int,contentY:int,contentW:int,currentY:int)
		local skin:TDatasheetSkin = GetSkin()
		if not skin then return
		
		local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		local boxAreaH:int = 0
		local showDetails:int = False
		if selectedStation then showDetails = True
		if TScreenHandler_StationMap.actionMode = GetSellActionMode() then showDetails = True
		if TScreenHandler_StationMap.actionMode = GetBuyActionMode() then showDetails = True

		'update information
		detailsBackgroundH = actionButton.GetScreenHeight() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*2)
		listBackgroundH = GetBodyHeight() - detailsBackgroundH
		
		skin.RenderContent(contentX, currentY, contentW, listBackgroundH, "2")
		skin.RenderContent(contentX, currentY + listBackgroundH, contentW, detailsBackgroundH, "1_top")


		'=== LIST ===
		currentY :+ listBackgroundH
	

		'=== BOXES ===
		if TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			local price:string = "", reach:string = "", reachChange:string = "", runningCost:string =""
			local headerText:string
			local subHeaderText:string
			local canAfford:int = True
			local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation

			Select TScreenHandler_StationMap.actionMode
				case TScreenHandler_StationMap.MODE_SELL_SATELLITE
					if selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						endif
					endif

				case TScreenHandler_StationMap.MODE_BUY_SATELLITE
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					if selectedStation
						subHeaderText = selectedStation.GetName()

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						endif

						local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (not finance or finance.canAfford(selectedStation.GetPrice()))
					endif
			End Select


			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, headerColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.drawBlock(subHeaderText, contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			local halfW:int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			if TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			endif
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			if TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				if GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				endif
			endif

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			if TScreenHandler_StationMap.actionMode = GetSellActionMode()
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				if canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
				endif
			endif
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH
		endif

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TSatelliteSelectionFrame
	Field area:TRectangle
	Field contentArea:TRectangle
	Field headerHeight:int
	Field listHeight:int
	Field selectedSatellite:TStationMap_Satellite
	Field satelliteList:TGUISelectList
	Field tooltips:TTooltipBase[]
	Field _open:int = True

	Field _eventListeners:TLink[]


	Method New()
		satelliteList = new TGUISelectList.Create(new TVec2D.Init(610,133), new TVec2D.Init(178, 100), "STATIONMAP")
		'scroll by one entry at a time
		satelliteList.scrollItemHeightPercentage = 1.0
		satelliteList.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)

		'panel handles them (similar to a child - but with manual draw/update calls)
		'satelliteList.SetParent(self)
		GuiManager.Remove(satelliteList)


		tooltips = New TTooltipBase[2]
		For local i:int = 0 until tooltips.length
			tooltips[i] = new TGUITooltipBase.Initialize("", "", new TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = new TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = new TVec2D.Init(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next

		'fill with content
		RefreshSatellitesList()


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerMethod( "stationmapcollection.removeSatellite", self, "OnChangeSatellites" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "stationmapcollection.addSatellite", self, "OnChangeSatellites" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "GUISelectList.onSelectEntry", self, "OnSelectEntryList", satelliteList ) ]

'		return self
	End Method

	
	Method SetLanguage()
		local strings:string[] = [GetLocale("REACH"), GetLocale("Increase"), GetLocale("CONSTRUCTION_TIME"), GetLocale("RUNNING_COSTS"), GetLocale("PRICE")]
		strings = strings[.. tooltips.length]

		For local i:int = 0 until tooltips.length
			if tooltips[i] then tooltips[i].SetContent(strings[i])
		Next
	End Method


	Method OnChangeSatellites:int(triggerEvent:TEventBase)
		RefreshSatellitesList()
	End Method


	'an entry was selected - make the linked station the currently selected station
	Method OnSelectEntryList:int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If not senderList then return False
		If senderList <> satelliteList then return False
		If not GetPlayerBaseCollection().IsPlayer(TScreenHandler_StationMap.currentSubRoom.owner) then return False

		'set the linked satellite as the selected one
		local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		if item
			selectedSatellite = TStationMap_Satellite(item.data.get("satellite"))
		endif
	End Method


	Method SelectSatellite:int(satellite:TStationMap_Satellite)
		selectedSatellite = satellite
		if not selectedSatellite
			satelliteList.DeselectEntry()

			return True
		else
			For local i:TGUIListItem = EachIn satelliteList.entries
				local itemSatellite:TStationMap_Satellite = TStationMap_Satellite(i.data.get("satellite"))
				if itemSatellite = satellite
					satelliteList.SelectEntry(i)

					return True
				endif
			Next
		endif

		return False
	End Method


	Method IsOpen:int()
		return _open
	End Method


	Method Close:int()
		SelectSatellite(null)
		
		_open = False
		return True
	End Method


	Method Open:int()
		_open = True
		return True
	End Method


	Method RefreshSatellitesList:int()
		satelliteList.EmptyList()
		'remove potential highlighted item
		satelliteList.deselectEntry()

		'keep them sorted the way we added the stations
		satelliteList.setListOption(GUILIST_AUTOSORT_ITEMS, False)


		local listContentWidth:int = satelliteList.GetContentScreenWidth()

		For Local satellite:TStationMap_Satellite = EachIn GetStationMapCollection().satellites
			if not satellite.IsLaunched() then continue
			
			local item:TGUISelectListItem = new TGUISelectListItem.Create(new TVec2D, new TVec2D.Init(listContentWidth,20), satellite.name)

			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)

			'link the station to the item
			item.data.Add("satellite", satellite)
			'item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			satelliteList.AddItem( item )
		Next

		return True
	End Method

	
	Method Update:int()
		if contentArea
			if satelliteList.rect.GetX() <> contentArea.GetX()
				satelliteList.SetPosition(contentArea.GetX(), contentArea.GetY() + 16)
			endif
			if satelliteList.GetWidth() <> contentArea.GetW()
				satelliteList.Resize(contentArea.GetW())
			endif
		endif

	
		satelliteList.update()
	End Method


	Method Draw:int()
		local skin:TDatasheetSkin = GetDatasheetSkin("stationMapPanel")
		if not skin then return False

		local owner:int = GetPlayer().playerID
		if TScreenHandler_StationMap.currentSubRoom then owner = TScreenHandler_StationMap.currentSubRoom.owner

		if not area then area = new TRectangle.Init(408, 90, 190, 200)
		if not contentArea then contentArea = new TRectangle

		local detailsH:int = 90 * (selectedSatellite<>null)
		'local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		contentArea.SetW( skin.GetContentW( area.GetW() ) )
		contentArea.SetX( area.GetX() + skin.GetContentX() )
		contentarea.SetY( area.GetY() + skin.GetContentY() )
		contentArea.SetH( area.GetH() - (skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()) )

		headerHeight = 16
		listHeight = contentArea.GetH() - headerHeight - detailsH

		'resize list if needed
		if listHeight <> satelliteList.GetHeight()
			satelliteList.Resize(-1, listHeight)
		endif


		local currentY:int = contentArea.GetY()


		local headerText:string = GetLocale("SATELLITES")
		local titleColor:TColor = new TColor.Create(75,75,75)
		local subTitleColor:TColor = new TColor.Create(115,115,115)



		'=== HEADER ===
		skin.RenderContent(contentArea.GetX(), contentArea.GetY(), contentArea.GetW(), headerHeight, "1_top")
		skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentArea.GetX() + 5, currentY, contentArea.GetW() - 10,  headerHeight, ALIGN_CENTER_CENTER, skin.textColorNeutral, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
		currentY :+ headerHeight

		'=== LIST ===
		skin.RenderContent(contentArea.GetX(), currentY, contentArea.GetW(), listHeight, "2")
		satelliteList.Draw()
		currentY :+ listHeight


		'=== SATELLITE DETAILS ===
		if selectedSatellite
			local titleText:string = selectedSatellite.name
			local subtitleText:string = GetLocale("NOT_LAUNCHED_YET")
			if selectedSatellite.IsLaunched()
				subtitleText = GetLocale("LAUNCHED")+": " + GetWorldTime().GetFormattedDate(selectedSatellite.launchTime, GameConfig.dateFormat)
			endif

			skin.RenderContent(contentArea.GetX(), currentY, contentArea.GetW(), detailsH, "1_top")
			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+titleText+"|/b|", contentArea.GetX() + 5, currentY, contentArea.GetW() - 10,  16, ALIGN_CENTER_CENTER, titleColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			currentY :+ 14
			skin.fontNormal.drawBlock(subTitleText, contentArea.GetX() + 5, currentY, contentArea.GetW() - 10,  16, ALIGN_CENTER_CENTER, subTitleColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			local halfW:int = (contentArea.GetW() - 10)/2 - 2
			'=== BOX LINE 1 ===
			local qualityText:string = "-/-"
			if selectedSatellite.quality <> 100
				qualityText = MathHelper.NumberToString((selectedSatellite.quality-100), 0, True)+"%"
			endif
			local marketShareText:string = MathHelper.NumberToString(100*selectedSatellite.populationShare, 1, True)+"%"

			if selectedSatellite.quality < 100
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, qualityText, "quality", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			else
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, qualityText, "quality", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			endif
			skin.RenderBox(contentArea.GetX() + 5 + halfW-5 + 4, currentY, halfW+5, -1, marketShareText, "marketShare", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			'tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			'tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			local boxH:int = skin.GetBoxSize(100, -1, "").GetY()

			currentY :+ boxH
			local minImageText:string = MathHelper.NumberToString(100*selectedSatellite.minImage, 1, True)+"%"

			if not GetPublicImage(owner) or GetPublicImage(owner).GetAverageImage() < selectedSatellite.minImage
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, minImageText, "image", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			else
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, minImageText, "image", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			endif


			local channelX:int = contentArea.GetX() + 5 + halfW-5 + 4
			skin.RenderBox(channelX, currentY, halfW+5, -1, "", "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			channelX :+ 27

			local oldColor:TColor = new TColor.Get()
			For local i:int = 1 to 4
				SetColor 50,50,50
				SetAlpha oldcolor.a * 0.4
				DrawRect(channelX, currentY + 6, 11,11)
				if selectedSatellite.IsSubscribedChannel(i)
					GetPlayerBase(i).color.SetRGB()
					SetAlpha oldColor.a
				else
					SetColor 255,255,255
					SetAlpha oldColor.a *0.5
				endif
				DrawRect(channelX+1, currentY + 7, 9,9)
				'GetSpriteFromRegistry("gfx_gui_button.datasheet").DrawArea(channelX, currentY + 4, 14, 14)
				channelX :+ 13
			Next
			oldColor.SetRGBA()

		endif


		skin.RenderBorder(area.GetX(), area.GetY(), area.GetW(), area.GetH())

		'debug
		rem
		DrawRect(contentArea.GetX(), contentArea.GetY(), 20, contentArea.GetH() )
		Setcolor 255,0,0
		DrawRect(contentArea.GetX() + 10, contentArea.GetY(), 20, headerHeight )
		Setcolor 255,255,0
		DrawRect(contentArea.GetX() + 20, contentArea.GetY() + headerHeight, 20, listHeight )
		Setcolor 255,0,255
		DrawRect(contentArea.GetX() + 30, contentArea.GetY() + headerHeight + listHeight, 20, detailsH )
		endrem
	End Method
End Type



Type TScreenHandler_StationMap
	global guiAccordeon:TGUIAccordeon
	global satelliteSelectionFrame:TSatelliteSelectionFrame

	global actionMode:int = 0
	global actionConfirmed:int = FALSE

	global selectedStation:TStationBase
	global mouseoverStation:TStationBase
	global mouseoverStationPosition:TVec2D


	global guiShowStations:TGUICheckBox[4]
	global guiFilterButtons:TGUICheckBox[3]
	global guiInfoButton:TGUIButton
	global mapBackgroundSpriteName:String = ""


	global currentSubRoom:TRoomBase = null
	global lastSubRoom:TRoomBase = null

	global LS_stationmap:TLowerString = TLowerString.Create("stationmap")

	Global _eventListeners:TLink[]

	Const PRODUCT_NONE:int = 0
	Const PRODUCT_STATION:int = 1
	Const PRODUCT_CABLE_NETWORK:int = 2
	Const PRODUCT_SATELLITE:int = 3

	Const MODE_NONE:int               =  0
	Const MODE_BUY:int                =  1
	Const MODE_SELL:int               =  2
	Const MODE_SELL_STATION:int       =  4 + MODE_SELL
	Const MODE_BUY_STATION:int        =  8 + MODE_BUY
	Const MODE_SELL_CABLE_NETWORK:int = 16 + MODE_SELL
	Const MODE_BUY_CABLE_NETWORK:int  = 32 + MODE_BUY
	Const MODE_SELL_SATELLITE:int     = 64 + MODE_SELL
	Const MODE_BUY_SATELLITE:int      =128 + MODE_BUY

	'=== THEME CONFIG === 
	Const titleH:int = 18
	Const subTitleH:int = 16
	Const sheetWidth:int = 211
	Const buttonAreaPaddingY:int = 4
	Const boxAreaPaddingY:int = 4
	

	Function Initialize:int()
		local screen:TIngameScreen = TIngameScreen(ScreenCollection.GetScreen("screen_office_stationmap"))
		if not screen then return False

		'remove background from stationmap screen
		'(we draw the map and then the screen bg)
		if screen.backgroundSpriteName <> ""
			mapBackgroundSpriteName = screen.backgroundSpriteName
			screen.backgroundSpriteName = ""
		endif
		
		'=== create gui elements if not done yet
		if not guiInfoButton
			guiAccordeon = New TGameGUIAccordeon.Create(new TVec2D.Init(586, 70), new TVec2D.Init(211, 275), "", "STATIONMAP")
			TGameGUIAccordeon(guiAccordeon).skinName = "stationmapPanel"

			local p:TGUIAccordeonPanel
			p = New TGameGUIAntennaPanel.Create(new TVec2D.Init(-1, -1), new TVec2D.Init(-1, -1), "Stations", "STATIONMAP")
			p.Open()
			guiAccordeon.AddPanel(p, 0)
			p = New TGameGUICableNetworkPanel.Create(new TVec2D.Init(-1, -1), new TVec2D.Init(-1, -1), "Cable Networks", "STATIONMAP")
			guiAccordeon.AddPanel(p, 1)
			p = New TGameGUISatellitePanel.Create(new TVec2D.Init(-1, -1), new TVec2D.Init(-1, -1), "Satellites", "STATIONMAP")
			guiAccordeon.AddPanel(p, 2)


			'== info panel
			guiInfoButton = new TGUIButton.Create(new TVec2D.Init(610, 215), new TVec2D.Init(20, 28), "", "STATIONMAP")
			guiInfoButton.spriteName = "gfx_gui_button.datasheet"
			guiInfoButton.SetTooltip( new TGUITooltipBase.Initialize(GetLocale("SHOW_MAP_DETAILS"), GetLocale("CLICK_TO_SHOW_ADVANCED_MAP_INFORMATION"), new TRectangle.Init(0,0,-1,-1)) )
			guiInfoButton.GetTooltip()._minContentDim = new TVec2D.Init(120,-1)
			guiInfoButton.GetTooltip()._maxContentDim = new TVec2D.Init(150,-1)
			guiInfoButton.GetTooltip().SetOrientationPreset("BOTTOM", 10)

			For Local i:Int = 0 until guiFilterButtons.length
				guiFilterButtons[i] = new TGUICheckBox.Create(new TVec2D.Init(695 + i*23, 30 ), new TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
				guiFilterButtons[i].ShowCaption(False)
				guiFilterButtons[i].data.AddNumber("stationType", i+1)
				'guiFilterButtons[i].SetUnCheckedTintColor( TColor.Create(255,255,255) )
				guiFilterButtons[i].SetUnCheckedTintColor( TColor.Create(210,210,210, 0.75) )
				guiFilterButtons[i].SetCheckedTintColor( TColor.Create(245,255,240) )

				guiFilterButtons[i].uncheckedSpriteName = "gfx_datasheet_icon_" + TVTStationType.GetAsString(i+1) + ".off"
				guiFilterButtons[i].checkedSpriteName = "gfx_datasheet_icon_" + TVTStationType.GetAsString(i+1) + ".on"

				guiFilterbuttons[i].SetTooltip( new TGUITooltipBase.Initialize("", GetLocale("TOGGLE_DISPLAY_OF_STATIONTYPE").Replace("%STATIONTYPE%", "|b|"+GetLocale(TVTStationType.GetAsString(i+1)+"S")+"|/b|"), new TRectangle.Init(0,60,-1,-1)) )
				guiFilterbuttons[i].GetTooltip()._minContentDim = new TVec2D.Init(80,-1)
				guiFilterbuttons[i].GetTooltip()._maxContentDim = new TVec2D.Init(120,-1)
				guiFilterbuttons[i].GetTooltip().SetOrientationPreset("BOTTOM", 10)
			Next


			For Local i:Int = 0 To 3
				guiShowStations[i] = new TGUICheckBox.Create(new TVec2D.Init(695 + i*23, 30 ), new TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
				guiShowStations[i].ShowCaption(False)
				guiShowStations[i].data.AddNumber("playerNumber", i+1)

				guiShowStations[i].SetTooltip( new TGUITooltipBase.Initialize("", GetLocale("TOGGLE_DISPLAY_OF_PLAYER_X").Replace("%X%", i+1), new TRectangle.Init(0,60,-1,-1)) )
				guiShowStations[i].GetTooltip()._minContentDim = new TVec2D.Init(80,-1)
				guiShowStations[i].GetTooltip()._maxContentDim = new TVec2D.Init(120,-1)
				guiShowStations[i].GetTooltip().SetOrientationPreset("BOTTOM", 10)
			Next
		endif


		satelliteSelectionFrame = new TSatelliteSelectionFrame


		'=== reset gui element options to their defaults
		For Local i:Int = 0 until guiShowStations.length
			guiShowStations[i].SetChecked( True, False)
		Next
		For Local i:Int = 0 until guiFilterButtons.length
			guiFilterButtons[i].SetChecked( True, False)
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		'unset "selected station" when other panels get opened 
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiaccordeon.onOpenPanel", OnOpenOrCloseAccordeonPanel, guiAccordeon ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiaccordeon.onClosePanel", OnOpenOrCloseAccordeonPanel, guiAccordeon ) ]

		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]
		'player enters station map screen - set checkboxes according to station map config
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterStationMapScreen, screen ) ]

		'register checkbox changes
		For Local i:Int = 0 until guiShowStations.length
			_eventListeners :+ [ EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, guiShowStations[i]) ]
		Next
		For Local i:Int = 0 until guiFilterButtons.length
			_eventListeners :+ [ EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, guiFilterButtons[i]) ]
		Next

		'to update/draw the screen
		_eventListeners :+ TRoomHandler._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, screen )

		'(re-)localize content
		SetLanguage()
	End Function


	Function SetLanguage()
		if not guiInfoButton then return
		
		guiInfoButton.SetCaption("?")

		guiInfoButton.GetTooltip().SetTitle( GetLocale("SHOW_MAP_DETAILS") )
		guiInfoButton.GetTooltip().SetContent( GetLocale("CLICK_TO_SHOW_ADVANCED_MAP_INFORMATION") )

		For Local i:Int = 0 until guiFilterButtons.length
			guiFilterbuttons[i].GetTooltip().SetContent( GetLocale("TOGGLE_DISPLAY_OF_STATIONTYPE").Replace("%STATIONTYPE%", "|b|"+GetLocale(TVTStationType.GetAsString(i+1)+"S")+"|/b|") )
		Next
		
		For Local i:Int = 0 To 3
			guiShowStations[i].GetTooltip().SetContent( GetLocale("TOGGLE_DISPLAY_OF_PLAYER_X").Replace("%X%", i+1) )
		Next

		For local p:TGameGUIBasicStationmapPanel = EachIn guiAccordeon.panels
			p.SetLanguage()
		Next
	End Function


	Function SetActionMode(mode:int)
		actionMode = mode
	End Function


	Function HasActionMode:int(mode:int, flag:int)
		return (mode & flag) > 0
	End Function


	Function IsInBuyActionMode:int()
		return HasActionMode(actionMode, MODE_BUY)
	End Function


	Function IsInSellActionMode:int()
		return HasActionMode(actionMode, MODE_SELL)
	End Function


	Function _DrawStationMapInfoPanel:Int(x:Int,y:Int, room:TRoomBase)
		'=== PREPARE VARIABLES ===
		local sheetHeight:int = 0 'calculated later

		local skin:TDatasheetSkin = GetDatasheetSkin("stationmapPanel")

		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentX()
		local contentY:int = y + skin.GetContentY()

		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local buttonH:int = 0
		local buttonAreaH:int = 0, bottomAreaH:int = 0

		buttonAreaH = guiInfoButton.rect.GetH() + buttonAreaPaddingY*2

		bottomAreaH :+ buttonAreaH
	
		'total height
		sheetHeight = bottomAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		'=== RENDER ===
	

		'=== BUTTON / CHECKBOX AREA ===
		skin.RenderContent(contentX, contentY, contentW, bottomAreaH, "1_top")


		'=== BUTTON ===
		'move buy button accordingly
		contentY :+ buttonAreaPaddingY
		local buttonX:int = contentX + 5
		guiInfoButton.rect.dimension.SetX(25)
		guiInfoButton.rect.position.SetXY(contentX + 5, contentY)
		buttonX :+ guiInfoButton.rect.GetW() + 6

		for local i:int = 0 until guiFilterButtons.length
			guiFilterButtons[i].rect.position.SetXY(buttonX, contentY + ((guiInfoButton.rect.GetH() - guiFilterButtons[i].rect.GetH())/2) )
			buttonX :+ guiFilterButtons[i].rect.GetW()
		next
		
		for local i:int = 0 until guiShowStations.length
			guiShowStations[i].rect.position.SetXY(contentX + 8 + 50+15+30 + 21*i, contentY + ((guiInfoButton.rect.GetH() - guiShowStations[i].rect.GetH())/2) )
		next
		contentY :+ buttonAreaPaddingY


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function

	
 	Function onDrawStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		if not room then return 0

		'draw map
		GetSpriteFromRegistry("map_Surface").Draw(0,0)

		'when selecting a station position with the mouse or a
		'cable network or a satellite
		if actionMode = MODE_BUY_SATELLITE or actionMode = MODE_BUY_SATELLITE or actionMode = MODE_BUY_CABLE_NETWORK
			SetAlpha float(0.8 + 0.2 * Sin(Millisecs()/6))
			DrawImage(GetStationMapCollection().populationImageOverlay, 0,0)
			SetAlpha 1.0
		endif

		'overlay with alpha channel screen
		GetSpriteFromRegistry(mapBackgroundSpriteName).Draw(0,0)


		_DrawStationMapInfoPanel(586, 5, room)

		'debug draw station map sections
		'TStationMapSection.DrawAll()

		'backgrounds
		If mouseoverStation and mouseoverStation = selectedStation
			'avoid drawing it two times...
			mouseoverStation.DrawBackground(True, True)
		Else
			'also draw the station used for buying/searching
			If mouseoverStation Then mouseoverStation.DrawBackground(False, True)
			'also draw the station used for buying/searching
			If selectedStation Then selectedStation.DrawBackground(True, False)
		EndIf

		
		'draw stations and tooltips
		GetStationMap(room.owner).Draw()

		'also draw the station used for buying/searching
		If mouseoverStation then mouseoverStation.Draw()
		'also draw the station used for buying/searching
		If selectedStation then selectedStation.Draw(true)


		GUIManager.Draw( LS_stationmap )

		For Local i:Int = 0 To 3
			guiShowStations[i].SetUncheckedTintColor( GetPlayerBase(i+1).color.Copy().AdjustBrightness(+0.25).AdjustSaturation(-0.35), False)
			guiShowStations[i].SetCheckedTintColor( GetPlayerBase(i+1).color ) '.Copy().AdjustBrightness(0.25)
			'guiShowStations[i].tintColor = GetPlayerBase(i+1).color '.Copy().AdjustBrightness(0.25)
		Next

		'draw a kind of tooltip over a mouseoverStation
		if mouseoverStation then mouseoverStation.DrawInfoTooltip()

		'draw activation tooltip for all other stations
		'- only draw them while NOT placing a new one (to ease spot finding)
		if actionMode <> MODE_BUY_STATION and actionMode <> MODE_BUY_SATELLITE and actionMode <> MODE_BUY_CABLE_NETWORK
			For Local station:TStationBase = EachIn GetStationMap(room.owner).Stations
				if mouseoverStation = station then continue
				if station.IsActive() then continue

				station.DrawActivationTooltip()
			Next
		endif


		'draw satellite selection frame
'		if actionMode = MODE_BUY_SATELLITE
			if satelliteSelectionFrame.IsOpen()
				satelliteSelectionFrame.Draw()
			endif
'		endif
	End Function


	Function onUpdateStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		if not room then return 0

		'backup room if it changed
		if currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom

			'if we changed the room meanwhile - we have to rebuild the stationList
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList()
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(1)).RefreshList()
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(2)).RefreshList()
		endif

		currentSubRoom = room

		GetStationMap(room.owner).Update()

		'process right click
		if MOUSEMANAGER.isClicked(2) or MouseManager.IsLongClicked(1)
			local reset:int = (selectedStation or mouseoverStation or satelliteSelectionFrame.IsOpen())

			if satelliteSelectionFrame.IsOpen()
				satelliteSelectionFrame.Close()
			else
				ResetActionMode(0)
			endif

			if reset
				MOUSEMANAGER.ResetKey(2)
				MOUSEMANAGER.ResetKey(1) 'also normal clicks
			endif
		Endif


		'buying stations using the mouse
		'1. searching
		If actionMode = MODE_BUY_STATION
			'create a temporary station if not done yet
			if not mouseoverStation then mouseoverStation = GetStationMap(room.owner).GetTemporaryAntennaStation( MouseManager.GetPosition().GetIntX(), MouseManager.GetPosition().GetIntY() )
			local mousePos:TVec2D = new TVec2D.Init( MouseManager.x, MouseManager.y)

			'if the mouse has moved - refresh the station data and move station
			if not mouseoverStation.pos.isSame( mousePos )
				mouseoverStation.pos.CopyFrom(mousePos)
				mouseoverStation.refreshData()
				'refresh state information
				mouseoverStation.GetSectionName(true)
			endif

			local hoveredMapSection:TStationMapSection
			if mouseoverStation then hoveredMapSection = GetStationMapCollection().GetSection(Int(mouseoverStation.pos.x), Int(mouseoverStation.pos.y))

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if hoveredMapSection and mouseoverStation.GetReach() > 0
					selectedStation = GetStationMap(room.owner).GetTemporaryAntennaStation( mouseoverStation.pos.GetIntX(), mouseoverStation.pos.GetIntY() )
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if not hoveredMapSection or mouseoverStation.GetReach() <= 0
				mouseoverStation = null
				mouseoverStationPosition = null
			endif

			if selectedStation
				local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSection(Int(selectedStation.pos.x), Int(selectedStation.pos.y))

				if not selectedMapSection or selectedStation.GetReach() <= 0 then selectedStation = null
			endif


		ElseIf actionMode = MODE_BUY_CABLE_NETWORK
			'if the mouse has moved or nothing was created yet
			'refresh the station data and move station
			if not mouseoverStation or not mouseoverStationPosition or not mouseoverStationPosition.isSame( MouseManager.GetPosition() )
				local mouseOverSection:TStationMapSection = GetStationMapCollection().GetSection( MouseManager.GetPosition().GetIntX(), MouseManager.GetPosition().GetIntY() )
				if mouseOverSection
					mouseoverStationPosition = MouseManager.GetPosition().Copy()
					mouseoverStation = GetStationMap(room.owner).GetTemporaryCableNetworkStation( mouseOverSection.name )
					mouseoverStation.refreshData()
					'refresh state information
					'DO NOT TRUST: Brandenburg's center is berlin - leading
					'              to sectionname = berlin
					mouseOverStation.sectionName = mouseOverSection.name
					'mouseoverStation.GetSectionName(true)
				'remove cache
				elseif mouseoverStation
					mouseoverStation = null
					mouseoverStationPosition = null
				endif
			endif

			local hoveredMapSection:TStationMapSection
			if mouseoverStation and mouseoverStationPosition
				hoveredMapSection = GetStationMapCollection().GetSection(Int(mouseoverStationPosition.x), Int(mouseoverStationPosition.y))
			endif

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if hoveredMapSection and mouseoverStation.GetReach() > 0
					selectedStation = GetStationMap(room.owner).GetTemporaryCableNetworkStation( mouseoverStation.sectionName )
					selectedStation.refreshData()
					'refresh state information
					selectedStation.sectionName = hoveredMapSection.name
					'selectedStation.GetSectionName(true)
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if not hoveredMapSection or mouseoverStation.GetReach() <= 0
				mouseoverStation = null
				mouseoverStationPosition = null
			endif

			if selectedStation
				local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSection(Int(selectedStation.pos.x), Int(selectedStation.pos.y))

				if not selectedMapSection or selectedStation.GetReach() <= 0 then selectedStation = null
			endif
			
		ElseIf actionMode = MODE_BUY_SATELLITE
			if satelliteSelectionFrame.selectedSatellite
				local satLink:TStationSatelliteLink = TStationSatelliteLink(selectedStation)

				if not satLink or satLink.satelliteGUID <> satelliteSelectionFrame.selectedSatellite.GetGUID()
					selectedStation = GetStationMap(room.owner).GetTemporarySatelliteStationBySatelliteGUID( satelliteSelectionFrame.selectedSatellite.GetGUID() )
					selectedStation.refreshData()
				endif
			endif

rem
			'if the mouse has moved or nothing was created yet
			'refresh the station data and move station
			if not mouseoverStation or not mouseoverStationPosition or not mouseoverStationPosition.isSame( MouseManager.GetPosition() )
				local mouseOverSection:TStationMapSection = GetStationMapCollection().GetSection( MouseManager.GetPosition().GetIntX(), MouseManager.GetPosition().GetIntY() )
				if mouseOverSection
					mouseoverStationPosition = MouseManager.GetPosition().Copy()
					mouseoverStation = GetStationMap(room.owner).GetTemporarySatelliteStation( mouseOverSection.name )
					mouseoverStation.refreshData()
					'refresh state information
					mouseOverStation.sectionName = mouseOverSection.name
				'remove cache
				elseif mouseoverStation
					mouseoverStation = null
					mouseoverStationPosition = null
				endif
			endif

			local hoveredMapSection:TStationMapSection
			if mouseoverStation and mouseoverStationPosition
				hoveredMapSection = GetStationMapCollection().GetSection(Int(mouseoverStationPosition.x), Int(mouseoverStationPosition.y))
			endif

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if hoveredMapSection and mouseoverStation.GetReach() > 0
					selectedStation = GetStationMap(room.owner).GetTemporarySatelliteStation( mouseoverStation.sectionName )
					selectedStation.refreshData()
					'refresh state information
					selectedStation.sectionName = hoveredMapSection.name
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if not hoveredMapSection or mouseoverStation.GetReach() <= 0
				mouseoverStation = null
				mouseoverStationPosition = null
			endif

			if selectedStation
				local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSection(Int(selectedStation.pos.x), Int(selectedStation.pos.y))

				if not selectedMapSection or selectedStation.GetReach() <= 0 then selectedStation = null
			endif
endrem
		endif


		if satelliteSelectionFrame.IsOpen()
			satelliteSelectionFrame.Update()
		endif

		
		GUIManager.Update( LS_stationmap )
	End Function


	Function OnOpenOrCloseAccordeonPanel:int( triggerEvent:TEventBase )
		local accordeon:TGameGUIAccordeon = TGameGUIAccordeon(triggerEvent.GetSender())
		if not accordeon or accordeon <> guiAccordeon then return False 

		local panel:TGameGUIAccordeonPanel = TGameGUIAccordeonPanel(triggerEvent.GetData().Get("panel"))


		if triggerEvent.IsTrigger("guiaccordeon.onClosePanel".ToLower())
			'selectedStation = null
			'print "selected = null"
			ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
		endif
	End Function


	Function OnChangeStationMapStation:int( triggerEvent:TEventBase )
		'do nothing when not in a room
		if not currentSubRoom then return FALSE

		TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList( currentSubRoom.owner )
		TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(1)).RefreshList( currentSubRoom.owner )
		TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(2)).RefreshList( currentSubRoom.owner )
	End Function


	Function ResetActionMode(mode:int=0)
		SetActionMode(mode)
		actionConfirmed = FALSE
		'remove selection
		selectedStation = null
		mouseoverStation = Null
		mouseoverStationPosition = null
	End Function


	'===================================
	'Stationmap: Connect GUI elements
	'===================================

	Function OnUpdate_ActionButton:int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if not currentSubRoom or currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE

		Select actionMode
			case MODE_BUY_STATION
				if not selectedStation
					button.SetValue(GetLocale("SELECT_LOCATION")+" ...")
					button.disable()
				else
					local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
					if finance and finance.canAfford(selectedStation.GetPrice())
						button.SetValue(GetLocale("BUY_STATION"))
						button.enable()
					else
						button.SetValue(GetLocale("TOO_EXPENSIVE"))
						button.disable()
					endif
				endif

			case MODE_SELL_STATION
				'different owner or not paid or not sellable
				if selectedStation
					if selectedStation.owner <> GetPlayerBase().playerID
						button.disable()
						button.SetValue(GetLocale("WRONG_PLAYER"))
					elseif not selectedStation.HasFlag(TVTStationFlag.SELLABLE)
						button.SetValue(GetLocale("UNSELLABLE"))
						button.disable()
					elseif not selectedStation.HasFlag(TVTStationFlag.PAID)
						button.SetValue(GetLocale("SELL_STATION"))
						button.disable()
					else
						button.SetValue(GetLocale("SELL_STATION"))
						button.enable()
					endif
				endif

			case MODE_BUY_CABLE_NETWORK
				if not selectedStation
					button.SetValue(GetLocale("SELECT_LOCATION")+" ...")
					button.disable()
				else
					local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
					if finance and finance.canAfford(selectedStation.GetPrice())
						button.SetValue(GetLocale("BUY_CABLE_NETWORK"))
						button.enable()
					else
						button.SetValue(GetLocale("TOO_EXPENSIVE"))
						button.disable()
					endif
				endif

			case MODE_SELL_CABLE_NETWORK
				'different owner or not paid or not sellable
				if selectedStation
					if selectedStation.owner <> GetPlayerBase().playerID
						button.disable()
						button.SetValue(GetLocale("WRONG_PLAYER"))
					elseif not selectedStation.HasFlag(TVTStationFlag.SELLABLE)
						button.SetValue(GetLocale("UNSELLABLE"))
						button.disable()
					elseif not selectedStation.HasFlag(TVTStationFlag.PAID)
						button.SetValue(GetLocale("SELL_CABLE_NETWORK"))
						button.disable()
					else
						button.SetValue(GetLocale("SELL_CABLE_NETWORK"))
						button.enable()
					endif
				endif


			default
				button.SetValue(GetLocale("NEW_STATION"))
				button.enable()
		End Select
	End Function


	'custom drawing function for list entries
	Function DrawMapStationListEntryContent:int(obj:TGUIObject)
		local item:TGUISelectListItem = TGUISelectListItem(obj)
		if not item then return False

		local station:TStationBase = TStationBase(item.data.Get("station"))
		if not station then return False

		local sprite:TSprite
		if station.IsActive()
			sprite = GetSpriteFromRegistry(station.listSpriteNameOn)
		else
			sprite = GetSpriteFromRegistry(station.listSpriteNameOff)
		endif

		local rightValue:string = TFunctions.convertValue(station.GetReach(), 2, 0)
		local paddingLR:int = 2
		local textOffsetX:int = paddingLR + sprite.GetWidth() + 5
		local textOffsetY:int = 2
		local textW:int = item.GetScreenWidth() - textOffsetX - paddingLR

		local currentColor:TColor = new TColor.Get()
		local entryColor:TColor

		'draw with different color according status
		if station.IsActive()
			'colorize antenna for "not sellable ones
			if not station.HasFlag(TVTStationFlag.SELLABLE)
				entryColor = new TColor.Create(120,90,60, currentColor.a)
			else
				entryColor = item.valueColor.copy()
				entryColor.a = currentColor.a
			endif
		else
			entryColor = item.valueColor.copy().AdjustFactor(50)
			entryColor.a = currentColor.a * 0.5
		endif


		'draw antenna
		sprite.Draw(Int(item.GetScreenX() + paddingLR), item.GetScreenY() + 0.5*item.rect.getH(), -1, ALIGN_LEFT_CENTER)
		entryColor.SetRGBA()
		local rightValueWidth:int = item.GetFont().GetWidth(rightValue)
'		item.GetFont().DrawBlock(int(TGUIScrollablePanel(item._parent).scrollPosition.y)+"/"+int(TGUIScrollablePanel(item._parent).scrollLimit.y)+" "+item.GetValue(), Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, int(item.GetScreenHeight() - textOffsetY), ALIGN_LEFT_CENTER, item.valueColor)
		item.GetFont().DrawBlock(item.GetValue(), Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW - rightValueWidth - 5, int(item.GetScreenHeight() - textOffsetY), ALIGN_LEFT_CENTER, item.valueColor, , , , False)
		item.GetFont().DrawBlock(rightValue, Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, int(item.GetScreenHeight() - textOffsetY), ALIGN_RIGHT_CENTER, item.valueColor)

		currentColor.SetRGBA()
	End Function
	

	'set checkboxes according to stationmap config
	Function onEnterStationMapScreen:int(triggerEvent:TEventBase)
		'only players can "enter screens" - so just use "inRoom"
		local owner:int = 0
		if GetPlayer().GetFigure().inRoom then owner = GetPlayer().GetFigure().inRoom.owner
		if owner = 0 then owner = GetPlayerBase().playerID
		
		For local i:int = 0 to 3
			local show:int = GetStationMap(owner).GetShowStation(i+1)
			guiShowStations[i].SetChecked(show)
		Next
	End Function


	Function OnSetChecked_StationMapFilters:int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent._sender)
		if not button then return FALSE

		'ignore clicks if not in the own office
		if not currentSubRoom or currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE

		'player filter
		local player:int = button.data.GetInt("playerNumber", -1)
		if player >= 0
			if not GetPlayerCollection().IsPlayer(player) then return FALSE

			'only set if not done already
			if GetStationMap(GetPlayerBase().playerID).GetShowStation(player) <> button.isChecked()
				TLogger.Log("StationMap", "Stationmap #"+GetPlayerBase().playerID+" show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
				GetStationMap(GetPlayerBase().playerID).SetShowStation(player, button.isChecked())
			endif
		endif

		'station type filter
		local stationType:int = button.data.GetInt("stationType", -1)
		if stationType >= 0
			'only set if not done already
			if GetStationMap(GetPlayerBase().playerID).GetShowStationType(stationType) <> button.isChecked()
				TLogger.Log("StationMap", "Stationmap #"+GetPlayerBase().playerID+" show station type "+stationType+": "+button.isChecked(), LOG_DEBUG)
				GetStationMap(GetPlayerBase().playerID).SetShowStationType(stationType, button.isChecked())
			endif
		endif
	End Function
End Type