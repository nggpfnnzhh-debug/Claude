import SwiftUI

/// Erzeugt die Aufgaben für eine Runde. Jede Runde hat `tasksPerRound` Aufgaben.
enum TaskFactory {
    static let tasksPerRound = 5

    static func tasks(for game: Game, countingUpTo countingMax: Int) -> [QuizTask] {
        switch game {
        case .counting: return countingTasks(upTo: countingMax)
        case .colors: return colorTasks()
        case .shapes: return shapeTasks()
        case .letters: return letterTasks()
        case .patterns: return patternTasks()
        case .memory: return []
        }
    }

    // MARK: - Zählen

    struct CountItem {
        let emoji: String
        let plural: String
    }

    static let countItems: [CountItem] = [
        CountItem(emoji: "🐞", plural: "Marienkäfer"),
        CountItem(emoji: "🐟", plural: "Fische"),
        CountItem(emoji: "🐥", plural: "Küken"),
        CountItem(emoji: "🍎", plural: "Äpfel"),
        CountItem(emoji: "⭐️", plural: "Sterne"),
        CountItem(emoji: "🐸", plural: "Frösche"),
        CountItem(emoji: "🦋", plural: "Schmetterlinge"),
        CountItem(emoji: "🚗", plural: "Autos"),
        CountItem(emoji: "🌸", plural: "Blumen"),
        CountItem(emoji: "🐶", plural: "Hunde"),
    ]

    static func countingTasks(upTo countingMax: Int) -> [QuizTask] {
        let upper = min(max(countingMax, tasksPerRound), 10)
        let numbers = Array(1...upper).shuffled()
        let items = countItems.shuffled()

        return (0..<tasksPerRound).map { i in
            let n = numbers[i % numbers.count]
            let item = items[i % items.count]
            var options: Set<Int> = [n]
            while options.count < 3 {
                options.insert(Int.random(in: 1...upper))
            }
            let choices = options.shuffled().map { value in
                Choice(
                    content: .number(value),
                    isCorrect: value == n,
                    spokenName: "\(value)",
                    wrongFeedback: "Zähl noch einmal mit mir. Tippe auf jedes Bild!"
                )
            }
            return QuizTask(
                prompt: .objects(emoji: item.emoji, count: n),
                instruction: "Wie viele \(item.plural) siehst du?",
                choices: choices,
                correctFeedback: "\(Phrases.randomPraise) \(Phrases.numberWords[n].capitalized)!"
            )
        }
    }

    // MARK: - Farben

    static let palette: [NamedColor] = [
        NamedColor(name: "Rot", color: .red),
        NamedColor(name: "Blau", color: .blue),
        NamedColor(name: "Gelb", color: .yellow),
        NamedColor(name: "Grün", color: .green),
        NamedColor(name: "Orange", color: .orange),
        NamedColor(name: "Lila", color: .purple),
        NamedColor(name: "Rosa", color: .pink),
        NamedColor(name: "Braun", color: .brown),
    ]

    static let colorSymbols = ["circle.fill", "star.fill", "heart.fill", "car.fill", "drop.fill", "leaf.fill", "cloud.fill"]

    static func colorTasks() -> [QuizTask] {
        palette.shuffled().prefix(tasksPerRound).map { target in
            let others = palette.filter { $0 != target }.shuffled().prefix(3)
            let symbol = colorSymbols.randomElement() ?? "circle.fill"
            let choices = ([target] + others).shuffled().map { option in
                Choice(
                    content: .color(option.color, symbol: symbol),
                    isCorrect: option == target,
                    spokenName: option.name,
                    wrongFeedback: "Das ist \(option.name). Wo ist \(target.name)?"
                )
            }
            return QuizTask(
                prompt: .empty,
                instruction: "Tippe auf \(target.name)!",
                choices: choices,
                correctFeedback: "\(Phrases.randomPraise) Das ist \(target.name)."
            )
        }
    }

    // MARK: - Formen

    static func shapeTasks() -> [QuizTask] {
        ShapeKind.allCases.shuffled().prefix(tasksPerRound).map { target in
            let others = ShapeKind.allCases.filter { $0 != target }.shuffled().prefix(2)
            // Jede Form in einer anderen Farbe: Das Kind soll die Form, nicht die Farbe erkennen.
            let colors = palette.shuffled()
            let choices = ([target] + others).shuffled().enumerated().map { index, kind in
                Choice(
                    content: .shape(kind, colors[index % colors.count].color),
                    isCorrect: kind == target,
                    spokenName: kind.name,
                    wrongFeedback: "Das ist ein \(kind.name). Wo ist \(target.article) \(target.name)?"
                )
            }
            return QuizTask(
                prompt: .empty,
                instruction: "Wo ist \(target.article) \(target.name)?",
                choices: choices,
                correctFeedback: "\(Phrases.randomPraise) Das ist \(target.article) \(target.name)."
            )
        }
    }

    // MARK: - Buchstaben (Anlaute)

    struct LetterWord {
        let letter: String
        let word: String
        let emoji: String
    }

    /// Nur Wörter mit klar hörbarem Anlaut (keine "Sch"-, "Ei"- oder "Ch"-Wörter).
    static let letterWords: [LetterWord] = [
        LetterWord(letter: "A", word: "Affe", emoji: "🐒"),
        LetterWord(letter: "A", word: "Apfel", emoji: "🍎"),
        LetterWord(letter: "A", word: "Ananas", emoji: "🍍"),
        LetterWord(letter: "B", word: "Banane", emoji: "🍌"),
        LetterWord(letter: "B", word: "Bär", emoji: "🐻"),
        LetterWord(letter: "B", word: "Baum", emoji: "🌳"),
        LetterWord(letter: "E", word: "Ente", emoji: "🦆"),
        LetterWord(letter: "E", word: "Elefant", emoji: "🐘"),
        LetterWord(letter: "E", word: "Erdbeere", emoji: "🍓"),
        LetterWord(letter: "F", word: "Fisch", emoji: "🐟"),
        LetterWord(letter: "F", word: "Frosch", emoji: "🐸"),
        LetterWord(letter: "F", word: "Feuer", emoji: "🔥"),
        LetterWord(letter: "H", word: "Hund", emoji: "🐶"),
        LetterWord(letter: "H", word: "Haus", emoji: "🏠"),
        LetterWord(letter: "H", word: "Herz", emoji: "❤️"),
        LetterWord(letter: "K", word: "Katze", emoji: "🐱"),
        LetterWord(letter: "K", word: "Käse", emoji: "🧀"),
        LetterWord(letter: "K", word: "Kuh", emoji: "🐮"),
        LetterWord(letter: "L", word: "Löwe", emoji: "🦁"),
        LetterWord(letter: "L", word: "Löffel", emoji: "🥄"),
        LetterWord(letter: "M", word: "Maus", emoji: "🐭"),
        LetterWord(letter: "M", word: "Mond", emoji: "🌙"),
        LetterWord(letter: "M", word: "Milch", emoji: "🥛"),
        LetterWord(letter: "N", word: "Nase", emoji: "👃"),
        LetterWord(letter: "N", word: "Nashorn", emoji: "🦏"),
        LetterWord(letter: "O", word: "Ohr", emoji: "👂"),
        LetterWord(letter: "O", word: "Oktopus", emoji: "🐙"),
        LetterWord(letter: "P", word: "Pferd", emoji: "🐴"),
        LetterWord(letter: "P", word: "Pinguin", emoji: "🐧"),
        LetterWord(letter: "P", word: "Pilz", emoji: "🍄"),
        LetterWord(letter: "R", word: "Rakete", emoji: "🚀"),
        LetterWord(letter: "R", word: "Regenbogen", emoji: "🌈"),
        LetterWord(letter: "R", word: "Roboter", emoji: "🤖"),
        LetterWord(letter: "S", word: "Sonne", emoji: "☀️"),
        LetterWord(letter: "S", word: "Socke", emoji: "🧦"),
        LetterWord(letter: "T", word: "Tiger", emoji: "🐯"),
        LetterWord(letter: "T", word: "Tomate", emoji: "🍅"),
        LetterWord(letter: "T", word: "Teddy", emoji: "🧸"),
        LetterWord(letter: "U", word: "Uhr", emoji: "⏰"),
        LetterWord(letter: "U", word: "Ufo", emoji: "🛸"),
        LetterWord(letter: "Z", word: "Zebra", emoji: "🦓"),
        LetterWord(letter: "Z", word: "Zug", emoji: "🚂"),
        LetterWord(letter: "Z", word: "Zitrone", emoji: "🍋"),
    ]

    static func letterTasks() -> [QuizTask] {
        let letters = Array(Set(letterWords.map(\.letter))).shuffled().prefix(tasksPerRound)
        return letters.map { letter in
            let candidates = letterWords.filter { $0.letter == letter }
            let correct = candidates.randomElement() ?? candidates[0]

            var usedLetters: Set<String> = [letter]
            var distractors: [LetterWord] = []
            for word in letterWords.shuffled() where !usedLetters.contains(word.letter) {
                distractors.append(word)
                usedLetters.insert(word.letter)
                if distractors.count == 2 { break }
            }

            let choices = ([correct] + distractors).shuffled().map { word in
                Choice(
                    content: .emoji(word.emoji),
                    isCorrect: word.letter == letter,
                    spokenName: word.word,
                    wrongFeedback: "\(word.word) fängt mit \(word.letter) an. Wir suchen \(letter)."
                )
            }
            return QuizTask(
                prompt: .letter(letter),
                instruction: "Was fängt mit \(letter) an?",
                choices: choices,
                correctFeedback: "\(Phrases.randomPraise) \(correct.word) fängt mit \(letter) an!"
            )
        }
    }

    // MARK: - Muster

    static let patternThemes: [[String]] = [
        ["🍎", "🍌", "🍇", "🍓"],
        ["🐶", "🐱", "🐭", "🐰"],
        ["🔴", "🔵", "🟢", "🟡"],
        ["⭐️", "🌙", "☀️", "☁️"],
        ["🚗", "🚂", "✈️", "🚲"],
    ]

    /// Steigende Schwierigkeit: AB, AB, AAB, ABB, ABC.
    static let patternUnits: [[Int]] = [[0, 1], [0, 1], [0, 0, 1], [0, 1, 1], [0, 1, 2]]

    static func patternTasks() -> [QuizTask] {
        (0..<tasksPerRound).map { i in
            let theme = (patternThemes.randomElement() ?? patternThemes[0]).shuffled()
            let unit = patternUnits[i % patternUnits.count]
            let shownLength = unit.count == 2 ? 5 : 6
            let sequence = (0...shownLength).map { theme[unit[$0 % unit.count]] }
            let shown = Array(sequence.prefix(shownLength))
            let answer = sequence[shownLength]

            // Antwortmöglichkeiten: alle Elemente des Musters plus ggf. ein fremdes Element.
            var options: [String] = []
            for index in unit where !options.contains(theme[index]) {
                options.append(theme[index])
            }
            if options.count < 3 {
                options.append(theme[3])
            }

            let choices = options.shuffled().map { emoji in
                Choice(
                    content: .emoji(emoji),
                    isCorrect: emoji == answer,
                    spokenName: emoji,
                    wrongFeedback: "Schau genau hin. Was wiederholt sich?"
                )
            }
            return QuizTask(
                prompt: .sequence(shown),
                instruction: "Was kommt als Nächstes?",
                choices: choices,
                correctFeedback: "\(Phrases.randomPraise) Das Muster geht weiter!"
            )
        }
    }
}
