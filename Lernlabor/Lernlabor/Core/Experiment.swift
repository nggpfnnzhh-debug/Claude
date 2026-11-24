import Foundation

struct WordPair: Hashable {
    let swahili: String
    let german: String
    var alternatives: [String] = []
}

/// Wie ein Wort in Runde 2 geübt wird
enum Method: String, Codable {
    case reread
    case quiz
}

/// Vermutung vor dem Versuch und Gewinner danach
enum Prediction: String, Codable, CaseIterable {
    case reread
    case quiz
    case same

    var text: String {
        switch self {
        case .reread: return "Nochmal lesen"
        case .quiz: return "Abfragen"
        case .same: return "Kein Unterschied"
        }
    }
}

struct ExperimentRun: Codable, Identifiable {
    var id = UUID()
    var prediction: Prediction
    /// Suaheli-Wort → Übungsmethode
    var assignment: [String: Method]
    var learnedAt: Date
    var testedAt: Date?
    /// Suaheli-Wort → im Test gewusst?
    var results: [String: Bool] = [:]

    var dueDate: Date { learnedAt.addingTimeInterval(RereadVsQuiz.recommendedDelay) }

    /// Mit echter Pause getestet (nicht als Schnell-Demo)?
    var delayed: Bool {
        guard let testedAt else { return false }
        return testedAt.timeIntervalSince(learnedAt) >= RereadVsQuiz.delayThreshold
    }

    func correct(_ method: Method) -> Int {
        results.filter { assignment[$0.key] == method && $0.value }.count
    }
}

/// Selbstversuch 1: Nochmal lesen oder sich selbst abfragen?
enum RereadVsQuiz {
    static let words: [WordPair] = [
        WordPair(swahili: "maji", german: "Wasser"),
        WordPair(swahili: "kitabu", german: "Buch"),
        WordPair(swahili: "nyumba", german: "Haus"),
        WordPair(swahili: "chakula", german: "Essen", alternatives: ["Nahrung", "Speise"]),
        WordPair(swahili: "rafiki", german: "Freund", alternatives: ["Freundin"]),
        WordPair(swahili: "mti", german: "Baum"),
        WordPair(swahili: "jua", german: "Sonne"),
        WordPair(swahili: "mvua", german: "Regen"),
        WordPair(swahili: "samaki", german: "Fisch"),
        WordPair(swahili: "mbwa", german: "Hund"),
        WordPair(swahili: "paka", german: "Katze"),
        WordPair(swahili: "gari", german: "Auto", alternatives: ["Wagen"]),
        WordPair(swahili: "kalamu", german: "Stift", alternatives: ["Kugelschreiber", "Füller"]),
        WordPair(swahili: "mlima", german: "Berg"),
        WordPair(swahili: "mto", german: "Fluss"),
        WordPair(swahili: "nyota", german: "Stern"),
    ]

    static let perMethod = 8
    static let recommendedDelay: TimeInterval = 2 * 24 * 3600
    /// Ab dieser Pause zählt ein Test als „nach Pause“
    static let delayThreshold: TimeInterval = 20 * 3600

    /// Teilt die Wörter zufällig je zur Hälfte auf die beiden Methoden auf.
    static func randomAssignment() -> [String: Method] {
        var result: [String: Method] = [:]
        for (index, pair) in words.shuffled().enumerated() {
            result[pair.swahili] = index < perMethod ? .reread : .quiz
        }
        return result
    }

    /// Kleinschreibung, Umlaute ausgeschrieben, Artikel und Satzzeichen entfernt
    static func normalize(_ text: String) -> String {
        var value = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for (umlaut, replacement) in [("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")] {
            value = value.replacingOccurrences(of: umlaut, with: replacement)
        }
        for article in ["der ", "die ", "das ", "ein ", "eine ", "einen "] where value.hasPrefix(article) {
            value = String(value.dropFirst(article.count))
            break
        }
        return String(value.filter { $0.isLetter && $0.isASCII })
    }

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }

    /// Richtig ist auch eine Antwort mit einem kleinen Tippfehler (bei Wörtern ab 4 Buchstaben).
    static func isCorrect(_ answer: String, for pair: WordPair) -> Bool {
        let given = normalize(answer)
        guard !given.isEmpty else { return false }
        return ([pair.german] + pair.alternatives).contains { target in
            let expected = normalize(target)
            return given == expected || (expected.count >= 4 && levenshtein(given, expected) <= 1)
        }
    }

    struct Verdict {
        let title: String
        let detail: String
        let winner: Prediction
    }

    /// Bewertet den Unterschied ehrlich: Erst ab 3 Wörtern gilt er als deutlich.
    static func verdict(reread: Int, quiz: Int) -> Verdict {
        let difference = quiz - reread
        if abs(difference) >= 3 {
            return difference > 0
                ? Verdict(title: "Abfragen hat bei dir klar gewonnen.",
                          detail: "Ein Unterschied von 3 oder mehr Wörtern ist ein deutlicher Hinweis.",
                          winner: .quiz)
                : Verdict(title: "Nochmal lesen hat bei dir klar gewonnen.",
                          detail: "Ungewöhnlich, aber möglich. Wiederhole den Versuch, um sicherzugehen.",
                          winner: .reread)
        }
        if difference == 0 {
            return Verdict(title: "Kein Unterschied.",
                           detail: "Bei so wenigen Wörtern heißt das: Wiederholen lohnt sich, am besten mit Pause.",
                           winner: .same)
        }
        return Verdict(title: (difference > 0 ? "Abfragen" : "Nochmal lesen") + " liegt knapp vorne.",
                       detail: "1 oder 2 Wörter Unterschied können Zufall sein. Ein zweiter Durchgang macht das Ergebnis sicherer.",
                       winner: .same)
    }

    static func predictionFeedback(prediction: Prediction, winner: Prediction) -> String {
        if prediction == winner { return "Das passt zum Ergebnis." }
        if winner == .same { return "Noch ist der Unterschied zu klein, um das zu bestätigen." }
        return "Das Ergebnis sieht anders aus. Unser Gefühl für gute Lernmethoden täuscht oft."
    }
}
