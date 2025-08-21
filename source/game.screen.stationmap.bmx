SuperStrict
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"
Import "common.misc.gamegui.bmx"
Import "game.screen.base.bmx"
Import "game.stationmap.bmx"
Import "game.player.bmx"
Import "game.player.difficulty.bmx"
Import "game.room.base.bmx"
Import "game.roomhandler.base.bmx"
Import "game.gameeventkeys.bmx"




Type TGameGUIBasicStationmapPanel Extends TGameGUIAccordeonPanel
'	Field selectedStation:TStationBase
	Field list:TGUISelectList
	Field renewButton:TGUIButton
	Field renewInfoButton:TGUIButton
	Field autoRenewCheckbox:TGUICheckbox
	Field renewContractTooltips:TTooltipBase[]

	Field actionButton:TGUIButton
	Field cancelButton:TGUIButton
	Field tooltips:TTooltipBase[]

	Field listExtended:Int = False
	Field detailsBackgroundH:Int
	Field listBackgroundH:Int
	Field localeKey_NewItem:String = "NEW_ITEM"
	Field localeKey_BuyItem:String = "BUY_ITEM"
	Field localeKey_SellItem:String = "SELL_ITEM"
	Field buttonFont:TBitmapFont
	Field listFont:TBitmapFont

	Field _eventListeners:TEventListenerBase[]
	Global headerColor:SColor8 = new SColor8(75,75,75)
	Global subHeaderColor:SColor8 = new SColor8(115,115,115)


	Method Create:TGameGUIBasicStationmapPanel(pos:SVec2I, dimension:SVec2I, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		buttonFont = GetBitmapFontManager().Get("Default", 11, BOLDFONT)
		listFont = GetBitmapFontManager().Get("Default", 11)

		actionButton = New TGUIButton.Create(New SVec2I(0, 0), New SVec2I(150, 28), "", "STATIONMAP")
		actionButton.SetSpriteName("gfx_gui_button.datasheet")
		actionButton.SetFont( buttonFont )


		renewButton = New TGUIButton.Create(New SVec2I(0, 0), New SVec2I(150, 28), "", "STATIONMAP")
		renewButton.SetSpriteName("gfx_gui_button.datasheet")
		renewButton.SetFont( buttonFont )

		renewInfoButton = New TGUIButton.Create(New SVec2I(145, 0), New SVec2I(30, 28), "i", "STATIONMAP")
		renewInfoButton.caption.color = TColor.clBlue.ToSColor8()
		renewInfoButton.SetSpriteName("gfx_gui_button.datasheet")
		renewInfoButton.SetFont( buttonFont )

		autoRenewCheckbox = New TGUICheckBox.Create(New SVec2I(145, 0), New SVec2I(20, 20), "auto renew", "STATIONMAP")
		'autoRenewCheckbox.caption.color = TColor.clBlue.copy()
		'autoRenewCheckbox.spriteName = "gfx_gui_button.datasheet"
		autoRenewCheckbox.SetFont( buttonFont )

		cancelButton = New TGUIButton.Create(New SVec2I(145, 0), New SVec2I(30, 28), "X", "STATIONMAP")
		cancelButton.caption.color = TColor.clRed.ToSColor8()
		cancelButton.SetSpriteName("gfx_gui_button.datasheet")
		cancelButton.SetFont( buttonFont )

		list = New TGUISelectList.Create(New SVec2I(610,133), New SVec2I(178, 100), "STATIONMAP")
		'scroll by one entry at a time
		list.scrollItemHeightPercentage = 1.0
		list.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)
		list.SetFont( listFont )


		cancelButton.SetParent(Self)
		actionButton.SetParent(Self)
		autoRenewCheckbox.SetParent(Self)
		renewInfoButton.SetParent(Self)
		renewButton.SetParent(Self)
		list.SetParent(Self)

		'panel handles them (similar to a child - but with manual draw/update calls)
		GuiManager.Remove(cancelButton)
		GuiManager.Remove(actionButton)
		GuiManager.Remove(autoRenewCheckbox)
		GuiManager.Remove(renewInfoButton)
		GuiManager.Remove(renewButton)
		GuiManager.Remove(list)


		tooltips = New TTooltipBase[5]
		For Local i:Int = 0 Until tooltips.length
			tooltips[i] = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = New TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = New TVec2D(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next


		renewContractTooltips = New TTooltipBase[2]
		For Local i:Int = 0 Until renewContractTooltips.length
			renewContractTooltips[i] = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
			renewContractTooltips[i].parentArea = New TRectangle
			renewContractTooltips[i].SetOrientationPreset("TOP")
			renewContractTooltips[i].offset = New TVec2D(0,+5)
			renewContractTooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			renewContractTooltips[i].dwellTime = 50
			renewContractTooltips[i].SetContent("i="+i)


			'manually set to hovered when needed
			renewContractTooltips[i].SetOption(TTooltipBase.OPTION_MANUAL_HOVER_CHECK)
		Next


		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "OnClickCancelButton", cancelButton) ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "OnClickActionButton", actionButton) ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "OnClickRenewButton", renewButton) ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUICheckbox_OnSetChecked, Self, "OnSetChecked_AutoRenewCheckbox", autoRenewCheckbox) ]
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, OnChangeStationMapStation) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, OnChangeStationMapStation) ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUISelectList_onSelectEntry, Self, "OnSelectEntryList", list) ]

		'(re-)localize content
		SetLanguage()

		Return Self
	End Method


	Method SetLanguage()
		Local strings:String[] = [GetLocale("REACH"), GetLocale("INCREASE"), GetLocale("CONSTRUCTION_TIME"), GetLocale("RUNNING_COSTS"), GetLocale("PRICE")]
		strings = strings[.. tooltips.length]

		For Local i:Int = 0 Until tooltips.length
			If tooltips[i] Then tooltips[i].SetContent(strings[i])
		Next

		if autoRenewCheckbox
			autoRenewCheckbox.SetCaptionValues(GetLocale("RENEW_AUTOMATICALLY"), GetLocale("RENEW_AUTOMATICALLY"))
		endif
	End Method


	Method OnClickActionButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		if TScreenHandler_StationMap.mapInformationFrame
			'ignore clicks as long as map info screen is shown ?
			'if TScreenHandler_StationMap.mapInformationFrame.IsOpen() Then Return False

			'or close window
			if TScreenHandler_StationMap.mapInformationFrame.IsOpen() Then TScreenHandler_StationMap.mapInformationFrame.Close()
		endif


		If TScreenHandler_StationMap.IsInBuyActionMode()
			Local stationToBuy:TStationBase  = TScreenHandler_StationMap.selectedStation
			If stationToBuy And stationToBuy.GetReceivers() > 0
				'add the station (and buy it)
				If GetStationMap( GetPlayerBase().playerID ).AddStation(stationToBuy, True)
					If Not stationToBuy.isAntenna() Then stationToBuy.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT, True)
					ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
				EndIf
			EndIf

		ElseIf TScreenHandler_StationMap.IsInSellActionMode()
			'do not check reach - to allow selling "unused transmitters" / unconnected uplinks
			If TScreenHandler_StationMap.selectedStation 'And TScreenHandler_StationMap.selectedStation.GetReceivers() > 0
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


	Method OnClickRenewButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		'try to renew a contract
		if TScreenHandler_StationMap.selectedStation then TScreenHandler_StationMap.selectedStation.RenewContractOverDuration(12 * TWorldTime.DAYLENGTH)
	End Method


	Method OnSetChecked_AutoRenewCheckbox:Int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent.GetSender())
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False
		'ignore clicks if not sellable (e.g. initial contract)
		If Not TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.SELLABLE) Then Return False

		If TScreenHandler_StationMap.selectedStation
			TScreenHandler_StationMap.selectedStation.SetFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT, button.IsChecked())
		EndIf

		return True
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
			SetSelectedStation( TStationBase(item.data.get("station")) )

			'close potentially open item
			'if TScreenHandler_StationMap.mapInformationFrame.IsOpen() Then TScreenHandler_StationMap.mapInformationFrame.Close()
		EndIf
	End Method
	
	
	Method SetSelectedStation(station:TStationBase)
		TScreenHandler_StationMap.selectedStation = station
		If TScreenHandler_StationMap.selectedStation
			autoRenewCheckbox.SetChecked( TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.AUTO_RENEW_PROVIDER_CONTRACT) )
			If TScreenHandler_StationMap.selectedStation.HasFlag(TVTStationFlag.SELLABLE)
				autoRenewCheckbox.enable()
			Else
				autoRenewCheckbox.disable()
			EndIf
		EndIf

		SetActionMode( GetSellActionMode() )
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
	Method onAppearanceChanged:Int()
		Super.onAppearanceChanged()
		InvalidateContentScreenRect()
		list.SetSize(GetContentScreenRect().GetW()- 2, -1)
	End Method


	Method Update:Int()
		If isOpen
			'NOW done in UpdateLayout()
			'move list to here...
'			If list.rect.x <> 2 'or list.IsAppearanceChanged()
'				list.SetPosition(2, GetHeaderHeight() + 3 )
				'resizing is done when status changes
				'list.SetSize(GetContentScreenRect().w - 2, -1)
'			EndIf


			UpdateActionButton()

			'disable buttons when in different room
			If not TRoomHandler.IsPlayersRoom(TScreenHandler_StationMap.currentSubRoom)
			'If TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID 
				cancelButton.disable()
				actionButton.disable()
				renewButton.disable()
				autoRenewCheckbox.disable()
				renewInfoButton.disable()
			EndIf


			if renewButton.IsVisible()
				if TScreenHandler_StationMap.selectedStation and not TScreenHandler_StationMap.selectedStation.IsShutDown()
					if renewButton.IsHovered() or renewInfoButton.IsHovered()
						For Local t:TTooltipBase = EachIn renewContractTooltips
							t.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED)
							'skip dwelling
							t.SetStep(TTooltipBase.STEP_ACTIVE)
							t.Update()
						Next
					else
						For Local t:TTooltipBase = EachIn renewContractTooltips
							t.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED, False)
							t.Update()
						Next
					endif
				endif
			endif


			list.Update()
			autoRenewCheckbox.Update()
			renewButton.Update()
			renewInfoButton.Update()
			actionButton.Update()
			cancelButton.Update()
		EndIf


		'update count in title
		If TScreenHandler_StationMap.currentSubRoom
			SetValue( GetHeaderValue() )
		EndIf

		For Local t:TTooltipBase = EachIn tooltips
			'avoid tooltips reacting to mouseovers if the panel is closed
			if not isOpen
				t.SetOption(TTooltipBase.OPTION_MANUAL_HOVER_CHECK, True)
			else
				t.SetOption(TTooltipBase.OPTION_MANUAL_HOVER_CHECK, False)
			endif
			t.Update()
		Next


		'call update after button updates so mouse events are properly
		'emitted
		Super.Update()
	End Method


	Method UpdateActionButton:Int()
		'disable buttons when in different room
		If Not TScreenHandler_StationMap.currentSubRoom Then Return False

		If TScreenHandler_StationMap.IsInBuyActionMode()
			If Not TScreenHandler_StationMap.selectedStation
				If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
					actionButton.SetValue(GetLocale("SELECT_SATELLITE")+" ...")
				Else
					actionButton.SetValue(GetLocale("SELECT_LOCATION")+" ...")
				EndIf
				actionButton.disable()
			Else
				Local totalPrice:int = GetStationMap(GetPlayerBase().playerID).GetTotalStationBuyPrice(TScreenHandler_StationMap.selectedStation)
				Local finance:TPlayerFinance = GetPlayerFinance(GetPlayerBase().playerID)
				Local section:TStationMapSection = GetStationMapCollection().GetSectionByName( TScreenHandler_StationMap.selectedStation.GetSectionName() )

				If not section and TStationAntenna(TScreenHandler_StationMap.selectedStation)
					actionButton.SetValue(GetLocale("SECTION_MISSING"))
					actionButton.disable()
				Else
					if section and section.CanGetBroadcastPermission(GetPlayerBase().playerID) = -1
						actionButton.SetValue(GetLocale("CHANNEL_IMAGE_TOO_LOW"))
						actionButton.Disable()
					elseif finance And finance.canAfford(totalPrice)
'TODO: die ganze funktion nur aufrufen, wenn sich was geaendert hat
						actionButton.SetValue(GetLocale( localeKey_BuyItem))
						actionButton.enable()
					Else
						actionButton.SetValue(GetLocale("TOO_EXPENSIVE"))
						actionButton.disable()
					EndIf
				endif
			EndIf

		ElseIf TScreenHandler_StationMap.IsInSellActionMode()
			'different owner or not paid or not sellable
			If TScreenHandler_StationMap.selectedStation
				If TScreenHandler_StationMap.selectedStation.owner <> GetPlayerBase().playerID
					actionButton.SetValue("")
					actionButton.disable()
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

		renewButton.SetValue(GetLocale("RENEW_CONTRACT"))

		Return True
	End Method


	'override
	Method DrawBody()
		'draw nothing if not open
		If Not isOpen Then Return


		Local skin:TDatasheetSkin = GetSkin()
		If skin
			Local contentX:Int = GetScreenRect().GetX()
			Local contentY:Int = GetScreenRect().GetY()
			Local contentW:Int = GetScreenRect().GetW()
			Local currentY:Int = contentY + GetHeaderHeight()


			DrawBodyContent(contentX, contentY, contentW, currentY)


			If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_NONE
				autoRenewCheckbox.Hide()
				renewButton.Hide()
				renewInfoButton.Hide()
				cancelButton.Hide()
				renewButton.SetSize(contentW - 10, -1)
				actionButton.SetSize(contentW - 10, -1)
			Else
				autoRenewCheckbox.SetSize(180,-1)
				renewButton.SetSize(150, -1)
				actionButton.SetSize(150, -1)
				cancelButton.Show()
			EndIf

		EndIf

		list.Draw()
		autoRenewCheckbox.Draw()
		renewInfoButton.Draw()
		renewButton.Draw()
		actionButton.Draw()
		cancelButton.Draw()
	End Method


	Method DrawTooltips:int()
		Super.DrawTooltips()

		if TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
			For Local t:TTooltipBase = EachIn tooltips
				t.Render()
			Next
		endif

		if renewButton.IsVisible()
			if TScreenHandler_StationMap.selectedStation and not TScreenHandler_StationMap.selectedStation.IsShutDown()
				For Local t:TTooltipBase = EachIn renewContractTooltips
					t.Render()
				Next
			endif
		endif
	End Method


	Method DrawBodyContent(contentX:Int, contentY:Int, contentW:Int, contentH:Int)
		'by default draw nothing
	End Method


	Method UpdateLayout()
		Super.UpdateLayout()

		list.SetPosition(2, GetHeaderHeight() + 3 )
		list.SetSize(GetContentScreenRect().GetW() - 2, -1)

		'adjust list size if needed
		Local listH:Int = listBackgroundH - 6
		If listBackgroundH > 0 And list.GetHeight() <> listH
			list.SetSize(-1, listH)
		EndIf


		autoRenewCheckbox.SetPosition(5, GetHeaderHeight() + GetBodyHeight() - 34 - 30 - 23 )
		renewButton.SetPosition(5, GetHeaderHeight() + GetBodyHeight() - 34 - 30 )
		renewInfoButton.SetPosition(5 + 150, GetHeaderHeight() + GetBodyHeight() - 34 - 30 )
		actionButton.SetPosition(5, GetHeaderHeight() + GetBodyHeight() - 34 )
		cancelButton.SetPosition(5 + 150, GetHeaderHeight() + GetBodyHeight() - 34 )
	End Method

	Method getRunningCostsString:String(station:TStationBase)
		If station.HasFlag(TVTStationFlag.NO_RUNNING_COSTS)
			return "-/-"
		ElseIf KeyManager.IsDown(KEY_LSHIFT) OR KeyManager.IsDown(KEY_RSHIFT)
			Local excl:Int = station.GetStationExclusiveReceivers()
			If excl
				Return TFunctions.convertValue(station.GetCurrentRunningCosts()*1000 / excl, 2, 0)+"/1000"
			Else
				Return "-"
			EndIf
		Else
			return TFunctions.convertValue(station.GetCurrentRunningCosts(), 2, 0)
		EndIf
	End Method
End Type




Type TGameGUIAntennaPanel Extends TGameGUIBasicStationmapPanel
	Method Create:TGameGUIAntennaPanel(pos:SVec2I, dimension:SVec2I, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		localeKey_NewItem = "NEW_STATION"
		localeKey_BuyItem = "BUY_STATION"
		localeKey_SellItem = "SELL_STATION"

		'=== register custom event listeners
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, OnChangeStationMapStation) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, OnChangeStationMapStation) ]

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

		Local listContentWidth:Int = list.GetContentScreenRect().GetW()
		For Local station:TStationAntenna = EachIn GetStationMap(playerID).Stations
			Local item:TGUISelectListItem = New TGUISelectListItem.Create(New SVec2I(0,0), New SVec2I(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item.data.AddString("ISOCode", station.GetSectionISO3166Code())
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			item.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, True)
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

		Local boxH:Int = skin.GetBoxSize(100, -1, "").y
		Local boxAreaH:Int = 0
		Local showDetails:Int = False
		Local showPermissionText:Int = False
		Local permissionTextH:int = 34
		'only show when buying/looking for a new
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
			If TScreenHandler_StationMap.selectedStation And section And section.NeedsBroadcastPermission(TScreenHandler_StationMap.selectedStation.owner, TVTStationType.ANTENNA)
				showPermissionText = True
			EndIf
		EndIf
		If TScreenHandler_StationMap.selectedStation Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetSellActionMode() Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() Then showDetails = True

		'update information
		Local boxCount:Int = 2
		Local difficulty:TPlayerDifficulty = GetPlayerDifficulty(GetPlayerBase().playerID)
		Local constructionTime:int=difficulty.antennaConstructionTime
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() and TScreenHandler_StationMap.selectedStation and constructionTime > 0 Then boxCount = 3
		detailsBackgroundH = actionButton.GetScreenRect().GetH() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*boxCount) + showPermissionText * permissionTextH

		If listBackgroundH <> GetBodyHeight() - detailsBackgroundH
			listBackgroundH = GetBodyHeight() - detailsBackgroundH
			'InvalidateLayout()
			UpdateLayout()
		EndIf

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
						'fix incorrect built (eg. code-tests with station ads before worldtime is set)
						if selectedStation.built = 0 then selectedStation.built = GetWorldTime().GetTimeStart()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReceivers(), 2)
						reachChange = MathHelper.DottedValue( -1 * selectedStation.GetStationExclusiveReceivers() )
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						runningCost = getRunningCostsString(selectedStation)
					EndIf

				Case TScreenHandler_StationMap.MODE_BUY_ANTENNA
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					If selectedStation
						local totalPrice:int = GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetTotalStationBuyPrice(selectedStation)

						Local iso:String = selectedStation.GetSectionISO3166Code()
						subHeaderText = GetLocale("MAP_COUNTRY_"+iso+"_LONG") + " (" + GetLocale("MAP_COUNTRY_"+iso+"_SHORT")+")"

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReceivers(), 2)
						reachChange = MathHelper.DottedValue(selectedStation.GetStationExclusiveReceivers())
						price = TFunctions.convertValue( totalPrice, 2, 0)
						runningCost = getRunningCostsString(selectedStation)

						Local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (Not finance Or finance.canAfford(totalPrice))
					EndIf
			End Select


			currentY :+ 2
			skin.fontSmallCaption.DrawBox(headerText, contentX + 5, currentY, contentW - 10,  18, sALIGN_CENTER_TOP, headerColor, EDrawTextEffect.Shadow, 0.2)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.DrawBox(subHeaderText, contentX + 5, currentY, contentW - 10,  18, sALIGN_CENTER_TOP, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
			currentY :+ 15 + 3


			Local halfW:Int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_BUY
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			Else
				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, reachChange, "audienceIncrease", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
			EndIf
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW-5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)


			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				If selectedStation and constructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, selectedStation.GetConstructionTime() + " h", "runningTime", EDatasheetColorStyle.Neutral, skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				EndIf
			EndIf

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = GetSellActionMode()
				If price < 0
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER)
				EndIf
			Else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				If canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
				EndIf
			EndIf
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW-5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH

			If showPermissionText And section And selectedStation
				If Not section.HasBroadcastPermission(selectedStation.owner)
					skin.fontNormal.DrawBox(getLocale("PRICE_INCLUDES_X_FOR_BROADCAST_PERMISSION").Replace("%X%", "|b|"+GetFormattedCurrency(section.GetBroadcastPermissionPrice(selectedStation.owner)) +"|/b|"), contentX + 2, currentY, contentW - 4, permissionTextH, sALIGN_CENTER_CENTER, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
				Else
					currentY :- 1 'align it a bit better
					skin.fontNormal.DrawBox(getLocale("BROADCAST_PERMISSION_EXISTING"), contentX + 2, currentY, contentW - 4, permissionTextH, sALIGN_CENTER_CENTER, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
				EndIf
			EndIf
		EndIf

		'=== BUTTONS ===
		'actionButton.rect.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TGameGUICableNetworkPanel Extends TGameGUIBasicStationmapPanel

	Method Create:TGameGUICableNetworkPanel(pos:SVec2I, dimension:SVec2I, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		localeKey_NewItem = "NEW_CABLE_NETWORK_UPLINK"
		localeKey_BuyItem = "SIGN_UPLINK"
		localeKey_SellItem = "CANCEL_UPLINK"


		'=== register custom event listeners
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, OnChangeStationMapStation) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, OnChangeStationMapStation) ]

		Return Self
	End Method


	Method SetLanguage()
		Super.SetLanguage()

		Local strings:String[] = [GetLocale("REACH"), GetLocale("CONTRACT_DURATION"), GetLocale("CONSTRUCTION_TIME"), GetLocale("RUNNING_COSTS"), GetLocale("PRICE")]
		strings = strings[.. tooltips.length]

		For Local i:Int = 0 Until tooltips.length
			If tooltips[i] Then tooltips[i].SetContent(strings[i])
		Next
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

		Local listContentWidth:Int = list.GetContentScreenRect().GetW()
		For Local station:TStationCableNetworkUplink = EachIn GetStationMap(playerID).Stations
			Local item:TGUISelectListItem = New TGUISelectListItem.Create(New SVec2I(0, 0), New SVec2I(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item.data.AddString("ISOCode", station.GetSectionISO3166Code())
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			item.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, True)
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:String()
		local maxCount:int = GetStationMapCollection().GetSectionCount()
		If TScreenHandler_StationMap.currentSubRoom And GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner)
			Return GetLocale( "CABLE_NETWORK_UPLINKS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.CABLE_NETWORK_UPLINK) + " / " + maxCount
		Else
			Return GetLocale( "CABLE_NETWORK_UPLINKS" ) + ": -" + " / " + maxCount
		EndIf
	End Method



	'override
	Method UpdateActionButton:int()
		If Not TScreenHandler_StationMap.currentSubRoom Then Return False

		Super.UpdateActionButton()


		if TStationCableNetworkUplink(TScreenHandler_StationMap.selectedStation)
			if TScreenHandler_StationMap.IsInBuyActionMode()
				local provider:TStationMap_BroadcastProvider = TScreenHandler_StationMap.selectedStation.GetProvider()
				'disable action button if subscription not possible
				if provider
					if provider.CanSubscribeChannel(GetPlayerBase().playerID) <= 0 or provider.IsSubscribedChannel(GetPlayerBase().playerID)
						Select provider.CanSubscribeChannel(GetPlayerBase().playerID)
							case -1
								actionButton.SetValue(GetLocale("CHANNEL_IMAGE_TOO_LOW"))
							case -2
								actionButton.SetValue(GetLocale("CHANNEL_LIMIT_REACHED"))
						End Select
						actionButton.Disable()
					else
						actionButton.Enable()
					endif
				endif
			endif
		EndIf

		return True
	End Method



	Method DrawBodyContent(contentX:Int,contentY:Int,contentW:Int,currentY:Int)
		Local skin:TDatasheetSkin = GetSkin()
		If Not skin Then Return

		Local section:TStationMapSection
		If TScreenHandler_StationMap.selectedStation Then section = GetStationMapCollection().GetSectionByName(TScreenHandler_StationMap.selectedStation.GetSectionName())

		Local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation
		Local boxH:Int = skin.GetBoxSize(100, -1, "").y
		Local boxAreaH:Int = 0
		Local showDetails:Int = False
		If TScreenHandler_StationMap.selectedStation Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetSellActionMode() Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() Then showDetails = True

		Local showPermissionText:Int = False
		Local permissionTextH:int = 34
		'only show when buying/looking for a new
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
			If TScreenHandler_StationMap.selectedStation And section And section.NeedsBroadcastPermission(TScreenHandler_StationMap.selectedStation.owner, TVTStationType.CABLE_NETWORK_UPLINK)
				showPermissionText = True
			EndIf
		EndIf

		'update information
		Local boxCount:Int = 2
		Local difficulty:TPlayerDifficulty = GetPlayerDifficulty(GetPlayerBase().playerID)
		Local constructionTime:int=difficulty.cableNetworkConstructionTime
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() and TScreenHandler_StationMap.selectedStation and constructionTime > 0 Then boxCount = 3
		detailsBackgroundH = actionButton.GetScreenRect().GetH() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*boxCount) + showPermissionText * permissionTextH
		If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK_UPLINK
			if selectedStation
				detailsBackgroundH :+ renewButton.GetScreenRect().GetH() + 3
				detailsBackgroundH :+ autoRenewCheckbox.GetScreenRect().GetH() + 3
			endif
		EndIf

		If listBackgroundH <> GetBodyHeight() - detailsBackgroundH
			listBackgroundH = GetBodyHeight() - detailsBackgroundH
			'InvalidateLayout()
			UpdateLayout()
		EndIf

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

			Select TScreenHandler_StationMap.actionMode
				Case TScreenHandler_StationMap.MODE_SELL_CABLE_NETWORK_UPLINK
					If selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReceivers(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())
						price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
						runningCost = getRunningCostsString(selectedStation)


						local runningCostChange:int = selectedStation.GetCurrentRunningCosts() - selectedStation.GetRunningCosts()
						if runningCostChange < 0
							renewContractTooltips[1].contentColor = skin.textColorGood
							renewContractTooltips[1].SetContent( GetFormattedCurrency(runningCostChange))
						elseif runningCostChange = 0
							renewContractTooltips[1].contentColor = skin.textColorNeutral
							renewContractTooltips[1].SetContent( "+/- " + GetFormattedCurrency(0))
						else
							renewContractTooltips[1].contentColor = skin.textColorBad
							renewContractTooltips[1].SetContent( "+" + GetFormattedCurrency(runningCostChange))
						endif

					EndIf
					autoRenewCheckbox.Show()
					renewButton.Show()
					renewInfoButton.Show()

				Case TScreenHandler_StationMap.MODE_BUY_CABLE_NETWORK_UPLINK
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					If selectedStation
						local totalPrice:int = GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetTotalStationBuyPrice(selectedStation)
						Local iso:String = selectedStation.GetSectionISO3166Code()
						subHeaderText = GetLocale("MAP_COUNTRY_"+iso+"_LONG") + " (" + GetLocale("MAP_COUNTRY_"+iso+"_SHORT")+")"

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReceivers(), 2)
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue( totalPrice, 2, 0)
'						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						runningCost = getRunningCostsString(selectedStation)

						Local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (Not finance Or finance.canAfford(totalPrice))
					EndIf

					autoRenewCheckbox.Hide()
					renewButton.Hide()
					renewInfoButton.Hide()
			End Select


			currentY :+ 2
			skin.fontSmallCaption.DrawBox(headerText, contentX + 5, currentY, contentW - 10,  18, sALIGN_CENTER_TOP, headerColor, EDrawTextEffect.Shadow, 0.2)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.DrawBox(subHeaderText, contentX + 5, currentY, contentW - 10,  18, sALIGN_CENTER_TOP, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
			currentY :+ 15 + 3


			Local halfW:Int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)


			If selectedStation
				Local subscriptionText:String
				Local provider:TStationMap_BroadcastProvider = selectedStation.GetProvider()
				local duration:long
				If TScreenHandler_StationMap.actionMode = GetBuyActionMode() and provider
					duration = provider.GetDefaultSubscribedChannelDuration()
				Else
					duration = selectedStation.GetSubscriptionTimeLeft()
				EndIf
				if duration >= TWorldTime.DAYLENGTH
					subscriptionText = GetWorldTime().GetFormattedDuration(duration, "d h")
				else
					subscriptionText = GetWorldTime().GetFormattedDuration(duration, "h i")
				endif
				'set to subscription time
				if provider
					renewContractTooltips[0].SetContent( subscriptionText +" -> " + GetWorldTime().GetFormattedDuration(provider.GetDefaultSubscribedChannelDuration(), "d h"))
				else
					renewContractTooltips[0].SetContent( "?" )
				endif

				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, subscriptionText, "duration", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf
			renewContractTooltips[0].parentArea.SetXY(contentX + 5 + halfW-5 + 4, currentY).SetWH(halfW+5, boxH)

			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)
			If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				If selectedStation and difficulty.cableNetworkConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, difficulty.cableNetworkConstructionTime + " h", "runningTime", EDatasheetColorStyle.Neutral, skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				EndIf
			EndIf

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = GetSellActionMode()
				if price < 0
					tooltips[4].SetContent(GetLocale("TERMINATION_FEE"))
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Bad, skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					tooltips[4].SetContent(GetLocale("PROCEEDS_OF_SALE"))
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Good, skin.fontBold, ALIGN_RIGHT_CENTER)
				endif
			Else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				If canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
				EndIf
			EndIf
			renewContractTooltips[1].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH

			If showPermissionText And section And selectedStation
				If Not section.HasBroadcastPermission(selectedStation.owner)
					skin.fontNormal.DrawBox(getLocale("PRICE_INCLUDES_X_FOR_BROADCAST_PERMISSION").Replace("%X%", "|b|"+GetFormattedCurrency(section.GetBroadcastPermissionPrice(selectedStation.owner)) +"|/b|"), contentX + 5, currentY, contentW - 10, permissionTextH, sALIGN_CENTER_CENTER, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
				Else
					currentY :- 1 'align it a bit better
					skin.fontNormal.DrawBox(getLocale("BROADCAST_PERMISSION_EXISTING"), contentX + 5, currentY, contentW - 10, permissionTextH, sALIGN_CENTER_CENTER, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
				EndIf
			EndIf
		EndIf

		'=== BUTTONS ===
		'actionButton.rect.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.SetXY(contentX + 5 + 150, currentY + 3)
	End Method
End Type




Type TGameGUISatellitePanel Extends TGameGUIBasicStationmapPanel
	Method Create:TGameGUISatellitePanel(pos:SVec2I, dimension:SVec2I, value:String, State:String = "")
		Super.Create(pos, dimension, value, State)

		localeKey_NewItem = "NEW_SATELLITE_UPLINK"
		localeKey_BuyItem = "SIGN_UPLINK"
		localeKey_SellItem = "CANCEL_UPLINK"

		'=== register custom event listeners
		'localize the button
		'we have to refresh the gui station list as soon as we remove or add a station
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, OnChangeStationMapStation) ]
		'_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, OnChangeStationMapStation) ]

		Return Self
	End Method


	Method SetLanguage()
		Super.SetLanguage()

		Local strings:String[] = [GetLocale("REACH"), GetLocale("CONTRACT_DURATION"), GetLocale("CONSTRUCTION_TIME"), GetLocale("RUNNING_COSTS"), GetLocale("PRICE")]
		strings = strings[.. tooltips.length]

		For Local i:Int = 0 Until tooltips.length
			If tooltips[i] Then tooltips[i].SetContent(strings[i])
		Next
	End Method


	'override
	Method GetBuyActionMode:Int()
		Return TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
	End Method


	'override
	Method GetSellActionMode:Int()
		Return TScreenHandler_StationMap.MODE_SELL_SATELLITE_UPLINK
	End Method


	'override
	Method OnClickRenewButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		'ignore clicks if not in the own office
		If Not TScreenHandler_StationMap.currentSubRoom Or TScreenHandler_StationMap.currentSubRoom.owner <> GetPlayerBase().playerID Then Return False

		local satLink:TStationSatelliteUplink = TStationSatelliteUplink(TScreenHandler_StationMap.selectedStation)
		if not satLink then return False


		'select new satellite
		if satLink.IsShutDown()
			if not TScreenHandler_StationMap.satelliteSelectionFrame.IsOpen()
				TScreenHandler_StationMap.satelliteSelectionFrame.Open()
			else
				if TScreenHandler_StationMap.satelliteSelectionFrame.selectedSatellite
					'set new provider/satellite
					satLink.SetProvider( TScreenHandler_StationMap.satelliteSelectionFrame.selectedSatellite.GetID() )

					'sign potential contracts (= add connections)
					satLink.SignContract()

					ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
				EndIf
			endif
		else

			Return Super.OnClickRenewButton(triggerEvent)

			'try to renew a contract
			'TScreenHandler_StationMap.selectedStation.RenewContract(12 * TWorldTime.DAYLENGTH)
		endif
	End Method


	'override
	Method UpdateActionButton:int()
		If Not TScreenHandler_StationMap.currentSubRoom Then Return False

		Super.UpdateActionButton()


		local openFrame:int = TScreenHandler_StationMap.satelliteSelectionFrame and TScreenHandler_StationMap.satelliteSelectionFrame.IsOpen()
		local selectedSatellite:TStationMap_Satellite = TScreenHandler_StationMap.satelliteSelectionFrame.selectedSatellite
'		actionButton.Disable()
'		renewButton.Disable()


		if TScreenHandler_StationMap.selectedStation
			if TScreenHandler_StationMap.IsInBuyActionMode()
				'disable action button if subscription not possible
				if openFrame
					actionButton.Enable()
					if selectedSatellite
						if selectedSatellite.CanSubscribeChannel(GetPlayerBase().playerID) <= 0 or selectedSatellite.IsSubscribedChannel(GetPlayerBase().playerID)
							Select selectedSatellite.CanSubscribeChannel(GetPlayerBase().playerID)
								case -1
									actionButton.SetValue(GetLocale("CHANNEL_IMAGE_TOO_LOW"))
								case -2
									actionButton.SetValue(GetLocale("CHANNEL_LIMIT_REACHED"))
							End Select
							actionButton.Disable()
						endif
					endif
				endif
			endif


			'sat uplinks can be sold extra
			If TScreenHandler_StationMap.selectedStation.IsShutDown()
				If TStationSatelliteUplink(TScreenHandler_StationMap.selectedStation)
					actionButton.SetValue(GetLocale("SELL_TRANSMITTER"))
'					if not openFrame
'						actionButton.Enable()
'					endif

					if openFrame
						if selectedSatellite
							renewInfoButton.Enable()
							renewButton.Enable()
						else
							renewInfoButton.Disable()
							renewButton.Disable()
						endif
						renewButton.SetValue(GetLocale("SIGN_UPLINK"))
						renewInfoButton.Enable()
					else
						renewButton.SetValue(GetLocale("SELECT_SATELLITE"))
						renewInfoButton.Disable()
'						renewButton.enable()
					endif
				EndIf
			EndIf
		EndIf

		return True
	End Method



	'rebuild the stationList - eg. when changed the room (other office)
	Method RefreshList(playerID:Int=-1)
		Super.RefreshList(playerID)

		'update satellites too
		if TScreenHandler_StationMap.satelliteSelectionFrame
			TScreenHandler_StationMap.satelliteSelectionFrame.RefreshSatellitesList()
		endif

		If playerID <= 0 Then playerID = GetPlayerBase().playerID

		Local listContentWidth:Int = list.GetContentScreenRect().GetW()
		For Local station:TStationSatelliteUplink = EachIn GetStationMap(playerID).Stations
			Local item:TGUISelectListItem = New TGUISelectListItem.Create(New SVec2I(0,0), New SVec2I(listContentWidth,20), station.GetLongName())
			'fill complete width
			item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
			'link the station to the item
			item.data.Add("station", station)
			item.data.AddString("ISOCode", station.GetSectionISO3166Code())
			item._customDrawContent = TScreenHandler_StationMap.DrawMapStationListEntryContent
			item.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, True)
			list.AddItem( item )
		Next
	End Method


	Method GetHeaderValue:String()
		local maxCount:int = GetStationMapCollection().satellites.Count()
		If TScreenHandler_StationMap.currentSubRoom And GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner)
			Return GetLocale( "SATELLITE_UPLINKS" ) + ": " + GetStationMap(TScreenHandler_StationMap.currentSubRoom.owner).GetStationCount(TVTStationType.SATELLITE_UPLINK) + " / " + maxCount
		Else
			Return GetLocale( "SATELLITE_UPLINKS" ) + ": -/" + " / " + maxCount
		EndIf
	End Method


	Method DrawBodyContent(contentX:Int,contentY:Int,contentW:Int,currentY:Int)
		Local skin:TDatasheetSkin = GetSkin()
		If Not skin Then Return

		Local selectedStation:TStationBase = TScreenHandler_StationMap.selectedStation
		Local boxH:Int = skin.GetBoxSize(100, -1, "").y
		Local boxAreaH:Int = 0
		Local showDetails:Int = False
		If selectedStation Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetSellActionMode() Then showDetails = True
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() Then showDetails = True

		Local showIncludesHardwareText:int = False
		Local includesHardwareTextH:int = 24

		'update information
		Local boxCount:Int = 2
		Local difficulty:TPlayerDifficulty = GetPlayerDifficulty(GetPlayerBase().playerID)
		Local constructionTime:int=difficulty.satelliteConstructionTime
		If TScreenHandler_StationMap.actionMode = GetBuyActionMode() and selectedStation and constructionTime > 0 Then boxCount = 3
		detailsBackgroundH = actionButton.GetScreenRect().GetH() + 2*6 + (showDetails<>False)*(24 + (boxH+2)*boxCount)
		If TScreenHandler_StationMap.actionMode = TScreenHandler_StationMap.MODE_SELL_SATELLITE_UPLINK
			if selectedStation
				detailsBackgroundH :+ renewButton.GetScreenRect().GetH() + 3
				detailsBackgroundH :+ autoRenewCheckbox.GetScreenRect().GetH() + 3

				if TStationSatelliteUplink(selectedStation).IsShutdown()
					showIncludesHardwareText = True
					detailsBackgroundH :+ includesHardwareTextH
				endif
			EndIf
		EndIf

		If listBackgroundH <> GetBodyHeight() - detailsBackgroundH
			listBackgroundH = GetBodyHeight() - detailsBackgroundH
			'InvalidateLayout()
			UpdateLayout()
		EndIf

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

			Select TScreenHandler_StationMap.actionMode
				Case TScreenHandler_StationMap.MODE_SELL_SATELLITE_UPLINK
					If selectedStation
						headerText = selectedStation.GetLongName()
						subHeaderText = GetWorldTime().GetFormattedGameDate(selectedStation.built)
						reach = TFunctions.convertValue(selectedStation.GetReceivers(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachDecrease())

						'reassign to new satellite?
						if TScreenHandler_StationMap.satelliteSelectionFrame.IsOpen() and TScreenHandler_StationMap.satelliteSelectionFrame.selectedSatellite
							price = TFunctions.convertValue( selectedStation.GetBuyPrice(), 2, 0)
							runningCost = TFunctions.convertValue(selectedStation.GetCurrentRunningCosts(), 2, 0)
						else
							local runningCostChange:int = selectedStation.GetCurrentRunningCosts() - selectedStation.GetRunningCosts()
							if runningCostChange < 0
								renewContractTooltips[1].contentColor = skin.textColorGood
								renewContractTooltips[1].SetContent( GetFormattedCurrency(runningCostChange))
							elseif runningCostChange = 0
								renewContractTooltips[1].contentColor = skin.textColorNeutral
								renewContractTooltips[1].SetContent( "+/- " +GetFormattedCurrency(0))
							else
								renewContractTooltips[1].contentColor = skin.textColorBad
								renewContractTooltips[1].SetContent( "+"+GetFormattedCurrency(runningCostChange))
							endif

							price = TFunctions.convertValue(selectedStation.GetSellPrice(), 2, 0)
							runningCost = getRunningCostsString(selectedStation)
						endif
					EndIf
					autoRenewCheckbox.Show()
					renewButton.Show()
					renewInfoButton.Show()

				Case TScreenHandler_StationMap.MODE_BUY_SATELLITE_UPLINK
					headerText = GetLocale( localeKey_NewItem )

					'=== BOXES ===
					If selectedStation
						'Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatelliteByGUID( TStationSatelliteUplink(selectedStation).satelliteGUID)
						'if not satellite then satellite = TScreenHandler_StationMap.satelliteSelectionFrame.selectedSatellite

						subHeaderText = selectedStation.GetName()

						'stationName = Koordinaten?
						reach = TFunctions.convertValue(selectedStation.GetReceivers(), 2)
'not needed
'						reachChange = MathHelper.DottedValue(selectedStation.GetReachIncrease())
						price = TFunctions.convertValue(selectedStation.getPrice(), 2, 0)
						runningCost = getRunningCostsString(selectedStation)

						Local finance:TPlayerFinance = GetPlayerFinance(TScreenHandler_StationMap.currentSubRoom.owner)
						canAfford = (Not finance Or finance.canAfford(selectedStation.GetPrice()))
					EndIf
					autoRenewCheckbox.Hide()
					renewButton.Hide()
					renewInfoButton.Hide()
			End Select


			currentY :+ 2
			skin.fontSmallCaption.DrawBox(headerText, contentX + 5, currentY, contentW - 10,  18, sALIGN_CENTER_TOP, headerColor, EDrawTextEffect.Shadow, 0.2)
			'currentY :+ skin.fontNormal._fSize
			currentY :+ 14
			skin.fontNormal.DrawBox(subHeaderText, contentX + 5, currentY, contentW - 10,  18, sALIGN_CENTER_TOP, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
			currentY :+ 15 + 3


			Local halfW:Int = (contentW - 10)/2 - 2
			'=== BOX LINE 1 ===
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, reach, "audience", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			tooltips[0].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			If selectedStation
				Local subscriptionText:String
				Local provider:TStationMap_BroadcastProvider = selectedStation.GetProvider()
				if not provider then provider = TScreenHandler_StationMap.satelliteSelectionFrame.selectedSatellite
				local duration:Long
				If TScreenHandler_StationMap.actionMode = GetBuyActionMode() and provider
					duration = provider.GetDefaultSubscribedChannelDuration()
				Else
					duration = selectedStation.GetSubscriptionTimeLeft()
				EndIf
				if duration >= TWorldTime.DAYLENGTH
					subscriptionText = GetWorldTime().GetFormattedDuration(duration, "d h")
				else
					subscriptionText = GetWorldTime().GetFormattedDuration(duration, "h i")
				endif
				'set to subscription time
				if provider
					renewContractTooltips[0].SetContent( subscriptionText +" -> " + GetWorldTime().GetFormattedDuration(provider.GetDefaultSubscribedChannelDuration(), "d h"))
				else
					renewContractTooltips[0].SetContent( "?" )
				endif

				skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, subscriptionText, "duration", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf
			renewContractTooltips[0].parentArea.SetXY(contentX + 5 + halfW-5 + 4, currentY).SetWH(halfW+5, boxH)

			'=== BOX LINE 2 (optional) ===
			tooltips[2].parentArea.SetXY(-1000,0)

			If TScreenHandler_StationMap.actionMode = GetBuyActionMode()
				If selectedStation and difficulty.satelliteConstructionTime > 0
					currentY :+ boxH
					skin.RenderBox(contentX + 5, currentY, halfW-5, -1, difficulty.satelliteConstructionTime + " h", "runningTime", EDatasheetColorStyle.Neutral, skin.fontNormal)
					tooltips[2].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
				EndIf
			EndIf

			'=== BOX LINE 3 ===
			currentY :+ boxH
			skin.RenderBox(contentX + 5, currentY, halfW-5, -1, runningCost, "moneyRepetitions", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			If TScreenHandler_StationMap.actionMode = GetSellActionMode()
				if price < 0
					tooltips[4].SetContent(GetLocale("TERMINATION_FEE"))
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Bad, skin.fontBold, ALIGN_RIGHT_CENTER)
				else
					tooltips[4].SetContent(GetLocale("PROCEEDS_OF_SALE"))
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Good, skin.fontBold, ALIGN_RIGHT_CENTER)
				endif
			Else
				'fetch financial state of room owner (not player - so take care
				'if the player is allowed to do this)
				If canAfford
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER)
				Else
					skin.RenderBox(contentX + 5 + halfW-5 + 4, currentY, halfW+5, -1, price, "money", EDatasheetColorStyle.Neutral, skin.fontBold, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
				EndIf
			EndIf
			renewContractTooltips[1].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[3].parentArea.SetXY(contentX + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[4].parentArea.SetXY(contentX + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)

			currentY :+ boxH


			If showIncludesHardwareText
				'TODO constant value 123?
				skin.fontNormal.DrawBox(getLocale("PRICE_INCLUDES_X_FOR_HARDWARE").Replace("%X%", "|b|"+ GetFormattedCurrency(123) +"|/b|"), contentX + 5, currentY, contentW - 10, includesHardwareTextH, sALIGN_CENTER_CENTER, subHeaderColor, EDrawTextEffect.Emboss, 0.55)
			EndIf
		EndIf

		'renewButton.rect.SetXY(contentX + 5, currentY + 3)

		'=== BUTTONS ===
		'actionButton.rect.SetXY(contentX + 5, currentY + 3)
		'cancelButton.rect.SetXY(contentX + 5 + 150, currentY + 3)
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

	Field _eventListeners:TEventListenerBase[]


	Method New()
		If Not area Then area = New TRectangle.Init(402, 96, 190, 212)
		If Not contentArea Then contentArea = New TRectangle

		satelliteList = New TGUISelectList.Create(New SVec2I(410, 121), New SVec2I(178, 100), "STATIONMAP")
		'scroll by one entry at a time
		satelliteList.scrollItemHeightPercentage = 1.0
		satelliteList.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)
		satelliteList.SetFont( GetBitmapFontManager().Get("Default", 11) )

		'panel handles them (similar to a child - but with manual draw/update calls)
		'satelliteList.SetParent(self)
		GuiManager.Remove(satelliteList)


		tooltips = New TTooltipBase[4]
		For Local i:Int = 0 Until tooltips.length
			tooltips[i] = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = New TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = New TVec2D(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next

		'fill with content
		RefreshSatellitesList()


		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.StationMapCollection_RemoveSatellite, Self, "OnChangeSatellites") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.StationMapCollection_AddSatellite, Self, "OnChangeSatellites") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.StationMapCollection_LaunchSatellite, Self, "OnChangeSatellites") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUISelectList_OnSelectEntry, Self, "OnSelectEntryList", satelliteList) ]

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


		Local listContentWidth:Int = satelliteList.GetContentScreenRect().GetW()

		If GetStationMapCollection().satellites
			For Local satellite:TStationMap_Satellite = EachIn GetStationMapCollection().satellites
				If Not satellite.IsLaunched() Then Continue

				Local item:TGUISelectListItem = New TGUISelectListItem.Create(New SVec2I(0,0), New SVec2I(listContentWidth,20), satellite.name)

				'fill complete width
				item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)

				'link the station to the item
				item.data.Add("satellite", satellite)
				item._customDrawContent = DrawSatelliteListEntryContent
				item.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, True)
				satelliteList.AddItem( item )
			Next
		EndIf

		Return True
	End Method


	'custom drawing function for list entries
	Function DrawSatelliteListEntryContent:Int(obj:TGUIObject)
		Local item:TGUISelectListItem = TGUISelectListItem(obj)
		If Not item Then Return False

		Local satellite:TStationMap_Satellite = TStationMap_Satellite(item.data.Get("satellite"))
		If Not satellite Then Return False

		Local sprite:TSprite
		If satellite.IsSubscribedChannel(GetPlayerBase().playerID)
			sprite = GetSpriteFromRegistry(satellite.listSpriteNameOn)
		Else
			sprite = GetSpriteFromRegistry(satellite.listSpriteNameOff)
		EndIf

		Local paddingLR:Int = 2
		Local textOffsetX:Int = paddingLR + sprite.GetWidth() + 5
		Local textOffsetY:Int = 2
		Local textW:Int = item.GetScreenRect().GetW() - textOffsetX - paddingLR

		Local currentColor:SColor8; GetColor(currentColor)
		Local currentAlpha:Float = GetAlpha()
		Local entryColor:SColor8
		Local leftValue:string = item.GetValue()
		local highlight:int = False

		'draw with different color according status
		If satellite.IsSubscribedChannel(GetPlayerBase().playerID)
			entryColor = New SColor8(80,130,50, int(255 * currentAlpha))
			highlight = True
		ElseIf satellite.CanSubscribeChannel(GetPlayerBase().playerID) <= 0
			entryColor = New SColor8(130,80,50, int(255 * currentAlpha * 0.85))
			highlight = True
		Else
			entryColor = item.valueColor '.copy().AdjustFactor(50)
'			entryColor.a = currentAlpha * 0.5
		EndIf

		if highlight
			SetColor(entryColor)
			SetAlpha entryColor.a / 255.0 * 0.5
			DrawRect(Int(item.GetScreenRect().GetX() + paddingLR), item.GetScreenRect().GetY(), sprite.GetWidth(), item.rect.getH())
			SetColor(currentColor)
			SetAlpha(currentAlpha)
		endif

		'draw antenna
		sprite.Draw(Int(item.GetScreenRect().GetX() + paddingLR), item.GetScreenRect().GetY() + 0.5*item.rect.getH(), -1, ALIGN_LEFT_CENTER)
		item.GetFont().DrawBox(leftValue, Int(item.GetScreenRect().GetX() + textOffsetX), Int(item.GetScreenRect().GetY() + textOffsetY), textW - 5, Int(item.GetScreenRect().GetH() - textOffsetY), sALIGN_LEFT_CENTER, entryColor)
	End Function


	Method Update:Int()
		If contentArea
			If satelliteList.rect.GetX() <> contentArea.GetX()
				satelliteList.SetPosition(contentArea.GetX(), contentArea.GetIntY() + 16)
			EndIf
			If satelliteList.GetWidth() <> contentArea.GetW()
				satelliteList.SetSize(contentArea.GetW())
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
			satelliteList.SetSize(-1, listHeight)
		EndIf


		Local currentY:Int = contentArea.GetIntY()


		Local headerText:String = GetLocale("SATELLITES")
		Local titleColor:SColor8 = new SColor8(75,75,75)
		Local subTitleColor:SColor8 = new SColor8(115,115,115)



		'=== HEADER ===
		skin.RenderContent(contentArea.GetIntX(), contentArea.GetIntY(), contentArea.GetIntW(), headerHeight, "1_top")
		skin.fontNormal.DrawBox("|b|"+headerText+"|/b|", contentArea.GetX() + 5, currentY, contentArea.GetIntW() - 10,  headerHeight+2, sALIGN_CENTER_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		currentY :+ headerHeight

		'=== LIST ===
		skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), listHeight, "2")
		satelliteList.Draw()
		currentY :+ listHeight


		'=== SATELLITE DETAILS ===
		If selectedSatellite
			Local titleText:String = selectedSatellite.name
			Local subtitleText:String = GetLocale("NOT_LAUNCHED_YET")
			If selectedSatellite.IsLaunched()
				subtitleText = GetLocale("LAUNCHED")+": " + GetWorldTime().GetFormattedDate(selectedSatellite.launchTime, GameConfig.dateFormat)
			EndIf

			skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), detailsH, "1_top")
			currentY :+ 2
			skin.fontSmallCaption.DrawBox(titleText, contentArea.GetX() + 5, currentY, contentArea.GetIntW() - 10,  18, sALIGN_CENTER_TOP, titleColor, EDrawTextEffect.Shadow, 0.2)
			currentY :+ 14
			skin.fontNormal.DrawBox(subTitleText, contentArea.GetX() + 5, currentY, contentArea.GetIntW() - 10,  18, sALIGN_CENTER_TOP, subTitleColor, EDrawTextEffect.Emboss, 0.75)
			currentY :+ 15 + 3


			Local halfW:Int = (contentArea.GetW() - 10)/2 - 2
			Local boxH:Int = skin.GetBoxSize(100, -1, "").y
			'=== BOX LINE 1 ===
			'local qualityText:string = "-/-"
			'if selectedSatellite.quality <> 100
			'	qualityText = MathHelper.NumberToString((selectedSatellite.quality-100), 0, True)+"%"
			'endif
			Local qualityText:String = MathHelper.NumberToString(selectedSatellite.quality, 0, True)+"%"
			Local marketShareText:String = MathHelper.NumberToString(100*selectedSatellite.populationShare, 1, True)+"%"

			If selectedSatellite.quality < 100
				skin.RenderBox(contentArea.GetIntX() + 5, currentY, halfW-5, -1, qualityText, "quality", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
			Else
				skin.RenderBox(contentArea.GetIntX() + 5, currentY, halfW-5, -1, qualityText, "quality", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf
			skin.RenderBox(contentArea.GetIntX() + 5 + halfW-5 + 4, currentY, halfW+5, -1, marketShareText, "marketShare", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			tooltips[0].parentArea.SetXY(contentArea.GetX() + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[1].parentArea.SetXY(contentArea.GetX() + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)



			currentY :+ boxH
			Local minImageText:String = MathHelper.NumberToString(selectedSatellite.minimumChannelImage, 1, True)+"%"

			If Not GetPublicImage(owner) Or GetPublicImage(owner).GetAverageImage() < selectedSatellite.minimumChannelImage
				skin.RenderBox(contentArea.GetIntX() + 5, currentY, halfW-5, -1, minImageText, "image", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER, EDatasheetColorStyle.Bad)
			Else
				skin.RenderBox(contentArea.GetIntX() + 5, currentY, halfW-5, -1, minImageText, "image", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			EndIf


			'draw "used by channel xy" box
			Local channelX:Int = contentArea.GetX() + 5 + halfW-5 + 4
			skin.RenderBox(channelX, currentY, halfW+5, -1, "", "audience", EDatasheetColorStyle.Neutral, skin.fontNormal, ALIGN_RIGHT_CENTER)
			tooltips[2].parentArea.SetXY(contentArea.GetX() + 5, currentY).SetWH(halfW+5, boxH)
			tooltips[3].parentArea.SetXY(contentArea.GetX() + 5 + halfW-5 +4, currentY).SetWH(halfW+5, boxH)



			channelX :+ 27
			Local oldCol:SColor8; GetColor(oldCol)
			Local oldColA:Float = GetAlpha()
			For Local i:Int = 1 To 4
				SetColor( 50,50,50 )
				SetAlpha( oldColA * 0.4 )
				DrawRect(channelX, currentY + 6, 11,11)
				If selectedSatellite.IsSubscribedChannel(i)
					GetPlayerBase(i).color.SetRGB()
					SetAlpha( oldColA )
				Else
					SetColor( 255,255,255 )
					SetAlpha( oldColA * 0.5 )
				EndIf
				DrawRect(channelX+1, currentY + 7, 9,9)
				'GetSpriteFromRegistry("gfx_gui_button.datasheet").DrawArea(channelX, currentY + 4, 14, 14)
				channelX :+ 13
			Next
			SetColor( oldCol )
			SetAlpha( oldColA )
		EndIf


		skin.RenderBorder(area.GetIntX(), area.GetIntY(), area.GetIntW(), area.GetIntH())

		'debug
		Rem
		DrawRect(contentArea.GetX(), contentArea.GetIntY(), 20, contentArea.GetH() )
		Setcolor 255,0,0
		DrawRect(contentArea.GetX() + 10, contentArea.GetIntY(), 20, headerHeight )
		Setcolor 255,255,0
		DrawRect(contentArea.GetX() + 20, contentArea.GetIntY() + headerHeight, 20, listHeight )
		Setcolor 255,0,255
		DrawRect(contentArea.GetX() + 30, contentArea.GetIntY() + headerHeight + listHeight, 20, detailsH )
		endrem
	End Method


	Method DrawTooltips()
'		Super.DrawOverlay()

		For Local t:TTooltipBase = EachIn tooltips
			t.Render()
		Next
	End Method
End Type





Type TStationMapInformationFrame
	Field area:TRectangle
	Field contentArea:TRectangle
	Field headerHeight:Int
	Field countryInformationHeight:Int = 90
	Field sectionListHeight:Int
	Field sectionListHeaderHeight:Int = 16
	Field selectedSection:TStationMapSection
	Field sectionList:TGUISelectList
	Field tooltips:TTooltipBase[]
	Field _open:Int = False
	Global subHeaderColor:SColor8 = New SColor8(115,115,115)

	Field _eventListeners:TEventListenerBase[]


	Method New()
		sectionList = New TGUISelectList.Create(New SVec2I(410,153), New SVec2I(378, 100), "STATIONMAP")
		'scroll by one entry at a time
		sectionList.scrollItemHeightPercentage = 1.0
		sectionList.SetListOption(GUILIST_SCROLL_TO_NEXT_ITEM, True)
		sectionList.SetFont( GetBitmapFontManager().Get("Default", 11) )

		'panel handles them (similar to a child - but with manual draw/update calls)
		GuiManager.Remove(sectionList)

		tooltips = New TTooltipBase[4]
		For Local i:Int = 0 Until tooltips.length
			tooltips[i] = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
			tooltips[i].parentArea = New TRectangle
			tooltips[i].SetOrientationPreset("TOP")
			tooltips[i].offset = New TVec2D(0,+5)
			tooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
			'standard icons should need a bit longer for tooltips to show up
			tooltips[i].dwellTime = 500
		Next

		'fill with content
		RefreshSectionList()


		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		'we have to refresh the gui station list as soon as we remove or add a station
		_eventListeners :+ [ EventManager.registerListenerMethod(GameEventKeys.StationMapCollection_AddSection, Self, "OnChangeSections") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUISelectList_OnSelectEntry, Self, "OnSelectEntryList", sectionList) ]

'		return self
	End Method


	Method SetLanguage()
		Local strings:String[] = [GetLocale("BROADCAST_QUALITY"), GetLocale("MARKET_SHARE"), GetLocale("REQUIRED_CHANNEL_IMAGE"), GetLocale("SUBSCRIBED_CHANNELS")]
		strings = strings[.. tooltips.length]

		For Local i:Int = 0 Until tooltips.length
			If tooltips[i] Then tooltips[i].SetContent(strings[i])
		Next
	End Method


	Method OnChangeSections:Int(triggerEvent:TEventBase)
		RefreshSectionList()
	End Method


	'an entry was selected - make the linked section the currently selected one
	Method OnSelectEntryList:Int(triggerEvent:TEventBase)
		Local senderList:TGUISelectList = TGUISelectList(triggerEvent._sender)
		If Not senderList Then Return False
		If senderList <> sectionList Then Return False
		If Not TScreenHandler_StationMap.currentSubRoom Then Return False
		If Not GetPlayerBaseCollection().IsPlayer(TScreenHandler_StationMap.currentSubRoom.owner) Then Return False

		'set the linked satellite as the selected one
		Local item:TGUISelectListItem = TGUISelectListItem(senderList.getSelectedEntry())
		If item
			selectedSection = TStationMapSection(item.data.get("section"))
		EndIf
	End Method


	Method SelectSection:Int(section:TStationMapSection)
		selectedSection = section
		If Not selectedSection
			sectionList.DeselectEntry()

			Return True
		Else
			For Local i:TGUIListItem = EachIn sectionList.entries
				Local itemSection:TStationMapSection = TStationMapSection(i.data.get("section"))
				If itemSection = section
					sectionList.SelectEntry(i)

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
		SelectSection(Null)

		_open = False
		Return True
	End Method


	Method Open:Int()
		_open = True
		Return True
	End Method


	'custom drawing function for list entries
	Function DrawMapSectionListEntryContent:Int(obj:TGUIObject)
		Local item:TGUISelectListItem = TGUISelectListItem(obj)
		If Not item Then Return False

		Local section:TStationMapSection = TStationMapSection(item.data.Get("section"))
		If Not section Then Return False

		local owner:int = 0
		if TScreenHandler_StationMap.currentSubRoom then owner = TScreenHandler_StationMap.currentSubRoom.owner
		if owner = 0 then return False

		Local valueA:String = GetLocale("MAP_COUNTRY_"+section.GetISO3166Code()+"_LONG")
		Local valueB:String = GetLocale("NO")
		if section.HasBroadcastPermission(owner) then valueB = GetLocale("YES")
		Local valueC:String = MathHelper.NumberToString(section.GetPressureGroupsChannelSympathy(owner)*100,2) +"%"
		Local valueD:String = TFunctions.convertValue(section.GetPopulation(), 2, 0)
		Local paddingLR:Int = 2
		Local textOffsetX:Int = paddingLR + 5
		Local textOffsetY:Int = 2
		Local textW:Int = item.GetScreenRect().GetW() - textOffsetX - paddingLR
		Local colY:Int = Int(item.GetScreenRect().GetY() + textOffsetY)
		Local colHeight:Int = Int(item.GetScreenRect().GetH() - textOffsetY)
		Local colWidthA:Int = 0.45 * textW
		Local colWidthB:Int = 0.2 * textW
		Local colWidthC:Int = 0.1 * textW
		Local colWidthD:Int = 0.25 * textW

		'draw with different color according status
		'draw antenna
		item.GetFont().DrawBox(valueA, Int(item.GetScreenRect().GetX() + textOffsetX), colY, colWidthA, colHeight, sALIGN_LEFT_CENTER, item.valueColor)
		textOffsetX :+ colWidthA
		item.GetFont().DrawBox(valueB, Int(item.GetScreenRect().GetX() + textOffsetX), Int(item.GetScreenRect().GetY() + textOffsetY), colWidthB, colHeight, sALIGN_LEFT_CENTER, item.valueColor)
		textOffsetX :+ colWidthB
		item.GetFont().DrawBox(valueC, Int(item.GetScreenRect().GetX() + textOffsetX), Int(item.GetScreenRect().GetY() + textOffsetY), colWidthC, colHeight, sALIGN_LEFT_CENTER, item.valueColor)
		textOffsetX :+ colWidthC
		item.GetFont().DrawBox(valueD, Int(item.GetScreenRect().GetX() + textOffsetX), Int(item.GetScreenRect().GetY() + textOffsetY), colWidthD, colHeight, sALIGN_RIGHT_CENTER, item.valueColor)
		textOffsetX :+ colWidthD
	End Function


	Method RefreshSectionList:Int()
		sectionList.EmptyList()
		'remove potential highlighted item
		sectionList.deselectEntry()

		'keep them sorted the way we added the stations
		sectionList.setListOption(GUILIST_AUTOSORT_ITEMS, False)


		Local listContentWidth:Int = sectionList.GetContentScreenRect().GetW()

		If GetStationMapCollection().sections
			For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
				Local item:TGUISelectListItem = New TGUISelectListItem.Create(New SVec2I(0,0), New SVec2I(listContentWidth,20), section.name)

				'fill complete width
				item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)

				'link the station to the item
				item.data.Add("section", section)
				item._customDrawContent = DrawMapSectionListEntryContent
				item.SetOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE, True)
				sectionList.AddItem( item )
			Next
		EndIf

		Return True
	End Method


	Method Update:Int()
		If contentArea
			If sectionList.rect.GetX() <> contentArea.GetX()
				sectionList.SetPosition(contentArea.GetX(), contentArea.GetIntY() + 16 + countryInformationHeight + sectionListHeaderHeight)
			EndIf
			If sectionList.GetWidth() <> contentArea.GetW()
				sectionList.SetSize(contentArea.GetW())
			EndIf
		EndIf

		sectionList.update()

		For Local t:TTooltipBase = EachIn tooltips
			t.Update()
		Next
	End Method


	Method Draw:Int()
		Local skin:TDatasheetSkin = GetDatasheetSkin("stationMapPanel")
		If Not skin Then Return False

		Local owner:Int = GetPlayer().playerID
		If TScreenHandler_StationMap.currentSubRoom Then owner = TScreenHandler_StationMap.currentSubRoom.owner

		If Not area Then area = New TRectangle.Init(170, 5, 400, 349)
		If Not contentArea Then contentArea = New TRectangle

		Local detailsH:Int = 90 * (selectedSection<>Null)
		'local boxH:int = skin.GetBoxSize(100, -1, "").GetY()
		contentArea.SetW( skin.GetContentW( area.GetW() ) )
		contentArea.SetX( area.GetX() + skin.GetContentX() )
		contentarea.SetY( area.GetY() + skin.GetContentY() )
		contentArea.SetH( area.GetH() - (skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()) )

		headerHeight = 18
		sectionListHeight = contentArea.GetH() - headerHeight - countryInformationHeight - detailsH - sectionListHeaderHeight

		'resize list if needed
		If sectionListHeight <> sectionList.GetHeight()-5
			sectionList.SetSize(-1, sectionListHeight-5)
		EndIf


		Local currentY:Int = contentArea.GetIntY()


		Local headerText:String = GetLocale("MAP_COUNTRY_"+GetStationMapCollection().GetMapISO3166Code()+"_LONG")
		Local titleColor:SColor8 = new SColor8(75,75,75)
		Local subTitleColor:SColor8 = new SColor8(115,115,115)



		'=== HEADER ===
		skin.RenderContent(contentArea.GetIntX(), contentArea.GetIntY(), contentArea.GetIntW(), headerHeight, "1_top")
		skin.fontBold.DrawBox(headerText, contentArea.GetX() + 5, currentY +1, contentArea.GetIntW() - 10,  headerHeight, sALIGN_CENTER_CENTER, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		currentY :+ headerHeight

		'=== COUNTRY DETAILS ===
		skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), countryInformationHeight, "1")
		local lineH:int = 14
		local col1W:int = 100
		local col2W:int = 60
		local col3W:int = 110
		local col4W:int = 70
		local col1:int = contentArea.GetX() + 5
		local col3:int = contentArea.GetX2() - 5 - col3W - col4W
		local col2:int = col1 + col1W
		local col4:int = col3 + col3W
		local textY:int = currentY + 1
		local overviewLineH:Int = 18
		skin.fontNormal.DrawBox("|b|"+GetLocale("POPULATION")+":|/b|", col1, textY + 0*lineH, col1W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(TFunctions.DottedValue(GetStationMapCollection().GetPopulation()), col2, textY + 0*lineH, col2W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox("|b|"+GetLocale("STATIONMAP_SECTIONS_NAME")+":|/b|", col1, textY + 1*lineH, col1W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetStationMapCollection().GetSectionCount(), col2, textY + 1*lineH, col2W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)

		skin.fontNormal.DrawBox("|b|"+GetLocale("RECEIVER_SHARE")+"|/b|", col3, textY + 0*lineH, col3W + col4W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetLocale("ANTENNA_RECEIVERS")+":", col3, textY + 1*lineH, col3W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(MathHelper.NumberToString(GetStationMapCollection().GetAveragePopulationAntennaShare()*100, 2)+"%", col4, textY + 1*lineH, col4W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetLocale("SATELLITE_RECEIVERS")+":", col3, textY + 2*lineH, col3W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(MathHelper.NumberToString(GetStationMapCollection().GetAveragePopulationSatelliteShare()*100, 2)+"%", col4, textY + 2*lineH, col4W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetLocale("CABLE_NETWORK_RECEIVERS")+":", col3, textY + 3*lineH, col3W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(MathHelper.NumberToString(GetStationMapCollection().GetAveragePopulationCableShare()*100, 2)+"%", col4, textY + 3*lineH, col4W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)

		local statusText:string = GetLocale("AS_OF_DATEX").Replace("%DATEX%", GetWorldTime().GetFormattedGameDate(GetStationMapCollection().GetLastCensusTime()))
		statusText :+ ". " + GetLocale("NEXT_CENSUS_AT_DATEX").Replace("%DATEX%", GetWorldTime().GetFormattedGameDate(GetStationMapCollection().GetNextCensusTime()))
		skin.fontNormal.DrawBox("|i|"+statusText+"|/i|", contentArea.GetX() + 5, textY + 4*lineH, contentArea.GetIntW()- 10,  30, sALIGN_CENTER_CENTER, subHeaderColor, EDrawTextEffect.Emboss, 0.75)
		currentY :+ countryInformationHeight


		'=== LIST ===
		local sectionListContentW:int = sectionList.GetContentScreenRect().GetW()
		skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), sectionListHeight + sectionListHeaderHeight, "2")
		skin.fontNormal.DrawBox(GetLocale("STATIONMAP_SECTION_NAME"), contentArea.GetX() + 7, currentY, 0.45*sectionListContentW,  headerHeight, sALIGN_LEFT_CENTER, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(GetLocale("BROADCAST_PERMISSION_SHORT"), contentArea.GetX() + 7 + 5 + 0.4*sectionListContentW, currentY, 0.2*sectionListContentW,  headerHeight, sALIGN_LEFT_CENTER, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(GetLocale("IMAGE"), contentArea.GetX() + 6 + 0.6*sectionListContentW, currentY, 0.1*sectionListContentW,  headerHeight, sALIGN_LEFT_CENTER, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(GetLocale("POPULATION"), contentArea.GetX() + 11 + 0.65*sectionListContentW, currentY, 0.26*sectionListContentW,  headerHeight, sALIGN_RIGHT_CENTER, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		currentY :+ sectionListHeaderHeight

'		skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), sectionListHeight, "2")
		sectionList.Draw()
		currentY :+ sectionListHeight


		'=== SECTION DETAILS ===
		If selectedSection
			Local fontH:int = 16
			'col1W :- 30
			'col2  :- 30
			'col2W :+ 30
			Local iso:String = selectedSection.GetISO3166Code()
			Local titleText:String = GetLocale("MAP_COUNTRY_"+iso+"_LONG") + " (" + GetLocale("MAP_COUNTRY_"+iso+"_SHORT")+")"

			skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), 17, "1_top")
'			currentY :+ 2
			skin.fontSmallCaption.DrawBox(titleText, contentArea.GetX() + 5, currentY, contentArea.GetIntW() - 10,  20, sALIGN_CENTER_TOP, titleColor, EDrawTextEffect.Shadow, 0.2)
			currentY :+ 14 + 3
			skin.RenderContent(contentArea.GetIntX(), currentY, contentArea.GetIntW(), detailsH - 17, "1")

			textY = currentY

			local pressureGroups:string 'TVTPressureGroup.GetAsString(pgID).Split(",")
			local pressureGroupIndexes:int[] = TVTPressureGroup.GetIndexes(selectedSection.pressureGroups)
			if not pressureGroupIndexes then throw "ups"
			For local pgIndex:int = eachIn TVTPressureGroup.GetIndexes(selectedSection.pressureGroups)
				if pressureGroups
					pressureGroups :+ ", " + GetLocale("PRESSURE_GROUPS_"+ TVTPressureGroup.GetAsString( TVTPressureGroup.GetAtIndex(pgIndex) ))
				else
					pressureGroups :+ GetLocale("PRESSURE_GROUPS_"+ TVTPressureGroup.GetAsString( TVTPressureGroup.GetAtIndex(pgIndex) ))
				endif
			Next
			skin.fontSmallCaption.DrawBox(GetLocale("POPULATION")+":", col1, textY + 0*lineH, col1W,  fontH, sALIGN_LEFT_TOP, skin.textColorNeutral)
			skin.fontNormal.DrawBox(TFunctions.DottedValue(selectedSection.GetPopulation()), col2, textY + 0*lineH, col2W,  fontH, sALIGN_RIGHT_TOP, skin.textColorNeutral)

			local cableNetworkText:string
			if GetStationMapCollection().GetCableNetworksInSectionCount(selectedSection.name, True) > 0
				cableNetworkText:string = GetLocale("YES")
			else
				cableNetworkText:string = GetLocale("NO")
				rem
				local firstCableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetFirstCableNetworkBySectionName(selectedSection.name)
				if firstCableNetwork and firstCableNetwork.launchTime >= 0
					cableNetworkText = GetWorldTime().GetFormattedDate(firstCableNetwork.launchTime)
				else
					cableNetworkText = "-/-"
				endif
				endrem
			endif
			skin.fontSmallCaption.DrawBox(GetLocale("CABLE_NETWORK")+":", col1, textY + 1*lineH, col1W,  -1, sALIGN_LEFT_TOP, skin.textColorNeutral)
			skin.fontNormal.DrawBox(cableNetworkText, col2, textY + 1*lineH, col2W,  -1, sALIGN_RIGHT_TOP, skin.textColorNeutral)

			skin.fontNormal.DrawBox("|b|" + GetLocale("PRESSURE_GROUPS")+":|/b| " + pressureGroups, col1, textY + 2*lineH, col1W + col2W,  3*fontH, sALIGN_LEFT_TOP, skin.textColorNeutral, skin.textBlockDrawSettings.data)

			skin.fontSmallCaption.DrawBox(GetLocale("BROADCAST_PERMISSION")+":", col3, textY + 0*lineH, col3W+col4W, -1, sALIGN_LEFT_TOP, skin.textColorNeutral)
			skin.fontNormal.DrawBox(GetLocale("PRICE")+":", col3, textY + 1*lineH, col3W, -1, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.4)
			skin.fontNormal.DrawBox(GetFormattedCurrency(selectedSection.GetBroadcastPermissionPrice(owner)), col4, textY + 1*lineH, col4W, -1, sALIGN_RIGHT_TOP, skin.textColorNeutral)
			skin.fontNormal.DrawBox(GetLocale("CHANNEL_IMAGE")+":", col3, textY + 2*lineH, col3W,  -1, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.4)
			skin.fontNormal.DrawBox(GetLocale("MIN_VALUEX").Replace("%VALUEX%", MathHelper.NumberToString(selectedSection.broadcastPermissionMinimumChannelImage, 1, True)+"%"), col4, textY + 2*lineH, col4W,  -1, sALIGN_RIGHT_TOP, skin.textColorNeutral)
			if selectedSection.HasBroadcastPermission(owner)
				skin.fontNormal.DrawBox(getLocale("BROADCAST_PERMISSION_EXISTING"), col3, textY + 3*lineH, col3W+col4W, -1, sALIGN_LEFT_TOP, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
			else
				skin.fontNormal.DrawBox(getLocale("BROADCAST_PERMISSION_MISSING"), col3, textY + 3*lineH, col3W+col4W, -1, sALIGN_LEFT_TOP, subHeaderColor, EDrawTextEffect.Emboss, 0.5)
			endif
		EndIf


		skin.RenderBorder(area.GetIntX(), area.GetIntY(), area.GetIntW(), area.GetIntH())

		'debug
		Rem
		DrawRect(contentArea.GetX(), contentArea.GetIntY(), 20, contentArea.GetH() )
		Setcolor 255,0,0
		DrawRect(contentArea.GetX() + 10, contentArea.GetIntY(), 20, headerHeight )
		Setcolor 255,255,0
		DrawRect(contentArea.GetX() + 20, contentArea.GetIntY() + headerHeight, 20, sectionListHeight )
		Setcolor 255,0,255
		DrawRect(contentArea.GetX() + 30, contentArea.GetIntY() + headerHeight + listHeight, 20, detailsH )
		endrem

		For Local t:TTooltipBase = EachIn tooltips
			t.Render()
		Next
	End Method
End Type




Type TScreenHandler_StationMap
	Global guiAccordeon:TGUIAccordeon
	Global satelliteSelectionFrame:TSatelliteSelectionFrame
	Global mapInformationFrame:TStationMapInformationFrame

	Global actionMode:Int = 0
	Global actionConfirmed:Int = False
	
	Global antennaPanel:TGameGUIAntennaPanel

	Global mouseoverSection:TStationMapSection
	Global selectedStation:TStationBase
	Global mouseoverStation:TStationBase
	Global mouseoverStationPosition:TVec2D
	
	'indicator for each player (bitmask)
	Global stationMapChanged:int
	'mutex to protect indicator change and reaction to changes
	Global stationMapChangedMutex:TMutex = CreateMutex()


	Global guiShowStations:TGUICheckBox[4]
	Global guiFilterButtons:TGUICheckBox[3]
	Global guiInfoButton:TGUIButton
	Global mapBackgroundSpriteName:String = ""


	Global currentSubRoom:TRoomBase = Null
	Global lastSubRoom:TRoomBase = Null

	Global LS_stationmap:TLowerString = TLowerString.Create("stationmap")

	Global _eventListeners:TEventListenerBase[]

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
		If Not screen
			print "TScreenHandler_StationMap.Initialize(): FAILED. Screen not available"
			Return False
		EndIf

		'remove background from stationmap screen
		'(we draw the map and then the screen bg)
		If screen.backgroundSpriteName <> ""
			mapBackgroundSpriteName = screen.backgroundSpriteName
			screen.backgroundSpriteName = ""
		EndIf

		'=== create gui elements if not done yet
		If Not guiInfoButton
			guiAccordeon = New TGameGUIAccordeon.Create(New SVec2I(586, 64), New SVec2I(211, 317), "", "STATIONMAP")
			TGameGUIAccordeon(guiAccordeon).skinName = "stationmapPanel"

			antennaPanel = New TGameGUIAntennaPanel.Create(New SVec2I(-1, -1), New SVec2I(-1, -1), "Stations", "STATIONMAP")
			antennaPanel.Open()
			guiAccordeon.AddPanel(antennaPanel, 0)
			Local p:TGUIAccordeonPanel
			p = New TGameGUICableNetworkPanel.Create(New SVec2I(-1, -1), New SVec2I(-1, -1), "Cable Networks", "STATIONMAP")
			guiAccordeon.AddPanel(p, 1)
			p = New TGameGUISatellitePanel.Create(New SVec2I(-1, -1), New SVec2I(-1, -1), "Satellites", "STATIONMAP")
			guiAccordeon.AddPanel(p, 2)


			'== info panel
			guiInfoButton = New TGUIButton.Create(New SVec2I(610, 15), New SVec2I(20, 28), "", "STATIONMAP")

			guiInfoButton.SetSpriteName("gfx_gui_button.datasheet")
			guiInfoButton.SetTooltip( New TGUITooltipBase.Initialize(GetLocale("SHOW_MAP_DETAILS"), GetLocale("CLICK_TO_SHOW_ADVANCED_MAP_INFORMATION"), New TRectangle.Init(0,0,-1,-1)) )
			guiInfoButton.GetTooltip()._minContentDim = New TVec2D(120,-1)
			guiInfoButton.GetTooltip()._maxContentDim = New TVec2D(150,-1)
			guiInfoButton.GetTooltip().SetOrientationPreset("LEFT", 10)

			For Local i:Int = 0 Until guiFilterButtons.length
				guiFilterButtons[i] = New TGUICheckBox.Create(New SVec2I(695 + i*23, 30 ), New SVec2I(20, 20), String(i + 1), "STATIONMAP")
				guiFilterButtons[i].ShowCaption(False)
				guiFilterButtons[i].data.AddNumber("stationType", i+1)
				'guiFilterButtons[i].SetUnCheckedTintColor( TColor.Create(255,255,255) )
				guiFilterButtons[i].SetUnCheckedTintColor( TColor.Create(210,210,210, 0.75) )
				guiFilterButtons[i].SetCheckedTintColor( TColor.Create(245,255,240) )

				guiFilterButtons[i].uncheckedSpriteName = "gfx_datasheet_icon_" + TVTStationType.GetAsString(i+1) + ".off"
				guiFilterButtons[i].checkedSpriteName = "gfx_datasheet_icon_" + TVTStationType.GetAsString(i+1) + ".on"

				guiFilterbuttons[i].SetTooltip( New TGUITooltipBase.Initialize("", GetLocale("TOGGLE_DISPLAY_OF_STATIONTYPE").Replace("%STATIONTYPE%", GetLocale(TVTStationType.GetAsString(i+1)+"S")), New TRectangle.Init(0,60,-1,-1)) )
				guiFilterbuttons[i].GetTooltip()._minContentDim = New TVec2D(80,-1)
				guiFilterbuttons[i].GetTooltip()._maxContentDim = New TVec2D(150,-1)
				guiFilterbuttons[i].GetTooltip().SetOrientationPreset("LEFT", 5)
			Next


			For Local i:Int = 0 To 3
				guiShowStations[i] = New TGUICheckBox.Create(New SVec2I(695 + i*23, 30 ), New SVec2I(20, 20), String(i + 1), "STATIONMAP")
				guiShowStations[i].ShowCaption(False)
				guiShowStations[i].data.AddNumber("playerNumber", i+1)

				guiShowStations[i].SetTooltip( New TGUITooltipBase.Initialize("", GetLocale("TOGGLE_DISPLAY_OF_PLAYER_X").Replace("%X%", i+1), New TRectangle.Init(0,60,-1,-1)) )
				guiShowStations[i].GetTooltip()._minContentDim = New TVec2D(80,-1)
				guiShowStations[i].GetTooltip()._maxContentDim = New TVec2D(120,-1)
				guiShowStations[i].GetTooltip().SetOrientationPreset("LEFT", 5)
			Next

			satelliteSelectionFrame = New TSatelliteSelectionFrame
			mapInformationFrame = New TStationMapInformationFrame
		EndIf


		'=== reset gui element options to their defaults
		For Local i:Int = 0 Until guiShowStations.length
			guiShowStations[i].SetChecked( True, False)
		Next
		For Local i:Int = 0 Until guiFilterButtons.length
			guiFilterButtons[i].SetChecked( True, False)
		Next


		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]


		'=== register event listeners
		'unset "selected station" when other panels get opened
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIAccordeon_OnOpenPanel, OnOpenOrCloseAccordeonPanel, guiAccordeon) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIAccordeon_OnClosePanel, OnOpenOrCloseAccordeonPanel, guiAccordeon) ]

		'mark the player's stationmap as "changed" when stations are
		'added, removed, activated or shutdown
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_RemoveStation, OnChangeStationMapStation) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.StationMap_AddStation, OnChangeStationMapStation) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_SetActive, OnChangeStation) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_SetInactive, OnChangeStation) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_OnShutDown, OnChangeStation) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_OnResume, OnChangeStation) ]

		'player enters station map screen - set checkboxes according to station map config
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterStationMapScreen, screen) ]

		'register checkbox changes
		For Local i:Int = 0 Until guiShowStations.length
			_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUICheckbox_OnSetChecked, OnSetChecked_StationMapFilters, guiShowStations[i]) ]
		Next
		For Local i:Int = 0 Until guiFilterButtons.length
			_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUICheckbox_OnSetChecked, OnSetChecked_StationMapFilters, guiFilterButtons[i]) ]
		Next

		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, OnClickInfoButton, guiInfoButton) ]

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
		If mapInformationFrame Then mapInformationFrame.SetLanguage()
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
		guiInfoButton.SetSize(25, -1)
		guiInfoButton.SetPosition(contentX + 5, contentY)
		buttonX :+ guiInfoButton.rect.GetW() + 6

		For Local i:Int = 0 Until guiFilterButtons.length
			guiFilterButtons[i].SetPosition(buttonX, contentY + ((guiInfoButton.rect.GetH() - guiFilterButtons[i].rect.GetH())/2) )
			buttonX :+ guiFilterButtons[i].rect.GetW()
		Next

		For Local i:Int = 0 Until guiShowStations.length
			guiShowStations[i].SetPosition(contentX + 8 + 50+15+30 + 21*i, contentY + ((guiInfoButton.rect.GetH() - guiShowStations[i].rect.GetH())/2) )
		Next
		contentY :+ buttonAreaPaddingY


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function


 	Function onDrawStationMap:Int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		Local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		SetBlend AlphaBlend
		'draw map
		'SetColor 255,255,255
		'SetAlpha 1.0
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
			Local oldCol:SColor8; GetColor(oldCol)
			Local oldColA:Float = GetAlpha()

			Local foundNoPermissionSections:Int = 0
			For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
				If Not section.HasBroadcastPermission(room.owner)
					SetColor( 225,175,50 )
					SetAlpha( 0.40 * oldColA )
					DrawImage(section.GetDisabledOverlay(), section.rect.GetX(), section.rect.GetY())
					'SetAlpha 0.25 * oldCol.a
					'section.GetHighlightBorderSprite().Draw(section.rect.GetX(), section.rect.GetY())

					foundNoPermissionSections :+ 1
				EndIf
			Next
			SetColor( oldCol )
			SetAlpha( oldColA )

			'draw normal ones on top - but only if needed
			'this is done to avoid "available sections" to get hidden
			If foundNoPermissionSections > 0
				For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
					If section.HasBroadcastPermission(room.owner)
						DrawImage(section.GetEnabledOverlay(), section.rect.GetX(), section.rect.GetY())
					EndIf
				Next
			EndIf
		EndIf

		'when selecting a station position with the mouse or a
		'cable network or a satellite
		If actionMode = MODE_BUY_ANTENNA Or actionMode = MODE_BUY_SATELLITE_UPLINK Or actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
			Local oldCol:SColor8; GetColor(oldCol)
			Local oldColA:Float = GetAlpha()
			SetAlpha oldColA * Float(0.7 + 0.2 * Sin(MilliSecs()/6))
			SetColor 225, 75, 0
			Local populationDensityOverlayXY:SVec2I = GetStationMapCollection().GetPopulationDensityOverlayXY()
			DrawImage(GetStationMapCollection().GetPopulationDensityOverlay(), populationDensityOverlayXY.x, populationDensityOverlayXY.y)
			SetColor(oldCol)
			SetAlpha oldColA
		EndIf



		'overlay with alpha channel screen
		GetSpriteFromRegistry(mapBackgroundSpriteName).Draw(0,0)


		_DrawStationMapInfoPanel(586, 7, room)

		'debug draw station map sections
		'TStationMapSection.DrawAll()

		'backgrounds
		If mouseoverStation And mouseoverStationPosition And mouseoverStation = selectedStation
			'avoid drawing it two times...
			mouseoverStation.DrawBackground(True, True)
		Else
			'also draw the station used for buying/searching
			If mouseoverStation And mouseoverStationPosition Then mouseoverStation.DrawBackground(False, True)
			'also draw the station used for buying/searching
			If selectedStation Then selectedStation.DrawBackground(True, False)
		EndIf


		'draw stations and tooltips
		GetStationMap(room.owner).Draw()

		'also draw the station used for buying/searching
		If mouseoverStation and mouseoverStationPosition Then mouseoverStation.Draw()
		'also draw the station used for buying/searching
		If selectedStation Then selectedStation.Draw(True)


		if mouseoverStation And mouseoverStationPosition ' or selectedStation
			GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)

			If actionMode = MODE_BUY_ANTENNA
				GetGameBase().SetCursorAlpha(0.4)
			EndIf

			If actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
				if mouseoverStation.HasFlag(TVTStationFlag.PAID)
					GetGameBase().SetCursor(TGameBase.CURSOR_STOP, TGameBase.CURSOR_EXTRA_FORBIDDEN)
				EndIf
			EndIf
		endif


		'draw activation tooltip for all other stations
		'- only draw them while NOT placing a new one (to ease spot finding)
		If actionMode <> MODE_BUY_ANTENNA And actionMode <> MODE_BUY_SATELLITE_UPLINK And actionMode <> MODE_BUY_CABLE_NETWORK_UPLINK
			For Local station:TStationBase = EachIn GetStationMap(room.owner).Stations
				If mouseoverStation = station Then Continue
				If station.IsActive() Then Continue

				station.DrawActivationTooltip()
			Next
		EndIf

		If mapInformationFrame.IsOpen()
			mapInformationFrame.Draw()
		EndIf


		GUIManager.Draw( LS_stationmap )

		For Local i:Int = 0 To 3
			Local playerColor:TColor = GetPlayerBase(i+1).color
			'replace and recalc colors if playerColor differs
			if not playerColor.isSame(guiShowStations[i].checkedTintColor)
				guiShowStations[i].SetCheckedTintColor( playerColor, False ) '.Copy().AdjustBrightness(0.25)
				guiShowStations[i].SetUncheckedTintColor( playerColor.Copy().AdjustBrightness(+0.25).AdjustSaturation(-0.35), False)
				'guiShowStations[i].tintColor = GetPlayerBase(i+1).color '.Copy().AdjustBrightness(0.25)
			EndIf
		Next

		'draw a kind of tooltip over a mouseoverStation
		If mouseoverStation And mouseoverStationPosition
			mouseoverStation.DrawInfoTooltip()
		else
			'if over a section, draw special tooltip displaying reasons
			'why we cannot build there
			If mouseoverSection and currentSubRoom
				if actionMode = MODE_BUY_ANTENNA
					mouseoverSection.DrawChannelStatusTooltip(currentSubRoom.owner, TVTStationType.ANTENNA )
				elseif actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
					mouseoverSection.DrawChannelStatusTooltip(currentSubRoom.owner, TVTStationType.CABLE_NETWORK_UPLINK )
				endif
			EndIf
		EndIf


		'draw satellite selection frame
'		if actionMode = MODE_BUY_SATELLITE_UPLINK
			If satelliteSelectionFrame.IsOpen()
				satelliteSelectionFrame.Draw()
				satelliteSelectionFrame.DrawTooltips()
			EndIf
'		endif


		if TVTDebugInfo
			SetAlpha 0.5
			SetColor 0,0,0
			DrawRect(0,25, 200, 55)
			SetColor 255,255,255
			SetAlpha 1.0
			DrawText(GetStationMapCollection().nextCensusTime, 30,30)
			DrawText("census: " + GetWorldTime().GetFormattedGameDate(GetStationMapCollection().nextCensusTime), 30,45)
			DrawText("now   : " + GetWorldTime().GetFormattedGameDate(), 30,60)
		endif
	End Function
	

	Function Navigate:Int(key:Int, xDelta:Int, yDelta:Int)
		If KEYMANAGER.IsDown(key)
			'MoveMouse(MouseManager.evMousePosX+xDelta, MouseManager.evMousePosY+yDelta)
			GetGraphicsManager().DesignedMoveMouseBy(xDelta, yDelta)
			KEYMANAGER.blockKey(key, 100)
			Return True
		EndIf
		Return False
	End Function
	
	
	Function ReactToStationMapChanges()
		If Not currentSubRoom Then Return
		
		LockMutex(stationMapChangedMutex)
		
		'if we do not own the selected station anymore, action mode
		'has to be reset (so remove "selection")
		If TScreenHandler_StationMap.selectedStation
			If TScreenHandler_StationMap.selectedStation.owner <= 0
				TScreenHandler_StationMap.ResetActionMode(0)
			EndIf
		EndIf

		Local ownerFlag:Int = (1 Shl (currentSubRoom.owner-1))
		If stationMapChanged & ownerFlag 
			'refresh panels if player is currently looking at a changed
			'stationmap
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList( currentSubRoom.owner )
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(1)).RefreshList( currentSubRoom.owner )
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(2)).RefreshList( currentSubRoom.owner )

			'remove owner from changed state
			stationMapChanged :& ~ ownerFlag
		EndIf
		
		UnlockMutex(stationMapChangedMutex)
	End Function
	

	Function onUpdateStationMap:Int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		Local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		'backup room if it changed
		Local changedSubRoom:int
		If currentSubRoom <> lastSubRoom
			lastSubRoom = currentSubRoom
			changedSubRoom = True
		EndIf
		currentSubRoom = room

		'if stationmap changed or we changed the room meanwhile
		'then we have to rebuild the stationList and potentially remove
		'selections in lists
		If changedSubRoom or stationMapChanged
			ReactToStationMapChanges()
		EndIf


		GetStationMap(room.owner).Update()

		'process right click
		If MOUSEMANAGER.isClicked(2)
			Local reset:Int = (selectedStation Or mouseoverStation Or satelliteSelectionFrame.IsOpen() or mapInformationFrame.IsOpen())

			If mapInformationFrame.IsOpen()
				if mapInformationFrame.selectedSection
					mapInformationFrame.SelectSection(Null)
					reset = True
				else
					mapInformationFrame.Close()
					reset = True
				endif
			EndIf

			if satelliteSelectionFrame.IsOpen()
				'reassigning to an empty one?
				if selectedStation 'and selectedStation.IsShutDown()
					ResetActionMode(0)
					satelliteSelectionFrame.SelectSatellite(null)
					satelliteSelectionFrame.Close()
				else
					ResetActionMode(0)
				endif
				reset = True
			else
				if TScreenHandler_StationMap.actionMode <> TScreenHandler_StationMap.MODE_NONE
					ResetActionMode(0)
					reset = True
				endif
			endif

			If reset
				'avoid clicks
				'remove right click - to avoid leaving the room
				MouseManager.SetClickHandled(2)
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
				GetGameBase().SetCursor(TGameBase.CURSOR_STOP)
				print "invalid"
			endif
		endif
endrem

		Local mouseDataX:Int = GetStationMapCollection().mapInfo.ScreenXToDataX(MouseManager.x)
		Local mouseDataY:Int = GetStationMapCollection().mapInfo.ScreenYToDataY(MouseManager.y)

		'buying stations using the mouse
		'1. searching
		GetCurrentPlayer().setHotKeysEnabled(True)
		If actionMode = MODE_BUY_ANTENNA
			GetCurrentPlayer().setHotKeysEnabled(False)
			Navigate(KEY_UP, 0, -1)
			Navigate(KEY_DOWN, 0, 1) 
			Navigate(KEY_LEFT, -1, 0)
			Navigate(KEY_RIGHT, 1, 0)

			'create a temporary station if not done yet
			If Not mouseoverStation
				Local mapInfo:TStationMapInfo = GetStationMapCollection().mapInfo
				Local dataX:Int = mapInfo.ScreenXToDataX(MouseManager.x)
				Local dataY:Int = mapInfo.ScreenYToDataY(MouseManager.y)
				mouseoverStation = New TStationAntenna.Init(New SVec2I(dataX, dataY), room.owner)
			EndIf

			if not mouseoverStationPosition Then mouseoverStationPosition = New TVec2D
			mouseoverStationPosition.SetXY(MouseManager.x, MouseManager.y)

			'if the mouse has moved - refresh the station data and move station
			If mouseDataX <> mouseoverStation.x or mouseDataY <> mouseoverStation.y
				mouseoverStation.SetPosition(mouseDataX, mouseDataY)

				'refresh state information
				mouseoverStation.GetSectionName()
			EndIf

			Local hoveredMapSection:TStationMapSection
			If mouseoverStation Then hoveredMapSection = GetStationMapCollection().GetSectionByDataXY(mouseoverStation.x, mouseoverStation.y)

			'if mouse gets clicked, we store that position in a separate station
			If MOUSEMANAGER.isClicked(1) OR KEYMANAGER.IsHit(KEY_SPACE)
				'check reach and valid federal state
				If hoveredMapSection And mouseoverStation.GetReceivers() > 0
					selectedStation = New TStationAntenna.Init(New SVec2I(mouseoverStation.x, mouseoverStation.y), room.owner)

					'handled left click
					MouseManager.SetClickHandled(1)
				EndIf
			EndIf

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			If Not hoveredMapSection Or mouseoverStation.GetReceivers() <= 0
				'mouseoverStation = Null
				mouseoverStationPosition = Null
			EndIf

			If selectedStation
				Local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSectionByDataXY(selectedStation.x, selectedStation.y)

				If Not selectedMapSection Or selectedStation.GetReceivers() <= 0 Then selectedStation = Null
			EndIf

		ElseIf actionMode = MODE_BUY_CABLE_NETWORK_UPLINK
			'if the mouse has moved or nothing was created yet
			'refresh the station data and move station
			If Not mouseoverStation Or Not mouseoverStationPosition Or mouseDataX <> mouseoverStation.x or mouseDataY <> mouseoverStation.y
				mouseoverSection = GetStationMapCollection().GetSectionByDataXY(mouseDataX, mouseDataY)
				If mouseoverSection
					Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetFirstCableNetworkBySectionName(mouseoverSection.name)
					If cableNetwork And cableNetwork.IsLaunched()
						mouseoverStationPosition = MouseManager.GetPosition().Copy()
						
						mouseoverStation = Null
						
						'do we already have one?
						For local station:TStationCableNetworkUplink = EachIn GetStationMap(room.owner).stations
							if station.providerID = cableNetwork.getID()
								mouseoverStation = station
								exit
							endif
						Next
						if not mouseoverStation
							mouseoverStation = New TStationCableNetworkUplink.Init(cableNetwork, room.owner, True)
						endif
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
				hoveredMapSection = GetStationMapCollection().GetSectionByDataXY(mouseDataX, mouseDataY)
			EndIf

			'if mouse gets clicked, we store that position in a separate station
			If MOUSEMANAGER.isClicked(1)
				'check reach and valid federal state
				If hoveredMapSection And mouseoverStation.GetReceivers() > 0
					Local cableNetwork:TStationMap_CableNetwork = GetStationMapCollection().GetCableNetwork(mouseOverStation.providerID)
					selectedStation = New TStationCableNetworkUplink.Init(cableNetwork, room.owner, True)
					If selectedStation
						'handled left click
						MouseManager.SetClickHandled(1)
					EndIf
				EndIf
			EndIf

			'no antennagraphic in foreign countries
			'-> remove the station so it wont get displayed
			If Not hoveredMapSection Or mouseoverStation.GetReceivers() <= 0
				mouseoverStation = Null
				mouseoverStationPosition = Null
			EndIf

			If selectedStation
				Local selectedMapSection:TStationMapSection = GetStationMapCollection().GetSectionByDataXY(selectedStation.x, selectedStation.y)

				If Not selectedMapSection Or selectedStation.GetReceivers() <= 0 Then selectedStation = Null
			EndIf

		ElseIf actionMode = MODE_BUY_SATELLITE_UPLINK
			If satelliteSelectionFrame.selectedSatellite
				Local satLink:TStationSatelliteUplink = TStationSatelliteUplink(selectedStation)
				'only create a temporary sat link station if a satellite was
				'selected
				If satelliteSelectionFrame.selectedSatellite
					If Not satLink Or satLink.providerID <> satelliteSelectionFrame.selectedSatellite.GetID()
						selectedStation = new TStationSatelliteUplink.Init(satelliteSelectionFrame.selectedSatellite, room.owner, True)
					EndIf
				EndIf
			EndIf
		EndIf


		'select an antenna by mouse?
		If actionMode = 0 or actionMode = MODE_SELL_ANTENNA
			If MouseManager.IsClicked(1)
				Local mouseDataX:Int = GetStationMapCollection().mapInfo.ScreenXToDataX(int(MouseManager.GetClickPosition(1).x))
				Local mouseDataY:Int = GetStationMapCollection().mapInfo.ScreenYToDataY(int(MouseManager.GetClickPosition(1).y))
			
				local antenna:TStationAntenna = GetStationMap(room.owner).GetAntennaByXY(mouseDataX, mouseDataY, False)
				if antenna
					'make sure antenna panel is open
					antennaPanel.Open()
					guiAccordeon.UpdateLayout()
					antennaPanel.UpdateLayout()

					antennaPanel.SetSelectedStation(antenna)
					selectAndReveal(antenna)

					MouseManager.SetClickHandled(1)
				endif
			EndIf
		EndIf


		'select satellite of the currently selected satlink
		If TStationSatelliteUplink(selectedStation)
			Local satLink:TStationSatelliteUplink = TStationSatelliteUplink(selectedStation)
			Local satellite:TStationMap_Satellite = GetStationMapCollection().GetSatellite( satLink.providerID )
			If satellite <> satelliteSelectionFrame.selectedSatellite
				if not satLink.IsShutDown() and satLink.providerID
					satelliteSelectionFrame.SelectSatellite( satellite )
				endif
			EndIf
		EndIf


		'no info screen while something is selected
		if selectedStation
			if TScreenHandler_StationMap.mapInformationFrame.IsOpen() Then TScreenHandler_StationMap.mapInformationFrame.Close()
		endif
		
		If mapInformationFrame.IsOpen()
			'no interaction
			'if actionMode <> MODE_NONE Then ResetActionMode(MODE_NONE)

			mapInformationFrame.Update()
		EndIf


		If satelliteSelectionFrame.IsOpen()
			satelliteSelectionFrame.Update()
		EndIf


		GUIManager.Update( LS_stationmap )
	End Function

	Function selectAndReveal:Int(station:TStationBase)
		For Local listItem:TGUISelectListItem = EachIn antennaPanel.list.entries
			If listItem.data.get("station") = station
				antennaPanel.list.ScrollAndSelectItem(listItem)
				Return True
			EndIf
		Next
		Return False
	End Function

	Function OnOpenOrCloseAccordeonPanel:Int( triggerEvent:TEventBase )
		Local accordeon:TGameGUIAccordeon = TGameGUIAccordeon(triggerEvent.GetSender())
		If Not accordeon Or accordeon <> guiAccordeon Then Return False

		Local panel:TGameGUIAccordeonPanel = TGameGUIAccordeonPanel(triggerEvent.GetData().Get("panel"))

		If triggerEvent.GetEventKey() = GUIEventKeys.GUIAccordeon_OnClosePanel
			if mapInformationFrame.IsOpen()
				mapInformationFrame.Close()
			endif

			ResetActionMode(TScreenHandler_StationMap.MODE_NONE)
		EndIf
	End Function


	Function OnChangeStationMapStation:Int( triggerEvent:TEventBase )
		'do nothing when not in a room
		If Not currentSubRoom Then Return False
	
		Local station:TStationBase = TStationBase(triggerEvent.GetData().Get("station"))
		If station and station.owner > 0 and GetPlayer(station.owner)
			'mark stationmap of player/owner as changed
			LockMutex(stationMapChangedMutex)
			stationMapChanged :| (1 Shl (station.owner-1))
			UnLockMutex(stationMapChangedMutex)
		EndIf
	End Function


	Function OnChangeStation:Int( triggerEvent:TEventBase )
		'do nothing when not in a room
		If Not currentSubRoom Then Return False

		Local station:TStationBase = TStationBase(triggerEvent.GetSender())
		If Not station Then Return False

		If station and station.owner > 0 and GetPlayer(station.owner)
			'mark stationmap of player/owner as changed
			LockMutex(stationMapChangedMutex)
			stationMapChanged :| (1 Shl (station.owner-1))
			UnLockMutex(stationMapChangedMutex)
		EndIf
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

	Function OnClickInfoButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not button Then Return False

		ResetActionMode(0)

		if mapInformationFrame then mapInformationFrame.Open()
	End Function


	'custom drawing function for list entries
	Function DrawMapStationListEntryContent:Int(obj:TGUIObject)
		Local item:TGUISelectListItem = TGUISelectListItem(obj)
		If Not item Then Return False

		Local station:TStationBase = TStationBase(item.data.Get("station"))
		If Not station Then Return False

		Local sprite:TSprite
		If station.CanBroadcast()
			sprite = GetSpriteFromRegistry(station.listSpriteNameOn)
		Else
			sprite = GetSpriteFromRegistry(station.listSpriteNameOff)
		EndIf

		Local rightValue:String = TFunctions.convertValue(station.GetReceivers(), 2, 0)
		Local paddingLR:Int = 2
		Local textOffsetX:Int = paddingLR + sprite.GetWidth() + 5
		Local textOffsetY:Int = 1
		Local textW:Int = item.GetScreenRect().GetW() - textOffsetX - paddingLR - 1 '-1 looks better

		Local currentAlpha:Float = GetAlpha()
		Local entryColor:SColor8
		Local rightValueColor:SColor8
		Local leftValue:string = item.GetValue()
		Local midValue:String
		If TStationAntenna(station)
			leftValue = station.GetName() 'not LongName()!
			midValue = "("+GetLocale("MAP_COUNTRY_" + station.GetSectionISO3166Code() + "_SHORT") + ")"
		EndIf

		'draw with different color according status
		If station.CanBroadcast()
			'colorize antenna for "not sellable ones
			If Not station.HasFlag(TVTStationFlag.SELLABLE)
				entryColor = new SColor8(130,80,50, int(currentAlpha * 255))
				rightValueColor = entryColor
			Else
				entryColor = new SColor8(item.valueColor.r, item.valueColor.g, item.valueColor.b, int(currentAlpha * 255))
				rightValueColor = entryColor
			EndIf
		Else If station.IsShutdown()
			entryColor = new SColor8(90,90,60, int(currentAlpha * 255))
			leftValue = GetLocale("UNUSED_TRANSMITTER")
			if TStationSatelliteUplink(station) and not TStationSatelliteUplink(station).providerID
				rightValue = ""
			endif
			'leftValue = "|color="+(150 + 50*Sin(Millisecs()*0.5))+",90,90|!!|/color| " + leftValue
			rightValueColor = entryColor
		Else
			entryColor = SColor8AdjustFactor(item.valueColor, 50)
			entryColor = new SColor8(entryColor.r, entryColor.g, entryColor.b, int(255 * currentAlpha * 0.5))
			rightValueColor = entryColor
		EndIf

		'blink a bit to emphasize a soon ending contract
		local subTimeLeft:Long = station.GetSubscriptionTimeLeft()
		if subTimeLeft > 0 and subTimeLeft < 1*TWorldTime.DAYLENGTH
			entryColor = new SColor8(130,100,50, int(255 * (currentAlpha * (0.65 + 0.35 * sin(Millisecs()*0.33)))))
			rightValueColor = entryColor
		endif

		'draw antenna
		sprite.Draw(Int(item.GetScreenRect().GetX() + paddingLR), item.GetScreenRect().GetY() + 0.5*item.rect.getH(), -1, ALIGN_LEFT_CENTER)
		Local rightValueWidth:Int = item.GetFont().GetWidth(rightValue)
		Local dim:SVec2I = item.GetFont().DrawBox(leftValue, Int(item.GetScreenRect().GetX() + textOffsetX), Int(item.GetScreenRect().GetY() + textOffsetY), textW - rightValueWidth - 5, Int(item.GetScreenRect().GetH() - textOffsetY), sALIGN_LEFT_CENTER, entryColor)
		If midValue
			item.GetFont().DrawBox(midValue, Int(item.GetScreenRect().GetX() + textOffsetX) + (max(30, dim.x + 5)), Int(item.GetScreenRect().GetY() + textOffsetY), textW - rightValueWidth - 5, Int(item.GetScreenRect().GetH() - textOffsetY), sALIGN_LEFT_CENTER, entryColor)
		EndIf
		item.GetFont().DrawBox(rightValue, Int(item.GetScreenRect().GetX() + textOffsetX), Int(item.GetScreenRect().GetY() + textOffsetY), textW, Int(item.GetScreenRect().GetH() - textOffsetY), sALIGN_RIGHT_CENTER, rightValueColor)
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

		For Local i:Int = 0 To 2
			Local show:Int = GetStationMap(owner).GetShowStationType(i+1)
			guiFilterButtons[i].SetChecked(show)
		Next

		'rebuild the stationLists
		if guiAccordeon.GetPanelAtIndex(0)
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(0)).RefreshList(owner)
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(1)).RefreshList(owner)
			TGameGUIBasicStationmapPanel(guiAccordeon.GetPanelAtIndex(2)).RefreshList(owner)
		endif
		if TScreenHandler_StationMap.mapInformationFrame
			TScreenHandler_StationMap.mapInformationFrame.RefreshSectionList()
		endif
	End Function


	Function OnSetChecked_StationMapFilters:Int(triggerEvent:TEventBase)
		Local button:TGUICheckBox = TGUICheckBox(triggerEvent._sender)
		If Not button Then Return False

		If Not currentSubRoom or not GetPlayerBaseCollection().IsPlayer(currentSubRoom.owner) Then Return False

		'player filter
		Local player:Int = button.data.GetInt("playerNumber", -1)
		If player >= 0
			If Not GetPlayerCollection().IsPlayer(player) Then Return False

			'only set if not done already
			If GetStationMap(currentSubRoom.owner).GetShowStation(player) <> button.isChecked()
				TLogger.Log("StationMap", "Stationmap #"+currentSubRoom.owner+" show stations for player "+player+": "+button.isChecked(), LOG_DEBUG)
				GetStationMap(currentSubRoom.owner).SetShowStation(player, button.isChecked())
			EndIf
		EndIf

		'station type filter
		Local stationType:Int = button.data.GetInt("stationType", -1)
		If stationType >= 0
			'only set if not done already
			If GetStationMap(currentSubRoom.owner).GetShowStationType(stationType) <> button.isChecked()
				TLogger.Log("StationMap", "Stationmap #"+currentSubRoom.owner+" show station type "+stationType+": "+button.isChecked(), LOG_DEBUG)
				GetStationMap(currentSubRoom.owner).SetShowStationType(stationType, button.isChecked())
			EndIf
		EndIf
	End Function
End Type
