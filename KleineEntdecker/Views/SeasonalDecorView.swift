import SwiftUI

/// Sanft herabschwebende Blätter, Schneeflocken, Fledermäuse … auf dem Startbildschirm.
/// Bewusst wenige, kleine und halbtransparente Teile, damit nichts von den Spielen ablenkt.
struct SeasonalDecorView: View {
    let emojis: [String]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Piece: Identifiable {
        let id = UUID()
        let emoji: String
        let x = CGFloat.random(in: 0.03...0.97)
        let startY = CGFloat.random(in: 0...1)
        let size = CGFloat.random(in: 18...28)
        let duration = Double.random(in: 14...22)
        let drift = CGFloat.random(in: -30...30)
        let spin = Double.random(in: -120...120)
    }

    @State private var pieces: [Piece]
    @State private var fall = false

    init(emojis: [String]) {
        self.emojis = emojis
        // Die Teile müssen schon vor dem ersten Erscheinen da sein – sonst gibt es keinen Startpunkt
        // für die Animation und alles läge sofort am Ziel (unterhalb des Bildschirms).
        _pieces = State(initialValue: (0..<10).map { index in Piece(emoji: emojis[index % emojis.count]) })
    }

    var body: some View {
        GeometryReader { proxy in
            ForEach(pieces) { piece in
                // Jedes Teil startet an einer zufälligen Höhe und fällt dann endlos von oben nach unten.
                let height = proxy.size.height + 80
                let start = piece.startY * height - 40
                Text(piece.emoji)
                    .font(.system(size: piece.size))
                    .opacity(0.55)
                    .rotationEffect(.degrees(fall && !reduceMotion ? piece.spin : 0))
                    .position(
                        x: piece.x * proxy.size.width + (fall && !reduceMotion ? piece.drift : 0),
                        y: fall && !reduceMotion ? start + height : start
                    )
                    .animation(
                        reduceMotion ? nil : .linear(duration: piece.duration).repeatForever(autoreverses: false),
                        value: fall
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            DispatchQueue.main.async { fall = true }
        }
    }
}
