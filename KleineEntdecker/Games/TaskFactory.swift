import SwiftUI

/// Erzeugt die Aufgaben für eine Runde. Jede Runde hat `tasksPerRound` Aufgaben.
/// `level` (0 = leicht … 2 = schwer) wird vom `ProgressStore` automatisch angepasst.
///
/// Alle gesprochenen Sätze sind als Aufnahmen hinterlegt – Änderungen an Texten oder
/// Daten hier auch in `scripts/voice/generate.py` nachziehen (VoiceCoverageTests prüft das).
enum TaskFactory {
    static let tasksPerRound = 5

    static func tasks(for game: Game, level: Int) -> [QuizTask] {
        let level = min(max(level, 0), game.maxLevel)
        switch game {
        case .counting: return countingTasks(level: level)
        case .colors: return colorTasks(level: level)
        case .shapes: return shapeTasks(level: level)
        case .letters: return letterTasks(level: level)
        case .patterns: return patternTasks(level: level)
        case .moreLess: return moreLessTasks(level: level)
        case .syllables: return syllableTasks(level: level)
        case .rhymes: return rhymeTasks(level: level)
        case .clock: return clockTasks(level: level)
        case .missingNumber: return missingNumberTasks(level: level)
        case .positions: return positionTasks(level: level)
        case .memory, .buildNumbers, .story: return []
        }
    }

    /// Wählt `count` Elemente, wiederholt bei kleinem Vorrat, aber nie zweimal direkt hintereinander.
    static func varied<T: Equatable>(_ pool: [T], count: Int) -> [T] {
        var result: [T] = []
        while result.count < count {
            for item in pool.shuffled() where result.count < count && result.last != item {
                result.append(item)
            }
        }
        return result
    }

    // MARK: - Zählen

    struct CountItem: Equatable {
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

    /// Grundmotive plus – je nach Jahreszeit oder Fest – passende Motive, die doppelt im Topf liegen,
    /// damit sie spürbar oft vorkommen.
    static var currentCountItems: [CountItem] {
        let seasonal = Seasonal.active?.countItems ?? []
        return countItems + seasonal + seasonal
    }

    static let countingLimits = [5, 10, 20]

    static func countingTasks(level: Int) -> [QuizTask] {
        let upper = countingLimits[level]
        let numbers = Array(Array(1...upper).shuffled().prefix(tasksPerRound))
        let items = varied(currentCountItems, count: tasksPerRound)

        return zip(numbers, items).map { n, item in
            // Ab Stufe 1 liegen die falschen Antworten nah an der richtigen – so lohnt sich genaues Zählen.
            let range = level == 0 ? 1...upper : max(1, n - 3)...min(upper, n + 3)
            var options: Set<Int> = [n]
            while options.count < 3 {
                options.insert(Int.random(in: range))
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
                correctFeedback: "\(Phrases.numberWords[n].capitalized)!"
            )
        }
    }

    // MARK: - Farben

    /// Eindeutige, kindgerechte Farbtöne. Bewusst keine Systemfarben: `.pink` ist z. B. kaum von Rot zu unterscheiden.
    static let palette: [NamedColor] = [
        NamedColor(name: "Rot", color: rgb(229, 57, 53)),
        NamedColor(name: "Blau", color: rgb(30, 102, 245)),
        NamedColor(name: "Gelb", color: rgb(255, 221, 0)),
        NamedColor(name: "Grün", color: rgb(46, 158, 68)),
        NamedColor(name: "Orange", color: rgb(255, 140, 0)),
        NamedColor(name: "Lila", color: rgb(142, 68, 173)),
        NamedColor(name: "Rosa", color: rgb(255, 158, 199)),
        NamedColor(name: "Braun", color: rgb(139, 90, 43)),
    ]

    static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(.sRGB, red: red / 255, green: green / 255, blue: blue / 255, opacity: 1)
    }

    static let colorSymbols = ["circle.fill", "star.fill", "heart.fill", "car.fill", "drop.fill", "leaf.fill", "cloud.fill"]

    static func colorTasks(level: Int) -> [QuizTask] {
        // Stufe 0: nur die vier Grundfarben, 3 Antworten; Stufe 2: alle Farben, 4 Antworten.
        let pool = level == 0 ? Array(palette.prefix(4)) : palette
        let optionCount = level == 2 ? 4 : 3
        return varied(pool, count: tasksPerRound).map { target in
            let others = pool.filter { $0 != target }.shuffled().prefix(optionCount - 1)
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
                correctFeedback: "Das ist \(target.name)."
            )
        }
    }

    // MARK: - Formen

    static func shapeTasks(level: Int) -> [QuizTask] {
        let pool = level == 0 ? ShapeKind.basic : ShapeKind.allCases
        let optionCount = level == 2 ? 4 : 3
        return varied(pool, count: tasksPerRound).map { target in
            let others = pool.filter { $0 != target }.shuffled().prefix(optionCount - 1)
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
                correctFeedback: "Das ist \(target.article) \(target.name)."
            )
        }
    }

    // MARK: - Buchstaben (Anlaute)

    struct LetterWord {
        let letter: String
        let word: String
        let emoji: String
    }

    /// Nur Wörter mit klar hörbarem Einzel-Anlaut (keine „Sch“-, „Ei“-, „Pf“- oder „Ch“-Wörter).
    /// Die Buchstaben werden in den Aufnahmen als Laut gesprochen („mmm“ statt „Em“).
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
        LetterWord(letter: "P", word: "Pizza", emoji: "🍕"),
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

    /// Ankerwort je Laut – wie in der Anlauttabelle von Kita und Grundschule.
    /// Der Laut wird im Muster „M, M, Mama“ gesprochen: einzeln ist er für Sprachsynthese zu undeutlich.
    /// Ankerwörter kommen nie als Antwortbild vor, damit sie die Lösung nicht verraten.
    static let anchorWords: [String: String] = [
        "A": "Ameise", "B": "Ball", "E": "Esel", "F": "Fuß", "H": "Hut", "K": "Kind", "L": "Lampe", "M": "Mama",
        "N": "Nudel", "O": "Opa", "P": "Papa", "R": "Rose", "S": "Sofa", "T": "Tasse", "U": "Uhu", "Z": "Zahn",
    ]

    /// „M, M, Maus“ – Laut zweimal, dann das Wort.
    static func soundPattern(_ letter: String, _ word: String) -> String {
        "\(letter), \(letter), \(word)"
    }

    static func letterTasks(level: Int) -> [QuizTask] {
        let distractorCount = level == 2 ? 3 : 2
        let letters = Array(Set(letterWords.map(\.letter))).shuffled().prefix(tasksPerRound)
        return letters.map { letter in
            let candidates = letterWords.filter { $0.letter == letter }
            let correct = candidates.randomElement() ?? candidates[0]

            var usedLetters: Set<String> = [letter]
            var distractors: [LetterWord] = []
            for word in letterWords.shuffled() where !usedLetters.contains(word.letter) {
                distractors.append(word)
                usedLetters.insert(word.letter)
                if distractors.count == distractorCount { break }
            }

            let anchorSound = soundPattern(letter, anchorWords[letter] ?? correct.word)
            let choices = ([correct] + distractors).shuffled().map { word in
                Choice(
                    content: .emoji(word.emoji),
                    isCorrect: word.letter == letter,
                    spokenName: word.word,
                    wrongFeedback: "\(soundPattern(word.letter, word.word)). Wir suchen: \(anchorSound)."
                )
            }
            return QuizTask(
                prompt: .letter(letter, sound: "Hör mal: \(anchorSound)."),
                instruction: "Hör mal: \(anchorSound). Was fängt auch so an?",
                choices: choices,
                correctFeedback: "\(soundPattern(letter, correct.word))!"
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

    /// Je Stufe steigende Schwierigkeit: AB → AAB/ABB → ABC/AABB.
    static let patternUnits: [[[Int]]] = [
        [[0, 1], [0, 1], [0, 1], [0, 0, 1], [0, 0, 1]],
        [[0, 1], [0, 1], [0, 0, 1], [0, 1, 1], [0, 1, 2]],
        [[0, 1], [0, 0, 1], [0, 1, 1], [0, 1, 2], [0, 0, 1, 1]],
    ]

    static func patternTasks(level: Int) -> [QuizTask] {
        patternUnits[level].map { unit in
            let theme = (patternThemes.randomElement() ?? patternThemes[0]).shuffled()
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
                correctFeedback: "Das Muster geht weiter!"
            )
        }
    }

    // MARK: - Mehr oder weniger? (Vorschule)

    /// Stufe 0: Mengen bis 10 mit kleinem Unterschied – hier muss man zählen statt schätzen.
    /// Stufe 1: Täuschbilder (die kleinere Menge ist breiter verteilt) und „gleich viele“.
    /// Stufe 2: Zahlen ohne Bilder vergleichen (bis 20), dazu weiter Täuschbilder.
    static let moreLessRange = 2...10
    static let sameAmount = "Das sind gleich viele!"
    static let notSameAmount = "Das sind nicht gleich viele."
    static let biggerNumberQuestion = "Welche Zahl ist größer?"
    static let smallerNumberQuestion = "Welche Zahl ist kleiner?"
    static let biggerNumberAnswer = "Das ist die größere Zahl."
    static let smallerNumberAnswer = "Das ist die kleinere Zahl."
    static let biggerNumberHint = "Die größere Zahl kommt beim Zählen später."
    static let smallerNumberHint = "Die kleinere Zahl kommt beim Zählen früher."

    static func moreLessTasks(level: Int) -> [QuizTask] {
        varied(currentCountItems, count: tasksPerRound).enumerated().map { index, item in
            switch level {
            case 0: return groupComparison(item: item, tricky: false, allowSame: false)
            case 1: return groupComparison(item: item, tricky: true, allowSame: index % 3 == 2)
            // Abwechselnd Ziffern und Täuschbilder, damit die Mengen nicht vergessen werden.
            default: return index.isMultiple(of: 2) ? numberComparison() : groupComparison(item: item, tricky: true, allowSame: false)
            }
        }
    }

    private static func groupComparison(item: CountItem, tricky: Bool, allowSame: Bool) -> QuizTask {
        var a = 0, b = 0
        if allowSame {
            a = Int.random(in: 4...8)
            b = a
        } else {
            repeat {
                a = Int.random(in: moreLessRange)
                b = Int.random(in: moreLessRange)
            } while a == b || abs(a - b) > 2
        }
        let askMore = Bool.random()
        let target = askMore ? max(a, b) : min(a, b)
        let same = a == b
        // Täuschbild: Die kleinere Menge wird groß und weit verteilt gezeigt – sieht nach „mehr“ aus.
        let smaller = min(a, b)
        let groups = [a, b].enumerated().map { offset, count in
            (count: count, spread: tricky && !same && count == smaller, id: offset)
        }

        var choices = groups.map { group in
            Choice(
                content: .group(item.emoji, count: group.count, spread: group.spread, variant: group.id),
                isCorrect: !same && group.count == target,
                spokenName: "\(group.count) \(item.plural)",
                wrongFeedback: "Zähl mal nach! Hier sind es \(Phrases.numberWords[group.count])."
            )
        }
        if tricky {
            choices.append(Choice(
                content: .same,
                isCorrect: same,
                spokenName: "Gleich viele",
                wrongFeedback: "Zähl mal nach! \(notSameAmount)"
            ))
        }
        let correctFeedback = same
            ? "Hier sind es \(Phrases.numberWords[a]). \(sameAmount)"
            : "Hier sind es \(Phrases.numberWords[target]). \(askMore ? "Das sind mehr!" : "Das sind weniger!")"
        return QuizTask(
            prompt: .empty,
            instruction: "Wo sind \(askMore ? "mehr" : "weniger") \(item.plural)?",
            choices: choices,
            correctFeedback: correctFeedback
        )
    }

    private static func numberComparison() -> QuizTask {
        var a = 0, b = 0
        repeat {
            a = Int.random(in: 1...20)
            b = Int.random(in: 1...20)
        } while a == b
        let askBigger = Bool.random()
        let target = askBigger ? max(a, b) : min(a, b)
        let choices = [a, b].map { value in
            Choice(
                content: .number(value),
                isCorrect: value == target,
                spokenName: "\(value)",
                wrongFeedback: askBigger ? biggerNumberHint : smallerNumberHint
            )
        }
        return QuizTask(
            prompt: .empty,
            instruction: askBigger ? biggerNumberQuestion : smallerNumberQuestion,
            choices: choices,
            correctFeedback: "\(Phrases.numberWords[target].capitalized)! \(askBigger ? biggerNumberAnswer : smallerNumberAnswer)"
        )
    }

    // MARK: - Silben klatschen (Vorschule)

    struct SyllableWord: Equatable {
        let word: String
        let emoji: String
        let syllables: [String]

        /// So wird das Wort in Silben vorgelesen, z. B. „Ba-na-ne.“
        var spokenSyllables: String { syllables.joined(separator: "-") + "." }
    }

    static let syllableWords: [SyllableWord] = [
        SyllableWord(word: "Hund", emoji: "🐶", syllables: ["Hund"]),
        SyllableWord(word: "Baum", emoji: "🌳", syllables: ["Baum"]),
        SyllableWord(word: "Haus", emoji: "🏠", syllables: ["Haus"]),
        SyllableWord(word: "Mond", emoji: "🌙", syllables: ["Mond"]),
        SyllableWord(word: "Fisch", emoji: "🐟", syllables: ["Fisch"]),
        SyllableWord(word: "Kuh", emoji: "🐮", syllables: ["Kuh"]),
        SyllableWord(word: "Ball", emoji: "⚽️", syllables: ["Ball"]),
        SyllableWord(word: "Ente", emoji: "🦆", syllables: ["En", "te"]),
        SyllableWord(word: "Katze", emoji: "🐱", syllables: ["Kat", "ze"]),
        SyllableWord(word: "Sonne", emoji: "☀️", syllables: ["Son", "ne"]),
        SyllableWord(word: "Apfel", emoji: "🍎", syllables: ["Ap", "fel"]),
        SyllableWord(word: "Tiger", emoji: "🐯", syllables: ["Ti", "ger"]),
        SyllableWord(word: "Zebra", emoji: "🦓", syllables: ["Ze", "bra"]),
        SyllableWord(word: "Auto", emoji: "🚗", syllables: ["Au", "to"]),
        SyllableWord(word: "Banane", emoji: "🍌", syllables: ["Ba", "na", "ne"]),
        SyllableWord(word: "Tomate", emoji: "🍅", syllables: ["To", "ma", "te"]),
        SyllableWord(word: "Rakete", emoji: "🚀", syllables: ["Ra", "ke", "te"]),
        SyllableWord(word: "Giraffe", emoji: "🦒", syllables: ["Gi", "raf", "fe"]),
        SyllableWord(word: "Elefant", emoji: "🐘", syllables: ["E", "le", "fant"]),
        SyllableWord(word: "Ananas", emoji: "🍍", syllables: ["A", "na", "nas"]),
        SyllableWord(word: "Krokodil", emoji: "🐊", syllables: ["Kro", "ko", "dil"]),
        SyllableWord(word: "Regenbogen", emoji: "🌈", syllables: ["Re", "gen", "bo", "gen"]),
        SyllableWord(word: "Avocado", emoji: "🥑", syllables: ["A", "vo", "ca", "do"]),
        SyllableWord(word: "Schokolade", emoji: "🍫", syllables: ["Scho", "ko", "la", "de"]),
        SyllableWord(word: "Krankenwagen", emoji: "🚑", syllables: ["Kran", "ken", "wa", "gen"]),
    ]

    static let syllableCountTexts = ["Eine Silbe!", "Zwei Silben!", "Drei Silben!", "Vier Silben!"]
    /// Je Stufe: höchste Silbenzahl der Wörter und der Antwortmöglichkeiten.
    /// Stufe 0: Wörter mit bis zu drei Silben, Stufe 1: bis vier, Stufe 2: nur lange Wörter (3–4 Silben).
    static let syllableLimits = [(words: 3, choices: 3), (words: 4, choices: 4), (words: 4, choices: 4)]

    static func syllableTasks(level: Int) -> [QuizTask] {
        let limits = syllableLimits[level]
        let pool = syllableWords.filter { $0.syllables.count <= limits.words && (level < 2 || $0.syllables.count >= 3) }
        return Array(pool.shuffled().prefix(tasksPerRound)).map { word in
            let count = word.syllables.count
            let choices = (1...limits.choices).map { claps in
                Choice(
                    content: .claps(claps),
                    isCorrect: claps == count,
                    spokenName: "\(claps)-mal klatschen",
                    wrongFeedback: "Hör nochmal genau hin. \(word.spokenSyllables)"
                )
            }
            return QuizTask(
                prompt: .word(emoji: word.emoji, syllables: word.spokenSyllables),
                instruction: "Wie oft klatschst du bei \(word.word)?",
                choices: choices,
                correctFeedback: "\(word.spokenSyllables) \(syllableCountTexts[count - 1])"
            )
        }
    }

    // MARK: - Reime finden (Vorschule)

    struct RhymeWord: Equatable {
        let word: String
        let emoji: String
    }

    /// Klare Reimpaare mit eindeutigen Bildern. Das erste Wort ist die Frage, das zweite die Antwort.
    /// Keine zwei Paare reimen sich untereinander – so ist immer genau eine Antwort richtig.
    static let rhymePairs: [(RhymeWord, RhymeWord)] = [
        (RhymeWord(word: "Maus", emoji: "🐭"), RhymeWord(word: "Haus", emoji: "🏠")),
        (RhymeWord(word: "Kuh", emoji: "🐮"), RhymeWord(word: "Schuh", emoji: "👟")),
        (RhymeWord(word: "Katze", emoji: "🐱"), RhymeWord(word: "Tatze", emoji: "🐾")),
        (RhymeWord(word: "Hose", emoji: "👖"), RhymeWord(word: "Rose", emoji: "🌹")),
        (RhymeWord(word: "Hase", emoji: "🐰"), RhymeWord(word: "Nase", emoji: "👃")),
        (RhymeWord(word: "Brot", emoji: "🍞"), RhymeWord(word: "Boot", emoji: "⛵️")),
        (RhymeWord(word: "Zahn", emoji: "🦷"), RhymeWord(word: "Hahn", emoji: "🐓")),
        (RhymeWord(word: "Schwein", emoji: "🐷"), RhymeWord(word: "Bein", emoji: "🦵")),
        (RhymeWord(word: "Ziege", emoji: "🐐"), RhymeWord(word: "Fliege", emoji: "🪰")),
        (RhymeWord(word: "Wal", emoji: "🐋"), RhymeWord(word: "Schal", emoji: "🧣")),
        (RhymeWord(word: "Igel", emoji: "🦔"), RhymeWord(word: "Spiegel", emoji: "🪞")),
        (RhymeWord(word: "Rakete", emoji: "🚀"), RhymeWord(word: "Trompete", emoji: "🎺")),
        (RhymeWord(word: "Socke", emoji: "🧦"), RhymeWord(word: "Glocke", emoji: "🔔")),
        (RhymeWord(word: "Tanne", emoji: "🌲"), RhymeWord(word: "Kanne", emoji: "🫖")),
        (RhymeWord(word: "Hund", emoji: "🐶"), RhymeWord(word: "Mund", emoji: "👄")),
    ]

    static func rhymeTasks(level: Int) -> [QuizTask] {
        let optionCount = level == 2 ? 4 : 3
        let pairs = Array(rhymePairs.shuffled().prefix(tasksPerRound))
        return pairs.map { target, rhyme in
            // Falsche Antworten: Wörter aus anderen Paaren (sie reimen sich garantiert nicht).
            let others = rhymePairs.filter { $0.0 != target }.flatMap { [$0.0, $0.1] }.shuffled()
            let options = ([rhyme] + others.prefix(optionCount - 1)).shuffled()
            let choices = options.map { option in
                Choice(
                    content: .emoji(option.emoji),
                    isCorrect: option == rhyme,
                    spokenName: option.word,
                    wrongFeedback: "\(option.word). Das reimt sich nicht auf \(target.word)."
                )
            }
            // Huhu nennt alle Bilder beim Namen – Reime kann man nur hören, nicht sehen.
            let names = options.map { "\($0.word)." }.joined(separator: " ")
            return QuizTask(
                prompt: .word(emoji: target.emoji, syllables: "\(target.word)."),
                instruction: "Was reimt sich auf \(target.word)? \(names)",
                choices: choices,
                correctFeedback: "\(target.word) – \(rhyme.word), das reimt sich!"
            )
        }
    }

    // MARK: - Uhr lesen (Vorschule)

    /// „drei Uhr“, „halb vier“ – so, wie Kinder die Uhrzeit hören.
    static func timeText(hour: Int, minute: Int) -> String {
        if minute == 0 {
            return hour == 1 ? "ein Uhr" : "\(Phrases.numberWords[hour]) Uhr"
        }
        return "halb \(Phrases.numberWords[hour % 12 + 1])"
    }

    static func clockTasks(level: Int) -> [QuizTask] {
        let optionCount = level == 1 ? 4 : 3
        let targets: [(hour: Int, minute: Int)] = Array(1...12).shuffled().prefix(tasksPerRound).map { hour in
            (hour: hour, minute: level == 2 && Bool.random() ? 30 : 0)
        }
        return targets.map { target in
            var options: [(hour: Int, minute: Int)] = [target]
            if level == 2 {
                // Typische Verwechslung: dieselbe Stunde, andere Hälfte.
                options.append((hour: target.hour, minute: target.minute == 0 ? 30 : 0))
            }
            for hour in Array(1...12).shuffled() where options.count < optionCount {
                let candidate = (hour: hour, minute: level == 2 && Bool.random() ? 30 : 0)
                if !options.contains(where: { $0.hour == candidate.hour && $0.minute == candidate.minute }) {
                    options.append(candidate)
                }
            }
            let targetText = timeText(hour: target.hour, minute: target.minute)
            let choices = options.shuffled().map { option in
                Choice(
                    content: .clock(hour: option.hour, minute: option.minute),
                    isCorrect: option.hour == target.hour && option.minute == target.minute,
                    spokenName: timeText(hour: option.hour, minute: option.minute),
                    wrongFeedback: "Hier ist es \(timeText(hour: option.hour, minute: option.minute)). Wo ist es \(targetText)?"
                )
            }
            return QuizTask(
                prompt: .empty,
                instruction: "Wo ist es \(targetText)?",
                choices: choices,
                correctFeedback: "Es ist \(targetText)."
            )
        }
    }
}

// MARK: - Welche Zahl fehlt?

extension TaskFactory {
    /// Größte Zahl je Stufe; ab Stufe 2 auch rückwärts.
    static let missingNumberLimits = [10, 20, 20]
    static let countBackwards = "Hier zählen wir rückwärts!"
    static let countFromStart = "Zähl noch einmal von vorne!"

    static func missingNumberTasks(level: Int) -> [QuizTask] {
        let upper = missingNumberLimits[level]
        let length = 5
        return (0..<tasksPerRound).map { _ in
            let start = Int.random(in: 1...(upper - length + 1))
            var numbers = Array(start..<(start + length))
            let backwards = level == 2 && Bool.random()
            if backwards { numbers.reverse() }
            // Nie die erste Zahl weglassen – die Reihe braucht einen Anfang.
            let gap = Int.random(in: 1..<length)
            let answer = numbers[gap]
            let line: [Int?] = numbers.enumerated().map { $0.offset == gap ? nil : $0.element }

            var options: Set<Int> = [answer]
            while options.count < 3 {
                let candidate = answer + Int.random(in: -3...3)
                if (1...upper).contains(candidate) { options.insert(candidate) }
            }
            let choices = options.shuffled().map { value in
                Choice(
                    content: .number(value),
                    isCorrect: value == answer,
                    spokenName: "\(value)",
                    wrongFeedback: countFromStart
                )
            }
            return QuizTask(
                prompt: .numberLine(line),
                instruction: backwards ? "Welche Zahl fehlt? \(countBackwards)" : "Welche Zahl fehlt?",
                choices: choices,
                correctFeedback: "\(Phrases.numberWords[answer].capitalized)!"
            )
        }
    }
}

// MARK: - Oben, unten, neben, hinter

extension TaskFactory {
    struct PositionAnimal: Equatable {
        let emoji: String
        /// Mit Artikel, z. B. „die Katze“.
        let name: String
    }

    static let positionAnimals: [PositionAnimal] = [
        .init(emoji: "🐱", name: "die Katze"),
        .init(emoji: "🐶", name: "der Hund"),
        .init(emoji: "🐭", name: "die Maus"),
        .init(emoji: "🐰", name: "der Hase"),
    ]

    /// Welche Begriffe je Stufe vorkommen: erst auf/unter/neben, dann vor/hinter, zuletzt links/rechts.
    static let positionLevels: [[SpatialPosition]] = [
        [.on, .under, .beside],
        [.inFront, .behind, .beside],
        [.left, .right, .on],
    ]

    static func positionQuestion(_ animal: PositionAnimal) -> String {
        "Wo ist \(animal.name)?"
    }

    static func positionAnswer(_ position: SpatialPosition) -> String {
        "\(position.phrase.prefix(1).uppercased())\(position.phrase.dropFirst())!"
    }

    static func positionStatement(_ animal: PositionAnimal, _ position: SpatialPosition) -> String {
        "\(animal.name.prefix(1).uppercased())\(animal.name.dropFirst()) ist \(position.phrase)."
    }

    static func positionTasks(level: Int) -> [QuizTask] {
        let positions = positionLevels[level]
        let targets = varied(positions, count: tasksPerRound)
        let animals = varied(positionAnimals, count: tasksPerRound)
        return zip(targets, animals).map { target, animal in
            let others = positions.filter { $0 != target }.shuffled().prefix(2)
            let options = ([target] + others).shuffled()
            let tablecloth = positions.contains { $0.needsTablecloth }
            let choices = options.map { position in
                Choice(
                    content: .scene(animal: animal.emoji, position: position, tablecloth: tablecloth),
                    isCorrect: position == target,
                    spokenName: positionStatement(animal, position),
                    wrongFeedback: positionStatement(animal, position)
                )
            }
            return QuizTask(
                prompt: .empty,
                // Frage und Antwort-Begriff: Das Kind hört die räumliche Sprache vorgemacht.
                instruction: "\(positionQuestion(animal)) \(positionAnswer(target))",
                choices: choices,
                correctFeedback: positionStatement(animal, target)
            )
        }
    }
}
