superstrict
'event-classes
Import brl.Map
Import brl.retro
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
		self._events.Sort()		'sort by age
		self._ticks = 0 		'begin
		print "TEventManager.Init()"
	End Method

	Method isStarted:Int()
		Return self._ticks <> -1
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

	Method registerListenerFunction:TLink( trigger:string, _function(triggeredByEvent:TEventBase), limitToObject:object=null )
		self.registerListener( trigger,	TEventListenerRunFunction.Create(_function, limitToObject) )
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

	Method triggerEvent(triggeredByEvent:TEventBase)
		local listeners:TList = TList(self._listeners.ValueForKey( lower(triggeredByEvent._trigger) ))
		if listeners <> null
			for local listener:TEventListenerBase = eachin listeners
				listener.onEvent(triggeredByEvent)
			Next
		endif
	End Method

	Method update()
		Assert self._ticks >= 0, "TEventManager: updating event manager that hasn't been prepared"
		self._processEvents()
		self._ticks :+ 1
	End Method

	Method _processEvents()
		If Not self._events.IsEmpty()
			Local event:TEventBase = TEventBase(self._events.First()) 			' get the next event
			if event<> null
				Local startTime:int = event.getStartTime()
'				Assert startTime >= self._ticks, "TEventManager: an future event didn't get triggered in time"
				If startTime <= _ticks						' is it time for this event?
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
	field _limitToObject:object

	method OnEvent:int(triggeredByEvent:TEventBase) Abstract
End Type

Type TEventListenerRunFunction extends TEventListenerBase
	field _function(triggeredByEvent:TEventBase)

	Function Create:TEventListenerRunFunction(_function(triggeredByEvent:TEventBase), limitToObject:object=null )
		local obj:TEventListenerRunFunction = new TEventListenerRunFunction
		obj._function		= _function
		obj._limitToObject	= limitToObject
		return obj
	End Function

	Method OnEvent:int(triggerEvent:TEventBase)
		if triggerEvent = null then return 0

		if self._limitToObject = null OR (self._limitToObject = triggerEvent._sender)
			self._function(triggerEvent)
		endif
	End Method
End Type

Type TEventBase
	Field _startTime:int
	Field _trigger:string = ""
	Field _sender:object = null
	field _data:object

	Method getStartTime:Int()
		Return self._startTime
	End Method

	Method onEvent()
	End Method

	Method getData:TData()
		return TData(self._data)
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

	Function Create:TEventSimple(trigger:string, data:object, sender:object=null)
		local obj:TEventSimple = new TEventSimple
		obj._trigger	= lower(trigger)
		obj._data	 	= data
		obj._sender		= sender
		return obj
	End Function
End Type

