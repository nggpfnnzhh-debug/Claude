import SwiftUI

/// Vergrößerungsfaktor für große Bildschirme (iPad): Kinderfinger brauchen dort große Ziele.
private struct LayoutScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var layoutScale: CGFloat {
        get { self[LayoutScaleKey.self] }
        set { self[LayoutScaleKey.self] = newValue }
    }
}

/// Setzt `layoutScale` auf 1,5, wenn genug Platz in beide Richtungen ist (iPad, nicht iPhone quer).
struct AdaptiveLayoutScale: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontal
    @Environment(\.verticalSizeClass) private var vertical

    func body(content: Content) -> some View {
        content.environment(\.layoutScale, horizontal == .regular && vertical == .regular ? 1.5 : 1)
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct RoundIconButton: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 60
    let action: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * scale * 0.42, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size * scale, height: size * scale)
                .background(Circle().fill(tint))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Kopfzeile in jedem Spiel: Zurück, Fortschrittspunkte, Anweisung wiederholen.
struct GameTopBar: View {
    let tint: Color
    let completed: Int
    let total: Int
    let onExit: () -> Void
    let onRepeat: () -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        HStack {
            RoundIconButton(systemName: "house.fill", tint: tint, action: onExit)
                .accessibilityLabel("Zurück zum Start")
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? tint : Color.gray.opacity(0.25))
                        .frame(width: 16 * scale, height: 16 * scale)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(completed) von \(total) geschafft")
            Spacer()
            RoundIconButton(systemName: "speaker.wave.2.fill", tint: tint, action: onRepeat)
                .accessibilityLabel("Anweisung wiederholen")
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ShapeView: View {
    let kind: ShapeKind
    let color: Color

    var body: some View {
        switch kind {
        case .circle:
            Circle().fill(color).aspectRatio(1, contentMode: .fit)
        case .square:
            Rectangle().fill(color).aspectRatio(1, contentMode: .fit).padding(6)
        case .rectangle:
            Rectangle().fill(color).aspectRatio(1.8, contentMode: .fit)
        case .oval:
            Ellipse().fill(color).aspectRatio(1.6, contentMode: .fit)
        case .triangle:
            Triangle().fill(color).aspectRatio(1, contentMode: .fit)
        case .star:
            Image(systemName: "star.fill").resizable().scaledToFit().foregroundColor(color)
        case .heart:
            Image(systemName: "heart.fill").resizable().scaledToFit().foregroundColor(color)
        }
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 28) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        )
    }
}
