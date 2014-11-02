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
	char.area.dimension.addXY(shadowSize, shadowSize)

	char.img = LoadImage(newPixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function




Type TGUISpriteDropDown extends TGUIDropDown

	Method Create:TGUISpriteDropDown(position:TVec2D = null, dimension:TVec2D = null, value:string="", maxLength:Int=128, limitState:String = "")
		Super.Create(position, dimension, value, maxLength, limitState)
		Return self
	End Method
	

	'override to add sprite next to value
	Method DrawInputContent:Int(position:TVec2D)
		'position is already a copy, so we can reuse it without
		'copying it first

		'draw sprite
		if TGUISpriteDropDownItem(selectedEntry)
			local scaleSprite:float = 0.8
			local labelHeight:int = GetFont().GetHeight(GetValue())
			local item:TGUISpriteDropDownItem = TGUISpriteDropDownItem(selectedEntry)
			local sprite:TSprite = GetSpriteFromRegistry( item.data.GetString("spriteName", "default") )
			if item and sprite.GetName() <> "defaultSprite"
				local displaceY:int = -1 + 0.5 * (labelHeight - (item.GetSpriteDimension().y * scaleSprite))
				sprite.DrawArea(position.x, position.y + displaceY, item.GetSpriteDimension().x * scaleSprite, item.GetSpriteDimension().y * scaleSprite)
				position.addXY(item.GetSpriteDimension().x * scaleSprite + 3, 0)
			endif
		endif

		'draw value
		Super.DrawInputContent(position)
	End Method
End Type


Type TGUISpriteDropDownItem Extends TGUIDropDownItem
	Global spriteDimension:TVec2D
	Global defaultSpriteDimension:TVec2D = new TVec2D.Init(24, 24)
	

    Method Create:TGUISpriteDropDownItem(position:TVec2D=null, dimension:TVec2D=null, value:String="")
		if not dimension
			dimension = new TVec2D.Init(-1, GetSpriteDimension().y + 2)
		else
			dimension.x = Max(dimension.x, GetSpriteDimension().x)
			dimension.y = Max(dimension.y, GetSpriteDimension().y)
		endif
		Super.Create(position, dimension, value)
		return self
    End Method


    Method GetSpriteDimension:TVec2D()
		if not spriteDimension then return defaultSpriteDimension
		return spriteDimension
    End Method


	Method SetSpriteDimension:int(dimension:TVec2D)
		spriteDimension = dimension.copy()

		Resize(..
			Max(dimension.x, GetSpriteDimension().x), ..
			Max(dimension.y, GetSpriteDimension().y) ..
		)
	End Method


	'override to change color
	Method DrawBackground:int()
		local oldCol:TColor = new TColor.Get()
		SetColor(125, 160, 215)
		If mouseover
			SetAlpha(oldCol.a * 0.75)
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), rect.getH())
		ElseIf selected
			SetAlpha(oldCol.a * 0.5)
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), rect.getH())
		EndIf
		oldCol.SetRGBA()
	End Method
    

	Method DrawValue:int()
		local valueX:int = getScreenX()

		local sprite:TSprite = GetSpriteFromRegistry( data.GetString("spriteName", "default") )
		if sprite.GetName() <> "defaultSprite"
			sprite.DrawArea(valueX, GetScreenY()+1, GetSpriteDimension().x, GetSpriteDimension().y)
			valueX :+ GetSpriteDimension().x + 3
		else
			valueX :+ GetSpriteDimension().x + 3
		endif
		'draw value
		GetFont().draw(value, valueX, Int(GetScreenY() + 2 + 0.5*(rect.getH()- GetFont().getHeight(value))), valueColor)
	End Method
End Type




Type TGUIChatWindow Extends TGUIGameWindow
	Field guiPanel:TGUIBackgroundBox
	Field guiChat:TGUIChat
	Field padding:TRectangle = new TRectangle.Init(8, 8, 8, 8)


	Method Create:TGUIChatWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		'use "create" instead of "createBase" so the caption gets
		'positioned similar
		Super.Create(pos, dimension, limitState)

		guiPanel = AddContentBox(0,0,GetContentScreenWidth()-10,-1)
		'we manage the panel
		AddChild(guiPanel)

		guiChat = new TGUIChat.Create(new TVec2D.Init(0,0), new TVec2D.Init(-1,-1), limitState)
		'we manage the panel
		AddChild(guiChat)

		'resize base and move child elements
		resize(dimension.GetX(), dimension.GetY())

		GUIManager.Add( Self )

		Return Self
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

		If guiPanel then guiPanel.Resize(GetContentScreenWidth(), GetContentScreenHeight())
		
		If guiChat
			guiChat.rect.position.SetXY(padding.GetLeft(), padding.GetTop())
			guiChat.Resize(GetContentScreenWidth() - padding.GetRight() - padding.GetLeft(), GetContentScreenHeight() - padding.GetTop() - padding.GetBottom())
		endif
	End Method
End Type




Type TGUIChat Extends TGUIPanel
	Field _defaultTextColor:TColor = TColor.Create(0,0,0)
	Field _defaultHideEntryTime:Int = Null
	'bitmask of channels the chat listens to
	Field _channels:Int = 0
	Field guiList:TGUIListBase = Null
	Field guiInput:TGUIInput = Null
	'is the input is inside the chatbox or absolute
	Field guiInputPositionRelative:Int = 0
	Field guiInputHistory:TList	= CreateList()
	Field keepInputActive:Int = True

	'time when again allowed to send
	Global antiSpamTimer:Int = 0
	Global antiSpamTime:Int	= 100


	Method Create:TGUIChat(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		guiList = New TGUIListBase.Create(new TVec2D.Init(0,0), new TVec2D.Init(GetContentScreenWidth(),GetContentScreenHeight()), limitState)
		guiList.setOption(GUI_OBJECT_ACCEPTS_DROP, False)
		guiList.autoSortItems = False
		guiList.SetAcceptDrop("")
		guiList.setParent(Self)
		guiList.autoScroll = True
		guiList.SetBackground(Null)

		guiInput = New TGUIInput.Create(new TVec2D.Init(0, dimension.y),new TVec2D.Init(dimension.x,-1), "", 32, limitState)
		guiInput.setParent(Self)

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


	'only hides the box with the messages
	Method HideChat:int()
		guiList.Hide()
	End Method


	Method ShowChat:int()
		guiList.Show()
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
		guiChat.antiSpamTimer = Time.GetTimeGone() + guiChat.antiSpamTime

		If guiChat.guiInputHistory.last() <> guiInput.value
			guiChat.guiInputHistory.AddLast(guiInput.value)

			'limit history to 50 entries
			While guiChat.guiInputHistory.Count() > 50
				guichat.guiInputHistory.RemoveFirst()
			Wend
		EndIf

		'reset input field
		guiInput.SetValue("")
	End Function


	Method onAddEntry:Int( triggerEvent:TEventBase )
		Local guiChat:TGUIChat = TGUIChat(triggerEvent.getReceiver())
		'if event has a specific receiver and this is not a chat - we are not interested
		If triggerEvent.getReceiver() And Not guiChat Then Return False
		'found a chat - but it is another chat
		If guiChat And guiChat <> Self Then Return False

		'DO NOT WRITE COMMANDS !
		if GetCommandFromText(triggerEvent.GetData().GetString("text")) <> CHAT_COMMAND_NONE
			return False
		endif

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
		Select GetCommandFromText(text)
			Case CHAT_COMMAND_WHISPER
				sendToChannels :| CHAT_CHANNEL_PRIVATE
			Case CHAT_COMMAND_SYSTEM
				sendToChannels :| CHAT_CHANNEL_SYSTEM
			Default
				sendToChannels :| CHAT_CHANNEL_GLOBAL
		End Select
		Return SendToChannels
	End Function


	Function GetPayloadFromText:string(text:string)
		text = text.Trim()
		If Left( text,1 ) <> "/" Then Return ""

		Return Right(text, text.length - Instr(text, " "))
	End Function


	Function GetCommandStringFromText:string(text:string)
		text = text.Trim()
		If Left( text,1 ) <> "/" Then Return ""

		Return Mid(text, 2, Instr(text, " ") - 2 )
	End Function
	

	Function GetCommandFromText:Int(text:String)
		Select GetCommandStringFromText(text).ToLower()
			Case "fluestern", "whisper", "w"
				Return CHAT_COMMAND_WHISPER
			Case "dev", "sys"
				Return CHAT_COMMAND_SYSTEM
			Default
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

		local sendingPlayer:TPlayerBase = GetPlayerCollection().Get(senderID)

		If sendingPlayer and senderID > 0
			senderName	= sendingPlayer.Name
			senderColor	= sendingPlayer.color
			If Not textColor Then textColor = Self._defaultTextColor
		Else
			senderName	= "SYSTEM"
			senderColor	= TColor.Create(220,50,50)
			textColor	= TColor.Create(220,80,70)
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

		Local subtractInputHeight:Float = 0.0
		'move and resize input field to the bottom
		If guiInput And Not guiInput.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiInput.resize(GetContentScreenWidth(),Null)
			guiInput.rect.position.setXY(0, GetContentScreenHeight() - guiInput.GetScreenHeight())
			subtractInputHeight = guiInput.GetScreenHeight()
		EndIf

		'move and resize the listbox (subtract input if needed)
		If guiList
			guiList.resize(GetContentScreenWidth(), GetContentScreenHeight() - subtractInputHeight)
		EndIf
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


	Method Create:TGUIGameWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
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
		Local box:TGUIBackgroundBox = New TGUIBackgroundBox.Create(new TVec2D.Init(displaceX, maxOtherBoxesY + displaceY), new TVec2D.Init(w, h), "")

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
	Method Create:TGUIGameModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
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


    Method Create:TGUIChatEntry(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		Resize(GetDimension().GetX(), GetDimension().GetY())
		SetValue(value)
		SetLifetime( 1000 )
		SetShowtime( 1000 )

		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TVec2D()
		Local move:TVec2D = new TVec2D.Init(0,0)
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

		Local dimension:TVec2D = GetBitmapFontManager().baseFont.drawBlock(GetValue(), getScreenX()+move.x, getScreenY()+move.y, maxWidth-move.X, maxHeight, Null, Null, 2, 0)

		'add padding
		dimension.addXY(0, paddingBottom)

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


	Method DrawContent:Int()
		Self.getParent("tguilistbase").RestrictViewPort()

		If Self.showtime <> Null Then SetAlpha Float(Self.showtime - Time.GetTimeGone())/500.0
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = parentPanel.getContentScreenWidth()-Self.rect.getX()

		'local maxWidth:int = self.getParentWidth("tguiscrollablepanel")-self.rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local move:TVec2D = new TVec2D.Init(0,0)
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


    Method Create:TGUIGameList(pos:TVec2D=null, dimension:TVec2D=null, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Return Self
	End Method

rem
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
endrem

	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		'check if we already have an item with the same value
		local gameItem:TGUIGameEntry = TGUIGameEntry(item)
		if gameItem
			For Local olditem:TGUIListItem = EachIn Self.entries
				'skip other items (same ip:port-combination)
				if gameItem.data.GetInt("hostPort") <> olditem.data.GetInt("hostPort") OR gameItem.data.GetString("hostIP") <> olditem.data.GetString("hostIP") then continue
				'refresh lifetime
				olditem.setLifeTime(olditem.initialLifeTime)
				'unset the new one
				item.remove()
				Return False
			Next
		endif
		Return Super.AddItem(item, extra)
	End Method
End Type




Type TGUIGameEntry Extends TGUISelectListItem
	Field paddingBottom:Int		= 3
	Field paddingTop:Int		= 2


	Method CreateSimple:TGUIGameEntry(hostIP:String, hostPort:Int, hostName:String="", gameTitle:String="", slotsUsed:Int, slotsMax:Int)
		'make it "unique" enough
		Self.Create(null, null, hostIP+":"+hostPort)

		Self.data.AddString("hostIP", hostIP)
		Self.data.AddNumber("hostPort", hostPort)
		Self.data.AddString("hostName", hostName)
		Self.data.AddString("gameTitle", gametitle)
		Self.data.AddNumber("slotsUsed", slotsUsed)
		Self.data.AddNumber("slotsMax", slotsMax)

		'resize it
		GetDimension()

		Return Self
	End Method


    Method Create:TGUIGameEntry(pos:TVec2D=null, dimension:TVec2D=null, value:String="")

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetLifetime(30000) '30 seconds
		SetValue(":D")
		SetValueColor(TColor.Create(0,0,0))
		
		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 200
		if parentPanel then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = new TVec2D.Init(maxWidth, GetBitmapFontManager().baseFont.GetMaxCharHeight())
		
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


	'override
	Method DrawValue:int()
		'draw text
		Local move:TVec2D = new TVec2D.Init(0, Self.paddingTop)
		Local text:String = ""
		Local textColor:TColor = Null
		Local textDim:TVec2D = Null
		'line: title by hostname (slotsused/slotsmax)
'DrawRect(GetScreenX(), GetScreenY(), GetDimension().x, GetDimension().y)
		text 		= Self.Data.getString("gameTitle","#unknowngametitle#")
		textColor	= TColor(Self.Data.get("gameTitleColor", TColor.Create(150,80,50)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor, 2, 1,0.5)
		move.addXY(textDim.x,1)

		text 		= " by "+Self.Data.getString("hostName","#unknownhostname#")
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(50,50,150)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.addXY(textDim.x,0)

		text 		= " ("+Self.Data.getInt("slotsUsed",1)+"/"++Self.Data.getInt("slotsMax",4)+")"
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(0,0,0)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.addXY(textDim.x,0)
	End Method


	Method DrawContent:Int()
		If Self.showtime <> Null
			SetAlpha Float(Self.showtime - Time.GetTimeGone())/500.0
		endif
		
		'draw highlight-background etc
		Super.DrawContent()

		SetAlpha 1.0
	End Method
End Type




Type THotspot extends TStaticEntity
	Field name:String = ""
	Field tooltipEnabled:int = True
	Field tooltip:TTooltip = Null
	Field tooltipText:String = ""
	Field tooltipDescription:String	= ""
	Field hovered:Int = False
	Field enterable:int = False
	Global list:TList = CreateList()


	Method Create:THotSpot(name:String, x:Int,y:Int,w:Int,h:Int)
		area = new TRectangle.Init(x,y,w,h)
		Self.name = name

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


	Method SetEnterable(bool:int = True)
		enterable = bool
	End Method


	Method IsEnterable:int()
		return enterable
	End Method


	'update tooltip
	'handle clicks -> send events so eg can send figure to it
	Method Update:Int(offsetX:Int=0,offsetY:Int=0)
		hovered = False
	
		If GetScreenArea().containsXY(MouseManager.x, MouseManager.y)
			hovered = True
			If MOUSEMANAGER.isClicked(1)
				EventManager.triggerEvent( TEventSimple.Create("hotspot.onClick", new TData , Self ) )
			EndIf
		EndIf

		If hovered and tooltipEnabled
			If tooltip
				tooltip.Hover()
			ElseIf tooltipText<>""
				tooltip = TTooltip.Create(tooltipText, tooltipDescription, 100, 140, 0, 0)
				'so it aligns properly to the hotspot
				tooltip.SetParent(self)
				'layout the tooltip centered above the hotspot
				tooltip.area.position.SetXY(area.GetW()/2 - tooltip.GetWidth()/2, -tooltip.GetHeight())

				tooltip.enabled = True
			EndIf
		EndIf

		If tooltip And tooltip.enabled
			'tooltip.area.position.SetXY( adjustedArea.getX() + adjustedArea.getW()/2 - tooltip.GetWidth()/2, adjustedArea.getY() - tooltip.GetHeight())
			tooltip.Update()
			'delete old tooltips
			If tooltip.lifetime < 0 Then tooltip = Null
		EndIf
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		'DrawRect(GetScreenArea().GetX(), GetScreenArea().GetY(), GetScreenArea().GetW(), GetScreenArea().GetH())
		If tooltip Then tooltip.Render()
	End Method
End Type











Type TBlockGraphical Extends TBlockMoveable
	Field imageBaseName:String
	Field imageDraggedBaseName:String
	Field image:TSprite
	Field image_dragged:TSprite
    Global AdditionallyDragged:Int	= 0
End Type







'a graphical representation of multiple object ingame
Type TGUIGameListItem Extends TGUIListItem
	Field assetNameDefault:String = "gfx_movie_undefined"
	Field assetNameDragged:String = "gfx_movie_undefined"
	Field asset:TSprite = Null
	Field assetDefault:TSprite = Null
	Field assetDragged:TSprite = Null


    Method Create:TGUIGameListItem(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
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

		'over item and item could get dragged - indicate with hand cursor
		If Self.mouseover and Self.IsDragable() Then Game.cursorstate = 1

		If Self.isDragged()
			Self.SetAsset(Self.assetDragged)
			Game.cursorstate = 2
		EndIf
	End Method


	Method DrawContent()
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






Type TError
	Field title:String
	Field message:String
	Field id:Int
	Field link:TLink
	Field pos:TVec2D

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
		obj.pos		= new TVec2D.Init(400-obj.sprite.area.GetW()/2 +6, 200-obj.sprite.area.GetH()/2 +6)
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
		DrawRect(0,0,800, 385)
		SetAlpha 1.0
		Game.cursorstate = 0
		SetColor 255,255,255
		sprite.Draw(pos.x,pos.y)
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.area.GetW() - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.area.GetW()-40, sprite.area.GetH()-60, Null, TColor.Create(50, 50, 50))
  End Method
End Type


'extend tooltip to overwrite draw method
Type TTooltipAudience Extends TTooltip
	Field audienceResult:TAudienceResult
	Field showDetails:Int = False
	Field lineHeight:Int = 0
	Field lineIconHeight:Int = 0
	Field originalPos:TVec2D

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
			Return Self.useFont.GetWidth( GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + MathHelper.floatToString(100.0 * audienceResult.GetPotentialMaxAudienceQuote().GetAverage(), 2) + "%)" )
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

		local reach:int = GetStationMapCollection().GetMap(GetPlayerCollection().playerID).reach
		local totalReach:int = GetStationMapCollection().population
		result:+ Self.Usefont.GetHeight(GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + MathHelper.floatToString(100.0 * audienceResult.GetPotentialMaxAudienceQuote().GetAverage(), 2) + "%)")
		result:+ Self.Usefont.GetHeight(GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 0) + " (" + MathHelper.floatToString(100.0 * float(reach)/totalReach, 2) + "%)")
		result:+ 1*lineHeight

		If showDetails
			result:+ 9*lineIconHeight
		else
			result:+ 1*lineHeight
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
		Local lineIconX:Int = lineX + GetSpriteFromRegistry("gfx_targetGroup1").area.GetW() + 2
		Local lineIconWidth:Int = w - GetSpriteFromRegistry("gfx_targetGroup1").area.GetW()
		Local lineIconDY:Int = floor(0.5 * (lineIconHeight - lineHeight))
		Local lineTextDY:Int = lineIconDY + 2

		'draw overview text
		lineText = GetLocale("MAX_AUDIENCE_RATING") + ": " + TFunctions.convertValue(audienceResult.PotentialMaxAudience.GetSum(),0) + " (" + MathHelper.floatToString(100.0 * audienceResult.GetPotentialMaxAudienceQuote().GetAverage(), 2) + "%)"
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ 1 * Self.Usefont.GetHeight(lineText)

		local reach:int = GetStationMapCollection().GetMap(GetPlayerCollection().playerID).reach
		local totalReach:int = GetStationMapCollection().population

		lineText = GetLocale("BROADCASTING_AREA") + ": " + TFunctions.convertValue(reach, 0) + " (" + MathHelper.floatToString(100.0 * float(reach)/totalReach, 2) + "%)"
		Self.Usefont.draw(lineText, lineX, lineY, TColor.CreateGrey(90))
		lineY :+ Self.Usefont.GetHeight(lineText)

		'add 1 line more - as spacing to details
		lineY :+ lineHeight

		
		If Not showDetails
			Self.Usefont.draw(GetLocale("HINT_PRESSING_ALT_WILL_SHOW_DETAILS") , lineX, lineY, TColor.CreateGrey(150))
		Else
			'add lines so we can have an easier "for loop"
			Local lines:String[9]
			Local percents:String[9]
			local audienceQuote:TAudience = audienceResult.GetAudienceQuote()
			lines[0]	= getLocale("AD_TARGETGROUP_1") + ": " + TFunctions.convertValue(audienceResult.Audience.Children, 0)
			percents[0]	= MathHelper.floatToString(audienceQuote.Children * 100,2)
			lines[1]	= getLocale("AD_TARGETGROUP_2") + ": " + TFunctions.convertValue(audienceResult.Audience.Teenagers, 0)
			percents[1]	= MathHelper.floatToString(audienceQuote.Teenagers * 100,2)
			lines[2]	= getLocale("AD_TARGETGROUP_3") + ": " + TFunctions.convertValue(audienceResult.Audience.HouseWifes, 0)
			percents[2]	= MathHelper.floatToString(audienceQuote.HouseWifes * 100,2)
			lines[3]	= getLocale("AD_TARGETGROUP_4") + ": " + TFunctions.convertValue(audienceResult.Audience.Employees, 0)
			percents[3]	= MathHelper.floatToString(audienceQuote.Employees * 100,2)
			lines[4]	= getLocale("AD_TARGETGROUP_5") + ": " + TFunctions.convertValue(audienceResult.Audience.Unemployed, 0)
			percents[4]	= MathHelper.floatToString(audienceQuote.Unemployed * 100,2)
			lines[5]	= getLocale("AD_TARGETGROUP_6") + ": " + TFunctions.convertValue(audienceResult.Audience.Manager, 0)
			percents[5]	= MathHelper.floatToString(audienceQuote.Manager * 100,2)
			lines[6]	= getLocale("AD_TARGETGROUP_7") + ": " + TFunctions.convertValue(audienceResult.Audience.Pensioners, 0)
			percents[6]	= MathHelper.floatToString(audienceQuote.Pensioners * 100,2)
			lines[7]	= getLocale("AD_TARGETGROUP_8") + ": " + TFunctions.convertValue(audienceResult.Audience.Women, 0)
			percents[7]	= MathHelper.floatToString(audienceQuote.Women * 100,2)
			lines[8]	= getLocale("AD_TARGETGROUP_9") + ": " + TFunctions.convertValue(audienceResult.Audience.Men, 0)
			percents[8]	= MathHelper.floatToString(audienceQuote.Men * 100,2)

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
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineTextDY, lineIconWidth - 5, lineIconHeight, new TVec2D.Init(ALIGN_RIGHT), ColorTextLight)
				Else
					Usefont.drawBlock(lines[i-1], lineIconX, lineY + lineTextDY,  w, lineHeight, Null, ColorTextDark)
					Usefont.drawBlock(percents[i-1]+"%", lineIconX, lineY + lineTextDY, lineIconWidth - 5, lineIconHeight, new TVec2D.Init(ALIGN_RIGHT), ColorTextDark)
				EndIf

				lineY :+ lineIconHeight
			Next
		EndIf
	End Method
End Type


