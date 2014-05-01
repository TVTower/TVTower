SuperStrict
Import "base.util.point.bmx"
Import "base.util.deltatimer.bmx"


Type TStaticRenderable
	Field position:TPoint = new TPoint
	Field name:string
	Field visible:int = True


	Method New()
		name = "TStaticRenderable"
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float) abstract


	Method Update:Int()
	'do nothing
	End Method


	Method IsVisible:int()
		return visible
	End Method


	Method ToString:String()
		return name
	End Method
End Type



Type TRenderable extends TStaticRenderable
	Field oldPosition:TPoint = new TPoint 	'for tweening
	Field velocity:TPoint = new TPoint

	Method New()
		name = "TRenderable"
	End Method


	Method SetVelocity(dx:float, dy:float)
		velocity.SetXY(dx, dy)
	End Method


	Method Update:Int()
		local deltaTime:Float = GetDeltaTimer().GetDelta()

		'=== UPDATE MOVEMENT ===
		'backup for tweening
		oldPosition.SetXY(position.x, position.y)
		'set new position
		position.MoveXY( deltaTime * velocity.x, deltaTime * velocity.y )
	End Method
End Type