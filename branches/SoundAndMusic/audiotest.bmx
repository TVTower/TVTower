Import maxmod2.ogg
Import maxmod2.rtaudio
?Linux
TMaxModRtAudioDriver.Init("LINUX_PULSE")
?not Linux
TMaxModRtAudioDriver.Init()
?

if not SetAudioDriver("MaxMod RtAudio") then throw "Audio Failed"
'for local str:string = eachin TMaxModRtAudioDriver.Active.APIs.Values()
'	print "maxmod api:"+str
'Next

Graphics 640,480


'type to store music files (ogg) in it
'data is stored in bank
'Play-Method is adopted from maxmod2.bmx-Function "play"
Type TMusicStream
	field bank:TBank
	field url:object

	Function Create:TMusicStream(url:object)
		local obj:TMusicStream = new TMusicStream
		obj.bank = LoadBank(url)
		obj.url = url
		return obj
	End Function

	Method Play:TChannel(sendToChannel:Tchannel var, loop:int=false )
		sendToChannel = CueMusic(self.bank, loop)
		If Not sendToChannel then Return Null
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

local music:TMusicStream = TMusicStream.Create("res/music/music1.ogg")
While Not KeyHit( KEY_ESCAPE )

	If KeyHit( KEY_SPACE )
		print Millisecs()+ " playing"
		nchan=(nchan+1) & 3
		If chans[nchan]
			StopChannel chans[nchan]
			print "stopping "+nchan
		endif
		chans[nchan]=AllocChannel()
		music.Play(chans[nchan])
'		PlaySound sound,chans[nchan]
	EndIf

	Flip

Wend