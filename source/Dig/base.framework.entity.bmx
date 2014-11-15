SuperStrict
Import Brl.Map
Import "base.util.rectangle.bmx"
Import "base.util.deltatimer.bmx"



Type TEntityCollection
	Field entries:TMap = CreateMap()
	Field entriesCount:int = -1
	Field _entriesMapEnumerator:TNodeEnumerator {nosave}

	Method Initialize:TEntityCollection()
		entries.Clear()
		entriesCount = -1

		return self
	End Method


	Method GetByGUID:TEntityBase(GUID:String)
		Return TEntityBase(entries.ValueForKey(GUID))
	End Method


	Method GetCount:Int()
		if entriesCount >= 0 then return entriesCount

		entriesCount = 0
		For Local base:TEntityBase = EachIn entries.Values()
			entriesCount :+1
		Next
		return entriesCount
	End Method


	Method Add:int(obj:TEntityBase)
		if entries.Insert(obj.GetGUID(), obj)
			'invalidate count
			entriesCount = -1

			return TRUE
		endif

		return False
	End Method


	Method Remove:int(obj:TEntityBase)
		if obj.GetGuid() and entries.Remove(obj.GetGUID())
			'invalidate count
			entriesCount = -1

			return True
		endif

		return False
	End Method


	'=== ITERATOR ===
	'for "EachIn"-support

	'Set iterator to begin of array
	Method ObjectEnumerator:TEntityCollection()
		_entriesMapEnumerator = entries.Values()._enumerator
		'_iteratorPos = 0
		Return Self
	End Method
	

	'checks if there is another element
	Method HasNext:Int()
		Return _entriesMapEnumerator.HasNext()

		'If _iteratorPos > GetCount() Then Return False
		'Return True
	End Method


	'return next element, and increase position
	Method NextObject:Object()
		Return _entriesMapEnumerator.NextObject()

		'_iteratorPos :+ 1
		'Return entries.ValueAtIndex(_iteratorPos-1)
	End Method
End Type



Type TEntityBase {_exposeToLua="selected"}
	Field id:Int = 0	{_exposeToLua}
	Field GUID:String	{_exposeToLua}
	Global LastID:Int = 0


	Method New()
		LastID :+ 1
		'assign the new id
		id = LastID

		'create a new guid
		SetGUID("")
	End Method


	Method GetID:Int() {_exposeToLua}
		Return id
	End Method


	Method GetGUID:String() {_exposeToLua}
		if GUID="" then GUID = GenerateGUID()
		Return GUID
	End Method


	Method SetGUID:Int(GUID:String="")
		if GUID="" then GUID = GenerateGUID()
		self.GUID = GUID
	End Method


	Method GenerateGUID:string()
		return "entitybase-"+id
	End Method


	'overrideable method for cleanup actions
	Method Remove()
	End Method
End Type




Type TRenderableEntity extends TEntityBase
	Field area:TRectangle = new TRectangle
	Field name:string
	Field visible:int = True
	Field parent:TRenderableEntity = null
	Field _options:int = 0
	Const OPTION_IGNORE_PARENT_SCREENLIMIT:int = 1


	Method New()
		name = "TRenderableEntity"
	End Method


	Method GenerateGUID:string()
		return "renderableentity-"+id
	End Method


	Method setOption(option:Int, enable:Int=True)
		If enable
			_options :| option
		Else
			_options :& ~option
		EndIf
	End Method


'	Method Render:Int(xOffset:Float=0, yOffset:Float=0) abstract
	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		'implement in extension
	End Method


'	Method Update:Int()
	'do nothing
'	End Method

	'returns whether two (Render)Entities overlap eachother visually
	Method Overlaps:int(other:TRenderableEntity)
		if not other then return False
		return GetBoundingBox().intersects(other.GetBoundingBox())
	End Method


	Method GetBoundingBox:TRectangle()
		return GetScreenArea()
	End Method


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
		if parent and not _options & OPTION_IGNORE_PARENT_SCREENLIMIT
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
		if parent and not _options & OPTION_IGNORE_PARENT_SCREENLIMIT
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
	Method GetChildX:Float(child:TRenderableEntity = Null)
		return 0
	End Method


	'return at which y position a child (or all) start
	'	returns an offset, not a screen coordinate!
	Method GetChildY:Float(child:TRenderableEntity = Null)
		return 0
	End Method


	Method SetParent:Int(parent:TRenderableEntity)
		self.parent = parent
	End Method


	Method SetVisible:int(bool:int=True)
		visible = bool
	End Method


	Method SetSize(width:Float, height:Float)
		area.dimension.SetXY(width, height)
	End Method


	Method SetPosition(x:Float, y:Float)
		area.position.SetXY(x, y)
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



'a moveable and drawable entity
Type TEntity extends TRenderableEntity
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


	Method GenerateGUID:string()
		return "entity-"+id
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


	Method GetSpeed:Float()
		if not velocity then return 0
		return sqr(velocity.x^2 + velocity.y^2)
	End Method


	Method Move:int()
		local deltaTime:Float = GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()

		'=== UPDATE MOVEMENT ===
		'backup for tweening
		oldPosition.SetXY(area.position.x, area.position.y)
		'set new position
		area.position.AddXY( deltaTime * GetVelocity().x, deltaTime * GetVelocity().y )
	End Method


	Method Update:Int()
		Move()
	End Method
End Type