import Foundation

struct Statement {
    let trait: Trait
    /// +1: Zustimmung spricht für die Eigenschaft, −1: Aussage ist umgepolt
    let keyed: Int
    let text: String
}

/// Kurzer Big-Five-Fragebogen nach dem Mini-IPIP (Donnellan u. a. 2006, gemeinfrei, IPIP).
/// Deutsche Übersetzung für die erste Version, noch nicht wissenschaftlich geprüft.
enum PersonalityTest {
    static let statements: [Statement] = [
        Statement(trait: .extraversion, keyed: 1, text: "Auf Feiern bin ich oft der Mittelpunkt."),
        Statement(trait: .agreeableness, keyed: 1, text: "Ich fühle mit, wenn es anderen schlecht geht."),
        Statement(trait: .conscientiousness, keyed: 1, text: "Ich erledige Aufgaben sofort."),
        Statement(trait: .calmness, keyed: -1, text: "Meine Stimmung schwankt häufig."),
        Statement(trait: .openness, keyed: 1, text: "Ich habe eine lebhafte Fantasie."),
        Statement(trait: .extraversion, keyed: -1, text: "Ich rede nicht viel."),
        Statement(trait: .agreeableness, keyed: -1, text: "Die Probleme anderer interessieren mich nicht besonders."),
        Statement(trait: .conscientiousness, keyed: -1, text: "Ich vergesse oft, Dinge an ihren Platz zurückzulegen."),
        Statement(trait: .calmness, keyed: 1, text: "Meistens bin ich entspannt."),
        Statement(trait: .openness, keyed: -1, text: "Abstrakte Ideen interessieren mich nicht."),
        Statement(trait: .extraversion, keyed: 1, text: "Auf Feiern unterhalte ich mich mit vielen verschiedenen Leuten."),
        Statement(trait: .agreeableness, keyed: 1, text: "Ich spüre, wie es anderen geht."),
        Statement(trait: .conscientiousness, keyed: 1, text: "Ich mag Ordnung."),
        Statement(trait: .calmness, keyed: -1, text: "Ich rege mich schnell auf."),
        Statement(trait: .openness, keyed: -1, text: "Mit abstrakten Ideen tue ich mich schwer."),
        Statement(trait: .extraversion, keyed: -1, text: "Ich halte mich eher im Hintergrund."),
        Statement(trait: .agreeableness, keyed: -1, text: "Andere Menschen interessieren mich nicht wirklich."),
        Statement(trait: .conscientiousness, keyed: -1, text: "Ich bringe Dinge oft durcheinander."),
        Statement(trait: .calmness, keyed: 1, text: "Ich bin selten niedergeschlagen."),
        Statement(trait: .openness, keyed: -1, text: "Ich habe nicht viel Fantasie."),
    ]

    static let scale = ["Trifft gar nicht zu", "Trifft eher nicht zu", "Teils, teils", "Trifft eher zu", "Trifft voll zu"]

    /// Vorläufige Vergleichswerte (Mittelwert, Streuung) nach der Mini-IPIP-Originalstudie
    /// mit US-Studierenden. Vor dem Start durch deutsche Normwerte ersetzen.
    static let norms: [Trait: (mean: Double, sd: Double)] = [
        .extraversion: (2.96, 0.88),
        .agreeableness: (3.84, 0.70),
        .conscientiousness: (3.37, 0.80),
        .calmness: (3.43, 0.78),
        .openness: (3.64, 0.73),
    ]

    /// Durchschnitt der Antworten (1 bis 5) je Eigenschaft, umgepolte Aussagen eingerechnet.
    /// Unbeantwortete Aussagen (nil) werden übersprungen.
    static func means(answers: [Int?]) -> [Trait: Double] {
        var sum: [Trait: Double] = [:]
        var count: [Trait: Double] = [:]
        for (statement, answer) in zip(statements, answers) {
            guard let answer else { continue }
            let value = statement.keyed > 0 ? answer : 6 - answer
            sum[statement.trait, default: 0] += Double(value)
            count[statement.trait, default: 0] += 1
        }
        var result: [Trait: Double] = [:]
        for (trait, total) in sum {
            result[trait] = total / (count[trait] ?? 1)
        }
        return result
    }

    /// Prozentrang 1–99: Bei wie vielen von 100 Menschen ist die Eigenschaft schwächer ausgeprägt?
    static func percentile(mean: Double, for trait: Trait) -> Int {
        guard let norm = norms[trait] else { return 50 }
        let z = (mean - norm.mean) / norm.sd
        let cdf = 0.5 * erfc(-z / 2.0.squareRoot())
        return min(99, max(1, Int((cdf * 100).rounded())))
    }

    static func percentiles(means: [Trait: Double]) -> [Trait: Int] {
        var result: [Trait: Int] = [:]
        for (trait, mean) in means {
            result[trait] = percentile(mean: mean, for: trait)
        }
        return result
    }

    /// Die zwei Tiere, die am stärksten herausstechen
    static func topTwo(_ scores: [Trait: Int]) -> [Trait] {
        Array(Trait.displayOrder.sorted { (scores[$0] ?? 0) > (scores[$1] ?? 0) }.prefix(2))
    }

    /// Beispielprofil, solange noch kein eigenes Ergebnis da ist
    static let example: [Trait: Int] = [
        .conscientiousness: 38, .extraversion: 72, .openness: 81, .agreeableness: 64, .calmness: 45,
    ]

    /// Eine Vermutung, die ein Selbstversuch prüfen kann
    static func hypothesis(for scores: [Trait: Int]) -> String {
        if (scores[.extraversion] ?? 50) > 65 {
            return "Bei dir ist viel Erdmännchen. Vielleicht hilft dir Erklären mehr als stilles Lesen. Das prüft später der Selbstversuch „Erklären oder Lesen“."
        }
        if (scores[.conscientiousness] ?? 50) < 35 {
            return "Der Biber ist bei dir eher klein. Vermutlich helfen dir kurze, feste Lerneinheiten mehr als lange. Das prüft später der Selbstversuch „Am Stück oder verteilt“."
        }
        return "Egal welche Tiere vorne liegen: Ob Abfragen bei dir besser wirkt als Lesen, zeigt nur ein Versuch."
    }
}

struct PersonalityResult: Codable {
    var means: [Trait: Double]
    var date: Date

    var scores: [Trait: Int] { PersonalityTest.percentiles(means: means) }
}
