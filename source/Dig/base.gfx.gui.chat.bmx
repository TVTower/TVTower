SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.panel.bmx"
Import "base.gfx.gui.input.bmx"
Import "base.gfx.gui.list.base.bmx"


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
	Global antiSpamTimer:Long = 0
	Global antiSpamTime:Int	= 100


	Method Create:TGUIChat(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		guiList = New TGUIListBase.Create(New TVec2D.Init(0,0), New TVec2D.Init(GetContentScreenWidth(),GetContentScreenHeight()), limitState)
		guiList.setOption(GUI_OBJECT_ACCEPTS_DROP, False)
		guiList.SetAutoSortItems(False)
		guiList.SetAcceptDrop("")
		guiList.setParent(Self)
		guiList.SetAutoScroll(True)
		guiList.SetBackground(Null)

		guiInput = New TGUIInput.Create(New TVec2D.Init(0, dimension.y),New TVec2D.Init(dimension.x,-1), "", 32, limitState)
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
	Method HideChat:Int()
		guiList.Hide()
	End Method


	Method ShowChat:Int()
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


	'implement in custom chats
	Method GetSenderID:Int()
		return 0
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
		EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", New TData.AddNumber("senderID", guiChat.GetSenderID()).AddNumber("channels", sendToChannels).AddString("text",guiInput.value) , guiChat ) )

		'avoid getting the enter-key registered multiple times
		'which leads to "flickering"
		KEYMANAGER.blockKey(KEY_ENTER, 250) 'block for 100ms

		'trigger antiSpam
		guiChat.antiSpamTimer = Time.GetAppTimeGone() + guiChat.antiSpamTime

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
		'if event has a specific receiver and this is not this chat
		If triggerEvent.getReceiver() and guiChat <> Self Then Return False

		'DO NOT WRITE COMMANDS !
		If GetCommandFromText(triggerEvent.GetData().GetString("text")) = CHAT_COMMAND_SYSTEM
			Return False
		EndIf

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


	Function GetPayloadFromText:String(text:String)
		text = text.Trim()
		If Left( text,1 ) <> "/" Then Return ""

		Return Right(text, text.length - Instr(text, " "))
	End Function


	Function GetCommandStringFromText:String(text:String)
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
		Local senderName:String	= data.getString("senderName", "guest")
		Local senderColor:TColor= TColor( data.get("senderColor") )

		If Not textColor Then textColor = Self._defaultTextColor
		If Not senderColor Then senderColor = Self._defaultTextColor

		'finally add to the chat box
		Local entry:TGUIChatEntry = New TGUIChatEntry.CreateSimple(text, textColor, senderName, senderColor, Null )
		'if the default is "null" then no hiding will take place
		entry.SetShowtime( _defaultHideEntryTime )
		AddEntry( entry )
	End Method


	Method SetPadding:Int(top:Float, left:Float, bottom:Float, right:Float)
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


Type TGUIChatEntry Extends TGUIListItem
	Field paddingBottom:Int	= 5


	Method CreateSimple:TGUIChatEntry(text:String, textColor:TColor, senderName:String, senderColor:TColor, lifetime:Int=Null)
		Create(Null,Null, text)
		SetLifetime(lifeTime)
		SetShowtime(lifeTime)
		SetSender(senderName, senderColor)
		SetValue(text)
		SetValueColor(textColor)

		GetDimension()

		Return Self
	End Method


    Method Create:TGUIChatEntry(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetValue(value)
		SetLifetime( 1000 )
		SetShowtime( 1000 )

		'now we know the actual content and resize properly
		Resize(GetDimension().GetX(), GetDimension().GetY())

		GUIManager.add(Self)

		Return Self
	End Method


	Method GetDimension:TVec2D()
		local startX:int = self.GetScreenX()
		local startY:int = self.GetScreenY()
		Local move:TVec2D = New TVec2D.Init(0,0)
		If Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = GetBitmapFontManager().baseFontBold.drawStyled(Data.getString("senderName")+":", startX, startY, senderColor, 2, 0)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.SetXY( move.x + 5, 1)
		EndIf
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetParent("tguiscrollablepanel"))
		Local maxWidth:Int
		If parentPanel
			maxWidth = parentPanel.GetContentScreenWidth()
		Else
			maxWidth = GetParent().GetContentScreenWidth()
		EndIf
		if maxWidth <> -1 then maxWidth :- rect.GetX()
		if maxWidth = -1 then maxWidth = GetScreenWidth()
		if maxWidth <> -1 then maxWidth :+ 10
'		maxWidth=295
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = GetBitmapFontManager().baseFont.drawBlock(GetValue(), startX + move.x, startY + move.y, maxWidth - move.X, maxHeight, Null, Null, 2, 0)
		'add padding
		dimension.addXY(0, paddingBottom)
'print GetValue()+"     " + dimension.y +"   move.y="+move.Y+"   maxWidth="+maxWidth+"  move.X="+move.X
		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If rect.getW() <> dimension.getX() Or rect.getH() <> dimension.getY()
			'resize item
			Resize(dimension.getX(), dimension.getY())
			'recalculate item positions and scroll limits
			'-> without multi-line entries would be not completely visible
			local list:TGUIListBase = TGUIListBase(self.getParent("tguilistbase"))
			if list then list.RecalculateElements()
		EndIf

		Return dimension
	End Method


	Method SetSender:Int(senderName:String=Null, senderColor:TColor=Null)
		If senderName Then Self.Data.AddString("senderName", senderName)
		If senderColor Then Self.Data.Add("senderColor", senderColor)
	End Method


	Method GetParentWidth:Float(parentClassName:String="toplevelparent")
		If Not Self._parent Then Return Self.rect.getW()
		Return Self.getParent(parentClassName).rect.getW()
	End Method


	Method GetParentHeight:Float(parentClassName:String="toplevelparent")
		If Not Self._parent Then Return Self.rect.getH()
		Return Self.getParent(parentClassName).rect.getH()
	End Method


	Method DrawContent()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		local screenX:int = GetScreenX()
		local screenY:int = GetScreenY()
		if not parentPanel then throw "GUIChatEntry - no parentpanel"
		if GetParent().GetScreenY() > screenY + rect.GetH() then return
		if GetParent().GetScreenY() + GetParent().GetScreenHeight() < screenY then return

		Local maxWidth:Int = parentPanel.getContentScreenWidth() - Self.rect.getX()

		'local maxWidth:int = self.getParentWidth("tguiscrollablepanel")-self.rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local move:TVec2D = New TVec2D.Init(0,0)
		local oldCol:TColor = new TColor.Get()

		If Self.showtime <> Null Then SetAlpha oldCol.a * Float(Self.showtime - Time.GetTimeGone())/500.0
		If Self.Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Self.Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = GetBitmapFontManager().baseFontBold.drawStyled(Self.Data.getString("senderName", "")+":", screenX, screenY, senderColor, 2, 1)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.SetXY( move.x + 5, 1)
		EndIf
		GetBitmapFontManager().baseFont.drawBlock(GetValue(), screenX + move.x, screenY + move.y, maxWidth - move.X, maxHeight, Null, valueColor, 2, 1, 0.5)

		oldCol.SetRGBA()
	End Method
End Type
