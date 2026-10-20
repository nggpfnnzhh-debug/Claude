import SwiftUI

enum Game: String, CaseIterable, Identifiable {
    case counting, colors, shapes, letters, patterns, memory
    case moreLess, syllables, clock

    var id: String { rawValue }

    static var basics: [Game] { allCases.filter { !$0.isPreschool } }
    static var preschool: [Game] { allCases.filter(\.isPreschool) }

    /// Vorschulspiele (ca. 5–6 Jahre) stehen auf dem Startbildschirm in einem eigenen Bereich.
    var isPreschool: Bool {
        switch self {
        case .moreLess, .syllables, .clock: return true
        default: return false
        }
    }

    /// Höchste Schwierigkeitsstufe (0 = leicht). Die App passt die Stufe automatisch an.
    var maxLevel: Int { 2 }

    var title: String {
        switch self {
        case .counting: return "Zählen"
        case .colors: return "Farben"
        case .shapes: return "Formen"
        case .letters: return "Buchstaben"
        case .patterns: return "Muster"
        case .memory: return "Memory"
        case .moreLess: return "Mehr oder weniger?"
        case .syllables: return "Silben klatschen"
        case .clock: return "Uhr lesen"
        }
    }

    var icon: String {
        switch self {
        case .counting: return "🐞"
        case .colors: return "🎨"
        case .shapes: return "🔺"
        case .letters: return "🔤"
        case .patterns: return "🧩"
        case .memory: return "🃏"
        case .moreLess: return "⚖️"
        case .syllables: return "👏"
        case .clock: return "🕒"
        }
    }

    var tint: Color {
        switch self {
        case .counting: return Color(red: 0.96, green: 0.36, blue: 0.36)
        case .colors: return Color(red: 0.98, green: 0.62, blue: 0.20)
        case .shapes: return Color(red: 0.30, green: 0.69, blue: 0.40)
        case .letters: return Color(red: 0.25, green: 0.53, blue: 0.93)
        case .patterns: return Color(red: 0.58, green: 0.40, blue: 0.86)
        case .memory: return Color(red: 0.12, green: 0.70, blue: 0.75)
        case .moreLess: return Color(red: 0.90, green: 0.45, blue: 0.65)
        case .syllables: return Color(red: 0.95, green: 0.55, blue: 0.30)
        case .clock: return Color(red: 0.35, green: 0.45, blue: 0.80)
        }
    }

    /// Erklärung für Eltern, was das Spiel fördert.
    var parentInfo: String {
        switch self {
        case .counting:
            return "Mengen erfassen und Zahlen zuordnen – je nach Können bis 5, 10 oder 20. Durch Antippen der Bilder zählt Ihr Kind laut mit; das übt die Eins-zu-eins-Zuordnung."
        case .colors:
            return "Grund- und Mischfarben benennen und wiedererkennen."
        case .shapes:
            return "Geometrische Grundformen unterscheiden – unabhängig von ihrer Farbe."
        case .letters:
            return "Anlaute hören und erste Buchstaben kennenlernen. Die Buchstaben werden – wie in Kita und Schule – als Laut gesprochen („mmm“ statt „Em“)."
        case .patterns:
            return "Regelmäßigkeiten erkennen und fortsetzen – eine Grundlage für mathematisches und logisches Denken."
        case .memory:
            return "Konzentration und visuelles Gedächtnis trainieren, Tiernamen festigen."
        case .moreLess:
            return "Mengen vergleichen, ohne genau zählen zu müssen – ein wichtiger Schritt zum Zahlverständnis."
        case .syllables:
            return "Wörter in Silben zerlegen. Silbenklatschen ist eine bewährte Vorübung für das Lesen- und Schreibenlernen."
        case .clock:
            return "Die analoge Uhr kennenlernen: erst volle, dann halbe Stunden."
        }
    }

    /// Fördertipps: Ideen zum gemeinsamen Üben im Alltag – ganz ohne Bildschirm.
    var tips: [String] {
        switch self {
        case .counting:
            return [
                "Zählen Sie gemeinsam Treppenstufen, Knöpfe oder Löffel beim Tischdecken.",
                "Beim Zählen auf jeden Gegenstand zeigen oder ihn antippen – ein Gegenstand, eine Zahl.",
                "Würfelspiele wie „Mensch ärgere dich nicht“ üben Mengen ganz nebenbei.",
            ]
        case .colors:
            return [
                "Spielen Sie „Ich sehe was, was du nicht siehst, und das ist rot“.",
                "Sortieren Sie gemeinsam Wäsche, Bausteine oder Gummibärchen nach Farben.",
                "Hinweis: Etwa jeder zwölfte Junge hat eine Rot-Grün-Schwäche. Verwechselt Ihr Kind diese Farben dauerhaft, sprechen Sie das bei der nächsten Vorsorgeuntersuchung an.",
            ]
        case .shapes:
            return [
                "Formen im Alltag suchen: Das Fenster ist ein Rechteck, der Teller ein Kreis.",
                "Mit Knete oder Bauklötzen Formen nachbauen.",
                "Formen mit dem Finger in die Luft oder in den Sand malen.",
            ]
        case .letters:
            return [
                "Anlaut-Spiel beim Einkaufen: „Was fängt mit mmm an?“ – Milch, Möhre, Marmelade!",
                "Sprechen Sie Laute, nicht Buchstabennamen: „mmm“ statt „Em“.",
                "Den Anfangsbuchstaben des eigenen Namens suchen – auf Schildern, Packungen, Büchern.",
            ]
        case .patterns:
            return [
                "Perlen in einem Muster auffädeln: rot, blau, rot, blau …",
                "Klatsch-Muster: klatschen, stampfen, klatschen, stampfen – wer macht weiter?",
                "Beim Tischdecken abwechseln: Teller, Becher, Teller, Becher.",
            ]
        case .memory:
            return [
                "Tisch-Memory mit Alltagsgegenständen: Fünf Dinge zeigen, abdecken – was fehlt?",
                "Klassisches Karten-Memory mit wenigen Paaren beginnen.",
                "Beim Einkaufen: „Kannst du dir drei Sachen merken, die wir brauchen?“",
            ]
        case .moreLess:
            return [
                "Beim Teilen: Wer hat mehr Weintrauben? Erst schätzen, dann nachzählen.",
                "Zwei Häufchen Bausteine bauen und vergleichen: Wo sind weniger?",
                "Ins Wasserglas schauen: Wo ist mehr drin?",
            ]
        case .syllables:
            return [
                "Namen klatschen: Ma-ma, Pa-pa und der eigene Name.",
                "Beim Spazierengehen zu jeder Silbe einen Schritt machen: Ba-na-ne = drei Schritte.",
                "Silben-Roboter spielen: Wörter wie ein Roboter abgehackt sprechen.",
            ]
        case .clock:
            return [
                "Eine Spielzeuguhr oder eine echte Wanduhr gemeinsam anschauen und stellen.",
                "Feste Zeiten benennen: „Um sechs Uhr gibt es Abendessen.“",
                "Erst nur volle Stunden üben – halbe Stunden kommen später ganz von allein.",
            ]
        }
    }
}
