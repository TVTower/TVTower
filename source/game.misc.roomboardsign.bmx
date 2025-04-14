SuperStrict
Import "common.misc.blockmoveable.bmx"
Import "common.misc.dragndrop.bmx"
Import "game.room.base.bmx"
Import "game.room.roomdoor.base.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"


Type TRoomBoardBase
	'elements are not sorted (keep "indices" intact!) 
	Field list:TObjectList = New TObjectList
	'list contains the signs "sorted" by dragged and not dragged
	Field visualList:TObjectList {nosave}
	Field visualListOrderValid:Int = False {nosave}
	Field slotMax:Int = 4
	Field floorMax:Int = 13
	Field draggedSign:TRoomBoardSign = Null {nosave}
	Field clickedSign:TRoomBoardSign = Null {nosave}
	Field hoveredSign:TRoomBoardSign = Null {nosave}


	Method Initialize:Int()
		Reset()

		AddBoardSigns()
	End Method


	Method Reset:Int()
		List.Clear()
		visualList = Null
		
		hoveredSign = Null
		clickedSign = Null
		draggedSign = Null
	End Method


	Method AddBoardSigns:Int()
		For Local door:TRoomDoorBase = EachIn GetRoomDoorBaseCollection().List
			'create the sign in the roomplan (if not "invisible door")
			If door.doorType >= 0
				'print "door: " + door.GetOwnerName() + "   " + door.GetRoomName()
				Local sign:TRoomBoardSign = New TRoomBoardSign.Init(door)
				AddSign(sign)
			EndIf
		Next
	End Method


	Method AddSign:Int(sign:TRoomBoardSign)
		List.AddLast(sign)
		visualListOrderValid = False
	End Method


	Method ResetImageCaches:Int(owner:Int = -2)
		For Local obj:TRoomBoardSign = EachIn list
			If owner <> -2 And obj.GetOwner() <> owner Then Continue
			obj.imageCache = Null
			obj.imageDraggedCache = Null
		Next
	End Method


	Method ResetPositions()
		For Local obj:TRoomBoardSign = EachIn list
			obj.ResetPosition()
		Next
		visualListOrderValid = False
	End Method


	Function GetFloorY:Int(signFloor:Int)
		Return 41 + (13 - signFloor) * 23
	End Function


	Function GetFloor:Int(signY:Float)
		Return 13 - ((Int(signY) - 41) / 23)
	End Function


	Function GetSlotX:Int(signSlot:Int)
		Select signSlot
			Case 1	Return 26
			Case 2	Return 208
			Case 3	Return 417
			Case 4	Return 599
			Case -1 Return -1000
			Default Throw "TRoomBoard.GetSlotX(): invalid signSlot "+signSlot
		End Select
		Return 0
	End Function


	Function GetSlot:Int(signX:Float)
		Select Int(signX)
			Case 26		Return 1
			Case 208	Return 2
			Case 417	Return 3
			Case 599	Return 4
			Default Throw "TRoomBoard.GetSlot(): invalid signX "+signX
		End Select
		Return 0
	End Function


	Method GetSignAtIndex:TRoomBoardSign(arrayIndex:Int)
		If arrayIndex >= list.count() Or arrayIndex < 0 Then Return Null

		Return TRoomBoardSign( list.ValueAtIndex(arrayIndex) )
	End Method


	Method GetSignById:TRoomBoardSign(id:Int)
		For Local sign:TRoomBoardSign = EachIn list
			If sign.id = id
				Return sign
			EndIf
		Next
		Return Null
	End Method


	'return the sign which originally was at the given position
	Method GetSignByOriginalPosition:TRoomBoardSign(signSlot:Int, signFloor:Int)
		For Local sign:TRoomBoardSign = EachIn list
			If sign.door.doorSlot = signSlot And sign.door.onFloor = signFloor
				Return sign
			EndIf
		Next
		Return Null
	End Method


	'return the sign now at the given position
	Method GetSignByCurrentPosition:TRoomBoardSign(signSlot:Int, signFloor:Int)
		For Local sign:TRoomBoardSign = EachIn list
			If GetSlot(Int(sign.rect.GetX())) = signSlot And GetFloor(Int(sign.rect.GetY())) = signFloor
				Return sign
			EndIf
		Next
		Return Null
	End Method


	'return the sign now at the given pixel coordinates
	Method GetSignByXY:TRoomBoardSign(x:Int, y:Int)
		For Local sign:TRoomBoardSign = EachIn List
			'virtual rooms
			If sign.rect.GetX() < 0 Then Continue

			If sign.rect.containsXY(x,y) Then Return sign
		Next

		Return Null
	End Method


	'return the sign originally at the given pixel coordinates
	Method GetSignByOriginalXY:TRoomBoardSign(x:Int, y:Int)
		For Local sign:TRoomBoardSign = EachIn List
			'virtual rooms
			If sign.StartPos.x < 0 Then Continue

			If new SRect(sign.OrigPos.x, sign.OrigPos.y, sign.rect.w, sign.rect.h).containsXY(x,y) Then Return sign
		Next

		Return Null
	End Method


	'return the first sign leading to a specific room
	Method GetFirstSignByRoom:TRoomBoardSign(roomID:Int)
		For Local sign:TRoomBoardSign = EachIn list
			If sign.door And sign.door.roomID = roomID
				Return sign
			EndIf
		Next
		Return Null
	End Method


	'switches the _current_ position of two signs
	'permanentSwitch: if true, also switches original position
	'                 (wont reset on roomboard/plan-reset)
	Method SwitchSigns:Int(signA:TRoomBoardSign, signB:TRoomBoardSign, playerID:Int = 0, permanentSwitch:Int = False)
		If Not signA Or Not signB Then Return False

		signA.SwitchCoords(signB)

		If permanentSwitch Then TVec2D.SwitchVecs(signA.OrigPos, signB.OrigPos)

		If signA Then signA.MarkMoved(playerID)
		If signB Then signB.MarkMoved(playerID)

		Return True
	End Method


	Method SwitchSignPositions:Int(slotA:Int, floorA:Int, slotB:Int, floorB:Int, playerID:Int = 0, permanentSwitch:Int = False)
		Local signA:TRoomBoardSign = GetSignByCurrentPosition(slotA, floorA)
		Local signB:TRoomBoardSign = GetSignByCurrentPosition(slotB, floorB)

		If signA Then signA.MarkMoved(playerID)
		If signB Then signB.MarkMoved(playerID)

		If signA
			Local x:Int = GetSlotX(slotB)
			Local y:Int = GetFloorY(floorB)
			signA.rect.SetXY(x,y)
			signA.StartPos.SetXY(x,y)
			signA.StartPosBackup.SetXY(x,y)

			If permanentSwitch Then signA.OrigPos.SetXY(x,y)
		EndIf

		If signB
			Local x:Int = GetSlotX(slotA)
			Local y:Int = GetFloorY(floorA)
			signB.rect.SetXY(x,y)
			signB.StartPos.SetXY(x,y)
			signB.StartPosBackup.SetXY(x,y)

			If permanentSwitch Then signB.OrigPos.SetXY(x,y)
		EndIf

		'at least one existed
		If signA Or signB Then Return True
		Return False
	End Method


	Method GetSignCount:Int()
		Return list.Count()
	End Method
	
	
	Method GetOrderedVisualList:TObjectList()
		If Not visualList Or visualList.count() = 0 Then visualList = list.copy()

		If Not visualListOrderValid
			'sort dragged as last
			visualList.Sort(True, SortByDraggedState)
			visualListOrderValid = True
		EndIf
		Return visualList
	End Method
	
	
	Function SortByDraggedState:Int(o1:Object, o2:Object)
		Local r1:TRoomBoardSign = TRoomBoardSign(o1)
		Local r2:TRoomBoardSign = TRoomBoardSign(o2)
		If Not r1 Then Return -1
		If Not r2 Then Return 1

		Return (r1.dragged * 100) - (r2.dragged * 100)
'		Return r1.Compare(r2)
	End Function


	Method DropBackDraggedSigns:Int()
		Local droppedSomethingBack:Int = False
		For Local sign:TRoomBoardSign = EachIn List
			If Not sign.dragged Then Continue

			sign.SetCoords(Int(sign.StartPos.x), Int(sign.StartPos.y))
			sign.dragged = False
			droppedSomethingBack = True
			visualListOrderValid = False
		Next

		Return droppedSomethingBack
	End Method


	Method UpdateSigns(DraggingAllowed:Int)
		hoveredSign = Null
		clickedSign = Null
		draggedSign = Null

		For Local sign:TRoomBoardSign = EachIn GetOrderedVisualList().ReverseEnumerator()
			If Not sign Then Continue
			If sign.dragged
				If sign.StartPosBackup.y = 0
					sign.StartPosBackup.CopyFrom(sign.StartPos)
				EndIf
			EndIf
			'block is dragable
			If DraggingAllowed And sign.dragable
				'if right mbutton clicked and block dragged: reset coord of block
				If MOUSEMANAGER.IsClicked(2) And sign.dragged
					sign.SetCoords(Int(sign.StartPos.x), Int(sign.StartPos.y))
					sign.dragged = False
					visualListOrderValid = False
					clickedSign = Null

					If Not sign.IsAtOriginalPosition()
						sign.MarkMoved(GetPlayerBase().playerID)
					EndIf

					'avoid clicks
					'remove right click - to avoid leaving the room
					MouseManager.SetClickHandled(2)
				Else
					'if left mbutton clicked: drop, replace with underlaying block...
					If MouseManager.IsClicked(1)
						'search for underlaying block (we have a block dragged already)
						If sign.dragged
							clickedSign = sign

							'obj over old position - drop ?
							If THelper.MouseIn(Int(sign.StartPosBackup.x), Int(sign.StartPosBackup.y), Int(sign.rect.GetW()), Int(sign.rect.GetH()))
								sign.dragged = False
								visualListOrderValid = False
								clickedSign = Null
							EndIf

							'want to drop in origin-position
							If sign.containsCoord(MouseManager.x, MouseManager.y)
								sign.dragged = False
								visualListOrderValid = False
								clickedSign = Null

								'handled left click
								MouseManager.SetClickHandled(1)
							'not dropping on origin: search for other underlaying obj
							Else
								For Local otherSign:TRoomBoardSign = EachIn List
									If otherSign = sign Then Continue
									If otherSign.containsCoord(MouseManager.x, MouseManager.y) And otherSign.dragged = False And otherSign.dragable
	'									If game.networkgame Then
	'										Network.SendMovieAgencyChange(Network.NET_SWITCH, GetPlayerCollection().playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
	'	  								End If
										sign.SwitchBlock(otherSign)
										visualListOrderValid = False

										'handled left click
										MouseManager.SetClickHandled(1)
										Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
									EndIf
								Next
							EndIf		'end: drop in origin or search for other obj underlaying

							If Not sign.dragged
								If Not sign.IsAtOriginalPosition()
									sign.MarkMoved(GetPlayerBase().playerID)
								Else
									sign.lastMoveByPlayerID = 0
								EndIf
							EndIf
						Else			'end: an obj is dragged
							If sign.containsCoord(MouseManager.x, MouseManager.y)
								sign.dragged = 1
								visualListOrderValid = False

								'handled left click
								MouseManager.SetClickHandled(1)
							EndIf
						EndIf
					EndIf
				EndIf 				'end: left mbutton clicked
			EndIf					'end: dragable block and player or movieagency is owner

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If sign.dragged = 1
				Local displacement:Int = 5
				sign.SetCoords(Int(MouseManager.x - sign.rect.GetW()/2 - displacement), Int(11+ MouseManager.y - sign.rect.GetH()/2 - displacement))
			Else
				sign.SetCoords(Int(sign.StartPos.x), Int(sign.StartPos.y))
			EndIf


			If Not hoveredSign And Not sign.dragged And sign.containsCoord(MouseManager.x, MouseManager.y)
				hoveredSign = sign
			EndIf

			sign.isHovered = (hoveredSign = sign)
			sign.isClicked = (clickedSign = sign)
			
			If sign.dragged Then draggedSign = sign
		Next
	End Method


	Method DrawSigns(DraggingAllowed:Int)
		'draw background sprites
		Local bgSprite:TSprite = GetSpriteFromRegistry("gfx_roomboard_sign_bg")
		For Local sign:TRoomBoardSign = EachIn GetOrderedVisualList()
			bgSprite.Draw(sign.OrigPos.x + 20, sign.OrigPos.y + 6)
		Next
		'draw actual sign
		For Local sign:TRoomBoardSign = EachIn GetOrderedVisualList()
			sign.Draw()
		Next

		If DraggingAllowed 'roomplan
			If draggedSign
				GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
			ElseIf hoveredSign
				GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL)
			EndIf
			Rem
			For Local sign:TRoomBoardSign = EachIn list
				if sign.dragged
					GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
				elseif sign.isHovered
					GetGameBase().SetCursor(TGameBase.CURSOR_PICK_HORIZONTAL)
				endif
			Next
			endrem
		EndIf
			
		'debug
		Rem
		local hovered:TRoomBoardSign = GetSignByXY(MouseX(), MouseY())
		local hoveredOriginal:TRoomBoardSign = GetSignByOriginalXY(MouseX(), MouseY())
		'tint sign which is below the cursor
		'green: current position (should be below cursor)
		'blue: original position of that sign
		if hovered
			SetAlpha 0.5
			SetColor 0,255,0
			DrawRect(hovered.rect.GetX(), hovered.rect.GetY(), hovered.rect.GetW(), hovered.rect.GetH())
			'hovered.Draw()
			SetColor 0,0,255
			DrawRect(hovered.OrigPos.GetX(), hovered.OrigPos.GetY(), hovered.rect.GetW(), hovered.rect.GetH())
			SetColor 255,255,255
			SetAlpha 1.0
		endif
		'tint sign which belongs originally on the slot below the cursor
		'red: current position of the original sign
		if hoveredOriginal
			SetAlpha 0.5
			SetColor 255,0,0
			DrawRect(hoveredOriginal.rect.GetX(), hoveredOriginal.rect.GetY(), hoveredOriginal.rect.GetW(), hoveredOriginal.rect.GetH())
			SetColor 255,255,255
			SetAlpha 1.0
		endif
		endrem
	End Method
End Type




Type TRoomBoard Extends TRoomBoardBase
	Global _eventsRegistered:Int = False
	Global _instance:TRoomBoard


	Function GetInstance:TRoomBoard()
		If Not _instance Then _instance = New TRoomBoard
		Return _instance
	End Function


	Method New()
		'===== REGISTER EVENTS =====
		If Not _eventsRegistered
			'handle savegame loading (remove old gui elements)
			EventManager.registerListenerFunction(GameEventKeys.SaveGame_OnBeginLoad, onSaveGameBeginLoad)
			EventManager.registerListenerFunction(GameEventKeys.App_OnSetLanguage, onSetLanguage)
			EventManager.registerListenerFunction(GameEventKeys.Room_OnBeginRental, onChangeRoomOwner)
			EventManager.registerListenerFunction(GameEventKeys.Room_OnCancelRental, onChangeRoomOwner)

			_eventsRegistered = True
		EndIf
	End Method


	'as soon as a language changes, remove the cached images
	'to get them regenerated
	Function onSetLanguage:Int(triggerEvent:TEventBase)
		GetInstance().ResetImageCaches()
	End Function


	'as soon as a savegame gets loaded, we remove the cached images
	Function onSaveGameBeginLoad:Int(triggerEvent:TEventBase)
		GetInstance().ResetImageCaches()
	End Function


	'recreate image cache if a room owner changes
	Function onChangeRoomOwner:Int(triggerEvent:TEventBase)
		'reset caches of the affected signs
		Local roomOwner:Int = triggerEvent.GetData().GetInt("owner")
		GetInstance().ResetImageCaches(roomOwner)
	End Function
End Type

Function GetRoomBoard:TRoomBoard()
	Return TRoomBoard.GetInstance()
End Function




'signs used in elevator-plan /room-plan
Type TRoomBoardSign Extends TBlockMoveable {_exposeToLua="selected"}
	Field door:TRoomDoorBase
	'bitmask describing which player numbers moved the sign since reset
	Field movedByPlayers:Int = 0
	'playerID of the one who moved last
	Field lastMoveByPlayerID:Int = 0
	Field isHovered:Int = False
	Field isClicked:Int = False
	Field imageCache:TSprite = Null {nosave}
	Field imageDraggedCache:TSprite	= Null {nosave}


	Global imageBaseName:String = "gfx_roomboard_sign_"
	Global imageDraggedBaseName:String = "gfx_roomboard_sign_dragged_"


	Method GenerateGUID:String()
		Return "roomboardsign-"+id
	End Method


	Method Init:TRoomBoardSign(roomDoor:TRoomDoorBase)
		If Not roomDoor Then Return Null

		'local tmpImage:TSprite = GetSpriteFromRegistry(imageBaseName + Max(0, roomDoor.GetOwner()))
		'this base image is already loaded on sign creation
		Local tmpImage:TSprite = GetSpriteFromRegistry("gfx_roomboard_sign_base")
		door = roomDoor
		dragable = 1

		Local y:Int = GetRoomBoard().GetFloorY(door.onFloor)
		Local x:Int = GetRoomBoard().GetSlotX(door.doorSlot)

		OrigPos = New TVec2D(x, y)
		StartPos = New TVec2D(x, y)
		rect = New TRectangle.Init(x, y, tmpImage.area.GetW(), tmpImage.area.GetH() - 1)

		Return Self
	End Method


	Method CopyFrom:TRoomBoardSign(other:TRoomBoardSign)
		If Not other Then Return Self

		dragable = other.dragable
		OrigPos = other.OrigPos.Copy()
		StartPos = other.StartPos.Copy()
		rect = other.rect.Copy()

		door = other.door
		movedByPlayers = other.movedByPlayers
		lastMoveByPlayerID = other.lastMoveByPlayerID
		isHovered = other.isHovered
		isClicked = other.isClicked
		imageCache = other.imageCache
		imageDraggedCache = other.imageDraggedCache

		Return Self
	End Method


	Method Copy:TRoomBoardSign()
		Return New TRoomBoardSign.CopyFrom(Self)
	End Method


	Method Compare:Int(otherObject:Object)
		Local s:TRoomBoardSign = TRoomBoardSign(otherObject)
		If s
			Return (dragged * 100)-(s.dragged * 100)
		EndIf
		Return Super.Compare(otherObject)
	End Method


	Method IsAtOriginalPosition:Int() {_exposeToLua}
		If GetSlot() <> GetOriginalSlot() Then Return False
		If GetFloor() <> GetOriginalFloor() Then Return False

		Return True
	End Method


	Method GetOwner:Int() {_exposeToLua}
		Return door.GetOwner()
	End Method


	Method GetOwnerName:String() {_exposeToLua}
		Return door.GetOwnerName()
	End Method


	Method GetSlot:Int() {_exposeToLua}
		Return GetRoomBoard().GetSlot(StartPos.GetX())
	End Method


	Method GetFloor:Int() {_exposeToLua}
		Return GetRoomBoard().GetFloor(StartPos.GetY())
	End Method


	Method GetOriginalSlot:Int() {_exposeToLua}
		Return door.doorSlot
	End Method


	Method GetOriginalFloor:Int() {_exposeToLua}
		Return door.onFloor
	End Method


	Method GetRoomId:Int() {_exposeToLua}
		Return door.roomID
	End Method


	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


	Method ResetPosition()
		rect.SetXY(OrigPos)
		StartPos.CopyFrom(OrigPos)

		dragged	= 0
		lastMoveByPlayerID = 0
		movedByPlayers = 0

		Local roomBase:TRoomBase = GetRoomBase(door.roomID)
		If roomBase
			roomBase.roomSignMovedByPlayers = movedByPlayers
			roomBase.roomSignLastMoveByPlayerID = lastMoveByPlayerID
		EndIf
	End Method


	Method MarkMoved(playerID:Int = 0)
		'ensure "2 ^ (playerID)" does not result in a ":double"!
		Local playerBitmaskValue:Int = 1 Shl (playerID)  ' = 2^(playerID)
		movedByPlayers :| playerBitmaskValue
		lastMoveByPlayerID = playerID

		Local roomBase:TRoomBase = GetRoomBase(door.roomID)
		If roomBase
			roomBase.roomSignMovedByPlayers = movedByPlayers
			roomBase.roomSignLastMoveByPlayerID = lastMoveByPlayerID
		EndIf
	End Method


	'draw the Block inclusive text
	'zeichnet den Block inklusive Text
	Method Draw()
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()
		SetColor 255,255,255
		dragable=1  'normal

		If dragged = 1
			'refresh cache if needed
			If Not imageDraggedCache
				imageDraggedCache = GenerateCacheImage( GetSpriteFromRegistry(imageDraggedBaseName + Max(0, door.GetOwner())) )
			EndIf
			imageDraggedCache.Draw(rect.GetX(),rect.GetY())
		Else
			'refresh cache if needed
			If Not imageCache
				imageCache = GenerateCacheImage( GetSpriteFromRegistry(imageBaseName + Max(0, door.GetOwner())) )
			EndIf
			'slightly tint switched signs
			If Not IsAtOriginalPosition()
				SetColor 255,245,230
				imageCache.Draw(rect.GetX(),rect.GetY())
				SetColor(oldCol)
			Else
				imageCache.Draw(rect.GetX(),rect.GetY())
			EndIf

			If isHovered
				SetBlend LightBlend
				SetAlpha oldColA * 0.20
				SetColor 255, 240, 180
				imageCache.Draw(rect.GetX(),rect.GetY())
				SetBlend AlphaBlend
			EndIf
		EndIf
		SetColor( oldCol )
		SetAlpha( oldColA )
	End Method


	'generates an image containing background + text on it
	Method GenerateCacheImage:TSprite(background:TSprite)
		Local newImage:TImage = background.GetImageCopy()
		Local font:TBitmapFont = GetBitmapFont("Default",9, BOLDFONT)
		TBitmapFont.setRenderTarget(newImage)
		Local key:String
		Local playerId:Int = GetPlayerBase().playerID
		If Not GetPlayerBase().IsLocalHuman() Then playerId = -1
		Local doorOwner:Int = door.GetOwner()
		Select door.GetRoomName()
			Case "roomboard"
				key = "[P]"
			Case "betty"
				key = "[B]"
			Case "supermarket"
				key = "[L]"
			Case "movieagency"
				key = "[F]"
			Case "adagency"
				key = "[W]"
			Case "scriptagency"
				key = "[D]"
			Case "roomagency"
				key = "[R]"
			Case "credits"
				key = "[E]"
			Case "office"
				If playerId = doorOwner Then key = "[O]"
			Case "news"
				If playerId = doorOwner Then key = "[N]"
			Case "boss"
				If playerId = doorOwner Then key = "[C]"
			Case "archive"
				If playerId = doorOwner Then key = "[A]"
			Case "studio"
				If playerId = doorOwner Then key = "[S]"
		End Select
		If key
			If doorOwner > 0
				font.DrawBox(door.GetOwnerName(), 22, 2, 135,18, sALIGN_LEFT_TOP, New SColor8(50,50,50), EDrawTextEffect.GLOW, 0.20)
				font.DrawBox(key, 22, 2, 150,18, sALIGN_RIGHT_TOP, New SColor8(50,50,50, 150), EDrawTextEffect.GLOW, 0.20)
			Else
				font.DrawBox(door.GetOwnerName(), 22, 2, 135,18, sALIGN_LEFT_TOP, New SColor8(100,100,100), EDrawTextEffect.GLOW, 0.20)
				font.DrawBox(key, 22, 2, 150,18, sALIGN_RIGHT_TOP, New SColor8(100,100,100, 150), EDrawTextEffect.GLOW, 0.20)
			EndIf
		Else
			If doorOwner > 0
				font.DrawBox(door.GetOwnerName(), 22, 2, 150,18, sALIGN_LEFT_TOP, New SColor8(50,50,50), EDrawTextEffect.GLOW, 0.20)
			Else
				font.DrawBox(door.GetOwnerName(), 22, 2, 150,18, sALIGN_LEFT_TOP, New SColor8(100,100,100), EDrawTextEffect.GLOW, 0.20)
			EndIf
		EndIf
		TBitmapFont.setRenderTarget(Null)

		Return New TSprite.InitFromImage(newImage, "tempCacheImage")
	End Method
End Type
