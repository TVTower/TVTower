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
Import "base.util.clipboard.bmx"
Import "base.gfx.tooltip.base.bmx"
Import "base.gfx.gui.eventkeys.bmx"

Import "base.util.registry.spriteloader.bmx"

Import "base.gfx.renderconfig.bmx"




'===== GUI CONSTANTS =====
Const GUI_OBJECT_DRAGGED:Int                    = 2^0
Const GUI_OBJECT_VISIBLE:Int                    = 2^1
Const GUI_OBJECT_ENABLED:Int                    = 2^2
Const GUI_OBJECT_CLICKABLE:Int                  = 2^3
Const GUI_OBJECT_DRAGABLE:Int                   = 2^4
Const GUI_OBJECT_MANAGED:Int                    = 2^5
Const GUI_OBJECT_POSITIONABSOLUTE:Int           = 2^6
Const GUI_OBJECT_IGNORE_POSITIONMODIFIERS:Int   = 2^7
Const GUI_OBJECT_IGNORE_PARENTPADDING:Int       = 2^8
Const GUI_OBJECT_IGNORE_PARENTLIMITS:Int        = 2^9
Const GUI_OBJECT_ACCEPTS_DROP:Int               = 2^10
Const GUI_OBJECT_CAN_RECEIVE_KEYBOARDINPUT:Int  = 2^11
Const GUI_OBJECT_CAN_RECEIVE_MOUSEINPUT:Int     = 2^12
Const GUI_OBJECT_CAN_GAIN_FOCUS:Int             = 2^13
Const GUI_OBJECT_CAN_GAIN_ACTIVE:Int            = 2^14
Const GUI_OBJECT_DRAWMODE_GHOST:Int             = 2^15
'defines what GetFont() tries to get at first: parents or types font
Const GUI_OBJECT_FONT_PREFER_PARENT_TO_TYPE:Int = 2^16
'defines if changes to children change gui order (zindex on "panels")
Const GUI_OBJECT_CHILDREN_CHANGE_GUIORDER:Int	= 2^17
'defines whether children are updated automatically or not
Const GUI_OBJECT_STATIC_CHILDREN:Int            = 2^18
'does the gui object manage assigned tooltips?
Const GUI_OBJECT_TOOLTIP_MANAGED:Int            = 2^19
'dropdowns, guiinputs ... do not loose active state after clicking, buttons do.
Const GUI_OBJECT_STAY_ACTIVE_AFTER_MOUSECLICK:Int               = 2^20
'enabling this allows to move the mouse outside while still pressing the button
'and so eg to scroll without having to hit the scroller area once one did.
Const GUI_OBJECT_KEEP_ACTIVE_ON_OUTSIDE_CONTINUED_MOUSEDOWN:Int = 2^21

'===== GUI STATUS CONSTANTS =====
Const GUI_OBJECT_STATUS_HOVERED:Int	= 2^0			'mouse over
Const GUI_OBJECT_STATUS_SELECTED:Int = 2^1
Const GUI_OBJECT_STATUS_APPEARANCE_CHANGED:Int	= 2^2
Const GUI_OBJECT_STATUS_CONTENT_CHANGED:Int	= 2^3
Const GUI_OBJECT_STATUS_ACTIVE:Int = 2^4			'eg. accepting input (keyboard)
Const GUI_OBJECT_STATUS_FOCUSED:Int = 2^5			'activated
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

Global GUI_DIM_AUTOSIZE:SVec2I = new SVec2I(-1, -1)



Type TGUIManager
	Field globalScale:Float	= 1.0
	'which state are we currently handling?
	Field currentState:TLowerString = Null
	'config about specific gui settings (eg. panelGap)
	Field config:TData = New TData
	Field List:TObjectList = New TObjectList
	'contains dragged objects (above normal)
	Field ListDragged:TObjectList = New TObjectList
	'contains objects which need to get informed because of changed appearance
	Field elementsWithChangedAppearance:TObjectList = New TObjectList
	Field activeTooltips:TObjectList = New TObjectList
	
	'the widget set focused when a mouse button was held down
	'this only resets once the mouse button is released
	'use this to keep track of the "initially hit widget"
	Field initialMouseHitObject:TGUIObject[]
	
	Field _listsSorted:Int = False


	'=== UPDATE STATE PROPERTIES ===

	Field UpdateState_mouseButtonDown:Int[]
	Field UpdateState_mouseScrollwheelMovement:Int = 0
	Field UpdateState_foundClickedObject:TGUIObject = Null
	Field UpdateState_foundHoveredObject:TGUIObject = Null
	Field UpdateState_foundFocusedObject:TGUIObject = Null
	Field UpdateState_foundActiveObject:TGUIObject = Null

	Field UpdateState_foundInputReceiverObject:TGUIObject = Null
	
	'=== PRIVATE PROPERTIES ===

	Field _defaultfont:TBitmapFont
	Field _ignoreMouse:Int = False
	Field _activeObject:TGUIObject
	Field _focusedObject:TGUIObject
	'is there an object listening to keystrokes?
	Field _keyboardInputReceiver:TGUIObject = Null
	'is there an object receiving mouse interaction?
	Field _mouseInputReceiver:TGUIObject = Null

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


		'gui specific settings
		config.AddNumber("panelGap",10)

		initialMouseHitObject = New TGUIObject[ MouseManager.GetButtonCount() +1]
		UpdateState_mouseButtonDown = New Int[ MouseManager.GetButtonCount() +1]

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
		For Local i:int = 0 until ListDragged.Count()
			If ListDragged.data[i] = obj Then Return i
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


	Method RestrictViewport(x:Int,y:Int,w:Int,h:Int)
		TRenderConfig.Backup()
		If w > 0 And h > 0
			GetGraphicsManager().SetViewport(x,y,w,h)
		EndIf
	End Method


	Method ResetViewport()
		TRenderConfig.Restore()
	End Method


	Method Add:Int(obj:TGUIobject, skipCheck:Int=False)
		obj.setOption(GUI_OBJECT_MANAGED, True)

		If Not skipCheck And list.contains(obj) Then Return True

		List.AddLast(obj)
		
		'mark unsorted/dirty
		_listsSorted = False
	End Method


	Function SortObjects:Int(ob1:Object, ob2:Object)
		Local objA:TGUIobject = TGUIobject(ob1)
		Local objB:TGUIobject = TGUIobject(ob2)

		'-1 = bottom
		' 1 = top

		'undefined object 1 - "a<b"
		If Not objA Then Return -1
		'undefined object 2 - "a>b"
		If Not objB Then Return 1

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
		'If objA.IsFocused() Then Return 1
		'if objB is active element - move to top
		'If objB.IsFocused() Then Return -1

		'if objA is "higher", move it to the top
		If objA.GetZIndex() > objB.GetZIndex() Then Return 1
		'if objA is "lower"", move to bottom
		If objA.GetZIndex() < objB.GetZIndex() Then Return -1

		'if one of them is active - prefer it
		If objA._status & GUI_OBJECT_STATUS_ACTIVE Then Return 1
		If objB._status & GUI_OBJECT_STATUS_ACTIVE Then Return -1


		'run custom compare job
		Return objA.compare(objB)
		'Return 0
	End Function


	Method SortLists()
		List.sort(True, SortObjects)
		
		_listsSorted = True
	End Method


	'only remove from lists (object cleanup has to get called separately)
	Method Remove:Int(obj:TGUIObject)
		If Not obj Then Return False

		obj.setOption(GUI_OBJECT_MANAGED, False)

		List.remove(obj)

		RemoveDragged(obj)
		
		'unset focus if the item was focused (also remove keystroke 
		'receiver etc)
		if GetFocus() = obj Then ResetFocus()

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
		If Not (obj._flags & GUI_OBJECT_VISIBLE) Then Return False

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
	Method GetObjectsByPos:TGuiObject[](coord:SVec2I, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
		Return GetObjectsByPos(coord.x, coord.y, limitState, ignoreDragged, requiredFlags, limit)
	End Method


	'returns an array of objects at the given x,y coordinate
	Method GetObjectsByPos:TGuiObject[](x:Int, y:Int, limitState:TLowerString=Null, ignoreDragged:Int=True, requiredFlags:Int=0, limit:Int=0)
	'	If limitState=Null Then limitState = currentState

		Local guiObjects:TGuiObject[]
		'from TOP to BOTTOM (user clicks to visible things - which are at the top)
		For Local i:Int = list.Count()-1 to 0 step -1
			Local obj:TGUIObject = TGUIObject(list.data[i])

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


	Method GetKeyboardInputReceiver:TGUIobject()
		Return _keyboardInputReceiver
	End Method


	Method SetKeyboardInputReceiver:Int(obj:TGUIObject)
		If obj And obj.hasOption(GUI_OBJECT_CAN_RECEIVE_KEYBOARDINPUT)
			_keyboardInputReceiver = obj
		Else
			'just reset the old one
			_keyboardInputReceiver = Null
		EndIf
	End Method


	Method GetMouseInputReceiver:TGUIobject()
		Return _mouseInputReceiver
	End Method


	Method SetMouseInputReceiver:Int(obj:TGUIObject)
		If obj And obj.hasOption(GUI_OBJECT_CAN_RECEIVE_MOUSEINPUT)
			_mouseInputReceiver = obj
		Else
			'just reset the old one
			_mouseInputReceiver = Null
		EndIf
	End Method


	'sets the currently active object
	Method SetActive(obj:TGUIObject)
		'ignore if object is already focused
		if obj = _activeObject Then Return
		
		'if there was an active object -> inform about loss of active state
		If (obj <> _activeObject) And _activeObject
			'sender = previous focused object
			'receiver = newly focused object
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnRemoveActive, Null , _activeObject, obj)
			_activeObject._SetActive(False, obj)
		EndIf

		'inform about a new object getting activated
		'sender = newly activated object
		'receiver = previous activate object
		If obj
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnSetActive, Null , obj, _activeObject)
			obj._SetActive(True, _activeObject)
		EndIf

		'set new active object
		_activeObject = obj

		'if there is a active object now - inform about gain of the state
'		If _activeObject
			UpdateState_foundActiveObject = _activeObject
'		EndIf

		'if the new active object cannot act as input receiver
		'the current receivers are unset nonetheless
		SetKeyboardInputReceiver(_activeObject)
		SetMouseInputReceiver(_activeObject)

		GuiManager._listsSorted = False
		'GuiManager.SortLists()
	End Method


	Method GetActive:TGUIObject()
		Return _activeObject
	End Method
	

	'sets the currently focused object
	Method SetFocus(obj:TGUIObject)
		'ignore if object is already focused
		if obj = _focusedObject Then Return
		
		'if there was an focused object -> inform about removal of focus
		If (obj <> _focusedObject) And _focusedObject
			'sender = previous focused object
			'receiver = newly focused object
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnRemoveFocus, Null , _focusedObject, obj)
			_focusedObject._SetFocused(False)
		EndIf

		'inform about a new object getting focused
		'sender = newly focused object
		'receiver = previous focused object
		If obj
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnSetFocus, Null , obj, _focusedObject)
			obj._SetFocused(True)
		EndIf

		'set new focused object
		_focusedObject = obj

		'if there is a focused object now - inform about gain of focus
		If _focusedObject
			UpdateState_foundFocusedObject = _focusedObject
		EndIf

		'if the new focus object cannot act as keystroke receiver
		'the current receiver is unset nonetheless
		SetKeyboardInputReceiver(_focusedObject)

		GuiManager._listsSorted = False
		'GuiManager.SortLists()
	End Method


	Method GetFocus:TGUIObject()
		Return _focusedObject
	End Method


	Method ResetFocus:Int()
		'remove focus (eg. when switching gamestates
		SetFocus(Null)

		'also remove potential keystroke receivers
		SetKeyboardInputReceiver(Null)
		SetMouseInputReceiver(Null)
	End Method


	'should be run on start of the current tick
	Method StartUpdates:Int()

		UpdateState_mouseScrollwheelMovement = MouseManager.GetScrollwheelMovement()
		UpdateState_mouseButtonDown = MouseManager.GetAllIsDown()

		For local i:int = 1 To UpdateState_mouseButtonDown.length -1
			If not UpdateState_mouseButtonDown[i] Then GUIManager.initialMouseHitObject[i] = Null
		Next

		UpdateState_foundClickedObject = null
		UpdateState_foundFocusedObject = Null
		UpdateState_foundHoveredObject = Null
		UpdateState_foundActiveObject = Null
		UpdateState_foundInputReceiverObject = Null
	End Method


	'run after all other gui things so important values can get reset
	Method EndUpdates:Int()
		'if we had a click this cycle and an gui element is focused,
		'remove focus from it
		If MouseManager.isClicked(1)
			If Not UpdateState_foundFocusedObject And GUIManager.GetFocus()
				GUIManager.ResetFocus()
				'GUIManager.setFocus(Null)
			EndIf
'			If Not UpdateState_foundClickedObject And GUIManager.GetFocus()
'				GUIManager.ResetFocus()
				'GUIManager.setFocus(Null)
'			EndIf
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
				TriggerBaseEvent(GUIEventKeys.GUIObject_OnUpdate, Null, obj )
			Next
		EndIf

		'then the rest
		If GUIMANAGER_TYPES_NONDRAGGED & updateTypes
			if not _listsSorted Then SortLists()
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
				TriggerBaseEvent(GUIEventKeys.GUIObject_OnUpdate, Null, obj )
			Next
		EndIf
	End Method


	Method Draw:Int(State:TLowerString = Null, fromZ:Int=-1000, toZ:Int=-1000, drawTypes:Int=GUIMANAGER_TYPES_ALL)
		currentState = State

		'this needs to get run in Draw() and Update() as you might else
		'run into discrepancies (drawn without updates according to new
		'visuals)
		UpdateElementswithChangedAppearance()

		If Not _listsSorted Then SortLists()
		
		local draggedCount:Int = ListDragged.Count()
	
		If GUIMANAGER_TYPES_NONDRAGGED & drawTypes
			activeTooltips.Clear()
			For Local obj:TGUIobject = EachIn List
				'all special objects get drawn separately
				If draggedCount > 0 and ListDragged.contains(obj) Then Continue
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				'skip invisible objects
				If Not obj.IsVisible() Then Continue

				obj.Draw()

				If obj._tooltip And (obj._flags & GUI_OBJECT_ENABLED) And (obj._flags & GUI_OBJECT_TOOLTIP_MANAGED)  'and not obj.hasOption(GUI_OBJECT_MANAGED)
					activeTooltips.AddLast(obj._tooltip)
				EndIf

				'fire event
				TriggerBaseEvent(GUIEventKeys.GUIObject_OnDraw, Null, obj )
			Next

			'TODO: sort by lastActive state?
			If activeTooltips.count() > 0 
				For Local t:TTooltipBase = EachIn activeTooltips
					t.Render()
				Next
			EndIf
		EndIf


		If GUIMANAGER_TYPES_DRAGGED & drawTypes and draggedCount > 0
			'draw all dragged objects above normal objects...
			'from bottom to top
			For Local obj:TGUIobject = EachIn ListDragged.ReverseEnumerator()
				If Not haveToHandleObject(obj,State,fromZ,toZ) Then Continue

				obj.Draw()

				'fire event
				TriggerBaseEvent(GUIEventKeys.GUIObject_OnDraw, Null, obj )
			Next
		EndIf
	End Method
End Type
Global GUIManager:TGUIManager = TGUIManager.GetInstance()



Enum EGUIClickType
	Pointer
	Keyboard
	Virtual
End Enum



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
	Field contentAlignment:SVec2F = New SVec2F(0.5, 0.5)
	Field value:String = ""
	Field mouseIsClicked:TVec2D	= Null 'null = not clicked
	'displacement of object when dragged (null = centered)
	Field handle:TVec2D	= Null


	Field _tooltip:TTooltipBase = Null
	Field _children:TObjectList = Null
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
	Field _timeDragged:Long = 0
	Field _parent:TGUIobject = Null
	'only handle if this state is requested on guimanager.update / draw
	Field _limitToState:String = ""
	'an array containing registered event listeners
	Field _registeredEventListener:TEventListenerBase[]

	Field _acceptedDropFilter:object = Null

	'=== CALLBACKS ===
	'compared to events callbacks can be used for hardwired bindings
	'where the receiver KNOWS this specific instance
	Field _callbacks_onClick:Int(sender:TGUIObject, button:Int, x:Int, y:Int)[]

	'=== HOOKS ===
	'allow custom functions to get hooked in
	Field _customDraw:Int(obj:TGUIObject)
	Field _customDrawBackground:Int(obj:TGUIObject)
	Field _customDrawContent:Int(obj:TGUIObject)
	Field _customDrawChildren:Int(obj:TGUIObject)
	Field _customDrawOverlay:Int(obj:TGUIObject)


	Global defaultTextCol:SColor8 = new SColor8(100,100,100)
	Global defaultHoverTextCol:SColor8 = new SColor8(50,50,50)
	Global defaultDisabledTextCol:SColor8 = new SColor8(150,150,150)
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
		SetOption(GUI_OBJECT_CAN_GAIN_ACTIVE, True)
		SetOption(GUI_OBJECT_CAN_RECEIVE_MOUSEINPUT, True)
		SetOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER, True)
	End Method


	Method GetClassName:String() Abstract
'		Return "TGUIObject"
'	End Method


	Method CreateBase:TGUIobject(pos:SVec2I, dimension:SVec2I, limitState:String="")
		SetPosition(pos.x, pos.y)
		'resize widget, dimension of (-1,-1) is "auto dimension"
		SetSize(dimension.x, dimension.y)

		SetLimitToState(limitState)
	End Method


	'default compare (sort) just uses _id to have widgets
	'created after an other one, to be render on top of it
	Method Compare:Int( other:Object )
		If not TGUIObject(other) then Return 1
		Return _id - TGUIObject(other)._id
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
			'(the children inform the parent...)
			'(this else leads to eg. some skipped children)
			For Local child:TGUIObject = EachIn _children.copy()
				child.Remove()
			Next
			_children.Clear()
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
	Method HasParent:Int(parent:TGUIObject, depth:Int = 0)
		If Not _parent
			'object itself cannot be the parent
			'except requested "parent" is null
			If depth = 0
				if parent
					Return False
				else
					Return True
				EndIf
			Else
				Return self = parent
			EndIf
		EndIf
		If _parent = parent Then Return True
		Return _parent.HasParent(parent, depth + 1)
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
	End Method


	Method AddChild:Int(child:TGUIobject)
		'remove child from a prior parent to avoid multiple references
		If child._parent Then child._parent.RemoveChild(child)

		child.setParent( Self )
		If Not _children Then _children = New TObjectList

		_children.addLast(child)

		'remove from guimanager, we take care of it
		GUIManager.Remove(child)
		SortChildren()

		'maybe zindex changed now
		If hasOption(GUI_OBJECT_CHILDREN_CHANGE_GUIORDER)
			GuiManager._listsSorted = False
			'GuiManager.SortLists()
		EndIf

		'inform object
		child.onAddAsChild(Self)
	End Method


	'remove child from children list
	Method RemoveChild:Int(child:TGUIobject, giveBackToManager:Int=False)
		If Not _children Then Return False
		_children.Remove(child)

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
		For Local obj:TGUIobject = EachIn _children.ReverseEnumerator()
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
		if self.value <> value
			Self.value = value
			InvalidateScreenRect()
		EndIf
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


	Method _SetActive:Int(bool:Int, oldOrNewActive:TGUIObject = Null)
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
		ElseIf IsSelected()
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


	Method SetAcceptDrop:Int(accept:Object)
		Local tID:TTypeID
		If TTypeID(accept)
			tID = TTypeID(accept)
		ElseIf TGUIObject(accept)
			tID = TTypeID.ForObject(accept)
		Else
			tID = TTypeID.ForName(string(accept))
		EndIf
		if tID
			_acceptedDropFilter = tID
		else
			_acceptedDropFilter = accept
		endif
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
			If IsActive() Then GUIManager.SetActive(Null)
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
		Local oldW:Float = rect.w
		Local oldH:Float = rect.h

		If w > 0 And w <> rect.w
			rect.SetW(w)
			resized = True
		EndIf
		If h > 0 And h <> rect.h
			rect.SetH(h)
			resized = True
		EndIf

		If resized
			Local dW:Float = w - oldW
			Local dH:Float = h - oldH
			if (oldW = -1 and w <> -1) or (w = -1) Then dW = 0
			if (oldH = -1 and h <> -1) or (h = -1) Then dH = 0

			InvalidateContentScreenRect()
			InvalidateLayout()
			OnResize(dW, dH)
			UpdateLayout()
		EndIf
	End Method


	Method SetPosition(x:Float, y:Float)
		If Not rect.IsSamePosition(x,y)
			Local dx:Float = x - rect.x
			Local dy:Float = y - rect.y
			rect.SetXY(x, y)

			OnReposition(dx, dy)
		EndIf
	End Method


	Method SetPositionX(x:Float)
		If rect.x <> x
			Local dx:Float = x - rect.x
			rect.SetX(x)

			OnReposition(dx, 0)
		EndIf
	End Method


	Method SetPositionY(y:Float)
		If rect.y <> y
			Local dy:Float = y - rect.y
			rect.SetY(y)

			OnReposition(0, dy)
		EndIf
	End Method


	Method Move(dx:Float, dy:Float)
		If dx <> 0 Or dy <> 0
			rect.MoveXY(dx, dy)

			OnReposition(dx, dy)
		EndIf
	End Method


	Method SetScreenPosition(x:Float, y:Float)
		If Not GetScreenRect().IsSamePosition(x,y)
			Local dx:Float = x - _screenRect.x
			Local dy:Float = y - _screenRect.y
			rect.MoveXY(dx, dy)

			OnReposition(dx, dy)
		EndIf
	End Method


	'set the anchor of the gui objects content
	'valid values are 0-1.0 (percentage)
	Method SetContentAlignment(contentLeft:Float=0.0, contentTop:Float=0.0)
		contentAlignment = new SVec2F(contentLeft, contentTop)
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

			If hasOption(GUI_OBJECT_MANAGED) 
				GuiManager._listsSorted = False
				'GuiManager.SortLists()
			EndIf

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

		data.Add("dragPosition", New TVec2D( GetScreenRect().x, GetScreenRect().y ))
		data.Add("dragState", GUIManager.currentState )

		Local evData:TData = new TData.Add("coord", coord)
		Local event:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnTryDrag, evData, Self)
		self.OnTryDrag(event)
		event.Trigger()

		'if there is no problem ...just start dropping
		If Not event.isVeto()
			'trigger an event immediately - if the event has a veto afterwards, do not drag!
			Local event:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnBeginDrag, evData, Self )
			self.OnBeginDrag(event)
			If not event.isVeto() then event.Trigger()

			If not event.isVeto() 
				'nobody said "no" to drag, so drag it
				GuiManager.AddDragged(Self)
				GuiManager._listsSorted = False
				'GuiManager.SortLists()

				'inform others - item finished dragging
				event = TEventBase.Create(GUIEventKeys.GUIObject_OnFinishDrag, evData, Self)
				Self.OnFinishDrag(event)
				event.Trigger()

				'avoid that the object flickers shortly on position 0,0
				'if it was freshly created -> this way it appears right
				'at the "mouse"
				InvalidateScreenRect()

				Return True
			EndIf
		EndIf


		event = TEventBase.Create(GUIEventKeys.GUIObject_OnDragFailed, evData, Self)
		self.OnDragFailed(event)
		event.Trigger()

		Return False
	End Method


	'forcefully drops an item back to the position when dragged
	'if a "drop accepting" widget is below ... this is asked to handle it! 
	Method DropBackToOrigin:Int()
		If not IsDragged() Then Return False

		Local dragPosition:TVec2D = TVec2D(data.Get("dragPosition"))
		Local dragState:TLowerString = TLowerString(data.Get("dragState"))
		If Not dragPosition Then Return False

		'no state stored?
		if not dragState then dragState = GUIManager.currentState

		'drop forcefully and without requiring a widget below the drop
		'spot
		return Drop(dragPosition, dragState, True, True)
		
		rem
		'debug
		'print TTypeID.ForObject(self).name() + " / " + GetClassName()+".DropBackToOrigin()"

		'find out if a list or some other would accept the dropping widget
		Local potentialDropTargets:TGuiObject[] = GUIManager.GetObjectsByPos(dragPosition, dragState, True, GUI_OBJECT_ACCEPTS_DROP)
		Local dropTarget:TGUIObject
		For Local potentialDropTarget:TGUIobject = EachIn potentialDropTargets
			If potentialDropTarget.AcceptsDrop(self, dragPosition)
				dropTarget = potentialDropTarget
				Exit
			EndIf
		Next
		if not dropTarget Then dropTarget = _parent
		
		'if there is no dropTarget this can mean that we simply ... "un-drag"
		'an item ... so back to its start position

		'drop back to origins cannot be vetoed - so not checking any 
		'isVeto()
		'inform dropping object, target and listeners 
		Local evData:TData = new TData.Add("coord", dragPosition).Add("target", dropTarget)
		Local event:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnBeginDrop, evData, Self, dropTarget)
		self.OnBeginDrop(event)
		if dropTarget Then dropTarget.OnBeginReceiveDrop(event)
		event.Trigger()
		

		If not dropTarget
			self.SetPosition(dragPosition.x, dragPosition.y)
		EndIf

		'drop it
		GUIManager.RemoveDragged(Self)
		GuiManager._listsSorted = False

		'inform dropping object, target and listeners 
		event = TEventBase.Create(GUIEventKeys.GUIObject_OnFinishDrop, evData, Self, dropTarget)
		Self.onFinishDrop(event)
		if dropTarget Then dropTarget.onFinishReceiveDrop(event)
		event.Trigger()
		endrem
		Return True
	End Method


	'when using "allowDropToNonGUIObject = true" a widget drops 
	'everywhere and does not require a gui object below the drop position
	'use "force = True" to ignore potential Veto's of events/callbacks
	Method Drop:Int(coord:TVec2D=Null, limitState:TLowerString = Null, allowDropToNonGUIObject:Int = False, force:Int = False)
		If Not isDragged() Then Return False
		If coord And coord.getX()=-1 Then coord = New TVec2D(MouseManager.x, MouseManager.y)

		if not limitState then limitState = GUIManager.currentState
		'debug
		'print TTypeID.ForObject(self).name() + " / " + GetClassName()+".Drop()"


		'find out if a list or some other would accept the dropping
		'widget
		Local potentialDropTargets:TGuiObject[] = GUIManager.GetObjectsByPos(coord.GetIntX(), coord.GetIntY(), limitState, True, GUI_OBJECT_ACCEPTS_DROP)
		Local dropTarget:TGUIObject

		For Local i:Int = 0 until potentialDropTargets.length
			Local potentialDropTarget:TGUIobject = potentialDropTargets[i]

			'ask if it would theoretically handle the drop
			If potentialDropTarget.AcceptsDrop(self, coord)
				dropTarget = potentialDropTarget
				'debug
				'print "  dropTarget="+TTypeID.ForObject(dropTarget).name() + " / " + dropTarget.GetClassName()

				'do not ask other targets if there was already one handling that drop
				Exit
			EndIf
		Next
		
		'Normally we cannot drop without a valid target
		If Not dropTarget And Not allowDropToNonGUIObject Then Return False


		'ask if someone does not want the drop to happen
		'events share same base data (attention to NOT tamper it - if so,
		'then simply reassign coord/source again)
		Local evData:TData = new TData.Add("coord", coord).Add("target", dropTarget)
		Local event:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnTryDrop, evData, Self, dropTarget)
		'ask if widget is OK to drop and drop target NOW accepts the
		'drop (might be "full")
		self.OnTryDrop(event)	
		If dropTarget And (force or Not event.IsVeto()) Then dropTarget.OnTryReceiveDrop(event)
		'inform all others (+ they might be against it)
		If (force or Not event.IsVeto()) Then event.Trigger()

		'if there is no problem ...just start dropping
		If (force or Not event.IsVeto())
			'fire an event - if the event has a veto afterwards, do not drop!
			'exception is, if the action is forced
			event = TEventBase.Create(GUIEventKeys.GUIObject_OnBeginDrop, evData, Self, dropTarget)
			'inform dropping object and drop target
			self.OnBeginDrop(event)
			If dropTarget And (force or Not event.IsVeto()) Then dropTarget.OnBeginReceiveDrop(event)
			'inform all others
			if (force or Not event.IsVeto()) then event.Trigger()

			If (force or Not event.IsVeto())
				'nobody said "no" to drop, so drop it
				GUIManager.RemoveDragged(Self)
				GuiManager._listsSorted = False
				'GuiManager.SortLists()

				If not dropTarget and allowDropToNonGUIObject
					self.SetPosition(coord.x, coord.y)
				EndIf

				'inform others - item finished dropping / dropped
				event = TEventBase.Create(GUIEventKeys.GUIObject_OnFinishDrop, evData, Self, dropTarget)
				Self.onFinishDrop(event)
				If dropTarget Then dropTarget.onFinishReceiveDrop(event)
				event.Trigger()

				Return True
			EndIf
		EndIf


		'inform others - item failed dropping, GetReceiver might
		'contain the item it should have been dropped to
		event = TEventBase.Create(GUIEventKeys.GUIObject_OnDropFailed, evData, Self, dropTarget)
		self.OnDropFailed(event)
		dropTarget.OnReceiveDropFailed(event)
		event.Trigger()

		Return False
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


	Method InvalidateScreenRect()
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

		Local oldX:Float = _screenRect.x
		Local oldY:Float = _screenRect.y
		Local oldW:Float = _screenRect.w
		Local oldH:Float = _screenRect.h

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


	Method GetDimension:SVec2F()
		Return new SVec2F(rect.w, rect.h)
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
	
	
	'source: EGUIClickType.Pointer, EGUIClickType.Keyboard, ...
	'button: button or key
	'x,y:    coordinates
	Method Click:Int(source:EGUIClickType, button:Int, x:Int=-1, y:Int=-1)
		Local clickPos:TVec2D = New TVec2D(x, y)

		'print "IS CLICKED    " + _id + "   " + GetClassName()
		Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnClick, New TData.AddNumber("button", button).Add("coord", clickPos), Self)
		'let the object handle the click
		Local handledClick:Int = OnClick(ev)
		'run callbacks
		For Local i:Int = 0 Until _callbacks_onClick.length
			Local cb:Int(sender:TGUIObject, button:int, x:int, y:Int) = _callbacks_onclick[i]
			If cb(self, button, x, y)
				handledClick = True
				ev.SetAccepted(True) 'mark event as already been handled
			EndIf
		Next

		'fire onClickEvent
		ev.Trigger()

		'doing this leads to "handled click" in these cases
		'-> if handled
		'-> if vetoed
		'And not handled, if "not handled" but event vetoed
		'If Not handledClick And Not ev.IsVeto() Then handledClick = True

		'store click position
		If source = EGUIClickType.POINTER
			'print "TODO: Remove mouseisclicked - interessierte koennen clickevent nutzen"
			mouseIsClicked = clickPos
		EndIf
		
		Return handledClick
	End Method

	Method Click:Int(source:EGUIClickType, button:Int, pos:TVec2D)
		If pos
			Return Click(source, button, Int(pos.x), Int(pos.y))
		Else
			Return Click(source, button)
		EndIf
	End Method
	

	'source: EGUIClickType.Pointer, EGUIClickType.Keyboard, ...
	'button: button or key
	'x,y:    coordinates
	Method DoubleClick:Int(source:EGUIClickType, button:Int, x:Int=-1, y:Int=-1)
		Local clickPos:TVec2D = New TVec2D(x, y)

		Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnDoubleClick, New TData.AddNumber("button", button).Add("coord", clickPos), Self)
		'let the object handle the click
		Local handledClick:int = OnDoubleClick(ev)

		ev.Trigger()
		
		Return handledClick
	End Method

	Method DoubleClick:Int(source:EGUIClickType, button:Int, pos:TVec2D)
		If pos
			Return DoubleClick(source, button, Int(pos.x), Int(pos.y))
		Else
			Return DoubleClick(source, button)
		EndIf
	End Method
	
	
	'called when trying to "ctrl + v"
	Method PasteFromClipboard:Int()
		'read via 
		'local res:String = GetOSClipboard()
		'alternatively app-only
		'local data:object = GetAppClipboard()
		'local source:object = GetAppClipboardSource()

		Return False
	End Method
	

	'called when trying to "ctrl + c"
	Method CopyToClipboard:Int()
		'write via 
		'SetOSClipboard("hello world")
		'alternatively
		'SetAppClipboard(data, source)
		
		Return False
	End Method


	Method HandleKeyboard()
		if IsFocused() or IsHovered()
			If (KeyManager.IsDown(KEY_LCONTROL) Or KeyManager.IsDown(KEY_RCONTROL))
				If KeyManager.IsHit(KEY_V)
					If PasteFromClipboard()
						KeyManager.ResetKey(KEY_LCONTROL)
						KeyManager.ResetKey(KEY_RCONTROL)
						KeyManager.BlockKeyTillRelease(KEY_V)
					EndIf
				ElseIf KeyManager.IsHit(KEY_C)
					If CopyToClipboard()
						KeyManager.ResetKey(KEY_LCONTROL)
						KeyManager.ResetKey(KEY_RCONTROL)
						KeyManager.BlockKeyTillRelease(KEY_C)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method
	
	
	Method HandleMouse()
		'1. check if another item is currently receiving (exclusive) mouse input
		'   -> skip further processing if so
		'2. check if mouse-over takes place, mark if found
		'3. Skip further checks if widget is not clickable
		'4. check if widget becomes mouse input receiver
		'5. handle mouse input (if receiver)
		
		

		' skip if disabled
		If not _flags & GUI_OBJECT_ENABLED Then Return
		' skip if other item is receiving input already 
		' Ronny: enabling this requires a "deactivation click" means
		'        having a widget active and clicking on another one
		'        does not activate the new one but deactivates the first
		'        one first - you need to click again to activate
		'If GUIManager.GetMouseInputReceiver() and GUIManager.GetMouseInputReceiver() <> self then Return
	'	If GUIManager.UpdateState_foundInputReceiverObject and GUIManager.UpdateState_foundInputReceiverObject <> self Then Return


		Local containsMouse:Int = self.ContainsXY(MouseManager.x, MouseManager.y)

		
		'allow to stay "active/hovered..." if mousedown over an item and
		'then moving outside of the widget area without mouse button release
		'(eg scrollers)

		if GUIManager.UpdateState_mouseButtonDown[1] 
			if GUIManager.GetActive() = self 
				if HasOption(GUI_OBJECT_KEEP_ACTIVE_ON_OUTSIDE_CONTINUED_MOUSEDOWN)
					containsMouse = True
				endif
			endif
		ElseIf GUIManager.GetActive() = self and not HasOption(GUI_OBJECT_STAY_ACTIVE_AFTER_MOUSECLICK)
			if not containsMouse 	
				GUIManager.SetActive(Null)
			Endif
		Endif


		'no longer mouse over?
		If not containsMouse and IsHovered()
'print "on mouse leave :" + _id + ": " + GetValue()
			Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnMouseLeave, New TData.AddInt("x", MouseManager.x).AddInt("y", MouseManager.y), Self )
			OnMouseLeave(ev)
			ev.Trigger()


			SetHovered(False)
			
			'update indicator
			If GUIManager.UpdateState_foundHoveredObject = self
				GUIManager.UpdateState_foundHoveredObject = Null
			EndIf
		EndIf


		' skip mouse enter/over and mouse click checks if another item is 
		' hovered already in this update tick/cycle 
		If GUIManager.UpdateState_foundHoveredObject and GUIManager.UpdateState_foundHoveredObject <> self Then Return


		'mouse enter/over?
		If containsMouse
			'mark indicator so next widget does not hover too
			GUIManager.UpdateState_foundHoveredObject = self
			
			Local evData:TData = New TData.AddInt("x", MouseManager.x).AddInt("y", MouseManager.y)

			'create event: onmouseenter
			If Not isHovered()
'print "on mouse enter :" + _id + ": " + GetValue()
				Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnMouseEnter, evData, Self )
				OnMouseEnter(ev)
				ev.Trigger()

				SetHovered(True)
			EndIf

			'create event: onmouseover
			Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnMouseOver, evData, Self )
			OnMouseOver(ev)
			ev.Trigger()
		EndIf
		

		' skip mouse interaction if not clickable -> non click
		If not IsClickable() Then Return


		'handle "mousedown"
		If containsMouse and IsActive()
			For local i:int = 1 to GUIManager.UpdateState_mouseButtonDown.length - 1
				If GUIManager.UpdateState_mouseButtonDown[i]
					Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnMouseDown, New TData.AddNumber("button",1).Add("coord", New TVec2D(MouseManager.x, MouseManager.y)), Self)
					OnMouseDown(ev)
					ev.Trigger()
				EndIf
			Next
		EndIf
		
		

		' check if element becomes or looses "active" (mousedown)
		If GUIManager.UpdateState_mouseButtonDown[1]
			'gain active (and focus)?
			If containsMouse
				'a widget which gets activated _requires_ to be focused
				'too - so ensure that.

				' gain focus if not done yet
				If HasOption(GUI_OBJECT_CAN_GAIN_FOCUS) and not HasStatus(GUI_OBJECT_STATUS_FOCUSED)
					'focuses object and emits event!
					GUIManager.SetFocus(Self)
				EndIf

				If HasOption(GUI_OBJECT_CAN_GAIN_ACTIVE) and GUIManager.GetActive() <> self
'print "set active " + GetClassName()
					GUIManager.SetActive(self)
				EndIf


				'avoid others reacting to mouse down this cycle
				GUIManager.UpdateState_mouseButtonDown[1] = False
			'loose active (can happen even if widget has flag to not gain active)?
			ElseIf IsActive() 'no need to check guimanager.GetActive() 
				GUIManager.SetActive(Null)

				'avoid others reacting to mouse down this cycle
				GUIManager.UpdateState_mouseButtonDown[1] = False
			EndIf
		EndIf
		
		

		' check clicked
		For local button:int = 1 To GUIManager.UpdateState_mouseButtonDown.length - 1
			If MouseManager.IsClicked(button)
				'only handle click if the "button release" happens
				'over the widget (so not "down" over button but "up" 
				'somewhere else)
				Local clickPos:TVec2D = MouseManager.GetClickposition(button)
				if ContainsXY(int(clickPos.x), int(clickPos.y))
					Local handledClick:Int = Click(EGUIClickType.POINTER, button, clickPos)

					'handled that click
					If handledClick
						MOUSEMANAGER.SetClickHandled(button)
					EndIf
					
					
					'special threatment for left click
					If button = 1
						GUIManager.UpdateState_foundClickedObject = Self
						
						If not HasOption(GUI_OBJECT_STAY_ACTIVE_AFTER_MOUSECLICK)
							If GUIManager.GetActive() = self 
								GUIManager.SetActive(Null)
							EndIf
						EndIf
					EndIf
				Endif
			EndIf


			If MouseManager.IsDoubleClicked(button)
				'only handle click if the "button release" happens
				'over the widget (so not "down" over button but "up" 
				'somewhere else)
				Local clickPos:TVec2D = MouseManager.GetClickposition(button)
				If ContainsXY(int(clickPos.x), int(clickPos.y))
					Local handledClick:Int = DoubleClick(EGUIClickType.POINTER, button, clickPos)

					If handledClick
						MouseManager.SetDoubleClickHandled(button)
					EndIf
				EndIf
			EndIf
		Next
		
		
		'handle scrollwheel
		'inform others about a scroll with the mousewheel
		'If IsFocused() And GUIManager.UpdateState_mouseScrollwheelMovement <> 0
		If IsHovered() And GUIManager.UpdateState_mouseScrollwheelMovement <> 0
'print "on scrollwheel :" + _id + " ["+GetClassName()+"] "' + GetValue()
			Local ev:TEventBase = TEventBase.Create(GUIEventKeys.GUIObject_OnMouseScrollwheel, New TData.AddInt("value", GUIManager.UpdateState_mouseScrollwheelMovement).Add("coord", New TVec2D(MouseManager.x, MouseManager.y)), Self)
			OnMouseScrollwheel(ev)
			ev.Trigger()

			'a listener handles the scroll - so remove it for others
			If ev.isAccepted()
				GUIManager.UpdateState_mouseScrollwheelMovement = 0
			EndIf
		EndIf
	End Method


	Method Draw()
		_UpdateLayout()

		If Not IsVisible() Then Return
rem
		'active state check
		If IsActive() and (GUIManager.GetMouseInputReceiver() <> self and GUIManager.GetKeyboardInputReceiver() <> self)
			SetActive(False)
		EndIf
		'hover state check
		If IsHovered() and not ContainsXY(MouseManager.x, MouseManager.y)
			SetHovered(False)
		EndIf
endrem

		'Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		'tint image if object is disabled
		If Not(_flags & GUI_OBJECT_ENABLED) Then SetAlpha 0.5 * oldColA

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

		If Not(_flags & GUI_OBJECT_ENABLED) Then SetAlpha oldColA

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
			'skip dragged ones - as we set them to managed by GUIManager for that time
			If obj.isDragged() 
				'before skipping a dragged one, we try to ask it as a ghost (at old position)
				obj.drawGhost()
				Continue
			EndIf

			'skip invisible objects
			If Not obj.IsVisible() Then Continue

			'tint image if object is disabled
'			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 0.5*GetAlpha()
			obj.draw()
			'tint image if object is disabled
'			If Not(obj._flags & GUI_OBJECT_ENABLED) Then SetAlpha 2.0*GetAlpha()

			'fire event
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnDraw, Null, obj )
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


		If not GUIManager._ignoreMouse Then HandleMouse()
		'react to some special keys
		HandleKeyboard()


		'=== HANDLE TOOLTIP ===
		If _tooltip And Not hasOption(GUI_OBJECT_MANAGED) And Not hasOption(GUI_OBJECT_DRAGGED)
			'update hovered state
			_tooltip.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED, IsHovered())
			'change position if required

			_tooltip.Update()
		EndIf



		'=== REFRESH INDICATORS ===
		'guimanager resets updatestate values each "StartUpdates()"
		'to ensure only actively used widgets (this cycle) can be hovered,
		'activated, ...

		If GUIManager.GetFocus() = self or IsActive()
			GUIManager.UpdateState_foundFocusedObject = self
		EndIf
	End Method


	Method DrawBaseFormText:Int(_value:String, x:Float, y:Float)
		If Not(_flags & GUI_OBJECT_ENABLED)
'			GetFont().DrawSimple(_value,x,y, defaultDisabledTextCol, EDrawTextEffect.Shadow, 0.5)
		ElseIf isHovered()
'			GetFont().DrawSimple(_value,x,y, defaultHoverTextCol, EDrawTextEffect.Shadow, 0.5)
		Else
'			GetFont().DrawSimple(_value,x,y, defaultTextCol, EDrawTextEffect.Shadow, 0.5)
		EndIf

		Return True
	End Method


	'returns true if the conversion was successful
	Function ConvertKeystrokesToText:Int(value:String Var, valuePosition:Int Var, ignoreEnterKey:Int = False)
		If valuePosition = -1
			valuePosition = value.length
		Else
			valuePosition = Min(valuePosition, value.length)
		EndIf

		'codes for "Keyhit()" (or keymanager.***)
		'old codes included 127 ... as my (Ronny) old linux box sent this
		'on "delete" key)
		'Local specialCommandKeys:Int[] = [KEY_BACKSPACE, KEY_DELETE, 127, KEY_HOME, KEY_END, KEY_LEFT, KEY_RIGHT, KEY_ESCAPE]
		Local specialCommandKeys:Int[] = [KEY_BACKSPACE, KEY_DELETE, KEY_HOME, KEY_END, KEY_LEFT, KEY_RIGHT, KEY_ESCAPE]
		'codes for "GetChar()" - might be same than scancodes
		'8 equals KEY_BACKSPACE, 127 is "Delete" (but _not_ KEY_DELETE)
		Local specialCommandCodes:Int[] = [8, 127]

		'=== SPECIAL COMMAND KEYS ===
		Local handledSpecialCommandKeys:Int = False
		For Local key:Int = EachIn specialCommandKeys
			If Not KEYWRAPPER.IsPressed(key) Then Continue

			Select key
				Case KEY_BACKSPACE
					If valuePosition > 0
						value = value[.. valuePosition-1] + value[valuePosition ..]
						valuePosition :- 1
					EndIf

				'Ronny: on my linux OLD box "127" was the delete-key and not KEY_DELETE (46)
				'       but now it seems to be "KEY_DELETE" (46) too
				Case KEY_DELETE ', 127
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
		'If handledSpecialCommandKeys Then Return True



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
			'skip chars like "KEY_BACKSPACE"
			if not MathHelper.InIntArray(charCode, specialCommandCodes)
				'charCode is < 0 for me when umlauts are pressed
				If charCode < 0
					?Win32
					If KEYWRAPPER.IsPressed(186)
						If shiftPressed Then value:+ "Ü" Else value :+ "ü"
						valuePosition :+ 1
					EndIf
					If KEYWRAPPER.IsPressed(192)
						If shiftPressed Then value:+ "Ö" Else value :+ "ö"
						valuePosition :+ 1
					EndIf
					If KEYWRAPPER.IsPressed(222)
						If shiftPressed Then value:+ "Ä" Else value :+ "ä"
						valuePosition :+ 1
					EndIf
					?MacOS
					If KEYWRAPPER.IsPressed(186)
						If shiftPressed Then value:+ "Ü" Else value :+ "ü"
						valuePosition :+ 1
					EndIf
					If KEYWRAPPER.IsPressed(192)
						If shiftPressed Then value:+ "Ö" Else value :+ "ö"
						valuePosition :+ 1
					EndIf
					If KEYWRAPPER.IsPressed(222)
						If shiftPressed Then value:+ "Ä" Else value :+ "ä"
						valuePosition :+ 1
					EndIf
					?Linux
					If KEYWRAPPER.IsPressed(252)
						If shiftPressed Then value:+ "Ü" Else value :+ "ü"
						valuePosition :+ 1
					EndIf
					If KEYWRAPPER.IsPressed(246)
						If shiftPressed Then value:+ "Ö" Else value :+ "ö"
						valuePosition :+ 1
					EndIf
					If KEYWRAPPER.IsPressed(163)
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
			endif
			charCode = Int(GetChar())
		Wend
		'special chars - recognized on Mac, but not Linux
		'euro sign
		?Linux
		If KEYWRAPPER.IsPressed(69) And altGrPressed Then value :+ Chr(8364)
		?
		Return True
	End Function


	'object realigned some components / inner stuff
	Method OnUpdateLayout()
	End Method


	'object was resized in width and/or height
	Method OnResize(dW:Float, dH:Float)
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


	Method OnTryDrag:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnBeginDrag:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnFinishDrag:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnDragFailed:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnTryDrop:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnBeginDrop:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnFinishDrop:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnDropFailed:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnTryReceiveDrop:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnBeginReceiveDrop:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnFinishReceiveDrop:Int(triggerEvent:TEventBase)
		Return True
	End Method


	Method OnReceiveDropFailed:Int(triggerEvent:TEventBase)
		Return True
	End Method



	'defines if the passed "o" is accepted
	Method AcceptsDrop:Int(o:TGUIObject, coord:TVec2D, extra:object=Null)
		If HasOption(GUI_OBJECT_ACCEPTS_DROP)
			If _acceptedDropFilter And Not TEventManager.FiltersObject(o, _acceptedDropFilter)
				Return False
			EndIf
			Return True
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


	'default mouse enter handler
	Method onMouseEnter:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default mouse leave handler
	Method onMouseLeave:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default mouse over handler
	Method onMouseOver:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default mouse down handler
	Method onMouseDown:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default mouse up handler
	Method onMouseUp:Int(triggerEvent:TEventBase)
		Return False
	End Method


	'default mouse scrollwheel handler
	Method onMouseScrollwheel:Int(triggerEvent:TEventBase)
		Return False
	End Method


	Method OnChildAppearanceChanged(child:TGUIObject, bool:Int)
		Return
	End Method


	Method OnParentAppearanceChanged(bool:Int)
		Return
	End Method


	Method OnChangePadding:Int()
		InvalidateScreenRect()
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
		'already done by InvalidateScreenRect()
		'InvalidateContentScreenRect()
	End Method


	Method onSelect:Int()
		TriggerBaseEvent(GUIEventKeys.GUIObject_OnSelect, Null, Self )
	End Method


	Method onDeselect:Int()
		TriggerBaseEvent(GUIEventKeys.GUIObject_OnDeselect, Null, Self )
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


	Method Create:TGUISimpleRect(position:SVec2I, dimension:SVec2I, limitState:String="")
		Super.CreateBase(position, dimension, limitState)
		Self.SetSize(dimension.x, dimension.y)

    	GUIManager.Add( Self )
		Return Self
	End Method


	Method DrawContent()
		'
	End Method


	Method DrawDebug()
		SetAlpha 0.5
		local scrRect:TRectangle = GetScreenRect()
		DrawRect(scrRect.x, scrRect.y, scrRect.w, scrRect.h)
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

	Global _defaultOffset:TVec2D = New TVec2D(0, 3)
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
			Local bgSpritePadding:SRect = GetBGSprite().GetNinePatchInformation().contentBorder
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
			If _bgSprite <> TSprite.defaultSprite
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
