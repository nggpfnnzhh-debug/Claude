import SwiftUI

enum ShapeKind: String, CaseIterable {
    case circle, square, triangle, rectangle, star, heart, oval

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
    case empty
}

struct QuizTask: Identifiable {
    let id = UUID()
    let prompt: Prompt
    let instruction: String
    let choices: [Choice]
    let correctFeedback: String
}
