SuperStrict
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.rectangle.bmx"

'generic variables shared across the whole game
Type TGameConfig {_exposeToLua}
	'which figure/entity to follow with the camera?
	Field observerMode:int = False
	Field observedObject:object = null
	Field highSpeedObservation:int = False
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

	Global compressSavegames:Int = True
	Global compressedSavegameExtension:String = "zst"
	Global uncompressedSavegameExtension:String = "xml"
	
	Global targetGroupColors:SColor8[]
	
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
	
	
	'set useCompression to 0 to forcefully disable compression
	'set useCompression to 1 to forcefully enable compression
	Function GetSavegameExtension:String(useCompression:Int = -1)
		If useCompression = -1 Then useCompression = TGameConfig.compressSavegames

		If useCompression
			Return compressedSavegameExtension
		Else
			Return uncompressedSavegameExtension
		EndIf
	End Function


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

	Method GetTargetGroupColor:SColor8(targetGroupIndex:Int)
		if targetGroupIndex < 0 or targetGroupIndex > targetGroupColors.length Then Return SColor8.White
		return targetGroupColors[targetGroupIndex]
	End Method


	Method GetModifier:Float(key:TLowerString, defaultValue:Float=1.0)
		if not _modifiers then return defaultValue
		return _modifiers.GetFloat(key, defaultValue)
	End Method


	Method GetModifier:Float(key:String, defaultValue:Float=1.0)
		if not _modifiers then return defaultValue
		return _modifiers.GetFloat(key, defaultValue)
	End Method


	Method SetModifier(key:TLowerString, value:Float)
		if not _modifiers then _modifiers = new TData
		_modifiers.Add(key, value)
	End Method
	

	Method SetModifier(key:String, value:Float)
		if not _modifiers then _modifiers = new TData
		_modifiers.Add(key, value)
	End Method
End Type

Global GameConfig:TGameConfig = new TGameConfig
