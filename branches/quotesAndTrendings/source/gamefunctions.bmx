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
		local guiInput:TGUIInput = TGUIInput(triggerEvent.GetSender())
		if guiInput = Null then return FALSE

		local guiChat:TGUIChat = TGUIChat(guiInput._parent)
		if guiChat = Null then return FALSE

		'emit event : chats should get a new line
		'- step A) is to get what channels we want to announce to
		local sendToChannels:int = guiChat.GetChannelsFromText(guiInput.value)
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
		local guiChat:TGUIChat = TGUIChat(triggerEvent.GetReceiver())
		'if event has a specific receiver and this is not a chat - we are not interested
		if triggerEvent.GetReceiver() AND not guiChat then return FALSE
		'found a chat - but it is another chat
		if guiChat and guiChat <> self then return FALSE

		'here we could add code to exlude certain other chat channels
		local sendToChannels:int = triggerEvent.GetData().getInt("channels", 0)
		if self.isListeningToChannel(sendToChannels)
			self.AddEntryFromData( triggerEvent.GetData() )
		else
			print "onAddEntry - unknown channel, not interested"
		endif
	End Method


	Function GetChannelsFromText:int(text:string)
		local sendToChannels:int = 0 'by default send to no channel
		Select GetSpecialCommandFromText("/w ronny hi")
			case CHAT_COMMAND_WHISPER
				sendToChannels :| CHAT_CHANNEL_PRIVATE
			default
				sendToChannels :| CHAT_CHANNEL_GLOBAL
		end Select
		return SendToChannels
	End Function

	Function GetSpecialCommandFromText:int(text:string)
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
		local text:string		= data.GetString("text", "")
		local textColor:TColor	= TColor( data.Get("textColor") )
		local senderID:int		= data.GetInt("senderID", 0)
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

	Method Update()
		'Super.update()

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

	Method GetDimension:TPoint()
		local move:TPoint = TPoint.Create(0,0)
		if self.Data.getString("senderName",null)
			local senderColor:TColor = TColor(self.Data.get("senderColor"))
			if not senderColor then senderColor = TColor.Create(0,0,0)
			move = Assets.fonts.baseFontBold.drawStyled(self.Data.getString("senderName")+":", self.GetScreenX(), self.GetScreenY(), senderColor.r, senderColor.g, senderColor.b, 2, 0)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		endif
		'available width is parentsDimension minus startingpoint
		local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(self.getParent("tguiscrollablepanel"))
		local maxWidth:int = parentPanel.GetContentScreenWidth()-self.rect.GetX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		local dimension:TPoint = Assets.fonts.baseFont.drawBlock(self.label, self.GetScreenX()+move.x, self.GetScreenY()+move.y, maxWidth-move.X, maxHeight, 0, 255, 255, 255, 0, 2, 0)

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

	Method GetParentWidth:float(parentClassName:string="toplevelparent")
		if not self._parent then return self.rect.GetW()
		return self.getParent(parentClassName).rect.GetW()
	End Method

	Method GetParentHeight:float(parentClassName:string="toplevelparent")
		if not self._parent then return self.rect.GetH()
		return self.getParent(parentClassName).rect.GetH()
	End Method

	Method Draw:int()
		self.getParent("tguilistbase").RestrictViewPort()

		if self.showtime <> Null then setAlpha float(self.showtime-Millisecs())/500.0
		'available width is parentsDimension minus startingpoint
		local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(self.getParent("tguiscrollablepanel"))
		local maxWidth:int = parentPanel.GetContentScreenWidth()-self.rect.GetX()

		'local maxWidth:int = self.GetParentWidth("tguiscrollablepanel")-self.rect.GetX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		local move:TPoint = TPoint.Create(0,0)
		if self.Data.getString("senderName",null)
			local senderColor:TColor = TColor(self.Data.get("senderColor"))
			if not senderColor then senderColor = TColor.Create(0,0,0)
			move = Assets.fonts.baseFontBold.drawStyled(self.Data.getString("senderName", "")+":", self.GetScreenX(), self.GetScreenY(), senderColor.r, senderColor.g, senderColor.b, 2, 1)
			'move the x so we get space between name and text
			'move the y point 1 pixel as bold fonts are "higher"
			move.setXY( move.x+5, 1)
		endif
		Assets.fonts.baseFont.drawBlock(self.label, self.GetScreenX()+move.x, self.GetScreenY()+move.y, maxWidth-move.X, maxHeight, 0, self.labelColor.r, self.labelColor.g, self.labelColor.b, 0, 2, 1, 0.5)

		setAlpha 1.0

		self.getParent("tguilistbase").ResetViewPort()
	End Method

End Type


'create a custom type so we can check for doublettes on add
Type TGUIGameList Extends TGUIListBase
	field selectedEntry:TGUIobject = null

    Method Create:TGUIGameList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		super.Create(x,y,width,height, State)

		'we want to know about clicks
		EventManager.registerListenerMethod( "guiobject.onClick",	self, "onClickOnEntry", "TGUIGameEntry" )

		return self
	end Method

	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		local entry:TGUIGameEntry = TGUIGameEntry( triggerEvent.GetSender() )
		if not entry then return FALSE

		'only mark selected if we are owner of that entry
		if self.HasItem(entry)
			if TGUIGameEntry(self.selectedEntry) then TGUIGameEntry(self.selectedEntry).selected = false
			self.selectedEntry = entry
			if TGUIGameEntry(self.selectedEntry) then TGUIGameEntry(self.selectedEntry).selected = true
		endif
	End Method

	Method GetSelectedEntry:TGUIobject()
		return self.selectedEntry
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

Type TGUIGameEntry extends TGUIListItem
	field paddingBottom:int		= 3
	field paddingTop:int		= 2
	field selected:int			= FALSE

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

	Method GetDimension:TPoint()
		'available width is parentsDimension minus startingpoint
		local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(self.getParent("tguiscrollablepanel"))
		local maxWidth:int = parentPanel.GetContentScreenWidth()-self.rect.GetX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		local text:string = self.Data.getString("gameTitle","#unknowngametitle#")+" by "+ self.Data.getString("hostName","#unknownhostname#") + " ("+self.Data.getInt("slotsUsed",1)+"/"+self.Data.getInt("slotsMax",4)
		local dimension:TPoint = Assets.fonts.baseFont.drawBlock(text, self.GetScreenX(), self.GetScreenY(), maxWidth, maxHeight, 0, 255, 255, 255, 0, 2, 0)

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
		'available width is parentsDimension minus startingpoint
		local maxWidth:int = TGUIobject(self.getParent("topitem")).GetContentScreenWidth()-self.rect.GetX()
		local maxHeight:int = 2000 'more than 2000 pixel is a really long text

		if self.mouseover
			SetColor 250,210,100
			DrawRect(self.GetScreenX(), self.GetScreenY(), maxWidth, self.rect.GetH())
			SetColor 255,255,255
		elseif self.selected
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(self.GetScreenX(), self.GetScreenY(), maxWidth, self.rect.GetH())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		endif

		'draw text
		local move:TPoint = TPoint.Create(0, self.paddingTop)
		local text:string = ""
		local textColor:TColor = null
		local textDim:TPoint = null
		'line: title by hostname (slotsused/slotsmax)

		text 		= self.Data.getString("gameTitle","#unknowngametitle#")
		textColor	= TColor(self.Data.get("gameTitleColor", TColor.Create(150,80,50)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, self.GetScreenX() + move.x, self.GetScreenY() + move.y, textColor.r, textColor.g, textColor.b, 2, 1,0.5)
		move.moveXY(textDim.x,1)

		text 		= " by "+self.Data.getString("hostName","#unknownhostname#")
		textColor	= TColor(self.Data.get("hostNameColor", TColor.Create(50,50,150)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, self.GetScreenX() + move.x, self.GetScreenY() + move.y, textColor.r, textColor.g, textColor.b)
		move.moveXY(textDim.x,0)

		text 		= " ("+self.Data.getInt("slotsUsed",1)+"/"++self.Data.getInt("slotsMax",4)+")"
		textColor	= TColor(self.Data.get("hostNameColor", TColor.Create(0,0,0)) )
		textDim		= Assets.fonts.baseFontBold.drawStyled(text, self.GetScreenX() + move.x, self.GetScreenY() + move.y, textColor.r, textColor.g, textColor.b)
		move.moveXY(textDim.x,0)

		setAlpha 1.0

		self.getParent("tguigamelist").ResetViewPort()
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
						If TList(t.Get(obj)) <> Null
							Local liste:TList = TList(t.Get(obj))
							For Local childobj:Object = EachIn liste
								Print "saving list children..."
								Self.SaveObject(childobj, nodename + "_CHILD", _addfunc)
							Next
						Else
							Self.xmlWrite(Upper(t.name()), String(t.Get(obj)))
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

	Method GetOpen:Int()
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
		Obj.gfxmovies		= Assets.GetSprite("pp_menu_werbung")   'Assets.GetSprite("") '  = gfxmovies
		Obj.gfxtape			= Assets.GetSprite("pp_cassettes_movies")
		Obj.gfxtapeseries	= Assets.GetSprite("pp_cassettes_series")
		Obj.gfxtapeepisodes	= Assets.GetSprite("pp_cassettes_episodes")
		Obj.gfxepisodes		= Assets.GetSprite("episodes")
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
			Assets.GetSprite("genres_top").draw(Pos.x,currY)
			currY:+Assets.GetSprite("genres_top").h

'			gfxgenres.Draw(Pos.x, Pos.y)
			For local genres:int = 0 To self.maxGenres-1 		'21 genres
				local lineHeight:int =0
				local entryNum:string = (genres mod 2)
				if genres = 0 then entryNum = "First"
				Assets.GetSprite("genres_entry"+entryNum).draw(Pos.x,currY)
				lineHeight = Assets.GetSprite("genres_entry"+entryNum).h

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
			Assets.GetSprite("genres_bottom").draw(Pos.x,currY)
		EndIf
	End Method

	Method DrawTapes:Int(genre:Int, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxmovies.w + 25
		Local locy:Int = Pos.y+7 -19

		local font:TBitmapFont = Assets.GetFont("Font10")
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
		local font:TBitmapFont = Assets.GetFont("Default", 8)

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
			If MOUSEMANAGER.IsHit(1) AND functions.IsIn(MouseManager.x,MouseManager.y, Pos.x,Pos.y, Assets.GetSprite("genres_entry0").w, Assets.GetSprite("genres_entry0").h*self.MaxGenres)
				SetOpen(2)
				currentgenre = Floor((MouseManager.y - Pos.y - 1) / Assets.GetSprite("genres_entry0").h)
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
		NewObject.gfxcontracts	= Assets.GetSprite("pp_menu_werbung")
		NewObject.gfxtape 		= Assets.GetSprite("pp_cassettes_movies")
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
		local font:TBitmapFont 		= Assets.GetFont("Default", 10)
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
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
		LoadSaveFile.xmlCloseNode()
	End Method


  Function Create:TAudienceQuotes(title:String, audience:Double, audiencepercentage:Int, sendhour:Int, sendminute:Int,senddate:Int, playerID:Int)
    Local locObject:TAudienceQuotes = New TAudienceQuotes
	locObject.title    = title
	locObject.audience = audience
	locObject.audiencepercentage = Int(audiencepercentage)
	locObject.sendhour = sendhour
	locObject.sendminute = sendminute
	locObject.senddate = senddate
	locObject.playerID = playerID
	List.AddLast(locObject)
	Return locObject
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

	Function GetAudienceOfDate:TAudienceQuotes(playerID:int, day:Int, hour:Int, minute:Int)
		Local locObject:TAudienceQuotes
		For Local obj:TAudienceQuotes = EachIn TAudienceQuotes.List
			If obj.playerID = playerID And obj.senddate = day And obj.sendhour = hour And obj.sendminute = minute Then Return obj
  		Next
		Return Null
	End Function

  Function GetAudienceOfDay:TAudienceQuotes[](playerID:Int, day:Int)
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

	Method GetWidth:Int()
		local txtWidth:int = self.useFontBold.getWidth(title)+6
		If tooltipimage >=0 Then txtwidth:+ TTooltip.ToolTipIcons.framew+ 2
		If txtwidth < self.useFont.getWidth(text)+6 Then txtwidth = self.useFont.getWidth(text)+6
		Return txtwidth
	End Method

	Method DrawShadow(_width:float, _height:float)
		SetColor 0, 0, 0
		SetAlpha self.GetFadeAmount()-0.8
		DrawRect(self.pos.x+2,self.pos.y+2,_width,_height)

		SetAlpha self.GetFadeAmount()-0.5
		DrawRect(self.pos.x+1,self.pos.y+1,_width,_height)
	End Method

	Method GetFadeAmount:float()
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

			SetAlpha self.GetFadeAmount()
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

			SetAlpha self.GetFadeAmount()
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
			SetAlpha self.GetFadeAmount()
			SetColor 255,255,255
			DrawImage(image, self.pos.x, self.pos.y)
			SetAlpha 1.0
		EndIf
	End Method
End Type


	Function DrawDialog(gfx_Rect:TGW_SpritePack, x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TGW_Sprites = gfx_Rect.GetSprite(DialogStart)
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
		gfx_Rect.GetSprite(nameBase+"TopLeft").Draw(x, y)
		gfx_Rect.GetSprite(nameBase+"TopRight").Draw(x + width, y,-1,0,1)
		gfx_Rect.GetSprite(nameBase+"BottomLeft").Draw(x, y + Height, -1,1)
		gfx_Rect.GetSprite(nameBase+"BottomRight").Draw(x + width, y + Height, -1, 1,1)

		gfx_Rect.GetSprite(nameBase+"BorderLeft").TileDraw(x, y + gfx_Rect.GetSprite(nameBase+"TopLeft").h, gfx_Rect.GetSprite(nameBase+"BorderLeft").w, Height - gfx_Rect.GetSprite(nameBase+"BottomLeft").h - gfx_Rect.GetSprite(nameBase+"TopLeft").h)
		gfx_Rect.GetSprite(nameBase+"BorderRight").TileDraw(x + width - gfx_Rect.GetSprite(nameBase+"BorderRight").w, y + gfx_Rect.GetSprite(nameBase+"TopLeft").h, gfx_Rect.GetSprite(nameBase+"BorderRight").w, Height - gfx_Rect.GetSprite(nameBase+"BottomRight").h - gfx_Rect.GetSprite(nameBase+"TopRight").h)
		gfx_Rect.GetSprite(nameBase+"BorderTop").TileDraw(x + gfx_Rect.GetSprite(nameBase+"TopLeft").w, y, width - gfx_Rect.GetSprite(nameBase+"TopLeft").w - gfx_Rect.GetSprite(nameBase+"TopRight").w, gfx_Rect.GetSprite(nameBase+"BorderTop").h)
		gfx_Rect.GetSprite(nameBase+"BorderBottom").TileDraw(x + gfx_Rect.GetSprite(nameBase+"BottomLeft").w, y + Height - gfx_Rect.GetSprite(nameBase+"BorderBottom").h, width - gfx_Rect.GetSprite(nameBase+"BottomLeft").w - gfx_Rect.GetSprite(nameBase+"BottomRight").w, gfx_Rect.GetSprite(nameBase+"BorderBottom").h)
		gfx_Rect.GetSprite(nameBase+"Back").TileDraw(x + gfx_Rect.GetSprite(nameBase+"TopLeft").w, y + gfx_Rect.GetSprite(nameBase+"TopLeft").h, width - gfx_Rect.GetSprite(nameBase+"TopLeft").w - gfx_Rect.GetSprite(nameBase+"TopRight").w, Height - gfx_Rect.GetSprite(nameBase+"TopLeft").h - gfx_Rect.GetSprite(nameBase+"BottomLeft").h)
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
		return TFunctions.IsIn( x,y, Self.StartPos.GetX(), Self.StartPos.GetY(), Self.rect.GetW(), Self.rect.getH() )
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

	Method Enable()
		Self.fadecount = 1
		Self.fadeenabled = True
		Self.fadeout = False
	End Method

	Method EnableFadeout()
		Self.fadecount = 20
		Self.fadeenabled = True
		Self.fadeout = True
	End Method

	Method Update(deltaTime:float=1.0)
		If Self.fadecount > 20
			Self.fadecount = 20
		ElseIf Self.fadecount >= 0 And Self.fadeenabled
			Self.fadecount:+(0.75 - 1.5 * Self.fadeout)
		ElseIf Self.fadecount < 0
			Self.fadecount = -1
			Self.fadeenabled = False
		EndIf
	End Method

	Method Draw(deltaTime:float=1.0)
		If Self.fadecount >= 0 And Self.fadeenabled
			SetColor 0, 0, 0;SetAlpha Self.fadecount / 20
			DrawRect(20,10,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(400+(20-Self.fadecount)*19,10,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(20,195+(20-Self.fadecount)*19,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(400+(20-Self.fadecount)*19,195+(20-Self.fadecount)*19,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			SetColor 255,255,255;SetAlpha 1
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
		if obj.sprite = null then obj.sprite = Assets.GetSprite("gfx_errorbox")
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
		If Mousemanager.IsHit(1)
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
		Assets.GetFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.w - 60, 40, 0, 150, 50, 50)
		Assets.GetFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.w-40, sprite.h-60,0,50,50,50)
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
		self._highlighted = 0
		If functions.MouseIn( x, y, w, Assets.GetFont("Default", 12).getBlockHeight(Self._text, w, h))
			self._highlighted = 1
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
			Assets.GetFont("Default", 12, BoldFont).drawBlock(Self._text, x+9, y-1, w-10, h,0, 0, 0, 0)
		else
			SetColor 0,0,0
			DrawOval(x, y +3, 6, 6)
			Assets.GetFont("Default", 12).drawBlock(Self._text, x+10, y, w-10, h,0, 100, 100, 100)
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
		Local ydisplace:Float = Assets.GetFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit
		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(x + 9, y + ydisplace, w - 9, h, clicked)
			If returnValue <> - 1 Then _goTo = returnValue
			ydisplace:+Assets.GetFont("Default", 14).getHeight(answer._text) + 2
		Next
		Return _goTo
	End Method

	Method Draw(x:Float, y:Float, w:Float, h:Float)
		Local ydisplace:Float = Assets.GetFont("Default", 14).drawBlock(Self._text, x, y, w, h).getY()
		ydisplace:+15 'displace answers a bit

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			answer.Draw(x, y + ydisplace, w, h)
			ydisplace:+Assets.GetFont("Default", 14).getHeight(answer._text) + 2
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

			Local returnValue:Int = TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Update(self._rect.GetX() + 10, self._rect.GetY() + 10, self._rect.GetW() - 60, self._rect.GetH(), clicked)
			If returnValue <> - 1 Then nextText = returnValue
		EndIf
		_currentText = nextText
		If _currentText = -2 Then _currentText = 0;Return 0
		Return 1
	End Method

	Method Draw()
		SetColor 255, 255, 255
	    DrawDialog(Assets.GetSpritePack("gfx_dialog"), self._rect.GetX(), self._rect.GetY(), self._rect.GetW(), self._rect.GetH(), "StartLeftDown", 0, "", Assets.GetFont("Default", 14))
		SetColor 0, 0, 0
		If Self._texts.Count() > 0 Then TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Draw(self._rect.GetX() + 10, self._rect.GetY() + 10, self._rect.GetW() - 60, self._rect.GetH())
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
		Interface.CurrentNoise				= Assets.GetSprite("gfx_interface_TVprogram_noise1")
		Interface.CurrentProgramme			= Assets.GetSprite("gfx_interface_TVprogram_none")
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
			If Game.GetMinute() >= 55
				Local adblock:TAdBlock = Game.Players[ShowChannel].ProgrammePlan.GetCurrentAdBlock()
				Interface.CurrentProgramme = Assets.GetSprite("gfx_interface_TVprogram_ads")
			    If adblock <> Null
					CurrentProgrammeToolTip.TitleBGtype = 1
					CurrentProgrammeText 				= getLocale("ADVERTISMENT")+": "+adblock.contract.contractBase.title
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText				= getLocale("BROADCASTING_OUTAGE")
				EndIf
			Else
				Local block:TProgrammeBlock = Game.Players[ShowChannel].ProgrammePlan.GetCurrentProgrammeBlock()
				Interface.CurrentProgramme = Assets.GetSprite("gfx_interface_TVprogram_none")
				If block <> Null
					Interface.CurrentProgramme = Assets.GetSprite("gfx_interface_TVprogram_" + block.Programme.genre, "gfx_interface_TVprogram_none")
					CurrentProgrammeToolTip.TitleBGtype	= 0
					if block.programme.parent <> null
						CurrentProgrammeText = block.programme.parent.title + ": "+ block.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.GetHour()-(block.sendhour - game.GetDay()*24))+"/"+block.Programme.blocks+")"
					else
						CurrentProgrammeText = block.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.GetHour()-(block.sendhour - game.GetDay()*24))+"/"+block.Programme.blocks+")"
					endif
				Else
					CurrentProgrammeToolTip.TitleBGtype	= 2
					CurrentProgrammeText 				= getLocale("BROADCASTING_OUTAGE")
				EndIf
			EndIf
			If Game.GetMinute() <= 5
				Interface.CurrentProgramme = Assets.GetSprite("gfx_interface_TVprogram_news")
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
			If randomnoise = 0 Then CurrentNoise = Assets.GetSprite("gfx_interface_TVprogram_noise1")
			If randomnoise = 1 Then CurrentNoise = Assets.GetSprite("gfx_interface_TVprogram_noise2")
			If randomnoise = 2 Then CurrentNoise = Assets.GetSprite("gfx_interface_TVprogram_noise3")
			If randomnoise = 3 Then CurrentNoise = Assets.GetSprite("gfx_interface_TVprogram_noise4")
			ChangeNoiseTimer = 0.0
			NoiseAlpha = 0.45 - (Rand(0,10)*0.01)
		EndIf

		If functions.IsIn(MouseManager.x,MouseManager.y,20,385,280,200)
			CurrentProgrammeToolTip.title 		= CurrentProgrammeText
			If ShowChannel <> 0
				CurrentProgrammeToolTip.text	= getLocale("AUDIENCE_RATING")+": "+Game.Players[ShowChannel].GetFormattedAudience()+ " (MA: "+functions.convertPercent(Game.Players[ShowChannel].GetRelativeAudiencePercentage(),2)+"%)"

				'show additional information if channel is player's channel
				if ShowChannel = Game.playerID
					If Game.GetMinute() >= 5 and Game.GetMinute() < 55
						Local adblock:TAdBlock = Game.Players[ShowChannel].ProgrammePlan.GetCurrentAdBlock()
						if adblock
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+":~n" + adblock.contract.contractBase.title+" (Mindestz.: "+functions.convertValue(String( adblock.contract.GetMinAudience() ))+")"
						else
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_ADBLOCK")+": nicht gesetzt!"
						endif
					elseif Game.GetMinute()>=55 OR Game.GetMinute()<5
						Local programmeblock:TProgrammeBlock = Game.Players[ShowChannel].ProgrammePlan.GetCurrentProgrammeBlock()
						if programmeblock
							CurrentProgrammeToolTip.text :+ "~n ~n"+getLocale("NEXT_PROGRAMME")+":~n"
							if programmeblock.programme.parent <> null
								CurrentProgrammeToolTip.text :+ programmeblock.programme.parent.title + ": "+ programmeblock.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.GetHour()-(programmeblock.sendhour - game.GetDay()*24))+"/"+programmeblock.Programme.blocks+")"
							else
								CurrentProgrammeToolTip.text :+ programmeblock.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.GetHour()-(programmeblock.sendhour - game.GetDay()*24))+"/"+programmeblock.Programme.blocks+")"
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
		If functions.IsIn(MouseManager.x,MouseManager.y,355,468,130,30)
			CurrentAudienceToolTip.title 	= getLocale("AUDIENCE_RATING")+": "+Game.Players[Game.playerID].GetFormattedAudience()+ " (MA: "+functions.convertPercent(Game.Players[Game.playerID].GetRelativeAudiencePercentage(),2)+"%)"
			CurrentAudienceToolTip.text  	= getLocale("MAX_AUDIENCE_RATING")+": "+functions.convertValue(Int((Game.Quotes.maxAudiencePercentage * Game.Players[Game.playerID].maxaudience)),2,0)+ " ("+(Int(Ceil(1000*Game.Quotes.maxAudiencePercentage)/10))+"%)"
			CurrentAudienceToolTip.enabled 	= 1
			CurrentAudienceToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = true
		EndIf
		If functions.IsIn(MouseManager.x,MouseManager.y,355,533,130,45)
			CurrentTimeToolTip.title 	= getLocale("GAME_TIME")+": "
			CurrentTimeToolTip.text  	= Game.GetFormattedTime()+" "+getLocale("DAY")+" "+Game.GetDayOfYear()+"/"+Game.daysPerYear+" "+Game.GetYear()
			CurrentTimeToolTip.enabled 	= 1
			CurrentTimeToolTip.Hover()
			'force redraw
			CurrentTimeToolTip.dirtyImage = true
		EndIf
		If functions.IsIn(MouseManager.x,MouseManager.y,355,415,130,30)
			MoneyToolTip.title 	= getLocale("MONEY")
			MoneyTooltip.text	= getLocale("MONEY")+": "+Game.Players[Game.playerID].GetMoney() + getLocale("CURRENCY")
			Moneytooltip.text	:+ "~n"
			Moneytooltip.text	:+ getLocale("DEBT")+": "+ Game.Players[Game.playerID].GetCreditCurrent() + getLocale("CURRENCY")
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
		Assets.GetSprite("gfx_interface_top").Draw(0,0)
		Assets.GetSprite("gfx_interface_leftright").DrawClipped(0, 20, 0, 20, 27, 363, 0, 0)
		SetBlend SOLIDBLEND
		Assets.GetSprite("gfx_interface_leftright").DrawClipped(780 - 27, 20, 780, 20, 20, 363, 0, 0)

		If BottomImgDirty
			Local NoDX9moveY:Int = 383

			SetBlend MASKBLEND
			'draw bottom, aligned "bottom"
			Assets.GetSprite("gfx_interface_bottom").Draw(0,App.settings.getHeight(),0,1)

			If ShowChannel <> 0 Then Assets.GetSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
		    For Local i:Int = 0 To 4
				If i = ShowChannel
					Assets.GetSprite("gfx_interface_channelbuttons_on"+i).Draw(75 + i * 33, 171 + NoDX9moveY, i)
				Else
					Assets.GetSprite("gfx_interface_channelbuttons_off"+i).Draw(75 + i * 33, 171 + NoDX9moveY, i)
				EndIf
		    Next
			If ShowChannel <> 0
				'If CurrentProgram = Null Then Print "ERROR: CurrentProgram is missing"
				CurrentProgramme.Draw(49, 403 - 383 + NoDX9moveY)

				Local audiencerate:Float	= Float(Game.Players[ShowChannel].audience2.GetSum() / Float(Game.Quotes.maxAudiencePercentage * Game.Players[Game.playerID].maxaudience))
				Local girl_on:Int 			= 0
				Local grandpa_on:Int		= 0
				Local teen_on:Int 			= 0
				If audiencerate > 0.4 And (Game.GetHour() < 21 And Game.GetHour() > 6) Then girl_on = True
				If audiencerate > 0.1 Then grandpa_on = True
		  		If audiencerate > 0.3 And (Game.GetHour() < 2 Or Game.GetHour() > 11) Then teen_on = True
				If teen_on And grandpa_on
					Assets.GetSprite("gfx_interface_audience_teen").Draw(570, 419 - 383 + NoDX9moveY)    'teen
					Assets.GetSprite("gfx_interface_audience_grandpa").Draw(650, 419 - 383 + NoDX9moveY)      'teen
				ElseIf grandpa_on And girl_on And Not teen_on
					Assets.GetSprite("gfx_interface_audience_girl").Draw(570, 419 - 383 + NoDX9moveY)      'teen
					Assets.GetSprite("gfx_interface_audience_grandpa").Draw(650, 419 - 383 + NoDX9moveY)       'teen
				Else
					If teen_on Then Assets.GetSprite("gfx_interface_audience_teen").Draw(670, 419 - 383 + NoDX9moveY)
					If girl_on Then Assets.GetSprite("gfx_interface_audience_girl").Draw(550, 419 - 383 + NoDX9moveY)
					If grandpa_on Then Assets.GetSprite("gfx_interface_audience_grandpa").Draw(610, 419 - 383 + NoDX9moveY)
					If Not grandpa_on And Not girl_on And Not teen_on
						SetColor 50, 50, 50
						SetBlend MASKBLEND
						Assets.GetSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)
						SetColor 255, 255, 255
		    	    EndIf
				EndIf
			EndIf 'showchannel <>0

	  		SetBlend MASKBLEND
	     	Assets.GetSprite("gfx_interface_audience_overlay").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
			Assets.GetFont("Default", 13, BOLDFONT).drawBlock(Game.Players[Game.playerID].GetMoneyFormatted() + "  ", 377, 427 - 383 + NoDX9moveY, 103, 25, 2, 200,230,200, 0, 2)
			Assets.GetFont("Default", 13, BOLDFONT).drawBlock(Game.Players[Game.playerID].GetFormattedAudience() + "  ", 377, 469 - 383 + NoDX9moveY, 103, 25, 2, 200,200,230, 0, 2)
		 	Assets.GetFont("Default", 11, BOLDFONT).drawBlock((Game.daysPlayed+1) + ". Tag", 366, 555 - 383 + NoDX9moveY, 120, 25, 1, 180,180,180, 0, 2)
		EndIf 'bottomimg is dirty

		SetBlend ALPHABLEND
		Assets.GetSprite("gfx_interface_antenna").Draw(111,329)

		If ShowChannel <> 0
			SetAlpha NoiseAlpha
			If CurrentNoise = Null Then Print "ERROR: CurrentNoise is missing"
			CurrentNoise.Draw(50, 404)
			SetAlpha 1.0
		EndIf
		SetAlpha 0.25
		Assets.GetFont("Default", 13, BOLDFONT).drawBlock(Game.GetFormattedTime() + " Uhr", 366, 542, 120, 25, 1, 180, 180, 180)
		SetAlpha 0.9
		Assets.GetFont("Default", 13, BOLDFONT).drawBlock(Game.GetFormattedTime()+ " Uhr", 365,541,120,25,1, 40,40,40)
		SetAlpha 1.0
   		CurrentProgrammeToolTip.Draw()
	    CurrentAudienceToolTip.Draw()
   		CurrentTimeToolTip.Draw()
	    BettyToolTip.Draw()
   		MoneyToolTip.Draw()
	    GUIManager.Draw("InGame")

		If Game.error >=1 Then TError.DrawErrors()
		If Game.cursorstate = 0 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y		,0)
		If Game.cursorstate = 1 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-7, 	MouseManager.y-4	,1)
		If Game.cursorstate = 2 Then Assets.GetSprite("gfx_mousecursor").Draw(MouseManager.x-10,	MouseManager.y-12	,2)
	End Method

End Type








'----stations
'Stationmap
'provides the option to buy new stations
'functions are calculation of audiencesums and drawing of stations

Type TStation
	field pos:TPoint
	Field reach:Int=0
	Field price:Int
	Field owner:Int = 0
	Field id:Int = 0
	Global lastID:Int = 0


	Function Create:TStation(x:Int,y:Int, reach:Int, price:Int, owner:Int)
		Local obj:TStation = New TStation
		obj.pos = TPoint.Create(x,y)
		obj.reach = reach
		obj.price = price
		obj.owner = owner
		obj.id = obj.GetNewID()
		Return obj
	End Function

	Method GetNewID:Int()
		Self.lastID:+1
		Return Self.lastID
	End Method

	Method Reset()
		self.reach = 0
		self.pos.SetXY(-1,-1)
		self.owner = -1
		self.price = 0
	End Method

	Method getPrice:int()
		self.price = self.calculatePrice(self.reach)
		return self.price
	End Method

	Function calculatePrice:Int(summe:Int)
		return Max( 25000, Int(Ceil(summe / 10000)) * 25000 )
	End Function

	Function Load:TStation(pnode:TxmlNode)
print "implement Load:TStation"
return null
rem
		Local station:TStation= New TStation
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(Station)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "extra" And Upper(t.name()) = NODE.name
					t.Set(Station, nodevalue)
				EndIf
			Next
			Node = Node.NextSibling()
		Wend
	Return station
endrem
  End Function


	Method Save()
		LoadSaveFile.xmlBeginNode("STATION")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "extra" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
			Next
		LoadSaveFile.xmlCloseNode()
  End Method

	Method Draw()
		Local antennaNr:string = ""
		Local radius:Int = StationMap.radius
		SetAlpha 0.3
		Select owner
			Case 1,2,3,4	Game.Players[owner].color.SetRGB()
							antennaNr = "stationmap_antenna"+owner
			Default			SetColor 255, 255, 255
							antennaNr = "stationmap_antenna0"
		End Select
		DrawOval(pos.x - radius + 20, pos.y - radius + 10, 2 * radius, 2 * radius)
		SetColor 255,255,255
		SetAlpha 1.0
		Assets.GetSprite(antennaNr).Draw(pos.x + 20, pos.y + 10 + radius - Assets.GetSprite(antennaNr).h - 2, -1,0,0.5)
	End Method


End Type

Type TStationMapSection
	field pos:TPoint
	field sprite:TGW_Sprites
	field name:string
	global sections:TList = CreateList()

	Method Create:TStationMapSection(pos:TPoint, name:string, sprite:TGW_Sprites)
		self.pos = pos
		self.name = name
		self.sprite = sprite
		return self
	End Method

	Method Add()
		self.sections.addLast(self)
	End Method
end Type

Type TStationPoint
	field pos:TPoint
	field color:Int

	Function Create:TStationPoint(x:Int, y:Int, color:Int)
		Local obj:TStationPoint = New TStationPoint
		obj.pos = TPoint.Create(x,y)
		obj.color = color
		Return obj
	End Function
End Type

EventManager.registerListener( "LoadResource.STATIONMAP",	TEventListenerRunFunction.Create(TStationMap.onLoadStationMapConfiguration)  )
Type TStationMap
	Field StationList:TList	= CreateList()
	Field radius:Int		= 15		{saveload = "normal"}
	Field einwohner:Int		= 0			{saveload = "normal"}
	Field LastStation:TStation			{saveload = "normal"}
	Field LastCalculatedAudienceIncrease:int = -1
	Field action:Int		= 0			{saveload = "normal"}	'2= station buying (another click on the map buys the station)
																'1= searching a station
	Field populationmap:Int[5,5]
	field populationMapSize:TPoint = TPoint.Create()
	Field bundesland:String = "" {saveload = "normal"}	'mouse over state
	Field outsideLand:Int = 0

	Field sellStation:TStation[5]
	Field buyStation:TStation[5]
	Field filter_ShowStations:Int[5]
	Field StationShare:Int[4, 3]

    field baseStationSprite:TGW_Sprites

	Global List:TList = CreateList()

	Function Load:TStationmap(pnode:TxmlNode)
print "implement Load:TStationmap"
return null
rem
		Local StationMap:TStationMap = New TStationMap
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(StationMap)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" And Upper(t.name()) = NODE.name
					t.Set(StationMap, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "STATION"
							    Local station:TStation = TStation.Load(NODE)
		    					If station <> Null Then PrintDebug("TStationmap.load()", "Station zur Stationmap hinzugefuegt", DEBUG_SAVELOAD) ;StationMap.StationList.AddLast(station)
			End Select
			NODE = NODE.nextSibling()
		Wend
endrem
  End Function

	Function LoadAll()
		PrintDebug("TStationMap.LoadAll()", "Lade StationMaps", DEBUG_SAVELOAD)
		TStationMap.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local node:txmlNode = EachIn Children
			If NODE.getName() = "STATIONMAP"
			      TStationMap.Load(NODE)
			EndIf
		Next
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLSTATIONMAPS")
			For Local StationMap:TStationMap = EachIn TStationMap.List
				LoadSaveFile.xmlBeginNode("STATIONMAP")
		 			Local typ:TTypeId = TTypeId.ForObject(StationMap)
					For Local t:TField = EachIn typ.EnumFields()
						If t.MetaData("saveload") = "normal" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(StationMap)))
					Next
					For Local station:TStation = EachIn StationMap.StationList
						If station <> Null Then station.Save()
					Next
				LoadSaveFile.xmlCloseNode()
		    Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Function Create:TStationMap()
		Local obj:TStationMap=New TStationMap
		local start:int = Millisecs()
		local i:int, j:int

		local pix:TPixmap = Assets.GetPixmap("stationmap_populationDensity")
		local map:int[pix.width + 20, pix.height + 20]
		obj.populationMap = map
		obj.populationMapSize.SetX(pix.width)
		obj.populationMapSize.SetY(pix.height)

		'read all inhabitants of the map
		For i = 0 To pix.width-1
			For j = 0 To pix.height-1
				obj.populationmap[i, j] = obj.getPopulationForBrightness( ARGB_RED(pix.ReadPixel(i, j)) )
				obj.einwohner:+ obj.populationmap[i, j]
			Next
		Next
		Print "StationMap: alle Pixel eingelesen - Einwohner:" + obj.einwohner + " zeit: "+(Millisecs()-start)+"ms"
		EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "Stationmap").AddNumber("itemNumber", 1).AddNumber("maxItemNumber", 1) ) )

		obj.baseStationSprite	= Assets.GetSprite("stationmap_antenna0")
		obj.LastStation			= TStation.Create(-1,-1, 0, 0, -1)

		List.AddLast(obj)
		SortList List
		Return obj
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

		For Local child:TxmlNode = EachIn statesNode.GetChildren()
			local name:string	= xmlLoader.xml.FindValue(child, "name", "")
			local sprite:string	= xmlLoader.xml.FindValue(child, "sprite", "")
			local pos:TPoint	= TPoint.Create( xmlLoader.xml.FindValueInt(child, "x", 0), xmlLoader.xml.FindValueInt(child, "y", 0) )
			'add state section if data is ok
			if name<>"" and sprite<>"" then new TStationMapSection.Create(pos,name, Assets.GetSprite(sprite)).add()
		Next

	End Function


	Method AddStation(x:Int, y:Int, playerid:Int, valuetorefresh:Int Var)
		Local reach:Int = Self.CalculateAudienceIncrease(playerid, x, y)

		'print "StationMap: added station to "+playerID+" reach:"+reach
		StationList.AddLast(TStation.Create(x, y, reach, TStation.calculatePrice(reach), playerid))
		valuetorefresh = CalculateAudienceSum(playerid)
	End Method

    Method Buy(x:Float, y:Float, playerid:Int = 1, fromNetwork:int = false)
		If Game.Players[playerid].finances[Game.getWeekday()].PayStation(self.LastStation.getPrice() )
			Local station:TStation = TStation.Create(LastStation.pos.x,LastStation.pos.y, self.LastStation.reach, self.LastStation.getPrice(), playerid)
			StationList.AddLast(station)
			Print "Player" + playerid + " kauft Station für " + station.price + " Euro (" + station.reach + " Einwohner)"
			Game.Players[playerid].maxaudience = CalculateAudienceSum(playerid)
			'network
			if game.networkgame Then NetworkHelper.SendStationChange(game.playerid, station, Game.Players[game.playerID].maxaudience, 1)
			self.LastStation.Reset()
			Self.buyStation[playerid] = Null
		EndIf
    End Method

	Method SellByPos(pos:TPoint, reach:int, playerID:int)
		for local station:TStation = eachin self.StationList
			if station.pos.isSame(pos) and station.reach = station.reach and station.owner = playerID
				self.sell(station)
				exit
			endif
		Next
	End Method

	Method Sell(station:TStation)
		If Game.Players[station.owner].finances[Game.getWeekday()].SellStation(Floor(station.price * 0.75))
			StationList.Remove(station)
	        Print "Player" + station.owner + " verkauft Station für " + (station.price * 0.75) + " Euro (" + station.reach + " Einwohner)"
			Game.Players[station.owner].maxaudience = CalculateAudienceSum(station.owner) 'auf entsprechenden Player umstellen
			'events ...
			'network
			If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendStationChange(station.owner, station, Game.Players[station.owner].maxaudience, 0)
			LastStation.reset()
			'when station is sold, audience will decrease, atm buy =/= increase ;D
			Game.Players[station.owner].ComputeAudience(1)
		EndIf
    End Method

	Method CalculateStationCosts:Int(owner:Int=0)
		Local costs:Int = 0
		For Local Station:TStation = EachIn StationList
			If station.owner = owner Then costs:+1000 * Ceil(station.price / 50000) ' price / 50 = cost
		Next
		Return costs
	End Method

	Method Update()

		If action = 4 'sell finished?
			If Self.sellStation[Game.playerID] <> Null Then Self.Sell(Self.sellStation[Game.playerID])
			action = 0
		EndIf

		'buying stations
		'1. searching
		If action = 1
			Local pos:TPoint = TPoint.Create(0,0)
			If MOUSEMANAGER.hasMoved
				pos.setXY( MouseManager.x -20, MouseManager.y -10)

				lastStation.reach = Self.CalculateStationRange(pos.X, pos.Y)
				If lastStation.reach > 0
					Self.outsideLand = False 'no antennagraphic in foreign countries
					LastCalculatedAudienceIncrease = CalculateAudienceIncrease(Game.playerid, pos.X, pos.Y)
				else
					pos.setXY( LastStation.pos.X + 20, LastStation.pos.Y + 10)
					Self.outsideLand = True
					LastStation.reach = Self.CalculateStationRange(pos.X, pos.Y)
				EndIf
			Else
				pos.setXY( LastStation.pos.X + 20, LastStation.pos.Y + 10)
			EndIf
		endif
		'2. actually buy it
		If action = 2 And LastStation.pos.X <> 0 And LastStation.pos.y <> 0
			If MOUSEMANAGER.hasMoved Then LastStation.reach = Self.CalculateStationRange(LastStation.pos.X + 20, LastStation.pos.Y + 10)
			Buy(LastStation.pos.X, LastStation.pos.Y, Game.playerID)
			LastStation.Reset()
			action = 0
		EndIf

		If action = 1 'placing a new station
			'only find new if mouse was moved - saves unneeded pixel reads
			if MOUSEMANAGER.hasMoved
				Bundesland = ""
				For local section:TStationMapSection = eachin TStationMapSection.sections
					if TFunctions.MouseIn(section.pos.x, section.pos.y, section.sprite.w, section.sprite.h)
						if section.sprite.PixelIsOpaque(MouseManager.x-section.pos.x, MouseManager.y-section.pos.y) > 0
							'print "	found "+section.name
							Bundesland = Localization.GetString("MAP_COUNTRY_"+section.name)
							exit
						endif
					endif
				Next
			endif
		EndIf

  End Method

	Method DrawStations()
		For Local _Station:TStation = EachIn StationList
			If Self.filter_ShowStations[_Station.owner] Then _Station.Draw()
		Next
		If LastStation.pos.X <> 0 and LastStation.pos.Y <> 0
			SetAlpha 0.2
			SetColor 0,0,0 'replace with a playercolor
			DrawOval(  LastStation.pos.X+20- radius +1, LastStation.pos.Y+10-radius,2*radius,2*radius +1)
			SetAlpha 0.5
			SetColor 255,255,255 'replace with a playercolor
			DrawOval(  LastStation.pos.X+20- radius, LastStation.pos.Y+10-radius,2*radius,2*radius )
			SetAlpha 0.9
			baseStationSprite.draw(LastStation.pos.X+20,LastStation.pos.Y+10+radius-baseStationSprite.h-2, -1,0,0.5)
			SetAlpha 1.0
		EndIf
	End Method

	Method Draw()
		SetColor 255,255,255
		DrawStations()
		If action = 1 And Not Self.outsideLand 'placing a new station
			SetAlpha 0.5
			DrawOval( MouseManager.x- radius,MouseManager.y-radius,2*radius,2*radius )
			SetAlpha 0.9
			baseStationSprite.draw(MouseManager.x, MouseManager.y +radius -baseStationSprite.h-2, -1,0,0.5)
			SetAlpha 1.0
		EndIf
		local font:TBitmapFont = Assets.fonts.baseFont
		If action = 1
			SetColor(0, 0, 0)
			font.draw(bundesland, 595, 35)
			font.draw("Reichweite: ", 595, 52)
				font.drawBlock(functions.convertValue(String(self.LastStation.reach), 2, 0), 660, 52, 102, 20, 0.5)
			font.draw("Zuwachs: ", 595, 69)
				font.drawBlock(functions.convertValue(String(LastCalculatedAudienceIncrease), 2, 0), 660, 69, 102, 20, 2)
			font.draw("Preis: ", 595, 86)
				Assets.fonts.baseFontBold.drawBlock(functions.convertValue(self.LastStation.GetPrice(), 2, 0), 660, 86, 102, 20, 2)
			SetColor(180, 180, 255)
			font.draw(bundesland, 594, 34)
			SetColor(255,255,255)
		EndIf

		If Self.sellStation[Game.playerID] <> Null
			SetColor(0, 0, 0)
			font.draw("Reichweite: ", 595, 197)
				font.drawBlock(functions.convertValue(Self.sellStation[Game.playerID].reach, 2, 0), 660, 197, 102, 20, 2)
			font.draw("Preis: ", 595, 214)
				Assets.fonts.baseFontBold.drawBlock(functions.convertValue(Self.sellStation[Game.playerID].price, 2, 0), 660, 214, 102, 20, 2)
			SetColor(255, 255, 255)
		EndIf

		if game.DebugMode
			For local section:TStationMapSection = eachin TStationMapSection.sections
				if TFunctions.MouseIn(section.pos.x, section.pos.y, section.sprite.w, section.sprite.h)
					if section.sprite.PixelIsOpaque(MouseManager.x-section.pos.x, MouseManager.y-section.pos.y) > 0
						section.sprite.Draw(section.pos.x, section.pos.y)
						exit
					endif
				endif
			Next
		endif

  End Method

	'summary: returns calculated distance between 2 points
	Method calculateDistance:Double(x1:Int, x2:Int)
		Return Sqr((x1*x1) + (x2*x2))
	End Method

	Method getPopulationForBrightness:int(value:int)
		value = Max(5, 255-value)
		value = (value*value)/255 '2 times so low values are getting much lower
		value = (value*value)/255

		If value > 110 Then value :* 2.0
		If value > 140 Then value :* 1.9
		If value > 180 Then value :* 1.3
		If value > 220 Then value :* 1.1	'population in big cities
		return 26.0 * value					'population in general
	End Method

	Method CalculateShareNOTFINISHED:Int(playerA:Int, playerB:Int)
		Local Points:TMap = New TMap
		Local PointsA:TMap = New TMap
		Local PointsB:TMap = New TMap
		Local returnValue:Int = 0
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0

		'add Stations of both players to their corresponding map
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = playerA Or _Station.owner = playerB
				For posX = _Station.pos.x - radius To _Station.pos.x + radius
					For posY = _Station.pos.y - radius To _Station.pos.y + radius
						' noch innerhalb des Kreises?
						If Sqr((posX - _Station.pos.x) ^ 2 + (posY - _Station.pos.y) ^ 2) <= radius
							If _Station.owner = playerA
								pointsA.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							Else
								pointsB.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							EndIf
						EndIf
					Next
				Next
			EndIf
		Next
		'combine both maps
		For Local point:String = EachIn pointsA.Keys()
			Local obj:Object = pointsB.ValueForKey(point)
			If obj <> Null
				points.Insert(point, obj)
			EndIf
		Next

		Local pixel:Int
		Local r:Int
		Local g:Int
		Local b:Int

		'einmal "blaue farbe" einmal "rote" farbe nutzen

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 0 And ARGB_Blue(point.color) = 255
				returnvalue:+ populationmap[point.pos.x, point.pos.y]
			EndIf
		Next
		Return returnvalue
	End Method

	Method _FillPoints(map:TMap var, x:int, y:int, color:int)
		local posX:int=0
		local posY:int=0
		x = Max(0,x)
		y = Max(0,y)
'print "given: x"+x+" y"+y
'print "for posX = "+Max(x - radius,radius)+" To "+Min(x + radius, stationmap_mainpix.width-radius)
'print "	For posY = "+Max(y - radius,radius)+" To "+Min(y + radius, stationmap_mainpix.height-radius)
		' innerhalb des Bildes?
		For posX = Max(x - radius,radius) To Min(x + radius, self.populationMapSize.x-radius)
			For posY = Max(y - radius,radius) To Min(y + radius, self.populationMapSize.y-radius)
				' noch innerhalb des Kreises?
				If self.calculateDistance( posX - x, posY - y ) <= radius
					map.Insert(String((posX) + "," + (posY)), TStationPoint.Create((posX) , (posY), color ))
				EndIf
			Next
		Next
	End Method

	Method CalculateAudienceIncrease:Int(owner:Int = 0, _x:Int, _y:Int)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
		Local returnValue:Int = 0
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0

		'add "new" station which may be bought
		If _x = 0 And _y = 0 Then _x = MouseManager.x - 20; _y = MouseManager.y - 10
		self._FillPoints(Points, _x,_y, ARGB_Color(255, 0, 255, 255))

		'overwrite with stations owner already has - red pixels get overwritten with white,
		'count red at the end for increase amount
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = owner
				If functions.IsIn(_x,_y, _station.pos.x - 2*radius, _station.pos.y - 2 * radius, 4*radius, 4*radius)
					self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
				EndIf
			EndIf
		Next

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 0 And ARGB_Blue(point.color) = 255
				returnvalue:+ populationmap[point.pos.x, point.pos.y]
			EndIf
		Next
		Return returnvalue
	End Method

	'summary: returns maximum audience a player has
	Method CalculateAudienceSum:Int(owner:Int = 0)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = owner
				self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
			EndIf
		Next
		Local returnvalue:Int = 0

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 255 And ARGB_Blue(point.color) = 255
				returnvalue:+ populationmap[point.pos.x, point.pos.y]
			EndIf
		Next
		Return returnvalue
	End Method

	'summary: returns a stations maximum audience reach
	Method CalculateStationRange:Int(x:Int, y:Int)
		Local posX:Int, posY:Int
		Local returnValue:Int = 0
		' für die aktuelle Koordinate die summe berechnen
		' min/max = immer innerhalb des Bildes
		For posX = Max(x - radius,radius) To Min(x + radius, self.populationMapSize.x-radius)
			For posY = Max(y - radius,radius) To Min(y + radius, self.populationMapSize.y-radius)
				' noch innerhalb des Kreises?
				If self.calculateDistance( posX - x, posY - y ) <= radius
					returnvalue:+ populationmap[posX, posY]
				EndIf
			Next
		Next
		Return returnValue
	End Method

End Type
