Rem
	====================================================================
	Spriteparticle class
	====================================================================

	Simple particle class.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

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
Import "base.gfx.sprite.bmx"
Import "base.util.deltatimer.bmx"


Type TSpriteParticleEmitter
	Field area:TRectangle = new TRectangle
	Field particles:TSpriteParticle[]
	'delay spawn by x seconds
	Field spawnEveryMin:Float = 0.15, spawnEveryMax:Float = 0.20
	Field spawnNextTime:Float = 0
	Field particleConfig:TData = new TData


	Method Init:TSpriteParticleEmitter(emitterConfig:TData, particleConfig:TData)
		area = TRectangle(emitterConfig.Get("area", area))
		spawnEveryMin = emitterConfig.GetFloat("spawnEveryMin", spawnEveryMin)
		spawnEveryMax = emitterConfig.GetFloat("spawnEveryMax", spawnEveryMax)

		'resize array
		local particlesLimit:int = emitterConfig.GetInt("particlesLimit", 100)
		particles = particles[..particlesLimit]

		'create new particles, set them "dead"
		For Local i:Int = 0 until particles.length
			particles[i] = New TSpriteParticle.Init(particleConfig)
		Next

		return self
	End Method


	Method ResetSpawnTime()
		'reset time for next spawn
		spawnNextTime = rnd(spawnEveryMin, spawnEveryMax)
	End Method


	Method Update:int()
		local deltaTime:Float = GetDeltaTimer().GetDelta()
		spawnNextTime :- deltaTime

		'cigar particles
		If spawnNextTime <= 0
			ResetSpawnTime()

			'recreate dead particles
			For local i:int = 0 until particles.Length
				If not particles[i].isAlive
					particles[i].Spawn(area)
				endif
			Next
		EndIf

		'update all particles
		For local i:int = 0 until particles.Length
			particles[i].Update(deltaTime)
		Next

	End Method


	Method Draw:int()
		For Local i:Int = 0 until particles.Length
			particles[i].Draw()
		Next
	End Method

End Type




Type TSpriteParticle
	Field sprite:TSprite
	Field x:Float,y:Float
	Field xrange:Int,yrange:Int
	Field vel:Float, velMin:Float, velMax:Float
	Field angle:Float, angleMin:Float, angleMax:Float
	Field life:float, lifeMin:Float, lifeMax:Float
	Field startLife:float
	Field isAlive:Int
	Field alpha:Float, alphaMin:Float, alphaMax:Float, alphaRate:Float
	Field scale:Float, scaleMin:Float, scaleMax:Float, scaleRate:Float



	Method Init:TSpriteParticle(config:TData)
		sprite = TSprite(config.Get("sprite"))
		xRange = config.GetFloat("xRange")
		yRange = config.GetFloat("yRange")
		velMin = config.GetFloat("velocityMin")
		velMax = config.GetFloat("velocityMax")
		lifeMin = config.GetFloat("LifeMin")
		lifeMax = config.GetFloat("lifeMax")
		scaleMin = config.GetFloat("scaleMin")
		scaleMax = config.GetFloat("scaleMax")
		scaleRate = config.GetFloat("scaleRate", 1.0)
		alphaMin = config.GetFloat("alphaMin", 1.0)
		alphaMax = config.GetFloat("alphaMax", 1.0)
		alphaRate = config.GetFloat("alphaRate", 1.0)
		angleMin = config.GetFloat("angleMin")
		angleMax = config.GetFloat("angleMax")

		return self
	End Method


	Method Spawn(area:TRectangle)
		isAlive = True

		'spawn in given area
		x = area.GetX() + Rnd(-(xRange/2),(xRange/2))
		y = area.GetY() + Rnd(-(yRange/2),(yRange/2))

		vel = Rnd(velMin, velMax)
		life = Rnd(lifeMin, lifeMax)
		scale = Rnd(scaleMin, scaleMax)
		angle = Rnd(angleMin, angleMax)

		startLife = life
		alpha = Rnd(alphaMin, alphaMax)
	End Method


	Method Update(deltaTime:float = 1.0)
		life :- deltaTime
		If life <0 then isAlive = False

		if not isAlive then return

		'pcount:+1
		vel :* 0.99 '1.02 '0.98
		x :- (vel * Cos(angle-90)) * deltaTime
		y :- (vel * Sin(angle-90)) * deltaTime

		alpha :+ alpha * (alphaRate * deltatime)
		scale :+ scale * (scaleRate * deltatime)

		angle:*0.999
	End Method


	Method Draw()
		if not isAlive then return

		SetAlpha alpha
		SetRotation angle
		SetScale(scale, scale)
		if sprite
			sprite.Draw(x,y, -1, ALIGN_CENTER_CENTER)
		else
			DrawOval(x-3, y-3, 6,6)
		endif
		SetAlpha 1.0
		SetRotation 0
		SetScale 1,1
		SetColor 255,255,255
	EndMethod
End Type