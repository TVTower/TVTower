SuperStrict
Import Brl.LinkedList
Import "Dig/base.util.event.bmx"
Import "common.misc.screen.bmx"




Type TScreenHandler
	Method Initialize:int() abstract

	'special events for screens used in rooms - only this event has the room as sender
	'screen.onScreenUpdate/Draw is more general purpose
	'returns the event listener links
	Function _RegisterScreenHandler:TLink[](updateFunc(triggerEvent:TEventBase), drawFunc(triggerEvent:TEventBase), screen:TScreen)
		local links:TLink[]
		if screen
			links :+ [ EventManager.registerListenerFunction( "room.onScreenUpdate", updateFunc, screen ) ]
			links :+ [ EventManager.registerListenerFunction( "room.onScreenDraw", drawFunc, screen ) ]
		endif
		return links
	End Function
End Type