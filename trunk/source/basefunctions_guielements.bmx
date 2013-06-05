SuperStrict
'Author: Ronny Otto
Import "basefunctions.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_keymanager.bmx"
Import "basefunctions_localization.bmx"
Import "basefunctions_resourcemanager.bmx"
Import "basefunctions_events.bmx"

REM
	Die Objekte sollten statt "function Create:OBJECT"
	eine Methode "Create:OBJECT" benutzen, falls ein Element
	ein anderes "extends", dann in der Methode "super.Create(parameter,...)
	aufrufen
	WICHTIG:	dadurch statt	local obj:Object = Object.Create(parameter)
								local obj:Object = new Object.Create(parameter)
				aufrufen (new instanziert neues Objekt, Create ist nur Methode)
ENDREM


''''''GUIzeugs'
CONST EVENT_GUI_CLICK:int			= 1
CONST EVENT_GUI_DOUBLECLICK:int		= 2
CONST GUI_OBJECT_DRAGGED:int		= 1
CONST GUI_OBJECT_VISIBLE:int		= 2
CONST GUI_OBJECT_ENABLED:int		= 4
CONST GUI_OBJECT_CLICKABLE:int		= 8
CONST GUI_OBJECT_DRAGABLE:int		= 16

CONST GUI_OBJECT_ACCEPTS_DROP:int	= 128

Global gfx_GuiPack:TGW_SpritePack = TGW_SpritePack.Create(LoadImage("grafiken/GUI/guipack.png"), "guipack_pack")
gfx_GuiPack.AddAnimSpriteMultiCol("ListControl", 96, 0, 56, 28, 14, 14, 8)
gfx_GuiPack.AddAnimSpriteMultiCol("DropDown", 160, 0, 126, 42, 14, 14, 21)
gfx_GuiPack.AddSprite("Slider", 0, 30, 112, 14, 8)
gfx_GuiPack.AddSprite("Chat_IngameOverlay", 0, 60, 504, 20)

Type TGUIManager
	Field Defaultfont:TBitmapFont
	Field globalScale:Float		= 1.0
	Field MouseIsHit:Int 		= 0
	Field MouseIsDown:Int 		= 0
	Field MouseIsDownTime:Int	= 0
	Field currentState:string	= ""			'which state are we currently handling?
	Field List:TList			= CreateList()
	Field ListReverse:TList		= CreateList()
	global viewportX:int=0,viewportY:int=0,viewportW:int=0,viewportH:int=0

	Function Create:TGUIManager()
		Local obj:TGUIManager = New TGUIManager

		'is something dropping on a gui element?
		EventManager.registerListenerFunction( "guiobject.onDrop",	TGUIManager.onDrop )


		Return obj
	End Function

	Function onDrop:int( triggerEvent:TEventBase )
		local guiobject:TGUIObject = TGUIObject(triggerEvent.GetSender())
		if guiobject = Null then return FALSE

		local data:TData = triggerEvent.GetData()
		if not data then return FALSE

		'find out if it hit a list...
		local coord:TPoint = TPoint( data.get("coord") )
		local dropTarget:TGuiObject = GUIManager.GetObjectByPos( coord, NULL, TRUE, GUI_OBJECT_ACCEPTS_DROP )

		'if we found a dropTarget - emit an event
		if dropTarget<>Null
			'print "sendEvent: guiobject.onDropOnTarget for object " + TTypeId.ForObject(dropTarget).Name()+" ["+dropTarget._id+"]"
			local event:TEventSimple = TEventSimple.Create( "guiobject.onDropOnTarget", TData.Create().AddObject("coord", coord) , guiobject, dropTarget )
			EventManager.triggerEvent( event )
			'if there is a veto happening (dropTarget does not want the item)
			'also veto the onDrop-event
			if event.isVeto() then triggerEvent.setVeto()
		'no dropTarget found
		else
			triggerEvent.setVeto()
		endif
	End Function

	Method RestrictViewport(x:int,y:int,w:int,h:int)
		GetViewport(viewportX,viewportY,viewportW,viewportH)
		SetViewport(x,y,w,h)
	End Method

	Method ResetViewport()
		SetViewport(viewportX,viewportY,viewportW,viewportH)
	End Method

	Method Add(GUIobject:TGUIobject)
		Self.List.AddLast(GUIobject)
		Self.ListReverse.AddFirst(GUIobject)
		Self.SortList()
	End Method

	Function SortObjects:Int(ob1:Object, ob2:Object)
		Local objA:TGUIobject = TGUIobject(ob1)
		Local objB:TGUIobject = TGUIobject(ob2)

		'undefined object - move at the end of the list
		If not objB Then Return 1

		'if objA is a dragged element - move to top
		If objA._flags & GUI_OBJECT_DRAGGED
			'if both are dragged, sort by higher number
			if objA._timeDragged < objB._timeDragged then Return -1
			Return 1
		endif

		'if objA is active element - move to top
		If GUIManager.getActive() = objA._id then Return 1

		'if objA is invisible, move to to end
		if not(objA._flags & GUI_OBJECT_VISIBLE) then Return -1

		'if objB is "higher", move it to the top
		if objB.zIndex > objA.zIndex then Return -1
		'if objB is "same height", do not move at all
		if objB.zIndex = objA.zIndex then Return 0
		'move to the end
		return 1
	End Function

	Method SortList()
		Self.List.sort(True, Self.SortObjects)
		Self.ListReverse.sort(False, Self.SortObjects)
	End Method

	Method isActive:Int(id:Int)
		Return id = TGUIObject._activeID
	End Method

	Method getActive:Int()
		Return TGUIObject._activeID
	End Method

	Method setActive(id:Int)
		TGUIObject._activeID = id
	End Method

	Method Remove(guiobject:TGUIObject)
		Self.List.remove(guiobject)
		Self.ListReverse.remove(GUIobject)
		Self.SortList()
	End Method


	'returns whether an object is hidden/invisible/inactive and therefor
	'does not have to get handled now
	Method haveToHandleObject:int(obj:TGUIObject, State:string="", fromZ:Int=-1000, toZ:Int=-1000)
		'skip if parent has not to get handled
		if(obj._parent <> null and not self.haveToHandleObject(obj._parent,State,fromZ,toZ)) then return FALSE

		'skip if not visible
		if not(obj._flags & GUI_OBJECT_VISIBLE) then return FALSE

		'skip if not visible by zindex
		If not ( (toZ = -1000 Or obj.zIndex <= toZ) And (fromZ = -1000 Or obj.zIndex >= fromZ)) then return FALSE

		'limit display by state - skip if object is hidden in that state
		If (State<>"" AND State <> obj.GetLimitToState() And obj.GetLimitToState() <> "") then return FALSE

		return TRUE
	End Method

	Method GetObjectByPos:TGuiObject(coord:TPoint, limitState:string=Null, ignoreDragged:int=TRUE, requiredFlags:int=0)
		if limitState=null then limitState = self.currentState

		'from bottom to top - bottom has biggest "area" to hit
		For Local obj:TGUIobject = EachIn Self.List
			if not self.haveToHandleObject(obj, limitState) then continue

			'avoids finding the dragged object on a drop-event
			if not ignoreDragged and obj.isDragged() then continue
			'if obj is required to accept drops, but does not so  - continue
			if (requiredFlags & GUI_OBJECT_ACCEPTS_DROP) and not(obj._flags & GUI_OBJECT_ACCEPTS_DROP) then continue

			if obj.getRect().containsXY( coord.getX(), coord.getY() ) then return obj
		Next

		return Null
	End Method


	Method Update(State:String = "", updatelanguage:Int = 0, fromZ:Int=-1000, toZ:Int=-1000)
		self.currentState = State

		'store mouse button 1 state
		If MOUSEMANAGER.IsHit(1) Then MouseIsHit = 1 Else MouseIsHit = 0
		If MOUSEMANAGER.IsDown(1)
			MouseIsDown = 1
			'store time when first mousedown happened
			if self.MouseIsDownTime = 0 then self.MouseIsDownTime = millisecs()
		Else
			MouseIsDown = 0
			self.MouseIsDownTime = 0
		endif
		
		local foundClickObject:int = FALSE
		local foundHoverObject:int = FALSE
		local foundDraggedObject:int=TGUIobject(self.list.last()).isDragged()

		For Local obj:TGUIobject = EachIn Self.ListReverse 'from top to bottom
			if not self.haveToHandleObject(obj,State,fromZ,toZ) then continue

			'always be above parent
			if obj._parent and obj._parent.zIndex >= obj.zIndex then obj.setZIndex(obj._parent.zIndex+10)

			if obj._flags & GUI_OBJECT_CLICKABLE
				If Not functions.isIn( MouseX(), MouseY(), obj.GetX(), obj.GetY(), obj.GetWidth(), obj.GetHeight() )
					obj.mouseIsDown		= null
					obj.mouseIsClicked	= null
					obj.mouseover		= 0
					obj.setState("")
					'mouseclick somewhere - should deactivate active button
					If self.MouseIsHit And obj.isActive()
						self.setActive(0)
						'print Millisecs() +": set INactive " + TTypeId.ForObject( obj ).name() + string(" [ID:"+(obj._id)+"]")
					endif
				EndIf
				'no rect.intersects as GetX and GetY add parent position
				If (foundDraggedObject=FALSE or obj.isDragged()) AND..
				   functions.isIn(MouseX(), MouseY(), obj.GetX(), obj.GetY(), obj.GetWidth(), obj.GetHeight())
					'activate objects - or skip if if one gets active
					If self.MouseIsDown And obj._flags & GUI_OBJECT_ENABLED
						'create a new "event"
						if obj.MouseIsDown = null 'if self.getActive() <> obj._id
							self.setActive(obj._id)
							'print Millisecs() +": set active/clicked " + TTypeId.ForObject( obj ).name() + string(" [ID:"+(obj._id)+"]")
							obj.EnterPressed = 1
							obj.MouseIsDown = TPoint.Create( MouseX(), MouseY() )
						endif

						'we found a gui element which can accept clicks
						'dont check further guiobjects
						self.MouseIsDown = 0
					EndIf

					if not foundHoverObject and obj._flags & GUI_OBJECT_ENABLED
						'create events
						if obj.mouseover = 0 then EventManager.registerEvent( TEventSimple.Create( "guiobject.OnMouseEnter", TData.Create(), obj ) )
						EventManager.registerEvent( TEventSimple.Create( "guiobject.OnMouseOver", TData.Create(), obj ) )
						obj.mouseover = 1
'						print "over "+obj.className
						foundHoverObject = TRUE

						If self.MouseIsDown Or obj.MouseIsDown
							obj.setState("active")
							EventManager.registerEvent( TEventSimple.Create( "guiobject.OnMouseDown", TData.Create().AddNumber("type", 1), obj ) )
						Else
							obj.setState("hover")
						endif

						If MOUSEMANAGER.isUp(1) And obj.MouseIsDown
							if not foundClickObject
								obj.mouseIsClicked = TPoint.Create( MouseX(), MouseY() )
								If obj._flags & GUI_OBJECT_ENABLED
									'fire onClickEvent
									EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", TData.Create().AddNumber("type", 1), obj ) )
									'print ".onclick " +obj.className + " ["+obj._id+"]"
								endif
								'added for imagebutton and arrowbutton not being reset when mouse standing still
								obj.MouseIsDown = null
								foundClickObject = TRUE
							endif
						EndIf
					endif

				EndIf
			EndIf
			If obj.value = "" Then obj.value = "  "
			If obj.backupvalue = "x" Then obj.backupvalue = obj.value
			If updatelanguage Or Chr(obj.value[0] ) = "_" Then If Chr(obj.backupvalue[0] ) = "_" Then obj.value = Localization.GetString(Right(obj.backupvalue, Len(obj.backupvalue) - 1))

			'run custom guiobject update
			obj.Update()

			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onUpdate", null, obj ) )

		Next
	End Method

	Method DisplaceGUIobjects(State:String = "", x:Int = 0, y:Int = 0)
		For Local obj:TGUIobject = EachIn Self.List
			If State = obj.GetLimitToState() then obj.rect.position.MoveXY( x,y )
		Next
	End Method

	Method Draw:Int(State:String = "", updatelanguage:Int = 0, fromZ:Int=-1000, toZ:Int=-1000)
		self.currentState = State

		For Local obj:TGUIobject = EachIn Self.List
			if not self.haveToHandleObject(obj,State,fromZ,toZ) then continue

			obj.Draw()
			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", TData.Create(), obj ) )
		Next
	End Method

End Type

Global GUIManager:TGUIManager = TGUIManager.Create()


Type TGUIobject
	Field rect:TRectangle			= TRectangle.Create(-1,-1,-1,-1)
	Field zIndex:Int					
	Field scale:Float				= 1.0
	Field align:Int					= 0 			'alignment of object
	Field valign:Int				= 0 			'vertical-alignment of object
	Field state:String				= ""
	Field value:String				= ""
	Field backupvalue:String		= "x"
	Field mouseIsClicked:TPoint		= null			'null = not clicked
	Field mouseIsDown:TPoint		= TPoint.Create(-1,-1)
	Field EnterPressed:Int=0
	Field mouseover:Int				= 0			'could be done with TPoint
	Field _id:Int
	Field _flags:int				= 0
	Field _timeDragged:int			= 0			'time when item got dragged, maybe find a better name
	field _parent:TGUIobject		= null
	Field _limitToState:String		= ""		'fuer welchen gamestate anzeigen
	Field useFont:TBitmapFont
	Field className:string			= ""
	global _activeID:int			= 0
	global _lastID:int

	Method New()
		self._id	= self.GetNextID()
		self.scale	= GUIManager.globalScale
		Self.useFont = GUIManager.defaultFont
		self.className = TTypeId.ForObject(self).Name()

		'default options
		self.setOption(GUI_OBJECT_VISIBLE, TRUE)
		self.setOption(GUI_OBJECT_ENABLED, TRUE)
		self.setOption(GUI_OBJECT_CLICKABLE, TRUE)
	End Method

	Method getClassName:string()
		return self.className
	End Method

	Method CreateBase:TGUIobject(x:float,y:float, limitState:string="", useFont:TBitmapFont=null)
		If useFont <> Null Then Self.useFont = useFont
		self.rect.position.setXY( x,y )
		self._limitToState = limitState
	end Method

	Method RestrictViewport()
		GUIManager.RestrictViewport(self.getX(),self.getY(), self.rect.getW(),self.rect.getH())
	End Method

	Method ResetViewport()
		GUIManager.ResetViewport()
	End Method

	Method getOption:int(option:int)
		return self._flags & option
	End Method

	Method setOption(option:int, enable:int=TRUE)
		if enable
			self._flags :| option
		else
			self._flags :& ~option
		endif
	End Method

	Method isDragable:int()
		return self._flags & GUI_OBJECT_DRAGABLE
	End Method

	Method isDragged:int()
		return self._flags & GUI_OBJECT_DRAGGED
	End Method


	Method Show()
		self._flags :| GUI_OBJECT_VISIBLE
	End Method

	Method Hide()
		self._flags :& ~GUI_OBJECT_VISIBLE
	End Method

	Method enable()
		self._flags :| GUI_OBJECT_ENABLED
		GUIManager.SortList()
	End Method

	Method disable()
		self._flags :& ~GUI_OBJECT_ENABLED
		GUIManager.SortList()
	End Method

	Method isActive:int()
		return self._id = self._activeID
	End Method

	Method SetZIndex(zindex:Int)
		Self.zIndex = zindex
		GUIManager.SortList()
	End Method

	Method SetState(state:String="")
		If state <> "" Then state = "."+state
		Self.state = state
	End Method


	Method drag:int(coord:TPoint=Null)
		if not self.isDragable() or self.isDragged() then return FALSE
		
		'trigger an event immediately - if the event has a veto afterwards, do not drag!
		local event:TEventSimple = TEventSimple.Create( "guiobject.onDrag", TData.Create().AddObject("coord", coord), self )
		EventManager.triggerEvent( event )
		if event.isVeto() then return FALSE

		'nobody said no to "drag", so do it
		self.setOption(GUI_OBJECT_DRAGGED, TRUE)

		GUIManager.SortList()

		return TRUE
	End Method

	Method drop:int(coord:TPoint=Null)
		if not self.isDragged() then return FALSE

		if coord and coord.getX()=-1 then coord = TPoint.Create(MouseX(), MouseY())

		'fire an event - if the event has a veto afterwards, do not drag!
		local event:TEventSimple = TEventSimple.Create( "guiobject.onDrop", TData.Create().AddObject("coord", coord), self )
		EventManager.triggerEvent( event )
		if event.isVeto() then return FALSE

		'nobody said no to "drop", so do it
		self.setOption(GUI_OBJECT_DRAGGED, FALSE)

		GUIManager.SortList()
		return TRUE
	End Method
	
	Method setParent:int(parent:TGUIobject)
		self._parent = parent
	End Method

	Method SetSelfManaged()
		GuiManager.Remove(self)
	End Method

	Function GetNextID:Int()
		TGUIobject._lastID:+1
		Return TGUIobject._lastID
	End Function

	'returns true if clicked
	'resets clicked value!
	Method getClicks:Int()
		if not(self._flags & GUI_OBJECT_ENABLED) Then Self.mouseIsClicked = null

		if self.mouseIsClicked
			self.mouseIsClicked = null
			return 1
		else
			return 0
		endif
	End Method

	Method GetLimitToState:string()
		'if there is no limit set - ask parent if there is one
		if self._limitToState="" and self._parent then return self._parent.GetLimitToState()

		return self._limitToState
	End Method

	Method GetWidth:float()
		return self.rect.GetW()
	End Method

	Method GetHeight:float()
		return self.rect.GetH()
	End Method

	Method GetRect:TRectangle()
		'if obj has a parent, use the parent's starting coordinates
		if self._parent <> null
			return TRectangle.Create(self.GetX(), self.GetY(), self.rect.GetW(), self.rect.GetH() )
		else
			return self.rect
		endif
	End Method

	'adds parent position
	Method GetX:float()
		'maybe use a dragX, dragY-value instead of center point
		if self._flags & GUI_OBJECT_DRAGGED then return MouseX() - self.getWidth()/2

		if self._parent <> null
			return self._parent.GetX() + self.rect.GetX()
		else
			return self.rect.GetX()
		endif
	End Method

	Method GetY:float()
		if self._flags & GUI_OBJECT_DRAGGED then return MouseY() - self.getHeight()/2

		if self._parent <> null
			return self._parent.GetY() + self.rect.GetY()
		else
			return self.rect.GetY()
		endif
	End Method

	Method setAlignment(align:Int=0, valign:int=0)
		If Self.align <> align
			If Self.align = 0 And align = 1 then Self.rect.position.setX( Self.rect.position.x - Self.GetWidth() )
			If Self.align = 1 And align = 0 then Self.rect.position.setX( Self.rect.position.x + Self.GetWidth() )
		EndIf
		If Self.valign <> valign
			If Self.valign = 0 And valign = 1 then Self.rect.position.setY( Self.rect.position.y - Self.GetHeight() )
			If Self.valign = 1 And valign = 0 then Self.rect.position.setY( Self.rect.position.y + Self.GetHeight() )
		EndIf
	End Method


	Method Draw() Abstract
	Method Update() Abstract

	'eg. for buttons/inputfields/dropdownbase...
	Method DrawBaseForm(identifier:string, x:float, y:float)
		SetScale Self.scale, Self.scale
		Assets.GetSprite(identifier+".L").Draw(x,y)
		Assets.GetSprite(identifier+".M").TileDrawHorizontal(x + Assets.GetSprite(identifier+".L").w*Self.scale, y, self.GetWidth() - ( Assets.GetSprite(identifier+".L").w + Assets.GetSprite(identifier+".R").w)*self.scale, Self.scale)
		Assets.GetSprite(identifier+".R").Draw(x + self.GetWidth(), y, -1, VALIGN_BOTTOM, ALIGN_LEFT, self.scale)
		SetScale 1.0,1.0
	End Method

	Method DrawBaseFormText:object(_value:string, x:float, y:float)
		local col:TColor = TColor.create(100,100,100)
		if Self.mouseover Then col = TColor.create(50,50,50)
		if not(self._flags & GUI_OBJECT_ENABLED) then col = TColor.create(150,150,150)

		return self.useFont.drawStyled(_value,x,y, col.r, col.g, col.b, 1, 0, 1, 0.5)
	End Method

	Method Input2Value:String(value$)
		Local shiftPressed:Int = False
		Local altGrPressed:Int = False
		?win32
		If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then shiftPressed = True
		If KEYMANAGER.IsDown(164) Or KEYMANAGER.IsDown(165) Then altGrPressed = True
		?
		?Not win32
		If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then shiftPressed = True
		If KEYMANAGER.IsDown(3) Then altGrPressed = True
		?

		Local charToAdd:String = ""
		For Local i:Int = 65 To 90
			charToAdd = ""
			If KEYWRAPPER.pressedKey(i)
				If i = 69 And altGrPressed Then charToAdd = "€"
				If i = 81 And altGrPressed Then charToAdd = "@"
				If shiftPressed Then charToAdd = Chr(i) Else charToAdd = Chr(i+32)
			EndIf
			value :+ charToAdd
		Next

        If KEYWRAPPER.pressedKey(186) then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
        If KEYWRAPPER.pressedKey(192) then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
        If KEYWRAPPER.pressedKey(222) then If shiftPressed Then value:+ "Ä" Else value :+ "ä"

        If KEYWRAPPER.pressedKey(48) then If shiftPressed Then value :+ "=" Else value :+ "0"
        If KEYWRAPPER.pressedKey(49) then If shiftPressed Then value :+ "!" Else value :+ "1"
        If KEYWRAPPER.pressedKey(50) then If shiftPressed Then value :+ Chr(34) Else value :+ "2"
        If KEYWRAPPER.pressedKey(51) then If shiftPressed Then value :+ "§" Else value :+ "3"
        If KEYWRAPPER.pressedKey(52) then If shiftPressed Then value :+ "$" Else value :+ "4"
        If KEYWRAPPER.pressedKey(53) then If shiftPressed Then value :+ "%" Else value :+ "5"
        If KEYWRAPPER.pressedKey(54) then If shiftPressed Then value :+ "&" Else value :+ "6"
        If KEYWRAPPER.pressedKey(55) then If shiftPressed Then value :+ "/" Else value :+ "7"
        If KEYWRAPPER.pressedKey(56) then If shiftPressed Then value :+ "(" Else value :+ "8"
        If KEYWRAPPER.pressedKey(57) then If shiftPressed Then value :+ ")" Else value :+ "9"
        If KEYWRAPPER.pressedKey(219) And shiftPressed Then value :+ "?"
        If KEYWRAPPER.pressedKey(219) And altGrPressed Then value :+ "\"
        If KEYWRAPPER.pressedKey(219) And Not altGrPressed And Not shiftPressed Then value :+ "ß"

        If KEYWRAPPER.pressedKey(221) then If shiftPressed Then value :+ "`" Else value :+ "´"
	    If KEYWRAPPER.pressedKey(188) then If shiftPressed Then value :+ ";" Else value :+ ","
	    If KEYWRAPPER.pressedKey(189) then If shiftPressed Then value :+ "_" Else value :+ "-"
	    If KEYWRAPPER.pressedKey(190) then If shiftPressed Then value :+ ":" Else value :+ "."
        If KEYWRAPPER.pressedKey(226) then If shiftPressed Then value :+ ">" Else value :+ "<"
        If KEYWRAPPER.pressedKey(KEY_BACKSPACE) then value = value[..value.length -1]
	    If KEYWRAPPER.pressedKey(106) then value :+ "*"
	    If KEYWRAPPER.pressedKey(111) then value :+ "/"
	    If KEYWRAPPER.pressedKey(109) then value :+ "-"
	    If KEYWRAPPER.pressedKey(109) then value :+ "-"
	    If KEYWRAPPER.pressedKey(110) then value :+ ","
	    For Local i:Int = 0 To 9
			If KEYWRAPPER.pressedKey(96+i) Then value :+ "0"
		Next
	    If KEYWRAPPER.pressedKey(32) Then value :+ " "

	    If KEYWRAPPER.pressedKey(13) Then EnterPressed :+1
   	    Return value
	End Method
	
End Type

Type TGUIButton Extends TGUIobject
	Field textalign:Int		= 0
	Field manualState:Int	= 0

	Method Create:TGUIButton(pos:TPoint, width:Int=-1, value:String, State:String = "", UseFont:TBitmapFont = Null)
		super.CreateBase(pos.x,pos.y, State, UseFont)

		If width < 0 Then width = self.useFont.getWidth(value) + 8
		self.rect.dimension.SetXY(width, Assets.GetSprite("gfx_gui_button.L").h * self.scale )
		self.setZindex(10)
		self.value		= value
		self.textalign	= 1	'by default centered

    	GUIManager.Add( self )
		Return self
	End Method

	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method

	Method Update()
		If not(self._flags & GUI_OBJECT_ENABLED)
			self.mouseIsClicked = null
			self.mouseover = null
		endif
		'button like behaviour
		if self.mouseIsClicked then	GuiManager.SetActive(0)
	End Method

	Method Draw()
		SetColor 255, 255, 255

		self.DrawBaseForm( "gfx_gui_button"+Self.state, Self.GetX(),Self.GetY() )

		Local TextX:Float = Ceil(Self.GetX() + 10)
		Local TextY:Float = Ceil(Self.GetY() - (Self.useFont.getHeight("ABC") - self.GetHeight()) / 2)
		If textalign = 1 Then TextX = Ceil(Self.GetX() + (Self.GetWidth() - Self.useFont.getWidth(value)) / 2)

		self.DrawBaseFormText(value, TextX, TextY)
	End Method

End Type

Type TGUILabel extends TGUIobject
	Field text:string = ""
	Field displacement:TPoint = TPoint.Create(0,0)
	Field color:TColor = TColor.Create(0,0,0)
	field alignment:float = 0.5 '0 = left, 0.5 = center, 1 = right
	Global defaultLabelFont:TBitmapFont

	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUILabel(x:int,y:int, text:string, color:TColor=null, displacement:TPoint = null, enabled:byte=1, State:string="")
		local useFont:TBitmapFont = self.defaultLabelFont
		super.CreateBase(x,y, State, useFont)

		self.text = text
		if color then self.color = color
		if displacement then self.displacement = displacement

		GUIManager.Add( self )
		return self
	End Method

	Function SetDefaultLabelFont(font:TBitmapFont)
		if font <> null then TGUILabel.defaultLabelFont = font
	End Function

	Method Update:int()
	End Method

	Method SetAlignLeft:int(); self.alignment = 0; End Method
	Method SetAlignRight:int(); self.alignment = 1; End Method
	Method SetAlignCenter:int(); self.alignment = 0.5; End Method

	Method Draw:int()
		usefont.drawStyled(text, floor(rect.GetX() + alignment*(rect.GetW() - usefont.getWidth(text))) + self.displacement.GetX(), floor(rect.GetY() + self.displacement.GetY()), color.r, color.g, color.b, 1)
	End Method

End Type


Type TGUIImageButton Extends TGUIobject
	Field startframe:Int		= 0
	Field spriteBaseName:String	= ""

	'could be done in a TGUILabel
	Field caption:TGUILabel		= null

	Method Create:TGUIImageButton(x:Int, y:Int, spriteBaseName:String, State:String = "", startframe:Int = 0)
		super.CreateBase(x,y, State, null)

		self.spriteBaseName	= spriteBaseName
		self.startframe		= startframe
		self.rect.dimension.setXY( Assets.getSprite(spriteBaseName).w, Assets.getSprite(spriteBaseName).h )
		self.value			= ""

		GUIManager.Add( self )
		Return self
	End Method

	Method SetCaption:TGUIImageButton(caption:String, color:TColor=null, position:TPoint=null)
		self.caption = new TGUILabel.Create(self.rect.GetX(), self.rect.GetY(), caption,color,position)
		'we want to manage it...
		GUIManager.Remove(self.caption)
		return self
	End Method

	Method GetCaption:TGUILabel()
		return self.caption
	End Method

	Method GetCaptionText:string()
		if self.caption then return self.caption.text else return ""
	End Method

	Method Update()
		'button like behaviour
		if self.mouseIsClicked then	GuiManager.SetActive(0)

        If not(self._flags & GUI_OBJECT_ENABLED) then self.mouseIsClicked = null

		'unmanaged label -> we have to position it ourself
		if self.caption and self.caption._flags & GUI_OBJECT_ENABLED
			self.caption.rect.position.SetPos( self.rect.position )
			self.caption.rect.dimension.SetPos( self.rect.dimension )
		endif
	End Method

	Method Draw()
		SetColor 255,255,255

		Local state:String = ""
		if NOT self.getOption(GUI_OBJECT_ENABLED) then state = "_disabled"
		if (self.mouseIsClicked or self.mouseIsDown) then state = "_clicked"

		local sprite:TGW_Sprites = Assets.GetSprite(Self.spriteBaseName+state, Self.spriteBaseName)

		'no clicked image found: displace button and caption by 1,1
		if sprite.GetName() = self.spriteBaseName and (self.mouseIsClicked or self.mouseIsDown)
			sprite.draw(Self.GetX()+1, Self.GetY()+1)
			if self.caption and self.caption._flags & GUI_OBJECT_ENABLED
				self.caption.rect.position.MoveXY( 1,1 )
				self.caption.Draw()
				self.caption.rect.position.MoveXY( -1,-1 )
			endif
		else
			sprite.draw(Self.GetX(), Self.GetY())
			if self.caption and self.caption._flags & GUI_OBJECT_ENABLED then self.caption.Draw()
		endif
	End Method

End Type

'''''TProgressBar -> Ladebildschirm

Type TGUIBackgroundBox Extends TGUIobject
   ' Global List:Tlist
	Field textalign:Int = 0
	Field manualState:Int = 0

	Method Create:TGUIBackgroundBox(x:Int, y:Int, width:Int = 100, height:Int= 100, textalign:Int = 0, value:String, State:String = "", UseFont:TBitmapFont = Null)
		super.CreateBase(x,y, State, useFont)

		self.textalign	= textalign
		self.rect.dimension.setXY( width, height )
		self.value		= value
		self.setZindex(0)

		self.setOption(GUI_OBJECT_CLICKABLE, FALSE) 'by default not clickable
		GUIManager.Add( self )

		Return self
	End Method

	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method

	Method Update()
		'
	End Method

	Method Draw()
		SetColor 255, 255, 255

		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
		Local addY:Float = 0
		local drawPos:TPoint = TPoint.Create(self.GetX(), self.GetY())
		Assets.GetSprite("gfx_gui_box_context.TL").Draw( drawPos.x,drawPos.y )
		Assets.GetSprite("gfx_gui_box_context.TM").TileDrawHorizontal( drawPos.x + Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale, drawPos.y, self.GetWidth() - Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale - Assets.GetSprite("gfx_gui_box_context.TR").w*Self.scale, Self.scale )
		Assets.GetSprite("gfx_gui_box_context.TR").Draw( drawPos.x + self.GetWidth(), drawPos.y, -1, VALIGN_BOTTOM, ALIGN_LEFT, self.scale )
		addY = Assets.GetSprite("gfx_gui_box_context.TM").h * scale

		Assets.GetSprite("gfx_gui_box_context.ML").TileDrawVertical( drawPos.x,drawPos.y + addY, self.GetHeight() - addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*Self.scale), Self.scale )
		Assets.GetSprite("gfx_gui_box_context.MM").TileDraw( drawPos.x + Assets.GetSprite("gfx_gui_box_context.ML").w*Self.scale, drawPos.y + addY, self.GetWidth() - Assets.GetSprite("gfx_gui_box_context.BL").w*scale - Assets.GetSprite("gfx_gui_box_context.BR").w*scale,  self.GetHeight() - addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*Self.scale), Self.scale )
		Assets.GetSprite("gfx_gui_box_context.MR").TileDrawVertical( drawPos.x + self.GetWidth() - Assets.GetSprite("gfx_gui_box_context.MR").w*Self.scale,drawPos.y + addY, self.GetHeight() - addY - (Assets.GetSprite("gfx_gui_box_context.BR").h*Self.scale), Self.scale )

		addY = self.GetHeight() - Assets.GetSprite("gfx_gui_box_context.BM").h * scale

		'buggy "line" zwischen bottom und tiled bg
		addY :-1

		Assets.GetSprite("gfx_gui_box_context.BL").Draw( drawPos.x,drawPos.y + addY)
		Assets.GetSprite("gfx_gui_box_context.BM").TileDrawHorizontal( drawPos.x + Assets.GetSprite("gfx_gui_box_context.BL").w*Self.scale, drawPos.y + addY, self.GetWidth() - Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale - Assets.GetSprite("gfx_gui_box_context.BR").w*Self.scale, Self.scale )
		Assets.GetSprite("gfx_gui_box_context.BR").Draw( drawPos.x + self.GetWidth(), drawPos.y +  addY, -1, VALIGN_BOTTOM, ALIGN_LEFT, self.scale )

		If Self.scale <> 1.0 Then SetScale 1.0,1.0

		Local TextX:Float = Ceil( drawPos.x + 10)
		Local TextY:Float = Ceil( drawPos.y + 5 - (Self.useFont.getHeight(value) - Assets.GetSprite("gfx_gui_box_context.TL").h * Self.scale) / 2 )

		If textalign = 1 Then TextX = Ceil( drawPos.x + (self.GetWidth() - Self.useFont.getWidth(value)) / 2 )

		self.UseFont.drawStyled(value,TextX,TextY, 200,200,200, 2, 0, 1, 0.75)

rem
		SetAlpha 0.50
		SetColor 75, 75, 75
		Self.Usefont.Draw(value, TextX+1, TextY + 1)
		SetAlpha 0.35
		SetColor 0, 0, 0
		Self.Usefont.Draw(value, TextX-1, TextY - 1)
		SetAlpha 1.0
		SetColor 200, 200, 200
		Self.Usefont.Draw(value, TextX, TextY)
endrem
		SetColor 255,255,255
	End Method

End Type


Type TGUIArrowButton  Extends TGUIobject
    Field direction:String

	Method Create:TGUIArrowButton(x:Int,y:Int, direction:Int=0, State:String="", align:Int = 0, valign:int=0)
		super.CreateBase(x,y,State,null)

		select direction
			case 0		self.direction="left"
			case 1		self.direction="up"
			case 2		self.direction="right"
			case 3		self.direction="down"
			default		self.direction="left"
		endselect

		self.setZindex(40)
		self.value		= ""

		self.rect.dimension.setXY( Assets.GetSprite("gfx_gui_arrow_"+self.direction).w * self.scale, Assets.GetSprite("gfx_gui_arrow_"+self.direction).h * self.scale )
		self.setAlignment(align, valign)

		'let the guimanager manage the button
		GUIManager.Add( self )

		Return self
	End Method

	Method Update()
        If not(self._flags & GUI_OBJECT_ENABLED)
			self.mouseIsClicked = null
		endif
		'button like behaviour
		if self.mouseIsClicked then GuiManager.SetActive(0)
	End Method

	Method Draw()
		SetColor 255,255,255
		SetScale Self.scale, Self.scale
		Assets.GetSprite("gfx_gui_arrow_"+Self.direction+Self.state).Draw(Self.GetX(), Self.GetY())
		SetScale 1.0, 1.0
	End Method

End Type

Type TGUISlider Extends TGUIobject
    Field minvalue:Int
    Field maxvalue:Int
    Field actvalue:Int = 50
    Field addvalue:Int = 0
    Field drawvalue:Int = 0

	Method Create:TGUISlider(x:Int, y:Int, width:Int, minvalue:Int, maxvalue:Int, value:String, State:String = "")
		super.CreateBase(x,y,State,null)

		If width < 0 Then width = TextWidth(value) + 8
		self.rect.dimension.setXY( width, gfx_GuiPack.GetSprite("Button").frameh )
		self.value		= value
		self.minvalue	= minvalue
		self.maxvalue	= maxvalue
		self.actvalue	= minvalue

		GUIMAnager.Add( self )
		Return self
	End Method

	Method Update()
		'
	End Method

    Method EnableDrawValue:Int()
		drawvalue = 1
	End Method

    Method DisableDrawValue:Int()
		drawvalue = 0
	End Method

    Method EnableAddValue:Int(add:Int)
 		addvalue = add
	End Method

    Method DisableAddValue:Int()
 		addvalue = 0
	End Method

	Method GetValue:Int()
		Return actvalue + addvalue
	End Method

	Method Draw()
		Local sprite:TGW_Sprites = gfx_GuiPack.GetSprite("Slider")

		Local PixelPerValue:Float = self.GetWidth() / (maxvalue - 1 - minvalue)
	    Local actvalueX:Float = actvalue * PixelPerValue
	    Local maxvalueX:Float = (maxvalue) * PixelPerValue
		Local difference:Int = actvalueX '+ PixelPerValue / 2

		If self.mouseIsDown
			difference = MouseX() - Self.rect.position.x + PixelPerValue / 2
			actvalue = Float(difference) / PixelPerValue
			If actvalue > maxvalue Then actvalue = maxvalue
			If actvalue < minvalue Then actvalue = minvalue
			actvalueX = difference'actvalue * PixelPerValue
			If actvalueX >= maxValueX - sprite.framew Then actvalueX = maxValueX - sprite.framew
		EndIf

  		If Ceil(actvalueX) < sprite.framew
			'links an
			sprite.DrawClipped( self.GetX(), self.GetY(), Self.GetX(), Self.GetY(), Ceil(actvalueX) + 5, sprite.frameh, 0, 0, 4)
			'links aus
  		    sprite.DrawClipped( Self.GetX(), Self.GetY(), Self.GetX() + Ceil(actvalueX) + 5, Self.GetY(), sprite.framew, sprite.frameh, 0, 0, 0)
		Else
			sprite.Draw( Self.GetX(), Self.GetY(), 4 )
		EndIf
  		If Ceil(actvalueX) > self.GetWidth() - sprite.framew
			sprite.DrawClipped( Self.GetX() + self.GetWidth() - sprite.framew, Self.GetY(), Self.GetX() + self.GetWidth() - sprite.framew, Self.GetY(), Ceil(actvalueX) - (self.GetWidth() - sprite.framew) + 5, sprite.frameh, 0, 0, 6) 'links an
  		    'links aus
  		    sprite.DrawClipped( Self.GetX() + self.GetWidth() - sprite.framew, Self.GetY(), Self.GetX() + actvalueX + 5, Self.GetY(), sprite.framew, sprite.frameh, 0, 0, 2 )
		Else
			sprite.Draw( Self.GetX() + self.GetWidth(), Self.GetY(), 2, VALIGN_BOTTOM, ALIGN_LEFT )
		EndIf


		' middle
		'      \
		' [L][++++++()-----][R]
		' MaxWidth = GuiObj.w - [L].w - [R].w
		local maxWidth:float	= self.GetWidth() - 2*sprite.framew
		local reachedWidth:float= Min(maxWidth, actvalueX - sprite.framew)
		local missingWidth:float= maxWidth - reachedWidth
		'gefaerbter Balken
		sprite.TileDrawHorizontal(Self.GetX() + sprite.framew, self.GetY(), reachedWidth, self.scale, 1+4)
		'ungefaerbter Balken
		if missingWidth > 0 then sprite.TileDrawHorizontal(Self.GetX() + sprite.framew + reachedWidth, self.GetY(), missingWidth, self.scale, 1)

	    'dragger  -5px = Mitte des Draggers
	    local mouseIsDown:int = 1
	    if self.mouseIsDown then mouseIsDown=0
	    
		sprite.Draw( Self.GetX() + Ceil(actvalueX - 5), Self.GetY(), 3 + (mouseIsDown) * 4)


		'draw label/text
		if self.value = "" then return

		local drawText:string = self.value
		If drawvalue <> 0 then drawText = (actvalue + addvalue) + " " + drawText

		Self.Usefont.Draw(value, Self.GetX()+self.GetWidth()+7, Self.GetY()- (Self.useFont.getHeight(drawText) - self.GetHeight()) / 2 - 1)
	End Method

End Type

Type TGUIinput Extends TGUIobject
    Field maxLength:Int
    Field maxTextWidth:Int
    Field color:TColor					= TColor.Create(0,0,0)
    Field OverlayImage:TGW_Sprites		= Null
    Field InputImageActive:TGW_Sprites	= Null	  'own Image for Inputarea
    Field InputImage:TGW_Sprites		= Null	  'own Image for Inputarea
    Field OverlayColor:TColor			= TColor.Create(200,200,200, 0.5)
	Field TextDisplacement:TPoint		= TPoint.Create(5,5)
	Field autoAlignText:int				= 1
	Field valueChanged:int				= 0 '1 if changed

    Method Create:TGUIinput(x:Int, y:Int, width:Int, value:String, maxlength:Int = 128, State:String = "", useFont:TBitmapFont = Null)
		super.CreateBase(x,y,State, useFont)

		self.setZindex(20)
		self.rect.dimension.setXY( Max(width, 40), Assets.GetSprite("gfx_gui_input.L").h * self.scale )
		self.maxTextWidth	= self.GetWidth() - 15
		self.value			= value
		self.maxlength		= maxlength
		self.EnterPressed	= 0
		self.color = TColor.Create(100,100,100)

		GUIMAnager.Add( self )
	  	Return self
	End Method


	Method Update()
		If self._flags & GUI_OBJECT_ENABLED
			If EnterPressed >= 2
				EnterPressed = 0
				GUIManager.setActive(0)
				if self.valueChanged
					'reset changed indicator
					self.valueChanged = 0
					'fire onChange-event (text changed)
					EventManager.registerEvent( TEventSimple.Create( "guiobject.onChange", TData.Create().AddNumber("type", 1), self ) )
				endif
			EndIf
			If GUIManager.isActive(Self._id)
				local oldvalue:string = value
				value = Input2Value(value)
				if oldvalue <> value then self.valueChanged = 1
			endif
		EndIf
		If GUIManager.isActive(self._id)
			self.setState("active")
		endif

        If value.length > maxlength Then value = value[..maxlength]
	End Method

    Method SetOverlayImage:TGUIInput(_sprite:TGW_Sprites)
		If _sprite <> Null Then If _sprite.w > 0 Then OverlayImage = _sprite
		Return Self
	End Method

	Method Draw()
		Local useTextDisplaceX:Int	= Self.TextDisplacement.x
	    Local i:Int					= 0
		Local printvalue:String		= value

		if self.InputImage or self.InputImageActive
			If self.isActive()
				if self.InputImageActive then self.InputImageActive.Draw(self.GetX(), self.GetY())
			else
				if self.InputImage then self.InputImage.Draw(self.GetX(), self.GetY())
			endif
		else
			'draw base buttonstyle
			If not(self._flags & GUI_OBJECT_ENABLED) then SetColor 225, 255, 150
			self.DrawBaseForm("gfx_gui_input"+Self.state, self.GetX(),Self.GetY())
		endif

		'center overlay over left frame
		If OverlayImage <> Null
			Local Left:Float	= ( ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").w - OverlayImage.w ) / 2 ) * Self.scale
			Local top:Float		= ( ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").h - OverlayImage.h ) / 2 ) * Self.scale
			SetScale Self.scale, Self.scale
			OverlayImage.Draw( Self.GetX() + Left, Self.GetY() + top )
		EndIf
		SetScale 1.0,1.0

		Local useMaxTextWidth:Int = Self.maxTextWidth
		If Self.useFont = Null Then self.useFont = GUIManager.defaultFont 'item not created with create but new

		'only center text if autoAlign is set
		if self.autoAlignText then Self.textDisplacement.y = (self.GetHeight() - Self.useFont.getHeight("abcd")) /2

        If OverlayImage <> Null
			useTextDisplaceX :+ OverlayImage.framew * Self.scale
			useMaxTextWidth :-  OverlayImage.framew * Self.scale
		EndIf
		local textPosX:int = ceil( Self.GetX() + usetextDisplaceX + 2 )
		local textPosY:int = ceil( Self.GetY() + Self.textDisplacement.y )

		If self.isActive()
			Self.color.set()
			While Len(printvalue) >1 And Self.useFont.getWidth(printValue + "_") > useMaxTextWidth
				printvalue = printValue[1..]
			Wend
			Self.useFont.draw(printValue, textPosX, textPosY)

			SetAlpha Ceil(Sin(MilliSecs() / 4))
			Self.useFont.draw("_", textPosX + Self.useFont.getWidth(printValue), textPosY )
			SetAlpha 1
	    Else
			Self.color.set()
			While TextWidth(printValue) > useMaxTextWidth And printvalue.length > 0
				printvalue = printValue[..printvalue.length - 1]
			Wend

'			if NOT self.InputImage AND NOT self.InputImageActive
			If Self.mouseover
				Self.useFont.drawStyled(printValue, textPosX, textPosY, Self.color.r-50, Self.color.g-50, Self.color.b-50, 1)
			Else
				Self.useFont.drawStyled(printValue, textPosX, textPosY, Self.color.r, Self.color.g, Self.color.b, 1)
			EndIf
		EndIf

		SetColor 255, 255, 255
	End Method

End Type

'data objects for gui objects (eg. dropdown entries, list entries, ...)
Type TGUIEntry
	Field formatValue:String = "#value"		'how to format value
	Field id:Int							'internal gui id
	Field data:TData						'custom data

	Function Create:TGUIEntry(data:TData=null)
		Local obj:TGUIEntry = New TGUIEntry
		obj.data	= data
		obj.id		= TGUIObject.getNextID()
		Return obj
	End Function

	Method setFormatValue(newValue:string)
		self.formatValue = newValue
	End Method

	Method getValue:string()
		return self.data.getString("value", "")
	End Method

End Type

Type TGUIDropDown Extends TGUIobject
    Field Values:String[]
	Field EntryList:TList = CreateList()
    Field PosChangeTimer:Int
	Field clickedEntryID:Int=-1
	Field hoveredEntryID:int=-1
	Field textalign:Int = 0
	Field heightIfOpen:float = 0

	Method Create:TGUIDropDown(x:Int, y:Int, width:Int = -1, on:Byte = 0, value:String, State:String = "", UseFont:TBitmapFont = Null)
		super.CreateBase(x,y,State,UseFont)

		If width < 0 Then width = self.useFont.getWidth(value) + 8
		self.rect.dimension.setXY( width, Assets.GetSprite("gfx_gui_dropdown.L").frameh * self.scale)
		self.value		= value
		self.heightIfOpen = self.rect.GetH()

		GUIManager.Add( self )
		Return self
	End Method

	'overwrite default method
	Method GetHeight:float()
		return self.heightIfOpen
	End Method


	Method SetActiveEntry(id:Int)
		Self.clickedEntryID = id
		Self.value = TGUIEntry(Self.EntryList.ValueAtIndex(id)).getValue()
	End Method

	Method Update()
        If not(self._flags & GUI_OBJECT_ENABLED) then self.mouseIsClicked = null

		if not self.isActive() or not self.mouseIsDown then return

		local currentAddY:Int = self.rect.GetH() 'ignore "if open"
		local lineHeight:float = Assets.GetSprite("gfx_gui_dropdown_list_entry.L").h*self.scale

		'reset hovered item id ...
		self.hoveredEntryID = -1

		'check new hovered or clicked items
		For Local Entry:TGUIEntry = EachIn self.EntryList 'Liste hier global
			If functions.MouseIn( Self.GetX(), Self.GetY() + currentAddY, self.GetWidth(), lineHeight)
				If GUIManager.MouseIsHit
					value			= Entry.getValue()
					clickedEntryID	= Entry.id
					GUIManager.setActive(0)
					EventManager.registerEvent( TEventSimple.Create( "guiobject.OnChange", TData.Create().AddNumber("entryID", entry.id), self ) )
					GUIManager.MouseIsHit = 0
					Exit
				else
					hoveredEntryID	= Entry.id
				endif
			EndIf
			currentAddY:+ lineHeight
		Next
		'store height if opened
		self.heightIfOpen = self.rect.GetH() + currentAddY


		if hoveredEntryID > 0
			GUIManager.setActive(self._id)
			self.setState("hover")
		else
			'clicked outside of list
			if GUIManager.MouseIsHit and self.isActive() then GUIManager.setActive(0)
		EndIf

	End Method

	Method AddEntry(value:String)
		local entry:TGUIEntry = TGUIEntry.Create( TData.Create().AddString("value", value) )
		EntryList.AddLast(entry)
		If Self.value = "" Then Self.value = entry.getValue()
		If Self.clickedEntryID = -1 Then Self.clickedEntryID = entry.id
	End Method


	Method Draw()
	    Local i:Int					= 0
	    Local j:Int					= 0
	    Local useheight:Int			= 0
	    Local printheight:Int		= 0

		'draw list if enabled
		If self._flags & GUI_OBJECT_ENABLED 'ausgeklappt zeichnen
			useheight = self.rect.GetH()
			For Local Entry:TGUIEntry = EachIn self.EntryList
				if self.EntryList.last() = Entry
					self.DrawBaseForm( "gfx_gui_dropdown_list_bottom", Self.rect.GetX(), Self.rect.GetY() + useheight )
				else
					self.DrawBaseForm( "gfx_gui_dropdown_list_entry", Self.rect.GetX(), Self.rect.GetY() + useheight )
				endif

				SetColor 100,100,100

				If Entry.id = self.clickedEntryID then SetColor 0,0,0
				If Entry.id = self.hoveredEntryID then SetColor 150,150,150

				If textalign = 1 Then self.useFont.Draw( Entry.getValue(), Self.GetX() + (self.GetWidth() - self.useFont.getWidth( Entry.GetValue() ) ) / 2, Self.GetY() + useheight + 5)
				If textalign = 0 Then self.useFont.Draw( Entry.getValue(), Self.GetX() + 10, Self.GetY() + useHeight + 5)
				SetColor 255,255,255

				'move y to next spot
				if self.EntryList.last() = Entry
					useheight:+ Assets.GetSprite("gfx_gui_dropdown_list_bottom.L").h*self.scale
				else
					useheight:+ Assets.GetSprite("gfx_gui_dropdown_list_entry.L").h*self.scale
				endif
			Next
		endif

		'draw base button
		self.DrawBaseForm( "gfx_gui_dropdown"+Self.state, Self.GetX(), Self.GetY() )

		'text on button

		If not(self._flags & GUI_OBJECT_ENABLED)
			SetAlpha 0.7
			self.DrawBaseFormText(value, Self.GetX() + 10, Self.GetY() + self.rect.GetH()/2 - self.useFont.getHeight(value)/2)
			SetAlpha 1.0
	    Else
			self.DrawBaseFormText(value, Self.GetX() + 10, Self.GetY() + self.rect.GetH()/2 - self.useFont.getHeight(value)/2)
		EndIf
		SetColor 255, 255, 255

		'debuglog ("GUIradiobutton zeichnen")
	End Method
End Type



Type TGUIOkButton Extends TGUIobject
	Field crossed:Int = 0
	Field assetWidth:Float = 1.0

	Method Create:TGUIOkButton(x:Int,y:Int, crossed:int=FALSE, value:String, State:String="", useFont:TBitmapFont=null)
		super.CreateBase(x,y,State,useFont)

		'scale in both dimensions ()
		self.rect.dimension.setXY( Assets.GetSprite("gfx_gui_ok_off").w * self.scale, Assets.GetSprite("gfx_gui_ok_off").h * self.scale)
		'store assetWidth to have dimension.x store "whole widget"
		self.assetWidth	= Assets.GetSprite("gfx_gui_ok_off").w
		self.value		= value
		self.setZindex(50)
		self.crossed	= crossed
		GUIManager.Add( self )
		Return self
	End Method

	Method Update()
		'button like behaviour
		if self.mouseIsClicked then	GuiManager.SetActive(0)

		If mouseIsClicked Then crossed = 1-crossed; self.mouseIsClicked = null
		'disable "active state"
		If Self.state = ".active" Then Self.state = ".hover"

	End Method

	Method IsCrossed:Int()
		Return crossed & 1
		'If crossed = 1 Then Return 1 Else Return 0
	End Method

	Method Draw()
		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
		If crossed
			Assets.GetSprite("gfx_gui_ok_on"+Self.state).Draw(Self.GetX(), Self.GetY())
		else
			Assets.GetSprite("gfx_gui_ok_off"+Self.state).Draw(Self.GetX(), Self.GetY())
		endif
		If Self.scale <> 1.0 Then SetScale 1.0,1.0

		Local textDisplaceX:Int = 5
		local dimX:float = int(string(Self.useFont.drawStyled(value, 0, 0, 0, 0, 0, 1, 0,0) ))
		local dimY:float = int(string(Self.useFont.drawStyled(value, 0, 0, 0, 0, 0, 1, 1,0) ))
		self.rect.dimension.setX( Self.assetWidth*Self.scale + textDisplaceX + dimX )


		local col:TColor = TColor.create(100,100,100)
		if Self.mouseover Then col = TColor.create(50,50,50)
		if not(self._flags & GUI_OBJECT_ENABLED) then col = TColor.create(150,150,150)

		Self.useFont.drawStyled( value, Self.GetX()+Self.assetWidth*Self.scale + textDisplaceX, Self.GetY() - (dimY - self.GetHeight()) / 2, col.r, col.g, col.b, 1 )
	End Method

End Type

Type TGUIPanel Extends TGUIObject
	Field elements:TList				= CreateList()
	Field background:TGUIBackgroundBox	= Null

	Method Create:TGUIPanel(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		self.rect.setXYWH(x, y, width, height)
		self._limitToState = limitState

		GUIManager.Add( self )
		Return self
	End Method

	Method AddElement(element:TGUIobject)
		element.setParent( self )
		self.elements.addLast(element)
	End Method

	Method disableBackground()
		if self.background then self.background.disable()
	End Method

	Method enableBackground()
		if self.background then self.background.enable()
	End Method

   	Method Update()
		'
	End Method

	Method Draw()
		'
	End Method
End Type

rem
Type TGUIScrollablePanel Extends TGUIPanel
	Field guiScroller:TGUIScroller	= Null
	Field guiScrollerEnabled:int	= TRUE
	Field scrolled:TPoint			= TPoint.Create(0,0)

	Method Create:TGUIScrollablePanel(x:Int, y:Int, width:Int = 100, height:Int= 100, State:string = "")
	End Method
End Type
endrem

Type TGUIScroller Extends TGUIobject
	field sprite:TGW_Sprites
	field mouseDownTime:int				= 200	'milliseconds until we react on "mousedown"
	field guiButtonUp:TGUIArrowButton	= null
	field guiButtonDown:TGUIArrowButton = null


	Method Create:TGUIScroller(parent:TGUIobject)
		self.sprite 		= gfx_GuiPack.GetSprite("ListControl")
		self.setParent(parent)

		'create buttons
		self.guiButtonUp	= new TGUIArrowButton.Create(0,0, 1, "", 0)
		self.guiButtonDown	= new TGUIArrowButton.Create(0,parent.rect.GetH(), 3, "", 0,1)
		'from button width, calculate position on own parent
		self.rect.position.setXY(parent.rect.getW() - self.guiButtonUp.rect.getW(),0)
		self.rect.dimension.setXY(self.guiButtonUp.rect.getW(), parent.rect.getH())
		
		'set the parent of the buttons so they inherit visible state etc.
		self.guiButtonUp.setParent(self)
		self.guiButtonDown.setParent(self)

		'scroller is interested in click on its buttons
		EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScroller.onButtonClick, self.guiButtonUp )
		EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScroller.onButtonClick, self.guiButtonDown )
		EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScroller.onButtonDown, self.guiButtonUp )
		EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScroller.onButtonDown, self.guiButtonDown )

		GUIManager.Add( self)

		return self
	End Method
	

	'handle clicks on the up/down-buttons and inform others about changes
	Function onButtonClick:int( triggerEvent:TEventBase )
		local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		if sender = Null then return FALSE
		
		local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		if guiScroller = Null then return FALSE

		'emit event that the scroller position has changed
		if sender = guiScroller.guiButtonUp
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", TData.Create().AddString("direction", "upStep"), guiScroller ) )
		elseif sender = guiScroller.guiButtonDown
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", TData.Create().AddString("direction", "downStep"), guiScroller ) )
		endif
	End Function

	'handle clicks on the up/down-buttons and inform others about changes
	Function onButtonDown:int( triggerEvent:TEventBase )
		local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		if sender = Null then return FALSE
		
		local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		if guiScroller = Null then return FALSE

		if GUIManager.MouseIsDownTime > 0
			'if we still have to wait - return without emitting events
			if Millisecs() - GUIManager.MouseIsDownTime < guiScroller.mouseDownTime
				return FALSE
			endif
		endif
	

		'emit event that the scroller position has changed
		if sender = guiScroller.guiButtonUp
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", TData.Create().AddString("direction", "up"), guiScroller ) )
		elseif sender = guiScroller.guiButtonDown
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", TData.Create().AddString("direction", "down"), guiScroller ) )
		endif
	End Function	


	Method Update:int()
		'nothing special
	End Method

	Method Draw()
		SetColor 125,125,125
		SetAlpha 0.25
		
		local width:int = self.guiButtonUp.getWidth() 
		local height:int = self.guiButtonUp.getHeight() 
		DrawRect(self.GetX() + width/4, self.GetY() + height/2, width/2, self.GetHeight()-height)

		SetAlpha 1.0
		SetColor 255,255,255
	End Method

End Type

Type TGUISlotList Extends TGUIListBase
	Field _slotMinHeight:int = 0
	Field _slotAmount:int = -1		'<=0 means dynamically, else it is fixed
	Field _slots:TGUIobject[0]
	field _autofillSlots:int = FALSE
	
    Method Create:TGUISlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		
		self.autoSortItems = false
		return self
	End Method

	'override
	Method SetItemLimit:int(limit:int)
		Super.SetItemLimit(limit)
		self._slotAmount = limit

		'maybe better "drag" items before if resizing to smaller slot amounts
		self._slots = self._slots[..limit]
	End Method

	Method SetSlotMinHeight:int(height:int=0)
		self._slotMinHeight = height
	End Method

	'which slot is occupied by the given item?
	Method getSlot:int(item:TGUIobject)
		For local i:int = 0 to self._slots.length-1
			if self._slots[i] = item then return i
		Next
		return -1
	End Method

	'return the next free slot (for autofill)
	Method getFreeSlot:int()
		For local i:int = 0 to self._slots.length-1
			if self._slots[i] then continue
			return i
		Next
		return -1
	End Method

	'get a slot by a (global/screen) coord
	Method GetSlotByCoord:int(coord:TPoint, isScreenCoord:int=TRUE)
		'convert global/screen to local coords
		if isScreenCoord then coord.MoveXY(-self.GetX(),-self.GetY())
		local baseRect:TRectangle = TRectangle.Create(0, 0, self.rect.GetW(), self._slotMinHeight)

		local currentYPos:float = 0
		For local i:int = 0 to self._slots.length-1
			baseRect.position.setY(currentYPos)
'			print "x="+coord.getX()+",y="+coord.GetY()+" in x=" + baserect.getX()+",y="+baserect.getY()+",w="+baserect.getW()+",h="+baserect.getH()
			if self._slots[i]
				if self._slots[i].rect.containsXY(coord.getX(),coord.getY()) then return i
				currentYPos :+ Max(self._slotMinHeight, self._slots[i].rect.getH() )
			else
				if baseRect.containsXY(coord.GetX(), coord.GetY()) then return i
				currentYPos :+ self._slotMinHeight
			endif
		Next
		return -1
	End Method

	Method GetItemByCoord:TGUIobject(coord:TPoint)
		local slot:int = self.GetSlotByCoord(coord)
		return self.GetItemBySlot(slot)
	End Method

	Method GetItemBySlot:TGUIobject(slot:int)
		if slot < 0 or slot > self._slots.length-1 then return Null

		return self._slots[slot]
	End Method

	'overrideable AddItem-Handler
	Method AddItem:int(item:TGUIobject, extra:object=null)
		local addToSlot:int = 0
		'search for first free slot
		if self._autofillSlots then addToslot = self.getFreeSlot()
		'no free slot? find out on which slot we are dropping
		'if possible, drag the other one and drop the new
		if not self._autofillSlots or addToSlot < 0
			local data:TData = TData(extra)
			if not data then return FALSE

			local dropCoord:TPoint = TPoint(data.get("coord"))
			if not dropCoord then return FALSE

			'set slot to land
			addToSlot = self.GetSlotByCoord(dropCoord)
			'no slot was hit
			if addToSlot < 0 then return FALSE

			'is there another item?
			local dragItem:TGUIListItem = TGUIListItem(self.getItemBySlot(addToSlot))

			if dragItem
				'drag the other one
				dragItem.drag()
				'force sort the second time ... WHY IS THIS NEEDED? 
				GuiManager.sortList()
			endif
		endif
		
		self._slots[addToSlot] = item
		item.setParent(self)

		self.RecalculateElements()

		return TRUE
	End Method

	'overrideable RemoveItem-Handler
	Method RemoveItem:int(item:TGUIobject)
		For local i:int = 0 to self._slots.length-1
			if self._slots[i] = item
				self._slots[i] = null

				self.RecalculateElements()
				return TRUE
			endif
		Next
		return FALSE
	End Method

	Method Draw()
		'restrict by scrollable panel
		self.guiEntriesPanel.RestrictViewPort()
		local currentY:float = self.guiEntriesPanel.scrollPosition.GetY()
		For local i:int = 0 to self._slots.length-1
			if self._slots[i]
				currentY :+ Max(self._slotMinHeight, self._slots[i].rect.getH())
			else
				SetAlpha 0.2
				SetColor 0,0,0
				DrawRect(self.getX(), self.getY()+currentY, self.rect.getW(), self._slotMinHeight)
				SetColor 255,255,255
				DrawRect(self.getX()+1, self.getY()+currentY+1, self.rect.getW()-2, self._slotMinHeight-2)
				SetAlpha 1.0
				currentY :+ self._slotMinHeight
			endif
		Next
		DrawText(self.guiEntriesPanel.scrollPosition.GetY(), self.getX(), self.getY()+10)
		self.ResetViewPort()
	End Method


	Method RecalculateElements:int()
		local currentYPos:float = 0
		For local i:int = 0 to self._slots.length-1
			if self._slots[i]
				'move entry's y position to current one
				self._slots[i].rect.position.SetY(currentYPos)
				currentYPos :+ Max(self._slotMinHeight, self._slots[i].rect.getH())
			else
				currentYPos :+ self._slotMinHeight
			endif
		Next
		'set scroll limits:
		'maximum is at the bottom of the area, not top - so subtract height
		self.guiEntriesPanel.SetLimits(0, currentYPos - self.guiEntriesPanel.rect.GetH())
	End Method

End Type




Type TGUIListBase Extends TGUIobject
	Field guiBackground:TGUIBackgroundBox		= Null
	Field guiEntriesPanel:TGUIScrollablePanel	= Null
	Field guiScroller:TGUIScroller				= Null
	Field guiScrollerEnabled:int				= TRUE

	Field autoScroll:Int						= FALSE
	Field entries:TList							= CreateList()
	Field entriesLimit:int						= -1
	Field autoSortItems:int						= TRUE

    Method Create:TGUIListBase(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		super.CreateBase(x,y,State,null)
		self.setZIndex(10)
		If width < 40 Then width = 40
		self.rect.dimension.setXY( width, height )

		self.guiScroller = new TGUIScroller.Create(self)

		self.guiEntriesPanel = new TGUIScrollablePanel.Create(0,0, width-self.guiScroller.rect.getW(), height,state)
		self.guiEntriesPanel.setParent(self)

		'by default all lists accept drop
		self.setOption(GUI_OBJECT_ACCEPTS_DROP, TRUE)

		'register events
		'- we are interested in certain events from the scroller
		EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged",	TGUIListBase.onScroll, self.guiScroller )
		'is something dropping - check if it this list
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", self.onDropOnTarget, "TGUIListItem", self)

		GUIManager.Add( self )
		Return self
	End Method

	Method SetItemLimit:int(limit:int)
		self.entriesLimit = limit
	End Method

	Method ReachedItemLimit:int()
		if self.entriesLimit <= 0 then return FALSE
		return (self.entries.count() >= self.entriesLimit)
	End Method
	
	Method GetItemByCoord:TGUIobject(coord:TPoint)
		For local entry:TGUIobject = eachin self.entries
			'our entries are sorted and replaced, so we could
			'quit as soon as the
			'entry is out of range... 
			if entry.GetY() > self.getY()+self.getHeight() then return Null
			
			if entry.GetRect().containsXY(coord.GetX(), coord.GetY()) then return entry
		Next
		return Null
	End Method

	'base handling of add item
	Method _AddItem:int(item:TGUIobject, extra:object=null)
		if self.ReachedItemLimit() then return FALSE

		'set parent of the item - so item is able to calculate position
		item.setParent(self.guiEntriesPanel)
		self.entries.addLast(item)
		if self.autoSortItems then print Self.entries.sort() ')(True, TGUIListItem.SortItems)

		return TRUE
	End Method

	'base handling of add item
	Method _RemoveItem:int(item:TGUIobject)
		self.entries.Remove(item)
		return TRUE
	End Method

	'overrideable AddItem-Handler
	Method AddItem:int(item:TGUIobject, extra:object=null)
		if self._AddItem(item, extra)
			'recalculate positions, dimensions etc.
			self.RecalculateElements()
			return TRUE
		endif
		return FALSE
	End Method
	'overrideable RemoveItem-Handler
	Method RemoveItem:int(item:TGUIobject)
		if self._RemoveItem(item)
			self.RecalculateElements()
			return TRUE
		endif
		return FALSE
	End Method

	'recalculate scroll maximas, item positions...
	Method RecalculateElements:int()
		local currentYPos:float = 0
		For local entry:TGUIobject = eachin self.entries
			'move entry's y position to current one
			entry.rect.position.SetY(currentYPos)

			'advance to next y position
			currentYPos:+entry.rect.GetH()
		Next
		'set scroll limits:
		'maximum is at the bottom of the area, not top - so subtract height
		self.guiEntriesPanel.SetLimits(0, currentYPos - self.guiEntriesPanel.rect.GetH())
	End Method

	Method SetScrollerState(on:Int = 1)
		Self.guiScrollerEnabled = on
	End Method

	Function onDropOnTarget:int( triggerEvent:TEventBase )
		local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		'only handle if coming from another list ?
		local parent:TGUIobject = item._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local fromList:TGUIListBase = TGUIListBase(parent)
		if not fromList then return FALSE

		local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		if not toList then return FALSE

		local data:TData = triggerEvent.getData()
		if not data then return FALSE

		'move item if possible
		fromList.removeItem(item)
print "drop: removed FROM - contains now:" + fromList.entries.count()
		'try to add the item, if not able, readd
		if not toList.addItem(item, data)
print "drop: not able to add TO"
			if fromList.addItem(item) then return TRUE
			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
		endif
		
	End Function

	'handle events from the connected scroller
	Function onScroll:int( triggerEvent:TEventBase )
		local scroller:TGUIScroller = TGUIScroller(triggerEvent.GetSender())
		if scroller = Null then return FALSE

		local guiList:TGUIListBase = TGUIListBase(scroller._parent)
		if not guiList then return FALSE

		local data:TData = triggerEvent.GetData()
		if not data then return FALSE

		'this should be "calculate height and change amount"
		if data.GetString("direction") = "upStep" then guiList.ScrollEntries(0, +10)
		if data.GetString("direction") = "downStep" then guiList.ScrollEntries(0, -10)

		if data.GetString("direction") = "up" then guiList.ScrollEntries(0, +1)
		if data.GetString("direction") = "down" then guiList.ScrollEntries(0, -1)
	End Function

	'positive values scroll to top or left
	Method ScrollEntries(dx:int, dy:int)
		self.guiEntriesPanel.scroll(dx,dy)
	End Method

	Method Update()
		'
	End Method

	Method Draw()
		'
	End Method
End Type

Type TGUIListItem Extends TGUIobject
	field label:string = ""
	field positionNumber:int = 0

    Method Create:TGUIListItem(label:string="")
		local defaultWidth:int = 120
		local defaultHeight:int= 20

   		super.CreateBase(0,0,"",null)
		self.rect.dimension.setXY( defaultWidth, defaultHeight )
		self.label = label

		'make dragable
		self.setOption(GUI_OBJECT_DRAGABLE, TRUE)

		'register events
		'- each item wants to know whether it was clicked
		EventManager.registerListenerFunction( "guiobject.onClick",	TGUIListItem.onClick, self )

		GUIManager.add(self)

		return self
	End Method

	Function onClick:int( triggerEvent:TEventBase )
		local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		local data:TData = triggerEvent.GetData()
		if not data then return FALSE

		if item.isDragged()
			item.drop( TPoint.Create(data.getInt("x",-1), data.getInt("y",-1)) )
		else
			item.drag( TPoint.Create(data.getInt("x",-1), data.getInt("y",-1)) )
		endif
	End Function

	Method Update()
		'nothing special
	End Method

	Method Draw()
		local sx:int,sy:int,sw:int,sh:int
		if not(self._flags & GUI_OBJECT_DRAGGED)
			GetViewport(sx,sy,sw,sh)
			local parent:TGUIobject = self._parent
			if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent

			if TGUIListBase(parent) then TGUIListBase(parent).RestrictViewPort()
		endif
		'self.getX() and self.getY() include parents coordinate
		SetColor 0,0,0
		DrawRect(self.getX(), self.getY(), self.rect.GetW(), self.rect.GetH() )
		if self._flags & GUI_OBJECT_DRAGGED 
			SetColor 125,0,125
		else
			SetColor 125,125,125
		endif
		DrawRect(self.getX()+1, self.getY()+1, self.rect.GetW()-2, self.rect.GetH()-2 )
		SetColor 255,255,255

		DrawText(self.label + " ["+self._id+"]", self.getX() + 5, self.getY() + 2+ 0.5*(self.rect.getH()-TextHeight(self.label)))

		if not(self._flags & GUI_OBJECT_DRAGGED)
			SetViewport(sx,sy,sw,sh)
		endif
	End Method
End Type


Type TGUIScrollablePanel Extends TGUIPanel
	Field scrollPosition:TPoint	= TPoint.Create(0,0)
	Field scrollLimit:TPoint = TPoint.Create(0,0)

	Method Create:TGUIScrollablePanel(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		Super.Create(x,y,width,height,limitState)
	
		return self
	End Method

	Method SetLimits:int(lx:float,ly:float)
		self.scrollLimit.setXY(lx,ly)
	End Method

	Method Scroll:int(dx:float,dy:float)
		self.scrollPosition.MoveXY(dx, dy)

		'check limits
		self.scrollPosition.SetY( Min(0, self.scrollPosition.GetY()) )
		self.scrollPosition.SetY( Max(self.scrollPosition.GetY(), -self.scrollLimit.GetY()) )
	End Method

	'override getters - to adjust values by scrollposition
	Method GetY:float()
		local y:float = Super.GetY()
		return y + self.scrollPosition.getY()
	End Method

	Method GetX:float()
		local x:float = Super.GetX()
		return x + self.scrollPosition.getX()
	End Method

	Method RestrictViewport()
		GUIManager.RestrictViewport(self.getX(),self.getY() - self.scrollPosition.getY(), self.rect.getW(), self.rect.getH())
	End Method

End Type




Type TGUIList Extends TGUIobject 'should extend TGUIPanel if Background - or guiobject with background?
    Field maxlength:Int
    Field filter:String
	Field AutoScroll:Int			= 0
	Field scroller:TGUIScroller		= null
	Field ListStartsAtPos:Int
	Field ListPosClicked:Int
	Field EntryList:TList			= CreateList()
	Field ControlEnabled:Int		= 0
	Field lastMouseClickTime:Int	= 0
	Field LastMouseClickPos:Int		= 0
	Field background:TGUIBackgroundBox = null

    Method Create:TGUIList(x:Int, y:Int, width:Int, height:Int = 50, maxlength:Int = 128, State:String = "")
		super.CreateBase(x,y,State,null)

		If width < 40 Then width = 40
		self.rect.dimension.setXY( width, height )
		self.maxlength			= maxlength
		self.ListStartsAtPos	= 0
		self.ListPosClicked		= -1

		self.scroller			= new TGUIScroller.Create(self)
		'hide scroll element
		self.scroller.hide()

		GUIManager.Add( self )
		Return self
	End Method

	Method AddBackground(title:string="Box")
		self.background = new TGUIBackgroundBox.Create(self.GetX(), self.GetY(), self.GetWidth(), self.GetHeight(), 0, title, "", Assets.GetFont("Default", 16, BOLDFONT))
		self.background.SetSelfManaged()
	End Method

	Method SetControlState(on:Int = 1)
		Self.ControlEnabled = on
	End Method

	Method SetFilter:Int(usefilter:String = "")
		self.filter = usefilter
	End Method


'RemoveOld ... should be done in specific object (pid...)

 	Method RemoveOldEntries:Int(pid:Int=0, timeout:Int=500)
	  Local i:Int = 0
	  Local RemoveTime:Int = MilliSecs()
	  For Local Entry:TGUIEntry = EachIn Self.EntryList
        If Entry.data.getInt("pid",0) = pid
		  If Entry.data.getInt("time",0) = 0 Then Entry.data.addNumber("time", MilliSecs() )
          If Entry.data.getInt("time",0) + timeout < RemoveTime
	        EntryList.Remove(Entry)
		    Print  "entry aged... removed "
	      EndIf
	    EndIf
  	    i = i + 1
 	  Next
 	  Return i
	End Method

' should be done in specific
	Method AddUniqueEntry:Int(title:string, value:string, owner:string, ip:string, port:int, time:Int, usefilter:String = "")
		If filter = "" Or filter = usefilter
			For Local Entry:TGUIEntry = EachIn Self.EntryList
				If Entry.data.getInt("pid", 0) = self._id AND ..
				   Entry.data.getString("ip", "0.0.0.0") = ip AND ..
				   Entry.data.getInt("port",0) = port

					If time = 0 Then time = MilliSecs()
					Entry.data.addNumber("time", time)
					Entry.data.addString("owner", owner)
					Entry.data.addString("value", value)
					Return 0
				EndIf
			Next
			local data:TData = new TData
			data.addString("title",title).addString("value", value).addString("owner", owner)
			data.addNumber("pid", self._id).addString("ip", ip).addNumber("port", port).addNumber("time",time)
			EntryList.AddLast( TGUIEntry.Create(data) )
		EndIf
	End Method

 	Method GetEntryCount:Int()
	    Return EntryList.count()
	End Method

'getters should be specific - eg. extension of list
 	Method GetEntryPort:Int()
	    Local i:Int = 0
	    For Local Entries:TGUIEntry = EachIn Self.EntryList
			If i = ListPosClicked then Return Entries.data.getInt("port",0)
  	      	i:+1
	    Next
	    return 0
	End Method

	Method GetEntryTime:Int()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn self.EntryList
   	        If i = ListPosClicked then Return Entries.data.getInt("time",0)
  	      	i:+1
	    Next
	    return 0
	End Method

	Method GetEntryValue:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn self.EntryList
			If i = ListPosClicked then Return Entries.data.getString("value", "")
  	      	i:+1
	    Next
	End Method

	Method GetEntryTitle:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn EntryList
			If i = ListPosClicked Then Return Entries.data.getString("title", "")
  	      	i:+1
	    Next
	End Method

	Method GetEntryIP:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn EntryList
 	        If i = ListPosClicked Then Return Entries.data.getString("ip", "0.0.0.0")
  	      	i:+1
	    Next
	End Method

	Method ClearEntries()
		EntryList.Clear()
	End Method

	Method AddEntry(title$, value$, owner:string, ip$, port:int, time:Int)
		If time = 0 Then time = MilliSecs()

		local data:TData = new TData
		data.addString("title",title).addString("value", value).addString("owner", owner)
		data.addNumber("pid", self._id).addString("ip", ip).addNumber("port", port).addNumber("time",time)
		EntryList.AddLast( TGUIEntry.Create(data) )
	End Method

	Method Update()
		local scrollTo:int = self.scroller.Update()
		if scrollTo = 1 and self.ListStartsAtPos > 0 then self.ListStartsAtPos :-1
		if scrollTo =-1 and self.ListStartsAtPos < Int(self.EntryList.Count() - 2) then self.ListStartsAtPos :+1
	End Method

	Method Draw()
		Local i:Int					= 0
		Local spaceavaiable:Int		= self.GetHeight() 'Hoehe der Liste
		Local controlWidth:Float	= ControlEnabled * gfx_GuiPack.GetSprite("ListControl").framew
		Local printvalue:String

		if self.background <> null then self.background.Draw()

	    For Local Entries:TGUIEntry = EachIn self.EntryList
			If i > ListStartsAtPos-1 AND SpaceAvaiable > TextHeight( Entries.data.getString("value", "") )
				printValue = Entries.data.getString("value", "")
				If Entries.data.getInt("owner", 0) > 0 then printValue = "[Team "+Entries.data.getInt("owner", 0) + "]: "+printValue

				While TextWidth(printValue+"...") > self.GetWidth()-4-18
					printvalue= printValue[..printvalue.length-1]
				Wend
				If Entries.data.getInt("owner", 0) > 0
					If printvalue <> "[Team "+Entries.data.getInt("owner", 0) + "]: "+Entries.data.getString("value", "") then printvalue = printvalue+"..."
				Else
					If printvalue <> Entries.data.getString("value", "") then printvalue = printvalue+"..."
				EndIf
				If i = ListPosClicked
					SetAlpha(0.5)
					SetColor(250,180,20)
					DrawRect(Self.rect.position.x+8,Self.rect.position.y+8+self.GetHeight()-SpaceAvaiable ,self.GetWidth()-20, TextHeight(printvalue))
					SetAlpha(1)
					SetColor(255,255,255)
				EndIf
				If ListPosClicked = i then SetColor(250, 180, 20)
				If functions.MouseIn(Self.rect.position.x + 5, Self.rect.position.y + 5 + self.GetHeight() - Spaceavaiable, self.GetWidth() - 1 - ControlWidth, useFont.getHeight(printvalue))
					SetAlpha(0.5)
					DrawRect(Self.rect.position.x+8,Self.rect.position.y+8+self.GetHeight()-SpaceAvaiable ,self.GetWidth()-20, useFont.getHeight(printvalue))
					SetAlpha(1)
					If MouseIsDown
						If LastMouseClickPos = i AND LastMouseClickTime + 50 < MilliSecs() And LastMouseClicktime +700 > MilliSecs()
							'registering is enough, trigger would be immediate but not needed
							EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", TData.Create().AddNumber("type", EVENT_GUI_DOUBLECLICK), self ) )
							'also trigger specific class event
							EventManager.registerEvent( TEventSimple.Create( self.getClassName()+".OnClick", TData.Create().AddNumber("type", EVENT_GUI_DOUBLECLICK), self ) )
						EndIf
						ListPosClicked		= i
						LastMouseClickTime	= MilliSecs()
						LastMouseClickPos	= i
					EndIf
				EndIf
				SetColor(55,55,55)
				Local text:String[] = printvalue.split(":")
				If Len(text) = 2 Then text[0] = text[0]+":"

				useFont.Draw(text[0], Self.rect.position.x+13, Self.rect.position.y+8+self.GetHeight()-SpaceAvaiable)
				SetColor(55,55,55)
				If Len(text) > 1
					useFont.Draw(text[1], Self.rect.position.x+13+useFont.getWidth(text[0]), Self.rect.position.y+8+self.GetHeight()-SpaceAvaiable)
					SetColor(255,255,255)
				EndIf
				SpaceAvaiable:-useFont.getHeight(printvalue)
			EndIf
			i:+1
  		Next

		If ControlEnabled = 1
			self.scroller.Draw()
		EndIf 'ControlEnabled

		SetColor 255,255,255
	End Method

End Type

Type TGUITextList Extends TGUIList
	field doFadeOut:int					= 0 'fade out old entries?
	field backgroundEnabled:int			= 0
	field backgroundColor:TColor		= TColor.Create(0,0,0)
	field guiListControl:TGW_Sprites	= null
'    Field turndirection:Int = 0

	Field OwnerNames:String[5]
	Field OwnerColors:TColor[5]

    Method Create:TGUITextList(x:Int, y:Int, width:Int, height:Int = 50, maxlength:Int = 128, State:String = "")
		super.Create(x,y,width,height,maxlength,State)

		return self
	End Method

	Method Update()
		Super.Update() 'normal List update

	    For Local Entries:TGUIEntry = EachIn self.EntryList 'Liste hier global
			If self.doFadeOut And (7 - Float(MilliSecs() - Entries.data.getInt("time", 0))/1000) <=0 Then EntryList.Remove(Entries)
		Next
	End Method

	Method Draw()
		if self.guiListControl = null then self.guiListControl = gfx_GuiPack.GetSprite("ListControl")

		Local SpaceAvaiable:Int	= 0
		Local i:Int				= 0
		Local chatinputheight:Int=0
		Local printvalue:String
		Local charcount:Int
		Local charpos:Int
		Local lineprintvalue:String=""
		SpaceAvaiable = Self.GetHeight() 'Hoehe der Liste
	    i = 0

		Local displace:Float = 0.0
	    For Local Entries:TGUIEntry = EachIn self.EntryList 'Liste hier global
			local entryAlpha:float = 1.0
			If self.doFadeOut then entryAlpha = (7 - Float(MilliSecs() - Entries.data.getInt("time",0) )/1000)

			If i > ListStartsAtPos-1
				If AutoScroll=1 And Self.useFont.getHeight( Entries.data.getString("value", "") ) > SpaceAvaiable-chatinputheight
					ListStartsAtPos :+1
				EndIf
				If Self.useFont.getHeight( Entries.data.getString("value", "") ) < SpaceAvaiable-chatinputheight
					Local playerID:Int = Entries.data.getInt("owner",1)
					Local dimension:TPoint
					Local nameWidth:Float=0.0
					Local blockHeight:Float = 0.0

					'0 = get dimensions
					'1 = draw the text
					For Local i:Int = 0 To 1
						If i = 1 AND self.backgroundEnabled
							SetAlpha Min(0.3, 0.3*entryAlpha)
							self.backgroundColor.Set()
							DrawRect(Self.GetX(), Self.GetY()+displace, self.GetWidth(), blockHeight)
							SetColor 255,255,255
						EndIf

						SetAlpha entryAlpha

						If PlayerID > 0
							dimension = TPoint(Self.useFont.drawStyled(Self.OwnerNames[PlayerID]+": ", Self.GetX()+2, Self.GetY()+displace +2, OwnerColors[PlayerID].r,OwnerColors[PlayerID].g,OwnerColors[PlayerID].b, 2,2, i))
						Else
							dimension = TPoint(Self.useFont.drawStyled("System:", Self.GetX()+2, Self.GetY()+displace +2, 50,50,50, 2,2, i))
						EndIf
						nameWidth = dimension.x
						blockHeight = Self.useFont.drawBlock(Entries.data.getString("value", ""), Self.GetX()+2+nameWidth, Self.GetY()+displace +2, self.GetWidth() - nameWidth, SpaceAvaiable, 0, 255,255,255,0,2, i)

						If i = 1 Then displace:+blockHeight
					Next
				EndIf
			EndIf
			i:+1
			If self.doFadeOut Then SetAlpha (1)
		Next

		if self.ControlEnabled 'AND ... SCROLLING NOTWENDIG
			self.scroller.Draw()
		endif

		SetColor 255,255,255
	End Method
End Type

'combination of elements
Type TGUIChat extends TGUIObject
	field panel:TGUIPanel
	field input:TGUIInput
	field list:TGUITextList

	Method Create:TGUIChat(x:Int, y:Int, width:Int = 100, height:Int= 100, title:string="", State:String = "", UseFont:TBitmapFont = Null)
'		super.Create(x,y,width,height,textalign,value,state, UseFont)

		self.setZIndex(10)
		If width < 40 Then width = 40
		self.rect.dimension.setXY( width, height )

		self.panel = new TGUIPanel.Create(0,0,width, height,state)
		self.panel.setParent(self)

		self.list = new TGUITextList.Create( 0,0,width, height, 100, state)

		'input.SetSelfManaged()
		self.list.ListStartsAtPos		= 0
		self.list.ListPosClicked		= -1
		self.list.AutoScroll			= 1
		self.list.setZIndex(self.zindex + 1)
		self.panel.AddElement(self.list) 'adding sets parent -> parent used for displacement

		self.input = new TGUIinput.Create(0, 0, width - 10, "", 100, state, null)
		self.input.rect.position.SetXY(5, height - self.input.GetHeight() - 5)
		'input.SetSelfManaged()
		self.input.color.adjust(50,50,50, True)
		self.input.maxlength	= 100
		self.input.setZIndex(self.zindex + 2)
		self.panel.AddElement(self.input)

		'subtract input from list height
		self.list.rect.dimension.MoveXY(0,-self.input.GetHeight() - 10)

		'obj.GUIbackground:TGUIbackground = New TGUIbackground
		'obj.GUIbackground.pos.setXY( x,y )
		'obj.GUIbackground.dimension.setXY( width, height )
		Return self
	End Method

	Method Draw()
		'
	End Method

	Method Update()
	End Method

	Method SetMaxLength(value:int)
		self.input.maxlength = value
	End Method
End Type