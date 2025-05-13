SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "game.roomhandler.base.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.player.programmecollection.bmx"
Import "game.programme.programmelicence.gui.bmx"


'Movie agency
Type RoomHandler_MovieAgency Extends TRoomHandler
	Global AuctionToolTip:TTooltip

	Global VendorEntity:TSpriteEntity
	Global VendorArea:TGUISimpleRect	'allows registration of drop-event

	Global spriteShelfHighlight:TSprite
	Global AuctionEntity:TSpriteEntity

	Global hoveredGuiProgrammeLicence:TGUIProgrammeLicence = Null
	Global draggedGuiProgrammeLicence:TGUIProgrammeLicence = Null
	Global draggedGuiProgrammeLicenceTargetShelf:TGUIObject

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listMoviesGood:TProgrammeLicence[]
	Field listMoviesCheap:TProgrammeLicence[]
	Field listSeries:TProgrammeLicence[]

	Field filterMoviesGood:TProgrammeLicenceFilterGroup {nosave}
	Field filterMoviesCheap:TProgrammeLicenceFilterGroup {nosave}
	Field filterCrap:TProgrammeLicenceFilter {nosave}
	Field filterSeries:TProgrammeLicenceFilter {nosave}
	Field filterAuction:TProgrammeLicenceFilterGroup {nosave}

	'a list containing all licenses which _could_ be offered
	'(so no licences currently owned by someone)
	'- newly added licences are added "somewhere" at the end
	'- licences to get offered are choosen "somewhere" from the top
	Field offerPlanSingleLicences:TObjectList = New TObjectList
	Field offerPlanSeriesLicences:TObjectList = New TObjectList
	Field offerPlanCollectionLicences:TObjectList = New TObjectList

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:Int = True
	Global GuiListMoviesGood:TGUIProgrammeLicenceSlotList = Null
	Global GuiListMoviesCheap:TGUIProgrammeLicenceSlotList = Null
	Global GuiListSeries:TGUIProgrammeLicenceSlotList = Null
	Global GuiListSuitcase:TGUIProgrammeLicenceSlotList = Null

	'Field spriteSuitcaseGlow:TSprite {nosave}
	Global spriteAuctionPanel:TSprite {nosave}
	Global spriteAuctionPanelContent:TSprite {nosave}
	Global spriteSuitcase:TSprite {nosave}

	Global LS_movieagency:TLowerString = TLowerString.Create("movieagency")

	'configuration
	Global suitcasePos:SVec2I = New SVec2I(350,130)
	Global suitcaseGuiListDisplace:SVec2I = New SVec2I(14,25)
	Field programmesPerLine:Int	= 13

	Global _instance:RoomHandler_MovieAgency
	Global _eventListeners:TEventListenerBase[]


	Function GetInstance:RoomHandler_MovieAgency()
		If Not _instance Then _instance = New RoomHandler_MovieAgency
		Return _instance
	End Function


	Method New()
		InitializeFilters()
	End Method


	Function checkFilters:Int( triggerEvent:TEventBase )
		GetInstance().InitializeFilters()
	End Function


	Method InitializeFilters:Int()
		'determine thresholds
		Local movieGoodMoneyMinimum:Int = 170000
		Local movieGoodQualityMinimum:Float = 0.15
		Local movieCheapMoneyMaximum:Int = 145000
		Local movieCheapQualityMaximum:Float = 0.50
		Local relativeTopicalityMin:Float = 0.25
		Local crapFilterTopicality:Float = 0.05
		Local minCount:Int = 100

		For Local player:Int = 1 until 4
			Local collection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(player)
			If collection
				minCount = min(mincount, collection.GetSingleLicenceCount())
			Else
				minCount = 0
			EndIf
		Next
		If minCount > 20
			movieGoodMoneyMinimum:Int = 400000
			movieGoodQualityMinimum:Float = 0.25
			movieCheapMoneyMaximum:Int = 500000
			relativeTopicalityMin = 0.35
			crapFilterTopicality = 0.1
		EndIf

		If Not filterMoviesGood
			filterMoviesGood = New TProgrammeLicenceFilterGroup
			filterMoviesGood.AddFilter(New TProgrammeLicenceFilter)
			filterMoviesGood.AddFilter(New TProgrammeLicenceFilter)
		EndIf
		If Not filterMoviesCheap
			filterMoviesCheap = New TProgrammeLicenceFilterGroup
			filterMoviesCheap.AddFilter(New TProgrammeLicenceFilter)
			filterMoviesCheap.AddFilter(New TProgrammeLicenceFilter)
		EndIf
		If Not filterCrap Then filterCrap = New TProgrammeLicenceFilter

		If Not filterSeries Then filterSeries = New TProgrammeLicenceFilter

		'good movies must be more expensive than X _and_ of better
		'quality then Y
		Rem
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
		filterMoviesGood.filters[0].relativeTopicalityMin = relativeTopicalityMin
		filterMoviesGood.filters[0].relativeTopicalityMax = -1.0
		filterMoviesGood.filters[0].maxTopicalityMin = 0.35 'avoid older/broadcasted too often
		filterMoviesGood.filters[0].maxTopicalityMax = -1.0
		filterMoviesGood.filters[0].checkTradeability = True
		filterMoviesGood.filters[0].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]
		'filter 2 requires min-Quality
		filterMoviesGood.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterMoviesGood.filters[1].qualityMin = movieCheapQualityMaximum
		filterMoviesGood.filters[1].qualityMax = -1.0
		filterMoviesGood.filters[1].relativeTopicalityMin = relativeTopicalityMin
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
		filterMoviesCheap.filters[0].relativeTopicalityMin = relativeTopicalityMin
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
		filterMoviesCheap.filters[1].relativeTopicalityMin = relativeTopicalityMin
		filterMoviesCheap.filters[1].relativeTopicalityMax = -1.0
		filterMoviesCheap.filters[1].maxTopicalityMin = 0.20 'avoid older/broadcasted too often
		filterMoviesCheap.filters[1].maxTopicalityMax = -1.0
		filterMoviesCheap.filters[1].checkTradeability = True
		filterMoviesCheap.filters[1].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]

		'filter them by price too - eg. for auction ?
		filterSeries.licenceTypes = [TVTProgrammeLicenceType.SERIES]
		'filterSeries.filters[0].SetRequiredOwners([TOwnedGameObject.OWNER_NOBODY])
		'as long as there are not that much series, allow 15% instead of 25%
		filterSeries.relativeTopicalityMin = relativeTopicalityMin * 0.75
		filterSeries.relativeTopicalityMax = -1.0
		filterSeries.maxTopicalityMin = 0.25 'avoid older/broadcasted too often
		filterSeries.maxTopicalityMax = -1.0
		filterSeries.checkTradeability = True
		filterSeries.requiredOwners = [TOwnedGameObject.OWNER_NOBODY]


		'filter out no longer useful-to-broadcast stuff
		filterCrap.licenceTypes = [TVTProgrammeLicenceType.SERIES, TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION]
		filterCrap.maxTopicalityMin = 0.00
		filterCrap.maxTopicalityMax = crapFilterTopicality
		filterCrap.checkTradeability = True
'		filterCrap.requiredOwners = [TOwnedGameObject.OWNER_NOBODY]


		If Not filterAuction
			filterAuction = New TProgrammeLicenceFilterGroup
			filterAuction.AddFilter(New TProgrammeLicenceFilter)
			filterAuction.AddFilter(New TProgrammeLicenceFilter)

			'auction: either expensive - or - live programme
			filterAuction.filters[0].priceMin = 350000
			filterAuction.filters[0].priceMax = -1
			filterAuction.filters[0].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION, TVTProgrammeLicenceType.SERIES]
			'avoid "too used" licences
			filterAuction.filters[0].relativeTopicalityMin = 0.85
			filterAuction.filters[0].relativeTopicalityMax = -1.0
			filterAuction.filters[0].SetNotDataFlag(TVTProgrammeDataFlag.LIVEONTAPE)
			filterAuction.filters[0].maxTopicalityMin = 0.85
			filterAuction.filters[0].maxTopicalityMax = -1.0
			filterAuction.filters[0].checkTradeability = True
			filterAuction.filters[0].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]

			'maximum of 1 year since release
			filterAuction.filters[1].priceMin = 100000
			filterAuction.filters[1].priceMax = -1
			filterAuction.filters[1].licenceTypes = [TVTProgrammeLicenceType.SINGLE, TVTProgrammeLicenceType.COLLECTION, TVTProgrammeLicenceType.SERIES]
			filterAuction.filters[1].SetDataFlag(TVTProgrammeDataFlag.LIVE)
			filterAuction.filters[1].SetNotDataFlag(TVTProgrammeDataFlag.LIVEONTAPE)
			filterAuction.filters[1].checkTradeability = True
			filterAuction.filters[1].timeToReleaseMin = 5 * TWorldTime.DAYLENGTH
			filterAuction.filters[1].checkTimeToReleaseMin = True
			filterAuction.filters[1].checkTimeToReleaseMax = False
			filterAuction.filters[1].checkAgeMin = False
			filterAuction.filters[1].checkAgeMax = False
			filterAuction.filters[1].requiredOwners = [TOwnedGameObject.OWNER_NOBODY]
		EndIf

	End Method


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		listMoviesGood = New TProgrammeLicence[programmesPerLine]
		listMoviesCheap = New TProgrammeLicence[programmesPerLine]
		listSeries = New TProgrammeLicence[programmesPerLine]

'		InitializeOfferPlanLists()
		offerPlanSeriesLicences = New TObjectList
		offerPlanSingleLicences = New TObjectList
		offerPlanCollectionLicences = New TObjectList

		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		'=== create room elements
		spriteShelfHighlight = GetSpriteFromRegistry("gfx_movieagency_shelfhighlight")
		VendorEntity = GetSpriteEntityFromRegistry("entity_movieagency_vendor")
		AuctionEntity = GetSpriteEntityFromRegistry("entity_movieagency_auction")

		'=== create gui elements if not done yet
		If Not GuiListMoviesGood
			Local videoCase:TSprite = GetSpriteFromRegistry("gfx_movie_undefined")

			GuiListMoviesGood = New TGUIProgrammeLicenceSlotList.Create(New SVec2I(596,50), New SVec2I(200, Int(videoCase.area.h)), "movieagency")
			GuiListMoviesCheap = New TGUIProgrammeLicenceSlotList.Create(New SVec2I(596,148), New SVec2I(200, Int(videoCase.area.h)), "movieagency")
			GuiListSeries = New TGUIProgrammeLicenceSlotList.Create(New SVec2I(596,246), New SVec2I(200, Int(videoCase.area.h)), "movieagency")
			GuiListSuitcase = New TGUIProgrammeLicenceSlotList.Create(New SVec2I(suitcasePos.x + suitcaseGuiListDisplace.x, suitcasePos.y + suitcaseGuiListDisplace.y), New SVec2I(180, Int(videoCase.area.h)), "movieagency")

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

			GuiListMoviesGood.SetAutofillSlots(True)
			GuiListMoviesCheap.SetAutofillSlots(True)
			GuiListSeries.SetAutofillSlots(True)
			GuiListSuitcase.SetAutofillSlots(True)


			GuiListMoviesGood.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
			GuiListMoviesCheap.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
			GuiListSeries.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())
			GuiListSuitcase.SetSlotMinDimension(videoCase.area.GetW(), videoCase.area.GetH())

			GuiListMoviesGood.SetAcceptDrop("TGUIProgrammeLicence")
			GuiListMoviesCheap.SetAcceptDrop("TGUIProgrammeLicence")
			GuiListSeries.SetAcceptDrop("TGUIProgrammeLicence")
			GuiListSuitcase.SetAcceptDrop("TGUIProgrammeLicence")

			'default vendor position/dimension
			Local vendorAreaDimension:SVec2I = New SVec2I(200,200)
			Local vendorAreaPosition:SVec2I = New SVec2I(20,60)
			If VendorEntity Then vendorAreaDimension = New SVec2I(Int(VendorEntity.area.w), Int(VendorEntity.area.h) )
			If VendorEntity Then vendorAreaPosition = New SVec2I(Int(VendorEntity.area.x), Int(VendorEntity.area.y) )

			VendorArea = New TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "movieagency" )
			'vendor should accept drop - else no recognition
			VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, True)
		EndIf

		spriteAuctionPanel = GetSpriteFromRegistry("gfx_gui_panel")
		spriteAuctionPanelContent = GetSpriteFromRegistry("gfx_gui_panel.content")
		spriteSuitcase = GetSpriteFromRegistry("gfx_suitcase")


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		'drop ... so sell/buy the thing
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrop, onTryDropProgrammeLicence, "TGUIProgrammeLicence" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrop, onDropProgrammeLicence, "TGUIProgrammeLicence") ]
		'dropping a licence on another (in suitcase) can lead to a "replacement"
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUISlotList_OnReplaceSlotItem, onReplaceProgrammeLicence, "TGUIProgrammeLicenceSlotList" ) ]
		'is dragging even allowed? - eg. intercept if not enough money
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrag, onTryDragProgrammeLicence, "TGUIProgrammeLicence") ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverProgrammeLicence, "TGUIProgrammeLicence") ]
		'drop on vendor - sell things
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_onFinishDrop, onDropProgrammeLicenceOnVendor, "TGUIProgrammeLicence") ]
		'return to original position on right click
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickLicence, "TGUIProgrammeLicence") ]

		'reset auction block caches
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnSetActivePlayer, onResetAuctionBlockCache) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_OnSetActive, onResetAuctionBlockCache) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Station_OnSetInActive, onResetAuctionBlockCache) ]

		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, checkFilters) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnDay, checkFilters)]

		'fill/update offerPlan-lists
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeLicence_OnSetOwner, onSetProgrammeLicenceOwner) ]


		_eventListeners :+ _RegisterScreenHandler( onUpdateMovieAgency, onDrawMovieAgency, ScreenCollection.GetScreen("screen_movieagency"))
		_eventListeners :+ _RegisterScreenHandler( onUpdateMovieAuction, onDrawMovieAuction, ScreenCollection.GetScreen("screen_movieauction"))

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		If GuiListMoviesGood Then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:Int()
		If GetInstance() <> Self Then Self.CleanUp()
		GetRoomHandlerCollection().SetHandler("movieagency", GetInstance())
	End Method


	Method AbortScreenActions:Int()
		If draggedGuiProgrammeLicence
			'try to drop the licence back
			draggedGuiProgrammeLicence.dropBackToOrigin()
			draggedGuiProgrammeLicence = Null
			hoveredGuiProgrammeLicence = Null
			Return True
		EndIf
		Return False
	End Method


	Method onSaveGameBeginLoad:Int( triggerEvent:TEventBase )
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new programmes are not loaded yet

		GetInstance().RemoveAllGuiElements()
		haveToRefreshGuiElements = True
	End Method


	'fill offerPlan if the savegame is too old and did not contain one
	Method onSaveGameLoad:Int( triggerEvent:TEventBase )
		local added:int = 0
		If offerPlanSingleLicences.Count() = 0
			For local pl:TProgrammeLicence = EachIn GetProgrammeLicenceCollection().licences.Values()
				'only add un-owned
				if pl.owner <> TOwnedGameObject.OWNER_NOBODY then continue
				if OfferPlanLicenceAdd(pl)
					added :+ 1
				endif
			Next
		EndIf
		if added then print "MovieAgency: initialized OfferPlan with " + added + " unowned (parental) elements."
	End Method


	'clear the guilist for the suitcase if a player enters
	Method onEnterRoom:Int( triggerEvent:TEventBase )
		Local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		If Not figure Or Not figure.playerID Then Return False


		'=== FOR ALL PLAYERS ===
		'
		'fill all open slots in the agency
		GetInstance().ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		If IsObservedFigure(figure)
			'
		EndIf

		Return True
	End Method


	'override: figure leaves room - only without dragged blocks
	Method onTryLeaveRoom:Int( triggerEvent:TEventBase )
		'non players can always leave
		Local figure:TFigure = TFigure(triggerEvent.GetSender())
		If Not figure Or Not figure.playerID Then Return False


		'=== FOR ALL PLAYERS ===
		'


		'=== FOR WATCHED PLAYERS ===
		If IsObservedFigure(figure)
			'as only 1 player is allowed simultaneously, the limitation
			'to "observed" is not strictly needed - but does not harm

			'do not allow leaving as long as we have a dragged block
			If draggedGuiProgrammeLicence
				triggerEvent.setVeto()
				Return False
			EndIf
		EndIf

		Return True
	End Method


	'add back the programmes from the suitcase
	'also fill empty blocks, remove gui elements
	Method onLeaveRoom:Int( triggerEvent:TEventBase )
		'non players can always leave
		Local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		If Not figure Or Not figure.playerID Then Return False

		'=== FOR ALL PLAYERS ===
		'
		'print "player #" + figure.playerID +" leaves movieagency."

		'disabled auto-suitcase-readding
		'now we use
		'- readd when timer fires
		'- readd when going into another room than the movieagency
		'GetPlayerProgrammeCollection(figure.playerID).ReaddProgrammeLicencesFromSuitcase()

		Local player:TPlayerBase = GetPlayerBase(figure.playerID)
		'empty suitcase after 20 realtime seconds
		If player
			player.emptyProgrammeSuitcase = True
			player.emptyProgrammeSuitcaseFromRoom = "movieagency"
			player.emptyProgrammeSuitcaseTime = Time.GetTimeGone() + 20 * 1000
		EndIf


		'=== FOR WATCHED PLAYERS ===
		If IsObservedFigure(figure)
			'
		EndIf

		Return True
	End Method


	'called as soon as a players figure is forced to leave the room
	Method onForcefullyLeaveRoom:Int( triggerEvent:TEventBase )
		'only handle the player figures
		Local figure:TFigure = TFigure(triggerEvent.GetSender())
		If Not figure Or Not figure.playerID Then Return False

		'=== FOR ALL PLAYERS ===
		'


		'=== FOR WATCHED PLAYERS ===
		If IsObservedFigure(figure)
			AbortScreenActions()
		EndIf

		Return True
	End Method


	'called when the owner of a licence changes - so we could remove it
	'from lists or add it to one of them
	Function onSetProgrammeLicenceOwner:Int( triggerEvent:TEventBase )
		Local oldOwner:Int = triggerEvent.GetData().GetInt("oldOwner")
		Local newOwner:Int = triggerEvent.GetData().GetInt("newOwner")
		Local licence:TProgrammeLicence = TProgrammeLicence( triggerEvent.GetSender() )
		Local mA:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		If oldOwner = newOwner Then Return False

		'give back to pool -> add to list
		If newOwner = TOwnedGameObject.OWNER_NOBODY ' or newOwner = TOwnedGameObject.OWNER_VENDOR
			ma.OfferPlanLicenceAdd(licence)
		'players or vendor now owns it -> remove from list
		ElseIf oldOwner = TOwnedGameObject.OWNER_NOBODY
			ma.OfferPlanLicenceRemove(licence)
		EndIf
	End Function


	Method OfferPlanLicenceAdd:Int(licence:TProgrammeLicence)
		Local useList:TObjectList
		'ignore franchise-licences ?
		If licence.licenceType = TVTProgrammeLicenceType.FRANCHISE
			Return False
		'single / normal programme licences like movies / documentations /...
		ElseIf licence.isSingle()
			useList = offerPlanSingleLicences
		ElseIf licence.IsSeries()
			useList = offerPlanSeriesLicences
		ElseIf licence.IsCollection()
			useList = offerPlanCollectionLicences
		Else 'isEpisode() or isCollectionElement()
			Return False
		EndIf
		If useList.Contains(licence) Then Return False

		'add to somewhere "at the bottom"
		Local index:Int = BiasedRandRange(0, useList.Count(), 0.90)
		'TODO useList.Add(licence)
		If ObjectListAddAtIndex(licence, useList, index)
	'		Print "MovieAgency: offer plan - added " + licence.GetTitle() +"    index: " + index+" of 0-" + (useList.Count())
	'	Else
	'		Print "MovieAgency: offer plan - Failed to add licence " + licence.GetTitle()
		EndIf

		Return True
	End Method


	Method OfferPlanLicenceRemove:Int(licence:TProgrammeLicence)
		'ignore franchise-licences ?
		If licence.licenceType = TVTProgrammeLicenceType.FRANCHISE
			Return False
		'single / normal programme licences like movies / documentations /...
		ElseIf licence.isSingle()
			offerPlanSingleLicences.Remove(licence)
		ElseIf licence.IsSeries()
			offerPlanSeriesLicences.Remove(licence)
		ElseIf licence.IsCollection()
			offerPlanCollectionLicences.Remove(licence)
		Else 'isEpisode() or isCollectionElement()
			Return False
		EndIf

'		Print "MovieAgency: offer plan - removed " + licence.GetTitle()
	End Method
	
	
	Method OfferPlanShuffle()
		THelper.ShuffleObjectList(offerPlanSingleLicences)
		THelper.ShuffleObjectList(offerPlanSeriesLicences)
		THelper.ShuffleObjectList(offerPlanCollectionLicences)
	End Method


	Function ObjectListAddAtIndex:Int(o:Object, l:TObjectList, index:Int)
		l.Compact()

		l._ensureCapacity(l.size + 1)

		'Compact() refreshed "size" already, size = "index + 1"
		If index > l.size
			index = l.size
		Else
			'clamp index
			If index < 0 Then index = 0

			'move entries
			ArrayCopy(l.data, index, l.data, index + 1, l.size - index)
		EndIf

		l.data[index] = o
		l.size :+ 1
		l.version :+ 1
		Return True
	End Function


	Function ListAddAtIndex:Int(o:Object, l:TList, index:Int)
		Local link:TLink = GetListLink(o, l, index)
		If Not link
			l.AddLast(o)
		Else
			l.InsertBeforeLink(o, link)
		EndIf
		Return True
	End Function


	Function GetListLink:TLink(o:Object, l:TList, index:Int)
		Local link:TLink = l._head._succ
		While link <> l._head
			If Not index Then Return link
			link = link._succ
			index :- 1
		Wend
	End Function

	'===================================
	'Movie Agency: common TFunctions
	'===================================

	Method GetProgrammeLicencesInStock:Int()
		Local ret:Int = 0
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For Local j:Int = 0 To lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				If licence Then ret:+1
			Next
		Next
		Return ret
	End Method


	Method GetProgrammeLicences:TProgrammeLicence[]()
		Local ret:TProgrammeLicence[ GetProgrammeLicencesInStock() ]
		Local c:Int = 0
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For Local j:Int = 0 To lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				If licence Then ret[c] = licence
				c :+ 1
			Next
		Next
		Return ret
	End Method


	Method GetProgrammeLicenceByPosition:TProgrammeLicence(position:Int)
		If position > GetProgrammeLicencesInStock() Then Return Null
		Local currentPosition:Int = 0
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For Local j:Int = 0 To lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				If licence
					If currentPosition = position Then Return licence
					currentPosition:+1
				EndIf
			Next
		Next
		Return Null
	End Method


	Method HasProgrammeLicence:Int(licence:TProgrammeLicence)
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For Local j:Int = 0 To lists.length-1
			For Local listLicence:TProgrammeLicence = EachIn lists[j]
				If listLicence= licence Then Return True
			Next
		Next
		Return False
	End Method


	Method GetProgrammeLicenceByID:TProgrammeLicence(licenceID:Int)
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For Local j:Int = 0 To lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				If licence And licence.id = licenceID Then Return licence
			Next
		Next
		Return Null
	End Method


	Method SellProgrammeLicenceToPlayer:Int(licence:TProgrammeLicence, playerID:Int, skipOwnerCheck:Int=False)
		If licence.owner = playerID And Not skipOwnerCheck Then Return False

		If Not GetPlayerBaseCollection().IsPlayer(playerID) Then Return False

		'do not sell episodes/sub elements
		If licence.HasParentLicence() Then Return False

		'try to add to suitcase of player
		If Not GetPlayerProgrammeCollection(playerID).AddProgrammeLicenceToSuitcase(licence)
			Return False
		EndIf

		'remove from agency's lists
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		For Local j:Int = 0 To lists.length-1
			For Local i:Int = 0 To lists[j].length-1
				If lists[j][i] = licence Then lists[j][i] = Null
			Next
		Next

		Return True
	End Method


	Method BuyProgrammeLicenceFromPlayer:Int(licence:TProgrammeLicence)
		'do not buy episodes/sub elements
		If licence.HasParentLicence() Then Return False
		'do not buy if unowned
		If Not licence.isOwnedByPlayer() Then Return False
		'do not buy if not tradeable
		If Not licence.IsTradeable() Then Return False

		'remove from player (lists and suitcase) - and give him money
		If Not GetPlayerProgrammeCollection(licence.owner).RemoveProgrammeLicence(licence, True)
			Return False
		EndIf

		'add to agency's lists - if not existing yet
		If Not HasProgrammeLicence(licence) Then AddProgrammeLicence(licence)

		Return True
	End Method


	Method AddProgrammeLicence:Int(licence:TProgrammeLicence, tryOtherLists:Int = False)
		'do not add if still owned by a player or the vendor
		If licence.isOwned()
			TLogger.Log("MovieAgency", "AddProgrammeLicence() failed: cannot add licence owned by someone else. Owner="+licence.owner+"! Report to developers asap.", LOG_ERROR)
			Return False
		EndIf

		'try to fill the licence into the corresponding list
		'we use multiple lists - if the first is full, try second
		Local lists:TProgrammeLicence[][]

		'do not add episodes or collection elements
		If licence.isEpisode() Or licence.isCollectionElement()
			'licence.SetOwner(licence.OWNER_VENDOR)
			Return False
		EndIf


		If filterMoviesCheap.DoesFilter(licence)
			lists = [listMoviesCheap]
			If tryOtherLists Then lists :+ [listMoviesGood]
		ElseIf filterMoviesGood.DoesFilter(licence)
			lists = [listMoviesGood]
			If tryOtherLists Then lists :+ [listMoviesCheap]
		Else
			lists = [listSeries]
		EndIf

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		For Local j:Int = 0 To lists.length-1
			For Local i:Int = 0 To lists[j].length-1
				If lists[j][i] Then Continue
				licence.SetOwner(licence.OWNER_VENDOR)
				lists[j][i] = licence
				'print "added licence "+licence.title+" to list "+j+" at spot:"+i
				Return True
			Next
		Next


		Return False
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Method RemoveAllGuiElements:Int()
		GuiListMoviesGood.EmptyList()
		GuiListMoviesCheap.EmptyList()
		GuiListSeries.EmptyList()
		GuiListSuitcase.EmptyList()

		For Local guiLicence:TGUIProgrammeLicence = EachIn GuiManager.listDragged.Copy()
			guiLicence.remove()
			guiLicence = Null
		Next

		hoveredGuiProgrammeLicence = Null
		draggedGuiProgrammeLicence = Null
		draggedGuiProgrammeLicenceTargetShelf = Null

		'to recreate everything during next update...
		haveToRefreshGuiElements = True
	End Method


	Method RefreshGuiElements:Int()
		'===== REMOVE UNUSED =====
		'remove gui elements with movies the player does not have any
		'longer in the suitcase

		'suitcase
		For Local guiLicence:TGUIProgrammeLicence = EachIn GuiListSuitcase._slots
			'if the player has this licence in suitcase, skip deletion
			If GetPlayerProgrammeCollection(GetPlayerBaseCollection().playerID).HasProgrammeLicenceInSuitcase(guiLicence.licence) Then Continue

			'print "guiListSuitcase has obsolete licence: "+guiLicence.licence.getTitle()
			guiLicence.remove()
			guiLicence = Null
		Next
		'agency lists
		Local lists:TProgrammeLicence[][] = [ listMoviesGood,listMoviesCheap,listSeries ]
		Local guiLists:TGUIProgrammeLicenceSlotList[] = [ guiListMoviesGood, guiListMoviesCheap, guiListSeries ]
		For Local j:Int = 0 To guiLists.length-1
			For Local guiLicence:TGUIProgrammeLicence = EachIn guiLists[j]._slots
				If HasProgrammeLicence(guiLicence.licence) Then Continue

				'print "REM lists"+j+" has obsolete licence: "+guiLicence.licence.getTitle()
				guiLicence.remove()
				guiLicence = Null
			Next
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all programme-lists

		For Local j:Int = 0 To lists.length-1
			For Local licence:TProgrammeLicence = EachIn lists[j]
				If Not licence Then Continue
				If guiLists[j].ContainsLicence(licence) Then Continue


				Local lic:TGUIProgrammeLicence = New TGUIProgrammeLicence.CreateWithLicence(licence)
				'if adding to list was not possible, remove the licence again
				If Not guiLists[j].addItem(lic,"-1" )
					GUIManager.Remove(lic)
				EndIf

				'print "ADD lists"+j+" had missing licence: "+licence.getTitle()
			Next
		Next

		'create missing gui elements for the current suitcase
		For Local licence:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(GetPlayerBaseCollection().playerID).suitcaseProgrammeLicences
			If guiListSuitcase.ContainsLicence(licence) Then Continue
			guiListSuitcase.addItem(New TGUIProgrammeLicence.CreateWithLicence(licence),"-1" )
			'print "ADD suitcase had missing licence: "+licence.getTitle()
		Next

		haveToRefreshGuiElements = False
	End Method


	'refills slots in the movie agency
	'replaceOffer: remove (some) old programmes and place new there?
	Method RefillBlocks:Int(replaceOffer:Int=False, replaceChance:Float=1.0)
		Local lists:TProgrammeLicence[][] = [listMoviesGood,listMoviesCheap,listSeries]
		Local licence:TProgrammeLicence = Null

		haveToRefreshGuiElements = True
		'delete some random movies/series
		If replaceOffer
			For Local j:Int = 0 To lists.length-1
				For Local i:Int = 0 To lists[j].length-1
					If Not lists[j][i] Then Continue
					'delete an old movie by a chance of 50%
					If RandRange(0,100) < replaceChance*100
						'reset owner
						lists[j][i].SetOwner(TOwnedGameObject.OWNER_NOBODY)
						'unlink from this list
						lists[j][i] = Null
					EndIf
				Next
			Next
		EndIf


		'collect as many random licences per list as needed ("empty slots")
		Local licencesPerList:TProgrammeLicence[][]

		For Local listIndex:Int = 0 To lists.length-1
			Local cheapEroticCount:Int=0
			Local needed:Int = 0
			For Local entryIndex:Int = 0 To lists[listIndex].length-1
				If lists[listIndex][entryIndex]
					If Not lists[listIndex][entryIndex].IsAvailable()
						'remove entries not available anymore (as when replacing)
						lists[listIndex][entryIndex].SetOwner(TOwnedGameObject.OWNER_NOBODY)
						lists[listIndex][entryIndex] = Null
					Else
						'count exisiting cheap erotic entries
						If listIndex = 1 And lists[listIndex][entryIndex].GetGenre() = TVTProgrammeGenre.Erotic
							cheapEroticCount :+ 1
						EndIf
						Continue
					EndIf
				EndIf
				needed :+ 1
			Next

			If needed
				Local licences:TProgrammeLicence[]
				Select lists[listIndex]
					Case listMoviesGood
						licences = GetNextOffers([filterMoviesGood], Null, needed)
						'licences = GetProgrammeLicenceCollection().GetRandomsByFilter(filterMoviesGood, needed)
					Case listMoviesCheap
						'exclude the good movies
						licences = GetNextOffers(Null, [filterCrap, TProgrammeLicenceFilter(filterMoviesGood)], needed, Null, 2 - cheapEroticCount)
						'licences = GetProgrammeLicenceCollection().GetRandomsByFilter(filterMoviesCheap, needed)
					Case listSeries
						licences = GetNextOffers([filterSeries], [filterCrap], needed, offerPlanSeriesLicences)
						'licences = GetProgrammeLicenceCollection().GetRandomsByFilter(filterSeries, needed)
				End Select
				'fill to "needed" (with null values!)
				If Not licences
					licences = New TProgrammeLicence[needed]
				ElseIf licences.length < needed
'					print "not enough licences: needed=" + needed+"  got="+licences.length
					licences = licences[.. needed]
				EndIf

				licencesPerList :+ [licences] 'array of arrays
			Else
				'add empty, so that indices stay intact
				licencesPerList :+ [New TProgrammeLicence[0]]
			EndIf
		Next


		'fill empty slots
		For Local listIndex:Int = 0 To lists.length-1
			Local warnedOfMissingLicence:Int = False
			Local licenceIndex:Int = 0
			For Local entryIndex:Int = 0 Until lists[listIndex].length
				'if exists...skip it
				If lists[listIndex][entryIndex] Then Continue

				Local licence:TProgrammeLicence = licencesPerList[listIndex][licenceIndex]
				licenceIndex :+ 1

				'add new licence at slot
				If licence
					'set owner (and automatically remove from offerPlan-lists)
					licence.SetOwner(licence.OWNER_VENDOR)
					lists[listIndex][entryIndex] = licence
					'once a custom production is sold, the player difficulty should be considered
					If licence.IsAPlayersCustomProduction() Then licence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, False)
				Else
					If Not warnedOfMissingLicence
						TLogger.Log("MovieAgency.RefillBlocks()", "Not enough licences to refill slot["+entryIndex+"+] in list["+listIndex+"]", LOG_WARNING | LOG_DEBUG)
						warnedOfMissingLicence = True
					EndIf
				EndIf
			Next
		Next
	End Method


	Method GetNextOffers:TProgrammeLicence[](includeFilters:TProgrammeLicenceFilter[], excludeFilters:TProgrammeLicenceFilter[], amount:Int=1, list:TObjectList=Null, maxEroticCount:Int=100)
		If Not list Then list = offerPlanSingleLicences

		Local result:TProgrammeLicence[] = New TProgrammeLicence[amount]
		Local added:Int = 0
		Local allowedErotic:Int = maxEroticCount
		For Local p:TProgrammeLicence = EachIn list
			'IsAvailable() includes more than those flags and is potentially suppressed in filter
			If p.HasBroadCastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)
				Continue
			ElseIf p.data.HasBroadCastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)
				Continue
			ElseIf Not includeFilters
				If Not p.IsTradeable() Then Continue
				If Not p.IsReleased() Then Continue
			Else
				Local unfiltered:int = False
				For Local includeFilter:TProgrammeLicenceFilter = EachIn includeFilters
					If not includeFilter.DoesFilter(p)
						unfiltered = True
						Continue
					EndIf
				Next
				If unfiltered Then Continue
			EndIf

			If excludeFilters
				Local filtered:Int = False
				For Local excludeFilter:TProgrammeLicenceFilter = EachIn excludeFilters
					If excludeFilter.DoesFilter(p)
						filtered = True
						Continue
					EndIf
				Next
				If filtered Then Continue
			EndIf

			If p.GetGenre() = TVTProgrammeGenre.Erotic
				If allowedErotic > 0
					allowedErotic :- 1
				Else
					Continue
				EndIf
			EndIf

			result[added] = p
			added :+ 1

			'found enough
			If added >= amount Then Exit
		Next

		If result.length <> added Then result = result[.. added]
		Return result
	End Method


	'===================================
	'Movie Agency: All screens
	'===================================

	'can be done for all, as the order of handling that event
	'does not care ... just update animations is important
	Method onUpdateRoom:Int( triggerEvent:TEventBase )
		Super.onUpdateRoom(triggerEvent)
Rem
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

		If AuctionEntity Then AuctionEntity.Update()
		If VendorEntity Then VendorEntity.Update()
	End Method


	'===================================
	'Movie Agency: Room screen
	'===================================


	Function onMouseOverProgrammeLicence:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("movieagency") Then Return False

		Local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		If item = Null Then Return False

		hoveredGuiProgrammeLicence = item

		'only handle dragged for the real player
		If CheckPlayerObservedAndInRoom("movieagency")
			If item.isDragged() Then draggedGuiProgrammeLicence = item
		EndIf

		Return True
	End Function


	'check if we are allowed to drag that licence
	Function onTryDragProgrammeLicence:Int( triggerEvent:TEventBase )
		If Not CheckPlayerObservedAndInRoom("movieagency") Then Return False

		Local item:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetSender())
		If item = Null Then Return False

		Local owner:Int = item.licence.owner

		'do not allow dragging items from other players
		If owner > 0 And owner <> GetPlayerBaseCollection().playerID
			triggerEvent.setVeto()
			Return False
		EndIf

		'check whether a player could afford the licence
		'if not - just veto the event so it does not get dragged
		If owner <= 0
			If Not GetPlayerBase().getFinance().canAfford(item.licence.getPriceForPlayer( GetObservedPlayerID() ))
				triggerEvent.setVeto()
				Return False
			EndIf
		EndIf

		'check whether a player could sell the licence
		'if not - just veto the event so it does not get dragged
		If owner = GetPlayerBaseCollection().playerID
			If Not item.licence.IsTradeable()
				triggerEvent.setVeto()
				Return False
			EndIf
		EndIf

		Return True
	End Function


	'- check if dropping on suitcase and affordable
	'- check if dropping own licence on the shelf (not possible for now)
	'(OLD: - check if dropping on an item which is not affordable)
	Function onTryDropProgrammeLicence:Int( triggerEvent:TEventBase )
		If Not CheckPlayerObservedAndInRoom("movieagency") Then Return False

		Local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		Local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		If Not guiLicence Or Not receiverList Then Return False

		Local owner:Int = guiLicence.licence.owner

		Select receiverList
			Case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'check if something is underlaying and whether the licence
				'differs to the dropped one
				Local underlayingItem:TGUIProgrammeLicence = Null
				Local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", New TVec2D(-1,-1)))
				If coord Then underlayingItem = TGUIProgrammeLicence(receiverList.GetItemByCoord(coord))

				'allow drop on own place
				If underlayingItem = guiLicence Then Return True

				'prevent dropping licence to incompatible shelf
				Local filter:TProgrammeLicenceFilter = TProgrammeLicenceFilter(GetInstance().filterMoviesGood)
				If receiverList = GuiListMoviesCheap Then filter = TProgrammeLicenceFilter(GetInstance().filterMoviesCheap)
				If receiverList = GuiListSeries Then filter = GetInstance().filterSeries

				Local isFiltered:Int = filter.DoesFilter(guiLicence.licence, True)

				If underlayingItem Or Not isFiltered
					triggerEvent.SetVeto()
					Return False
				EndIf
			Case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				If guiLicence.licence.owner = GetPlayerBaseCollection().playerID Then Return True

				If Not GetPlayerBase().getFinance().canAfford(guiLicence.licence.getPriceForPlayer( GetObservedPlayerID() ))
					triggerEvent.setVeto()
				EndIf
		End Select

		Return True
	End Function


	Function onResetAuctionBlockCache:Int( triggerEvent:TEventBase )
		TAuctionProgrammeBlocks.ClearCaches()
	End Function


	Function onReplaceProgrammeLicence:int( triggerEvent:TEventBase )
		'as soon as dropping a licence on a "full" suitcase, we remove 
		'the "dragged" from the player's suitcase
		'- licences exceeding the suitcase limit must come from the shelf
		'- so for any "in addition" dragged licence there must be a free
		'  slot in the shelf

		If Not CheckObservedFigureInRoom("movieagency") Then Return False
		Local senderList:TGUIProgrammeLicenceSlotList = TGUIProgrammeLicenceSlotList(triggerEvent._sender)
		If Not senderList Then Return False

		Local droppedGUIProgrammeLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetData().Get("source"))
		Local draggedGUIProgrammeLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent.GetData().Get("target"))
		
		'dropping a licence from the vendor to the suitcase 
		'(on an already occupied slot)
		If senderlist = GuiListSuitcase and droppedGUIProgrammeLicence.licence.IsOwnedByVendor()
			'buy replaced (now dragged) from player
			GetInstance().BuyProgrammeLicenceFromPlayer(draggedGuiProgrammeLicence.licence)
			'sell replacement (now dropped) to player
			GetInstance().SellProgrammeLicenceToPlayer(droppedGUIProgrammeLicence.licence, GetObservedPlayerID())
		'ElseIf (senderlist = GuiListMoviesCheap or senderList = GuiListMoviesGood or senderlist = GuiListSeries) and droppedGUIProgrammeLicence.licence.owner > 0
			'replacement on vendor lists does not need special handling as
			'we do not want to automatically place the "replacement" in the
			'player's suitcase
		EndIf
	End Function


	'dropping takes place - sell/buy licences or veto if not possible
	Function onDropProgrammeLicence:Int( triggerEvent:TEventBase )
		If Not CheckPlayerObservedAndInRoom("movieagency") Then Return False

		Local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		Local receiverList:TGUIListBase = TGUIListBase(triggerEvent._receiver)
		If Not guiLicence Or Not receiverList Then Return False

		draggedGuiProgrammeLicenceTargetShelf = Null

		Local owner:Int = guiLicence.licence.owner

		Select receiverList
			Case GuiListMoviesGood, GuiListMoviesCheap, GuiListSeries
				'when dropping vendor licence on vendor shelf .. no prob
				If guiLicence.licence.owner <= 0 Then Return True

				If Not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
					triggerEvent.setVeto()
					Return False
				EndIf
			Case GuiListSuitcase
				'no problem when dropping own programme to suitcase..
				If guiLicence.licence.owner = GetPlayerBaseCollection().playerID Then Return True

				If Not GetInstance().SellProgrammeLicenceToPlayer(guiLicence.licence, GetPlayerBaseCollection().playerID)
					triggerEvent.setVeto()
					Return False
				EndIf
		End Select

		Return True
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropProgrammeLicenceOnVendor:Int(triggerEvent:TEventBase)
		If Not CheckPlayerObservedAndInRoom("movieagency") Then Return False

		Local guiLicence:TGUIProgrammeLicence = TGUIProgrammeLicence(triggerEvent._sender)
		Local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		If Not guiLicence Or Not receiver Then Return False
		If receiver <> VendorArea Then Return False

		'do not accept blocks from the vendor itself
		If Not guiLicence.licence.isOwnedByPlayer()
			triggerEvent.setVeto()
			Return False
		EndIf

		'buy licence back and place it somewhere in the right board shelf
		If Not GetInstance().BuyProgrammeLicenceFromPlayer(guiLicence.licence)
			triggerEvent.setVeto()
			Return False
		Else
			'successful - delete that gui block
			guiLicence.remove()
			'remove the whole block too
			guiLicence = Null
			
			draggedGuiProgrammeLicenceTargetShelf = Null
'RONNY
			haveToRefreshGuiElements = True
		EndIf

		Return True
	End Function

	'in case of right mouse button click a dragged licence is
	'placed at its original spot again
	Function onClickLicence:Int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		If triggerEvent.GetData().getInt("button",0) <> 2 Then Return True

		Local guiLicence:TGUIProgrammeLicence= TGUIProgrammeLicence(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		If Not guiLicence Or Not guiLicence.isDragged() Then Return False

		'remove gui object
		guiLicence.remove()
		guiLicence = Null

		'rebuild at correct spot
		haveToRefreshGuiElements = True

		'avoid clicks
		'remove right click - to avoid leaving the room
		MouseManager.SetClickHandled(2)
	End Function


	Function onDrawMovieAgency:Int( triggerEvent:TEventBase )
		If AuctionEntity Then AuctionEntity.Render()
		If VendorEntity Then VendorEntity.Render()

		If spriteSuitcase Then spriteSuitcase.Draw(suitcasePos.x, suitcasePos.y)

		'make auction/suitcase/vendor highlighted if needed
		Local highlightSuitcase:Int = False
		Local highlightVendor:Int = False
		Local highlightAuction:Int = False
		Local highlightShelf:Int
	
		'sometimes a draggedGuiProgrammeLicence is defined in an update
		'but isnt dragged anymore (will get removed in the next tick)
		'the dragged check avoids that the vendor is highlighted for
		'1-2 render frames
		If draggedGuiProgrammeLicence And draggedGuiProgrammeLicence.isDragged()
			If draggedGuiProgrammeLicence.licence.owner <= 0
				highlightSuitcase = True
			EndIf
			'Else
				highlightVendor = True

				'also allow dropping on a specific shelf?
				If not draggedGuiProgrammeLicenceTargetShelf
					Local shelfGuiList:TGUIProgrammeLicenceSlotList
					
					'prevent dropping licence to incompatible shelf
					If GetInstance().filterSeries.DoesFilter(draggedGuiProgrammeLicence.licence, True)
						shelfGuiList = GuiListSeries
					Elseif GetInstance().filterMoviesGood.DoesFilter(draggedGuiProgrammeLicence.licence, True)
						shelfGuiList = GuiListMoviesGood
					ElseIf GetInstance().filterMoviesCheap.DoesFilter(draggedGuiProgrammeLicence.licence, True)
						shelfGuiList = GuiListMoviesCheap
					EndIf

					'skip highlighting if the selected list is not empty
					If shelfGuiList and Not shelfGuiList.HasItem(draggedGuiProgrammeLicence) And shelfGuiList.GetUnusedSlotAmount() <= 0
						shelfGuiList = Null
					EndIf

					If Not shelfGuiList
						'set some "non null" so it is only calculated once
						draggedGuiProgrammeLicenceTargetShelf = VendorArea
					Else
						draggedGuiProgrammeLicenceTargetShelf = shelfGuiList
					EndIf
				EndIf

				If TGUIProgrammeLicenceSlotList(draggedGuiProgrammeLicenceTargetShelf)
					highlightShelf = True
				EndIf
			'EndIf
		Else
			If AuctionEntity And AuctionEntity.GetScreenArea().ContainsXY(MouseManager.x, MouseManager.y)
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
				highlightAuction = True
			EndIf
		EndIf

		If highlightAuction Or highlightVendor Or highlightSuitcase or highlightShelf
			Local oldColA:Float = GetAlpha()
			SetBlend LightBlend
			SetAlpha oldColA * Float(0.4 + 0.2 * Sin(Time.GetAppTimeGone() / 5))

			If AuctionEntity And highlightAuction Then AuctionEntity.Render()
			If VendorEntity And highlightVendor Then VendorEntity.Render()
			If highlightSuitcase And spriteSuitcase Then spriteSuitcase.Draw(suitcasePos.x, suitcasePos.y)
			
			If highlightShelf and TGUIListBase(draggedGuiProgrammeLicenceTargetShelf)
				spriteShelfHighlight.Draw(draggedGuiProgrammeLicenceTargetShelf.GetScreenRect().x, draggedGuiProgrammeLicenceTargetShelf.GetScreenRect().y)
			EndIf

			SetAlpha(oldColA)
			SetBlend AlphaBlend
		EndIf


		Local fontColor:SColor8 = new SColor8(50, 50, 50, 125)
		Local font:TBitmapFont = GetBitmapFont("Default",12, BOLDFONT)
		font.DrawBox(GetLocale("MOVIES"),      642,  27+1, 108,20, sALIGN_CENTER_TOP, fontColor)
		font.DrawBox(GetLocale("SPECIAL_BIN"), 642, 125+1, 108,20, sALIGN_CENTER_TOP, fontColor)
		font.DrawBox(GetLocale("SERIES"),      642, 223+1, 108,20, sALIGN_CENTER_TOP, fontColor)

		GUIManager.Draw( LS_movieagency )

		If hoveredGuiProgrammeLicence
			if hoveredGuiProgrammeLicence.IsDragged()
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
			elseif not hoveredGuiProgrammeLicence.licence.IsTradeable()
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL, TGameBase.CURSOR_EXTRA_FORBIDDEN)
			elseif hoveredGuiProgrammeLicence.licence.owner = GetPlayerBase().playerID or GetPlayerBase().getFinance().canAfford(hoveredGuiProgrammeLicence.licence.getPriceForPlayer( GetPlayerBase().playerID ))
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL)
			else
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL, TGameBase.CURSOR_EXTRA_FORBIDDEN)
			endif

			'draw the current sheet
			If MouseManager.x < GetGraphicsManager().GetWidth()/2
				hoveredGuiProgrammeLicence.DrawSheet(GetGraphicsManager().GetWidth() - 30, 20, 1)
			Else
				hoveredGuiProgrammeLicence.DrawSheet(30, 20, 0)
			EndIf
		EndIf


		If draggedGuiProgrammeLicence And draggedGuiProgrammeLicence.isDragged()
			GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
			'add "forbidden" icon if hovering your dragged licence over the
			'wrong lists
			'also forbid if target list is "full" and won't accept it
			'and the dragged licence comes from another source
			If TGUIListBase(draggedGuiProgrammeLicenceTargetShelf)
				For local guiList:TGUIProgrammeLicenceSlotList = EachIn [GuiListSeries, GuiListMoviesCheap, GuiListMoviesGood]
					Local scrRect:TRectangle = guiList.GetScreenRect()
					If THelper.MouseIn(Int(scrRect.x), Int(scrRect.y - 25), Int(scrRect.w), Int(scrRect.h + 25))
						If draggedGuiProgrammeLicenceTargetShelf <> guiList or not highlightShelf
							GetGameBase().SetCursorExtra(TGameBase.CURSOR_EXTRA_FORBIDDEN)
						EndIf
					EndIf
				Next
			EndIf
		EndIf


		If AuctionToolTip Then AuctionToolTip.Render()
	End Function


	Function onUpdateMovieAgency:Int( triggerEvent:TEventBase )
		Local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		If Not room Then Return 0

		If CheckObservedFigureInRoom("movieagency")
			'show a auction-tooltip (but not if we dragged a block)
			If Not hoveredGuiProgrammeLicence
				If THelper.MouseIn(210,220,140,60)
					If Not AuctionToolTip Then AuctionToolTip = TTooltip.Create(GetLocale("AUCTION"), GetLocale("MOVIES_AND_SERIES_AUCTION"), 200, 180, 0, 0)
					AuctionToolTip.enabled = 1
					AuctionToolTip.Hover()

					If MouseManager.IsClicked(1)
						'handled left click
						MouseManager.SetClickHandled(1)

						ScreenCollection.GoToSubScreen("screen_movieauction")
					EndIf
				EndIf
			EndIf

			'delete unused and create new gui elements
			If haveToRefreshGuiElements Then GetInstance().RefreshGUIElements()

			'reset hovered block - will get set automatically on gui-update
			hoveredGuiProgrammeLicence = Null
			'reset dragged block too
			draggedGuiProgrammeLicence = Null

			GUIManager.Update( LS_movieagency )

			If AuctionToolTip Then AuctionToolTip.Update()
		EndIf
	End Function



	'===================================
	'Movie Agency: Room screen
	'===================================

	Function onDrawMovieAuction:Int( triggerEvent:TEventBase )
		If AuctionEntity Then AuctionEntity.Render()
		If VendorEntity Then VendorEntity.Render()
		If spriteSuitcase Then spriteSuitcase.Draw(suitcasePos.x, suitcasePos.y)

		Local fontColor:SColor8 = new SColor8(50, 50, 50, 125)
		Local font:TBitmapFont = GetBitmapFont("Default",12, BOLDFONT)
		font.DrawBox(GetLocale("MOVIES"),      642,  27+3, 108,20, sALIGN_CENTER_TOP, fontColor)
		font.DrawBox(GetLocale("SPECIAL_BIN"), 642, 125+3, 108,20, sALIGN_CENTER_TOP, fontColor)
		font.DrawBox(GetLocale("SERIES"),      642, 223+3, 108,20, sALIGN_CENTER_TOP, fontColor)

		GUIManager.Draw( LS_movieagency )
		SetAlpha 0.2;SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetAlpha 1.0;SetColor 255,255,255

		If spriteAuctionPanel Then spriteAuctionPanel.DrawArea(120-15,60-15,555+30,290+30)
		If spriteAuctionPanelContent Then spriteAuctionPanelContent.DrawArea(120,60,555,290)

		SetAlpha 0.6 + Float(Min(0.15, Max(-0.20, Sin(MilliSecs() / 6) * 0.20)))
		'SetAlpha 0.6 + Float( 0.1 * Sin(Time.GetAppTimeGone() / 5))
		font.DrawBox(GetLocale("CLICK_ON_MOVIE_OR_SERIES_TO_PLACE_BID"), 140,320, 535,30, sALIGN_CENTER_TOP, new SColor8(50,50,50), EDrawTextEffect.Shadow, 0.25)
		SetAlpha 1.0

		TAuctionProgrammeBlocks.DrawAll()
	End Function


	Function onUpdateMovieAuction:Int( triggerEvent:TEventBase )
		If CheckPlayerObservedAndInRoom("movieagency")
			TAuctionProgrammeBlocks.UpdateAll()
		EndIf

		'remove old tooltips from previous screens
		If AuctionToolTip Then AuctionToolTip = Null
	End Function
End Type




'Programmeblocks used in Auction-Screen
'they do not need to have gui/non-gui objects as no special
'handling is done (just clicking)
Type TAuctionProgrammeBlocks Extends TGameObject {_exposeToLua="selected"}
	Field area:TRectangle {nosave}
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
	Global spriteAuctionMovie:TSprite {nosave}
	Global textBlockDrawSettings:TDrawTextSettings = new TDrawTextSettings

	'todo/idea: we could add a "started" and a "endTime"-field so
	'           auctions do not end at midnight but individually

	Method GenerateGUID:String()
		Return "auctionprogrammeblocks-"+id
	End Method


	Method Create:TAuctionProgrammeBlocks(slot:Int=0, licence:TProgrammeLicence)
		Self.slot = slot
		Self.Refill(licence)
		List.AddLast(Self)

		'sort so that slot1 comes before slot2 without having to matter about creation order
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
			
		Return Self
	End Method


	Function ClearCaches:Int()
		For Local block:TAuctionProgrammeBlocks = EachIn List
			block._imageWithText = Null
		Next
	End Function


	Function Initialize:Int()
		list.Clear()
	End Function


	Function GetByIndex:TAuctionProgrammeBlocks(index:Int)
		If index < 0 Then index = 0
		If index >= list.Count() Then Return Null

		Return TAuctionProgrammeBlocks( list.ValueAtIndex(index) )
	End Function


	Function GetByLicence:TAuctionProgrammeBlocks(licence:TProgrammeLicence, licenceGUID:String="")
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If licence And obj.licence = licence Then Return obj
			If obj.licence And obj.licence.GetGUID() = licenceGUID Then Return obj
		Next
		Return Null
	End Function


	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o1)
		Local s2:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o2)
		If Not s1 Then Return -1
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function


	'give all won auctions to the winners
	Function EndAllAuctions()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			obj.EndAuction()
		Next
	End Function


	Function GetCurrentLiveOffers:Int()
		Local res:Int = 0
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If obj.licence And obj.licence.IsLive() Then res :+1
		Next
		Return res
	End Function


	'refill all auctions without bids
	Function RefillAuctionsWithoutBid()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If Not obj.bestBidder
				obj.Refill()
				If Not obj.licence Then Print "RefillAuctionsWithoutBid: no licence available"
			EndIf
		Next
	End Function


	Function GetAuctionMovieSprite:TSprite()
		If Not spriteAuctionMovie Then spriteAuctionMovie = GetSpriteFromRegistry("gfx_auctionmovie")
		Return spriteAuctionMovie
	End Function


	Method GetBidSavingsMaximum:Float()
		If _bidSavingsMaximum = -1.0
			_bidSavingsMaximum = RandRange(80,90) / 100.0 '0.8 - 0.9
		EndIf
		Return _bidSavingsMaximum
	End Method


	Method GetBidSavingsMinimum:Float()
		If _bidSavingsMinimum = -1.0
			'0.55 - (Max-0.05)
			_bidSavingsMinimum = RandRange(55, Int(100*(GetBidSavingsMaximum()-0.05))) / 100.0
		EndIf
		Return _bidSavingsMinimum
	End Method


	Method GetBidSavingsDecreaseBy:Float()
		If _bidSavingsDecreaseBy = -1.0
			'0.05 - 0.10
			_bidSavingsDecreaseBy = RandRange(5, 10) / 100.0
		EndIf
		Return _bidSavingsDecreaseBy
	End Method


	Method GetMaxAuctionTime:Long(useLicence:TProgrammeLicence = Null)
		If Not useLicence Then useLicence = licence

		'limit live programme by their airTime - 1 day
		'TODO alwaysLiveCheck may be problematic for episodes... (true if any child is live)
		'becomes relevant only if there are live series in auctions
		If useLicence And useLicence.IsLive() And Not useLicence.isAlwaysLive()
			Return useLicence.data.GetReleaseTime() - 1 * TWorldTime.DAYLENGTH
		EndIf

		Return maxAuctionTime
	End Method


	'sets another licence into the slot
	Method Refill:Int(programmeLicence:TProgrammeLicence=Null)
		'if licence
		'	print "Refill: " + licence.GetTitle()
		'else
		'	print "Refill: Initial call"
		'endif
		'turn back licence if nobody bought the old one
		If licence And licence.owner = TOwnedGameObject.OWNER_VENDOR
			licence.SetOwner( TOwnedGameObject.OWNER_NOBODY )
			'no longer ignore player difficulty
			licence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, False)
			'print "   gave back licence"
		EndIf

		'backup old licence if a new is to find - but eg. fails (no live)
		Local oldLicence:TProgrammeLicence
		If Not programmeLicence Then oldLicence = licence
		licence = programmeLicence

		'try to find a "live" programme first
		If GetCurrentLiveOffers() < 3
			'print "   try to find live one"
			Local keepOld:Int = False
			'keep an old live programme if it airs _after_ the next day
			If Not bestBidder And GetMaxAuctionTime() > GetWorldTime().GetTimeGone()
				'print "   keep as still in the future"
				keepOld = True
				licence = oldLicence
			EndIf

			If Not keepOld
				'print "   find new live one"
				'Searching can be a bit "slow" on huge databases, so we
				'try to avoid to iterate over all licences each time
				'-> start with a "loose" filter to limit candidate list
				Local filterLiveNum:Int = 1 '0 = normal programme, 1 = live
				Local filter:TProgrammeLicenceFilter = RoomHandler_MovieAgency.GetInstance().filterAuction.filters[filterLiveNum].Copy()
				Local oldPriceMin:Int = filter.priceMin
				'only take live-programme starting not earlier than 3 days
				'from now. This is needed to avoid a "live"-programme
				'being no longer live
				filter.timeToReleaseMin = 2 * TWorldTime.DAYLENGTH
				'do not limit too much
				filter.priceMin = 0

				'fetch candidates
				Local candidates:TProgrammeLicence[] = GetProgrammeLicenceCollection().GetByFilter(filter)
				If candidates.length > 0
					filter.priceMin = oldPriceMin
					While Not licence And filter.priceMin >= 0
						licence = GetProgrammeLicenceCollection().GetRandomByFilter(filter, candidates)
						'lower the requirements
						If Not licence Then filter.priceMin :- 25000
					End While
				EndIf
			EndIf
		EndIf


		'find a normal licence
		If Not licence
			'print "   find new one"
			Local filterGroup:TProgrammeLicenceFilterGroup = TProgrammeLicenceFilterGroup(RoomHandler_MovieAgency.GetInstance().filterAuction.Copy())
			While Not licence And filterGroup.filters[0].priceMin >= 0
				licence = GetProgrammeLicenceCollection().GetRandomByFilter(filterGroup)
				'lower the requirements
				If Not licence
					filterGroup.filters[0].priceMin :- 5000
					filterGroup.filters[0].ageMax :+ TWorldTime.DAYLENGTH

					filterGroup.filters[1].priceMin = Max(0, filterGroup.filters[1].priceMin - 5000)
				EndIf
			Wend
		EndIf
		If Not licence
			TLogger.Log("AuctionProgrammeBlocks.Refill()", "No licences for new auction found. Database needs more entries!", LOG_ERROR)
			'If Not licence Then Throw "[ERROR] TAuctionProgrammeBlocks.Refill - no licence"
		EndIf

		If licence
			'print "   found " + licence.GetTitle()
			'set licence owner to "-1" so it gets not returned again from Random-Getter
			licence.SetOwner( TOwnedGameObject.OWNER_VENDOR )

			'reset auctionPrice-Mod
			'ATTENTION: during "filtering" the price might have been
			'           modified by this modifier - for now we ignore
			'           the fact it could not have passed the filter...
			licence.SetModifier(TProgrammeLicence.modKeyAuctionPriceLS, 1.0)
			licence.SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.IGNORE_PLAYERDIFFICULTY, True)
		EndIf

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
		TriggerBaseEvent(GameEventKeys.ProgrammeLicenceAuction_Refill, New TData.Add("licence", licence).AddNumber("slot", slot), Self)
	End Method


	Method EndAuction:Int()
		'if there was no licence stored, try again to refill the block
		If Not licence
			Refill()
			Return False
		EndIf


		If bestBidder And GetPlayerBaseCollection().IsPlayer(bestBidder)
			'modify licences new price until a new auction of this licence
			'might reset it
			licence.SetModifier("auctionPrice", Float(bestBid) / licence.GetPriceForPlayer(bestBidder, bestBidderLevel))
			licence.SetLicencedAudienceReachLevel(bestBidderLevel)

			?debug
			Print "modifier auctionPrice=" + Float(bestBid) / licence.GetPriceForPlayer(bestBidder, bestBidderLevel)
			Print "endAuction: price for p0="+licence.GetPriceForPlayer(0)
			For Local i:Int = 1 To 4
				Print "endAuction: price for p"+i+"="+licence.GetPriceForPlayer(i, GetPlayerBase(i).GetChannelReachLevel()) + " audienceLevel="+GetPlayerBase(i).GetChannelReachLevel()
			Next
			?

			Local player:TPlayerBase = GetPlayerBase(bestBidder)
			GetPlayerProgrammeCollection(player.playerID).AddProgrammeLicence(licence)
			If Not GetPlayerProgrammeCollection(player.playerID).HasProgrammeLicence(licence)
				TLogger.Log("EndAuction", "Not able to add won auction to programmeCollection: ~q"+ licence.GetGUID()+"~q.", LOG_ERROR)
			Else

				If player.isLocalAI()
					'player.PlayerAI.CallOnProgrammeLicenceAuctionWin(licence, bestBid)
					player.PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnProgrammeLicenceAuctionWin).Add(licence).AddInt(bestBid))
				EndIf

				'emit event so eg. toastmessages could attach
				Local evData:TData = New TData
				evData.Add("licence", licence)
				evData.AddNumber("bestBidder", player.playerID)
				evData.AddNumber("bestBidderLevel", bestBidderLevel)
				evData.AddNumber("bestBidRaw", bestBidRaw)
				evData.AddNumber("bestBid", bestBid)
				TriggerBaseEvent(GameEventKeys.ProgrammeLicenceAuction_OnWin, evData, Self)
			EndIf
		End If


		'found nobody to buy this licence
		'so we decrease price a bit
		If Not bestBidder
			Self.bidSavings :- Self.GetBidSavingsDecreaseBy()
		EndIf


		'actually need to end the auction instead of just decreasing
		'minimum bid?
		Local auctionEnds:Int = False

		'if we had a bidder or found nobody with the allowed price minimum
		'we add another licence to this block and reset everything
		If bestBidder Or Self.bidSavings < Self.GetBidSavingsMinimum()
			auctionEnds = True
		'is time for this auction gone (eg. live-programme has limits)?
		Else
			Local maxTime:Long = GetMaxAuctionTime(licence)
			If maxTime <> -1 And maxTime < GetWorldTime().GetTimeGone()
				auctionEnds = True
				'print "maxAuctionTime reached: " + licence.GetTitle()
			EndIf
		EndIf

		If auctionEnds
			'emit event
			Local evData:TData = New TData
			evData.Add("licence", licence)
			evData.AddNumber("bestBidder", bestBidder)
			evData.AddNumber("bestBidderLevel", bestBidderLevel)
			evData.AddNumber("bestBidRaw", bestBidRaw)
			evData.AddNumber("bestBid", bestBid)
			evData.AddNumber("bidSavings", bidSavings)
			TriggerBaseEvent(GameEventKeys.ProgrammeLicenceAuction_OnEndAuction, evData, Self)

			Refill()
			Return True
		EndIf


		'reset cache
		_imageWithText = Null

		Return False
	End Method


	Method GetArea:TRectangle()
		If Not area
			area = New TRectangle
			'fit to the gfx?
			'area.position.SetXY(140 + (slot Mod 2) * 260, 80 + Int(Ceil(slot / 2)) * GetAuctionMovieSprite().area.dimension.y)
			'area.dimension.CopyFrom(GetAuctionMovieSprite().area.dimension)
			'fit to a given height
			area.SetXY(140 + (slot Mod 2) * 260, 80 + Int(Ceil(slot / 2)) * 60)
			area.SetWH(GetAuctionMovieSprite().area.w, 60)
		EndIf
		Return area
	End Method


	Method GetLicence:TProgrammeLicence()  {_exposeToLua}
		Return licence
	End Method


	Method SetBid:Int(playerID:Int)
		If Not licence Then Return -1

		Local player:TPlayerBase = GetPlayerBase(playerID)
		If Not player Then Return -1
		'if the playerID was -1 ("auto") we should assure we have a correct id now
		playerID = player.playerID
		'already highest bidder, no need to add another bid
		If playerID = bestBidder Then Return 0


		'prices differ between the players - depending on their audience
		'reach level
		Local audienceReachLevel:Int = Max(1, GetPlayerBase(playerID).GetChannelReachLevel())
		Local thisBidRaw:Int = GetNextBidRaw()
		Local thisBid:Int = TFunctions.RoundToBeautifulValue(thisBidRaw * licence.GetAudienceReachLevelPriceMod(audienceReachLevel))

		If player.getFinance().PayAuctionBid(thisBid, Self.GetLicence())
			'another player was highest bidder, we pay him back the
			'bid he gave (which is the currently highest bid...)
			If bestBidder And GetPlayerBase(bestBidder)
				'bestBid contains the best bid adjusted for this players
				'reach level - so we need to calculate it properly
				Local previousPaidBestBid:Int = TFunctions.RoundToBeautifulValue(bestBidRaw * licence.GetAudienceReachLevelPriceMod(bestBidderLevel))
				GetPlayerFinance(bestBidder).PayBackAuctionBid(previousPaidBestBid, Self)

				'inform player AI that their bid was overbid
				If GetPlayerBase(bestBidder).isLocalAI()
					Local thisPaidBestBid:Int = thisBid
					'GetPlayerBase(bestBidder).PlayerAI.CallOnProgrammeLicenceAuctionGetOutbid(GetLicence(), thisPaidBestBid, playerID)
					GetPlayerBase(bestBidder).PlayerAI.AddEventObj( New TAIEvent.SetID(TAIEvent.OnProgrammeLicenceAuctionGetOutbid).Add(GetLicence()).AddInt(thisPaidBestBid).AddInt(playerID))
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
				TriggerBaseEvent(GameEventKeys.ProgrammeLicenceAuction_OnGetOutbid, evData, Self)
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
			TriggerBaseEvent(GameEventKeys.ProgrammeLicenceAuction_SetBid, evData, Self)

			Return bestBid
		EndIf

		Return 0
	End Method


	Method GetNextBid:Int(playerID:Int) {_exposeToLua}
		If Not licence Then Return -1

		Local audienceReachLevel:Int = Max(1, GetPlayerBase(playerID).GetChannelReachLevel())
		Return TFunctions.RoundToBeautifulValue(GetNextBidRaw() * licence.GetAudienceReachLevelPriceMod(audienceReachLevel))
	End Method


	Method GetNextBidRaw:Int()
		If Not licence Then Return -1

		Local nextBidRaw:Int = 0
		'no bid done yet, next bid is the licences price cut by 25%
		If bestBid = 0
			nextBidRaw = licence.getPriceForPlayer(0, 0) * bidSavings
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
		If Not licence Then Return -1

		licence.ShowSheet(x,y)
	End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		If Not licence Then Return

		SetColor 255,255,255  'normal
		'not yet cached?
	    If Not _imageWithText
			'print "renew cache for "+self.licence.GetTitle()
			_imageWithText = GetAuctionMovieSprite().GetImageCopy()

			Local pix:TPixmap = LockImage(_imageWithText)
			Local font:TBitmapFont = GetBitmapFont("Default", 12)
			Local titleFont:TBitmapFont	= GetBitmapFont("Default", 12, BOLDFONT)

			'set target for fonts
			TBitmapFont.setRenderTarget(_imageWithText)

			If bestBidder
				Local player:TPlayerBase = GetPlayerBase(bestBidder)
				titleFont.DrawSimple(player.name, 31,30, player.color.ToScolor8(), EDrawTextEffect.Emboss, 0.4)
			Else
				font.DrawSimple(GetLocale("AUCTION_WITHOUT_BID"), 31,30, new SColor8(150,150,150), EDrawTextEffect.Emboss, 0.4)
			EndIf
			textBlockDrawSettings.data.lineHeight = 13
			titleFont.DrawBox(licence.GetTitle(), 31,3, 215,36, sALIGN_LEFT_TOP, new SColor8(50,50,50), textBlockDrawSettings, EDrawTextEffect.Emboss, 0.4)

			font.DrawBox("|color=90,90,90|" + GetLocale("AUCTION_MAKE_BID")+":|/color| |b|"+GetFormattedCurrency(GetNextBid(GetPlayerBase().playerID))+"|/b|", 31,30, 212,-1, sALIGN_RIGHT_TOP, new SColor8(50,50,50), EDrawTextEffect.Emboss, 0.4)

			'reset target for fonts
			TBitmapFont.setRenderTarget(Null)
	    EndIf
		SetColor 255,255,255
		SetAlpha 1

		Local a:TRectangle = GetArea()
		DrawImage(_imageWithText, a.GetX(), a.GetY())

		'live
		If licence.data.IsLive()
			GetSpriteFromRegistry("pp_live").Draw(a.GetX() + _imageWithText.width - 8, a.GetY() +3,  -1, ALIGN_RIGHT_TOP)
		EndIf
		'xrated
		If licence.data.IsXRated()
			GetSpriteFromRegistry("pp_xrated").Draw(a.GetX() + _imageWithText.width - 8, a.GetY() +3,  -1, ALIGN_RIGHT_TOP)
		EndIf
		'paid
		If licence.data.IsPaid()
			GetSpriteFromRegistry("pp_paid").Draw(a.GetX() + _imageWithText.width - 8, a.GetY() +3,  -1, ALIGN_RIGHT_TOP)
		EndIf

		If TVTDebugInfo
			Local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(a.GetX(), a.GetY(), _imageWithText.width, _imageWithText.height)
			SetColor 255,255,255
			SetAlpha oldAlpha

			GetBitmapFont("default", 12).DrawSimple("bidSavings="+MathHelper.NumberToString(bidSavings, 4) + "  Min="+MathHelper.NumberToString(GetBidSavingsMinimum(), 4) + "  Decr="+MathHelper.NumberToString(GetBidSavingsDecreaseBy(), 4), a.getX() + 5, a.GetY() + 5)
			GetBitmapFont("default", 12).DrawSimple("bestBidder="+bestBidder +"  lvl="+bestBidderLevel+ "  bestBidRaw="+bestBidRaw, a.getX() + 5, a.GetY() + 5 + 12)
			GetBitmapFont("default", 12).DrawSimple("nextBidRaw="+GetNextBidRaw() + "  MyReachLevel("+GetPlayerBase().playerID+")="+Max(1, GetPlayerBase(GetPlayerBase().playerID).GetChannelReachLevel()), a.getX() + 5, a.GetY() + 5 + 2*12)
		EndIf

    End Method


	Function DrawAll()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If Not obj.GetLicence() Then Continue

			obj.Draw()
		Next

		'draw sheets (must be afterwards to avoid overlapping (itemA Sheet itemB itemC) )
	'not yet known to this class
	'todo: maybe add this to a global
	'	if not TError.hasActiveError()
			For Local obj:TAuctionProgrammeBlocks = EachIn List
				If Not obj.GetLicence() Then Continue

				If obj.GetArea().containsXY(MouseManager.x, MouseManager.y)
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
					GetAuctionMovieSprite().Draw(obj.GetArea().GetX(), obj.GetArea().GetY())
					SetAlpha 1.0
					SetBlend AlphaBlend

					obj.licence.ShowSheet(sheetX, sheetY, sheetAlign, TVTBroadcastMaterialType.PROGRAMME)

					If obj.bestBidder <> GetPlayerBaseCollection().playerID
						GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
					EndIf

					Exit
				EndIf
			Next
	'	endif
	End Function



	Function UpdateAll:Int()
		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If Not obj.GetLicence() Then Continue

			If obj.bestBidder <> GetPlayerBaseCollection().playerID And obj.GetArea().containsXY(MouseManager.x, MouseManager.y)
				If MouseManager.IsClicked(1)
					obj.SetBid( GetPlayerBaseCollection().playerID )  'set the bid

					'handled left click
					MouseManager.SetClickHandled(1)
					Return True
				EndIf
			EndIf
		Next
	End Function

End Type
