import SwiftUI

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

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
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

    var body: some View {
        HStack {
            RoundIconButton(systemName: "house.fill", tint: tint, action: onExit)
                .accessibilityLabel("Zurück zum Start")
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? tint : Color.gray.opacity(0.25))
                        .frame(width: 16, height: 16)
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
