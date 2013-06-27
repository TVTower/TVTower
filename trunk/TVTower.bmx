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
* Schauspieler + Regisseur-Datenbank
  - Anhand der "fruehsten" und "spaetesten" Filme kann eine
    Aktivitaetenzeit festgelegt werden (ausserhalb waere Spekulation - unschoen
    wenn bspweise jemand gestorben ist)
  - News koennen ueber die Person innerhalb der Aktivitaetenzeit geschrieben
    werden
  - News koennten auch Filme "ankuendigen" (1 Jahr vor Produktionszeit) oder
    es koennte Nachrichten geben à la "Schauspieler XY" verpflichtet

* SaveLoad als Events "Movie.onLoad"

* Räume als besetzt markieren (damit KI keine Filme kauft waehrend ich beim Haendler steh :D)
    - Innenraeume checken? (Auktionsraum bei Filmhaendler)
* XML-Dateien: Animationskonfiguration
	- TAsset -> global "currentDeltaTime"
	- TAsset -> global "updateList" haelt Assets die in einer Update-Runde aktualisiert werden muessen
	- TAsset -> Sprites mit Animationskonfiguration setzen sich in diese "updateList"
	- TAsset -> TAsset.UpdateAll() ruft die Updates auf (currentDeltaTime -> animationen etc)

* "TImageCache" in TBitmapFont-Rendering einbinden
* Fensterverschiebung in Windows stoppt Programmablauf bis loslassen
	- DirectX -> eigene WindowDeco - stylen
	- OpenGL ... - WindowDeco nicht stylebar
* Live-Events:
	- Fussball, Formel1, Konzerte, ... fehlen noch
* Eigenproduktionen:
	- Filme - die auch bspweise in den Wiederverkauf
	  gelangen koennen. Hier sollte evtl der "Kino"-Wert
	  erst nach der Erstausstrahlung definiert werden
EndRem
