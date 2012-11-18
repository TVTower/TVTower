SuperStrict
Import brl.Map
'Import brl.OpenALAudio
'Import brl.FreeAudioAudio
Import brl.WAVLoader
Import brl.OGGLoader
Import "basefunctions.bmx"


Import maxmod2.ogg
Import maxmod2.rtaudio
Import MaxMod2.WAV

?Linux
'linux needs a different maxmod-implementation

'maybe move it to maxmod - or leave it out to save dependencies if not used
'import pulse for pulseaudio support
Import "-lpulse-simple"
TMaxModRtAudioDriver.Init("LINUX_PULSE")

If Not SetAudioDriver("MaxMod RtAudio") Then Throw "Audio Failed"
'only possible for linux
'For Local str:String = EachIn TMaxModRtAudioDriver.Active.APIs.Values()
'	Print "maxmod api:"+str
'Next

?Not Linux
'init has to be done for all
If Not SetAudioDriver("MaxMod RtAudio") Then Throw "Audio Failed"
?

Global SoundManager:TSoundManager = TSoundManager.Create()

Const MUSIC_TITLE:String					= "MUSIC_TITLE"
Const MUSIC_MUSIC:String					= "MUSIC_MUSIC"

Const SFX_ELEVATOR_OPENDOOR:String			= "SFX_ELEVATOR_OPENDOOR"
Const SFX_ELEVATOR_CLOSEDOOR:String			= "SFX_ELEVATOR_CLOSEDOOR"
Const SFX_ELEVATOR_ENGINE:String			= "SFX_ELEVATOR_ENGINE"

Const SFX_OPEN_DOOR:String					= "SFX_OPEN_DOOR"
Const SFX_CLOSE_DOOR:String					= "SFX_CLOSE_DOOR"


'type to store music files (ogg) in it
'data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TMusicStream
	field bank:TBank
	field loop:int

	Function Create:TMusicStream(url:object, loop:int=false)
		local obj:TMusicStream = new TMusicStream
		obj.bank = LoadBank(url)
		obj.loop = loop
		return obj
	End Function

	Method GetChannel:TChannel(volume:int)
		local channel:TChannel = CueMusic(self.bank, loop)
		channel.SetVolume(volume)
		Return channel
	End Method
End Type

Type TSoundManager
	Field soundFiles:TMap = null
	Field musicChannel1:TChannel = null
	Field musicChannel2:TChannel = null
	Field activeMusicChannel:TChannel = null
	Field inactiveMusicChannel:TChannel = null

	Field sfxChannel_Elevator:TChannel = null
	Field sfxChannel_Elevator2:TChannel = null
	Field sfxVolume:float = 1
	Field defaultSfxSettings:TSfxSettings = null

	Field musicOn:int = 1
	Field musicVolume:float = 1
	Field nextMusicTitleVolume:float = 1
	Field lastTitleNumber:int = 0
	Field currentMusicStream:TMusicStream = null
	Field nextMusicTitleStream:TMusicStream = null

	Field currentMusic:TSound = null
	Field nextMusicTitle:TSound = null
	Field forceNextMusicTitle:int = 0
	Field fadeProcess:int = 0 '0 = nicht aktiv  1 = aktiv
	Field fadeOutVolume:int = 1000
	Field fadeInVolume:int = 0

	Field soundSources:TList = CreateList()
	Field receiver:TElementPosition

	Function Create:TSoundManager()
rem
		If EnableOpenALAudio()
			print "AudioDriver: OpenAL"
			SetAudioDriver("OpenAL")
		Else
'			print "AudioDriver: MaxMod RtAudio"
			SetAudioDriver("MaxMod RtAudio")
			'SetAudioDriver("FreeAudio")
'		SetAudioDriver("OpenAL")
		End If
endrem

		Local manager:TSoundManager = New TSoundManager
		manager.musicChannel1 = AllocChannel()
		manager.musicChannel2 = AllocChannel()
		manager.sfxChannel_Elevator = AllocChannel()
		manager.sfxChannel_Elevator2 = AllocChannel()
		manager.defaultSfxSettings = TSfxSettings.Create()
		Return manager
	End Function
	
	Method GetDefaultReceiver:TElementPosition()
		print "GetDefaultReceiver: " + (receiver <> null)
		Return receiver
	End Method

	Method SetDefaultReceiver(_receiver:TElementPosition)
		print "SetDefaultReceiver: " + (_receiver <> null)
		receiver = _receiver
	End Method

	Method LoadSoundFiles()
		'mv: Alternativ kÃ¶nnen die Files auch in einem seperaten Thread geladen werden oder erst bei Bedarf... dann ruckelt's leider aber etwas. Kannst du (Ronny) entscheiden ;)
		local total:int = 8

		Self.soundFiles = CreateMap:TMap()
		LoadProgress(1, total)
		Self.soundFiles.insert( MUSIC_TITLE, TMusicStream.Create("res/music/title.ogg", true) )
		LoadProgress(2, total)
		Self.soundFiles.insert( MUSIC_MUSIC + "1", TMusicStream.Create("res/music/music1.ogg") )
		LoadProgress(3, total)
		Self.soundFiles.insert( MUSIC_MUSIC + "2", TMusicStream.Create("res/music/music2.ogg") )
		LoadProgress(4, total)
		Self.soundFiles.insert( MUSIC_MUSIC + "3", TMusicStream.Create("res/music/music3.ogg") )
		LoadProgress(5, total)
		Self.soundFiles.insert( MUSIC_MUSIC + "4", TMusicStream.Create("res/music/music4.ogg") )
		LoadProgress(6, total)
		Self.soundFiles.insert( MUSIC_MUSIC + "5", TMusicStream.Create("res/music/music5.ogg") )
		print "loaded sound files"
rem
		MapInsert( Self.soundFiles, MUSIC_TITLE, LoadSound("res/music/title.ogg", SOUND_LOOP) )
		LoadProgress(2, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "1", LoadSound("res/music/music1.ogg", SOUND_HARDWARE) )
		LoadProgress(3, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "2", LoadSound("res/music/music2.ogg", SOUND_HARDWARE) )
		LoadProgress(4, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "3", LoadSound("res/music/music3.ogg", SOUND_HARDWARE) )
		LoadProgress(5, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "4", LoadSound("res/music/music4.ogg", SOUND_HARDWARE) )
		LoadProgress(6, total)
		MapInsert( Self.soundFiles, MUSIC_MUSIC + "5", LoadSound("res/music/music5.ogg", SOUND_HARDWARE) )
endrem
		'LoadProgress(7, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "6", LoadSound("res/music/music6.ogg") )
		'LoadProgress(8, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "7", LoadSound("res/music/music7.ogg") )
		'LoadProgress(9, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "8", LoadSound("res/music/music8.ogg") )
		'LoadProgress(10, total)
		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "9", LoadSound("res/music/music9.ogg") )

		'MapInsert( Self.soundFiles, MUSIC_MUSIC + "9", LoadSound("res/music/specialroom1.ogg") )
		'Rnd(1, TRooms.RoomList.Count() - 1)

		LoadProgress(7, total)
		MapInsert( Self.soundFiles, SFX_ELEVATOR_OPENDOOR, LoadSound("res/sfx/elevator_openDoor.ogg", SOUND_HARDWARE) )
		
		LoadProgress(7, total)
		MapInsert( Self.soundFiles, SFX_ELEVATOR_CLOSEDOOR, LoadSound("res/sfx/elevator_closeDoor.ogg", SOUND_HARDWARE) )
		
		
		LoadProgress(7, total)
		MapInsert( Self.soundFiles, SFX_OPEN_DOOR, LoadSound("res/sfx/openDoor.ogg", SOUND_HARDWARE) )
		
		LoadProgress(7, total)
		MapInsert( Self.soundFiles, SFX_CLOSE_DOOR, LoadSound("res/sfx/closeDoor.ogg", SOUND_HARDWARE) )		
		

		LoadProgress(8, total)
		MapInsert( Self.soundFiles, SFX_ELEVATOR_ENGINE, LoadSound("res/sfx/elevator_engine.ogg", SOUND_LOOP | SOUND_HARDWARE) )
	End Method

	Method LoadProgress(currentCount:int, totalCount:int)
		'EventManager.triggerEvent( TEventSimple.Create("Loader.onLoadElement", TData.Create().AddString("text", "sound files").AddNumber("itemNumber", currentCount).AddNumber("maxItemNumber", totalCount) ) )
	End Method

	Method RegisterSoundSource(soundSource:TSoundSourceElement)
		If Not soundSources.Contains(soundSource) Then soundSources.AddLast(soundSource)
	End Method

	Method Update()
		For Local element:TSoundSourceElement = EachIn soundSources
			element.Update()
		Next

		If musicOn Then
			'Wenn der Musik-Channel nicht läuft, dann muss nichts gemacht werden
			If activeMusicChannel <> null
				If (Self.activeMusicChannel.Playing()) then
					If (Self.forceNextMusicTitle and Self.nextMusicTitleStream <> null) Or Self.fadeProcess > 0 then
						print "Fadeover"
						FadeOverToNextTitle()
					endif
				Else
					print "not playing"
					self.PlayMusic(MUSIC_MUSIC)
				Endif
			Endif
		EndIf
	End Method

	Method FadeOverToNextTitle()
		If (fadeProcess = 0) Then
			fadeProcess = 1
			inactiveMusicChannel = nextMusicTitleStream.GetChannel(0)
			ResumeChannel(inactiveMusicChannel)			
			Self.nextMusicTitleStream = null

			Self.forceNextMusicTitle = false
			Self.fadeOutVolume = 1000
			Self.fadeInVolume = 0
		Endif

		If (Self.fadeProcess = 1) Then 'Das fade out des aktiven Channels
			Self.fadeOutVolume = Self.fadeOutVolume - 15
			Self.activeMusicChannel.SetVolume(float(Self.fadeOutVolume) / 1000 * Self.musicVolume)

			Self.fadeInVolume = Self.fadeInVolume + 15
			Self.inactiveMusicChannel.SetVolume(float(Self.fadeInVolume) / 1000 * Self.nextMusicTitleVolume)
		Endif

		if Self.fadeOutVolume <= 0 And Self.fadeInVolume >= 1000 then
			Self.fadeProcess = 0 'Prozess beendet
			Self.musicVolume = Self.nextMusicTitleVolume
			SwitchMusicChannels()
		endif
	End Method

	Method SwitchMusicChannels()
		Local channelTemp:TChannel = Self.activeMusicChannel
		Self.activeMusicChannel = Self.inactiveMusicChannel
		Self.inactiveMusicChannel = channelTemp
		Self.inactiveMusicChannel.Stop()
	End Method

	Method PlayMusic(music:string)
		Self.nextMusicTitleStream = GetMusicStream(music)
		Self.nextMusicTitleVolume = GetVolume(music)
		Self.forceNextMusicTitle = true		

		'Wenn der Musik-Channel noch nicht lÃ¤uft, dann jetzt starten
		if activeMusicChannel = null Or not activeMusicChannel.Playing() then
			musicVolume = Self.nextMusicTitleVolume
			
			activeMusicChannel = nextMusicTitleStream.GetChannel(musicVolume)
			ResumeChannel(activeMusicChannel)

			Self.forceNextMusicTitle = false
		endif
	End Method
REM
	Method PlaySfx(sfx:string, element:TElementPosition, options:TSfxOptions = null)
		If (options = null) Then options = Self.defaultSfxOptions
		local currSfx:TSound = Self.GetSfx(sfx)
		local currChannel:TChannel = Self.GetSfxChannel(sfx)

		local elementfx:TSoundSourceElement = TMovingElementSfx.Create(self, sfx, currSfx, currChannel, receiver, element, options)

		elementfx.Play()

		If element.IsMovable()
			If MapContains(movingElements, elementfx.GetID()) Then MapRemove (movingElements, elementfx.GetID()) 'Alte EintrÃ¤ge entfernen
			MapInsert(movingElements, elementfx.GetID(), elementfx) 'Neuer Eintrag hinzufÃ¼gen

			local count:int = 0
			For Local element:TMovingElementSfx = EachIn MapValues(movingElements)
				count = count + 1
			Next
		Endif
	End Method
ENDREM
	Method GetMusicStream:TMusicStream(music:string)
		Local result:TMusicStream

		Select music
			Case MUSIC_MUSIC
				Local nextTitleNumber:int = int(Rnd(1,5))
				while(nextTitleNumber = Self.lastTitleNumber)
					nextTitleNumber = int(Rnd(1,5))
				wend
				result = TMusicStream(MapValueForKey(Self.soundFiles, MUSIC_MUSIC + nextTitleNumber))
				Self.lastTitleNumber = nextTitleNumber
				print "Play music: " + MUSIC_MUSIC + " (" + nextTitleNumber + ")"
			Default
				result = TMusicStream(MapValueForKey(Self.soundFiles, music))
				print "Play music: " + MUSIC_MUSIC
		EndSelect
		Return result
	End Method

	Method GetSfx:TSound (sfx:string)
		Return TSound(MapValueForKey(Self.soundFiles, sfx))
	End Method

	Method GetVolume:float(music:string)
		Select music
			Case MUSIC_TITLE
				return 1
			Default
				return 0.2
		EndSelect
	End Method

	Method GetSfxChannel:TChannel(sfx:string)
		Select sfx
			Case SFX_ELEVATOR_OPENDOOR
				Return Self.sfxChannel_Elevator
			Case SFX_ELEVATOR_CLOSEDOOR
				Return Self.sfxChannel_Elevator2				
			Case SFX_ELEVATOR_ENGINE
				Return Self.sfxChannel_Elevator
		EndSelect
	End Method
End Type

'Diese Basisklasse ist ein Wrapper für einen normalen Channel mit erweiterten Funktionen
Type TSfxChannel
	Field Channel:TChannel = AllocChannel()
	Field CurrentSfx:string
	Field CurrentSettings:TSfxSettings
	
	Function Create:TSfxChannel()
		Return new TSfxChannel
	End Function
	
	Method PlaySfx(sfx:string, settings:TSfxSettings=null)		
		CurrentSfx = sfx
		CurrentSettings = settings		
		
		AdjustSettings(false)

		local sound:TSound = SoundManager.GetSfx(sfx)		
		PlaySound(sound, Channel)
	End Method
	
	Method IsActive:int()
		Return Channel.Playing()
	End Method
	
	Method Stop()
		Channel.Stop()
	End Method
	
	Method AdjustSettings(isUpdate:int)
		If Not isUpdate			
			channel.SetVolume(SoundManager.sfxVolume * 0.75 * CurrentSettings.GetVolume()) '0.75 ist ein fixer Wert die Lautstärke der Sfx reduzieren soll
		Endif
	End Method
End Type

'Der dynamische SfxChannel hat die Möglichkeit abhängig von der Position von Sound-Quelle und Empfänger dynamische Modifikationen an den Einstellungen vorzunehmen. Er wird bei jedem Update aktualisiert.
Type TDynamicSfxChannel Extends TSfxChannel
	Field Source:TSoundSourceElement			
	Field Receiver:TElementPosition
	
	Function CreateDynamicSfxChannel:TSfxChannel(source:TSoundSourceElement=null)
		local sfxChannel:TDynamicSfxChannel = new TDynamicSfxChannel
		sfxChannel.Source = source		
		Return sfxChannel
	End Function	
	
	Method SetReceiver(_receiver:TElementPosition)
		self.Receiver = _receiver
	End Method
	
	Method AdjustSettings(isUpdate:int)
		local sourcePoint:TPoint = Source.GetCenter()
		local receiverPoint:TPoint = Receiver.GetCenter() 'Meistens die Position der Spielfigur		
		local distanceXYZ:int = receiverPoint.DistanceTo(sourcePoint)

		'Lautstärke ist Abhängig von der Entfernung zur Geräuschquelle
		local distanceVolume:float = CurrentSettings.GetVolumeByDistance(distanceXYZ)		
		channel.SetVolume(SoundManager.sfxVolume * distanceVolume) ''0.75 ist ein fixer Wert die Lautstärke der Sfx reduzieren soll
		
		If (sourcePoint.z = 0) Then
			'170 Grenzwert = Erst aber dem Abstand von 170 (gefühlt/geschätzt) hört man nur noch von einer Seite.
			'Ergebnis sollte ungefähr zwischen -1 (links) und +1 (rechts) liegen.
			channel.SetPan(float(sourcePoint.x - receiverPoint.x) / 170)
			channel.SetDepth(0) 'Die Tiefe spielt keine Rolle, da elementPoint.z = 0
		Else
			local xDistance:float = TPoint.DistanceOfValues(sourcePoint.x, receiverPoint.x)
			local yDistance:float = TPoint.DistanceOfValues(sourcePoint.y, receiverPoint.y)
			local zDistance:float = TPoint.DistanceOfValues(sourcePoint.z, receiverPoint.z)
			local angleZX:float = ATan(zDistance / xDistance) 'Winkelfunktion: Welchen Winkel hat der Hörer zur Soundquelle. 90° = davor/dahiner    0° = gleiche Ebene	tan(alpha) = Gegenkathete / Ankathete

			local rawPan:float = ((90 - angleZX) / 90)			
			local panCorrection:float = max(0, min(1, xDistance / 170)) 'Den r/l Effekt sollte noch etwas abgeschwächt werden, wenn die Quelle nah ist
			local correctPan:float = rawPan * panCorrection

			'0° => Aus einer Richtung  /  90° => aus beiden Richtungen
			If (sourcePoint.x < receiverPoint.x) Then 'von links
				channel.SetPan(-correctPan)
				'print "Pan:" + (-correctPan) + " - angle: " + angle + " (" + xAxis + "/" + zAxis + ")    # " + rawPan + " / " + panCorrection
			Elseif (sourcePoint.x > receiverPoint.x) Then 'von rechts
				channel.SetPan(correctPan)
				'print "Pan:" + correctPan + " - angle: " + angle + " (" + xAxis + "/" + zAxis + ")    # " + rawPan + " / " + panCorrection
			Else
				channel.SetPan(0)
			Endif
			
			local angleOfDepth:float = ATan(receiverPoint.DistanceTo(sourcePoint, false) / zDistance) '0 = direkt hinter mir/vor mir, 90° = über/unter/neben mir

			If sourcePoint.z < 0 Then 'Hintergrund
				channel.SetDepth(-((90 - angleOfDepth) / 90)) 'Minuswert = Hintergrund / Pluswert = Vordergrund
			'	print "Depth:" + (-((90 - angleOfDepth) / 90)) + " - angle: " + angleOfDepth + " (" + distanceXY + "/" + zAxis + ")"
			ElseIf sourcePoint.z > 0 Then 'Vordergrund
				channel.SetDepth((90 - angleOfDepth) / 90) 'Minuswert = Hintergrund / Pluswert = Vordergrund
			'	print "Depth:" + ((90 - angleOfDepth) / 90) + " - angle: " + angleOfDepth + " (" + distanceXY + "/" + zAxis + ")"
			Endif
		Endif
	End Method			
End Type


Type TSfxSettings
	Field defaultVolume:float = 1

	Field nearbyDistanceRange:int = -1
'	Field nearbyDistanceRangeTopY:int -1
'	Field nearbyDistanceRangeBottomY:int -1   hier war ich
	Field maxDistanceRange:int = 1000	
	
	Field nearbyRangeVolume:float = 1
	Field midRangeVolume:float = 0.8
	Field minVolume:float = 0	

	Function Create:TSfxSettings()
		Return new TSfxSettings
	End Function
	
	Method GetVolume:float()
		Return defaultVolume
	End Method
	
	Method GetVolumeByDistance:float(currentDistance:int)
		local result:float = midRangeVolume
		If (currentDistance <> -1) Then
			If currentDistance > Self.maxDistanceRange Then 'zu weit weg
				result = Self.minVolume
			Elseif currentDistance < Self.nearbyDistanceRange Then 'sehr nah dran
				result = Self.nearbyRangeVolume
			Else 'irgendwo dazwischen
				result = midRangeVolume * (float(Self.maxDistanceRange) - float(currentDistance)) / float(Self.maxDistanceRange)
			Endif
		Endif

		Return result
	End Method	
End Type


'Das ElementPositionzeug kann auch eventuell wo anders hin
Type TElementPosition 'Basisklasse für verschiedene Wrapper
	Method GetID:string() abstract
	Method GetCenter:TPoint() abstract
	Method IsMovable:int() abstract
End Type


Type TSoundSourceElement Extends TElementPosition
	Field SfxChannels:TMap = CreateMap()
		
	Method GetIsHearable:int() abstract
	Method GetChannelForSfx:TSfxChannel(sfx:string) abstract
	Method GetSfxSettings:TSfxSettings(sfx:string) abstract	
	Method OnPlaySfx:int(sfx:string) abstract
	
	Method GetReceiver:TElementPosition()
		Return SoundManager.GetDefaultReceiver()
	End Method
	
	Method PlaySfx(sfx:string)		
		If Not OnPlaySfx(sfx) Then Return
		
		SoundManager.RegisterSoundSource(self)
		
		local channel:TSfxChannel = GetChannelForSfx(sfx)
		local settings:TSfxSettings = GetSfxSettings(sfx)
		
		If TDynamicSfxChannel(channel)
			TDynamicSfxChannel(channel).SetReceiver(GetReceiver())
		Endif
		
		channel.PlaySfx(sfx, settings)
	End Method
	
	Method Update()	
		For Local sfxChannel:TSfxChannel = EachIn MapValues(SfxChannels)
			If sfxChannel.IsActive() Then sfxChannel.AdjustSettings(true)
		Next		
	End Method

	Method AddDynamicSfxChannel(name:string)
		SfxChannels.insert(name, TDynamicSfxChannel.CreateDynamicSfxChannel(self))
	End Method	

	Method GetSfxChannelByName:TSfxChannel(name:string)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))	
	End Method
End Type