import SwiftUI

#if os(iOS)
/// Ekran "inteligentnego" skanowania: na żywo pokazuje podgląd aparatu z podświetlonym
/// rozpoznanym tekstem. Dotknięcie kwoty/daty na ekranie od razu ją zapamiętuje —
/// bez robienia zdjęcia. Na końcu przechodzi do zwykłego skanera dokumentu (zdjęcie do archiwum).
struct LiveSkanowanieView: View {
    var naDalej: (_ kwota: Double?, _ data: Date?) -> Void
    var naAnulowanie: () -> Void

    @State private var zlapanaKwota: Double?
    @State private var zlapanaData: Date?

    var body: some View {
        ZStack(alignment: .top) {
            LiveScannerRepresentable(naDotkniecie: obsluzDotkniecie)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button("Anuluj") { naAnulowanie() }
                        .buttonStyle(.bordered)
                        .tint(.white)

                    Spacer()

                    Button("Dalej") { naDalej(zlapanaKwota, zlapanaData) }
                        .buttonStyle(.borderedProminent)
                }
                .padding()

                Text("Dotknij kwotę lub datę na rachunku")
                    .font(Theme.body(13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                Spacer()

                HStack(spacing: 10) {
                    chip(etykieta: "Kwota", wartosc: zlapanaKwota.map { String(format: "%.2f zł", $0) })
                    chip(etykieta: "Data", wartosc: zlapanaData?.formatted(date: .abbreviated, time: .omitted))
                }
                .padding(.bottom, 24)
            }
        }
        .background(.black)
    }

    private func chip(etykieta: String, wartosc: String?) -> some View {
        VStack(spacing: 2) {
            Text(etykieta.uppercased())
                .font(Theme.mono(9, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Text(wartosc ?? "—")
                .font(Theme.mono(14, weight: .semibold))
                .foregroundStyle(wartosc == nil ? .white.opacity(0.5) : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func obsluzDotkniecie(_ tekst: String) {
        if let kwota = TekstRozpoznawania.kwotaZTekstu(tekst) {
            zlapanaKwota = kwota
        } else if let data = TekstRozpoznawania.dataZTekstu(tekst) {
            zlapanaData = data
        }
    }
}
#endif
