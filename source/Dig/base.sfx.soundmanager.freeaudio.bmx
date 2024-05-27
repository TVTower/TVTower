Rem
	====================================================================
	Audio Stream Classes
	====================================================================

	Contains:
	- soundmanager using brl.Freeaudio
	  Music played in the soundmanager is automatically updated/buffer-
	  filled
	- a manager "TDigAudioStreamManager" needed for regular updates of
	  audio streams (refill of buffers). If not used, take care to
	  manually call "update()" for each stream on a regular base.
	- a basic stream class "TDigAudioStream" and its extension
	  "TDigAudioStreamOgg" to enable decoding of ogg files.



	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2014-now Ronny Otto, digidea.de

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
ENDREM
SuperStrict
Import pub.freeaudio
Import brl.WAVLoader
Import Pub.OggVorbis
Import Brl.OggLoader
Import Brl.freeaudioaudio
Import Brl.bank
Import Brl.blitz
Import "base.sfx.soundmanager.base.bmx"
Import "base.util.time.bmx"


?threaded
Import Brl.Threads

OnEnd( EndStreamThreadHook )
Function EndStreamThreadHook()
	TSoundManager_FreeAudio.updateStreamManagerThreadEnabled = False
End Function


?Not threaded
'externalize the threading to a c file
Import "base.sfx.soundmanager.freeaudio.c"
Extern "C"
'	Function RegisterUpdateStreamManagerCallback:int( cbFunc:int())
	Function RegisterUpdateStreamManagerCallback:Int( cbFunc:Byte Ptr )
	Function StartUpdateStreamManagerThread:Int() = "startThread"
	Function StopUpdateStreamManagerThread:Int() = "stopThread"
End Extern
?


Type TSoundManager_FreeAudio Extends TSoundManager
	?threaded
	Global refillBufferMutex:TMutex = CreateMutex()
	Global updateStreamManagerThread:TThread = New TThread
	Global updateStreamManagerThreadEnabled:Int = True
	?


	Function Create:TSoundManager_FreeAudio()
		Local manager:TSoundManager_FreeAudio = New TSoundManager_FreeAudio

		SetAudioDriver("FreeAudio")

		'initialize sound system
		manager.InitAudioEngine()

		manager.defaultSfxDynamicSettings = TSfxSettings.Create()

		?Not threaded
		'print "using external/c stream update threads"
		RegisterUpdateStreamManagerCallback(UpdateStreamManagerCallback)
		StartUpdateStreamManagerThread()
		?threaded
		'print "using internal stream update threads"
		updateStreamManagerThread = CreateThread( UpdateStreamManagerThreadFunction, Null )
		?

		Return manager
	End Function


	Function GetInstance:TSoundManager_FreeAudio()
		If Not TSoundManager_FreeAudio(instance) Then instance = TSoundManager_FreeAudio.Create()
		Return TSoundManager_FreeAudio(instance)
	End Function


	Method FillAudioEngines:Int()
		engineKeys = ["AUTOMATIC", "NONE"]
		engineNames = ["Automatic", "None"]
		engineDriverNames = ["AUTOMATIC", "NONE"]
		?linux
			engineKeys :+  ["LINUX_ALSA", "LINUX_PULSE", "LINUX_OSS"]
			engineDriverNames :+ ["FreeAudio ALSA System", "FreeAudio PulseAudio System", "FreeAudio OpenSound System"]
			engineNames :+ ["ALSA", "PulseAudio", "OSS"]
		?MacOS
			engineKeys :+  ["MACOSX_CORE"]
			engineDriverNames :+ ["FreeAudio CoreAudio"]
			engineNames :+ ["CoreAudio"]
		?Win32
			engineKeys :+  ["WINDOWS_MM", "WINDOWS_DS"]
			engineDriverNames :+ ["FreeAudio Multimedia", "FreeAudio DirectSound"]
			engineNames :+ ["Multimedia", "DirectSound"]
		?
	End Method


	?threaded
	Function UpdateStreamManagerThreadFunction:Object( data:Object )
		While updateStreamManagerThreadEnabled
			local t:Long = Time.MillisecsLong()
			If instance
'				LockMutex(refillBufferMutex)
				instance.RefillBuffers()
'				UnlockMutex(refillBufferMutex)
			EndIf
			'wait until 1000ms are gone in total
			local d:Int = Max(0, 1000 - (Time.MillisecsLong() - t))
			Delay(d) 'waiting time
		Wend

	End Function
	?Not threaded
	Function UpdateStreamManagerCallback:Int()
		If Not instance Then Return False

		instance.RefillBuffers()

		Return True
	End Function
	?


	Method InitSpecificAudioEngine:Int(engine:String)
		If engine = "AUTOMATIC" Then engine = "FreeAudio"
		Return Super.InitSpecificAudioEngine(engine)
	End Method


	'override for FreeAudio-specific checks
	Method FixChannel:Int(sfxChannel:TSfxChannel)
		'unset invalid channels
		'and try to refresh previous settings
		If TFreeAudioChannel(sfxChannel._channel) And TFreeAudioChannel(sfxChannel._channel).fa_channel = 0
			sfxChannel._channel = Null
			sfxChannel._channel = AllocChannel()
			If sfxChannel.CurrentSettings Then sfxChannel.AdjustSettings(False)
		EndIf
		Return Super.FixChannel(sfxChannel)
	End Method


	Method RefillBuffers:Int()
		'currently executed?
		If isRefillBufferRunning Then Return False
		isRefillBufferRunning = True

		If inactiveMusicStream And inactiveMusicStream.IsPlaying()
			inactiveMusicStream.Update()
		EndIf
		If activeMusicStream And activeMusicStream.IsPlaying()
			'print "activeStream:   buffersize="+ TDigAudioStream_FreeAudio(activeMusicStream).GetBufferSize() + "  bufferlength="+TDigAudioStream_FreeAudio(activeMusicStream).GetBufferLength() + "  bufferposition="+TDigAudioStream_FreeAudio(activeMusicStream).GetBufferPosition() + "  position="+TDigAudioStream_FreeAudio(activeMusicStream).GetPosition() + "  timeleft="+TDigAudioStream_FreeAudio(activeMusicStream).GetTimeLeft() + "  timebuffered="+TDigAudioStream_FreeAudio(activeMusicStream).GetTimeBuffered()
			activeMusicStream.Update()
		EndIf

		isRefillBufferRunning = False
	End Method


	Method CreateDigAudioStreamOgg:TDigAudioStream(uri:String, loop:Int)
		Return New TDigAudioStream_Freeaudio_Ogg.CreateWithFile(uri, loop)
	End Method
End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetSoundManager:TSoundManager_FreeAudio()
	Return TSoundManager_FreeAudio.GetInstance()
End Function






'base class for audio streams
Type TDigAudioStream_FreeAudio Extends TDigAudioStream
	Field buffer:TBank
'	Field buffer:Int[]
	Field sound:TSound
	Field currentChannel:TChannel

	Field writePos:Int
	Field streaming:Int
	'channel position might differ from the really played position
	'so better store a custom position property to avoid discrepancies
	'when pausing a stream
	Field position:Int
	'position when cued/play
	Field channelStartPosition:Int
	'temporary variable to calculate position changes since last update
	Field _lastPosition:Int

	Field finishedPlaying:Int = False

	'length of the total sound
	Field samplesCount:Int = 0
	Field sampleLength:Int = 0

	Field bits:Int = 16
	Field freq:Int = 44100
	Field channels:Int = 2
	Field format:Int = 0
	Field paused:Int = False
	Field volume:Float = 1.0

	'length of each chunk in positions/ints
	Const chunkLength:Int = 1024
	'amount of chunks to load/buffer
	Const chunkCount:Int = 128*2


	Method Create:TDigAudioStream_FreeAudio(loop:Int = False)
		If channels=1 Then format=SF_MONO16LE Else format=SF_STEREO16LE

		'option A
		'audioSample = CreateAudioSample(GetBufferLength(), freq, format)

		'option B
'		Self.buffer = New Int[GetBufferLength()]
		Self.buffer = New TBank
		Self.buffer.Resize( GetBufferLength() * 4 ) 'SizeOf( Int(0) ) )
'		Local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetBufferLength(), freq, format)
		Local audioSample:TAudioSample = CreateStaticAudioSample(buffer.Lock(), GetBufferLength(), freq, format)


		'driver specific sound creation
		CreateSound(audioSample)

		SetLooped(loop)
		SetLoopedPlayTime( GetTimeTotal() )

		'fill initial buffer
		BufferData()

		Return Self
	End Method


	Method CopyAudioFrom:TDigAudioStream_FreeAudio(other:TDigAudioStream_FreeAudio, deepCopy:Int = False)
		Self.writePos = 0
		Self.streaming = other.streaming
		Self._lastPosition = 0
		Self.samplesCount = other.samplesCount
		Self.bits = other.bits
		Self.freq = other.freq
		Self.channels = other.channels
		Self.format = other.format
		Self.paused = False

		Self.playtime = other.playtime
		Self.loop = other.loop


		If deepCopy
'			buffer = other.buffer[ .. ]
			buffer = new TBank
			buffer.Resize(other.buffer.Size())
			CopyBank( other.buffer, 0, buffer, 0, other.buffer.Size() )
		EndIf


		If other.currentChannel
			Self.CreateChannel( other.volume )
		EndIf
		If other.sound
'			Local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetBufferLength(), freq, format)
			Local audioSample:TAudioSample = CreateStaticAudioSample(buffer.Lock(), GetBufferLength(), freq, format)
			'driver specific sound creation
			CreateSound(audioSample)
		EndIf

		Return Self
	End Method


	Method Clone:TDigAudioStream_FreeAudio(deepClone:Int = False)
		Local c:TDigAudioStream_FreeAudio = New TDigAudioStream_FreeAudio.Create(Self.loop)
		c.CopyAudioFrom(Self)
		Return c
	End Method


	'=== CONTAINING FREE AUDIO SPECIFIC CODE ===
?bmxng
	Method CreateSound:Byte Ptr(audioSample:TAudioSample)
?Not bmxng
	Method CreateSound:Int(audioSample:TAudioSample)
?
		'not possible as "Loadsound"-flags are not given to
		'fa_CreateSound, but $80000000 is needed for dynamic sounds
		Rem
			$80000000 = "dynamic" -> dynamic sounds stay in app memory
			sound = LoadSound(audioSample, $80000000)
		endrem

		'LOAD FREE AUDIO SOUND
'?bmxng
		Local fa_sound:Byte Ptr = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
'?Not bmxng
'		Local fa_sound:Int = int(fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 ))
'?
		'"audioSample" is ignored in the module, so could be skipped
		'sound = TFreeAudioSound.CreateWithSound( fa_sound, audioSample)
		sound = TFreeAudioSound.CreateWithSound( fa_sound, Null)
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Reset()
		Self.volume = volume

		currentChannel = Cue()
		currentChannel.SetVolume(volume)

		lastChannelTime = Time.MillisecsLong()
		SetPlaying(True)

		Return currentChannel
	End Method


	Method GetChannel:TChannel()
		Return currentChannel
	End Method


	Method Stop()
		If GetChannel() Then GetChannel().Stop()

		Super.Stop()
	End Method


	Method GetChannelPosition:Int()
		'to recognize if the buffer needs a new refill, the position of
		'the current playback is needed. TChannel does not provide that
		'functionality, streaming with it is not possible that way.
		If TFreeAudioChannel(currentChannel)
			Return TFreeAudioChannel(currentChannel).Position() - channelStartPosition
		EndIf
		Return 0
	End Method

	'=== / END OF FREE AUDIO SPECIFIC CODE ===


	Method GetBufferSize:Int()
		Return GetBufferLength() * channels * 2
	End Method


	Method GetBufferLength:Int()
		'buffer up to "chunkCount" chunks
		Return chunkLength * chunkCount
	End Method


	Method GetPosition:Int()
		Return position
	End Method


	Method GetBufferPosition:Int()
		Return GetPosition() + GetBufferLength()/2 - writepos
	End Method


	'returns time left in milliseconds
	Method GetTimeLeft:Int()
		Return Int(1000 * (samplesCount - GetPosition()) / Float(freq))
	End Method


	'returns milliseconds
	Method GetTimePlayed:Int()
		Return Int(1000 * GetPosition() / Float(freq))
	End Method


	'returns milliseconds
	Method GetTimeBuffered:Int()
		Return Int(1000 * (GetPosition() + GetBufferPosition()) / Float(freq))
	End Method


	'returns milliseconds
	Method GetTimeTotal:Int()
		Return int(1000 * (samplesCount / Float(freq)))
	End Method


	Method Delete()
		'int arrays get cleaned without our help
		'so only free the buffer if it was MemAlloc'ed
		'if GetBufferSize() > 0 then MemFree buffer

		if buffer and buffer._locked then buffer.Unlock()
	End Method


	Method ReadyToPlay:Int()
		Return Not streaming And writepos >= GetBufferLength()/2
	End Method


	'begin again
	Method Reset:Int()
		writePos = 0
		position = 0
		_lastPosition = 0
		streaming = False
		paused = False

		finishedPlaying = True
	End Method


	Method IsPaused:Int()
		'we cannot use "channelStatus & PAUSED" as the channel gets not
		'paused but the stream!
		'16 is the const "PAUSED" in freeAudio
		'return (fa_ChannelStatus(faChannel) & 16)

		Return paused
	End Method


	Method PauseStreaming:Int(bool:Int = True)
		paused = bool

		GetChannel().SetPaused(bool)
	End Method


	Method SetLooped(bool:Int = True)
		loop = bool
	End Method


	Method FinishPlaying:Int()
		Reset()

		finishedPlaying = True

		If loop
			Play()
		Else
			PauseStreaming()
		EndIf
	End Method


	Method Play:TChannel(reUseChannel:TChannel = Null)
		If Not reUseChannel Then reUseChannel = currentChannel
		currentChannel = PlaySound(sound, reUseChannel)

		If TFreeAudioChannel(currentChannel)
			channelStartPosition = TFreeAudioChannel(currentChannel).Position()
		Else
			channelStartPosition = 0
		EndIf

		finishedPlaying = False

		Return currentChannel
	End Method


	Method Cue:TChannel(reUseChannel:TChannel = Null)
		If Not reUseChannel Then reUseChannel = currentChannel
		currentChannel = CueSound(sound, reUseChannel)

		If TFreeAudioChannel(currentChannel)
			channelStartPosition = TFreeAudioChannel(currentChannel).Position()
		Else
			channelStartPosition = 0
		EndIf

		finishedPlaying = False

		Return currentChannel
	End Method


	Method FillBuffer:Int(offset:Int, length:Int = -1)
	End Method


	Method BufferData()
		Local chunksToLoad:Int = GetBufferPosition() / chunkLength
		'looping this way (in blocks of 1024) means that no "wrap over"
		'can occour (start at 7168 and add 2048 - which wraps over 8192)

		While chunksToLoad > 0 And writePos < samplesCount
			'buffer offset  =  writepos Mod GetBufferLength()
			FillBuffer(writepos Mod GetBufferLength(), chunkLength)
			writepos :+ chunkLength
			chunksToLoad :- 1
		Wend
	End Method


	Method Update()
'If currentChannel Then print "  ChannelPos="+GetChannelPosition() + "  GetPos="+GetPosition() + "  playing="+currentChannel.Playing() +"  Time="+GetTimePlayed()+ "/" + GetTimeLeft() + "  ReadyToPlay="+ReadyToPlay() + "  IsPaused="+IsPaused() + "  finishedPlaying="+finishedPlaying
		If Not isPaused()
			'=== CALCULATE STREAM POSITION ===
			position :+ GetChannelPosition() - _lastPosition
			_lastPosition = position


			'=== FINISH PLAYBACK IF END IS REACHED ===
			'did the playing position reach the last piece of the stream?
			If GetPosition() >= samplesCount Then FinishPlaying()
		EndIf

		'=== LOAD NEW CHUNKS / BUFFER DATA ===
		BufferData()


		'=== BEGIN PLAYBACK IF BUFFERED ENOUGH ===
		If ReadyToPlay() And Not IsPaused()
			If currentChannel Then currentChannel.SetPaused(False)
			streaming = True
		EndIf
	End Method
End Type



'extended audio stream to allow ogg file streaming
Type TDigAudioStream_FreeAudio_Ogg Extends TDigAudioStream_FreeAudio
	Field stream:TStream
	Field bank:TBank
	Field uri:Object
	Field ogg:Byte Ptr


	Method Create:TDigAudioStream_FreeAudio_Ogg(loop:Int = False)
		Super.Create(loop)

		Return Self
	End Method


	Method CreateWithFile:TDigAudioStream_FreeAudio_Ogg(uri:Object, loop:Int = False, useMemoryStream:Int = False)
		Self.uri = uri
		'avoid file accesses and load file into a bank
		If useMemoryStream
			SetMemoryStreamMode()
		Else
			SetFileStreamMode()
		EndIf

		Reset()

		Create(loop)
		Return Self
	End Method


	Method Clone:TDigAudioStream_FreeAudio_Ogg(deepClone:Int = False)
		Local c:TDigAudioStream_FreeAudio_Ogg = New TDigAudioStream_FreeAudio_Ogg.Create(Self.loop)
		c.CopyAudioFrom(Self)
		c.uri = Self.uri
		If Self.bank
			If deepClone
				c.bank = LoadBank(Self.bank)
				c.stream = OpenStream(c.bank)
			'save memory and use the same bank
			Else
				c.bank = Self.bank
				c.stream = OpenStream(c.bank)
			EndIf
		Else
			c.stream = OpenStream(c.uri)
		EndIf

		c.Reset()

		Return c
	End Method


	Method GetURI:Object()
		Return uri
	End Method


	Method SetMemoryStreamMode:Int()
		bank = LoadBank(uri)
		stream = OpenStream(bank)
	End Method


	Method SetFileStreamMode:Int()
		stream = OpenStream(uri)
	End Method


	'move to start, (re-)generate pointer to decoded ogg stream
	Method Reset:Int()
		If Not stream Then Return False
		Super.Reset()

		'return to begin of raw data stream
		stream.Seek(0)

		'generate pointer object to decoded ogg stream
		ogg = Decode_Ogg(stream, readfunc, seekfunc, closefunc, tellfunc, samplesCount, channels, freq)
		If Not ogg Return False

		Return True
	End Method


	Method FillBuffer:Int(offset:Int, length:Int = -1)
		If Not ogg Then Return False

		'=== PROCESS PARAMS ===
		'do not read more than available
		length = Min(length, (samplesCount - writePos))
		If length <= 0 Then Return False

		'length is given in "ints", so calculate length in bytes
		Local bytes:Int = 4 * length
		If bytes > GetBufferSize() Then bytes = GetBufferSize()


		'=== FILL IN DATA ===
		Local bufAppend:Byte Ptr = buffer.Lock() + offset*4

		'try to read the oggfile at the current position
		Local bytesRead:Int = Read_Ogg(ogg, bufAppend, bytes)
		If bytesRead = 0 Then Throw "Error streaming from OGG. Null bytes read."

		Return True
	End Method


	'adjusted from brl.mod/oggloader.mod/oggloader.bmx
	'they are "private" there... so this is needed to expose them
	Function readfunc:Int(buf:Byte Ptr, size:Int, nmemb:Int, src:Object )
		If TStream(src) Then Return TStream(src).Read(buf, size * nmemb) / size
		Return 0
	End Function


?bmxng
	Function seekfunc:Int( src_obj:Object, offset:Long, whence:Int )
		Local src:TStream=TStream(src_obj)
		Local off:Int = offset
?Not bmxng
	Function seekfunc:Int(src_obj:Object, off0:Int, off1:Int, whence:Int)
		Local src:TStream=TStream(src_obj)
		Local off:Int = off0
?
		If Not src Then Return -1

	?PPC
		off = off1
	?
		Local res:Int = -1
		Select whence
			Case 0 'SEEK_SET
				res = src.Seek(off)
			Case 1 'SEEK_CUR
				res = src.Seek(src.Pos()+off)
			Case 2 'SEEK_END
				res = src.Seek(src.Size()+off)
		End Select
		If res >= 0 Then Return 0
		Return -1
	End Function


	Function closefunc:Int(src:Object)

	End Function

?bmxng
	Function tellfunc:Long(src:Object)
?Not bmxng
	Function tellfunc:Int(src:Object)
?
		If TStream(src) Then Return TStream(src).Pos()
		Return 0
	End Function
End Type
