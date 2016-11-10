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
'defines whether children are updated automatically or not
Const GUI_OBJECT_STATIC_CHILDREN:Int            = 2^16

'===== GUI STATUS CONSTANTS =====
Const GUI_OBJECT_STATUS_HOVERED:Int	= 2^0
Const GUI_OBJECT_STATUS_SELECTED:Int = 2^1
Const GUI_OBJECT_STATUS_APPEARANCE_CHANGED:Int	= 2^2

Const GUI_OBJECT_ORIENTATION_VERTICAL:Int   = 0
Const GUI_OBJECT_ORIENTATION_HORIZONTAL:Int = 1

'===== GUI MANAGER =====
'for each "List" of the guimanager
Const GUIMANAGER_TYPES_DRAGGED:Int    = 2^0
Const GUIMANAGER_TYPES_NONDRAGGED:Int = 2^1
Const GUIMANAGER_TYPES_ALL:Int        = GUIMANAGER_TYPES_DRAGGED | GUIMANAGER_TYPES_NONDRAGGED


Type TGUIManager
	Field globalScale:Float	= 1.0
	'which state are we currently handling?
	Field currentState:TLowerString = Null
	'config about specific gui settings (eg. panelGap)
	Field config:TData = New TData
	Field List:TList = CreateList()
	'contains dragged objects (above normal)
	Field ListDragged:TList = CreateList()

	'=== UPDATE STATE PROPERTIES ===

	Field UpdateState_mouseButtonDown:Int[]
	Field UpdateState_mouseButtonHit:Int[]
	Field UpdateState_mouseScrollwheelMovement:Int = 0
	Field UpdateState_foundHitObject:TGUIObject[]
	Field UpdateState_foundHoverObject:TGUIObject = Null
	Field UpdateState_foundFocusObject:TGUIObject = Null

	'=== PRIVATE PROPERTIES ===

	Field _defaultfont:TBitmapFont
	Field _ignoreMouse:Int = False
	'is there an object listening to keystrokes?
	Field _keystrokeReceivingObject:TGUIObject = Null

	Global _instance:TGUIManager
	Global _eventListeners:TLink[]


	Method New()
		If Not _instance Then Self.Init()
	End Method


	Function GetInstance:TGUIManager()
		If Not _instance Then _instance = New TGUIManager
		Return _instance
	End Function


	Method Init:TGUIManager()
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = New TLink[0]


		'is something dropping on a gui element?
		_eventListeners :+ [EventManager.registerListenerFunction("guiobject.onDrop", TGUIManager.onDrop)]

		'gui specific settings
		config.AddNumber("panelGap",10)


		UpdateState_mouseButtonDown = New Int[ MouseManager.GetButtonCount() ]
		UpdateState_mouseButtonHit = New Int[ MouseManager.GetButtonCount() ]
		UpdateState_foundHitObject = New TGUIObject[ MouseManager.GetButtonCount() ]

		Return Self
	End Method


	Method SetDefaultFont:Int(font:TBitmapFont)
		_defaultFont = font
	End Method


	Method GetDefaultFont:TBitmapFont()
		If Not _defaultFont Then _defaultFont = GetBitmapFontManager().GetDefaultFont()
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
		'removing should not need a sort-call as the rest is still
		'sorted
		'ListDragged.sort(False, SortObjects)

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


		If Not triggerEvent.isAccepted()
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
				EndIf
			Next
		EndIf

		'if we haven't found a dropTarget and nobody already cares for it
		'stop processing that event
		If Not dropTarget And Not triggerEvent.isAccepted()
			triggerEvent.setVeto()
			Return False
		EndIf

		'we found an object accepting the drop

		'ask if something does not want that drop to happen
		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDropOnTarget", New TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			event = TEventSimple.Create("guiobject.onDropOnTarget", New TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget)
			EventManager.triggerEvent( event )
		EndIf

		'if there is a veto happening (dropTarget does not want the item)
		'also veto the onDropOnTarget-event
		If event.isVeto()
			triggerEvent.setVeto()
			EventManager.triggerEvent( TEventSimple.Create("guiobject.onDropOnTargetDeclined", New TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget ))
			Return False
		Else
			'inform others: we successfully dropped the object to a target#
			EventManager.triggerEvent( TEventSimple.Create("guiobject.onDropOnTargetAccepted", New TData.Add("coord", coord).Add("source", source) , guiobject, dropTarget ))

			'also add this drop target as receiver of the original-drop-event
			triggerEvent._receiver = dropTarget
			Return True
		EndIf
	End Function


	Method RestrictViewport(x:Int,y:Int,w:Int,h:Int)
		TRenderConfig.Push()
		if w > 0 and h > 0
			GetGraphicsManager().SetViewport(x,y,w,h)
		endif
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

		'if one is the parent of the other, sort so, that the parent
		'comes last (child on top of parent -> handled before parent)
		If objA.HasParent(objB) Then Return 1
		If objB.HasParent(objA) Then Return -1

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

Rem
	Method DeleteObject(obj:TGUIObject var)
		if not obj then return 
		obj.remove()
		Remove(obj)
		obj = null
	End Method
endrem

	'only remove from lists (object cleanup has to get called separately)
	Method Remove:Int(obj:TGUIObject)
		If Not obj Then Return False
		
		obj.setOption(GUI_OBJECT_MANAGED, False)

		List.remove(obj)

		RemoveDragged(obj)

		Return True
	End Method


	Method IsState:Int(obj:TGUIObject, State:TLowerString)
		If Not State Then Return True
		Return State.HasSplitFieldInSplitText("|", obj.GetLimitToState(), "|")
	End Method


	'returns whether an object is hidden/invisible/inactive and therefor
	'does not have to get handled now
	Method haveToHandleObject:Int(obj:TGUIObject, State:TLowerString=Null, fromZ:Int=-1000, toZ:Int=-1000)
		'skip if parent has not to get handled
		If(obj._parent And Not haveToHandleObject(obj._parent,State,fromZ,toZ)) Then Return False

		'skip if not visible
		If Not(obj._flags & GUI_OBJECT_VISIBLE) Then Return False

		'skip if not visible by zindex
		If Not ( (toZ = -1000 Or obj.GetZIndex() <= toZ) And (fromZ = -1000 Or obj.GetZIndex() >= fromZ)) Then Return False

		'limit display by state - skip if object is hidden in that state
		'deep check only if a specific state is wanted AND the object is limited to states
		If(state<>Null And obj.GetLimitToState() <> "")
			Return IsState(obj, state)
		EndIf
		Return True
	End Method


	'returns an array of objects at the given point
	Method GetObjectsByPos:TGuiObject[](coord:TVec2D, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
		If limitState=Null Then limitState = currentState

		Local guiObjects:TGuiObject[]
		'from TOP to BOTTOM (user clicks to visible things - which are at the top)
		'Local listReversed:TList = list.Reversed()
		Local listReversed:TGUIObject[] = TGUIObject[](list.ToArray())
		local i:int = listReversed.Length
		while i
			i :- 1
			Local obj:TGUIobject = listReversed[i]
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
		Wend

		Return guiObjects
	End Method


	Method GetFirstObjectByPos:TGuiObject(coord:TVec2D, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0)
		Local guiObjects:TGuiObject[] = GetObjectsByPos(coord, limitState, ignoreDragged, requiredFlags, 1)

		If guiObjects.length = 0 Then Return Null Else Return guiObjects[0]
	End Method


	Method DisplaceGUIobjects(State:TLowerString = null, x:Int = 0, y:Int = 0)
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
		If obj Then UpdateState_foundFocusObject = obj

		'skip setting focus if already focused
		If TGUIObject.GetFocusedObject() = obj Then Return False

		TGUIObject.SetFocusedObject(obj)

		'try to set as potential keystroke receiver
		SetKeystrokeReceiver(obj)

		Return True
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

		UpdateState_foundFocusObject = Null
		UpdateState_foundHitObject = New TGUIObject[3] '[null,null,null]
		UpdateState_foundHoverObject = Null
	End Method


	'run after all other gui things so important values can get reset
	Method EndUpdates:Int()
		'if we had a click this cycle and an gui element is focused,
		'remove focus from it
		If MouseManager.isClicked(1)
			If Not UpdateState_foundFocusObject And GUIManager.GetFocus()
				GUIManager.ResetFocus()
				'GUIManager.setFocus(Null)
			EndIf
		EndIf

		'ignoreMouse can be useful for objects which know, that nothing
		'else should take care of mouse movement/clicks
		_ignoreMouse = False
	End Method


	Method Update(State:TLowerString = Null, fromZ:Int=-1000, toZ:Int=-1000, updateTypes:Int=GUIMANAGER_TYPES_ALL)
		'_lastUpdateTick :+1
		'if _lastUpdateTick >= 100000 then _lastUpdateTick = 0

		currentState = State

		'store a list of special elements - maybe the list gets changed
		'during update... some elements will get added/destroyed...
		'Local ListDraggedBackup:TList = ListDragged.Copy()
		Local ListDraggedBackup:TGUIObject[] = TGUIObject[](ListDragged.ToArray())

		'first update all dragged objects...
		If GUIMANAGER_TYPES_DRAGGED & updateTypes
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
		EndIf

		'then the rest
		If GUIMANAGER_TYPES_NONDRAGGED & updateTypes
			'from top to bottom
			'traverse through a backup to avoid concurrent modification
			'Local listBackupReversed:TList = List.Reversed()
			Local listBackupReversed:TGUIObject[] = TGUIObject[](List.ToArray())
			Local i:Int = listBackupReversed.Length
			'For Local obj:TGUIobject = EachIn listBackupReversed
			While i
				i :- 1
				Local obj:TGUIObject = listBackupReversed[i]
				'all dragged objects got already updated...
				Local found:int
				for Local n:Int = 0 until ListDraggedBackup.Length
					if obj = ListDraggedBackup[n] Then
						found = True
						Exit
					End if
				Next
				if found then Continue
				'If ListDraggedBackup.contains(obj) Then Continue

				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue
				'avoid getting updated multiple times
				'this can be overcome with a manual "obj.Update()"-call
				'if obj._lastUpdateTick = _lastUpdateTick then continue
				'obj._lastUpdateTick = _lastUpdateTick
				obj.Update()
				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onUpdate", Null, obj ) )
			Wend
		EndIf
	End Method


	Method Draw:Int(State:TLowerString = Null, fromZ:Int=-1000, toZ:Int=-1000, drawTypes:Int=GUIMANAGER_TYPES_ALL)
		'_lastDrawTick :+1
		'if _lastDrawTick >= 100000 then _lastDrawTick = 0

		currentState = State

		If GUIMANAGER_TYPES_NONDRAGGED & drawTypes
			For Local obj:TGUIobject = EachIn List
				'all special objects get drawn separately
				If ListDragged.contains(obj) Then Continue
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'skip invisible objects
				If Not obj.IsVisible() Then Continue

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
		EndIf


		If GUIMANAGER_TYPES_DRAGGED & drawTypes
			'draw all dragged objects above normal objects...
			'Local listReversed:TList = ListDragged.Reversed()
			Local listReversed:TGUIObject[] = TGUIObject[](ListDragged.ToArray())
			Local i:Int = listReversed.Length
			While i
			'For Local obj:TGUIobject = EachIn listReversed
				i :- 1
				Local obj:TGUIobject = listReversed[i]
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'avoid getting drawn multiple times
				'this can be overcome with a manual "obj.Draw()"-call
				'if obj._lastDrawTick = _lastDrawTick then continue
				'obj._lastDrawTick = _lastDrawTick

				obj.Draw()

				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
			Wend
		EndIf
	End Method
End Type
Global GUIManager:TGUIManager = TGUIManager.GetInstance()




Type TGUIobject
	Field rect:TRectangle = New TRectangle.Init(-1,-1,-1,-1)
	Field zIndex:Int = 0
	Field positionBackup:TVec2D = Null
	'storage for additional data
	Field data:TData = New TData
	Field scale:Float = 1.0
	Field alpha:Float = 1.0
	'where to attach the object [unused]
	Field handlePosition:TVec2D	= New TVec2D.Init(0, 0)
	'where to attach the content within the object
	Field contentPosition:TVec2D = New TVec2D.Init(0.5, 0.5)
	Field state:String = ""
	Field value:String = ""
	Field mouseIsClicked:TVec2D	= Null			'null = not clicked
	Field mouseIsDown:TVec2D = New TVec2D.Init(-1,-1)
	Field screenRect:TRectangle
	Field _children:TList = Null
	Field _childrenReversed:TList = Null
	Field _id:Int
	Field _padding:TRectangle = Null 'by default no padding
	Field _flags:Int = 0
	'status of the widget: eg. GUI_OBJECT_STATUS_APPEARANCE_CHANGED
	Field _status:Int = 0
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

	'=== HOOKS ===
	'allow custom functions to get hooked in
	Field _customDraw:Int(obj:TGUIObject)
	Field _customDrawBackground:Int(obj:TGUIObject)
	Field _customDrawContent:Int(obj:TGUIObject)
	Field _customDrawChildren:Int(obj:TGUIObject)
	Field _customDrawOverlay:Int(obj:TGUIObject)


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
		If Not pos Then pos = New TVec2D.Init(0,0)
		If Not dimension Then dimension = New TVec2D.Init(-1,-1)

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
		Return Null
	End Function


	Method SetFont:Int(font:TBitmapFont)
		Self._font = font
	End Method


	Method GetFont:TBitmapFont()
		Local newFont:TBitmapFont
		If Not _font
			If hasOption(GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE)
				If _parent
					newFont = _parent.GetFont()
				ElseIf GetTypeFont()
					newFont = GetTypeFont()
				Else
					newFont = GUIManager.GetDefaultFont()
				EndIf
			Else
				If GetTypeFont()
					newFont = GetTypeFont()
				ElseIf _parent
					newFont = _parent.GetFont()
				Else
					newFont = GUIManager.GetDefaultFont()
				EndIf
			EndIf
		Else
			newFont = _font
		EndIf

		'font differs - inform gui object
		If newfont <> _lastFont
			_lastFont = newFont
			If Not isAppearanceChanged() Then SetAppearanceChanged(True)
		EndIf

		Return newFont
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
		EventManager.unregisterListenerByLimit(Self,Self)

		EventManager.unregisterListenersByLinks(_registeredEventListener)
		_registeredEventListener = New TLink[0]

		'maybe our parent takes care of us...
'		If _parent Then _parent.DeleteChild(Self)
		If _parent Then _parent.RemoveChild(Self)

		'remove children (so they might inform their children and so on)
		If _children
			'traverse along a copy to avoid concurrent modification
			Local childrenCopy:TGUIObject[] = TGUIObject[](_children.ToArray())
			For Local child:TGUIObject = EachIn childrenCopy
				child.Remove()
			Next
			_children.Clear()
			_childrenReversed.Clear()
		EndIf
		
		'just in case we have a managed one
		GUIManager.remove(Self)

		Return True
	End Method


	Method AddEventListener:Int(listenerLink:TLink)
		_registeredEventListener :+ [listenerLink]
	End Method


	Method GetClassName:String()
		Return TTypeId.ForObject(Self).Name()
'		return self.className
	End Method


	Method HasParent:Int(parent:TGUIObject)
		If Not _parent Then Return False
		If _parent = parent Then Return True
		Return _parent.HasParent(parent)
	End Method


	'convencience function to return the uppermost parent
	Method GetUppermostParent:TGUIObject()
		'also possible:
		'getParent("someunlikelyname")
		If _parent Then Return _parent.GetUppermostParent()
		Return Self
	End Method


	'returns the requested parent
	'if parentclassname is NOT found and <> "" you get the uppermost
	'parent returned
	Method GetParent:TGUIobject(parentClassName:String="", strictMode:Int=False)
		'if no special parent is requested, just return the direct parent or self
		If parentClassName=""
			If _parent Then Return _parent
			Return Self
		EndIf

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
		Return True
	End Method


	Method onFinishDrop:Int(triggerEvent:TEventBase)
		Return True
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


	'default mouseover handler for all gui objects
	'by default they do nothing
	Method onMouseOver:Int(triggerEvent:TEventBase)
		Return False
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
		If Not _children Then _children = CreateList()
		If Not _childrenReversed Then _childrenReversed = CreateList()

		If _children.addLast(child)
			_childrenReversed.addFirst(child)

			'remove from guimanager, we take care of it
			GUIManager.Remove(child)
			_children.sort(True, TGUIManager.SortObjects)
			_childrenReversed.sort(False, TGUIManager.SortObjects)

			'maybe zindex changed now
			If hasOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER)
				GuiManager.SortLists()
			EndIf
		EndIf

		'inform object
		child.onAddAsChild(Self)
	End Method


	'just deletes child from children list
	Method DeleteChild:Int(child:TGUIobject)
		If Not _children Then Return False
		_children.Remove(child)
		_childrenReversed.Remove(child)

		'inform object
		child.onRemoveAsChild(Self)
	End Method
	

	'removes child and adds it back to the guimanager
	Method RemoveChild:Int(child:TGUIobject)
		'remove from children list
		If Not _children Then Return False
		_children.Remove(child)
		_childrenReversed.Remove(child)

		'add back to guimanager
		'RON: this should be needed but bugs out "news dnd handling"
		'GuiManager.Add(child)

		'inform object
		child.onRemoveAsChild(Self)
	End Method


	Method UpdateChildren:Int()
		If Not _children Or _children.Count() = 0 Then Return False
		If HasOption(GUI_OBJECT_STATIC_CHILDREN) Then Return False

		'traverse through a backup to avoid concurrent modification
		'Local childrenReversedBackup:TList = _childrenReversed.Copy()
		Local childrenReversedBackup:TGUIobject[] = TGUIObject[](_childrenReversed.ToArray())
		'update added elements
		For Local obj:TGUIobject = EachIn childrenReversedBackup
			'avoid getting updated multiple times
			'this can be overcome with a manual "obj.Update()"-call
			'if obj._lastUpdateTick = GUIManager._lastUpdateTick then continue
			'obj._lastUpdateTick = GUIManager._lastUpdateTick

			obj.update()
		Next
	End Method


	Method onAddAsChild:Int(parent:TGUIObject)
		'stub
	End Method


	Method onRemoveAsChild:Int(parent:TGUIObject)
		'stub
	End Method
		

	Method RestrictContentViewport:Int()
		GUIManager.RestrictViewport(..
			Int(GetContentScreenX()), ..
			Int(GetContentScreenY()), ..
			Int(GetContentScreenWidth()), ..
			Int(GetContentScreenHeight()) ..
		)
	End Method
	

	Method RestrictViewport:Int()
		Local screenRect:TRectangle = GetScreenRect()
		If screenRect and screenRect.GetW() > 0 and screenRect.GetH() > 0
			GUIManager.RestrictViewport(..
				Int(screenRect.getX()), ..
				Int(screenRect.getY()), ..
				Int(screenRect.getW()), ..
				Int(screenRect.getH()) ..
			)
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
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onRemoveFocus", Null , _focusedObject, obj))
			_focusedObject.removeFocus()
		EndIf

		'inform about a new object getting focused
		'sender = newly focused object
		'receiver = previous focused object
		If obj Then EventManager.triggerEvent(TEventSimple.Create("guiobject.onSetFocus", Null , obj, _focusedObject))

		'set new focused object
		_focusedObject = obj
		'if there is a focused object now - inform about gain of focus
		If _focusedObject Then _focusedObject.setFocus()

		GuiManager.SortLists()
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


	Method SetValue(value:String)
		Self.value = value
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


	Method SetHovered:Int(bool:Int)
		SetStatus(GUI_OBJECT_STATUS_HOVERED, bool)
	End Method


	Method IsSelected:Int()
		Return (_status & GUI_OBJECT_STATUS_SELECTED) <> 0
	End Method


	Method SetSelected:Int(bool:Int)
		'skip if already done
		If IsSelected() = bool Then Return True

		If bool
			onSelect()
		Else
			onDeselect()
		EndIf
		SetStatus(GUI_OBJECT_STATUS_SELECTED, bool)

		Return True
	End Method


	Method IsAppearanceChanged:Int()
		Return (_status & GUI_OBJECT_STATUS_APPEARANCE_CHANGED) <> 0
	End Method


	Method SetAppearanceChanged:Int(bool:Int)
		SetStatus(GUI_OBJECT_STATUS_APPEARANCE_CHANGED, bool)

		If bool = True
			'inform parent (and its grandparent and...)
			If _parent And Not _parent.IsAppearanceChanged()
				_parent.SetAppearanceChanged(bool)
			EndIf
			'inform children
			If _children
				For Local child:TGUIobject = EachIn _children
					If child.IsAppearanceChanged() Then Continue
					child.SetAppearanceChanged(bool)
				Next
			EndIf
		EndIf
	End Method


	'called when appearance changes - override in widgets to react
	'to it
	'do not call this directly, this is handled at the end of
	'each "update" call so multiple things can set "appearanceChanged"
	'but this function is called only "once"
	Method onStatusAppearanceChange:Int()
		'
	End Method


	Method onSelect:Int()
		EventManager.triggerEvent( TEventSimple.Create( "GUIObject.onSelect", Null, Self ) )
	End Method


	Method onDeselect:Int()
		EventManager.triggerEvent( TEventSimple.Create( "GUIObject.onDeselect", Null, Self ) )
	End Method


	Method isDragable:Int()
		Return (_flags & GUI_OBJECT_DRAGABLE) <> 0
	End Method


	Method isDragged:Int()
		Return (_flags & GUI_OBJECT_DRAGGED) <> 0
	End Method


	Method IsClickable:Int()
		Return (_flags & GUI_OBJECT_CLICKABLE) <> 0
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

			'should not be needed (enabled-flag is not used in sort)
			'GUIManager.SortLists()
		EndIf
	End Method


	Method disable()
		If hasOption(GUI_OBJECT_ENABLED)
			_flags :& ~GUI_OBJECT_ENABLED

			'should not be needed (enabled-flag is not used in sort)
			'GUIManager.SortLists()


			'no longer clicked
			mouseIsClicked = Null
			'no longer hovered or active
			If IsHovered() Then SetHovered(False)
			setState("")
			'remove focus
			If HasFocus() Then removeFocus()
		EndIf
	End Method


	Method IsEnabled:Int()
		Return (_flags & GUI_OBJECT_ENABLED) <> 0
	End Method
	

	Method Resize(w:Float = 0, h:Float = 0)
		If w > 0 Then rect.dimension.setX(w)
		If h > 0 Then rect.dimension.setY(h)
	End Method


	Method SetPosition(x:Float, y:Float)
		rect.position.SetXY(x, y)
	End Method


	Method Move(dx:Float, dy:Float)
		rect.position.AddXY(dx, dy)
	End Method


	'set the anchor of the gui object
	'valid values are 0-1.0 (percentage)
	Method SetHandlePosition:Int(handleLeft:Float=0.0, handleTop:Float=0.0)
		handlePosition = New TVec2D.init(handleLeft, handleTop)
	End Method


	'set the anchor of the gui objects content
	'valid values are 0-1.0 (percentage)
	Method SetContentPosition:Int(contentLeft:Float=0.0, contentTop:Float=0.0)
		contentPosition = New TVec2D.Init(contentLeft, contentTop)
	End Method


	Method GetZIndex:Int()
		If zIndex = 0
			'each children is at least 1 zindex higher
			If _parent Then Return _parent.GetZIndex() + 1
		'-1 means: try to get the zindex from parent
		ElseIf zIndex = -1
			If _parent Then Return _parent.GetZIndex()
		EndIf
		Return zIndex
	End Method


	Method SetZIndex(zindex:Int)
		Self.zIndex = zindex
		GUIManager.SortLists()
	End Method


	Method SetState(state:String="", forceSet:Int=False)
		If state <> "" Then state = "."+state
		If Self.state <> state Or forceSet
			'do other things (eg. events)
			Self.state = state
		EndIf
	End Method


	Method GetState:String()
		If state <> "" Then Return Mid(state, 1)
		Return ""
	End Method


	Method SetPadding:Int(top:Float, Left:Float, bottom:Float, Right:Float)
		If Not _padding
			_padding = New TRectangle.Init(top, Left, bottom, Right)
		Else
			_padding.setTLBR(top, Left, bottom, Right)
		EndIf
		resize()
	End Method


	Method GetPadding:TRectangle()
		If Not _padding Then _padding = New TRectangle.Init(0,0,0,0)
		Return _padding
	End Method


	Method drag:Int(coord:TVec2D=Null)
		If Not isDragable() Or isDragged() Then Return False

		positionBackup = New TVec2D.Init( GetScreenX(), GetScreenY() )


		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDrag", New TData.Add("coord", coord), Self)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			'trigger an event immediately - if the event has a veto afterwards, do not drag!
			Local event:TEventSimple = TEventSimple.Create( "guiobject.onDrag", New TData.Add("coord", coord), Self )
			EventManager.triggerEvent( event )
			If event.isVeto() Then Return False

			'nobody said "no" to drag, so drag it
			GuiManager.AddDragged(Self)
			GUIManager.SortLists()

			'inform others - item finished dragging
			Local ev:TEventSimple = TEventSimple.Create("guiobject.onFinishDrag", New TData.Add("coord", coord), Self)
			EventManager.triggerEvent(ev)
			Self.onFinishDrag(ev)

			Return True
		Else
			Return False
		EndIf
	End Method


	'forcefully drops an item back to the position when dragged
	Method dropBackToOrigin:Int()
		If Not positionBackup Then Return False
		drop(positionBackup, True)
		Return True
	End Method


	Method drop:Int(coord:TVec2D=Null, force:Int=False)
		If Not isDragged() Then Return False

		If coord And coord.getX()=-1 Then coord = New TVec2D.Init(MouseManager.x, MouseManager.y)


		Local event:TEventSimple = TEventSimple.Create("guiobject.onTryDrop", New TData.Add("coord", coord), Self)
		EventManager.triggerEvent( event )
		'if there is no problem ...just start dropping
		If Not event.isVeto()
			'fire an event - if the event has a veto afterwards, do not drop!
			'exception is, if the action is forced
			Local event:TEventSimple = TEventSimple.Create("guiobject.onDrop", New TData.Add("coord", coord), Self)
			EventManager.triggerEvent( event )

			If Not force And event.isVeto()
				'inform others - item failed dropping, GetReceiver might
				'contain the item it should have been dropped to
				EventManager.triggerEvent(TEventSimple.Create("guiobject.onDropFailed", New TData.Add("coord", coord), Self, event.GetReceiver()))
				Return False
			EndIf

			'nobody said "no" to drop, so drop it
			GUIManager.RemoveDragged(Self)
			GUIManager.SortLists()

			'inform others - item finished dropping - Receiver of "event" may now be helding the guiobject dropped on
			Local ev:TEventSimple = TEventSimple.Create("guiobject.onFinishDrop", New TData.Add("coord", coord), Self, event.GetReceiver())
			EventManager.triggerEvent(ev)
			Self.onFinishDrop(ev)

			Return True
		Else
			Return False
		EndIf
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
		If _parent Then Return alpha * _parent.GetScreenAlpha()
		Return alpha
	End Method


	Method GetScreenHeight:Float()
		Return rect.GetH()
	End Method


	Method GetScreenPos:TVec2D()
		Return New TVec2D.Init(GetScreenX(), GetScreenY())
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


	Method GetScreenX2:Float()
		Return GetScreenX() + GetScreenWidth()
	End Method


	Method GetScreenY2:Float()
		Return GetScreenY() + GetScreenHeight()
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
		Return New TRectangle.Init(..
			GetContentScreenX(), ..
			GetContentScreenY(), ..
			GetContentScreenWidth(), ..
			GetContentScreenHeight()..
		)
	End Method


	'get a rectangle describing the objects area on the screen
	Method GetScreenRect:TRectangle()
		If screenRect Then Return screenRect

		screenRect = New TRectangle

		'dragged items ignore parents but take care of mouse position...
		If isDragged()
			screenRect.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
			Return screenRect.Copy()
		EndIf

		'if the item ignores parental limits, just return its very own screen rect
		If HasOption(GUI_OBJECT_IGNORE_PARENTLIMITS)
			screenRect.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
			Return screenRect.Copy()
		EndIf

		'no other limiting object - just return the object's area
		'(no move needed as it is already oriented to screen 0,0)
		If Not _parent
			If Not rect Then Print "NO SELF RECT"
			screenRect.CopyFrom(rect)
			Return screenRect.Copy()
		EndIf


		Local resultRect:TRectangle = _parent.GetScreenRect()
		'only try to intersect if the parent gaves back an intersection (or self if no parent)
		If resultRect
			'create a sourceRect which is a screen-rect (=visual!)
			Local sourceRect:TRectangle = New TRectangle.Init( ..
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
				screenRect.CopyFrom(resultRect)
				Return screenRect.Copy()
			EndIf
		EndIf
		screenRect.Init(0,0,-1,-1)
		Return screenRect.Copy()
	End Method


	Method Draw()
		If _customDraw
			_customDraw(Self)
		Else
			If _customDrawBackground
				_customDrawBackground(Self)
			Else
				DrawBackground()
			EndIf

			If _customDrawContent
				_customDrawContent(Self)
			Else
				DrawContent()
			EndIf
			
			If _customDrawOverlay
				_customDrawChildren(Self)
			Else
				DrawChildren()
			EndIf
			
			If _customDrawOverlay
				_customDrawOverlay(Self)
			Else
				DrawOverlay()
			EndIf
		EndIf
	End Method


	'has to get implemented in each widget
	Method DrawContent() Abstract


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
		If Not _children Then Return False

		'skip children if self not visible
		If Not IsVisible() Then Return False

		'draw children
		For Local obj:TGUIobject = EachIn _children
			'before skipping a dragged one, we try to ask it as a ghost (at old position)
			If obj.isDragged() Then obj.drawGhost()
			'skip dragged ones - as we set them to managed by GUIManager for that time
			If obj.isDragged() Then Continue

			'skip invisible objects
			If Not obj.IsVisible() Then Continue

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
		screenRect = Null
	
		'to recognize clicks/hovers/actions on child elements:
		'ask them first!
		UpdateChildren()


		'if appearance changed since last update tick: inform widget
		If isAppearanceChanged()
			onStatusAppearanceChange()
			SetAppearanceChanged(False)
		EndIf


		If GUIManager._ignoreMouse Then Return False


		'=== HANDLE MOUSE ===
		If Not GUIManager.UpdateState_mouseButtonDown[1]
			mouseIsDown	= Null
			'remove hover/active state
			setState("")
		EndIf

		'mouse position could have changed since a begin of a "click"
		'-> eg when clicking + moving the cursor very fast
		'   in that case the mouse position should be the one of the
		'   moment the "click" begun
		Local mousePos:TVec2D = New TVec2D.Init(MouseManager.x, MouseManager.y)
		If MouseManager.IsClicked(1) Or MouseManager.GetClicks(1) > 0
			mousePos = MouseManager.GetClickPosition(1)
		EndIf

		Local containsMouse:Int = containsXY(mousePos.x, mousePos.y)


		'=== HANDLE MOUSE OVER ===

		'if nothing of the obj is visible or the mouse is not in
		'the visible part - reset the mouse states
		If Not containsMouse

			'avoid fast mouse movement to get interpreted incorrect
			'-> only "unhover" undragged elements
			If Not isDragged()
				'reset clicked position as soon as leaving the widget
				mouseIsClicked = Null
				SetHovered(False)
				setState("")
			EndIf
			'mouseclick somewhere - should deactivate active object
			'no need to use the cached mouseButtonDown[] as we want the
			'general information about a click
'			If MOUSEMANAGER.isHit(1) And hasFocus() Then GUIManager.setFocus(Null)
		'mouse over object
		Else
			'inform others about a scroll with the mousewheel
			If GUIManager.UpdateState_mouseScrollwheelMovement <> 0
				Local event:TEventSimple = TEventSimple.Create("guiobject.OnScrollwheel", New TData.AddNumber("value", GUIManager.UpdateState_mouseScrollwheelMovement).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
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
		If Not containsMouse And Not isDragged() Then Return False


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
						If HasOption(GUI_OBJECT_CAN_GAIN_FOCUS)
							GUImanager.setFocus(Self)
						EndIf

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
					If Not isHovered()
						EventManager.triggerEvent( TEventSimple.Create( "guiobject.OnMouseEnter", Null, Self ) )
						SetHovered(True)
					EndIf
					GUIManager.UpdateState_foundHoverObject = Self
				EndIf
				'create event: onmouseover
				Local mouseOverEvent:TEventSimple = TEventSimple.Create("guiobject.OnMouseOver", New TData.Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self )
				OnMouseOver(mouseOverEvent)
				EventManager.triggerEvent(mouseOverEvent)

				'somone decided to say the button is pressed above the object
				If MouseIsDown
					setState("active")
					EventManager.triggerEvent( TEventSimple.Create("guiobject.OnMouseDown", New TData.AddNumber("button", 1), Self ) )
				Else
					setState("hover")
				EndIf

				If IsClickable()
					'inform others about a right guiobject click
					'we do use a "cached hit state" so we can reset it if
					'we found a one handling it
					If (MouseManager.IsClicked(2) Or MouseManager.IsLongClicked(1)) And Not GUIManager.UpdateState_foundHitObject[2 -1]
						Local clickEvent:TEventSimple = TEventSimple.Create("guiobject.OnClick", New TData.AddNumber("button",2).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
						OnClick(clickEvent)
						'fire onClickEvent
						EventManager.triggerEvent(clickEvent)

						'maybe change to "isAccepted" - but then each gui object
						'have to modify the event IF they accepted the click

						'reset Button
						If MouseManager.IsLongClicked(1)
							GUIManager.UpdateState_mouseButtonHit[1] = False
							'MouseManager.ResetClicked(1) 'long and normal
						Else
							GUIManager.UpdateState_mouseButtonHit[2] = False
						EndIf

						GUIManager.UpdateState_foundHitObject[2 -1] = Self
					EndIf


					'IsClicked does not include waiting time - so check for
					'single and double clicks too
					If Not GUIManager.UpdateState_foundHitObject[0]
						Local isHit:Int = False
						If Not MouseManager.IsLongClicked(1)
							If MouseManager.IsHit(1)
								Local hitEvent:TEvenTsimple = TEventSimple.Create("guiobject.OnHit", New TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
								'let the object handle the click
								OnHit(hitEvent)
								'fire onClickEvent
								EventManager.triggerEvent(hitEvent)
								isHit = True
							EndIf
							
							If MOUSEMANAGER.IsClicked(1) Or MOUSEMANAGER.GetClicks(1) > 0
								'=== SET CLICKED VAR ====
								mouseIsClicked = MouseManager.GetClickposition(1)

								'=== SEND OUT CLICK EVENT ====
								'if recognized as "double click" no normal "onClick"
								'is emitted. Same for "single clicks".
								'this avoids sending "onClick" and after 100ms
								'again "onSingleClick" AND "onClick"
								Local clickEvent:TEventSimple
								If MOUSEMANAGER.IsDoubleClicked(1)
									clickEvent = TEventSimple.Create("guiobject.OnDoubleClick", New TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
									'let the object handle the click
									OnDoubleClick(clickEvent)
								ElseIf MOUSEMANAGER.IsSingleClicked(1)
									clickEvent = TEventSimple.Create("guiobject.OnSingleClick", New TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
									'let the object handle the click
									OnSingleClick(clickEvent)
								'only "hit" if done the first time
								Else 'if not GUIManager.UpdateState_foundHitObject
									clickEvent = TEventSimple.Create("guiobject.OnClick", New TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
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

								GUIManager.UpdateState_foundHitObject[0] = Self
							EndIf
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
	Function ConvertKeystrokesToText:Int(value:String Var, skipEnterKey:Int = False)
		'remove with backspace
		If KEYWRAPPER.pressedKey(KEY_BACKSPACE)
			value = value[..value.length -1]
			Return True
		EndIf
		'abort with ESCAPE
		If KEYWRAPPER.pressedKey(KEY_ESCAPE) Then Return False

		'read special keys (shift + altgr) to enable special key handling
		Local shiftPressed:Int = KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161)
		?Not Linux
		'windows and mac
		Local altGrPressed:Int = KEYMANAGER.IsDown(164) Or KEYMANAGER.IsDown(165)
		?Linux
		'linux
		Local altGrPressed:Int = KEYMANAGER.IsDown(3)
		?

		'charCode is "0" if no key is recognized
		Local charCode:Int = Int(GetChar())

		'loop through all chars of the getchar-queue
		While charCode <>0
			'charCode is < 0 for me when umlauts are pressed
			If charCode < 0
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
			ElseIf charCode > 0
				Local addChar:Int = True
				'skip "backspace"
				If Chr(KEY_BACKSPACE) = Chr(charCode) Then addChar = False
				'skip enter if whished so
				If skipEnterKey And Chr(KEY_ENTER) = Chr(charCode) Then addChar = False

				If addChar Then value :+ Chr(charCode)
			EndIf
			charCode = Int(GetChar())
		Wend

		'special chars - recognized on Mac, but not Linux
		'euro sign
		?Linux
		If KEYWRAPPER.pressedKey(69) And altGrPressed Then value :+ Chr(8364)
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
		DrawRect(Self.GetScreenX(), Self.GetScreenY(), Self.GetScreenWidth(), Self.GetScreenHeight())
		SetAlpha 1.0
	End Method
End Type
