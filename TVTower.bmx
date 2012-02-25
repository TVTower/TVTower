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
- bufferedopengl
. - Batchrendering (gleiche "Texturen" ersparen glbegin/glend)
. - bufferedopngl - GrabPixmap gefixt (+ Koordinatenfix)
. - eigene LoadTrueTypeFont-Funktion - fixt Bug mit TImageFont.load unter bufferedGL
. -> FPS: Hochhaus von 130 auf 240 fps, supermarkt von 270 auf 430fps
- basefunctions_image  - drawPixmapOnPixmap - Alpha vom Ziel mit beachten
- basefunctions_sprites - enthaelt nun basefunctions_text
. - Truetype-Schriften nun auf eine Imagemap geladen statt pro Glyphe ein Bild - Vorteil fuer BufferedGL
. - Eigene Schriftfunktionen TBitmapFont.draw ... (BitmapFont wird aus TTF generiert...)

' 2012:
' gamefunctions - tstation - farben der ovale anpassen auf tplayercolor

EndRem
