SuperStrict
Import "Dig/base.util.registry.spriteentityloader.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "Dig/base.gfx.gui.list.base.bmx"
Import "common.misc.gamegui.bmx"
Import "game.roomhandler.base.bmx"
Import "game.broadcastmaterial.news.bmx"
Import "game.newsagency.bmx"


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
	Global showDeleteHintTimer:Long = 0
	'how long to display?
	Global showDeleteHintTime:int = 4000
	'time to wait until hint is shown
	Global showDeleteHintDwellTime:Int = 1000


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
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.OnTryLeave", onTryLeaveNewsPlannerScreen, plannerScreen) ]
		
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


	Function IsMyScreen:Int(screen:TScreen)
		if not screen then return False
		if screen.name = "screen_newsstudio_newsplanner" then return True
		if screen.name = "screen_newsstudio" then return True

		return False
	End Function


	Function IsMyRoom:Int(room:TRoomBase)
		For Local i:Int = 1 To 4
			If room = GetRoomCollection().GetFirstByDetails("news", i) Then Return True
		Next
		Return False
	End Function
	

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


		if TVTDebugInfos
			SetColor 0,0,0
			SetAlpha 0.5
			DrawRect(15,35, 180, 140)
			SetAlpha 1.0
			SetColor 255,255,255
			GetBitmapFont("default", 12).Draw("Newstimer:", 20, 40)
			For local i:int = 0 until TVTNewsGenre.count
				GetBitmapFont("default", 10).Draw(GetLocale("NEWS_"+TVTNewsGenre.GetAsString(i))+":  "+GetWorldTime().GetFormattedtime(GetNewsAgency().NextEventTimes[i]), 20, 60 + 12*i)
			Next
		endif
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
			If THelper.MouseIn(167,60,240,160)
				If not PlannerToolTip Then PlannerToolTip = TTooltip.Create("Newsplaner", GetLocale("MANAGE_BROADCASTED_NEWS"), 180, 100, 0, 0)
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
		if GetPlayerBase().GetNewsAbonnementDaysMax(genre) > level
			NewsGenreTooltip.content :+ "~n~n"
			local tip:String = getLocale("NEWSSTUDIO_YOU_ALREADY_USED_LEVEL_AND_THEREFOR_PAY")
			tip = tip.Replace("%MAXLEVEL%", GetPlayerBase().GetNewsAbonnementDaysMax(genre))
			tip = tip.Replace("%TOPAY%", TNewsAgency.GetNewsAbonnementPrice(GetPlayerBase().GetNewsAbonnementDaysMax(genre)) + getLocale("CURRENCY"))
			NewsGenreTooltip.content :+ getLocale("HINT")+": " + tip
		endif
	End Function


	Function onClickNewsGenreButtons:int( triggerEvent:TEventBase )
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		local room:TRoom = currentRoom
		if not button or not room then return 0

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
		For local i:int = 0 until len( NewsGenreButtons )
			if button = NewsGenreButtons[i]
				level = GetPlayerBase(room.owner).GetNewsAbonnement( button.data.GetInt("newsGenre", i) )
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
				GetBitmapFont("default", 12, BOLDFONT).DrawBlock(GetLocale("RIGHT_CLICK_TO_DELETE"), draggedGuiNews.GetScreenX(), draggedGuiNews.GetScreenY2() + 3, draggedGuiNews.GetScreenWidth(), 30, ALIGN_CENTER_TOP, TColor.clWhite, TBitmapFont.STYLE_SHADOW)
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

		If Not owner Or owner <> currentRoom.owner Then Return False

		'only adjust GUI if we are displaying that screen (eg. AI skips that)
		If not IsMyScreen( ScreenCollection.GetCurrentScreen() ) Then Return False

		'our plan?
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
		local owner:int = GetPlayerBaseCollection().playerID
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
		if GetPlayerBaseCollection().IsPlayer(guiNews.news.owner)
			GetPlayerProgrammePlan(guiNews.news.owner).RemoveNewsByGUID(guiNews.news.GetGUID(), FALSE)
			GetPlayerProgrammeCollection(guiNews.news.owner).RemoveNews(guiNews.news)
		endif

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

		if not GetPlayerBaseCollection().IsPlayer(guiNews.news.owner) return False

		if receiverList = guiNewsListAvailable
			GetPlayerProgrammePlan(guiNews.news.owner).RemoveNewsByGUID(guiNews.news.GetGUID(), TRUE)
		elseif receiverList = guiNewsListUsed
			local slot:int = -1
			'check drop position
			local coord:TVec2D = TVec2D(triggerEvent.getData().get("coord", new TVec2D.Init(-1,-1)))
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
		RefreshGUIElements()
	End Function


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

    Method Create:TGUINewsList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
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

    Method Create:TGUINewsSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
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

    Method Create:TGUINews(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Return Self
	End Method

	Method SetNews:Int(news:TNews)
		Self.news = news
		If news
			'now we can calculate the item width
			Self.Resize( GetSpriteFromRegistry(Self.imageBaseName+news.newsEvent.genre).area.GetW(), GetSpriteFromRegistry(Self.imageBaseName+news.newsEvent.genre).area.GetH() )
		EndIf
		'self.SetLimitToState("Newsplanner")

		'as the news inflicts the sorting algorithm - resort
		GUIManager.sortLists()
	End Method


	Method Compare:Int(Other:Object)
		Local otherBlock:TGUINews = TGUINews(Other)
		If otherBlock<>Null
			'both items are dragged - check time
			If Self._flags & GUI_OBJECT_DRAGGED And otherBlock._flags & GUI_OBJECT_DRAGGED
				'if a drag was earlier -> move to top
				If Self._timeDragged < otherBlock._timeDragged Then Return 1
				If Self._timeDragged > otherBlock._timeDragged Then Return -1
				Return 0
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


	'override default update-method
	Method Update:Int()
		Super.Update()

		'set mouse to "hover"
		'set mouse to "hover"
		If isHovered() and (news.owner <= 0 or news.IsOwnedByPlayer( GetPlayerBaseCollection().playerID))
			if news.IsControllable()
				GetGameBase().cursorstate = 1
			endif
		endif

		'set mouse to "dragged"
		If isDragged() Then GetGameBase().cursorstate = 2
	End Method


	Method DrawTextOverlay()
		Local screenX:Float = Int(GetScreenX())
		Local screenY:Float = Int(GetScreenY())

		'===== CREATE CACHE IF MISSING =====
		If Not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(rect.GetIntW(), rect.GetIntH())
'			cacheTextOverlay = CreateImage(rect.GetW(), rect.GetH(), DYNAMICIMAGE | FILTEREDIMAGE)

			'render to image
			TBitmapFont.SetRenderTarget(cacheTextOverlay)

			'default texts (title, text,...)
			GetBitmapFontManager().basefontBold.drawBlock(news.GetTitle(), 15, 2, 330, 15, Null, TColor.CreateGrey(20))
			GetBitmapFontManager().baseFont.drawBlock(news.GetDescription(), 15, 17, 340, 50 + 8, Null, TColor.CreateGrey(100))

			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.3*oldAlpha
			GetBitmapFont("Default", 9).drawBlock(news.GetGenreString(), 15, 73, 120, 15, Null, TColor.clBlack)
			SetAlpha 1.0*oldAlpha

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(Null)
		EndIf

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, screenX, screenY)
	End Method


	Method DrawContent()
		State = 0
		SetColor 255,255,255

		If Self.RestrictViewPort()
			Local screenX:Float = Int(GetScreenX())
			Local screenY:Float = Int(GetScreenY())

			Local oldAlpha:Float = GetAlpha()
			Local itemAlpha:Float = 1.0
			'fade out dragged
			If isDragged() Then itemAlpha = 0.25 + 0.5^GuiManager.GetDraggedNumber(Self)

			SetAlpha oldAlpha*itemAlpha
			'background - no "_dragged" to add to name
			GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)

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
				GetBitmapFontManager().basefontBold.drawBlock(news.GetPrice(GetPlayerBaseCollection().playerID) + ",-", screenX + 262, screenY + 70, 90, -1, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			Else
				SetAlpha GetAlpha()*0.75
				GetBitmapFontManager().basefontBold.drawBlock(news.GetPrice(GetPlayerBaseCollection().playerID) + ",-", screenX + 262, screenY + 70, 90, -1, New TVec2D.Init(ALIGN_RIGHT), TColor.CreateGrey(100))
				SetAlpha GetAlpha()*2.0
			EndIf

			Select GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())
				Case 0	GetBitmapFontManager().baseFont.drawBlock(GetLocale("TODAY")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack )
				Case 1	GetBitmapFontManager().baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("YESTERDAY")+" "+ GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
				Case 2	GetBitmapFontManager().baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("TWO_DAYS_AGO")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			End Select

			SetAlpha oldAlpha * 0.5
			SetColor 140,110,110
			DrawRect(screenX + 15, screenY + 67, 152, 3)
			SetAlpha oldAlpha
			SetColor 255,255,255
			DrawRect(screenX + 16, screenY + 68, 150, 1)
			SetColor 230,150,100
			SetAlpha oldAlpha * 0.4
			DrawRect(screenX + 16, screenY + 68, news.newsEvent.GetMaxTopicality()*150, 1)
			SetAlpha oldAlpha
			DrawRect(screenX + 16 + news.newsEvent.GetMaxTopicality()*150 - 1, screenY + 68, 2, 1)
			SetAlpha oldAlpha
			DrawRect(screenX + 16, screenY + 68, news.newsEvent.GetTopicality()*150, 1)

			SetColor 255, 255, 255
			SetAlpha oldAlpha
	
			Self.resetViewport()
		EndIf

		If TVTDebugInfos
			Local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			Local w:Int = rect.GetW()
			Local h:Int = rect.GetH()
			Local screenX:Float = Int(GetScreenX())
			Local screenY:Float = Int(GetScreenY())
			DrawRect(screenX, screenY, w,h)
		
			SetColor 255,255,255
			SetAlpha 1.0

			Local textY:Int = screenY + 2
			Local fontBold:TBitmapFont = GetBitmapFontManager().basefontBold
			Local fontNormal:TBitmapFont = GetBitmapFont("",11)
			
			fontBold.draw("News: " + news.newsEvent.GetTitle(), screenX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Preis: " + news.GetPrice(GetPlayerBaseCollection().playerID)+"  (PreisMod: "+MathHelper.NumberToString(news.newsEvent.GetModifier("price"),4)+")", screenX + 5, textY)
			textY :+ 11	
			fontNormal.draw("Qualitaet: " + MathHelper.NumberToString(news.GetQuality(), 4) + " (Event:" + MathHelper.NumberToString(news.newsEvent.GetQuality(),4) + ", roh=" + MathHelper.NumberToString(news.newsEvent.GetQualityRaw(), 4) + ")", screenX + 5, textY)
			textY :+ 11	
			fontNormal.draw("(KI-)Attraktivitaet: "+MathHelper.NumberToString(news.newsEvent.GetAttractiveness(),4)+"    Aktualitaet: " + MathHelper.NumberToString(news.newsEvent.GetTopicality(),4), screenX + 5, textY)
			textY :+ 11	
			fontNormal.draw("Ausstrahlungen: " + news.newsEvent.GetTimesBroadcasted(news.owner)+"x  (" + news.newsEvent.GetTimesBroadcasted()+"x gesamt)", screenX + 5, textY)
			textY :+ 11	
			fontNormal.draw("Alter: " + Long(GetWorldTime().GetTimeGone() - news.GetHappenedtime()) + " Sekunden  (" + (GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())) + " Tage)", screenX + 5, textY)
			textY :+ 11	
			Rem
			local eventCan:string = ""
			if news.newsEvent.skippable
				eventCan :+ "ueberspringbar)"
			else
				eventCan :+ "nicht ueberspringbar"
			endif
			if eventCan <> "" then eventCan :+ ",  "
			if news.newsEvent.reuseable
				eventCan :+ "erneut nutzbar"
			else
				eventCan :+ "nicht erneut nutzbar"
			endif
			
			fontNormal.draw("Ist: " + eventCan, screenX + 5, textY)
			textY :+ 12	
			endrem
			local happenEffects:int = 0
			local broadcastEffects:int = 0
			if news.newsEvent.effects.GetList("happen") then happenEffects = news.newsEvent.effects.GetList("happen").Count()
			if news.newsEvent.effects.GetList("broadcast") then broadcastEffects = news.newsEvent.effects.GetList("broadcast").Count()
			fontNormal.draw("Effekte: " + happenEffects + "x onHappen, "+ broadcastEffects + "x onBroadcast    Newstyp: " + news.newsEvent.newsType + "   Genre: "+news.newsEvent.genre, screenX + 5, textY)
			textY :+ 12	

			SetAlpha oldAlpha
		EndIf
	End Method
End Type