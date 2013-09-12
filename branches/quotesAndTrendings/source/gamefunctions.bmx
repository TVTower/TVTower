'Import "basefunctions_image.bmx"
'Import "basefunctions_resourcemanager.bmx"

global CHAT_CHANNEL_NONE:int	= 0
global CHAT_CHANNEL_DEBUG:int	= 1
global CHAT_CHANNEL_SYSTEM:int	= 2
global CHAT_CHANNEL_PRIVATE:int	= 4
'normal chat channels
global CHAT_CHANNEL_LOBBY:int	= 8
global CHAT_CHANNEL_INGAME:int	= 16
global CHAT_CHANNEL_OTHER:int	= 32
global CHAT_CHANNEL_GLOBAL:int	= 56	'includes LOBBY, INGAME, OTHER

global CHAT_COMMAND_NONE:int	= 0
global CHAT_COMMAND_WHISPER:int	= 1
global CHAT_COMMAND_SYSTEM:int	= 2


Type TGUIChat extends TGUIObject
	field _defaultTextColor:TColor		= TColor.Create(0,0,0)
	field _defaultHideEntryTime:int		= null
	field _channels:int					= 0		'bitmask of channels the chat listens to
	field guiList:TGUIListBase			= Null
	field guiInput:TGUIInput			= Null
	field guiInputPositionRelative:int	= 0		'is the input is inside the chatbox or absolute
	field guiBackground:TGUIobject		= Null
	field guiInputHistory:TList			= CreateList()

	global antiSpamTimer:int			= 0		'time when again allowed to send
	global antiSpamTime:int				= 100

	Method Create:TGUIChat(x:int,y:int,width:int,height:int, State:string="")
		super.CreateBase(x,y,State,null)

		self.guiList = new TGUIListBase.Create(0,0,width,height,State)
		self.guiList.setOption(GUI_OBJECT_ACCEPTS_DROP, false)
		Self.guiList.autoSortItems = false
		self.guiList.SetAcceptDrop("")
		self.guiList.setParent(self)
		self.guiList.autoScroll = true

		self.guiInput = new TGUIInput.Create(0, height, width, "", 32, State)
		self.guiInput.setParent(self)

		'resize base and move child elements
		self.resize(width,height)

		'by default all chats want to list private messages and system announcements
		self.setListenToChannel(CHAT_CHANNEL_PRIVATE, true)
		self.setListenToChannel(CHAT_CHANNEL_SYSTEM, true)

		'register events
		'- observe text changes in our input field
		EventManager.registerListenerFunction( "guiobject.onChange", self.onInputChange, self.guiInput )
		'- observe wishes to add a new chat entry - listen to all sources
		EventManager.registerListenerMethod( "chat.onAddEntry", self, "onAddEntry" )

		GUIManager.Add( self )

		return self
	End Method

	'returns boolean whether chat listens to a channel
	Method isListeningToChannel:int(channel:int)
		return self._channels & channel
	End Method

	Method setListenToChannel(channel:int, enable:int=TRUE)
		if enable
			self._channels :| channel
		else
			self._channels :& ~channel
		endif
	End Method

	Method SetBackground(guiBackground:TGUIobject)
		'set old background to managed again
		if self.guiBackground then GUIManager.add(self.guiBackground)
		'assign new background
		self.guiBackground = guiBackground
		self.guiBackground.setParent(self)
		'set to unmanaged in all cases
		GUIManager.remove(guiBackground)
	End Method

	Method SetDefaultHideEntryTime(milliseconds:int=null)
		self._defaultHideEntryTime = milliseconds
	End Method

	Method SetDefaultTextColor(color:TColor)
		self._defaultTextColor = color
	End Method

	Function onInputChange:int( triggerEvent:TEventBase )
		local guiInput:TGUIInput = TGUIInput(triggerEvent.getSender())
		if guiInput = Null then return FALSE

		local guiChat:TGUIChat = TGUIChat(guiInput._parent)
		if guiChat = Null then return FALSE

		'emit event : chats should get a new line
		'- step A) is to get what channels we want to announce to
		local sendToChannels:int = guiChat.getChannelsFromText(guiInput.value)
		'- step B) is emitting the event "for all"
		'  (the listeners have to handle if they want or ignore the line
		EventManager.triggerEvent( TEventSimple.Create( "chat.onAddEntry", TData.Create().AddNumber("senderID", Game.playerID).AddNumber("channels", sendToChannels).AddString("text",guiInput.value) , guiChat ) )

		'trigger antiSpam
		guiChat.antiSpamTimer = Millisecs() + guiChat.antiSpamTime

		if guiChat.guiInputHistory.last() <> guiInput.value
			guiChat.guiInputHistory.AddLast(guiInput.value)
		endif



		'reset input field
		guiInput.value = ""
	End Function

	Method onAddEntry:int( triggerEvent:TEventBase )
		local guiChat:TGUIChat = TGUIChat(triggerEvent.getReceiver())
		'if event has a specific receiver and this is not a chat - we are not interested
		if triggerEvent.getReceiver() AND not guiChat then return FALSE
		'found a chat - but it is another chat
		if guiChat and guiChat <> self then return FALSE

		'here we could add code to exlude certain other chat channels
		local sendToChannels:int = triggerEvent.getData().getInt("channels", 0)
		if self.isListeningToChannel(sendToChannels)
			self.AddEntryFromData( triggerEvent.getData() )
		else
			print "onAddEntry - unknown channel, not interested"
		endif
	End Method


	Function getChannelsFromText:int(text:string)
		local sendToChannels:int = 0 'by default send to no channel
		Select getSpecialCommandFromText("/w ronny hi")
			case CHAT_COMMAND_WHISPER
				sendToChannels :| CHAT_CHANNEL_PRIVATE
			default
				sendToChannels :| CHAT_CHANNEL_GLOBAL
		end Select
		return SendToChannels
	End Function

	Function getSpecialCommandFromText:int(text:string)
		text = text.trim()

		if Left( text,1 ) <> "/" then return CHAT_COMMAND_NONE

		local spacePos:int = instr(text, " ")
		local commandString:string = Mid(text, 2, spacePos-2 ).toLower()
		local payload:string = Right(text, text.length -spacePos)

		select commandString
			case "fluestern", "whisper", "w"
				'local spacePos:int = instr(payload, " ")
				'local target:string = Mid(payload, 1, spacePos-1 ).toLower()
				'local message:string = Right(payload, payload.length -spacePos)
				'print "whisper to: " + "-"+target+"-"
				'print "whisper msg:" + message
				return CHAT_COMMAND_WHISPER
			default
				'print "command: -"+commandString+"-"
				'print "payload: -"+payload+"-"
				return CHAT_COMMAND_NONE
		end select

	End Function


	Method AddEntry(entry:TGUIListItem)
		self.guiList.AddItem(entry)
	End Method

	Method AddEntryFromData( data:TData )
		local text:string		= data.getString("text", "")
		local textColor:TColor	= TColor( data.get("textColor") )
		local senderID:int		= data.getInt("senderID", 0)
		local senderName:string	= ""
		local senderColor:TColor= Null

		if Game.isPlayer(senderID)
			senderName	= Game.Players[senderID].Name
			senderColor	= Game.Players[senderID].color
			if not textColor then textColor = self._defaultTextColor
		else
			senderName	= "SYSTEM"
			senderColor	= TColor.Create(255,100,100)
			textColor	= TColor.Create(255,100,100)
		endif


		'finally add to the chat box
		local entry:TGUIChatEntry = new TGUIChatEntry.CreateSimple(text, textColor, senderName, senderColor, null )
		'if the default is "null" then no hiding will take place
		entry.SetShowtime( self._defaultHideEntryTime )
		self.AddEntry( entry )
	End Method

	Method SetPadding:int(top:int,left:int,bottom:int,right:int)
		self.padding.setTLBR(top,left,bottom,right)
		self.resize()
	End Method

	'override resize and add minSize-support
	Method Resize(w:float=Null,h:float=Null)
		super.Resize(w,h)

		local subtractInputHeight:float = 0.0
		'move and resize input field to the bottom
		if self.guiInput and not self.guiInput.getOption(GUI_OBJECT_POSITIONABSOLUTE)
			self.guiInput.resize(self.getContentScreenWidth(),null)
			self.guiInput.rect.position.setXY(0, self.getContentScreenHeight() - self.guiInput.rect.getH())
			subtractInputHeight = self.guiInput.rect.getH()
		endif

		'move and resize the listbox (subtract input if needed)
		if self.guiList then self.guiList.resize(self.getContentScreenWidth(), self.getContentScreenHeight() - subtractInputHeight)

		if self.guiBackground
			'move background by negative padding values ( -> ignore padding)
			self.guiBackground.rect.position.setXY(-self.padding.getLeft(), -self.padding.getTop())

			'background covers whole area, so resize it
			self.guiBackground.resize(self.rect.getW(), self.rect.getH())
		endif

	End Method

	'override default update-method
	Method Update:int()
		super.Update()

		'show items again if somone hovers over the list (-> reset timer)
		if self.guiList._mouseOverArea
			for local entry:TGuiObject = eachin self.guiList.entries
				entry.show()
			next
		endif
	End Method

	Method Draw()
		if self.guiBackground
			self.guiBackground.Draw()
		endif
		'Super.Draw()
	End Method

End Type

Type TGUIChatEntry extends TGUIListItem
	field paddingBottom:int		= 5

	Method CreateSimple:TGUIChatEntry(text:string, textColor:TColor, senderName:string, senderColor:TColor, lifetime:int=null)
		self.Create(text)
		self.SetLifetime(lifeTime)
		self.SetShowtime(lifeTime)
		self.SetSender(senderName, senderColor)
		self.SetLabel(text,textColor)

		return self
	End Method

    Method Create:TGUIChatEntry(text:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		'no "super.Create..." as we do not need events and dragable and...
   		super.CreateBase(x,y,"",null)

		self.Resize( width, height )
		self.label = text

		self.setLifetime( 1000 )
		self.setShowtime( 1000 )

		GUIManager.add(self)

		return self
	End Method

	Method getDimension:TPoint()
		local move:TPoint = TPoint.Create(0,0)
		if self.Data.getString("senderName",null)
			local senderColor:TColor = TColor(self.Data.get("senderColor"))
			if not senderColor then senderColor = TColor.Create(0,0,0)
			move = Assets.fonts.baseFontBold.drawStyled(self.Data.getString("senderName")+":", self.getScreenX(), self.getScreenY(), senderColor.r, senderColor.g, senderColor.b, 2, 0)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		endif
		'available width is parentsDimension minus startingpoint
		local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(self.getParent("tguiscrollablepanel"))
		local maxWidth:int = parentPanel.getContentScreenWidth()-self.rect.getX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		local dimension:TPoint = Assets.fonts.baseFont.drawBlock(self.label, self.getScreenX()+move.x, self.getScreenY()+move.y, maxWidth-move.X, maxHeight, 0, 255, 255, 255, 0, 2, 0)

		'add padding
		dimension.moveXY(0, self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		if self.rect.getW() <> dimension.getX() OR self.rect.getH() <> dimension.getY()
			'resize item
			self.Resize(dimension.getX(), dimension.getY())
			'recalculate item positions and scroll limits
'			local list:TGUIListBase = TGUIListBase(self.getParent("tguilistbase"))
'			if list then list.RecalculateElements()
		endif

		return dimension
	End Method

	Method SetSender:int(senderName:string=Null, senderColor:TColor=Null)
		if senderName then self.Data.AddString("senderName", senderName)
		if senderColor then self.Data.Add("senderColor", senderColor)
	End Method

	Method getParentWidth:float(parentClassName:string="toplevelparent")
		if not self._parent then return self.rect.getW()
		return self.getParent(parentClassName).rect.getW()
	End Method

	Method getParentHeight:float(parentClassName:string="toplevelparent")
		if not self._parent then return self.rect.getH()
		return self.getParent(parentClassName).rect.getH()
	End Method

	Method Draw:int()
		self.getParent("tguilistbase").RestrictViewPort()

		if self.showtime <> Null then setAlpha float(self.showtime-Millisecs())/500.0
		'available width is parentsDimension minus startingpoint
		local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(self.getParent("tguiscrollablepanel"))
		local maxWidth:int = parentPanel.getContentScreenWidth()-self.rect.getX()

		'local maxWidth:int = self.getParentWidth("tguiscrollablepanel")-self.rect.getX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		local move:TPoint = TPoint.Create(0,0)
		if self.Data.getString("senderName",null)
			local senderColor:TColor = TColor(self.Data.get("senderColor"))
			if not senderColor then senderColor = TColor.Create(0,0,0)
			move = Assets.fonts.baseFontBold.drawStyled(self.Data.getString("senderName", "")+":", self.getScreenX(), self.getScreenY(), senderColor.r, senderColor.g, senderColor.b, 2, 1)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		endif
		Assets.fonts.baseFont.drawBlock(self.label, self.getScreenX()+move.x, self.getScreenY()+move.y, maxWidth-move.X, maxHeight, 0, self.labelColor.r, self.labelColor.g, self.labelColor.b, 0, 2, 1, 0.5)

		setAlpha 1.0

		self.getParent("tguilistbase").ResetViewPort()
	End Method

End Type


'create a custom type so we can check for doublettes on add
Type TGUIGameList Extends TGUISelectList

    Method Create:TGUIGameList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		super.Create(x,y,width,height, State)

		return self
	end Method

	'override default
	Method RegisterListeners:int()
		'we want to know about clicks
		EventManager.registerListenerMethod( "guiobject.onClick",	self, "onClickOnEntry", "TGUIGameEntry" )
	End Method

	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		local entry:TGUIGameEntry = TGUIGameEntry( triggerEvent.getSender() )
		if not entry then return FALSE

		return super.onClickOnEntry(triggerEvent)
	End Method

	Method AddItem:int(item:TGUIobject, extra:object=null)
		for local olditem:TGUIListItem = eachin self.entries
			if TGUIGameEntry(item) and TGUIGameEntry(item).label = olditem.label
				'refresh lifetime
				olditem.setLifeTime(olditem.initialLifeTime)
				'unset the new one
				item.remove()
				return FALSE
			endif
		next
		return Super.AddItem(item, extra)
	End Method
End Type

Type TGUIGameEntry extends TGUISelectListItem
	field paddingBottom:int		= 3
	field paddingTop:int		= 2

	Method CreateSimple:TGUIGameEntry(_hostIP:string, _hostPort:int, _hostName:string="", gameTitle:string="", slotsUsed:int, slotsMax:int)
		'make it "unique" enough
		self.Create(_hostIP+":"+_hostPort)

		self.data.AddString("hostIP", _hostIP)
		self.data.AddNumber("hostPort", _hostPort)
		self.data.AddString("hostName", _hostName)
		self.data.AddString("gameTitle", gametitle)
		self.data.AddNumber("slotsUsed", slotsUsed)
		self.data.AddNumber("slotsMax", slotsMax)

		return self
	End Method

    Method Create:TGUIGameEntry(text:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		'no "super.Create..." as we do not need events and dragable and...
   		super.CreateBase(x,y,"",null)

		self.SetLifetime(30000) '30 seconds
		self.SetLabel(":D", TColor.Create(0,0,0))

		self.Resize( width, height )

		GUIManager.add(self)

		return self
	End Method

	Method getDimension:TPoint()
		'available width is parentsDimension minus startingpoint
		local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(self.getParent("tguiscrollablepanel"))
		local maxWidth:int = parentPanel.getContentScreenWidth()-self.rect.getX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		local text:string = self.Data.getString("gameTitle","#unknowngametitle#")+" by "+ self.Data.getString("hostName","#unknownhostname#") + " ("+self.Data.getInt("slotsUsed",1)+"/"+self.Data.getInt("slotsMax",4)
		local dimension:TPoint = Assets.fonts.baseFont.drawBlock(text, self.getScreenX(), self.getScreenY(), maxWidth, maxHeight, 0, 255, 255, 255, 0, 2, 0)

		'add padding
		dimension.moveXY(0, self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		if self.rect.getW() <> dimension.getX() OR self.rect.getH() <> dimension.getY()
			'resize item
			self.Resize(dimension.getX(), dimension.getY())
		endif

		return dimension
	End Method



	Method Draw:int()
		self.getParent("tguigamelist").RestrictViewPort()

		if self.showtime <> Null then setAlpha float(self.showtime-Millisecs())/500.0

		'draw highlight-background etc
		Super.Draw()

		'draw text
		local move:TPoint = TPoint.Create(0, self.paddingTop)
		local text:string = ""
		local textColor:TColor = null
		local textDim:TPoint = null
		'line: title by hostname (slotsused/slotsmax)

		text 		= self.Data.getString("gameTitle","#unknowngametitle#")
		textColor	= TColor(self.Data.get("gameTitleColor", TColor.Create(150,80,50)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, self.getScreenX() + move.x, self.getScreenY() + move.y, textColor.r, textColor.g, textColor.b, 2, 1,0.5)
		move.moveXY(textDim.x,1)

		text 		= " by "+self.Data.getString("hostName","#unknownhostname#")
		textColor	= TColor(self.Data.get("hostNameColor", TColor.Create(50,50,150)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, self.getScreenX() + move.x, self.getScreenY() + move.y, textColor.r, textColor.g, textColor.b)
		move.moveXY(textDim.x,0)

		text 		= " ("+self.Data.getInt("slotsUsed",1)+"/"++self.Data.getInt("slotsMax",4)+")"
		textColor	= TColor(self.Data.get("hostNameColor", TColor.Create(0,0,0)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, self.getScreenX() + move.x, self.getScreenY() + move.y, textColor.r, textColor.g, textColor.b)
		move.moveXY(textDim.x,0)

		setAlpha 1.0

		self.getParent("tguigamelist").ResetViewPort()
	End Method

End Type


Type THotspot
	Field area:TRectangle			= TRectangle.Create(0,0,0,0)
	Field name:string				= ""
	Field tooltip:TTooltip			= null
	Field tooltipText:string		= ""
	Field tooltipDescription:string	= ""
	Field hovered:int				= FALSE

	Method Create:THotSpot(name:string, x:int,y:int,w:int,h:int)
		self.area = TRectangle.Create(x,y,w,h)
		self.name = name
		return self
	End Method

	Method setTooltipText( text:string="", description:string="" )
		self.tooltipText		= text
		self.tooltipDescription = description
	End Method

	Method Update:int(offsetX:int=0,offsetY:int=0)
		'update tooltip
		'handle clicks -> send events so eg can send figure to it

		local adjustedArea:TRectangle = area.copy()
		adjustedArea.position.moveXY(offsetX, offsetY)

		if adjustedArea.containsXY(MOUSEMANAGER.x, MOUSEMANAGER.y)
			hovered = TRUE
			if MOUSEMANAGER.isClicked(1)
				EventManager.triggerEvent( TEventSimple.Create("hotspot.onClick", TData.Create() , self ) )
			endif
		else
			hovered = FALSE
		endif

		if hovered
			if tooltip
				tooltip.Hover()
			elseif tooltipText<>""
				tooltip = TTooltip.Create(tooltipText, tooltipDescription, 100, 140, 0, 0)
				tooltip.enabled = true
			endif
		endif

		If tooltip AND tooltip.enabled
			tooltip.pos.SetXY( adjustedArea.getX() + adjustedArea.getW()/2 - tooltip.GetWidth()/2, adjustedArea.getY() - tooltip.GetHeight())
			tooltip.Update( App.Timer.getDeltaTime() )
			'delete old tooltips
			if tooltip.lifetime < 0 then tooltip = null
		EndIf

	End Method

	Method Draw:int(offsetX:int=0,offsetY:int=0)
		if tooltip then tooltip.draw()
rem
		'draw tooltip
		SetAlpha 0.5
		DrawRect(offsetX + area.getX(), offsetY + area.getY(), area.getW(), area.getH() )
		SetAlpha 1.0
endrem
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
  	Local tmpobj:TSaveFile = New TSaveFile
	Return tmpobj
  End Function

  Method InitSave()
	self.xml		= new TXmlHelper
	self.xml.file	= TxmlDoc.newDoc("1.0")
	Self.xml.root 	= TxmlNode.newNode("tvtsavegame")
	self.xml.file.setRootElement(self.xml.root)
    Self.Nodes[0]	= xml.root
	Self.lastNode	= xml.root
  End Method

	Method InitLoad(filename:String="save.xml", zipped:Byte=0)
		self.xml		= new TXmlHelper
		self.xml.file	= TxmlDoc.parseFile(filename)
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

	'Summary: loads an object from a XMLstream
	Method LoadObject:Object(obj:Object, _handleNodefunc(_obj:Object, _node:txmlnode))
print "implement LoadObject"
return null
rem
		Local NODE:txmlNode = Self.NODE.FirstChild()
		Local nodevalue:String
		While NODE <> Null
			nodevalue = ""
			If NODE.hasAttribute("var", False) Then nodevalue = Self.NODE.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(obj)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("sl") <> "no" And Upper(t.name()) = NODE.name
					t.Set(obj, nodevalue)
				EndIf
			Next
			Self.NODE = Self.NODE.nextSibling()
			If _handleNodefunc <> Null Then _handleNodefunc(obj, NODE)
		Wend
		Return obj
endrem
	End Method
End Type
Global LoadSaveFile:TSaveFile = TSaveFile.Create()



Type TPlannerList
	Field openState:int				= 0 '0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field currentGenre:Int			=-1
	Field enabled:Int				= 0
	Field Pos:TPoint 				= TPoint.Create()

	Method getOpen:Int()
		return self.openState
	End Method
End Type

'the programmelist shown in the programmeplaner
Type TgfxProgrammelist extends TPlannerList
	Field gfxmovies:TGW_Sprites
	Field gfxtape:TGW_Sprites
	Field gfxtapeseries:TGW_Sprites
	Field gfxtapeepisodes:TGW_Sprites
	Field gfxepisodes:TGW_Sprites
	Field maxGenres:int = 1

	Field currentseries:TProgramme	= Null

	Function Create:TgfxProgrammelist(x:Int, y:Int, maxGenres:int)
		Local Obj:TgfxProgrammelist =New TgfxProgrammelist
		Obj.gfxmovies		= Assets.getSprite("pp_menu_werbung")   'Assets.getSprite("") '  = gfxmovies
		Obj.gfxtape			= Assets.getSprite("pp_cassettes_movies")
		Obj.gfxtapeseries	= Assets.getSprite("pp_cassettes_series")
		Obj.gfxtapeepisodes	= Assets.getSprite("pp_cassettes_episodes")
		Obj.gfxepisodes		= Assets.getSprite("episodes")
		Obj.Pos.SetXY(x, y)
		Obj.maxGenres = maxGenres
		Return Obj
	End Function

	Method Draw:Int(createProgrammeblock:Int=1)
		if not enabled then return 0

		If self.openState >=3 Then gfxepisodes.Draw(Pos.x - gfxepisodes.w, Pos.y + gfxmovies.h - 4)

		If self.openState >=2
			gfxmovies.Draw(Pos.x - gfxmovies.w + 14, Pos.y)
			If currentgenre >= 0 	Then DrawTapes(currentgenre, createProgrammeblock)
			If currentSeries<> Null	Then DrawEpisodeTapes(currentseries, createProgrammeblock)
		EndIf
		If self.openState >=1
			local currY:float = Pos.y
			Assets.getSprite("genres_top").draw(Pos.x,currY)
			currY:+Assets.getSprite("genres_top").h

'			gfxgenres.Draw(Pos.x, Pos.y)
			For local genres:int = 0 To self.maxGenres-1 		'21 genres
				local lineHeight:int =0
				local entryNum:string = (genres mod 2)
				if genres = 0 then entryNum = "First"
				Assets.getSprite("genres_entry"+entryNum).draw(Pos.x,currY)
				lineHeight = Assets.getSprite("genres_entry"+entryNum).h

				Local genrecount:Int = TProgramme.CountGenre(genres, Game.Players[Game.playerID].ProgrammeCollection.List)

				If genrecount > 0
					Assets.fonts.baseFont.drawBlock(GetLocale("MOVIE_GENRE_" + genres) + " (" + TProgramme.CountGenre(genres, Game.Players[Game.playerID].ProgrammeCollection.List) + ")", Pos.x + 4, Pos.y + lineHeight*genres +5, 114, 16, 0)
					SetAlpha 0.6; SetColor 0, 255, 0
					'takes 20% of fps...
					For Local i:Int = 0 To genrecount -1
						DrawLine(Pos.x + 121 + i * 2, Pos.y + 4 + lineHeight*genres - 1, Pos.x + 121 + i * 2, Pos.y + 17 + lineHeight*genres - 1)
					Next
				else
					SetAlpha 0.3; SetColor 0, 0, 0
					Assets.fonts.baseFont.drawBlock(GetLocale("MOVIE_GENRE_" + genres), Pos.x + 4, Pos.y + lineHeight*genres +5, 114, 16, 0)
				EndIf
				SetAlpha 1.0
				SetColor 255, 255, 255
				currY:+ lineHeight
			Next
			Assets.getSprite("genres_bottom").draw(Pos.x,currY)
		EndIf
	End Method

	Method DrawTapes:Int(genre:Int, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxmovies.w + 25
		Local locy:Int = Pos.y+7 -19

		local font:TBitmapFont = Assets.getFont("Font10")
		For Local movie:TProgramme = EachIn Game.Players[Game.playerID].ProgrammeCollection.List 'all programmes of one player
			If movie.genre = genre
				locy :+ 19
				If movie.isMovie()
					gfxtape.Draw(locx, locy)
				else
					gfxtapeseries.Draw(locx, locy)
				endif
				font.drawBlock(movie.title, locx + 13, locy + 5, 139, 16, 0, 0, 0, 0, True)
				If functions.MouseIn( locx, locy, gfxtape.w, gfxtape.h)
					SetAlpha 0.2;
					If movie.isMovie()
						DrawRect(locx, locy, gfxtape.w, gfxtape.h)
					else
						DrawRect(locx, locy, gfxtapeseries.w, gfxtapeseries.h)
					endif
					SetAlpha 1.0
					If Not MOUSEMANAGER.IsHit(1) then movie.ShowSheet(30,20)
				EndIf
			EndIf
		Next
	End Method

	Method UpdateTapes:Int(genre:Int, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxmovies.w + 25
		Local locy:Int = Pos.y+7 -19

		For Local movie:TProgramme = EachIn Game.Players[Game.playerID].ProgrammeCollection.List 'all programmes of one player
			If movie.genre = genre
				locy :+ 19
				If MOUSEMANAGER.IsHit(1) AND functions.MouseIn( locx, locy, gfxtape.w, gfxtape.h)
					Game.cursorstate = 1
					If createProgrammeblock
						If movie.isMovie()
							TProgrammeBlock.CreateDragged(movie)
							SetOpen(0)
						Else
							currentseries = movie
							SetOpen(3)
						EndIf
						MOUSEMANAGER.resetKey(1)
					Else
						'create a dragged block
						new TGUIProgrammeCoverBlock.CreateWithProgramme(movie).drag()

						SetOpen(0)
					EndIf
					Exit 'exit for local movie
				EndIf
			EndIf
		Next
	End Method

	Method DrawEpisodeTapes:Int(series:TProgramme, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxepisodes.w + 8
		Local locy:Int = Pos.y + 5 + gfxmovies.h - 4 -12 '-4 as displacement for displaced the background
		local font:TBitmapFont = Assets.getFont("Default", 8)

		For Local i:Int = 0 To series.episodes.Count()-1
			Local programme:TProgramme = TProgramme(series.episodes.ValueAtIndex(i))   'all programmes of one player
			If programme <> Null
				locy :+ 12
				SetAlpha 1.0
				gfxtapeepisodes.Draw(locx, locy)
				font.drawBlock("(" + programme.episode + "/" + series.episodes.count() + ") " + programme.title, locx + 10, locy + 1, 85, 12, 0, 0, 0, 0, True)
				If functions.IsIn(MouseManager.x,MouseManager.y, locx,locy, gfxtapeepisodes.w, gfxtapeepisodes.h)
					Game.cursorstate = 1
					SetAlpha 0.2;DrawRect(locx, locy, gfxtapeepisodes.w, gfxtapeepisodes.h) ;SetAlpha 1.0
					If Not MOUSEMANAGER.IsHit(1) then programme.ShowSheet(30,20, -1, series)
				EndIf
			EndIf
		Next
	End Method

	Method UpdateEpisodeTapes:Int(series:TProgramme, createProgrammeblock:Int=1)
		'Local genres:Int
		Local tapecount:Int = 0
		Local locx:Int = Pos.x - gfxepisodes.w + 8
		Local locy:Int = Pos.y + 5 + gfxmovies.h - 4 -12 '-4 as displacement for displaced the background
		For local programme:TProgramme = eachin series.episodes
			If programme <> Null
				locy :+ 12
				tapecount :+ 1
				If MOUSEMANAGER.IsHit(1) AND functions.IsIn(MouseManager.x,MouseManager.y, locx,locy, gfxtapeepisodes.w, gfxtapeepisodes.h)
					TProgrammeBlock.CreateDragged(programme)
					SetOpen(0)
					MOUSEMANAGER.resetKey(1)
				EndIf
			EndIf
		Next
	End Method

	Method Update(createProgrammeblock:Int=1)
		If enabled
			If MOUSEMANAGER.IsHit(2)
				SetOpen(0)
				MOUSEMANAGER.resetKey(2)
			EndIf
			If MOUSEMANAGER.IsHit(1) AND functions.IsIn(MouseManager.x,MouseManager.y, Pos.x,Pos.y, Assets.getSprite("genres_entry0").w, Assets.getSprite("genres_entry0").h*self.MaxGenres)
				SetOpen(2)
				currentgenre = Floor((MouseManager.y - Pos.y - 1) / Assets.getSprite("genres_entry0").h)
			EndIf

			If self.openState >=2
				If currentgenre >= 0	Then UpdateTapes(currentgenre, createProgrammeblock)
				If currentSeries<> Null	Then UpdateEpisodeTapes(currentseries, createProgrammeblock)
			EndIf
		EndIf
	End Method

	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		if newState <= 1 then currentgenre=-1
		if newState <= 2 then currentseries=Null
		If newState = 0 Then enabled = 0;currentseries=Null;currentgenre=-1 else enabled = 1

		self.openState = newState
	End Method
End Type

'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist extends TPlannerList
	Field gfxcontracts:TGW_Sprites
	Field gfxtape:TGW_Sprites

	Function Create:TgfxContractlist(x:Int, y:Int)
		Local NewObject:TgfxContractlist =New TgfxContractlist
		NewObject.gfxcontracts	= Assets.getSprite("pp_menu_werbung")
		NewObject.gfxtape 		= Assets.getSprite("pp_cassettes_movies")
		NewObject.Pos.SetXY(x, y)
		Return NewObject
	End Function

	Method Draw:Int()
		If enabled And self.openState >= 1
			gfxcontracts.Draw(Pos.x - gfxcontracts.w, Pos.y)
			DrawTapes()
		EndIf
	End Method

	Method DrawTapes:Int()
		local boxHeight:int			= gfxtape.h + 1
		Local locx:Int 				= Pos.x - gfxcontracts.w + 10
		Local locy:Int 				= Pos.y+7 - boxHeight
		local font:TBitmapFont 		= Assets.getFont("Default", 10)
		For Local contract:TContract = EachIn Game.Players[Game.playerID].ProgrammeCollection.ContractList 'all contracts of one player
			locy :+ boxHeight
			gfxtape.Draw(locx, locy)

			font.drawBlock(contract.contractBase.title, locx + 13,locy + 3, 139,16,0,0,0,0,True)
			If functions.IsIn(MouseManager.x,MouseManager.y, locx,locy, gfxtape.w, gfxtape.h)
				Game.cursorstate = 1
				SetAlpha 0.2;DrawRect(locx, locy, gfxtape.w, gfxtape.h) ;SetAlpha 1.0
				If MOUSEMANAGER.IsHit(1)
					TAdBlock.CreateDragged(contract)
					self.SetOpen(0)
					MOUSEMANAGER.resetKey(1)
				Else
					contract.ShowSheet(30,20)
				EndIf
			EndIf
		Next
	End Method

	Method Update()
		If enabled
			If MOUSEMANAGER.IsHit(2)
				SetOpen(0)
				MOUSEMANAGER.resetKey(2)
			endif
			Draw()
		EndIf
	End Method

	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 else enabled = 1
		self.openState = newState
	End Method
End Type



Type TAudienceQuotes
  Field title:String
  Field audience:Int
  Field audiencepercentage:Int
  Field playerID:Int
  Field sendhour:Int
  Field sendminute:Int
  Field senddate:Int
  Global List:TList = CreateList()  ' :TObjectList = TObjectList.Create(1000) {saveload = "nosave"}
  Global sheet:TTooltip = Null {saveload = "nosave"}


	Function Load:TAudienceQuotes(pnode:TxmlNode)
print "implement Load:TAudienceQuotes"
return null
rem
  		Local audience:TAudienceQuotes = New TAudienceQuotes
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(audience)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal") And Upper(t.name()) = NODE.name
					t.Set(audience, nodevalue)
				EndIf
			Next
			NODE = NODE.nextSibling()
		Wend
		TAudienceQuotes.List.AddLast(audience)
		Return audience
endrem
	End Function

	Function LoadAll()
		TAudienceQuotes.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local NODE:TxmlNode = EachIn Children
			If NODE.getName() = "AUDIENCEQUOTE"
				TAudienceQuotes.Load(NODE)
			End If
		Next
		PrintDebug ("TAudienceQuotes.LoadAll()", "AudienceQuotes eingeladen", DEBUG_SAVELOAD)
	End Function

	Function SaveAll()
		'TFinancials.List.Sort()
		LoadSaveFile.xmlBeginNode("ALLAUDIENCEQUOTES")
			For Local i:Int = 0 To TAudienceQuotes.List.Count()-1
'				Local audience:TAudienceQuotes = TAudienceQuotes(TAudienceQuotes.List.Items[i] )
				Local audience:TAudienceQuotes = TAudienceQuotes(TAudienceQuotes.List.ValueAtIndex(i))
				If audience<> Null Then audience.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("AUDIENCEQUOTE")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.get(Self)))
				EndIf
			Next
		LoadSaveFile.xmlCloseNode()
	End Method


	Function Create:TAudienceQuotes(title:String, audience:Double, sendhour:Int, sendminute:Int,senddate:Int, playerID:Int)
		Local obj:TAudienceQuotes = New TAudienceQuotes
		obj.title    = title
		obj.audience = audience
		obj.audiencepercentage = 0
		if Game.getMaxAudience(playerID) > 0 then obj.audiencepercentage = Floor( audience*1000 / Game.getMaxAudience(playerID) )

		obj.sendhour = sendhour
		obj.sendminute = sendminute
		obj.senddate = senddate
		obj.playerID = playerID

		List.AddLast(obj)
		Return obj
	End Function

  Method ShowSheet(x:Int, y:Int)
	If Sheet = Null
	  Sheet = TTooltip.Create(title, getLocale("AUDIENCE_RATING") + ": " + functions.convertValue(String(audience), 2, 0) + " (MA: " + audiencepercentage + "%)", x, y, 200, 20)
    Else
	  Sheet.title = title
	  Sheet.text = getLocale("AUDIENCE_RATING")+": "+functions.convertValue(String(audience), 2, 0)+" (MA: "+(audiencepercentage/10)+"%)"
	  Sheet.enabled = 1
	  Sheet.pos.setXY(x,y)
	  Sheet.width = 0
	  Sheet.height = 0
	  Sheet.Hover()
	End If
  End Method

	Function getAudienceOfDate:TAudienceQuotes(playerID:int, day:Int, hour:Int, minute:Int)
		Local locObject:TAudienceQuotes
		For Local obj:TAudienceQuotes = EachIn TAudienceQuotes.List
			If obj.playerID = playerID And obj.senddate = day And obj.sendhour = hour And obj.sendminute = minute Then Return obj
  		Next
		Return Null
	End Function

  Function getAudienceOfDay:TAudienceQuotes[](playerID:Int, day:Int)
    Local locObjects:TAudienceQuotes[]
	Local locObject:TAudienceQuotes

	For Local i:Int = 0 To TAudienceQuotes.List.Count()-1
	  locObject = TAudienceQuotes(TAudienceQuotes.List.ValueAtIndex(i))
	  If locObject <> Null
        If locObject.playerID = playerID And locObject.senddate = day
		  LocObjects=LocObjects[..LocObjects.length+1]
		  LocObjects[LocObjects.length-1] = locObject
        End If
	  EndIf
	Next
	Return locObjects
  End Function
End Type

'tooltips containing headline and text, updated and drawn by Tinterface
'extends TRenderableChild - could get attached to sprites
Type TTooltip extends TRenderableChild
  Field lifetime:float = 0.1
  Field startLifetime:float = 1.0
  Field fadeTime:float= 0.20
  Field title:String
  Field text:String
  Field oldtitle:String
  Field width:Int
  Field height:Int
  Field Image:TImage = Null
  Field DirtyImage:Byte =1
  Field tooltipimage:Int=-1
  Field TitleBGtype:Byte = 0
  Field enabled:Int = 0

  Global TooltipHeader:TGW_Sprites
  Global ToolTipIcons:TGW_Sprites

  Global UseFontBold:TBitmapFont
  Global UseFont:TBitmapFont
  Global List:TList = CreateList()
  Global startFadeTime:float = 0.2 '200ms after no-hover - fade away

  Global imgCacheEnabled:int = TRUE

	Function Create:TTooltip(title:String = "", text:String = "unknown", x:Int = 0, y:Int = 0, width:Int = -1, Height:Int = -1, lifetime:Int = 300)
		Local tooltip:TTooltip = New TTooltip
		tooltip.title			= title
		tooltip.oldtitle		= title
		tooltip.text			= text
		tooltip.pos.setXY(x,y)
		tooltip.tooltipimage	= -1
		tooltip.width			= width
		tooltip.height			= height
		tooltip.startlifetime	= float(lifetime) / 1000.0
		tooltip.startFadeTime	= Min(tooltip.startlifetime/2.0, 0.2) '0.5 * tooltip.startlifetime
		tooltip.Hover()
		If not List Then List	= CreateList()
		List.AddLast(tooltip)
		SortList List
		'Print "Tooltip created:" + title + "ListCount: " + List.Count()

		Return tooltip
	End Function

	Method Hover()
		self.lifetime = self.startlifetime
		self.fadeTime = self.startFadeTime
	End Method

	Method Update:Int(deltaTime:float=1.0)
'		print "update "+self.lifetime + " " + deltatime
		self.lifetime :- deltaTime

		'start fading if lifetime is running out (lower than fade time)
		if self.lifetime <= self.startFadeTime
			self.fadeTime :- deltaTime
			self.fadeTime :* 0.8 'speed up fade
		endif

		If self.lifetime <= 0 ' And enabled 'enabled - as pause sign?
			Self.Image		= Null
			Self.enabled	= False
			self.List.remove(Self)
		EndIf
	End Method

	Method getWidth:Int()
		local txtWidth:int = self.useFontBold.getWidth(title)+6
		If tooltipimage >=0 Then txtwidth:+ TTooltip.ToolTipIcons.framew+ 2
		If txtwidth < self.useFont.getWidth(text)+6 Then txtwidth = self.useFont.getWidth(text)+6
		Return txtwidth
	End Method

	Method getHeight:int()
		If not DirtyImage and Image and imgCacheEnabled then return image.height

		Local boxHeight:Int	= height
		if height <= 0
			boxHeight = TooltipHeader.h
			If Len(text)>1 Then boxHeight :+ (UseFont.getHeight(text)+8)
			If tooltipimage >= 0 Then boxHeight :+ 2
		endif

		return boxHeight
	End Method

	Method DrawShadow(_width:float, _height:float)
		SetColor 0, 0, 0
		SetAlpha self.getFadeAmount()-0.8
		DrawRect(self.pos.x+2,self.pos.y+2,_width,_height)

		SetAlpha self.getFadeAmount()-0.5
		DrawRect(self.pos.x+1,self.pos.y+1,_width,_height)
	End Method

	Method getFadeAmount:float()
		return Float(100*self.fadeTime / self.startFadeTime) / 100.0
	End Method

	Method Draw:Int(tweenValue:float=1.0)
		If Not enabled Then Return 0
rem
		DrawRect(200,50,200, 20)
		SetColor 0,0,0
		DrawText("x:"+self.pos.x + " y:" +self.pos.y, 200,50)
		SetColor 255,255,255
endrem

		If Title <> oldTitle then self.DirtyImage = True

		If Self.DirtyImage = True Or Self.Image = Null OR not self.imgCacheEnabled
			Local boxWidth:Int		= self.width
			Local boxHeight:Int		= Self.height

			'auto width calculation
			If width <= 0
				'width from title + spacing
				boxWidth = self.UseFontBold.getWidth(title)+6
				'add icon to width
				If tooltipimage >=0 Then boxWidth:+ TTooltip.ToolTipIcons.framew+ 2
				'compare with tex
				boxWidth = max(self.UseFont.getWidth(text)+6, boxWidth)
				boxWidth :+ 4 'extra spacing
			EndIf

			'auto height calculation
			if height <= 0
				boxHeight = Self.TooltipHeader.h
				If Len(text)>1 Then boxHeight :+ (self.UseFont.getHeight(text)+8)
				If tooltipimage >= 0 Then boxHeight :+ 2
			endif
			self.DrawShadow(boxWidth,boxHeight)

			SetAlpha self.getFadeAmount()
			DrawRect(self.pos.x,self.pos.y, boxWidth,boxHeight)

			SetColor 255,255,255
			DrawRect(self.pos.x+1,self.pos.y+1,boxWidth-2,boxHeight-2)

			If TitleBGtype = 0 Then SetColor 250,250,250
			If TitleBGtype = 1 Then SetColor 200,250,200
			If TitleBGtype = 2 Then SetColor 250,150,150
			If TitleBGtype = 3 Then SetColor 200,200,250

			Self.TooltipHeader.TileDraw(self.pos.x+1,self.pos.y+1, boxWidth-2, Self.TooltipHeader.h)
			SetColor 255,255,255
			local displaceX:float = 0.0
			If tooltipimage >=0
				TTooltip.ToolTipIcons.Draw(self.pos.x+1,self.pos.y+1, tooltipimage)
				displaceX = TTooltip.ToolTipIcons.framew
			endif

			SetAlpha self.getFadeAmount()
			'caption
			self.useFontBold.drawStyled(title, self.pos.x+5+displaceX, self.pos.y+Self.TooltipHeader.h/2 - self.useFontBold.getHeight("ABC")/2 +2 , 50,50,50, 2, 1, 0.1)
			SetColor 90,90,90
			'text
			If text <> "" Then self.Usefont.draw(text, self.pos.x+5,self.pos.y+Self.TooltipHeader.h + 7)

			'limit to visible areas
			self.pos.x = Max(21, Min(self.pos.x, 759 - boxWidth))
			'limit to screen too
			self.pos.y = Max(10, Min(self.pos.y, 600 - boxHeight))

			If self.imgCacheEnabled 'And lifetime = startlifetime
				Image = TImage.Create(boxWidth, boxHeight, 1, 0, 255, 0, 255)
				image.pixmaps[0] = VirtualGrabPixmap(self.pos.x, self.pos.y, boxWidth, boxHeight)
				DirtyImage = False
			EndIf
			oldTitle = title
			SetColor 255, 255, 255
			SetAlpha 1.0
		Else 'not dirty
			self.DrawShadow(ImageWidth(image),ImageHeight(image))
			SetAlpha self.getFadeAmount()
			SetColor 255,255,255
			DrawImage(image, self.pos.x, self.pos.y)
			SetAlpha 1.0
		EndIf
	End Method
End Type


	Function DrawDialog(gfx_Rect:TGW_SpritePack, x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TGW_Sprites = gfx_Rect.getSprite(DialogStart)
		If DialogStart = "StartLeftDown" Then dx = x - 48;dy = y + (Height - DialogSprite.h)/2 + DialogStartMove;width:-48
		If DialogStart = "StartRightDown" Then dx = x + width - 12;dy = y + (Height - DialogSprite.h)/2 + DialogStartMove;width:-48
		If DialogStart = "StartDownRight" Then dx = x + (width - DialogSprite.w)/2 + DialogStartMove;dy = y + Height - 12;Height:-53
		If DialogStart = "StartDownLeft" Then dx = x + (width - DialogSprite.w)/2 + DialogStartMove;dy = y + Height - 12;Height:-53

		DrawGFXRect(gfx_Rect,x,y,width,height,"") ' "" = no nameBase

		DialogSprite.Draw(dx, dy)
		If DialogText <> "" then DialogFont.drawBlock(DialogText, x + 10, y + 10, width - 16, Height - 16, 0, 0, 0, 0)
	End Function

	'draws a rounded rectangle (blue border) with alphashadow
	Function DrawGFXRect(gfx_Rect:TGW_SpritePack, x:Int, y:Int, width:Int, Height:Int, nameBase:string="gfx_gui_rect_")
		gfx_Rect.getSprite(nameBase+"TopLeft").Draw(x, y)
		gfx_Rect.getSprite(nameBase+"TopRight").Draw(x + width, y,-1,0,1)
		gfx_Rect.getSprite(nameBase+"BottomLeft").Draw(x, y + Height, -1,1)
		gfx_Rect.getSprite(nameBase+"BottomRight").Draw(x + width, y + Height, -1, 1,1)

		gfx_Rect.getSprite(nameBase+"BorderLeft").TileDraw(x, y + gfx_Rect.getSprite(nameBase+"TopLeft").h, gfx_Rect.getSprite(nameBase+"BorderLeft").w, Height - gfx_Rect.getSprite(nameBase+"BottomLeft").h - gfx_Rect.getSprite(nameBase+"TopLeft").h)
		gfx_Rect.getSprite(nameBase+"BorderRight").TileDraw(x + width - gfx_Rect.getSprite(nameBase+"BorderRight").w, y + gfx_Rect.getSprite(nameBase+"TopLeft").h, gfx_Rect.getSprite(nameBase+"BorderRight").w, Height - gfx_Rect.getSprite(nameBase+"BottomRight").h - gfx_Rect.getSprite(nameBase+"TopRight").h)
		gfx_Rect.getSprite(nameBase+"BorderTop").TileDraw(x + gfx_Rect.getSprite(nameBase+"TopLeft").w, y, width - gfx_Rect.getSprite(nameBase+"TopLeft").w - gfx_Rect.getSprite(nameBase+"TopRight").w, gfx_Rect.getSprite(nameBase+"BorderTop").h)
		gfx_Rect.getSprite(nameBase+"BorderBottom").TileDraw(x + gfx_Rect.getSprite(nameBase+"BottomLeft").w, y + Height - gfx_Rect.getSprite(nameBase+"BorderBottom").h, width - gfx_Rect.getSprite(nameBase+"BottomLeft").w - gfx_Rect.getSprite(nameBase+"BottomRight").w, gfx_Rect.getSprite(nameBase+"BorderBottom").h)
		gfx_Rect.getSprite(nameBase+"Back").TileDraw(x + gfx_Rect.getSprite(nameBase+"TopLeft").w, y + gfx_Rect.getSprite(nameBase+"TopLeft").h, width - gfx_Rect.getSprite(nameBase+"TopLeft").w - gfx_Rect.getSprite(nameBase+"TopRight").w, Height - gfx_Rect.getSprite(nameBase+"TopLeft").h - gfx_Rect.getSprite(nameBase+"BottomLeft").h)
	End Function

Type TBlockGraphical extends TBlockMoveable
	Field imageBaseName:string
	Field imageDraggedBaseName:string
	Field image:TGW_Sprites
	Field image_dragged:TGW_Sprites
    Global AdditionallyDragged:Int	= 0

End Type

Type TGameObject {_exposeToLua="selected"}
	Field id:Int		= 0 	{_exposeToLua saveload = "normal"}
	Global LastID:int	= 0

	Method New()
		self.GenerateID()
	End Method

	Method GenerateID()
		Self.id = Self.LastID
		Self.LastID:+1
	End Method

	'overrideable method for cleanup actions
	Method Remove()
	End Method

End Type

Type TBlockMoveable extends TGameObject
	Field rect:TRectangle			= TRectangle.Create(0,0,0,0)
	Field dragable:Int				= 1 {saveload = "normalExt"}
	Field dragged:Int				= 0 {saveload = "normalExt"}
	Field OrigPos:TPoint 			= TPoint.Create(0, 0) {saveload = "normalExtB"}
	Field StartPos:TPoint			= TPoint.Create(0, 0) {saveload = "normalExt"}
	Field StartPosBackup:TPoint		= TPoint.Create(0, 0)
	Field owner:Int					= 0 {saveload="normalExt"}

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
		return TFunctions.IsIn( x,y, Self.StartPos.getX(), Self.StartPos.getY(), Self.rect.getW(), Self.rect.getH() )
	End Method

	Method SetCoords(x:Int=NULL, y:Int=NULL, startx:Int=NULL, starty:Int=NULL)
      If x<>NULL 		Then Self.rect.position.SetX(x)
      If y<>NULL		Then Self.rect.position.SetY(y)
      If startx<>NULL	Then Self.StartPos.setX(startx)
      If starty<>NULL	Then Self.StartPos.SetY(starty)
	End Method

	Method SetBasePos(pos:TPoint = null)
		if pos <> null
			self.rect.position.setPos(pos)
			self.StartPos.setPos(pos)
		endif
	End Method

	Method IsAtStartPos:Int()
		return self.rect.position.isSame(self.StartPos, true)
	End Method

	Function SortDragged:int(o1:object, o2:object)
		Local s1:TBlockMoveable = TBlockMoveable(o1)
		Local s2:TBlockMoveable = TBlockMoveable(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (s1.dragged * 100)-(s2.dragged * 100)
	End Function
End Type


Type TFader
	Field fadecount:Double	= 0
	Field fadeout:Int 		= False
	Field fadeenabled:Int	= False
	Field fadeStarted:int	= FALSE

	Method Start()
		self.fadeStarted = TRUE
		Self.fadecount = 1
		Self.fadeout = False
	End Method

	Method Stop()
		self.fadeStarted = FALSE
	End Method

	Method Enable()
		Self.fadeenabled = True
	End Method

	Method Disable()
		Self.fadeenabled = FALSE
	End Method

	Method StartFadeout()
		self.Start()
		Self.fadecount = 20
		Self.fadeout = True
	End Method

	Method Update:int(deltaTime:float=1.0)
		if not self.fadeStarted then return FALSE

		If Self.fadecount > 20
			Self.fadecount = 20
		ElseIf Self.fadecount >= 0 And Self.fadeenabled
			if self.fadeOut
				Self.fadecount:-1.3
			else
				Self.fadecount:+1.3
			endif
		ElseIf Self.fadecount < 0
			Self.fadecount = -1
			Self.fadeenabled = False
		EndIf
	End Method

	Method Draw(deltaTime:float=1.0)
		If Self.fadecount >= 0 And Self.fadeenabled
			SetColor 0, 0, 0;SetAlpha float(Self.fadecount) / 20.0
			DrawRect(20,10,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(400+(20-Self.fadecount)*19,10,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(20,195+(20-Self.fadecount)*19,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(400+(20-Self.fadecount)*19,195+(20-Self.fadecount)*19,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			SetColor 255,255,255;SetAlpha 1.0
		EndIf
	End Method
End Type

Type TError
	Field title:String
	Field message:String
	Field id:Int
	Field link:TLink
	field pos:TPoint
	Global List:TList = CreateList()
	Global LastID:Int=0
	global sprite:TGW_Sprites

	Function Create:TError(title:String, message:String)
		Local obj:TError =  New TError
		obj.title	= title
		obj.message	= message
		obj.id		= LastID
		LastID :+1
		if obj.sprite = null then obj.sprite = Assets.getSprite("gfx_errorbox")
		obj.pos		= TPoint.Create(400-obj.sprite.w/2 +6, 200-obj.sprite.h/2 +6)
		obj.link	= List.AddLast(obj)
		Game.error:+1
		Return obj
	End Function

	Function CreateNotEnoughMoneyError()
		TError.Create(getLocale("ERROR_NOT_ENOUGH_MONEY"),getLocale("ERROR_NOT_ENOUGH_MONEY_TEXT"))
	End Function

	Function DrawErrors()
		If Game.error > 0
			Local error:TError = TError(List.Last())
			If error <> Null Then error.draw()
		EndIf
	End Function

	Function UpdateErrors()
		If Game.error > 0
			Local error:TError = TError(List.Last())
			If error <> Null Then error.Update()
		EndIf
	End Function

	Method Update()
		MouseManager.resetKey(2) 'no right clicking allowed as long as "error notice is active"
		If Mousemanager.IsClicked(1)
			If functions.MouseIn(pos.x,pos.y, sprite.w, sprite.h)
				link.Remove()
				Game.error :-1
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
		Assets.getFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.w - 60, 40, 0, 150, 50, 50)
		Assets.getFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.w-40, sprite.h-60,0,50,50,50)
  End Method
End Type


'Answer - objects for dialogues
Type TDialogueAnswer
	Field _text:String = ""
	Field _leadsTo:Int = 0
	Field _func:String(param:Int)
	Field _funcparam:Int = 0

	field _highlighted:int = 0

	Function Create:TDialogueAnswer (text:String, leadsTo:Int = 0, _func:String(param:Int) = Null, _funcparam:Int = 0)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text = Text
		obj._leadsTo = leadsTo
		obj._func = _func
		obj._funcparam = _funcparam
		Return obj
	End Function

	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		self._highlighted = FALSE
		If functions.MouseIn( x, y-2, w, Assets.getFont("Default", 12).getBlockHeight(Self._text, w, h))
			self._highlighted = TRUE
			If clicked
				If _func <> Null Then _func(Self._funcparam)
				Return _leadsTo
			EndIf
		EndIf
		Return - 1
	End Method

	Method Draw(x:Float, y:Float, w:Float, h:Float)
		if self._highlighted
			SetColor 200,100,100
			DrawOval(x, y +3, 6, 6)
			Assets.getFont("Default", 12, BoldFont).drawBlock(Self._text, x+9, y-1, w-10, h,0, 0, 0, 0)
		else
			SetColor 0,0,0
			DrawOval(x, y +3, 6, 6)
			Assets.getFont("Default", 12).drawBlock(Self._text, x+10, y, w-10, h,0, 100, 100, 100)
		endif
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

		local lineHeight:int = 2 + Assets.getFont("Default", 14).getHeight("QqT") 'high chars, low chars

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

			Local returnValue:Int = TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Update(self._rect.getX() + 10, self._rect.getY() + 10, self._rect.getW() - 60, self._rect.getH(), clicked)
			If returnValue <> - 1 Then nextText = returnValue
		EndIf
		_currentText = nextText
		If _currentText = -2 Then _currentText = 0;Return 0
		Return 1
	End Method

	Method Draw()
		SetColor 255, 255, 255
	    DrawDialog(Assets.getSpritePack("gfx_dialog"), self._rect.getX(), self._rect.getY(), self._rect.getW(), self._rect.getH(), "StartLeftDown", 0, "", Assets.getFont("Default", 14))
		SetColor 0, 0, 0
		If Self._texts.Count() > 0 Then TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Draw(self._rect.getX() + 10, self._rect.getY() + 10, self._rect.getW() - 60, self._rect.getH())
		SetColor 255, 255, 255
	End Method
End Type



'Interface, border, TV-antenna, audience-picture and number, watch...
'updates tv-images shown and so on
Type TInterface
  Field gfx_bottomRTT:TImage
  Field CurrentProgramme:TGW_Sprites
  Field CurrentAudience:TImage
  Field CurrentNoise:TGW_Sprites
  Field CurrentProgrammeText:String
  Field CurrentProgrammeToolTip:TTooltip
  Field CurrentAudienceToolTip:TTooltip
  Field MoneyToolTip:TTooltip
  Field BettyToolTip:TTooltip
  Field CurrentTimeToolTip:TTooltip
  Field NoiseAlpha:Float	= 0.95
  Field ChangeNoiseTimer:float= 0.0
  Field ShowChannel:Byte 	= 1
  Field BottomImgDirty:Byte = 1
  Global InterfaceList:TList

	'creates and returns an interface
	Function Create:TInterface()
		Local Interface:TInterface = New TInterface
		Interface.CurrentNoise				= Assets.getSprite("gfx_interface_TVprogram_noise1")
		Interface.CurrentProgramme			= Assets.getSprite("gfx_interface_TVprogram_none")
		Interface.CurrentProgrammeToolTip	= TTooltip.Create("", "", 40, 395)
		Interface.CurrentAudienceToolTip	= TTooltip.Create("", "", 355, 415)
		Interface.CurrentTimeToolTip		= TTooltip.Create("", "", 355, 495)
		Interface.MoneyToolTip				= TTooltip.Create("", "", 355, 365)
		Interface.BettyToolTip				= TTooltip.Create("", "", 355, 465)
		If Not InterfaceList Then InterfaceList = CreateList()
		InterfaceList.AddLast(Interface)
		SortList InterfaceList
		Return Interface
	End Function

	Method Update(deltaTime:float=1.0)
		If ShowChannel <> 0
			If Game.getMinute() >= 55
				Local adblock:TAdBlock = Game.Players[ShowChannel].ProgrammePlan.getCurrentAdBlock()
				Interface.CurrentProgramme = Assets.getSprite("gfx_interface_TVprogram_ads")
			    If adblock <> Null
					CurrentProgrammeToolTip.TitleBGtype = 1
					CurrentProgrammeText 				= getLocale("ADVERTISMENT")+": "+adblock.contract.contractBase.title
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText				= getLocale("BROADCASTING_OUTAGE")
				EndIf
			Else
				Local block:TProgrammeBlock = Game.Players[ShowChannel].ProgrammePlan.getCurrentProgrammeBlock()
				Interface.CurrentProgramme = Assets.getSprite("gfx_interface_TVprogram_none")
				If block <> Null
					Interface.CurrentProgramme = Assets.getSprite("gfx_interface_TVprogram_" + block.Programme.genre, "gfx_interface_TVprogram_none")
					CurrentProgrammeToolTip.TitleBGtype	= 0
					if block.programme.parent <> null
						CurrentProgrammeText = block.programme.parent.title + ": "+ block.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.getHour()-(block.sendhour - game.getDay()*24))+"/"+block.Programme.blocks+")"
					else
						CurrentProgrammeText = block.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.getHour()-(block.sendhour - game.getDay()*24))+"/"+block.Programme.blocks+")"
					endif
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText 				= getLocale("BROADCASTING_OUTAGE")
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
				If functions.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
					ShowChannel = i
					BottomImgDirty = True
				endif
			Next
		EndIf

		'noise on interface-tvscreen
		ChangeNoiseTimer :+ deltaTime
		If ChangeNoiseTimer >= 0.20
		    Local randomnoise:Int = Rand(0,3)
			If randomnoise = 0 Then CurrentNoise = Assets.getSprite("gfx_interface_TVprogram_noise1")
			If randomnoise = 1 Then CurrentNoise = Assets.getSprite("gfx_interface_TVprogram_noise2")
			If randomnoise = 2 Then CurrentNoise = Assets.getSprite("gfx_interface_TVprogram_noise3")
			If randomnoise = 3 Then CurrentNoise = Assets.getSprite("gfx_interface_TVprogram_noise4")
			ChangeNoiseTimer = 0.0
			NoiseAlpha = 0.45 - (Rand(0,10)*0.01)
		EndIf

		If functions.IsIn(MouseManager.x,MouseManager.y,20,385,280,200)
			CurrentProgrammeToolTip.title 		= CurrentProgrammeText
			If ShowChannel <> 0
				CurrentProgrammeToolTip.text	= GetLocale("AUDIENCE_RATING")+": "+Game.Players[ShowChannel].getFormattedAudience()+ " (MA: "+functions.convertPercent(Game.Players[ShowChannel].GetAudiencePercentage()*100,2)+"%)"

				'show additional information if channel is player's channel
				if ShowChannel = Game.playerID
					If Game.getMinute() >= 5 and Game.getMinute() < 55
						Local adblock:TAdBlock = Game.Players[ShowChannel].ProgrammePlan.getCurrentAdBlock()
						if adblock
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+":~n" + adblock.contract.contractBase.title+" (Mindestz.: "+functions.convertValue(String( adblock.contract.getMinAudience() ))+")"
						else
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+": nicht gesetzt!"
						endif
					elseif Game.getMinute()>=55 OR Game.getMinute()<5
						Local programmeblock:TProgrammeBlock = Game.Players[ShowChannel].ProgrammePlan.getCurrentProgrammeBlock()
						if programmeblock
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+":~n"
							if programmeblock.programme.parent <> null
								CurrentProgrammeToolTip.text :+ programmeblock.programme.parent.title + ": "+ programmeblock.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.getHour()-(programmeblock.sendhour - game.getDay()*24))+"/"+programmeblock.Programme.blocks+")"
							else
								CurrentProgrammeToolTip.text :+ programmeblock.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.getHour()-(programmeblock.sendhour - game.getDay()*24))+"/"+programmeblock.Programme.blocks+")"
							endif
						else
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+": nicht gesetzt!"
						endif
					endif
				endif

			Else
				CurrentProgrammeToolTip.text	= getLocale("TV_TURN_IT_ON")
			EndIf
			CurrentProgrammeToolTip.enabled 	= 1
			CurrentProgrammeToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = true
	    EndIf
		If functions.IsIn(MOUSEMANAGER.x,MOUSEMANAGER.y,355,468,130,30)
			'Print "DebugInfo: " + TAudienceResult.Curr().ToString()
			Local player:TPlayer = Game.Players[Game.playerID]
			Local audienceResult:TAudienceResult = player.audience
			CurrentAudienceToolTip.title 	= GetLocale("AUDIENCE_RATING")+": "+player.getFormattedAudience()+ " (MA: "+functions.convertPercent(player.GetAudiencePercentage() * 100,2)+"%)"
			CurrentAudienceToolTip.text = GetLocale("MAX_AUDIENCE_RATING") + ": " + audienceResult.MaxAudienceThisHour.GetSum() + " (" + (Int(Ceil(1000 * audienceResult.MaxAudienceThisHourQuote.GetAverage()) / 10)) + "%)"
			CurrentAudienceToolTip.enabled 	= 1
			CurrentAudienceToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = true
		EndIf
		If functions.IsIn(MouseManager.x,MouseManager.y,355,533,130,45)
			CurrentTimeToolTip.title 	= getLocale("GAME_TIME")+": "
			CurrentTimeToolTip.text  	= Game.getFormattedTime()+" "+getLocale("DAY")+" "+Game.getDayOfYear()+"/"+Game.daysPerYear+" "+Game.getYear()
			CurrentTimeToolTip.enabled 	= 1
			CurrentTimeToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = true
		EndIf
		If functions.IsIn(MouseManager.x,MouseManager.y,355,415,130,30)
			MoneyToolTip.title 	= getLocale("MONEY")
			MoneyTooltip.text	= getLocale("MONEY")+": "+Game.Players[Game.playerID].getMoney() + getLocale("CURRENCY")
			Moneytooltip.text	:+ "~n"
			Moneytooltip.text	:+ getLocale("DEBT")+": "+ Game.Players[Game.playerID].getCreditCurrent() + getLocale("CURRENCY")
			MoneyToolTip.enabled 	= 1
			MoneyToolTip.Hover()
			'force redraw
			MoneyToolTip.dirtyImage = true
		EndIf
		If functions.IsIn(MouseManager.x,MouseManager.y,355,510,130,15)
			BettyToolTip.title	 	= getLocale("BETTY_FEELINGS")
			BettyToolTip.text 	 	= "0 %"
			BettyToolTip.enabled 	= 1
			BettyToolTip.Hover()
			'force redraw
			BettyToolTip.dirtyImage = true
		EndIf

	End Method

	'draws the interface
	Method Draw(tweenValue:float=1.0)
		Assets.getSprite("gfx_interface_top").Draw(0,0)
		Assets.getSprite("gfx_interface_leftright").DrawClipped(0, 20, 0, 20, 27, 363, 0, 0)
		SetBlend SOLIDBLEND
		Assets.getSprite("gfx_interface_leftright").DrawClipped(780 - 27, 20, 780, 20, 20, 363, 0, 0)

		If BottomImgDirty
			Local NoDX9moveY:Int = 383

			SetBlend MASKBLEND
			'draw bottom, aligned "bottom"
			Assets.getSprite("gfx_interface_bottom").Draw(0,App.settings.getHeight(),0,1)

			If ShowChannel <> 0 Then Assets.getSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
		    For Local i:Int = 0 To 4
				If i = ShowChannel
					Assets.getSprite("gfx_interface_channelbuttons_on"+i).Draw(75 + i * 33, 171 + NoDX9moveY, i)
				Else
					Assets.getSprite("gfx_interface_channelbuttons_off"+i).Draw(75 + i * 33, 171 + NoDX9moveY, i)
				EndIf
		    Next
			If ShowChannel <> 0
				'If CurrentProgram = Null Then Print "ERROR: CurrentProgram is missing"
				CurrentProgramme.Draw(49, 403 - 383 + NoDX9moveY)

				Local audiencerate:Float = Game.Players[ShowChannel].audience.AudienceQuote.GetAverage()
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

	  		SetBlend MASKBLEND
	     	Assets.getSprite("gfx_interface_audience_overlay").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
			Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.Players[Game.playerID].getMoneyFormatted() + "  ", 377, 427 - 383 + NoDX9moveY, 103, 25, 2, 200,230,200, 0, 2)
			Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.Players[Game.playerID].getFormattedAudience() + "  ", 377, 469 - 383 + NoDX9moveY, 103, 25, 2, 200,200,230, 0, 2)
		 	Assets.getFont("Default", 11, BOLDFONT).drawBlock((Game.daysPlayed+1) + ". Tag", 366, 555 - 383 + NoDX9moveY, 120, 25, 1, 180,180,180, 0, 2)
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND
		Assets.getSprite("gfx_interface_antenna").Draw(111,329)

		If ShowChannel <> 0
			SetAlpha NoiseAlpha
			If CurrentNoise = Null Then Print "ERROR: CurrentNoise is missing"
			CurrentNoise.Draw(50, 404)
			SetAlpha 1.0
		EndIf
		SetAlpha 0.25
		Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.getFormattedTime() + " Uhr", 366, 542, 120, 25, 1, 180, 180, 180)
		SetAlpha 0.9
		Assets.getFont("Default", 13, BOLDFONT).drawBlock(Game.getFormattedTime()+ " Uhr", 365,541,120,25,1, 40,40,40)
		SetAlpha 1.0
   		CurrentProgrammeToolTip.Draw()
	    CurrentAudienceToolTip.Draw()
   		CurrentTimeToolTip.Draw()
	    BettyToolTip.Draw()
   		MoneyToolTip.Draw()
	    GUIManager.Draw("InGame")

		If Game.error >=1 Then TError.DrawErrors()
		If Game.cursorstate = 0 Then Assets.getSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y		,0)
		If Game.cursorstate = 1 Then Assets.getSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y-4	,1)
		If Game.cursorstate = 2 Then Assets.getSprite("gfx_mousecursor").Draw(MouseManager.x-10,	MouseManager.y-12	,2)
	End Method

End Type








'----stations
'Stationmap
'provides the option to buy new stations
'functions are calculation of audiencesums and drawing of stations

Type TStation extends TGameObject {_exposeToLua="selected"}
	Field pos:TPoint
	Field reach:Int				= -1
	Field reachIncrease:Int		= -1		'increase of reach at when bought
	Field price:Int				= -1
	Field fixedPrice:int		= FALSE		'fixed prices are kept during refresh
	Field owner:Int				= 0
	Field paid:Int				= FALSE
	Field built:int				= 0			'time at which the
	Field radius:int			= 0
	Field federalState:string	= ""

	Function Create:TStation( pos:TPoint, price:Int=-1, radius:int, owner:Int)
		Local obj:TStation = New TStation
		obj.owner		= owner
		obj.pos			= pos
		obj.price		= price
		obj.radius		= radius
		obj.built		= Game.getTimeGone()

		obj.fixedPrice	= (price <> -1)
		obj.refreshData()
		'print "pos "+pos.getIntX()+","+pos.getIntY()+" preis:"+obj.getPrice()+" reach:"+obj.getReach()
		Return obj
	End Function

	Function Load:TStation(pnode:TxmlNode)
		print "implement Load:TStation"
		return null
	End Function

	Method Save()
		print "implement Save:TStation"
	End Method

	'refresh the station data
	Method refreshData() {_exposeToLua}
		getReach(true)
		getReachIncrease(true)
		getPrice( not fixedPrice )
	End Method

	'returns the age in days
	Method getAge:int()
		return Game.GetDay() - Game.GetDay(self.built)
	End Method

	'get the reach of that station
	Method getReach:int(refresh:int=FALSE) {_exposeToLua}
		if reach >= 0 and not refresh then return reach
		reach = TStationMap.CalculateStationReach(pos.x, pos.y)

		return reach
	End Method

	Method getReachIncrease:int(refresh:int=FALSE) {_exposeToLua}
		if reachIncrease >= 0 and not refresh then return reachIncrease

		if not Game.isPlayer(owner)
			print "getReachIncrease: owner is not a player."
			return 0
		endif

		reachIncrease = Game.Players[owner].StationMap.CalculateAudienceIncrease(pos.x, pos.y)

		return reachIncrease
	End Method

	Method getFederalState:string(refresh:int=FALSE) {_exposeToLua}
		if federalState <> "" and not refresh then return federalState

		local hoveredSection:TStationMapSection = TStationMapSection.get(self.pos.x, self.pos.y)
		if hoveredSection then federalState = hoveredSection.name

		return federalState
	End Method

	Method getSellPrice:int(refresh:int=FALSE) {_exposeToLua}
		'price is multiplied by an age factor of 0.75-0.95
		local factor:float = Max(0.75, 0.95 - float(getAge())/1.0)
		if price >= 0 and not refresh then return int(price * factor / 10000) * 10000

		return int( getPrice(refresh) * factor / 10000) * 10000
	End Method

	Method getPrice:int(refresh:int=FALSE) {_exposeToLua}
		if price >= 0 and not refresh then return price
		price = Max( 25000, Int(Ceil(getReach() / 10000)) * 25000 )

		return price
	End Method

	Method Sell:int()
		if not Game.IsPlayer(owner) then return FALSE

		If Game.Players[owner].finances[Game.getWeekday()].SellStation( getSellPrice() )
			owner = 0
			return TRUE
		EndIf
		return FALSE
	End Method

	Method Buy:int( playerID:int=-1 )
		If playerID = -1 Then playerID = Game.playerID
		if not Game.IsPlayer(playerID) then return FALSE

		if paid then return TRUE

		If Game.Players[playerID].finances[Game.getWeekday()].PayStation( getPrice() )
			owner = playerID
			paid = TRUE
			return TRUE
		EndIf
		return FALSE
	End Method

	Method DrawInfoTooltip()
		local textH:int =  Assets.fonts.baseFontBold.getHeight( "Tg" )
		local tooltipW:int = 180
		local tooltipH:int = textH * 4 + 10 + 5
		local tooltipX:int = pos.x +20 - tooltipW/2
		local tooltipY:int = pos.y - radius - tooltipH

		'move below station if at screen top
		if tooltipY < 20 then tooltipY = pos.y+radius + 10 +10
		tooltipX = Max(20,tooltipX)
		tooltipX = Min(585-tooltipW,tooltipX)

		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(tooltipX,tooltipY,tooltipW,tooltipH)
		SetColor 255,255,255
		SetAlpha 1.0

		local textY:int = tooltipY+5
		local textX:int = tooltipX+5
		local textW:int = tooltipW-10
		Assets.fonts.baseFontBold.drawStyled( getLocale("MAP_COUNTRY_"+getFederalState()), textX, textY, 255,255,0, 2)
		textY:+ textH + 5

		Assets.fonts.baseFont.draw("Reichweite: ", textX, textY)
		Assets.fonts.baseFontBold.drawBlock(functions.convertValue(String(getReach()), 2, 0), textX, textY, textW, 20, 2, 255,255,255)
		textY:+ textH

		Assets.fonts.baseFont.draw("Zuwachs: ", textX, textY)
		Assets.fonts.baseFontBold.drawBlock(functions.convertValue(String(getReachIncrease()), 2, 0), textX, textY, textW, 20, 2, 255,255,255)
		textY:+ textH

		Assets.fonts.baseFont.draw("Preis: ", textX, textY)
		Assets.fonts.baseFontBold.drawBlock(functions.convertValue(getPrice(), 2, 0), textX, textY, textW, 20, 2, 255,255,255)
	End Method


	Method Draw(selected:int=FALSE)
		Local sprite:TGW_Sprites = Null
		local oldAlpha:float = getAlpha()

		if selected
			'white border around the colorized circle
			SetAlpha 0.25 * oldAlpha
			DrawOval(pos.x - radius+20 -2, pos.y - radius+10 -2 ,radius*2+4,radius*2+4)

			SetAlpha Min(0.9, Max(0,sin(Millisecs()/3)) + 0.5 ) * oldAlpha
		else
			SetAlpha 0.4 * oldAlpha
		endif

		Select owner
			Case 1,2,3,4	Game.Players[owner].color.SetRGB()
							sprite = Assets.getSprite("stationmap_antenna"+owner)
			Default			SetColor 255, 255, 255
							sprite = Assets.getSprite("stationmap_antenna0")
		End Select
		DrawOval(pos.x - radius + 20, pos.y - radius + 10, 2 * radius, 2 * radius)

		SetColor 255,255,255
		SetAlpha OldAlpha
		sprite.Draw(pos.x + 20, pos.y + 10 + radius - sprite.h - 2, -1,0,0.5)
	End Method
End Type

Type TStationMapSection
	field rect:TRectangle
	field sprite:TGW_Sprites
	field name:string
	global sections:TList = CreateList()

	Method Create:TStationMapSection(pos:TPoint, name:string, sprite:TGW_Sprites)
		self.rect = TRectangle.Create(pos.x,pos.y, sprite.w, sprite.h)
		self.name = name
		self.sprite = sprite
		return self
	End Method

	Function get:TStationMapSection(x:int,y:int)
		For local section:TStationMapSection = eachin sections
			if section.rect.containsXY(x,y)
				if section.sprite.PixelIsOpaque(x-section.rect.getX(), y-section.rect.getY()) > 0
					return section
				endif
			endif
		Next
		return Null
	End Function

	Method Add()
		self.sections.addLast(self)
	End Method
end Type

EventManager.registerListener( "LoadResource.STATIONMAP",	TEventListenerRunFunction.Create(TStationMap.onLoadStationMapConfiguration)  )
Type TStationMap {_exposeToLua="selected"}
	Field showStations:Int[4]						'select whose players stations we want to see
	Field reach:int					= 0				'maximum audience possible

	Field mouseoverStation:TStation	= null			'for showing details for current mouse position
	Field selectedStation:TStation	= null			'for sale or buy
	Field userAction:int			= 0				'state
	Field parent:TPlayer			= null
	Field stations:TList			= CreateList()	'all stations of the map owner

	Global shareMap:TMap			= Null			'map containing bitmask-coded information for "used" pixels
	Global shareCache:TMap			= Null

	Global stationRadius:Int		= 15		{saveload = "normal"}
	Global population:Int			= 0			{saveload = "normal"}
	Global populationmap:Int[,]
	Global populationMapSize:TPoint	= TPoint.Create()

	Global List:TList				= CreateList()	'all stationmaps (currently: only one)
	Global fireEvents:int			= TRUE			'FALSE to avoid recursive handling (network)
	Global initDone:int				= FALSE			'map init already done?

	Method Load:TStationmap(pnode:TxmlNode)
		print "implement Load:TStationmap"
		return null
	End Method

	Function LoadAll()
		print "implement loadall:TStationmap"
	End Function

	Function SaveAll()
		print "implement saveall:TStationmap"
	End Function

	Function InitMapData:int()
		if initDone then return TRUE

		local start:int = Millisecs()
		local i:int, j:int

		'calculate population
		local pix:TPixmap = Assets.getPixmap("stationmap_populationDensity")
		local map:int[pix.width + 20, pix.height + 20]
		populationMap = map
		populationMapSize.SetXY(pix.width, pix.height)

		'read all inhabitants of the map
		For i = 0 To pix.width-1
			For j = 0 To pix.height-1
				if ARGB_ALPHA(pix.ReadPixel(i, j)) = 0 then continue
				populationmap[i, j] = getPopulationForBrightness( ARGB_RED(pix.ReadPixel(i, j)) )
				population:+ populationmap[i, j]
			Next
		Next
		Print "StationMap: calculated a population of:" + population + " in "+(Millisecs()-start)+"ms"
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Stationmap").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

		'to refresh share map on buy/sell of stations
		EventManager.registerListenerFunction( "stationmap.addStation",	onChangeStations )
		EventManager.registerListenerFunction( "stationmap.removeStation",	onChangeStations )

		initDone = true
		return TRUE
	End Function


	Function Create:TStationMap(player:TPlayer)
		Local obj:TStationMap = New TStationMap
		obj.parent = player

		if not InitDone then obj.InitMapData()

		list.AddLast(obj)
		Return obj
	End Function

	'return the stationmap of other players
	'do not expose to Lua... else they get access to buy/sell
	Function getStationMap:TStationMap(playerID:int=-1)
		If playerID <= 0 Then playerID = Game.playerID

		if list.count() < playerID then return Null

		return TStationMap(self.list.ValueAtIndex(playerID-1))
	End Function

	'someone sold or bought a station, call shareMap-Generator
	Function onChangeStations:int( triggerEvent:TEventBase )
		GenerateShareMap()
	End Function

	'external xml configuration of map and states
	Function onLoadStationMapConfiguration:int( triggerEvent:TEventBase)
		local childNode:TxmlNode = null
		local xmlLoader:TXmlLoader = null
		if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

		'find and load density map data (and overwrite asset name)
		local densityNode:TXmlNode = xmlLoader.xml.FindChild(childNode, "densitymap")
		if densityNode then xmlLoader.LoadPixmapResource(densityNode, "stationmap_populationDensity")

		'find and load states data
		local statesNode:TXmlNode = xmlLoader.xml.FindChild(childNode, "states")
		if statesNode = null then Throw("StationMap: states definition missing in XML files.")

		For Local child:TxmlNode = EachIn statesNode.getChildren()
			local name:string	= xmlLoader.xml.FindValue(child, "name", "")
			local sprite:string	= xmlLoader.xml.FindValue(child, "sprite", "")
			local pos:TPoint	= TPoint.Create( xmlLoader.xml.FindValueInt(child, "x", 0), xmlLoader.xml.FindValueInt(child, "y", 0) )
			'add state section if data is ok
			if name<>"" and sprite<>"" then new TStationMapSection.Create(pos,name, Assets.getSprite(sprite)).add()
		Next

	End Function

	'returns the maximum reach of the stations on that map
	Method getReach:int() {_exposeToLua}
		return self.reach
	End Method

	Method getCoverage:float() {_exposeToLua}
		return float(self.reach) / float(self.population)
	End Method


	'returns a station-object wich can be used for further
	'information getting (share etc)
	Method getTemporaryStation:TStation(x:int,y:int)  {_exposeToLua}
		return TStation.Create(TPoint.Create(x,y),-1, self.stationRadius, self.parent.playerID)
	End Method

	'return a station at the given coordinates (eg. used by network)
	Method getStation:TStation(x:int=0,y:int=0) {_exposeToLua}
		local pos:TPoint = TPoint.Create(x,y)
		For local station:TStation = eachin self.stations
			if not station.pos.isSame(pos) then continue
			return station
		Next
		return Null
	End Method

	'returns a station of a player at a given position in the list
	Method getStationFromList:TStation(playerID:int=-1, position:int=0) {_exposeToLua}
		local stationMap:TStationMap = self.getStationMap(playerID)
		if not stationMap then return Null
		'out of bounds?
		If position<0 OR position >= stationMap.stations.count() Then Return NULL

		return TStation( stationMap.stations.ValueAtIndex(position) )
	End Method

	'returns the amount of stations a player has
	Method getStationCount:Int(playerID:int=-1) {_exposeToLua}
		if playerID = self.parent.playerID then Return stations.count()

		local stationMap:TStationMap = self.getStationMap(playerID)
		if not stationMap then return Null

		return stationMap.getStationCount(playerID)
	End Method


	'buy a new station at the given coordinates
	'only possible when in office+subrooms
	Method BuyStation:int(x:int,y:int) {_exposeToLua}
		if not self.parent.isInRoom("office", True) then return FALSE

		return self.AddStation( getTemporaryStation( x, y ), TRUE )
	End Method

	'sell a station at the given position in the list
	'only possible when in office+subrooms
	Method SellStation:int(position:int) {_exposeToLua}
		if not self.parent.isInRoom("office", True) then return FALSE

		local station:TStation = self.getStationFromList(position)
		if station then return self.RemoveStation(station, true)
	End Method


	Method AddStation:int(station:TStation, buy:int=FALSE)
		if not station then return FALSE

		'try to buy it (does nothing if already done)
		if buy and not station.Buy(parent.playerID) then return FALSE
		'set to paid in all cases
		station.paid = true

		stations.AddLast(station)

		'recalculate audience of channel
		RecalculateAudienceSum()

		Print "Player" + parent.playerID + " kauft Station fuer " + station.price + " Euro (" + station.reach + " Einwohner)"

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "stationmap.addStation", TData.Create().add("station", station), self ) )

		return TRUE
	End Method


	Method RemoveStation:int(station:TStation, sell:int=FALSE)
		if not station then return FALSE

		'check if we try to sell our last station...
		if self.stations.count() = 1
			'if we are the player in front of the screen
			'inform about the situation
			if parent.playerID = Game.playerID
				TError.Create( getLocale("ERROR_NOT_POSSIBLE"), getLocale("ERROR_NOT_ABLE_TO_SELL_LAST_STATION") )
			endif
			return FALSE
		endif

		if sell and not station.sell() then return FALSE

		stations.Remove(station)

		if sell
			Print "Player" + parent.playerID + " verkauft Station fuer " + ( station.getSellPrice() ) + " Euro (" + station.reach + " Einwohner)"
		else
			Print "Player" + parent.playerID + " verschrottet Station fuer 0 Euro (" + station.reach + " Einwohner)"
		endif

		'recalculate audience of channel
		RecalculateAudienceSum()

		'when station is sold, audience will decrease,
		'while a buy will not increase the current audience but the next block
		parent.ComputeAudience( TRUE )

		'emit an event so eg. network can recognize the change
		if fireEvents then EventManager.registerEvent( TEventSimple.Create( "stationmap.removeStation", TData.Create().add("station", station), self ) )

		return TRUE
    End Method


	Method CalculateStationCosts:Int(owner:Int=0)
		Local costs:Int = 0
		For Local Station:TStation = EachIn stations
			If station.owner = owner Then costs:+1000 * Ceil(station.price / 50000) ' price / 50 = cost
		Next
		Return costs
	End Method

	Method Update()
	End Method


	Method DrawStations()
		For Local _Station:TStation = EachIn stations
			if _station = selectedStation then continue
			_Station.Draw()
		Next
	End Method

	Method Draw()
		SetColor 255,255,255

		'zero based
		For local i:int = 0 to Game.playerCount-1
			If not Self.showStations[i] then continue
			GetStationMap(i).DrawStations()
		Next
	End Method

	'summary: returns calculated distance between 2 points
	Function calculateDistance:Double(x1:Int, x2:Int)
		Return Sqr((x1*x1) + (x2*x2))
	End Function

	Function getMaskIndex:int(number:int)
		Local t:int = 1
		for local i:int = 1 to number-1
			t:*2
		Next
		Return t
	End Function

	Function getPopulationForBrightness:int(value:int)
		value = Max(5, 255-value)
		value = (value*value)/255 '2 times so low values are getting much lower
'		value = (value*value)/255
		value:* 0.649
'		If value < 50 Then value :* 1.5

		If value > 110 Then value :* 2.0
		If value > 140 Then value :* 1.9
		If value > 180 Then value :* 1.3
		If value > 220 Then value :* 1.1	'population in big cities
		return 26.0 * value					'population in general
	End Function

	Function GetShareMap:TMap()
		if not shareMap then GenerateShareMap()
		return shareMap
	End Function

	'returns the shared amount of audience between players
	Function GetShareAudience:int(playerIDs:int[], withoutPlayerIDs:int[]=null)
		return GetShare(playerIDs, withoutPlayerIDs).x
	End Function

	Function GetSharePercentage:float(playerIDs:int[], withoutPlayerIDs:int[]=null)
		return GetShare(playerIDs, withoutPlayerIDs).z
	End Function

	'returns a share between players, encoded in a tpoint containing:
	'x=sharedAudience,y=totalAudience,z=percentageOfSharedAudience
	Function GetShare:TPoint(playerIDs:Int[], withoutPlayerIDs:Int[]=Null)
		If playerIDs.length <1 Then Return TPoint.Create(0,0,0.0)
		if not withoutPlayerIDs then withoutPlayerIDs = new Int[0]
		Local cacheKey:String = ""

		for local i:int = 0 to playerIDs.length-1
			cacheKey:+ "_"+playerIDs[i]
		Next
		cacheKey:+"_without_"
		for local i:int = 0 to withoutPlayerIDs.length-1
			cacheKey:+ "_"+withoutPlayerIDs[i]
		Next

		'if already cached, save time...
		if shareCache and shareCache.contains(cacheKey) then return TPoint(shareMap.ValueForKey(cacheKey))

		local map:TMap				= GetShareMap()
		local result:TPoint			= TPoint.Create(0,0,0.0)
		local share:int				= 0
		local total:int				= 0
		local playerFlags:int[]
		local allFlag:int			= 0
		local withoutPlayerFlags:int[]
		local withoutFlag:int		= 0
		playerFlags					= playerFlags[.. playerIDs.length]
		withoutPlayerFlags			= withoutPlayerFlags[.. withoutPlayerIDs.length]

		for local i:int = 0 to playerIDs.length-1
			'player 1=1, 2=2, 3=4, 4=8 ...
			playerFlags[i]	= getMaskIndex( playerIDs[i] )
			allFlag :| playerFlags[i]
		Next

		for local i:int = 0 to withoutPlayerIDs.length-1
			'player 1=1, 2=2, 3=4, 4=8 ...
			withoutPlayerFlags[i]	= getMaskIndex( withoutPlayerIDs[i] )
			withoutFlag :| withoutPlayerFlags[i]
		Next


		local someoneUsesPoint:int			= FALSE
		local allUsePoint:int				= FALSE
		For Local mapValue:TPoint	= EachIn map.Values()
			someoneUsesPoint		= FALSE
			allUsePoint				= FALSE

			'we need to check if one on our ignore list is there
				'no need to do this individual, we can just check the groupFlag
				rem
				local someoneUnwantedUsesPoint:int	= FALSE
				for local i:int = 0 to withoutPlayerFlags.length-1
					if int(mapValue.z) & withoutPlayerFlags[i]
						someoneUnwantedUsesPoint = true
						exit
					endif
				Next
				if someoneUnwantedUsesPoint then continue
				endrem
			if int(mapValue.z) & withoutFlag then continue

			'as we have multiple flags stored in AllFlag, we have to
			'compare the result to see if all of them hit,
			'if only one of it hits, we just check for <>0
			if (int(mapValue.z) & allFlag) = allFlag
				allUsePoint = true
				someoneUsesPoint = true
			else
				for local i:int = 0 to playerFlags.length-1
					if int(mapValue.z) & playerFlags[i] then someoneUsesPoint = true;exit
				Next
			endif
			'someone has a station there
			if someoneUsesPoint then total:+ populationmap[mapValue.x, mapValue.y]
			'all searched have a station there
			if allUsePoint then share:+ populationmap[mapValue.x, mapValue.y]
		Next
		result.setXY(share, total)
		if total = 0 then result.z = 0.0 else result.z = float(share)/float(total)

		print "total: "+total
		print "share:"+share
		print "result:"+result.z
		print "allFlag:"+allFlag
		'print "cache:"+cacheKey
		print "--------"
		'add to cache...
		'shareCache.insert(cacheKey, result )

		return result
	End Function


	Function GenerateShareMap:int()
		'reset values
		shareMap = new TMap
		'reset cache here too
		shareCache = new TMap

		'define locals outside of that for loops...
		local posX:int		= 0
		local posY:int		= 0
		local stationX:int	= 0
		local stationY:int	= 0
		local mapKey:string	= ""
		local mapValue:TPoint = null
		local rect:TRectangle = TRectangle.Create(0,0,0,0)
		For local stationmap:TStationMap = eachin List
			For local station:TStation = EachIn stationmap.stations
				'mark the area within the stations circle
				posX = 0
				posY = 0
				stationX = Max(0, station.pos.x)
				stationY = Max(0, station.pos.y)
				Rect.position.SetXY( Max(stationX - stationRadius,stationRadius), Max(stationY - stationRadius,stationRadius) )
				Rect.dimension.SetXY( Min(stationX + stationRadius, self.populationMapSize.x-stationRadius), Min(stationY + stationRadius, self.populationMapSize.y-stationRadius) )

				For posX = Rect.getX() To Rect.getW()
					For posY = Rect.getY() To Rect.getH()
						' left the circle?
						If self.calculateDistance( posX - stationX, posY - stationY ) > stationRadius then continue

						'insert the players bitmask-number into the field
						'and if there is already one ... add the number
						mapKey = posX+","+posY
						mapValue = TPoint.Create(posX,posY, getMaskIndex(stationmap.parent.playerID) )
						If shareMap.Contains(mapKey)
							mapValue.z = int(mapValue.z) | int(TPoint(shareMap.ValueForKey(mapKey)).z)
						endif
						shareMap.Insert(mapKey, mapValue)
					Next
				Next
			Next
		Next
	End Function


	Method _FillPoints(map:TMap var, x:int, y:int, color:int)
		local posX:int=0
		local posY:int=0
		x = Max(0,x)
		y = Max(0,y)
		' innerhalb des Bildes?
		For posX = Max(x - stationRadius,stationRadius) To Min(x + stationRadius, self.populationMapSize.x-stationRadius)
			For posY = Max(y - stationRadius,stationRadius) To Min(y + stationRadius, self.populationMapSize.y-stationRadius)
				' noch innerhalb des Kreises?
				If self.calculateDistance( posX - x, posY - y ) <= stationRadius
					map.Insert(String((posX) + "," + (posY)), TPoint.Create((posX) , (posY), color ))
				EndIf
			Next
		Next
	End Method

	Method CalculateAudienceIncrease:Int(_x:Int, _y:Int)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
		Local returnValue:Int = 0
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0

		'add "new" station which may be bought
		If _x = 0 And _y = 0 Then _x = MouseManager.x - 20; _y = MouseManager.y - 10
		self._FillPoints(Points, _x,_y, ARGB_Color(255, 0, 255, 255))

		'overwrite with stations owner already has - red pixels get overwritten with white,
		'count red at the end for increase amount
		For Local _Station:TStation = EachIn stations
			If functions.IsIn(_x,_y, _station.pos.x - 2*stationRadius, _station.pos.y - 2 * stationRadius, 4*stationRadius, 4*stationRadius)
				self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
			EndIf
		Next

		For Local point:TPoint = EachIn points.Values()
			If ARGB_Red(point.z) = 0 And ARGB_Blue(point.z) = 255
				returnvalue:+ populationmap[point.x, point.y]
			EndIf
		Next
		Return returnvalue
	End Method

	'summary: returns maximum audience a player has
	Method RecalculateAudienceSum:Int()
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0
		For Local _Station:TStation = EachIn stations
			self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
		Next
		Local returnValue:Int = 0

		For Local point:TPoint = EachIn points.Values()
			If ARGB_Red(point.z) = 255 And ARGB_Blue(point.z) = 255
				returnValue:+ populationmap[point.x, point.y]
			EndIf
		Next
		self.reach = returnValue
		Return returnValue
	End Method

	'summary: returns a stations maximum audience reach
	Function CalculateStationReach:Int(x:Int, y:Int)
		Local posX:Int, posY:Int
		Local returnValue:Int = 0
		' fÃ¼r die aktuelle Koordinate die summe berechnen
		' min/max = immer innerhalb des Bildes
		For posX = Max(x - stationRadius,stationRadius) To Min(x + stationRadius, self.populationMapSize.x-stationRadius)
			For posY = Max(y - stationRadius,stationRadius) To Min(y + stationRadius, self.populationMapSize.y-stationRadius)
				' noch innerhalb des Kreises?
				If self.calculateDistance( posX - x, posY - y ) <= stationRadius
					returnvalue:+ populationmap[posX, posY]
				EndIf
			Next
		Next
		Return returnValue
	End Function

End Type
