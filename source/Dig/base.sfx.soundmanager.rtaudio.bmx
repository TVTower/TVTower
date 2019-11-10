SuperStrict
Import brl.Map
Import brl.WAVLoader
'Import brl.OGGLoader

'the needed module files are located in "external/maxmod2_lite.mod.zip"
Import MaxMod2.ogg
Import MaxMod2.rtaudio
'Import MaxMod2.rtaudionopulse
Import MaxMod2.WAV
'MaxModVerbose True

Import "base.sfx.soundmanager.base.bmx"



Type TSoundManager_RtAudio Extends TSoundManager
	Function Create:TSoundManager_RtAudio()
		Local manager:TSoundManager_RtAudio = New TSoundManager_RtAudio

		'initialize sound system
		If audioEngineEnabled Then manager.InitAudioEngine()

		manager.defaultSfxDynamicSettings = TSfxSettings.Create()

		Return manager
	End Function


	Function GetInstance:TSoundManager_RtAudio()
		If Not TSoundManager_RtAudio(instance) Then instance = TSoundManager_RtAudio.Create()
		Return TSoundManager_RtAudio(instance)
	End Function



	Method FillAudioEngines:Int()
		engineKeys = ["AUTOMATIC", "NONE"]
		engineNames = ["Automatic", "None"]
		engineDriverNames = ["AUTOMATIC", "NONE"]
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
	End Method


	Method InitSpecificAudioEngine:Int(engine:String)
		TMaxModRtAudioDriver.Init(engine)
		'
		If Not SetAudioDriver("MaxMod RtAudio")
			If engine = audioEngine
				TLogger.Log("SoundManager.SetAudioEngine()", "audio engine ~q"+engine+"~q (configured) failed.", LOG_ERROR)
			Else
				TLogger.Log("SoundManager.SetAudioEngine()", "audio engine ~q"+engine+"~q failed.", LOG_ERROR)
			EndIf
			Return False
		Else
			SetAudioStreamDriver("MaxMod RtAudio")
			Return True
		EndIf
	End Method


	Method InitAudioEngine:Int()
		'reenable rtAudio-messages
		TMaxModRtAudioDriver.showWarnings(False)

		Super.InitAudioEngine()

		'reenable rtAudio-messages
		TMaxModRtAudioDriver.showWarnings(True)

		Return True
	End Method


	Method CreateDigAudioStreamOgg:TDigAudioStream(uri:String, loop:Int)
		Return New TDigAudioStream_RtAudio_Ogg.CreateWithFile(uri, loop)
	End Method
End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetSoundManager:TSoundManager()
	Return TSoundManager_RtAudio.GetInstance()
End Function





'type to store music files (ogg) in it
'(no longer) data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TDigAudioStream_RtAudio Extends TDigAudioStream
	'Field bank:TBank
	Field url:String
	Field volume:Float = 1.0
	Field channel:TChannel


	Function Create:TDigAudioStream_RtAudio(url:Object, loop:Int=False)
		Local obj:TDigAudioStream_RtAudio = New TDigAudioStream_RtAudio
		'obj.bank = LoadBank(url)
		obj.loop = loop
		obj.url = "unknown"
		If String(url) Then obj.url=String(url)
		Return obj
	End Function


	'override
	Method Clone:TDigAudioStream_RtAudio(deepClone:Int = False)
		Local c:TDigAudioStream_RtAudio = New TDigAudioStream_RtAudio
		'c.bank = Self.bank
		c.loop = Self.loop
		c.url = Self.url
		Return c
	End Method


	Method isValid:Int()
		If url
			Return FileType(url) <> 1
		Else
			Return False
		EndIf

		'If Not Self.bank Then Return False
		'Return True
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Self.volume = volume
		'just return the channel
'		return GetChannel()

		If Not url Then Throw "no url to play"
		channel = CueMusic(Self.url, loop)
		If Not channel
			Throw "TDigAudioStream.GetChannel() failed to CueMusic"
		EndIf
		lastChannelTime = Time.MillisecsLong()
		SetPlaying(True)

		channel.SetVolume(volume)

		SetLoopedPlaytime( GetChannelLength(channel, MM_MILLISECS) )

		Return channel
	End Method


	Method GetChannel:TChannel()
		If Not url Then Throw "no url to play"
		Local channel:TChannel = CueMusic(Self.url, loop)
		If Not channel
			Throw "TDigAudioStream_RtAudio.GetChannel() failed to CueMusic"
		EndIf
		lastChannelTime = Time.MillisecsLong()
		SetPlaying(True)

		channel.SetVolume(volume)

		Return channel
	End Method


	'returns time left in milliseconds
	Method GetTimeLeft:Float()
		Return GetTimeTotal() - GetTimePlayed()
	End Method


	'returns time of a track in milliseconds
	Method GetTimeTotal:Int()
		If Not channel Then Return 0
		Return GetChannelLength(channel, MM_MILLISECS)
	End Method


	'returns time left in milliseconds
	Method GetTimePlayed:Float()
		If Not channel Then Return 0

		Return maxmod2.maxmod2.GetChannelPosition(channel, MM_MILLISECS)
	End Method
End Type




Type TDigAudioStream_RtAudio_Ogg Extends TDigAudioStream_RtAudio
	Method CreateWithFile:TDigAudioStream_RtAudio_Ogg(url:Object, loop:Int = False, useMemoryStream:Int = False)
		'Self.bank = LoadBank(url)
		Self.loop = loop
		Self.url = "unknown"
		If String(url) Then Self.url=String(url)
		Return Self
	End Method


	Method Clone:TDigAudioStream_RtAudio_Ogg(deepClone:Int = False)
		Local c:TDigAudioStream_RtAudio_Ogg = New TDigAudioStream_RtAudio_Ogg
		'c.bank = Self.bank
		c.loop = Self.loop
		c.url = Self.url
		Return c
	End Method
End Type