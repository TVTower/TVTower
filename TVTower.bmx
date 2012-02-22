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

'done
rem

- Koffer-Grafiken zu einer Grafik zusammengefuehrt, per XML und von
  Koffer-Timage auf Asset umgestellt
- Filmverleiher-Grafiken in eine Grafik gepackt und per XML geladen
- TGW_SpritePack.colorizeSprite(spritename, r,g,b) hinzugefuegt
- TGW_Sprites.colorize(r,g,b) hinzugefuegt (referenziert SpritePack)
- gfx.xml - laedt nun auch Filmverleiher-Filmhuellen und faerbt diese ein
- OnMinuteEventListener hoert nun auf OnMinute (und aktualisiert Zuschauerzahlen)

endrem

' 2012:
' gamefunctions - tstation - farben der ovale anpassen auf tplayercolor
