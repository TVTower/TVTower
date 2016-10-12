SuperStrict
Import brl.Map
Import brl.WAVLoader
Import brl.OGGLoader
Import "base.util.logger.bmx"
Import "base.util.vector.bmx"

'the needed module files are located in "external/maxmod2_lite.mod.zip"
?Not bmxng
Import MaxMod2.ogg

Import MaxMod2.rtaudio
'Import MaxMod2.rtaudionopulse
Import MaxMod2.WAV
?bmxng
Import brl.audio
?

'type to store music files (ogg) in it
'data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TDigAudioStream
	Field bank:TBank
	Field loop:Int
	Field url:String


	Function Create:TDigAudioStream(url:Object, loop:Int=False)
		Local obj:TDigAudioStream = New TDigAudioStream
		obj.bank = LoadBank(url)
		obj.loop = loop
		obj.url = "unknown"
		If String(url) Then obj.url=String(url)
		Return obj
	End Function


	Method Clone:TDigAudioStream(deepClone:Int = False)
		Local c:TDigAudioStream = New TDigAudioStream
		c.bank = Self.bank
		c.loop = Self.loop
		c.url = Self.url
		Return c
	End Method


	Method isValid:Int()
		If Not Self.bank Then Return False
		Return True
	End Method


	Method GetChannel:TChannel(volume:Float)
?bmxng
		Local channel:TChannel = New TChannel()
?Not bmxng
		Local channel:TChannel = CueMusic(Self.bank, loop)
		channel.SetVolume(volume)
?
		Return channel
	End Method
End Type


Type TDigAudioStreamOgg Extends TDigAudioStream
	Method CreateWithFile:TDigAudioStreamOgg(url:Object, loop:Int = False, useMemoryStream:Int = False)
		Self.bank = LoadBank(url)
		Self.loop = loop
		Self.url = "unknown"
		If String(url) Then Self.url=String(url)
		Return Self
	End Method


	Method Clone:TDigAudioStreamOgg(deepClone:Int = False)
		Local c:TDigAudioStreamOgg = New TDigAudioStreamOgg
		c.bank = Self.bank
		c.loop = Self.loop
		c.url = Self.url
		Return c
	End Method
End Type




Type TSoundManager
	Field soundFiles:TMap = CreateMap()
	Field musicChannel1:TChannel = Null
	Field musicChannel2:TChannel = Null
	Field activeMusicChannel:TChannel = Null
	Field inactiveMusicChannel:TChannel = Null

	Field sfxChannel_Elevator:TChannel = Null
	Field sfxChannel_Elevator2:TChannel = Null
	Field sfxVolume:Float = 1
	Field defaulTSfxDynamicSettings:TSfxSettings = Null

	Field sfxOn:Int = 1
	Field musicOn:Int = 1
	Field musicVolume:Float = 1
	Field nextMusicTitleVolume:Float = 1
	Field lastTitleNumber:Int = 0
	Field currenTDigAudioStream:TDigAudioStream = Null
	Field nextMusicTitleStream:TDigAudioStream = Null

	Field currentMusic:TSound = Null
	Field nextMusicTitle:TSound = Null
	Field forceNextMusicTitle:Int = 0
	Field fadeProcess:Int = 0 '0 = nicht aktiv  1 = aktiv
	Field fadeOutVolume:Int = 1000
	Field fadeInVolume:Int = 0

	Field soundSources:TMap = CreateMap()
	Field receiver:TSoundSourcePosition

	Field _currentPlaylistName:String = "default"
	Field playlists:TMap = CreateMap()		'a named array of playlists, playlists contain available musicStreams


	Global instance:TSoundManager

	Global PREFIX_MUSIC:String = "MUSIC_"
	Global PREFIX_SFX:String = "SFX_"

	Global audioEngineEnabled:Int = True
	Global audioEngine:String = "AUTOMATIC"


	Function Create:TSoundManager()
		Local manager:TSoundManager = New TSoundManager


		'initialize sound system
		InitAudioEngine()


		manager.musicChannel1 = AllocChannel()
		manager.musicChannel2 = AllocChannel()
		manager.sfxChannel_Elevator = AllocChannel()
		manager.sfxChannel_Elevator2 = AllocChannel()
		manager.defaulTSfxDynamicSettings = TSfxSettings.Create()
		Return manager
	End Function


	Function SetAudioEngine:int(engine:String)
		if engine.ToUpper() = audioEngine then return False
		
		'limit to allowed engines
		Select engine.ToUpper()
			Case "NONE"
				audioEngine = "NONE"

			Case "LINUX_ALSA"
				audioEngine = "LINUX_ALSA"
			Case "LINUX_PULSE"
				audioEngine = "LINUX_PULSE"
			Case "LINUX_OSS"
				audioEngine = "LINUX_OSS"
			'following are currently not compiled in the rtAudio module
			'case "UNIX_JACK"
			'	audioEngine = "UNIX_JACK"

			Case "MACOSX_CORE"
				audioEngine = "MACOSX_CORE"

			Case "WINDOWS_ASIO"
				audioEngine = "WINDOWS_ASIO"
			Case "WINDOWS_DS"
				audioEngine = "WINDOWS_DS"

			Default
				audioEngine = "AUTOMATIC"
		End Select

		return True
	End Function


	Function InitSpecificAudioEngine:Int(engine:String)
?Not bmxng
		TMaxModRtAudioDriver.Init(engine)
?
		'
		If Not SetAudioDriver("MaxMod RtAudio")
			If engine = audioEngine
				TLogger.Log("SoundManager.SetAudioEngine()", "audio engine ~q"+engine+"~q (configured) failed.", LOG_ERROR)
			Else
				TLogger.Log("SoundManager.SetAudioEngine()", "audio engine ~q"+engine+"~q failed.", LOG_ERROR)
			EndIf
			Return False
		Else
			Return True
		EndIf
	End Function


	Function InitAudioEngine:Int()
		'reenable rtAudio-messages
?Not bmxng
		TMaxModRtAudioDriver.showWarnings(False)
?
		Local engines:String[] = [audioEngine]
		'add automatic-engine if manual setup is not already set to it
		If audioEngine <> "AUTOMATIC" Then engines :+ ["AUTOMATIC"]

		?Linux
			If audioEngine <> "LINUX_PULSE" Then engines :+ ["LINUX_PULSE"]
			If audioEngine <> "LINUX_ALSA" Then engines :+ ["LINUX_ALSA"]
			If audioEngine <> "LINUX_OSS" Then engines :+ ["LINUX_OSS"]
			'if audioEngine <> "UNIX_JACK" then engines :+ ["UNIX_JACK"]
		?MacOS
			'ATTENTION: WITHOUT ENABLED SOUNDCARD THIS CRASHES!
			engines :+ ["MACOSX_CORE"]
		?Win32
			engines :+ ["WINDOWS_ASIO"]
			engines :+ ["WINDOWS_DS"]
		?

		'try to init one of the engines, starting with the manually set
		'audioEngine
		Local foundWorkingEngine:String = ""
		If audioEngine <> "NONE"
			For Local engine:String = EachIn engines
				If InitSpecificAudioEngine(engine)
					foundWorkingEngine = engine
					Exit
				EndIf
			Next
		EndIf

		'if no sound engine initialized successfully, use the dummy
		'output (no sound)
		If foundWorkingEngine = ""
			TLogger.Log("SoundManager.SetAudioEngine()", "No working audio engine found. Disabling sound.", LOG_ERROR)
			DisableAudioEngine()
			Return False
		EndIf

		'reenable rtAudio-messages
?Not bmxng
		TMaxModRtAudioDriver.showWarnings(True)
?
		TLogger.Log("SoundManager.SetAudioEngine()", "initialized with engine ~q"+foundWorkingEngine+"~q.", LOG_DEBUG)
		Return True
	End Function


	Function GetInstance:TSoundManager()
		If Not instance Then instance = TSoundManager.Create()
		Return instance
	End Function


	Function DisableAudioEngine:Int()
		audioEngineEnabled = False
	End Function


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
		Return _currentPlaylistName:String
	End Method


	Method SetCurrentPlaylist(name:String="default")
		_currentPlaylistName = name
	End Method


	'use this method if multiple sfx for a certain event are possible
	'(so eg. multiple "door open/close"-sounds to make variations
	Method GetRandomSfxFromPlaylist:TSound(playlist:String)
		playlist = playlist.ToLower()
		Local playlistContainer:TList = TList(playlists.ValueForKey(PREFIX_SFX + playlist))

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
	Method GetRandomMusicFromPlaylist:TDigAudioStream(playlist:String, avoidMusic:TDigAudioStream=Null)
		playlist = playlist.ToLower()
		Local playlistContainer:TList = TList(playlists.ValueForKey(PREFIX_MUSIC + playlist))
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

'		local playlistContainer:TDigAudioStream[] = TDigAudioStream[](playlists.ValueForKey("MUSIC_"+playlist))
'		if playlistContainer.length = 0 then print "empty list:"+"MUSIC_"+playlist; return NULL
'		return playlistContainer[Rand(0, playlistContainer.length-1)]
	End Method


	Method RegisterSoundSource:Int(soundSource:TSoundSourceElement)
		If Not soundSource Then Return False
		If Not soundSources.ValueForKey(soundSource.GetGUID())
			soundSources.Insert(soundSource.GetGUID(), soundSource)
		EndIf
	End Method


	Method GetSoundSource:TSoundSourceElement(GUID:String)
		Return TSoundSourceElement(soundSources.ValueForKey(GUID))
	End Method


	Method IsPlaying:Int()
		If Not activeMusicChannel Then Return False
		Return activeMusicChannel.Playing()
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
		
		If Not audioEngineEnabled Then Return False

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


	Method Update:Int()
		'skip updates if muted
		If isMuted() Then Return True

		If sfxOn
			For Local element:TSoundSourceElement = EachIn soundSources.Values()
				element.Update()
			Next
		EndIf

		If Not HasMutedMusic()
			'Wenn der Musik-Channel nicht läuft, dann muss nichts gemacht werden
			If Not activeMusicChannel Then Return True

			'if the music didn't stop yet
			If activeMusicChannel.Playing()
				If (forceNextMusicTitle And nextMusicTitleStream) Or fadeProcess > 0
'					TLogger.log("TSoundManager.Update()", "FadeOverToNextTitle", LOG_DEBUG)
					FadeOverToNextTitle()
				EndIf
			'no music is playing, just start
			Else
				TLogger.Log("TSoundManager.Update()", "PlayMusicPlaylist", LOG_DEBUG)
				PlayMusicPlaylist(GetCurrentPlaylist())
			EndIf
		EndIf
	End Method


	Method FadeOverToNextTitle:Int()
		If Not audioEngineEnabled Then Return False

		If (fadeProcess = 0) Then
			fadeProcess = 1
			inactiveMusicChannel = nextMusicTitleStream.GetChannel(0)
			ResumeChannel(inactiveMusicChannel)
			nextMusicTitleStream = Null

			forceNextMusicTitle = False
			fadeOutVolume = 1000
			fadeInVolume = 0
		EndIf

		If (fadeProcess = 1) Then 'Das fade out des aktiven Channels
			fadeOutVolume = fadeOutVolume - 15
			activeMusicChannel.SetVolume(fadeOutVolume/1000.0 * musicVolume)

			fadeInVolume = fadeInVolume + 15
			inactiveMusicChannel.SetVolume(fadeInVolume/1000.0 * nextMusicTitleVolume)
		EndIf

		If fadeOutVolume <= 0 And fadeInVolume >= 1000 Then
			fadeProcess = 0 'Prozess beendet
			musicVolume = nextMusicTitleVolume
			SwitchMusicChannels()
		EndIf
	End Method


	Method SwitchMusicChannels()
		Local channelTemp:TChannel = Self.activeMusicChannel
		Self.activeMusicChannel = Self.inactiveMusicChannel
		Self.inactiveMusicChannel = channelTemp
		Self.inactiveMusicChannel.Stop()
	End Method


	Method PlaySfx:Int(sfx:TSound, channel:TChannel)
		If Not audioEngineEnabled Then Return False

		If Not HasMutedSfx() And sfx Then PlaySound(sfx, Channel)
	End Method


	Method PlayMusicPlaylist(playlist:String)
		PlayMusicOrPlayList(playlist, True)
	End Method


	Method PlayMusic(music:String)
		PlayMusicOrPlayList(music, False)
	End Method


	Method PlayMusicOrPlaylist:Int(name:String, fromPlaylist:Int=False)
		If Not audioEngineEnabled Then Return False

		If HasMutedMusic() Then Return True

		If fromPlaylist
			nextMusicTitleStream = GetDigAudioStream("", name)
			nextMusicTitleVolume = GetMusicVolume(name)
			If nextMusicTitleStream
				SetCurrentPlaylist(name)
				TLogger.Log("PlayMusicOrPlaylist", "GetDigAudioStream from Playlist ~q"+name+"~q. Also set current playlist to it.", LOG_DEBUG)
			Else
				TLogger.Log("PlayMusicOrPlaylist", "GetDigAudioStream from Playlist ~q"+name+"~q not possible. No Playlist.", LOG_DEBUG)
			EndIf
		Else
			nextMusicTitleStream = GetDigAudioStream(name, "")
			nextMusicTitleVolume = GetMusicVolume(name)
			If nextMusicTitleStream
				TLogger.Log("PlayMusicOrPlaylist", "GetDigAudioStream by name ~q"+name+"~q", LOG_DEBUG)
			Else
				TLogger.Log("PlayMusicOrPlaylist", "GetDigAudioStream by name ~q"+name+"~q not possible. Not found.", LOG_DEBUG)
			EndIf
		EndIf

		forceNextMusicTitle = True

		'Wenn der Musik-Channel noch nicht laeuft, dann jetzt starten
		If Not activeMusicChannel Or Not activeMusicChannel.Playing()
			If Not nextMusicTitleStream
				'already logged with "no playlist" / "not found"
				'TLogger.Log("PlayMusicOrPlaylist", "could not start activeMusicChannel: no next music found", LOG_DEBUG)
			Else
				TLogger.Log("PlayMusicOrPlaylist", "start activeMusicChannel", LOG_DEBUG)
				Local musicVolume:Float = nextMusicTitleVolume
				activeMusicChannel = nextMusicTitleStream.GetChannel(musicVolume)
				ResumeChannel(activeMusicChannel)

				forceNextMusicTitle = False
			EndIf
		EndIf
	End Method


	'returns if there would be a stream to play
	'use this to avoid music changes if there is no new stream available
	Method HasMusicStream:Int(music:String="", playlist:String="")
		If playlist=""
			Return Null <> TDigAudioStream(soundFiles.ValueForKey(Lower(music)))
		Else
			Return Null <> GetRandomMusicFromPlaylist(playlist, nextMusicTitleStream)
		EndIf
	End Method


	Method GetDigAudioStream:TDigAudioStream(music:String="", playlist:String="")
		Local result:TDigAudioStream

		If playlist=""
			result = TDigAudioStream(soundFiles.ValueForKey(Lower(music)))
			TLogger.Log("TSoundManager.GetDigAudioStream()", "Play music: " + music, LOG_DEBUG)
		Else
			result = GetRandomMusicFromPlaylist(playlist, nextMusicTitleStream)
			Rem
			if result
				TLogger.log("TSoundManager.GetDigAudioStream()", "Play random music from playlist: ~q" + playlist +"~q  file: ~q"+result.url+"~q", LOG_DEBUG)
			else
				TLogger.log("TSoundManager.GetDigAudioStream()", "Cannot play random music from playlist: ~q" + playlist +"~q, nothing found.", LOG_DEBUG)
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


	'by default all sfx share the same volume
	Method GetSfxVolume:Float(sfx:String)
		Return 0.2
	End Method

	'by default all music share the same volume
	Method GetMusicVolume:Float(music:String)
		Return 1.0
	End Method
End Type

'===== CONVENIENCE ACCESSORS =====
'convenience instance getter
Function GetSoundManager:TSoundManager()
	Return TSoundManager.GetInstance()
End Function




'Diese Basisklasse ist ein Wrapper fuer einen normalen Channel mit erweiterten Funktionen
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
		if not _channel then _channel = AllocChannel()

		return _channel
	End Method


	Method PlaySfx(sfx:String, settings:TSfxSettings=Null)
		CurrentSfx = sfx
		CurrentSettings = settings

		AdjustSettings(False)

		Local sound:TSound = TSoundManager.GetInstance().GetSfx(sfx)
		TSoundManager.GetInstance().PlaySfx(sound, GetChannel())
	End Method


	Method PlayRandomSfx(playlist:String, settings:TSfxSettings=Null)
		CurrentSfx = playlist
		CurrentSettings = settings

		AdjustSettings(False)

		Local sound:TSound = TSoundManager.GetInstance().GetSfx("", playlist)
		if not sound or not GetChannel() then return
		TSoundManager.GetInstance().PlaySfx(sound, GetChannel())
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
		
		Local sourcePoint:TVec3D = Source.GetCenter()
		Local receiverPoint:TVec3D = Receiver.GetCenter() 'Meistens die Position der Spielfigur

		If CurrentSettings.forceVolume
			_channel.SetVolume(CurrentSettings.defaultVolume)
			'print "Volume:" + CurrentSettings.defaultVolume
		Else
			'Lautstärke ist Abhängig von der Entfernung zur Geräuschquelle
			Local distanceVolume:Float = CurrentSettings.GetVolumeByDistance(Source, Receiver)
			_channel.SetVolume(TSoundManager.GetInstance().sfxVolume * distanceVolume) ''0.75 ist ein fixer Wert die Lautstärke der Sfx reduzieren soll
			'print "Volume: " + (TSoundManager.GetInstance().sfxVolume * distanceVolume)
		EndIf

		If (sourcePoint.z = 0) Then
			'170 Grenzwert = Erst aber dem Abstand von 170 (gefühlt/geschätzt) hört man nur noch von einer Seite.
			'Ergebnis sollte ungefähr zwischen -1 (links) und +1 (rechts) liegen.
			If CurrentSettings.forcePan
				_channel.SetPan(CurrentSettings.defaultPan)
			Else
				_channel.SetPan(Float(sourcePoint.x - receiverPoint.x) / 170)
			EndIf
			_channel.SetDepth(0) 'Die Tiefe spielt keine Rolle, da elemenTVec2D.z = 0
		Else
			Local zDistance:Float = Abs(sourcePoint.z - receiverPoint.z)

			If CurrentSettings.forcePan
				_channel.SetPan(CurrentSettings.defaultPan)
				'print "Pan:" + CurrentSettings.defaultPan
			Else
				Local xDistance:Float = Abs(sourcePoint.x - receiverPoint.x)
				Local yDistance:Float = Abs(sourcePoint.y - receiverPoint.y)

				Local angleZX:Float = ATan(zDistance / xDistance) 'Winkelfunktion: Welchen Winkel hat der Hörer zur Soundquelle. 90° = davor/dahiner    0° = gleiche Ebene	tan(alpha) = Gegenkathete / Ankathete

				Local rawPan:Float = ((90 - angleZX) / 90)
				Local panCorrection:Float = Max(0, Min(1, xDistance / 170)) 'Den r/l Effekt sollte noch etwas abgeschwächt werden, wenn die Quelle nah ist
				Local correctPan:Float = rawPan * panCorrection

				'0° => Aus einer Richtung  /  90° => aus beiden Richtungen
				If (sourcePoint.x < receiverPoint.x) Then 'von links
					_channel.SetPan(-correctPan)
					'print "Pan:" + (-correctPan) + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				ElseIf (sourcePoint.x > receiverPoint.x) Then 'von rechts
					_channel.SetPan(correctPan)
					'print "Pan:" + correctPan + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				Else
					_channel.SetPan(0)
				EndIf
			EndIf

			If CurrentSettings.forceDepth
				_channel.SetDepth(CurrentSettings.defaultDepth)
				'print "Depth:" + CurrentSettings.defaultDepth
			Else
				Local angleOfDepth:Float = ATan(receiverPoint.DistanceTo(sourcePoint, False) / zDistance) '0 = direkt hinter mir/vor mir, 90° = über/unter/neben mir

				If sourcePoint.z < 0 Then 'Hintergrund
					_channel.SetDepth(-((90 - angleOfDepth) / 90)) 'Minuswert = Hintergrund / Pluswert = Vordergrund
					'print "Depth:" + (-((90 - angleOfDepth) / 90)) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				ElseIf sourcePoint.z > 0 Then 'Vordergrund
					_channel.SetDepth((90 - angleOfDepth) / 90) 'Minuswert = Hintergrund / Pluswert = Vordergrund
					'print "Depth:" + ((90 - angleOfDepth) / 90) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				EndIf
			EndIf
		EndIf
	End Method
End Type




Type TSfxSettings
	Field forceVolume:Float = False
	Field forcePan:Float = False
	Field forceDepth:Float = False

	Field defaultVolume:Float = 1
	Field defaultPan:Float = 0
	Field defaultDepth:Float = 0

	Field nearbyDistanceRange:Int = -1
'	Field nearbyDistanceRangeTopY:int -1
'	Field nearbyDistanceRangeBottomY:int -1   hier war ich
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

		Return result
	End Method
End Type




Type TSoundSourcePosition 'Basisklasse für verschiedene Wrapper
	Field ID:Int = 0
	Global _lastID:Int = 0

	Method GetCenter:TVec3D() Abstract
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
	Field GUID:String = ""
	Field SfxChannels:TMap = CreateMap()


	Method GetIsHearable:Int() Abstract
	Method GetChannelForSfx:TSfxChannel(sfx:String) Abstract
	Method GetSfxSettings:TSfxSettings(sfx:String) Abstract
	Method OnPlaySfx:Int(sfx:String) Abstract


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
		'print GetID() + " # PlaySfx: " + sfx

		TSoundManager.GetInstance().RegisterSoundSource(Self)

		Local channel:TSfxChannel = GetChannelForSfx(name)
		if not channel then return
		
		Local settings:TSfxSettings = sfxSettings
		If settings = Null Then settings = GetSfxSettings(name)

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


	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		if not channel then return
		
		channel.Stop()
	End Method


	Method Mute:Int(bool:Int=True)
		For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
			sfxChannel.Mute(bool)
		Next
	End Method


	Method Update()
		If GetIsHearable()
			For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
				If sfxChannel.IsActive() Then sfxChannel.AdjustSettings(True)
			Next
		Else
			For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
				sfxChannel.Mute()
			Next
		EndIf
	End Method


	Method AddDynamicSfxChannel:TSfxChannel(name:String, muteAfterSfx:Int=False)
		Local sfxChannel:TSfxChannel = TDynamicSfxChannel.CreateDynamicSfxChannel(Self)
		sfxChannel.MuteAfterCurrentSfx = muteAfterSfx
		SfxChannels.insert(name, sfxChannel)
		Return sfxChannel
	End Method


	Method GetSfxChannelByName:TSfxChannel(name:String)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))
	End Method
End Type