Import maxmod2.ogg
Import maxmod2.rtaudio
Import MaxMod2.WAV
Import brl.max2d

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
'MaxModVerbose True

SetGraphicsDriver GLMax2DDriver()
Graphics 640,480
Print "graphics ...done"

'type to store music files (ogg) in it
'data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TMusicStream
	Field bank:TBank
	Field url:Object

	Function Create:TMusicStream(url:Object)
		Local obj:TMusicStream = New TMusicStream
		obj.bank = LoadBank(url)
		obj.url = url
		If obj Then Print "loaded object" Else Print "error loading obj"
		Return obj
	End Function

	Method Play:TChannel(sendToChannel:TChannel Var, loop:Int=False )
		sendToChannel = CueMusic(Self.bank, loop)
		If Not sendToChannel Then Return Null
		ResumeChannel(sendToChannel)
		Return sendToChannel
	End Method
End Type

For Local i=1 To 256
	Local chan:TChannel=AllocChannel()
	'PlaySound sound,chan   'also fixes problem!
	StopChannel chan
Next

Local chans:TChannel[4],nchan

Local music:TMusicStream = TMusicStream.Create("res/music/music1.ogg")
While Not KeyHit( KEY_ESCAPE )

	If KeyHit( KEY_SPACE )
		Print MilliSecs()+ " playing"
		nchan=(nchan+1) & 3
		If chans[nchan]
			StopChannel chans[nchan]
			Print "stopping "+nchan
		EndIf
		chans[nchan]=AllocChannel()
		music.Play(chans[nchan])
'		PlaySound sound,chans[nchan]
	EndIf

	Flip

Wend