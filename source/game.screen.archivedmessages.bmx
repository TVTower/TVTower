SuperStrict
Import "Dig/base.gfx.gui.list.base.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"

Import "common.misc.datasheet.bmx"
Import "game.screen.base.bmx"

Import "game.misc.archivedmessage.bmx"


Type TScreenHandler_OfficeArchivedMessages extends TScreenHandler
	Field showCategory:int = 0
	Field showCategoryIndex:int = 0
	Field showMode:int = 0
	Field roomOwner:int = 0
	Field categoryCountRead:int[]
	Field categoryCountTotal:int[]
	Field markReadTime:Long = 0
	Field colorCategoryHighlight:TColor = TColor.CreateGrey(20)
	Field colorCategoryActive:TColor = TColor.Create(30,110,150)
	Field colorCategoryDefault:TColor = TColor.CreateGrey(90)

	Field highlightNavigationEntry:int = -1

	Global messageList:TGUISelectList

	Global hoveredGuiMessage:TGUIArchivedMessageListItem

	Global LS_office_archivedmessages:TLowerString = TLowerString.Create("office_archivedmessages")	
	Global _eventListeners:TLink[]
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
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'to reload message list when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterScreen, screen) ]

		'also reload when messages get added or removed
		_eventListeners :+ [ EventManager.registerListenerFunction("ArchivedMessageCollection.onAdd", onAddOrRemoveArchivedMessage) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ArchivedMessageCollection.onRemove", onAddOrRemoveArchivedMessage) ]

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

		GetInstance().markReadTime = Time.MillisecsLong()
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
			item.Resize(400, 70)
			messageList.AddItem( item )
		Next

		messageList.RecalculateElements()
		'refresh scrolling state
		messageList.Resize(-1, -1)
	End Method


	Method Update()
		'gets refilled in gui-updates
		hoveredGuiMessage = null

		highlightNavigationEntry = -1
		if THelper.MouseIn(50,40,100,300)
			local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessages")
			local contentX:int = skin.GetContentX(50)
			'add titleHeight + titleHeight of "padding" (right window)
			local contentY:int = skin.GetContentY(25) + 18 + 18

			'0 to ... because we include "all" (which is 0)
			For local i:int = 0 to TVTMessageCategory.count
				if THelper.MouseIn(contentX, contentY + i*20, 100, 20)
					highlightNavigationEntry = i

					if MouseManager.IsClicked(1)
						showCategory = TVTMessageCategory.GetAtIndex(i)
						showCategoryIndex = i
						ReloadMessages()
						MouseManager.ResetKey(1)

						'reset
						markReadTime = Time.MillisecsLong()
					endif
				endif
			Next
		endif

		'mark displayed/drawn as read
		if markReadTime > 0 and Time.MillisecsLong() - markReadTime > 5000 
			For local item:TGUIArchivedMessageListItem = EachIn messageList.entries
				item.message.SetRead(roomOwner, True)
			Next
			markReadTime = 0
		endif

		GuiManager.Update( LS_office_archivedmessages )

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllGuiElements()
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
		listH = (TVTMessageCategory.count+1) * 20 + 5
		outer.Init(50, 25 + titleH, 180, 50)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		'resize outer to fit to the list
		outer.dimension.SetY(50-contentH + listH + titleH)
		contentH = listH

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(GetLocale("MESSAGECATEGORY_CATEGORIES"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, contentH , "2")

		For local i:int = 0 to TVTMessageCategory.count
			local title:string = GetLocale( "MESSAGECATEGORY_" + TVTMessageCategory.GetAsString(TVTMessageCategory.GetAtIndex(i)) )
			if highlightNavigationEntry = i
				GetBitmapFont("default", 13, BOLDFONT).DrawStyled(Chr(183) + " " + title, contentX + 5, contentY + 5 + i*20, colorCategoryHighlight, TBitmapFont.STYLE_EMBOSS, 1, 0.5)
			elseif i = showCategoryIndex
				GetBitmapFont("default", 13, BOLDFONT).DrawStyled(Chr(183) + " " + title, contentX + 5, contentY + 5 + i*20, colorCategoryActive, TBitmapFont.STYLE_EMBOSS, 1, 0.5)
			else
				GetBitmapFont("default", 13, BOLDFONT).DrawStyled(Chr(183) + " " + title, contentX + 5, contentY + 5 + i*20, colorCategoryDefault, TBitmapFont.STYLE_EMBOSS, 1, 0.5)
			endif
		Next
		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())



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
			caption :+ " [" + categoryCountRead[showCategoryIndex] + "/" + categoryCountTotal[showCategoryIndex] + "]"
		endif
		

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(caption, contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		if messageList.rect.getX() <> contentX + 5
			messageList.rect.SetXY(contentX + 5, contentY + 3)
			messageList.Resize(contentW - 8, listH - 6)
		endif
		contentY :+ listH

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

		GuiManager.Draw( LS_office_archivedmessages )

		'draw achievement-sheet
		'if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()
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
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, GetContentHeight(maxWidth))
		
		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method
'endrem

	Method GetContentHeight:Float(width:int)
		local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessage")

		local height:int

		local sprite:TSprite = GetBackgroundSprite()
		if sprite
			local border:TRectangle = sprite.GetNinePatchContentBorder()
			height :+ (border.GetTop() + border.GetBottom())

			width :- (border.GetLeft() + border.GetRight())
		endif

		height :+ skin.fontSemiBold.GetBlockDimension(message.title, width, -1).GetY()
		height :+ 3
		'text
		'attention: subtract some pixels from width (to avoid texts fitting
		'because of rounding errors - but then when drawing they do not
		'fit)
		height :+ skin.fontNormal.GetBlockDimension(message.text, width - 1, -1).GetY()

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
		DrawMessage(GetScreenX(), GetScreenY() + Self.paddingTop, GetScreenWidth(), GetScreenHeight() - Self.paddingBottom - Self.paddingTop)

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawMessage(GetScreenX(), GetScreenY() + Self.paddingTop, GetScreenWidth(), GetScreenHeight() - Self.paddingBottom - Self.paddingTop)

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


		local border:TRectangle = sprite.GetNinePatchContentBorder()

		'local oldCol:TColor = new TColor.Get()
		local contentH:int = GetScreenHeight() - (border.GetTop() + border.GetBottom())
		local titleH:int = 0
		local timeW:int = 0

		timeW = skin.fontNormal.drawBlock( ..
			GetLocale("DAY") + " " + (GetWorldTime().GetDaysRun(message.time)+1) + " " + GetWorldTime().GetFormattedTime(message.time), ..
			x + (w - border.GetRight() - 100), ..
			y + border.GetTop(), .. '-1 to align it more properly
			100, ..
			contentH, ..
			ALIGN_RIGHT_TOP, skin.textColorNeutral, 0,1,1.0,True, True).GetX()
		timeW :+ 10
			
		titleH = skin.fontSemiBold.drawBlock( ..
			title, ..
			x + border.GetLeft(), ..
			y + border.GetTop(), .. '-1 to align it more properly
			w - (border.GetRight() + border.GetLeft() - timeW),  ..
			contentH, ..
			ALIGN_LEFT_TOP, skin.textColorNeutral, 0,1,1.0,True, True).GetY()

		titleH :+ 3

		skin.fontNormal.drawBlock( ..
			text, ..
			x + border.GetLeft(), ..
			y + titleH + border.GetTop(), .. '-1 to align it more properly
			w - (border.GetRight() + border.GetLeft()),  ..
			contentH - titleH, ..
			ALIGN_LEFT_TOP, skin.textColorNeutral)
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


	Method DrawDatasheet(leftX:Float=30, rightX:Float=30)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= int(leftX)
		Local sheetAlign:Int= 0
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - int(rightX)
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		local sheetCenterX:Float = sheetX
		if sheetAlign = 0
			sheetCenterX :+ 250/2 '250 is sheetWidth
		else
			sheetCenterX :- 250/2 '250 is sheetWidth
		endif
		Local tri:Float[]=[sheetCenterX,sheetY+25, sheetCenterX,sheetY+90, getScreenX() + getScreenWidth()/2.0, getScreenY() + GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		ShowMessageSheet(message, sheetX, sheetY, sheetAlign)
	End Method


	Function ShowMessageSheet:Int(message:TArchivedMessage, x:Float,y:Float, align:int=0)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 250
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("archivedmessage")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = int(x) + skin.GetContentX()
		local contentY:int = int(y) + skin.GetContentY()
		'=== OVERLAY / BORDER ===
		skin.RenderBorder(int(x), int(y), sheetWidth, sheetHeight)
	End Function

End Type
