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


TGUIChatEntry.senderDrawTextEffect = new TDrawTextEffect
TGUIChatEntry.senderDrawTextEffect.data.mode = EDrawTextEffect.GLOW
TGUIChatEntry.senderDrawTextEffect.data.value = 1.0
TGUIChatEntry.valueDrawTextEffect = new TDrawTextEffect
TGUIChatEntry.valueDrawTextEffect.data.mode = EDrawTextEffect.GLOW
TGUIChatEntry.valueDrawTextEffect.data.value = 0.5



Type TGUIChat Extends TGUIPanel
	Field _defaultTextColor:TColor = TColor.Create(0,0,0)
	Field _defaultHideEntryTime:Int = Null
	Field _defaultSenderID:Int = 0
	Field _defaultSenderName:String = "unknown"
	'bitmask of channels the chat listens to
	Field _channels:Int = 0
	Field guiList:TGUIListBase = Null
	Field guiInput:TGUIInput = Null
	'is the input is inside the chatbox or absolute
	Field guiInputPositionRelative:Int = 0
	Field guiInputHistory:TList	= CreateList()

	'time when again allowed to send
	Global antiSpamTimer:Long = 0
	Global antiSpamTime:Int	= 100


	Method Create:TGUIChat(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Local cScrRect:TRectangle = GetContentScreenRect()
		guiList = New TGUIListBase.Create(New SVec2I(0,0), New SVec2I(Int(cScrRect.w), Int(cScrRect.h)), limitState)
		guiList.setOption(GUI_OBJECT_ACCEPTS_DROP, False)
		guiList.SetAutoSortItems(False)
		guiList.SetAcceptDrop("")
		guiList.setParent(Self)
		guiList.SetAutoScroll(True)
		guiList.SetBackground(Null)

		guiInput = New TGUIInput.Create(New SVec2I(0, dimension.y), New SVec2I(dimension.x, -1), "", 32, limitState)
		guiInput.setParent(Self)

		'resize base and move child elements
		SetSize(dimension.x, dimension.y)

		'by default all chats want to list private messages and system announcements
		setListenToChannel(CHAT_CHANNEL_PRIVATE, True)
		setListenToChannel(CHAT_CHANNEL_SYSTEM, True)
		setListenToChannel(CHAT_CHANNEL_GLOBAL, True)

		'register events
		'- observe text changes in our input field
		EventManager.registerListenerFunction( GUIEventKeys.GUIobject_OnChange, Self.onInputChange, Self.guiInput )
		'- observe wishes to add a new chat entry - listen to all sources
		EventManager.registerListenerMethod( GUIEventKeys.Chat_OnAddEntry, Self, "onAddEntry" )

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
	
	
	'remove all entries
	Method Clear:Int()
		guiList.EmptyList()
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
		Return _defaultSenderID
	End Method


	'implement in custom chats
	Method GetSenderName:String()
		Return _defaultSenderName
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
		TriggerBaseEvent(GUIEventKeys.Chat_onAddEntry, New TData.Add("senderID", guiChat.GetSenderID()).Add("senderName", guiChat.GetSenderName()).Add("channels", sendToChannels).Add("text",guiInput.value) , guiChat )

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
		If triggerEvent.getReceiver() And guiChat <> Self Then Return False

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


	Function GetChannelsFromText:Int(text:String)
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
		
		'now we know the actual content and resize properly
		local dim:SVec2F = entry.GetDimension()
		entry.SetSize(dim.x, dim.y)

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


	Method UpdateLayout()
		Super.UpdateLayout()

		'background covers whole area, so resize it
		If guiBackground Then guiBackground.SetSize(rect.getW(), rect.getH())

		Local subtractInputHeight:Float = 0.0
		'move and resize input field to the bottom
		If guiInput And Not guiInput.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiInput.SetSize(GetContentScreenRect().GetW(),Null)
			guiInput.SetPosition(0, GetContentScreenRect().GetH() - guiInput.GetScreenRect().GetH())
			subtractInputHeight = guiInput.GetScreenRect().GetH()
		EndIf

		'move and resize the listbox (subtract input if needed)
		If guiList
			guiList.SetSize(GetContentScreenRect().GetW(), GetContentScreenRect().GetH() - subtractInputHeight)
		EndIf
	End Method
End Type




Type TGUIChatEntry Extends TGUIListItem
	'boxDimension already includes "linebox", 
	'so additional padding is not needed for now
	Field paddingBottom:Int	= 0
	
	Global senderDrawTextEffect:TDrawTextEffect
	Global valueDrawTextEffect:TDrawTextEffect


	Method CreateSimple:TGUIChatEntry(text:String, textColor:TColor, senderName:String, senderColor:TColor, lifetime:Int=Null)
   		Super.CreateBase(Null, Null, "")

		SetLifetime(lifeTime)
		SetShowtime(lifeTime)
		SetSender(senderName, senderColor)
		SetValue(text)
		SetValueColor(textColor)

		GUIManager.add(Self)

		Return Self
	End Method


    Method Create:TGUIChatEntry(pos:SVec2I, dimension:SVec2I, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetValue(value)
		SetLifetime( 1000 )
		SetShowtime( 1000 )

		'now we know the actual content and resize properly
		local dim:SVec2F = GetDimension()
		SetSize(dim.x, dim.y)

		GUIManager.add(Self)

		Return Self
	End Method


	Method GetDimension:SVec2F() override
		Local move:SVec2I
		Local senderName:String = Data.getString("senderName")
		If senderName
			Local width:Int = GetBitmapFontManager().baseFontBold.GetWidth(senderName + ":", senderDrawTextEffect)
			'move the x so we get space between name and text
			move = new SVec2I(width + 5, 0)
		EndIf

		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel( GetFirstParentalObject("tguiscrollablepanel") )
		Local maxWidth:Int
		If parentPanel
			maxWidth = parentPanel.GetContentScreenRect().GetW()
		ElseIf _parent
			maxWidth = _parent.GetContentScreenRect().GetW()
		Else
			maxWidth = rect.GetW()
		EndIf
		If maxWidth <> -1 Then maxWidth :- rect.GetX()
		If maxWidth = -1 Then maxWidth = GetScreenRect().GetW()
		If maxWidth <> -1 Then maxWidth :+ 10
'		maxWidth=295
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:SVec2I = GetBitmapFontManager().baseFont.GetBoxDimension(GetValue(), maxWidth - move.X, maxHeight, valueDrawTextEffect)
		'add padding
		dimension = new SVec2I(dimension.x, dimension.y + paddingBottom)

		'print "  id="+_id+": " + GetValue()+"    move="+move.x + ", "+move.y + " dimension="+dimension.x+", " + dimension.y +"   maxWidth="+maxWidth+"  paddingBottom="+paddingBottom
		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If rect.getW() <> dimension.x Or rect.getH() <> dimension.y
			'resize item
			SetSize(dimension.x, dimension.y)
			'recalculate item positions and scroll limits
			'-> without multi-line entries would be not completely visible
			Local list:TGUIListBase = TGUIListBase( GetFirstParentalObject("tguilistbase") )

'			If list Then list.RecalculateElements()
			If list Then list.InvalidateLayout()
		EndIf

		Return new SVec2F(dimension.x, dimension.y)
	End Method


	Method SetSender:Int(senderName:String=Null, senderColor:TColor=Null)
		If senderName Then Self.Data.Add("senderName", senderName)
		If senderColor Then Self.Data.Add("senderColor", senderColor)
	End Method


	Method DrawContent()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))
		Local screenX:Int = GetScreenRect().GetX()
		Local screenY:Int = GetScreenRect().GetY()
		If Not parentPanel Then Throw "GUIChatEntry - no parentpanel"
		If _parent.GetScreenRect().GetY() > screenY + rect.GetH() Then Return
		If _parent.GetScreenRect().GetY() + _parent.GetScreenRect().GetH() < screenY Then Return

		Local maxWidth:Int = parentPanel.GetContentScreenRect().GetW() - Self.rect.getX()

		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local move:SVec2I
		Local oldCol:SColor8, oldAlpha:Float
		GetColor(oldCol)
		oldAlpha = GetAlpha()

		If Self.showtime <> Null Then SetAlpha oldCol.a * Float(Self.showtime - Time.GetTimeGone())/500.0
		If Self.Data.getString("senderName",Null)
			Local senderColor:TColor = TColor(Self.Data.get("senderColor"))
			If Not senderColor Then senderColor = TColor.Create(0,0,0)
			move = GetBitmapFontManager().baseFontBold.DrawSimple(Self.Data.getString("senderName", "")+":", screenX, screenY, senderColor.ToScolor8(), EDrawTextEffect.Shadow, 0.5)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move = new SVec2I(move.x + 5, 1)
		EndIf
		GetBitmapFontManager().baseFont.DrawBox(GetValue(), screenX + move.x, screenY + move.y, maxWidth - move.X, maxHeight, sALIGN_LEFT_TOP, valueColor, EDrawTextEffect.Shadow, 0.5)

		SetColor(oldCol)
		SetAlpha(oldAlpha)
	End Method
End Type
