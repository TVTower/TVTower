# Powód podziału plików

Lokalizacja została zrestrukturyzowana w celu uproszczenia konserwacji.
Dla każdego tematu istnieje jeden katalog zawierający słowniki.
Struktura plików w każdym katalogu ma być identyczna, co ułatwia porównywanie i tłumaczenie.

Brakujące tłumaczenie zaczyna się od symbolu komentarza (`#`).
Prawdziwe komentarze zaczynają się od dwóch symboli komentarza (`##Comment`).

Kodowanie plików to UTF-8.

# Tłumaczenie

Jeśli to możliwe, nie tylko szukaj brakujących wpisów oznaczonych `#`, ale także sprawdź istniejące.
Możliwe, że niektóre nadal zawierają angielskie tłumaczenia.

...i nie zapomnij usunąć symboli komentarza po przetłumaczeniu.

# Dodawanie nowego klucza

Podczas dodawania nowego klucza, powinien on zostać dodany do wszystkich plików w tej samej linii.
Dla plików językowych bez natychmiastowego tłumaczenia, należy utworzyć komentarz (`#NEW_KEY =`).
Dzięki temu od razu widać, że nadal brakuje tłumaczenia.

Używanie spacji zamiast tabulatorów i wyrównywanie wpisów w bloku poprawia czytelność.

# Przenoszenie lub usuwanie klucza

Ponownie, zmień wszystkie pliki językowe w tym samym czasie, aby struktura plików dla motywu pozostała identyczna.

# Dodawanie nowego języka

* udostępnienie obrazu dla potrzebnej flagi
    * przenieś odpowiedni plik png z `res/gfx/gui/flags/currently_unused` do `res/gfx/gui/flags`.
    * dodać pasujący wpis w `config/gui_languageflags.xml`
* dodać pliki lokalizacyjne
    * we wszystkich podkatalogach `res/lang` skopiuj `xxx_en.txt` do pliku z odpowiednim kodem kraju (np. `gen_settings_en.txt` do `gen_settings_cz.txt`)
    * zmienić tłumaczenia w nowych plikach

Zaleca się rozpoczęcie od `gen_settings`.
Podczas uruchamiania nowej gry i zmiany języka, natychmiast zobaczysz wprowadzone zmiany.