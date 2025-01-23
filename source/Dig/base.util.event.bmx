Rem
	====================================================================
	Event Manager
	====================================================================

	This class provides an event manager handling all incoming events.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2025 Ronny Otto, digidea.de

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
Import BRL.Reflection
Import Brl.threads
Import "base.util.logger.bmx"
Import "base.util.data.bmx"
Import "base.util.time.bmx"
Import "base.util.longmap.bmx"
Import Brl.ObjectList


Extern
	Function event_bbRefPushObject( p:Byte Ptr,obj:Object )="void bbRefPushObject(BBObject **,BBObject *)!"
End Extern


Global EventManager:TEventManager = New TEventManager

Function TriggerBaseEvent(trigger:String, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.triggerEvent(TEventBase.Create(trigger, data, sender, receiver, channel))
End Function

Function TriggerBaseEvent(eventKey:TEventKey, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.triggerEvent(TEventBase.Create(eventKey, data, sender, receiver, channel))
End Function

Function TriggerBaseEvent(eventKeyID:Long, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.triggerEvent(TEventBase.Create(eventKeyID, data, sender, receiver, channel))
End Function

Function TriggerBaseEvent(event:TEventBase)
	EventManager.triggerEvent(event)
End Function

Function RegisterBaseEvent(trigger:String, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.registerEvent(TEventBase.Create(trigger, data, sender, receiver, channel))
End Function

Function RegisterBaseEvent(eventKey:TEventKey, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.registerEvent(TEventBase.Create(eventKey, data, sender, receiver, channel))
End Function

Function RegisterBaseEvent(eventKeyID:Long, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
	EventManager.registerEvent(TEventBase.Create(eventKeyID, data, sender, receiver, channel))
End Function

Function RegisterBaseEvent(event:TEventBase)
	EventManager.registerEvent(event)
End Function

Function GetEventKey:TEventKey(text:String, createIfMissing:Int)
	Return EventManager.GetEventKey(text, createIfMissing)
End Function

Function GetEventKey:TEventKey(text:TLowerString, createIfMissing:Int)
	Return EventManager.GetEventKey(text, createIfMissing)
End Function

Function GetEventKey:TEventKey(eventKeyID:Long)
	Return EventManager.GetEventKey(eventKeyID)
End Function


Function GetEventChannel:TEventChannel(text:String, createIfMissing:Int = False) Inline
	Return EventManager.GetEventChannel(text, createIfMissing)
End Function

Function GetEventChannel:TEventChannel(eventChannelID:Long) Inline
	Return EventManager.GetEventChannel(eventChannelID)
End Function




Type TEventManager
	'holding events
	Field _events:TList = New TList
	'current time
	Field _ticks:Long = -1
	'list of eventhandlers waiting for trigger
	'"eventkey.id -> listener"
	Field _listeners:TLongMap = new TLongMap
	Field eventsProcessed:Int = 0
	Field listenersCalled:Int = 0
	Field eventsTriggered:Int = 0
	
	'storing TEventKey by "id" for lookup
	Field eventKeyIDMap:TLongMap = new TLongMap
	'storing TEventKey by "text" (TLowerstring) for fast lookup
	Field eventKeyTextMap:TMap = new TMap
	'storing TEventChannel by "id" for lookup
	Field eventChannelIDMap:TLongMap = new TLongMap
	'storing TEventChannel by "text" (lower cased) for fast lookup
	Field eventChannelTextMap:TStringMap = new TStringMap
	
	'Field _onEventMutex:TMutex = CreateMutex()
	Field _listenersMutex:TMutex = CreateMutex()
	Field _eventsMutex:TMutex = CreateMutex()
	Field _eventKeyMutex:TMutex = CreateMutex()
	Field _eventChannelMutex:TMutex = CreateMutex()


	'returns how many update ticks are gone since start
	Method getTicks:Long()
		Return _ticks
	End Method


	'initialize the event manager
	Method Init()
		'Assert _ticks = -1, "TEventManager: preparing to start event manager while already started"
		If _ticks = -1
			'sort by age
			LockMutex(_eventsMutex)
			_events.Sort()
			UnlockMutex(_eventsMutex)
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


	Method GetEventChannel:TEventChannel(id:Long)
		LockMutex(_eventChannelMutex)
		Local c:TEventChannel = TEventChannel(eventChannelIDMap.ValueForKey( id ))
		UnlockMutex(_eventChannelMutex)

		Return c
	End Method

	Method GetEventChannel:TEventChannel(text:String, createIfMissing:Int = False)
		LockMutex(_eventChannelMutex)
		Local c:TEventChannel = TEventChannel(eventKeyTextMap.ValueForKey( text.ToLower() ))
		UnlockMutex(_eventChannelMutex)

		If Not c and createIfMissing Then c = GenerateEventChannel(text)

		Return c
	End Method


	Method GenerateEventChannel:TEventChannel(text:String)
		'we cannot simply use a "increasing ID" as the order of the
		'added event keys is not the same everytime
		'Objects could store eventKeys for less GarbageCollector heavy
		'event triggering.
		'So instead of "id = lastID + 1" we generate the hash
		'from the string and use it
		
		'a string hash _could_ collide, so we check for that too
		
		Local lowerText:String = text.ToLower()
		Local e:TEventChannel = new TEventChannel
		e.id = lowerText.Hash()
		e.text = text
		
		LockMutex(_eventChannelMutex)
		Local existingChannel:TEventChannel = TEventChannel(eventChannelIDMap.ValueForKey(e.id))
		If existingChannel
			UnlockMutex(_eventChannelMutex)
			Throw "GenerateEventKey(): key for ID="+e.id+" already exists. Hash collision?"
		EndIf
		
		eventChannelTextMap.Insert(lowerText, e)
		eventChannelIDMap.Insert(e.id, e)
		UnlockMutex(_eventChannelMutex)
		
		Return e
	End Method



	Method GetEventKey:TEventKey(id:Long)
		LockMutex(_eventKeyMutex)
		Local k:TEventKey = TEventKey(eventKeyIDMap.ValueForKey(id))
		UnlockMutex(_eventKeyMutex)
		Return k
	End Method

	Method GetEventKey:TEventKey(text:String)
		LockMutex(_eventKeyMutex)
		Local k:TEventKey = TEventKey(eventKeyTextMap.ValueForKey( new TLowerString(text) ))
		UnlockMutex(_eventKeyMutex)
		Return k
	End Method

	Method GetEventKey:TEventKey(text:TLowerString)
		LockMutex(_eventKeyMutex)
		Local k:TEventKey = TEventKey(eventKeyTextMap.ValueForKey( text ))
		UnlockMutex(_eventKeyMutex)
		Return k
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
		
		LockMutex(_eventKeyMutex)
		local existingKey:TEventKey = TEventKey(eventKeyIDMap.ValueForKey(e.id))
		If existingKey
			UnlockMutex(_eventKeyMutex)
			Throw "GenerateEventKey(): key for ID="+e.id+" already exists. Hash collision?"
		EndIf
		
		eventKeyTextMap.Insert(e.text, e)
		eventKeyIDMap.Insert(e.id, e)
		UnlockMutex(_eventKeyMutex)
		
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
	Method RegisterListener:TEventListenerBase(eventKeyID:Long, eventListener:TEventListenerBase)
		local eventKey:TEventKey = GetEventKey(eventKeyID)
		If not eventKey Then Throw "Cannot RegisterListener() with unknown eventKey. ID="+eventKeyID

		Return RegisterListener(eventKey, eventListener)
	End Method


	Method RegisterListener:TEventListenerBase(eventKey:TEventKey, eventListener:TEventListenerBase)
		If not TryLockMutex(_listenersMutex)
			TLogger.Log("RegisterListener()", "Mutex was still locked, waiting.", LOG_DEBUG)
			LockMutex(_listenersMutex)
		EndIf
		Local listeners:TObjectList = TObjectList(_listeners.ValueForKey(eventKey.id))
		If Not listeners
			listeners = New TObjectList
			_listeners.Insert(eventKey.id, listeners)
		EndIf

		listeners.AddLast(eventListener)
		UnlockMutex(_listenersMutex)

		Return eventListener
	End Method


	'register a function getting called as soon as a trigger is fired
	Method RegisterListenerFunction:TEventListenerBase( trigger:String, _function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( trigger, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method

	Method RegisterListenerFunction:TEventListenerBase( eventKey:TEventKey, _function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKey, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method

	Method RegisterListenerFunction:TEventListenerBase( eventKeyID:Long, _function:Int(triggeredByEvent:TEventBase), limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKeyID, TEventListenerRunFunction.Create(_function, limitToSender, limitToReceiver) )
	End Method


	'register a method getting called as soon as a trigger is fired
	Method RegisterListenerMethod:TEventListenerBase( trigger:String, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( trigger, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method
	Method RegisterListenerMethod:TEventListenerBase( eventKey:TEventKey, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKey, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method
	Method RegisterListenerMethod:TEventListenerBase( eventKeyID:Long, objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Return RegisterListener( eventKeyID, TEventListenerRunMethod.Create(objectInstance, methodName, limitToSender, limitToReceiver) )
	End Method


	'remove an event listener from all trigger
	Method UnregisterListener(eventListener:TEventListenerBase)
		If not TryLockMutex(_listenersMutex)
			TLogger.Log("UnregisterListener() (Var1)", "Mutex was still locked, waiting.", LOG_DEBUG)
			LockMutex(_listenersMutex)
		EndIf
		For Local listeners:TObjectList = EachIn _listeners.Values()
			listeners.Remove(eventListener)
		Next
		UnlockMutex(_listenersMutex)
	End Method

	'remove an event listener from a specific trigger
	Method UnregisterListener(eventListener:TEventListenerBase, trigger:TLowerString)
		Local eventKey:TEventKey = GetEventKey(trigger)
		If not eventKey Then Return

		If not TryLockMutex(_listenersMutex)
			TLogger.Log("RegisterListener() (Var2)", "Mutex was still locked, waiting.", LOG_DEBUG)
			LockMutex(_listenersMutex)
		EndIf
		Local listeners:TObjectList = TObjectList(_listeners.ValueForKey( eventKey.id ))
		If listeners Then listeners.Remove(eventListener)
		UnlockMutex(_listenersMutex)
	End Method

	'remove an event listener from a specific trigger
	Method UnregisterListener(eventListener:TEventListenerBase, trigger:String)
		Local eventKey:TEventKey = GetEventKey(trigger)
		If not eventKey Then Return

		If not TryLockMutex(_listenersMutex)
			TLogger.Log("RegisterListener() (Var3)", "Mutex was still locked, waiting.", LOG_DEBUG)
			LockMutex(_listenersMutex)
		EndIf
		Local listeners:TObjectList = TObjectList(_listeners.ValueForKey( eventKey.id ))
		If listeners Then listeners.Remove(eventListener)
		UnlockMutex(_listenersMutex)
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
		If not TryLockMutex(_listenersMutex)
			TLogger.Log("UnregisterListenerByLimit()", "Mutex was still locked, waiting.", LOG_DEBUG)
			LockMutex(_listenersMutex)
		EndIf
		For Local list:TObjectList = EachIn _listeners.Values()
			For Local listener:TEventListenerBase = EachIn list
				'if one of both limits hits, remove that listener
				If FiltersObject(listener._limitToSender, limitSender) Or..
				   FiltersObject(listener._limitToReceiver, limitReceiver)
					list.Remove(listener)
				EndIf
			Next
		Next
		UnlockMutex(_listenersMutex)
	End Method


	'removes all listeners listening to a specific trigger
	Method UnregisterListenersByTrigger(trigger:String, limitReceiver:Object=Null, limitSender:Object=Null)
		Local eventKey:TEventKey = GetEventKey(trigger)
		If not eventKey Then Return

		'remove all of that trigger
		If Not limitReceiver And Not limitSender
			If not TryLockMutex(_listenersMutex)
				TLogger.Log("UnregisterListenersByTrigger()", "Mutex was still locked, waiting.", LOG_DEBUG)
				LockMutex(_listenersMutex)
			EndIf
			_listeners.Remove( eventKey.id )
			UnlockMutex(_listenersMutex)
		'remove all defined by limits
		Else
			Local triggerListeners:TObjectList = TObjectList(_listeners.ValueForKey( eventKey.id ))
			if triggerListeners
				Local toRemove:TEventListenerBase[]
				For Local listener:TEventListenerBase = EachIn triggerListeners
					'if one of both limits hits, remove that listener
					If FiltersObject(listener._limitToSender, limitSender) Or..
					   FiltersObject(listener._limitToReceiver, limitReceiver)
						toRemove :+ [listener]
					EndIf
				Next

				If not TryLockMutex(_listenersMutex)
					TLogger.Log("UnregisterListenersByTrigger()", "Mutex was still locked, waiting.", LOG_DEBUG)
					LockMutex(_listenersMutex)
				EndIf
				For local listener:TEventListenerBase = EachIn toRemove
					triggerListeners.remove(listener)
				Next
				UnlockMutex(_listenersMutex)
			EndIf
		EndIf
	End Method
	
	
	Method GetListeners:TObjectList(eventKeyID:Long)
		Local result:TObjectList = TObjectList( _listeners.ValueForKey(eventKeyID) ) 
		Return result
	End Method
	

	'add a new event to the list
	Method RegisterEvent(event:TEventBase)
		LockMutex(_eventsMutex)
		_events.AddLast(event)
		UnlockMutex(_eventsMutex)
	End Method


'global debugLastListenedEventKey:TEventKey
'global debugLastEventKey:TEventKey
	'runs all listeners NOW ...returns amount of listeners
	Method TriggerEvent:Int(triggeredByEvent:TEventBase)
		If Not triggeredByEvent Then Return 0

		?Threaded
		'if we have systemonly-event we cannot do it in a subthread
		'instead we just add that event to the upcoming events list
		If triggeredByEvent._channel = 1
			If CurrentThread()<>MainThread()
				RegisterEvent(triggeredByEvent)
				Return False
			EndIf
		EndIf
		?

		?debug
		if not triggeredByEvent.GetEventKey() then Throw "triggering event without key"
		?

		Local listeners:TObjectList = GetListeners(triggeredByEvent.GetEventKeyID())
		If listeners
			'If not TryLockMutex(_listenersMutex)
			'	print "TryLockMutex(_listenersMutex) failed"
			'	LockMutex(_listenersMutex)
			'EndIf
			'use a _copy_ of the original listeners to avoid concurrent
			'modification within the loop
			'listeners = listeners.Copy()
			For Local listener:TEventListenerBase = EachIn listeners
				listenersCalled :+ 1

				'limit to only execution at the same time
				'only useful if the "eachin listeners" is not mutexed too
				'If not TryLockMutex(_onEventMutex)
				'	Print "TryLockMutex(_onEventMutex) failed in EachIn listeners loop ... "
				'	if debugLastListenedEventKey then print "debugLastListenedEventKey = " + debugLastListenedEventKey.text.ToString()
				'	if debugLastEventKey then print "debugLastEventKey = " + debugLastEventKey.text.ToString()
				'	LockMutex(_onEventMutex)
				'EndIf
				listener.onEvent(triggeredByEvent)
				'debugLastListenedEventKey = triggeredByEvent._eventKey
				'UnlockMutex(_onEventMutex)
				'stop triggering the event if ONE of them vetos
				If triggeredByEvent.isVeto() Then Exit
			Next
			'UnlockMutex(_onEventMutex)
		EndIf

		'run individual event method
		If Not triggeredByEvent.IsVeto()
			eventsTriggered :+ 1
			'If not TryLockMutex(_onEventMutex)
			'	Print "TryLockMutex(_onEventMutex) failed in triggeredByEvent.onEvent ... "
			'	if debugLastListenedEventKey then print "debugLastListenedEventKey = " + debugLastListenedEventKey.text.ToString()
			'	if debugLastEventKey then print "debugLastEventKey = " + debugLastEventKey.text.ToString()
			'	LockMutex(_onEventMutex)
			'EndIf
			triggeredByEvent.onEvent()
			'debugLastEventKey = triggeredByEvent._eventKey 
			'UnlockMutex(_onEventMutex)
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
			LockMutex(_eventsMutex)
			Local event:TEventBase = TEventBase(_events.First())
			UnlockMutex(_eventsMutex)

			If event <> Null
				If onlyChannel <> Null
					'system
					If event._channel = 1 And event._channel <> onlyChannel
						If CurrentThread() <> MainThread() Then Return
					EndIf
				EndIf

				' is it time for this event?
				If event.getStartTime() <= _ticks
					triggerEvent( event )

					' remove from list
					LockMutex(_eventsMutex)
					_events.RemoveFirst()
					UnlockMutex(_eventsMutex)
					' another event may start on the same tick - check again
					_processEvents()
				EndIf
			EndIf
		EndIf
	End Method


	Method DumpListeners()
		Print "==== EVENT MANAGER DUMP LISTENERS ===="
		LockMutex(_listenersMutex)

		Local listeners:Int
		For Local l:TObjectList = EachIn EventManager._listeners.Values()
			listeners :+ l.Count()
		Next
		
		local methodListenerCount:Int
		local functionListenerCount:Int

		For Local longKey:TLongKey = EachIn EventManager._listeners.Keys()
			local eventKey:TEventKey = GetEventKey(longKey.value)
			if not eventKey then Throw "EventManager._listeners contain obsolete eventKeys for ID="+longKey.value

			'skip GUI for now
			'If eventKey.text.Find("gui") = 0 then continue
			print "- " + eventKey.text.ToString() ' + "    [ID:"+eventKey.id+"]"

			For Local elb:TEventListenerBase = EachIn TObjectList( _listeners.ValueForKey(eventKey.id) )
				Local callName:String
				If TEventListenerRunFunction(elb)
					Local elbF:TEventListenerRunFunction = TEventListenerRunFunction(elb)
					Local callSource:TFunction
					'identify the function and the parent of it
					For local t:TTypeID = EachIn TTypeId.EnumTypes()
						For local f:TFunction = EachIn t.EnumFunctions()
							If f._ref = Byte Ptr (elbf._function)
								If callSource 
									callName :+ "~n" + t.name() + "." + f.name() + "  [Override]"
								Else
									callName :+ t.name() + "." + f.name()
								EndIf

								callSource = f
							endif
						Next
					Next
				ElseIf TEventListenerRunMethod(elb)
					Local elbM:TEventListenerRunMethod = TEventListenerRunMethod(elb)
					if TTypeID.ForObject(elbM._objectInstance)
						callName = TTypeID.ForObject(elbM._objectInstance).name() + "." + elbM._methodName+"()"
					Endif
				EndIf
					
				
				If TEventListenerRunFunction(elb)
					For local s:String = Eachin callName.split("~n")
						Print "    listener function: " + s
					Next
					functionListenerCount :+ 1
				ElseIf TEventListenerRunMethod(elb)
					For local s:String = Eachin callName.split("~n")
						Print "    listener method: " + s
					Next
					methodListenerCount :+ 1
				Else
					Print "    listener " + TTypeId.ForObject(elb).name()
				EndIf
			Next
		Next
		UnlockMutex(_listenersMutex)

		Print "====="
		Print "Events: " + _events.Count()
		Print "Event Listeners: " + listeners + " (" + methodListenerCount + " method listeners, " + functionListenerCount + " function listeners)"

		Print "====="
	End Method


	'check whether a object is filtered by a given filter object
	'1) filter is the same object
	'2) filter is a type and it is the same as the one of the object
	'3) filter is a parent type of the one of the object
	Function FiltersObject:Int(obj:Object, filter:Object, filterObjType:Int = 0, objTypeID:TTypeID = Null)
		'filterObjType: 0 = unchecked
		'               1 = string
		'               2 = ttypeid
		'               3 = object
	
		'one of both is empty
		If Not obj Then Return False
		If Not filter Then Return False
		'same object (also compares strings if they are both strings)
		'(only return if they are the same, differing strings need interpretation)
		If obj = filter Then Return True

		If filterObjType = 0 or filterObjType = 1
			Local filterString:String = String(filter)
			Local objString:String = String(obj)

			'if both strings we just compare and also return if different
			If filterString And objString
				Return objString = filterString
			EndIf
			
			If filterObjType = 1 'string? so no "type name"!
				Return False
			EndIf
		EndIf

		'check if classname / type is the same (type-name/id given as limit )
		Local filterTypeId:TTypeId = TTypeId(filter)
		If filterObjType = 0 or filterObjType = 1
			If Not filterTypeId And String(filter) 
				filterTypeId = TTypeId.ForName(String(filter) )
			EndIf
		EndIf

		'got a valid classname and checked object is same type or does extend from that type
		If filterTypeId
			If Not objTypeId Then objTypeID = TTypeId.ForObject(obj)
			If objTypeId.ExtendsType(filterTypeId) Then Return True
		EndIf

		Return False
	End Function

	
	Function FiltersObjectByTypeID:Int(obj:Object, filter:TTypeID, objTypeID:TTypeID = Null)
		'one of both is empty
		If Not obj Then Return False
		If Not filter Then Return False

		If Not objTypeID Then objTypeID = TTypeId.ForObject(obj)

		'direct comparison to avoid function call (debug speed)
		'albeit ExtendsType() checks "self" too
		If objTypeId = filter Then Return True
		Return objTypeId.ExtendsType(filter)
	End Function	
End Type




'each event key consists of a fast to retrieve numeric ID
'and a textual representation (allowing for "wildcards") 
Type TEventKey
	Field id:Long
	Field text:TLowerString

private
	'avoid outside world being able to create new event keys without Generate()
	Method New()
	End Method
End Type




'simple basic class for an event listener
Type TEventListenerBase
	Field _limitToSender:Object
	Field _limitToSenderObjType:Int = 0 {nosave} '0 = unchecked, 1 = string, 2 = ttypeid, 3 = object 
	Field _limitToSenderTypeID:TTypeID {nosave} 'TTypeIDs will differ between savegames...
	Field _limitToReceiver:Object
	Field _limitToReceiverObjType:Int = 0 {nosave}
	Field _limitToReceiverTypeID:TTypeID {nosave} 'TTypeIDs will differ between savegames...
	Global cacheHit:Int
	Global cacheCalc:Int

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
		If self._limitToSender
			'we want a sender but got none - ignore (albeit objects are NOT equal)
			If Not triggerEvent._sender Then Return True
			
			If _limitToSenderObjType = 0
				IdentifySenderReceiverObjType()
			EndIf

			If self._limitToSenderTypeID
'				cacheHit :+ 1
'				print "cache hit" + cacheHit
				'use pre-cached typeid to speedup lookup
				If Not TEventManager.FiltersObjectByTypeID(triggerEvent._sender, self._limitToSenderTypeID) Then Return True
			Else
				If Not TEventManager.FiltersObject(triggerEvent._sender, self._limitToSender) Then Return True
			EndIf
		EndIf

		'Check limit for "receiver" - but only if receiver is set
		'if the listener wants a special receiver but the event does not have one... ignore
		'old: if self._limitToReceiver and triggerEvent._receiver
		'new
		If self._limitToReceiver
			'we want a receiver but got none - ignore (albeit objects are NOT equal)
			If Not triggerEvent._receiver Then Return True

			If _limitToReceiverObjType = 0
				IdentifySenderReceiverObjType()
			EndIf

			'identify limit type
			If _limitToReceiverObjType = 0
'				cacheCalc :+ 1
'				print "calc cache: " + cacheCalc

				self._limitToReceiverTypeID = TTypeId(self._limitToReceiver)
				If Not self._limitToReceiverTypeID And String(self._limitToReceiver) 
					self._limitToReceiverTypeID = TTypeId.ForName(String(self._limitToReceiver))
				EndIf
				If self._limitToReceiverTypeID
					self._limitToSenderObjType = 2 'typeID
				ElseIf String(_limitToReceiver)
					self._limitToReceiverObjType = 1 'string
				Else
					self._limitToReceiverObjType = 3 'object 
				EndIf
			EndIf

			If self._limitToReceiverTypeID
'				cacheHit :+ 1
'				print "cache hit" + cacheHit
				'use pre-cached typeid to speedup lookup
				If Not TEventManager.FiltersObjectByTypeID(triggerEvent._sender, self._limitToReceiverTypeID) Then Return True
			Else
				If Not TEventManager.FiltersObject(triggerEvent._receiver, self._limitToReceiver, self._limitToReceiverObjType) Then Return True
			EndIf
		EndIf

		Return False
	End Method
	
	
	Method IdentifySenderReceiverObjType()
		'identify limit type
		If self._limitToSender and self._limitToSenderObjType = 0
'				cacheCalc :+ 1
'				print "calc cache: " + cacheCalc
			self._limitToSenderTypeID = TTypeId(self._limitToSender)
			If Not self._limitToSenderTypeID And String(self._limitToSender) 
				self._limitToSenderTypeID = TTypeId.ForName(String(self._limitToSender))
			EndIf
			If self._limitToSenderTypeID
				self._limitToSenderObjType = 2 'typeID
			ElseIf String(_limitToSender)
				self._limitToSenderObjType = 1 'string
			Else
				self._limitToSenderObjType = 3 'object 
			EndIf
		EndIf
		'identify limit type
		If self._limitToReceiver and self._limitToReceiverObjType = 0
'				cacheCalc :+ 1
'				print "calc cache: " + cacheCalc

			self._limitToReceiverTypeID = TTypeId(self._limitToReceiver)
			If Not self._limitToReceiverTypeID And String(self._limitToReceiver) 
				self._limitToReceiverTypeID = TTypeId.ForName(String(self._limitToReceiver))
			EndIf
			If self._limitToReceiverTypeID
				self._limitToSenderObjType = 2 'typeID
			ElseIf String(_limitToReceiver)
				self._limitToReceiverObjType = 1 'string
			Else
				self._limitToReceiverObjType = 3 'object 
			EndIf
		EndIf
	End Method
		
	Function IdentifyLimitType:Object(limitObj:Object, limitType:Int var)
		Local result:Object = TTypeId(limitObj)
		If Not result And String(limitObj) 
			result = TTypeId.ForName(String(limitObj))
		EndIf
		If result
			limitType = 2 'typeID
		ElseIf String(limitObj)
			result = limitObj
			limitType = 1 'string
		Else
			result = limitObj
			limitType = 3 'object 
		EndIf
		Return result
	End Function
End Type




Type TEventListenerRunMethod Extends TEventListenerBase
	Field _methodName:String = ""
	Field _objectInstance:Object
	Field _method:TMethod {nosave}


	Function Create:TEventListenerRunMethod(objectInstance:Object, methodName:String, limitToSender:Object=Null, limitToReceiver:Object=Null )
		Local obj:TEventListenerRunMethod = New TEventListenerRunMethod
		obj._methodName	= methodName
		obj._objectInstance = objectInstance

		'convert limits to TTypeID if corresponding - this saves lookups
		'later on
		If String(limitToSender)
			local t:TTypeID = TTypeID.ForName(String(limitToSender))
			if t Then limitToSender = t
		EndIf
		If String(limitToReceiver)
			local t:TTypeID = TTypeID.ForName(String(limitToReceiver))
			if t Then limitToReceiver = t
		EndIf

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
				'_method.Invoke(_objectInstance ,[triggerEvent])

				If _method._argTypes.length <> 1
					print "_method " + _method.name() + " does not correspond to event-definition: only argument should be ~qtriggerEvent:TEventBase~q" 
					_method.Invoke(_objectInstance ,[triggerEvent])
				Else	
					Local arg:Byte Ptr
					event_bbRefPushObject(varptr arg, triggerEvent)
				
					if _method._typeID._retType = IntTypeID
						Local f:Int(m:Object, data:Byte Ptr) = _method._ref
						f(_objectInstance, arg)
					ElseIf _method._typeID._retType = VoidTypeID
						Local f(m:Object, data:Byte Ptr) = _method._ref
						f(_objectInstance, arg)
					EndIf
				EndIf
				
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
		
		'convert limits to TTypeID if corresponding - this saves lookups
		'later on
		If ObjectIsString(limitToSender)
			local t:TTypeID = TTypeID.ForName(String(limitToSender))
			if t Then limitToSender = t
		EndIf
		If ObjectIsString(limitToReceiver)
			local t:TTypeID = TTypeID.ForName(String(limitToReceiver))
			if t Then limitToReceiver = t
		EndIf
		
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
	Field _startTime:Long
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


	Function Create:TEventBase(eventKeyID:Long, data:Object=Null, sender:Object=Null, receiver:Object=Null, channel:Int=0)
		Local eventKey:TEventKey = EventManager.GetEventKey(eventKeyID)
		if not eventKey Then Throw "No eventKey found for ID="+eventKeyID

		Return Create(eventKey, data, sender, receiver, channel)
	End Function


	Method GetEventKeyID:Long()
		if _eventKey Then Return _eventKey.id
		Return 0
	End Method
	
	
	Method SetEventKey(eventKey:TEventKey)
		_eventKey = eventKey
	End Method


	Method GetEventKey:TEventKey()
		Return _eventKey
	End Method


	Method GetStartTime:Long()
		Return _startTime
	End Method


	Method SetStartTime:TEventBase(newStartTime:Long=0)
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

