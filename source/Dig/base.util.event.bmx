Rem
	====================================================================
	Event Manager
	====================================================================

	This class provides an event manager handling all incoming events.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2021 Ronny Otto, digidea.de

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
Import brl.Map
?Not bmxng
'using custom to have support for const/function reflection
Import "external/reflectionExtended/reflection.bmx"
'Import BRL.Reflection
?bmxng
'ng has it built-in!
Import BRL.Reflection
?
?Threaded
Import Brl.threads
?
Import "base.util.logger.bmx"
Import "base.util.data.bmx"
Import "base.util.time.bmx"
Import Brl.ObjectList



Global EventManager:TEventManager = New TEventManager

Function TriggerBaseEvent(trigger:String, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.triggerEvent(TEventBase.Create(trigger, data, sender, receiver, channel))
End Function

Function TriggerBaseEvent(eventKey:TEventKey, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.triggerEvent(TEventBase.Create(eventKey, data, sender, receiver, channel))
End Function

Function TriggerBaseEvent(eventKeyID:Int, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.triggerEvent(TEventBase.Create(eventKeyID, data, sender, receiver, channel))
End Function

Function TriggerBaseEvent(event:TEventBase)
	EventManager.triggerEvent(event)
End Function

Function GetEventKey:TEventKey(text:String, createIfMissing:Int)
	Return EventManager.GetEventKey(text, createIfMissing)
End Function

Function GetEventKey:TEventKey(text:TLowerString, createIfMissing:Int)
	Return EventManager.GetEventKey(text, createIfMissing)
End Function

Function GetEventKey:TEventKey(eventKeyID:Int)
	Return EventManager.GetEventKey(eventKeyID)
End Function




Type TEventManager
	'holding events
	Field _events:TList = New TList
	'current time
	Field _ticks:Int = -1
	'list of eventhandlers waiting for trigger
	'"eventkey.id -> listener"
	Field _listeners:TIntMap = new TIntMap()
	Field eventsProcessed:Int = 0
	Field listenersCalled:Int = 0
	Field eventsTriggered:Int = 0

	'storing TEventKey by "id" for lookup
	Field eventKeyIDMap:TIntMap = new TIntMap
	'storing TEventKey by "text" (TLowerstring) for fast lookup
	Field eventKeyTextMap:TMap = new TMap


	'returns how many update ticks are gone since start
	Method getTicks:Int()
		Return _ticks
	End Method


	'initialize the event manager
	Method Init()
		'Assert _ticks = -1, "TEventManager: preparing to start event manager while already started"
		If _ticks = -1
			'sort by age
			_events.Sort()
			'begin
			_ticks = Time.GetTimeGone()
			TLogger.Log("TEventManager.Init()", "OK", LOG_LOADING)
		EndIf
	End Method


	'returns whether the manager was started
	Method isStarted:Int()
		Return _ticks > -1
	End Method


	'returns whether the manager has nothing to do
	Method isFinished:Int()
		Return _events.IsEmpty()
	End Method


	Method GetEventKey:TEventKey(id:Int)
		Return TEventKey(eventKeyIDMap.ValueForKey(id))
	End Method

	Method GetEventKey:TEventKey(text:String)
		Return TEventKey(eventKeyTextMap.ValueForKey( new TLowerString(text) ))
	End Method

	Method GetEventKey:TEventKey(text:TLowerString)
		Return TEventKey(eventKeyTextMap.ValueForKey( text ))
	End Method

	Method GetEventKey:TEventKey(text:String, createIfMissing:Int)
		Local key:TEventKey = GetEventKey(text)
		If Not key and createIfMissing Then key = GenerateEventKey(text)
		Return key
	End Method

	Method GetEventKey:TEventKey(text:TLowerString, createIfMissing:Int)
		Local key:TEventKey = GetEventKey(text)
		If Not key and createIfMissing Then key = GenerateEventKey(text)
		Return key
	End Method


	Method GenerateEventKey:TEventKey(text:String)
		Return GenerateEventKey( new TLowerString(text) )
	End Method


	Method GenerateEventKey:TEventKey(text:TLowerString)
		'we cannot simply use a "increasing ID" as the order of the
		'added event keys is not the same everytime
		'Objects could store eventKeys for less GarbageCollector heavy
		'event triggering.
		'So instead of "id = lastID + 1" we generate the hash
		'from the string and use it
		
		'a string hash _could_ collide, so we check for that too
		
		
	
		local e:TEventKey = new TEventKey
		e.id = text.ToString().ToLower().Hash()
		e.text = text
		
		local existingKey:TEventKey = TEventKey(eventKeyIDMap.ValueForKey(e.id))
		if existingKey then Throw "GenerateEventKey(): key for ID="+e.id+" already exists. Hash collision?"
		
		eventKeyTextMap.Insert(e.text, e)
		eventKeyIDMap.Insert(e.id, e)
		
		Return e
	End Method




	Method GetRegisteredListenersCount:Int()
		Local count:Int = 0
		For Local list:TObjectList = EachIn _listeners.Values()
			For Local listener:TEventListenerBase = EachIn list
				count :+1
			Next
		Next
		Return count
	End Method


	'add a new listener to a trigger
	Method RegisterListener:TEventListenerBase(trigger:String, eventListener:TEventListenerBase)
		'true = register key if needed
		local eventKey:TEventKey = GetEventKey(trigger, True)
		Return RegisterListener(eventKey, eventListener)
	End Method

	'add a new listener to a trigger
	Method RegisterListener:TEventListenerBase(eventKeyID:Int, eventListener:TEventListenerBase)
		local eventKey:TEventKey = GetEventKey(eventKeyID)
		If not eventKey Then Throw "Cannot RegisterListener() with unknown eventKey. ID="+eventKeyID

		Return RegisterListener(eventKey, eventListener)
	End Method


	Method RegisterListener:TEventListenerBase(eventKey:TEventKey, eventListener:TEventListenerBase)
		Local listeners:TObjectList = TObjectList(_listeners.ValueForKey(eventKey.id))
		If Not listeners
			listeners = New TObjectList
			_listeners.Insert(eventKey.id, listeners)
		EndIf

		listeners.AddLast(eventListener)

		Return eventListener
	End Method


	'register a function getting called as soon as a trigger is fired
	Method RegisterListenerFunction:TEventListenerBase( trigger:String, _function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( trigger, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method

	Method RegisterListenerFunction:TEventListenerBase( eventKey:TEventKey, _function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKey, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method

	Method RegisterListenerFunction:TEventListenerBase( eventKeyID:Int, _function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKeyID, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method


	'register a method getting called as soon as a trigger is fired
	Method RegisterListenerMethod:TEventListenerBase( trigger:String, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( trigger, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method
	Method RegisterListenerMethod:TEventListenerBase( eventKey:TEventKey, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKey, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method
	Method RegisterListenerMethod:TEventListenerBase( eventKeyID:Int, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKeyID, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method


	'remove an event listener from all trigger
	Method UnregisterListener(eventListener:TEventListenerBase)
		For Local listeners:TObjectList = EachIn _listeners.Values()
			listeners.Remove(eventListener)
		Next
	End Method

	'remove an event listener from a specific trigger
	Method UnregisterListener(eventListener:TEventListenerBase, trigger:TLowerString)
		Local eventKey:TEventKey = GetEventKey(trigger)
		If not eventKey Then Return

		Local listeners:TObjectList = TObjectList(_listeners.ValueForKey( eventKey.id ))
		If listeners Then listeners.Remove(eventListener)
	End Method

	'remove an event listener from a specific trigger
	Method UnregisterListener(eventListener:TEventListenerBase, trigger:String)
		Local eventKey:TEventKey = GetEventKey(trigger)
		If not eventKey Then Return

		Local listeners:TObjectList = TObjectList(_listeners.ValueForKey( eventKey.id ))
		If listeners Then listeners.Remove(eventListener)
	End Method


	'removes a listener using a list of eventlisteners
	Method UnregisterListenersList(list:TList)
		For Local listener:TEventListenerBase = EachIn list
			UnregisterListener(listener)
		Next
	End Method


	'removes a listener using a list of eventlisteners
	Method UnregisterListenersArray(arr:TEventListenerBase[])
		For Local listener:TEventListenerBase = EachIn arr
			unregisterListener(listener)
		Next
	End Method


	'remove all listeners having the given receiver or sender as limit
	Method UnregisterListenerByLimit(limitReceiver:Object=Null, limitSender:Object=Null)
		For Local list:TObjectList = EachIn _listeners.Values()
			For Local listener:TEventListenerBase = EachIn list
				'if one of both limits hits, remove that listener
				If ObjectsAreEqual(listener._limitToSender, limitSender) Or..
				   ObjectsAreEqual(listener._limitToReceiver, limitReceiver)
					list.Remove(listener)
				EndIf
			Next
		Next
	End Method


	'removes all listeners listening to a specific trigger
	Method UnregisterListenersByTrigger(trigger:String, limitReceiver:Object=Null, limitSender:Object=Null)
		Local eventKey:TEventKey = GetEventKey(trigger)
		If not eventKey Then Return

		'remove all of that trigger
		If Not limitReceiver And Not limitSender
			_listeners.Remove( eventKey.id )
		'remove all defined by limits
		Else
			Local triggerListeners:TObjectList = TObjectList(_listeners.ValueForKey( eventKey.id ))
			For Local listener:TEventListenerBase = EachIn triggerListeners
				'if one of both limits hits, remove that listener
				If ObjectsAreEqual(listener._limitToSender, limitSender) Or..
				   ObjectsAreEqual(listener._limitToReceiver, limitReceiver)
					triggerListeners.remove(listener)
				EndIf
			Next
		EndIf
	End Method
	
	
	Method GetListeners:TObjectList(eventKeyID:Int)
		Return TObjectList( _listeners.ValueForKey(eventKeyID) ) 
	End Method
	

	'add a new event to the list
	Method RegisterEvent(event:TEventBase)
		_events.AddLast(event)
	End Method


	'runs all listeners NOW ...returns amount of listeners
	Method TriggerEvent:Int(triggeredByEvent:TEventBase)
		If Not triggeredByEvent Then Return 0

		?Threaded
		'if we have systemonly-event we cannot do it in a subthread
		'instead we just add that event to the upcoming events list
		If triggeredByEvent._channel = 1
			If CurrentThread()<>MainThread() Then RegisterEvent(triggeredByEvent)
		EndIf
		?

		?debug
		if not triggeredByEvent.GetEventKey() then Throw "triggering event without key"
		?

		Local listeners:TObjectList = GetListeners(triggeredByEvent.GetEventKeyID())
		If listeners
			'use a _copy_ of the original listeners to avoid concurrent
			'modification within the loop
			'listeners = listeners.Copy()
			For Local listener:TEventListenerBase = EachIn listeners
				listenersCalled :+ 1
				listener.onEvent(triggeredByEvent)
				'stop triggering the event if ONE of them vetos
				If triggeredByEvent.isVeto() Then Exit
			Next
		EndIf

		'run individual event method
		If Not triggeredByEvent.IsVeto()
			eventsTriggered :+ 1
			triggeredByEvent.onEvent()
		EndIf

		If listeners
			Return listeners.count()
		Else
			Return 0
		EndIf
	End Method


	'update the event manager - call this each cycle of your app loop
	Method Update(onlyChannel:Int=Null)
		If Not isStarted() Then Init()
		'Assert _ticks >= 0, "TEventManager: updating event manager that hasn't been prepared"
		_ProcessEvents(onlyChannel)
		_ticks = Time.GetTimeGone()
	End Method


	'process all events currently in the queue
	Method _ProcessEvents(onlyChannel:Int=Null)
		If Not _events.IsEmpty()
			' get the next event
			Local event:TEventBase = TEventBase(_events.First())
			If event <> Null
				If onlyChannel <> Null
					'system
					?Threaded
					If event._channel = 1 And event._channel <> onlyChannel
						If CurrentThread() <> MainThread() Then Return
					EndIf
					?
				EndIf

				' is it time for this event?
				If event.getStartTime() <= _ticks
					triggerEvent( event )

					' remove from list
					_events.RemoveFirst()
					' another event may start on the same tick - check again
					_processEvents()
				EndIf
			EndIf
		EndIf
	End Method


	Method DumpListeners()
		Print "==== EVENT MANAGER DUMP LISTENERS ===="
		Print "Events: " + _events.Count()

		Local listeners:Int
		For Local l:TObjectList = EachIn EventManager._listeners.Values()
			listeners :+ l.Count()
		Next
		Print "Event Listeners: " + listeners

		For Local intKey:TIntKey = EachIn EventManager._listeners.Keys()
			local eventKey:TEventKey = GetEventKey(intKey.value)
			if not eventKey then Throw "EventManager._listeners contain obsolete eventKeys for ID="+intKey.value
			
			For Local elb:TEventListenerBase = EachIn TObjectList( _listeners.ValueForKey(eventKey.id) )
				If TEventListenerRunFunction(elb)
					Print "KEY="+eventKey.text.ToString()+"  :: run function"
				ElseIf TEventListenerRunMethod(elb)
					Local tyd:TTypeId = TTypeId.ForObject(TEventListenerRunMethod(elb)._objectInstance)
					If tyd
						Print "KEY="+eventKey.text.ToString()+"  :: run method. instance "+ tyd.name()
					Else
						Print "KEY="+eventKey.text.ToString()+"  :: run method. instance UNKNOWN"
					EndIf
				Else
					Print "KEY="+eventKey.text.ToString()+"  :: run " + TTypeId.ForObject(elb).name()
				EndIf
			Next
		Next

		Print "====="
	End Method


	'check whether a checkedObject equals to a limitObject
	'1) is the same object
	'2) is of the same type
	'3) is extended from same type
	Function ObjectsAreEqual:Int(checkedObject:Object, limit:Object)
		'one of both is empty
		If Not checkedObject Then Return False
		If Not limit Then Return False
		'same object (also compares strings if they are both strings)
		If checkedObject = limit Then Return True

		'if both strings we just compare and also return if different
		If String(limit) And String(checkedObject)
			Return String(limit) = String(checkedObject)
		EndIf

		'check if classname / type is the same (type-name/id given as limit )
		Local typeId:TTypeId
		If TTypeId(limit)
			typeId = TTypeId(limit)
		ElseIf String(limit)
			typeId = TTypeId.ForName(String(limit))
		EndIf

		'got a valid classname and checked object is same type or does extend from that type
		If typeId And TTypeId.ForObject(checkedObject).ExtendsType(typeId) Then Return True

		Return False
	End Function
End Type




'each event key consists of a fast to retrieve numeric ID
'and a textual representation (allowing for "wildcards") 
Type TEventKey
	Field id:Int
	Field text:TLowerString

private
	'avoid outside world being able to create new event keys without Generate()
	Method New()
	End Method
End Type




'simple basic class for an event listener
Type TEventListenerBase
	Field _limitToSender:Object
	Field _limitToReceiver:Object


	'what to do if the event happens
	Method OnEvent:Int(triggeredByEvent:TEventBase) Abstract


	'returns whether to ignore the incoming event (eg. limits...)
	'an event can be ignored if the sender<>limitSender or receiver<>limitReceiver
	Method ignoreEvent:Int(triggerEvent:TEventBase)
		If triggerEvent = Null Then Return True

		'Check limit for "sender"
		'if the listener wants a special sender but the event does not have one... ignore
		'old if self._limitToSender and triggerEvent._sender
		'new
		If _limitToSender
			'we want a sender but got none - ignore (albeit objects are NOT equal)
			If Not triggerEvent._sender Then Return True

			If Not TEventManager.ObjectsAreEqual(triggerEvent._sender, _limitToSender) Then Return True
		EndIf

		'Check limit for "receiver" - but only if receiver is set
		'if the listener wants a special receiver but the event does not have one... ignore
		'old: if self._limitToReceiver and triggerEvent._receiver
		'new
		If _limitToReceiver
			'we want a receiver but got none - ignore (albeit objects are NOT equal)
			If Not triggerEvent._receiver Then Return True

			If Not TEventManager.ObjectsAreEqual(triggerEvent._receiver, _limitToReceiver) Then Return True
		EndIf

		Return False
	End Method
End Type




Type TEventListenerRunMethod Extends TEventListenerBase
	Field _methodName:String = ""
	Field _objectInstance:Object
	Field _method:TMethod {nosave}


	Function Create:TEventListenerRunMethod(objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Local obj:TEventListenerRunMethod = New TEventListenerRunMethod
		obj._methodName	= methodName
		obj._objectInstance = objectInstance
		obj._limitToSender = limitToSender
		obj._limitToReceiver = limitToReceiver
		Return obj
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		If triggerEvent = Null Then Return 0

		If Not Self.ignoreEvent(triggerEvent)
			If Not _method
				Local id:TTypeId = TTypeId.ForObject( _objectInstance )
				_method = id.FindMethod( _methodName )
			EndIf

			If _method
				_method.Invoke(_objectInstance ,[triggerEvent])
				Return True
			Else
				TLogger.Log("TEventListener.OnEvent", "Tried to call non-existing method ~q"+_methodName+"~q.", LOG_WARNING | LOG_DEBUG)
				Return False
			EndIf
		EndIf

		Return True
	End Method
End Type




Type TEventListenerRunFunction Extends TEventListenerBase
	Field _function:Int(triggeredByEvent:TEventBase)


	Function Create:TEventListenerRunFunction(_function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Local obj:TEventListenerRunFunction = New TEventListenerRunFunction
		obj._function = _function
		obj._limitToSender = limitToSender
		obj._limitToReceiver = limitToReceiver
		Return obj
	End Function


	Method OnEvent:Int(triggerEvent:TEventBase)
		If triggerEvent = Null Then Return 0

		If Not ignoreEvent(triggerEvent) Then Return _function(triggerEvent)

		Return True
	End Method
End Type




Type TEventBase
private
	Field _eventKey:TEventKey
	Field _data:Object
public
	Field _startTime:Int
	Field _sender:Object = Null
	Field _receiver:Object = Null
	Field _status:Int = 0
	Field _channel:Int = 0		'no special channel
	
	Global stubData:TData = new TData

	Const STATUS_VETO:Int = 1
	Const STATUS_ACCEPTED:Int = 2

	Function Create:TEventBase(eventKey:TEventKey, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
		Local obj:TEventBase = New TEventBase
		obj._eventKey = eventKey
		obj._data = data
		obj._sender = sender
		obj._receiver = receiver
		obj._channel = channel
		obj.SetStartTime( EventManager.getTicks() )
		Return obj
	End Function


	Function Create:TEventBase(trigger:String, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
		Local eventKey:TEventKey = EventManager.GetEventKey(trigger, True)
		Return Create(eventKey, data, sender, receiver, channel)
	End Function


	Function Create:TEventBase(eventKeyID:Int, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
		Local eventKey:TEventKey = EventManager.GetEventKey(eventKeyID)
		if not eventKey Then Throw "No eventKey found for ID="+eventKeyID

		Return Create(eventKey, data, sender, receiver, channel)
	End Function


	Method GetEventKeyID:Int()
		if _eventKey Then Return _eventKey.id
		Return 0
	End Method
	
	
	Method SetEventKey(eventKey:TEventKey)
		_eventKey = eventKey
	End Method


	Method GetEventKey:TEventKey()
		Return _eventKey
	End Method


	Method GetStartTime:Int()
		Return _startTime
	End Method


	Method SetStartTime:TEventBase(newStartTime:Int=0)
		_startTime = newStartTime
		Return Self
	End Method


	Method DelayStart:TEventBase(delayMilliseconds:Int=0)
		_startTime :+ delayMilliseconds

		Return Self
	End Method


	Method SetStatus(status:Int, enable:Int=True)
		If enable
			_status :| status
		Else
			_status :& ~status
		EndIf
	End Method


	Method SetVeto(bool:Int=True)
		SetStatus(STATUS_VETO, bool)
	End Method


	Method IsVeto:Int()
		Return (_status & STATUS_VETO) > 0
	End Method


	Method SetAccepted(bool:Int=True)
		SetStatus(STATUS_ACCEPTED, bool)
	End Method


	Method IsAccepted:Int()
		Return (_status & STATUS_ACCEPTED) > 0
	End Method


	Method onEvent()
	End Method


	Method GetReceiver:Object()
		Return _receiver
	End Method


	Method GetSender:Object()
		Return _sender
	End Method


	Method HasData:Int()
		Return TData(_data) <> null
	End Method


	Method GetData:TData(returnStubIfMissing:Int = True)
		If returnStubIfMissing and not TData(_data)
			Return stubData
		EndIf
		Return TData(_data)
	End Method


	Method SetData(data:TData)
		_data = data
	End Method


	Method GetEventKeyText:TLowerString()
		Return _eventKey.text
	End Method


	'returns wether trigger is the same
	Method IsTrigger:Int(trigger:String)
		Return _eventKey.text.Compare(trigger) = 0
	End Method


	Method Trigger:TEventBase()
		EventManager.triggerEvent(Self)
		Return Self
	End Method


	Method Register:TEventBase()
		EventManager.registerEvent(Self)
		Return Self
	End Method


	' to sort the event queue by time
	Method Compare:Int(other:Object)
		Local event:TEventBase = TEventBase(other)
		If event
			' i'm newer
			If getStartTime() > event.getStartTime() Then Return 1
			' they're newer
			If getStartTime() < event.getStartTime() Then Return -1
		EndIf

		' let the basic object decide
		Return Super.Compare(other)
	End Method
End Type

