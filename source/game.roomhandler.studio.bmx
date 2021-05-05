SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "Dig/base.gfx.gui.bmx"
Import "common.misc.dialogue.bmx"
Import "game.roomhandler.base.bmx"
Import "game.player.programmecollection.bmx"
Import "game.production.script.gui.bmx"
Import "game.production.productionconcept.gui.bmx"
Import "game.production.productionmanager.bmx"
Import "game.gameconfig.bmx"


'Studio: emitting and receiving the production concepts for specific
'        scripts
Type RoomHandler_Studio Extends TRoomHandler
	'a map containing "roomGUID"=>"script" pairs
	Field studioScriptsByRoom:TMap = CreateMap()

	Global studioManagerDialogue:TDialogue
	Global studioScriptLimit:Int = 1

	Global deskGuiListPos:TVec2D = New TVec2D.Init(330,335)
	Global suitcasePos:TVec2D = New TVec2D.Init(520,70)
	Global trashBinPos:TVec2D = New TVec2D.Init(148,327)
	Global suitcaseGuiListDisplace:TVec2D = New TVec2D.Init(16,22)

	Global studioManagerEntity:TSpriteEntity
	Global studioManagerArea:TGUISimpleRect

	Global studioManagerTooltip:TTooltip
	Global placeScriptTooltip:TTooltip

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:Int = True
	Global guiListStudio:TGUIScriptSlotList
	Global guiListSuitcase:TGUIScriptSlotList
	Global guiListDeskProductionConcepts:TGUIProductionConceptSlotList

	Global hoveredGuiScript:TGUIStudioScript
	Global draggedGuiScript:TGUIStudioScript

	Global hoveredGuiProductionConcept:TGuiProductionConceptListItem
	Global draggedGuiProductionConcept:TGuiProductionConceptListItem

	Global LS_studio:TLowerString = TLowerString.Create("studio")

	Global _instance:RoomHandler_Studio
	Global _eventListeners:TEventListenerBase[]


	Function GetInstance:RoomHandler_Studio()
		If Not _instance Then _instance = New RoomHandler_Studio
		Return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()
		studioScriptLimit = 1


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		'=== create room elements
		studioManagerEntity = GetSpriteEntityFromRegistry("entity_studio_manager")

		'=== create gui elements if not done yet
		If Not guiListStudio
			Local spriteScript:TSprite = GetSpriteFromRegistry("gfx_scripts_0")
			Local spriteProductionConcept:TSprite = GetSpriteFromRegistry("gfx_studio_productionconcept_0")
			Local spriteSuitcase:TSprite = GetSpriteFromRegistry("gfx_scripts_0_dragged")
			guiListStudio = New TGUIScriptSlotList.Create(New TVec2D.Init(710, 290), New TVec2D.Init(17, 52), "studio")
			'set to autofill so that "failed suitcase drops" can safely
			'be dropped back into the studio slot
			guiListStudio.SetAutofillSlots(True)
			guiListStudio.SetEntriesBlockDisplacement( 23, 10)
			guiListStudio.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			guiListStudio.SetItemLimit( studioScriptLimit )
			'increase list size by 2 times - makes it easier to drop
			guiListStudio.SetSize(90, 80)
			guiListStudio.SetSlotMinDimension(90, 80)
			guiListStudio.SetAcceptDrop("TGUIStudioScript")

			guiListSuitcase	= New TGUIScriptSlotlist.Create(New TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), New TVec2D.Init(200,80), "studio")
			guiListSuitcase.SetAutofillSlots(True)
			guiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			guiListSuitcase.SetItemLimit(GameRules.maxScriptsInSuitcase)
			guiListSuitcase.SetEntryDisplacement( 0, 0 )
			guiListSuitcase.SetAcceptDrop("TGUIStudioScript")

			guiListDeskProductionConcepts = New TGUIProductionConceptSlotList.Create(New TVec2D.Init(deskGuiListPos.GetX(), deskGuiListPos.GetY()), New TVec2D.Init(290,80), "studio")
			'make the list items sortable by the player
			guiListDeskProductionConcepts.SetAutofillSlots(False)
			guiListDeskProductionConcepts.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			guiListDeskProductionConcepts.SetItemLimit(GameRules.maxProductionConceptsPerScript)
			guiListDeskProductionConcepts.SetSlotMinDimension(spriteProductionConcept.area.GetW(), spriteProductionConcept.area.GetH())
			guiListDeskProductionConcepts.SetEntryDisplacement( 0, 0 )
			guiListDeskProductionConcepts.SetAcceptDrop("TGuiProductionConceptListItem")
			guiListDeskProductionConcepts._customDrawContent = DrawProductionConceptStudioSlotListContent


			'default studioManager dimension
			Local studioManagerAreaDimension:TVec2D = New TVec2D.Init(150,270)
			Local studioManagerAreaPosition:TVec2D = New TVec2D.Init(0,115)
			If studioManagerEntity Then studioManagerAreaDimension = studioManagerEntity.area.dimension.copy()
			If studioManagerEntity Then studioManagerAreaPosition = studioManagerEntity.area.position.copy()

			studioManagerArea = New TGUISimpleRect.Create(studioManagerAreaPosition, studioManagerAreaDimension, "studio" )
			'studioManager should accept drop - else no recognition
			studioManagerArea.setOption(GUI_OBJECT_ACCEPTS_DROP, True)
		EndIf


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]

		'=== register event listeners
		'to react on changes in the programmeCollection (eg. custom script finished)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveScript, onRemoveScriptFromProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveScript, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_MoveScript, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProductionConcept, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProductionConcept, onChangeProgrammeCollection) ]
		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to studio manager or suitcase
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnDropOnTargetAccepted, onDropScript, "TGUIStudioScript") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUISlotList_OnReplaceSlotItem, onReplaceGUIScripts, "TGUIScriptSlotList") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_onDropOnTargetAccepted, onDropProductionConcept, "TGuiProductionConceptListItem") ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverScript, "TGUIStudioScript") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverProductionConcept, "TGuiProductionConceptListItem") ]
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickScript, "TGUIStudioScript") ]

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		studioScriptsByRoom.Clear()
		studioManagerDialogue = Null
		studioManagerTooltip = Null
		placeScriptTooltip = Null

		'=== remove obsolete gui elements ===
		If guiListStudio Then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:Int()
		If GetInstance() <> Self Then Self.CleanUp()
		GetRoomHandlerCollection().SetHandler("studio", GetInstance())
	End Method


	Method AbortScreenActions:Int()
		Local abortedAction:Int = False

		If draggedGuiProductionConcept
			'try to drop the concept back
			draggedGuiProductionConcept.dropBackToOrigin()
			draggedGuiProductionConcept = Null
			hoveredGuiProductionConcept = Null
			abortedAction = True
		EndIf

		If draggedGuiScript
			'try to drop the licence back
			draggedGuiScript.dropBackToOrigin()
			draggedGuiScript = Null
			hoveredGuiScript = Null
			abortedAction = True
		EndIf

		'Try to drop back dragged elements
		If GUIManager.listDragged.Count() > 0
			For Local obj:TGUIStudioScript = EachIn GuiManager.ListDragged.Copy()
				obj.dropBackToOrigin()
				'successful or not - get rid of the gui element
				obj.Remove()
			Next
		EndIf

		Return abortedAction
	End Method


	Function GetStudioGUIDByScript:String(script:TScriptBase)
		For Local roomGUID:String = EachIn GetInstance().studioScriptsByRoom.Keys()
			If GetInstance().studioScriptsByRoom.ValueForKey(roomGUID) = script Then Return roomGUID
		Next
		Return ""
	End Function


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:Int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		Local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		If Not GameConfig.IsObserved(figure) And GetPlayerBase().GetFigure() <> figure Then Return False

		'empty the guilist / delete gui elements so they can get rebuild
		RemoveAllGuiElements()

		'remove potential old dialogues
		studioManagerDialogue = Null

		'enable/disable gui elements according to room owner
		'"only our player" filter already done before
		If IsRoomOwner(figure, TRoom(triggerEvent.GetSender()))
			guiListSuitcase.Enable()
			guiListStudio.Enable()
		Else
			guiListSuitcase.Disable()
			guiListStudio.Disable()
		EndIf
	End Method


	Function onRemoveScriptFromProgrammeCollection:Int( triggerEvent:TEventBase )
		Local script:TScriptBase = TScriptBase( triggerEvent.GetData().Get("script") )
		If Not script Then Return False

		Local roomGUID:String = GetStudioGUIDByScript(script)
		If roomGUID
			GetInstance().RemoveCurrentStudioScript(roomGUID)

			'refresh gui if player is in room
			If CheckObservedFigureInRoom("studio")
				haveToRefreshGuiElements = True
			EndIf
		EndIf
	End Function


	'if players are in a studio during changes in their programme
	'collection, react to it...
	Function onChangeProgrammeCollection:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("studio") Then Return False

		'instead of directly refreshing, we just set the dirty-indicator
		'to true (so it only refreshes once per tick, even with
		'multiple events coming in (add + move)
		haveToRefreshGuiElements = True
	End Function


	'in case of right mouse button click a dragged script is
	'placed at its original spot again
	Function onClickScript:Int(triggerEvent:TEventBase)
		If Not CheckPlayerObservedAndInRoom("studio") Then Return False

		'only react if the click came from the right mouse button
		If triggerEvent.GetData().getInt("button",0) <> 2 Then Return True

		Local guiScript:TGUIStudioScript = TGUIStudioScript(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		If Not guiScript Or Not guiScript.isDragged() Then Return False

		'just drop it to where it came from
		guiScript.DropBackToOrigin()
		
		'if deleting:
		rem
		'remove gui object
		guiScript.remove()
		guiScript = Null

		'rebuild at correct spot
		GetInstance().RefreshGuiElements()
		endrem

		'avoid clicks
		'remove right click - to avoid leaving the room
		MouseManager.SetClickHandled(2)
	End Function


	Function onMouseOverScript:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("studio") Then Return False

		Local item:TGUIStudioScript = TGUIStudioScript(triggerEvent.GetSender())
		If item = Null Then Return False

		hoveredGuiScript = item
		If item.isDragged() Then draggedGuiScript = item

		'close dialogue if we drag a script
		If draggedGuiScript And studioManagerDialogue
			studioManagerDialogue = Null
		EndIf

		Return True
	End Function


	Function onMouseOverProductionConcept:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("studio") Then Return False

		Local item:TGuiProductionConceptListItem = TGuiProductionConceptListItem(triggerEvent.GetSender())
		If item = Null Then Return False

		hoveredGuiProductionConcept = item
		If item.isDragged()
			'close dialogue if we started dragging a script
			If Not draggedGuiProductionConcept And studioManagerDialogue
				studioManagerDialogue = Null
			EndIf

			draggedGuiProductionConcept = item
		EndIf

		Return True
	End Function


	Function onReplaceGUIScripts:Int( triggerEvent:TEventBase )
		'only interested in drops on the suitcase ?
		Local list:TGUIObject = TGUIObject(triggerEvent.GetSender())
		Local oldItem:TGUIStudioScript = TGUIStudioScript(triggerEvent.GetData().Get("target"))
		Local newItem:TGUIStudioScript = TGUIStudioScript(triggerEvent.GetData().Get("source"))
		if not list or not newItem or not oldItem then Return False

		Local roomGUID:String = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()
		Local roomOwner:Int = TFigure(GetPlayerBase().GetFigure()).inRoom.owner

		'suitcase? check if new one came from studio ("is current")
		If list = guiListSuitcase and GetInstance().GetCurrentStudioScript(roomGUID) = newItem.script
			'print "dropped current on suitcase, set old as current"
			Local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(roomOwner)
			GetInstance().SetCurrentStudioScript(oldItem.script, roomGUID)

			newItem.InitAssets(newItem.getAssetName(-1, True), newItem.getAssetName(-1, True))
		ElseIf list = guiListStudio and GetInstance().GetCurrentStudioScript(roomGUID) <> newItem.script
			'print "dropped new on suitcase"
			GetInstance().SetCurrentStudioScript(newItem.script, roomGUID)

			newItem.InitAssets(newItem.getAssetName(-1, False), newItem.getAssetName(-1, True))
		EndIf
	End Function



	Function onDropScript:Int( triggerEvent:TEventBase )
		If Not CheckPlayerObservedAndInRoom("studio") Then Return False

		Local guiBlock:TGUIStudioScript = TGUIStudioScript(triggerEvent._sender)
		Local receiver:TGUIObject = TGUIObject(triggerEvent._receiver)
		If Not guiBlock Or Not receiver Then Return False

		Local roomGUID:String = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()

		If receiver = guiListStudio Or receiver = studioManagerArea
			if GetInstance().GetCurrentStudioScript(roomGUID) <> guiBlock.script 
				'print "   suitcase -> studio [is new]"
				GetInstance().SetCurrentStudioScript(guiBlock.script, roomGUID)

				guiBlock.InitAssets(guiBlock.getAssetName(-1, False), guiBlock.getAssetName(-1, True))
				'remove an old dialogue, it might be different now
				studioManagerDialogue = Null
			EndIf
		ElseIf receiver = guiListSuitcase and GetInstance().GetCurrentStudioScript(roomGUID) = guiBlock.script
			if GetInstance().GetCurrentStudioScript(roomGUID) = guiBlock.script 
				'print "   studio -> suitcase  [is current]"
				GetInstance().RemoveCurrentStudioScript(roomGUID)

				guiBlock.InitAssets(guiBlock.getAssetName(-1, True), guiBlock.getAssetName(-1, True))
				'remove an old dialogue, it might be different now
				studioManagerDialogue = Null
			EndIf
		EndIf


		Return True
	End Function




	Function onDropProductionConcept:Int( triggerEvent:TEventBase )
		If Not CheckPlayerObservedAndInRoom("studio") Then Return False

		Local guiBlock:TGuiProductionConceptListItem = TGuiProductionConceptListItem( triggerEvent._sender )
		Local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		If Not guiBlock Or Not receiver Then Return False

		Local receiverList:TGUIProductionConceptSlotList = TGUIProductionConceptSlotList(TGUIListBase.FindGUIListBaseParent(receiver))
		'only interested in drops to the list
		If Not receiverList Then Return False


		'save order of concepts
		For Local i:Int = 0 Until guiListDeskProductionConcepts._slots.length
			guiBlock = TGuiProductionConceptListItem(guiListDeskProductionConcepts.GetItemBySlot(i))
			If Not guiBlock Then Continue

			guiBlock.productionConcept.studioSlot = i
		Next

		Return True
	End Function


	'override
	Method onTryLeaveRoom:Int( triggerEvent:TEventBase )
		'non players can always leave
		Local figure:TFigure = TFigure(triggerEvent.GetSender())
		If Not figure Or Not figure.playerID Then Return False

		'handle interactivity for room owners
		If IsRoomOwner(figure, TRoom(triggerEvent.GetReceiver()))
			'if the manager dialogue is open - just close the dialogue
			If studioManagerDialogue
				studioManagerDialogue = Null
			EndIf
		EndIf

		Return True
	End Method


	Method SetCurrentStudioScript:Int(script:TScript, roomGUID:String, ignoreRoomSize:Int = False)
		If Not script Or Not roomGUID Then Return False
		
		If Not ignoreRoomSize
			local room:TRoomBase = GetRoomBaseByGUID(roomGUID)
			if room and room.GetSize() < script.requiredStudioSize then Return False
		EndIf

		'remove old script if there is one
		'-> this makes them available again
		'if this the new script is coming from the suitcase we can
		'just move the old one back into the suitcase even if there
		'is not enough space (the new one will make space...)
		If GetPlayerBaseCollection().IsPlayer(script.owner) and GetPlayerProgrammeCollection(script.owner).HasScriptInSuitcase(script)
			RemoveCurrentStudioScript(roomGUID, True)
		Else
			RemoveCurrentStudioScript(roomGUID, False)
		EndIf

		studioScriptsByRoom.Insert(roomGUID, script)

		'remove from suitcase list
		If GetPlayerBaseCollection().IsPlayer(script.owner)
			GetPlayerProgrammeCollection(script.owner).MoveScriptFromSuitcaseToStudio(script)
		EndIf

		Return True
	End Method


	Method RemoveCurrentStudioScript:Int(roomGUID:String, forceSuitcase:Int = False)
		If Not roomGUID Then Return False

		Local script:TScript = GetCurrentStudioScript(roomGUID)
		If Not script Then Return False


		If GetPlayerBaseCollection().IsPlayer(script.owner)
			Local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(script.owner)

			'if players suitcase has enough space for the script, add
			'it to there, else add to archive
			If forceSuitcase or pc.CanMoveScriptToSuitcase()
				pc.MoveScriptFromStudioToSuitcase(script, forceSuitcase)
			Else
				pc.MoveScriptFromStudioToArchive(script)
			EndIf
		EndIf

		Return studioScriptsByRoom.Remove(roomGUID)
	End Method


	Method GetCurrentStudioScript:TScript(roomGUID:String)
		If Not roomGUID Then Return Null

		Return TScript(studioScriptsByRoom.ValueForKey(roomGUID))
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:Int()
		guiListStudio.EmptyList()
		guiListSuitcase.EmptyList()
		guiListDeskProductionConcepts.EmptyList()

		If GUIManager.listDragged.Count() > 0
			For Local guiScript:TGUIStudioScript = EachIn GuiManager.listDragged.Copy()
				guiScript.remove()
				guiScript = Null
			Next
		EndIf

		If GUIManager.listDragged.Count() > 0
			For Local guiConcept:TGuiProductionConceptListItem = EachIn GuiManager.listDragged.Copy()
				guiConcept.remove()
				guiConcept = Null
			Next
		EndIf

		hoveredGuiScript = Null
		draggedGuiScript = Null
		draggedGuiProductionConcept = Null
		hoveredGuiProductionConcept = Null

		'to recreate everything during next update...
		haveToRefreshGuiElements = True
	End Function


	Method RefreshGuiElements:Int()
		'===== REMOVE UNUSED =====
		'remove gui elements with scripts the player does no longer have

		'1) refresh gui elements for the player who owns the room, not
		'   the active player!
		'2) player should be ALWAYS inRoom when "RefreshGuiElements()"
		'   is called
		Local room:TRoomBase = TFigure(GetPlayerBase().GetFigure()).inRoom
		If Not room Then Return False
		
		Local roomGUID:String = room.GetGUID()

		'helper vars
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(room.owner)

		'=== REMOVE SCRIPTS ===

		'dragged scripts
		Local draggedScripts:TList = CreateList()
		If GUIManager.listDragged.Count() > 0
			For Local guiScript:TGUIStudioScript = EachIn GuiManager.listDragged.Copy()
				draggedScripts.AddLast(guiScript.script)
				'remove the dragged guiscript, gets replaced by a new
				'instance
				guiScript.Remove()
			Next
		EndIf

		'suitcase
		For Local guiScript:TGUIStudioScript = EachIn GuiListSuitcase._slots
			'if the player has this script in suitcase or list, skip deletion
			If programmeCollection.HasScript(guiScript.script) Then Continue
			If programmeCollection.HasScriptInSuitcase(guiScript.script) Then Continue
			guiScript.remove()
			guiScript = Null
		Next

		'studio list
		For Local guiScript:TGUIStudioScript = EachIn guiListStudio._slots
			If GetCurrentStudioScript(roomGUID) <> guiScript.script
				guiScript.remove()
				guiScript = Null
			EndIf
		Next


		'=== REMOVE PRODUCTION CONCEPTS ===

		'dragged ones
		Local draggedProductionConcepts:TList = CreateList()
		If GUIManager.listDragged.Count() > 0
			For Local guiProductionConcept:TGuiProductionConceptListItem = EachIn GuiManager.listDragged.Copy()
				draggedProductionConcepts.AddLast(guiProductionConcept.productionConcept)
				'remove the dragged one, gets replaced by a new instance
				guiProductionConcept.Remove()
			Next
		EndIf

		'desk production concepts
		For Local guiProductionConcept:TGuiProductionConceptListItem = EachIn guiListDeskProductionConcepts._slots
			'if the concept is for the current set script, skip deletion
			If guiProductionConcept.productionConcept.script = GetCurrentStudioScript(roomGUID) Then Continue

			guiProductionConcept.remove()
			guiProductionConcept = Null
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all script-lists

		'=== SCRIPTS ===

		'studio concept list
		Local studioScript:TScript = GetCurrentStudioScript(roomGUID)
		If studioScript
			'adjust list limit
			Local minConceptLimit:Int = 1
			If studioScript.GetSubScriptCount() > 0
				minConceptLimit = Min(GameRules.maxProductionConceptsPerScript, studioScript.GetSubScriptCount() - studioScript.GetProductionsCount())
			Else
				minConceptLimit = Min(GameRules.maxProductionConceptsPerScript, studioScript.CanGetProducedCount())
			EndIf

			guiListDeskProductionConcepts.SetItemLimit( minConceptLimit )
		Else
			guiListDeskProductionConcepts.SetItemLimit( 0 )
		EndIf

		'studio list
		If studioScript And Not guiListStudio.ContainsScript(studioScript)
			'try to fill in our list
			If guiListStudio.getFreeSlot() >= 0
				Local block:TGUIStudioScript = New TGUIStudioScript.CreateWithScript(studioScript)

				'change look
				block.InitAssets(block.getAssetName(-1, False), block.getAssetName(-1, True))

				guiListStudio.addItem(block, "-1")

				'we deleted the dragged scripts before - now drag the new
				'instances again -> so they keep their "ghost information"
				If draggedScripts.contains(studioScript) Then block.Drag()
			Else
				TLogger.Log("Studio.RefreshGuiElements", "script exists but does not fit in GuiListNormal - script removed.", LOG_ERROR)
				RemoveCurrentStudioScript(roomGUID)
			EndIf
		EndIf

		'create missing gui elements for the players suitcase scripts
		For Local script:TScript = EachIn programmeCollection.suitcaseScripts
			If guiListSuitcase.ContainsScript(script) Then Continue

			Local block:TGUIStudioScript = New TGUIStudioScript.CreateWithScript(script)
			'change look
			block.InitAssets(block.getAssetName(-1, True), block.getAssetName(-1, True))

			guiListSuitcase.addItem(block, "-1")

			'we deleted the dragged scripts before - now drag the new
			'instances again -> so they keep their "ghost information"
			If draggedScripts.contains(script) Then block.Drag()
		Next


		'=== PRODUCTION CONCEPTS ===

		'studio desk - only if a studio script was set
		If studioScript
			'repair borked up savegames
			if studioScript.GetSubScriptCount() > 0
				For Local subScript:TScript = EachIn studioScript.subScripts
					For Local pc:TProductionConcept = EachIn GetProductionConceptCollection().GetProductionConceptsByScript(subScript)
						if programmeCollection.HasProductionConcept(pc) Then continue
						
						'we also pay back potentially paid deposits
						If pc.IsDepositPaid()
							GetPlayerFinance(pc.owner).SellMisc(pc.GetDepositCost())
							TLogger.Log("Studio.RefreshGuiElements", "productionconcept exists but does not fit in guiListDeskProductionConcepts - concept removed and deposit refunded.", LOG_ERROR)
						Else
							TLogger.Log("Studio.RefreshGuiElements", "productionconcept exists but does not fit in guiListDeskProductionConcepts - concept removed.", LOG_ERROR)
						EndIf
						'remove from player's collection and also from global
						'conception list
						programmeCollection.DestroyProductionConcept(pc)
					Next
				Next
			endif

		
			'try to fill in our list
			For Local pc:TProductionConcept = EachIn programmeCollection.GetProductionConcepts()
				'skip ones that are already started (and possibly even finished)
				If pc.IsProductionStarted() Then Continue

				'show episodes
				If studioScript.IsSeries()
					If pc.script.parentScriptID  <> studioScript.GetID() Then Continue
				'or single production concepts
				Else
					If pc.script <> studioScript Then Continue
				EndIf

				If guiListDeskProductionConcepts.ContainsProductionConcept(pc) Then Continue

				If guiListDeskProductionConcepts.getFreeSlot() >= 0

					'try to place it at the slot we defined before
					Local block:TGuiProductionConceptListItem = New TGuiProductionConceptListItem.CreateWithProductionConcept(pc)
					guiListDeskProductionConcepts.addItem(block, String(pc.studioSlot))

					'we deleted the dragged concept before - now drag
					'the new instances again -> so they keep their "ghost
					'information"
					If draggedProductionConcepts.contains(pc) Then block.Drag()
				Else
					'we also pay back potentially paid deposits
					If pc.IsDepositPaid()
						GetPlayerFinance(pc.owner).SellMisc(pc.GetDepositCost())
						TLogger.Log("Studio.RefreshGuiElements", "productionconcept exists but does not fit in guiListDeskProductionConcepts - concept removed and deposit refunded.", LOG_ERROR)
					Else
						TLogger.Log("Studio.RefreshGuiElements", "productionconcept exists but does not fit in guiListDeskProductionConcepts - concept removed.", LOG_ERROR)
					EndIf
					'remove from player's collection and also from global
					'conception list
					programmeCollection.DestroyProductionConcept(pc)
				EndIf
			Next
		EndIf

		haveToRefreshGuiElements = False
	End Method


	Function onClickStartProduction(data:TData)
		If Not TFigure(GetPlayerBase().GetFigure()).inRoom Then Return

		Local roomID:Int = TFigure(GetPlayerBase().GetFigure()).inRoom.GetID()
		Local script:TScript = TScript(data.Get("script"))
		If Not script Then Return

		Local count:Int = GetProductionManager().StartProductionInStudio(roomID, script)
'print "added "+count+" productions to shoot"

		'leave room now, remove dialogue before
		RoomHandler_Studio.studioManagerDialogue = Null
		GetPlayerBase().GetFigure().LeaveRoom()
	End Function


	Function onClickCreateProductionConcept(data:TData)
		Local script:TScript = TScript(data.Get("script"))
		If Not script Then Return

		CreateProductionConcept(GetPlayerBase().playerID, script)

		'recreate the dialogue (changed list amounts)
		GetInstance().GenerateStudioManagerDialogue()
	End Function


	Function CreateProductionConcept:Int(playerID:Int, script:TScript)
		Local useScript:TScript = script

		'if it is a series, fetch first free episode script
		If script.IsSeries()
			'print "CreateProductionConcept : is series"
			If script.GetEpisodes() = 0 Then Return False
			'print "                        : has episodes"

			For Local subScript:TScript = EachIn script.subScripts
				If subScript.CanGetProduced()
					If subScript.IsSeries() Then Continue
					'already concept created?
					If GetProductionConceptCollection().GetProductionConceptCountByScript(subScript) > 0 Then Continue

					useScript = subScript
					Exit
				EndIf
			Next

			If useScript.IsSeries() Then Return False
		EndIf
		'print "CreateProductionConcept : create... " + useScript.GetTitle()
		local pc:TProductionConcept = GetPlayerProgrammeCollection( playerID ).CreateProductionConcept(useScript)

		'if this not the first concept of a non-series script then append a number
		'to distinguish them
		If script.GetEpisodes() = 0 and not pc.HasCustomTitle()
			Local conceptCount:int = GetProductionConceptCollection().GetProductionConceptCountByScript(script)
			If conceptCount > 1
				'use title of the script to avoid reading in the custom title
				pc.SetCustomTitle( pc.script.GetTitle() + " - #" + conceptCount)
				pc.SetCustomDescription (pc.script.GetDescription())
			EndIf
		EndIf

		Return True
	End Function


	Function SortProductionConceptsBySlotAndEpisode:Int(a:Object, b:Object)
		Local pcA:TProductionConcept = TProductionConcept(a)
		Local pcB:TProductionConcept = TProductionConcept(b)
		If Not pcA Or Not pcA.script Then Return -1
		If Not pcB Or Not pcB.script Then Return 1


		If pcA.studioSlot = -1 And pcB.studioSlot = -1
			'sort by their position in the parent script / episode number
			Return pcA.script.GetEpisodeNumber() - pcB.script.GetEpisodeNumber()
		Else
			Return pcA.studioSlot - pcB.studioSlot
		EndIf

		Return pcA.GetGUID() < pcB.GetGUID()
	End Function


	Method GenerateStudioManagerDialogue(dialogueType:Int = 0)
		If Not TFigure(GetPlayerBase().GetFigure()).inRoom Then Return

		Local roomGUID:String = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()
		Local script:TScript = GetCurrentStudioScript(roomGUID)
		'store first producible concept - it may not be the first script of a series
		Local firstProducibleScript:TScript


		'to calculate the amount of production concepts per script we
		'call the productionconcept collection instead of the player's
		'programmecollection
		Local productionConcepts:TProductionConcept[]
		Local conceptCount:Int = 0
		'how many productions were conceptioned with the script?
		'for series this equals to "episodes of this 'season' produced"
		Local producedConceptCount:Int = 0
		'how many concepts could be created based on the script
		'(for series this means "not yet concepted/produced episodes")
		Local conceptCountMax:Int = 0
		Local produceableConceptCount:Int = 0
		Local produceableConcepts:String = ""


		If script
			'=== PRODUCED CONCEPT COUNT ===
			producedConceptCount = script.GetProductionsCount()

			'=== COLLECT PRODUCEABLE CONCEPTS ===
			productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScript(script, True)

			'sort by slots or guid
			Local list:TList = New TList.FromArray(productionConcepts)
			list.Sort(True, SortProductionConceptsBySlotAndEpisode)
			For Local i:Int = 0 Until list.Count()
				productionConcepts[i] = TProductionConcept(list.ValueAtIndex(i))
			Next

			For Local pc:TProductionConcept = EachIn productionConcepts
				If pc.IsProduceable()
					If produceableConcepts <> "" Then produceableConcepts :+ ", "
					produceableConceptCount :+ 1
					If pc.script.GetEpisodeNumber() > 0
						produceableConcepts :+ String(pc.script.GetEpisodeNumber())
					Else
						produceableConcepts :+ String(pc.studioSlot)
					EndIf
					If Not firstProducibleScript Then firstProducibleScript = pc.script
				EndIf
			Next

			'prepend "episodes" to episodes-string
			If script.IsSeries() Then produceableConcepts = GetLocale("MOVIE_EPISODES")+" "+produceableConcepts

			conceptCount = productionConcepts.length

			'series?
			If script.GetSubScriptCount() > 0
				conceptCountMax = script.GetSubScriptCount() - producedConceptCount
				'print "conceptCountMax = " + conceptCountMax  +"  script.GetSubScriptCount()=" + script.GetSubScriptCount() + "  producedConceptCount="+producedConceptCount
			Else
				conceptCountMax = script.CanGetProducedCount()
				'print "conceptCountMax = " + conceptCountMax  +"  productionLimit=" + script.productionLimit + "  usedInProductionsCount="+script.usedInProductionsCount
			EndIf
		EndIf


		Local text:String
		'=== SCRIPT HINT ===
		If dialogueType = 2
			text = GetRandomLocale("DIALOGUE_STUDIO_SCRIPT_HINT")
		'=== PRODUCTION CONCEPT HINT ===
		ElseIf dialogueType = 1
			text = GetRandomLocale("DIALOGUE_STUDIO_PRODUCTIONCONCEPT_HINT")

			If Not draggedGuiProductionConcept
				text = "Report to developer: DialogueType 1 while no production concept was dragged on the vendor"
			Else
				Local pc:TProductionConcept = draggedGuiProductionConcept.productionConcept

				if not pc.IsPlanned()
					text = GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_UNPLANNED_FOR_TITLEX").Replace("%TITLE%", pc.GetTitle()) + "~n~n"
				else
					text = GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_INTRO_FOR_TITLEX").Replace("%TITLE%", pc.GetTitle()) + "~n~n"

					'instead of returning the actual values we cluster them to only hand out
					'raw "estimations"
					Local scriptGenreFit:Float = pc.CalculateScriptGenreFit(True)
					'"Nice cast you got there!"
					Local castFit:Float = pc.CalculateCastFit(True)
					'"You know the cast does not like you?!"
					'values from -1 to 1
					Local castSympathy:Float = pc.CalculateCastSympathy(True)

					'"what a bad production company!"
					Local productionCompanyQuality:Float = 0
					If pc.productionCompany Then productionCompanyQuality = pc.productionCompany.GetQuality()
					Local effectiveFocusPoints:Int = pc.CalculateEffectiveFocusPoints()
					Local effectiveFocusPointsRatio:Float = pc.GetEffectiveFocusPointsRatio()

					text = GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_INTRO_FOR_TITLEX").Replace("%TITLE%", pc.GetTitle()) + "~n~n"


					If scriptGenreFit < 0.30
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_SCRIPT_GENRE_BAD")
					ElseIf scriptGenreFit > 0.70
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_SCRIPT_GENRE_GOOD")
					Else
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_SCRIPT_GENRE_AVERAGE")
					EndIf
					text :+ "~n"


					Local castSympathyKey:String
					If castSympathy < - 0.10
						castSympathyKey = "_CASTSYMPATHY_BAD"
					ElseIf castSympathy > 0.50
						castSympathyKey = "_CASTSYMPATHY_GOOD"
					Else
						castSympathyKey = "_CASTSYMPATHY_AVERAGE"
					EndIf

					If castFit < 0.30
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_CAST_BAD" + castSympathyKey)
					ElseIf castFit > 0.70
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_CAST_GOOD" + castSympathyKey)
					Else
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_CAST_AVERAGE" + castSympathyKey)
					EndIf
					text :+ "~n"


					If pc.productionCompany
						If productionCompanyQuality < 0.30
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_PRODUCTIONCOMPANY_BAD")
						ElseIf productionCompanyQuality > 0.70
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_PRODUCTIONCOMPANY_GOOD")
						Else
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_PRODUCTIONCOMPANY_AVERAGE")
						EndIf
						text :+ " "
					EndIf


					If effectiveFocusPointsRatio < 0.30
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_EFFECTIVEFOCUSPOINTSRATIO_BAD")
					ElseIf effectiveFocusPointsRatio> 0.70
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_EFFECTIVEFOCUSPOINTSRATIO_GOOD")
					Else
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CONCEPT_EFFECTIVEFOCUSPOINTSRATIO_AVERAGE")
					EndIf

					'local effectiveFocusPoints:Int = pc.CalculateEffectiveFocusPoints()
				endif
			EndIf

		'=== INFORMATION ABOUT CURRENT PRODUCTION ===
		Else
			If script
				text = GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION")
				text :+"~n~n"

				Local countText:String = conceptCount
				If conceptCountMax > 0 And conceptCountMax < 1000 Then countText = conceptCount + "/" + conceptCountMax

				If conceptCount = 1 And conceptCountMax = 1
					If producedConceptCount = 0
						If script.IsLive()
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_1_PREPRODUCTION_PLANNED")
						Else
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_1_PRODUCTION_PLANNED")
						EndIf
					Else
						If script.IsLive()
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_1_PREPRODUCTION_DONE")
						Else
							text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_1_PRODUCTION_DONE")
						EndIf
					EndIf
				Else
					Local producedCountText:String = producedConceptCount
					If conceptCountMax > 0 Then producedCountText = producedConceptCount + "/" + conceptCountMax
					If script.GetSubScriptCount() > 0 Then producedCountText = producedConceptCount + "/"+script.GetSubScriptCount()

					If script.IsLive()
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_X_PREPRODUCTIONS_PLANNED_AND_Y_PREPRODUCTIONS_DONE").Replace("%X%", countText).Replace("%Y%", producedCountText)
					Else
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_X_PRODUCTIONS_PLANNED_AND_Y_PRODUCTIONS_DONE").Replace("%X%", countText).Replace("%Y%", producedCountText)
					EndIf
				EndIf

				If Not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).CanCreateProductionConcept(script) AND conceptCountMax > GameRules.maxProductionConceptsPerScript
					text :+"~n~n"
					text :+ GetRandomLocale("DIALOGUE_STUDIO_SHOPPING_LIST_LIMIT_REACHED")
				EndIf

				If produceableConceptCount = 0 And conceptCount > 0
					text :+ "~n"
					If script.IsLive()
						text :+ GetRandomLocale("DIALOGUE_STUDIO_YOU_NEED_TO_FINISH_PREPRODUCTION_PLANNING")
					Else
						text :+ GetRandomLocale("DIALOGUE_STUDIO_YOU_NEED_TO_FINISH_PRODUCTION_PLANNING")
					EndIf
				EndIf
				
				local title:String
				if productionConcepts.length = 1
					title = productionConcepts[0].GetTitle()
				else
					title = script.GetTitle()
				endif

				text = text.Replace("%SCRIPTTITLE%", title)
			Else
				text = GetRandomLocale("DIALOGUE_STUDIO_BRING_SOME_SCRIPT")
			EndIf
		EndIf

		text = text.Replace("%PLAYERNAME%", GetPlayerBase().name)


		Local texts:TDialogueTexts[1]
		texts[0] = TDialogueTexts.Create(text)

		If script
			If (dialogueType = 0 or dialogueType = 1)  And produceableConceptCount > 0
				Local answerText:String
				If produceableConceptCount = 1
					If script.IsLive()
						answerText = GetRandomLocale("DIALOGUE_STUDIO_START_PREPRODUCTION")
					Else
						answerText = GetRandomLocale("DIALOGUE_STUDIO_START_PRODUCTION")
					EndIf
				Else
					If script.IsLive()
						answerText = GetRandomLocale("DIALOGUE_STUDIO_START_ALL_X_POSSIBLE_PREPRODUCTIONS").Replace("%X%", produceableConceptCount)
					Else
						texts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_STUDIO_START_NEXT_EPISODE"), -2, Null, onClickStartProduction, New TData.Add("script", firstProducibleScript)))
						answerText = GetRandomLocale("DIALOGUE_STUDIO_START_ALL_X_POSSIBLE_PRODUCTIONS").Replace("%X%", produceableConcepts)
					EndIf
				EndIf
				texts[0].AddAnswer(TDialogueAnswer.Create( answerText, -2, Null, onClickStartProduction, New TData.Add("script", script)))
			EndIf


			If GetPlayerProgrammeCollection( GetPlayerBase().playerID ).CanCreateProductionConcept(script)
				Local answerText:String
				If conceptCount > 0
					answerText = GetRandomLocale("DIALOGUE_STUDIO_ASK_FOR_ANOTHER_SHOPPINGLIST")
				Else
					answerText = GetRandomLocale("DIALOGUE_STUDIO_ASK_FOR_A_SHOPPINGLIST")
				EndIf
				texts[0].AddAnswer(TDialogueAnswer.Create( answerText, -1, Null, onClickCreateProductionConcept, New TData.Add("script", script)))
			EndIf
		EndIf
		texts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_STUDIO_GOODBYE"), -2, Null))


		studioManagerDialogue = New TDialogue
		studioManagerDialogue.AddTexts(texts)

		studioManagerDialogue.SetArea(New TRectangle.Init(115, 30, 440, 120))
		studioManagerDialogue.SetAnswerArea(New TRectangle.Init(200, 225, 355, 45))
		studioManagerDialogue.moveDialogueBalloonStart = 30
		studioManagerDialogue.moveAnswerDialogueBalloonStart = 230
		studioManagerDialogue.answerStartType = "StartDownRight"
		studioManagerDialogue.SetGrow(1,1)
	End Method


	Method DrawDebug(room:TRoom)
		If Not room Then Return
		If Not GetPlayerBaseCollection().IsPlayer(room.owner) Then Return

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(room.owner)

		Local sY:Int = 50
		DrawText("Scripts:", 10, sY);sY:+20
		For Local s:TScript = EachIn programmeCollection.scripts
			DrawText(s.GetTitle(), 30, sY)
			sY :+ 13
		Next
		sY:+5
		DrawText("Studio:", 10, sY);sY:+20
		For Local s:TScript = EachIn programmeCollection.studioScripts
			DrawText(s.GetTitle(), 30, sY)
			sY :+ 13
		Next
		sY:+5
		DrawText("Suitcase:", 10, sY);sY:+20
		For Local s:TScript = EachIn programmeCollection.suitcaseScripts
			DrawText(s.GetTitle(), 30, sY)
			sY :+ 13
		Next
		sY:+5
		DrawText("currentStudioScript:", 10, sY);sY:+20
		If GetCurrentStudioScript(room.GetGUID())
			DrawText(GetCurrentStudioScript(room.GetGUID()).GetTitle(), 30, sY)
		Else
			DrawText("NONE", 30, sY)
		EndIf
	End Method


	'custom draw function for "DrawContent()" call of that list
	Function DrawProductionConceptStudioSlotListContent:Int(guiObject:TGuiObject)
		Local list:TGUIProductionConceptSlotList = TGUIProductionConceptSlotList(guiObject)
		If Not list Then Return False

		Local atPoint:TVec2D = guiObject.GetScreenRect().position
		Local spriteProductionConcept:TSprite = GetSpriteFromRegistry("gfx_studio_productionconcept_0")

		SetAlpha 0.20
		For Local i:Int = 0 Until list._slots.length
			Local item:TGUIObject = list.GetItemBySlot(i)
			If item Then Continue

			Local pos:TVec3D = list.GetSlotCoord(i)
			pos.AddX(list._slotMinDimension.x * 0.5)
			pos.AddY(list._slotMinDimension.y * 0.5)

			spriteProductionConcept.Draw(atPoint.x + pos.x, atPoint.y + pos.y, -1, ALIGN_CENTER_CENTER, 0.7)
		Next
		SetAlpha 1.0
	End Function


	Method onDrawRoom:Int( triggerEvent:TEventBase )
		Local room:TRoom = TRoom(triggerEvent.GetSender())
		If Not room Then Return False
		Local roomGUID:String = room.GetGUID()

		'skip drawing the manager or other things for "empty studios"
		If room.GetOwner() <= 0 Then Return False

		
		'draw room size information
		GetSpriteFromRegistry("gfx_datasheet_icon_roomSize").Draw(GetGraphicsManager().GetWidth() - 48, 20)
		GetBitmapFont("default", 10).DrawBox(GetLocale("ROOM_SIZE").Replace("%SIZE%", ""), GetGraphicsManager().GetWidth() - 100, 8,90,20, sALIGN_RIGHT_TOP, New SColor8(150,150,150), EDrawTextEffect.SHADOW, 0.50)
		GetBitmapFont("default", 22, BOLDFONT).DrawBox(room.GetSize(), GetGraphicsManager().GetWidth() - 100,10,90,39, sALIGN_RIGHT_BOTTOM, New SColor8(180,180,180), EDrawTextEffect.SHADOW, 0.50)

		If studioManagerEntity Then studioManagerEntity.Render()

		GetSpriteFromRegistry("gfx_suitcase_scripts").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'=== HIGHLIGHT INTERACTIONS ===
		'make suitcase/vendor highlighted if needed
		Local highlightSuitcase:Int = False
		Local highlightStudioManager:Int = False
		Local highlightDesk:Int = False
		Local highlightTrashBin:Int = False

		If draggedGuiScript And draggedGuiScript.isDragged()
			If draggedGuiScript.script = GetCurrentStudioScript(roomGUID)
				highlightSuitcase = True
			EndIf
			highlightStudioManager = True
			highlightDesk = True
			highlightTrashBin = True
		EndIf
		
		If draggedGuiProductionConcept and draggedGuiProductionConcept.isDragged()
			highlightTrashBin = True
			highlightStudioManager = True
		EndIf

		If highlightStudioManager Or highlightSuitcase or highlightTrashBin or highlightDesk
			Local oldColA:Float = GetAlpha()
			SetBlend( LightBlend )
			SetAlpha( oldColA * Float(0.4 + 0.2 * Sin(Time.GetAppTimeGone() / 5)) )

			If highlightStudioManager
				If studioManagerEntity Then studioManagerEntity.Render()
			EndIf
			If highlightDesk
				GetSpriteFromRegistry("gfx_studio_deskhint").Draw(710, 325)
			EndIf
			If highlightSuitcase 
				GetSpriteFromRegistry("gfx_suitcase_scripts").Draw(suitcasePos.GetX(), suitcasePos.GetY())
			EndIf
			If highlightTrashBin 
				'DrawRect(140, 330, 76, 59)
				GetSpriteFromRegistry("gfx_studio_trashbin").Draw(trashBinPos.GetX(), trashBinPos.GetY())
			EndIf

			SetAlpha( oldColA )
			SetBlend( AlphaBlend )
		EndIf

		Local roomOwner:Int = TRoom(triggerEvent.GetSender()).owner
		If Not GetPlayerBaseCollection().IsPlayer(roomOwner) Then roomOwner = 0

		GUIManager.Draw( LS_studio, -1000, -1000, GUIMANAGER_TYPES_NONDRAGGED )

		'draw before potential tooltips (and before datasheets)
		If roomOwner And studioManagerDialogue Then studioManagerDialogue.Draw()

		'draw data sheets for scripts or production concepts
		If hoveredGuiScript Then hoveredGuiScript.DrawSheet(365, , 0)
		If hoveredGuiProductionConcept Then hoveredGuiProductionConcept.DrawSheet(365, , 0)

		GUIManager.Draw( LS_studio, -1000, -1000, GUIMANAGER_TYPES_DRAGGED )



		If hoveredGuiScript
			if hoveredGuiScript.IsDragged()
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
'			elseif hoveredGuiScript.script.owner = GetPlayerBase().playerID or (GetPlayerBase().GetFinance().canAfford(hoveredGuiScript.script.GetPrice()) and GetPlayerProgrammeCollection(GetPlayerBase().playerID).CanMoveScriptToSuitcase())
			'set mouse to "hover"
			ElseIf hoveredGuiScript.isDragable() and hoveredGuiScript.isHovered() and (hoveredGuiScript.script.owner = GetPlayerBaseCollection().playerID Or hoveredGuiScript.script.owner <= 0)
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL)
			else
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL, TGameBase.CURSOR_EXTRA_FORBIDDEN)
			endif
		EndIf
		if draggedGuiScript
			if guiListSuitcase.GetScreenRect().containsXY(MouseManager.x, MouseManager.y)
				if not guiListSuitcase.CanDropOnCoord(MouseManager.currentPos)
					GetGameBase().SetCursor(TGameBase.CURSOR_HOLD, TGameBase.CURSOR_EXTRA_FORBIDDEN)
				endif
			endif
		endif


		If TVTDebugInfos
			DrawDebug(TRoom(triggerEvent.GetSender()))
			guiListDeskProductionConcepts.DrawDebug()
		EndIf

		If roomOwner And studioManagerTooltip Then studioManagerTooltip.Render()
	End Method



	Method onUpdateRoom:Int( triggerEvent:TEventBase )
		TFigure(GetPlayerBase().GetFigure()).fromroom = Null

		'no interaction for other players rooms
		If Not IsPlayersRoom(TRoom(triggerEvent.GetSender())) Then Return False


		'mouse over studio manager
		If Not MouseManager.IsLongClicked(1)
'			If THelper.MouseIn(0,100,150,300)
			If THelper.MouseInRect( studioManagerArea.rect )
				If Not studioManagerDialogue
					'generate the dialogue if not done yet
					If MouseManager.IsClicked(1)
						If draggedGuiProductionConcept
							GenerateStudioManagerDialogue(1)

							draggedGuiProductionConcept.dropBackToOrigin()
							draggedGuiProductionConcept = Null
						ElseIf draggedGuiScript
							GenerateStudioManagerDialogue(2)

							draggedGuiScript.dropBackToOrigin()
							draggedGuiScript = Null
						Else
							GenerateStudioManagerDialogue(0)
						EndIf
					EndIf

					'show tooltip of studio manager
					'only show when no dialogue is (or just got) opened
					If Not studioManagerDialogue
						If Not studioManagerTooltip Then studioManagerTooltip = TTooltip.Create(GetLocale("STUDIO_MANAGER"), GetLocale("STUDIO_MANAGER_TOOLTIP"), 150, 160,-1,-1)
						studioManagerTooltip.enabled = 1
						studioManagerTooltip.SetMinTitleAndContentWidth(150)
						studioManagerTooltip.Hover()
					EndIf
				EndIf
			EndIf

			If MouseManager.IsClicked(1) and THelper.MouseIn( trashBinPos.GetIntX(), trashBinPos.GetIntY(), 76, 59)
				Local roomOwner:Int = TRoom(triggerEvent.GetSender()).owner
				Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(roomOwner)
				If programmeCollection
					Local handledC:Int = False
					'do not do a "if ... elseif" as we could even delete
					'both (if for whatever reason we have both dragged
					'simultaneously 
					'Destroy, not just remove (would keep it in the concept collection)
					If draggedGuiProductionConcept and programmeCollection.DestroyProductionConcept(draggedGuiProductionConcept.productionConcept)
						draggedGuiProductionConcept = null

						handledC = True
					EndIf
					
					If draggedGuiScript and programmeCollection.RemoveScript(draggedGuiScript.script, FALSE)
						draggedGuiScript = null
						
						handledC = True
					EndIf
					
					if handledC Then MouseManager.SetClickHandled(1)
				EndIf
			EndIf
		EndIf

		If studioManagerTooltip Then studioManagerTooltip.Update()

		If studioManagerDialogue And studioManagerDialogue.Update() = 0
			studioManagerDialogue = Null
		EndIf
		

		'remove dragged concept list
		If draggedGuiProductionConcept And MouseManager.IsClicked(2)
			'no need to check owner - done at begin of function already
			'If IsPlayersRoom(TRoom(triggerEvent.GetSender())) ...

			Local roomOwner:Int = TRoom(triggerEvent.GetSender()).owner
			Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(roomOwner)

			'Destroy, not just remove (would keep it in the concept collection)
			If programmeCollection and programmeCollection.DestroyProductionConcept(draggedGuiProductionConcept.productionConcept)
				draggedGuiProductionConcept.Remove()
				draggedGuiProductionConcept = null
				haveToRefreshGuiElements = True
			
				'remove right click - to avoid leaving the room
				MouseManager.SetClickHandled(2)
			EndIf
		EndIf


		If studioManagerDialogue And MouseManager.IsClicked(2)
			studioManagerDialogue = Null

			'remove right click - to avoid leaving the room
			'this also handles long clicks
			MouseManager.SetClickHandled(2)
		EndIf


		'delete unused and create new gui elements
		If haveToRefreshGuiElements Then GetInstance().RefreshGUIElements()

		'reset hovered/dragged blocks - will get set automatically on gui-update
		hoveredGuiScript = Null
		draggedGuiScript = Null
		hoveredGuiProductionConcept = Null
		draggedGuiProductionConcept = Null

		GUIManager.Update( LS_studio )
	End Method
End Type




Type TGUIStudioScript Extends TGUIScript
	Field roomSize:Int = -1


    Method Create:TGUIStudioScript(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="") override
		Return TGUIStudioScript( Super.Create(pos, dimension, value) )
	End Method


	Method CreateWithScript:TGUIStudioScript(script:TScript) override
		Return TGUIStudioScript( Super.CreateWithScript(script) )
	End Method
	

	Method GetAssetName:String(genre:Int=-1, dragged:Int=False)
		If Not dragged Then Return "gfx_scripts_0_studiodesk"
		Return Super.GetAssetName(genre, dragged)
	End Method

	
	Method GetStudioRoomSize:Int() override
		If roomSize <= 0
			Local room:TRoomBase = TFigure(GetPlayerBase().GetFigure()).inRoom
			If room
				roomSize = room.GetSize()
			Else
				roomSize = 1 'default to size 1
			EndIf
		EndIf
		Return roomSize
	End Method


	Method IsDragable:Int() override
		'GUI is recreated each time we go into rooms - so we could cache
		'the information
		if GetStudioRoomSize() < script.requiredStudioSize
			Return False
		EndIf
		
		Return Super.IsDragable()
	End Method
End Type