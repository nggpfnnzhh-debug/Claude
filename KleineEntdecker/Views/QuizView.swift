import SwiftUI

/// Gemeinsamer Ablauf für alle Auswahl-Spiele: Anweisung hören, Antwort antippen, Lob, nächste Aufgabe.
/// Falsche Antworten werden nur ausgegraut und freundlich erklärt – es gibt keine Strafen.
struct QuizView: View {
    let game: Game
    let onExit: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @AppStorage(SettingsKey.countingMax) private var countingMax = 5

    @State private var tasks: [QuizTask] = []
    @State private var index = 0
    @State private var wrongIDs: Set<UUID> = []
    @State private var solvedID: UUID?
    @State private var finished = false

    private var currentTask: QuizTask? {
        tasks.indices.contains(index) ? tasks[index] : nil
    }

    var body: some View {
        ZStack {
            game.tint.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 16) {
                GameTopBar(
                    tint: game.tint,
                    completed: index + (solvedID == nil ? 0 : 1),
                    total: tasks.count,
                    onExit: onExit,
                    onRepeat: repeatInstruction
                )

                if let task = currentTask {
                    Spacer(minLength: 0)
                    PromptView(prompt: task.prompt, tint: game.tint)
                        .id(task.id)
                    Spacer(minLength: 0)
                    ChoiceRow(
                        choices: task.choices,
                        wrongIDs: wrongIDs,
                        solvedID: solvedID
                    ) { choice in
                        select(choice, in: task)
                    }
                    .id("choices-\(task.id)")
                    Spacer(minLength: 0)
                }
            }
            .padding()

            if finished {
                CelebrationView(tint: game.tint, onAgain: start, onHome: onExit)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if tasks.isEmpty { start() }
        }
        // Verzögertes Weiterschalten nach richtiger Antwort; wird beim Verlassen automatisch abgebrochen.
        .task(id: solvedID) {
            guard solvedID != nil else { return }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    private func start() {
        tasks = TaskFactory.tasks(for: game, countingUpTo: countingMax)
        index = 0
        wrongIDs = []
        solvedID = nil
        withAnimation { finished = false }
        if let first = tasks.first {
            Speaker.shared.say(first.instruction)
        }
    }

    private func repeatInstruction() {
        if let task = currentTask {
            Speaker.shared.say(task.instruction)
        }
    }

    private func select(_ choice: Choice, in task: QuizTask) {
        guard solvedID == nil, !wrongIDs.contains(choice.id) else { return }
        if choice.isCorrect {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                solvedID = choice.id
            }
            Haptics.success()
            Speaker.shared.say(task.correctFeedback)
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                _ = wrongIDs.insert(choice.id)
            }
            Haptics.soft()
            Speaker.shared.say(choice.wrongFeedback)
        }
    }

    private func advance() {
        if index + 1 < tasks.count {
            withAnimation(.easeInOut) {
                index += 1
                wrongIDs = []
                solvedID = nil
            }
            Speaker.shared.say(tasks[index].instruction, interrupt: false)
        } else {
            progress.addStar(for: game)
            withAnimation(.spring()) { finished = true }
        }
    }
}

// MARK: - Aufgabenbereich

struct PromptView: View {
    let prompt: Prompt
    let tint: Color

    var body: some View {
        switch prompt {
        case let .objects(emoji, count):
            CountingObjectsView(emoji: emoji, count: count)
        case let .letter(letter):
            Button {
                Speaker.shared.say(letter)
            } label: {
                Text("\(letter) \(letter.lowercased())")
                    .font(.system(size: 120, weight: .heavy, design: .rounded))
                    .foregroundColor(tint)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 8)
                    .cardBackground()
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Buchstabe \(letter)")
        case let .sequence(items):
            SequenceView(items: items, tint: tint)
        case .empty:
            EmptyView()
        }
    }
}

/// Zeigt die zu zählenden Bilder. Jedes Antippen zählt laut weiter.
struct CountingObjectsView: View {
    let emoji: String
    let count: Int

    @State private var tapOrder: [Int: Int] = [:]

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: min(count, 5))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<count, id: \.self) { index in
                Button {
                    tap(index)
                } label: {
                    Text(emoji)
                        .font(.system(size: 54))
                        .frame(minWidth: 60, minHeight: 64)
                        .scaleEffect(tapOrder[index] == nil ? 1 : 1.12)
                        .overlay(alignment: .topTrailing) {
                            if let number = tapOrder[index] {
                                Text("\(number)")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.accentColor))
                                    .offset(x: 4, y: -4)
                                    .transition(.scale)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: CGFloat(min(count, 5)) * 90 + 40)
        .cardBackground()
    }

    private func tap(_ index: Int) {
        guard tapOrder[index] == nil else { return }
        let number = tapOrder.count + 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            tapOrder[index] = number
        }
        if Phrases.numberWords.indices.contains(number) {
            Speaker.shared.say(Phrases.numberWords[number])
        }
    }
}

struct SequenceView: View {
    let items: [String]
    let tint: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(size: 56)
            row(size: 44)
            row(size: 34)
            row(size: 26)
        }
        .accessibilityLabel("Muster")
    }

    private func row(size: CGFloat) -> some View {
        HStack(spacing: size * 0.15) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item).font(.system(size: size))
            }
            Text("?")
                .font(.system(size: size * 0.8, weight: .heavy, design: .rounded))
                .foregroundColor(tint)
                .frame(width: size * 1.25, height: size * 1.25)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(tint, style: StrokeStyle(lineWidth: 3, dash: [6]))
                )
        }
        .padding(size * 0.35)
        .cardBackground()
        .fixedSize()
    }
}

// MARK: - Antwortkarten

struct ChoiceRow: View {
    let choices: [Choice]
    let wrongIDs: Set<UUID>
    let solvedID: UUID?
    let onSelect: (Choice) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ForEach(choices) { choice in
                Button {
                    onSelect(choice)
                } label: {
                    ChoiceCard(
                        content: choice.content,
                        isWrong: wrongIDs.contains(choice.id),
                        isSolved: solvedID == choice.id
                    )
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(choice.spokenName)
            }
        }
        .frame(maxWidth: 680)
    }
}

struct ChoiceCard: View {
    let content: ChoiceContent
    let isWrong: Bool
    let isSolved: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            ChoiceContentView(content: content)
                .padding(16)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 160)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSolved ? Color.green : Color.clear, lineWidth: 6)
        )
        .overlay(alignment: .topTrailing) {
            if isSolved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.green)
                    .background(Circle().fill(Color.white))
                    .offset(x: 8, y: -8)
                    .transition(.scale)
            }
        }
        .scaleEffect(isSolved ? 1.08 : 1)
        .opacity(isWrong ? 0.3 : 1)
    }
}

struct ChoiceContentView: View {
    let content: ChoiceContent

    var body: some View {
        switch content {
        case let .number(value):
            Text("\(value)")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                .minimumScaleFactor(0.4)
        case let .color(color, symbol):
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
        case let .shape(kind, color):
            ShapeView(kind: kind, color: color)
        case let .emoji(emoji):
            Text(emoji)
                .font(.system(size: 80))
                .minimumScaleFactor(0.3)
        }
    }
}
