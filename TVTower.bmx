SuperStrict

'Application: TVGigant/TVTower
'Author: Ronny Otto

' creates version.txt and puts date in it
' @bmk include source/version_script.bmk
' @bmk doVersion source/version.txt
'

Framework brl.glmax2d
?Win32
'	Import "tvtower_icon.o"
?
Import pub.freeaudio 'fuer rtaudio
Import "source/main.bmx"

Incbin "source/version.txt"


?Win32
rem
	Function SetIcon(iconname$, TheWindow%)
		Local icon:Int=ExtractIconA(TheWindow,iconname,0)
		Local WM_SETICON:Int = $80
		Local ICON_SMALL:Int = 0
		Local ICON_BIG:Int = 1
		sendmessage(TheWindow, WM_SETICON, ICON_BIG, icon)
	End Function

	Extern "win32"
		Function ExtractIconA%(hWnd%,File$z,Index%)
		Function GetActiveWindow%()
		Function SendMessage:Int(hWnd:Int,MSG:Int,wParam:Int,lParam:Int) = "SendMessageA@16"
	End Extern

	SetIcon(AppFile, GetActiveWindow())
endrem
?




Rem
DONE
- TGame.Update() ueberarbeitet:
  - Hilfsfunktionen wie GetMinute() / GetHour() /... liefern nun auch dann korrekte Ergebnisse, wenn sie innerhalb der "uebersprungene Spielminuten"-Schleife aufgerufen werden. Direkt getriggerte (also sofort ausgefuehrten) Events koennten nun auf die Zeitparameter verzichten.
- TGame: durch Update()-Ueberarbeitung nicht laenger benoetigte Variablen entfernt
- TDevHelper: SetPrintMode() / SetLogMode() ueberschreiben nun den Modus, ChangePrintMode() und ChangeLogMode() dienen jetzt dazu, Modis an- oder auszuschalten
- nicht verwendete Dateien entfernt: Pfeilgrafiken fuer Datenblaetter und ein paar Erinnerungsdateien ("wo wird was platziert")

Todo
----
- RoomSigns ueberarbeiten (dynamisch aus Raeumen auslesen statt eigener Liste)
  dann dies per Getter machen um Neuerzeugung zu ermoeglichen
- Tooltip am Mauscursor - "Programm vom Plan entfernen", "Hier fallen lassen um zu löschen" ..
- Abnutzung anhand der erreichten Zuschauer-Prozente berechnen "Potenzial"
- Werbehaendler: 2 "Billigwerbungen" die nur ab und an "erneuert" werden,
  wenn leer, dann leer  - ist das sinnvoll? Derzeit ist Billigwerbung
  "immer vorhanden"
- Werbung:
  - Imageverlust moeglich
  - Zeitrahmen
  - FSK18


* Schauspieler + Regisseur-Datenbank
  - Anhand der "fruehsten" und "spaetesten" Filme kann eine
    Aktivitaetenzeit festgelegt werden (ausserhalb waere Spekulation - unschoen
    wenn bspweise jemand gestorben ist)
  - News koennen ueber die Person innerhalb der Aktivitaetenzeit geschrieben
    werden
  - ACHTUNG: nicht immer moeglich, es erscheinen Filme manchmal NACH dem Tod
    eines Menschen (John Candy, Paul Walker) ... wie diese behandeln?
-> bei fiktiven Personen: Eignung als Newssprecher, Moderatoren, Darsteller, ...

* XML-Dateien: Animationskonfiguration
	- TAsset -> global "currentDeltaTime"
	- TAsset -> global "updateList" haelt Assets die in einer Update-Runde aktualisiert werden muessen
	- TAsset -> Sprites mit Animationskonfiguration setzen sich in diese "updateList"
	- TAsset -> TAsset.UpdateAll() ruft die Updates auf (currentDeltaTime -> animationen etc)

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
