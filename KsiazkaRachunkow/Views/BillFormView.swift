import SwiftUI
import SwiftData

struct BillFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var edytowanyRachunek: Rachunek?
    var wstepneZdjecie: Data?
    var wstepnaKwota: Double?
    var wstepnaData: Date?

    @State private var nazwa: String = ""
    @State private var kwotaTekst: String = ""
    @State private var maData: Bool = false
    @State private var data: Date = Date()
    @State private var kategoria: Kategoria = .inne
    @State private var oplacony: Bool = false
    @State private var notatka: String = ""
    @State private var zdjecieSkanu: Data?
    @State private var dodajDoKalendarza: Bool = true
    @State private var dodajPrzypomnienie: Bool = true
    @State private var zapisywanie = false
    @State private var ostrzezeniaSynchronizacji: [String] = []
    @State private var pokazOstrzezenie = false

    private var edycja: Bool { edytowanyRachunek != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nazwa (od kogo / za co)", text: $nazwa)
                    TextField("Kwota (zł)", text: $kwotaTekst)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Toggle("Ma termin płatności", isOn: $maData.animation())
                    if maData {
                        DatePicker("Termin", selection: $data, displayedComponents: .date)
                    }
                    Picker("Kategoria", selection: $kategoria) {
                        ForEach(Kategoria.allCases) { kat in
                            Text(kat.rawValue).tag(kat)
                        }
                    }
                    Toggle("Opłacony", isOn: $oplacony)
                    TextField("Notatka (opcjonalnie)", text: $notatka, axis: .vertical)
                }

                if let zdjecie = zdjecieSkanu, let obraz = platformImage(from: zdjecie) {
                    Section("Skan") {
                        obraz
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                    }
                }

                if maData && !oplacony {
                    Section("Przypomnij mi") {
                        Toggle("Dodaj do Kalendarza", isOn: $dodajDoKalendarza)
                        Toggle("Dodaj przypomnienie", isOn: $dodajPrzypomnienie)
                    }
                }
            }
            .navigationTitle(edycja ? "Edytuj rachunek" : "Dodaj rachunek")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(edycja ? "Zapisz zmiany" : "Dodaj") { zapisz() }
                        .disabled(nazwa.trimmingCharacters(in: .whitespaces).isEmpty || zapisywanie)
                }
            }
            .onAppear { wypelnijFormularz() }
            .alert("Nie wszystko się zsynchronizowało", isPresented: $pokazOstrzezenie) {
                Button("OK") { dismiss() }
            } message: {
                Text("Rachunek zapisany, ale:\n\n" + ostrzezeniaSynchronizacji.joined(separator: "\n"))
            }
        }
    }

    private func wypelnijFormularz() {
        if let r = edytowanyRachunek {
            nazwa = r.nazwa
            kwotaTekst = r.kwota == 0 ? "" : String(format: "%.2f", r.kwota)
            maData = r.data != nil
            data = r.data ?? Date()
            kategoria = r.kategoria
            oplacony = r.oplacony
            notatka = r.notatka
            zdjecieSkanu = r.zdjecieSkanu
            dodajDoKalendarza = r.dodajDoKalendarza
            dodajPrzypomnienie = r.dodajPrzypomnienie
        } else {
            if let kwota = wstepneKwotaLubNil() { kwotaTekst = String(format: "%.2f", kwota) }
            if let d = wstepnaData { maData = true; data = d }
            if let img = wstepneZdjecie { zdjecieSkanu = img }
        }
    }

    private func wstepneKwotaLubNil() -> Double? { wstepnaKwota }

    private func zapisz() {
        zapisywanie = true
        let kwota = Double(kwotaTekst.replacingOccurrences(of: ",", with: ".")) ?? 0

        let rachunek: Rachunek
        if let istniejacy = edytowanyRachunek {
            rachunek = istniejacy
            rachunek.nazwa = nazwa.trimmingCharacters(in: .whitespaces)
            rachunek.kwota = kwota
            rachunek.data = maData ? data : nil
            rachunek.kategoria = kategoria
            rachunek.oplacony = oplacony
            rachunek.notatka = notatka
            rachunek.zdjecieSkanu = zdjecieSkanu
            rachunek.dodajDoKalendarza = dodajDoKalendarza
            rachunek.dodajPrzypomnienie = dodajPrzypomnienie
        } else {
            rachunek = Rachunek(
                nazwa: nazwa.trimmingCharacters(in: .whitespaces),
                kwota: kwota,
                data: maData ? data : nil,
                kategoria: kategoria,
                oplacony: oplacony,
                notatka: notatka,
                zdjecieSkanu: zdjecieSkanu,
                dodajDoKalendarza: dodajDoKalendarza,
                dodajPrzypomnienie: dodajPrzypomnienie
            )
            context.insert(rachunek)
        }

        Task {
            let ostrzezenia = await RachunekSync.synchronizuj(rachunek)
            try? context.save()
            await MainActor.run {
                if ostrzezenia.isEmpty {
                    dismiss()
                } else {
                    ostrzezeniaSynchronizacji = ostrzezenia
                    pokazOstrzezenie = true
                }
            }
        }
    }
}

#if canImport(UIKit)
import UIKit
private func platformImage(from dane: Data) -> Image? {
    guard let ui = UIImage(data: dane) else { return nil }
    return Image(uiImage: ui)
}
#elseif canImport(AppKit)
import AppKit
private func platformImage(from dane: Data) -> Image? {
    guard let ns = NSImage(data: dane) else { return nil }
    return Image(nsImage: ns)
}
#endif
