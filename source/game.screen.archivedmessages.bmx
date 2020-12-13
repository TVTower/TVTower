SuperStrict
Import "Dig/base.gfx.gui.list.base.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"

Import "common.misc.datasheet.bmx"
Import "game.screen.base.bmx"

Import "game.misc.archivedmessage.bmx"


Type TScreenHandler_OfficeArchivedMessages extends TScreenHandler
	Field showCategory:int = 0
	Field showCategoryIndex:int = 0
	Field showMode:int = SHOW_UNREAD
	Field roomOwner:int = 0
	Field categoryCountRead:int[]
	Field categoryCountTotal:int[]
	Field colorCategoryHighlight:SColor8 = new SColor8(20,20,20)
	Field colorCategoryActive:SColor8 = new SColor8(30,110,150)
	Field colorCategoryDefault:SColor8 = new SColor8(90,90,90)
	Field showModeSelect:TGUIDropDown

	Field highlightNavigationEntry:int = -1

	Global messageList:TGUISelectList

	Global hoveredGuiMessage:TGUIArchivedMessageListItem

	Global LS_office_archivedmessages:TLowerString = TLowerString.Create("office_archivedmessages")
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TScreenHandler_OfficeArchivedMessages

	Const SHOW_ALL:int = 0
	Const SHOW_READ:int = 1
	Const SHOW_UNREAD:int = 2



	Function GetInstance:TScreenHandler_OfficeArchivedMessages()
		if not _instance then _instance = new TScreenHandler_OfficeArchivedMessages
		return _instance
	End Function


	Method Initialize:int()
		local screen:TScreen = ScreenCollection.GetScreen("screen_office_archivedmessages")
		if not screen then return False

		'=== CREATE ELEMENTS ===
		InitGUIElements()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'to reload message list when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterScreen, screen) ]

		'also reload when messages get added or removed
		_eventListeners :+ [ EventManager.registerListenerFunction("ArchivedMessageCollection.onAdd", onAddOrRemoveArchivedMessage) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ArchivedMessageCollection.onRemove", onAddOrRemoveArchivedMessage) ]

		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickMessage, "TGUIArchivedMessageListItem") ]
		_eventListeners :+ [ EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", Self, "onChangeShowModeDropdown", "TGUIDropDown" ) ]

		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )
	End Method


	Method RemoveAllGuiElements:int()
		messageList.EmptyList()

		hoveredGuiMessage = null
	End Method


	Method SetLanguage()
		'nothing yet
	End Method


	Method AbortScreenActions:Int()
		'nothing yet
	End Method


	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetInstance().roomOwner = room.owner

		GetInstance().Update()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetInstance().roomOwner = room.owner

		GetInstance().Render()
	End Function


	Function onEnterScreen:int( triggerEvent:TEventBase )
		'only an "active player" can enter a screen
		if GetPlayerBase().IsInRoom()
			GetInstance().roomOwner = TRoomBase(GetPlayerBase().GetFigure().GetInRoom()).owner
		endif

		GetInstance().ReloadMessages()
	End Function


	Function onAddOrRemoveArchivedMessage:int( triggerEvent:TEventBase )
		local archivedMessage:TArchivedMessage = TArchivedMessage(triggerEvent.GetReceiver())
		if not archivedMessage then return False

		if GetInstance().roomOwner = archivedMessage.owner or archivedMessage.owner <= 0
			GetInstance().ReloadMessages()
		endif
	End Function



	'=== EVENTS ===

	'GUI -> GUI reactio
	Function onMouseOverMessage:int( triggerEvent:TEventBase )
		local item:TGUIArchivedMessageListItem = TGUIArchivedMessageListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		GetInstance().hoveredGuiMessage = item

		return TRUE
	End Function

	Function onClickMessage:int( triggerEvent:TEventBase )
		If GetInstance().showMode <> SHOW_ALL
			local item:TGUIArchivedMessageListItem = TGUIArchivedMessageListItem(triggerEvent.GetSender())
			If MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1)
				local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
				If GetInstance().showMode = SHOW_UNREAD
					item.message.SetRead(room.owner, True)
				Else
					item.message.SetRead(room.owner, False)
				EndIf
				GetInstance().messageList.removeItem(item)
				'make sure the heading is updated
				GetInstance().Render()
				MouseManager.SetClickHandled(2)
			EndIf
		EndIf
		return TRUE
	End Function

	Method onChangeShowModeDropdown:Int(triggerEvent:TEventBase)
		Local list:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		local item:TGUIDropDownItem = TGUIDropDownItem(list.getSelectedEntry())
		If not item Then return FALSE
		local mode:Int=item.data.getInt("showMode")
		If mode <> showMode
			showMode = mode
			GetInstance().ReloadMessages()
		EndIf
		return TRUE
	End Method

	Method InitGUIElements()
		if not messageList
			messageList = new TGUISelectList.Create(new TVec2D.Init(210,60), new TVec2D.Init(525, 280), "office_archivedmessages")
		endif

		messageList.scrollItemHeightPercentage = 1.0
		messageList.SetAutosortItems(False) 'already sorted achievements
		messageList.SetOrientation(GUI_OBJECT_ORIENTATION_Vertical)


'		ReloadMessages()
	End Method


	Method ReloadMessages()
		'=== PRODUCTION COMPANY SELECT ===
		messageList.EmptyList()

		'add the messages to that list

		categoryCountRead = new int[TVTMessageCategory.count+1]
		categoryCountTotal = new int[TVTMessageCategory.count+1]

		local messages:TList = CreateList()
		For local message:TArchivedMessage = EachIn GetArchivedMessageCollection().entries.values()
			'ignore messages of other players
			if message.GetOwner() <> roomOwner then continue

			categoryCountTotal[0] :+ 1
			if message.messageCategory > 0
				categoryCountTotal[TVTMessageCategory.GetIndex(message.messageCategory)] :+ 1
			endif
			if message.IsRead(roomOwner)
				categoryCountRead[0] :+ 1
				if message.messageCategory > 0
					categoryCountRead[TVTMessageCategory.GetIndex(message.messageCategory)] :+ 1
				endif
			endif

			if showCategory > 0 and message.messageCategory <> showCategory then continue
			if showMode > 0
				if showMode & SHOW_READ > 0 and not message.IsRead(roomOwner) then continue
				if showMode & SHOW_UNREAD > 0 and message.IsRead(roomOwner) then continue
			endif

			messages.AddLast(message)
		Next
		'sort descending
		messages.Sort( False, TArchivedMessage.SortByTime )


		For local message:TArchivedMessage = EachIn messages
			'base items do not have a size - so we have to give a manual one
			local item:TGUIArchivedMessageListItem = new TGUIArchivedMessageListItem.Create(null, null, message.GetTitle())
			item.message = message
			item.displayName = message.GetTitle()
			item.SetSize(400, 70)
			messageList.AddItem( item )
		Next

		messageList.RecalculateElements()
		'refresh scrolling state
		messageList.SetSize(-1, -1)
	End Method


	Method Update()
		'gets refilled in gui-updates
		hoveredGuiMessage = null

		highlightNavigationEntry = -1
		if THelper.MouseIn(50,40,130,300)
			local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessages")
			local contentX:int = skin.GetContentX(50)
			'add titleHeight + titleHeight of "padding" (right window)
			local contentY:int = skin.GetContentY(25) + 18 + 18

			'0 to ... because we include "all" (which is 0)
			For local i:int = 0 to TVTMessageCategory.count
				if THelper.MouseIn(contentX, contentY + i*20, 130, 20)
					highlightNavigationEntry = i

					if MouseManager.IsClicked(1)
						showCategory = TVTMessageCategory.GetAtIndex(i)
						showCategoryIndex = i
						ReloadMessages()

						'handled left click
						MouseManager.SetClickHandled(1)
					endif
				endif
			Next
		endif

		GuiManager.Update( LS_office_archivedmessages )

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllGuiElements()

			'no mouse reset - we still want to leave the room
		endif
	End Method


	Method Render()
		SetColor(255,255,255)

		'=== PANEL ===
		local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessages")

		'where to draw
		local outer:TRectangle = new TRectangle
		'calculate position/size of content elements
		local contentX:int = 0
		local contentY:int = 0
		local contentW:int = 0
		local contentH:int = 0
		local outerSizeH:int = skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		local outerH:int = 0 'size of the "border"
		local titleH:int = 18
		local listH:int



		'=== CATEGORY SELECTION ===
		listH = (TVTMessageCategory.count+1) * 20 + 5 + 35
		outer.Init(40, 25 + titleH, 180, 50)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		'resize outer to fit to the list
		outer.dimension.SetY(50-contentH + listH + titleH)
		contentH = listH

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).DrawBox(GetLocale("MESSAGECATEGORY_CATEGORIES"), contentX + 5, contentY , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, contentH , "2")

		For local i:int = 0 to TVTMessageCategory.count
			local title:string = GetLocale( "MESSAGECATEGORY_" + TVTMessageCategory.GetAsString(TVTMessageCategory.GetAtIndex(i)) )
			if highlightNavigationEntry = i
				GetBitmapFont("default", 13, BOLDFONT).DrawSimple(Chr(183) + " " + title, contentX + 5, contentY + 5 + i*20, colorCategoryHighlight, EDrawTextEffect.Emboss, 0.5)
			elseif i = showCategoryIndex
				GetBitmapFont("default", 13, BOLDFONT).DrawSimple(Chr(183) + " " + title, contentX + 5, contentY + 5 + i*20, colorCategoryActive, EDrawTextEffect.Emboss, 0.5)
			else
				GetBitmapFont("default", 13, BOLDFONT).DrawSimple(Chr(183) + " " + title, contentX + 5, contentY + 5 + i*20, colorCategoryDefault, EDrawTextEffect.Emboss, 0.5)
			endif
		Next
		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

		if not showModeSelect
			showModeSelect = New TGUIDropDown.Create(New TVec2D.Init(outer.GetX() + 12, outer.GetH()-5 ), New TVec2D.Init(147,-1), "", 128, "office_archivedmessages")
			showModeSelect.SetListContentHeight(60)

			addShowModeItem(SHOW_UNREAD, "MESSAGES_SHOW_UNREAD")
			addShowModeItem(SHOW_ALL, "MESSAGES_SHOW_ALL")
			addShowModeItem(SHOW_READ, "MESSAGES_SHOW_READ")
		endif

		'=== MESSAGE LIST ===
		outer.Init(200, 25, 550, 325)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		listH = contentH - titleH

		local caption:string = GetLocale("ARCHIVED_MESSAGES")
		caption :+ " ~q" + GetLocale( "MESSAGECATEGORY_" + TVTMessageCategory.GetAsString(showCategory) ) + "~q"
		if categoryCountRead.length > showCategoryIndex
			Local totalCount:Int = categoryCountTotal[showCategoryIndex]
			Local showCount:Int = messageList.entries.count()
			caption :+ " [" + showCount + "/" + categoryCountTotal[showCategoryIndex] + "]"
		endif


		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).DrawBox(caption, contentX + 5, contentY, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		if messageList.rect.getX() <> contentX + 5
			messageList.rect.SetXY(contentX + 5, contentY + 3)
			messageList.SetSize(contentW - 8, listH - 6)
		endif
		contentY :+ listH

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

		GuiManager.Draw( LS_office_archivedmessages )

		'draw achievement-sheet
		'if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method

	Method addShowModeItem(mode:Int, key:String)
		Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, "")
		item.SetValue(GetLocale(key))
		item.data.AddNumber("showMode", mode)
		showModeSelect.AddItem(item)
		If mode = SHOW_UNREAD Then showModeSelect.setSelectedEntry(item)
	End Method
End Type




Type TGUIArchivedMessageListItem Extends TGUISelectListItem
	Field message:TArchivedMessage
	Field displayName:string = ""
	Field backgroundSprite:TSprite

	Const paddingBottom:Int	= 2
	Const paddingTop:Int = 3


	Method CreateSimple:TGUIArchivedMessageListItem(message:TArchivedMessage)
		'make it "unique" enough
		Self.Create(Null, Null, message.GetGUID())

		self.displayName = message.GetTitle()

		'resize it
		GetDimension()

		Return Self
	End Method


    Method Create:TGUIArchivedMessageListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetValueColor(TColor.Create(0,0,0))

'		GUIManager.add(Self)

		Return Self
	End Method

'rem
	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.GetContentScreenRect().GetW() '- GetScreenRect().GetW()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, GetContentHeight(maxWidth))

		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.SetSize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method
'endrem

	Method GetContentHeight:Float(width:int)
		local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessage")

		local height:int

		local sprite:TSprite = GetBackgroundSprite()
		if sprite
			local border:SRect = sprite.GetNinePatchInformation().contentBorder
			height :+ (border.GetTop() + border.GetBottom())
			width :- (border.GetLeft() + border.GetRight())
		endif

		height :+ skin.fontSemiBold.GetBoxHeight(message.title, width, -1)
		height :+ 3
		'text
		'attention: subtract some pixels from width (to avoid texts fitting
		'because of rounding errors - but then when drawing they do not
		'fit)
		height :+ skin.fontNormal.GetBoxHeight(message.text, width - 1, -1)

		return height
	End Method



	Method GetBackgroundSprite:TSprite()
		if not self.backgroundSprite
			Select message.group
				case 1
					self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.attention")
				case 2
					self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.positive")
				case 3
					self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.negative")
				default
					self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.info")
			EndSelect
		endif
		return self.backgroundSprite
	End Method


	'override to not draw anything
	'as "highlights" are drawn in "DrawValue"
	Method DrawBackground()
		'nothing
	End Method


	'override
	Method DrawValue()
		DrawMessage(GetScreenRect().GetX(), GetScreenRect().GetY() + Self.paddingTop, GetScreenRect().GetW(), GetScreenRect().GetH() - Self.paddingBottom - Self.paddingTop)

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawMessage(GetScreenRect().GetX(), GetScreenRect().GetY() + Self.paddingTop, GetScreenRect().GetW(), GetScreenRect().GetH() - Self.paddingBottom - Self.paddingTop)

			SetBlend AlphaBlend
			SetAlpha 10.0 * GetAlpha()
		EndIf
	End Method


	Method DrawMessage(x:Float, y:Float, w:Float, h:Float)
		local title:string = message.GetTitle() ' + " [c:"+achievement.category+" > g:"+achievement.group+" > i:"+achievement.index+"   "+achievement.GetGUID()+"]"
		local text:string = message.GetText()

		local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessage")

		local sprite:TSprite = GetBackgroundSprite()
		sprite.DrawArea(x,y,w,h)


		local border:Srect = sprite.GetNinePatchInformation().contentBorder

		local contentH:int = GetScreenRect().GetH() - (border.GetTop() + border.GetBottom())
		local titleH:int = 0
		local timeW:int = 0
		local dim:SVec2I

		dim = skin.fontNormal.DrawBox( ..
			GetLocale("DAY") + " " + (GetWorldTime().GetDaysRun(message.time)+1) + " " + GetWorldTime().GetFormattedTime(message.time), ..
			x + (w - border.GetRight() - 100), ..
			y + border.GetTop(), .. '-1 to align it more properly
			100, ..
			contentH, ..
			sALIGN_RIGHT_TOP, skin.textColorNeutral)
		timeW = dim.x
		timeW :+ 10

		dim = skin.fontSemiBold.DrawBox( ..
			title, ..
			x + border.GetLeft(), ..
			y + border.GetTop(), .. '-1 to align it more properly
			w - (border.GetRight() + border.GetLeft() - timeW),  ..
			contentH, ..
			sALIGN_LEFT_TOP, skin.textColorNeutral)
		titleH = dim.y
		titleH :+ 3

		skin.fontNormal.DrawBox( ..
			text, ..
			x + border.GetLeft(), ..
			y + titleH + border.GetTop(), .. '-1 to align it more properly
			w - (border.GetRight() + border.GetLeft()),  ..
			contentH - titleH, ..
			sALIGN_LEFT_TOP, skin.textColorNeutral)
	End Method


	Method DrawContent()
		if isSelected()
			SetColor 245,230,220
			Super.DrawContent()

			SetColor 220,210,190
			SetAlpha GetAlpha() * 0.10
			SetBlend LightBlend
			Super.DrawContent()
			SetBlend AlphaBlend
			SetAlpha GetAlpha() * 10

			SetColor 255,255,255
		else
			Super.DrawContent()
		endif
	End Method


	Method DrawDatasheet(x:Int=30, y:Int=20, alignment:Float=0.5)
		Local sheetWidth:Int = 250
		local baseX:Int = int(x - alignment * sheetWidth)

		local oldCol:SColor8; GetColor(oldCol)
		local oldColA:Float = GetAlpha()
		SetColor 0,0,0
		SetAlpha 0.2 * oldColA
		TFunctions.DrawBaseTargetRect(baseX + sheetWidth/2, ..
		                              y + 70, ..
		                              Self.GetScreenRect().GetX() + Self.GetScreenRect().GetW()/2.0, ..
		                              Self.GetScreenRect().GetY() + Self.GetScreenRect().GetH()/2.0, ..
		                              20, 3)
		SetColor(oldCol)
		SetAlpha(oldColA)


		ShowMessageSheet(message, x, y, alignment)
	End Method


	Function ShowMessageSheet:Int(message:TArchivedMessage, x:Int,y:Int, alignment:Float=0.5)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 250
		local sheetHeight:int = 0 'calculated later
		x = x - alignment * sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessage")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = int(x) + skin.GetContentX()
		local contentY:int = int(y) + skin.GetContentY()
		'=== OVERLAY / BORDER ===
		skin.RenderBorder(x, y, sheetWidth, sheetHeight)
	End Function

End Type
