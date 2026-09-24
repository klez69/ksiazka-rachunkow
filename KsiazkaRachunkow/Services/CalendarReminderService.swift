import Foundation
import EventKit

enum BladSynchronizacji: LocalizedError {
    case brakZgody(String)
    case brakKalendarza(String)
    case zapisNieUdany(String)

    var errorDescription: String? {
        switch self {
        case .brakZgody(let co): "Brak dostępu do \(co). Włącz go w Ustawieniach → Prywatność i bezpieczeństwo → \(co)."
        case .brakKalendarza(let co): "Nie znaleziono żadnego \(co) na tym urządzeniu (otwórz appkę systemową przynajmniej raz, żeby ją skonfigurować)."
        case .zapisNieUdany(let szczegoly): "Nie udało się zapisać: \(szczegoly)"
        }
    }
}

/// Tworzy/aktualizuje/usuwa wydarzenie w Kalendarzu i wpis w Przypomnieniach
/// powiązany z danym rachunkiem. Wszystko lokalnie przez systemowy EventKit.
@MainActor
enum CalendarReminderService {

    private static let store = EKEventStore()

    static func poprosOZgodeNaKalendarz() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    static func poprosOZgodeNaPrzypomnienia() async -> Bool {
        (try? await store.requestFullAccessToReminders()) ?? false
    }

    /// Tworzy nowe wydarzenie lub aktualizuje istniejące (po `identyfikator`). Zwraca identyfikator wydarzenia.
    static func zapiszWydarzenie(dlaRachunku nazwa: String, kwota: Double, data: Date, istniejacyIdentyfikator: String?) throws -> String {
        let event: EKEvent
        if let id = istniejacyIdentyfikator, let istniejace = store.event(withIdentifier: id) {
            event = istniejace
        } else {
            event = EKEvent(eventStore: store)
            guard let kalendarz = store.defaultCalendarForNewEvents ?? store.calendars(for: .event).first(where: \.allowsContentModifications) else {
                throw BladSynchronizacji.brakKalendarza("kalendarza")
            }
            event.calendar = kalendarz
        }
        event.title = "\(nazwa) — \(formatujKwote(kwota)) zł"
        event.isAllDay = true
        event.startDate = data
        event.endDate = data

        do {
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw BladSynchronizacji.zapisNieUdany(error.localizedDescription)
        }
    }

    static func usunWydarzenie(identyfikator: String) {
        guard let event = store.event(withIdentifier: identyfikator) else { return }
        try? store.remove(event, span: .thisEvent)
    }

    /// Tworzy nowe przypomnienie lub aktualizuje istniejące. Zwraca identyfikator przypomnienia.
    static func zapiszPrzypomnienie(dlaRachunku nazwa: String, kwota: Double, data: Date, istniejacyIdentyfikator: String?) throws -> String {
        let reminder: EKReminder
        if let id = istniejacyIdentyfikator,
           let istniejace = store.calendarItem(withIdentifier: id) as? EKReminder {
            reminder = istniejace
        } else {
            reminder = EKReminder(eventStore: store)
            guard let lista = store.defaultCalendarForNewReminders() ?? store.calendars(for: .reminder).first(where: \.allowsContentModifications) else {
                throw BladSynchronizacji.brakKalendarza("listy w Przypomnieniach")
            }
            reminder.calendar = lista
        }
        reminder.title = "Zapłać: \(nazwa) — \(formatujKwote(kwota)) zł"
        let komponenty = Calendar.current.dateComponents([.year, .month, .day], from: data)
        reminder.dueDateComponents = komponenty
        reminder.addAlarm(EKAlarm(absoluteDate: data))

        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            throw BladSynchronizacji.zapisNieUdany(error.localizedDescription)
        }
    }

    static func usunPrzypomnienie(identyfikator: String) {
        guard let reminder = store.calendarItem(withIdentifier: identyfikator) as? EKReminder else { return }
        try? store.remove(reminder, commit: true)
    }

    private static func formatujKwote(_ kwota: Double) -> String {
        String(format: "%.2f", kwota)
    }
}
