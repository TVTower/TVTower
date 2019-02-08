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
Type RoomHandler_Studio extends TRoomHandler
	'a map containing "roomGUID"=>"script" pairs
	Field studioScriptsByRoom:TMap = CreateMap()

	Global studioManagerDialogue:TDialogue
	Global studioScriptLimit:int = 1

	Global deskGuiListPos:TVec2D = new TVec2D.Init(350,335)
	Global suitcasePos:TVec2D = new TVec2D.Init(520,70)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(19,32)

	Global studioManagerEntity:TSpriteEntity
	Global studioManagerArea:TGUISimpleRect

	Global studioManagerTooltip:TTooltip
	Global placeScriptTooltip:TTooltip

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global guiListStudio:TGUIScriptSlotList
	Global guiListSuitcase:TGUIScriptSlotList
	Global guiListDeskProductionConcepts:TGUIProductionConceptSlotList

	Global hoveredGuiScript:TGUIScript
	Global draggedGuiScript:TGUIScript

	Global hoveredGuiProductionConcept:TGuiProductionConceptListItem
	Global draggedGuiProductionConcept:TGuiProductionConceptListItem

	global LS_studio:TLowerString = TLowerString.Create("studio")

	Global _instance:RoomHandler_Studio
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_Studio()
		if not _instance then _instance = new RoomHandler_Studio
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()
		studioScriptLimit = 1


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		'=== create room elements
		studioManagerEntity = GetSpriteEntityFromRegistry("entity_studio_manager")

		'=== create gui elements if not done yet
		if not guiListStudio
			local spriteScript:TSprite = GetSpriteFromRegistry("gfx_scripts_0")
			local spriteProductionConcept:TSprite = GetSpriteFromRegistry("gfx_studio_productionconcept_0")
			local spriteSuitcase:TSprite = GetSpriteFromRegistry("gfx_scripts_0_dragged")
			guiListStudio = new TGUIScriptSlotList.Create(new TVec2D.Init(730, 300), new TVec2D.Init(17, 52), "studio")
			guiListStudio.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			guiListStudio.SetItemLimit( studioScriptLimit )
			'increase list size by 2 times - makes it easier to drop
			guiListStudio.Resize(2 * spriteScript.area.GetW(), spriteScript.area.GetH() )
			guiListStudio.SetSlotMinDimension(2 * spriteScript.area.GetW(), spriteScript.area.GetH())
			guiListStudio.SetAcceptDrop("TGuiScript")

			guiListSuitcase	= new TGUIScriptSlotlist.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(200,80), "studio")
			guiListSuitcase.SetAutofillSlots(true)
			guiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			guiListSuitcase.SetItemLimit(GameRules.maxScriptsInSuitcase)
			guiListSuitcase.SetEntryDisplacement( 0, 0 )
			guiListSuitcase.SetAcceptDrop("TGuiScript")

			guiListDeskProductionConcepts = new TGUIProductionConceptSlotList.Create(new TVec2D.Init(deskGuiListPos.GetX(), deskGuiListPos.GetY()), new TVec2D.Init(250,80), "studio")
			'make the list items sortable by the player
			guiListDeskProductionConcepts.SetAutofillSlots(False)
			guiListDeskProductionConcepts.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			guiListDeskProductionConcepts.SetItemLimit(GameRules.maxProductionConceptsPerScript)
			guiListDeskProductionConcepts.SetSlotMinDimension(spriteProductionConcept.area.GetW(), spriteProductionConcept.area.GetH())
			guiListDeskProductionConcepts.SetEntryDisplacement( 0, 0 )
			guiListDeskProductionConcepts.SetAcceptDrop("TGuiProductionConceptListItem")
			guiListDeskProductionConcepts._debugMode = True
			guiListDeskProductionConcepts._customDrawContent = DrawProductionConceptStudioSlotListContent


			'default studioManager dimension
			local studioManagerAreaDimension:TVec2D = new TVec2D.Init(150,270)
			local studioManagerAreaPosition:TVec2D = new TVec2D.Init(0,115)
			if studioManagerEntity then studioManagerAreaDimension = studioManagerEntity.area.dimension.copy()
			if studioManagerEntity then studioManagerAreaPosition = studioManagerEntity.area.position.copy()

			studioManagerArea = new TGUISimpleRect.Create(studioManagerAreaPosition, studioManagerAreaDimension, "studio" )
			'studioManager should accept drop - else no recognition
			studioManagerArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)
		endif


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'to react on changes in the programmeCollection (eg. custom script finished)
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.removeScript", onRemoveScriptFromProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.removeScript", onChangeProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.moveScript", onChangeProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.removeProductionConcept", onChangeProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.addProductionConcept", onChangeProgrammeCollection ) ]
		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to studio manager or suitcase
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropScript, "TGuiScript" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProductionConcept, "TGuiProductionConceptListItem" ) ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverScript, "TGuiScript" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverProductionConcept, "TGuiProductionConceptListItem" ) ]
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickScript, "TGuiScript") ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickProductionConcept, "TGuiProductionConceptListItem") ]

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		studioScriptsByRoom.Clear()
		studioManagerDialogue = null
		studioManagerTooltip = null
		placeScriptTooltip = null

		'=== remove obsolete gui elements ===
		if guiListStudio then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("studio", GetInstance())
	End Method


	Method AbortScreenActions:Int()
		local abortedAction:int = False

		if draggedGuiProductionConcept
			'try to drop the concept back
			draggedGuiProductionConcept.dropBackToOrigin()
			draggedGuiProductionConcept = null
			hoveredGuiProductionConcept = null
			abortedAction = True
		endif

		if draggedGuiScript
			'try to drop the licence back
			draggedGuiScript.dropBackToOrigin()
			draggedGuiScript = null
			hoveredGuiScript = null
			abortedAction = True
		endif

		'Try to drop back dragged elements
		For local obj:TGUIScript = eachIn GuiManager.ListDragged.Copy()
			obj.dropBackToOrigin()
			'successful or not - get rid of the gui element
			obj.Remove()
		Next

		return abortedAction
	End Method


	Function GetStudioGUIDByScript:string(script:TScriptBase)
		For local roomGUID:string = EachIn GetInstance().studioScriptsByRoom.Keys()
			if GetInstance().studioScriptsByRoom.ValueForKey(roomGUID) = script then return roomGUID
		Next
		return ""
	End Function


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not GameConfig.IsObserved(figure) and GetPlayerBase().GetFigure() <> figure Then Return False

		'empty the guilist / delete gui elements so they can get rebuild
		RemoveAllGuiElements()

		'remove potential old dialogues
		studioManagerDialogue = null

		'enable/disable gui elements according to room owner
		'"only our player" filter already done before
		if IsRoomOwner(figure, TRoom(triggerEvent.GetSender()))
			guiListSuitcase.Enable()
			guiListStudio.Enable()
		else
			guiListSuitcase.Disable()
			guiListStudio.Disable()
		endif
	End Method


	Function onRemoveScriptFromProgrammeCollection:int( triggerEvent:TEventBase )
		local script:TScriptBase = TScriptBase( triggerEvent.GetData().Get("script") )
		if not script then return False

		local roomGUID:string = GetStudioGUIDByScript(script)
		if roomGUID
			GetInstance().RemoveCurrentStudioScript(roomGUID)

			'refresh gui if player is in room
			if CheckPlayerInRoom("studio")
				haveToRefreshGuiElements = True
			endif
		endif
	End Function


	'if players are in a studio during changes in their programme
	'collection, react to it...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		'instead of directly refreshing, we just set the dirty-indicator
		'to true (so it only refreshes once per tick, even with
		'multiple events coming in (add + move)
		haveToRefreshGuiElements = True
	End Function


	'in case of right mouse button click a dragged script is
	'placed at its original spot again
	Function onClickScript:int(triggerEvent:TEventBase)
		if not CheckPlayerInRoom("studio") then return FALSE

		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiScript:TGUIScript= TGUIScript(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiScript or not guiScript.isDragged() then return FALSE

		'remove gui object
		guiScript.remove()
		guiScript = null

		'rebuild at correct spot
		GetInstance().RefreshGuiElements()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
		'also avoid long click (touch screen)
		MouseManager.ResetLongClicked(1)
	End Function


	'in case of right mouse button click a dragged production concept is
	'removed
	Function onClickProductionConcept:int(triggerEvent:TEventBase)
		if not CheckPlayerInRoom("studio") then return FALSE

		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiItem:TGuiProductionConceptListItem= TGuiProductionConceptListItem(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiItem or not guiItem.isDragged() then return FALSE


'		if not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).DestroyProductionConcept(guiItem.productionConcept)
'			TLogger.log("Studio.onClickProductionConcept", "Not able to destroy production concept: "+guiItem.productionConcept.GetGUID()+"  " +guiItem.productionConcept.script.GetTitle(), LOG_ERROR)
'		endif

		'remove gui object
		guiItem.remove()
		guiItem = null

		'rebuild elements (also resets hovered/dragged)
		GetInstance().RefreshGuiElements()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
		'also avoid long click (touch screen)
		MouseManager.ResetLongClicked(1)
	End Function


	Function onMouseOverScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		local item:TGUIScript = TGUIScript(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiScript = item
		if item.isDragged() then draggedGuiScript = item

		return TRUE
	End Function


	Function onMouseOverProductionConcept:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		local item:TGuiProductionConceptListItem = TGuiProductionConceptListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProductionConcept = item
		if item.isDragged() then draggedGuiProductionConcept = item

		return TRUE
	End Function


	Function onDropScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		local guiBlock:TGUIScript = TGUIScript( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE

		'try to get a list out of the drag-source-guiobject
		local source:TGuiObject = TGuiObject(triggerEvent.GetData().Get("source"))
		local sourceList:TGUIScriptSlotList
		if source
			local sourceParent:TGUIobject = source._parent
			if TGUIPanel(sourceParent) then sourceParent = TGUIPanel(sourceParent)._parent
			sourceList = TGUIScriptSlotList(sourceParent)
		endif
		'only interested in drops FROM a list
		if not sourceList then return FALSE

		'assign the dropped script as the current one
		local roomGUID:string = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()


		'alternatively TGUIGameListItems contain "lastListID" which
		'is the id of the last list they there attached too
		'if guiBlock.lastListID = guiListSuitcase._id ... and so on

		'ATTENTION: senderList (parent of the parent of guiBlock) is
		'           only correct when NOT dropping on another list
		'           -> so we use sourceList

		'dropping to studio/studiomanager
		'(this includes "switching" guiblocks on the studio list)
		if receiver = guiListStudio or receiver = studioManagerArea
			GetInstance().SetCurrentStudioScript(guiBlock.script, roomGUID)
		endif

		'dropping to suitcase from studio list (important!)
		if receiver = guiListSuitcase and sourceList = guiListStudio
			'remove the script as the current one
			if GetInstance().GetCurrentStudioScript(roomGUID) = guiBlock.script
				GetInstance().RemoveCurrentStudioScript(roomGUID)
			endif
		endif

		'remove gui block, it will get recreated if needed
		'(and it then will have the correct assets assigned)
		guiBlock.remove()
		guiBlock = null
		GetInstance().RefreshGuiElements()

		'remove an old dialogue, it might be different now
		studioManagerDialogue = null

		return TRUE
	End Function


	Function onDropProductionConcept:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("studio") then return FALSE

		local guiBlock:TGuiProductionConceptListItem = TGuiProductionConceptListItem( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE

		local receiverList:TGUIProductionConceptSlotList = TGUIProductionConceptSlotList(TGUIListBase.FindGUIListBaseParent(receiver))
		'only interested in drops to the list
		if not receiverList then return FALSE


		'save order of concepts
		For local i:int = 0 until guiListDeskProductionConcepts._slots.length
			guiBlock = TGuiProductionConceptListItem(guiListDeskProductionConcepts.GetItemBySlot(i))
			if not guiBlock then continue

			guiBlock.productionConcept.studioSlot = i
		Next

		return TRUE
	End Function


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'handle interactivity for room owners
		if IsRoomOwner(figure, TRoom(triggerEvent.GetReceiver()))
			'if the manager dialogue is open - just close the dialogue and
			'veto against leaving the room
			if studioManagerDialogue
				studioManagerDialogue = null

				triggerEvent.SetVeto()
				return FALSE
			endif

			'do not allow leaving as long as we have a dragged block
			if draggedGuiProductionConcept or draggedGuiScript
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	Method SetCurrentStudioScript:int(script:TScript, roomGUID:string)
		if not script or not roomGUID then return False

		'remove old script if there is one
		'-> this makes them available again
		RemoveCurrentStudioScript(roomGUID)

		studioScriptsByRoom.Insert(roomGUID, script)

		'remove from suitcase list
		if GetPlayerBaseCollection().IsPlayer(script.owner)
			GetPlayerProgrammeCollection(script.owner).MoveScriptFromSuitcaseToStudio(script)
		endif

		return True
	End Method


	Method RemoveCurrentStudioScript:int(roomGUID:string)
		if not roomGUID then return False

		local script:TScript = GetCurrentStudioScript(roomGUID)
		if not script then return False


		If GetPlayerBaseCollection().IsPlayer(script.owner)
			local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(script.owner)

			'if players suitcase has enough space for the script, add
			'it to there, else add to archive
			if pc.CanMoveScriptToSuitcase()
				pc.MoveScriptFromStudioToSuitcase(script)
			else
				pc.MoveScriptFromStudioToArchive(script)
			endif
		endif

		return studioScriptsByRoom.Remove(roomGUID)
	End Method


	Method GetCurrentStudioScript:TScript(roomGUID:string)
		if not roomGUID then return Null

		return TScript(studioScriptsByRoom.ValueForKey(roomGUID))
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		guiListStudio.EmptyList()
		guiListSuitcase.EmptyList()
		guiListDeskProductionConcepts.EmptyList()

		For local guiScript:TGUIScript = eachin GuiManager.listDragged.Copy()
			guiScript.remove()
			guiScript = null
		Next

		For local guiConcept:TGuiProductionConceptListItem = eachin GuiManager.listDragged.Copy()
			guiConcept.remove()
			guiConcept = null
		Next

		hoveredGuiScript = null
		draggedGuiScript = null
		draggedGuiProductionConcept = null
		hoveredGuiProductionConcept = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with scripts the player does no longer have

		'1) refresh gui elements for the player who owns the room, not
		'   the active player!
		'2) player should be ALWAYS inRoom when "RefreshGuiElements()"
		'   is called
		local roomOwner:int
		local roomGUID:string
		If TFigure(GetPlayerBase().GetFigure()).inRoom
			roomOwner = TFigure(GetPlayerBase().GetFigure()).inRoom.owner
			roomGUID = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()
		EndIf
		if not roomOwner or not roomGUID then return False

		'helper vars
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(roomOwner)

		'=== REMOVE SCRIPTS ===

		'dragged scripts
		local draggedScripts:TList = CreateList()
		For local guiScript:TGUIScript = EachIn GuiManager.listDragged.Copy()
			draggedScripts.AddLast(guiScript.script)
			'remove the dragged guiscript, gets replaced by a new
			'instance
			guiScript.Remove()
		Next

		'suitcase
		For local guiScript:TGUIScript = eachin GuiListSuitcase._slots
			'if the player has this script in suitcase or list, skip deletion
			if programmeCollection.HasScript(guiScript.script) then continue
			if programmeCollection.HasScriptInSuitcase(guiScript.script) then continue
			guiScript.remove()
			guiScript = null
		Next

		'studio list
		For local guiScript:TGUIScript = eachin guiListStudio._slots
			if GetCurrentStudioScript(roomGUID) <> guiScript.script
				guiScript.remove()
				guiScript = null
			endif
		Next


		'=== REMOVE PRODUCTION CONCEPTS ===

		'dragged ones
		local draggedProductionConcepts:TList = CreateList()
		For local guiProductionConcept:TGuiProductionConceptListItem = EachIn GuiManager.listDragged.Copy()
			draggedProductionConcepts.AddLast(guiProductionConcept.productionConcept)
			'remove the dragged one, gets replaced by a new instance
			guiProductionConcept.Remove()
		Next

		'desk production concepts
		For local guiProductionConcept:TGuiProductionConceptListItem = eachin guiListDeskProductionConcepts._slots
			'if the concept is for the current set script, skip deletion
			if guiProductionConcept.productionConcept.script = GetCurrentStudioScript(roomGUID) then continue

			guiProductionConcept.remove()
			guiProductionConcept = null
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all script-lists

		'=== SCRIPTS ===

		'studio concept list
		local studioScript:TScript = GetCurrentStudioScript(roomGUID)
		if studioScript
			'adjust list limit
			local minConceptLimit:int = 1
			if studioScript.GetSubScriptCount() > 0
				minConceptLimit = Min(GameRules.maxProductionConceptsPerScript, studioScript.GetSubScriptCount() - studioScript.GetProductionsCount())
			else
				minConceptLimit = Min(GameRules.maxProductionConceptsPerScript, studioScript.CanGetProducedCount())
			endif
			guiListDeskProductionConcepts.SetItemLimit( minConceptLimit )
		else
			guiListDeskProductionConcepts.SetItemLimit( 0 )
		endif

		'studio list
		if studioScript and not guiListStudio.ContainsScript(studioScript)
			'try to fill in our list
			if guiListStudio.getFreeSlot() >= 0
				local block:TGUIScript = new TGUIScript.CreateWithScript(studioScript)
				block.studioMode = True
				'change look
				block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

				guiListStudio.addItem(block, "-1")

				'we deleted the dragged scripts before - now drag the new
				'instances again -> so they keep their "ghost information"
				if draggedScripts.contains(studioScript) then block.Drag()
			else
				TLogger.log("Studio.RefreshGuiElements", "script exists but does not fit in GuiListNormal - script removed.", LOG_ERROR)
				RemoveCurrentStudioScript(roomGUID)
			endif
		endif

		'create missing gui elements for the players suitcase scripts
		For local script:TScript = eachin programmeCollection.suitcaseScripts
			if guiListSuitcase.ContainsScript(script) then continue

			local block:TGUIScript = new TGUIScript.CreateWithScript(script)
			block.studioMode = True
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			guiListSuitcase.addItem(block, "-1")

			'we deleted the dragged scripts before - now drag the new
			'instances again -> so they keep their "ghost information"
			if draggedScripts.contains(script) then block.Drag()
		Next


		'=== PRODUCTION CONCEPTS ===

		'studio desk - only if a studio script was set
		if studioScript
			'try to fill in our list
			For local pc:TProductionConcept = EachIn programmeCollection.GetProductionConcepts()
				'skip produced ones
				if pc.IsProduced() then continue

				'show episodes
				if studioScript.IsSeries()
					if pc.script.parentScriptID  <> studioScript.GetID() then continue
				'or single production concepts
				else
					if pc.script <> studioScript then continue
				endif

				if guiListDeskProductionConcepts.ContainsProductionConcept(pc) then continue

				if guiListDeskProductionConcepts.getFreeSlot() >= 0

					'try to place it at the slot we defined before
					local block:TGuiProductionConceptListItem = new TGuiProductionConceptListItem.CreateWithProductionConcept(pc)
					guiListDeskProductionConcepts.addItem(block, string(pc.studioSlot))

					'we deleted the dragged concept before - now drag
					'the new instances again -> so they keep their "ghost
					'information"
					if draggedProductionConcepts.contains(pc) then block.Drag()
				else
					TLogger.log("Studio.RefreshGuiElements", "productionconcept exists but does not fit in guiListDeskProductionConcepts - concept removed.", LOG_ERROR)
					programmeCollection.RemoveProductionConcept(pc)
				endif
			Next
		endif

		haveToRefreshGuiElements = FALSE
	End Method


	Function onClickStartProduction(data:TData)
		if not TFigure(GetPlayerBase().GetFigure()).inRoom then return

		local roomGUID:string = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()
		local script:TScript = TScript(data.Get("script"))
		if not script then return

		local count:int = GetProductionManager().StartProductionInStudio(roomGUID, script)
'print "added "+count+" productions to shoot"

		'leave room now, remove dialogue before
		RoomHandler_Studio.studioManagerDialogue = null
		GetPlayerBase().GetFigure().LeaveRoom()
	End Function


	Function onClickCreateProductionConcept(data:TData)
		local script:TScript = TScript(data.Get("script"))
		if not script then return

		CreateProductionConcept(GetPlayerBase().playerID, script)

		'recreate the dialogue (changed list amounts)
		GetInstance().GenerateStudioManagerDialogue()
	End Function


	Function CreateProductionConcept:int(playerID:int, script:TScript)
		local useScript:TScript = script

		'if it is a series, fetch first free episode script
		if script.IsSeries()
			'print "CreateProductionConcept : is series"
			if script.GetEpisodes() = 0 then return False
			'print "                        : has episodes"

			for local subScript:TScript = EachIn script.subScripts
				if subScript.CanGetProduced()
					if subScript.IsSeries() then continue
					'already concept created?
					if GetProductionConceptCollection().GetProductionConceptsByScript(subScript).length > 0 then continue

					useScript = subScript
					exit
				endif
			Next

			if useScript.IsSeries() then return False
		endif
		'print "CreateProductionConcept : create... " + useScript.GetTitle()
		GetPlayerProgrammeCollection( playerID ).CreateProductionConcept(useScript)


		return True
	End Function


	Function SortProductionConceptsBySlotAndEpisode:int(a:object, b:object)
		local pcA:TProductionConcept = TProductionConcept(a)
		local pcB:TProductionConcept = TProductionConcept(b)
		if not pcA or not pcA.script then return -1
		if not pcB or not pcB.script then return 1


		if pcA.studioSlot = -1 and pcB.studioSlot = -1
			'sort by their position in the parent script / episode number
			return pcA.script.GetEpisodeNumber() - pcB.script.GetEpisodeNumber()
		else
			return pcA.studioSlot - pcB.studioSlot
		endif

		return pcA.GetGUID() < pcB.GetGUID()
	End Function


	Method GenerateStudioManagerDialogue(dialogueType:int = 0)
		if not TFigure(GetPlayerBase().GetFigure()).inRoom then return

		local roomGUID:string = TFigure(GetPlayerBase().GetFigure()).inRoom.GetGUID()
		local script:TScript = GetCurrentStudioScript(roomGUID)


		'to calculate the amount of production concepts per script we
		'call the productionconcept collection instead of the player's
		'programmecollection
		local productionConcepts:TProductionConcept[]
		local conceptCount:int = 0
		local producedConceptCount:int = 0
		local conceptCountMax:int = 0
		local produceableConceptCount:int = 0
		local produceableConcepts:string = ""


		if script
			'=== PRODUCED CONCEPT COUNT ===
			producedConceptCount = script.GetProductionsCount()


			'=== COLLECT PRODUCEABLE CONCEPTS ===
			if script.GetSubScriptCount() > 0
				productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScripts(script.subScripts)
			else
				productionConcepts = GetProductionConceptCollection().GetProductionConceptsByScript(script)
			endif

			'sort by slots or guid
			local list:TList = new TList.FromArray(productionConcepts)
			list.Sort(True, SortProductionConceptsBySlotAndEpisode)
			for local i:int = 0 until list.Count()
				productionConcepts[i] = TProductionConcept(list.ValueAtIndex(i))
			Next

			For local pc:TProductionConcept = EachIn productionConcepts
				if pc.IsProduceable()
					if produceableConcepts <> "" then produceableConcepts :+ ", "
					produceableConceptCount :+ 1
					if pc.script.GetEpisodeNumber() > 0
						produceableConcepts :+ string(pc.script.GetEpisodeNumber())
					else
						produceableConcepts :+ string(pc.studioSlot)
					endif
				endif
			Next

			'prepend "episodes" to episodes-string
			if script.IsSeries() then produceableConcepts = GetLocale("MOVIE_EPISODES")+" "+produceableConcepts

			conceptCount = productionConcepts.length

			'series?
			if script.GetSubScriptCount() > 0
				conceptCountMax = script.GetSubScriptCount() - producedConceptCount
			else
				conceptCountMax = script.CanGetProducedCount()
			endif
		endif


		local text:string
		'=== SCRIPT HINT ===
		if dialogueType = 2
			text = GetRandomLocale("DIALOGUE_STUDIO_SCRIPT_HINT")
		'=== PRODUCTION CONCEPT HINT ===
		elseif dialogueType = 1
			text = GetRandomLocale("DIALOGUE_STUDIO_PRODUCTIONCONCEPT_HINT")
		'=== INFORMATION ABOUT CURRENT PRODUCTION ===
		else
			if script
				text = GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION")
				text :+"~n~n"

				local countText:string = conceptCount
				if conceptCountMax > 0 and conceptCountMax < 1000 then countText = conceptCount + "/" + conceptCountMax

				if conceptCount = 1 and conceptCountMax = 1
					if producedConceptCount = 0
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_1_PRODUCTION_PLANNED")
					else
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_1_PRODUCTION_DONE")
					endif
				else
					if producedConceptCount = 0
						text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_X_PRODUCTIONS_DONE").replace("%X%", countText)
					else
						local producedCountText:string = producedConceptCount
						if conceptCountMax > 0 then producedCountText = producedConceptCount + "/" + conceptCountMax
						if script.GetSubScriptCount() > 0 then producedCountText = producedConceptCount + "/"+script.GetSubScriptCount()

						text :+ GetRandomLocale("DIALOGUE_STUDIO_CURRENTPRODUCTION_INFORMATION_X_PRODUCTIONS_PLANNED_AND_Y_PRODUCTIONS_DONE").replace("%X%", countText).replace("%Y%", producedCountText)
					endif
				endif
				if not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).CanCreateProductionConcept(script)
					text :+"~n~n"
					text :+ GetRandomLocale("DIALOGUE_STUDIO_SHOPPING_LIST_LIMIT_REACHED")
				endif

				if produceableConceptCount = 0 and conceptCount > 0
					text :+ "~n"
					text :+ GetRandomLocale("DIALOGUE_STUDIO_YOU_NEED_TO_FINISH_PRODUCTION_PLANNING")
				endif

				text = text.replace("%SCRIPTTITLE%", script.GetTitle())
			else
				text = GetRandomLocale("DIALOGUE_STUDIO_BRING_SOME_SCRIPT")
			endif
		endif

		text = text.replace("%PLAYERNAME%", GetPlayerBase().name)


		local texts:TDialogueTexts[1]
		texts[0] = TDialogueTexts.Create(text)

		if script
			if dialogueType = 0 and produceableConceptCount > 0
				local answerText:string
				if produceableConceptCount = 1
					answerText = GetRandomLocale("DIALOGUE_STUDIO_START_PRODUCTION")
				else
					answerText = GetRandomLocale("DIALOGUE_STUDIO_START_ALL_X_POSSIBLE_PRODUCTIONS").Replace("%X%", produceableConcepts)
				endif
				texts[0].AddAnswer(TDialogueAnswer.Create( answerText, -2, null, onClickStartProduction, new TData.Add("script", script)))
			endif

			'limit concepts: shows have none, programmes 1 and series
			'are limited by their episodes
			local conceptMax:int
			if script.GetSubScriptCount() > 0
				conceptMax = script.GetSubScriptCount() - script.GetProductionsCount()
			else
				conceptMax = script.CanGetProducedCount()
			endif

			If conceptCount < conceptCountMax
				local answerText:string
				if conceptCount > 0
					answerText = GetRandomLocale("DIALOGUE_STUDIO_ASK_FOR_ANOTHER_SHOPPINGLIST")
				else
					answerText = GetRandomLocale("DIALOGUE_STUDIO_ASK_FOR_A_SHOPPINGLIST")
				endif
				texts[0].AddAnswer(TDialogueAnswer.Create( answerText, -1, null, onClickCreateProductionConcept, new TData.Add("script", script)))
			endif
		endif
		texts[0].AddAnswer(TDialogueAnswer.Create( GetRandomLocale("DIALOGUE_STUDIO_GOODBYE"), -2, Null))


		studioManagerDialogue = new TDialogue
		studioManagerDialogue.AddTexts(texts)

		studioManagerDialogue.SetArea(new TRectangle.Init(150, 40, 400, 120))
		studioManagerDialogue.SetAnswerArea(new TRectangle.Init(200, 180, 320, 45))
		studioManagerDialogue.moveAnswerDialogueBalloonStart = 240
		studioManagerDialogue.answerStartType = "StartDownRight"
		studioManagerDialogue.SetGrow(1,1)

	End Method


	Method DrawDebug(room:TRoom)
		if not room then return
		if not GetPlayerBaseCollection().IsPlayer(room.owner) then return

		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(room.owner)

		local sY:int = 50
		DrawText("Scripts:", 10, sY);sY:+20
		For local s:TScript = EachIn programmeCollection.scripts
			DrawText(s.GetTitle(), 30, sY)
			sY :+ 13
		Next
		sY:+5
		DrawText("Studio:", 10, sY);sY:+20
		For local s:TScript = EachIn programmeCollection.studioScripts
			DrawText(s.GetTitle(), 30, sY)
			sY :+ 13
		Next
		sY:+5
		DrawText("Suitcase:", 10, sY);sY:+20
		For local s:TScript = EachIn programmeCollection.suitcaseScripts
			DrawText(s.GetTitle(), 30, sY)
			sY :+ 13
		Next
		sY:+5
		DrawText("currentStudioScript:", 10, sY);sY:+20
		if GetCurrentStudioScript(room.GetGUID())
			DrawText(GetCurrentStudioScript(room.GetGUID()).GetTitle(), 30, sY)
		else
			DrawText("NONE", 30, sY)
		endif
	End Method


	'custom draw function for "DrawContent()" call of that list
	Function DrawProductionConceptStudioSlotListContent:int(guiObject:TGuiObject)
		Local list:TGUIProductionConceptSlotList = TGUIProductionConceptSlotList(guiObject)
		if not list then return False

		Local atPoint:TVec2D = guiObject.GetScreenPos()
		local spriteProductionConcept:TSprite = GetSpriteFromRegistry("gfx_studio_productionconcept_0")

		SetAlpha 0.20
		For Local i:Int = 0 until list._slots.length
			local item:TGUIObject = list.GetItemBySlot(i)
			if item then continue

			local pos:TVec3D = list.GetSlotCoord(i)
			pos.AddX(list._slotMinDimension.x * 0.5)
			pos.AddY(list._slotMinDimension.y * 0.5)

			spriteProductionConcept.Draw(atPoint.x + pos.x, atPoint.y + pos.y, -1, ALIGN_CENTER_CENTER, 0.7)
		Next
		SetAlpha 1.0
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom(triggerEvent.GetSender())
		if not room then return False
		local roomGUID:string = room.GetGUID()

		'skip drawing the manager or other things for "empty studios"
		if room.GetOwner() <= 0 then return False

		if studioManagerEntity then studioManagerEntity.Render()

		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'=== HIGHLIGHT INTERACTIONS ===
		'make suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightStudioManager:int = False

		if draggedGuiScript and draggedGuiScript.isDragged()
			if draggedGuiScript.script = GetCurrentStudioScript(roomGUID)
				highlightSuitcase = True
			else
				highlightStudioManager = True
			endif
		endif

		if highlightStudioManager or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * sin(Time.GetAppTimeGone() / 5))

			if highlightStudioManager
				if studioManagerEntity then studioManagerEntity.Render()
				GetSpriteFromRegistry("gfx_studio_deskhint").Draw(710, 325)
			endif
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif

		local roomOwner:int = TRoom(triggerEvent.GetSender()).owner
		if not GetPlayerBaseCollection().IsPlayer(roomOwner) then roomOwner = 0

		GUIManager.Draw( LS_studio )

		'draw data sheets for scripts or production concepts
		if not studioManagerDialogue
			if hoveredGuiScript then hoveredGuiScript.DrawSheet()
			if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSheet()
		endif

		if TVTDebugInfos
			DrawDebug(TRoom(triggerEvent.GetSender()))
			guiListDeskProductionConcepts.DrawDebug()
		endif

		'draw after potential tooltips
		if roomOwner and studioManagerDialogue then studioManagerDialogue.Draw()

		if roomOwner and studioManagerTooltip then studioManagerTooltip.Render()
	End Method



	Method onUpdateRoom:int( triggerEvent:TEventBase )
		TFigure(GetPlayerBase().GetFigure()).fromroom = Null

		'no interaction for other players rooms
		if not IsPlayersRoom(TRoom(triggerEvent.GetSender())) then return False

		'mouse over studio manager
		if not MouseManager.IsLongClicked(1)
			if THelper.MouseIn(0,100,150,300)
				if not studioManagerDialogue
					'generate the dialogue if not done yet
					if MouseManager.IsClicked(1)
						if draggedGuiProductionConcept
'							draggedGuiProductionConcept.dropBackToOrigin()
'							draggedGuiProductionConcept = null

'							GenerateStudioManagerDialogue(1)
						elseif draggedGuiScript
							draggedGuiScript.dropBackToOrigin()
							draggedGuiScript = null

							GenerateStudioManagerDialogue(2)
						else
							GenerateStudioManagerDialogue(0)
						endif
					endif

					'show tooltip of studio manager
					'only show when no dialogue is (or just got) opened
					if not studioManagerDialogue
						If not studioManagerTooltip Then studioManagerTooltip = TTooltip.Create(GetLocale("STUDIO_MANAGER"), GetLocale("STUDIO_MANAGER_TOOLTIP"), 150, 160,-1,-1)
						studioManagerTooltip.enabled = 1
						studioManagerTooltip.SetMinTitleAndContentWidth(150)
						studioManagerTooltip.Hover()
					endif
				endif
			endif
		endif

		If studioManagerTooltip Then studioManagerTooltip.Update()

		if studioManagerDialogue and studioManagerDialogue.Update() = 0
			studioManagerDialogue = null
		endif


		GetGameBase().cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered/dragged blocks - will get set automatically on gui-update
		hoveredGuiScript = null
		draggedGuiScript = null
		hoveredGuiProductionConcept = null
		draggedGuiProductionConcept = null

		GUIManager.Update( LS_studio )
	End Method
End Type
