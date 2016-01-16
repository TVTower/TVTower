Rem
	===========================================================
	GUI Classes
	===========================================================

	TGuiManager - managing gui elements, handling update/render...
	TGUIObject - base class for gui objects to extend from
End Rem
SuperStrict
Import "base.gfx.sprite.bmx"
Import "base.gfx.bitmapfont.bmx"
Import "base.util.input.bmx"
Import "base.util.localization.bmx"
Import "base.util.registry.bmx"
Import "base.util.event.bmx"
Import "base.util.time.bmx"

Import "base.gfx.renderconfig.bmx"




'===== GUI CONSTANTS =====
Const GUI_OBJECT_DRAGGED:Int					= 2^0
Const GUI_OBJECT_VISIBLE:Int					= 2^1
Const GUI_OBJECT_ENABLED:Int					= 2^2
Const GUI_OBJECT_CLICKABLE:Int					= 2^3
Const GUI_OBJECT_DRAGABLE:Int					= 2^4
Const GUI_OBJECT_MANAGED:Int					= 2^5
Const GUI_OBJECT_POSITIONABSOLUTE:Int			= 2^6
Const GUI_OBJECT_IGNORE_POSITIONMODIFIERS:Int	= 2^7
Const GUI_OBJECT_IGNORE_PARENTPADDING:Int		= 2^8
Const GUI_OBJECT_IGNORE_PARENTLIMITS:Int		= 2^9
Const GUI_OBJECT_ACCEPTS_DROP:Int				= 2^10
Const GUI_OBJECT_CAN_RECEIVE_KEYSTROKES:Int		= 2^11
Const GUI_OBJECT_CAN_GAIN_FOCUS:Int				= 2^12
Const GUI_OBJECT_DRAWMODE_GHOST:Int				= 2^13
'defines what GetFont() tries to get at first: parents or types font
Const GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE:Int	= 2^14
'defines if changes to children change gui order (zindex on "panels")
Const GUI_OBJECT_CHILDREN_CHANGE_GUIORDER:Int	= 2^15

'===== GUI STATUS CONSTANTS =====
CONST GUI_OBJECT_STATUS_HOVERED:Int	= 2^0
CONST GUI_OBJECT_STATUS_SELECTED:Int = 2^1
CONST GUI_OBJECT_STATUS_APPEARANCE_CHANGED:Int	= 2^2

Const GUI_OBJECT_ORIENTATION_VERTICAL:Int   = 0
Const GUI_OBJECT_ORIENTATION_HORIZONTAL:Int = 1

'===== GUI MANAGER =====
'for each "List" of the guimanager
Const GUIMANAGER_TYPES_DRAGGED:int    = 2^0
Const GUIMANAGER_TYPES_NONDRAGGED:int = 2^1
Const GUIMANAGER_TYPES_ALL:int        = GUIMANAGER_TYPES_DRAGGED | GUIMANAGER_TYPES_NONDRAGGED


Type TGUIManager
	Field globalScale:Float	= 1.0
	'which state are we currently handling?
	Field currentState:String = ""
	'config about specific gui settings (eg. panelGap)
	Field config:TData = new TData
	Field List:TList = CreateList()
	'contains dragged objects (above normal)
	Field ListDragged:TList = CreateList()

	'=== UPDATE STATE PROPERTIES ===

	Field UpdateState_mouseButtonDown:Int[]
	Field UpdateState_mouseButtonHit:Int[]
	Field UpdateState_mouseScrollwheelMovement:Int = 0
	Field UpdateState_foundHitObject:Int = False
	Field UpdateState_foundHoverObject:Int = False
	Field UpdateState_foundFocusObject:Int = False

	'=== PRIVATE PROPERTIES ===

	Field _defaultfont:TBitmapFont
	Field _ignoreMouse:Int = False
	'is there an object listening to keystrokes?
	Field _keystrokeReceivingObject:TGUIObject = Null

	Global _instance:TGUIManager
	Global _eventListeners:TLink[]


	Method New()
		if not _instance then self.Init()
	End Method


	Function GetInstance:TGUIManager()
		if not _instance then _instance = new TGUIManager
		return _instance
	End Function


	Method Init:TGUIManager()
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]


		'is something dropping on a gui element?
		_eventListeners :+ [EventManager.registerListenerFunction("guiobject.onDrop", TGUIManager.onDrop)]

		'gui specific settings
		config.AddNumber("panelGap",10)

		Return self
	End Method


	Method SetDefaultFont:int(font:TBitmapFont)
		_defaultFont = font
	End Method


	Method GetDefaultFont:TBitmapFont()
		If Not _defaultFont then _defaultFont = GetBitmapFontManager().GetDefaultFont()
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
		obj._timeDragged = Time.GetTimeGone()

		If ListDragged.contains(obj) Then Return False

		ListDragged.addLast(obj)
		ListDragged.sort(False, SortObjects)

		Return True
	End Method


	Method RemoveDragged:Int(obj:TGUIObject)
		obj.setOption(GUI_OBJECT_DRAGGED, False)
		obj._timeDragged = 0
		ListDragged.Remove(obj)
		ListDragged.sort(False, SortObjects)

		Return True
	End Method


	Function onDrop:Int( triggerEvent:TEventBase )
		Local guiobject:TGUIObject = TGUIObject(triggerEvent.GetSender())
		If guiobject = Null Then Return False

		'find out if it hit a list...
		Local coord:TVec2D = TVec2D(triggerEvent.GetData().get("coord"))
		If Not coord Then Return False
		Local potentialDropTargets:TGuiObject[] = GUIManager.GetObjectsByPos(coord, GUIManager.currentState, True, GUI_OBJECT_ACCEPTS_DROP)
		Local dropTarget:TGuiObject = TGUIObject(triggerEvent.GetReceiver())
		Local source:TGuiObject = guiobject._parent


		if not triggerEvent.isAccepted()
			For Local potentialDropTarget:TGUIobject = EachIn potentialDropTargets
				'do not ask other targets if there was already one handling that drop
				If triggerEvent.isAccepted() Then Continue
				'do not ask other targets if one object already aborted the event
				If triggerEvent.isVeto() Then Continue

				'inform about drag and ask object if it wants to handle the drop
				potentialDropTarget.onDrop(triggerEvent)

				If triggerEvent.isAccepted()
					dropTarget = potentialDropTarget
					'modify event to hold dropTarget now
					triggerEvent.GetData().Add("dropTarget", dropTarget)
				endif
			Next
		endif

		'if we haven't found a dropTarget and nobody already cares for it
		'stop processing that event
		If Not dropTarget and not triggerEvent.isAccepted()
			triggerEvent.setVeto()
			Return False
		EndIf

		'we found an object accepting the drop

		'ask if something does not want that drop to happen
		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDropOnTarget", new TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			event = TEventSimple.Create("guiobject.onDropOnTarget", new TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget)
			EventManager.triggerEvent( event )
		EndIf

		'if there is a veto happening (dropTarget does not want the item)
		'also veto the onDropOnTarget-event
		If event.isVeto()
			triggerEvent.setVeto()
			EventManager.triggerEvent( TEventSimple.Create("guiobject.onDropOnTargetDeclined", new TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget ))
			Return False
		Else
			'inform others: we successfully dropped the object to a target#
			EventManager.triggerEvent( TEventSimple.Create("guiobject.onDropOnTargetAccepted", new TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget ))

			'also add this drop target as receiver of the original-drop-event
			triggerEvent._receiver = dropTarget
			Return True
		EndIf
	End Function


	Method RestrictViewport(x:Int,y:Int,w:Int,h:Int)
		TRenderConfig.Push()
		GetGraphicsManager().SetViewport(x,y,w,h)
	End Method


	Method ResetViewport()
		TRenderConfig.Pop()
	End Method


	Method Add:Int(obj:TGUIobject, skipCheck:Int=False)
		obj.setOption(GUI_OBJECT_MANAGED, True)

		If Not skipCheck And list.contains(obj) Then Return True

		List.AddLast(obj)
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

		'if objA is "higher", move it to the top
		If objA.GetZIndex() > objB.GetZIndex() Then Return 1
		'if objA is "lower"", move to bottom
		If objA.GetZIndex() < objB.GetZIndex() Then Return -1

		'run custom compare job
'		return objA.compare(objB)
		Return 0
	End Function


	Method SortLists()
		List.sort(True, SortObjects)
	End Method

rem
	Method DeleteObject(obj:TGUIObject var)
		if not obj then return 
		obj.remove()
		Remove(obj)
		obj = null
	End Method
endrem

	'only remove from lists (object cleanup has to get called separately)
	Method Remove:Int(obj:TGUIObject)
		if not obj then return False
		
		obj.setOption(GUI_OBJECT_MANAGED, False)

		List.remove(obj)

		RemoveDragged(obj)

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
		If Not ( (toZ = -1000 Or obj.GetZIndex() <= toZ) And (fromZ = -1000 Or obj.GetZIndex() >= fromZ)) Then Return False

		'limit display by state - skip if object is hidden in that state
		'deep check only if a specific state is wanted AND the object is limited to states
		If(state<>"" And obj.GetLimitToState() <> "")
			Return IsState(obj, state)
		EndIf
		Return True
	End Method


	'returns an array of objects at the given point
	Method GetObjectsByPos:TGuiObject[](coord:TVec2D, limitState:String=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
		If limitState=Null Then limitState = currentState

		Local guiObjects:TGuiObject[]
		'from TOP to BOTTOM (user clicks to visible things - which are at the top)
		local listReversed:TList = list.Reversed()
		For Local obj:TGUIobject = EachIn listReversed
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


	Method GetFirstObjectByPos:TGuiObject(coord:TVec2D, limitState:String=Null, ignoreDragged:Int=True, requiredFlags:Int=0)
		Local guiObjects:TGuiObject[] = GetObjectsByPos(coord, limitState, ignoreDragged, requiredFlags, 1)

		If guiObjects.length = 0 Then Return Null Else Return guiObjects[0]
	End Method


	Method DisplaceGUIobjects(State:String = "", x:Int = 0, y:Int = 0)
		For Local obj:TGUIobject = EachIn List
			If isState(obj, State) Then obj.rect.position.AddXY( x,y )
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
		'in all cases: set the foundFocus for this cycle
		if obj then UpdateState_foundFocusObject = true

		'skip setting focus if already focused
		if TGUIObject.GetFocusedObject() = obj then return False

		TGUIObject.SetFocusedObject(obj)

		'try to set as potential keystroke receiver
		SetKeystrokeReceiver(obj)

		return True
	End Method


	Method ResetFocus:Int()
		'remove focus (eg. when switching gamestates
		TGuiObject.SetFocusedObject(Null)

		'also remove potential keystroke receivers
		SetKeystrokeReceiver(Null)
	End Method


	'should be run on start of the current tick
	Method StartUpdates:Int()

		UpdateState_mouseScrollwheelMovement = MOUSEMANAGER.GetScrollwheelmovement()

		UpdateState_mouseButtonDown = MOUSEMANAGER.GetAllStatusDown()
		UpdateState_mouseButtonHit = MOUSEMANAGER.GetAllStatusHit() 'single and double clicks!

		UpdateState_foundFocusObject = False
		UpdateState_foundHitObject = False
		UpdateState_foundHoverObject = False
	End Method


	'run after all other gui things so important values can get reset
	Method EndUpdates:Int()
		'if we had a click this cycle and an gui element is focused,
		'remove focus from it
		if MouseManager.isClicked(1)
			if not UpdateState_foundFocusObject and GUIManager.GetFocus()
				GUIManager.ResetFocus()
				'GUIManager.setFocus(Null)
			endif
		endif

		'ignoreMouse can be useful for objects which know, that nothing
		'else should take care of mouse movement/clicks
		_ignoreMouse = False
	End Method


	Method Update(State:String = "", fromZ:Int=-1000, toZ:Int=-1000, updateTypes:int=GUIMANAGER_TYPES_ALL)
		'_lastUpdateTick :+1
		'if _lastUpdateTick >= 100000 then _lastUpdateTick = 0

		currentState = State

		'store a list of special elements - maybe the list gets changed
		'during update... some elements will get added/destroyed...
		Local ListDraggedBackup:TList = ListDragged.Copy()

		'first update all dragged objects...
		if GUIMANAGER_TYPES_DRAGGED & updateTypes
			For Local obj:TGUIobject = EachIn ListDraggedBackup
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'avoid getting updated multiple times
				'this can be overcome with a manual "obj.Update()"-call
				'if obj._lastUpdateTick = _lastUpdateTick then continue
				'obj._lastUpdateTick = _lastUpdateTick

				obj.Update()
				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onUpdate", Null, obj ) )
			Next
		endif

		'then the rest
		if GUIMANAGER_TYPES_NONDRAGGED & updateTypes
			'from top to bottom
			'traverse through a backup to avoid concurrent modification
			local listBackupReversed:TList = List.Reversed()
			For Local obj:TGUIobject = EachIn listBackupReversed
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
		endif
	End Method


	Method Draw:Int(State:String = "", fromZ:Int=-1000, toZ:Int=-1000, drawTypes:int=GUIMANAGER_TYPES_ALL)
		'_lastDrawTick :+1
		'if _lastDrawTick >= 100000 then _lastDrawTick = 0

		currentState = State

		if GUIMANAGER_TYPES_NONDRAGGED & drawTypes
			For Local obj:TGUIobject = EachIn List
				'all special objects get drawn separately
				If ListDragged.contains(obj) Then Continue
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'skip invisible objects
				if not obj.IsVisible() then continue

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
		endif


		if GUIMANAGER_TYPES_DRAGGED & drawTypes
			'draw all dragged objects above normal objects...
			local listReversed:TList = ListDragged.Reversed()
			For Local obj:TGUIobject = EachIn listReversed
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'avoid getting drawn multiple times
				'this can be overcome with a manual "obj.Draw()"-call
				'if obj._lastDrawTick = _lastDrawTick then continue
				'obj._lastDrawTick = _lastDrawTick

				obj.Draw()

				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
			Next
		endif
	End Method
End Type
Global GUIManager:TGUIManager = TGUIManager.GetInstance()




Type TGUIobject
	Field rect:TRectangle = new TRectangle.Init(-1,-1,-1,-1)
	Field zIndex:int = 0
	Field positionBackup:TVec2D = Null
	'storage for additional data
	Field data:TData = new TData
	Field scale:Float = 1.0
	Field alpha:Float = 1.0
	'where to attach the object
	Field handlePosition:TVec2D	= new TVec2D.Init(0, 0)
	'where to attach the content within the object
	Field contentPosition:TVec2D = new TVec2D.Init(0.5, 0.5)
	Field state:String = ""
	Field value:String = ""
	Field mouseIsClicked:TVec2D	= Null			'null = not clicked
	Field mouseIsDown:TVec2D = new TVec2D.Init(-1,-1)
	Field children:TList = Null
	Field _id:Int
	Field _padding:TRectangle = null 'by default no padding
	Field _flags:Int = 0
	'status of the widget: eg. GUI_OBJECT_STATUS_APPEARANCE_CHANGED
	Field _status:int = 0
	'the font used to display text in the widget
	Field _font:TBitmapFont
	'the font used in the last display call
	Field _lastFont:TBitmapFont
	'time when item got dragged, maybe find a better name
	Field _timeDragged:Int = 0
	Field _parent:TGUIobject = Null
	'fuer welchen gamestate anzeigen
	Field _limitToState:String = ""
	'an array containing registered event listeners
	Field _registeredEventListener:TLink[]
	'displacement of object when dragged (null = centered)
	Field handle:TVec2D	= Null
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
		className = TTypeId.ForObject(Self).Name()

		'default options
		setOption(GUI_OBJECT_VISIBLE, True)
		setOption(GUI_OBJECT_ENABLED, True)
		setOption(GUI_OBJECT_CLICKABLE, True)
		setOption(GUI_OBJECT_CAN_GAIN_FOCUS, True)
		setOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER, True)
	End Method


	Method CreateBase:TGUIobject(pos:TVec2D, dimension:TVec2D, limitState:String="")
		'create missing params
		If Not pos Then pos = new TVec2D.Init(0,0)
		If Not dimension Then dimension = new TVec2D.Init(-1,-1)

		rect.position.setXY(pos.x, pos.y)
		'resize widget, dimension of (-1,-1) is "auto dimension"
		Resize(dimension.x, dimension.y)

		_limitToState = limitState
	End Method


	Function SetTypeFont:Int(font:TBitmapFont)
		'implement in classes
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		return Null
	End Function


	Method SetFont:Int(font:TBitmapFont)
		self._font = font
	End Method


	Method GetFont:TBitmapFont()
		local newFont:TBitmapFont
		if not _font
			if hasOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE)
				if _parent
					newFont = _parent.GetFont()
				elseif GetTypeFont()
					newFont = GetTypeFont()
				else
					newFont = GUIManager.GetDefaultFont()
				endif
			else
				if GetTypeFont()
					newFont = GetTypeFont()
				elseif _parent
					newFont = _parent.GetFont()
				else
					newFont = GUIManager.GetDefaultFont()
				endif
			endif
		else
			newFont = _font
		endif

		'font differs - inform gui object
		if newfont <> _lastFont
			_lastFont = newFont
			if not isAppearanceChanged() then SetAppearanceChanged(true)
		endif

		return newFont
	End Method


	Method SetManaged(bool:Int)
		If bool
			If Not _flags & GUI_OBJECT_MANAGED Then GUIManager.add(Self)
		Else
			If _flags & GUI_OBJECT_MANAGED Then GUIManager.remove(Self)
		EndIf
	End Method


	'cleanup function, makes it ready for getting set to null
	Method Remove:Int()
		'unlink all potential event listeners concerning that object
		EventManager.unregisterListenerByLimit(self,self)

		EventManager.unregisterListenersByLinks(_registeredEventListener)
		_registeredEventListener = new TLink[0]

		'maybe our parent takes care of us...
'		If _parent Then _parent.DeleteChild(Self)
		If _parent Then _parent.RemoveChild(Self)

		'remove children (so they might inform their children and so on)
		If children
			'traverse along a copy to avoid concurrent modification
			For local child:TGUIObject = eachin children.Copy()
				child.Remove()
			Next
			children.Clear()
		EndIf
		
		'just in case we have a managed one
		GUIManager.remove(Self)

		Return True
	End Method


	Method AddEventListener:int(listenerLink:TLink)
		_registeredEventListener :+ [listenerLink]
	End Method


	Method GetClassName:String()
		Return TTypeId.ForObject(Self).Name()
'		return self.className
	End Method


	Method HasParent:int(parent:TGUIObject)
		if not _parent then return False
		if _parent = parent then return True
		return _parent.HasParent(parent)
	End Method


	'convencience function to return the uppermost parent
	Method GetUppermostParent:TGUIObject()
		'also possible:
		'getParent("someunlikelyname")
		if _parent then return _parent.GetUppermostParent()
		return self
	End Method


	'returns the requested parent
	'if parentclassname is NOT found and <> "" you get the uppermost
	'parent returned
	Method GetParent:TGUIobject(parentClassName:String="", strictMode:Int=False)
		'if no special parent is requested, just return the direct parent or self
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


	Method onFinishDrag:Int(triggerEvent:TEventBase)
		return True
	End Method


	Method onFinishDrop:Int(triggerEvent:TEventBase)
		return True
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


	'default click handler for all gui objects
	'by default they do nothing
	'click: no wait: mouse button was down and is now up again
	Method onClick:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default hit handler for all gui objects
	Method onHit:Int(triggerEvent:TEventBase)
		Return False
	End Method


	Method AddChild:Int(child:TGUIobject)
		'remove child from a prior parent to avoid multiple references
		If child._parent Then child._parent.RemoveChild(child)

		child.setParent( Self )
		If Not children Then children = CreateList()

		If children.addLast(child)
			'remove from guimanager, we take care of it
			GUIManager.Remove(child)
			children.sort(True, TGUIManager.SortObjects)

			'maybe zindex changed now
			if hasOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER)
				GuiManager.SortLists()
			endif
		endif

		'inform object
		child.onAddAsChild(self)
	End Method


	'just deletes child from children list
	Method DeleteChild:Int(child:TGUIobject)
		If Not children Then Return False
		children.Remove(child)

		'inform object
		child.onRemoveAsChild(self)
	End Method
	

	'removes child and adds it back to the guimanager
	Method RemoveChild:Int(child:TGUIobject)
		'remove from children list
		If Not children Then Return False
		children.Remove(child)

		'add back to guimanager
		'RON: this should be needed but bugs out "news dnd handling"
		'GuiManager.Add(child)

		'inform object
		child.onRemoveAsChild(self)
	End Method


	Method UpdateChildren:Int()
		If Not children Then Return False
		'traverse through a backup to avoid concurrent modification
		local childrenReversedBackup:TList = children.Reversed()
		'update added elements
		For Local obj:TGUIobject = EachIn childrenReversedBackup
			'avoid getting updated multiple times
			'this can be overcome with a manual "obj.Update()"-call
			'if obj._lastUpdateTick = GUIManager._lastUpdateTick then continue
			'obj._lastUpdateTick = GUIManager._lastUpdateTick

			obj.update()
		Next
	End Method


	Method onAddAsChild:int(parent:TGUIObject)
		'stub
	End Method


	Method onRemoveAsChild:int(parent:TGUIObject)
		'stub
	End Method
		

	Method RestrictContentViewport:Int()
		GUIManager.RestrictViewport(..
			GetContentScreenX(), ..
			GetContentScreenY(), ..
			GetContentScreenWidth(), ..
			GetContentScreenHeight() ..
		)
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
		If (obj <> _focusedObject) And _focusedObject
			'sender = previous focused object
			'receiver = newly focused object
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onRemoveFocus", null , _focusedObject, obj))
			_focusedObject.removeFocus()
		endif

		'inform about a new object getting focused
		'sender = newly focused object
		'receiver = previous focused object
		if obj then EventManager.triggerEvent(TEventSimple.Create("guiobject.onSetFocus", null , obj, _focusedObject))

		'set new focused object
		_focusedObject = obj
		'if there is a focused object now - inform about gain of focus
		If _focusedObject then _focusedObject.setFocus()
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


	Method SetValue(value:string)
		self.value = value
	End Method


	Method hasOption:Int(option:Int)
		Return (_flags & option) <> 0
	End Method


	Method setOption(option:Int, enable:Int=True)
		If enable
			_flags :| option
		Else
			_flags :& ~option
		EndIf
	End Method


	Method HasStatus:Int(statusCode:Int)
		Return (_status & statusCode) <> 0
	End Method


	Method SetStatus(statusCode:Int, enable:Int=True)
		If enable
			_status :| statusCode
		Else
			_status :& ~statusCode
		EndIf
	End Method


	Method IsHovered:Int()
		Return (_status & GUI_OBJECT_STATUS_HOVERED) <> 0
	End Method


	Method SetHovered:Int(bool:int)
		SetStatus(GUI_OBJECT_STATUS_HOVERED, bool)
	End Method


	Method IsSelected:Int()
		Return (_status & GUI_OBJECT_STATUS_SELECTED) <> 0
	End Method


	Method SetSelected:Int(bool:int)
		'skip if already done
		if IsSelected() = bool then return True

		if bool
			onSelect()
		else
			onDeselect()
		endif
		SetStatus(GUI_OBJECT_STATUS_SELECTED, bool)

		return True
	End Method


	Method IsAppearanceChanged:Int()
		Return (_status & GUI_OBJECT_STATUS_APPEARANCE_CHANGED) <> 0
	End Method


	Method SetAppearanceChanged:Int(bool:int)
		SetStatus(GUI_OBJECT_STATUS_APPEARANCE_CHANGED, bool)

		If bool = true
			'inform parent (and its grandparent and...)
			If _parent and not _parent.IsAppearanceChanged()
				_parent.SetAppearanceChanged(bool)
			Endif
			'inform children
			If children
				For local child:TGUIobject = EachIn children
					if child.IsAppearanceChanged() then continue
					child.SetAppearanceChanged(bool)
				Next
			Endif
		endif
	End Method


	'called when appearance changes - override in widgets to react
	'to it
	'do not call this directly, this is handled at the end of
	'each "update" call so multiple things can set "appearanceChanged"
	'but this function is called only "once"
	Method onStatusAppearanceChange:int()
		'
	End Method


	Method onSelect:Int()
		EventManager.triggerEvent( TEventSimple.Create( "GUIObject.onSelect", null, Self ) )
	End Method


	Method onDeselect:Int()
		EventManager.triggerEvent( TEventSimple.Create( "GUIObject.onDeselect", null, Self ) )
	End Method


	Method isDragable:Int()
		Return (_flags & GUI_OBJECT_DRAGABLE) <> 0
	End Method


	Method isDragged:Int()
		Return (_flags & GUI_OBJECT_DRAGGED) <> 0
	End Method


	Method IsClickable:int()
		return (_flags & GUI_OBJECT_CLICKABLE) <> 0
	End Method


	Method IsVisible:Int()
		'i am invisible if my parent is not visible
'		if _parent and not _parent.IsVisible() then return FALSE
		Return (_flags & GUI_OBJECT_VISIBLE) <> 0
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


	Method IsEnabled:int()
		return (_flags & GUI_OBJECT_ENABLED) <> 0
	End Method
	

	Method Resize(w:Float = 0, h:Float = 0)
		If w > 0 Then rect.dimension.setX(w)
		If h > 0 Then rect.dimension.setY(h)
	End Method


	'set the anchor of the gui object
	'valid values are 0-1.0 (percentage)
	Method SetHandlePosition:Int(handleLeft:Float=0.0, handleTop:Float=0.0)
		handlePosition = new TVec2D.init(handleLeft, handleTop)
	End Method


	'set the anchor of the gui objects content
	'valid values are 0-1.0 (percentage)
	Method SetContentPosition:Int(contentLeft:Float=0.0, contentTop:Float=0.0)
		contentPosition = new TVec2D.Init(contentLeft, contentTop)
	End Method


	Method GetZIndex:int()
		if zIndex = 0
			'each children is at least 1 zindex higher
			if _parent then return _parent.GetZIndex() + 1
		'-1 means: try to get the zindex from parent
		elseif zIndex = -1
			if _parent then return _parent.GetZIndex()
		endif
		return zIndex
	End Method


	Method SetZIndex(zindex:Int)
		self.zIndex = zindex
		GUIManager.SortLists()
	End Method


	Method SetState(state:String="", forceSet:Int=False)
		If state <> "" Then state = "."+state
		If Self.state <> state Or forceSet
			'do other things (eg. events)
			Self.state = state
		EndIf
	End Method


	Method GetState:string()
		if state <> "" then return Mid(state, 1)
		return ""
	End Method


	Method SetPadding:Int(top:Int,Left:Int,bottom:Int,Right:Int)
		if not _padding
			_padding = new TRectangle.Init(top, left, bottom, right)
		else
			_padding.setTLBR(top,Left,bottom,Right)
		endif
		resize()
	End Method


	Method GetPadding:TRectangle()
		if not _padding then _padding = new TRectangle.Init(0,0,0,0)
		Return _padding
	End Method


	Method drag:Int(coord:TVec2D=Null)
		If Not isDragable() Or isDragged() Then Return False

		positionBackup = new TVec2D.Init( GetScreenX(), GetScreenY() )


		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDrag", new TData.Add("coord", coord), self)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			'trigger an event immediately - if the event has a veto afterwards, do not drag!
			Local event:TEventSimple = TEventSimple.Create( "guiobject.onDrag", new TData.Add("coord", coord), Self )
			EventManager.triggerEvent( event )
			If event.isVeto() Then Return False

			'nobody said "no" to drag, so drag it
			GuiManager.AddDragged(Self)
			GUIManager.SortLists()

			'inform others - item finished dragging
			local ev:TEventSimple = TEventSimple.Create("guiobject.onFinishDrag", new TData.Add("coord", coord), Self)
			EventManager.triggerEvent(ev)
			self.onFinishDrag(ev)

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


	Method drop:Int(coord:TVec2D=Null, force:Int=False)
		If Not isDragged() Then Return False

		If coord And coord.getX()=-1 Then coord = new TVec2D.Init(MouseManager.x, MouseManager.y)


		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDrop", new TData.Add("coord", coord), self)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			'fire an event - if the event has a veto afterwards, do not drop!
			'exception is, if the action is forced
			Local event:TEventSimple = TEventSimple.Create("guiobject.onDrop", new TData.Add("coord", coord), Self)
			EventManager.triggerEvent( event )

			If Not force And event.isVeto()
				'inform others - item failed dropping, GetReceiver might
				'contain the item it should have been dropped to
				EventManager.triggerEvent(TEventSimple.Create("guiobject.onDropFailed", new TData.Add("coord", coord), Self, event.GetReceiver()))
				Return False
			Endif

			'nobody said "no" to drop, so drop it
			GUIManager.RemoveDragged(Self)
			GUIManager.SortLists()

			'inform others - item finished dropping - Receiver of "event" may now be helding the guiobject dropped on
			local ev:TEventSimple = TEventSimple.Create("guiobject.onFinishDrop", new TData.Add("coord", coord), Self, event.GetReceiver())
			EventManager.triggerEvent(ev)
			self.onFinishDrop(ev)

			Return True
		else
			Return FALSE
		endif
	End Method


	Method setParent:Int(parent:TGUIobject)
		_parent = parent
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


	'takes parent alpha into consideration
	Method GetScreenAlpha:Float()
		if _parent then return alpha * _parent.GetScreenAlpha()
		return alpha
	End Method


	Method GetScreenHeight:Float()
		Return rect.GetH()
	End Method


	Method GetScreenPos:TVec2D()
		Return new TVec2D.Init(GetScreenX(), GetScreenY())
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
		Return GetScreenX() + GetPadding().getLeft()
	End Method
	'at which y-coordinate has content/children to be drawn
	Method GetContentScreenY:Float()
		Return GetScreenY() + GetPadding().getTop()
	End Method
	'available width for content/children
	Method GetContentScreenWidth:Float()
		Return GetScreenWidth() - (GetPadding().getLeft() + GetPadding().getRight())
	End Method
	'available height for content/children
	Method GetContentScreenHeight:Float()
		Return GetScreenHeight() - (GetPadding().getTop() + GetPadding().getBottom())
	End Method


	Method SetHandle:Int(handle:TVec2D)
		Self.handle = handle
	End Method


	Method GetHandle:TVec2D()
		Return handle
	End Method


	Method GetRect:TRectangle()
		Return rect
	End Method


	Method getDimension:TVec2D()
		Return rect.dimension
	End Method


	Method GetContentScreenRect:TRectangle()
		return new TRectangle.Init(..
			GetContentScreenX(), ..
			GetContentScreenY(), ..
			GetContentScreenWidth(), ..
			GetContentScreenHeight()..
		)
	End Method


	'get a rectangle describing the objects area on the screen
	Method GetScreenRect:TRectangle()
		'dragged items ignore parents but take care of mouse position...
		If isDragged() Then Return new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )

		'if the item ignores parental limits, just return its very own screen rect
		If HasOption(GUI_OBJECT_IGNORE_PARENTLIMITS)
			Return new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
		endif

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
			Local sourceRect:TRectangle = new TRectangle.Init( ..
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
		Return new TRectangle.Init(0,0,-1,-1)
	End Method


	Method Draw()
		DrawBackground()
		DrawContent()
		DrawChildren()
		DrawOverlay()
	End Method


	'has to get implemented in each widget
	Method DrawContent() abstract


	Method DrawBackground()
		'
	End Method


	Method DrawOverlay()
		'
	End Method


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

		'skip children if self not visible
		if not IsVisible() then return false

		'draw children
		For Local obj:TGUIobject = EachIn children
			'before skipping a dragged one, we try to ask it as a ghost (at old position)
			If obj.isDragged() Then obj.drawGhost()
			'skip dragged ones - as we set them to managed by GUIManager for that time
			If obj.isDragged() Then Continue

			'skip invisible objects
			if not obj.IsVisible() then continue

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
		'to recognize clicks/hovers/actions on child elements:
		'ask them first!
		UpdateChildren()
	
		'if appearance changed since last update tick: inform widget
		If isAppearanceChanged()
			onStatusAppearanceChange()
			SetAppearanceChanged(false)
		Endif


		If GUIManager._ignoreMouse then return FALSE


		'mouse position could have changed since a begin of a "click"
		'-> eg when clicking + moving the cursor very fast
		'   in that case the mouse position should be the one of the
		'   moment the "click" begun
		local mousePos:TVec2D = new TVec2D.Init(MouseManager.x, MouseManager.y)
		If MouseManager.IsClicked(1) or MouseManager.GetClicks(1) > 0
			mousePos = MouseManager.GetClickPosition(1)
		Endif


		'=== HANDLE MOUSE ===
		if not GUIManager.UpdateState_mouseButtonDown[1]
			mouseIsDown	= Null
			'remove hover/active state
			setState("")
		endif
		'=== HANDLE MOUSE OVER ===

		'if nothing of the obj is visible or the mouse is not in
		'the visible part - reset the mouse states
		If Not containsXY(mousePos.x, mousePos.y)
			'avoid fast mouse movement to get interpreted incorrect
			'-> only "unhover" undragged elements
			if not isDragged()
				'reset clicked position as soon as leaving the widget
				mouseIsClicked = Null
				SetHovered(false)
				setState("")
			endif
			'mouseclick somewhere - should deactivate active object
			'no need to use the cached mouseButtonDown[] as we want the
			'general information about a click
'			If MOUSEMANAGER.isHit(1) And hasFocus() Then GUIManager.setFocus(Null)
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
		'skip objects the mouse is not over (except it is already dragged).
		'ATTENTION: this differs to self.isHovered() (which is set later on)
		if not containsXY(mousePos.x, mousePos.y) and not isDragged() then return FALSE


		'handle mouse clicks / button releases / hover state
		'only do something if
		'a) there is NO dragged object
		'b) we handle the dragged object
		'-> only react to dragged obj or all if none is dragged
		If Not GUIManager.GetDraggedCount() Or isDragged()

			If IsClickable()
				'activate objects - or skip if if one gets active
				If GUIManager.UpdateState_mouseButtonDown[1] And _flags & GUI_OBJECT_ENABLED
					'create a new "event"
					If Not MouseIsDown
						'as soon as someone clicks on a object it is getting focused
						if HasOption(GUI_OBJECT_CAN_GAIN_FOCUS)
							GUImanager.setFocus(Self)
						endif

						MouseIsDown = mousePos.Copy()
					EndIf

					'we found a gui element which can accept clicks
					'dont check further guiobjects for mousedown
					'ATTENTION: do not use MouseManager.ResetKey(1)
					'as this also removes "down" state
					GUIManager.UpdateState_mouseButtonDown[1] = False
					GUIManager.UpdateState_mouseButtonHit[1] = False
					'MOUSEMANAGER.ResetKey(1)
				EndIf
			EndIf

			If Not GUIManager.UpdateState_foundHoverObject And _flags & GUI_OBJECT_ENABLED

				'do not create "hovered" for dragged objects
				If Not isDragged()
					'create event: onmouseenter
					If not isHovered()
						EventManager.triggerEvent( TEventSimple.Create( "guiobject.OnMouseEnter", null, Self ) )
						SetHovered(true)
					EndIf
					GUIManager.UpdateState_foundHoverObject = True
				EndIf
				'create event: onmouseover
				EventManager.triggerEvent( TEventSimple.Create("guiobject.OnMouseOver", null, Self ) )

				'somone decided to say the button is pressed above the object
				If MouseIsDown
					setState("active")
					EventManager.triggerEvent( TEventSimple.Create("guiobject.OnMouseDown", new TData.AddNumber("button", 1), Self ) )
				Else
					setState("hover")
				EndIf


				If IsClickable()
					'inform others about a right guiobject click
					'we do use a "cached hit state" so we can reset it if
					'we found a one handling it
					If GUIManager.UpdateState_mouseButtonHit[2]
						Local clickEvent:TEventSimple = TEventSimple.Create("guiobject.OnClick", new TData.AddNumber("button",2).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
						OnClick(clickEvent)
						'fire onClickEvent
						EventManager.triggerEvent(clickEvent)

						'maybe change to "isAccepted" - but then each gui object
						'have to modify the event IF they accepted the click

						'reset Button
						GUIManager.UpdateState_mouseButtonHit[2] = False
					EndIf


					'IsClicked does not include waiting time - so check for
					'single and double clicks too
					If _flags & GUI_OBJECT_ENABLED and not GUIManager.UpdateState_foundHitObject
						local isHit:int = False
						If MouseManager.IsHit(1)
							local hitEvent:TEvenTsimple = TEventSimple.Create("guiobject.OnHit", new TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
							'let the object handle the click
							OnHit(hitEvent)
							'fire onClickEvent
							EventManager.triggerEvent(hitEvent)

							isHit = True
						endif
						
						If MOUSEMANAGER.IsClicked(1) or MOUSEMANAGER.GetClicks(1) > 0
							'=== SET CLICKED VAR ====
							mouseIsClicked = MouseManager.GetClickposition(1)

							'=== SEND OUT CLICK EVENT ====
							'if recognized as "double click" no normal "onClick"
							'is emitted. Same for "single clicks".
							'this avoids sending "onClick" and after 100ms
							'again "onSingleClick" AND "onClick"
							Local clickEvent:TEventSimple
							If MOUSEMANAGER.IsDoubleClicked(1)
								clickEvent = TEventSimple.Create("guiobject.OnDoubleClick", new TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
								'let the object handle the click
								OnDoubleClick(clickEvent)
							ElseIf MOUSEMANAGER.IsSingleClicked(1)
								clickEvent = TEventSimple.Create("guiobject.OnSingleClick", new TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
								'let the object handle the click
								OnSingleClick(clickEvent)
							'only "hit" if done the first time
							Else 'if not GUIManager.UpdateState_foundHitObject
								clickEvent = TEventSimple.Create("guiobject.OnClick", new TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
								'let the object handle the click
								OnClick(clickEvent)
							EndIf
							'fire onClickEvent
							EventManager.triggerEvent(clickEvent)

							'added for imagebutton and arrowbutton not being reset when mouse standing still
	'						MouseIsDown = Null
							'reset mouse button
							'-> do not reset it as it would disable
							'   "doubleclick" recognition
							'MOUSEMANAGER.ResetKey(1)
							'but we can reset clicked state
							MOUSEMANAGER.ResetClicked(1)

							isHit = True
						EndIf

						If isHit
							'reset Button cache
							GUIManager.UpdateState_mouseButtonHit[1] = False

							'clicking on an object sets focus to it
							'so remove from old before
							'Ronny: 2014/05/11 - commented out, still needed?
							'If Not HasFocus() Then GUIManager.ResetFocus()

							GUIManager.UpdateState_foundHitObject = True
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	End Method


	Method DrawBaseFormText:Object(_value:String, x:Float, y:Float)
		Local col:TColor = TColor.Create(100,100,100)
		If isHovered() Then col = TColor.Create(50,50,50)
		If Not(_flags & GUI_OBJECT_ENABLED) Then col = TColor.Create(150,150,150)

		Return GetFont().drawStyled(_value,x,y, col, 1, 1, 0.5)
	End Method


	'returns true if the conversion was successful
	Function ConvertKeystrokesToText:Int(value:String Var, skipEnterKey:int = False)
		'remove with backspace
		If KEYWRAPPER.pressedKey(KEY_BACKSPACE)
			value = value[..value.length -1]
			return TRUE
		Endif
		'abort with ESCAPE
		If KEYWRAPPER.pressedKey(KEY_ESCAPE) then Return False

		'read special keys (shift + altgr) to enable special key handling
		Local shiftPressed:Int = KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161)
		?not Linux
		'windows and mac
		Local altGrPressed:int = KEYMANAGER.IsDown(164) Or KEYMANAGER.IsDown(165)
		?Linux
		'linux
		Local altGrPressed:int = KEYMANAGER.IsDown(3)
		?

		'charCode is "0" if no key is recognized
		local charCode:int = int(GetChar())

		'loop through all chars of the getchar-queue
		While charCode <>0
			'charCode is < 0 for me when umlauts are pressed
			if charCode < 0
				?Win32
				If KEYWRAPPER.pressedKey(186) Then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
				If KEYWRAPPER.pressedKey(192) Then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
				If KEYWRAPPER.pressedKey(222) Then If shiftPressed Then value:+ "Ä" Else value :+ "ä"
				?Mac
				If KEYWRAPPER.pressedKey(186) Then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
				If KEYWRAPPER.pressedKey(192) Then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
				If KEYWRAPPER.pressedKey(222) Then If shiftPressed Then value:+ "Ä" Else value :+ "ä"
				?Linux
				If KEYWRAPPER.pressedKey(252) Then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
				If KEYWRAPPER.pressedKey(246) Then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
				If KEYWRAPPER.pressedKey(163) Then If shiftPressed Then value:+ "Ä" Else value :+ "ä"
				?
			'handle normal "keys" (excluding umlauts)
			elseif charCode > 0
				local addChar:int = True
				'skip "backspace"
				if chr(KEY_BACKSPACE) = chr(charCode) then addChar = False
				'skip enter if whished so
				if skipEnterKey and chr(KEY_ENTER) = chr(charCode) then addChar = False

				if addChar then value :+ chr(charCode)
			endif
			charCode = int(GetChar())
		Wend

		'special chars - recognized on Mac, but not Linux
		'euro sign
		?Linux
		If KEYWRAPPER.pressedKey(69) And altGrPressed Then value :+ chr(8364)
		?
		Return True
	End Function
End Type




'simple gui object helper - so non-gui-objects may receive events...
Type TGUISimpleRect Extends TGUIobject
	Method Create:TGUISimpleRect(position:TVec2D, dimension:TVec2D, limitState:String="")
		Super.CreateBase(position, dimension, limitState)
		Self.Resize(dimension.GetX(), dimension.GetY() )

    	GUIManager.Add( Self )
		Return Self
	End Method


	Method DrawContent()
		'
	End Method


	Method DrawDebug()
		SetAlpha 0.5
		DrawRect(self.GetScreenX(), self.GetScreenY(), self.GetScreenWidth(), self.GetScreenHeight())
		SetAlpha 1.0
	End Method
End Type