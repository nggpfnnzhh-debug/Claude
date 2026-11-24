import SwiftUI

/// Die fünf Big-Five-Eigenschaften. „Gelassenheit“ ist das Gegenteil von Neurotizismus
/// und wird bewusst positiv benannt.
enum Trait: String, CaseIterable, Codable, Identifiable {
    case conscientiousness = "C"
    case extraversion = "E"
    case openness = "O"
    case agreeableness = "A"
    case calmness = "N"

    var id: String { rawValue }

    /// Reihenfolge in Ergebnis und Profil
    static let displayOrder: [Trait] = [.conscientiousness, .extraversion, .openness, .agreeableness, .calmness]

    var animal: Animal {
        switch self {
        case .conscientiousness:
            return Animal(
                name: "Biber", symbol: .emoji("🦫"), color: Theme.beaver,
                traitName: "Gewissenhaftigkeit", short: "plant und bleibt dran",
                high: "Du hältst Pläne gut ein. Plane die Wiederholungen gleich mit ein, zum Beispiel nach 1, 3 und 7 Tagen.",
                mid: "Mit etwas Struktur bleibst du gut dran. Feste Lernzeiten im Kalender helfen dir.",
                low: "Du bist spontan und flexibel. Damit Lernen trotzdem klappt: 10 Minuten zu einer festen Uhrzeit, mit Erinnerung. Kleine Ziele schlagen große Vorsätze.")
        case .extraversion:
            return Animal(
                name: "Erdmännchen", symbol: .meerkat, color: Theme.meerkat,
                traitName: "Geselligkeit", short: "blüht in der Gruppe auf",
                high: "Erklär den Stoff anderen oder lern zu zweit und fragt euch gegenseitig ab.",
                mid: "Du lernst allein und mit anderen gut. Probier aus, ob Erklären dir zusätzlich hilft.",
                low: "Du kannst dich gut allein konzentrieren. Erklär den Stoff laut für dich oder schreib ihn auf, als würdest du ihn jemandem beibringen.")
        case .openness:
            return Animal(
                name: "Krake", symbol: .emoji("🐙"), color: Theme.octopus,
                traitName: "Offenheit", short: "will alles erkunden",
                high: "Du lernst gern über Zusammenhänge. Frag bei jedem Thema „Warum?“ und verknüpfe Neues mit dem, was du schon weißt. Vorsicht: Neugier springt gern weiter. Erst abfragen, dann zum nächsten Thema.",
                mid: "Du magst Neues, brauchst aber auch Bekanntes. Wechsle zwischen Grundlagen und spannenden Hintergründen.",
                low: "Du bist praktisch veranlagt. Starte mit konkreten Beispielen und Anwendungen, die Theorie kommt danach.")
        case .agreeableness:
            return Animal(
                name: "Elefant", symbol: .emoji("🐘"), color: Theme.elephant,
                traitName: "Verträglichkeit", short: "fühlt mit anderen mit",
                high: "Ein Lernpartner, der auf dich zählt, hält dich bei der Stange. In Gruppen: Frag nach, auch wenn es sich unangenehm anfühlt.",
                mid: "Du arbeitest gern mit anderen, kannst aber auch kritisch sein. Beides hilft in einer Lerngruppe.",
                low: "Du sagst offen, was du denkst, und magst Herausforderungen. Setz dir Bestwerte und miss dich an deinem früheren Ich.")
        case .calmness:
            return Animal(
                name: "Schildkröte", symbol: .emoji("🐢"), color: Theme.turtle,
                traitName: "Gelassenheit", short: "bleibt ruhig und kommt ans Ziel",
                high: "Wie in der Fabel vom Hasen und der Schildkröte: Du bleibst ruhig und kommst stetig voran. Prüf dich trotzdem echt ab, denn wer gelassen ist, überschätzt leicht, wie viel schon sitzt.",
                mid: "Normaler Druck stört dich kaum. Vor Prüfungen helfen Probe-Abfragen, damit nichts überrascht.",
                low: "Du nimmst Dinge ernst und spürst Druck deutlich. Übe mit Probe-Abfragen ohne Bewertung, denn Abfragen hilft nachweislich auch unter Stress. Und mach deinen Fortschritt sichtbar.")
        }
    }
}

struct Animal {
    enum Symbol {
        case emoji(String)
        /// Für das Erdmännchen gibt es kein Emoji, es wird gezeichnet.
        case meerkat
    }

    let name: String
    let symbol: Symbol
    let color: Color
    let traitName: String
    let short: String
    let high: String
    let mid: String
    let low: String

    func tip(for level: Level) -> String {
        switch level {
        case .low: return low
        case .mid: return mid
        case .high: return high
        }
    }
}

/// Einordnung eines Prozentrangs
enum Level {
    case low, mid, high

    init(score: Int) {
        if score < 35 {
            self = .low
        } else if score > 65 {
            self = .high
        } else {
            self = .mid
        }
    }

    var text: String {
        switch self {
        case .low: return "eher wenig"
        case .mid: return "mittel"
        case .high: return "eher viel"
        }
    }
}
