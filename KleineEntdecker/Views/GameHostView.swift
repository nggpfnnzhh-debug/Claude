import SwiftUI

struct GameHostView: View {
    let game: Game
    let onExit: () -> Void

    var body: some View {
        switch game {
        case .memory:
            MemoryGameView(game: game, onExit: onExit)
        default:
            QuizView(game: game, onExit: onExit)
        }
    }
}
