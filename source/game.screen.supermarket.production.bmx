SuperStrict
Import "Dig/base.gfx.gui.window.modal.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "Dig/base.gfx.gui.dropdown.bmx"
Import "Dig/base.gfx.gui.slider.bmx"
Import "Dig/base.gfx.gui.checkbox.bmx"
Import "Dig/base.gfx.gui.list.base.bmx"
Import "Dig/base.gfx.gui.list.slotlist.bmx"

Import "common.misc.datasheet.bmx"
Import "game.person.base.bmx"
Import "game.production.productionconcept.bmx"
Import "game.production.productionconcept.gui.bmx"
Import "game.production.productionmanager.bmx"
Import "game.screen.base.bmx"
Import "game.player.finance.bmx"


Type TScreenHandler_SupermarketProduction Extends TScreenHandler
	Global productionFocusSlider:TGUISlider[6]
	Global productionFocusLabel:String[6]
	Global editTextsButton:TGUIButton
	Global editTextsWindow:TGUIProductionEditTextsModalWindow
	Global finishProductionConcept:TGUIButton
	Global productionConceptList:TGUISelectList
	Global productionConceptTakeOver:TGUICheckbox
	Global productionCompanySelect:TGUIDropDown
	Global castSlotList:TGUICastSlotList

	Field repositionSliders:Int = True
	'set to true and production GUI changes wont affect logic
	Field refreshingProductionGUI:Int = False
	Field refreshFinishProductionConcept:Int = True

	Field currentProductionConcept:TProductionConcept

	Global hoveredGuiCastItem:TGUICastListItem
	Global hoveredGuiProductionConcept:TGuiProductionConceptListItem

	Global _eventListeners:TEventListenerBase[]
	Global _instance:TScreenHandler_SupermarketProduction


	Function GetInstance:TScreenHandler_SupermarketProduction()
		If Not _instance Then _instance = New TScreenHandler_SupermarketProduction
		Return _instance
	End Function


	Method Initialize:Int()
		Local screen:TScreen = ScreenCollection.GetScreen("screen_supermarket_production")
		If Not screen Then Return False

		'=== CREATE ELEMENTS ===
		InitCustomProductionElements()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]

		'=== register event listeners
		'GUI -> GUI
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickCastItem, "TGUICastListItem") ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickEditTextsButton, "TGUIButton") ]
		'we want to know if we hover a specific block
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverCastItem, "TGUICastListItem" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverProductionConceptItem, "TGuiProductionConceptSelectListItem" ) ]



		'GUI -> LOGIC
		'finish planning/make production ready
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickFinishProductionConcept, "TGUIButton") ]
		'changes to the cast (slot) list
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.addedItem", onProductionConceptChangeCastSlotList, "TGUICastSlotList" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.removedItem", onProductionConceptChangeCastSlotList, "TGUICastSlotList" ) ]
		'changes to production focus sliders
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onChangeValue", onProductionConceptChangeFocusSliders, "TGUISlider" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onSetFocus", onProductionConceptSetFocusSliderFocus, "TGUISlider" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onRemoveFocus", onProductionConceptRemoveFocusSliderFocus, "TGUISlider" ) ]
		'changes to production company dropdown
		_eventListeners :+ [ EventManager.registerListenerFunction("GUIDropDown.onSelectEntry", onProductionConceptChangeProductionCompanyDropDown, "TGUIDropDown" ) ]
		'changes to production company levels / skill points
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionCompany.OnChangeLevel", onProductionCompanyChangesLevel ) ]
		'select a production concept
		_eventListeners :+ [ EventManager.registerListenerFunction("GUISelectList.onSelectEntry", onSelectProductionConcept) ]
		'edit title/description
		_eventListeners :+ [ EventManager.registerListenerFunction("guiModalWindow.onClose", onCloseEditTextsWindow, "TGUIProductionEditTextsModalWindow") ]


		'LOGIC -> GUI
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionConcept.SetCast", onProductionConceptChangeCast ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionConcept.SetProductionCompany", onProductionConceptChangeProductionCompany ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionFocus.SetFocus", onProductionConceptChangeProductionFocus ) ]

		'to reload concept list when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterScreen, screen) ]

		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )
	End Method


	Method RemoveAllGuiElements:Int()
		productionConceptList.EmptyList()
		productionCompanySelect.list.EmptyList()
		castSlotList.EmptyList()

		hoveredGuiProductionConcept = Null
		hoveredGuiCastItem = Null

'		'to recreate everything during next update...
	End Method


	Method SetLanguage()
	End Method


	Method AbortScreenActions:Int()
		If castSlotList.SelectCastWindowIsOpen()
			castSlotList.selectCastWindow.Close(2)
		EndIf
		SetCurrentProductionConcept(Null)
	End Method


	Function onUpdate:Int( triggerEvent:TEventBase )
		GetInstance().Update()
	End Function


	Function onDraw:Int( triggerEvent:TEventBase )
		GetInstance().Render()
	End Function


	Function onEnterScreen:Int( triggerEvent:TEventBase )
		GetInstance().ReloadProductionConceptContent()
	End Function


	'reset gui elements to their initial state (new production)
	Method ResetProductionConceptGUI()
		refreshingProductionGUI = True

		For Local i:Int = 0 To productionFocusSlider.length -1
			productionFocusSlider[i].SetValue(0)
		Next

		productionCompanySelect.SetValue("Produktionsfirma")

		'cast: remove old entries
		castSlotList.EmptyList()

		'reselect currently selected production concept
		Local selectedGuiConcept:TGuiProductionConceptSelectListItem = TGuiProductionConceptSelectListItem(productionConceptList.GetSelectedEntry())
		If selectedGuiConcept And selectedGuiConcept.productionConcept <> currentProductionConcept
			productionConceptList.DeselectEntry()
		EndIf

		refreshingProductionGUI = False
	End Method


	Method RefreshFinishProductionConceptGUI()
		If Not currentProductionConcept
			finishProductionConcept.Disable()
			finishProductionConcept.spriteName = "gfx_gui_button.datasheet"
			finishProductionConcept.SetValue("")

			Return
		EndIf

		If currentProductionConcept.IsProduceable()
			finishProductionConcept.Disable()
			finishProductionConcept.spriteName = "gfx_gui_button.datasheet.informative"

			finishProductionConcept.SetValue("|b|"+GetLocale("FINISHED_PLANNING")+"|/b|")
		ElseIf currentProductionConcept.IsPlanned()
			finishProductionConcept.Enable()
			'TODO: positive/negative je nach Geldstand
			finishProductionConcept.spriteName = "gfx_gui_button.datasheet.positive"
			finishProductionConcept.SetValue("|b|"+GetLocale("FINISH_PLANNING")+"|/b|~n" + GetLocale("AND_PAY_DOWN_MONEY").Replace("%money%", "|b|"+MathHelper.DottedValue(currentProductionConcept.GetDepositCost())+" " + GetLocale("CURRENCY")+"|/b|"))
		Else
			finishProductionConcept.Disable()
			finishProductionConcept.spriteName = "gfx_gui_button.datasheet"
			finishProductionConcept.SetValue("|b|"+GetLocale("PLANNING")+"|/b|~n(" + GetLocale("MONEY_TO_PAY_DOWN").Replace("%money%", "|b|"+MathHelper.DottedValue(currentProductionConcept.GetDepositCost())+" " + GetLocale("CURRENCY")+"|/b|") +")")
		EndIf
	End Method


	'set all gui elements to the values of the production concept
	Method RefreshProductionConceptGUI()
		If Not currentProductionConcept Then Return


		'=== CAST SLOT LIST ===
		castSlotList.SetItemLimit( currentProductionConcept.script.jobs.length )
		For Local i:Int = 0 Until currentProductionConcept.script.jobs.length
			castSlotList.SetSlotJob(currentProductionConcept.script.jobs[i], i)
			'also create gui
			castSlotList.SetSlotCast(i, currentProductionConcept.cast[i])
		Next
		'enable/disable scrollbars
		castSlotList.InvalidateLayout() 'RecalculateElements()


		'=== PRODUCTION COMPANY ===
		Local productionCompanyItem:TGUIDropDownItem
		For Local i:TGUIDropDownItem = EachIn productionCompanySelect.GetEntries()
			If Not i.data Or i.data.Get("productionCompany") <> currentProductionConcept.productionCompany Then Continue

			productionCompanyItem = i
			Exit
		Next
		'adjust gui dropdown
		If productionCompanyItem Then productionCompanySelect.SetSelectedEntry(productionCompanyItem)


		'=== PRODUCTION FOCUS ITEMS ===
		'hide sliders according to focuspoint type of script
		'(this is _different_ to the "disable" action done in
		' UpdateCustomProduction())
		For Local i:Int = 0 To productionFocusSlider.length -1
			productionFocusSlider[i].Hide()
		Next
		'enable used ones...
		For Local i:Int = 0 To productionFocusSlider.length -1
			If currentProductionConcept.productionFocus.GetFocusAspectCount() > i
				productionFocusSlider[i].Show()
			EndIf
		Next
		'reposition them
		repositionSliders = True
	End Method


	Method PayCurrentProductionConceptDeposit:Int()
		If Not currentProductionConcept Then Return False

		Return currentProductionConcept.PayDeposit()
	End Method


	Method SetCurrentProductionConcept(productionConcept:TProductionConcept = Null, takeOverConcept:TProductionConcept = Null)
		currentProductionConcept = productionConcept
		'use values of the new concept if nothing defined to take over
		If Not takeOverConcept Then takeOverConcept = productionConcept


		ResetProductionConceptGUI()
		ReloadProductionConceptContent()

		'=== TAKE OVER OLD CONCEPT VALUES ===
		If currentProductionConcept
			'=== CAST ===
			'loop over all jobs and try to take over as much of them as
			'possible.
			'So if there are 3 actors in the old concept but only 2 in the
			'new one, 2 of 3 actors are taken over
			'Cast not available in the new one, is ignored
			Local currentCastIndex:Int = 0
			For Local jobID:Int = EachIn TVTPersonJob.GetCastJobs()
				Local castGroup:TPersonBase[] = currentProductionConcept.GetCastGroup(jobID, False)
				Local oldCastGroup:TPersonBase[] = takeOverConcept.GetCastGroup(jobID)

				'skip group if current concept does not contain that group
				If castGroup.length = 0 Then Continue

				'leave group empty if previous concept does not contain that
				'job
				If oldCastGroup.length = 0
					currentCastIndex :+ castGroup.length
					Continue
				EndIf

				'has to collapse unused cast slots?
				Local hasToCollapseUnused:Int = (castGroup.length - oldCastGroup.length) < 0

				'try to fill slots
				For Local castGroupIndex:Int = 0 Until castGroup.length
					'skip other cast slots not available in old concept
					If castGroupIndex >= oldCastGroup.length
						currentCastIndex :+ (castGroup.length - castGroupIndex)
						Continue
					EndIf
					'collapse: skip unused
					If hasToCollapseUnused And Not oldCastGroup[castGroupIndex] Then Continue

					currentProductionConcept.SetCast(currentCastIndex, oldCastGroup[castGroupIndex])

					'SetCast() fails if the index is > than allowed, so
					'we should not need to do additional checks...
					currentCastIndex :+ 1
				Next
			Next


			'=== PRODUCTION COMPANY ===
			If takeOverConcept.productionCompany
				currentProductionConcept.SetProductionCompany(takeOverConcept.productionCompany)
			EndIf


			'=== PRODUCTION FOCUS POINTS ===
			If takeOverConcept.productionFocus
				For Local i:Int = 1 To takeOverConcept.productionFocus.focusPoints.length
					currentProductionConcept.productionFocus.SetFocus(i, takeOverConcept.productionFocus.GetFocus(i) )
				Next
			EndIf
		EndIf

		'refresh the gui objects (create items, set sliders,  ...)
		RefreshProductionConceptGUI()
		RefreshFinishProductionConceptGUI()
	End Method


	Method OpenEditTextsWindow()
		If editTextsWindow Then editTextsWindow.Remove()

		GetCurrentPlayer().setHotKeysEnabled(False)
		editTextsWindow = New TGUIProductionEditTextsModalWindow.Create(New TVec2D.Init(250,60), New TVec2D.Init(300,220), "supermarket_customproduction_productionbox_modal")
		editTextsWindow.SetZIndex(100000)
		editTextsWindow.SetConcept(GetInstance().currentProductionConcept)
		editTextsWindow.Open()
		GuiManager.Add(editTextsWindow)
	End Method


	Function onProductionCompanyChangesLevel:Int(triggerEvent:TEventBase)
		If Not GetInstance().currentProductionConcept Then Return False

		Local pc:TProductionCompanyBase = TProductionCompanyBase(triggerEvent.GetSender())
		If Not pc Then Return False
		'only interested if the currently set company changes their level
		If GetInstance().currentProductionConcept.GetProductionCompany() <> pc Then Return False
		
		'set it anew so values change (force = true)
		GetInstance().currentProductionConcept.SetProductionCompany(pc, True)

		'update displayed value
		Local entry:TGUIProductionCompanyDropDownItem = TGUIProductionCompanyDropDownItem( GetInstance().productionCompanySelect.GetSelectedEntry() )
		If entry
			entry.SetValue( entry.GetBaseValue() )
			GetInstance().productionCompanySelect.RefreshValue()
		EndIf
		
		Return True
	End Function


	Function onCloseEditTextsWindow:Int( triggerEvent:TEventBase )
		GetCurrentPlayer().setHotKeysEnabled(True)
		Local closeButton:Int = triggerEvent.GetData().GetInt("closeButton", -1)
		If closeButton <> 1 Then Return False

		Local window:TGUIProductionEditTextsModalWindow = TGUIProductionEditTextsModalWindow( triggerEvent.GetSender() )

		Local title:String = ""
		Local description:String = ""
		Local parentTitle:String = ""
		Local parentDescription:String = ""

		title = window.inputTitle.GetValue()
		description = window.inputDescription.GetValue()
		
		If window.concept.script.IsEpisode()
			parentTitle = title
			parentDescription = description
			title = window.inputSubTitle.GetValue()
			description = window.inputSubDescription.GetValue()
		EndIf

		'set title / description of the element
		If title <> window.concept.GetTitle()
			window.concept.SetCustomTitle(title)
			'also assign this to the script 
			'(means for a multi-concept-script the last custom value
			' will be displayed in the studio/script displays)
			If Not window.concept.script.IsEpisode()
				window.concept.script.SetCustomTitle(title)
			EndIf
		EndIf
		If description <> window.concept.GetDescription()
			window.concept.SetCustomDescription(description)
			'also assign this to the script 
			'(means for a multi-concept-script the last custom value
			' will be displayed in the studio/script displays)
			If Not window.concept.script.IsEpisode()
				window.concept.script.SetCustomDescription(description)
			EndIf
		EndIf

		'set the title / description of the parent (series header)
		If window.concept.script.IsEpisode()
			Local seriesScript:TScript = window.concept.script.GetParentScript()
			If parentTitle <> seriesScript.GetTitle()
				seriesScript.SetCustomTitle(parentTitle)
			EndIf
			If parentDescription <> window.concept.script.GetDescription()
				seriesScript.SetCustomDescription(parentDescription)
			EndIf
		EndIf
	End Function


	'=== SELECTLIST - PRODUCTIONCONCEPT SELECTION ===

	'GUI -> LOGIC
	'create new production / pause current
	Function onSelectProductionConcept:Int(triggerEvent:TeventBase)
		'only interested in production concept list entries
		If GetInstance().productionConceptList <> TGUIListBase(triggerEvent.GetSender()) Then Return False


		'create new one ?
		Local currentGUIScript:TGuiProductionConceptSelectListItem = TGuiProductionConceptSelectListItem(GetInstance().productionConceptList.getSelectedEntry())
		If Not currentGUIScript Or Not currentGUIScript.productionConcept Then Return False

		'skip if not changed
		If currentGUIScript.productionConcept <> GetInstance().currentProductionConcept
			'take over values from last concept - if desired
			If GetInstance().productionConceptTakeOver.isChecked() And GetInstance().currentProductionConcept
				GetInstance().SetCurrentProductionConcept(currentGUIScript.productionConcept, GetInstance().currentProductionConcept)
			Else
				GetInstance().SetCurrentProductionConcept(currentGUIScript.productionConcept, Null)
			EndIf
		EndIf
	End Function


	'=== DROPDOWN - PRODUCTION COMPANY - EVENTS ===

	'GUI -> LOGIC reaction
	'set production concepts production company according to selection
	Function onProductionConceptChangeProductionCompanyDropDown:Int(triggerEvent:TeventBase)
		If Not GetInstance().currentProductionConcept Then Return False

		Local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		If dropdown <> GetInstance().productionCompanySelect Then Return False

		Local entry:TGUIDropDownItem = TGUIDropDownItem(dropdown.GetSelectedEntry())
		If Not entry Or Not entry.data Then Return False

		Local company:TProductionCompanyBase = TProductionCompanyBase(entry.data.Get("productionCompany"))
		If Not company Then Return False

		GetInstance().currentProductionConcept.SetProductionCompany(company)
	End Function


	'LOGIC -> GUI reaction
	Function onProductionConceptChangeProductionCompany:Int(triggerEvent:TEventBase)
		If Not GetInstance().currentProductionConcept Then Return False

		Local productionConcept:TProductionConcept = TProductionConcept(triggerEvent.GetSender())
		Local company:TProductionCompanyBase = TProductionCompanyBase(triggerEvent.GetData().Get("productionCompany"))
		If productionConcept <> GetInstance().currentProductionConcept Then Return False

		'skip without changes
		Local newItem:TGUIDropDownItem
		For Local i:TGUIDropDownItem = EachIn GetInstance().productionCompanySelect.GetEntries()
			If Not i.data Or i.data.Get("productionCompany") <> company Then Continue

			newItem = i
			Exit
		Next
	'	if newItem = GetInstance().productionCompanySelect.GetSelectedEntry() then return False

		'adjust gui dropdown
		GetInstance().productionCompanySelect.SetSelectedEntry(newItem)

		'to inform the sliders we need to remove the focus from them
		'-> set it to the dropdown
		GUIManager.SetFocus(GetInstance().productionCompanySelect)
		'alternative:
		'readjust all gui slider limits (as an previously focused slider
		'would not get the new limits without)
		'For local i:int = 0 to productionFocusSlider.length -1
		'	_AdjustProductionConceptFocusSliderLimit(GetInstance().productionFocusSlider[i])
		'Next

		Return True
	End Function


	'=== SLIDER - PRODUCTION FOCUS - EVENTS ===

	'LOGIC -> GUI reaction
	'Triggered on change of the production concepts production focus.
	'Adjusts the GUI sliders to represent the new values.
	Function onProductionConceptChangeProductionFocus:Int(triggerEvent:TEventBase)
		If Not GetInstance().currentProductionConcept Then Return False

		Local productionFocus:TProductionFocusBase = TProductionFocusBase(triggerEvent.GetSender())
		If GetInstance().currentProductionConcept.productionFocus <> productionFocus Then Return False

		Local focusIndex:Int = triggerEvent.GetData().GetInt("focusIndex")
		Local value:Int = triggerEvent.GetData().GetInt("value")

		'skip without production company!
		If Not GetInstance().currentProductionConcept.productionCompany Then Return False

		'skip focus aspects without sliders
		If focusIndex < 0 Or GetInstance().productionFocusSlider.length < focusIndex Then Return False

		'do this before skipping without changes
		GetInstance().refreshFinishProductionConcept = True

		'skip without changes
		If Int(GetInstance().productionFocusSlider[focusIndex -1].GetValue()) = value Then Return False

		'disable a previously set limit
		GetInstance().productionFocusSlider[focusIndex -1].DisableLimitValue()
		'adjust values
		GetInstance().productionFocusSlider[focusIndex -1].SetValue(value)

		Return True
	End Function


	'GUI
	'Limit slider range to points available
	'Triggered as soon as the user activates the TGUISlider element.
	Function onProductionConceptSetFocusSliderFocus:Int(triggerEvent:TEventBase)
		Local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		If Not slider Then Return False

		_AdjustProductionConceptFocusSliderLimit(slider)
	End Function


	Function _GetProductionConceptFocusSliderByFocusIndex:TGUISlider(index:Int)
		For Local s:TGUISlider = EachIn GetInstance().productionFocusSlider
			If s.data And s.data.GetInt("focusIndex") = index Then Return s
		Next
		Return Null
	End Function


	'helper, so slider limit could get adjusted by other objects too
	Function _AdjustProductionConceptFocusSliderLimit:Int(slider:TGUISlider)
		If Not GetInstance().currentProductionConcept Then Return False
		If Not slider Then Return False

		'adjust slider limit dynamically
		Local focusIndex:Int = slider.data.GetInt("focusIndex")
		Local currentValue:Int = Max(0, GetInstance().currentProductionConcept.GetProductionFocus(focusIndex))
		Local desiredValue:Int = Int(slider.GetValue())
		'available points (of 10)
		Local maxValue:Int = Min(10, GetInstance().currentProductionConcept.productionFocus.GetFocusPointsLeft() + currentValue)

		slider.SetLimitValueRange(0, maxValue)
	End Function


	'GUI
	'Remove slider limit
	'Triggered as soon as the user deactivates the TGUISlider element.
	Function onProductionConceptRemoveFocusSliderFocus:Int(triggerEvent:TEventBase)
		Local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		If Not slider Then Return False

		Slider.DisableLimitValue()
	End Function


	'GUI -> LOGIC reaction
	'GUI -> GUI reaction
	'Changes production focus value according to TGUISlider values.
	'Triggered on each change to a TGUISlider element. Additionally the
	'function adjusts slider values on limited production focus values.
	Function onProductionConceptChangeFocusSliders:Int(triggerEvent:TEventBase)
		If Not GetInstance().currentProductionConcept Then Return False
		Local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		If Not slider Then Return False

		Local focusIndex:Int = slider.data.GetInt("focusIndex")
		Local currentValue:Int = GetInstance().currentProductionConcept.GetProductionFocus(focusIndex)
		Local newValue:Int = Int(slider.GetValue())

		'skip if nothing to do
		If newValue = currentValue Then Return False

		'set logic-value
		If Not GetInstance().refreshingProductionGUI
			GetInstance().currentProductionConcept.SetProductionFocus( focusIndex, newValue )
		EndIf
		'fetch resulting value (might differ because of limitations)
		newValue = Max(0, GetInstance().currentProductionConcept.GetProductionFocus(focusIndex))

		'there might be a limitation - so adjust gui slider
		If newValue <> Int(slider.GetValue())
			slider.SetValue( newValue )
		EndIf
	End Function


	'=== CAST LISTS - EVENTS ===

	'GUI -> GUI reaction
	Function onMouseOverProductionConceptItem:Int( triggerEvent:TEventBase )
		Local item:TGuiProductionConceptListItem = TGuiProductionConceptListItem(triggerEvent.GetSender())
		If item = Null Then Return False

		GetInstance().hoveredGuiProductionConcept = item

		Return True
	End Function


	'LOGIC -> GUI reaction
	'GUI -> GUI reaction
	Function onProductionConceptChangeCast:Int(triggerEvent:TEventBase)
		Local castIndex:Int = triggerEvent.GetData().GetInt("castIndex")
		Local person:TPersonBase = TPersonBase(triggerEvent.GetData().Get("person"))

		'do this before skipping without changes
		GetInstance().refreshFinishProductionConcept = True

		'skip without changes
		If GetInstance().castSlotList.GetSlotCast(castIndex) = person Then Return False
		'if currentProductionConcept.GetCast(castIndex) = person then return False

		'create new gui element
		GetInstance().castSlotList.SetSlotCast(castIndex, person)
	End Function


	'open modal window for editing titles
	Function onClickEditTextsButton:Int(triggerEvent:TEventBase)
		Local button:TGUIButton = TGUIButton(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		If Not button Or button <> GetInstance().editTextsButton Then Return False

		GetInstance().OpenEditTextsWindow()
	End Function


	'GUI -> LOGIC reaction
	Function onProductionConceptChangeCastSlotList:Int(triggerEvent:TEventBase)
		If Not GetInstance().currentProductionConcept Then Return False

		'local list:TGUICastSlotList = TGUICastSlotList( triggerEvent.GetSender() )
		Local item:TGUICastListItem = TGUICastListItem( triggerEvent.GetData().Get("item") )
		Local slot:Int = triggerEvent.GetData().GetInt("slot")

		'DO NOT skip without changes
		'-> we listen to "successful"-message ("added" vs "add")
		'   so the slot is already filled then
		'if GetInstance().castSlotList.GetSlotCast(slot) = item.person then return False


		If Not GetInstance().refreshingProductionGUI
			If item And triggerEvent.IsTrigger("guiList.addedItem")
				'print "set "+slot + "  " + item.person.GetFullName()
				GetInstance().currentProductionConcept.SetCast(slot, item.person)
			Else
				'print "clear "+slot
				GetInstance().currentProductionConcept.SetCast(slot, Null)
			EndIf
		EndIf
	End Function


	'we need to know whether we hovered an cast entry to show the
	'datasheet
	Function onMouseOverCastItem:Int( triggerEvent:TEventBase )
		Local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
		If item = Null Then Return False

		GetInstance().hoveredGuiCastItem = item

		Return True
	End Function


	'in case of right mouse button click we want to remove the
	'cast
	Function onClickCastItem:Int(triggerEvent:TEventBase)
		'print "click on cast item"
		'only react if the click came from the right mouse button
		If triggerEvent.GetData().getInt("button",0) <> 2 Then Return True

		Local guiCast:TGUICastListItem = TGUICastListItem(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		If Not guiCast Or Not guiCast.isDragged() Then Return False

		'remove from production
'		currentProductionConcept.SetCast(slot, null)

		'remove gui object
		guiCast.remove()
		guiCast = Null


		'avoid clicks
		'remove right click - to avoid leaving the room
		MouseManager.SetClickHandled(2)
	End Function


	'finish production concept
	Function onClickFinishProductionConcept:Int(triggerEvent:TEventBase)
		'skip other buttons
		If triggerEvent.GetSender() <> GetInstance().finishProductionConcept Then Return False

		If Not GetInstance().currentProductionConcept Then Return False
		'already at last step
		If GetInstance().currentProductionConcept.IsProduceable() Then Return False
		'nothing to do (should be disabled already)
		If GetInstance().currentProductionConcept.IsUnplanned() Then Return False

		If GetInstance().currentProductionConcept.IsPlanned()
			Return GetInstance().PayCurrentProductionConceptDeposit()
		EndIf

		Return True
	End Function


	Function _GetEventFocusSlider:TGUISlider(triggerEvent:TEventBase)
		Local slider:TGUISlider
		For Local s:TGUISlider = EachIn GetInstance().productionFocusSlider
			If s = triggerEvent.GetSender() Then slider = s
		Next
		'skip other sliders
		If Not slider Then Return Null
		If Not slider.data Then Return Null
		Return slider
	End Function


	Method InitCustomProductionElements()
		Local screenDefaultFont:TBitmapFont = GetBitmapFontManager().Get("default", 12)

		'=== CAST ===
		'============
		If Not castSlotList
			castSlotList = New TGUICastSlotList.Create(New TVec2D.Init(300,200), New TVec2D.Init(200, 200), "supermarket_customproduction_castbox")
		EndIf

		castSlotList.SetSlotMinDimension(230, 42)
		castSlotList._fixedSlotDimension = True
		'occupy the first free slot?
		'castSlotList.SetAutofillSlots(true)


		'=== PRODUCTION COMPANY ===
		'==========================

		'=== PRODUCTION COMPANY SELECT ===
		If Not productionCompanySelect
			productionCompanySelect = New TGUIDropDown.Create(New TVec2D.Init(600,200), New TVec2D.Init(150,-1), GetLocale("PRODUCTION_COMPANY"), 128, "supermarket_customproduction_productionbox")
			productionCompanySelect.SetListContentHeight(120)
		EndIf
		'entries added during ReloadProductionConceptContent()


		'=== PRODUCTION WEIGHTS ===
		For Local i:Int = 0 To productionFocusSlider.length -1
			If Not productionFocusSlider[i]
				productionFocusSlider[i] = New TGUISlider.Create(New TVec2D.Init(640,300 + i*25), New TVec2D.Init(150,22), "0", "supermarket_customproduction_productionbox")
			EndIf
			productionFocusSlider[i].SetValueRange(0,10)
			productionFocusSlider[i].steps = 10
			productionFocusSlider[i]._gaugeOffset.SetY(2)
			productionFocusSlider[i].SetRenderMode(TGUISlider.RENDERMODE_DISCRETE)
			productionFocusSlider[i].SetDirection(TGUISlider.DIRECTION_RIGHT)
			productionFocusSlider[i].data = New TData.AddNumber("focusIndex", i+1)

			productionFocusSlider[i]._handleDim.SetX(17)
		Next


		'=== EDIT TEXTS BUTTON ===
		If Not editTextsButton
			editTextsButton = New TGUIButton.Create(New TVec2D.Init(530, 26), New TVec2D.Init(30, 28), "...", "supermarket_customproduction_newproduction")
		EndIf
		'editTextsButton.disable()
		editTextsButton.caption.SetSpriteName("gfx_datasheet_icon_pencil")
		editTextsButton.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_ONLY )
		editTextsButton.spriteName = "gfx_gui_button.datasheet"


		'=== FINISH CONCEPT BUTTON ===
		If Not finishProductionConcept
			finishProductionConcept = New TGUIButton.Create(New TVec2D.Init(20, 220), New TVec2D.Init(100, 28), "...", "supermarket_customproduction_newproduction")
		EndIf
		finishProductionConcept.caption.SetSpriteName("gfx_datasheet_icon_money")
		finishProductionConcept.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_LEFT_OF_TEXT3 )
		finishProductionConcept.disable()
		finishProductionConcept.spriteName = "gfx_gui_button.datasheet"
		finishProductionConcept.SetFont( screenDefaultFont )

		'=== PRODUCTION TAKEOVER CHECKBOX ===
		If Not productionConceptTakeOver
			productionConceptTakeOver = New TGUICheckbox.Create(New TVec2D.Init(20, 220), New TVec2D.Init(100, 28), GetLocale("TAKE_OVER_SETTINGS"), "supermarket_customproduction_productionconceptbox")
		EndIf
		productionConceptTakeOver.SetFont( screenDefaultFont )

		'=== PRODUCTION CONCEPT LIST ===
		If Not productionConceptList
			productionConceptList = New TGUISelectList.Create(New TVec2D.Init(20,20), New TVec2D.Init(150,180), "supermarket_customproduction_productionconceptbox")
		EndIf
		'scroll one concept per "scroll"
		productionConceptList.scrollItemHeightPercentage = 1.0
		productionConceptList.SetAutosortItems(True) 'sort concepts


		ReloadProductionConceptContent()
	End Method


	Method ReloadProductionConceptContent()
		'=== PRODUCTION COMPANY SELECT ===
		productionCompanySelect.list.EmptyList()
		productionCompanySelect.SetValue(GetLocale("PRODUCTION_COMPANY"))

		'add some items to that list
		For Local p:TProductionCompanyBase = EachIn GetProductionCompanyBaseCollection().entries.values()
			'base items do not have a size - so we have to give a manual one
'			local item:TGUIDropDownItem = new TGUIDropDownItem.Create(null, null, p.name+" [Lvl: "+p.GetLevel()+"]")
'			item.data = new TData.Add("productionCompany", p)
			Local item:TGUIProductionCompanyDropDownItem = New TGUIProductionCompanyDropDownItem.CreateSimple(p)
			productionCompanySelect.AddItem( item )
		Next


		'=== CONCEPTS ===
		productionConceptList.EmptyList()

		Local productionConcepts:TProductionConcept[]
		For Local productionConcept:TProductionConcept = EachIn GetProductionConceptCollection().entries.Values()
			productionConcepts :+ [productionConcept]
		Next

		'sort by series/name
		productionConcepts.Sort(True)

		For Local productionConcept:TProductionConcept = EachIn productionConcepts

			'skip produced concepts
			If productionConcept.IsProduced() Then Continue

			Local item:TGuiProductionConceptSelectListItem = New TGuiProductionConceptSelectListItem.Create(Null, New TVec2D.Init(150,24), "concept")
			'done in TGuiProductionConceptSelectListItem.New() already
			'item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)

			item.SetProductionConcept(productionConcept)

			'base items do not have a size - so we have to give a manual one
			productionConceptList.AddItem( item )
		Next
'		productionConceptList.entries.sort(true)

		productionConceptList.InvalidateLayout()
'		productionConceptList.RecalculateElements()
		'refresh scrolling state
'		productionConceptList.SetSize(-1, -1)
	End Method


	Method Update()
		'gets refilled in gui-updates
		hoveredGuiCastItem = Null
		hoveredGuiProductionConcept = Null

		'disable / enable elements according to state
		If Not currentProductionConcept Or currentProductionConcept.IsProduceable()
			If (Not currentProductionConcept Or Not currentProductionConcept.productionCompany Or productionFocusSlider[0].IsEnabled())
				'disable _all_ sliders if no production company is selected
				For Local i:Int = 0 To productionFocusSlider.length -1
					productionFocusSlider[i].Disable()
				Next
			EndIf

			'general elements
			If productionCompanySelect.IsEnabled()
				productionCompanySelect.Disable()
				castSlotList.Disable()
				'if currentProductionConcept then print "DISABLE " + currentProductionConcept.script.GetTitle()
			EndIf
		EndIf

		'or enable (specific of) them...
		If currentProductionConcept And Not currentProductionConcept.IsProduceable()
			'sliders only with selected production company
			If currentProductionConcept.productionCompany And Not productionFocusSlider[0].IsEnabled()
				For Local i:Int = 0 To productionFocusSlider.length -1
					If currentProductionConcept.productionFocus.GetFocusAspectCount() > i
						productionFocusSlider[i].Enable()
					EndIf
				Next
			EndIf

			'general elements
			If Not productionCompanySelect.IsEnabled()
				productionCompanySelect.Enable()
				castSlotList.Enable()
				'if currentProductionConcept then print "ENABLE " + currentProductionConcept.script.GetTitle()
			EndIf
		EndIf

		GuiManager.Update( TLowerString.Create("supermarket_customproduction_castbox_modal") )
		GuiManager.Update( TLowerString.Create("supermarket_customproduction_productionbox_modal") )
		GuiManager.Update( TLowerString.Create("supermarket_customproduction_productionconceptbox") )
		GuiManager.Update( TLowerString.Create("supermarket_customproduction_newproduction") )
		GuiManager.Update( TLowerString.Create("supermarket_customproduction_productionbox") )
		GuiManager.Update( TLowerString.Create("supermarket_customproduction_castbox") )

		If (MouseManager.IsClicked(2) Or MouseManager.IsLongClicked(1))
			'leaving room now
			If Not currentProductionConcept
				RemoveAllGuiElements()

			'just aborting current production planning
			Else
				If Not castSlotList.SelectCastWindowIsOpen()
					SetCurrentProductionConcept(Null)
				EndIf

				'abort room leaving
				'remove right click
				MouseManager.SetClickHandled(2)
			EndIf
		EndIf
	End Method


	Method Render()
		'update finishProductionConcept-button's value if needed
		If refreshFinishProductionConcept
			RefreshFinishProductionConceptGUI()
		EndIf

		SetColor(255,255,255)

		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		'where to draw
		Local outer:TRectangle = New TRectangle
		'calculate position/size of content elements
		Local contentX:Int = 0
		Local contentY:Int = 0
		Local contentW:Int = 0
		Local contentH:Int = 0
		Local outerSizeH:Int = skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		Local outerH:Int = 0 'size of the "border"

		Local titleH:Int = 18, subTitleH:Int = 16
		Local boxAreaH:Int = 0, buttonAreaH:Int = 0, bottomAreaH:Int = 0, msgH:Int = 0
		Local boxAreaPaddingY:Int = 4, buttonAreaPaddingY:Int = 4
		Local msgPaddingY:Int = 4

		msgH = skin.GetMessageSize(100, -1, "").GetY()



		'=== PRODUCTION CONCEPT LIST ===
		outer.Init(10, 15, 210, 205)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		Local checkboxArea:Int = productionConceptTakeOver.rect.GetH() + 0*buttonAreaPaddingY

		Local listH:Int = contentH - titleH - checkboxArea

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(GetLocale("PRODUCTION_CONCEPTS"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		If productionConceptList.rect.getX() <> contentX + 5
			productionConceptList.SetPosition(contentX + 5, contentY + 3)
			productionConceptList.SetSize(contentW - 10, listH - 6)
		EndIf
		contentY :+ listH

		skin.RenderContent(contentX, contentY, contentW, contentH - (listH+titleH) , "1_bottom")
		'reposition checkbox
		productionConceptTakeOver.SetPosition(contentX + 5, contentY + buttonAreaPaddingY)
		productionConceptTakeOver.SetSize(contentW - 10)
		contentY :+ contentH - (listH+titleH)

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())



		If currentProductionConcept
			'=== CHECK AND START BOX ===
			outer.SetXY(10, 225)
			outer.dimension.SetXY(210,145)
			contentX = skin.GetContentX(outer.GetX())
			contentY = skin.GetContentY(outer.GetY())
			contentW = skin.GetContentW(outer.GetW())
			contentH = skin.GetContentH(outer.GetH())

			buttonAreaH = finishProductionConcept.rect.GetH() + 2*buttonAreaPaddingY

			'reset
			contentY = contentY
			skin.RenderContent(contentX, contentY, contentW, contentH - buttonAreaH, "1_top")
			contentY :+ 3
			skin.fontBold.drawBlock(GetLocale("MOVIE_CAST"), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorLabel, 0,1,1.0,True, True)
			skin.fontNormal.drawBlock(MathHelper.DottedValue(currentProductionConcept.GetCastCost()), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
			contentY :+ subtitleH
			skin.fontBold.drawBlock(GetLocale("PRODUCTION"), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorLabel, 0,1,1.0,True, True)
			skin.fontNormal.drawBlock(MathHelper.DottedValue(currentProductionConcept.GetProductionCost()), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
			contentY :+ subtitleH

			SetColor 150,150,150
			DrawRect(contentX + 5, contentY-1, contentW - 10, 1)
			SetColor 255,255,255

			contentY :+ 1
			skin.fontBold.drawBlock(GetLocale("TOTAL_COSTS"), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			skin.fontBold.drawBlock(MathHelper.DottedValue(currentProductionConcept.GetTotalCost()), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
			contentY :+ subtitleH

			contentY :+ 10
			skin.fontBold.drawBlock(GetLocale("DURATION"), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			skin.fontNormal.drawBlock(currentProductionConcept.GetBaseProductionTime()+" Stunden", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ subtitleH

			contentY :+ (contentH - buttonAreaH) - 4*subtitleH - 3 -1 - 10

			skin.RenderContent(contentX, contentY, contentW, buttonAreaH, "1_bottom")
			'reposition button
			finishProductionConcept.SetPosition(contentX + 5, contentY + buttonAreaPaddingY)
			finishProductionConcept.SetSize(contentW - 10, 38)
			contentY :+ buttonAreaH

			skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())


			'=== CAST / MESSAGE BOX ===
			'calc height
			Local castAreaH:Int = 215
			Local msgAreaH:Int = 0
			If Not currentProductionConcept.IsCastComplete() Then msgAreaH :+ msgH + msgPaddingY
			If Not currentProductionConcept.IsFocusPointsComplete() Then msgAreaH :+ msgH + msgPaddingY
			outerH = outerSizeH + titleH + subTitleH + castAreaH + msgAreaH

			outer.SetXY(225, 15)
			outer.dimension.SetXY(350, outerH)
			contentX = skin.GetContentX(outer.GetX())
			contentY = skin.GetContentY(outer.GetY())
			contentW = skin.GetContentW(outer.GetW())
			contentH = skin.GetContentH(outer.GetH())

			'reset
			contentY = contentY

			Local title:String = currentProductionConcept.GetTitle()
			Local subTitle:String
			If currentProductionConcept.script.IsEpisode()
				Local seriesScript:TScript = currentProductionConcept.script.GetParentScript()
				subTitle = (seriesScript.GetSubScriptPosition(currentProductionConcept.script)+1) + "/" + seriesScript.GetSubscriptCount() + ": " + title
				title = seriesScript.GetTitle()
			EndIf


			skin.RenderContent(contentX, contentY, contentW, titleH + subTitleH, "1_top")
			skin.fontCaption.drawBlock(title, contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ titleH

			If currentProductionConcept.script.IsEpisode()
				skin.fontSmallCaption.drawBlock(subTitle, contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			EndIf
			contentY :+ subTitleH

			skin.RenderContent(contentX, contentY, contentW, castAreaH, "2")
			'reposition cast list
			If castSlotList.rect.getX() <> contentX + 5
				castSlotList.SetPosition(contentX +5, contentY + 3)
				'-5 => 210 height, each slot 42px, so 5 slots fit
				castSlotList.SetSize(contentW - 10, castAreaH - 5 )
				castSlotList.SetSlotMinDimension(contentW - 10, 42)
			EndIf

			contentY :+ castAreaH

			If msgAreaH > 0
				skin.RenderContent(contentX, contentY, contentW, msgAreaH, "1_bottom")
				If Not currentProductionConcept.IsCastComplete()
					skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("CAST_INCOMPLETE"), "audience", "warning")
					contentY :+ msgH + msgPaddingY
				EndIf
				If Not currentProductionConcept.IsFocusPointsComplete()
					If currentProductionConcept.productionCompany
						If Not currentProductionConcept.IsFocusPointsMinimumUsed()
							skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("NEED_TO_SPENT_AT_LEAST_ONE_POINT_OF_PRODUCTION_FOCUS_POINTS"), "spotsplanned", "warning")
						Else
							skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("PRODUCTION_FOCUS_POINTS_NOT_SET_COMPLETELY"), "spotsplanned", "neutral")
						EndIf
					Else
						skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("NO_PRODUCTION_COMPANY_SELECTED"), "spotsplanned", "warning")
					EndIf
					contentY :+ msgH + msgPaddingY
				EndIf
			EndIf

			skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())




			'=== PRODUCTION BOX ===
			Local productionFocusSliderH:Int = 21
			Local productionFocusLabelH:Int = 15
			Local productionCompanyH:Int = 60
			Local productionFocusH:Int = titleH + subTitleH + 5 'bottom padding
			If currentProductionConcept.productionFocus
				productionFocusH :+ currentProductionConcept.productionFocus.GetFocusAspectCount() * (productionFocusSliderH + productionFocusLabelH)
			EndIf
			outerH = outerSizeH + titleH + productionCompanyH + productionFocusH

			outer.SetXY(580, 15)
			outer.dimension.SetXY(210, outerH)
			contentX = skin.GetContentX(outer.GetX())
			contentY = skin.GetContentY(outer.GetY())
			contentW = skin.GetContentW(outer.GetW())
			contentH = skin.GetContentH(outer.GetH())


			'reset
			contentY = contentY
			skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			skin.fontCaption.drawBlock(GetLocale("PRODUCTION_DETAILS"), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ titleH

			skin.RenderContent(contentX, contentY, contentW, productionCompanyH + productionFocusH, "1")

			skin.fontSemiBold.drawBlock(GetLocale("PRODUCTION_COMPANY"), contentX + 5, contentY + 3, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			'reposition dropdown
			If productionCompanySelect.rect.getX() <> contentX + 5
				productionCompanySelect.SetPosition(contentX + 5, contentY + 20)
				productionCompanySelect.SetSize(contentW - 10, -1)
			EndIf
			contentY :+ productionCompanyH

			skin.fontSemiBold.drawBlock(GetLocale("PRODUCTION_FOCUS"), contentX + 5, contentY + 3, contentW - 10, titleH - 3, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			contentY :+ titleH
			'reposition sliders
			If repositionSliders
				Local sliderOrder:Int[]
				If currentProductionConcept And currentProductionConcept.productionFocus
					sliderOrder = currentProductionConcept.productionFocus.GetOrderedFocusIndices()
				Else
					sliderOrder = [1,2,3,4,5,6]
				EndIf
				For Local i:Int = 0 Until sliderOrder.length
					Local sliderNum:Int = sliderOrder[i]
					Local slider:TGUISlider = productionFocusSlider[ sliderNum-1]
					slider.SetPosition(contentX + 5, contentY + productionFocusLabelH + i * (productionFocusLabelH + productionFocusSliderH))
					slider.SetSize(contentW - 10)
				Next
				repositionSliders = False
			EndIf

			If currentProductionConcept.productionFocus
				Local pF:TProductionFocusBase = currentProductionConcept.productionFocus
				For Local labelNum:Int = EachIn pF.GetOrderedFocusIndices()
		'		For local labelNum:int = 0 until productionFocusLabel.length
					If Not productionFocusSlider[labelNum-1].IsVisible() Then Continue
					Local focusIndex:Int = productionFocusSlider[labelNum-1].data.GetInt("focusIndex")
					Local label:String = GetLocale(TVTProductionFocus.GetAsString(focusIndex))
					skin.fontNormal.drawBlock(label, contentX + 10, contentY, contentW - 15, titleH, ALIGN_LEFT_CENTER, skin.textColorLabel, 0,1,1.0,True, True)
					contentY :+ (productionFocusLabelH + productionFocusSliderH)
				Next

				'inform about unused skill points / missing company selection
				Local color:TColor
				If currentProductionConcept.productionCompany
					If pF.GetFocusPointsSet() < pF.GetFocusPointsMax()
						color = skin.textColorWarning
					Else
						color = skin.textColorLabel
					EndIf
					Local text:String = GetLocale("POINTSSET_OF_POINTSMAX_POINTS_SET").Replace("%POINTSSET%", pF.GetFocusPointsSet()).Replace("%POINTSMAX%", pF.GetFocusPointsMax())
					skin.fontNormal.drawBlock("|i|"+text+"|/i|", contentX + 5, contentY, contentW - 10, subTitleH, ALIGN_CENTER_CENTER, color, 0,1,1.0,True, True)
				EndIf
				contentY :+ subTitleH
			EndIf
			skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_productionconceptbox") )
			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_newproduction") )
			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_productionbox") )
			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_castbox") )
	'		GuiManager.Draw( TLowerString.Create("supermarket_customproduction_castbox"), -1000,-1000, GUIMANAGER_TYPES_NONDRAGGED)

			GuiManager.Draw( TLowerString.Create("supermarket_customproduction") )
	'		GuiManager.Draw( TLowerString.Create("supermarket_customproduction_castbox", -1000,-1000, GUIMANAGER_TYPES_DRAGGED) )
			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_castbox_modal") )
			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_productionbox_modal") )

			'draw datasheet if needed
			If hoveredGuiCastItem Then hoveredGuiCastItem.DrawDatasheet(hoveredGuiCastItem.GetScreenRect().GetX() - 230, hoveredGuiCastItem.GetScreenRect().GetX() - 170 )

		Else
			GuiManager.Draw( TLowerString.Create("supermarket_customproduction_productionconceptbox") )
		EndIf

		'draw script-sheet
		If hoveredGuiProductionConcept Then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method
End Type



Type TGUIProductionModalWindow Extends TGUIModalWindow
	Field buttonOK:TGUIButton
	Field buttonCancel:TGUIButton
	Field _eventListeners:TEventListenerBase[]


	Method Create:TGUIProductionModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		darkenedAreaAlpha = 0.25 '0.5 is default


		buttonOK = New TGUIButton.Create(New TVec2D.Init(10, dimension.GetY() - 44), New TVec2D.Init(136, 28), "OK", "")
		buttonOK.spriteName = "gfx_gui_button.datasheet"
		buttonCancel = New TGUIButton.Create(New TVec2D.Init(dimension.GetX() - 15 - 136, dimension.GetY() - 44), New TVec2D.Init(136, 28), "Cancel", "")
		buttonCancel.spriteName = "gfx_gui_button.datasheet"

		AddChild(buttonOK)
		AddChild(buttonCancel)
	End Method


	Method Remove:Int()
		EventManager.UnregisterListenersArray(_eventListeners)
		Return Super.Remove()
	End Method


	'override to skip animation
	Method IsClosed:Int()
		Return closeActionStarted
	End Method


	Method SetSize(w:Float = 0, h:Float = 0)
		Super.SetSize(w, h)
		If buttonOK Then buttonOK.rect.position.SetY( rect.dimension.GetY() - 44)
		If buttonCancel Then buttonCancel.rect.position.SetY( rect.dimension.GetY() - 44)
	End Method


	'override to _not_ recenter
	Method Recenter:Int(moveByX:Float = 0, moveByY:Float = 0)
		Return True
	End Method


	Method Update:Int()
		If buttonCancel.IsClicked() Then Close(2)
		If buttonOK.IsClicked() Then Close(1)

		If (MouseManager.IsClicked(2) Or MouseManager.IsLongClicked(1))
			Close(2)

			'avoid clicks
			'remove right click - to avoid leaving the room
			MouseManager.SetClickHandled(2)
			'also avoid long click (touch screen)
			MouseManager.SetLongClickHandled(1)
		EndIf

		Return Super.Update()
	End Method
End Type






Type TGUISelectCastWindow Extends TGUIProductionModalWindow
	Field jobFilterSelect:TGUIDropDown
	Field genderFilterSelect:TGUIDropDown
	'only list persons with the following job?
	Field listOnlyJobID:Int = -1
	Field listOnlyGenderID:Int = -1
	'select a person for the following job (for correct fee display)
	Field selectJobID:Int = 0
	Field selectGenderID:Int = 0
	Field castSelectList:TGUICastSelectList


	'override
	Method Create:TGUISelectCastWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		jobFilterSelect = New TGUIDropDown.Create(New TVec2D.Init(15,12), New TVec2D.Init(170,-1), "Hauptberuf", 128, "")
		jobFilterSelect.SetZIndex( GetZIndex() + 10)
		jobFilterSelect.list.SetZIndex( GetZIndex() + 11)
		jobFilterSelect.SetListContentHeight(180)

		'add some items to that list
		Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, "")
		item.SetValue(GETLOCALE("JOB_ALL"))
		item.data.AddNumber("jobIndex", 0)
		jobFilterSelect.AddItem(item)

		For Local i:Int = EachIn TVTPersonJob.GetCastJobIndices()
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, "")
			item.SetValue(GETLOCALE("JOB_" + TVTPersonJob.GetAsString( TVTPersonJob.GetAtIndex(i) )))
			item.data.AddNumber("jobIndex", i)
			jobFilterSelect.AddItem(item)
		Next


		genderFilterSelect = New TGUIDropDown.Create(New TVec2D.Init(192,12), New TVec2D.Init(90,-1), "Alle", 128, "")
		genderFilterSelect.SetZIndex( GetZIndex() + 10)
		genderFilterSelect.list.SetZIndex( GetZIndex() + 11)
		genderFilterSelect.SetListContentHeight(60)

		'add some items to that list
		For Local i:Int = 0 To TVTPersonGender.count
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(Null, Null, "")

			If i = 0
				item.SetValue(GetLocale("GENDER_ALL"))
			Else
				If i = 1
					item.SetValue(GetLocale("GENDER_MEN"))
				Else
					item.SetValue(GetLocale("GENDER_WOMEN"))
				EndIf
			EndIf
			item.data.AddNumber("genderIndex", i)
			genderFilterSelect.AddItem(item)
		Next


		castSelectList = New TGUICastSelectList.Create(New TVec2D.Init(15,50), New TVec2D.Init(270, dimension.y - 103), "")


		AddChild(jobFilterSelect)
		AddChild(genderFilterSelect)
		AddChild(castSelectList)

		buttonOK.SetValue(GetLocale("SELECT_PERSON"))
		buttonCancel.SetValue(GetLocale("CANCEL"))

		_eventListeners :+ [ EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", Self, "onCastChangeFilterDropdown", "TGUIDropDown" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod("guiobject.OnDoubleClick", Self, "onDoubleClickCastListItem", "TGUICastListItem" ) ]

		Return Self
	End Method


	'override to also set zIndex of list element
	Method SetZIndex(zindex:Int)
		If jobFilterSelect
			jobFilterSelect.SetZIndex( zindex + 1)
			jobFilterSelect.list.SetZIndex( zindex + 2)
		EndIf
		If genderFilterSelect
			genderFilterSelect.SetZIndex( zindex + 1)
			genderFilterSelect.list.SetZIndex( zindex + 2)
		EndIf

		Super.SetZIndex(zindex)
	End Method



	'GUI->GUI
	'close window with "OK" (shortcut to "select + OK")
	Method onDoubleClickCastListItem:Int( triggerEvent:TEventBase )
		Local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
		If item = Null Then Return False
		'skip if from another list
		If TGUIListBase.FindGUIListBaseParent(item) <> castSelectList Then Return False

		Close(1)

		Return True
	End Method


	'GUI -> GUI
	'set cast filter according to selection
	Method onCastChangeFilterDropdown:Int(triggerEvent:TeventBase)
		Local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		If Not dropdown Then Return False
		If dropdown <> jobFilterSelect And dropdown <> genderFilterSelect Then Return False

		Local entry:TGUIDropDownItem = TGUIDropDownItem(dropdown.GetSelectedEntry())
		If Not entry Or Not entry.data Then Return False

		'select*** contains what is supposed to get selected when opening
		'the whole cast-select window
		Local jobID:Int = selectJobID
		Local genderID:Int = selectGenderID

		'override that values with the ones from the dropdowns
		If jobFilterSelect.GetSelectedEntry()
			jobID = TVTPersonJob.GetAtIndex( jobFilterSelect.GetSelectedEntry().data.GetInt("jobIndex") )
		EndIf
		If genderFilterSelect.GetSelectedEntry()
			genderID = TVTPersonGender.GetAtIndex( genderFilterSelect.GetSelectedEntry().data.GetInt("genderIndex") )
		EndIf
		LoadPersons(jobID, genderID)
	End Method


	Method GetSelectedPerson:TPersonBase()
		Local item:TGUICastListItem = TGUICastListItem(castSelectList.getSelectedEntry())
		If Not item Or Not item.person Then Return Null

		Return item.person
	End Method


	Method SetJobFilterSelectEntry:Int(jobIndex:Int)
		'adjust dropdown to use the correct entry
		'skip without changes
		Local newItem:TGUIDropDownItem
		For Local i:TGUIDropDownItem = EachIn jobFilterSelect.GetEntries()
			If Not i.data Or i.data.GetInt("jobIndex", -2) <> jobIndex Then Continue

			newItem = i
			Exit
		Next
		If newItem = jobFilterSelect.GetSelectedEntry() Then Return False

		jobFilterSelect.SetSelectedEntry(newItem)
		Return True
	End Method


	Method SetGenderFilterSelectEntry:Int(genderIndex:Int)
		'adjust dropdown to use the correct entry
		'skip without changes
		Local newItem:TGUIDropDownItem
		For Local i:TGUIDropDownItem = EachIn genderFilterSelect.GetEntries()
			If Not i.data Or i.data.GetInt("genderIndex", -2) <> genderIndex Then Continue

			newItem = i
			Exit
		Next
		If newItem = genderFilterSelect.GetSelectedEntry() Then Return False

		genderFilterSelect.SetSelectedEntry(newItem)
		Return True
	End Method


	'override to fill with content on open
	Method Open:Int()
		Super.Open()


		'adjust gui dropdown
		Local jobIndex:Int = TVTPersonJob.GetIndex(listOnlyJobID)
		If listOnlyJobID = -1 Then jobIndex = -1
		SetJobFilterSelectEntry(jobIndex)

		Local genderIndex:Int = listOnlyGenderID
		If listOnlyGenderID = -1 Then genderIndex = 0
		SetGenderFilterSelectEntry(genderIndex)


		LoadPersons(listOnlyJobID, listOnlyGenderID)
	End Method


	Method LoadPersons(filterToJobID:Int, filterToGenderID:Int = 0)
		'skip if no change is needed
		If castSelectList.filteredJobID = filterToJobID And castSelectList.filteredGenderID = filterToGenderID Then Return
		'print "LoadPersons: filter=" + filterToJobID

		castSelectList.EmptyList()

		'add all castable celebrities to that list
		Local personsList:TObjectList = GetPersonBaseCollection().GetCastableCelebritiesList()
		Local persons:TPersonBase[]
		If filterToJobID > 0
			For Local person:TPersonBase = EachIn personsList
				If filterToGenderID > 0 And person.gender <> filterToGenderID Then Continue

				If person.HasJob(filterToJobID)
					persons :+ [person]
				EndIf
			Next
		EndIf

		'sort by name (rely on "TPersonBase.Compare()")
		persons.Sort(True)

		'add an amateur/layman at the top (hidden behind is a random
		'normal person)
		Local amateur:TPersonBase
		Repeat
			'only bookable amateurs
			amateur = GetPersonBaseCollection().GetRandomInsignificant(Null, True, True, 0, filterToGenderID)

			If Not amateur
				Local countryCode:String = GetStationMapCollection().config.GetString("nameShort", "Unk")
				'try to use "map specific names"
				If RandRange(0,100) < 25 Or Not GetPersonGenerator().HasProvider(countryCode)
					countryCode = GetPersonGenerator().GetRandomCountryCode()
				EndIf

				amateur = GetPersonBaseCollection().CreateRandom(countryCode, Max(0, filterToGenderID))
			EndIf

			'print "check " + amateur.GetFullName() + "  " + amateur.GetAge() +"  fictional:"+amateur.fictional
			'if not amateur.IsAlive() then print "skip: dead "+amateur.GetFullName()
			'if not (amateur.GetAge() >= 10) then print "skip: too young "+amateur.GetFullName()
			'if not amateur.fictional then print "skip: real "+amateur.GetFullName()
		Until amateur.IsAlive() And amateur.IsFictional() And amateur.IsBookable()

		persons = [amateur] + persons

		'disable list-sort
		castSelectList.SetAutosortItems(False)

		For Local p:TPersonBase = EachIn persons
			'custom production not possible with real persons...
			If Not p.IsFictional() Then Continue
			'also the person must be bookable for productions (maybe retired?)
			If Not p.IsBookable() Then Continue
			If Not p.IsAlive() Then Continue

			'we also want to avoid "children"
			If p.IsCelebrity() And p.GetAge() < 10 And p.GetAge() <> -1 Then Continue

			'base items do not have a size - so we have to give a manual one
			Local item:TGUICastListItem = New TGUICastListItem.CreateSimple( p, selectJobID )
			If p = amateur
				If selectJobID > 0
					item.displayName = GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString(selectJobID))
				Else
					item.displayName = GetLocale("JOB_AMATEUR")
				EndIf
				item.isAmateur = True
			EndIf
			item.SetSize(180,40)
			castSelectList.AddItem( item )
		Next

		'adjust which desired job the list is selecting
		castSelectList.selectJobID = selectJobID
		castSelectList.selectGenderID = selectGenderID
		'adjust which filter we are using
		castSelectList.filteredJobID = filterToJobID
		castSelectList.filteredGenderID = filterToGenderID
	End Method


	Method DrawBackground()
		Super.DrawBackground()

		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		Local outer:TRectangle = GetScreenRect().Copy() ')new TRectangle.Init(GetScreenRect().GetX(), GetScreenRect().GetY(), 200, 200)
		Local contentX:Int = skin.GetContentX(outer.GetX())
		Local contentY:Int = skin.GetContentY(outer.GetY())
		Local contentW:Int = skin.GetContentW(outer.GetW())
		Local contentH:Int = skin.GetContentH(outer.GetH())

		skin.RenderContent(contentX, contentY, contentW, 38, "1_top")
		skin.RenderContent(contentX, contentY+38, contentW, contentH-73, "1")
		skin.RenderContent(contentX, contentY+contentH-35, contentW, 35, "1_bottom")
		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())
	End Method
End Type




Type TGUIProductionEditTextsModalWindow Extends TGUIProductionModalWindow
	Field inputTitle:TGUIInput
	Field inputDescription:TGUIInput
	Field inputSubTitle:TGUIInput
	Field inputSubDescription:TGUIInput
	Field clearTitle:TGUIButton
	Field clearDescription:TGUIButton
	Field clearSubTitle:TGUIButton
	Field clearSubDescription:TGUIButton

	Field labelTitle:TGUILabel
	Field labelDescription:TGUILabel
	Field labelEpisode:TGUILabel
	Field labelSubTitle:TGUILabel
	Field labelSubDescription:TGUILabel

	Field concept:TProductionConcept

	'override
	Method Create:TGUIProductionEditTextsModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		labelTitle = New TGUILabel.Create(New TVec2D.Init(15,12), GetLocale("TITLE"), Null, "")
		labelDescription = New TGUILabel.Create(New TVec2D.Init(15,60), GetLocale("DESCRIPTION"), Null, "")
		labelEpisode = New TGUILabel.Create(New TVec2D.Init(15,115), GetLocale("EPISODE"), Null, "")
		labelEpisode.SetFont( GetBitmapFontManager().Get("default", 13, BOLDFONT) )
		labelSubTitle = New TGUILabel.Create(New TVec2D.Init(15,137), GetLocale("TITLE"), Null, "")
		labelSubDescription = New TGUILabel.Create(New TVec2D.Init(15,180), GetLocale("DESCRIPTION"), Null, "")

		inputTitle = New TGUIInput.Create(New TVec2D.Init(15,12+13), New TVec2D.Init(245,-1), GetLocale("TITLE"), 128, "")
		inputDescription = New TGUIInput.Create(New TVec2D.Init(15,60+13), New TVec2D.Init(245,-1), GetLocale("DESCRIPTION"), 128, "")
		inputSubTitle = New TGUIInput.Create(New TVec2D.Init(15,137+13), New TVec2D.Init(245,-1), GetLocale("TITLE"), 128, "")
		inputSubDescription = New TGUIInput.Create(New TVec2D.Init(15,180+13), New TVec2D.Init(245,-1), GetLocale("DESCRIPTION"), 128, "")

		clearTitle = New TGUIButton.Create(New TVec2D.Init(15+245, 12 + 13 + 2), New TVec2D.Init(25, 25), "x", "")
		clearTitle.spriteName = "gfx_gui_button.datasheet"
		clearDescription = New TGUIButton.Create(New TVec2D.Init(15+245, 60 + 13 + 2), New TVec2D.Init(25, 25), "x", "")
		clearDescription.spriteName = "gfx_gui_button.datasheet"
		clearSubTitle = New TGUIButton.Create(New TVec2D.Init(15+245, 137 + 13 + 2), New TVec2D.Init(25, 25), "x", "")
		clearSubTitle.spriteName = "gfx_gui_button.datasheet"
		clearSubDescription = New TGUIButton.Create(New TVec2D.Init(15+245, 180 + 13 + 2), New TVec2D.Init(25, 26), "x", "")
		clearSubDescription.spriteName = "gfx_gui_button.datasheet"



		AddChild(labelTitle)
		AddChild(labelDescription)
		AddChild(labelEpisode)
		AddChild(labelSubTitle)
		AddChild(labelSubDescription)

		AddChild(inputTitle)
		AddChild(inputDescription)
		AddChild(inputSubTitle)
		AddChild(inputSubDescription)

		AddChild(clearTitle)
		AddChild(clearDescription)
		AddChild(clearSubTitle)
		AddChild(clearSubDescription)

		buttonOK.SetValue(GetLocale("EDIT_TEXTS"))
		buttonCancel.SetValue(GetLocale("CANCEL"))

		_eventListeners :+ [ EventManager.registerListenerMethod("guiobject.onChange", Self, "onChangeInputValues", "TGUIInput" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickClearInputButton", "TGUIButton") ]

		Return Self
	End Method


	'override
	Method Remove:Int()
		Super.Remove()
		concept = Null
	End Method


	'override to fill with content on open
	Method Open:Int()
		Super.Open()

		'read values
		If concept
			If concept.script.IsEpisode()
				Local seriesScript:TScript = concept.script.GetParentScript()
				inputTitle.SetValue(seriesScript.GetTitle())
				inputDescription.SetValue(seriesScript.GetDescription())

				inputSubTitle.SetValue(concept.script.GetTitle())
				inputSubDescription.SetValue(concept.script.GetDescription())
			Else
				inputTitle.SetValue(concept.script.GetTitle())
				inputDescription.SetValue(concept.script.GetDescription())
			EndIf
		EndIf
	End Method


	Method SetConcept:Int(concept:TProductionConcept)
		If Not concept Then Return False

		Self.concept = concept
		If concept.script.IsEpisode()
			inputSubDescription.Show()
			inputSubTitle.Show()
			clearSubTitle.Show()
			clearSubDescription.Show()
			labelSubDescription.Show()
			labelSubTitle.Show()
			labelEpisode.Show()

			Local seriesScript:TScript = concept.script.GetParentScript()
			labelEpisode.SetValue( GetLocale("EPISODE") +": "+(seriesScript.GetSubScriptPosition(concept.script)+1)+"/"+seriesScript.GetSubscriptCount() )

			SetSize(-1,280)
		Else
			inputSubDescription.Hide()
			inputSubTitle.Hide()
			clearSubDescription.Hide()
			clearSubTitle.Hide()
			labelSubDescription.Hide()
			labelSubTitle.Hide()
			labelEpisode.Hide()
			SetSize(-1,155)
		EndIf
	End Method


	Method DrawBackground()
		Super.DrawBackground()

		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		Local outer:TRectangle = GetScreenRect().Copy()
		Local contentX:Int = skin.GetContentX(outer.GetX())
		Local contentY:Int = skin.GetContentY(outer.GetY())
		Local contentW:Int = skin.GetContentW(outer.GetW())
		Local contentH:Int = skin.GetContentH(outer.GetH())


		If concept And concept.script.IsEpisode()
			Local topH:Int = Int((contentH - 35)/2.0) - 8
			skin.RenderContent(contentX, contentY, contentW, topH, "1_top")
			skin.RenderContent(contentX, contentY + topH, contentW, contentH - topH - 35, "1")
		Else
			skin.RenderContent(contentX, contentY, contentW, contentH - 35, "1_top")
		EndIf

		skin.RenderContent(contentX, contentY+contentH-35, contentW, 35, "1_bottom")

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())
	End Method


	Method onClickClearInputButton:Int( triggerEvent:TEventBase )
		Local button:TGUIButton = TGUIButton( triggerEvent.GetSender() )
		Select button
			Case clearTitle
				If inputTitle.GetValue() = "" And concept And concept.script
					inputTitle.SetValue(concept.script.GetTitle())
				Else
					inputTitle.SetValue("")
				EndIf
				'TODO: setfocus
			Case clearSubTitle
				inputSubTitle.SetValue("")
			Case clearDescription
				inputDescription.SetValue("")
			Case clearSubDescription
				inputSubDescription.SetValue("")
		EndSelect
	End Method


	Method onChangeInputValues:Int( triggerEvent:TEventBase )
		Local Input:TGUIInput = TGUIInput( triggerEvent.GetSender() )

		Select Input
			Case inputTitle
				'restore original title when empty?
			Case inputSubTitle
				'restore original title when empty?
			Case inputDescription
				'restore original description when empty?
			Case inputSubDescription
				'restore original description when empty?
		EndSelect
	End Method
End Type



Type TGUICastSelectList Extends TGUISelectList
	'the job/gender the selection list is used for
	Field selectJobID:Int = -1
	Field selectGenderID:Int = -1
	'the job/gender the selection is currently filtered for
	Field filteredJobID:Int = -1
	Field filteredGenderID:Int = -1
	Field _eventListeners:TEventListenerBase[]


    Method Create:TGUICastSelectList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		Return Self
	End Method


	Method Remove:Int()
		EventManager.UnregisterListenersArray(_eventListeners)
		Return Super.Remove()
	End Method


	Method GetJobID:Int(entry:TGUIListItem)
		Return selectJobID
	End Method
End Type




Type TGUICastSlotList Extends TGUISlotList
	'contains job for each slot
	Field slotJob:TPersonProductionJob[]
	Field _eventListeners:TEventListenerBase[]
	Field selectCastWindow:TGUISelectCastWindow
	'the currently clicked/selected slot for a cast selection
	Field selectCastSlot:Int = -1


    Method Create:TGUICastSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		_eventListeners :+ [ EventManager.registerListenerMethod( "guiModalWindow.onClose", Self, "onCloseSelectCastWindow", "TGUISelectCastWindow") ]

		Return Self
	End Method


	Method SelectCastWindowIsOpen:Int()
		If Not selectCastWindow Then Return False
		Return Not selectCastWindow.IsClosed()
	End Method


	Method Remove:Int()
		EventManager.UnregisterListenersArray(_eventListeners)
		Return Super.Remove()
	End Method


	'override
	Method SetItemLimit:Int(limit:Int)
		If Not slotJob
			slotJob = New TPersonProductionJob[ limit ]
		Else
			slotJob = slotJob[.. limit]
		EndIf
		Return Super.SetItemLimit(limit)
	End Method


	Method SetSlotJob:Int(job:TPersonProductionJob, slotIndex:Int)
		If slotIndex < 0 Or slotIndex >= slotJob.length Then Return False

		If Not slotJob Then slotJob = New TPersonProductionJob[0]
		slotJob[slotIndex] = job
	End Method


	Method GetSlotJob:TPersonProductionJob(slotIndex:Int)
		If Not slotJob Or slotIndex < 0 Or slotIndex >= slotJob.length Then Return Null
		Return slotJob[slotIndex]
	End Method


	Method GetSlotJobID:Int(slotIndex:Int)
		Local j:TPersonProductionJob = GetSlotJob(slotIndex)

		If j Then Return j.job

		Return 0
	End Method


	'override
	Method EmptyList:Int()
		slotJob = New TPersonProductionJob[0]

		Return Super.EmptyList()
	End Method


	Method GetSlotCast:TPersonBase(slotIndex:Int)
		Local oldItem:TGUICastListItem = TGUICastListItem(GetItemBySlot(slotIndex))
		If Not oldItem Then Return Null
		Return oldItem.person
	End Method


	Method SetSlotCast(slotIndex:Int, person:TPersonBase)
		If slotIndex < 0 Or GetSlotAmount() <= slotIndex Then Return
		'skip if already done
		If GetSlotCast(slotIndex) = person Then Return

		'remove a potential gui list item
		Local i:TGUICastListItem = TGUICastListItem(GetItemBySlot(slotIndex))
		If i
			If i.person = person Then Return
			i.remove()
			'RemoveItem(i)
		EndIf


		If person
			'create gui even without a valid jobID (0).

			'print "SetSlotCast: AddItem " + slotIndex +"  "+person.GetFullName()
			i = New TGUICastListItem.CreateSimple(person, GetSlotJobID(slotIndex) )
			'hide the name of amateurs
			If Not person.IsCelebrity() Then i.isAmateur = True
			i.SetOption(GUI_OBJECT_DRAGABLE, True)
		Else
			i = Null
		EndIf

		AddItem( i, String(slotIndex) )
	End Method


	Method OpenSelectCastWindow(job:Int, gender:Int=-1)
		If selectCastWindow Then selectCastWindow.Remove()

		selectCastWindow = New TGUISelectCastWindow.Create(New TVec2D.Init(250,60), New TVec2D.Init(300,270), _limitToState+"_modal")
		selectCastWindow.SetZIndex(100000)
		selectCastWindow.selectJobID = job
		selectCastWindow.listOnlyJobID = job
		selectCastWindow.listOnlyGenderID = gender
		selectCastWindow.screenArea = New TRectangle.Init(0,0, 800, 383)
		selectCastWindow.Open() 'loads the cast
		GuiManager.Add(selectCastWindow)
	End Method


	Method GetJobID:Int(entry:TGUIListItem)
		Local slotIndex:Int = getSlot(entry)
		If slotIndex = -1 Then Return 0
		Local job:TPersonProductionJob = GetSlotJob(slotIndex)
		If job Then Return job.job
		Return 0
	End Method


	'override
	'react to clicks to empty slots
	Method onClick:Int(triggerEvent:TEventBase)
		'only interested in left click
		If triggerEvent.GetData().GetInt("button") <> 1 Then Return False

		Local coord:TVec2D = TVec2D(triggerEvent.GetData().Get("coord"))
		If Not coord Then Return False

		selectCastSlot = GetSlotByCoord(coord, True)
		If selectCastSlot >= 0 And TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
			Local jobID:Int = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.jobs[selectCastSlot].job
			Local genderID:Int = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.jobs[selectCastSlot].gender
			OpenSelectCastWindow(jobID, genderID)
		EndIf
	End Method


	Method Update:Int()
		'window is "modal"
		If selectCastWindow
'			selectCastWindow.Update()
			If selectCastWindow.IsClosed()
				GuiManager.Remove(selectCastWindow)
				selectCastWindow = Null
			EndIf
		Else
			Super.Update()
		EndIf
	End Method


'	Method DrawOverlay()
'		RecalculateElements()
'	End Method

	'override to draw unused slots
	Method DrawContent()
		Super.DrawContent()



		If RestrictViewport()
			SetAlpha 0.5 * GetAlpha()

			Local atPoint:TVec2D = GetScreenRect().position

			For Local slot:Int = 0 Until _slots.length
			'	local pos:TVec3D = GetSlotOrCoord(slot)
				If _slots[slot] Then Continue
				If slotJob.length < slot Then Continue

				Local coord:TVec3D = GetSlotCoord(slot)

				Local job:TPersonProductionJob = GetSlotJob(slot)

				Local genderHint:String
				If job
	'				local role:TProgrammeRole = GetProgrammeRoleCollection().GetByGUID(j.roleGUID)

					If job.gender = TVTPersonGender.MALE
						genderHint = " ("+GetLocale("MALE")+")"
					ElseIf job.gender = TVTPersonGender.FEMALE
						genderHint = " ("+GetLocale("FEMALE")+")"
					EndIf
				EndIf

	'TODO: nur zeichnen, wenn innerhalb "panel rect"
				If MouseManager._ignoreFirstClick 'touch mode
'					TGUICastListItem.DrawCast(atPoint.GetX() + pos.getX(), atPoint.GetY() + pos.getY(), _slotMinDimension.getX(), GetLocale("JOB_" + TVTPersonJob.GetAsString(GetSlotJobID(slot))) + genderHint, GetLocale("TOUCH_TO_SELECT_PERSON"), null, 0,0,0)
					TGUICastListItem.DrawCast(GetScreenRect().GetX() + coord.GetX(), GetScreenRect().GetY() + coord.GetY(), guiEntriesPanel.GetContentScreenRect().GetW()-2, GetLocale("JOB_" + TVTPersonJob.GetAsString(GetSlotJobID(slot))) + genderHint, GetLocale("TOUCH_TO_SELECT_PERSON"), Null, 0,0,0)
				Else
					TGUICastListItem.DrawCast(GetScreenRect().GetX() + coord.GetX(), GetScreenRect().GetY() + coord.GetY(), guiEntriesPanel.GetContentScreenRect().GetW()-2, GetLocale("JOB_" + TVTPersonJob.GetAsString(GetSlotJobID(slot))) + genderHint, GetLocale("CLICK_TO_SELECT_PERSON"), Null, 0,0,0)
				EndIf
			Next
			SetAlpha 2.0 * GetAlpha()

			ResetViewPort()
		EndIf


'		if selectCastWindow then selectCastWindow.Draw()
	End Method



	Method onCloseSelectCastWindow:Int( triggerEvent:TEventBase )
		Local closeButton:Int = triggerEvent.GetData().GetInt("closeButton", -1)
		If closeButton <> 1 Then Return False

		Local person:TPersonBase = selectCastWindow.GetSelectedPerson()
		If person
			SetSlotCast(selectCastSlot, person)
		EndIf
	End Method


	'override default event handler
	Function onDropOnTarget:Int( triggerEvent:TEventBase )
		'adjust cast slots...
		If Super.onDropOnTarget( triggerEvent )
			Local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
			If Not item Then Return False

			Local list:TGUICastSlotList = TGUICastSlotList(triggerEvent.GetReceiver())
			If Not list Then Return False

			Local slotNumber:Int = list.getSlot(item)

			list.SetSlotCast(slotNumber, item.person)
		EndIf

		Return True
	End Function
End Type




Type TGUICastListItem Extends TGUISelectListItem
	Field person:TPersonBase
	Field displayName:String = ""
	Field isAmateur:Int = False
	'the job this list item is "used for" (the dropdown-filter)
	Field displayJobID:Int = -1
	Field lastDisplayJobID:Int = -1
	Field selectJobID:Int = -1

	Global yearColor:TColor = New TColor.Create(80,80,80, 0.8)

	Const paddingBottom:Int	= 5
	Const paddingTop:Int = 0


	Method CreateSimple:TGUICastListItem(person:TPersonBase, displayJobID:Int)
		If not person Then Throw "TGUICastListItem.CreateSimple() - no person passed"

		'make it "unique" enough
		Self.Create(Null, Null, person.GetFullName())

		Self.displayName = person.GetFullName()
		Self.person = person
		Self.isAmateur = False

		Self.displayJobID = -1
		Self.selectJobID = displayJobID
		Self.lastDisplayJobID = displayJobID

		'resize it
		GetDimension()

		Return Self
	End Method


    Method Create:TGUICastListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetValueColor(TColor.Create(0,0,0))

		GUIManager.add(Self)

		Return Self
	End Method


	'override
	Method onFinishDrag:Int(triggerEvent:TEventBase)
		If Super.OnFinishDrag(triggerEvent)
			'invalidate displayJobID
			'print "invalidate jobID"
			displayJobID = -1
			Return True
		Else
			Return False
		EndIf
	End Method


	'override
	Method onFinishDrop:Int(triggerEvent:TEventBase)
		If Super.OnFinishDrop(triggerEvent)
			'refresh displayJobID
			displayJobID = -1
			GetDisplayJobID()
			Return True
		Else
			Return False
		EndIf
	End Method


	Method GetDisplayJobID:Int()
		'refresh displayJobID
		If displayJobID = -1
			Local parentList:TGUIListBase = TGUIListBase.FindGUIListBaseParent(Self._parent)

			'dragged ()items use their backup or the underlaying slot list
			If (Self._flags & GUI_OBJECT_DRAGGED)
				'only check items from the slot lists, not the select ones
				If TGUICastSlotList(parentList)
					Local slotListSlot:Int = TScreenHandler_SupermarketProduction.GetInstance().castSlotList.GetSlotByCoord( MouseManager.GetPosition() )
					If slotListSlot >= 0
						Local slotJob:Int = TGUICastSlotList(parentList).GetSlotJobID(slotListSlot)
						If slotJob > 0
							Return TGUICastSlotList(parentList).GetSlotJobID(slotListSlot)
						Else
							Return lastDisplayJobID
						EndIf
					EndIf
				EndIf

				Return lastDisplayJobID
			EndIf


			If TGUICastSelectList(parentList)
				'displayJobID = TGUICastSelectList(parentList).GetJobID(self)
				displayJobID = TGUICastSelectList(parentList).filteredJobID
			ElseIf TGUICastSlotList(parentList)
				displayJobID = TGUICastSlotList(parentList).GetJobID(Self)
				'print "slot: displayJobID = "+displayJobID
			Else
				'print "unknown: displayJobID = "+displayJobID
			EndIf

			If displayJobID = 0 Then displayJobID = lastDisplayJobID
		EndIf

		Return displayJobID
	End Method


	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))
		Local maxWidth:Int = 295
		If parentPanel Then maxWidth = parentPanel.GetContentScreenRect().GetW() '- GetScreenRect().GetW()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, GetSpriteFromRegistry("gfx_datasheet_cast_icon").GetHeight())

		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.SetSize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method


	'override to not draw anything
	'as "highlights" are drawn in "DrawValue"
	Method DrawBackground()
		'nothing
	End Method


	'override
	Method DrawValue()
		if not person then Throw "TGUICastListItem.DrawValue() - no person assigned"
		
		Local xpPercentage:Float = person.GetEffectiveJobExperiencePercentage( GetDisplayJobID() )
		Local sympathyPercentage:Float = person.GetChannelSympathy( GetPlayerBase().playerID )

		Local name:String = displayName
		If isAmateur And Not isDragged()
			If GetDisplayJobID() > 0 and TVTPersonJob.IsCastJob( GetDisplayJobID() )
				name = GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString( GetDisplayJobID() ))
			Else
				name = GetLocale("JOB_AMATEUR")
			EndIf
			displayName = name
		EndIf

		Local face:TImage = TImage(person.GetPersonalityData().GetFigureImage())
		DrawCast(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), name, "", face, xpPercentage, sympathyPercentage, 1)

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawCast(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), name, "", face, xpPercentage, 0, 1)

			SetBlend AlphaBlend
			SetAlpha 10.0 * GetAlpha()
		EndIf
	End Method


	Method DrawContent()
		If isSelected()
			SetColor 245,230,220
			Super.DrawContent()

			SetColor 220,210,190
			SetAlpha GetAlpha() * 0.10
			SetBlend LightBlend
			Super.DrawContent()
			SetBlend AlphaBlend
			SetAlpha GetAlpha() * 10

			SetColor 255,255,255
		Else
			Super.DrawContent()
		EndIf
	End Method


	Method DrawDatasheet(leftX:Float=30, rightX:Float=30)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= Int(leftX)
		Local sheetAlign:Int= 0
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - Int(rightX)
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		Local sheetCenterX:Float = sheetX
		If sheetAlign = 0
			sheetCenterX :+ 250/2 '250 is sheetWidth
		Else
			sheetCenterX :- 250/2 '250 is sheetWidth
		EndIf
		Local tri:Float[]=[sheetCenterX,sheetY+25, sheetCenterX,sheetY+90, GetScreenRect().GetX() + GetScreenRect().GetW()/2.0, GetScreenRect().GetY() + GetScreenRect().GetH()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		Local jobID:Int = selectJobID
		If jobID = -1 Then jobID = GetDisplayJobID()
		If person.IsCelebrity()
			ShowCastSheet(person, jobID, sheetX, sheetY, sheetAlign, False)
		Else
			'hide person name etc for non-celebs
			ShowCastSheet(person, jobID, sheetX, sheetY, sheetAlign, True)
		EndIf
	End Method


	Function DrawCast(x:Float, y:Float, w:Float, name:String, nameHint:String="", face:Object=Null, xp:Float, sympathy:Float, mood:Int)
		'Draw name bg
		'Draw xp bg + front bar
		'Draw sympathy bg + front bar
		'draw mood icon
		'draw Pic overlay
		'render text

		'avoid rendering on subpixels (sometimes renders ninepatch borders ...)
		x = Int(x)
		y = Int(y)

		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")
		Local nameSprite:TSprite = GetSpriteFromRegistry("gfx_datasheet_cast_name")
		Local iconSprite:TSprite = GetSpriteFromRegistry("gfx_datasheet_cast_icon")

		Local nameOffsetX:Int = 34, nameOffsetY:Int = 3
		Local nameTextOffsetX:Int = 38
		Local barOffsetX:Int = 34, barOffsetY:Int = nameOffsetY + nameSprite.GetHeight()
		Local barH:Int = skin.GetBarSize(100,-1, "cast_bar_xp").GetY()

		'=== NAME ===
		'face/icon-area covers 36px + shadow, place bar a bit "below"
		nameSprite.DrawArea(x + nameOffsetX, y + nameOffsetY, w - nameOffsetX, nameSprite.GetHeight())


		'=== BARS ===
		If nameHint = ""
			skin.RenderBar(x + nameOffsetX, y + barOffsetY, 200, -1, xp, -1.0, "cast_bar_xp")
			skin.RenderBar(x + nameOffsetX, y + barOffsetY + barH, 200, -1, sympathy, -1.0, "cast_bar_sympathy")
		EndIf

		'=== FACE / ICON ===
		iconSprite.Draw(x, y)

		'maybe "TPersonBase.GetFace()" ?
		If TSprite(face)
			TSprite(face).Draw(x+5, y+3)
		Else
			If TImage(face)
				DrawImageArea(TImage(face), x+1, y+3, 2, 4, 34, 33)
				'DrawImage(TProgrammePerson(person).GetFigureImage(), GetScreenRect().GetX(), GetScreenRect().GetY())
			EndIf
		EndIf

		If name Or nameHint
			Local border:TRectangle = nameSprite.GetNinePatchContentBorder()

			Local oldCol:TColor = New TColor.Get()

			SetAlpha( Max(0.6, oldCol.a) )
			If name
				skin.fontSemiBold.drawBlock( ..
					name, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop(), .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(15, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			EndIf

			SetAlpha( Max(0.6, oldCol.a) )
			If nameHint
				skin.fontNormal.drawBlock( ..
					nameHint, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop() + barOffsetY - 3, .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(15, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					ALIGN_RIGHT_CENTER, skin.textColorNeutral)
			EndIf

			SetAlpha (oldCol.a)
		EndIf
	End Function


	Function ShowCastSheet:Int(person:TPersonBase, jobID:Int=-1, x:Float,y:Float, align:Int=0, showAmateurInformation:Int = False)
		'=== PREPARE VARIABLES ===
		Local sheetWidth:Int = 250
		Local sheetHeight:Int = 0 'calculated later
		'move sheet to left when right-aligned
		If align = 1 Then x = x - sheetWidth

		Local skin:TDatasheetSkin = GetDatasheetSkin("cast")
		Local contentW:Int = skin.GetContentW(sheetWidth)
		Local contentX:Int = Int(x) + skin.GetContentX()
		Local contentY:Int = Int(y) + skin.GetContentY()

		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		Local titleH:Int = 18, jobDescriptionH:Int = 16, lifeDataH:Int = 15, lastProductionEntryH:Int = 15, lastProductionsH:Int = 50
		Local splitterHorizontalH:Int = 6
		Local boxH:Int = 0, barH:Int = 0
		Local boxAreaH:Int = 0, barAreaH:Int = 0, msgAreaH:Int = 0
		Local boxAreaPaddingY:Int = 4, barAreaPaddingY:Int = 4

		If showAmateurInformation
			jobDescriptionH = 0
			lifeDataH = 0
			lastProductionsH = 0

			'bereich fuer hinweis einfuehren -- dass  es sich um einen
			'non-celeb handelt der "Erfahrung" sammelt
		EndIf

		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(person.GetFullName(), contentW - 10, 100))

		'bar area starts with padding, ends with padding and contains
		'also contains 8 bars
		If person.IsCelebrity() And Not showAmateurInformation
			barAreaH = 2 * barAreaPaddingY + 7 * (barH + 2)
		EndIf

		'box area
		'contains 1 line of boxes + padding at the top
		boxAreaH = 1 * boxH + 1 * boxAreaPaddingY

		'total height
		sheetHeight = titleH + jobDescriptionH + lifeDataH + lastProductionsH + barAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			Local title:String = person.GetFullName()
			If showAmateurInformation
				title = GetLocale("JOB_AMATEUR")
			EndIf

			If titleH <= 18
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			Else
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			EndIf
		contentY :+ titleH


		If Not showAmateurInformation
			'=== JOB DESCRIPTION AREA ===
			If jobDescriptionH > 0
				skin.RenderContent(contentX, contentY, contentW, jobDescriptionH, "1")

				Local firstJobID:Int = -1
				For Local jobIndex:Int = 1 To TVTPersonJob.Count
					Local jobID:Int = TVTPersonJob.GetAtIndex(jobIndex)
					If Not person.HasJob(jobID) Then Continue

					firstJobID = jobID
					Exit
				Next

				Local genre:Int = 0
				if person.GetProductionData() 
					genre = person.GetProductionData().GetTopGenre()
				endif

				Local genreText:String = ""
				If genre >= 0 Then genreText = GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(genre))
				If genreText Then genreText = "~q" + genreText+"~q-"

				If firstJobID >= 0
					'add genre if you know the job
					skin.fontNormal.drawBlock(genreText + GetLocale("JOB_"+TVTPersonJob.GetAsString(firstJobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				Else
					'use the given jobID but declare as amateur
					If jobID > 0
						skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR_"+TVTPersonJob.GetAsString(jobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
					Else
						skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR"), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
					EndIf
				EndIf

				contentY :+ jobDescriptionH
			EndIf


			'=== LIFE DATA AREA ===
			skin.RenderContent(contentX, contentY, contentW, lifeDataH, "1")
			'splitter
			GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + 165, contentY, 2, jobDescriptionH)
			Local latinCross:String = Chr(10013) '† = &#10013 ---NOT--- &#8224; (the dagger-cross)
			If person.IsCelebrity()
				Local dob:String = GetWorldTime().GetFormattedDate( person.GetPersonalityData().GetDOB(), GameConfig.dateFormat)
				If person.GetAge() >= 0
					skin.fontNormal.drawBlock(dob + " (" + person.GetAge() + " " + GetLocale("ABBREVIATION_YEARS")+")", contentX + 5, contentY, 165 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				Else
					skin.fontNormal.drawBlock("**.**.****", contentX + 5, contentY, 165 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				EndIf
				skin.fontNormal.drawBlock(person.GetCountryCode(), contentX + 170 + 5, contentY, contentW - 170 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			EndIf
			contentY :+ lifeDataH


			'=== LAST PRODUCTIONS AREA ===
			skin.RenderContent(contentX, contentY, contentW, lastProductionsH, "2")

			contentY :+ 5
			If person.IsCelebrity() and person.GetProductionData()
				'last productions
				Local productionIDs:Int[] = person.GetProductionData().GetProducedProgrammeIDs()

				If productionIDs and productionIDs.length > 0
					Local i:Int = 0
					Local entryNum:Int = 0
					While i < productionIDs.length And entryNum < 3
						Local production:TProgrammeData = GetProgrammeDataCollection().GetByID( productionIDs[ i] )
						i :+ 1
						If Not production Then Continue

'						skin.fontSemiBold.drawBlock(production.GetYear(), contentX + 5, contentY + lastProductionEntryH*entryNum, contentW, lastProductionEntryH, null, skin.textColorNeutral)
						GetBitmapfont("default", 12, BOLDFONT).drawBlock(production.GetYear(), contentX + 5, contentY + lastProductionEntryH*entryNum + 1, contentW, lastProductionEntryH, Null, yearColor)
						If production.IsInProduction()
							GetBitmapfont("default", 12).drawBlock(production.GetTitle() + " (In Produktion)", contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, Null, skin.textColorNeutral)
						Else
						'	skin.fontNormal.drawBlock(production.GetTitle(), contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, null, skin.textColorNeutral)
							GetBitmapfont("default", 12).drawBlock(production.GetTitle(), contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, Null, skin.textColorNeutral)
						EndIf
						entryNum :+1
					Wend
				EndIf
			EndIf
			contentY :+ lastProductionsH - 5
		EndIf

		'=== BARS / BOXES AREA ===
		'background for bars + boxes
		If barAreaH + boxAreaH > 0
			skin.RenderContent(contentX, contentY, contentW, barAreaH + boxAreaH, "1_bottom")
		EndIf


		'===== DRAW CHARACTERISTICS / BARS =====
		'TODO: only show specific data of a cast, "all" should not be
		'      exposed until we eg. produce specific "insight"-shows ?
		'      -> or have some "agent" to pay to get such information

		If person.IsCelebrity()
			'bars have a top-padding
			contentY :+ barAreaPaddingY
			'XP
			Local xpValue:Float = person.GetEffectiveJobExperiencePercentage(jobID)
			skin.RenderBar(contentX + 5, contentY, 100, 12, xpValue)
			skin.fontSemiBold.drawBlock(GetLocale("CAST_EXPERIENCE"), contentX + 5 + 100 + 5, contentY, 125, 15, Null, skin.textColorLabel)
			contentY :+ barH + 2


			Local genreDefinition:TMovieGenreDefinition
			If TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
				Local script:TScript = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script
				If script Then genreDefinition = GetMovieGenreDefinition( script.mainGenre )
			EndIf

			Local attributes:Int[] = [TVTPersonPersonality.FAME, ..
			                          TVTPersonPersonality.SKILL, ..
			                          TVTPersonPersonality.POWER, ..
			                          TVTPersonPersonality.HUMOR, ..
			                          TVTPersonPersonality.CHARISMA, ..
			                          TVTPersonPersonality.APPEARANCE ..
			                         ]
			For Local attributeID:Int = EachIn attributes
				Local mode:Int = 0

				Local attributeFit:Float = 0.0
				Local attributeGenre:Float = 0.0
				Local attributePerson:Float = 0.0
				If genreDefinition
					attributeGenre = genreDefinition.GetCastAttribute(jobID, attributeID)
					attributePerson = person.GetPersonalityData().GetAttribute(attributeID)
				EndIf

				'unimportant attribute / no bonus/malus for this attribute
				If MathHelper.AreApproximatelyEqual(attributeGenre, 0.0)
					mode = 1
				'neutral
'				elseif MathHelper.AreApproximatelyEqual(attributePerson, 0.0)
'					mode = 2
				'negative
				ElseIf attributeGenre < 0
					mode = 3
				'positive
				Else
					mode = 4
				EndIf
'print "ShowCastSheet: jobID="+jobID + "  attributeID=" +attributeID +"  attributeGenre="+attributeGenre +"  mode="+mode

				'set "skill" neutral if not assigned "negative/positive" already
				If mode = 1 And attributeID = TVTPersonPersonality.SKILL
					mode = 2
				EndIf


				Select mode
					'unused
					Case 1
						Local oldA:Float = GetAlpha()
						SetAlpha oldA * 0.5
						skin.RenderBar(contentX + 5, contentY, 100, 12, person.GetPersonalityData().GetAttribute(attributeID))
						SetAlpha oldA * 0.4
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTPersonPersonality.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, Null, skin.textColorLabel)
						SetAlpha oldA
					'neutral
					Case 2
						skin.RenderBar(contentX + 5, contentY, 100, 12, person.GetPersonalityData().GetAttribute(attributeID))
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTPersonPersonality.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, Null, skin.textColorLabel)
					'negative
					Case 3
						skin.RenderBar(contentX + 5, contentY, 100, 12, person.GetPersonalityData().GetAttribute(attributeID))
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTPersonPersonality.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, Null, skin.textColorBad)

					'positive
					Case 4
						skin.RenderBar(contentX + 5, contentY, 100, 12, person.GetPersonalityData().GetAttribute(attributeID))
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTPersonPersonality.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, Null, skin.textColorGood)
				End Select
				contentY :+ barH + 2
			Next
		EndIf
	'hidden?
	Rem
		'Scandalizing
		skin.RenderBar(contentX + 5, contentY, 100, 12, cast.GetScandalizing())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_SCANDALIZING"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
	endrem

		'=== MESSAGES ===
		'TODO: any chances of "not available from day x-y of 1998"

		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		If msgAreaH = 0 Then contentY :+ boxAreaPaddingY

		If person.IsCelebrity()
			contentY :+ boxAreaPaddingY
		EndIf
		If jobID >= 0
			skin.fontSemibold.drawBlock(GetLocale("JOB_"+TVTPersonJob.GetAsString(jobID)), contentX + 5, contentY, 94, 25, ALIGN_LEFT_CENTER, skin.textColorLabel)
			skin.RenderBox(contentX + 5 + 94, contentY, contentW - 10 - 94 +1, -1, MathHelper.DottedValue(person.GetJobBaseFee(jobID, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.blocks)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		EndIf
		contentY :+ boxH


		'=== OVERLAY / BORDER ===
		skin.RenderBorder(Int(x), Int(y), sheetWidth, sheetHeight)
	End Function

End Type




Type TGUIProductionCompanyDropDownItem Extends TGUIDropDownItem
	'company is stored in data->"ProductionCompany"

	Const paddingBottom:Int	= 6
	Const paddingTop:Int = 0
	Global xpColor:TColor = TColor.Create(70,85,160)
	Global sympathyColor:TColor = TColor.Create(70,160,90)


	Method CreateSimple:TGUIProductionCompanyDropDownItem(company:TProductionCompanyBase)
		'make it "unique" enough
		Self.Create(Null, New TVec2D.Init(100, 30), company.name+" [Lvl: "+company.GetLevel()+"]")

		data = New TData.Add("productionCompany", company)

		'resize it
		GetDimension()

		Return Self
	End Method
	
	
	Method GetBaseValue:String()
		Local company:TProductionCompanyBase = TProductionCompanyBase(data.Get("productionCompany"))
		If company
			Return company.name+" [Lvl: "+company.GetLevel()+"]"
		Else
			Return "Unknown company [Lvl: /]"
		EndIf
	End Method


	'override
	Method DrawValue()
		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")
		Local company:TProductionCompanyBase = TProductionCompanyBase(data.Get("productionCompany"))

		'Super.DrawValue()
		skin.fontSmallCaption.DrawBlock(company.name, GetScreenRect().GetX()+2, GetScreenRect().GetY(), GetScreenRect().GetW()-4 - 20, GetScreenRect().GetH(), ALIGN_LEFT_TOP, skin.textColorNeutral, 0,1,1.0, True, True)
		skin.fontSmall.DrawBlock("Lvl: "+company.GetLevel(), GetScreenRect().GetX()+2, GetScreenRect().GetY(), GetScreenRect().GetW()-4, GetScreenRect().GetH(), ALIGN_RIGHT_TOP, skin.textColorNeutral)


		Local barH:Int = skin.GetBarSize(100,-1, "cast_bar_xp").GetY()
		Local bottomY:Int = GetScreenRect().GetY() + rect.GetH()

		skin.RenderBar(GetScreenRect().GetX() + 1, bottomY - 2*barH - paddingBottom, 80, -1, company.GetLevelExperiencePercentage(), -1, "cast_bar_xp")
		skin.RenderBar(GetScreenRect().GetX() + 1, bottomY - 1*barH - paddingBottom, 80, -1, company.GetChannelSympathy( GetPlayerBase().playerID ), -1, "cast_bar_sympathy")

		If IsHovered() And (Time.MillisecsLong() / 1500) Mod 3 = 0 'every 3s for 1.5s
			skin.fontSmall.drawBlock("XP", GetScreenRect().GetX() + 76, bottomY - 2*barH - paddingBottom -2, 30, 2*barH+4, ALIGN_RIGHT_CENTER, xpColor)
			skin.fontSmall.drawBlock("SYMP", GetScreenRect().GetX() + 2, bottomY - 2*barH - paddingBottom -2, GetScreenRect().GetW()-4, 2*barH+4, ALIGN_RIGHT_CENTER, sympathyColor)
		Else
			skin.fontSmall.drawBlock(Int(company.GetLevelExperiencePercentage()*100)+"%", GetScreenRect().GetX() + 76, bottomY - 2*barH - paddingBottom -2, 30, 2*barH+4, ALIGN_RIGHT_CENTER, xpColor)
			skin.fontSmall.drawBlock(Int(company.GetChannelSympathy( GetPlayerBase().playerID )*100)+"%", GetScreenRect().GetX() + 2, bottomY - 2*barH - paddingBottom -2, GetScreenRect().GetW()-4, 2*barH+4, ALIGN_RIGHT_CENTER, sympathyColor)
		EndIf
	End Method
End Type
