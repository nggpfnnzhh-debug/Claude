import SwiftUI

enum ShapeKind: String, CaseIterable {
    case circle, square, triangle, rectangle, star, heart, oval

    /// Für Einsteiger: gut unterscheidbare Formen.
    static let basic: [ShapeKind] = [.circle, .square, .triangle, .star, .heart]

    var name: String {
        switch self {
        case .circle: return "Kreis"
        case .square: return "Quadrat"
        case .triangle: return "Dreieck"
        case .rectangle: return "Rechteck"
        case .star: return "Stern"
        case .heart: return "Herz"
        case .oval: return "Oval"
        }
    }

    var article: String {
        switch self {
        case .circle, .star: return "der"
        default: return "das"
        }
    }
}

struct NamedColor: Hashable {
    let name: String
    let color: Color
}

enum ChoiceContent: Hashable {
    case number(Int)
    case color(Color, symbol: String)
    case shape(ShapeKind, Color)
    case emoji(String)
    /// Eine Gruppe gleicher Bilder (Mehr oder weniger?).
    case group(String, count: Int)
    /// Anzahl Klatscher (Silben klatschen).
    case claps(Int)
    /// Analoge Uhr (Uhr lesen).
    case clock(hour: Int, minute: Int)
}

struct Choice: Identifiable, Hashable {
    let id = UUID()
    let content: ChoiceContent
    let isCorrect: Bool
    /// Für VoiceOver.
    let spokenName: String
    /// Wird bei falscher Antwort vorgelesen – erklärend statt bestrafend.
    let wrongFeedback: String
}

enum Prompt: Hashable {
    case objects(emoji: String, count: Int)
    case letter(String)
    case sequence([String])
    /// Ein Bild, das beim Antippen in Silben vorgelesen wird.
    case word(emoji: String, syllables: String)
    case empty
}

struct QuizTask: Identifiable {
    let id = UUID()
    let prompt: Prompt
    let instruction: String
    let choices: [Choice]
    /// Wird nach dem Lob gesprochen (das Lob wählt die App je nach Verlauf).
    let correctFeedback: String
}
