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

		if not GetPlayerBaseCollection().IsPlayer(playerID) then return FALSE

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
		if owner > 0 and owner <> GetPlayerBaseCollection().playerID
			triggerEvent.setVeto()
			return FALSE
		endif

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		if owner <= 0
			if not GetPlayerBase().getFinance().canAfford(item.licence.getPrice())
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

				if not GetPlayerBase().getFinance().canAfford(guiLicence.licence.getPrice())
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




'Programmeblocks used in Auction-Screen
'they do not need to have gui/non-gui objects as no special
'handling is done (just clicking)
Type TAuctionProgrammeBlocks Extends TGameObject {_exposeToLua="selected"}
	Field area:TRectangle = New TRectangle.Init(0,0,0,0)
	Field licence:TProgrammeLicence		'the licence getting auctionated (a series, movie or collection)
	Field bestBid:Int = 0				'what was bidden for that licence
	Field bestBidder:Int = 0			'what was bidden for that licence
	Field slot:Int = 0					'for ordering (and displaying sheets without overlapping)
	Field bidSavings:Float = 0.75		'how much to shape of the original price
	Field _bidSavingsMinimum:Float = -1
	Field _bidSavingsMaximum:Float = -1
	Field _bidSavingsDecreaseBy:Float = -1
	
	'cached image
	Field _imageWithText:TImage = Null {nosave}

	Global List:TList = CreateList()	'list of all blocks

	'todo/idea: we could add a "started" and a "endTime"-field so
	'           auctions do not end at midnight but individually


	Method Create:TAuctionProgrammeBlocks(slot:Int=0, licence:TProgrammeLicence)
		Self.area.position.SetXY(140 + (slot Mod 2) * 260, 80 + Ceil(slot / 2) * 60)
		Self.area.dimension.CopyFrom(GetSpriteFromRegistry("gfx_auctionmovie").area.dimension)
		Self.slot = slot
		Self.Refill(licence)
		List.AddLast(Self)

		'sort so that slot1 comes before slot2 without having to matter about creation order
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return Self
	End Method


	Function Initialize:int()
		list.Clear()
	End Function
	

	Function GetByLicence:TAuctionProgrammeBlocks(licence:TProgrammeLicence, licenceID:Int=-1)
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If licence And obj.licence = licence Then Return obj
			If obj.licence and obj.licence.id = licenceID Then Return obj
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
	 

	'sets another licence into the slot
	Method Refill:Int(programmeLicence:TProgrammeLicence=Null)
		'turn back licence if nobody bought the old one
		if licence and licence.owner = TOwnedGameObject.OWNER_VENDOR
			licence.SetOwner( TOwnedGameObject.OWNER_NOBODY )
		endif
	
		licence = programmeLicence

		local filter:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterAuction.Copy()

		While Not licence And filter.priceMin >= 0
			licence = GetProgrammeLicenceCollection().GetRandomByFilter(filter)
			'lower the requirements
			If Not licence
				filter.priceMin :- 5000
				filter.ageMax :+ TWorldTime.DAYLENGTH
			endif
		Wend
		If not licence
			TLogger.log("AuctionProgrammeBlocks.Refill()", "No licences for new auction found. Database needs more entries!", LOG_ERROR)
			'If Not licence Then Throw "[ERROR] TAuctionProgrammeBlocks.Refill - no licence"
		EndIf

		if licence
			'set licence owner to "-1" so it gets not returned again from Random-Getter
			licence.SetOwner( TOwnedGameObject.OWNER_VENDOR )
		endif
		
		'reset cache
		_imageWithText = Null
		'reset bids
		bestBid = 0
		bestBidder = 0
		_bidSavingsDecreaseBy = -1
		_bidSavingsMaximum = -1
		_bidSavingsMinimum = -1

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
			Local player:TPlayerBase = GetPlayerBase(bestBidder)
			GetPlayerProgrammeCollection(player.playerID).AddProgrammeLicence(licence)

			If player.isLocalAI()
				player.PlayerAI.CallOnProgrammeLicenceAuctionWin(licence, bestBid)
			EndIf

			'emit event so eg. toastmessages could attach
			Local evData:TData = New TData
			evData.Add("licence", licence)
			evData.AddNumber("bestBidder", player.playerID)
			evData.AddNumber("bestBid", bestBid)
			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onWin", evData, Self))
		End If

		'emit event
		Local evData:TData = New TData
		evData.Add("licence", licence)
		evData.AddNumber("bestBidder", bestBidder)
		evData.AddNumber("bestBid", bestBid)
		evData.AddNumber("bidSavings", bidSavings)
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onEndAuction", evData, Self))

		'found nobody to buy this licence
		'so we decrease price a bit
		If Not bestBidder
			Self.bidSavings :- Self.GetBidSavingsDecreaseBy()
		EndIf

		'if we had a bidder or found nobody with the allowed price minimum
		'we add another licence to this block and reset everything
		If bestBidder Or Self.bidSavings < Self.GetBidSavingsMinimum()
			Refill()
		EndIf
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

		Local price:Int = GetNextBid()
		If player.getFinance().PayAuctionBid(price, Self.GetLicence())
			'another player was highest bidder, we pay him back the
			'bid he gave (which is the currently highest bid...)
			If bestBidder And GetPlayerBase(bestBidder)
				GetPlayerFinance(bestBidder).PayBackAuctionBid(bestBid, Self)

				'inform player AI that their bid was overbid
				If GetPlayerBase(bestBidder).isLocalAI()
					GetPlayerBase(bestBidder).PlayerAI.CallOnProgrammeLicenceAuctionGetOutbid(GetLicence(), price, playerID)
				EndIf
				
				'emit event so eg. toastmessages could attach
				Local evData:TData = New TData
				evData.Add("licence", GetLicence())
				evData.AddNumber("previousBestBidder", bestBidder)
				evData.AddNumber("previousBestBid", bestBid)
				evData.AddNumber("bestBidder", playerID)
				evData.AddNumber("bestBid", price)
				EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onGetOutbid", evData, Self))
			EndIf
			'set new bid values
			bestBidder = playerID
			bestBid = price


			'reset so cache gets renewed
			_imageWithText = Null

			'emit event
			Local evData:TData = New TData
			evData.Add("licence", GetLicence())
			evData.AddNumber("bestBidder", bestBidder)
			evData.AddNumber("bestBid", bestBid)
			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.setBid", evData, Self))
		EndIf
		Return price
	End Method


	Method GetNextBid:Int() {_exposeToLua}
		If not licence Then Return -1

		Local nextBid:Int = 0
		'no bid done yet, next bid is the licences price cut by 25%
		If bestBid = 0
			nextBid = licence.getPrice() * 0.75
		Else
			nextBid = bestBid

			If nextBid < 100000
				nextBid :+ 10000
			Else If nextBid >= 100000 And nextBid < 250000
				nextBid :+ 25000
			Else If nextBid >= 250000 And nextBid < 750000
				nextBid :+ 50000
			Else If nextBid >= 750000
				nextBid :+ 75000
			EndIf
		EndIf

		Return nextBid
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
			Local font:TBitmapFont		= GetBitmapFont("Default", 12)
			Local titleFont:TBitmapFont	= GetBitmapFont("Default", 12, BOLDFONT)

			'set target for fonts
			TBitmapFont.setRenderTarget(_imageWithText)

			If bestBidder
				Local player:TPlayerBase = GetPlayerBase(bestBidder)
				titleFont.drawStyled(player.name, 31,33, player.color, 2, 1, 0.25)
			Else
				font.drawStyled(GetLocale("AUCTION_WITHOUT_BID"), 31,33, TColor.CreateGrey(150), 0, 1, 0.25)
			EndIf
			titleFont.drawBlock(licence.GetTitle(), 31,5, 215,30, Null, TColor.clBlack, 1, 1, 0.50)

			font.drawBlock(GetLocale("AUCTION_MAKE_BID")+": "+TFunctions.DottedValue(GetNextBid())+CURRENCYSIGN, 31,33, 212,20, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack, 1)

			'reset target for fonts
			TBitmapFont.setRenderTarget(Null)
	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(_imageWithText, area.GetX(), area.GetY())
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