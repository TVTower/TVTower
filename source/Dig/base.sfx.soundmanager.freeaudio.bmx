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


?threaded
Import Brl.Threads

OnEnd( EndStreamThreadHook )
Function EndStreamThreadHook()
	TSoundManager_FreeAudio.updateStreamManagerThreadEnabled = False
End Function


?not threaded
'externalize the threading to a c file
Import "base.sfx.soundmanager.freeaudio.c"
Extern "C"
'	Function RegisterUpdateStreamManagerCallback:int( cbFunc:int())
	Function RegisterUpdateStreamManagerCallback:int( cbFunc:Byte Ptr )
	Function StartUpdateStreamManagerThread:int() = "startThread"
	Function StopUpdateStreamManagerThread:int() = "stopThread"
End Extern
?


Type TSoundManager_FreeAudio extends TSoundManager
	?threaded
	Global refillBufferMutex:TMutex = CreateMutex()
	Global updateStreamManagerThread:TThread = new TThread
	Global updateStreamManagerThreadEnabled:int = True
	?
	Global isRefillBufferRunning:Int = False


	Function Create:TSoundManager_FreeAudio()
		Local manager:TSoundManager_FreeAudio = New TSoundManager_FreeAudio

		'initialize sound system
		manager.InitAudioEngine()

		manager.defaultSfxDynamicSettings = TSfxSettings.Create()
		
		?not threaded
		'print "using external/c stream update threads"
		RegisterUpdateStreamManagerCallback(UpdateStreamManagerCallback)
		StartUpdateStreamManagerThread()
		?threaded
		'print "using internal stream update threads"
		updateStreamManagerThread = CreateThread( UpdateStreamManagerThreadFunction, null )
		?
			
		Return manager
	End Function


	Function GetInstance:TSoundManager_FreeAudio()
		If Not TSoundManager_FreeAudio(instance) Then instance = TSoundManager_FreeAudio.Create()
		Return TSoundManager_FreeAudio(instance)
	End Function
	
	
	Method FillAudioEngines:int()
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
			if instance 
				LockMutex(refillBufferMutex)
				instance.RefillBuffers()
				UnLockMutex(refillBufferMutex)
			endif
			delay(125) 'waiting time
		Wend
		
	End Function
	?not threaded
	Function UpdateStreamManagerCallback:int()
		if not instance then return False

		instance.RefillBuffers()

		return True
	End Function
	?


	Method InitSpecificAudioEngine:int(engine:string)
		if engine = "AUTOMATIC" then engine = "FreeAudio"
		return Super.InitSpecificAudioEngine(engine)
	End Method


	'override for FreeAudio-specific checks
	Method FixChannel:int(sfxChannel:TSfxChannel)
		'unset invalid channels
		'and try to refresh previous settings
		if TFreeAudioChannel(sfxChannel._channel) and TFreeAudioChannel(sfxChannel._channel).fa_channel = 0
			sfxChannel._channel = null
			sfxChannel._channel = AllocChannel()
			if sfxChannel.CurrentSettings then sfxChannel.AdjustSettings(false)
		endif
		return Super.FixChannel(sfxChannel)
	End Method


	Method RefillBuffers:int()
		'currently executed?
		if isRefillBufferRunning then return False
		isRefillBufferRunning = True	

		If inactiveMusicStream then inactiveMusicStream.Update()
		If activeMusicStream then activeMusicStream.Update()

		isRefillBufferRunning = False
	End Method
	

	Method CreateDigAudioStreamOgg:TDigAudioStream(uri:string, loop:int)
		return new TDigAudioStream_Freeaudio_Ogg.CreateWithFile(uri, loop)
	End Method
End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetSoundManager:TSoundManager_FreeAudio()
	return TSoundManager_FreeAudio.GetInstance()
End Function






'base class for audio streams
Type TDigAudioStream_FreeAudio extends TDigAudioStream
	Field buffer:Int[]
	Field sound:TSound
	Field currentChannel:TChannel

	Field writePos:Int
	Field streaming:Int
	'channel position might differ from the really played position
	'so better store a custom position property to avoid discrepancies
	'when pausing a stream
	Field position:Int
	'temporary variable to calculate position changes since last update
	Field _lastPosition:Int

	'length of the total sound
	Field samplesCount:Int = 0
	Field sampleLength:Int = 0

	Field bits:Int = 16
	Field freq:Int = 44100
	Field channels:Int = 2
	Field format:Int = 0
	Field paused:Int = False
	Field volume:float = 1.0

	'length of each chunk in positions/ints
	Const chunkLength:Int = 1024
	'amount of chunks to block
	Const chunkCount:Int = 32


	Method Create:TDigAudioStream_FreeAudio(loop:Int = False)
		If channels=1 Then format=SF_MONO16LE Else format=SF_STEREO16LE

		'option A
		'audioSample = CreateAudioSample(GetBufferLength(), freq, format)

		'option B
		Self.buffer = New Int[GetBufferLength()]
		Local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetBufferLength(), freq, format)


		'driver specific sound creation
		CreateSound(audioSample)

		SetLooped(loop)
		SetLoopedPlayTime( GetTimeTotal() )

		Return Self
	End Method
	
	
	Method CopyAudioFrom:TDigAudioStream_FreeAudio(other:TDigAudioStream_FreeAudio, deepCopy:int = False)
		self.writePos = 0
		self.streaming = other.streaming
		self._lastPosition = 0
		self.samplesCount = other.samplesCount
		self.bits = other.bits
		self.freq = other.freq
		self.channels = other.channels
		self.format = other.format
		self.paused = False

		'self.playing = other.playing
		self.playtime = other.playtime
		self.loop = other.loop
		'self.lastChannelTime = other.lastChannelTime


		if deepCopy
			buffer = other.buffer[ .. ]
		endif

	
		if other.currentChannel
			self.CreateChannel( other.volume )
		endif
		if other.sound
print "create new sound"
			Local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetBufferLength(), freq, format)
			'driver specific sound creation
			CreateSound(audioSample)
		endif
	
		Return self
	End Method


	Method Clone:TDigAudioStream_FreeAudio(deepClone:Int = False)
		Local c:TDigAudioStream_FreeAudio = New TDigAudioStream_FreeAudio.Create(Self.loop)
		c.CopyAudioFrom(self)
		return c
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
?bmxng
		Local fa_sound:Byte Ptr = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
?Not bmxng
		Local fa_sound:Int = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
?
		'"audioSample" is ignored in the module, so could be skipped
		'sound = TFreeAudioSound.CreateWithSound( fa_sound, audioSample)
		sound = TFreeAudioSound.CreateWithSound( fa_sound, null)
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Reset()
		self.volume = volume
		
		currentChannel = Cue()
		currentChannel.SetVolume(volume)

		lastChannelTime = Time.MillisecsLong()
		SetPlaying(true)

		Return currentChannel
	End Method


	Method GetChannel:TChannel()
		Return currentChannel
	End Method


	Method GetChannelPosition:Int()
		'to recognize if the buffer needs a new refill, the position of
		'the current playback is needed. TChannel does not provide that
		'functionality, streaming with it is not possible that way.
		If TFreeAudioChannel(currentChannel)
			Return TFreeAudioChannel(currentChannel).Position()
		EndIf
		Return 0
	End Method

	'=== / END OF FREE AUDIO SPECIFIC CODE ===


	Method GetBufferSize:Int()
		Return GetBufferLength() * channels * 2
	End Method


	Method GetBufferLength:Int()
		'buffer up to 8 chunks
		Return chunkLength * chunkCount
	End Method


	Method GetPosition:Int()
		Return position
	End Method


	Method GetBufferPosition:Int()
		Return GetPosition() + GetBufferLength()/2 - writepos
	End Method


	'returns time left in milliseconds
	Method GetTimeLeft:Float()
		Return 1000.0 * (samplesCount - GetPosition()) / Float(freq)
	End Method


	'returns milliseconds
	Method GetTimePlayed:Float()
		Return 1000.0 * GetPosition() / Float(freq)
	End Method


	'returns milliseconds
	Method GetTimeBuffered:Float()
		Return 1000.0 * (GetPosition() + GetBufferPosition()) / Float(freq)
	End Method


	'returns milliseconds
	Method GetTimeTotal:Int()	
		Return 1000 * (samplesCount / float(freq))
	End Method


	Method Delete()
		'int arrays get cleaned without our help
		'so only free the buffer if it was MemAlloc'ed
		'if GetBufferSize() > 0 then MemFree buffer
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

		If loop
			Play()
		Else
			PauseStreaming()
		EndIf
	End Method


	Method Play:TChannel(reUseChannel:TChannel = Null)
		If Not reUseChannel Then reUseChannel = currentChannel
		currentChannel = PlaySound(sound, reUseChannel)
		Return currentChannel
	End Method


	Method Cue:TChannel(reUseChannel:TChannel = Null)
		If Not reUseChannel Then reUseChannel = currentChannel
		currentChannel = CueSound(sound, reUseChannel)
		Return currentChannel
	End Method


	Method FillBuffer:Int(offset:Int, length:Int = -1)
	End Method


	Method Update()
		If isPaused() Then Return
		If currentChannel And Not currentChannel.Playing() Then Return


		'=== CALCULATE STREAM POSITION ===
		position :+ GetChannelPosition() - _lastPosition
		_lastPosition = position

		'=== FINISH PLAYBACK IF END IS REACHED ===
		'did the playing position reach the last piece of the stream?
		If GetPosition() >= samplesCount Then FinishPlaying()


		'=== LOAD NEW CHUNKS / BUFFER DATA ===
		Local chunksToLoad:Int = GetBufferPosition() / chunkLength
		'looping this way (in blocks of 1024) means that no "wrap over"
		'can occour (start at 7168 and add 2048 - which wraps over 8192)

		While chunksToLoad > 0 And writePos < samplesCount
			'buffer offset  =  writepos Mod GetBufferLength()
			FillBuffer(writepos Mod GetBufferLength(), chunkLength)
			writepos :+ chunkLength
			chunksToLoad :- 1
		Wend


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
		c.CopyAudioFrom(self)
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


	Method GetURI:object()
		return uri
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
		?bmxng
		Local bufAppend:Byte Ptr = Byte Ptr(buffer) + offset
		?not bmxng
		Local bufAppend:Byte Ptr = Byte Ptr(buffer) + offset*4
		?
		'try to read the oggfile at the current position
		Local bytesRead:Int = Read_Ogg(ogg, bufAppend, bytes)
		If bytesRead = 0 Then Throw "Error streaming from OGG. Null bytes read."

		Return True
	End Method


	'adjusted from brl.mod/oggloader.mod/oggloader.bmx
	'they are "private" there... so this is needed to expose them
	Function readfunc:Int(buf:Byte Ptr, size:Int, nmemb:Int, src:Object )
		if TStream(src) then Return TStream(src).Read(buf, size * nmemb) / size
		return 0
	End Function


?bmxng
	Function seekfunc:Int( src_obj:Object, offset:Long, whence:int )
		Local src:TStream=TStream(src_obj)
		Local off:Int = offset
?not bmxng
	Function seekfunc:Int(src_obj:Object, off0:Int, off1:Int, whence:Int)
		Local src:TStream=TStream(src_obj)
		Local off:Int = off0
?
		if not src then return -1

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
?not bmxng
	Function tellfunc:Int(src:Object)
?
		If TStream(src) then Return TStream(src).Pos()
		Return 0
	End Function
End Type
