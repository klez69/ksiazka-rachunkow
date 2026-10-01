import SwiftUI

#if os(iOS)
import VisionKit

/// Opakowanie na DataScannerViewController — pokazuje żywy podgląd aparatu
/// z automatycznie podświetlonym rozpoznanym tekstem. Dotknięcie fragmentu
/// zwraca jego tekst przez `naDotkniecie`.
struct LiveScannerRepresentable: UIViewControllerRepresentable {
    var naDotkniecie: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(naDotkniecie: naDotkniecie)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let naDotkniecie: (String) -> Void

        init(naDotkniecie: @escaping (String) -> Void) {
            self.naDotkniecie = naDotkniecie
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case let .text(tekst) = item {
                naDotkniecie(tekst.transcript)
            }
        }
    }
}

/// Czy ten telefon/symulator w ogóle obsługuje rozpoznawanie na żywo
/// (np. Symulator nie obsługuje, bo nie ma prawdziwego aparatu).
@MainActor
enum LiveScannerDostepnosc {
    static var dostepny: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
}
#endif
