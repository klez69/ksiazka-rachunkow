import Foundation

/// Wspólne reguły wyłuskiwania kwoty i daty z rozpoznanego tekstu —
/// używane zarówno przy OCR całego zdjęcia, jak i przy rozpoznawaniu na żywo (dotknięcie tekstu).
enum TekstRozpoznawania {

    static func kwotaZLinii(_ linie: [String]) -> Double? {
        var kandydaci: [Double] = []
        for linia in linie {
            kandydaci.append(contentsOf: kwotyWLinii(linia))
        }
        // najczęściej najwyższa kwota na paragonie to suma "do zapłaty"
        return kandydaci.max()
    }

    static func kwotaZTekstu(_ tekst: String) -> Double? {
        kwotyWLinii(tekst).max()
    }

    static func dataZLinii(_ linie: [String]) -> Date? {
        for linia in linie {
            if let data = dataZTekstu(linia) { return data }
        }
        return nil
    }

    static func dataZTekstu(_ tekst: String) -> Date? {
        let formaty = ["dd.MM.yyyy", "dd-MM-yyyy", "dd/MM/yyyy", "yyyy-MM-dd"]
        let wzorzec = try? NSRegularExpression(
            pattern: #"\b(\d{1,2}[.\-/]\d{1,2}[.\-/]\d{4}|\d{4}-\d{2}-\d{2})\b"#
        )
        let zakres = NSRange(tekst.startIndex..<tekst.endIndex, in: tekst)
        guard let match = wzorzec?.firstMatch(in: tekst, range: zakres),
              let r = Range(match.range, in: tekst) else { return nil }
        let dopasowanie = String(tekst[r])
        for format in formaty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.locale = Locale(identifier: "pl_PL")
            if let data = dateFormatter.date(from: dopasowanie) {
                return data
            }
        }
        return nil
    }

    private static func kwotyWLinii(_ linia: String) -> [Double] {
        // szuka wzorca kwoty typu "123,45 zł" / "123.45 PLN" / "Razem: 87,00"
        let wzorzec = try? NSRegularExpression(
            pattern: #"(\d{1,6}[.,]\d{2})\s*(zł|PLN)?"#,
            options: [.caseInsensitive]
        )
        var kandydaci: [Double] = []
        let zakres = NSRange(linia.startIndex..<linia.endIndex, in: linia)
        wzorzec?.enumerateMatches(in: linia, range: zakres) { match, _, _ in
            guard let match, let r = Range(match.range(at: 1), in: linia) else { return }
            let liczbaTekst = linia[r].replacingOccurrences(of: ",", with: ".")
            if let wartosc = Double(liczbaTekst) {
                kandydaci.append(wartosc)
            }
        }
        return kandydaci
    }
}
