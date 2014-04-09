SuperStrict
'Author: Ronny Otto
Import "basefunctions.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_keymanager.bmx"
Import "basefunctions_localization.bmx"
Import "basefunctions_resourcemanager.bmx"
Import "basefunctions_events.bmx"

Rem
	Die Objekte sollten statt
		function Create:OBJECT
	eine Methode
		Create:OBJECT
	benutzen, falls ein Element	ein anderes "extends", dann in der Methode
		super.Create(parameter,...)
	aufrufen

	WICHTIG:	dadurch statt	local obj:Object = Object.Create(parameter)
								local obj:Object = new Object.Create(parameter)
				aufrufen (new instanziert neues Objekt, Create ist nur Methode)
EndRem


''''''GUIzeugs'
Const GUI_OBJECT_DRAGGED:Int					= 2^0
Const GUI_OBJECT_VISIBLE:Int					= 2^1
Const GUI_OBJECT_ENABLED:Int					= 2^2
Const GUI_OBJECT_CLICKABLE:Int					= 2^3
Const GUI_OBJECT_DRAGABLE:Int					= 2^4
Const GUI_OBJECT_MANAGED:Int					= 2^5
Const GUI_OBJECT_POSITIONABSOLUTE:Int			= 2^6
Const GUI_OBJECT_IGNORE_POSITIONMODIFIERS:Int	= 2^7
Const GUI_OBJECT_IGNORE_PARENTPADDING:Int		= 2^8
Const GUI_OBJECT_ACCEPTS_DROP:Int				= 2^9
Const GUI_OBJECT_CAN_RECEIVE_KEYSTROKES:Int		= 2^10
Const GUI_OBJECT_DRAWMODE_GHOST:Int				= 2^11

Const GUI_OBJECT_ORIENTATION_VERTICAL:Int			= 0
Const GUI_OBJECT_ORIENTATION_HORIZONTAL:Int			= 1


Global gfx_GuiPack:TGW_SpritePack = TGW_SpritePack.Create(LoadImage("res/grafiken/GUI/guipack.png"), "guipack_pack")
gfx_GuiPack.AddSprite(New TGW_Sprite.Create(Null, "ListControl", TRectangle.Create(96, 0, 56, 28), Null, 8, -1, TPoint.Create(14, 14)))
gfx_GuiPack.AddSprite(New TGW_Sprite.Create(Null, "DropDown", TRectangle.Create(160, 0, 126, 42), Null, 21, -1, TPoint.Create(14, 14)))
gfx_GuiPack.AddSprite(New TGW_Sprite.Create(Null, "Slider", TRectangle.Create(0, 30, 112, 14), Null, 8))
gfx_GuiPack.AddSprite(New TGW_Sprite.Create(Null, "Chat_IngameOverlay", TRectangle.Create(0, 60, 504, 20), Null))


Type TGUIManager
	Field globalScale:Float			= 1.0
	Field currentState:String		= ""			'which state are we currently handling?
	Field config:TData = new TData
	Field List:TList				= CreateList()
	Field ListReversed:TList		= CreateList()
	Field ListDragged:TList			= CreateList()	'contains dragged objects (above normal)
	Field ListDraggedReversed:TList	= CreateList()	'contains dragged objects in reverse (for draw)
	Field _defaultfont:TGW_BitmapFont
	'Field _lastDrawTick:int			= 0
	'Field _lastUpdateTick:int		= 0

	Field _ignoreMouse:Int			= False
	Field _keystrokeReceivingObject:TGUIObject = Null 'is there an object listening to keystrokes?
	Field modalActive:Int			= False			'modal dialogues will block every click etc.
	Global viewportX:Int=0,viewportY:Int=0,viewportW:Int=0,viewportH:Int=0

	Function Create:TGUIManager()
		Local obj:TGUIManager = New TGUIManager

		'is something dropping on a gui element?
		EventManager.registerListenerFunction( "guiobject.onDrop",	TGUIManager.onDrop )

		'gui specific settings
		obj.config.AddNumber("panelGap",10)


		Return obj
	End Function


	Method GetDefaultFont:TGW_BitmapFont()
		If Not _defaultFont Then _defaultFont = Assets.GetFont("Default", 12)

		Return _defaultFont
	End Method


	Method GetDraggedCount:Int()
		Return ListDragged.count()
	End Method


	Method GetDraggedNumber:Int(obj:TGUIObject)
		Local pos:Int = 0
		For Local guiObject:TGUIObject = EachIn ListDragged
			If guiObject = obj Then Return pos
			pos:+1
		Next
		Return 0
	End Method


	'dragged are above normal objects
	Method AddDragged:Int(obj:TGUIObject)
		obj.setOption(GUI_OBJECT_DRAGGED, True)
		obj._timeDragged = MilliSecs()

		If ListDragged.contains(obj) Then Return False

		ListDragged.addLast(obj)
		ListDragged.sort(False, SortObjects)
		ListDraggedReversed = ListDragged.Reversed()

		Return True
	End Method


	Method RemoveDragged:Int(obj:TGUIObject)
		obj.setOption(GUI_OBJECT_DRAGGED, False)
		obj._timeDragged = 0
		ListDragged.Remove(obj)
		ListDragged.sort(False, SortObjects)
		ListDraggedReversed = ListDragged.Reversed()

		Return True
	End Method


	Function onDrop:Int( triggerEvent:TEventBase )
		Local guiobject:TGUIObject = TGUIObject(triggerEvent.GetSender())
		If guiobject = Null Then Return False

		'find out if it hit a list...
		Local coord:TPoint = TPoint(triggerEvent.GetData().get("coord"))
		If Not coord Then Return False
		Local potentialDropTargets:TGuiObject[] = GUIManager.GetObjectsByPos(coord, GUIManager.currentState, True, GUI_OBJECT_ACCEPTS_DROP)
		Local dropTarget:TGuiObject = Null

		For Local potentialDropTarget:TGUIobject = EachIn potentialDropTargets
			'do not ask other targets if there was already one handling that drop
			If triggerEvent.isAccepted() Then Continue
			'do not ask other targets if one object already aborted the event
			If triggerEvent.isVeto() Then Continue

			'inform about drag and ask object if it wants to handle the drop
			potentialDropTarget.onDrop(triggerEvent)

			If triggerEvent.isAccepted() Then dropTarget = potentialDropTarget
		Next

		'if we haven't found a dropTarget stop processing that event
		If Not dropTarget
			triggerEvent.setVeto()
			Return False
		EndIf

		'we found an object accepting the drop

		'ask if something does not want that drop to happen
		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDropOnTarget", new TData.AddObject("coord", coord) , guiobject, dropTarget)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			event = TEventSimple.Create("guiobject.onDropOnTarget", new TData.AddObject("coord", coord) , guiobject, dropTarget)
			EventManager.triggerEvent( event )
		EndIf

		'if there is a veto happening (dropTarget does not want the item)
		'also veto the onDropOnTarget-event
		If event.isVeto()
			triggerEvent.setVeto()
			Return False
		Else
			'inform others: we successfully dropped the object to a target
			EventManager.triggerEvent( TEventSimple.Create("guiobject.onDropOnTargetAccepted", new TData.AddObject("coord", coord) , guiobject, dropTarget ))
			'also add this drop target as receiver of the original-drop-event
			triggerEvent._receiver = dropTarget
			Return True
		EndIf
	End Function


	Method RestrictViewport(x:Int,y:Int,w:Int,h:Int)
		GetViewport(viewportX,viewportY,viewportW,viewportH)
		SetViewport(x,y,w,h)
	End Method


	Method ResetViewport()
		SetViewport(viewportX,viewportY,viewportW,viewportH)
	End Method


	Method Add:Int(obj:TGUIobject, skipCheck:Int=False)
		obj.setOption(GUI_OBJECT_MANAGED, True)

		If Not skipCheck And list.contains(obj) Then Return True

		List.AddLast(obj)
		ListReversed.AddFirst(obj)
		SortLists()
	End Method


	Function SortObjects:Int(ob1:Object, ob2:Object)
		Local objA:TGUIobject = TGUIobject(ob1)
		Local objB:TGUIobject = TGUIobject(ob2)

		'-1 = bottom
		' 1 = top


		'undefined object - "a>b"
		If objA And Not objB Then Return 1

		'if objA and objB are dragged elements
		If objA._flags & GUI_OBJECT_DRAGGED And objB._flags & GUI_OBJECT_DRAGGED
			'if a drag was earlier -> move to top
			If objA._timeDragged < objB._timeDragged Then Return 1
			If objA._timeDragged > objB._timeDragged Then Return -1
			Return 0
		EndIf
		'if only objA is dragged - move to Top
		If objA._flags & GUI_OBJECT_DRAGGED Then Return 1
		'if only objB is dragged - move to A to bottom
		If objB._flags & GUI_OBJECT_DRAGGED Then Return -1

		'if objA is active element - move to top
		If objA.hasFocus() Then Return 1
		'if objB is active element - move to top
		If objB.hasFocus() Then Return -1

		'if objA is invisible, move to to end
		If Not(objA._flags & GUI_OBJECT_VISIBLE) Then Return -1
		If Not(objB._flags & GUI_OBJECT_VISIBLE) Then Return 1

		'if objA is "higher", move it to the top
		If objA.rect.position.z > objB.rect.position.z Then Return 1
		'if objA is "lower"", move to bottom
		If objA.rect.position.z < objB.rect.position.z Then Return -1

		'run custom compare job
'		return objA.compare(objB)
		Return 0
	End Function


	Method SortLists()
		List.sort(True, SortObjects)

		ListReversed = List.Reversed()
	End Method


	'only remove from lists (object cleanup has to get called separately)
	Method Remove:Int(obj:TGUIObject)
		obj.setOption(GUI_OBJECT_MANAGED, False)

		List.remove(obj)
		ListReversed.remove(obj)

		RemoveDragged(obj)

		'no need to sort on removal as the order wont change then (just one less)
		'SortLists()
		Return True
	End Method


	Method IsState:Int(obj:TGUIObject, State:String)
		If State = "" Then Return True

		State = state.toLower()
		Local states:String[] = state.split("|")
		Local objStates:String[] = obj.GetLimitToState().toLower().split("|")
		For Local limit:String = EachIn states
			For Local objLimit:String = EachIn objStates
				If limit = objLimit Then Return True
			Next
		Next
		Return False
	End Method


	'returns whether an object is hidden/invisible/inactive and therefor
	'does not have to get handled now
	Method haveToHandleObject:Int(obj:TGUIObject, State:String="", fromZ:Int=-1000, toZ:Int=-1000)
		'skip if parent has not to get handled
		If(obj._parent And Not haveToHandleObject(obj._parent,State,fromZ,toZ)) Then Return False

		'skip if not visible
		If Not(obj._flags & GUI_OBJECT_VISIBLE) Then Return False

		'skip if not visible by zindex
		If Not ( (toZ = -1000 Or obj.rect.position.z <= toZ) And (fromZ = -1000 Or obj.rect.position.z >= fromZ)) Then Return False

		'limit display by state - skip if object is hidden in that state
		'deep check only if a specific state is wanted AND the object is limited to states
		If(state<>"" And obj.GetLimitToState() <> "")
			Return IsState(obj, state)
		EndIf
		Return True
	End Method


	'returns an array of objects at the given point
	Method GetObjectsByPos:TGuiObject[](coord:TPoint, limitState:String=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
		If limitState=Null Then limitState = currentState

		Local guiObjects:TGuiObject[]
		'from TOP to BOTTOM (user clicks to visible things - which are at the top)
		For Local obj:TGUIobject = EachIn ListReversed
			'return array if we reached the limit
			If limit > 0 And guiObjects.length >= limit Then Return guiObjects

			If Not haveToHandleObject(obj, limitState) Then Continue

			'avoids finding the dragged object on a drop-event
			If Not ignoreDragged And obj.isDragged() Then Continue

			'if obj is required to accept drops, but does not so  - continue
			If (requiredFlags & GUI_OBJECT_ACCEPTS_DROP) And Not(obj._flags & GUI_OBJECT_ACCEPTS_DROP) Then Continue

			If obj.getScreenRect().containsXY( coord.getX(), coord.getY() )
				'add to array
				guiObjects = guiObjects[..guiObjects.length+1]
				guiObjects[guiObjects.length-1] = obj
			EndIf
		Next

		Return guiObjects
	End Method


	Method GetFirstObjectByPos:TGuiObject(coord:TPoint, limitState:String=Null, ignoreDragged:Int=True, requiredFlags:Int=0)
		Local guiObjects:TGuiObject[] = GetObjectsByPos(coord, limitState, ignoreDragged, requiredFlags, 1)

		If guiObjects.length = 0 Then Return Null Else Return guiObjects[0]
	End Method


	Method DisplaceGUIobjects(State:String = "", x:Int = 0, y:Int = 0)
		For Local obj:TGUIobject = EachIn List
			If isState(obj, State) Then obj.rect.position.MoveXY( x,y )
		Next
	End Method


	Method GetKeystrokeReceiver:TGUIobject()
		Return _keystrokeReceivingObject
	End Method


	Method SetKeystrokeReceiver:Int(obj:TGUIObject)
		If obj And obj.hasOption(GUI_OBJECT_CAN_RECEIVE_KEYSTROKES)
			_keystrokeReceivingObject = obj
		Else
			'just reset the old one
			_keystrokeReceivingObject = Null
		EndIf
	End Method


	Method GetFocus:TGUIObject()
		Return TGUIObject.GetFocusedObject()
	End Method


	Method SetFocus:Int(obj:TGUIObject)
		TGUIObject.SetFocusedObject(obj)

		'try to set as potential keystroke receiver
		SetKeystrokeReceiver(obj)
	End Method


	Method ResetFocus:Int()
		'remove focus (eg. when switching gamestates
		TGuiObject.SetFocusedObject(Null)

		'also remove potential keystroke receivers
		SetKeystrokeReceiver(Null)
	End Method


	Field UpdateState_mouseButtonDown:Int[]
	Field UpdateState_mouseButtonHit:Int[]
	Field UpdateState_mouseScrollwheelMovement:Int = 0
	Field UpdateState_foundHitObject:Int = False
	Field UpdateState_foundHoverObject:Int = False


	'should be run on start of the current tick
	Method StartUpdates:Int()
		UpdateState_mouseScrollwheelMovement = MOUSEMANAGER.GetScrollwheelmovement()

		UpdateState_mouseButtonDown = MOUSEMANAGER.GetAllStatusDown()
		UpdateState_mouseButtonHit = MOUSEMANAGER.GetAllStatusHit() 'single and double clicks!
	End Method

	'run after all other gui things so important values can get reset
	Method EndUpdates:Int()
		'ignoreMouse can be useful for objects which know, that nothing
		'else should take care of mouse movement/clicks
		_ignoreMouse	= False
		modalActive		= False
	End Method


	Method Update(State:String = "", fromZ:Int=-1000, toZ:Int=-1000)
		'_lastUpdateTick :+1
		'if _lastUpdateTick >= 100000 then _lastUpdateTick = 0

		currentState = State

		UpdateState_mouseScrollwheelMovement = MOUSEMANAGER.GetScrollwheelmovement()

		UpdateState_foundHitObject = False
		UpdateState_foundHoverObject = False
		Local screenRect:TRectangle = Null

		'store a list of special elements - maybe the list gets changed
		'during update... some elements will get added/destroyed...
		Local ListDraggedBackup:TList = ListDragged

		'first update all dragged objects...
		For Local obj:TGUIobject = EachIn ListDragged
			If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

			'avoid getting updated multiple times
			'this can be overcome with a manual "obj.Update()"-call
			'if obj._lastUpdateTick = _lastUpdateTick then continue
			'obj._lastUpdateTick = _lastUpdateTick

			obj.Update()
			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onUpdate", Null, obj ) )
		Next

		'then the rest
		For Local obj:TGUIobject = EachIn ListReversed 'from top to bottom
			'all dragged objects got already updated...
			If ListDraggedBackup.contains(obj) Then Continue

			If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

			'avoid getting updated multiple times
			'this can be overcome with a manual "obj.Update()"-call
			'if obj._lastUpdateTick = _lastUpdateTick then continue
			'obj._lastUpdateTick = _lastUpdateTick

			obj.Update()
			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onUpdate", Null, obj ) )
		Next
	End Method


	Method Draw:Int(State:String = "", fromZ:Int=-1000, toZ:Int=-1000)
		'_lastDrawTick :+1
		'if _lastDrawTick >= 100000 then _lastDrawTick = 0

		currentState = State

		For Local obj:TGUIobject = EachIn List
			'all special objects get drawn separately
			If ListDragged.contains(obj) Then Continue
			If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

			'avoid getting drawn multiple times
			'this can be overcome with a manual "obj.Draw()"-call
			'if obj._lastDrawTick = _lastDrawTick then continue
			'obj._lastDrawTick = _lastDrawTick

			'tint image if object is disabled
			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 0.5*GetAlpha()
			obj.Draw()
			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 2.0*GetAlpha()

			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
		Next

		'draw all dragged objects above normal objects...
		For Local obj:TGUIobject = EachIn listDraggedReversed
			If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

			'avoid getting drawn multiple times
			'this can be overcome with a manual "obj.Draw()"-call
			'if obj._lastDrawTick = _lastDrawTick then continue
			'obj._lastDrawTick = _lastDrawTick

			obj.Draw()

			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
		Next
	End Method
End Type
Global GUIManager:TGUIManager = TGUIManager.Create()



Type TGUIobject
	Field rect:TRectangle			= TRectangle.Create(-1,-1,-1,-1)
	Field positionBackup:TPoint		= Null
	Field padding:TRectangle		= TRectangle.Create(0,0,0,0)
	Field data:TData				= new TData 'storage for additional data
	Field scale:Float				= 1.0
	Field alpha:Float				= 1.0
	Field handlePosition:TPoint		= TPoint.Create(0, 0)		'where to attach the object
	Field contentPosition:TPoint	= TPoint.Create(0.5, 0.5)	'where to attach the content within the object
	Field state:String				= ""
	Field value:String				= ""
	Field mouseIsClicked:TPoint		= Null			'null = not clicked
	Field mouseIsDown:TPoint		= TPoint.Create(-1,-1)
	Field mouseover:Int				= 0			'could be done with TPoint
	Field children:TList			= Null
	Field _id:Int
	Field _flags:Int				= 0
	Field _timeDragged:Int			= 0			'time when item got dragged, maybe find a better name
	Field _parent:TGUIobject		= Null
	Field _limitToState:String		= ""		'fuer welchen gamestate anzeigen
	'Field _registeredListeners:TList= CreateList()
	Field handle:TPoint				= Null		'displacement of object when dragged (null = centered)
	Field useFont:TGW_BitmapFont
	Field className:String			= ""
	'Field _lastDrawTick:int			= 0
	'Field _lastUpdateTick:int		= 0

	Global ghostAlpha:Float			= 0.5
	Global _focusedObject:TGUIObject= Null
	Global _lastID:Int
	Global _debugMode:Int			= False

	Const ALIGN_LEFT:Float		= 0
	Const ALIGN_CENTER:Float	= 0.5
	Const ALIGN_RIGHT:Float		= 1.0
	Const ALIGN_TOP:Float		= 0
	Const ALIGN_BOTTOM:Float	= 1.0


	Method New()
		_lastID:+1
		_id = _lastID
		scale	= GUIManager.globalScale
		useFont = GUIManager.GetDefaultFont()
		className = TTypeId.ForObject(Self).Name()

		'default options
		setOption(GUI_OBJECT_VISIBLE, True)
		setOption(GUI_OBJECT_ENABLED, True)
		setOption(GUI_OBJECT_CLICKABLE, True)
	End Method


	Method CreateBase:TGUIobject(x:Float,y:Float, limitState:String="", useFont:TGW_BitmapFont=Null)
		If useFont <> Null Then Self.useFont = useFont
		rect.position.setXY( x,y )
		_limitToState = limitState
	End Method


	Method SetManaged(bool:Int)
		If bool
			If Not _flags & GUI_OBJECT_MANAGED Then GUIManager.add(Self)
		Else
			If _flags & GUI_OBJECT_MANAGED Then GUIManager.remove(Self)
		EndIf
	End Method


	Method AddEventListenerLink(link:TLink)
	End Method


	'cleanup function
	Method Remove:Int()
		'unlink all potential event listeners concerning that object
		EventManager.unregisterListenerByLimit(self,self)
'		For Local link:TLink = EachIn _registeredEventListener
'			link.Remove()
'		Next

		'maybe our parent takes care of us...
		If _parent Then _parent.RemoveChild(Self)

		'just in case we have a managed one
		'if _flags & GUI_OBJECT_MANAGED then
		GUIManager.remove(Self)

		Return True
	End Method


	Method getClassName:String()
		Return TTypeId.ForObject(Self).Name()
'		return self.className
	End Method


	'convencience function to return the uppermost parent
	Method GetUppermostParent:TGUIObject()
		'also possible:
		'getParent("someunlikelyname")
		if _parent then return _parent.GetUppermostParent()
		return self
	End Method
	

	Method getParent:TGUIobject(parentClassName:String="", strictMode:Int=False)
		'if no special parent is requested, just return the direct parent
		If parentClassName=""
			if _parent then Return _parent
			return self
		endif

		If _parent
			If _parent.getClassName().toLower() = parentClassName.toLower() Then Return _parent
			Return _parent.getParent(parentClassName)
		EndIf
		'if no parent - we reached the top level and just return self
		'as the searched parent
		'exception is "strictMode" which forces exactly that wanted parent
		If strictMode
			Return Null
		Else
			Return Self
		EndIf
	End Method


	'default drop handler for all gui objects
	'by default they do nothing
	Method onDrop:Int(triggerEvent:TEventBase)
		If hasOption(GUI_OBJECT_ACCEPTS_DROP)
			triggerEvent.SetAccepted(True)
		Else
			Return False
		EndIf
	End Method


	'default single click handler for all gui objects
	'by default they do nothing
	'singleClick: waited long enough to see if there comes another mouse click
	Method onSingleClick:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default double click handler for all gui objects
	'by default they do nothing
	'doubleClick: waited long enough to see if there comes another mouse click
	Method onDoubleClick:Int(triggerEvent:TEventBase)
		Return False
	End Method
	

	'default hit handler for all gui objects
	'by default they do nothing
	'click: no wait: mouse button was down and is now up again
	Method onClick:Int(triggerEvent:TEventBase)
		Return False
	End Method


	Method AddChild:Int(child:TGUIobject)
		'remove child from a prior parent to avoid multiple references
		If child._parent Then child._parent.RemoveChild(child)

		child.setParent( Self )
		If Not children Then children = CreateList()
		If children.addLast(child) Then GUIManager.Remove(child)
		children.sort(True, TGUIManager.SortObjects)
	End Method


	Method RemoveChild:Int(child:TGUIobject)
		If Not children Then Return False
		If children.Remove(child) Then GUIManager.Add(child)
	End Method


	Method UpdateChildren:Int()
		If Not children Then Return False

		'update added elements
		For Local obj:TGUIobject = EachIn children.Reversed()

			'avoid getting updated multiple times
			'this can be overcome with a manual "obj.Update()"-call
			'if obj._lastUpdateTick = GUIManager._lastUpdateTick then continue
			'obj._lastUpdateTick = GUIManager._lastUpdateTick

			obj.update()
		Next
	End Method


	Method RestrictViewport:Int()
		Local screenRect:TRectangle = GetScreenRect()
		If screenRect
			GUIManager.RestrictViewport(screenRect.getX(),screenRect.getY(), screenRect.getW(),screenRect.getH())
			Return True
		Else
			Return False
		EndIf
	End Method


	Method ResetViewport()
		GUIManager.ResetViewport()
	End Method


	'sets the currently focused object
	Function setFocusedObject(obj:TGUIObject)
		'if there was an focused object -> inform about removal of focus
		If obj <> _focusedObject And _focusedObject Then _focusedObject.removeFocus()
		'set new focused object
		_focusedObject = obj
		'if there is a focused object now - inform about gain of focus
		If _focusedObject Then _focusedObject.setFocus()
	End Function


	'returns the currently focused object
	Function getFocusedObject:TGUIObject()
		Return _focusedObject
	End Function


	'returns whether the current object is the focused one
	Method hasFocus:Int()
		Return (Self = _focusedObject)
	End Method


	'object gains focus
	Method setFocus:Int()
		Return True
	End Method


	'object looses focus
	Method removeFocus:Int()
		Return True
	End Method


	Method GetValue:String()
		Return value
	End Method


	Method hasOption:Int(option:Int)
		Return _flags & option
	End Method


	Method setOption(option:Int, enable:Int=True)
		If enable
			_flags :| option
		Else
			_flags :& ~option
		EndIf
	End Method


	Method isDragable:Int()
		Return _flags & GUI_OBJECT_DRAGABLE
	End Method


	Method isDragged:Int()
		Return _flags & GUI_OBJECT_DRAGGED
	End Method


	Method isVisible:Int()
		Return _flags & GUI_OBJECT_VISIBLE
	End Method


	Method Show()
		_flags :| GUI_OBJECT_VISIBLE
	End Method


	Method Hide()
		_flags :& ~GUI_OBJECT_VISIBLE
	End Method


	Method enable()
		If Not hasOption(GUI_OBJECT_ENABLED)
			_flags :| GUI_OBJECT_ENABLED
			GUIManager.SortLists()
		EndIf
	End Method


	Method disable()
		If hasOption(GUI_OBJECT_ENABLED)
			_flags :& ~GUI_OBJECT_ENABLED
			GUIManager.SortLists()
		EndIf
	End Method


	Method Resize(w:Float=Null,h:Float=Null)
		If w Then rect.dimension.setX(w)
		If h Then rect.dimension.setY(h)
	End Method


	'set the anchor of the gui object
	'valid values are 0-1.0 (percentage)
	Method SetHandlePosition:Int(handleLeft:Float=0.0, handleTop:Float=0.0)
		handlePosition = TPoint.Create(handleLeft, handleTop)
	End Method


	'set the anchor of the gui objects content
	'valid values are 0-1.0 (percentage)
	Method SetContentPosition:Int(contentLeft:Float=0.0, contentTop:Float=0.0)
		contentPosition = TPoint.Create(contentLeft, contentTop)
	End Method


	Method SetZIndex(zindex:Int)
		rect.position.z = zindex
		GUIManager.SortLists()
	End Method


	Method SetState(state:String="", forceSet:Int=False)
		If state <> "" Then state = "."+state
		If Self.state <> state Or forceSet
			'do other things (eg. events)
			Self.state = state
		EndIf
	End Method


	Method SetPadding:Int(top:Int,Left:Int,bottom:Int,Right:Int)
		padding.setTLBR(top,Left,bottom,Right)
		resize()
	End Method


	Method GetPadding:TRectangle()
		Return padding
	End Method


	Method drag:Int(coord:TPoint=Null)
		If Not isDragable() Or isDragged() Then Return False

		positionBackup = TPoint.Create( GetScreenX(), GetScreenY() )


		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDrag", new TData.AddObject("coord", coord), self)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			'trigger an event immediately - if the event has a veto afterwards, do not drag!
			Local event:TEventSimple = TEventSimple.Create( "guiobject.onDrag", new TData.AddObject("coord", coord), Self )
			EventManager.triggerEvent( event )
			If event.isVeto() Then Return False

			'nobody said "no" to drag, so drag it
			GuiManager.AddDragged(Self)
			GUIManager.SortLists()

			'inform others - item finished dragging
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onFinishDrag", new TData.AddObject("coord", coord), Self))

			Return True
		else
			Return FALSE
		endif
	End Method


	'forcefully drops an item back to the position when dragged
	Method dropBackToOrigin:Int()
		If Not positionBackup Then Return False
		drop(positionBackup, True)
		Return True
	End Method


	Method drop:Int(coord:TPoint=Null, force:Int=False)
		If Not isDragged() Then Return False

		If coord And coord.getX()=-1 Then coord = TPoint.Create(MouseManager.x, MouseManager.y)


		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDrop", new TData.AddObject("coord", coord), self)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()

			'fire an event - if the event has a veto afterwards, do not drop!
			'exception is, if the action is forced
			Local event:TEventSimple = TEventSimple.Create("guiobject.onDrop", new TData.AddObject("coord", coord), Self)
			EventManager.triggerEvent( event )
			If Not force And event.isVeto() Then Return False

			'nobody said "no" to drop, so drop it
			GUIManager.RemoveDragged(Self)
			GUIManager.SortLists()

			'inform others - item finished dropping - Receiver of "event" may now be helding the guiobject dropped on
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onFinishDrop", new TData.AddObject("coord", coord), Self, event.GetReceiver()))
			Return True
		else
			Return FALSE
		endif
	End Method


	Method setParent:Int(parent:TGUIobject)
		_parent = parent
	End Method


	Method GetUseFont:TGW_BitmapFont()
		Return useFont
	End Method


	'returns true if clicked
	Method isClicked:Int()
		If Not(_flags & GUI_OBJECT_ENABLED) Then mouseIsClicked = Null

		Return (mouseIsClicked<>Null)
	End Method


	Method SetLimitToState:Int(state:String)
		_limitToState = state
	End Method


	Method GetLimitToState:String()
		'if there is no limit set - ask parent if there is one
		If _limitToState="" And _parent Then Return _parent.GetLimitToState()

		Return _limitToState
	End Method


	Method GetScreenWidth:Float()
		Return rect.GetW()
	End Method


	Method GetScreenHeight:Float()
		Return rect.GetH()
	End Method


	Method GetScreenPos:TPoint()
		Return TPoint.Create(GetScreenX(), GetScreenY())
	End Method


	'adds parent position
	Method GetScreenX:Float()
		If (_flags & GUI_OBJECT_DRAGGED) And Not(_flags & GUI_OBJECT_IGNORE_POSITIONMODIFIERS)
			'no manual setup of handle exists -> center the spot
			If Not handle
				Return MouseManager.x - GetScreenWidth()/2 + 5*GUIManager.GetDraggedNumber(Self)
			Else
				Return MouseManager.x - GetHandle().x + 5*GUIManager.GetDraggedNumber(Self)
			EndIf
		EndIf

		'only integrate parent if parent is set, or object not positioned "absolute"
		If _parent And Not(_flags & GUI_OBJECT_POSITIONABSOLUTE)
			'ignore parental padding or not
			If Not(_flags & GUI_OBJECT_IGNORE_PARENTPADDING)
				'instead of "ScreenX", we ask the parent where it wants the Content...
				Return _parent.GetContentScreenX() + rect.GetX()
			Else
				Return _parent.GetScreenX() + rect.GetX()
			EndIf
		Else
			Return rect.GetX()
		EndIf
	End Method


	Method GetScreenY:Float()
		If (_flags & GUI_OBJECT_DRAGGED) And Not(_flags & GUI_OBJECT_IGNORE_POSITIONMODIFIERS)
			'no manual setup of handle exists -> center the spot
			If Not handle
				Return MouseManager.y - getScreenHeight()/2 + 7*GUIManager.GetDraggedNumber(Self)
			Else
				Return MouseManager.y - GetHandle().y/2 + 7*GUIManager.GetDraggedNumber(Self)
			EndIf
		EndIf
		'only integrate parent if parent is set, or object not positioned "absolute"
		If _parent And Not(_flags & GUI_OBJECT_POSITIONABSOLUTE)
			'ignore parental padding or not
			If Not(_flags & GUI_OBJECT_IGNORE_PARENTPADDING)
				'instead of "ScreenY", we ask the parent where it wants the Content...
				Return _parent.GetContentScreenY() + rect.GetY()
			Else
				Return _parent.GetScreenY() + rect.GetY()
			EndIf
		Else
			Return rect.GetY()
		EndIf
	End Method


	'override this methods if the object something like
	'virtual size or "addtional padding"

	'at which x-coordinate has content/children to be drawn
	Method GetContentScreenX:Float()
		Return GetScreenX() + padding.getLeft()
	End Method
	'at which y-coordinate has content/children to be drawn
	Method GetContentScreenY:Float()
		Return GetScreenY() + padding.getTop()
	End Method
	'available width for content/children
	Method GetContentScreenWidth:Float()
		Return GetScreenWidth() - (padding.getLeft() + padding.getRight())
	End Method
	'available height for content/children
	Method GetContentScreenHeight:Float()
		Return GetScreenHeight() - (padding.getTop() + padding.getBottom())
	End Method


	Method SetHandle:Int(handle:TPoint)
		Self.handle = handle
	End Method


	Method GetHandle:TPoint()
		Return handle
	End Method


	Method GetRect:TRectangle()
		Return rect
	End Method


	Method getDimension:TPoint()
		Return rect.dimension
	End Method


	'get a rectangle describing the objects area on the screen
	Method GetScreenRect:TRectangle()
		'dragged items ignore parents but take care of mouse position...
		If isDragged() Then Return TRectangle.Create(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )

		'no other limiting object - just return the object's area
		'(no move needed as it is already oriented to screen 0,0)
		If Not _parent
			If Not rect Then Print "NO SELF RECT"
			Return rect
		EndIf


		Local resultRect:TRectangle = _parent.GetScreenRect()
		'only try to intersect if the parent gaves back an intersection (or self if no parent)
		If resultRect
			'create a sourceRect which is a screen-rect (=visual!)
			Local sourceRect:TRectangle = TRectangle.Create( ..
										    GetScreenX(),..
										    GetScreenY(),..
										    GetScreenWidth(),..
										    GetScreenHeight() )

			'get the intersecting rectangle
			'the x,y-values are local coordinates!
			resultRect = resultRect.intersectRect( sourceRect )
			If resultRect
				'move the resulting rect by coord to get a screen-Rect
				resultRect.position.setXY(..
					Max(resultRect.position.getX(),getScreenX()),..
					Max(resultRect.position.getY(),GetScreeny())..
				)
				Return resultRect
			EndIf
		EndIf
		Return TRectangle.Create(0,0,-1,-1)
	End Method


	Method Draw() Abstract


	'used when an item is eg. dragged
	Method DrawGhost()
		Local oldAlpha:Float = GetAlpha()
		'by default a shaded version of the gui element is drawn at the original position
		SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, True)
		SetOption(GUI_OBJECT_DRAWMODE_GHOST, True)
		SetAlpha ghostAlpha * oldAlpha
		Draw()
		SetAlpha oldAlpha
		SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, False)
		SetOption(GUI_OBJECT_DRAWMODE_GHOST, False)
	End Method


	Method DrawChildren:Int()
		If Not children Then Return False

		'update added elements
		For Local obj:TGUIobject = EachIn children
			'before skipping a dragged one, we try to ask it as a ghost (at old position)
			If obj.isDragged() Then obj.drawGhost()
			'skip dragged ones - as we set them to managed by GUIManager for that time
			If obj.isDragged() Then Continue

			'avoid getting updated multiple times
			'this can be overcome with a manual "obj.Update()"-call
			'if obj._lastDrawTick = GUIManager._lastDrawTick then continue
			'obj._lastDrawTick = GUIManager._lastDrawTick


			'tint image if object is disabled
			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 0.5*GetAlpha()
			obj.draw()
			'tint image if object is disabled
			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 2.0*GetAlpha()
		Next
	End Method


	'returns whether a given coordinate is within the objects bounds
	'by default it just checks a simple rectangular bound
	Method containsXY:Int(x:Float,y:Float)
		'if not dragged ask parent first
		If Not isDragged() And _parent And Not _parent.containsXY(x,y) Then Return False
		Return GetScreenRect().containsXY(x,y)
	End Method



	Method Update:Int()
		'always be above parent
		If _parent And _parent.rect.position.z >= rect.position.z Then setZIndex(_parent.rect.position.z+10)

		If GUIManager._ignoreMouse then return FALSE

		'=== HANDLE MOUSE OVER ===

		'if nothing of the obj is visible or the mouse is not in
		'the visible part - reset the mouse states
		If Not containsXY(MouseManager.x, MouseManager.y)
			mouseIsDown		= Null
			mouseIsClicked	= Null
			mouseover		= 0
			setState("")

			'mouseclick somewhere - should deactivate active object
			'no need to use the cached mouseButtonDown[] as we want the
			'general information about a click
			If MOUSEMANAGER.isHit(1) And hasFocus() Then GUIManager.setFocus(Null)
		'mouse over object
		Else
			'inform others about a scroll with the mousewheel
			If GUIManager.UpdateState_mouseScrollwheelMovement <> 0
				Local event:TEventSimple = TEventSimple.Create("guiobject.OnScrollwheel", new TData.AddNumber("value", GUIManager.UpdateState_mouseScrollwheelMovement),Self)
				EventManager.triggerEvent(event)
				'a listener handles the scroll - so remove it for others
				If event.isAccepted()
					GUIManager.UpdateState_mouseScrollwheelMovement = 0
				EndIf
			EndIf
		EndIf


		'=== HANDLE MOUSE CLICKS / POSITION ===

		'skip non-clickable objects
		if not (_flags & GUI_OBJECT_CLICKABLE) then return FALSE
		'skip objects the mouse is not over.
		'ATTENTION: this differs to self.mouseOver (which is set later on)
		if not containsXY(MouseManager.x, MouseManager.y) then return FALSE


		'handle mouse clicks / button releases
		'only do something if
		'a) there is NO dragged object
		'b) we handle the dragged object
		'-> only react to dragged obj or all if none is dragged
		If Not GUIManager.GetDraggedCount() Or isDragged()

			'activate objects - or skip if if one gets active
			If GUIManager.UpdateState_mouseButtonDown[1] And _flags & GUI_OBJECT_ENABLED
				'create a new "event"
				If Not MouseIsDown
					'as soon as someone clicks on a object it is getting focused
					GUImanager.setFocus(Self)

					MouseIsDown = TPoint.Create( MouseManager.x, MouseManager.y )
				EndIf

				'we found a gui element which can accept clicks
				'dont check further guiobjects for mousedown
				'ATTENTION: do not use MouseManager.ResetKey(1)
				'as this also removes "down" state
				GUIManager.UpdateState_mouseButtonDown[1] = False
				GUIManager.UpdateState_mouseButtonHit[1] = False
				'MOUSEMANAGER.ResetKey(1)
			EndIf

			If Not GUIManager.UpdateState_foundHoverObject And _flags & GUI_OBJECT_ENABLED

				'do not create "mouseover" for dragged objects
				If Not isDragged()
					'create events
					'onmouseenter
					If mouseover = 0
						EventManager.registerEvent( TEventSimple.Create( "guiobject.OnMouseEnter", new TData, Self ) )
						mouseover = 1
					EndIf
					'onmousemove
					EventManager.registerEvent( TEventSimple.Create("guiobject.OnMouseOver", new TData, Self ) )
					GUIManager.UpdateState_foundHoverObject = True
				EndIf

				'somone decided to say the button is pressed above the object
				If MouseIsDown
					setState("active")
					EventManager.registerEvent( TEventSimple.Create("guiobject.OnMouseDown", new TData.AddNumber("button", 1), Self ) )
				Else
					setState("hover")
				EndIf

				'inform others about a right guiobject click
				'we do use a "cached hit state" so we can reset it if
				'we found a one handling it
				If GUIManager.UpdateState_mouseButtonHit[2]
					Local clickEvent:TEventSimple = TEventSimple.Create("guiobject.OnClick", new TData.AddNumber("button",2), Self)
					OnClick(clickEvent)
					'fire onClickEvent
					EventManager.triggerEvent(clickEvent)

					'maybe change to "isAccepted" - but then each gui object
					'have to modify the event IF they accepted the click
					
					'reset Button
					GUIManager.UpdateState_mouseButtonHit[2] = False
				EndIf

				If Not GUIManager.UpdateState_foundHitObject And _flags & GUI_OBJECT_ENABLED
					If MOUSEMANAGER.IsClicked(1)
						'=== SET CLICKED VAR ====
						mouseIsClicked = TPoint.Create( MouseManager.x, MouseManager.y)

						'=== SEND OUT CLICK EVENT ====
						'if recognized as "double click" no normal "onClick"
						'is emitted. Same for "single clicks".
						'this avoids sending "onClick" and after 100ms
						'again "onSingleClick" AND "onClick"
						Local clickEvent:TEventSimple
						If MOUSEMANAGER.IsDoubleClicked(1)
							clickEvent = TEventSimple.Create("guiobject.OnDoubleClick", new TData.AddNumber("button",1), Self)
							'let the object handle the click
							OnDoubleClick(clickEvent)
						ElseIf MOUSEMANAGER.IsSingleClicked(1)
							clickEvent = TEventSimple.Create("guiobject.OnSingleClick", new TData.AddNumber("button",1), Self)
							'let the object handle the click
							OnSingleClick(clickEvent)
						Else
							clickEvent = TEventSimple.Create("guiobject.OnClick", new TData.AddNumber("button",1), Self)
							'let the object handle the click
							OnClick(clickEvent)
						EndIf
						'fire onClickEvent
						EventManager.triggerEvent(clickEvent)

						'added for imagebutton and arrowbutton not being reset when mouse standing still
						MouseIsDown = Null
						'reset mouse button
						MOUSEMANAGER.ResetKey(1)

						'clicking on an object sets focus to it
						'so remove from old before
						If Not HasFocus() Then GUIManager.ResetFocus()

						GUIManager.UpdateState_foundHitObject = True
					EndIf
				EndIf
			EndIf
		EndIf
	End Method



	'eg. for buttons/inputfields/dropdownbase...
	Method DrawBaseForm(identifier:String, x:Float, y:Float)
		SetScale scale, scale
		Assets.GetSprite(identifier+".L").Draw(x,y)
		Assets.GetSprite(identifier+".M").TileDrawHorizontal(x + Assets.GetSprite(identifier+".L").area.GetW()*scale, y, GetScreenWidth() - ( Assets.GetSprite(identifier+".L").area.GetW() + Assets.GetSprite(identifier+".R").area.GetW())*scale, scale)
		Assets.GetSprite(identifier+".R").Draw(x + GetScreenWidth(), y, -1, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM), scale)
		SetScale 1.0,1.0
	End Method


	Method DrawBaseFormText:Object(_value:String, x:Float, y:Float)
		Local col:TColor = TColor.Create(100,100,100)
		If mouseover Then col = TColor.Create(50,50,50)
		If Not(_flags & GUI_OBJECT_ENABLED) Then col = TColor.Create(150,150,150)

		Return useFont.drawStyled(_value,x,y, col, 1, 1, 0.5)
	End Method


	'returns true if the conversion was successful
	Function ConvertKeystrokesToText:Int(value:String Var)
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
				If i = 69 And altGrPressed Then charToAdd = "¤"
				If i = 81 And altGrPressed Then charToAdd = "@"
				If shiftPressed Then charToAdd = Chr(i) Else charToAdd = Chr(i+32)
			EndIf
			value :+ charToAdd
		Next

		'num keys
		For Local i:Int = 96 To 105
			If KEYWRAPPER.pressedKey(i) Then charToAdd=i-96
		Next


		?Win32
        If KEYWRAPPER.pressedKey(186) Then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
        If KEYWRAPPER.pressedKey(192) Then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
        If KEYWRAPPER.pressedKey(222) Then If shiftPressed Then value:+ "Ä" Else value :+ "ä"
		?Linux
        If KEYWRAPPER.pressedKey(252) Then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
        If KEYWRAPPER.pressedKey(246) Then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
        If KEYWRAPPER.pressedKey(163) Then If shiftPressed Then value:+ "Ä" Else value :+ "ä"
		?
        If KEYWRAPPER.pressedKey(48) Then If shiftPressed Then value :+ "=" Else value :+ "0"
        If KEYWRAPPER.pressedKey(49) Then If shiftPressed Then value :+ "!" Else value :+ "1"
        If KEYWRAPPER.pressedKey(50) Then If shiftPressed Then value :+ Chr(34) Else value :+ "2"
        If KEYWRAPPER.pressedKey(51) Then If shiftPressed Then value :+ "§" Else value :+ "3"
        If KEYWRAPPER.pressedKey(52) Then If shiftPressed Then value :+ "$" Else value :+ "4"
        If KEYWRAPPER.pressedKey(53) Then If shiftPressed Then value :+ "%" Else value :+ "5"
        If KEYWRAPPER.pressedKey(54) Then If shiftPressed Then value :+ "&" Else value :+ "6"
        If KEYWRAPPER.pressedKey(55) Then If shiftPressed Then value :+ "/" Else value :+ "7"
        If KEYWRAPPER.pressedKey(56) Then If shiftPressed Then value :+ "(" Else value :+ "8"
        If KEYWRAPPER.pressedKey(57) Then If shiftPressed Then value :+ ")" Else value :+ "9"
        If KEYWRAPPER.pressedKey(223) Then If shiftPressed Then value :+ "?" Else value :+ "ß"
        If KEYWRAPPER.pressedKey(81) And altGrPressed Then value :+ "@"
		?win32
        If KEYWRAPPER.pressedKey(219) And shiftPressed Then value :+ "?"
        If KEYWRAPPER.pressedKey(219) And altGrPressed Then value :+ "\"
        If KEYWRAPPER.pressedKey(219) And Not altGrPressed And Not shiftPressed Then value :+ "ß"
        If KEYWRAPPER.pressedKey(221) Then If shiftPressed Then value :+ "`" Else value :+ "'"
        If KEYWRAPPER.pressedKey(226) Then If shiftPressed Then value :+ ">" Else value :+ "<"
		?linux
        If KEYWRAPPER.pressedKey(223) And shiftPressed Then value :+ "?"
        If KEYWRAPPER.pressedKey(223) And altGrPressed Then value :+ "\"
        If KEYWRAPPER.pressedKey(223) And Not altGrPressed And Not shiftPressed Then value :+ "ß"
        If KEYWRAPPER.pressedKey(37) Then If shiftPressed Then value :+ "`" Else value :+ "'"
        If KEYWRAPPER.pressedKey(60) Then If shiftPressed Then value :+ ">" Else value :+ "<"
		?
        If KEYWRAPPER.pressedKey(43) And shiftPressed Then value :+ "*"
        If KEYWRAPPER.pressedKey(43) And altGrPressed Then value :+ "~~"
        If KEYWRAPPER.pressedKey(43) And Not altGrPressed And Not shiftPressed Then value :+ "+"
	    If KEYWRAPPER.pressedKey(60) Then If shiftPressed Then value :+ "°" Else value :+ "^"
	    If KEYWRAPPER.pressedKey(35) Then If shiftPressed Then value :+ "'" Else value :+ "#"
	    If KEYWRAPPER.pressedKey(188) Then If shiftPressed Then value :+ ";" Else value :+ ","
	    If KEYWRAPPER.pressedKey(189) Then If shiftPressed Then value :+ "_" Else value :+ "-"
	    If KEYWRAPPER.pressedKey(190) Then If shiftPressed Then value :+ ":" Else value :+ "."
	    'numblock
	    If KEYWRAPPER.pressedKey(106) Then value :+ "*"
	    If KEYWRAPPER.pressedKey(111) Then value :+ "/"
	    If KEYWRAPPER.pressedKey(109) Then value :+ "-"
	    If KEYWRAPPER.pressedKey(109) Then value :+ "-"
	    If KEYWRAPPER.pressedKey(110) Then value :+ ","
	    For Local i:Int = 0 To 9
			If KEYWRAPPER.pressedKey(96+i) Then value :+ i
		Next
		'space
	    If KEYWRAPPER.pressedKey(32) Then value :+ " "
	    'remove with backspace
        If KEYWRAPPER.pressedKey(KEY_BACKSPACE) Then value = value[..value.length -1]

		If KEYWRAPPER.pressedKey(KEY_ESCAPE) Then Return False
		Return True
	End Function
End Type




Type TGUIButton Extends TGUIobject
	Field textalign:Int		= 0
	Field manualState:Int	= 0
	Field spriteName:String = "gfx_gui_button.default"


	Method Create:TGUIButton(pos:TPoint, width:Int=-1, value:String, State:String = "", UseFont:TGW_BitmapFont = Null)
		Super.CreateBase(pos.x,pos.y, State, UseFont)

		If width < 0 Then width = useFont.getWidth(value) + 8

		Self.Resize(width, Assets.GetNinePatchSprite(spriteName).area.GetH())
		Self.setZindex(10)
		Self.value		= value
		Self.textalign	= 1	'by default centered

    	GUIManager.Add( Self )
		Return Self
	End Method


	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		Local oldAlpha:Float = GetAlpha()

		SetColor 255, 255, 255

		SetAlpha oldAlpha * Self.alpha

		Local sprite:TGW_NinePatchSprite = Assets.GetNinePatchSprite(spriteName+Self.state, spriteName)
		sprite.DrawArea(atPoint.getX(), atPoint.getY(), rect.GetW(), rect.GetH())

		Local TextX:Float = Ceil(atPoint.GetX() + 10)
		Local TextY:Float = Ceil(atPoint.GetY() - (Self.useFont.getHeight("ABC") - Self.GetScreenHeight()) / 2)
		If Self.state =".active"
			TextX:+1
			TextY:+1
		EndIf
		If textalign = 1 Then TextX = Ceil(atPoint.GetX() + (Self.GetScreenWidth() - Self.useFont.getWidth(value)) / 2)

		Self.DrawBaseFormText(Self.value, TextX, TextY)

		SetAlpha oldAlpha
	End Method
End Type




Type TGUILabel Extends TGUIobject
	Field text:String = ""
	Field displacement:TPoint = TPoint.Create(0,0)
	Field color:TColor = TColor.Create(0,0,0)

	Global defaultLabelFont:TGW_BitmapFont


	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUILabel(x:Int,y:Int, text:String, color:TColor=Null, displacement:TPoint = Null, State:String="")
		Local useFont:TGW_BitmapFont = Self.defaultLabelFont
		Super.CreateBase(x,y, State, useFont)

		'by default labels have left aligned content
		SetContentPosition(ALIGN_LEFT, ALIGN_CENTER)

		Self.text = text
		If color Then Self.color = color
		If displacement Then Self.displacement = displacement

		GUIManager.Add( Self )
		Return Self
	End Method


	Function SetDefaultLabelFont(font:TGW_BitmapFont)
		If font <> Null Then TGUILabel.defaultLabelFont = font
	End Function


	Method Draw:Int()
		usefont.drawStyled(text, Floor(Self.GetScreenX() + contentPosition.x*(rect.GetW() - usefont.getWidth(text))) + Self.displacement.GetX(), Floor(Self.GetScreenY() + Self.displacement.GetY()), color, 1)
	End Method
End Type




Type TGUITextBox Extends TGUIobject
	Field valueAlignment:TPoint 	= TPoint.Create(0,0)
	Field valueColor:TColor			= TColor.Create(0,0,0)
	Field valueStyle:Int			= 0			'used in DrawBlock(...style)
	Field valueStyleSpecial:Float	= 1.0		'used in DrawBlock(...special)
	Field _autoAdjustHeight:Int		= False


	'will be added to general GuiManager
	'-- use CreateSelfContained to get a unmanaged object
	Method Create:TGUITextBox(x:Int,y:Int, w:Int,h:Int, text:String, color:TColor=Null, displacement:TPoint = Null, limitState:String="")
		Super.CreateBase(x,y, limitState, Null)
		Self.resize(w,h)
		Self.value = text
		If color Then Self.SetValueColor(color)

		GUIManager.Add(Self)
		Return Self
	End Method


	Method SetValueColor(color:TColor)
		valueColor = color
	End Method


	Method SetAutoAdjustHeight(bool:Int=True)
		Self._autoAdjustHeight = bool
	End Method


	Method SetValuePosition:Int(valueLeft:Float=0.0, valueTop:Float=0.0)
		rect.position.SetXY(valueLeft, valueTop)
	End Method


	Method GetHeight:Int(maxHeight:Int=800)
		If _autoAdjustHeight
			Return Min(maxHeight, GetUseFont().drawBlock(value, GetScreenX(), GetScreenY(), rect.GetW(), maxHeight, valueAlignment, Null, 1, 0).getY())
		Else
			Return rect.GetH()
		EndIf
	End Method


	Method SetValueAlignment(align:String="", valign:String="")
		Select align.ToUpper()
			Case "LEFT" 	valueAlignment.SetX(ALIGN_LEFT)
			Case "CENTER" 	valueAlignment.SetX(ALIGN_CENTER)
			Case "RIGHT" 	valueAlignment.SetX(ALIGN_RIGHT)

			Default	 		valueAlignment.SetX(ALIGN_LEFT)
		End Select

		Select valign.ToUpper()
			Case "TOP" 		valueAlignment.SetY(ALIGN_TOP)
			Case "CENTER" 	valueAlignment.SetY(ALIGN_CENTER)
			Case "BOTTOM" 	valueAlignment.SetY(ALIGN_BOTTOM)

			Default	 		valueAlignment.SetY(ALIGN_TOP)
		End Select
	End Method



	Method Draw:Int()
		Local drawPos:TPoint = TPoint.Create(GetScreenX(), GetScreenY())
		'horizontal alignment is done in drawBlock
		'vertical align
		drawPos.y :+ valueAlignment.GetY() * (GetHeight() - GetUseFont().getHeight(value))

		GetUseFont().drawBlock(value, drawPos.GetIntX(), drawPos.GetIntY(), rect.GetW(), rect.GetH(), valueAlignment, valueColor, 1, 1, 0.25)
	End Method

End Type




Type TGUIImageButton Extends TGUIobject
	Field startframe:Int		= 0
	Field spriteBaseName:String	= ""
	Field caption:TGUILabel		= Null


	Method Create:TGUIImageButton(x:Int, y:Int, spriteBaseName:String, State:String = "", startframe:Int = 0)
		Super.CreateBase(x,y, State, Null)

		Self.spriteBaseName	= spriteBaseName
		Self.startframe		= startframe
		Self.Resize( Assets.getSprite(spriteBaseName).area.GetW(), Assets.getSprite(spriteBaseName).area.GetH() )
		Self.value			= ""

		GUIManager.Add( Self )
		Return Self
	End Method


	Method SetCaption:TGUIImageButton(caption:String, color:TColor=Null, position:TPoint=Null)
		Self.caption = New TGUILabel.Create(Self.rect.GetX(), Self.rect.GetY(), caption,color,position)
		'we want to manage it...
		GUIManager.Remove(Self.caption)

		'unmanaged label -> we have to position it ourself
		If Self.caption And Self.caption._flags & GUI_OBJECT_ENABLED
			Self.caption.rect.position.SetPos( Self.rect.position )
			Self.caption.rect.dimension.SetPos( Self.rect.dimension )
		EndIf
		Return Self
	End Method


	Method GetCaption:TGUILabel()
		Return Self.caption
	End Method


	Method GetCaptionText:String()
		If Self.caption Then Return Self.caption.text Else Return ""
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		SetColor 255,255,255

		Local sprite:TGW_Sprite = Assets.GetSprite(Self.spriteBaseName + state, Self.spriteBaseName)

		'no clicked image found: displace button and caption by 1,1
		If sprite.GetName() = Self.spriteBaseName And state=".active"
			sprite.draw(atPoint.GetX() + 1, atPoint.GetY() + 1)
			If Self.caption And Self.caption._flags & GUI_OBJECT_ENABLED
				Self.caption.rect.position.MoveXY(1, 1)
				Self.caption.Draw()
				Self.caption.rect.position.MoveXY(-1, -1)
			EndIf
		Else
			sprite.draw(atPoint.GetX(), atPoint.GetY())
			If Self.caption And Self.caption._flags & GUI_OBJECT_ENABLED Then Self.caption.Draw()

			If Self.mouseover
				'only "non clicked" state has hover
				Local oldAlpha:Float = GetAlpha()
				SetBlend LightBlend
				SetAlpha 0.20*oldAlpha
				sprite.draw(atPoint.GetX(), atPoint.GetY())
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			EndIf
		EndIf
	End Method
End Type




Type TGUIBackgroundBox Extends TGUIobject
	Field sprite:TGW_NinePatchSprite
	Field spriteAlpha:Float = 1.0


	Method Create:TGUIBackgroundBox(x:Int, y:Int, width:Int = 100, height:Int= 100, State:String = "")
		Super.CreateBase(x,y, State, Null)

		Self.Resize( width, height )
		Self.setZindex(0)
		Self.setOption(GUI_OBJECT_CLICKABLE, False) 'by default not clickable

		Self.sprite = Assets.GetNinePatchSprite("gfx_gui_panel")

		GUIManager.Add( Self )

		Return Self
	End Method


	Method DrawBackground:Int()
		Local drawPos:TPoint = GetScreenPos()
		Local oldAlpha:Float = GetAlpha()
		SetAlpha spriteAlpha*oldAlpha
		sprite.DrawArea(drawPos.getX(), drawPos.getY(), GetScreenWidth(), GetScreenHeight())
		SetAlpha oldAlpha
	End Method


	Method Update:Int()
		UpdateChildren()

		Super.Update()
	End Method


	Method Draw()
		DrawBackground()
		DrawChildren()
		SetColor 255,255,255
	End Method
End Type




Type TGUIArrowButton  Extends TGUIObject
    Field direction:String
    Field arrowSprite:TGW_Sprite
	Field buttonSprite:TGW_NinePatchSprite
	Field spriteBaseName:String			= "gfx_gui_icon_arrow"
	Field spriteButtonBaseName:String	= "gfx_gui_button.round"


	Method Create:TGUIArrowButton(area:TRectangle=Null, direction:String="LEFT", limitState:String = "")
		If Not area Then area = TRectangle.Create(0,0,-1,-1)
		Super.CreateBase(area.GetX(), area.GetY(), State, Null)

		SetDirection(direction)
		setZindex(40)
		setState("", True) 'force update
		value = ""
		Resize(area.GetW(), area.GetH() )

		'let the guimanager manage the button
		GUIManager.Add( Self )

		Return Self
	End Method


	Method SetDirection(direction:String="LEFT")
		Select direction.ToUpper()
			Case "LEFT"		Self.direction="Left"
			Case "UP"		Self.direction="Up"
			Case "RIGHT"	Self.direction="Right"
			Case "DOWN"		Self.direction="Down"
			Default			Self.direction="Left"
		EndSelect
		Self.arrowSprite = Assets.GetSprite(spriteBaseName+Self.direction)
		If Not Self.arrowSprite Then Throw("Sprite ~q"+spriteBaseName+Self.direction+"~q not defined.")
	End Method


	'override so we have a minimum size
	Method Resize(w:Float=Null,h:Float=Null)
		If Not buttonSprite Then Return
		'set to minimum size or bigger
		rect.dimension.setX( Max(w, buttonSprite.GetBorder().GetLeft() + buttonSprite.GetBorder().GetRight()))
		rect.dimension.sety( Max(h, buttonSprite.GetBorder().GetTop() + buttonSprite.GetBorder().GetBottom()))
	End Method


	'override so we set the button sprite accordingly
	Method SetState(state:String="", forceUpdate:Int=False)
		If state <> "" Then state = "."+state
		If Self.state <> state Or forceUpdate
			Self.state = state
			buttonSprite = Assets.GetNinePatchSprite(spriteButtonBaseName+Self.state, spriteButtonBaseName)
		EndIf
	End Method


	'override default draw-method
	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		Local oldAlpha:Float = GetAlpha()
		SetColor 255, 255, 255

		SetAlpha oldAlpha * Self.alpha

		'draw button (background)
		If buttonSprite Then buttonSprite.DrawArea(atPoint.getX(), atPoint.getY(), rect.GetW(), rect.GetH())
		'draw arrow at center of button
		arrowSprite.Draw(atPoint.getX() + Int((rect.GetW()-arrowSprite.GetWidth())/2), atPoint.getY() + Int((rect.GetH()-arrowSprite.GetHeight())/2))

		SetAlpha oldAlpha
	End Method
End Type




Type TGUISlider Extends TGUIobject
    Field minvalue:Int
    Field maxvalue:Int
    Field actvalue:Int = 50
    Field addvalue:Int = 0
    Field drawvalue:Int = 0


	Method Create:TGUISlider(x:Int, y:Int, width:Int, minvalue:Int, maxvalue:Int, value:String, State:String = "")
		Super.CreateBase(x,y,State,Null)

		If width < 0 Then width = TextWidth(value) + 8
		Self.Resize( width, gfx_GuiPack.GetSprite("Button").frameh )
		Self.value		= value
		Self.minvalue	= minvalue
		Self.maxvalue	= maxvalue
		Self.actvalue	= minvalue

		GUIMAnager.Add( Self )
		Return Self
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


	Method GetValue:String()
		Return actvalue + addvalue
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		Local sprite:TGW_Sprite = gfx_GuiPack.GetSprite("Slider")

		Local PixelPerValue:Float = Self.GetScreenWidth() / (maxvalue - 1 - minvalue)
	    Local actvalueX:Float = actvalue * PixelPerValue
	    Local maxvalueX:Float = (maxvalue) * PixelPerValue
		Local difference:Int = actvalueX

		If Self.mouseIsDown
			difference = MouseManager.x - Self.rect.position.x + PixelPerValue / 2
			actvalue = Float(difference) / PixelPerValue
			If actvalue > maxvalue Then actvalue = maxvalue
			If actvalue < minvalue Then actvalue = minvalue
			actvalueX = difference'actvalue * PixelPerValue
			If actvalueX >= maxValueX - sprite.framew Then actvalueX = maxValueX - sprite.framew
		EndIf

  		If Ceil(actvalueX) < sprite.framew
			'links an
			sprite.DrawClipped(atPoint, TRectangle.Create(0,0, Ceil(actvalueX) + 5, -1), 4)
			'links aus
  		    sprite.DrawClipped(atPoint, TRectangle.Create(0,0,-1,-1), 0)
		Else
			sprite.Draw(atPoint.GetX(), atPoint.GetY(), 4)
		EndIf
  		If Ceil(actvalueX) > Self.GetScreenWidth() - sprite.framew
			Local rightAtPoint:TPoint = atPoint.Copy()
			rightAtPoint.MoveX(Self.GetScreenWidth() - sprite.framew)
			'links an
			sprite.DrawClipped(rightAtPoint, TRectangle.Create(0,0, Ceil(actvalueX) - (Self.GetScreenWidth() - sprite.framew) + 5, -1), 6)
  		    'links aus
  		    sprite.DrawClipped(rightAtPoint, TRectangle.Create(0,0,-1,-1), 2)
		Else
			sprite.Draw(atPoint.GetX() + GetScreenWidth(), atPoint.GetY(), 2, TPoint.Create(ALIGN_LEFT, ALIGN_BOTTOM) )
		EndIf


		' middle
		'      \
		' [L][++++++()-----][R]
		' MaxWidth = GuiObj.w - [L].w - [R].w
		Local maxWidth:Float	= Self.GetScreenWidth() - 2*sprite.framew
		Local reachedWidth:Float= Min(maxWidth, actvalueX - sprite.framew)
		Local missingWidth:Float= maxWidth - reachedWidth
		'gefaerbter Balken
		sprite.TileDrawHorizontal(atPoint.GetX() + sprite.framew, atPoint.GetY(), reachedWidth, Self.scale, 1 + 4)
		'ungefaerbter Balken
		If missingWidth > 0 Then sprite.TileDrawHorizontal(atPoint.GetX() + sprite.framew + reachedWidth, atPoint.GetY(), missingWidth, Self.scale, 1)

	    'dragger  -5px = Mitte des Draggers
	    Local mouseIsDown:Int = 1
	    If Self.mouseIsDown Then mouseIsDown=0

		sprite.Draw(atPoint.GetX() + Ceil(actvalueX - 5), atPoint.GetY(), 3 + mouseIsDown * 4)


		'draw label/text
		If Self.value = "" Then Return

		Local DrawText:String = Self.value
		If drawvalue <> 0 Then DrawText = (actvalue + addvalue) + " " + DrawText

		Self.Usefont.draw(value, atPoint.GetX() + Self.GetScreenWidth() + 7, atPoint.GetY() - (Self.useFont.getHeight(DrawText) - Self.GetScreenHeight()) / 2 - 1)
	End Method
End Type




Type TGUIinput Extends TGUIobject
    Field maxLength:Int
    Field maxTextWidth:Int
    Field color:TColor					= TColor.Create(0,0,0)
    Field spriteName:String				= "gfx_gui_input.default"
    Field overlayArea:TRectangle
    Field overlaySprite:TGW_Sprite		= Null		'icon to display separately
    Field overlayText:String			= ""		'text to display separately
	Field overlayPosition:String		= ""		'empty=none, "left", "right"
	Field valueDisplacement:TPoint

	Field _valueChanged:Int				= 0 '1 if changed
	Field _valueBeforeEdit:String		= ""
	Field _activated:Int				= False

	Global minDimension:TPoint 				= TPoint.Create(40,28)
    Global spriteNameDefault:String			= "gfx_gui_input.default"


    Method Create:TGUIinput(x:Int, y:Int, w:Int, h:Int, initialValue:String, maxLength:Int=128, State:String="")
		Super.CreateBase(x,y,State)

		Self.setZindex(20)
		Self.Resize(Max(w, minDimension.x), Max(h, minDimension.y))
		Self.value			= initialValue
		Self.maxLength		= maxLength
		Self.color			= TColor.Create(120,120,120)

		'this element reacts to keystrokes
		Self.setOption(GUI_OBJECT_CAN_RECEIVE_KEYSTROKES, True)

		GUIMAnager.Add( Self )
	  	Return Self
	End Method


	Method SetMaxLength:Int(maxLength:Int)
		Self.maxLength = maxLength
	End Method


	Method SetValueDisplacement(x:Int, y:Int)
		Self.valueDisplacement = TPoint.Create(x,y)
	End Method


	'(this creates a backup of the old value)
	Method SetFocus()
		Super.SetFocus()
		'backup old value
		_valueBeforeEdit = value
		'GuiManager.SetKeystrokeReceiver(self)
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		If Self._flags & GUI_OBJECT_ENABLED
			'manual entering "focus" with ENTER-key is not intended,
			'this is done by the app/game with "if enter then setFocus..."

			'enter pressed means: finished editing -> loose focus too
			If KEYMANAGER.isHit(KEY_ENTER) And hasFocus()
				KEYMANAGER.blockKey(KEY_ENTER, 200) 'to avoid auto-enter on a chat input
				GuiManager.ResetFocus()
				If Self = GuiManager.GetKeystrokeReceiver() Then GuiManager.SetKeystrokeReceiver(Null)
			EndIf

			'as soon as an input field is marked as active input
			'all key strokes could change the input
			If Self = GuiManager.GetKeystrokeReceiver()
				If Not ConvertKeystrokesToText(value)
					value = _valueBeforeEdit

					'do not allow another ESC-press for 150ms
					KeyManager.blockKey(KEY_ESCAPE, 150)

					If Self = GuiManager.GetKeystrokeReceiver() Then GuiManager.SetKeystrokeReceiver(Null)
					GuiManager.ResetFocus()
				Else
					_valueChanged = (_valueBeforeEdit <> value)
				EndIf
			EndIf

			'if input is not the active input (enter key or clicked on another input)
			'and the value changed, inform others with an event
			If Self <> GuiManager.GetKeystrokeReceiver() And _valueChanged
				'reset changed indicator
				_valueChanged = False

				'fire onChange-event (text changed)
				EventManager.registerEvent( TEventSimple.Create( "guiobject.onChange", new TData.AddNumber("type", 1).AddString("value", value), Self ) )
			EndIf
		EndIf
		'set to "active" look
		If Self = GuiManager.GetKeystrokeReceiver() Then setState("active")

		'limit input length
        If value.length > maxlength Then value = value[..maxlength]
	End Method


    Method SetOverlayPosition:Int(position:String="left")
		Select position.toLower()
			Case "left" 	overlayPosition = "iconLeft"
			Case "right" 	overlayPosition = "iconRight"
			Default			overlayPosition = ""
		EndSelect
    End Method


	Method SetOverlay:Int(sprite:TGW_Sprite=Null, text:String="")
		overlaySprite = sprite
		overlayText = text
		'give it an default orientation
		If overlayPosition = "" Then SetOverlayPosition("left")

		If Not overlayArea Then overlayArea = TRectangle.Create(0,0,0,0)
		If overlaySprite
			overlayArea.dimension.SetXY(overlaySprite.GetWidth(), overlaySprite.GetHeight())
		ElseIf overlayText<>""
			overlayArea.dimension.SetXY(useFont.GetWidth(overlayText), useFont.GetHeight(overlayText))
		EndIf

	End Method


	Method GetspriteName:String()
		If overlayPosition<>"" Then Return spriteName + "."+overlayPosition
		Return spriteName
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()

		Local textPos:TPoint
		Local inputWidth:Int = rect.GetW()
		If Not valueDisplacement
			textPos = TPoint.Create(5, (rect.GetH() - useFont.getHeight("a")) /2)
		Else
			textPos = valueDisplacement.copy()
		EndIf

		'===== DRAW BACKGROUND SPRITE ====
		'if a spriteName is set, we use a spriteNameDefault,
		'else we just skip drawing the sprite
		Local sprite:TGW_NinePatchSprite
		If spriteName<>"" Then sprite = Assets.GetNinePatchSprite(GetSpriteName() + Self.state, spriteNameDefault)
		If sprite
			Local overlayBGWidth:Int= 0

			If overlayArea And overlayArea.GetW() > 0 And overlayPosition<>""
				'draw background for overlay  [.][  Input  ]
				Local overlayBGSprite:TGW_NinePatchSprite = Assets.GetNinePatchSprite(GetSpriteName() + ".background" + Self.state)
				If overlayBGSprite
					'overlay background width is overlay + background  borders
					overlayBGWidth = overlayArea.GetW() + overlayBGSprite.GetBorder().GetLeft() + overlayBGSprite.GetBorder().GetRight()
					If overlayPosition = "iconLeft"
						overlayBGSprite.DrawArea(atPoint.GetX(), atPoint.getY(), overlayBGWidth, rect.GetH())
					ElseIf overlayPosition = "iconRight"
						overlayBGSprite.DrawArea(atPoint.GetX() + rect.GetW() - overlayBGWidth, atPoint.getY(), overlayBGWidth, rect.GetH())
					EndIf
				EndIf

				'draw the icon or label if needed
				Local borderHalf:Int = (overlayBGSprite.GetBorder().GetLeft() + overlayBGSprite.GetBorder().GetRight())/2
				If overlayPosition = "iconLeft"
					overlayArea.position.SetX(borderHalf)
				ElseIf overlayPosition = "iconRight"
					overlayArea.position.SetX(rect.GetW() + overlayBGWidth - borderHalf - overlayArea.GetW())
				EndIf
				overlayArea.position.SetY((rect.GetH()- overlayArea.GetH())/2)
				If overlaySprite
					overlaySprite.Draw(atPoint.GetX() + overlayArea.GetX(), atPoint.getY() + overlayArea.GetY())
				ElseIf overlayText<>""
					usefont.Draw(overlayText, atPoint.GetX() + overlayArea.GetX(), atPoint.getY() + overlayArea.GetY())
				EndIf
			EndIf

			'move sprite by Icon-Area (and decrease width)
			If overlayPosition = "iconLeft" Then atPoint.MoveXY(overlayBGWidth,0)
			inputWidth :- overlayBGWidth

			sprite.DrawArea(atPoint.GetX(), atPoint.getY(), inputWidth, rect.GetH())
			'move text according to content borders
			textPos.SetX(Max(textPos.GetX(), sprite.GetContentBorder().GetLeft()))


		EndIf

	    Local i:Int					= 0
		Local printValue:String		= value

		'limit maximal text width
		Self.maxTextWidth = inputWidth - textPos.GetX()*2

		'if we are the input receiving keystrokes, symbolize it with the
		'blinking underscore sign "text_"
		'else just draw it like a normal gui object
		If Self = GuiManager.GetKeystrokeReceiver()
			color.copy().AdjustFactor(-80).SetRGB()
			While Len(printvalue) >1 And useFont.getWidth(printValue + "_") > maxTextWidth
				printvalue = printValue[1..]
			Wend
			useFont.draw(printValue, Int(atPoint.GetX() + textPos.GetX()), Int(atPoint.GetY() + textPos.GetY()))

			SetAlpha Ceil(Sin(MilliSecs() / 4))
			useFont.draw("_", Int(atPoint.GetX() + textPos.GetX() + useFont.getWidth(printValue)), Int(atPoint.GetY() + textPos.GetY()) )
			SetAlpha 1
	    Else
			color.setRGB()
			While useFont.GetWidth(printValue) > maxTextWidth And printvalue.length > 0
				printvalue = printValue[..printvalue.length - 1]
			Wend

			useFont.drawStyled(printValue, atPoint.GetX() + textPos.GetX(), atPoint.GetY() + textPos.GetY(), color, 1)
		EndIf

		SetColor 255, 255, 255
	End Method
End Type




'data objects for gui objects (eg. dropdown entries, list entries, ...)
Type TGUIEntry
	Field formatValue:String = "#value"		'how to format value
	Field id:Int							'internal gui id
	Field data:TData						'custom data


	Function Create:TGUIEntry(data:TData=Null)
		Local obj:TGUIEntry = New TGUIEntry
		obj.data	= data
		Return obj
	End Function


	Method setFormatValue(newValue:String)
		Self.formatValue = newValue
	End Method


	Method getValue:String()
		Return Self.data.getString("value", "")
	End Method
End Type




Type TGUIDropDown Extends TGUIobject
    Field Values:String[]
	Field EntryList:TList = CreateList()
    Field PosChangeTimer:Int
	Field clickedEntryID:Int=-1
	Field hoveredEntryID:Int=-1
	Field textalign:Int = 0
	Field heightIfOpen:Float = 0


	Method Create:TGUIDropDown(x:Int, y:Int, width:Int = -1, value:String, limitState:String = "")
		Super.CreateBase(x,y,limitState,Null)

		If width < 0 Then width = Self.useFont.getWidth(value) + 8
		Self.Resize( width, Assets.GetSprite("gfx_gui_dropdown.L").frameh * Self.scale)
		Self.value		= value
		Self.heightIfOpen = Self.rect.GetH()

		GUIManager.Add( Self )
		Return Self
	End Method


	'overwrite default method
	Method GetScreenHeight:Float()
		Return Self.heightIfOpen
	End Method


	Method SetActiveEntry(id:Int)
		Self.clickedEntryID = id
		Self.value = TGUIEntry(Self.EntryList.ValueAtIndex(id)).getValue()
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

        If Not(Self._flags & GUI_OBJECT_ENABLED) Then Self.mouseIsClicked = Null

		If Not Self.hasFocus() Or Not Self.mouseIsDown Then Return False

		Local currentAddY:Int = Self.rect.GetH() 'ignore "if open"
		Local lineHeight:Float = Assets.GetSprite("gfx_gui_dropdown_list_entry.L").area.GetH()*Self.scale

		'reset hovered item id ...
		Self.hoveredEntryID = -1

		'check new hovered or clicked items
		For Local Entry:TGUIEntry = EachIn Self.EntryList 'Liste hier global
			If TFunctions.MouseIn( Self.GetScreenX(), Self.GetScreenY() + currentAddY, Self.GetScreenWidth(), lineHeight)
				If MOUSEMANAGER.IsHit(1)
					value			= Entry.getValue()
					clickedEntryID	= Entry.id
		'			GUIManager.setActive(0)
					EventManager.registerEvent( TEventSimple.Create( "guiobject.OnChange", new TData.AddNumber("entryID", entry.id), Self ) )
					'threadsafe?
					MOUSEMANAGER.ResetKey(1)
					Exit
				Else
					hoveredEntryID	= Entry.id
				EndIf
			EndIf
			currentAddY:+ lineHeight
		Next
		'store height if opened
		Self.heightIfOpen = Self.rect.GetH() + currentAddY


		If hoveredEntryID > 0
			Self.setState("hover")
		Else
			'clicked outside of list
			'Print "RONFOCUS: clicked outside of list, remove focus from "+Self._id
			If MOUSEMANAGER.IsHit(1) Then GUIManager.setFocus(Null)
		EndIf
	End Method


	Method AddEntry(value:String)
		Local entry:TGUIEntry = TGUIEntry.Create( new TData.AddString("value", value) )
		EntryList.AddLast(entry)
		If Self.value = "" Then Self.value = entry.getValue()
		If Self.clickedEntryID = -1 Then Self.clickedEntryID = entry.id
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
	    Local i:Int					= 0
	    Local j:Int					= 0
	    Local useheight:Int			= 0
	    Local printheight:Int		= 0

		'draw list if enabled
		If Self._flags & GUI_OBJECT_ENABLED 'ausgeklappt zeichnen
			useheight = Self.rect.GetH()
			For Local Entry:TGUIEntry = EachIn Self.EntryList
				If Self.EntryList.last() = Entry
					Self.DrawBaseForm( "gfx_gui_dropdown_list_bottom", atPoint.GetX(), atPoint.GetY() + useheight )
				Else
					Self.DrawBaseForm( "gfx_gui_dropdown_list_entry", atPoint.GetX(), atPoint.GetY() + useheight )
				EndIf

				SetColor 100,100,100

				If Entry.id = Self.clickedEntryID Then SetColor 0,0,0
				If Entry.id = Self.hoveredEntryID Then SetColor 150,150,150

				If textalign = 1 Then Self.useFont.draw( Entry.getValue(), atPoint.GetX() + (Self.GetScreenWidth() - Self.useFont.getWidth( Entry.GetValue() ) ) / 2, atPoint.GetY() + useheight + 5)
				If textalign = 0 Then Self.useFont.draw( Entry.getValue(), atPoint.GetX() + 10, atPoint.GetY() + useHeight + 5)
				SetColor 255,255,255

				'move y to next spot
				If Self.EntryList.last() = Entry
					useheight:+ Assets.GetSprite("gfx_gui_dropdown_list_bottom.L").area.GetH()*Self.scale
				Else
					useheight:+ Assets.GetSprite("gfx_gui_dropdown_list_entry.L").area.GetH()*Self.scale
				EndIf
			Next
		EndIf

		'draw base button
		Self.DrawBaseForm( "gfx_gui_dropdown"+Self.state, atPoint.GetX(), atPoint.GetY() )

		'text on button
		Self.DrawBaseFormText(value, atPoint.GetX() + 10, atPoint.GetY() + Self.rect.GetH()/2 - Self.useFont.getHeight(value)/2)
		SetColor 255, 255, 255

		'debuglog ("GUIradiobutton zeichnen")
	End Method
End Type



Type TGUICheckBox  Extends TGUIObject
    Field _checked:Int=False
    Field _showValue:Int=True
    Field checkSprite:TGW_Sprite
	Field buttonSprite:TGW_NinePatchSprite
	Field spriteBaseName:String			= "gfx_gui_icon_check"
	Field spriteButtonBaseName:String	= "gfx_gui_button.round"

	Method Create:TGUICheckbox(area:TRectangle=Null, checked:Int=False, labelValue:String, limitState:String="", useFont:TGW_BitmapFont=Null)
		If Not area Then area = TRectangle.Create(0,0,-1,-1)
		Super.CreateBase(area.GetX(), area.GetY(), limitState, Null)

		setZindex(40)
		setState("", True) 'force update
		Self.value = labelValue
		SetChecked(checked, False) 'without sending events

		Resize(area.GetW(), area.GetH() )

		'let the guimanager manage the button
		GUIManager.Add( Self )

		Return Self
	End Method



	Method SetChecked(checked:Int=True, informOthers:Int=True)
		'if already same state - do nothing
		If _checked = checked Then Return

		_checked = checked

		'set sprite
		checkSprite = Null
		If checked
			checkSprite = Assets.GetSprite(spriteBaseName)
			If Not checkSprite Then Throw("Sprite ~q"+spriteBaseName+"~q not defined.")
		EndIf

		If informOthers Then EventManager.registerEvent(TEventSimple.Create("guiCheckBox.onSetChecked", new TData.AddNumber("checked", checked), Self ) )
	End Method


	Method SetShowValue:Int(bool:Int=True)
		_showValue = bool
	End Method


	'override so we have a minimum size
	Method Resize(w:Float=Null,h:Float=Null)
		If Not buttonSprite Then Return
		'set to minimum size or bigger
		rect.dimension.setX( Max(w, buttonSprite.GetBorder().GetLeft() + buttonSprite.GetBorder().GetRight()))
		rect.dimension.sety( Max(h, buttonSprite.GetBorder().GetTop() + buttonSprite.GetBorder().GetBottom()))
	End Method


	'override so we set the button sprite accordingly
	Method SetState(state:String="", forceUpdate:Int=False)
		'disable "active state"
		If state = "active" Then state = "hover"

		If state <> "" Then state = "."+state

		If Self.state <> state Or forceUpdate
			Self.state = state
			buttonSprite = Assets.GetNinePatchSprite(spriteButtonBaseName+Self.state, spriteButtonBaseName)
		EndIf
	End Method


	Method IsChecked:Int()
		Return _checked
	End Method


	'override default to (un)check box
	Method onClick:Int(triggerEvent:TEventBase)
		local button:int = triggerEvent.GetData().GetInt("button", -1)
		'only react to left mouse button
		if button <> 1 then return FALSE

		'set box (un)checked
		SetChecked(1-isChecked())
	End Method
	

	'override default draw-method
	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		Local oldAlpha:Float = GetAlpha()
		SetColor 255, 255, 255

		SetAlpha oldAlpha * Self.alpha

		Local buttonWidth:Int = rect.GetH() 'square...

		'draw button (background)
		If buttonSprite Then buttonSprite.DrawArea(atPoint.getX(), atPoint.getY(), buttonWidth, rect.GetH())
		'draw checks sprite at center of button
		If checkSprite Then checkSprite.Draw(atPoint.getX() + Int((buttonWidth-checkSprite.GetWidth())/2), atPoint.getY() + Int((rect.GetH()-checkSprite.GetHeight())/2))

		If _showValue
			Local col:TColor = TColor.Create(75,75,75)
			If isChecked() Then col = col.AdjustFactor(-50)
			If mouseover Then col = col.AdjustFactor(-25)

			useFont.drawStyled(value, atPoint.GetX() + buttonWidth + 5, Int(atPoint.GetY() + (GetScreenHeight()- useFont.GetHeight("Aq")) / 2) +2, col, 1 )
		EndIf

		SetAlpha oldAlpha
	End Method
End Type




Type TGUIWindow Extends TGUIPanel
	Field guiCaptionTextBox:TGUITextBox
	Field guiCaptionArea:TRectangle
	Field _defaultCaptionColor:TColor


	Method Create:TGUIWindow(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		Super.Create(x,y,width,height,limitState)

		'create background, setup text etc.
		Self.InitContent(width, height)

		Self.resize(width,height)
		Return Self
	End Method


	Method InitContent(width:Int, height:Int)
		If Not guiBackground
			SetBackground(New TGUIBackgroundBox.Create(0,0,width,height,""))
		Else
			guiBackground.rect.position.SetXY(0,0)
			guiBackground.resize(width, height)
		EndIf
		guiBackground.sprite= Assets.GetNinePatchSprite("gfx_gui_window", "gfx_gui_panel")

		SetCaption("Window")
		guiCaptionTextBox.usefont = Assets.GetFont("Default", 16, BOLDFONT)

		guiBackground.SetZIndex(0) 'absolute background of all children
		guiCaptionTextBox.SetZIndex(1)

		'we want to hand it by ourself
		AddChild(guiBackground)
		AddChild(guiCaptionTextBox)
	End Method


	Method SetCaptionArea(area:TRectangle)
		guiCaptionArea = area.copy()
	End Method

	'override for different alignment
	Method SetValue(value:String="")
		Super.SetValue(value)
		If guiTextBox Then guiTextBox.SetValueAlignment("LEFT", "TOP")

	End Method


	Method SetCaption:Int(caption:String="")
		If caption=""
			If guiCaptionTextBox
				guiCaptionTextBox.remove()
				guiCaptionTextBox = Null
			EndIf
		Else
			Local rect:TRectangle = Null
			'if an area was defined - use this instead of an automatic area
			If guiCaptionArea
				rect = guiCaptionArea
			Else
				Local padding:TRectangle = guiBackground.sprite.GetContentBorder()
				rect = TRectangle.Create(padding.GetLeft(), 0, GetContentScreenWidth(), padding.GetTop())
			EndIf

			If Not guiCaptionTextBox
				'create the caption container
				guiCaptionTextBox = New TGUITextBox.Create(rect.GetX(), rect.GetY(), rect.GetW(), rect.GetH(), caption, Null, Null, "")

				If _defaultCaptionColor
					guiCaptionTextBox.SetValueColor(_defaultCaptionColor)
				Else
					guiCaptionTextBox.SetValueColor(TColor.clWhite)
				EndIf
				guiCaptionTextBox.SetValueAlignment("CENTER", "CENTER")
				guiCaptionTextBox.SetAutoAdjustHeight(False)
				guiCaptionTextBox.SetZIndex(1)
				'set to ignore parental padding (so it starts at 0,0)
				guiCaptionTextBox.SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)

				addChild(guiCaptionTextBox)
			EndIf

			'reposition in all cases
			guiCaptionTextBox.rect.position.SetXY(rect.GetX(), rect.GetY())
			guiCaptionTextBox.resize(rect.GetW(), rect.GetH())
			guiCaptionTextBox.value = caption
		EndIf
	End Method


	Method SetCaptionAndValue:Int(caption:String="", value:String="")
		SetCaption(caption)
		SetValue(value)

		Local oldTextboxHeight:Float = guiTextBox.rect.GetH()
		Local newTextboxHeight:Float = guiTextBox.getHeight()

		'resize window
		Self.resize(0, rect.getH() + newTextboxHeight - oldTextboxHeight)
		Return True
	End Method


	Method Draw:Int()
		Super.Draw()
	End Method
End Type




Type TGUIModalWindow Extends TGUIWindow
	Field DarkenedArea:TRectangle	= Null
	Field buttons:TGUIButton[]
	Field autoAdjustHeight:Int		= True
	'variables for closing animation
	Field moveAcceleration:Float	= 1.2
	Field moveDY:Float				= -1.0
	Field moveOld:TPoint			= TPoint.Create(0,0)
	Field move:TPoint				= TPoint.Create(0,0)
	Field fadeValueOld:Float		= 1.0
	Field fadeValue:Float			= 1.0
	Field fadeFactor:Float			= 0.9
	Field fadeActive:Float			= False
	Field isSetToClose:Int			= False

	Method Create:TGUIModalWindow(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		Super.Create(x,y,width,height,limitState)

		setZIndex(10000)

		'by default just a "ok" button
		SetDialogueType(1)

		'use another sprite as base background
		Local sprite:TGW_NinePatchSprite = Assets.GetNinePatchSprite("gfx_gui_modalWindow")
		If sprite Then guiBackground.sprite = sprite

		'we want to know if one clicks on a windows buttons
		EventManager.registerListenerMethod("guiobject.onClick", Self, "onButtonClick")

		'fire event so others know that the window is created
		EventManager.triggerEvent(TEventSimple.Create("guiModalWindow.onCreate", Self))
		Return Self
	End Method


	'easier setter for dialogue types
	Method SetDialogueType:Int(typeID:Int)
		For Local button:TGUIobject = EachIn Self.buttons
			button.remove()
			removeChild(button)
		Next
		buttons = New TGUIButton[0] '0 sized array

		Select typeID
			'a default button
			Case 1
					buttons = buttons[..1]
					buttons[0] = New TGUIButton.Create(TPoint.Create(0, 0), 120, "OK")
					AddChild(buttons[0])
			'yes and no button
			Case 2
					buttons = buttons[..2]
					buttons[0] = New TGUIButton.Create(TPoint.Create(0, 0), 90, GetLocale("YES"))
					buttons[0].SetZIndex(1)
					buttons[1] = New TGUIButton.Create(TPoint.Create(0, 0), 90, GetLocale("NO"))
					buttons[1].SetZIndex(1)
					AddChild(buttons[0])
					AddChild(buttons[1])
		End Select
	End Method


	Method Resize:Int(w:Float=Null,h:Float=Null)
		Super.Resize()

		'move button
		If buttons.length = 1
			buttons[0].rect.position.setXY(rect.GetW()/2 - buttons[0].rect.GetW()/2, rect.GetH()-50)
		ElseIf buttons.length = 2
			buttons[0].rect.position.setXY(rect.GetW()/2 - buttons[0].rect.GetW() - 10, rect.GetH()-50)
			buttons[1].rect.position.setXY(rect.GetW()/2 + 10, rect.GetH()-50)
		EndIf

		Recenter()
	End Method


	Method Recenter:Int(moveBy:TPoint=Null)
		'center the window
		Local centerX:Float=0.0
		Local centerY:Float=0.0
		If Not darkenedArea
			centerX = VirtualWidth()/2
			centerY = VirtualHeight()/2
		Else
			centerX = DarkenedArea.getX() + DarkenedArea.GetW()/2
			centerY = DarkenedArea.getY() + DarkenedArea.GetH()/2
		EndIf

		If Not moveBy Then moveBy = TPoint.Create(0,0)
		Self.rect.position.setXY(centerX - Self.rect.getW()/2 + moveBy.getX(),centerY - Self.rect.getH()/2 + moveBy.getY() )
	End Method


	'cleanup function
	Method Remove:Int()
		Super.remove()

		'button is managed from guimanager
		'so we have to delete that separately
		For Local button:TGUIobject = EachIn Self.buttons
			button.remove()
		Next
		Return True
	End Method


	'close the window (eg. with an animation)
	Method Close:Int(closeButton:Int=-1)
		Self.isSetToClose = True

		'no animation just calls "remove"
		'but we want a nice fadeout
		Self.fadeActive = True

		'fire event so others know that the window is closed
		'and what button was used
		'ATTENTION: maybe instead of self = sender wie should use
		'TGUIModalWindow(self) so the listeners can fetch it correctly
		EventManager.triggerEvent(TEventSimple.Create("guiModalWindow.onClose", new TData.AddNumber("closeButton", closeButton) , Self))
	End Method


	Method canClose:Int()
		If Self.fadeActive Then Return False

		Return True
	End Method


	'handle clicks on the up/down-buttons and inform others about changes
	Method onButtonClick:Int( triggerEvent:TEventBase )
		Local sender:TGUIButton = TGUIButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		For Local i:Int = 0 To Self.buttons.length - 1
			If Self.buttons[i] <> sender Then Continue

			'close window
			Self.close(i)
		Next
	End Method


	'override default update-method
	Method Update:Int()
		'maybe children intercept clicks...
		UpdateChildren()

		Super.Update()

		'remove the window as soon as there is no animation active
		If isSetToClose
			If canClose()
				Self.remove()
				Return False
			Else
				If fadeActive
					'backup for tweening
					fadeValueOld = fadeValue
					fadeValue :* fadeFactor
				EndIf
				'buttons are managed by guimanager, so we have to set
				'their alpha here so they can draw correctly
				For Local i:Int = 0 To buttons.length-1
					buttons[i].alpha = fadeValue
				Next
				'quit fading when nearly zero
				If fadeValue < 0.05 Then fadeActive = False

				'move the dialogue too
				'- first increase the speed
				moveDY :* moveAcceleration
				'backup old move for tweening, store fade as .z
				moveold.setXY(0, move.y)
				'- now displace the objects
				move.moveXY(0, moveDY)
			EndIf
		EndIf

		Self.recenter(move)

		GUIManager.modalActive = True

		'deactivate mousehandling for other underlying objects
		GUIManager._ignoreMouse = True
	End Method


	Method Draw()
		'move to tweened move-position
		Self.recenter(GetTweenPoint(move, moveOld, True))

		SetAlpha Max(0, 0.5 * GetTweenResult(fadeValue, fadeValueOld, True))
		SetColor 0,0,0
		If Not DarkenedArea
			DrawRect(0,0,GraphicsWidth(), GraphicsHeight())
		Else
			DrawRect(DarkenedArea.getX(),DarkenedArea.getY(),DarkenedArea.getW(), DarkenedArea.getH())
		EndIf
		SetAlpha Max(0, 1.0 * GetTweenResult(fadeValue, fadeValueOld, True))

		SetColor 255,255,255

		'draw the window - done by DrawChildren
		'self.guiBackground.draw()

		DrawChildren()

		SetAlpha 1.0
	End Method
End Type




Type TGUIPanel Extends TGUIObject
	Field guiBackground:TGUIBackgroundBox	= Null
	Field guiTextBox:TGUITextBox
	Field _defaultValueColor:TColor


	Method Create:TGUIPanel(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		Self.rect.setXYWH(x, y, width, height)
		Self._limitToState = limitState

		GUIManager.Add( Self )
		Return Self
	End Method


	Method Resize:Int(w:Float=Null,h:Float=Null)
		'resize self
		If w Then rect.dimension.setX(w) Else w = rect.GetW()
		If h Then rect.dimension.setY(h) Else h = rect.GetH()

		'move background
		If guiBackground Then guiBackground.resize(w,h)
		'move textbox
		If guiTextBox
			If guiBackground
				guiTextBox.resize(guiBackground.GetContentScreenWidth(),guiBackground.GetContentScreenHeight())
			Else
				guiTextBox.resize(GetContentScreenWidth(),GetContentScreenHeight())
			EndIf
		EndIf
	End Method


	Method SetBackground(obj:TGUIBackgroundBox=Null)
		'reset to nothing?
		If Not obj
			If guiBackground
				removeChild(guiBackground)
				guiBackground.remove()
				guiBackground = Null
			EndIf
		Else
			guiBackground = obj
			'set background to ignore parental padding (so it starts at 0,0)
			guiBackground.SetOption(GUI_OBJECT_IGNORE_PARENTPADDING, True)

			addChild(obj) 'manage it by our own
		EndIf
	End Method


	Method GetValue:String()
		If guiTextBox Then Return guiTextBox.value
		Return ""
	End Method


	Method SetValue(value:String="")
		If value=""
			If guiTextBox
				guiTextBox.remove()
				guiTextBox = Null
			EndIf
		Else
			Local padding:TRectangle = guiBackground.sprite.GetContentBorder()
			guiTextBox = New TGUITextBox.Create(padding.GetLeft(),padding.GetTop(),0,0, value, Null, Null, "")
			If _defaultValueColor
				guiTextBox.SetValueColor(_defaultValueColor)
			Else
				guiTextBox.SetValueColor(TColor.clWhite)
			EndIf
			guiTextBox.SetValueAlignment("CENTER", "CENTER")
			guiTextBox.SetAutoAdjustHeight(True)
			'we take care of the text box
			addChild(guiTextBox)
		EndIf
	End Method


	Method disableBackground()
		If guiBackground Then guiBackground.disable()
	End Method


	Method enableBackground()
		If guiBackground Then guiBackground.enable()
	End Method


	Method Update()
		'Super.Update()
		UpdateChildren()
	End Method


	Method Draw()
		DrawChildren()
	End Method
End Type




Type TGUIScrollablePanel Extends TGUIPanel
	Field scrollPosition:TPoint	= TPoint.Create(0,0)
	Field scrollLimit:TPoint	= TPoint.Create(0,0)
	Field minSize:TPoint		= TPoint.Create(0,0)


	Method Create:TGUIScrollablePanel(x:Int, y:Int, width:Int = 100, height:Int= 100, limitState:String = "")
		Super.Create(x,y,width,height,limitState)
		Self.minSize.SetXY(50,50)

		Return Self
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float=Null,h:Float=Null)
		If w And w >= minSize.GetX() Then rect.dimension.setX(w)
		If h And h >= minSize.GetY() Then rect.dimension.setY(h)

	End Method


	'override getters - to adjust values by scrollposition
	Method GetScreenHeight:Float()
		Return Min(Super.GetScreenHeight(), minSize.getY())
	End Method


	'override getters - to adjust values by scrollposition
	Method GetScreenWidth:Float()
		Return Min(Super.GetScreenWidth(), minSize.getX())
	End Method


	Method GetContentScreenY:Float()
		Return Super.GetContentScreenY() + scrollPosition.getY()
	End Method


	Method GetContentScreenX:Float()
		Return Super.GetContentScreenX() + scrollPosition.getX()
	End Method


	Method SetLimits:Int(lx:Float,ly:Float)
		scrollLimit.setXY(lx,ly)
	End Method


	Method Scroll:Int(dx:Float,dy:Float)
		scrollPosition.MoveXY(dx, dy)

		'check limits
		scrollPosition.SetY(Min(0, scrollPosition.GetY()))
		scrollPosition.SetY(Max(scrollPosition.GetY(), scrollLimit.GetY()))
	End Method


	Method RestrictViewport:Int()
		Local screenRect:TRectangle = Self.GetScreenRect()
		If screenRect
			GUIManager.RestrictViewport(screenRect.getX(),screenRect.getY() - scrollPosition.getY(), screenRect.getW(),screenRect.getH())
			Return True
		Else
			Return False
		EndIf
	End Method
End Type




Type TGUIScroller Extends TGUIobject
	Field sprite:TGW_Sprite
	Field mouseDownTime:Int					= 200	'milliseconds until we react on "mousedown"
	Field guiButtonMinus:TGUIArrowButton	= Null
	Field guiButtonPlus:TGUIArrowButton 	= Null
	Field _orientation:int					= GUI_OBJECT_ORIENTATION_VERTICAL

	Method Create:TGUIScroller(parent:TGUIobject)
		sprite 		= gfx_GuiPack.GetSprite("ListControl")
		setParent(parent)

		'create buttons
		guiButtonMinus		= New TGUIArrowButton.Create(Null, "UP", "")
		guiButtonPlus		= New TGUIArrowButton.Create(Null, "DOWN", "")

		'from button width, calculate position on own parent

		rect.position.setXY(parent.rect.getW() - guiButtonMinus.rect.getW(),0)
		'this also aligns the buttons
		Resize(parent.rect.getW(), parent.rect.getH())

		'set the parent of the buttons so they inherit visible state etc.
		guiButtonMinus.setParent(Self)
		guiButtonPlus.setParent(Self)

		'scroller is interested in hits (not clicks) on its buttons
		EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScroller.onButtonClick, Self.guiButtonMinus )
		EventManager.registerListenerFunction( "guiobject.onClick",	TGUIScroller.onButtonClick, Self.guiButtonPlus )
		EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScroller.onButtonDown, Self.guiButtonMinus )
		EventManager.registerListenerFunction( "guiobject.onMouseDown",	TGUIScroller.onButtonDown, Self.guiButtonPlus )

		GUIManager.Add( Self)

		Return Self
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float=Null,h:Float=Null)
		'according the orientation we limit height or width
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				h = guiButtonMinus.rect.getH()
				'if w <= 0 then w = rect.GetW()
			case GUI_OBJECT_ORIENTATION_VERTICAL
				w = guiButtonMinus.rect.getW()
				'if h <= 0 then h = rect.GetH()
		End Select
		Super.Resize(w,h)

		'move the first button to the most left and top position
		guiButtonMinus.rect.position.SetXY(0, 0)
		'move the second button to the most right and bottom position
		guiButtonPlus.rect.position.SetXY(GetScreenWidth() - guiButtonPlus.GetScreenWidth(), GetScreenHeight() - guiButtonPlus.GetScreenHeight())
	End Method


	Method SetOrientation:int(orientation:Int=0)
		if _orientation = orientation then return FALSE

		_orientation = orientation
		Select _orientation
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				guiButtonMinus.SetDirection("LEFT")
				guiButtonPlus.SetDirection("RIGHT")
				'set scroller area to full WIDTH of parent
				if GetParent() then rect.dimension.SetX(GetParent().rect.getW())
			default
				guiButtonMinus.SetDirection("UP")
				guiButtonPlus.SetDirection("DOWN")
				'set scroller area to full height of parent
				if GetParent() then rect.dimension.SetY(GetParent().rect.getH())
		End Select

		Resize()

		return TRUE
	End Method


	'handle clicks on the up/down-buttons and inform others about changes
	Function onButtonClick:Int( triggerEvent:TEventBase )
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		If guiScroller = Null Then Return False

		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "up").AddNumber("scrollAmount", 15), guiScroller ) )
		ElseIf sender = guiScroller.guiButtonPlus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "down").AddNumber("scrollAmount", 15), guiScroller ) )
		EndIf
	End Function


	'handle a mousedown on the up/down-buttons and inform others about changes
	Function onButtonDown:Int( triggerEvent:TEventBase )
		Local sender:TGUIArrowButton = TGUIArrowButton(triggerEvent.GetSender())
		If sender = Null Then Return False

		Local guiScroller:TGUIScroller = TGUIScroller( sender._parent )
		If guiScroller = Null Then Return False

		If MOUSEMANAGER.GetDownTime(1) > 0
			'if we still have to wait - return without emitting events
			If MOUSEMANAGER.GetDownTime(1) < guiScroller.mouseDownTime
				Return False
			EndIf
		EndIf


		'emit event that the scroller position has changed
		If sender = guiScroller.guiButtonMinus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "up"), guiScroller ) )
		ElseIf sender = guiScroller.guiButtonPlus
			EventManager.registerEvent( TEventSimple.Create( "guiobject.onScrollPositionChanged", new TData.AddString("direction", "down"), guiScroller ) )
		EndIf
	End Function


	Method Draw()
		SetColor 125,0,0
		SetAlpha 0.20

		Local width:Int = guiButtonMinus.GetScreenWidth()
		Local height:Int = guiButtonMinus.GetScreenHeight()
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				DrawRect(GetScreenX() + width/4, GetScreenY() + height/2, width/2, GetScreenHeight() - height)
			Default
				DrawRect(GetScreenX() + width/2, GetScreenY() + height/4, GetScreenWidth() - width, height/2)
		End Select

		SetAlpha 1.0
		SetColor 255,255,255
	End Method
End Type




Type TGUIListBase Extends TGUIobject
	Field guiBackground:TGUIobject				= Null
	Field backgroundColor:TColor				= TColor.Create(0,0,0,0)
	Field backgroundColorHovered:TColor			= TColor.Create(0,0,0,0)
	Field guiEntriesPanel:TGUIScrollablePanel	= Null
	Field guiScrollerH:TGUIScroller				= Null
	Field guiScrollerV:TGUIScroller				= Null

	Field autoScroll:Int						= False
	Field autoHideScroller:Int					= False 'hide if mouse not over parent
	Field scrollerUsed:Int						= False 'we need it to do a "one time" auto scroll
	Field entries:TList							= CreateList()
	Field entriesLimit:Int						= -1
	Field autoSortItems:Int						= True
	Field _multiColumn:int						= FALSE
	Field _mouseOverArea:Int					= False 'private mouseover-field (ignoring covering child elements)
	Field _dropOnTargetListenerLink:TLink		= Null
	Field _entryDisplacement:TPoint				= TPoint.Create(0,0,1)	'displace each entry by (z-value is stepping)...
	Field _entriesBlockDisplacement:TPoint		= TPoint.Create(0,0,0)	'displace the entriesblock by x,y...
	Field _orientation:Int						= 0		'0 means vertical, 1 is horizontal
	Field _scrollingEnabled:Int					= False
	Field _scrollToBeginWithoutScrollbars:Int	= True	'scroll to the very first element as soon as the scrollbars get hidden ?



    Method Create:TGUIListBase(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.CreateBase(x,y,State,Null)

		setZIndex(10)
		If width < 40 Then width = 40

		Resize( width, height )

		guiScrollerH = New TGUIScroller.Create(Self)
		guiScrollerV = New TGUIScroller.Create(Self)
		'orientation of horizontal scroller has to get set manually
		guiScrollerH.SetOrientation(GUI_OBJECT_ORIENTATION_HORIZONTAL)

		guiEntriesPanel = New TGUIScrollablePanel.Create(0,0, width - guiScrollerV.rect.getW(), height - guiScrollerH.rect.getH(),state)
		AddChild(guiEntriesPanel) 'manage by our own
		'RON: already set this on create (to 50,50)
		'guiEntriesPanel.minSize.SetXY(100,100)

		'by default all lists accept drop
		setOption(GUI_OBJECT_ACCEPTS_DROP, True)
		'by default all lists do not have scrollers
		setScrollerState(False, False)

		autoSortItems = True


		'register events
		'someone uses the mouse wheel to scroll over the panel
		EventManager.registerListenerFunction( "guiobject.OnScrollwheel",	onScrollWheel, Self)
		'- we are interested in certain events from the scroller or self
		EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged",	onScroll, guiScrollerH )
		EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged",	onScroll, guiScrollerV )
		EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged",	onScroll, self )


		'is something dropping - check if it this list
		SetAcceptDrop("TGUIListItem")

		GUIManager.Add(Self)
		Return Self
	End Method


	Method EmptyList:Int()
		For Local obj:TGUIobject = EachIn entries
			'call the objects cleanup-method
			obj.remove()
		Next
		'overwrite the list with a new one
		entries = CreateList()
	End Method


	Method SetEntryDisplacement(x:Float=0.0, y:Float=0.0, stepping:Int=1)
		_entryDisplacement.SetXYZ(x,y, Max(1,stepping))
	End Method


	Method SetEntriesBlockDisplacement(x:Float=0.0, y:Float=0.0)
		_entriesBlockDisplacement.SetXY(x,y)
	End Method


	Method SetOrientation(orientation:Int=0)
		_orientation = orientation
	End Method


	Method SetMultiColumn(bool:int=FALSE)
		if _multiColumn <> bool
			_multiColumn = bool
			'maybe now more or less elements fit into the visible
			'area, so elements position need to get recalculated
			RecalculateElements()
		endif
	End Method


	Method SetBackground(background:TGUIobject)
		'set old background to managed again
		If guiBackground Then GUIManager.add(guiBackground)
		'assign new background
		guiBackground = background
		If guiBackground
			guiBackground.setParent(Self)
			'set to unmanaged in all cases
			GUIManager.remove(guiBackground)
		EndIf
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float=Null,h:Float=Null)
		Super.Resize(w,h)

		'cache enabled state of both scrollers
		local showScrollerH:int = 0<(guiScrollerH and guiScrollerH.hasOption(GUI_OBJECT_ENABLED))
		local showScrollerV:int = 0<(guiScrollerV and guiScrollerV.hasOption(GUI_OBJECT_ENABLED))


		'resize panel - but use resulting dimensions, not given (maybe restrictions happening!)
		If guiEntriesPanel
			'also set minsize so scroll works
			guiEntriesPanel.minSize.SetXY(..
				rect.GetW() + _entriesBlockDisplacement.x - showScrollerV*guiScrollerV.GetScreenWidth(),..
				rect.GetH() + _entriesBlockDisplacement.y - showScrollerH*guiScrollerH.rect.getH()..
			)

			guiEntriesPanel.Resize(..
				rect.getW() + _entriesBlockDisplacement.x - showScrollerV * guiScrollerV.rect.getW(),..
				rect.getH() + _entriesBlockDisplacement.y - showScrollerH * guiScrollerH.rect.getH()..
			)
		EndIf

		'move horizontal scroller --
		If showScrollerH and not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerH.rect.position.setXY(_entriesBlockDisplacement.x, rect.getH() + _entriesBlockDisplacement.y - guiScrollerH.guiButtonMinus.rect.getH())
			if showScrollerV
				guiScrollerH.Resize(GetScreenWidth() - guiScrollerV.GetScreenWidth(), 0)
			else
				guiScrollerH.Resize(GetScreenWidth())
			endif
		EndIf
		'move vertical scroller |
		If showScrollerV and not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerV.rect.position.setXY( rect.getW() + _entriesBlockDisplacement.x - guiScrollerV.guiButtonMinus.rect.getW(), _entriesBlockDisplacement.y)
			if showScrollerH
				guiScrollerV.Resize(0, GetScreenHeight() - guiScrollerH.GetScreenHeight()-03)
			else
				guiScrollerV.Resize(0, GetScreenHeight())
			endif
		EndIf


		If guiBackground
			'move background by negative padding values ( -> ignore padding)
			guiBackground.rect.position.setXY(-padding.getLeft(), -padding.getTop())

			'background covers whole area, so resize it
			guiBackground.resize(rect.getW(), rect.getH())
		EndIf
	End Method


	Method SetAcceptDrop:Int(accept:Object)
		'if we registered already - remove the old one
		If _dropOnTargetListenerLink Then EventManager.unregisterListenerByLink(_dropOnTargetListenerLink)

		'is something dropping - check if it is this list
		EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropOnTarget, accept, Self)
	End Method


	Method SetItemLimit:Int(limit:Int)
		entriesLimit = limit
	End Method


	Method ReachedItemLimit:Int()
		If entriesLimit <= 0 Then Return False
		Return (entries.count() >= entriesLimit)
	End Method


	Method GetItemByCoord:TGUIobject(coord:TPoint)
		For Local entry:TGUIobject = EachIn entries
			'our entries are sorted and replaced, so we could
			'quit as soon as the
			'entry is out of range...
			If entry.GetScreenY() > GetScreenY()+GetScreenHeight() Then Return Null
			If entry.GetScreenX() > GetScreenX()+GetScreenWidth() Then Return Null

			If entry.GetScreenRect().containsXY(coord.GetX(), coord.GetY()) Then Return entry
		Next
		Return Null
	End Method


	'base handling of add item
	Method _AddItem:Int(item:TGUIobject, extra:Object=Null)
'		if self.ReachedItemLimit() then return FALSE

		'set parent of the item - so item is able to calculate position
		guiEntriesPanel.addChild(item )

		'recalculate dimensions as the item now knows its parent
		'so a normal AddItem-handler can work with calculated dimensions from now on
		Local dimension:TPoint = item.getDimension()

		'reset zindex
		item.setZIndex(rect.position.z)

		entries.addLast(item)

		'run the custom compare method
		If autoSortItems Then entries.sort()

		EventManager.triggerEvent(TEventSimple.Create("guiList.addItem", new TData.Add("item", item) , Self))

		Return True
	End Method


	'base handling of remove item
	Method _RemoveItem:Int(item:TGUIobject)
		If entries.Remove(item)
			'remove from panel and item gets managed by guimanager
			guiEntriesPanel.removeChild(item)

			EventManager.triggerEvent(TEventSimple.Create("guiList.removeItem", new TData.Add("item", item) , Self))

			Return True
		Else
			Print "not able to remove item "+item._id
			Return False
		EndIf
	End Method


	'overrideable AddItem-Handler
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		If _AddItem(item, extra)
			'recalculate positions, dimensions etc.
			RecalculateElements()

			Return True
		EndIf
		Return False
	End Method
	'overrideable RemoveItem-Handler
	Method RemoveItem:Int(item:TGUIobject)
		If _RemoveItem(item)
			RecalculateElements()

			Return True
		EndIf
		Return False
	End Method


	Method HasItem:Int(item:TGUIobject)
		For Local otheritem:TGUIobject = EachIn entries
			If otheritem = item Then Return True
		Next
		Return False
	End Method


	'recalculate scroll maximas, item positions...
	Method RecalculateElements:Int()
		local startPos:TPoint = _entriesBlockDisplacement.copy()
		Local dimension:TPoint = _entriesBlockDisplacement.copy()
		Local entryNumber:Int = 1
		Local nextPos:TPoint = startPos.copy()
		Local currentPos:TPoint
		local columnPadding:int = 5

		For Local entry:TGUIobject = EachIn entries
			currentPos = nextPos.copy()

			'==== CALCULATE POSITION ====
			Select _orientation
				'only from top to bottom
				Case GUI_OBJECT_ORIENTATION_VERTICAL
					'MultiColumn: from left to right, if space left a
					'             new column on the right is started.

					'advance the next position starter
					if _multiColumn
						'if entry does not fit, try the next line
						if currentPos.GetX() + entry.rect.GetW() > GetContentScreenWidth()
							currentPos.SetXY(startPos.GetX(), currentPos.GetY() + entry.rect.GetH())
							'new lines increase dimension of container
							dimension.MoveXY(0, entry.rect.GetH())
						endif

						nextPos = currentPos.copy()
						nextPos.MoveXY(entry.rect.GetW() + columnPadding, 0)
					else
						nextPos = currentPos.copy()
						nextPos.MoveXY(0, entry.rect.GetH())
						'new lines increase dimension of container
						dimension.MoveXY(0, entry.rect.GetH())
					endif

				Case GUI_OBJECT_ORIENTATION_HORIZONTAL
					'MultiColumn: from top to bottom, if space left a
					'             new line below is started.

					'advance the next position starter
					if _multiColumn
						'if entry does not fit, try the next row
						if currentPos.GetY() + entry.rect.GetH() > GetContentScreenHeight()
							currentPos.SetXY(currentPos.GetX() + entry.rect.GetW(), startPos.GetY())
							'new lines increase dimension of container
							dimension.MoveXY(entry.rect.GetW(), 0 )
						endif

						nextPos = currentPos.copy()
						nextPos.MoveXY(0, entry.rect.GetH() + columnPadding)
					else
						nextPos = currentPos.copy()
						nextPos.MoveXY(entry.rect.GetW(),0)
						'new lines increase dimension of container
						dimension.MoveXY(entry.rect.GetW(), 0 )
					endif
			End Select

			'==== ADD POTENTIAL DISPLACEMENT ====
			'add the displacement afterwards - so the first one is not displaced
			If entryNumber Mod _entryDisplacement.z = 0 And entry <> entries.last()
				currentPos.MoveXY(_entryDisplacement.x, _entryDisplacement.y)
				'increase dimension if positive displacement
				dimension.MoveXY( Max(0,_entryDisplacement.x), Max(0, _entryDisplacement.y))
			EndIf

			'==== SET POSITION ====
			entry.rect.position.SetPos(currentPos)

			entryNumber:+1
		Next

		'resize container panel
		guiEntriesPanel.resize(dimension.getX(), dimension.getY())

		Select _orientation
			'===== VERTICAL ALIGNMENT =====
			case GUI_OBJECT_ORIENTATION_VERTICAL
				'determine if we did not scroll the list to a middle position
				'so this is true if we are at the very bottom of the list aka "the end"
				Local atListBottom:Int = 1 > Floor(Abs(guiEntriesPanel.scrollLimit.GetY() - guiEntriesPanel.scrollPosition.getY()))

				'set scroll limits:
				If dimension.getY() < guiEntriesPanel.getScreenheight()
					'if there are only some elements, they might be "less high" than
					'the available area - no need to align them at the bottom
					guiEntriesPanel.SetLimits(0, -dimension.getY())
				Else
					'maximum is at the bottom of the area, not top - so subtract height
					guiEntriesPanel.SetLimits(0, -(dimension.getY() - guiEntriesPanel.getScreenheight()) )

					'in case of auto scrolling we should consider scrolling to
					'the next visible part
					If autoscroll And (Not scrollerUsed Or atListBottom) Then scrollToLastItem()
				EndIf
			'===== HORIZONTAL ALIGNMENT =====
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				'determine if we did not scroll the list to a middle position
				'so this is true if we are at the very bottom of the list aka "the end"
				Local atListBottom:Int = 1 > Floor( Abs(guiEntriesPanel.scrollLimit.GetX() - guiEntriesPanel.scrollPosition.getX() ) )

				'set scroll limits:
				If dimension.getX() < guiEntriesPanel.getScreenWidth()
					'if there are only some elements, they might be "less high" than
					'the available area - no need to align them at the bottom
					guiEntriesPanel.SetLimits(-dimension.getX(), 0 )
				Else
					'maximum is at the bottom of the area, not top - so subtract height
					guiEntriesPanel.SetLimits(-(dimension.getX() - guiEntriesPanel.getScreenWidth()), 0)

					'in case of auto scrolling we should consider scrolling to
					'the next visible part
					If autoscroll And (Not scrollerUsed Or atListBottom) Then scrollToLastItem()
				EndIf

		End Select

		'if not all entries fit on the panel, enable scroller
		SetScrollerState( dimension.getX() > guiEntriesPanel.GetScreenWidth(), ..
		                  dimension.getY() > guiEntriesPanel.GetScreenHeight() ..
						)
	End Method


	Method SetScrollerState:int(boolH:int, boolV:int)
		'set scrolling as enabled or disabled
		_scrollingEnabled = (boolH or boolV)

		local changed:int = FALSE
		if boolH <> guiScrollerH.hasOption(GUI_OBJECT_ENABLED) then changed = TRUE
		if boolV <> guiScrollerV.hasOption(GUI_OBJECT_ENABLED) then changed = TRUE

		'as soon as the scroller gets disabled, we scroll to the first
		'item.
		'ATTENTION: if you do not want this behaviour, set the variable below
		'           accordingly
		if changed and _scrollToBeginWithoutScrollbars
			if not _scrollingEnabled then ScrollToFirstItem()
		End If


		guiScrollerH.setOption(GUI_OBJECT_ENABLED, boolH)
		guiScrollerH.setOption(GUI_OBJECT_VISIBLE, boolH)
		guiScrollerV.setOption(GUI_OBJECT_ENABLED, boolV)
		guiScrollerV.setOption(GUI_OBJECT_VISIBLE, boolV)

		'resize everything
		Resize()

'print "SetScrollerState : h:"+boolH+" v:"+boolV
rem
		'if active, subtract guiScroller-width
		guiEntriesPanel.Resize(rect.getW() - (boolV>0) * guiScrollerV.rect.getW(),..
		                       rect.getH() - (boolH>0) * guiScrollerH.rect.getH()..
		                      )
endrem

	End Method


	'override default
	Method onDrop:Int(triggerEvent:TEventBase)
		'we could check for dragged element here

		triggerEvent.setAccepted(True)
		Return True
	End Method


	'default handler for the case of an item being dropped back to its
	'parent list
	'by default it does not handly anything, so returns FALSE
	Method HandleDropBack:Int(triggerEvent:TEventBase)
		Return False
	End Method


	Function onDropOnTarget:Int( triggerEvent:TEventBase )
		Local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		If item = Null Then Return False

		'ATTENTION:
		'Item is still in dragged state!
		'Keep this in mind when sorting the items

		'only handle if coming from another list ?
		Local parent:TGUIobject = item._parent
		If TGUIPanel(parent) Then parent = TGUIPanel(parent)._parent
		Local fromList:TGUIListBase = TGUIListBase(parent)
		'if not fromList then return FALSE

		Local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		If Not toList Then Return False

		Local data:TData = triggerEvent.getData()
		If Not data Then Return False

		If fromList = toList
			'if the handler took care of everything, we skip
			'removing and adding the item
			If fromList.HandleDropBack(triggerEvent) Then Return True
		EndIf

		'move item if possible
		If fromList Then fromList.removeItem(item)
		'try to add the item, if not able, readd
		If Not toList.addItem(item, data)
			If fromList And fromList.addItem(item) Then Return True

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
		EndIf


		Return True
	End Function


	'handle clicks on the up/down-buttons and inform others about changes
	Function onScrollWheel:Int( triggerEvent:TEventBase )
		Local list:TGUIListBase = TGUIListBase(triggerEvent.GetSender())
		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If Not list Or value=0 Then Return False

		'emit event that the scroller position has changed
		local direction:string = ""
		select list._orientation
			case GUI_OBJECT_ORIENTATION_VERTICAL
				If value < 0 then direction = "up"
				If value > 0 then direction = "down"
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				If value < 0 then direction = "left"
				If value > 0 then direction = "right"
		End Select
		if direction <> "" then	EventManager.registerEvent(TEventSimple.Create("guiobject.onScrollPositionChanged", new TData.AddString("direction", direction).AddNumber("scrollAmount", 25), list))

		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Function


	'handle events from the connected scroller
	Function onScroll:Int( triggerEvent:TEventBase )
		local guiSender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		if not guiSender then return False

		Local guiList:TGUIListBase = TGUIListBase(guiSender.GetParent("TGUIListBase"))
		If Not guiList Then Return False

		'do not allow scrolling if not enabled
		If Not guiList._scrollingEnabled Then Return False

		Local data:TData = triggerEvent.GetData()
		If Not data Then Return False

		'by default scroll by 2 pixels
		Local scrollAmount:Int = data.GetInt("scrollAmount", 2)

		'this should be "calculate height and change amount"
		If data.GetString("direction") = "up" Then guiList.ScrollEntries(0, +scrollAmount)
		If data.GetString("direction") = "down" Then guiList.ScrollEntries(0, -scrollAmount)
		If data.GetString("direction") = "left" Then guiList.ScrollEntries(+scrollAmount,0)
		If data.GetString("direction") = "right" Then guiList.ScrollEntries(-scrollAmount,0)
		'from now on the user decides if he wants the end of the chat or stay inbetween
		guiList.scrollerUsed = True
	End Function


	'positive values scroll to top or left
	Method ScrollEntries(dx:float, dy:float)
		guiEntriesPanel.scroll(dx,dy)
	End Method


	Method ScrollToFirstItem()
		ScrollEntries(0, 0 )
	End Method


	Method ScrollToLastItem()
		Select _orientation
			case GUI_OBJECT_ORIENTATION_VERTICAL
				ScrollEntries(0, guiEntriesPanel.scrollLimit.GetY() )
			case GUI_OBJECT_ORIENTATION_HORIZONTAL
				ScrollEntries(guiEntriesPanel.scrollLimit.GetX(), 0 )
		End Select
	End Method


	'override default update-method
	Method Update:Int()
		'first check if our children recognize that click
		UpdateChildren()

		Super.Update()

		_mouseOverArea = TFunctions.MouseIn(GetScreenX(), GetScreenY(), rect.GetW(), rect.GetH())

		If autoHideScroller
			If _mouseOverArea
				guiScrollerV.hide()
				guiScrollerH.hide()
			Else
				guiScrollerV.show()
				guiScrollerH.show()
			EndIf
		EndIf
	End Method


	Method Draw()
		If guiBackground
			guiBackground.Draw()
		Else
			Local rect:TRectangle = TRectangle.Create(guiEntriesPanel.GetScreenX(), guiEntriesPanel.GetScreenY(), Min(rect.GetW(), guiEntriesPanel.rect.GetW()), Min(rect.GetH(), guiEntriesPanel.rect.GetH()) )

			If _mouseOverArea
				backgroundColorHovered.setRGBA()
			Else
				backgroundColor.setRGBA()
			EndIf

			rect.Draw()

			SetAlpha 1.0
			SetColor 255,255,255
		EndIf

		DrawChildren()

		If _debugMode
			Local offset:Int = GetScreenY()
			For Local entry:TGUIListItem = EachIn entries
				'move entry's y position to current one
				SetAlpha 0.5
				DrawRect(	GetScreenX() + entry.rect.GetX() - 20,..
							GetScreenY() + entry.rect.GetY(),..
							entry.rect.GetW(),..
							entry.rect.GetH()-1..
						)
				SetAlpha 0.2
				SetColor 0,255,255
				DrawRect(0, offset+15, 40, 20 )
				SetAlpha 1.0
				DrawText(entry._id, 20, offset+15 )
				offset:+ entry.rect.GetH()


				SetAlpha 0.2
				SetColor 255,255,255
	'			SetColor 0,0,0
				SetAlpha 1.0
				DrawText(entry._id, GetScreenX()-20 + entry.rect.GetX(), GetScreenY() + entry.rect.GetY() )
				SetColor 255,255,255
			Next
		EndIf
	End Method
End Type




Type TGUISelectListItem Extends TGUIListItem
	Field selected:Int = False


    Method Create:TGUISelectListItem(text:String="",x:Float=0.0,y:Float=0.0,width:Int=120,height:Int=20)
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(x,y,"",Null)

		SetLabel(text, TColor.Create(0,0,0))
		Resize( width, height )

		GUIManager.add(Self)

		Return Self
	End Method


	Method Draw:Int()
		getParent("topitem").RestrictViewPort()

		'available width is parentsDimension minus startingpoint
		Local maxWidth:Int = TGUIobject(getParent("topitem")).getContentScreenWidth() - rect.getX()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		If mouseover
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), maxWidth, rect.getH())
			SetColor 255,255,255
		ElseIf selected
			SetAlpha GetAlpha()*0.5
			SetColor 250,210,100
			DrawRect(getScreenX(), getScreenY(), maxWidth, rect.getH())
			SetColor 255,255,255
			SetAlpha GetAlpha()*2.0
		EndIf

		'draw label
		'Assets.fonts.baseFontBold.drawStyled(text, self.getScreenX() + move.x, self.getScreenY() + move.y, textColor.r, textColor.g, textColor.b, 2, 1,0.5)

		useFont.draw(label, Int(GetScreenX() + 5), Int(GetScreenY() + 2 + 0.5*(rect.getH()- useFont.getHeight(Self.label))), labelColor)

		getParent("topitem").ResetViewPort()

	End Method
End Type




Type TGUISelectList Extends TGUIListBase
	Field selectedEntry:TGUIobject = Null


    Method Create:TGUISelectList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height, State)

		RegisterListeners()

		Return Self
	End Method


	'overrideable
	Method RegisterListeners:Int()
		'we want to know about clicks
		EventManager.registerListenerMethod( "guiobject.onClick",	Self, "onClickOnEntry", "TGUISelectListItem" )
	End Method


	Method onClickOnEntry:Int(triggerEvent:TEventBase)
		Local entry:TGUISelectListItem = TGUISelectListItem( triggerEvent.getSender() )
		If Not entry Then Return False

		'only mark selected if we are owner of that entry
		If Self.HasItem(entry)
			'remove old entry
			Self.deselectEntry()
			Self.selectedEntry = entry
			If TGUISelectListItem(Self.selectedEntry) Then TGUISelectListItem(Self.selectedEntry).selected = True

			'inform others: we successfully selected an item
			EventManager.triggerEvent( TEventSimple.Create( "GUISelectList.onSelectEntry", new TData.AddObject("entry", entry) , Self ) )
		EndIf
	End Method


	Method deselectEntry:Int()
		If TGUISelectListItem(selectedEntry)
			TGUISelectListItem(selectedEntry).selected = False
			selectedEntry = Null
		EndIf
	End Method


	Method getSelectedEntry:TGUIobject()
		Return selectedEntry
	End Method
End Type




Type TGUISlotList Extends TGUIListBase
	Field _slotMinDimension:TPoint	= TPoint.Create(0,0)
	Field _slotAmount:Int			= -1		'<=0 means dynamically, else it is fixed
	Field _slots:TGUIobject[0]
	Field _slotsState:Int[0]
	Field _autofillSlots:Int		= False
	Field _fixedSlotDimension:Int	= False

    Method Create:TGUISlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)

		autoSortItems = False
		Return Self
	End Method


	Method ClearSlotsState:Int()
		_slotsState = New Int[_slots.length]
	End Method


	Method GetSlotState:Int(slot:Int)
		If slot >= _slotsState.length Then Return -1
		Return _slotsState[slot]
	End Method


	Method SetSlotState:Int(slot:Int, state:Int)
		If slot >= _slotsState.length Then Return False
		_slotsState[slot] = state
		Return True
	End Method


	Method EmptyList:Int()
		Super.EmptyList()

		For Local i:Int = 0 To _slots.length-1
			'skip empty slots
			If _slots[i]=null then continue
			'call the objects cleanup-method
			_slots[i].remove()
			'unset
			_slots[i] = Null
			_slotsState[i] = 0
		Next
	End Method


	'returns how many slots that list has at all
	Method GetSlotAmount:Int()
		Return _slotAmount
	End Method


	'returns how many slots of that list are not occupied
	Method GetUnusedSlotAmount:Int()
		Local amount:Int = 0
		For Local i:Int = 0 To _slots.length-1
			If _slots[i] Then amount:+1
		Next
		Return amount
	End Method


	Method SetAutofillSlots(bool:Int=True)
		Self._autofillSlots = bool
	End Method


	'override
	Method HasItem:Int(item:TGUIobject)
		Return (getSlot(item) >= 0)
	End Method


	'override
	Method SetItemLimit:Int(limit:Int)
		Super.SetItemLimit(limit)
		_slotAmount = limit

		'maybe better "drag" items before if resizing to smaller slot amounts
		_slots = _slots[..limit]
		_slotsState = _slotsState[..limit]
	End Method


	Method SetSlotMinDimension:Int(width:Float=0.0, height:Float=0.0)
		_slotMinDimension.setXY(width, height)
	End Method


	'which slot is occupied by the given item?
	Method getSlot:Int(item:TGUIobject)
		For Local i:Int = 0 To _slots.length-1
			If _slots[i] = item Then Return i
		Next
		Return -1
	End Method


	'return the next free slot (for autofill)
	Method getFreeSlot:Int()
		For Local i:Int = 0 To _slots.length-1
			If _slots[i] Then Continue
			Return i
		Next
		Return -1
	End Method


	Method GetSlotOrCoord:TPoint(slot:Int=-1, coord:TPoint=Null)
		Local baseRect:TRectangle = Null
		If _fixedSlotDimension
			baseRect = TRectangle.Create(0, 0, _slotMinDimension.getX(), _slotMinDimension.getY())
		Else
			If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
				baseRect = TRectangle.Create(0, 0, rect.GetW(), _slotMinDimension.getY())
			ElseIf _orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
				baseRect = TRectangle.Create(0, 0, _slotMinDimension.getX(), rect.GetH())
			Else
				TDevHelper.log("TGUISlotList.GetSlotOrCoord", "unknown orientation : " + _orientation, LOG_ERROR)
			EndIf
		EndIf

		'set startpos at point of block displacement
		Local currentPos:TPoint = _entriesBlockDisplacement.copy()
		Local currentRect:TRectangle 'used to check if a given coord is within
		Local slotW:Int
		Local slotH:Int
		For Local i:Int = 0 To _slots.length-1
			'size the slot dimension accordingly
			slotW = _slotMinDimension.getX()
			slotH = _slotMinDimension.getY()
			'only use slots real dimension if occupied and not fixed
			If _slots[i] And Not _fixedSlotDimension
				slotW = Max(slotW, _slots[i].rect.getW())
				slotH = Max(slotH, _slots[i].rect.getH())
			EndIf

			'move base rect
			baseRect.position.setPos(currentPos)

			'if the current position + dimension contains the given
			'coord or is of this slot - return this position
			'1. GIVEN SLOT
			If slot >= 0 And i = slot Then Return currentPos
			'2. GIVEN COORD
			If coord
				If _slots[i] And Not _fixedSlotDimension
					currentRect = _slots[i].rect
				Else
					currentRect = baseRect
				EndIf
				If currentRect.containsXY(coord.getX(),coord.getY())
					'print "currentRect: "+currentRect.position.getIntX()+","+currentRect.position.getIntY()+" "+currentRect.dimension.getIntX()+","+currentRect.dimension.getIntY() + " minW:"+_slotMinDimension.getX()+" minH:"+_slotMinDimension.getY() +" slot:"+i
					currentPos.z = i
					Return currentPos
				EndIf
			EndIf


			'move to the next one
			If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
				currentPos.MoveXY(0, slotH )
			ElseIf _orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
				currentPos.MoveXY(slotW, 0)
			EndIf

			'add the displacement, z-value is stepping, not for LAST element
			If (i+1) Mod _entryDisplacement.z = 0 And i < _slots.length-1
				currentPos.MoveXY(_entryDisplacement.x, _entryDisplacement.y)
			EndIf
		Next
		'return the end of the list coordinate ?!
		Return currentPos
	End Method


	Method GetSlotCoord:TPoint(slot:Int)
		Return GetSlotOrCoord(slot, Null)
	End Method


	'get a slot by a (global/screen) coord
	Method GetSlotByCoord:Int(coord:TPoint, isScreenCoord:Int=True)
		'create a copy of the given coord - avoids modifying it
		Local useCoord:TPoint = coord.copy()

		'convert global/screen to local coords
		If isScreenCoord Then useCoord.MoveXY(-Self.GetScreenX(),-Self.GetScreenY())
		Return GetSlotOrCoord(-1, useCoord).z
	End Method


	Method GetItemByCoord:TGUIobject(coord:TPoint)
		Local slot:Int = Self.GetSlotByCoord(coord)
		Return Self.GetItemBySlot(slot)
	End Method


	'returns the slot of the previous occupied slot
	Method GetPreviousUsedSlot:Int(slot:Int)
		Local previousSlot:Int = slot-1
		If previousSlot < 0  Or previousSlot > Self._slots.length-1 Then Return -1
		While previousSlot >= 0
			If Self._slots[previousSlot] Then Return previousSlot
			previousSlot:-1
		Wend
		Return -1
	End Method


	'returns the slot of the next occupied slot
	Method GetNextUsedSlot:Int(slot:Int)
		Local nextSlot:Int = slot+1
		If nextSlot < 0  Or nextSlot > Self._slots.length-1 Then Return -1
		While nextSlot <= Self._slots.length-1
			If Self._slots[nextSlot] Then Return nextSlot
			nextSlot:+1
		Wend
		Return -1
	End Method


	Method GetItemBySlot:TGUIobject(slot:Int)
		If slot < 0 Or slot > Self._slots.length-1 Then Return Null

		Return Self._slots[slot]
	End Method


	'set the slots and emits events
	Method _SetSlot:Int(slot:Int, item:TGUIobject)
		If slot < 0 Or slot > Self._slots.length-1 Then Return False

		If item
			EventManager.triggerEvent(TEventSimple.Create("guiList.addItem", new TData.Add("item", item).AddNumber("slot",slot) , Self))
			Self._slots[slot] = item
		Else
			If Self._slots[slot]
				EventManager.triggerEvent(TEventSimple.Create("guiList.removeItem", new TData.Add("item", Self._slots[slot]).AddNumber("slot",slot) , Self))
				Self._slots[slot] = Null
			EndIf
		EndIf
		Return True
	End Method


	'may return a object which was on the place where the new item is to position
	Method SetItemToSlot:Int(item:TGUIobject,slot:Int)
		Local itemSlot:Int = Self.GetSlot(item)
		'somehow we try to place an item at the place where the item
		'already resides
		If itemSlot = slot Then Return True

		'is there another item?
		Local dragItem:TGUIobject = TGUIobject(Self.getItemBySlot(slot))

		If dragItem
			'do not allow if the underlying item cannot get dragged
			If Not dragItem.isDragable() Then Return False

			'ask others if they want to intercept that exchange
			Local event:TEventSimple = TEventSimple.Create( "guiSlotList.onBeginReplaceSlotItem", new TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot), Self)
			EventManager.triggerEvent(event)

			If Not event.isVeto()
				'remove the other one from the panel
				If dragItem._parent Then dragItem._parent.RemoveChild(dragItem)

				'drag the other one
				dragItem.drag()
				'unset the occupied slot
				Self._SetSlot(slot, Null)

				EventManager.triggerEvent(TEventSimple.Create( "guiSlotList.onReplaceSlotItem", new TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot) , Self))
			EndIf
		EndIf

		'if the item is already on the list, remove it from the former slot
		If itemSlot >= 0 Then Self._SetSlot(itemSlot, Null)

		'set the item to the new slot
		Self._SetSlot(slot, item)

		guiEntriesPanel.addChild(item)

		Self.RecalculateElements()

		Return True
	End Method


	'override default handler for the case of dropping something back to
	'its parent
	Method HandleDropBack:Int(triggerEvent:TEventBase)
		'as slotlists can easily compare "old slot" and "dropzone"-slot
		'we use this to check if the slot is changing..
		Local dropCoord:TPoint = TPoint(triggerEvent.GetData().get("coord"))
		Local item:TGUIobject = TGUIobject(triggerEvent.GetSender())
		'skip handling if important data is missing/incorrect
		If Not dropCoord Or Not item Then Return False

		'the drop-coordinate is the same one as the original slot, so we
		'handled that situation
		If dropCoord And GetSlotByCoord(dropCoord) = GetSlot(item)
			Return True
		EndIf

		Return False
	End Method



	'overrideable AddItem-Handler
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		Local addToSlot:Int = -1
		Local extraIsRawSlot:Int = False
		If String(extra)<>"" Then addToSlot= Int( String(extra) );extraIsRawSlot=True

		'search for first free slot
		If Self._autofillSlots Then addToSlot = Self.getFreeSlot()
		'auto slot requested
		If extraIsRawSlot And addToSlot = -1 Then addToSlot = Self.getFreeSlot()

		'no free slot or none given? find out on which slot we are dropping
		'if possible, drag the other one and drop the new
		If addToSlot < 0
			Local data:TData = TData(extra)
			If Not data Then Return False

			Local dropCoord:TPoint = TPoint(data.get("coord"))
			If Not dropCoord Then Return False

			'set slot to land
			addToSlot = Self.GetSlotByCoord(dropCoord)
			'no slot was hit
			If addToSlot < 0 Then Return False
		EndIf

		'ask if an add to this slot is ok
		Local event:TEventSimple =  TEventSimple.Create("guiList.TryAddItem", new TData.Add("item", item).AddNumber("slot",addtoSlot) , Self)
		EventManager.triggerEvent(event)
		If event.isVeto() Then Return False

		'return if there is an underlying item which cannot get dragged
		Local dragItem:TGUIobject = TGUIobject(Self.getItemBySlot(addToSlot))
		If dragItem And Not dragItem.isDragable() Then Return False

		Return Self.SetItemToSlot(item, addToSlot)
	End Method


	'overrideable RemoveItem-Handler
	Method RemoveItem:Int(item:TGUIobject)
		Local slot:Int = GetSlot(item)
		If slot >=0
			'ask if a removal from this slot is ok
			Local event:TEventSimple =  TEventSimple.Create("guiList.TryRemoveItem", new TData.Add("item", item).AddNumber("slot",slot) , Self)
			EventManager.triggerEvent(event)
			If event.isVeto() Then Return False

			'remove it
			Self._SetSlot(slot, Null)
			'remove from panel
			guiEntriesPanel.removeChild(item)

			Self.RecalculateElements()
			Return True
		EndIf
		Return False
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		If _debugMode
			'restrict by scrollable panel - if not possible, there is no "space left"
			If guiEntriesPanel.RestrictViewPort()
				Local pos:TPoint = Null
				SetAlpha 0.4
				For Local i:Int = 0 To Self._slots.length-1
					pos = GetSlotOrCoord(i)
					'print "slot "+i+": "+pos.GetX()+","+pos.GetY() +" result: "+(atPoint.GetX()+pos.getX())+","+(atPoint.GetY()+pos.getY()) +" h:"+self._slotMinDimension.getY()
					SetColor 0,0,0
					DrawRect(atPoint.GetX()+pos.getX(), atPoint.GetY()+pos.getY(), _slotMinDimension.getX(), _slotMinDimension.getY())
					SetColor 255,255,255
					DrawRect(atPoint.GetX()+pos.getX()+1, atPoint.GetY()+pos.getY()+1, _slotMinDimension.getX()-2, _slotMinDimension.getY()-2)
					SetColor 0,0,0
					DrawText("slot "+i+"|"+GetSlotByCoord(pos), atPoint.GetX()+pos.getX(), atPoint.GetY()+pos.getY())
					SetColor 255,255,255
				Next
				SetAlpha 1.0
				ResetViewPort()
			EndIf
		EndIf

		DrawChildren()
	End Method


	Method RecalculateElements:Int()
		'set startpos at point of block displacement
		Local currentPos:TPoint = _entriesBlockDisplacement.copy()
		Local coveredArea:TRectangle = TRectangle.Create(0,0,_entriesBlockDisplacement.x,_entriesBlockDisplacement.y)
		For Local i:Int = 0 To Self._slots.length-1
			Local slotW:Int = _slotMinDimension.getX()
			Local slotH:Int = _slotMinDimension.getY()
			'only use slots real dimension if occupied and not fixed
			If _slots[i] And Not _fixedSlotDimension
				slotW = Max(slotW, _slots[i].rect.getW())
				slotH = Max(slotH, _slots[i].rect.getH())
			EndIf

			'move entry's position to current one
			If _slots[i] Then _slots[i].rect.position.SetPos(currentPos)

			'resize covered area
			coveredArea.position.setXY( Min(coveredArea.position.x, currentPos.x), Min(coveredArea.position.y, currentPos.y) )
			coveredArea.dimension.setXY( Max(coveredArea.dimension.x, currentPos.x+slotW), Max(coveredArea.dimension.y, currentPos.y+slotH) )


			If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
				currentPos.MoveXY(0, slotH )
			ElseIf Self._orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
				currentPos.MoveXY(slotW, 0)
			EndIf

			'add the displacement, z-value is stepping, not for LAST element
			If (i+1) Mod Self._entryDisplacement.z = 0 And i < _slots.length-1
				currentPos.MoveXY(_entryDisplacement.x, _entryDisplacement.y)
			EndIf
		Next

		'resize container panel
		Local dimension:TPoint = TPoint.Create(coveredArea.getW() - coveredArea.getX(), coveredArea.getH() - coveredArea.getY())
		guiEntriesPanel.minSize.setXY(dimension.getX(), dimension.getY() )
		guiEntriesPanel.resize(dimension.getX(), dimension.getY() )

		If _orientation = GUI_OBJECT_ORIENTATION_VERTICAL
			'set scroll limits:
			'maximum is at the bottom of the area, not top - so subtract height
			guiEntriesPanel.SetLimits(0, -(dimension.getY() - guiEntriesPanel.rect.GetH()) )
		ElseIf _orientation = GUI_OBJECT_ORIENTATION_HORIZONTAL
			'set scroll limits:
			'maximum is at the bottom of the area, not top - so subtract height
			guiEntriesPanel.SetLimits(-(dimension.getX() - guiEntriesPanel.rect.GetW()), 0 )
		EndIf

		'if not all entries fit on the panel, enable scroller
		SetScrollerState(dimension.getX() > guiEntriesPanel.rect.GetW(), ..
		                 dimension.getY() > guiEntriesPanel.rect.GetH() ..
		                )
	End Method
End Type




Type TGUIListItem Extends TGUIobject
	Field lifetime:Float		= Null		'how long until auto remove? (current value)
	Field initialLifetime:Float	= Null		'how long until auto remove? (initial value)
	Field showtime:Float		= Null		'how long until hiding (current value)
	Field initialShowtime:Float	= Null		'how long until hiding (initial value)

	Field label:String = ""
	Field labelColor:TColor	= TColor.Create(0,0,0)

	Field positionNumber:Int = 0


    Method Create:TGUIListItem(label:String="",x:Float=0.0,y:Float=0.0,width:Int=120,height:Int=20)
		'limit this blocks to nothing - as soon as we parent it, it will
		'follow the parents limits
   		Super.CreateBase(x,y,"",Null)
		Self.Resize( width, height )
		Self.label = label

		'make dragable
		Self.setOption(GUI_OBJECT_DRAGABLE, True)

		GUIManager.add(Self)

		Return Self
	End Method


	Method Remove:Int()
		Super.Remove()

		'also remove itself from the list it may belong to
		Local parent:TGUIobject = Self._parent
		If TGUIPanel(parent) Then parent = TGUIPanel(parent)._parent
		If TGUIScrollablePanel(parent) Then parent = TGUIScrollablePanel(parent)._parent
		If TGUIListBase(parent) Then TGUIListBase(parent).RemoveItem(Self)
		Return True
	End Method


	'override default
	Method onClick:Int(triggerEvent:TEventBase)
		Local data:TData = triggerEvent.GetData()
		If Not data Then Return False

		'only react on clicks with left mouse button
		If data.getInt("button") <> 1 Then Return False

		'we handled the click
		triggerEvent.SetAccepted(True)

		If isDragged()
			drop(TPoint.Create(data.getInt("x",-1), data.getInt("y",-1)))
		Else
			drag(TPoint.Create(data.getInt("x",-1), data.getInt("y",-1)))
		EndIf
	End Method


	Method SetLabel:Int(label:String=Null, labelColor:TColor=Null)
		If label Then Self.label = label
		If labelColor Then Self.labelColor = labelColor
	End Method


	Method SetLifetime:Int(milliseconds:Int=Null)
		If milliseconds
			Self.initialLifetime = milliseconds
			Self.lifetime = MilliSecs() + milliseconds
		Else
			Self.initialLifetime = Null
			Self.lifetime = Null
		EndIf
	End Method


	Method Show:Int()
		Self.SetShowtime(Self.initialShowtime)
		Super.Show()
	End Method


	Method SetShowtime:Int(milliseconds:Int=Null)
		If milliseconds
			Self.InitialShowtime = milliseconds
			Self.showtime = MilliSecs() + milliseconds
		Else
			Self.InitialShowtime = Null
			Self.showtime = Null
		EndIf
	End Method

Rem
	Method drag:int(coord:TPoint=Null)
		if super.drag(coord)
			'add it to the gui manager to be "on top" of the rest
			'GUIManager.add(self)
			return TRUE
		endif
		return FALSE
	End Method
endrem

	'override default update-method
	Method Update:Int()
		Super.Update()

		'if the item has a lifetime it will autoremove on death
		If lifetime And (MilliSecs() > lifetime) Then Return Remove()

		If showtime And isVisible()
			If (MilliSecs() > showtime) Then hide()
		EndIf

		'as soon as dragged we want the GUIManager to handle the item
		'as we want to have it drawn above all
	'	if not isDragged() and (_flags & GUI_OBJECT_MANAGED) then GUIManager.Remove(self)
	End Method


	Method Draw()
		Local atPoint:TPoint = GetScreenPos()
		Local draw:Int=True
		Local parent:TGUIobject = Null
		If Not(Self._flags & GUI_OBJECT_DRAGGED)
			parent = Self._parent
			If TGUIPanel(parent) Then parent = TGUIPanel(parent)._parent

			If TGUIListBase(parent) Then draw = TGUIListBase(parent).RestrictViewPort()
		EndIf
		If draw
			'self.GetScreenX() and self.GetScreenY() include parents coordinate
			SetColor 0,0,0
			DrawRect(atPoint.GetX(), atPoint.GetY(), Self.rect.GetW(), Self.rect.GetH())
			If Self._flags & GUI_OBJECT_DRAGGED
				SetColor 125,0,125
			Else
				SetColor 125,125,125
			EndIf
			DrawRect(atPoint.GetX() + 1, atPoint.GetY() + 1, Self.rect.GetW()-2, Self.rect.GetH()-2)

			Self.useFont.draw(Self.label + " [" + Self._id + "]", atPoint.GetX() + 5, atPoint.GetY() + 2 + 0.5*(Self.rect.getH()-Self.useFont.getHeight(Self.label)), Self.labelColor)
		EndIf
		If Not(Self._flags & GUI_OBJECT_DRAGGED) And TGUIListBase(parent)
			TGUIListBase(parent).ResetViewPort()
		EndIf
	End Method
End Type




'simple gui object helper - so non-gui-objects may receive events...
Type TGUISimpleRect Extends TGUIobject
	Method Create:TGUISimpleRect(rect:TRectangle, limitState:String="")
		Super.CreateBase(rect.GetX(),rect.GetY(), limitState, Null)
		Self.Resize(rect.GetW(), rect.GetH() )

    	GUIManager.Add( Self )
		Return Self
	End Method


	Method Draw()
	Rem debug
		SetAlpha 0.5
		DrawRect(self.GetScreenX(), self.GetScreenY(), self.GetScreenWidth(), self.GetScreenHeight())
		SetAlpha 1.0
	endrem
	End Method
End Type