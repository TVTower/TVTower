SuperStrict
Import "common.misc.plannerlist.base.bmx"
Import "game.programme.adcontract.bmx"
Import "game.player.programmecollection.bmx"
Import "game.game.base.bmx"
Import "game.screen.programmeplanner.gui.bmx"


'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist Extends TPlannerList
	Field hoveredAdContract:TAdContract = Null

	Method Create:TgfxContractlist(x:Int, y:Int)
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()

		'right align the list
		Pos.SetXY(x - entrySize.GetX(), y)

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		entriesRect = New TRectangle.Init(Pos.GetX(), Pos.GetY(), entrySize.GetX(), 0)
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		entriesRect.dimension.y :+ GameRules.maxContracts * entrySize.GetY()
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		Return Self
	End Method


	Method Draw:Int()
		If Not enabled Or Self.openState < 1 Then Return False

		If Not owner Then Return False

		Local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		Local currX:Int = entriesRect.GetX()
		Local currY:Int = entriesRect.GetY()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner)
		'draw slots, even if empty
		For Local i:Int = 0 Until 10 'GameRules.maxContracts
			Local contract:TAdContract = programmeCollection.GetAdContractAtIndex(i)

			Local entryPositionType:String = "entry"
			If i = 0 Then entryPositionType = "first"
			If i = GameRules.maxContracts-1 Then entryPositionType = "last"

		
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+".default").draw(currX,currY)


			'=== DRAW TAPE===
			If contract
				local drawType:string = "default"
				'light emphasize
				if contract.GetDaysLeft() <= 1 then drawType = "planned"
				'strong emphasize
				if contract.GetDaysLeft() <= 0 then SetColor 255,220,220
				
				'hovered - draw hover effect if hovering
				If THelper.MouseIn(currX, currY, int(entrySize.GetX()), int(entrySize.GetY())-1)
					GetSpriteFromRegistry("gfx_programmetape_movie.hovered").draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_movie."+drawType).draw(currX + 8, currY+1)
				EndIf

				if contract.GetDaysLeft() <= 0 then SetColor 255,255,255
			
				if TVTDebugInfos
					font.drawBlock(contract.GetProfit() +CURRENCYSIGN+" @ "+ contract.GetMinAudience(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
				else
					font.drawBlock(contract.GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
				endif
			EndIf


			'advance to next line
			currY:+ entrySize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = GameRules.maxContracts-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next
	End Method


	Method Update:Int()
		'gets repopulated if an contract is hovered
		hoveredAdContract = Null

		If Not enabled Then Return False

		If Not owner Then Return False

		If Self.openState >= 1
			Local currY:Int = entriesRect.GetY() + GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

			Local programmeCollection:TPlayerProgrammeCollection = GetPlayerProgrammeCollection(owner)
			For Local i:Int = 0 Until GameRules.maxContracts
				Local contract:TAdContract = programmeCollection.GetAdContractAtIndex(i)

				If contract And THelper.MouseIn(int(entriesRect.GetX()), currY, int(entrySize.GetX()), int(entrySize.GetY())-1)
					'store for outside use (eg. displaying a sheet)
					hoveredAdContract = contract

					GetGameBase().cursorstate = 1
					'only interact if allowed
					If clicksAllowed
						If MOUSEMANAGER.IsShortClicked(1)
							New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TAdvertisement.Create(contract), "programmePlanner" ).drag()
							MOUSEMANAGER.resetKey(1)
							SetOpen(0)
						EndIf
					EndIf
				EndIf

				'next tape
				currY :+ entrySize.y
			Next
		EndIf

		If MOUSEMANAGER.IsClicked(2) or MouseManager.IsLongClicked(1)
			SetOpen(0)
			MOUSEMANAGER.resetKey(2)
			MOUSEMANAGER.resetKey(1) 'also normal clicks
		EndIf

		'close if mouse hit outside - simple mode: so big rect
		If MouseManager.IsHit(1)
			If Not entriesRect.containsXY(MouseManager.x, MouseManager.y)
				SetOpen(0)
				'MouseManager.ResetKey(1)
			EndIf
		EndIf
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 Else enabled = 1
		Self.openState = newState
	End Method
End Type