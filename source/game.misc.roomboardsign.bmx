SuperStrict
Import "common.misc.blockmoveable.bmx"
Import "common.misc.dragndrop.bmx"
Import "game.room.base.bmx"
Import "game.room.roomdoor.base.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"


Type TRoomBoard
	Field DragAndDropList:TList = CreateList()
	Field List:TList = CreateList()
	Field AdditionallyDragged:Int = 0
	Field slotMax:int = 4
	Field floorMax:int = 13
	Global _eventsRegistered:Int = FALSE
	Global _instance:TRoomBoard


	Function GetInstance:TRoomBoard()
		if not _instance then _instance = new TRoomBoard
		return _instance
	End Function


	Method New()
		'===== REGISTER EVENTS =====
		If Not _eventsRegistered
			'handle savegame loading (remove old gui elements)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage)

			_eventsRegistered = TRUE
		EndIf
	End Method


	Method Reset:int()
		List.Clear()
		AdditionallyDragged = 0
		DragAndDropList.Clear()
	End Method


	Method AddSign:int(sign:TRoomBoardSign)
		List.AddLast(sign)
		List.Sort()

		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 		DragAndDrop.slot = List.Count() - 1
 		DragAndDrop.pos.CopyFrom(sign.StartPos)
 		DragAndDrop.w = sign.rect.GetW()
 		DragAndDrop.h = sign.rect.GetH()

		DragAndDropList.AddLast(DragAndDrop)
 		DragAndDropList.Sort()
	End Method



	'as soon as a language changes, remove the cached images
	'to get them regenerated
	Function onSetLanguage(triggerEvent:TEventBase)
		GetRoomBoard().ResetImageCaches()
	End Function


	'as soon as a savegame gets loaded, we remove the cached images
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		GetRoomBoard().ResetImageCaches()
	End Function


	Method ResetImageCaches:int()
		For Local obj:TRoomBoardSign = EachIn list
			obj.imageCache = null
			obj.imageDraggedCache = null
		Next
	End Method


	Method ResetPositions()
		For Local obj:TRoomBoardSign = EachIn list
			obj.rect.position.CopyFrom(obj.OrigPos)
			obj.StartPos.CopyFrom(obj.OrigPos)
			obj.dragged	= 0
		Next
		AdditionallyDragged = 0
	End Method
	

	Function GetFloorY:int(signFloor:int)
		return 41 + (13 - signFloor) * 23
	End Function


	Function GetFloor:int(signY:int)
		return 13 - ((signY - 41) / 23)
	End Function


	Function GetSlotX:int(signSlot:int)
		select signSlot
			case 1	return 26
			case 2	return 208
			case 3	return 417
			case 4	return 599
			default Throw "TRoomBoard.GetSlotX(): invalid signSlot "+signSlot
		end select
		return 0
	End Function


	Function GetSlot:int(signX:int)
		select signX
			case 26		return 1
			case 208	return 2
			case 417	return 3
			case 599	return 4
			default Throw "TRoomBoard.GetSlot(): invalid signX "+signX
		end select
		return 0
	End Function


	Method GetSignAtIndex:TRoomBoardSign(arrayIndex:int)
		if arrayIndex >= list.count() Or arrayIndex < 0 then return Null

		return TRoomBoardSign(List.ValueAtIndex(arrayIndex))
	End Method
	
	Method GetSignById:TRoomBoardSign(id:int)
		For local sign:TRoomBoardSign = eachin list
			if sign.id = id
				return sign
			endif
		Next
		return Null
	End Method	


	'return the sign which originally was at the given position
	Method GetSignByOriginalPosition:TRoomBoardSign(signSlot:int, signFloor:int)
		For local sign:TRoomBoardSign = eachin list
			if sign.door.doorSlot = signSlot and sign.door.onFloor = signFloor
				return sign
			endif
		Next
		return Null
	End Method


	'return the sign now at the given position
	Method GetSignByCurrentPosition:TRoomBoardSign(signSlot:int, signFloor:int)
		For local sign:TRoomBoardSign = eachin list
			if GetSlot(sign.rect.GetX()) = signSlot and GetFloor(sign.rect.GetY()) = signFloor
				return sign
			endif
		Next
		return Null
	End Method


	'return the sign now at the given pixel coordinates
	Method GetSignByXY:TRoomBoardSign(x:int, y:int)
		For Local sign:TRoomBoardSign = EachIn List
			'virtual rooms
			If sign.rect.GetX() < 0 then continue

			If sign.rect.containsXY(x,y) then return sign
		Next

		Return Null
	End Method

	
	'return the sign originally at the given pixel coordinates
	Method GetSignByOriginalXY:TRoomBoardSign(x:int, y:int)
		For Local sign:TRoomBoardSign = EachIn List
			'virtual rooms
			If sign.StartPos.GetX() < 0 then continue

			local currRect:TRectangle = sign.rect.Copy()
			currRect.position.CopyFrom(sign.OrigPos)

			If currRect.containsXY(x,y) then return sign
		Next

		Return Null
	End Method

	
	'return the first sign leading to a specific room
	Method GetFirstSignByRoom:TRoomBoardSign(roomID:int)
		For local sign:TRoomBoardSign = eachin list
			if sign.door and sign.door.roomID = roomID
				return sign
			endif
		Next
		return Null
	End Method


	'switches the _current_ position of two signs
	'permanentSwitch: if true, also switches original position
	'                 (wont reset on roomboard/plan-reset)
	Method SwitchSigns:int(signA:TRoomBoardSign, signB:TRoomBoardSign, permanentSwitch:int = False)
		if not signA or not signB then return False

		signA.SwitchCoords(signB)

		if permanentSwitch then TVec2D.SwitchVecs(signA.OrigPos, signB.OrigPos)

		return True
	End Method


	Method SwitchSignPositions:int(slotA:int, floorA:int, slotB:int, floorB:int, permanentSwitch:Int = False)
		Local signA:TRoomBoardSign = GetSignByCurrentPosition(slotA, floorA)
		Local signB:TRoomBoardSign = GetSignByCurrentPosition(slotB, floorB)

		if signA
			local x:Int = GetSlotX(slotB)
			Local y:Int = GetFloorY(floorB)
			signA.rect.position.SetXY(x,y)
			signA.StartPos.SetXY(x,y)
			signA.StartPosBackup.SetXY(x,y)

			if permanentSwitch then signA.OrigPos.SetXY(x,y)
		endif

		if signB
			local x:Int = GetSlotX(slotA)
			Local y:Int = GetFloorY(floorA)
			signB.rect.position.SetXY(x,y)
			signB.StartPos.SetXY(x,y)
			signB.StartPosBackup.SetXY(x,y)

			if permanentSwitch then signB.OrigPos.SetXY(x,y)
		endif

		'at least one existed
		if signA or signB then return True
		return False
	End Method


	Method GetSignCount:int()
		return list.Count()
	End Method
	


	Method DropBackDraggedSigns:Int()
		For Local sign:TRoomBoardSign = EachIn List
			If not sign.dragged then continue

			sign.SetCoords(sign.StartPos.x, sign.StartPos.y)
			sign.dragged = False
		Next
	End Method
	

	Method UpdateSigns(DraggingAllowed:int)
		'reset additional dragged objects
		AdditionallyDragged = 0
		'sort blocklist
		SortList(List)
		'reorder: first are dragged obj then not dragged
		ReverseList(list)

		For Local sign:TRoomBoardSign = EachIn List
			If not sign then continue

			If sign.dragged
				If sign.StartPosBackup.y = 0
					sign.StartPosBackup.CopyFrom(sign.StartPos)
				EndIf
			EndIf
			'block is dragable
			If DraggingAllowed And sign.dragable
				'if right mbutton clicked and block dragged: reset coord of block
				If MOUSEMANAGER.IsHit(2) And sign.dragged
					sign.SetCoords(sign.StartPos.x, sign.StartPos.y)
					sign.dragged = False
					MOUSEMANAGER.resetKey(2)
				EndIf

				'if left mbutton clicked: drop, replace with underlaying block...
				If MouseManager.IsHit(1)
					'search for underlaying block (we have a block dragged already)
					If sign.dragged
						'obj over old position - drop ?
						If THelper.MouseIn(sign.StartPosBackup.x, sign.StartPosBackup.y, sign.rect.GetW(), sign.rect.GetH())
							sign.dragged = False
						EndIf

						'want to drop in origin-position
						If sign.containsCoord(MouseManager.x, MouseManager.y)
							sign.dragged = False
							MouseManager.resetKey(1)
						'not dropping on origin: search for other underlaying obj
						Else
							For Local otherSign:TRoomBoardSign = EachIn List
								if otherSign = sign then continue
								If otherSign.containsCoord(MouseManager.x, MouseManager.y) And otherSign.dragged = False And otherSign.dragable
'									If game.networkgame Then
'										Network.SendMovieAgencyChange(Network.NET_SWITCH, GetPlayerCollection().playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
'	  								End If
									sign.SwitchBlock(otherSign)
									MouseManager.resetKey(1)
									Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
								EndIf
							Next
						EndIf		'end: drop in origin or search for other obj underlaying
					Else			'end: an obj is dragged
						If sign.containsCoord(MouseManager.x, MouseManager.y)
							sign.dragged = 1
							MouseManager.resetKey(1)
						EndIf
					EndIf
				EndIf 				'end: left mbutton clicked
			EndIf					'end: dragable block and player or movieagency is owner

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If sign.dragged = 1
				AdditionallyDragged :+1
				Local displacement:Int = AdditionallyDragged * 5
				sign.setCoords(MouseManager.x - sign.rect.GetW()/2 - displacement, 11+ MouseManager.y - sign.rect.GetH()/2 - displacement)
			Else
				sign.SetCoords(sign.StartPos.x, sign.StartPos.y)
			EndIf
		Next
		ReverseList list 'reorder: first are not dragged obj
	End Method


	Method DrawSigns()
		SortList List
		'draw background sprites
		For Local sign:TRoomBoardSign = EachIn List
			GetSpriteFromRegistry("gfx_roomboard_sign_bg").Draw(sign.OrigPos.x + 20, sign.OrigPos.y + 6)
		Next
		'draw actual sign
		For Local sign:TRoomBoardSign = EachIn List
			sign.Draw()
		Next
	End Method
End Type

Function GetRoomBoard:TRoomBoard()
	return TRoomBoard.GetInstance()
End Function




'signs used in elevator-plan /room-plan
Type TRoomBoardSign Extends TBlockMoveable {_exposeToLua="selected"}
	Field door:TRoomDoorBase
	Field signSlot:int = 0
	Field signFloor:int = 0
	Field imageCache:TSprite = null
	Field imageDraggedCache:TSprite	= null


	Global imageBaseName:string = "gfx_roomboard_sign_"
	Global imageDraggedBaseName:string = "gfx_roomboard_sign_dragged_"


	Method Init:TRoomBoardSign(roomDoor:TRoomDoorBase)
		if not roomDoor then return Null

		'local tmpImage:TSprite = GetSpriteFromRegistry(imageBaseName + Max(0, roomDoor.GetOwner()))
		'this base image is already loaded on sign creation
		local tmpImage:TSprite = GetSpriteFromRegistry("gfx_roomboard_sign_base")
		door = roomDoor
		dragable = 1

		Local y:Int = GetRoomBoard().GetFloorY(door.onFloor)
		local x:Int = GetRoomBoard().GetSlotX(door.doorSlot)

		OrigPos = new TVec2D.Init(x, y)
		StartPos = new TVec2D.Init(x, y)
		rect = new TRectangle.Init(x, y, tmpImage.area.GetW(), tmpImage.area.GetH() - 1)

		GetRoomBoard().AddSign(self)

		Return self
	End Method


	Method IsAtOriginalPosition:int() {_exposeToLua}
		'startPos is the position of the undragged sign,
		'"originalPos" contains the position before potential switches
		if door.doorSlot <> GetRoomBoard().GetSlot(StartPos.GetX()) then return False
		if door.onFloor <> GetRoomBoard().GetFloor(StartPos.GetY()) then return False

		return True
	End Method


	Method GetOwner:int() {_exposeToLua}
		return door.GetOwner()
	End Method


	Method GetSlot:int() {_exposeToLua}
		return GetRoomBoard().GetSlot(StartPos.GetX())
	End Method


	Method GetFloor:int() {_exposeToLua}
		return GetRoomBoard().GetFloor(StartPos.GetY())
	End Method
	

	Method GetOriginalSlot:int() {_exposeToLua}
		return door.doorSlot
	End Method


	Method GetOriginalFloor:int() {_exposeToLua}
		return door.onFloor
	End Method

	
	Method GetRoomId:int() {_exposeToLua}
		return door.roomID
	End Method	


	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


	Method Compare:Int(otherObject:Object)
	   Local s:TRoomBoardSign = TRoomBoardSign(otherObject)
	   If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
	   Return (dragged * 100)-(s.dragged * 100)
	End Method


	'draw the Block inclusive text
	'zeichnet den Block inklusive Text
	Method Draw()
		SetColor 255,255,255;dragable=1  'normal

		If dragged = 1
			If GetRoomBoard().AdditionallyDragged > 0 Then SetAlpha 1.0 - 1.0/GetRoomBoard().AdditionallyDragged * 0.25
			'refresh cache if needed
			If not imageDraggedCache
				imageDraggedCache = GenerateCacheImage( GetSpriteFromRegistry(imageDraggedBaseName + Max(0, door.GetOwner())) )
			Endif
			imageDraggedCache.Draw(rect.GetX(),rect.GetY())
		Else
			'refresh cache if needed
			If not imageCache
				imageCache = GenerateCacheImage( GetSpriteFromRegistry(imageBaseName + Max(0, door.GetOwner())) )
			Endif
			'slightly tint switched signs
			if not IsAtOriginalPosition()
				SetColor 255,245,230
				imageCache.Draw(rect.GetX(),rect.GetY())
				SetColor 255,255,255
			Else
				imageCache.Draw(rect.GetX(),rect.GetY())
			EndIf
		EndIf
		SetAlpha 1
	End Method


	'generates an image containing background + text on it
	Method GenerateCacheImage:TSprite(background:TSprite)
		local newImage:Timage = background.GetImageCopy()
		Local font:TBitmapFont = GetBitmapFont("Default",10, BOLDFONT)
		TBitmapFont.setRenderTarget(newImage)
		if door.GetOwner() > 0
			font.drawBlock(door.GetOwnerName(), 22, 4, 150,15, null, TColor.CreateGrey(50), 2, 1, 0.20)
		else
			font.drawBlock(door.GetOwnerName(), 22, 4, 150,15, null, TColor.CreateGrey(100), 2, 1, 0.20)
		endif
		TBitmapFont.setRenderTarget(null)

		return new TSprite.InitFromImage(newImage, "tempCacheImage")
	End Method
End Type
