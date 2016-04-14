Function RegisterRoomHandlers()
	'=== (re-)initialize all known room handlers
	RoomHandler_Office.GetInstance().RegisterHandler()
	RoomHandler_News.GetInstance().RegisterHandler()
	RoomHandler_Boss.GetInstance().RegisterHandler()
	RoomHandler_Archive.GetInstance().RegisterHandler()
	RoomHandler_Studio.GetInstance().RegisterHandler()

	RoomHandler_AdAgency.GetInstance().RegisterHandler()
	RoomHandler_ScriptAgency.GetInstance().RegisterHandler()
	RoomHandler_MovieAgency.GetInstance().RegisterHandler()
	RoomHandler_RoomAgency.GetInstance().RegisterHandler()

	RoomHandler_Betty.GetInstance().RegisterHandler()

	RoomHandler_ElevatorPlan.GetInstance().RegisterHandler()
	RoomHandler_Roomboard.GetInstance().RegisterHandler()

	RoomHandler_Credits.GetInstance().RegisterHandler()
End Function



Include "game.screen.stationmap.bmx"
Include "game.screen.programmeplanner.bmx"
Include "game.screen.financials.bmx"
Include "game.screen.statistics.bmx"

'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	'=== OFFICE ROOM ===
	Global StationsToolTip:TTooltip
	Global PlannerToolTip:TTooltip
	Global SafeToolTip:TTooltip

	Global _instance:RoomHandler_Office
	Global _initDone:int = False
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_Office()
		if not _instance then _instance = new RoomHandler_Office
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'reset/initialize screens (event connection etc.)
		TScreenHandler_Financials.Initialize()
		TScreenHandler_ProgrammePlanner.Initialize()
		TScreenHandler_StationMap.Initialize()
		TScreenHandler_Statistics.Initialize()		


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'handle the "office" itself (not computer etc)
		'using this approach avoids "tooltips" to be visible in subscreens
		_eventListeners :+ _RegisterScreenHandler( onUpdateOffice, onDrawOffice, ScreenCollection.GetScreen("screen_office") )

		'(re-)localize content
		'disabled as the screens are setting their language during "initialize()"
		'too.
		'reenable if doing more localization there
		'SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		StationsToolTip = null
		PlannerToolTip = null
		SafeToolTip = null

		'=== remove obsolete gui elements ===
		'
		
		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("office", GetInstance())
	End Method


	Method SetLanguage()
		TScreenHandler_Financials.SetLanguage()
		TScreenHandler_ProgrammePlanner.SetLanguage()
		TScreenHandler_StationMap.SetLanguage()
		TScreenHandler_Statistics.SetLanguage()
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements in the planner
		TScreenHandler_ProgrammePlanner.AbortScreenActions()

		return False
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Function onDrawOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen( triggerEvent._sender )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if room.GetBackground() then room.GetBackground().draw(0, 0)

		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)
			If StationsToolTip Then StationsToolTip.Render()
			'allowed for all - if having keys
			If PlannerToolTip Then PlannerToolTip.Render()

			If SafeToolTip Then SafeToolTip.Render()
		EndIf
	End Function


	Function onUpdateOffice:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0


		GetPlayer().GetFigure().fromroom = Null
		If MOUSEMANAGER.IsClicked(1)
			'emulated right click or clicked door
			If MOUSEMANAGER.IsLongClicked(1) or THelper.IsIn(MouseManager.x,MouseManager.y,25,40,150,295)
				GetPlayer().GetFigure().LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
		EndIf


		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)
			GetGameBase().cursorstate = 0

			'only if player does not want to leave room
			if not MouseManager.IsLongClicked(1)
				'safe - reachable for all
				If THelper.MouseIn(165,85,70,100)
					If not SafeToolTip Then SafeToolTip = TTooltip.Create(GetLocale("ROOM_SAFE"), GetLocale("FOR_PRIVATE_AFFAIRS"), 140, 100,-1,-1)
					SafeToolTip.enabled = 1
					SafeToolTip.SetMinTitleAndContentWidth(90, 120)
					SafeToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0

						ScreenCollection.GoToSubScreen("screen_office_safe")
					endif
				EndIf

				'planner - reachable for all
				If THelper.IsIn(MouseManager.x, MouseManager.y, 600,140,128,210)
					If not PlannerToolTip Then PlannerToolTip = TTooltip.Create(GetLocale("ROOM_PROGRAMMEPLANNER"), GetLocale("AND_STATISTICS"), 580, 140)
					PlannerToolTip.enabled = 1
					PlannerToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0
						ScreenCollection.GoToSubScreen("screen_office_programmeplanner")
					endif
				EndIf

				If THelper.IsIn(MouseManager.x, MouseManager.y, 732,45,160,170)
					If not StationsToolTip Then StationsToolTip = TTooltip.Create(GetLocale("ROOM_STATIONMAP"), GetLocale("BUY_AND_SELL"), 650, 80, 0, 0)
					StationsToolTip.enabled = 1
					StationsToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0
						ScreenCollection.GoToSubScreen("screen_office_stationmap")
					endif
				EndIf
			endif

			If StationsToolTip Then StationsToolTip.Update()
			If PlannerToolTip Then PlannerToolTip.Update()
			If SafeToolTip Then SafeToolTip.Update()
		EndIf
	End Function
End Type



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
			GetPlayer().GetProgrammeCollection().ReaddProgrammeLicencesFromSuitcase()
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
			if GetPlayer().GetProgrammeCollection().HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next

		'===== CREATE NEW =====
		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayer().GetProgrammeCollection().suitcaseProgrammeLicences
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
		if not GetPlayer().GetProgrammeCollection().HasProgrammeLicence(guiBlock.licence)
			GetPlayer().GetProgrammeCollection().RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
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
				if GetPlayer().GetProgrammeCollection().HasProgrammeLicence(guiBlock.licence)
					'remove gui - a new one will be generated automatically
					'as soon as added to the suitcase and the room's update
					guiBlock.remove()

					'if not able to add to suitcase (eg. full), cancel
					'the drop-event
					if not GetPlayer().GetProgrammeCollection().AddProgrammeLicenceToSuitcase(guiBlock.licence)
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
		GetPlayer().GetProgrammeCollection().RemoveProgrammeLicenceFromSuitcase(guiBlock.licence)
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
			GetPlayerProgrammeCollection(figure.playerID).MoveScriptsFromSuitcaseToArchive()
		endif

		'empty the guilist / delete gui elements
		'- the real list still may contain elements with gui-references
		guiListSuitcase.EmptyList()
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'only draw custom elements for players room
		local room:TRoom = TRoom(triggerEvent._sender)
		if room.owner <> GetPlayerCollection().playerID then return FALSE

		programmeList.owner = GetPlayer(room.owner)
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
		if room.owner <> GetPlayerCollection().playerID then return FALSE

		GetGameBase().cursorstate = 0

		'open list when clicking dude
		if not draggedGuiProgrammeLicence
			If not programmeList.GetOpen()
				if THelper.IsIn(MouseManager.x, MouseManager.y, 605,65,160,90) Or THelper.IsIn(MouseManager.x, MouseManager.y, 525,155,240,225)
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
		programmeList.owner = GetPlayer(room.owner)
		programmeList.Update(TgfxProgrammelist.MODE_ARCHIVE)

		'handle tooltip
		If openCollectionTooltip Then openCollectionTooltip.Update()


		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayer().GetProgrammeCollection().suitcaseProgrammeLicences
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


'Movie agency
Type RoomHandler_MovieAgency extends TRoomHandler
	Global AuctionToolTip:TTooltip

	Global VendorEntity:TSpriteEntity
	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	Global AuctionEntity:TSpriteEntity

	Global hoveredGuiProgrammeLicence:TGUIProgrammeLicence = null
	Global draggedGuiProgrammeLicence:TGUIProgrammeLicence = null

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listMoviesGood:TProgrammeLicence[]
	Field listMoviesCheap:TProgrammeLicence[]
	Field listSeries:TProgrammeLicence[]

	Field filterMoviesGood:TProgrammeLicenceFilterGroup
	Field filterMoviesCheap:TProgrammeLicenceFilterGroup
	Field filterSeries:TProgrammeLicenceFilter
	Field filterAuction:TProgrammeLicenceFilter

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListMoviesGood:TGUIProgrammeLicenceSlotList = null
	Global GuiListMoviesCheap:TGUIProgrammeLicenceSlotList = null
	Global GuiListSeries:TGUIProgrammeLicenceSlotList = null
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = null

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(350,130)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(14,25)
	Field programmesPerLine:int	= 13
	Field movieCheapMoneyMaximum:int = 75000
	Field movieCheapQualityMaximum:Float = 0.20

	Global _instance:RoomHandler_MovieAgency
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_MovieAgency()
		if not _instance then _instance = new RoomHandler_MovieAgency
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()
		
		listMoviesGood = new TProgrammeLicence[programmesPerLine]
		listMoviesCheap = new TProgrammeLicence[programmesPerLine]
		listSeries = new TProgrammeLicence[programmesPerLine]


		if not filterMoviesGood
			filterMoviesGood = new TProgrammeLicenceFilterGroup
			'filterMoviesGood.AddFilter(new TProgrammeLicenceFilter)
			'filterMoviesGood.AddFilter(new TProgrammeLicenceFilter)
		endif
		if not filterMoviesCheap
			filterMoviesCheap = new TProgrammeLicenceFilterGroup
			filterMoviesCheap.AddFilter(new TProgrammeLicenceFilter)
			filterMoviesCheap.AddFilter(new TProgrammeLicenceFilter)
		endif
		if not filterSeries then filterSeries = new TProgrammeLicenceFilter
		if not filterAuction then filterAuction = new TProgrammeLicenceFilter

		filterAuction.priceMin = 250000
		filterAuction.priceMax = -1
		filterAuction.licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION, TVTProgrammeLicenceType.SERIES, TVTProgrammeLicenceType.COLLECTION]
		'avoid "too used" licences
		filterAuction.relativeTopicalityMin = 0.85
		filterAuction.relativeTopicalityMax = -1.0
		filterAuction.ageMin = -1
		'maximum of 1 year since release
		filterAuction.ageMax = TWorldTime.DAYLENGTH * GetWorldTime().GetDaysPerYear()
		


		'good movies must be more expensive than X _and_ of better
		'quality then Y
		filterMoviesGood.priceMin = movieCheapMoneyMaximum
		filterMoviesGood.priceMax = -1
		filterMoviesGood.licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesGood.qualityMin = movieCheapQualityMaximum
		filterMoviesGood.qualityMax = -1.0
		filterMoviesGood.relativeTopicalityMin = 0.25
		filterMoviesGood.relativeTopicalityMax = -1.0
		'filterMoviesGood.connectionType = TProgrammeLicenceFilterGroup.CONNECTION_TYPE_AND
		'filterMoviesGood.filters[0].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		'filterMoviesGood.filters[0].priceMin = movieCheapMoneyMaximum
		'filterMoviesGood.filters[0].priceMax = -1
		'filterMoviesGood.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		'filterMoviesGood.filters[1].qualityMin = movieCheapQualityMaximum
		'filterMoviesGood.filters[1].qualityMax = -1.0

		'cheap movies must be cheaper than X _or_ of lower quality than Y
		filterMoviesCheap.connectionType = TProgrammeLicenceFilterGroup.CONNECTION_TYPE_OR
		filterMoviesCheap.filters[0].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		'filterMoviesCheap.filters[0].SetRequiredOwners([TOwnedGameObject.OWNER_NOBODY])

		filterMoviesCheap.filters[0].priceMin = 0
		filterMoviesCheap.filters[0].priceMax = movieCheapMoneyMaximum
		filterMoviesCheap.filters[0].relativeTopicalityMin = 0.25
		filterMoviesCheap.filters[0].relativeTopicalityMax = -1.0

		filterMoviesCheap.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		'filterMoviesCheap.filters[1].SetRequiredOwners([TOwnedGameObject.OWNER_NOBODY])
		filterMoviesCheap.filters[1].qualityMin = -1.0
		filterMoviesCheap.filters[1].qualityMax = movieCheapQualityMaximum
		filterMoviesCheap.filters[1].relativeTopicalityMin = 0.25
		filterMoviesCheap.filters[1].relativeTopicalityMax = -1.0
		
		'filter them by price too - eg. for auction ?
		filterSeries.licenceTypes = [TVTProgrammeLicenceType.SERIES]
		'filterSeries.filters[0].SetRequiredOwners([TOwnedGameObject.OWNER_NOBODY])
		'as long as there are not that much series, allow 10% instead of 25%
		filterSeries.relativeTopicalityMin = 0.10
		filterSeries.relativeTopicalityMax = -1.0


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		'=== create room elements
		VendorEntity = GetSpriteEntityFromRegistry("entity_movieagency_vendor")
		AuctionEntity = GetSpriteEntityFromRegistry("entity_movieagency_auction")

		'=== create gui elements if not done yet
		if not GuiListMoviesGood
			local videoCase:TSprite = GetSpriteFromRegistry("gfx_movie_undefined")

			GuiListMoviesGood = new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,50), new TVec2D.Init(200, videoCase.area.GetH()), "movieagency")
			GuiListMoviesCheap = new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,148), new TVec2D.Init(200, videoCase.area.GetH()), "movieagency")
			GuiListSeries = new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(596,246), new TVec2D.Init(200, videoCase.area.GetH()), "movieagency")
			GuiListSuitcase = new TGUIProgrammeLicenceSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(180, videoCase.area.GetH()), "movieagency")

			GuiListMoviesGood.guiEntriesPanel.minSize.SetXY(200,80)
			GuiListMoviesCheap.guiEntriesPanel.minSize.SetXY(200,80)
			GuiListSeries.guiEntriesPanel.minSize.SetXY(200,80)
			GuiListSuitcase.guiEntriesPanel.minSize.SetXY(200,80)

			GuiListMoviesGood.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListMoviesCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListSeries.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

			GuiListMoviesGood.acceptType = TGUIProgrammeLicenceSlotList.acceptMovies
			GuiListMoviesCheap.acceptType = TGUIProgrammeLicenceSlotList.acceptMovies
			GuiListSeries.acceptType = TGUIProgrammeLicenceSlotList.acceptSeries
			GuiListSuitcase.acceptType = TGUIProgrammeLicenceSlotList.acceptAll

			GuiListMoviesGood.SetItemLimit(listMoviesGood.length)
			GuiListMoviesCheap.SetItemLimit(listMoviesCheap.length)
			GuiListSeries.SetItemLimit(listSeries.length)
			GuiListSuitcase.SetItemLimit(GameRules.maxProgrammeLicencesInSuitcase)

			GuiListMoviesGood.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
			GuiListMoviesCheap.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
			GuiListSeries.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
			GuiListSuitcase.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())

			GuiListMoviesGood.SetAcceptDrop("TGUIProgrammeLicence")
			GuiListMoviesCheap.SetAcceptDrop("TGUIProgrammeLicence")
			GuiListSeries.SetAcceptDrop("TGUIProgrammeLicence")
			GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

			'default vendor position/dimension
			local vendorAreaDimension:TVec2D = new TVec2D.Init(200,200)
			local vendorAreaPosition:TVec2D = new TVec2D.Init(20,60)
			if VendorEntity then vendorAreaDimension = VendorEntity.area.dimension.copy()
			if VendorEntity then vendorAreaPosition = VendorEntity.area.position.copy()

			VendorArea = new TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "movieagency" )
			'vendor should accept drop - else no recognition
			VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)
		endif
		

		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'drop ... so sell/buy the thing
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onTryDropOnTarget", onTryDropProgrammeLicence, "TGUIProgrammeLicence" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicence, "TGUIProgrammeLicence") ]
		'is dragging even allowed? - eg. intercept if not enough money
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDrag", onDragProgrammeLicence, "TGUIProgrammeLicence") ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverProgrammeLicence, "TGUIProgrammeLicence") ]
		'drop on vendor - sell things
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDropOnTarget", onDropProgrammeLicenceOnVendor, "TGUIProgrammeLicence") ]

		_eventListeners :+ _RegisterScreenHandler( onUpdateMovieAgency, onDrawMovieAgency, ScreenCollection.GetScreen("screen_movieagency"))
		_eventListeners :+ _RegisterScreenHandler( onUpdateMovieAuction, onDrawMovieAuction, ScreenCollection.GetScreen("screen_movieauction"))

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'
		
		'=== remove obsolete gui elements ===
		if GuiListMoviesGood then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("movieagency", GetInstance())
	End Method


	Method AbortScreenActions:Int()
		if draggedGuiProgrammeLicence
			'try to drop the licence back
			draggedGuiProgrammeLicence.dropBackToOrigin()
			draggedGuiProgrammeLicence = null
			hoveredGuiProgrammeLicence = null
			return True
		endif
		return False
	End Method


	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase )
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet

		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = true
	End Method


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure then return FALSE

		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure.playerID then return False

		'fill all open slots in the agency
		GetInstance().ReFillBlocks()
	End Method


	'override: figure leaves room - only without dragged blocks
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiProgrammeLicence
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Method


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		GetPlayerProgrammeCollection(figure.playerID).ReaddProgrammeLicencesFromSuitcase()

		return TRUE
	End Method


	'===================================
	'Movie Agency: common TFunctions
	'===================================

	Method GetProgrammeLicencesInStock:int()
		Local ret:Int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence Then ret:+1
			Next
		Next
		return ret
	End Method


	Method GetProgrammeLicences:TProgrammeLicence[]()
		Local ret:TProgrammeLicence[ GetProgrammeLicencesInStock() ]
		local c:int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence Then ret[c] = licence
				c :+ 1
			Next
		Next
		return ret
	End Method
	

	Method GetProgrammeLicenceByPosition:TProgrammeLicence(position:int)
		if position > GetProgrammeLicencesInStock() then return null
		local currentPosition:int = 0
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence
					if currentPosition = position then return licence
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasProgrammeLicence:int(licence:TProgrammeLicence)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local listLicence:TProgrammeLicence = EachIn lists[j]
				if listLicence= licence then return TRUE
			Next
		Next
		return FALSE
	End Method


	Method GetProgrammeLicenceByID:TProgrammeLicence(licenceID:int)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				if licence and licence.id = licenceID then return licence
			Next
		Next
		return null
	End Method


	Method SellProgrammeLicenceToPlayer:int(licence:TProgrammeLicence, playerID:int)
		if licence.owner = playerID then return FALSE

		if not GetPlayerCollection().IsPlayer(playerID) then return FALSE

		'try to add to suitcase of player
		if not GetPlayerProgrammeCollection(playerID).AddProgrammeLicenceToSuitcase(licence)
			return FALSE
		endif

		'remove from agency's lists
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = licence then lists[j][i] = null
			Next
		Next

		return TRUE
	End Method


	Method BuyProgrammeLicenceFromPlayer:int(licence:TProgrammeLicence)
		'do not buy if unowned
		if not licence.isOwnedByPlayer() then return False

		'remove from player (lists and suitcase) - and give him money
		GetPlayerProgrammeCollection(licence.owner).RemoveProgrammeLicence(licence, TRUE)
		'add to agency's lists - if not existing yet
		if not HasProgrammeLicence(licence) then AddProgrammeLicence(licence)

		return TRUE
	End Method


	Method AddProgrammeLicence:int(licence:TProgrammeLicence, tryOtherLists:int = False)
		'do not add if still owned by a player or the vendor
		if licence.isOwned()
			TLogger.Log("MovieAgency", "===========", LOG_ERROR)
			TLogger.Log("MovieAgency", "AddProgrammeLicence() failed: cannot add licence owned by someone else. Owner="+licence.owner+"! Report to developers asap.", LOG_ERROR)
			TLogger.Log("MovieAgency", "===========", LOG_ERROR)
			return False
		endif
		
		'try to fill the licence into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TProgrammeLicence[][]

		'do not add episodes
		if licence.isEpisode()
			'licence.SetOwner(licence.OWNER_VENDOR)
			return FALSE
		endif


		if filterMoviesCheap.DoesFilter(licence)
			lists = [listMoviesCheap]
			if tryOtherLists then lists :+ [listMoviesGood]
		elseif filterMoviesGood.DoesFilter(licence)
			lists = [listMoviesGood]
			if tryOtherLists then lists :+ [listMoviesCheap]
		else
			lists = [listSeries]
		endif

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				licence.SetOwner(licence.OWNER_VENDOR)
				lists[j][i] = licence
				'print "added licence "+licence.title+" to list "+j+" at spot:"+i
				return TRUE
			Next
		Next


		return FALSE
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Method RemoveAllGuiElements:int()
		GuiListMoviesGood.EmptyList()
		GuiListMoviesCheap.EmptyList()
		GuiListSeries.EmptyList()
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
		'remove gui elements with movies the player does not have any
		'longer in the suitcase

		'suitcase
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			if GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = null
		Next
		'agency lists
		local lists:TProgrammeLicence[][] = [ listMoviesGood,listMoviesCheap,listSeries ]
		local guiLists:TGUIProgrammeLicenceSlotList[] = [ guiListMoviesGood, guiListMoviesCheap, guiListSeries ]
		For local j:int = 0 to guiLists.length-1
			For local guiLicence:TGUIProgrammeLicence = eachin guiLists[j]._slots
				if HasProgrammeLicence(guiLicence.licence) then continue

				'print "REM lists"+j+" has obsolete licence: "+guiLicence.licence.getTitle()
				guiLicence.remove()
				guiLicence = null
			Next
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programme-lists

		For local j:int = 0 to lists.length-1
			For local licence:TProgrammeLicence = eachin lists[j]
				if not licence then continue
				if guiLists[j].ContainsLicence(licence) then continue


				local lic:TGUIProgrammeLicence = new TGUIProgrammeLicence.CreateWithLicence(licence)
				'if adding to list was not possible, remove the licence again
				if not guiLists[j].addItem(lic,"-1" )
					GUIManager.Remove(lic)
				endif
				
				'print "ADD lists"+j+" had missing licence: "+licence.getTitle()
			Next
		Next

		'create missing gui elements for the current suitcase
		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollectionCollection().Get(GetPlayerCollection().playerID).suitcaseProgrammeLicences
			if guiListSuitcase.ContainsLicence(licence) then continue
			guiListSuitcase.addItem(new TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the movie agency
	'replaceOffer: remove (some) old programmes and place new there?
	Method RefillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		local licence:TProgrammeLicence = null

		haveToRefreshGuiElements = TRUE

		'delete some random movies/series
		if replaceOffer
			for local j:int = 0 to lists.length-1
				for local i:int = 0 to lists[j].length-1
					if not lists[j][i] then continue
					'delete an old movie by a chance of 50%
					if RandRange(0,100) < replaceChance*100
						'reset owner
						lists[j][i].SetOwner(TOwnedGameObject.OWNER_NOBODY)
						'unlink from this list
						lists[j][i] = null
					endif
				Next
			Next
		endif


		for local j:int = 0 to lists.length-1
			local warnedOfMissingLicence:int = FALSE
			for local i:int = 0 to lists[j].length-1
				'if exists...skip it
				if lists[j][i] then continue

				if lists[j] = listMoviesGood then licence = GetProgrammeLicenceCollection().GetRandomByFilter(filterMoviesGood)
				if lists[j] = listMoviesCheap then licence = GetProgrammeLicenceCollection().GetRandomByFilter(filterMoviesCheap)
				if lists[j] = listSeries then licence = GetProgrammeLicenceCollection().GetRandomByFilter(filterSeries)

				'add new licence at slot
				if licence
					licence.SetOwner(licence.OWNER_VENDOR)
					lists[j][i] = licence
				else
					if not warnedOfMissingLicence
						TLogger.log("MovieAgency.RefillBlocks()", "Not enough licences to refill slot["+i+"+] in list["+j+"]", LOG_WARNING | LOG_DEBUG)
						warnedOfMissingLicence = TRUE
					endif
				endif
			Next
		Next
	End Method


	'===================================
	'Movie Agency: All screens
	'===================================

	'can be done for all, as the order of handling that event
	'does not care ... just update animations is important
	Method onUpdateRoom:int( triggerEvent:TEventBase )
		Super.onUpdateRoom(triggerEvent)

		if AuctionEntity Then AuctionEntity.Update()
		if VendorEntity Then VendorEntity.Update()
	End Method

	
	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item
		if item.isDragged() then draggedGuiProgrammeLicence = item

		return TRUE
	End Function


	'check if we are allowed to drag that licence
	Function onDragProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		local owner:int = item.licence.owner

		'do not allow dragging items from other players
		if owner > 0 and owner <> GetPlayerCollection().playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		if owner <= 0
			if not GetPlayer().getFinance().canAfford(item.licence.getPrice())
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Function


	'- check if dropping on suitcase and affordable
	'- check if dropping own licence on the shelf (not possible for now)
	'(OLD: - check if dropping on an item which is not affordable)
	Function onTryDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'check if something is underlaying and whether the licence
				'differs to the dropped one
				local underlayingItem:TGUIProgrammeLicence = null
				local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
				if coord then underlayingItem = TGUIProgrammeLicence(receiverList.GetItemByCoord(coord))

				'allow drop on own place
				if underlayingItem = guiLicence then return TRUE

				if underlayingItem
					triggerEvent.SetVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = GetPlayerCollection().playerID then return TRUE

				if not GetPlayer().getFinance().canAfford(guiLicence.licence.getPrice())
					triggerEvent.setVeto()
				endif
		End select

		return TRUE
	End Function


	'dropping takes place - sell/buy licences or veto if not possible
	Function onDropProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		if not guiLicence or not receiverList then return FALSE

		local owner:int = guiLicence.licence.owner

		select receiverList
			case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'when dropping vendor licence on vendor shelf .. no prob
				if guiLicence.licence.owner <= 0 then return true

				if not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
					triggerEvent.setVeto()
					return FALSE
				endif
			case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				if guiLicence.licence.owner = GetPlayerCollection().playerID then return TRUE

				if not GetInstance().SellProgrammeLicenceToPlayer(guiLicence.licence, GetPlayerCollection().playerID)
					triggerEvent.setVeto()
					'try to drop back to old list - which triggers
					'this function again... but with a differing list..
					guiLicence.dropBackToOrigin()
					haveToRefreshGuiElements = TRUE
				endif
		end select

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropProgrammeLicenceOnVendor:int(triggerEvent:TEventBase)
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiLicence or not receiver then return FALSE
		if receiver <> VendorArea then return FALSE

		'do not accept blocks from the vendor itself
		if not guiLicence.licence.isOwnedByPlayer()
			triggerEvent.setVeto()
			return FALSE
		endif

		'buy licence back and place it somewhere in the right board shelf
		if not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
			triggerEvent.setVeto()
			return FALSE
		else
			'successful - delete that gui block
			guiLicence.remove()
			'remove the whole block too
			guiLicence = null
'RONNY
			haveToRefreshGuiElements = True
		endif

		return TRUE
	End function


	Function onDrawMovieAgency:int( triggerEvent:TEventBase )
		if AuctionEntity Then AuctionEntity.Render()
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make auction/suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightVendor:int = False
		local highlightAuction:int = False

		'sometimes a draggedGuiProgrammeLicence is defined in an update
		'but isnt dragged anymore (will get removed in the next tick)
		'the dragged check avoids that the vendor is highlighted for
		'1-2 render frames
		if draggedGuiProgrammeLicence and draggedGuiProgrammeLicence.isDragged()
			if draggedGuiProgrammeLicence.licence.owner <= 0
				highlightSuitcase = True
			else
				highlightVendor = True
			endif
		else
			If AuctionEntity and AuctionEntity.GetScreenArea().ContainsXY(MouseManager.x, MouseManager.y)
				highlightAuction = True
			EndIf
		endif

		if highlightAuction or highlightVendor or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * (0.4 + 0.2 * sin(Time.GetAppTimeGone() / 5))

			if AuctionEntity and highlightAuction then AuctionEntity.Render()
			if VendorEntity and highlightVendor then VendorEntity.Render()
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif


		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")

		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif


		If AuctionToolTip Then AuctionToolTip.Render()
	End Function


	Function onUpdateMovieAgency:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetGameBase().cursorstate = 0

		'show a auction-tooltip (but not if we dragged a block)
		if not hoveredGuiProgrammeLicence
			if not MouseManager.IsLongClicked(1)
				If THelper.IsIn(MouseManager.x, MouseManager.y, 210,220,140,60)
					If not AuctionToolTip Then AuctionToolTip = TTooltip.Create(GetLocale("AUCTION"), GetLocale("MOVIES_AND_SERIES_AUCTION"), 200, 180, 0, 0)
					AuctionToolTip.enabled = 1
					AuctionToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0
						ScreenCollection.GoToSubScreen("screen_movieauction")
					endif
				EndIf
			endif
		endif

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiProgrammeLicence = null
		'reset dragged block too
		draggedGuiProgrammeLicence = null

		GUIManager.Update("movieagency")

		If AuctionToolTip Then AuctionToolTip.Update()
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================

	Function onDrawMovieAuction:int( triggerEvent:TEventBase )
		if AuctionEntity Then AuctionEntity.Render()
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		SetAlpha 0.5
		local fontColor:TColor = TColor.CreateGrey(50)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("MOVIES"),		642,  27+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SPECIAL_BIN"),	642, 125+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		GetBitmapFont("Default",12, BOLDFONT).drawBlock(GetLocale("SERIES"), 		642, 223+3, 108,20, new TVec2D.Init(ALIGN_CENTER), fontColor)
		SetAlpha 1.0

		GUIManager.Draw("movieagency")
		SetAlpha 0.2;SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetAlpha 1.0;SetColor 255,255,255

		GetSpriteFromRegistry("gfx_gui_panel").DrawArea(120-15,60-15,555+30,290+30)
		GetSpriteFromRegistry("gfx_gui_panel.content").DrawArea(120,60,555,290)

		SetAlpha 0.5
		GetBitmapFont("Default",12,BOLDFONT).drawBlock(GetLocale("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,317, 535,30, new TVec2D.Init(ALIGN_CENTER), TColor.CreateGrey(50), 2, 1, 0.20)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll()
	End Function

	Function onUpdateMovieAuction:int( triggerEvent:TEventBase )
		GetGameBase().cursorstate = 0
		TAuctionProgrammeBlocks.UpdateAll()

		'remove old tooltips from previous screens
		If AuctionToolTip Then AuctionToolTip = null
	End Function
End Type


'News room
Type RoomHandler_News extends TRoomHandler
	Global PlannerToolTip:TTooltip
	Global NewsGenreButtons:TGUIButton[5]
	Global NewsGenreTooltip:TTooltip			'the tooltip if hovering over the genre buttons
	Global currentRoom:TRoom					'holding the currently updated room (so genre buttons can access it)
	'the image displaying "send news"
	Global newsPlannerTextImage:TImage = null

	'lists for visually placing news blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global guiNewsListAvailable:TGUINewsList
	Global guiNewsListUsed:TGUINewsSlotList
	Global draggedGuiNews:TGuiNews = null
	Global hoveredGuiNews:TGuiNews = null

	Global _instance:RoomHandler_News
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_News()
		if not _instance then _instance = new RoomHandler_News
		return _instance
	End Function


	Method Initialize:int()
		local plannerScreen:TScreen = ScreenCollection.GetScreen("screen_newsstudio_newsplanner")
		local studioScreen:TScreen = ScreenCollection.GetScreen("screen_newsstudio")
		if not plannerScreen or not studioScreen then return False

		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		'=== create gui elements if not done yet
		if not NewsGenreButtons[0]
			'create genre buttons
			'ATTENTION: We could do this in order of The NewsGenre-Values
			'           But better add it to the buttons.data-property
			'           for better checking
			NewsGenreButtons[0]	= new TGUIButton.Create( new TVec2D.Init(15, 194), null, GetLocale("NEWS_TECHNICS_MEDIA"), "newsroom")
			NewsGenreButtons[1]	= new TGUIButton.Create( new TVec2D.Init(64, 194), null, GetLocale("NEWS_POLITICS_ECONOMY"), "newsroom")
			NewsGenreButtons[2]	= new TGUIButton.Create( new TVec2D.Init(15, 247), null, GetLocale("NEWS_SHOWBIZ"), "newsroom")
			NewsGenreButtons[3]	= new TGUIButton.Create( new TVec2D.Init(64, 247), null, GetLocale("NEWS_SPORT"), "newsroom")
			NewsGenreButtons[4]	= new TGUIButton.Create( new TVec2D.Init(113, 247), null, GetLocale("NEWS_CURRENTAFFAIRS"), "newsroom")
			For local i:int = 0 to 4
				NewsGenreButtons[i].SetAutoSizeMode( TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE )
				'adjust width according sprite dimensions
				NewsGenreButtons[i].spriteName = "gfx_news_btn"+i
				'disable drawing of caption
				NewsGenreButtons[i].caption.Hide()
			Next

			'create the lists in the news planner
			'we add 2 pixel to the height to make "auto scrollbar" work better
			guiNewsListAvailable = new TGUINewsList.Create(new TVec2D.Init(15,16), new TVec2D.Init(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(), 4*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH()), "Newsplanner")
			guiNewsListAvailable.SetAcceptDrop("TGUINews")
			guiNewsListAvailable.Resize(guiNewsListAvailable.rect.GetW() + guiNewsListAvailable.guiScrollerV.rect.GetW() + 8,guiNewsListAvailable.rect.GetH())
			guiNewsListAvailable.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),356)

			guiNewsListUsed = new TGUINewsSlotList.Create(new TVec2D.Init(420,106), new TVec2D.Init(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(), 3*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH()), "Newsplanner")
			guiNewsListUsed.SetItemLimit(3)
			guiNewsListUsed.SetAcceptDrop("TGUINews")
			guiNewsListUsed.SetSlotMinDimension(0,GetSpriteFromRegistry("gfx_news_sheet0").area.GetH())
			guiNewsListUsed.SetAutofillSlots(false)
			guiNewsListUsed.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),3*GetSpriteFromRegistry("gfx_news_sheet0").area.GetH())
		endif


		'=== reset gui element options to their defaults
		'add news genre to button data
		NewsGenreButtons[0].data.AddNumber("newsGenre", TVTNewsGenre.TECHNICS_MEDIA)
		NewsGenreButtons[1].data.AddNumber("newsGenre", TVTNewsGenre.POLITICS_ECONOMY)
		NewsGenreButtons[2].data.AddNumber("newsGenre", TVTNewsGenre.SHOWBIZ)
		NewsGenreButtons[3].data.AddNumber("newsGenre", TVTNewsGenre.SPORT)
		NewsGenreButtons[4].data.AddNumber("newsGenre", TVTNewsGenre.CURRENTAFFAIRS)


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		
		'=== register event listeners
		'we are interested in the genre buttons
		for local i:int = 0 until NewsGenreButtons.length
			_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onMouseOver", onHoverNewsGenreButtons, NewsGenreButtons[i] ) ]
			_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDraw", onDrawNewsGenreButtons, NewsGenreButtons[i] ) ]
			_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onClick", onClickNewsGenreButtons, NewsGenreButtons[i] ) ]
		Next


		'if the player visually manages the blocks, we need to handle the events
		'so we can inform the programmeplan about changes...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onDropOnTargetAccepted", onDropNews, "TGUINews" ) ]
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickNews, "TGUINews") ]

		'we want to get informed if the news situation changes for a user
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.SetNews", onChangeNews ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.RemoveNews", onChangeNews ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.addNews", onChangeNews ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("programmecollection.removeNews", onChangeNews ) ]
		'we want to know if we hover a specific block
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverNews, "TGUINews" ) ]

		'figure enters screen - reset the guilists, limit listening to the 4 rooms
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onEnter", onEnterNewsPlannerScreen, plannerScreen) ]
		'also we want to interrupt leaving a room with dragged items
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.OnLeave", onLeaveNewsPlannerScreen, plannerScreen) ]
		
		_eventListeners :+ _RegisterScreenHandler( onUpdateNews, onDrawNews, studioScreen )
		_eventListeners :+ _RegisterScreenHandler( onUpdateNewsPlanner, onDrawNewsPlanner, plannerScreen )
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		PlannerToolTip = null
		NewsGenreTooltip = null
		currentRoom = null
		newsPlannerTextImage = null

		'=== remove obsolete gui elements ===
		if NewsGenreButtons[0] then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("news", GetInstance())
	End Method
	

	Method AbortScreenActions:Int()
		local abortedAction:int = False

		if draggedGuiNews
			'try to drop the licence back
			draggedGuiNews.dropBackToOrigin()
			draggedGuiNews = null
			hoveredGuiNews = null
			abortedAction = True
		endif

		'Try to drop back dragged elements
		For local obj:TGUINews = eachIn GuiManager.ListDragged.Copy()
			obj.dropBackToOrigin()
			'successful or not - get rid of the gui element
			obj.Remove()
		Next

		return abortedAction
	End Method


	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase )
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiNews = null
		draggedGuiNews = null

		RemoveAllGuiElements()
	End Method


	'===================================
	'News: room screen
	'===================================


	Function onDrawNews:int( triggerEvent:TEventBase )
		GUIManager.Draw("newsroom")

		'no interaction for other players newsrooms
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not IsPlayersRoom(room) then return False

		If PlannerToolTip Then PlannerToolTip.Render()
		If NewsGenreTooltip then NewsGenreTooltip.Render()
	End Function


	Function onUpdateNews:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'store current room for later access (in guiobjects)
		currentRoom = room

		GUIManager.Update("newsroom")

		GetGameBase().cursorstate = 0
		If PlannerToolTip Then PlannerToolTip.Update()
		If NewsGenreTooltip Then NewsGenreTooltip.Update()


		'no further interaction for other players newsrooms
		if not IsPlayersRoom(room) then return False

		'pinwall
		if not MouseManager.IsLongClicked(1)
			If THelper.IsIn(MouseManager.x, MouseManager.y, 167,60,240,160)
				If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
				PlannerToolTip.enabled = 1
				PlannerToolTip.Hover()
				GetGameBase().cursorstate = 1
				If MOUSEMANAGER.IsClicked(1)
					MOUSEMANAGER.resetKey(1)
					GetGameBase().cursorstate = 0
					ScreenCollection.GoToSubScreen("screen_newsstudio_newsplanner")
				endif
			endif
		endif
	End Function


	'could handle the buttons in one function ( by comparing triggerEvent._trigger )
	'onHover: handle tooltip
	Function onHoverNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0


		'how much levels do we have?
		local level:int = 0
		local genre:int = -1
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				genre = button.data.GetInt("newsGenre", i)
				level = GetPlayerCollection().Get(room.owner).GetNewsAbonnement( genre )
				exit
			endif
		Next

		if not NewsGenreTooltip then NewsGenreTooltip = TTooltip.Create("genre", "abonnement", 180,100 )
		NewsGenreTooltip.SetMinTitleAndContentWidth(180)
		NewsGenreTooltip.enabled = 1
		'refresh lifetime
		NewsGenreTooltip.Hover()

		'move the tooltip
		NewsGenreTooltip.area.position.SetXY(Max(21,button.rect.GetX() + button.rect.GetW()), button.rect.GetY()-30)

		If level = 0
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
			NewsGenreTooltip.content = getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ TNewsAgency.GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
		Else
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+level
			if level = GameRules.maxAbonnementLevel
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ ": 0" + getLocale("CURRENCY")
			Else
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ TNewsAgency.GetNewsAbonnementPrice(level+1)+getLocale("CURRENCY")
			EndIf
		EndIf
		if GetPlayer().GetNewsAbonnementDaysMax(genre) > level
			NewsGenreTooltip.content :+ "~n~n"
			local tip:String = getLocale("NEWSSTUDIO_YOU_ALREADY_USED_LEVEL_AND_THEREFOR_PAY")
			tip = tip.Replace("%MAXLEVEL%", GetPlayer().GetNewsAbonnementDaysMax(genre))
			tip = tip.Replace("%TOPAY%", TNewsAgency.GetNewsAbonnementPrice(GetPlayer().GetNewsAbonnementDaysMax(genre)) + getLocale("CURRENCY"))
			NewsGenreTooltip.content :+ getLocale("HINT")+": " + tip
		endif
	End Function


	Function onClickNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'wrong room? go away!
		if room.owner <> GetPlayerCollection().playerID then return 0

		'increase the abonnement
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				GetPlayer().IncreaseNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next
	End Function


	Function onDrawNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'how much levels do we have?
		local level:int = 0
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				level = GetPlayerCollection().Get(room.owner).GetNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next

		'draw the levels
		SetColor 0,0,0
		SetAlpha 0.4
		For Local i:Int = 0 to level-1
			DrawRect( button.rect.GetX()+8+i*10, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -7, 7,4)
		Next
		SetColor 255,255,255
		SetAlpha 1.0
	End Function



	'===================================
	'News: NewsPlanner screen
	'===================================

	Function onDrawNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0


		'create sign text image
		if not newsPlannerTextImage
			newsPlannerTextImage = TFunctions.CreateEmptyImage(310, 60)
			'render to image
			TBitmapFont.SetRenderTarget(newsPlannerTextImage)

			GetBitmapFont("default", 18).DrawBlock("An das Team~n|b|Folgende News senden:|/b|", 0, 0, 300, 50, ALIGN_CENTER_CENTER, TColor.CreateGrey(100))

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(null)
		endif
		SetRotation(-2.1)
		DrawImage(newsPlannerTextImage, 450, 30)
		SetRotation(0)

		SetColor 255,255,255  'normal
		GUIManager.Draw("Newsplanner")

	End Function


	Function onChangeNews:int( triggerEvent:TEventBase )
		'something changed -- refresh  gui elements
		RefreshGuiElements()
	End Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		guiNewsListAvailable.emptyList()
		guiNewsListUsed.emptyList()

		For local guiNews:TGuiNews = eachin GuiManager.listDragged.Copy()
			guiNews.remove()
			guiNews = null
		Next
		'should not be needed
		rem
		For local guiNews:TGuiNews = eachin GuiManager.list
			guiNews.remove()
			guiNews = null
		Next
		endrem
		haveToRefreshGuiElements = True
	End Function


	Function RefreshGuiElements:int()
		local owner:int = GetPlayerCollection().playerID
		'remove gui elements with news the player does not have anylonger
		For local guiNews:TGuiNews = eachin guiNewsListAvailable.entries.Copy()
			if not GetPlayerProgrammeCollection(owner).hasNews(guiNews.news)
				guiNews.remove()
				guiNews = null
			endif
		Next
		For local guiNews:TGuiNews = eachin guiNewsListUsed._slots
			if not GetPlayerProgrammePlan(owner).hasNews(guiNews.news)
				guiNews.remove()
				guiNews = null
			endif
		Next

		'if removing "dragged" we also bug out the "replace"-mechanism when
		'dropping on occupied slots
		'so therefor this items should check itself for being "outdated"
		'For local guiNews:TGuiNews = eachin GuiManager.ListDragged.Copy()
		'	if guiNews.news.isOutdated() then guiNews.remove()
		'Next

		'fill a list containing dragged news - so we do not create them again
		local draggedNewsList:TList = CreateList()
		For local guiNews:TGuiNews = eachin GuiManager.ListDragged
			draggedNewsList.addLast(guiNews.news)
		Next

		'create gui element for news still missing them
		For Local news:TNews = EachIn GetPlayerProgrammeCollection(owner).news
			'skip if news is dragged
			if draggedNewsList.contains(news) then continue

			if not guiNewsListAvailable.ContainsNews(news)
				'only add for news NOT planned in the news show
				if not GetPlayer().GetProgrammePlan().HasNews(news)
					local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
					guiNews.SetNews(news)
					guiNewsListAvailable.AddItem(guiNews)
				endif
			endif
		Next
		For Local i:int = 0 to GetPlayer().GetProgrammePlan().news.length - 1
			local news:TNews = TNews(GetPlayerProgrammePlanCollection().Get(owner).GetNews(i))
			'skip if news is dragged
			if news and draggedNewsList.contains(news) then continue

			if news and not guiNewsListUsed.ContainsNews(news)
				local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
				guiNews.SetNews(news)
				guiNewsListUsed.AddItem(guiNews, string(i))
			endif
		Next

		haveToRefreshGuiElements = FALSE
	End Function


	Function onUpdateNewsPlanner:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen(triggerEvent._sender)
		local room:TRoom		= TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetGameBase().cursorstate = 0

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset dragged block - will get set automatically on gui-update
		hoveredGuiNews = null
		draggedGuiNews = null


		'no GUI-interaction for other players rooms
		if not IsPlayersRoom(room) then return False

		'general newsplanner elements
		GUIManager.Update("Newsplanner")
	End Function


	'we need to know whether we dragged or hovered an item - so we
	'can react to right clicks ("forbid room leaving")
	Function onMouseOverNews:int( triggerEvent:TEventBase )
		local item:TGUINews = TGUINews(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiNews = item
		if item.isDragged() then draggedGuiNews = item

		return TRUE
	End Function


	'in case of right mouse button click we want to remove the
	'block from the player's programmePlan
	Function onClickNews:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiNews:TGUINews= TGUINews(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiNews or not guiNews.isDragged() then return FALSE

		'remove from plan (with addBackToCollection=FALSE) and collection
		local player:TPlayer = GetPlayerCollection().Get(guiNews.news.owner)
		player.GetProgrammePlan().RemoveNews(guiNews.news, -1, FALSE)
		player.GetProgrammeCollection().RemoveNews(guiNews.news)

		'remove gui object
		guiNews.remove()
		guiNews = null
		
		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
		'also avoid long click (touch screen)
		MouseManager.ResetLongClicked(1)
	End Function


	Function onDropNews:int(triggerEvent:TEventBase)
		local guiNews:TGUINews = TGUINews( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNews or not receiverList then return FALSE

		local player:TPlayer = GetPlayerCollection().Get(guiNews.news.owner)
		if not player then return False

		if receiverList = guiNewsListAvailable
			player.GetProgrammePlan().RemoveNews(guiNews.news, -1, TRUE)
		elseif receiverList = guiNewsListUsed
			local slot:int = -1
			'check drop position
			local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
			if coord then slot = guiNewsListUsed.GetSlotByCoord(coord)
			if slot = -1 then slot = guiNewsListUsed.getSlot(guiNews)

			'this may also drag a news that occupied that slot before
			player.GetProgrammePlan().SetNews(guiNews.news, slot)
		endif
	End Function


	'clear the guilist for the suitcase if a player enters
	'screens are only handled by real players
	Function onEnterNewsPlannerScreen:int(triggerEvent:TEventBase)
		'empty the guilist / delete gui elements
		RemoveAllGuiElements()
		RefreshGUIElements()
	End Function


	Function onLeaveNewsPlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving as long as we have a dragged block
		if draggedGuiNews
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function
End Type




'Chief: credit and emmys - your boss :D
Type RoomHandler_Boss extends TRoomHandler
	'smoke effect
	Global smokeEmitter:TSpriteParticleEmitter

	Global _instance:RoomHandler_Boss
	Global _initDone:int = False


	Function GetInstance:RoomHandler_Boss()
		if not _instance then _instance = new RoomHandler_Boss
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		if not smokeEmitter
			local smokeConfig:TData = new TData
			smokeConfig.Add("sprite", GetSpriteFromRegistry("gfx_misc_smoketexture"))
			smokeConfig.AddNumber("velocityMin", 2)
			smokeConfig.AddNumber("velocityMax", 13)
			smokeConfig.AddNumber("lifeMin", 0.3)
			smokeConfig.AddNumber("lifeMax", 2.5)
			smokeConfig.AddNumber("scaleMin", 0.05)
			smokeConfig.AddNumber("scaleMax", 0.10)
			smokeConfig.AddNumber("angleMin", 190)
			smokeConfig.AddNumber("angleMax", 215)
			smokeConfig.AddNumber("xRange", 2)
			smokeConfig.AddNumber("yRange", 2)

			local emitterConfig:TData = new TData
			emitterConfig.Add("area", new TRectangle.Init(49, 335, 0, 0))
			emitterConfig.AddNumber("particleLimit", 75)
			emitterConfig.AddNumber("spawnEveryMin", 0.50)
			emitterConfig.AddNumber("spawnEveryMax", 0.75)

			smokeEmitter = new TSpriteParticleEmitter.Init(emitterConfig, smokeConfig)
		endif
	End Method


	Method CleanUp()
		'
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("boss", GetInstance())
	End Method
	

	Method onDrawRoom:int( triggerEvent:TEventBase )
		smokeEmitter.Draw()

		local room:TRoom = TRoom(triggerEvent.GetSender())
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE


		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False
		For Local dialog:TDialogue = EachIn boss.Dialogues
			dialog.Draw()
		Next
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		GetPlayer().GetFigure().fromroom = Null

		smokeEmitter.Update()

		local room:TRoom = TRoom(triggerEvent._sender)
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE

		
		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		'generate the dialogue if not done yet
		If boss.Dialogues.Count() <= 0 then boss.GenerateDialogues(GetPlayer().playerID)
		For Local dialog:TDialogue = EachIn boss.Dialogues
			If dialog.Update() = 0
				GetPlayer().GetFigure().LeaveRoom()
				boss.Dialogues.Remove(dialog)
			endif
		Next
	End Method
End Type





