import brl.blitz
import brl.map
import brl.retro
import brl.glmax2d
TEventManager^brl.blitz.Object{
._events:brl.linkedlist.TList&
._ticks%&
._listeners:brl.map.TMap&
-New%()="_bb_TEventManager_New"
-getTicks%()="_bb_TEventManager_getTicks"
-isStarted%()="_bb_TEventManager_isStarted"
-isFinished%()="_bb_TEventManager_isFinished"
-registerListener%(trigger$,eventListener:TEventListenerBase)="_bb_TEventManager_registerListener"
-unregisterListener%(trigger$,eventListener:TEventListenerBase)="_bb_TEventManager_unregisterListener"
-registerEvent%(event:TEventBase)="_bb_TEventManager_registerEvent"
-triggerEvent%(trigger$,triggeredByEvent:TEventBase)="_bb_TEventManager_triggerEvent"
-update%()="_bb_TEventManager_update"
-_processEvents%()="_bb_TEventManager__processEvents"
}="bb_TEventManager"
TEventListenerBase^brl.blitz.Object{
-New%()="_bb_TEventListenerBase_New"
-onEvent%(triggeredByEvent:TEventBase)A="brl_blitz_NullMethodError"
}A="bb_TEventListenerBase"
TEventListenerRunFunction^TEventListenerBase{
._function%(triggeredByEvent:TEventBase)&
-New%()="_bb_TEventListenerRunFunction_New"
+Create:TEventListenerRunFunction(_function%(triggeredByEvent:TEventBase))="_bb_TEventListenerRunFunction_Create"
-OnEvent%(triggerEvent:TEventBase)="_bb_TEventListenerRunFunction_OnEvent"
}="bb_TEventListenerRunFunction"
TEventBase^brl.blitz.Object{
._startTime%&
._trigger$&
._data:Object&
-New%()="_bb_TEventBase_New"
-getStartTime%()="_bb_TEventBase_getStartTime"
-onEvent%()="_bb_TEventBase_onEvent"
-Compare%(other:Object)="_bb_TEventBase_Compare"
}="bb_TEventBase"
TEventSimple^TEventBase{
-New%()="_bb_TEventSimple_New"
+Create:TEventSimple(trigger$,data:Object)="_bb_TEventSimple_Create"
}="bb_TEventSimple"
EventManager:TEventManager&=mem:p("bb_EventManager")
