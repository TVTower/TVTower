SuperStrict
Import "common.misc.plannerlist.base.bmx"
Import "game.programme.adcontract.bmx"
Import "game.player.programmecollection.bmx"
Import "game.game.base.bmx"
Import "game.screen.programmeplanner.gui.bmx"


'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist Extends TPlannerList
	Field hoveredAdContract:TAdContract = Null
	'cache
	Global _contracts:TList {nosave}
	Global _contractsCacheKey:string = "" {nosave}
	Global _contractsOwner:int = 0 {nosave}

	Global _registeredListeners:TList = CreateList() {nosave}
	Global registeredEvents:int = False


	Method Create:TgfxContractlist(x:Int, y:Int)
		entrySize = null
		entriesRect = null

		'right align the list
		Pos.SetXY(x - GetEntrySize().GetX(), y)

		Return Self
	End Method


	Method New()
		sortSymbols = ["gfx_datasheet_icon_az", "gfx_datasheet_icon_minAudience", "gfx_datasheet_icon_money", "gfx_datasheet_icon_duration", "gfx_datasheet_icon_spotsAired"]
		sortKeys = [0, 1, 2, 3, 4]
		sortTooltips = [ new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("NAME")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("MIN_AUDIENCE")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("AD_PROFIT")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("REMAINING_TERM")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("SPOTS_TO_SEND")), new TRectangle.Init(0,0,-1,-1)) ..
		               ]

		RegisterEvents()
	End Method


	Method Initialize:int()
		Super.Initialize()

		'invalidate contracts list
		_contracts = null
		_contractsCacheKey = ""
		_contractsOwner = 0
	End Method


	Method UnRegisterEvents:Int()
		For local link:TLink = EachIn _registeredListeners
			'variant a: link.Remove()
			'variant b: we never know if there happens something else
			EventManager.unregisterListenerByLink(link)
		Next
	End Method


	Method RegisterEvents:Int()
		'register events for all lists
		if not registeredEvents
			'handle changes to the programme collections (add/removal
			'of contracts)
			EventManager.registerListenerFunction("programmecollection.addAdContract", OnChangeProgrammeCollection)
			EventManager.registerListenerFunction("programmecollection.removeAdContract", OnChangeProgrammeCollection)

			'handle broadcasts of advertisements with our contracts
			EventManager.registerListenerFunction("broadcast.advertisement.BeginBroadcasting", OnBroadcastAdvertisement)
			EventManager.registerListenerFunction("broadcast.advertisement.BeginBroadcastingAsProgramme", OnBroadcastAdvertisement)

			'handle changes to the contracts to avoid outdated information
			EventManager.registerListenerFunction("adContract.onSetSpotsSent", OnChangeContractData)

			'handle savegame loading (reset cache)
			EventManager.registerListenerFunction("SaveGame.OnLoad", OnLoadSaveGame)

			registeredEvents = True
		endif
	End Method


	'override
	Method GetEntrySize:TVec2D()
		if not entrySize
			entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		endif

		return entrySize
	End Method


	'override
	Method GetEntriesRect:TRectangle()
		if not entriesRect
			'recalculate dimension of the area of all entries (also if not all slots occupied)
			entriesRect = New TRectangle.Init(Pos.GetX(), Pos.GetY(), GetEntrySize().GetX(), 0)
			if ListSortVisible
				entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_topButton.default").area.GetH()
			else
				entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
			endif
			entriesRect.dimension.y :+ GameRules.adContractsPerPlayerMax * GetEntrySize().GetY()
			entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()
		endif

		return entriesRect
	End Method


	Method GetContracts:TList(owner:int)
		local cacheKey:string = ListSortDirection+"_"+ListSortMode+"_"+owner
		'create cached var?
		if not _contracts or cacheKey <> _contractsCacheKey
			_contracts = GetPlayerProgrammeCollection(owner).GetAdContracts().Copy()

			'sort
			Select ListSortMode
				case 0
					_contracts.Sort(not ListSortDirection, TAdContract.SortByName)
				case 1
					_contracts.Sort(not ListSortDirection, TAdContract.SortByMinAudience)
				case 2
					_contracts.Sort(not ListSortDirection, TAdContract.SortByProfit)
				case 3
					_contracts.Sort(not ListSortDirection, TAdContract.SortByDaysLeft)
				case 4
					_contracts.Sort(not ListSortDirection, TAdContract.SortBySpotsToSend)
				default
					_contracts.Sort(not ListSortDirection, TAdContract.SortByName)
			End Select

			_contractsCacheKey = cacheKey
			_contractsOwner = owner
		endif

		return _contracts
	End Method


	Method Draw:Int()
		If Not enabled Or Self.openState < 1 Then Return False

		If Not owner Then Return False

		Local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = null
		Local currX:Int = GetEntriesRect().GetX()
		Local currY:Int = GetEntriesRect().GetY()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)

		Local contracts:TList = GetContracts(owner)
		'draw slots, even if empty
		For Local i:Int = 0 Until GameRules.adContractsPerPlayerMax
			Local contract:TAdContract
			if i < contracts.Count() then contract = TAdContract( contracts.ValueAtIndex(i) )

			Local entryPositionType:String = "entry"
			If i = 0 Then entryPositionType = "first"
			If i = GameRules.adContractsPerPlayerMax-1 Then entryPositionType = "last"


			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = 0
				if ListSortVisible
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_topButton.default")
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				endif
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+".default").draw(currX,currY)


			'=== DRAW TAPE===
			If contract
				local drawType:string = "default"
				'light emphasize
				if contract.GetDaysLeft() <= 1 then drawType = "planned"
				'strong emphasize
				if contract.GetDaysLeft() <= 0 then SetColor 255,220,220

				'hovered - draw hover effect if hovering
				If THelper.MouseIn(currX, currY, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					GetSpriteFromRegistry("gfx_programmetape_movie.hovered").draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_movie."+drawType).draw(currX + 8, currY+1)
				EndIf

				if contract.GetDaysLeft() <= 0 then SetColor 255,255,255

				if TVTDebugInfos
					font.drawBlock(contract.GetProfit() +CURRENCYSIGN+" @ "+ contract.GetMinAudience(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
				else
					font.drawBlock(contract.GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
				endif

				if contract.GetLimitedToTargetGroup() > 0 or contract.GetLimitedToGenre() > 0 or contract.GetLimitedToProgrammeFlag() > 0
					GetSpriteFromRegistry("gfx_programmetape_stamp_attention").draw(currX + 8, currY+1)
				endif
			EndIf


			'advance to next line
			currY:+ GetEntrySize().y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = GameRules.adContractsPerPlayerMax-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next



		'draw sort symbols
		if ListSortVisible
			DrawSortArea(int(GetEntriesRect().GetX()), int(GetEntriesRect().GetY()))
		endif
	End Method


	Method Update:Int()
		'gets repopulated if an contract is hovered
		hoveredAdContract = Null

		If Not enabled Then Return False

		If Not owner Then Return False

		If Self.openState >= 1
			Local currY:Int
			if ListSortVisible
				currY = GetEntriesRect().GetY() + GetSpriteFromRegistry("gfx_programmeentries_topButton.default").area.GetH()
			else
				currY = GetEntriesRect().GetY() + GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
			endif

			local contracts:TList = GetContracts(owner)
			'sort
			For Local i:Int = 0 Until Min(contracts.Count(), GameRules.adContractsPerPlayerMax	)
				Local contract:TAdContract = TAdContract(contracts.ValueAtIndex(i))

				'we add 1 pixel to height (aka not subtracting -1) - to hover between tapes too
				If contract And THelper.MouseIn(int(GetEntriesRect().GetX()), currY, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					'store for outside use (eg. displaying a sheet)
					hoveredAdContract = contract

					GetGameBase().cursorstate = 1
					'only interact if allowed
					If clicksAllowed
						If MOUSEMANAGER.IsShortClicked(1)
							New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TAdvertisement.Create(contract), "programmePlanner" ).drag()
							MOUSEMANAGER.resetKey(1)
							SetOpen(0)
						EndIf
					EndIf
				EndIf

				'next tape
				currY :+ GetEntrySize().y
			Next
		EndIf


		'handle sort buttons (if still open)
		If Self.openState >= 1
			UpdateSortArea(int(GetEntriesRect().GetX()), int(GetEntriesRect().GetY()))
		endif


		'react to right click
		If openState > 0 and (MOUSEMANAGER.IsClicked(2) or MouseManager.IsLongClicked(1))
			SetOpen( Max(0, openState - 1) )

			MOUSEMANAGER.resetKey(2)
			MOUSEMANAGER.resetKey(1) 'also normal clicks
		EndIf

		'close if mouse hit outside - simple mode: so big rect
		If MouseManager.IsHit(1)
			If Not GetEntriesRect().containsXY(MouseManager.x, MouseManager.y)
				SetOpen(0)
				'MouseManager.ResetKey(1)
			EndIf
		EndIf
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 Else enabled = 1
		Self.openState = newState
	End Method


	'=== EVENT LISTENERS ===

	Function OnChangeProgrammeCollection:int( triggerEvent:TEventBase )
		local collection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent.GetSender())
		if not collection or collection.owner <> _contractsOwner then return False

		'invalidate contracts list
		_contracts = null
	End Function


	Function OnChangeContractData:int( triggerEvent:TEventBase )
		local adContract:TAdContract = TAdContract(triggerEvent.GetSender())
		if not adContract or adContract.owner <> _contractsOwner then return False

		'invalidate contracts list
		_contracts = null
	End Function


	Function OnBroadcastAdvertisement:int( triggerEvent:TEventBase )
		local advertisement:TAdvertisement = TAdvertisement(triggerEvent.GetSender())
		if not advertisement or advertisement.owner <> _contractsOwner then return False

		'invalidate contracts list
		_contracts = null
	End Function


	Function OnLoadSaveGame:int( triggerEvent:TEventBase )
		'invalidate contracts list
		_contracts = null
	End Function
End Type