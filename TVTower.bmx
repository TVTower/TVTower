SuperStrict

'Application: TVGigant/TVTower
'Author: Ronny Otto

' creates version.txt and puts date in it
' @bmk include source/version_script.bmk
' @bmk doVersion source/version.txt
'

Framework brl.glmax2d
Import "source/main.bmx"

Incbin "source/version.txt"

' "TImageCache" in TBitmapFont-Rendering einbinden

' ressourcenlader - plugins (registerLoader) -> Stationmap mit details auslagern etc.








Rem
- todo :
	* "impact"-feld bei filmen (refresh rate)

	* TPlayerColor-creation in XML auslagern ...
	* Fensterverschiebung in Windows stoppt Programmablauf bis loslassen
		- DirectX -> eigene WindowDeco - stylen
		- OpenGL ... - WindowDeco nicht stylebar

' 2012:
' gamefunctions - tstation - farben der ovale anpassen auf tplayercolor
Filmauktionen:
	Filminformationen anzeigen

Live-Events:
	(Fussball, Formel1, Konzerte, ...) fehlen noch

Quiz/Call-In
	- Werbung: Werbebloecke die prozentual von der Zuschauerzahl
	  Einkuenfte erzielen


Eigenproduktionen:
	Filme - die auch bspweise in den Wiederverkauf
	gelangen koennen. Hier sollte evtl der "Kino"-Wert
	erst nach der Erstausstrahlung definiert werden


EndRem
