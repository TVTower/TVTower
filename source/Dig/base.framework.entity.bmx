SuperStrict
Import "base.util.rectangle.bmx"
Import "base.util.deltatimer.bmx"


Type TStaticEntity
	Field area:TRectangle = new TRectangle
	Field name:string
	Field visible:int = True
	Field id:int = 0
	Field parent:TStaticEntity = null
	Global LastID:int = 0


	Method New()
		name = "TStaticEntity"
	End Method


	Method GenerateID:int()
		LastID:+1
		'assign a new id
		id = LastID
	End Method
	


	Method Render:Int(xOffset:Float=0, yOffset:Float=0) abstract


'	Method Update:Int()
	'do nothing
'	End Method


	Method GetX:Float()
		if parent then return parent.GetX() + area.GetX()
	End Method


	Method GetY:Float()
		if parent then return parent.GetY() + area.GetY()
	End Method


	Method SetParent:Int(parent:TStaticEntity)
		self.parent = parent
	End Method


	Method SetVisible:int(bool:int=True)
		visible = bool
	End Method


	Method IsVisible:int()
		return visible
	End Method


	Method ToString:String()
		return name
	End Method
End Type



Type TEntity extends TStaticEntity
	'for tweening
	Field oldPosition:TVec2D = new TVec2D
	'moving direction
	Field velocity:TVec2D = new TVec2D
	'entity specific speedFactor. If < 0 then worldSpeedFactor gets used
	Field worldSpeedFactor:Float = -1.0
	'a world speed factor of 1.0 means realtime, 2.0 = fast forward 
	Global globalWorldSpeedFactor:Float = 1.0


	Method New()
		name = "TEntity"
	End Method


	Method GetWorldSpeedFactor:float()
		if worldSpeedFactor < 0 then return globalWorldSpeedFactor
		return worldSpeedFactor
	End Method


	Method SetVelocity(dx:float, dy:float)
		velocity.SetXY(dx, dy)
	End Method


	Method GetVelocity:TVec2D()
		return velocity
	End Method


	Method Update:Int()
		local deltaTime:Float = GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()

		'=== UPDATE MOVEMENT ===
		'backup for tweening
		oldPosition.SetXY(area.position.x, area.position.y)
		'set new position
		area.position.AddXY( deltaTime * GetVelocity().x, deltaTime * GetVelocity().y )
	End Method
End Type