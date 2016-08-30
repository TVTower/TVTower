SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "Dig/base.gfx.gui.list.base.bmx"
Import "common.misc.gamegui.bmx"
Import "game.roomhandler.base.bmx"
Import "game.programme.programmelicence.gui.bmx"
'Import "game.broadcastmaterial.programme.bmx"
'Import "game.player.programmecollection.bmx"

Import "common.misc.plannerlist.programmelist.bmx"


'Archive: handling of players programmearchive - for selling it later, ...
Type RoomHandler_Archive extends TRoomHandler
	Field hoveredGuiProgrammeLicence:TGuiProgrammeLicence = null
	Field draggedGuiProgrammeLicence:TGuiProgrammeLicence = null
	Field openCollectionTooltip:TTooltip

	Field programmeList:TgfxProgrammelist
	Field haveToRefreshGuiElements:int = TRUE
	Field GuiListSuitcase:TGUIProgrammeLicenceSlotList = null
	Field DudeArea:TGUISimpleRect	'allows registration of drop-event

	'configuration
	Field suitcasePos:TVec2D				= new TVec2D.Init(40,270)
	Field suitcaseGuiListDisplace:TVec2D	= new TVec2D.Init(14,25)

	Global _instance:RoomHandler_Archive
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_Archive()
		if not _instance then _instance = new RoomHandler_Archive
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		if not GuiListSuitCase
			GuiListSuitcase	= new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(180, GetSpriteFromRegistry("gfx_movie_undefined").area.GetH()), "archive")
			GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)
			GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListSuitcase.acceptType = TGUIProgrammeLicenceSlotList.acceptAll
			GuiListSuitcase.SetItemLimit(GameRules.maxProgrammeLicencesInSuitcase)
			GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_movie_undefined").area.GetW(), GetSpriteFromRegistry("gfx_movie_undefined").area.GetH())
			GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

			DudeArea = new TGUISimpleRect.Create(new TVec2D.Init(600,100), new TVec2D.Init(200, 350), "archive" )
			'dude should accept drop - else no recognition
			DudeArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

			programmeList = New TgfxProgrammelist.Create(720, 10)
		endif

		
		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence" ) ]
		'drop programme ... so sell/buy the thing
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProgrammeLicence, "TGUIProgrammeLicence" ) ]
		'drop programme on dude - add back to player's collection
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropProgrammeLicenceOnDude, "TGUIProgrammeLicence" ) ]
		'check right clicks on a gui block
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", onClickProgrammeLicence, "TGUIProgrammeLicence" ) ]

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
		GetRoomHandlerCollection().SetHandler("archive", GetInstance())
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements
		If draggedGuiProgrammeLicence
			draggedGuiProgrammeLicence.dropBackToOrigin()
			'remove in all cases
			draggedGuiProgrammeLicence = null
			hoveredGuiProgrammeLicence = null
			return True
		EndIf
		return False
	End Method


	'override
	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase )
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null
		GuiListSuitcase.EmptyList()

		haveToRefreshGuiElements = true
	End Method


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'handle interactivity for room owners
		if IsRoomOwner(figure, TRoom(triggerEvent.GetReceiver()))
			'if the list is open - just close the list and veto against
			'leaving the room
			if programmeList.openState <> 0
				programmeList.SetOpen(0)
				triggerEvent.SetVeto()
				return FALSE
			endif

			'do not allow leaving as long as we have a dragged block
			if draggedGuiProgrammeLicence
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	'remove suitcase licences from a players programme plan
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		'handle interactivity for room owners
		if IsRoomOwner(figure, TRoom(triggerEvent.GetSender()))
			'remove all licences in the suitcase from the programmeplan
			local plan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(figure.playerID)
			For local licence:TProgrammeLicence = EachIn GetPlayerProgrammeCollectionCollection().Get(figure.playerID).suitcaseProgrammeLicences
				plan.RemoveProgrammeInstancesByLicence(licence, true)
			Next

			'close the list if open
			'programmeList.SetOpen(0)
		endif
		
		return TRUE
	End Method


	'called as soon as a players figure is forced to leave the room
	Method onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		if not super.onForcefullyLeaveRoom(triggerEvent) then return False

		'handle interactivity for room owners
		if IsRoomOwner(TFigure(triggerEvent.GetReceiver()), TRoom(triggerEvent.GetSender()))
			'instead of leaving the room and accidentially removing programmes
			'from the plan we readd all licences from the suitcase back to
			'the players collection
			GetPlayerProgrammeCollection( GetPlayerBase().playerID ).ReaddProgrammeLicencesFromSuitcase()
		endif
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Method RemoveAllGuiElements:int()
		GuiListSuitcase.EmptyList()

		For local guiLicence:TGUIProgrammeLicence = eachin GuiManager.listDragged.Copy()
			guiLicence.remove()
			guiLicence = null
		Next

		hoveredGuiProgrammeLicence = null
		draggedGuiProgrammeLicence = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Method


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with licences the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next

		'===== CREATE NEW =====
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollection( GetPlayerBase().playerID ).suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Method



	'in case of right mouse button click we want to add back the
	'dragged block to the player's programmeCollection
	Function onClickProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiBlock or not guiBlock.isDragged() then return FALSE

		'add back to collection if already dropped it to suitcase before
		if not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasProgrammeLicence(guiBlock.licence)
			GetPlayerProgrammeCollection( GetPlayerBase().playerID ).RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		endif
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
		'also avoid long click (touch screen)
		MouseManager.ResetLongClicked(1)
	End Function


	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiBlock or not receiverList then return FALSE

		local owner:int = guiBlock.licence.owner

		select receiverList
			case GetInstance().GuiListSuitcase
				'check if still in collection - if so, remove
				'from collection and add to suitcase
				if GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasProgrammeLicence(guiBlock.licence)
					'remove gui - a new one will be generated automatically
					'as soon as added to the suitcase and the room's update
					guiBlock.remove()

					'if not able to add to suitcase (eg. full), cancel
					'the drop-event
					if not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).AddProgrammeLicenceToSuitcase(guiBlock.licence)
						triggerEvent.setVeto()
					endif
					
					guiBlock = null
				endif

				'else it is just a "drop back"
				return TRUE
		end select

		return TRUE
	End Function


	'handle cover block drops on the dude
	Function onDropProgrammeLicenceOnDude:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("archive") then return FALSE

		local guiBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver then return FALSE
		if receiver <> GetInstance().DudeArea then return FALSE

		'add back to collection
		GetPlayerProgrammeCollection( GetPlayerBase().playerID ).RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
		'remove the gui element
		guiBlock.remove()
		guiBlock = null

		return TRUE
	End function


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		GetInstance().hoveredGuiProgrammeLicence = item
		if item.isDragged()
			GetInstance().draggedGuiProgrammeLicence = item
			'if we have an item dragged... we cannot have a menu open
			GetInstance().programmeList.SetOpen(0)
		endif

		return TRUE
	End Function


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:int( triggerEvent:TEventBase )
		'we are not interested in other figures than our player's
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or GetPlayerBase().GetFigure() <> figure then return FALSE

		'handle interactivity only for own room
		if IsRoomOwner(figure, TRoom(triggerEvent.GetSender()))
			'when entering the archive, all scripts are moved from the
			'suitcase to the collection
			'TODO: mark these scripts as "new" 

			'RONNY 2016/08/06:
			'disabled because there is - for now - now way to move them
			'back into the suitcase
			'TODO: add wayback option (dialogue + archive-script-box ?)
			'GetPlayerProgrammeCollection(figure.playerID).MoveScriptsFromSuitcaseToArchive()
		endif

		'empty the guilist / delete gui elements
		'- the real list still may contain elements with gui-references
		guiListSuitcase.EmptyList()
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'only draw custom elements for players room
		local room:TRoom = TRoom(triggerEvent._sender)
		if room.owner <> GetPlayerBaseCollection().playerID then return FALSE

		programmeList.owner = room.owner
		programmeList.Draw()

		'make suitcase/vendor glow if needed
		local glowSuitcase:string = ""
		if draggedGuiProgrammeLicence then glowSuitcase = "_glow"
		'draw suitcase
		GetSpriteFromRegistry("gfx_suitcase"+glowSuitcase).Draw(suitcasePos.GetX(), suitcasePos.GetY())

		GUIManager.Draw("archive")

		'draw dude tooltip
		If openCollectionTooltip Then openCollectionTooltip.Render()


		'show sheet from hovered list entries
		if programmeList.hoveredLicence
			programmeList.hoveredLicence.ShowSheet(30,20)
		endif
		'show sheet from hovered suitcase entries
		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'only handle custom elements for players room
		local room:TRoom = TRoom(triggerEvent._sender)
		if room.owner <> GetPlayerBaseCollection().playerID then return FALSE

		GetGameBase().cursorstate = 0

		'open list when clicking dude
		if not draggedGuiProgrammeLicence
			If not programmeList.GetOpen()
				if THelper.MouseIn(605,65,160,90) Or THelper.MouseIn(525,155,240,225)
					'activate tooltip
					If not openCollectionTooltip Then openCollectionTooltip = TTooltip.Create(GetLocale("PROGRAMMELICENCES"), GetLocale("SELECT_LICENCES_FOR_SALE"), 470, 130, 0, 0)
					openCollectionTooltip.enabled = 1
					openCollectionTooltip.Hover()

					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1) and not MouseManager.IsLongClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0
						programmeList.SetOpen(1)
						'remove tooltip
						openCollectionTooltip = null
					endif
				EndIf
			endif
			programmeList.enabled = TRUE
		else
			'disable list if we have a dragged guiobject
			programmeList.enabled = FALSE
		endif
		programmeList.owner = room.owner
		programmeList.Update(TgfxProgrammelist.MODE_ARCHIVE)

		'handle tooltip
		If openCollectionTooltip Then openCollectionTooltip.Update()


		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollection( GetPlayerBase().playerID ).suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem( new TGuiProgrammeLicence.CreateWithLicence(licence),"-1" )
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then RefreshGUIElements()


		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("archive")
	End Method
End Type

