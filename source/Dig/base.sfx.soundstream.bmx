Rem
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
Import "base.util.time.bmx"




Type TDigAudioStreamManager
	Field streams:TList = CreateList()


	Method AddStream:Int(stream:TDigAudioStream)
		streams.AddLast(stream)
		Return True
	End Method


	Method RemoveStream:Int(stream:TDigAudioStream)
		streams.Remove(stream)
		Return True
	End Method


	Method Update:Int()
		For Local stream:TDigAudioStream = EachIn streams
			stream.Update()
		Next
	End Method
End Type
Global DigAudioStreamManager:TDigAudioStreamManager = New TDigAudioStreamManager



'base class for audio streams
Type TDigAudioStream
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

	Field playtime:int = 0
	Field playing:int = False
	Field lastChannelTime:Long

	Field bits:Int = 16
	Field freq:Int = 44100
	Field channels:Int = 2
	Field format:Int = 0
	Field loop:Int = False
	Field paused:Int = False

	'length of each chunk in positions/ints
	Const chunkLength:Int = 1024
	'amount of chunks to block
	Const chunkCount:Int = 16


	Method Create:TDigAudioStream(loop:Int = False)
		?PPC
		If channels=1 Then format=SF_MONO16BE Else format=SF_STEREO16BE
		?X86
		If channels=1 Then format=SF_MONO16LE Else format=SF_STEREO16LE
		?

		'option A
		'audioSample = CreateAudioSample(GetBufferLength(), freq, format)

		'option B
		Self.buffer = New Int[GetBufferLength()]
		Local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetBufferLength(), freq, format)


		'driver specific sound creation
		CreateSound(audioSample)

		SetLooped(loop)

		Return Self
	End Method


	Method Clone:TDigAudioStream(deepClone:Int = False)
		Local c:TDigAudioStream = New TDigAudioStream.Create(Self.loop)
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
?bmxng
		Local fa_sound:Byte Ptr = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
?Not bmxng
		Local fa_sound:Int = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
?
		sound = TFreeAudioSound.CreateWithSound( fa_sound, audioSample)
	End Method


	Method IsPlaying:int()
		return playing
	End Method

	Method SetPlaying:int(playing:int)
		self.playing = playing
	End Method


	'for looped sounds...
	Method SetLoopedPlaytime:int(playtime:int)
		self.playtime = playtime
	End Method


	Method GetLoopedPlaytime:int()
		return playtime
	End Method


	Method GetLoopedTimePlayed:int()
		if lastChannelTime = 0 then return 0
		return Time.MillisecsLong() - lastChannelTime
	End Method


	Method GetLoopedPlaytimeLeft:int()
		return GetLoopedPlaytime() - GetLoopedTimePlayed()
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Reset()
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


	Method GetTimeLeft:Float()
		Return (samplesCount - GetPosition()) / Float(freq)
	End Method


	Method GetTimePlayed:Float()
		Return GetPosition() / Float(freq)
	End Method


	Method GetTimeBuffered:Float()
		Return (GetPosition() + GetBufferPosition()) / Float(freq)
	End Method


	Method GetTimeTotal:Int()
		Return samplesCount / freq
	End Method


	Method Delete()
		'int arrays get cleaned without our help
		'so only free the buffer if it was MemAlloc'ed
		'if GetBufferSize() > 0 then MemFree buffer
	End Method


	Method ReadyToPlay:Int()
		Return Not streaming And writepos >= GetBufferLength()/2
	End Method


	Method FillBuffer:Int(offset:Int, length:Int = -1)
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
Type TDigAudioStreamOgg Extends TDigAudioStream
	Field stream:TStream
	Field bank:TBank
	Field uri:Object
	Field ogg:Byte Ptr


	Method Create:TDigAudioStreamOgg(loop:Int = False)
		Super.Create(loop)

		Return Self
	End Method


	Method CreateWithFile:TDigAudioStreamOgg(uri:Object, loop:Int = False, useMemoryStream:Int = False)
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


	Method Clone:TDigAudioStreamOgg(deepClone:Int = False)
		Local c:TDigAudioStreamOgg = New TDigAudioStreamOgg.Create(Self.loop)
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
		Local bufAppend:Byte Ptr = Byte Ptr(buffer) + offset*4
		'try to read the oggfile at the current position
		Local err:Int = Read_Ogg(ogg, bufAppend, bytes)
		If err Then Throw "Error streaming from OGG"

		Return True
	End Method


	'adjusted from brl.mod/oggloader.mod/oggloader.bmx
	'they are "private" there... so this is needed to expose them
	Function readfunc:Int( buf:Byte Ptr, size:Int, nmemb:Int, src:Object )
		Return TStream(src).Read(buf, size * nmemb) / size
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
		Return TStream(src).Pos()
	End Function
End Type
