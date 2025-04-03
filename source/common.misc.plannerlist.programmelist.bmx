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

	Field maxLicencesPerPage:Int = 8
	Field maxSubLicencesPerPage:Int = 8

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
	Global _licencesCacheKey:Long = 0 {nosave}
	Global _licencesOwner:int = 0 {nosave}

	Global _registeredListeners:TEventListenerBase[] {nosave}
	Global registeredEvents:int = False

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
		sortSymbols = ["gfx_datasheet_icon_az", "gfx_datasheet_icon_runningTime", "gfx_datasheet_icon_topicality", "gfx_datasheet_icon_repetitions"]
		sortKeys = [0, 1, 2, 3]
		sortTooltips = [ new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("NAME")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("MOVIE_BLOCKS")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("MOVIE_TOPICALITY")), new TRectangle.Init(0,0,-1,-1)), ..
		                 new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("MOVIE_REPITITIONS")), new TRectangle.Init(0,0,-1,-1)) ..
		]

		RegisterEvents()
	End Method


	Method Initialize:int()
		Super.Initialize()

		'invalidate contracts list
		_licences = null
		_licencesCacheKey = 0
		_licencesOwner = 0
	End Method


	Method UnRegisterEvents:Int()
		EventManager.UnregisterListenersArray(_registeredListeners)
	End Method


	Method RegisterEvents:Int()
		'register events for all lists
		if not registeredEvents
			'handle changes to the programme collections (add/removal
			'of contracts)
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicence, OnChangeProgrammeCollection) ]
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicence, OnChangeProgrammeCollection) ]
			'also clear cache if licences get moved from/to suitcase
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddProgrammeLicenceToSuitcase, OnChangeProgrammeCollection) ]
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveProgrammeLicenceFromSuitcase, OnChangeProgrammeCollection) ]

			'handle broadcasts of the programme
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcast_Programme_BeginBroadcasting, OnBroadcastProgramme) ]
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Broadcast_Programme_BeginBroadcastingAsAdvertisement, OnBroadcastProgramme) ]

			'handle savegame loading (reset cache)
			_registeredListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnLoad, OnLoadSaveGame) ]

			registeredEvents = True
		endif
	End Method


	Method GetGenreSize:TVec2D()
		if not genreSize
			genreSize = new TVec2D(GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.GetDimension())
		endif

		return genreSize
	End Method


	Method GetGenresRect:TRectangle()
		if not genresRect
			'recalculate dimension of the area of all genres
			genresRect = New TRectangle.Init(Pos.x, Pos.y, GetGenreSize().x, 0)
			genresRect.MoveH( GetSpriteFromRegistry("gfx_programmegenres_top.default").area.h)
			genresRect.MoveH( TProgrammeLicenceFilter.GetVisibleCount() * GetGenreSize().y)
			genresRect.MoveH( GetSpriteFromRegistry("gfx_programmegenres_bottom.default").area.h)
		endif

		return genresRect
	End Method


	'override
	Method GetEntrySize:TVec2D()
		if not entrySize
			entrySize = new TVec2D(GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.GetDimension())
		endif

		return entrySize
	End Method


	'override
	Method GetEntriesRect:TRectangle()
		if not entriesRect
			'recalculate dimension of the area of all entries (also if not all slots occupied)
			entriesRect = New TRectangle.Init(GetGenresRect().x - 170, GetGenresRect().y+1, GetEntrySize().x, 0)
			if ListSortVisible
				entriesRect.MoveH( GetSpriteFromRegistry("gfx_programmeentries_topButton.default").area.h)
			else
				entriesRect.MoveH( GetSpriteFromRegistry("gfx_programmeentries_top.default").area.h)
			endif
			'max 10 licences per page
			entriesRect.MoveH( maxLicencesPerPage * GetEntrySize().y)

			if entriesPages > 1
				entriesRect.MoveH( GetSpriteFromRegistry("gfx_programmeentries_bottomButton.default").area.h)
			else
				entriesRect.MoveH( GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.h)
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
			subEntriesRect.MoveH( GetSpriteFromRegistry("gfx_programmeentries_top.default").area.h)
			'max 10 licences per page
			subEntriesRect.MoveH( maxSubLicencesPerPage * GetEntrySize().y)
			subEntriesRect.MoveH( GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.h)
			'height added when button visible
			'subEntriesRectButtonH = GetSpriteFromRegistry("gfx_programmeentries_bottomButton.default").area.GetH() - GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()
		endif
		return subEntriesRect
	End Method



	Method GetLicences:TList(owner:int, filterIndex:int)
		'                     ListSortDirection 0-255              | ListSortMode 0-255              | filterIndex 0 - IntMax   | owner 0-255
		local cacheKey:Long = Long(ListSortDirection & 255) Shl 56 | Long(ListSortMode & 255) Shl 48 | Long(filterIndex) Shl 16 | Long(owner & 255) Shl 8
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
				case 3
					_licences.Sort(not ListSortDirection, TProgrammeLicence.SortByRepititions)
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


	Method Draw(mode:Int)
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
			genreSize.CopyFrom( GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.GetDimension() )
			Local currY:Int = GetGenresRect().GetY()
			Local currX:Int = GetGenresRect().GetX()
			Local textRect:SRectI = New SRectI(currX + 13, currY, Int(GetGenreSize().x - 12 - 5), Int(GetGenreSize().y))
			Local font:TBitmapFont = GetBitmapFont("Default", 11)

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
				textRect = New SRectI(textRect.x, currY + 1 -2, textRect.w, textRect.h)

				Local licenceCount:Int = programmeCollection.GetFilteredLicenceCount(visibleFilters[i])
				Local filterName:String = visibleFilters[i].GetCaption()


				If licenceCount > 0
					font.DrawBox(filterName + " (" +licenceCount+ ")", textRect.x, textRect.y, textRect.w, textRect.h, sALIGN_LEFT_CENTER, SColor8.Black)
				Else
					SetAlpha 0.25 * GetAlpha()
					font.DrawBox(filterName, textRect.x, textRect.y, textRect.w, textRect.h, sALIGN_LEFT_CENTER, SColor8.Black)
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
					currY :+ currSprite.area.h
				EndIf
			Next
		EndIf

		'draw tapes of current genre + episodes of a selected series
		If Self.openState >=2 And currentGenre >= 0
			DrawTapes(currentgenre, mode)
		EndIf

		'draw episodes background
		If Self.openState >=3
			If currentGenre >= 0 Then DrawSubTapes(hoveredParentalLicence, mode)
		EndIf

	End Method

	Method RecalculateMaxLicenceCount:Int(licenceCount:Int, currentMax:Int, isRegularTapes:Int = True)
		Local newSize:Int = 8
		If licenceCount > 8 Then newSize = 15
		If currentMax <> newSize
			If isRegularTapes
				entriesButtonPrev = null
				entriesButtonNext = null
			Else
				subEntriesButtonPrev = null
				subEntriesButtonNext = null
			EndIf
		EndIf
		Return newSize
	End Method

	Method DrawTapes:Int(filterIndex:Int=-1, mode:Int=0)
		'skip drawing tapes if no genreGroup is selected
		If filterIndex < 0 Then Return False

		If not owner then Return False

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner)
		Local licences:TList = GetLicences(owner, filterIndex)

		maxLicencesPerPage = RecalculateMaxLicenceCount(licences.Count(), maxLicencesPerPage)

		SetEntriesPages( int(ceil(licences.Count() / Float(maxLicencesPerPage))) )

		Local currSprite:TSprite
		'maybe it has changed since initialization
		'it DOES change - causing the next page button width to increase and leave the rectangle
		'was the wrong sprite referenced?
		'what should be the effect of reading the size again?
		entrySize.CopyFrom( GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.GetDimension() )
		Local currY:Int = GetEntriesRect().y
		Local currX:Int = GetEntriesRect().x
		Local font:TBitmapFont = GetBitmapFont("Default", 9)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()


		'draw slots, even if empty
		local startIndex:int = (entriesPage-1)*maxLicencesPerPage
		local endIndex:int = entriesPage*maxLicencesPerPage -1
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
				'planned is more important than new, except for series parents
				If licence.GetSubLicenceCount() > 0 And programmeCollection.JustAddedLicencesContains(licence)
					entryDrawType = "new"
					tapeDrawType = "new"
				Else If licence.IsProgrammePlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				Else If programmeCollection.JustAddedLicencesContains(licence)
					entryDrawType = "new"
					tapeDrawType = "new"
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

				'mark not available licences (eg. broadcast limits exceeded or not yet released)
				if not licence.IsAvailable()
					setAlpha 0.5 * oldColA
					SetColor 255,200,200
				endif


				'active - if tape is the currently used
				If i = currentEntry Then tapeDrawType = "hovered"
				'hovered - draw hover effect if hovering
				'we add 1 pixel to height - to hover between tapes too
				If THelper.MouseIn(currX, currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					tapeDrawType="hovered"
				endif


				If licence.isSingle()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				EndIf
				font.DrawBox(licence.GetTitle(), currX + 22, currY + 2, 145,15, sALIGN_LEFT_CENTER, SColor8.Black)

				SetColor(oldCol)
				SetAlpha(oldColA)
			EndIf


			'adjust mouse cursor if needed
			If clicksAllowed and THelper.MouseIn(currX, currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
				If licence and licence.IsAvailable() 
					If mode = MODE_PROGRAMMEPLANNER and licence.isSingle()
						GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL)
					ElseIf mode = MODE_ARCHIVE
						'archive vetoes picking up running programme
						Local material:TProgramme = TProgramme(GetPlayerProgrammePlan(_licencesOwner).GetProgramme(-1,-1))
						If material And material.licence = licence And material.state = TBroadcastMaterial.STATE_RUNNING
							GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL, TGameBase.CURSOR_EXTRA_FORBIDDEN)
						Else
							GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL)
						EndIf
					EndIf
				EndIf
			Endif

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
			DrawSortArea(int(GetEntriesRect().GetX()), int(GetEntriesRect().GetY()))
		endif


		'handle page buttons
		if entriesPages > 1
			local w:int = 0.5 * GetEntriesRect().GetW() - 14 - 20
			if not entriesButtonPrev
				entriesButtonPrev = new TGUIButton.Create(new SVec2I(currX + 5 , currY - 23), new SVec2I(w, 18), "<", "PLANNERLIST_PROGRAMMELIST")
				entriesButtonPrev.SetSpriteName("gfx_gui_button.datasheet")
				'manage on our own
				GuiManager.Remove(entriesButtonPrev)
			endif
			if not entriesButtonNext
				entriesButtonNext = new TGUIButton.Create(new SVec2I(Int(currX + GetEntriesRect().w - 7 - w), currY - 23), new SVec2I(w, 18), ">", "PLANNERLIST_PROGRAMMELIST")
				entriesButtonNext.SetSpriteName("gfx_gui_button.datasheet")
				GuiManager.Remove(entriesButtonNext)
			endif


			if entriesButtonPrev
				if not entriesButtonPrev.IsEnabled() then SetAlpha 0.5*oldColA
				entriesButtonPrev.Draw()
				SetAlpha oldColA
			endif
			if entriesButtonNext
				if not entriesButtonNext.IsEnabled() then SetAlpha 0.5*oldColA
				entriesButtonNext.Draw()
				SetAlpha oldColA
			endif

			font.DrawBox(entriesPage+"/" + entriesPages, currX, currY - 22, GetEntriesRect().GetW(), 20, sALIGN_CENTER_CENTER, SColor8.Black)
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


	Method UpdateTapes:Int(filterIndex:Int=-1, mode:Int)
		'skip doing something without a selected filter
		If filterIndex < 0 Then Return False

		If not owner Then Return False

		Local currY:Int = GetEntriesRect().GetY()
		Local licences:TList = GetLicences(owner, filterIndex)
		if not licences or licences.count() = 0
			SetEntriesPages( 1 )
			return False
		endif

		maxLicencesPerPage= RecalculateMaxLicenceCount(licences.Count(), maxLicencesPerPage)

		SetEntriesPages( int(ceil(licences.Count() / Float(maxLicencesPerPage))) )

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
					hoveredParentalLicence = Null

					'handled left click
					MouseManager.SetClickHandled(1)
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
					hoveredParentalLicence = Null

					'handled left click
					MouseManager.SetClickHandled(1)
				endif
			endif
		endif


		local startIndex:int = (entriesPage-1)*maxLicencesPerPage
		local endIndex:int = Min(licences.Count()-1, entriesPage*maxLicencesPerPage -1)
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
					If MOUSEMANAGER.IsClicked(1)
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
							'handled left click
							MouseManager.SetClickHandled(1)
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
			UpdateSortArea(int(GetEntriesRect().GetX()), int(GetEntriesRect().GetY()))
		endif

		Return False
	End Method


	Method DrawSubTapes:Int(parentLicence:TProgrammeLicence, mode:Int)
		If Not parentLicence Then Return False

		'retrieve only existing sub licences (ignore empty/reserved slots)
		Local subLicences:TProgrammeLicence[] = parentLicence.GetSubLicences()

		maxSubLicencesPerPage = RecalculateMaxLicenceCount(subLicences.length, maxSubLicencesPerPage, False)

		SetSubEntriesPages( int(ceil(subLicences.length / Float(maxSubLicencesPerPage))) )

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner)

		Local hoveredLicence:TProgrammeLicence = Null
		Local currSprite:TSprite
		Local currY:Int = GetSubEntriesRect().GetY()
		Local currX:Int = GetSubEntriesRect().GetX()
		Local font:TBitmapFont = GetBitmapFont("Default", 9)
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		local startIndex:int = (subEntriesPage-1)*maxSubLicencesPerPage
		local endIndex:int = subEntriesPage*maxSubLicencesPerPage -1
		'if no paging was used, hide empty slots
		'(to have consistent button coordinates we show empty slots on
		' subsequent pages)
		if subEntriesPages = 1
			endIndex = Min(subLicences.length-1, endIndex)
		endif

		Local licence:TProgrammeLicence
		For Local i:Int = startIndex to endIndex
			licence = Null
			If i < subLicences.length Then licence = subLicences[i]

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


			'switch background to "new" if the licence is a just-added-one
			For Local newLicence:TProgrammeLicence = EachIn programmeCollection.justAddedProgrammeLicences
				If licence = newLicence
					entryDrawType = "new"
					tapeDrawType = "new"
					Exit
				EndIf
			Next


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
				'mark not available licences (eg. broadcast limits exceeded or not yet released)
				if not licence.IsAvailable()
					setAlpha 0.5 * oldColA
					SetColor 255,200,200
				endif

				'== ADJUST TAPE TYPE ==
				'active - if tape is the currently used
				If i = currentSubEntry Then tapeDrawType = "hovered"
				'hovered? - draw hover effect, adjust shown mouse cursor
				If THelper.MouseIn(currX, currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
					tapeDrawType="hovered"
				endif

				If licence.isSingle()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				EndIf
				font.DrawBox("(" + licence.GetEpisodeNumber() + "/" + parentLicence.GetEpisodeCount() + ") " + licence.GetTitle(), currX + 22, currY + 2, 145,15, sALIGN_LEFT_CENTER, SColor8.Black)

				SetColor(oldCol)
				SetAlpha(oldColA)
			EndIf

			'adjust mouse cursor if needed
			If clicksAllowed and THelper.MouseIn(currX, currY + 1, int(GetEntrySize().GetX()), int(GetEntrySize().GetY()))
				If licence and licence.IsAvailable() 
					If mode = MODE_PROGRAMMEPLANNER
						GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL)
					ElseIf mode = MODE_ARCHIVE
						GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL)
					EndIf
				EndIf
			Endif
			
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
				subEntriesButtonPrev = new TGUIButton.Create(new SVec2I(currX + 5 , currY - 23), new SVec2I(w, 18), "<", "PLANNERLIST_PROGRAMMELIST")
				subEntriesButtonPrev.SetSpriteName("gfx_gui_button.datasheet")
				'manage on our own
				GuiManager.Remove(subEntriesButtonPrev)
			endif
			if not subEntriesButtonNext
				subEntriesButtonNext = new TGUIButton.Create(new SVec2I(Int(currX + GetSubEntriesRect().w - 7 - w), currY - 23), new SVec2I(w, 18), ">", "PLANNERLIST_PROGRAMMELIST")
				subEntriesButtonNext.SetSpriteName("gfx_gui_button.datasheet")
				GuiManager.Remove(subEntriesButtonNext)
			endif


			if subEntriesButtonPrev
				if not subEntriesButtonPrev.IsEnabled() then SetAlpha 0.5*oldColA
				subEntriesButtonPrev.Draw()
				SetAlpha oldColA
			endif
			if subEntriesButtonNext
				if not subEntriesButtonNext.IsEnabled() then SetAlpha 0.5*oldColA
				subEntriesButtonNext.Draw()
				SetAlpha oldColA
			endif
			font.DrawBox(subEntriesPage+"/" + subEntriesPages, currX, currY - 22, GetSubEntriesRect().GetW(), 20, sALIGN_CENTER_CENTER, SColor8.Black)
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

		'retrieve only existing sub licences (ignore empty/reserved slots)
		Local subLicences:TProgrammeLicence[] = parentLicence.GetSubLicences()

		maxSubLicencesPerPage = RecalculateMaxLicenceCount(subLicences.length, maxSubLicencesPerPage, False)

		SetSubEntriesPages( int(ceil(subLicences.length / Float(maxSubLicencesPerPage))) )


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

					'handled left click
					MouseManager.SetClickHandled(1)
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

					'handled left click
					MouseManager.SetClickHandled(1)
				endif
			endif
		endif


		Local currY:Int = GetSubEntriesRect().GetY() '+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

		local startIndex:int = (subEntriesPage-1)*maxSubLicencesPerPage
		local endIndex:int = Min(subLicences.length-1, subEntriesPage*maxSubLicencesPerPage -1)
		For Local i:Int = startIndex to endIndex
			Local licence:TProgrammeLicence = subLicences[i]

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
							If MOUSEMANAGER.IsClicked(1)
								'create and drag new block
								New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TProgramme.Create(licence), "programmePlanner" ).drag()
								SetOpen(0)

								'handled left click
								MouseManager.SetClickHandled(1)
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


	Method Update:Int(mode:Int)
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
			GetGenresRect() 'refresh
			If MOUSEMANAGER.IsClicked(1) And THelper.MouseIn(int(genresRect.GetX()), int(genresRect.GetY()) + genresStartY, int(genresRect.GetW()), int(genreSize.GetY())*TProgrammeLicenceFilter.GetVisibleCount())
				SetOpen(2)
				Local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
				currentGenre = Max(0, Min(visibleFilters.length-1, Floor((MouseManager.y - (genresRect.GetY() + genresStartY)) / genreSize.GetY())))

				'handled left click
				MouseManager.SetClickHandled(1)
			EndIf
		EndIf

		'if the genre is selected, also take care of its programmes
		If Self.openState >=2
			If currentgenre >= 0 Then UpdateTapes(currentgenre, mode)
			'series episodes are only available in mode 0, so no mode-param to give
			If hoveredParentalLicence Then UpdateSubTapes(hoveredParentalLicence)
		EndIf


		'react to right click
		If openState > 0 and MOUSEMANAGER.IsClicked(2)
			SetOpen( Max(0, openState - 1) )

			'avoid clicks
			'remove right click - to avoid leaving the room
			MouseManager.SetClickHandled(2)
		EndIf

		'close if clicked outside - simple mode: so big rect
		If MouseManager.isClicked(1) ' and mode=MODE_ARCHIVE
			Local closeMe:Int = True
			'in all cases the genre selector is opened
			If GetGenresRect().containsXY(MouseManager.x, MouseManager.y) Then closeMe = False
			'check tape rect
			If openState >=2 And GetEntriesRect().containsXY(MouseManager.x, MouseManager.y) then closeMe = False
			'check episodetape rect
			If openState >=3 And GetSubEntriesRect().containsXY(MouseManager.x, MouseManager.y)  Then closeMe = False

			If closeMe
				SetOpen(0)

				'handled left click
				MouseManager.SetClickHandled(1)
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

