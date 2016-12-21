SuperStrict
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.rectangle.bmx"

'generic variables shared across the whole game
Type TGameConfig {_exposeToLua}
	'which figure/entity to follow with the camera?
	Field observerMode:int = False
	Field observedObject:object = null
	Field interfaceRect:TRectangle = new TRectangle.Init(0,385, 800,215)
	Field nonInterfaceRect:TRectangle = new TRectangle.Init(0,0, 800,385)
	Field isChristmasTime:int = False

	Method IsObserved:int(obj:object)
		if not observerMode then return False
		return observedObject = obj
	End Method


	Method GetObservedObject:object()
		if not observerMode then return Null

		return observedObject
	End Method


	Method SetObservedObject:int(obj:object)
		observedObject = obj

		return True
	End Method
End Type

Global GameConfig:TGameConfig = new TGameConfig