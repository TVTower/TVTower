SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "common.misc.gamegui.bmx"
Import "game.roomhandler.base.bmx"
Import "game.player.programmecollection.bmx"
Import "game.broadcast.dailybroadcaststatistic.bmx"


'Ad agency
Type RoomHandler_AdAgency extends TRoomHandler
	Global hoveredGuiAdContract:TGuiAdContract = null
	Global draggedGuiAdContract:TGuiAdContract = null

	Global VendorEntity:TSpriteEntity
	'allows registration of drop-event
	Global VendorArea:TGUISimpleRect

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listNormal:TAdContract[]
	Field listCheap:TAdContract[]
	Field listAll:TList {nosave}
	Field levelFilters:TAdContractBaseFilter[6]

	'cache to check if changes are processed yet
	Field _setRefillMode:int = 0 {nosave}

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:int = TRUE
	Global GuiListNormal:TGUIAdContractSlotList[]
	Global GuiListCheap:TGUIAdContractSlotList = null
	Global GuiListSuitcase:TGUIAdContractSlotList = null

	'sorting
	Global ListSortMode:int = 0
	Global ListSortVisible:int = False
	Global contractsSortKeys:int[] = [0,1,2]
	Global contractsSortKeysTooltips:TTooltipBase[3]
	Global contractsSortSymbols:string[] = ["gfx_datasheet_icon_minAudience", "gfx_datasheet_icon_money", "gfx_datasheet_icon_maxAudience"]

	global LS_adagency:TLowerString = TLowerString.Create("adagency")

	'configuration
	Global suitcasePos:TVec2D = new TVec2D.Init(520,100)
	Global suitcaseGuiListDisplace:TVec2D = new TVec2D.Init(14,32)
	Global contractsPerLine:int	= 4
	Global contractsNormalAmount:int = 12
	Global contractsCheapAmount:int	= 4

	Global _instance:RoomHandler_AdAgency
	Global _eventListeners:TLink[]

	Const SORT_BY_MINAUDIENCE:int = 0
	Const SORT_BY_PROFIT:int = 1
	Const SORT_BY_CLASSIFICATION:int = 2


	Function GetInstance:RoomHandler_AdAgency()
		if not _instance then _instance = new RoomHandler_AdAgency
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		contractsPerLine:int = 4
		contractsNormalAmount = 12
		contractsCheapAmount = 4
		listNormal = new TAdContract[contractsNormalAmount]
		listCheap = new TAdContract[contractsCheapAmount]

		Select GameRules.adagencySortContractsBy
			case "minaudience"
				ListSortMode = SORT_BY_MINAUDIENCE
			case "classification"
				ListSortMode = SORT_BY_CLASSIFICATION
			case "profit"
				ListSortMode = SORT_BY_PROFIT
			default
				ListSortMode = SORT_BY_MINAUDIENCE
		End Select

		VendorEntity = GetSpriteEntityFromRegistry("entity_adagency_vendor")


		For local i:int = 0 until contractsSortKeysTooltips.length
			Select i
				case SORT_BY_CLASSIFICATION
					contractsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("CLASSIFICATION")), new TRectangle.Init(0,0,-1,-1))
				case SORT_BY_PROFIT
					contractsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("AD_PROFIT")), new TRectangle.Init(0,0,-1,-1))
				case SORT_BY_MINAUDIENCE
					contractsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("MIN_AUDIENCE")), new TRectangle.Init(0,0,-1,-1))
				Default
					contractsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", "UNKNOWN SORT MODE: " + i, new TRectangle.Init(0,0,-1,-1))
			End Select
			contractsSortKeysTooltips[i].parentArea = new TRectangle.Init(0,0,30,30)
			'contractsSortKeysTooltips[i]._minTitleDim = null
			'contractsSortKeysTooltips[i]._minContentDim = null
		Next


		'set to new mode defined in the rules
		SetRefillMode( GameRules.adagencyRefillMode )


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		if not GuiListSuitcase
			GuiListNormal = GuiListNormal[..3]
			for local i:int = 0 to GuiListNormal.length-1
				local listIndex:int = GuiListNormal.length-1 - i
				GuiListNormal[listIndex] = new TGUIAdContractSlotList.Create(new TVec2D.Init(418 - i*80, 122 + i*36), new TVec2D.Init(200, 140), "adagency")
				GuiListNormal[listIndex].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
				GuiListNormal[listIndex].SetItemLimit( contractsNormalAmount / GuiListNormal.length  )
				GuiListNormal[listIndex].Resize(GetSpriteFromRegistry("gfx_contracts_0").area.GetW() * (contractsNormalAmount / GuiListNormal.length), GetSpriteFromRegistry("gfx_contracts_0").area.GetH() )
				GuiListNormal[listIndex].SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
				GuiListNormal[listIndex].SetAcceptDrop("TGuiAdContract")
				GuiListNormal[listIndex].setZindex(i)

				GuiListNormal[listIndex].Resize(-1, GuiListNormal[listIndex].rect.GetH() + 30) 'for 4x displacement
				GuiListNormal[listIndex].SetEntriesBlockDisplacement(0, 0) 'displace by 20
				GuiListNormal[listIndex].Move(0, 20)
				GuiListNormal[listIndex].SetEntryDisplacement( 0, 10)

			Next

			GuiListSuitcase	= new TGUIAdContractSlotList.Create(new TVec2D.Init(suitcasePos.GetX() + suitcaseGuiListDisplace.GetX(), suitcasePos.GetY() + suitcaseGuiListDisplace.GetY()), new TVec2D.Init(255, GetSpriteFromRegistry("gfx_contracts_0_dragged").area.GetH()), "adagency")
			GuiListSuitcase.SetAutofillSlots(true)

			GuiListCheap = new TGUIAdContractSlotList.Create(new TVec2D.Init(70, 220), new TVec2D.Init(5 +GetSpriteFromRegistry("gfx_contracts_0").area.GetW()*4,GetSpriteFromRegistry("gfx_contracts_0").area.GetH()), "adagency")
			'GuiListCheap = new TGUIAdContractSlotList.Create(new TVec2D.Init(70, 200), new TVec2D.Init(10 +GetSpriteFromRegistry("gfx_contracts_0").area.GetW()*4,GetSpriteFromRegistry("gfx_contracts_0").area.GetH()), "adagency")
			'GuiListCheap.setEntriesBlockDisplacement(70,0)
			'GuiListCheap.SetEntryDisplacement( -2*GuiListNormal[0]._slotMinDimension.x, 5)

			GuiListCheap.Move(0, -20)
			GuiListCheap.Resize(-1, GuiListCheap.rect.GetH() + 20) 'for 4x displacement
			GuiListCheap.SetEntriesBlockDisplacement(0, 20) 'displace by 20


			GuiListCheap.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
			GuiListSuitcase.SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )

			GuiListCheap.SetItemLimit(listCheap.length)
			GuiListSuitcase.SetItemLimit(GameRules.adContractsPerPlayerMax)

			GuiListCheap.SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
			GuiListSuitcase.SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW()-3, GetSpriteFromRegistry("gfx_contracts_0").area.GetH())

			GuiListCheap.SetEntryDisplacement( 0, -5)
			GuiListSuitcase.SetEntryDisplacement( 0, 0)

			GuiListCheap.SetAcceptDrop("TGuiAdContract")
			GuiListSuitcase.SetAcceptDrop("TGuiAdContract")


			'default vendor dimension
			local vendorAreaDimension:TVec2D = new TVec2D.Init(150,200)
			local vendorAreaPosition:TVec2D = new TVec2D.Init(241,110)
			if VendorEntity then vendorAreaDimension = VendorEntity.area.dimension.copy()
			if VendorEntity then vendorAreaPosition = VendorEntity.area.position.copy()

			VendorArea = new TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "scriptagency" )
			'vendor should accept drop - else no recognition
			VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)
			VendorArea.zIndex = 0
		endif


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'to react on changes in the programmeCollection (eg. contract finished)
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.addAdContract", onChangeProgrammeCollection ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction( "programmecollection.removeAdContract", onChangeProgrammeCollection ) ]
		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to vendor or suitcase
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropContract, "TGuiAdContract" ) ]
		'drop on vendor - sell things
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.onDropOnTargetAccepted", onDropContractOnVendor, "TGuiAdContract" ) ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction( "guiobject.OnMouseOver", onMouseOverContract, "TGuiAdContract" ) ]
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickContract, "TGuiAdContract") ]

		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		if GuiListSuitcase then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("adagency", GetInstance())
	End Method


	Method AbortScreenActions:Int()
		local abortedAction:int = False

		if draggedGuiAdContract
			'try to drop the licence back
			draggedGuiAdContract.dropBackToOrigin()
			draggedGuiAdContract = null
			hoveredGuiAdContract = null
			abortedAction = True
		endif

		'remove and recreate all (so they get the correct visual style)
		'do not use that - it reorders elements and changes the position
		'of empty slots ... maybe unwanted
		'GetInstance().RemoveAllGuiElements()
		'GetInstance().RefreshGuiElements()


		'change look to "stand on table look"
		For local i:int = 0 to GuiListNormal.length-1
			For Local obj:TGUIAdContract = EachIn GuiListNormal[i]._slots
				obj.InitAssets(obj.getAssetName(-1, FALSE), obj.getAssetName(-1, TRUE))
			Next
		Next
		For Local obj:TGUIAdContract = EachIn GuiListCheap._slots
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

		GetInstance().FigureEntersRoom(figure)
	End Method


	'override
	Method onTryLeaveRoom:int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE

		'do not allow leaving as long as we have a dragged block
		if draggedGuiAdContract
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


		'=== FOR ALL PLAYERS ===
		'
		'sign all new contracts
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(figure.playerID)
		For Local contract:TAdContract = EachIn programmeCollection.suitcaseAdContracts
			'adds a contract to the players collection (gets signed THERE)
			'if successful, this also removes the contract from the suitcase
			programmeCollection.AddAdContract(contract)
		Next


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
		'instead of leaving the room and accidentially adding contracts
		'we delete all unsigned contracts from the list
		GetPlayerProgrammeCollection(figure.playerID).suitcaseAdContracts.Clear()


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			AbortScreenActions()
		endif

		return True
	End Method


	'===================================
	'AD Agency: common TFunctions
	'===================================

	Method FigureEntersRoom:int(figure:TFigureBase)
		'=== FOR ALL PLAYERS ===
		'
		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'reorder AFTER refilling
			ResetContractOrder()
		endif
	End Method


	Method GetContractsInStock:TList()
		if not listAll
			listAll = CreateList()
			local lists:TAdContract[][] = [listNormal,listCheap]
			For local j:int = 0 to lists.length-1
				For Local contract:TAdContract = EachIn lists[j]
					if contract Then listAll.AddLast(contract)
				Next
			Next
		endif
		return listAll
	End Method


	Method GetContractsInStockCount:int()
		return GetContractsInStock().Count()
		rem
		Local ret:Int = 0
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract Then ret:+1
			Next
		Next
		return ret
		endrem
	End Method


	Method GetContractByPosition:TAdContract(position:int)
		if position > GetContractsInStockCount() then return null
		local currentPosition:int = 0
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract
					if currentPosition = position then return contract
					currentPosition:+1
				endif
			Next
		Next
		return null
	End Method


	Method HasContract:int(contract:TAdContract)
		return GetContractsInStock().Contains(contract)
		rem
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local cont:TAdContract = EachIn lists[j]
				if cont = contract then return TRUE
			Next
		Next
		return FALSE
		endrem
	End Method


	Method GetContractByID:TAdContract(contractID:int)
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				if contract and contract.id = contractID then return contract
			Next
		Next
		return null
	End Method


	Method GiveContractToPlayer:int(contract:TAdContract, playerID:int, sign:int=FALSE)
		'alreay owning?
		if contract.owner = playerID then return FALSE
		'does not satisfy eg. "channel image"
		if not contract.IsAvailableToSign(playerID) then return False

		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if not programmeCollection then return FALSE

		'try to add to suitcase of player
		if not sign
			if not programmeCollection.AddUnsignedAdContractToSuitcase(contract) then return FALSE
		'we do not need the suitcase, direkt sign pls (eg. for AI)
		else
			if not programmeCollection.AddAdContract(contract) then return FALSE
		endif

		'remove from agency's lists
		GetInstance().RemoveContract(contract)

		return TRUE
	End Method


	Method TakeContractFromPlayer:int(contract:TAdContract, playerID:int)
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		if not programmeCollection then return False

		if programmeCollection.RemoveUnsignedAdContractFromSuitcase(contract)
			'add to agency's lists - if not existing yet
			if not HasContract(contract)
				if not AddContract(contract)
					'if adding failed, remove the contract from the game
					'at all!
					GetAdContractCollection().Remove(contract)
				endif
			endif
			return TRUE
		else
			return FALSE
		endif
	End Method


	Function isCheapContract:int(contract:TAdContract)
		return contract.adAgencyClassification < 0
	End Function


	Method SetRefillMode(mode:int)
		_setRefillMode = mode
		if _setRefillMode = 2
			contractsSortSymbols = ["gfx_datasheet_icon_minAudience", "gfx_datasheet_icon_money"]
			contractsSortKeys = [0, 1]
		else
			contractsSortSymbols = ["gfx_datasheet_icon_minAudience", "gfx_datasheet_icon_money", "gfx_datasheet_icon_maxAudience"]
			contractsSortKeys = [0, 1, 2]
		endif
	End Method


	Method SortContracts(list:TList, mode:int = -1)
		if not list then return

		if mode = -1 then mode = ListSortMode

		Select ListSortMode
			Case SORT_BY_CLASSIFICATION
				list.sort(True, TAdContract.SortByClassification)
			Case SORT_BY_PROFIT
				list.sort(True, TAdContract.SortByProfit)
			Case SORT_BY_MINAUDIENCE
				list.sort(True, TAdContract.SortByMinAudienceRelative)
			default
				list.sort(True, TAdContract.SortByMinAudienceRelative)
		End select
	End Method


	Method ResetContractOrder:int()
		local contracts:TList = CreateList()
		for local contract:TAdContract = eachin listNormal
			'only add valid contracts
			if contract.base then contracts.addLast(contract)
		Next
		for local contract:TAdContract = eachin listCheap
			'only add valid contracts
			if contract.base then contracts.addLast(contract)
		Next
		listNormal = new TAdContract[listNormal.length]
		listCheap = new TAdContract[listCheap.length]
		listAll = null

		SortContracts(contracts, ListSortMode)

		'add again - so it gets sorted
		for local contract:TAdContract = eachin contracts
			AddContract(contract)
		Next

		RemoveAllGuiElements()
	End Method


	Method RemoveContract:int(contract:TAdContract)
		if GetContractsInStockCount() = 0 then return False

		local foundContract:int = FALSE
		'remove from agency's lists
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For local i:int = 0 to lists[j].length-1
				if lists[j][i] = contract
					lists[j][i] = null
					listAll.Remove(contract)

					'emit event
					EventManager.triggerEvent(TEventSimple.Create("adagency.removeAdContract", New TData.add("adcontract", contract), Self))

					foundContract = TRUE
				endif
			Next
		Next

		return foundContract
	End Method


	Method AddContract:int(contract:TAdContract)
		'skip if done already
		if HasContract(contract) then return False

		'try to fill the program into the corresponding list
		'we use multiple lists - if the first is full, try second
		local lists:TAdContract[][]

		if isCheapContract(contract)
			lists = [listCheap,listNormal]
		else
			lists = [listNormal,listCheap]
		endif

		'create list if needed
		GetContractsInStock()

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				if lists[j][i] then continue
				contract.SetOwner(contract.OWNER_VENDOR)
				lists[j][i] = contract
				listAll.Addlast(contract)
				'emit event
				EventManager.triggerEvent(TEventSimple.Create("adagency.addAdContract", New TData.add("adcontract", contract), Self))

				return TRUE
			Next
		Next

		'there was no empty slot to place that programme
		'so just give it back to the pool
		contract.SetOwner(contract.OWNER_NOBODY)

		return FALSE
	End Method


	Method RemoveRandomContracts:int(removeChance:Float = 1.0)
		local toRemove:TAdContract[]
		For local c:TAdContract = EachIn GetContractsInStock()
			'delete an old contract by a chance of 50%
			if RandRange(0,100) < removeChance*100
				toRemove :+ [c]
			endif
		Next

		For local c:TAdContract = EachIn toRemove
			'remove from game! - else the contracts stay
			'there forever!
			GetAdContractCollection().Remove(c)

			'unlink from the lists
			RemoveContract(c)

			'let the contract cleanup too
			c.Remove()
		Next

		return toRemove.length
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		For local i:int = 0 to GuiListNormal.length-1
			GuiListNormal[i].EmptyList()
		Next
		GuiListCheap.EmptyList()
		GuiListSuitcase.EmptyList()
		For local guiAdContract:TGuiAdContract = eachin GuiManager.listDragged.Copy()
			guiAdContract.remove()
			guiAdContract = null
		Next

		hoveredGuiAdContract = null
		draggedGuiAdContract = null

		'to recreate everything during next update...
		haveToRefreshGuiElements = TRUE
	End Function


	Method RefreshGuiElements:int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the player does not have any longer

		'suitcase
		local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(GetPlayerBase().playerID)
		For local guiAdContract:TGuiAdContract = eachin GuiListSuitcase._slots
			'if the player has this contract in suitcase or list, skip deletion
			if programmeCollection.HasAdContract(guiAdContract.contract) then continue
			if programmeCollection.HasUnsignedAdContractInSuitcase(guiAdContract.contract) then continue

			'print "guiListSuitcase has obsolete contract: "+guiAdContract.contract.id
			guiAdContract.remove()
			guiAdContract = null
		Next
		'agency lists
		For local i:int = 0 to GuiListNormal.length-1
			For local guiAdContract:TGuiAdContract = eachin GuiListNormal[i]._slots
				'if not HasContract(guiAdContract.contract) then print "REM guiListNormal"+i+" has obsolete contract: "+guiAdContract.contract.id
				if not HasContract(guiAdContract.contract)
					guiAdContract.remove()
					guiAdContract = null
				endif
			Next
		Next
		For local guiAdContract:TGuiAdContract = eachin GuiListCheap._slots
			'if not HasContract(guiAdContract.contract) then	print "REM guiListCheap has obsolete contract: "+guiAdContract.contract.id
			if not HasContract(guiAdContract.contract)
				guiAdContract.remove()
				guiAdContract = null
			endif
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all contract-lists

		'normal list
		For local contract:TAdContract = eachin listNormal
			if not contract then continue
			local contractAdded:int = FALSE

			'search the contract in all of our lists...
			local contractFound:int = FALSE
			For local i:int = 0 to GuiListNormal.length-1
				if contractFound then continue
				if GuiListNormal[i].ContainsContract(contract) then contractFound=true
			Next

			'try to fill in one of the normalList-Parts
			if not contractFound
				For local i:int = 0 to GuiListNormal.length-1
					if contractAdded then continue
					if GuiListNormal[i].ContainsContract(contract) then contractAdded=true;continue
					if GuiListNormal[i].getFreeSlot() < 0 then continue
					local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
					'change look
					block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

					'print "ADD guiListNormal"+i+" missed new contract: "+block.contract.id

					GuiListNormal[i].addItem(block, "-1")
					contractAdded = true
				Next
				if not contractAdded
					TLogger.log("AdAgency.RefreshGuiElements", "contract exists but does not fit in GuiListNormal - contract removed.", LOG_ERROR)
					RemoveContract(contract)
				endif
			endif
		Next

		'cheap list
		For local contract:TAdContract = eachin listCheap
			if not contract then continue
			if GuiListCheap.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, FALSE), block.getAssetName(-1, TRUE))

			'print "ADD guiListCheap missed new contract: "+block.contract.id

			GuiListCheap.addItem(block, "-1")
		Next

		'create missing gui elements for the players contracts
		For local contract:TAdContract = eachin programmeCollection.adContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "ADD guiListSuitcase missed new (old) contract: "+block.contract.id

			block.setOption(GUI_OBJECT_DRAGABLE, FALSE)
			guiListSuitcase.addItem(block, "-1")
		Next

		'create missing gui elements for the current suitcase
		For local contract:TAdContract = eachin programmeCollection.suitcaseAdContracts
			if guiListSuitcase.ContainsContract(contract) then continue
			local block:TGuiAdContract = new TGuiAdContract.CreateWithContract(contract)
			'change look
			block.InitAssets(block.getAssetName(-1, TRUE), block.getAssetName(-1, TRUE))

			'print "guiListSuitcase missed new contract: "+block.contract.id

			guiListSuitcase.addItem(block, "-1")
		Next
		haveToRefreshGuiElements = FALSE
	End Method


	'refills slots in the ad agency
	'replaceOffer: remove (some) old contracts and place new there?
	Method ReFillBlocks:Int(replaceOffer:int=FALSE, replaceChance:float=1.0)
		haveToRefreshGuiElements = TRUE

		'reset list cache
		listAll = null

		'delete some random ads
		if replaceOffer then RemoveRandomContracts(replaceChance)


		if GameRules.adagencyRefillMode <= 1
			RefillBlocksMode1()
		else
			RefillBlocksMode2()
		endif
	End Method


	Method RefillBlocksMode1()
		TLogger.log("AdAgency.RefillBlocks", "RefillBlocksMode1.", LOG_DEBUG)

		'=== CALCULATE VARIOUS INFORMATION FOR FILTERS ===
		'we calculate the "average quote" using yesterdays audience but
		'todays reach ... so it is not 100% accurate (buying stations today
		'will lower the quote)
		local averageChannelImage:Float = GetPublicImageCollection().GetAverage().GetAverageImage()
		local averageChannelReach:Int = GetStationMapCollection().GetAverageReach()
		local averageChannelQuoteDayTime:Float = 0.0
		local averageChannelQuotePrimeTime:Float = 0.0
		local dayWithoutPrimeTime:int[] = [6,7,8,9,10,11,12,13,14,15,16,17,23 ] 'without primetime 18-22 and night time 0-5
		local dayOnlyPrimeTime:int[] = [18,19,20,21,22]
		if averageChannelReach > 0
			'GetAverageAudienceForHours expects "hours to skip" !
			averageChannelQuoteDayTime = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetAverageAudienceForHours(-1, dayWithoutPrimeTime).GetTotalSum() / averageChannelReach
			averageChannelQuotePrimeTime = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetAverageAudienceForHours(-1, dayOnlyPrimeTime).GetTotalSum() / averageChannelReach
		endif

		local highestChannelImage:Float = averageChannelImage
		local highestChannelQuoteDayTime:Float = 0.0
		local highestChannelQuotePrimeTime:Float = 0.0

		local lowestChannelImage:Float = averageChannelImage
		local lowestChannelQuoteDayTime:Float = -1
		local lowestChannelQuotePrimeTime:Float = -1

		local onDayOne:int = (Getworldtime().GetDay() = GetWorldtime().GetStartDay())
		if onDayOne
			'quotes of TOTAL REACH, not of WHO IS AT HOME
			lowestChannelQuoteDayTime = 0.005
			lowestChannelQuotePrimeTime = 0.01

			averageChannelQuoteDayTime = 0.015 '0.02
			averageChannelQuotePrimeTime = 0.04

			highestChannelQuoteDayTime = 0.045
			highestChannelQuotePrimeTime = 0.075 '0.1
		else
			For local i:int = 1 to 4
				local image:Float = GetPublicImageCollection().Get(i).GetAverageImage()
				if image > highestChannelImage then highestChannelImage = image
				if image < lowestChannelImage then lowestChannelImage = image

				'daytime (without night)
				if averageChannelReach > 0
					local audience:Float = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetAverageAudienceForHours(i, dayWithoutPrimeTime).GetTotalSum()
					local quote:Float = audience / averageChannelReach
					if lowestChannelQuoteDayTime < 0 then lowestChannelQuoteDayTime = quote
					if lowestChannelQuoteDayTime > quote then lowestChannelQuoteDayTime = quote
					if highestChannelQuoteDayTime < quote then highestChannelQuoteDayTime = quote
				endif

				'primetime (without day and night)
				if averageChannelReach > 0
					local audience:Float = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetAverageAudienceForHours(i, dayOnlyPrimeTime).GetTotalSum()
					local quote:Float = audience / averageChannelReach
					if lowestChannelQuotePrimeTime < 0 then lowestChannelQuotePrimeTime = quote
					if lowestChannelQuotePrimeTime > quote then lowestChannelQuotePrimeTime = quote
					if highestChannelQuotePrimeTime < quote then highestChannelQuotePrimeTime = quote
				endif
			Next
		endif
		'convert to percentage
		highestChannelImage :* 0.01
		averageChannelImage :* 0.01
		lowestChannelImage :* 0.01


		'=== SETUP FILTERS ===
		local spotMin:Float = 0.0001 '0.01% to avoid 0.0-spots
		local rangeStep:Float = 0.005 '0.5%
		local limitInstances:int = GameRules.adContractInstancesMax

		'the cheap list contains really low contracts
		local cheapListFilter:TAdContractBaseFilter = new TAdContractbaseFilter
		'0.5% market share -> 1mio reach means 5.000 people!
		cheapListFilter.SetAudience(spotMin, Max(spotMin, 0.005))
		'no image requirements - or not more than the lowest image
		'(so all could sign this)
		cheapListFilter.SetImage(0, 0.01 * lowestChannelImage)
		'cheap contracts should in now case limit genre/groups
		cheapListFilter.SetSkipLimitedToProgrammeGenre()
		cheapListFilter.SetSkipLimitedToTargetGroup()
		'the dev value is defining how many simultaneously are allowed
		'while the filter filters contracts already having that much (or
		'more) contracts, that's why we subtract 1
		if limitInstances > 0 then cheapListFilter.SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		'the 12 contracts are divided into 6 groups
		'4x fitting the lowest requirements (2x day, 2x prime)
		'4x fitting the average requirements -> 8x planned but slots limited (2x day, 2x prime)
		'4x fitting the highest requirements (2x day, 2x prime)
		for local i:int = 0 until levelFilters.length
			if not levelFilters[i] then levelFilters[i] = new TAdContractBaseFilter
		Next
		'=== LOWEST ===
		levelFilters[0] = new TAdContractbaseFilter
		'from 80-120% of lowest (Minimum of 0.01%)
		levelFilters[0].SetAudience(Max(spotMin, 0.8 * lowestChannelQuoteDaytime), Max(spotMin , 1.2 * lowestChannelQuoteDayTime))
		'1% - avgImage %
		levelFilters[0].SetImage(0.0, lowestChannelImage)
		'lowest should be without "limits"
		levelFilters[0].SetSkipLimitedToProgrammeGenre()
		levelFilters[0].SetSkipLimitedToTargetGroup()
		if limitInstances > 0 then levelFilters[0].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		levelFilters[1] = new TAdContractbaseFilter
		levelFilters[1].SetAudience(Max(spotMin, 0.8 * lowestChannelQuotePrimeTime), Max(spotMin , 1.2 * lowestChannelQuotePrimeTime))
		levelFilters[1].SetImage(0.0, lowestChannelImage)
		levelFilters[1].SetSkipLimitedToProgrammeGenre()
		levelFilters[1].SetSkipLimitedToTargetGroup()
		if limitInstances > 0 then levelFilters[1].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		'=== AVERAGE ===
		levelFilters[2] = new TAdContractbaseFilter
		'from 70% of avg to 130% of avg, may cross with lowest!
		'levelFilters[1].SetAudience(0.8 * averageChannelQuote, Max(0.01, 1.2 * averageChannelQuote))
		'weighted Minimum/Maximum (the more away from border, the
		'stronger the influence)
		local minAvg:Float = (0.7 * lowestChannelQuoteDayTime + 0.3 * averageChannelQuoteDayTime)
		local maxAvg:Float = (0.3 * averageChannelQuoteDayTime + 0.7 * highestChannelQuoteDayTime)
		levelFilters[2].SetAudience(Max(spotMin, minAvg), Max(spotMin, maxAvg))
		'0-100% of average Image
		levelFilters[2].SetImage(0, averageChannelImage)
		if limitInstances > 0 then levelFilters[2].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		levelFilters[3] = new TAdContractbaseFilter
		minAvg = (0.7 * lowestChannelQuotePrimeTime + 0.3 * averageChannelQuotePrimeTime)
		maxAvg = (0.3 * averageChannelQuotePrimeTime + 0.7 * highestChannelQuotePrimeTime)
		levelFilters[3].SetAudience(Max(spotMin, minAvg), Max(spotMin, maxAvg))
		levelFilters[3].SetImage(0, averageChannelImage)
		if limitInstances > 0 then levelFilters[3].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		'=== HIGH ===
		levelFilters[4] = new TAdContractbaseFilter
		'from 50% of avg to 150% of highest
		levelFilters[4].SetAudience(Max(spotMin, 0.7 * highestChannelQuoteDayTime), Max(spotMin, 1.2 * highestChannelQuoteDayTime))
		'0-100% of highest Image
		levelFilters[4].SetImage(0, highestChannelImage)
		if limitInstances > 0 then levelFilters[4].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		levelFilters[5] = new TAdContractbaseFilter
		levelFilters[5].SetAudience(Max(spotMin, 0.7 * highestChannelQuotePrimeTime), Max(spotMin, 1.2 * highestChannelQuotePrimeTime))
		levelFilters[5].SetImage(0, highestChannelImage)
		if limitInstances > 0 then levelFilters[5].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		TLogger.log("AdAgency.RefillBlocks", "Refilling "+ GetWorldTime().GetFormattedTime() +". Filter details", LOG_DEBUG)

rem
print "REFILL:"
print "level0:  audienceDay "+"0.0%"+" - "+MathHelper.NumberToString(100*lowestChannelQuoteDayTime, 2)+"%"
print "level0:  audiencePrime "+"0.0%"+" - "+MathHelper.NumberToString(100*lowestChannelQuotePrimeTime, 2)+"%"
print "level0:  image    "+"0.0"+" - "+lowestChannelImage
print "level1:  audienceDay "+MathHelper.NumberToString(100 * (0.5 * averageChannelQuoteDayTime),2)+"% - "+MathHelper.NumberToString(100 * Max(0.01, 1.5 * averageChannelQuoteDayTime),2)+"%"
print "level1:  audiencePrime "+MathHelper.NumberToString(100 * (0.5 * averageChannelQuotePrimeTime),2)+"% - "+MathHelper.NumberToString(100 * Max(0.01, 1.5 * averageChannelQuotePrimeTime),2)+"%"
print "level1:  image     0.00 - "+averageChannelImage
print "level2:  audienceDay "+MathHelper.NumberToString(100*(Max(0.01, 0.5 * highestChannelQuoteDayTime)),2)+"% - "+MathHelper.NumberToString(100 * Max(0.03, 1.5 * highestChannelQuoteDayTime),2)+"%"
print "level2:  audiencePrime "+MathHelper.NumberToString(100*(Max(0.01, 0.5 * highestChannelQuotePrimeTime)),2)+"% - "+MathHelper.NumberToString(100 * Max(0.03, 1.5 * highestChannelQuotePrimeTime),2)+"%"
print "level2:  image     0.00 - "+highestChannelImage
print "------------------"
endrem
		'=== ACTUALLY CREATE CONTRACTS ===
		local classification:int = -1
		local lists:TAdContract[][] = [listNormal,listCheap]
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists and is valid...skip it
				if lists[j][i] and lists[j][i].base then continue

				local contract:TAdContract

				if lists[j] = listNormal
					local filterNum:int = 0
					Select floor(i / 4)
						case 2
							'levelFilters[4 + 5]
							if i mod 4 <= 1
								filterNum = 4
								classification = 4
							else
								filterNum = 5
								classification = 5
							endif
						case 1
							'levelFilters[2 + 3]
							if i mod 4 <= 1
								filterNum = 2
								classification = 2
							else
								filterNum = 3
								classification = 3
							endif
						case 0
							'levelFilters[0 + 1]
							if i mod 4 <= 1
								filterNum = 0
								classification = 0
							else
								filterNum = 1
								classification = 1
							endif
					End Select

					'check if there is an adcontract base available for this filter
					local contractBase:TAdContractBase = null
					while not contractBase
						contractBase = GetAdContractBaseCollection().GetRandomNormalByFilter(levelFilters[filterNum], False)
						'if not, then lower minimum and increase maximum audience
						if not contractBase
							TLogger.log("AdAgency.RefillBlocks", "Adjusting LevelFilter #"+filterNum+"  Min: " +MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMin,2)+"% ("+(100 * levelFilters[filterNum].minAudienceMin)+" - 0.5%   Max: "+ MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMax,2)+"% + 0.5%"  , LOG_DEBUG)
							levelFilters[filterNum].SetAudience( Max(0.0, levelFilters[filterNum].minAudienceMin - rangeStep), Min(1.0, levelFilters[filterNum].minAudienceMax + rangeStep))
						endif

						'absolutely nothing available?
						if not contractBase and levelFilters[filterNum].minAudienceMin = 0.0 and levelFilters[filterNum].minAudienceMax = 1.0
							TLogger.log("AdAgency.RefillBlocks", "FAILED to find new contract for LevelFilter #"+filterNum+"  Min: " +MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMin,2)+"%   Max: "+ MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMax,2)+"%."  , LOG_DEBUG)
						endif
					Wend
					if contractBase
						contract = new TAdContract.Create( contractBase )
					endif
					'print "refilling ads with filternum="+filternum+"  classification="+classification
				EndIf

				'=== CHEAP LIST ===
				if lists[j] = listCheap
					'check if there is an adcontract base available for this filter
					local contractBase:TAdContractBase = null
					while not contractBase
						contractBase = GetAdContractBaseCollection().GetRandomNormalByFilter(cheapListFilter, False)
						'if not, then lower minimum and increase maximum audience
						if not contractBase
							TLogger.log("AdAgency.RefillBlocks", "Adjusting CheapListFilter  Min: " +MathHelper.NumberToString(100 * cheapListFilter.minAudienceMin,2)+"% - 0.5%   Max: "+ MathHelper.NumberToString(100 * cheapListFilter.minAudienceMax,2)+"% + 0.5%"  , LOG_DEBUG)
							cheapListFilter.SetAudience( Max(0, cheapListFilter.minAudienceMin - rangeStep), Min(1.0, cheapListFilter.minAudienceMax + rangeStep))
						endif

						'absolutely nothing available?
						if not contractBase and cheapListFilter.minAudienceMin = 0.0 and cheapListFilter.minAudienceMax = 1.0
							TLogger.log("AdAgency.RefillBlocks", "FAILED to find new contract for CheapListFilter  Min: " +MathHelper.NumberToString(100 * cheapListFilter.minAudienceMin,2)+"%   Max: "+ MathHelper.NumberToString(100 * cheapListFilter.minAudienceMax,2)+"%."  , LOG_DEBUG)
						endif
					Wend
					if contractBase
						contract = new TAdContract.Create( contractBase )
					endif

					classification = -1
				endif


				if not contract
					TLogger.log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+i+". Using absolutely random one without limitations.", LOG_ERROR)
					'try again without filter - to avoid "empty room"
					contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandom() )
				endif

				'add new contract to slot
				if contract
					'set classification so contract knows its "origin"
					contract.adAgencyClassification = classification
					contract.SetOwner(contract.OWNER_VENDOR)

					GetContractsInStock().AddLast(contract)
					'add afterwards as "GetContractsInStock()" might create
					'a list already containing the lists[][]-content)
					lists[j][i] = contract

					'emit event
					EventManager.triggerEvent(TEventSimple.Create("adagency.addAdContract", New TData.add("adcontract", contract), Self))
				endif
			Next
		Next

		'now all filters contain "valid ranges"
		TLogger.log("AdAgency.RefillBlocks", "    Cheap filter: "+cheapListFilter.ToString(), LOG_DEBUG)

		for local i:int = 0 until 6
			if i mod 2 = 0
				TLogger.log("AdAgency.RefillBlocks", "  Level "+i+" filter: "+levelFilters[i].ToString() + " [DAYTIME]", LOG_DEBUG)
			else
				TLogger.log("AdAgency.RefillBlocks", "  Level "+i+" filter: "+levelFilters[i].ToString() + " [PRIMETIME]", LOG_DEBUG)
			endif
		next
	End Method


	Method RefillBlocksMode2()
		TLogger.log("AdAgency.RefillBlocks", "RefillBlocksMode2.", LOG_DEBUG)

		'=== CALCULATE VARIOUS INFORMATION FOR FILTERS ===
		'we calculate the "average quote" using yesterdays audience but
		'todays reach ... so it is not 100% accurate (buying stations today
		'will lower the quote)
		local averageChannelImage:Float = GetPublicImageCollection().GetAverage().GetAverageImage()
		local averageChannelReach:Int = GetStationMapCollection().GetAverageReach()

		local highestChannelImage:Float = averageChannelImage
		local lowestChannelImage:Float = averageChannelImage

		local highestChannelQuote:Float = 0.0
		local lowestChannelQuote:Float = -1
		local averageChannelQuote:Float = -1

		local onDayOne:int = (Getworldtime().GetDay() = GetWorldtime().GetStartDay())
		if onDayOne
			'quotes of TOTAL REACH, not of WHO IS AT HOME
			lowestChannelQuote = 0.005
			averageChannelQuote = 0.085
			highestChannelQuote = 0.175
		else
			For local i:int = 1 to 4
				local image:Float = GetPublicImageCollection().Get(i).GetAverageImage()
				if image > highestChannelImage then highestChannelImage = image
				if image < lowestChannelImage then lowestChannelImage = image

				if averageChannelReach > 0
					local bestAudience:int = GetDailyBroadcastStatistic( GetWorldTime().GetDay()-1, True ).GetBestAudienceForHours(i, [-1]).GetTotalSum()
					local quote:Float = bestAudience / float(averageChannelReach)
					if highestChannelQuote < quote then highestChannelQuote = quote
				endif
			Next

			'highestQuote to use is AT LEAST 17.5% (like default) to avoid
			'a too low maximum if all channels fail for one day
			highestChannelQuote = Max(highestChannelQuote, 0.175)
		endif
		'convert to percentage
		highestChannelImage :* 0.01
		averageChannelImage :* 0.01
		lowestChannelImage :* 0.01


		'=== OTHER BASIC INFORMATION ===
		local limitInstances:int = GameRules.adContractInstancesMax
		local rangeStep:Float = 0.005 '0.5%




		'=== CHEAP LIST ===
		'the cheap list contains really low contracts
		local cheapListFilter:TAdContractBaseFilter = new TAdContractbaseFilter
		'0.5% market share -> 1mio reach means 5.000 people!
		cheapListFilter.SetAudience(0.0005, 0.005)
		'no image requirements > lowest (so all could sign this)
		cheapListFilter.SetImage(0, 0.01 * lowestChannelImage)
		'cheap contracts should in no case limit genre/groups
		cheapListFilter.SetSkipLimitedToProgrammeGenre()
		cheapListFilter.SetSkipLimitedToTargetGroup()
		'the dev value is defining how many simultaneously are allowed
		'while the filter filters contracts already having that much (or
		'more) contracts, that's why we subtract 1
		if limitInstances > 0 then cheapListFilter.SetCurrentlyUsedByContractsLimit(0, limitInstances-1)


		'=== NON-CHEAP ===
		levelFilters[0] = new TAdContractbaseFilter
		'from 0,51% to 120% of best audience of that day
		levelFilters[0].SetAudience(0.0051, 1.2 * highestChannelQuote)
		'1% - avgImage %
		levelFilters[0].SetImage(0.0, 1.2*highestChannelImage)
		if limitInstances > 0 then levelFilters[0].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)




		'=== FILL EMPTY SLOTS ===
		'=== ACTUALLY CREATE CONTRACTS ===
		local classification:int = -1
		local lists:TAdContract[][] = [listNormal,listCheap]
		for local j:int = 0 to lists.length-1
			for local i:int = 0 to lists[j].length-1
				'if exists and is valid...skip it
				if lists[j][i] and lists[j][i].base then continue

				local contract:TAdContract
				local filter:TAdContractBaseFilter
				local filterName:string = "unknown"

				if lists[j] = listNormal
					filter = levelFilters[0]
					classification = 0
					filterName="LevelFilter #0"
				else
					filter = cheapListFilter
					classification = -1
					filterName="CheapListFilter"
				endif

				'check if there is an adcontract base available for this filter
				local contractBase:TAdContractBase = null
				while not contractBase
					contractBase = GetAdContractBaseCollection().GetRandomNormalByFilter(filter, False)
					'if not, then lower minimum and increase maximum audience
					if not contractBase
						TLogger.log("AdAgency.RefillBlocks", "Adjusting "+filterName+"  Min: " +MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"% ("+(100 * filter.minAudienceMin)+" - 0.5%   Max: "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"% + 0.5%"  , LOG_DEBUG)
						filter.SetAudience( Max(0.0, filter.minAudienceMin - rangeStep), Min(1.0, filter.minAudienceMax + rangeStep))
					endif

					'absolutely nothing available?
					if not contractBase and filter.minAudienceMin = 0.0 and filter.minAudienceMax = 1.0
						TLogger.log("AdAgency.RefillBlocks", "FAILED to find new contract for "+filterName+"  Min: " +MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"%   Max: "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"%."  , LOG_DEBUG)
					endif
				Wend
				if contractBase
					contract = new TAdContract.Create( contractBase )
				endif

				if not contract
					TLogger.log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+j+". Using absolutely random one without limitations.", LOG_ERROR)
					'try again without filter - to avoid "empty room"
					contract = new TAdContract.Create( GetAdContractBaseCollection().GetRandom() )
				endif

				'add new contract to slot
				if contract
					'set classification so contract knows its "origin"
					contract.adAgencyClassification = classification

					contract.SetOwner(contract.OWNER_VENDOR)
					GetContractsInStock().AddLast(contract)
					'add afterwards as "GetContractsInStock()" might create
					'a list already containing the lists[][]-content)
					lists[j][i] = contract

					'emit event
					EventManager.triggerEvent(TEventSimple.Create("adagency.addAdContract", New TData.add("adcontract", contract), Self))
				endif
			Next
		Next

		'now all filters contain "valid ranges"
		TLogger.log("AdAgency.RefillBlocks", "    Cheap filter: "+cheapListFilter.ToString(), LOG_DEBUG)
		TLogger.log("AdAgency.RefillBlocks", "  Level 0 filter: "+levelFilters[0].ToString(), LOG_DEBUG)
	End Method



	'===================================
	'Ad Agency: Room screen
	'===================================

	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("adagency") then return FALSE

		GetInstance().RefreshGuiElements()
	End Function


	'in case of right mouse button click a dragged contract is
	'placed at its original spot again
	Function onClickContract:int(triggerEvent:TEventBase)
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiAdContract:TGuiAdContract= TGUIAdContract(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiAdContract or not guiAdContract.isDragged() then return FALSE

		'remove gui object
		guiAdContract.remove()
		guiAdContract = null

		'rebuild at correct spot
		GetInstance().RefreshGuiElements()

		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
		'also avoid long click (touch screen)
		MouseManager.ResetLongClicked(1)
	End Function


	Function onMouseOverContract:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("adagency") then return FALSE

		local item:TGuiAdContract = TGuiAdContract(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiAdContract = item
		if item.isDragged() then draggedGuiAdContract = item

		return TRUE
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropContractOnVendor:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("adagency") then return FALSE

		local guiBlock:TGuiAdContract = TGuiAdContract( triggerEvent._sender )
		local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		if not guiBlock or not receiver or receiver <> VendorArea then return FALSE

		local parent:TGUIobject = guiBlock._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(parent)
		if not senderList then return FALSE

		'if coming from suitcase, try to remove it from the player
		if senderList = GuiListSuitcase
			if not GetInstance().TakeContractFromPlayer(guiBlock.contract, GetPlayerBase().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif
		else
			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiBlock.contract)
			GetInstance().AddContract(guiBlock.contract)
		endif
		'remove the block, will get recreated if needed
		guiBlock.remove()
		guiBlock = null

		'something changed...refresh missing/obsolete...
		GetInstance().RefreshGuiElements()

		return TRUE
	End function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropContract:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("adagency") then return FALSE

		local guiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent._sender)
		local receiverList:TGUIAdContractSlotList = TGUIAdContractSlotList(triggerEvent._receiver)
		if not guiAdContract or not receiverList then return FALSE

		'get current owner of the contract, as the field "owner" is set
		'during sign we cannot rely on it. So we check if the player has
		'the contract in the suitcaseContractList
		local owner:int = guiAdContract.contract.owner
		if owner <= 0 and GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasUnsignedAdContractInSuitcase( guiAdContract.contract )
			owner = GetPlayerBase().playerID
		endif

		'find out if we sell it to the vendor or drop it to our suitcase
		if receiverList <> GuiListSuitcase
			guiAdContract.InitAssets( guiAdContract.getAssetName(-1, FALSE ), guiAdContract.getAssetName(-1, TRUE ) )

			'no problem when dropping vendor programme to vendor..
			if owner <= 0 then return TRUE

			if not GetInstance().TakeContractFromPlayer(guiAdContract.contract, GetPlayerBase().playerID )
				triggerEvent.setVeto()
				return FALSE
			endif

			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiAdContract.contract)
			GetInstance().AddContract(guiAdContract.contract)
		else
			guiAdContract.InitAssets(guiAdContract.getAssetName(-1, TRUE ), guiAdContract.getAssetName(-1, TRUE ))
			'no problem when dropping own programme to suitcase..
			if owner = GetPlayerBase().playerID then return TRUE
			if not GetInstance().GiveContractToPlayer(guiAdContract.contract, GetPlayerBase().playerID)
				triggerEvent.setVeto()
				return FALSE
			endif
		endIf

		return TRUE
	End Function


	Method onDrawRoom:int( triggerEvent:TEventBase )
		if VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase_big").Draw(suitcasePos.GetX(), suitcasePos.GetY())

		'make suitcase/vendor highlighted if needed
		local highlightSuitcase:int = False
		local highlightVendor:int = False

		if draggedGuiAdContract
			if not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasUnsignedAdContractInSuitcase(draggedGuiAdContract.contract)
				highlightSuitcase = True
			endif
			highlightVendor = True
		endif

		if highlightVendor or highlightSuitcase
			local oldCol:TColor = new TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * sin(Time.GetAppTimeGone() / 5))

			if VendorEntity and highlightVendor then VendorEntity.Render()
			if highlightSuitcase then GetSpriteFromRegistry("gfx_suitcase_big").Draw(suitcasePos.GetX(), suitcasePos.GetY())

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		endif


		local availableSortKeys:int[]
		if not ListSortVisible
			availableSortKeys :+ [ListSortMode]
		else
			availableSortKeys :+ contractsSortKeys
		endif

		local skin:TDatasheetSkin = GetDatasheetSkin("default")
		local boxWidth:int = 28 + availableSortKeys.length * 38
		local boxHeight:int = 35 + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		local contentX:int = 5 + skin.GetContentX()
		skin.RenderContent(contentX, 325 +skin.GetContentY(), skin.GetContentW(boxWidth), 42, "1_top")


		For local i:int = 0 until availableSortKeys.length
			local spriteName:string = "gfx_gui_button.datasheet"
			if ListSortMode = availableSortKeys[i]
				spriteName = "gfx_gui_button.datasheet.positive"
			endif

			if THelper.MouseIn(contentX + 5 + i*38, 342, 35, 27)
				spriteName :+ ".hover"
			endif
			GetSpriteFromRegistry(spriteName).DrawArea(contentX + 5 + i*38, 342, 35,27)
			GetSpriteFromRegistry(contractsSortSymbols[ availableSortKeys[i] ]).Draw(contentX + 10 + i*38, 344)
		Next

		GUIManager.Draw( LS_adagency )

		skin.RenderBorder(5, 330, boxWidth, boxHeight)

		'tooltips
		For local i:int = 0 until availableSortKeys.length
			if contractsSortKeysTooltips[availableSortKeys[i]]
				contractsSortKeysTooltips[availableSortKeys[i]].Render()
			endif
		Next


		if hoveredGuiAdContract
			'draw the current sheet
			if hoveredGuiAdContract.IsDragged()
				hoveredGuiAdContract.DrawSheet()
			else
				'rem
				'MODE 1: trash contracts have right aligned sheets
				'        rest is left aligned
				if GuiListCheap.ContainsContract(hoveredGuiAdContract.contract)
					hoveredGuiAdContract.DrawSheet(,, 1)
				else
					hoveredGuiAdContract.DrawSheet(,, 0)
				endif
				'endrem

				rem
				'MODE 2: all contracts are left aligned
				'        ->problems with big datasheets for trash ads
				'          as they overlap the contracts then
				hoveredGuiAdContract.DrawSheet(,, 0)
				endrem
			endif
		endif


		if TVTDebugInfos
			DrawImage(GetSpritepackFromRegistry("gfx_screen_adagency_pack").GetImage(), 0,0)
			SetColor 0,0,0
			SetAlpha 0.6
			DrawRect(15,215, 380, 200)
			SetAlpha 1.0
			SetColor 255,255,255
			GetBitmapFont("default", 12).Draw("RefillMode:" + GameRules.adagencyRefillMode, 20, 220)
			GetBitmapFont("default", 12).Draw("Durchschnittsquoten:", 20, 240)
			local y:int = 260
			local filterNum:int = 0
			for local filter:TAdContractBaseFilter = eachIn levelFilters
				filterNum :+ 1
				local title:string = "#"+filterNum
				select filterNum
					case 1	title = "Schlechtester (Tag):~t"
					case 2	title = "Schlechtester (Prime):"
					case 3	title = "Durchschnitt (Tag):~t"
					case 4	title = "Durchschnitt (Prime):"
					case 5	title = "Bester Spieler (Tag):~t"
					case 6	title = "Bester Spieler (Prime):"
				End Select
				GetBitmapFont("default", 12).Draw(title+"~tMinAudience = " + MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"% - "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"%", 20, y)
				if filterNum mod 2 = 0 then y :+ 4
				y:+ 13
			Next
		endif

	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		if VendorEntity Then VendorEntity.Update()

		GetGameBase().cursorstate = 0

		'update refill mode if needed
		if GameRules.adagencyRefillMode <> _setRefillMode
			SetRefillMode(GameRules.adagencyRefillMode)
		endif

		ListSortVisible = False
		If not draggedGuiAdContract
			'show and react to mouse-over-sort-buttons
			'HINT: does not work for touch displays
			local skin:TDatasheetSkin = GetDatasheetSkin("default")
			local boxWidth:int = 28 + contractsSortKeys.Length * 38
			local boxHeight:int = 35 + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
			if THelper.MouseIn(5, 335, boxWidth, boxHeight)
				ListSortVisible = True

				if MouseManager.isShortClicked(1)
					local contentX:int = 5 + skin.GetContentX()

					For local i:int = 0 to contractsSortKeys.length-1
						If THelper.MouseIn(contentX + i*38, 342, 35, 27)
							'sort now
							if ListSortMode <> contractsSortKeys[i]
								ListSortMode = contractsSortKeys[i]
								'this sorts the contract list and recreates
								'the gui
								ResetContractOrder()
							endif
						endif
					Next
				endif
			endif

			'move tooltips
			local contentX:int = 5 + skin.GetContentX()
			For local i:int = 0 to contractsSortKeys.length-1
				if contractsSortKeysTooltips[contractsSortKeys[i]]
					contractsSortKeysTooltips[contractsSortKeys[i]].parentArea.SetXYWH(contentX + 5 + i*38, 342, 35,27)
				endif
			Next
		endif

		'update tooltips
		For local i:int = 0 to contractsSortKeys.length-1
			contractsSortKeysTooltips[contractsSortKeys[i]].Update()
		Next

		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiAdContract = null
		'reset dragged block too
		draggedGuiAdContract = null

		GUIManager.Update( LS_adagency )
	End Method

End Type




'a graphical representation of contracts at the ad-agency ...
Type TGuiAdContract Extends TGUIGameListItem
	Field contract:TAdContract


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGuiAdContract(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_contracts_0"
		Self.assetNameDragged = "gfx_contracts_0_dragged"

		Return Self
	End Method


	Method CreateWithContract:TGuiAdContract(contract:TAdContract)
		Self.Create()
		Self.setContract(contract)
		Return Self
	End Method


	Method SetContract:TGuiAdContract(contract:TAdContract)
		Self.contract		= contract
		'targetgroup is between 0-9
		Self.InitAssets(GetAssetName(contract.GetLimitedToTargetGroup(), False), GetAssetName(contract.GetLimitedToTargetGroup(), True))

		Return Self
	End Method


	Method GetAssetName:String(targetGroup:Int=-1, dragged:Int=False)
		If targetGroup < 0 And contract Then targetGroup = contract.GetLimitedToTargetGroup()
		Local result:String = "gfx_contracts_" + Min(9,Max(0, TVTTargetGroup.GetIndexes(targetGroup)[0]))
		If dragged Then result = result + "_dragged"
		Return result
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'disable dragging if not signable
		If contract.owner <= 0
			If Not contract.IsAvailableToSign(GetPlayerBase().playerID)
				SetOption(GUI_OBJECT_DRAGABLE, False)
			Else
				SetOption(GUI_OBJECT_DRAGABLE, True)
			EndIf
		EndIf


		'set mouse to "hover"
		If contract.owner = GetPlayerBase().playerID Or contract.owner <= 0 And isHovered()
			GetGameBase().cursorstate = 1
		EndIf

		'set mouse to "dragged"
		If isDragged()
			GetGameBase().cursorstate = 2
		EndIf
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30, forceAlign:int = -1)
		Local sheetY:Int = 20
		Local sheetX:Int = leftX
		Local sheetAlign:Int= 0
		'if mouse on left side of screen - align sheet on right side
		'METHOD 1
		'instead of using the half screen width, we use another
		'value to remove "flipping" when hovering over the desk-list
		'if MouseManager.x < RoomHandler_AdAgency.suitcasePos.GetX()
		'METHOD 2
		'just use the half of a screen - ensures the data sheet does not overlap
		'the object
		If forceAlign <> -1
			sheetAlign = forceAlign
		elseIf MouseManager.x < GameConfig.nonInterfaceRect.GetXCenter()
			sheetAlign = 1
		EndIf

		if sheetAlign = 1
			sheetX = GameConfig.nonInterfaceRect.GetX2() - rightX
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		local pointA:TVec2D = new TVec2D.Init(GetScreenX() + 0.5 * GetScreenWidth(), GetScreenY() + 0.25 * GetScreenHeight())
		local pointB:TVec2D = new TVec2D.Init(sheetX + (sheetAlign=0)*100 - (sheetalign=1)*100, sheetY + 75)
		local pointC:TVec2D = pointB.Copy().RotateAroundPoint(pointA, 5)
		'this centers the middle of BC
		pointB.RotateAroundPoint(pointA, -4)
		Local tri:Float[]=[pointB.x,pointB.y, pointA.x,pointA.y, pointC.x,pointC.y]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		local forPlayerID:int = GetObservedPlayerID()
		if self.contract.IsSigned() then forPlayerID = self.contract.owner

		Self.contract.ShowSheet(sheetX,sheetY, sheetAlign, TVTBroadcastMaterialType.ADVERTISEMENT, forPlayerID)
	End Method


	Method Draw()
		SetColor 255,255,255
		Local oldCol:TColor = New TColor.Get()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If contract.owner = GetObservedPlayerID()
				SetAlpha 0.80*oldCol.a
				SetColor 200,200,200
			Else
				SetAlpha 0.70*oldCol.a
'				SetColor 250,200,150
			EndIf
		EndIf

		'mark special vendor-contracts
		If contract.owner <> GetObservedPlayerID()
			if contract.GetDaysToFinish() <= 1
				SetColor 255,230,215
			endif
		Endif

		Super.Draw()

		oldCol.SetRGBA()
	End Method
End Type




Type TGUIAdContractSlotList Extends TGUIGameSlotList

    Method Create:TGUIAdContractSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsContract:Int(contract:TAdContract)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGuiAdContract = TGuiAdContract( Self.GetItemBySlot(i) )
			If block And block.contract = contract Then Return True
		Next
		Return False
	End Method
End Type
