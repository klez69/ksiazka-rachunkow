import SwiftUI
import SwiftData

struct BillDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var rachunek: Rachunek

    @State private var pokazEdycje = false
    @State private var pokazPotwierdzenieUsuniecia = false
    @State private var pokazPowiekszony = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rachunek.kategoria.rawValue.uppercased())
                        .font(Theme.mono(11, weight: .medium))
                        .foregroundStyle(Theme.inkFaint)
                    Text(rachunek.nazwa)
                        .font(Theme.heading(28))
                        .foregroundStyle(Theme.ink)
                    Text(rachunek.kwota, format: .number.precision(.fractionLength(2)))
                        .font(Theme.mono(22, weight: .medium))
                        .foregroundStyle(Theme.accent)
                    + Text(" zł").font(Theme.body(14)).foregroundStyle(Theme.inkFaint)
                }

                if let data = rachunek.data {
                    wiersz(etykieta: "Termin", wartosc: data.formatted(date: .long, time: .omitted))
                }
                wiersz(etykieta: "Status", wartosc: rachunek.oplacony ? "Opłacony" : "Nieopłacony")
                if !rachunek.notatka.isEmpty {
                    wiersz(etykieta: "Notatka", wartosc: rachunek.notatka)
                }

                if let dane = rachunek.zdjecieSkanu, let obraz = platformImage(dane) {
                    Button {
                        pokazPowiekszony = true
                    } label: {
                        obraz
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.lineSoft))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edytuj") { pokazEdycje = true }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Usuń", role: .destructive) { pokazPotwierdzenieUsuniecia = true }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $pokazEdycje) {
            BillFormView(edytowanyRachunek: rachunek)
        }
        #else
        .sheet(isPresented: $pokazEdycje) {
            BillFormView(edytowanyRachunek: rachunek)
        }
        #endif
        .sheet(isPresented: $pokazPowiekszony) {
            if let dane = rachunek.zdjecieSkanu, let obraz = platformImage(dane) {
                obraz.resizable().scaledToFit().padding()
            }
        }
        .confirmationDialog("Usunąć „\(rachunek.nazwa)”?", isPresented: $pokazPotwierdzenieUsuniecia, titleVisibility: .visible) {
            Button("Usuń", role: .destructive) { usun() }
            Button("Anuluj", role: .cancel) {}
        }
    }

    private func wiersz(etykieta: String, wartosc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(etykieta.uppercased())
                .font(Theme.mono(11, weight: .medium))
                .foregroundStyle(Theme.inkFaint)
            Text(wartosc)
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink)
        }
    }

    private func usun() {
        RachunekSync.usunPowiazania(rachunek)
        context.delete(rachunek)
        try? context.save()
        dismiss()
    }
}

#if canImport(UIKit)
import UIKit
private func platformImage(_ dane: Data) -> Image? {
    guard let ui = UIImage(data: dane) else { return nil }
    return Image(uiImage: ui)
}
#elseif canImport(AppKit)
import AppKit
private func platformImage(_ dane: Data) -> Image? {
    guard let ns = NSImage(data: dane) else { return nil }
    return Image(nsImage: ns)
}
#endif
