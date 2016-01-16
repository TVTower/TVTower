SuperStrict

Framework brl.StandardIO

Import "../source/Dig/base.framework.graphicalapp.bmx"
Import "../source/Dig/base.gfx.bitmapfont.bmx"
Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.util.registry.imageloader.bmx"
Import "../source/Dig/base.util.registry.bitmapfontloader.bmx"

Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.gfx.gui.dropdown.bmx"
Import "../source/Dig/base.gfx.gui.slider.bmx"
Import "../source/Dig/base.gfx.gui.button.bmx"
Import "../source/Dig/base.gfx.gui.list.slotlist.bmx"
Import "../source/Dig/base.gfx.gui.window.modal.bmx"


Import "../source/game.database.bmx"
Import "../source/game.player.base.bmx"
Import "../source/game.registry.loaders.bmx" 'genres

Import "../source/game.production.productionconcept.bmx"
Import "../source/game.production.productioncompany.bmx"
Import "../source/game.production.shoppinglist.gui.bmx"



Global MyApp:TMyApp = New TMyApp
MyApp.debugLevel = 1

Type TMyApp Extends TGraphicalApp
	Field mouseCursorState:Int = 0
	Field dbLoader:TDatabaseLoader
	Field bg:TImage
	Field screen:TTestScreen

	Method Prepare:Int()
		Super.Prepare()

		Local gm:TGraphicsManager = TGraphicsManager.GetInstance()
		GetDeltatimer().Init(30, -1)
		GetGraphicsManager().SetResolution(800,600)
		GetGraphicsManager().InitGraphics()	

		'we use a full screen background - so no cls needed
		autoCls = True

		'=== LOAD RESOURCES ===
		Local registryLoader:TRegistryLoader = New TRegistryLoader
		'if loading from a "parent directory" - state this here
		'-> all resources can get loaded with "relative paths"
		registryLoader.baseURI = "../"
		if FileType("TVTower") or FileType("TVTower.app") or FileType("TVTower.exe")
			registryLoader.baseURI = ""
		endif

		'afterwards we can display background images and cursors
		'"TRUE" indicates that the content has to get loaded immediately
		registryLoader.LoadFromXML("config/startup.xml", True)

		registryLoader.LoadFromXML("config/programmedatamods.xml", True)
		GetMovieGenreDefinitionCollection().Initialize()

'		registryLoader.LoadFromXML("config/resources.xml")
		registryLoader.LoadFromXML("config/screen_elements.xml", True)
		registryLoader.LoadFromXML("config/gfx.xml")

		bg = LoadImage(registryLoader.baseURI + "res/gfx/supermarket/screen_supermarket.png")
		
		registryLoader.LoadFromXML("config/gui.xml")


		'load db
		dbLoader = New TDatabaseLoader
		dbLoader.LoadDir(registryLoader.baseURI + "res/database/Default")

		'set game time
		GetWorldTime().SetStartYear(1985)
		'refresh states of old programme productions (now we now
		'the start year and are therefore able to refresh who has
		'done which programme yet)
		GetProgrammeDataCollection().UpdateAll()
	

		TLocalization.LoadLanguageFiles(registryLoader.baseURI + "res/lang/lang_*.txt")
		'set default languages
		TLocalization.SetFallbackLanguage("en")
		TLocalization.SetCurrentLanguage("de")

		screen = New TTestScreen.Init("test")
		GetScreenManager().Set(screen)
		GetScreenManager().SetCurrent( GetScreenManager().Get("test") )


		'get a new script
		local script:TScript = GetScriptCollection().GetRandomAvailable()
		script.SetOwner(1)

		'create some companies
		local cnames:string[] = ["Movie World", "Picture Fantasy", "UniPics", "Motion Gems", "Screen Jewel"]
		For local i:int = 0 until cnames.length
			local c:TProductionCompany = new TProductionCompany
			c.name = cnames[i]
			c.SetExperience( BiasedRandRange(0, 0.35 * TProductionCompanyBase.MAX_XP, 0.25) )
			GetProductionCompanyBaseCollection().Add(c)
		Next

		RoomHandler_Supermarket.GetInstance().Initialize()
		RoomHandler_Supermarket.GetInstance().CreateNewConcept(script)


		'debug
		local p:TProgrammePersonBase[] = GetProgrammePersonBaseCollection().GetAllInsignificantAsArray()
		for local i:int = 0 until p.length
			if TProgrammePerson(p[i]) then print "failed: "+i+"   " + p[i].GetGUID() 
		next
	End Method


	Method Update:Int()
		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()


		'=== UPDATE GUI ===
		'system wide gui elements
		GuiManager.Update("SYSTEM")

		'run parental update (screen handling)
		Super.Update()


		if KeyManager.IsHit(KEY_SPACE)
			'get a new script
			local script:TScript = GetScriptCollection().GetRandomAvailable()
			script.SetOwner(1)

			RoomHandler_Supermarket.GetInstance().CreateNewConcept(script)
		endif

		if KeyManager.IsHit(KEY_1)
			currentProductionConcept.SetCast(0, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
		Endif
		if KeyManager.IsHit(KEY_2)
			currentProductionConcept.SetCast(1, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
		Endif
		if KeyManager.IsHit(KEY_3)
			RoomHandler_Supermarket.GetInstance().castSlotList.SetSlotCast(2, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True) )
			'currentProductionConcept.SetCast(2, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
		Endif
		if KeyManager.IsHit(KEY_4)
			RoomHandler_Supermarket.GetInstance().castSlotList.SetSlotCast(3, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True) )
		Endif
		if KeyManager.IsHit(KEY_5)
			currentProductionConcept.SetCast(4, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
		Endif

		if KeyManager.IsHit(KEY_Q)
			currentProductionConcept.SetProductionCompany( TProductionCompanyBase(RoomHandler_Supermarket.GetInstance().productionCompanySelect.GetEntryByPos(0).data.Get("productionCompany")) )
		Endif
		if KeyManager.IsHit(KEY_W)
			currentProductionConcept.SetProductionCompany( TProductionCompanyBase(RoomHandler_Supermarket.GetInstance().productionCompanySelect.GetEntryByPos(1).data.Get("productionCompany")) )
		Endif
		if KeyManager.IsHit(KEY_E)
			currentProductionConcept.SetProductionCompany( TProductionCompanyBase(RoomHandler_Supermarket.GetInstance().productionCompanySelect.GetEntryByPos(2).data.Get("productionCompany")) )
		Endif
		if KeyManager.IsHit(KEY_R)
			'random one
			currentProductionConcept.SetProductionCompany( GetProductionCompanyBaseCollection().GetRandom() )
		Endif

		if KeyManager.IsHit(KEY_NUM1)
			currentProductionConcept.SetProductionFocus(1, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM2)
			currentProductionConcept.SetProductionFocus(2, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM3)
			currentProductionConcept.SetProductionFocus(3, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM4)
			currentProductionConcept.SetProductionFocus(4, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM5)
			currentProductionConcept.SetProductionFocus(5, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM6)
			currentProductionConcept.SetProductionFocus(6, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM7)
			currentProductionConcept.SetProductionFocus(7, RandRange(0,10))
		Endif
		if KeyManager.IsHit(KEY_NUM8)
			currentProductionConcept.productionFocus.SetFocusPointsMax( Max(0, currentProductionConcept.productionFocus.focusPointsMax - 1))
		Endif
		if KeyManager.IsHit(KEY_NUM9)
			currentProductionConcept.productionFocus.SetFocusPointsMax( currentProductionConcept.productionFocus.focusPointsMax + 1)
		Endif
		

		'check if new resources have to get loaded
		TRegistryUnloadedResourceCollection.GetInstance().Update()

		'reset modal window states
		GUIManager.EndUpdates()
	End Method


	Method Render:Int()
		Super.Render()
	End Method


	Method RenderContent:Int()
		'=== RENDER GUI ===
		'system wide gui elements
		GuiManager.Draw("SYSTEM")
	End Method


	Method RenderLoadingResourcesInformation:Int()
		'do nothing if there is nothing to load
		If TRegistryUnloadedResourceCollection.GetInstance().FinishedLoading() Then Return True

		'reduce instance requests
		Local RURC:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()

		SetAlpha 0.2
		SetColor 50,0,0
		DrawRect(0, GraphicsHeight() - 20, GraphicsWidth(), 20)
		SetAlpha 1.0
		SetColor 255,255,255
		DrawText("Loading: "+RURC.loadedCount+"/"+RURC.toLoadCount+"  "+String(RURC.loadedLog.Last()), 0, 580)
	End Method


	Method RenderHUD:Int()
		'=== DRAW RESOURCEL LOADING INFORMATION ===
		'if there is a resource loading currently - display information
		RenderLoadingResourcesInformation()



		'=== DRAW MOUSE CURSOR ===
		'default pointer
		'If Game.cursorstate = 0 Then
		GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)
		'open hand
'		If Game.cursorstate = 1 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11, 	MouseManager.y-8	,1)
		'grabbing hand
'		If Game.cursorstate = 2 Then GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-11,	MouseManager.y-16	,2)
'		GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x, MouseManager.y, mouseCursorState)
	End Method
End Type


'kickoff
MyApp.SetTitle("Demoapp")
MyApp.Run()



Global currentProductionConcept:TProductionConcept

Type TTestScreen extends TScreen
	Global _eventListeners:TLink[]


	Method Init:TTestScreen(name:string)
		Super.Init(name)




		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		return self
	End Method


	Method Update:int()
		RoomHandler_Supermarket.GetInstance().UpdateCustomProduction()
	End Method


	Method Render:int()
		RoomHandler_Supermarket.GetInstance().RenderCustomProduction()
	End Method
End Type




Type RoomHandler_Supermarket 'extends TRoomHandler
	'datasheet
	Field productionFocusSlider:TGUISlider[6]
	Field productionFocusLabel:string[6]
	Field newProductionButton:TGUIButton
	Field startProductionButton:TGUIButton
	Field shoppingListList:TGUISelectList
	Field productionCompanySelect:TGUIDropDown
	Field castSlotList:TGUICastSlotList
	Field repositionSliders:int = True

	Global hoveredGuiCastItem:TGUICastListItem

	Global _instance:RoomHandler_Supermarket
	'ENTFERNEN 
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_Supermarket()
		if not _instance then _instance = new RoomHandler_Supermarket
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		InitCustomProductionElements()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'GUI -> GUI
		'this lists want to delete the item if a right mouse click happens...
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickCastItem, "TGUICastListItem") ]
		'we want to know if we hover a specific block
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverCastItem, "TGUICastListItem" ) ]

		'GUI -> LOGIC
		'react to clicks on slider or other ways of changing it
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onChangeValue", onChangeFocusPointSlider, "TGUISlider" ) ]
		'changes to the cast (slot) list
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.addedItem", onProductionConceptChangeCastSlotList, "TGUICastSlotList" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiList.removedItem", onProductionConceptChangeCastSlotList, "TGUICastSlotList" ) ]
		'changes to production focus sliders
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onChangeValue", onProductionConceptChangeFocusSliders, "TGUISlider" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onSetFocus", onProductionConceptSetFocusSliderFocus, "TGUISlider" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onRemoveFocus", onProductionConceptRemoveFocusSliderFocus, "TGUISlider" ) ]
		'changes to production company dropdown
		_eventListeners :+ [ EventManager.registerListenerFunction("GUIDropDown.onSelectEntry", onProductionConceptChangeProductionCompanyDropDown, "TGUIDropDown" ) ]


		'LOGIC -> GUI
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionConcept.SetCast", onProductionConceptChangeCast ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionConcept.SetProductionCompany", onProductionConceptChangeProductionCompany ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionFocus.SetFocus", onProductionConceptChangeProductionFocus ) ]


		'(re-)localize content
'		SetLanguage()
	End Method

	
	Method CleanUp()
		'=== unset cross referenced objects ===
		'
		
		'=== remove obsolete gui elements ===
		'
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		'GetRoomHandlerCollection().SetHandler("supermarket", GetInstance())
	End Method


	Method CreateNewConcept(script:TScript)
		'sollte normalerweise von der "ShoppingList" uebernommen werden
		'-> und die Shoppingliste dann geloescht, sobald die Produktion
		'   eingestellt ist - mit dem "TProductionConcept" kann dann ins
		'   Studio gegangen werden
		currentProductionConcept = new TProductionConcept
		currentProductionConcept.Initialize()
		currentProductionConcept.SetScript(script)

		'=== RESET GUI ===
		For local i:int = 0 to productionFocusSlider.length -1
			productionFocusSlider[i].SetValue(0)
		Next

		productionCompanySelect.SetValue("Produktionsfirma")

		'hide sliders according to focuspoint type of script
		'(this is _different_ to the "disable" action done in
		' UpdateCustomProduction())
		For local i:int = 0 to productionFocusSlider.length -1
			if currentProductionConcept.productionFocus.GetFocusAspectCount() <= i
				productionFocusSlider[i].Hide()
'				productionFocusSlider[i].Disable()
			endif
		Next
		'or enable them...
		For local i:int = 0 to productionFocusSlider.length -1
			if currentProductionConcept.productionFocus.GetFocusAspectCount() > i
				productionFocusSlider[i].Show()
'				productionFocusSlider[i].Enable()
			endif
		Next
		'reposition them
		repositionSliders = True

		'cast: remove old entries
		castSlotList.EmptyList()
		castSlotList.SetItemLimit( script.cast.length )
		For local i:int = 0 until script.cast.length
			castSlotList.SetSlotJob(script.cast[i].job, i)
		Next
	End Method


	'=== DROPDOWN - PRODUCTION COMPANY - EVENTS ===

	'GUI -> LOGIC reaction
	'set production concepts production company according to selection
	Function onProductionConceptChangeProductionCompanyDropDown:int(triggerEvent:TeventBase)
		local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		if dropdown <> GetInstance().productionCompanySelect then return False

		local entry:TGUIDropDownItem = TGUIDropDownItem(dropdown.GetSelectedEntry())
		if not entry or not entry.data then return False

		local company:TProductionCompanyBase = TProductionCompanyBase(entry.data.Get("productionCompany"))
		if not company then return False

		currentProductionConcept.SetProductionCompany(company)
	End Function


	'LOGIC -> GUI reaction
	Function onProductionConceptChangeProductionCompany:int(triggerEvent:TEventBase)
		local productionConcept:TProductionConcept = TProductionConcept(triggerEvent.GetSender())
		local company:TProductionCompanyBase = TProductionCompanyBase(triggerEvent.GetData().Get("productionCompany"))
		if productionConcept <> currentProductionConcept then return False

		'skip without changes
		local newItem:TGUIDropDownItem
		For local i:TGUIDropDownItem = EachIn GetInstance().productionCompanySelect.GetEntries()
			if not i.data or i.data.Get("productionCompany") <> company then continue

			newItem = i
			exit
		Next
		if newItem = GetInstance().productionCompanySelect.GetSelectedEntry() then return False

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

		return True
	End Function


	'=== SLIDER - PRODUCTION FOCUS - EVENTS ===

	'LOGIC -> GUI reaction
	'Triggered on change of the production concepts production focus.
	'Adjusts the GUI sliders to represent the new values.
	Function onProductionConceptChangeProductionFocus:int(triggerEvent:TEventBase)
		local productionFocus:TProductionFocusBase = TProductionFocusBase(triggerEvent.GetSender())
		if currentProductionConcept.productionFocus <> productionFocus then return False

		local focusIndex:int = triggerEvent.GetData().GetInt("focusIndex")
		local value:int = triggerEvent.GetData().GetInt("value")

		'skip without production company!
		if not currentProductionConcept.productionCompany then return False

		'skip focus aspects without sliders
		if focusIndex < 0 or GetInstance().productionFocusSlider.length < focusIndex then return False

		'skip without changes
		if int(GetInstance().productionFocusSlider[focusIndex -1].GetValue()) = value then return False

		'disable a previously set limit
		GetInstance().productionFocusSlider[focusIndex -1].DisableLimitValue()
		'adjust values
		GetInstance().productionFocusSlider[focusIndex -1].SetValue(value)
	End Function


	'GUI
	'Limit slider range to points available
	'Triggered as soon as the user activates the TGUISlider element.
	Function onProductionConceptSetFocusSliderFocus:int(triggerEvent:TEventBase)
		local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		if not slider then return False

		_AdjustProductionConceptFocusSliderLimit(slider)
	End Function


	Function _GetProductionConceptFocusSliderByFocusIndex:TGUISlider(index:int)
		For local s:TGUISlider = EachIn GetInstance().productionFocusSlider
			if s.data and s.data.GetInt("focusIndex") = index then return s
		Next
		return Null
	End Function
	

	'helper, so slider limit could get adjusted by other objects too
	Function _AdjustProductionConceptFocusSliderLimit(slider:TGUISlider)
		if not slider then return
		
		'adjust slider limit dynamically
		local focusIndex:int = slider.data.GetInt("focusIndex")
		local currentValue:int = Max(0, currentProductionConcept.GetProductionFocus(focusIndex))
		local desiredValue:int = int(slider.GetValue())
		'available points (of 10)
		local maxValue:int = Min(10, currentProductionConcept.productionFocus.GetFocusPointsLeft() + currentValue)

		slider.SetLimitValueRange(0, maxValue)
	End Function

	
	'GUI
	'Remove slider limit
	'Triggered as soon as the user deactivates the TGUISlider element.
	Function onProductionConceptRemoveFocusSliderFocus:int(triggerEvent:TEventBase)
		local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		if not slider then return False

		Slider.DisableLimitValue()
	End Function
	

	'GUI -> LOGIC reaction
	'GUI -> GUI reaction
	'Changes production focus value according to TGUISlider values.
	'Triggered on each change to a TGUISlider element. Additionally the
	'function adjusts slider values on limited production focus values.
	Function onProductionConceptChangeFocusSliders:int(triggerEvent:TEventBase)
		local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		if not slider then return False

		local focusIndex:int = slider.data.GetInt("focusIndex")
		local currentValue:int = currentProductionConcept.GetProductionFocus(focusIndex)
		local newValue:int = int(slider.GetValue())

		'skip if nothing to do
		if newValue = currentValue then return False

		'set logic-value
		currentProductionConcept.SetProductionFocus( focusIndex, newValue )
		'fetch resulting value (might differ because of limitations)
		newValue = Max(0, currentProductionConcept.GetProductionFocus(focusIndex))

		'there might be a limitation - so adjust gui slider
		if newValue <> int(slider.GetValue())
			slider.SetValue( newValue )
		endif
	End Function

	
	'=== CAST LISTS - EVENTS ===

	'LOGIC -> GUI reaction
	'GUI -> GUI reaction
	Function onProductionConceptChangeCast:int(triggerEvent:TEventBase)
		local castIndex:int = triggerEvent.GetData().GetInt("castIndex")
		local person:TProgrammePersonBase = TProgrammePersonBase(triggerEvent.GetData().Get("person"))

		'skip without changes
		if GetInstance().castSlotList.GetSlotCast(castIndex) = person then return False
		'if currentProductionConcept.GetCast(castIndex) = person then return False

		'create new gui element
		GetInstance().castSlotList.SetSlotCast(castIndex, person)
	End Function


	'GUI -> LOGIC reaction
	Function onProductionConceptChangeCastSlotList:int(triggerEvent:TEventBase)
		'local list:TGUICastSlotList = TGUICastSlotList( triggerEvent.GetSender() )
		local item:TGUICastListItem = TGUICastListItem( triggerEvent.GetData().Get("item") )
		local slot:int = triggerEvent.GetData().GetInt("slot")

		'DO NOT skip without changes
		'-> we listen to "successful"-message ("added" vs "add")
		'   so the slot is already filled then
		'if GetInstance().castSlotList.GetSlotCast(slot) = item.person then return False


		if item and triggerEvent.IsTrigger("guiList.addedItem")
			'print "set "+slot + "  " + item.person.GetFullName()
			currentProductionConcept.SetCast(slot, item.person)
		else
			'print "clear "+slot
			currentProductionConcept.SetCast(slot, null)
		endif
	End Function
		

	'we need to know whether we hovered an cast entry to show the
	'datasheet
	Function onMouseOverCastItem:int( triggerEvent:TEventBase )
		local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		GetInstance().hoveredGuiCastItem = item

		return TRUE
	End Function
	

	'in case of right mouse button click we want to remove the
	'cast
	Function onClickCastItem:int(triggerEvent:TEventBase)
		'print "click on cast item"
		'only react if the click came from the right mouse button
		if triggerEvent.GetData().getInt("button",0) <> 2 then return TRUE

		local guiCast:TGUICastListItem = TGUICastListItem(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not guiCast or not guiCast.isDragged() then return FALSE

		'remove from production
'		currentProductionConcept.SetCast(slot, null)

		'remove gui object
		guiCast.remove()
		guiCast = null
		
		'remove right click - to avoid leaving the room
		MouseManager.ResetKey(2)
	End Function


	'we need to know whether we hovered an cast entry to show the
	'datasheet
	Function onChangeFocusPointSlider:int( triggerEvent:TEventBase )
'		local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
'		if item = Null then return FALSE

'		hoveredGuiCastItem = item

		return TRUE
	End Function


	Function _GetEventFocusSlider:TGUISlider(triggerEvent:TEventBase)
		local slider:TGUISlider
		For local s:TGUISlider = Eachin GetInstance().productionFocusSlider
			if s = triggerEvent.GetSender() then slider = s
		Next
		'skip other sliders
		if not slider then return null
		if not slider.data then return null
		return slider
	End Function


	Method InitCustomProductionElements()
		'=== CAST ===
		'============
		castSlotList = new TGUICastSlotList.Create(new TVec2D.Init(300,200), new TVec2D.Init(200, 200), "supermarket_customproduction_castbox")

		castSlotList.SetSlotMinDimension(230, 42)
		'occupy the first free slot?
		'castSlotList.SetAutofillSlots(true)


		'=== PRODUCTION COMPANY ===
		'==========================

		'=== PRODUCTION COMPANY SELECT ===
		productionCompanySelect = new TGUIDropDown.Create(new TVec2D.Init(600,200), new TVec2D.Init(150,-1), "Produktionsfirma", 128, "supermarket_customproduction_productionbox")
		'add some items to that list
		For local p:TProductionCompanyBase = EachIn GetProductionCompanyBaseCollection().entries.values()
			'base items do not have a size - so we have to give a manual one
			local item:TGUIDropDownItem = new TGUIDropDownItem.Create(null, null, p.name+" [Lvl: "+p.GetLevel()+"]")
			item.data = new TData.Add("productionCompany", p)
			productionCompanySelect.AddItem( item )
		Next


		'=== PRODUCTION WEIGHTS ===
		For local i:int = 0 to productionFocusSlider.length -1
			productionFocusSlider[i] = New TGUISlider.Create(New TVec2D.Init(640,300 + i*25), New TVec2D.Init(150,22), "0", "supermarket_customproduction_productionbox")
			productionFocusSlider[i].SetValueRange(0,10)
			productionFocusSlider[i].steps = 10
			productionFocusSlider[i]._gaugeOffset.SetY(2)
			productionFocusSlider[i].SetRenderMode(TGUISlider.RENDERMODE_DISCRETE)
			productionFocusSlider[i].SetDirection(TGUISlider.DIRECTION_RIGHT)
			productionFocusSlider[i].data = new TData.AddNumber("focusIndex", i+1)

			productionFocusSlider[i]._handleDim.SetX(17)
		Next


		'=== NEW PRODUCTION BUTTON ===
		newProductionButton = new TGUIButton.Create(new TVec2D.Init(20, 20), new TVec2D.Init(100, 28), "Neue Produktion", "supermarket_customproduction_newproduction")
		newProductionButton.disable()
		newProductionButton.spriteName = "gfx_gui_button.datasheet"

		'=== START PRODUCTION BUTTON ===
		startProductionButton = new TGUIButton.Create(new TVec2D.Init(20, 200), new TVec2D.Init(100, 28), "Produktion starten", "supermarket_customproduction_newproduction")
		startProductionButton.disable()
		startProductionButton.spriteName = "gfx_gui_button.datasheet"

		shoppingListList = new TGUISelectList.Create(new TVec2D.Init(20,20), new TVec2D.Init(150,150), "supermarket_customproduction_newproduction")
		'add some items to that list
		for local i:int = 1 to 10
			local script:TScript = GetScriptCollection().GetRandomAvailable()
			local shoppingList:TShoppingList = new TShoppingList.Init(1, script)
			local item:TGuiShoppingListSelectListItem = new TGuiShoppingListSelectListItem.Create(null, new TVec2D.Init(150,24), "ICON + Drehbuchtitel "+i)

			script.SetOwner(1)
			item.SetShoppingList(shoppingList)
			'base items do not have a size - so we have to give a manual one
			shoppingListList.AddItem( item )
		Next
		'refresh scrolling state
		shoppingListList.Resize(150, 170)
	End Method


	Method UpdateCustomProduction()
		'gets refilled in gui-updates
		hoveredGuiCastItem = null

		'disable _all_ sliders if no production company is selected
		if not currentProductionConcept.productionCompany and productionFocusSlider[0].IsEnabled()
			For local i:int = 0 to productionFocusSlider.length -1
				productionFocusSlider[i].Disable()
			Next
		endif
		'or enable (specific of) them...
		if currentProductionConcept.productionCompany and not productionFocusSlider[0].IsEnabled()
			For local i:int = 0 to productionFocusSlider.length -1
				if currentProductionConcept.productionFocus.GetFocusAspectCount() > i
					productionFocusSlider[i].Enable()
				endif
			Next
		endif

		GuiManager.Update("supermarket_customproduction_castbox_modal")
		GuiManager.Update("supermarket_customproduction_newproduction")
		GuiManager.Update("supermarket_customproduction_productionbox")
		GuiManager.Update("supermarket_customproduction_castbox")
	End Method


	Method RenderCustomProduction()
		'draw a background on all menus
'		SetClsColor(160,160,160)
'		Cls
		SetColor(255,255,255)

		DrawImage(MyApp.bg,0,0)
'		SetColor 190,190,190
'		DrawRect(0,0,800,375)
		SetColor 50,50,50
		DrawRect(0,375,800,225)
		SetColor 255,255,255


		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		'where to draw
		local outer:TRectangle = new TRectangle
		'calculate position/size of content elements
		local contentX:int = 0
		local contentY:int = 0
		local contentW:int = 0
		local contentH:int = 0
		local outerSizeH:int = skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		local outerH:int = 0 'size of the "border"
		
		local titleH:int = 18, subTitleH:int = 16
		local boxAreaH:int = 0, buttonAreaH:int = 0, bottomAreaH:int = 0, msgH:int = 0
		local boxAreaPaddingY:int = 4, buttonAreaPaddingY:int = 4
		local msgPaddingY:int = 4

		msgH = skin.GetMessageSize(100, -1, "").GetY()



		'=== SHOPPING LIST ===
		outer.Init(10, 15, 200, 200)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		buttonAreaH = newProductionButton.rect.GetH() + 2*buttonAreaPaddingY

		local listH:int = contentH - titleH - buttonAreaH
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock("Einkaufslisten", contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		if shoppingListList.rect.getX() <> contentX + 5
			shoppingListList.rect.SetXY(contentX + 5, contentY + 3)
			shoppingListList.Resize(contentW - 10, listH - 6)
		endif
		contentY :+ listH

		skin.RenderContent(contentX, contentY, contentW, contentH - (listH+titleH) , "1_bottom")
		'reposition button
		newProductionButton.rect.SetXY(contentX + 5, contentY + buttonAreaPaddingY)
		newProductionButton.Resize(contentW - 10)
		contentY :+ contentH - (listH+titleH)

		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())




		'=== CHECK AND START BOX ===
		outer.SetXY(10, 220)
		outer.dimension.SetXY(200,136)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		buttonAreaH = newProductionButton.rect.GetH() + 2*buttonAreaPaddingY

		'reset
		contentY = contentY
		skin.RenderContent(contentX, contentY, contentW, contentH - buttonAreaH, "1_top")
		contentY :+ 3
		skin.fontBold.drawBlock("Besetzung", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorLabel, 0,1,1.0,True, True)
		if currentProductionConcept
			skin.fontNormal.drawBlock(TFunctions.DottedValue(currentProductionConcept.GetCastCost()), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
		else
			skin.fontNormal.drawBlock("0", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
		endif
		contentY :+ subtitleH
		skin.fontBold.drawBlock("Produktion", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorLabel, 0,1,1.0,True, True)
		if currentProductionConcept
			skin.fontNormal.drawBlock(TFunctions.DottedValue(currentProductionConcept.GetProductionCost()), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
		else
			skin.fontNormal.drawBlock("0", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
		endif
		contentY :+ subtitleH

		SetColor 150,150,150
		DrawRect(contentX + 5, contentY-1, contentW - 10, 1)
		SetColor 255,255,255

		contentY :+ 1
		skin.fontBold.drawBlock("Gesamtkosten", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		if currentProductionConcept
			skin.fontBold.drawBlock(TFunctions.DottedValue(currentProductionConcept.GetTotalCost()), contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
		else
			skin.fontBold.drawBlock("0", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorBad, 0,1,1.0,True, True)
		endif
			

		contentY :+ subtitleH

		contentY :+ 10
		skin.fontBold.drawBlock("Dauer", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		if currentProductionConcept
			skin.fontNormal.drawBlock(currentProductionConcept.GetBaseProductionTime()+" Stunden", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		else
			skin.fontNormal.drawBlock("", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_RIGHT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
		contentY :+ subtitleH

		contentY :+ (contentH - buttonAreaH) - 4*subtitleH - 3 -1 - 10

		skin.RenderContent(contentX, contentY, contentW, buttonAreaH, "1_bottom")
		'reposition button
		startProductionButton.rect.SetXY(contentX + 5, contentY + buttonAreaPaddingY)
		startProductionButton.Resize(contentW - 10)
		contentY :+ buttonAreaH

		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())





		'=== CAST / MESSAGE BOX ===
		'calc height
		local castAreaH:int = 215
		local msgAreaH:int = 0
		if not currentProductionConcept.IsCastComplete() then msgAreaH :+ msgH + msgPaddingY
		if not currentProductionConcept.IsFocusPointsComplete() then msgAreaH :+ msgH + msgPaddingY

		outerH = outerSizeH + titleH + subTitleH + castAreaH + msgAreaH
		
		outer.SetXY(225, 15)
		outer.dimension.SetXY(350, outerH)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		'reset
		contentY = contentY

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		if currentProductionConcept
			skin.fontCaption.drawBlock(currentProductionConcept.script.title.Get(), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
		contentY :+ titleH

		skin.RenderContent(contentX, contentY, contentW, subTitleH, "1")
		skin.fontNormal.drawBlock("Untertitel", contentX + 5, contentY-1, contentW - 10, subTitleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ subTitleH

		skin.RenderContent(contentX, contentY, contentW, castAreaH, "2")
		'reposition cast list
		if castSlotList.rect.getX() <> contentX + 5
			castSlotList.rect.SetXY(contentX +5, contentY + 3)
			castSlotList.resize(contentW - 10, castAreaH - 6 )
		endif

		contentY :+ castAreaH

		if msgAreaH > 0 
			skin.RenderContent(contentX, contentY, contentW, msgAreaH, "1_bottom")
			if not currentProductionConcept.IsCastComplete() 
				skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, "Besetzung unvollstaendig", "audience", "warning")
				contentY :+ msgH + msgPaddingY
			endif
			if not currentProductionConcept.IsFocusPointsComplete()
				if currentProductionConcept.productionCompany
					skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("PRODUCTION_FOCUS_POINTS_NOT_SET_COMPLETELY"), "spotsplanned", "neutral")
				else
					skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("NO_PRODUCTION_COMPANY_SELECTED"), "spotsplanned", "warning")
				endif
				contentY :+ msgH + msgPaddingY
			endif
		endif

		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())




		'=== PRODUCTION BOX ===
		local productionFocusSliderH:int = 21
		local productionFocusLabelH:int = 15
		local productionCompanyH:int = 60
		local productionFocusH:int = titleH + subTitleH + 5 'bottom padding
		if currentProductionConcept.productionFocus
			productionFocusH :+ currentProductionConcept.productionFocus.GetFocusAspectCount() * (productionFocusSliderH + productionFocusLabelH)
		endif
		outerH = outerSizeH + titleH + productionCompanyH + productionFocusH
		
		outer.SetXY(590, 15)
		outer.dimension.SetXY(200, outerH)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

	
		'reset
		contentY = contentY
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		skin.fontCaption.drawBlock("Produktionsdetails", contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH

		skin.RenderContent(contentX, contentY, contentW, productionCompanyH + productionFocusH, "1")

		skin.fontSemiBold.drawBlock("Produktionsfirma", contentX + 5, contentY + 3, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		'reposition dropdown
		if productionCompanySelect.rect.getX() <> contentX + 5
			productionCompanySelect.rect.SetXY(contentX + 5, contentY + 20)
			productionCompanySelect.resize(contentW - 10, -1)
		endif
		contentY :+ productionCompanyH

		skin.fontSemiBold.drawBlock("Schwerpunkte", contentX + 5, contentY + 3, contentW - 10, titleH - 3, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		'reposition sliders
		if repositionSliders
			local sliderOrder:int[]
			if currentProductionConcept and currentProductionConcept.productionFocus
				sliderOrder = currentProductionConcept.productionFocus.GetOrderedFocusIndices()
			else
				sliderOrder = [1,2,3,4,5,6]
			endif
			For local i:int = 0 until sliderOrder.length
				local sliderNum:int = sliderOrder[i]
				local slider:TGUISlider = productionFocusSlider[ sliderNum-1]
				slider.rect.SetXY(contentX + 5, contentY + productionFocusLabelH + i * (productionFocusLabelH + productionFocusSliderH))
				slider.Resize(contentW - 10)
			Next
			repositionSliders = False
		endif

if currentProductionConcept and currentProductionConcept.productionFocus
		local pF:TProductionFocusBase = currentProductionConcept.productionFocus
		For local labelNum:int = EachIn pF.GetOrderedFocusIndices()
'		For local labelNum:int = 0 until productionFocusLabel.length
			if not productionFocusSlider[labelNum-1].IsVisible() then continue
			local focusIndex:int = productionFocusSlider[labelNum-1].data.GetInt("focusIndex")
			local label:string = GetLocale(TVTProductionFocus.GetAsString(focusIndex))
			skin.fontNormal.drawBlock(label, contentX + 10, contentY, contentW - 15, titleH, ALIGN_LEFT_CENTER, skin.textColorLabel, 0,1,1.0,True, True)
			contentY :+ (productionFocusLabelH + productionFocusSliderH)
		Next

		'inform about unused skill points / missing company selection
		local color:TColor
		if currentProductionConcept.productionCompany
			if pF.GetFocusPointsSet() < pF.GetFocusPointsMax()
				color = skin.textColorWarning
			else
				color = skin.textColorLabel
			endif
			local text:string = GetLocale("POINTSSET_OF_POINTSMAX_POINTS_SET").replace("%POINTSSET%", pF.GetFocusPointsSet()).replace("%POINTSMAX%", pF.GetFocusPointsMax())
			skin.fontNormal.drawBlock("|i|"+text+"|/i|", contentX + 5, contentY, contentW - 10, subTitleH, ALIGN_CENTER_CENTER, color, 0,1,1.0,True, True)
		endif
		contentY :+ subTitleH
endif
		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())

		GuiManager.Draw("supermarket_customproduction_newproduction")
		GuiManager.Draw("supermarket_customproduction_productionbox")
		GuiManager.Draw("supermarket_customproduction_castbox")
'		GuiManager.Draw("supermarket_customproduction_castbox", -1000,-1000, GUIMANAGER_TYPES_NONDRAGGED)

		'mouse cross
		'DrawRect(MouseManager.x, MouseY()-5, 1,10)
		'DrawRect(MouseManager.x-5, MouseY(), 10,1)

		GuiManager.Draw("supermarket_customproduction")
'		GuiManager.Draw("supermarket_customproduction_castbox", -1000,-1000, GUIMANAGER_TYPES_DRAGGED)
		GuiManager.Draw("supermarket_customproduction_castbox_modal")

		'draw datasheet if needed
		if hoveredGuiCastItem then hoveredGuiCastItem.DrawDatasheet(hoveredGuiCastItem.GetScreenX() - 230, hoveredGuiCastItem.GetScreenX() - 170 )


		'=== DEBUG ===
		local debugX:int = 20
		local debugY:int = 400

		SetColor 0,0,0
		SetAlpha 0.5
		DrawRect(debugX, debugY, 180, 20 + castSlotList.GetSlotAmount() * 15 + 5)
		SetColor 255,255,255
		SetAlpha 1.0
		DrawText("Cast:", debugX + 5, debugY)
		For local i:int = 0 until castSlotList.GetSlotAmount()
			if currentProductionConcept.GetCast(i)
				DrawText((i+1)+") " + currentProductionConcept.GetCast(i).GetFullName(), debugX + 5, debugY + 20 + i * 15)
			else
				DrawText((i+1)+") ", debugX + 5, debugY + 20 + i * 15)
			endif
		Next


		debugX = 220

		SetColor 0,0,0
		SetAlpha 0.5
		DrawRect(debugX, debugY, 190, 20 + currentProductionConcept.productionFocus.GetFocusAspectCount() * 15 + 5)
		SetColor 255,255,255
		SetAlpha 1.0
		DrawText("FocusPoints: " + currentProductionConcept.productionFocus.GetFocusPointsSet()+"/" + currentProductionConcept.productionFocus.GetFocusPointsMax(), debugX + 5, debugY)
		For local i:int = 0 until currentProductionConcept.productionFocus.GetFocusAspectCount()
			DrawText((i+1)+") " + currentProductionConcept.productionFocus.GetFocus( TVTProductionFocus.GetAtIndex(i+1) ), debugX + 5, debugY + 20 + i * 15)
		
			DrawText(GetLocale(TVTProductionFocus.GetAsString(i+1)), debugX + 45, debugY + 20 + i * 15)
		Next

		DrawText("Tasten:", 50,525)
		DrawText("1-5: Zufallsbesetzung #1-5   Num1-7: Focus #1-7   Num8/9: FocusPoints +/-", 50,540)
		DrawText("Q/W/E: Produktionsfirma #1-3   R: Zufallsproduktionsfirma", 50,555)
		DrawText("Leertaste: Neue Zufallsproduktion", 50,570)
 	End Method
End Type



Type TGuiShoppingListSelectListItem Extends TGuiShoppingListListItem
	Field displayName:string = ""
	Const scaleAsset:Float = 0.8
	Const paddingBottom:Int	= 2
	Const paddingTop:Int = 1


    Method Create:TGuiShoppingListSelectListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)
		SetOption(GUI_OBJECT_DRAGABLE, False)

		Self.InitAssets(GetAssetName(0, False), GetAssetName(0, True))

		'resize it
		GetDimension()

		Return Self
	End Method

rem
TODO: might be needed somewhen
	'override to add scaleAsset
	Method SetAsset(sprite:TSprite=Null, name:string = "")
		If Not sprite then sprite = Self.assetDefault
		If Not name then name = Self.assetNameDefault

			
		'only resize if not done already
		If Self.asset <> sprite or self.assetName <> name
			Self.asset = sprite
			Self.assetName = name
			Self.Resize(sprite.area.GetW() * scaleAsset, sprite.area.GetH() * scaleAsset)
		EndIf
	End Method
endrem

	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, asset.GetHeight() * scaleAsset)
		
		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method


	'override
	Method DrawContent()

		'selected
		If isSelected() and not isDragged()
			Local oldCol:TColor = new TColor.Get()
			SetColor 255,220,180

			DrawShoppingList()

			oldCol.SetRGBA()
		Else
			DrawShoppingList()
		EndIf
		
		'hovered
		If isHovered() and not isDragged()
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend

			DrawShoppingList()

			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf
	End Method


	Method DrawShoppingList()
		GetAsset().draw(Self.GetScreenX(), Self.GetScreenY(), -1, null, scaleAsset)

		local textOffsetX:int = asset.GetWidth()*scaleAsset + 3
		local title:string = "unknown script"
		local titleSize:TVec2D
		local genreColor:TColor
		if shoppingList then title = shoppingList.script.GetTitle()

		if isSelected()
			titleSize = GetBitmapFont("default",,BOLDFONT).DrawBlock(title, int(GetScreenX()+ textOffsetX), int(GetScreenY()+3), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-6,,TColor.clRed)
			genreColor = TColor.CreateGrey(100, 0.25)
		else
			if isHovered()
				titleSize = GetBitmapFont("default").DrawBlock(title, int(GetScreenX()+ textOffsetX), int(GetScreenY()+3), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-6,,TColor.CreateGrey(0))
				genreColor = TColor.CreateGrey(50, 0.25)
			else
				titleSize = GetBitmapFont("default").DrawBlock(title, int(GetScreenX()+ textOffsetX), int(GetScreenY()+3), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-6,,TColor.CreateGrey(50))
				genreColor = TColor.CreateGrey(100, 0.25)
			endif
		endif

		GetBitmapFont("default",,BOLDFONT).DrawBlock("Action-Film", int(GetScreenX()+ textOffsetX), int(GetScreenY()+3 + titleSize.y), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-6,,genreColor)
	End Method
	

End Type




Type TGUICastSlotList Extends TGUISlotList
	'contains job for each slot
	Field slotJob:int[]
	Field _eventListeners:TLink[]
	Field selectCastWindow:TGUISelectCastWindow
	'the currently clicked/selected slot for a cast selection
	Field selectCastSlot:int = -1

	
    Method Create:TGUICastSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		_eventListeners :+ [ EventManager.registerListenerMethod( "guiModalWindow.onClose", self, "onCloseSelectCastWindow", "TGUISelectCastWindow") ]
		
		return self
	End Method


	Method Remove:Int()
		EventManager.unregisterListenersByLinks(_eventListeners)
		return Super.Remove()
	End Method


	'override
	Method SetItemLimit:Int(limit:Int)
		slotJob = slotJob[.. limit + 1]

		return Super.SetItemLimit(limit)
	End Method


	Method SetSlotJob:int(jobID:int, slotIndex:int)
		if slotIndex >= slotJob.length then return False
		slotJob[slotIndex] = jobID
	End Method


	Method GetSlotJob:int(slotIndex:int)
		if slotIndex >= slotJob.length then return 0
		return slotJob[slotIndex]
	End Method


	'override
	Method EmptyList:Int()
		slotJob = new Int[0]
	
		return Super.EmptyList()
	End Method


	Method GetSlotCast:TProgrammePersonBase(slotIndex:int)
		local oldItem:TGUICastListItem = TGUICastListItem(GetItemBySlot(slotIndex))
		if not oldItem then return Null
		return oldItem.person
	End Method


	Method SetSlotCast(slotIndex:int, person:TProgrammePersonBase)
		if slotIndex < 0 or GetSlotAmount() <= slotIndex then return
		'skip if already done
		if GetSlotCast(slotIndex) = person then return

		'remove a potential gui list item
		local i:TGUICastListItem = TGUICastListItem(GetItemBySlot(slotIndex))
		if i
			if i.person = person then return
			i.remove()
			'RemoveItem(i)
		endif


		if person
			'print "SetSlotCast: AddItem " + slotIndex +"  "+person.GetFullName()
			i = new TGUICastListItem.CreateSimple(person, GetSlotJob(slotIndex) )
			'hide the name of amateurs
			if not TProgrammePerson(person) then i.isAmateur = True
			i.SetOption(GUI_OBJECT_DRAGABLE, True)
		else
			i = null
		endif

		AddItem( i, string(slotIndex) )
	End Method


	Method OpenSelectCastWindow(job:int)
		if selectCastWindow then selectCastWindow.Remove()
		
		selectCastWindow = New TGUISelectCastWindow.Create(New TVec2D.Init(250,60), New TVec2D.Init(300,270), _limitToState+"_modal")
		selectCastWindow.SetZIndex(100000)
		selectCastWindow.selectJobID = job
		selectCastWindow.listOnlyJobID = job
		selectCastWindow.Open() 'loads the cast
		GuiManager.Add(selectCastWindow)
	End Method


	Method GetJobID:int(entry:TGUIListItem)
		local slotIndex:int = getSlot(entry)
		if slotIndex = -1 then return 0
		return GetSlotJob(slotIndex)
	End Method


	'override
	'react to clicks to empty slots
	Method onClick:Int(triggerEvent:TEventBase)
		'only interested in left click
		if triggerEvent.GetData().GetInt("button") <> 1 then return False
		
		local coord:TVec2D = TVec2D(triggerEvent.GetData().Get("coord"))
		if not coord then return False

		selectCastSlot = GetSlotByCoord(coord, True)
		
		if selectCastSlot >= 0 and currentProductionConcept
			local jobID:int = currentProductionConcept.script.cast[selectCastSlot].job
			OpenSelectCastWindow(jobID)
		endif
	End Method
	
rem
	'override to refresh list item dimension
	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)

		For local i:TGUIListItem = EachIn _slots
			i.GetDimension()
		Next
	End Method
endrem

	Method Update:int()
		'window is "modal" 
		if selectCastWindow
'			selectCastWindow.Update()
			if selectCastWindow.IsClosed()
				GuiManager.Remove(selectCastWindow)
				selectCastWindow = null
			endif
		else
			Super.Update()
		endif
	End Method


	'override to draw unused slots
	Method DrawContent()
		Super.DrawContent()

		SetAlpha 0.4 * GetAlpha()
		For local slot:int = 0 until _slots.length
			if _slots[slot] then continue
			if slotJob.length < slot then continue
			
			local coord:TVec3D = GetSlotCoord(slot)

			TGUICastListItem.DrawCast(GetScreenX() + coord.GetX(), GetScreenY() + coord.GetY(), GetContentScreenWidth(), GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(GetSlotJob(slot))), "Klicken um Person auszuwählen", null, 0,0,0)
		Next
		SetAlpha 2.5 * GetAlpha()

'		if selectCastWindow then selectCastWindow.Draw()
	End Method



	Method onCloseSelectCastWindow:int( triggerEvent:TEventBase )
		local closeButton:int = triggerEvent.GetData().GetInt("closeButton", -1)
		if closeButton <> 1 then return False

		local person:TProgrammePersonBase = selectCastWindow.GetSelectedPerson()
		'todo: entfernen der bereits ausgewaehlten Personen aus Liste,
		'      WENN gleicher Beruf des "Slots" (Regisseur + Schauspieler
		'      ist ja moeglich

		if person
			SetSlotCast(selectCastSlot, person)
		endif
	End Method
	

	'override default event handler
	Function onDropOnTarget:int( triggerEvent:TEventBase )
		'adjust cast slots...
		if Super.onDropOnTarget( triggerEvent )
			local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
			if not item then return False

			local list:TGUICastSlotList = TGUICastSlotList(triggerEvent.GetReceiver())
			if not list then return False

			local slotNumber:int = list.getSlot(item)

			list.SetSlotCast(slotNumber, item.person)
		endif

		return TRUE
	End Function
End Type




Type TGUICastSelectList extends TGUISelectList
	'the job the selection list is used for 
	Field selectJobID:int = -1
	'the job the selection is currently filtered for
	Field filteredJobID:int = -1
	Field _eventListeners:TLink[]
	
    Method Create:TGUICastSelectList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		return self
	End Method


	Method Remove:Int()
		EventManager.unregisterListenersByLinks(_eventListeners)
		return Super.Remove()
	End Method


	Method GetJobID:int(entry:TGUIListItem)
		return selectJobID
	End Method
End Type




Type TGUICastListItem Extends TGUISelectListItem
	Field person:TProgrammePersonBase
	Field displayName:string = ""
	Field isAmateur:int = False
	'the job this list item is "used for"
	Field displayJobID:int = -1
	Field lastDisplayJobID:int = -1

	Const paddingBottom:Int	= 3
	Const paddingTop:Int = 2


	Method CreateSimple:TGUICastListItem(person:TProgrammePersonBase, displayJobID:int)
		'make it "unique" enough
		Self.Create(Null, Null, person.GetFullName())

		self.displayName = person.GetFullName()
		self.person = person
		self.isAmateur = False

		self.displayJobID = -1
		self.lastDisplayJobID = displayJobID

		'resize it
		GetDimension()

		Return Self
	End Method


    Method Create:TGUICastListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		'SetLifetime(30000) '30 seconds
		'SetValue(":D")
		SetValueColor(TColor.Create(0,0,0))
		
		GUIManager.add(Self)

		Return Self
	End Method



	'override
	Method onFinishDrag:int(triggerEvent:TEventBase)
		if Super.OnFinishDrag(triggerEvent)
			'invalidate displayJobID
			'print "invalidate jobID"
			displayJobID = -1
			return true
		else
			return false
		endif
	End Method


	'override
	Method onFinishDrop:int(triggerEvent:TEventBase)
		if Super.OnFinishDrop(triggerEvent)
			'refresh displayJobID
			'print "refresh jobID"
			displayJobID = -1
			GetDisplayJobID()
			return true
		else
			return false
		endif
	End Method


	Method GetDisplayJobID:int()
		'refresh displayJobID
		if displayJobID = -1
			local parentList:TGUIListBase = TGUIListBase.FindGUIListBaseParent(self._parent)

			'dragged ()items use their backup or the underlaying slot list
			If (Self._flags & GUI_OBJECT_DRAGGED)
				'only check items from the slot lists, not the select ones
				if TGUICastSlotList(parentList)
					local slotListSlot:int = RoomHandler_Supermarket.GetInstance().castSlotList.GetSlotByCoord( MouseManager.GetPosition() )
					if slotListSlot >= 0 then return TGUICastSlotList(parentList).GetSlotJob(slotListSlot)
				endif

				return lastDisplayJobID
			endif


			if TGUICastSelectList(parentList)
				'displayJobID = TGUICastSelectList(parentList).GetJobID(self)
				displayJobID = TGUICastSelectList(parentList).filteredJobID
			elseif TGUICastSlotList(parentList)
				displayJobID = TGUICastSlotList(parentList).GetJobID(self)
				'print "slot: displayJobID = "+displayJobID
			else
				'print "unknown: displayJobID = "+displayJobID
			endif
		endif

		return displayJobID
	End Method


	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, GetSpriteFromRegistry("gfx_datasheet_cast_icon").GetHeight())
		
		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
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
		local xpPercentage:float = 0.0
		if TProgrammePerson(person) then xpPercentage = TProgrammePerson(person).GetExperiencePercentage( GetDisplayJobID() )

		local name:string = displayName
		if isAmateur and not isDragged()
			name = GetLocale("JOB_AMATEUR_" + TVTProgrammePersonJob.GetAsString( GetDisplayJobID() ))
			displayName = name
		endif
		DrawCast(GetScreenX(), GetScreenY(), GetScreenWidth(), name, "", null, xpPercentage, 0, 1)

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawCast(GetScreenX(), GetScreenY(), GetScreenWidth(), name, "", null, xpPercentage, 0, 1)

			SetBlend AlphaBlend
			SetAlpha 10.0 * GetAlpha()
		EndIf
	End Method


	Method DrawContent()
		if isSelected()
			SetColor 245,230,220
			Super.DrawContent()

			SetColor 220,210,190
			SetAlpha GetAlpha() * 0.10
			SetBlend LightBlend
			Super.DrawContent()
			SetBlend AlphaBlend
			SetAlpha GetAlpha() * 10

			SetColor 255,255,255
		else
			Super.DrawContent()
		endif
	End Method


	Method DrawDatasheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= leftX
		Local sheetAlign:Int= 0
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		local sheetCenterX:Float = sheetX
		if sheetAlign = 0
			sheetCenterX :+ 250/2 '250 is sheetWidth
		else
			sheetCenterX :- 250/2 '250 is sheetWidth
		endif
		Local tri:Float[]=[sheetCenterX,sheetY+25, sheetCenterX,sheetY+90, getScreenX() + getScreenWidth()/2.0, getScreenY() + GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		if TProgrammePerson(person)
			ShowCastSheet(person, GetDisplayJobID(), sheetX, sheetY, sheetAlign, FALSE)
		else
			'hide person name etc for non-celebs
			ShowCastSheet(person, GetDisplayJobID(), sheetX, sheetY, sheetAlign, TRUE)
		endif
	End Method


	Function DrawCast(x:int, y:int, w:int, name:string, nameHint:string="", face:TSprite=null, xp:float, sympathy:float, mood:int)
		'Draw name bg
		'Draw xp bg + front bar
		'Draw sympathy bg + front bar
		'draw mood icon
		'draw Pic overlay
		'render text

		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")
		local nameSprite:TSprite = GetSpriteFromRegistry("gfx_datasheet_cast_name")
		local iconSprite:TSprite = GetSpriteFromRegistry("gfx_datasheet_cast_icon")

		local nameOffsetX:int = 34, nameOffsetY:int = 3
		local nameTextOffsetX:int = 38
		local barOffsetX:int = 34, barOffsetY:int = nameOffsetY + nameSprite.GetHeight()
		local barH:int = skin.GetBarSize(100,-1, "cast_bar_xp").GetY()
		
		'=== NAME ===
		'face/icon-area covers 36px + shadow, place bar a bit "below"
		nameSprite.DrawArea(x + nameOffsetX, y + nameOffsetY, w - nameOffsetX, nameSprite.GetHeight())

		'=== BARS ===
		skin.RenderBar(x + nameOffsetX, y + barOffsetY, 200, -1, xp, -1.0, "cast_bar_xp")
		skin.RenderBar(x + nameOffsetX, y + barOffsetY + barH, 200, -1, sympathy, -1.0, "cast_bar_sympathy")

		'=== FACE / ICON ===
		iconSprite.Draw(x, y)

		'maybe "TProgrammePersonBase.GetFace()" ?
		if face then face.Draw(x, y)

		if name or nameHint
			local border:TRectangle = nameSprite.GetNinePatchContentBorder()

			if name
				skin.fontSemiBold.drawBlock( ..
					name, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop(), .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(15, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif

			if nameHint
				skin.fontNormal.drawBlock( ..
					nameHint, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop(), .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(15, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					ALIGN_RIGHT_CENTER, skin.textColorNeutral)
			endif
		endif
	End Function	
End Type






Function ShowCastSheet:Int(cast:TProgrammePersonBase, jobID:int=-1, x:Int,y:Int, align:int=0, showAmateurInformation:int = False)
	'=== PREPARE VARIABLES ===
	local sheetWidth:int = 250
	local sheetHeight:int = 0 'calculated later
	'move sheet to left when right-aligned
	if align = 1 then x = x - sheetWidth

	local skin:TDatasheetSkin = GetDatasheetSkin("cast")
	local contentW:int = skin.GetContentW(sheetWidth)
	local contentX:int = x + skin.GetContentY()
	local contentY:int = y + skin.GetContentY()

	local celebrity:TProgrammePerson = TProgrammePerson(cast)


	'=== CALCULATE SPECIAL AREA HEIGHTS ===
	local titleH:int = 18, jobDescriptionH:int = 16, lifeDataH:int = 15, lastProductionEntryH:int = 15, lastProductionsH:int = 50
	local splitterHorizontalH:int = 6
	local boxH:int = 0, barH:int = 0
	local boxAreaH:int = 0, barAreaH:int = 0, msgAreaH:int = 0
	local boxAreaPaddingY:int = 4, barAreaPaddingY:int = 4

	if showAmateurInformation
		jobDescriptionH = 0
		lifeDataH = 0
		lastProductionsH = 0

		'bereich fuer hinweis einfuehren -- dass  es sich um einen
		'non-celeb handelt der "Erfahrung" sammelt
	endif

	boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
	barH = skin.GetBarSize(100, -1).GetY()
	titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(cast.GetFullName(), contentW - 10, 100))

	'bar area starts with padding, ends with padding and contains
	'also contains 8 bars
	if celebrity and not showAmateurInformation
		barAreaH = 2 * barAreaPaddingY + 7 * (barH + 2)
	endif
	
	'box area
	'contains 1 line of boxes + padding at the top
	boxAreaH = 1 * boxH + 1 * boxAreaPaddingY

	'total height
	sheetHeight = titleH + jobDescriptionH + lifeDataH + lastProductionsH + barAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


	'=== RENDER ===

	'=== TITLE AREA ===
	skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		local title:string = cast.GetFullName()
		if showAmateurInformation
			title = GetLocale("JOB_AMATEUR")
		endif
		
		if titleH <= 18
			GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		else
			GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
	contentY :+ titleH


	if not showAmateurInformation	
		'=== JOB DESCRIPTION AREA ===
		if jobDescriptionH > 0
			skin.RenderContent(contentX, contentY, contentW, jobDescriptionH, "1")

			local firstJobID:int = -1
			for local jobIndex:int = 1 to TVTProgrammePersonJob.Count 
				if not cast.HasJob(jobIndex) then continue

				firstJobID = jobIndex
				exit
			next

			local genre:int = cast.GetTopGenre()
			local genreText:string = ""
			if genre >= 0 then genreText = GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(genre))
			if genreText then genreText = "~q" + genreText+"~q-"

			if firstJobID >= 0
				'add genre if you know the job
				skin.fontNormal.drawBlock(genreText + GetLocale("JOB_"+TVTProgrammePersonJob.GetAsString(firstJobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				'use the given jobID but declare as amateur
				skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR_"+TVTProgrammePersonJob.GetAsString(jobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif

			contentY :+ jobDescriptionH
		endif


		'=== LIFE DATA AREA ===
		skin.RenderContent(contentX, contentY, contentW, lifeDataH, "1")
		'splitter
		GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + 165, contentY, 2, jobDescriptionH)
		local latinCross:string = Chr(10013) '† = &#10013 ---NOT--- &#8224; (the dagger-cross)
		if celebrity
			local dob:String = GetWorldTime().GetFormattedDate( GetWorldTime().GetTimeGoneFromString(celebrity.dayOfBirth), "d.m.y")
			skin.fontNormal.drawBlock(dob +" ("+celebrity.GetAge()+" J.)", contentX + 5, contentY, 165 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			skin.fontNormal.drawBlock(celebrity.countryCode, contentX + 170 + 5, contentY, contentW - 170 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		endif
		contentY :+ lifeDataH


		'=== LAST PRODUCTIONS AREA ===
		skin.RenderContent(contentX, contentY, contentW, lastProductionsH, "2")

		contentY :+ 3
		if celebrity
			'last productions
			if celebrity.GetProducedProgrammes().length > 0
				local productionGUIDs:string[] = celebrity.GetProducedProgrammes()
				local i:int = 0
				local entryNum:int = 0
				while i < productionGUIDs.length and entryNum < 3
					local production:TProgrammeData = GetProgrammeDataCollection().GetByGUID( productionGUIDs[ i] )
					i :+ 1
					if not production then continue

					skin.fontSemiBold.drawBlock(production.GetYear(), contentX + 5, contentY + lastProductionEntryH*entryNum, contentW, lastProductionEntryH, null, skin.textColorNeutral)
					if production.IsInProduction()
						skin.fontNormal.drawBlock(production.GetTitle() + " (In Produktion)", contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, null, skin.textColorNeutral)
					else
						skin.fontNormal.drawBlock(production.GetTitle(), contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, null, skin.textColorNeutral)
					endif
					entryNum :+1
				Wend
			endif
		endif
		contentY :+ lastProductionsH - 3
	endif

	'=== BARS / BOXES AREA ===
	'background for bars + boxes
	if barAreaH + boxAreaH > 0
		skin.RenderContent(contentX, contentY, contentW, barAreaH + boxAreaH, "1_bottom")
	endif


	'===== DRAW CHARACTERISTICS / BARS =====
	'TODO: only show specific data of a cast, "all" should not be
	'      exposed until we eg. produce specific "insight"-shows ?
	'      -> or have some "agent" to pay to get such information

	if celebrity
		'bars have a top-padding
		contentY :+ barAreaPaddingY
		'XP
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetExperiencePercentage(jobID))
		skin.fontSemiBold.drawBlock(GetLocale("CAST_EXPERIENCE"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'Fame
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetFame())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_FAME"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'Skill
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetSkill())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_SKILL"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'Power
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetPower())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_POWER"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'Humor
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetHumor())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_HUMOR"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'Charisma
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetCharisma())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_CHARISMA"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
		'Appearance
		skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetAppearance())
		skin.fontSemiBold.drawBlock(GetLocale("CAST_APPEARANCE"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
		contentY :+ barH + 2
	endif
'hidden?
rem
	'Scandalizing
	skin.RenderBar(contentX + 5, contentY, 100, 12, cast.GetScandalizing())
	skin.fontSemiBold.drawBlock(GetLocale("CAST_SCANDALIZING"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
	contentY :+ barH + 2
endrem

	'=== MESSAGES ===
	'TODO: any chances of "not available from day x-y of 1998"

	'=== BOXES ===
	'boxes have a top-padding (except with messages)
	if msgAreaH = 0 then contentY :+ boxAreaPaddingY

	if celebrity
		contentY :+ boxAreaPaddingY
	endif
	if jobID >= 0
		skin.fontSemibold.drawBlock(GetLocale("JOB_"+TVTProgrammePersonJob.GetAsString(jobID)), contentX + 5, contentY, 94, 25, ALIGN_LEFT_CENTER, skin.textColorLabel)
		skin.RenderBox(contentX + 5 + 94, contentY, contentW - 10 - 94 +1, -1, TFunctions.DottedValue(cast.GetBaseFee(jobID, currentProductionConcept.script.blocks)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
	endif
	contentY :+ boxH


	'=== OVERLAY / BORDER ===
	skin.RenderBorder(x, y, sheetWidth, sheetHeight)
End Function



Type TGUISelectCastWindow extends TGUIModalWindow
	Field jobFilterSelect:TGUIDropDown
	Field buttonOK:TGUIButton
	Field buttonCancel:TGUIButton
	Field _eventListeners:TLink[]
	'only list persons with the following job?
	Field listOnlyJobID:int = -1
	'select a person for the following job (for correct fee display)
	Field selectJobID:int = 0
	Field castSelectList:TGUICastSelectList
	

	'override
	Method Create:TGUISelectCastWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		darkenedAreaAlpha = 0.25 '0.5 is default

		jobFilterSelect = new TGUIDropDown.Create(new TVec2D.Init(15,12), new TVec2D.Init(180,-1), "Hauptberuf", 128, "")
		jobFilterSelect.SetZIndex( GetZIndex() + 1)
		'add some items to that list
		for local i:int = 0 to TVTProgrammePersonJob.count
			local item:TGUIDropDownItem = new TGUIDropDownItem.Create(null, null, "") 
			if i = 0
				item.SetValue(GETLOCALE("JOB_ALL"))
				item.data.AddNumber("jobIndex", 0)
			else
				item.SetValue(GETLOCALE("JOB_" + TVTProgrammePersonJob.GetAsString( TVTProgrammePersonJob.GetAtIndex(i) )))
				item.data.AddNumber("jobIndex", i)
			endif
			jobFilterSelect.AddItem(item)
		Next

		castSelectList = new TGUICastSelectList.Create(new TVec2D.Init(15,50), new TVec2D.Init(270, dimension.y - 103), "")



		buttonOK = new TGUIButton.Create(new TVec2D.Init(10, dimension.GetY() - 44), new TVec2D.Init(136, 28), "Person auswählen", "")
		buttonOK.spriteName = "gfx_gui_button.datasheet"
		buttonCancel = new TGUIButton.Create(new TVec2D.Init(dimension.GetX() - 15 - 136, dimension.GetY() - 44), new TVec2D.Init(136, 28), "Abbrechen", "")
		buttonCancel.spriteName = "gfx_gui_button.datasheet"

		AddChild(jobFilterSelect)
		AddChild(castSelectList)
		AddChild(buttonOK)
		AddChild(buttonCancel)


		_eventListeners :+ [ EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", self, "onCastChangeJobFilterDropdown", "TGUIDropDown" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod("guiobject.OnDoubleClick", self, "onDoubleClickCastListItem", "TGUICastListItem" ) ]


		Return self
	End Method


	Method Remove:Int()
		EventManager.unregisterListenersByLinks(_eventListeners)
		return Super.Remove()
	End Method


	'GUI->GUI
	'close window with "OK" (shortcut to "select + OK")
	Method onDoubleClickCastListItem:int( triggerEvent:TEventBase )
		local item:TGUICastListItem = TGUICastListItem(triggerEvent.GetSender())
		if item = Null then return False
		'skip if from another list
		if TGUIListBase.FindGUIListBaseParent(item) <> castSelectList then return False

		Close(1)

		return TRUE
	End Method
	

	'GUI -> GUI
	'set cast filter according to selection
	Method onCastChangeJobFilterDropdown:int(triggerEvent:TeventBase)
		local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		if dropdown <> jobFilterSelect then return False

		local entry:TGUIDropDownItem = TGUIDropDownItem(dropdown.GetSelectedEntry())
		if not entry or not entry.data then return False

		local jobIndex:int = entry.data.GetInt("jobIndex")

		LoadPersons(TVTProgrammePersonJob.GetAtIndex(jobIndex))
	End Method



	Method GetSelectedPerson:TProgrammePersonBase()
		local item:TGUICastListItem = TGUICastListItem(castSelectList.getSelectedEntry())
		if not item or not item.person then return Null

		return item.person
	End Method


	'override to skip animation
	Method IsClosed:int()
		return closeActionStarted
	End Method


	'override to _not_ recenter
	Method Recenter:Int(moveBy:TVec2D=Null)
		return True
	End Method


	Method SetJobFilterSelectEntry:int(jobIndex:int)
		'adjust dropdown to use the correct entry
		'skip without changes
		local newItem:TGUIDropDownItem
		For local i:TGUIDropDownItem = EachIn jobFilterSelect.GetEntries()
			if not i.data or i.data.GetInt("jobIndex", -2) <> jobIndex then continue

			newItem = i
			exit
		Next
		if newItem = jobFilterSelect.GetSelectedEntry() then return False

		jobFilterSelect.SetSelectedEntry(newItem)
		return True
	End Method
	

	'override to fill with content on open
	Method Open:Int()
		Super.Open()


		'adjust gui dropdown
		local jobIndex:int = TVTProgrammePersonJob.GetIndex(listOnlyJobID)
		if listOnlyJobID = -1 then jobIndex = -1
		SetJobFilterSelectEntry(jobIndex)

	
		LoadPersons(listOnlyJobID)
		
		'refresh scrolling state
'		castSelectList.Resize(-1, 150)
	End Method


	Method LoadPersons(filterToJobID:int)
		'skip if no change is needed
		if castSelectList.filteredJobID = filterToJobID then return
		'print "LoadPersons: filter=" + filterToJobID

		castSelectList.EmptyList()
		
		'add persons to that list
		local persons:TProgrammePersonBase[] = GetProgrammePersonBaseCollection().GetAllCelebritiesAsArray(True)
		if filterToJobID > 0
			local filteredPersons:TProgrammePersonBase[]
			For local person:TProgrammePersonBase = EachIn persons
				if person.HasJob(filterToJobID)
					filteredPersons :+ [person]
				endif	
			Next
			persons = filteredPersons
		endif

		'sort by name (rely on "TProgrammePersonBase.Compare()")
		persons.Sort(true)

		'add an amateur/layman at the top (hidden behind is a random
		'normal person)
		local amateur:TProgrammePersonBase
		Repeat
			amateur = GetProgrammePersonBaseCollection().GetRandomInsignificant(null, True)
			'print "check " + amateur.GetFullName() + "  " + amateur.GetAge() +"  fictional:"+amateur.fictional
			'if not amateur.IsAlive() then print "skip: dead "+amateur.GetFullName()
			'if not (amateur.GetAge() >= 10) then print "skip: too young "+amateur.GetFullName()
			'if not amateur.fictional then print "skip: real "+amateur.GetFullName()
		Until amateur.IsAlive() and amateur.fictional

		persons = [amateur] + persons

		'disable list-sort
		castSelectList.SetAutosortItems(False)

		For local p:TProgrammePersonBase = EachIn persons
			'custom production not possible with real persons...
			if not p.fictional then continue
			if not p.IsAlive() then continue
			'we also want to avoid "children" (only available for celebs
			if TProgrammePerson(p) and p.GetAge() < 10 then continue
			
			'base items do not have a size - so we have to give a manual one
			local item:TGUICastListItem = new TGUICastListItem.CreateSimple( p, selectJobID )
			if p = amateur
				item.displayName = GetLocale("JOB_AMATEUR_" + TVTProgrammePersonJob.GetAsString(selectJobID))
				item.isAmateur = True
			endif
			item.Resize(180,40)
			castSelectList.AddItem( item )
		Next

		'adjust which desired job the list is selecting
		castSelectList.selectJobID = selectJobID
		'adjust which filter we are using
		castSelectList.filteredJobID = filterToJobID
	End Method


	Method Update:int()
		if buttonCancel.IsClicked() then Close(2)
		if buttonOK.IsClicked() then Close(1)

		return super.Update()
	End Method	


	Method DrawBackground()
		Super.DrawBackground()

		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		local outer:TRectangle = GetScreenRect().Copy() ')new TRectangle.Init(GetScreenX(), GetScreenY(), 200, 200)
		local contentX:int = skin.GetContentX(outer.GetX())
		local contentY:int = skin.GetContentY(outer.GetY())
		local contentW:int = skin.GetContentW(outer.GetW())
		local contentH:int = skin.GetContentH(outer.GetH())

		skin.RenderContent(contentX, contentY, contentW, 38, "1_top")
		skin.RenderContent(contentX, contentY+38, contentW, contentH-73, "1")
		skin.RenderContent(contentX, contentY+contentH-35, contentW, 35, "1_bottom")
		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())

	End Method
	

	Method DrawContent()
		Super.DrawContent()
	End Method
End Type