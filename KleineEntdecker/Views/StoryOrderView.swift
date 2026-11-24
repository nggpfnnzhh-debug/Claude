import SwiftUI

/// Bildergeschichten: Die Bilder liegen gemischt unten und werden der Reihe nach angetippt.
struct StoryOrderView: View {
    let game: Game
    let onExit: () -> Void

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.layoutScale) private var scale
    @State private var tasks: [StoryTask] = []
    @State private var index = 0
    /// Wie viele Bilder schon richtig gelegt sind.
    @State private var placed = 0
    @State private var wrongStep: Int?
    @State private var mistakesInTask = 0
    @State private var firstTryCount = 0
    @State private var hintActive = false
    @State private var showTapArea = true
    @State private var solved = false
    @State private var finished = false

    private var currentTask: StoryTask? {
        tasks.indices.contains(index) ? tasks[index] : nil
    }

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
                    // Die Geschichte entsteht oben: nummerierte Felder füllen sich nacheinander.
                    HStack(spacing: 8 * scale) {
                        ForEach(task.story.steps.indices, id: \.self) { step in
                            StorySlot(number: step + 1, emoji: step < placed ? task.story.steps[step].emoji : nil, tint: game.tint, side: cardSide(for: task))
                        }
                    }
                    .id(task.id)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 24 * scale, weight: .bold))
                        .foregroundColor(game.tint.opacity(0.6))
                    HStack(spacing: 8 * scale) {
                        ForEach(task.shuffledIndices, id: \.self) { step in
                            let used = step < placed
                            Button {
                                select(step, in: task)
                            } label: {
                                StoryCard(
                                    emoji: task.story.steps[step].emoji,
                                    side: cardSide(for: task),
                                    isWrong: wrongStep == step,
                                    isHinted: hintActive && step == placed
                                )
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .opacity(used ? 0.15 : 1)
                            .disabled(used || solved)
                            .accessibilityLabel(task.story.steps[step].caption)
                        }
                    }
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
        .task(id: solved) {
            guard solved else { return }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await Speaker.shared.waitUntilQuiet()
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    /// Drei Bilder dürfen größer sein als vier – beides passt auch auf kleine iPhones.
    private func cardSide(for task: StoryTask) -> CGFloat {
        (task.story.steps.count == 3 ? 96 : 74) * scale
    }

    private func start() {
        tasks = Stories.tasks(level: progress.level(for: game))
        index = 0
        firstTryCount = 0
        resetTaskState()
        withAnimation { finished = false }
        showTapArea = true
        Speaker.shared.say(Stories.instruction)
    }

    private func resetTaskState() {
        placed = 0
        wrongStep = nil
        mistakesInTask = 0
        hintActive = false
        solved = false
    }

    private func repeatInstruction() {
        guard currentTask != nil, !solved else { return }
        Speaker.shared.say(Stories.instruction)
    }

    private func select(_ step: Int, in task: StoryTask) {
        guard !solved else { return }
        withAnimation { showTapArea = false }

        if step == placed {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                placed += 1
                wrongStep = nil
                hintActive = false
            }
            let caption = task.story.steps[step].caption
            if placed == task.story.steps.count {
                if mistakesInTask == 0 { firstTryCount += 1 }
                Haptics.success()
                withAnimation { solved = true }
                Speaker.shared.say("\(caption) \(Phrases.praise(afterMistakes: mistakesInTask > 0))")
            } else {
                Haptics.soft()
                Speaker.shared.say(caption)
            }
        } else {
            mistakesInTask += 1
            Haptics.soft()
            withAnimation(.easeOut(duration: 0.2)) { wrongStep = step }
            var feedback = Stories.later
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
            Speaker.shared.say(Stories.instruction)
        } else {
            progress.completeRound(for: game, result: RoundResult(firstTry: firstTryCount, total: tasks.count))
            withAnimation(.spring()) { finished = true }
        }
    }
}

private struct StorySlot: View {
    let number: Int
    let emoji: String?
    let tint: Color
    let side: CGFloat

    @Environment(\.layoutScale) private var scale

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(emoji == nil ? Color.white.opacity(0.5) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(tint.opacity(emoji == nil ? 0.6 : 0), style: StrokeStyle(lineWidth: 3, dash: [6]))
                )
            if let emoji {
                Text(emoji)
                    .font(.system(size: side * 0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale)
            }
            Text("\(number)")
                .font(.system(size: 14 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 24 * scale, height: 24 * scale)
                .background(Circle().fill(tint))
                .offset(x: -6, y: -6)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

private struct StoryCard: View {
    let emoji: String
    let side: CGFloat
    let isWrong: Bool
    let isHinted: Bool

    @Environment(\.layoutScale) private var scale
    @State private var pulse = false

    var body: some View {
        Text(emoji)
            .font(.system(size: side * 0.64))
            .frame(width: side, height: side)
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
