import Foundation
import Vision

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Odczytuje tekst ze zdjęcia rachunku (offline, Vision) i próbuje wyłuskać kwotę i datę.
/// To tylko podpowiedź — użytkownik zawsze poprawia wynik ręcznie w formularzu.
enum OCRService {

    struct Wynik {
        var kwota: Double?
        var data: Date?
    }

    static func rozpoznaj(z obraz: PlatformImage) async -> Wynik {
        guard let cgImage = cgImage(from: obraz) else { return Wynik(kwota: nil, data: nil) }

        let linie: [String] = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let results = (request.results as? [VNRecognizedTextObservation]) ?? []
                let teksty = results.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: teksty)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["pl-PL", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }

        return Wynik(kwota: znajdzKwote(w: linie), data: znajdzDate(w: linie))
    }

    private static func cgImage(from obraz: PlatformImage) -> CGImage? {
        #if canImport(UIKit)
        return obraz.cgImage
        #elseif canImport(AppKit)
        var rect = CGRect(origin: .zero, size: obraz.size)
        return obraz.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }

    private static func znajdzKwote(w linie: [String]) -> Double? {
        // szuka wzorca kwoty typu "123,45 zł" / "123.45 PLN" / "Razem: 87,00"
        let wzorzec = try? NSRegularExpression(
            pattern: #"(\d{1,6}[.,]\d{2})\s*(zł|PLN)?"#,
            options: [.caseInsensitive]
        )
        var kandydaci: [Double] = []
        for linia in linie {
            let zakres = NSRange(linia.startIndex..<linia.endIndex, in: linia)
            wzorzec?.enumerateMatches(in: linia, range: zakres) { match, _, _ in
                guard let match, let r = Range(match.range(at: 1), in: linia) else { return }
                let liczbaTekst = linia[r].replacingOccurrences(of: ",", with: ".")
                if let wartosc = Double(liczbaTekst) {
                    kandydaci.append(wartosc)
                }
            }
        }
        // najczęściej najwyższa kwota na paragonie to suma "do zapłaty"
        return kandydaci.max()
    }

    private static func znajdzDate(w linie: [String]) -> Date? {
        let formaty = ["dd.MM.yyyy", "dd-MM-yyyy", "dd/MM/yyyy", "yyyy-MM-dd"]
        let wzorzec = try? NSRegularExpression(
            pattern: #"\b(\d{1,2}[.\-/]\d{1,2}[.\-/]\d{4}|\d{4}-\d{2}-\d{2})\b"#
        )
        for linia in linie {
            let zakres = NSRange(linia.startIndex..<linia.endIndex, in: linia)
            guard let match = wzorzec?.firstMatch(in: linia, range: zakres),
                  let r = Range(match.range, in: linia) else { continue }
            let tekst = String(linia[r])
            for format in formaty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = format
                dateFormatter.locale = Locale(identifier: "pl_PL")
                if let data = dateFormatter.date(from: tekst) {
                    return data
                }
            }
        }
        return nil
    }
}
