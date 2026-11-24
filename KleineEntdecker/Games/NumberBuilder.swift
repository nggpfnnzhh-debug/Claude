import Foundation

/// „Zahlen bauen“: Huhu nennt eine Zahl, das Kind setzt sie aus Zehner- und Einerziffer zusammen.
/// Zehnerstangen zeigen dabei, was die Ziffern bedeuten (die 8 in der 80 = acht Zehner).
struct BuildTask: Identifiable {
    let id = UUID()
    let number: Int

    var tens: Int { number / 10 }
    var ones: Int { number % 10 }
}

enum NumberBuilder {
    /// Stufe 0: 10–20 (vom Zählen bekannt), Stufe 1: volle Zehner, Stufe 2: alle Zahlen bis 99.
    static let levelNumbers: [[Int]] = [
        Array(10...20),
        Array(stride(from: 10, through: 90, by: 10)),
        (21...99).filter { $0 % 10 != 0 },
    ]

    static func tasks(level: Int) -> [BuildTask] {
        let pool = levelNumbers[min(max(level, 0), levelNumbers.count - 1)]
        return pool.shuffled().prefix(TaskFactory.tasksPerRound).map { BuildTask(number: $0) }
    }

    // MARK: - Sprache

    /// Deutsches Zahlwort bis 99, kleingeschrieben – z. B. „vierundzwanzig“.
    static func word(_ number: Int) -> String {
        if number <= 20 { return Phrases.numberWords[number] }
        let tensWords = ["", "zehn", "zwanzig", "dreißig", "vierzig", "fünfzig", "sechzig", "siebzig", "achtzig", "neunzig"]
        let tens = number / 10, ones = number % 10
        if ones == 0 { return tensWords[tens] }
        let onesWord = ones == 1 ? "ein" : Phrases.numberWords[ones]
        return "\(onesWord)und\(tensWords[tens])"
    }

    static func instruction(for number: Int) -> String {
        "Bau die Zahl \(word(number))!"
    }

    static func solvedText(for number: Int) -> String {
        "\(word(number).capitalized)!"
    }

    static func tensText(_ tens: Int) -> String {
        tens == 1 ? "Ein Zehner!" : "\(Phrases.numberWords[tens].capitalized) Zehner!"
    }

    static func onesText(_ ones: Int) -> String {
        switch ones {
        case 0: return "Keine Einer!"
        case 1: return "Ein Einer!"
        default: return "\(Phrases.numberWords[ones].capitalized) Einer!"
        }
    }

    static let countTens = "Zähl die Zehnerstangen!"
    static let countOnes = "Zähl die einzelnen Punkte!"
    /// Typischer Zahlendreher: Bei „vierundzwanzig“ hört man die Vier zuerst, geschrieben wird aber die Zwei zuerst.
    static let tensFirst = "Zuerst kommen die Zehner!"

    /// Alle Sätze, die das Spiel sprechen kann (für Tests und Vertonung).
    static var allTexts: [String] {
        var texts = [countTens, countOnes, tensFirst]
        for number in levelNumbers.flatMap({ $0 }) {
            texts += [instruction(for: number), solvedText(for: number)]
        }
        texts += (1...9).map(tensText) + (0...9).map(onesText)
        return texts
    }
}
