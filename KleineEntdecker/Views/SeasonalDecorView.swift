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
        /// Startpunkt im Fall-Zyklus (0…1), damit nicht alle gleichzeitig oben beginnen.
        let phase = Double.random(in: 0...1)
        let size = CGFloat.random(in: 18...28)
        let duration = Double.random(in: 14...22)
        let drift = CGFloat.random(in: 10...30)
    }

    @State private var pieces: [Piece]

    init(emojis: [String]) {
        self.emojis = emojis
        _pieces = State(initialValue: (0..<10).map { index in Piece(emoji: emojis[index % emojis.count]) })
    }

    var body: some View {
        // Position direkt aus der Uhrzeit berechnet: läuft endlos und ohne Sprünge beim Neuzeichnen.
        TimelineView(.animation(paused: reduceMotion)) { context in
            GeometryReader { proxy in
                let time = context.date.timeIntervalSinceReferenceDate
                ForEach(pieces) { piece in
                    let cycle: Double = time / piece.duration + piece.phase
                    let progress: CGFloat = CGFloat(reduceMotion ? piece.phase : cycle.truncatingRemainder(dividingBy: 1))
                    let sway: CGFloat = CGFloat(sin(Double(progress) * .pi * 4)) * piece.drift
                    Text(piece.emoji)
                        .font(.system(size: piece.size))
                        .opacity(0.6)
                        .rotationEffect(.degrees(Double(sway)))
                        .position(
                            x: piece.x * proxy.size.width + sway,
                            y: progress * (proxy.size.height + 80) - 40
                        )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
