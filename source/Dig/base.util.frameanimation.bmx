SuperStrict
Import BRL.Map


Type TFrameAnimationCollection
	Field animations:TMap = CreateMap()
	Field currentAnimationName:string = ""


	'insert a TFrameAnimation with a certain Name
	Method Set(name:string, animation:TFrameAnimation)
		animations.insert(lower(animationName), animation)
		if not animations.contains("default") then setCurrentAnimation(name, 0)
	End Method


	'Set a new Animation
	'If it is a different animation name, the Animation will get reset (start from begin)
	Method SetCurrent(name:string, start:int = TRUE)
		name = lower(name)
		local reset:int = 1 - (currentAnimationName = name)
		currentAnimationName = name
		if reset then getCurrent().Reset()
		if start then getCurrent().Playback()
	End Method


	Method GetCurrent:TFrameAnimation()
		local obj:TFrameAnimation = TFrameAnimation(animations.ValueForKey(currentAnimationName))
		'load default if nothing was found
		if not obj then obj = TFrameAnimation(animations.ValueForKey("default"))
		return obj
	End Method


	Method Get:TFrameAnimation(name:string="default")
		local obj:TFrameAnimation = TFrameAnimation(animations.ValueForKey(name.toLower()))
		if not obj then obj = TFrameAnimation(animations.ValueForKey("default"))
		return obj
	End Method


	Method getCurrentAnimationName:string()
		return currentAnimationName
	End Method


	Method Update(deltaTime:float)
		getCurrent().Update(deltaTime)
	End Method
End Type




Type TFrameAnimation
	Field repeatTimes:int = 0			'how many times animation should repeat until finished
	Field currentImageFrame:int = 0		'frame of sprite/image
	Field currentFrame:int = 0			'position in frames-array
	Field frames:int[]
	Field framesTime:float[]			'duration for each frame
	Field paused:Int = FALSE			'stay with currentFrame or cycle through frames?
	Field frameTimer:float = null
	Field randomness:int = 0


	Function Create:TFrameAnimation(framesArray:int[][], repeatTimes:int=0, paused:int=0, randomness:int = 0)
		local obj:TFrameAnimation = new TFrameAnimation
		local framecount:int = len( framesArray )

		obj.frames		= obj.frames[..framecount] 'extend
		obj.framesTime	= obj.framesTime[..framecount] 'extend

		For local i:int = 0 until framecount
			obj.frames[i]		= framesArray[i][0]
			obj.framesTime[i]	= float(framesArray[i][1]) * 0.001
		Next
		obj.repeatTimes	= repeatTimes
		obj.paused = paused
		return obj
	End Function


	Method Update:int()
		'skip update if only 1 frame is set
		'skip if paused
		If paused or frames.length <= 1 then return 0

		if frameTimer = null then ResetFrameTimer()
		frameTimer :- GetDeltaTimer().GetDelta()

		'time for next frame
		if frameTimer <= 0.0
			local nextPos:int = currentFramePos + 1
			'increase current frameposition but only if frame is set
			'resets frametimer too
			setCurrentFramePos(nextPos)

			'reached end? (use nextPos as setCurrentFramePos already limits value)
			If nextPos >= len(frames)
				If repeatTimes = 0
					Pause()	'stop animation
				Else
					setCurrentFramePos(0)
					repeatTimes :-1
				EndIf
			EndIf
		Endif
	End Method


	Method Reset()
		setCurrentFramePos(0)
	End Method


	Method ResetFrameTimer()
		frameTimer = framesTime[currentFramePos] + Rand(-randomness, randomness)
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
		return currentFramePos
	End Method


	Method SetCurrentFrame(framePos:int)
		currentFramePos = Max( Min(framePos, len(frames) - 1), 0)
		setCurrentFrame( frames[currentFramePos] )
	End Method


	Method isPaused:Int()
		return paused
	End Method


	Method isFinished:Int()
		return paused AND (currentFramePos >= len(frames)-1)
	End Method


	Method Playback()
		paused = 0
	End Method


	Method Pause()
		paused = 1
	End Method
End Type