'basic type for soundsettings taking "floors" of the building into
'account
SuperStrict
Import "Dig/base.sfx.soundmanager.base.bmx"
Import "game.building.base.bmx"

Type TSfxFloorSoundBarrierSettings Extends TSfxSettings

	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TSoundSourcePosition)
		Local floorNumberSource:Int = TBuildingBase.getFloorByPixelExactPoint(source.GetCenter())
		Local floorNumberTarget:Int = TBuildingBase.getFloorByPixelExactPoint(receiver.GetCenter())
		Local floorDistance:Int = Abs(floorNumberSource - floorNumberTarget)
		'print "floorDistance: " + floorDistance + " - " + (0.5^floorDistance) + " # " + floorNumberSource + " $ " + floorNumberTarget + "  source="+source.GetCenter().toVec2D().ToString() + "  receiver="+receiver.GetCenter().toVec2D().ToString()
		'0 floors = *1  |  1 floor = *0.5  |  2 floors = *0.25 ..
		Return Super.GetVolumeByDistance(source, receiver) * (0.5^floorDistance)
	End Method
End Type
