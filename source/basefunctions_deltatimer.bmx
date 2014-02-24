superstrict
Import "basefunctions_events.bmx"
?Threaded
Import Brl.threads
?
'timer mode
Import Brl.timer
Import Brl.event
Import Brl.retro

'class for smooth framerates

Type TDeltaTimer
	Field _updateRate:float			'1.0/UPS
	Field _renderRate:float			'1.0/FPS
	Field _timeFactor:float  = 1.0	'conversion from realtime->apptime (2.0 = double as fast)

	Field _updateAccumulator:float	'time available for updates this loop
	Field _renderAccumulator:float	'time available for renders this loop

	Field timesUpdated:int   = 0
	Field timesRendered:int  = 0
	Field currentUPS:int     = 0
	Field currentFPS:int     = 0

	Field _loopBeginTime:int		'when did the current loop begin
	Field _lastLoopTime:int			'realtime how long the last loop took
	Field _loopTimeSum:float = 0.0	'time all loops used so far
	Field _loopTimeCount:int = 0	'amount of loops done
	Field _secondGone:int	 = 0	'time accumulator to check whether a second passed (value=milliseconds)


	Function Create:TDeltaTimer(UpdatesPerSecond:int = 60, RendersPerSecond:int = -1)
		local obj:TDeltaTimer = new TDeltaTimer
		obj._updateRate    = 1.0 / UpdatesPerSecond	'UPS
		obj._renderRate    = 1.0 / RendersPerSecond	'FPS
		obj.Reset()
		return obj
	End Function


	Method Reset()
		_loopBeginTime = MilliSecs()
	End Method


	'returns the time available for the next loop.
	'if not enough time is left, the time left is returned
	'returned value is in seconds (0.123 seconds)
	Method GetDelta:float()
		return _updateRate  'fixed rate

		'more updates fit into that thing ... r
'		if _updateAccumulator > _updateRate then return _updateRate
'		return _updateAccumulator
'		return (_lastLoopTime * _timeFactor) / 1000.0
	End Method


	'time the current loop needed up to now
	Method getCurrentLoopTime:float()
		return Millisecs() - _loopBeginTime
	End Method


	Method getLoopTimeAverage:float()
		if _loopTimeCount > 0
			return _loopTimeSum / _loopTimeCount
		else
			return 0
		endif
	End Method


	'result is a value between 0.0 and 1.0 (percentage)
	'until next update will take place
	Method getTween:float()
		'_updateAccumulator contains remainder
		return _updateAccumulator / _updateRate

'		return Max(0.0, Min(1.0, updateAccumulator / getTimeStep()))
'		return _updateAccumulator / getDelta()
'		if _updateAccumulator > _updateRate then return 1.0
'		return _updateAccumulator / _updateRate
	End Method


	Method getTweenResult:float(currentValue:float, oldValue:float, avoidShaking:int=TRUE)
		local result:float = currentValue * getTween() + oldValue * (1.0 - getTween())
		if avoidShaking and Abs(result - currentValue) < 0.1 then return currentValue
		return result
	End Method


	'updates currentFps and currentUps
	Method updateStatistics:int()
		_secondGone	:+ _lastLoopTime

		if _secondGone >= 1000 'in ms
			_secondGone   = 0
			currentFPS    = timesRendered
			currentUPS    = timesUpdated
			timesRendered = 0
			timesUpdated  = 0
			_loopTimeSum  = GetLoopTimeAverage()
			_loopTimeCount= 1
		endif
	End Method



	Method runUpdate()
		'each loop the looptime is added to an accumulator
		'as soon as the accumulator is bigger than the time reserved
		'for an update ("timeStep"), the loop does as much updates
		'as the accumulator "fits"
		_updateAccumulator:+ _lastLoopTime/1000.0
		while(_updateAccumulator > _updateRate)
			'every second update do a system update
			if timesUpdated mod 2 = 0 then EventManager.triggerEvent( TEventSimple.Create("App.onSystemUpdate",null) )
			'emit event to do update
			EventManager.triggerEvent(TEventSimple.Create("App.onUpdate"))

			'subtract the time reserved for an update from the accumulator
			_updateAccumulator = Max(0.0, _updateAccumulator - _updateRate)
			'for stats
			timesUpdated:+1
		wend
	End Method


	Method runRender()
		'the time available for rendering has to consider the time
		'used for updating - so subtract that from the accumulator
		_renderAccumulator:+ (_lastLoopTime - getCurrentLoopTime()) / 1000.0

		if(_renderAccumulator > _renderRate)
			EventManager.triggerEvent(TEventSimple.Create("App.onDraw"))

			'subtract the time reserved for a render from the accumulator
'				_renderAccumulator = Max(0.0, _renderAccumulator - _renderRate)
			_renderAccumulator = 0

			'for stats
			timesRendered:+1
		endif
	End Method


	Method limitedFPS:int()
		return _renderRate > 0
	End Method


	Method Loop()
		'compute time last loop neeeded
		_lastLoopTime  = Millisecs() - _loopBeginTime	'<-- the delta
		_loopBeginTime = MilliSecs()					'store for next run

		'update values for FPS/UPS stats
		updateStatistics()

		'the loop time is limited to 250 ms to avoid spiral of dead
		_lastLoopTime  = Min(250, _lastLoopTime)


		runUpdate()
		runRender()

		'for looptime-average-calculation
		_loopTimeSum :+ getCurrentLoopTime()
		_loopTimeCount :+ 1

		'if there was time left but no updates need to be done
		'ALTERNATIV?: hierfuer feststellen wieviel zeit ein loop haette
		'und wieviel davon benutzt worden ist... den rest dann "delayen"
		if _renderRate > 0 and (_updateRate*1000 - getCurrentLoopTime() > 0)
			delay(1)
		endif
	End Method
End Type
rem
Type TDeltaTimer
	field newTime:int 				= 0
	field oldTime:int 				= 0
	field accumulator:float			= 0.0
	field tweenValue:float			= 0.0		'between 0..1 (0 = no tween, 1 = full tween)
	Field timeStep:float			= 1.0 / 60.0	'60.0 = UPS
	Field frameRate:float			= 1.0 / 30.0	'30.0 = FPS
	Field updateAccumulator:float	= 0.0			'time left for updates
	Field renderAccumulator:float	= 0.0			'time left for renders
	Field lastLoopTime:int			= 0
	Field lastUpdateTime:int		= 0
	Field limitFrames:int			= TRUE			'limit to vsync/framerate

	field currentUps:int			= 0
	field currentFps:int			= 0
	field timesDrawn:int 			= 0
	field timesUpdated:int 			= 0
	field secondGone:float 			= 0.0

	'for avg calculation
	field loopTimeSum:float			= 0.0
	field loopTimeCount:int			= 0

	?Threaded
	Global UpdateThread:TThread
	Global drawMutex:TMutex 		= CreateMutex()
	Global useDeltaTimer:TDeltaTimer= null

	field mainLoopTime:float		= 0.1
	field mainNewTime:int			= 0
	field mainOldTime:int			= 0.0
	?

	Function Create:TDeltaTimer(UpdatesPerSecond:int = 60, RendersPerSecond:int = -1)
		local obj:TDeltaTimer	= new TDeltaTimer
		obj.timeStep			= 1.0 / UpdatesPerSecond	'UPS
		obj.frameRate			= 1.0 / RendersPerSecond	'FPS


		obj.newTime				= MilliSecs()
		obj.oldTime				= 0.0
		return obj
	End Function

	?Threaded
	Function RunUpdateThread:Object(Input:Object)
		repeat
			useDeltaTimer.newTime		= MilliSecs()
			if useDeltaTimer.oldTime = 0.0 then useDeltaTimer.oldTime = useDeltaTimer.newTime - 1
			useDeltaTimer.secondGone	:+ (useDeltaTimer.newTime - useDeltaTimer.oldTime)
			useDeltaTimer.loopTime		= (useDeltaTimer.newTime - useDeltaTimer.oldTime) / 1000.0
			useDeltaTimer.oldTime		= useDeltaTimer.newTime

			if useDeltaTimer.secondGone >= 1000.0 'in ms
				useDeltaTimer.secondGone 	= 0.0
				useDeltaTimer.currentFps	= useDeltaTimer.timesDrawn
				useDeltaTimer.currentUps	= useDeltaTimer.timesUpdated
				useDeltaTimer.timesDrawn 	= 0
				useDeltaTimer.timesUpdated	= 0
			endif

			'fill time available for this loop
			useDeltaTimer.loopTime = Min(0.25, useDeltaTimer.loopTime)	'min 4 updates per seconds 1/4
			useDeltaTimer.accumulator :+ useDeltaTimer.loopTime

			if useDeltaTimer.accumulator >= useDeltaTimer.getDelta()
				'wait for the drawMutex to are unlocked (no drawing process at the moment)
				'force lock as physical updates are crucial
				LockMutex(drawMutex)
				While useDeltaTimer.accumulator >= useDeltaTimer.getDelta()
					useDeltaTimer.totalTime		:+ useDeltaTimer.getDelta()
					useDeltaTimer.accumulator	:- useDeltaTimer.getDelta()
					useDeltaTimer.timesUpdated	:+ 1

					'every second update do a system update
					if useDeltaTimer.timesUpdated mod 2 = 0
						EventManager.triggerEvent( TEventSimple.Create("App.onSystemUpdate",null) )
					endif
					EventManager.triggerEvent( TEventSimple.Create("App.onUpdate",null) )
				Wend
				UnLockMutex(drawMutex)
			else
				delay( floor(Max(1, 1000.0 * (useDeltaTimer.getDelta() - useDeltaTimer.accumulator) - 1)) )
			endif
		forever
	End Function


	Method Loop()
		mainNewTime		= MilliSecs()
		if mainOldTime = 0.0 then mainOldTime = mainNewTime - 1
		mainLoopTime	= (mainNewTime - mainOldTime) / 1000.0
		mainOldTime		= mainNewTime

		'init update thread
		if not self.UpdateThread OR not ThreadRunning(self.UpdateThread)
			useDeltaTimer = self
			print " - - - - - - - - - - - - - - - - -"
			print "Start Updatethread: create thread."
			print " - - - - - - - - - - - - - - - - -"
			self.UpdateThread = CreateThread(self.RunUpdateThread, Null)
		endif

		'time for drawing?
		'- subtract looptime
		'  -> time lost for doing other things
		self.nextDraw :- mainLoopTime

		If self.fps < 0 OR (self.fps > 0 and self.nextDraw <= 0.0)
			'if we get the mutex (not updating now) -> send draw event
			if TryLockMutex(drawMutex)
				self.nextDraw = 1.0/float(self.fps)

				'how many % of ONE update are left - 1.0 would mean: 1 update missing
				'this is NOT related to the fps! but some event listeners may want that information
				self.tweenValue = self.accumulator / self.getDelta()


				'draw gets tweenvalue (0..1)
				self.timesDrawn :+1
				EventManager.triggerEvent( TEventSimple.Create("App.onDraw", string(self.tweenValue)) )
				UnlockMutex(drawMutex)
			endif
		else
			'delay by a minimum of 1ms - subtract looptime (as "time of next run")
			delay floor(Max(1, 1000.0*(self.nextDraw - self.mainLoopTime) -1))
		EndIf
		'in a non threaded version we delay...
'		delay(2)
	End Method
	?

	?not Threaded
	Method Loop()
		'adjust "delta"-value for the time gone since last loop
		'if an update is done, the delta value is reset
		'so the delta contains a value describing the portion between
		'two UPDATES, not loops
		lastUpdateTime :+ computeLastLoopTime()
		'refresh fps/ups values
		updateSecond()


		updateAccumulator:+ lastLoopTime/1000.0
		while(updateAccumulator > timeStep )
			'every second update do a system update
			if timesUpdated mod 2 = 0
				EventManager.triggerEvent( TEventSimple.Create("App.onSystemUpdate",null) )
			endif
			EventManager.triggerEvent(TEventSimple.Create("App.onUpdate"))
			lastUpdateTime = 0 'reset value, update was done
			'subtract a timeStep from the accumulator
			updateAccumulator:- timeStep
			'for stats
			timesUpdated:+1
		wend


		'as soon as enough cycles happened, draw.
		'if there are more "draws" than "updates", we still only need
		'one ... except we use tweening...
		'if framerate is -1 each loop a render is done (maxFPS mode)
		renderAccumulator:+ lastLoopTime/1000.0
		if(renderAccumulator > frameRate)
			EventManager.triggerEvent(TEventSimple.Create("App.onDraw"))
			'reset accumulator - so it fills up if enough time was left
			'after updates
			renderAccumulator = 0.0
			'for stats
			timesDrawn:+1
		endif

		'for looptime-average-calculation
		loopTimeSum :+ getCurrentLoopTime()
		loopTimeCount :+ 1


		'timeStep: is the available time for each cycle in MILLISECONDS
		'Millisecs()- newTime = time this cycle took in SECONDS
		'-> we can sleep for the difference
'		print (floor(timeStep*1000) - (Millisecs()-newTime))
'		delay( Max(0, floor((timeStep-delta)*1000)) )
'		delay( Max(0, timeStep*1000 - (Millisecs()-newTime)) )
		if not limitFrames and (timeStep*1000 - getCurrentLoopTime() > 0)
			delay(1)
		endif
	End Method
	?


	'percentage (0.0 - 1.0) of next position
	'each drawing function has to take care of it by itself
	Method getTween:float()
'		return Max(0.0, Min(1.0, updateAccumulator / getTimeStep()))
'		return updateAccumulator / getDelta()
		return updateAccumulator / getTimeStep()
	End Method


	'time between physical updates as fraction of a second
	'used to be able to give "velocity" in pixels per second (dx = 100 means 100px per second)
	Method getTimeStep:float()
		return timeStep
	End Method


	'time the current loop needed up to now
	Method getCurrentLoopTime:float()
		return Millisecs() - newTime
	End Method


	Method getLoopTimeAverage:float()
		if loopTimeCount > 0
			return loopTimeSum / loopTimeCount
		else
			return 0
		endif
	End Method


	'time since last update - the delta
	Method computeLastLoopTime:int()
		oldTime		= newTime
		newTime		= MilliSecs()
		lastLoopTime= (newTime - oldTime)
		oldTime		= newTime
		return lastLoopTime
	End Method


	'returns the fraction of the second the since the last update
	Method getDelta:float()
		'if lastupdate was longer than a normal timestep
		'return how many times it took longer
'		if lastUpdateTime > timestep*1000.0 then return lastUpdateTime / (timestep*1000.0)
		'else just return the timestep
		return Max(timestep, lastUpdateTime/1000.0)
	End Method


	Method GetTweenResult:float(currentValue:float, oldValue:float, avoidShaking:int=TRUE)
		local result:float = currentValue * GetTween() + oldValue * (1.0 - GetTween())
		if avoidShaking and Abs(result - currentValue) < 0.1 then return currentValue
		return result
	End Method


	'updates currentFps and currentUps
	Method updateSecond:int()
		secondGone	:+ lastLoopTime

		if secondGone >= 1000.0 'in ms
			secondGone 		= 0.0
			currentFps		= timesDrawn
			currentUps		= timesUpdated
			timesDrawn		= 0
			timesUpdated	= 0
			loopTimeSum		= GetLoopTimeAverage()
			looptimeCount	= 1
		endif
	End Method
End Type
endrem

