SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.player.bmx"

Type TDebugScreenPage_CustomProductions extends TDebugScreenPage
	Global _instance:TDebugScreenPage_CustomProductions
	Field playerStudioBlocks:TDebugContentBlock[]
	Field scriptsBlock:TDebugContentBlock
	Field selectedPlayerStudioBlock:TDebugContentBlock
	Field selectedObjectBlock:TDebugContentBlock
	Field selectedObject:Object
	Field displayedPlayerID:Int
	Field selectedStudioID:Int


	Method New()
		_instance = self
	End Method

	Function GetInstance:TDebugScreenPage_CustomProductions()
		If Not _instance Then new TDebugScreenPage_CustomProductions
		Return _instance
	End Function


	Method Init:TDebugScreenPage_CustomProductions()
		RefreshDisplayedPlayer( GetShownPlayerID() )

		RefreshScripts()

		Return self
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
		If Not scriptsBlock Or Not playerStudioBlocks Then Init()

		Local playerID:Int = GetShownPlayerID()

		If playerID <> displayedPlayerID
			RefreshDisplayedPlayer(playerID)
		EndIf

		Local startY:Int = position.y
		For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
			block.Update(position.x + 5, startY)
			startY :+ block.size.y
		Next


		'identify selected/hovered elements
		selectedObject = Null
		For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
			If Not selectedObject And block.selectedObject
				selectedObject = block.selectedObject
			EndIf
			'hover overrides selection
			If block.hoveredObject
				selectedObject = block.hoveredObject
			EndIf
		Next


		'identify possibly clicked studio block
		If Not selectedObject
			startY = position.y
			Local i:Int
			For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
				'open / close
				If THelper.MouseIn(position.x + 5, startY, 20, 20) And MouseManager.IsClicked(1)
					block.open = 1 - block.open
					MouseManager.SetClickHandled(1)
				ElseIf THelper.MouseIn(position.x + 5, startY, block.size.x, block.size.y) And MouseManager.IsClicked(1)
					If selectedPlayerStudioBlock Then selectedPlayerStudioBlock.selected = False

					selectedPlayerStudioBlock = block
					block.selected = True
					block.open = True
					SelectStudio(block.room.GetID())

					MouseManager.SetClickHandled(1)
				EndIf

				startY :+ block.size.y
				i :+ 1
			Next
		EndIf

		If selectedObject
			If TScriptBase(selectedObject)
				If Not TDebugContentBlock_Script(selectedObjectBlock)
					selectedObjectBlock = new TDebugContentBlock_Script()
				EndIf
				TDebugContentBlock_Script(selectedObjectBlock).script = TScriptBase(selectedObject)
			ElseIf TProduction(selectedObject)
				If Not TDebugContentBlock_Production(selectedObjectBlock)
					selectedObjectBlock = new TDebugContentBlock_Production()
				EndIf
				TDebugContentBlock_Production(selectedObjectBlock).production = TProduction(selectedObject)
			ElseIf TProductionConcept(selectedObject)
				If Not TDebugContentBlock_ProductionConcept(selectedObjectBlock)
					selectedObjectBlock = new TDebugContentBlock_ProductionConcept()
				EndIf
				TDebugContentBlock_ProductionConcept(selectedObjectBlock).productionConcept = TProductionConcept(selectedObject)
			Else
				selectedObjectBlock = Null
			EndIf
		EndIf

		If selectedObject And selectedObjectBlock
			selectedObjectBlock.Update(position.x + 320, position.y)
		EndIf

		scriptsBlock.Update(position.x + 320, position.y)
	End Method


	Method Render()
		If Not scriptsBlock Or Not playerStudioBlocks Then Init()

		Local startY:Int = position.y
		For Local block:TDebugContentBlock = EachIn playerStudioBlocks
			block.Draw(position.x + 5, startY)
			startY :+ block.size.y
		Next

		scriptsBlock.Draw(position.x + 320, position.y)

		If selectedObject And selectedObjectBlock
			selectedObjectBlock.Draw(position.x + 320, position.y)
		EndIf
	End Method


	Method SelectStudio(roomID:Int)
		selectedStudioID = roomID
	End Method
	

	Method RefreshDisplayedPlayer(playerID:Int, force:Int = False)
		If playerID <> displayedPlayerID Or force
			RefreshPlayerStudios(playerID)
		EndIf
		displayedPlayerID = playerID
	End Method


	Method RefreshPlayerStudios(playerID:Int)
		Local rooms:TRoomBase[] = GetRoomBaseCollection().GetAllByDetails("studio", "", playerID)
		If rooms.length <> playerStudioBlocks.length 
			playerStudioBlocks = playerStudioBlocks[.. rooms.length]
		EndIf

		Local i:Int
		For Local room:TRoomBase = Eachin rooms
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
'		For Local script:TScript = Eachin GetScriptCollection().entries.Values() ' .GetUsedScriptList()
'		Next
	End Method

rem
Allgemein:
- Einkaufslisten - mit Status
- laufende Produktionen -> welches Studio?
- Studio -> Laufende Produktion? 
endrem
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
		For Local script:TScript = Eachin GetScriptCollection().entries.Values() ' .GetUsedScriptList()
			'ignore episodes and only expose them if parent selected?
			If script.IsEpisode() Then Continue
			
			'enable these lines to filter for specific owners
			'eg.: only players and vendor
			If Not script.IsOwned() Or script.GetOwner() < 0 Then Continue

			TDebugScreenPage.textFont.Draw(script.GetTitle(), x + 5, y + contentHeight)
			Local ownerText:String
			Local locText:String
			If script.IsOwned()
				Local ownerID:Int = script.GetOwner()
				If ownerID = TOwnedGameObject.OWNER_VENDOR
					ownerText = "Vendor"
				ElseIf ownerID > 0
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

					If Not locText Then locText = "UNKNOWN"
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
	Field open:Int = True


	Method New(room:TRoomBase)
		self.room = room
	End Method


	Method Update(x:Int, y:Int) override
		Super.Update(x, y)

		' splitting logic from rendering this way (marking hovered element
		' during DrawContent() can lead to slight inaccuracies on low FPS
		' - but it keeps required code amount low and should do for our
		' "dev/debug purposes"
		If hoveredObject And MouseManager.IsClicked(1)
			selectedObject = hoveredObject
			'print "clicked on obj"
		EndIf
	End Method


	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 300
		Local contentHeight:Int = 0
		Local dim:SVec2I

		Local oldHoveredObject:Object = hoveredObject
		hoveredObject = Null

		Local highlightToggle:Int = False
		If THelper.MouseIn(x + 5, y + contentHeight, 20, 20)
			highlightToggle = True
		EndIf

		If Not open
			If highlightToggle
				TDebugScreenPage.textFont.Draw("[+]", x + 5, y + contentHeight, SColor8.White)
			Else
				TDebugScreenPage.textFont.Draw("[+]", x + 5, y + contentHeight, new SColor8(220,220,220))
			EndIf
			TDebugScreenPage.textFont.Draw("|b|"+room.GetName() + "|/b| (size: " + room.GetSize()+", ID: "+room.GetID()+")", x + 20, y + contentHeight)
			contentHeight :+ 12
		Else
			If highlightToggle
				TDebugScreenPage.textFont.Draw("[-]", x + 5, y + contentHeight, SColor8.White)
			Else
				TDebugScreenPage.textFont.Draw("[-]", x + 5, y + contentHeight, new SColor8(220,220,220))
			EndIf
			TDebugScreenPage.textFont.Draw("|b|"+room.GetName() + "|/b| (size: " + room.GetSize()+", ID: "+room.GetID()+")", x + 20, y + contentHeight)
			contentHeight :+ 12
			Local currentScript:TScriptBase = RoomHandler_Studio.GetInstance().GetCurrentStudioScript(room.GetID())
			If Not currentScript
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

				For Local p:TProduction = eachIn GetProductionManager().GetProductionQueueInStudio(room.GetID())
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
		EndIf

		contentSize = new SVec2I(contentWidth, contentHeight)
	End Method
End Type