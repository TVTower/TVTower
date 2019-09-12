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
	Field entriesDimension:TVec2D = New TVec2D.Init(0,0)

	Field _listFlags:Int = 0
	Field _autoSortFunction:int(o1:Object,o2:Object)
	Field _autoSortInAscendingOrder:int = True

	'amount (percentage) a list is scrolled based on item height
	Field scrollItemHeightPercentage:Float = 0.5

	Field entries:TList	= CreateList()
	Field entriesLimit:Int = -1
	'private mouseover-field (ignoring covering child elements)
	Field _mouseOverArea:Int = False
	Field _dropOnTargetListenerLink:TLink = Null
	'displace each entry by (z-value is stepping)...
	Field _entryDisplacement:TVec3D	= New TVec3D.Init(0, 0, 1)
	'displace the entriesblock by x,y...
	Field _entriesBlockDisplacement:TVec2D = New TVec2D.Init(0, 0)
	'orientation of the list: 0 means vertical, 1 is horizontal
	Field _orientation:Int = 0


	Method New()
		setListOption(GUILIST_AUTOSCROLL, False)
		setListOption(GUILIST_AUTOHIDE_SCROLLER, False)
		setListOption(GUILIST_MULTICOLUMN, False)
		setListOption(GUILIST_AUTOSORT_ITEMS, True)
		setListOption(GUILIST_SCROLL_TO_BEGIN_WITHOUT_SCROLLBARS, True)
		'by default all lists accept drop
		setOption(GUI_OBJECT_ACCEPTS_DROP, True)
	End Method


    Method Create:TGUIListBase(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.CreateBase(position, dimension, limitState)

		setZIndex(0)

		guiScrollerH = New TGUIScroller.Create(Self)
		guiScrollerV = New TGUIScroller.Create(Self)
		'orientation of horizontal scroller has to get set manually
		guiScrollerH.SetOrientation(GUI_OBJECT_ORIENTATION_HORIZONTAL)

		guiEntriesPanel = New TGUIScrollablePanel.Create(Null, New TVec2D.Init(rect.GetW() - guiScrollerV.rect.getW(), rect.GetH() - guiScrollerH.rect.getH()), Self.state)

		'manage by our own
		AddChild(guiEntriesPanel)
		AddChild(guiScrollerH)
		AddChild(guiScrollerV)


		'by default all lists do not have scrollers
		setScrollerState(False, False)

		'the entries panel cannot be focused
		guiEntriesPanel.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)


		'register events
		'someone uses the mouse wheel to scroll over the panel
		AddEventListener(EventManager.registerListenerFunction( "guiobject.OnScrollwheel", onScrollWheel, Self))
		'- we are interested in certain events from the scroller or self
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScroll, guiScrollerH ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScroll, guiScrollerV ))
		AddEventListener(EventManager.registerListenerFunction( "guiobject.onScrollPositionChanged", onScroll, Self ))


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
			RecalculateElements()
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
			guiBackground.setParent(Self)
			'set to unmanaged in all cases
			GUIManager.remove(guiBackground)
		EndIf
	End Method


	'when reskinned, resize to move scrollbars accordingly
	Method onStatusAppearanceChange:Int()
		Resize(-1,-1)
	End Method


	'override resize and add minSize-support
	'size 0, 0 is not possible (leads to autosize)
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w,h)

		'cache enabled state of both scrollers
		Local showScrollerH:Int = 0<(guiScrollerH And guiScrollerH.hasOption(GUI_OBJECT_ENABLED))
		Local showScrollerV:Int = 0<(guiScrollerV And guiScrollerV.hasOption(GUI_OBJECT_ENABLED))

		'resize panel - but use resulting dimensions, not given (maybe restrictions happening!)
		If guiEntriesPanel
			'also set minsize so scroll works
			guiEntriesPanel.minSize.SetXY(..
				GetContentScreenWidth() + _entriesBlockDisplacement.x - showScrollerV*guiScrollerV.GetScreenWidth(),..
				GetContentScreenHeight() + _entriesBlockDisplacement.y - showScrollerH*guiScrollerH.rect.getH()..
			)

			guiEntriesPanel.Resize(..
				GetContentScreenWidth() + _entriesBlockDisplacement.x - showScrollerV * guiScrollerV.rect.getW(),..
				GetContentScreenHeight() + _entriesBlockDisplacement.y - showScrollerH * guiScrollerH.rect.getH()..
			)
		EndIf

		'move regardless of "showScrollerX" as you might resize elements without
		'showing them yet
		'move horizontal scroller --
		'If showScrollerH And Not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
		If guiScrollerH And Not guiScrollerH.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerH.SetPosition( _entriesBlockDisplacement.x, GetContentScreenHeight() + _entriesBlockDisplacement.y - guiScrollerH.guiButtonMinus.rect.getH())
			If showScrollerV
				guiScrollerH.Resize(GetScreenWidth() - guiScrollerV.GetScreenWidth(), 0)
			Else
				guiScrollerH.Resize(GetScreenWidth())
			EndIf
		EndIf
		'move vertical scroller |
		'move regardless of "showScrollerV" as you might resize elements without
		'showing them yet
		'If showScrollerV And Not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
		If guiScrollerV And Not guiScrollerV.hasOption(GUI_OBJECT_POSITIONABSOLUTE)
			guiScrollerV.SetPosition( GetContentScreenWidth() + _entriesBlockDisplacement.x - guiScrollerV.guiButtonMinus.rect.getW(), _entriesBlockDisplacement.y)
			If showScrollerH
				guiScrollerV.Resize(0, GetContentScreenHeight() - guiScrollerH.GetScreenHeight() - 3)
			Else
				guiScrollerV.Resize(0, GetContentScreenHeight())
			EndIf
		EndIf

		If guiBackground
			'move background by negative padding values ( -> ignore padding)
			guiBackground.rect.position.setXY(-GetPadding().getLeft(), -GetPadding().getTop())

			'background covers whole area, so resize it
			guiBackground.resize(rect.getW(), rect.getH())
		EndIf

		'recalculate scroll limits etc.
		UpdateLimitsAndScrollerState()

		'let the children properly refresh their size
		'(eg. because the scrollbars are visible now)
		For Local entry:TGUIobject = EachIn entries
			entry.onParentResize()
		Next
	End Method


	Method SetAcceptDrop:Int(accept:Object)
		'if we registered already - remove the old one
		If _dropOnTargetListenerLink Then EventManager.unregisterListenerByLink(_dropOnTargetListenerLink)

		'is something dropping - check if it is this list
		_dropOnTargetListenerLink = EventManager.registerListenerFunction( "guiobject.onDropOnTarget", onDropOnTarget, accept, Self)
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
			'quit as soon as the
			'entry is out of range...
			If entry.GetScreenY() > GetScreenY()+GetScreenHeight() Then Return Null
			If entry.GetScreenX() > GetScreenX()+GetScreenWidth() Then Return Null

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
		'Local dimension:TVec2D = item.getDimension()

		EventManager.triggerEvent(TEventSimple.Create("guiList.addItem", New TData.Add("item", item) , Self))

		entries.addLast(item)

		'resize item
		If item Then item.onParentResize()

		'run the custom compare method
		If hasListOption(GUILIST_AUTOSORT_ITEMS)
			if _autoSortFunction
				entries.sort(_autoSortInAscendingOrder, _autoSortFunction)
			else
				entries.sort(_autoSortInAscendingOrder)
			endif
		EndIf

		EventManager.triggerEvent(TEventSimple.Create("guiList.addedItem", New TData.Add("item", item) , Self))

		Return True
	End Method


	'base handling of remove item
	Method _RemoveItem:Int(item:TGUIobject)
		If entries.Remove(item)
			EventManager.triggerEvent(TEventSimple.Create("guiList.removeItem", New TData.Add("item", item) , Self))

			'remove from panel and item gets managed by guimanager
			guiEntriesPanel.removeChild(item)

			EventManager.triggerEvent(TEventSimple.Create("guiList.removedItem", New TData.Add("item", item) , Self))

			Return True
		Else
			DebugStop
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


	Method IsAtListBottom:Int()
		Local result:Int = 1 > Floor(Abs(guiEntriesPanel.scrollLimit.GetY() - guiEntriesPanel.scrollPosition.getY()))

		'if all items fit on the screen, scroll limit will be
		'lower than the container panel
		If Abs(guiEntriesPanel.scrollLimit.GetY()) < guiEntriesPanel.GetScreenHeight()
			'if scrolled = 0 this could also mean we scrolled up to the top part
			'in this case we check if the last item in the list fits into the
			'panel
			If guiEntriesPanel.scrollPosition.getY() = 0
				result = 1
				Local lastItem:TGUIListItem = GetLastItem()
				If lastItem And lastItem.GetScreenY() > guiEntriesPanel.getScreenY() + guiEntriesPanel.getScreenheight()
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
		If i Then Return i.GetScreenY()
		Return 0
	End Method


	'recalculate scroll maximas, item positions...
	Method RecalculateElements:Int()
		Local startPos:TVec2D = _entriesBlockDisplacement.copy()
		Local entryNumber:Int = 1
		Local nextPos:TVec2D = startPos.copy()
		Local currentPos:TVec2D
		Local columnPadding:Int = 5

		'reset current entriesDimension ...
		entriesDimension.CopyFrom(_entriesBlockDisplacement)

		For Local entry:TGUIobject = EachIn entries
			currentPos = nextPos.copy()

			'==== CALCULATE POSITION ====
			Select _orientation
				'only from top to bottom
				Case GUI_OBJECT_ORIENTATION_VERTICAL
					'MultiColumn: from left to right, if space left a
					'             new column on the right is started.

					'advance the next position starter
					If hasListOption(GUILIST_MULTICOLUMN)
						'if entry does not fit, try the next line
						If currentPos.GetX() + entry.rect.GetW() > GetContentScreenWidth()
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
						If currentPos.GetY() + entry.rect.GetH() > GetContentScreenHeight()
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
			entry.rect.position.CopyFrom(currentPos)

			entryNumber:+1
		Next


		UpdateLimitsAndScrollerState()
	End Method


	Method UpdateLimitsAndScrollerState()
		if guiEntriesPanel
			'resize container panel
			guiEntriesPanel.resize(entriesDimension.getX(), entriesDimension.getY())

			'refresh scrolling limits
			RefreshListLimits()

			'if not all entries fit on the panel, enable scroller
			SetScrollerState(..
				entriesDimension.getX() > guiEntriesPanel.GetScreenWidth(), ..
				entriesDimension.getY() > guiEntriesPanel.GetScreenHeight() ..
			)
		endif
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
				If entriesDimension.getY() <= guiEntriesPanel.getScreenheight()
					'if there are only some elements, they might be
					'"less high" than the available area - no need to
					'align them at the bottom
					guiEntriesPanel.SetLimits(0, -entriesDimension.getY())
				Else
					'maximum is at the bottom of the area, not top - so
					'subtract height
					'old: guiEntriesPanel.SetLimits(0, -(dimension.getY() - guiEntriesPanel.getScreenheight()) )
					Local lastItem:TGUIListItem = GetLastItem()
					If Not lastItem And GetLastItemY() = 0
						guiEntriesPanel.SetLimits(0, 0)
					Else
'						if not autoScroll
'							guiEntriesPanel.SetLimits(0, - (dimension.getY() - guiEntriesPanel.getScreenheight() - lastItem.GetScreenHeight()))
'						else
							guiEntriesPanel.SetLimits(0, - (entriesDimension.getY() - guiEntriesPanel.getScreenheight()))
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
				If entriesDimension.getX() < guiEntriesPanel.getScreenWidth()
					'if there are only some elements, they might be
					'"less high" than the available area - no need to
					'align them at the right
					guiEntriesPanel.SetLimits(-entriesDimension.getX(), 0 )
				Else
					'maximum is at the bottom of the area, not top - so
					'subtract height
					'old: guiEntriesPanel.SetLimits(-(dimension.getX() - guiEntriesPanel.getScreenWidth()), 0)
					Local lastItem:TGUIListItem = GetLastItem()
					If Not lastItem
						guiEntriesPanel.SetLimits(0, 0)
					Else
						guiEntriesPanel.SetLimits(- (entriesDimension.getX() - guiEntriesPanel.getScreenWidth() - lastItem.GetScreenWidth()), 0)
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
		If changed Then Resize()
	End Method


	Function FindGUIListBaseParent:TGUIListBase(guiObject:TGUIObject)
		If Not guiObject Then Return Null

		Local guiList:TGUIListBase = TGUIListBase(guiObject)
		If guiList Then Return guiList

		Local obj:TGUIObject = guiObject.GetParent()
		While obj <> guiObject And Not TGUIListBase(obj)
			obj = obj.GetParent()
		Wend
		Return TGUIListBase(obj)
	End Function


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
		Local fromList:TGUIListBase = FindGUIListBaseParent(item._parent)
		'if not fromList then return FALSE

		Local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		If Not toList Then Return False

		Local data:TData = triggerEvent.getData()
		If Not data Then Return False

		If fromList = toList
			'if the handler took care of everything, we skip
			'removing and adding the item
			If fromList.HandleDropBack(triggerEvent)
				'inform others about that dropback
				EventManager.triggerEvent( TEventSimple.Create("guiobject.onDropBack", Null , item, toList))
				Return True
			EndIf
			'no drop back?
			'we might have dropped it on another slot/position
		EndIf
'method A
		'move item if possible
		If fromList Then fromList.removeItem(item)
		'try to add the item, if not able, readd
		If Not toList.addItem(item, data)
			If fromList And fromList.addItem(item) Then Return True

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
			Return False
		EndIf


'method B
Rem
		'-> this does not work as an "removal" might start things
		'   the "add" needs to know
		'also a list might only be able to add the object if that
		'got removed before (multi slots, or some other behaviour)

		'try to add the item, if able, remove from prior one
		local doMove:int = True
		If toList.addItem(item, data) and fromList
			if not fromList.removeItem(item) then triggerEvent.setVeto()
		endif
endrem

		Return True
	End Function


	'handle clicks on the up/down-buttons and inform others about changes
	Function onScrollWheel:Int( triggerEvent:TEventBase )
		Local list:TGUIListBase = TGUIListBase(triggerEvent.GetSender())
		Local value:Int = triggerEvent.GetData().getInt("value",0)
		If Not list Or value=0 Then Return False
		'emit event that the scroller position has changed
		Local direction:String = ""
		Select list._orientation
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
			If list.entries.Count() > 0 Then item = TGUIObject(list.entries.First())
			If item Then scrollAmount = item.rect.GetH() * list.scrollItemHeightPercentage

			EventManager.triggerEvent(TEventSimple.Create("guiobject.onScrollPositionChanged", New TData.AddString("direction", direction).AddNumber("scrollAmount", scrollAmount), list))
		EndIf
		'set to accepted so that nobody else receives the event
		triggerEvent.SetAccepted(True)
	End Function


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
				Local itemHeight:Int = Max(currentItem.rect.GetH(), currentItem.GetScreenHeight())
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
		If data.getString("changeType") = "percentage"
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
		guiEntriesPanel.scrollBy(dx,dy)

		'refresh scroller values (for "progress bar" on the scroller)
		If dx <> 0 Then guiScrollerH.SetRelativeValue( GetScrollPercentageX() )
		If dy <> 0 Then guiScrollerV.SetRelativeValue( GetScrollPercentageY() )
	End Method


	Method GetScrollPercentageY:Float()
		Return guiEntriesPanel.GetScrollPercentageY()
	End Method


	Method GetScrollPercentageX:Float()
		Return guiEntriesPanel.GetScrollPercentageX()
	End Method


	Method SetScrollPercentageX:Float(percentage:Float = 0.0)
		guiScrollerH.SetRelativeValue(percentage)
		Return guiEntriesPanel.SetScrollPercentageX(percentage)
	End Method


	Method SetScrollPercentageY:Float(percentage:Float = 0.0)
		guiScrollerH.SetRelativeValue(percentage)
		Return guiEntriesPanel.SetScrollPercentageY(percentage)
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
				guiEntriesPanel.SetScrollPercentageY(100)
				If guiScrollerV Then guiScrollerV.SetRelativeValue(100)
			Case GUI_OBJECT_ORIENTATION_HORIZONTAL
				guiEntriesPanel.SetScrollPercentageX(100)
				If guiScrollerH Then guiScrollerH.SetRelativeValue(100)
		End Select
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'update all children (and therefore items of the guientriespanel)
		'now done by basic "Update" already
		'UpdateChildren()

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
		Else
			Local oldCol:TColor = New TColor.Get()
			Local rect:TRectangle = New TRectangle.Init(guiEntriesPanel.GetScreenX(), guiEntriesPanel.GetScreenY(), Min(rect.GetW(), guiEntriesPanel.rect.GetW()), Min(rect.GetH(), guiEntriesPanel.rect.GetH()) )

			If _mouseOverArea
				backgroundColorHovered.setRGBA()
			Else
				backgroundColor.setRGBA()
			EndIf
			If GetAlpha() > 0
				DrawRect(rect.GetX(), rect.GetY(), rect.GetW(), rect.GetH())
			EndIf

			oldCol.SetRGBA()
		EndIf
	End Method


	Method DrawContent()
		'
	End Method


	Method DrawDebug()
		If _debugMode
			SetAlpha 0.2
			Local rect:TRectangle = New TRectangle.Init(guiEntriesPanel.GetScreenX(), guiEntriesPanel.GetScreenY(), Min(rect.GetW(), guiEntriesPanel.rect.GetW()), Min(rect.GetH(), guiEntriesPanel.rect.GetH()) )
			DrawRect(rect.GetX(), rect.GetY(), rect.GetW(), rect.GetH())
			SetColor 255,0,0
			DrawRect(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())
			SetColor 255,255,255
			SetAlpha 1.0

			Local oldCol:TColor = New TColor.Get()
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
			oldCol.SetRGBA()
		EndIf
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
	Field valueColor:TColor	= New TColor
	Field extra:object

	Field positionNumber:Int = 0
	Field _listItemFlags:Int = 0


	Method New()
		'by default maximize width
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)
	End Method


    Method Create:TGUIListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		'have a basic size (specify a dimension in your custom type)
		If Not dimension Then dimension = New TVec2D.Init(80,20)

		'limit this items to nothing - as soon as we parent it, it will
		'follow the parents limits
   		Super.CreateBase(pos, dimension, "")

		SetValue(value)

		'make dragable
		SetOption(GUI_OBJECT_DRAGABLE, True)

		GUIManager.add(Self)

		Return Self
	End Method


	Method Remove:Int()
		Super.Remove()

		'also remove itself from the list it may belong to
		'this adds the object back to the guimanager
		Local guiList:TGUIListBase = TGUIListBase.FindGUIListBaseParent(Self._parent)
		If guiList And guiList.HasItem(Self) Then guiList.RemoveItem(Self)
		Return True
	End Method


	Method SetExtra:TGUIListItem(extra:object)
		self.extra = extra
		return self
	End Method


	'override onClick to emit a special event
	Method OnClick:Int(triggerEvent:TEventBase)
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
			'drop(new TVec2D.Init(data.getInt("x",-1), data.getInt("y",-1)))
			drop(MouseManager.GetClickPosition(1))
		Else
			'same for dragging
			'drag(new TVec2D.Init(data.getInt("x",-1), data.getInt("y",-1)))
			drag(MouseManager.GetClickPosition(1))
		EndIf

		'inform others that a selectlistitem was clicked
		'this makes the "listitem-clicked"-event filterable even
		'if the itemclass gets extended (compared to the general approach
		'of "guiobject.onclick")
		EventManager.triggerEvent(TEventSimple.Create("GUIListItem.onClick", Null, Self, triggerEvent.GetReceiver()) )
	End Method

Rem
	'override to ask list first
	Method IsClickable:int()
		Local parent:TGUIobject = Self._parent
		If TGUIPanel(parent) Then parent = TGUIPanel(parent)._parent
		If TGUIScrollablePanel(parent) Then parent = TGUIScrollablePanel(parent)._parent
		If TGUIListBase(_parent) and not _parent.IsClickable() then return False

		return Super.IsClickable()
	End Method
endrem

	'override default
	Method onHit:Int(triggerEvent:TEventBase)
	End Method


	Method SetValueColor:Int(color:TColor=Null)
		valueColor = color
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
		If HasListItemOption(GUILISTITEM_AUTOSIZE_WIDTH)
			Self.Resize(GetParent().GetContentScreenWidth(), -1)
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
		Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		GetFont().drawBlock(value + " [" + Self._id + "]", GetScreenX() + 5, GetScreenY() + 2 + 0.5*(rect.getH() - GetFont().getHeight(value)), maxWidth-2, rect.GetH(), Null, valueColor)
	End Method


	Method DrawContent()
		DrawValue()
	End Method
End Type