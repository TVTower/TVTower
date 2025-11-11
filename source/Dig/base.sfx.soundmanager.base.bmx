SuperStrict
Import Brl.Map
Import Brl.Audio 'for TChannel
Import Brl.LinkedList
Import brl.IntMap
Import brl.Map
Import Brl.Reflection
Import "base.util.logger.bmx"
Import "base.util.vector.bmx"
Import "base.util.time.bmx"

Type TSoundManager
	Field soundFiles:TMap = CreateMap()
	Field activeMusicChannel:TChannel = Null
	Field inactiveMusicChannel:TChannel = Null

	Field sfxVolume:Float = 1
	Field defaulTSfxDynamicSettings:TSfxSettings = Null

	Field sfxOn:Int = 1
	Field musicOn:Int = 1
	Field musicVolume:Float = 1
	Field nextMusicVolume:Float = 1
	Field lastTitleNumber:Int = 0
	Field inactiveMusicStream:TDigAudioStream = Null
	Field activeMusicStream:TDigAudioStream = Null
	Field nextMusicStream:TDigAudioStream = Null

	'do auto crossfade X milliseconds before song end, 0 disables
	Field autoCrossFadeTime:Int = 1500
	'disable to skip fading on next song switch
	Field autoCrossFadeNextSong:Int = True
	'crossfade time for the current crossfade
	field crossFadeTime:int = 1500

	Field defaultMusicVolume:Float = 1.0


	Field forceNextMusic:Int = 0
	Field fadeProcess:Int = 0 '0 = nicht aktiv  1 = aktiv
	'time when fading started
	Field fadeProcessTime:Long = 0

	Field soundSources:TIntMap = new TIntMap
	Field receiver:TSoundSourcePosition

	Field _currentPlaylistName:String = "default"
	'a named array of playlists, playlists contain available musicStreams
	Field playlists:TMap = CreateMap()

	'contains keys (IDs) and names (string representations and driver names)
	'of supported audio engines
	Field engineKeys:string[]
	Field engineDriverNames:string[]
	Field engineNames:string[]

	Global instance:TSoundManager

	Global PREFIX_MUSIC:String = "MUSIC_"
	Global PREFIX_SFX:String = "SFX_"

	Global audioEngineEnabled:int = True
	Global audioEngine:String = "AUTOMATIC"

	Global isRefillBufferRunning:Int = False


	Function Create:TSoundManager()
		Local manager:TSoundManager = New TSoundManager
		'initialize sound system
		manager.InitAudioEngine()

		manager.defaulTSfxDynamicSettings = TSfxSettings.Create()


		Return manager
	End Function


	Method GetAudioEngineDriverName:string(engineKey:string)
		if not engineKeys or engineKeys.length = 0 then FillAudioEngines()
		for local i:int = 0 until engineKeys.length
			if engineKeys[i] = engineKey then return engineDriverNames[i]
		Next
		return "default"
	End Method


	Method GetAudioEngineKeys:String[]()
		if not engineKeys or engineKeys.length = 0 then FillAudioEngines()
		return engineKeys
	End Method


	Method GetAudioEngineDriverNames:String[]()
		if not engineDriverNames or engineDriverNames.length = 0 then FillAudioEngines()
		return engineDriverNames
	End Method


	Method GetAudioEngineNames:String[]()
		if not engineNames or engineNames.length = 0 then FillAudioEngines()
		return engineNames
	End Method


	Method FillAudioEngines:int()
	End Method


	Method SetAudioEngine:int(engine:String)
		engine = engine.ToUpper()
		if engine = audioEngine then return False

		audioEngine = "AUTOMATIC"
		local keys:string[] = GetAudioEngineKeys()
		'local driverNames:string[] = GetAudioEngineDriverNames()

		for local i:int = 0 until keys.length
			if engine = keys[i]
				audioEngine = keys[i]
				exit
			endif
		Next

		return True
	End Method


	Method InitSpecificAudioEngine:int(engineKey:string)
		local engineDriver:string = GetAudioEngineDriverName(engineKey)
		If Not SetAudioDriver(engineKey)
			if engineKey = audioEngine
				TLogger.Log("SoundManager.SetAudioEngine()", "audio engine ~q"+engineDriver+" [" + engineKey+"]~q (configured) failed.", LOG_ERROR)
			else
				TLogger.Log("SoundManager.SetAudioEngine()", "audio engine ~q"+engineDriver+" [" + engineKey+"]~q failed.", LOG_ERROR)
			endif
			Return False
		Else
			Return True
		endif
	End Method


	Method InitAudioEngine:int()
		local engines:String[] = [audioEngine]
		local otherEngineKeys:String[] = GetAudioEngineKeys()

		for local i:int = 0 until otherEngineKeys.length
			if otherEngineKeys[i].ToLower() <> audioEngine.toLower()
				engines :+ [otherEngineKeys[i]]
			endif
		Next

		'try to init one of the engines, starting with the manually set
		'audioEngine
		local foundWorkingEngine:string = ""
		if audioEngine <> "NONE"
			For local engineKey:string = eachin engines
				if InitSpecificAudioEngine(engineKey)
					foundWorkingEngine = engineKey
					exit
				endif
			Next
		endif

		'if no sound engine initialized successfully, use the dummy
		'output (no sound)
		if foundWorkingEngine = ""
			TLogger.Log("SoundManager.SetAudioEngine()", "No working audio engine found. Disabling sound.", LOG_ERROR)
			DisableAudioEngine()
			Return False
		endif

		local workingDriver:string = GetAudioEngineDriverName(foundWorkingEngine)
		TLogger.Log("SoundManager.SetAudioEngine()", "initialized with engine ~q"+workingDriver +" ["+foundWorkingEngine+"]~q.", LOG_DEBUG)
		Return True
	End Method


	Function GetInstance:TSoundManager()
		If Not instance Then instance = TSoundManager.Create()
		Return instance
	End Function


	Method ApplyConfig(soundEngine:String="", musicVolume:Float=1.0, sfxVolume:Float=1.0, playlist:String="")
		if soundEngine.ToLower() = "none"
			MuteMusic(true)
			MuteSfx(true)
			audioEngineEnabled = False
		elseif soundEngine <> ""
			audioEngineEnabled = true
			if SetAudioEngine(soundEngine.ToUpper())
				'new and old engine differed, so initialize the engine
				InitAudioEngine()
			endif
		endif

		self.sfxVolume = sfxVolume
		SetMusicvolume(musicVolume)

		if audioEngineEnabled
			MuteSfx(sfxVolume = 0.0)
			MuteMusic(musicVolume = 0)

			if not HasMutedMusic()
				'if no music is played yet, try to get one from the "menu"-playlist
				If Not isPlaying() and playlist
					PlayMusicPlaylist(playlist)
				endif
			endif
		endif
	End Method

	Function DisableAudioEngine:int()
		audioEngineEnabled = False
	End Function


	'override for FreeAudio-specific checks
	Method FixChannel:int(sfxChannel:TSfxChannel)
		return False
	End Method


	'use 0 to disable feature
	Method SetAutoCrossfadeTime:int(milliseconds:int = 0)
		autoCrossFadeTime = milliseconds
	End Method


	Method GetDefaultReceiver:TSoundSourcePosition()
		Return receiver
	End Method


	Method SetDefaultReceiver(_receiver:TSoundSourcePosition)
		receiver = _receiver
	End Method


	'playlists is a comma separated string of playlists this music wants to
	'be stored in
	Method AddSound:Int(name:String, sound:Object, playlists:String="default")
		Self.soundFiles.insert(Lower(name), sound)

		Local playlistsArray:String[] = playlists.split(",")
		For Local playlist:String = EachIn playlistsArray
			playlist = playlist.Trim() 'remove whitespace
			AddSoundToPlaylist(playlist, name, sound)
		Next
	End Method


	Method AddSoundToPlaylist(playlist:String="default", name:String, sound:Object)
		If TSound(sound)
			playlist = PREFIX_SFX + Lower(playlist)
		ElseIf TDigAudioStream(sound)
			playlist = PREFIX_MUSIC + Lower(playlist)
		EndIf
		name = Lower(name)

		'if not done yet - create a new playlist entry
		'fetch the playlist
		Local playlistContainer:TList
		If Not playlists.contains(playlist)
			playlistContainer = CreateList()
			playlists.insert(playlist, playlistContainer)
		Else
			playlistContainer = TList(playlists.ValueForKey(playlist))
		EndIf
		playlistContainer.AddLast(sound)
	End Method


	Method GetCurrentPlaylist:String()
		Return _currentPlaylistName
	End Method


	Method SetCurrentPlaylist(name:String="default")
		_currentPlaylistName = name
	End Method
	
	
	Method GetMusicPlaylist:TList(name:String)
		Return TList(playlists.ValueForKey(PREFIX_MUSIC + name.ToLower()))
	End Method

	Method GetSFXPlaylist:TList(name:String)
		Return TList(playlists.ValueForKey(PREFIX_SFX + name.ToLower()))
	End Method
	

	'use this method if multiple sfx for a certain event are possible
	'(so eg. multiple "door open/close"-sounds to make variations
	Method GetRandomSfxFromPlaylist:TSound(playlist:String)
		Local playlistContainer:TList = GetSFXPlaylist(playlist)
	
		If Not playlistContainer
			TLogger.Log("SoundManager.GetRandomSfxFromPlaylist()", "Playlist ~q"+playlist+"~q not found.", LOG_WARNING)
			Return Null
		EndIf
		If playlistContainer.count() = 0
			TLogger.Log("SoundManager.GetRandomSfxFromPlaylist()", "Playlist ~q"+playlist+"~q is empty.", LOG_WARNING)
			Return Null
		EndIf

		Return TSound(playlistContainer.ValueAtIndex(Rand(0, playlistContainer.count()-1)))
	End Method


	'if avoidMusic is set, the function tries to return another music (if possible)
	Method GetRandomMusicFromPlaylist:TDigAudioStream(playlist:String, avoidMusic:TDigAudioStream = Null)
		Local playlistContainer:TList = GetMusicPlaylist(playlist)
		If Not playlistContainer
			'TLogger.Log("SoundManager.GetRandomMusicFromPlaylist()", "Playlist ~q"+playlist+"~q not found.", LOG_WARNING)
			Return Null
		EndIf
		If playlistContainer.count() = 0
			'TLogger.Log("SoundManager.GetRandomMusicFromPlaylist()", "Playlist ~q"+playlist+"~q is empty.", LOG_WARNING)
			Return Null
		EndIf

		Local result:TDigAudioStream
		'try to find another music file
		If avoidMusic And playlistContainer.count()>1
			Repeat
				result = TDigAudioStream(playlistContainer.ValueAtIndex(Rand(0, playlistContainer .count()-1)))
			Until result <> avoidMusic
		Else
			result = TDigAudioStream(playlistContainer.ValueAtIndex(Rand(0, playlistContainer .count()-1)))
		EndIf
		Return result
	End Method


	Method RemoveSoundSource:int(soundSource:TSoundSourceElement)
		If Not soundSource then Return False
		If Not soundSources.ValueForKey(soundSource.GetID()) then Return False
		
		'stop playing all sfx - else "looped" continue playing
		soundSource.StopAll()

		soundSources.Remove(soundSource.GetID())
		Return True
	End Method


	Method RegisterSoundSource:int(soundSource:TSoundSourceElement)
		if not soundSource then return False
		If Not soundSources.ValueForKey(soundSource.GetID())
			soundSources.Insert(soundSource.GetID(), soundSource)
		endif
	End Method


	Method GetSoundSource:TSoundSourceElement(ID:Int)
		return TSoundSourceElement(soundSources.ValueForKey(ID))
	End Method


	Method IsPlaying:Int()
		If Not activeMusicChannel Then Return False
		Return activeMusicChannel.Playing()
	End Method


	Method StopSFX:Int()
		'stop playing all sfx - else "looped" continue playing
		For local soundSource:TSoundSourceElement = EachIn soundSources.Values()
			soundSource.StopAll()
		Next
		soundSources.Clear()
	End Method
	

	Method Mute:Int(bool:Int=True)
		If bool
			TLogger.Log("TSoundManager.Mute()", "Muting all sounds", LOG_DEBUG)
		Else
			TLogger.Log("TSoundManager.Mute()", "Unmuting all sounds", LOG_DEBUG)
		EndIf
		MuteSfx(bool)
		MuteMusic(bool)
	End Method


	Method MuteSfx:Int(bool:Int=True)
		'already muted
		if sfxOn = Not bool then return False

		If bool
			TLogger.Log("TSoundManager.MuteSfx()", "Muting all sound effects", LOG_DEBUG)
		Else
			TLogger.Log("TSoundManager.MuteSfx()", "Unmuting all sound effects", LOG_DEBUG)
		EndIf
		For Local element:TSoundSourceElement = EachIn soundSources.Values()
			element.mute(bool)
		Next

		sfxOn = Not bool

		return True
	End Method


	Method MuteMusic:Int(bool:Int=True)
		'already muted
		if musicOn = Not bool then return False

		if not audioEngineEnabled then return False

		If bool
			TLogger.Log("TSoundManager.MuteMusic()", "Muting music", LOG_DEBUG)
		Else
			TLogger.Log("TSoundManager.MuteMusic()", "Unmuting music", LOG_DEBUG)
		EndIf

		If bool
			If activeMusicChannel Then PauseChannel(activeMusicChannel)
			If inactiveMusicChannel Then inactiveMusicChannel.Stop()
		Else
			If activeMusicChannel Then ResumeChannel(activeMusicChannel)
		EndIf
		musicOn = Not bool

		return True
	End Method


	Method IsMuted:Int()
		If sfxOn Or musicOn Then Return False
		Return True
	End Method


	Method HasMutedMusic:Int()
		Return Not musicOn
	End Method


	Method HasMutedSfx:Int()
		Return Not sfxOn
	End Method


	Method RefillBuffers:int()
		'currently executed?
		if isRefillBufferRunning then return False
		isRefillBufferRunning = True

		If inactiveMusicStream then inactiveMusicStream.Update()
		If activeMusicStream then activeMusicStream.Update()

		isRefillBufferRunning = False
	End Method


	Method UpdateSFX()
		If not sfxOn Then Return

		For Local element:TSoundSourceElement = EachIn soundSources.Values()
			element.Update()
		Next
	End Method


	Method UpdateMusic:Int()
		'nothing to do if no activated channel exists
		If Not activeMusicChannel Then Return False
		'also skip actions with muted music
		If HasMutedMusic() then return False


		'=== START PLAYING ===
		'if nothing was playing yet, just start except we are playing already
		If not activeMusicChannel.Playing() 'and not activeMusicStream ' and fadeProcess = 0
			TLogger.Log("TSoundManager.Update()", "No active music channel playing, start new from current playlist", LOG_DEBUG)
			PlayMusicPlaylist(GetCurrentPlaylist())

			'enable autocrossfading for next song if disabled in the
			'past (eg through playing the same song twice)
			if autoCrossFadeTime > 0 then autoCrossFadeNextSong = True
		EndIf



		'=== AUTO CROSS FADE ===
		'autocrossfade to the next song ?
		'only start a new fade if not already fading
		if autoCrossFadeNextSong and autoCrossFadeTime > 0 and activeMusicStream and fadeProcess = 0
			local timeLeft:int = activeMusicStream.GetTimeLeft()

			'if it is looped do not use the normal stream/track time but
			'something taking loop amount into account
			if activeMusicStream.loop then timeLeft = activeMusicStream.GetLoopedPlaytimeLeft()
			if timeLeft < autoCrossFadeTime
				PlayMusicPlaylist(GetCurrentPlaylist())
				StartFadeOverToNextTitle(autoCrossFadeTime)
			endif
		endif


		'=== FORCE NEXT MUSIC ===
		'if something enforced next music, cross fade to it
		If forceNextMusic And nextMusicStream
			'TLogger.log("TSoundManager.Update()", "FadeOverToNextTitle. fadeProcess=" + fadeProcess, LOG_DEBUG)
			StartFadeOverToNextTitle(autoCrossFadeTime)
		EndIf



		'=== UPDATE CROSS FADE ===
		UpdateFadeOverToNextTitle()


		return True
	End Method


	Method Update:Int()
		'skip updates if muted
		If isMuted() Then Return False

		UpdateSFX()
		UpdateMusic()

		Return True
	End Method


	Method StartFadeOverToNextTitle:int(fadeTime:int = -1)
		if not audioEngineEnabled then return False

		If fadeProcess <> 0
			?debug
			print "StartFadeOverToNextTitle(). Skipped, called while cross fade in progress."
			?
			return False
		?debug
		Else
			print "StartFadeOverToNextTitle(). ForceNextMusic=" + forceNextMusic
		?
		EndIf


		'set default if none was given
		if fadeTime = -1 then
			self.crossFadeTime = autoCrossFadeTime
		else
			self.crossFadeTime = fadeTime
		endif


		'maybe we missed the crossfade or "jumped beyond end"
		'so this limits fade to it and in case of already reaching
		'the end this means we instantly switch music
		local timeLeft:int = activeMusicStream.GetTimeLeft()
		if activeMusicStream.loop then timeLeft = activeMusicStream.GetLoopedPlaytimeLeft()
		self.crossFadeTime = Max(0, Min(self.crossFadeTime, timeLeft))

		?debug
		if activeMusicStream.loop
			print "  crossfade current track looptime left: " + activeMusicStream.GetLoopedPlaytimeLeft() + " played="+activeMusicStream.GetLoopedTimePlayed() +"  total="+activeMusicStream.GetLoopedPlaytime()
			print "  crossFadeTime: " + self.crossFadeTime
		else
			print "  crossfade current track time Left: " + activeMusicStream.GetTimeLeft() + " played="+activeMusicStream.GetTimePlayed() +"  total="+activeMusicStream.GetTimeTotal()
			print "  crossFadeTime: " + self.crossFadeTime
		endif
		?


		'fade in the next channel
		fadeProcess = 1
		fadeProcessTime = Time.MillisecsLong()

		'load next music "into" a new inactive channel and start playing
		inactiveMusicChannel = nextMusicStream.CreateChannel(0)
		ResumeChannel(inactiveMusicChannel)

		'switches inactive channel/stream with active channel/stream
		SwitchMusicChannels()

		'set current next one
		activeMusicStream = nextMusicStream
		nextMusicStream = Null

		?debug
		print "FadeOverToNextTitle(): inactiveMusicStream.IsPlaying() = " + inactiveMusicStream.IsPlaying()
		print "FadeOverToNextTitle(): activeMusicStream.IsPlaying() = " + activeMusicStream.IsPlaying()
		?


		forceNextMusic = False
	End Method


	Method UpdateFadeOverToNextTitle:int()
		if not audioEngineEnabled then return False

		'fade out of old (inactive) channel
		If fadeProcess = 1

			Local fadeValue:Float = 1.0
			if self.crossFadeTime > 0
				fadeValue = Max(0.0, Min(1.0, (Time.MillisecsLong() - fadeProcessTime) / float(crossFadeTime)))
			endif
			inactiveMusicChannel.SetVolume((1.0 - fadeValue) * musicVolume)
			activeMusicChannel.SetVolume(fadeValue * nextMusicVolume)


			if fadeValue >= 1.0 then fadeProcess = 2
		EndIf

		'fade finished
		If fadeProcess = 2
?debug
print "FadeOverToNextTitle() finished"
?
			fadeProcess = 0
			musicVolume = nextMusicVolume


			'stops the stream AND the channel (which might also remove it)
			inactiveMusicStream.Stop()
			'removes that channel!
			inactiveMusicChannel.Stop()
			'remove the whole stream (and the associated channel)
			inactiveMusicStream = null
			inactiveMusicChannel = null

			'make sure active is unpaused
			if activeMusicStream then activeMusicStream.SetPlaying(true)
		EndIf
	End Method


	Method SetMusicVolume:int(volume:Float)
		'disturbs fading!
		if activeMusicChannel then activeMusicChannel.SetVolume(volume)
		if inactiveMusicChannel then inactiveMusicChannel.SetVolume(volume)
		musicVolume = volume
		nextMusicVolume = volume
		defaultMusicVolume = volume
	End Method


	Method SwitchMusicChannels()
		Local channelTemp:TChannel = Self.activeMusicChannel
		Local streamTemp:TDigAudioStream = Self.activeMusicStream

		Self.activeMusicChannel = Self.inactiveMusicChannel
		Self.activeMusicStream = Self.inactiveMusicStream

		Self.inactiveMusicChannel = channelTemp
		Self.inactiveMusicStream = streamTemp
	End Method


	Method PlaySfx:int(sfx:TSound, channel:TChannel)
		if not audioEngineEnabled then return False

		If Not HasMutedSfx() And sfx Then PlaySound(sfx, Channel)
	End Method


	Method PlayMusicPlaylist(playlist:String)
		PlayMusicOrPlayList(playlist, True)
	End Method


	Method PlayMusic(music:String)
		PlayMusicOrPlayList(music, False)
	End Method


	Method PlayMusicOrPlaylist:Int(name:String, fromPlaylist:Int=False)
		if not audioEngineEnabled then return False

		If HasMutedMusic() Then Return True

		If fromPlaylist
			nextMusicStream = GetMusicStream("", name)
			nextMusicVolume = GetMusicVolume(name)
			If nextMusicStream
				SetCurrentPlaylist(name)
				TLogger.Log("PlayMusicOrPlaylist", "GetMusicStream from Playlist ~q"+name+"~q. Also set current playlist to it.", LOG_DEBUG)
			Else
				TLogger.Log("PlayMusicOrPlaylist", "GetMusicStream from Playlist ~q"+name+"~q not possible. No Playlist.", LOG_DEBUG)
			EndIf
		Else
			nextMusicStream = GetMusicStream(name, "")
			nextMusicVolume = GetMusicVolume(name)
			TLogger.Log("PlayMusicOrPlaylist", "GetMusicStream by name ~q"+name+"~q", LOG_DEBUG)
		EndIf

		if not nextMusicStream
			TLogger.Log("PlayMusicOrPlaylist", "Music not found. Using random from default playlist", LOG_DEBUG)
			nextMusicStream = GetRandomMusicFromPlaylist("default")
			nextMusicVolume = defaultMusicVolume
			'when playing a default playlist anyways, this will skip
			'crossfading into another "default" one if a "default"
			'playlist is set as next then
			SetCurrentPlaylist("default")
		endif

		forceNextMusic = True


		'start to play music if not done yet
		If Not activeMusicChannel or Not activeMusicChannel.Playing()
			If Not nextMusicStream
				TLogger.Log("PlayMusicOrPlaylist", "could not start activeMusicChannel: no next music found", LOG_DEBUG)
			Else
				TLogger.Log("PlayMusicOrPlaylist", "start activeMusicChannel", LOG_DEBUG)
				Local musicVolume:Float = nextMusicVolume
				if activeMusicChannel then activeMusicChannel.Stop()
				activeMusicChannel = nextMusicStream.CreateChannel(musicVolume)

				activeMusicChannel.SetPaused(False)

				inactiveMusicStream = activeMusicStream
				activeMusicStream = nextMusicStream

				forceNextMusic = False
			EndIf
		EndIf


		'While playMusicPlayList will return the next song,
		'there is no guarantee that it does not return the
		'same song again
		'the nature of the stream's buffer is, that you
		'cannot play 1 stream in 2 different channels

		'that is why fading needs a clone if songs are the same
		if autoCrossFadeNextSong and nextMusicStream
			if nextMusicStream = activeMusicStream
				'print "playing same song: creating clone"
				nextMusicStream = activeMusicStream.Clone()
				nextMusicVolume = musicVolume
			endif
		endif
	End Method


	'returns if there would be a stream to play
	'use this to avoid music changes if there is no new stream available
	Method HasMusicStream:Int(music:String="", playlist:String="")
		If playlist=""
			Return Null <> TDigAudioStream(soundFiles.ValueForKey(Lower(music)))
		Else
			Return Null <> GetRandomMusicFromPlaylist(playlist, nextMusicStream)
		EndIf
	End Method


	Method GetMusicStream:TDigAudioStream(music:String="", playlist:String="")
		Local result:TDigAudioStream

		If playlist=""
			result = TDigAudioStream(soundFiles.ValueForKey(Lower(music)))
			TLogger.Log("TSoundManager.GetMusicStream()", "Play music: " + music, LOG_DEBUG)
		Else
			'try to get a song differing to the current one
			result = GetRandomMusicFromPlaylist(playlist, activeMusicStream)
			'result = GetRandomMusicFromPlaylist(playlist, nextMusicStream)
			Rem
			if result
				TLogger.log("TSoundManager.GetMusicStream()", "Play random music from playlist: ~q" + playlist +"~q  file: ~q"+result.url+"~q", LOG_DEBUG)
			else
				TLogger.log("TSoundManager.GetMusicStream()", "Cannot play random music from playlist: ~q" + playlist +"~q, nothing found.", LOG_DEBUG)
			endif
			endrem
		EndIf

		Return result
	End Method


	Method GetSfx:TSound(sfx:String="", playlist:String="")
		Local result:TSound
		If playlist=""
			result = TSound(soundFiles.ValueForKey(Lower(sfx)))
			'TLogger.log("TSoundManager.GetSfx()", "Play sfx: " + sfx, LOG_DEBUG)
		Else
			result = GetRandomSfxFromPlaylist(playlist)
			'TLogger.log("TSoundManager.GetSfx()", "Play random sfx from playlist: " + playlist, LOG_DEBUG)
		EndIf

		Return result
	End Method

rem
	'by default all sfx share the same volume
	Method GetSfxVolume:Float(sfx:String)
		Return 0.2
	End Method
endrem
	'by default all music share the same volume
	Method GetMusicVolume:Float(music:String)
		Return defaultMusicVolume
	End Method


	Method CreateDigAudioStreamOgg:TDigAudioStream(uri:string, loop:int)
		return null
	End Method
End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetSoundManagerBase:TSoundManager()
	return TSoundManager.GetInstance()
End Function



'base class
Type TDigAudioStream
	Field playing:int = False
	Field playtime:int = 0
	Field loop:Int = False
	Field lastChannelTime:Long


	Method Clone:TDigAudioStream(deepClone:Int = False) abstract

	Method CreateChannel:TChannel(volume:Float) abstract

	Method GetChannel:TChannel() abstract

	Method GetChannelPosition:int()
		return 0
	End Method


	Method Stop()
		SetPlaying(False)
	End Method


	Method Update()
		'do stream updates here if needed
	End Method


	Method GetURI:object()
		return null
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


	Method GetLoopedPlaytimeLeft:Int()
		return GetLoopedPlaytime() - GetLoopedTimePlayed()
	End Method


	'returns time left in milliseconds
	Method GetTimeLeft:Int()
		Return GetLoopedPlaytimeLeft()
	End Method


	'returns milliseconds
	Method GetTimePlayed:Int()
		return GetLoopedTimePlayed()
	End Method


	'returns milliseconds
	Method GetTimeBuffered:Int()
		return 0
	End Method


	'returns milliseconds
	Method GetTimeTotal:Int()
		return GetLoopedPlaytime()
	End Method

End Type





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





'base class wrapping a normal channel to add extended features
Type TSfxChannel
	'preallocating channels returns invalid channels if done before the
	'soundengine (eg. FreeAudio) is initialized
	'-> channel.fa_channel is 0 then
	Field _Channel:TChannel '= AllocChannel()
	Field CurrentSfx:String
	Field CurrentSettings:TSfxSettings
	Field MuteAfterCurrentSfx:Int


	Function Create:TSfxChannel()
		Return New TSfxChannel
	End Function


	Method GetChannel:TChannel()
		'Ask sound manager to check the channel
		TSoundManager.GetInstance().FixChannel(self)

		If not _channel 
			_channel = AllocChannel()
			'print "AllocChannel() for ~q" + CurrentSfx+"~q. _channel="+_channel.ToString() + "   time="+Millisecs()
		EndIf

		return _channel
	End Method


	Method PlaySfx(sfx:String, settings:TSfxSettings=Null)
		'skip adjustments and loading the sound
		if TSoundManager.GetInstance().HasMutedSfx() then return

		CurrentSfx = sfx
		CurrentSettings = settings
		
		' ensure we have a channel (AdjustSettings() requires one)
		Local c:TChannel = GetChannel()
		If Not c Then Return

		'print "PlaySfX: " + sfx
		AdjustSettings(False)

		Local sound:TSound = TSoundManager.GetInstance().GetSfx(sfx)
		if not sound then return

		TSoundManager.GetInstance().PlaySfx(sound, c)
	End Method


	Method PlayRandomSfx(playlist:String, settings:TSfxSettings=Null)
		'skip adjustments and loading the sound
		if TSoundManager.GetInstance().HasMutedSfx() then return

		CurrentSfx = playlist
		CurrentSettings = settings

		' ensure we have a channel (AdjustSettings() requires one)
		Local c:TChannel = GetChannel()
		If Not c Then Return

		'print "PlayRandomSfx: " + playlist
		AdjustSettings(False)

		Local sound:TSound = TSoundManager.GetInstance().GetSfx("", playlist)
		if not sound then return

		TSoundManager.GetInstance().PlaySfx(sound, c)
		'if sound then PlaySound(sound, channel)
	End Method


	Method IsActive:Int()
		If not _channel then return False

		Return _channel.Playing()
	End Method


	Method Stop()
		If not _channel then return

		_channel.Stop()
	End Method


	Method Mute(bool:Int=True)
		If not _channel then return

		If bool
			If MuteAfterCurrentSfx And IsActive()
				AdjustSettings(True)
			Else
				GetChannel().SetVolume(0)
			EndIf
		Else
			GetChannel().SetVolume(TSoundManager.GetInstance().sfxVolume)
		EndIf
	End Method


	Method AdjustSettings(isUpdate:Int)
		If not _channel then return

		If Not isUpdate
			GetChannel().SetVolume(TSoundManager.GetInstance().sfxVolume * 0.75 * CurrentSettings.GetVolume()) '0.75 ist ein fixer Wert die Lautstärke der Sfx reduzieren soll
		EndIf
	End Method
End Type




'Der dynamische SfxChannel hat die Möglichkeit abhängig von der Position von Sound-Quelle und Empfänger dynamische Modifikationen an den Einstellungen vorzunehmen. Er wird bei jedem Update aktualisiert.
Type TDynamicSfxChannel Extends TSfxChannel
	Field Source:TSoundSourceElement
	Field Receiver:TSoundSourcePosition
	'used to be able to define where a position is - left or right side
	'of the building center
	Global soundPanOffset:int = 0 '+150 if you want to offset the building
	Global soundPanWidth:int = 235


	Function CreateDynamicSfxChannel:TSfxChannel(source:TSoundSourceElement=Null)
		Local sfxChannel:TDynamicSfxChannel = New TDynamicSfxChannel
		sfxChannel.Source = source
		Return sfxChannel
	End Function


	Method SetReceiver(_receiver:TSoundSourcePosition)
		Self.Receiver = _receiver
	End Method


	Method AdjustSettings(isUpdate:Int)
		'create one, so we could adjust volume etc before starting to play
		if not _channel then GetChannel()
		if not _channel then return

		'Local sourcePoint:SVec3D = Source.GetCenter()
		'most probably the center of the figure
		'Local receiverPoint:SVec3D = Receiver.GetCenter()

		If CurrentSettings.forceVolume
			_channel.SetVolume( TSoundManager.GetInstance().sfxVolume * CurrentSettings.defaultVolume )
			'print "Volume (forced):" + (TSoundManager.GetInstance().sfxVolume * CurrentSettings.defaultVolume) +   "    source="+TTypeID.ForObject(Source).Name() + "  receiver="+TTypeID.ForObject(Receiver).Name()
		Else
			'Volume is dependend on distance to sound source
			Local distanceVolume:Float = CurrentSettings.GetVolumeByDistance(Source, Receiver)
'			if CurrentSfx = "elevator_door_open"
				_channel.SetVolume( TSoundManager.GetInstance().sfxVolume * distanceVolume )
'			endif
			'print "-> Volume [" + CurrentSfx + "]: " + (TSoundManager.GetInstance().sfxVolume * distanceVolume) +   "    source="+TTypeID.ForObject(Source).Name() + "  receiver="+TTypeID.ForObject(Receiver).Name() + "    channel = " + _channel.ToString()
		EndIf
return
rem
		If (sourcePoint.z = 0) Then
			'soundPanWidth describes where the maximum of left/right
			'is reached. soundPanOffset any potential offset from center
			If CurrentSettings.forcePan
				_channel.SetPan(CurrentSettings.defaultPan)
			Else
				_channel.SetPan(Max(-1.0, Min(1.0, Float(sourcePoint.x - receiverPoint.x - soundPanOffset) / soundPanWidth)))
			EndIf
			'depth is unimportant as elementPoint.z = 0
			_channel.SetDepth(0)
		Else
			Local zDistance:Float = Abs(sourcePoint.z - receiverPoint.z)

			If CurrentSettings.forcePan
				_channel.SetPan(CurrentSettings.defaultPan)
				'print "Pan:" + CurrentSettings.defaultPan
			Else
				Local xDistance:Float = Abs(sourcePoint.x - receiverPoint.x)
				Local yDistance:Float = Abs(sourcePoint.y - receiverPoint.y)

				'aTan: what is the angle from listener to sound source
				'90° = in front/back
				'0°  = same level
				Local angleZX:Float = ATan(zDistance / xDistance)

				Local rawPan:Float = ((90 - angleZX) / 90)
				'The right/left effect should be made less powerful if the source is near
				Local panCorrection:Float = Max(0, Min(1, xDistance / soundPanWidth))
				Local correctPan:Float = rawPan * panCorrection

				'0° => from one direction
				'90° => from both directions
				'left
				If (sourcePoint.x < receiverPoint.x)
					_channel.SetPan(-correctPan)
					'print "Pan:" + (-correctPan) + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				'right
				ElseIf (sourcePoint.x > receiverPoint.x)
					_channel.SetPan(correctPan)
					'print "Pan:" + correctPan + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				'center
				Else
					_channel.SetPan(0)
				EndIf
			EndIf

			If CurrentSettings.forceDepth
				_channel.SetDepth(CurrentSettings.defaultDepth)
				'print "Depth:" + CurrentSettings.defaultDepth
			Else
				Local angleOfDepth:Float = ATan(receiverPoint.DistanceTo(sourcePoint, False) / zDistance) '0 = direkt hinter mir/vor mir, 90° = über/unter/neben mir

				'negative values = background / positive values = front
				'from back
				If sourcePoint.z < 0
					_channel.SetDepth(-((90 - angleOfDepth) / 90))
					'print "Depth:" + (-((90 - angleOfDepth) / 90)) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				'from front
				ElseIf sourcePoint.z > 0
					_channel.SetDepth((90 - angleOfDepth) / 90)
					'print "Depth:" + ((90 - angleOfDepth) / 90) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				EndIf
			EndIf
		EndIf
endrem
	End Method
End Type




Type TSfxSettings
	Field forceVolume:Int = False
	Field forcePan:Int = False
	Field forceDepth:Int = False

	Field defaultVolume:Float = 1
	Field defaultPan:Float = 0
	Field defaultDepth:Float = 0

	Field nearbyDistanceRange:Int = -1
	Field maxDistanceRange:Int = 1000

	Field nearbyRangeVolume:Float = 1
	Field midRangeVolume:Float = 0.8
	Field minVolume:Float = 0


	Function Create:TSfxSettings()
		Return New TSfxSettings
	End Function


	Method GetVolume:Float()
		Return defaultVolume
	End Method


	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TSoundSourcePosition)
		Local currentDistance:Int = source.GetCenter().DistanceTo(receiver.getCenter())
		Local result:Float = midRangeVolume
		If (currentDistance <> -1) Then
			If currentDistance > Self.maxDistanceRange Then 'zu weit weg
				result = Self.minVolume
			ElseIf currentDistance < Self.nearbyDistanceRange Then 'sehr nah dran
				result = Self.nearbyRangeVolume
			Else 'irgendwo dazwischen
				'exponential decrease - the more far away, the less volume
				result = midRangeVolume  - midRangeVolume * (Float(currentDistance) / Float(Self.maxDistanceRange))^2
'				result = midRangeVolume * (Float(Self.maxDistanceRange) - Float(currentDistance)) / Float(Self.maxDistanceRange)
			EndIf
		EndIf
		'print "GetVolumeByDistance: result=" + result + "  distance=" + currentDistance + "  midRangeVolume=" + midRangeVolume + "  Self.maxDistanceRange="+Self.maxDistanceRange +"  Self.nearbyDistanceRange="+Self.nearbyDistanceRange

		Return result
	End Method
End Type




Type TSoundSourcePosition 'Basisklasse für verschiedene Wrapper
	Field ID:Int = 0
	Global _lastID:Int = 0

	Method GetCenter:SVec3D() Abstract
	Method IsMovable:Int() Abstract
	Method GetClassIdentifier:String() Abstract


	Method New()
		_lastID :+ 1
		ID = _lastID
	End Method


	Method GetGUID:String()
		Return GetClassIdentifier()+"-"+ID
	End Method
End Type




Type TSoundSourceElement Extends TSoundSourcePosition
	Field id:int
	Field GUID:String = ""
	Field SfxChannels:TSfxChannel[]
	Field SfxChannelNames:String[]
	Global lastID:int = 0

	Method GetIsHearable:Int() Abstract
	Method GetChannelForSfx:TSfxChannel(sfx:String) Abstract
	Method GetSfxSettings:TSfxSettings(sfx:String) Abstract
	Method OnPlaySfx:Int(sfx:String) Abstract


	Method New()
		lastID :+ 1
		id = lastID
	End Method


	Method GetID:Int()
		Return id
	End Method


	Method GetGUID:String()
		If GUID = "" Then Return GetClassIdentifier()+"-"+ID
		Return GUID
	End Method


	Method SetGUID(newGUID:String)
		GUID = newGUID
	End Method


	Method GetReceiver:TSoundSourcePosition()
		Return TSoundManager.GetInstance().GetDefaultReceiver()
	End Method


	Method PlayRandomSfx(playlist:String, sfxSettings:TSfxSettings=Null)
		PlaySfxOrPlaylist(playlist, sfxSettings, True)
	End Method


	Method PlaySfx(sfx:String, sfxSettings:TSfxSettings=Null)
		PlaySfxOrPlaylist(sfx, sfxSettings, False)
	End Method


	Method PlaySfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:Int=False)
		If Not GetIsHearable() Then Return
		If Not OnPlaySfx(name) Then Return

		TSoundManager.GetInstance().RegisterSoundSource(Self)

		Local channel:TSfxChannel = GetChannelForSfx(name)
		if not channel 
			TLogger.Log("PlaySfxOrPlaylist", "GetChannelForSfx() did not return a channel for ~q" + name+"~q.", LOG_DEBUG)
			return
		endif
		'print GetID() + " # PlaySfx: " + name + "   sfxchannel="+channel.ToString() + "  time="+Millisecs()
		

		Local settings:TSfxSettings = sfxSettings
		If not settings Then settings = GetSfxSettings(name)

		If TDynamicSfxChannel(channel)
			TDynamicSfxChannel(channel).SetReceiver(GetReceiver())
		EndIf

		If playlistMode
			channel.PlayRandomSfx(name, settings)
		Else
			channel.PlaySfx(name, settings)
		EndIf
		'print GetID() + " # End PlaySfx: " + sfx
	End Method


	Method PlayOrContinueRandomSfx(playlist:String, sfxSettings:TSfxSettings=Null)
		PlayOrContinueSfxOrPlaylist(playlist, sfxSettings, True)
	End Method


	Method PlayOrContinueSfx(sfx:String, sfxSettings:TSfxSettings=Null)
		PlayOrContinueSfxOrPlaylist(sfx, sfxSettings, False)
	End Method


	Method PlayOrContinueSfxOrPlaylist(name:String, sfxSettings:TSfxSettings=Null, playlistMode:Int=False)
		Local channel:TSfxChannel = GetChannelForSfx(name)
		if not channel then return

		If Not channel.IsActive() then PlaySfxOrPlaylist(name, sfxSettings, playlistMode)
	End Method
	
	
	Method StopAll()
		For local channel:TSfxChannel = Eachin sfxChannels
			channel.Stop()
		Next
	End Method


	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		if not channel then return

		channel.Stop()
	End Method


	Method Mute:Int(sfx:String, bool:Int=True)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		if not channel then return False

		channel.Mute(bool)
		
		Return True
	End Method


	Method Mute:Int(bool:Int=True)
		For Local sfxChannel:TSfxChannel = EachIn SfxChannels
			sfxChannel.Mute(bool)
		Next
		
		Return True
	End Method


	Method Update()
		If GetIsHearable()
'			For Local sfxChannel:TSfxChannel = EachIn SfxChannels
			For local i:int = 0 until sfxChannels.length
				Local sfxChannel:TSfxChannel = SfxChannels[i]
				If sfxChannel.IsActive() Then sfxChannel.AdjustSettings(True)
			Next
		Else
'			For Local sfxChannel:TSfxChannel = EachIn SfxChannels
			For local i:int = 0 until sfxChannels.length
				Local sfxChannel:TSfxChannel = SfxChannels[i]
				sfxChannel.Mute()
			Next
		EndIf
	End Method


	Method AddDynamicSfxChannel:TSfxChannel(name:String, muteAfterSfx:Int=False)
		Local sfxChannel:TSfxChannel = TDynamicSfxChannel.CreateDynamicSfxChannel(Self)
		sfxChannel.MuteAfterCurrentSfx = muteAfterSfx

		Local index:Int = GetSfxChannelIndex(name)
		'append
		if index = -1
			sfxChannelNames :+ [name]
			sfxChannels :+ [sfxChannel]
		'overwrite
		Else
			'name already the same
			'sfxChannelNames[index] = [name]
			sfxChannels[index] = sfxChannel
		EndIf
		Return sfxChannel
	End Method
	
	
	Method GetSfxChannelIndex:Int(name:String)
		For local i:int = 0 until sfxChannelNames.length
			if sfxChannelNames[i] = name then return i
		Next
		Return -1
	End Method


	Method GetSfxChannelByName:TSfxChannel(name:String)
		Local index:int = GetSfxChannelIndex(name)
		if index = -1 then Return Null
		Return sfxChannels[index]
	End Method
End Type
