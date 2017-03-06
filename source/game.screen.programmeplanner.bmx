SuperStrict
Import "Dig/base.gfx.gui.button.bmx"
import "common.misc.plannerlist.contractlist.bmx"
import "common.misc.plannerlist.programmelist.bmx"
import "common.misc.screen.bmx"
import "game.room.base.bmx"
import "game.roomhandler.base.bmx"
import "game.player.bmx"




Type TScreenHandler_ProgrammePlanner
	Global showPlannerShortCutHintTime:Int = 0
	Global showPlannerShortCutHintFadeAmount:Int = 1
	Global planningDay:Int = -1
	Global talkToProgrammePlanner:Int = True		'set to FALSE for deleting gui objects without modifying the plan
	Global DrawnOnProgrammePlannerBG:Int = 0
	Global ProgrammePlannerButtons:TGUIButton[6]
	Global PPprogrammeList:TgfxProgrammelist
	Global PPcontractList:TgfxContractlist
	Global overlayedAdSlots:Int[24]
	Global overlayedProgrammeSlots:Int[24]
	Global fastNavigateTimer:TIntervalTimer = TIntervalTimer.Create(250)
	Global fastNavigateInitialTimer:Int = 250
	Global fastNavigationUsedContinuously:Int = False
	Global plannerNextDayButton:TGUIButton
	Global plannerPreviousDayButton:TGUIButton
	Global openedProgrammeListThisVisit:Int = False
	Global currentRoom:TRoomBase
	'indicator whether an item just got dropped and therefor the next
	'check should ignore "shift/ctrl"-shortcuts
	Global ignoreCopyOrEpisodeShortcut:Int = False

	Global hoveredGuiProgrammePlanElement:TGuiProgrammePlanElement = Null
	Global draggedGuiProgrammePlanElement:TGuiProgrammePlanElement = Null
	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:Int = True
	Global GuiListProgrammes:TGUIProgrammePlanSlotList
	Global GuiListAdvertisements:TGUIProgrammePlanSlotList

	Global LS_programmeplanner:TLowerString = TLowerString.Create("programmeplanner")
	Global LS_programmeplanner_buttons:TLowerString = TLowerString.Create("programmeplanner_buttons")
	Global LS_programmeplanner_and_programmeplanner_buttons:TLowerString = TLowerString.Create("programmeplanner|programmeplanner_buttons")

	Global _eventListeners:TLink[]
	Global screenName:string = "screen_office_programmeplanner"
	Global programmePlannerBackgroundOriginal:TImage


	Function Initialize:Int()
		Local screen:TScreen = ScreenCollection.GetScreen(screenName)
		If Not screen Then Return False
		


		'=== create gui elements if not done yet
		If GuiListProgrammes
			'clear gui lists etc
			RemoveAllGuiElements(True)
			hoveredGuiProgrammePlanElement = Null
			draggedGuiProgrammePlanElement = Null
		Else
			'=== create programme/ad-slot lists
			'the visual gap between 0-11 and 12-23 hour
			Local gapBetweenHours:Int = 45
			Local area:TRectangle = New TRectangle.Init(45,5,625,12 * GetSpriteFromRegistry("pp_programmeblock1").area.GetH())

			GuiListProgrammes = New TGUIProgrammePlanSlotList.Create(area.position, area.dimension, "programmeplanner")
			GuiListProgrammes.Init("pp_programmeblock1", Int(GetSpriteFromRegistry("pp_adblock1").area.GetW() + gapBetweenHours))
			GuiListProgrammes.isType = TVTBroadcastMaterialType.PROGRAMME

			GuiListAdvertisements = New TGUIProgrammePlanSlotList.Create(New TVec2D.Init(area.GetX() + GetSpriteFromRegistry("pp_programmeblock1").area.GetW(), area.GetY()), area.dimension, "programmeplanner")
			GuiListAdvertisements.Init("pp_adblock1", Int(GetSpriteFromRegistry("pp_programmeblock1").area.GetW() + gapBetweenHours))
			GuiListAdvertisements.isType = TVTBroadcastMaterialType.ADVERTISEMENT


			'=== create programme/contract lists
			PPprogrammeList	= New TgfxProgrammelist.Create(669, 8)
			PPcontractList = New TgfxContractlist.Create(669, 8)


			'=== create buttons
			plannerNextDayButton = New TGUIButton.Create(New TVec2D.Init(768, 6), New TVec2D.Init(28, 28), ">", "programmeplanner_buttons")
			plannerNextDayButton.spriteName = "gfx_gui_button.datasheet"

			plannerPreviousDayButton = New TGUIButton.Create(New TVec2D.Init(684, 6), New TVec2D.Init(28, 28), "<", "programmeplanner_buttons")
			plannerPreviousDayButton.spriteName = "gfx_gui_button.datasheet"

			'so we can handle clicks to the daychange-buttons while some
			'programmeplan elements are dragged
			'ATTENTION: this makes the button drop-targets, so take care of
			'vetoing try-drop-events
			plannerNextDayButton.SetOption(GUI_OBJECT_ACCEPTS_DROP)
			plannerPreviousDayButton.SetOption(GUI_OBJECT_ACCEPTS_DROP)


			ProgrammePlannerButtons[0] = New TGUIButton.Create(New TVec2D.Init(686, 41 + 0*54), Null, GetLocale("PLANNER_ADS"), "programmeplanner_buttons")
			ProgrammePlannerButtons[0].spriteName = "gfx_programmeplanner_btn_ads"

			ProgrammePlannerButtons[1] = New TGUIButton.Create(New TVec2D.Init(686, 41 + 1*54), Null, GetLocale("PLANNER_PROGRAMME"), "programmeplanner_buttons")
			ProgrammePlannerButtons[1].spriteName = "gfx_programmeplanner_btn_programme"

			ProgrammePlannerButtons[2] = New TGUIButton.Create(New TVec2D.Init(686, 41 + 2*54), Null, GetLocale("PLANNER_FINANCES"), "programmeplanner_buttons")
			ProgrammePlannerButtons[2].spriteName = "gfx_programmeplanner_btn_financials"

			ProgrammePlannerButtons[3] = New TGUIButton.Create(New TVec2D.Init(686, 41 + 3*54), Null, GetLocale("PLANNER_STATISTICS"), "programmeplanner_buttons")
			ProgrammePlannerButtons[3].spriteName = "gfx_programmeplanner_btn_statistics"

			ProgrammePlannerButtons[4] = New TGUIButton.Create(New TVec2D.Init(686, 41 + 4*54), Null, GetLocale("PLANNER_ACHIEVEMENTS"), "programmeplanner_buttons")
			ProgrammePlannerButtons[4].spriteName = "gfx_programmeplanner_btn_achievements"

			ProgrammePlannerButtons[5] = New TGUIButton.Create(New TVec2D.Init(686, 41 + 5*54), Null, GetLocale("PLANNER_MESSAGES"), "programmeplanner_buttons")
			ProgrammePlannerButtons[5].spriteName = "gfx_programmeplanner_btn_unknown"

			For Local i:Int = 0 To 5
				ProgrammePlannerButtons[i].SetAutoSizeMode(TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE)
				ProgrammePlannerButtons[i].caption.SetContentPosition(ALIGN_CENTER, ALIGN_TOP)
				ProgrammePlannerButtons[i].caption.SetFont( GetBitmapFont("Default", 10, BOLDFONT) )

				ProgrammePlannerButtons[i].SetCaptionOffset(0,42)
			Next
		EndIf


		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]


		'=== register event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammePlanElementOnDayButton, "TGUIProgrammePlanElement") ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropFreshProgrammePlanElementOnRunningSlot, "TGUIProgrammePlanElement") ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropUnownedElement, "TGUIProgrammePlanElement") ]

		'savegame loaded - clear gui elements
		_eventListeners :+ [ EventManager.registerListenerFunction("SaveGame.OnLoad", onLoadSavegame) ]
		'player enters screen - reset the guilists
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterProgrammePlannerScreen, screen) ]
		'player leaves screen - only without dragged blocks
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.OnTryLeave", onTryLeaveProgrammePlannerScreen, screen) ]
		'player leaves screen - clean GUI (especially dragged ones)
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.OnFinishLeave", onLeaveProgrammePlannerScreen, screen) ]
		'player tries to leave the room - check like with screens
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onTryLeaveRoom", onTryLeaveRoom) ]
		'player leaves office forcefully - clean up
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onForcefullyLeaveRoom", onForcefullyLeaveRoom) ]

		'to react on changes in the programmePlan (eg. contract finished)
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.addObject", onChangeProgrammePlan) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.removeObject", onChangeProgrammePlan) ]
		'also react on "group changes" like removing unneeded adspots
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.removeObjectInstances", onChangeProgrammePlan) ]

		'to react on changes in the programmeCollection (eg. contract finished)
		'contrary to the programmeplan this triggers also for removed ad
		'contracts if only a dragged advertisement is "on" the plan
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeAdContract", onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeProgrammeLicence", onChangeProgrammeCollection) ]

	 	'automatically change current-plan-day on day change
		_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnDay", onChangeGameDay) ]


		'1) begin drop - to intercept if dropping ad to programme which does not allow Ad-Show
		'2) drop on a list - mark to ignore shortcuts if "replacing" an
		'   existing slot item. Must be done in "onTryDrop" so it is run
		'   before the shortcut-check is done (which is in "onTryDrag")
		'   -> so "onDrop" is not possible
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'drag/drop ... from or to one of the two lists
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.removedItem", onRemoveItemFromSlotList, GuiListProgrammes) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.removedItem", onRemoveItemFromSlotList, GuiListAdvertisements) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.addedItem", onAddItemToSlotList, GuiListProgrammes) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.addedItem", onAddItemToSlotList, GuiListAdvertisements) ]
		'so we can forbid adding to a "past"-slot
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListProgrammes) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.TryAddItem", onTryAddItemToSlotList, GuiListAdvertisements) ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverProgrammePlanElement, "TGUIProgrammePlanElement" ) ]
		'these lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'handle dragging of dayChangeProgrammePlanElements (eg. when dropping an item on them)
		'in this case - send them to GuiManager (like freshly created to avoid a history)
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'we want to handle drops on the same guilist slot (might be other planning day)
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDropBack", onDropProgrammePlanElementBack, "TGUIProgrammePlanElement") ]

		'intercept dragging items if we want a SHIFT/CTRL-copy/nextepisode
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDrag", onTryDragProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'handle dropping at the end of the list (for dragging overlapped items)
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.addObject", onProgrammePlanAddObject) ]

		'we want to colorize the list background depending on minute
		'_eventListeners :+ [ EventManager.registerListenerFunction("Game.OnMinute", onGameMinute) ]

		'we are interested in the programmeplanner buttons
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onProgrammePlannerButtonClick, "TGUIButton" ) ]

		'to update/draw the screen
		_eventListeners :+ TRoomHandler._RegisterScreenHandler( onUpdateProgrammePlanner, onDrawProgrammePlanner, screen )

		'(re-)localize content
		SetLanguage()
	End Function


	Function SetLanguage()
		'programmeplanner
		If ProgrammePlannerButtons[0]
			ProgrammePlannerButtons[0].SetCaption(GetLocale("PLANNER_ADS"))
			ProgrammePlannerButtons[1].SetCaption(GetLocale("PLANNER_PROGRAMME"))
			ProgrammePlannerButtons[2].SetCaption(GetLocale("PLANNER_FINANCES"))
			ProgrammePlannerButtons[3].SetCaption(GetLocale("PLANNER_STATISTICS"))
			ProgrammePlannerButtons[4].SetCaption(GetLocale("PLANNER_ACHIEVEMENTS"))
			ProgrammePlannerButtons[5].SetCaption(GetLocale("PLANNER_UNKNOWN"))
		EndIf

		'add gfx to background image
'		If Not DrawnOnProgrammePlannerBG
			InitProgrammePlannerBackground()
'			DrawnOnProgrammePlannerBG = True
'		EndIf
	End Function


	Function IsMyScreen:Int(screen:TScreen)
		if not screen then return False
		if screen.name = screenName then return True

		return False
	End Function


	Function IsMyRoom:Int(room:TRoomBase)
		For Local i:Int = 1 To 4
			If room = GetRoomCollection().GetFirstByDetails("office", i) Then Return True
		Next
		Return False
	End Function


	Function ResetSlotOverlays:Int(slotType:Int = -1)
		For Local i:Int = 0 To 23
			If slotType = TVTBroadcastMaterialType.PROGRAMME
				overlayedProgrammeSlots[i] = 0
			ElseIf slotType = TVTBroadcastMaterialType.ADVERTISEMENT
				overlayedAdSlots[i] = 0
			Else
				overlayedProgrammeSlots[i] = 0
				overlayedAdSlots[i] = 0
			EndIf
		Next
	End Function


	Function EnableSlotOverlays:Int(hours:Int[] = Null, slotType:Int = -1, mode:Int=1)
		If hours And hours.length > 0
			For Local hour:Int = EachIn hours
				If slotType = TVTBroadcastMaterialType.PROGRAMME
					overlayedProgrammeSlots[hour] = mode
				ElseIf slotType = TVTBroadcastMaterialType.ADVERTISEMENT
					overlayedAdSlots[hour] = mode
				Else
					overlayedProgrammeSlots[hour] = mode
					overlayedAdSlots[hour] = mode
				EndIf
			Next
		EndIf
	End Function


	Function DisableSlotOverlays:Int(hours:Int[] = Null, slotType:Int = 0)
		If hours And hours.length > 0
			For Local hour:Int = EachIn hours
				If slotType = TVTBroadcastMaterialType.PROGRAMME
					overlayedProgrammeSlots[hour] = 0
				ElseIf slotType = TVTBroadcastMaterialType.ADVERTISEMENT
					overlayedAdSlots[hour] = 0
				Else
					overlayedProgrammeSlots[hour] = 0
					overlayedAdSlots[hour] = 0
				EndIf
			Next
		EndIf
	End Function


	Function HasSlotOverlay:Int(hour:Int, slotType:Int = 0)
		If slotType = TVTBroadcastMaterialType.PROGRAMME
			Return overlayedProgrammeSlots[hour] <> 0
		Else
			Return overlayedAdSlots[hour] <> 0
		EndIf
	End Function


	Function GetSlotOverlay:Int(hour:Int, slotType:Int = 0)
		If slotType = TVTBroadcastMaterialType.PROGRAMME
			Return overlayedProgrammeSlots[hour]
		Else
			Return overlayedAdSlots[hour]
		EndIf
	End Function


	'called as soon as a player's figure is forced to leave a room
	Function onForcefullyLeaveRoom:Int( triggerEvent:TEventBase )
		'only handle the players figure
		If TFigure(triggerEvent.GetSender()) <> GetPlayer().figure Then Return False
		'only handle offices
		If Not IsMyRoom(TRoomBase(triggerEvent.GetReceiver())) Then Return False


		'=== PROGRAMMEPLANNER ===
		'close lists
		PPprogrammeList.SetOpen(0)
		PPcontractList.SetOpen(0)

		AbortScreenActions()
	End Function


	'called as soon as a player leaves a screen
	Function onLeaveProgrammePlannerScreen:Int( triggerEvent:TEventBase )
		'=== UNSET GUI ELEMENTS ===
		If draggedGuiProgrammePlanElement
			draggedGuiProgrammePlanElement.Remove()
			draggedGuiProgrammePlanElement = null
		endif
		hoveredGuiProgrammePlanElement = null

		For Local obj:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged.Copy()
			obj.Remove()
		Next
	End Function
	

	'call this function if the visual user actions need to get
	'aborted
	'clear the screen (remove dragged elements)
	Function AbortScreenActions:Int()
		'=== PROGRAMMEPLANNER ===
		If draggedGuiProgrammePlanElement
			'Try to drop back the element, except it is a freshly
			'created one
			If draggedGuiProgrammePlanElement.inList
				draggedGuiProgrammePlanElement.dropBackToOrigin()
			EndIf
			'successful or not - get rid of the gui element
			'(if it was a clone with no dropback-possibility this
			'just removes the clone, no worries)
			draggedGuiProgrammePlanElement = Null
			hoveredGuiProgrammePlanElement = Null
		EndIf

		'Try to drop back dragged elements
		For Local obj:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged.Copy()
			obj.dropBackToOrigin()
			'successful or not - get rid of the gui element
			obj.Remove()
		Next

		'=== IMAGE SCREEN ===
		'...

		'=== FINANCIAL SCREEN ===
		'...

		'...
	End Function


	Function RefreshHoveredProgrammePlanElement:Int()
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListProgrammes._slots
			If guiObject.isDragged() Or guiObject.isHovered()
				hoveredGuiProgrammePlanElement = guiObject
				Return True
			EndIf
		Next
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListAdvertisements._slots
			If guiObject.isDragged() Or guiObject.isHovered()
				hoveredGuiProgrammePlanElement = guiObject
				Return True
			EndIf
		Next
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiManager.ListDragged
			If guiObject.isDragged() Or guiObject.isHovered()
				hoveredGuiProgrammePlanElement = guiObject
				Return True
			EndIf
		Next
		Return False
	End Function


	Function DrawSlotHints()
		'nothing for noe
	End Function
	

	Function DrawSlotOverlays(invert:Int = False)
		Local oldCol:TColor = New TColor.get()
		SetAlpha oldCol.a * 0.65 + Float(Min(0.15, Max(-0.20, Sin(MilliSecs() / 6) * 0.20)))

		Local blockOverlay:TSprite = GetSpriteFromRegistry("gfx_programmeplanner_blockoverlay.highlighted")
		Local clockOverlay1:TSprite = GetSpriteFromRegistry("gfx_programmeplanner_clockoverlay1.highlighted")
		Local clockOverlay2:TSprite = GetSpriteFromRegistry("gfx_programmeplanner_clockoverlay2.highlighted")


		For Local i:Int = 0 To 23
			Local overlayedCount:Int = 0
			Local mode1:Int = GetSlotOverlay(i, TVTBroadcastMaterialType.PROGRAMME)
			Local mode2:Int = GetSlotOverlay(i, TVTBroadcastMaterialType.ADVERTISEMENT)
			overlayedCount = (mode1<>0) + (mode2<>0)
			If invert Then overlayedCount = 2 - overlayedCount
			If Not overlayedCount Then Continue


			Local x:Int, y:Int

			If i < 12
				x = 5
				y = 5 + i*30
			Else
				x = 340
				y = 5 + (i - 12)*30
			EndIf

			'clock overlay
			If mode1 = mode2
				If mode1 = 1 Then SetColor 110, 255, 110
				If mode1 = 2 Then SetColor 255,200,75
			Else
				SetColor 255,190,75
			EndIf
			If i Mod 2 = 0
				clockOverlay1.Draw(x, y)
			Else
				clockOverlay2.Draw(x, y)
			EndIf

			'programme overlay
			If (mode1<>0) = Not invert
				If mode1 = 1 Then SetColor 110, 255, 110
				If mode1 = 2 Then SetColor 255,200,75

				blockOverlay.DrawArea(x+40, y, 205, 30)
			EndIf

			'ad overlay
			If (mode2<>0) = Not invert
				If mode2 = 1 Then SetColor 110, 255, 110
				If mode2 = 2 Then SetColor 255,200,75

				blockOverlay.DrawArea(x+40 + 205, y, 85, 30)
			EndIf
		Next



		Local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
		SetAlpha oldCol.a * 0.30
		SetColor 170,30,0
		For Local i:Int = 0 To 23
			If plan.IsLockedSlot(TVTBroadcastMaterialType.PROGRAMME, GetWorldTime().GetDay(), i)
				If i < 12
					blockOverlay.DrawArea(45, 5 + i*30, 205, 30)
				Else
					blockOverlay.DrawArea(380, 5 + i*30, 205, 30)
				EndIf
			EndIf
			If plan.IsLockedSlot(TVTBroadcastMaterialType.ADVERTISEMENT, GetWorldTime().GetDay(), i)
				If i < 12
					blockOverlay.DrawArea(45 + 205, 5 + i*30, 85, 30)
				Else
					blockOverlay.DrawArea(380 + 205, 5 + i*30, 85, 30)
				EndIf
			EndIf
		Next
		oldCol.SetRGBA()
	End Function

	'=== EVENTS ===


	'clear the guilist once a savegame was loaded
	'(this avoids empty programme planners if loaded a savegame
	' with "planner" as active screen while already being there)
	Function onLoadSavegame:Int(triggerEvent:TEventBase)
		'important: change back to current planning day
		ChangePlanningDay(GetWorldTime().GetDay())
	End Function
	

	'clear the guilist if a player enters
	'screens are only handled by real players
	Function onEnterProgrammePlannerScreen:Int(triggerEvent:TEventBase)
		currentRoom = GetPlayer().GetFigure().inRoom
	
		'==== EMPTY/DELETE GUI-ELEMENTS =====
		hoveredGuiProgrammePlanElement = Null
		draggedGuiProgrammePlanElement = Null
		'remove all entries, also the dragged ones
		RemoveAllGuiElements(True)


		'local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
		'if plan
		'	if plan.RemoveBrokenObjects() > 0 then Notify "Ronny: Du hattest Programme/Werbung im Programmplan die als ~qnicht programmiert~q deklariert waren."
		'endif


		'=== INITIALIZE VIEW ===
		'set the planning day to the current one and recreate all gui
		'elements
		ChangePlanningDay(GetWorldTime().GetDay())
		'ChangePlanningDay already refreshes all gui elements
		'RefreshGUIElements()
	End Function


	Function onTryLeaveRoom:Int( triggerEvent:TEventBase )
		'only check a players or a observed figure
		local figure:TFigureBase = TFigureBase(triggerEvent.GetSender())
		if not (GameConfig.IsObserved(figure) or GetPlayerBase().GetFigure() = figure) then return False
		
		'as long as onTryLeaveProgrammePlannerScreen does not
		'check for specific event data... just forward the event
		return onTryLeaveProgrammePlannerScreen( triggerEvent )
	End Function


	Function onTryLeaveProgrammePlannerScreen:Int( triggerEvent:TEventBase )
		'old: do not allow leaving with a list open
		'new: just close the lists
		If PPprogrammeList.enabled Or PPcontractList.enabled
			PPprogrammeList.SetOpen(0)
			PPcontractList.SetOpen(0)
			'triggerEvent.SetVeto()
			'Return False
		EndIf

		'do not allow leaving as long as we have a dragged block
		If draggedGuiProgrammePlanElement
			triggerEvent.setVeto()
			Return False
		EndIf


		If openedProgrammeListThisVisit And TRoomHandler.IsPlayersRoom(currentRoom)
			GetPlayerProgrammeCollection(currentRoom.owner).ClearJustAddedProgrammeLicences()
		EndIf

		Return True
	End Function	


	Function onChangeProgrammeCollection:Int( triggerEvent:TEventBase )
		If Not TRoomHandler.CheckPlayerInRoom("office") Then Return False
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'is it the collection of the room owner?
		Local collection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent.GetSender())
		If Not collection Or not currentRoom or collection.owner <> currentRoom.owner Then Return False

		'recreate gui elements
		RefreshGuiElements()
		'refetch the hovered element (if there was one before)
		'so it can get drawn correctly in the render calls until the
		'next update call would fetch the hovered item again
		FindHoveredPlanElement()
	End Function


	'change to new day
	Function onChangeGameDay:Int( triggerEvent:TEventBase )
		ChangePlanningDay(GetWorldTime().GetDay())
	End Function


	'if players are in the office during changes
	'to their programme plan, react to...
	Function onChangeProgrammePlan:Int( triggerEvent:TEventBase )
		If Not TRoomHandler.CheckPlayerInRoom("office") Then Return False
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'is it the plan of the room owner?
		Local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		If Not plan or not currentRoom Or plan.owner <> currentRoom.owner Then Return False

		'recreate gui elements
		RefreshGuiElements()
		'refetch the hovered element (if there was one before)
		'so it can get drawn correctly in the render calls until the
		'next update call would fetch the hovered item again
		FindHoveredPlanElement()
	End Function


	'handle dragging dayChange elements (give them to GuiManager)
	'this way the newly dragged item is kind of a "newly" created
	'item without history of a former slot etc.
	Function onDragProgrammePlanElement:Int(triggerEvent:TEventBase)
		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'check if we somehow dragged a dayChange element
		'if so : remove it from the list and let the GuiManager manage it
		If item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListProgrammes.dayChangeGuiProgrammePlanElement)
			GuiListProgrammes.dayChangeGuiProgrammePlanElement = Null
			Return True
		EndIf
		If item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
			GuiManager.AddDragged(GuiListAdvertisements.dayChangeGuiProgrammePlanElement)
			GuiListAdvertisements.dayChangeGuiProgrammePlanElement = Null
			Return True
		EndIf
		Return False
	End Function


	Function onTryDragProgrammePlanElement:Int(triggerEvent:TEventBase)
		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'stop dragging from locked slots
		If GetPlayerProgrammePlan(currentRoom.owner).IsLockedBroadcastMaterial(item.broadcastMaterial)
			triggerEvent.SetVeto()
			Return False
		EndIf

		If Not ignoreCopyOrEpisodeShortcut And CreateNextEpisodeOrCopyByShortcut(item)
			triggerEvent.SetVeto()
			Return False
		EndIf

		'dragging is ok
		Return True
	End Function


	'handle adding items at the end of a day
	'so the removed material can be recreated as dragged gui items
	Function onProgrammePlanAddObject:Int(triggerEvent:TEventBase)
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'do not react if not the players Programme Plan
		'this is important, as you are _never_ able to control other
		'players plans
		Local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		If Not plan Or plan.owner <> GetPlayer().playerID Then Return False

		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False


		Local removedObjects:Object[] = Object[](triggerEvent.GetData().get("removedObjects"))
		Local addedObject:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().get("object"))
		If Not removedObjects Then Return False
		If Not addedObject Then Return False
		'also not interested if the programme ends before midnight
		If addedObject.programmedHour + addedObject.getBlocks() <= 24 Then Return False

		'create new gui items for all removed ones
		'this also includes todays programmes:
		'ex: added 5block to 21:00 - removed programme from 23:00-24:00 gets added again too
		For Local i:Int = 0 To removedObjects.length-1
			Local material:TBroadcastMaterial = TBroadcastMaterial(removedObjects[i])
			If material Then New TGUIProgrammePlanElement.CreateWithBroadcastMaterial(material, "programmePlanner").drag()
		Next
		Return False
	End Function


	'intercept if item does not allow dropping on specific lists
	'eg. certain ads as programme if they do not allow no commercial shows
	'eg. a live programme can only be dropped to a specific slot
	'eg. a programme with a time slot can only be dropped to a specific slots
	Function onTryDropProgrammePlanElement:Int(triggerEvent:TEventBase)
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False
		
		Local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		If Not list Then Return False


		'check if that item is allowed to get dropped on such a list
		Local receiverList:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent._receiver)
		If receiverList
			Local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", New TVec2D.Init(-1,-1)))
			Local slot:Int = receiverList.GetSlotByCoord(coord)

			'check if dropping on that slot is allowed slots
			'eg. live programme or programmes with a time slot
			If receiverList = GuiListProgrammes
				local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan( GetPlayerBase().playerID )

				if plan and plan.ProgrammePlaceable(item.broadcastMaterial, planningDay, slot) = -1
					triggerEvent.SetVeto()
					Return False
				endif
				
				rem
				If TProgramme(item.broadcastMaterial) And TProgramme(item.broadcastMaterial).data.IsLive()
					Local releaseTime:Long = TProgramme(item.broadcastMaterial).data.releaseTime

					If planningDay <> GetWorldTime().GetDay( releaseTime ) Or ..
					   slot <> GetWorldTime().GetDayHour( releaseTime )
						triggerEvent.SetVeto()
						Return False
					EndIf
				EndIf
				endrem
			EndIf
		EndIf


		'mark that something was dropped this round and no shortcuts should
		'get used
		ignoreCopyOrEpisodeShortcut = True

		'up to now: all are allowed
		Return True
	End Function


	'intercept if we do not own that element
	Function onTryDropUnownedElement:int(triggerEvent:TEventBase)
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False
		If Not currentRoom Then Return False

		if not GetPlayerProgrammeCollection(currentRoom.owner).HasBroadcastMaterial(item.broadcastMaterial)
			triggerEvent.SetVeto()
			return False
		endif

		return True
	End Function
	

	'intercept if a freshly created element is dropped on a not modifyable
	'slot
	Function onTryDropFreshProgrammePlanElementOnRunningSlot:Int(triggerEvent:TEventBase)
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False
		If Not currentRoom Then Return False

		Local receiverList:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent._receiver)
		If receiverList
			Local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", New TVec2D.Init(-1,-1)))
			Local slot:Int = receiverList.GetSlotByCoord(coord)

			'loop over all slots affected by this event
			Local pp:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
			For Local currentSlot:Int = slot Until slot + item.broadcastMaterial.GetBlocks(receiverList.isType)
				'stop adding to a locked slots or slots occupied by a partially
				'locked programme
				'also stops if the slot is used by a not-controllable programme
				If Not pp.IsModifyableSlot(receiverList.isType, planningDay, currentSlot)
					triggerEvent.SetVeto()
				EndIf
			Next

			'old "slotstate"-check approach
			If receiverList.GetSlotState(slot) = 2
				triggerEvent.SetVeto()
			EndIf
		EndIf
	End Function


	Function onTryDropProgrammePlanElementOnDayButton:Int(triggerEvent:TEventBase)
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'dropping on daychangebuttons means trying to change the day
		'while elements are dragged
		If plannerPreviousDayButton = triggerEvent.GetReceiver() Or ..
		   plannerNExtDayButton = triggerEvent.GetReceiver()
		
			triggerEvent.SetVeto()

			If plannerPreviousDayButton = triggerEvent.GetReceiver()
				ChangePlanningDay(planningDay-1)
			Else
				ChangePlanningDay(planningDay+1)
			EndIf

			'remove that programme from plan now
			'do this to avoid "handleDropBack()" returning true
			If item.lastList = GuiListAdvertisements
				GetPlayerProgrammePlan(currentRoom.owner).RemoveAdvertisement(item.broadcastMaterial)
				GuiListAdvertisements.RemoveItem(item)
			ElseIf item.lastList = GuiListProgrammes
				GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
				GuiListProgrammes.RemoveItem(item)
			EndIf

			'reset mousebutton
			MouseManager.ResetKey(1)

			Return False
		EndIf
	End Function
	

	'remove the material from the programme plan
	Function onRemoveItemFromSlotList:Int(triggerEvent:TEventBase)
		Local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		Local slot:Int = triggerEvent.GetData().getInt("slot", -1)

		If Not list Or Not item Or slot = -1 Then Return False

		'we removed the item but do not want the planner to know
		If Not talkToProgrammePlanner Then Return True

		If list = GuiListProgrammes
			If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
				TLogger.Log("onRemoveItemFromSlotList()", "Dragged item from programmelist - removing from programmeplan at "+slot+":00 - FAILED", LOG_WARNING)
			EndIf
		ElseIf list = GuiListAdvertisements
			If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveAdvertisement(item.broadcastMaterial)
				TLogger.Log("onRemoveItemFromSlotList()", "Dragged item from adlist - removing from programmeplan at "+slot+":00 - FAILED", LOG_WARNING)
			EndIf
		Else
			TLogger.Log("onRemoveItemFromSlotList()", "Dragged item from unknown list - removing from programmeplan at "+slot+":00 - FAILED", LOG_WARNING)
		EndIf

		Return True
	End Function


	'handle if a programme is dropped on the same slot but different
	'planning day
	Function onDropProgrammePlanElementBack:Int(triggerEvent:TEventBase)
		Local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetReceiver())
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())

		'is the gui item coming from another day?
		'remove it from there (was "silenced" during automatic mode)
		If List = GuiListProgrammes Or list = GuiListAdvertisements
			If item.plannedOnDay >= 0 And item.plannedOnDay <> list.planDay
				If item.lastList = GuiListAdvertisements
					If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveAdvertisement(item.broadcastMaterial)
						TLogger.Log("onDropProgrammePlanElementBack()", "Dropped item from another day on active day - removal in other days adlist FAILED", LOG_ERROR)
						Return False
					EndIf
				ElseIf item.lastList = GuiListProgrammes
					If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
						TLogger.Log("onDropProgrammePlanElementBack()", "Dropped item from another day on active day - removal in other days programmelist FAILED", LOG_ERROR)
						Return False
					EndIf
				EndIf
			EndIf
		EndIf

	End Function

	'add the material to the programme plan
	'added shortcuts for faster placement here as this event
	'is emitted on successful placements (avoids multiple dragged blocks
	'while dropping not possible)
	Function onAddItemToSlotList:Int(triggerEvent:TEventBase)
		Local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		Local slot:Int = triggerEvent.GetData().getInt("slot", -1)
		If Not list Or Not item Or slot = -1 Then Return False


		'set indicator on which day the item is planned
		'  (this saves some processing time - else we could request
		'   the day from the players ProgrammePlan)
		If List = GuiListProgrammes Or list = GuiListAdvertisements
			item.plannedOnDay = list.planDay
		EndIf

		'we removed the item but do not want the planner to know
		If Not talkToProgrammePlanner Then Return True


		'is the gui item coming from another day?
		'remove it from there (was "silenced" during automatic mode)
		If List = GuiListProgrammes Or list = GuiListAdvertisements
			If item.plannedOnDay >= 0 And item.plannedOnDay <> list.planDay
				If item.lastList = GuiListAdvertisements
					If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveAdvertisement(item.broadcastMaterial)
						TLogger.Log("onAddItemToSlotList()", "Dropped item from another day on active day - removal in other days adlist FAILED", LOG_ERROR)
						Return False
					EndIf
				ElseIf item.lastList = GuiListProgrammes
					If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
						TLogger.Log("onAddItemToSlotList()", "Dropped item from another day on active day - removal in other days programmelist FAILED", LOG_ERROR)
						Return False
					EndIf
				EndIf
			EndIf
		EndIf


		If list = GuiListProgrammes
			'is the gui item coming from another day?
			'remove it from there (was "silenced" during automatic mode)
			If item.plannedOnDay >= 0 And item.plannedOnDay <> list.planDay
				If Not GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
					TLogger.Log("onAddItemToSlotList()", "Dropped item on programmelist - removal from other day FAILED", LOG_ERROR)
					Return False
				EndIf
			EndIf

			If Not GetPlayerProgrammePlan(currentRoom.owner).SetProgrammeSlot(item.broadcastMaterial, planningDay, slot)
				TLogger.Log("onAddItemToSlotList()", "Dropped item on programmelist - adding to programmeplan at "+slot+":00 - FAILED", LOG_WARNING)
				Return False
			EndIf
		ElseIf list = GuiListAdvertisements
			If Not GetPlayerProgrammePlan(currentRoom.owner).SetAdvertisementSlot(item.broadcastMaterial, planningDay, slot)
				TLogger.Log("onAddItemToSlotList()", "Dropped item on adlist - adding to programmeplan at "+slot+":00 - FAILED", LOG_ERROR)
				Return False
			EndIf
		Else
			TLogger.Log("onAddItemToSlotList()", "Dropped item on unknown list - adding to programmeplan at "+slot+":00 - FAILED", LOG_ERROR)
			Return False
		EndIf

		Return True
	End Function


	'checks if it is allowed to occupy the the targeted slot (eg. slot lies in the past)
	Function onTryAddItemToSlotList:Int(triggerEvent:TEventBase)
		Local list:TGUIProgrammePlanSlotList = TGUIProgrammePlanSlotList(triggerEvent.GetSender())
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetData().get("item"))
		Local slot:Int = triggerEvent.GetData().getInt("slot", -1)
		If Not list Or Not item Or slot = -1 Then Return False
		If Not item.broadcastMaterial Then Return False

		Local pp:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
		'loop over all slots affected by this event - except
		'the broadcastmaterial is already placed at the given spot
		If item.broadcastMaterial <> pp.GetObject(list.isType, planningDay, slot)
			For Local currentSlot:Int = slot Until slot + item.broadcastMaterial.GetBlocks()
				'stop adding to a locked slots or slots occupied by a partially
				'locked programme
				'also stops if the slot is used by a not-controllable programme
				If Not pp.IsModifyableSlot(list.isType, planningDay, currentSlot)
					triggerEvent.SetVeto()
					Return False
				EndIf
			Next
		EndIf

		'only check slot state if interacting with the programme planner
		If talkToProgrammePlanner
			'already running or in the past
			If list.GetSlotState(slot) = 2
				triggerEvent.SetVeto()
				Return False
			EndIf
		EndIf
		Return True
	End Function


	'right mouse button click: remove the block from the player's programmePlan
	'left mouse button click: check shortcuts and create a copy/nextepisode-block
	Function onClickProgrammePlanElement:Int(triggerEvent:TEventBase)
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False

		Local item:TGUIProgrammePlanElement= TGUIProgrammePlanElement(triggerEvent._sender)

		'left mouse button
		If triggerEvent.GetData().getInt("button",0) = 1
			'special handling for special items
			'-> remove dayChangeObjects from plan if dragging (and allowed)
			If Not item.isDragged() And item.isDragable() And talkToProgrammePlanner
				If item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
					If GetPlayerProgrammePlan(currentRoom.owner).RemoveAdvertisement(item.broadcastMaterial)
						GuiListAdvertisements.dayChangeGuiProgrammePlanElement = Null
					EndIf
				ElseIf item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
					If GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
						GuiLisTProgrammes.dayChangeGuiProgrammePlanElement = Null
					EndIf
				EndIf
			EndIf


			'if shortcut is used on a dragged item ... it gets executed
			'on a successful drop, no need to do it here before
			If item.isDragged() Then Return False

			'assisting shortcuts create new guiobjects
			If CreateNextEpisodeOrCopyByShortcut(item)
				'do not try to drag the object - we did something special
				triggerEvent.SetVeto()
				Return False
			EndIf

			Return True
		EndIf

		'right mouse button - delete
		If triggerEvent.GetData().getInt("button",0) = 2
			'ignore wrong types and NON-dragged items
			If Not item.isDragged() Then Return False

			'remove if special
			If item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement Then GuiListAdvertisements.dayChangeGuiProgrammePlanElement = Null
			If item = GuiListProgrammes.dayChangeGuiProgrammePlanElement Then GuiListProgrammes.dayChangeGuiProgrammePlanElement = Null

			'will automatically rebuild at correct spot if needed
			item.remove()
			item = Null

			'remove right click - to avoid leaving the room
			MouseManager.ResetKey(2)
			'also avoid long click (touch screen)
			MouseManager.ResetLongClicked(1)
		EndIf
	End Function


	Function onMouseOverProgrammePlanElement:Int(triggerEvent:TEventBase)
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'only assign the first hovered item (to avoid having the lowest of a stack)
		If Not hoveredGuiProgrammePlanElement
			hoveredGuiProgrammePlanElement = item
			TGUIProgrammePlanElement.hoveredElement = item

			If item.isDragged()
				draggedGuiProgrammePlanElement = item
				'if we have an item dragged... we cannot have a menu open
				PPprogrammeList.SetOpen(0)
				PPcontractList.SetOpen(0)
			EndIf
		EndIf

		Return True
	End Function


	Function onDrawProgrammePlanner:Int( triggerEvent:TEventBase )
		Local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		currentRoom = room

		DrawSlotHints()
		
		GUIManager.Draw( LS_programmeplanner,,, GUIMANAGER_TYPES_NONDRAGGED)

		DrawSlotOverlays()

		'overlay old days
		If GetWorldTime().GetDay() > planningDay
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(5,5,675,400)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf


		GetSpriteFromRegistry("screen_programmeplanner_overlay").Draw(0,0)

		'time indicator
		If planningDay = GetWorldTime().GetDay() Then SetColor 0,100,0
		If planningDay < GetWorldTime().GetDay() Then SetColor 100,100,0
		If planningDay > GetWorldTime().GetDay() Then SetColor 0,0,0
		Local day:Int = 1+ planningDay - GetWorldTime().GetDay(GetWorldTime().GetTimeStart())
		GetBitmapFont("default", 11).drawBlock(day+". "+GetLocale("DAY"),712, 7, 56, 26, ALIGN_CENTER_TOP)
		GetBitmapFont("default", 10).drawBlock(GetWorldTime().GetFormattedDayLong(planningDay),712, 7, 56, 26, ALIGN_CENTER_BOTTOM)
		SetColor 255,255,255

		GUIManager.Draw(LS_programmeplanner_buttons,,, GUIMANAGER_TYPES_NONDRAGGED)
		GUIManager.Draw(LS_programmeplanner_and_programmeplanner_buttons,,, GUIMANAGER_TYPES_DRAGGED)


		SetColor 255,255,255
		If PPprogrammeList.GetOpen() > 0
			PPprogrammeList.owner = currentRoom.owner
			PPprogrammeList.Draw()
			If TRoomHandler.IsPlayersRoom(currentRoom)
				openedProgrammeListThisVisit = True
			EndIf
		EndIf

		If PPcontractList.GetOpen() > 0
			PPcontractList.owner = currentRoom.owner
			PPcontractList.Draw()
		EndIf

		'draw lists sheet
		If PPprogrammeList.GetOpen() And PPprogrammeList.hoveredLicence
			PPprogrammeList.hoveredLicence.ShowSheet(15-3, 10)
		EndIf

		'If PPcontractList.GetOpen() and
		If PPcontractList.hoveredAdContract
			PPcontractList.hoveredAdContract.ShowSheet(15-3, 10)
		EndIf


		'if not hoveredGuiProgrammePlanElement then RefreshHoveredProgrammePlanElement()
		'only draw, if not over the right side button
		If hoveredGuiProgrammePlanElement and MouseManager.x < 680
			'draw the current sheet
			hoveredGuiProgrammePlanElement.DrawSheet(15-3, 15-3, 680) ' +/-3 for dropshadow
		EndIf


		Local oldAlpha:Float = GetAlpha()
		If showPlannerShortCutHintTime > 0
			SetAlpha Min(1.0, 2.0*showPlannerShortCutHintTime/100.0)
			GetBitmapFont("Default", 11, BOLDFONT).drawBlock(GetLocale("HINT_PROGRAMMEPLANER_SHORTCUTS"), 3, 368, 660, 15, New TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(75),2,1,0.20)
		EndIf

		Local pulse:Float = Sin(Time.GetAppTimeGone() / 10)
		SetAlpha Max(0.75, -pulse) * oldAlpha
		DrawOval(5+pulse,367+pulse,15-2*pulse,15-2*pulse)
		SetAlpha oldAlpha
		GetBitmapFont("Default", 20, BOLDFONT).drawStyled("?", 7, 367, TColor.Create(50,50,150),2,1,0.25)
	End Function


	Function onUpdateProgrammePlanner:Int( triggerEvent:TEventBase )
		Local room:TRoomBase = TRoomBase( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		currentRoom = room

		'if not initialized, do so
		If planningDay = -1 Then planningDay = GetWorldTime().GetDay()

		'reset and refresh locked slots of this day
		ResetSlotOverlays()
		Local pp:TPlayerProgrammePlan = GetPlayerProgrammePlan(room.owner)
		Local hrs:Int[]
		For Local h:Int = 0 To 23
			If pp.IsLockedSlot(TVTBroadcastMaterialType.PROGRAMME, planningDay, h)
				hrs :+ [h]
			EndIf
		Next
		If hrs.length > 0 Then DisableSlotOverlays(hrs, TVTBroadcastMaterialType.PROGRAMME)

		'enable slot overlay if a dragged element is "live" or has a
		'"time slot" defining allowed times
		If draggedGuiProgrammePlanElement
			Local programme:TProgramme = TProgramme(draggedGuiProgrammePlanElement.broadcastMaterial)

			If programme
				'if it has a given time slot, mark these
				If programme.data.HasBroadcastTimeSlot()
					Local hourSlots:Int[]
					Local startHour:int = programme.data.broadcastTimeSlotStart
					Local endHour:int = programme.data.broadcastTimeSlotEnd
					If startHour < 0 Then startHour = 0
					If endHour < 0 Then endHour = 23

					For local hour:int = startHour to endHour
						hourSlots :+ [hour]
					Next
					EnableSlotOverlays(hourSlots, TVTBroadcastMaterialType.PROGRAMME, 1)
'					EnableSlotOverlays(hourSlots, TVTBroadcastMaterialType.ADVERTISEMENT, 1)
rem
Ueberpruefen:
- Lizenzen "Live" setzen und Zeitfenster erlauben
- Zeigt datenblatt dann "Live morgen 0:05 Uhr" _und_ "Nursendbar 0-6"?

- KI muss auch damit klarkommen (ausfiltern solcher Sendungen in der
"verfuegbar fuer jetzt" Liste
endrem
				'else mark the exact live time (releasetime + blocks) slots
				'(if planning day not in the past)
				ElseIf programme.data.IsLive() And GetWorldTime().GetDay() <= planningDay 
					Local hourSlots:Int[]
				
					Local blockTime:Long = programme.data.releaseTime
					If GameRules.onlyExactLiveProgrammeTimeAllowedInProgrammePlan
						'mark allowed slots
						For Local i:Int = 0 Until programme.GetBlocks()
							If GetWorldTime().GetDay(blockTime) = planningDay 
								hourSlots :+ [ GetWorldTime().GetDayHour(blockTime) ]
							EndIf
							blockTime :+ 3600
						Next
						EnableSlotOverlays(hourSlots, TVTBroadcastMaterialType.PROGRAMME, 1)


						'mark all future ad-slots allowed
						hourSlots = New Int[0]
						Local start:Int = GetWorldTime().GetDayHour()+1
						If GetWorldTime().GetDayMinute() < 55 Then start :- 1
						If GetWorldTime().GetDay() < planningDay Then start = 0
						For Local i:Int = start To 23
							hourSlots :+ [i]
						Next
						EnableSlotOverlays(hourSlots, TVTBroadcastMaterialType.ADVERTISEMENT, 1)
					Else
						'mark all forbidden slots
						Local startDay:Int = GetWorldtime().GetDay(blockTime)
						Local endDay:Int = GetWorldTime().GetDay(blockTime + programme.GetBlocks() * 3600)

						'future day - mark ALL blocks of today
						if startDay > planningDay and endDay > planningDay
							if GetWorldTime().GetDay() = planningDay
								For Local i:Int = GetWorldTime().GetDayHour() Until 24
									hourSlots :+ [ i ]
								Next
							else
								hourSlots = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
							endif

						'past day - mark NO block of today
						elseif startDay < planningDay and endDay < planningDay
							'
						'starts or ends today
						else
							Local nowHour:Int = GetWorldtime().GetDayHour()
							Local startHour:Int = GetWorldtime().GetDayHour(blockTime)
							Local endHour:Int = GetWorldTime().GetDayHour(blockTime) + programme.GetBlocks()

							If GetWorldTime().GetDayMinute() < 5 Then nowHour :- 1

							'only mark till midnight
							if startDay <> planningDay then startHour = 0
							if endDay <> planningDay then endHour = 23 
							if startHour > nowHour
								For Local i:Int = 0 Until startHour
									hourSlots :+ [ i ]
								Next
							endif
						endif

						EnableSlotOverlays(hourSlots, TVTBroadcastMaterialType.PROGRAMME, 2)
					EndIf
				EndIf
			EndIf
		EndIf
		
		GetGameBase().cursorstate = 0

		ignoreCopyOrEpisodeShortcut  = False

		'set all slots occupied or not
		Local day:Int = GetWorldTime().GetDay()
		Local hour:Int = GetWorldTime().GetDayHour()
		Local minute:Int = GetWorldTime().GetDayMinute()
		For Local i:Int = 0 To 23
			If Not TPlayerProgrammePlan.IsUseableTimeSlot(TVTBroadcastMaterialType.PROGRAMME, planningDay, i, day, hour, minute)
				GuiListProgrammes.SetSlotState(i, 2)
			Else
				GuiListProgrammes.SetSlotState(i, 0)
			EndIf
			If Not TPlayerProgrammePlan.IsUseableTimeSlot(TVTBroadcastMaterialType.ADVERTISEMENT, planningDay, i, day, hour, minute)
				GuiListAdvertisements.SetSlotState(i, 2)
			Else
				GuiListAdvertisements.SetSlotState(i, 0)
			EndIf
		Next

		'delete unused and create new gui elements
		If haveToRefreshGuiElements
			RefreshGuiElements()
			'reassign a potential hovered/dragged element
			FindHoveredPlanElement()
		EndIf

		If planningDay-1 < GetWorldTime().GetDay(GetWorldTime().GetTimeStart())
			plannerPreviousDayButton.disable()
		Else
			plannerPreviousDayButton.enable()
		EndIf

		'reset hovered and dragged gui objects - gets repopulated automagically
		hoveredGuiProgrammePlanElement = Null
		draggedGuiProgrammePlanElement = Null
		TGUIProgrammePlanElement.hoveredElement = Null

		'RON
		'fast movement is possible with keys
		'we use doAction as this allows a decreasing time
		'while keeping the original interval backupped
		If fastNavigateTimer.isExpired()
			If Not KEYMANAGER.isDown(KEY_PAGEUP) And Not KEYMANAGER.isDown(KEY_PAGEDOWN)
				fastNavigationUsedContinuously = False
			EndIf
			If KEYMANAGER.isDown(KEY_PAGEUP)
				ChangePlanningDay(planningDay-1)
				fastNavigationUsedContinuously = True
			EndIf
			If KEYMANAGER.isDown(KEY_PAGEDOWN)
				ChangePlanningDay(planningDay+1)
				fastNavigationUsedContinuously = True
			EndIf

			'modify action time AND reset timer
			If fastNavigationUsedContinuously
				'decrease action time each time a bit more...
				fastNavigateTimer.setInterval( Int(Max(50, fastNavigateTimer.GetInterval() * 0.9)), True )
			Else
				'set to initial value
				fastNavigateTimer.setInterval( fastNavigateInitialTimer, True )
			EndIf
		EndIf


		Local listsOpened:Int = (PPprogrammeList.enabled Or PPcontractList.enabled)
		'only handly programmeblocks if the lists are closed
		'else you will end up with nearly no space on the screen not showing
		'a licence sheet.
		If Not listsOpened
			GUIManager.Update( LS_programmeplanner_and_programmeplanner_buttons )
		'if a list is opened, we cannot have a hovered gui element
		Else
			hoveredGuiProgrammePlanElement = Null
			'but still have to check for clicks on the buttons
			GUIManager.Update( LS_programmeplanner_buttons)
		EndIf


		'do not allow interaction for other players (even with master key)
		'If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)
		If TRoomHandler.IsPlayersRoom(room)
			'enable List interaction
			PPprogrammeList.clicksAllowed = True
			PPcontractList.clicksAllowed = True
			GuiListProgrammes.setOption(GUI_OBJECT_CLICKABLE, True)
		Else
			'disable List interaction
			PPprogrammeList.clicksAllowed = False
			PPcontractList.clicksAllowed = False
			GuiListProgrammes.setOption(GUI_OBJECT_CLICKABLE, False)
		EndIf

		PPprogrammeList.owner = currentRoom.owner
		PPprogrammeList.Update()

		PPcontractList.owner = currentRoom.owner
		PPcontractList.Update()


		'hide or show help
		If THelper.IsIn(Int(MouseManager.x), Int(MouseManager.y), 0,365,20,20)
			showPlannerShortCutHintTime = 90
			showPlannerShortCutHintFadeAmount = 1
		Else
			showPlannerShortCutHintTime = Max(showPlannerShortCutHintTime-showPlannerShortCutHintFadeAmount, 0)
			showPlannerShortCutHintFadeAmount:+1
		EndIf
	End Function


	Function onProgrammePlannerButtonClick:Int( triggerEvent:TEventBase )
		Local button:TGUIButton = TGUIButton( triggerEvent._sender )
		If Not button Then Return 0

		'ignore other buttons than the plan buttons
		If Not GUIManager.IsState(button, LS_programmeplanner_buttons) Then Return 0
		Rem
		local validButton:int = False
		for local b:TGUIButton = EachIn ProgrammePlannerButtons
			if button = b then validButton = True; exit
		next
		if button = plannerNextDayButton then validButton = True
		if button = plannerPreviousDayButton then validButton = True
		endrem

		'only react if the click came from the left mouse button
		If triggerEvent.GetData().getInt("button",0) <> 1 Then Return True


		If button = plannerNextDayButton
			ChangePlanningDay(planningDay+1)
			'reset mousebutton
			MouseManager.ResetKey(1)
			Return True
		ElseIf button = plannerPreviousDayButton
			ChangePlanningDay(planningDay-1)
			'reset mousebutton
			MouseManager.ResetKey(1)
			Return True
		EndIf
			


		'close both lists
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'reset mousebutton
		MouseManager.ResetKey(1)

		'open others?
		If button = ProgrammePlannerButtons[0] Then Return PPcontractList.SetOpen(1)		'opens contract list
		If button = ProgrammePlannerButtons[1] Then Return PPprogrammeList.SetOpen(1)		'opens programme genre list

		If button = ProgrammePlannerButtons[2] Then Return ScreenCollection.GoToSubScreen("screen_office_financials")
		If button = ProgrammePlannerButtons[3] Then Return ScreenCollection.GoToSubScreen("screen_office_statistics")
		If button = ProgrammePlannerButtons[4] then return ScreenCollection.GoToSubScreen("screen_office_achievements")
		If button = ProgrammePlannerButtons[5] then return ScreenCollection.GoToSubScreen("screen_office_archivedmessages")
	End Function


	'=== COMMON FUNCTIONS / HELPERS ===


	Function CreateNextEpisodeOrCopyByShortcut:Int(item:TGUIProgrammePlanElement)
		If Not item Then Return False
		'only react to items which got freshly created
		If Not item.inList Then Return False

		'assisting shortcuts create new guiobjects
		'shift: next episode
		'ctrl : programme again
		If KEYMANAGER.IsDown(KEY_LSHIFT) Or KEYMANAGER.IsDown(KEY_RSHIFT)
			'reset key
			KEYMANAGER.ResetKey(KEY_LSHIFT)
			KEYMANAGER.ResetKey(KEY_RSHIFT)
			CreateNextEpisodeOrCopy(item, False)
			Return True
		ElseIf KEYMANAGER.IsDown(KEY_LCONTROL) Or KEYMANAGER.IsDown(KEY_RCONTROL)
			KEYMANAGER.ResetKey(KEY_LCONTROL)
			KEYMANAGER.ResetKey(KEY_RCONTROL)
			CreateNextEpisodeOrCopy(item, True)
			Return True
		EndIf
		'nothing clicked
		Return False
	End Function


	Function CreateNextEpisodeOrCopy:Int(item:TGUIProgrammePlanElement, createCopy:Int=True)
		Local newMaterial:TBroadcastMaterial = Null

		'copy:         for ads and programmes create a new object based
		'              on licence or contract
		'next episode: for ads: create a copy
		'              for movies and series: rely on a licence-function
		'              which returns the next licence of a series/collection
		'              OR the first one if already on the latest spot
		Local pCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(item.broadcastMaterial.owner)
		If Not pCollection Then Return False

		Select item.broadcastMaterial.materialType
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				'skip if you do no longer own the licence
				If Not pCollection.HasAdContract(TAdvertisement(item.broadcastMaterial).contract) Then Return False

				newMaterial = New TAdvertisement.Create(TAdvertisement(item.broadcastMaterial).contract)

			Case TVTBroadcastMaterialType.PROGRAMME
				'skip if you do no longer own the licence
				If Not pCollection.HasProgrammeLicence(TProgramme(item.broadcastMaterial).licence) Then Return False

				local createFromLicence:TProgrammeLicence
				If CreateCopy
					createFromLicence = TProgramme(item.broadcastMaterial).licence
				Else
					'attention: ask parent licence (which might be the same ...)
					if TProgramme(item.broadcastMaterial).licence.GetParentLicence().GetSubLicenceCount() > 0
						createFromLicence = TProgramme(item.broadcastMaterial).licence.GetNextAvailableSubLicence()
					'for "single licences" we cannot fetch a "next sublicence"
					else
						createFromLicence = TProgramme(item.broadcastMaterial).licence
					endif
				EndIf

				'only create a new broadcastmaterial if the licence is
				'available now (this avoids "broadcast limit exceeding" licences)
				if createFromLicence.IsAvailable()
					newMaterial = New TProgramme.Create(createFromLicence)
				endif
		End Select

		'create and drag
		If newMaterial
			Local guiObject:TGUIProgrammePlanElement = New TGUIProgrammePlanElement.CreateWithBroadcastMaterial(newMaterial, "programmePlanner")
			guiObject.drag()
			'remove position backup so a "dropback" does not work, and
			'the item does not drop back to "0,0"
			guiObject.positionBackup = Null
		EndIf
	End Function


	Function ChangePlanningDay:Int(day:Int=0)
		local earliestDay:int = GetWorldTime().GetDay(GetWorldTime().GetTimeStart())
		if currentRoom then earliestDay :+ Max(0, GetPlayer(currentRoom.owner).GetStartDay())

		'limit to start day
		planningDay = Max(earliestDay, day)

		'adjust slotlists (to hide ghosts on differing days)
		GuiListProgrammes.planDay = planningDay
		GuiListAdvertisements.planDay = planningDay

		'only do the gui stuff with the player being in the office
		If TRoomHandler.CheckPlayerInRoom("office")
			'only adjust GUI if we are displaying that screen (eg. AI skips that)
			If IsMyScreen( ScreenCollection.GetCurrentScreen() )
				'FALSE: without removing dragged
				'->ONLY keeps newly created, not ones dragged from a slot
				RemoveAllGuiElements(False)

				RefreshGuiElements()
				FindHoveredPlanElement()
			EndIf
		EndIf
	End Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:Int(removeDragged:Int=True)
		'do not inform programmeplanner!
		Local oldTalk:Int =	talkToProgrammePlanner
		talkToProgrammePlanner = False

'		Rem
'			this is problematic as this could bug out the programmePlan
		'keep the dragged entries if wanted so
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListProgrammes._slots
			If Not guiObject Then Continue
			If removeDragged Or Not guiObject.IsDragged()
				guiObject.remove()
				guiObject = Null
			EndIf
		Next
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListAdvertisements._slots
			If Not guiObject Then Continue
			If removeDragged Or Not guiObject.IsDragged()
				guiObject.remove()
				guiObject = Null
			EndIf
		Next
'		End Rem

		'remove dragged ones of gui manager
		If removeDragged
			For Local guiObject:TGuiProgrammePlanElement = EachIn GuiManager.listDragged.Copy()
				guiObject.remove()
				guiObject = Null
			Next
		EndIf

		'to recreate everything during next update...
		haveToRefreshGuiElements = True

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	Function FindHoveredPlanElement:Int()
'		hoveredGuiProgrammePlanElement = Null

		Local obj:TGUIProgrammePlanElement
		For obj = EachIn GuiManager.ListDragged
			If obj.containsXY(MouseManager.x, MouseManager.y)
				hoveredGuiProgrammePlanElement = obj
				Return True
			EndIf
		Next
		For obj = EachIn GuiListProgrammes._slots
			If obj.containsXY(MouseManager.x, MouseManager.y)
				hoveredGuiProgrammePlanElement = obj
				Return True
			EndIf
		Next
		For obj = EachIn GuiListAdvertisements._slots
			If obj.containsXY(MouseManager.x, MouseManager.y)
				hoveredGuiProgrammePlanElement = obj
				Return True
			EndIf
		Next
	End Function


	Function RefreshGuiElements:Int()
		'do not inform programmeplanner!
		Local oldTalk:Int =	talkToProgrammePlanner
		talkToProgrammePlanner = False


		'fix not-yet-set-currentroom and set to players office
		If Not currentRoom Then currentRoom = GetRoomCollection().GetFirstByDetails("office", GetPlayer().playerID)

		'===== REMOVE UNUSED =====
		'remove overnight
		If GuiListProgrammes.daychangeGuiProgrammePlanElement
			GuiListProgrammes.daychangeGuiProgrammePlanElement.remove()
			GuiListProgrammes.daychangeGuiProgrammePlanElement = Null
		EndIf
		If GuiListAdvertisements.daychangeGuiProgrammePlanElement
			GuiListAdvertisements.daychangeGuiProgrammePlanElement.remove()
			GuiListAdvertisements.daychangeGuiProgrammePlanElement = Null
		EndIf

		'remove dragged ones we do no longer own / have access too
		For Local obj:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged.Copy()
			if not GetPlayerProgrammeCollection(currentRoom.owner).HasBroadcastMaterial(obj.broadcastMaterial)
				obj.Remove()
			endif
		Next
		draggedGuiProgrammePlanElement = Null
		hoveredGuiProgrammePlanElement = Null


		Local currDay:Int = planningDay
		If currDay = -1 Then currDay = GetWorldTime().GetDay()

		
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListProgrammes._slots
			If guiObject.isDragged() Then Continue
			'check if programmed on the current day
			If guiObject.broadcastMaterial.isProgrammedForDay(currDay) Then Continue
			'print "GuiListProgramme has obsolete programme: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
			guiObject = Null
		Next
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListAdvertisements._slots
			If guiObject.isDragged() Then Continue
			'check if programmed on the current day
			If guiObject.broadcastMaterial.isProgrammedForDay(currDay) Then Continue
			'print "GuiListAdvertisement has obsolete ad: "+guiObject.broadcastMaterial.GetTitle()
			guiObject.remove()
			guiObject = Null
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programmes/ads
		Local daysProgramme:TBroadcastMaterial[] = GetPlayerProgrammePlan(currentRoom.owner).GetProgrammesInTimeSpan(currDay, 0, currDay, 23)
		Local repairBrokenAd:Int = False
		Local repairBrokenProgramme:Int = False
		For Local obj:TBroadcastMaterial = EachIn daysProgramme
			If Not obj Then Continue
			'if already included - skip it
			If GuiListProgrammes.ContainsBroadcastMaterial(obj) Then Continue

			'repair broken hours (could happen up to v0.2.7 because
			'of days=0 hours>24 params )
			If obj.programmedHour > 23
				obj.programmedDay :+ Int(obj.programmedHour / 24)
				obj.programmedHour = obj.programmedHour Mod 24
			EndIf
			'repair broken ones
			If obj.programmedDay = -1 And obj.programmedHour = -1
				repairBrokenProgramme = True
				Continue
			'today or yesterday ending after midnight
			ElseIf obj.programmedDay = currDay Or (obj.programmedDay+1 = currDay And obj.programmedHour + obj.GetBlocks() > 24)
				'ok
			'someday _not_ today or yesterday+endingToday
			Else
				repairBrokenProgramme = True
				Continue
			EndIf

						
			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			If obj.programmedDay < currDay And currDay  > 0
				'set to the obj still running at the begin of the current day
				GuiListProgrammes.SetDayChangeBroadcastMaterial(obj, currDay)
				Continue
			EndIf

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			Local foundInDragged:Int = False
			For Local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged
				If draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = True
					Continue
				EndIf
			Next
			If foundInDragged Then Continue

			'NORMAL MISSING
			If GuiListProgrammes.getFreeSlot() < 0
				Print "[ERROR] ProgrammePlanner: should add programme but no empty slot left"
				Continue
			EndIf

			Local block:TGUIProgrammePlanElement = New TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj)
			'print "ADD GuiListProgramme - missed new programme: "+obj.GetTitle() +" (programmedDay="+obj.programmedDay+", currDay="+currDay+") -> created block:"+block._id

			If Not GuiListProgrammes.addItem(block, String(obj.programmedHour))
				Print "ADD ERROR - could not add programme"
			Else
				'set value so a dropped block will get the correct ghost image
				block.lastListType = GuiListProgrammes.isType
			EndIf
		Next


		'ad list (can contain ads, programmes, ...)
		Local daysAdvertisements:TBroadcastMaterial[] = GetPlayerProgrammePlan(currentRoom.owner).GetAdvertisementsInTimeSpan(currDay, 0, currDay, 23)
		For Local obj:TBroadcastMaterial = EachIn daysAdvertisements
			If Not obj Then Continue

			'if already included - skip it
			If GuiListAdvertisements.ContainsBroadcastMaterial(obj) Then Continue
			'repair broken ones
			If obj.programmedDay = -1 And obj.programmedHour = -1
				repairBrokenAd = True
				Continue
			EndIf
			
			'DAYCHANGE
			'skip programmes started yesterday (they are stored individually)
			If obj.programmedDay < currDay And currDay > 0
				'set to the obj still running at the begin of the planning day
				GuiListAdvertisements.SetDayChangeBroadcastMaterial(obj, currDay)
				Continue
			EndIf

			'DRAGGED
			'check if we find it in the GuiManagers list of dragged items
			Local foundInDragged:Int = False
			For Local draggedGuiProgrammePlanElement:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged
				If draggedGuiProgrammePlanElement.broadcastMaterial = obj
					foundInDragged = True
					Continue
				EndIf
			Next
			If foundInDragged Then Continue

			'NORMAL MISSING
			If GuiListAdvertisements.getFreeSlot() < 0
				Print "[ERROR] ProgrammePlanner: should add advertisement but no empty slot left"
				Continue
			EndIf

			Local block:TGUIProgrammePlanElement = New TGUIProgrammePlanElement.CreateWithBroadcastMaterial(obj, "programmePlanner")
			'print "ADD GuiListAdvertisements - missed new advertisement: "+obj.GetTitle()

			If Not GuiListAdvertisements.addItem(block, String(obj.programmedHour))
				Print "ADD ERROR - could not add advertisement"
			EndIf
		Next


		If repairBrokenAd Or repairBrokenProgramme
			If GetPlayerProgrammePlan(currentRoom.owner).RemoveBrokenObjects()
				Notify "Ronny: Du hattest Programme/Werbung im Programmplan die als ~qnicht programmiert~q deklariert waren."
			EndIf
		EndIf


		haveToRefreshGuiElements = False

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	'add gfx to background
	Function InitProgrammePlannerBackground:Int()
		'restore backup before
		if programmePlannerBackgroundOriginal
			GetSpriteFromRegistry("screen_bg_programmeplanner").parent.image = LoadImage(LockImage(programmePlannerBackgroundOriginal).Copy())
		endif

		Local roomImg:TImage = GetSpriteFromRegistry("screen_bg_programmeplanner").parent.image

		'create backup if not existing
		if not programmePlannerBackgroundOriginal
			'either use our CopyImage() command - or a simpler one for
			'static background images:
			programmePlannerBackgroundOriginal = LoadImage(LockImage(roomImg).Copy())
		endif
		
		Local Pix:TPixmap = LockImage(roomImg)
		if Pix.format <> PF_RGB888
			TLogger.Log("TScreenHandler_ProgrammePlanner.InitProgrammePlannerBackground()", "Converted ~qscreen_bg_programmeplanner~q color space to RGB.", LOG_DEBUG)
			'convert it (attention: adjusts pix pointer)
			Pix = Pix.convert(PF_RGB888)
			'and store it in the image again (we just changed reference)
			roomImg.SetPixmap(0, Pix)

			Pix = LockImage(roomImg)
		endif

		Local gfx_ProgrammeBlock1:TImage = GetSpriteFromRegistry("pp_programmeblock1").GetImage()
		Local gfx_AdBlock1:TImage = GetSpriteFromRegistry("pp_adblock1").GetImage()


		'block"shade" on bg
		Local shadeColor:TColor = TColor.CreateGrey(200, 0.3)
		For Local j:Int = 0 To 11
			DrawImageOnImage(gfx_Programmeblock1, Pix, 45, 5 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Programmeblock1, Pix, 380, 5 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 45 + ImageWidth(gfx_Programmeblock1), 5 + j * 30, shadeColor)
			DrawImageOnImage(gfx_Adblock1, Pix, 380 + ImageWidth(gfx_Programmeblock1), 5 + j * 30, shadeColor)
		Next


		'set target for font
		TBitmapFont.setRenderTarget(roomImg)

		Local fontColor:TColor = TColor.CreateGrey(240)

		SetAlpha 0.75
		'only hour, not hour:00
		For Local i:Int = 0 To 11
			'right side
			GetBitmapFontManager().baseFontBold.DrawBlock( (i + 12), 341, 5 + i * 30, 39, 30, ALIGN_CENTER_CENTER, fontColor, 2,1,0.25)
			'left side
			Local text:String = i
			If i < 10 Then text = "0" + text
			GetBitmapFontManager().baseFontBold.DrawBlock( text, 6, 5 + i * 30, 39, 30, ALIGN_CENTER_CENTER, fontColor, 2,1,0.25)
		Next
		SetAlpha 1.0



		'=== DRAW HINTS FOR PRIMETIME/NIGHTTIME ===
		Local hintColor:TColor = New TColor.CreateGrey(75)
		Local hintColorGood:TColor = New TColor.Create(60,110,60)
		Local hintColorBad:TColor = New TColor.Create(110,60,60)
		Local f:TBitmapFont = GetBitmapFont("default", 10)
		Local fB:TBitmapFont = GetBitmapFont("default", 10, BOLDFONT)
		Local oldA:Float = GetAlpha()

		For Local i:Int = 0 To 23
			If i > 0 and i <= 6
				SetAlpha 0.8 * oldA
				fB.DrawBlock(GetLocale("NIGHTTIME"), 48, 5 + i*30, 205 - 2*10, 15, ALIGN_LEFT_CENTER, hintColor)
				SetAlpha 0.7 * oldA
				f.DrawBlock(GetLocale("LOW_AUDIENCE"), 48, 5 + i*30 + 15, 205 - 2*10, 15, ALIGN_LEFT_CENTER, hintColorBad)
			ElseIf i >= 19 And i <= 23
				SetAlpha 0.8 * oldA
				fB.DrawBlock(GetLocale("PRIMETIME"), 383, 5 + (i-12)*30, 205 - 2*10, 15, ALIGN_LEFT_CENTER, hintColor)
				SetAlpha 0.7 * oldA
				f.DrawBlock(GetLocale("HIGH_AUDIENCE"), 383, 5 + (i-12)*30 + 15, 205 - 2*10, 15, ALIGN_LEFT_CENTER, hintColorGood)
			EndIf
		Next

		SetAlpha oldA


		'reset target for font
		TBitmapFont.setRenderTarget(Null)
	End Function
End Type