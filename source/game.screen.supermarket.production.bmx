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
	Field refreshControlEnablement:Int = True {nosave}
	Field haveToRefreshFinishProductionConceptGUI:Int = True

	Field currentProductionConcept:TProductionConcept
	Global castSortType:Int = 0

	Global evKey_supermarket_customproduction:TLowerString = new TLowerString("supermarket_customproduction")
	Global evKey_supermarket_customproduction_productionconceptbox:TLowerString = new TLowerString("supermarket_customproduction_productionconceptbox")
	Global evKey_supermarket_customproduction_newproduction:TLowerString = new TLowerString("supermarket_customproduction_newproduction")
	Global evKey_supermarket_customproduction_productionbox:TLowerString = new TLowerString("supermarket_customproduction_productionbox")
	Global evKey_supermarket_customproduction_productionbox_modal:TLowerString = new TLowerString("supermarket_customproduction_productionbox_modal")
	Global evKey_supermarket_customproduction_castbox:TLowerString = new TLowerString("supermarket_customproduction_castbox")
	Global evKey_supermarket_customproduction_castbox_modal:TLowerString = new TLowerString("supermarket_customproduction_castbox_modal")


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
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickCastItem, "TGUICastListItem") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickEditTextsButton, "TGUIButton") ]
		'we want to know if we hover a specific block
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverCastItem, "TGUICastListItem" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnMouseOver, onMouseOverProductionConceptItem, "TGuiProductionConceptSelectListItem" ) ]



		'GUI -> LOGIC
		'finish planning/make production ready
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickFinishProductionConcept, "TGUIButton") ]
		'changes to the cast (slot) list
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_AddedItem, onProductionConceptChangeCastSlotList, "TGUICastSlotList") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIList_RemovedItem, onProductionConceptChangeCastSlotList, "TGUICastSlotList") ]
		'changes to production focus sliders
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnChangeValue, onProductionConceptChangeFocusSliders, "TGUISlider") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnSetFocus, onProductionConceptSetFocusSliderFocus, "TGUISlider") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnRemoveFocus, onProductionConceptRemoveFocusSliderFocus, "TGUISlider") ]
		'changes to production company dropdown
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIDropDown_OnSelectEntry, onProductionConceptChangeProductionCompanyDropDown, "TGUIDropDown") ]
		'changes to production company levels / skill points
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProductionCompany_OnChangeLevel, onProductionCompanyChangesLevel) ]
		'select a production concept
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUISelectList_OnSelectEntry, onSelectProductionConcept) ]
		'edit title/description
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIModalWindow_OnClose, onCloseEditTextsWindow, "TGUIProductionEditTextsModalWindow") ]


		'LOGIC -> GUI
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProductionConcept_SetCast, onProductionConceptChangeCast) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProductionConcept_SetProductionCompany, onProductionConceptChangeProductionCompany) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.ProductionFocus_SetFocus, onProductionConceptChangeProductionFocus) ]

		'to reload concept list when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterScreen, screen) ]
		'refresh finish button on money change (maybe no longer enough money to finish... )
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.PlayerFinance_OnChangeMoney, onPlayerChangeMoney) ]


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
		Local result:Int = False
		If castSlotList.SelectCastWindowIsOpen()
			castSlotList.selectCastWindow.Close(2)
			result = True
		EndIf
		
		if currentProductionConcept
			result = True
		EndIf
		SetCurrentProductionConcept(Null)
		If productionCompanySelect Then productionCompanySelect.SetOpen(0)

		Return result
	End Method


	Function onUpdate:Int( triggerEvent:TEventBase )
		GetInstance().Update()
	End Function


	Function onDraw:Int( triggerEvent:TEventBase )
		GetInstance().Render()
	End Function


	Function onEnterScreen:Int( triggerEvent:TEventBase )
		GetInstance().refreshControlEnablement = True
		GetInstance().ReloadProductionCompanySelect()
		GetInstance().ReloadProductionConceptContent()
		'show correct production company when re-entering the screen
		GetInstance().RefreshProductionConceptGUI()
	End Function


	Function onPlayerChangeMoney:Int( triggerEvent:TEventBase )
		Local pf:TPlayerFinance = TPlayerFinance(triggerEvent.GetSender())
		If Not pf Then throw "onPlayerChangeMoney: Incorrect event sender for event PlayerFinance_OnChangeMoney."
		
		If pf.playerID = GetObservedPlayerID() 
			GetInstance().haveToRefreshFinishProductionConceptGUI = True
		EndIf

		Return True
	End Function


	'reset gui elements to their initial state (new production)
	Method ResetProductionConceptGUI()
		refreshingProductionGUI = True

		For Local i:Int = 0 To productionFocusSlider.length -1
			productionFocusSlider[i].SetValue(0)
		Next

		productionCompanySelect.SetSelectedEntry(Null)
		productionCompanySelect.SetValue(GetLocale("PRODUCTION_COMPANY"))

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
		haveToRefreshFinishProductionConceptGUI = False

		If Not currentProductionConcept
			finishProductionConcept.Disable()
			finishProductionConcept.SetSpriteName("gfx_gui_button.datasheet")
			finishProductionConcept.SetValue("")

			Return
		EndIf

		'remove current concept if its produciton has started
		If currentProductionConcept.isProductionStarted() or currentProductionConcept.isProductionFinished()
			SetCurrentProductionConcept (Null, Null)
			GetInstance().ReloadProductionConceptContent()
			Return
		EndIf

		editTextsButton.Enable()
		If currentProductionConcept.IsProduceable()
			editTextsButton.Disable()
			finishProductionConcept.Disable()
			finishProductionConcept.SetSpriteName("gfx_gui_button.datasheet.informative")
			finishProductionConcept.SetValue("|b|"+GetLocale("FINISHED_PLANNING")+"|/b|")
		ElseIf currentProductionConcept.IsPlanned()
			If GetPlayerBase().GetFinance().CanAfford(currentProductionConcept.GetDepositCost())
				finishProductionConcept.Enable()
				finishProductionConcept.SetSpriteName("gfx_gui_button.datasheet.positive")
			Else
				finishProductionConcept.Disable()
				finishProductionConcept.SetSpriteName("gfx_gui_button.datasheet.negative")
			EndIf
			finishProductionConcept.SetValue("|b|"+GetLocale("FINISH_PLANNING")+"|/b|~n" + GetLocale("AND_PAY_DOWN_MONEY").Replace("%money%", "|b|"+GetFormattedCurrency(currentProductionConcept.GetDepositCost())+"|/b|"))
		Else
			finishProductionConcept.Disable()
			finishProductionConcept.SetSpriteName("gfx_gui_button.datasheet")
			finishProductionConcept.SetValue("|b|"+GetLocale("PLANNING")+"|/b|~n(" + GetLocale("MONEY_TO_PAY_DOWN").Replace("%money%", "|b|"+GetFormattedCurrency(currentProductionConcept.GetDepositCost())+"|/b|") +")")
		EndIf
	End Method


	'set all gui elements to the values of the production concept
	Method RefreshProductionConceptGUI()
		refreshControlEnablement = True
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
		If productionCompanyItem 
			productionCompanySelect.SetSelectedEntry(productionCompanyItem)
			productionCompanySelect.RefreshValue()
		EndIf

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
		ReloadProductionCompanySelect()
		'reloading concepts would also recreate the concept list
		'ReloadProductionConceptContent()
		'so we just ensure concept is visible
		productionConceptList.EnsureEntryIsVisible( productionConceptList.GetSelectedEntry() )


		'=== TAKE OVER OLD CONCEPT VALUES ===
		'only take over if not already "finished planning"
		If currentProductionConcept and not currentProductionConcept.IsProduceable()
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
		editTextsWindow = New TGUIProductionEditTextsModalWindow.Create(New SVec2I(250,60), New SVec2I(300,220), "supermarket_customproduction_productionbox_modal")
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
			window.concept.script.SetCustomTitle(title)
		EndIf
		If description <> window.concept.GetDescription()
			window.concept.SetCustomDescription(description)
			'also assign this to the script 
			'(means for a multi-concept-script the last custom value
			' will be displayed in the studio/script displays)
			window.concept.script.SetCustomDescription(description)
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

		GetInstance().refreshControlEnablement = True
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
		GetInstance().productionCompanySelect.RefreshValue()

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
		GetInstance().haveToRefreshFinishProductionConceptGUI = True

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
	Function onProductionConceptChangeCast:Int(triggerEvent:TEventBase)
		If Not GetInstance().currentProductionConcept Then Return False
		If GetInstance().currentProductionConcept <> triggerEvent.GetSender() Then Return False

		GetInstance().haveToRefreshFinishProductionConceptGUI = True
		
		Return True
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
			If item And triggerEvent.GetEventKey() = GUIEventKeys.GUIList_AddedItem
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
		GetInstance().RefreshControlEnablement = True
		'already at last step
		If GetInstance().currentProductionConcept.IsProduceable() Then Return False
		'nothing to do (should be disabled already)
		If GetInstance().currentProductionConcept.IsUnplanned() Then Return False

		If GetInstance().currentProductionConcept.IsPlanned()
			editTextsButton.disable()
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
			castSlotList = New TGUICastSlotList.Create(New SVec2I(300,200), New SVec2I(200, 200), "supermarket_customproduction_castbox")
		EndIf

		castSlotList.SetSlotMinDimension(230, 42)
		castSlotList._fixedSlotDimension = True
		'occupy the first free slot?
		'castSlotList.SetAutofillSlots(true)


		'=== PRODUCTION COMPANY ===
		'==========================

		'=== PRODUCTION COMPANY SELECT ===
		If Not productionCompanySelect
			productionCompanySelect = New TGUIDropDown.Create(New SVec2I(600,200), New SVec2I(150,-1), GetLocale("PRODUCTION_COMPANY"), 128, "supermarket_customproduction_productionbox")
			productionCompanySelect.SetListContentHeight(4*35)
		EndIf
		'entries added during ReloadProductionConceptContent()


		'=== PRODUCTION WEIGHTS ===
		For Local i:Int = 0 To productionFocusSlider.length -1
			If Not productionFocusSlider[i]
				productionFocusSlider[i] = New TGUISlider.Create(New SVec2I(640,300 + i*25), New SVec2I(150,22), "0", "supermarket_customproduction_productionbox")
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
			editTextsButton = New TGUIButton.Create(New SVec2I(530, 26), New SVec2I(30, 28), "...", "supermarket_customproduction_newproduction")
		EndIf
		editTextsButton.disable()
		editTextsButton.caption.SetSpriteName("gfx_datasheet_icon_pencil")
		editTextsButton.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_ONLY )
		editTextsButton.SetSpriteName("gfx_gui_button.datasheet")


		'=== FINISH CONCEPT BUTTON ===
		If Not finishProductionConcept
			finishProductionConcept = New TGUIButton.Create(New SVec2I(20, 220), New SVec2I(100, 28), "...", "supermarket_customproduction_newproduction")
		EndIf
		finishProductionConcept.caption.SetSpriteName("gfx_datasheet_icon_money")
		finishProductionConcept.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_LEFT_OF_TEXT3 )
		finishProductionConcept.disable()
		finishProductionConcept.SetSpriteName("gfx_gui_button.datasheet")
		finishProductionConcept.SetFont( screenDefaultFont )

		'=== PRODUCTION TAKEOVER CHECKBOX ===
		If Not productionConceptTakeOver
			productionConceptTakeOver = New TGUICheckbox.Create(New SVec2I(20, 220), New SVec2I(100, 28), GetLocale("TAKE_OVER_SETTINGS"), "supermarket_customproduction_productionconceptbox")
		EndIf
		productionConceptTakeOver.SetFont( screenDefaultFont )

		'=== PRODUCTION CONCEPT LIST ===
		If Not productionConceptList
			productionConceptList = New TGUISelectList.Create(New SVec2I(20,20), New SVec2I(150,180), "supermarket_customproduction_productionconceptbox")
		EndIf
		'scroll one concept per "scroll"
		productionConceptList.scrollItemHeightPercentage = 1.0
		productionConceptList.SetAutosortItems(True) 'sort concepts


		ReloadProductionConceptContent()
		ReloadProductionCompanySelect()
	End Method
	
	
	Method ReloadProductionCompanySelect()
		'=== PRODUCTION COMPANY SELECT ===
		productionCompanySelect.list.EmptyList()
		productionCompanySelect.SetSelectedEntry(Null)
		productionCompanySelect.SetValue(GetLocale("PRODUCTION_COMPANY"))

		'add some items to that list
		For Local p:TProductionCompanyBase = EachIn GetProductionCompanyBaseCollection().entries.values()
			'base items do not have a size - so we have to give a manual one
'			local item:TGUIDropDownItem = new TGUIDropDownItem.Create(null, null, p.name+" [Lvl: "+p.GetLevel()+"]")
'			item.data = new TData.Add("productionCompany", p)
			Local item:TGUIProductionCompanyDropDownItem = New TGUIProductionCompanyDropDownItem.CreateSimple(p)
			productionCompanySelect.AddItem( item )
		Next
		productionCompanySelect.SetListContentHeight(4, 0)
	End Method


	Method ReloadProductionConceptContent()
		'=== CONCEPTS ===
		local selectedBackup:TGuiProductionConceptSelectListItem = TGuiProductionConceptSelectListItem(productionConceptList.GetSelectedEntry())
		local selectedProductionConcept:TProductionConcept
		if selectedBackup then selectedProductionConcept = selectedBackup.productionConcept
		selectedBackup = Null
		
		productionConceptList.EmptyList()


		'only valid players can have concept lists
		Local observedPlayerID:Int = GetObservedPlayerID()
		If observedPlayerID <= 0 Then Return

		
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(observedPlayerID)
		If not programmeCollection Then Return
		
		Local productionConcepts:TProductionConcept[]
		For Local productionConcept:TProductionConcept = EachIn programmeCollection.GetProductionConcepts()
			productionConcepts :+ [productionConcept]
		Next

		'sort by series/name
		productionConcepts.Sort(True)

		For Local productionConcept:TProductionConcept = EachIn productionConcepts
			'skip concepts already getting produced
			If productionConcept.IsProductionStarted() Then Continue

			Local item:TGuiProductionConceptSelectListItem = New TGuiProductionConceptSelectListItem.Create(New SVec2I(0,0), New SVec2I(150,40), "concept")
			item.SetMode( TGuiProductionConceptSelectListItem.MODE_SUPERMARKET ) 

			'done in TGuiProductionConceptSelectListItem.New() already
			'item.SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, True)

			item.SetProductionConcept(productionConcept)
			
			'mark current item as the previously selected one
			if selectedProductionConcept = productionConcept
				selectedBackup = item
			endif

			'base items do not have a size - so we have to give a manual one
			productionConceptList.AddItem( item )
		Next

		productionConceptList.InvalidateLayout()

		'restore backup
		if selectedBackup
			productionConceptList.ScrollAndSelectItem(selectedBackup)
		endif
	End Method


	Method Update()
		'gets refilled in gui-updates
		hoveredGuiCastItem = Null
		'reset hovered concept (will be auto-reassigned by the list)
		hoveredGuiProductionConcept = Null

		If refreshControlEnablement
			'disable / enable elements according to state
			If Not currentProductionConcept Or currentProductionConcept.IsProduceable()
				For Local i:Int = 0 To productionFocusSlider.length -1
					Local slider:TGUISlider = productionFocusSlider[i]
					'ensure correct value is shown for finished concepts
					If currentProductionConcept
						slider.SetValue(currentProductionConcept.GetProductionFocus(slider.data.GetInt("focusIndex")))
					EndIf
					slider.Disable()
				Next
				productionCompanySelect.Disable()
				castSlotList.Disable()
			Else
				'disable sliders if no company is selected
				if not productionCompanySelect.GetSelectedEntry() 
					If productionFocusSlider[0].IsEnabled()
						For Local slider:TGUISlider = EachIn productionFocusSlider
							slider.Disable()
						Next
					EndIf
				Else
					Local focusAspectCount:int = currentProductionConcept.productionFocus.GetFocusAspectCount()
					If focusAspectCount > 0 and Not productionFocusSlider[0].IsEnabled()
						For Local i:Int = 0 To productionFocusSlider.length -1
							If focusAspectCount > i
								productionFocusSlider[i].Enable()
							EndIf
						Next
					EndIf
				EndIf

				productionCompanySelect.Enable()
				castSlotList.Enable()
			EndIf
			refreshControlEnablement = False
		EndIf

		GuiManager.Update(evKey_supermarket_customproduction_castbox_modal)
		GuiManager.Update(evKey_supermarket_customproduction_productionbox_modal)
		GuiManager.Update(evKey_supermarket_customproduction_productionconceptbox)
		GuiManager.Update(evKey_supermarket_customproduction_newproduction)
		GuiManager.Update(evKey_supermarket_customproduction_productionbox)
		GuiManager.Update(evKey_supermarket_customproduction_castbox)

		If MouseManager.IsClicked(2)
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
		If haveToRefreshFinishProductionConceptGUI
			RefreshFinishProductionConceptGUI()
		EndIf

		SetColor(255,255,255)

		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		'where to draw
		Local outer:SRectI = New SRectI
		'calculate position/size of content elements
		Local content:SRectI = New SRectI()
		Local outerSizeH:Int = skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		Local outerH:Int = 0 'size of the "border"

		Local titleH:Int = 18, subTitleH:Int = 16
		Local boxAreaH:Int = 0, buttonAreaH:Int = 0, bottomAreaH:Int = 0, msgH:Int = 0
		Local boxAreaPaddingY:Int = 4, buttonAreaPaddingY:Int = 4
		Local msgPaddingY:Int = 4

		msgH = skin.GetMessageSize(100, -1, "").y

		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).GetBoxHeight(GetLocale("PRODUCTION_CONCEPTS"), content.w - 10, 100))


		'=== PRODUCTION CONCEPT LIST ===
		Local availableHeight:Int = 205
		'resize list
		If Not currentProductionConcept And productionConceptList.entries.count() > 3
			availableHeight = 370
		EndIf

		outer = new SRectI(10, 15, 210, availableHeight)
		content = skin.GetContentRect(outer)
		Local contentY:Int = content.y
		
		Local checkboxArea:Int = productionConceptTakeOver.rect.h + 0*buttonAreaPaddingY

		Local listH:Int = content.h - titleH - checkboxArea

		skin.RenderContent(content.x, contentY, content.w, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).DrawBox(GetLocale("PRODUCTION_CONCEPTS"), content.x + 5, contentY, content.w - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ titleH
		skin.RenderContent(content.x, contentY, content.w, listH , "2")
		'reposition/resize list and keep scroll position
		If productionConceptList.rect.x <> content.x + 5 OR productionConceptList.getHeight() <> listH - 6
			Local scrollPosition:Float = productionConceptList.GetScrollPercentageY()
			productionConceptList.SetPosition(content.x + 5, contentY + 3)
			productionConceptList.SetSize(content.w - 10, listH - 6)
			'if for the enlarged list the scrollbar is still visible restore the scroll position
			If Not currentProductionConcept And productionConceptList.guiScrollerV And productionConceptList.guiScrollerV.isVisible() Then productionConceptList.SetScrollPercentageY(scrollPosition-0.001)
		EndIf
		contentY :+ listH

		skin.RenderContent(content.x, contentY, content.w, content.h - (listH + titleH) , "1_bottom")
		'reposition checkbox
		productionConceptTakeOver.SetPosition(content.x + 5, contentY + buttonAreaPaddingY)
		productionConceptTakeOver.SetSize(content.w - 10)
		contentY :+ content.h - (listH + titleH)

		skin.RenderBorder(outer.x, outer.y, outer.w, outer.h)


		If currentProductionConcept
			'=== CHECK AND START BOX ===
			outer = New SRectI(10, 225, 210, 145)
			content = skin.GetContentRect(outer)
			contentY = content.y

			buttonAreaH = finishProductionConcept.rect.h + 2*buttonAreaPaddingY

			skin.RenderContent(content.x, contentY, content.w, content.h - buttonAreaH, "1_top")
			contentY :+ 3
			skin.fontBold.DrawSimple(GetLocale("MOVIE_CAST"), content.x + 5, contentY - 1, skin.textColorLabel)
			skin.fontNormal.DrawBox(MathHelper.DottedValue(currentProductionConcept.GetCastCost()), content.x + 5, contentY -1, content.w - 10, -1, sALIGN_RIGHT_TOP, skin.textColorBad)
			contentY :+ subtitleH
			skin.fontBold.DrawSimple(GetLocale("PRODUCTION"), content.x + 5, contentY - 1, skin.textColorLabel)
			skin.fontNormal.DrawBox(MathHelper.DottedValue(currentProductionConcept.GetProductionCost()), content.x + 5, contentY - 1, content.w - 10, -1, sALIGN_RIGHT_TOP, skin.textColorBad)
			contentY :+ subtitleH

			SetColor 150,150,150
			DrawRect(content.x + 5, contentY - 1, content.w - 10, 1)
			SetColor 255,255,255

			contentY :+ 1
			skin.fontBold.DrawSimple(GetLocale("TOTAL_COSTS"), content.x + 5, contentY - 1, skin.textColorNeutral)
			skin.fontBold.DrawBox(MathHelper.DottedValue(currentProductionConcept.GetTotalCost()), content.X + 5, contentY - 1, content.w - 10, -1, sALIGN_RIGHT_TOP, skin.textColorBad)
			contentY :+ subtitleH

			contentY :+ 10
			skin.fontBold.DrawSimple(GetLocale("DURATION"), content.x + 5, contentY-1, skin.textColorNeutral)
			skin.fontNormal.DrawBox(TWorldtime.GetHourMinutesLeft(currentProductionConcept.GetBaseProductionTime(), True), content.x + 5, contentY - 1, content.w - 10, -1, sALIGN_RIGHT_TOP, skin.textColorNeutral)

			contentY :+ subtitleH

			contentY :+ (content.h- buttonAreaH) - 4*subtitleH - 3 -1 - 10

			skin.RenderContent(content.x, contentY, content.w, buttonAreaH, "1_bottom")
			'reposition button
			finishProductionConcept.SetPosition(content.x + 5, contentY + buttonAreaPaddingY)
			finishProductionConcept.SetSize(content.w - 10, 38)
			contentY :+ buttonAreaH

			skin.RenderBorder(outer.x, outer.y, outer.w, outer.h)


			'=== CAST / MESSAGE BOX ===
			'calc height
			Local castAreaH:Int = 215
			Local msgAreaH:Int = 0
			If Not currentProductionConcept.IsCastComplete() Then msgAreaH :+ msgH + msgPaddingY
			If Not currentProductionConcept.IsFocusPointsComplete() Then msgAreaH :+ msgH + msgPaddingY


			outer = new SRectI(225, 15, 350, outerSizeH + titleH + subTitleH + castAreaH + msgAreaH)
			content = skin.GetContentRect(outer)
			contentY = content.y

			Local title:String = currentProductionConcept.GetTitle()
			Local subTitle:String
			If currentProductionConcept.script.IsEpisode()
				Local seriesScript:TScript = currentProductionConcept.script.GetParentScript()
				subTitle = (seriesScript.GetSubScriptPosition(currentProductionConcept.script)+1) + "/" + seriesScript.GetSubscriptCount() + ": " + title
				title = seriesScript.GetTitle()
			EndIf


			skin.RenderContent(content.x, contentY, content.w, titleH + subTitleH, "1_top")
			skin.fontCaption.DrawBox(title, content.x + 5, contentY - 1, content.w - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			contentY :+ titleH

			If currentProductionConcept.script.IsEpisode()
				skin.fontSmallCaption.DrawBox(subTitle, content.x + 5, contentY - 1, content.w - 10, subTitleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			EndIf
			contentY :+ subTitleH

			skin.RenderContent(content.x, contentY, content.w, castAreaH, "2")
			'reposition cast list
			If castSlotList.rect.x <> content.x + 5
				castSlotList.SetPosition(content.x +5, contentY + 3)
				'-5 => 210 height, each slot 42px, so 5 slots fit
				castSlotList.SetSize(content.w - 10, castAreaH - 5 )
				castSlotList.SetSlotMinDimension(content.w - 10, 42)
			EndIf

			contentY :+ castAreaH

			If msgAreaH > 0
				skin.RenderContent(content.x, contentY, content.w, msgAreaH, "1_bottom")
				If Not currentProductionConcept.IsCastComplete()
					skin.RenderMessage(content.x + 5 , contentY + 3, content.w - 10, -1, GetLocale("CAST_INCOMPLETE"), "audience", "warning")
					contentY :+ msgH + msgPaddingY
				EndIf
				If Not currentProductionConcept.IsFocusPointsComplete()
					If currentProductionConcept.productionCompany
						If Not currentProductionConcept.IsFocusPointsMinimumUsed()
							skin.RenderMessage(content.x + 5 , contentY + 3, content.w - 10, -1, GetLocale("NEED_TO_SPENT_AT_LEAST_ONE_POINT_OF_PRODUCTION_FOCUS_POINTS"), "spotsplanned", "warning")
						Else
							skin.RenderMessage(content.x + 5 , contentY + 3, content.w - 10, -1, GetLocale("PRODUCTION_FOCUS_POINTS_NOT_SET_COMPLETELY"), "spotsplanned", "neutral")
						EndIf
					Else
						skin.RenderMessage(content.x + 5 , contentY + 3, content.w - 10, -1, GetLocale("NO_PRODUCTION_COMPANY_SELECTED"), "spotsplanned", "warning")
					EndIf
					contentY :+ msgH + msgPaddingY
				EndIf
			EndIf

			skin.RenderBorder(outer.x, outer.y, outer.w, outer.h)




			'=== PRODUCTION BOX ===
			Local productionFocusSliderH:Int = 21
			Local productionFocusLabelH:Int = 15
			Local productionCompanyH:Int = 60
			Local productionFocusH:Int = titleH + subTitleH + 5 'bottom padding
			If currentProductionConcept.productionFocus
				productionFocusH :+ currentProductionConcept.productionFocus.GetFocusAspectCount() * (productionFocusSliderH + productionFocusLabelH)
			EndIf


			outer = new SRectI(580, 15, 210, outerSizeH + titleH + productionCompanyH + productionFocusH)
			content = skin.GetContentRect(outer)
			contentY = content.y

			skin.RenderContent(content.x, contentY, content.w, titleH, "1_top")
			skin.fontCaption.DrawBox(GetLocale("PRODUCTION_DETAILS"), content.x + 5, contentY - 1, content.w - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			contentY :+ titleH

			skin.RenderContent(content.x, contentY, content.w, productionCompanyH + productionFocusH, "1")

			skin.fontSemiBold.DrawBox(GetLocale("PRODUCTION_COMPANY"), content.x + 5, contentY + 3, content.w - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			'reposition dropdown
			If productionCompanySelect.rect.x <> content.x + 5
				productionCompanySelect.SetPosition(content.x + 5, contentY + 20)
				productionCompanySelect.SetSize(content.w - 10, -1)
			EndIf
			contentY :+ productionCompanyH

			skin.fontSemiBold.DrawBox(GetLocale("PRODUCTION_FOCUS"), content.x + 5, contentY + 3, content.w - 10, titleH - 3, sALIGN_LEFT_CENTER, skin.textColorNeutral)
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
					slider.SetPosition(content.x + 5, contentY + productionFocusLabelH + i * (productionFocusLabelH + productionFocusSliderH))
					slider.SetSize(content.w - 10)
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
					skin.fontNormal.DrawBox(label, content.x + 10, contentY, content.w - 15, titleH, sALIGN_LEFT_CENTER, skin.textColorLabel)
					contentY :+ (productionFocusLabelH + productionFocusSliderH)
				Next

				'inform about unused skill points / missing company selection
				If currentProductionConcept.productionCompany
					Local text:String = GetLocale("POINTSSET_OF_POINTSMAX_POINTS_SET").Replace("%POINTSSET%", pF.GetFocusPointsSet()).Replace("%POINTSMAX%", pF.GetFocusPointsMax())
					If pF.GetFocusPointsSet() < pF.GetFocusPointsMax()
						skin.fontNormal.DrawBox("|i|"+text+"|/i|", content.x + 5, contentY, content.w - 10, subTitleH, sALIGN_CENTER_CENTER, skin.textColorWarning)
					Else
						skin.fontNormal.DrawBox("|i|"+text+"|/i|", content.x + 5, contentY, content.w - 10, subTitleH, sALIGN_CENTER_CENTER, skin.textColorLabel)
					EndIf
				EndIf
				contentY :+ subTitleH
			EndIf
			skin.RenderBorder(outer.x, outer.y, outer.w, outer.h)

			GuiManager.Draw(evKey_supermarket_customproduction_productionconceptbox)
			GuiManager.Draw(evKey_supermarket_customproduction_newproduction)
			GuiManager.Draw(evKey_supermarket_customproduction_productionbox)
			GuiManager.Draw(evKey_supermarket_customproduction_castbox)
			'GuiManager.Draw(evKey_supermarket_customproduction_castbox, -1000,-1000, GUIMANAGER_TYPES_NONDRAGGED)

			GuiManager.Draw(evKey_supermarket_customproduction)
			'GuiManager.Draw(evKey_supermarket_customproduction_castbox, -1000,-1000, GUIMANAGER_TYPES_DRAGGED) )
			GuiManager.Draw(evKey_supermarket_customproduction_castbox_modal)
			GuiManager.Draw(evKey_supermarket_customproduction_productionbox_modal)

			'draw datasheet if needed
			If hoveredGuiCastItem 
				'check if the selection is more current (show this instead)
				if castSlotList and castSlotList.SelectCastWindowIsOpen()
					if castSlotList.selectCastWindow and castSlotList.selectCastWindow.castSelectList.selectionChangedTime > MouseManager.GetLastMovedTime()
						local selectedEntry:TGUICastListItem = TGUICastListItem(castSlotList.selectCastWindow.castSelectList.GetSelectedEntry())
						if selectedEntry then hoveredGUICastItem = selectedEntry
					endif
				endif
				
				If MouseManager.x < GetGraphicsManager().GetWidth()/2
					hoveredGuiCastItem.DrawDatasheet(GetGraphicsManager().GetWidth() - 20, 20, 1.0)
				Else
					hoveredGuiCastItem.DrawDatasheet(20, 20, 0.0)
				EndIf
			EndIf

		Else
			GuiManager.Draw( evKey_supermarket_customproduction_productionconceptbox )
		EndIf

		'draw script-sheet
		If hoveredGuiProductionConcept Then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method
End Type



Type TGUIProductionModalWindow Extends TGUIModalWindow
	Field buttonOK:TGUIButton
	Field buttonCancel:TGUIButton
	Field _eventListeners:TEventListenerBase[]


	Method Create:TGUIProductionModalWindow(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		darkenedAreaAlpha = 0.25 '0.5 is default


		buttonOK = New TGUIButton.Create(New SVec2I(10, dimension.y - 44), New SVec2I(136, 28), "OK", "")
		buttonOK.SetSpriteName("gfx_gui_button.datasheet")
		buttonCancel = New TGUIButton.Create(New SVec2I(dimension.x - 15 - 136, dimension.y - 44), New SVec2I(136, 28), "Cancel", "")
		buttonCancel.SetSpriteName("gfx_gui_button.datasheet")

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
		If buttonOK Then buttonOK.rect.SetY( rect.h - 44)
		If buttonCancel Then buttonCancel.rect.SetY( rect.h - 44)
	End Method


	'override to _not_ recenter
	Method Recenter:Int(moveByX:Float = 0, moveByY:Float = 0)
		Return True
	End Method


	Method Update:Int()
		If buttonCancel.IsClicked() Then Close(2)
		If buttonOK.IsClicked() Then Close(1)

		If MouseManager.IsClicked(2)
			Close(2)

			'remove right click - to avoid leaving the room
			MouseManager.SetClickHandled(2)
		EndIf

		Return Super.Update()
	End Method
End Type






Type TGUISelectCastWindow Extends TGUIProductionModalWindow
	Field jobFilterSelect:TGUIDropDown
	Field genderFilterSelect:TGUIDropDown
	Field sortCastButton:TGUIButton
	'only list persons with the following job?
	Field listOnlyJobID:Int = -1
	Field listOnlyGenderID:Int = -1
	'select a person for the following job (for correct fee display)
	Field selectJobID:Int = 0
	Field selectGenderID:Int = 0
	Field castSelectList:TGUICastSelectList
	Field sortCastTooltip:TTooltipBase
	Field sortType:Int = 0


	'override
	Method Create:TGUISelectCastWindow(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		jobFilterSelect = New TGUIDropDown.Create(New SVec2I(15,12), New SVec2I(130,-1), "Hauptberuf", 128, "")
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


		genderFilterSelect = New TGUIDropDown.Create(New SVec2I(152,12), New SVec2I(90,-1), "Alle", 128, "")
		genderFilterSelect.SetZIndex( GetZIndex() + 10)
		genderFilterSelect.list.SetZIndex( GetZIndex() + 11)
		genderFilterSelect.SetListContentHeight(60)

		'add some items to that list
		For Local i:Int = 0 To TVTPersonGender.count
			Local item:TGUIDropDownItem = New TGUIDropDownItem.Create(New SVec2I(0,0), New SVec2I(0,0), "")

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

		sortCastButton = New TGUIButton.Create(New SVec2I(250,12), New SVec2I(30, 28), "", "")
		sortCastButton.enable()
		sortCastButton.caption.SetSpriteName("gfx_datasheet_icon_az")
		sortCastButton.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_ONLY )
		sortCastButton.SetSpriteName("gfx_gui_button.datasheet")

		castSelectList = New TGUICastSelectList.Create(New SVec2I(15,50), New SVec2I(270, dimension.y - 103), "")


		sortCastTooltip = New TGUITooltipBase.Initialize("", "", New TRectangle.Init(0,0,-1,-1))
		sortCastTooltip.parentArea = New TRectangle
		sortCastTooltip.SetOrientationPreset("TOP")
		sortCastTooltip.offset = New TVec2D(0,+5)
		sortCastTooltip.SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
		'standard icons should need a bit longer for tooltips to show up
		sortCastTooltip.dwellTime = 50
		sortCastTooltip.SetContent( StringHelper.UCFirst(GetLocale("NAME")) )
		'manually set to hovered when needed
		sortCastTooltip.SetOption(TTooltipBase.OPTION_MANUAL_HOVER_CHECK)


		AddChild(jobFilterSelect)
		AddChild(genderFilterSelect)
		AddChild(sortCastButton)
		AddChild(castSelectList)

		buttonOK.SetValue(GetLocale("SELECT_PERSON"))
		buttonCancel.SetValue(GetLocale("CANCEL"))
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIDropDown_OnSelectEntry, Self, "onCastChangeFilterDropdown", "TGUIDropDown") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnDoubleClick, Self, "onDoubleClickCastListItem", "TGUICastListItem") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "onClickSortCastButton", "TGUIButton") ]

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

	Method onClickSortCastButton:Int(triggerEvent:TEventBase )
		If triggerEvent.GetSender() <> sortCastButton Then Return False

		sortType = sortType + 1
		If sortType > 3 Then sortType = 0
		SortCastList(sortType)
		TScreenHandler_SupermarketProduction.castSortType = sortType
		Return True
	End Method

	Method SortCastList(sortBy:Int = -1)
		If sortBy < 0 Then sortBy = sortType
		If sortBy = 0
			castSelectList.entries.sort(True, TGUICastSelectList.SortCastByName)
			sortCastButton.caption.SetSpriteName("gfx_datasheet_icon_az")
			sortCastTooltip.SetContent( StringHelper.UCFirst(GetLocale("NAME")) )
		Else If sortBy = 1
			castSelectList.entries.sort(True, TGUICastSelectList.SortCastByJobXP)
			sortCastButton.caption.SetSpriteName("gfx_datasheet_icon_quality")
			sortCastTooltip.SetContent( StringHelper.UCFirst(GetLocale("CAST_JOB_EXPERIENCE")) )
		Else If sortBy = 2
			castSelectList.entries.sort(True, TGUICastSelectList.SortCastByGenreXP)
			sortCastButton.caption.SetSpriteName("gfx_datasheet_icon_genreXP")
			sortCastTooltip.SetContent( StringHelper.UCFirst(GetLocale("CAST_GENRE_EXPERIENCE")) )
		Else If sortBy = 3
			castSelectList.entries.sort(True, TGUICastSelectList.SortCastByFee)
			sortCastButton.caption.SetSpriteName("gfx_datasheet_icon_money")
			sortCastTooltip.SetContent( StringHelper.UCFirst(GetLocale("CAST_FEE")) )
		End If
		castSelectList.Update()
		castSelectList.UpdateLayout()
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
		'sort again
		SortCastList()
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
		'also prepend 5 amateurs (at least 1 of them "not yet interested"
		'in the job) - for "all jobs" do not show amateurs
		Local amateurCount:Int = 5
		If filterToJobID = 0 Then amateurCount = 0
		Local minAge:Int = getMinAge()
		Local persons:TPersonBase[] = GetProductionManager().GetCastCandidates(filterToJobID, filterToGenderID, minAge, amateurCount, 1, True)

		Rem
			'Variant for "all jobs": no filter for celebrities but keep use job filter for amateurs
			Local persons:TPersonBase[] = GetProductionManager().GetCastCandidates(filterToJobID, filterToGenderID, 10, 0, 1, True)
			Local amateurJobID:Int = filterToJobID
			If filterToJobID = 0 then amateurJobID = selectJobID
			Local amateurs:TPersonBase[] = GetProductionManager().GetCurrentAvailableAmateurs(amateurJobID, filterToGenderID, 10, 5, 0)
			persons = amateurs + persons
		EndRem

		'disable list-sort
		castSelectList.SetAutosortItems(False)

		For Local p:TPersonBase = EachIn persons
			'base items do not have a size - so we have to give a manual one
			Local item:TGUICastListItem = New TGUICastListItem.CreateSimple( p, selectJobID )
			If not p.IsCelebrity()
				If selectJobID > 0
					item.displayName = p.GetFullName() + " ("+GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString(selectJobID)) + ")"
				Else
					item.displayName = p.GetFullName() + " ("+GetLocale("JOB_AMATEUR") + ")"
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
		'initial sorting
		castSelectList.entries.sort(True, TGUICastSelectList.SortCastByName)

		'TODO this filter does not prevent moving an underage actor to a director slot
		Function getMinAge:Int()
			Local handler:TScreenHandler_SupermarketProduction = TScreenHandler_SupermarketProduction.GetInstance()
			Local script:TScriptBase = handler.currentProductionConcept.script
			Local jobSlotList:TGUICastSlotList = handler.castSlotList
			Local jobId:Int = jobSlotList.selectCastWindow.selectJobID

			Local adultAge:Int = 20
			If script
				If jobId = TVTPersonJob.DIRECTOR Then Return adultAge
				If script.IsXRated()
					If jobId = TVTPersonJob.HOST Then Return adultAge
					If jobId = TVTPersonJob.REPORTER Then Return adultAge
				EndIf
				Local genres:Int[] = [script.mainGenre]
				If script.subGenres Then genres:+ script.subGenres
				For Local i:Int = 0 Until genres.length
					Local genre:Int = genres[i]
					If genre = TVTProgrammeGenre.Erotic Then Return adultAge
					'If genre = TVTProgrammeGenre.Horror Then Return adultAge
					'If genre = TVTProgrammeGenre.Thriller Then Return adultAge
				Next
				return 10
			Else
				Return adultAge
			EndIf
		EndFunction
	End Method


	Method Update:Int() override
		Super.Update()
		
		'for now this always focuses the select list - so keyboard
		'scrolling will work.
		'exception is if one of the dropdowns is open (they might as
		'well want keyboard scrolling...)
		if jobFilterSelect.IsOpen() or genderFilterSelect.IsOpen()
			'by default the dropdowns should decide if they want keyboard
			'control or not
			
			'use this to enforce focus loss
			'If GUIManager.GetFocus() = castSelectList then GUIManager.SetFocus( null )
		Else
			GUIManager.SetFocus( castSelectList )
		EndIf


		if not IsClosed() 'or better isopen()?
			if sortCastButton.IsVisible()
				if sortCastButton.IsHovered()
					sortCastTooltip.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED)
					'skip dwelling
					sortCastTooltip.SetStep(TTooltipBase.STEP_ACTIVE)
					sortCastTooltip.Update()
				else
					sortCastTooltip.SetOption(TTooltipBase.OPTION_MANUALLY_HOVERED, False)
					sortCastTooltip.Update()
				endif
			endif
		endif
	End Method


	Method DrawTooltips:Int() override
		Super.DrawTooltips()

		if not IsClosed()
			sortCastTooltip.parentArea.SetXY(GetContentScreenRect().GetX() + 250, GetContentScreenRect().GetY() + 12).SetWH(30, 28)

			sortCastTooltip.Render()
		endif
	End Method


	Method DrawBackground()
		Super.DrawBackground()

		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		Local outer:SRectI = GetScreenRect().ToSRectI()
		Local content:SRectI = skin.GetContentRect(outer)

		skin.RenderContent(content.x, content.y, content.w, 38, "1_top")
		skin.RenderContent(content.x, content.y + 38, content.w, content.h - 73, "1")
		skin.RenderContent(content.x, content.y + content.h - 35, content.w, 35, "1_bottom")
		skin.RenderBorder(outer.x, outer.y, outer.w, outer.h)
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
	Method Create:TGUIProductionEditTextsModalWindow(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		labelTitle = New TGUILabel.Create(New SVec2I(15,9), GetLocale("TITLE"), "")
		labelDescription = New TGUILabel.Create(New SVec2I(15,57), GetLocale("DESCRIPTION"), "")
		labelEpisode = New TGUILabel.Create(New SVec2I(15,112), GetLocale("EPISODE"), "")
		labelEpisode.SetFont( GetBitmapFontManager().Get("default", 13, BOLDFONT) )
		labelSubTitle = New TGUILabel.Create(New SVec2I(15,134), GetLocale("TITLE"), "")
		labelSubDescription = New TGUILabel.Create(New SVec2I(15,177), GetLocale("DESCRIPTION"), "")

		inputTitle = New TGUIInput.Create(New SVec2I(15,12+13), New SVec2I(245,-1), GetLocale("TITLE"), 128, "")
		inputDescription = New TGUIInput.Create(New SVec2I(15,60+13), New SVec2I(245,-1), GetLocale("DESCRIPTION"), 512, "")
		inputSubTitle = New TGUIInput.Create(New SVec2I(15,137+13), New SVec2I(245,-1), GetLocale("TITLE"), 128, "")
		inputSubDescription = New TGUIInput.Create(New SVec2I(15,180+13), New SVec2I(245,-1), GetLocale("DESCRIPTION"), 512, "")

		clearTitle = New TGUIButton.Create(New SVec2I(15+245, 12 + 13 + 2), New SVec2I(25, 25), "x", "")
		clearTitle.SetSpriteName("gfx_gui_button.datasheet")
		clearDescription = New TGUIButton.Create(New SVec2I(15+245, 60 + 13 + 2), New SVec2I(25, 25), "x", "")
		clearDescription.SetSpriteName("gfx_gui_button.datasheet")
		clearSubTitle = New TGUIButton.Create(New SVec2I(15+245, 137 + 13 + 2), New SVec2I(25, 25), "x", "")
		clearSubTitle.SetSpriteName("gfx_gui_button.datasheet")
		clearSubDescription = New TGUIButton.Create(New SVec2I(15+245, 180 + 13 + 2), New SVec2I(25, 26), "x", "")
		clearSubDescription.SetSpriteName("gfx_gui_button.datasheet")



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

		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnChange, Self, "onChangeInputValues", "TGUIInput") ]
		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIObject_OnClick, Self, "onClickClearInputButton", "TGUIButton") ]

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
				inputTitle.SetValue(concept.GetTitle())
				inputDescription.SetValue(concept.GetDescription())
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

		labelTitle.SetValueColor(SColor8.Black)
		'GetFont().DrawBox(GetLocale("TITLE"), contentX + 5, contentY + 5, 100, 20, sALIGN_LEFT_TOP, SColor8.Black)
'		GetFont().DrawBox("Titel", 265.000000 + 0.00000000, 72.0000000 + 0.00000000, 100, 30, sALIGN_LEFT_TOP, SColor8.Black)
	End Method


	Method onClickClearInputButton:Int( triggerEvent:TEventBase )
		Local button:TGUIButton = TGUIButton( triggerEvent.GetSender() )
		If concept And concept.script
			Local isEpisode:int = concept.script.HasParentScript()
			Select button
				Case clearTitle
					If inputTitle.GetValue() = ""
						If isEpisode
							inputTitle.SetValue(concept.script.getParentScript().GetTitle())
						Else
							inputTitle.SetValue(concept.script.GetTitle())
						EndIf
					Else
						inputTitle.SetValue("")
					EndIf
					GuiManager.setFocus(inputTitle)
				Case clearSubTitle
					If inputSubTitle.GetValue() = "" And isEpisode
						inputSubTitle.SetValue(concept.script.GetTitle())
					Else
						inputSubTitle.SetValue("")
					EndIf
					GuiManager.setFocus(inputSubTitle)
				Case clearDescription
					If inputDescription.GetValue() = ""
						If isEpisode
							inputDescription.SetValue(concept.script.getParentScript().GetDescription())
						Else
							inputDescription.SetValue(concept.script.GetDescription())
						EndIf
					Else
						inputDescription.SetValue("")
					EndIf
					GuiManager.setFocus(inputDescription)
				Case clearSubDescription
					If inputSubDescription.GetValue() = "" And isEpisode
						inputSubDescription.SetValue(concept.script.GetDescription())
					Else
						inputSubDescription.SetValue("")
					EndIf
					GuiManager.setFocus(inputSubDescription)
			EndSelect
		EndIf
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


    Method Create:TGUICastSelectList(position:SVec2I, dimension:SVec2I, limitState:String = "")
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

	Function SortCastByName:Int(o1:Object, o2:Object)
		Local a1:TGUICastListItem = TGUICastListItem(o1)
		Local a2:TGUICastListItem = TGUICastListItem(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		If a1.person.GetLastName().ToLower() = a2.person.GetLastName().ToLower()
			Return a1.person.GetFirstName().ToLower() > a2.person.GetFirstName().ToLower()
		ElseIf a1.person.GetLastName().ToLower() > a2.person.GetLastName().ToLower()
			Return 1
		EndIf
		Return -1
	End Function


	Function SortCastByJobXP:Int(o1:Object, o2:Object)
		Local a1:TGUICastListItem = TGUICastListItem(o1)
		Local a2:TGUICastListItem = TGUICastListItem(o2)
		'sort amateurs "at bottom"
		If Not a1 or a1.isAmateur and (not a2 or not a2.isAmateur) Then Return 1
		If Not a2 or a2.isAmateur and (not a1 or not a1.isAmateur) Then Return -1
		
		Local xp1:float
		Local xp2:float
		'for amateurs we order by production job count (when to "upgrade")
		If a1 And a1.isAmateur And a2 And a2.isAmateur
			xp1 = a1.person.GetProductionJobsDone(a1.selectJobID)
			xp2 = a2.person.GetProductionJobsDone(a2.selectJobID)
		Else
			xp1 = a1.person.GetEffectiveJobExperiencePercentage(a1.selectJobID)
			xp2 = a2.person.GetEffectiveJobExperiencePercentage(a2.selectJobID)
		EndIf

		If xp1 = xp2 Then Return SortCastByName(o1, o2)
		Return xp1 < xp2
	End Function

	Function SortCastByGenreXP:Int(o1:Object, o2:Object)
		Local a1:TGUICastListItem = TGUICastListItem(o1)
		Local a2:TGUICastListItem = TGUICastListItem(o2)
		'sort amateurs "at bottom"
		If Not a1 or a1.isAmateur and (not a2 or not a2.isAmateur) Then Return 1
		If Not a2 or a2.isAmateur and (not a1 or not a1.isAmateur) Then Return -1

		Local genre:Int = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.mainGenre

		Local xp1:float
		Local xp2:float
		'for amateurs we order by production job count (when to "upgrade")
		If a1 And a1.isAmateur And a2 And a2.isAmateur
			xp1 = a1.person.GetProductionJobsDone(a1.selectJobID)
			xp2 = a2.person.GetProductionJobsDone(a2.selectJobID)
		Else
			Local pd1:TPersonProductionData = TPersonProductionData(a1.person.getProductionData())
			Local pd2:TPersonProductionData = TPersonProductionData(a2.person.getProductionData())
			If pd1 Then xp1 = pd1.GetEffectiveGenreExperiencePercentage(genre)
			If pd2 Then xp2 = pd2.GetEffectiveGenreExperiencePercentage(genre)
		EndIf

		If xp1 = xp2 Then Return SortCastByName(o1, o2)
		Return xp1 < xp2
	End Function

	Function SortCastByFee:Int(o1:Object, o2:Object)
		Local a1:TGUICastListItem = TGUICastListItem(o1)
		Local a2:TGUICastListItem = TGUICastListItem(o2)
		If Not a1 Then Return -1
		If Not a2 Then Return 1

		local playerID:Int = 0
		local blocks:Int = 1
		If TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
			playerID = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.owner
			If TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script
				blocks = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.blocks
			EndIf
		EndIf
	
		Local fee1:Int = a1.person.GetJobBaseFee(a1.selectJobID, blocks, playerID)
		Local fee2:Int = a2.person.GetJobBaseFee(a2.selectJobID, blocks, playerID)

		If fee1 = fee2 Then Return SortCastByName(o1, o2)
		'cheap on top, expensive at bottom
		Return fee1 > fee2
	End Function
End Type




Type TGUICastSlotList Extends TGUISlotList
	'contains job for each slot
	Field slotJob:TPersonProductionJob[]
	Field _eventListeners:TEventListenerBase[]
	Field selectCastWindow:TGUISelectCastWindow
	'the currently clicked/selected slot for a cast selection
	Field selectCastSlot:Int = -1


    Method Create:TGUICastSlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)

		_eventListeners :+ [ EventManager.registerListenerMethod(GUIEventKeys.GUIModalWindow_OnClose, Self, "onCloseSelectCastWindow", "TGUISelectCastWindow") ]

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

		Local i:TGUICastListItem = TGUICastListItem(GetItemBySlot(slotIndex))

		If person
			If not i
				i = New TGUICastListItem.CreateSimple(person, GetSlotJobID(slotIndex) )
			Else
				'reuse existing item
				i.Init(person, GetSlotJobID(slotIndex))
			EndIf

			'print "SetSlotCast: AddItem " + slotIndex +"  "+person.GetFullName()
			'hide the name of amateurs
			If Not person.IsCelebrity() Then i.isAmateur = True
			i.SetOption(GUI_OBJECT_DRAGABLE, True)
		'empty the slot
		Else
			If i 
				i.remove()
				i = Null
			EndIf
		EndIf

		AddItem( i, String(slotIndex) )
	End Method


	Method OpenSelectCastWindow(job:Int, gender:Int=-1)
		If selectCastWindow Then selectCastWindow.Remove()

		selectCastWindow = New TGUISelectCastWindow.Create(New SVec2I(250,60), New SVec2I(300,270), _limitToState+"_modal")
		selectCastWindow.SetZIndex(100000)
		selectCastWindow.selectJobID = job
		selectCastWindow.listOnlyJobID = job
		selectCastWindow.listOnlyGenderID = gender
		selectCastWindow.screenArea = New TRectangle.Init(0,0, 800, 383)
		selectCastWindow.sortType = TScreenHandler_SupermarketProduction.castSortType
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
	Method onClick:Int(triggerEvent:TEventBase) override
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
		
		Return True
	End Method


	'called when trying to "ctrl + v"
	Method PasteFromClipboard:Int () override
		local coord:TVec2D = new TVec2D(MouseManager.x, MouseManager.y)
		Local slot:Int = GetSlotByCoord(coord, True)
		
		Local appData:String[] = String( GetAppClipboard() ).Split(":")
		if appData.length < 2 or appData[0] <> "person" then Return False

		Local personID:Int = int(appData[1])
		local person:TPersonBase = GetPersonBase(personID)

		'quick fix: prevent pasting minors
		'TODO implement proper "slot allowed for person" functionality, see also getMinAge function in LoadPersons
		If person.GetAge() < 20
			Local handler:TScreenHandler_SupermarketProduction = TScreenHandler_SupermarketProduction.GetInstance()
			Local script:TScriptBase = handler.currentProductionConcept.script
			If script
				Local genres:Int[] = [script.mainGenre]
				If script.subGenres Then genres:+ script.subGenres
				For Local i:Int = 0 Until genres.length
					Local genre:Int = genres[i]
					If genre = TVTProgrammeGenre.Erotic Then Return False
				Next
			EndIf
		EndIf

		SetSlotCast(slot, person)
		
		Return True
	End Method

rem
	'called when trying to "ctrl + v"
	Method CopyToClipboard:Int() override
		local coord:TVec2D = new TVec2D(MouseManager.x, MouseManager.y)
		Local slot:Int = GetSlotByCoord(coord, True)
		Local item:TGUICastListItem = TGUICastListItem(GetItemBySlot(slot))

		if item and item.person
			SetAppClipboard("person:"+item.person.GetID(), "TGUICastListItem")
		EndIf
		
		Return True
	End Method
endrem	
	

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

			Local atPoint:SVec2F = GetScreenRect().GetPosition()

			For Local slot:Int = 0 Until _slots.length
			'	local pos:TVec3D = GetSlotOrCoord(slot)
				If _slots[slot] Then Continue
				If slotJob.length < slot Then Continue

				Local coord:SVec3F = GetSlotCoord(slot)

				Local job:TPersonProductionJob = GetSlotJob(slot)

				Local genderHint:String
				Local gender:Int = 0
				If job 
					gender = job.gender

					If job.gender = TVTPersonGender.MALE
						genderHint = " ("+GetLocale("MALE")+")"
					ElseIf job.gender = TVTPersonGender.FEMALE
						genderHint = " ("+GetLocale("FEMALE")+")"
					EndIf
					If job.roleID
						Local role:TProgrammeRole = GetProgrammeRoleCollection().GetById(job.roleID)
						If role Then genderHint = " - "+role.GetFullName()
					EndIf
				EndIf

	'TODO: nur zeichnen, wenn innerhalb "panel rect"
				If MouseManager._ignoreFirstClick 'touch mode
'					TGUICastListItem.DrawCast(atPoint.GetX() + pos.getX(), atPoint.GetY() + pos.getY(), _slotMinDimension.getX(), GetLocale("JOB_" + TVTPersonJob.GetAsString(GetSlotJobID(slot))) + genderHint, GetLocale("TOUCH_TO_SELECT_PERSON"), null, 0,0,0)
					TGUICastListItem.DrawCast(GetScreenRect().x + coord.x, GetScreenRect().y + coord.y, guiEntriesPanel.GetContentScreenRect().w-2, GetLocale("JOB_" + TVTPersonJob.GetAsString(GetSlotJobID(slot))) + genderHint, GetLocale("TOUCH_TO_SELECT_PERSON"), Null, 0,0,0, gender, 0.35)
				Else
					TGUICastListItem.DrawCast(GetScreenRect().x + coord.x, GetScreenRect().y + coord.y, guiEntriesPanel.GetContentScreenRect().w-2, GetLocale("JOB_" + TVTPersonJob.GetAsString(GetSlotJobID(slot))) + genderHint, GetLocale("CLICK_TO_SELECT_PERSON"), Null, 0,0,0, gender, 0.35)
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
	Method OnBeginReceiveDrop:Int( triggerEvent:TEventBase ) override
		'adjust cast slots...
		If Super.OnBeginReceiveDrop( triggerEvent )
			Local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
			If Not item Then Return False

			Local list:TGUICastSlotList = TGUICastSlotList(triggerEvent.GetReceiver())
			If Not list Then Return False

			Local slotNumber:Int = list.getSlot(item)

			list.SetSlotCast(slotNumber, item.person)
		EndIf

		Return True
	End Method
End Type




Type TGUICastListItem Extends TGUISelectListItem
	Field person:TPersonBase
	Field displayName:String = ""
	Field isAmateur:Int = False
	'the job this list item is "used for" (the dropdown-filter)
	Field displayJobID:Int = -1
	Field lastDisplayJobID:Int = -1
	Field selectJobID:Int = -1

	Global yearColor:SColor8 = New SColor8(60,60,60, int(0.8*255))

	Const paddingBottom:Int	= 5
	Const paddingTop:Int = 0


	Method CreateSimple:TGUICastListItem(person:TPersonBase, displayJobID:Int)
		If not person Then Throw "TGUICastListItem.CreateSimple() - no person passed"

		'make it "unique" enough
		Self.Create(Null, Null, "")
		
		Self.Init(person, displayJobID)

		'resize it
		GetDimension()

		Return Self
	End Method
	
	
	Method Init(person:TPersonBase, displayJobID:Int)
		Self.SetValue(person.GetFullName())
		Self.displayName = person.GetFullName()
		Self.person = person
		Self.isAmateur = False

		Self.displayJobID = -1
		Self.selectJobID = displayJobID
		Self.lastDisplayJobID = displayJobID
	End Method


    Method Create:TGUICastListItem(pos:SVec2I, dimension:SVec2I, value:String="")
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

	
	'called when trying to "ctrl + c"
	Method CopyToClipboard:Int() override
		'write via 
		'SetOSClipboard("hello world")

		'not sending self as source (avoid references) but at least
		'inform "what type" was used
		SetAppClipboard("person:"+person.GetID(), "TGUICastListItem")
		
		Return True
	End Method


	'called when trying to "ctrl + v"
	Method PasteFromClipboard:Int() override
		Local appData:String[] = String( GetAppClipboard() ).Split(":")
		if appData.length < 2 or appData[0] <> "person" then Return False

		'while dragged we ignore paste tries
		If (Self._flags & GUI_OBJECT_DRAGGED) Then Return False
		'only check items from the slot lists, not the select ones
		If not TGUICastSlotList( TGUIListBase.FindGUIListBaseParent(Self._parent) ) Then Return False
		
		Local slot:Int = TScreenHandler_SupermarketProduction.GetInstance().castSlotList.GetSlot( self )
		Local personID:Int = int(appData[1])
		local person:TPersonBase = GetPersonBase(personID)

		TScreenHandler_SupermarketProduction.GetInstance().castSlotList.SetSlotCast(slot, person)
		
		Return True
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


	Method GetDimension:SVec2F() override
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))
		Local maxWidth:Int = 295
		If parentPanel Then maxWidth = parentPanel.GetContentScreenRect().GetW() '- GetScreenRect().GetW()

		Local w:Float = maxWidth
		Local h:Float = GetSpriteFromRegistry("gfx_datasheet_cast_icon").GetHeight()

		'add padding
		h :+ Self.paddingTop
		h :+ Self.paddingBottom

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.w <> w Or Self.rect.h <> h
			'resize item
			Self.SetSize(w, h)
		EndIf

		Return new SVec2F(w, h)
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
		Local gender:Int = person.gender
		Local overlayIntensity:Float = 0.35	
		Local name:String = displayName
		local nameHint:String 
		
		'update isAmateur state?
		if isAmateur and person.IsCelebrity() then isAmateur = False

		If isAmateur And Not isDragged()
			If GetDisplayJobID() > 0 and TVTPersonJob.IsCastJob( GetDisplayJobID() )
				nameHint = "(" + GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString( GetDisplayJobID() ))  + ")"
'				name = person.GetFullName() + " ("+GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString( GetDisplayJobID() )) + ")"
			Else
				nameHint = "(" + GetLocale("JOB_AMATEUR") + ")"
'				name = person.GetFullName() + " ("+GetLocale("JOB_AMATEUR") + ")"
			EndIf
			name = person.GetFullName()

			displayName = name
		EndIf

		'drawing as ghost (so part of the list?)
		If HasOption(GUI_OBJECT_DRAWMODE_GHOST) or not IsDragged()
			Local genderHint:String
			Local jobID:Int = GetDisplayJobID()
			Local parentList:TGUIListBase = TGUIListBase.FindGUIListBaseParent(Self._parent)
			If parentList = TScreenHandler_SupermarketProduction.GetInstance().castSlotList
				local list:TGUICastSlotList = TScreenHandler_SupermarketProduction.GetInstance().castSlotList
				Local slot:Int = list.GetSlot(self)
				Local job:TPersonProductionJob = list.GetSlotJob(slot) 
				if job
					jobID = job.job
					If job.gender = TVTPersonGender.MALE
						genderHint = " ("+GetLocale("MALE")+")"
					ElseIf job.gender = TVTPersonGender.FEMALE
						genderHint = " ("+GetLocale("FEMALE")+")"
					EndIf

					'set color to "warning" when placed to a slot of 
					'different "gender"
					If not IsDragged()
						if job.gender <> 0 and job.gender <> person.gender
							gender = -1
						EndIf
					'set color to "original job" indicator
					ElseIf HasOption(GUI_OBJECT_DRAWMODE_GHOST)
						gender = job.gender
					EndIf
				EndIf
				
				'do not add too much color when already "selected" (in slot list)
				'except it _requires_ a gender
				If Not job Or job.gender = 0
					overlayIntensity = 0.15
				ElseIf job and job.gender <> 0
					overlayIntensity = 0.5
				endif
			EndIf
			
			If HasOption(GUI_OBJECT_DRAWMODE_GHOST)
				name = GetLocale("JOB_" + TVTPersonJob.GetAsString(jobID))   + genderHint
			EndIf
		EndIf

		Local face:TImage = TImage(person.GetPersonalityData().GetFigureImage())
		If HasOption(GUI_OBJECT_DRAWMODE_GHOST) 
			face = Null
			xpPercentage = 0
			sympathyPercentage = 0
		EndIf
	
	
		DrawCast(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), name, nameHint, face, xpPercentage, sympathyPercentage, 1, gender, overlayIntensity)

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawCast(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), name, nameHint, face, xpPercentage, 0, 1, gender, overlayIntensity)

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


	Method DrawDatasheet(x:Int=30, y:Int=20, alignment:Float=0.5)
		Local sheetWidth:Int = 250
		local baseX:Int = int(x - alignment * sheetWidth)

		local oldA:Float = GetAlpha()
		local oldCol:SColor8
		GetColor(oldCol)
		SetColor 0,0,0
		SetAlpha 0.2 * oldA
		TFunctions.DrawBaseTargetRect(baseX + sheetWidth/2, ..
		                              y + 70, ..
		                              Self.GetScreenRect().GetX() + Self.GetScreenRect().GetW()/2.0, ..
		                              Self.GetScreenRect().GetY() + Self.GetScreenRect().GetH()/2.0, ..
		                              20, 3)
		SetColor(oldCol)
		SetAlpha oldA


		Local jobID:Int = selectJobID
		If jobID = -1 Then jobID = GetDisplayJobID()

		If person.IsCelebrity()
			ShowCastSheet(person, jobID, x, y, alignment, False)
		Else
			'hide person name etc for non-celebs
			ShowCastSheet(person, jobID, x, y, alignment, True)
		EndIf
	End Method


	Function DrawCast(x:Float, y:Float, w:Float, name:String, nameHint:String="", face:Object=Null, xp:Float, sympathy:Float, mood:Int, gender:Int, overlayIntensity:Float = 0.3)
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

		Local nameOffsetX:Int = 35, nameOffsetY:Int = 3
		Local nameTextOffsetX:Int = 38
		Local barOffsetX:Int = 35, barOffsetY:Int = nameOffsetY + nameSprite.GetHeight()
		Local barH:Int = skin.GetBarSize(100,-1, "cast_bar_xp").y

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
		if gender <> 0
			Local iconSpriteOverlay:TSprite = GetSpriteFromRegistry("gfx_datasheet_cast_icon_overlay")
			if iconSpriteOverlay
				local oldA:Float = GetAlpha()
				local oldCol:SColor8
				GetColor(oldCol)

				'SetBlend LightBlend
				SetAlpha oldA * overlayIntensity

				If gender = TVTPersonGender.MALE
					SetColor 120, 120, 255
				ElseIf gender = TVTPersonGender.FEMALE
					SetColor 255, 120, 120
				ElseIf gender = -1 'warning
					SetAlpha oldA * Float(0.6 + 0.2 * Sin(Time.GetAppTimeGone() / 5))
					SetColor 255, 180, 50
				EndIf
			
				iconSpriteOverlay.Draw(x, y)
				
				'SetBlend AlphaBlend
				SetAlpha oldA
				SetColor(oldCol)
			EndIf
		EndIf

				

		'maybe "TPersonBase.GetFace()" ?
		If TSprite(face)
			TSprite(face).Draw(x+5, y+3)
		ElseIf TImage(face)
			DrawImageArea(TImage(face), x+1, y+3, 2, 4, 34, 33)
			'DrawImage(TProgrammePerson(person).GetFigureImage(), GetScreenRect().GetX(), GetScreenRect().GetY())
		EndIf


		If name Or nameHint
			Local border:SRect = nameSprite.GetNinePatchInformation().contentBorder
'			Local oldAlpha:Float = GetAlpha()

'			SetAlpha( Max(0.6, oldAlpha) )
			If name
				skin.fontSmallCaption.DrawBox( ..
					name, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop() - 1, .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(17, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					sALIGN_LEFT_CENTER, new SColor8(60,60,60), EDrawTextEffect.Emboss, 0.25)
			EndIf

'			SetAlpha( Max(0.6, oldAlpha) )
			If nameHint
				skin.fontNormal.DrawBox( ..
					nameHint, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop() + barOffsetY - 3 - 1, .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(17, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					sALIGN_RIGHT_CENTER, new SColor8(60,60,60))
			EndIf

'			SetAlpha( oldAlpha )
		EndIf
	End Function


	Function ShowCastSheet:Int(person:TPersonBase, jobID:Int=-1, x:Int, y:Int, alignment:Float=0.5, showAmateurInformation:Int = False)
		'=== PREPARE VARIABLES ===
		Local sheetWidth:Int = 250
		Local sheetHeight:Int = 0 'calculated later
		x = x - alignment * sheetWidth

		Local skin:TDatasheetSkin = GetDatasheetSkin("cast")
		Local contentW:Int = skin.GetContentW(sheetWidth)
		Local contentX:Int = Int(x) + skin.GetContentX()
		Local contentY:Int = Int(y) + skin.GetContentY()

		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		Local titleH:Int = 18, jobDescriptionH:Int = 16, lifeDataH:Int = 16, lastProductionEntryH:Int = 16, lastProductionTitleH:Int = 17, lastProductionsH:Int = 50
		Local splitterHorizontalH:Int = 6
		Local boxH:Int = 0, barH:Int = 0
		Local boxAreaH:Int = 0, barAreaH:Int = 0, msgAreaH:Int = 0
		Local boxAreaPaddingY:Int = 4, barAreaPaddingY:Int = 4

		If showAmateurInformation
'			jobDescriptionH = 0
			lifeDataH = 0
'			lastProductionsH = 0
		EndIf

		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").y
		barH = skin.GetBarSize(100, -1).y
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).GetBoxHeight(person.GetFullName(), contentW - 10, 100))

		'bar area starts with padding, ends with padding and contains
		'also contains 8 bars
		If person.IsCelebrity() And Not showAmateurInformation
			barAreaH = 2 * barAreaPaddingY + 7 * (barH + 2)
		else
			'"profession"
			barAreaH = 1 * barAreaPaddingY + 1 * (barH + 2)
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
			'If showAmateurInformation
				'title = GetLocale("JOB_AMATEUR")
				'title = person.GetFullName() + " ("+GetLocale("JOB_AMATEUR_" + TVTPersonJob.GetAsString(jobID)) + ")"
			'EndIf

			If titleH <= 18
				GetBitmapFont("default", 13, BOLDFONT).DrawBox(title, contentX + 5, contentY +1, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			Else
				GetBitmapFont("default", 13, BOLDFONT).DrawBox(title, contentX + 5, contentY   , contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			EndIf
		contentY :+ titleH


		'=== JOB DESCRIPTION AREA ===
		If jobDescriptionH > 0
			skin.RenderContent(contentX, contentY, contentW, jobDescriptionH, "1")

			Local firstJobID:Int = -1
			Local genreText:String = ""
			If not showAmateurInformation
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

				If genre >= 0 Then genreText = GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(genre))
				If genreText Then genreText = "~q" + genreText+"~q-"
			EndIf

			If firstJobID >= 0
				'add genre if you know the job
				skin.fontNormal.DrawBox(genreText + GetLocale("JOB_"+TVTPersonJob.GetAsString(firstJobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
			Else
				'use the given jobID but declare as amateur
				If jobID > 0
					skin.fontNormal.DrawBox(GetLocale("JOB_AMATEUR_"+TVTPersonJob.GetAsString(jobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
				Else
					skin.fontNormal.DrawBox(GetLocale("JOB_AMATEUR"), contentX + 5, contentY, contentW - 10, jobDescriptionH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
				EndIf
			EndIf

			contentY :+ jobDescriptionH
		EndIf


		'=== LIFE DATA AREA ===
		If lifeDataH > 0
			skin.RenderContent(contentX, contentY, contentW, lifeDataH, "1")
			'splitter
			GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + 165, contentY, 2, jobDescriptionH)
			Local latinCross:String = Chr(10013) '† = &#10013 ---NOT--- &#8224; (the dagger-cross)
			If person.IsCelebrity()
				Local dob:String = GetWorldTime().GetFormattedDate( person.GetPersonalityData().GetDOB(), GameConfig.dateFormat)
				If person.GetAge() >= 0
					skin.fontNormal.DrawSimple(dob + " (" + person.GetAge() + " " + GetLocale("ABBREVIATION_YEARS")+")", contentX + 5, contentY, skin.textColorNeutral)
				Else
					skin.fontNormal.DrawSimple("**.**.****", contentX + 5, contentY, skin.textColorNeutral)
				EndIf
				skin.fontNormal.DrawSimple(person.GetCountryCode(), contentX + 170 + 5, contentY, skin.textColorNeutral)
			EndIf
			contentY :+ lifeDataH
		EndIf


		'=== LAST PRODUCTIONS AREA ===
		if lastProductionsH > 0
			skin.RenderContent(contentX, contentY, contentW, lastProductionsH, "2")
			'If person.IsCelebrity() and person.GetProductionData()
			'If person.GetTotalProductionJobsDone() > 0 and 
			If person.GetProductionData()
				'last productions
				Local productionIDs:Int[] = person.GetProductionData().GetProducedProgrammeIDs()
				If productionIDs and productionIDs.length > 0
					Local i:Int = 0
					Local entryNum:Int = 0
					While i < productionIDs.length And entryNum < 3
						Local production:TProgrammeData = GetProgrammeDataCollection().GetByID( productionIDs[ i] )
						i :+ 1
						If Not production Then Continue

						skin.fontNormal.DrawSimple(production.GetYear(), contentX + 5, contentY + lastProductionEntryH*entryNum, yearColor)
						If production.IsInProduction()
							skin.fontNormal.DrawBox(production.GetTitle() + " ("+GetLocale("IN_PRODUCTION")+")", contentX + 5 + 25 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 25 - 5, lastProductionTitleH, sALIGN_LEFT_TOP, skin.textColorNeutral)
						Else
						'	skin.fontNormal.drawBlock(production.GetTitle(), contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, sALIGN_LEFT_TOP, skin.textColorNeutral)
							skin.fontNormal.DrawBox(production.GetTitle(), contentX + 5 + 25 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 25 - 5, lastProductionTitleH, sALIGN_LEFT_TOP, skin.textColorNeutral)
						EndIf
						entryNum :+1
					Wend
				EndIf
			EndIf
			contentY :+ lastProductionsH
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
			Local genreDefinition:TMovieGenreDefinition
			Local genreID:Int = -1
			If TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
				Local script:TScript = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script
				If script 
					genreID = script.mainGenre
					genreDefinition = GetMovieGenreDefinition( [genreID] + script.subgenres )
				EndIf
			EndIf


			'bars have a top-padding
			contentY :+ barAreaPaddingY
			'XP
			Local xpValue:Float = person.GetEffectiveJobExperiencePercentage(jobID)
			skin.RenderBar(contentX + 5, contentY, 100, 12, xpValue)
			skin.fontSmallCaption.DrawSimple(GetLocale("CAST_EXPERIENCE"), contentX + 5 + 100 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
			contentY :+ barH + 2
			'affinity
			Local affinity:Float = person.GetPersonalityData().GetAffinityValue(jobID, genreID)
			skin.RenderBar(contentX + 5, contentY, 100, 12, affinity)
			skin.fontSmallCaption.DrawSimple(GetLocale("CAST_AFFINITY"), contentX + 5 + 100 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
			contentY :+ barH + 2


			Local attributes:Int[] = [TVTPersonPersonalityAttribute.FAME, ..
			                          TVTPersonPersonalityAttribute.POWER, ..
			                          TVTPersonPersonalityAttribute.HUMOR, ..
			                          TVTPersonPersonalityAttribute.CHARISMA, ..
			                          TVTPersonPersonalityAttribute.APPEARANCE ..
			                         ]
			For Local attributeID:Int = EachIn attributes
				Local mode:Int = 0

				Local attributeFit:Float = 0.0
				Local attributeGenre:Float = 0.0
				Local attributePerson:Float = 0.0
				If genreDefinition
					attributeGenre = genreDefinition.GetCastAttribute(jobID, attributeID)
					attributePerson = person.GetPersonalityData().GetAttributeValue(attributeID)
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
'print person.GetFullName() + "   " +  GetLocale("CAST_"+TVTPersonPersonalityAttribute.GetAsString(attributeID).ToUpper()) + "   " + person.GetPersonalityData().GetAttributes().attributes[attributeID-1].Get() + " (" +person.GetPersonalityData().GetAttributes().attributes[attributeID-1].GetMin() + " - " + person.GetPersonalityData().GetAttributes().attributes[attributeID-1].GetMax() + ")"
				Select mode
					'unused
					Case 1
						Local oldA:Float = GetAlpha()
						SetAlpha oldA * 0.5
						skin.RenderBar(contentX + 5, contentY, 100, 12, attributePerson)
						SetAlpha oldA * 0.4
						skin.fontSmallCaption.DrawSimple(GetLocale("CAST_"+TVTPersonPersonalityAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
						SetAlpha oldA
					'neutral
					Case 2
						skin.RenderBar(contentX + 5, contentY, 100, 12, attributePerson)
						skin.fontSmallCaption.DrawSimple(GetLocale("CAST_"+TVTPersonPersonalityAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
					'negative
					Case 3
						skin.RenderBar(contentX + 5, contentY, 100, 12, attributePerson)
						skin.fontSmallCaption.DrawSimple(GetLocale("CAST_"+TVTPersonPersonalityAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY - 2, skin.textColorBad, EDrawTextEffect.Emboss, 0.3)
					'positive
					Case 4
						skin.RenderBar(contentX + 5, contentY, 100, 12, attributePerson)
						skin.fontSmallCaption.DrawSimple(GetLocale("CAST_"+TVTPersonPersonalityAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY - 2, skin.textColorGood, EDrawTextEffect.Emboss, 0.3)
				End Select
				contentY :+ barH + 2
			Next
		Else
			'bars have a top-padding
			contentY :+ barAreaPaddingY

			Local percentageUntilUpgrade:Float = person.GetProductionJobsDone(jobID) / float(GameRules.UpgradeInsignificantOnProductionJobsCount)

			skin.RenderBar(contentX + 5, contentY, 100, 12, percentageUntilUpgrade)
			skin.fontSmallCaption.DrawSimple(GetLocale("CAST_TRAINING"), contentX + 5 + 100 + 5, contentY - 2, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
			contentY :+ barH + 2

		EndIf
	'hidden?
	Rem
		'Scandalizing
		skin.RenderBar(contentX + 5, contentY, 100, 12, cast.GetScandalizing())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_SCANDALIZING"), contentX + 5 + 100 + 5, contentY, 125, 15, sALIGN_LEFT_TOP, skin.textColorLabel)
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
			skin.fontSmallCaption.DrawBox(GetLocale("JOB_"+TVTPersonJob.GetAsString(jobID)), contentX + 5, contentY - 1, 94, 25, sALIGN_LEFT_CENTER, skin.textColorLabel, EDrawTextEffect.Emboss, 0.3)
			skin.RenderBox(contentX + 5 + 94, contentY, contentW - 10 - 94 +1, -1, MathHelper.DottedValue(person.GetJobBaseFee(jobID, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.blocks, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.owner)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
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
	Global xpColor:SColor8 = new SColor8(70,85,160)
	Global sympathyColor:SColor8 = new SColor8(70,160,90)


	Method CreateSimple:TGUIProductionCompanyDropDownItem(company:TProductionCompanyBase)
		'make it "unique" enough
		Self.Create(New SVec2I(0,0), New SVec2I(100, 35), company.name+" [Lvl: "+company.GetLevel()+"]")

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
	
	
	Method DrawContent() override
		Super.DrawContent()

		Local scrRect:TRectangle = GetScreenRect()
		SetColor 150,150,150
		DrawLine(scrRect.GetX() + 10, scrRect.GetY2() - paddingBottom/2 -1, scrRect.GetX2() - 20, scrRect.GetY2() - paddingBottom/2 -1)
		SetColor 210,210,210
		DrawLine(scrRect.GetX() + 10, scrRect.GetY2() - paddingBottom/2, scrRect.GetX2() - 20, scrRect.GetY2() - paddingBottom/2)
	End Method


	Method DrawValue() override
		Local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")
		Local company:TProductionCompanyBase = TProductionCompanyBase(data.Get("productionCompany"))
		Local scrRect:TRectangle = GetScreenRect()

		'Super.DrawValue()
		local titleH:Int = skin.fontSmallCaption.DrawBox(company.name, scrRect.GetX() + 2, scrRect.GetY() - 2, scrRect.GetW()-4 - 20, scrRect.GetH(), sALIGN_LEFT_TOP, new SColor8(60,60,60)).y
		skin.fontSmall.DrawBox("Lvl: "+company.GetLevel(), scrRect.GetX()+2, scrRect.GetY() - 2, scrRect.GetW()-4, scrRect.GetH(), sALIGN_RIGHT_TOP, new SColor8(60,60,60))


		Local barH:Int = skin.GetBarSize(100,-1, "cast_bar_xp").y
		Local bottomY:Int = scrRect.GetY() + titleH - 1

		skin.RenderBar(scrRect.GetX() + 1, bottomY + 0*barH, 80, -1, company.GetLevelExperiencePercentage(), -1, "cast_bar_xp")
		skin.RenderBar(scrRect.GetX() + 1, bottomY + 1*barH, 80, -1, company.GetChannelSympathy( GetPlayerBase().playerID ), -1, "cast_bar_sympathy")

		If IsHovered() And (Time.MillisecsLong() / 1500) Mod 3 = 0 'every 3s for 1.5s
			skin.fontSmall.DrawBox("XP", scrRect.GetX() + 76, bottomY + 0*barH - 2, 30, 2*barH+2, sALIGN_RIGHT_CENTER, xpColor)
			skin.fontSmall.DrawBox("SYMP", scrRect.GetX() + 2, bottomY + 0*barH -2, scrRect.GetW()-4, 2*barH+2, sALIGN_RIGHT_CENTER, sympathyColor)
		Else
			skin.fontSmall.DrawBox(Int(company.GetLevelExperiencePercentage()*100)+"%", scrRect.GetX() + 76, bottomY + 0*barH - 2, 30, 2*barH+2, sALIGN_RIGHT_CENTER, xpColor)
			skin.fontSmall.DrawBox(Int(company.GetChannelSympathy( GetPlayerBase().playerID )*100)+"%", scrRect.GetX() + 2, bottomY + 0*barH - 2, scrRect.GetW()-4, 2*barH+2, sALIGN_RIGHT_CENTER, sympathyColor)
		EndIf
	End Method
End Type
