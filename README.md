# Książka Rachunków

Prosta aplikacja na iPhone i Maca do zapisywania rachunków/faktur. Jedna osoba, bez logowania, bez internetu — wszystkie dane trzymane lokalnie na urządzeniu.

## Funkcje

- Lista rachunków pogrupowana po miesiącach, z sumą zaległych i najbliższym terminem
- Dodawanie / edycja / usuwanie rachunków (nazwa, kwota, data, kategoria, status, notatka)
- Skaner rachunków: na iPhonie aparatem (VisionKit), na Macu przez wybór zdjęcia/PDF — z automatycznym odczytem kwoty i daty (Vision OCR, offline)
- Integracja z Kalendarzem i Przypomnieniami: nieopłacony rachunek z terminem dodaje wpis do obu, opłacenie go usuwa wpis
- Jasny/ciemny motyw, zgodny z systemem

## Stack

- Swift + SwiftUI (jeden kod na iOS i macOS)
- SwiftData (lokalna baza danych, bez serwera)
- VisionKit / Vision (skaner + OCR)
- EventKit (Kalendarz, Przypomnienia)
- Xcode 27, iOS 18+ / macOS 15+

Appka działa w 100% offline — nie ma backendu, kont, żadnych usług trzecich.

## Uruchomienie

1. Otwórz `KsiazkaRachunkow.xcodeproj` w Xcode
2. Wybierz cel: symulator/Mac albo własny iPhone (dla telefonu: zakładka **Signing & Capabilities** → wybierz swój **Team**/Apple ID)
3. ▶ Run

Przy uruchamianiu na fizycznym iPhonie z darmowym Apple ID appka wymaga ponownego zainstalowania co 7 dni (limit Apple dla kont bez płatnego programu Developer).

## Struktura projektu

```
KsiazkaRachunkow/
  Models/         — model danych (Rachunek, grupowanie po miesiącach)
  Views/          — ekrany SwiftUI (lista, formularz, szczegóły, skaner)
  Services/       — logika: OCR, Kalendarz/Przypomnienia, import dokumentów
  DesignSystem/   — kolory i typografia
  Assets.xcassets — kolory (jasny/ciemny motyw) i ikona appki
```

## Uwaga o designie

Kolorystyka i układ są wzorowane na webowym prototypie appki (ciepła, "papierowa" paleta, serif nagłówki, monospace liczby). Ze względów praktycznych appka używa wbudowanych fontów systemowych (serif / monospaced) zamiast pobieranych fontów Fraunces / IBM Plex — wizualnie bardzo zbliżonych, ale bez potrzeby dołączania plików fontów do repozytorium.

## Status

Wersja robocza (v1) — pełna specyfikacja w [project_specs.md](project_specs.md).
