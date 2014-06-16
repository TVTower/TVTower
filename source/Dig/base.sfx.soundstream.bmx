REM
	====================================================================
	Audio Stream Classes
	====================================================================

	Contains:

	- a manager "TDigAudioStreamManager" needed for regular updates of
	  audio streams (refill of buffers). If not used, take care to
	  manually call "update()" for each stream on a regular base. 
	- a basic stream class "TDigAudioStream" and its extension
	  "TDigAudioStreamOgg" to enable decoding of ogg files.



	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2014 Ronny Otto, digidea.de

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
Import Pub.OggVorbis
Import Brl.OggLoader
Import Brl.LinkedList
Import Brl.audio
Import Brl.freeaudioaudio
Import Brl.standardio
Import Brl.bank




Type TDigAudioStreamManager
	Field streams:TList = CreateList()


	Method AddStream:int(stream:TDigAudioStream)
		streams.AddLast(stream)
		return True
	End Method


	Method RemoveStream:int(stream:TDigAudioStream)
		streams.Remove(stream)
		return True
	End Method


	Method Update:int()
		For local stream:TDigAudioStream = eachin streams
			stream.Update()
		Next
	End Method
End Type
Global DigAudioStreamManager:TDigAudioStreamManager = new TDigAudioStreamManager



'base class for audio streams
Type TDigAudioStream
	Field buffer:int[]
	Field sound:TSound
	Field currentChannel:TChannel

	Field writePos:int
	Field streaming:int
	'channel position might differ from the really played position
	'so better store a custom position property to avoid discrepancies
	'when pausing a stream
	Field position:int
	'temporary variable to calculate position changes since last update
	Field _lastPosition:int

	'length of the total sound
	Field samplesCount:int = 0

	Field bits:int = 16
	Field freq:int = 44100
	Field channels:int = 2
	Field format:int = 0
	Field loop:int = False
	Field paused:int = False

	'length of each chunk in positions/ints 
	Const chunkLength:int = 1024
	'amount of chunks to block
	Const chunkCount:int = 16


	Method Create:TDigAudioStream(loop:int = False)
		?PPC
		If channels=1 Then format=SF_MONO16BE Else format=SF_STEREO16BE
		?X86
		If channels=1 Then format=SF_MONO16LE Else format=SF_STEREO16LE
		?

		'option A
		'audioSample = CreateAudioSample(GetBufferLength(), freq, format)

		'option B
		self.buffer = new Int[GetBufferLength()]
		local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetBufferLength(), freq, format)


		'driver specific sound creation
		CreateSound(audioSample)
	
		SetLooped(loop)

		return Self
	End Method


	Method Clone:TDigAudioStream(deepClone:int = False)
		local c:TDigAudioStream = new TDigAudioStream.Create(self.loop)
		return c
	End Method


	'=== CONTAINING FREE AUDIO SPECIFIC CODE ===

	Method CreateSound:int(audioSample:TAudioSample)
		'not possible as "Loadsound"-flags are not given to
		'fa_CreateSound, but $80000000 is needed for dynamic sounds
		rem
			$80000000 = "dynamic" -> dynamic sounds stay in app memory
			sound = LoadSound(audioSample, $80000000)
		endrem

		'LOAD FREE AUDIO SOUND
		Local fa_sound:int = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
		sound = TFreeAudioSound.CreateWithSound( fa_sound, audioSample)
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Reset()
		currentChannel = Cue()
		currentChannel.SetVolume(volume)
		Return currentChannel
	End Method


	Method GetChannel:TChannel()
		return currentChannel
	End Method
	

	Method GetChannelPosition:int()
		'to recognize if the buffer needs a new refill, the position of
		'the current playback is needed. TChannel does not provide that
		'functionality, streaming with it is not possible that way.
		if TFreeAudioChannel(currentChannel)
			return TFreeAudioChannel(currentChannel).Position()
		endif
		return 0
	End Method

	'=== / END OF FREE AUDIO SPECIFIC CODE ===


	Method GetBufferSize:int()
		return GetBufferLength() * channels * 2
	End Method


	Method GetBufferLength:int()
		'buffer up to 8 chunks
		return chunkLength * chunkCount
	End Method


	Method GetPosition:int()
		return position
	End Method


	Method GetBufferPosition:int()
		return GetPosition() + GetBufferLength()/2 - writepos	
	End Method


	Method GetTimeLeft:float()
		return (samplesCount - GetPosition()) / float(freq)
	End Method


	Method GetTimePlayed:float()
		return GetPosition() / float(freq)
	End Method
	

	Method GetTimeBuffered:float()
		return (GetPosition() + GetBufferPosition()) / float(freq)
	End Method


	Method GetTimeTotal:int()
		return samplesCount / freq
	End Method


	Method Delete()
		'int arrays get cleaned without our help
		'so only free the buffer if it was MemAlloc'ed 
		'if GetBufferSize() > 0 then MemFree buffer
	End Method


	Method ReadyToPlay:int()
		return Not streaming And writepos >= GetBufferLength()/2
	End Method


	Method FillBuffer:int(offset:int, length:int = -1)
	End Method


	'begin again
	Method Reset:int()
		writePos = 0
		position = 0
		_lastPosition = 0
		streaming = False
	End Method


	Method IsPaused:int()
		'we cannot use "channelStatus & PAUSED" as the channel gets not
		'paused but the stream!
		'16 is the const "PAUSED" in freeAudio
		'return (fa_ChannelStatus(faChannel) & 16)

		return paused
	End Method


	Method PauseStreaming:int(bool:int = True)
		paused = bool
		GetChannel().SetPaused(bool)
	End Method


	Method SetLooped(bool:int = True)
		loop = bool
	End Method


	Method FinishPlaying:int()
		Reset()

		if loop
			Play()
		else
			PauseStreaming()
		endif
	End Method


	Method Play:TChannel(reUseChannel:TChannel = null)
		if not reUseChannel then reUseChannel = currentChannel
		currentChannel = PlaySound(sound, reUseChannel)
		return currentChannel
	End Method


	Method Cue:TChannel(reUseChannel:TChannel = null)
		if not reUseChannel then reUseChannel = currentChannel
		currentChannel = CueSound(sound, reUseChannel)
		return currentChannel
	End Method


	Method Update()
		if isPaused() then return
		if currentChannel and not currentChannel.Playing() then return


		'=== CALCULATE STREAM POSITION ===
		position :+ GetChannelPosition() - _lastPosition
		_lastPosition = position

		'=== FINISH PLAYBACK IF END IS REACHED ===
		'did the playing position reach the last piece of the stream?
		if GetPosition() >= samplesCount then FinishPlaying()


		'=== LOAD NEW CHUNKS / BUFFER DATA ===
		Local chunksToLoad:int = GetBufferPosition() / chunkLength	
		'looping this way (in blocks of 1024) means that no "wrap over"
		'can occour (start at 7168 and add 2048 - which wraps over 8192)

		While chunksToLoad > 0 and writePos < samplesCount
			'buffer offset  =  writepos Mod GetBufferLength()
			FillBuffer(writepos Mod GetBufferLength(), chunkLength)
			writepos :+ chunkLength
			chunksToLoad :- 1
		Wend


		'=== BEGIN PLAYBACK IF BUFFERED ENOUGH ===
		if ReadyToPlay() and not IsPaused()
			if currentChannel then currentChannel.SetPaused(False)
			streaming = True
		endif
	End Method
End Type



'extended audio stream to allow ogg file streaming
Type TDigAudioStreamOgg extends TDigAudioStream
	Field stream:TStream
	Field bank:TBank
	Field uri:object
	Field ogg:Byte Ptr
	

	Method Create:TDigAudioStreamOgg(loop:int = False)
		Super.Create(loop)

		return Self
	End Method


	Method CreateWithFile:TDigAudioStreamOgg(uri:object, loop:int = False, useMemoryStream:int = False)
		self.uri = uri
		'avoid file accesses and load file into a bank
		if useMemoryStream
			SetMemoryStreamMode()
		else
			SetFileStreamMode()
		endif
		
		Reset()
	
		Create(loop)
		return self
	End Method


	Method Clone:TDigAudioStreamOgg(deepClone:int = False)
		local c:TDigAudioStreamOgg = new TDigAudioStreamOgg.Create(self.loop)
		c.uri = self.uri
		if self.bank
			if deepClone
				c.bank = LoadBank(self.bank)
				c.stream = OpenStream(c.bank)
			'save memory and use the same bank
			else
				c.bank = self.bank
				c.stream = OpenStream(c.bank)
			endif
		else
			c.stream = OpenStream(c.uri)
		endif

		c.Reset()
		
		return c
	End Method


	Method SetMemoryStreamMode:int()
		bank = LoadBank(uri)
		stream = OpenStream(bank)
	End Method


	Method SetFileStreamMode:int()
		stream = OpenStream(uri)
	End Method


	'move to start, (re-)generate pointer to decoded ogg stream 
	Method Reset:int()
		if not stream then return False
		Super.Reset()

		'return to begin of raw data stream
		stream.Seek(0)

		'generate pointer object to decoded ogg stream
		ogg = Decode_Ogg(stream, readfunc, seekfunc, closefunc, tellfunc, samplesCount, channels, freq)
		If Not ogg Return False

		Return True
	End Method


	Method FillBuffer:int(offset:int, length:int = -1)
		If Not ogg then Return False

		'=== PROCESS PARAMS === 
		'do not read more than available
		length = Min(length, (samplesCount - writePos))
		if length <= 0 then Return False

		'length is given in "ints", so calculate length in bytes
		local bytes:int = 4 * length
		If bytes > GetBufferSize() then bytes = GetBufferSize()


		'=== FILL IN DATA ===
		local bufAppend:Byte Ptr = Byte Ptr(buffer) + offset*4
		'try to read the oggfile at the current position
		Local err:int = Read_Ogg(ogg, bufAppend, bytes)
		if err then Throw "Error streaming from OGG"

		return True
	End Method


	'adjusted from brl.mod/oggloader.mod/oggloader.bmx
	'they are "private" there... so this is needed to expose them
	Function readfunc:int( buf:Byte Ptr, size:int, nmemb:int, src:Object )
		Return TStream(src).Read(buf, size * nmemb) / size
	End Function


	Function seekfunc:int(src_obj:Object, off0:int, off1:int, whence:int)
		Local src:TStream=TStream(src_obj)
	?X86
		Local off:int = off0
	?PPC
		Local off:int = off1
	?
		Local res:int = -1
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


	Function closefunc(src:Object)
		
	End Function
	

	Function tellfunc:int(src:Object)
		Return TStream(src).Pos()
	End Function
End Type
