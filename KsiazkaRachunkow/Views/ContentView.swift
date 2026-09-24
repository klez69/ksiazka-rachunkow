import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Rachunek.dataUtworzenia, order: .reverse) private var rachunki: [Rachunek]

    @State private var pokazZaplacone = false
    @State private var pokazNowyFormularz = false
    @State private var pokazSkaner = false
    @State private var trwaRozpoznawanie = false
    @State private var wstepneDane: WstepneDaneSkanu?

    private struct WstepneDaneSkanu: Identifiable {
        let id = UUID()
        let zdjecie: Data
        let kwota: Double?
        let data: Date?
    }

    private var nieoplacone: [Rachunek] { rachunki.filter { !$0.oplacony } }
    private var widoczne: [Rachunek] { pokazZaplacone ? rachunki : nieoplacone }
    private var grupy: [MiesiacGrupa] { Grupowanie.pogrupuj(widoczne) }
    private var sumaZaleglych: Double { nieoplacone.reduce(0) { $0 + $1.kwota } }
    private var najblizszyTermin: Date? { nieoplacone.compactMap(\.data).min() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    naglowek
                    pasekNarzedzi
                    podsumowanie

                    if grupy.isEmpty {
                        Text("Brak rachunków — dodaj pierwszy przyciskiem powyżej.")
                            .font(Theme.body(13))
                            .foregroundStyle(Theme.inkFaint)
                            .italic()
                            .padding(.top, 8)
                    } else {
                        ForEach(grupy) { grupa in
                            sekcjaMiesiaca(grupa)
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        pokazNowyFormularz = true
                    } label: {
                        Label("Dodaj", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        rozpocznijSkanowanie()
                    } label: {
                        Label("Skanuj", systemImage: "doc.viewfinder")
                    }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $pokazNowyFormularz) {
                BillFormView()
            }
            .fullScreenCover(item: $wstepneDane) { wstepne in
                BillFormView(wstepneZdjecie: wstepne.zdjecie, wstepnaKwota: wstepne.kwota, wstepnaData: wstepne.data)
            }
            #else
            .sheet(isPresented: $pokazNowyFormularz) {
                BillFormView()
            }
            .sheet(item: $wstepneDane) { wstepne in
                BillFormView(wstepneZdjecie: wstepne.zdjecie, wstepnaKwota: wstepne.kwota, wstepnaData: wstepne.data)
            }
            #endif
            #if os(iOS)
            .fullScreenCover(isPresented: $pokazSkaner) {
                ScannerView(naZakonczenie: obsluzZeskanowaneZdjecie, naAnulowanie: { pokazSkaner = false })
                    .ignoresSafeArea()
            }
            #endif
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }

    private var naglowek: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LISTA KONTROLNA")
                .font(Theme.mono(12, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.inkFaint)
            Text("Książka rachunków")
                .font(Theme.heading(32))
                .foregroundStyle(Theme.ink)
            Text("Zaznacz kółko, gdy zapłacisz — pozycja zniknie z listy głównej. Dodawaj rachunki ręcznie albo skanerem.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var pasekNarzedzi: some View {
        HStack {
            Button {
                withAnimation { pokazZaplacone.toggle() }
            } label: {
                Text(pokazZaplacone ? "Ukryj zapłacone" : "Pokaż zapłacone (\(rachunki.count - nieoplacone.count))")
                    .font(Theme.mono(12))
            }
            .buttonStyle(GhostButtonStyle(aktywny: pokazZaplacone))

            Spacer()

            if trwaRozpoznawanie {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Odczytuję rachunek…").font(Theme.mono(11.5)).foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private var podsumowanie: some View {
        HStack(spacing: 1) {
            statystyka(liczba: "\(nieoplacone.count)", etykieta: "DO ZAPŁATY")
            statystyka(liczba: sumaZaleglych.formatted(.number.precision(.fractionLength(2))) + " zł", etykieta: "SUMA ZALEGŁYCH")
            statystyka(
                liczba: najblizszyTermin?.formatted(date: .abbreviated, time: .omitted) ?? "—",
                etykieta: "NAJBLIŻSZY TERMIN"
            )
        }
        .background(Theme.line)
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
    }

    private func statystyka(liczba: String, etykieta: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(liczba)
                .font(Theme.mono(15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Theme.ink)
            Text(etykieta)
                .font(Theme.mono(9, weight: .medium))
                .tracking(0.3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 11)
        .background(Theme.paper)
    }

    private func sekcjaMiesiaca(_ grupa: MiesiacGrupa) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(grupa.etykieta)
                    .font(Theme.heading(16))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(grupa.pozycje.count) \(grupa.pozycje.count == 1 ? "pozycja" : "pozycji")")
                    .font(Theme.mono(11.5))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.bottom, 6)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.line).frame(height: 1)
            }

            VStack(spacing: 0) {
                ForEach(Array(grupa.pozycje.enumerated()), id: \.element.id) { indeks, rachunek in
                    NavigationLink {
                        BillDetailView(rachunek: rachunek)
                    } label: {
                        BillRowView(rachunek: rachunek) {
                            przelaczOplacony(rachunek)
                        }
                    }
                    .buttonStyle(.plain)
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button("Usuń", role: .destructive) { usun(rachunek) }
                    }
                    #endif

                    if indeks < grupa.pozycje.count - 1 {
                        Rectangle().fill(Theme.lineSoft).frame(height: 1)
                    }
                }
            }
            .background(Theme.paper)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.lineSoft))
        }
    }

    private func przelaczOplacony(_ rachunek: Rachunek) {
        rachunek.oplacony.toggle()
        Task {
            await RachunekSync.synchronizuj(rachunek)
            try? context.save()
        }
    }

    private func usun(_ rachunek: Rachunek) {
        RachunekSync.usunPowiazania(rachunek)
        context.delete(rachunek)
        try? context.save()
    }

    private func rozpocznijSkanowanie() {
        #if os(iOS)
        pokazSkaner = true
        #elseif os(macOS)
        guard let dane = ImportDokumentu.wybierzPlik() else { return }
        obsluzZeskanowaneZdjecie(dane)
        #endif
    }

    private func obsluzZeskanowaneZdjecie(_ dane: Data) {
        #if os(iOS)
        pokazSkaner = false
        #endif
        trwaRozpoznawanie = true
        Task {
            let obraz = platformImage(from: dane)
            let wynik = obraz != nil ? await OCRService.rozpoznaj(z: obraz!) : OCRService.Wynik(kwota: nil, data: nil)
            await MainActor.run {
                trwaRozpoznawanie = false
                wstepneDane = WstepneDaneSkanu(zdjecie: dane, kwota: wynik.kwota, data: wynik.data)
            }
        }
    }
}

private struct GhostButtonStyle: ButtonStyle {
    var aktywny: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(aktywny ? Theme.accentInk : Theme.inkSoft)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(aktywny ? Theme.accentSoft : Theme.paper)
            .overlay(
                Capsule().stroke(aktywny ? Theme.accent.opacity(0.5) : Theme.line)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

#if canImport(UIKit)
import UIKit
private func platformImage(from dane: Data) -> PlatformImage? { UIImage(data: dane) }
#elseif canImport(AppKit)
import AppKit
private func platformImage(from dane: Data) -> PlatformImage? { NSImage(data: dane) }
#endif
