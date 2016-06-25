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


Type TSpriteEntity extends TEntity
	Field sprite:TSprite
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

		local spriteEntity:TSpriteEntity = new TSpriteEntity

		'assign name
		spriteEntity.name = data.GetString("name", "unknownSpriteEntity")

		'set base values
		spriteEntity.setPosition(data.GetInt("x"), data.GetInt("y"))
		spriteEntity.setSize(data.GetInt("w"), data.GetInt("h"))

		'assign sprite (might set "size" too)
		if TSprite(data.Get("sprite")) then spriteEntity.SetSprite(TSprite(data.Get("sprite")))

		'Animations configuration
		'load this before children, so children could refer to this
		'collection
		local animationsConfig:TData = data.GetData("frameAnimations")
		if animationsConfig
			spriteEntity.frameAnimations = new TSpriteFrameAnimationCollection.InitFromData(animationsConfig)
		endif

		'assign children - if one of them fails, the whole entity
		'                  has to fail!
		For local childData:TData = EachIn TData[](data.Get("childrenData", new TData[0]))
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


	'override
	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'=== DRAW SPRITE ===
		if sprite
			if frameAnimations
				local frame:int = -1
				frame = frameAnimations.GetCurrent().GetCurrentImageFrame()

				'only draw something with a valid frame
				'-> this allows to setup "-1" as frame which means
				'   "do not draw me now"
				if frame >= 0
					sprite.Draw(GetScreenX() + xOffset, GetScreenY() + yOffset, frame, alignment)
				endif
			else
				'draw the whole sprite
				sprite.Draw(GetScreenX() + xOffset, GetScreenY() + yOffset, -1, alignment)
			endif

		endif

		'=== DRAW CHILDREN ===
		RenderChildren(xOffset, yOffset, alignment)
	End Method
	

	Method RenderAnimationAt:Int(x:Float, y:Float, animationName:String, alignment:TVec2D = Null)
		if animationName = "" or not frameAnimations
			return RenderAt(x, y, alignment)
		endif
		'backup current animation
		local oldAnimationName:string = frameAnimations.currentAnimationName
		'set new animation
		frameAnimations.currentAnimationName = animationName
		'render with new animation
		RenderAt(x, y, alignment)
		'set back to backup
		frameAnimations.currentAnimationName = oldAnimationName
	End Method


	Method Update:Int()
		'=== UPDATE ANIMATION ===
		'instead of letting the animation fetch a deltatime, we use the
		'modified value including the world speed factor
		if frameAnimations then frameAnimations.Update( GetDeltaTime() )

		'=== UPDATE MOVEMENT / CHILDREN ===
		Super.Update()
	End Method


	Method GetFrameAnimations:TSpriteFrameAnimationCollection()
		if not frameAnimations then frameAnimations = new TSpriteFrameAnimationCollection
		return frameAnimations
	End Method
End Type
