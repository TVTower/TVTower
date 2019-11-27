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
Import "base.gfx.tooltip.base.bmx"

Import "base.util.registry.spriteloader.bmx"

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
'does the gui object manage assigned tooltips?
Const GUI_OBJECT_TOOLTIP_MANAGED:Int            = 2^17

'===== GUI STATUS CONSTANTS =====
Const GUI_OBJECT_STATUS_HOVERED:Int	= 2^0
Const GUI_OBJECT_STATUS_SELECTED:Int = 2^1
Const GUI_OBJECT_STATUS_APPEARANCE_CHANGED:Int	= 2^2
Const GUI_OBJECT_STATUS_CONTENT_CHANGED:Int	= 2^3
Const GUI_OBJECT_STATUS_ACTIVE:Int = 2^4
Const GUI_OBJECT_STATUS_FOCUSED:Int = 2^5
Const GUI_OBJECT_STATUS_SCREENRECT_VALID:Int = 2^6
Const GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID:Int = 2^7
Const GUI_OBJECT_STATUS_LAYOUT_VALID:Int = 2^8

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
	Field List:TObjectList = New TObjectList
	'contains dragged objects (above normal)
	Field ListDragged:TObjectList = New TObjectlist
	'contains objects which need to get informed because of changed appearance
	Field elementsWithChangedAppearance:TObjectList = New TObjectList
	Field activeTooltips:TObjectList = New TObjectList


	'=== UPDATE STATE PROPERTIES ===

	Field UpdateState_mouseButtonDown:Int[]
	Field UpdateState_mouseScrollwheelMovement:Int = 0
	Field UpdateState_foundClickedObject:TGUIObject[]
	Field UpdateState_foundHoverObject:TGUIObject = Null
	Field UpdateState_foundFocusObject:TGUIObject = Null


	'=== PRIVATE PROPERTIES ===

	Field _defaultfont:TBitmapFont
	Field _ignoreMouse:Int = False
	'is there an object listening to keystrokes?
	Field _keystrokeReceivingObject:TGUIObject = Null
	Field _focusedObject:TGUIObject

	Global _instance:TGUIManager
	Global _eventListeners:TEventListenerBase[]



	Method New()
		If Not _instance Then Self.Init()
	End Method


	Function GetInstance:TGUIManager()
		If Not _instance Then _instance = New TGUIManager
		Return _instance
	End Function


	Method Init:TGUIManager()
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]


		'is something dropping on a gui element?
		_eventListeners :+ [EventManager.registerListenerFunction("guiobject.onDrop", TGUIManager.onDrop)]

		'gui specific settings
		config.AddNumber("panelGap",10)


		UpdateState_mouseButtonDown = New Int[ MouseManager.GetButtonCount() +1]
		UpdateState_foundClickedObject = New TGUIObject[ MouseManager.GetButtonCount() +1]

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
				'inform about drag and ask object if it wants to handle the drop
				potentialDropTarget.onDrop(triggerEvent)

				If triggerEvent.isAccepted()
					dropTarget = potentialDropTarget
					'modify event to hold dropTarget now
					triggerEvent.GetData().Add("dropTarget", dropTarget)

					'do not ask other targets if there was already one handling that drop
					Exit
				EndIf

				'do not ask other targets if one object already aborted the event
				If triggerEvent.isVeto() Then Exit
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
		If w > 0 And h > 0
			GetGraphicsManager().SetViewport(x,y,w,h)
		EndIf
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
		If objA.IsFocused() Then Return 1
		'if objB is active element - move to top
		If objB.IsFocused() Then Return -1

		'if objA is "higher", move it to the top
		If objA.GetZIndex() > objB.GetZIndex() Then Return 1
		'if objA is "lower"", move to bottom
		If objA.GetZIndex() < objB.GetZIndex() Then Return -1

		'if one of them is active - prefer it
		If objA._status & GUI_OBJECT_STATUS_ACTIVE Then Return 1
		If objB._status & GUI_OBJECT_STATUS_ACTIVE Then Return -1


		'run custom compare job
'		return objA.compare(objB)
		Return 0
	End Function


	Method SortLists()
		List.sort(True, SortObjects)
	End Method


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
		If(state And obj.GetLimitToState() <> "")
			Return IsState(obj, state)
		EndIf
		Return True
	End Method


	'returns an array of objects at the given point
	Method GetObjectsByPos:TGuiObject[](coord:TVec2D, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
		Return GetObjectsByXY(coord.GetIntX(), coord.GetIntY(), limitState, ignoreDragged, requiredFlags, limit)
	End Method


	'returns an array of objects at the given x,y coordinate
	Method GetObjectsByXY:TGuiObject[](x:Int, y:Int, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
	'	If limitState=Null Then limitState = currentState

		Local guiObjects:TGuiObject[]
		'from TOP to BOTTOM (user clicks to visible things - which are at the top)
		For Local obj:TGUIobject = EachIn list.ReverseEnumerator()
			'return array if we reached the limit
			If limit > 0 And guiObjects.length >= limit Then Return guiObjects

			If Not haveToHandleObject(obj, limitState) Then Continue

			'avoids finding the dragged object on a drop-event
			If Not ignoreDragged And obj.isDragged() Then Continue

			'if obj is required to accept drops, but does not so  - continue
			If (requiredFlags & GUI_OBJECT_ACCEPTS_DROP) And Not(obj._flags & GUI_OBJECT_ACCEPTS_DROP) Then Continue

			If obj.GetScreenRect().containsXY(x, y)
				'add to array
				guiObjects = guiObjects[..guiObjects.length+1]
				guiObjects[guiObjects.length-1] = obj
			EndIf
		Next

		Return guiObjects
	End Method


	Method GetFirstObjectByPos:TGuiObject(coord:TVec2D, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0)
		Return GetFirstObjectByXY(coord.GetIntX(), coord.GetIntY(), limitState, ignoreDragged, requiredFlags)
	End Method


	Method GetFirstObjectByXY:TGuiObject(x:Int, y:Int, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0)
		Local guiObjects:TGuiObject[] = GetObjectsByXY(x, y, limitState, ignoreDragged, requiredFlags, 1)

		If guiObjects.length = 0 Then Return Null Else Return guiObjects[0]
	End Method


	Method DisplaceGUIobjects(State:TLowerString = Null, x:Int = 0, y:Int = 0)
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


	'sets the currently focused object
	Method SetFocus(obj:TGUIObject)
		'if there was an focused object -> inform about removal of focus
		If (obj <> _focusedObject) And _focusedObject
			'sender = previous focused object
			'receiver = newly focused object
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onRemoveFocus", Null , _focusedObject, obj))
			_focusedObject._SetFocused(False)
		EndIf

		'inform about a new object getting focused
		'sender = newly focused object
		'receiver = previous focused object
		If obj
			EventManager.triggerEvent(TEventSimple.Create("guiobject.onSetFocus", Null , obj, _focusedObject))
			obj._SetFocused(True)
		EndIf

		'set new focused object
		_focusedObject = obj

		'if there is a focused object now - inform about gain of focus
		If _focusedObject
			UpdateState_foundFocusObject = _focusedObject

			'try to set as potential keystroke receiver
			SetKeystrokeReceiver(obj)
		EndIf

		GuiManager.SortLists()
	End Method


	Method GetFocus:TGUIObject()
		Return _focusedObject
	End Method


	Method ResetFocus:Int()
		'remove focus (eg. when switching gamestates
		SetFocus(Null)

		'also remove potential keystroke receivers
		SetKeystrokeReceiver(Null)
	End Method


	'should be run on start of the current tick
	Method StartUpdates:Int()

		UpdateState_mouseScrollwheelMovement = MouseManager.GetScrollwheelMovement()
		UpdateState_mouseButtonDown = MouseManager.GetAllIsDown()

		UpdateState_foundFocusObject = Null
		UpdateState_foundClickedObject = New TGUIObject[ MouseManager.GetButtonCount() + 1]
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


	Method UpdateElementswithChangedAppearance()
		If elementsWithChangedAppearance.Count() > 0
			For Local obj:TGUIObject = EachIn elementsWithChangedAppearance
				If obj.isAppearanceChanged()
					obj.onAppearanceChanged()
					obj.SetAppearanceChanged(False)
				EndIf
			Next
		EndIf
	End Method


	Method Update(State:TLowerString = Null, fromZ:Int=-1000, toZ:Int=-1000, updateTypes:Int=GUIMANAGER_TYPES_ALL)
		'_lastUpdateTick :+1
		'if _lastUpdateTick >= 100000 then _lastUpdateTick = 0

		currentState = State

		'this needs to get run in Draw() and Update() as you might else
		'run into discrepancies (drawn without updates according to new
		'visuals)
		UpdateElementswithChangedAppearance()


		'first update all dragged objects...
		If GUIMANAGER_TYPES_DRAGGED & updateTypes
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
		EndIf

		'then the rest
		If GUIMANAGER_TYPES_NONDRAGGED & updateTypes
			'from top to bottom
			For Local obj:TGUIobject = EachIn list.ReverseEnumerator()
				'all dragged objects got already updated...
				If ListDragged.Contains(obj) Then Continue
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'avoid getting updated multiple times
				'this can be overcome with a manual "obj.Update()"-call
				'if obj._lastUpdateTick = _lastUpdateTick then continue
				'obj._lastUpdateTick = _lastUpdateTick
				obj.Update()
				'if there is a tooltip, update it.
				'We handle it that way to be able to "group/order" tooltip updates
				If obj._tooltip
					'update hovered state
					obj._tooltip.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED, obj.IsHovered())
					obj._tooltip.Update()
				EndIf
				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onUpdate", Null, obj ) )
			Next
		EndIf
	End Method


	Method Draw:Int(State:TLowerString = Null, fromZ:Int=-1000, toZ:Int=-1000, drawTypes:Int=GUIMANAGER_TYPES_ALL)
		'_lastDrawTick :+1
		'if _lastDrawTick >= 100000 then _lastDrawTick = 0

		currentState = State

		'this needs to get run in Draw() and Update() as you might else
		'run into discrepancies (drawn without updates according to new
		'visuals)
		UpdateElementswithChangedAppearance()


		If GUIMANAGER_TYPES_NONDRAGGED & drawTypes
			activeTooltips.Clear()
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

				obj.Draw()

				If obj._tooltip And (obj._flags & GUI_OBJECT_ENABLED) And (obj._flags & GUI_OBJECT_TOOLTIP_MANAGED)  'and not obj.hasOption(GUI_OBJECT_MANAGED)
					activeTooltips.AddLast(obj._tooltip)
				EndIf

				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
			Next

			'TODO: sort by lastActive state?
			For Local t:TTooltipBase = EachIn activeTooltips
				t.Render()
			Next
		EndIf


		If GUIMANAGER_TYPES_DRAGGED & drawTypes
			'draw all dragged objects above normal objects...
			'from bottom to top
			For Local obj:TGUIobject = EachIn ListDragged.ReverseEnumerator()
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'avoid getting drawn multiple times
				'this can be overcome with a manual "obj.Draw()"-call
				'if obj._lastDrawTick = _lastDrawTick then continue
				'obj._lastDrawTick = _lastDrawTick

				obj.Draw()

				'fire event
				EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
			Next
		EndIf
	End Method
End Type
Global GUIManager:TGUIManager = TGUIManager.GetInstance()




Type TGUIobject
	'There are two rectangles: the original position and size without
	'limitations and with limitations by the current canvas/screen through
	'parents/canvas restrictions

	'the area of the widget on the "canvas"
	Field rect:TRectangle = New TRectangle.Init(-1,-1,-1,-1)
	'area the widget occupies on the screen (including limitations like
	'reache screen borders and screen limitations by parent widgets
	Field _screenRect:TRectangle = New TRectangle
	'are for content on the screen
	Field _contentScreenRect:TRectangle = New TRectangle


	Field zIndex:Int = 0
	'storage for additional data
	Field data:TData = New TData
	Field alpha:Float = 1.0
	'where to attach the content within the object
	Field contentAlignment:TVec2D = New TVec2D.Init(0.5, 0.5)
	Field value:String = ""
	Field mouseIsClicked:TVec2D	= Null 'null = not clicked
	Field mouseIsDown:TVec2D = Null
	'displacement of object when dragged (null = centered)
	Field handle:TVec2D	= Null


	Field _tooltip:TTooltipBase = Null
	Field _children:TObjectList = Null
	Field _childrenReversed:TObjectList = Null
	Field _id:Int
	Field _padding:TRectangle = Null 'by default no padding
	Field _flags:Int = 0
	'status of the widget: eg. GUI_OBJECT_STATUS_APPEARANCE_CHANGED
	Field _status:Int = 0
	'the font used to display text in the widget
	Field _font:TBitmapFont
	'the font used in the last display call
	Field _lastFont:TBitmapFont
	'time when item got dragged
	Field _timeDragged:Int = 0
	Field _parent:TGUIobject = Null
	'only handle if this state is requested on guimanager.update / draw
	Field _limitToState:String = ""
	'an array containing registered event listeners
	Field _registeredEventListener:TEventListenerBase[]
	'Field _lastDrawTick:int = 0
	'Field _lastUpdateTick:int = 0

	'=== HOOKS ===
	'allow custom functions to get hooked in
	Field _customDraw:Int(obj:TGUIObject)
	Field _customDrawBackground:Int(obj:TGUIObject)
	Field _customDrawContent:Int(obj:TGUIObject)
	Field _customDrawChildren:Int(obj:TGUIObject)
	Field _customDrawOverlay:Int(obj:TGUIObject)


	Global ghostAlpha:Float	= 0.5
	Global _lastID:Int


	Method New()
		_lastID:+1
		_id = _lastID

		'default options
		SetOption(GUI_OBJECT_VISIBLE, True)
		SetOption(GUI_OBJECT_ENABLED, True)
		SetOption(GUI_OBJECT_CLICKABLE, True)
		SetOption(GUI_OBJECT_CAN_GAIN_FOCUS, True)
		SetOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER, True)
	End Method


	Method GetClassName:String() Abstract
'		Return "TGUIObject"
'	End Method


	Method CreateBase:TGUIobject(pos:TVec2D, dimension:TVec2D, limitState:String="")
		'create missing params
		If Not pos Then pos = New TVec2D.Init(0,0)
		If Not dimension Then dimension = New TVec2D.Init(-1,-1)

		SetPosition(pos.x, pos.y)
		'resize widget, dimension of (-1,-1) is "auto dimension"
		SetSize(dimension.x, dimension.y)

		SetLimitToState(limitState)
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

		EventManager.UnregisterListenersArray(_registeredEventListener)
		_registeredEventListener = New TEventListenerBase[0]

		'maybe our parent takes care of us...
		If _parent Then _parent.RemoveChild(Self)

		'remove children (so they might inform their children and so on)
		If _children
			'traverse along a copy to avoid concurrent modification
			For Local child:TGUIObject = EachIn _children
				child.Remove()
			Next
			_children.Clear()
			_childrenReversed.Clear()
		EndIf

		'just in case we have a managed one
		GUIManager.remove(Self)

		Return True
	End Method


	Method AddEventListener:Int(listener:TEventListenerBase)
		_registeredEventListener :+ [listener]
	End Method


	Function SetTypeFont:Int(font:TBitmapFont)
		'implement in classes
	End Function


	'override in extended classes if wanted
	Function GetTypeFont:TBitmapFont()
		Return Null
	End Function


	Method SetFont:Int(font:TBitmapFont)
		If Self._font <> font
			Self._font = font

			SetAppearanceChanged(True)
		EndIf
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


	Method SetTooltip(t:TTooltipBase, setTooltipParent:Int = True, setTooltipManaged:Int = True)
		Self._tooltip = t

		If Self._tooltip
			'ATTENTION: reference, not copy!
			If setTooltipParent Then Self._tooltip.parentArea = Self._screenRect

			'the gui object updates hovered state to only hover if the
			'widget is hovered (avoids drawing tooltips for window _and_
			'a child button)
			Self._tooltip.SetOption(TTooltipBase.OPTION_MANUAL_HOVER_CHECK, True)

			'a managed tooltip is automatically drawn by a widget while
			'a non-managed needs to call stuff on its own
			Self.SetOption(GUI_OBJECT_TOOLTIP_MANAGED, setTooltipManaged)
		EndIf
	End Method


	Method GetTooltip:TTooltipBase()
		Return Self._tooltip
	End Method



	Method SetParent:Int(parent:TGUIobject)
		_parent = parent
	End Method


	'traverse through object's parents to find the given one
	Method HasParent:Int(parent:TGUIObject)
		If Not _parent Then Return False
		If _parent = parent Then Return True
		Return _parent.HasParent(parent)
	End Method


	'return the uppermost parent or null if there is none
	Method GetTopmostParent:TGUIObject()
		If _parent And _parent Then Return _parent.GetTopmostParent()
		Return _parent 'parent or null
	End Method


	'returns the requested parent
	'if parentclassname is NOT found and <> "" you get the uppermost
	'parent returned
	Method GetFirstParentalObject:TGUIobject(parentClassName:String="")
		If Not _parent Then Return Null
		'if no special parent is requested, just return the direct parent or self
		If parentClassName="" Then Return _parent

		If _parent.GetClassName() = parentClassName.toLower() Then Return _parent
		If _parent._parent Then Return _parent.GetFirstParentalObject(parentClassName)
	End Method


	Method SortChildren()
		If _children Then _children.sort(True, TGUIManager.SortObjects)
		If _childrenReversed Then _childrenReversed.sort(False, TGUIManager.SortObjects)
	End Method


	Method AddChild:Int(child:TGUIobject)
		'remove child from a prior parent to avoid multiple references
		If child._parent Then child._parent.RemoveChild(child)

		child.setParent( Self )
		If Not _children Then _children = New TObjectList
		If Not _childrenReversed Then _childrenReversed = New TObjectList

		_children.addLast(child)
		_childrenReversed.addFirst(child)

		'remove from guimanager, we take care of it
		GUIManager.Remove(child)
		SortChildren()

		'maybe zindex changed now
		If hasOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER)
			GuiManager.SortLists()
		EndIf

		'inform object
		child.onAddAsChild(Self)
	End Method


	'remove child from children list
	Method RemoveChild:Int(child:TGUIobject, giveBackToManager:Int=False)
		If Not _children Then Return False
		_children.Remove(child)
		_childrenReversed.Remove(child)

		'inform object
		child.onRemoveAsChild(Self)

		'add back to guimanager
		'RON: this should be needed but bugs out "news dnd handling"
		'if giveBackToManager Then GuiManager.Add(child)
	End Method


	Method GetChildAtIndex:TGUIobject(index:Int)
		If Not _children Or _children.count() >= index Then Return Null
		Return TGUIobject( _children.ValueAtIndex(index) )
	End Method


	Method UpdateChildren:Int()
		If Not _children Or _children.Count() = 0 Then Return False
		If HasOption(GUI_OBJECT_STATIC_CHILDREN) Then Return False

		'update added elements
		For Local obj:TGUIobject = EachIn _childrenReversed
			obj.update()
		Next
	End Method


	Method RestrictContentViewport:Int()
		Local rect:TRectangle = GetContentScreenRect()
		If rect And rect.GetW() > 0 And rect.GetH() > 0
			GUIManager.RestrictViewport(Int(rect.getX()), Int(rect.getY()), Int(rect.getW()), Int(rect.getH()))
			Return True
		Else
			Return False
		EndIf
	End Method


	Method RestrictViewport:Int()
		Local rect:TRectangle = GetScreenRect()
		If rect And rect.GetW() > 0 And rect.GetH() > 0
			GUIManager.RestrictViewport(Int(rect.getX()), Int(rect.getY()), Int(rect.getW()), Int(rect.getH()))
			Return True
		Else
			Return False
		EndIf
	End Method


	Method ResetViewport()
		GUIManager.ResetViewport()
	End Method


	Method GetValue:String()
		Return value
	End Method


	Method SetValue(value:String)
		Self.value = value
	End Method


	Method HasOption:Int(option:Int)
		Return (_flags & option) <> 0
	End Method


	Method SetOption(option:Int, enable:Int=True)
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


	'returns whether the current object is focused (there should only be one)
	Method IsFocused:Int()
		Return (_status & GUI_OBJECT_STATUS_FOCUSED) <> 0
	End Method


	'method is private - to focus a widget use GUIManager.SetFocus(widget)
	Method _SetFocused:Int(bool:Int)
		If (_status & GUI_OBJECT_STATUS_FOCUSED) <> bool
'print "setactive invalidate " + bool + "   " + (_status & GUI_OBJECT_STATUS_ACTIVE)
			SetStatus(GUI_OBJECT_STATUS_FOCUSED, bool)
			If bool
				_OnSetFocus()
			Else
				_OnRemoveFocus()
			EndIf
		EndIf
	End Method


	Method IsActive:Int()
		Return (_status & GUI_OBJECT_STATUS_ACTIVE) <> 0
	End Method


	Method SetActive:Int(bool:Int)
		If (_status & GUI_OBJECT_STATUS_ACTIVE) <> bool
			SetStatus(GUI_OBJECT_STATUS_ACTIVE, bool)

			InvalidateScreenRect()
		EndIf
	End Method


	Method IsHovered:Int()
		Return (_status & GUI_OBJECT_STATUS_HOVERED) <> 0
	End Method


	Method SetHovered:Int(bool:Int)
		If (_status & GUI_OBJECT_STATUS_HOVERED) <> bool
			SetStatus(GUI_OBJECT_STATUS_HOVERED, bool)

			InvalidateScreenRect()
		EndIf
	End Method


	Method GetStateSpriteAppendix:String()
		If IsActive()
			Return ".active"
		ElseIf IsHovered()
			Return ".hover"
		Else
			Return ""
		EndIf
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

		'remove from the list (if added previously)
		GuiManager.elementsWithChangedAppearance.Remove( Self )

		If bool = True
			'inform parent (and its grandparent and...)
			If _parent
				_parent.OnChildAppearanceChanged(Self, bool)
			EndIf

			'inform children
			If _children
				For Local child:TGUIobject = EachIn _children
					child.OnParentAppearanceChanged(bool)
				Next
			EndIf

			'append to the "to inform" list
			GuiManager.elementsWithChangedAppearance.AddLast( Self )
		EndIf
	End Method


	Method IsContentChanged:Int()
		Return (_status & GUI_OBJECT_STATUS_CONTENT_CHANGED) <> 0
	End Method


	Method SetContentChanged:Int(bool:Int)
		SetStatus(GUI_OBJECT_STATUS_CONTENT_CHANGED, bool)
	End Method


	'returns true if clicked
	Method IsClicked:Int()
		If Not(_flags & GUI_OBJECT_ENABLED) Then mouseIsClicked = Null

		Return (mouseIsClicked<>Null)
	End Method


	Method IsDragable:Int()
		Return (_flags & GUI_OBJECT_DRAGABLE) <> 0
	End Method


	Method IsDragged:Int()
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


	Method IsEnabled:Int()
		'if parent widget is disabled then child is disabled too
		If _parent And Not _parent.IsEnabled() Then Return False

		Return (_flags & GUI_OBJECT_ENABLED) <> 0
	End Method


	Method Show()
		_flags :| GUI_OBJECT_VISIBLE
	End Method


	Method Hide()
		_flags :& ~GUI_OBJECT_VISIBLE
	End Method


	Method Enable()
		If Not hasOption(GUI_OBJECT_ENABLED)
			_flags :| GUI_OBJECT_ENABLED
		EndIf
	End Method


	Method Disable()
		If hasOption(GUI_OBJECT_ENABLED)
			_flags :& ~GUI_OBJECT_ENABLED

			'no longer clicked
			mouseIsClicked = Null
			'no longer hovered or active
			If IsHovered() Then SetHovered(False)
			If IsActive() Then SetActive(False)
			'remove focus
			If IsFocused() Then GUIManager.ResetFocus()
		EndIf
	End Method


	Method Grow:Int(dW:Float = 0, dH:Float = 0)
		'do not grow "auto size" (-1) values
		Local newW:Int = -1
		Local newH:Int = -1
		If rect.GetW() > -1 Then newW = rect.GetW() + dW
		If rect.GetH() > -1 Then newH = rect.GetH() + dH
		SetSize(newW, newH)
	End Method


	Method SetSize(w:Float = 0, h:Float = 0)
		Local resized:Int = False

		If w > 0 And w <> rect.dimension.x
			rect.dimension.setX(w)
			resized = True
		EndIf
		If h > 0 And h <> rect.dimension.y
			rect.dimension.setY(h)
			resized = True
		EndIf

		If resized
			OnResize()
			UpdateLayout()
		EndIf
	End Method


	Method SetPosition(x:Float, y:Float)
		If Not rect.position.EqualsXY(x,y)
			Local dx:Float = x - rect.position.x
			Local dy:Float = y - rect.position.y
			rect.position.SetXY(x, y)

			OnReposition(dx, dy)
		EndIf
	End Method


	Method SetPositionX(x:Float)
		If rect.position.x <> x
			Local dx:Float = x - rect.position.x
			rect.position.SetX(x)

			OnReposition(dx, 0)
		EndIf
	End Method


	Method SetPositionY(y:Float)
		If rect.position.y <> y
			Local dy:Float = y - rect.position.y
			rect.position.SetY(y)

			OnReposition(0, dy)
		EndIf
	End Method


	Method Move(dx:Float, dy:Float)
		If dx <> 0 Or dy <> 0
			rect.position.AddXY(dx, dy)

			OnReposition(dx, dy)
		EndIf
	End Method


	Method SetScreenPosition(x:Float, y:Float)
		If Not GetScreenRect().position.EqualsXY(x,y)
			Local dx:Float = x - _screenRect.position.x
			Local dy:Float = y - _screenRect.position.y
			rect.position.AddXY(dx, dy)

			OnReposition(dx, dy)
		EndIf
	End Method


	'set the anchor of the gui objects content
	'valid values are 0-1.0 (percentage)
	Method SetContentAlignment(contentLeft:Float=0.0, contentTop:Float=0.0)
		If Not contentAlignment.EqualsXY(contentLeft, contentTop)
			contentAlignment.Init(contentLeft, contentTop)
		EndIf
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


	Method SetZIndex(zIndex:Int)
		If Self.zIndex <> zIndex
			Self.zIndex = zindex

			If hasOption(GUI_OBJECT_MANAGED) Then GUIManager.SortLists()

			If _parent Then _parent.OnChildZIndexChanged()
		EndIf
	End Method


	Method SetPadding:Int(pTop:Float, pLeft:Float, pBottom:Float, pRight:Float)
		If Not _padding Then _padding = New TRectangle
		If Not _padding.EqualsTLBR(pTop, pLeft, pBottom, pRight)
			_padding.SetTLBR(pTop, pLeft, pBottom, pRight)

			OnChangePadding()
		EndIf
	End Method


	Method GetPadding:TRectangle()
		If Not _padding Then _padding = New TRectangle
		Return _padding
	End Method


	Method Drag:Int(coord:TVec2D=Null)
		If Not isDragable() Or isDragged() Then Return False

		data.Add("dragPosition", New TVec2D.Init( GetScreenRect().GetX(), GetScreenRect().GetY() ))

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
	Method DropBackToOrigin:Int()
		Local dragPosition:TVec2D = TVec2D(data.Get("dragPosition"))
		If Not dragPosition Then Return False

		Drop(dragPosition, True)
		Return True
	End Method


	Method Drop:Int(coord:TVec2D=Null, force:Int=False)
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


	Method SetLimitToState:Int(state:String)
		_limitToState = state
	End Method


	Method GetLimitToState:String()
		'if there is no limit set - ask parent if there is one
		If _limitToState="" And _parent Then Return _parent.GetLimitToState()

		Return _limitToState
	End Method


	'takes parent alpha into consideration
	Method GetScreenAlpha:Float()
		If _parent Then Return alpha * _parent.GetScreenAlpha()
		Return alpha
	End Method


	'Returns the x coordinate on the screen
	Method _UpdateScreenX:Float()
		If (_flags & GUI_OBJECT_DRAGGED) And Not(_flags & GUI_OBJECT_IGNORE_POSITIONMODIFIERS)
			'no manual setup of handle exists -> center the spot
			If Not handle
				_screenRect.SetX( MouseManager.x - rect.GetW()/2 + 5*GUIManager.GetDraggedNumber(Self) )
			Else
				_screenRect.SetX( MouseManager.x - GetHandle().x + 5*GUIManager.GetDraggedNumber(Self) )
			EndIf

		'only integrate parent if parent is set, or object not positioned "absolute"
		ElseIf _parent And Not(_flags & GUI_OBJECT_POSITIONABSOLUTE)
			'ignore parental padding or not
			If Not(_flags & GUI_OBJECT_IGNORE_PARENTPADDING)
				'instead of "ScreenX", we ask the parent where it wants the Content...
				_screenRect.SetX( _parent.GetContentScreenRect().GetX() + rect.GetX() )
			Else
				_screenRect.SetX( _parent.GetScreenRect().GetX() + rect.GetX() )
			EndIf
		Else
			_screenRect.SetX( rect.GetX() )
		EndIf

		Return _screenRect.GetX()
	End Method


	'Updates and returns the y coordinate on the screen
	Method _UpdateScreenY:Float()
		If (_flags & GUI_OBJECT_DRAGGED) And Not(_flags & GUI_OBJECT_IGNORE_POSITIONMODIFIERS)
			'no manual setup of handle exists -> center the spot
			If Not handle
				_screenRect.SetY( MouseManager.y - rect.GetH()/2 + 7*GUIManager.GetDraggedNumber(Self) )
			Else
				_screenRect.SetY( MouseManager.y - GetHandle().y/2 + 7*GUIManager.GetDraggedNumber(Self) )
			EndIf

		'only integrate parent if parent is set, or object not positioned "absolute"
		ElseIf _parent And Not(_flags & GUI_OBJECT_POSITIONABSOLUTE)
			'ignore parental padding or not
			If Not(_flags & GUI_OBJECT_IGNORE_PARENTPADDING)
				'instead of "ScreenY", we ask the parent where it wants the Content...
				_screenRect.SetY( _parent.GetContentScreenRect().GetY() + rect.GetY() )
			Else
				_screenRect.SetY( _parent.GetScreenRect().GetY() + rect.GetY() )
			EndIf
		Else
			_screenRect.SetY( rect.GetY() )
		EndIf

		Return _screenRect.GetY()
	End Method


	'Updates and returns the width on the screen
	Method _UpdateScreenW:Float()
		_screenRect.SetW( rect.GetW() )
		Return _screenRect.GetW()
	End Method


	'Updates and returns the width on the screen
	Method _UpdateScreenH:Float()
		_screenRect.SetH( rect.GetH() )
		Return _screenRect.GetH()
	End Method


	'correct the current screenrect to limits like parent's content
	'screen rects.
	Method _LimitScreenRect:Float()
		'do not go beyond the content area of the parent
		If _parent
			Local pScreenRect:TRectangle
			If Not(_flags & GUI_OBJECT_IGNORE_PARENTPADDING)
				pScreenRect = _parent.GetContentScreenRect()
			Else
				pScreenRect = _parent.GetScreenRect()
			EndIf

			'let autosize elements fill the parental arrea
			If _screenRect.GetW() = -1 Then _screenRect.SetW( pScreenRect.GetW() )
			If _screenRect.GetH() = -1 Then _screenRect.SetH( pScreenRect.GetH() )

			If _screenRect.LimitToRect(pScreenRect)
				SetStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID, False)
			EndIf
		EndIf

		Return True
	End Method


	Method InvalidateScreenRect:TRectangle()
		SetStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID, False)

		If _children
			For Local c:TGUIObject = EachIn _children
				c.InvalidateScreenRect()
			Next
		EndIf

		'also invalidate rectangle of the content area
		InvalidateContentScreenRect()
	End Method


	Method GetScreenRect:TRectangle()
		If Not isDragged() And _parent And Not _parent.HasStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID) Then SetStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID, False)
		If Not HasStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID) Then UpdateScreenRect()

		Return _screenRect
	End Method


	'get a rectangle describing the objects area on the screen
	Method UpdateScreenRect:TRectangle()
		If HasStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID) Then Return _screenRect

		Local oldX:Float = _screenRect.position.x
		Local oldY:Float = _screenRect.position.y
		Local oldW:Float = _screenRect.dimension.x
		Local oldH:Float = _screenRect.dimension.y

		_UpdateScreenX()
		_UpdateScreenY()
		_UpdateScreenW()
		_UpdateScreenH()
		'we should only limit during rendering, not during "calculation
		'_LimitScreenRect()

		If Not _screenRect.EqualsXYWH(oldX, oldY, oldW, oldH)
			OnUpdateScreenRect()
		EndIf

		If Not (_flags & GUI_OBJECT_DRAGGED)
			SetStatus(GUI_OBJECT_STATUS_SCREENRECT_VALID, True)
		EndIf
		Return _screenRect
	End Method


	'override this methods if the object something like
	'virtual size or "addtional padding"
	'at which x-coordinate content/children is located within the parent
	Method GetContentX:Float()
		Return GetPadding().GetLeft()
	End Method


	'at which y-coordinate content/children located within the parent
	Method GetContentY:Float()
		Return GetPadding().GetTop()
	End Method


	'available width for content/children
	Method GetContentWidth:Float()
		Return GetWidth() - (GetPadding().GetLeft() + GetPadding().GetRight())
	End Method


	'available height for content/children
	Method GetContentHeight:Float(width:Int)
		Return GetHeight() - (GetPadding().GetTop() + GetPadding().GetBottom())
	End Method


	'Updates and returns the x pos for content/children on the screen
	Method _UpdateContentScreenX:Float()
		_contentScreenRect.SetX( GetScreenRect().GetX() + GetContentX() )
		Return _contentScreenRect.GetX()
	End Method


	'Updates and returns the y pos for content/children on the screen
	Method _UpdateContentScreenY:Float()
		_contentScreenRect.SetY( GetScreenRect().GetY() + GetContentY() )
		Return _contentScreenRect.GetY()
	End Method


	'Updates and returns the width for content/children on the screen
	Method _UpdateContentScreenW:Float()
		_contentScreenRect.SetW( _screenRect.GetW() - (GetPadding().GetLeft() + GetPadding().GetRight()) )
		Return _contentScreenRect.GetW()
	End Method


	'Updates and returns the height for content/children on the screen
	Method _UpdateContentScreenH:Float()
		_contentScreenRect.SetH( _screenRect.GetH() - (GetPadding().GetTop() + GetPadding().GetBottom()) )
		Return _contentScreenRect.GetH()
	End Method


	'correct the current content screenrect to limits
	'like parent's content screen rects.
	Method _LimitContentScreenRect:Float()
		'do not go beyond the content area of the parent
		If _parent
			Local pScreenRect:TRectangle
			If Not(_flags & GUI_OBJECT_IGNORE_PARENTPADDING)
				pScreenRect = _parent.GetContentScreenRect()
			Else
				pScreenRect = _parent.GetScreenRect()
			EndIf

			If Not (_flags & GUI_OBJECT_IGNORE_PARENTLIMITS) And _contentScreenRect.LimitToRect(pScreenRect)
				SetStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID, False)
			EndIf
		EndIf

		Return True
	End Method


	Method InvalidateContentScreenRect()
		If Not HasStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID) Then Return

		SetStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID, False)

		If _children
			For Local c:TGUIObject = EachIn _children
				c.InvalidateContentScreenRect()
			Next
		EndIf
	End Method


	Method GetContentScreenRect:TRectangle()
		If Not isDragged() And _parent And Not _parent.HasStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID) Then SetStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID, False)
		If Not HasStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID) Then UpdateContentScreenRect()

		Return _contentScreenRect
	End Method


	'update the rectangle describing the children's area on the screen
	Method UpdateContentScreenRect:TRectangle()
		If HasStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID) Then Return _contentScreenRect

		_UpdateContentScreenX()
		_UpdateContentScreenY()
		_UpdateContentScreenW()
		_UpdateContentScreenH()
		'might not be needed as screenRect is already limited
		'but maybe some odd constellation requires the content to
		'have a different limit ...
	'	_LimitContentScreenRect()

		SetStatus(GUI_OBJECT_STATUS_CONTENTSCREENRECT_VALID, True)
		Return _contentScreenRect
	End Method


	'Returns the local x coordinate
	Method GetX:Int()
		Return rect.GetX()
	End Method


	'Returns the local y coordinate
	Method GetY:Int()
		Return rect.GetY()
	End Method


	'Returns the local width
	Method GetWidth:Int()
		Return rect.GetW()
	End Method


	'Returns the local height
	Method GetHeight:Int()
		Return rect.GetH()
	End Method


	Method GetRect:TRectangle()
		Return rect
	End Method


	Method GetDimension:TVec2D()
		Return rect.dimension
	End Method



	Method SetHandle:Int(handle:TVec2D)
		Self.handle = handle
	End Method


	Method GetHandle:TVec2D()
		Return handle
	End Method


	'returns whether a given coordinate is within the objects bounds
	'by default it just checks a simple rectangular bound
	Method ContainsXY:Int(x:Float,y:Float)
		'if not dragged ask parent first
		If Not isDragged() And _parent And Not _parent.containsXY(x,y) Then Return False
		Return GetScreenRect().containsXY(x,y)
	End Method


	'reposition/resize/... all components of the widget
	'(eg custom buttons, panels, ...
	Method UpdateLayout() Abstract


	Method InvalidateLayout()
		SetStatus(GUI_OBJECT_STATUS_LAYOUT_VALID, False)
	End Method


	'internally called method to the abstract UpdateLayout()
	Method _UpdateLayout()
		If HasStatus(GUI_OBJECT_STATUS_LAYOUT_VALID) Then Return

		UpdateLayout()

		SetStatus(GUI_OBJECT_STATUS_LAYOUT_VALID, True)
	End Method


	Method Draw()
		_UpdateLayout()

		If Not IsVisible() Then Return

		Local oldCol:TColor = New TColor.Get()
		'tint image if object is disabled
		If Not(_flags & GUI_OBJECT_ENABLED) Then SetAlpha 0.5 * oldCol.a

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

			If _customDrawChildren
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

		If Not(_flags & GUI_OBJECT_ENABLED) Then SetAlpha oldCol.a

		'=== HANDLE TOOLTIP ===
		If Not _customDraw
			DrawTooltips()
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
'			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 0.5*GetAlpha()
			obj.draw()
			'tint image if object is disabled
'			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 2.0*GetAlpha()

			'fire event
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onDraw", Null, obj ) )
		Next
	End Method


	Method DrawTooltips:Int()
		'skip children if self not visible
		If Not IsVisible() Then Return False

		If _children
			'draw children
			For Local obj:TGUIobject = EachIn _children
				obj.DrawTooltips()
			Next
		EndIf

		If _tooltip And Not hasOption(GUI_OBJECT_MANAGED) And Not hasOption(GUI_OBJECT_DRAGGED) And hasOption(GUI_OBJECT_TOOLTIP_MANAGED)
			_tooltip.Render()
		EndIf
	End Method


	Method Update:Int()
		_UpdateLayout()
		If IsDragged() Then InvalidateScreenRect()

		'if appearance changed since last update tick: inform widget
		'Attention: this is also called via GUIManager.Update()/Draw()
		'           but we just do it here too, in case you manually update
		'           the widget (important: this does not resolve the issue
		'           if child elements have changed appearance too)
		If isAppearanceChanged()
			onAppearanceChanged()
			SetAppearanceChanged(False)
		EndIf


		'skip handling disabled entries
		'(eg. deactivated scrollbars which else would "hover" before
		' list items on the same spot)
		If Not IsEnabled() Then Return False

		'do not handle invisible elements
		If Not IsVisible() Then Return False


		'to recognize clicks/hovers/actions on child elements:
		'ask them first!
		UpdateChildren()



		If GUIManager._ignoreMouse Then Return False


		'=== HANDLE MOUSE ===
		If Not GUIManager.UpdateState_mouseButtonDown[1]
			mouseIsDown	= Null
			'remove hover/active state
'			SetHovered(False)
			SetActive(False)
		EndIf

		'mouse position could have changed since a begin of a "click"
		'-> eg when clicking + moving the cursor very fast
		'   in that case the mouse position should be the one of the
		'   moment the "click" begun
		Local mousePos:TVec2D
		If MouseManager.IsClicked(1)
			mousePos = MouseManager.GetClickPosition(1)
		EndIf
		If Not mousePos Then mousePos = MouseManager.currentPos

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
				SetActive(False)
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
		If Not containsMouse And Not isDragged()
			'do not return - we need to check tooltips later on
			'Return False
		Else

			'handle mouse clicks / button releases / hover state
			'only do something if
			'a) there is NO dragged object
			'b) we handle the dragged object
			'-> only react to dragged obj or all if none is dragged

			If Not GUIManager.GetDraggedCount() Or isDragged()

				If IsClickable()
					'activate objects - or skip if if one gets active
					'as soon as someone clicks on a object it is getting focused
					'	do this "on click" instead of "on mouse down"
					'	as else a drop down widget which covers another widget
					'	with its listbox will handle the "losr focus" event
					'	and after closing the underlaying widget receives the
					'	click event
					IF _flags & GUI_OBJECT_ENABLED and MouseManager.IsClicked(1)
						If HasOption(GUI_OBJECT_CAN_GAIN_FOCUS)
							GUImanager.SetFocus(Self)
						EndIf
					EndIf

					If GUIManager.UpdateState_mouseButtonDown[1] And _flags & GUI_OBJECT_ENABLED
						'create a new "event"
						If Not MouseIsDown
							'store a copy (might be the currentPos instance of MouseManager)
							MouseIsDown = mousePos.Copy()
						EndIf

						'we found a gui element which can accept clicks
						'dont check further guiobjects for mousedown
						'as this also removes "down" state
						GUIManager.UpdateState_mouseButtonDown[1] = False
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
						SetActive(True)
						EventManager.triggerEvent( TEventSimple.Create("guiobject.OnMouseDown", New TData.AddNumber("button", 1), Self ) )
					Else
						SetHovered(True)
					EndIf

					If IsClickable()
						'inform others about a right guiobject click
						'we do use a "cached hit state" so we can reset it if
						'we found a one handling it
						If (MouseManager.IsClicked(2) Or MouseManager.IsLongClicked(1)) And Not GUIManager.UpdateState_foundClickedObject[2]
							Local clickEvent:TEventSimple = TEventSimple.Create("guiobject.OnClick", New TData.AddNumber("button",2).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
							Local handledClick:Int

							handledClick = OnClick(clickEvent)
							'fire onClickEvent
							EventManager.triggerEvent(clickEvent)
'TODO: add veto
							'if not handledClick and not clickEvent.IsVeto() then handledClick = True

							'maybe change to "isAccepted" - but then each gui object
							'have to modify the event IF they accepted the click

							'reset Button
							If handledClick
								If MouseManager.IsLongClicked(1)
									MouseManager.SetLongClickHandled(1)
								Else
									MouseManager.SetClickHandled(2)
								EndIf
							EndIf

							'found clicked even if not handled?
							GUIManager.UpdateState_foundClickedObject[2] = Self
						EndIf


						'IsClicked does include waiting time
						If Not GUIManager.UpdateState_foundClickedObject[1]
							Local isClicked:Int = False

							If MouseManager.IsClicked(1)
								Local clickEvent:TEvenTsimple = TEventSimple.Create("guiobject.OnClick", New TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
								Local handledClick:Int

								'let the object handle the click
								handledClick = OnClick(clickEvent)
								'fire onClickEvent
								EventManager.triggerEvent(clickEvent)
								If Not handledClick And Not clickEvent.IsVeto() Then handledClick = True

								isClicked = True

								mouseIsClicked = MouseManager.GetClickposition(1)

								'handled that click
								If handledClick
									MOUSEMANAGER.SetClickHandled(1)
								EndIf

								GUIManager.UpdateState_foundClickedObject[1] = Self
							EndIf


							If MouseManager.IsDoubleClicked(1)
								Local clickEvent:TEventSimple = TEventSimple.Create("guiobject.OnDoubleClick", New TData.AddNumber("button",1).Add("coord", New TVec2D.Init(MouseManager.x, MouseManager.y)), Self)
								'let the object handle the click
								OnDoubleClick(clickEvent)

								'handled that click
								MouseManager.SetDoubleClickHandled(1)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf


		'=== HANDLE TOOLTIP ===
		If _tooltip And Not hasOption(GUI_OBJECT_MANAGED) And Not hasOption(GUI_OBJECT_DRAGGED)
			'update hovered state
			_tooltip.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED, IsHovered())
			'change position if required

			_tooltip.Update()
		EndIf
	End Method


	Global defaultTextCol:TColor = TColor.Create(100,100,100)
	Global defaultHoverTextCol:TColor = TColor.Create(50,50,50)
	Global defaultDisabledTextCol:TColor = TColor.Create(150,150,150)

	Method DrawBaseFormText:Int(_value:String, x:Float, y:Float)
		Local col:TColor = defaultTextCol
		If isHovered() Then col = defaultHoverTextCol
		If Not(_flags & GUI_OBJECT_ENABLED) Then col = defaultDisabledTextCol

		GetFont().drawStyled(_value,x,y, col, 1, 1, 0.5)
		Return True
	End Method


	'returns true if the conversion was successful
	Function ConvertKeystrokesToText:Int(value:String Var, valuePosition:Int Var, ignoreEnterKey:Int = False)
		If valuePosition = -1
			valuePosition = value.length
		Else
			valuePosition = Min(valuePosition, value.length)
		EndIf

		Local specialCommandKeys:Int[] = [KEY_BACKSPACE, KEY_DELETE, 127, KEY_HOME, KEY_END, KEY_LEFT, KEY_RIGHT, KEY_ESCAPE]

		'=== SPECIAL COMMAND KEYS ===
		Local handledSpecialCommandKeys:Int = False
		For Local key:Int = EachIn specialCommandKeys
			If Not KEYWRAPPER.pressedKey(key) Then Continue

			Select key
				Case KEY_BACKSPACE
					If valuePosition > 0
						value = value[.. valuePosition-1] + value[valuePosition ..]
						valuePosition :- 1
					EndIf

				'on my linux box "127" is the delete-key and not KEY_DELETE (46)
				Case KEY_DELETE, 127
					If valuePosition < value.length
						value = value[.. valuePosition] + value[valuePosition+1 ..]
					EndIf

				Case KEY_END
					valuePosition = value.length

				Case KEY_HOME
					valuePosition = 0

				Case KEY_LEFT
					Local ctrlPressed:Int = KEYMANAGER.IsDown(KEY_LCONTROL) Or KEYMANAGER.IsDown(KEY_RCONTROL)
					Local stoppers:Int[] = [KEY_SPACE, KEY_PERIOD, KEY_COMMA, KEY_SEMICOLON, KEY_OPENBRACKET, KEY_CLOSEBRACKET]

					If ctrlPressed
						For Local i:Int = valuePosition-1 To 0 Step -1
							If MathHelper.InIntArray(value[i], stoppers)
								valuePosition = Max(0, i)
								Exit
							EndIf
						Next
					Else
						'stop at the 0 position
						valuePosition = Max(0, valuePosition - 1)
						'wrap around and continue at end of the text
						'valuePosition :- 1
					EndIf

				Case KEY_RIGHT
					Local ctrlPressed:Int = KEYMANAGER.IsDown(KEY_LCONTROL) Or KEYMANAGER.IsDown(KEY_RCONTROL)
					Local stoppers:Int[] = [KEY_SPACE, KEY_PERIOD, KEY_COMMA, KEY_SEMICOLON, KEY_OPENBRACKET, KEY_CLOSEBRACKET]

					If ctrlPressed
						'ignore next char (will be a stopper...)
						For Local i:Int = valuePosition+1 To value.length-1
							If MathHelper.InIntArray(value[i], stoppers)
								valuePosition = i+1
								Exit
							EndIf
						Next
					Else
						valuePosition = Min(value.length, valuePosition +1)
					EndIf

				'abort with ESCAPE
				Case KEY_ESCAPE
					Return False
			End Select

			handledSpecialCommandKeys = True
		Next
		If handledSpecialCommandKeys Then Return True



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
		While charCode <> 0
			'ignore special keys
			If MathHelper.InIntArray(charCode, specialCommandKeys)
				charCode = Int(GetChar())
				Continue
			EndIf
			'charCode is < 0 for me when umlauts are pressed
			If charCode < 0
				?Win32
				If KEYWRAPPER.pressedKey(186)
					If shiftPressed Then value:+ "Ü" Else value :+ "ü"
					valuePosition :+ 1
				EndIf
				If KEYWRAPPER.pressedKey(192)
					If shiftPressed Then value:+ "Ö" Else value :+ "ö"
					valuePosition :+ 1
				EndIf
				If KEYWRAPPER.pressedKey(222)
					If shiftPressed Then value:+ "Ä" Else value :+ "ä"
					valuePosition :+ 1
				EndIf
				?MacOS
				If KEYWRAPPER.pressedKey(186)
					If shiftPressed Then value:+ "Ü" Else value :+ "ü"
					valuePosition :+ 1
				EndIf
				If KEYWRAPPER.pressedKey(192)
					If shiftPressed Then value:+ "Ö" Else value :+ "ö"
					valuePosition :+ 1
				EndIf
				If KEYWRAPPER.pressedKey(222)
					If shiftPressed Then value:+ "Ä" Else value :+ "ä"
					valuePosition :+ 1
				EndIf
				?Linux
				If KEYWRAPPER.pressedKey(252)
					If shiftPressed Then value:+ "Ü" Else value :+ "ü"
					valuePosition :+ 1
				EndIf
				If KEYWRAPPER.pressedKey(246)
					If shiftPressed Then value:+ "Ö" Else value :+ "ö"
					valuePosition :+ 1
				EndIf
				If KEYWRAPPER.pressedKey(163)
					If shiftPressed Then value:+ "Ä" Else value :+ "ä"
					valuePosition :+ 1
				EndIf
				?
				If charCode = -33
					value:+ "ß"
					valuePosition :+ 1
				EndIf
			'handle normal "keys" (excluding umlauts)
			ElseIf charCode > 0
				'skip enter if whished so
				If ignoreEnterKey And KEY_ENTER = charCode
					'addChar = False
				Else
					value = value[.. valuePosition] + Chr(charCode) + value[valuePosition ..]
					valuePosition :+ 1
				EndIf

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


	'object realigned some components / inner stuff
	Method OnUpdateLayout()
	End Method


	'object was resized in width and/or height
	Method OnResize()
		InvalidateScreenRect()
	End Method


	'object gains focus
	'private function, NOT the event listener
	Method _OnSetFocus:Int()
		Return True
	End Method


	'object looses focus
	'private function, NOT the event listener
	Method _OnRemoveFocus:Int()
		Return True
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


	Method OnChildAppearanceChanged(child:TGUIObject, bool:Int)
		Return
	End Method


	Method OnParentAppearanceChanged(bool:Int)
		Return
	End Method


	Method OnChangePadding:Int()
		InvalidateContentScreenRect()
		InvalidateLayout()
	End Method


	Method onAddAsChild:Int(parent:TGUIObject)
		InvalidateScreenRect()
	End Method


	Method onRemoveAsChild:Int(parent:TGUIObject)
		InvalidateScreenRect()
	End Method


	'called when appearance changes - override in widgets to react
	'to it
	'do not call this directly, this is handled at the end of
	'each "update" call so multiple things can set "appearanceChanged"
	'but this function is called only "once"
	Method onAppearanceChanged:Int()
		InvalidateScreenRect()
	End Method


	Method onSelect:Int()
		EventManager.triggerEvent( TEventSimple.Create( "GUIObject.onSelect", Null, Self ) )
	End Method


	Method onDeselect:Int()
		EventManager.triggerEvent( TEventSimple.Create( "GUIObject.onDeselect", Null, Self ) )
	End Method


	Method OnParentResize:Int()
		InvalidateScreenRect()
		Return False
	End Method


	Method OnUpdateScreenRect()
		If _children
			For Local obj:TGUIobject = EachIn _children
				obj.InvalidateScreenRect()
			Next
		EndIf
	End Method


	Method OnUpdateContentScreenRect()
		If _children
			For Local obj:TGUIobject = EachIn _children
				obj.InvalidateContentScreenRect()
			Next
		EndIf
	End Method


	Method OnReposition(dx:Float, dy:Float)
		If dx = 0 And dy = 0 Then Return

		InvalidateScreenRect()

		If _children
			For Local obj:TGUIobject = EachIn _children
				obj.OnParentReposition(Self, dx,dy)
			Next
		EndIf
	End Method


	Method OnChildZIndexChanged()
		SortChildren()
		If _parent Then _parent.OnChildZIndexChanged()
	End Method


	Method OnParentReposition(parent:TGUIObject, dx:Float, dy:Float)
		If dx = 0 And dy = 0 Then Return
		'ignore parent if not interested
		If Not (parent Or _parent) Or (_flags & GUI_OBJECT_POSITIONABSOLUTE) Then Return

		InvalidateScreenRect()
	End Method

End Type




'simple gui object helper - so non-gui-objects may receive events...
Type TGUISimpleRect Extends TGUIobject


	Method GetClassName:String()
		Return "tguisimplerect"
	End Method


	Method Create:TGUISimpleRect(position:TVec2D, dimension:TVec2D, limitState:String="")
		Super.CreateBase(position, dimension, limitState)
		Self.SetSize(dimension.GetX(), dimension.GetY() )

    	GUIManager.Add( Self )
		Return Self
	End Method


	Method DrawContent()
		'
	End Method


	Method DrawDebug()
		SetAlpha 0.5
		DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
		SetAlpha 1.0
	End Method


	Method UpdateLayout()
	End Method
End Type



Type TGUITooltipBase Extends TTooltipBase
	Field bgSpriteName:String = "gfx_gui_tooltip.bg"
	Field _bgSprite:TSprite
	'caches calculated content padding (max of default padding and bgSprite-padding)
	Field _effectiveContentPadding:TRectangle
	Field _arrowType:Int = ARROW_DOWN

	Global _defaultOffset:TVec2D = New TVec2D.Init(0, 3)
	Const ARROW_NONE:Int = 0
	Const ARROW_LEFT:Int = 1
	Const ARROW_RIGHT:Int = 2
	Const ARROW_UP:Int = 3
	Const ARROW_DOWN:Int = 4


	Method Initialize:TGUITooltipBase(title:String="", content:String="unknown", area:TRectangle)
		Super.Initialize(title, content, area)
		offset = _defaultOffset.Copy()
		Return Self
	End Method


	'override
	Method GetContentPadding:TRectangle()
		If Not _effectiveContentPadding
			Local contentPadding:TRectangle = Super.GetContentPadding()
			Local bgSpritePadding:TRectangle = GetBGSprite().GetNinePatchContentBorder()
			_effectiveContentPadding = New TRectangle
			_effectiveContentPadding.SetLeft( Max( contentPadding.GetLeft(), bgSpritePadding.GetLeft()) )
			_effectiveContentPadding.SetRight( Max( contentPadding.GetRight(), bgSpritePadding.GetRight()) )
			_effectiveContentPadding.SetTop( Max( contentPadding.GetTop(), bgSpritePadding.GetTop()) )
			_effectiveContentPadding.SetBottom( Max( contentPadding.GetBottom(), bgSpritePadding.GetBottom()) )
		EndIf
		Return _effectiveContentPadding
	End Method


	'override to set arrow too
	Method SetOrientationPreset(direction:String="TOP", distance:Int = 0)
		Super.SetOrientationPreset(direction, distance)

		Select direction.ToUpper()
			Case "LEFT"
				_arrowType = ARROW_RIGHT
			Case "RIGHT"
				_arrowType = ARROW_LEFT
			Case "BOTTOM"
				_arrowType = ARROW_UP
			Default
				_arrowType = ARROW_DOWN
		End Select
	End Method


	'acts as cache
	Method GetBGSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		If Not _bgsprite Or _bgsprite.GetName() <> bgSpriteName
			_bgSprite = GetSpriteFromRegistry(bgSpriteName)
			'new -non default- sprite: adjust appearance
			If _bgSprite.GetName() <> "defaultsprite"
				_effectiveContentPadding = Null
				'SetAppearanceChanged(TRUE)
			EndIf
		EndIf
		Return _bgSprite
	End Method


	'override to fetch background sprite - so it can calculate padding
	'correctly
	Method Update:Int()
		GetBGSprite()

		Super.Update()
	End Method


	'override: render a themed background
	Method _DrawBackground:Int(x:Int, y:Int, w:Int, h:Int)
		If _customDrawBackground Then Return _customDrawBackground(Self, x, y, w, h)

		GetBGSprite().DrawArea(x,y,w,h)
'		DrawRect(x,y,w,h)

		_DrawArrow(x,y,w,h)
	End Method


	Method _DrawArrow:Int(x:Int, y:Int, w:Int, h:Int)
		If _arrowType <> ARROW_NONE
			Local useArrowType:Int = _arrowType
			If HasOption(OPTION_MIRRORED_RENDER_POSITION_X)
				Select _arrowType
					Case ARROW_LEFT
						useArrowType = ARROW_RIGHT
					Case ARROW_RIGHT
						useArrowType = ARROW_LEFT
				End Select
			EndIf
			If HasOption(OPTION_MIRRORED_RENDER_POSITION_Y)
				Select _arrowType
					Case ARROW_UP
						useArrowType = ARROW_DOWN
					Case ARROW_DOWN
						useArrowType = ARROW_UP
				End Select
			EndIf

			'TODO: GetArrowSprite()-cache

			Select useArrowType
				Case ARROW_UP
					If parentArea
						Local scrX:Int = GetScreenRect().GetX()
						Local scrW:Int = GetScreenRect().GetW()
						If _effectiveContentPadding
							scrX :+ _effectiveContentPadding.GetLeft()
							scrW :- _effectiveContentPadding.GetLeft() - _effectiveContentPadding.GetRight()
						EndIf
						Local minX:Int = Max(scrX, parentArea.GetX())
						Local maxX:Int = Min(scrX + scrW, parentArea.GetX2())
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.up").Draw(Int(0.5 * (minx + maxX)), Int(GetScreenRect().GetY()), -1, ALIGN_CENTER_BOTTOM)
					Else
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.up").Draw(Int(GetScreenRect().GetX() + 0.5 * GetScreenRect().GetW()), Int(GetScreenRect().GetY()), -1, ALIGN_CENTER_BOTTOM)
					EndIf
				Case ARROW_DOWN
					If parentArea
						Local scrX:Int = GetScreenRect().GetX()
						Local scrW:Int = GetScreenRect().GetW()
						If _effectiveContentPadding
							scrX :+ _effectiveContentPadding.GetLeft()
							scrW :- _effectiveContentPadding.GetLeft() - _effectiveContentPadding.GetRight()
						EndIf
						Local minX:Int = Max(scrX, parentArea.GetX())
						Local maxX:Int = Min(scrX + scrW, parentArea.GetX2())
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.down").Draw(Int(0.5 * (minx + maxX)), Int(GetScreenRect().GetY() + GetScreenRect().GetH()), -1, ALIGN_CENTER_TOP)
					Else
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.down").Draw(Int(GetScreenRect().GetX() + 0.5 * GetScreenRect().GetW()), Int(GetScreenRect().GetY() + GetScreenRect().GetH()), -1, ALIGN_CENTER_TOP)
					EndIf
				Case ARROW_LEFT
					If parentArea
						Local scrY:Int = GetScreenRect().GetY()
						Local scrH:Int = GetScreenRect().GetH()
						If _effectiveContentPadding
							scrY :+ _effectiveContentPadding.GetTop()
							scrH :- _effectiveContentPadding.GetBottom() - _effectiveContentPadding.GetTop()
						EndIf
						Local minY:Int = Max(scrY, parentArea.GetY())
						Local maxY:Int = Min(scrY + scrH, parentArea.GetY2())
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.left").Draw(Int(GetScreenRect().GetX()), Int(0.5 * (minY + maxY)), -1, ALIGN_RIGHT_CENTER)
					Else
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.left").Draw(Int(GetScreenRect().GetX()), Int(GetScreenRect().GetY() + 0.5 * GetScreenRect().GetH()), -1, ALIGN_RIGHT_CENTER)
					EndIf
				Case ARROW_RIGHT
					If parentArea
						Local scrY:Int = GetScreenRect().GetY()
						Local scrH:Int = GetScreenRect().GetH()
						If _effectiveContentPadding
							scrY :+ _effectiveContentPadding.GetTop()
							scrH :- _effectiveContentPadding.GetBottom() - _effectiveContentPadding.GetTop()
						EndIf
						Local minY:Int = Max(scrY, parentArea.GetY())
						Local maxY:Int = Min(scrY + scrH, parentArea.GetY2())
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.right").Draw(Int(GetScreenRect().GetX() + GetScreenRect().GetW()), Int(0.5 * (minY + maxY)), -1, ALIGN_LEFT_CENTER)
					Else
						GetSpriteFromRegistry("gfx_gui_tooltip.arrow.right").Draw(Int(GetScreenRect().GetX() + GetScreenRect().GetW()), Int(GetScreenRect().GetY() + 0.5 * GetScreenRect().GetH()), -1, ALIGN_LEFT_CENTER)
					EndIf
			End Select
		EndIf
	End Method
End Type