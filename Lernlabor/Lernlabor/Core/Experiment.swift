import Foundation

/// Die Selbstversuche der App
enum ExperimentKind: String, Codable, CaseIterable, Identifiable {
    case rereadQuiz
    case explainRead

    struct Detail: Hashable {
        let icon: String
        let text: String
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rereadQuiz: return "Lesen oder Abfragen?"
        case .explainRead: return "Erklären oder Lesen?"
        }
    }

    var shortTitle: String {
        switch self {
        case .rereadQuiz: return "Lesen oder Abfragen"
        case .explainRead: return "Erklären oder Lesen"
        }
    }

    var number: Int {
        switch self {
        case .rereadQuiz: return 1
        case .explainRead: return 2
        }
    }

    var summary: String {
        switch self {
        case .rereadQuiz:
            return "Du lernst 16 Wörter auf Suaheli. Die Hälfte liest du ein zweites Mal, die andere Hälfte fragst du dich selbst ab. Später testen wir alle 16 und vergleichen."
        case .explainRead:
            return "Du liest 12 überraschende Fakten. Die Hälfte liest du ein zweites Mal, die andere Hälfte erklärst du laut in eigenen Worten. Später testen wir alle 12 mit Fragen."
        }
    }

    var details: [Detail] {
        switch self {
        case .rereadQuiz:
            return [Detail(icon: "clock", text: "etwa 10 Minuten, dazu ein kurzer Test später"),
                    Detail(icon: "globe.europe.africa", text: "Suaheli, damit niemand Vorwissen hat"),
                    Detail(icon: "dice", text: "Welches Wort in welche Gruppe kommt, entscheidet der Zufall")]
        case .explainRead:
            return [Detail(icon: "clock", text: "etwa 12 Minuten, dazu ein kurzer Test später"),
                    Detail(icon: "bubble.left", text: "Erklären geht auch leise murmelnd"),
                    Detail(icon: "dice", text: "Welcher Fakt in welche Gruppe kommt, entscheidet der Zufall. Kennst du einen schon, gleicht sich das aus")]
        }
    }

    /// Erste Methode ist immer die Vergleichsgruppe „Nochmal lesen“.
    var methods: [StudyMethod] {
        switch self {
        case .rereadQuiz: return [.reread, .quiz]
        case .explainRead: return [.reread, .explain]
        }
    }

    var isFree: Bool { self == .rereadQuiz }

    var items: [ExperimentItem] {
        switch self {
        case .rereadQuiz: return RereadVsQuiz.words.map(ExperimentItem.word)
        case .explainRead: return ExplainVsRead.facts.map(ExperimentItem.fact)
        }
    }

    var perMethod: Int { items.count / 2 }

    /// Mindestzeit pro Karte, damit beide Gruppen ähnlich lange gesehen werden
    var gateSeconds: Double {
        switch self {
        case .rereadQuiz: return 2.5
        case .explainRead: return 6
        }
    }
}

enum StudyMethod: String, Codable {
    case reread
    case quiz
    case explain

    var name: String {
        switch self {
        case .reread: return "Nochmal lesen"
        case .quiz: return "Abfragen"
        case .explain: return "Erklären"
        }
    }

    /// Antwort auf „Was bleibt besser hängen?“
    var choice: String {
        switch self {
        case .reread: return "Nochmal lesen"
        case .quiz: return "Mich selbst abfragen"
        case .explain: return "Laut erklären"
        }
    }

    /// Beschriftung im Ergebnis
    var resultLabel: String {
        switch self {
        case .reread: return "Nochmal gelesen"
        case .quiz: return "Abgefragt"
        case .explain: return "Erklärt"
        }
    }
}

struct WordPair: Hashable {
    let swahili: String
    let german: String
    var alternatives: [String] = []
}

struct Fact: Hashable {
    let id: String
    let text: String
    let question: String
    let answer: String
    let wrong: [String]
}

enum ExperimentItem: Hashable, Identifiable {
    case word(WordPair)
    case fact(Fact)

    var id: String {
        switch self {
        case .word(let pair): return pair.swahili
        case .fact(let fact): return fact.id
        }
    }

    var label: String {
        switch self {
        case .word(let pair): return "\(pair.swahili) = \(pair.german)"
        case .fact(let fact): return fact.answer + " (" + fact.question + ")"
        }
    }
}

struct ExperimentRun: Codable, Identifiable {
    var id = UUID()
    var kind: ExperimentKind
    /// Vermutung vor dem Versuch, nil = „kein Unterschied“
    var prediction: StudyMethod?
    /// Element-ID → Übungsmethode
    var assignment: [String: StudyMethod]
    var learnedAt: Date
    var testedAt: Date?
    /// Element-ID → im Test gewusst?
    var results: [String: Bool] = [:]

    var dueDate: Date { learnedAt.addingTimeInterval(Experiments.recommendedDelay) }

    /// Mit echter Pause getestet (nicht als Schnell-Demo)?
    var delayed: Bool {
        guard let testedAt else { return false }
        return testedAt.timeIntervalSince(learnedAt) >= Experiments.delayThreshold
    }

    func correct(_ method: StudyMethod) -> Int {
        results.filter { assignment[$0.key] == method && $0.value }.count
    }
}

enum Experiments {
    static let recommendedDelay: TimeInterval = 2 * 24 * 3600
    /// Ab dieser Pause zählt ein Test als „nach Pause“
    static let delayThreshold: TimeInterval = 20 * 3600

    /// Teilt die Elemente zufällig je zur Hälfte auf die beiden Methoden auf.
    static func randomAssignment(for kind: ExperimentKind) -> [String: StudyMethod] {
        var result: [String: StudyMethod] = [:]
        for (index, item) in kind.items.shuffled().enumerated() {
            result[item.id] = index < kind.perMethod ? kind.methods[0] : kind.methods[1]
        }
        return result
    }

    struct Verdict {
        let title: String
        let detail: String
        /// nil = kein klarer Unterschied
        let winner: StudyMethod?
    }

    /// Bewertet den Unterschied ehrlich: Erst ab 3 Treffern gilt er als deutlich.
    static func verdict(for run: ExperimentRun) -> Verdict {
        let baseline = run.kind.methods[0], other = run.kind.methods[1]
        let difference = run.correct(other) - run.correct(baseline)
        if abs(difference) >= 3 {
            let winner = difference > 0 ? other : baseline
            return Verdict(title: "\(winner.name) hat bei dir klar gewonnen.",
                           detail: winner == .reread
                               ? "Ungewöhnlich, aber möglich. Wiederhole den Versuch, um sicherzugehen."
                               : "Ein Unterschied von 3 oder mehr ist ein deutlicher Hinweis.",
                           winner: winner)
        }
        if difference == 0 {
            return Verdict(title: "Kein Unterschied.",
                           detail: "Bei so wenigen Aufgaben heißt das: Wiederholen lohnt sich, am besten mit Pause.",
                           winner: nil)
        }
        let leader = difference > 0 ? other : baseline
        return Verdict(title: "\(leader.name) liegt knapp vorne.",
                       detail: "1 oder 2 Treffer Unterschied können Zufall sein. Ein zweiter Durchgang macht das Ergebnis sicherer.",
                       winner: nil)
    }

    static func predictionText(_ prediction: StudyMethod?) -> String {
        prediction?.name ?? "Kein Unterschied"
    }

    static func predictionFeedback(prediction: StudyMethod?, winner: StudyMethod?) -> String {
        if prediction == winner { return "Das passt zum Ergebnis." }
        if winner == nil { return "Noch ist der Unterschied zu klein, um das zu bestätigen." }
        return "Das Ergebnis sieht anders aus. Unser Gefühl für gute Lernmethoden täuscht oft."
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
}

/// Selbstversuch 2: Laut erklären oder nochmal lesen?
enum ExplainVsRead {
    static let facts: [Fact] = [
        Fact(id: "oktopus",
             text: "Ein Oktopus hat drei Herzen: Zwei pumpen Blut durch die Kiemen, das dritte versorgt den restlichen Körper.",
             question: "Wie viele Herzen hat ein Oktopus?",
             answer: "Drei", wrong: ["Eins", "Zwei", "Vier"]),
        Fact(id: "honig",
             text: "Honig verdirbt praktisch nie, weil er sehr wenig Wasser enthält und leicht sauer ist. In altägyptischen Gräbern fand man noch essbaren Honig.",
             question: "Was fand man in altägyptischen Gräbern noch essbar?",
             answer: "Honig", wrong: ["Brot", "Käse", "Datteln"]),
        Fact(id: "eiffelturm",
             text: "Der Eiffelturm ist im Sommer bis zu etwa 15 Zentimeter höher, weil sich sein Eisen bei Wärme ausdehnt.",
             question: "Um wie viel wächst der Eiffelturm im Sommer ungefähr?",
             answer: "Bis zu 15 Zentimeter", wrong: ["Etwa 1 Millimeter", "Etwa 1 Meter", "Etwa 3 Meter"]),
        Fact(id: "banane",
             text: "Botanisch ist die Banane eine Beere, die Erdbeere dagegen nicht. Bei einer Beere stecken die Samen im Fruchtfleisch, die Erdbeere trägt ihre Nüsschen außen.",
             question: "Welche Frucht ist botanisch eine Beere?",
             answer: "Banane", wrong: ["Erdbeere", "Himbeere", "Brombeere"]),
        Fact(id: "wombat",
             text: "Wombats hinterlassen würfelförmigen Kot. Die Kanten entstehen im Darm, dessen Wand unterschiedlich dehnbar ist.",
             question: "Welches Tier hinterlässt würfelförmigen Kot?",
             answer: "Wombat", wrong: ["Koala", "Känguru", "Biber"]),
        Fact(id: "venus",
             text: "Eine Drehung um sich selbst dauert auf der Venus länger als ein ganzer Umlauf um die Sonne. Sie dreht sich extrem langsam.",
             question: "Auf welchem Planeten dauert eine Drehung um sich selbst länger als ein Jahr?",
             answer: "Venus", wrong: ["Mars", "Jupiter", "Saturn"]),
        Fact(id: "einhorn",
             text: "Das Nationaltier Schottlands ist das Einhorn. Es galt im Mittelalter als Symbol für Stärke und Unabhängigkeit.",
             question: "Welches Nationaltier hat Schottland?",
             answer: "Das Einhorn", wrong: ["Der Hirsch", "Der Adler", "Der Löwe"]),
        Fact(id: "blitz",
             text: "Ein Blitz ist rund 30.000 Grad heiß, etwa fünfmal heißer als die Oberfläche der Sonne. Deshalb dehnt sich die Luft explosionsartig aus, und wir hören Donner.",
             question: "Wie heiß ist ein Blitz im Vergleich zur Sonnenoberfläche?",
             answer: "Etwa fünfmal heißer", wrong: ["Etwa halb so heiß", "Etwa gleich heiß", "Etwa hundertmal heißer"]),
        Fact(id: "seeotter",
             text: "Seeotter halten sich beim Schlafen oft an den Pfoten fest, damit sie im Wasser nicht voneinander wegtreiben.",
             question: "Warum halten sich Seeotter beim Schlafen an den Pfoten?",
             answer: "Damit sie nicht wegtreiben", wrong: ["Um sich zu wärmen", "Um Feinde abzuschrecken", "Um Futter zu teilen"]),
        Fact(id: "krieg",
             text: "Der kürzeste Krieg der Geschichte dauerte weniger als eine Stunde: 1896 zwischen Großbritannien und Sansibar.",
             question: "Wie lange dauerte der kürzeste Krieg der Geschichte?",
             answer: "Weniger als eine Stunde", wrong: ["Einen Tag", "Eine Woche", "Einen Monat"]),
        Fact(id: "flamingo",
             text: "Flamingos sind rosa, weil sie Krebstierchen und Algen mit roten Farbstoffen fressen. Ohne diese Nahrung verblasst ihr Gefieder.",
             question: "Warum sind Flamingos rosa?",
             answer: "Wegen ihrer Nahrung", wrong: ["Wegen der Sonne", "Allein wegen ihrer Gene", "Wegen des Schlamms"]),
        Fact(id: "faultier",
             text: "Faultiere können unter Wasser bis zu 40 Minuten die Luft anhalten, weil sie ihren Herzschlag stark verlangsamen.",
             question: "Wie lange kann ein Faultier unter Wasser die Luft anhalten?",
             answer: "Bis zu 40 Minuten", wrong: ["Etwa 1 Minute", "Etwa 5 Minuten", "Etwa 3 Stunden"]),
    ]
}
