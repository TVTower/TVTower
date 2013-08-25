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

Const SFX_STEPS:String						= "SFX_STEPS"

'type to store music files (ogg) in it
'data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TMusicStream
	Field bank:TBank
	Field loop:Int

	Function Create:TMusicStream(url:Object, loop:Int=False)
		Local obj:TMusicStream = New TMusicStream
		obj.bank = LoadBank(url)
		obj.loop = loop
		Return obj
	End Function

	Method GetChannel:TChannel(volume:Float)
		Local channel:TChannel = CueMusic(Self.bank, loop)
		channel.SetVolume(volume)
		Return channel
	End Method	
End Type

Type TSoundManager
	Field soundFiles:TMap = Null
	Field musicChannel1:TChannel = Null
	Field musicChannel2:TChannel = Null
	Field activeMusicChannel:TChannel = Null
	Field inactiveMusicChannel:TChannel = Null

	Field sfxChannel_Elevator:TChannel = Null
	Field sfxChannel_Elevator2:TChannel = Null
	Field sfxVolume:Float = 1
	Field defaulTSfxDynamicSettings:TSfxSettings = Null

	Field musicOn:Int = 1
	Field musicVolume:Float = 1
	Field nextMusicTitleVolume:Float = 1
	Field lastTitleNumber:Int = 0
	Field currentMusicStream:TMusicStream = Null
	Field nextMusicTitleStream:TMusicStream = Null

	Field currentMusic:TSound = Null
	Field nextMusicTitle:TSound = Null
	Field forceNextMusicTitle:Int = 0
	Field fadeProcess:Int = 0 '0 = nicht aktiv  1 = aktiv
	Field fadeOutVolume:Int = 1000
	Field fadeInVolume:Int = 0

	Field soundSources:TList = CreateList()
	Field receiver:TElementPosition

	Function Create:TSoundManager()
Rem
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
		manager.defaulTSfxDynamicSettings = TSfxSettings.Create()
		Return manager
	End Function
	
	Method GetDefaultReceiver:TElementPosition()
		Return receiver
	End Method

	Method SetDefaultReceiver(_receiver:TElementPosition)
		receiver = _receiver
	End Method

	Method LoadSoundFiles()
		'mv: Alternativ kÃ¶nnen die Files auch in einem seperaten Thread geladen werden oder erst bei Bedarf... dann ruckelt's leider aber etwas. Kannst du (Ronny) entscheiden ;)
		Local total:Int = 8

		Self.soundFiles = CreateMap:TMap()
		LoadProgress(1, total)
		Self.soundFiles.insert( MUSIC_TITLE, TMusicStream.Create("res/music/title.ogg", True) )
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
		Print "loaded sound files"
Rem
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
		
		LoadProgress(9, total)
		MapInsert( Self.soundFiles, SFX_STEPS, LoadSound("res/sfx/steps.ogg", SOUND_LOOP | SOUND_HARDWARE) )
		
	End Method

	Method LoadProgress(currentCount:Int, totalCount:Int)
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
			If activeMusicChannel <> Null
				If (Self.activeMusicChannel.Playing()) Then
					If (Self.forceNextMusicTitle And Self.nextMusicTitleStream <> Null) Or Self.fadeProcess > 0 Then
						'Print "Fadeover"
						FadeOverToNextTitle()
					EndIf
				Else
					Self.PlayMusic(MUSIC_MUSIC)
				EndIf
			EndIf
		EndIf
	End Method

	Method FadeOverToNextTitle()
		If (fadeProcess = 0) Then
			fadeProcess = 1
			inactiveMusicChannel = nextMusicTitleStream.GetChannel(0)
			ResumeChannel(inactiveMusicChannel)			
			Self.nextMusicTitleStream = Null

			Self.forceNextMusicTitle = False
			Self.fadeOutVolume = 1000
			Self.fadeInVolume = 0
		EndIf

		If (Self.fadeProcess = 1) Then 'Das fade out des aktiven Channels
			Self.fadeOutVolume = Self.fadeOutVolume - 15
			Self.activeMusicChannel.SetVolume(Float(Self.fadeOutVolume) / 1000 * Self.musicVolume)

			Self.fadeInVolume = Self.fadeInVolume + 15
			Self.inactiveMusicChannel.SetVolume(Float(Self.fadeInVolume) / 1000 * Self.nextMusicTitleVolume)
		EndIf

		If Self.fadeOutVolume <= 0 And Self.fadeInVolume >= 1000 Then
			Self.fadeProcess = 0 'Prozess beendet
			Self.musicVolume = Self.nextMusicTitleVolume
			SwitchMusicChannels()
		EndIf
	End Method

	Method SwitchMusicChannels()
		Local channelTemp:TChannel = Self.activeMusicChannel
		Self.activeMusicChannel = Self.inactiveMusicChannel
		Self.inactiveMusicChannel = channelTemp
		Self.inactiveMusicChannel.Stop()
	End Method

	Method PlayMusic(music:String)		
		Self.nextMusicTitleStream = GetMusicStream(music)
		Self.nextMusicTitleVolume = GetVolume(music)
		Self.forceNextMusicTitle = True
		
		'Wenn der Musik-Channel noch nicht lÃ¤uft, dann jetzt starten
		If activeMusicChannel = Null Or Not activeMusicChannel.Playing() Then
			Local musicVolume:Float = Self.nextMusicTitleVolume			
			Self.activeMusicChannel = Self.nextMusicTitleStream.GetChannel(musicVolume)
			ResumeChannel(Self.activeMusicChannel)

			Self.forceNextMusicTitle = False
		EndIf
	End Method
Rem
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
EndRem

	Method GetMusicStream:TMusicStream(music:String)
		Local result:TMusicStream

		Select music
			Case MUSIC_MUSIC
				Local nextTitleNumber:Int = Int(Rnd(1,5))
				While(nextTitleNumber = Self.lastTitleNumber)
					nextTitleNumber = Int(Rnd(1,5))
				Wend
				result = TMusicStream(MapValueForKey(Self.soundFiles, MUSIC_MUSIC + nextTitleNumber))
				Self.lastTitleNumber = nextTitleNumber
				Print "Play music: " + MUSIC_MUSIC + " (" + nextTitleNumber + ")"
			Default
				result = TMusicStream(MapValueForKey(Self.soundFiles, music))
				Print "Play music: " + MUSIC_MUSIC
		EndSelect
		Return result
	End Method

	Method GetSfx:TSound (sfx:String)
		Return TSound(MapValueForKey(Self.soundFiles, sfx))
	End Method

	Method GetVolume:Float(music:String)
		Select music
			Case MUSIC_TITLE
				Return 1
			Default
				Return 0.2
		EndSelect
	End Method

	Method GetSfxChannel:TChannel(sfx:String)
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
	Field CurrentSfx:String
	Field CurrentSettings:TSfxSettings
	Field MuteAfterCurrentSfx:Int
	
	Function Create:TSfxChannel()
		Return New TSfxChannel
	End Function
	
	Method PlaySfx(sfx:String, settings:TSfxSettings=Null)		
		CurrentSfx = sfx
		CurrentSettings = settings		
		
		AdjustSettings(False)

		Local sound:TSound = SoundManager.GetSfx(sfx)		
		PlaySound(sound, Channel)
	End Method
	
	Method IsActive:Int()
		Return Channel.Playing()
	End Method
	
	Method Stop()
		Channel.Stop()
	End Method
	
	Method Mute()
		If MuteAfterCurrentSfx And IsActive()
			AdjustSettings(True)
		Else
			Channel.SetVolume(0)
		EndIf
	End Method
	
	Method AdjustSettings(isUpdate:Int)
		If Not isUpdate			
			channel.SetVolume(SoundManager.sfxVolume * 0.75 * CurrentSettings.GetVolume()) '0.75 ist ein fixer Wert die Lautstärke der Sfx reduzieren soll
		EndIf
	End Method	
End Type

'Der dynamische SfxChannel hat die Möglichkeit abhängig von der Position von Sound-Quelle und Empfänger dynamische Modifikationen an den Einstellungen vorzunehmen. Er wird bei jedem Update aktualisiert.
Type TDynamicSfxChannel Extends TSfxChannel
	Field Source:TSoundSourceElement			
	Field Receiver:TElementPosition
	
	Function CreateDynamicSfxChannel:TSfxChannel(source:TSoundSourceElement=Null)
		Local sfxChannel:TDynamicSfxChannel = New TDynamicSfxChannel
		sfxChannel.Source = source		
		Return sfxChannel
	End Function	
	
	Method SetReceiver(_receiver:TElementPosition)
		Self.Receiver = _receiver
	End Method
	
	Method AdjustSettings(isUpdate:Int)
		Local sourcePoint:TPoint = Source.GetCenter()
		Local receiverPoint:TPoint = Receiver.GetCenter() 'Meistens die Position der Spielfigur		
	
		If CurrentSettings.forceVolume
			channel.SetVolume(CurrentSettings.defaultVolume)
			'print "Volume:" + CurrentSettings.defaultVolume
		Else
			'Lautstärke ist Abhängig von der Entfernung zur Geräuschquelle
			Local distanceVolume:Float = CurrentSettings.GetVolumeByDistance(Source, Receiver)		
			channel.SetVolume(SoundManager.sfxVolume * distanceVolume) ''0.75 ist ein fixer Wert die Lautstärke der Sfx reduzieren soll
			'print "Volume: " + (SoundManager.sfxVolume * distanceVolume)
		EndIf
		
		If (sourcePoint.z = 0) Then
			'170 Grenzwert = Erst aber dem Abstand von 170 (gefühlt/geschätzt) hört man nur noch von einer Seite.
			'Ergebnis sollte ungefähr zwischen -1 (links) und +1 (rechts) liegen.
			If CurrentSettings.forcePan
				channel.SetPan(CurrentSettings.defaultPan)
			Else
				channel.SetPan(Float(sourcePoint.x - receiverPoint.x) / 170)
			EndIf
			channel.SetDepth(0) 'Die Tiefe spielt keine Rolle, da elementPoint.z = 0
		Else		
			Local zDistance:Float = TPoint.DistanceOfValues(sourcePoint.z, receiverPoint.z)
		
			If CurrentSettings.forcePan
				channel.SetPan(CurrentSettings.defaultPan)
				'print "Pan:" + CurrentSettings.defaultPan
			Else					
				Local xDistance:Float = TPoint.DistanceOfValues(sourcePoint.x, receiverPoint.x)
				Local yDistance:Float = TPoint.DistanceOfValues(sourcePoint.y, receiverPoint.y)
				
				Local angleZX:Float = ATan(zDistance / xDistance) 'Winkelfunktion: Welchen Winkel hat der Hörer zur Soundquelle. 90° = davor/dahiner    0° = gleiche Ebene	tan(alpha) = Gegenkathete / Ankathete
	
				Local rawPan:Float = ((90 - angleZX) / 90)			
				Local panCorrection:Float = Max(0, Min(1, xDistance / 170)) 'Den r/l Effekt sollte noch etwas abgeschwächt werden, wenn die Quelle nah ist
				Local correctPan:Float = rawPan * panCorrection
	
				'0° => Aus einer Richtung  /  90° => aus beiden Richtungen
				If (sourcePoint.x < receiverPoint.x) Then 'von links
					channel.SetPan(-correctPan)
					'print "Pan:" + (-correctPan) + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				ElseIf (sourcePoint.x > receiverPoint.x) Then 'von rechts
					channel.SetPan(correctPan)
					'print "Pan:" + correctPan + " - angleZX: " + angleZX + " (" + xDistance + "/" + zDistance + ")    # " + rawPan + " / " + panCorrection
				Else
					channel.SetPan(0)
				EndIf
			EndIf
			
			If CurrentSettings.forceDepth
				channel.SetDepth(CurrentSettings.defaultDepth)
				'print "Depth:" + CurrentSettings.defaultDepth
			Else			
				Local angleOfDepth:Float = ATan(receiverPoint.DistanceTo(sourcePoint, False) / zDistance) '0 = direkt hinter mir/vor mir, 90° = über/unter/neben mir
	
				If sourcePoint.z < 0 Then 'Hintergrund
					channel.SetDepth(-((90 - angleOfDepth) / 90)) 'Minuswert = Hintergrund / Pluswert = Vordergrund
					'print "Depth:" + (-((90 - angleOfDepth) / 90)) + " - angle: " + angleOfDepth + " (" + receiverPoint.DistanceTo(sourcePoint, false) + "/" + zDistance + ")"
				ElseIf sourcePoint.z > 0 Then 'Vordergrund
					channel.SetDepth((90 - angleOfDepth) / 90) 'Minuswert = Hintergrund / Pluswert = Vordergrund
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
	
	Method GetVolumeByDistance:Float(source:TSoundSourceElement, receiver:TElementPosition)
		Local currentDistance:Int = source.GetCenter().DistanceTo(receiver.getCenter())
	
		Local result:Float = midRangeVolume
		If (currentDistance <> -1) Then
			If currentDistance > Self.maxDistanceRange Then 'zu weit weg
				result = Self.minVolume
			ElseIf currentDistance < Self.nearbyDistanceRange Then 'sehr nah dran
				result = Self.nearbyRangeVolume
			Else 'irgendwo dazwischen
				result = midRangeVolume * (Float(Self.maxDistanceRange) - Float(currentDistance)) / Float(Self.maxDistanceRange)
			EndIf
		EndIf

		Return result
	End Method	
End Type

'Das ElementPositionzeug kann auch eventuell wo anders hin
Type TElementPosition 'Basisklasse für verschiedene Wrapper
	Method GetID:String() Abstract
	Method GetCenter:TPoint() Abstract
	Method IsMovable:Int() Abstract
End Type


Type TSoundSourceElement Extends TElementPosition
	Field SfxChannels:TMap = CreateMap()
		
	Method GetIsHearable:Int() Abstract
	Method GetChannelForSfx:TSfxChannel(sfx:String) Abstract
	Method GetSfxSettings:TSfxSettings(sfx:String) Abstract	
	Method OnPlaySfx:Int(sfx:String) Abstract
	
	Method GetReceiver:TElementPosition()
		Return SoundManager.GetDefaultReceiver()
	End Method
	
	Method PlaySfx(sfx:String, sfxSettings:TSfxSettings=Null)
		If Not GetIsHearable() Then Return
		If Not OnPlaySfx(sfx) Then Return
		'print GetID() + " # PlaySfx: " + sfx
		
		SoundManager.RegisterSoundSource(Self)
		
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		Local settings:TSfxSettings = sfxSettings
		If settings = Null Then settings = GetSfxSettings(sfx)
		
		If TDynamicSfxChannel(channel)
			TDynamicSfxChannel(channel).SetReceiver(GetReceiver())
		EndIf
		
		channel.PlaySfx(sfx, settings)
		'print GetID() + " # End PlaySfx: " + sfx
	End Method
	
	Method PlayOrContinueSfx(sfx:String, sfxSettings:TSfxSettings=Null)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		If Not channel.IsActive()
			'Print "PlayOrContinueSfx: start"
			PlaySfx(sfx, sfxSettings)
		Else
			'Print "PlayOrContinueSfx: Continue"
		EndIf
	End Method	
	
	Method Stop(sfx:String)
		Local channel:TSfxChannel = GetChannelForSfx(sfx)
		channel.Stop()
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

	Method AddDynamicSfxChannel(name:String, muteAfterSfx:Int=False)
		Local sfxChannel:TSfxChannel = TDynamicSfxChannel.CreateDynamicSfxChannel(Self)
		sfxChannel.MuteAfterCurrentSfx = muteAfterSfx	
		SfxChannels.insert(name, sfxChannel)
	End Method	

	Method GetSfxChannelByName:TSfxChannel(name:String)
		Return TSfxChannel(MapValueForKey(SfxChannels, name))	
	End Method
End Type