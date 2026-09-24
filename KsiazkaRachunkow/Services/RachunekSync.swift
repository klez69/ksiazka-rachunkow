import Foundation

/// Spina zapisanie rachunku z Kalendarzem/Przypomnieniami: dodaje, aktualizuje albo usuwa
/// powiązane wpisy, w zależności od statusu i przełączników na rachunku.
/// Zwraca listę czytelnych ostrzeżeń, jeśli coś się nie udało (pusta lista = wszystko OK).
@MainActor
enum RachunekSync {

    @discardableResult
    static func synchronizuj(_ rachunek: Rachunek) async -> [String] {
        if rachunek.oplacony {
            usunPowiazania(rachunek)
            return []
        }

        guard let data = rachunek.data else { return [] }

        var ostrzezenia: [String] = []

        if rachunek.dodajDoKalendarza {
            if await CalendarReminderService.poprosOZgodeNaKalendarz() {
                do {
                    rachunek.idWydarzeniaKalendarza = try CalendarReminderService.zapiszWydarzenie(
                        dlaRachunku: rachunek.nazwa,
                        kwota: rachunek.kwota,
                        data: data,
                        istniejacyIdentyfikator: rachunek.idWydarzeniaKalendarza
                    )
                } catch {
                    ostrzezenia.append(error.localizedDescription)
                }
            } else {
                ostrzezenia.append("Brak dostępu do Kalendarza. Włącz go w Ustawieniach → Prywatność i bezpieczeństwo → Kalendarze.")
            }
        } else if let id = rachunek.idWydarzeniaKalendarza {
            CalendarReminderService.usunWydarzenie(identyfikator: id)
            rachunek.idWydarzeniaKalendarza = nil
        }

        if rachunek.dodajPrzypomnienie {
            if await CalendarReminderService.poprosOZgodeNaPrzypomnienia() {
                do {
                    rachunek.idPrzypomnienia = try CalendarReminderService.zapiszPrzypomnienie(
                        dlaRachunku: rachunek.nazwa,
                        kwota: rachunek.kwota,
                        data: data,
                        istniejacyIdentyfikator: rachunek.idPrzypomnienia
                    )
                } catch {
                    ostrzezenia.append(error.localizedDescription)
                }
            } else {
                ostrzezenia.append("Brak dostępu do Przypomnień. Włącz go w Ustawieniach → Prywatność i bezpieczeństwo → Przypomnienia.")
            }
        } else if let id = rachunek.idPrzypomnienia {
            CalendarReminderService.usunPrzypomnienie(identyfikator: id)
            rachunek.idPrzypomnienia = nil
        }

        return ostrzezenia
    }

    static func usunPowiazania(_ rachunek: Rachunek) {
        if let id = rachunek.idWydarzeniaKalendarza {
            CalendarReminderService.usunWydarzenie(identyfikator: id)
            rachunek.idWydarzeniaKalendarza = nil
        }
        if let id = rachunek.idPrzypomnienia {
            CalendarReminderService.usunPrzypomnienie(identyfikator: id)
            rachunek.idPrzypomnienia = nil
        }
    }
}
