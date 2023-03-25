SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.framework.entity.spriteentity.bmx"
Import "Dig/base.util.fadingstate.bmx"
Import "Dig/base.util.math.bmx"
Import "game.world.worldtime.bmx"


Type TWeatherEffectBase extends TEntity
	Field fadeState:TFadingState = new TFadingState
	'fade duration in milliseconds
	Field fadeDuration:int = 1000
	Field sprites:TSprite[]


	Method Start:int()
		'skip if already started
		if fadeState.IsOn() or fadeState.IsFadingOn() then return False

		fadeState.SetState(true, fadeDuration)
	End Method


	Method Stop:int()
		'skip if already stopped
		if fadeState.IsOff() or fadeState.IsFadingOff() then return False

		fadeState.SetState(false, fadeDuration)
	End Method


	Method SetUseSprites:Int(useSprites:TSprite[])
		'clear old
		sprites = new TSprite[0]

		for local sprite:TSprite = eachIn useSprites
			self.sprites :+ [sprite]
		Next
	End Method


	Method IsActive:int()
		return fadeState.GetState() = 1 or fadeState.IsFadingOn()
	End Method


	Method ModifySkyColor(screenColor:SColor8 var)
	End Method
End Type




Type TWeatherEffectRain extends TWeatherEffectBase
	'layer config
	Field layerVelocities:TVec2D[]
	Field layerPositions:TVec2D[]
	Field layerSprites:TSprite[]

	Field alpha:Float = 1.0
	Field alphaTarget:Float = 1.0
	Field alphaMax:Float = 0.5
	Field colorMax:int = 150

	Field windVelocity:Float = 0


	Method Init:TWeatherEffectRain(area:TRectangle, layers:int = 2, useSprites:TSprite[])
		'do nothing without sprites
		if not useSprites then return null

		'clear old
		layerVelocities = new TVec2D[0]
		layerPositions = new TVec2D[0]
		layerSprites = new TSprite[0]
		sprites = new TSprite[0]
	
		for local sprite:TSprite = eachIn useSprites
			self.sprites :+ [sprite]
		Next

		self.area = area.copy()

		for local i:int = 0 until layers
			ConfigureLayer(i+1, new TVec2D(0, 0), new TVec2D(0, 300+i*50), null)
		Next
		return self
	End Method
	

	Method ConfigureLayer(layerNumber:int, position:TVec2D, velocity:TVec2D, sprite:TSprite = null)
		'resize if needed
		if layerPositions.length < layerNumber
			layerPositions = layerPositions[.. layerNumber]
			layerVelocities = layerVelocities[.. layerNumber]
			layerSprites = layerSprites[.. layerNumber]
		endif

		'set sprite
		if sprite
			layerSprites[layerNumber-1] = sprite
		else
			if sprites.length < layerNumber
				layerSprites[layerNumber-1] = sprites[rand(0, sprites.length-1)]
			else
				layerSprites[layerNumber-1] = sprites[layerNumber-1]
			endif
		endif

		if not position then position = new TVec2D
		if not velocity then velocity = new TVec2D
		
		'move the sprite "above"
		position.AddXY(0, -layerSprites[layerNumber-1].GetHeight())
		'move the sprite a bit to the left
		position.AddXY(((layerNumber-1) * -50) mod layerSprites[layerNumber-1].GetWidth() ,0)

		'set position and velocity
		layerPositions[layerNumber-1] = position
		layerVelocities[layerNumber-1] = velocity
	End Method
	

	Method Update:int()
		If not IsActive() then return False

		For local i:int = 0 until layerPositions.length
			'move layer
			layerPositions[i].x :+ GetDeltaTimer().GetDelta() * layerVelocities[i].x * windVelocity
			layerPositions[i].y :+ GetDeltaTimer().GetDelta() * layerVelocities[i].y

			'the layer is drawn on the whole area (tiled) so go back to
			'0 as soon as it would move further than the sprites width
			if layerPositions[i].x >= layerSprites[i].GetWidth() then layerPositions[i].x = 0
			'same for height...
			if layerPositions[i].y >= 0 then layerPositions[i].y = -layerSprites[i].GetHeight()
		Next
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		If not IsActive() then return False
		
		local decreaseAmount:int = layerPositions.length-1
		local color:int

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		local useAlpha:Float = fadeState.GetFadeProgress()
		if fadeState.IsFadingOff() then useAlpha = 1.0 - useAlpha

		For local i:int = 0 until layerPositions.length
			color = colorMax * 1.0 / 1.5^(layerPositions.length-1 - i)
			SetColor(color, color, color)
			SetAlpha Float(oldA * useAlpha * alphaMax * 1.0 / 2^(layerPositions.length-1 - i))
		
			layerSprites[i].TileDraw(area.GetX() + layerPositions[i].x - layerSprites[i].GetWidth(), int(area.GetY() + layerPositions[i].y), int(area.GetW() - (layerPositions[i].x - layerSprites[i].GetWidth())), int(area.GetH() + layerSprites[i].GetHeight()))
		Next

		SetColor(oldCol)
		SetAlpha(oldA)
	End Method
End Type


Type TWeatherEffectLightningElement
	Field lifetime:Int
	Field lifetimeBase:Int
	Field direction:Byte
	Field position:SVec2I
	Field useSpritesSide:Int
	Field spriteNumber:Int
End Type


Type TWeatherEffectLightning extends TWeatherEffectBase
	Field lightnings:TObjectList = new TObjectList
	'time in milliseconds
	Field lightningLifetimeMin:int = 150
	Field lightningLifetimeMax:int = 210
	Field nextLightningTime:Long = 0
	Field nextLightningIntervalMin:int = 3500
	Field nextLightningIntervalMax:int = 7500
	Field spritesSide:TSprite[]


	Method Init:TWeatherEffectLightning(area:TRectangle, startLightnings:int = 1, useSprites:TSprite[], useSpritesSide:TSprite[])
		'do nothing without sprites
		if not useSprites then return null

'		fadeDuration = 100
		'clear old
		sprites = new TSprite[0]

		for local sprite:TSprite = eachIn useSprites
			self.sprites :+ [sprite]
		Next

		if useSpritesSide
			for local sprite:TSprite = eachIn useSpritesSide
				self.spritesSide :+ [sprite]
			Next
		endif

		self.area = area.copy()

		For local i:int = 0 until startLightnings
			AddLightning()
		Next
		
		return self
	End Method


	Method SetUseSpritesSide:Int(useSpritesSide:TSprite[])
		'clear old
		spritesSide = new TSprite[0]

		for local sprite:TSprite = eachIn useSpritesSide
			self.sprites :+ [sprite]
		Next
	End Method
	

	Method AddLightning:int()
		'lifetime in milliseconds
		local lifetime:Int = rand(lightningLifetimeMin, lightningLifetimeMax)
		local lightningElement:TWeatherEffectLightningElement = new TWeatherEffectLightningElement
		lightningElement.lifetime = lifetime
		lightningElement.lifetimeBase = lifetime

		'comfing-from-side lightning
		if spritesSide and spritesSide.length > 0 and Rand(0,10) < 3
			if rand(0,1) = 0
				lightningElement.position = New SVec2I(Int(area.GetX()), rand(int(area.y), int(area.y - rand(0,60))))
				lightningElement.direction = 0
			else
				lightningElement.position = New SVec2I(Int(area.GetX2()), rand(int(area.y), int(area.y - rand(0,60))))
				lightningElement.direction = 1
			endif
			lightningElement.useSpritesSide = 1
			lightningElement.spriteNumber =rand(0, spritesSide.length-1)
		else
			lightningElement.position = New SVec2I(rand(int(area.x), int(area.GetX2())), int(area.y) - rand(0,60))
			lightningElement.useSpritesSide = 0
			lightningElement.direction = rand(0,1)
			lightningElement.spriteNumber = rand(0, sprites.length-1)
		endif
		
		lightnings.AddLast(lightningElement)

		nextLightningTime = Time.GetTimeGone() + rand(nextLightningIntervalMin, nextLightningIntervalMax)
	End Method


	Method Update:int()
		If not IsActive() then return False

		local lifetime:Int
		local removed:TWeatherEffectLightningElement[]
		For local lightningElement:TWeatherEffectLightningElement = EachIn lightnings
			lightningElement.lifetime :- int(1000 * GetDeltaTimer().GetDelta())
			if lightningElement.lifetime < 0 then removed :+ [lightningElement]
		Next

		For local d:TWeatherEffectLightningElement = Eachin removed
			lightnings.Remove(d)
		Next

		'add a new lightning if time is near
		if nextLightningTime < Time.GetTimeGone() then AddLightning()
	End Method


	Method GetLightningAlpha:Float(lightningElement:TWeatherEffectLightningElement)
		if lightningElement.lifetimeBase - lightningElement.lifetime <= 20
			return (lightningElement.lifetimeBase - lightningElement.lifetime)/20.0
		elseif lightningElement.lifetime <= 20
			return 1.0 - (20 - lightningElement.lifetime)/20.0
		endif
		return 1.0
	End Method


	'override to brighten the sky with a active lightning
	Method ModifySkyColor(screenColor:SColor8 var)
		local maxAlpha:Float = 0.0
		For local lightningElement:TWeatherEffectLightningElement = EachIn lightnings
			'skip calculating more if already at max
			if maxAlpha >= 1.0 then continue
			
			maxAlpha = max(maxAlpha, GetLightningAlpha(lightningElement))
		Next
		
		'mix a white screen into the color
		'(max 20%, just to show the difference)
		screenColor = SColor8Helper.Mix(screenColor, SColor8.WHITE, maxAlpha*0.2)
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		If not IsActive() then return False
		
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		local effectAlpha:Float = fadeState.GetFadeProgress()
		if fadeState.IsFadingOff() then effectAlpha = 1.0 - effectAlpha

		'=== DRAW LIGHTNINGS ===
		For local lightningElement:TWeatherEffectLightningElement = eachin lightnings
			local sprite:TSprite

			if lightningElement.useSpritesSide = 1
				sprite = spritesSide[lightningElement.spriteNumber]
			else
				sprite = sprites[lightningElement.spriteNumber]
			endif
			if not sprite then continue
			
			SetAlpha(oldA * effectAlpha * GetLightningAlpha(lightningElement))

			'mirrored drawing?
			if lightningElement.direction = 1
				local oldScaleX:Float,oldScaleY:Float
				GetScale(oldScaleX, oldScaleY)
				SetScale(-1 * oldScaleX, oldScaleY)

				sprite.Draw(lightningElement.position.x, lightningElement.position.y)

				SetScale(oldScaleX, oldScaleY)
			else
				sprite.Draw(lightningElement.position.x, lightningElement.position.y)
			endif
		Next
	
		SetColor(oldCol)
		SetAlpha(oldA)	
	End Method
End Type


Type TWeatherEffectSnowFlake
	Field lifetime:Int
	Field lifetimeBase:Int
	Field spriteNumber:Int = -1
	Field direction:Byte
	Field position:SVec2F
	Field positionOld:SVec2F
	Field velocity:SVec2F
End Type




Type TWeatherEffectSnow extends TWeatherEffectBase
	Field flakes:TObjectList = New TObjectList
	Field flakeLifetimeMin:int = 3000
	Field flakeLifetimeMax:int = 6500
	Field nextFlakeTime:Long = 0
	Field nextFlakeIntervalMin:int = 150
	Field nextFlakeIntervalMax:int = 550
	Field nextFlakeEmitAmountMin:int = 3
	Field nextFlakeEmitAmountMax:int = 10
	Field flakesMax:int = 150

	Field windVelocity:Float = 0


	Method Init:TWeatherEffectSnow(area:TRectangle, startFlakes:int = 15, useSprites:TSprite[])
		'clear old
		sprites = new TSprite[0]

		for local sprite:TSprite = eachIn useSprites
			self.sprites :+ [sprite]
		Next

		self.area = area.copy()

		For local i:int = 0 until startFlakes
			AddFlake()
		Next
		nextFlakeTime = Time.GetTimeGone() + rand(nextFlakeIntervalMin, nextFlakeIntervalMax)
		
		return self
	End Method


	Method AddFlake:int()
		'do not add if already at max
		if flakes.Count() >= flakesMax then return False

		'lifetime in seconds
		local lifetime:Int = rand(flakeLifetimeMin, flakeLifetimeMax)
		local spriteNumber:int = rand(0, Max(0, sprites.length-1))
		local spriteHeight:int = 30
		local spriteWidth:int = 30
		if sprites[spriteNumber] 
			spriteHeight = sprites[spriteNumber].GetHeight()
			spriteWidth = sprites[spriteNumber].GetWidth()
		endif
		Local flake:TWeatherEffectSnowFlake = New TWeatherEffectSnowFlake
		flake.lifetime = lifetime
		flake.lifetimeBase = lifetime
		flake.spriteNumber = spriteNumber
		flake.direction = rand(0,1)

		Local windFromSideMod:Float = 1.0 + abs(windVelocity)
		Local limitLeft:Int = area.x - spriteWidth/2 - Int(75*windFromSideMod)
		Local limitRight:Int = area.GetX2() + spriteWidth/2 + Int(75*windFromSideMod)
		'if wind is from a specific direction now ... skip "outside" snow
		'we would possibly not see at all
		If windVelocity < -0.125 
			limitLeft :+ 50
		ElseIf windVelocity > 0.125 
			limitRight :+ 50
		EndIf
		Local x:Int = rand(limitLeft, limitRight)
		Local y:Int = area.y - rand(0, 150) - spriteHeight
		'if coming from "outside" we can already start a bit "later" to
		'simulate more mass of snow
		if x < area.x - spriteWidth/2 or x > area.GetX2() + spriteWidth/2
			y = area.y + rand(50, 150) - spriteHeight
		endif
		local pos:SVec2F = new SVec2F(x, y)
		flake.position = pos
		flake.positionOld = pos	
		flake.velocity = new SVec2F(rand(-2,2)/10.0, rand(75, 90) )
		
		flakes.AddLast(flake)
		
		Return True
	End Method


	Method Update:int()
		If not IsActive() then return False

		local removed:TWeatherEffectSnowFlake[]

		Local delta:Float = GetDeltaTimer().GetDelta()

		For local flake:TWeatherEffectSnowFlake = EachIn flakes
			flake.lifetime :- int(1000 * delta)
			if flake.lifetime < 0 or flake.position.x < area.x - 150 or flake.position.x > area.GetX2() + 150
				removed :+ [flake]
				continue
			endif
			
			flake.positionOld = flake.position
			
			'adjust position (by local velocity, wind and a bit swirling around)
			Local newX:Float = delta * flake.velocity.x + 1.5 * windVelocity + Float(sin(flake.position.y * 0.75)*1.05)
			Local newY:Float = delta * flake.velocity.y
			flake.position = flake.position + New SVec2F(newX, newY)

			'below ground
			if flake.position.y > area.GetY2() 
				removed :+ [flake]
				continue
			endif
		Next

		For local d:TWeatherEffectSnowFlake = Eachin removed
			flakes.Remove(d)
		Next

		'add a new flake if time is near or something got removed
		if nextFlakeTime < Time.GetTimeGone() or removed.length > 0
			For local i:int = 0 until rand(nextFlakeEmitAmountMin, nextFlakeEmitAmountMax)
				If not AddFlake()
					Exit
				EndIf
			Next
			nextFlakeTime = Time.GetTimeGone() + rand(nextFlakeIntervalMin, nextFlakeIntervalMax)
		endif
	End Method


	'override to brighten the sky a bit
	Method ModifySkyColor(screenColor:SColor8 var)
		if flakes.Count() > 0
			'mix a white screen into the color
			'(max 20%, just to show the difference)
			screenColor = SColor8Helper.Mix(screenColor, SColor8.WHITE, 0.1)
		endif
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		If not IsActive() then return False
		
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		local effectAlpha:Float = fadeState.GetFadeProgress()
		if fadeState.IsFadingOff() then effectAlpha = 1.0 - effectAlpha

		'=== DRAW LIGHTNINGS ===
		local direction:int
		local lifetime:Int
		local lifetimeBase:Int
		local pos:TVec2D
		local sprite:TSprite
		For local flake:TWeatherEffectSnowFlake = eachin flakes
			sprite = sprites[flake.spriteNumber]
			if not sprite then continue
			
			Local t:Float = GetDeltaTimer().GetTween()
			local tweenPos:SVec2F = new SVec2F(MathHelper.Tween(flake.positionOld.x, flake.position.x, t), ..
				                               MathHelper.Tween(flake.positionOld.y, flake.position.y, t))
			'fade out but after 50% of lifetime is gone
			if flake.lifetime/Float(flake.lifeTimeBase) < 0.5
				SetAlpha(oldA * effectAlpha * 2.0 * flake.lifetime/Float(flake.lifeTimeBase))
			else
				SetAlpha(oldA * effectAlpha)
			endif
			
			'mirrored drawing?
			if flake.direction = 1
				local oldScaleX:Float, oldScaleY:Float
				GetScale(oldScaleX, oldScaleY)
				SetScale(-1 * oldScaleX, oldScaleY)

				sprite.Draw(tweenPos.x, tweenPos.y)

				SetScale(oldScaleX, oldScaleY)
			else
				sprite.Draw(tweenPos.x, tweenPos.y)
			endif
		Next
		
		SetColor(oldCol)
		SetAlpha(oldA)
	End Method
End Type




Type TWeatherEffectCloud
	Field spriteEntity:TSpriteEntity
	Field velocityX:Float
	Field velocityStrengthX:Float
	Field alpha:Float
End Type



Type TWeatherEffectClouds extends TWeatherEffectBase
	Field clouds:TObjectList = new TObjectList
	Field cloudMax:int = 30
	'current cloud color
	Field cloudColor:SColor8 = SColor8.WHITE
	'basic cloud color
	Field cloudColorBase:SColor8 = SColor8.WHITE
	Field cloudBrightness:int = 100
	Field skyBrightness:Float = 1.0
	

	Method Init:TWeatherEffectClouds(area:TRectangle, cloudAmount:int = 30, useSprites:TSprite[])
		SetUseSprites(useSprites)

		self.area = area.copy()

		'get rid of old clouds
		self.clouds.clear()

		self.cloudMax = cloudAmount

		For local i:int = 0 until cloudAmount
			AddCloud()
		Next
		
		return self
	End Method


	Method AddCloud:int()
		local cloudSprite:TSprite
		local cloud:TWeatherEffectCloud = new TWeatherEffectCloud
		local spriteEntity:TSpriteEntity = new TSpriteEntity

		if sprites then cloudSprite = sprites[rand(0, sprites.length-1)]
		if cloudSprite
			spriteEntity.SetSprite(cloudSprite)
			spriteEntity.area.SetWH(cloudSprite.GetWidth(), cloudSprite.GetHeight())
		else
			spriteEntity.area.SetWH(100, 50)
		endif

		local i:int = clouds.Count()
		spriteEntity.area.MoveXY(Rand(-200,800), -30 + Rand(0,40))
		spriteEntity.velocity.SetX(2.3 + Rand(0, 20)/10.0)

		cloud.velocityX = spriteEntity.velocity.GetX()
		cloud.velocityStrengthX = abs(spriteEntity.velocity.GetX())
		cloud.alpha = Rand(85,100)/100.0
		cloud.spriteEntity = spriteEntity

		clouds.AddLast(cloud)
	End Method


	Method StoreCloudVelocity()
		For local cloud:TWeatherEffectCloud = eachin clouds
			cloud.velocityX = cloud.spriteEntity.velocity.GetX()
		Next
	End Method


	Method AdjustCloudMovement(windStrength:float=0.0, timeSinceLastUpdate:int = 0, allowWrapping:int=True)
		local strengthX:float
		local velocityX:float

		For local cloud:TWeatherEffectCloud = eachin clouds
			cloud.spriteEntity.velocity.SetX(Float(TInterpolation.Linear(..
				cloud.velocityX,..
				cloud.velocityStrengthX * windStrength,..
				Double(Min(30 * TWorldTime.MINUTELENGTH, timeSinceLastUpdate)), 30 * TWorldTime.MINUTELENGTH)..
			))
			'do not use the global worldSpeed
			cloud.spriteEntity.worldSpeedFactor = GetWorldTime().GetTimeFactor() * 0.01
		
			cloud.spriteEntity.Update()

			'if weather does not allow clouds, do not wrap offscreen clouds
			if allowWrapping
				if cloud.spriteEntity.velocity.GetX() > 0 and cloud.spriteEntity.area.x > area.GetX2()
					cloud.spriteEntity.area.SetX(area.x -(cloud.spriteEntity.area.w+1))
				elseif cloud.spriteEntity.velocity.GetX() < 0 and cloud.spriteEntity.area.x < area.x - (cloud.spriteEntity.area.w+1)
					cloud.spriteEntity.area.SetX(area.GetX2() + 1)
				endif
			endif
		Next
	End Method


	Method Update:int()
		If not IsActive() then return False
	End Method


	Method Render:int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		If not IsActive() then return False
		
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		local effectAlpha:Float = fadeState.GetFadeProgress()
		if fadeState.IsFadingOff() then effectAlpha = 1.0 - effectAlpha

		'darken according to lighting (up to 20%)
		SetColor( SColor8Helper.Mix(cloudColor, SColor8.BLACK, 0.2 - 0.2 * skyBrightness) )

		local cloudNumber:int = 0
		For local cloud:TWeatherEffectCloud = eachin clouds
			'skip invisible ones
			if cloud.spriteEntity.area.GetX() > 801 then continue
			if cloud.spriteEntity.area.GetX() < - (cloud.spriteEntity.area.GetW()+1) then continue
			SetAlpha effectAlpha * (oldA*0.9 + 0.1*(float(cloudNumber)/(clouds.Count())) )
			if cloud.spriteEntity.sprite
				cloud.spriteEntity.Render()
			else
				DrawOval(cloud.spriteEntity.area.GetX(), cloud.spriteEntity.area.GetY(), 100, 50)
			endif
			cloudNumber :+1
		Next
		'restore alpha and color
		SetColor(oldCol)
		SetAlpha(oldA)
	End Method
End Type
