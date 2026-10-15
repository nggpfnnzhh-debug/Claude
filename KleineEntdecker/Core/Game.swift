import SwiftUI

enum Game: String, CaseIterable, Identifiable {
    case counting, colors, shapes, letters, patterns, memory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .counting: return "Zählen"
        case .colors: return "Farben"
        case .shapes: return "Formen"
        case .letters: return "Buchstaben"
        case .patterns: return "Muster"
        case .memory: return "Memory"
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
        }
    }

    /// Erklärung für Eltern, was das Spiel fördert.
    var parentInfo: String {
        switch self {
        case .counting:
            return "Mengen erfassen und Zahlen bis 5 (oder 10) zuordnen. Durch Antippen der Bilder zählt Ihr Kind laut mit – das übt die Eins-zu-eins-Zuordnung."
        case .colors:
            return "Grund- und Mischfarben benennen und wiedererkennen."
        case .shapes:
            return "Geometrische Grundformen unterscheiden – unabhängig von ihrer Farbe."
        case .letters:
            return "Anlaute hören und erste Buchstaben kennenlernen. Diese phonologische Bewusstheit ist eine wichtige Vorläuferfähigkeit für das Lesen."
        case .patterns:
            return "Regelmäßigkeiten erkennen und fortsetzen – eine Grundlage für mathematisches und logisches Denken."
        case .memory:
            return "Konzentration und visuelles Gedächtnis trainieren, Tiernamen festigen."
        }
    }
}
