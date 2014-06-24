Rem
	====================================================================
	Sprite Entity
	====================================================================

	An entity containing a sprite which is updated/drawn accordingly.



	====================================================================
	LICENCE

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

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


Type TSpriteEntity extends TEntity
	Field sprite:TSprite
	Field frameAnimations:TSpriteFrameAnimationCollection


	Method New()
		name = "TSpriteEntity"
	End Method


	Method Init:TSpriteEntity(sprite:TSprite)
		SetSprite(sprite)
	End Method


	Method SetSprite:TSpriteEntity(sprite:TSprite)
		self.sprite = sprite
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0)
		'=== DRAW SPRITE ===
		local frame:int = -1
		if frameAnimations
			frame = frameAnimations.GetCurrent().GetCurrentImageFrame()
		endif
		sprite.Draw(area.position.GetX() + xOffset, area.position.GetY() + yOffset, frame)
	End Method


	Method RenderAt:Int(x:Float = 0, y:Float = 0, animationName:string="")
		'=== DRAW SPRITE ===
		local frame:int = -1
		if frameAnimations
			if animationName = ""
				frame = frameAnimations.GetCurrent().GetCurrentImageFrame()
			else
				frame = frameAnimations.Get(animationName).GetCurrentImageFrame()
			endif
		endif
		sprite.Draw(x, y, frame)
	End Method


	Method Update:Int()
		'=== UPDATE MOVEMENT ===
		Super.Update()

		'=== UPDATE ANIMATION ===
		local deltaTime:Float = GetDeltaTimer().GetDelta() * GetWorldSpeedFactor()
		if frameAnimations then frameAnimations.GetCurrent().Update(deltaTime)
	End Method


	Method GetFrameAnimations:TSpriteFrameAnimationCollection()
		if not frameAnimations then frameAnimations = new TSpriteFrameAnimationCollection
		return frameAnimations
	End Method
End Type
