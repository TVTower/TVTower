SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "common.misc.gamegui.bmx"
Import "game.roomhandler.base.bmx"
Import "game.player.programmecollection.bmx"
Import "game.broadcast.dailybroadcaststatistic.bmx"


'Ad agency
Type RoomHandler_AdAgency Extends TRoomHandler
	Global hoveredGuiAdContract:TGuiAdContract = Null
	Global draggedGuiAdContract:TGuiAdContract = Null

	Global VendorEntity:TSpriteEntity
	'allows registration of drop-event
	Global VendorArea:TGUISimpleRect

	'arrays holding the different blocks
	'we use arrays to find "free slots" and set to a specific slot
	Field listNormal:TAdContract[]
	Field listCheap:TAdContract[]
	Field listAll:TList {nosave}
	Field levelFilters:TAdContractBaseFilter[3]

	'cache to check if changes are processed yet
	Field _setRefillMode:Int = 0 {nosave}
	Field refillData:SAdContractRefillData = Null {nosave}

	'graphical lists for interaction with blocks
	Global haveToRefreshGuiElements:Int = True
	Global GuiListNormal:TGUIAdContractSlotList[]
	Global GuiListCheap:TGUIAdContractSlotList = Null
	Global GuiListSuitcase:TGUIAdContractSlotList = Null

	'sorting
	Global ListSortMode:Int = 0
	Global ListSortVisible:Int = False
	Global contractsSortKeys:Int[] = [0,1]
	Global contractsSortKeysTooltips:TTooltipBase[3]
	Global contractsSortSymbols:String[] = ["gfx_datasheet_icon_minAudience", "gfx_datasheet_icon_money"]

	Global LS_adagency:TLowerString = TLowerString.Create("adagency")

	'configuration
	Global suitcasePos:SVec2I = New SVec2I(520,100)
	Global suitcaseGuiListDisplace:SVec2I = New SVec2I(14,32)
	Global contractsPerLine:Int	= 4
	Global contractsNormalAmount:Int = 12
	Global contractsCheapAmount:Int	= 4

	Global _instance:RoomHandler_AdAgency
	Global _eventListeners:TEventListenerBase[]

	Const SORT_BY_MINAUDIENCE:Int = 0
	Const SORT_BY_PROFIT:Int = 1
	Const SORT_BY_CLASSIFICATION:Int = 2


	Function GetInstance:RoomHandler_AdAgency()
		If Not _instance Then _instance = New RoomHandler_AdAgency
		Return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()

		contractsPerLine:Int = 4
		contractsNormalAmount = 12
		contractsCheapAmount = 4
		listNormal = New TAdContract[contractsNormalAmount]
		listCheap = New TAdContract[contractsCheapAmount]

		Select GameRules.adagencySortContractsBy
			Case "minaudience"
				ListSortMode = SORT_BY_MINAUDIENCE
			Case "classification"
				ListSortMode = SORT_BY_CLASSIFICATION
			Case "profit"
				ListSortMode = SORT_BY_PROFIT
			Default
				ListSortMode = SORT_BY_MINAUDIENCE
		End Select

		VendorEntity = GetSpriteEntityFromRegistry("entity_adagency_vendor")


		For Local i:Int = 0 Until contractsSortKeysTooltips.length
			Select i
				Case SORT_BY_CLASSIFICATION
					contractsSortKeysTooltips[i] = New TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("CLASSIFICATION")), New TRectangle.Init(0,0,-1,-1))
				Case SORT_BY_PROFIT
					contractsSortKeysTooltips[i] = New TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("AD_PROFIT")), New TRectangle.Init(0,0,-1,-1))
				Case SORT_BY_MINAUDIENCE
					contractsSortKeysTooltips[i] = New TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("MIN_AUDIENCE")), New TRectangle.Init(0,0,-1,-1))
				Default
					contractsSortKeysTooltips[i] = New TGUITooltipBase.Initialize("", "UNKNOWN SORT MODE: " + i, New TRectangle.Init(0,0,-1,-1))
			End Select
			contractsSortKeysTooltips[i].parentArea = New TRectangle.Init(0,0,30,30)
			'contractsSortKeysTooltips[i]._minTitleDim = null
			'contractsSortKeysTooltips[i]._minContentDim = null
		Next


		'set to new mode defined in the rules
		SetRefillMode( GameRules.adagencyRefillMode )


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		If Not GuiListSuitcase
			GuiListNormal = GuiListNormal[..3]
			For Local i:Int = 0 To GuiListNormal.length-1
				Local listIndex:Int = GuiListNormal.length-1 - i
				GuiListNormal[listIndex] = New TGUIAdContractSlotList.Create(New SVec2I(418 - i*80, 122 + i*36), New SVec2I(200, 140), "adagency")
				GuiListNormal[listIndex].SetOrientation( GUI_OBJECT_ORIENTATION_HORIZONTAL )
				GuiListNormal[listIndex].SetItemLimit( contractsNormalAmount / GuiListNormal.length  )
				GuiListNormal[listIndex].SetSize(GetSpriteFromRegistry("gfx_contracts_0").area.GetW() * (contractsNormalAmount / GuiListNormal.length), GetSpriteFromRegistry("gfx_contracts_0").area.GetH() )
				GuiListNormal[listIndex].SetSlotMinDimension(GetSpriteFromRegistry("gfx_contracts_0").area.GetW(), GetSpriteFromRegistry("gfx_contracts_0").area.GetH())
				GuiListNormal[listIndex].SetAcceptDrop("TGuiAdContract")
				GuiListNormal[listIndex].setZindex(i)

				GuiListNormal[listIndex].SetSize(-1, GuiListNormal[listIndex].rect.GetH() + 30) 'for 4x displacement
				GuiListNormal[listIndex].SetEntriesBlockDisplacement(0, 0) 'displace by 20
				GuiListNormal[listIndex].Move(0, 20)
				GuiListNormal[listIndex].SetEntryDisplacement( 0, 10)

			Next

			GuiListSuitcase	= New TGUIAdContractSlotList.Create(New SVec2I(suitcasePos.x + suitcaseGuiListDisplace.x, suitcasePos.y + suitcaseGuiListDisplace.y), New SVec2I(255, Int(GetSpriteFromRegistry("gfx_contracts_0_dragged").area.h)), "adagency")
			GuiListSuitcase.SetAutofillSlots(True)

			GuiListCheap = New TGUIAdContractSlotList.Create(New SVec2I(70, 220), New SVec2I(5 + Int(GetSpriteFromRegistry("gfx_contracts_0").area.w*4), Int(GetSpriteFromRegistry("gfx_contracts_0").area.h)), "adagency")

			GuiListCheap.Move(0, -20)
			GuiListCheap.SetSize(-1, GuiListCheap.rect.GetH() + 20) 'for 4x displacement
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
			Local vendorAreaDimension:SVec2I = New SVec2I(150,200)
			Local vendorAreaPosition:SVec2I = New SVec2I(241,110)
			If VendorEntity Then vendorAreaDimension = New SVec2I(Int(VendorEntity.area.w), Int(VendorEntity.area.h))
			If VendorEntity Then vendorAreaPosition = New SVec2I(Int(VendorEntity.area.x), Int(VendorEntity.area.y))

			VendorArea = New TGUISimpleRect.Create(vendorAreaPosition, vendorAreaDimension, "adagency" )
			'vendor should accept drop - else no recognition
			VendorArea.setOption(GUI_OBJECT_ACCEPTS_DROP, True)
			VendorArea.zIndex = 0
		EndIf


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		'to react on changes in the programmeCollection (eg. contract finished)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddAdContract, onChangeProgrammeCollection) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveAdContract, onChangeProgrammeCollection) ]
		'update quote statistics for refill; on day start and on game begins (new/load)
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnDay, onDay) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Game_OnStart, onDay) ]

		'instead of "guiobject.onDropOnTarget" the event "guiobject.onDropOnTargetAccepted"
		'is only emitted if the drop is successful (so it "visually" happened)
		'drop ... to vendor or suitcase
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrop, onDropContract, "TGuiAdContract" ) ]
		'drop on vendor - sell things
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrop, onDropContractOnVendor, "TGuiAdContract" ) ]
		'dropping an contract on another can lead to a "replacement"
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUISlotList_OnReplaceSlotItem, onReplaceContract, "TGUIAdContractSlotList" ) ]
		'we want to know if we hover a specific block - to show a datasheet
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverContract, "TGuiAdContract" ) ]


		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		If GuiListSuitcase Then RemoveAllGuiElements()

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:Int()
		If GetInstance() <> Self Then Self.CleanUp()
		GetRoomHandlerCollection().SetHandler("adagency", GetInstance())
	End Method


	Method AbortScreenActions:Int()
		Local abortedAction:Int = False

		If draggedGuiAdContract
			'try to drop the licence back
			draggedGuiAdContract.dropBackToOrigin()
			draggedGuiAdContract = Null
			hoveredGuiAdContract = Null
			abortedAction = True
		EndIf

		'remove and recreate all (so they get the correct visual style)
		'do not use that - it reorders elements and changes the position
		'of empty slots ... maybe unwanted
		'GetInstance().RemoveAllGuiElements()
		'GetInstance().RefreshGuiElements()


		'change look to "stand on table look"
		For Local i:Int = 0 To GuiListNormal.length-1
			For Local obj:TGUIAdContract = EachIn GuiListNormal[i]._slots
				obj.InitAssets(obj.getAssetName(-1, False), obj.getAssetName(-1, True))
			Next
		Next
		For Local obj:TGUIAdContract = EachIn GuiListCheap._slots
			obj.InitAssets(obj.getAssetName(-1, False), obj.getAssetName(-1, True))
		Next

		Return abortedAction
	End Method




	Method onSaveGameBeginLoad:Int( triggerEvent:TEventBase )
		'as soon as a savegame gets loaded, we remove every
		'guiElement this room manages
		'Afterwards we force the room to update the gui elements
		'during next update.
		'Not RefreshGUIElements() in this function as the
		'new contracts are not loaded yet

		'We cannot rely on "onEnterRoom" as we could have saved
		'in this room
		GetInstance().RemoveAllGuiElements()

		haveToRefreshGuiElements = True
	End Method


	'run AFTER the savegame data got loaded
	'handle faulty adcontracts (after data got loaded)
	Method onSaveGameLoad:Int( triggerEvent:TEventBase )
		'in the case of being empty (should not happen)
		GetInstance().RefillBlocks()
	End Method


	Method onEnterRoom:Int( triggerEvent:TEventBase )
		Local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		'only interested in player figures (they cannot be in one room
		'simultaneously, others like postman should not refill while you
		'are in)
		If Not figure Or Not figure.playerID Then Return False

		'=== FOR ALL PLAYERS ===
		'
		'refill the empty blocks, also sets haveToRefreshGuiElements=true
		'so next call the gui elements will be redone
		ReFillBlocks()


		'=== FOR WATCHED PLAYERS ===
		If IsObservedFigure(figure)
			'reorder AFTER refilling
			ResetContractOrder()
		EndIf
	End Method


	'override
	Method onTryLeaveRoom:Int( triggerEvent:TEventBase )
		'non players can always leave
		Local figure:TFigure = TFigure(triggerEvent.GetSender())
		If Not figure Or Not figure.playerID Then Return False

		'do not allow leaving as long as we have a dragged block
		If draggedGuiAdContract
			triggerEvent.setVeto()
			Return False
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
		'sign all new contracts
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(figure.playerID)
		For Local contract:TAdContract = EachIn programmeCollection.suitcaseAdContracts
			'adds a contract to the players collection (gets signed THERE)
			'if successful, this also removes the contract from the suitcase
			programmeCollection.AddAdContract(contract)
		Next


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
		'instead of leaving the room and accidentially adding contracts
		'we delete all unsigned contracts from the list
		GetPlayerProgrammeCollection(figure.playerID).suitcaseAdContracts.Clear()


		'=== FOR WATCHED PLAYERS ===
		If IsObservedFigure(figure)
			AbortScreenActions()
		EndIf

		Return True
	End Method


	'===================================
	'AD Agency: common TFunctions
	'===================================

	Method GetContractsInStock:TList()
		If Not listAll
			listAll = CreateList()
			Local lists:TAdContract[][] = [listNormal,listCheap]
			For Local j:Int = 0 To lists.length-1
				For Local contract:TAdContract = EachIn lists[j]
					If contract Then listAll.AddLast(contract)
				Next
			Next
		EndIf
		Return listAll
	End Method


	Method GetContractsInStockCount:Int()
		Return GetContractsInStock().Count()
		Rem
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


	Method GetContractByPosition:TAdContract(position:Int)
		If position > GetContractsInStockCount() Then Return Null
		Local currentPosition:Int = 0
		Local lists:TAdContract[][] = [listNormal,listCheap]
		For Local j:Int = 0 To lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				If contract
					If currentPosition = position Then Return contract
					currentPosition:+1
				EndIf
			Next
		Next
		Return Null
	End Method


	Method HasContract:Int(contract:TAdContract)
		Return GetContractsInStock().Contains(contract)
		Rem
		local lists:TAdContract[][] = [listNormal,listCheap]
		For local j:int = 0 to lists.length-1
			For Local cont:TAdContract = EachIn lists[j]
				if cont = contract then return TRUE
			Next
		Next
		return FALSE
		endrem
	End Method


	Method GetContractByID:TAdContract(contractID:Int)
		Local lists:TAdContract[][] = [listNormal,listCheap]
		For Local j:Int = 0 To lists.length-1
			For Local contract:TAdContract = EachIn lists[j]
				If contract And contract.id = contractID Then Return contract
			Next
		Next
		Return Null
	End Method


	Method GiveContractToPlayer:Int(contract:TAdContract, playerID:Int, Sign:Int=False)
		'alreay owning?
		If contract.owner = playerID Then Return False
		'does not satisfy eg. "channel image"
		If Not contract.IsAvailableToSign(playerID) Then Return False

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		If Not programmeCollection Then Return False

		'try to add to suitcase of player
		If Not Sign
			If Not programmeCollection.AddUnsignedAdContractToSuitcase(contract) Then Return False
		'we do not need the suitcase, direkt sign pls (eg. for AI)
		Else
			If Not programmeCollection.AddAdContract(contract) Then Return False
		EndIf

		'remove from agency's lists
		GetInstance().RemoveContract(contract)

		Return True
	End Method


	Method TakeContractFromPlayer:Int(contract:TAdContract, playerID:Int)
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(playerID)
		If Not programmeCollection Then Return False

		If programmeCollection.RemoveUnsignedAdContractFromSuitcase(contract)
			'add to agency's lists - if not existing yet
			If Not HasContract(contract)
				If Not AddContract(contract)
					'if adding failed, remove the contract from the game
					'at all!
					GetAdContractCollection().Remove(contract)
				EndIf
			EndIf
			Return True
		Else
			Return False
		EndIf
	End Method


	Function isCheapContract:Int(contract:TAdContract)
		Return contract.adAgencyClassification < 0
	End Function


	Method SetRefillMode(mode:Int)
		_setRefillMode = mode
	End Method


	Method SortContracts(list:TList, mode:Int = -1)
		If Not list Then Return

		If mode = -1 Then mode = ListSortMode

		Select ListSortMode
			Case SORT_BY_CLASSIFICATION
				list.sort(True, TAdContract.SortByClassification)
			Case SORT_BY_PROFIT
				list.sort(True, TAdContract.SortByProfit)
			Case SORT_BY_MINAUDIENCE
				list.sort(True, TAdContract.SortByMinAudienceRelative)
			Default
				list.sort(True, TAdContract.SortByMinAudienceRelative)
		End Select
	End Method


	Method ResetContractOrder:Int()
		Local contracts:TList = CreateList()
		For Local contract:TAdContract = EachIn listNormal
			'only add valid contracts
			If contract.base Then contracts.addLast(contract)
		Next
		For Local contract:TAdContract = EachIn listCheap
			'only add valid contracts
			If contract.base Then contracts.addLast(contract)
		Next
		listNormal = New TAdContract[listNormal.length]
		listCheap = New TAdContract[listCheap.length]
		listAll = Null

		SortContracts(contracts, ListSortMode)

		'add again - so it gets sorted
		For Local contract:TAdContract = EachIn contracts
			AddContract(contract)
		Next

		RemoveAllGuiElements()
	End Method


	Method RemoveContract:Int(contract:TAdContract)
		If GetContractsInStockCount() = 0 Then Return False

		Local foundContract:Int = False
		'remove from agency's lists
		Local lists:TAdContract[][] = [listNormal,listCheap]
		For Local j:Int = 0 To lists.length-1
			For Local i:Int = 0 To lists[j].length-1
				If lists[j][i] = contract
					lists[j][i] = Null
					listAll.Remove(contract)

					'emit event
					TriggerBaseEvent(GameEventKeys.Adagency_RemoveAdContract, New TData.add("adcontract", contract), Self)

					foundContract = True
				EndIf
			Next
		Next

		Return foundContract
	End Method


	Method AddContract:Int(contract:TAdContract)
		'skip if done already
		If HasContract(contract) Then Return False

		'try to fill the program into the corresponding list
		'we use multiple lists - if the first is full, try second
		Local lists:TAdContract[][]

		If isCheapContract(contract)
			lists = [listCheap,listNormal]
		Else
			lists = [listNormal,listCheap]
		EndIf

		'create list if needed
		GetContractsInStock()

		'loop through all lists - as soon as we find a spot
		'to place the programme - do so and return
		For Local j:Int = 0 To lists.length-1
			For Local i:Int = 0 To lists[j].length-1
				If lists[j][i] Then Continue
				contract.SetOwner(contract.OWNER_VENDOR)
				lists[j][i] = contract
				listAll.Addlast(contract)
				'emit event
				TriggerBaseEvent(GameEventKeys.Adagency_AddAdContract, New TData.add("adcontract", contract), Self)

				Return True
			Next
		Next

		'there was no empty slot to place that programme
		'so just give it back to the pool
		contract.SetOwner(contract.OWNER_NOBODY)

		Return False
	End Method


	Method RemoveRandomContracts:Int(removeChance:Float = 1.0)
		Local toRemove:TAdContract[]
		For Local c:TAdContract = EachIn GetContractsInStock()
			'delete an old contract by a chance of 50%
			If RandRange(0,100) < removeChance*100
				toRemove :+ [c]
			EndIf
		Next

		For Local c:TAdContract = EachIn toRemove
			'remove from game! - else the contracts stay
			'there forever!
			GetAdContractCollection().Remove(c)

			'unlink from the lists
			RemoveContract(c)

			'let the contract cleanup too
			c.Remove()
		Next

		Return toRemove.length
	End Method


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:Int()
		For Local i:Int = 0 To GuiListNormal.length-1
			GuiListNormal[i].EmptyList()
		Next
		GuiListCheap.EmptyList()
		GuiListSuitcase.EmptyList()
		For Local guiAdContract:TGuiAdContract = EachIn GuiManager.listDragged.Copy()
			guiAdContract.remove()
			guiAdContract = Null
		Next

		hoveredGuiAdContract = Null
		draggedGuiAdContract = Null

		'to recreate everything during next update...
		haveToRefreshGuiElements = True
	End Function


	Method RefreshGuiElements:Int()
		'===== REMOVE UNUSED =====
		'remove gui elements with contracts the player does not have any longer

		'suitcase
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(GetPlayerBase().playerID)
		For Local guiAdContract:TGuiAdContract = EachIn GuiListSuitcase._slots
			'if the player has this contract in suitcase or list, skip deletion
			If programmeCollection.HasAdContract(guiAdContract.contract) Then Continue
			If programmeCollection.HasUnsignedAdContractInSuitcase(guiAdContract.contract) Then Continue

			'print "guiListSuitcase has obsolete contract: "+guiAdContract.contract.id
			guiAdContract.remove()
			guiAdContract = Null
		Next
		'agency lists
		For Local i:Int = 0 To GuiListNormal.length-1
			For Local guiAdContract:TGuiAdContract = EachIn GuiListNormal[i]._slots
				'if not HasContract(guiAdContract.contract) then print "REM guiListNormal"+i+" has obsolete contract: "+guiAdContract.contract.id
				If Not HasContract(guiAdContract.contract)
					guiAdContract.remove()
					guiAdContract = Null
				EndIf
			Next
		Next
		For Local guiAdContract:TGuiAdContract = EachIn GuiListCheap._slots
			'if not HasContract(guiAdContract.contract) then	print "REM guiListCheap has obsolete contract: "+guiAdContract.contract.id
			If Not HasContract(guiAdContract.contract)
				guiAdContract.remove()
				guiAdContract = Null
			EndIf
		Next


		'===== CREATE NEW =====
		'create missing gui elements for all contract-lists

		'normal list
		For Local contract:TAdContract = EachIn listNormal
			If Not contract Then Continue
			Local contractAdded:Int = False

			'search the contract in all of our lists...
			Local contractFound:Int = False
			For Local i:Int = 0 To GuiListNormal.length-1
				If contractFound Then Continue
				If GuiListNormal[i].ContainsContract(contract) Then contractFound=True
			Next

			'try to fill in one of the normalList-Parts
			If Not contractFound
				For Local i:Int = 0 To GuiListNormal.length-1
					If contractAdded Then Continue
					If GuiListNormal[i].ContainsContract(contract) Then contractAdded=True;Continue
					If GuiListNormal[i].getFreeSlot() < 0 Then Continue
					Local block:TGuiAdContract = New TGuiAdContract.CreateWithContract(contract)
					block._callbacks_onClick :+ [onClickAdContractCallback]
					'change look
					block.InitAssets(block.getAssetName(-1, False), block.getAssetName(-1, True))

					'print "ADD guiListNormal"+i+" missed new contract: "+block.contract.id

					GuiListNormal[i].addItem(block, "-1")
					contractAdded = True
				Next
				If Not contractAdded
					TLogger.Log("AdAgency.RefreshGuiElements", "contract exists but does not fit in GuiListNormal - contract removed.", LOG_ERROR)
					RemoveContract(contract)
				EndIf
			EndIf
		Next

		'cheap list
		For Local contract:TAdContract = EachIn listCheap
			If Not contract Then Continue
			If GuiListCheap.ContainsContract(contract) Then Continue
			Local block:TGuiAdContract = New TGuiAdContract.CreateWithContract(contract)
			block._callbacks_onClick :+ [onClickAdContractCallback]
			'change look
			block.InitAssets(block.getAssetName(-1, False), block.getAssetName(-1, True))

			'print "ADD guiListCheap missed new contract: "+block.contract.id

			GuiListCheap.addItem(block, "-1")
		Next

		'create missing gui elements for the players contracts
		SortContracts(programmeCollection.adContracts, ListSortMode)
		For Local contract:TAdContract = EachIn programmeCollection.adContracts
			If guiListSuitcase.ContainsContract(contract) Then Continue
			Local block:TGuiAdContract = New TGuiAdContract.CreateWithContract(contract)
			block._callbacks_onClick :+ [onClickAdContractCallback]
			'change look
			block.InitAssets(block.getAssetName(-1, True), block.getAssetName(-1, True))

			'print "ADD guiListSuitcase missed new (old) contract: "+block.contract.id

			block.setOption(GUI_OBJECT_DRAGABLE, False)
			guiListSuitcase.addItem(block, "-1")
		Next

		'create missing gui elements for the current suitcase
		For Local contract:TAdContract = EachIn programmeCollection.suitcaseAdContracts
			If guiListSuitcase.ContainsContract(contract) Then Continue
			Local block:TGuiAdContract = New TGuiAdContract.CreateWithContract(contract)
			block._callbacks_onClick :+ [onClickAdContractCallback]
			'change look
			block.InitAssets(block.getAssetName(-1, True), block.getAssetName(-1, True))

			'print "guiListSuitcase missed new contract: "+block.contract.id

			guiListSuitcase.addItem(block, "-1")
		Next
		haveToRefreshGuiElements = False
	End Method


	'refills slots in the ad agency
	'replaceOffer: remove (some) old contracts and place new there?
	Method ReFillBlocks:Int(replaceOffer:Int=False, replaceChance:Float=1.0)
		haveToRefreshGuiElements = True

		'reset list cache
		listAll = Null

		'delete some random ads
		If replaceOffer
			Local removed:Int = RemoveRandomContracts(replaceChance)
			TLogger.Log("AdAgency.RefillBlocks", "removed "+removed+" contracts", LOG_DEBUG)
		EndIf
		If _setRefillMode < 10 Then _setRefillMode = 10
		Select _setRefillMode
			Case 10
				If RandRange(1,100) > 65
					RefillBlocksMode1()
				Else
					RefillBlocksMode2()
				EndIf
			Case 11
				RefillBlocksMode1()
			Case 12
				RefillBlocksMode2()
			Default
				throw "invalid ad agency refill mode " + _setRefillMode
		EndSelect
	End Method


	Method RefillBlocksMode1()
		TLogger.Log("AdAgency.RefillBlocks", "RefillBlocks Mode 1.", LOG_DEBUG)

		Local d:SAdContractRefillData = refillData
		'=== SETUP FILTERS ===
		Local spotMin:Float = 0.0001 '0.01% to avoid 0.0-spots
		Local rangeStep:Float = 0.005 '0.5%
		Local limitInstances:Int = GameRules.adContractInstancesMax

		'the cheap list contains really low contracts
		Local cheapListFilter:TAdContractBaseFilter = New TAdContractbaseFilter
		'0.5% market share -> 1mio reach means 5.000 people!
		cheapListFilter.SetAudience(spotMin, Max(spotMin, 1.5 * d.lowestChannelQuoteDaytime))
		'no image requirements - or not much more than the lowest image
		'(so all could sign this)
		cheapListFilter.SetMinImageRange(0, 1.1 * d.lowestChannelImage)

		'cheap contracts should not limit genre
		cheapListFilter.SetSkipLimitedToProgrammeGenre()
		'cheapListFilter.SetSkipLimitedToTargetGroup()

		'the dev value is defining how many simultaneously are allowed
		'while the filter filters contracts already having that much (or
		'more) contracts, that's why we subtract 1
		If limitInstances > 0 Then cheapListFilter.SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		'the 12 contracts are divided into 3 groups
		'4x fitting the lowest requirements
		'4x fitting the average requirements
		'4x fitting the highest requirements
		For Local i:Int = 0 Until levelFilters.length
			If Not levelFilters[i] Then levelFilters[i] = New TAdContractBaseFilter
		Next
		'=== LOWEST ===
		levelFilters[0] = New TAdContractbaseFilter
		'from lowest to average day quote (Minimum of 0.01%)
		levelFilters[0].SetAudience(Max(spotMin, d.lowestChannelQuoteDaytime), Max(spotMin , d.averageChannelQuoteDayTime))
		'1% - avgImage %
		levelFilters[0].SetMinImageRange(0.0, d.lowestChannelImage)
		'lowest should be without "limits"
		levelFilters[0].SetSkipLimitedToProgrammeGenre()
		levelFilters[0].SetSkipLimitedToTargetGroup()
		If limitInstances > 0 Then levelFilters[0].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		'=== AVERAGE ===
		levelFilters[1] = New TAdContractbaseFilter
		'from 80% of avg to lowest prime/dayaverage, may cross with lowest and high
		levelFilters[1].SetAudience(Max(spotMin, 0.8 * d.averageChannelQuoteDayTime), Max(d.highestChannelQuoteDayTime, d.lowestChannelQuotePrimeTime))
		'0-100% of average Image
		levelFilters[1].SetMinImageRange(0, d.averageChannelImage)
		If limitInstances > 0 Then levelFilters[1].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

		'=== HIGH ===
		levelFilters[2] = New TAdContractbaseFilter
		'from 80% of highest day to 130% of highest prime
		levelFilters[2].SetAudience(Max(spotMin, 0.8 * d.highestChannelQuoteDayTime), 1.3 * Max(d.highestChannelQuoteDayTime, d.highestChannelQuotePrimeTime))
		'0-100% of highest Image
		levelFilters[2].SetMinImageRange(0, d.highestChannelImage)
		If limitInstances > 0 Then levelFilters[2].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)

'		TLogger.Log("AdAgency.RefillBlocks", "Refilling "+ GetWorldTime().GetFormattedTime() +". Filter details", LOG_DEBUG)

Rem
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
		Local classification:Int = -1
		Local lists:TAdContract[][] = [listNormal,listCheap]
		For Local j:Int = 0 To lists.length-1
			For Local i:Int = 0 To lists[j].length-1
				'if exists and is valid...skip it
				If lists[j][i] And lists[j][i].base Then Continue

				Local contract:TAdContract

				If lists[j] = listNormal
					Local filterNum:Int = 0
					Select Floor(i / 4)
						Case 2
							filterNum = 2
							classification = 2
						Case 1
							filterNum = 1
							classification = 1
						Case 0
							filterNum = 0
							classification = 0
					End Select

					'check if there is an adcontract base available for this filter
					Local contractBase:TAdContractBase = Null
					While Not contractBase
						contractBase = GetAdContractBaseCollection().GetRandomNormalByFilter(levelFilters[filterNum], False)
						'if not, then lower minimum and increase maximum audience
						If Not contractBase
							TLogger.Log("AdAgency.RefillBlocks", "Adjusting LevelFilter #"+filterNum+"  Min: " +MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMin,2)+"% ("+(100 * levelFilters[filterNum].minAudienceMin)+" - 0.5%   Max: "+ MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMax,2)+"% + 0.5%"  , LOG_DEBUG)
							levelFilters[filterNum].SetAudience( Max(0.0, levelFilters[filterNum].minAudienceMin - rangeStep), Min(1.0, levelFilters[filterNum].minAudienceMax + rangeStep))
						EndIf

						'absolutely nothing available?
						If Not contractBase And levelFilters[filterNum].minAudienceMin = 0.0 And levelFilters[filterNum].minAudienceMax = 1.0
							TLogger.Log("AdAgency.RefillBlocks", "FAILED to find new contract for LevelFilter #"+filterNum+"  Min: " +MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMin,2)+"%   Max: "+ MathHelper.NumberToString(100 * levelFilters[filterNum].minAudienceMax,2)+"%."  , LOG_DEBUG)
						EndIf
					Wend
					If contractBase
						contract = New TAdContract.Create( contractBase )
					EndIf
					'print "refilling ads with filternum="+filternum+"  classification="+classification
				EndIf

				'=== CHEAP LIST ===
				If lists[j] = listCheap
					'check if there is an adcontract base available for this filter
					Local contractBase:TAdContractBase = Null
					While Not contractBase
						contractBase = GetAdContractBaseCollection().GetRandomNormalByFilter(cheapListFilter, False)
						'if not, then lower minimum and increase maximum audience
						If Not contractBase
							TLogger.Log("AdAgency.RefillBlocks", "Adjusting CheapListFilter  Min: " +MathHelper.NumberToString(100 * cheapListFilter.minAudienceMin,2)+"% - 0.5%   Max: "+ MathHelper.NumberToString(100 * cheapListFilter.minAudienceMax,2)+"% + 0.5%"  , LOG_DEBUG)
							cheapListFilter.SetAudience( Max(0, cheapListFilter.minAudienceMin - rangeStep), Min(1.0, cheapListFilter.minAudienceMax + rangeStep))
						EndIf

						'absolutely nothing available?
						If Not contractBase And cheapListFilter.minAudienceMin = 0.0 And cheapListFilter.minAudienceMax = 1.0
							TLogger.Log("AdAgency.RefillBlocks", "FAILED to find new contract for CheapListFilter  Min: " +MathHelper.NumberToString(100 * cheapListFilter.minAudienceMin,2)+"%   Max: "+ MathHelper.NumberToString(100 * cheapListFilter.minAudienceMax,2)+"%."  , LOG_DEBUG)
						EndIf
					Wend
					If contractBase
						contract = New TAdContract.Create( contractBase )
					EndIf

					classification = -1
				EndIf


				If Not contract
					TLogger.Log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+i+". Using absolutely random one without limitations.", LOG_ERROR)
					'try again without filter - to avoid "empty room"
					contract = New TAdContract.Create( GetAdContractBaseCollection().GetRandom() )
				EndIf

				'add new contract to slot
				If contract
					'set classification so contract knows its "origin"
					contract.adAgencyClassification = classification
					contract.SetOwner(contract.OWNER_VENDOR)
					If GameRules.adContractRandomize Then contract.Randomize()

					GetContractsInStock().AddLast(contract)
					'add afterwards as "GetContractsInStock()" might create
					'a list already containing the lists[][]-content)
					lists[j][i] = contract

					'emit event
					TriggerBaseEvent(GameEventKeys.Adagency_AddAdContract, New TData.add("adcontract", contract), Self)
				EndIf
			Next
		Next

rem
		'now all filters contain "valid ranges"
		TLogger.Log("AdAgency.RefillBlocks", "    Cheap filter: "+cheapListFilter.ToString(), LOG_DEBUG)

		For Local i:Int = 0 Until 3
			TLogger.Log("AdAgency.RefillBlocks", "  Level "+i+" filter: "+levelFilters[i].ToString(), LOG_DEBUG)
		Next
endrem
	End Method


	'reduced mode - separate only cheap and non-cheap contracts
	Method RefillBlocksMode2()
		TLogger.Log("AdAgency.RefillBlocks", "RefillBlocks Mode 2.", LOG_DEBUG)

		Local d:SAdContractRefillData = refillData

		'=== OTHER BASIC INFORMATION ===
		Local limitInstances:Int = GameRules.adContractInstancesMax
		Local rangeStep:Float = 0.005 '0.5%

		'=== CHEAP LIST ===
		'the cheap list contains really low contracts
		Local cheapListFilter:TAdContractBaseFilter = New TAdContractbaseFilter
		'0.5% market share -> 1mio reach means 5.000 people!
		cheapListFilter.SetAudience(0.0005, 0.005)
		'no image requirements much higher than lowest (so all could sign this)
		cheapListFilter.SetMinImageRange(0, 1.1 * d.lowestChannelImage)

		'cheap contracts should not limit genre
		cheapListFilter.SetSkipLimitedToProgrammeGenre()
		'cheapListFilter.SetSkipLimitedToTargetGroup()

		'the dev value is defining how many simultaneously are allowed
		'while the filter filters contracts already having that much (or
		'more) contracts, that's why we subtract 1
		If limitInstances > 0 Then cheapListFilter.SetCurrentlyUsedByContractsLimit(0, limitInstances-1)


		'=== NON-CHEAP ===
		levelFilters[0] = New TAdContractbaseFilter
		'from 0,51% to 120% of best audience of that day
		levelFilters[0].SetAudience(0.0051, 1.2 * d.highestChannelQuotePrimeTime)
		'1% - avgImage %
		levelFilters[0].SetMinImageRange(0.0, 1.2 * d.highestChannelImage)
		If limitInstances > 0 Then levelFilters[0].SetCurrentlyUsedByContractsLimit(0, limitInstances-1)




		'=== FILL EMPTY SLOTS ===
		'=== ACTUALLY CREATE CONTRACTS ===
		Local classification:Int = -1
		Local lists:TAdContract[][] = [listNormal,listCheap]
		For Local j:Int = 0 To lists.length-1
			For Local i:Int = 0 To lists[j].length-1
				'if exists and is valid...skip it
				If lists[j][i] And lists[j][i].base Then Continue

				Local contract:TAdContract
				Local filter:TAdContractBaseFilter
				Local filterName:String = "unknown"

				If lists[j] = listNormal
					filter = levelFilters[0]
					classification = 0
					filterName="LevelFilter #0"
				Else
					filter = cheapListFilter
					classification = -1
					filterName="CheapListFilter"
				EndIf

				'check if there is an adcontract base available for this filter
				Local contractBase:TAdContractBase = Null
				While Not contractBase
					contractBase = GetAdContractBaseCollection().GetRandomNormalByFilter(filter, False)
					'if not, then lower minimum and increase maximum audience
					If Not contractBase
						TLogger.Log("AdAgency.RefillBlocks", "Adjusting "+filterName+"  Min: " +MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"% ("+(100 * filter.minAudienceMin)+" - 0.5%   Max: "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"% + 0.5%"  , LOG_DEBUG)
						filter.SetAudience( Max(0.0, filter.minAudienceMin - rangeStep), Min(1.0, filter.minAudienceMax + rangeStep))
					EndIf

					'absolutely nothing available?
					If Not contractBase And filter.minAudienceMin = 0.0 And filter.minAudienceMax = 1.0
						TLogger.Log("AdAgency.RefillBlocks", "FAILED to find new contract for "+filterName+"  Min: " +MathHelper.NumberToString(100 * filter.minAudienceMin,2)+"%   Max: "+ MathHelper.NumberToString(100 * filter.minAudienceMax,2)+"%."  , LOG_DEBUG)
					EndIf
				Wend
				If contractBase
					contract = New TAdContract.Create( contractBase )
				EndIf

				If Not contract
					TLogger.Log("AdAgency.ReFillBlocks", "Not enough contracts to fill ad agency in list "+j+". Using absolutely random one without limitations.", LOG_ERROR)
					'try again without filter - to avoid "empty room"
					contract = New TAdContract.Create( GetAdContractBaseCollection().GetRandom() )
				EndIf

				'add new contract to slot
				If contract
					'set classification so contract knows its "origin"
					contract.adAgencyClassification = classification
					If GameRules.adContractRandomize Then contract.Randomize()

					contract.SetOwner(contract.OWNER_VENDOR)
					GetContractsInStock().AddLast(contract)
					'add afterwards as "GetContractsInStock()" might create
					'a list already containing the lists[][]-content)
					lists[j][i] = contract

					'emit event
					TriggerBaseEvent(GameEventKeys.Adagency_AddAdContract, New TData.add("adcontract", contract), Self)
				EndIf
			Next
		Next
rem
		'now all filters contain "valid ranges"
		TLogger.Log("AdAgency.RefillBlocks", "    Cheap filter: "+cheapListFilter.ToString(), LOG_DEBUG)
		TLogger.Log("AdAgency.RefillBlocks", "  Level 0 filter: "+levelFilters[0].ToString(), LOG_DEBUG)
endrem
	End Method



	'===================================
	'Ad Agency: Room screen
	'===================================

	Function onDay:Int( triggerEvent:TEventBase )
		Local instance:RoomHandler_AdAgency = RoomHandler_AdAgency.GetInstance()
		instance.refillData.update()
		Return True
	End Function

	'if players are in the agency during changes
	'to their programme collection, react to...
	Function onChangeProgrammeCollection:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("adagency") Then Return False

		GetInstance().haveToRefreshGuiElements = True
		'GetInstance().RefreshGuiElements()
	End Function


	'in case of right mouse button click a dragged contract is
	'placed at its original spot again
	Function onClickAdContractCallback:Int(sender:TGUIObject, mouseButton:Int, x:Int, y:Int)
		'only react if the click came from the right mouse button
		If mouseButton <> 2 Then Return False

		Local guiAdContract:TGuiAdContract= TGUIAdContract(sender)
		'ignore wrong types and NON-dragged items
		If Not guiAdContract Or Not guiAdContract.isDragged() Then Return False

		'remove gui object
		guiAdContract.remove()
		guiAdContract = Null

		'rebuild at correct spot
		haveToRefreshGuiElements = True

		'avoid clicks
		'remove right click - to avoid leaving the room
		MouseManager.SetClickHandled(2)
	End Function


	Function onMouseOverContract:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("adagency") Then Return False

		Local item:TGuiAdContract = TGuiAdContract(triggerEvent.GetSender())
		If item = Null Then Return False

		hoveredGuiAdContract = item
		If item.isDragged() Then draggedGuiAdContract = item

		Return True
	End Function


	'handle cover block drops on the vendor ... only sell if from the player
	Function onDropContractOnVendor:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("adagency") Then Return False

		Local guiBlock:TGuiAdContract = TGuiAdContract( triggerEvent._sender )
		Local receiver:TGUIobject = TGUIObject(triggerEvent._receiver)
		If Not guiBlock Or Not receiver Or receiver <> VendorArea Then Return False

		Local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(TGUIListBase.FindGUIListBaseParent(guiBlock._parent))
		If Not senderList Then Return False

		'if coming from suitcase, try to remove it from the player
		If senderList = GuiListSuitcase
			If Not GetInstance().TakeContractFromPlayer(guiBlock.contract, GetPlayerBase().playerID )
				triggerEvent.setVeto()
				Return False
			EndIf
		Else
			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiBlock.contract)
			GetInstance().AddContract(guiBlock.contract)
		EndIf
		'remove the block, will get recreated if needed
		guiBlock.remove()
		guiBlock = Null

		'something changed...refresh missing/obsolete...
		haveToRefreshGuiElements = True

		Return True
	End Function


	Function onReplaceContract:int( triggerEvent:TEventBase )
		'as soon as dropping a contract on a "full" suitcase, we remove 
		'the "dragged" from the players suitcase
		'- One can only drag "unsigned" contracts from the suitcase
		'- contracts are only "unsigned" if taken from the agency this visit
		'- so for any "unsigned" contract there must be a free slot in the
		'  agency (desk)

		If Not CheckObservedFigureInRoom("adagency") Then Return False

		Local senderList:TGUIAdContractSlotList = TGUIAdContractSlotList(triggerEvent._sender)
		If Not senderList Then Return False

		Local droppedGuiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent.GetData().Get("source"))
		Local draggedGuiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent.GetData().Get("target"))
		
		'dropping a contract from the vendor to the suitcase 
		'(on an already occupied slot)
		If senderlist = GuiListSuitcase and droppedGuiAdContract.contract.IsOwnedByVendor()
			'remove replaced/dragged contract from player
			Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(GetObservedPlayerID())
			programmeCollection.RemoveUnsignedAdContractFromSuitcase(draggedGuiAdContract.contract)
			'remove replacing/dropped contract from vendor
			GetInstance().RemoveContract(droppedGuiAdContract.contract)
			'print "  -> removed dragged contract from player suitcase, removed dropped contract from vendor"

			'add replacing/dropped contract to player
			programmeCollection.AddUnsignedAdContractToSuitcase(droppedGuiAdContract.contract)
			'add replaced/dragged contract to vendor
			GetInstance().AddContract(draggedGuiAdContract.contract)
			'print "  -> added dropped contract to player suitcase, added dragged contract to vendor"
		'ElseIf (senderlist = GuiListCheap or senderlist = GuiListNormal) and droppedGuiAdContract.contract.owner > 0
			'replacement on vendor lists does not need special handling as
			'we do not want to automatically place the "replacement" in the
			'players suitcase
		EndIf
	End Function


	'in this stage, the item is already added to the new gui list
	'we now just add or remove it to the player or vendor's list
	Function onDropContract:Int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("adagency") Then Return False

		Local guiAdContract:TGuiAdContract = TGuiAdContract(triggerEvent._sender)
		Local receiverList:TGUIAdContractSlotList = TGUIAdContractSlotList(triggerEvent._receiver)
		If Not guiAdContract Or Not receiverList Then Return False

		'get current owner of the contract, as the field "owner" is set
		'during sign we cannot rely on it. So we check if the player has
		'the contract in the suitcaseContractList
		Local owner:Int = guiAdContract.contract.owner
		If owner <= 0 And GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasUnsignedAdContractInSuitcase( guiAdContract.contract )
			owner = GetPlayerBase().playerID
		EndIf

		'find out if we sell it to the vendor or drop it to our suitcase
		If receiverList <> GuiListSuitcase
			guiAdContract.InitAssets( guiAdContract.getAssetName(-1, False ), guiAdContract.getAssetName(-1, True ) )
			'no problem when dropping vendor programme to vendor..
			If owner <= 0 Then Return True

			If Not GetInstance().TakeContractFromPlayer(guiAdContract.contract, GetPlayerBase().playerID )
				triggerEvent.setVeto()
				Return False
			EndIf

			'remove and add again (so we drop automatically to the correct list)
			GetInstance().RemoveContract(guiAdContract.contract)
			GetInstance().AddContract(guiAdContract.contract)
		Else
			guiAdContract.InitAssets(guiAdContract.getAssetName(-1, True ), guiAdContract.getAssetName(-1, True ))
			'no problem when dropping own programme to suitcase..
			If owner = GetPlayerBase().playerID Then Return True

			If Not GetInstance().GiveContractToPlayer(guiAdContract.contract, GetPlayerBase().playerID)
				triggerEvent.setVeto()
				Return False
			EndIf
		EndIf

		Return True
	End Function


	Method onDrawRoom:Int( triggerEvent:TEventBase )
		'delete unused and create new gui elements
		If haveToRefreshGuiElements Then RefreshGUIElements()

		If VendorEntity Then VendorEntity.Render()
		GetSpriteFromRegistry("gfx_suitcase_big").Draw(suitcasePos.x, suitcasePos.y)

		'make suitcase/vendor highlighted if needed
		Local highlightSuitcase:Int = False
		Local highlightVendor:Int = False

		If draggedGuiAdContract
			If Not GetPlayerProgrammeCollection( GetPlayerBase().playerID ).HasUnsignedAdContractInSuitcase(draggedGuiAdContract.contract)
				highlightSuitcase = True
			EndIf
			highlightVendor = True
		EndIf

		If highlightVendor Or highlightSuitcase
			Local oldCol:TColor = New TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * Sin(Time.GetAppTimeGone() / 5))

			If VendorEntity And highlightVendor Then VendorEntity.Render()
			If highlightSuitcase Then GetSpriteFromRegistry("gfx_suitcase_big").Draw(suitcasePos.x, suitcasePos.y)

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		EndIf


		Local availableSortKeys:Int[]
		If Not ListSortVisible
			availableSortKeys :+ [ListSortMode]
		Else
			availableSortKeys :+ contractsSortKeys
		EndIf

		Local skin:TDatasheetSkin = GetDatasheetSkin("default")
		Local boxWidth:Int = 28 + availableSortKeys.length * 38
		Local boxHeight:Int = 35 + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		Local contentX:Int = 5 + skin.GetContentX()
		skin.RenderContent(contentX, 325 +skin.GetContentY(), skin.GetContentW(boxWidth), 42, "1_top")


		For Local i:Int = 0 Until availableSortKeys.length
			Local spriteName:String = "gfx_gui_button.datasheet"
			If ListSortMode = availableSortKeys[i]
				spriteName = "gfx_gui_button.datasheet.positive"
			EndIf

			If THelper.MouseIn(contentX + 5 + i*38, 342, 35, 27)
				spriteName :+ ".hover"
			EndIf
			GetSpriteFromRegistry(spriteName).DrawArea(contentX + 5 + i*38, 342, 35,27)
			GetSpriteFromRegistry(contractsSortSymbols[ availableSortKeys[i] ]).Draw(contentX + 10 + i*38, 344)
		Next

		GUIManager.Draw( LS_adagency )

		skin.RenderBorder(5, 330, boxWidth, boxHeight)

		'tooltips
		For Local i:Int = 0 Until availableSortKeys.length
			If contractsSortKeysTooltips[availableSortKeys[i]]
				contractsSortKeysTooltips[availableSortKeys[i]].Render()
			EndIf
		Next


		If hoveredGuiAdContract

			'draw the current sheet
			If hoveredGuiAdContract.IsDragged()
				If MouseManager.x < GetGraphicsManager().GetWidth()/2
					hoveredGuiAdContract.DrawSheet(GetGraphicsManager().GetWidth() - 30, 20, 1.0)
				Else
					hoveredGuiAdContract.DrawSheet(30, 20, 0)
				EndIf

			Else
				'rem
				'MODE 1: trash contracts have right aligned sheets
				'        rest is left aligned
				If GuiListCheap.ContainsContract(hoveredGuiAdContract.contract)
					hoveredGuiAdContract.DrawSheet(GetGraphicsManager().GetWidth() - 30, 20, 1.0)
				Else
					hoveredGuiAdContract.DrawSheet(30, 20, 0)
				EndIf
				'endrem

				Rem
				'MODE 2: all contracts are left aligned
				'        ->problems with big datasheets for trash ads
				'          as they overlap the contracts then
				hoveredGuiAdContract.DrawSheet(,, 0)
				EndRem
			EndIf
		EndIf
	End Method


	Method onUpdateRoom:Int( triggerEvent:TEventBase )
		If VendorEntity Then VendorEntity.Update()

		ListSortVisible = False
		If Not draggedGuiAdContract
			'show and react to mouse-over-sort-buttons
			'HINT: does not work for touch displays
			Local skin:TDatasheetSkin = GetDatasheetSkin("default")
			Local boxWidth:Int = 28 + contractsSortKeys.Length * 38
			Local boxHeight:Int = 35 + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
			If THelper.MouseIn(5, 335, boxWidth, boxHeight)
				ListSortVisible = True

				If MouseManager.IsClicked(1)
					Local contentX:Int = 5 + skin.GetContentX()

					For Local i:Int = 0 To contractsSortKeys.length-1
						If THelper.MouseIn(contentX + i*38, 342, 35, 27)
							'sort now
							If ListSortMode <> contractsSortKeys[i]
								ListSortMode = contractsSortKeys[i]
								'this sorts the contract list and recreates
								'the gui
								ResetContractOrder()
							EndIf

							'handled left click
							MouseManager.SetClickHandled(1)

							exit
						EndIf
					Next
				EndIf
			EndIf

			'move tooltips
			Local contentX:Int = 5 + skin.GetContentX()
			For Local i:Int = 0 To contractsSortKeys.length-1
				If contractsSortKeysTooltips[contractsSortKeys[i]]
					contractsSortKeysTooltips[contractsSortKeys[i]].parentArea.SetXYWH(contentX + 5 + i*38, 342, 35,27)
				EndIf
			Next
		EndIf

		'update tooltips
		For Local i:Int = 0 To contractsSortKeys.length-1
			contractsSortKeysTooltips[contractsSortKeys[i]].Update()
		Next

		'delete unused and create new gui elements
		If haveToRefreshGuiElements Then RefreshGUIElements()

		'reset hovered block - will get set automatically on gui-update
		hoveredGuiAdContract = Null
		'reset dragged block too
		draggedGuiAdContract = Null

		GUIManager.Update( LS_adagency )
	End Method

End Type




'a graphical representation of contracts at the ad-agency ...
Type TGuiAdContract Extends TGUIGameListItem
	Field contract:TAdContract


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGuiAdContract(pos:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_contracts_0"
		Self.assetNameDragged = "gfx_contracts_0_dragged"

		Return Self
	End Method


	Method CreateWithContract:TGuiAdContract(contract:TAdContract)
		Self.Create(New SVec2I(0,0), New SVec2I(0,0))
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
	Method Update:Int() override
		Super.Update()

		'disable dragging if not signable
		If contract.owner <= 0
			If Not contract.IsAvailableToSign(GetPlayerBase().playerID)
				SetOption(GUI_OBJECT_DRAGABLE, False)
			Else
				SetOption(GUI_OBJECT_DRAGABLE, True)
			EndIf
		EndIf
	End Method


	Method DrawSheet(x:Int=30, y:Int=20, alignment:Float=0.5)
		local sheetWidth:int = 330
		local baseX:Int = int(x - alignment * sheetWidth)

		local oldA:Float = GetAlpha()
		local oldCol:SColor8
		GetColor(oldCol)
		SetColor 0,0,0
		SetAlpha 0.2 * oldA
		TFunctions.DrawBaseTargetRect(baseX + sheetWidth/2, ..
		                              y + 70, ..
		                              Self.GetScreenRect().GetX() + Self.GetScreenRect().GetW()/2.0, ..
		                              Self.GetScreenRect().GetY() + Self.GetScreenRect().GetH()/2.0, ..
		                              20, 3)
'		Local pointB:TVec2D = New TVec2D(sheetX + (sheetAlign=0)*100 - (sheetalign=1)*100, sheetY + 75)
		SetColor(oldCol)
		SetAlpha oldA

		Local forPlayerID:Int = GetObservedPlayerID()
		If Self.contract.IsSigned() Then forPlayerID = Self.contract.owner

		Self.contract.ShowSheet(x, y, alignment, TVTBroadcastMaterialType.ADVERTISEMENT, forPlayerID, GetBroadcastManager().GetAudienceResult( forPlayerID ))
	End Method


	Method Draw() override
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If contract.owner = GetObservedPlayerID()
				Local daysLeft:Int = contract.GetDaysLeft()
				SetAlpha( 0.80*oldColA )
				If daysLeft <= 0
					 SetColor( 240,150,150 )
				ElseIf daysLeft <= 1
					SetColor( 255,190,190)
				Else
					SetColor( 200,200,200 )
				EndIf
			Else
				SetAlpha( 0.70*oldColA )
'				SetColor 250,200,150
			EndIf
		EndIf

		'mark special vendor-contracts
		If contract.owner <> GetObservedPlayerID()
			If contract.GetDaysToFinish() <= 1
				SetColor( 255,230,215 )
			EndIf
		EndIf

		Super.Draw()

		SetColor( oldCol )
		SetAlpha( oldColA )


		'set mouse to "hold/dragged"
		If isDragged()
			GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
		'set mouse to "pick/drag"
		ElseIf isHovered()
			if isDragable() And (contract.owner = GetPlayerBase().playerID Or contract.owner <= 0)
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL)
			else
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_VERTICAL, TGameBase.CURSOR_EXTRA_FORBIDDEN)
			endif
		EndIf
	End Method
End Type




Type TGUIAdContractSlotList Extends TGUIGameSlotList

    Method Create:TGUIAdContractSlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
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



'common image and broadcast quote statistics used for configuring ad contract filters
'updated once a day
Struct SAdContractRefillData

	Field lowestChannelImage:Float
	Field averageChannelImage:Float
	Field highestChannelImage:Float

	'quotes of TOTAL REACH, not of WHO IS AT HOME
	Field lowestChannelQuoteDayTime:Float
	Field averageChannelQuoteDayTime:Float
	Field highestChannelQuoteDayTime:Float

	Field lowestChannelQuotePrimeTime:Float
	Field averageChannelQuotePrimeTime:Float
	Field highestChannelQuotePrimeTime:Float

	Method update()
		Local day:Int = GetWorldTime().GetDay()

		If day > GetWorldtime().GetStartDay()
			Local statistics:TDailyBroadcastStatistic = GetDailyBroadcastStatistic(day-1, True)

			Local averageImage:Float = GetPublicImageCollection().GetAverage().GetAverageImage()
			Local lowestImage:Float = averageImage
			Local highestImage:Float = averageImage

			Local lowestQuoteDayTime:Float = 1.0
			Local averageQuoteDayTime:Float = 0.0
			Local highestQuoteDayTime:Float = 0.0

			Local lowestQuotePrimeTime:Float = 1.0
			Local averageQuotePrimeTime:Float = 0.0
			Local highestQuotePrimeTime:Float = 0.0

			Local broadcast:TAudienceResultBase
			Local value:Float = 0
			Local dayCount:Int = 0
			Local primeCount:Int = 0
			For Local i:Int = 1 To 4
				Local image:Float = GetPublicImageCollection().Get(i).GetAverageImage()
				If image > highestImage Then highestImage = image
				If image < lowestImage Then lowestImage = image

				For local h:Int = 0 to 23
					broadcast = statistics.GetAudienceResult(i, h, False)
					If broadcast
						value = broadcast.GetWholeMarketAudienceQuotePercentage()
						If value > 0
							'print "value " + i + " hour "+ h +" "+value
							If h < 18 Or h > 22
								dayCount:+1
								averageQuoteDayTime:+ value
								If lowestQuoteDayTime > value Then lowestQuoteDayTime = value
								If highestQuoteDayTime < value Then highestQuoteDayTime = value
							Else
								primeCount:+1
								averageQuotePrimeTime:+ value
								If lowestQuotePrimeTime > value Then lowestQuotePrimeTime = value
								If highestQuotePrimeTime < value Then highestQuotePrimeTime = value
							EndIf
						EndIf
					EndIf
				Next
			Next
			averageQuoteDayTime:/ dayCount
			averageQuotePrimeTime:/ primeCount

			lowestChannelImage = lowestImage * 0.01
			averageChannelImage = averageImage * 0.01
			highestChannelImage = highestImage * 0.01

			lowestChannelQuoteDayTime = lowestQuoteDayTime
			averageChannelQuoteDayTime = averageQuoteDayTime
			highestChannelQuoteDayTime = highestQuoteDayTime

			lowestChannelQuotePrimeTime = lowestQuotePrimeTime
			averageChannelQuotePrimeTime = averageQuotePrimeTime
			highestChannelQuotePrimeTime = highestQuotePrimeTime
		Else
			'from refill2
			'averageChannelQuote = 0.085
			'highestChannelQuote = 0.175

			lowestChannelQuoteDayTime:Float = 0.005
			averageChannelQuoteDayTime:Float = 0.03
			highestChannelQuoteDayTime:Float = 0.07

			lowestChannelQuotePrimeTime:Float = 0.07
			averageChannelQuotePrimeTime:Float = 0.1
			highestChannelQuotePrimeTime:Float = 0.15
		EndIf
		rem
		print "Image "+ lowestChannelImage + " " + averageChannelImage + " " + highestChannelImage
		print "Day   "+ lowestChannelQuoteDayTime + " " + averageChannelQuoteDayTime + " " + highestChannelQuoteDayTime
		print "Prime "+ lowestChannelQuotePrimeTime + " " + averageChannelQuotePrimeTime + " " + highestChannelQuotePrimeTime
		endrem
	EndMethod
End Struct
