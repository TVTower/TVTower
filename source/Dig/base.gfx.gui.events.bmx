SuperStrict

Import "base.util.event.bmx"
Import "base.gfx.guieventkeys.bmx"



'attention: using specific events REQUIRES knowledge of them, so
'you cannot access properties of them without knowing the type
'(aka importing this file - with all the dependencies)
Type TGUIEvent Extends TEventBase
End Type




Type TGUIMouseEvent Extends TGUIEvent
	Field button:Int
	Field x:Int
	Field y:Int
	
	Method New(button:Int, x:Int, y:Int)
		self.button = button
		self.x = x
		self.y = y
	End Method
End Type
