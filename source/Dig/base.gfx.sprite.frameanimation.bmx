SuperStrict
Import BRL.Map
Import BRL.Retro
Import "base.util.deltatimer.bmx"
Import "base.util.data.bmx"


Type TSpriteFrameAnimationCollection
	Field animations:TMap = CreateMap()
	Field currentAnimation:TSpriteFrameAnimation


	Method Copy:TSpriteFrameAnimationCollection()
		local c:TSpriteFrameAnimationCollection = new TSpriteFrameAnimationCollection
		c.animations = animations.Copy()
		c.currentAnimation = currentAnimation
		return c
	End Method


	Method InitFromData:TSpriteFrameAnimationCollection(data:TData)
		For local animationData:TData = EachIn TData[](data.Get("animations"))
			Add(new TSpriteFrameAnimation(animationData))
		Next

		local newCurrentAnimationName:string = data.GetString("currentAnimationName")
		if newCurrentAnimationName then SetCurrent(newCurrentAnimationName)

		return self
	End Method


	'insert a TSpriteFrameAnimation 
	Method Add(animation:TSpriteFrameAnimation)
		animations.insert(animation.GetNameLS(), animation)

		if not animations.contains("default") then SetCurrent(animation, 0)
	End Method


	'Set a new Animation
	'If it is a different animation name, the Animation will get reset (start from begin)
	Method SetCurrent(name:string, start:int = TRUE, reset:int = True)
		SetCurrent(Get(name), start, reset)
	End Method

	'Set a new Animation
	'If it is a different animation, the Animation will get reset (start from begin)
	Method SetCurrent(animation:TSpriteFrameAnimation, start:int = TRUE, reset:int = True)
		'if reset is allowed, reset on a different name
		if reset then reset = 1 - (currentAnimation = animation)

		currentAnimation = animation

		if reset then animation.Reset()
		if start then animation.Playback()
	End Method

	Method GetCurrent:TSpriteFrameAnimation()
		'return default if nothing was found
		if not currentAnimation Then Return TSpriteFrameAnimation(animations.ValueForKey("default"))

		Return currentAnimation
	End Method

	Method Get:TSpriteFrameAnimation(name:string)
		local obj:TSpriteFrameAnimation = TSpriteFrameAnimation(animations.ValueForKey(name.toLower()))
		if not obj then obj = TSpriteFrameAnimation(animations.ValueForKey("default"))
		return obj
	End Method


	Method Update:int(deltaTime:Float = -1.0)
		GetCurrent().Update(deltaTime)
	End Method
End Type




Type TSpriteFrameAnimation
	Field name:string
	Field nameLS:string
	'how many times animation should repeat until finished
	Field repeatTimes:int = 0
	'frame of sprite/image
	Field currentImageFrame:int = 0
	Field currentSpriteName:string = ""
	'position in frames-array
	Field currentFrame:int = 0
	Field frames:int[]
	Field spriteNames:string[]
	'duration for each frame
	Field framesTime:float[]
	'stay with currentFrame or cycle through frames?
	Field paused:Int = FALSE
	Field frameTimer:float = null
	Field randomness:float = 0
	Field flags:int = 0

	'use this flag to use the default GetDelta() instead of the given
	'one -> ignores the WorldSpeedFactor given by the sprite
	Const FLAG_IGNORE_DELTATIME_PARAM:int = 1


	Method New(name:string, framesArray:int[][], repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		Init(name, framesArray, repeatTimes, paused, randomness)
	End Method


	Method New(name:string, spriteNames:string[], frameTimes:int[], repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		Init(name, spriteNames, frameTimes, repeatTimes, paused, randomness)
	End Method


	Method New(name:string, frameAmount:int, frameTime:int, repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local f:int[][]
		For local i:int = 0 until frameAmount
			f :+ [[i,frameTime]]
		Next

		Init(name, f, repeatTimes, paused, randomness)
	End Method


	Method New(name:string, spriteNames:string[], frameTime:int, repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local f:int[]
		For local i:int = 0 until spriteNames.length
			f :+ [frameTime]
		Next

		Init(name, spriteNames, f, repeatTimes, paused, randomness)
	End Method

	
	Method New(data:TData)
		Init(data)
	End Method

	
	Method Init:TSpriteFrameAnimation(name:string, framesArray:int[][], repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local framecount:int = framesArray.length

		self.name = name
		self.frames = self.frames[..framecount] 'extend
		self.framesTime = self.framesTime[..framecount] 'extend
		self.randomness = 0.001 * randomness 'ms to second

		For local i:int = 0 until framecount
			self.frames[i]		= framesArray[i][0]
			self.framesTime[i]	= float(framesArray[i][1]) * 0.001
		Next
		self.repeatTimes	= repeatTimes
		self.paused = paused

		Return Self
	End Method


	Method Init:TSpriteFrameAnimation(name:string, spriteNames:string[], frameTimes:int[], repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local framecount:int = frameTimes.length

		self.name = name
		self.frames = self.frames[..framecount] 'extend
		self.spriteNames = self.spriteNames[..framecount] 'extend
		self.framesTime = self.framesTime[..framecount] 'extend
		self.randomness = 0.001 * randomness 'ms to second

		For local i:int = 0 until framecount
			self.spriteNames[i]  = spriteNames[i]
			self.framesTime[i]	= float(frameTimes[i]) * 0.001
		Next
		self.repeatTimes	= repeatTimes
		self.paused = paused
	
		Return Self
	End Method


	Method Init:TSpriteFrameAnimation(data:TData)
		name = data.GetString("name")
		repeatTimes = data.GetInt("repeatTimes", -1) 'default to "loop"
		currentImageFrame = data.GetInt("currentImageFrame")
		currentFrame = data.GetInt("currentFrame")
		currentSpriteName = data.GetString("currentSpriteName")
		paused = data.GetInt("paused")
		frameTimer = data.GetFloat("frameTimer")
		randomness = data.GetFloat("randomness")
		flags = data.GetInt("flags")

		For local s:string = EachIn data.GetString("frames").Split("::")
			frames :+ [int(s)]
		Next
		For local s:string = EachIn data.GetString("spriteNames").Split("::")
			spriteNames :+ [s]
		Next
		For local s:string = EachIn data.GetString("framesTime").Split("::")
			framesTime :+ [Float(s)]
		Next
		'if not enough framesTime were defined, just reuse the last
		'time for the missing ones
		if frames.length > 0
			For local i:int = framesTime.length until frames.length
				framesTime :+ [ framesTime[framesTime.length-1] ]
			Next
		endif

		return self
	End Method


	Method Copy:TSpriteFrameAnimation()
		local c:TSpriteFrameAnimation = new TSpriteFrameAnimation
		c.name = name
		c.repeatTimes = repeatTimes
		c.currentImageFrame = currentImageFrame
		c.currentFrame = currentFrame
		c.currentSpriteName = currentSpriteName
		c.frames = frames[..]
		if spriteNames
			c.spriteNames = spriteNames[..]
		else
			c.spriteNames = null
		endif
		c.framesTime = framesTime[..]
		c.paused = paused
		c.frameTimer = frameTimer
		c.randomness = randomness
		return c
	End Method


	Method SetFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	Method HasFlag:Int(flag:Int)
		Return (flags & flag) <> 0
	End Method


	Function GetDeltaTime:Float()
		return GetDeltaTimer().GetDelta()
	End Function
	
	
	Method GetNameLS:String()
		if not nameLS then nameLS = name.ToLower()
		return nameLS
	End Method


	Method Update:int(deltaTime:Float = -1)
		'skip update if only 1 frame is set
		'skip if paused
		If paused or frames.length <= 1 then return 0

		'use given or default deltaTime?
		if deltaTime < 0 or HasFlag(FLAG_IGNORE_DELTATIME_PARAM)
			deltaTime = GetDeltaTime()
		endif

		frameTimer :- deltaTime

		'skip frames if delta is bigger than frame time
		'time for next frame
		While frameTimer <= 0
			local oldFrameTimer:Float = frameTimer
			local nextPos:int = currentFrame + 1
			'increase current frameposition but only if frame is set
			'resets frametimer too
			setCurrentFrame(nextPos)

			'reached end? (use nextPos as setCurrentFramePos already limits value)
			If nextPos >= frames.length
				If repeatTimes = 0
					Pause()	'stop animation
					exit 'exit the while loop
				Else
					setCurrentFrame(0)
					repeatTimes :-1
				EndIf
			EndIf

			'add back what was left before
			frameTimer = oldFrameTimer + frameTimer
		Wend
	End Method


	Method Reset()
		setCurrentFrame(0)
	End Method


	Method ResetFrameTimer()
		frameTimer = framesTime[currentFrame] + 0.001*Rand(Int(-1000*randomness), Int(1000*randomness))
	End Method


	Method GetFrameCount:int()
		return frames.length
	End Method


	Method GetCurrentImageFrame:int()
		return currentImageFrame
	End Method


	Method SetCurrentImageFrame(frame:int)
		currentImageFrame = frame
		ResetFrameTimer()
	End Method


	Method GetCurrentFrame:int()
		return currentFrame
	End Method


	Method SetCurrentFrame(framePos:int)
		currentFrame = Max( Min(framePos, len(frames) - 1), 0)
		'set the image frame of the animation frame
		setCurrentImageFrame( frames[currentFrame] )

		if spriteNames and spriteNames.length > currentFrame
			setCurrentSpriteName( spriteNames[currentFrame] )
		endif
	End Method


	Method SetCurrentSpriteName(name:string)
		currentSpriteName = name
		ResetFrameTimer()
	End Method


	Method GetCurrentSpriteName:string()
		return currentSpriteName
	End Method


	Method isPaused:Int()
		return paused
	End Method


	Method isFinished:Int()
		return paused AND (currentFrame >= frames.length-1)
	End Method


	Method Playback()
		paused = 0
	End Method


	Method Pause()
		paused = 1
	End Method
End Type