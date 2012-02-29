SuperStrict

'Application: TVGigant/TVTower
'Author: Ronny Otto

' creates version.txt and puts date in it
' @bmk include source/version_script.bmk
' @bmk doVersion source/version.txt
'

Framework brl.glmax2d
'Import axe.luascript
Import "source/main.bmx"

Incbin "source/version.txt"
Rem
'done
- gfx_building_skyscraper-TBigImage mit TGW_Sprites("gfx_building") ersetzt
- falschen Tuerensprite-Bezeichner beim Abruf genutzt
- TBitmapFont.draw() und getHeight/getWidth akzeptieren Multiline-Text (mit chr(13))
- TBitmapFont.draw gibt nun TPosition (X/Y-Pair) zurueck (bzw stringobject von x oder y	)
- TBitmapFont.drawBlock - Blocksatz fuer Texte :D
- TProgrammeBlock-Zeichenfunktion aufgeräumt
- TGW_Sprites.drawClipped() , -1 Werte fuer W/H = automatisch
- TColor (Tripel + Set/Get)
- basefunctions.xml - StringSplit entfernt (gibt es in Blitzmax als string.split(delim))
' 2012:

' gamefunctions_tvprogramme - basisklassen zusammenfassen
' gamefunctions - tstation - farben der ovale anpassen auf tplayercolor
Filmauktionen:
	Filminformationen anzeigen

Live-Events:
	(Fussball, Formel1, Konzerte, ...) fehlen noch

Quiz/Call-In
	- Werbung: Werbebloecke die prozentual von der Zuschauerzahl
	  Einkuenfte erzielen
	- Sendungen: Komplette Stundensendungen die geringe Einnahmen
	  erzielen


Eigenproduktionen:
	Filme - die auch bspweise in den Wiederverkauf
	gelangen koennen. Hier sollte evtl der "Kino"-Wert
	erst nach der Erstausstrahlung definiert werden


EndRem
