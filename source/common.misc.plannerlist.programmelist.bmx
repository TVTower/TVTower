SuperStrict
Import "common.misc.plannerlist.base.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.programme.programmelicence.gui.bmx"
Import "game.player.programmecollection.bmx"
Import "game.game.base.bmx"
Import "game.screen.programmeplanner.gui.bmx"
Import "Dig/base.gfx.gui.button.bmx"


'the programmelist shown in the programmeplaner
Type TgfxProgrammelist Extends TPlannerList
	Field displaceEpisodeTapes:TVec2D = New TVec2D.Init(6,5)
	'area of all genres/filters including top/bottom-area
	Field genresRect:TRectangle
	Field genresCount:Int = -1
	Field genreSize:TVec2D = New TVec2D
	Field currentEntry:Int = -1
	Field currentSubEntry:Int = -1
	Field subEntriesRect:TRectangle
	Field entriesPage:int = 1
	Field entriesPages:int = 1
	Field subEntriesPage:int = 1
	Field subEntriesPages:int = 1

	Field entriesButtonPrev:TGUIButton
	Field entriesButtonNext:TGUIButton
	Field subEntriesButtonPrev:TGUIButton
	Field subEntriesButtonNext:TGUIButton

	'licence with children
	Field hoveredParentalLicence:TProgrammeLicence = Null
	'licence 
	Field hoveredLicence:TProgrammeLicence = Null

	'cache
	Global _licences:TList {nosave}
	Global _licencesCacheKey:string = "" {nosave}
	Global _licencesOwner:int = 0 {nosave}

	Global _registeredListeners:TList = CreateList() {nosave}
	Global registeredEvents:int = False

	Const MAX_LICENCES_PER_PAGE:int= 8
	Const MODE_PROGRAMMEPLANNER:Int=0	'creates a GuiProgrammePlanElement
	Const MODE_ARCHIVE:Int=1			'creates a GuiProgrammeLicence

	

	Method Create:TgfxProgrammelist(x:Int, y:Int)
		genreSize = null
		entrySize = null
		entriesRect = null
		genresRect = null

		'right align the list
		Pos.SetXY(x - GetGenreSize().GetX(), y)

		Return Self
	End Method


	Method New()
		sortSymbols = ["gfx_datasheet_icon_az", "gfx_datasheet_icon_runningTime", "gfx_datasheet_icon_topicality"]
		sortKeys = [0, 1, 2]

		RegisterEvents()
	End Method


	Method Initialize:int()
		Super.Initialize()

		'invalidate contracts list
		_licences = null
		_licencesCacheKey = ""
		_licencesOwner = 0
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
			EventManager.registerListenerFunction("programmecollection.addProgrammeLicence", OnChangeProgrammeCollection)
			EventManager.registerListenerFunction("programmecollection.removeProgrammeLicence", OnChangeProgrammeCollection)
			'also clear cache if licences get moved from/to suitcase
			EventManager.registerListenerFunction("programmecollection.addProgrammeLicenceToSuitcase", OnChangeProgrammeCollection)
			EventManager.registerListenerFunction("programmecollection.removeProgrammeLicenceFromSuitcase", OnChangeProgrammeCollection)

			'handle broadcasts of the programme
			EventManager.registerListenerFunction("broadcast.programme.BeginBroadcasting", OnBroadcastProgramme)
			EventManager.registerListenerFunction("broadcast.programme.BeginBroadcastingAsAdvertisement", OnBroadcastProgramme)

			'handle savegame loading (reset cache)
			EventManager.registerListenerFunction("SaveGame.OnLoad", OnLoadSaveGame)

			registeredEvents = True
		endif
	End Method	


	Method GetGenreSize:TVec2D()
		if not genreSize
			genreSize = GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.dimension.copy()
		endif

		return genreSize
	End Method


	Method GetGenresRect:TRectangle()
		if not genresRect
			'recalculate dimension of the area of all genres
			genresRect = New TRectangle.Init(Pos.GetX(), Pos.GetY(), GetGenreSize().GetX(), 0)
			genresRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmegenres_top.default").area.GetH()
			genresRect.dimension.y :+ TProgrammeLicenceFilter.GetVisibleCount() * GetGenreSize().GetY()
			genresRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmegenres_bottom.default").area.GetH()
		endif

		return genresRect
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
			entriesRect = New TRectangle.Init(GetGenresRect().GetX() - 170, GetGenresRect().GetY()+1, GetEntrySize().GetX(), 0)
			if ListSortVisible
				entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_topButton.default").area.GetH()
			else
				entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
			endif
			'max 10 licences per page
			entriesRect.dimension.y :+ MAX_LICENCES_PER_PAGE * GetEntrySize().GetY()

			if entriesPages > 1
				entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottomButton.default").area.GetH()
			else
				entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()
			endif

			'height added when button visible
			'entriesRectButtonH = GetSpriteFromRegistry("gfx_programmeentries_bottomButton.default").area.GetH() - GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()
		endif
		
		return entriesRect
	End Method


	Method GetSubEntriesRect:TRectangle()
		if not subEntriesRect
			'recalculate dimension of the area of all entries (also if not all slots occupied)
			subEntriesRect = New TRectangle.Init(GetEntriesRect().GetX() + 174, GetEntriesRect().GetY() + 27, GetEntrySize().GetX(), 0)
			subEntriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
			'max 10 licences per page
			subEntriesRect.dimension.y :+ MAX_LICENCES_PER_PAGE * GetEntrySize().GetY()
			subEntriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()
			'height added when button visible
			'subEntriesRectButtonH = GetSpriteFromRegistry("gfx_programmeentries_bottomButton.default").area.GetH() - GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()
		endif
		return subEntriesRect
	End Method



	Method GetLicences:TList(owner:int, filterIndex:int)
		local cacheKey:string = ListSortDirection+"_"+ListSortMode+"_"+filterIndex+"_"+owner 
		'create cached var?
		if not _licences or cacheKey <> _licencesCacheKey
			Local filter:TProgrammeLicenceFilter = TProgrammeLicenceFilter.GetAtIndex(filterIndex)
			_licences = ListFromArray( GetPlayerProgrammeCollection(owner).GetLicencesByFilter(filter) )

			'sort
			Select ListSortMode
				case 0
					_licences.Sort(not ListSortDirection, TProgrammeLicence.SortByName)
				case 1
					_licences.Sort(not ListSortDirection, TProgrammeLicence.SortByBlocks)
				case 2
					_licences.Sort(not ListSortDirection, TProgrammeLicence.SortByTopicality)
				default
					_licences.Sort(not ListSortDirection, TProgrammeLicence.SortByName)
			End Select
			
			_licencesCacheKey = cacheKey
			_licencesOwner = owner
		endif

		return _licences
	End Method
		

	Method SetEntriesPages(pages:int)
		if entriesPages <> pages
			entriesPages = pages
			'reset rect
			entriesRect = null
		endif
	End Method


	Method SetSubEntriesPages(pages:int)
		if subEntriesPages <> pages
			subEntriesPages = pages
			'reset rect
			subEntriesRect = null
		endif
	End Method


	Method Draw()
		If Not enabled Then Return
		if Not owner Then Return

		'draw genre selector
		If Self.openState >=1
			Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner)

			'mark new genres
			'TODO: do this part in programmecollection (only on add/remove)
			Local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
			Local containsNew:Int[visibleFilters.length]

			For Local licence:TProgrammeLicence = EachIn programmeCollection.justAddedProgrammeLicences
				'check all filters if they take care of this licence
				For Local i:Int = 0 Until visibleFilters.length
					'no check needed if already done
					If containsNew[i] Then Continue

					If visibleFilters[i].DoesFilter(licence)
						containsNew[i] = 1
						'do not check other filters
						Exit
					EndIf
				Next
			Next

			'=== DRAW ===
			Local currSprite:TSprite
			'maybe it has changed since initialization
			genreSize = GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.dimension.copy()
			Local currY:Int = GetGenresRect().GetY()
			Local currX:Int = GetGenresRect().GetX()
			Local textRect:TRectangle = New TRectangle.Init(currX + 13, currY, GetGenreSize().x - 12 - 5, GetGenreSize().y)
			 
			Local oldAlpha:Float = GetAlpha()

			'draw each visible filter
			Local filter:TProgrammeLicenceFilter
			For Local i:Int = 0 Until visibleFilters.length
				Local entryPositionType:String = "entry"
				If i = 0 Then entryPositionType = "first"
				If i = visibleFilters.length-1 Then entryPositionType = "last"

				Local entryDrawType:String = "default"
				'highlighted - if genre contains new entries
				If containsNew[i] = 1 Then entryDrawType = "highlighted"
				'active - if genre is the currently used (selected to see tapes)
				If i = currentGenre Then entryDrawType = "active"
				'hovered - draw hover effect if hovering
				'can only haver if no episode list is open
				If Self.openState <3 And THelper.MouseIn(currX, currY, int(GetGenreSize().GetX()), int(GetGenreSize().GetY()))
					entryDrawType="hovered"
				endif

				'add "top" portion when drawing first item
				'do this in the for loop, so the entrydrawType is known
				'(top-portion could contain color code of the drawType)
				If i = 0
					currSprite = GetSpriteFromRegistry("gfx_programmegenres_top."+entryDrawType)
					currSprite.draw(currX, currY)
					currY :+ currSprite.area.GetH()
				EndIf

				'draw background
				GetSpriteFromRegistry("gfx_programmegenres_"+entryPositionType+"."+entryDrawType).draw(currX,currY)

				'genre background contains a 2px splitter (bottom + top)
				'so add 1 pixel to textY
				textRect.position.SetY(currY + 1)

				Local licenceCount:Int = programmeCollection.GetFilteredLicenceCount(visibleFilters[i])
				Local filterName:String = visibleFilters[i].GetCaption()

				
				If licenceCount > 0
					GetBitmapFontManager().baseFont.drawBlock(filterName + " (" +licenceCount+ ")", textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), ALIGN_LEFT_CENTER, TColor.clBlack)
				Else
					SetAlpha 0.25 * GetAlpha()
					GetBitmapFontManager().baseFont.drawBlock(filterName, textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), ALIGN_LEFT_CENTER, TColor.clBlack)
					SetAlpha 4 * GetAlpha()
				EndIf
				'advance to next line
				currY:+ GetGenreSize().y

				'add "bottom" portion when drawing last item
				'do this in the for loop, so the entrydrawType is known
				'(top-portion could contain color code of the drawType)
				If i = visibleFilters.length-1
					currSprite = GetSpriteFromRegistry("gfx_programmegenres_bottom."+entryDrawType)
					currSprite.draw(currX, currY)
					currY :+ currSprite.area.GetH()
				EndIf
			Next
		EndIf

		'draw tapes of current genre + episodes of a selected series
		If Self.openState >=2 And currentGenre >= 0
			DrawTapes(currentgenre)
		EndIf

		'draw episodes background
		If Self.openState >=3
			If currentGenre >= 0 Then DrawSubTapes(hoveredParentalLicence)
		EndIf

	End Method


	Method DrawTapes:Int(filterIndex:Int=-1)
		'skip drawing tapes if no genreGroup is selected
		If filterIndex < 0 Then Return False

		If not owner then Return False 

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner) 
		Local licences:TList = GetLicences(owner, filterIndex)

		SetEntriesPages( int(ceil(licences.Count() / Float(MAX_LICENCES_PER_PAGE))) )

		Local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		Local currY:Int = GetEntriesRect().GetY()
		Local currX:Int = GetEntriesRect().GetX()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)
		Local oldColor:TColor = new TColor.Get()


		'draw slots, even if empty
		local startIndex:int = (entriesPage-1)*MAX_LICENCES_PER_PAGE
		local endIndex:int = entriesPage*MAX_LICENCES_PER_PAGE -1
		For Local i:Int = startIndex To endIndex
			local licence:TProgrammeLicence
			if i < licences.Count() and i >= 0 then licence = TProgrammeLicence(licences.ValueAtIndex(i))

			Local entryPositionType:String = "entry"
			If i = startIndex Then entryPositionType = "first"
			If i = endIndex Then entryPositionType = "last"

			Local entryDrawType:String = "default"
			Local tapeDrawType:String = "default"
			If licence 
				'== BACKGROUND ==
				'planned is more important than new - both only happen
				'on startprogrammes
				If licence.IsProgrammePlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				Else
					'switch background to "new" if the licence is a just-added-one
					For Local newLicence:TProgrammeLicence = EachIn programmeCollection.justAddedProgrammeLicences
						If licence = newLicence
							entryDrawType = "new"
							tapeDrawType = "new"
							Exit
						EndIf
					Next
				EndIf
			EndIf

			
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = startIndex
				if ListSortVisible
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_topButton."+entryDrawType)
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top."+entryDrawType)
				endif

				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+"."+entryDrawType).draw(currX,currY)


			'=== DRAW TAPE===
			If licence
				'== ADJUST TAPE TYPE ==
				'do that afterwards because now "new" and "planned" are
				'already handled

				local licenceAvailable:int = licence.IsAvailable()
				'mark not available licences (eg. broadcast limits exceeded or not yet released)
				if not licenceAvailable
					setAlpha 0.5 * oldColor.a
					SetColor 255,200,200
				endif


				'active - if tape is the currently used
				If i = currentEntry Then tapeDrawType = "hovered"
				'hovered - draw hover effect if hovering
				'we add 1 pixel to height - to hover between tapes too
				If THelper.MouseIn(currX, currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					'mouse-over-hand
					if clicksAllowed and licenceAvailable then GetGameBase().cursorstate = 1

					tapeDrawType="hovered"
				endif


				If licence.isSingle()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				EndIf
				font.drawBlock(licence.GetTitle(), currX + 22, currY + 3, 145,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)

				oldColor.SetRGBA()
			EndIf


			'advance to next line
			currY:+ GetEntrySize().y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = endIndex
				if entriesPages > 1
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottomButton."+entryDrawType)
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom."+entryDrawType)
				endif
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next




		'draw sort symbols
		if ListSortVisible
			local buttonX:int = GetEntriesRect().GetX() + 2
			local buttonY:int = GetEntriesRect().GetY() + 4
			local buttonWidth:int = 32
			local buttonPadding:int = 2

			For local i:int = 0 until sortKeys.length
				local spriteName:string = "gfx_gui_button.datasheet"
				if ListSortMode = sortKeys[i]
					spriteName = "gfx_gui_button.datasheet.positive"
				endif

				if THelper.MouseIn(buttonX + 5 + i*(buttonWidth + buttonPadding), buttonY, buttonWidth, 27)
					spriteName :+ ".hover"
				endif
				GetSpriteFromRegistry(spriteName).DrawArea(buttonX + 5 + i*(buttonWidth + buttonPadding), buttonY, buttonWidth,27)
				GetSpriteFromRegistry(sortSymbols[ sortKeys[i] ]).Draw(buttonX + 9 + i*(buttonWidth + buttonPadding), buttonY+2)
				'sort
				if ListSortMode = sortKeys[i]
					if ListSortDirection = 0
						GetSpriteFromRegistry("gfx_datasheet_icon_arrow_down").Draw(buttonX + 10 + i*(buttonWidth + buttonPadding), buttonY+2)
					else
						GetSpriteFromRegistry("gfx_datasheet_icon_arrow_up").Draw(buttonX + 10 + i*(buttonWidth + buttonPadding), buttonY+2)
					endif
				endif
			Next
		endif

		
		'handle page buttons
		if entriesPages > 1
			local w:int = 0.5 * GetSubEntriesRect().GetW() - 14 - 20
			if not entriesButtonPrev
				entriesButtonPrev = new TGUIButton.Create(new TVec2D.Init(currX + 5 , currY - 23), new TVec2D.Init(w, 18), "<", "PLANNERLIST_PROGRAMMELIST")
				entriesButtonPrev.spriteName = "gfx_gui_button.datasheet"
				'manage on our own
				GuiManager.Remove(entriesButtonPrev)
			endif
			if not entriesButtonNext
				entriesButtonNext = new TGUIButton.Create(new TVec2D.Init(currX + GetEntriesRect().GetW() - 7 - w, currY - 23), new TVec2D.Init(w, 18), ">", "PLANNERLIST_PROGRAMMELIST")
				entriesButtonNext.spriteName = "gfx_gui_button.datasheet"
				GuiManager.Remove(entriesButtonNext)
			endif


			local oldAlpha:float = GetAlpha()
			if entriesButtonPrev
				if not entriesButtonPrev.IsEnabled() then SetAlpha 0.5*oldAlpha
				entriesButtonPrev.Draw()
				if not entriesButtonPrev.IsEnabled() then SetAlpha oldAlpha
			endif
			if entriesButtonNext
				if not entriesButtonNext.IsEnabled() then SetAlpha 0.5*oldAlpha
				entriesButtonNext.Draw()
				if not entriesButtonNext.IsEnabled() then SetAlpha oldAlpha
			endif			

			GetBitmapFont("Default", 10).DrawBlock(entriesPage+"/" + entriesPages, currX, currY - 22, GetEntriesRect().GetW(), 20, ALIGN_CENTER_CENTER, TColor.clBlack)
		endif
				
		Rem
		'debug
		currY = GetEntriesRect().GetY()
		For Local i:Int = 0 To GameRules.maxProgrammeLicencesPerFilter
			if i = 0
				Local currSprite:TSprite
				If licences[0].IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				Else
					'switch background to "new" if the licence is a just-added-one
					For Local licence:TProgrammeLicence = EachIn GetPlayer().GetProgrammeCollection().justAddedProgrammeLicences
						If licences[i] = licence
							currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.new")
							Exit
						EndIf
					Next
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				EndIf

				currY :+ currSprite.area.GetH()
			EndIf
			
			SetColor 0,255,0
			If i mod 2 = 0 then SetColor 255,0,0
			SetAlpha 1.0
			DrawRect(GetEntriesRect().GetX(), currY+1, entrySize.GetX(), 1)
			'we add 1 pixel to y - as we hover between tapes too
			DrawRect(GetEntriesRect().GetX(), currY+1 + entrySize.GetY() - 1, entrySize.GetX(), 1)
			SetAlpha 0.4
			'we add 1 pixel to height - as we hover between tapes too
			DrawRect(GetEntriesRect().GetX(), currY+1, entrySize.GetX(), entrySize.GetY())

			currY:+ entrySize.y

			SetColor 255,255,255
			SetAlpha 1.0
		Next
		endrem
	End Method


	Method UpdateTapes:Int(filterIndex:Int=-1, mode:Int=0)
		'skip doing something without a selected filter
		If filterIndex < 0 Then Return False

		If not owner Then Return False  

		Local currY:Int = GetEntriesRect().GetY()
		Local licences:TList = GetLicences(owner, filterIndex)
		if not licences or licences.count() = 0
			SetEntriesPages( 1 )
			return False
		endif
		
		SetEntriesPages( int(ceil(licences.Count() / Float(MAX_LICENCES_PER_PAGE))) )

		'handle page buttons (before other click handling here)
		if entriesPages > 1
			if entriesButtonPrev
				entriesButtonPrev.Update()

				if entriesPage = 1
					if entriesButtonPrev.IsEnabled() then entriesButtonPrev.Disable()
				else
					if not entriesButtonPrev.IsEnabled() then entriesButtonPrev.Enable()
				endif

				if entriesButtonPrev.IsClicked()
					entriesPage = Min(entriesPage, entriesPage-1)
					entriesButtonPrev.mouseIsClicked = null
					MouseManager.ResetKey(1)
				endif
			endif

			if entriesButtonNext
				entriesButtonNext.Update()

				if entriesPage = entriesPages
					if entriesButtonNext.IsEnabled() then entriesButtonNext.Disable()
				else
					if not entriesButtonNext.IsEnabled() then entriesButtonNext.Enable()
				endif

				'need to check "hit" - outer rect is checking for hit too
				if entriesButtonNext.IsClicked()
					entriesPage = Max(entriesPage, entriesPage+1)
					entriesButtonNext.mouseIsClicked = null
					MouseManager.ResetKey(1)
				endif
			endif
		endif


		local startIndex:int = (entriesPage-1)*MAX_LICENCES_PER_PAGE
		local endIndex:int = Min(licences.Count()-1, entriesPage*MAX_LICENCES_PER_PAGE -1)
		For Local i:Int = startIndex to endIndex
			local licence:TProgrammeLicence
			if i < licences.Count() and i >= 0 then licence = TProgrammeLicence(licences.ValueAtIndex(i))

			If i = startIndex
				Local currSprite:TSprite
				Local spriteKey:string = ""
				if ListSortVisible
					spriteKey = "gfx_programmeentries_topButton"
				else
					spriteKey = "gfx_programmeentries_top"
				endif

				If licence and licence.IsPlanned()
					currSprite = GetSpriteFromRegistry(spriteKey+".planned")
				Else
					'switch background to "new" if the licence is a just-added-one
					For Local newLicence:TProgrammeLicence = EachIn GetPlayerProgrammeCollection(owner).justAddedProgrammeLicences
						If licence = newLicence
							currSprite = GetSpriteFromRegistry(spriteKey+".new")
							Exit
						EndIf
					Next
					currSprite = GetSpriteFromRegistry(spriteKey+".default")
				EndIf

				currY :+ currSprite.area.GetH()
			EndIf

			'we add 1 pixel to height (aka not subtracting -1) - to hover between tapes too
			If THelper.MouseIn(int(GetEntriesRect().GetX()), currY+1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
				Local doneSomething:Int = False
				'store for sheet-display
				hoveredLicence = licence

				'only interact if allowed
				If clicksAllowed
					If MOUSEMANAGER.IsShortClicked(1)
						If mode = MODE_PROGRAMMEPLANNER
							If licence.isSingle()
								'create and drag new block
								local programme:TProgramme = TProgramme.Create(licence)
								if programme
									New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( programme, "programmePlanner" ).drag()
									SetOpen(0)
									doneSomething = True
								endif
							Else
								'set the hoveredParentalLicence so the episodes-list is drawn
								hoveredParentalLicence = licence
								SetOpen(3)
								doneSomething = True
							EndIf
						ElseIf mode = MODE_ARCHIVE
							'create a dragged block
							Local obj:TGUIProgrammeLicence = New TGUIProgrammeLicence.CreateWithLicence(licence)
							obj.SetLimitToState("archive")
							obj.drag()

							SetOpen(0)
							doneSomething = True
						EndIf

						'something changed, so stop looping through rest
						If doneSomething
							MOUSEMANAGER.resetKey(1)
							Return True
						EndIf
					EndIf
				endif
			EndIf

			'next tape
			currY :+ GetEntrySize().y
		Next


		'handle sort buttons (if still open)
		If Self.openState >= 1
			UpdateSortButtons()
		endif

		Return False
	End Method


	Method DrawSubTapes:Int(parentLicence:TProgrammeLicence)
		If Not parentLicence Then Return False

		SetSubEntriesPages( int(ceil(parentLicence.GetSubLicenceSlots() / Float(MAX_LICENCES_PER_PAGE))) )

		Local hoveredLicence:TProgrammeLicence = Null
		Local currSprite:TSprite
		Local currY:Int = GetSubEntriesRect().GetY()
		Local currX:Int = GetSubEntriesRect().GetX()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)
		Local oldColor:TColor = new TColor.Get()

		local startIndex:int = (subEntriesPage-1)*MAX_LICENCES_PER_PAGE
		local endIndex:int = subEntriesPage*MAX_LICENCES_PER_PAGE -1
		'if no paging was used, hide empty slots
		'(to have consistent button coordinates we show empty slots on
		' subsequent pages)
		if subEntriesPage = 1
			endIndex = Min(parentLicence.GetSubLicenceSlots()-1, endIndex)
		endif

		For Local i:Int = startIndex to endIndex				
			Local licence:TProgrammeLicence = parentLicence.GetSubLicenceAtIndex(i)

			Local entryPositionType:String = "entry"
			If i = startIndex Then entryPositionType = "first"
			If i = endIndex Then entryPositionType = "last"

			Local entryDrawType:String = "default"
			Local tapeDrawType:String = "default"
			If licence
				'== BACKGROUND ==
				If licence.IsPlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				EndIf
			EndIf

			
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = startIndex
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+"."+entryDrawType).draw(currX,currY)


			'=== DRAW TAPE===
			If licence
				local licenceAvailable:int = licence.IsAvailable()
				'mark not available licences (eg. broadcast limits exceeded or not yet released)
				if not licenceAvailable
					setAlpha 0.5 * oldColor.a
					SetColor 255,200,200
				endif
				
				'== ADJUST TAPE TYPE ==
				'active - if tape is the currently used
				If i = currentSubEntry Then tapeDrawType = "hovered"
				'hovered? - draw hover effect, adjust shown mouse cursor
				If THelper.MouseIn(currX, currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					'mouse-over-hand
					if clicksAllowed and licenceAvailable then GetGameBase().cursorstate = 1

					tapeDrawType="hovered"
				endif

				If licence.isSingle()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				EndIf
				font.drawBlock("(" + (i+1) + "/" + parentLicence.GetEpisodeCount() + ") " + licence.GetTitle(), currX + 22, currY + 3, 145,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)

				oldColor.SetRGBA()
			EndIf


			'advance to next line
			currY:+ GetEntrySize().y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = endIndex
				if subEntriesPages > 1
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottomButton."+entryDrawType)
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom."+entryDrawType)
				endif
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next

		'handle page buttons
		if subEntriesPages > 1
			local w:int = 0.5 * GetSubEntriesRect().GetW() - 14 - 20
			if not subEntriesButtonPrev
				subEntriesButtonPrev = new TGUIButton.Create(new TVec2D.Init(currX + 5 , currY - 23), new TVec2D.Init(w, 18), "<", "PLANNERLIST_PROGRAMMELIST")
				subEntriesButtonPrev.spriteName = "gfx_gui_button.datasheet"
				'manage on our own
				GuiManager.Remove(subEntriesButtonPrev)
			endif
			if not subEntriesButtonNext
				subEntriesButtonNext = new TGUIButton.Create(new TVec2D.Init(currX + GetSubEntriesRect().GetW() - 7 - w, currY - 23), new TVec2D.Init(w, 18), ">", "PLANNERLIST_PROGRAMMELIST")
				subEntriesButtonNext.spriteName = "gfx_gui_button.datasheet"
				GuiManager.Remove(subEntriesButtonNext)
			endif
			

			local oldAlpha:float = GetAlpha()
			if subEntriesButtonPrev
				if not subEntriesButtonPrev.IsEnabled() then SetAlpha 0.5*oldAlpha
				subEntriesButtonPrev.Draw()
				if not subEntriesButtonPrev.IsEnabled() then SetAlpha oldAlpha
			endif
			if subEntriesButtonNext
				if not subEntriesButtonNext.IsEnabled() then SetAlpha 0.5*oldAlpha
				subEntriesButtonNext.Draw()
				if not subEntriesButtonNext.IsEnabled() then SetAlpha oldAlpha
			endif
			GetBitmapFont("Default", 10).DrawBlock(subEntriesPage+"/" + subEntriesPages, currX, currY - 22, GetSubEntriesRect().GetW(), 20, ALIGN_CENTER_CENTER, TColor.clBlack)
		endif


		Rem
		'debug - hitbox
		currY = GetSubEntriesRect().GetY()
		For Local i:Int = startIndex To endIndex
			Local licence:TProgrammeLicence = parentLicence.GetsubLicenceAtIndex(i)

			If i = startIndex
				Local currSprite:TSprite
				If licence And licence.IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				endif
				currY :+ currSprite.area.GetH()
			EndIf


			If THelper.MouseIn(GetSubEntriesRect().GetX(), currY + 1, entrySize.GetX(), entrySize.GetY())
				SetColor 100,255,100
				If i mod 2 = 0 then SetColor 255,100,100
			Else
				SetColor 0,255,0
				If i mod 2 = 0 then SetColor 255,0,0
			EndIf
			SetAlpha 1.0
			DrawRect(GetSubEntriesRect().GetX(), currY + 1, entrySize.GetX(), 1)
			DrawRect(GetSubEntriesRect().GetX(), currY + 1 + entrySize.GetY() - 1, entrySize.GetX(), 1)
			SetAlpha 0.3
			'complete size
			DrawRect(GetSubEntriesRect().GetX(), currY + 1, entrySize.GetX(), entrySize.GetY() - 1)

			currY:+ entrySize.y

			SetColor 255,255,255
			SetAlpha 1.0
		Next
		EndRem
	End Method


	Method UpdateSubTapes:Int(parentLicence:TProgrammeLicence)
		if not parentLicence
			SetEntriesPages( 1 )
			return False
		endif

		SetSubEntriesPages( int(ceil(parentLicence.GetSubLicenceSlots() / Float(MAX_LICENCES_PER_PAGE))) )


		'handle page buttons (before other click handling here)
		if subEntriesPages > 1
			if subEntriesButtonPrev
				subEntriesButtonPrev.Update()

				if subEntriesPage = 1
					if subEntriesButtonPrev.IsEnabled() then subEntriesButtonPrev.Disable()
				else
					if not subEntriesButtonPrev.IsEnabled() then subEntriesButtonPrev.Enable()
				endif

				if subEntriesButtonPrev.IsClicked()
					subEntriesPage = Min(subEntriesPage, subEntriesPage-1)
					subEntriesButtonPrev.mouseIsClicked = null
					MouseManager.ResetKey(1)
				endif
			endif

			if subEntriesButtonNext
				subEntriesButtonNext.Update()

				if subEntriesPage = subEntriesPages
					if subEntriesButtonNext.IsEnabled() then subEntriesButtonNext.Disable()
				else
					if not subEntriesButtonNext.IsEnabled() then subEntriesButtonNext.Enable()
				endif

				'need to check "hit" - outer rect is checking for hit too
				if subEntriesButtonNext.IsClicked()
					subEntriesPage = Max(subEntriesPage, subEntriesPage+1)
					subEntriesButtonNext.mouseIsClicked = null
					MouseManager.ResetKey(1)
				endif
			endif
		endif

		
		Local currY:Int = GetSubEntriesRect().GetY() '+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

		local startIndex:int = (subEntriesPage-1)*MAX_LICENCES_PER_PAGE
		local endIndex:int = Min(parentLicence.GetSubLicenceSlots()-1, subEntriesPage*MAX_LICENCES_PER_PAGE -1)
		For Local i:Int = startIndex to endIndex				
			Local licence:TProgrammeLicence = parentLicence.GetSubLicenceAtIndex(i)

			If i = startIndex
				Local currSprite:TSprite
				If licence And licence.IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				endif
				currY :+ currSprite.area.GetH()
			EndIf

			
			If licence
				If THelper.MouseIn(int(GetSubEntriesRect().GetX()), currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					'store for sheet-display
					hoveredLicence = licence

					if licence.isAvailable()
						'only interact if allowed
						If clicksAllowed
							If MOUSEMANAGER.IsShortClicked(1)
								'create and drag new block
								New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TProgramme.Create(licence), "programmePlanner" ).drag()
								SetOpen(0)
								MOUSEMANAGER.resetKey(1)
								Return True
							EndIf
						endif
					endif
				EndIf
			EndIf

			'next tape
			currY :+ GetEntrySize().y
		Next

		'handle page buttons
		if subEntriesPages > 1
			if subEntriesButtonPrev then subEntriesButtonPrev.Update()
			if subEntriesButtonNext then subEntriesButtonNext.Update()
		endif

		Return False
	End Method


	Method Update:Int(mode:Int=0)
		'gets repopulated automagically if hovered
		hoveredLicence = Null

		'if not "open", do nothing (including checking right clicks)
		If Not GetOpen() Then Return False

		'clicking on the genre selector -> select Genre
		'instead of isClicked (butten must be "normal" then)
		'we use "hit" (as soon as mouse button down)
		Local genresStartY:Int = GetSpriteFromRegistry("gfx_programmegenres_top.default").area.GetH()

		'only react to genre area if episode area is not open
		If openState <3
			If MOUSEMANAGER.IsShortClicked(1) And THelper.MouseIn(int(genresRect.GetX()), int(genresRect.GetY()) + genresStartY, int(genresRect.GetW()), int(genreSize.GetY())*TProgrammeLicenceFilter.GetVisibleCount())
				SetOpen(2)
				Local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
				currentGenre = Max(0, Min(visibleFilters.length-1, Floor((MouseManager.y - (genresRect.GetY() + genresStartY)) / genreSize.GetY())))
				MOUSEMANAGER.ResetKey(1)
			EndIf
		EndIf

		'if the genre is selected, also take care of its programmes
		If Self.openState >=2
			If currentgenre >= 0 Then UpdateTapes(currentgenre, mode)
			'series episodes are only available in mode 0, so no mode-param to give
			If hoveredParentalLicence Then UpdateSubTapes(hoveredParentalLicence)
		EndIf


		'react to right click
		If openState > 0 and (MOUSEMANAGER.IsClicked(2) or MouseManager.IsLongClicked(1))
			SetOpen( Max(0, openState - 1) )

			MOUSEMANAGER.resetKey(2)
			MOUSEMANAGER.resetKey(1) 'also normal clicks
		EndIf
		
		'close if clicked outside - simple mode: so big rect
		If MouseManager.isHit(1) ' and mode=MODE_ARCHIVE
			Local closeMe:Int = True
			'in all cases the genre selector is opened
			If genresRect.containsXY(MouseManager.x, MouseManager.y) Then closeMe = False
			'check tape rect
			If openState >=2 And GetEntriesRect().containsXY(MouseManager.x, MouseManager.y) then closeMe = False
			'check episodetape rect
			If openState >=3 And GetSubEntriesRect().containsXY(MouseManager.x, MouseManager.y)  Then closeMe = False

			If closeMe
				SetOpen(0)
				'MouseManager.ResetKey(1)
			EndIf
		EndIf
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 1 Then currentgenre=-1
		If newState <= 2 Then hoveredParentalLicence=Null
		If newState = 0
			enabled = 0
		Else
			enabled = 1

			entriesPage = 1
			subEntriesPage = 1
		EndIf

		Self.openState = newState
	End Method


	'=== EVENT LISTENERS ===

	Function OnChangeProgrammeCollection:int( triggerEvent:TEventBase )
		local collection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent.GetSender())
		if not collection or collection.owner <> _licencesOwner then return False

		'invalidate list to enforce cache recreation
		_licences = null
	End Function


	Function OnBroadcastProgramme:int( triggerEvent:TEventBase )
		local programme:TProgramme = TProgramme(triggerEvent.GetSender())
		if not programme or programme.owner <> _licencesOwner then return False

		'invalidate list to enforce cache recreation
		_licences = null
	End Function


	Function OnLoadSaveGame:int( triggerEvent:TEventBase )
		'invalidate list to enforce cache recreation
		_licences = null
	End Function	
End Type

