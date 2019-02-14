SuperStrict
Import "game.roomhandler.base.bmx"
Import "game.production.script.gui.bmx"
Import "game.player.programmecollection.bmx"
Import "Dig/base.util.registry.spriteentityloader.bmx"

'Script agency
Type RoomHandler_ScriptAgency extends TRoomHandler
	Global hoveredGuiScript:TGuiScript = null
	Global draggedGuiScript:TGuiScript = null

	Global VendorEntity:TSpriteEntity
	'allows registration of drop-event
	Global VendorArea:TGUISimpleRect

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listNormal:TScript[]
	Field listNormal2:TScript[]

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListNormal:TGUIScriptSlotList[]
	Global GuiListNormal2:TGUIScriptSlotList = null
	Global GuiListSuitcase:TGUIScriptSlotList = null

	global LS_scriptagency:TLowerString = TLowerString.Create("scriptagency")

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(320,270)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(19,32)
	Global scriptsPerLine:int = 1
	Global scriptsNormalAmount:int = 4
	Global scriptsNormal2Amount:int	= 1

	Global _instance:RoomHandler_ScriptAgency
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_ScriptAgency()
		if not _instance then _instance = new RoomHandler_ScriptAgency
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()
		scriptsPerLine = 1
		scriptsNormalAmount = 4
		scriptsNormal2Amount = 1
		listNormal = new TScript[scriptsNormalAmount]
		listNormal2 = new TScript[scriptsNormal2Amount]
		VendorEntity = GetSpriteEntityFromRegistry("entity_scriptagency_vendor")


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		if not GuiListSuitCase
			GuiListNormal = GuiListNormal[..scriptsNormalAmount]
			local sprite:TSprite = GetSpriteFromRegistry("gfx_scripts_0")
			local spriteSuitcase:TSprite = GetSpriteFromRegistry("gfx_scripts_0_dragged")
			for local i:int = 0 to GuiListNormal.length-1
				GuiListNormal[i] = new TGUIScriptSlotList.Create(new TVec2D.Init(233 + (GuiListNormal.length-1 - i)*22, 143 + i*2), new TVec2D.Init(17, sprite.area.GetH()), "scriptagency")
				GuiListNormal[i].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
				GuiListNormal[i].SetItemLimit( scriptsNormalAmount / GuiListNormal.length  )
				GuiListNormal[i].Resize(sprite.area.GetW() * (scriptsNormalAmount / GuiListNormal.length), sprite.area.GetH() )
				GuiListNormal[i].SetSlotMinDimension(sprite.area.GetW(), sprite.area.GetH())
				GuiListNormal[i].SetAcceptDrop("TGuiScript")
				GuiListNormal[i].setZindex(i)
			Next

			GuiListSuitcase	= new TGUIScriptSlotlist.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(175, spriteSuitcase.area.GetH()), "scriptagency")
			GuiListSuitcase.SetAutofillSlots(true)

			'for more than 1 entry
			'GuiListNormal2 = new TGUIScriptSlotlist.Create(new TVec2D.Init(188, 240), new TVec2D.Init(10 + sprite.area.GetW()*scriptsNormal2Amount, sprite.area.GetH()), "scriptagency")
			'GuiListNormal2.setEntriesBlockDisplacement(18, 11)
			GuiListNormal2 = new TGUIScriptSlotlist.Create(new TVec2D.Init(206, 251), new TVec2D.Init(10 + sprite.area.GetW()*scriptsNormal2Amount, sprite.area.GetH()), "scriptagency")

			GuiListNormal2.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

			GuiListNormal2.SetItemLimit(listNormal2.length)
			GuiListSuitcase.SetItemLimit(GameRules.maxScriptsInSuitcase)

			GuiListNormal2.SetSlotMinDimension(sprite.area.GetW(), sprite.area.GetH())
			GuiListSuitcase.SetSlotMinDimension(spriteSuitcase.area.GetW(), spriteSuitcase.area.GetH())

			GuiListNormal2.SetEntryDisplacement( -scriptsNormal2Amount * GuiListNormal[0]._slotMinDimension.x, 5)
			GuiListSuitcase.SetEntryDisplacement( 0, 0 )

			GuiListNormal2.SetAcceptDrop("TGuiScript")
			GuiListSuitcase.SetAcceptDrop("TGuiScript")

			'default vendor dimension
			local vendorAreaDimension:TVec2D = new TVec2D.Init(200,300)
			local vendorAreaPosition:TVec2D = new TVec2D.Init(350,100)
			if VendorEntity then vendorAreaDimension = VendorEntity.area.dimension.copy()
			if VendorEntity then vendorAreaPosition = VendorEntity.area.position.copy()

			VendorArea = new TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "scriptagency" )
			'vendor should accept drop - else no recognition
			VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)
			VendorArea.zIndex = 0

			'must be above vendorArea, as they overlap
			GuiListSuitcase.zIndex = 100
		endif


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'to react on changes in the programmeCollection (eg. custom script finished)
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.addScript", onChangeProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.removeScript", onChangeProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.moveScript", onChangeProgrammeCollection ) ]

		'check if dropping is possible (affordable price for a script dragged when dropping on a one)
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropScript, "TGuiScript" ) ]
		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to vendor or suitcase
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropScript, "TGuiScript" ) ]
		'drop on vendor - sell things
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropScriptOnVendor, "TGuiScript" ) ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverScript, "TGuiScript" ) ]
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickScript, "TGuiScript") ]

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		if GuiListSuitCase then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("scriptagency", GetInstance())
	End Method




	Method AbortScreenActions:Int()
		local abortedAction:int = False
		if draggedGuiScript
			'try to drop the licence back
			draggedGuiScript.dropBackToOrigin()
			draggedGuiScript = null
			hoveredGuiScript = null
			abortedAction = True
		endif

		'change look to "stand on furniture look"
		For local i:int = 0 to GuiListNormal.length-1
			For Local obj:TGUIGameListItem = EachIn GuiListNormal[i]._slots
				obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
			Next
		Next
		For Local obj:TGUIGameListItem = EachIn GuiListNormal2._slots
			obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
		Next

		return abortedAction
	End Method


	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase )
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new contracts are not loaded yet

		'We cannot rely on "onEnterRoom" as we could have saved
		'in this room
		GetInstance().RemoveAllGuiElements()

		haveToRefreshGuiElements = true
	End Method


	'run AFTER the savegame data got loaded
	'handle faulty adcontracts (after data got loaded)
	Method onSaveGameLoad:int( triggerEvent:TEventBase )
		'in the case of being empty (should not happen)
		GetInstance().RefillBlocks()
	End Method


	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure or not figure.playerID then return FALSE


		'=== FOR ALL PLAYERS ===
		'
		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		GetInstance().ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			GetInstance().ResetScriptOrder()
		endif
	End Method


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE


		'=== FOR ALL PLAYERS ===
		'


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'as only 1 player is allowed simultaneously, the limitation
			'to "observed" is not strictly needed - but does not harm

			'do not allow leaving as long as we have a dragged block
			if draggedGuiScript
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		'=== FOR ALL PLAYERS ===
		'


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'add back the scripts from the suitcase?
			'currently this is done when entering the archive room
			'TODO: add wayback option, for now this is disabled in the
			'      archive room
		endif


		return TRUE
	End Method



	'===================================
	'Script Agency: common Functions
	'===================================

	Method GetScriptsInStock:TList()
		Local ret:TList = CreateList()
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				If script Then ret.addLast(script)
			Next
		Next
		return ret
	End Method


	Method GetScriptsInStockCount:int()
		Local ret:Int = 0
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				If script Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetScriptByPosition:TScript(position:int)
		'no need do check that twice...
		'if position > GetScriptsInStockCount() then return null
		local currentPosition:int = 0
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				if script
					if currentPosition = position then return script
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasScript:int(script:TScript)
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local s:TScript = EachIn lists[j]
				if s = script then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetScriptByID:TScript(scriptID:int)
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For Local script:TScript = EachIn lists[j]
				if script and script.id = scriptID then return script
			Next
		Next
		return null
	End Method


	Method SellScriptToPlayer:int(script:TScript, playerID:int, skipOwnerCheck:int = False)
		if script.owner = playerID and not skipOwnerCheck then return FALSE

		if not GetPlayerBaseCollection().IsPlayer(playerID) then return FALSE

		local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if pc.CanMoveScriptToSuitcase()
			'try to add to player (buying)
			if pc.AddScript(script, TRUE)
				'try to move it to the suitcase
				pc.AddScriptToSuitcase(script)
			endif
		endif

		'remove from agency's lists
		RemoveScript(script)

		return TRUE
	End Method


	Method BuyScriptFromPlayer:int(script:TScript)
		'remove from player (lists and suitcase) - and give him money
		if GetPlayerBaseCollection().IsPlayer(script.owner)
			local pc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(script.owner)
			'try to remove it from the suitcase
			if pc.RemoveScriptFromSuitcase(script)
				'sell it
				pc.RemoveScript(script, TRUE)
			endif
		endif

		'add to agency's lists - if not existing yet
		if not HasScript(script) then AddScript(script)

		return TRUE
	End Method


	Method ResetScriptOrder:int()
		local scripts:TList = CreateList()
		for local script:TScript = eachin listNormal
			scripts.addLast(script)
		Next
		for local script:TScript = eachin listNormal2
			scripts.addLast(script)
		Next
		listNormal = new TScript[listNormal.length]
		listNormal2 = new TScript[listNormal2.length]

		scripts.sort()

		'add again - so it gets sorted
		for local script:TScript = eachin scripts
			AddScript(script)
		Next

		RemoveAllGuiElements()
	End Method


	Method RemoveScript:int(script:TScript)
		local foundScript:int = FALSE
		'remove from agency's lists
		local lists:TScript[][] = [listNormal,listNormal2]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = script
					lists[j][i] = null
					foundScript = True
				endif
			Next
		Next

		return foundScript
	End Method


	Method AddScript:int(script:TScript)
		'try to fill the script into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TScript[][]

		lists = [listNormal,listNormal2]

		'loop through all lists - as soon as we find a spot
		'to place the script - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				GetScriptCollection().SetScriptOwner(script, TOwnedGameObject.OWNER_VENDOR)
				lists[j][i] = script
				return TRUE
			Next
		Next

		'there was no empty slot to place that script
		'so just give it back to the pool
		GetScriptCollection().SetScriptOwner(script, TOwnedGameObject.OWNER_NOBODY)

		return FALSE
	End Method



	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		For local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i].EmptyList()
		Next
		GuiListNormal2.EmptyList()
		GuiListSuitcase.EmptyList()
		For local guiScript:TGUIScript = eachin GuiManager.listDragged.Copy()
			guiScript.remove()
			guiScript = null
		Next

		hoveredGuiScript = null
		draggedGuiScript = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements_Suitcase:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the player does not have any longer
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(GetPlayerBase().playerID)
		For local guiScript:TGUIScript = eachin GuiListSuitcase._slots
			'if the player has this script in suitcase or list, skip deletion
			if programmeCollection.HasScript(guiScript.script) then continue
			if programmeCollection.HasScriptInSuitcase(guiScript.script) then continue

			guiScript.remove()
			guiScript = null
		Next


		'===== CREATE NEW =====
		'create missing gui elements for the players suitcase scripts
		For local script:TScript = eachin programmeCollection.suitcaseScripts
			if guiListSuitcase.ContainsScript(script) then continue
			local block:TGUIScript = new TGUIScript.CreateWithScript(script)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "ADD guiListSuitcase missed new script: "+block.script.id

			guiListSuitcase.addItem(block, "-1")
		Next
	End Method


	Method RefreshGuiElements_Vendor:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the vendor does not have any longer
		For local i:int = 0 to GuiListNormal.length-1
			For local guiScript:TGUIScript = eachin GuiListNormal[i]._slots
				if not HasScript(guiScript.script)
					guiScript.remove()
					guiScript = null
				endif
			Next
		Next
		For local guiScript:TGUIScript = eachin GuiListNormal2._slots
			if not HasScript(guiScript.script)
				guiScript.remove()
				guiScript = null
			endif
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all contract-lists

		'normal list
		For local script:TScript = eachin listNormal
			if not script then continue

			'search the script in all of our lists...
			local scriptFound:int = FALSE
			For local i:int = 0 to GuiListNormal.length-1
				if scriptFound then continue
				if GuiListNormal[i].ContainsScript(script) then scriptFound = True
			Next
			if GuiListNormal2.ContainsScript(script) then scriptFound = True

			'go to next script if the script is already stored in the
			'gui list
			if scriptFound then continue

			'first try to add to the guiListNormal-array, then guiListNormal2
			if not AddScriptToVendorGuiLists(script, GuiListNormal + [GuiListNormal2])
				TLogger.log("ScriptAgency.RefreshGuiElements_Vendor", "script exists in listNormal but does not fit in GuiListNormal or GuiListNormal2 - script removed.", LOG_ERROR)
				RemoveScript(script)
			endif
		Next

		'normal2 list
		For local script:TScript = eachin listNormal2
			if not script then continue

			'search the script in all of our lists...
			local scriptFound:int = FALSE
			For local i:int = 0 to GuiListNormal.length-1
				if scriptFound then continue
				if GuiListNormal[i].ContainsScript(script) then scriptFound = True
			Next
			if GuiListNormal2.ContainsScript(script) then scriptFound = True

			if scriptFound then continue

			'try to add to guiListNormal2, then guiListNormal-array
			if not AddScriptToVendorGuiLists(script, [GuiListNormal2] + GuiListNormal)
				TLogger.log("ScriptAgency.RefreshGuiElements_Vendor", "script exists in listNormal2 but does not fit in GuiListNormal2 or GuiListNormal - script removed.", LOG_ERROR)
				RemoveScript(script)
			endif
		Next
	End Method


	'helper function
	Function AddScriptToVendorGuiLists:int(script:TScript, lists:TGUIScriptSlotlist[])
		'try to fill in one of the normalList-Parts
		For local i:int = 0 until lists.length
			if lists[i].getFreeSlot() < 0 then continue
			local block:TGUIScript = new TGUIScript.CreateWithScript(script)
			'change look
			block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))


			lists[i].addItem(block, "-1")
			return True
		Next
		return False
	End Function


	Method RefreshGuiElements:int()
		RefreshGuiElements_Suitcase()
		RefreshGuiElements_Vendor()


		haveToRefreshGuiElements = FALSE
	End Method


	Method WriteNewScripts()
		local scriptsToWrite:int = Max(0, 5 - GetScriptCollection().GetAvailableScriptList().Count())
		if scriptsToWrite = 0 then return

		local usedTemplateIDs:int[]
		'add written but not offered
		For local s:TScript = EachIn GetScriptCollection().GetAvailableScriptList()
			usedTemplateIDs :+ [s.basedOnScriptTemplateID]
		Next
		'add check IDs at vendor
		local lists:TScript[][] = [listNormal,listNormal2]
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if not lists[j][i] then continue
				usedTemplateIDs :+ [ lists[j][i].basedOnScriptTemplateID ]
			Next
		Next


		for local i:int = 0 until scriptsToWrite
			local s:TScript = GetScriptCollection().GenerateRandom(usedTemplateIDs)
			usedTemplateIDs :+ [s.basedOnScriptTemplateID]
		next
	End Method


	'refills slots in the script agency
	'replaceOffer: remove (some) old scripts and place new there?
	Method ReFillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TScript[][] = [listNormal,listNormal2]

		haveToRefreshGuiElements = TRUE

		replaceChance :* 100 '0-1.0 to 0-100

		'delete some random scripts
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue

					if RandRange(0,100) < replaceChance
						'with 30% chance the script gets trashed
						'and a completely new one will get created
						if RandRange(0,100) < 30
							'print "REMOVE: " + lists[j][i].GetTitle()
							GetScriptCollection().Remove(lists[j][i])
						'else just give it back to the collection
						'(reset owner)
						else
							'print "GIVE BACK: " + lists[j][i].GetTitle()
							lists[j][i].GiveBackToScriptPool()
						endif
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		'=== ACTUALLY CREATE SCRIPTS ===
		'collect used templates to avoid scripts with the same base template
		local usedTemplateIDs:int[]
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] and lists[j][i].basedOnScriptTemplateID > 0
					usedTemplateIDs :+ [lists[j][i].basedOnScriptTemplateID]
				endif
			Next
		Next


		'fetch and set new scripts
		local script:TScript = null
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists and is valid...skip it
				if lists[j][i] then continue

				'get a new script - but avoid having multiple scripts
				'of the same base template (high similarity)
				script = GetScriptCollection().GetRandomAvailable(usedTemplateIDs)

				'add new script to slot
				if script
					GetScriptCollection().SetScriptOwner(script, TOwnedGameObject.OWNER_VENDOR)
					lists[j][i] = script

					if script.basedOnScriptTemplateID
						usedTemplateIDs :+ [script.basedOnScriptTemplateID]
					endif
				endif
			Next
		Next
	End Method



	'===================================
	'Script Agency: Room screen
	'===================================

	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("scriptagency") then return FALSE

		'refresh the suitcase, not the board shelf!
		GetInstance().RefreshGuiElements_Suitcase()

rem
		'only refresh if the vendor did not get the script
		if triggerEvent.IsTrigger("programmecollection.removeScript")
			if not GetInstance().HasScript(TScript(triggerEvent.GetData().Get("script")))
				GetInstance().RefreshGuiElements()
			endif
		'only refresh if the vendor did not get the script
		elseif triggerEvent.IsTrigger("programmecollection.moveScript")
			if not GetInstance().HasScript(TScript(triggerEvent.GetData().Get("script")))
				GetInstance().RefreshGuiElements()
			endif
		else
			GetInstance().RefreshGuiElements()
		endif
endrem
	End Function


	'in case of right mouse button click a dragged script is
	'placed at its original spot again
	Function onClickScript:int(triggerEvent:TEventBase)
		if not CheckPlayerInRoom("scriptagency") then return FALSE

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


	Function onMouseOverScript:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("scriptagency") then return FALSE

		local item:TGUIScript = TGUIScript(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiScript = item
		'only handle dragged for the real player
		if CheckPlayerInRoom("scriptagency")
			if item.isDragged() then draggedGuiScript = item
		endif

		return TRUE
	End Function


	'- check if dropping on suitcase and affordable
	'- check if dropping on an item in the shelf (not allowed for now)
	Function onTryDropScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		local guiScript:TGUIScript = TGUIScript(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiScript or not receiverList then return FALSE

		local owner:int = guiScript.script.owner

		select receiverList
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiScript.script.IsOwnedByPlayer(GetPlayerBase().playerID) then return TRUE

				if not GetPlayerBase().getFinance().canAfford(guiScript.script.getPrice())
					triggerEvent.setVeto()
				endif
			'case GuiListNormal[0], ..., GuiListNormal2
			default
				'check if something is underlaying and whether it is
				'a different script
				local underlayingItem:TGUIScript = null
				local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
				if coord then underlayingItem = TGUIScript(receiverList.GetItemByCoord(coord))

				'allow drop on own place
				if underlayingItem = guiScript then return TRUE

				'only allow drops on empty slots
				if underlayingItem
					triggerEvent.SetVeto()
					return FALSE
				endif
		End Select

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropScriptOnVendor:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		local guiBlock:TGUIScript = TGUIScript( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIScriptSlotList = TGUIScriptSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		'and try to add it back to the shelf
		if senderList = GuiListSuitcase
			if not GetInstance().BuyScriptFromPlayer(guiBlock.script)
				triggerEvent.setVeto()
				return FALSE
			endif
		else
			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveScript(guiBlock.script)
			GetInstance().AddScript(guiBlock.script)
		endif
		'remove the block, will get recreated if needed
		guiBlock.remove()
		guiBlock = null

		'something changed...refresh missing/obsolete...
'		GetInstance().RefreshGuiElements()
		GetInstance().RefreshGuiElements_Vendor()

		return TRUE
	End function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropScript:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("scriptagency") then return FALSE

		local guiScript:TGUIScript = TGUIScript(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiScript or not receiverList then return FALSE

		'get current owner of the script, as the field "owner" is set
		'during buy we cannot rely on it. So we check if the player has
		'the script in the suitcaseScriptList
		local owner:int = guiScript.script.owner
		if owner <= 0 and GetPlayerProgrammeCollection(GetPlayerBase().playerID).HasScriptInSuitcase(guiScript.script)
			owner = GetPlayerBase().playerID
		endif


		select receiverList
			case GuiListSuitcase
				local dropOK:int = False
				'no problem when dropping own script to suitcase..
				if guiScript.script.IsOwnedByPlayer(GetPlayerBase().playerID)
					dropOK = True
				'try to sell it to the player
				elseif GetInstance().SellScriptToPlayer(guiScript.script, GetPlayerBase().playerID)
					dropOK = true
				endif


				if dropOK
					'set to suitcase view
					guiScript.InitAssets( guiScript.getAssetName(-1, TRUE ), guiScript.getAssetName(-1, TRUE ) )
					return TRUE
				else
					triggerEvent.setVeto()
					'try to drop back to old list - which triggers
					'this function again... but with a differing list..
					guiScript.dropBackToOrigin()
					haveToRefreshGuiElements = TRUE
				endif

			'case GuiListNormal[0], ... , GuiListNormal2
			default
				'set to "board-view"
				guiScript.InitAssets( guiScript.getAssetName(-1, FALSE ), guiScript.getAssetName(-1, TRUE ) )

				'when dropping vendor licence on vendor shelf .. no prob
				if not guiScript.script.IsOwnedByPlayer() Then return true

				if not GetInstance().BuyScriptFromPlayer(guiScript.script)
					triggerEvent.setVeto()
					'try to drop back to old list - which triggers
					'this function again... but with a differing list..
					guiScript.dropBackToOrigin()
					haveToRefreshGuiElements = TRUE
					return FALSE
				endif
		end select

		return TRUE
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightVendor:int = False

		if draggedGuiScript and draggedGuiScript.isDragged()
			'if not GetPlayerProgrammeCollection(GetPlayerCollection().playerID).HasScriptInSuitcase(draggedGuiScript.script)
			if draggedGuiScript.script.owner <= 0
				highlightSuitcase = True
			else
				highlightVendor = True
			endif
		endif

		if highlightVendor or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * sin(Time.GetAppTimeGone() / 5))

			if VendorEntity and highlightVendor then VendorEntity.Render()
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif

		'debug
		'SetAlpha 0.4
		'DrawRect(VendorArea.rect.GetX(),VendorArea.rect.GetY(), VendorArea.rect.GetW(), VendorArea.rect.GetH())
		'SetAlpha 1.0
		'DrawRect(GuiListSuitcase.GetScreenX(),GuiListSuitcase.GetScreenY(), GuiListSuitcase.GetScreenWidth(), GuiListSuitcase.GetScreenHeight())


		GUIManager.Draw( LS_scriptagency )

		if hoveredGuiScript
			'draw the current sheet
			hoveredGuiScript.DrawSheet()
		endif

		if TVTDebugInfos
			SetColor 0,0,0
			SetAlpha 0.6
			DrawRect(300,215, 480, 200)
			SetAlpha 1.0
			SetColor 255,255,255
			GetBitmapFont("default", 12).Draw("Script Pool (refill: " + GetGameBase().refillScriptAgencyTime+")", 320, 220)
			GetBitmapFont("default", 12).Draw("available", 320, 235)
			GetBitmapFont("default", 12).Draw("used", 540, 235)
			local y:int = 250
			for local script:TScript = EachIn GetScriptCollection().GetAvailableScriptList()
				GetBitmapFont("default", 12).Draw(script.GetTitle(), 320, y)
				y:+ 13
			Next
			y = 250
			for local script:TScript = EachIn GetScriptCollection().GetUsedScriptList()
				GetBitmapFont("default", 12).Draw(script.GetTitle(), 540, y)
				y:+ 13
			Next
		endif
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		if VendorEntity Then VendorEntity.Update()

		if CheckPlayerInRoom("scriptagency")
			'delete unused and create new gui elements
			if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

			'reset hovered block - will get set automatically on gui-update
			hoveredGuiScript = null
			'reset dragged block too
			draggedGuiScript = null

			GUIManager.Update( LS_scriptagency )
		endif
	End Method
End Type

