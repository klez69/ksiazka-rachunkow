import Foundation

#if os(macOS)
import AppKit
import PDFKit
import UniformTypeIdentifiers

/// Mac nie ma skanera dokumentów aparatem — zamiast tego wybór istniejącego
/// zdjęcia lub PDF-a z dysku. PDF zamieniamy na obraz pierwszej strony.
@MainActor
enum ImportDokumentu {
    static func wybierzPlik() -> Data? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Wybierz zdjęcie lub PDF rachunku"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        if url.pathExtension.lowercased() == "pdf" {
            return obrazZPierwszejStronyPDF(url: url)
        }
        return try? Data(contentsOf: url)
    }

    private static func obrazZPierwszejStronyPDF(url: URL) -> Data? {
        guard let dokument = PDFDocument(url: url), let strona = dokument.page(at: 0) else { return nil }
        let rect = strona.bounds(for: .mediaBox)
        let obraz = NSImage(size: rect.size)
        obraz.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(NSColor.white.cgColor)
            context.fill(rect)
            strona.draw(with: .mediaBox, to: context)
        }
        obraz.unlockFocus()
        guard let tiff = obraz.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
    }
}
#endif
