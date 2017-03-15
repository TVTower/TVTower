SuperStrict
Import "common.misc.datasheet.bmx"
Import "game.screen.base.bmx"

Import "game.misc.roomboardsigns.bmx"


Type TScreenHandler_RoomAgencyBoard extends TScreenHandler
	'rental or cancel rental?
	Field mode:int = 0
	Field selectedRoom:TRoomBase
	Field hoveredRoom:TRoomBase

	Global LS_roomagency_board:TLowerString = TLowerString.Create("roomagency_board")	
	Global _eventListeners:TLink[]
	Global _instance:TScreenHandler_RoomAgencyBoard

	Const MODE_RENT:int = 0
	Const MODE_CANCELRENT:int = 1


	Function GetInstance:TScreenHandler_RoomAgencyBoard()
		if not _instance then _instance = new TScreenHandler_RoomAgencyBoard
		return _instance
	End Function


	Method Initialize:int()
		local screen:TScreen = ScreenCollection.GetScreen("screen_roomagency_board")
		if not screen then return False

		'=== CREATE ELEMENTS ===
		InitGUIElements()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'react to changes (eg. cancel a buy/sell-selection if the selected
		'room changes owner)
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onBeginRental", onBeginOrCancelRoomRental) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onCancelRental", onBeginOrCancelRoomRental) ]

		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )
	End Method


	Method RemoveAllGuiElements:int()
		'
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

		GetInstance().Update()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetInstance().Render()
	End Function


	Function onBeginOrCancelRoomRental:int( triggerEvent:TEventBase )
		local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		if not room then return False

		if selectedRoom and mode = MODE_RENT and not selectedRoom.IsRentable() then selectedRoom = null
		if selectedRoom and mode = MODE_CANCELRENT and selectedRoom.IsRentable() then selectedRoom = null
	End Function


	
	'=== EVENTS ===


	'=== COMMON FUNCTIONS ===

	Method InitGUIElements()
		'
	End Method


	Method Update()
		hoveredRoom = null

		'signs updaten und aktivieren

		If clickedRoom and (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			clickedRoom = null
			MouseManager.ResetKey(2)
			MouseManager.ResetKey(1)
		EndIf

		UpdateRoomBoard()

		GuiManager.Update( LS_roomagency_board )

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllGuiElements()
		endif
	End Method


	Method Render()
		SetColor(255,255,255)

		RenderRoomBoard()

		GuiManager.Draw( LS_roomagency_board )

		'draw achievement-sheet
		'if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method


 	Method UpdateRoomBoard()
 	End Method


 	Method RenderRoomBoard()
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

	Method GetContentHeight:int(width:int)
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
