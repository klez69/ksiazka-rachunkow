import SwiftUI

#if os(iOS)
import VisionKit
import UIKit

/// Skaner dokumentów na iPhone: robi zdjęcie aparatem, sam prostuje i przycina kartkę.
struct ScannerView: UIViewControllerRepresentable {
    var naZakonczenie: (Data) -> Void
    var naAnulowanie: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(naZakonczenie: naZakonczenie, naAnulowanie: naAnulowanie)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let naZakonczenie: (Data) -> Void
        let naAnulowanie: () -> Void

        init(naZakonczenie: @escaping (Data) -> Void, naAnulowanie: @escaping () -> Void) {
            self.naZakonczenie = naZakonczenie
            self.naAnulowanie = naAnulowanie
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0, let dane = scan.imageOfPage(at: 0).jpegData(compressionQuality: 0.85) else {
                naAnulowanie()
                return
            }
            naZakonczenie(dane)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            naAnulowanie()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            naAnulowanie()
        }
    }
}
#endif
