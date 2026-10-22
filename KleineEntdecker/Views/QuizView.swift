import SwiftUI

/// Gemeinsamer Ablauf für alle Auswahl-Spiele: Anweisung hören, Antwort antippen, Lob, nächste Aufgabe.
///
/// Pädagogische Leitlinien:
/// - Falsche Antworten werden ausgegraut und freundlich erklärt – keine Strafen.
/// - Nach zwei Fehlversuchen hilft Huhu (zeigt die Lösung bzw. zählt mit), statt das Kind raten zu lassen.
/// - Gelobt wird auch der Weg: genaues Hinschauen, Nicht-Aufgeben.
/// - Wie oft beim ersten Versuch richtig geantwortet wird, steuert die Schwierigkeit und die Fördertipps.
struct QuizView: View {
    let game: Game
    let onExit: () -> Void

    @EnvironmentObject private var progress: ProgressStore

    @State private var tasks: [QuizTask] = []
    @State private var index = 0
    @State private var wrongIDs: Set<UUID> = []
    @State private var solvedID: UUID?
    @State private var mistakesInTask = 0
    @State private var firstTryCount = 0
    @State private var hintActive = false
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
                    PromptView(prompt: task.prompt, tint: game.tint, countAlong: hintActive)
                        .id(task.id)
                    Spacer(minLength: 0)
                    ChoiceRow(
                        choices: task.choices,
                        wrongIDs: wrongIDs,
                        solvedID: solvedID,
                        hintedID: hintActive ? task.choices.first(where: \.isCorrect)?.id : nil
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
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    private func start() {
        tasks = TaskFactory.tasks(for: game, level: progress.level(for: game))
        index = 0
        firstTryCount = 0
        resetTaskState()
        withAnimation { finished = false }
        if let first = tasks.first {
            Speaker.shared.say(first.instruction)
        }
    }

    private func resetTaskState() {
        wrongIDs = []
        solvedID = nil
        mistakesInTask = 0
        hintActive = false
    }

    private func repeatInstruction() {
        if let task = currentTask {
            Speaker.shared.say(task.instruction)
        }
    }

    private func select(_ choice: Choice, in task: QuizTask) {
        guard solvedID == nil, !wrongIDs.contains(choice.id) else { return }
        if choice.isCorrect {
            if mistakesInTask == 0 { firstTryCount += 1 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                solvedID = choice.id
                hintActive = false
            }
            Haptics.success()
            Speaker.shared.say("\(Phrases.praise(afterMistakes: mistakesInTask > 0)) \(task.correctFeedback)")
        } else {
            mistakesInTask += 1
            withAnimation(.easeOut(duration: 0.25)) {
                _ = wrongIDs.insert(choice.id)
            }
            Haptics.soft()
            let remaining = task.choices.filter { !$0.isCorrect && !wrongIDs.contains($0.id) }
            if mistakesInTask >= 2, !remaining.isEmpty {
                // Huhu hilft: nicht weiter raten lassen, sondern zeigen bzw. gemeinsam zählen.
                withAnimation(.easeInOut) { hintActive = true }
                if case .objects = task.prompt {
                    Speaker.shared.say(Lines.countingHint)
                } else {
                    Speaker.shared.say("\(choice.wrongFeedback) \(Lines.hint)")
                }
            } else {
                Speaker.shared.say(choice.wrongFeedback)
            }
        }
    }

    private func advance() {
        if index + 1 < tasks.count {
            withAnimation(.easeInOut) {
                index += 1
                resetTaskState()
            }
            Speaker.shared.say(tasks[index].instruction, interrupt: false)
        } else {
            progress.completeRound(for: game, result: RoundResult(firstTry: firstTryCount, total: tasks.count))
            withAnimation(.spring()) { finished = true }
        }
    }
}

// MARK: - Aufgabenbereich

struct PromptView: View {
    let prompt: Prompt
    let tint: Color
    /// Huhus Hilfe beim Zählen: alle Bilder werden nacheinander laut gezählt.
    var countAlong = false

    @Environment(\.layoutScale) private var scale

    var body: some View {
        switch prompt {
        case let .objects(emoji, count):
            CountingObjectsView(emoji: emoji, count: count, countAlong: countAlong)
        case let .letter(letter, sound):
            Button {
                Speaker.shared.say(sound)
            } label: {
                Text("\(letter) \(letter.lowercased())")
                    .font(.system(size: 120 * scale, weight: .heavy, design: .rounded))
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
        case let .word(emoji, syllables):
            Button {
                Speaker.shared.say(syllables)
            } label: {
                VStack(spacing: 4) {
                    Text(emoji)
                        .font(.system(size: 110 * scale))
                    Image(systemName: "ear.fill")
                        .font(.system(size: 22 * scale))
                        .foregroundColor(tint)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
                .cardBackground()
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel("Wort anhören")
        case .empty:
            EmptyView()
        }
    }
}

/// Zeigt die zu zählenden Bilder. Jedes Antippen zählt laut weiter.
struct CountingObjectsView: View {
    let emoji: String
    let count: Int
    var countAlong = false

    @State private var tapOrder: [Int: Int] = [:]
    @Environment(\.layoutScale) private var scale

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: min(count, 5))
    }

    /// Bei bis zu 20 Bildern etwas kleiner, damit alles auf den Bildschirm passt.
    private var emojiSize: CGFloat { (count > 10 ? 40 : 54) * scale }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Button {
                    tap(index)
                } label: {
                    Text(emoji)
                        .font(.system(size: emojiSize))
                        .frame(minWidth: emojiSize * 1.1, minHeight: emojiSize * 1.15)
                        .scaleEffect(tapOrder[index] == nil ? 1 : 1.12)
                        .overlay(alignment: .topTrailing) {
                            if let number = tapOrder[index] {
                                Text("\(number)")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
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
        .frame(maxWidth: CGFloat(min(count, 5)) * (emojiSize + 36) + 40)
        .cardBackground()
        .task(id: countAlong) {
            guard countAlong else { return }
            await countAllTogether()
        }
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

    /// Huhu zählt mit: von vorn, Bild für Bild, mit hörbarer Zahl.
    private func countAllTogether() async {
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        withAnimation { tapOrder = [:] }
        for index in 0..<count {
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                tapOrder[index] = index + 1
            }
            if Phrases.numberWords.indices.contains(index + 1) {
                Speaker.shared.say(Phrases.numberWords[index + 1], interrupt: false)
            }
            try? await Task.sleep(nanoseconds: 750_000_000)
        }
    }
}

struct SequenceView: View {
    let items: [String]
    let tint: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            row(size: 84)
            row(size: 70)
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
    var hintedID: UUID?
    let onSelect: (Choice) -> Void

    @Environment(\.layoutScale) private var scale

    var body: some View {
        HStack(spacing: 16 * scale) {
            ForEach(choices) { choice in
                Button {
                    onSelect(choice)
                } label: {
                    ChoiceCard(
                        content: choice.content,
                        isWrong: wrongIDs.contains(choice.id),
                        isSolved: solvedID == choice.id,
                        isHinted: hintedID == choice.id
                    )
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(choice.spokenName)
            }
        }
        .frame(maxWidth: 720 * scale)
    }
}

struct ChoiceCard: View {
    let content: ChoiceContent
    let isWrong: Bool
    let isSolved: Bool
    var isHinted = false

    @Environment(\.layoutScale) private var scale
    @State private var pulse = false

    /// Mengen-Karten (Mehr oder weniger?) brauchen mehr Platz.
    private var maxWidth: CGFloat {
        if case .group = content { return 260 * scale }
        return 160 * scale
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            ChoiceContentView(content: content)
                .padding(16)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: maxWidth)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: 6)
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
        .scaleEffect(isSolved ? 1.08 : (isHinted && pulse ? 1.07 : 1))
        .opacity(isWrong ? 0.3 : 1)
        .onChange(of: isHinted) { hinted in
            if hinted {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                pulse = false
            }
        }
    }

    private var borderColor: Color {
        if isSolved { return .green }
        if isHinted { return Color(red: 1.0, green: 0.78, blue: 0.1) }
        return .clear
    }
}

struct ChoiceContentView: View {
    let content: ChoiceContent

    @Environment(\.layoutScale) private var scale

    var body: some View {
        switch content {
        case let .number(value):
            Text("\(value)")
                .font(.system(size: 72 * scale, weight: .heavy, design: .rounded))
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
                .font(.system(size: 80 * scale))
                .minimumScaleFactor(0.3)
        case let .group(emoji, count):
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: count <= 4 ? 2 : (count <= 6 ? 3 : 4))
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<count, id: \.self) { _ in
                    Text(emoji)
                        .font(.system(size: (count <= 4 ? 40 : (count <= 6 ? 32 : 24)) * scale))
                        .minimumScaleFactor(0.5)
                }
            }
        case let .claps(count):
            let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: count == 1 ? 1 : 2)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<count, id: \.self) { _ in
                    Text("👏")
                        .font(.system(size: (count == 1 ? 64 : 38) * scale))
                        .minimumScaleFactor(0.5)
                }
            }
        case let .clock(hour, minute):
            ClockFace(hour: hour, minute: minute)
        }
    }
}

/// Analoge Kinderuhr: kurzer, dicker roter Stundenzeiger, langer blauer Minutenzeiger.
struct ClockFace: View {
    let hour: Int
    let minute: Int

    private let ink = Color(red: 0.25, green: 0.2, blue: 0.4)

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            ZStack {
                Circle().fill(Color.white)
                Circle().stroke(ink, lineWidth: size * 0.05)
                ForEach(1...12, id: \.self) { number in
                    let angle = Double(number) / 12 * 2 * .pi - .pi / 2
                    Text("\(number)")
                        .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                        .foregroundColor(ink)
                        .position(
                            x: radius + cos(angle) * radius * 0.74,
                            y: radius + sin(angle) * radius * 0.74
                        )
                }
                hand(length: radius * 0.48, width: size * 0.07, degrees: (Double(hour % 12) + Double(minute) / 60) * 30,
                     color: Color(red: 0.9, green: 0.25, blue: 0.25))
                hand(length: radius * 0.75, width: size * 0.04, degrees: Double(minute) * 6,
                     color: Color(red: 0.2, green: 0.45, blue: 0.95))
                Circle().fill(ink).frame(width: size * 0.09, height: size * 0.09)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func hand(length: CGFloat, width: CGFloat, degrees: Double, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(degrees))
    }
}
