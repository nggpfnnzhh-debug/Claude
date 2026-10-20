import SwiftUI

/// Huhus Sternenhimmel: Jeder gesammelte Stern leuchtet hier auf.
/// Bewusst eine Sammlung zum Anschauen – kein Punktestand, kein Vergleich.
struct StarSkyView: View {
    let starCount: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutScale) private var scale
    @State private var twinkling: Set<Int> = []
    @State private var appear = false

    /// Mehr Sterne passen nicht sinnvoll auf den Himmel.
    private static let maxVisible = 150

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.10, blue: 0.30), Color(red: 0.25, green: 0.20, blue: 0.50)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ForEach(0..<min(starCount, Self.maxVisible), id: \.self) { index in
                    let position = Self.position(for: index, in: proxy.size)
                    Text("⭐️")
                        .font(.system(size: (index % 3 == 0 ? 30 : 22) * scale))
                        .scaleEffect(twinkling.contains(index) ? 1.6 : (appear ? 1 : 0.1))
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(Double(index) * 0.02), value: appear)
                        .position(position)
                        .onTapGesture { twinkle(index) }
                        .accessibilityHidden(true)
                }

                VStack {
                    HStack {
                        Spacer()
                        RoundIconButton(systemName: "xmark", tint: .white.opacity(0.25), size: 48) { dismiss() }
                            .accessibilityLabel("Schließen")
                    }
                    Spacer()
                    if starCount == 0 {
                        Text("✨")
                            .font(.system(size: 60 * scale))
                    }
                    Text("🦉")
                        .font(.system(size: 90 * scale))
                        .accessibilityLabel("Huhu, die Eule")
                }
                .padding()
            }
        }
        .onAppear {
            appear = true
            if starCount > 0 {
                Speaker.shared.say(Lines.starSky)
            }
        }
    }

    private func twinkle(_ index: Int) {
        Haptics.soft()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { _ = twinkling.insert(index) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring()) { _ = twinkling.remove(index) }
        }
    }

    /// Feste, „zufällig“ wirkende Position je Stern – derselbe Stern bleibt immer an seinem Platz.
    static func position(for index: Int, in size: CGSize) -> CGPoint {
        let x = fraction(index, salt: 0.6180339887)
        let y = fraction(index, salt: 0.7548776662)
        // Unten bleibt Platz für Huhu, oben für den Schließen-Knopf.
        return CGPoint(x: 30 + x * (size.width - 60), y: 80 + y * (size.height - 260))
    }

    private static func fraction(_ index: Int, salt: Double) -> Double {
        let value = Double(index + 1) * salt
        return value - value.rounded(.down)
    }
}
