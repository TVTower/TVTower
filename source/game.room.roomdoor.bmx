SuperStrict
Import "Dig/base.util.helper.bmx"
Import "Dig/base.util.interpolation.bmx"
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "game.gameconfig.bmx"
Import "game.player.base.bmx"
Import "game.building.base.sfx.bmx" 'for TsfxFloorSoundBarrierSettings
Import "game.room.roomdoor.base.bmx"
Import "game.room.roomdoor.tooltip.bmx"



Type TRoomDoorCollection extends TRoomDoorBaseCollection
	'override - create a TRoomDoorCollection instead of TRoomDoorBaseCollection
	Function GetInstance:TRoomDoorCollection()
		if not _instance
			_instance = new TRoomDoorCollection
		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		'==== ATTENTION =====
		'NEVER store _instance somewhere without paying attention
		'to this "whacky hack"
		elseif not TRoomDoorCollection(_instance)
			local oldInstance:TRoomDoorBasecollection = _instance
			_instance = New TRoomDoorCollection
			'now the new collection is the instance
			THelper.TakeOverObjectValues(oldInstance, _instance)
		endif
		return TRoomDoorCollection(_instance)
	End Function


	Method Get:TRoomDoor(id:int)
		return TRoomdoor( super.Get(id) )
	End Method


	Method UpdateTooltips:Int()
		For Local door:TRoomDoor = EachIn list
			'delete and skip if not found
			If not door
				list.remove(door)
				continue
			Endif

			if door.HasFlag(TVTRoomDoorFlag.SHOW_TOOLTIP) then door.UpdateTooltip()
		Next
	End Method


	Method DrawTooltips:Int()
		For Local door:TRoomDoor = EachIn List
			if door.HasFlag(TVTRoomDoorFlag.SHOW_TOOLTIP) then door.DrawTooltip()
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetRoomDoorCollection:TRoomDoorCollection()
	Return TRoomDoorCollection.GetInstance()
End Function




Type TRoomDoor extends TRoomDoorBase  {_exposeToLua="selected"}
	'uses description
	Field tooltip:TRoomDoorTooltip = null
	Field _soundSource:TDoorSoundSource = Null {nosave}
	Field _lastOwner:int = 1000 {nosave}
	Field _signSprite:TSprite {nosave}


	Method GenerateGUID:string()
		return "roomdoor-"+roomID+"-"+doorSlot+"-"+onFloor
	End Method


	'create room and use preloaded image
	Method Init:TRoomDoor(roomID:int, doorSlot:int=-1, onFloor:Int=0, doorType:Int=-1)
		'assign variables
		self.roomID = roomID

		DoorTimer.setInterval( TRoomBase.ChangeRoomSpeed )

		self.area = new TRectangle.Init(0, 0, GetSpriteFromRegistry("gfx_building_Tueren").framew, 52)
		self.doorSlot = doorSlot
		self.doorType = doorType
		self.onFloor = onFloor

		'generate a new guid
		SetGUID("")

		Return self
	End Method


	Method GetSoundSource:TDoorSoundSource()
		if not _soundSource then _soundSource = TDoorSoundSource.Create(self)
		return _soundSource
	End Method


	Method GetRoom:TRoomBase()
		if not roomID then return Null
		return GetRoomBaseCollection().Get(roomID)
	End Method


	Method GetSignSprite:TSprite(owner:int)
		'invalidate if owner changed
		if _lastOwner <> owner
			_signSprite = null
			_lastOwner = owner
		endif

		if not _signSprite
			_signSprite = GetSpriteFromRegistry("gfx_building_sign_" + owner)
			if _signSprite.name = "defaultsprite"
				local tmpSprite:TSprite = _signSprite
				_signSprite = null
				return tmpSprite
			endif
		endif
		Return _signSprite
	End Method


	'override to play sound
	Method Close(entity:TEntity)
		Super.Close(entity)

		if not TFigureBase(entity) then return

		'timer finished is finished in Super.Close() already
		'If DoorTimer.isExpired() and not GetBuildingTime().TooFastForSound()
		if not GetBuildingTime().TooFastForSound()
			GetSoundSource().PlayCloseDoorSfx(TFigureBase(entity))
		Endif

	End Method


	'override to play sound
	Method Open(entity:TEntity)
		if not TFigureBase(entity) then return

		if not GetBuildingTime().TooFastForSound()
			GetSoundSource().PlayOpenDoorSfx(TFigureBase(entity))
		Endif

		Super.Open(entity)
	End Method


	'override to add visibility support for rooms
	Method IsVisible:int()
		if not Super.IsVisible() then return False

		'skip invisible doors (without door-sprite)
		'Ronny
		'TODO: maybe replace "invisible doors" with hotspots + room
		'      signs (if visible in elevator)
		local room:TRoomBase = GetRoom()
		If room = null then Return FALSE
		if room.IsFake() then Return False
		'above is equivalent to:
		'local roomName:string = room.GetName()
		'If roomName = "roomboard" OR roomName = "credits" OR roomName = "porter" then Return FALSE

		return True
	End Method


	Method DrawTooltip:Int()
		If not tooltip or not tooltip.enabled then return False

		tooltip.Render()
	End Method


	Method UpdateTooltip:Int()
		local room:TRoomBase = GetRoom()
		if not room then return False

		'only show tooltip if not "empty" and mouse in door-rect
		if not GameConfig.mouseHandlingDisabled
			If room.GetDescription(1) <> "" and GetPlayerBase().GetFigure().IsInBuilding() And THelper.MouseIn(Int(GetScreenRect().GetX()), Int(GetScreenRect().GetY() - area.GetH()), Int(area.GetW()), Int(area.GetH()))
				'require the player to be on that floor?
				If not (HasFlag(TVTRoomDoorFlag.TOOLTIP_ONLY_ON_SAME_FLOOR) and GetPlayerBase().GetFigure().GetFloor() <> onFloor)
					If not tooltip
						tooltip = TRoomDoorTooltip.Create("", "", 100, 140, 0, 0)
						tooltip.SetMinTitleAndContentWidth(100, 160)
						tooltip.AssignRoom(room.id)
					endif

					tooltip.Hover()
					tooltip.enabled	= 1
				EndIf
			EndIf
		endif

		If tooltip AND tooltip.enabled
			if tooltip.Update()
				'not enough space for the tooltip above the door
				If tooltip.GetHeight()-10 > GetScreenRect().GetY() - area.GetH()
					tooltip.area.SetY(GetScreenRect().y)
					tooltip.area.SetX(GetScreenRect().x - tooltip.GetWidth())
				Else
					tooltip.area.SetY(GetScreenRect().y - area.h - tooltip.GetHeight())
					tooltip.area.SetX(GetScreenRect().x + area.w/2.0 - tooltip.GetWidth()/2)
				EndIf
			else
				'delete old tooltips
				tooltip = null
			endif
		EndIf
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		local doorSprite:TSprite = GetSprite()

		'==== DRAW DOOR ====
		If IsOpen()
			'valign = 1 -> subtract sprite height
			doorSprite.Draw(xOffset + GetScreenRect().GetX(), yOffset + GetScreenRect().GetY(), getDoorType(), ALIGN_LEFT_BOTTOM)
		EndIf

		local room:TRoomBase = GetRoom()
		if not room then return False

		'==== DRAW DOOR OWNER SIGN ====
		'draw on same height than door startY
		If room.owner < 5 And room.owner >=0
			GetSignSprite(room.owner).Draw(xOffset + GetScreenRect().GetX() + 2 + doorSprite.framew, yOffset + GetScreenRect().GetY() - area.GetH())
		EndIf


		'==== DRAW OVERLAY ===
		if room.IsBlocked()
			'when a bomb is the reason - draw a barrier tape
			if room.blockedState & room.BLOCKEDSTATE_BOMB > 0

				'is there is an explosion happening in that moment?
				'attention: not gametime but time (realtime effect)
				if room.bombExplosionTime + room.bombExplosionDuration > Time.GetTimeGone()
					local bombTimeGone:int = (Time.GetTimeGone() - room.bombExplosionTime)
					local scale:float = 1.0
					scale = TInterpolation.BackOut(0.0, 1.0, Min(room.bombExplosionDuration, bombTimeGone), room.bombExplosionDuration)
					scale :* TInterpolation.BounceOut(0.0, 1.0, Min(room.bombExplosionDuration, bombTimeGone), room.bombExplosionDuration)
					GetSpriteFromRegistry("gfx_building_explosion").Draw(xOffset + GetScreenRect().GetX() + area.GetW()/2, yOffset + GetScreenRect().GetY() - doorSprite.area.GetH()/2, -1, ALIGN_CENTER_CENTER, scale)
				else
					GetSpriteFromRegistry("gfx_building_blockeddoorsign").Draw(xOffset + GetScreenRect().GetX(), yOffset + GetScreenRect().GetY(), -1, ALIGN_LEFT_BOTTOM)
				endif
			EndIf
		EndIf


		'==== DRAW DEBUG TEXT ====
		if TVTDebugInfo
			local f:TBitmapFont = GetBitmapFont("default", 10)
			local textY:int = GetScreenRect().GetY() - area.GetH() - 10
			if room.hasOccupant()
				for local figure:TFigureBase = eachin room.occupants
					f.Draw(figure.name, xOffset + GetScreenRect().GetX(), yOffset + textY)
					textY :- 8
				next
			else
				f.Draw("empty", xOffset + GetScreenRect().GetX(), yOffset + textY)
				textY :- 8
			endif
			f.Draw("room: "+roomID, xOffset + GetScreenRect().GetX(), yOffset + textY)
		endif
	End Method


	'override to return owner of room
	Method GetOwner:Int()
		local room:TRoomBase = GetRoom()
		if room then return room.owner
		return Super.GetOwner()
	End Method


	'override to add rooms description
	Method GetOwnerName:String() override
		local room:TRoomBase = GetRoom()
		if room then return room.GetDescription(1)
		return super.GetOwnerName()
	End Method


	Method GetRoomName:String() override
		local room:TRoomBase = GetRoom()
		if room then return room.name
		return super.GetRoomName
	End Method


	'override
	Method RemoveFromCollection:Int(collection:object = null)
		'if collection = GetRoomDoorBaseCollection() ...
		if _soundSource
			GetSoundManagerBase().RemoveSoundSource(_soundSource)
		EndIf
	End Method
End Type




Type TDoorSoundSource Extends TSoundSourceElement
	Field door:TRoomDoor
	Field IsGamePlayerAction:Int


	Function Create:TDoorSoundSource(door:TRoomDoor)
		Local result:TDoorSoundSource = New TDoorSoundSource
		result.door = door

		Return result
	End Function


	Method PlayOpenDoorSfx(figure:TFigureBase)
		If figure = GetPlayerBase().GetFigure()
			IsGamePlayerAction = True
			'moving into a room
			If not GetPlayerBase().IsInRoom()
				'play a sound with settings as if in the building
				PlayRandomSfx("door_open", GetPlayerBeforeDoorSettings())
			'leaving a room
			Else
				'play a sound with settings as if in the room
				PlayRandomSfx("door_open", GetPlayerBehindDoorSettings())
			EndIf
			IsGamePlayerAction = False
		Else
			PlayRandomSfx("door_open")
		EndIf
	End Method


	Method PlayCloseDoorSfx(figure:TFigureBase)
		If figure = GetPlayerBase().GetFigure()
			IsGamePlayerAction = True
			'moving into the room (from building)
			If not GetPlayerBase().IsInRoom()
				'play a sound with settings as if in the room
				PlayRandomSfx("door_close", GetPlayerBehindDoorSettings())
			'leaving a room
			Else
				'play a sound with settings as if in the room
				PlayRandomSfx("door_close", GetPlayerBeforeDoorSettings())
			EndIf
			IsGamePlayerAction = False
		Else
			PlayRandomSfx("door_close")
		EndIf
	End Method


	Method GetClassIdentifier:String()
		Return "Door"
	End Method


	Method GetCenter:SVec3D()
		'print "DoorCenter: " + int(door.area.GetX() +  door.area.GetW()/2)+", "+int(door.area.GetY() - door.area.GetH()/2) + "    GetFloorY: " + TBuildingBase.GetFloorY2(Door.area.GetY()) + " ... Floor: " + door.onFloor
		Return New SVec3D(door.area.GetX() + door.area.GetW()/2, door.area.GetY() + door.area.GetH()/2, -15)
	End Method


	Method IsMovable:Int()
		Return False
	End Method


	Method GetIsHearable:Int()
		If Not door.isVisible() Then Return False
		'If door.room.name = "" Or door.room.name = "roomboard" Or Room.name = "credits" Or Room.name = "porter" Then Return False
		Return not GetPlayerBase().IsInRoom() Or IsGamePlayerAction
	End Method


	Method GetChannelForSfx:TSfxChannel(sfx:String)
		Local result:TSfxChannel = GetSfxChannelByName(sfx)
		If result = Null
			'TLogger.log("TDoorSoundSource.GetChannelForSfx()", "SFX ~q"+sfx+"~q was not defined for room ~q"+self.room.name+"~q yet. Registered Channel for this SFX.", LOG_DEBUG)
			result = Self.AddDynamicSfxChannel(sfx, True)
		EndIf
		Return result
	End Method


	Method GetSfxSettings:TSfxSettings(sfx:String)
		Return GetDoorOptions()
	End Method


	Method OnPlaySfx:Int(sfx:String)
		Return True
	End Method


	Method GetDoorOptions:TSfxSettings()
		Local result:TSfxSettings = New TSfxFloorSoundBarrierSettings
		result.nearbyDistanceRange = 60
		result.maxDistanceRange = 500
		result.nearbyRangeVolume = 0.25
		result.midRangeVolume = 0.12
		result.minVolume = 0
		Return result
	End Method


	Method GetPlayerBeforeDoorSettings:TSfxSettings()
		Local result:TSfxSettings = GetDoorOptions()
		result.forceVolume = True
		result.forcePan = True
		result.forceDepth = True
		result.defaultVolume = 0.3
		result.defaultPan = 0
		result.defaultDepth = -1
		Return result
	End Method


	Method GetPlayerBehindDoorSettings:TSfxSettings()
		Local result:TSfxSettings = GetDoorOptions()
		result.forceVolume = True
		result.forcePan = True
		result.forceDepth = True
		result.defaultVolume = 0.3
		result.defaultPan = 0
		result.defaultDepth = 1
		Return result
	End Method
End Type
