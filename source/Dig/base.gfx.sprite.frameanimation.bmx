SuperStrict
Import BRL.Map
Import BRL.Retro
Import "base.util.deltatimer.bmx"
Import "base.util.data.bmx"


Type TSpriteFrameAnimationCollection
	Field animations:TMap = CreateMap()
	Field currentAnimationName:string = ""


	Method Copy:TSpriteFrameAnimationCollection()
		local c:TSpriteFrameAnimationCollection = new TSpriteFrameAnimationCollection
		c.animations = animations.Copy()
		c.currentAnimationName = currentAnimationName
		return c
	End Method


	Method InitFromData:TSpriteFrameAnimationCollection(data:TData)
		For local animationData:TData = EachIn TData[](data.Get("animations"))
			Set(new TSpriteFrameAnimation.InitFromData(animationData))
		Next

		local newCurrentAnimationName:string = data.GetString("currentAnimationName")
		if newCurrentAnimationName then SetCurrent(newCurrentAnimationName)

		return self
	End Method


	'insert a TSpriteFrameAnimation with a certain Name
	Method Set(animation:TSpriteFrameAnimation, name:string="")
		if name = "" then name = animation.name
		animations.insert(lower(name), animation)
		if not animations.contains("default") then setCurrent(name, 0)
	End Method


	'Set a new Animation
	'If it is a different animation name, the Animation will get reset (start from begin)
	Method SetCurrent(name:string, start:int = TRUE, reset:int = True)
		name = lower(name)
		'if reset is allowed, reset on a different name
		if reset then reset = 1 - (currentAnimationName = name)
		currentAnimationName = name
		if reset then getCurrent().Reset()
		if start then getCurrent().Playback()
	End Method


	Method GetCurrent:TSpriteFrameAnimation()
		local obj:TSpriteFrameAnimation = TSpriteFrameAnimation(animations.ValueForKey(currentAnimationName))
		'load default if nothing was found
		if not obj then obj = TSpriteFrameAnimation(animations.ValueForKey("default"))
		return obj
	End Method


	Method Get:TSpriteFrameAnimation(name:string="default")
		local obj:TSpriteFrameAnimation = TSpriteFrameAnimation(animations.ValueForKey(name.toLower()))
		if not obj then obj = TSpriteFrameAnimation(animations.ValueForKey("default"))
		return obj
	End Method


	Method getCurrentAnimationName:string()
		return currentAnimationName
	End Method


	Method Update:int(deltaTime:Float = -1.0)
		GetCurrent().Update(deltaTime)
	End Method
End Type




Type TSpriteFrameAnimation
	Field name:string
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


	Function Create:TSpriteFrameAnimation(name:string, framesArray:int[][], repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local obj:TSpriteFrameAnimation = new TSpriteFrameAnimation
		local framecount:int = len( framesArray )

		obj.name = name
		obj.frames = obj.frames[..framecount] 'extend
		obj.framesTime = obj.framesTime[..framecount] 'extend
		obj.randomness = 0.001 * randomness 'ms to second

		For local i:int = 0 until framecount
			obj.frames[i]		= framesArray[i][0]
			obj.framesTime[i]	= float(framesArray[i][1]) * 0.001
		Next
		obj.repeatTimes	= repeatTimes
		obj.paused = paused
		return obj
	End Function


	Function CreateWithSpriteNames:TSpriteFrameAnimation(name:string, spriteNames:string[], frameTimes:int[], repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local obj:TSpriteFrameAnimation = new TSpriteFrameAnimation
		local framecount:int = frameTimes.length

		obj.name = name
		obj.frames = obj.frames[..framecount] 'extend
		obj.spriteNames = obj.spriteNames[..framecount] 'extend
		obj.framesTime = obj.framesTime[..framecount] 'extend
		obj.randomness = 0.001 * randomness 'ms to second

		For local i:int = 0 until framecount
			obj.spriteNames[i]  = spriteNames[i]
			obj.framesTime[i]	= float(frameTimes[i]) * 0.001
		Next
		obj.repeatTimes	= repeatTimes
		obj.paused = paused
		return obj
	End Function


	Function CreateSimple:TSpriteFrameAnimation(name:string, frameAmount:int, frameTime:int, repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local f:int[][]
		For local i:int = 0 until frameAmount
			f :+ [[i,frameTime]]
		Next
		return Create(name, f, repeatTimes, paused, randomness)
	End Function


	Function CreateSimpleWithSpriteNames:TSpriteFrameAnimation(name:string, spriteNames:string[], frameTime:int, repeatTimes:int=0, paused:int=0, randomness:Int = 0)
		local f:int[]
		For local i:int = 0 until spriteNames.length
			f :+ [frameTime]
		Next
		return CreateWithSpriteNames(name, spriteNames, f, repeatTimes, paused, randomness)
	End Function


	Method InitFromData:TSpriteFrameAnimation(data:TData)
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
			framesTime :+ [float(s)]
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


	Method Update:int(deltaTime:Float = -1)
		'skip update if only 1 frame is set
		'skip if paused
		If paused or frames.length <= 1 then return 0

		'use given or default deltaTime?
		if deltaTime < 0 or HasFlag(FLAG_IGNORE_DELTATIME_PARAM)
			deltaTime = GetDeltaTime()
		endif
		if frameTimer = null then ResetFrameTimer()
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
			If nextPos >= len(frames)
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
		return len(frames)
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
		'set the image frame of thhe animation frame
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
		return paused AND (currentFrame >= len(frames)-1)
	End Method


	Method Playback()
		paused = 0
	End Method


	Method Pause()
		paused = 1
	End Method
End Type