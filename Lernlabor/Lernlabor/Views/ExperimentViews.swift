import SwiftUI

/// Ein Selbstversuch von der Vermutung bis zum Ergebnis
struct ExperimentFlowView: View {
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

    let kind: ExperimentKind

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase
    @State private var run: ExperimentRun
    @State private var order: [ExperimentItem]
    @State private var answer = ""
    @State private var checked: Bool?
    @State private var options: [String] = []
    @State private var canContinue = false
    @State private var sum = (a: 0, b: 0)
    @FocusState private var fieldFocused: Bool

    /// Mit `pending` startet direkt der Test nach der Pause.
    init(kind: ExperimentKind, pending: ExperimentRun? = nil) {
        self.kind = kind
        _order = State(initialValue: kind.items.shuffled())
        if let pending {
            _phase = State(initialValue: .test(0))
            _run = State(initialValue: pending)
        } else {
            let screen = LaunchOptions.screenshotScreen
            let startPhase: Phase = (screen == "experiment" && kind == .rereadQuiz) || (screen == "explain" && kind == .explainRead)
                ? .study(2) : .predict
            _phase = State(initialValue: startPhase)
            _run = State(initialValue: ExperimentRun(kind: kind, prediction: nil,
                                                     assignment: Experiments.randomAssignment(for: kind),
                                                     learnedAt: .now))
        }
    }

    var body: some View {
        NavigationStack {
            Page { content }
                .navigationTitle(kind.title)
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
                    try? await Task.sleep(for: .seconds(kind.gateSeconds))
                    canContinue = true
                }
                .onAppear { prepareOptionsIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .predict:
            predictView
        case .study(let index):
            progress(index, label: "Runde 1 · Einprägen")
            Text(kind == .rereadQuiz ? "Präg dir jedes Wortpaar ein." : "Lies den Fakt aufmerksam.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            ItemCard(item: order[index], showsAnswer: true)
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
            ForEach(kind.methods, id: \.self) { method in
                Button(method.choice) {
                    run.prediction = method
                    phase = .study(0)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Button("Kein Unterschied") {
                run.prediction = nil
                phase = .study(0)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    @ViewBuilder
    private func practiceView(_ index: Int) -> some View {
        let item = order[index]
        progress(index, label: "Runde 2 · Üben")
        switch run.assignment[item.id] ?? .reread {
        case .reread:
            Text(kind == .rereadQuiz ? "**Lies** das Wortpaar noch einmal." : "**Lies** den Fakt noch einmal aufmerksam.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            ItemCard(item: item, showsAnswer: true)
            Button("Weiter") { nextPractice(after: index) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
        case .explain:
            Text("**Erklär** das laut in eigenen Worten, als würdest du es jemandem beibringen. Sag auch, warum es so ist.")
                .font(.subheadline).foregroundStyle(Theme.muted)
            ItemCard(item: item, showsAnswer: true)
            Button("Erklärt") { nextPractice(after: index) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
        case .quiz:
            if case .word(let pair) = item {
                if let checked {
                    ItemCard(item: item, showsAnswer: true)
                    Text(checked ? "Richtig!" : "Noch nicht. Präg dir die Lösung ein.")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(checked ? Theme.good : Theme.bad)
                    Button("Weiter") { nextPractice(after: index) }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Text("**Frag dich ab:** Was heißt das Wort?").font(.subheadline).foregroundStyle(Theme.muted)
                    ItemCard(item: item, showsAnswer: false)
                    answerField(prompt: "Auf Deutsch") { checked = RereadVsQuiz.isCorrect(answer, for: pair) }
                    Button("Prüfen") { checked = RereadVsQuiz.isCorrect(answer, for: pair) }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
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
                Task { await Reminder.scheduleTest(kind, at: due) }
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
            Text("Der Test wartet im Labor auf dich. Bitte wiederhol den Stoff nicht zwischendurch, sonst verfälscht das den Versuch.")
            Button("Fertig") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    @ViewBuilder
    private func distractView(_ step: Int) -> some View {
        Eyebrow("Kurze Ablenkung · \(step + 1) von 5")
        Text("Rechne im Kopf").font(.heading)
        Text("Damit der Stoff nicht mehr frisch im Kopf ist.").foregroundStyle(Theme.muted)
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
        let item = order[index]
        progress(index, label: "Test")
        switch item {
        case .word(let pair):
            Text("Was heißt das Wort? Keine Ahnung? Einfach leer lassen.").font(.subheadline).foregroundStyle(Theme.muted)
            ItemCard(item: item, showsAnswer: false)
            answerField(prompt: "Auf Deutsch") { record(item, correct: RereadVsQuiz.isCorrect(answer, for: pair), index: index) }
            Button("Weiter") { record(item, correct: RereadVsQuiz.isCorrect(answer, for: pair), index: index) }
                .buttonStyle(PrimaryButtonStyle())
        case .fact(let fact):
            Text(fact.question).font(.heading)
            VStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button { record(item, correct: option == fact.answer, index: index) } label: {
                        Text(option)
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button("Weiß ich nicht") { record(item, correct: false, index: index) }
                .font(.subheadline.weight(.medium))
        }
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
        prepareOptionsIfNeeded()
    }

    /// Antwortmöglichkeiten für Fakten-Fragen in zufälliger Reihenfolge
    private func prepareOptionsIfNeeded() {
        guard case .test(let index) = phase, case .fact(let fact) = order[index] else { return }
        options = ([fact.answer] + fact.wrong).shuffled()
    }

    private func record(_ item: ExperimentItem, correct: Bool, index: Int) {
        run.results[item.id] = correct
        answer = ""
        if index + 1 < order.count {
            phase = .test(index + 1)
            prepareOptionsIfNeeded()
        } else {
            run.testedAt = .now
            model.complete(run)
            phase = .result
        }
    }
}

/// Wortpaar oder Fakt als Karte
struct ItemCard: View {
    let item: ExperimentItem
    let showsAnswer: Bool

    var body: some View {
        Group {
            switch item {
            case .word(let pair):
                VStack(spacing: 6) {
                    Text(pair.swahili).font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("heißt").font(.subheadline).foregroundStyle(Theme.muted)
                    Text(showsAnswer ? pair.german : "?").font(.title2.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            case .fact(let fact):
                Text(fact.text)
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 18)
        .card()
        .accessibilityElement(children: .combine)
    }
}

struct ExperimentResultContent: View {
    let run: ExperimentRun

    var body: some View {
        let verdict = Experiments.verdict(for: run)
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("Dein Ergebnis · \(run.kind.shortTitle)")
            Text(verdict.title).font(.heading)
            HStack(spacing: 12) {
                ForEach(run.kind.methods, id: \.self) { method in
                    scoreTile(method.resultLabel, run.correct(method))
                }
            }
            Text(verdict.detail)
            Text("Deine Vermutung war: **\(Experiments.predictionText(run.prediction))**. \(Experiments.predictionFeedback(prediction: run.prediction, winner: verdict.winner))")
                .font(.subheadline)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 3) }
            if !run.delayed {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Gut zu wissen")
                    Text("Du hast sofort getestet. Direkt danach schneidet Nochmal-Lesen oft gut ab. Der Vorteil anderer Methoden zeigt sich in Studien meist erst nach Tagen (zum Beispiel Roediger & Karpicke, 2006). Mach den Versuch nochmal mit 2 Tagen Pause.")
                        .font(.subheadline)
                }
                .card()
            }
            DisclosureGroup("Was saß, was nicht?") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(run.kind.methods, id: \.self) { method in
                        itemList(method)
                    }
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
                Text("/ \(run.kind.perMethod)").foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func itemList(_ method: StudyMethod) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(method.resultLabel).font(.footnote).foregroundStyle(Theme.muted)
            ForEach(run.kind.items.filter { run.assignment[$0.id] == method }) { item in
                let ok = run.results[item.id] ?? false
                Label(item.label, systemImage: ok ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(ok ? Theme.good : Theme.bad)
            }
        }
    }
}

struct LabView: View {
    struct FlowRequest: Identifiable {
        let kind: ExperimentKind
        let continuesPending: Bool
        var id: String { kind.rawValue + (continuesPending ? "-test" : "-neu") }
    }

    private struct Upcoming: Identifiable {
        let icon: String
        let title: String
        let subtitle: String
        var id: String { title }
    }

    @Environment(AppModel.self) private var model
    @Environment(Purchases.self) private var purchases
    @State private var flow: FlowRequest?
    @State private var showPremium = false

    private let upcoming = [
        Upcoming(icon: "timer", title: "Am Stück oder verteilt?", subtitle: "Einmal 15 oder dreimal 5 Minuten"),
        Upcoming(icon: "ear", title: "Hören, Lesen oder Schreiben?", subtitle: "Gibt es bei dir einen Unterschied?"),
        Upcoming(icon: "sunrise", title: "Lerche oder Eule?", subtitle: "Morgens oder abends lernen"),
    ]

    var body: some View {
        NavigationStack {
            Page {
                Text("Labor").font(.display)

                ForEach(model.pendingRuns) { pending in
                    let due = Date.now >= pending.dueDate
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Läuft")
                        Text("„\(pending.kind.shortTitle)“: gelernt am \(pending.learnedAt.formatted(date: .abbreviated, time: .omitted)). " +
                             (due ? "Der Test ist fällig." : "Empfohlener Test ab \(pending.dueDate.formatted(.dateTime.weekday(.wide)))."))
                        Button(due ? "Jetzt testen" : "Trotzdem jetzt testen") {
                            flow = FlowRequest(kind: pending.kind, continuesPending: true)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        Button("Versuch verwerfen", role: .destructive) { model.discardPending(pending.kind) }
                            .font(.subheadline.weight(.medium))
                    }
                    .card()
                }

                ForEach(ExperimentKind.allCases) { kind in
                    experimentCard(kind)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow("Kommt mit den nächsten Updates")
                    ForEach(upcoming) { item in
                        EntryRow(title: item.title, subtitle: item.subtitle, meta: "bald") {
                            Image(systemName: item.icon).font(.title2).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
            .fullScreenCover(item: $flow) { request in
                ExperimentFlowView(kind: request.kind,
                                   pending: request.continuesPending ? model.pending(request.kind) : nil)
            }
            .sheet(isPresented: $showPremium) { PremiumView() }
            .onAppear {
                guard flow == nil else { return }
                switch LaunchOptions.screenshotScreen {
                case "experiment": flow = FlowRequest(kind: .rereadQuiz, continuesPending: false)
                case "explain": flow = FlowRequest(kind: .explainRead, continuesPending: false)
                default: break
                }
            }
        }
    }

    private func experimentCard(_ kind: ExperimentKind) -> some View {
        let available = kind.isFree || purchases.unlocked
        let doneCount = model.runs(of: kind).count
        return VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Selbstversuch \(kind.number) · " + (kind.isFree ? "kostenlos" : "Vollversion"))
            Text(kind.title).font(.heading)
            Text(kind.summary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(kind.details, id: \.self) { detail in
                    Label(detail.text, systemImage: detail.icon)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.muted)
            if model.pending(kind) == nil {
                if available {
                    Button("Versuch starten") { flow = FlowRequest(kind: kind, continuesPending: false) }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button { showPremium = true } label: {
                        Label("Mit der Vollversion freischalten", systemImage: "lock")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            if doneCount > 0 {
                Text("Schon \(doneCount)× gemacht. Ergebnisse im Profil.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
            }
        }
        .card()
    }
}
