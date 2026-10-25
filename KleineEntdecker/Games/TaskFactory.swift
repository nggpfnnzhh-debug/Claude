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
        case .memory: return []
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

    /// Je Stufe: Mengenbereich und Mindestabstand. Ab 2, damit „Hier sind es …“ immer stimmt.
    static let moreLessRanges: [(range: ClosedRange<Int>, minimumDifference: Int)] = [
        (2...5, 2), (2...8, 2), (2...10, 1),
    ]

    static func moreLessTasks(level: Int) -> [QuizTask] {
        let (range, minimumDifference) = moreLessRanges[level]
        return varied(currentCountItems, count: tasksPerRound).map { item in
            var a = 0, b = 0
            repeat {
                a = Int.random(in: range)
                b = Int.random(in: range)
            } while abs(a - b) < minimumDifference
            // Stufe 0 fragt nur nach „mehr“ – das ist für Kinder leichter als „weniger“.
            let askMore = level == 0 || Bool.random()
            let answer = askMore ? max(a, b) : min(a, b)
            let other = askMore ? min(a, b) : max(a, b)

            let choices = [a, b].map { count in
                Choice(
                    content: .group(item.emoji, count: count),
                    isCorrect: count == answer,
                    spokenName: "\(count) \(item.plural)",
                    wrongFeedback: "Zähl mal nach! Hier sind es \(Phrases.numberWords[other])."
                )
            }
            return QuizTask(
                prompt: .empty,
                instruction: "Wo sind \(askMore ? "mehr" : "weniger") \(item.plural)?",
                choices: choices,
                correctFeedback: "Hier sind es \(Phrases.numberWords[answer]). \(askMore ? "Das sind mehr!" : "Das sind weniger!")"
            )
        }
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
    static let syllableLimits = [(words: 2, choices: 3), (words: 3, choices: 3), (words: 4, choices: 4)]

    static func syllableTasks(level: Int) -> [QuizTask] {
        let limits = syllableLimits[level]
        let pool = syllableWords.filter { $0.syllables.count <= limits.words }
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
