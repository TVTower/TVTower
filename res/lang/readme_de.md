# Hintergrund der Aufteilung

Die Lokalisierung wurde auf mehrere Dateien aufgeteilt, um die Pflege der Daten zu erleichtern.
Pro Thema gibt es ein Verzeichnis.
Die Struktur der Dateien pro Verzeichnis soll identisch sein, um sie leicht vergleichen und Übersetzungen anfertigen zu können.

Eine fehlende Übersetzung beginnt mit einem Kommentarzeichen (`#`).
Echte Kommentare sind mit zwei Kommentarzeichen markiert (`##Kommentar`).

Das Datei-Encoding ist UTF-8

# Übersetzen

Wenn möglich sollten nicht nur durch Kommentarzeichen (`#`) markierten fehlenden Einträge bearbeitet sondern auch die Bestandseinträge korrekturgelesen werden.
Es ist möglich, dass dort in Einzelfällen noch englische Übersetzungen stehen.

... nicht vergessen nach dem Übersetzen die Kommentarzeichen zu entfernen.

# Neuen Schlüssel hinzufügen

Wenn ein neuer Schlüssel hinzugefügt wird, soll dieser in sämtlichen Sprachdateien an derselben Stelle ergänzt werden.
Für die Sprachen ohne sofortige Übersetzung wird er dafür auskommentiert (`#NEW_KEY   = `).
Durch die Verwendung des Kommentars ist sofort ersichtlich, dass hier nocheine Übersetzung benötigt wird.

Die Verwendung von Leerzeichen statt Tabulatoren und die Ausrichtung der Gleichheitszeichen innerhalb eines Blocks soll eine gute Lesbarkeit erreicht werden.

# Schlüssel entfernen/verschieben

Auch hier soll die Änderung für sämtliche Sprachdateien gemacht werden, damit die Struktur der Dateien identisch bleibt.

# Neue Sprache hinzufügen

* Grafik für die benötigte Flagge integrieren
    * verschiebe die passende png-Datei von `res/gfx/gui/flags/currently_unused` nach `res/gfx/gui/flags`
    * ergänze einen passenden Eintrag in `config/gui_languageflags.xml`
* Übersetzungsdateien hinzufügen
    * in den Unterverzeichnissen von `res/lang` jeweils die `xxx_en.txt` mit dem passenden Länderkürzel kopieren (z.B. `gen_settings_en.txt` nach `gen_settings_cz.txt`)
    * in den neuen Dateien die Übersetzungen anpassen

Es ist sinnvoll, mit `gen_settings` zu beginnen, da man bei Spielstart und dem Wechsel der Sprache sofort die Anpassungen sieht.