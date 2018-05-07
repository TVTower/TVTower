Rem
	====================================================================
	Basic entity class
	====================================================================

	Entities are objects in your game / app.

	The collection contains various entity-types depending on whether
	the object needs to move or is a static one.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2018 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import "base.framework.entity.base.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.deltatimer.bmx"




Type TRenderableEntity extends TEntityBase
	Field area:TRectangle = new TRectangle
	Field name:string
	Field visible:int = True
	Field parent:TRenderableEntity = null
	Field childEntities:TRenderableEntity[]
	Field childOffsets:TVec2D[]

	Field _entityOptions:int = 0
	Const OPTION_IGNORE_PARENT_SCREENLIMIT:int = 1
	Const OPTION_IGNORE_PARENT_SCREENCOORDS:int = 2


	Method New()
		name = "TRenderableEntity"
	End Method


	Method GenerateGUID:string()
		return "renderableentity-"+id
	End Method


	Method hasEntityOption:Int(option:Int)
		Return (_entityOptions & option) <> 0
	End Method


	Method setEntityOption(option:Int, enable:Int=True)
		If enable
			_entityOptions :| option
		Else
			_entityOptions :& ~option
		EndIf
	End Method


	Method HasChild:int(child:TRenderableEntity)
		for local c:TRenderableEntity = EachIn childEntities
			if child = c then return True
		next
		return False
	End Method


	Method AddChild(child:TRenderableEntity, childOffset:TVec2D = null, index:int = -1)
		if not child then return
		if not childEntities then childEntities = new TRenderableEntity[0]
		if not childOffsets then childOffsets = new TVec2D[0]

		if not childOffset then childOffset = new TVec2D.Init()

		if index < 0 then index = childEntities.length
		if index >= childEntities.length
			childEntities :+ [child]
			childOffsets :+ [childOffset]
		else
			childEntities = childEntities[.. index] + [child] + childEntities[index ..]
			childOffsets = childOffsets[.. index] + [childOffset] + childOffsets[index ..]
		endif

		'set self as parent
		childEntities[index].SetParent(self)
	End Method


	Method RemoveChild(child:TRenderableEntity)
		if not child then return
		if not childEntities or childEntities.length = 0 then return

		local index:int = 0
		while index < childEntities.length
			if childEntities[index] = child
				'skip increasing index, the next child might be also the
				'searched one
				RemoveChildAtIndex(index)
			else
				index :+ 1
			endif
		Wend
	End Method


	Method RemoveChildAtIndex:Int(index:int = -1)
		if not childEntities or childEntities.length = 0 then return False

		if index < 0 then index = childEntities.length - 1
		'remove parent association (strong reference)
		'this makes it garbage-collectable
		childEntities[index].SetParent(null)

		if index <= 0
			childEntities = childEntities[1 ..]
			childOffsets = childOffsets[1 ..]
		elseif index >= childEntities.length - 1
			childEntities = childEntities[.. childEntities.length-1]
			childOffsets = childOffsets[.. childOffsets.length-1]
		else
			childEntities = childEntities[.. index] + childEntities[index+1 ..]
			childOffsets = childOffsets[.. index] + childOffsets[index+1 ..]
		endif

		return True
	End Method
	

	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		RenderChildren(xOffset, yOffset, alignment)
	End Method


	Method RenderAt:Int(x:Float = 0, y:Float = 0, alignment:TVec2D = Null)
		local oldPos:TVec2D = area.position.copy()
		area.position.SetXY(x,y)

		Render(0, 0, alignment)

		area.position = oldPos
	End Method


	Method Update:Int()
		UpdateChildren()
	End Method


	Method RenderChildren:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		For local i:int = 0 until childEntities.length
			if not childEntities[i] then continue
			childEntities[i].Render(xOffset + childOffsets[i].GetX(), yOffset + childOffsets[i].GetY(), alignment)
		Next
	End Method


	Method UpdateChildren:Int()
		For local child:TRenderableEntity = EachIn childEntities
			child.Update()
		Next
	End Method


	'returns whether two (Render)Entities overlap eachother visually
	Method OverlapsVisually:int(other:TRenderableEntity)
		if not other then return False
		return GetScreenBoundingBox().intersects(other.GetScreenBoundingBox())
	End Method


	Method GetX:Float()
		return area.GetX()
	End Method


	Method GetY:Float()
		return area.GetY()
	End Method


	Method GetWidth:Float()
		return area.GetW()
	End Method


	Method GetHeight:Float()
		return area.GetH()
	End Method


	Method GetBoundingBox:TRectangle()
		return area
	End Method


	Method GetScreenBoundingBox:TRectangle()
		return GetScreenArea()
	End Method


	Method GetScreenArea:TRectangle()
		return new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
	End Method


	Method GetScreenX:Float()
		if parent and not (_entityOptions & OPTION_IGNORE_PARENT_SCREENCOORDS)
			return parent.GetScreenX() + parent.GetChildX(self) + area.GetX()
		else
			return area.GetX()
		endif
	End Method


	Method GetScreenY:Float()
		if parent and not (_entityOptions & OPTION_IGNORE_PARENT_SCREENCOORDS)
			return parent.GetScreenY() + parent.GetChildY(self) + area.GetY()
		else
			return area.GetY()
		endif
	End Method


	Method GetScreenWidth:Float()
		if parent and not (_entityOptions & OPTION_IGNORE_PARENT_SCREENLIMIT)
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
		if parent and not (_entityOptions & OPTION_IGNORE_PARENT_SCREENLIMIT)
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


	'get a rectangle describing the objects area on the screen
	Method GetScreenRect:TRectangle()
			Return new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
	End Method


	'get a vector describing the objects position on the screen
	Method GetScreenPos:TVec2D()
			Return new TVec2D.Init(GetScreenX(), GetScreenY())
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
	Global globalWorldSpeedFactorMod:Float = 1.0


	Method New()
		name = "TEntity"
	End Method


	Method GenerateGUID:string()
		return "entity-"+id
	End Method


	Function GetGlobalWorldSpeedFactor:float()
		return globalWorldSpeedFactor * globalWorldSpeedFactorMod
	End Function


	'until BMX-NG allows for returned function pointers
	'Method GetCustomSpeedFactorFunc:Float()()
	'	return Null
	'End Method

	Method HasCustomSpeedFactorFunc:int()
		return False
	End Method

	Method RunCustomSpeedFactorFunc:float()
		return 0
	End Method


	Method GetWorldSpeedFactor:float()
		if worldSpeedFactor < 0
			'call the individual function if needed
			if HasCustomSpeedFactorFunc()
				return RunCustomSpeedFactorFunc() * globalWorldSpeedFactorMod
			else
				return GetGlobalWorldSpeedFactor()
			endif
		endif
		return worldSpeedFactor * globalWorldSpeedFactorMod
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


	Method GetDeltaTime:Float()
		return GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()
	End Method


	Method Move:int()
		'=== UPDATE MOVEMENT ===
		'backup for tweening
		oldPosition.SetXY(area.position.x, area.position.y)
		'set new position
		local deltaTime:Float = GetDeltaTime()
		area.position.AddXY( deltaTime * GetVelocity().x, deltaTime * GetVelocity().y )
	End Method


	Method Update:Int()
		Super.Update()
		Move()
	End Method
End Type