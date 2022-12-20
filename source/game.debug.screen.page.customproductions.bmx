SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.player.bmx"



Type TDebugScreenPage_CustomProductions extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field playerStudioBlocks:TDebugContentBlock[]
	Field scriptsBlock:TDebugContentBlock
	Field selectedPlayerStudioBlock:TDebugContentBlock
	Field selectedObjectBlock:TDebugContentBlock
	Field selectedObject:Object
	Field displayedPlayerID:Int
	Field selectedStudioID:Int
	
	Global _instance:TDebugScreenPage_CustomProductions


	Method New()
		_instance = self
	End Method

	Function GetInstance:TDebugScreenPage_CustomProductions()
		if not _instance then new TDebugScreenPage_CustomProductions
		return _instance
	End Function 

	
	Method Init:TDebugScreenPage_CustomProductions()
rem
		Local texts:String[] = ["Reset", "-1%", "+1%", "+10%", "Reset", "-1%", "+1%", "+10%", "Reset", "-1%", "+1%", "+10%", "Reset", "-1%", "+1%", "+10%"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next
endrem		
		RefreshDisplayedPlayer( GetShownPlayerID() )
		
		RefreshScripts()

		Return self
	End Method
	
	
	Method SetPosition(x:Int, y:Int)
		position = new SVec2I(x, y)

		'move buttons
		For local b:TDebugControlsButton = EachIn buttons
			b.x = x + 510 + 5
			b.y = y + b.dataInt * (b.h + 3)
		Next
	End Method
	
	
	Method Reset()
		displayedPlayerID = -1
		playerStudioBlocks = Null
		selectedStudioID = -1
		selectedObjectBlock = Null
		selectedObject = Null
		selectedPlayerStudioBlock = Null
		scriptsBlock = Null
	End Method
	
	
	Method Activate()
		Reset()
		RefreshDisplayedPlayer( GetShownPlayerID(), True)
		RefreshScripts()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		If not scriptsBlock or not playerStudioBlocks Then Init()

		Local playerID:Int = GetShownPlayerID()

'		For Local b:TDebugControlsButton = EachIn buttons
'			b.Update()
'		Next

		If GetShownPlayerID() <> displayedPlayerID
			RefreshDisplayedPlayer( GetShownPlayerID() )
		EndIf

		local startY:int = position.y
		For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
			block.Update(position.x + 5, startY)
			startY :+ block.size.y
		Next


		'identify selected/hovered elements
		selectedObject = Null
		For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
			If not selectedObject and block.selectedObject
				selectedObject = block.selectedObject
			EndIf
			'hover overrides selection
			If block.hoveredObject
				selectedObject = block.hoveredObject
			EndIf
		Next


		'identify possibly clicked studio block
		If not selectedObject
			startY = position.y
			For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
				If THelper.MouseIn(position.x + 5, startY, block.size.x, block.size.y) and MouseManager.IsClicked(1)
					if selectedPlayerStudioBlock Then selectedPlayerStudioBlock.selected = False

					selectedPlayerStudioBlock = block
					block.selected = True
					SelectStudio(block.room.GetID())

					MouseManager.SetClickHandled(1)
				EndIf

				startY :+ block.size.y
			Next
		EndIf
		
		
		If selectedObject
			If TScriptBase(selectedObject)
				if not TDebugContentBlock_Script(selectedObjectBlock)
					selectedObjectBlock = new TDebugContentBlock_Script()
				EndIf
				TDebugContentBlock_Script(selectedObjectBlock).script = TScriptBase(selectedObject)
			ElseIf TProduction(selectedObject)
				if not TDebugContentBlock_Production(selectedObjectBlock)
					selectedObjectBlock = new TDebugContentBlock_Production()
				EndIf
				TDebugContentBlock_Production(selectedObjectBlock).production = TProduction(selectedObject)
			ElseIf TProductionConcept(selectedObject)
				if not TDebugContentBlock_ProductionConcept(selectedObjectBlock)
					selectedObjectBlock = new TDebugContentBlock_ProductionConcept()
				EndIf
				TDebugContentBlock_ProductionConcept(selectedObjectBlock).productionConcept = TProductionConcept(selectedObject)
			Else
				selectedObjectBlock = Null
			EndIf
		EndIf

		if selectedObject and selectedObjectBlock
			selectedObjectBlock.Update(position.x + 320, position.y)
		EndIf
		
		scriptsBlock.Update(position.x + 320, position.y)
	End Method


	Method Render()
		If not scriptsBlock or not playerStudioBlocks Then Init()
			
	
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		local startY:int = position.y
		For Local block:TDebugContentBlock = EachIn playerStudioBlocks
			block.Draw(position.x + 5, startY)
			startY :+ block.size.y
		Next
		
		scriptsBlock.Draw(position.x + 320, position.y)

		if selectedObject and selectedObjectBlock
			selectedObjectBlock.Draw(position.x + 320, position.y)
		EndIf
	End Method
	
	
	Method SelectStudio(roomID:Int)
		selectedStudioID = roomID
	End Method
	

	Method RefreshDisplayedPlayer(playerID:Int, force:int = False)
		if playerID <> displayedPlayerID or force
			RefreshPlayerStudios(playerID)
		EndIf
		displayedPlayerID = playerID
	End Method

	
	Method RefreshPlayerStudios(playerID:Int)
		Local rooms:TRoomBase[] = GetRoomBaseCollection().GetAllByDetails("studio", "", playerID)
		If rooms.length <> playerStudioBlocks.length 
			playerStudioBlocks = playerStudioBlocks[.. rooms.length]
		EndIf

		local i:int
		For local room:TRoomBase = Eachin rooms
			playerStudioBlocks[i] = New TDebugContentBlock_Studios(room)
			i :+ 1
		Next
		
		selectedPlayerStudioBlock = Null
	End Method
	
	
	Method RefreshScripts()
		scriptsBlock = New TDebugContentBlock_Scripts()
	
	
		'- welche Drehbuecher haben die Spieler (Koffer, ProgrammeCollection ... ?)
		'- Welches Drehbuch steht in welchem Studio?

		'loop over ALL scripts (not just in the collections!)
'		For local script:TScript = Eachin GetScriptCollection().entries.Values() ' .GetUsedScriptList()
'		Next
	End Method
	
rem
Allgemein:
- Einkaufslisten - mit Status
- laufende Produktionen -> welches Studio?
- Studio -> Laufende Produktion? 
endrem


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local changeValue:Float = 1.0 '1%
'		Select sender.dataInt
'...
'		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type




Type TDebugContentBlock_Scripts extends TDebugContentBlock
	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 320
		Local contentHeight:Int = 0
		Local dim:SVec2I

		TDebugScreenPage.textFont.Draw("|b|All Scripts|/b|", x, y + contentHeight)
		contentHeight :+ 12
		TDebugScreenPage.textFont.Draw("|b|Title|/b|", x + 5, y + contentHeight)
		TDebugScreenPage.textFont.Draw("|b|Owner|/b|", x + 5 + 200, y + contentHeight)
		TDebugScreenPage.textFont.Draw("|b|Loc.|/b|", x + 5 + 200 + 45, y + contentHeight)
		contentHeight :+ 10

		'- welche Drehbuecher haben die Spieler (Koffer, ProgrammeCollection ... ?)
		'- Welches Drehbuch steht in welchem Studio?

		'loop over ALL scripts (not just in the collections!)
		For local script:TScript = Eachin GetScriptCollection().entries.Values() ' .GetUsedScriptList()
			'ignore episodes and only expose them if parent selected?
			If script.IsEpisode() Then Continue
			
			'enable these lines to filter for specific owners
			'eg.: only players and vendor
			If not script.IsOwned() or script.GetOwner() < 0 Then Continue
		
			TDebugScreenPage.textFont.Draw(script.GetTitle(), x + 5, y + contentHeight)
			Local ownerText:String
			Local locText:String
			If script.IsOwned()
				Local ownerID:Int = script.GetOwner()
				If ownerID = TOwnedGameObject.OWNER_VENDOR
					ownerText = "Vendor"
				Elseif ownerID > 0
					ownerText = "Player #"+ownerID
					
					'find location of the script
					Local ppc:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(ownerID)
					If ppc.HasScriptInSuitcase(script)
						locText :+ "Suitcase"
					EndIf
					If ppc.HasScriptInStudio(script)
						Local roomID:Int = RoomHandler_Studio.GetInstance().GetStudioIDByScript(script)
						Local room:TRoomBase = GetRoomBaseCollection().Get(roomID)
						If room
							locText :+ room.GetName()+" (ID:"+roomID+")"
						Else
							locText :+ "Room (ID:"+roomID+")"
						EndIf
					EndIf
					If ppc.HasScript(script)
						locText :+ "Archive"
					EndIf
					
					If not locText Then locText = "UNKNOWN"
				ElseIf ownerID < 0
					Local producer:TProgrammeProducerBase = GetProgrammeProducerCollection().GetByID(- ownerID)
					If producer
						ownerText = producer.name
					Else
						ownerText = ownerID
					EndIf
				Else
					ownerText = ownerID
				EndIf
			Else
				ownerText = "Nobody"
			EndIf
			TDebugScreenPage.textFont.Draw(ownerText, x + 5 + 200, y + contentHeight, new SColor8(220,220,200))
			TDebugScreenPage.textFont.Draw(locText, x + 5 + 200 + 45, y + contentHeight, new SColor8(220,220,200))
			
			contentHeight :+ 10
		Next

		contentSize = new SVec2I(contentWidth, contentHeight)
	End Method
End Type




Type TDebugContentBlock_Script extends TDebugContentBlock
	Field script:TScriptBase

	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 300
		Local contentHeight:Int = 0
		Local dim:SVec2I
		
		TScript(script).ShowSheet(x, y, -1, -1)
		'contentHeight :+ 300

		'TDebugScreenPage.textFont.Draw("|b|"+script.GetTitle() + "|/b|", x + 5, y + contentHeight)
		'contentHeight :+ 12
		contentSize = new SVec2I(contentWidth, contentHeight)
	End Method
End Type




Type TDebugContentBlock_ProductionConcept extends TDebugContentBlock
	Field productionConcept:TProductionConcept
	Global dummyGUIItem:TGuiProductionConceptListItem
	
	Method New()
		dummyGUIItem = new TGuiProductionConceptListItem
	End Method


	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 300
		Local contentHeight:Int = 0
		Local dim:SVec2I
		
		dummyGUIItem.productionConcept = productionConcept
		dummyGUIItem.ShowStudioSheet(x, y, -1, -1)
		dummyGUIItem.productionConcept = Null
		'contentHeight :+ 300

		'TDebugScreenPage.textFont.Draw("|b|"+productionConcept.GetTitle() + "|/b|", x + 5, y + contentHeight)
		'contentHeight :+ 12
		contentSize = new SVec2I(contentWidth, contentHeight)
	End Method
End Type



Type TDebugContentBlock_Production extends TDebugContentBlock
	Field production:TProduction

	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 300
		Local contentHeight:Int = 0
		Local dim:SVec2I

		TDebugScreenPage.textFont.Draw("|b|"+production.productionConcept.GetTitle() + "|/b|", x + 5, y + contentHeight)
		contentHeight :+ 12
		contentSize = new SVec2I(contentWidth, contentHeight)
	End Method
End Type



Type TDebugContentBlock_Studios extends TDebugContentBlock
	Field room:TRoomBase
	Field hoveredObject:Object
	Field selectedObject:Object
	

	Method New(room:TRoomBase)
		self.room = room
	End Method
	
	
	
	Method Update(x:Int, y:Int) override
		Super.Update(x, y)
		
		' splitting logic from rendering this way (marking hovered element
		' during DrawContent() can lead to slight inaccuracies on low FPS
		' - but it keeps required code amount low and should do for our
		' "dev/debug purposes"
		if hoveredObject and MouseManager.IsClicked(1)
			selectedObject = hoveredObject
			'print "clicked on obj"
		Endif
			
	End Method
	
	
	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 300
		Local contentHeight:Int = 0
		Local dim:SVec2I

		Local oldHoveredObject:Object = hoveredObject
		hoveredObject = Null
		
		TDebugScreenPage.textFont.Draw("|b|"+room.GetName() + "|/b| (size: " + room.GetSize()+", ID: "+room.GetID()+")", x + 5, y + contentHeight)
		contentHeight :+ 12

		local currentScript:TScriptBase = RoomHandler_Studio.GetInstance().GetCurrentStudioScript(room.GetID())
		If not currentScript
			dim = TDebugScreenPage.textFont.Draw("|b|Script:|/b| Empty", x + 10, y + contentHeight)
			contentHeight :+ 12
		Else
			If oldHoveredObject = currentScript
				dim = TDebugScreenPage.textFont.Draw("|b|Script:|/b| " + currentScript.GetTitle(), x + 10, y + contentHeight, SColor8.White)
			Else
				dim = TDebugScreenPage.textFont.Draw("|b|Script:|/b| " + currentScript.GetTitle(), x + 10, y + contentHeight, new SColor8(220,220,220))
			EndIf
			'mark hovered?
			If THelper.MouseIn(x + 10, y + contentHeight, dim.x, dim.y) Then hoveredObject = currentScript
			contentHeight :+ 12
		EndIf

		Local productions:TProduction[] = GetProductionManager().GetProductionQueueInStudio(room.GetID())
		If productions.length = 0
			TDebugScreenPage.textFont.Draw("|b|Production Queue:|/b| Empty", x + 10, y + contentHeight)
			contentHeight :+ 12
		Else
			TDebugScreenPage.textFont.Draw("|b|Production Queue:|/b| ", x + 10, y + contentHeight)
			contentHeight :+ 10

			For local p:TProduction = eachIn GetProductionManager().GetProductionQueueInStudio(room.GetID())
				If oldHoveredObject = p
					dim = TDebugScreenPage.textFont.Draw(p.productionConcept.GetTitle(), x + 15, y + contentHeight, SColor8.White)
					TDebugScreenPage.textFont.Draw(TVTProductionStep.GetAsString(p.productionStep), x + 185, y + contentHeight, SColor8.White)
				Else
					dim = TDebugScreenPage.textFont.Draw(p.productionConcept.GetTitle(), x + 15, y + contentHeight, new SColor8(220,220,220))
					TDebugScreenPage.textFont.Draw(TVTProductionStep.GetAsString(p.productionStep), x + 185, y + contentHeight, new SColor8(220,220,220))
				EndIf
				'mark hovered?
				If THelper.MouseIn(x + 15, y + contentHeight, 290, dim.y) Then hoveredObject = p
				contentHeight :+ 10
			Next
			contentHeight :+ 2
		EndIf

		If currentScript
			'true = including subscripts
			Local concepts:TProductionConcept[] = GetProductionConceptCollection().GetProductionConceptsByScript(currentScript, True)
			If concepts.length = 0
				TDebugScreenPage.textFont.Draw("|b|Shopping Lists/Concepts:|/b| Empty", x + 10, y + contentHeight)
				contentHeight :+ 12
			Else
				TDebugScreenPage.textFont.Draw("|b|Shopping Lists/Concepts:|/b|", x + 10, y + contentHeight)
				contentHeight :+ 10
				For Local c:TProductionConcept = EachIn concepts
					If oldHoveredObject = c
						dim = TDebugScreenPage.textFont.Draw(c.GetTitle(), x + 15, y + contentHeight, SColor8.White)
					Else
						dim = TDebugScreenPage.textFont.Draw(c.GetTitle(), x + 15, y + contentHeight, new SColor8(220,220,220))
					EndIf
					'mark hovered?
					If THelper.MouseIn(x + 15, y + contentHeight, 290, dim.y) Then hoveredObject = c

					If c.IsProductionFinished()
						'should not be displayed (if so, this is a BUG!)
						TDebugScreenPage.textFont.Draw("prod. finished", x + 185, y + contentHeight, SColor8.red)
					ElseIf c.IsProductionStarted()
						TDebugScreenPage.textFont.Draw("prod. started", x + 185, y + contentHeight, new SColor8(130,250,130))
					ElseIf c.IsUnplanned()
						TDebugScreenPage.textFont.Draw("unplanned", x + 185, y + contentHeight, SColor8.gray)
					ElseIf c.IsProduceable()
						TDebugScreenPage.textFont.Draw("produceable", x + 185, y + contentHeight, new SColor8(120,180,120))
					ElseIf c.IsPlanned()
						If c.IsBalancePaid()
							TDebugScreenPage.textFont.Draw("planned, paid)", x + 185, y + contentHeight, new SColor8(220,220,220))
						ElseIf c.IsDepositPaid()
							TDebugScreenPage.textFont.Draw("planned, deposit paid", x + 185, y + contentHeight, new SColor8(220,220,220))
						Else
							TDebugScreenPage.textFont.Draw("planned", x + 185, y + contentHeight, new SColor8(220,220,220))
						EndIf
					ElseIf c.IsGettingPlanned()
						TDebugScreenPage.textFont.Draw("getting planned)", x + 185, y + contentHeight)
					EndIf
					contentHeight :+ 10
				Next
				contentHeight :+ 2
			EndIf
		EndIf
		
		contentSize = new SVec2I(contentWidth, contentHeight)
	End Method
End Type