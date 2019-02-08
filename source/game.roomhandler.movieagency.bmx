SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "game.roomhandler.base.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.player.programmecollection.bmx"
Import "game.programme.programmelicence.gui.bmx"


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

	Field filterMoviesGood:TProgrammeLicenceFilterGroup {nosave}
	Field filterMoviesCheap:TProgrammeLicenceFilterGroup {nosave}
	Field filterSeries:TProgrammeLicenceFilter {nosave}
	Field filterAuction:TProgrammeLicenceFilterGroup {nosave}

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListMoviesGood:TGUIProgrammeLicenceSlotList = null
	Global GuiListMoviesCheap:TGUIProgrammeLicenceSlotList = null
	Global GuiListSeries:TGUIProgrammeLicenceSlotList = null
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = null

	global LS_movieagency:TLowerString = TLowerString.Create("movieagency")

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(350,130)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(14,25)
	Field programmesPerLine:int	= 13
	Field movieGoodMoneyMinimum:int = 170000
	Field movieGoodQualityMinimum:Float = 0.15
	Field movieCheapMoneyMaximum:int = 145000
	Field movieCheapQualityMaximum:Float = 0.50

	Global _instance:RoomHandler_MovieAgency
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_MovieAgency()
		if not _instance then _instance = new RoomHandler_MovieAgency
		return _instance
	End Function


	Method New()
		InitializeFilters()
	End Method


	Method InitializeFilters:int()
		if not filterMoviesGood
			filterMoviesGood = new TProgrammeLicenceFilterGroup
			filterMoviesGood.AddFilter(new TProgrammeLicenceFilter)
			filterMoviesGood.AddFilter(new TProgrammeLicenceFilter)
		endif
		if not filterMoviesCheap
			filterMoviesCheap = new TProgrammeLicenceFilterGroup
			filterMoviesCheap.AddFilter(new TProgrammeLicenceFilter)
			filterMoviesCheap.AddFilter(new TProgrammeLicenceFilter)
		endif
		if not filterSeries then filterSeries = new TProgrammeLicenceFilter

		'good movies must be more expensive than X _and_ of better
		'quality then Y
		rem
		filterMoviesGood.priceMin = movieGoodMoneyMinimum
		filterMoviesGood.priceMax = 500000
		filterMoviesGood.licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesGood.qualityMin = movieGoodQualityMinimum
		filterMoviesGood.qualityMax = -1.0
		filterMoviesGood.relativeTopicalityMin = 0.25
		filterMoviesGood.relativeTopicalityMax = -1.0
		filterMoviesGood.maxTopicalityMin = 0.45 'avoid older/broadcasted too often
		filterMoviesGood.maxTopicalityMax = -1.0
		filterMoviesGood.checkTradeability = True
		endrem

		filterMoviesGood.connectionType = TProgrammeLicenceFilterGroup.CONNECTION_TYPE_OR
		'filter 1 requires min-Price
		filterMoviesGood.filters[0].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesGood.filters[0].priceMin = movieGoodMoneyMinimum
		filterMoviesGood.filters[0].priceMax = -1
		filterMoviesGood.filters[0].relativeTopicalityMin = 0.25
		filterMoviesGood.filters[0].relativeTopicalityMax = -1.0
		filterMoviesGood.filters[0].maxTopicalityMin = 0.35 'avoid older/broadcasted too often
		filterMoviesGood.filters[0].maxTopicalityMax = -1.0
		filterMoviesGood.filters[0].checkTradeability = True
		filterMoviesGood.filters[0].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]
		'filter 2 requires min-Quality
		filterMoviesGood.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesGood.filters[1].qualityMin = movieCheapQualityMaximum
		filterMoviesGood.filters[1].qualityMax = -1.0
		filterMoviesGood.filters[1].relativeTopicalityMin = 0.25
		filterMoviesGood.filters[1].relativeTopicalityMax = -1.0
		filterMoviesGood.filters[1].maxTopicalityMin = 0.35 'avoid older/broadcasted too often
		filterMoviesGood.filters[1].maxTopicalityMax = -1.0
		filterMoviesGood.filters[1].checkTradeability = True
		filterMoviesGood.filters[1].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]

		'cheap movies must be cheaper than X _or_ of lower quality than Y
		filterMoviesCheap.connectionType = TProgrammeLicenceFilterGroup.CONNECTION_TYPE_OR

		filterMoviesCheap.filters[0].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesCheap.filters[0].priceMin = 0
		filterMoviesCheap.filters[0].priceMax = 0.75*movieCheapMoneyMaximum
		filterMoviesCheap.filters[0].relativeTopicalityMin = 0.25
		filterMoviesCheap.filters[0].relativeTopicalityMax = -1.0
		filterMoviesCheap.filters[0].maxTopicalityMin = 0.15 'avoid older/broadcasted too often
		filterMoviesCheap.filters[0].maxTopicalityMax = -1.0
		filterMoviesCheap.filters[0].checkTradeability = True
		filterMoviesCheap.filters[0].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]

		filterMoviesCheap.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesCheap.filters[1].priceMin = -1
		filterMoviesCheap.filters[1].priceMax = 1.0*movieCheapMoneyMaximum
		filterMoviesCheap.filters[1].qualityMin = -1.0
		filterMoviesCheap.filters[1].qualityMax = movieCheapQualityMaximum
		filterMoviesCheap.filters[1].relativeTopicalityMin = 0.25
		filterMoviesCheap.filters[1].relativeTopicalityMax = -1.0
		filterMoviesCheap.filters[1].maxTopicalityMin = 0.20 'avoid older/broadcasted too often
		filterMoviesCheap.filters[1].maxTopicalityMax = -1.0
		filterMoviesCheap.filters[1].checkTradeability = True
		filterMoviesCheap.filters[1].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]

		'filter them by price too - eg. for auction ?
		filterSeries.licenceTypes = [TVTProgrammeLicenceType.SERIES]
		'filterSeries.filters[0].SetRequiredOwners([TOwnedGameObject.OWNER_NOBODY])
		'as long as there are not that much series, allow 15% instead of 25%
		filterSeries.relativeTopicalityMin = 0.15
		filterSeries.relativeTopicalityMax = -1.0
		filterSeries.maxTopicalityMin = 0.25 'avoid older/broadcasted too often
		filterSeries.maxTopicalityMax = -1.0
		filterSeries.checkTradeability = True
		filterSeries.requiredOwners = [TOwnedGameObject.OWNER_NOBODY]


		if not filterAuction
			filterAuction = new TProgrammeLicenceFilterGroup
			filterAuction.AddFilter(new TProgrammeLicenceFilter)
			filterAuction.AddFilter(new TProgrammeLicenceFilter)

			'auction: either expensive - or - live programme
			filterAuction.filters[0].priceMin = 350000
			filterAuction.filters[0].priceMax = -1
			filterAuction.filters[0].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION, TVTProgrammeLicenceType.SERIES]
			'avoid "too used" licences
			filterAuction.filters[0].relativeTopicalityMin = 0.85
			filterAuction.filters[0].relativeTopicalityMax = -1.0
			filterAuction.filters[0].maxTopicalityMin = 0.85
			filterAuction.filters[0].maxTopicalityMax = -1.0
			filterAuction.filters[0].checkTradeability = True
			filterAuction.filters[0].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]

			'maximum of 1 year since release
			filterAuction.filters[1].priceMin = 100000
			filterAuction.filters[1].priceMax = -1
			filterAuction.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION, TVTProgrammeLicenceType.SERIES]
			filterAuction.filters[1].SetDataFlag(TVTProgrammeDataFlag.LIVE)
			filterAuction.filters[1].checkTradeability = True
			filterAuction.filters[1].timeToReleaseMin = 5 * TWorldTime.DAYLENGTH
			filterAuction.filters[1].checkTimeToReleaseMin = True
			filterAuction.filters[1].checkTimeToReleaseMax = False
			filterAuction.filters[1].checkAgeMin = False
			filterAuction.filters[1].checkAgeMax = False
			filterAuction.filters[1].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]
		endif

	End Method

	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		listMoviesGood = new TProgrammeLicence[programmesPerLine]
		listMoviesCheap = new TProgrammeLicence[programmesPerLine]
		listSeries = new TProgrammeLicence[programmesPerLine]



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

		'reset auction block caches
		_eventListeners :+ [ EventManager.registerListenerFunction("game.onSetActivePlayer", onResetAuctionBlockCache) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("station.onSetActive", onResetAuctionBlockCache) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("station.onSetInActive", onResetAuctionBlockCache) ]


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
		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		if not figure or not figure.playerID then return FALSE


		'=== FOR ALL PLAYERS ===
		'
		'fill all open slots in the agency
		GetInstance().ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'
		endif

		return True
	End Method


	'override: figure leaves room - only without dragged blocks
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
			if draggedGuiProgrammeLicence
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		return TRUE
	End Method


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		if not figure or not figure.playerID then return FALSE

		'=== FOR ALL PLAYERS ===
		'
		'print "player #" + figure.playerID +" leaves movieagency."

		'disabled auto-suitcase-readding
		'now we use
		'- readd when timer fires
		'- readd when going into another room than the movieagency
		'GetPlayerProgrammeCollection(figure.playerID).ReaddProgrammeLicencesFromSuitcase()

		local player:TPlayerBase = GetPlayerBase(figure.playerID)
		'empty suitcase after 20 realtime seconds
		if player
			player.emptyProgrammeSuitcase = True
			player.emptyProgrammeSuitcaseFromRoom = "movieagency"
			player.emptyProgrammeSuitcaseTime = Time.GetTimeGone() + 20 * 1000
		endif


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'
		endif

		return TRUE
	End Method


	'called as soon as a players figure is forced to leave the room
	Method onForcefullyLeaveRoom:int( triggerEvent:TEventBase )
		'only handle the player figures
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'=== FOR ALL PLAYERS ===
		'


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			AbortScreenActions()
		endif

		return True
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


	Method SellProgrammeLicenceToPlayer:int(licence:TProgrammeLicence, playerID:int, skipOwnerCheck:int=False)
		if licence.owner = playerID and not skipOwnerCheck then return FALSE

		if not GetPlayerBaseCollection().IsPlayer(playerID) then return FALSE

		'do not sell episodes/sub elements
		if licence.HasParentLicence() then return False

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
		'do not buy episodes/sub elements
		if licence.HasParentLicence() then return False
		'do not buy if unowned
		if not licence.isOwnedByPlayer() then return False
		'do not buy if not tradeable
		if not licence.IsTradeable() then return False

		'remove from player (lists and suitcase) - and give him money
		if not GetPlayerProgrammeCollection(licence.owner).RemoveProgrammeLicence(licence, TRUE)
			return False
		endif

		'add to agency's lists - if not existing yet
		if not HasProgrammeLicence(licence) then AddProgrammeLicence(licence)

		return TRUE
	End Method


	Method AddProgrammeLicence:int(licence:TProgrammeLicence, tryOtherLists:int = False)
		'do not add if still owned by a player or the vendor
		if licence.isOwned()
			TLogger.Log("MovieAgency", "AddProgrammeLicence() failed: cannot add licence owned by someone else. Owner="+licence.owner+"! Report to developers asap.", LOG_ERROR)
			return False
		endif

		'try to fill the licence into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TProgrammeLicence[][]

		'do not add episodes or collection elements
		if licence.isEpisode() or licence.isCollectionElement()
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
			if GetPlayerProgrammeCollection(GetPlayerBaseCollection().playerID).HasProgrammeLicenceInSuitcase(guiLicence.licence) then continue

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
		For local licence:TProgrammeLicence = eachin GetPlayerProgrammeCollection(GetPlayerBaseCollection().playerID).suitcaseProgrammeLicences
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


		'collect as many random licences per list as needed ("empty slots")
		local licencesPerList:TProgrammeLicence[][]

		for local listIndex:int = 0 to lists.length-1
			local needed:int = 0
			for local entryIndex:int = 0 to lists[listIndex].length-1
				if lists[listIndex][entryIndex] then continue
				needed :+ 1
			Next

			if needed
				local licences:TProgrammeLicence[]
				Select lists[listIndex]
					case listMoviesGood
						licences = GetProgrammeLicenceCollection().GetRandomsByFilter(filterMoviesGood, needed)
					case listMoviesCheap
						licences = GetProgrammeLicenceCollection().GetRandomsByFilter(filterMoviesCheap, needed)
					case listSeries
						licences = GetProgrammeLicenceCollection().GetRandomsByFilter(filterSeries, needed)
				End Select
				'fill to "needed" (with null values!)
				if not licences
					licences = new TProgrammeLicence[needed]
				elseif licences.length < needed
'					print "not enough licences: needed=" + needed+"  got="+licences.length
					licences = licences[.. needed]
				endif

				licencesPerList :+ [licences] 'array of arrays
			else
				'add empty, so that indices stay intact
				licencesPerList :+ [new TProgrammeLicence[0]]
			endif
		Next


		'fill empty slots
		for local listIndex:int = 0 to lists.length-1
			local warnedOfMissingLicence:int = False
			local licenceIndex:int = 0
			for local entryIndex:int = 0 until lists[listIndex].length
				'if exists...skip it
				if lists[listIndex][entryIndex] then continue

				local licence:TProgrammeLicence = licencesPerList[listIndex][licenceIndex]
				licenceIndex :+ 1

				'add new licence at slot
				if licence
					licence.SetOwner(licence.OWNER_VENDOR)
					lists[listIndex][entryIndex] = licence
				else
					if not warnedOfMissingLicence
						TLogger.log("MovieAgency.RefillBlocks()", "Not enough licences to refill slot["+entryIndex+"+] in list["+listIndex+"]", LOG_WARNING | LOG_DEBUG)
						warnedOfMissingLicence = True
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
rem
		'disable non-tradeable licences (or vice versa)
		For local guiLicence:TGUIProgrammeLicence = eachin GuiListSuitcase._slots
			if not guiLicence.licence then continue
			if not guiLicence.licence.IsTradeable()
				if guiLicence.IsEnabled() then guiLicence.Disable()
			else
				if not guiLicence.IsEnabled() then guiLicence.Enable()
			endif
		Next
endrem

		if AuctionEntity Then AuctionEntity.Update()
		if VendorEntity Then VendorEntity.Update()
	End Method


	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiProgrammeLicence = item

		'only handle dragged for the real player
		if CheckPlayerInRoom("movieagency")
			if item.isDragged() then draggedGuiProgrammeLicence = item
		endif

		return TRUE
	End Function


	'check if we are allowed to drag that licence
	Function onDragProgrammeLicence:int( triggerEvent:TEventBase )
		if not CheckPlayerInRoom("movieagency") then return FALSE

		local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		if item = Null then return FALSE

		local owner:int = item.licence.owner

		'do not allow dragging items from other players
		if owner > 0 and owner <> GetPlayerBaseCollection().playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		if owner <= 0
			if not GetPlayerBase().getFinance().canAfford(item.licence.getPriceForPlayer( GetObservedPlayerID() ))
				triggerEvent.setVeto()
				return FALSE
			endif
		endif

		'check whether a player could sell the licence
		'if not - just veto the event so it does not get dragged
		if owner = GetPlayerBaseCollection().playerID
			if not item.licence.IsTradeable()
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
				if guiLicence.licence.owner = GetPlayerBaseCollection().playerID then return TRUE

				if not GetPlayerBase().getFinance().canAfford(guiLicence.licence.getPriceForPlayer( GetObservedPlayerID() ))
					triggerEvent.setVeto()
				endif
		End select

		return TRUE
	End Function


	Function onResetAuctionBlockCache:int( triggerEvent:TEventBase )
		TAuctionProgrammeBlocks.ClearCaches()
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
				if guiLicence.licence.owner = GetPlayerBaseCollection().playerID then return TRUE

				if not GetInstance().SellProgrammeLicenceToPlayer(guiLicence.licence, GetPlayerBaseCollection().playerID)
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
			SetAlpha oldCol.a * Float(0.4 + 0.2 * sin(Time.GetAppTimeGone() / 5))

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

		GUIManager.Draw( LS_movieagency )

		if hoveredGuiProgrammeLicence
			'draw the current sheet
			hoveredGuiProgrammeLicence.DrawSheet()
		endif


		If AuctionToolTip Then AuctionToolTip.Render()
	End Function


	Function onUpdateMovieAgency:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetGameBase().cursorstate = 0

		if CheckPlayerInRoom("movieagency")
			'show a auction-tooltip (but not if we dragged a block)
			if not hoveredGuiProgrammeLicence
				if not MouseManager.IsLongClicked(1)
					If THelper.MouseIn(210,220,140,60)
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

			GUIManager.Update( LS_movieagency )

			If AuctionToolTip Then AuctionToolTip.Update()
		endif
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

		GUIManager.Draw( LS_movieagency )
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

		if CheckPlayerInRoom("movieagency")
			TAuctionProgrammeBlocks.UpdateAll()
		endif

		'remove old tooltips from previous screens
		If AuctionToolTip Then AuctionToolTip = null
	End Function
End Type




'Programmeblocks used in Auction-Screen
'they do not need to have gui/non-gui objects as no special
'handling is done (just clicking)
Type TAuctionProgrammeBlocks Extends TGameObject {_exposeToLua="selected"}
	Field area:TRectangle = New TRectangle.Init(0,0,0,0)
	Field licence:TProgrammeLicence		'the licence getting auctionated (a series, movie or collection)
	Field bestBidRaw:Int = 0			'what was bidden for that licence without audience reach level
	Field bestBid:Int = 0				'what was bidden for that licence with audience reach level
	Field bestBidder:Int = 0			'who bid for that licence
	Field bestBidderLevel:Int = 1		'what was the audience reach level when bidding
	Field slot:Int = 0					'for ordering (and displaying sheets without overlapping)
	Field bidSavings:Float = 0.75		'how much to shape of the original price
	Field maxAuctionTime:Long = -1
	Field _bidSavingsMinimum:Float = -1
	Field _bidSavingsMaximum:Float = -1
	Field _bidSavingsDecreaseBy:Float = -1

	'cached image
	Field _imageWithText:TImage = Null {nosave}

	Global List:TList = CreateList()	'list of all blocks

	'todo/idea: we could add a "started" and a "endTime"-field so
	'           auctions do not end at midnight but individually

	Method GenerateGUID:string()
		return "auctionprogrammeblocks-"+id
	End Method


	Method Create:TAuctionProgrammeBlocks(slot:Int=0, licence:TProgrammeLicence)
		Self.area.position.SetXY(140 + (slot Mod 2) * 260, 80 + int(Ceil(slot / 2)) * 60)
		Self.area.dimension.CopyFrom(GetSpriteFromRegistry("gfx_auctionmovie").area.dimension)
		Self.slot = slot
		Self.Refill(licence)
		List.AddLast(Self)

		'sort so that slot1 comes before slot2 without having to matter about creation order
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return Self
	End Method


	Function ClearCaches:int()
		for local block:TAuctionProgrammeBlocks = EachIn List
			block._imageWithText = null
		next
	End Function


	Function Initialize:int()
		list.Clear()
	End Function


	Function GetByIndex:TAuctionProgrammeBlocks(index:int)
		if index < 0 then index = 0
		if index >= list.Count() then return null

		return TAuctionProgrammeBlocks( list.ValueAtIndex(index) )
	End Function


	Function GetByLicence:TAuctionProgrammeBlocks(licence:TProgrammeLicence, licenceGUID:string="")
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If licence And obj.licence = licence Then Return obj
			If obj.licence and obj.licence.GetGUID() = licenceGUID Then Return obj
		Next
		Return Null
	End Function


	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o1)
		Local s2:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function


	'give all won auctions to the winners
	Function EndAllAuctions()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			obj.EndAuction()
		Next
	End Function


	Function GetCurrentLiveOffers:int()
		local res:int = 0
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			if obj.licence and obj.licence.IsLive() then res :+1
		Next
		return res
	End Function


	'refill all auctions without bids
	Function RefillAuctionsWithoutBid()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If Not obj.bestBidder
				obj.Refill()
				if not obj.licence then print "RefillAuctionsWithoutBid: no licence available"
			endif
		Next
	End Function


	Method GetBidSavingsMaximum:Float()
		if _bidSavingsMaximum = -1.0
			_bidSavingsMaximum = RandRange(80,90) / 100.0 '0.8 - 0.9
		endif
		return _bidSavingsMaximum
	End Method


	Method GetBidSavingsMinimum:Float()
		if _bidSavingsMinimum = -1.0
			'0.55 - (Max-0.05)
			_bidSavingsMinimum = RandRange(55, int(100*(GetBidSavingsMaximum()-0.05))) / 100.0
		endif
		return _bidSavingsMinimum
	End Method


	Method GetBidSavingsDecreaseBy:Float()
		if _bidSavingsDecreaseBy = -1.0
			'0.05 - 0.10
			_bidSavingsDecreaseBy = RandRange(5, 10) / 100.0
		endif
		return _bidSavingsDecreaseBy
	End Method


	Method GetMaxAuctionTime:Long(useLicence:TProgrammeLicence = null)
		if not useLicence then useLicence = licence

		'limit live programme by their airTime - 1 day
		if useLicence and useLicence.IsLive()
			return useLicence.data.GetReleaseTime() - 1 * TWorldTime.DAYLENGTH
		endif

		return maxAuctionTime
	End Method


	'sets another licence into the slot
	Method Refill:Int(programmeLicence:TProgrammeLicence=Null)
		'if licence
		'	print "Refill: " + licence.GetTitle()
		'else
		'	print "Refill: Initial call"
		'endif
		'turn back licence if nobody bought the old one
		if licence and licence.owner = TOwnedGameObject.OWNER_VENDOR
			licence.SetOwner( TOwnedGameObject.OWNER_NOBODY )
			'no longer ignore player difficulty
			licence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, False)
			'print "   gave back licence"
		endif

		'backup old licence if a new is to find - but eg. fails (no live)
		local oldLicence:TProgrammeLicence
		if not programmeLicence then oldLicence = licence
		licence = programmeLicence

		'try to find a "live" programme first
		if GetCurrentLiveOffers() < 3
			'print "   try to find live one"
			local keepOld:int = False
			'keep an old live programme if it airs _after_ the next day
			if not bestBidder and GetMaxAuctionTime() > GetWorldTime().GetTimeGone()
				'print "   keep as still in the future"
				keepOld = true
				licence = oldLicence
			endif

			if not keepOld
				'print "   find new live one"
				'Searching can be a bit "slow" on huge databases, so we
				'try to avoid to iterate over all licences each time
				'-> start with a "loose" filter to limit candidate list
				local filterLiveNum:int = 1 '0 = normal programme, 1 = live
				local filter:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterAuction.filters[filterLiveNum].Copy()
				local oldPriceMin:int = filter.priceMin
				'only take live-programme starting not earlier than 3 days
				'from now. This is needed to avoid a "live"-programme
				'being no longer live
				filter.timeToReleaseMin = 2 * TWorldTime.DAYLENGTH
				'do not limit too much
				filter.priceMin = 0

				'fetch candidates
				local candidates:TProgrammeLicence[] = GetProgrammeLicenceCollection().GetByFilter(filter)
				if candidates.length > 0
					filter.priceMin = oldPriceMin
					While Not licence And filter.priceMin >= 0
						licence = GetProgrammeLicenceCollection().GetRandomByFilter(filter, candidates)
						'lower the requirements
						If Not licence then filter.priceMin :- 25000
					End While
				endif
			endif
		endif


		'find a normal licence
		if not licence
			'print "   find new one"
			local filterGroup:TProgrammeLicenceFilterGroup = TProgrammeLicenceFilterGroup(RoomHandler_MovieAgency.GetInstance().filterAuction.Copy())
			While Not licence And filterGroup.filters[0].priceMin >= 0
				licence = GetProgrammeLicenceCollection().GetRandomByFilter(filterGroup)
				'lower the requirements
				If Not licence
					filterGroup.filters[0].priceMin :- 5000
					filterGroup.filters[0].ageMax :+ TWorldTime.DAYLENGTH

					filterGroup.filters[1].priceMin = Max(0, filterGroup.filters[1].priceMin - 5000)
				endif
			Wend
		endif
		If not licence
			TLogger.log("AuctionProgrammeBlocks.Refill()", "No licences for new auction found. Database needs more entries!", LOG_ERROR)
			'If Not licence Then Throw "[ERROR] TAuctionProgrammeBlocks.Refill - no licence"
		EndIf

		if licence
			'print "   found " + licence.GetTitle()
			'set licence owner to "-1" so it gets not returned again from Random-Getter
			licence.SetOwner( TOwnedGameObject.OWNER_VENDOR )

			'reset auctionPrice-Mod
			'ATTENTION: during "filtering" the price might have been
			'           modified by this modifier - for now we ignore
			'           the fact it could not have passed the filter...
			licence.SetModifier("auctionPrice", 1.0)
			licence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, True)
		endif

		'reset cache
		_imageWithText = Null
		'reset bids
		bestBidRaw = 0
		bestBid = 0
		bestBidder = 0
		bestBidderLevel = 1
		_bidSavingsDecreaseBy = -1
		_bidSavingsMaximum = -1
		_bidSavingsMinimum = -1
		bidSavings = 0.75

		'emit event
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.Refill", New TData.Add("licence", licence).AddNumber("slot", slot), Self))
	End Method


	Method EndAuction:Int()
		'if there was no licence stored, try again to refill the block
		If not licence
			Refill()
			Return False
		EndIf


		If bestBidder and GetPlayerBaseCollection().IsPlayer(bestBidder)
			'modify licences new price until a new auction of this licence
			'might reset it
			licence.SetModifier("auctionPrice", Float(bestBid) / licence.GetPriceForPlayer(bestBidder, bestBidderLevel))

			?debug
			print "modifier auctionPrice=" + Float(bestBid) / licence.GetPriceForPlayer(bestBidder, bestBidderLevel)
			print "endAuction: price for p0="+licence.GetPriceForPlayer(0)
			for local i:int = 1 to 4
				print "endAuction: price for p"+i+"="+licence.GetPriceForPlayer(i, GetPlayerBase(i).GetAudienceReachLevel()) + " audienceLevel="+GetPlayerBase(i).GetAudienceReachLevel()
			next
			?

			Local player:TPlayerBase = GetPlayerBase(bestBidder)
			GetPlayerProgrammeCollection(player.playerID).AddProgrammeLicence(licence)
			if not GetPlayerProgrammeCollection(player.playerID).HasProgrammeLicence(licence)
				TLogger.Log("EndAuction", "Not able to add won auction to programmeCollection: ~q"+ licence.GetGUID()+"~q.", LOG_ERROR)
			else

				If player.isLocalAI()
					player.PlayerAI.CallOnProgrammeLicenceAuctionWin(licence, bestBid)
				EndIf

				'emit event so eg. toastmessages could attach
				Local evData:TData = New TData
				evData.Add("licence", licence)
				evData.AddNumber("bestBidder", player.playerID)
				evData.AddNumber("bestBidderLevel", bestBidderLevel)
				evData.AddNumber("bestBidRaw", bestBidRaw)
				evData.AddNumber("bestBid", bestBid)
				EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onWin", evData, Self))
			endif
		End If


		'found nobody to buy this licence
		'so we decrease price a bit
		If Not bestBidder
			Self.bidSavings :- Self.GetBidSavingsDecreaseBy()
		EndIf


		'actually need to end the auction instead of just decreasing
		'minimum bid?
		local auctionEnds:int = False

		'if we had a bidder or found nobody with the allowed price minimum
		'we add another licence to this block and reset everything
		If bestBidder Or Self.bidSavings < Self.GetBidSavingsMinimum()
			auctionEnds = True
		'is time for this auction gone (eg. live-programme has limits)?
		Else
			local maxTime:Long = GetMaxAuctionTime(licence)
			if maxTime <> -1 and maxTime < GetWorldTime().GetTimeGone()
				auctionEnds = True
				'print "maxAuctionTime reached: " + licence.GetTitle()
			endif
		endif

		if auctionEnds
			'emit event
			Local evData:TData = New TData
			evData.Add("licence", licence)
			evData.AddNumber("bestBidder", bestBidder)
			evData.AddNumber("bestBidderLevel", bestBidderLevel)
			evData.AddNumber("bestBidRaw", bestBidRaw)
			evData.AddNumber("bestBid", bestBid)
			evData.AddNumber("bidSavings", bidSavings)
			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onEndAuction", evData, Self))

			Refill()
			return True
		endif


		'reset cache
		_imageWithText = Null

		return False
	End Method


	Method GetLicence:TProgrammeLicence()  {_exposeToLua}
		Return licence
	End Method


	Method SetBid:Int(playerID:Int)
		If not licence Then Return -1

		Local player:TPlayerBase = GetPlayerBase(playerID)
		If Not player Then Return -1
		'if the playerID was -1 ("auto") we should assure we have a correct id now
		playerID = player.playerID
		'already highest bidder, no need to add another bid
		If playerID = bestBidder Then Return 0


		'prices differ between the players - depending on their audience
		'reach level
		Local audienceReachLevel:int = Max(1, GetPlayerBase(playerID).GetAudienceReachLevel())
		Local thisBidRaw:Int = GetNextBidRaw()
		Local thisBid:Int = thisBidRaw * licence.GetAudienceReachLevelPriceMod(audienceReachLevel)

		If player.getFinance().PayAuctionBid(thisBid, Self.GetLicence())
			'another player was highest bidder, we pay him back the
			'bid he gave (which is the currently highest bid...)
			If bestBidder And GetPlayerBase(bestBidder)
				'bestBid contains the best bid adjusted for this players
				'reach level - so we need to calculate it properly
				local previousPaidBestBid:int = bestBidRaw * licence.GetAudienceReachLevelPriceMod(bestBidderLevel)
				GetPlayerFinance(bestBidder).PayBackAuctionBid(previousPaidBestBid, Self)

				'inform player AI that their bid was overbid
				If GetPlayerBase(bestBidder).isLocalAI()
					local thisPaidBestBid:int = thisBidRaw * licence.GetAudienceReachLevelPriceMod(audienceReachLevel)
					GetPlayerBase(bestBidder).PlayerAI.CallOnProgrammeLicenceAuctionGetOutbid(GetLicence(), thisPaidBestBid, playerID)
				EndIf

				'emit event so eg. toastmessages could attach
				Local evData:TData = New TData
				evData.Add("licence", GetLicence())
				evData.AddNumber("previousBestBidder", bestBidder)
				evData.AddNumber("previousBestBidderLevel", bestBidderLevel)
				evData.AddNumber("previousBestBid", bestBid)
				evData.AddNumber("previousBestBidRaw", bestBidRaw)
				evData.AddNumber("bestBidder", playerID)
				evData.AddNumber("bestBidderLevel", audienceReachLevel)
				evData.AddNumber("bestBid", thisBid)
				evData.AddNumber("bestBidRaw", thisBidRaw)
				EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onGetOutbid", evData, Self))
			EndIf
			'set new bid values
			bestBidder = playerID
			bestBidderLevel = audienceReachLevel
			bestBidRaw = thisBidRaw
			bestBid = thisBid


			'reset so cache gets renewed
			_imageWithText = Null

			'emit event
			Local evData:TData = New TData
			evData.Add("licence", GetLicence())
			evData.AddNumber("bestBidder", bestBidder)
			evData.AddNumber("bestBidderLevel", bestBidderLevel)
			evData.AddNumber("bestBid", bestBid)
			evData.AddNumber("bestBidRaw", bestBidRaw)
			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.setBid", evData, Self))

			Return bestBid
		EndIf

		Return 0
	End Method


	Method GetNextBid:Int(playerID:int) {_exposeToLua}
		if not licence then return -1

		Local audienceReachLevel:int = Max(1, GetPlayerBase(playerID).GetAudienceReachLevel())
		return GetNextBidRaw() * licence.GetAudienceReachLevelPriceMod(audienceReachLevel)
	End Method


	Method GetNextBidRaw:Int()
		If not licence Then Return -1

		Local nextBidRaw:Int = 0
		'no bid done yet, next bid is the licences price cut by 25%
		If bestBid = 0
			nextBidRaw = licence.getPriceForPlayer(0, 0) * bidSavings
			nextBidRaw = TFunctions.RoundToBeautifulValue(nextBidRaw)
		Else
			nextBidRaw = bestBidRaw

			If nextBidRaw < 100000
				nextBidRaw :+ 10000
			Else If nextBidRaw < 250000
				nextBidRaw :+ 25000
			Else If nextBidRaw < 750000
				nextBidRaw :+ 50000
			Else
				nextBidRaw :+ 75000
			EndIf
		EndIf

		Return nextBidRaw
	End Method


	Method ShowSheet:Int(x:Int,y:Int)
		If not licence Then Return -1

		licence.ShowSheet(x,y)
	End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		If not licence Then Return

		SetColor 255,255,255  'normal
		'not yet cached?
	    If Not _imageWithText
			'print "renew cache for "+self.licence.GetTitle()
			_imageWithText = GetSpriteFromRegistry("gfx_auctionmovie").GetImageCopy()
			If Not _imageWithText Then Throw "GetImage Error for gfx_auctionmovie"

			Local pix:TPixmap = LockImage(_imageWithText)
			Local font:TBitmapFont = GetBitmapFont("Default", 12)
			Local titleFont:TBitmapFont	= GetBitmapFont("Default", 12, BOLDFONT)

			'set target for fonts
			TBitmapFont.setRenderTarget(_imageWithText)

			If bestBidder
				Local player:TPlayerBase = GetPlayerBase(bestBidder)
				titleFont.drawStyled(player.name, 31,33, player.color, 2, 1, 0.25)
			Else
				font.drawStyled(GetLocale("AUCTION_WITHOUT_BID"), 31,33, TColor.CreateGrey(150), 0, 1, 0.25)
			EndIf
			titleFont.drawBlock(licence.GetTitle(), 31,5, 215,30, ALIGN_LEFT_TOP, TColor.clBlack, 1, 1, 0.50)

			font.drawBlock(GetLocale("AUCTION_MAKE_BID")+": "+MathHelper.DottedValue(GetNextBid(GetPlayerBase().playerID))+CURRENCYSIGN, 31,33, 212,20, ALIGN_RIGHT_TOP, TColor.clBlack, 1)

			'reset target for fonts
			TBitmapFont.setRenderTarget(Null)
	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(_imageWithText, area.GetX(), area.GetY())

		'live
		If licence.data.IsLive()
			GetSpriteFromRegistry("pp_live").Draw(area.GetX() + _imageWithText.width - 8, area.GetY() +3,  -1, ALIGN_RIGHT_TOP)
		EndIf
		'xrated
		If licence.data.IsXRated()
			GetSpriteFromRegistry("pp_xrated").Draw(area.GetX() + _imageWithText.width - 8, area.GetY() +3,  -1, ALIGN_RIGHT_TOP)
		EndIf
		'paid
		If licence.data.IsPaid()
			GetSpriteFromRegistry("pp_paid").Draw(area.GetX() + _imageWithText.width - 8, area.GetY() +3,  -1, ALIGN_RIGHT_TOP)
		EndIf

		If TVTDebugInfos
			local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(area.GetX(), area.GetY(), _imageWithText.width, _imageWithText.height)
			SetColor 255,255,255
			SetAlpha oldAlpha

			GetBitmapFont("default", 12).Draw("bidSavings="+MathHelper.NumberToString(bidSavings, 4) + "  Min="+MathHelper.NumberToString(GetBidSavingsMinimum(), 4) + "  Decr="+MathHelper.NumberToString(GetBidSavingsDecreaseBy(), 4), area.getX() + 5, area.GetY() + 5)
			GetBitmapFont("default", 12).Draw("bestBidder="+bestBidder +"  lvl="+bestBidderLevel+ "  bestBidRaw="+bestBidRaw, area.getX() + 5, area.GetY() + 5 + 12)
			GetBitmapFont("default", 12).Draw("nextBidRaw="+GetNextBidRaw() + "  MyReachLevel("+GetPlayerBase().playerID+")="+Max(1, GetPlayerBase(GetPlayerBase().playerID).GetAudienceReachLevel()), area.getX() + 5, area.GetY() + 5 + 2*12)
		endif

    End Method


	Function DrawAll()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If not obj.GetLicence() Then continue

			obj.Draw()
		Next

		'draw sheets (must be afterwards to avoid overlapping (itemA Sheet itemB itemC) )
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If not obj.GetLicence() Then continue

			If obj.area.containsXY(MouseManager.x, MouseManager.y)
				Local leftX:Int = 30, rightX:Int = 30
				Local sheetY:Int = 20
				Local sheetX:Int = leftX
				Local sheetAlign:Int= 0
				'if mouse on left side of screen - align sheet on right side
				If MouseManager.x < GetGraphicsManager().GetWidth()/2
					sheetX = GetGraphicsManager().GetWidth() - rightX
					sheetAlign = 1
				EndIf

				SetBlend LightBlend
				SetAlpha 0.20
				GetSpriteFromRegistry("gfx_auctionmovie").Draw(obj.area.GetX(), obj.area.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend


				obj.licence.ShowSheet(sheetX, sheetY, sheetAlign, TVTBroadcastMaterialType.PROGRAMME)
				Exit
			EndIf
		Next
	End Function



	Function UpdateAll:Int()
		'without clicks we do not need to handle things
		If Not MOUSEMANAGER.IsClicked(1) Then Return False

		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If not obj.GetLicence() Then continue

			If obj.bestBidder <> GetPlayerBaseCollection().playerID And obj.area.containsXY(MouseManager.x, MouseManager.y)
				obj.SetBid( GetPlayerBaseCollection().playerID )  'set the bid
				MOUSEMANAGER.ResetKey(1)
				Return True
			EndIf
		Next
	End Function

End Type