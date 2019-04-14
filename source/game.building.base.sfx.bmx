'basic type for soundsettings taking "floors" of the building into
'account
SuperStrict
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "game.building.base.bmx"

Type TSfxFloorSoundBarrierSettings Extends TSfxSettings

	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TSoundSourcePosition)
		Local floorNumberSource:Int = TBuildingBase.getFloorByPixelExactPoint(source.GetCenter().toVec2D())
		Local floorNumberTarget:Int = TBuildingBase.getFloorByPixelExactPoint(receiver.GetCenter().toVec2D())
		Local floorDistance:Int = Abs(floorNumberSource - floorNumberTarget)
'		print "floorDistance: " + floorDistance + " - " + Exponential(0.5, floorDistance) + " # " + floorNumberSource + " $ " + floorNumberTarget
		Return Super.GetVolumeByDistance(source, receiver) * Exponential(0.5, floorDistance)
	End Method

	Method Exponential:Float(base:Float, expo:Float)
'		print "Exponential1: " + base + " - " + expo
		Local result:Float = base
		If expo >= 2
			For Local i:Int = 1 To expo - 1
				result = result * base
			Next
		EndIf
'		print "Exponential2: " + result
		Return result
	End Method
End Type