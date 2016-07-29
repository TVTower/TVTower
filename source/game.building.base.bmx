SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.util.math.bmx"


Type TBuildingBase Extends TRenderableEntity
	Global _instance:TBuildingBase

	'position at which the figure is offscren (walked out of screen
	'along the pavement)
	Const figureOffscreenX:int = -200
	'position of the start of the left wall (aka the building sprite)
	Const leftWallX:int = 127
	'position of the inner left/right side of the building
	'measured from the beginning of the sprite/leftWallX
	Const innerX:Int = 40
	Const innerX2:Int = 508
	'default door width
	Const doorWidth:int	= 19
	'height of each floor
	Const floorWidth:int = 469
	Const floorHeight:int = 73
	Const floorCount:Int = 14 '0-13
	'start of the uppermost floor - eg. add roof height
	Const uppermostFloorTop:Int = 0
	'x coord of defined slots
	'x coord is relative to "leftWallX" 
	Const doorSlot0:int	= -10
	Const doorSlot1:int	= 19
	Const doorSlot2:int	= doorSlot1 + 97
	Const doorSlot3:int	= doorSlot1 + 283
	Const doorSlot4:int	= doorslot1 + 376


	Function GetInstance:TBuildingBase()
		if not _instance then _instance = new TBuildingBase
		return _instance
	End Function
	

	Function GetDoorXFromDoorSlot:int(slot:int)
		select slot
			case 1	return doorSlot1
			case 2	return doorSlot2
			case 3	return doorSlot3
			case 4	return doorSlot4
		end select

		return 0
	End Function


	Method GetTravelDuration:int(entity:TEntity, targetX:int, targetFloor:int)
		return 0
	End Method


	Method CenterToFloor:Int(floornumber:Int)
		area.position.y = ((13 - floornumber) * floorHeight) - 115
	End Method


	'returns y of the requested floors CEILING position (upper part)
	'	coordinate is local (difference to building coordinates)
	Function GetFloorY:Int(floorNumber:Int)
		'limit floornumber to 0-(floorCount-1)
		floorNumber = Max(0, Min(floornumber,floorCount-1))

		'subtract 7 because last floor has no "splitter wall"
		Return 1 + (floorCount-1 - floorNumber) * floorHeight - 7
	End Function


	'returns y of the requested floors GROUND position (lower part)
	'	coordinate is local (difference to building coordinates)
	Function GetFloorY2:Int(floorNumber:Int)
		return GetFloorY(floorNumber) + floorHeight
	End Function


	'returns floor of a given y-coordinate (local to building coordinates)
	Method GetFloor:Int(y:Float)
		y :- uppermostFloorTop
		y = y / floorHeight
		return MathHelper.Clamp(13 - int(y), 0, 13)
	End Method


	'point ist hier NICHT zwischen 0 und 13... sondern pixelgenau...
	'also zwischen 0 und ~ 1000
	Function getFloorByPixelExactPoint:Int(point:TVec2D)
		For Local i:Int = 0 To 13
			If GetFloorY2(i) < point.y Then Return i
		Next
		Return -1
	End Function
End Type


'===== CONVENIENCE ACCESSORS =====
Function GetBuildingBase:TBuildingBase()
	return TBuildingBase.GetInstance()
End Function