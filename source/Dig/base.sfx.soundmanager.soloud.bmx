SuperStrict
Import brl.Map
'sdl
'Import audio.AudioSDL
'or miniaudio
Import audio.AudioMiniAudio

Import "base.sfx.soundmanager.base.bmx"



Type TSoundManager_Soloud Extends TSoundManager
	Function Create:TSoundManager_Soloud()
		Local manager:TSoundManager_Soloud = New TSoundManager_Soloud

		SetAudioDriver("Soloud")

		'initialize sound system
		If audioEngineEnabled Then manager.InitAudioEngine()

		manager.defaultSfxDynamicSettings = TSfxSettings.Create()

		Return manager
	End Function


	Function GetInstance:TSoundManager_Soloud()
		If Not TSoundManager_Soloud(instance) Then instance = TSoundManager_Soloud.Create()
		Return TSoundManager_Soloud(instance)
	End Function



	Method FillAudioEngines:Int()
		engineKeys = ["AUTOMATIC", "NONE"]
		engineNames = ["Automatic", "None"]
		engineDriverNames = ["AUTOMATIC", "NONE"]
Rem
		?linux
			engineKeys :+  ["LINUX_ALSA", "LINUX_PULSE", "LINUX_OSS"]
			engineDriverNames :+ ["LINUX_ALSA", "LINUX_PULSE", "LINUX_OSS"]
			engineNames :+ ["ALSA", "PulseAudio", "OSS"]
		?MacOS
			engineKeys :+  ["MACOSX_CORE"]
			engineDriverNames :+ ["MACOSX_CORE"]
			engineNames :+ ["CoreAudio"]
		?Win32
			engineKeys :+  ["WINDOWS_ASIO", "WINDOWS_DS"]
			engineDriverNames :+ ["WINDOWS_ASIO", "WINDOWS_DS"]
			engineNames :+ ["ASIO", "DirectSound"]
		?
endrem
	End Method


	Method InitSpecificAudioEngine:Int(engine:String)
		Return True
	End Method


	Method InitAudioEngine:Int()
		Super.InitAudioEngine()

		Return True
	End Method


	Method CreateDigAudioStreamOgg:TDigAudioStream(uri:String, loop:Int)
		Return New TDigAudioStream_Soloud.Create(uri, loop)
	End Method
End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetSoundManager:TSoundManager()
	Return TSoundManager_Soloud.GetInstance()
End Function





'type to store music files (ogg) in it
Type TDigAudioStream_Soloud Extends TDigAudioStream
	'Field bank:TBank
	Field url:String
	Field volume:Float = 1.0
	Field channel:TChannel
	Field sound:TSound
	'how often to _repeat_! (0 = play once)
	Field loopCount:Int = 0


	Function Create:TDigAudioStream_Soloud(url:Object, loop:Int=False)
		Local obj:TDigAudioStream_Soloud = New TDigAudioStream_Soloud
		'obj.bank = LoadBank(url)
		obj.loop = loop
		If loop
			obj.loopCount = -1
		EndIf
		obj.url = "unknown"

		If Not TStream(url) And String(url) Then obj.url = String(url)

		Return obj
	End Function


	'override
	Method Clone:TDigAudioStream_Soloud(deepClone:Int = False)
		Local c:TDigAudioStream_Soloud = New TDigAudioStream_Soloud
		c.loop = Self.loop
		c.url = Self.url

		Return c
	End Method


	Method isValid:Int()
		If url Then Return FileType(url) <> 1

		Return False
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Self.volume = volume

		If Not url Then Throw "no url to play"

		channel = Cue()
		channel.SetVolume(volume)

		SetPlaying(True)

		Return channel
	End Method


	Method Cue:TChannel(reUseChannel:TChannel = Null)
		If Not reUseChannel Then reUseChannel = channel

		If Not sound
			If loop
				sound = LoadSound(url, SOUND_STREAM | SOUND_LOOP)
			Else
				sound = LoadSound(url, SOUND_STREAM)
			EndIf
		EndIf
		channel = CueSound(sound, reUseChannel)
		channel.SetVolume(0)

		If loopCount > 0 Then SetLoopedPlaytime((loopCount+1) * GetTimeTotal())

'		finishedPlaying = False

		Return channel
	End Method


	Method GetChannel:TChannel()
		If Not url Then Throw "no url to play"
		If Not channel Then channel = Cue()

		SetPlaying(True)
		channel.SetVolume(volume)

		Return channel
	End Method


	Method GetURI:Object()
		Return url
	End Method


	'returns time left in milliseconds
	Method GetTimeLeft:Int()
		Return GetTimeTotal() - GetTimePlayed()
	End Method


	'returns time of a track in milliseconds
	Method GetTimeTotal:Int()
		If Not TSoloudChannel(channel) Then Return 0

		Return Int(TSoloudChannel(channel).Length())
	End Method


	'returns time left in milliseconds
	Method GetTimePlayed:Int()
		If Not TSoloudChannel(channel) Then Return 0

		Return TSoloudChannel(channel).StreamTime()
	End Method


	'returns time left in milliseconds
	Method GetLoopsDoneCount:Int()
		If Not TSoloudChannel(channel) Then Return 0

		Return Float(TSoloudChannel(channel).LoopCount())
	End Method


	Method GetLoopedPlaytime:Int()
		Return loopCount * GetTimeTotal()
	End Method


	Method GetLoopedPlaytimeLeft:Int()
		If loopCount > 0
			'  (loopCount * GetTimeTotal()) - (GetLoopsDoneCount() * GetTimeTotal() + GetTimePlayed())
			'= (loopCount * GetTimeTotal()) - (GetLoopsDoneCount() * GetTimeTotal()) - GetTimePlayed()
			'= GetTimeTotal() * (loopCount - GetLoopsDoneCount()) - GetTimePlayed()
			Return GetTimeTotal() * (loopCount - GetLoopsDoneCount()) - GetTimePlayed()
			'return GetLoopedPlaytime() - GetLoopedTimePlayed()
		Else
			Return GetTimeTotal() - GetTimePlayed()
		EndIf
	End Method


	Method GetLoopedTimePlayed:Int()
		Return GetLoopsDoneCount() * GetTimeTotal() + GetTimePlayed()
	End Method
End Type

