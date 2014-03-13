Global CHAT_CHANNEL_NONE:Int	= 0
Global CHAT_CHANNEL_DEBUG:Int	= 1
Global CHAT_CHANNEL_SYSTEM:Int	= 2
Global CHAT_CHANNEL_PRIVATE:Int	= 4
'normal chat channels
Global CHAT_CHANNEL_LOBBY:Int	= 8
Global CHAT_CHANNEL_INGAME:Int	= 16
Global CHAT_CHANNEL_OTHER:Int	= 32
Global CHAT_CHANNEL_GLOBAL:Int	= 56	'includes LOBBY, INGAME, OTHER

Global CHAT_COMMAND_NONE:Int	= 0
Global CHAT_COMMAND_WHISPER:Int	= 1
Global CHAT_COMMAND_SYSTEM:Int	= 2



Function Font_AddGradient:TGW_BitmapFontChar(font:TGW_BitmapFont, charKey:String, char:TGW_BitmapFontChar, config:TData=Null)
	If Not char.img Then Return char 'for "space" and other empty signs
	Local pixmap:TPixmap	= LockImage(char.img)
	'convert to rgba
	If pixmap.format = PF_A8 Then pixmap = pixmap.convert(PF_RGBA8888)
'	pixmap = pixmap.convert(PF_A8)
	If Not config Then config = new TData

	'gradient
	Local color:Int
	Local gradientTop:Int	= config.GetInt("gradientTop", 255)
	Local gradientBottom:Int= config.GetInt("gradientBottom", 100)
	Local gradientSteps:Int = font.GetMaxCharHeight()
	Local onStep:Int		= Max(0, char.area.GetY() -2)
	Local brightness:Int	= 0

	For Local y:Int = 0 To pixmap.height-1
		brightness = 255 - onStep * (gradientTop - gradientBottom) / gradientSteps
		onStep :+1
		For Local x:Int = 0 To pixmap.width-1
			color = ARGB_Color( ARGB_Alpha( ReadPixel(pixmap, x,y) ), brightness, brightness, brightness)
			WritePixel(pixmap, x,y, color)
		Next
	Next
	char.img = LoadImage(pixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function


Function Font_AddShadow:TGW_BitmapFontChar(font:TGW_BitmapFont, charKey:String, char:TGW_BitmapFontChar, config:TData=Null)
	If Not char.img Then Return char 'for "space" and other empty signs

	If Not config Then config = new TData
	Local shadowSize:Int = config.GetInt("size", 0)
	'nothing to do?
	If shadowSize=0 Then Return char
	Local pixmap:TPixmap	= LockImage(char.img) ;If pixmap.format = PF_A8 Then pixmap = pixmap.convert(PF_RGBA8888)
	Local stepX:Float		= Float(config.GetString("stepX", "0.75"))
	Local stepY:Float		= Float(config.GetString("stepY", "1.0"))
	Local intensity:Float	= Float(config.GetString("intensity", "0.75"))
	Local blur:Float		= Float(config.GetString("blur", "0.5"))
 	Local width:Int			= pixmap.width + shadowSize
	Local height:Int		= pixmap.height + shadowSize

	Local newPixmap:TPixmap = TPixmap.Create(width, height, PF_RGBA8888)
	newPixmap.ClearPixels(0)

	If blur > 0.0
		DrawImageOnImage(pixmap, newPixmap, 1,1, TColor.Create(0,0,0,1.0))
		blurPixmap(newPixmap,0.5)
	EndIf

	'shadow
	For Local i:Int = 0 To shadowSize
		DrawImageOnImage(pixmap, newPixmap, Int(i*stepX),Int(i*stepY), TColor.Create(0,0,0,intensity/i))
	Next
	'original image
	DrawImageOnImage(pixmap, newPixmap, 0,0)

	'increase character dimension
	char.charWidth :+ shadowSize
	char.area.dimension.moveXY(shadowSize, shadowSize)

	char.img = LoadImage(newPixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function



Type TGUIChat Extends TGUIGameWindow
	Field guiPanel:TGUIBackgroundBox
	Field _defaultTextColor:TColor		= TColor.Create(0,0,0)
	Field _defaultHideEntryTime:Int		= Null
	Field _channels:Int					= 0		'bitmask of channels the chat listens to
	Field guiList:TGUIListBase			= Null
	Field guiInput:TGUIInput			= Null
	Field guiInputPositionRelative:Int	= 0		'is the input is inside the chatbox or absolute
	Field guiInputHistory:TList			= CreateList()
	Field keepInputActive:Int			= True

	Global antiSpamTimer:Int			= 0		'time when again allowed to send
	Global antiSpamTime:Int				= 100


	Method Create:TGUIChat(x:Int,y:Int,width:Int,height:Int, State:String="")
		Super.Create(x,y,width,height, State)

		guiPanel = AddContentBox(0,0,GetContentScreenWidth()-10,-1)

		guiList = New TGUIListBase.Create(10,10,GetContentScreenWidth(),GetContentScreenHeight(),State)
		guiList.setOption(GUI_OBJECT_ACCEPTS_DROP, False)
		guiList.autoSortItems = False
		guiList.SetAcceptDrop("")
		guiList.setParent(Self)
		guiList.autoScroll = True
		guiList.SetBackground(Null)


		guiInput = New TGUIInput.Create(0, height, width,-1, "", 32, State)
		guiInput.setParent(Self)

		'guiPanel.AddChild(guiPanel, false)
		'guiPanel.AddChild(guiInput, false)

		'we manage the panel
		AddChild(guiPanel)


		'resize base and move child elements
		resize(width,height)

		'by default all chats want to list private messages and system announcements
		setListenToChannel(CHAT_CHANNEL_PRIVATE, True)
		setListenToChannel(CHAT_CHANNEL_SYSTEM, True)
		setListenToChannel(CHAT_CHANNEL_GLOBAL, True)

		'register events
		'- observe text changes in our input field
		EventManager.registerListenerFunction( "guiobject.onChange", Self.onInputChange, Self.guiInput )
		'- observe wishes to add a new chat entry - listen to all sources
		EventManager.registerListenerMethod( "chat.onAddEntry", Self, "onAddEntry" )

		GUIManager.Add( Self )

		Return Self
	End Method


	'returns boolean whether chat listens to a channel
	Method isListeningToChannel:Int(channel:Int)
		Return Self._channels & channel
	End Method


	Method setListenToChannel(channel:Int, enable:Int=True)
		If enable
			Self._channels :| channel
		Else
			Self._channels :& ~channel
		EndIf
	End Method


	Method SetDefaultHideEntryTime(milliseconds:Int=Null)
		Self._defaultHideEntryTime = milliseconds
	End Method


	Method SetDefaultTextColor(color:TColor)
		Self._defaultTextColor = color
	End Method


	Function onInputChange:Int( triggerEvent:TEventBase )
		Local guiInput:TGUIInput = TGUIInput(triggerEvent.getSender())
		If guiInput = Null Then Return False

		Local guiChat:TGUIChat = TGUIChat(guiInput._parent)
		If guiChat = Null Then Return False

		'skip empty text
		If guiInput.value.Trim() = "" Then Return False

		'emit event : chats should get a new line
		'- step A) is to get what channels we want to announce to
		Local sendToChannels:Int = guiChat.getChannelsFromText(guiInput.value)
		'- step B) is emitting the event "for all"
		'  (the listeners have to handle if they want or ignore the line
		EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", new TData.AddNumber("senderID", Game.playerID).AddNumber("channels", sendToChannels).AddString("text",guiInput.value) , guiChat ) )

		'avoid getting the enter-key registered multiple times
		'which leads to "flickering"
		KEYMANAGER.blockKey(KEY_ENTER, 250) 'block for 100ms

		'trigger antiSpam
		guiChat.antiSpamTimer = MilliSecs() + guiChat.antiSpamTime

		If guiChat.guiInputHistory.last() <> guiInput.value
			guiChat.guiInputHistory.AddLast(guiInput.value)
		EndIf

		'reset input field
		guiInput.value = ""
	End Function


	Method onAddEntry:Int( triggerEvent:TEventBase )
		Local guiChat:TGUIChat = TGUIChat(triggerEvent.getReceiver())
		'if event has a specific receiver and this is not a chat - we are not interested
		If triggerEvent.getReceiver() And Not guiChat Then Return False
		'found a chat - but it is another chat
		If guiChat And guiChat <> Self Then Return False

		'here we could add code to exlude certain other chat channels
		Local sendToChannels:Int = triggerEvent.getData().getInt("channels", 0)
		If Self.isListeningToChannel(sendToChannels)
			Self.AddEntryFromData( triggerEvent.getData() )
		Else
			Print "onAddEntry - unknown channel, not interested"
		EndIf
	End Method


	Function getChannelsFromText:Int(text:String)
		Local sendToChannels:Int = 0 'by default send to no channel
		Select getSpecialCommandFromText(text)
			Case CHAT_COMMAND_WHISPER
				sendToChannels :| CHAT_CHANNEL_PRIVATE
			Default
				sendToChannels :| CHAT_CHANNEL_GLOBAL
		End Select
		Return SendToChannels
	End Function


	Function getSpecialCommandFromText:Int(text:String)
		text = text.Trim()

		If Left( text,1 ) <> "/" Then Return CHAT_COMMAND_NONE

		Local spacePos:Int = Instr(text, " ")
		Local commandString:String = Mid(text, 2, spacePos-2 ).toLower()
		Local payload:String = Right(text, text.length -spacePos)

		Select commandString
			Case "fluestern", "whisper", "w"
				'local spacePos:int = instr(payload, " ")
				'local target:string = Mid(payload, 1, spacePos-1 ).toLower()
				'local message:string = Right(payload, payload.length -spacePos)
				'print "whisper to: " + "-"+target+"-"
				'print "whisper msg:" + message
				Return CHAT_COMMAND_WHISPER
			Default
				'print "command: -"+commandString+"-"
				'print "payload: -"+payload+"-"
				Return CHAT_COMMAND_NONE
		End Select
	End Function


	Method AddEntry(entry:TGUIListItem)
		guiList.AddItem(entry)
	End Method


	Method AddEntryFromData( data:TData )
		Local text:String		= data.getString("text", "")
		Local textColor:TColor	= TColor( data.get("textColor") )
		Local senderID:Int		= data.getInt("senderID", 0)
		Local senderName:String	= ""
		Local senderColor:TColor= Null

		If Game.isPlayer(senderID)
			senderName	= Game.Players[senderID].Name
			senderColor	= Game.Players[senderID].color
			If Not textColor Then textColor = Self._defaultTextColor
		Else
			senderName	= "SYSTEM"
			senderColor	= TColor.Create(255,100,100)
			textColor	= TColor.Create(255,100,100)
		EndIf


		'finally add to the chat box
		Local entry:TGUIChatEntry = New TGUIChatEntry.CreateSimple(text, textColor, senderName, senderColor, Null )
		'if the default is "null" then no hiding will take place
		entry.SetShowtime( _defaultHideEntryTime )
		AddEntry( entry )
	End Method


	Method SetPadding:Int(top:Int,Left:Int,bottom:Int,Right:Int)
		padding.setTLBR(top,Left,bottom,Right)
		resize()
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float=Null,h:Float=Null)
		Super.Resize(w,h)

		'background covers whole area, so resize it
		If guiBackground Then guiBackground.resize(rect.getW(), rect.getH())

		Local contentWidth:Int = GetContentScreenWidth()
		Local contentHeight:Int = GetContentScreenHeight()
		If guiPanel
			guiPanel.Resize(contentWidth, contentHeight)
			contentWidth = guiPanel.GetContentScreenWidth()
			contentHeight = guiPanel.GetContentScreenHeight()
		EndIf

		Local subtractInputHeight:Float = 0.0
		'move and resize input field to the bottom
		If guiInput And Not guiInput.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiInput.resize(GetContentScreenWidth(),Null)
			'ignore panel padding...
			guiInput.rect.position.setXY(0, GetContentScreenHeight() - guiInput.rect.getH())
			subtractInputHeight = guiInput.rect.getH()
		EndIf

		'move and resize the listbox (subtract input if needed)
		If guiList Then guiList.resize(contentWidth, GetContentScreenHeight() - 10 - subtractInputHeight)
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'show items again if somone hovers over the list (-> reset timer)
		If Self.guiList._mouseOverArea
			For Local entry:TGuiObject = EachIn Self.guiList.entries
				entry.show()
			Next
		EndIf
	End Method


	Method Draw()
		Super.Draw()
	End Method
End Type


Type TGUIGameWindow Extends TGUIWindow
	Field contentBoxes:TGUIBackgroundBox[]

	Global childSprite:TGW_NinePatchSprite


	Method Create:TGUIGameWindow(x:Int, y:Int, width:Int = 100, height:Int= 100, State:String = "")
		Super.Create(x,y,width,height,State)

		GetPadding().SetTop(35)

		SetCaptionArea(TRectangle.Create(20, 10, GetContentScreenWidth() - 2*20, 25))
		guiCaptionTextBox.SetValueAlignment("LEFT", "TOP")

		If Not childSprite Then childSprite = Assets.GetNinePatchSprite("gfx_gui_panel.content")

		Return Self
	End Method


	'special handling for child elements of kind GuiGameBackgroundBox
	Method AddContentBox:TGUIBackgroundBox(displaceX:Int=0, displaceY:Int=0, w:Int=-1, h:Int=-1)
		If w < 0 Then w = GetContentScreenWidth()
		If h < 0 Then h = GetContentScreenHeight()

		'replace single-content-window-sprite (aka: remove "drawn on"-contentimage)
		Self.guiBackground.sprite = Assets.GetNinePatchSprite("gfx_gui_panel")

		Local maxOtherBoxesY:Int = 0
		If children
			For Local box:TGUIBackgroundBox = EachIn contentBoxes
				maxOtherBoxesY = Max(maxOtherBoxesY, box.rect.GetY() + box.rect.GetH())
				'after each box we want a gap
				maxOtherBoxesY :+ TGUISettings.panelGap
			Next
		EndIf
		Local box:TGUIBackgroundBox = New TGUIBackgroundBox.Create(displaceX, maxOtherBoxesY + displaceY, w, h, "")

		box.sprite = childSprite
		box.spriteAlpha = 1.0
		box.SetPadding(TGUISettings.panelGap,TGUISettings.panelGap,TGUISettings.panelGap,TGUISettings.panelGap)
		AddChild(box)

		contentBoxes = contentBoxes[.. contentBoxes.length +1]
		contentBoxes[contentBoxes.length-1] = box


		'resize self so it fits
		Local newHeight:Int = box.rect.GetY() + box.rect.GetH()
		'add padding
		newHeight :+ GetPadding().GetTop() + GetPadding().GetBottom()
		resize(rect.GetW(), Max(rect.GetH(), newHeight))

		Return box
	End Method


	Method Update:Int()
		If guiCaptionTextBox Then guiCaptionTextBox.useFont = .headerFont
		'self.guiTextBox.useFont = .modalWindowTextFont

		Super.Update()
	End Method
End Type




Type TGUIGameModalWindow Extends TGUIModalWindow
	Method Create:TGUIGameModalWindow(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		_defaultValueColor = TColor.clBlack.copy()
		_defaultCaptionColor = TColor.clWhite.copy()
		Super.Create(x,y,width,height,limitState)

'		GetPadding().SetTop(35)

		SetCaptionArea(TRectangle.Create(20, 10, GetContentScreenWidth() - 2*20, 25))
		guiCaptionTextBox.SetValueAlignment("CENTER", "TOP")


		Return Self
	End Method

	Method SetCaption:Int(caption:String="")
		Super.SetCaption(caption)
		If guiCaptionTextBox Then guiCaptionTextBox.useFont = .headerFont
	End Method
End Type




Type TGUIChatEntry Extends TGUIListItem
	Field paddingBottom:Int		= 5


	Method CreateSimple:TGUIChatEntry(text:String, textColor:TColor, senderName:String, senderColor:TColor, lifetime:Int=Null)
		Create(text)
		SetLifetime(lifeTime)
		SetShowtime(lifeTime)
		SetSender(senderName, senderColor)
		SetLabel(text,textColor)

		Return Self
	End Method


    Method Create:TGUIChatEntry(text:String="",x:Float=0.0,y:Float=0.0,width:Int=120,height:Int=20)
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(x,y,"",Null)

		Resize( width, height )
		label = text

		setLifetime( 1000 )
		setShowtime( 1000 )

		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TPoint()
		Local move:TPoint = TPoint.Create(0,0)
		If Self.Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Self.Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = Assets.fonts.baseFontBold.drawStyled(Self.Data.getString("senderName")+":", Self.getScreenX(), Self.getScreenY(), senderColor, 2, 0)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		EndIf
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = parentPanel.getContentScreenWidth()-Self.rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TPoint = Assets.fonts.baseFont.drawBlock(label, getScreenX()+move.x, getScreenY()+move.y, maxWidth-move.X, maxHeight, Null, Null, 2, 0)

		'add padding
		dimension.moveXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
			'recalculate item positions and scroll limits
'			local list:TGUIListBase = TGUIListBase(self.getParent("tguilistbase"))
'			if list then list.RecalculateElements()
		EndIf

		Return dimension
	End Method


	Method SetSender:Int(senderName:String=Null, senderColor:TColor=Null)
		If senderName Then Self.Data.AddString("senderName", senderName)
		If senderColor Then Self.Data.Add("senderColor", senderColor)
	End Method


	Method getParentWidth:Float(parentClassName:String="toplevelparent")
		If Not Self._parent Then Return Self.rect.getW()
		Return Self.getParent(parentClassName).rect.getW()
	End Method


	Method getParentHeight:Float(parentClassName:String="toplevelparent")
		If Not Self._parent Then Return Self.rect.getH()
		Return Self.getParent(parentClassName).rect.getH()
	End Method


	Method Draw:Int()
		Self.getParent("tguilistbase").RestrictViewPort()

		If Self.showtime <> Null Then SetAlpha Float(Self.showtime-MilliSecs())/500.0
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = parentPanel.getContentScreenWidth()-Self.rect.getX()

		'local maxWidth:int = self.getParentWidth("tguiscrollablepanel")-self.rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local move:TPoint = TPoint.Create(0,0)
		If Self.Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Self.Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = Assets.fonts.baseFontBold.drawStyled(Self.Data.getString("senderName", "")+":", Self.getScreenX(), Self.getScreenY(), senderColor, 2, 1)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		EndIf
		Assets.fonts.baseFont.drawBlock(label, getScreenX()+move.x, getScreenY()+move.y, maxWidth-move.X, maxHeight, Null, labelColor, 2, 1, 0.5)

		SetAlpha 1.0

		Self.getParent("tguilistbase").ResetViewPort()
	End Method
End Type




'create a custom type so we can check for doublettes on add
Type TGUIGameList Extends TGUISelectList


    Method Create:TGUIGameList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height, State)

		Return Self
	End Method


	'override default
	Method RegisterListeners:Int()
		'we want to know about clicks
		EventManager.registerListenerMethod( "guiobject.onClick",	Self, "onClickOnEntry", "TGUIGameEntry" )
	End Method


	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUIGameEntry = TGUIGameEntry( triggerEvent.getSender() )
		If Not entry Then Return False

		Return Super.onClickOnEntry(triggerEvent)
	End Method


	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		For Local olditem:TGUIListItem = EachIn Self.entries
			If TGUIGameEntry(item) And TGUIGameEntry(item).label = olditem.label
				'refresh lifetime
				olditem.setLifeTime(olditem.initialLifeTime)
				'unset the new one
				item.remove()
				Return False
			EndIf
		Next
		Return Super.AddItem(item, extra)
	End Method
End Type




Type TGUIGameEntry Extends TGUISelectListItem
	Field paddingBottom:Int		= 3
	Field paddingTop:Int		= 2


	Method CreateSimple:TGUIGameEntry(_hostIP:String, _hostPort:Int, _hostName:String="", gameTitle:String="", slotsUsed:Int, slotsMax:Int)
		'make it "unique" enough
		Self.Create(_hostIP+":"+_hostPort)

		Self.data.AddString("hostIP", _hostIP)
		Self.data.AddNumber("hostPort", _hostPort)
		Self.data.AddString("hostName", _hostName)
		Self.data.AddString("gameTitle", gametitle)
		Self.data.AddNumber("slotsUsed", slotsUsed)
		Self.data.AddNumber("slotsMax", slotsMax)

		Return Self
	End Method


    Method Create:TGUIGameEntry(text:String="",x:Float=0.0,y:Float=0.0,width:Int=120,height:Int=20)
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(x,y,"",Null)

		Self.SetLifetime(30000) '30 seconds
		Self.SetLabel(":D", TColor.Create(0,0,0))

		Self.Resize( width, height )

		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TPoint()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = parentPanel.getContentScreenWidth()-Self.rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local text:String = Self.Data.getString("gameTitle","#unknowngametitle#")+" by "+ Self.Data.getString("hostName","#unknownhostname#") + " ("+Self.Data.getInt("slotsUsed",1)+"/"+Self.Data.getInt("slotsMax",4)
		Local dimension:TPoint = Assets.fonts.baseFont.drawBlock(text, getScreenX(), getScreenY(), maxWidth, maxHeight, Null, Null, 2, 0)

		'add padding
		dimension.moveXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method


	Method Draw:Int()
		'self.getParent("topitem").RestrictViewPort()

		If Self.showtime <> Null Then SetAlpha Float(Self.showtime-MilliSecs())/500.0

		'draw highlight-background etc
		Super.Draw()

		'draw text
		Local move:TPoint = TPoint.Create(0, Self.paddingTop)
		Local text:String = ""
		Local textColor:TColor = Null
		Local textDim:TPoint = Null
		'line: title by hostname (slotsused/slotsmax)

		text 		= Self.Data.getString("gameTitle","#unknowngametitle#")
		textColor	= TColor(Self.Data.get("gameTitleColor", TColor.Create(150,80,50)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor, 2, 1,0.5)
		move.moveXY(textDim.x,1)

		text 		= " by "+Self.Data.getString("hostName","#unknownhostname#")
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(50,50,150)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.moveXY(textDim.x,0)

		text 		= " ("+Self.Data.getInt("slotsUsed",1)+"/"++Self.Data.getInt("slotsMax",4)+")"
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(0,0,0)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.moveXY(textDim.x,0)

		SetAlpha 1.0

		'self.getParent("topitem").ResetViewPort()
	End Method
End Type




Type THotspot
	Field area:TRectangle			= TRectangle.Create(0,0,0,0)
	Field name:String				= ""
	Field tooltip:TTooltip			= Null
	Field tooltipText:String		= ""
	Field tooltipDescription:String	= ""
	Field hovered:Int				= False
	Field id:int					= 0
	Global LastID:int 				= 0
	Global list:TList				= CreateList()

	Method New()
		LastID:+1
		id = LastID

	End Method


	Method Create:THotSpot(name:String, x:Int,y:Int,w:Int,h:Int)
		Self.area = TRectangle.Create(x,y,w,h)
		Self.name = name

		list. AddLast(self)
		Return Self
	End Method


	Function Get:THotspot(id:int)
		For local hotspot:THotspot = eachin list
			if hotspot.id = id then return hotspot
		Next

		return Null
	End Function


	Method setTooltipText( text:String="", description:String="" )
		Self.tooltipText		= text
		Self.tooltipDescription = description
	End Method


	Method Update:Int(offsetX:Int=0,offsetY:Int=0)
		'update tooltip
		'handle clicks -> send events so eg can send figure to it

		Local adjustedArea:TRectangle = area.copy()
		adjustedArea.position.moveXY(offsetX, offsetY)

		If adjustedArea.containsXY(MOUSEMANAGER.x, MOUSEMANAGER.y)
			hovered = True
			If MOUSEMANAGER.isClicked(1)
				EventManager.triggerEvent( TEventSimple.Create("hotspot.onClick", new TData , Self ) )
			EndIf
		Else
			hovered = False
		EndIf

		If hovered
			If tooltip
				tooltip.Hover()
			ElseIf tooltipText<>""
				tooltip = TTooltip.Create(tooltipText, tooltipDescription, 100, 140, 0, 0)
				tooltip.enabled = True
			EndIf
		EndIf

		If tooltip And tooltip.enabled
			tooltip.area.position.SetXY( adjustedArea.getX() + adjustedArea.getW()/2 - tooltip.GetWidth()/2, adjustedArea.getY() - tooltip.GetHeight())
			tooltip.Update( App.Timer.getDelta() )
			'delete old tooltips
			If tooltip.lifetime < 0 Then tooltip = Null
		EndIf
	End Method


	Method Draw:Int(offsetX:Int=0,offsetY:Int=0)
		If tooltip Then tooltip.draw()
	End Method
End Type




Type TSaveFile
	Field xml:TXmlHelper
	Field node:TxmlNode
	Field currentnode:TxmlNode
	Field Nodes:TxmlNode[10]
	Field NodeDepth:Int = 0
	Field lastNode:TxmlNode


	Function Create:TSaveFile()
		Return New TSaveFile
	End Function


	Method InitSave()
		Self.xml		= New TXmlHelper
		Self.xml.file	= TxmlDoc.newDoc("1.0")
		Self.xml.root 	= TxmlNode.newNode("tvtsavegame")
		Self.xml.file.setRootElement(Self.xml.root)
		Self.Nodes[0]	= xml.root
		Self.lastNode	= xml.root
	End Method


	Method InitLoad(filename:String="save.xml", zipped:Byte=0)
		Self.xml		= New TXmlHelper
		Self.xml.file	= TxmlDoc.parseFile(filename)
		Self.xml.root	= xml.file.getRootElement()
		Self.node		= Self.xml.root
	End Method


	Method xmlWrite(typ:String="unknown",str:String, newDepth:Byte=0, depth:Int=-1)
		If depth <=-1 Or depth >=10 Then depth = Self.NodeDepth ';newDepth=False
		If newDepth
			Self.Nodes[Self.NodeDepth+1] = Self.Nodes[depth].addChild( typ )
			Self.Nodes[Self.NodeDepth+1].addAttribute("var", str)
			Self.NodeDepth:+1
		Else
			Self.Nodes[depth].addChild( typ ).addAttribute("var", str)
		EndIf
	End Method


	Method xmlCloseNode()
		Self.NodeDepth:-1
	End Method


	Method xmlBeginNode(str:String)
		Self.Nodes[Self.NodeDepth + 1] = Self.Nodes[Self.NodeDepth].AddChild( str )
		Self.NodeDepth:+1
	End Method


	Method xmlSave(filename:String="-", zipped:Byte=0)
		If filename = "-" Then Print "nodes:"+Self.xml.root.getChildren().count() Else Self.xml.file.saveFile(filename)
	End Method

'deprecated
Rem
	'Summary: saves an object to defined XMLstream
	Method SaveObject:Int(obj:Object, nodename:String, _addfunc(obj:Object))
		Local result:String = ""
	    Self.xmlBeginNode(nodename)
			'list of objects as obj-param - iterate through all listobjects
			If TList(obj) <> Null
				For Local listobj:Object = EachIn TList(obj)
					SaveObject(listobj, nodename + "_CHILD", _addfunc)
				Next
			Else
				Local typ:TTypeId = TTypeId.ForObject(obj)
				For Local t:TField = EachIn typ.EnumFields()
					If t.MetaData("sl") <> "no"
						local fieldtype:TTypeId = TTypeId.ForObject(t.get(obj))
						If fieldtype.ExtendsType(ArrayTypeId)
							If fieldtype.ArrayLength(typ) > 0
								Print "array '" + t.Name() + " - " + fieldtype.Name() + "'"
							EndIf
						End If
						If TList(t.get(obj)) <> Null
							Local liste:TList = TList(t.get(obj))
							For Local childobj:Object = EachIn liste
								Print "saving list children..."
								Self.SaveObject(childobj, nodename + "_CHILD", _addfunc)
							Next
						Else
							Self.xmlWrite(Upper(t.name()), String(t.get(obj)))
						End If
					EndIf
				Next
				If _addfunc <> Null Then _addfunc(obj)
			EndIf
		Self.xmlCloseNode()
	End Method
endrem

	'Summary: loads an object from a XMLstream
	Method LoadObject:Object(obj:Object, _handleNodefunc(_obj:Object, _node:TxmlNode))
		Print "implement LoadObject"
		Return Null
	End Method
End Type
Global LoadSaveFile:TSaveFile = TSaveFile.Create()





'tooltips containing headline and text, updated and drawn by Tinterface
Type TTooltip Extends TRenderable
	Field lifetime:Float		= 0.1		'how long this tooltip is existing
	Field fadeValue:Float		= 1.0		'current fading value (0-1.0)
	Field _startLifetime:Float	= 1.0		'initial lifetime value
	Field _startFadingTime:Float= 0.20		'at which lifetime fading starts
	Field title:String
	Field content:String
	Field image:TImage			= Null
	Field dirtyImage:Int		= 1
	Field tooltipImage:Int		=-1
	Field titleBGtype:Int		= 0
	Field enabled:Int			= 0
	Field _oldTitle:String

	Global tooltipHeader:TGW_Sprite
	Global tooltipIcons:TGW_Sprite
	Global list:TList 			= CreateList()

	Global useFontBold:TGW_BitmapFont
	Global useFont:TGW_BitmapFont
	Global imgCacheEnabled:Int	= True


	Function Create:TTooltip(title:String = "", content:String = "unknown", x:Int = 0, y:Int = 0, w:Int = -1, h:Int = -1, lifetime:Int = 300)
		Local obj:TTooltip = New TTooltip
		obj.Initialize(title, content, x, y, w, h, lifetime)

		list.addLast(obj)
		Return obj
	End Function


	Method Initialize:Int(title:String="", content:String="unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Self.title				= title
		Self._oldTitle			= title
		Self.content			= content
		Self.area				= TRectangle.Create(x, y, w, h)
		Self.tooltipimage		= -1
		Self._startLifetime		= Float(lifetime) / 1000.0 	'in seconds
		Self._startFadingTime	= Min(_startLifetime/2.0, 0.1)
		Self.Hover()
	End Method


	'reset lifetime
	Method Hover()
		lifeTime 	= _startLifetime
		fadeValue	= 1.0
	End Method


	Method Update:Int(deltaTime:Float=1.0)
		lifeTime :- deltaTime

		'start fading if lifetime is running out (lower than fade time)
		If lifetime <= _startFadingTime
			fadeValue :- deltaTime
			fadeValue :* 0.8 'speed up fade
		EndIf

		If lifeTime <= 0 ' And enabled 'enabled - as pause sign?
			Image	= Null
			enabled	= False
			List.remove(Self)
		EndIf

		If dirtyImage
			'limit to visible areas
			area.position.SetX( Max(21, Min(area.GetX(), 759 - GetWidth())) )
			'limit to screen too
			area.position.SetY( Max(10, Min(area.GetY(), 600 - GetHeight())) )
		EndIf
	End Method


	Method getWidth:Int()
		If Not DirtyImage And Image And imgCacheEnabled Then Return image.width

		'manual config
		If area.GetW() > 0 Then Return area.GetW()

		'auto width calculation
		If area.GetW() <= 0
			Local result:Int = 0
			'width from title + content + spacing
			result = UseFontBold.getWidth(title)+6
			'add icon to width
			If tooltipimage >=0 Then result:+ ToolTipIcons.framew + 2
			'compare with content text width
			result = Max(GetContentWidth() + 6, result)
			result :+ 4 'extra spacing
			Return result
		EndIf
	End Method


	Method getHeight:Int()
		If Not DirtyImage And Image And imgCacheEnabled Then Return image.height

		'manual config
		If area.GetH() > 0 Then Return area.GetH()

		'auto height calculation
		If area.GetH() <= 0
			Local result:Int = 0
			'height from title + content + spacing
			result:+ getTitleHeight()
			result:+ getContentHeight()
			Return result
		EndIf
	End Method


	Method getTitleHeight:Int()
		Local result:Int = TooltipHeader.area.GetH()
		'add icon to height of caption
		'If tooltipimage >= 0 Then result :+ 2
		Return result
	End Method


	Method getContentWidth:Int()
		'only add a line if there is text
		If Len(content)>1 Then Return UseFont.getWidth(content)
		Return 0
	End Method


	Method getContentHeight:Int()
		'only add a line if there is text
		If Len(content)>1 Then Return UseFont.getHeight(content) + 8
		Return 0
	End Method


	Method DrawShadow(width:Float, height:Float)
		SetColor 0, 0, 0
		SetAlpha getFadeAmount() * 0.3
		DrawRect(area.GetX()+2, area.GetY()+2, width, height)

		SetAlpha getFadeAmount() * 0.1
		DrawRect(area.GetX()+1, area.GetY()+1, width, height)
		SetColor 255,255,255
	End Method


	Method getFadeAmount:Float()
		Return fadeValue
'		if (startLifetime - lifetime) >= startFadeTime then return 1.0

'		return (100.0 * (fadeTime - startFadeTime)) / 100.0
	End Method


	Method DrawHeader:Int(x:Float, y:Float, width:Int, height:Int)
		If TitleBGtype = 0 Then SetColor 250,250,250
		If TitleBGtype = 1 Then SetColor 200,250,200
		If TitleBGtype = 2 Then SetColor 250,150,150
		If TitleBGtype = 3 Then SetColor 200,200,250
		TooltipHeader.TileDraw(x, y, width, height)

		SetColor 255,255,255
		Local displaceX:Float = 0.0
		If tooltipimage >=0
			TTooltip.ToolTipIcons.Draw(x, y, tooltipimage)
			displaceX = TTooltip.ToolTipIcons.framew
		EndIf
'		SetAlpha getFadeAmount()
		'caption
		useFontBold.drawStyled(title, x+5+displaceX, y+height/2 - useFontBold.getHeight("ABC")/2 +2 , TColor.Create(50,50,50), 2, 1, 0.1)
'		SetAlpha 1.0
	End Method


	Method DrawContent:Int(x:Int, y:Int, width:Int, height:Int)
		SetColor 90,90,90
		'content
		If content <> "" Then Usefont.draw(content, area.GetX()+5,area.GetY()+TooltipHeader.area.GetH() + 7)
		SetColor 255, 255, 255
	End Method


	Method Draw:Int(tweenValue:Float=1.0)
		If Not enabled Then Return 0

		'reset cache if title changes
		'TODO RONNY: make obsolete and take care in correct position
		If title <> _oldTitle Then DirtyImage = True


		If DirtyImage Or Not Image Or Not imgCacheEnabled
			Local boxWidth:Int	= GetWidth()
			Local boxHeight:Int	= GetHeight()
			Local captionHeight:Int = GetTitleHeight()
			DrawShadow(boxWidth, boxHeight)

			SetAlpha getFadeAmount()
			SetColor 0,0,0
			'border
			DrawRect(area.GetX(), area.GetY(), boxWidth, boxHeight)
			'bright background
			SetColor 255,255,255
			DrawRect(area.GetX()+1, area.GetY()+1, boxWidth-2, boxHeight-2)

			'draw header including caption and header background
			DrawHeader(area.GetX()+1, area.GetY()+1, boxWidth-2, captionHeight)

			'draw content - do not use contentHeight here..
			'if boxHeight was defined manually we just give it the left space
			'as a caption has to get drawn in all cases...
			DrawContent(area.GetX()+1, area.GetY()+1 + captionHeight, boxWidth-2, boxHeight-captionHeight-2)


			If imgCacheEnabled 'And lifetime = startlifetime
				Image = TImage.Create(boxWidth, boxHeight, 1, 0, 255, 0, 255)
				image.pixmaps[0] = VirtualGrabPixmap(Self.area.GetX(), Self.area.GetY(), boxWidth, boxHeight)
				DirtyImage = False
			EndIf
			_oldTitle = title
		Else 'not dirty
			DrawShadow(ImageWidth(image),ImageHeight(image))
			SetAlpha getFadeAmount()
			SetColor 255,255,255
			DrawImage(image, area.GetX(), area.GetY())
			SetAlpha 1.0
		EndIf
	End Method
End Type







	Function DrawDialog(dialogueType:String="default", x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogFont:TGW_BitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TGW_Sprite = Assets.getSprite(DialogStart)
		height = Max(95, height ) 'minheight
		If DialogStart = "StartLeftDown" Then dx = x - 48;dy = y + Height/3 + DialogStartMove;width:-48
		If DialogStart = "StartRightDown" Then dx = x + width - 12;dy = y + Height/2 + DialogStartMove;width:-48
		If DialogStart = "StartDownRight" Then dx = x + width/2 + DialogStartMove;dy = y + Height - 12;Height:-53
		If DialogStart = "StartDownLeft" Then dx = x + width/2 + DialogStartMove;dy = y + Height - 12;Height:-53

		Assets.GetNinePatchSprite("dialogue."+dialogueType).DrawArea(x,y,width,height)

		DialogSprite.Draw(dx, dy)
		If DialogText <> "" Then DialogFont.drawBlock(DialogText, x + 10, y + 10, width - 16, Height - 16, Null, TColor.clBlack)
	End Function

	'draws a rounded rectangle (blue border) with alphashadow
	Function DrawGFXRect(gfx_Rect:TGW_SpritePack, x:Int, y:Int, width:Int, Height:Int, nameBase:String="gfx_gui_rect_")
		gfx_Rect.getSprite(nameBase+"TopLeft").Draw(x, y)
		gfx_Rect.getSprite(nameBase+"TopRight").Draw(x + width, y,-1, TPoint.Create(ALIGN_RIGHT, ALIGN_TOP))
		gfx_Rect.getSprite(nameBase+"BottomLeft").Draw(x, y + Height, -1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))
		gfx_Rect.getSprite(nameBase+"BottomRight").Draw(x + width, y + Height, -1, TPoint.Create(ALIGN_RIGHT, ALIGN_BOTTOM))

		gfx_Rect.getSprite(nameBase+"BorderLeft").TileDraw(x, y + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH(), gfx_Rect.getSprite(nameBase+"BorderLeft").area.GetW(), Height - gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetH() - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH())
		gfx_Rect.getSprite(nameBase+"BorderRight").TileDraw(x + width - gfx_Rect.getSprite(nameBase+"BorderRight").area.GetW(), y + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH(), gfx_Rect.getSprite(nameBase+"BorderRight").area.GetW(), Height - gfx_Rect.getSprite(nameBase+"BottomRight").area.GetH() - gfx_Rect.getSprite(nameBase+"TopRight").area.GetH())
		gfx_Rect.getSprite(nameBase+"BorderTop").TileDraw(x + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW(), y, width - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW() - gfx_Rect.getSprite(nameBase+"TopRight").area.GetW(), gfx_Rect.getSprite(nameBase+"BorderTop").area.GetH())
		gfx_Rect.getSprite(nameBase+"BorderBottom").TileDraw(x + gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetW(), y + Height - gfx_Rect.getSprite(nameBase+"BorderBottom").area.GetH(), width - gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetW() - gfx_Rect.getSprite(nameBase+"BottomRight").area.GetW(), gfx_Rect.getSprite(nameBase+"BorderBottom").area.GetH())
		gfx_Rect.getSprite(nameBase+"Back").TileDraw(x + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW(), y + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH(), width - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW() - gfx_Rect.getSprite(nameBase+"TopRight").area.GetW(), Height - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH() - gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetH())
	End Function





Type TBlockGraphical Extends TBlockMoveable
	Field imageBaseName:String
	Field imageDraggedBaseName:String
	Field image:TGW_Sprite
	Field image_dragged:TGW_Sprite
    Global AdditionallyDragged:Int	= 0
End Type




Type TGameObject {_exposeToLua="selected"}
	Field id:Int		= 0 	{_exposeToLua}
	Global LastID:Int	= 0

	Method New()
		LastID:+1
		'assign a new id
		id = LastID
	End Method

	Method GetID:Int() {_exposeToLua}
		Return id
	End Method


	'overrideable method for cleanup actions
	Method Remove()
	End Method
End Type




Type TOwnedGameObject Extends TGameObject {_exposeToLua="selected"}
	Field owner:Int		= 0


	Method SetOwner:Int(owner:Int=0) {_exposeToLua}
		Self.owner = owner
	End Method


	Method GetOwner:Int() {_exposeToLua}
		Return owner
	End Method
End Type




'a graphical representation of multiple object ingame
Type TGUIGameListItem Extends TGUIListItem
	Field assetNameDefault:String = "gfx_movie0"
	Field assetNameDragged:String = "gfx_movie0"
	Field asset:TGW_Sprite = Null
	Field assetDefault:TGW_Sprite = Null
	Field assetDragged:TGW_Sprite = Null


    Method Create:TGUIGameListItem(label:String="",x:Float=0.0,y:Float=0.0,width:Int=120,height:Int=20)
		'creates base, registers click-event,...
		Super.Create(label, x,y,width,height)

   		Self.InitAssets()
   		Self.SetAsset()

		Return Self
	End Method


	Method InitAssets(nameDefault:String="", nameDragged:String="")
		If nameDefault = "" Then nameDefault = Self.assetNameDefault
		If nameDragged = "" Then nameDragged = Self.assetNameDragged

		Self.assetNameDefault = nameDefault
		Self.assetNameDragged = nameDragged
		Self.assetDefault = Assets.GetSprite(nameDefault)
		Self.assetDragged = Assets.GetSprite(nameDragged)

		Self.SetAsset(Self.assetDefault)
	End Method


	Method SetAsset(sprite:TGW_Sprite=Null)
		If Not sprite Then sprite = Self.assetDefault

		'only resize if not done already
		If Self.asset <> sprite
			Self.asset = sprite
			Self.Resize(sprite.area.GetW(), sprite.area.GetH())
		EndIf
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		If Self.mouseover Or Self.isDragged()
			EventManager.triggerEvent(TEventSimple.Create("guiGameObject.OnMouseOver", new TData, Self))
		EndIf

		If Self.mouseover Then Game.cursorstate = 1
		If Self.isDragged()
			Self.SetAsset(Self.assetDragged)
			Game.cursorstate = 2
		EndIf
	End Method


	Method Draw()
		asset.draw(Self.GetScreenX(), Self.GetScreenY())
		'hovered
		If Self.mouseover
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend
			asset.draw(Self.GetScreenX(), Self.GetScreenY())
			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf
	End Method
End Type




Type TBlockMoveable Extends TOwnedGameObject
	Field rect:TRectangle			= TRectangle.Create(0,0,0,0)
	Field dragable:Int				= 1 {saveload = "normalExt"}
	Field dragged:Int				= 0 {saveload = "normalExt"}
	Field OrigPos:TPoint 			= TPoint.Create(0, 0) {saveload = "normalExtB"}
	Field StartPos:TPoint			= TPoint.Create(0, 0) {saveload = "normalExt"}
	Field StartPosBackup:TPoint		= TPoint.Create(0, 0)


	'switches coords and state of blocks
	Method SwitchBlock(otherObj:TBlockMoveable)
		Self.SwitchCoords(otherObj)
		Local old:Int	= Self.dragged
		Self.dragged	= otherObj.dragged
		otherObj.dragged= old
	End Method


	'switches current and startcoords of two blocks
	Method SwitchCoords(otherObj:TBlockMoveable)
		TPoint.SwitchPos(Self.rect.position, 	otherObj.rect.position)
		TPoint.SwitchPos(Self.StartPos,			otherObj.StartPos)
		TPoint.SwitchPos(Self.StartPosBackup,	otherObj.StartPosBackup)
	End Method


	'checks if x, y are within startPoint+dimension
	Method containsCoord:Byte(x:Int, y:Int)
		Return TFunctions.IsIn( x,y, Self.StartPos.getX(), Self.StartPos.getY(), Self.rect.getW(), Self.rect.getH() )
	End Method


	Method SetCoords(x:Int=Null, y:Int=Null, startx:Int=Null, starty:Int=Null)
      If x<>Null 		Then Self.rect.position.SetX(x)
      If y<>Null		Then Self.rect.position.SetY(y)
      If startx<>Null	Then Self.StartPos.setX(startx)
      If starty<>Null	Then Self.StartPos.SetY(starty)
	End Method


	Method SetBasePos(pos:TPoint = Null)
		If pos <> Null
			Self.rect.position.setPos(pos)
			Self.StartPos.setPos(pos)
		EndIf
	End Method


	Method IsAtStartPos:Int()
		Return Self.rect.position.isSame(Self.StartPos, True)
	End Method


	Function SortDragged:Int(o1:Object, o2:Object)
		Local s1:TBlockMoveable = TBlockMoveable(o1)
		Local s2:TBlockMoveable = TBlockMoveable(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (s1.dragged * 100)-(s2.dragged * 100)
	End Function
End Type


Type TError
	Field title:String
	Field message:String
	Field id:Int
	Field link:TLink
	Field pos:TPoint

	Global List:TList = CreateList()
	Global LastID:Int=0
	Global sprite:TGW_Sprite


	Function Create:TError(title:String, message:String)
		Local obj:TError =  New TError
		obj.title	= title
		obj.message	= message
		obj.id		= LastID
		LastID :+1
		If obj.sprite = Null Then obj.sprite = Assets.getSprite("gfx_errorbox")
		obj.pos		= TPoint.Create(400-obj.sprite.area.GetW()/2 +6, 200-obj.sprite.area.GetH()/2 +6)
		obj.link	= List.AddLast(obj)
		Return obj
	End Function

	Function hasActiveError:Int()
		Return (List.count() > 0)
	End Function


	Function CreateNotEnoughMoneyError()
		TError.Create(getLocale("ERROR_NOT_ENOUGH_MONEY"),getLocale("ERROR_NOT_ENOUGH_MONEY_TEXT"))
	End Function


	Function DrawErrors()
		Local error:TError = TError(List.Last())
		If error Then error.draw()
	End Function


	Function UpdateErrors()
		Local error:TError = TError(List.Last())
		If error Then error.Update()
	End Function


	Method Update()
		MouseManager.resetKey(2) 'no right clicking allowed as long as "error notice is active"
		If Mousemanager.IsClicked(1)
			If TFunctions.MouseIn(pos.x,pos.y, sprite.area.GetW(), sprite.area.GetH())
				link.Remove()
				MouseManager.resetKey(1) 'clicked to remove error
			EndIf
		EndIf
	End Method


	Function DrawNewError(str:String="unknown error")
		TError(TError.List.Last()).message = str
		TError.DrawErrors()
		Flip 0
	End Function


	Method Draw()
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(20,10,760, 373)
		SetAlpha 1.0
		Game.cursorstate = 0
		SetColor 255,255,255
		sprite.Draw(pos.x,pos.y)
		Assets.getFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.area.GetW() - 60, 40, Null, TColor.Create(150, 50, 50))
		Assets.getFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.area.GetW()-40, sprite.area.GetH()-60, Null, TColor.Create(50, 50, 50))
  End Method
End Type




'Answer - objects for dialogues
Type TDialogueAnswer
	Field _text:String = ""
	Field _leadsTo:Int = 0
	Field _onUseEvent:TEventBase
	Field _highlighted:Int = 0


	Function Create:TDialogueAnswer (text:String, leadsTo:Int = 0, onUseEvent:TEventBase= Null)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text		= Text
		obj._leadsTo	= leadsTo
		obj._onUseEvent	= onUseEvent
		Return obj
	End Function


	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Self._highlighted = False
		If TFunctions.MouseIn( x, y-2, w, Assets.getFont("Default", 12).getBlockHeight(Self._text, w, h))
			Self._highlighted = True
			If clicked
				'emit the event if there is one
				If _onUseEvent Then EventManager.triggerEvent(_onUseEvent)
				Return _leadsTo
			EndIf
		EndIf
		Return - 1
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		If Self._highlighted
			SetColor 200,100,100
			DrawOval(x, y +3, 6, 6)
			Assets.getFont("Default", 12, BoldFont).drawBlock(Self._text, x+9, y-1, w-10, h, Null, TColor.Create(0, 0, 0))
		Else
			SetColor 0,0,0
			DrawOval(x, y +3, 6, 6)
			Assets.getFont("Default", 12).drawBlock(Self._text, x+10, y, w-10, h, Null, TColor.Create(100, 100, 100))
		EndIf
	End Method
End Type




'Texts, maintext + list of answers to this said thing ;D
Type TDialogueTexts
	Field _text:String = ""
	Field _answers:TList = CreateList() 'of TDialogueAnswer
	Field _goTo:Int = -1


	Function Create:TDialogueTexts(text:String)
		Local obj:TDialogueTexts = New TDialogueTexts
		obj._text = Text
		Return obj
	End Function


	Method AddAnswer(answer:TDialogueAnswer)
		Self._answers.AddLast(answer)
	End Method


	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Local ydisplace:Float = Assets.getFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit
		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(x + 9, y + ydisplace, w - 9, h, clicked)
			If returnValue <> - 1 Then _goTo = returnValue
			ydisplace:+Assets.getFont("Default", 14).getHeight(answer._text) + 2
		Next
		Return _goTo
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		Local ydisplace:Float = Assets.getFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit

		Local lineHeight:Int = 2 + Assets.getFont("Default", 14).getHeight("QqT") 'high chars, low chars

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer.Draw(x, y + ydisplace, w, h)
			ydisplace:+ lineHeight
		Next
	End Method
End Type




Type TDialogue
	Field _texts:TList = CreateList() 'of TDialogueTexts
	Field _currentText:Int = 0
	Field _rect:TRectangle = TRectangle.Create(0,0,0,0)


	Function Create:TDialogue(x:Float, y:Float, w:Float, h:Float)
		Local obj:TDialogue = New TDialogue
		obj._rect.position.SetXY(x,y)
		obj._rect.dimension.SetXY(w,h)
		Return obj
	End Function


	Method AddText(Text:TDialogueTexts)
		Self._texts.AddLast(Text)
	End Method


	Method Update:Int(isMouseHit:Int = 0)
		Local clicked:Int = MouseManager.isHit(1) + MouseManager.IsDown(1)
		If clicked >= 1 Then clicked = 1;MouseManager.resetKey(1)
		Local nextText:Int = _currentText
		If Self._texts.Count() > 0

			Local returnValue:Int = TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Update(Self._rect.getX() + 10, Self._rect.getY() + 10, Self._rect.getW() - 60, Self._rect.getH(), clicked)
			If returnValue <> - 1 Then nextText = returnValue
		EndIf
		_currentText = nextText
		If _currentText = -2 Then _currentText = 0;Return 0
		Return 1
	End Method


	Method Draw()
		SetColor 255, 255, 255
	    DrawDialog("default", _rect.getX(), _rect.getY(), _rect.getW(), _rect.getH(), "StartLeftDown", 0, "", Assets.getFont("Default", 14))
		SetColor 0, 0, 0
		If Self._texts.Count() > 0 Then TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Draw(Self._rect.getX() + 10, Self._rect.getY() + 10, Self._rect.getW() - 60, Self._rect.getH())
		SetColor 255, 255, 255
	End Method
End Type


'extend tooltip to overwrite draw method
Type TTooltipAudience Extends TTooltip
	Field audienceResult:TAudienceResult
	Field showDetails:Int = False
	Field lineHeight:Int = 0
	Field lineIconHeight:Int = 0

	Function Create:TTooltipAudience(title:String = "", text:String = "unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Local obj:TTooltipAudience = New TTooltipAudience
		obj.Initialize(title, text, x, y, w, h, lifetime)

		Return obj
	End Function


	'override to add lineheight
	Method Initialize:Int(title:String="", content:String="unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Super.Initialize(title, content, x, y, w, h, lifetime)
		Self.lineHeight = Self.useFont.GetHeight("Qg") 'Qg - big + underline char
		'text line with icon
		Self.lineIconHeight = Max(lineHeight, Assets.getSprite("gfx_targetGroup1").area.GetH())
	End Method


	Method SetAudienceResult(audienceResult:TAudienceResult)
		Self.audienceResult = audienceResult
	End Method


	Method GetContentWidth:Int()
		If audienceResult
			Return Self.useFont.GetWidth( GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + TFunctions.shortenFloat(100.0 * audienceResult.PotentialMaxAudienceQuote.Average, 2) + "%)" )
		Else
			Return Self.Usefont.GetWidth( GetLocale("MAX_AUDIENCE_RATING") + ": 100 (100%)")
		EndIf
	End Method


	'override default to add "ALT-Key"-Switcher
	Method Update:Int(deltaTime:Float=1.0)
		If KeyManager.isDown(KEY_LALT) Or KeyManager.isDown(KEY_RALT)
			If Not showDetails Then Self.dirtyImage = True
			showDetails = True
		Else
			If showDetails Then Self.dirtyImage = True
			showDetails = False
		EndIf

		Super.Update(deltaTime)
	End Method


	Method GetContentHeight:Int()
		If showDetails Then Return 3*lineHeight + 9*lineIconHeight
		'default
		Return 4*lineHeight
	End Method


	'override default
	Method DrawContent:Int(x:Int, y:Int, w:Int, h:Int)
		'give text padding
		x :+ 5
		y :+ 7
		w :- 2*5
		h :- 2*7

		If Not Self.audienceResult
			Usefont.draw("Audience data missing", x, y)
			Return False
		EndIf


		Local lineY:Int = y
		Local lineX:Int = x
		Local lineText:String = ""
		Local lineIconHeight:Int = Max(lineHeight, Assets.getSprite("gfx_targetGroup1").area.GetH())
		Local lineIconX:Int = lineX + Assets.getSprite("gfx_targetGroup1").area.GetW() + 2
		Local lineIconWidth:Int = w - Assets.getSprite("gfx_targetGroup1").area.GetW()
		Local lineIconDY:Int = Ceil(0.5 * (lineIconHeight - lineHeight))*2

		'draw overview text
		lineText = GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + TFunctions.shortenFloat(100.0 * audienceResult.PotentialMaxAudienceQuote.Average, 2) + "%)"
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ 2 * Self.Usefont.GetHeight(lineText)

		If Not showDetails
			Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_SHOW_DETAILS") , lineX, lineY, TColor.CreateGrey(150))
		Else
			'add lines so we can have an easier "for loop"
			Local lines:String[9]
			Local percents:String[9]
			lines[0]	= getLocale("AD_GENRE_1") + ": " + TFunctions.convertValue(audienceResult.Audience.Children, 0)
			percents[0]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Children * 100,2)
			lines[1]	= getLocale("AD_GENRE_2") + ": " + TFunctions.convertValue(audienceResult.Audience.Teenagers, 0)
			percents[1]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Teenagers * 100,2)
			lines[2]	= getLocale("AD_GENRE_3") + ": " + TFunctions.convertValue(audienceResult.Audience.HouseWifes, 0)
			percents[2]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.HouseWifes * 100,2)
			lines[3]	= getLocale("AD_GENRE_4") + ": " + TFunctions.convertValue(audienceResult.Audience.Employees, 0)
			percents[3]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Employees * 100,2)
			lines[4]	= getLocale("AD_GENRE_5") + ": " + TFunctions.convertValue(audienceResult.Audience.Unemployed, 0)
			percents[4]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Unemployed * 100,2)
			lines[5]	= getLocale("AD_GENRE_6") + ": " + TFunctions.convertValue(audienceResult.Audience.Manager, 0)
			percents[5]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Manager * 100,2)
			lines[6]	= getLocale("AD_GENRE_7") + ": " + TFunctions.convertValue(audienceResult.Audience.Pensioners, 0)
			percents[6]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Pensioners * 100,2)
			lines[7]	= getLocale("AD_GENRE_8") + ": " + TFunctions.convertValue(audienceResult.Audience.Women, 0)
			percents[7]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Women * 100,2)
			lines[8]	= getLocale("AD_GENRE_9") + ": " + TFunctions.convertValue(audienceResult.Audience.Men, 0)
			percents[8]	= TFunctions.shortenFloat(audienceResult.AudienceQuote.Men * 100,2)

			Local colorLight:TColor = TColor.CreateGrey(240)
			Local colorDark:TColor = TColor.CreateGrey(230)
			Local colorTextLight:TColor = colorLight.copy().AdjustFactor(-110)
			Local colorTextDark:TColor = colorDark.copy().AdjustFactor(-140)

			For Local i:Int = 1 To lines.length
				'shade the rows
				If i Mod 2 = 0 Then colorLight.SetRGB() Else colorDark.SetRGB()
				DrawRect(lineX, lineY, w, lineIconHeight)
				'draw icon
				SetColor 255,255,255
				Assets.getSprite("gfx_targetGroup"+i).draw(lineX, lineY)
				'draw text
				If i Mod 2 = 0
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineIconDY,  w, lineHeight, Null, ColorTextLight)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineIconDY, lineIconWidth - 5, lineIconHeight, TPoint.Create(ALIGN_RIGHT), ColorTextLight)
				Else
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineIconDY,  w, lineHeight, Null, ColorTextDark)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineIconDY, lineIconWidth - 5, lineIconHeight, TPoint.Create(ALIGN_RIGHT), ColorTextDark)
				EndIf
				lineY :+ lineIconHeight
			Next
		EndIf
	End Method
End Type



'Interface, border, TV-antenna, audience-picture and number, watch...
'updates tv-images shown and so on
Type TInterface
	Field gfx_bottomRTT:TImage
	Field CurrentProgramme:TGW_Sprite
	Field CurrentAudience:TImage
	Field CurrentProgrammeText:String
	Field CurrentProgrammeToolTip:TTooltip
	Field CurrentAudienceToolTip:TTooltipAudience
	Field MoneyToolTip:TTooltip
	Field BettyToolTip:TTooltip
	Field CurrentTimeToolTip:TTooltip
	Field noiseSprite:TGW_Sprite
	Field noiseAlpha:Float	= 0.95
	Field noiseDisplace:Trectangle = TRectangle.Create(0,0,0,0)
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field BottomImgDirty:Byte = 1
	Global InterfaceList:TList


	'creates and returns an interface
	Function Create:TInterface()
		Local Interface:TInterface = New TInterface
		Interface.CurrentProgramme			= Assets.getSprite("gfx_interface_tv_programme_none")
		Interface.CurrentProgrammeToolTip	= TTooltip.Create("", "", 40, 395)
		'Interface.CurrentAudienceToolTip	= TTooltip.Create("", "", 355, 415)
		Interface.CurrentAudienceToolTip	= TTooltipAudience.Create("", "", 500, 415)
		Interface.CurrentTimeToolTip		= TTooltip.Create("", "", 355, 495)
		Interface.MoneyToolTip				= TTooltip.Create("", "", 355, 365)
		Interface.BettyToolTip				= TTooltip.Create("", "", 355, 465)
		Interface.noiseSprite				= Assets.getSprite("gfx_interface_tv_noise")
		'set space "left" when subtracting the genre image
		'so we know how many pixels we can move that image to simulate animation
		Interface.noiseDisplace.Dimension.SetX(Max(0, Interface.noiseSprite.area.GetW() - Interface.CurrentProgramme.area.GetW()))
		Interface.noiseDisplace.Dimension.SetY(Max(0, Interface.noiseSprite.area.GetH() - Interface.CurrentProgramme.area.GetH()))
		If Not InterfaceList Then InterfaceList = CreateList()
		InterfaceList.AddLast(Interface)
		SortList InterfaceList
		Return Interface
	End Function


	Method Update(deltaTime:Float=1.0)
		If ShowChannel <> 0
			If Game.getMinute() >= 55
				Local advertisement:TBroadcastMaterial = Game.Players[ShowChannel].ProgrammePlan.GetAdvertisement()
				Interface.CurrentProgramme = Assets.getSprite("gfx_interface_TVprogram_ads")
			    If advertisement
					'real ad
					If TAdvertisement(advertisement)
						CurrentProgrammeToolTip.TitleBGtype = 1
						CurrentProgrammeText 				= getLocale("ADVERTISMENT")+": "+advertisement.GetTitle()
					Else
						CurrentProgrammeToolTip.TitleBGtype = 1
						CurrentProgrammeText 				= getLocale("TRAILER")+": "+advertisement.GetTitle()
					EndIf
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText				= getLocale("BROADCASTING_OUTAGE")
				EndIf
			Else
				Local obj:TBroadcastMaterial = Game.Players[ShowChannel].ProgrammePlan.GetProgramme()
				Interface.CurrentProgramme = Assets.getSprite("gfx_interface_tv_programme_none")
				If obj
					Interface.CurrentProgramme = Assets.getSprite("gfx_interface_tv_programme_none")
					CurrentProgrammeToolTip.TitleBGtype	= 0
					'real programme
					If TProgramme(obj)
						Local programme:TProgramme = TProgramme(obj)
						Interface.CurrentProgramme = Assets.getSprite("gfx_interface_TVprogram_" + programme.data.GetGenre(), "gfx_interface_tv_programme_none")
						If programme.isSeries()
							CurrentProgrammeText = programme.licence.parentLicence.GetTitle() + " ("+ (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + " (" + getLocale("BLOCK") + " " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						Else
							CurrentProgrammeText = programme.GetTitle() + " (" + getLocale("BLOCK") + " " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						EndIf
					ElseIf TAdvertisement(obj)
						CurrentProgrammeText = GetLocale("INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
					ElseIf TNews(obj)
						CurrentProgrammeText = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
					EndIf
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
				EndIf
			EndIf
			If Game.getMinute() <= 5
				Interface.CurrentProgramme = Assets.getSprite("gfx_interface_TVprogram_news")
				CurrentProgrammeToolTip.TitleBGtype	= 3
				CurrentProgrammeText				= getLocale("NEWS")
			EndIf
		Else
			CurrentProgrammeToolTip.TitleBGtype		= 3
			CurrentProgrammeText 					= getLocale("TV_OFF")
		EndIf 'showchannel <>0

		If CurrentProgrammeToolTip.enabled Then CurrentProgrammeToolTip.Update(deltaTime)
		If CurrentAudienceToolTip.enabled Then CurrentAudienceToolTip.Update(deltaTime)
		If CurrentTimeToolTip.enabled Then CurrentTimeToolTip.Update(deltaTime)
		If BettyToolTip.enabled Then BettyToolTip.Update(deltaTime)
		If MoneyToolTip.enabled Then MoneyToolTip.Update(deltaTime)

		'channel selection (tvscreen on interface)
		If MOUSEMANAGER.IsHit(1)
			For Local i:Int = 0 To 4
				If TFunctions.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
					ShowChannel = i
					BottomImgDirty = True
				EndIf
			Next
		EndIf

		'noise on interface-tvscreen
		ChangeNoiseTimer :+ deltaTime
		If ChangeNoiseTimer >= 0.20
			noiseDisplace.position.SetXY(Rand(0, noiseDisplace.dimension.GetX()),Rand(0, noiseDisplace.dimension.GetY()))
			ChangeNoiseTimer = 0.0
			NoiseAlpha = 0.45 - (Rand(0,20)*0.01)
		EndIf

		If TFunctions.MouseIn(20,385,280,200)
			CurrentProgrammeToolTip.title 		= CurrentProgrammeText
			If ShowChannel <> 0
				CurrentProgrammeToolTip.content	= GetLocale("AUDIENCE_RATING")+": "+Game.Players[ShowChannel].getFormattedAudience()+ " (MA: "+TFunctions.shortenFloat(Game.Players[ShowChannel].GetAudiencePercentage()*100,2)+"%)"

				'show additional information if channel is player's channel
				If ShowChannel = Game.playerID
					If Game.getMinute() >= 5 And Game.getMinute() < 55
						Local obj:TBroadcastMaterial = Game.Players[ShowChannel].ProgrammePlan.GetAdvertisement()
						If TAdvertisement(obj)
							CurrentProgrammeToolTip.content :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+":~n" + obj.GetTitle()+" (Mindestz.: " + TFunctions.convertValue(TAdvertisement(obj).contract.getMinAudience())+")"
						ElseIf TProgramme(obj)
							CurrentProgrammeToolTip.content :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+":~nTrailer: " + obj.GetTitle()
						Else
							CurrentProgrammeToolTip.content :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+": nicht gesetzt!"
						EndIf
					ElseIf Game.getMinute()>=55 Or Game.getMinute()<5
						Local obj:TBroadcastMaterial = Game.Players[ShowChannel].ProgrammePlan.GetProgramme()
						If TProgramme(obj)
							CurrentProgrammeToolTip.content :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+":~n"
							If TProgramme(obj) And TProgramme(obj).isSeries()
								CurrentProgrammeTooltip.content :+ TProgramme(obj).licence.parentLicence.data.GetTitle() + ": " + obj.GetTitle() + " (" + getLocale("BLOCK") + " " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							Else
								CurrentProgrammeToolTip.content :+ obj.GetTitle() + " (" + getLocale("BLOCK")+" " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							EndIf
						ElseIf TAdvertisement(obj)
							CurrentProgrammeToolTip.content :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+":~nDauerwerbesendung: " + obj.GetTitle() + " (" + getLocale("BLOCK")+" " + Game.Players[ShowChannel].ProgrammePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						Else
							CurrentProgrammeToolTip.content :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+": nicht gesetzt!"
						EndIf
					EndIf
				EndIf

			Else
				CurrentProgrammeToolTip.content = getLocale("TV_TURN_IT_ON")
			EndIf
			CurrentProgrammeToolTip.enabled 	= 1
			CurrentProgrammeToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = True
	    EndIf
		If TFunctions.MouseIn(355,468,130,30)
			'Print "DebugInfo: " + TAudienceResult.Curr().ToString()
			Local player:TPlayer = Game.Players[Game.playerID]
			Local audienceResult:TAudienceResult = player.audience

			CurrentAudienceToolTip.title 	= GetLocale("AUDIENCE_RATING")+": "+player.getFormattedAudience()+ " (MA: "+TFunctions.shortenFloat(player.GetAudiencePercentage() * 100,2)+"%)"
			CurrentAudienceToolTip.SetAudienceResult(audienceResult)
			CurrentAudienceToolTip.enabled 	= 1
			CurrentAudienceToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = True
		EndIf
		If TFunctions.MouseIn(355,533,130,45)
			CurrentTimeToolTip.title 	= getLocale("GAME_TIME")+": "
			CurrentTimeToolTip.content 	= Game.getFormattedTime()+" "+getLocale("DAY")+" "+Game.getDayOfYear()+"/"+Game.daysPerYear+" "+Game.getYear()
			CurrentTimeToolTip.enabled 	= 1
			CurrentTimeToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = True
		EndIf
		If TFunctions.MouseIn(355,415,130,30)
			MoneyToolTip.title 		= getLocale("MONEY")
			MoneyTooltip.content	= "|b|"+getLocale("MONEY")+":|/b| "+Game.GetPlayer().GetMoney() + getLocale("CURRENCY")
			Moneytooltip.content	:+ "~n"
			Moneytooltip.content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=200,100,100|"+ Game.GetPlayer().GetCredit() + getLocale("CURRENCY")+"|/color|"
			MoneyToolTip.enabled 	= 1
			MoneyToolTip.Hover()
			'force redraw
			MoneyToolTip.dirtyImage = True
		EndIf
		If TFunctions.MouseIn(355,510,130,15)
			BettyToolTip.title	 	= getLocale("BETTY_FEELINGS")
			BettyToolTip.content 	= "0 %"
			BettyToolTip.enabled 	= 1
			BettyToolTip.Hover()
			'force redraw
			BettyToolTip.dirtyImage = True
		EndIf
	End Method


	'draws the interface
	Method Draw(tweenValue:Float=1.0)
		SetBlend ALPHABLEND
		Assets.getSprite("gfx_interface_top").Draw(0,0)
		Assets.getSprite("gfx_interface_leftright").DrawClipped(TPoint.Create(0, 20), TRectangle.Create(0, 0, 27, 363))
		SetBlend SOLIDBLEND
		Assets.getSprite("gfx_interface_leftright").DrawClipped(TPoint.Create(780, 20), TRectangle.Create(27, 0, 20, 363))

		If BottomImgDirty
			Local NoDX9moveY:Int = 383

			SetBlend MASKBLEND
			'draw bottom, aligned "bottom"
			Assets.getSprite("gfx_interface_bottom").Draw(0,App.settings.getHeight(),0, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM))

			If ShowChannel <> 0 Then Assets.getSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)



		    'channel choosen and something aired?
			If ShowChannel <> 0 And Game.Players[ShowChannel].audience
				'If CurrentProgram = Null Then Print "ERROR: CurrentProgram is missing"
				If CurrentProgramme Then CurrentProgramme.Draw(45, 400)

				Local audiencerate:Float = Game.Players[ShowChannel].audience.AudienceQuote.Average

				Local girl_on:Int 			= 0
				Local grandpa_on:Int		= 0
				Local teen_on:Int 			= 0
				If audiencerate > 0.4 And (Game.getHour() < 21 And Game.getHour() > 6) Then girl_on = True
				If audiencerate > 0.1 Then grandpa_on = True
		  		If audiencerate > 0.3 And (Game.getHour() < 2 Or Game.getHour() > 11) Then teen_on = True
				If teen_on And grandpa_on
					Assets.getSprite("gfx_interface_audience_teen").Draw(570, 419 - 383 + NoDX9moveY)    'teen
					Assets.getSprite("gfx_interface_audience_grandpa").Draw(650, 419 - 383 + NoDX9moveY)      'teen
				ElseIf grandpa_on And girl_on And Not teen_on
					Assets.getSprite("gfx_interface_audience_girl").Draw(570, 419 - 383 + NoDX9moveY)      'teen
					Assets.getSprite("gfx_interface_audience_grandpa").Draw(650, 419 - 383 + NoDX9moveY)       'teen
				Else
					If teen_on Then Assets.getSprite("gfx_interface_audience_teen").Draw(670, 419 - 383 + NoDX9moveY)
					If girl_on Then Assets.getSprite("gfx_interface_audience_girl").Draw(550, 419 - 383 + NoDX9moveY)
					If grandpa_on Then Assets.getSprite("gfx_interface_audience_grandpa").Draw(610, 419 - 383 + NoDX9moveY)
					If Not grandpa_on And Not girl_on And Not teen_on
						SetColor 50, 50, 50
						SetBlend MASKBLEND
						Assets.getSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)
						SetColor 255, 255, 255
		    	    EndIf
				EndIf
			EndIf 'showchannel <>0
			SetBlend ALPHABLEND

			Assets.getSprite("gfx_interface_antenna").Draw(111,329)

			'draw noise of tv device
			If ShowChannel <> 0
				SetAlpha NoiseAlpha
				If noiseSprite Then noiseSprite.DrawClipped(TPoint.Create(45, 400), TRectangle.Create(noiseDisplace.GetX(),noiseDisplace.GetY(), 220,170) )
				SetAlpha 1.0
			EndIf
			'draw overlay to hide corners of non-round images
			Assets.getSprite("gfx_interface_tv_overlay").Draw(45,400)

		    For Local i:Int = 0 To 4
				If i = ShowChannel
					Assets.getSprite("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 171 + NoDX9moveY)
				Else
					Assets.getSprite("gfx_interface_channelbuttons_off_"+i).Draw(75 + i * 33, 171 + NoDX9moveY)
				EndIf
		    Next

			'draw the small electronic parts - "the inner tv"
	  		SetBlend MASKBLEND
	     	Assets.getSprite("gfx_interface_audience_overlay").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
			Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.GetPlayer().getMoneyFormatted() + "  ", 377, 427 - 383 + NoDX9moveY, 103, 25, TPoint.Create(ALIGN_RIGHT), TColor.Create(200,230,200), 2)
			Assets.GetFont("Default", 13, BOLDFONT).drawBlock(Game.GetPlayer().getFormattedAudience() + "  ", 377, 469 - 383 + NoDX9moveY, 103, 25, TPoint.Create(ALIGN_RIGHT), TColor.Create(200,200,230), 2)
		 	Assets.GetFont("Default", 11, BOLDFONT).drawBlock((Game.daysPlayed+1) + ". Tag", 366, 555 - 383 + NoDX9moveY, 120, 25, TPoint.Create(ALIGN_CENTER), TColor.Create(180,180,180), 2)
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND


		SetAlpha 0.25
		Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.getFormattedTime() + " Uhr", 366, 542, 120, 25, TPoint.Create(ALIGN_CENTER), TColor.Create(180,180,180))
		SetAlpha 0.9
		Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.getFormattedTime()+ " Uhr", 365,541,120,25, TPoint.Create(ALIGN_CENTER), TColor.Create(40,40,40))
		SetAlpha 1.0
   		CurrentProgrammeToolTip.Draw()
	    CurrentAudienceToolTip.Draw()
   		CurrentTimeToolTip.Draw()
	    BettyToolTip.Draw()
   		MoneyToolTip.Draw()
	    GUIManager.Draw("InGame")

		TError.DrawErrors()
	End Method
End Type

