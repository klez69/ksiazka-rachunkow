# Książka Rachunków — specyfikacja projektu

## Co to jest i dla kogo
Prosta aplikacja na iPhone i Maca do zapisywania rachunków/faktur (jedna osoba, bez logowania, bez internetu). Dane trzymane tylko na urządzeniu użytkownika.

## Stack technologiczny
- **Język:** Swift
- **UI:** SwiftUI (jeden kod na iOS i macOS — "multiplatform app")
- **Baza danych:** SwiftData (wbudowana w iOS/macOS, zapisuje dane lokalnie na urządzeniu, bez serwera)
- **Środowisko:** Xcode 27
- **Backend / hosting:** brak — appka działa w 100% offline
- **Minimalne wersje systemu:** iOS 18+, macOS 15+ (żeby SwiftData działało stabilnie)
- **Fonty:** Fraunces, IBM Plex Sans, IBM Plex Mono (darmowe, Google Fonts) — pliki dołączone do projektu, appka działa offline, bez pobierania fontów z internetu

## Design
Appka ma wyglądać jak ten webowy artefakt, przeniesiony na SwiftUI — ciepły, "papierowy" styl, nie typowy jaskrawy design appki.

- **Kolory (jasny motyw):** tło `#f4f2ec`, karty/wiersze `#fffefb`, tekst główny `#1d2420`, tekst przygaszony `#55605a`, linie `#ddd7c8`, zielony akcent `#3a5c4d` (ciemniejszy `#2a4438` na hover/aktywne), tło akcentu `#e2ebe4`, kolor ostrzeżenia (zaległe/braki) `#a8402c`, kolor "zrobione" `#7c8a80`
- **Kolory (ciemny motyw):** tło `#141815`, karty `#1a1f1b`, tekst `#eae8e0`, przygaszony `#a8ada4`, linie `#33392f`, akcent `#7fa78e`, ostrzeżenie `#d98872` — appka ma się sama przełączać z systemem (jasny/ciemny)
- **Fonty:** nagłówki (nazwa appki, tytuły sekcji) — serif **Fraunces**; treść i formularze — **IBM Plex Sans**; kwoty, daty, etykiety/tagi — monospace **IBM Plex Mono** (te same fonty co w artefakcie, dołączone jako pliki do projektu Xcode)
- **Układ listy:** rachunki pogrupowane w sekcje po miesiącu terminu (np. "Wrzesień 2026"), każda sekcja to karta z zaokrąglonymi rogami i cienkim obramowaniem, delikatny cień
- **Wiersz rachunku:** okrągły checkbox po lewej (kliknięcie = oznacz opłacony, zielone wypełnienie z haczykiem), nazwa + mała etykieta źródła ("ręcznie" / "skan") + termin, kwota wyrównana do prawej w monospace; opłacone pozycje — przekreślone i wyszarzone, domyślnie ukryte pod przyciskiem "Pokaż zapłacone (N)"
- **Pasek podsumowania** na górze: 3 kafelki — "Do zapłaty" (liczba), "Suma zaległych" (kwota), "Najbliższy termin" (data)
- **Formularz dodawania/edycji:** karta na dole ekranu (na iPhone: pełnoekranowy arkusz/sheet), pola z etykietami wielkimi literami nad polem, przycisk zapisu w formie zielonej "pigułki" (pill button)
- **Akcje na wierszu:** na iPhone — przesunięcie palcem (swipe) pokazuje "Edytuj"/"Usuń" (odpowiednik ikon widocznych na hover w wersji webowej)

## Ekrany i przepływ
1. **Lista rachunków** (ekran główny)
   - Pokazuje wszystkie rachunki, najnowsze na górze
   - Suma rachunków nieopłaconych na górze listy
   - Przycisk "+" do dodania nowego rachunku ręcznie
   - Przycisk "Skanuj" do dodania rachunku przez skaner (patrz niżej)
   - Kliknięcie w rachunek → szczegóły / edycja
   - Przesunięcie w lewo (swipe) → usuń
2. **Dodaj / Edytuj rachunek** (formularz w oknie modalnym)
   - Pola: nazwa/kontrahent, kwota, data, kategoria (np. prąd, internet, czynsz, inne), status (opłacony / nieopłacony), notatka (opcjonalnie), zdjęcie skanu (opcjonalne, miniatura)
   - Dwa przełączniki (domyślnie włączone, widoczne gdy rachunek jest nieopłacony i ma datę): "Dodaj do Kalendarza" i "Dodaj przypomnienie"
   - Przycisk "Zapisz" i "Anuluj"
3. **Szczegóły rachunku**
   - Podgląd wszystkich danych + zdjęcie skanu (jeśli jest, kliknięcie → powiększenie)
   - Przycisk "Edytuj" i "Usuń"
4. **Skaner rachunków** (nowy ekran)
   - **iPhone:** wbudowany skaner dokumentów (VisionKit) — robi zdjęcie rachunku aparatem, sam wykrywa krawędzie kartki i prostuje obraz, jak w Notatkach Apple
   - **Mac:** brak skanera aparatem — zamiast tego wybór istniejącego zdjęcia/PDF z dysku (lub przeciągnięcie pliku)
   - Po zeskanowaniu: aplikacja spróbuje **automatycznie odczytać kwotę i datę** z tekstu na rachunku (rozpoznawanie tekstu, wbudowane w iOS/macOS, offline, bez wysyłania zdjęcia gdziekolwiek)
   - Odczytane dane wypełniają formularz "Dodaj rachunek" (kwota, data) — użytkownik zawsze może je poprawić ręcznie przed zapisaniem, bo rozpoznawanie nie zawsze będzie idealne
   - Zeskanowane zdjęcie zapisuje się razem z rachunkiem jako załącznik
5. **Kalendarz i Przypomnienia** (dzieje się automatycznie przy zapisie, nie osobny ekran)
   - Przy zapisaniu nieopłaconego rachunku z datą, jeśli przełączniki są włączone, appka:
     - tworzy **wydarzenie w Kalendarzu** systemowym (na dzień terminu płatności, "cały dzień", tytuł = nazwa rachunku + kwota)
     - tworzy **przypomnienie w Przypomnieniach** systemowych (z terminem = data rachunku), żeby dostać powiadomienie
   - Appka pamięta, które wydarzenie/przypomnienie należy do którego rachunku, więc:
     - edycja daty/kwoty rachunku → aktualizuje istniejące wpisy (nie tworzy duplikatów)
     - oznaczenie rachunku jako **opłacony** → usuwa wydarzenie z Kalendarza i odznacza/usuwa przypomnienie
     - usunięcie rachunku → usuwa też powiązane wydarzenie i przypomnienie
   - Wszystko dzieje się lokalnie przez systemowe aplikacje Kalendarz/Przypomnienia (Apple), bez żadnej wysyłki danych na zewnątrz

## Model danych (jedna tabela, lokalnie w SwiftData)
`Rachunek`:
- `id` — unikalny identyfikator
- `nazwa` — tekst (np. "Prąd — wrzesień")
- `kwota` — liczba (PLN)
- `data` — data wystawienia/terminu
- `kategoria` — tekst (z listy: Prąd, Gaz, Woda, Internet, Telefon, Czynsz, Inne)
- `status` — opłacony / nieopłacony
- `notatka` — tekst opcjonalny
- `zdjecieSkanu` — plik obrazu zapisany lokalnie obok bazy danych (opcjonalny)
- `idWydarzeniaKalendarza` — techniczny identyfikator wydarzenia w Kalendarzu (opcjonalny, do aktualizacji/usuwania)
- `idPrzypomnienia` — techniczny identyfikator wpisu w Przypomnieniach (opcjonalny, do aktualizacji/usuwania)

## Usługi zewnętrzne
Brak. Żadnego Supabase, Stripe, kont, internetu — wszystko lokalnie na urządzeniu. Rozpoznawanie tekstu ze skanu też działa offline (wbudowana funkcja systemu iOS/macOS), zdjęcie nigdzie nie jest wysyłane.

## Uprawnienia potrzebne od użytkownika
- **Aparat** (iPhone) — do skanowania rachunków. Aplikacja poprosi o zgodę przy pierwszym użyciu skanera; bez zgody skaner nie zadziała, ale dodawanie ręczne — tak.
- **Kalendarz** — do tworzenia wydarzeń z terminami płatności. Bez zgody przełącznik "Dodaj do Kalendarza" po prostu nic nie zrobi (appka nie przestaje działać).
- **Przypomnienia** — do tworzenia przypomnień o płatności. Bez zgody przełącznik "Dodaj przypomnienie" po prostu nic nie zrobi.
- Appka poprosi o te dwie zgody dopiero gdy użytkownik pierwszy raz zapisze rachunek z włączonym przełącznikiem (nie od razu przy starcie).

## Co znaczy "zrobione" dla pierwszej wersji (v1)
- Projekt buduje się bez błędów w Xcode 27 (iOS Simulator + Mac)
- Można dodać, edytować, usunąć i przejrzeć rachunek
- Można zeskanować rachunek na iPhonie i zaimportować zdjęcie/PDF na Macu
- Rozpoznawanie tekstu proponuje kwotę i datę po skanie (można poprawić ręcznie)
- Zapisanie nieopłaconego rachunku z datą tworzy wpis w Kalendarzu i w Przypomnieniach (gdy przełączniki włączone i zgoda dana)
- Oznaczenie rachunku jako opłacony usuwa powiązany wpis z Kalendarza i Przypomnień
- Dane (w tym zdjęcia skanów) zostają po zamknięciu i ponownym otwarciu aplikacji
- Lista pokazuje sumę nieopłaconych rachunków
- Działa i na iPhonie (symulator), i na Macu

## Poza zakresem v1 (na później, jeśli będzie potrzebne)
- Synchronizacja między urządzeniami (iCloud)
- Automatyczne rozpoznawanie kategorii/kontrahenta ze skanu (tylko kwota + data w v1)
- Wykresy i statystyki wydatków
