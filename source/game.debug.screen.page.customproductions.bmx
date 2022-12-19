SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.player.bmx"



Type TDebugScreenPage_CustomProductions extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field playerStudioBlocks:TDebugContentBlock[]
	Field selectedPlayerStudioBlock:TDebugContentBlock
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
		selectedPlayerStudioBlock = Null
	End Method
	
	
	Method Activate()
		RefreshDisplayedPlayer( GetShownPlayerID(), True)
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

'		For Local b:TDebugControlsButton = EachIn buttons
'			b.Update()
'		Next

		local startY:int = position.y
		For Local block:TDebugContentBlock_Studios = EachIn playerStudioBlocks
			block.Update(position.x + 5, startY)

			If THelper.MouseIn(position.x + 5, startY, block.size.x, block.size.y) and MouseManager.IsClicked(1)
				if selectedPlayerStudioBlock Then selectedPlayerStudioBlock.selected = False

				selectedPlayerStudioBlock = block
				block.selected = True
				SelectStudio(block.room.GetID())

				MouseManager.SetClickHandled(1)
			EndIf

			startY :+ block.size.y
		Next

		If GetShownPlayerID() <> displayedPlayerID
			RefreshDisplayedPlayer( GetShownPlayerID() )
		EndIf
	End Method


	Method Render()
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		local startY:int = position.y
		For Local block:TDebugContentBlock = EachIn playerStudioBlocks
			block.Draw(position.x + 5, startY)
			startY :+ block.size.y
		Next
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
	
rem	
Allgemein:
- welche Drehbuecher haben die Spieler (Koffer, ProgrammeCollection ... ?)
- Welches Drehbuch steht in welchem Studio?
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




Type TDebugContentBlock_Studios extends TDebugContentBlock
	Field room:TRoomBase
	Field clickBoxes:SDebugClickBox[15]
	Field clickBoxesActive:int = 0
	

	Method New(room:TRoomBase)
		self.room = room
	End Method
	
	
	Function onHoverScript:Int(scriptID:Int, data:Object = Null)
	End Function

	Function onClickScript:Int(scriptID:Int, data:Object = Null)
	End Function
	
	
	Method Update(x:Int, y:Int) override
		Super.Update(x, y)
		
		For local i:int = 0 until clickBoxesActive
			clickBoxes[i].update()
		Next
	End Method
	

	Method DrawContent(x:Int, y:Int)
		'update dimensions
		Local contentWidth:Int = 300
		Local contentHeight:Int = 0
		Local dim:SVec2I
		
		clickBoxesActive = 0
		
		TDebugScreenPage.textFont.Draw("|b|"+room.GetName() + "|/b| (size: " + room.GetSize()+", ID: "+room.GetID()+")", x + 5, y + contentHeight)
		contentHeight :+ 12

		local currentScript:TScriptBase = RoomHandler_Studio.GetInstance().GetCurrentStudioScript(room.GetID())
		If not currentScript
			dim = TDebugScreenPage.textFont.Draw("|b|Script:|/b| Empty", x + 10, y + contentHeight)
			contentHeight :+ 12
		Else
			If clickBoxes[clickBoxesActive].hovered
				dim = TDebugScreenPage.textFont.Draw("|b|Script:|/b| " + currentScript.GetTitle(), x + 10, y + contentHeight, New SColor8(255,220,200))
			Else
				dim = TDebugScreenPage.textFont.Draw("|b|Script:|/b| " + currentScript.GetTitle(), x + 10, y + contentHeight)
			EndIf
			clickBoxes[clickBoxesActive].Init(new SVec2I(x + 10, y + contentHeight), dim, onHoverScript, onClickScript, currentScript.GetID())
			clickBoxesActive :+ 1
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
				TDebugScreenPage.textFont.Draw(p.productionConcept.GetTitle(), x + 15, y + contentHeight)
				TDebugScreenPage.textFont.Draw(TVTProductionStep.GetAsString(p.productionStep), x + 185, y + contentHeight)
				contentHeight :+ 10
			Next
			contentHeight :+ 2
		EndIf

		If currentScript
			'true = including subscripts
			Local concepts:TProductionConcept[] = GetProductionConceptCollection().GetProductionConceptsByScript(currentScript, True)
			if concepts.length = 0
				TDebugScreenPage.textFont.Draw("|b|Shopping Lists/Concepts:|/b| Empty", x + 10, y + contentHeight)
				contentHeight :+ 12
			Else
				TDebugScreenPage.textFont.Draw("|b|Shopping Lists/Concepts:|/b|", x + 10, y + contentHeight)
				contentHeight :+ 10
				For Local c:TProductionConcept = EachIn concepts
					TDebugScreenPage.textFont.Draw(c.GetTitle(), x + 15, y + contentHeight)
					If c.IsProductionFinished()
						'should not be displayed (if so, this is a BUG!)
						TDebugScreenPage.textFont.Draw("prod. finished", x + 185, y + contentHeight, SColor8.red)
					ElseIf c.IsProductionStarted()
						TDebugScreenPage.textFont.Draw("prod. started", x + 185, y + contentHeight, SColor8.green)
					ElseIf c.IsUnplanned()
						TDebugScreenPage.textFont.Draw("unplanned", x + 185, y + contentHeight, SColor8.gray)
					ElseIf c.IsProduceable()
						TDebugScreenPage.textFont.Draw("produceable", x + 185, y + contentHeight, SColor8.darkgreen)
					ElseIf c.IsPlanned()
						If c.IsBalancePaid()
							TDebugScreenPage.textFont.Draw("planned, paid)", x + 185, y + contentHeight)
						ElseIf c.IsDepositPaid()
							TDebugScreenPage.textFont.Draw("planned, deposit paid", x + 185, y + contentHeight)
						Else
							TDebugScreenPage.textFont.Draw("planned", x + 185, y + contentHeight)
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