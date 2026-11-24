import SwiftUI

struct TestIntroView: View {
    var body: some View {
        Page {
            Text("Lerne deine Tiere kennen").font(.heading)
            Text("Fünf Tiere stehen für fünf Seiten deiner Persönlichkeit. Du hast alle fünf in dir, nur unterschiedlich stark.")

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Trait.displayOrder) { trait in
                    HStack(spacing: 12) {
                        AnimalIcon(trait: trait, size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(trait.animal.name) · \(trait.animal.traitName)").font(.body.weight(.semibold))
                            Text(trait.animal.short).font(.subheadline).foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
            .card()

            Text("Grundlage ist das Big-Five-Modell der Psychologie, gemessen mit einem kurzen, frei verfügbaren Fragebogen (Mini-IPIP). Das Ergebnis ist eine Selbsteinschätzung, keine Diagnose.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)

            NavigationLink("Los geht's", value: HomeRoute.test)
                .buttonStyle(PrimaryButtonStyle())
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PersonalityTestView: View {
    @Environment(AppModel.self) private var model
    @State private var index = 0
    @State private var answers: [Int?] = Array(repeating: nil, count: PersonalityTest.statements.count)

    private var count: Int { PersonalityTest.statements.count }

    var body: some View {
        Page {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(index), total: Double(count))
                    .tint(Theme.accent)
                Eyebrow("Aussage \(index + 1) von \(count)")
            }

            Text(PersonalityTest.statements[index].text)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
                .id(index)

            VStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    let selected = answers[index] == value
                    Button { choose(value) } label: {
                        Text(PersonalityTest.scale[value - 1])
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(selected ? Theme.accentSoft : Theme.surface,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selected ? Theme.accent : Theme.line, lineWidth: selected ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }

            if index > 0 {
                Button("Vorherige Aussage") { index -= 1 }
                    .font(.subheadline.weight(.medium))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choose(_ value: Int) {
        answers[index] = value
        if index < count - 1 {
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                index += 1
            }
        } else {
            model.savePersonality(answers: answers)
            model.homePath = [.result]
        }
    }
}

struct PersonalityResultView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let scores = model.scores
        let top = PersonalityTest.topTwo(scores)
        Page {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Dein Ergebnis")
                Text("Bei dir stechen \(top[0].animal.name) und \(top[1].animal.name) heraus")
                    .font(.heading)
            }
            Text("Die Zahl vergleicht dich mit anderen Menschen: 80 heißt, bei dir ist diese Seite stärker als bei etwa 80 von 100 Menschen. 50 ist genau Durchschnitt. Ein niedriger Wert ist keine Schwäche.")
                .foregroundStyle(Theme.muted)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Trait.displayOrder) { trait in
                    AnimalBarRow(trait: trait, score: scores[trait] ?? 50, showTip: true)
                }
            }
            .card()

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Vermutung zum Testen")
                Text(PersonalityTest.hypothesis(for: scores))
            }
            .card()

            Button("Zum Selbstversuch") { model.selectedTab = .lab }
                .buttonStyle(PrimaryButtonStyle())

            Text("Kurzer Fragebogen mit 20 Aussagen, vorläufige Vergleichswerte aus einer US-Studie. Persönlichkeit sagt viel darüber, wie du dranbleibst, aber nicht, welche Lernmethode wirkt. Das zeigen die Selbstversuche.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.homePath == [.result])
        .toolbar {
            if model.homePath == [.result] {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Start") { model.homePath = [] }
                }
            }
        }
    }
}
