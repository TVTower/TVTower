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
		GenerateID()
	End Method


	Method GenerateID:int()
		LastID:+1
		'assign a new id
		id = LastID
	End Method


	Method Remove:Int()
		'cleanup
	End Method


'	Method Render:Int(xOffset:Float=0, yOffset:Float=0) abstract
	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		'implement in extension
	End Method


'	Method Update:Int()
	'do nothing
'	End Method


	Method GetScreenArea:TRectangle()
		return new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
	End Method


	Method GetScreenX:Float()
		if parent
			return parent.GetScreenX() + parent.GetChildX(self) + area.GetX()
		else
			return area.GetX()
		endif
	End Method


	Method GetScreenY:Float()
		if parent
			return parent.GetScreenY() + parent.GetChildY(self) + area.GetY()
		else
			return area.GetY()
		endif
	End Method


	Method GetScreenWidth:Float()
		if parent
			'parent has auto-size wont limit the entity, so use full size
			if parent.area.GetW() < 0 then return Max(0, area.GetW())

			'variant a:
			'entity has auto-size -> cannot calculate occupied space
			'just occupy all potential space
			'if area.GetW() < 0 then return Max(0, parent.GetScreenWidth() - parent.GetChildX(self))

			'variant b:
			'just return 0 if we cannot calculate the size
			if area.GetW() < 0 then return 0

			'calculate available space of parent, or if enough left,
			'occupy all space entity wants
			local x:Int = GetScreenX() 'parent.GetScreenX() + parent.GetChildX(self)
			local x2:Int = Min(GetScreenX() + area.GetW(), parent.GetScreenX() + parent.GetScreenWidth())
			return Max(0, (x2 - x))
		endif

		return Max(0, area.GetW())
	End Method


	Method GetScreenHeight:Float()
		if parent
			'parent has auto-size wont limit the entity, so use full size
			if parent.area.GetH() < 0 then return Max(0, area.GetH())

			'variant a:
			'entity has auto-size -> cannot calculate occupied space
			'just occupy all potential space
			'if area.GetH() < 0 then return Max(0, parent.GetScreenHeight() - parent.GetChildY(self))

			'variant b:
			'just return 0 if we cannot calculate the size
			if area.GetH() < 0 then return 0

			'calculate available space of parent, or if enough left,
			'occupy all space entity wants
			local y:Int = GetScreenY() 'parent.GetScreenY() + parent.GetChildY(self)
			local y2:Int = Min(GetScreenY() + area.GetH(), parent.GetScreenY() + parent.GetScreenHeight())
			return Max(0, (y2 - y))
		endif

		return Max(0, area.GetH())
	End Method


	'return at which x position a child (or all) start
	'	returns an offset, not a screen coordinate!
	Method GetChildX:Float(child:TStaticEntity = Null)
		return 0
	End Method


	'return at which y position a child (or all) start
	'	returns an offset, not a screen coordinate!
	Method GetChildY:Float(child:TStaticEntity = Null)
		return 0
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


	'returns if the size of the entity was given
	Method HasSize:int()
		return area.GetW() > 0 and area.GetH() > 0
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