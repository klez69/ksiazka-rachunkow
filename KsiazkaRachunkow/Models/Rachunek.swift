import Foundation
import SwiftData

enum Kategoria: String, Codable, CaseIterable, Identifiable {
    case prad = "Prąd"
    case gaz = "Gaz"
    case woda = "Woda"
    case internet = "Internet"
    case telefon = "Telefon"
    case czynsz = "Czynsz"
    case inne = "Inne"

    var id: String { rawValue }
}

@Model
final class Rachunek {
    var nazwa: String
    var kwota: Double
    var data: Date?
    var kategoriaRaw: String
    var oplacony: Bool
    var notatka: String
    @Attribute(.externalStorage) var zdjecieSkanu: Data?
    var idWydarzeniaKalendarza: String?
    var idPrzypomnienia: String?
    var dataUtworzenia: Date
    var dodajDoKalendarza: Bool
    var dodajPrzypomnienie: Bool

    init(
        nazwa: String,
        kwota: Double,
        data: Date? = nil,
        kategoria: Kategoria = .inne,
        oplacony: Bool = false,
        notatka: String = "",
        zdjecieSkanu: Data? = nil,
        dodajDoKalendarza: Bool = true,
        dodajPrzypomnienie: Bool = true
    ) {
        self.nazwa = nazwa
        self.kwota = kwota
        self.data = data
        self.kategoriaRaw = kategoria.rawValue
        self.oplacony = oplacony
        self.notatka = notatka
        self.zdjecieSkanu = zdjecieSkanu
        self.idWydarzeniaKalendarza = nil
        self.idPrzypomnienia = nil
        self.dataUtworzenia = Date()
        self.dodajDoKalendarza = dodajDoKalendarza
        self.dodajPrzypomnienie = dodajPrzypomnienie
    }

    var kategoria: Kategoria {
        get { Kategoria(rawValue: kategoriaRaw) ?? .inne }
        set { kategoriaRaw = newValue.rawValue }
    }
}
