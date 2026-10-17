import SwiftUI

struct MemoryCard: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    var isFaceUp = false
    var isMatched = false
}

struct MemoryGameView: View {
    let game: Game
    let onExit: () -> Void

    static let pairCount = 6
    static let animals: [(emoji: String, name: String)] = [
        ("🐶", "Hund"), ("🐱", "Katze"), ("🐭", "Maus"), ("🐰", "Hase"),
        ("🦊", "Fuchs"), ("🐻", "Bär"), ("🐼", "Panda"), ("🐸", "Frosch"),
        ("🐵", "Affe"), ("🐷", "Schwein"), ("🐮", "Kuh"), ("🦁", "Löwe"),
    ]
    private static let instruction = Lines.memoryInstruction

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.layoutScale) private var scale
    @State private var cards: [MemoryCard] = []
    @State private var firstIndex: Int?
    @State private var isBusy = false
    @State private var finished = false

    private var matchedPairs: Int {
        cards.filter(\.isMatched).count / 2
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ZStack {
            game.tint.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 16) {
                GameTopBar(
                    tint: game.tint,
                    completed: matchedPairs,
                    total: Self.pairCount,
                    onExit: onExit,
                    onRepeat: { Speaker.shared.say(Self.instruction) }
                )
                Spacer(minLength: 0)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(cards.indices, id: \.self) { index in
                        MemoryCardView(card: cards[index], tint: game.tint)
                            .onTapGesture { flip(index) }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityLabel(cards[index].isFaceUp ? cards[index].name : "Verdeckte Karte")
                    }
                }
                .frame(maxWidth: 560 * scale)
                Spacer(minLength: 0)
            }
            .padding()

            if finished {
                CelebrationView(tint: game.tint, onAgain: start, onHome: onExit)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if cards.isEmpty { start() }
        }
    }

    private func start() {
        let chosen = Self.animals.shuffled().prefix(Self.pairCount)
        cards = chosen
            .flatMap { [MemoryCard(emoji: $0.emoji, name: $0.name), MemoryCard(emoji: $0.emoji, name: $0.name)] }
            .shuffled()
        firstIndex = nil
        isBusy = false
        withAnimation { finished = false }
        Speaker.shared.say(Self.instruction)
    }

    private func flip(_ index: Int) {
        guard !isBusy, cards.indices.contains(index), !cards[index].isFaceUp, !cards[index].isMatched else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            cards[index].isFaceUp = true
        }
        Speaker.shared.say(cards[index].name)

        guard let first = firstIndex else {
            firstIndex = index
            return
        }
        firstIndex = nil

        if cards[first].emoji == cards[index].emoji {
            withAnimation(.spring()) {
                cards[first].isMatched = true
                cards[index].isMatched = true
            }
            Haptics.success()
            Speaker.shared.say(Lines.memoryPair, interrupt: false)
            if cards.allSatisfy(\.isMatched) {
                progress.addStar(for: game)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.spring()) { finished = true }
                }
            }
        } else {
            isBusy = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if cards.indices.contains(first) { cards[first].isFaceUp = false }
                    if cards.indices.contains(index) { cards[index].isFaceUp = false }
                }
                isBusy = false
            }
        }
    }
}

struct MemoryCardView: View {
    let card: MemoryCard
    let tint: Color

    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                Text(card.emoji)
                    .font(.system(size: 52 * scale))
                    .minimumScaleFactor(0.4)
                    .padding(6)
                    .transition(.scale)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.8), tint], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("⭐️")
                    .font(.system(size: 30 * scale))
                    .opacity(0.7)
            }
        }
        .aspectRatio(0.8, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(card.isMatched ? Color.green : Color.clear, lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
        .opacity(card.isMatched ? 0.75 : 1)
    }
}
