superstrict
Import "basefunctions_events.bmx"

'Import Brl.threads
'class for smooth framerates

'Global drawMutex:TMutex = CreateMutex()

Type TDeltaTimer
	field newTime:int 				= 0
	field oldTime:int 				= 0.0
	field loopTime:float			= 0.1
	field deltaTime:float			= 0.1		'10 updates per second
	field accumulator:float			= 0.0
	field tweenValue:float			= 0.0		'between 0..1 (0 = no tween, 1 = full tween)

	field fps:int = 0
	field ups:int = 0
	field deltas:float = 0.0
	field timesDrawn:int = 0
	field timesUpdated:int = 0
	field secondGone:float = 0.0

	field totalTime:float = 0.0

	Function Create:TDeltaTimer(physicsFps:int = 60)
		local obj:TDeltaTimer	= new TDeltaTimer
		obj.deltaTime			= 1.0 / float(physicsFps)
		obj.newTime				= MilliSecs()
		obj.oldTime				= 0.0
		return obj
	End Function

	Method Loop()
		self.newTime		= MilliSecs()
		if self.oldTime = 0.0 then self.oldTime = self.newTime - 1
		self.secondGone		:+ (self.newTime - self.oldTime)
		self.loopTime		= (self.newTime - self.oldTime) / 1000.0
		self.oldTime		= self.newTime

		if self.secondGone >= 1000.0 'in ms
			self.secondGone 	= 0.0
			self.fps			= self.timesDrawn
			self.ups			= self.timesUpdated
			self.deltas			= 0.0
			self.timesDrawn 	= 0
			self.timesUpdated	= 0
		endif

		'fill time available for this loop
		self.loopTime = Min(0.25, self.loopTime)	'min 4 updates per seconds 1/4
		self.accumulator :+ self.loopTime

		'update gets deltatime - fraction of a second (speed = pixels per second)
	'	LockMutex(drawMutex)
		While self.accumulator >= self.deltaTime
			self.totalTime		:+ self.deltaTime
			self.accumulator	:- self.deltaTime
			self.timesUpdated	:+ 1
			EventManager.triggerEvent( "App.onUpdate", TEventSimple.Create("App.onUpdate",null))
		Wend
	'	UnLockMutex(drawMutex)

	'	if TryLockMutex(drawMutex)
			'how many % of ONE update are left - 1.0 would mean: 1 update missing
			self.tweenValue = self.accumulator / self.deltaTime

			'draw gets tweenvalue (0..1)
			self.timesDrawn :+1
			EventManager.triggerEvent( "App.onDraw", TEventSimple.Create("App.onDraw", string(self.tweenValue) ) )
			'Delay(1)
	'		UnlockMutex(drawMutex)
	'	endif
	End Method



	Method singleThreadLoop()
		self.newTime		= MilliSecs()
		if self.oldTime = 0.0 then self.oldTime = self.newTime - 1
		self.secondGone		:+ (self.newTime - self.oldTime)
		self.loopTime		= (self.newTime - self.oldTime) / 1000.0
		self.oldTime		= self.newTime

		if self.secondGone >= 1000.0 'in ms
			self.secondGone 	= 0.0
			self.fps			= self.timesDrawn
			self.ups			= self.timesUpdated
			self.deltas			= 0.0
			self.timesDrawn 	= 0
			self.timesUpdated	= 0
		endif

		'fill time available for this loop
		self.loopTime = Min(0.25, self.loopTime)	'min 4 updates per seconds 1/4
		self.accumulator :+ self.loopTime

		'update gets deltatime - fraction of a second (speed = pixels per second)
		While self.accumulator >= self.deltaTime
			self.totalTime		:+ self.deltaTime
			self.accumulator	:- self.deltaTime
			self.timesUpdated	:+ 1
			EventManager.triggerEvent( "App.onUpdate", TEventSimple.Create("App.onUpdate",null))
		Wend
		'how many % of ONE update are left - 1.0 would mean: 1 update missing
		self.tweenValue = self.accumulator / self.deltaTime

		'draw gets tweenvalue (0..1)
		self.timesDrawn :+1
		EventManager.triggerEvent( "App.onDraw", TEventSimple.Create("App.onDraw", string(self.tweenValue) ) )
		'Delay(1)
	End Method

	'tween value = oldposition*tween + (1-tween)*newPosition
	'so its 1 if no movement, 0 for full movement to new position
	'each drawing function has to take care of it by itself
	Method getTween:float()
		return self.tweenValue
	End Method

	'time between physical updates as fraction to a second
	'used to be able to give "velocity" in pixels per second (dx = 100 means 100px per second)
	Method getDeltaTime:float()
		return self.deltaTime
	End Method
End Type



