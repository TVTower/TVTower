SuperStrict
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"
Import "Dig/base.gfx.gui.accordeon.bmx"
Import "game.screen.base.bmx"
Import "game.stationmap.bmx"
Import "game.player.bmx"
Import "game.room.base.bmx"
Import "game.roomhandler.base.bmx"




Type TGameGUIAccordeon extends TGUIAccordeon
	Field skin:TDatasheetSkin


	Method GetSkin:TDatasheetSkin()
		if not skin
			skin = GetDatasheetSkin("stationmapPanel")
			RefitPanelSizes()
		endif
		
		return skin
	End Method


	Method GetContentScreenWidth:Float()
		if not skin then return GetScreenWidth()
		return skin.GetContentW(GetScreenWidth())
	End Method


	Method GetContentWidth:Float()
		if not skin then return Super.GetContentWidth()
		return skin.GetContentW(GetWidth())
	End Method


	Method GetContentX:Float()
		if not skin then return Super.GetContentX()
		return skin.GetContentX()
	End Method


	Method GetContentY:Float()
		if not skin then return Super.GetContentY()
		return skin.GetContentY()
	End Method


	'override
	Method GetMaxPanelBodyHeight:int()
		if not skin then return Super.GetMaxPanelBodyHeight()
		'subtract skin's border padding
		return skin.GetContentH( super.GetMaxPanelBodyHeight() )
	End Method
		

	Method DrawOverlay()
		'use GetSkin() to fetch the skin when drawing was possible
		GetSkin().RenderBorder(int(GetScreenX()), int(GetScreenY()), int(GetScreenWidth()), int(GetScreenHeight()))
	End Method
End Type




Type TGameGUIAccordeonPanel extends TGUIAccordeonPanel
	Method GetSkin:TDatasheetSkin()
		if TGameGUIAccordeon(GetParent()) then return TGameGUIAccordeon(GetParent()).skin
		return null
	End Method


	Method IsHeaderHovered:int()
		'skip further checks
		if not isHovered() then return False

		local mouseYOffset:int = MouseManager.y - GetScreenY()

		Return mouseYOffset > 0 and mouseYOffset < GetHeaderHeight()
	End Method


	Method GetHeaderValue:string()
		return GetValue()
	End Method


	Method DrawHeader()
		local openStr:string = Chr(9654)
		if isOpen then openStr = Chr(9660)

		local skin:TDatasheetSkin = GetSkin()
		if skin
			local contentW:int = GetScreenWidth()
			local contentX:int = GetScreenX()
			local contentY:int = GetScreenY()
			local headerHeight:int = GetHeaderHeight()

			skin.RenderContent(contentX, contentY, contentW, headerHeight, "1_top")
			if IsHeaderHovered()
				local oldCol:TColor = new TColor.Get()
				SetBlend LightBlend
				SetAlpha 0.25 * oldCol.a
				skin.RenderContent(contentX, contentY, contentW, headerHeight, "1_top")
				SetBlend AlphaBlend
				SetAlpha oldCol.a
			endif
			if isOpen
				skin.fontNormal.drawBlock(openStr + " |b|" +GetHeaderValue()+"|/b|", contentX + 5, contentY, contentW - 10, headerHeight, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				skin.fontNormal.drawBlock(openStr + " " +GetHeaderValue(), contentX + 5, contentY, contentW - 10, headerHeight, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		endif
	End Method


	Method DrawBody()
		local skin:TDatasheetSkin = GetSkin()
		if skin
			skin.RenderContent(int(GetScreenX()), int(GetScreenY() + GetHeaderHeight()), int(GetScreenWidth()), int(GetBodyHeight()), "2")
		endif
	End Method
End Type




Type TGameGUIBasicStationmapPanel extends TGameGUIAccordeonPanel
	Field selectedStation:TStationBase
	Field list:TGUISelectList
	Field actionButton:TGUIButton
	Field cancelButton:TGUIButton
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
				If TScreenHandler_StationMap.selectedStation and TScreenHandler_StationMap.selectedStation.getReach() > 0
					'remove the station (and sell it)
					if GetStationMap( GetPlayerBase().playerID ).RemoveStation(TScreenHandler_StationMap.selectedStation, TRUE)
						ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
					endif
				EndIf

		else
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


	Method Update:int()
		if isOpen
			'move list to here...
			if list.rect.position.GetX() <> 2
				list.SetPosition(2, GetHeaderHeight() + 3 )
				'list.rect.dimension.SetX(GetContentScreenWidth() - 23)
				list.Resize(GetContentScreenWidth() - 23, -1)
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


		'call update after button updates so mouse events are properly
		'emitted
		Super.Update()
	End Method


	Method UpdateActionButton:int()
		'ignore clicks if not in the own office
		if not TScreenHandler_StationMap.currentSubRoom or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE


		If TScreenHandler_StationMap.IsInBuyActionMode()
			if not TScreenHandler_StationMap.selectedStation
				actionButton.SetValue(GetLocale("SELECT_LOCATION")+" ...")
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
		return GetLocale("STATIONS") + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount()
	End Method


	Method DrawBodyContent(contentX:int,contentY:int,contentW:int,currentY:int)
		local skin:TDatasheetSkin = GetSkin()
		if not skin then return
		
		local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		local boxAreaH:int = 0
		local showDetails:int = False
		if selectedStation then showDetails = True
		if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_STATION then showDetails = True
		if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_STATION then showDetails = True

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
						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
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
						subHeaderText = GetLocale("MAP_COUNTRY_"+selectedStation.getFederalState())

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
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_STATION
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			endif

			'=== BOX LINE 2 (optional) ===
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_STATION
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				if GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
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
		return GetLocale( GetValue() ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount()
	End Method


	Method DrawBodyContent(contentX:int,contentY:int,contentW:int,currentY:int)
		local skin:TDatasheetSkin = GetSkin()
		if not skin then return
		
		local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		local boxAreaH:int = 0
		local showDetails:int = False
		if selectedStation then showDetails = True
		if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_STATION then showDetails = True
		if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_STATION then showDetails = True

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
						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
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
						subHeaderText = GetLocale("MAP_COUNTRY_"+selectedStation.getFederalState())

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
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_STATION
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			endif

			'=== BOX LINE 2 (optional) ===
			if TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_STATION
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				if GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
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

			currentY :+ boxH
		endif

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TScreenHandler_StationMap
	global guiAccordeon:TGUIAccordeon


	global guiAntennaList:TGUISelectList
	global guiAntennaActionButton:TGUIButton
	global guiAntennaCancelButton:TGUIButton

	global guiCableNetworkList:TGUISelectList
	global guiCableNetworkActionButton:TGUIButton
	global guiCableNetworkCancelButton:TGUIButton

	global guiSatelliteList:TGUISelectList

	'global selectedProduct:int = PRODUCT_CABLE_NETWORK
	global selectedProduct:int = PRODUCT_STATION
	global actionMode:int = 0
	global actionConfirmed:int = FALSE

	global selectedStation:TStationBase
	global mouseoverStation:TStationBase


	global mapSelectedCableNetwork:TStationCableNetwork
	global mapMouseoverCableNetwork:TStationCableNetwork

	global guiShowStations:TGUITintedCheckBox[4]
	global guiInfoButton:TGUIButton
	global mapBackgroundSpriteName:String = ""

	global currentSubRoom:TRoomBase = null
	global lastSubRoom:TRoomBase = null

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
		if not guiAntennaActionButton
			guiAccordeon = New TGameGUIAccordeon.Create(new TVec2D.Init(380, 70), new TVec2D.Init(211, 275), "", "STATIONMAP")

			local p:TGUIAccordeonPanel
			p = New TGameGUIAntennaPanel.Create(new TVec2D.Init(-1, -1), new TVec2D.Init(-1, -1), "Stations", "STATIONMAP")
			p.Open()
			guiAccordeon.AddPanel(p, 0)
			p = New TGameGUIAntennaPanel.Create(new TVec2D.Init(-1, -1), new TVec2D.Init(-1, -1), "Cable Networks", "STATIONMAP")
			guiAccordeon.AddPanel(p, 1)
			p = New TGameGUIAntennaPanel.Create(new TVec2D.Init(-1, -1), new TVec2D.Init(-1, -1), "Satellites", "STATIONMAP")
			guiAccordeon.AddPanel(p, 2)

		
			'position gets recalculated during drawing (so it can move with the panel)

			'== antennas subpanel
			guiAntennaActionButton = new TGUIButton.Create(new TVec2D.Init(610, 275), new TVec2D.Init(140, 28), "", "STATIONMAP")
			guiAntennaActionButton.spriteName = "gfx_gui_button.datasheet"

			guiAntennaCancelButton = new TGUIButton.Create(new TVec2D.Init(610, 245), new TVec2D.Init(30, 28), "X", "STATIONMAP")
			guiAntennaCancelButton.caption.color = TColor.clRed.copy()
			guiAntennaCancelButton.spriteName = "gfx_gui_button.datasheet"

			guiAntennaList = new TGUISelectList.Create(new TVec2D.Init(610,133), new TVec2D.Init(178, 100), "STATIONMAP")
			'scroll by one entry at a time
			guiAntennaList.scrollItemHeightPercentage = 1.0
			guiAntennaList.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)


			'== cable networks subpanel
			guiCableNetworkActionButton = new TGUIButton.Create(new TVec2D.Init(610, 275), new TVec2D.Init(140, 28), "", "STATIONMAP")
			guiCableNetworkActionButton.spriteName = "gfx_gui_button.datasheet"

			guiCableNetworkCancelButton = new TGUIButton.Create(new TVec2D.Init(610, 245), new TVec2D.Init(30, 28), "X", "STATIONMAP")
			guiCableNetworkCancelButton.caption.color = TColor.clRed.copy()
			guiCableNetworkCancelButton.spriteName = "gfx_gui_button.datasheet"

			guiCableNetworkList = new TGUISelectList.Create(new TVec2D.Init(610,133), new TVec2D.Init(178, 100), "STATIONMAP")
			'scroll by one entry at a time
			guiCableNetworkList.scrollItemHeightPercentage = 1.0
			guiCableNetworkList.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)


			'== info panel
			guiInfoButton = new TGUIButton.Create(new TVec2D.Init(610, 215), new TVec2D.Init(70, 28), "", "STATIONMAP")
			guiInfoButton.spriteName = "gfx_gui_button.datasheet"

			For Local i:Int = 0 To 3
				guiShowStations[i] = new TGUITintedCheckBox.Create(new TVec2D.Init(680 + i*25, 30 ), new TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
				guiShowStations[i].ShowCaption(False)
				guiShowStations[i].data.AddNumber("playerNumber", i+1)
			Next
		endif


		'=== reset gui element options to their defaults
		guiAntennaActionButton.disable()
		guiCableNetworkActionButton.disable()
		For Local i:Int = 0 To 3
			guiShowStations[i].SetChecked(True, False)
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", OnClick_ActionButton, guiAntennaActionButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", OnClick_ActionCancel, guiAntennaCancelButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_ActionButton, guiAntennaActionButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", OnClick_ActionButton, guiCableNetworkActionButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", OnClick_ActionCancel, guiCableNetworkCancelButton ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_ActionButton, guiCableNetworkActionButton ) ]

		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "GUISelectList.onSelectEntry", OnSelectEntry_StationList, guiAntennaList ) ]
		'player enters station map screen - set checkboxes according to station map config
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterStationMapScreen, screen ) ]

		For Local i:Int = 0 To 3
			'register checkbox changes
			_eventListeners :+ [ EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, guiShowStations[i]) ]
		Next

		'to update/draw the screen
		_eventListeners :+ TRoomHandler._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, screen )

		'(re-)localize content
		SetLanguage()
	End Function


	Function SetLanguage()
		if not guiAntennaActionButton then return
		
		guiAntennaActionButton.SetCaption(GetLocale("BUY_STATION"))
		guiCableNetworkActionButton.SetCaption(GetLocale("BUY_CABLE_NETWORK"))
	
		guiInfoButton.SetCaption(GetLocale("DETAILS"))
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
		local contentX:int = x + skin.GetContentY()
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
		guiInfoButton.rect.dimension.SetX(70)
		guiInfoButton.rect.position.SetXY(contentX + 5, contentY)
		for local i:int = 0 to 3
			guiShowStations[i].rect.position.SetXY(contentX + 5 + 70+15 + 23*i, contentY + ((guiInfoButton.rect.GetH() - guiShowStations[i].rect.GetH())/2) )
		Next
		contentY :+ buttonAreaPaddingY


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function


	Function _DrawStationMapPropertyListPanel:Int(x:Int,y:Int, room:TRoomBase)
		'=== PREPARE VARIABLES ===
		local sheetHeight:int = 0 'calculated later

		local skin:TDatasheetSkin = GetDatasheetSkin("stationmapPanel")

		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = x + skin.GetContentY()
		local contentY:int = y + skin.GetContentY()


		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local contentH:int = 0
		local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		local boxAreaH:int = 0
		local buttonAreaH:int = guiInfoButton.rect.GetH() + buttonAreaPaddingY*2
		local listAreaH:int = 0, bottomAreaH:int = 0
		local stationDataAreaH:int
		local stationListAreaH:int
		local stationNameH:int = 16

		local cableNetworkDataAreaH:int
		local cableNetworkListAreaH:int
		local cableNetworkNameH:int = 16

		'local cableListAreaH:int = cableList.rect.GetH() + 6

		contentH:int = 3*subtitleH


		if selectedProduct = PRODUCT_STATION
			stationListAreaH = guiAntennaList.rect.GetH() + 6

			'button plus boxes if searching or trying to sell a station
			if actionMode <> MODE_NONE
				stationDataAreaH = boxAreaPaddingY + stationNameH + 2 * boxH + buttonAreaH
				if actionMode  = MODE_BUY_STATION
					if GameRules.stationConstructionTime > 0
						stationDataAreaH :+ 1 * boxH
					endif
				endif
			else
				stationDataAreaH = buttonAreaH
			endif
		endif
		contentH :+ stationListAreaH + stationDataAreaH

		if selectedProduct = PRODUCT_CABLE_NETWORK
			cableNetworkListAreaH = guiCableNetworkList.rect.GetH() + 6

			'button plus boxes if searching or trying to sell a station
			if actionMode <> MODE_NONE
				cableNetworkDataAreaH = boxAreaPaddingY + cableNetworkNameH + 2 * boxH + buttonAreaH
				if actionMode  = MODE_BUY_CABLE_NETWORK
					if GameRules.cableNetworkConstructionTime > 0
						cableNetworkDataAreaH :+ 1 * boxH
					endif
				endif
			else
				cableNetworkDataAreaH = buttonAreaH
			endif
		endif
		contentH :+ cableNetworkListAreaH + cableNetworkDataAreaH

		

		'total height
		sheetHeight = contentH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		'=== RENDER ===

		'=== PANEL: stations ===
		skin.RenderContent(contentX, contentY, contentW, subTitleH, "1_top")
		'skin.RenderContent(contentX, contentY, contentW, subTitleH, "1")
		skin.fontNormal.drawBlock(Chr(9660) + " " +GetLocale("STATIONS")+": "+GetStationMap(room.owner).GetStationCount(), contentX + 5, contentY, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ subTitleH


		if selectedProduct = PRODUCT_STATION
			skin.RenderContent(contentX, contentY, contentW, stationListAreaH, "2")
			'move list to here...
			if guiAntennaList.rect.position.GetX() <> contentX + 3
				guiAntennaList.rect.position.SetXY(contentX + 3, contentY + 3)
				guiAntennaList.rect.dimension.SetX(contentW - 4)
			endif
			contentY :+ stationListAreaH

			'=== PANEL: stations - details ===
			skin.RenderContent(contentX, contentY, contentW, stationDataAreaH, "1")

			'=== BOXES ===
			if actionMode <> MODE_NONE
				local price:string = "", reach:string = "", reachChange:string = "", runningCost:string =""
				local stationName:string = ""
				local canAfford:int = True

				Select actionMode
					case MODE_SELL_STATION
						if selectedStation
							stationName = selectedStation.GetLongName()
							reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
							reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
							price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
							if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
								runningCost = "-/-"
							else
								runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
							endif
						endif

					case MODE_BUY_STATION
						stationName = GetLocale("NEW_STATION")

						'=== BOXES ===
						if selectedStation
							'stationName = Koordinaten?
							reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
							reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
							price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
							if selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
								runningCost = "-/-"
							else
								runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
							endif

							local finance:TPlayerFinance = GetPlayerFinance(room.owner)
							canAfford = (not finance or finance.canAfford(selectedStation.GetPrice()))
						endif
				End Select

				contentY :+ boxAreaPaddingY
				skin.fontNormal.drawBlock(stationName, contentX + 5, contentY, contentW - 10, stationNameH, ALIGN_CENTER_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				contentY :+ stationNameH


				local halfW:int = (contentW - 10)/2 - 2
				'=== BOX LINE 1 ===
				skin.RenderBox(contentX + 5, contentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
				if actionMode = MODE_BUY_STATION
					skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
				else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
				endif

				'=== BOX LINE 2 (optional) ===
				if actionMode = MODE_BUY_STATION
					'TODO: individual build time for stations ("GetStationConstructionTime()")?
					if GameRules.stationConstructionTime > 0
						contentY :+ boxH
						skin.RenderBox(contentX + 5, contentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					endif
				endif

				'=== BOX LINE 3 ===
				contentY :+ boxH
				skin.RenderBox(contentX + 5, contentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
				if actionMode = MODE_SELL_STATION
					skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					'fetch financial state of room owner (not player - so take care
					'if the player is allowed to do this)
					if canAfford
						skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
					else
						skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
					endif
				endif

				contentY :+ boxH
			endif

			'=== BUTTONS ===
			guiAntennaActionButton.rect.position.SetXY(contentX + 5, contentY + 3)
			guiAntennaCancelButton.rect.position.SetXY(contentX + 5 + 150, contentY + 3)
			contentY :+ buttonAreaH

			if actionMode = MODE_NONE
				guiAntennaCancelButton.Hide()
				guiAntennaActionButton.Resize(contentW - 10, -1)
			else
				guiAntennaActionButton.Resize(150, -1)
				guiAntennaCancelButton.Show()
			endif

			guiAntennaList.Show()
			guiAntennaActionButton.Show()
		else
			guiAntennaList.Hide()
			guiAntennaActionButton.Hide()
			guiAntennaCancelButton.Hide()
		endif




		'=== PANEL: cable ===
		skin.RenderContent(contentX, contentY, contentW, subTitleH, "1")
		skin.fontNormal.drawBlock(Chr(9654) + " " +GetLocale("CABLE_NETWORK")+": 1/15", contentX + 5, contentY, contentW - 10, subTitleH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ subTitleH


		if selectedProduct = PRODUCT_CABLE_NETWORK
			skin.RenderContent(contentX, contentY, contentW, cableNetworkListAreaH, "2")
			'move list to here...
			if guiCableNetworkList.rect.position.GetX() <> contentX + 3
				guiCableNetworkList.rect.position.SetXY(contentX + 3, contentY + 3)
				guiCableNetworkList.rect.dimension.SetX(contentW - 4)
			endif
			contentY :+ cableNetworkListAreaH

			'=== PANEL: cable network - details ===
			skin.RenderContent(contentX, contentY, contentW, cableNetworkDataAreaH, "1")

			'=== BOXES ===
			if actionMode <> MODE_NONE
				local price:string = "", reach:string = "", reachChange:string = "", runningCost:string =""
				local cableNetworkName:string = ""
				local canAfford:int = True

				Select actionMode
					case MODE_SELL_CABLE_NETWORK
						if mapSelectedCableNetwork
							cableNetworkName = mapSelectedCableNetwork.GetLongName()
							reach = TFunctions.convertValue(mapSelectedCableNetwork.getReach(), 2)
							reachChange = MathHelper.DottedValue(mapSelectedCableNetwork.getReachDecrease())
							price = TFunctions.convertValue(mapSelectedCableNetwork.getSellPrice(), 2, 0)
							if mapSelectedCableNetwork.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
								runningCost = "-/-"
							else
								runningCost = TFunctions.convertValue(mapSelectedCableNetwork.GetRunningCosts(), 2, 0)
							endif
						endif

					case MODE_BUY_CABLE_NETWORK
						cableNetworkName = GetLocale("NEW_CABLE_NETWORK")

						'=== BOXES ===
						if mapSelectedCableNetwork
							reach = TFunctions.convertValue(mapSelectedCableNetwork.getReach(), 2)
							reachChange = MathHelper.DottedValue(mapSelectedCableNetwork.getReachIncrease())
							price = TFunctions.convertValue(mapSelectedCableNetwork.getPrice(), 2, 0)
							if mapSelectedCableNetwork.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
								runningCost = "-/-"
							else
								runningCost = TFunctions.convertValue(mapSelectedCableNetwork.GetRunningCosts(), 2, 0)
							endif

							local finance:TPlayerFinance = GetPlayerFinance(room.owner)
							canAfford = (not finance or finance.canAfford(mapSelectedCableNetwork.GetPrice()))
						endif
				End Select

				contentY :+ boxAreaPaddingY
				skin.fontNormal.drawBlock(cableNetworkName, contentX + 5, contentY, contentW - 10, cableNetworkNameH, ALIGN_CENTER_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				contentY :+ cableNetworkNameH


				local halfW:int = (contentW - 10)/2 - 2
				'=== BOX LINE 1 ===
				skin.RenderBox(contentX + 5, contentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
				if actionMode = MODE_BUY_CABLE_NETWORK
					skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
				else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
				endif

				'=== BOX LINE 2 (optional) ===
				if actionMode = MODE_BUY_CABLE_NETWORK
					'TODO: individual build time for networks ("GetConstructionTime()")?
					if GameRules.cableNetworkConstructionTime > 0
						contentY :+ boxH
						skin.RenderBox(contentX + 5, contentY, halfW-5, -1, GameRules.cableNetworkConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					endif
				endif

				'=== BOX LINE 3 ===
				contentY :+ boxH
				skin.RenderBox(contentX + 5, contentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
				if actionMode = MODE_SELL_CABLE_NETWORK
					skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					'fetch financial state of room owner (not player - so take care
					'if the player is allowed to do this)
					if canAfford
						skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
					else
						skin.RenderBox(contentX + 5 + halfW-5 + 4, contentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
					endif
				endif

				contentY :+ boxH
			endif

			'=== BUTTONS ===
			guiCableNetworkActionButton.rect.position.SetXY(contentX + 5, contentY + 3)
			guiCableNetworkCancelButton.rect.position.SetXY(contentX + 5 + 150, contentY + 3)
			contentY :+ buttonAreaH

			if actionMode = MODE_NONE
				guiCableNetworkCancelButton.Hide()
				guiCableNetworkActionButton.Resize(contentW - 10, -1)
			else
				guiCableNetworkActionButton.Resize(150, -1)
				guiCableNetworkCancelButton.Show()
			endif

			guiCableNetworkActionButton.Show()
			guiCableNetworkList.Show()
		else
			guiCableNetworkList.Hide()
			guiCableNetworkActionButton.Hide()
			guiCableNetworkCancelButton.Hide()
		endif




		'=== PANEL: statellites ===
		skin.RenderContent(contentX, contentY, contentW, subTitleH, "1")
		skin.fontNormal.drawBlock(Chr(9654) + " " +GetLocale("SATELLITES")+": 1/15", contentX + 5, contentY, contentW - 10, subTitleH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ subTitleH



		
		'=== BOTTOM AREA ===
		'TODO
		'skin.RenderContent(contentX, contentY, contentW, bottomAreaH, "1")

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function


	
global LS_stationmap:TLowerString = TLowerString.Create("stationmap")

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
			DrawImage(GetStationMapCollection().populationImage, 0,0)
			SetAlpha 1.0
		endif

		'overlay with alpha channel screen
		GetSpriteFromRegistry(mapBackgroundSpriteName).Draw(0,0)

		_DrawStationMapInfoPanel(586, 5, room)
		_DrawStationMapPropertyListPanel(586, 70, room)

		'debug draw station map sections
		'TStationMapSection.DrawAll()
		
		'draw stations and tooltips
		GetStationMap(room.owner).Draw()

		'also draw the station used for buying/searching
		If mouseoverStation then mouseoverStation.Draw()
		'also draw the station used for buying/searching
		If selectedStation then selectedStation.Draw(true)


		GUIManager.Draw( LS_stationmap )

		For Local i:Int = 0 To 3
			guiShowStations[i].tintColor = GetPlayerBase(i+1).color '.Copy().AdjustBrightness(0.25)
'			SetColor 100, 100, 100
'			DrawRect(544, 32 + i * 25, 15, 18)
'			GetPlayerBase(i+1).color.SetRGB()
'			DrawRect(545, 33 + i * 25, 13, 16)
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
	End Function


	Function onUpdateStationMap:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		if not room then return 0

		'backup room if it changed
		if currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom
			'if we changed the room meanwhile - we have to rebuild the stationList
			RefreshStationAntennaList()
			RefreshStationCableNetworkList()


			TGameGUIAntennaPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList()
		endif

		currentSubRoom = room

		GetStationMap(room.owner).Update()

		'process right click
		if MOUSEMANAGER.isClicked(2) or MouseManager.IsLongClicked(1)
			local reset:int = (selectedStation or mouseoverStation)

			ResetActionMode(0)

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
				mouseoverStation.getFederalState(true)
			endif

			local hoveredMapSection:TStationMapSection
			if mouseoverStation then hoveredMapSection = TStationMapSection.get(Int(mouseoverStation.pos.x), Int(mouseoverStation.pos.y))

			'if mouse gets clicked, we store that position in a separate station
			if MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				if hoveredMapSection and mouseoverStation.getReach() > 0
					selectedStation = GetStationMap(room.owner).GetTemporaryAntennaStation( mouseoverStation.pos.GetIntX(), mouseoverStation.pos.GetIntY() )
				endif
			endif

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			if not hoveredMapSection or mouseoverStation.getReach() <= 0 then mouseoverStation = null

			if selectedStation
				local selectedMapSection:TStationMapSection = TStationMapSection.get(Int(selectedStation.pos.x), Int(selectedStation.pos.y))

				if not selectedMapSection or selectedStation.GetReach() <= 0 then selectedStation = null
			endif
		endif

		GUIManager.Update( LS_stationmap )
	End Function


	Function OnChangeStationMapStation:int( triggerEvent:TEventBase )
		if not currentSubRoom then return FALSE
		'do nothing when not in a room

		RefreshStationAntennaList( currentSubRoom.owner )
		RefreshStationCableNetworkList( currentSubRoom.owner )

		TGameGUIAntennaPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList( currentSubRoom.owner )
	End Function


	Function ResetActionMode(mode:int=0)
		SetActionMode(mode)
		actionConfirmed = FALSE
		'remove selection
		selectedStation = null
		mouseoverStation = Null

		'reset gui list
		guiAntennaList.deselectEntry()
		guiCableNetworkList.deselectEntry()
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

			default
				button.SetValue(GetLocale("NEW_STATION"))
				button.enable()
		End Select
	End Function


	Function OnClick_ActionButton:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if not currentSubRoom or currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE


		Select actionMode
			case MODE_BUY_STATION
				If selectedStation and selectedStation.GetReach() > 0
					'add the station (and buy it)
					if GetStationMap( GetPlayerBase().playerID ).AddStation(selectedStation, TRUE)
						ResetActionMode(MODE_NONE)
					endif
				EndIf
				
			case MODE_SELL_STATION
				If selectedStation and selectedStation.getReach() > 0
					'remove the station (and sell it)
					if GetStationMap( GetPlayerBase().playerID ).RemoveStation(selectedStation, TRUE)
						ResetActionMode(MODE_NONE)
					endif
				EndIf

			default
				ResetActionMode(MODE_BUY_STATION)
		End Select
	End Function


	Function OnClick_ActionCancel:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If not button then return FALSE

		'ignore clicks if not in the own office
		if not currentSubRoom or currentSubRoom.owner <> GetPlayerBase().playerID then return FALSE

		ResetActionMode(MODE_NONE)
	End Function


	'rebuild the stationList - eg. when changed the room (other office)
	Function RefreshStationAntennaList(playerID:int=-1)
		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		'first fill of stationlist
		guiAntennaList.EmptyList()
		'remove potential highlighted item
		guiAntennaList.deselectEntry()


		local listContentWidth:int = guiAntennaList.GetContentScreenWidth()
		'keep them sorted the way we add the stations
		guiAntennaList.setListOption(GUILIST_AUTOSORT_ITEMS, False)
		For Local station:TStationAntenna = EachIn GetStationMap(playerID).Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create(new TVec2D, new TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = DrawMapStationListEntryContent
			guiAntennaList.AddItem( item )
		Next
	End Function


	'rebuild the stationList - eg. when changed the room (other office)
	Function RefreshStationCableNetworkList(playerID:int=-1)
		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		'first fill of stationlist
		guiCableNetworkList.EmptyList()
		'remove potential highlighted item
		guiCableNetworkList.deselectEntry()


		local listContentWidth:int = guiCableNetworkList.GetContentScreenWidth()
		'keep them sorted the way we add the stations
		guiCableNetworkList.setListOption(GUILIST_AUTOSORT_ITEMS, False)
		For Local station:TStationCableNetwork = EachIn GetStationMap(playerID).Stations
			local item:TGUISelectListItem = new TGUISelectListItem.Create(new TVec2D, new TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = DrawMapStationListEntryContent
			guiCableNetworkList.AddItem( item )
		Next
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

		local rightValue:string = TFunctions.convertValue(station.reach, 2, 0)
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

		entryColor.SetRGBA()

		'draw antenna
		sprite.Draw(Int(item.GetScreenX() + paddingLR), item.GetScreenY() + 0.5*item.rect.getH(), -1, ALIGN_LEFT_CENTER)
'		item.GetFont().DrawBlock(int(TGUIScrollablePanel(item._parent).scrollPosition.y)+"/"+int(TGUIScrollablePanel(item._parent).scrollLimit.y)+" "+item.GetValue(), Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, int(item.GetScreenHeight() - textOffsetY), ALIGN_LEFT_CENTER, item.valueColor)
		item.GetFont().DrawBlock(item.GetValue(), Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, int(item.GetScreenHeight() - textOffsetY), ALIGN_LEFT_CENTER, item.valueColor)
		item.GetFont().DrawBlock(rightValue, Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, int(item.GetScreenHeight() - textOffsetY), ALIGN_RIGHT_CENTER, item.valueColor)

		currentColor.SetRGBA()
	End Function
	

	'an entry was selected - make the linked station the currently selected station
	Function OnSelectEntry_StationList:int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If not senderList then return FALSE

		if not currentSubRoom or not GetPlayerBaseCollection().IsPlayer(currentSubRoom.owner) then return FALSE

		'set the linked station as selected station
		'also set the stationmap's userAction so the map knows we want to sell
		local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		if item
			selectedStation = TStationBase(item.data.get("station"))
			if selectedStation
				'force stat refresh (so we can display decrease properly)!
				selectedStation.GetReachDecrease(True)
			endif


			if TStationAntenna(selectedStation)
				SetActionMode(MODE_SELL_STATION)
			elseif TStationCableNetwork(selectedStation)
				SetActionMode(MODE_SELL_CABLE_NETWORK)
			endif
		endif
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

		local player:int = button.data.GetInt("playerNumber", -1)
		if not GetPlayerCollection().IsPlayer(player) then return FALSE

		'only set if not done already
		if GetStationMap(player).GetShowStation(player) <> button.isChecked()
			TLogger.Log("StationMap", "show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
			GetStationMap(player).SetShowStation(player, button.isChecked())
		endif
	End Function
End Type




Type TGUITintedCheckBox extends TGUICheckBox
	Field tintColor:TColor
	

	Method Create:TGUITintedCheckbox(pos:TVec2D, dimension:TVec2D, value:String, limitState:String="")
		Super.Create(pos, dimension, value, limitState)
		return self
	End Method


	Method SetTintColor(color:TColor)
		if color
			self.tintColor = color.Copy()
		else
			self.tintColor = null
		endif
	End Method


	'override to "simple" tint the checkbox
	Method DrawContent()
		local oldColor:TColor
		if tintColor
			oldColor = new TColor.Get()
			tintColor.SetRGBA()
		endif

		Super.DrawContent()

		if tintColor and oldColor then oldColor.SetRGBA()
	End Method
End Type