import Foundation

/// Feste Sätze der App. Alle gesprochenen Sätze sind als Audioaufnahmen hinterlegt
/// (siehe `scripts/voice/generate.py`) – neue Sätze dort ebenfalls eintragen.
enum Lines {
    static let homeQuestion = "Was möchtest du spielen?"
    static let pickerQuestion = "Wer bist du? Such dir einen Namen aus!"
    static let celebrationPlain = "Super gemacht!"
    static let celebrationStar = "Du hast einen Stern bekommen!"
    static let memoryInstruction = "Finde die Paare! Tippe auf zwei Karten."
    static let memoryPair = "Ein Paar! Super!"
    static let breakTime = "Zeit für eine Pause! Du hast heute schon toll gespielt."
    static let voicePreview = "Hallo! Wie viele Äpfel siehst du? Toll gemacht!"

    static func hello(_ spokenName: String) -> String { "Hallo, \(spokenName)!" }
    static func celebration(_ spokenName: String) -> String { "Super gemacht, \(spokenName)!" }

    static let fixed = [
        homeQuestion, pickerQuestion, celebrationPlain, celebrationStar,
        memoryInstruction, memoryPair, breakTime, voicePreview,
    ]
}
