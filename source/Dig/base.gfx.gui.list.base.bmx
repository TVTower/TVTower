Rem
	===========================================================
	GUI Basic List
	===========================================================

	Code contains:
	- TGUIListBase: basic list
	- TGUIListItem: basic list item
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.gfx.gui.scroller.bmx"
Import "base.gfx.gui.panel.scrollablepanel.bmx"
Import "base.util.helper.bmx"


'=== LIST SPECIFIC CONSTANTS ===
Const GUILIST_AUTOSCROLL:Int        = 2^0
'hide scroller if mouse not over parent
Const GUILIST_AUTOHIDE_SCROLLER:Int = 2^1
Const GUILIST_MULTICOLUMN:Int       = 2^2
Const GUILIST_AUTOSORT_ITEMS:Int    = 2^3
'flag to do a "one time" auto scroll
Const GUILIST_SCROLLER_USED:Int     = 2^4
Const GUILIST_SCROLLING_ENABLED:Int = 2^5
'scroll to the very first element as soon as the scrollbars get hidden ?
Const GUILIST_SCROLL_TO_BEGIN_WITHOUT_SCROLLBARS:Int = 2^6
Const GUILIST_SCROLL_TO_NEXT_ITEM:Int = 2^7

Const GUILISTITEM_AUTOSIZE_WIDTH:Int = 2^0




Type TGUIListBase Extends TGUIobject
	Field guiBackground:TGUIobject = Null
	Field backgroundColor:TColor = TColor.Create(0,0,0,0)
	Field backgroundColorHovered:TColor	= TColor.Create(0,0,0,0)
	Field guiEntriesPanel:TGUIScrollablePanel = Null
	Field guiScrollerH:TGUIScrollerBase = Null
	Field guiScrollerV:TGUIScrollerBase	= Null
	Field entriesDimension:TVec2D = New TVec2D(0,0)

	Field _listFlags:Int = 0
	Field _autoSortFunction:Int(o1:Object,o2:Object)
	Field _autoSortInAscendingOrder:Int = True

	'amount (percentage) a list is scrolled based on item height
	Field scrollItemHeightPercentage:Float = 0.5

	Field entries:TList	= CreateList()
	Field entriesLimit:Int = -1
	'private mouseover-field (ignoring covering child elements)
	Field _mouseOverArea:Int = False
	'displace each entry by (z-value is stepping)...
	Field _entryDisplacement:TVec3D	= New TVec3D.Init(0, 0, 1)
	'displace the entriesblock by x,y...
	Field _entriesBlockDisplacement:TVec2D = New TVec2D(0, 0)
	'orientation of the list: 0 means vertical, 1 is horizontal
	Field _orientation:Int = 0


	Method GetClassName:String()
		Return "tguilistbase"
	End Method


	Method New()
		setListOption(GUILIST_AUTOSCROLL, False)
		setListOption(GUILIST_AUTOHIDE_SCROLLER, False)
		setListOption(GUILIST_MULTICOLUMN, False)
		setListOption(GUILIST_AUTOSORT_ITEMS, True)
		setListOption(GUILIST_SCROLL_TO_BEGIN_WITHOUT_SCROLLBARS, True)
		'by default all lists accept drop
		setOption(GUI_OBJECT_ACCEPTS_DROP, True)
	End Method


    Method Create:TGUIListBase(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.CreateBase(position, dimension, limitState)

		setZIndex(0)

		guiScrollerH = New TGUIScroller.Create(Self)
		guiScrollerV = New TGUIScroller.Create(Self)
		'orientation of horizontal scroller has to get set manually
		guiScrollerH.SetOrientation(GUI_OBJECT_ORIENTATION_HORIZONTAL)

		guiEntriesPanel = New TGUIScrollablePanel.Create(new SVec2I(0,0), New SVec2I(Int(rect.w - guiScrollerV.rect.w), Int(rect.h - guiScrollerH.rect.h)), limitState)

		'manage by our own
		AddChild(guiEntriesPanel)
		AddChild(guiScrollerH)
		AddChild(guiScrollerV)


		'by default all lists do not have scrollers
		setScrollerState(False, False)

		'the entries panel cannot be focused
		guiEntriesPanel.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)


		'register events
		'- we are interested in certain events from the scroller or self
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScroll, guiScrollerH ))
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScroll, guiScrollerV ))
		'listening to our own scroll events redirects them to the same 
		'as the scrollers - but without requiring it
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnScrollPositionChanged, onScroll, self ))
		'redirect the scroll event of the panel 
		AddEventListener(EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnMouseScrollwheel, onPanelMouseScrollWheel, guiEntriespanel ))

		'is something dropping - check if it this list
		SetAcceptDrop("TGUIListItem")

		GUIManager.Add(Self)
		Return Self
	End Method


	Method hasListOption:Int(option:Int)
		Return (_listFlags & option) <> 0
	End Method


	Method setListOption(option:Int, enable:Int=True)
		If enable
			_listFlags :| option
		Else
			_listFlags :& ~option
		EndIf
	End Method


	Method Remove:Int()
		Super.Remove()

		If guiEntriesPanel Then guiEntriesPanel.Remove()
		If guiScrollerH Then guiScrollerH.Remove()
		If guiScrollerV Then guiScrollerV.Remove()

		'set all entries free
		EmptyList()
	End Method


	Method EmptyList:Int()
		'traverse a copy to avoid concurrent modification
		For Local obj:TGUIobject = EachIn entries.Copy()
			'call the objects cleanup-method and unsets the object
			obj.remove()
			GUIManager.Remove(obj)
			obj = Null
		Next
		entries.Clear()

		'also reset scroll state!
		ScrollToFirstItem()
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


	Method SetMultiColumn(bool:Int=False)
		If hasListOption(GUILIST_MULTICOLUMN) <> bool
			setListOption(GUILIST_MULTICOLUMN, bool)
			'maybe now more or less elements fit into the visible
			'area, so elements position need to get recalculated
			InvalidateLayout()
		EndIf
	End Method


	Method SetAutosortItems(bool:Int=False)
		If hasListOption(GUILIST_AUTOSORT_ITEMS) <> bool
			setListOption(GUILIST_AUTOSORT_ITEMS, bool)
		EndIf
	End Method


	Method SetAutoscroll(bool:Int=False)
		If hasListOption(GUILIST_AUTOSCROLL) <> bool
			setListOption(GUILIST_AUTOSCROLL, bool)
		EndIf
	End Method


	Method SetBackground(background:TGUIobject)
		'set old background to managed again
		If guiBackground Then GUIManager.add(guiBackground)
		'assign new background
		guiBackground = background
		If guiBackground
			guiBackground.SetOPTION(GUI_OBJECT_IGNORE_PARENTPADDING, True)
			guiBackground.setParent(Self)
			'set to unmanaged in all cases
			GUIManager.remove(guiBackground)
		EndIf
	End Method


	'when reskinned, resize to move scrollbars accordingly
	Method onAppearanceChanged:Int()
		Super.onAppearanceChanged()

		UpdateLayout()
	End Method


	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method SetSize(w:Float = 0, h:Float = 0) override
		Super.SetSize(w,h)

'		If guiBackground Then guiBackground.SetSize(w, h)

		'let the children properly refresh their size
		'(eg. because the scrollbars are visible now)
		For Local entry:TGUIobject = EachIn entries
			entry.onParentResize()
		Next
	End Method


	Method SetItemLimit:Int(limit:Int)
		entriesLimit = limit
	End Method


	Method ReachedItemLimit:Int()
		If entriesLimit <= 0 Then Return False
		Return (entries.count() >= entriesLimit)
	End Method


	Method GetItemByCoord:TGUIobject(coord:TVec2D)
		For Local entry:TGUIobject = EachIn entries
			'our entries are sorted and replaced, so we could
			'quit as soon as the entry is out of range...
			If entry.GetScreenRect().GetY() > GetScreenRect().GetY2() Then Return Null
			If entry.GetScreenRect().GetX() > GetScreenRect().GetX2() Then Return Null

			If entry.GetScreenRect().containsXY(coord.GetX(), coord.GetY()) Then Return entry
		Next
		Return Null
	End Method


	Method GetItemByListPosition:TGUIobject(pos:TVec2D)
		For Local entry:TGUIobject = EachIn entries
			'our entries are sorted and replaced, so we could
			'quit as soon as the entry is out of range...
			If entry.rect.GetY() > pos.y Then Return Null
			If entry.rect.GetX() > pos.x Then Return Null

			If entry.rect.containsVec(pos) Then Return entry
		Next
		Return Null
	End Method


	Method GetItemIndex:Int(item:Object)
		'using "object" to avoid filtering and therefor invalid indices
		'also it should be faster than loops with "ValueAtIndex"-calls in
		'it

		Local index:Int = 0
		For Local obj:Object = EachIn entries
			If item = obj Then Return index
			index :+ 1
		Next

		Return -1
	End Method


	Method GetItemAtIndex:TGUIObject(index:Int)
		if index >= entries.Count() or index < 0 then Return Null
		Return TGUIObject(entries.ValueAtIndex(index))
	End Method


	Method GetItemNextToItem:TGUIobject(item:Object, distance:Int, allowDistanceReductionOnBorders:Int = True)
		Local currentIndex:Int = GetItemIndex(item)
		If currentIndex = -1 Then Return Null
		Local nextIndex:Int = 0

		'when reaching below "0" or more than "max" should we return the
		'very first/last or nothing?
		If currentIndex + distance < 0
			If Not allowDistanceReductionOnBorders Then Return Null
			nextIndex = 0
		Else If currentIndex + distance >= entries.Count()
			If Not allowDistanceReductionOnBorders Then Return Null
			nextIndex = entries.Count() - 1
		EndIf

		Return GetItemAtIndex(nextIndex)
	End Method


	'base handling of add item
	Method _AddItem:Int(item:TGUIobject, extra:Object=Null)
'		if self.ReachedItemLimit() then return FALSE

		'set parent of the item - so item is able to calculate position
		guiEntriesPanel.addChild( item )
		

		'recalculate dimensions as the item now knows its parent
		'so a normal AddItem-handler can work with calculated dimensions from now on
		'Local dimension:SVec2F = item.getDimension()

		TriggerBaseEvent(GUIEventKeys.GUIList_AddItem, New TData.Add("item", item) , Self)

		entries.addLast(item)
		if TGUIListItem(item) then TGUIListItem(item).parentListID = self._id

		'resize item
		If item Then item.onParentResize()

		'run the custom compare method
		If hasListOption(GUILIST_AUTOSORT_ITEMS)
			If _autoSortFunction
				entries.sort(_autoSortInAscendingOrder, _autoSortFunction)
			Else
				entries.sort(_autoSortInAscendingOrder)
'				entries.sort(_autoSortInAscendingOrder, SortByCompare)
'				entries.sort(_autoSortInAscendingOrder, SortByValue)
			EndIf
		EndIf

		TriggerBaseEvent(GUIEventKeys.GUIList_AddedItem, New TData.Add("item", item) , Self)

		Return True
	End Method


	'base handling of remove item
	Method _RemoveItem:Int(item:TGUIobject)
		If entries.Remove(item)
			TriggerBaseEvent(GUIEventKeys.GUIList_RemoveItem, New TData.Add("item", item) , Self)

			if TGUIListItem(item) then TGUIListItem(item).parentListID = -1

			'remove from panel and item gets managed by guimanager
			guiEntriesPanel.removeChild(item)

			TriggerBaseEvent(GUIEventKeys.GUIList_RemovedItem, New TData.Add("item", item) , Self)

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
			InvalidateLayout()

			Return True
		EndIf
		Return False
	End Method


	'overrideable RemoveItem-Handler
	Method RemoveItem:Int(item:TGUIobject)
		If _RemoveItem(item)
			InvalidateLayout()

			Return True
		EndIf
		Return False
	End Method


	Method HasItem:Int(item:TGUIobject)
		'TODO: maybe faster to just check parentListID
		'if TGUIListItem(item)
		'	Return TGUIListItem(item).parentListID = self._id
		'endif

		For Local otheritem:TGUIobject = EachIn entries
			If otheritem = item Then Return True
		Next
		Return False
	End Method


	Method IsAtListBottom:Int()
		Local result:Int = 1 > Floor(Abs(guiEntriesPanel.scrollLimit.GetY() - guiEntriesPanel.scrollPosition.getY()))

		'if all items fit on the screen, scroll limit will be
		'lower than the container panel
		If Abs(guiEntriesPanel.scrollLimit.GetY()) < guiEntriesPanel.GetContentScreenRect().GetH()
			'if scrolled = 0 this could also mean we scrolled up to the top part
			'in this case we check if the last item in the list fits into the
			'panel
			If guiEntriesPanel.scrollPosition.getY() = 0
				result = 1
				Local lastItem:TGUIListItem = GetLastItem()
				If lastItem And lastItem.GetScreenRect().GetY() > guiEntriesPanel.GetContentScreenRect().GetY2()
					result = 0
				EndIf
			EndIf
		EndIf
		Return result
	End Method


	Method GetFirstItem:TGUIListItem()
		Return TGUIListItem(entries.First())
	End Method


	Method GetLastItem:TGUIListItem()
		Return TGUIListItem(entries.Last())
	End Method


	Method GetLastItemY:Int()
		Local i:TGUIListItem = GetLastItem()
		If i Then Return i.GetScreenRect().GetY()
		Return 0
	End Method


	'recalculate scroll maximas, item positions...
	Method RecalculateElements:Int()
		Local startPos:TVec2D = _entriesBlockDisplacement.copy()
		Local entryNumber:Int = 1
		Local nextPos:TVec2D = startPos.copy()
		Local currentPos:TVec2D = New TVec2D
		Local columnPadding:Int = 5

		'reset current entriesDimension ...
		entriesDimension.CopyFrom(_entriesBlockDisplacement)

		For Local entry:TGUIobject = EachIn entries
			currentPos.CopyFrom( nextPos )

			'==== CALCULATE POSITION ====
			Select _orientation
				'only from top to bottom
				Case GUI_OBJECT_ORIENTATION_VERTICAL
					'MultiColumn: from left to right, if space left a
					'             new column on the right is started.

					'advance the next position starter
					If hasListOption(GUILIST_MULTICOLUMN)
						'if entry does not fit, try the next line
						If currentPos.GetX() + entry.rect.GetW() > GetContentScreenRect().GetW()
							currentPos.SetXY(startPos.GetX(), currentPos.GetY() + entry.rect.GetH())
							'new lines increase dimension of container
							entriesDimension.AddXY(0, entry.rect.GetH())
						EndIf

						nextPos.CopyFrom(currentPos)
						nextPos.AddXY(entry.rect.GetW() + columnPadding, 0)
					Else
						nextPos.CopyFrom(currentPos)
						nextPos.AddXY(0, entry.rect.GetH())
						'new lines increase dimension of container
						entriesDimension.AddXY(0, entry.rect.GetH())
					EndIf

				Case GUI_OBJECT_ORIENTATION_HORIZONTAL
					'MultiColumn: from top to bottom, if space left a
					'             new line below is started.

					'advance the next position starter
					If hasListOption(GUILIST_MULTICOLUMN)
						'if entry does not fit, try the next row
						If currentPos.GetY() + entry.rect.GetH() > GetContentScreenRect().GetH()
							currentPos.SetXY(currentPos.GetX() + entry.rect.GetW(), startPos.GetY())
							'new lines increase dimension of container
							entriesDimension.AddXY(entry.rect.GetW(), 0 )
						EndIf

						nextPos.CopyFrom(currentPos)
						nextPos.AddXY(0, entry.rect.GetH() + columnPadding)
					Else
						nextPos.CopyFrom(currentPos)
						nextPos.AddXY(entry.rect.GetW(),0)
						'new lines increase dimension of container
						entriesDimension.AddXY(entry.rect.GetW(), 0 )
					EndIf
			End Select

			'==== ADD POTENTIAL DISPLACEMENT ====
			'add the displacement afterwards - so the first one is not displaced
			If entryNumber Mod _entryDisplacement.z = 0 And entry <> GetLastItem()
				currentPos.AddXY(_entryDisplacement.x, _entryDisplacement.y)
				'increase dimension if positive displacement
				entriesDimension.AddXY( Max(0,_entryDisplacement.x), Max(0, _entryDisplacement.y))
			EndIf

			'==== SET POSITION ====
			If Not entry.rect.IsSamePosition(currentPos)
				entry.rect.SetXY(currentPos)
				entry.InvalidateScreenRect()
			EndIf
			entryNumber:+1
		Next


		UpdateLimitsAndScrollerState()
	End Method


	Method UpdateLimitsAndScrollerState()
		If guiEntriesPanel
			'resize container panel
			guiEntriesPanel.SetSize(entriesDimension.getX(), entriesDimension.getY())

			'refresh scrolling limits
			RefreshListLimits()

			'if not all entries fit on the panel, enable scroller
			SetScrollerState(..
				entriesDimension.getX() > guiEntriesPanel.GetContentScreenRect().GetW(), ..
				entriesDimension.getY() > guiEntriesPanel.GetContentScreenRect().GetH() ..
			)
		EndIf
	End Method


	Method RefreshListLimits:Int()
		If Not guiEntriesPanel Then Return False
		'if entriesDimension.GetX() = 0 then return false

		Select _orientation
			'===== VERTICAL ALIGNMENT =====
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				'determine if we did not scroll the list to a middle
				'position so this is true if we are at the very bottom
				'of the list aka "the end"
				Local atListBottom:Int = IsAtListBottom()

				'set scroll limits:
				If entriesDimension.getY() <= guiEntriesPanel.GetContentScreenRect().GetH()
					'if there are only some elements, they might be
					'"less high" than the available area - no need to
					'align them at the bottom
					guiEntriesPanel.SetLimits(0, -entriesDimension.getY())
				Else
					'maximum is at the bottom of the area, not top - so
					'subtract height
					'old: guiEntriesPanel.SetLimits(0, -(dimension.getY() - guiEntriesPanel.GetScreenRect().GetH()) )
					Local lastItem:TGUIListItem = GetLastItem()
					If Not lastItem And GetLastItemY() = 0
						guiEntriesPanel.SetLimits(0, 0)
					Else
'						if not autoScroll
'							guiEntriesPanel.SetLimits(0, - (dimension.getY() - guiEntriesPanel.GetScreenRect().GetH() - lastItem.GetScreenRect().GetH()))
'						else
							guiEntriesPanel.SetLimits(0, - (entriesDimension.getY() - guiEntriesPanel.GetContentScreenRect().GetH()))
'						endif
					EndIf
					'in case of auto scrolling we should consider
					'scrolling to the next visible part
					If hasListOption(GUILIST_AUTOSCROLL) And (Not hasListOption(GUILIST_SCROLLER_USED) Or atListBottom) Then scrollToLastItem()
				EndIf
			'===== HORIZONTAL ALIGNMENT =====
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				'determine if we did not scroll the list to a middle
				'position so this is true if we are at the very right
				'of the list aka "the end"
				Local atListBottom:Int = 1 > Floor( Abs(guiEntriesPanel.scrollLimit.GetX() - guiEntriesPanel.scrollPosition.getX() ) )

				'set scroll limits:
				If entriesDimension.getX() < guiEntriesPanel.GetContentScreenRect().GetW()
					'if there are only some elements, they might be
					'"less high" than the available area - no need to
					'align them at the right
					guiEntriesPanel.SetLimits(-entriesDimension.getX(), 0 )
				Else
					'maximum is at the bottom of the area, not top - so
					'subtract height
					'old: guiEntriesPanel.SetLimits(-(dimension.getX() - guiEntriesPanel.GetScreenRect().GetW()), 0)
					Local lastItem:TGUIListItem = GetLastItem()
					If Not lastItem
						guiEntriesPanel.SetLimits(0, 0)
					Else
						guiEntriesPanel.SetLimits(- (entriesDimension.getX() - guiEntriesPanel.GetContentScreenRect().GetW() - lastItem.GetScreenRect().GetW()), 0)
					EndIf

					'in case of auto scrolling we should consider
					'scrolling to the next visible part
					If hasListOption(GUILIST_AUTOSCROLL) And (Not hasListOption(GUILIST_SCROLLER_USED) Or atListBottom) Then scrollToLastItem()
				EndIf

		End Select

		guiScrollerH.SetValueRange(0, entriesDimension.getX())
		guiScrollerV.SetValueRange(0, entriesDimension.getY())
	End Method


	Method SetScrollerState:Int(boolH:Int, boolV:Int)
		'set scrolling as enabled or disabled
		SetListOption(GUILIST_SCROLLING_ENABLED, (boolH Or boolV))

		Local changed:Int = False
		If boolH <> guiScrollerH.hasOption(GUI_OBJECT_ENABLED) Then changed = True
		If boolV <> guiScrollerV.hasOption(GUI_OBJECT_ENABLED) Then changed = True

		'as soon as the scroller gets disabled, we scroll to the first
		'item.
		'ATTENTION: if you do not want this behaviour, set the variable below
		'           accordingly
		If changed And HasListOption(GUILIST_SCROLL_TO_BEGIN_WITHOUT_SCROLLBARS)
			If Not HasListOption(GUILIST_SCROLLING_ENABLED) Then ScrollToFirstItem()
		End If


		guiScrollerH.setOption(GUI_OBJECT_ENABLED, boolH)
		guiScrollerH.setOption(GUI_OBJECT_VISIBLE, boolH)
		guiScrollerV.setOption(GUI_OBJECT_ENABLED, boolV)
		guiScrollerV.setOption(GUI_OBJECT_VISIBLE, boolV)

		'resize everything
		If changed Then UpdateLayout()
	End Method


	Function FindGUIListBaseParent:TGUIListBase(guiObject:TGUIObject)
		If Not guiObject Then Return Null

		'self is already the list?
		Local guiList:TGUIListBase = TGUIListBase(guiObject)
		If guiList Then Return guiList

		Local obj:TGUIObject = guiObject._parent
		While obj and obj <> guiObject And Not TGUIListBase(obj)
			obj = obj._parent
		Wend
		'return the list or null (if topmost parent is of incompatible type)
		Return TGUIListBase(obj)
	End Function


	'default handler for the case of an item being dropped back to its
	'parent list
	'by default it does not handly anything, so returns FALSE
	Method HandleDropBack:Int(triggerEvent:TEventBase)
		Return False
	End Method


	Method onTryReceiveDrop:Int( triggerEvent:TEventBase ) override
		If not AcceptsDrop(TGUIObject(triggerEvent.GetSender()), null)
			triggerEvent.SetVeto()
			Return False
		endif
		
		Return Super.onTryReceiveDrop(triggerEvent)
	End Method


	Method OnBeginReceiveDrop:Int( triggerEvent:TEventBase ) override
		Local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		If item = Null Then Return False
		'ATTENTION:
		'Item is still in dragged state!
		'Keep this in mind when sorting the items

		'only handle if coming from another list ?
		Local fromList:TGUIListBase = FindGUIListBaseParent(item._parent)
		'if not fromList then return FALSE

'		Local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
'		If Not toList Then Return False

		Local data:TData = triggerEvent.getData()
		If Not data Then Return False

		If fromList = self
			'if the handler took care of everything, we skip
			'removing and adding the item
			If fromList.HandleDropBack(triggerEvent)
				'inform others about that dropback
				TriggerBaseEvent(GUIEventKeys.GUIObject_OnDropBack, Null , item, self)
				Return True
			EndIf
			'no drop back?
			'we might have dropped it on another slot/position
		EndIf
'method A
		'move item if possible
		If fromList Then fromList.removeItem(item)
		'try to add the item, if not able, readd
		If Not addItem(item, data)
			If fromList And fromList.addItem(item) Then Return True

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
			Return False
		EndIf

		Return True
	End Method


	'redirect panel scrolling to parental list
	Function onPanelMouseScrollWheel:Int( triggerEvent:TEventBase )
		Local guiSender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		If Not guiSender Then Return False

		Local guiList:TGUIListBase = FindGUIListBaseParent(guiSender)
		If Not guiList Then Return False
		
		If guiList
			guiList.onMouseScrollWheel(triggerEvent)
		EndIf
	End Function
	
	
	Method onMouseScrollWheel:Int( triggerEvent:TEventBase ) override
		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If value = 0 Then Return False
		'emit event that the scroller position has changed
		Local direction:String = ""
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				If value < 0 Then direction = "up"
				If value > 0 Then direction = "down"
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				If value < 0 Then direction = "left"
				If value > 0 Then direction = "right"
		End Select
		If direction <> ""
			Local scrollAmount:Int = 25
			'try to scroll by X percent of an item height
			Local item:TGUIObject
			If entries.Count() > 0 Then item = TGUIObject(entries.First())
			If item Then scrollAmount = item.rect.GetH() * scrollItemHeightPercentage


			'instead of scrolling on our own - we just emulate scrolling
			'via scrollers (which should only exist if scrolling is there)
			'but IF there was no scroller
'			if direction = "left" or direction = "right"
'				TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, New TData.AddString("direction", direction).AddNumber("scrollAmount", scrollAmount), guiScrollerH)
'			else
'				TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, New TData.AddString("direction", direction).AddNumber("scrollAmount", scrollAmount), guiScrollerV)
'			endif
			TriggerBaseEvent(GUIEventKeys.GUIObject_OnScrollPositionChanged, New TData.Add("direction", direction).Add("scrollAmount", scrollAmount), self)
		EndIf
		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Method


	'handle events from the connected scroller
	Function onScroll:Int( triggerEvent:TEventBase )
		Local guiSender:TGUIObject = TGUIObject(triggerEvent.GetSender())
		If Not guiSender Then Return False

		'search a TGUIListBase-parent
		Local guiList:TGUIListBase = FindGUIListBaseParent(guiSender)
		If Not guiList Then Return False

		'do not allow scrolling if not enabled
		If Not guiList.HasListOption(GUILIST_SCROLLING_ENABLED) Then Return False

		Local data:TData = triggerEvent.GetData()
		If Not data Then Return False


		'by default scroll by 2 pixels
		'the longer you pressed the mouse button, the "speedier" we get
		'1px per 100ms. Start speeding up after 500ms, limit to 20px per scroll
		Local baseScrollSpeed:Int = Min(20, 2 + Max(0, MOUSEMANAGER.GetDownTime(1) - 500)/100.0)


		If guiList.HasListOption(GUILIST_SCROLL_TO_NEXT_ITEM)
			'for now assume same height for all (as we do not know what
			'item to use as "current item")
			Local currentItem:TGUIListItem = guiList.GetFirstItem()
			If currentItem
				Local itemHeight:Int = Max(currentItem.rect.GetH(), currentItem.GetScreenRect().GetH())
				If itemHeight = 0 Then itemHeight = 20
				baseScrollSpeed = itemHeight * Ceil(baseScrollSpeed / Float(itemHeight))
			EndIf
		EndIf

		Local scrollAmount:Int = data.GetInt("scrollAmount", baseScrollSpeed)
		'this should be "calculate height and change amount"
		If data.GetString("direction") = "up" Then guiList.ScrollEntries(0, +scrollAmount)
		If data.GetString("direction") = "down" Then guiList.ScrollEntries(0, -scrollAmount)
		If data.GetString("direction") = "left" Then guiList.ScrollEntries(+scrollAmount,0)
		If data.GetString("direction") = "right" Then guiList.ScrollEntries(-scrollAmount,0)

		'maybe data was given in percents - so something like a
		'"scrollTo"-value
		If data.GetInt("isRelative") = 1
			Local percentage:Float = data.GetFloat("percentage", 0)
			If guiSender = guiList.guiScrollerH
				guiList.SetScrollPercentageX(percentage)
			ElseIf guiSender = guiList.guiScrollerV
				guiList.SetScrollPercentageY(percentage)
			EndIf
		EndIf
		'from now on the user decides if he wants the end of the chat or stay inbetween
		guiList.SetListOption(GUILIST_SCROLLER_USED, True)
	End Function


	'positive values scroll to top or left
	Method ScrollEntries(dx:Float, dy:Float)
		if guiEntriesPanel Then guiEntriesPanel.scrollBy(dx,dy)

		'refresh scroller values (for "progress bar" on the scroller)
		If dx <> 0 and guiScrollerH Then guiScrollerH.SetRelativeValue( GetScrollPercentageX() )
		If dy <> 0 and guiScrollerV Then guiScrollerV.SetRelativeValue( GetScrollPercentageY() )

		InvalidateLayout()
	End Method


	Method GetScrollPercentageY:Float()
		Return guiEntriesPanel.GetScrollPercentageY()
	End Method


	Method GetScrollPercentageX:Float()
		Return guiEntriesPanel.GetScrollPercentageX()
	End Method


	Method SetScrollPercentageX:Float(percentage:Float = 0.0)
		if percentage = guiEntriesPanel.GetScrollPercentageX() 
			Return percentage
		EndIf

		InvalidateLayout()


		rem
		'scroller displays "0 - 100%" along his axis
		'entries panel might be bigger than the container, to ensure
		'that the panel is always visible, percentage must take
		'content size and panel size into consideration
		Local panelScrollValue:Float = (abs(guiEntriesPanel.scrollLimit.GetX()) - GetContentScreenRect().GetW() )
		'turn negative if required (items scroll from right to left)
		panelScrollValue :*	sgn(guiEntriesPanel.scrollLimit.GetX())
		'avoid "bottom alignment" (if list being bigger than entries panel)
		panelScrollValue = Min(0, panelScrollValue)
		guiEntriesPanel.ScrollToX(panelScrollValue)
		endrem
		guiEntriesPanel.SetScrollPercentageX(percentage)


		If guiScrollerH Then guiScrollerH.SetRelativeValue(percentage)
		Return guiEntriesPanel.GetScrollPercentageX()
	End Method


	Method SetScrollPercentageY:Float(percentage:Float = 0.0)
		if percentage = guiEntriesPanel.GetScrollPercentageY() 
			Return percentage
		EndIf

		InvalidateLayout()

		rem
		'scroller displays "0 - 100%" along his axis
		'entries panel might be bigger than the container, to ensure
		'that the panel is always visible, percentage must take
		'content size and panel size into consideration
		Local panelScrollValue:Float = (abs(guiEntriesPanel.scrollLimit.GetY()) - GetContentScreenRect().GetH() )
		'turn negative if required (items scroll from bottom to top)
		panelScrollValue :*	sgn(guiEntriesPanel.scrollLimit.GetY())
		'avoid "bottom alignment" (if list being bigger than entries panel)
		panelScrollValue = Min(0, panelScrollValue)
		guiEntriesPanel.ScrollToY(panelScrollValue)
		endrem

		guiEntriesPanel.SetScrollPercentageY(percentage)

		If guiScrollerV Then guiScrollerV.SetRelativeValue( percentage )
		Return guiEntriesPanel.GetScrollPercentageY()
	End Method
	
	
	Method ScrollToItemIndex(index:Int, alignment:Float = 0.5)
		local item:TGUIObject = GetItemAtIndex(index)
		ScrollToItem(item, alignment)
	End Method


	'scroll to the given item
	'@alignment defines the location of the item in the list
	'             0.0 = top, 0.5 = center and 1.0 = bottom
	Method ScrollToItem(item:TGUIobject, alignment:Float = 0.5)
		if not item then return
		if not HasItem(item) then return
		
		'bottom alignment means the item must still be visible, so
		'maximum space to align along is "list height minus item height"
		local alignmentHeight:Int = Max(0, guiEntriesPanel.GetScreenRect().GetH() - item.rect.GetH())
		local alignmentWidth:Int = Max(0, guiEntriesPanel.GetScreenRect().GetW() - item.rect.GetW())

		'- move to top
		'- sum heights of all items until desired one
		'- scroll down to this height (item then is "on top")
		'  + include alignment offset (item then "where needed" )
		ScrollToFirstItem()
		
		local earlierItemsHeight:Int
		local earlierItemsWidth:Int
		For Local obj:TGUIObject = EachIn entries
			if obj = item then exit
			earlierItemsHeight :+ obj.rect.GetH()
			earlierItemsWidth :+ obj.rect.GetW()
		Next

		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				ScrollEntries(0, -(earlierItemsHeight - alignmentHeight * alignment))
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				ScrollEntries(-(earlierItemsWidth - alignmentWidth * alignment), 0)
		End Select
	End Method


	Method ScrollToFirstItem()
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				guiEntriesPanel.SetScrollPercentageY(0)
				If guiScrollerV Then guiScrollerV.SetRelativeValue(0)
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				guiEntriesPanel.SetScrollPercentageX(0)
				If guiScrollerH Then guiScrollerH.SetRelativeValue(0)
		End Select
	End Method


	Method ScrollToLastItem()
		Select _orientation
			Case GUI_OBJECT_ORIENTATION_VERTICAL
				guiEntriesPanel.SetScrollPercentageY(1.0)
				If guiScrollerV Then guiScrollerV.SetRelativeValue(1.0)
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				guiEntriesPanel.SetScrollPercentageX(1.0)
				If guiScrollerH Then guiScrollerH.SetRelativeValue(1.0)
		End Select
	End Method


	Function SortByCompare:Int(o1:Object,o2:Object)
		If Not TGUIObject(o1) Then Return 0
		Return o1.Compare(o2) 'is this safe for o2=null?
	End Function


	Function SortByValue:Int(o1:Object,o2:Object)
		If Not TGUIObject(o1) Then Return -1
		If Not TGUIObject(o2) Then Return 1
		If TGUIObject(o1).GetValue() > TGUIObject(o2).GetValue() Return 1
		Return 0
	End Function


	Method EnsureEntryIsVisible(item:TGUIObject)
		If Not item Then Return

		'if bottom of entry ends after bottom of list, ensure visibility
		'if bottom of last entry ends before bottom of list, try to scroll up a bit

		'positive distance = starting later
		'local bottomDistanceY:Int = GetScreenRect().GetY2() - (item.GetScreenRect().GetY() + item.rect.GetH())
		local bottomDistanceY:Int = guiEntriesPanel.GetScreenRect().GetY2() - (item.GetScreenRect().GetY() + item.rect.GetH())
		local topDistanceY:Int = item.GetScreenRect().GetY() - guiEntriesPanel.GetScreenRect().GetY()

		'first try to make top of entry visible (can be overriden by bottom then)
		if topDistanceY < 0 
			UpdateLimitsAndScrollerState()
			ScrollEntries(0, -topDistanceY)
		endif

		if bottomDistanceY < 0 
			UpdateLimitsAndScrollerState()
			ScrollEntries(0, bottomDistanceY)
		'space left to bottom
		elseif bottomDistanceY > 0 
			local lastItem:TGUIObject = GetLastItem() 'might be selectedEntry
			local lastItemBottomDistanceY:Int = guiEntriesPanel.GetScreenRect().GetY2() - (lastItem.GetScreenRect().GetY() + lastItem.rect.GetH())
			if lastItemBottomDistanceY > 0
				ScrollEntries(0, lastItemBottomDistanceY)
			endif
		endif
	End Method
	
	
	Method HandleKeyboardScrolling()
		If KeyWrapper.IsPressed(KEY_PAGEUP)
			Local contentParent:TGUIObject = Self
			If guiEntriesPanel Then contentParent = guiEntriesPanel

			ScrollEntries(0, contentParent.GetContentScreenRect().GetH())
'			SetScrollPercentageY(Min(1.0, GetScrollPercentageY() + 0.05))
		EndIf
		If KeyWrapper.IsPressed(KEY_PAGEDOWN)
			Local contentParent:TGUIObject = Self
			If guiEntriesPanel Then contentParent = guiEntriesPanel

			ScrollEntries(0, - contentParent.GetContentScreenRect().GetH())
'			SetScrollPercentageY(Max(0.0, GetScrollPercentageY() - 0.05))
		EndIf

		If KeyWrapper.IsPressed(KEY_HOME)
			local item:TGUIListItem = GetFirstItem()
			if item Then EnsureEntryIsVisible(item)
		ElseIf KeyWrapper.IsPressed(KEY_END)
			local item:TGUIListItem = GetLastItem()
			if item Then EnsureEntryIsVisible(item)
		EndIf

		If KeyWrapper.IsPressed(KEY_DOWN)
			Local scrollAmount:Int = 25
			'try to scroll by X percent of an item height
			Local item:TGUIObject = TGUIObject(self.entries.First())
			If item Then scrollAmount = item.rect.GetH() * self.scrollItemHeightPercentage

			ScrollEntries(0, -scrollAmount)
		ElseIf KeyWrapper.IsPressed(KEY_UP)
			Local scrollAmount:Int = 25
			'try to scroll by X percent of an item height
			Local item:TGUIObject = TGUIObject(self.entries.First())
			If item Then scrollAmount = item.rect.GetH() * self.scrollItemHeightPercentage

			ScrollEntries(0, +scrollAmount)
		EndIf
	End Method
	
	
	Method HandleKeyboard() override
		Super.HandleKeyboard()

		If IsHandlingKeyBoardScrolling()
			HandleKeyBoardScrolling()
		EndIf
	End Method
	
	
	Method IsHandlingKeyBoardScrolling:Int()
		'react if "activated" or no other element was focused but this
		'is hovered
		If HasListOption(GUILIST_SCROLLING_ENABLED)
			If IsFocused() or (not GUIManager.GetFocus() and IsHovered())
				Return True
			EndIf
		EndIf
		Return False
	End Method

	'override default update-method
	Method Update:Int()
		Super.Update()

		'enable/disable buttons of scrollers if they reached the
		'limits of the scrollable panel
		If guiScrollerH.hasOption(GUI_OBJECT_ENABLED)
			guiScrollerH.SetButtonStates(Not guiEntriesPanel.ReachedLeftLimit(), Not guiEntriesPanel.ReachedRightLimit())
		EndIf
		If guiScrollerV.hasOption(GUI_OBJECT_ENABLED)
			guiScrollerV.SetButtonStates(Not guiEntriesPanel.ReachedTopLimit(), Not guiEntriesPanel.ReachedBottomLimit())
		EndIf


		_mouseOverArea = THelper.MouseInRect(GetScreenRect())

		If hasListOption(GUILIST_AUTOHIDE_SCROLLER)
			If _mouseOverArea
				guiScrollerV.hide()
				guiScrollerH.hide()
			Else
				guiScrollerV.show()
				guiScrollerH.show()
			EndIf
		EndIf
	End Method


	Method DrawBackground()
		If guiBackground
			guiBackground.Draw()

'SetColor 255,0,0
'DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
'SetColor 255,255,255
		Else
			Local oldCol:SColor8; GetColor(oldCol)
			Local oldColA:Float = GetAlpha()
			
			If _mouseOverArea
				backgroundColorHovered.setRGBA()
			Else
				backgroundColor.setRGBA()
			EndIf
			If GetAlpha() > 0
				DrawRect(guiEntriesPanel.GetScreenRect().GetX(), ..
				         guiEntriesPanel.GetScreenRect().GetY(), ..
				         Min(rect.GetW(), guiEntriesPanel.rect.GetW()), ..
				         Min(rect.GetH(), guiEntriesPanel.rect.GetH()))
			EndIf

			SetColor(oldCol)
			SetAlpha(oldColA)
		EndIf
	End Method


	Method DrawContent()
	End Method


	Method DrawDebug()
		SetAlpha 0.5
'		SetColor 200,250,150
'		DrawRect(guiEntriesPanel.GetScreenRect().GetX()-50, guiEntriesPanel.GetScreenRect().GetY(), guiEntriesPanel.GetScreenRect().GetW(), guiEntriesPanel.GetScreenRect().GetH())
		SetColor 255,0,0
		DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
		SetColor 255,255,255
		SetAlpha 1.0

Rem
		Local oldCol:TColor = New TColor.Get()
		Local offset:Int = GetScreenRect().GetY()
		For Local entry:TGUIListItem = EachIn entries
			'move entry's y position to current one
			SetAlpha 0.5
			DrawRect(	GetScreenRect().GetX() + entry.rect.GetX(),..
						GetScreenRect().GetY() + entry.rect.GetY(),..
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
			DrawText(entry._id, GetScreenRect().GetX()-20 + entry.rect.GetX(), GetScreenRect().GetY() + entry.rect.GetY() )
			SetColor 255,255,255
		Next
		oldCol.SetRGBA()
endrem
	End Method


	'object was resized in width and/or height
	Method OnResize(dW:Float, dH:Float) override
		Super.OnResize(dW, dH)

		If guiBackground
			'background covers whole area, so resize it
			guiBackground.SetSize(rect.getW(), rect.getH())
		EndIf
	End Method


	Method OnReposition(dx:Float, dy:Float)
		Super.OnReposition(dx, dy)

		If dx <> 0 Or dy <> 0
			If guiBackground Then guiBackground.InvalidateScreenRect()
		EndIf
	End Method


	Method UpdateLayout()
		RecalculateElements()

		'cache enabled state of both scrollers
		Local showScrollerH:Int = 0<(guiScrollerH And guiScrollerH.hasOption(GUI_OBJECT_ENABLED))
		Local showScrollerV:Int = 0<(guiScrollerV And guiScrollerV.hasOption(GUI_OBJECT_ENABLED))
		'resize panel - but use resulting dimensions, not given (maybe restrictions happening!)
		If guiEntriesPanel
			'also set minsize so scroll works
			guiEntriesPanel.minSize.SetXY(..
				GetContentScreenRect().GetW() + _entriesBlockDisplacement.x - showScrollerV * guiScrollerV.GetScreenRect().GetW(),..
				GetContentScreenRect().GetH() + _entriesBlockDisplacement.y - showScrollerH * guiScrollerH.rect.getH()..
			)

			guiEntriesPanel.SetSize(..
				GetContentScreenRect().GetW() + _entriesBlockDisplacement.x - showScrollerV * guiScrollerV.rect.getW(),..
				GetContentScreenRect().GetH() + _entriesBlockDisplacement.y - showScrollerH * guiScrollerH.rect.getH()..
			)
		EndIf

		Local scrollerParent:TGUIObject = Self
		If guiEntriesPanel Then scrollerParent = guiEntriesPanel

		If guiScrollerH And Not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			If showScrollerV
				guiScrollerH.SetSize(scrollerParent.GetContentScreenRect().GetW() - guiScrollerV.GetScreenRect().GetW(), 0)
			Else
				guiScrollerH.SetSize(scrollerParent.GetContentScreenRect().GetW())
			EndIf
		EndIf
		If guiScrollerV And Not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			If showScrollerH
				guiScrollerV.SetSize(0, scrollerParent.GetContentScreenRect().GetH() - guiScrollerH.GetScreenRect().GetH() - 3)
			Else
				guiScrollerV.SetSize(0, scrollerParent.GetContentScreenRect().GetH())
'				guiScrollerV.InvalidateLayout()
			EndIf
		EndIf



		If guiScrollerH And Not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerH.SetPosition( _entriesBlockDisplacement.x, GetContentScreenRect().GetH() + _entriesBlockDisplacement.y - guiScrollerH.guiButtonMinus.rect.getH())
			guiScrollerH.InvalidateScreenRect()
		EndIf
		If guiScrollerV And Not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerV.SetPosition( GetContentScreenRect().GetW() + _entriesBlockDisplacement.x - guiScrollerV.guiButtonMinus.rect.getW(), _entriesBlockDisplacement.y)
			guiScrollerV.InvalidateScreenRect()
		EndIf


		'recalculate scroll limits etc.
		UpdateLimitsAndScrollerState()
	End Method
End Type




'basic list item
Type TGUIListItem Extends TGUIobject
	'how long until auto remove? (current value)
	Field lifetime:Long = 0
	'how long until auto remove? (initial value)
	Field initialLifetime:Int = 0
	'how long until hiding (current value)
	Field showtime:Long = 0
	'how long until hiding (initial value)
	Field initialShowtime:Int = 0
	'color of the displayed value
	Field valueColor:SColor8 = SColor8.Black
	Field extra:Object
	Field textCache:TBitmapFontText
	Field _drawTextEffect:TDrawTextEffect
	
	Field parentListID:Int = -1
	Field parentListPosition:Int = -1
	Field _listItemFlags:Int = 0


	Method GetClassName:String()
		Return "tguilistitem"
	End Method


	Method New()
		'by default maximize width
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
	End Method


    Method Create:TGUIListItem(pos:SVec2I, dimension:SVec2I, value:String="")
		'have a basic size (specify a dimension in your custom type)
		If dimension.x = 0 and dimension.y = 0 Then dimension = New SVec2I(80,20)

		'limit this items to nothing - as soon as we parent it, it will
		'follow the parents limits
   		Super.CreateBase(pos, dimension, "")

		SetValue(value)

		'make dragable
		SetOption(GUI_OBJECT_DRAGABLE, True)

		GUIManager.add(Self)

		Return Self
	End Method
	
	
	Method GetParentList:TGUIListBase()
		Return TGUIListBase.FindGUIListBaseParent(self)
	
		'alternative:
		'If TGUIPanel(_parent) Then Return TGUIListBase(TGUIPanel(sourceParent)._parent)
		'Return TGUIListBase(_parent)
	End Method
	

	Method SetValueEffect:Int(valueEffectType:Int, valueEffectSpecial:Float = 1.0)
		if not _drawTextEffect Then _drawTextEffect = new TDrawTextEffect

		Select valueEffectType
			case 1	_drawTextEffect.data.mode = EDrawTextEffect.Shadow
			case 2	_drawTextEffect.data.mode = EDrawTextEffect.Glow
			case 3	_drawTextEffect.data.mode = EDrawTextEffect.Emboss
			default _drawTextEffect.data.mode = EDrawTextEffect.None
		End Select
		
		_drawTextEffect.data.value = valueEffectSpecial
	End Method


	Method _UpdateScreenX:Float()
		If IsDragged() Then Return Super._UpdateScreenX()

		Local listParent:TGUIListBase = TGUIListBase.FindGUIListBaseParent(self)
		If Not listParent Or Not listParent.guiEntriesPanel
			If _parent
				_screenRect.SetX( _parent.GetContentScreenRect().GetX() + rect.GetX() )
			Else
				_screenRect.SetX( rect.GetX() )
			EndIf
		Else
			'incorporate the scrolling offset
			_screenRect.SetX( listParent.guiEntriesPanel.GetContentScreenRect().GetX() + listParent.guiEntriesPanel.scrollPosition.GetX() + rect.GetX() )
		EndIf

		Return _screenRect.GetX()
	End Method


	Method _UpdateScreenY:Float()
		If IsDragged() Then Return Super._UpdateScreenY()

		Local listParent:TGUIListBase = TGUIListBase.FindGUIListBaseParent(self)
		If Not listParent Or Not listParent.guiEntriesPanel
			If _parent
				_screenRect.SetY( _parent.GetContentScreenRect().GetY() + rect.GetY() )
			Else
				_screenRect.SetY( rect.GetY() )
			EndIf
		Else
			_screenRect.SetY( listParent.guiEntriesPanel.GetContentScreenRect().GetY() + listParent.guiEntriesPanel.scrollPosition.getY() + rect.GetY() )
		EndIf

		Return _screenRect.GetY()
	End Method


	Method _UpdateScreenW:Float()
		Local listParent:TGUIListBase = TGUIListBase.FindGUIListBaseParent(self)
		If Not listParent Or Not listParent.guiEntriesPanel
			If _parent and HasListItemOption(GUILISTITEM_AUTOSIZE_WIDTH)
				_screenRect.SetW( _parent.GetScreenRect().GetW() )
			Else
				_screenRect.SetW( rect.GetW() )
			EndIf
		Else
			if HasListItemOption(GUILISTITEM_AUTOSIZE_WIDTH)
				_screenRect.SetW( listParent.guiEntriesPanel.GetScreenRect().GetW() )
			else
				_screenRect.SetW( rect.GetW() )
			endif
		EndIf

		Return _screenRect.GetW()
	End Method


	Method _UpdateContentScreenW:Float()
		Local listParent:TGUIListBase = TGUIListBase.FindGUIListBaseParent(self)
		If Not listParent Or Not listParent.guiEntriesPanel
			If _parent and HasListItemOption(GUILISTITEM_AUTOSIZE_WIDTH)
				_contentScreenRect.SetW( _parent.GetContentScreenRect().GetW() )
			Else
				_screenRect.SetW( rect.GetW() )
			EndIf
		Else
			If HasListItemOption(GUILISTITEM_AUTOSIZE_WIDTH)
				_contentScreenRect.SetW( listParent.guiEntriesPanel.GetContentScreenRect().GetW() )
			Else
				_screenRect.SetW( rect.GetW() )
			EndIf
		EndIf
		Return _contentScreenRect.GetW()
	End Method


	Method Remove:Int()
		Super.Remove()

		'also remove itself from the list it may belong to
		'this adds the object back to the guimanager
		Local guiList:TGUIListBase = TGUIListBase.FindGUIListBaseParent(_parent)
		If guiList And guiList.HasItem(Self) Then guiList.RemoveItem(Self)
		Return True
	End Method


	Method onMouseScrollWheel:Int( triggerEvent:TEventBase ) override
		'redirect mouse scrolling to parent list
		If not IsDragged()
			Local guiList:TGUIListBase = TGUIListBase.FindGUIListBaseParent(_parent)
			If guiList And guiList.HasItem(Self) 
				Return guiList.onMouseScrollWheel(triggerEvent)
			EndIf
		EndIf
		
		Return super.onMouseScrollWheel(triggerEvent)
	End Method


	Method SetExtra:TGUIListItem(extra:Object)
		Self.extra = extra
		Return Self
	End Method


	'override onClick to emit a special event
	Method OnClick:Int(triggerEvent:TEventBase) override
		Super.OnClick(triggerEvent)

		Local data:TData = triggerEvent.GetData()
		If Not data Then Return False

		'skip reaction if parental list is disabled
		If TGUIListBase.FindGUIListBaseParent(Self) And Not TGUIListBase.FindGUIListBaseParent(Self).IsEnabled() Then Return False

		'only react on clicks with left mouse button
		If data.getInt("button") <> 1 Then Return False

		'we handled the click
		triggerEvent.SetAccepted(True)

		If isDragged()
			'instead of using auto-coordinates, we use the coord of the
			'mouseposition when the "hit" started
			'drop(new TVec2D(data.getInt("x",-1), data.getInt("y",-1)))
			Drop(MouseManager.GetClickPosition(1))
		Else
			'same for dragging
			'drag(new TVec2D(data.getInt("x",-1), data.getInt("y",-1)))
			Drag(MouseManager.GetClickPosition(1))
		EndIf

		'inform others that a selectlistitem was clicked
		'this makes the "listitem-clicked"-event filterable even
		'if the itemclass gets extended (compared to the general approach
		'of "GUIobject_onclick")
		TriggerBaseEvent(GUIEventKeys.GUIListItem_OnClick, new TData.Add("button", 1), Self, triggerEvent.GetReceiver())
		
		Return True
	End Method


	Method SetValueColor:Int(color:SColor8)
		If self.valueColor <> color
			if textCache Then textCache.Invalidate()
			self.valueColor = color
		EndIf
	End Method


	Method SetValueColor:Int(color:TColor=Null)
		if color and color.ToSColor8() <>  valueColor
			if textCache then textCache.Invalidate()

			valueColor = color.ToSColor8()
		EndIf
	End Method


	Method SetValue(value:String)
		if self.value <> value
			if textCache then textCache.Invalidate()

			Super.SetValue(value)
		EndIf
	End Method


	Method SetLifetime:Int(milliseconds:Int=Null)
		If milliseconds
			initialLifetime = milliseconds
			lifetime = Time.GetTimeGone() + milliseconds
		Else
			initialLifetime = Null
			lifetime = Null
		EndIf
	End Method


	Method Show()
		SetShowtime(initialShowtime)
		Super.Show()
	End Method


	Method SetShowtime:Int(milliseconds:Int=Null)
		If milliseconds
			InitialShowtime = milliseconds
			showtime = Time.GetTimeGone() + milliseconds
		Else
			InitialShowtime = 0
			showtime = 0
		EndIf
	End Method


	Method HasListItemOption:Int(option:Int)
		Return (_listItemFlags & option) <> 0
	End Method


	Method SetListItemOption(option:Int, enable:Int=True)
		If enable
			_listItemFlags :| option
		Else
			_listItemFlags :& ~option
		EndIf
	End Method


	Method onParentResize:Int()
		If HasListItemOption(GUILISTITEM_AUTOSIZE_WIDTH) And _parent
			SetSize(_parent.GetContentScreenRect().GetW(), -1)
			Return True
		EndIf

		Return Super.onParentResize()
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'if the item has a lifetime it will autoremove on death
		If lifetime And (Time.GetTimeGone() > lifetime) Then Return Remove()

		If showtime And isVisible()
			If (Time.GetTimeGone() > showtime) Then hide()
		EndIf
	End Method


	Method Draw()
		If Not isDragged()
			'this allows to use a list in a modal dialogue
			Local upperParent:TGUIObject = TGUIListBase.FindGUIListBaseParent(Self)
			If upperParent Then upperParent.RestrictViewPort()

			Super.Draw()

			If upperParent Then upperParent.ResetViewPort()
		Else
			Super.Draw()
		EndIf
	End Method


	Method DrawValue()
		'draw value
		Local maxWidth:Int
		if _parent
			maxWidth = _parent.GetContentScreenRect().GetW() - rect.getX()
		else
			maxWidth = rect.GetW()
		endif
		local scrRect:TRectangle = GetScreenRect()

		if not textCache then textCache = new TBitmapFontText

		textCache.DrawBlock(GetFont(), value + " [" + Self._id + "]", Int(scrRect.GetX() + 5), Int(scrRect.GetY() + 2 + 0.5*(rect.getH() - GetFont().getHeight(value))), maxWidth-2, int(rect.GetH()), contentAlignment, valueColor, _drawTextEffect, null)
	End Method


	Method DrawContent()
		DrawValue()
	End Method


	Method UpdateLayout()
	End Method
End Type
