SuperStrict

'Application: TVGigant/TVTower
'Author: Ronny Otto

' creates version.txt and puts date in it
' @bmk include source/version_script.bmk
' @bmk doVersion source/version.txt
'

Framework brl.glmax2d
Import pub.freeaudio 'fuer rtaudio
Import "source/main.bmx"

Incbin "source/version.txt"

REM
* SaveLoad als Events "Movie.onLoad"


* Räume als besetzt markieren (damit KI keine Filme kauft waehrend ich beim Haendler steh :D)
* XML-Dateien: Animationskonfiguration
		- TAsset -> global "currentDeltaTime"
	- TAsset -> global "updateList" haelt Assets die in einer Update-Runde aktualisiert werden muessen
	- TAsset -> Sprites mit Animationskonfiguration setzen sich in diese "updateList"
	- TAsset -> TAsset.UpdateAll() ruft die Updates auf (currentDeltaTime -> animationen etc)

* "TImageCache" in TBitmapFont-Rendering einbinden
* "impact"-feld bei filmen (refresh rate)
* Fensterverschiebung in Windows stoppt Programmablauf bis loslassen
	- DirectX -> eigene WindowDeco - stylen
	- OpenGL ... - WindowDeco nicht stylebar

* Filmauktionen:
	- Filminformationen anzeigen
* Live-Events:
	- Fussball, Formel1, Konzerte, ... fehlen noch
* Quiz/Call-In
	- Werbung: Werbebloecke die prozentual von der Zuschauerzahl
	  Einkuenfte erzielen
* Eigenproduktionen:
	- Filme - die auch bspweise in den Wiederverkauf
	  gelangen koennen. Hier sollte evtl der "Kino"-Wert
	  erst nach der Erstausstrahlung definiert werden
EndRem
