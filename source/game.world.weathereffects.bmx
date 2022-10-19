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


	'reassign sprites for each raindrop
	Method ReassignSprites:int(useSprites:TSprite[])
		'assign new sprites to use
		SetUseSprites(useSprites)

		For local i:int = 0 until layerSprites.length
			'fetch sprite with given name again - or use random one
			local useSpriteNumber:Int = -1
			For local sprite:TSprite = eachin sprites
				if sprite.name <> layerSprites[i].name then continue

				useSpriteNumber = i
				exit
			Next
			'if number is not available anymore ... use random
			if useSpriteNumber < 0 or useSpriteNumber > sprites.length-1
				useSpriteNumber = rand(0, sprites.length-1)
			EndIf

			layerSprites[i] = sprites[useSpriteNumber]
		Next
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




Type TWeatherEffectLightning extends TWeatherEffectBase
	Field lightnings:TList = CreateList()
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


	'reassign sprites for each lightning strike
	Method ReassignSprites:int(useSprites:TSprite[], useSpritesSide:TSprite[])
		'assign new sprites to use
		SetUseSprites(useSprites)
		SetUseSpritesSide(useSpritesSide)

		For local lightning:TData = eachin lightnings
			local spriteNumber:int = lightning.GetInt("spriteNumber", -1)
			local useSpritesSide:int = lightning.GetInt("useSpritesSide", 0)
			if useSpritesSide
				if spriteNumber < 0 or spriteNumber > spritesSide.length-1
					lightning.Add("spriteNumber", spritesSide[rand(0, spritesSide.length-1)])
				EndIf
			else
				if spriteNumber < 0 or spriteNumber > sprites.length-1
					lightning.Add("spriteNumber", sprites[rand(0, sprites.length-1)])
				EndIf
			endif
		Next
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
		local lightning:TData = new TData
		lightning.AddInt("lifetime", lifetime)
		lightning.AddInt("lifetimeBase", lifetime)

		'comfing-from-side lightning
		if spritesSide and spritesSide.length > 0 and Rand(0,10) < 3
			if rand(0,1) = 0
				lightning.Add("position", new TVec2D(area.GetX(), rand(int(area.y), int(area.y - rand(0,60)))))
				lightning.AddNumber("direction", 0)
			else
				lightning.Add("position", new TVec2D(area.GetX2(), rand(int(area.y), int(area.y - rand(0,60)))))
				lightning.AddNumber("direction", 1)
			endif
			lightning.AddNumber("useSpritesSide", 1)
			lightning.AddNumber("spriteNumber", rand(0, spritesSide.length-1))
		else
			lightning.Add("position", new TVec2D(rand(int(area.x), int(area.GetX2())), int(area.y) - rand(0,60)))
			lightning.AddNumber("useSpritesSide", 0)
			lightning.AddNumber("direction", rand(0,1))
			lightning.AddNumber("spriteNumber", rand(0, sprites.length-1))
		endif
		
		lightnings.AddLast(lightning)

		nextLightningTime = Time.GetTimeGone() + rand(nextLightningIntervalMin, nextLightningIntervalMax)
	End Method


	Method Update:int()
		If not IsActive() then return False

		local lifetime:Int
		local removed:TData[]
		For local lightning:TData = EachIn lightnings
			lifeTime = lightning.GetInt("lifetime", 0) - int(1000 * GetDeltaTimer().GetDelta())
			if lifetime < 0 then removed :+ [lightning]

			lightning.AddInt("lifetime", lifetime) 			
		Next

		For local d:TData = Eachin removed
			lightnings.Remove(d)
		Next

		'add a new lightning if time is near
		if nextLightningTime < Time.GetTimeGone() then AddLightning()
	End Method


	Method GetLightningAlpha:Float(lightning:TData)
		local lifetime:Int = lightning.GetInt("lifetime", 0)
		local lifetimeBase:Float = lightning.GetInt("lifetimeBase", 0)

		if lifetimeBase - lifetime <= 20
			return (lifetimeBase - lifetime)/20.0
		elseif lifetime <= 20
			return 1.0 - (20 - lifetime)/20.0
		endif
		return 1.0
	End Method


	'override to brighten the sky with a active lightning
	Method ModifySkyColor(screenColor:SColor8 var)
		local maxAlpha:Float = 0.0
		For local lightning:TData = EachIn lightnings
			'skip calculating more if already at max
			if maxAlpha >= 1.0 then continue
			
			maxAlpha = max(maxAlpha, GetLightningAlpha(lightning))
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
		For local lightning:TData = eachin lightnings
			local sprite:TSprite

			if lightning.GetInt("useSpritesSide", 0) = 1
				sprite = spritesSide[lightning.GetInt("spriteNumber", 0)]
			else
				sprite = sprites[lightning.GetInt("spriteNumber", 0)]
			endif
			if not sprite then continue
			
			local pos:TVec2D = TVec2D(lightning.Get("position"))
			if not pos then pos = new TVec2D
			local direction:int = lightning.GetInt("direction", 0)

			SetAlpha(oldA * effectAlpha * GetLightningAlpha(lightning))

			'mirrored drawing?
			if direction = 1
				local oldScaleX:Float,oldScaleY:Float
				GetScale(oldScaleX, oldScaleY)
				SetScale(-1 * oldScaleX, oldScaleY)

				sprite.Draw(pos.x, pos.y)

				SetScale(oldScaleX, oldScaleY)
			else
				sprite.Draw(pos.x, pos.y)
			endif
		Next
	
		SetColor(oldCol)
		SetAlpha(oldA)	
	End Method
End Type




Type TWeatherEffectSnow extends TWeatherEffectBase
	Field flakes:TList = CreateList()
	Field flakeLifetimeMin:int = 2200
	Field flakeLifetimeMax:int = 3800
	Field nextFlakeTime:Long = 0
	Field nextFlakeIntervalMin:int = 150
	Field nextFlakeIntervalMax:int = 450
	Field nextFlakeEmitAmountMin:int = 3
	Field nextFlakeEmitAmountMax:int = 6
	Field flakesMax:int = 75


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


	'reassign sprites for each snowflake
	Method ReassignSprites:int(useSprites:TSprite[])
		'assign new sprites to use
		SetUseSprites(useSprites)

		For local flake:TData = eachin flakes
			local spriteNumber:int = flake.GetInt("spriteNumber", -1)
			if spriteNumber < 0 or spriteNumber > sprites.length-1
				flake.Add("spriteNumber", sprites[rand(0, sprites.length-1)])
			EndIf
		Next
	End Method


	Method AddFlake:int()
		'do not add if already at max
		if flakes.Count() >= flakesMax then return False

		'lifetime in seconds
		local lifetime:Int = rand(flakeLifetimeMin,flakeLifetimeMax)
		local spriteNumber:int = rand(0, Max(0,sprites.length-1))
		local spriteHeight:int = 30
		if sprites[spriteNumber] then spriteHeight = sprites[spriteNumber].GetHeight()
		
		local flake:TData = new TData
		flake.AddInt("lifetime", lifetime)
		flake.AddInt("lifetimeBase", lifetime)
		flake.AddInt("spriteNumber", spriteNumber)
		flake.Addint("direction", rand(0,1))

		local pos:TVec2D = new TVec2D(rand(int(area.x), int(area.GetX2())), area.y + rand(0, 60) - spriteHeight )
		flake.Add("position", pos)
		flake.Add("oldPosition", pos.copy())	
		flake.Add("velocity", new TVec2D(rand(-10,10)/10.0, rand(75, 90) ))
		
		flakes.AddLast(flake)
	End Method


	Method Update:int()
		If not IsActive() then return False

		local lifetime:Int
		local pos:TVec2D
		local vel:TVec2D
		local removed:TData[]

		For local flake:TData = EachIn flakes
			lifetime = flake.GetInt("lifetime", 0) - int(1000 * GetDeltaTimer().GetDelta())
			if lifetime < 0 
				removed :+ [flake]
				continue
			endif
			
			vel = TVec2D(flake.Get("velocity"))
			pos = TVec2D(flake.Get("position"))
			if not vel then vel = new TVec2D
			if not pos then pos = new TVec2D
			flake.Add("oldPosition", pos.copy())	
			pos.x :+ GetDeltaTimer().GetDelta() * vel.x
			pos.y :+ GetDeltaTimer().GetDelta() * vel.y

			'adjust position
			pos.AddXY(Float(sin(pos.y * 0.75)*1.05), 0.0)

			'below ground
			if pos.y > area.GetY2() 
				removed :+ [flake]
				continue
			endif

			flake.Add("position", pos) 			
			flake.AddInt("lifetime", lifetime) 			
		Next

		For local d:TData = Eachin removed
			flakes.Remove(d)
		Next

		'add a new flake if time is near
		if nextFlakeTime < Time.GetTimeGone()
			For local i:int = 0 until rand(nextFlakeEmitAmountMin, nextFlakeEmitAmountMax)
				AddFlake()
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
		For local flake:TData = eachin flakes
			sprite = sprites[flake.GetInt("spriteNumber", 0)]
			if not sprite then continue
			
			pos = TVec2D(flake.Get("position"))
			local oldPosition:TVec2D = TVec2D(flake.Get("oldPosition"))
			if not oldPosition then oldPosition = new TVec2D
			if not pos then pos = new TVec2D

			direction = flake.GetInt("direction", 0)
			lifetime = flake.GetInt("lifetime", 1)
			lifetimeBase = flake.GetInt("lifetimeBase", 1)
			lifetimeBase = flake.GetInt("lifetimeBase", 1)

			Local t:Float = GetDeltaTimer().GetTween()
			local tweenPos:TVec2D = new TVec2D(MathHelper.Tween(oldPosition.x, pos.x, t), ..
				                               MathHelper.Tween(oldPosition.y, pos.y, t))
			'fade out but after 50% of lifetime is gone
			if lifetime/Float(lifeTimeBase) < 0.5
				SetAlpha(oldA * effectAlpha * 2.0 * lifetime/Float(lifeTimeBase))
			else
				SetAlpha(oldA * effectAlpha)
			endif
			
			'mirrored drawing?
			if direction = 1
				local oldScaleX:Float,oldScaleY:Float
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




Type TWeatherEffectClouds extends TWeatherEffectBase
	Field clouds:TList = CreateList()
	Field cloudMax:int = 30
	'current cloud color
	Field cloudColor:SColor8 = SColor8.WHITE
	'basic cloud color
	Field cloudColorBase:SColor8 = SColor8.WHITE
	Field cloudBrightness:int = 100
	Field skyBrightness:Float = 1.0
	
	Field LSVelocityX:TLowerString = TLowerString.Create("velocityX")
	Field LSVelocityStrengthX:TLowerString = TLowerString.Create("velocityStrengthX")
	Field LSAlpha:TLowerString = TLowerString.Create("alpha")
	Field LSSpriteEntity:TLowerString = TLowerString.Create("spriteEntity")

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


	'reassign sprites for each cloud
	Method ReassignSprites:int(useSprites:TSprite[])
		'assign new sprites to use
		SetUseSprites(useSprites)

		local entity:TSpriteEntity
		For local cloud:TData = eachin clouds
			entity = TSpriteEntity(cloud.Get(LSSpriteEntity))
			'fetch sprite with given name again - or use random one
			local useSprite:TSprite
			For local sprite:TSprite = eachin sprites
				if sprite.name <> entity.sprite.name then continue

				useSprite = sprite
				exit
			Next
			if useSprite then entity.sprite = useSprite
			if not entity.sprite then entity.sprite = sprites[rand(0, sprites.length-1)]

			entity.area.SetWH(entity.sprite.GetWidth(), entity.sprite.GetHeight())
		Next
	End Method


	Method AddCloud:int()
		local cloudSprite:TSprite
		local cloud:TData = new TData
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

		cloud.AddNumber(LSVelocityX, spriteEntity.velocity.GetX())
		cloud.AddNumber(LSVelocityStrengthX, abs(spriteEntity.velocity.GetX()))
		cloud.AddNumber(LSAlpha, Float(Rand(85,100))/100.0)
		'assign spriteentity
		cloud.Add(LSSpriteEntity, spriteEntity)

		clouds.AddLast(cloud)
	End Method


	Method StoreCloudVelocity()
		For local cloud:TData = eachin clouds
			cloud.AddNumber(LSVelocityX, TSpriteEntity(cloud.Get(LSSpriteEntity)).velocity.GetX())
		Next
	End Method


	Method AdjustCloudMovement(windStrength:float=0.0, timeSinceLastUpdate:int = 0, allowWrapping:int=True)
		local strengthX:float
		local velocityX:float
		local entity:TSpriteEntity

		For local cloud:TData = eachin clouds
			entity = TSpriteEntity(cloud.Get(LSSpriteEntity))
			entity.velocity.SetX(Float(TInterpolation.Linear(..
				cloud.GetFloat(LSVelocityX),..
				cloud.GetFloat(LSVelocityStrengthX) * windStrength,..
				Double(Min(30 * TWorldTime.MINUTELENGTH, timeSinceLastUpdate)), 30 * TWorldTime.MINUTELENGTH)..
			))
			'do not use the global worldSpeed
			entity.worldSpeedFactor = GetWorldTime().GetTimeFactor() * 0.01
		
			entity.Update()

			'if weather does not allow clouds, do not wrap offscreen clouds
			if allowWrapping
				if entity.velocity.GetX() > 0 and entity.area.x > area.GetX2()
					entity.area.SetX(area.x -(entity.area.w+1))
				elseif entity.velocity.GetX() < 0 and entity.area.x < area.x - (entity.area.w+1)
					entity.area.SetX(area.GetX2() + 1)
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

		local entity:TSpriteEntity
		local cloudNumber:int = 0
		For local cloud:TData = eachin clouds
			entity = TSpriteEntity(cloud.Get(LSSpriteEntity))
			'skip invisible ones
			if entity.area.GetX() > 801 then continue
			if entity.area.GetX() < - (entity.area.GetW()+1) then continue
			SetAlpha effectAlpha * (oldA*0.9 + 0.1*(float(cloudNumber)/(clouds.Count())) )
			if entity.sprite
				entity.Render()
			else
				DrawOval(entity.area.GetX(), entity.area.GetY(), 100, 50)
			endif
			cloudNumber :+1
		Next
		'restore alpha and color
		SetColor(oldCol)
		SetAlpha(oldA)
	End Method
End Type
