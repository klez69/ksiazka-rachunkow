import Foundation

struct MiesiacGrupa: Identifiable {
    let id: String
    let etykieta: String
    let porzadek: Int
    let pozycje: [Rachunek]
}

enum Grupowanie {
    private static let miesiace = [
        "Styczeń", "Luty", "Marzec", "Kwiecień", "Maj", "Czerwiec",
        "Lipiec", "Sierpień", "Wrzesień", "Październik", "Listopad", "Grudzień"
    ]

    static func pogrupuj(_ rachunki: [Rachunek]) -> [MiesiacGrupa] {
        var kubelki: [String: (etykieta: String, porzadek: Int, pozycje: [Rachunek])] = [:]

        for rachunek in rachunki {
            let (klucz, etykieta, porzadek) = kluczDlaRachunku(rachunek)
            var kubelek = kubelki[klucz] ?? (etykieta, porzadek, [])
            kubelek.pozycje.append(rachunek)
            kubelki[klucz] = kubelek
        }

        return kubelki.map { klucz, wartosc in
            let posortowane = wartosc.pozycje.sorted { a, b in
                (a.data ?? .distantFuture) < (b.data ?? .distantFuture)
            }
            return MiesiacGrupa(id: klucz, etykieta: wartosc.etykieta, porzadek: wartosc.porzadek, pozycje: posortowane)
        }.sorted { $0.porzadek < $1.porzadek }
    }

    private static func kluczDlaRachunku(_ rachunek: Rachunek) -> (klucz: String, etykieta: String, porzadek: Int) {
        guard let data = rachunek.data else {
            return ("brak-daty", "Bez terminu", Int.max)
        }
        let kalendarz = Calendar.current
        let rok = kalendarz.component(.year, from: data)
        let miesiac = kalendarz.component(.month, from: data)
        let klucz = "\(rok)-\(miesiac)"
        let etykieta = "\(miesiace[miesiac - 1]) \(rok)"
        let porzadek = rok * 12 + miesiac
        return (klucz, etykieta, porzadek)
    }
}
