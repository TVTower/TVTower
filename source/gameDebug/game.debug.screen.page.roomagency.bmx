SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.roomagency.bmx"

Type TDebugScreenPage_RoomAgency extends TDebugScreenPage
	Global _instance:TDebugScreenPage_RoomAgency
	Field roomHighlight:TRoomBase
	Field roomHovered:TRoomBase


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_RoomAgency()
		If Not _instance Then new TDebugScreenPage_RoomAgency
		Return _instance
	End Function


	Method Init:TDebugScreenPage_RoomAgency()
		Local texts:String[] = ["Rent for player X", "Kick Renter", "Re-Rent", "Block for 1 Hour", "Remove Block"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler
			button.visible = False

			buttons :+ [button]
		Next

		Local slot1:Int = buttons[0].y
		Local slot2:Int = buttons[1].y
		Local slot3:Int = buttons[2].y

		'move them together by "group"
		buttons[1].y = slot2
		buttons[2].y = slot2
		buttons[3].y = slot3
		buttons[4].y = slot3
		Return self
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For Local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Method Reset()
		roomHovered = Null
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		If roomHovered
			UpdateRoomAgencyRoomDetails(roomHovered, position.x + 510, 200)
		ElseIf roomHighlight
			UpdateRoomAgencyRoomDetails(roomHighlight, position.x + 510, 200)
		Else
			UpdateRoomAgencyRoomDetails(Null, position.x + 510, 200)
		EndIf

		UpdateRoomAgencyRoomList(position.x + 5, 13)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method UpdateRoomAgencyRoomDetails(room:TRoomBase, x:Int, y:Int, width:Int = 500, height:Int = 80)
		For Local button:TDebugControlsButton = EachIn buttons
			button.visible = False
		Next

		If room
			buttons[0].text  ="Rent for Player #" + GetShownPlayerID()

			If room.IsFreehold() Or room.IsFake()
				buttons[0].visible = False
				buttons[1].visible = False
				buttons[2].visible = False
			ElseIf room.IsRented() 
				buttons[0].visible = False
				buttons[1].visible = True
				buttons[2].visible = False
			Else
				buttons[0].visible = True
				buttons[1].visible = False
				buttons[2].visible = True
			EndIf

			If Not room.IsBlocked()
				buttons[3].visible = True
				buttons[4].visible = False
			Else
				buttons[3].visible = False
				buttons[4].visible = True
			EndIf
		EndIf
	End Method


	Method UpdateRoomAgencyRoomList(x:Int, y:Int)
		Local slotW:Int = 118
		Local slotH:Int = 16
		Local slotStepX:Int = 4
		Local slotCenterStepX:Int = 10
		Local slotStepY:Int = 4

		'offset content
		x:+ 5
		y:+ 5

		roomHovered = Null

		For Local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			Local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			If Not room Then Continue

			Local slotX:Int = x + (sign.GetOriginalSlot()-1) * (slotW + slotStepX)
			Local slotY:Int = y + (13 - sign.GetOriginalFloor()) * (slotH + slotStepY)
			If sign.GetOriginalSlot() > 2 Then slotX :+ slotCenterStepX

			If THelper.MouseIn(slotX, slotY, slotW, slotH)
				roomHovered = room
				If MouseManager.IsClicked(1)
					roomHighlight = room
					'handle clicked
					MouseManager.SetClickHandled(1)

					Exit
				EndIf
			EndIf
		Next
	End Method


	Method Render()
		RenderRoomAgencyRoomList(position.x + 5, 13)
		If roomHovered
			RenderRoomAgencyRoomDetails(roomHovered, position.x + 510, 200)
		ElseIf roomHighlight
			RenderRoomAgencyRoomDetails(roomHighlight, position.x + 510, 200)
		EndIf

		DrawBorderRect(position.x + 510, 13, 160, 65)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
	End Method


	Method RenderRoomAgencyRoomList(x:Int, y:Int)
		'- raeume
		'- selektierten "kick/block/rent" (aktueller Spieler)


		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		Local slotW:Int = 118
		Local slotH:Int = 16
		Local slotStepX:Int = 4
		Local slotCenterStepX:Int = 10
		Local slotStepY:Int = 4
		Local playerColors:TColor[4]
		For Local i:Int = 1 To 4
			playerColors[i-1] = TPlayerColor.getByOwner(i).copy().AdjustSaturation(-0.5)
		Next

		DrawBorderRect(x, y, 4*slotW + (4-1)*slotStepX + slotCenterStepX + 10, 14 * slotH + (14-1) * slotStepY + 10)
		'offset content
		x:+ 5
		y:+ 5


		For Local sign:TRoomBoardSign = EachIn GetRoomBoard().list
			Local room:TRoomBase = TRoomDoor(sign.door).GetRoom()
			If Not room Then Continue

			Local slotX:Int = x + (sign.GetOriginalSlot()-1) * (slotW + slotStepX)
			Local slotY:Int = y + (13 - sign.GetOriginalFloor()) * (slotH + slotStepY)
			If sign.GetOriginalSlot() > 2 Then slotX :+ slotCenterStepX

			'ignore never-rentable rooms
			If room.IsFake() Or room.IsFreeHold() 
				DrawBorderRect(slotX, slotY, slotW, slotH, true, true, true, true, 0,0,0, 0.5, 0.0)
				SetAlpha oldColA * 0.45
			ElseIf room.GetOwner() <= 0 And Not room.IsRentable()
				DrawBorderRect(slotX, slotY, slotW, slotH, true, true, true, true, 50,0,0, 0.8, 0.0)
				SetAlpha oldColA * 0.80
			EndIf


			Select room.GetOwner()
				Case 1,2,3,4
					If room.IsBlocked()
						playerColors[room.GetOwner() -1].Copy().AdjustBrightness(-0.2).SetRGBA()
					Else
						playerColors[room.GetOwner() -1].SetRGBA()
					EndIf
				Default
					If room.IsBlocked()
						SetColor 50,50,50
					ElseIf room.IsFake() Or room.IsFreeHold()
						SetColor 80,80,80
					Else
						SetColor 150,150,150
					EndIf
			End Select

			DrawRect(slotX + 1, slotY + 1, slotW - 2, slotH - 2)
			SetAlpha oldColA
			textFont.DrawBox(sign.GetOwnerName(), slotX + 2, slotY + 2, slotW - 4, slotH - 2, SColor8.White)

			SetColor(oldCol)

			If room = roomHighlight
				SetBlend LIGHTBLEND
				SetAlpha 0.15
				SetColor 255,210,190
				DrawRect(slotX + 1, slotY + 1, slotW - 2, slotH - 2)
				SetBlend ALPHABLEND
			EndIf
			If room = roomHovered
				SetBlend LIGHTBLEND
				SetAlpha 0.10
				DrawRect(slotX + 1, slotY + 1, slotW - 2, slotH - 2)
				SetBlend ALPHABLEND
			EndIf

			SetColor(oldCol)
			SetAlpha(oldColA)
		Next
	End Method


	Method RenderRoomAgencyRoomDetails(room:TRoomBase, x:Int, y:Int, width:Int = 500, height:Int = 80)
		DrawBorderRect(x, y, width, height)
		'offset content
		x:+ 5
		y:+ 5

		Local textPosX:Int = x
		Local textPosY:Int = y

		textFont.DrawSimple("Name: ", textPosX, textPosY)
		textFont.DrawSimple(room.GetDescription(1), textPosX + 50, textPosY)

		textPosY :+ 12
		textFont.DrawSimple("Size: ", textPosX, textPosY)
		textFont.DrawSimple(room.GetSize(), textPosX + 50, textPosY)
	
		textPosY :+ 12
		textFont.DrawSimple("Rentable: ", textPosX, textPosY)
		If room.IsRentable()
			textFont.DrawSimple("Yes", textPosX + 50, textPosY)
		ElseIf room.IsRentableIfNotRented()
			textFont.DrawSimple("If free", textPosX + 50, textPosY)
		Else
			textFont.DrawSimple("Never", textPosX + 50, textPosY)
		EndIf

		textPosY :+ 12
		textFont.DrawSimple("Blocked: ", textPosX, textPosY)
		If room.IsBlocked()
			textFont.DrawSimple("Yes", textPosX + 50, textPosY)
			textPosY :+ 12
			textFont.DrawSimple("till " + GetWorldTime().GetFormattedGameDate(room.GetBlockedUntilTime()), textPosX + 50, textPosY)
		Else
			textFont.DrawSimple("No", textPosX + 50, textPosY)
		EndIf
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local room:TRoomBase = GetInstance().roomHighlight
		If Not room Then print "click no room"; Return

		Select sender.dataInt
			Case 0
				If room.IsRented() Then GetRoomAgency().CancelRoomRental(room, -1)
				GetRoomAgency().BeginRoomRental(room, GetInstance().GetShownPlayerID())
				room.SetUsedAsStudio(True)

			Case 1
				GetRoomAgency().CancelRoomRental(room, -1)
				room.SetUsedAsStudio(False)

			Case 2
				room.BeginRental(room.originalOwner, room.GetRent())

			Case 3
				'room.SetBlocked(TWorldTime.HOURLENGTH, TRoomBase.BLOCKEDSTATE_RENOVATION, False)
				'we want to see a "sign", so use a bomb :D
				room.SetBlocked(TWorldTime.HOURLENGTH, TRoomBase.BLOCKEDSTATE_BOMB, False)

			Case 4
				room.SetUnblocked()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
