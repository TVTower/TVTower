SuperStrict
Import "Dig/base.util.color.bmx"
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
	Field KeepBankruptPlayerFinances:int = True
	Field dateFormat:string = "d.m.y"
	Field devGUID:string
	Field mouseHandlingDisabled:int = False
	'storage for current savegame (if there is one loaded) information
	Field savegame_initialBuildDate:String
	Field savegame_initialVersion:String
	Field savegame_initialSaveGameVersion:String
	Field savegame_saveCount:Int = 0
	Field savegame_lastUsedName:String
	'auto save x hours after last saving - 0=off
	Field autoSaveIntervalHours:Int = 0 {nosave}
	'percentage of the gametime when in a room (default = 100%)
	'use a lower value, to slow down the game then (movement + time)
	Field InRoomTimeSlowDownMod:Float = 1.0 {nosave}
	'store configured value for disableing during fast forward
	Field InRoomTimeSlowDownModBackup:Float {nosave}

	Global clNormal:SColor8 = SColor8.Black
	Global clPositive:SColor8 = new SColor8(90, 110, 90)
	Global clNegative:SColor8 = new SColor8(110, 90, 90)

'	Field _values:TData
	Field _modifiers:TData


	Method Initialize:int()
		_modifiers = null
		observerMode = False
		observedObject = null
		isChristmasTime = False
		KeepBankruptPlayerFinances = True
	End Method


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

rem
	Method GetValues:TData()
		if not _values then _values = new TData
		return _values
	End Method
endrem

	Method GetModifier:Float(key:object, defaultValue:Float=1.0)
		if not _modifiers then return defaultValue
		return _modifiers.GetFloat(key, defaultValue)
	End Method


	Method SetModifier(key:object, value:Float)
		if not _modifiers then _modifiers = new TData
		_modifiers.AddNumber(key, value)
	End Method
End Type

Global GameConfig:TGameConfig = new TGameConfig