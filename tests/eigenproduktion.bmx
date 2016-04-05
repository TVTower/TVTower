SuperStrict

Framework brl.StandardIO

Import "../source/Dig/base.framework.graphicalapp.bmx"
Import "../source/Dig/base.gfx.bitmapfont.bmx"
Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.util.registry.imageloader.bmx"
Import "../source/Dig/base.util.registry.bitmapfontloader.bmx"

Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.gfx.gui.dropdown.bmx"
Import "../source/Dig/base.gfx.gui.checkbox.bmx"
Import "../source/Dig/base.gfx.gui.slider.bmx"
Import "../source/Dig/base.gfx.gui.button.bmx"
Import "../source/Dig/base.gfx.gui.list.slotlist.bmx"
Import "../source/Dig/base.gfx.gui.window.modal.bmx"


Import "../source/game.database.bmx"
Import "../source/game.player.base.bmx"
Import "../source/game.registry.loaders.bmx" 'genres

Import "../source/game.production.productionconcept.bmx"
Import "../source/game.production.productioncompany.bmx"
Import "../source/game.production.productionconcept.gui.bmx"
Import "../source/game.production.productionmanager.bmx"



Global MyApp:TMyApp = New TMyApp
MyApp.debugLevel = 1

Type TMyApp Extends TGraphicalApp
	Field mouseCursorState:Int = 0
	Field dbLoader:TDatabaseLoader
	Field bg:TImage
	Field screen:TTestScreen

	Method Prepare:Int()
		Super.Prepare()

		'set worldTime to 20:00, day 3 of 12 a year, in 1985
		GetWorldTime().SetTimeGone( GetWorldTime().MakeTime(1985, 3, 20, 0, 0) )
		'set speed 10x realtime
		GetWorldTime().SetTimeFactor(120)


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

		'load stationmap
		GetStationMapCollection().LoadMapFromXML("res/maps/germany/germany.xml", registryLoader.baseURI)

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
		'local script:TScript = GetScriptCollection().GetRandomAvailable()
		'script.SetOwner(1)

		'create some companies
		local cnames:string[] = ["Movie World", "Picture Fantasy", "UniPics", "Motion Gems", "Screen Jewel"]
		For local i:int = 0 until cnames.length
			local c:TProductionCompany = new TProductionCompany
			c.name = cnames[i]
			c.SetExperience( BiasedRandRange(0, 0.35 * TProductionCompanyBase.MAX_XP, 0.25) )
			GetProductionCompanyBaseCollection().Add(c)
		Next

		RoomHandler_Supermarket.GetInstance().Initialize()
		'local productionConcept:TProductionConcept = new TProductionConcept.Initialize(1, GetRandomScript())
		'RoomHandler_Supermarket.GetInstance().SetProductionConcept( productionConcept )


		'debug
		local p:TProgrammePersonBase[] = GetProgrammePersonBaseCollection().GetAllInsignificantAsArray()
		for local i:int = 0 until p.length
			if TProgrammePerson(p[i]) then print "failed: "+i+"   " + p[i].GetGUID() 
		next
	End Method


	Function GetRandomScript:TScript()
		'get a new script
		local script:TScript = GetScriptCollection().GetRandomAvailable()

		'use first episode of a series
		if script.isSeries()
			script = GetScriptCollection().GetByGUID( script.GetSubScriptAtIndex(0).GetGUID() )
		endif

		return script
	End Function


	Method Update:Int()
		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()

		'update worldtime (eg. in games this is the ingametime)
		GetWorldTime().Update()
		
		GetProductionManager().Update()

		'=== UPDATE GUI ===
		'system wide gui elements
		GuiManager.Update("SYSTEM")

		'run parental update (screen handling)
		Super.Update()


		if MouseManager.IsClicked(2)
			RoomHandler_Supermarket.GetInstance().SetCurrentProductionConcept(null)
			MouseManager.ResetKey(2)
		endif

		if not GuiManager.GetKeystrokeReceiver()
			if KeyManager.IsHit(KEY_SPACE)
				'get a new script
				local script:TScript = GetRandomScript()
				script.SetOwner(1)
				local productionConcept:TProductionConcept = new TProductionConcept.Initialize(1, script)
				'create new and take over
				RoomHandler_Supermarket.GetInstance().SetCurrentProductionConcept( productionConcept, RoomHandler_Supermarket.GetInstance().currentProductionConcept)
			endif

			if RoomHandler_Supermarket.GetInstance().currentProductionConcept
				if KeyManager.IsHit(KEY_1)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetCast(0, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
				Endif
				if KeyManager.IsHit(KEY_2)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetCast(1, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
				Endif
				if KeyManager.IsHit(KEY_3)
					RoomHandler_Supermarket.GetInstance().castSlotList.SetSlotCast(2, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True) )
					'currentProductionConcept.SetCast(2, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
				Endif
				if KeyManager.IsHit(KEY_4)
					RoomHandler_Supermarket.GetInstance().castSlotList.SetSlotCast(3, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True) )
				Endif
				if KeyManager.IsHit(KEY_5)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetCast(4, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
				Endif

				if KeyManager.IsHit(KEY_Q)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionCompany( TProductionCompanyBase(RoomHandler_Supermarket.GetInstance().productionCompanySelect.GetEntryByPos(0).data.Get("productionCompany")) )
				Endif
				if KeyManager.IsHit(KEY_W)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionCompany( TProductionCompanyBase(RoomHandler_Supermarket.GetInstance().productionCompanySelect.GetEntryByPos(1).data.Get("productionCompany")) )
				Endif
				if KeyManager.IsHit(KEY_E)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionCompany( TProductionCompanyBase(RoomHandler_Supermarket.GetInstance().productionCompanySelect.GetEntryByPos(2).data.Get("productionCompany")) )
				Endif
				if KeyManager.IsHit(KEY_R)
					'random one
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionCompany( GetProductionCompanyBaseCollection().GetRandom() )
				Endif

				if KeyManager.IsHit(KEY_NUM1)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(1, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM2)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(2, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM3)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(3, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM4)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(4, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM5)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(5, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM6)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(6, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM7)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(7, RandRange(0,10))
				Endif
				if KeyManager.IsHit(KEY_NUM8)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.productionFocus.SetFocusPointsMax( Max(0, RoomHandler_Supermarket.GetInstance().currentProductionConcept.productionFocus.focusPointsMax - 1))
				Endif
				if KeyManager.IsHit(KEY_NUM9)
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.productionFocus.SetFocusPointsMax( RoomHandler_Supermarket.GetInstance().currentProductionConcept.productionFocus.focusPointsMax + 1)
				Endif

				if KeyManager.IsHit(KEY_P)
					if RoomHandler_Supermarket.GetInstance().currentProductionConcept.IsProduceable()
						local count:int = GetProductionManager().StartProductionInStudio("test", RoomHandler_Supermarket.GetInstance().currentProductionConcept.script)
						print "added "+count+" productions to shoot"
					else
						print RoomHandler_Supermarket.GetInstance().currentProductionConcept.GetTitle()+"  not ready"
					endif
				endif
			endif
		

			'create demo production
			if KeyManager.IsHit(KEY_O)
				if not RoomHandler_Supermarket.GetInstance().currentProductionConcept
					local productionConcept:TProductionConcept = GetProductionConceptCollection().GetRandom()
					'create new and take over
					RoomHandler_Supermarket.GetInstance().SetCurrentProductionConcept( productionConcept, RoomHandler_Supermarket.GetInstance().currentProductionConcept)
				endif
				
				'random company
				RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionCompany( GetProductionCompanyBaseCollection().GetRandom() )

				For local i:int = 0 until RoomHandler_Supermarket.GetInstance().currentProductionConcept.cast.length
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetCast(i, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
				Next
				For local i:int = 0 until RoomHandler_Supermarket.GetInstance().currentProductionConcept.productionFocus.focusPoints.length
					RoomHandler_Supermarket.GetInstance().currentProductionConcept.SetProductionFocus(i, RandRange(0,10))
				Next

				'pay for it
				RoomHandler_Supermarket.GetInstance().PayCurrentProductionConceptDeposit()
				
				if RoomHandler_Supermarket.GetInstance().currentProductionConcept.IsProduceable()
					local count:int = GetProductionManager().StartProductionInStudio("test", RoomHandler_Supermarket.GetInstance().currentProductionConcept.script)

					local production:TProduction = GetProductionManager().GetProductionInStudio("test")
					if production
						'1 minute production time
						production.endDate = production.startDate + 60*1
					endif

					print "added "+count+" productions to shoot"
				else
					print RoomHandler_Supermarket.GetInstance().currentProductionConcept.GetTitle()+"  not ready"
				endif
			endif
			if KeyManager.IsHit(KEY_UP)
				GetWorldTime().SetTimeFactor( 2 * GetWorldTime().GetTimeFactor())
				print "factor: "+GetWorldTime().GetTimeFactor()
			endif
			if KeyManager.IsHit(KEY_DOWN)
				GetWorldTime().SetTimeFactor( Max(10, 0.5 * GetWorldTime().GetTimeFactor()))
				print "factor: "+GetWorldTime().GetTimeFactor()
			endif
		endif

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


		DrawText("worldTime: "+GetWorldTime().GetFormattedTime(-1, "h:i:s")+ " at day "+GetWorldTime().GetDayOfYear()+" in "+GetWorldTime().GetYear(), 90, 0)


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
	Field editTextsButton:TGUIButton
	Field editTextsWindow:TGUIEditTextsModalWindow
	Field finishProductionConcept:TGUIButton
	Field productionConceptList:TGUISelectList
	Field productionConceptTakeOver:TGUICheckbox
	Field productionCompanySelect:TGUIDropDown
	Field castSlotList:TGUICastSlotList
	Field repositionSliders:int = True
	'set to true and production GUI changes wont affect logic
	Field refreshingProductionGUI:int = False
	Field refreshFinishProductionConcept:int = True

	Field currentProductionConcept:TProductionConcept

	Global hoveredGuiCastItem:TGUICastListItem
	Global hoveredGuiProductionConcept:TGuiProductionConceptListItem

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
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickEditTextsButton, "TGUIButton") ]
		'we want to know if we hover a specific block
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverCastItem, "TGUICastListItem" ) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverProductionConceptItem, "TGuiProductionConceptListItem" ) ]



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
		'select a production concept
		_eventListeners :+ [ EventManager.registerListenerFunction("GUISelectList.onSelectEntry", onSelectProductionConcept) ]
		'edit title/description
		_eventListeners :+ [ EventManager.registerListenerFunction("guiModalWindow.onClose", onCloseEditTextsWindow, "TGUIEditTextsModalWindow") ]


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


	'reset gui elements to their initial state (new production)
	Method ResetProductionConceptGUI()
		refreshingProductionGUI = True

		For local i:int = 0 to productionFocusSlider.length -1
			productionFocusSlider[i].SetValue(0)
		Next

		productionCompanySelect.SetValue("Produktionsfirma")

		'cast: remove old entries
		castSlotList.EmptyList()

		'reselect currently selected production concept
		local selectedGuiConcept:TGuiProductionConceptSelectListItem = TGuiProductionConceptSelectListItem(productionConceptList.GetSelectedEntry())
		if selectedGuiConcept and selectedGuiConcept.productionConcept <> currentProductionConcept
			productionConceptList.DeselectEntry()
		endif

		refreshingProductionGUI = False
	End Method
	

	'set all gui elements to the values of the production concept
	Method RefreshProductionConceptGUI()
		if not currentProductionConcept then return
	

		'=== CAST SLOT LIST ===
		castSlotList.SetItemLimit( currentProductionConcept.script.cast.length )
		For local i:int = 0 until currentProductionConcept.script.cast.length
			castSlotList.SetSlotJob(currentProductionConcept.script.cast[i].job, i)
			'also create gui
			castSlotList.SetSlotCast(i, currentProductionConcept.cast[i])
		Next
		

		'=== PRODUCTION COMPANY ===
		local productionCompanyItem:TGUIDropDownItem
		For local i:TGUIDropDownItem = EachIn productionCompanySelect.GetEntries()
			if not i.data or i.data.Get("productionCompany") <> currentProductionConcept.productionCompany then continue

			productionCompanyItem = i
			exit
		Next
		'adjust gui dropdown
		if productionCompanyItem then productionCompanySelect.SetSelectedEntry(productionCompanyItem)


		'=== PRODUCTION FOCUS ITEMS ===
		'hide sliders according to focuspoint type of script
		'(this is _different_ to the "disable" action done in
		' UpdateCustomProduction())
		For local i:int = 0 to productionFocusSlider.length -1
			productionFocusSlider[i].Hide()
		Next
		'enable used ones...
		For local i:int = 0 to productionFocusSlider.length -1
			if currentProductionConcept.productionFocus.GetFocusAspectCount() > i
				productionFocusSlider[i].Show()
			endif
		Next
		'reposition them
		repositionSliders = True
	End Method


	Method PayCurrentProductionConceptDeposit:int()
		if not currentProductionConcept then return False
		'already paid ?
		if currentProductionConcept.IsDepositPaid() then return False

		print "TODO: connect to player finance"
		if currentProductionConcept.PayDeposit() then return True

		return False
	End Method
	

	Method SetCurrentProductionConcept(productionConcept:TProductionConcept = null, takeOverConcept:TProductionConcept = null)
		currentProductionConcept = productionConcept
		'use values of the new concept if nothing defined to take over
		if not takeOverConcept then takeOverConcept = productionConcept

		
		ResetProductionConceptGUI()

		'=== TAKE OVER OLD CONCEPT VALUES ===
		if currentProductionConcept
			'=== CAST ===
			'loop over all jobs and try to take over as much of them as
			'possible.
			'So if there are 3 actors in the old concept but only 2 in the
			'new one, 2 of 3 actors are taken over
			'Cast not available in the new one, is ignored
			local currentCastIndex:int = 0
			for local jobIndex:int = 1 to TVTProgrammePersonJob.Count
				local jobID:int = TVTProgrammePersonJob.GetAtIndex(jobIndex)
				local castGroup:TProgrammePersonBase[] = currentProductionConcept.GetCastGroup(jobID, False)
				local oldCastGroup:TProgrammePersonBase[] = takeOverConcept.GetCastGroup(jobID)

				'skip group if current concept does not contain that group
				if castGroup.length = 0 then continue

				'leave group empty if previous concept does not contain that
				'job
				if oldCastGroup.length = 0
					currentCastIndex :+ castGroup.length
					continue
				endif

				'has to collapse unused cast slots? 
				local hasToCollapseUnused:int = (castGroup.length - oldCastGroup.length) < 0

				'try to fill slots
				for local castGroupIndex:int = 0 until castGroup.length
					'skip other cast slots not available in old concept
					if castGroupIndex >= oldCastGroup.length
						currentCastIndex :+ (castGroup.length - castGroupIndex)
						continue
					endif
					'collapse: skip unused
					if hasToCollapseUnused and not oldCastGroup[castGroupIndex] then continue

					currentProductionConcept.SetCast(currentCastIndex, oldCastGroup[castGroupIndex])

					'SetCast() fails if the index is > than allowed, so
					'we should not need to do additional checks...
					currentCastIndex :+ 1
					'stop filling if there is no space left
					if currentCastIndex > castGroup.length then exit
				Next
			Next			


			'=== PRODUCTION COMPANY ===
			if takeOverConcept.productionCompany
				currentProductionConcept.SetProductionCompany(takeOverConcept.productionCompany)
			endif


			'=== PRODUCTION FOCUS POINTS ===
			if takeOverConcept.productionFocus
				for local i:int = 0 until takeOverConcept.productionFocus.focusPoints.length
					currentProductionConcept.productionFocus.SetFocus(i, takeOverConcept.productionFocus.GetFocus(i) )
				Next
			endif
		endif
	
		'refresh the gui objects (create items, set sliders,  ...)
		RefreshProductionConceptGUI()

		refreshFinishProductionConcept = true
	End Method


	Method OpenEditTextsWindow()
		if editTextsWindow then editTextsWindow.Remove()

		editTextsWindow = New TGUIEditTextsModalWindow.Create(New TVec2D.Init(250,60), New TVec2D.Init(300,220), "supermarket_customproduction_productionbox_modal")
		editTextsWindow.SetZIndex(100000)
		editTextsWindow.SetConcept(GetInstance().currentProductionConcept)
		editTextsWindow.Open()
		GuiManager.Add(editTextsWindow)
	End Method


	Function onCloseEditTextsWindow:int( triggerEvent:TEventBase )
		local closeButton:int = triggerEvent.GetData().GetInt("closeButton", -1)
		if closeButton <> 1 then return False

		local window:TGUIEditTextsModalWindow = TGUIEditTextsModalWindow( triggerEvent.GetSender() )

		local title:String = ""
		local description:String = "" 
		local parentTitle:String = ""
		local parentDescription:String = "" 

		title = window.inputTitle.GetValue()
		description = window.inputDescription.GetValue()

		if window.concept.script.IsEpisode()
			parentTitle = title
			parentDescription = description
			title = window.inputSubTitle.GetValue()
			description = window.inputSubDescription.GetValue()
		endif
		
		if title <> window.concept.script.GetTitle()
			window.concept.SetCustomTitle(title)
			print "customTitle"
		endif
		if description <> window.concept.script.GetDescription()
			window.concept.SetCustomDescription(description)
			print "customDescription"
		endif
		if window.concept.script.IsEpisode()
			local seriesScript:TScript = window.concept.script.GetParentScript()
			if title <> seriesScript.GetTitle()
				seriesScript.SetCustomTitle(parentTitle)
				print "customSeriesTitle"
			endif
			if description <> window.concept.script.GetDescription()
				seriesScript.SetCustomDescription(parentDescription)
				print "customSeriesDescription"
			endif
		endif
		print "TODO: titel uebernehmen" 
		'...
		
	End Function
	

	'=== SELECTLIST - PRODUCTIONCONCEPT SELECTION ===

	'GUI -> LOGIC
	'create new production / pause current
	Function onSelectProductionConcept:int(triggerEvent:TeventBase)
		'only interested in production concept list entries
		if GetInstance().productionConceptList <> TGUIListBase(triggerEvent.GetSender()) then return False


		'create new one ?
		local currentGUIScript:TGuiProductionConceptSelectListItem = TGuiProductionConceptSelectListItem(GetInstance().productionConceptList.getSelectedEntry())
		if not currentGUIScript or not currentGUIScript.productionConcept then return False
		
		'skip if not changed
		if currentGUIScript.productionConcept <> GetInstance().currentProductionConcept
			'take over values from last concept - if desired
			if GetInstance().productionConceptTakeOver.isChecked() and GetInstance().currentProductionConcept
				GetInstance().SetCurrentProductionConcept(currentGUIScript.productionConcept, GetInstance().currentProductionConcept)
			else
				GetInstance().SetCurrentProductionConcept(currentGUIScript.productionConcept, null)
			endif
		endif
	End Function


	'=== DROPDOWN - PRODUCTION COMPANY - EVENTS ===

	'GUI -> LOGIC reaction
	'set production concepts production company according to selection
	Function onProductionConceptChangeProductionCompanyDropDown:int(triggerEvent:TeventBase)
		if not GetInstance().currentProductionConcept then return False
		
		local dropdown:TGUIDropDown = TGUIDropDown(triggerEvent.GetSender())
		if dropdown <> GetInstance().productionCompanySelect then return False

		local entry:TGUIDropDownItem = TGUIDropDownItem(dropdown.GetSelectedEntry())
		if not entry or not entry.data then return False

		local company:TProductionCompanyBase = TProductionCompanyBase(entry.data.Get("productionCompany"))
		if not company then return False

		GetInstance().currentProductionConcept.SetProductionCompany(company)
	End Function


	'LOGIC -> GUI reaction
	Function onProductionConceptChangeProductionCompany:int(triggerEvent:TEventBase)
		if not GetInstance().currentProductionConcept then return False

		local productionConcept:TProductionConcept = TProductionConcept(triggerEvent.GetSender())
		local company:TProductionCompanyBase = TProductionCompanyBase(triggerEvent.GetData().Get("productionCompany"))
		if productionConcept <> GetInstance().currentProductionConcept then return False

		'skip without changes
		local newItem:TGUIDropDownItem
		For local i:TGUIDropDownItem = EachIn GetInstance().productionCompanySelect.GetEntries()
			if not i.data or i.data.Get("productionCompany") <> company then continue

			newItem = i
			exit
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

		return True
	End Function


	'=== SLIDER - PRODUCTION FOCUS - EVENTS ===

	'LOGIC -> GUI reaction
	'Triggered on change of the production concepts production focus.
	'Adjusts the GUI sliders to represent the new values.
	Function onProductionConceptChangeProductionFocus:int(triggerEvent:TEventBase)
		if not GetInstance().currentProductionConcept then return False

		local productionFocus:TProductionFocusBase = TProductionFocusBase(triggerEvent.GetSender())
		if GetInstance().currentProductionConcept.productionFocus <> productionFocus then return False

		local focusIndex:int = triggerEvent.GetData().GetInt("focusIndex")
		local value:int = triggerEvent.GetData().GetInt("value")

		'skip without production company!
		if not GetInstance().currentProductionConcept.productionCompany then return False

		'skip focus aspects without sliders
		if focusIndex < 0 or GetInstance().productionFocusSlider.length < focusIndex then return False

		'do this before skipping without changes
		GetInstance().refreshFinishProductionConcept = True

		'skip without changes
		if int(GetInstance().productionFocusSlider[focusIndex -1].GetValue()) = value then return False

		'disable a previously set limit
		GetInstance().productionFocusSlider[focusIndex -1].DisableLimitValue()
		'adjust values
		GetInstance().productionFocusSlider[focusIndex -1].SetValue(value)

		return True
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
	Function _AdjustProductionConceptFocusSliderLimit:int(slider:TGUISlider)
		if not GetInstance().currentProductionConcept then return False
		if not slider then return False
		
		'adjust slider limit dynamically
		local focusIndex:int = slider.data.GetInt("focusIndex")
		local currentValue:int = Max(0, GetInstance().currentProductionConcept.GetProductionFocus(focusIndex))
		local desiredValue:int = int(slider.GetValue())
		'available points (of 10)
		local maxValue:int = Min(10, GetInstance().currentProductionConcept.productionFocus.GetFocusPointsLeft() + currentValue)

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
		if not GetInstance().currentProductionConcept then return False
		local slider:TGUISlider = _GetEventFocusSlider(triggerEvent)
		if not slider then return False

		local focusIndex:int = slider.data.GetInt("focusIndex")
		local currentValue:int = GetInstance().currentProductionConcept.GetProductionFocus(focusIndex)
		local newValue:int = int(slider.GetValue())

		'skip if nothing to do
		if newValue = currentValue then return False

		'set logic-value
		if not GetInstance().refreshingProductionGUI
			GetInstance().currentProductionConcept.SetProductionFocus( focusIndex, newValue )
		endif
		'fetch resulting value (might differ because of limitations)
		newValue = Max(0, GetInstance().currentProductionConcept.GetProductionFocus(focusIndex))

		'there might be a limitation - so adjust gui slider
		if newValue <> int(slider.GetValue())
			slider.SetValue( newValue )
		endif
	End Function

	
	'=== CAST LISTS - EVENTS ===

	'GUI -> GUI reactio
	Function onMouseOverProductionConceptItem:int( triggerEvent:TEventBase )
		local item:TGuiProductionConceptListItem = TGuiProductionConceptListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		GetInstance().hoveredGuiProductionConcept = item

		return TRUE
	End Function


	'LOGIC -> GUI reaction
	'GUI -> GUI reaction
	Function onProductionConceptChangeCast:int(triggerEvent:TEventBase)
		local castIndex:int = triggerEvent.GetData().GetInt("castIndex")
		local person:TProgrammePersonBase = TProgrammePersonBase(triggerEvent.GetData().Get("person"))

		'do this before skipping without changes
		GetInstance().refreshFinishProductionConcept = True

		'skip without changes
		if GetInstance().castSlotList.GetSlotCast(castIndex) = person then return False
		'if currentProductionConcept.GetCast(castIndex) = person then return False

		'create new gui element
		GetInstance().castSlotList.SetSlotCast(castIndex, person)
	End Function


	'open modal window for editing titles
	Function onClickEditTextsButton:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent._sender)
		'ignore wrong types and NON-dragged items
		if not button or button <> GetInstance().editTextsButton then return FALSE

		GetInstance().OpenEditTextsWindow()
	End Function

	
	'GUI -> LOGIC reaction
	Function onProductionConceptChangeCastSlotList:int(triggerEvent:TEventBase)
		if not GetInstance().currentProductionConcept then return False

		'local list:TGUICastSlotList = TGUICastSlotList( triggerEvent.GetSender() )
		local item:TGUICastListItem = TGUICastListItem( triggerEvent.GetData().Get("item") )
		local slot:int = triggerEvent.GetData().GetInt("slot")

		'DO NOT skip without changes
		'-> we listen to "successful"-message ("added" vs "add")
		'   so the slot is already filled then
		'if GetInstance().castSlotList.GetSlotCast(slot) = item.person then return False


		if not GetInstance().refreshingProductionGUI
			if item and triggerEvent.IsTrigger("guiList.addedItem")
				'print "set "+slot + "  " + item.person.GetFullName()
				GetInstance().currentProductionConcept.SetCast(slot, item.person)
			else
				'print "clear "+slot
				GetInstance().currentProductionConcept.SetCast(slot, null)
			endif
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
	

	'finish production concept
	Function onClickFinishProductionConcept:int(triggerEvent:TEventBase)
		'skip other buttons
		if triggerEvent.GetSender() <> GetInstance().finishProductionConcept then return False

		if not GetInstance().currentProductionConcept then return False
		'already at last step
		if GetInstance().currentProductionConcept.IsProduceable() then return False
		'nothing to do (should be disabled already)
		if GetInstance().currentProductionConcept.IsUnplanned() then return False

		if GetInstance().currentProductionConcept.IsPlanned()
			return GetInstance().PayCurrentProductionConceptDeposit()
		endif

		return True
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


		'=== EDIT TEXTS BUTTON ===
		editTextsButton = new TGUIButton.Create(new TVec2D.Init(530, 26), new TVec2D.Init(30, 28), "...", "supermarket_customproduction_newproduction")
		'editTextsButton.disable()
		editTextsButton.caption.SetSpriteName("gfx_datasheet_icon_pencil")
		editTextsButton.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_ONLY )
		editTextsButton.spriteName = "gfx_gui_button.datasheet"


		'=== FINISH CONCEPT BUTTON ===
		finishProductionConcept = new TGUIButton.Create(new TVec2D.Init(20, 220), new TVec2D.Init(100, 28), "...", "supermarket_customproduction_newproduction")
		finishProductionConcept.caption.SetSpriteName("gfx_datasheet_icon_money")
		finishProductionConcept.caption.SetValueSpriteMode( TGUILabel.MODE_SPRITE_LEFT_OF_TEXT3 )
		finishProductionConcept.disable()
		finishProductionConcept.spriteName = "gfx_gui_button.datasheet"

		'=== PRODUCTION TAKEOVER CHECKBOX ===
		productionConceptTakeOver = new TGUICheckbox.Create(new TVec2D.Init(20, 220), new TVec2D.Init(100, 28), "Einstellungen übernehmen", "supermarket_customproduction_productionconceptbox")

	
		'=== PRODUCTION CONCEPT LIST ===
		productionConceptList = new TGUISelectList.Create(new TVec2D.Init(20,20), new TVec2D.Init(150,180), "supermarket_customproduction_productionconceptbox")
		'scroll one concept per "scroll"
		productionConceptList.scrollItemHeightPercentage = 1.0

		'create some random concepts
		'add some items to that list
		for local i:int = 1 to 10
			local script:TScript = TMyApp.GetRandomScript()
			script.SetOwner(1)
			'parent too
			if script.IsEpisode() then script.GetParentScript().SetOwner(1)

			local productionConcept:TProductionConcept = new TProductionConcept.Initialize(1, script)
			GetProductionConceptCollection().Add(productionConcept)
		Next

		For local productionConcept:TProductionConcept = EachIn GetProductionConceptCollection().entries.Values()
			'skip produced concepts
			if productionConcept.IsProduced() then continue

			local item:TGuiProductionConceptSelectListItem = new TGuiProductionConceptSelectListItem.Create(null, new TVec2D.Init(150,24), "concept")
			item.SetProductionConcept(productionConcept)

			'base items do not have a size - so we have to give a manual one
			productionConceptList.AddItem( item )
		Next
		'refresh scrolling state
		productionConceptList.Resize(150, 180)
	End Method


	Method UpdateCustomProduction()
		'gets refilled in gui-updates
		hoveredGuiCastItem = null
		hoveredGuiProductionConcept = null

		'disable / enable elements according to state
		if not currentProductionConcept or currentProductionConcept.IsProduceable()
			if (not currentProductionConcept or not currentProductionConcept.productionCompany or productionFocusSlider[0].IsEnabled())
				'disable _all_ sliders if no production company is selected
				For local i:int = 0 to productionFocusSlider.length -1
					productionFocusSlider[i].Disable()
				Next
			endif
			
			'general elements
			if productionCompanySelect.IsEnabled()
				productionCompanySelect.Disable()
				castSlotList.Disable()
				'if currentProductionConcept then print "DISABLE " + currentProductionConcept.script.GetTitle()
			endif
		endif

		'or enable (specific of) them...
		if currentProductionConcept and not currentProductionConcept.IsProduceable()
			'sliders only with selected production company
			if currentProductionConcept.productionCompany and not productionFocusSlider[0].IsEnabled()
				For local i:int = 0 to productionFocusSlider.length -1
					if currentProductionConcept.productionFocus.GetFocusAspectCount() > i
						productionFocusSlider[i].Enable()
					endif
				Next
			endif

			'general elements
			if not productionCompanySelect.IsEnabled()
				productionCompanySelect.Enable()
				castSlotList.Enable()
				'if currentProductionConcept then print "ENABLE " + currentProductionConcept.script.GetTitle()
			endif
		endif

		GuiManager.Update("supermarket_customproduction_castbox_modal")
		GuiManager.Update("supermarket_customproduction_productionbox_modal")
		GuiManager.Update("supermarket_customproduction_productionconceptbox")
		GuiManager.Update("supermarket_customproduction_newproduction")
		GuiManager.Update("supermarket_customproduction_productionbox")
		GuiManager.Update("supermarket_customproduction_castbox")
	End Method


	Method RenderCustomProduction()
		'update finishProductionConcept-button's value if needed
		if currentProductionConcept and refreshFinishProductionConcept
			if currentProductionConcept.IsProduceable()
				finishProductionConcept.Disable()
				finishProductionConcept.spriteName = "gfx_gui_button.datasheet.informative"

				finishProductionConcept.SetValue("|b|Planung abgeschlossen|/b|")
			elseif currentProductionConcept.IsPlanned()
				finishProductionConcept.Enable()
				'TODO: positive/negative je nach Geldstand
				finishProductionConcept.spriteName = "gfx_gui_button.datasheet.positive"
				finishProductionConcept.SetValue("|b|Planung abschließen|/b|~nund |b|"+TFunctions.DottedValue(currentProductionConcept.GetDepositCost())+" " + GetLocale("CURRENCY")+"|/b| anzahlen")
			else
				finishProductionConcept.Disable()
				finishProductionConcept.spriteName = "gfx_gui_button.datasheet"
				finishProductionConcept.SetValue("|b|Planung...|/b|~n(|b|"+TFunctions.DottedValue(currentProductionConcept.GetDepositCost())+" " + GetLocale("CURRENCY")+"|/b| anzuzahlen)")
			endif
		endif

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



		'=== PRODUCTION CONCEPT LIST ===
		outer.Init(10, 15, 210, 205)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		local checkboxArea:int = productionConceptTakeOver.rect.GetH() + 0*buttonAreaPaddingY

		local listH:int = contentH - titleH - checkboxArea

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock("Einkaufslisten", contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		if productionConceptList.rect.getX() <> contentX + 5
			productionConceptList.rect.SetXY(contentX + 5, contentY + 3)
			productionConceptList.Resize(contentW - 10, listH - 6)
		endif
		contentY :+ listH

		skin.RenderContent(contentX, contentY, contentW, contentH - (listH+titleH) , "1_bottom")
		'reposition checkbox
		productionConceptTakeOver.rect.SetXY(contentX + 5, contentY + buttonAreaPaddingY)
		productionConceptTakeOver.Resize(contentW - 10)
		contentY :+ contentH - (listH+titleH)

		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())



		if GetInstance().currentProductionConcept
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
			finishProductionConcept.rect.SetXY(contentX + 5, contentY + buttonAreaPaddingY)
			finishProductionConcept.Resize(contentW - 10, 38)
			contentY :+ buttonAreaH

			skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())


			'=== CAST / MESSAGE BOX ===
			'calc height
			local castAreaH:int = 215
			local msgAreaH:int = 0
			if currentProductionConcept
				if not currentProductionConcept.IsCastComplete() then msgAreaH :+ msgH + msgPaddingY
				if not currentProductionConcept.IsFocusPointsComplete() then msgAreaH :+ msgH + msgPaddingY
			endif
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
				skin.fontCaption.drawBlock(currentProductionConcept.GetTitle(), contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
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
						if not currentProductionConcept.IsFocusPointsMinimumUsed()
							skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("NEED_TO_SPENT_AT_LEAST_ONE_POINT_OF_PRODUCTION_FOCUS_POINTS"), "spotsplanned", "warning")
						else
							skin.RenderMessage(contentX + 5 , contentY + 3, contentW - 10, -1, GetLocale("PRODUCTION_FOCUS_POINTS_NOT_SET_COMPLETELY"), "spotsplanned", "neutral")
						endif
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
			
			outer.SetXY(580, 15)
			outer.dimension.SetXY(210, outerH)
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

			if currentProductionConcept.productionFocus
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

			GuiManager.Draw("supermarket_customproduction_productionconceptbox")
			GuiManager.Draw("supermarket_customproduction_newproduction")
			GuiManager.Draw("supermarket_customproduction_productionbox")
			GuiManager.Draw("supermarket_customproduction_castbox")
	'		GuiManager.Draw("supermarket_customproduction_castbox", -1000,-1000, GUIMANAGER_TYPES_NONDRAGGED)

			GuiManager.Draw("supermarket_customproduction")
	'		GuiManager.Draw("supermarket_customproduction_castbox", -1000,-1000, GUIMANAGER_TYPES_DRAGGED)
			GuiManager.Draw("supermarket_customproduction_castbox_modal")
			GuiManager.Draw("supermarket_customproduction_productionbox_modal")

			'draw datasheet if needed
			if hoveredGuiCastItem then hoveredGuiCastItem.DrawDatasheet(hoveredGuiCastItem.GetScreenX() - 230, hoveredGuiCastItem.GetScreenX() - 170 )

		else
			GuiManager.Draw("supermarket_customproduction_productionconceptbox")
		endif


		'=== DEBUG ===
		local debugX:int = 20
		local debugY:int = 400
		if GetInstance().currentProductionConcept
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

		endif


		'draw script-sheet
		if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()

		DrawText("Tasten:", 50,525)
		DrawText("1-5: Zufallsbesetzung #1-5   Num1-7: Focus #1-7   Num8/9: FocusPoints +/-", 50,540)
		DrawText("Q/W/E: Produktionsfirma #1-3   R: Zufallsproduktionsfirma", 50,555)
		DrawText("Leertaste: Neue Zufallsproduktion", 50,570)
 	End Method
End Type



Type TGuiProductionConceptSelectListItem Extends TGuiProductionConceptListItem
	Field displayName:string = ""
	Field minHeight:int = 50 '61
	Const scaleAsset:Float = 0.55
	Const paddingBottom:Int	= 2
	Const paddingTop:Int = 2


    Method Create:TGuiProductionConceptSelectListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
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

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, max(minHeight, asset.GetHeight() * scaleAsset))
		
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


	Method DrawBackground()
		local oldCol:TColor = new TColor.Get()

		'available width is parentsDimension minus startingpoint
		Local maxWidth:Int = GetParent().getContentScreenWidth() - rect.getX()
		local bgColor:TColor

		'ready for production
		if productionConcept.IsProduceable()
			bgColor = TColor.Create(110,180,60, 0.1)
		'planned but not paid
		elseif productionConcept.isPlanned()
			bgColor = TColor.Create(60,110,180, 0.1)
		'in planning
		elseif productionConcept.IsGettingPlanned()
			bgColor = TColor.Create(180,110,60, 0.1)
		'default
		else 'elseif productionConcept.IsUnplanned()
			if IsHovered() or isSelected()
				bgColor = TColor.Create(175,165,120, 0.25)
			endif
		endif


		if bgColor
			If isSelected() then bgColor.a :+ 0.05; bgColor.AdjustBrightness(0.1)
			If isHovered() then bgColor.a :+ 0.1; bgColor.AdjustBrightness(0.1)

			bgColor.SetRGBA()

			DrawRect(GetScreenX(), GetScreenY() + paddingTop -2, GetScreenWidth(), GetScreenHeight() - paddingBottom -3)

			oldCol.SetRGBA()
		endif
	End Method


	'override
	Method DrawContent()
		DrawProductionConceptItem()
		
		'hovered
		If isHovered() and not isDragged()
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend

			DrawProductionConceptItem()

			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf

		SetColor 150,150,150
		DrawLine(GetScreenX() + 10, GetScreenY2() - paddingBottom -1, GetScreenX2() - 20, GetScreenY2() - paddingBottom -1)
		SetColor 210,210,210
		DrawLine(GetScreenX() + 10, GetScreenY2() - paddingBottom, GetScreenX2() - 20, GetScreenY2() - paddingBottom)
	End Method


	Method DrawProductionConceptItem()
		GetAsset().draw(Self.GetScreenX(), Self.GetScreenY(), -1, null, scaleAsset)

		'ready for production
		if productionConcept.IsProduceable()
			GetSpriteFromRegistry("gfx_datasheet_icon_ok").Draw(Self.GetScreenX()-2, Self.GetScreenY() + GetAsset().GetHeight() * scaleAsset -1)
		'finished planning
		elseif productionConcept.IsPlanned()
			GetSpriteFromRegistry("gfx_datasheet_icon_ok2").Draw(Self.GetScreenX()-2, Self.GetScreenY() + GetAsset().GetHeight() * scaleAsset -1)
		'planning not yet finished
		elseif productionConcept.IsGettingPlanned()
			GetSpriteFromRegistry("gfx_datasheet_icon_warning").Draw(Self.GetScreenX()-3, Self.GetScreenY() + GetAsset().GetHeight() * scaleAsset -1)
		'default
		else 'elseif productionConcept.IsUnplanned()
			'nothing
		endif

		local textOffsetX:int = asset.GetWidth()*scaleAsset + 3
		local title:string = "unknown script"
		local subtitle:string = ""
		local titleSize:TVec2D
		local subTitleSize:TVec2D
		local genreColor:TColor
		local titleColor:TColor
		local titleFont:TBitmapFont = GetBitmapFont("default",,BOLDFONT)
		local oldMod:float = titleFont.lineHeightModifier
		titleFont.lineHeightModifier :* 0.9

		if productionConcept
			title = productionConcept.GetTitle()
			if productionConcept.script.IsEpisode()
				local seriesScript:TScript = productionConcept.script.GetParentScript()
				subtitle = (seriesScript.GetSubScriptPosition(productionConcept.script)+1)+"/"+seriesScript.GetSubscriptCount()+": "+ title
				title = seriesScript.GetTitle()
			endif
		endif


		'finished
		if productionConcept.IsProduceable()
			titleColor = TColor.Create(80,150,30)
			genreColor = TColor.CreateGrey(0, 0.6)
		'all slots filled, just not paid
		elseif productionConcept.IsPlanned()
			titleColor = TColor.Create(30,80,150)
			genreColor = TColor.CreateGrey(0, 0.6)
		'planned but not finished
		elseif productionConcept.IsGettingPlanned()
			titleColor = TColor.Create(150,80,30)
			genreColor = TColor.CreateGrey(0, 0.6)
		'default /unplanned
		else 'elseif productionConcept.IsUnplanned()
			titleColor = TColor.CreateGrey(50)
			genreColor = TColor.CreateGrey(0, 0.6)
		endif
		

		if isSelected()
			titleColor.AdjustBrightness(+0.05)
			genreColor.AdjustBrightness(+0.05)
		endif
		if isHovered()
			titleColor.AdjustBrightness(+0.05)
			genreColor.AdjustBrightness(+0.05)
		endif


		titleSize = titleFont.DrawBlock(title, int(GetScreenX()+ textOffsetX), int(GetScreenY()+2), GetScreenWidth() - textOffsetX - 1, GetScreenHeight()-4,,titleColor)
		if subTitle
			subTitleSize = titleFont.DrawBlock(subTitle, int(GetScreenX()+ textOffsetX), int(GetScreenY() + titleSize.y + 2), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-4,,titleColor)
		endif


		titleFont.lineHeightModifier = oldMod
		

		if productionConcept
			local productionTypeText:string = productionConcept.script.GetProductionTypeString()
			local genreText:string = productionConcept.script.GetMainGenreString()
			local text:string = productionTypeText
			if genreText <> productionTypeText then text :+ " / "+genreText
			if subTitle
				GetBitmapFont("default").DrawBlock(text, int(GetScreenX()+ textOffsetX), int(GetScreenY()+2 + titleSize.y + subTitleSize.y), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-4,,genreColor)
			else
				GetBitmapFont("default").DrawBlock(text, int(GetScreenX()+ textOffsetX), int(GetScreenY()+2 + titleSize.y), GetScreenWidth() - textOffsetX - 3, GetScreenHeight()-4,,genreColor)
			endif
		endif
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
		
		if selectCastSlot >= 0 and RoomHandler_Supermarket.GetInstance().currentProductionConcept
			local jobID:int = RoomHandler_Supermarket.GetInstance().currentProductionConcept.script.cast[selectCastSlot].job
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

		SetAlpha 0.5 * GetAlpha()
		For local slot:int = 0 until _slots.length
			if _slots[slot] then continue
			if slotJob.length < slot then continue
			
			local coord:TVec3D = GetSlotCoord(slot)

			if MouseManager._ignoreFirstClick 'touch mode
				TGUICastListItem.DrawCast(GetScreenX() + coord.GetX(), GetScreenY() + coord.GetY(), GetContentScreenWidth(), GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(GetSlotJob(slot))), GetLocale("TOUCH_TO_SELECT_PERSON"), null, 0,0,0)
			else
				TGUICastListItem.DrawCast(GetScreenX() + coord.GetX(), GetScreenY() + coord.GetY(), GetContentScreenWidth(), GetLocale("JOB_" + TVTProgrammePersonJob.GetAsString(GetSlotJob(slot))), GetLocale("CLICK_TO_SELECT_PERSON"), null, 0,0,0)
			endif
		Next
		SetAlpha 2.0 * GetAlpha()

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

	Const paddingBottom:Int	= 5
	Const paddingTop:Int = 0


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
					if slotListSlot >= 0
						local slotJob:int = TGUICastSlotList(parentList).GetSlotJob(slotListSlot)
						if slotJob > 0
							return TGUICastSlotList(parentList).GetSlotJob(slotListSlot)
						else
							print "return last: "+lastDisplayJobID
							return lastDisplayJobID
						endif
					endif
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

			if displayJobID = 0 then displayJobID = lastDisplayJobID
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
			if GetDisplayJobID() > 0
				name = GetLocale("JOB_AMATEUR_" + TVTProgrammePersonJob.GetAsString( GetDisplayJobID() ))
			else
				name = GetLocale("JOB_AMATEUR")
			endif
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

			local oldCol:TColor = new TColor.Get()

			SetAlpha( Max(0.6, oldCol.a) )
			if name
				skin.fontSemiBold.drawBlock( ..
					name, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop(), .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(15, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif

			SetAlpha( Max(0.75, oldCol.a) )
			if nameHint
				skin.fontNormal.drawBlock( ..
					nameHint, ..
					x + nameTextOffsetX + border.GetLeft(), ..
					y + nameOffsetY + border.GetTop(), .. '-1 to align it more properly
					w - nameTextOffsetX - (border.GetRight() + border.GetLeft()),  ..
					Max(15, nameSprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
					ALIGN_RIGHT_CENTER, skin.textColorNeutral)
			endif

			SetAlpha (oldCol.a)
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
				local jobID:int = TVTProgrammePersonJob.GetAtIndex(jobIndex)
				if not cast.HasJob(jobID) then continue

				firstJobID = jobID
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
				if jobID > 0
					skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR_"+TVTProgrammePersonJob.GetAsString(jobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				else
					skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR"), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				endif
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
		skin.RenderBox(contentX + 5 + 94, contentY, contentW - 10 - 94 +1, -1, TFunctions.DottedValue(cast.GetBaseFee(jobID, RoomHandler_Supermarket.GetInstance().currentProductionConcept.script.blocks)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
	endif
	contentY :+ boxH


	'=== OVERLAY / BORDER ===
	skin.RenderBorder(x, y, sheetWidth, sheetHeight)
End Function




Type TGUIProductionModalWindow extends TGUIModalWindow
	Field buttonOK:TGUIButton
	Field buttonCancel:TGUIButton
	Field _eventListeners:TLink[]


	Method Create:TGUIProductionModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.CreateBase(pos, dimension, limitState)

		darkenedAreaAlpha = 0.25 '0.5 is default


		buttonOK = new TGUIButton.Create(new TVec2D.Init(10, dimension.GetY() - 44), new TVec2D.Init(136, 28), "OK", "")
		buttonOK.spriteName = "gfx_gui_button.datasheet"
		buttonCancel = new TGUIButton.Create(new TVec2D.Init(dimension.GetX() - 15 - 136, dimension.GetY() - 44), new TVec2D.Init(136, 28), "Cancel", "")
		buttonCancel.spriteName = "gfx_gui_button.datasheet"

		AddChild(buttonOK)
		AddChild(buttonCancel)
	End Method


	Method Remove:Int()
		EventManager.unregisterListenersByLinks(_eventListeners)
		return Super.Remove()
	End Method


	'override to skip animation
	Method IsClosed:int()
		return closeActionStarted
	End Method


	Method Resize(w:Float = 0, h:Float = 0)
		Super.Resize(w, h)
		if buttonOK then buttonOK.rect.position.SetY( rect.dimension.GetY() - 44)
		if buttonCancel then buttonCancel.rect.position.SetY( rect.dimension.GetY() - 44)
	End Method
	

	'override to _not_ recenter
	Method Recenter:Int(moveBy:TVec2D=Null)
		return True
	End Method


	Method Update:int()
		if buttonCancel.IsClicked() then Close(2)
		if buttonOK.IsClicked() then Close(1)

		return super.Update()
	End Method	
End Type



Type TGUISelectCastWindow extends TGUIProductionModalWindow
	Field jobFilterSelect:TGUIDropDown
	'only list persons with the following job?
	Field listOnlyJobID:int = -1
	'select a person for the following job (for correct fee display)
	Field selectJobID:int = 0
	Field castSelectList:TGUICastSelectList
	

	'override
	Method Create:TGUISelectCastWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

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


		AddChild(jobFilterSelect)
		AddChild(castSelectList)

		buttonOK.SetValue("Person auswählen")
		buttonCancel.SetValue("Abbrechen")

		_eventListeners :+ [ EventManager.registerListenerMethod("GUIDropDown.onSelectEntry", self, "onCastChangeJobFilterDropdown", "TGUIDropDown" ) ]
		_eventListeners :+ [ EventManager.registerListenerMethod("guiobject.OnDoubleClick", self, "onDoubleClickCastListItem", "TGUICastListItem" ) ]

		Return self
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
				if selectJobID > 0
					item.displayName = GetLocale("JOB_AMATEUR_" + TVTProgrammePersonJob.GetAsString(selectJobID))
				else
					item.displayName = GetLocale("JOB_AMATEUR")
				endif

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
End Type




Type TGUIEditTextsModalWindow extends TGUIProductionModalWindow
	Field inputTitle:TGUIInput
	Field inputDescription:TGUIInput
	Field inputSubTitle:TGUIInput
	Field inputSubDescription:TGUIInput
	Field labelTitle:TGUILabel
	Field labelDescription:TGUILabel
	Field labelEpisode:TGUILabel
	Field labelSubTitle:TGUILabel
	Field labelSubDescription:TGUILabel
	
	Field concept:TProductionConcept

	'override
	Method Create:TGUIEditTextsModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		labelTitle = new TGUILabel.Create(new TVec2D.Init(15,12), GetLocale("TITLE"), null, "")
		labelDescription = new TGUILabel.Create(new TVec2D.Init(15,60), GetLocale("DESCRIPTION"), null, "")
		labelEpisode = new TGUILabel.Create(new TVec2D.Init(15,115), GetLocale("EPISODE"), null, "")
		labelEpisode.SetFont( GetBitmapFontManager().Get("default", 13, BOLDFONT) )
		labelSubTitle = new TGUILabel.Create(new TVec2D.Init(15,137), GetLocale("TITLE"), null, "")
		labelSubDescription = new TGUILabel.Create(new TVec2D.Init(15,180), GetLocale("DESCRIPTION"), null, "")

		inputTitle = new TGUIInput.Create(new TVec2D.Init(15,12+13), new TVec2D.Init(265,-1), "Titel", 128, "")
		inputDescription = new TGUIInput.Create(new TVec2D.Init(15,60+13), new TVec2D.Init(265,-1), "Text", 128, "")
		inputSubTitle = new TGUIInput.Create(new TVec2D.Init(15,137+13), new TVec2D.Init(265,-1), "Subtitel", 128, "")
		inputSubDescription = new TGUIInput.Create(new TVec2D.Init(15,180+13), new TVec2D.Init(265,-1), "Subtext", 128, "")

		AddChild(labelTitle)
		AddChild(labelDescription)
		AddChild(labelEpisode)
		AddChild(labelSubTitle)
		AddChild(labelSubDescription)

		AddChild(inputTitle)
		AddChild(inputDescription)
		AddChild(inputSubTitle)
		AddChild(inputSubDescription)

		buttonOK.SetValue("Texte ändern")
		buttonCancel.SetValue("Abbrechen")

		_eventListeners :+ [ EventManager.registerListenerMethod("guiinput.onChangeValue", self, "onChangeInputValues", "TGUIInput" ) ]

		Return self
	End Method


	'override
	Method Remove:int()
		Super.Remove()
		concept = null
	End Method
	

	'override to fill with content on open
	Method Open:Int()
		Super.Open()

		'read values
		if concept
			if concept.script.IsEpisode()
				local seriesScript:TScript = concept.script.GetParentScript()
				inputTitle.SetValue(seriesScript.GetTitle())
				inputDescription.SetValue(seriesScript.GetDescription())

				inputSubTitle.SetValue(concept.script.GetTitle())
				inputSubDescription.SetValue(concept.script.GetDescription())
			else
				inputTitle.SetValue(concept.script.GetTitle())
				inputDescription.SetValue(concept.script.GetDescription())
			endif
		endif
	End Method


	Method SetConcept:int(concept:TProductionConcept)
		if not concept then return False

		self.concept = concept
		if concept.script.IsEpisode()
			inputSubDescription.Show()
			inputSubTitle.Show()
			labelSubDescription.Show()
			labelSubTitle.Show()
			labelEpisode.Show()

			local seriesScript:TScript = concept.script.GetParentScript()
			labelEpisode.SetValue( GetLocale("EPISODE") +": "+(seriesScript.GetSubScriptPosition(concept.script)+1)+"/"+seriesScript.GetSubscriptCount() )

			Resize(-1,280)
		else
			inputSubDescription.Hide()
			inputSubTitle.Hide()
			labelSubDescription.Hide()
			labelSubTitle.Hide()
			labelEpisode.Hide()
			Resize(-1,155)
		endif
	End Method
		

	Method DrawBackground()
		Super.DrawBackground()

		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		local outer:TRectangle = GetScreenRect().Copy()
		local contentX:int = skin.GetContentX(outer.GetX())
		local contentY:int = skin.GetContentY(outer.GetY())
		local contentW:int = skin.GetContentW(outer.GetW())
		local contentH:int = skin.GetContentH(outer.GetH())


		if concept and concept.script.IsEpisode()
			local topH:int = int((contentH - 35)/2.0) - 8
			skin.RenderContent(contentX, contentY, contentW, topH, "1_top")
			skin.RenderContent(contentX, contentY + topH, contentW, contentH - topH - 35, "1")
		else
			skin.RenderContent(contentX, contentY, contentW, contentH - 35, "1_top")
		endif

		skin.RenderContent(contentX, contentY+contentH-35, contentW, 35, "1_bottom")

		skin.RenderBorder(outer.GetX(), outer.GetY(), outer.GetW(), outer.GetH())
	End Method


	Method onChangeInputValues:int( triggerEvent:TEventBase )
		local input:TGUIInput = TGUIInput( triggerEvent.GetSender() )

		if inputTitle
			'ueberpruefen ob Titel OK
			'wenn leer - dann Originaltext wieder einbinden
		elseif inputSubTitle
			'ueberpruefen ob Titel OK
			'wenn leer - dann Originaltext wieder einbinden
		elseif inputDescription
			'wenn leer - dann Originaltext wieder einbinden
		elseif inputSubDescription
			'wenn leer - dann Originaltext wieder einbinden
		endif
	End Method
End Type