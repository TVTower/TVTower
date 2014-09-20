SuperStrict
Import "common.misc.blockmoveable.bmx"
Import "common.misc.dragndrop.bmx"
Import "game.room.base.bmx"
Import "game.room.roomdoor.base.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"


'signs used in elevator-plan /room-plan
Type TRoomDoorSign Extends TBlockMoveable
	Field door:TRoomDoorBase
	Field signSlot:int = 0
	Field signFloor:int = 0
	Field imageCache:TSprite = null
	Field imageDraggedCache:TSprite	= null

	Global DragAndDropList:TList = CreateList()
	Global List:TList = CreateList()
	Global AdditionallyDragged:Int = 0
	Global eventsRegistered:Int = FALSE

	Global imageBaseName:string = "gfx_roomboard_sign_"
	Global imageDraggedBaseName:string = "gfx_roomboard_sign_dragged_"


	Method Init:TRoomDoorSign(roomDoor:TRoomDoorBase)
		if not roomDoor then return Null

		'local tmpImage:TSprite = GetSpriteFromRegistry(imageBaseName + Max(0, roomDoor.GetOwner()))
		'this base image is already loaded on sign creation
		local tmpImage:TSprite = GetSpriteFromRegistry("gfx_roomboard_sign_base")
		door = roomDoor
		dragable = 1

		Local y:Int = GetFloorY(door.onFloor)
		local x:Int = GetSlotX(door.doorSlot)

		OrigPos = new TVec2D.Init(x, y)
		StartPos = new TVec2D.Init(x, y)
		rect = new TRectangle.Init(x, y, tmpImage.area.GetW(), tmpImage.area.GetH() - 1)

		List.AddLast(self)
		SortList List

		Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 		DragAndDrop.slot = CountList(List) - 1
 		DragAndDrop.pos.setXY(x,y)
 		DragAndDrop.w = rect.GetW()
 		DragAndDrop.h = rect.GetH()

		DragAndDropList.AddLast(DragAndDrop)
 		SortList(DragAndDropList)

		'===== REGISTER EVENTS =====
		if not eventsRegistered
			'handle savegame loading (remove old gui elements)
			EventManager.registerListenerFunction("SaveGame.OnBeginLoad", onSaveGameBeginLoad)
			EventManager.registerListenerFunction("Language.onSetLanguage", onSetLanguage)
			eventsRegistered = TRUE
		endif

		Return self
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
			default Throw "TRoomDoorSign.GetSlotX(): invalid signSlot "+signSlot
		end select
		return 0
	End Function


	Function GetSlot:int(signX:int)
		select signX
			case 26		return 1
			case 208	return 2
			case 417	return 3
			case 599	return 4
			default Throw "TRoomDoorSign.GetSlot(): invalid signX "+signX
		end select
		return 0
	End Function


	'return the sign originally at the given position
	Function GetByOriginalPosition:TRoomDoorSign(signSlot:int, signFloor:int)
		For local sign:TRoomDoorSign = eachin list
			if sign.door.doorSlot = signSlot and sign.door.onFloor = signFloor
				return sign
			endif
		Next
		return Null
	End Function


	'return the sign now at the given position
	Function GetByCurrentPosition:TRoomDoorSign(signSlot:int, signFloor:int)
		For local sign:TRoomDoorSign = eachin list
			if sign.GetSlot(sign.rect.GetX()) = signSlot and sign.GetFloor(sign.rect.GetY()) = signFloor
				return sign
			endif
		Next
		return Null
	End Function
	

	'as soon as a language changes, remove the cached images
	'to get them regenerated
	Function onSetLanguage(triggerEvent:TEventBase)
		For Local obj:TRoomDoorSign = EachIn list
			obj.imageCache = null
			obj.imageDraggedCache = null
		Next
	End Function


	'as soon as a savegame gets loaded, we remove the cached images
	Function onSaveGameBeginLoad(triggerEvent:TEventBase)
		ResetImageCaches()
	End Function


	Function ResetImageCaches:int()
		For Local obj:TRoomDoorSign = EachIn list
			obj.imageCache = null
			obj.imageDraggedCache = null
		Next
	End Function


	Function ResetPositions()
		For Local obj:TRoomDoorSign = EachIn list
			obj.rect.position.CopyFrom(obj.OrigPos)
			obj.StartPos.CopyFrom(obj.OrigPos)
			obj.dragged	= 0
		Next
		TRoomDoorSign.AdditionallyDragged = 0
	End Function


	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


	Method Compare:Int(otherObject:Object)
	   Local s:TRoomDoorSign = TRoomDoorSign(otherObject)
	   If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
	   Return (dragged * 100)-(s.dragged * 100)
	End Method


	'draw the Block inclusive text
	'zeichnet den Block inklusive Text
	Method Draw()
		SetColor 255,255,255;dragable=1  'normal

		If dragged = 1
			If AdditionallyDragged > 0 Then SetAlpha 1- 1/AdditionallyDragged * 0.25
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
			imageCache.Draw(rect.GetX(),rect.GetY())
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


	Function DropBackDraggedSigns:Int()
		For Local locObj:TRoomDoorSign = EachIn List
			If not locObj then continue
			If not locObj.dragged then continue

			locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			locObj.dragged = False
		Next
	End Function
	

	Function UpdateAll(DraggingAllowed:int)
		'reset additional dragged objects
		AdditionallyDragged = 0
		'sort blocklist
		SortList(List)
		'reorder: first are dragged obj then not dragged
		ReverseList(list)

		For Local locObj:TRoomDoorSign = EachIn List
			If not locObj then continue

			If locObj.dragged
				If locObj.StartPosBackup.y = 0
					LocObj.StartPosBackup.CopyFrom(LocObj.StartPos)
				EndIf
			EndIf
			'block is dragable
			If DraggingAllowed And locObj.dragable
				'if right mbutton clicked and block dragged: reset coord of block
				If MOUSEMANAGER.IsHit(2) And locObj.dragged
					locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
					locObj.dragged = False
					MOUSEMANAGER.resetKey(2)
				EndIf

				'if left mbutton clicked: drop, replace with underlaying block...
				If MouseManager.IsHit(1)
					'search for underlaying block (we have a block dragged already)
					If locObj.dragged
						'obj over old position - drop ?
						If THelper.IsIn(MouseManager.x,MouseManager.y,LocObj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.rect.GetW(),locobj.rect.GetH())
							locObj.dragged = False
						EndIf

						'want to drop in origin-position
						If locObj.containsCoord(MouseManager.x, MouseManager.y)
							locObj.dragged = False
							MouseManager.resetKey(1)
						'not dropping on origin: search for other underlaying obj
						Else
							For Local OtherLocObj:TRoomDoorSign = EachIn TRoomDoorSign.List
								If not OtherLocObj then continue
								If OtherLocObj.containsCoord(MouseManager.x, MouseManager.y) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
'											If game.networkgame Then
'												Network.SendMovieAgencyChange(Network.NET_SWITCH, GetPlayerCollection().playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
'			  								End If
									locObj.SwitchBlock(otherLocObj)
									MouseManager.resetKey(1)
									Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
								EndIf
							Next
						EndIf		'end: drop in origin or search for other obj underlaying
					Else			'end: an obj is dragged
						If LocObj.containsCoord(MouseManager.x, MouseManager.y)
							locObj.dragged = 1
							MouseManager.resetKey(1)
						EndIf
					EndIf
				EndIf 				'end: left mbutton clicked
			EndIf					'end: dragable block and player or movieagency is owner

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TRoomDoorSign.AdditionallyDragged :+1
				Local displacement:Int = AdditionallyDragged *5
				locObj.setCoords(MouseManager.x - locObj.rect.GetW()/2 - displacement, 11+ MouseManager.y - locObj.rect.GetH()/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			EndIf
		Next
		ReverseList list 'reorder: first are not dragged obj
	End Function


	Function DrawAll()
		SortList List
		'draw background sprites
		For Local sign:TRoomDoorSign = EachIn List
			GetSpriteFromRegistry("gfx_roomboard_sign_bg").Draw(sign.OrigPos.x + 20, sign.OrigPos.y + 6)
		Next
		'draw actual sign
		For Local sign:TRoomDoorSign = EachIn List
			sign.Draw()
		Next
	End Function
End Type
