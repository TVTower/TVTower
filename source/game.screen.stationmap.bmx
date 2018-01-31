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




Type TGameGUIBasicStationmapPanel Extends TGameGUIAccordeonPanel
'	Field selectedStation:TStationBase
	Field list:TGUISelectList
	Field actionButton:TGUIButton
	Field cancelButton:TGUIButton
	Field tooltips:TTooltipBase[]

	Field listExtended:Int = False
	Field detailsBackgroundH:Int
	Field listBackgroundH:Int
	Field localeKey_NewItem:String = "NEW_ITEM"
	Field localeKey_BuyItem:String = "BUY_ITEM"
	Field localeKey_SellItem:String = "SELL_ITEM"
	
	Field _eventListeners:TLink[]
	Field headerColor:TColor = New TColor.Create(75,75,75)
	Field subHeaderColor:TColor = New TColor.Create(115,115,115)


	Method Create:TGameGUIBasicStationmapPanel(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		actionButton = New TGUIButton.Create(New TVec2D.Init(0, 0), New TVec2D.Init(150, 28), "", "STATIONMAP")
		actionButton.spriteName = "gfx_gui_button.datasheet"

		cancelButton = New TGUIButton.Create(New TVec2D.Init(145, 0), New TVec2D.Init(30, 28), "X", "STATIONMAP")
		cancelButton.caption.color = TColor.clRed.copy()
		cancelButton.spriteName = "gfx_gui_button.datasheet"

		list = New TGUISelectList.Create(New TVec2D.Init(610,133), New TVec2D.Init(178, 100), "STATIONMAP")
		'scroll by one entry at a time
		list.scrollItemHeightPercentage = 1.0
		list.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)


		cancelButton.SetParent(Self)
		actionButton.SetParent(Self)
		list.SetParent(Self)

		'panel handles them (similar to a child - but with manual draw/update calls)
		GuiManager.Remove(cancelButton)
		GuiManager.Remove(actionButton)
		GuiManager.Remove(list)


		tooltips = New TTooltipBase[5]
		For Local i:Int = 0 Until tooltips.length
			tooltips[i] = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = New TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = New TVec2D.Init(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]

		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onClick", Self, "OnClickActionButton", actionButton ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "guiobject.onClick", Self, "OnClickCancelButton", cancelButton ) ]
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.removeStation", OnChangeStationMapStation ) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction( "stationmap.addStation", OnChangeStationMapStation ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "GUISelectList.onSelectEntry", Self, "OnSelectEntryList", list ) ]

		Return Self
	End Method


	Method SetLanguage()
		Local strings:String[] = [GetLocale("REACH"), GetLocale("Increase"), GetLocale("CONSTRUCTION_TIME"), GetLocale("RUNNING_COSTS"), GetLocale("PRICE")]
		strings = strings[.. tooltips.length]

		For Local i:Int = 0 Until tooltips.length
			If tooltips[i] Then tooltips[i].SetContent(strings[i])
		Next
	End Method


	Method OnClickActionButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		If TScreenHandler_StationMap.IsInBuyActionMode()
			If TScreenHandler_StationMap.selectedStation And TScreenHandler_StationMap.selectedStation.GetReach() > 0
				'add the station (and buy it)
				If GetStationMap( GetPlayerBase().playerID ).AddStation(TScreenHandler_StationMap.selectedStation, True)
					ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
				EndIf
			EndIf

		ElseIf TScreenHandler_StationMap.IsInSellActionMode()
			If TScreenHandler_StationMap.selectedStation And TScreenHandler_StationMap.selectedStation.GetReach() > 0
				'remove the station (and sell it)
				If GetStationMap( GetPlayerBase().playerID ).RemoveStation(TScreenHandler_StationMap.selectedStation, True)
					ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
				EndIf
			EndIf

		Else
			'open up satellite selection frame for the satellite link panel
			If GetBuyActionMode() = TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
				TScreenHandler_StationMap.satelliteSelectionFrame.Open()
			EndIf

			ResetActionMode( GetBuyActionMode() )
		EndIf

		Return True
	End Method


	Method OnClickCancelButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
	End Method


	'an entry was selected - make the linked station the currently selected station
	Method OnSelectEntryList:Int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If Not senderList Then Return False
		If Not TScreenHandler_StationMap.currentSubRoom Then Return False
		If Not TScreenHandler_StationMap.currentSubRoom Or Not GetPlayerBaseCollection().IsPlayer(TScreenHandler_StationMap.currentSubRoom.owner) Then Return False

		'set the linked station as selected station
		'also set the stationmap's userAction so the map knows we want to sell
		Local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		If item
			TScreenHandler_StationMap.selectedStation = TStationBase(item.data.get("station"))
			If TScreenHandler_StationMap.selectedStation
				'force stat refresh (so we can display decrease properly)!
				TScreenHandler_StationMap.selectedStation.GetReachDecrease(True)
			EndIf

			SetActionMode( GetSellActionMode() )
		EndIf
	End Method


	Method SetActionMode(mode:Int)
		TScreenHandler_StationMap.SetActionMode(mode)
	End Method


	Method ResetActionMode(mode:Int=0)
		TScreenHandler_StationMap.ResetActionMode(mode)

		'remove selection
		TScreenHandler_StationMap.selectedStation = Null

		'reset gui list
		list.deselectEntry()
	End Method


	Method GetBuyActionMode:Int()
		Return TScreenHandler_StationMap.MODE_NONE
	End Method


	Method GetSellActionMode:Int()
		Return TScreenHandler_StationMap.MODE_NONE
	End Method


	Method RefreshList(playerID:Int=-1)
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
	

	Method Update:Int()
		If isOpen
			'move list to here...
			If list.rect.position.GetX() <> 2
				list.SetPosition(2, GetHeaderHeight() + 3 )
'local tt:TTypeID = TTypeId.ForObject(self)
'print tt.name() + "   " + GetContentScreenWidth()
				'list.rect.dimension.SetX(GetContentScreenWidth() - 23)
				'resizing is done when status changes
'				list.Resize(GetContentScreenWidth() - 23, -1)
			EndIf

			'adjust list size if needed
			Local listH:Int = listBackgroundH - 6
			If listBackgroundH > 0 And list.GetHeight() <> listH
				list.Resize(-1, listH)
'				list.RecalculateElements()
			EndIf

			
			actionButton.SetPosition(5, GetHeaderHeight() + GetBodyHeight() - 34 )
			cancelButton.SetPosition(5 + 150, GetHeaderHeight() + GetBodyHeight() - 34 )

			UpdateActionButton()

			list.Update()
			actionButton.Update()
			cancelButton.Update()
		EndIf


		'update count in title
		If TScreenHandler_StationMap.currentSubRoom 
			SetValue( GetHeaderValue() )
		EndIf


		For Local t:TTooltipBase = EachIn tooltips
			t.Update()
		Next


		'call update after button updates so mouse events are properly
		'emitted
		Super.Update()
	End Method


	Method UpdateActionButton:Int()
		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		If TScreenHandler_StationMap.IsInBuyActionMode()
			If Not TScreenHandler_StationMap.selectedStation
				If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
					actionButton.SetValue(GetLocale("SELECT_SATELLITE")+" ...")
				Else
					actionButton.SetValue(GetLocale("SELECT_LOCATION")+" ...")
				EndIf
				actionButton.disable()
			Else
				Local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
				If finance And finance.canAfford(TScreenHandler_StationMap.selectedStation.GetPrice())
					actionButton.SetValue(GetLocale( localeKey_BuyItem))
					actionButton.enable()
				Else
					actionButton.SetValue(GetLocale("TOO_EXPENSIVE"))
					actionButton.disable()
				EndIf
			EndIf

		ElseIf TScreenHandler_StationMap.IsInSellActionMode()
			'different owner or not paid or not sellable
			If TScreenHandler_StationMap.selectedStation
				If TScreenHandler_StationMap.selectedStation.owner <> GetPlayerBase().playerID
					actionButton.disable()
					actionButton.SetValue(GetLocale("WRONG_PLAYER"))
				ElseIf Not TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.SELLABLE)
					actionButton.SetValue(GetLocale("UNSELLABLE"))
					actionButton.disable()
				ElseIf Not TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.PAID)
					actionButton.SetValue(GetLocale( localeKey_SellItem ))
					actionButton.disable()
				Else
					actionButton.SetValue(GetLocale( localeKey_SellItem ))
					actionButton.enable()
				EndIf
			EndIf

		Else
			actionButton.SetValue(GetLocale( localeKey_NewItem ))
			actionButton.enable()
		EndIf

		Return True
	End Method


	'override
	Method DrawBody()
		'draw nothing if not open
		If Not isOpen Then Return

		
		Local skin:TDatasheetSkin = GetSkin()
		If skin
			Local contentX:Int = GetScreenX()
			Local contentY:Int = GetScreenY()
			Local contentW:Int = GetScreenWidth()
			Local currentY:Int = contentY + GetHeaderHeight()


			DrawBodyContent(contentX, contentY, contentW, currentY)


			If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_NONE
				cancelButton.Hide()
				actionButton.Resize(contentW - 10, -1)
			Else
				actionButton.Resize(150, -1)
				cancelButton.Show()
			EndIf

		EndIf

		list.Draw()
		actionButton.Draw()
		cancelButton.Draw()


		For Local t:TTooltipBase = EachIn tooltips
			t.Render()
		Next

	End Method


	Method DrawBodyContent(contentX:Int, contentY:Int, contentW:Int, contentH:Int)
		'by default draw nothing
	End Method
End Type




Type TGameGUIAntennaPanel Extends TGameGUIBasicStationmapPanel
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

		Return Self
	End Method


	'override
	Method GetBuyActionMode:Int()
		Return TScreenHandler_StationMap.MODE_BUY_ANTENNA
	End Method


	'override
	Method GetSellActionMode:Int()
		Return TScreenHandler_StationMap.MODE_SELL_ANTENNA
	End Method


	'===================================
	'EVENTS: Connect GUI elements
	'===================================


	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:Int=-1)
		Super.RefreshList(playerID)

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		Local listContentWidth:Int = list.GetContentScreenWidth()
		For Local station:TStationAntenna = EachIn GetStationMap(playerID).Stations
			Local item:TGUISelectListItem = New TGUISelectListItem.Create(New TVec2D, New TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:String()
		If TScreenHandler_StationMap.currentSubRoom And GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner)
			Return GetLocale( "STATIONS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.ANTENNA)
		Else
			Return GetLocale( "STATIONS" ) + ": -/-"
		EndIf
	End Method


	Method DrawBodyContent(contentX:Int,contentY:Int,contentW:Int,currentY:Int)
		Local skin:TDatasheetSkin = GetSkin()
		If Not skin Then Return

		Local section:TStationMapSection
		If TScreenHandler_StationMap.selectedStation Then section = GetStationMapCollection().GetSectionByName(TScreenHandler_StationMap.selectedStation.GetSectionName())

		Local boxH:Int = skin.GetBoxSize(100, -1, "").GetY()
		Local boxAreaH:Int = 0
		Local showDetails:Int = False
		Local showPermissionText:Int = False
		Local permissionTextH:int = 24
		'only show when buying/looking for a new
		If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_ANTENNA 
			If TScreenHandler_StationMap.selectedStation And section And section.NeedsBroadcastPermission(TScreenHandler_StationMap.selectedStation.owner, TVTStationType.SATELLITE_UPLINK)
				showPermissionText = True
			EndIf
		EndIf
		If TScreenHandler_StationMap.selectedStation Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetSellActionMode() Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() Then showDetails = True

		'update information
		detailsBackgroundH = actionButton.GetScreenHeight() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*2) + showPermissionText * permissionTextH
		
		listBackgroundH = GetBodyHeight() - detailsBackgroundH
		
		skin.RenderContent(contentX, currentY, contentW, listBackgroundH, "2")
		skin.RenderContent(contentX, currentY + listBackgroundH, contentW, detailsBackgroundH, "1_top")


		'=== LIST ===
		currentY :+ listBackgroundH
	

		'=== BOXES ===
		If TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			Local price:String = "", reach:String = "", reachChange:String = "", runningCost:String =""
			Local headerText:String
			Local subHeaderText:String
			Local canAfford:Int = True
			Local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation

			Select TScreenHandler_StationMap.actionMode
				Case TScreenHandler_StationMap.MODE_SELL_ANTENNA
					If selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue( -1 * selectedStation.GetReachDecrease() )
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						If selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						Else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						EndIf
					EndIf

				Case TScreenHandler_StationMap.MODE_BUY_ANTENNA
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					If selectedStation
						local totalPrice:int = GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetTotalStationPrice(selectedStation)

						subHeaderText = GetLocale("MAP_COUNTRY_"+selectedStation.GetSectionName())

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue( totalPrice, 2, 0)
						If selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						Else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						EndIf

						Local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (Not finance Or finance.canAfford(totalPrice))
					EndIf
			End Select


			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, headerColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.drawBlock(subHeaderText, contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			Local halfW:Int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			Else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			EndIf
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)


			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				If GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				EndIf
			EndIf

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_ANTENNA
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			Else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				If canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
				EndIf
			EndIf
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH

			If showPermissionText And section And selectedStation
				If Not section.HasBroadcastPermission(selectedStation.owner)
					skin.fontNormal.drawBlock(getLocale("PRICE_INCLUDES_X_FOR_BROADCAST_PERMISSION").Replace("%X%", "|b|"+TFunctions.convertValue(section.GetBroadcastPermissionPrice(selectedStation.owner), 2, 0) + " " + GetLocale("CURRENCY")+"|/b|"), contentX + 5, currentY, contentW - 10, permissionTextH, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
				Else
					currentY :- 1 'align it a bit better
					skin.fontNormal.drawBlock(getLocale("BROADCAST_PERMISSION_EXISTING"), contentX + 5, currentY, contentW - 10, permissionTextH, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
				EndIf
			EndIf
		EndIf

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TGameGUICableNetworkPanel Extends TGameGUIBasicStationmapPanel
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

		Return Self
	End Method


	'override
	Method GetBuyActionMode:Int()
		Return TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK_UPLINK
	End Method


	'override
	Method GetSellActionMode:Int()
		Return TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK_UPLINK
	End Method



	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:Int=-1)
		Super.RefreshList(playerID)

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		Local listContentWidth:Int = list.GetContentScreenWidth()
		For Local station:TStationCableNetworkUplink = EachIn GetStationMap(playerID).Stations
			Local item:TGUISelectListItem = New TGUISelectListItem.Create(New TVec2D, New TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:String()
		If TScreenHandler_StationMap.currentSubRoom And GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner)
			Return GetLocale( "CABLE_NETWORK_UPLINKS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.CABLE_NETWORK_UPLINK)
		Else
			Return GetLocale( "CABLE_NETWORK_UPLINKS" ) + ": -/-"
		EndIf
	End Method


	Method DrawBodyContent(contentX:Int,contentY:Int,contentW:Int,currentY:Int)
		Local skin:TDatasheetSkin = GetSkin()
		If Not skin Then Return
		
		Local boxH:Int = skin.GetBoxSize(100, -1, "").GetY()
		Local boxAreaH:Int = 0
		Local showDetails:Int = False
		If selectedStation Then showDetails = True
		If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK_UPLINK Then showDetails = True
		If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK_UPLINK Then showDetails = True

		'update information
		detailsBackgroundH = actionButton.GetScreenHeight() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*2)
		listBackgroundH = GetBodyHeight() - detailsBackgroundH
		
		skin.RenderContent(contentX, currentY, contentW, listBackgroundH, "2")
		skin.RenderContent(contentX, currentY + listBackgroundH, contentW, detailsBackgroundH, "1_top")


		'=== LIST ===
		currentY :+ listBackgroundH
	

		'=== BOXES ===
		If TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			Local price:String = "", reach:String = "", reachChange:String = "", runningCost:String =""
			Local headerText:String
			Local subHeaderText:String
			Local canAfford:Int = True
			Local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation

			Select TScreenHandler_StationMap.actionMode
				Case TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK_UPLINK
					If selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						If selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						Else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						EndIf
					EndIf

				Case TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK_UPLINK
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					If selectedStation
						subHeaderText = GetLocale("MAP_COUNTRY_"+selectedStation.GetSectionName())

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						If selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						Else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						EndIf

						Local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (Not finance Or finance.canAfford(selectedStation.GetPrice()))
					EndIf
			End Select


			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, headerColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.drawBlock(subHeaderText, contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			Local halfW:Int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)


			If selectedStation
				Local subscriptionText:String
				Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID( TStationCableNetworkUplink(selectedStation).cableNetworkGUID)
				If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
					subscriptionText = cableNetwork.GetDefaultSubscribedChannelDuration()
				Else
					subscriptionText = selectedStation.GetSubscriptionTimeLeft()
				EndIf
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, subscriptionText, "duration", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				If GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				EndIf
			EndIf

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_ANTENNA
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			Else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				If canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
				EndIf
			EndIf
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH
		EndIf

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TGameGUISatellitePanel Extends TGameGUIBasicStationmapPanel
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

		Return Self
	End Method


	'override
	Method GetBuyActionMode:Int()
		Return TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
	End Method


	'override
	Method GetSellActionMode:Int()
		Return TScreenHandler_StationMap.MODE_SELL_SATELLITE_UPLINK
	End Method



	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:Int=-1)
		Super.RefreshList(playerID)

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		Local listContentWidth:Int = list.GetContentScreenWidth()
		For Local station:TStationSatelliteUplink = EachIn GetStationMap(playerID).Stations
			Local item:TGUISelectListItem = New TGUISelectListItem.Create(New TVec2D, New TVec2D.Init(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:String()
		If TScreenHandler_StationMap.currentSubRoom And GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner)
			Return GetLocale( "SATELLITE_UPLINKS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.SATELLITE_UPLINK)
		Else
			Return GetLocale( "SATELLITE_UPLINKS" ) + ": -/-"
		EndIf
	End Method


	Method DrawBodyContent(contentX:Int,contentY:Int,contentW:Int,currentY:Int)
		Local skin:TDatasheetSkin = GetSkin()
		If Not skin Then Return
		
		Local boxH:Int = skin.GetBoxSize(100, -1, "").GetY()
		Local boxAreaH:Int = 0
		Local showDetails:Int = False
		If selectedStation Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetSellActionMode() Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() Then showDetails = True

		'update information
		detailsBackgroundH = actionButton.GetScreenHeight() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*2)
		listBackgroundH = GetBodyHeight() - detailsBackgroundH
		
		skin.RenderContent(contentX, currentY, contentW, listBackgroundH, "2")
		skin.RenderContent(contentX, currentY + listBackgroundH, contentW, detailsBackgroundH, "1_top")


		'=== LIST ===
		currentY :+ listBackgroundH
	

		'=== BOXES ===
		If TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			Local price:String = "", reach:String = "", reachChange:String = "", runningCost:String =""
			Local headerText:String
			Local subHeaderText:String
			Local canAfford:Int = True
			Local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation

			Select TScreenHandler_StationMap.actionMode
				Case TScreenHandler_StationMap.MODE_SELL_SATELLITE_UPLINK
					If selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						If selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						Else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						EndIf
					EndIf

				Case TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					If selectedStation
						subHeaderText = selectedStation.GetName()

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReach(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						If selectedStation.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
							runningCost = "-/-"
						Else
							runningCost = TFunctions.convertValue(selectedStation.GetRunningCosts(), 2, 0)
						EndIf

						Local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (Not finance Or finance.canAfford(selectedStation.GetPrice()))
					EndIf
			End Select


			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, headerColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.drawBlock(subHeaderText, contentX + 5, currentY, contentW - 10,  16, ALIGN_CENTER_CENTER, subHeaderColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			Local halfW:Int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
'not needed
'			if TScreenHandler_StationMap.actionMode = GetBuyActionMode()
'				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
'			else
'				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, "-"+reachChange, "audienceIncrease", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
'			endif
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
'not needed
'			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				'TODO: individual build time for stations ("GetStationConstructionTime()")?
				If GameRules.stationConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, GameRules.stationConstructionTime + "h", "runningTime", "neutral", skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				EndIf
			EndIf

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = GetSellActionMode()
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
			Else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				If canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER,"bad")
				EndIf
			EndIf
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH
		EndIf

		'=== BUTTONS ===
		'actionButton.rect.position.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.position.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TSatelliteSelectionFrame
	Field area:TRectangle
	Field contentArea:TRectangle
	Field headerHeight:Int
	Field listHeight:Int
	Field selectedSatellite:TStationMap_Satellite
	Field satelliteList:TGUISelectList
	Field tooltips:TTooltipBase[]
	Field _open:Int = True

	Field _eventListeners:TLink[]


	Method New()
		satelliteList = New TGUISelectList.Create(New TVec2D.Init(610,133), New TVec2D.Init(178, 100), "STATIONMAP")
		'scroll by one entry at a time
		satelliteList.scrollItemHeightPercentage = 1.0
		satelliteList.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)

		'panel handles them (similar to a child - but with manual draw/update calls)
		'satelliteList.SetParent(self)
		GuiManager.Remove(satelliteList)


		tooltips = New TTooltipBase[4]
		For Local i:Int = 0 Until tooltips.length
			tooltips[i] = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = New TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = New TVec2D.Init(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next

		'fill with content
		RefreshSatellitesList()


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]

		'=== register event listeners
		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerMethod( "stationmapcollection.removeSatellite", Self, "OnChangeSatellites" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "stationmapcollection.addSatellite", Self, "OnChangeSatellites" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod( "GUISelectList.onSelectEntry", Self, "OnSelectEntryList", satelliteList ) ]

'		return self
	End Method

	
	Method SetLanguage()
		Local strings:String[] = [GetLocale("BROADCAST_QUALITY"), GetLocale("MARKET_SHARE"), GetLocale("REQUIRED_CHANNEL_IMAGE"), GetLocale("SUBSCRIBED_CHANNELS")]
		strings = strings[.. tooltips.length]

		For Local i:Int = 0 Until tooltips.length
			If tooltips[i] Then tooltips[i].SetContent(strings[i])
		Next
	End Method


	Method OnChangeSatellites:Int(triggerEvent:TEventBase)
		RefreshSatellitesList()
	End Method


	'an entry was selected - make the linked station the currently selected station
	Method OnSelectEntryList:Int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If Not senderList Then Return False
		If senderList <> satelliteList Then Return False
		If Not TScreenHandler_StationMap.currentSubRoom Then Return False
		If Not GetPlayerBaseCollection().IsPlayer(TScreenHandler_StationMap.currentSubRoom.owner) Then Return False

		'set the linked satellite as the selected one
		Local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		If item
			selectedSatellite = TStationMap_Satellite(item.data.get("satellite"))
		EndIf
	End Method


	Method SelectSatellite:Int(satellite:TStationMap_Satellite)
		selectedSatellite = satellite
		If Not selectedSatellite
			satelliteList.DeselectEntry()

			Return True
		Else
			For Local i:TGUIListItem = EachIn satelliteList.entries
				Local itemSatellite:TStationMap_Satellite = TStationMap_Satellite(i.data.get("satellite"))
				If itemSatellite = satellite
					satelliteList.SelectEntry(i)

					Return True
				EndIf
			Next
		EndIf

		Return False
	End Method


	Method IsOpen:Int()
		Return _open
	End Method


	Method Close:Int()
		SelectSatellite(Null)
		
		_open = False
		Return True
	End Method


	Method Open:Int()
		_open = True
		Return True
	End Method


	Method RefreshSatellitesList:Int()
		satelliteList.EmptyList()
		'remove potential highlighted item
		satelliteList.deselectEntry()

		'keep them sorted the way we added the stations
		satelliteList.setListOption(GUILIST_AUTOSORT_ITEMS, False)


		Local listContentWidth:Int = satelliteList.GetContentScreenWidth()

		If GetStationMapCollection().satellites
			For Local satellite:TStationMap_Satellite = EachIn GetStationMapCollection().satellites
				If Not satellite.IsLaunched() Then Continue
				
				Local item:TGUISelectListItem = New TGUISelectListItem.Create(New TVec2D, New TVec2D.Init(listContentWidth,20), satellite.name)
	
				'fill complete width
				item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
	
				'link the station to the item
				item.data.Add("satellite", satellite)
				'item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
				satelliteList.AddItem( item )
			Next
		EndIf

		Return True
	End Method

	
	Method Update:Int()
		If contentArea
			If satelliteList.rect.GetX() <> contentArea.GetX()
				satelliteList.SetPosition(contentArea.GetX(), contentArea.GetY() + 16)
			EndIf
			If satelliteList.GetWidth() <> contentArea.GetW()
				satelliteList.Resize(contentArea.GetW())
			EndIf
		EndIf

	
		satelliteList.update()

		For Local t:TTooltipBase = EachIn tooltips
			t.Update()
		Next
	End Method


	Method Draw:Int()
		Local skin:TDatasheetSkin = GetDatasheetSkin("stationMapPanel")
		If Not skin Then Return False

		Local owner:Int = GetPlayer().playerID
		If TScreenHandler_StationMap.currentSubRoom Then owner = TScreenHandler_StationMap.currentSubRoom.owner

		If Not area Then area = New TRectangle.Init(402, 103, 190, 212)
		If Not contentArea Then contentArea = New TRectangle

		Local detailsH:Int = 90 * (selectedSatellite<>Null)
		'local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		contentArea.SetW( skin.GetContentW( area.GetW() ) )
		contentArea.SetX( area.GetX() + skin.GetContentX() )
		contentarea.SetY( area.GetY() + skin.GetContentY() )
		contentArea.SetH( area.GetH() - (skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()) )

		headerHeight = 16
		listHeight = contentArea.GetH() - headerHeight - detailsH

		'resize list if needed
		If listHeight <> satelliteList.GetHeight()
			satelliteList.Resize(-1, listHeight)
		EndIf


		Local currentY:Int = contentArea.GetY()


		Local headerText:String = GetLocale("SATELLITES")
		Local titleColor:TColor = New TColor.Create(75,75,75)
		Local subTitleColor:TColor = New TColor.Create(115,115,115)



		'=== HEADER ===
		skin.RenderContent(contentArea.GetX(), contentArea.GetY(), contentArea.GetW(), headerHeight, "1_top")
		skin.fontNormal.drawBlock("|b|"+headerText+"|/b|", contentArea.GetX() + 5, currentY, contentArea.GetW() - 10,  headerHeight, ALIGN_CENTER_CENTER, skin.textColorNeutral, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
		currentY :+ headerHeight

		'=== LIST ===
		skin.RenderContent(contentArea.GetX(), currentY, contentArea.GetW(), listHeight, "2")
		satelliteList.Draw()
		currentY :+ listHeight


		'=== SATELLITE DETAILS ===
		If selectedSatellite
			Local titleText:String = selectedSatellite.name
			Local subtitleText:String = GetLocale("NOT_LAUNCHED_YET")
			If selectedSatellite.IsLaunched()
				subtitleText = GetLocale("LAUNCHED")+": " + GetWorldTime().GetFormattedDate(selectedSatellite.launchTime, GameConfig.dateFormat)
			EndIf

			skin.RenderContent(contentArea.GetX(), currentY, contentArea.GetW(), detailsH, "1_top")
			currentY :+ 2
			skin.fontNormal.drawBlock("|b|"+titleText+"|/b|", contentArea.GetX() + 5, currentY, contentArea.GetW() - 10,  16, ALIGN_CENTER_CENTER, titleColor, TBitmapFont.STYLE_SHADOW,1,0.2,True, True)
			currentY :+ 14
			skin.fontNormal.drawBlock(subTitleText, contentArea.GetX() + 5, currentY, contentArea.GetW() - 10,  16, ALIGN_CENTER_CENTER, subTitleColor, TBitmapFont.STYLE_EMBOSS,1,0.75,True, True)
			currentY :+ 15 + 3


			Local halfW:Int = (contentArea.GetW() - 10)/2 - 2
			Local boxH:Int = skin.GetBoxSize(100, -1, "").GetY()
			'=== BOX LINE 1 ===
			'local qualityText:string = "-/-"
			'if selectedSatellite.quality <> 100
			'	qualityText = MathHelper.NumberToString((selectedSatellite.quality-100), 0, True)+"%"
			'endif
			Local qualityText:String = MathHelper.NumberToString(selectedSatellite.quality, 0, True)+"%"
			Local marketShareText:String = MathHelper.NumberToString(100*selectedSatellite.populationShare, 1, True)+"%"

			If selectedSatellite.quality < 100
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, qualityText, "quality", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			Else
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, qualityText, "quality", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf
			skin.RenderBox(contentArea.GetX() + 5 + halfW-5 + 4, currentY, halfW+5, -1, marketShareText, "marketShare", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			tooltips[0].parentArea.SetXY(contentArea.GetX() + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentArea.GetX() + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)



			currentY :+ boxH
			Local minImageText:String = MathHelper.NumberToString(100*selectedSatellite.minimumChannelImage, 1, True)+"%"

			If Not GetPublicImage(owner) Or GetPublicImage(owner).GetAverageImage() < selectedSatellite.minimumChannelImage
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, minImageText, "image", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER, "bad")
			Else
				skin.RenderBox(contentArea.GetX() + 5, currentY, halfW-5, -1, minImageText, "image", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf


			'draw "used by channel xy" box
			Local channelX:Int = contentArea.GetX() + 5 + halfW-5 + 4
			skin.RenderBox(channelX, currentY, halfW+5, -1, "", "audience", "neutral", skin.fontNormal, ALIGN_RIGHT_CENTER)
			tooltips[2].parentArea.SetXY(contentArea.GetX() + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[3].parentArea.SetXY(contentArea.GetX() + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)



			channelX :+ 27
			Local oldColor:TColor = New TColor.Get()
			For Local i:Int = 1 To 4
				SetColor 50,50,50
				SetAlpha oldcolor.a * 0.4
				DrawRect(channelX, currentY + 6, 11,11)
				If selectedSatellite.IsSubscribedChannel(i)
					GetPlayerBase(i).color.SetRGB()
					SetAlpha oldColor.a
				Else
					SetColor 255,255,255
					SetAlpha oldColor.a *0.5
				EndIf
				DrawRect(channelX+1, currentY + 7, 9,9)
				'GetSpriteFromRegistry("gfx_gui_button.datasheet").DrawArea(channelX, currentY + 4, 14, 14)
				channelX :+ 13
			Next
			oldColor.SetRGBA()

		EndIf


		skin.RenderBorder(area.GetX(), area.GetY(), area.GetW(), area.GetH())

		'debug
		Rem
		DrawRect(contentArea.GetX(), contentArea.GetY(), 20, contentArea.GetH() )
		Setcolor 255,0,0
		DrawRect(contentArea.GetX() + 10, contentArea.GetY(), 20, headerHeight )
		Setcolor 255,255,0
		DrawRect(contentArea.GetX() + 20, contentArea.GetY() + headerHeight, 20, listHeight )
		Setcolor 255,0,255
		DrawRect(contentArea.GetX() + 30, contentArea.GetY() + headerHeight + listHeight, 20, detailsH )
		endrem

		For Local t:TTooltipBase = EachIn tooltips
			t.Render()
		Next
	End Method
End Type



Type TScreenHandler_StationMap
	Global guiAccordeon:TGUIAccordeon
	Global satelliteSelectionFrame:TSatelliteSelectionFrame

	Global actionMode:Int = 0
	Global actionConfirmed:Int = False

	Global mouseoverSection:TStationMapSection
	Global selectedStation:TStationBase
	Global mouseoverStation:TStationBase
	Global mouseoverStationPosition:TVec2D


	Global guiShowStations:TGUICheckBox[4]
	Global guiFilterButtons:TGUICheckBox[3]
	Global guiInfoButton:TGUIButton
	Global mapBackgroundSpriteName:String = ""


	Global currentSubRoom:TRoomBase = Null
	Global lastSubRoom:TRoomBase = Null

	Global LS_stationmap:TLowerString = TLowerString.Create("stationmap")

	Global _eventListeners:TLink[]

	Const PRODUCT_NONE:Int = 0
	Const PRODUCT_STATION:Int = 1
	Const PRODUCT_CABLE_NETWORK:Int = 2
	Const PRODUCT_SATELLITE:Int = 3

	Const MODE_NONE:Int                      =  0
	Const MODE_BUY:Int                       =  1
	Const MODE_SELL:Int                      =  2
	Const MODE_SELL_ANTENNA:Int              =  4 + MODE_SELL
	Const MODE_BUY_ANTENNA:Int               =  8 + MODE_BUY
	Const MODE_SELL_CABLE_NETWORK_UPLINK:Int = 16 + MODE_SELL
	Const MODE_BUY_CABLE_NETWORK_UPLINK:Int  = 32 + MODE_BUY
	Const MODE_SELL_SATELLITE_UPLINK:Int     = 64 + MODE_SELL
	Const MODE_BUY_SATELLITE_UPLINK:Int      =128 + MODE_BUY

	'=== THEME CONFIG === 
	Const titleH:Int = 18
	Const subTitleH:Int = 16
	Const sheetWidth:Int = 211
	Const buttonAreaPaddingY:Int = 4
	Const boxAreaPaddingY:Int = 4
	

	Function Initialize:Int()
		Local screen:TIngameScreen = TIngameScreen(ScreenCollection.GetScreen("screen_office_stationmap"))
		If Not screen Then Return False

		'remove background from stationmap screen
		'(we draw the map and then the screen bg)
		If screen.backgroundSpriteName <> ""
			mapBackgroundSpriteName = screen.backgroundSpriteName
			screen.backgroundSpriteName = ""
		EndIf
		
		'=== create gui elements if not done yet
		If Not guiInfoButton
			guiAccordeon = New TGameGUIAccordeon.Create(New TVec2D.Init(586, 70), New TVec2D.Init(211, 305), "", "STATIONMAP")
			TGameGUIAccordeon(guiAccordeon).skinName = "stationmapPanel"

			Local p:TGUIAccordeonPanel
			p = New TGameGUIAntennaPanel.Create(New TVec2D.Init(-1, -1), New TVec2D.Init(-1, -1), "Stations", "STATIONMAP")
			p.Open()
			guiAccordeon.AddPanel(p, 0)
			p = New TGameGUICableNetworkPanel.Create(New TVec2D.Init(-1, -1), New TVec2D.Init(-1, -1), "Cable Networks", "STATIONMAP")
			guiAccordeon.AddPanel(p, 1)
			p = New TGameGUISatellitePanel.Create(New TVec2D.Init(-1, -1), New TVec2D.Init(-1, -1), "Satellites", "STATIONMAP")
			guiAccordeon.AddPanel(p, 2)


			'== info panel
			guiInfoButton = New TGUIButton.Create(New TVec2D.Init(610, 215), New TVec2D.Init(20, 28), "", "STATIONMAP")
			guiInfoButton.spriteName = "gfx_gui_button.datasheet"
			guiInfoButton.SetTooltip( New TGUITooltipBase.Initialize(GetLocale("SHOW_MAP_DETAILS"), GetLocale("CLICK_TO_SHOW_ADVANCED_MAP_INFORMATION"), New TRectangle.Init(0,0,-1,-1)) )
			guiInfoButton.GetTooltip()._minContentDim = New TVec2D.Init(120,-1)
			guiInfoButton.GetTooltip()._maxContentDim = New TVec2D.Init(150,-1)
			guiInfoButton.GetTooltip().SetOrientationPreset("BOTTOM", 10)

			For Local i:Int = 0 Until guiFilterButtons.length
				guiFilterButtons[i] = New TGUICheckBox.Create(New TVec2D.Init(695 + i*23, 30 ), New TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
				guiFilterButtons[i].ShowCaption(False)
				guiFilterButtons[i].data.AddNumber("stationType", i+1)
				'guiFilterButtons[i].SetUnCheckedTintColor( TColor.Create(255,255,255) )
				guiFilterButtons[i].SetUnCheckedTintColor( TColor.Create(210,210,210, 0.75) )
				guiFilterButtons[i].SetCheckedTintColor( TColor.Create(245,255,240) )

				guiFilterButtons[i].uncheckedSpriteName = "gfx_datasheet_icon_" + TVTStationType.GetAsString(i+1) + ".off"
				guiFilterButtons[i].checkedSpriteName = "gfx_datasheet_icon_" + TVTStationType.GetAsString(i+1) + ".on"

				guiFilterbuttons[i].SetTooltip( New TGUITooltipBase.Initialize("", GetLocale("TOGGLE_DISPLAY_OF_STATIONTYPE").Replace("%STATIONTYPE%", GetLocale(TVTStationType.GetAsString(i+1)+"S")), New TRectangle.Init(0,60,-1,-1)) )
				guiFilterbuttons[i].GetTooltip()._minContentDim = New TVec2D.Init(80,-1)
				guiFilterbuttons[i].GetTooltip()._maxContentDim = New TVec2D.Init(120,-1)
				guiFilterbuttons[i].GetTooltip().SetOrientationPreset("BOTTOM", 10)
			Next


			For Local i:Int = 0 To 3
				guiShowStations[i] = New TGUICheckBox.Create(New TVec2D.Init(695 + i*23, 30 ), New TVec2D.Init(20, 20), String(i + 1), "STATIONMAP")
				guiShowStations[i].ShowCaption(False)
				guiShowStations[i].data.AddNumber("playerNumber", i+1)

				guiShowStations[i].SetTooltip( New TGUITooltipBase.Initialize("", GetLocale("TOGGLE_DISPLAY_OF_PLAYER_X").Replace("%X%", i+1), New TRectangle.Init(0,60,-1,-1)) )
				guiShowStations[i].GetTooltip()._minContentDim = New TVec2D.Init(80,-1)
				guiShowStations[i].GetTooltip()._maxContentDim = New TVec2D.Init(120,-1)
				guiShowStations[i].GetTooltip().SetOrientationPreset("BOTTOM", 10)
			Next
		EndIf


		satelliteSelectionFrame = New TSatelliteSelectionFrame


		'=== reset gui element options to their defaults
		For Local i:Int = 0 Until guiShowStations.length
			guiShowStations[i].SetChecked( True, False)
		Next
		For Local i:Int = 0 Until guiFilterButtons.length
			guiFilterButtons[i].SetChecked( True, False)
		Next


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]


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
		For Local i:Int = 0 Until guiShowStations.length
			_eventListeners :+ [ EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, guiShowStations[i]) ]
		Next
		For Local i:Int = 0 Until guiFilterButtons.length
			_eventListeners :+ [ EventManager.registerListenerFunction("guiCheckBox.onSetChecked", OnSetChecked_StationMapFilters, guiFilterButtons[i]) ]
		Next

		'to update/draw the screen
		_eventListeners :+ TRoomHandler._RegisterScreenHandler( onUpdateStationMap, onDrawStationMap, screen )

		'(re-)localize content
		SetLanguage()
	End Function


	Function SetLanguage()
		If Not guiInfoButton Then Return
		
		guiInfoButton.SetCaption("?")

		guiInfoButton.GetTooltip().SetTitle( GetLocale("SHOW_MAP_DETAILS") )
		guiInfoButton.GetTooltip().SetContent( GetLocale("CLICK_TO_SHOW_ADVANCED_MAP_INFORMATION") )

		For Local i:Int = 0 Until guiFilterButtons.length
			guiFilterbuttons[i].GetTooltip().SetContent( GetLocale("TOGGLE_DISPLAY_OF_STATIONTYPE").Replace("%STATIONTYPE%", "|b|"+GetLocale(TVTStationType.GetAsString(i+1)+"S")+"|/b|") )
		Next
		
		For Local i:Int = 0 To 3
			guiShowStations[i].GetTooltip().SetContent( GetLocale("TOGGLE_DISPLAY_OF_PLAYER_X").Replace("%X%", i+1) )
		Next

		For Local p:TGameGUIBasicStationmapPanel = EachIn guiAccordeon.panels
			p.SetLanguage()
		Next

		If satelliteSelectionFrame Then satelliteSelectionFrame.SetLanguage()
	End Function


	Function SetActionMode(mode:Int)
		actionMode = mode
	End Function


	Function HasActionMode:Int(mode:Int, flag:Int)
		Return (mode & flag) > 0
	End Function


	Function IsInBuyActionMode:Int()
		Return HasActionMode(actionMode, MODE_BUY)
	End Function


	Function IsInSellActionMode:Int()
		Return HasActionMode(actionMode, MODE_SELL)
	End Function


	Function _DrawStationMapInfoPanel:Int(x:Int,y:Int, room:TRoomBase)
		'=== PREPARE VARIABLES ===
		Local sheetHeight:Int = 0 'calculated later

		Local skin:TDatasheetSkin = GetDatasheetSkin("stationmapPanel")

		Local contentW:Int = skin.GetContentW(sheetWidth)
		Local contentX:Int = x + skin.GetContentX()
		Local contentY:Int = y + skin.GetContentY()

		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		Local buttonH:Int = 0
		Local buttonAreaH:Int = 0, bottomAreaH:Int = 0

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
		Local buttonX:Int = contentX + 5
		guiInfoButton.rect.dimension.SetX(25)
		guiInfoButton.rect.position.SetXY(contentX + 5, contentY)
		buttonX :+ guiInfoButton.rect.GetW() + 6

		For Local i:Int = 0 Until guiFilterButtons.length
			guiFilterButtons[i].rect.position.SetXY(buttonX, contentY + ((guiInfoButton.rect.GetH() - guiFilterButtons[i].rect.GetH())/2) )
			buttonX :+ guiFilterButtons[i].rect.GetW()
		Next
		
		For Local i:Int = 0 Until guiShowStations.length
			guiShowStations[i].rect.position.SetXY(contentX + 8 + 50+15+30 + 21*i, contentY + ((guiInfoButton.rect.GetH() - guiShowStations[i].rect.GetH())/2) )
		Next
		contentY :+ buttonAreaPaddingY


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function

	
 	Function onDrawStationMap:Int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		Local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		'draw map
		GetSpriteFromRegistry("map_Surface").Draw(0,0)

		'disable sections when there is no active cable network there
		If actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
			Local foundDisabledSections:Int = 0
			For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
				If section.activeCableNetworkCount = 0
					DrawImage(section.GetDisabledOverlay(), section.rect.GetX(), section.rect.GetY())
					foundDisabledSections :+ 1
				EndIf
			Next
			'draw normal ones on top - but only if needed
			'this is done to avoid "available sections" to get hidden
			If foundDisabledSections > 0
				For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
					If section.activeCableNetworkCount > 0
						DrawImage(section.GetEnabledOverlay(), section.rect.GetX(), section.rect.GetY())
					EndIf
				Next
			EndIf
		EndIf

		'gray out sections when there is no broadcast permission
		If actionMode = MODE_BUY_ANTENNA
			Local oldCol:TColor = New TColor.Get()
			Local foundNoPermissionSections:Int = 0
			For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
				If Not section.HasBroadcastPermission(room.owner)
					SetColor 255,180,180
					SetAlpha 0.50 * oldCol.a
					DrawImage(section.GetDisabledOverlay(), section.rect.GetX(), section.rect.GetY())
					foundNoPermissionSections :+ 1
				EndIf
			Next
			oldCol.setRGBA()
			'draw normal ones on top - but only if needed
			'this is done to avoid "available sections" to get hidden
			If foundNoPermissionSections > 0
				For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
					If section.activeCableNetworkCount > 0
						DrawImage(section.GetEnabledOverlay(), section.rect.GetX(), section.rect.GetY())
					EndIf
				Next
			EndIf
		EndIf
		
		'when selecting a station position with the mouse or a
		'cable network or a satellite
		If actionMode = MODE_BUY_ANTENNA Or actionMode = MODE_BUY_SATELLITE_UPLINK Or actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
			SetAlpha Float(0.8 + 0.2 * Sin(MilliSecs()/6))
			DrawImage(GetStationMapCollection().populationImageOverlay, 0,0)
			SetAlpha 1.0
		EndIf



		'overlay with alpha channel screen
		GetSpriteFromRegistry(mapBackgroundSpriteName).Draw(0,0)


		_DrawStationMapInfoPanel(586, 5, room)

		'debug draw station map sections
		'TStationMapSection.DrawAll()

		'backgrounds
		If mouseoverStation And mouseoverStation = selectedStation
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
		If mouseoverStation Then mouseoverStation.Draw()
		'also draw the station used for buying/searching
		If selectedStation Then selectedStation.Draw(True)


		GUIManager.Draw( LS_stationmap )

		For Local i:Int = 0 To 3
			guiShowStations[i].SetUncheckedTintColor( GetPlayerBase(i+1).color.Copy().AdjustBrightness(+0.25).AdjustSaturation(-0.35), False)
			guiShowStations[i].SetCheckedTintColor( GetPlayerBase(i+1).color ) '.Copy().AdjustBrightness(0.25)
			'guiShowStations[i].tintColor = GetPlayerBase(i+1).color '.Copy().AdjustBrightness(0.25)
		Next

		GetGameBase().cursorstate = 0
		'draw a kind of tooltip over a mouseoverStation
		If mouseoverStation
			GetGameBase().cursorstate = 1
			mouseoverStation.DrawInfoTooltip()
		else
			'if over a section, draw special tooltip displaying reasons
			'why we cannot build there
			If mouseoverSection and currentSubRoom
				if actionMode = MODE_BUY_ANTENNA
					GetGameBase().cursorstate = 3
					mouseoverSection.DrawChannelStatusTooltip(currentSubRoom.owner, TVTStationType.ANTENNA )
				elseif actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
					GetGameBase().cursorstate = 3
					mouseoverSection.DrawChannelStatusTooltip(currentSubRoom.owner, TVTStationType.CABLE_NETWORK_UPLINK )
				endif
			EndIf
		EndIf
		

		'draw activation tooltip for all other stations
		'- only draw them while NOT placing a new one (to ease spot finding)
		If actionMode <> MODE_BUY_ANTENNA And actionMode <> MODE_BUY_SATELLITE_UPLINK And actionMode <> MODE_BUY_CABLE_NETWORK_UPLINK
			For Local station:TStationBase = EachIn GetStationMap(room.owner).Stations
				If mouseoverStation = station Then Continue
				If station.IsActive() Then Continue

				station.DrawActivationTooltip()
			Next
		EndIf


		'draw satellite selection frame
'		if actionMode = MODE_BUY_SATELLITE_UPLINK
			If satelliteSelectionFrame.IsOpen()
				satelliteSelectionFrame.Draw()
			EndIf
'		endif
	End Function


	Function onUpdateStationMap:Int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		Local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		'backup room if it changed
		If currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom

			'if we changed the room meanwhile - we have to rebuild the stationList
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList()
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(1)).RefreshList()
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(2)).RefreshList()
		EndIf

		currentSubRoom = room

		GetStationMap(room.owner).Update()

		'process right click
		If MOUSEMANAGER.isClicked(2) Or MouseManager.IsLongClicked(1)
			Local reset:Int = (selectedStation Or mouseoverStation Or satelliteSelectionFrame.IsOpen())

'			if satelliteSelectionFrame.IsOpen()
'				satelliteSelectionFrame.Close()
'			else
				ResetActionMode(0)
'			endif

			If reset
				MOUSEMANAGER.ResetKey(2)
				MOUSEMANAGER.ResetKey(1) 'also normal clicks
			EndIf
		EndIf


		If satelliteSelectionFrame.IsOpen()
			If Not selectedStation And TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
				satelliteSelectionFrame.Close()
			EndIf
		EndIf


		'If actionMode = MODE_BUY_ANTENNA or actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
		'	mouseoverSection = GetStationMapCollection().GetSection( MouseManager.GetPosition().GetIntX(), MouseManager.GetPosition().GetIntY() )
		'EndIf
rem
		If not mouseoverStation and mouseoverSection and currentSubRoom
			if actionMode = MODE_BUY_ANTENNA or actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
				GetGameBase().cursorstate = 3
				print "invalid"
			endif
		endif
endrem		

		'buying stations using the mouse
		'1. searching
		If actionMode = MODE_BUY_ANTENNA
			'create a temporary station if not done yet
			If Not mouseoverStation Then mouseoverStation = GetStationMap(room.owner).GetTemporaryAntennaStation( MouseManager.GetPosition().GetIntX(), MouseManager.GetPosition().GetIntY() )
			Local mousePos:TVec2D = New TVec2D.Init( MouseManager.x, MouseManager.y)

			'if the mouse has moved - refresh the station data and move station
			If Not mouseoverStation.pos.isSame( mousePos )
				mouseoverStation.pos.CopyFrom(mousePos)
				mouseoverStation.refreshData()
				'refresh state information
				mouseoverStation.GetSectionName(True)
			EndIf

			Local hoveredMapSection:TStationMapSection
			If mouseoverStation Then hoveredMapSection = GetStationMapCollection().GetSection(Int(mouseoverStation.pos.x), Int(mouseoverStation.pos.y))

			'if mouse gets clicked, we store that position in a separate station
			If MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				If hoveredMapSection And mouseoverStation.GetReach() > 0
					selectedStation = GetStationMap(room.owner).GetTemporaryAntennaStation( mouseoverStation.pos.GetIntX(), mouseoverStation.pos.GetIntY() )
				EndIf
			EndIf

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			If Not hoveredMapSection Or mouseoverStation.GetReach() <= 0
				mouseoverStation = Null
				mouseoverStationPosition = Null
			EndIf

			If selectedStation
				Local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSection(Int(selectedStation.pos.x), Int(selectedStation.pos.y))

				If Not selectedMapSection Or selectedStation.GetReach() <= 0 Then selectedStation = Null
			EndIf


		ElseIf actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
			'if the mouse has moved or nothing was created yet
			'refresh the station data and move station
			If Not mouseoverStation Or Not mouseoverStationPosition Or Not mouseoverStationPosition.isSame( MouseManager.GetPosition() )
				mouseoverSection = GetStationMapCollection().GetSection( MouseManager.GetPosition().GetIntX(), MouseManager.GetPosition().GetIntY() )
				If mouseoverSection
					Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetFirstCableNetworkBySectionName(mouseoverSection.name)
					If cableNetwork And cableNetwork.IsLaunched()
						mouseoverStationPosition = MouseManager.GetPosition().Copy()
						mouseoverStation = GetStationMap(room.owner).GetTemporaryCableNetworkUplinkStationByCableNetwork( cableNetwork )
						mouseoverStation.refreshData()
						'refresh state information
						'DO NOT TRUST: Brandenburg's center is berlin - leading
						'              to sectionname = berlin
						mouseOverStation.sectionName = mouseoverSection.name
						'mouseoverStation.GetSectionName(true)
					'remove cache
					Else
						mouseoverStation = Null
						mouseoverStationPosition = Null
					EndIf
				'remove cache
				ElseIf mouseoverStation
					mouseoverStation = Null
					mouseoverStationPosition = Null
				EndIf
			EndIf

			Local hoveredMapSection:TStationMapSection
			If mouseoverStation And mouseoverStationPosition
				hoveredMapSection = GetStationMapCollection().GetSection(Int(mouseoverStationPosition.x), Int(mouseoverStationPosition.y))
			EndIf

			'if mouse gets clicked, we store that position in a separate station
			If MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				If hoveredMapSection And mouseoverStation.GetReach() > 0
					Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetworkByGUID(TStationCableNetworkUplink(mouseOverStation).cableNetworkGUID)
					If cableNetwork And cableNetwork.IsLaunched()
						selectedStation = GetStationMap(room.owner).GetTemporaryCableNetworkUplinkStationByCableNetwork( cableNetwork )
						If selectedStation
							selectedStation.refreshData()
							'refresh state information
							selectedStation.sectionName = hoveredMapSection.name
							'selectedStation.GetSectionName(true)
						EndIf
					EndIf
				EndIf
			EndIf

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			If Not hoveredMapSection Or mouseoverStation.GetReach() <= 0
				mouseoverStation = Null
				mouseoverStationPosition = Null
			EndIf

			If selectedStation
				Local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSection(Int(selectedStation.pos.x), Int(selectedStation.pos.y))

				If Not selectedMapSection Or selectedStation.GetReach() <= 0 Then selectedStation = Null
			EndIf
			
		ElseIf actionMode = MODE_BUY_SATELLITE_UPLINK
			If satelliteSelectionFrame.selectedSatellite
				Local satLink:TStationSatelliteUplink = TStationSatelliteUplink(selectedStation)
				'only create a temporary sat link station if a satellite was
				'selected
				If satelliteSelectionFrame.selectedSatellite
					If Not satLink Or satLink.satelliteGUID <> satelliteSelectionFrame.selectedSatellite.GetGUID()
						selectedStation = GetStationMap(room.owner).GetTemporarySatelliteUplinkStationBySatelliteGUID( satelliteSelectionFrame.selectedSatellite.GetGUID() )
						selectedStation.refreshData()
					EndIf
				EndIf
			EndIf

Rem
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
		EndIf



		'select satellite of the currently selected satlink
		If TStationSatelliteUplink(selectedStation)
			Local satLink:TStationSatelliteUplink = TStationSatelliteUplink(selectedStation)
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID( satLink.satelliteGUID )
			If satellite <> satelliteSelectionFrame.selectedSatellite
				If Not satelliteSelectionFrame.IsOpen()
					satelliteSelectionFrame.Open()
				Else
					satelliteSelectionFrame.SelectSatellite( GetStationMapCollection().GetSatelliteByGUID( satLink.satelliteGUID ) )
				EndIf
			EndIf
		EndIf


		If satelliteSelectionFrame.IsOpen()
			satelliteSelectionFrame.Update()

			'check if closing needed or other another satellite needs
			'to get selected
'			if actionMode <> TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
'				else
'					satelliteSelectionFrame.Close()
'				endif
'			endif
		EndIf

		
		GUIManager.Update( LS_stationmap )
	End Function


	Function OnOpenOrCloseAccordeonPanel:Int( triggerEvent:TEventBase )
		Local accordeon:TGameGUIAccordeon = TGameGUIAccordeon(triggerEvent.GetSender())
		If Not accordeon Or accordeon <> guiAccordeon Then Return False 

		Local panel:TGameGUIAccordeonPanel = TGameGUIAccordeonPanel(triggerEvent.GetData().Get("panel"))


		If triggerEvent.IsTrigger("guiaccordeon.onClosePanel".ToLower())
			'selectedStation = null
			'print "selected = null"
			ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
		EndIf
	End Function


	Function OnChangeStationMapStation:Int( triggerEvent:TEventBase )
		'do nothing when not in a room
		If Not currentSubRoom Then Return False

		TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList( currentSubRoom.owner )
		TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(1)).RefreshList( currentSubRoom.owner )
		TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(2)).RefreshList( currentSubRoom.owner )
	End Function


	Function ResetActionMode(mode:Int=0)
		SetActionMode(mode)
		actionConfirmed = False
		'remove selection
		selectedStation = Null
		mouseoverStation = Null
		mouseoverStationPosition = Null
	End Function


	'===================================
	'Stationmap: Connect GUI elements
	'===================================

	Function OnUpdate_ActionButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not currentSubRoom Or currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		Select actionMode
			Case MODE_BUY_ANTENNA
				If Not selectedStation
					button.SetValue(GetLocale("SELECT_LOCATION")+" ...")
					button.disable()
				Else
					Local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
					If finance And finance.canAfford(selectedStation.GetPrice())
						button.SetValue(GetLocale("BUY_STATION"))
						button.enable()
					Else
						button.SetValue(GetLocale("TOO_EXPENSIVE"))
						button.disable()
					EndIf
				EndIf

			Case MODE_SELL_ANTENNA
				'different owner or not paid or not sellable
				If selectedStation
					If selectedStation.owner <> GetPlayerBase().playerID
						button.disable()
						button.SetValue(GetLocale("WRONG_PLAYER"))
					ElseIf Not selectedStation.HasFlag(TVTStationFlag.SELLABLE)
						button.SetValue(GetLocale("UNSELLABLE"))
						button.disable()
					ElseIf Not selectedStation.HasFlag(TVTStationFlag.PAID)
						button.SetValue(GetLocale("SELL_STATION"))
						button.disable()
					Else
						button.SetValue(GetLocale("SELL_STATION"))
						button.enable()
					EndIf
				EndIf

			Case MODE_BUY_CABLE_NETWORK_UPLINK
				If Not selectedStation
					button.SetValue(GetLocale("SELECT_LOCATION")+" ...")
					button.disable()
				Else
					Local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
					If finance And finance.canAfford(selectedStation.GetPrice())
						button.SetValue(GetLocale("BUY_CABLE_NETWORK"))
						button.enable()
					Else
						button.SetValue(GetLocale("TOO_EXPENSIVE"))
						button.disable()
					EndIf
				EndIf

			Case MODE_SELL_CABLE_NETWORK_UPLINK
				'different owner or not paid or not sellable
				If selectedStation
					If selectedStation.owner <> GetPlayerBase().playerID
						button.disable()
						button.SetValue(GetLocale("WRONG_PLAYER"))
					ElseIf Not selectedStation.HasFlag(TVTStationFlag.SELLABLE)
						button.SetValue(GetLocale("UNSELLABLE"))
						button.disable()
					ElseIf Not selectedStation.HasFlag(TVTStationFlag.PAID)
						button.SetValue(GetLocale("SELL_CABLE_NETWORK_UPLINK"))
						button.disable()
					Else
						button.SetValue(GetLocale("SELL_CABLE_NETWORK_UPLINK"))
						button.enable()
					EndIf
				EndIf


			Default
				button.SetValue(GetLocale("NEW_STATION"))
				button.enable()
		End Select
	End Function


	'custom drawing function for list entries
	Function DrawMapStationListEntryContent:Int(obj:TGUIObject)
		Local item:TGUISelectListItem = TGUISelectListItem(obj)
		If Not item Then Return False

		Local station:TStationBase = TStationBase(item.data.Get("station"))
		If Not station Then Return False

		Local sprite:TSprite
		If station.IsActive()
			sprite = GetSpriteFromRegistry(station.listSpriteNameOn)
		Else
			sprite = GetSpriteFromRegistry(station.listSpriteNameOff)
		EndIf

		Local rightValue:String = TFunctions.convertValue(station.GetReach(), 2, 0)
		Local paddingLR:Int = 2
		Local textOffsetX:Int = paddingLR + sprite.GetWidth() + 5
		Local textOffsetY:Int = 2
		Local textW:Int = item.GetScreenWidth() - textOffsetX - paddingLR

		Local currentColor:TColor = New TColor.Get()
		Local entryColor:TColor

		'draw with different color according status
		If station.IsActive()
			'colorize antenna for "not sellable ones
			If Not station.HasFlag(TVTStationFlag.SELLABLE)
				entryColor = New TColor.Create(120,90,60, currentColor.a)
			Else
				entryColor = item.valueColor.copy()
				entryColor.a = currentColor.a
			EndIf
		Else
			entryColor = item.valueColor.copy().AdjustFactor(50)
			entryColor.a = currentColor.a * 0.5
		EndIf


		'draw antenna
		sprite.Draw(Int(item.GetScreenX() + paddingLR), item.GetScreenY() + 0.5*item.rect.getH(), -1, ALIGN_LEFT_CENTER)
		entryColor.SetRGBA()
		Local rightValueWidth:Int = item.GetFont().GetWidth(rightValue)
'		item.GetFont().DrawBlock(int(TGUIScrollablePanel(item._parent).scrollPosition.y)+"/"+int(TGUIScrollablePanel(item._parent).scrollLimit.y)+" "+item.GetValue(), Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, int(item.GetScreenHeight() - textOffsetY), ALIGN_LEFT_CENTER, item.valueColor)
		item.GetFont().DrawBlock(item.GetValue(), Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW - rightValueWidth - 5, Int(item.GetScreenHeight() - textOffsetY), ALIGN_LEFT_CENTER, item.valueColor, , , , False)
		item.GetFont().DrawBlock(rightValue, Int(item.GetScreenX() + textOffsetX), Int(item.GetScreenY() + textOffsetY), textW, Int(item.GetScreenHeight() - textOffsetY), ALIGN_RIGHT_CENTER, item.valueColor)

		currentColor.SetRGBA()
	End Function
	

	'set checkboxes according to stationmap config
	Function onEnterStationMapScreen:Int(triggerEvent:TEventBase)
		'only players can "enter screens" - so just use "inRoom"
		Local owner:Int = 0
		If GetPlayer().GetFigure().inRoom Then owner = GetPlayer().GetFigure().inRoom.owner
		If owner = 0 Then owner = GetPlayerBase().playerID
		
		For Local i:Int = 0 To 3
			Local show:Int = GetStationMap(owner).GetShowStation(i+1)
			guiShowStations[i].SetChecked(show)
		Next
	End Function


	Function OnSetChecked_StationMapFilters:Int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not currentSubRoom Or currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		'player filter
		Local player:Int = button.data.GetInt("playerNumber", -1)
		If player >= 0
			If Not GetPlayerCollection().IsPlayer(player) Then Return False

			'only set if not done already
			If GetStationMap(GetPlayerBase().playerID).GetShowStation(player) <> button.isChecked()
				TLogger.Log("StationMap", "Stationmap #"+GetPlayerBase().playerID+" show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
				GetStationMap(GetPlayerBase().playerID).SetShowStation(player, button.isChecked())
			EndIf
		EndIf

		'station type filter
		Local stationType:Int = button.data.GetInt("stationType", -1)
		If stationType >= 0
			'only set if not done already
			If GetStationMap(GetPlayerBase().playerID).GetShowStationType(stationType) <> button.isChecked()
				TLogger.Log("StationMap", "Stationmap #"+GetPlayerBase().playerID+" show station type "+stationType+": "+button.isChecked(), LOG_DEBUG)
				GetStationMap(GetPlayerBase().playerID).SetShowStationType(stationType, button.isChecked())
			EndIf
		EndIf
	End Function
End Type