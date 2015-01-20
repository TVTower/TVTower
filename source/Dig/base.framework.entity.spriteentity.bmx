Rem
	====================================================================
	Sprite Entity
	====================================================================

	An entity containing a sprite which is updated/drawn accordingly.



	====================================================================
	LICENCE

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

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
Import "base.framework.entity.bmx"
Import "base.gfx.sprite.bmx"
Import "base.gfx.sprite.frameanimation.bmx"
Import "base.util.registry.spriteloader.bmx"


Type TSpriteEntity extends TEntity
	Field sprite:TSprite
	Field childSpriteEntities:TSpriteEntity[]
	Field childOffsets:TVec2D[]
	Field frameAnimations:TSpriteFrameAnimationCollection


	Method New()
		name = "TSpriteEntity"
	End Method


	Method Init:TSpriteEntity(sprite:TSprite)
		SetSprite(sprite)
	End Method



	'create a spriteEntity using a dataset containing the needed information
	Function InitFromConfig:TSpriteEntity(data:TData)
		if not data then return Null

		'if sprite is defined but invalid, return Null (this eg. allows
		'trying to load it again after other resources)
		local spriteName:string = data.GetString("spriteName", "")
		local sprite:TSprite
		if spriteName
			sprite = GetSpriteFromRegistry(spriteName)
			if not sprite or sprite = GetRegistry().GetDefault("sprite") then return Null
		endif
		
		local spriteEntity:TSpriteEntity = new TSpriteEntity
		'assign name
		spriteEntity.name = data.GetString("name", "unknownSpriteEntity")
		'assign sprite
		if sprite then spriteEntity.SetSprite(sprite)


		'Animations configuration
		'load this before children, so children could refer to this
		'collection
		local animationsConfig:TData = data.GetData("frameAnimations")
		if animationsConfig
			spriteEntity.frameAnimations = new TSpriteFrameAnimationCollection.InitFromData(animationsConfig)
		endif

		'assign children - if one of them fails, the whole entity
		'                  has to fail!
		For local childData:TData = EachIn TData[](data.Get("childrenData"))
			local child:TSpriteEntity = InitFromConfig(childData)
			if not child
				local childName:string = childData.GetString("name", "unknownSpriteEntity")
				TLogger.Log("TSpriteEntity.InitFromConfig()", "Child ~q"+childName+"~q of ~q" + spriteEntity.name+"~q failed to load.", LOG_ERROR)
				return Null
			endif

			'create an offset rect if defined so
			local offset:TVec2D = null
			if childData.GetInt("offsetLeft", 0) <> 0 or childData.GetInt("offsetTop", 0) <> 0
				offset = new TVec2D.Init(childData.GetInt("offsetLeft", 0), childData.GetInt("offsetTop", 0))
			EndIf

			spriteEntity.AddChild(child, offset)
		Next
		
		return spriteEntity
	End Function


	Method SetSprite:TSpriteEntity(sprite:TSprite)
		self.sprite = sprite
		if sprite
			self.area.dimension.SetXY(sprite.GetWidth(), sprite.GetHeight())
		else
			self.area.dimension.SetXY(0, 0)
		endif
	End Method


	Method AddChild(child:TSpriteEntity, childOffset:TVec2D = null, index:int = -1)
		if not child then return
		if not childSpriteEntities then childSpriteEntities = new TSpriteEntity[0]
		if not childOffsets then childOffsets = new TVec2D[0]

		if not childOffset then childOffset = new TVec2D.Init()

		if index < 0 then index = childSpriteEntities.length
		if index >= childSpriteEntities.length
			childSpriteEntities :+ [child]
			childOffsets :+ [childOffset]
		else
			childSpriteEntities = childSpriteEntities[.. index] + [child] + childSpriteEntities[index ..]
			childOffsets = childOffsets[.. index] + [childOffset] + childOffsets[index ..]
		endif

		childSpriteEntities[index].SetParent(self)
	End Method


	Method RemoveChild(child:TSpriteEntity)
		if not child then return
		if not childSpriteEntities or childSpriteEntities.length = 0 then return
		
		local index:int = 0
		while index < childSpriteEntities.length
			if childSpriteEntities[index] = child
				RemoveChildAtIndex(index)
				'skip increasing index, the next child might be
				'also the searched one
			else
				index :+ 1
			endif
		Wend
	End Method


	Method RemoveChildAtIndex(index:int = -1)
		if not childSpriteEntities or childSpriteEntities.length = 0 then return

		if index < 0 then index = childSpriteEntities.length - 1
		childSpriteEntities[index].SetParent(null)
		childSpriteEntities = childSpriteEntities[.. index-1] + childSpriteEntities[index ..]
		childOffsets = childOffsets[.. index-1] + childOffsets[index ..]
	End Method
	

	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0)
		'=== DRAW SPRITE ===
		if sprite
			local frame:int = -1
			if frameAnimations
				frame = frameAnimations.GetCurrent().GetCurrentImageFrame()
			endif

			sprite.Draw(GetScreenX() + xOffset, GetScreenY() + yOffset, frame)
		endif

		'=== DRAW CHILDREN ===
		For local childIndex:int = 0 until childSpriteEntities.length
			if not childSpriteEntities[childIndex] then continue
			childSpriteEntities[childIndex].Render(xOffset + childOffsets[childIndex].GetX(), yOffset + childOffsets[childIndex].GetY())
		Next
	End Method


	Method RenderAt:Int(x:Float = 0, y:Float = 0, animationName:string="", alignment:TVec2D = null)
		'=== DRAW SPRITE ===
		if sprite
			local frame:int = -1
			if frameAnimations
				if animationName = ""
					frame = frameAnimations.GetCurrent().GetCurrentImageFrame()
				else
					frame = frameAnimations.Get(animationName).GetCurrentImageFrame()
				endif
			endif
			sprite.Draw(x, y, frame, alignment)
		endif
		
		'=== DRAW CHILDREN ===
		For local childIndex:int = 0 until childSpriteEntities.length
			if not childSpriteEntities[childIndex] then continue
			childSpriteEntities[childIndex].RenderAt(x + childOffsets[childIndex].GetX(), y + childOffsets[childIndex].GetY(), animationName, alignment)
		Next
	End Method


	Method Update:Int()
		'=== UPDATE MOVEMENT ===
		Super.Update()

		'=== UPDATE ANIMATION ===
		'instead of deltatime, we use the modified value including the
		'world speed factor
		if frameAnimations then frameAnimations.Update()

		'=== UPDATE CHILDREN ===
		For local s:TSpriteEntity = EachIn childSpriteEntities
			s.Update()
		Next
	End Method


	Method GetFrameAnimations:TSpriteFrameAnimationCollection()
		if not frameAnimations then frameAnimations = new TSpriteFrameAnimationCollection
		return frameAnimations
	End Method
End Type
