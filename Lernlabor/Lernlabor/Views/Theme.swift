import SwiftUI
import UIKit

/// Farben für hell und dunkel: ruhiges Labor-Papier, Tinte, ein Kobalt-Akzent, jedes Tier mit eigener Farbe.
enum Theme {
    static let background = dynamic(light: 0xEEF2F1, dark: 0x0F1619)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x18232A)
    static let ink = dynamic(light: 0x16232A, dark: 0xE6EEF0)
    static let muted = dynamic(light: 0x5A6B72, dark: 0x9AABB1)
    static let line = dynamic(light: 0xD3DCDB, dark: 0x2C3A41)
    static let accent = dynamic(light: 0x2550D9, dark: 0x7D9BFF)
    static let accentInk = dynamic(light: 0xFFFFFF, dark: 0x0D1530)
    static let accentSoft = dynamic(light: 0xE2E9FD, dark: 0x1F2B4D)
    static let good = dynamic(light: 0x1D7A4F, dark: 0x5CC694)
    static let bad = dynamic(light: 0xB3372E, dark: 0xF08A80)

    static let beaver = dynamic(light: 0xA8662B, dark: 0xD99A5B)
    static let meerkat = dynamic(light: 0xB8862F, dark: 0xE0B565)
    static let octopus = dynamic(light: 0x8B4FC9, dark: 0xB98AF0)
    static let elephant = dynamic(light: 0x5C6F9E, dark: 0x93A6D6)
    static let turtle = dynamic(light: 0x3F8A3A, dark: 0x7CC775)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Font {
    static let display = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let heading = Font.system(.title2, design: .rounded, weight: .bold)
    static let subheading = Font.system(.headline, design: .rounded, weight: .bold)
}

// MARK: - Bausteine

/// Scrollbare Seite, auf dem iPad mittig mit begrenzter Breite
struct Page<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1)
            .foregroundStyle(Theme.muted)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(Theme.accentInk)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(Theme.accent)
            .background(configuration.isPressed ? Theme.accentSoft : Color.clear,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

/// Zeile auf dem Startbildschirm und im Labor
struct EntryRow<Icon: View>: View {
    let title: String
    let subtitle: String
    let meta: String
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: 14) {
            icon.frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.subheadline).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            Text(meta).font(.caption.monospaced()).foregroundStyle(Theme.muted)
        }
        .multilineTextAlignment(.leading)
        .card()
    }
}

/// Tier-Symbol: Emoji oder das gezeichnete Erdmännchen
struct AnimalIcon: View {
    let trait: Trait
    var size: CGFloat = 34

    var body: some View {
        Group {
            switch trait.animal.symbol {
            case .emoji(let emoji):
                Text(emoji).font(.system(size: size))
            case .meerkat:
                MeerkatDrawing()
            }
        }
        .frame(width: size * 1.25, height: size * 1.25)
        .accessibilityLabel(trait.animal.name)
    }
}

/// Einfaches Erdmännchen als Platzhalter, bis es eigene Illustrationen gibt
struct MeerkatDrawing: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 100
            let dx = (size.width - 100 * s) / 2
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: dx + x * s, y: y * s, width: w * s, height: h * s)
            }
            let fur = Color(UIColor(hex: 0xC9A06F))
            let furDark = Color(UIColor(hex: 0xA97F52))
            let belly = Color(UIColor(hex: 0xEBD7B8))
            let dark = Color(UIColor(hex: 0x3E3024))

            context.fill(Path(ellipseIn: rect(30, 40, 40, 58)), with: .color(fur))
            context.fill(Path(ellipseIn: rect(39, 52, 22, 42)), with: .color(belly))
            context.fill(Path(ellipseIn: rect(31, 50, 9, 22)), with: .color(furDark))
            context.fill(Path(ellipseIn: rect(60, 50, 9, 22)), with: .color(furDark))
            context.fill(Path(ellipseIn: rect(30, 16, 7, 7)), with: .color(dark))
            context.fill(Path(ellipseIn: rect(63, 16, 7, 7)), with: .color(dark))
            context.fill(Path(ellipseIn: rect(33, 8, 34, 34)), with: .color(fur))
            context.fill(Path(ellipseIn: rect(43, 26, 14, 13)), with: .color(belly))
            context.fill(Path(ellipseIn: rect(38, 17, 9, 10)), with: .color(dark))
            context.fill(Path(ellipseIn: rect(53, 17, 9, 10)), with: .color(dark))
            context.fill(Path(ellipseIn: rect(41, 19.5, 3.5, 3.5)), with: .color(.white))
            context.fill(Path(ellipseIn: rect(56, 19.5, 3.5, 3.5)), with: .color(.white))
            context.fill(Path(ellipseIn: rect(47.5, 29, 5, 3.5)), with: .color(dark))
        }
    }
}

/// Balken für ein Tier mit Prozentrang und optionalem Lerntipp
struct AnimalBarRow: View {
    let trait: Trait
    let score: Int
    var showTip = false

    var body: some View {
        let animal = trait.animal
        let level = Level(score: score)
        HStack(alignment: .top, spacing: 12) {
            AnimalIcon(trait: trait, size: 30)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(animal.name).font(.body.weight(.semibold))
                    Spacer()
                    Text("\(level.text) · \(score)")
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.muted)
                }
                Text(animal.traitName).font(.subheadline).foregroundStyle(Theme.muted)
                Capsule()
                    .fill(Theme.line)
                    .frame(height: 10)
                    .overlay(alignment: .leading) {
                        GeometryReader { geometry in
                            Capsule()
                                .fill(animal.color)
                                .frame(width: geometry.size.width * CGFloat(max(score, 3)) / 100)
                        }
                    }
                    .accessibilityHidden(true)
                if showTip {
                    DisclosureGroup("Was heißt das fürs Lernen?") {
                        Text(animal.tip(for: level))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 6)
                    }
                    .font(.subheadline.weight(.medium))
                    .tint(Theme.accent)
                    .padding(.top, 6)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(animal.name), \(animal.traitName): \(score) von 100, \(level.text)")
    }
}
