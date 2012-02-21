'''''''TODO
''''''' -Aehnlich der Ueberlappungsberechnung der Sendemasten, dass ganze noch so umsetzen, dass Differenz
'''''''  aus MaxAudience und MaxAudience - Ueberlappung mit Spieler 2/Spieler3 usw. abgezogen wird... dadurch
'''''''  die Mischberechnung ermoeglichen (bei Sendemast 3 koennen 34% auch Sender2 empfangen und "nicht gucken")
''''''' -Sendegewohnheiten (Serien): Stammpublikum bzw. Stammsendeplatz (Durchschnitt bisheriger Plaetze)

Import brl.basic

Global VersionDate:string = LoadText("incbin::source/version.txt")
Global versionstring:String = "version of " + VersionDate
'Global versionstring:String = "version of 2011/12/27 19:00" + VersionDate
Global copyrightstring:String = "by Ronny Otto, gamezworld.de"
AppTitle = "TVTower - " + versionstring + " " + copyrightstring

rem
15.02.11
- gamefunctions_tvprogramme.bmx - tdatabase.load nutzt nun Parameter statt konstanten Wert
- lua -> res/ai/*
- ttf -> res/fonts/*
- database -> res/*
- settings -> config/*
endrem


'08.10.2011 Ronny
'' -CHG:	weitere files.bmx in XML-Auslagerungen

'27.12.2010 Ronny
'' -CHG:	Raumfader in eigene Klasse ausgelagert
'' -CHG:	XML-Klasse: Tabs bei Attributzeilen fuehrten zu nicht erkannten Attributen
''			<script[TAB]do="ColorizeCopy"	dest="stationmap_antenna1" />
'04.12.2010 Ronny
'' -FIX:	LUA funktioniert wieder, nun koennen komplette Typen/Objekte an Lua
''			weitergereicht werden, eventuell sind getter setter nun verzichtbar
'' -CHG:	Interface - Texte von Schatten auf "emboss" umgestaltet
'' -CHG:	TTooltip - Grafischer Header statt einfarbigem Rechteck
'' -NEW:	XmlLoader - Konfiguration (Bilder, Spritepacks...) durch externe XML-Dateien
''			Spritepacks: script: "CopySprite", einfaerb-Kopiervorgang von Sprites auf Pixmap
''			des Spritepacks
'' -CHG:	gui_rect, neues Design
'' -FIX:	Spielfiguren, einige waren mit 255,255,255 weiss, was nicht eingefaerbt wird, gestaltet
'' -CHG:	Zusammenlegung von CheckLoadAnimImage und CheckLoadImage
'' -CHG:	Aufraeumarbeiten im Threaded-Loading / Ladebildschirm

'26.04.2008 Ronny
''- FIX:	Bloecke wie Programme, Filmhaendler, Werbung hatten teilweise genullte TPosition-Felder, diese
''			werden nun schon als Defaultwerte erstellt, die MemException muesste verschwunden sein.
'24.04.2008 Ronny
''- NEW:	Lua: OnSave und OnLoad als neue Events. OnLoad uebergibt String, OnSave erwartet String als Rueckgabe
'04.04.2008 Ronny
''- FIX:	Lua: LUA_getPlayerMaxAudience() war nicht per Lua-Scripts erreichbar (fehlende Funktionsverknuepfung)
'21.03.2008 Ronny
''- FIX:	KI-Spieler die Raeume verlassen haben wurden nicht korrekt auf inRoom-Objekt geprueft, dadurch
''			kam es zu Problemen mit dem Event, dass ein KI-Spieler den Filmhaendler verlassen hat (Programmkauf)
'18.03.2008 Ronny
''- NEW:	Lua:		MovieAgency→md_getMovieCount	MovieAgency→md_getMovie
''						MovieAgency→md_doBuyMovie
''						AdAgency→sa_getSpotCount		AdAgency→sa_getSpot
'29.01.2008 Ronny
''- FIX:	Die Pos.y vom Fahrstuhl wird bei Bewegung nun per Min(Abstand zum ZielY, Geschwindigkeits dY)
''			gesetzt. Dies sollte eventuelles "Vorbeifahren" an der Zieletage (bei Rucklern) eleminieren.
'26.01.2008 Ronny
''- NEW:	Lua:		Office→of_getSpotBeenSent		Office→of_getSpotWillBeSent
''						Office→of_getPlayerSpotCount	Office→of_getSpotDaysLeft
''						Office→of_doSpotInPlan			Office→of_getPlayerSpot
'21.01.2008 Ronny
''- CHG:	Fahrstuhl fährt und öffnet/schließt schneller, wartet weniger Zeit bis er losfährt
''- FIX:	"Tueren tauchten mitten im Hochhaus auf" - TRooms.DrawDoors hatte einen Parameterdreher
''- NEW:	Methode: TGW_SpritePack.CopySprite(spriteNameSrc, spriteNameDest, colR,colG,colB), kopiert
''			ein eingefärbtes Sprite des Spritepacks auf die Stelle eines anderen Sprites
''- CHG:	weitere Aufräumarbeiten im Quellcode
'20.01.2008 Ronny
''- FIX: Eingabefelder (Chat, Input) arbeiten nun korrekt, keine doppelten Buchstabeneingaben mehr
''- CHG: Dateistruktur (includes und imports) geaendert, GUIelements ist nun import statt include
''- CHG: Viele Codezeilen umstrukturiert, X,Y-Paare sind nun gekapselt in TPosition mit entsprechenden
''       Hilfsfunktionen (SetPos, SetXY, SetX, SetY, SwitchPos...)
'29.12.2007 Ronny
''- FIX: Elevator.AddFloorRoute hat faelschlicherweise beim "senden" des Fahrstuhles den nachfolgenden
''       "Fahrstuhlruf" gelöscht ("vergessene Passagiere"-Bug)
'28.12.2007 Ronny
''- FIX: Fehler in Game.Update() behoben (zu Spielbeginn wurde nicht OnDayBegins für KI aufgerufen)
''- FIX: TGW_Sprites.DrawClipped() war fehlerhaft, Problem behoben
''- CHG: GUI-Elemente auf Status von YourDoku (anderes Spiel) aktualisiert und für TGW_SpritePack angepasst
'13.12.2007 Ronny
''- FIX: Fehler in LUA_DoGoToRoom behoben (fehlerhafte Berechnung in Figures.SendToRoom(roomid))
''- NEW: LUA_GetMillisecs - liefert Millisekunden seit Rechnerstart
'02.12.2007 Ronny
''- NEW: LUA_getEvaluatedAudienceQuote  - ermöglicht "Ranking" von Filmen entsprechend potentieller Einschaltquote
''- NEW: LUA Konstanten: MaxMovies, MaxMoviesParGenre, MaxSpots
''- CHG: LUA Funktion "DoGoto" wurde zu "DoGoToRoom"
'01.12.2007 Ronny
''- NEW: LUA_onChat - im Spiel mit KI sprechen: "/Spielernummer Befehl"
''- FIX: Raumplaner funktionierte nicht (CreateTooltips() fehlerhaft), neue Methode: TBlocks.SetBaseCoords()
'30.11.2007 Ronny
''- NEW: LUA_doGoto
''- FIX: LUA_SetPlayerPosX
'29.11.2007 Ronny
''- NEW: TProgrammePlan.ProgrammePlaceable(programme,time,day) - gibt zurueck ob genuegend Platz vorhanden ist
''       um das Programm einsetzen zu koennen (ansonsten muss vom Spieler/von KI der Platz geschaffen werden)
''- NEW: LUA_of_doMovieInPlan, LUA_of_GetMovie, LUA_of_GetSpot
''- NEW: LUA_getPlayerCredit, LUA_getPlayerMaxAudience, LUA_getPlayerAudience
''- CHG: Spielfigur 3 nutzt testweise "test_base.lua" als KI-Script
'28.11.2007 Ronny
''- NEW: KI-Scripte koennen nun auf fast alle Helperfunktionen (siehe Lua_Doku.pdf) zugreifen
''- NEW: KI-Scripte koennen Spielfigurinformationen (Raum, X,Y,...) abrufen
'27.11.2007 Ronny
''- NEW: KI-Spieler werden ueber den Beginn eines neuen Tages informiert: CallOnDayBegins()
''- NEW: KI-Spieler werden ueber Raum "betreten" und "verlassen" informiert: CallOnLeaveRoom(), CallOnReachRoom(roomId)
''- NEW: KI-Spieler werden nun ueber Geldaenderungen informiert: CallOnMoneyChanged()
''- CHG: Bei der Rauminitialisierung werden die Spielernamen/Kanaele weggelassen und erst bei Bedarf erstellt,
''       dadurch kann LUA die Raumkonstanten uebernehmen
''- CHG: Lua: Raumkonstanten werden an KI komplett uebergeben (ROOM_OFFICE_PLAYER1 usw.)
''- CHG: Lua Doku ueberarbeitet
''- CHG: Chathintergruende (Ingame) nun Hell fuer Nicknames und Dunkel fuer Chattext
'26.11.2007 Ronny
''- NEW: Betty begruesst den Spieler freundlich ;D
''- NEW: Im Raum von Betty werden nun Spieler-"Bilder" angezeigt (Bilderrahmengrafik entsprechend angepasst)
'25.11.2007 Ronny
''- CHG: Functions.BlockText akzeptiert nun auch Zeilenumbrüche (Chr(13)), Doppelumbrüche benötigen Chr(13)+" "+Chr(13)
''- NEW: Functions.DrawDialog() - zeichnet Dialog-Rahmen mit Text
'24.11.2007 Ronny
''- NEW: Grafiken fuer Dialoge (von verschiedenen Richtungen ausgehend)
'23.11.2007 Ronny
''- FIX: Die Funktion "DrawOnPixmap" sowie die Farb-Funktionen "ARGB_RED/GREEN/BLUE" waren fehlerhaft. Nun ist
''       der Fehler behoben und es kann nun auch korrekt auf Pixmaps mit Alphakanal gezeichnet werden.
'22.11.2007 Ronny
''- NEW: Neue Supermarktgrafik /Bettygeschenk "Ring"
''- CHG: Alle Raumgrafiken werden nun nicht mehr separat in den Grafikspeicher geladen sondern ueberschreiben einen
''       von allen Raeumen geteilten Bereich: ActiveBackground:TBigImage. VidRam zum Start nun bei 15MB.
''- CHG: Die Hintergrundgrafik des Ladebildschirms ist nun vom Typ TBigImage (2 MB Video-RAM gespart)
'20.11.2007 Ronny
''- NEW: Logo scrollt weich am Startbildschirm zur Zielposition
''- NEW: Raumbilder werden am Startbildschirm wechselnd ein- und ausgefaded (um das Bild auszufuellen)
''- CHG: Die Geschwindigkeit des Fahrstuhls von Int auf Float umgestellt um leichtes Ruckeln beim Scrolling zu verhindern
''- CHG: Die X-Koordinate von Figuren wird leicht gerundet um Flimmern an Fraktalkoordinaten zu verhindern
''- NEW: Globale Boolean "FrameLimit" schaltet FrameLimit (momentan 30FPS) an und aktiviert Delay(1) um CPU zu sparen
'18.11.2007 Ronny
''- NEW: FontManager... fehlt eine Schrift (dynamisches Laden), wird sie nachgeladen
'11.11.2007 Ronny
''- CHG: Logo faded waehrend der Ladezeit ein
''- CHG: Logo ueberarbeitet (auf 512x256 fokussiert, spart die Haelfte an Grafikram des alten Logos)
''- CHG: GUI-Objekte nutzen nun TGW_Spritepack
''- CHG: Rect (rundes "blaues" Rechteck) nutzt Spritepack
''- NEW: TGW_Sprites.TileDraw(x,y,w,h) - Zeichnet Sprite in vorgegebene Fläche (Floodfill)
'10.11.2007 Ronny
''- CHG: DX9-Modus deaktiviert, da er in der BlitzMax Version 1.26 noch Inkompatibilitäten zu "Reflection" aufweist
'09.11.2007 Ronny
''- FIX: TTooltips: Interface-Tooltips (und alle anderen Nicht-Raum-Tooltips) wurden immer wieder erneuert, was
''       vorallem im DX9-Modus mit konstant sinkenden FPS-Raten quittiert wurde
''- CHG: TTooltips benoetigen keinen "own"-Parameter mehr
''- CHG: DX9-Modus wieder eingebaut. Er profitiert momentan noch nicht von Render-To-Texture (wie DX7 und OGL)
''       Hierfuer die DrawImageToArea-Funktion umgeschrieben. TObjectList scheint Probleme mit DX9 in Kombination
''       mit Reflection zu haben
'08.11.2007 Ronny
''- CHG: Sprites der Hochhausanzeige (Häuser, Türen, Pflanzen ...) zusammengefasst
''- CHG: Bundeslaender (für Kollisionscheck im Sendemastplaner) werden nun aus OfficePack geladen.
''       -> zu ladende Dateien auf 103 reduziert)
'07.11.2007 Ronny
''- CHG: Zu ladende Bilder von 135 auf 119 reduziert (GrafikRam um 4MB verringert)
''- CHG: Alle Figuren (außer Hausmeister) in ein Bild gesetzt und TFigures auf TGW_Sprites umgesetzt.
''       Hierdurch werden beim Zeichnen der Figuren Textur-Switches vermieden und Grafik-RAM gespart.
''- CHG: ChangeTarget-Berechnungen vereinfacht
'01.11.2007 Ronny
''- CHG: Weitere Sprites zusammengefasst
'26.10.2007 Ronny
''- CHG: Einige Sprites/TImages im Programmplaner wurden zusammengefasst (da intern das Genre-Bild eh mit
''       256x512 Pixeln im Speicher lag) ... erspart einige KB an Ram und brachte 10FPS (~480 auf ~490) mehr
''       im Programmplaner.
''- CHG: TPPButtons und TButtons umgeschrieben um auch mit TGW_Sprites klarzukommen
''- NEW: DrawOnPixmap() hat nun zwei neue Parameter: alpha (1.0 = volle Deckkraft) und light (0.5=halbierte
'' 		 Helligkeit) des zu aufzuzeichnenden TImages
''- CHG: Die Blockhintergründe im Programmplaner fallen weg, Normale Programmblöcke ersetzen sie (abgedunkelt und
''       geringe Deckkraft). Gleiches gilt für abgearbeitete Blöcke mit Sendeausfall
''- NEW: Neue Typen: TGW_Sprites und TGW_Spritepack - Bilder gleicher Art in einer Textur gespeichert (mit Angabe
''       der Koordinaten und Dimensionen) - Einsparungen beim Videospeicher möglich (auch wenn noch in geringem
''       Ausmaß). Erstes Spritepack: Audience (Opa, Kind und Teenie)
''- CHG: Zusammenlegung einiger Sprites (interface links und rechts bspweise)
'24.10.2007 Ronny
''- CHG: Weitere Versuche mit Render-To-Texture-Varianten ... Bottom-Interface wird nun bei Aenderung neugezeichnet,
''       ansonsten wird nur ein Composite-Bild gezeichnet (von ~460fps auf 480fps im Hochhaus)
''- CHG: Zusammenfassung einiger Bilder zu einem (loadingbar, newsbuttons) und dynamisch erstellte (Newsticker-
''		 Hintergruende) um wieder etwas RAM zu sparen
'22.10.2007 Ronny
''- FIX: GetRandomMovie/Serie/Programme setzten auch bei NULL-Rückgabe den Besitzer des letzten Objektes
''- CHG: bei TProgramme unnötige lokale Variablen entfernt, das Feld "maxepisodes" wurde gestrichen (bereits von
''       episodeCount zur Verfügung gestellt)
''- CHG: bis heute - Objekte TStationMap/TStations, TAudienceQuotes, TProgramme auf XML-Speicherung umgesetzt
'05.10.2007 Ronny
''- CHG: Beginn der Umstellung auf XML-Speicherstände - TGame, TFigures, TPlayer
''- CHG: Die Zip-Komponente musste geändert werden, da keine Dekomprimierung im Speicher möglich war (vorher
''       Auslagerung auf Festplatte, die wiederum zu Fehlern (nur 0Bytes-Zeichen in der Datei) führen konnte).
'25.09.2007 Ronny
''- CHG: Kodierung der database.xml in ANSI (von UTF-8) umgewandelt, da sonst Umlaute immernoch Probleme machen.
''       Dennoch sind die Inhalte UTF-8 kodiert (nur der Dateityp ist geaendert).
'12.09.2007 Ronny
''- CHG: Wolken mit besseren Pixel-Comic-Wolken ersetzt (Wolkenstreifen statt Einzelwolken -> 3 statt 30 Stueck)
''- CHG: Die Darstellung des Gebaeudes vereinfacht (ueberarbeitet), davon betroffene Objekte (Figuren, Tueren,
''		 Fahrstuhl) ebenfalls entschlackt. Y-Koordinatenberechnung nun besser nachvollziehbar
''- CHG: Die Gebaeudegrafik ist nun wieder nur 1024Pixel gross ... obige Anpassungen deswegen notwendig
''- FIX: Die Fahrstuhlbewegung hatte ein paar Grafik-Versetzer die etwas unschoen aussahen
''- CHG: Der Fahrstuhl ueberprueft nun beim Hinzufuegen einer Fahrtroute, ob derselbe Nutzer auf derselben Etage
''       bereits den Knopf gedrueckt hat, nun wird der Fahrstuhl nicht nochmals dorthin geschickt
''       (neue funktion: elevator.ElevatorCallIsDuplicate:int(floornumber,who) )
'10.09.2007 Ronny
''- CHG: weiter den Code umformatiert und uebersichtlicher gemacht
''- CHG: mit dem neuen Codeprofiler von BLIde unnoetige Variablen geloescht und unzureichend initialisierten
''       einen Wert gegeben
'18.08.2007 Ronny
''- CHG: Interface runderneuert - bessere Symbole und TV-Geraet neugezeichnet (Original vor langer Zeit verschollen)
''- CHG: Texte im Interface per Parameter einfaerbbar
'07.08.2007 Ronny
''- CHG: erneute Experimente mit Singlesurface-Modellen der Spritezeichnung, leider keine Performanceschuebe fuer
''       alte Onboard-Grafikchips, dafuer Grafikfehler. Neuere Karten wuerden bis zu 10% mehr FPS schaffen
'25.07.2007 Ronny
''- NEW: Supermarkt: Bettygeschenke - Kreuzfahrt
'12.07.2007 Ronny
''- CHG: Der momentan eingebaute Profiler (Messungen von Aufrufen und Dauer einer Funktion) laesst sich mit "P"
''       ein- und ausschalten. Ist er aktiviert, steigt der "Mem"-Bedarf kontinuierlich, da alle Aufrufe einer
''       Funktion protokolliert werden.
''- CHG: PhysikFPS auf 50 heruntergesetzt - erspart etwas CPU-Last und muesste bei aelteren Systemen fluessiger
''       laufen. Die Begrenzung auf 30FPS empfinde ich als etwas mehr "ruckelnd" in der Darstellung.
''- CHG: Die Figurenbewegung wird nun 0 gesetzt, wenn die Position + deltaabhaengige Bewegung kleiner der
''       ZielX-PosX-Differenz ist. Dadurch kann die PhysikFPS nun auch bei <60 genaue Ergebnisse liefern.
''       Vorher konnten Figuren bei bspweise 30PhysikFPS auf der Stelle Links/Rechts/Links...-Animationen zeigen.
'10.07.2007 Ronny
''- NEW: Supermarkt: Bettygeschenke - Sportwagen, Fussspray
'09.07.2007 Ronny
''- NEW: Supermarkt: Bettygeschenke - Nerz, Buch, Perlenkette, Collier, OP
'03.07.2007 Ronny
''- CHG: Interface-Tooltips faden schneller aus (50->20)
''- NEW: Bote rennt durchs Haus und holt bzw. bringt "Zettel" in verschiedene Räume
'02.07.2007 Ronny
''- NEW: GFX: Figur_Bote und Figur_Bote2 (mit "Zettel" in der Hand)
'28.06.2007 Ronny
''- CHG: Programmplaner: Zeichnen-Zeit von um 75% reduziert (neue Funktionen: DrawTextOnPixmap, DrawPixmapOnPixmap)
''       Hierfür wurden die Zeittexte fest in die Hintergrundgrafik gezeichnet, gleiches gilt für die ProgrammHGs.
'13.06.2007 Ronny
''- CHG: Da MaXML kein Zip und keine Verschlüsselung zur Verfügung stellt, habe ich in die MaXML-Funktionen
''       entsprechende Komprimierungsfunktionen eingebaut. Gibt man den Laden/Speichern-Funktionen bei 'zipped'
''       den Booleanwert "true" an, so wird eine komprimierte Speicherdatei angelegt, ansonsten die unkomprimierte
''       XML-Datei
''- CHG: Das XML-Modul hat zuviele C-Bibliotheken genutzt, die Exe schwoll von 1200 auf 2000KB an,
''       deswegen wieder Einsatz der modifizierten MaXML
'07.06.2007 Ronny
''- NEW: GameSettings und TFigures können aus XML geladen werden
''- NEW: Alle bisherigen Objekte können nun per XML gespeichert werden
''- NEW: Player- und Figuren-Objekte ebenfalls in XML gesichert
''- NEW: Filmagentur-Blöcke werden in der XML gespeichert
''- NEW: Programm-/Werbe-/News-Blöcke werden in der XML-Speicherdatei gesichert
'06.06.2007 Ronny
''- NEW: Programme, News, Werbung und Spieleeinstellungen werden per XML-Dialekt abgespeichert
'05.06.2007 Ronny
''- NEW: LoadSaveFile - XML-Objekt mit angepassten Schreibfunktionen, Ausgabe wahlweise komprimiert/verschlüsselt
'21.05.2007 Ronny
''- CHG: Lua_ki.bmx - Konstanten der NewsGenres eingebunden (sonst nicht kompilierbar)
''- CHG: TVGigant_Blitzmax.bmx etwas aufgeräumt
'12.04.2007 Ronny
''- FIX: Der Fahrstuhlinnenraum wurde 4 Pixel zu weit oben gezeichnet (nur in Bewegung erkennbar)
''- CHG: Fahrstuhl + Insassen werden nun hinter dem Hochhaus gezeichnet (was die Fahrstuhlbereiche als transparent
''       maskiert hat) - hierdurch dürften einige Clippingfehler bei älteren Grafikkarten entfernt sein.
''       Gleichzeitig wurde hierdurch der Programmieraufwand entschlackt (unnötige setviewports, Mehrfachzeichnungen)
'11.04.2007 Ronny
''- CHG: Das Dach vom Hochhaus besaß Alpha - aus Performancegründen wurde das Dach in eine Extragrafik ausgelagert,
''       diese nutzt Alphablend, der Rest des Hauses MaskBlend
''- FIX: Beim "Betreten" der Credits-Tafel wurde eine Tür-öffnen-Animation gezeigt
''- FIX: Wie im Werbeblock-Menu fehlte auch im Programm-Menu der Mausklick-Reset
''- FIX: Wenn man aus dem Werbeblock-Menu einen Block angeklickt hatte, wurde für die linke Maustaste kein Reset
''       durchgeführt, hierdurch konnte im gleichen Zyklus der Block auf die unterliegende Fläche gedroppt werden
''- FIX: Im Programmplaner konnte man auf alten Sendepositionen (ab- bzw. angelaufen) Werbung platzieren
''- FIX: Im Raumplaner konnte man den Raum verlassen, während man ein Raumschild gedraggt hielt -- Übernahme der
''       Updatebehandlung vom Filmmakler - Man muss nun das Schild erst droppen bevor man den Raum verlassen kann
'10.04.2007 Ronny
''- FIX: Wählte man "Onlinespiel", ging dann zurück ins Hauptmenü und wählte "Einzelspieler", wurde dennoch eine Verbindung
''       zum Server für Onlinespiele aufgebaut (game.onlinegame = false hat gefehlt)
''- FIX: Tooltips wurden aus Performancegründen gegrabbt und als Bild gezeichnet - hierbei wurde nicht auf Sichtbarkeit
''       des entsprechenden Grafikbereiches geachtet (weswegn Grafikfehler bzw. Abstuerze moeglich waren)
'09.04.2007 Ronny (Osterdemo2007-Release)
''- FIX: Das Grabben der Auktionsfilmblöcke lieferte einen Trauerrand, wenn es schon beim ersten Frame gegrabbt wurde
''       (nun wird erst nach 20 Frames das Bild gegrabbt, vorher Bildbearbeitung on-the-fly)
''- NEW: Filmauktionen werden nun korrekt im Mehrspielermodus übermittelt
''- FIX: Falls ein Mitspieler nicht genügend finanzielle Mittel hatte, kam die Meldung auch Anderen
''- NEW: (als Test zu betrachten) Was man mit einem Filmhändlerblock anstellen kann wird nun per
''       "Glow-Effekt" angezeigt - Kaufen: Händler und Koffer leuchten, Verkaufen: Händler leuchtet

''- CHG: Updatebehandlung der Filmhändlerblöcke von Grund auf neuprogrammiert
'07.04.2007 Ronny
''- FIX: Beim Trennen der Menüverarbeitung (Grafik, Logik) wurde die Netzwerk-Startsynchronisation gestört
''- CHG: Network.bmx - erweiterte Kommentierung der Quellcodezeilen
''- FIX: Doppelklick auf Mehrspielerlobby-Eintrag wurde nicht erkannt
'29.03.2007 Ronny
''- FIX: Der Keymanager wurde nicht richtig initialisiert und TGuiObject las die Tastendrücke falsch aus,
''       wodurch es zu "doppelt gedrückten Buchstaben" kommen konnte, bzw. e und q (wegen Sonderzeichen mit
''       Alt-Gr) nicht angenommen wurden
''- CHG: Auskommentierte Ladebefehle in files.bmx entfernt (Code-Entschlackung)
''- CHG: Menu-Bereiche in Update und Draw getrennt und in normale repeat-Routine eingebunden
''- CHG: Initialisierung: Init_Complete-Variable (bei false wird Init - also Räume, Farben usw. durchgeführt)
'28.03.2007 Ronny
''- CHG: TGUIButton-Text hat nun Schatteneffekt
''- CHG: TGUIButton-Textfarbe variiert nun bei MouseOver, Text wird um x+1,y+1 Pixel versetzt falls "down"
''- NEW: TGUIObject besitzt nun "mouseover"-Eigenschaft
''- CHG: TGUIButtons in den Startmenüs angepasst
''- NEW: TGUIButton übernimmt nun beim Erstellen eine Schrift, bei keiner Übergabe wird Font12 genutzt
''- FIX: Die Sprites der Zuschauerfamilie wurden mit MaskBlend gezeichnet (keine Schatten auf der Couch)
''       nun wird korrekt AlphaBlend genutzt, das Overlay über diesem "Bildteil" nun mit MaskBlend gezeichnet
'26.03.2007 Ronny
''- CHG: TBuilding: Eingangs- und Zaun-Sprite in die DrawBackground-Methode ausgelagert und ähnlich der
''       HG-Häuser abhängig von Tageszeit abgedunkelter dargestellt als das Hauptgebäude
'15.03.2007 Ronny
''- CHG: TVT ist wieder Linuxkompatibel ... entsprechende "?win32"-Klauseln für DX-Funktionen eingebunden
'14.03.2007 Ronny
''- CHG: Umstieg auf BnetEx 1.66 (Netzwerk-Funktionen umgeschrieben)
''- CHG: Weitere Aufräumarbeiten am Quellcode
'07.03.2007 Ronny
''- NEW: Auktionen werden nach Tagesende dem meistbietenden Spieler übergeben
'02.03.2007 Ronny
''- FIX: Bei Betreten des Raumplaners wurde eine "Tür schließen"-Animation gezeigt (Tür-Sprite)
''- FIX: Im Raumplaner konnten die Schilder nichtmehr verschoben werden (Mousemanager.change-Aufruf in
''       Raumplaner-Compute-Schleife)
''- FIX: Die Texte der Raumschilder hatten eine Transparenz, was unschoene Textdarstellung hervorrief (da
''       die Halterung der Schilder durchschien und Buchstabenteile dunkler wirken liess)
''- CHG: gehaltene (gedraggte) Raumschilder werden nun vom Textdesign gleich gedroppter Schilder dargestellt
''- CHG: weitere Aufräumarbeiten im Code...
''       - Initialisierungsvorgänge in Funktionen sortiert
''       - Include-Konstrukte sortiert (rooms.bmx - Raumerstellung in Funktion ausgelagert)
''- CHG: Grafik für Sendemastplan überarbeitet: Bundesländer in Grafik eingebunden und Kollisionsbilder
''       mit 2Bit-Grafiken ersetzt (n bisschen Ram und HDD sparen)
''- FIX: Dank Einsatz von TBigImage konnte der Sendemastplan nicht mit Grafiken überlagert werden (nur
''       Hintergrund wurde gezeichnet)
'25.02.2007 Ronny
''- CHG: Von Strict auf SuperStrict beim Kompliermodus gewechselt (erhöhte Sicherheit durch Typenangabe)
''- NEW: Bietet ein Spieler für ein Programm, bekommt der letztbietende Spieler sein Geld zurücküberwiesen.
''       Die Finanzstatistiken werden dementsprechend aktualisiert, so dass keine exorbitanten Summen von Ein-
''       und Ausgaben zustande kommen.
''- FIX: Der Sternenhimmel bestand aus einem Array von 60 Werten, eine For-Schleife wollte aber 61 Werte
''       auslesen, was im Debug-Modus zu einer Fehlermeldung fuehrte
''- FIX: DrawOnPixmap überprüft nun vor dem Werteauslesen, ob der Pixel überhaupt in der Pixmap vorhanden ist
''- CHG: Neue Version des DX9-Moduls (v0.5), sollte etwas kompatibler mit DX7-Grafikchips sein (Screengrabbing)
'24.02.2007 Ronny
''- NEW: Auktionsfilme-Gebotsberechnung eingebunden
''- CHG: Quellcode etwas aufgeräumt
'23.02.2007 Ronny
''- NEW: Auktionsfilme-Typ erstellt, Höchstbietender wird in Spielerfarbe (mit Schatten wie bei Raumplaner)
''       angezeigt, Schatten hier aber abhängig von Spielerfarbe
'19.02.2007 Ronny
''- NEW: Auktions-Raum beim Filmhändler, Anpassung der Auktionsfilm-Grafik und Einpassung des Rahmens
'17.02.2007 Ronny
''- CHG: Ladebalken-Bildauflösung verkleinert und Anzeige von geladenene und Total zu ladenden Dateien
''       in den Ladebildschirm eingefügt (+ kleiner Bug bei Fortschrittsanzeige entfernt)
''- CHG: Newsgenre-Buttons zu einem Sprite zusammengefügt (200kb RAM und 20->12KB Speicherplatz Ersparnis)
''- CHG: Redundante Methoden und Funktionen der Blöcke (News, Programme, Werbung...) ausgelagert
''       nun ist die EXE zwar nur 5kb kleiner, der Quellcode hat aber 12kb abgenommen, nun nur noch 1,3MB
''- CHG: Image, Color, Keymanager, xml, etc.-Funktionen ausgelagert in "basefunctions_TYP.bmx", dies
''       sorgt für etwas organisierteren und überschaubareren Quellcode
'13.02.2007 Ronny
''- CHG: Gesamtänderung: Haupthaus von 360 auf 490fps (openGL, windowed, 32bit) -> ~25%
''- CHG: TTooltip speichert nun seine Ausgabe in einem Bild, bei Inhaltsänderung wird dieses Bild
''       erneuert, die Zeichnung des Bildes müsste etwas Performance herauskitzeln (Vgl. mit Text+Rectausgabe)
''- CHG: Alle Raumgrafiken mit TBigImages ersetzt (760x373 nun im Speicher mit 768x384 statt 1024x512)
''       Ergebnis: 40MB Ram gespart
''- CHG: Die Hintergrund-Hochhäuser bestehen und aus einzelnen Sprites (links und rechts des Spielgebäudes)
''       (5% Performance)
''- CHG: Der animierte Sternenhintergund ist nun manueller Pixelsetzung gewichen (10% Performancegewinn)
''- CHG: Türen, Pflanzen etc. (Objekte hinter den Spielfiguren) sind nun fest auf dem Hochhaussprite
''       angebracht (Performance: 5-10%) -> neue Funktion: functions.DrawOnPixmap inklusive Alphawerten
''- CHG: Bei Objekten ohne Alphakanal wird vorher SetBlendMode SolidBlend statt AlphaBlend gesetzt, der
''       Performancegewinn ist vorallem bei älteren Grafikkarten bei ca. 20%
''- NEW: TBigImage-Typ, allzugroße Sprites werden automatisch in kleinere (bspweise 256x256) Blöcke zerschnitten
'07.02.2007 Ronny
''- NEW: Laden/Speichern von Blöcken beim Archiv + Laden/Speichern genutzter DNDBereiche
''- NEW: Laden/Speichern von Programmen beim Filmhändler + Laden/Speichern der dort genutzten DNDBereiche
''- FIX: Beim Filmmakler wurden alle verkauften Filme entfernt, "verkaufte" man ein Programm zurück ins
''       Regal, wurde diese Position nicht wieder mit dem Programm gefüllt ("zurückstellen ins Regal").
''       Nun wird dem Sell-Befehl der Parameter "bymakler" übergeben, dieser entscheidet über Löschung
''       oder nicht.
''- FIX: Beim Laden konnte bei TFigures ein Fehler auftreten, der zum Stillstand führte.
''       Nun wird bei NULL-Rückgabe eines TFigures.Load() die Schleife abgebrochen und der Ladevorgang
''       fortgesetzt
''- FIX: Bei SetInRoom und LeaveRoom wurde nicht überprüft ob ein Player von AI gesteuert wurde, sobald
''       Player[x].figure.ParentPlayer nicht Null war, wurden LUA-Funktionen aufgerufen, nach dem Ladevorgang
''       hatte aber jede Spielfigur einen Parentplayer - nun wird noch auf ControlledByID abgeprüft.
'03.02.2007 Ronny
''- NEW: Spielfigur "spielfigur1m.png" überarbeitet und etwas detaillierter gemacht. Gleichzeitig noch
''       die Testfigur "spielfigur1m_neu.png" erstellt, die doppelt (also 8) soviele Animationsframes
''       fuer eine Bewegungsrichtung enthält -> bisher nicht ins Spiel übernommen
'31.01.2007 Ronny
''- NEW: LUA_Ki.bmx (Typ-Basis von Michael) so angepasst, dass die notwendigen Funktionen zur Übergabe
''       und zum Erhalt von Werten an LUA-Scripte funktioniert - Testweise laufen die KI-Spieler herum.
''       In Michaels Basisklasse gab es keinerlei Rückgabe von Lua-Variablen und Parameter konnten nicht
''       übergeben werden, da die Funktion LuaScript.AddFunction nur dafür da ist, Blitzmax-Funktionen
''       innerhalb von Lua-Scripten verfügbar zu machen. TestFunktionen geben dem Script nun SpielerID
''       und -Position zurück und erlauben das Setzen eines neuen Zieles.
'28.01.2007
''- NEW: Raum "Save-Load" eingebunden, Funktionen noch nicht implementiert
'26.01.2007 Ronny
''- CHG: Die Funktion "Stream_SeekString()" hatte mit Fortschreiten der Position innerhalb der Speicherdatei
''       eine immer größer werdende Laufzeit, da sie immer bei 0 begann, die gewünschte Position zu suchen.
''       Nun wird die letzte Suchposition gespeichert und von ihr aus wird nach dem nächsten Suchwunsch
''       gesucht. Wird dabei kein Rückgabewert erzielt, so beginnt die Suche wieder bei Position 0 (und somit
''       der längeren Laufzeit... für den Großteil der doch sortierten Abfragen ist die Zeit hierbei aber um
''       den Faktor 200 verkürzt.
''       Da aber immer nach Start- und Endtag einer Objektklasse gesucht wird, ist spätestens beim Endtag eine
''       Optimierung erreicht (der kommt ja zu 99.99% nach dem Starttag).
''- NEW: Verträge beim Makler können nun gespeichert und geladen werden, die bereits abgeschlossenen
''       Werbeverträge der Spieler werden von deren ProgrammeCollections geladen (Originalverträge)
'25.01.2007 Ronny
''- FIX: Vor dem Speichervorgang wurde die Spielgeschwindigkeit auf 0 gestellt - dies wurde auch im
''       Speicherstand gespeichert, nun wird ein Backup (oldspeed) gespeichert zu dessen Wert nach dem
''       Speichervorgang zurückgekehrt wird.
''- NEW: Die Genrebuttons im Nachrichtenstudio entsprechen nun den Einstellungen des jeweiligen Besitzers
''- NEW: News und NewsBlöcke können nun gespeichert/geladen werden
''- NEW: Quoten (TAudienceQuotes) Speichern/Laden implementiert
''- FIX: Player-Objekte wurden beim laden zweifach in den Listen gespeichert (Fehler bei Quotenanzeige)
''- NEW: Verträge und Werbeblöcke werden nun gespeichert und können geladen werden
''- NEW: Fahrstuhl und Fahrstuhlrouten können nun gespeichert/geladen werden
'24.01.2007 Ronny
''- NEW: TFinancials werden nun mit in den Speicherstand geschrieben (Laden/Speichern)
''- FIX: Der Player-Array wurde nicht richtig mit den geladenen PlayerInformationen ersetzt, es koexistierten
''       also mehrere Spieler (aufgefallen durch TFinancials die nur scheinbar richtig dargestellt wurden)
''- FIX: Es wurden zwar alle TProgramme gespeichert, beim Laden wurden den danach erstellten Programmblöcken
''       keine Klone der Programme zugewiesen - und die Sendezeit/datum wurde nicht mitgespeichert (da nur
''       bei den Klonen enthalten... für den Lade/Speicher-Vorgang besitzen die Programmblöcke nun auch
''       Sendezeitinformationen
''- NEW: TPlayer (ohne TFinancials) und TFigures können nun gespeichert und geladen werden
'22.01.2007 Ronny
''- NEW: Game-Objekt (Geschwindigkeit, Zeit, Spieltag, Netzwerkspiel usw.) Laden/Speichern eingebunden
''- NEW: Laden und Speichern wird nun visualisiert indem eine Errorbox (bzw. MsgBox) über den Status
''       informiert
''- NEW: Programme und Serien werden nun gespeichert, beim Laden wird entsprechend der Besitzer die
''       ProgrammeCollection wieder mit den Programmen befuellt
'21.01.2007 Ronny
''- NEW: Laden und Speichern von Programmbloecken funktioniert
''- NEW: Funktion Stream_SeekString liefert die Position des gesuchten Wortes innerhalb der Savegames zurück
''- NEW: Laden/Speichern: Basisfunktionen für Programm/Werbe...-Klassen
'20.01.2007 Ronny
''- CHG: Büro kann nun per Klick auf die Tür verlassen werden
''- CHG: Grafik der Errorboxen neugestaltet.
''- NEW: Errorbox bei Senderkarte, ist eine Station nicht finanzierbar, bekommt der Spieler eine Meldung
''- NEW: Errorboxen - sprich Fehlermeldungen, fangen Mausklicks ab solange sie da sind
'14.01.2007 Ronny
''- FIX: erfolgreich beendete Werbeverträge werden nun korrekt aus dem Aktenkoffer beim Werbemakler entfernt.
''- CHG: Physik und Grafik bei den Raum-Tooltips (welcher Raum ist was) getrennt
''- FIX: Wenn ein Programm aus dem Archiv genommen wird, was derzeitig läuft, dann wurde die Zuschauer-
''       zahl nicht 0 gesetzt (was ermöglichte, trotzdem einen Werbevertrag erfolgreich abzuschließen)
''- CHG: Physik und Grafik im Newsplaner getrennt
''- FIX: Im Hochhaus wurde die CLS-Farbe auf Himmelfarbe gesetzt, in Raeumen hingegen nicht auf schwarz
''- CHG: Physik und Grafik im Archiv getrennt
''- NEW: Videokassetten beim Filmhaendler sind nun genreentsprechend eingefaerbt (bisher nur bis Genre 10)
'13.01.2007 Ronny
''- CHG: Physik und Grafik beim Filmfuzzi getrennt, Gimmick (Zwinkern) eingebaut
''- CHG: Grafiken der Werbevertraege beim Makler erneuert
''- CHG: Physik und Grafik beim Werbemakler getrennt
''- CHG: Die Textdarstellung im Fahrstuhlplan hat nun einen Blur-Schatten (erhoehte Lesbarkeit)
'11.01.2007 Ronny
''- CHG: Die Senderkarte wurde erneut um 200% (bei Nichtstun) beschleunigt
'09.01.2007 Ronny
''- NEW: DirectX 9-Modus auswählbar (leichte FPS-Verbesserungen auf meinen Testsystemen)
'07.01.2007 Ronny
''- FIX: Durch Trennung von Physik und Grafik kam es manchmal zu Aussetzern in er Mausereignis-Erkennung
''       Dadurch konnten Raumplangrafiken nicht immer ge-DnD-d werden. Dropzonen wurden hier um 1 Pixel
''       verringert.
'06.01.2007 Ronny
''- CHG: Die Framerate im Fahrstuhlplan wurde um 300% beschleunigt indem die gezeichneten Texte nun in die
''       Bilder geschrieben werden und sofern ein solches SchildMitText-Bild existiert wird dieses genommen.
''       Wird ein Schild gedragged, wird sein Textbild Null gesetzt (weil Alpha-Schatten nicht mitgegrabbed
''       werden können). Eventuell kann das bei einigen Grafikkarten zu Problemen führen - also Meldungen
''       abwarten
''- CHG: Die Framerate beim Platzieren von Stationen wurde um 120% beschleunigt
''- FIX: Die Trennung von Physik und Grafik fuehrte zu Erkennungsproblemen der Maus und Keyboard-Ereignisse
''       dadurch konnte man nur unzuverlaessig DnD-Aktionen durchführen
'05.01.2007 Ronny
''- NEW: Die Physik (also Bewegungen usw.) werden nun getrennt von der Grafik getimed
''       Hierbei ist die Bewegung auf 60 FPS festgesetzt waehrend die Grafik unabhaengig davon
''       agiert (bei mehr FPS wird eine Figur halt mehrfach am selben Platz gezeichnet, bei weniger gibt
''       es eventuell Spruenge - aber nur visuell)
''- CHG: Das gestern eingebundene "Fenster verschieben" wurde wieder entfernt
'04.01.2007 Ronny
''- CHG: Das Laden der Konfigurationsdatei überprüft nun, ob Einträge fehlen und setzt Defaultwerte
''- FIX: Im Fenstermodus ist das Fenster nun ohne Stopp des Programmes verschiebbar
'02.01.2007 Ronny
''- FIX: Der Fix mit den Datenbankfunktionen wurde nicht ausreichend auf NULL-Objekte überprüft (Absturz gefixt)
''- FIX: Beim Rechtsklick mit gedraggtem Werbeblock wurde vorm Löschvorgang die Blockliste umgedreht, ein
''       erneutes Drehen bewirkt nun eine korrekte Werbespot-Nummernberechnung
''------ TVTower Patch 02022007_2
''- CHG: Die Zeit zwischen neuen Nachrichten wurde halbiert (5-50 bzw. 90-200)
''- FIX: Räume ohne spezielle Behandlung (momentan Studio, Supermarkt, Credits) usw. setzten den fromRoom
''       der Figuren nicht Null (wie die anderen Räume) dadurch war es möglich, einen anderen Raum anzuklicken
''       dann in einen dieser normalen Räume zu gehen und per Rechtsklick im vorher angeklickten Raum zu landen
''- FIX: *nerv* fiesen Fehler bei den Werbevertragsblöcken ausgemerzt, der auftrat, wenn man einen Block
''       draggt, auf einen anderen droppt und den nun gedraggten an eine leere Stelle droppt, dieser war dann
''       an seine alte Stelle zurueckgefallen und somit belegten 2 Blöcke einen Platz
''- FIX: Werbung des Spielers wird wieder im Koffer angezeigt (mit Datenblattfunktion der Adblöcke da diese
''       bereits gesendete Werbeblöcke berücksichtigen). Gleichzeitig werden die Grafiken der Contractblöcke
''       mit dem neuen Werbevertrag auch aktualisiert statt nur die Daten des Vertrages zu uebernehmen
''- FIX: "zwei Filme auf einmal"-Bug beim Filmhändler entfernt (Drop-Breite um 1 Pixel verringert)
''------ TVTower Patch 02022007
''- NEW: Mersenne-Zufallszahlengenerator. Genutzt bei der Berechnung der Zuschauerzahlen. Hiermit ist
''       bei allen Clients der gleiche Zufallsfaktor genutzt und somit sind die Quoten überall identisch.
''- NEW: Der Filmhändler stellt nun keine doppelten Filme/Serien mehr zur Verfügung, ist keine neue Serie
''       bzw. neuer Film mehr vorhanden, bleibt eine Lücke im Regal, erst wenn ein Spieler entsprechend eine
''       Serie oder ein Programm verkauft, kann dieses Programm vom Händler wieder ins Angebot genommen
''       werden (used = -1 für weder Spieler noch Händler, used = 0 für Händler, used = 1-4 für Spieler)
''- CHG: Nahezu alle Funktionen mit dem Parameter TProgramme überprüfen nun erst, ob das Objekt NULL ist
''- NEW: Mitternacht werden die Aktualitätswerte der Programme wieder erhöht (*1.5) bis MaxAkt. vom Start
''- NEW: Die Aktualitätsverluste bei Ausstrahlung wirken sich nun auch auf den Preis aus
''- CHG: Da Serienepisoden keine wechselnden Genres haben sollten (aber könnten - aber doch als sinnlos
''       herausgestellt), übernehmen sie nun das Genre der Serie allgemein
''- CHG: Devkeys zum Spielerwechsel nur noch im Solospiel nutzbar
''- NEW: functions.blocktext hat nun einen Parameter, der den Zeilenumbruch verbietet und in diesem Falle
''       die Text-Kürzung auch ohne " " oder "-" durchführt (Ad- und Programmeblocks)
''       Dies sollte den "..."-Werbeverträgen den Garaus machen ;D
''- CHG: Wolkenbewegung nun abhängig von Spielgeschwindigkeit (passt besser zum Mond)
'01.01.2007 Ronny
''- FIX: TFinancials.GetDayArray() lieferte am 7. Tag einen negativen Wert für einen ArrayIndex zurück.
''       Dadurch stürzte TVT an diesem Tag ab (unerlaubter Speicherzugriff). Korrektur der Modulo-Berechnung.
''- CHG: Klickt man im Fahrstuhl auf den Raumplan, wird die Wartezeit nun gleich auf 0 gesetzt
''- NEW: Raumuebergaenge werden nun gefaded
''- FIX: Bei Abfrage ob Tueranimation zu zeigen fehlte die Ueberpruefung ob der Spieler aus dem Hochhaus kam
''       dies fuehrte zu dem beobachtbarem Tuerauf-und-zu-klappern
''- CHG: "Fahrstuhl mit Person"-Synchronisation erheblich verbessert
''- FIX: Bei schnellen Klicks auf die News-Genre-Buttons konnte der Status auf "geklickt" bleiben und somit
''       wurden stetig neue Synchronisationen der Abolevels ins Netzwerk geschickt
''- FIX: Nutzte der Spieler den Programm- oder Newsplaner und verliess mit Rechtsklick den Planer und
''       anschliessend den Raum, so blieb die Raumtuer geoeffnet (nun werden bei Verlassen immer die Tueren
''       geschlossen - so wie's die Polizei empfiehlt ;D)
''- FIX: Der (Dev-)Befehl zum Regeln der Spielgeschwindigkeit geht nur noch bis +-Null statt tiefer
''- NEW: Halterungen der Raumplanschilder nun Extragrafik und nur dort gezeichnet, wo auch ein Raumschild hängt
''- CHG: Darstellung der Raumplanschild-Titel angepasst (Danke an die Beschwerden ;D)
''- FIX: Positionen der Hauspflanzen angepasst und noch ein paar weitere Bluemchen eingebunden (+ Lampen)
''- FIX: Der Zurückbutton nach Auswahl des Solospiels führte zur Netzwerklobby
''- FIX: Die Anzeige über noch zu sendende Werbeblöcke funktioniert nun wie geplant, hierfuer wurde eine
''       neue Methode implementiert: Adblock.GetSuccessfullSentContractCount() und erfolgreiche Werbebloecke
''       bekommen nun den Wert botched=3 (botched=2 ist erfolgreich abgeschlossen und botched=1 ist vergeigt)
''- FIX: Ein gedraggtes Raumschild kann nicht mehr auf ein anderes gelegt werden, wenn man versucht es
''       an eine leere Stelle zu platzieren
''- CHG: Netzwerkklasse (UDP) etwas umgeschrieben, da Winsock-Routinen die Kompilierung unter Linux
''       verhinderten. Auf meiner Ubuntu-Installation wird allerdings keine IP zurueckgegeben, weswegen
''       eine Fallback-Adresse in der settings.xml angegeben werden kann (dennoch funktioniert der
''       LAN-Modus nicht richtig)
''- FIX: Der Hausmeister konnte bei Changetarget an den Fahrstuhl geschickt werden, dort blieb er aufgrund
''       seiner "am Fahrstuhl"-Position stehen - nun wird bei diesem Zustand nach spätestens 15 Sekunden
''       ein neues Ziel festgelegt
'31.12.2006 Ronny
''- CHG: Originaltitel-DB mit Fakenamen-DB ersetzt (Stand: 30% der eingetragenen Filme)
''- NEW: lang_de in lang_en uebersetzt
'30.12.2006 Ronny
''- NEW: Normale Spielfiguren bekommen ein "Hi", Gegner ein "grr" beim Vorbeilaufen
''- NEW: Cursoränderung nun auch bei Raumplan, Archiv und News sowie GFXContract und -Programmelist
''- NEW: Die Programm und Contract-Listen stellen die jeweilige Kassette unter dem Mauscursor heller dar
'28.12.2006 Ronny
''- FIX: Die Schatten von Programmblöcken werden nun vor der generellen Update-Funktion gezeichnet, da sich
''       sonst ein nicht-gedraggter Block unter dem Schatten befinden konnte (visuell mehr als unschön)
''- NEW: Neue Mauscursor braucht das Land - Cursor visualisiert nun schon bei Programmblöcken, ob man sie
''       zum Beispiel draggen (greifen) kann und ob ein Programm noch gehalten wird
'27.12.2006 Ronny
''- FIX: Die Programmblock-Datenblaetter werden nun ab x=390 links angezeigt (vorher 400), da sonst rechte
''       Programmbloecke fuer wenige Pixel rechts die Infos anzeigen konnten
''- NEW: Ein gedraggter Programmblock wird an seiner Originalposition noch angezeigt (alpha 0.5) um den
''       Ursprungsort dem Spieler zu visualisieren
''- FIX: Ein Programm kann nicht mehr auf einen gerade angelaufenen Sendeplatz gedroppt werden
'26.12.2006 Ronny
''- FIX: Building.getfloory liefert nur die Differenz zu Building.y aus - Changetarget der KI-Figuren nun darauf
''       angepasst (Figuren wackelten zur falschen Etage (oft Erdgeschoss also 0))
''- NEW: Der Hausmeister wischt ein paar Male die aktuelle Etage und per Zufall wird nach gewisser Zeit die nächste
''       Etage aufgesucht (wenn er allerdings länger als 15 Sekunden auf den Fahrstuhl wartet, wischt er erstmal
''       weiter die Etage ...). Nach der obersten Etage ist das Erdgeschoss dran und so weiter.
''- NEW: Hausmeister: Grundfunktionen (herumlatschen und ab und wann den Wischmop schwingen)
''- CHG: TFigures besitzen nun einen Namen, dieser wird bei der Fahrstuhlroutenanzeige genutzt (Fahrstuhlfunktionen
''       von Player auf TFigures umgestellt)
'24.12.2006 Ronny
''- NEW: Konventionalstrafen von abgelaufenen Werbeverträgen werden 0Uhr vom Spielerkonto abgezogen
''- NEW: Quotenstatistik des aktuellen Tages im Programmplaner abrufbar
''- NEW: Typ TudienceQuotes (beinhaltet Sendung, Sendezeit, Marktanteil und Zuschauerzahl)
''- FIX: TPlayer.ComputeAds() nutzte nur die PlayerID=1 zum holen aktueller Werbebloecke (weswegen "geschaffte"
''       Werbevertraege nach Vollendung nicht gelöscht wurden
'23.12.2006 Ronny
''- NEW: Vollbildmodus in der Settings.xml aktivierbar gemacht
''- FIX: Der Fahrstuhlbug liegt in der Spielerkoordinatensynchronisation, aber auch ohne diese, kann es selten
''       vorkommen, dass ein Spieler nicht korrekt als "im Fahrstuhl" erkannt wird und die betroffenen Spieler
''       bekommen erst im Moment des angekommenen Fahrstuhls die neue Position der Insassenfigur mit
''- NEW: "Speedfactor" der Netzwerkpakete... alle Intervalle werden mit dem Faktor multipliziert, so kann im
''       lokalen Netzwerk eine noch bessere Synchronisation gewährleistet werden, da dann Pakete aller weniger
''       Millisekunden verschickt werden (momentan 3kb/s im LAN und 300 Byte/s Online)
''- NEW: Traffic-Anzeige in Mehrspielersessions
'22.12.2006 Ronny
''- FIX: Nicht ganz gefixt, aber die Asynchronitaet von Spielern die den Fahrstuhl verlassen, wurde minimiert
''- NEW: Spieler die beim Spielerstellen das Spiel betreten, werden im Chatlog aufgefuehrt
''- NEW: Spielernamen und Sendernamen werden bei Spielerstellung synchronisiert
''- CHG: Visuelle Darstellung von Chatnachrichten verbessert (Schattenschrift nun bei Alpha 0.5 statt 1.0)
'20.12.2006 Ronny
''- FIX: Im Mehrspielermodus konnten durch FloorRoute-Paket und Fahrstuhlsynchronisation Etagen 2x eingetragen
''       werden
''- NEW: Spieltitel wird bei Clients nun auch in den Einstellungen angezeigt
''- CHG: TGUIList enthaelt nun noch pro Eintrag einen Title-Feld (Fuer Spielnamenuebermittlung genutzt)
''- CHG: Spiele werden nur noch verkündet, wenn das Spiel noch nicht läuft (späteres joinen also erstmal
''       ausgeschlossen)
''- NEW: Spieltitel in den Spieleinstellungen änderbar (wird noch nicht in Ini-Datei gespeichert)
''- NEW: "Einstellungen abgeschlossen"-Radiobutton, erst nach Häkchensetzung wird ein Spiel verkündet (Online/Lan)
''- FIX: TGuiRadioButton-Objekt hatte bei Verlassen der Maus auch seinen Klickstatus verloren (Haekchen oder nicht)
'18.12.2006 Ronny
''- CHG: Das Beenden des Spieles ist nun auch ohne Spielstart per ESC oder Klick aufs [x] moeglich
''       (kleinere Spielereien probiert, die eine Framelimitierung besser kontrollierbar machen wuerden)
''- NEW: Delay(1) in den Hauptroutinen - erspart ein paar wenige Prozent an CPU-Last (bei AMD 1800XP von
''       11-16% auf 8-13%)
'17.12.2006 Ronny
''- FIX: Serienepisoden hatten keine eindeutig zuordenbare ID (verglichen mit Filmen), die
''       Netzwerksynchronisation konnte dadurch kein Programm ausfindig machen (Serien waren nicht "auffindbar")
''- NEW: TProgramme.GetProgramme(number) - liefert ein Programm (Serie, Film) zur passenden Nummer
'15.12.2006 Ronny
''- CHG: Startbildschirm aktualisiert, bei GameSettings wird ein kleines Logo unten rechts gezeigt statt dem
''       grossen mittigen Bild.
''- CHG: Startmenueintrag "Spiel Starten" ist nun "Einzelspieler"
''- NEW: Solospielermodus beinhaltet nun ebenfalls Spieleranpassungen (Namen, Farben, ...)
''- FIX: War der Host in einem Raum, hatte er bestimmte Updatebefehle von Fahrstuhl und Figuren nicht
''       abgearbeitet (verwoben mit Zeichnen-Befehl), dadurch konnten andere Spieler in dieser Zeit
''       nicht den Fahrstuhl benutzen und der Host sah die Figuren nach Verlassen des Raumes zu deren
''       bereits ereichtem Zielpunkt laufen
''- CHG: weitere Trennung von Logik und Zeichnen-Befehlen bei: Building, Elevator, Figures
''       Dadurch obiger Fix
''- FIX: Die Spielerpositionen wurden an alle Mitspieler (einschliesslich einem selbst) geschickt, dadurch kam
''       es bei groesseren Pings zu Problemen, wenn ein Spieler in einen Raum ging (da Pakete mit solch
''       Verzoegerung eintreffen konnten, dass man immer wieder in den Raum gesetzt wurde)
''- DBG: Ping und Raum des Spielers werden in der rechten unteren Ecke angezeigt.
''- CHG: Hochhausgrafik angepasst, Titel nun aenderbar (momentan "TVTower"), neue Hoehe in Code eingebunden
''       Bilder die von Tueren verdeckt wurden sind nun korrekt im Hochhaus verschoben und sichtbar ;D
''- CHG: TReliableUDP - Resends werden nun erst ab dem 3. Versuch in der Konsole angezeigt
'13.12.2006 Ronny
''- NEW: Zum Spielstart werden eventuelle "Reliable"-Pakete zum Thema "SendProgramme" und "SendContract" entfernt,
''       sie wurden ja schon durch die "GameReady"-Flag-Sendung als erfolgreich uebermittelt deklariert
''- NEW: Fahrstuhl-Route wird vom Host immer dann synchronisiert, wenn die Fahrstuhltuer geoeffnet/geschlossen
''       wird oder X-Sekunden vorbei sind
'12.12.2006 Ronny
''- NEW: Neue Methode: TReliableUDP.DeletePacketsWithCommand(Command) - löscht bspweise alle "Join"-Pakete
''       Wird genutzt zum Spielstart
''- NEW: Spieler können aus dem Spieleinstellungsraum gehen und trennen dann die Verbindung zum Host
''       der eventuelle Pakete an den betreffenden Spieler löscht: TReliableUDP.DeletePacketsForIP(IP,Port)
''       Der verlassende Spieler leert nun seine ReliableUDP-Liste.
''- NEW: Verbindungstrennung funktioniert nun ohne Unmengen an Resends.
''- NEW: Doppelklickfunktionalität der Spielelisten (Doppelklick auf Eintrag "joined")
''- NEW: Netzwerkfunktionen in die Datei "network.bmx" ausgelagert
'11.12.2006 Ronny
''- FIX: Einloggen in Netzwerkspiel wieder moeglich
''- NEW: Host kann Computerspieler-Details aendern (Figur, Name usw.)
''- NEW: Netzwerkfunktionen GetMyIP(), GetMyPort(), UrlEncode(), UrlDecode(), WriteMyIP() ...
''- NEW: Alles Neue macht der Mai... schoen wenn Subversion mir einen Konflikt meldet und dann die aktuelle
''       Arbeitskopie zerstoert... dasselbe war vor einigen Tagen schonmal geschehen (unmassen Nullbytes in den
''       Sourcecodes) .. nun fehlen funktionierende Fahrstuhlsynchronisation, Doppelklickfunktionalitaet in der
''       Spieleliste, Moeglichkeit der Spieler ein noch nicht begonnenes Spiel wieder zu verlassen, ein
''       komfortablerer Verbindungstrennmodus, entbuggter und entschlackter Netzwerkverkehr, Doppelpaket-Handling
''       und ne ganze Menge mehr...
''       wird eine prima Nacht... danke Subversion (auch wenn DIE Schuld sicher bei einem ungluecklichem
''       Zusammenspiel mehrerer Komponenten liegt)

'02.12.2006 Ronny
''- FIX: Der Timeout für Listeneinträge wurde falsch gesetzt (genutzt in Spielelobby, Einträge älter als X Sekunden
''       werden entfernt
''- NEW: Onlinylobbytests... Spiel holt vom Server-Skript die aktuelle Spiel-Liste mit Titel, IP, Port usw.
'01.12.2006 Ronny
''- NEW: Synchronisation von Nachrichtenbloecken (Platzierung, Entfernung, Bezahltstatus)
''- NEW: Server sendet an alle Spieler, welcher der Mitspieler eine erzeugte Nachricht bekommt (abonniertes Genre)
''- FIX: Newsblock.create - dem "owner" wird nun die News in den Plan gelegt, nicht dem Client (game.playerID)
''- FIX: PlayerProgrammePlan.removeNews - Check ob Listenobjekt Null ist (exception Error)
'30.11.2006 Ronny
''- NEW: Synchronisation von Filmverkäufen und Aktionen im Archiv (Film in den Koffer legen und damit vom
''       Programmplan entfernen
'26.11.2006 - 29.11.2006 Ronny
''- NEW: Tests mit neuen Grafiken (Buero, Betty) ... Rendergrafiken in 1024x768 - eventuell fuer die Zukunft
''       vorgesehen
'24.11.2006 Ronny
''- FIX: RemoveAllProgrammeInstances ... nur, wenn Rückgabewert <> Null (zusammenhang mit Tobjectlist)
'23.11.2006 Ronny
''- FIX: Beim Aendern der Laufrichtung einer Figur wurde die momentane Animationsposition nicht geaendert
''       dadurch liefen manche Figuren fuer 3 Animationsschritte "rueckwaerts".
''- CHG: Den RAM-Verbrauch (gemessen kurz nach Einstieg ins Hochhaus) um 25MB auf 77MB gesenkt indem bspweise
''       Ladebalken etc. entfernt wurden, nachdem alle GFX geladen wurde. Desweiteren ein paar unnoetige Grafiken
''       entfernt (die doppelt geladen wurden - als Image und Pixmap bspweise).
''- CHG: TListen bei TProgramme und Abkömmlingen sowie TNews und TContracts mit TObjectList ersetzt (jeweils rund
''       1 MB Speicher gespart und schnellerer Zugriff auf enthaltene Objekte) - Methoden den neuen Funktionen
''       angepasst
'22.11.2006 Ronny
''- CHG: Räume mit dem "owner" -1 zeigen nun kein Zugehörigkeitsschild mehr neben der Tür an, dies dient der
''       Orientierungshilfe, ob es sich um einen Raum mit Funktion handelt oder nur einen potentiellen also
''       "späteren" Studioraum.
''- FIX: Beim setzen der "first"-Route des Fahrstuhles wird nun überprüft ob die Liste leer ist, da sonst eine
''       Fehlermeldung auftrat (beim Löschen des ersten Eintrages), da die Liste leer sein konnte.
'21.11.2006 Ronny
''- FIX: bei ProgrammePlan.refreshProgrammePlan(playerid,day) hatte beim erneuten hinzufuegen die Bedingung
''       gefehlt, ob das Programm für diesen Tag gedacht war (bei Vorrausplanung hatte dann jedes Programm
''       diesen Tag)
''- NEW: Verlässt man den Filmhändler, so werden die Filmregale aufgefüllt.
''       Dies hat zum Grund, dass man einen Film in seinen Aktenkoffer legen konnte, ihn dann auf den Haendler
''       droppen konnte und durch das folgende Löschen des Filmblockes ein Platz im Regal leerbleibt.
''       Dieser wird nun wieder aufgefüllt, wenn der Spieler den Raum verlässt und die Funktion "ProgrammeToPlayer"
''       ausgeführt wird.
''- NEW: Wenn das mal kein Krampf war, wieso zum Teufel gibt mir eine Bmax-interne Funktion zwar einerseits
''       das richtige Objekt zurueck, wenn man es aber loeschen will, dann loeschts ein anderes.
''       Also musste eine Objektliste in einen Array von Objekten konvertiert werden, dort dann entsprechend
''       bearbeitet und dann wieder zurueck in eine Liste gewandelt werden.
''       Nunja, verlaesst ein Spieler das Archiv, so wird dies mit dem Koffer beim Filmmakler synchronisiert
''- NEW: Filme koennen im Archiv ausgesucht und im Koffer platziert werden, diese sind solange im Koffer, bis
''       man sie zurückgelegt hat oder beim Filmmakler war. Filme im Koffer stehen bis zum Verlassen des Archives
''       noch im Programmplan, verlässt man den Raum, werden alle Programminstanzen entfernt.
'19.11.2006 Ronny
''- CHG: Raumtuer-Tooltip-Verarbeitung ausgelaggert und hinter die Fahrstuhltuer-Zeichenfunktion gesetzt
''- CHG: Code der Funktion TRoomSigns.GetRoomPosFromXY() entschlackt (auf 20%)
''- CHG: Spielerraeume von Spieler1 in Etage 2 verlegt, bei Spieler 2 von Etage 2 auf Etage 5
''- NEW: Neue Raeume eingebunden (Knarrenagentur, Friedenslobby, ...)
''- NEW: Raum Hinweistafel klickbar
''- NEW: Neue Raumerstellungsmethode die als Parameter X-Koordinate und Position(1-4) annimmt sowie Breite
''       der Klickflaeche
''- FIX: neuerstellte, "gedraggte" Werbebloecke konnten durch Klick ins Leere auf die zur Erstellung aktiven
''       Mauskoordinaten gedroppt werden. Nun ist deren startrectx und y 0 und in diesem Fall ist dropping nur
''       moeglich, wenn wirklich ueber einer Dropzone, ein "zurueckschnipsen" findet nicht statt
''- NEW: Nachrichtenagentur-Gebühren werden 0 Uhr vom Spielerkonto abgezogen. Gebuehren sind 1/2 des
''       Abolevelpreises
''- NEW: Nachrichtenbloecke die aelter als 2 Tage sind, werden aus den Listen entfernt...
''- NEW: Nachrichtenticker liefert nur News aus, wenn auch das Genre von einem der Spieler abonniert wurde,
''       damit spart man einiges an sonst unnuetz verschwendeten Nachrichten ein
''- NEW: Newsbloecke haben nun eine Paid-Eigenschaft (auch visuell), die abgrenzt ob eine Nachricht schon
''       bezahlt wurde und somit bei erneuter Nutzung nicht nochmals bezahlt werden muss
''- NEW: Besteht eine Nachrichtenkette aus mehreren Teilen, so wird bevorzugt eine dieser Ketten am naechsten
''       Spieltag fortgesetzt, als eine zufaellige neue Nachricht heranzuziehen
'18.11.2006 Ronny
''- NEW: Nachrichtenagentur (Ticker) - liefert in leicht zufälligen Abständen neue Nachrichten an die Sender
''       aus. Je nach in dem Moment genutzten Abolevel der Spieler, kommen diese mit Verzögerung als nutzbare
''       Nachrichtenblöcke beim Spieler an und können in die Nachrichtensendung reingenommen werden
''- NEW: Tooltipps der Genrebuttons im Nachrichtenstudio liefern nun Informationen über Abolevel des jeweiligen
''       Metiers. Momentan ist es so, dass die Verzögerung (3-Level) Stunden beträgt. Bei 0 wird die Nachricht
''       dem Spieler nicht übergeben (nicht abonniert)
''- NEW: Nachrichtenstudio: scrollbare Auswahlliste an Newsbloecken, diese sind aufsteigend nach
''       Datum/Zeit sortiert, scrollen jeweils nur soweit moeglich, wie auch Bloecke vorhanden sind
'16.11.2006 Ronny
''- CHG: TNews: Eigenschaften happenedday, happenedhour und happenedminute hinzugefuegt, sie werden von der
''       Newsagentur gesetzt um Wiederholungen planen zu koennen bzw. ungewollte auszumerzen und um auf die
''       Stufe der GenreAbos der jeweiligen Spieler reagieren zu koennen (Verzoegerung... nicht immer, aber
''       oft ;D)
''- NEW: TNews: Funktionen: GetRandomChainParent und GetNextInNewsChain (liefern News zurueck)
''- CHG: TNews.computePrice liefert nun einen von der Qualitaet abhaengigen Preis zurueck (bei Erstellung der
''       News wird ein Preisfaktor von 80-100 Prozent an "price" uebergeben, der den Preis pro Spiel variiert)
'15.11.2006 Ronny
''- NEW: room_credits.png neukreiiert, da Original (mit Layern etc.) vor Ewigkeiten verlorenging
''- CHG: BNET nun per import statt Modul eingebunden
''- CHG: kleinere Anpassung an striktere Syntaxueberpruefung nach Update von Bmax1.14 auf 1.22
'12.11.2006 Ronny
''- CHG: Erweiterte Kommentare in den Quellcodes und andere Aufräumarbeiten
''- CHG: Newsbloecke werden nun richtig eingefaerbt, Grafik neugestaltet, Titel hat mehr Platz.
'11.11.2006 Ronny
''- CHG: Das Netzwerkmodul wurde umgebaut, es unterstuetzt nun verlaessliche/reliable UDP-Pakete
''       Solange also vom Empfaenger keine Bestaetigung gekommen ist, wird in einem festgelegten Intervall
''       fuer eine bestimmte Versuchszahl das Paket erneut gesendet (-1 ist unendlich).
''       Das Problem trat auf, da Pakete in unbestimmter Reihenfolge eintrafen oder verschollen gingen, was
''       bei kritischen Daten (Spielstart, Programme, Werbung ...) nicht akzeptabel war
''- CHG: die Einlogmethodik im Netzwerk wurde generalueberholt und der Spielstart synchronisiert, erst wenn
''       alle Spieler ihre Startdaten haben, senden sie das bestaetigende Paket zum Startbefehl
'10.11.2006 Ronny
''- NEW: Adblocks werden nun im Netzwerk synchronisiert (aehnlich der Programmbloecke)
''- FIX: peinlich... TAdblock.createDragged hat den erstellten Block nicht zurueckgegeben... kein Wunder,
''       dass sowas Probleme im Netzwerk macht ;D ... Fehlersuche ahoi.
'09.11.2006 Ronny
''- NEW: Contracts (Werbung) haben nun jeweils eine uniqueID, gleiches gilt fuer Adblocks
''- FIX: Mausklicks im Hochhaus nur noch innerhalb der Interfacegrenzen moeglich
''- CHG: Anpassung der Text-Koordinaten bei Tooltipps
''- FIX: es wurden nur 13 Etagen-Fahrstuhlräume angelegt... 13 Etagen + Erdgeschoss sind aber 14 ;D
''- CHG: player[x].figure.changetarget: wird nur durchlaufen, wenn Figur nicht im Fahrstuhl (playerid <> elevator.passenger)
'08.11.2006 Ronny
''- CHG: Rooms[0].activeroom nicht mehr genutzt, stattdessen: Player[x].figure.inRoom, ermoeglicht die gezielte Abfrage,
''       in welchen Raeumen die jeweiligen Spieler sind, statt dies in komplexeren Abfragen zu gestalten.
''- NEW: Tür öffnen und schließen-Animation nun auch im Netzwerksichtbar... vorher galt dies nur fuer die eigene Spielfigur
''- NEW: Methode TRooms.getRoomFromID() - jeder Raum hat eine UniqueID, spart Daten im Netzwerk
'05.11.2006 Ronny
''- NEW: Fahrstuhl-Raumplan klickbar, klickt man den Fahrstuhl an, bekommt man einen Plan, auf dem alle Räume angezeigt
''       werden. Laeuft eine definierte Zeit (momentan 4 Sek + 1.5 Standardwartesekunden), fliegt man aus dem Plan raus
''       und gibt somit den Fahrstuhl wieder frei.
''- CHG: ein paar Koordinaten wurden angepasst
''- CHG: Schrift auf Vera.ttf geändert
''- NEW: TRooms und TRoomSigns besitzen nun weitere Funktionen zur Anfrage von Räumen nach XY oder Raumplanpositionen etc.
''(Nichts falsches denken: die Woche bis 03.11.2006 war mit Klausuren gespickt, da gabs wenig TVGigant ;D)
'25.10.2006 Ronny
''- FIX: Bug, dass nur die Adblocks von Spieler 1 hochgezählt wurden (fehlerhafte Übergabe von Owner bei CreateDragged)
''- NEW: Synchronisierung von Sendemast-Kaeufen im Netzwerk
''- NEW: Anzeige der notwendigen Zuschauerzahl bei Werbevertraegen im Werbemakler-Raum
''- NEW: wenn ein Spieler "quittet", dann stellen alle Mitspieler den entsprechenden Player auf CPU
'24.10.2006 Ronny
''- NEW: Verschiedene Figuren in der Fernsehfamilie, je nach Quote und Uhrzeit schauen Opa, Maedchen und/oder
''       der Teenager. Schaut keiner, wird die Couch abgedunkelt dargestellt.
''- NEW: Auslagerung der Texte in Sprachfiles (lang_de.txt), Multilanguage zumindest fuers Interface? Nun kein
''       Problem mehr.
''- FIX: Spieler 1 hatte im Netzwerk eine andere Startprogramm-Reihenfolge als die anderen Spieler
''       durch Sortieren der Programmliste, haben alle die gleichen Reihenfolge für Spieler 1 parat
''- FIX: Interface.showchannel wird bei Spielstart auf die aktuelle PlayerID gesetzt, jeder sieht zu Beginn
''       sein Programm im Interface-Fernseher
''- FIX: Das Klonen der Programme fuehrte zur Dreifachbelegung der Sendeplaetze, hierdurch konnten 4Block-Filme
''       nicht eindeutig ermittelt werden (bei Erstausstrahlung waren die ersten 2 Bloecke Zufallsfilme)
''       durch refreshprogrammeplan ist dies nun behoben
''- NEW: programmeplan.refreshprogrammeplan(playerid,day) - anhand der Programmbloecke den Programmplan erstellen
''- NEW: IngameChat + OverlayImage (befindet sich im ueber der Fernsehfamilie im unteren Interface)
''- NEW: Inputfelder koennen nun eigene Bilder besitzen
''- NEW: Chats haben die Moeglichkeit, Zeilen nach gewisser Zeit auszublenden (IngameChat)
'23.10.2006 Ronny
''- NEW: Elevator.floorroute: direction... Ritschls Idee, dass Personen mit gleichem "Richtungswunsch" vom Fahrstuhl
''       aufgesammelt werden koennten
''- FIX: Floorrouten beim Fahrstuhl werden erst entfernt, wenn der Fahrstuhl die Etage erreicht hat und nicht bei
''       Beginn seiner Fahrt
''- FIX: Figure.Draw ... "onfloor <> tofloor" in "onfloor <> clickedtofloor" geaendert (Spieler die auf den
''       Fahrstuhl warten, zeigen den Ruecken zum Spieler)
''- NEW: Net: Platziert ein Spieler einen Programmblock im Planer (um), so wird dies bei Mitspielern aktualisiert
''       Ist es ein Programm aus der Programmliste, wird der Block bei den Anderen erstellt
''- NEW: NET: Uebermittlung der Startprogramme, die ein jeder Spieler zu Beginn haben sollte
''- NEW: NET: Mit dem Statusupdate im Netzwerk wird nun auch die Spielzeit und Geschwindigkeit synchronisiert
''- FIX: Im Interface wurde beim TV immer das Spielerprogramm im Tooltip angezeigt (gefixt)
'22.10.2006 Ronny
''- NEW: NET: Neue Netzwerkmethoden, Spielerpositionen werden an Clients uebermittelt. Server managed KI-Figuren
''       Spieler steuern jeweils ihre Figur... mit jedem "Klick" wird die Position an die anderen
''       Mitspieler uebermittelt (SendPlayerPosition)
''- FIX: Einige ausgelagerte Funktionen besassen keine Informationen ueber notwendige Bilder und Schriften
'21.10.2006
''- NEW: NET: Netzwerkmethoden um Spielernamen/Sendernamen, Farben etc. in den Spieleeinstellungen an alle Mitspieler
''       zu schicken.
''- CHG: NET: SendUDP sendet nur noch an einen Empfaenger, da der Stream nach jedem senden geleert wird (produzierte Fehler)
'20.10.2006 Ronny
''- NEW: Spielmenues: Startmenu, Netzwerklobby und Spieleinstellungen (Namen, Figuren, Chat usw.)
''- FIX: guielements.bmx: Objekt-Updateroutine gibt einen Klick erst beim Loslassen der Maustaste aus
''- CHG: GUIChatList sendet automatisiert die Chatnachricht an alle Teilnehmer
''- NEW: NET: TTVGNetwork-Klasse... komplettes Management von IPs, Pakethandling usw.
''       SendUDP als Hauptfunktion, sie sendet das Paket an alle Teilnehmer
''       Funktionen wie GotPacket_Join, GotPacket_AnnouncedGame usw. gekapselt um Uebersicht zu wahren
'19.10.2006 Ronny
''- NEW: Designs der GUIElemente DropDownList, Checkbox, Input, Scrollbalken (Blau-Orange-Design)
''- NEW: GUIobjecte besitzen nun ein "parentTGuiObject", dient der automatischen Verwaltung von bspweise
''       verknuepften Eingabefeldern im Chatfenster usw.
''- CHG: GUIListEntries benutzen das Teamfeld nun als Indikator fuer Spielerfarben (genutzt im Chat), im alten
''       Code (den ich fuer Knights'n'Blocks geschrieben hatte) war dort der Team-Text gespeichert, um den nun
''       aktuelleren Code nicht rueckportieren zu muessen, wird weiterhin als String gespeichert
''- NEW: Chat-Bild (Zusammensetzen von groesseren Rects mittels der "BlueRect"-Methode hat beim Toshiba-Notebook
''       meiner Freundin zu etwas Ruckeln verholfen - zumindest im DirectX-Modus (OGL blieb unberuehrt davon ;D)
''- CHG: guielements.bmx nun wieder per include statt import eingebunden (da sonst Referenz auf Player-Objekt
''       nicht vorhanden und somit einige Fehler bzw. unnoetig einzubauende Uebergabeparameter.
''       Eventuell koennte man alle GUI-Objekte der TGame-Klasse unterordnen um dieses Problem zu beheben.
'18.10.2006 Ronny
''- NEW: GUIInput hat nun die Faehigkeit, OverlayIcons einzubinden, genutzt fuer Player/channel/disk-Symbole
''       in Eingabefeldern
''- NEW: Eingabefeld im Startmenu fuer Sendernamen. Sendername und Spielername werden nun ins Spiel uebernommen
''       Raumbezeichner enthalten nun Spielernamen und Sendernamen
'15.10.2006 Ronny
''- NEW: LinuxNB mit Ubuntu eingerichtet (hat nen paar Tage gedauert ;D) und TVG kompiliert bekommen
''- NEW: SVN-Repository eingerichtet
''- CHG: Dateinamen und Ordnerbezeichnungen auf Kleinschreibung umgestellt
''- CHG: functions.bmx enthaelt nun den Code des Maxml-Modules, da unter Linux nicht kompilierbar gewesen (bzw. "Panel error")
'07.10.2006 Ronny
''- CHG: die ueber 50 wahllos von meiner Katze auf der Tastatur hinterlassenen Tastendruecke aus dem Quellcode entfernt
''- FIX: Geldanzeige nun von aktuellem Tag statt Tag 0 im Finanzenarray
''- CHG: Balken in der Finanzstatistik nun von Spielerfarbe abhaengig (statt konstant)
''- FIX: Werbung gibt nun auch Geld, wenn man am Vortag schon Bloecke davon gesendet hatte
''- NEW: Ueberschuessige Werbebloecke werden bei Erfuellung des Soll entfernt (also Block 3 von 2 usw.)
'06.10.2006 Ronny
''- NEW: Spielersymbole bei den Tueren: abhaengig von Spielerfarbe gemacht
''- NEW: Kanalbuttons (beim TVgeraet) klickbar gemacht, Tooltipps angepasst
''- NEW: Bueros tragen nun den Spielernamen im Titel
''- CHG: einzufaerbende Grafiken neudesigned/angepasst: Spielersymbole, Fahrstuhlschilder
''- FIX: colorfunctions.ColorizeTImage wertet nun bei animierten Bildern die Alphakanaele aus
''- CHG: das Inkludieren der Rooms-Quellen wurde nach hinten verschoben, da sonst die Spielersymbole noch nicht
''       vorhanden waren (werden nun zusammen mit anderen Spielergrafiken erstellt und eingefaerbt
'04.10.2006 Ronny
''- NEW: Von Spielern genutzte Farben koennen nicht von anderen ausgewaehlt werden
''- CHG: Farbauswahl der Spielerfarben angepasst (testweise per Tasten manuelle Korrektur eingefuehrt)
''- CHG: Alle Spielfiguren sind nun in den einzufaerbenden Bereichen so hell wie moeglich gehalten um nun
''       alle Farben zu ermoeglichen, vorher war helles Grau die Basis, was "grellere" Farben wie Gelb
''       verhinderte. Der Busen der Frauen war allgemein etwas zu hell (um noch als "plastisch" empfunden zu
''       werden). Deshalb sind Frauen von der Bekleidung etwas dunkler gezeichnet als Maenner.
''- NEW: Design der Senderbuttons am TV-Geraet, erstes Einbinden (noch ohne Funktion), neuer Wert bei
''       TInterface: ShowChannel - 0=aus 1=sender1 usw.
'02.10.2006 Ronny
''- NEW: Spielernamen-Eingabefeld im Startmenu (neudesigned und dem Ladebalken angepasst)
''- NEW: Spielfigurenauswahl im Startmenu + neue Funktion player.UpdateFigureBase(), welche eine Basisspielfigur
''       mit der Einfaerbung der Spielerfarben zurueckgibt
''- NEW: TGUIArrowButton, Aehnlich Button nur ohne Text, namensgebend ist der Pfeil (dir 0 = links, dir 1 = oben usw.)
''- NEW: colorfunctions.ColorizeTImage faerbt nun auch Animationen ein
''- CHG: CheckLoadImage und CheckLoadAnimImage haben nun Flag = -1 statt 0 (gab Probleme beim einfaeben und
''       automatischen Laden eines AnimImages aus einem Bild, was alle Frames enthielt und eingefaerbt wurde
'30.09.2006 Ronny
''- NEW: colorfunctions.ColorizeTImage() - kopiert das uebergebene TImage, faerbt die Kopie ein und liefert
''       diese zurueck. Dies spart das mehrfache uebergeben von Bildpfaden aus.
''       -> files.bmx darauf angepasst, spart bisher 20 von 170 Dateiladeoperationen aus.
''- NEW: Startmenu: erste Designstudien
''- NEW: GUIElemente (uebernommen aus meinem Projekt "Knights n Blocks"): TGUISlider, TGUIButton, TGUIList,
''       TGUICheckbox, TGUIRadiobutton, TGUIDropDown, TGUIInput, TGUIChat
''- NEW: Erste Versuche eine Netzwerkspielstruktur aufzubauen, grundliegende Funktionen zusammengestellt
''       -> netzwerktest.bmx
'28.09.2006 Ronny
''- CHG: Fontgroesse der Nachrichtentexte verkleinert und ein Dutzend neuer News getippt
'27.09.2006 Ronny
''- FIX: ProgrammePlan.CloneProgramme fuegt nun den Klon in eine Liste ein damit alle Wiederholungen der:
''- NEW: Filme (Serien nicht) nach der Ausstrahlung die Haelfte ihrer Aktualitaet verlieren
''- NEW: Finanzen: Diagramm ueber Kontostaende der Spieler
''- FIX: ein als "vergeigt" angezeigter Werbeblock zaehlt nun nicht mehr als "geschafft" wenn nachfolgende OK bekommen
''- NEW: Player.money wird zu Player.finances, welches Angaben ueber Ausgaben und Einnahmen enthaelt (7 Tage)
''       (fuer Finanzstatistik)... Kaufen und Verkaufen von Programmen und Werbeeinnahmen darauf angepasst
'26.09.2006 Ronny
''- NEW: Finanzanzeige (Statistiken): Grafik fuer diesen "Raum" geplant und designed
'25.09.2006 Ronny
''- NEW: Neue Funktion der ProgrammeCollection: RemoveOriginalContract(contract), ermittelt anhand des Adblock-
''       contract-Klons den Originalvertrag und lscht ihn aus der verfgbaren Spieler-Werbeliste
''- CHG: "landesweite" Prozente verlaufen nun in Kurven und sind etwas abhngiger von der Sendezeit (Primetime)
'24.09.2006 Ronny
''- NEW: "landesweite" Prozente, wieviele Leuts maximal TV gucken koennen (leicht an Uhrzeit angepasst)
''- CHG: Minimal MarktanteilProzente der Werbebloecke angepasst
''- NEW: "geschaffte" Werbung bringt Geld aufs Spielerkonto
''- NEW: Spieler starten mit einem Sendemast in Bayern (Nhe zueinander)
''- NEW: erste (primitive) Einschaltquotenberechnung mit kleinem Audienceflow
''       -> neue Methoden der Playerklassen zur Berechnung von Quote und Marktanteil
''- NEW: Abfangen spezieller Zeiten wie 01:00, 01:05 und 01:55 (News,Film,Werbung) -> auslsen spezieller Funktionen
''- NEW: Werbebloecke bekommen nun Anzeige, ob "OK" oder "botched" (vergeigt -> "-----")
'23.09.2006 Ronny
''- NEW: Filme im Filmmakler ein- und verkaufbar.. nicht finanzierbare Filme werden "ausgegraut"
''       ansonsten verhaelt sich der Filmmakler wie der Werbemakler
'22.09.2006 Ronny
''- FIX: TDragAndDrop.Drop() setzte gleichzeitig used=1 ... CanDrop()-Methode eingefuehrt
''- NEW: Werbevertraege koennen auf den Aktenkoffer gedragged werden, naechste freie Stelle wird genutzt
'21.09.2006 Ronny
''- NEW: Ladebildschirm... Anzeige der Dateien, die aktuell geladen werden (momentan nur Bilder)
''- NEW: beim verlassen des Werbemaklers wir die Funktion TContractBlocks.ContractsToPlayer(game.playerid) aufgerufen
'20.09.2006 Ronny
''- NEW: Wird ein Werbevertrag in den Koffer gelegt und "W" gedrueckt, dann wird er "unterzeichnet" und gehoert
''       dem Spieler, ein neuer Vertrag wird im Maklerbuero angelegt
'19.09.2006 Ronny
''- NEW: vorhandene Werbevertraege werden im Koffer angezeigt (maximal game.maxContractsAllowed Vertraege)
''- NEW: Werbemakler-Vertraege sind per DND in den Koffer legbar
''- NEW: Werbemakler-Vertraege: Info wird angezeigt bei MouseOver
'18.09.2006 Ronny
''- CHG: Hinweistafeln in Objekte gekapselt (wegen DragnDrop usw.), 0:00 wird Position resettet
''- NEW: Fahrstuhl-Plan / Hinweistafel, testweise eingebundene Raumschilder (noch keine Objekte)
''- CHG: Hinweistafelhintergrund und Tafeln neudesigned
'17.09.2006 Ronny
''- NEW: Chef: Zigarre qualmt und qualmt und qualmt - Partikelrauch
''- NEW: TRooms: Tueren werden nun "offen" dargestellt, bevor eine Figur den Raum betritt
''- FIX: Playererstellung: SpielerID nicht an Adblock-Erstellung uebergeben (alle Blocks gehrten Spieler 1)
''- FIX: TDatabase: Bug beim lesen der News (keine Headnews vorhanden, nur Chains)
''- TNews: zeigt momentan nur die Chain 0 (Headnews an) (Pool fuer alle Spieler muss noch erstellt werden)
'16.09.2006 Ronny
''- Rechtsklick in PPlaner,Stationmap und Newsplaner fuehrt nun in die Hauptraeume statt Gebaeude
''- KI-Figuren suchen sich nur noch neue Ziele, wenn nicht vor oder im Fahrstuhl
''- spielfigur_frau6.png - Rock in Zwinkerframe war "verrutscht"
''- Mond: falsche Position bei 18 Uhr gesetzt... Mond verschwand bei Tag 2
''- Fahrstuhl und Figuren: Bewegunggeschwindigkeit erhoeht
''- Abfrage eingebunden, ob Programm/Werbebloecke-Besitzer=User, doppelte Anzeige von Infosheets unterbunden
'14.09.2006 Ronny
''- Newsraum: Genre-Buttons von TButtons abgeleitet und eingebunden (besitzen Tooltips die selbststaendig
''  verwaltet werden)
''- TSprites eingefuehrt (fuer statische, nichtanimierte Bilder)
''- Wolken im Hochhaus eingebunden
''- Spielfiguren-Grafiken, alle erneuert und mit Zwinkerframe und zwei weiteren Bewegungsframes ausgestattet,
''  Spielerfiguren gibt es weiblich und maennlich, jeweils euro, asia und afro-Style. Doppelte aussortiert
'13.09.2006 Ronny
''- TVProgramme nun mit "owner", dies erlaubt das betrachten (mit Schluessel) von gegnerischer Programmplanung,
''  und das gemeinsame verwalten in einer Liste... beim Netzwerkspiel wird hierfuer wohl eine Synchronisierung
''  genutzt werden muessen (altes raus, neues rein)
''- Tasten 1-4 schalten zwischen den 4 Spielern um
''- Rooms ueberarbeitet, statt String nun Objekt "Room", neue Methode GetRoom, liefert TRooms zurueck,
''  dessen Beschreibung und Besitzer mit den Parametern uebereinstimmen (PPlaner von Spieler2 usw.)
''- Tstationmap in stationmap.bmx ausgegliedert
''- einige Images in files ausgelagert, hierfuer Farbfunktionen aus TFunctions in TColorFunctions ausgegliedert
''  und diese in functions.bmx eingebunden
''- keymanager.bmx nun import statt include
''- files.bmx nun import statt include
''- CalculateRange: Berechnet nun die Reichweite anhand einer Bitmaske, auf der alle Reichweiten
''                  gezeichnet werden, diese wird als Maske genutzt um die Gesamtreichweite zu berechnen. Die
''                  Funktion von Falke&Donnervogel hat schneidende Reichweiten falsch behandelt (neuer
''                  Kreis ignoriert und nicht anteilig hinzuaddiert)
'12.09.2006 - Pierre&Donnervogel
''Berechnung der Gesamtreichweite (inkl. Ueberlappung der Sendekreise)
''-> TStationMap.calculateDistance:Double(x1:Int, y1:Int, x2:Int, y2:Int)
''-> TStationMap.calculateRange:Int(mausX:Int, mausY:Int, radius:Int, x:Int, y:Int,width:Int, height:Int)
'08.09.2006
'Buttonklasse fuer Stationmap erstellt
'07.09.2006
''stationmap eingebunden, Antenne neudesigned
''nachts: Kollisionen Kollisionspixel(bei Maus) und Bundeslaender in Stationmap eingebunden
''        blauen Rahmen als Funktion eingebunden und bei Stationmap gezeichnet (inkl. Bundeslandtext)
'06.09.2006
''neue Pflanzen gemalt und eingebunden, Ufo-Bewegung verbessert, bei Mond das gleiche
'05.09.2006
''Ufo gemalt und eingebunden + Beammodus
'04.09.2006
''fahrstuhlbug behoben, fahrstuhl besitzt nun passagierid, figuren haben auch eine id,
''zuordnung nun moeglich, abfragen ueber "im fahrstuhl" vereinfacht.
