import SwiftUI

struct BillRowView: View {
    @Bindable var rachunek: Rachunek
    var naZmianeStatusu: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: naZmianeStatusu) {
                Circle()
                    .strokeBorder(rachunek.oplacony ? Theme.accent : Theme.inkFaint, lineWidth: 1.5)
                    .background(Circle().fill(rachunek.oplacony ? Theme.accent : .clear))
                    .frame(width: 20, height: 20)
                    .overlay {
                        if rachunek.oplacony {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.paper)
                        }
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(rachunek.nazwa)
                    .font(Theme.body(14.5, weight: .medium))
                    .foregroundStyle(rachunek.oplacony ? Theme.doneColor : Theme.ink)
                    .strikethrough(rachunek.oplacony, color: Theme.line)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(rachunek.zdjecieSkanu != nil ? "skan" : "ręcznie")
                        .font(Theme.mono(10.5, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Theme.lineSoft)
                        .foregroundStyle(Theme.inkSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text(rachunek.kategoria.rawValue)
                        .font(Theme.mono(10.5, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Theme.accentSoft)
                        .foregroundStyle(Theme.accentInk)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    if let data = rachunek.data {
                        Text(data.formatted(.dateTime.day().month(.twoDigits)))
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }

            Spacer(minLength: 8)

            Text(rachunek.kwota, format: .number.precision(.fractionLength(2)))
                .font(Theme.mono(15, weight: .medium))
                .foregroundStyle(rachunek.oplacony ? Theme.doneColor : Theme.ink)
            + Text(" zł")
                .font(Theme.body(12))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }
}
