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

        return Wynik(
            kwota: TekstRozpoznawania.kwotaZLinii(linie),
            data: TekstRozpoznawania.dataZLinii(linie)
        )
    }

    private static func cgImage(from obraz: PlatformImage) -> CGImage? {
        #if canImport(UIKit)
        return obraz.cgImage
        #elseif canImport(AppKit)
        var rect = CGRect(origin: .zero, size: obraz.size)
        return obraz.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }
}
