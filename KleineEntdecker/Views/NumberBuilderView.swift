import SwiftUI

/// „Zahlen bauen“: Zehnerstangen ansehen, dann die Zahl aus zwei Ziffern zusammensetzen.
struct NumberBuilderView: View {
    let game: Game
    let onExit: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.layoutScale) private var scale
    @State private var tasks: [BuildTask] = []
    @State private var index = 0
    /// Gesetzte Ziffern: [Zehner, Einer].
    @State private var slots: [Int?] = [nil, nil]
    @State private var wrongDigit: Int?
    @State private var mistakesInTask = 0
    @State private var firstTryCount = 0
    @State private var hintActive = false
    @State private var showTapArea = true
    @State private var solved = false
    @State private var finished = false

    private var currentTask: BuildTask? {
        tasks.indices.contains(index) ? tasks[index] : nil
    }

    /// Welches Feld gerade gefüllt wird: 0 = Zehner, 1 = Einer.
    private var activeSlot: Int {
        slots[0] == nil ? 0 : 1
    }

    private var expectedDigit: Int? {
        guard let task = currentTask else { return nil }
        return activeSlot == 0 ? task.tens : task.ones
    }

    private let padColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        ZStack {
            game.tint.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 16 * scale) {
                GameTopBar(
                    tint: game.tint,
                    completed: index + (solved ? 1 : 0),
                    total: tasks.count,
                    onExit: onExit,
                    onRepeat: repeatInstruction
                )

                if let task = currentTask {
                    Spacer(minLength: 0)
                    TensOnesView(tens: task.tens, ones: task.ones, tint: game.tint)
                        .id(task.id)
                    DigitSlotsView(slots: slots, activeSlot: solved ? nil : activeSlot, tint: game.tint)
                    Spacer(minLength: 0)
                    LazyVGrid(columns: padColumns, spacing: 10) {
                        ForEach(0..<10, id: \.self) { digit in
                            Button {
                                select(digit, in: task)
                            } label: {
                                DigitKey(
                                    digit: digit,
                                    isWrong: wrongDigit == digit,
                                    isHinted: hintActive && !solved && expectedDigit == digit
                                )
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .accessibilityLabel("\(digit)")
                        }
                    }
                    .frame(maxWidth: 520 * scale)
                    .tapArea(active: index == 0 && showTapArea, tint: game.tint)
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
        // Wie im Quiz: erst weiter, wenn Huhu fertig gesprochen hat.
        .task(id: solved) {
            guard solved else { return }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await Speaker.shared.waitUntilQuiet()
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    private func start() {
        tasks = NumberBuilder.tasks(level: progress.level(for: game))
        index = 0
        firstTryCount = 0
        resetTaskState()
        withAnimation { finished = false }
        showTapArea = true
        Speaker.shared.say(instruction(for: 0))
    }

    private func resetTaskState() {
        slots = [nil, nil]
        wrongDigit = nil
        mistakesInTask = 0
        hintActive = false
        solved = false
    }

    private func instruction(for taskIndex: Int) -> String {
        guard tasks.indices.contains(taskIndex) else { return "" }
        let base = NumberBuilder.instruction(for: tasks[taskIndex].number)
        if taskIndex == 0, let hint = game.tapHint {
            return "\(base) \(hint)"
        }
        return base
    }

    private func repeatInstruction() {
        guard currentTask != nil, !solved else { return }
        Speaker.shared.say(instruction(for: index))
    }

    private func select(_ digit: Int, in task: BuildTask) {
        guard !solved, let expected = expectedDigit else { return }
        withAnimation { showTapArea = false }

        if digit == expected {
            let slot = activeSlot
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                slots[slot] = digit
                wrongDigit = nil
                hintActive = false
            }
            if slot == 0 {
                Haptics.soft()
                Speaker.shared.say(NumberBuilder.tensText(digit))
            } else {
                if mistakesInTask == 0 { firstTryCount += 1 }
                Haptics.success()
                withAnimation { solved = true }
                let praise = Phrases.praise(afterMistakes: mistakesInTask > 0)
                Speaker.shared.say("\(NumberBuilder.onesText(digit)) \(praise) \(NumberBuilder.solvedText(for: task.number))")
            }
        } else {
            mistakesInTask += 1
            Haptics.soft()
            withAnimation(.easeOut(duration: 0.2)) { wrongDigit = digit }
            var feedback: String
            if activeSlot == 0 {
                // Zahlendreher erkannt: Das Kind hat die Einerziffer zuerst gewählt.
                feedback = digit == task.ones && task.ones != task.tens
                    ? "\(NumberBuilder.tensFirst) \(NumberBuilder.countTens)"
                    : NumberBuilder.countTens
            } else {
                feedback = NumberBuilder.countOnes
            }
            if mistakesInTask >= 2 {
                withAnimation(.easeInOut) { hintActive = true }
                feedback += " \(Lines.hint)"
            }
            Speaker.shared.say(feedback)
        }
    }

    private func advance() {
        if index + 1 < tasks.count {
            withAnimation(.easeInOut) {
                index += 1
                resetTaskState()
            }
            Speaker.shared.say(instruction(for: index))
        } else {
            progress.completeRound(for: game, result: RoundResult(firstTry: firstTryCount, total: tasks.count))
            withAnimation(.spring()) { finished = true }
        }
    }
}

/// Zehnerstangen (je zehn Punkte) und einzelne Punkte – wie das Material aus Kita und Schule.
struct TensOnesView: View {
    let tens: Int
    let ones: Int
    let tint: Color

    @Environment(\.layoutScale) private var scale

    private var dot: CGFloat { 12 * scale }

    var body: some View {
        HStack(alignment: .bottom, spacing: 14 * scale) {
            HStack(alignment: .bottom, spacing: 6 * scale) {
                ForEach(0..<tens, id: \.self) { _ in
                    VStack(spacing: 3 * scale) {
                        ForEach(0..<10, id: \.self) { _ in
                            Circle().fill(Color.white).frame(width: dot, height: dot)
                        }
                    }
                    .padding(4 * scale)
                    .background(Capsule().fill(tint))
                }
            }
            if ones > 0 {
                // Einer in Fünferspalten, damit man sie leicht zählen kann.
                HStack(alignment: .bottom, spacing: 4 * scale) {
                    ForEach(0..<((ones + 4) / 5), id: \.self) { column in
                        VStack(spacing: 3 * scale) {
                            ForEach(0..<min(5, ones - column * 5), id: \.self) { _ in
                                Circle().fill(Color.orange).frame(width: dot + 4 * scale, height: dot + 4 * scale)
                            }
                        }
                    }
                }
            }
        }
        .padding(16 * scale)
        .frame(maxWidth: .infinity)
        .cardBackground(cornerRadius: 28)
        .frame(maxWidth: 560 * scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tens) Zehnerstangen und \(ones) einzelne Punkte")
    }
}

/// Die beiden Felder für Zehner und Einer.
struct DigitSlotsView: View {
    let slots: [Int?]
    let activeSlot: Int?
    let tint: Color

    @Environment(\.layoutScale) private var scale

    var body: some View {
        HStack(spacing: 14 * scale) {
            ForEach(0..<2, id: \.self) { slot in
                VStack(spacing: 4) {
                    Text(slots[slot].map(String.init) ?? " ")
                        .font(.system(size: 64 * scale, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .frame(width: 92 * scale, height: 108 * scale)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(activeSlot == slot ? tint : Color.gray.opacity(0.25), lineWidth: activeSlot == slot ? 5 : 2)
                        )
                    // Kleine Bildhilfe unter dem Feld: Stange für Zehner, Punkt für Einer.
                    Image(systemName: slot == 0 ? "rectangle.portrait.fill" : "circle.fill")
                        .font(.system(size: 14 * scale))
                        .foregroundColor(slot == 0 ? tint : .orange)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(slot == 0 ? "Zehner: \(slots[0].map(String.init) ?? "leer")" : "Einer: \(slots[1].map(String.init) ?? "leer")")
            }
        }
    }
}

struct DigitKey: View {
    let digit: Int
    let isWrong: Bool
    let isHinted: Bool

    @Environment(\.layoutScale) private var scale
    @State private var pulse = false

    var body: some View {
        Text("\(digit)")
            .font(.system(size: 34 * scale, weight: .heavy, design: .rounded))
            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 64 * scale)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isHinted ? Color.yellow : Color.clear, lineWidth: 5)
            )
            .scaleEffect(isHinted && pulse ? 1.08 : 1)
            .opacity(isWrong ? 0.4 : 1)
            .onChange(of: isHinted) { hinted in
                if hinted {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
                } else {
                    pulse = false
                }
            }
    }
}
