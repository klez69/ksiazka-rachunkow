import SwiftUI

/// Ciepła, "papierowa" paleta i typografia wzięta z artefaktu "Książka Rachunków".
/// Kolory żyją w Assets.xcassets (osobne warianty jasny/ciemny), tu tylko uchwyty.
enum Theme {
    static let bg = Color("BgColor")
    static let paper = Color("PaperColor")
    static let ink = Color("InkColor")
    static let inkSoft = Color("InkSoftColor")
    static let inkFaint = Color("InkFaintColor")
    static let line = Color("LineColor")
    static let lineSoft = Color("LineSoftColor")
    static let accent = Color("AccentColorCustom")
    static let accentInk = Color("AccentInkColor")
    static let accentSoft = Color("AccentSoftColor")
    static let warn = Color("WarnColor")
    static let doneColor = Color("DoneColor")

    static let radius: CGFloat = 10

    // Fraunces i IBM Plex nie są wbudowane w system, więc jako bliski odpowiednik
    // używamy wbudowanego serifa (New York) na nagłówki i systemowego mono na liczby —
    // ten sam charakter (serif nagłówki / mono liczby), bez pobierania plików fontów.
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
