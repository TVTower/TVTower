SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "Dig/base.gfx.gui.list.base.bmx"
Import "common.misc.gamegui.bmx"
Import "game.roomhandler.base.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.newsagency.bmx"
Import "game.gameconfig.bmx"

TGUINews.textBlockDrawSettings.data.lineHeight = 12
TGUINews.textBlockDrawSettings.data.boxDimensionMode = 0

'News room
Type RoomHandler_News extends TRoomHandler
	Global PlannerToolTip:TTooltip
	Global NewsGenreButtons:TGUIButton[6]
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

	'sorting
	Field ListSortMode:int = 0
	Field ListSortInAscendingOrder:int = True
	Global ListSortVisible:int = False
	Global sortButtonPos:TVec2D = new TVec2D(373,2)
	Global newsSortKeys:int[] = [0,1,2,3]
	'age: newest on top (biggest date number)
	'price: cheapest on top (lowest number on top)
	'topicality: highest value on top on top (highest number on top)
	'paid: paid on top (paid = 1, unpaid = 0 - highest number on top)
	Global newsSortDefaultOrder:int[] = [False, True, False, False]
	Global newsSortKeysTooltips:TTooltipBase[4]
	'Price, Published time, topicality, bought/not bought
	Global newsSortSymbols:string[] = ["gfx_datasheet_icon_duration", "gfx_datasheet_icon_money", "gfx_datasheet_icon_topicality", "gfx_datasheet_icon_ok"]

	global LS_newsplanner:TLowerString = TLowerString.Create("newsplanner")
	global LS_newsroom:TLowerString = TLowerString.Create("newsroom")

	Global _instance:RoomHandler_News
	Global _eventListeners:TEventListenerBase[]
	Global showDeleteHintTimer:Long = 0
	'how long to display?
	Global showDeleteHintTime:int = 4000
	'time to wait until hint is shown
	Global showDeleteHintDwellTime:Int = 1000

	Const SORT_BY_AGE:int = 0
	Const SORT_BY_PRICE:int = 1
	Const SORT_BY_TOPICALITY:int = 2
	Const SORT_BY_PAID:int = 3


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


		Select GameRules.newsStudioSortNewsBy
			case "price"
				SetAvailableNewsListSort(SORT_BY_PRICE)
			case "topicality"
				SetAvailableNewsListSort(SORT_BY_TOPICALITY)
			case "paid"
				SetAvailableNewsListSort(SORT_BY_PAID)
			default
				SetAvailableNewsListSort(SORT_BY_AGE)
		End Select


		For local i:int = 0 until newsSortKeysTooltips.length
			Select i
				case SORT_BY_AGE
					newsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("NEWS_SORT_AGE")), new TRectangle.Init(0,0,-1,-1))
				case SORT_BY_PRICE
					newsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("NEWS_SORT_PRICE")), new TRectangle.Init(0,0,-1,-1))
				case SORT_BY_TOPICALITY
					newsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("NEWS_SORT_TOPICALITY")), new TRectangle.Init(0,0,-1,-1))
				case SORT_BY_PAID
					newsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", StringHelper.UCFirst(GetLocale("NEWS_SORT_PAID")), new TRectangle.Init(0,0,-1,-1))
				Default
					newsSortKeysTooltips[i] = new TGUITooltipBase.Initialize("", "UNKNOWN SORT MODE: " + i, new TRectangle.Init(0,0,-1,-1))
			End Select
			newsSortKeysTooltips[i].parentArea = new TRectangle.Init(0,0,30,30)
			'with bigger mouse cursor we need to ensure it could be read - so move it
			'away from the buttons
			'newsSortKeysTooltips[i].SetOrientationPreset("BOTTOM", 10)
			'alternatively display the tooltip to the right (or left)
			newsSortKeysTooltips[i].SetOrientationPreset("RIGHT", 5)

		Next

		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		'=== create gui elements if not done yet
		if not NewsGenreButtons[0]
			'create genre buttons
			'ATTENTION: We could do this in order of The NewsGenre-Values
			'           But better add it to the buttons.data-property
			'           for better checking
			NewsGenreButtons[0]	= new TGUIButton.Create( new SVec2I(13, 194), New SVec2I(0,0), GetLocale("NEWS_TECHNICS_MEDIA"), "newsroom")
			NewsGenreButtons[1]	= new TGUIButton.Create( new SVec2I(58, 194), New SVec2I(0,0), GetLocale("NEWS_POLITICS_ECONOMY"), "newsroom")
			NewsGenreButtons[2]	= new TGUIButton.Create( new SVec2I(103, 194), New SVec2I(0,0), GetLocale("NEWS_SHOWBIZ"), "newsroom")
			NewsGenreButtons[3]	= new TGUIButton.Create( new SVec2I(13, 239), New SVec2I(0,0), GetLocale("NEWS_SPORT"), "newsroom")
			NewsGenreButtons[4]	= new TGUIButton.Create( new SVec2I(58, 239), New SVec2I(0,0), GetLocale("NEWS_CURRENTAFFAIRS"), "newsroom")
			NewsGenreButtons[5]	= new TGUIButton.Create( new SVec2I(103, 239), New SVec2I(0,0), GetLocale("NEWS_CULTURE"), "newsroom")
			For local i:int = 0 to 5
				NewsGenreButtons[i].SetAutoSizeMode( TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE )
				'adjust width according sprite dimensions
				NewsGenreButtons[i].SetSpriteName("gfx_news_btn" + i)
				'disable drawing of caption
				NewsGenreButtons[i].caption.Hide()
			Next

			'create the lists in the news planner
			'we add 2 pixel to the height to make "auto scrollbar" work better
			guiNewsListAvailable = new TGUINewsList.Create(new SVec2I(14,13), new SVec2I(Int(GetSpriteFromRegistry("gfx_news_sheet0").area.w), Int(4*GetSpriteFromRegistry("gfx_news_sheet0").area.h)), "Newsplanner")
			guiNewsListAvailable.SetAcceptDrop("TGUINews")
			'use a custom sort
'HEUTE
'			guiNewsListAvailable.SetAutosortItems(False)
			guiNewsListAvailable._autoSortFunction = TNews.SortByPublishedDate

			guiNewsListAvailable.SetSize(guiNewsListAvailable.rect.GetW() + guiNewsListAvailable.guiScrollerV.rect.GetW() + 8,guiNewsListAvailable.rect.GetH())
			guiNewsListAvailable.guiEntriesPanel.minSize.SetXY(GetSpriteFromRegistry("gfx_news_sheet0").area.GetW(),356)
			'move down scroller a bit
			guiNewsListAvailable.guiScrollerV.SetOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiNewsListAvailable.guiScrollerV.Move(13, 45)
			guiNewsListAvailable.guiScrollerV.SetSize(0, guiNewsListAvailable.guiScrollerV.rect.GetH() - 35)

			guiNewsListUsed = new TGUINewsSlotList.Create(new SVec2I(419,104), new SVec2I(Int(GetSpriteFromRegistry("gfx_news_sheet0").area.w), Int(3*GetSpriteFromRegistry("gfx_news_sheet0").area.h)), "Newsplanner")
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
		NewsGenreButtons[5].data.AddNumber("newsGenre", TVTNewsGenre.CULTURE)


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]


		'=== register event listeners
		'we are interested in the genre buttons
		for local i:int = 0 until NewsGenreButtons.length
			_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onHoverNewsGenreButtons, NewsGenreButtons[i]) ]
			_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnDraw, onDrawNewsGenreButtons, NewsGenreButtons[i]) ]
			_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickNewsGenreButtons, NewsGenreButtons[i]) ]
		Next


		'if the player visually manages the blocks, we need to handle the events
		'so we can inform the programmeplan about changes...
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnTryDrop, onTryDropNews, "TGUINews") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnFinishDrop, onDropNews, "TGUINews") ]
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickNews, "TGUINews") ]

		'we want to get informed if the news situation changes for a user
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_SetNews, onChangeNews) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammePlan_RemoveNews, onChangeNews) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_AddNews, onChangeNews) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProgrammeCollection_RemoveNews, onChangeNews) ]
		'we want to know if we hover a specific block
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverNews, "TGUINews") ]

		'figure enters screen - reset the guilists, limit listening to the 4 rooms
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterNewsPlannerScreen, plannerScreen) ]
		'also we want to interrupt leaving a room with dragged items
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnTryLeave, onTryLeaveNewsPlannerScreen, plannerScreen) ]

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
		If GUIManager.ListDragged.count() > 0
			For local obj:TGUINews = eachIn GuiManager.ListDragged.Copy()
				obj.dropBackToOrigin()
				'successful or not - get rid of the gui element
				obj.Remove()
			Next
		EndIf

		return abortedAction
	End Method


	Function IsMyScreen:Int(screen:TScreen)
		if not screen then return False
		if screen.name = "screen_newsstudio_newsplanner" then return True
		if screen.name = "screen_newsstudio" then return True

		return False
	End Function


	Function IsMyRoom:Int(room:TRoomBase)
		For Local i:Int = 1 To 4
			If room = GetRoomCollection().GetFirstByDetails("news", "", i) Then Return True
		Next
		Return False
	End Function


	'this sorts the news list and recreates the gui
	Method SetAvailableNewsListSort(sortMode:int, sortInAscendingOrder:int = True)
		if guiNewsListAvailable

			guiNewsListAvailable._autoSortInAscendingOrder = sortInAscendingOrder
			Select sortMode
				Case SORT_BY_AGE
					guiNewsListAvailable._autoSortFunction = SortListItemByPublishedDate
				Case SORT_BY_PRICE
					guiNewsListAvailable._autoSortFunction = SortListItemByPrice
				Case SORT_BY_PAID
					guiNewsListAvailable._autoSortFunction = SortListItemByIsPaid
				Case SORT_BY_TOPICALITY
					guiNewsListAvailable._autoSortFunction = SortListItemByTopicality
				default
					guiNewsListAvailable._autoSortFunction = SortListItemByPublishedDate
			End select

			if ListSortMode <> sortMode or ListSortInAscendingOrder <> sortInAscendingOrder
				RemoveAllGuiElements()
				haveToRefreshGuiElements = True
			endif
		endif

		ListSortMode = sortMode
		ListSortInAscendingOrder = sortInAscendingOrder
	End Method


	Method onSaveGameBeginLoad:int( triggerEvent:TEventBase ) override
		'for further explanation of this, check
		'RoomHandler_Office.onSaveGameBeginLoad()

		hoveredGuiNews = null
		draggedGuiNews = null

		RemoveAllGuiElements()
	End Method


	Method onSaveGameLoad:int( triggerEvent:TEventBase ) override
		'reassign sorting-function to GUI
		SetAvailableNewsListSort(ListSortMode, ListSortInAscendingOrder)
	End Method



	'===================================
	'News: room screen
	'===================================

	Function onDrawNews:int( triggerEvent:TEventBase )
		GUIManager.Draw( LS_newsroom )

		'no further interaction for other players newsrooms
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		'if not IsPlayersRoom(room) then return False

		If PlannerToolTip Then PlannerToolTip.Render()
		If NewsGenreTooltip then NewsGenreTooltip.Render()

		'pinwall - allowed for all players (with key) as it is a 
		'"watch only" for others
		If THelper.MouseIn(167,60,240,160) 'AND IsPlayersRoom(room)
			GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
		EndIf

		if TVTDebugInfo
			SetColor 0,0,0
			SetAlpha 0.6
			DrawRect(15,35, 380, 220)
			SetAlpha 1.0
			SetColor 255,255,255
			GetBitmapFont("default", 12).DrawSimple("Neue Startnews:", 20, 40)
			GetBitmapFont("default", 12).DrawSimple("Neue Folgenews (in Liste):", 20+130, 40)

			local upcomingCount:int[TVTNewsGenre.count+1]
			local upcomingEvent:TNewsEvent[TVTNewsGenre.count+1]
			local upcomingCountTotal:int = 0
			For local n:TNewsEvent = EachIn GetNewsEventCollection().GetUpcomingNewsList()
				upcomingCountTotal :+ 1
				upcomingCount[n.GetGenre()] :+ 1
				local g:int = n.GetGenre()
				if not upcomingEvent[g]
					upcomingEvent[g] = n
				elseif upcomingEvent[g].happenedTime > n.happenedTime 'new one is earlier
					upcomingEvent[g] = n
				endif
			Next

			For local i:int = 0 until TVTNewsGenre.count
				GetBitmapFont("default", 10).DrawSimple(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(i))+":  "+GetWorldTime().GetFormattedTime(GetNewsAgency().NextEventTimes[i]), 20, 60 + 24*i)

				if upcomingEvent[i]
					GetBitmapFont("default", 10).DrawSimple(GetWorldTime().GetFormattedDate(upcomingEvent[i].happenedTime)+" ( "+upcomingCount[i]+"x )", 20+130, 60 + 24*i)
					GetBitmapFont("default", 10).DrawBox(upcomingEvent[i].GetTitle(), 20+130, 60 + 24*i + 12, 200, 15, SColor8.Black)
				else
					GetBitmapFont("default", 10).DrawSimple("-- ( "+upcomingCount[i]+"x )", 20+130, 60 + 24*i)
					GetBitmapFont("default", 10).DrawSimple("--", 20+130, 60 + 24*i +12)
				endif
			Next


			local agency:TNewsAgency = GetNewsAgency()
			GetBitmapFont("default", 12).DrawSimple("Terrorlevel:", 20, 220)
			GetBitmapFont("default", 10).DrawSimple("a) " + MathHelper.NumberToString(100*agency.terroristAggressionLevelProgress[0],2)+"%  " + agency.terroristAggressionLevel[0]+"/"+agency.terroristAggressionLevelMax, 20, 235)
			GetBitmapFont("default", 10).DrawSimple("b) " + MathHelper.NumberToString(100*agency.terroristAggressionLevelProgress[1],2)+"%  " + agency.terroristAggressionLevel[1]+"/"+agency.terroristAggressionLevelMax, 20+130, 235)

		endif
	End Function


	Function onUpdateNews:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0


		If not IsPlayersRoom(room)
			For local n:TGUIButton = EachIn NewsGenreButtons
				n.SetOption(GUI_OBJECT_CLICKABLE, False)
			Next
		Else
			For local n:TGUIButton = EachIn NewsGenreButtons
				n.SetOption(GUI_OBJECT_CLICKABLE, True)
			Next
		EndIf
	
		'store current room for later access (in guiobjects)
		currentRoom = room

		GUIManager.Update( LS_newsroom )

		If PlannerToolTip Then PlannerToolTip.Update()
		If NewsGenreTooltip Then NewsGenreTooltip.Update()

		'pinwall
		If THelper.MouseIn(167,60,240,160)
			If not PlannerToolTip Then PlannerToolTip = TTooltip.Create(GetLocale("ROOM_NEWSPLANNER"), GetLocale("MANAGE_BROADCASTED_NEWS"), 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()

			If MouseManager.IsClicked(1)
				'handled left click
				MouseManager.SetClickHandled(1)
				ScreenCollection.GoToSubScreen("screen_newsstudio_newsplanner")
			endif
		endif

		'no further interaction for other players newsrooms
		if not IsPlayersRoom(room) then return False

		'...
	End Function


	'could handle the buttons in one function ( by comparing triggerEvent._trigger )
	'onHover: handle tooltip
	Function onHoverNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0
		
		Local playersRoom:Int = IsPlayersRoom(room)
		
		'how much levels do we have?
		local level:int = 0
		local genre:int = -1
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				genre = button.data.GetInt("newsGenre", i)
				level = GetPlayerBase(room.owner).GetNewsAbonnement( genre )
				exit
			endif
		Next

		if not NewsGenreTooltip then NewsGenreTooltip = TTooltip.Create("genre", "abonnement", 180,100 )
		NewsGenreTooltip.SetMinTitleAndContentWidth(180)
		NewsGenreTooltip.enabled = 1
		'refresh lifetime
		NewsGenreTooltip.Hover()

		'move the tooltip
		NewsGenreTooltip.area.SetXY(Max(21,button.rect.x + button.rect.w), button.rect.y-30)

		If level = 0
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
			if not playersRoom
				NewsGenreTooltip.content = ""
			else
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1:~t"+ GetFormattedCurrency(TNewsAgency.GetNewsAbonnementPrice(room.owner, genre, level+1))+"/"+getLocale("DAY")
			endif
		Else
			NewsGenreTooltip.title = button.caption.GetValue()+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+level
			if not playersRoom
				NewsGenreTooltip.content = ""
			else
				NewsGenreTooltip.content = getLocale("NEWSSTUDIO_CURRENT_SUBSCRIPTION_LEVEL")+":~t"+ GetFormattedCurrency(TNewsAgency.GetNewsAbonnementPrice(room.owner, genre, level))+"/"+getLocale("DAY")+"~n"
				if level = GameRules.maxAbonnementLevel
					NewsGenreTooltip.content :+ getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")
				Else
					NewsGenreTooltip.content :+ getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+":~t"+ GetFormattedCurrency(TNewsAgency.GetNewsAbonnementPrice(room.owner, genre, level+1))+"/"+getLocale("DAY")
				EndIf
			endif
		EndIf
		if playersRoom
			if GetPlayerBase().GetNewsAbonnementDaysMax(genre) > level
				NewsGenreTooltip.content :+ "~n~n"
				local tip:String = getLocale("NEWSSTUDIO_YOU_ALREADY_USED_LEVEL_AND_THEREFOR_PAY")
				tip = tip.Replace("%MAXLEVEL%", GetPlayerBase().GetNewsAbonnementDaysMax(genre))
				tip = tip.Replace("%TOPAY%", GetFormattedCurrency(TNewsAgency.GetNewsAbonnementPrice(room.owner, genre, GetPlayerBase().GetNewsAbonnementDaysMax(genre))))
				NewsGenreTooltip.content :+ getLocale("HINT")+": " + tip
			endif
		endif
	End Function


	Function onClickNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

		'only react to left clicks
		if triggerEvent.GetData().getInt("button",0) <> 1 then return false

		'wrong room? go away!
		if room.owner <> GetPlayerBaseCollection().playerID then return 0

		'increase the abonnement
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				GetPlayerBase().IncreaseNewsAbonnement( button.data.GetInt("newsGenre", i) )
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
		For local i:int = 0 until NewsGenreButtons.length
			if button = NewsGenreButtons[i]
				level = GetPlayerBase(room.owner).GetNewsAbonnement( button.data.GetInt("newsGenre", i) )
				exit
			endif
		Next

		'draw the levels
		For Local i:Int = 0 to level-1
			SetAlpha 0.4
			SetColor 0,0,0
			DrawRect( button.rect.GetX()+3+i*12, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -5, 9,1)
			SetAlpha 0.6
			SetColor 255,255,255
			DrawRect( button.rect.GetX()+3+i*12, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -9, 9,5)
		Next
		For Local i:Int = Max(0,level-1) to 2
			SetAlpha 0.2
			SetColor 0,0,0
			DrawRect( button.rect.GetX()+3+i*12, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -5, 9,1)
			SetColor 255,255,255
			DrawRect( button.rect.GetX()+3+i*12, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -9, 9,1)
			DrawRect( button.rect.GetX()+3+i*12, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -9, 1,5)
			DrawRect( button.rect.GetX()+3+i*12 + 9, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -9, 1,5)
			DrawRect( button.rect.GetX()+3+i*12, button.rect.GetY()+ GetSpriteFromRegistry(button.GetSpriteName()).area.GetH() -9+4, 9,1)
		Next

		SetColor 255,255,255
		SetAlpha 1.0


		For local i:int = 0 until NewsGenreButtons.length
			If NewsGenreButtons[i].IsHovered() AND IsPlayersRoom(room)
				GetGameBase().SetCursor(TGameBase.CURSOR_INTERACT)
				exit
			EndIf
		Next
	End Function



	'===================================
	'News: NewsPlanner screen
	'===================================

	Function onUpdateNewsPlanner:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'store current room for later access (in guiobjects)
		currentRoom = room

		ListSortVisible = False
		If not draggedGuiNews
			'show and react to mouse-over-sort-buttons
			'HINT: does not work for touch displays
			local skin:TDatasheetSkin = GetDatasheetSkin("default")
			local boxWidth:int = 28 + newsSortKeys.Length * 32
			local boxHeight:int = 35 + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
			local contentX:int = sortButtonPos.GetIntX() + skin.GetContentX()

			if THelper.MouseIn(sortButtonPos.GetIntX(), sortButtonPos.GetIntY(), boxWidth, boxHeight)
				ListSortVisible = True

				if MouseManager.isClicked(1)
					For local i:int = 0 to newsSortKeys.length-1
						If THelper.MouseIn(contentX + 5 + i*32, sortButtonPos.GetIntY() + 12, 28, 27)
							'sort now
							if GetInstance().ListSortMode <> newsSortKeys[i]
								GetInstance().SetAvailableNewsListSort(newsSortKeys[i], newsSortDefaultOrder[i])
							else
								'switch order
								GetInstance().SetAvailableNewsListSort(GetInstance().ListSortMode, not GetInstance().ListSortInAscendingOrder)
							endif

							'handled click
							MouseManager.SetClickHandled(1)
							exit
						endif
					Next
				endif
			endif

			'move tooltips
			For local i:int = 0 to newsSortKeys.length-1
				if newsSortKeysTooltips[newsSortKeys[i]]
					newsSortKeysTooltips[newsSortKeys[i]].parentArea.SetXYWH(contentX + 5 + i*32, sortButtonPos.GetIntY() + 11, 28,27)
				endif
			Next
		endif

		'update tooltips
		For local i:int = 0 to newsSortKeys.length-1
			newsSortKeysTooltips[newsSortKeys[i]].Update()
		Next


		'delete unused and create new gui elements
		if haveToRefreshGuiElements then GetInstance().RefreshGUIElements()

		'reset dragged block - will get set automatically on gui-update
		hoveredGuiNews = null
		draggedGuiNews = null

		'general newsplanner elements
		GUIManager.Update( LS_newsplanner )

		'no GUI-interaction for other players rooms
		'if not IsPlayersRoom(room) then return False

	End Function


	Function onDrawNewsPlanner:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'store current room for later access (in guiobjects)
		currentRoom = room

		'create sign text image
		if not newsPlannerTextImage
			newsPlannerTextImage = TFunctions.CreateEmptyImage(310, 60)
			'render to image
			TBitmapFont.SetRenderTarget(newsPlannerTextImage)

			GetBitmapFont("default", 18).DrawBox(GetLocale("NEWSPLANSIGN_TO_THE_TEAM")+"~n|b|"+ GetLocale("NEWSPLANSIGN_SEND_THE_FOLLOWING_NEWS")+"|/b|", 0, 0, 300, 50, sALIGN_CENTER_CENTER, new SColor8(100, 100, 100))

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(null)
		endif
		SetRotation(-2.1)
		DrawImage(newsPlannerTextImage, 450, 30)
		SetRotation(0)

		SetColor 255,255,255  'normal

		If not draggedGuiNews
			GUIManager.Draw( LS_newsplanner )
		endif

		local availableSortKeys:int[]
		if not ListSortVisible
			availableSortKeys :+ [GetInstance().ListSortMode]
		else
			availableSortKeys :+ newsSortKeys
		endif

		local skin:TDatasheetSkin = GetDatasheetSkin("default")
		local boxWidth:int = 28 + availableSortKeys.length * 32
		local boxHeight:int = 35 + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		local contentX:int = sortButtonPos.GetIntX() + skin.GetContentX()
		if ListSortVisible then skin.RenderContent(sortButtonPos.GetIntX() + 8, sortButtonPos.GetIntY() + skin.GetContentY() - 5, skin.GetContentW(boxWidth), 42, "1_top")


		For local i:int = 0 until availableSortKeys.length
			local spriteName:string = "gfx_gui_button.datasheet"
			if GetInstance().ListSortMode = availableSortKeys[i]
				spriteName = "gfx_gui_button.datasheet.positive"
			endif

			if ListSortVisible and THelper.MouseIn(contentX + 5 + i*32, sortButtonPos.GetIntY() + 12, 28, 27)
				spriteName :+ ".hover"
			endif
			GetSpriteFromRegistry(spriteName).DrawArea(contentX + 5 + i*32, sortButtonPos.GetIntY() + 12, 28,27)
			GetSpriteFromRegistry(newsSortSymbols[ availableSortKeys[i] ]).Draw(contentX + 7 + i*32, sortButtonPos.GetIntY() + 14)
		Next

		'overlay of buttons
		if ListSortVisible then skin.RenderBorder(sortButtonPos.GetIntX(), sortButtonPos.GetIntY(), boxWidth, boxHeight)

		'tooltips
		For local i:int = 0 until availableSortKeys.length
			if newsSortKeysTooltips[availableSortKeys[i]]
				newsSortKeysTooltips[availableSortKeys[i]].Render()
				
				'overlay to check if coords are OK
				'DrawRect(contentX + 5 + i*32, sortButtonPos.GetIntY() + 11, 28,27)
			endif
		Next


		'if there are dragged ones - draw ALL after sort widget
		If draggedGuiNews
			GUIManager.Draw( LS_newsplanner )
		endif



		if draggedGuiNews
			'wait to show hint
			if showDeleteHintTimer = 0
				showDeleteHintTimer = Time.GetTimeGone() + showDeleteHintDwellTime
			'remove hint ? - no keep invisible until nothing is dragged
			'(like a reset)
			'elseif showDeleteHintTimer + showDeleteHintTime < Time.GetTimeGone()
				'showDeleteHintTimer = 0
			'show hint
			elseif showDeleteHintTimer < Time.GetTimeGone() and showDeleteHintTime + showDeleteHintTimer > Time.GetTimeGone()
				local oldA:float = Getalpha()
				SetAlpha oldA * 7
				GetBitmapFont("default", 12, BOLDFONT).DrawBox(GetLocale("RIGHT_CLICK_TO_DELETE"), draggedGuiNews.GetScreenRect().GetX(), draggedGuiNews.GetScreenRect().GetY2() + 3, draggedGuiNews.GetScreenRect().GetW(), 30, sALIGN_CENTER_TOP, SColor8.White, EDrawTextEffect.Shadow, -1)
				SetAlpha oldA
			endif
		else
			showDeleteHintTimer = 0
		endif

	End Function


	Function onChangeNews:int( triggerEvent:TEventBase )
		'is it the plan of the room owner?
		Local plan:TPlayerProgrammePlan = TPlayerProgrammePlan(triggerEvent.GetSender())
		Local collection:TPlayerProgrammeCollection = TPlayerProgrammeCollection(triggerEvent.GetSender())
		Local owner:int = 0
		if plan then owner = plan.owner
		if collection then owner = collection.owner

		If Not owner or not currentRoom Or owner <> currentRoom.owner Then Return False

		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'our plan?
		'something changed -- refresh  gui elements
		haveToRefreshGuiElements = True 'RefreshGuiElements()
	End Function


	Function SortNewsList(list:TList, mode:int = -1)
		if not list then return

		if mode = -1 then mode = GetInstance().ListSortMode

		Select mode
			Case SORT_BY_AGE
				list.sort(GetInstance().ListSortInAscendingOrder, TNews.SortByPublishedDate)
			Case SORT_BY_PRICE
				list.sort(not GetInstance().ListSortInAscendingOrder, TNews.SortByPrice)
			Case SORT_BY_PAID
				list.sort(not GetInstance().ListSortInAscendingOrder, TNews.SortByIsPaid)
			Case SORT_BY_TOPICALITY
				list.sort(not GetInstance().ListSortInAscendingOrder, TNews.SortByTopicality)
			default
				list.sort(GetInstance().ListSortInAscendingOrder, TNews.SortByPublishedDate)
		End select
	End Function


	'deletes all gui elements (eg. for rebuilding)
	Function RemoveAllGuiElements:int()
		guiNewsListAvailable.emptyList()
		guiNewsListUsed.emptyList()

		If GUIManager.ListDragged.count() > 0
			For local guiNews:TGuiNews = eachin GuiManager.listDragged.Copy()
				guiNews.remove()
				guiNews = null
			Next
		EndIf

		haveToRefreshGuiElements = True
	End Function


	Function RefreshGuiElements:int()
		' skip refresh until currentRoom is set
		' (eg. after first update/draw if the game was saved in the 
		'  planner screen)
		If not currentRoom Then Return False
		
		local owner:int = currentRoom.owner
		
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
				'Ronny: should not be needed, as news are removed from the
				'       collection when they got added to the news show
				if not GetPlayerProgrammePlan(owner).HasNews(news)
					local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
					guiNews.SetNews(news)
					guiNewsListAvailable.AddItem(guiNews)
				endif
			endif
		Next


		For Local i:int = 0 to GetPlayerProgrammePlan(owner).news.length - 1
			local news:TNews = TNews(GetPlayerProgrammePlan(owner).GetNewsAtIndex(i))
			'skip if news is dragged
			if news and draggedNewsList.contains(news) then continue

			if news and not guiNewsListUsed.ContainsNews(news)
				local guiNews:TGUINews = new TGUINews.Create(null,null, news.GetTitle())
				guiNews.SetNews(news)
				guiNewsListUsed.AddItem(guiNews, string(i))
			endif
		Next


		'add/remove ability for interaction 
		local canInteract:Int = (GetPlayerBaseCollection().playerID = currentRoom.owner)
		For local guiNews:TGuiNews = eachin guiNewsListAvailable.entries
			guiNews.SetOption(GUI_OBJECT_CLICKABLE, canInteract)
		Next
		For local guiNews:TGuiNews = eachin guiNewsListUsed._slots
			guiNews.SetOption(GUI_OBJECT_CLICKABLE, canInteract)
		Next

		
		haveToRefreshGuiElements = FALSE
	End Function



	Function SortListItemByName:Int(o1:Object, o2:Object)
		if not TGUINews(o1) Then Return -1
		if not TGUINews(o2) Then Return 1
		return TGUINews(o1).news.CompareByName(TGUINews(o2).news)
	End Function


	Function SortListItemByPrice:Int(o1:Object, o2:Object)
		if not TGUINews(o1) Then Return -1
		if not TGUINews(o2) Then Return 1
		Return TGUINews(o1).news.CompareByPrice(TGUINews(o2).news)
	End Function


	Function SortListItemByPublishedDate:Int(o1:Object, o2:Object)
		if not TGUINews(o1) Then Return -1
		if not TGUINews(o2) Then Return 1
		Return TGUINews(o1).news.CompareByPublishedDate(TGUINews(o2).news)
	End Function


	Function SortListItemByIsPaid:Int(o1:Object, o2:Object)
		if not TGUINews(o1) Then Return -1
		if not TGUINews(o2) Then Return 1
		Return TGUINews(o1).news.CompareByIsPaid(TGUINews(o2).news)
	End Function


	Function SortListItemByTopicality:Int(o1:Object, o2:Object)
		if not TGUINews(o1) Then Return -1
		if not TGUINews(o2) Then Return 1
		Return TGUINews(o1).news.CompareByTopicality(TGUINews(o2).news)
	End Function



	'we need to know whether we dragged or hovered an item - so we
	'can react to right clicks ("forbid room leaving")
	Function onMouseOverNews:int( triggerEvent:TEventBase )
		if not CheckObservedFigureInRoom("news") then return FALSE

		local item:TGUINews = TGUINews(triggerEvent.GetSender())
		if item = Null then return FALSE

		hoveredGuiNews = item
		'only handle dragged for the real player
		if CheckPlayerObservedAndInRoom("news")
			if item.isDragged() then draggedGuiNews = item
		endif

		return TRUE
	End Function


	'in case of right mouse button click we want to remove the
	'block from the player's programmePlan
	Function onClickNews:int(triggerEvent:TEventBase)
		if not CheckPlayerObservedAndInRoom("news") then return FALSE

		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiNews:TGUINews= TGUINews(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiNews or not guiNews.isDragged() then return FALSE

		'remove from plan (with addBackToCollection=FALSE) and collection
		if GetPlayerBaseCollection().IsPlayer(guiNews.news.owner)
			'avoid calling this for old savegames (guid-duplication bug)
			'GetPlayerProgrammePlan(guiNews.news.owner).RemoveNewsByGUID(guiNews.news.GetGUID(), FALSE)
			'and meanwhile check "objects"
			GetPlayerProgrammePlan(guiNews.news.owner).RemoveNews(guiNews.news,-1, FALSE)

			GetPlayerProgrammeCollection(guiNews.news.owner).RemoveNews(guiNews.news)
		endif

		'remove gui object
		guiNews.remove()
		guiNews = null

		'avoid clicks
		'remove right click - to avoid leaving the room
		MouseManager.SetClickHandled(2)
	End Function


	Function onTryDropNews:int(triggerEvent:TEventBase)
		local guiNews:TGUINews = TGUINews( triggerEvent._sender )

		if guiNews and GetPlayerBase().getPlayerId() <> guiNews.news.owner
			triggerEvent.setVeto(true)
		endIf

		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNews or not receiverList then return FALSE

		if not GetPlayerBaseCollection().IsPlayer(guiNews.news.owner) return False
		'prevent using news that cannot be afforded
		if receiverList = guiNewsListUsed
			if Not guiNews.news.paid and Not GetPlayerBase().getFinance().canAfford(guiNews.news.GetPrice( GetPlayerBase().playerID ))
				triggerEvent.setVeto(true)
			endIf
		endif
	End Function


	Function onDropNews:int(triggerEvent:TEventBase)
		local guiNews:TGUINews = TGUINews( triggerEvent._sender )
		local receiverList:TGUIListBase = TGUIListBase( triggerEvent._receiver )
		if not guiNews or not receiverList then return FALSE

		if not GetPlayerBaseCollection().IsPlayer(guiNews.news.owner) return False

		if receiverList = guiNewsListAvailable
			GetPlayerProgrammePlan(guiNews.news.owner).RemoveNewsByGUID(guiNews.news.GetGUID(), TRUE)
		elseif receiverList = guiNewsListUsed
			local slot:int = -1
			'check drop position
			local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D(-1,-1)))
			if coord then slot = guiNewsListUsed.GetSlotByCoord(coord)
			if slot = -1 then slot = guiNewsListUsed.getSlot(guiNews)

			'this may also drag a news that occupied that slot before
			GetPlayerProgrammePlan(guiNews.news.owner).SetNews(guiNews.news, slot)
		endif
	End Function


	'clear the guilist for the suitcase if a player enters
	'screens are only handled by real players
	Function onEnterNewsPlannerScreen:int(triggerEvent:TEventBase)
		'empty the guilist / delete gui elements
		RemoveAllGuiElements()
		haveToRefreshGuiElements = True
	End Function


	'override to do same check as if leaving the planning screen
	Method onTryLeaveRoom:Int( triggerEvent:TEventBase )
		'non players can always leave
		local figure:TFigure = TFigure(triggerEvent.GetSender())
		if not figure or not figure.playerID then return FALSE
		if not IsRoomOwner(figure, TRoom(triggerEvent.GetReceiver())) then return False

		'=== FOR ALL PLAYERS ===
		'


		'=== FOR WATCHED PLAYERS ===
		if IsObservedFigure(figure)
			'as long as onTryLeaveProgrammePlannerScreen does not
			'check for specific event data... just forward the event
			return onTryLeaveNewsPlannerScreen( triggerEvent )
		endif

		return TRUE
	End Method


	Function onTryLeaveNewsPlannerScreen:int( triggerEvent:TEventBase )
		'do not allow leaving as long as we have a dragged block
		if draggedGuiNews
			triggerEvent.setVeto()
			return FALSE
		endif
		return TRUE
	End Function
End Type




Type TGUINewsList Extends TGUIListBase

    Method Create:TGUINewsList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsNews:Int(news:TNews)
		For Local guiNews:TGUINews = EachIn entries
			If guiNews.news = news Then Return True
		Next
		Return False
	End Method
End Type




Type TGUINewsSlotList Extends TGUISlotList

    Method Create:TGUINewsSlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsNews:Int(news:TNews)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local guiNews:TGUINews = TGUINews( Self.GetItemBySlot(i) )
			If guiNews And guiNews.news = news Then Return True
		Next
		Return False
	End Method
End Type



'a graphical representation of programmes/news/ads...
Type TGUINews Extends TGUIGameListItem
	Field news:TNews = Null
	Field imageBaseName:String = "gfx_news_sheet"
	Field cacheTextOverlay:TImage
	
	Global sortMode:int
	Global sortModeOrder:int = 0
	Global textBlockDrawSettings:TDrawTextSettings = new TDrawTextSettings


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGUINews(pos:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(pos, dimension, value)

		'to resize it properly
'		initAssets("gfx_news_sheet0","gfx_news_sheet0")
'  		Self.SetAsset()

		Return Self
	End Method


	Method SetNews:Int(news:TNews)
		Self.news = news
		If news
			'now we can calculate the item width
			Self.SetSize( GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).area.GetW(), GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).area.GetH() )
		EndIf

		'as the news inflicts the sorting algorithm - resort
		GUIManager.sortLists()
	End Method


	Method Compare:Int(Other:Object)
		if Other = self then return 0

		Local otherBlock:TGUINews = TGUINews(Other)
		If otherBlock
			'both items are dragged - check time
			If Self._flags & GUI_OBJECT_DRAGGED And otherBlock._flags & GUI_OBJECT_DRAGGED
				'if a drag was earlier -> move to top
				If Self._timeDragged < otherBlock._timeDragged Then Return 1
				If Self._timeDragged > otherBlock._timeDragged Then Return -1
				Return Super.Compare(Other)
			EndIf

			If Self.news And otherBlock.news
				Local publishDifference:Int = Self.news.GetPublishTime() - otherBlock.news.GetPublishTime()

				'self is newer ("later") than other
				If publishDifference>0 Then Return -1
				'self is older than other
				If publishDifference<0 Then Return 1
				'self is same age than other
				If publishDifference=0 Then Return Super.Compare(Other)
			EndIf
		EndIf

		Return Super.Compare(Other)
	End Method


	'override default draw-method to adjust mouse cursor
	Method Draw() override
		Super.Draw()

		'set mouse to "dragged"
		If isDragged()
			if not news.paid and not GetPlayerBase().getFinance().canAfford(news.GetPrice( GetPlayerBase().playerID )) and RoomHandler_News.getInstance().guiNewsListUsed.containsXY(MouseManager.x, MouseManager.y)
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD, TGameBase.CURSOR_EXTRA_FORBIDDEN)
			else
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
			endif
		'set mouse to "hover"
		ElseIf isHovered() and (news.owner <= 0 or news.IsOwnedByPlayer( GetPlayerBaseCollection().playerID))
			If news.IsControllable() and IsClickable()
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK)
			EndIf
		EndIf
	End Method


	Method DrawTextOverlay()
		Local screenX:Float = Int(GetScreenRect().GetX())
		Local screenY:Float = Int(GetScreenRect().GetY())

		'===== CREATE CACHE IF MISSING =====
		If Not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(rect.GetIntW(), rect.GetIntH())
'			cacheTextOverlay = CreateImage(rect.GetW(), rect.GetH(), DYNAMICIMAGE | FILTEREDIMAGE)

			'render to image
			TBitmapFont.SetRenderTarget(cacheTextOverlay)

			'default texts (title, text,...)
			GetBitmapFontManager().basefontBold.DrawBox(news.GetTitle(), 15, 0, 330, 18, sALIGN_LEFT_TOP, new SColor8(20, 20, 20))
			GetBitmapFontManager().baseFont.DrawBox(news.GetDescription(), 15, 15, 342, 50 + 10, sALIGN_LEFT_TOP, new SColor8(80, 80, 80), TGUINews.textBlockDrawSettings)

			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.3*oldAlpha
			GetBitmapFont("Default", 9).DrawBox(news.GetGenreString(), 15, 74, 120, 15, sALIGN_LEFT_TOP, new SColor8(80, 80, 80))
			SetAlpha 1.0*oldAlpha

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(Null)
		EndIf

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, screenX, screenY)
	End Method


	Method DrawContent()
		SetColor 255,255,255

		'Ronny: this flickers for the item moving "from the top" into the
		'       list while scrolling
		local sR:TRectangle = GetScreenRect()
		if sr.GetW() > 0 and sr.GetH() > 0
			Local screenX:Float = Int(GetScreenRect().GetX())
			Local screenY:Float = Int(GetScreenRect().GetY())

			Local oldAlpha:Float = GetAlpha()
			Local itemAlpha:Float = 1.0
			'fade out dragged
			If isDragged() Then itemAlpha = Min(1.0, 0.25 + 0.5^GuiManager.GetDraggedNumber(Self))

			SetAlpha oldAlpha*itemAlpha
			'background - no "_dragged" to add to name
			GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)

			'mark special news
			if news.GetNewsEvent().HasFlag(TVTNewsFlag.SPECIAL_EVENT)
				GetSpriteFromRegistry("gfx_newssheet_genreoverlay").Draw(screenX, screenY)
			endif

			'highlight hovered news (except already dragged)
			If Not isDragged() And Self = RoomHandler_News.hoveredGuiNews
				Local oldAlpha:Float = GetAlpha()
				SetBlend LightBlend
				SetAlpha 0.30*oldAlpha
				SetColor 150,150,150
				GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			EndIf

			'===== DRAW CACHED TEXTS =====
			'creates cache if needed
			DrawTextOverlay()

			'===== DRAW NON-CACHED TEXTS =====
			If Not news.paid
				GetBitmapFontManager().basefontBold.DrawBox(news.GetPrice(GetPlayerBaseCollection().playerID) + ",-", screenX + 262, screenY + 69, 90, 18, sALIGN_RIGHT_CENTER, SColor8.Black)
			Else
				SetAlpha GetAlpha()*0.75
				GetBitmapFontManager().basefontBold.DrawBox(news.GetPrice(GetPlayerBaseCollection().playerID) + ",-", screenX + 262, screenY + 69, 90, 18, sALIGN_RIGHT_CENTER, new SColor8(100, 100, 100))
				SetAlpha GetAlpha()*2.0
			EndIf

			Select GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())
				Case 0	GetBitmapFontManager().baseFont.DrawBox(GetLocale("TODAY")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 72, 140, 16, sALIGN_RIGHT_CENTER, new SColor8(80, 80, 80) )
				'Case 1	GetBitmapFontManager().baseFont.DrawBox("("+GetLocale("OLD")+") "+GetLocale("YESTERDAY")+" "+ GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, sALIGN_RIGHT_CENTER, SColor8.Black)
				'Case 2	GetBitmapFontManager().baseFont.DrawBox("("+GetLocale("OLD")+") "+GetLocale("TWO_DAYS_AGO")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, sALIGN_RIGHT_CENTER, SColor8.Black)
				Case 1	GetBitmapFontManager().baseFont.DrawBox(GetLocale("YESTERDAY")+" "+ GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 72, 140, 16, sALIGN_RIGHT_CENTER, new SColor8(80, 80, 80))
				Case 2	GetBitmapFontManager().baseFont.DrawBox(GetLocale("TWO_DAYS_AGO")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 72, 140, 16, sALIGN_RIGHT_CENTER, new SColor8(80, 80, 80))
			End Select

			SetAlpha oldAlpha * 0.5
			SetColor 140,110,110
			DrawRect(screenX + 15, screenY + 67, 152, 5)
			SetAlpha oldAlpha
			SetColor 255,255,255
			DrawRect(screenX + 16, screenY + 68, 150, 3)
			SetColor 230,150,100
			SetAlpha oldAlpha * 0.4
			DrawRect(screenX + 16, screenY + 68, news.GetNewsEvent().GetMaxTopicality()*150, 3)
			SetAlpha oldAlpha
			DrawRect(screenX + 16 + news.GetNewsEvent().GetMaxTopicality()*150 - 1, screenY + 68, 2, 3)
			SetAlpha oldAlpha
			DrawRect(screenX + 16, screenY + 68, news.GetNewsEvent().GetTopicality()*150, 3)

			SetColor 255, 255, 255
			SetAlpha oldAlpha
		EndIf

		If TVTDebugInfo
			Local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			Local w:Int = rect.GetW()
			Local h:Int = rect.GetH()
			Local screenX:Float = Int(GetScreenRect().GetX())
			Local screenY:Float = Int(GetScreenRect().GetY())
			DrawRect(screenX, screenY, w,h)

			SetColor 255,255,255
			SetAlpha 1.0

			Local textY:Int = screenY + 2
			Local fontBold:TBitmapFont = GetBitmapFontManager().basefontBold
			Local fontNormal:TBitmapFont = GetBitmapFont("",11)
			Local ne:TNewsEvent = news.GetNewsEvent()

			fontBold.DrawSimple("News: " + ne.GetTitle(), screenX + 5, textY)
			textY :+ 12
			fontNormal.DrawSimple("GUID: " + ne.GetGUID(), screenX + 5, textY)
			textY :+ 11
			fontNormal.DrawSimple("Preis: " + news.GetPrice(GetPlayerBaseCollection().playerID)+"  (PreisMod: "+MathHelper.NumberToString(ne.GetModifier(TBroadcastMaterialSource.modKeyPriceLS),4)+")", screenX + 5, textY)
			textY :+ 11
			fontNormal.DrawSimple("Qualitaet: " + MathHelper.NumberToString(news.GetQuality(), 4) + " (Event:" + MathHelper.NumberToString(ne.GetQuality(),4) + ", roh=" + MathHelper.NumberToString(ne.GetQualityRaw(), 4) + ")", screenX + 5, textY)
			textY :+ 11
			fontNormal.DrawSimple("(KI-)Attraktivitaet: "+MathHelper.NumberToString(ne.GetAttractiveness(),4), screenX + 5, textY)
			fontNormal.DrawSimple("Aktualitaet: " + MathHelper.NumberToString(ne.GetTopicality(),3) + "/" + MathHelper.NumberToString(ne.GetMaxTopicality(),3)+" ("+MathHelper.NumberToString(100 * ne.GetTopicality()/ne.GetMaxTopicality(),1)+"%)", screenX + 5 + 190, textY)
			textY :+ 11
			fontNormal.DrawSimple("Ausstrahlungen: " + ne.GetTimesBroadcasted(news.owner)+"x  (" + ne.GetTimesBroadcasted()+"x gesamt)", screenX + 5, textY)
			fontNormal.DrawSimple("Alter: " + Long((GetWorldTime().GetTimeGone() - news.GetHappenedTime())/1000) + " Sekunden  (" + (GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())) + " Tage)", screenX + 5 + 190, textY)
			textY :+ 11
			Rem
			local eventCan:string = ""
			if news.GetNewsEvent().skippable
				eventCan :+ "ueberspringbar)"
			else
				eventCan :+ "nicht ueberspringbar"
			endif
			if eventCan <> "" then eventCan :+ ",  "
			if news.GetNewsEvent().reuseable
				eventCan :+ "erneut nutzbar"
			else
				eventCan :+ "nicht erneut nutzbar"
			endif

			fontNormal.DrawSimple("Ist: " + eventCan, screenX + 5, textY)
			textY :+ 11
			endrem
			local happenEffects:int = ne.GetEffectsCount("happen")
			local broadcastEffects:int = ne.GetEffectsCount("broadcast")
			fontNormal.DrawSimple("Effekte: " + happenEffects + "x onHappen, "+ broadcastEffects + "x onBroadcast    Newstyp: " + ne.newsType + "   Genre: "+news.GetGenre(), screenX + 5, textY)
			textY :+ 11

			SetAlpha oldAlpha
		EndIf
	End Method
End Type
