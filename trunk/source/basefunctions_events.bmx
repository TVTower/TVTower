superstrict
'event-classes
Import brl.Map
Import brl.retro
?Threaded
Import Brl.threads
?
Import "basefunctions.bmx"  'get TData-Type
global EventManager:TEventManager = new TEventManager

Type TEventManager
	Field _events:TList = New TList			' holding events
	Field _ticks:int		= -1			' current time
	Field _listeners:TMap	= CreateMap()	' trigger => list of eventhandlers waiting for trigger

	Method getTicks:Int()
		Return self._ticks
	End Method

	' call after all events have been registered
	Method Init()
		Assert _ticks = -1, "TEventManager: preparing to start event manager while already started"
		self._events.Sort()				'sort by age
		self._ticks = Millisecs()		'begin
		print "TEventManager.Init()"
	End Method

	Method isStarted:Int()
		Return self._ticks > -1
	End Method

	Method isFinished:Int()
		Return self._events.IsEmpty()
	End Method

	' add a new listener to a trigger
	Method registerListener:TLink(trigger:string, eventListener:TEventListenerBase)
		trigger = lower(trigger)
		local listeners:TList = TList(self._listeners.ValueForKey(trigger))
		if listeners = null									'if not existing, create a new list
			listeners = CreateList()
			self._listeners.Insert(trigger, listeners)
		endif
		return listeners.AddLast(eventListener)					'add to list of listeners
	End Method

	Method registerListenerFunction:TLink( trigger:string, _function(triggeredByEvent:TEventBase), limitToSender:object=null, limitToReceiver:object=null )
		self.registerListener( trigger,	TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method

	Method registerListenerMethod:TLink( trigger:string, objectInstance:object, methodName:string, limitToSender:object=null, limitToReceiver:object=null )
		self.registerListener( trigger,	TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method

	' remove an event from a trigger
	Method unregisterListener(trigger:string, eventListener:TEventListenerBase)
		local listeners:TList = TList(self._listeners.ValueForKey( lower(trigger) ))
		if listeners <> null then listeners.remove(eventListener)
	End Method

	Method unregisterAllListeners(trigger:string)
		self._listeners.remove( lower(trigger) )
	End Method

	Method unregisterListenerByLink(link:TLink)
		link.remove()
	End Method



	' add a new event to the list
	Method registerEvent(event:TEventBase)
		self._events.AddLast(event)
	End Method

	'runs all listeners NOW ...returns amount of listeners
	Method triggerEvent:int(triggeredByEvent:TEventBase)
		?Threaded
		'if we have systemonly-event we cannot do it in a subthread
		'instead we just add that event to the upcoming events list
		if triggeredByEvent._channel = 1
			If CurrentThread()<>MainThread() then self.registerEvent(triggeredByEvent)
		endif
		?


		local listeners:TList = TList(self._listeners.ValueForKey( lower(triggeredByEvent._trigger) ))
		if listeners
			for local listener:TEventListenerBase = eachin listeners
				listener.onEvent(triggeredByEvent)
				'stop triggering the event if ONE of them vetos
				if triggeredByEvent.isVeto() then exit
			Next
			return listeners.count()
		endif
		return 0
	End Method

	Method update(onlyChannel:int=null)
		Assert self._ticks >= 0, "TEventManager: updating event manager that hasn't been prepared"
		self._processEvents(onlyChannel)
		self._ticks = Millisecs()
	End Method

	Method _processEvents(onlyChannel:int=null)
		If Not self._events.IsEmpty()
			Local event:TEventBase = TEventBase(self._events.First()) 			' get the next event
			if event<> null
				if onlyChannel<>null
					'system
					?Threaded
					if event._channel = 1 and event._channel <> onlyChannel
						If CurrentThread()<>MainThread() then return
					endif
					?
				endif

'				Assert startTime >= self._ticks, "TEventManager: an future event didn't get triggered in time"
				If event.getStartTime() <= _ticks			' is it time for this event?
					event.onEvent()							' start event
					if event._trigger <> ""					' only trigger event if _trigger is set
						self.triggerEvent( event )
					endif
					self._events.RemoveFirst()			' remove from list
					self._processEvents()				' another event may start on the same ticks - check again
				End If
			endif
		End If
	End Method
End Type

Type TEventListenerBase
	field _limitToSender:object		= Null
	field _limitToReceiver:object	= Null

	method OnEvent:int(triggeredByEvent:TEventBase) Abstract

	'returns whether to ignore the incoming event (eg. limits...)
	Method ignoreEvent:int(triggerEvent:TEventBase)
		if triggerEvent = null then return TRUE

		'Check limit for "sender"
		if self._limitToSender<>Null and triggerEvent._sender <> null
			'is different classname / type
			if string(self._limitToSender)<>null
				if string(self._limitToSender).toLower() <> TTypeId.ForObject(triggerEvent._sender).Name().toLower()
					return TRUE
				endif
			'different sender
			elseif self._limitToSender <> triggerEvent._sender
				return TRUE
			endif
		endif

		'Check limit for "receiver" - but only if receiver is set
		if self._limitToReceiver<>Null and triggerEvent._receiver<>Null
			'is different classname / type
			if string(self._limitToReceiver)<>null
				if string(self._limitToReceiver).toLower() <> TTypeId.ForObject(triggerEvent._receiver).Name().toLower()
					return TRUE
				endif
			'different receiver
			elseif self._limitToReceiver <> triggerEvent._receiver
				return TRUE
			endif
		endif

		return FALSE
	End Method
End Type

Type TEventListenerRunMethod extends TEventListenerBase
	field _methodName:string = ""
	field _objectInstance:object

	Function Create:TEventListenerRunMethod(objectInstance:object, methodName:string, limitToSender:object=null, limitToReceiver:object=null )
		local obj:TEventListenerRunMethod = new TEventListenerRunMethod
		obj._methodName			= methodName
		obj._objectInstance		= objectInstance
		obj._limitToSender		= limitToSender
		obj._limitToReceiver	= limitToReceiver
		return obj
	End Function

	Method OnEvent:int(triggerEvent:TEventBase)
		if triggerEvent = null then return 0

		if not self.ignoreEvent(triggerEvent)
			Local id:TTypeId		= TTypeId.ForObject( self._objectInstance )
			Local update:TMethod	= id.FindMethod( self._methodName )

			update.Invoke(self._objectInstance ,[triggerEvent])
			return true
		endif

		return true
	End Method
End Type

Type TEventListenerRunFunction extends TEventListenerBase
	field _function(triggeredByEvent:TEventBase)

	Function Create:TEventListenerRunFunction(_function(triggeredByEvent:TEventBase), limitToSender:object=null, limitToReceiver:object=null )
		local obj:TEventListenerRunFunction = new TEventListenerRunFunction
		obj._function			= _function
		obj._limitToSender		= limitToSender
		obj._limitToReceiver	= limitToReceiver
		return obj
	End Function

	Method OnEvent:int(triggerEvent:TEventBase)
		if triggerEvent = null then return 0

		if not self.ignoreEvent(triggerEvent) then return self._function(triggerEvent)

		return true
	End Method
End Type

Type TEventBase
	Field _startTime:int
	Field _trigger:string = ""
	Field _sender:object = null
	Field _receiver:object = null
	field _data:object
	field _veto:int = 0
	field _channel:int = 0		'no special channel

	Method getStartTime:Int()
		Return self._startTime
	End Method

	Method setStartTime:TEventBase(newStartTime:int=0)
		self._startTime = newStartTime
		return self
	End Method

	Method delayStart:TEventBase(delayMilliseconds:int=0)
		self._startTime:+delayMilliseconds

		return self
	End Method

	Method setVeto(); self._veto = true; End Method
	Method isVeto:int(); return (_veto=true); End Method

	Method onEvent()
	End Method

	Method getReceiver:object()
		return self._receiver
	End Method

	Method getSender:object()
		return self._sender
	End Method

	Method getData:TData()
		return TData(self._data)
	End Method

	Method getTrigger:string()
		return lower(_trigger)
	End Method

	'returns wether trigger is the same
	Method isTrigger:int(trigger:string)
		return _trigger = lower(trigger)
	End Method

	' to sort the event queue by time
	Method Compare:Int(other:Object)
		Local event:TEventBase = TEventBase(other)
		If Not event Then Return Super.Compare(other)

		Local mytime:int	= Self.getStartTime()
		Local theirtime:int = event.getStartTime()

		If Self.getStartTime() > event.getStartTime() Then Return 1 .. 			' i'm newer
		Else If Self.getStartTime() < event.getStartTime() Then Return -1 ..	' they're newer
		Else Return 0
	End Method
End Type

Type TEventSimple extends TEventBase

	Function Create:TEventSimple(trigger:string, data:object=null, sender:object=null, receiver:object=null, channel:int=0)
		if data=Null then data = TData.Create()
		local obj:TEventSimple = new TEventSimple
		obj._trigger	= lower(trigger)
		obj._data	 	= data
		obj._sender		= sender
		obj._receiver	= receiver
		obj._channel	= channel
		obj.setStartTime( EventManager.getTicks() )
		return obj
	End Function
End Type

