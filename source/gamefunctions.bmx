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



Function Font_AddGradient:TBitmapFontChar(font:TBitmapFont, charKey:String, char:TBitmapFontChar, config:TData=Null)
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


Function Font_AddShadow:TBitmapFontChar(font:TBitmapFont, charKey:String, char:TBitmapFontChar, config:TData=Null)
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


	Method Create:TGUIChat(pos:TPoint, dimension:TPoint, limitState:String = "")
		'use "create" instead of "createBase" so the caption gets
		'positioned similar
		Super.Create(pos, dimension, limitState)

		guiPanel = AddContentBox(0,0,GetContentScreenWidth()-10,-1)

		guiList = New TGUIListBase.Create(new TPoint.Init(10,10), new TPoint.Init(GetContentScreenWidth(),GetContentScreenHeight()), limitState)
		guiList.setOption(GUI_OBJECT_ACCEPTS_DROP, False)
		guiList.autoSortItems = False
		guiList.SetAcceptDrop("")
		guiList.setParent(Self)
		guiList.autoScroll = True
		guiList.SetBackground(Null)


		guiInput = New TGUIInput.Create(new TPoint.Init(0, dimension.y),new TPoint.Init(dimension.x,-1), "", 32, limitState)
		guiInput.setParent(Self)

		'we manage the panel
		AddChild(guiPanel)

		'resize base and move child elements
		resize(dimension.GetX(), dimension.GetY())

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
		EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", new TData.AddNumber("senderID", GetPlayerCollection().playerID).AddNumber("channels", sendToChannels).AddString("text",guiInput.value) , guiChat ) )

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

		local sendingPlayer:TPlayer = GetPlayerCollection().Get(senderID)

		If sendingPlayer
			senderName	= sendingPlayer.Name
			senderColor	= sendingPlayer.color
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
		GetPadding().setTLBR(top,Left,bottom,Right)
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
		If guiList._mouseOverArea
			For Local entry:TGuiObject = EachIn guiList.entries
				entry.show()
			Next
		EndIf
	End Method
End Type


Type TGUIGameWindow Extends TGUIWindowBase
	Field contentBoxes:TGUIBackgroundBox[]

	Global childSpriteBaseName:string = "gfx_gui_panel.content"


	Method Create:TGUIGameWindow(pos:TPoint, dimension:TPoint, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		GetPadding().SetTop(35)

		SetCaptionArea(new TRectangle.Init(20, 10, GetContentScreenWidth() - 2*20, 25))
		guiCaptionTextBox.SetValueAlignment("LEFT", "TOP")

		Return Self
	End Method


	'special handling for child elements of kind GuiGameBackgroundBox
	Method AddContentBox:TGUIBackgroundBox(displaceX:Int=0, displaceY:Int=0, w:Int=-1, h:Int=-1)
		If w < 0 Then w = GetContentScreenWidth()
		If h < 0 Then h = GetContentScreenHeight()

		'if no background was set yet - do it now
		if not guiBackground then SetBackground( new TGUIBackgroundBox.Create(null, null) )

		'replace single-content-window-sprite (aka: remove "drawn on"-contentimage)
		guiBackground.spriteBaseName = "gfx_gui_panel"

		Local maxOtherBoxesY:Int = 0
		local panelGap:int = GUIManager.config.GetInt("panelGap", 10)
		If children
			For Local box:TGUIBackgroundBox = EachIn contentBoxes
				maxOtherBoxesY = Max(maxOtherBoxesY, box.rect.GetY() + box.rect.GetH())
				'after each box we want a gap
				maxOtherBoxesY :+ panelGap
			Next
		EndIf
		Local box:TGUIBackgroundBox = New TGUIBackgroundBox.Create(new TPoint.Init(displaceX, maxOtherBoxesY + displaceY), new TPoint.Init(w, h), "")

		box.spriteBaseName = childSpriteBaseName
		box.spriteAlpha = 1.0
		box.SetPadding(panelGap, panelGap, panelGap, panelGap)

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
		If guiCaptionTextBox Then guiCaptionTextBox.SetFont(.headerFont)

		Super.Update()
	End Method
End Type




Type TGUIGameModalWindow Extends TGUIModalWindow
	Method Create:TGUIGameModalWindow(pos:TPoint, dimension:TPoint, limitState:String = "")
		_defaultValueColor = TColor.clBlack.copy()
		defaultCaptionColor = TColor.clWhite.copy()

		Super.Create(pos, dimension, limitState)

		SetCaptionArea(new TRectangle.Init(-1,10,-1,25))
		guiCaptionTextBox.SetValueAlignment("CENTER", "TOP")


		Return Self
	End Method

	Method SetCaption:Int(caption:String="")
		Super.SetCaption(caption)
		If guiCaptionTextBox Then guiCaptionTextBox.SetFont(.headerFont)
	End Method
End Type




Type TGUIChatEntry Extends TGUIListItem
	Field paddingBottom:Int	= 5


	Method CreateSimple:TGUIChatEntry(text:String, textColor:TColor, senderName:String, senderColor:TColor, lifetime:Int=Null)
		Create(null,null, text)
		SetLifetime(lifeTime)
		SetShowtime(lifeTime)
		SetSender(senderName, senderColor)
		SetValue(text)
		SetValueColor(textColor)

		Return Self
	End Method


    Method Create:TGUIChatEntry(pos:TPoint=null, dimension:TPoint=null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		Resize(GetDimension().GetX(), GetDimension().GetY())
		SetValue(value)
		SetLifetime( 1000 )
		SetShowtime( 1000 )

		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TPoint()
		Local move:TPoint = new TPoint.Init(0,0)
		If Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = GetBitmapFontManager().baseFontBold.drawStyled(Data.getString("senderName")+":", Self.getScreenX(), Self.getScreenY(), senderColor, 2, 0)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		EndIf
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetParent("tguiscrollablepanel"))
		Local maxWidth:Int
		if parentPanel
			maxWidth = parentPanel.GetContentScreenWidth() - rect.getX()
		else
			maxWidth = GetParent().GetContentScreenWidth() - rect.getX()
		endif
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TPoint = GetBitmapFontManager().baseFont.drawBlock(GetValue(), getScreenX()+move.x, getScreenY()+move.y, maxWidth-move.X, maxHeight, Null, Null, 2, 0)

		'add padding
		dimension.moveXY(0, paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If rect.getW() <> dimension.getX() Or rect.getH() <> dimension.getY()
			'resize item
			Resize(dimension.getX(), dimension.getY())
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

		Local move:TPoint = new TPoint.Init(0,0)
		If Self.Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Self.Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = GetBitmapFontManager().baseFontBold.drawStyled(Self.Data.getString("senderName", "")+":", Self.getScreenX(), Self.getScreenY(), senderColor, 2, 1)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		EndIf
		GetBitmapFontManager().baseFont.drawBlock(GetValue(), getScreenX()+move.x, getScreenY()+move.y, maxWidth-move.X, maxHeight, Null, valueColor, 2, 1, 0.5)

		SetAlpha 1.0

		Self.getParent("tguilistbase").ResetViewPort()
	End Method
End Type




'create a custom type so we can check for doublettes on add
Type TGUIGameList Extends TGUISelectList


    Method Create:TGUIGameList(pos:TPoint=null, dimension:TPoint=null, limitState:String = "")
		Super.Create(pos, dimension, limitState)

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
			If TGUIGameEntry(item) And TGUIGameEntry(item).GetValue() = olditem.GetValue()
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
		Self.Create(null, null, _hostIP+":"+_hostPort)

		Self.data.AddString("hostIP", _hostIP)
		Self.data.AddNumber("hostPort", _hostPort)
		Self.data.AddString("hostName", _hostName)
		Self.data.AddString("gameTitle", gametitle)
		Self.data.AddNumber("slotsUsed", slotsUsed)
		Self.data.AddNumber("slotsMax", slotsMax)

		Return Self
	End Method


    Method Create:TGUIGameEntry(pos:TPoint=null, dimension:TPoint=null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetLifetime(30000) '30 seconds
		SetValue(":D")
		SetValueColor(TColor.Create(0,0,0))

		Resize( dimension.x, dimension.y )

		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TPoint()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = parentPanel.getContentScreenWidth()-Self.rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local text:String = Self.Data.getString("gameTitle","#unknowngametitle#")+" by "+ Self.Data.getString("hostName","#unknownhostname#") + " ("+Self.Data.getInt("slotsUsed",1)+"/"+Self.Data.getInt("slotsMax",4)
		Local dimension:TPoint = GetBitmapFontManager().baseFont.drawBlock(text, getScreenX(), getScreenY(), maxWidth, maxHeight, Null, Null, 2, 0)

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
		Local move:TPoint = new TPoint.Init(0, Self.paddingTop)
		Local text:String = ""
		Local textColor:TColor = Null
		Local textDim:TPoint = Null
		'line: title by hostname (slotsused/slotsmax)

		text 		= Self.Data.getString("gameTitle","#unknowngametitle#")
		textColor	= TColor(Self.Data.get("gameTitleColor", TColor.Create(150,80,50)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor, 2, 1,0.5)
		move.moveXY(textDim.x,1)

		text 		= " by "+Self.Data.getString("hostName","#unknownhostname#")
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(50,50,150)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.moveXY(textDim.x,0)

		text 		= " ("+Self.Data.getInt("slotsUsed",1)+"/"++Self.Data.getInt("slotsMax",4)+")"
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(0,0,0)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.moveXY(textDim.x,0)

		SetAlpha 1.0

		'self.getParent("topitem").ResetViewPort()
	End Method
End Type




Type THotspot extends TStaticEntity
	Field area:TRectangle = new TRectangle.Init(0,0,0,0)
	Field name:String = ""
	Field tooltip:TTooltip = Null
	Field tooltipText:String = ""
	Field tooltipDescription:String	= ""
	Field hovered:Int = False
	Global list:TList = CreateList()


	Method Create:THotSpot(name:String, x:Int,y:Int,w:Int,h:Int)
		area = new TRectangle.Init(x,y,w,h)
		Self.name = name

		GenerateID()

		list.AddLast(self)
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
			tooltip.Update()
			'delete old tooltips
			If tooltip.lifetime < 0 Then tooltip = Null
		EndIf
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		If tooltip Then tooltip.Render()
	End Method
End Type





'tooltips containing headline and text, updated and drawn by Tinterface
Type TTooltip Extends TEntity
	Field lifetime:Float		= 0.1		'how long this tooltip is existing
	Field fadeValue:Float		= 1.0		'current fading value (0-1.0)
	Field _startLifetime:Float	= 1.0		'initial lifetime value
	Field _startFadingTime:Float= 0.20		'at which lifetime fading starts
	Field title:String
	Field content:String
	Field minContentWidth:int	= 120
	'left (2) and right (4) is for all elements
	'top (1) and bottom (3) padding for content
	Field padding:TRectangle	= new TRectangle.Init(3,5,4,7)
	Field image:TImage			= Null
	Field dirtyImage:Int		= 1
	Field tooltipImage:Int		=-1
	Field titleBGtype:Int		= 0
	Field enabled:Int			= 0

	Global tooltipHeader:TSprite
	Global tooltipIcons:TSprite
	Global list:TList 			= CreateList()

	Global useFontBold:TBitmapFont
	Global useFont:TBitmapFont
	Global imgCacheEnabled:Int	= True


	Function Create:TTooltip(title:String = "", content:String = "unknown", x:Int = 0, y:Int = 0, w:Int = -1, h:Int = -1, lifetime:Int = 300)
		Local obj:TTooltip = New TTooltip
		obj.Initialize(title, content, x, y, w, h, lifetime)

		list.addLast(obj)
		Return obj
	End Function


	Method Initialize:Int(title:String="", content:String="unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=50)
		Self.title				= title
		Self.content			= content
		Self.area				= new TRectangle.Init(x, y, w, h)
		Self.tooltipimage		= -1
		Self.lifetime			= lifetime
		Self._startLifetime		= Float(lifetime) / 1000.0 	'in seconds
		Self._startFadingTime	= Min(_startLifetime/2.0, 0.1)
		Self.Hover()
	End Method


	'sort tooltips according lifetime (dying ones behind)
	Method Compare:Int(other:Object)
		Local otherTip:TTooltip = TTooltip(other)
		'no weighting
		If Not otherTip then Return 0
		If otherTip = Self then Return 0
		If otherTip.GetLifePercentage() = GetLifePercentage() Then Return 0
		'below me
		If otherTip.GetLifePercentage() < GetLifePercentage() Then Return 1
		'on top of me
		Return -1
	End Method


	'returns (in percents) how many lifetime is left
	Method GetLifePercentage:float()
		return Min(1.0, Max(0.0, lifetime / _startLifetime))
	End Method


	'reset lifetime
	Method Hover()
		lifeTime 	= _startLifetime
		fadeValue	= 1.0
	End Method


	Method Update:Int()
		lifeTime :- GetDeltaTimer().GetDelta()

		'start fading if lifetime is running out (lower than fade time)
		If lifetime <= _startFadingTime
			fadeValue :- GetDeltaTimer().GetDelta()
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
			local paddingLeftRight:int = 6
			'width from title + content + spacing
			result = UseFontBold.getWidth(title)
			'add icon to width
			If tooltipimage >=0 Then result:+ ToolTipIcons.framew + 2
			'compare with content text width
			result = Max(GetContentWidth(), result)
			'add padding
			result:+ padding.GetLeft() + padding.GetRight()

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
			result:+ getContentHeight(GetWidth())
			Return result
		EndIf
	End Method


	Method getTitleHeight:Int()
		Local result:Int = TooltipHeader.area.GetH()
		'add icon to height of caption
		'If tooltipimage >= 0 Then result :+ 2
		Return result
	End Method


	Method SetTitle:Int(value:String)
		if title = value then return FALSE

		title = value
		'force redraw/cache reset
		dirtyImage = True
	End Method


	Method SetContent:Int(value:String)
		if content = value then return FALSE

		content = value
		'force redraw/cache reset
		dirtyImage = True
	End Method


	Method getContentWidth:Int()
		'only add a line if there is text
		if content <> "" then return minContentWidth
		return 0

		'If Len(content)>1 Then Return UseFont.getWidth(content)
		'Return 0
	End Method


	Method GetContentInnerWidth:Int()
		return getContentWidth() - padding.GetLeft() - padding.GetRight()
	End Method


	Method GetContentHeight:Int(width:int)
		local result:int = 0
		local maxTextWidth:int = width - padding.GetLeft() - padding.GetRight()

		'only add a line if there is text
		If content <> ""
			result :+ UseFont.getBlockHeight(content, maxTextWidth, -1)
			result :+ padding.GetTop() + padding.GetBottom()
		endif
		Return result
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
		useFontBold.drawStyled(title, x + padding.GetLeft() + displaceX, y + (height - useFontBold.getMaxCharHeight())/2 , TColor.Create(50,50,50), 2, 1, 0.1)
'		SetAlpha 1.0
	End Method


	Method DrawContent:Int(x:Int, y:Int, width:Int, height:Int)
		If content = "" then return FALSE
		local maxTextWidth:int = width - padding.GetLeft() - padding.GetRight()
		SetColor 90,90,90
		Usefont.drawBlock(content, x + padding.GetLeft(), y + padding.GetTop(), maxTextWidth, -1)
		SetColor 255, 255, 255
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		If Not enabled Then Return 0

		local col:TColor = TColor.Create().Get()

		If DirtyImage Or Not Image Or Not imgCacheEnabled
			local boxWidth:int = GetWidth()
			Local boxHeight:Int	= GetHeight()
			Local boxInnerWidth:Int	= boxWidth - 2
			Local boxInnerHeight:Int = boxHeight - 2
			Local innerX:int = area.GetX() + 1
			Local innerY:int = area.GetY() + 1
			Local captionHeight:Int = GetTitleHeight()
			DrawShadow(boxWidth, boxHeight)

			SetAlpha col.A * getFadeAmount()
			SetColor 0,0,0
			'border
			DrawRect(area.GetX(), area.GetY(), boxWidth, boxHeight)
			'bright background
			SetColor 255,255,255
			DrawRect(innerX, innerY, boxInnerWidth, boxInnerHeight)

			'draw header including caption and header background
			DrawHeader(innerX, innerY, boxInnerWidth, captionHeight)

			'draw content - do not use contentHeight here..
			'if boxHeight was defined manually we just give it the left space
			'as a caption has to get drawn in all cases...
			DrawContent(innerX, innerY + captionHeight, boxInnerWidth, boxInnerHeight - captionHeight)
rem
			If imgCacheEnabled 'And lifetime = startlifetime
				Image = TImage.Create(boxWidth, boxHeight, 1, 0, 255, 0, 255)
				image.pixmaps[0] = VirtualGrabPixmap(Self.area.GetX(), Self.area.GetY(), boxWidth, boxHeight)
				DirtyImage = False
			EndIf
endrem
		Else 'not dirty
			DrawShadow(ImageWidth(image),ImageHeight(image))
			SetAlpha col.a * getFadeAmount()
			SetColor 255,255,255
			DrawImage(image, area.GetX(), area.GetY())
			SetAlpha 1.0
		EndIf

		col.SetRGBA()
	End Method
End Type







	Function DrawDialog(dialogueType:String="default", x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TSprite = GetSpriteFromRegistry(DialogStart)
		height = Max(95, height ) 'minheight
		If DialogStart = "StartLeftDown" Then dx = x - 48;dy = y + Height/3 + DialogStartMove;width:-48
		If DialogStart = "StartRightDown" Then dx = x + width - 12;dy = y + Height/2 + DialogStartMove;width:-48
		If DialogStart = "StartDownRight" Then dx = x + width/2 + DialogStartMove;dy = y + Height - 12;Height:-53
		If DialogStart = "StartDownLeft" Then dx = x + width/2 + DialogStartMove;dy = y + Height - 12;Height:-53

		GetSpriteFromRegistry("dialogue."+dialogueType).DrawArea(x,y,width,height)

		DialogSprite.Draw(dx, dy)
		If DialogText <> "" Then DialogFont.drawBlock(DialogText, x + 10, y + 10, width - 16, Height - 16, Null, TColor.clBlack)
	End Function

	'draws a rounded rectangle (blue border) with alphashadow
	Function DrawGFXRect(gfx_Rect:TSpritePack, x:Int, y:Int, width:Int, Height:Int, nameBase:String="gfx_gui_rect_")
		gfx_Rect.getSprite(nameBase+"TopLeft").Draw(x, y)
		gfx_Rect.getSprite(nameBase+"TopRight").Draw(x + width, y,-1, new TPoint.Init(ALIGN_RIGHT, ALIGN_TOP))
		gfx_Rect.getSprite(nameBase+"BottomLeft").Draw(x, y + Height, -1, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))
		gfx_Rect.getSprite(nameBase+"BottomRight").Draw(x + width, y + Height, -1, new TPoint.Init(ALIGN_RIGHT, ALIGN_BOTTOM))

		gfx_Rect.getSprite(nameBase+"BorderLeft").TileDraw(x, y + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH(), gfx_Rect.getSprite(nameBase+"BorderLeft").area.GetW(), Height - gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetH() - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH())
		gfx_Rect.getSprite(nameBase+"BorderRight").TileDraw(x + width - gfx_Rect.getSprite(nameBase+"BorderRight").area.GetW(), y + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH(), gfx_Rect.getSprite(nameBase+"BorderRight").area.GetW(), Height - gfx_Rect.getSprite(nameBase+"BottomRight").area.GetH() - gfx_Rect.getSprite(nameBase+"TopRight").area.GetH())
		gfx_Rect.getSprite(nameBase+"BorderTop").TileDraw(x + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW(), y, width - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW() - gfx_Rect.getSprite(nameBase+"TopRight").area.GetW(), gfx_Rect.getSprite(nameBase+"BorderTop").area.GetH())
		gfx_Rect.getSprite(nameBase+"BorderBottom").TileDraw(x + gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetW(), y + Height - gfx_Rect.getSprite(nameBase+"BorderBottom").area.GetH(), width - gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetW() - gfx_Rect.getSprite(nameBase+"BottomRight").area.GetW(), gfx_Rect.getSprite(nameBase+"BorderBottom").area.GetH())
		gfx_Rect.getSprite(nameBase+"Back").TileDraw(x + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW(), y + gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH(), width - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetW() - gfx_Rect.getSprite(nameBase+"TopRight").area.GetW(), Height - gfx_Rect.getSprite(nameBase+"TopLeft").area.GetH() - gfx_Rect.getSprite(nameBase+"BottomLeft").area.GetH())
	End Function





Type TBlockGraphical Extends TBlockMoveable
	Field imageBaseName:String
	Field imageDraggedBaseName:String
	Field image:TSprite
	Field image_dragged:TSprite
    Global AdditionallyDragged:Int	= 0
End Type







'a graphical representation of multiple object ingame
Type TGUIGameListItem Extends TGUIListItem
	Field assetNameDefault:String = "gfx_movie0"
	Field assetNameDragged:String = "gfx_movie0"
	Field asset:TSprite = Null
	Field assetDefault:TSprite = Null
	Field assetDragged:TSprite = Null


    Method Create:TGUIGameListItem(pos:TPoint=null, dimension:TPoint=null, value:String="")
		'creates base, registers click-event,...
		Super.Create(pos, dimension, value)

   		Self.InitAssets()
   		Self.SetAsset()

		Return Self
	End Method


	Method InitAssets(nameDefault:String="", nameDragged:String="")
		If nameDefault = "" Then nameDefault = Self.assetNameDefault
		If nameDragged = "" Then nameDragged = Self.assetNameDragged

		Self.assetNameDefault = nameDefault
		Self.assetNameDragged = nameDragged
		Self.assetDefault = GetSpriteFromRegistry(nameDefault)
		Self.assetDragged = GetSpriteFromRegistry(nameDragged)

		Self.SetAsset(Self.assetDefault)
	End Method


	Method SetAsset(sprite:TSprite=Null)
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
	Field rect:TRectangle			= new TRectangle.Init(0,0,0,0)
	Field dragable:Int				= 1 {saveload = "normalExt"}
	Field dragged:Int				= 0 {saveload = "normalExt"}
	Field OrigPos:TPoint 			= new TPoint.Init(0, 0) {saveload = "normalExtB"}
	Field StartPos:TPoint			= new TPoint.Init(0, 0) {saveload = "normalExt"}
	Field StartPosBackup:TPoint		= new TPoint.Init(0, 0)


	'switches coords and state of blocks
	Method SwitchBlock(otherObj:TBlockMoveable)
		Self.SwitchCoords(otherObj)
		Local old:Int	= Self.dragged
		Self.dragged	= otherObj.dragged
		otherObj.dragged= old
	End Method


	'switches current and startcoords of two blocks
	Method SwitchCoords(otherObj:TBlockMoveable)
		TPoint.SwitchPoints(rect.position, otherObj.rect.position)
		TPoint.SwitchPoints(StartPos, otherObj.StartPos)
		TPoint.SwitchPoints(StartPosBackup, otherObj.StartPosBackup)
	End Method


	'checks if x, y are within startPoint+dimension
	Method containsCoord:Byte(x:Int, y:Int)
		Return THelper.IsIn( x,y, Self.StartPos.getX(), Self.StartPos.getY(), Self.rect.getW(), Self.rect.getH() )
	End Method


	Method SetCoords(x:Int=Null, y:Int=Null, startx:Int=Null, starty:Int=Null)
      If x<>Null 		Then Self.rect.position.SetX(x)
      If y<>Null		Then Self.rect.position.SetY(y)
      If startx<>Null	Then Self.StartPos.setX(startx)
      If starty<>Null	Then Self.StartPos.SetY(starty)
	End Method


	Method SetBasePos(pos:TPoint = Null)
		If pos <> Null
			rect.position.CopyFrom(pos)
			StartPos.CopyFrom(pos)
		EndIf
	End Method


	Method IsAtStartPos:Int()
		Return rect.position.isSame(StartPos, True)
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
	Global sprite:TSprite


	Function Create:TError(title:String, message:String)
		Local obj:TError =  New TError
		obj.title	= title
		obj.message	= message
		obj.id		= LastID
		LastID :+1
		If obj.sprite = Null Then obj.sprite = GetSpriteFromRegistry("gfx_errorbox")
		obj.pos		= new TPoint.Init(400-obj.sprite.area.GetW()/2 +6, 200-obj.sprite.area.GetH()/2 +6)
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
			If THelper.MouseIn(pos.x,pos.y, sprite.area.GetW(), sprite.area.GetH())
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
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.area.GetW() - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.area.GetW()-40, sprite.area.GetH()-60, Null, TColor.Create(50, 50, 50))
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
		If THelper.MouseIn( x, y-2, w, GetBitmapFont("Default", 12).getBlockHeight(Self._text, w, h))
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
			GetBitmapFont("Default", 12, BoldFont).drawBlock(Self._text, x+9, y-1, w-10, h, Null, TColor.Create(0, 0, 0))
		Else
			SetColor 0,0,0
			DrawOval(x, y +3, 6, 6)
			GetBitmapFont("Default", 12).drawBlock(Self._text, x+10, y, w-10, h, Null, TColor.Create(100, 100, 100))
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
		Local ydisplace:Float = GetBitmapFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit
		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(x + 9, y + ydisplace, w - 9, h, clicked)
			If returnValue <> - 1 Then _goTo = returnValue
			ydisplace:+GetBitmapFont("Default", 14).getHeight(answer._text) + 2
		Next
		Return _goTo
	End Method


	Method Draw(x:Float, y:Float, w:Float, h:Float)
		Local ydisplace:Float = GetBitmapFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit

		Local lineHeight:Int = 2 + GetBitmapFont("Default", 14).getHeight("QqT") 'high chars, low chars

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer.Draw(x, y + ydisplace, w, h)
			ydisplace:+ lineHeight
		Next
	End Method
End Type




Type TDialogue
	Field _texts:TList = CreateList() 'of TDialogueTexts
	Field _currentText:Int = 0
	Field _rect:TRectangle = new TRectangle.Init(0,0,0,0)


	Function Create:TDialogue(x:Float, y:Float, w:Float, h:Float)
		Local obj:TDialogue = New TDialogue
		obj._rect.position.SetXY(x,y)
		obj._rect.dimension.SetXY(w,h)
		Return obj
	End Function


	Method AddText(Text:TDialogueTexts)
		Self._texts.AddLast(Text)
	End Method


	Method Update:Int()
		Local clicked:Int = 0
		if MouseManager.isClicked(1)
			clicked = 1
			MouseManager.resetKey(1)
		endif
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
	    DrawDialog("default", _rect.getX(), _rect.getY(), _rect.getW(), _rect.getH(), "StartLeftDown", 0, "", GetBitmapFont("Default", 14))
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
	Field originalPos:TPoint

	Function Create:TTooltipAudience(title:String = "", text:String = "unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Local obj:TTooltipAudience = New TTooltipAudience
		obj.Initialize(title, text, x, y, w, h, lifetime)

		Return obj
	End Function


	'override to add lineheight
	Method Initialize:Int(title:String="", content:String="unknown", x:Int=0, y:Int=0, w:Int=-1, h:Int=-1, lifetime:Int=300)
		Super.Initialize(title, content, x, y, w, h, lifetime)
		Self.lineHeight = Self.useFont.getMaxCharHeight()+1
		'text line with icon
		Self.lineIconHeight = 1 + Max(lineHeight, GetSpriteFromRegistry("gfx_targetGroup1").area.GetH())
	End Method


	Method SetAudienceResult:Int(audienceResult:TAudienceResult)
		if Self.audienceResult = audienceResult then return FALSE

		Self.audienceResult = audienceResult
		self.dirtyImage = TRUE
	End Method


	Method GetContentWidth:Int()
		If audienceResult
			Return Self.useFont.GetWidth( GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + MathHelper.floatToString(100.0 * audienceResult.PotentialMaxAudienceQuote.GetAverage(), 2) + "%)" )
		Else
			Return Self.Usefont.GetWidth( GetLocale("MAX_AUDIENCE_RATING") + ": 100 (100%)")
		EndIf
	End Method


	'override default to add "ALT-Key"-Switcher
	Method Update:Int()
		If KeyManager.isDown(KEY_LALT) Or KeyManager.isDown(KEY_RALT)
			If Not showDetails Then Self.dirtyImage = True
			showDetails = True
			'backup position
			if not originalPos then originalPos = area.position.Copy()
		Else
			If showDetails Then Self.dirtyImage = True
			showDetails = False
			'restore position
			if originalPos
				area.position.CopyFrom(originalPos)
				originalPos = null
			endif
		EndIf

		Super.Update()
	End Method


	Method GetContentHeight:Int(width:int)
		local result:int = 0
		If showDetails
			result:+ 2*lineHeight + 9*lineIconHeight
		else
			result:+ 3*lineHeight
		endif

		result:+ padding.GetTop() + padding.GetBottom()

		return result
	End Method


	'override default
	Method DrawContent:Int(x:Int, y:Int, w:Int, h:Int)
		'give text padding
		x :+ padding.GetLeft()
		y :+ padding.GetTop()
		w :- (padding.GetLeft() + padding.GetRight())
		h :- (padding.GetTop() + padding.GetBottom())

		If Not Self.audienceResult
			Usefont.draw("Audience data missing", x, y)
			Return False
		EndIf


		Local lineY:Int = y
		Local lineX:Int = x
		Local lineText:String = ""
		Local lineIconHeight:Int = 1 + Max(lineHeight, GetSpriteFromRegistry("gfx_targetGroup1").area.GetH())
		Local lineIconX:Int = lineX + GetSpriteFromRegistry("gfx_targetGroup1").area.GetW() + 2
		Local lineIconWidth:Int = w - GetSpriteFromRegistry("gfx_targetGroup1").area.GetW()
		Local lineIconDY:Int = Ceil(0.5 * (lineIconHeight - lineHeight))
		Local lineTextDY:Int = lineIconDY + 2

		'draw overview text
		lineText = GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + MathHelper.floatToString(100.0 * audienceResult.PotentialMaxAudienceQuote.GetAverage(), 2) + "%)"
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ 2 * Self.Usefont.GetHeight(lineText)

		If Not showDetails
			Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_SHOW_DETAILS") , lineX, lineY, TColor.CreateGrey(150))
		Else
			'add lines so we can have an easier "for loop"
			Local lines:String[9]
			Local percents:String[9]
			lines[0]	= getLocale("AD_GENRE_1") + ": " + TFunctions.convertValue(audienceResult.Audience.Children, 0)
			percents[0]	= MathHelper.floatToString(audienceResult.AudienceQuote.Children * 100,2)
			lines[1]	= getLocale("AD_GENRE_2") + ": " + TFunctions.convertValue(audienceResult.Audience.Teenagers, 0)
			percents[1]	= MathHelper.floatToString(audienceResult.AudienceQuote.Teenagers * 100,2)
			lines[2]	= getLocale("AD_GENRE_3") + ": " + TFunctions.convertValue(audienceResult.Audience.HouseWifes, 0)
			percents[2]	= MathHelper.floatToString(audienceResult.AudienceQuote.HouseWifes * 100,2)
			lines[3]	= getLocale("AD_GENRE_4") + ": " + TFunctions.convertValue(audienceResult.Audience.Employees, 0)
			percents[3]	= MathHelper.floatToString(audienceResult.AudienceQuote.Employees * 100,2)
			lines[4]	= getLocale("AD_GENRE_5") + ": " + TFunctions.convertValue(audienceResult.Audience.Unemployed, 0)
			percents[4]	= MathHelper.floatToString(audienceResult.AudienceQuote.Unemployed * 100,2)
			lines[5]	= getLocale("AD_GENRE_6") + ": " + TFunctions.convertValue(audienceResult.Audience.Manager, 0)
			percents[5]	= MathHelper.floatToString(audienceResult.AudienceQuote.Manager * 100,2)
			lines[6]	= getLocale("AD_GENRE_7") + ": " + TFunctions.convertValue(audienceResult.Audience.Pensioners, 0)
			percents[6]	= MathHelper.floatToString(audienceResult.AudienceQuote.Pensioners * 100,2)
			lines[7]	= getLocale("AD_GENRE_8") + ": " + TFunctions.convertValue(audienceResult.Audience.Women, 0)
			percents[7]	= MathHelper.floatToString(audienceResult.AudienceQuote.Women * 100,2)
			lines[8]	= getLocale("AD_GENRE_9") + ": " + TFunctions.convertValue(audienceResult.Audience.Men, 0)
			percents[8]	= MathHelper.floatToString(audienceResult.AudienceQuote.Men * 100,2)

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
				GetSpriteFromRegistry("gfx_targetGroup"+i).draw(lineX, lineY + lineIconDY)
				'draw text
				If i Mod 2 = 0
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineTextDY,  w, lineHeight, Null, ColorTextLight)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineTextDY, lineIconWidth - 5, lineIconHeight, new TPoint.Init(ALIGN_RIGHT), ColorTextLight)
				Else
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineTextDY,  w, lineHeight, Null, ColorTextDark)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineTextDY, lineIconWidth - 5, lineIconHeight, new TPoint.Init(ALIGN_RIGHT), ColorTextDark)
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
	Field CurrentProgramme:TSprite
	Field CurrentAudience:TImage
	Field CurrentProgrammeText:String
	Field CurrentProgrammeToolTip:TTooltip
	Field CurrentAudienceToolTip:TTooltipAudience
	Field MoneyToolTip:TTooltip
	Field BettyToolTip:TTooltip
	Field CurrentTimeToolTip:TTooltip
	Field tooltips:TList = CreateList()
	Field noiseSprite:TSprite
	Field noiseAlpha:Float	= 0.95
	Field noiseDisplace:Trectangle = new TRectangle.Init(0,0,0,0)
	Field ChangeNoiseTimer:Float= 0.0
	Field ShowChannel:Byte 	= 1
	Field BottomImgDirty:Byte = 1
	Global InterfaceList:TList


	'creates and returns an interface
	Function Create:TInterface()
		Local Interface:TInterface = New TInterface
		Interface.CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")

		Interface.CurrentProgrammeToolTip = TTooltip.Create("", "", 40, 395)
		Interface.CurrentProgrammeToolTip.minContentWidth = 220

		Interface.CurrentAudienceToolTip = TTooltipAudience.Create("", "", 490, 440)
		Interface.CurrentAudienceToolTip.minContentWidth = 200

		Interface.CurrentTimeToolTip = TTooltip.Create("", "", 490, 535)
		Interface.MoneyToolTip = TTooltip.Create("", "", 490, 408)
		Interface.BettyToolTip = TTooltip.Create("", "", 490, 485)

		'collect them in one list (to sort them correctly)
		Interface.tooltips.AddLast(Interface.CurrentProgrammeToolTip)
		Interface.tooltips.AddLast(Interface.CurrentAudienceToolTip)
		Interface.tooltips.AddLast(Interface.CurrentTimeToolTip)
		Interface.tooltips.AddLast(Interface.MoneyTooltip)
		Interface.tooltips.AddLast(Interface.BettyToolTip)


		Interface.noiseSprite = GetSpriteFromRegistry("gfx_interface_tv_noise")
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
		local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(ShowChannel)

		if programmePlan	'similar to "ShowChannel<>0"
			If GetGameTime().getMinute() >= 55
				Local advertisement:TBroadcastMaterial = programmePlan.GetAdvertisement()
				Interface.CurrentProgramme = GetSpriteFromRegistry("gfx_interface_TVprogram_ads")
			    If advertisement
					'real ad
					If TAdvertisement(advertisement)
						CurrentProgrammeToolTip.TitleBGtype = 1
						CurrentProgrammeText = getLocale("ADVERTISMENT")+": "+advertisement.GetTitle()
					Else
						CurrentProgrammeToolTip.TitleBGtype = 1
						CurrentProgrammeText = getLocale("TRAILER")+": "+advertisement.GetTitle()
					EndIf
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
				EndIf
			ElseIf GetGameTime().getMinute() < 5
				Interface.CurrentProgramme = GetSpriteFromRegistry("gfx_interface_TVprogram_news")
				CurrentProgrammeToolTip.TitleBGtype	= 3
				CurrentProgrammeText = getLocale("NEWS")
			Else
				Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
				Interface.CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
				If obj
					Interface.CurrentProgramme = GetSpriteFromRegistry("gfx_interface_tv_programme_none")
					CurrentProgrammeToolTip.TitleBGtype	= 0
					'real programme
					If TProgramme(obj)
						Local programme:TProgramme = TProgramme(obj)
						Interface.CurrentProgramme = GetSpriteFromRegistry("gfx_interface_TVprogram_" + programme.data.GetGenre(), "gfx_interface_tv_programme_none")
						If programme.isSeries()
							CurrentProgrammeText = programme.licence.parentLicence.GetTitle() + " ("+ (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()+"): " + programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						Else
							CurrentProgrammeText = programme.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + programme.GetBlocks() + ")"
						EndIf
					ElseIf TAdvertisement(obj)
						CurrentProgrammeText = GetLocale("INFOMERCIAL")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
					ElseIf TNews(obj)
						CurrentProgrammeText = GetLocale("SPECIAL_NEWS_BROADCAST")+": "+obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
					EndIf
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText = getLocale("BROADCASTING_OUTAGE")
				EndIf
			EndIf
		Else
			CurrentProgrammeToolTip.TitleBGtype = 3
			CurrentProgrammeText = getLocale("TV_OFF")
		EndIf 'no programmePlan found -> invalid player / tv off

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Update()
		Next
		tooltips.Sort() 'sort according lifetime

		'channel selection (tvscreen on interface)
		If MOUSEMANAGER.IsHit(1)
			For Local i:Int = 0 To 4
				If THelper.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
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

		If THelper.MouseIn(20,385,280,200)
			CurrentProgrammeToolTip.SetTitle(CurrentProgrammeText)
			local content:String = ""
			If programmePlan
				content	= GetLocale("AUDIENCE_RATING")+": "+programmePlan.getFormattedAudience()+ " (MA: "+MathHelper.floatToString(programmePlan.GetAudiencePercentage()*100,2)+"%)"

				'show additional information if channel is player's channel
				If ShowChannel = GetPlayerCollection().playerID
					If GetGameTime().getMinute() >= 5 And GetGameTime().getMinute() < 55
						Local obj:TBroadcastMaterial = programmePlan.GetAdvertisement()
						If TAdvertisement(obj)
							content :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+":~n" + obj.GetTitle()+" (Mindestz.: " + TFunctions.convertValue(TAdvertisement(obj).contract.getMinAudience())+")"
						ElseIf TProgramme(obj)
							content :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+":~nTrailer: " + obj.GetTitle()
						Else
							content :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+": nicht gesetzt!"
						EndIf
					ElseIf GetGameTime().getMinute()>=55 Or GetGameTime().getMinute()<5
						Local obj:TBroadcastMaterial = programmePlan.GetProgramme()
						If TProgramme(obj)
							content :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+":~n"
							If TProgramme(obj) And TProgramme(obj).isSeries()
								content :+ TProgramme(obj).licence.parentLicence.data.GetTitle() + ": " + obj.GetTitle() + " (" + getLocale("BLOCK") + " " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							Else
								content :+ obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
							EndIf
						ElseIf TAdvertisement(obj)
							content :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+":~nDauerwerbesendung: " + obj.GetTitle() + " (" + getLocale("BLOCK")+" " + programmePlan.GetProgrammeBlock() + "/" + obj.GetBlocks() + ")"
						Else
							content :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+": nicht gesetzt!"
						EndIf
					EndIf
				EndIf
			Else
				content = getLocale("TV_TURN_IT_ON")
			EndIf

			CurrentProgrammeToolTip.SetContent(content)
			CurrentProgrammeToolTip.enabled = 1
			CurrentProgrammeToolTip.Hover()
	    EndIf
		If THelper.MouseIn(355,468,130,30)
			local playerProgrammePlan:TPlayerProgrammePlan = GetPlayerCollection().Get().GetProgrammePlan()
			if playerProgrammePlan
				CurrentAudienceToolTip.SetTitle(GetLocale("AUDIENCE_RATING")+": "+playerProgrammePlan.getFormattedAudience()+ " (MA: "+MathHelper.floatToString(playerProgrammePlan.GetAudiencePercentage() * 100,2)+"%)")
				CurrentAudienceToolTip.SetAudienceResult(GetBroadcastManager().GetAudienceResult(playerProgrammePlan.owner))
				CurrentAudienceToolTip.enabled = 1
				CurrentAudienceToolTip.Hover()
				'force redraw
				CurrentTimeToolTip.dirtyImage = True
			endif
		EndIf
		If THelper.MouseIn(355,533,130,45)
			CurrentTimeToolTip.SetTitle(getLocale("GAME_TIME")+": ")
			CurrentTimeToolTip.SetContent(GetGameTime().getFormattedTime()+" "+getLocale("DAY")+" "+GetGameTime().getDayOfYear()+"/"+GetGameTime().daysPerYear+" "+GetGameTime().getYear())
			CurrentTimeToolTip.enabled = 1
			CurrentTimeToolTip.Hover()
		EndIf
		If THelper.MouseIn(355,415,130,30)
			MoneyToolTip.title = getLocale("MONEY")
			local content:String = ""
			content	= "|b|"+getLocale("MONEY")+":|/b| "+GetPlayerCollection().Get().GetMoney() + getLocale("CURRENCY")
			content	:+ "~n"
			content	:+ "|b|"+getLocale("DEBT")+":|/b| |color=200,100,100|"+ GetPlayerCollection().Get().GetCredit() + getLocale("CURRENCY")+"|/color|"
			MoneyTooltip.SetContent(content)
			MoneyToolTip.enabled 	= 1
			MoneyToolTip.Hover()
		EndIf
		If THelper.MouseIn(355,510,130,15)
			BettyToolTip.SetTitle(getLocale("BETTY_FEELINGS"))
			BettyToolTip.SetContent(getLocale("THERE_IS_NO_LOVE_IN_THE_AIR_YET"))
			BettyToolTip.enabled = 1
			BettyToolTip.Hover()
		EndIf
	End Method


	'returns a string list of abbreviations for the watching family
	Function GetWatchingFamily:string[]()
		'fetch feedback to see which test-family member might watch
		Local feedback:TBroadcastFeedback = GetBroadcastManager().GetCurrentBroadcast().GetFeedback(GetPlayerCollection().playerID)

		local result:String[]

		if (feedback.AudienceInterest.Children > 0)
			'maybe sent to bed ? :D
			'If GetGameTime().GetHour() >= 5 and GetGameTime().GetHour() < 22 then 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["girl"]
		endif

		if (feedback.AudienceInterest.Pensioners > 0) then result :+ ["grandpa"]

		if (feedback.AudienceInterest.Teenagers > 0)
			'in school monday-friday - in school from till 7 to 13 - needs no sleep :D
			'If Game.GetWeekday()>6 or (GetGameTime().GetHour() < 7 or GetGameTime().GetHour() >= 13) then result :+ ["teen"] 'manuel: muss im Feedback-Code geprüft werden.
			result :+ ["teen"]
		endif

		return result
	End Function


	'draws the interface
	Method Draw(tweenValue:Float=1.0)
		SetBlend ALPHABLEND
		GetSpriteFromRegistry("gfx_interface_top").Draw(0,0)
		GetSpriteFromRegistry("gfx_interface_leftright").DrawClipped(new TPoint.Init(0, 20), new TRectangle.Init(0, 0, 27, 363))
		SetBlend SOLIDBLEND
		GetSpriteFromRegistry("gfx_interface_leftright").DrawClipped(new TPoint.Init(780, 20), new TRectangle.Init(27, 0, 20, 363))

		If BottomImgDirty

			SetBlend MASKBLEND
			'draw bottom, aligned "bottom"
			GetSpriteFromRegistry("gfx_interface_bottom").Draw(0, GetGraphicsManager().GetHeight(), 0, new TPoint.Init(ALIGN_LEFT, ALIGN_BOTTOM))

			If ShowChannel <> 0 Then GetSpriteFromRegistry("gfx_interface_audience_bg").Draw(520, 419)

		    'channel choosen and something aired?
		    local programmePlan:TPlayerProgrammePlan = GetPlayerProgrammePlanCollection().Get(ShowChannel)

			If programmePlan and programmePlan.GetAudience() > 0
				'If CurrentProgram = Null Then Print "ERROR: CurrentProgram is missing"
				If CurrentProgramme Then CurrentProgramme.Draw(45, 400)

				'fetch a list of watching family members
				local members:string[] = GetWatchingFamily()
				'later: limit to amount of "places" on couch
				Local familyMembersUsed:int = members.length

				'slots if 3 members watch
				local figureSlots:int[]
				if familyMembersUsed = 3 then figureSlots = [550, 610, 670]
				if familyMembersUsed = 2 then figureSlots = [580, 640]
				if familyMembersUsed = 1 then figureSlots = [610]

				'display an empty/dark room
				if familyMembersUsed = 0
					local col:TColor = new TColor.Get()
					SetColor 50, 50, 50
					SetBlend MASKBLEND
					GetSpriteFromRegistry("gfx_interface_audience_bg").Draw(520, 419)
					col.SetRGBA()
				else
					local currentSlot:int = 0
					For local member:string = eachin members
						GetSpriteFromRegistry("gfx_interface_audience_"+member).Draw(figureslots[currentslot], 419)
						currentslot:+1 'occupy a slot
					Next
				endif
			EndIf 'showchannel <>0
			SetBlend ALPHABLEND

			GetSpriteFromRegistry("gfx_interface_antenna").Draw(111,329)

			'draw noise of tv device
			If ShowChannel <> 0
				SetAlpha NoiseAlpha
				If noiseSprite Then noiseSprite.DrawClipped(new TPoint.Init(45, 400), new TRectangle.Init(noiseDisplace.GetX(),noiseDisplace.GetY(), 220,170) )
				SetAlpha 1.0
			EndIf
			'draw overlay to hide corners of non-round images
			GetSpriteFromRegistry("gfx_interface_tv_overlay").Draw(45,400)

		    For Local i:Int = 0 To 4
				If i = ShowChannel
					GetSpriteFromRegistry("gfx_interface_channelbuttons_on_"+i).Draw(75 + i * 33, 554)
				Else
					GetSpriteFromRegistry("gfx_interface_channelbuttons_off_"+i).Draw(75 + i * 33, 554)
				EndIf
		    Next

			'draw the small electronic parts - "the inner tv"
	  		SetBlend MASKBLEND
	     	GetSpriteFromRegistry("gfx_interface_audience_overlay").Draw(520, 419)
			SetBlend ALPHABLEND

			GetBitmapFont("Default", 13, BOLDFONT).drawBlock(GetPlayerCollection().Get().getMoneyFormatted() + "  ", 377, 427, 103, 25, new TPoint.Init(ALIGN_RIGHT), TColor.Create(200,230,200), 2)
			GetBitmapFont("Default", 13, BOLDFONT).drawBlock(GetPlayerCollection().Get().GetProgrammePlan().getFormattedAudience() + "  ", 377, 469, 103, 25, new TPoint.Init(ALIGN_RIGHT), TColor.Create(200,200,230), 2)
		 	GetBitmapFont("Default", 11, BOLDFONT).drawBlock((GetGameTime().daysPlayed+1) + ". "+GetLocale("DAY"), 366, 555, 120, 25, new TPoint.Init(ALIGN_CENTER), TColor.Create(180,180,180), 2)
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND


		SetAlpha 0.25
		GetBitmapFont("Default", 13, BOLDFONT).drawBlock(GetGameTime().getFormattedTime() + " "+GetLocale("OCLOCK"), 366, 542, 120, 25, new TPoint.Init(ALIGN_CENTER), TColor.Create(180,180,180))
		SetAlpha 0.9
		GetBitmapFont("Default", 13, BOLDFONT).drawBlock(GetGameTime().getFormattedTime()+ " "+GetLocale("OCLOCK"), 365,541,120,25, new TPoint.Init(ALIGN_CENTER), TColor.Create(40,40,40))
		SetAlpha 1.0

		For local tip:TTooltip = eachin tooltips
			If tip.enabled Then tip.Render()
		Next

	    GUIManager.Draw("InGame")

		TError.DrawErrors()
	End Method
End Type

