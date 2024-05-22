# Hintergrund der Aufteilung

Die Lokalisierung wurde auf mehrere Dateien aufgeteilt, um die Pflege der Daten zu erleichtern.
Pro Thema gibt es ein Verzeichnis.
Die Struktur der Dateien pro Verzeichnis soll identisch sein, um sie leicht vergleichen und Übersetzungen anfertigen zu können.

Eine fehlende Übersetzung beginnt mit einem Kommentarzeichen (`#`).
Echte Kommentare sind mit zwei Kommentarzeichen markiert (`##Kommentar`).

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