import SwiftUI

/// Selbstversuch „Lesen oder Abfragen?“ von der Vermutung bis zum Ergebnis
struct ExperimentFlowView: View {
    enum Start: Identifiable {
        case new, pendingTest
        var id: Self { self }
    }

    enum Phase: Hashable {
        case predict
        case study(Int)
        case practice(Int)
        case pause
        case saved
        case distract(Int)
        case test(Int)
        case result
    }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase
    @State private var run: ExperimentRun
    @State private var order: [WordPair] = RereadVsQuiz.words.shuffled()
    @State private var answer = ""
    @State private var checked: Bool?
    @State private var canContinue = false
    @State private var sum = (a: 0, b: 0)
    @FocusState private var fieldFocused: Bool

    init(start: Start, pending: ExperimentRun? = nil) {
        if start == .pendingTest, let pending {
            _phase = State(initialValue: .test(0))
            _run = State(initialValue: pending)
        } else {
            let screenshot = LaunchOptions.screenshotScreen == "experiment"
            _phase = State(initialValue: screenshot ? .study(2) : .predict)
            _run = State(initialValue: ExperimentRun(prediction: .same,
                                                     assignment: RereadVsQuiz.randomAssignment(),
                                                     learnedAt: .now))
        }
    }

    var body: some View {
        NavigationStack {
            Page { content }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if phase != .result && phase != .saved {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") { dismiss() }
                        }
                    }
                }
                .task(id: phase) {
                    canContinue = false
                    try? await Task.sleep(for: .seconds(2.5))
                    canContinue = true
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .predict:
            predictView
        case .study(let index):
            progress(index, label: "Runde 1 · Einprägen")
            Text("Präg dir jedes Wortpaar ein.").font(.subheadline).foregroundStyle(Theme.muted)
            WordCard(pair: order[index], showsAnswer: true)
            Button("Weiter") { nextStudy(after: index) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
        case .practice(let index):
            practiceView(index)
        case .pause:
            pauseView
        case .saved:
            savedView
        case .distract(let step):
            distractView(step)
        case .test(let index):
            testView(index)
        case .result:
            ExperimentResultContent(run: run)
            Button("Zu meinem Lernprofil") {
                model.selectedTab = .profile
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Fertig") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: Teilansichten

    private var predictView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("Bevor es losgeht")
            Text("Was glaubst du: Was bleibt bei dir besser hängen?").font(.heading)
            Text("Deine Vermutung vergleichen wir am Ende mit dem Ergebnis.").foregroundStyle(Theme.muted)
            ForEach([Prediction.reread, .quiz, .same], id: \.self) { prediction in
                Button(prediction == .quiz ? "Mich selbst abfragen" : prediction.text) {
                    run.prediction = prediction
                    phase = .study(0)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func practiceView(_ index: Int) -> some View {
        let pair = order[index]
        progress(index, label: "Runde 2 · Üben")
        if run.assignment[pair.swahili] == .reread {
            Text("**Lies** das Wortpaar noch einmal.").font(.subheadline).foregroundStyle(Theme.muted)
            WordCard(pair: pair, showsAnswer: true)
            Button("Weiter") { nextPractice(after: index) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
        } else if let checked {
            WordCard(pair: pair, showsAnswer: true)
            Text(checked ? "Richtig!" : "Noch nicht. Präg dir die Lösung ein.")
                .font(.body.weight(.semibold))
                .foregroundStyle(checked ? Theme.good : Theme.bad)
            Button("Weiter") { nextPractice(after: index) }
                .buttonStyle(PrimaryButtonStyle())
        } else {
            Text("**Frag dich ab:** Was heißt das Wort?").font(.subheadline).foregroundStyle(Theme.muted)
            WordCard(pair: pair, showsAnswer: false)
            answerField(prompt: "Auf Deutsch") { checkPractice(pair) }
            Button("Prüfen") { checkPractice(pair) }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var pauseView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("Geschafft")
            Text("Jetzt kommt das Wichtigste: die Pause").font(.heading)
            Text("Was direkt danach noch da ist, sagt wenig. Entscheidend ist, was nach ein paar Tagen hängen bleibt. Genau da zeigen sich die Unterschiede zwischen Methoden meist erst.")
            Button("In 2 Tagen testen (empfohlen)") {
                run.learnedAt = .now
                model.startPending(run)
                let due = run.dueDate
                Task { await Reminder.scheduleTest(at: due) }
                phase = .saved
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Jetzt testen (Schnell-Demo)") {
                run.learnedAt = .now
                startDistraction(0)
            }
            .buttonStyle(SecondaryButtonStyle())
            Text("Wenn du es erlaubst, erinnert dich die App an den Test.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
    }

    private var savedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("Gespeichert")
            Text("Bis in 2 Tagen!").font(.heading)
            Text("Der Test wartet im Labor auf dich. Bitte wiederhol die Wörter nicht zwischendurch, sonst verfälscht das den Versuch.")
            Button("Fertig") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    @ViewBuilder
    private func distractView(_ step: Int) -> some View {
        Eyebrow("Kurze Ablenkung · \(step + 1) von 5")
        Text("Rechne im Kopf").font(.heading)
        Text("Damit die Wörter nicht mehr frisch im Kopf sind.").foregroundStyle(Theme.muted)
        Text("\(sum.a) − \(sum.b)")
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .card()
        answerField(prompt: "Ergebnis", numeric: true) { startDistraction(step + 1) }
        Button("Weiter") { startDistraction(step + 1) }
            .buttonStyle(PrimaryButtonStyle())
        Button("Überspringen") { beginTest() }
            .font(.subheadline.weight(.medium))
    }

    @ViewBuilder
    private func testView(_ index: Int) -> some View {
        let pair = order[index]
        progress(index, label: "Test")
        Text("Was heißt das Wort? Keine Ahnung? Einfach leer lassen.").font(.subheadline).foregroundStyle(Theme.muted)
        WordCard(pair: pair, showsAnswer: false)
        answerField(prompt: "Auf Deutsch") { submitTest(pair, index: index) }
        Button("Weiter") { submitTest(pair, index: index) }
            .buttonStyle(PrimaryButtonStyle())
    }

    private func progress(_ index: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: Double(index), total: Double(order.count)).tint(Theme.accent)
            Eyebrow("\(label) · \(index + 1) von \(order.count)")
        }
    }

    private func answerField(prompt: String, numeric: Bool = false, onSubmit: @escaping () -> Void) -> some View {
        TextField(prompt, text: $answer)
            .font(.title3)
            .keyboardType(numeric ? .numberPad : .default)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused($fieldFocused)
            .onSubmit(onSubmit)
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
            .onAppear { fieldFocused = true }
    }

    // MARK: Ablauf

    private func nextStudy(after index: Int) {
        if index + 1 < order.count {
            phase = .study(index + 1)
        } else {
            order.shuffle()
            phase = .practice(0)
        }
    }

    private func checkPractice(_ pair: WordPair) {
        checked = RereadVsQuiz.isCorrect(answer, for: pair)
    }

    private func nextPractice(after index: Int) {
        answer = ""
        checked = nil
        phase = index + 1 < order.count ? .practice(index + 1) : .pause
    }

    private func startDistraction(_ step: Int) {
        answer = ""
        guard step < 5 else { return beginTest() }
        sum = (a: Int.random(in: 40...99), b: Int.random(in: 6...18))
        phase = .distract(step)
    }

    private func beginTest() {
        answer = ""
        order.shuffle()
        phase = .test(0)
    }

    private func submitTest(_ pair: WordPair, index: Int) {
        run.results[pair.swahili] = RereadVsQuiz.isCorrect(answer, for: pair)
        answer = ""
        if index + 1 < order.count {
            phase = .test(index + 1)
        } else {
            run.testedAt = .now
            model.complete(run)
            phase = .result
        }
    }
}

struct WordCard: View {
    let pair: WordPair
    let showsAnswer: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(pair.swahili).font(.system(size: 40, weight: .bold, design: .rounded))
            Text("heißt").font(.subheadline).foregroundStyle(Theme.muted)
            Text(showsAnswer ? pair.german : "?").font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .card()
        .accessibilityElement(children: .combine)
    }
}

struct ExperimentResultContent: View {
    let run: ExperimentRun

    var body: some View {
        let reread = run.correct(.reread)
        let quiz = run.correct(.quiz)
        let verdict = RereadVsQuiz.verdict(reread: reread, quiz: quiz)
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("Dein Ergebnis")
            Text(verdict.title).font(.heading)
            HStack(spacing: 12) {
                scoreTile("Nochmal gelesen", reread)
                scoreTile("Abgefragt", quiz)
            }
            Text(verdict.detail)
            Text("Deine Vermutung war: **\(run.prediction.text)**. \(RereadVsQuiz.predictionFeedback(prediction: run.prediction, winner: verdict.winner))")
                .font(.subheadline)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 3) }
            if !run.delayed {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Gut zu wissen")
                    Text("Du hast sofort getestet. Direkt danach schneidet Nochmal-Lesen oft gut ab. Der Vorteil des Abfragens zeigt sich in Studien meist erst nach Tagen (Roediger & Karpicke, 2006). Mach den Versuch nochmal mit 2 Tagen Pause.")
                        .font(.subheadline)
                }
                .card()
            }
            DisclosureGroup("Welche Wörter saßen?") {
                VStack(alignment: .leading, spacing: 10) {
                    wordList(.reread, title: "Nochmal gelesen")
                    wordList(.quiz, title: "Abgefragt")
                }
                .padding(.top, 8)
            }
            .tint(Theme.accent)
        }
    }

    private func scoreTile(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Eyebrow(title)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)").font(.system(size: 44, weight: .bold, design: .rounded)).monospacedDigit()
                Text("/ \(RereadVsQuiz.perMethod)").foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func wordList(_ method: Method, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.footnote).foregroundStyle(Theme.muted)
            ForEach(RereadVsQuiz.words.filter { run.assignment[$0.swahili] == method }, id: \.self) { pair in
                let ok = run.results[pair.swahili] ?? false
                Label("\(pair.swahili) = \(pair.german)", systemImage: ok ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(ok ? Theme.good : Theme.bad)
            }
        }
    }
}

struct LabView: View {
    @Environment(AppModel.self) private var model
    @Environment(Purchases.self) private var purchases
    @State private var flow: ExperimentFlowView.Start?
    @State private var showPremium = false

    private struct Upcoming: Identifiable {
        let icon: String
        let title: String
        let subtitle: String
        var id: String { title }
    }

    private let upcoming = [
        Upcoming(icon: "timer", title: "Am Stück oder verteilt?", subtitle: "Einmal 15 oder dreimal 5 Minuten"),
        Upcoming(icon: "bubble.left.and.bubble.right", title: "Erklären oder Lesen?", subtitle: "Bringt dir lautes Erklären etwas?"),
        Upcoming(icon: "ear", title: "Hören, Lesen oder Schreiben?", subtitle: "Gibt es bei dir einen Unterschied?"),
        Upcoming(icon: "sunrise", title: "Lerche oder Eule?", subtitle: "Morgens oder abends lernen"),
    ]

    var body: some View {
        NavigationStack {
            Page {
                Text("Labor").font(.display)

                if let pending = model.pendingRun {
                    let due = Date.now >= pending.dueDate
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Läuft")
                        Text("„Lesen oder Abfragen“: gelernt am \(pending.learnedAt.formatted(date: .abbreviated, time: .omitted)). " +
                             (due ? "Der Test ist fällig." : "Empfohlener Test ab \(pending.dueDate.formatted(.dateTime.weekday(.wide)))."))
                        Button(due ? "Jetzt testen" : "Trotzdem jetzt testen") { flow = .pendingTest }
                            .buttonStyle(PrimaryButtonStyle())
                        Button("Versuch verwerfen", role: .destructive) { model.discardPending() }
                            .font(.subheadline.weight(.medium))
                    }
                    .card()
                }

                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow("Selbstversuch 1 · kostenlos")
                    Text("Lesen oder Abfragen?").font(.heading)
                    Text("Du lernst 16 Wörter auf Suaheli. Die Hälfte liest du ein zweites Mal, die andere Hälfte fragst du dich selbst ab. Später testen wir alle 16 und vergleichen.")
                    VStack(alignment: .leading, spacing: 4) {
                        Label("etwa 10 Minuten, dazu ein kurzer Test später", systemImage: "clock")
                        Label("Suaheli, damit niemand Vorwissen hat", systemImage: "globe.europe.africa")
                        Label("Welches Wort in welche Gruppe kommt, entscheidet der Zufall", systemImage: "dice")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    if model.pendingRun == nil {
                        Button("Versuch starten") { flow = .new }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    if !model.runs.isEmpty {
                        Text("Schon \(model.runs.count)× gemacht. Ergebnisse im Profil.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .card()

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(purchases.hasFullVersion ? "Kommt mit den nächsten Updates" : "In der Vollversion")
                    ForEach(upcoming) { item in
                        Button { if !purchases.hasFullVersion { showPremium = true } } label: {
                            EntryRow(title: item.title, subtitle: item.subtitle,
                                     meta: purchases.hasFullVersion ? "bald" : "🔒") {
                                Image(systemName: item.icon).font(.title2).foregroundStyle(Theme.accent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .fullScreenCover(item: $flow) { start in
                ExperimentFlowView(start: start, pending: model.pendingRun)
            }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .onAppear {
                if LaunchOptions.screenshotScreen == "experiment" && flow == nil { flow = .new }
            }
        }
    }
}
