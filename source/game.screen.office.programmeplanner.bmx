SuperStrict
Import "Dig/base.gfx.gui.button.bmx"
import "common.misc.plannerlist.contractlist.bmx"
import "common.misc.plannerlist.programmelist.bmx"
import "common.misc.screen.bmx"
import "game.room.base.bmx"
import "game.roomhandler.base.bmx"
import "game.player.bmx"
import "game.screen.base.bmx"



Type TScreenHandler_ProgrammePlanner
	Global showPlannerShortCutHintTime:Int = 0
	Global showPlannerShortCutHintFadeAmount:Int = 1
	Global planningDay:Int = -1
	Global talkToProgrammePlanner:Int = True		'set to FALSE for deleting gui objects without modifying the plan
	Global DrawnOnProgrammePlannerBG:Int = 0
	Global ProgrammePlannerButtons:TGUIProgrammePlannerButton[6]
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
	Global slotOverlaysBlock:TSprite
	Global slotOverlaysClock1:TSprite
	Global slotOverlaysClock2:TSprite

	Global hoveredGuiProgrammePlanElement:TGuiProgrammePlanElement = Null
	Global draggedGuiProgrammePlanElement:TGuiProgrammePlanElement = Null
	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:Int = True
	Global haveToFindHoveredGuiElement:Int = True
	Global GuiListProgrammes:TGUIProgrammePlanSlotList
	Global GuiListAdvertisements:TGUIProgrammePlanSlotList

	Global LS_programmeplanner:TLowerString = TLowerString.Create("programmeplanner")
	Global LS_programmeplanner_buttons:TLowerString = TLowerString.Create("programmeplanner_buttons")
	Global LS_programmeplanner_and_programmeplanner_buttons:TLowerString = TLowerString.Create("programmeplanner|programmeplanner_buttons")

	Global _globalEventListeners:TEventListenerBase[]
	Global _localEventListeners:TEventListenerBase[]
	Global screenName:string = "screen_office_programmeplanner"
	Global programmePlannerBackgroundOriginal:TImage


	Function Initialize:Int()
		Local screen:TScreen = ScreenCollection.GetScreen(screenName)
		If Not screen Then Return False

		slotOverlaysBlock = GetSpriteFromRegistry("gfx_programmeplanner_blockoverlay.highlighted")
		slotOverlaysClock1 = GetSpriteFromRegistry("gfx_programmeplanner_clockoverlay1.highlighted")
		slotOverlaysClock2 = GetSpriteFromRegistry("gfx_programmeplanner_clockoverlay2.highlighted")


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
			Local spriteAdBlock1:TSprite = GetSpriteFromRegistry("pp_adblock1")
			Local spriteProgrammeBlock1:TSprite = GetSpriteFromRegistry("pp_programmeblock1")
			Local area:SRectI = New SRectI(45,5,625,Int(12 * spriteProgrammeBlock1.area.h))

			GuiListProgrammes = New TGUIProgrammePlanSlotList.Create(New SVec2I(area.x, area.y), New SVec2I(area.w, area.h), "programmeplanner")
			GuiListProgrammes.Init("pp_programmeblock1", Int(spriteAdBlock1.area.w + gapBetweenHours))
			GuiListProgrammes.isType = TVTBroadcastMaterialType.PROGRAMME

			GuiListAdvertisements = New TGUIProgrammePlanSlotList.Create(New SVec2I(area.x + Int(spriteProgrammeBlock1.area.w), area.y), New SVec2I(area.w, area.h), "programmeplanner")
			GuiListAdvertisements.Init("pp_adblock1", Int(spriteProgrammeBlock1.area.w + gapBetweenHours))
			GuiListAdvertisements.isType = TVTBroadcastMaterialType.ADVERTISEMENT


			'=== create programme/contract lists
			PPprogrammeList	= New TgfxProgrammelist.Create(669, 8)
			PPcontractList = New TgfxContractlist.Create(669, 8)


			'=== create buttons
			plannerNextDayButton = New TGUIButton.Create(New SVec2I(768, 6), New SVec2I(28, 28), ">", "programmeplanner_buttons")
			plannerNextDayButton.SetSpriteName("gfx_gui_button.datasheet")

			plannerPreviousDayButton = New TGUIButton.Create(New SVec2I(684, 6), New SVec2I(28, 28), "<", "programmeplanner_buttons")
			plannerPreviousDayButton.SetSpriteName("gfx_gui_button.datasheet")

			'so we can handle clicks to the daychange-buttons while some
			'programmeplan elements are dragged
			'ATTENTION: this makes the button drop-targets, so take care of
			'vetoing try-drop-events
			plannerNextDayButton.SetOption(GUI_OBJECT_ACCEPTS_DROP)
			plannerPreviousDayButton.SetOption(GUI_OBJECT_ACCEPTS_DROP)


			ProgrammePlannerButtons[0] = New TGUIProgrammePlannerButton.Create(New SVec2I(686, 41 + 0*54), GUI_DIM_AUTOSIZE, GetLocale("PLANNER_ADS"), "programmeplanner_buttons")
			ProgrammePlannerButtons[0].SetSpriteName("gfx_programmeplanner_btn")
			ProgrammePlannerButtons[0].spriteInlayName = "gfx_programmeplanner_btn_ads"

			ProgrammePlannerButtons[1] = New TGUIProgrammePlannerButton.Create(New SVec2I(686, 41 + 1*54), GUI_DIM_AUTOSIZE, GetLocale("PLANNER_PROGRAMME"), "programmeplanner_buttons")
			ProgrammePlannerButtons[1].SetSpriteName("gfx_programmeplanner_btn")
			ProgrammePlannerButtons[1].spriteInlayName = "gfx_programmeplanner_btn_programme"

			ProgrammePlannerButtons[2] = New TGUIProgrammePlannerButton.Create(New SVec2I(686, 41 + 2*54), GUI_DIM_AUTOSIZE, GetLocale("PLANNER_FINANCES"), "programmeplanner_buttons")
			ProgrammePlannerButtons[2].SetSpriteName("gfx_programmeplanner_btn")
			ProgrammePlannerButtons[2].spriteInlayName = "gfx_programmeplanner_btn_financials"

			ProgrammePlannerButtons[3] = New TGUIProgrammePlannerButton.Create(New SVec2I(686, 41 + 3*54), GUI_DIM_AUTOSIZE, GetLocale("PLANNER_STATISTICS"), "programmeplanner_buttons")
			ProgrammePlannerButtons[3].SetSpriteName("gfx_programmeplanner_btn")
			ProgrammePlannerButtons[3].spriteInlayName = "gfx_programmeplanner_btn_statistics"

			ProgrammePlannerButtons[4] = New TGUIProgrammePlannerButton.Create(New SVec2I(686, 41 + 4*54), GUI_DIM_AUTOSIZE, GetLocale("PLANNER_ACHIEVEMENTS"), "programmeplanner_buttons")
			ProgrammePlannerButtons[4].SetSpriteName("gfx_programmeplanner_btn")
			ProgrammePlannerButtons[4].spriteInlayName = "gfx_programmeplanner_btn_achievements"

			ProgrammePlannerButtons[5] = New TGUIProgrammePlannerButton.Create(New SVec2I(686, 41 + 5*54), GUI_DIM_AUTOSIZE, GetLocale("PLANNER_MESSAGES"), "programmeplanner_buttons")
			ProgrammePlannerButtons[5].SetSpriteName("gfx_programmeplanner_btn")
			ProgrammePlannerButtons[5].spriteInlayName = "gfx_programmeplanner_btn_unknown"

			For Local i:Int = 0 To 5
				ProgrammePlannerButtons[i].SetAutoSizeMode(TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE)
				ProgrammePlannerButtons[i].caption.SetContentAlignment(ALIGN_CENTER, ALIGN_TOP)
				ProgrammePlannerButtons[i].caption.SetFont( GetBitmapFont("Default", 10, BOLDFONT) )

				ProgrammePlannerButtons[i].SetCaptionOffset(0,40)
			Next
		EndIf


		' === REGISTER EVENTS ===

		' remove old listeners
		EventManager.UnregisterListenersArray(_globalEventListeners)
		EventManager.UnregisterListenersArray(_localEventListeners)
		_globalEventListeners = new TEventListenerBase[0]
		_localEventListeners = new TEventListenerBase[0]

		' register new global listeners
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrop, onFinishDropProgrammePlanElement, "TGUIProgrammePlanElement") ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrop, onTryDropProgrammePlanElementOnDayButton, "TGUIProgrammePlanElement") ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrop, onTryDropFreshProgrammePlanElementOnRunningSlot, "TGUIProgrammePlanElement") ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrop, onTryDropUnownedElement, "TGUIProgrammePlanElement") ]

		'savegame loaded - clear gui elements
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, onLoadSavegame) ]
		'player enters screen - reset the guilists
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterProgrammePlannerScreen, screen) ]
		'player leaves screen - only without dragged blocks
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnTryLeave, onTryLeaveProgrammePlannerScreen, screen) ]
		'player leaves screen - clean GUI (especially dragged ones)
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnFinishLeave, onLeaveProgrammePlannerScreen, screen) ]
		'player tries to leave the room - check like with screens
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_OnTryLeaveRoom, onTryLeaveRoom) ]
		'player leaves office forcefully - clean up
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_OnForcefullyLeaveRoom, onForcefullyLeaveRoom) ]

		'to react on changes in the programmePlan (eg. contract finished)
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_AddObject, onChangeProgrammePlan) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_RemoveObject, onChangeProgrammePlan) ]
		'also react on "group changes" like removing unneeded adspots
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_RemoveObjectInstances, onChangeProgrammePlan) ]

		'to react on changes in the programmeCollection (eg. contract finished)
		'contrary to the programmeplan this triggers also for removed ad
		'contracts if only a dragged advertisement is "on" the plan
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveAdContract, onChangeProgrammeCollection) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence, onChangeProgrammeCollection) ]

	 	'automatically change current-plan-day on day change
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnDay, onChangeGameDay) ]


		'1) begin drop - to intercept if dropping ad to programme which does not allow Ad-Show
		'2) drop on a list - mark to ignore shortcuts if "replacing" an
		'   existing slot item. Must be done in "onTryDrop" so it is run
		'   before the shortcut-check is done (which is in "onTryDrag")
		'   -> so "onDrop" is not possible
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrop, onTryDropProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'drag/drop ... from or to one of the two lists
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_RemovedItem, onRemoveItemFromSlotList, GuiListProgrammes) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_RemovedItem, onRemoveItemFromSlotList, GuiListAdvertisements) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_AddedItem, onAddItemToSlotList, GuiListProgrammes) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_AddedItem, onAddItemToSlotList, GuiListAdvertisements) ]
		'so we can forbid adding to a "past"-slot
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_TryAddItem, onTryAddItemToSlotList, GuiListProgrammes) ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_TryAddItem, onTryAddItemToSlotList, GuiListAdvertisements) ]
		'we want to know if we hover a specific block - to show a datasheet
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverProgrammePlanElement, "TGUIProgrammePlanElement" ) ]
		'these lists want to delete the item if a right mouse click happens...
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'we want to handle drops on the same guilist slot (might be other planning day)
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnDropBack, onDropProgrammePlanElementBack, "TGUIProgrammePlanElement") ]

		'intercept dragging items if we want a SHIFT/CTRL-copy/nextepisode
		'also handle dragging of dayChangeProgrammePlanElements (eg. when dropping an item on them)
		'in this case - send them to GuiManager (like freshly created to avoid a history)
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrag, onFinishDragProgrammePlanElement, "TGUIProgrammePlanElement") ]
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrag, onTryDragProgrammePlanElement, "TGUIProgrammePlanElement") ]
		'handle dropping at the end of the list (for dragging overlapped items)
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_AddObject, onProgrammePlanAddObject) ]

		'we are interested in the programmeplanner buttons
		_globalEventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onProgrammePlannerButtonClick, "TGUIButton" ) ]


		' === REGISTER CALLBACKS ===

		' to update/draw the screen
		screen.AddUpdateCallback(onUpdateScreen)
		screen.AddDrawCallback(onDrawScreen)


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
			If room = GetRoomCollection().GetFirstByDetails("office", "", i) Then Return True
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


	Function EnableAllSlotOverlays:Int( slotType:Int = -1, mode:Int=1)
		For Local i:Int = 0 to 23
			If slotType = TVTBroadcastMaterialType.PROGRAMME
				overlayedProgrammeSlots[i] = mode
			ElseIf slotType = TVTBroadcastMaterialType.ADVERTISEMENT
				overlayedAdSlots[i] = mode
			Else
				overlayedProgrammeSlots[i] = mode
				overlayedAdSlots[i] = mode
			EndIf
		Next
	End Function


	Function DisableAllSlotOverlays:Int( slotType:Int = -1)
		For Local i:Int = 0 to 23
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


	Function EnableSlotOverlay:Int(hour:Int, slotType:Int = -1, mode:Int=1)
		If slotType = TVTBroadcastMaterialType.PROGRAMME
			overlayedProgrammeSlots[hour] = mode
		ElseIf slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			overlayedAdSlots[hour] = mode
		Else
			overlayedProgrammeSlots[hour] = mode
			overlayedAdSlots[hour] = mode
		EndIf
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


	Function DisableSlotOverlay:Int(hour:Int, slotType:Int = 0)
		If slotType = TVTBroadcastMaterialType.PROGRAMME
			overlayedProgrammeSlots[hour] = 0
		ElseIf slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			overlayedAdSlots[hour] = 0
		Else
			overlayedProgrammeSlots[hour] = 0
			overlayedAdSlots[hour] = 0
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

		if GUIManager.ListDragged.count() > 0
			For Local obj:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged.Copy()
				obj.Remove()
			Next
		endif
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
		If GUIManager.ListDragged.count() > 0
			For Local obj:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged.Copy()
				obj.dropBackToOrigin()
				'successful or not - get rid of the gui element
				obj.Remove()
			Next
			InvalidateGuiElements()
		EndIf
		'=== IMAGE SCREEN ===
		'...

		'=== FINANCIAL SCREEN ===
		'...

		'...
	End Function


	Function DrawSlotHints()
		'nothing for noe
	End Function


	Function DrawSlotOverlays(invert:Int = False)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		SetAlpha oldColA * 0.65 + Float(Min(0.15, Max(-0.20, Sin(MilliSecs() / 6) * 0.20)))

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
				If mode1 = 1
					SetColor 110,255,110
				ElseIf mode1 = 2
					SetColor 255,200,75
				EndIf
			Else
				SetColor 255,190,75
			EndIf
			If i Mod 2 = 0
				slotOverlaysClock1.Draw(x, y)
			Else
				slotOverlaysClock2.Draw(x, y)
			EndIf

			'programme overlay
			If (mode1<>0) = Not invert
				If mode1 = 1
					SetColor 110,255,110
				ElseIf mode1 = 2
					SetColor 255,200,75
				EndIf

				slotOverlaysBlock.DrawArea(x+40, y, 205, 30)
			EndIf

			'ad overlay
			If (mode2<>0) = Not invert
				If mode2 = 1
					SetColor 110,255,110
				ElseIf mode2 = 2
					SetColor 255,200,75
				EndIf

				slotOverlaysBlock.DrawArea(x+40 + 205, y, 85, 30)
			EndIf
		Next



		Local plan:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
		SetAlpha oldColA * 0.30
		SetColor 170,30,0
		local d:Int = GetWorldTime().GetDay()
		For Local i:Int = 0 To 23
			If plan.IsLockedSlot(TVTBroadcastMaterialType.PROGRAMME, d, i)
				If i < 12
					slotOverlaysBlock.DrawArea(45, 5 + i*30, 205, 30)
				Else
					slotOverlaysBlock.DrawArea(380, 5 + i*30, 205, 30)
				EndIf
			EndIf
			If plan.IsLockedSlot(TVTBroadcastMaterialType.ADVERTISEMENT, d, i)
				If i < 12
					slotOverlaysBlock.DrawArea(45 + 205, 5 + i*30, 85, 30)
				Else
					slotOverlaysBlock.DrawArea(380 + 205, 5 + i*30, 85, 30)
				EndIf
			EndIf
		Next

		SetColor(oldCol)
		SetAlpha(oldColA)
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
		'InvalidateGUIElements()
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

		Return True
	End Function


	Function onChangeProgrammeCollection:Int( triggerEvent:TEventBase )
		'only refresh if we see it
		if Not TRoomHandler.CheckObservedFigureInRoom("office") then return FALSE
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'is it the collection of the room owner?
		Local collection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent.GetSender())
		If Not collection Or not currentRoom or collection.owner <> currentRoom.owner Then Return False

		'mark gui elements to be recreated on next update/render
		InvalidateGuiElements()
		'Mark information about hovered element as invalid so it gets
		'repopulated in next render/update
		InvalidateHoveredPlanElement()
	End Function


	'change to new day
	Function onChangeGameDay:Int( triggerEvent:TEventBase )
		ChangePlanningDay(GetWorldTime().GetDay())
	End Function


	'if players are in the office during changes
	'to their programme plan, react to...
	Function onChangeProgrammePlan:Int( triggerEvent:TEventBase )
		'only refresh if we see it
		if Not TRoomHandler.CheckObservedFigureInRoom("office") then return FALSE
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'is it the plan of the room owner?
		Local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		If Not plan or not currentRoom Or plan.owner <> currentRoom.owner Then Return False

		'mark gui elements to be recreated on next update/render
		InvalidateGuiElements()
		'Mark information about hovered element as invalid so it gets
		'repopulated in next render/update
		InvalidateHoveredPlanElement()
	End Function


	'handle dragging dayChange elements (give them to GuiManager)
	'this way the newly dragged item is kind of a "newly" created
	'item without history of a former slot etc.
	Function onFinishDragProgrammePlanElement:Int(triggerEvent:TEventBase)
		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False


		'-> remove dayChangeObjects from plan if dragging (and allowed)
		If item = GuiListAdvertisements.dayChangeGuiProgrammePlanElement
			If GetPlayerProgrammePlan(currentRoom.owner).RemoveAdvertisement(item.broadcastMaterial)
				GuiManager.AddDragged(GuiListAdvertisements.dayChangeGuiProgrammePlanElement)
				GuiListAdvertisements.dayChangeGuiProgrammePlanElement = Null
			EndIf
		ElseIf item = GuiListProgrammes.dayChangeGuiProgrammePlanElement
			If GetPlayerProgrammePlan(currentRoom.owner).RemoveProgramme(item.broadcastMaterial)
				'print("onFinishDragProgrammePlanElement -> is daychange, removed")
				GuiManager.AddDragged(GuiListProgrammes.dayChangeGuiProgrammePlanElement)
				GuiListProgrammes.dayChangeGuiProgrammePlanElement = Null
			'Else
				'print("onFinishDragProgrammePlanElement -> is daychange, remove FAILED")
			EndIf
		EndIf

		Local draggedProgramme:TProgramme=TProgramme(item.broadcastMaterial)
		If draggedProgramme Then GetPlayerProgrammeCollection(currentRoom.owner).RemoveJustAddedProgrammeLicence(draggedProgramme.licence)
	End Function


	Function onTryDragProgrammePlanElement:Int(triggerEvent:TEventBase)
		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Return False
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False
		'print("onTryDragProgrammePlanElement -> item="+item.ToString())
		
		'stop dragging from locked slots
		If GetPlayerProgrammePlan(currentRoom.owner).IsLockedBroadcastMaterial(item.broadcastMaterial)
			'print("onTryDragProgrammePlanElement -> VETO, locked material.")
			triggerEvent.SetVeto()
			Return False
		EndIf

		If CreateNextEpisodeOrCopyByShortcut(item)
			'print("onTryDragProgrammePlanElement -> VETO, created copy/episode.  item="+item.ToString())
			triggerEvent.SetVeto()
			Return False
		EndIf

		'print("onTryDragProgrammePlanElement -> OK.")
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
			Local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", New TVec2D(-1,-1)))
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

		'up to now: all are allowed
		Return True
	End Function

	
	'create a new copy if shortcut keys are still hold
	Function onFinishDropProgrammePlanElement:int(triggerEvent:TEventBase)
		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False
		'do not react if in other players rooms
		If Not TRoomHandler.IsPlayersRoom(currentRoom) Then Return False

		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'create a copy of the item if keys are down
		CreateNextEpisodeOrCopyByShortcut(item)
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
			Local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", New TVec2D(-1,-1)))
			Local slot:Int = receiverList.GetSlotByCoord(coord)

			'loop over all slots affected by this event
			Local pp:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
			For Local currentSlot:Int = slot Until slot + item.broadcastMaterial.GetBlocks(receiverList.isType)
				'stop adding to a locked slots or slots occupied by a partially
				'locked programme
				'also stops if the slot is used by a not-controllable programme
				If Not pp.IsModifiableSlot(receiverList.isType, planningDay, currentSlot)
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

			'handled single click
			MouseManager.SetClickHandled(1)

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
				If Not pp.IsModifiableSlot(list.isType, planningDay, currentSlot)
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


		'left mouse button - create copy/episode if shortcut was used
		If triggerEvent.GetData().getInt("button",0) = 1
			'if shortcut is used on a dragged item ... it gets executed
			'on a successful drop, no need to do it here before
			If item.isDragged() Then Return False

			'assisting shortcuts create new guiobjects
			If CreateNextEpisodeOrCopyByShortcut(item)
				'do not try to drag the object - we did something special
				triggerEvent.SetVeto()
				Return False
			EndIf
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

			'avoid clicks
			'remove right click - to avoid leaving the room
			MouseManager.SetClickHandled(2)
		EndIf

		Return True
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


	Function onDrawScreen:Int(sender:TScreen, tweenValue:Float)
		Local ingameScreen:TInGameScreen_Room = TInGameScreen_Room(sender)
		currentRoom = ingameScreen.GetCurrentRoom()

		'delete unused and create new gui elements if needed
		RefreshGuiElements()
		'reassign a potential hovered/dragged element if needed
		'(except programme/ad contract list is open)
		If not PPprogrammeList.GetOpen() and not PPcontractList.GetOpen()
			FindHoveredPlanElement()
		EndIf


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
		Local col:SColor8
		If planningDay = GetWorldTime().GetDay()
			col = new SColor8(0, 80, 0)
		ElseIf planningDay < GetWorldTime().GetDay()
			col = new SColor8(90, 90, 0)
		Else
			col = new SColor8(50, 50, 50)
'			col = SColor8.Black
		EndIf
		Local day:Int = 1+ planningDay - GetWorldTime().GetDay(GetWorldTime().GetTimeStart())
		GetBitmapFont("default", 12, BOLDFONT).DrawBox(day+". "+GetLocale("DAY"),712, 7, 56, 26, sALIGN_CENTER_TOP, col, EDrawTextEffect.Emboss, 0.2)
		GetBitmapFont("default", 10).DrawBox(GetWorldTime().GetFormattedDayLong(planningDay),712, 6, 56, 26, sALIGN_CENTER_BOTTOM, col)

		GUIManager.Draw(LS_programmeplanner_buttons,,, GUIMANAGER_TYPES_NONDRAGGED)
		GUIManager.Draw(LS_programmeplanner_and_programmeplanner_buttons,,, GUIMANAGER_TYPES_DRAGGED)


		SetColor 255,255,255
		If PPprogrammeList.GetOpen() > 0
			PPprogrammeList.owner = currentRoom.owner
			PPprogrammeList.Draw(TgfxProgrammelist.MODE_PROGRAMMEPLANNER)
			If TRoomHandler.IsPlayersRoom(currentRoom)
				openedProgrammeListThisVisit = True
			EndIf
		EndIf

		If PPcontractList.GetOpen() > 0
			PPcontractList.owner = currentRoom.owner
			PPcontractList.Draw()
		EndIf

rem
		'draw lists sheet
		local hoveredLicence:TProgrammeLicence
		If PPprogrammeList.GetOpen() And PPprogrammeList.hoveredLicence
			hoveredLicence = PPprogrammeList.hoveredLicence
		EndIf
		
Ronny:
repairs old approach if above condition ("getopen()") is required
It seems as if it was done to correct a different bug which I cannot
see now (and also not in the commit history)
		'avoid flickering by rendering the list of a freshly created
		'programme element (if "draw()" is called before "update()")
		if not hoveredlicence and not draggedGuiProgrammePlanElement and GuiManager.ListDragged.Count() > 0
			For Local draggedElement:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged
				if TProgramme(draggedElement.broadcastMaterial)
					hoveredLicence = TProgramme(draggedElement.broadcastMaterial).licence
					exit
				endif
			Next
		EndIf

		if hoveredlicence
			hoveredlicence.ShowSheet(7, 20, 0)
		endif
endrem
		If PPprogrammeList.hoveredLicence
			PPprogrammeList.hoveredLicence.ShowSheet(7, 7, 0)
		EndIf
		

		If PPcontractList.hoveredAdContract
			PPcontractList.hoveredAdContract.ShowSheet(7, 7, 0, TVTBroadcastMaterialType.ADVERTISEMENT, 0, GetBroadcastManager().GetAudienceResult( currentRoom.owner ))
		EndIf


		'only draw, if not over the right side button
		If hoveredGuiProgrammePlanElement and MouseManager.x < 680
			'draw the current sheet
			If MouseManager.x < 340
				hoveredGuiProgrammePlanElement.DrawSheet(673, 10, 1.0) ' +/-3 for dropshadow
			Else
				hoveredGuiProgrammePlanElement.DrawSheet(7, 7, 0) ' +/-3 for dropshadow
			endif
		EndIf


		Local oldAlpha:Float = GetAlpha()
		If showPlannerShortCutHintTime > 0
			SetAlpha Min(1.0, 2.0*showPlannerShortCutHintTime/100.0)
			GetBitmapFont("Default", 11, BOLDFONT).DrawBox(GetLocale("HINT_PROGRAMMEPLANER_SHORTCUTS"), 3, 366, 660, 17, sALIGN_CENTER_TOP, new SColor8(75, 75, 75), EDrawTextEffect.Shadow, 0.20)
		EndIf

		Local pulse:Float = Sin(Time.GetAppTimeGone() / 10)
		SetAlpha Max(0.75, -pulse) * oldAlpha
		DrawOval(5+pulse,367+pulse,15-2*pulse,15-2*pulse)
		SetAlpha oldAlpha
		GetBitmapFont("Default", 20, BOLDFONT).DrawSimple("?", 7, 363, new SColor8(50,50,150), EDrawTextEffect.Shadow, 0.25)
	End Function


	Function onUpdateScreen:Int(sender:TScreen, deltaTime:Float)
		Local ingameScreen:TInGameScreen_Room = TInGameScreen_Room(sender)
		currentRoom = ingameScreen.GetCurrentRoom()


		'if not initialized, do so
		If planningDay = -1 Then planningDay = GetWorldTime().GetDay()

		'reset and refresh locked slots of this day
		ResetSlotOverlays()
		Local pp:TPlayerProgrammePlan = GetPlayerProgrammePlan(currentRoom.owner)
		DisableAllSlotOverlays(TVTBroadcastMaterialType.PROGRAMME)

		'enable slot overlay if a dragged element is "live" or has a
		'"time slot" defining allowed times
		If draggedGuiProgrammePlanElement
			Local programme:TProgramme = TProgramme(draggedGuiProgrammePlanElement.broadcastMaterial)

			If programme
				Local programmeStartDay:Int = GetWorldTime().GetDay(programme.data.releaseTime)
				Local programmeEndDay:Int = GetWorldTime().GetDay(programme.data.releaseTime + programme.GetBlocks() * TWorldTime.HOURLENGTH)

				'if it has a given time slot, mark these
				If programme.licence.HasBroadcastTimeSlot()
					'mark all red (and mark "allowed" individually)
					EnableAllSlotOverlays(TVTBroadcastMaterialType.PROGRAMME, 2)
					
					Local slotStart:Int = programme.licence.GetBroadcastTimeSlotStart()
					Local slotEnd:Int = programme.licence.GetBroadcastTimeSlotEnd()

					local allowedSlotCount:int
					'01:00 - 11:00
					if slotStart < slotEnd
						allowedSlotCount = slotEnd - slotStart
					'11:00 - 01:00
					ElseIf slotStart > slotEnd
						allowedSlotCount = 24 - (slotStart - slotEnd)
					'01:00 - 01:00
					Else
						allowedSlotCount = 1
					EndIf

					If not programme.licence.IsLive() or programme.licence.isAlwaysLive()
						'mark allowed slots of whole day
						For Local i:Int = 0 Until allowedSlotCount
							EnableSlotOverlay((slotStart + i) mod 24, TVTBroadcastMaterialType.PROGRAMME, 1)
						Next
					Else
						'mark allowed slots since earliest start hour
						Local blockTime:Long = programme.data.releaseTime
						Local blockStartDay:Int = GetWorldTime().GetDay(blockTime)
						Local blockStartHour:Int = GetWorldTime().GetDayHour(blockTime)
						if blockStartDay <= planningDay
							'ex. 02:00 - 11:00
							If slotStart <= slotEnd
								local earliestSlot:int = slotStart
								'subtract 1 as the programme has to end BEFORE
								local latestSlot:int = slotEnd -1
								'starting today?
								if blockStartDay = planningDay
									earliestSlot = Max(earliestSlot, blockStartHour)
								endif
								if latestSlot < earliestSlot then latestSlot = 23

								For Local i:Int = earliestSlot to latestSlot
									EnableSlotOverlay(i, TVTBroadcastMaterialType.PROGRAMME, 1)
								Next

							'ex. 11:00 - 02:00
							ElseIf slotStart > slotEnd
								'11:00 - 0:00
								local earliestSlot:int = slotStart
								local latestSlot:int = 23
								'starting today?
								if blockStartDay = planningDay
									earliestSlot = Max(earliestSlot, blockStartHour)
								endif

								For Local i:Int = earliestSlot to latestSlot
									EnableSlotOverlay(i, TVTBroadcastMaterialType.PROGRAMME, 1)
								Next


								'0:00 - 2:00
								earliestSlot = 0
								'subtract 1 as the programme has to end BEFORE
								latestSlot = slotEnd -1
								'starting today?
								if blockStartDay = planningDay
									earliestSlot = Max(earliestSlot, blockStartHour)
								endif
								if latestSlot > earliestSlot
									For Local i:Int = earliestSlot to latestSlot
										EnableSlotOverlay(i, TVTBroadcastMaterialType.PROGRAMME, 1)
									Next
								endif
							EndIf
						EndIf
					EndIf

				'starting later than the planning day (no slot affected) ?
				Elseif programme.licence.IsLive() and planningDay < programmeStartDay
					'mark all others red
					EnableAllSlotOverlays(TVTBroadcastMaterialType.PROGRAMME, -1)


				'else mark the exact live time (releasetime + blocks) slots
				'(if planning day not in the past)
	'				ElseIf programme.data.IsLive() And GetWorldTime().GetDay() <= planningDay
				ElseIf programme.licence.IsLive() and planningDay = programmeStartDay
					'mark all others red
					EnableAllSlotOverlays(TVTBroadcastMaterialType.PROGRAMME, -1)

					Local blockTime:Long = programme.data.releaseTime
					If not GameRules.onlyExactLiveProgrammeTimeAllowedInProgrammePlan
						'mark allowed slots
						'mark the live-time-slot green!
						if not programme.licence.IsAlwaysLive()
							For Local i:Int = 0 Until programme.GetBlocks()
								If GetWorldTime().GetDay(blockTime) = planningDay
									EnableSlotOverlay(GetWorldTime().GetDayHour(blockTime), TVTBroadcastMaterialType.PROGRAMME, 1)
								EndIf
								blockTime :+ 1 * TWorldTime.HOURLENGTH
							Next
						endif

						'mark all future slots allowed if the programme ends on the same day
						If programmeStartDay = programmeEndDay
							Local start:Int = GetWorldTime().GetDayHour(programme.data.releaseTime + programme.GetBlocks() * TWorldTime.HOURLENGTH)
							if start <= 23
								'keep the non-live "free"
								For Local i:Int = start To 23
									DisableSlotOverlay(i, -1)
								Next
							Endif
						EndIf
						'EnableSlotOverlays(hourSlots, TVTBroadcastMaterialType.ADVERTISEMENT, 1)
					Else
						'mark all forbidden slots
						Local startDay:Int = GetWorldTime().GetDay(blockTime)
						Local endDay:Int = GetWorldTime().GetDay(blockTime + programme.GetBlocks() * TWorldTime.HOURLENGTH)

						'future day - mark ALL blocks of today
						if startDay > planningDay and endDay > planningDay
							if GetWorldTime().GetDay() = planningDay
								'mark all hours red
								EnableAllSlotOverlays(TVTBroadcastMaterialType.PROGRAMME, 2)
							endif

						'past day - mark NO block of today
						elseif startDay < planningDay and endDay < planningDay
							'
						'starts or ends today / planning day
						else
							Local nowHour:Int = GetWorldTime().GetDayHour()
							Local startHour:Int = GetWorldTime().GetDayHour(blockTime)
							Local endHour:Int = GetWorldTime().GetDayHour(blockTime) + programme.GetBlocks()
							If GetWorldTime().GetDayMinute() < 5 Then nowHour :- 1

							'mark all hours red
							EnableAllSlotOverlays(TVTBroadcastMaterialType.PROGRAMME, 2)

							'mark live slots green
							For Local i:Int = 0 Until programme.GetBlocks()
								If GetWorldTime().GetDay(blockTime) = planningDay
									If GetWorldTime().GetDayHour() < GetWorldTime().GetDayHour(blockTime)
										EnableSlotOverlay(GetWorldTime().GetDayHour(blockTime), TVTBroadcastMaterialType.PROGRAMME, 1)
									ElseIf GetWorldTime().GetDayHour() = GetWorldTime().GetDayHour(blockTime) and GetWorldTime().GetDayMinute() < 5
										EnableSlotOverlay(GetWorldTime().GetDayHour(blockTime), TVTBroadcastMaterialType.PROGRAMME, 1)
									EndIf
								endIf
								blockTime :+ 1 * TWorldTime.HOURLENGTH
							Next
rem
							'only mark till midnight
							if startDay <> planningDay then startHour = 0
							if endDay <> planningDay then endHour = 23

							local earliestHour:int = 0
							'if today then only mark "not run" hours
							If planningDay = GetWorldTime().GetDay()
								earliestHour = GetWorldTime().GetDayHour()
								'already in this hour
								If GetWorldTime().GetDayMinute() > 5 Then earliestHour :+ 1
							EndIf

							For Local i:Int = earliestHour Until startHour
								DisableSlotOverlay(i, TVTBroadcastMaterialType.PROGRAMME)
							Next
endrem
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

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

		'delete unused and create new gui elements if needed
		RefreshGuiElements()
		'reassign a potential hovered/dragged element if needed
		'(except programme/ad contract list is open)
		If not PPprogrammeList.GetOpen() and not PPcontractList.GetOpen()
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
		'home for going to the current day, up/down for changing by exactly one day
		If KEYMANAGER.isHit(KEY_HOME)
			ChangePlanningDay(GetWorldTime().GetDay())
		ElseIf KEYMANAGER.isHit(KEY_UP)
			ChangePlanningDay(planningDay-1)
		ElseIf KEYMANAGER.isHit(KEY_DOWN)
			ChangePlanningDay(planningDay+1)
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
		If TRoomHandler.IsPlayersRoom(currentRoom)
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
		PPprogrammeList.Update(TgfxProgrammelist.MODE_PROGRAMMEPLANNER)

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

			'handled single click
			MouseManager.SetClickHandled(1)
			Return True
		ElseIf button = plannerPreviousDayButton
			ChangePlanningDay(planningDay-1)

			'handled single click
			MouseManager.SetClickHandled(1)
			Return True
		EndIf



		'close both lists
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'handled single click
		MouseManager.SetClickHandled(1)

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
						'but for multi-productions we can look for the "next" one
						If createFromLicence.IsCustomProduction() And createFromLicence.GetData().extra
							Local scriptId:Int = createFromLicence.GetData().extra.GetInt("scriptID")
							Local origReleaseDate:Long = createFromLicence.GetData().GetReleaseTime()
							Local replaced:Int = False
							If scriptId
								For Local t:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(createFromLicence.GetOwner()).GetProgrammeLicences()
									If t.IsCustomProduction() And t.GetData().extra And scriptId = t.GetData().extra.GetInt("scriptID")
										If t.GetData().GetReleaseTime() > origReleaseDate And (Not replaced Or t.GetData().GetReleaseTime() < createFromLicence.GetData().GetReleaseTime())  
											createFromLicence = t
											replaced = True
										EndIf
									EndIf
								Next
							EndIf
						EndIf
					endif
				EndIf

				'only create a new broadcastmaterial if the licence is
				'available now (this avoids "broadcast limit exceeding" licences)
				if createFromLicence and createFromLicence.IsAvailable()
					newMaterial = New TProgramme.Create(createFromLicence)
				endif
		End Select

		'create and drag
		If newMaterial
			Local guiObject:TGUIProgrammePlanElement = New TGUIProgrammePlanElement.CreateWithBroadcastMaterial(newMaterial, "programmePlanner")
			'avoid drag() as this emits events (tryDrag, drag, finishDrag)
			'instead simply add the object as dragged
			'guiObject.drag()
			GuiManager.AddDragged(guiObject)
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
		If TRoomHandler.CheckPlayerObservedAndInRoom("office")
			'only adjust GUI if we are displaying that screen (eg. AI skips that)
			If IsMyScreen( ScreenCollection.GetCurrentScreen() )
				'FALSE: without removing dragged
				'->ONLY keeps newly created, not ones dragged from a slot
				'also marks all gui elements for refresh
				RemoveAllGuiElements(False)
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
		If removeDragged and GUIManager.listDragged.count() > 0
			For Local guiObject:TGuiProgrammePlanElement = EachIn GuiManager.listDragged.Copy()
				guiObject.remove()
				guiObject = Null
			Next
		EndIf

		'mark gui elements to be recreated on next update/render
		InvalidateGuiElements()

		'set to backupped value
		talkToProgrammePlanner = oldTalk
	End Function


	Function FindHoveredPlanElement:Int(forceRefresh:Int = False)
		if Not haveToFindHoveredGuiElement and Not forceRefresh Then Return False

'		hoveredGuiProgrammePlanElement = Null

		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListProgrammes._slots
			If guiObject.isDragged() Or guiObject.isHovered()
				hoveredGuiProgrammePlanElement = guiObject
			EndIf
		Next
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiListAdvertisements._slots
			If guiObject.isDragged() Or guiObject.isHovered()
				hoveredGuiProgrammePlanElement = guiObject
			EndIf
		Next
		For Local guiObject:TGuiProgrammePlanElement = EachIn GuiManager.ListDragged
			If guiObject.isDragged() Or guiObject.isHovered()
				hoveredGuiProgrammePlanElement = guiObject
			EndIf
		Next
		
		haveToFindHoveredGuiElement = False
	End Function


	Function InvalidateGuiElements:Int()
		haveToRefreshGuiElements = True
	End Function

	Function InvalidateHoveredPlanElement:Int()
		haveToFindHoveredGuiElement = True
		'TODO: needed?
		'hoveredGuiProgrammePlanElement = Null
	End Function
	

	Function RefreshGuiElements:Int(forceRefresh:Int = False)
		If Not haveToRefreshGuiElements and Not forceRefresh Then Return False
		
		'do not inform programmeplanner!
		Local oldTalk:Int =	talkToProgrammePlanner
		talkToProgrammePlanner = False


		'fix not-yet-set-currentroom and set to players office
		If Not currentRoom Then currentRoom = GetRoomCollection().GetFirstByDetails("office", "", GetPlayer().playerID)

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
		If GUIManager.ListDragged.count() > 0
			For Local obj:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged.Copy()
				if not GetPlayerProgrammeCollection(currentRoom.owner).HasBroadcastMaterial(obj.broadcastMaterial)
					'print "no longer owning: " + obj.broadcastMaterial.GetTitle()
					obj.Remove()
				endif
			Next
		EndIf
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
			For Local draggedElement:TGUIProgrammePlanElement = EachIn GuiManager.ListDragged
				If draggedElement.broadcastMaterial = obj
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

		Local fontColor:SColor8 = new SColor8(240, 240, 240, int(0.75*255))

		'only hour, not hour:00
		For Local i:Int = 0 To 11
			'right side
			GetBitmapFontManager().baseFontBold.DrawBox( (i + 12), 341, 5 + i * 30, 39, 30, sALIGN_CENTER_CENTER, fontColor, EDrawTextEffect.Shadow, 0.25)
			'left side
			Local text:String = i
			If i < 10 Then text = "0" + text
			GetBitmapFontManager().baseFontBold.DrawBox( text, 6, 5 + i * 30, 39, 30, sALIGN_CENTER_CENTER, fontColor, EDrawTextEffect.Shadow, 0.25)
		Next



		'=== DRAW HINTS FOR PRIMETIME/NIGHTTIME ===
		Local hintColor:SColor8 = new SColor8(75, 75, 75)
		Local hintColorGood:SColor8 = new SColor8(60,110,60)
		Local hintColorBad:SColor8 = new SColor8(110,60,60)
		Local f:TBitmapFont = GetBitmapFont("default", 10)
		Local fB:TBitmapFont = GetBitmapFont("default", 10, BOLDFONT)
		Local oldA:Float = GetAlpha()

		For Local i:Int = 0 To 23
			If i > 0 and i <= 6
				SetAlpha 0.8 * oldA
				fB.DrawBox(GetLocale("NIGHTTIME"), 48, 5 + i*30, 205 - 2*10, 15, sALIGN_LEFT_CENTER, hintColor)
				SetAlpha 0.7 * oldA
				f.DrawBox(GetLocale("LOW_AUDIENCE"), 48, 5 + i*30 + 15, 205 - 2*10, 15, sALIGN_LEFT_CENTER, hintColorBad)
			ElseIf i >= 19 And i <= 23
				SetAlpha 0.8 * oldA
				fB.DrawBox(GetLocale("PRIMETIME"), 383, 5 + (i-12)*30, 205 - 2*10, 15, sALIGN_LEFT_CENTER, hintColor)
				SetAlpha 0.7 * oldA
				f.DrawBox(GetLocale("HIGH_AUDIENCE"), 383, 5 + (i-12)*30 + 15, 205 - 2*10, 15, sALIGN_LEFT_CENTER, hintColorGood)
			EndIf
		Next

		SetAlpha oldA


		'reset target for font
		TBitmapFont.setRenderTarget(Null)
	End Function
End Type



Type TGUIProgrammePlannerButton extends TGUIButton
	Field spriteInlayName:String
	Field spriteInlay:TSprite

	Method Create:TGUIProgrammePlannerButton(pos:SVec2I, dimension:SVec2I, value:String, State:String = "") override
		Return TGUIProgrammePlannerButton(Super.Create(pos, dimension, value, State))
	End Method
		

	Method DrawButtonBackground:Int(position:SVec2F) override
		Super.DrawButtonBackground(position)
		
		If not spriteInlay and spriteInlayName
			spriteInlay = GetSpriteFromRegistry(spriteInlayName)
		EndIf
		
		If spriteInlay
			'no custom ".active" - then just offset +1,+1
			If IsActive() And (spriteInlay.name = spriteInlayName Or spriteInlay = TSprite.defaultSprite)
				spriteInlay.Draw(position.x+1, position.y+1)
			Else
				spriteInlay.Draw(position.x, position.y)
			EndIf
		EndIf
	End Method
End Type
