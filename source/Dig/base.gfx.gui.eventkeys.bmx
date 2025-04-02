SuperStrict
Import "base.util.event.bmx"

Global GUIEventKeys:TGUIEventKeys = new TGUIEventKeys

Type TGUIEventKeys
	'use when just creating an event for an onClick(event) call or similar
	Field DummyEvent:TEventKey = GetEventKey("GUIObject.DummyEvent", True)
	
	Field GUIObject_OnRemoveFocus:TEventKey = GetEventKey("GUIObject.OnRemoveFocus", True)
	Field GUIObject_OnSetFocus:TEventKey = GetEventKey("GUIObject.OnSetFocus", True)
	Field GUIObject_OnRemoveActive:TEventKey = GetEventKey("GUIObject.OnRemoveActive", True)
	Field GUIObject_OnSetActive:TEventKey = GetEventKey("GUIObject.OnSetActive", True)
	Field GUIObject_OnUpdate:TEventKey = GetEventKey("GUIObject.OnUpdate", True)
	Field GUIObject_OnDraw:TEventKey = GetEventKey("GUIObject.OnDraw", True)
	Field GUIObject_OnTryDrag:TEventKey = GetEventKey("GUIObject.OnTryDrag", True)
	Field GUIObject_OnBeginDrag:TEventKey = GetEventKey("GUIObject.OnBeginDrag", True)
	Field GUIObject_OnFinishDrag:TEventKey = GetEventKey("GUIObject.OnFinishDrag", True)
	Field GUIObject_OnDragFailed:TEventKey = GetEventKey("GUIObject.OnDragFailed", True)
	Field GUIObject_OnTryDrop:TEventKey = GetEventKey("GUIObject.OnTryDrop", True)
	Field GUIObject_OnBeginDrop:TEventKey = GetEventKey("GUIObject.OnBeginDrop", True)
	Field GUIObject_OnFinishDrop:TEventKey = GetEventKey("GUIObject.OnFinishDrop", True)
	Field GUIObject_OnDropFailed:TEventKey = GetEventKey("GUIObject.OnDropFailed", True)
	Field GUIObject_OnMouseScrollwheel:TEventKey = GetEventKey("GUIObject.OnMouseScrollwheel", True)
	Field GUIObject_OnMouseEnter:TEventKey = GetEventKey("GUIObject.OnMouseEnter", True)
	Field GUIObject_OnMouseLeave:TEventKey = GetEventKey("GUIObject.OnMouseLeave", True)
	Field GUIObject_OnMouseOver:TEventKey = GetEventKey("GUIObject.OnMouseOver", True)
	Field GUIObject_OnMouseDown:TEventKey = GetEventKey("GUIObject.OnMouseDown", True)
	Field GUIObject_OnClick:TEventKey = GetEventKey("GUIObject.OnClick", True)
	Field GUIObject_OnDoubleClick:TEventKey = GetEventKey("GUIObject.OnDoubleClick", True)
	Field GUIObject_OnSelect:TEventKey = GetEventKey("GUIObject.OnSelect", True)
	Field GUIObject_OnDeselect:TEventKey = GetEventKey("GUIObject.OnDeselect", True)	
	Field GUIObject_OnChange:TEventKey = GetEventKey("GUIObject.OnChange", True)	
	Field GUIObject_OnChangeValue:TEventKey = GetEventKey("GUIObject.OnChangeValue", True)	


	'base.gfx.gui.input.bmx
	Field GUIInput_OnChangeValue:TEventKey = GetEventKey("GUIInput.OnChangeValue", True)	
	Field GUIInput_OnFinishEdit:TEventKey = GetEventKey("GUIInput.OnFinishEdit", True)	

	'base.gfx.gui.accordeon.bmx
	Field GUIAccordeonPanel_OnOpen:TEventKey = GetEventKey("GUIAccordeonPanel.OnOpen", True)	
	Field GUIAccordeonPanel_OnClose:TEventKey = GetEventKey("GUIAccordeonPanel.OnClose", True)	
	Field GUIAccordeon_OnOpenPanel:TEventKey = GetEventKey("GUIAccordeon.OnOpenPanel", True)	
	Field GUIAccordeon_OnClosePanel:TEventKey = GetEventKey("GUIAccordeon.OnClosePanel", True)	

	'base.gfx.gui.slider.bmx
	Field GUISlider_SetValueByMouse:TEventKey = GetEventKey("GUISlider.SetValueByMouse", True)	

	'base.gfx.gui.button.bmx
	Field GUIButton_OnClick:TEventKey = GetEventKey("GUIButton.OnClick", True)	

	'base.gfx.gui.checkbox.bmx
	Field GUICheckbox_OnSetChecked:TEventKey = GetEventKey("GUICheckbox.OnSetChecked", True)	

	'base.gfx.gui.scroller.bmx
	Field GUIObject_OnScrollPositionChanged:TEventKey = GetEventKey("GUIObject.onScrollPositionChanged", True)	

	'base.gfx.gui.tabgroup.bmx
	Field GUIToggleButton_OnSetToggled:TEventKey = GetEventKey("GUIToggleButton.onSetToggled", True)	
	Field GUITabGroup_OnSetToggledButton:TEventKey = GetEventKey("GUITabGroup.onSetToggledButton", True)	

	'base.gfx.gui.list.base.bmx
	Field GUIListItem_OnClick:TEventKey = GetEventKey("GUIListItem.onClick", True)	
	Field GUIList_AddItem:TEventKey = GetEventKey("GUIList.AddItem", True)	
	Field GUIList_AddedItem:TEventKey = GetEventKey("GUIList.AddedItem", True)	
	Field GUIList_RemoveItem:TEventKey = GetEventKey("GUIList.RemoveItem", True)	
	Field GUIList_RemovedItem:TEventKey = GetEventKey("GUIList.RemovedItem", True)	
	Field GUIObject_OnDropBack:TEventKey = GetEventKey("GUIObject.OnDropBack", True)	

	'base.gfx.gui.list.selectlist.bmx
	Field GUISelectList_OnSelectEntry:TEventKey = GetEventKey("GUISelectList.onSelectEntry", True)	
	Field GUISelectList_OnSelectionChanged:TEventKey = GetEventKey("GUISelectList.onSelectionChanged", True)	

	'base.gfx.gui.list.slotlist.bmx
	Field GUISlotList_OnBeginReplaceSlotItem:TEventKey = GetEventKey("guiSlotList.onBeginReplaceSlotItem", True)	
	Field GUISlotList_OnReplaceSlotItem:TEventKey = GetEventKey("guiSlotList.onReplaceSlotItem", True)	
	Field GUIList_TryAddItem:TEventKey = GetEventKey("GUIList.TryAddItem", True)	
	Field GUIList_TryRemoveItem:TEventKey = GetEventKey("GUIList.TryRemoveItem", True)	

	'base.gfx.gui.window.modal.bmx
	Field GUIModalWindow_OnCreate:TEventKey = GetEventKey("GUIModalWindow.onCreate", True)	
	Field GUIModalWindow_OnOpen:TEventKey = GetEventKey("GUIModalWindow.onOpen", True)	
	Field GUIModalWindow_OnClose:TEventKey = GetEventKey("GUIModalWindow.onClose", True)	

	'base.gfx.gui.window.modalchain.bmx
	Field GUIModalWindowChain_OnOpen:TEventKey = GetEventKey("GUIModalWindowChain.onOpen", True)	
	Field GUIModalWindowChain_OnClose:TEventKey = GetEventKey("GUIModalWindowChain.onClose", True)
	
	'base.gfx.gui.chat.bmx
	Field Chat_OnAddEntry:TEventKey = GetEventKey("Chat.onAddEntry", True)	

	'base.gfx.gui.dropdown.bmx
	Field GUIDropDown_OnSelectEntry:TEventKey = GetEventKey("GUIDropDown.onSelectEntry", True)	
	Field GUIDropDown_OnSelectionChanged:TEventKey = GetEventKey("GUIDropDown.onSelectionChanged", True)	
	Field GUIDropDownItem_OnClick:TEventKey = GetEventKey("GUIDropDownItem.onClick", True)	
End Type
