import SwiftUI
import UIKit
import XCTest
@testable import KleineEntdecker

final class TaskFactoryTests: XCTestCase {
    private let quizGames = Game.allCases.filter { $0 != .memory }

    func testEveryTaskHasExactlyOneCorrectAndUniqueChoices() {
        for game in quizGames {
            for level in 0...game.maxLevel {
                for _ in 0..<60 {
                    let tasks = TaskFactory.tasks(for: game, level: level)
                    XCTAssertEqual(tasks.count, TaskFactory.tasksPerRound, "\(game) Stufe \(level)")
                    for task in tasks {
                        XCTAssertEqual(task.choices.filter(\.isCorrect).count, 1, "\(game): \(task.instruction)")
                        XCTAssertGreaterThanOrEqual(task.choices.count, game == .moreLess ? 2 : 3, "\(game)")
                        XCTAssertEqual(Set(task.choices.map(\.content)).count, task.choices.count, "\(game): doppelte Antwort")
                    }
                }
            }
        }
    }

    func testCountingRespectsLevelLimits() {
        for level in 0...Game.counting.maxLevel {
            let upper = TaskFactory.countingLimits[level]
            for _ in 0..<100 {
                for task in TaskFactory.tasks(for: .counting, level: level) {
                    guard case let .objects(_, count) = task.prompt else { return XCTFail("Falscher Prompt") }
                    XCTAssertTrue((1...upper).contains(count))
                    for choice in task.choices {
                        guard case let .number(value) = choice.content else { return XCTFail("Falscher Inhalt") }
                        XCTAssertTrue((1...upper).contains(value))
                        XCTAssertEqual(choice.isCorrect, value == count)
                    }
                }
            }
        }
    }

    func testCountingTasksDoNotRepeatNumbersWithinRound() {
        let counts = TaskFactory.tasks(for: .counting, level: 0).compactMap { task -> Int? in
            if case let .objects(_, count) = task.prompt { return count }
            return nil
        }
        XCTAssertEqual(Set(counts).count, counts.count)
    }

    func testLetterWordsStartWithTheirLetter() {
        for word in TaskFactory.letterWords {
            XCTAssertTrue(word.word.uppercased().hasPrefix(word.letter), word.word)
        }
        // „Pf“, „Sch“, „Ch“ und „Ei“ sind keine einfachen Anlaute.
        for word in TaskFactory.letterWords {
            for cluster in ["PF", "SCH", "CH", "EI"] {
                XCTAssertFalse(word.word.uppercased().hasPrefix(cluster), "\(word.word) beginnt mit \(cluster)")
            }
        }
    }

    func testAnchorWordsStartWithLetterAndAreNeverAnswers() {
        let letters = Set(TaskFactory.letterWords.map(\.letter))
        XCTAssertEqual(Set(TaskFactory.anchorWords.keys), letters, "jeder Buchstabe braucht ein Ankerwort")
        let answers = Set(TaskFactory.letterWords.map(\.word))
        for (letter, anchor) in TaskFactory.anchorWords {
            XCTAssertTrue(anchor.uppercased().hasPrefix(letter), anchor)
            XCTAssertFalse(answers.contains(anchor), "\(anchor) würde die Lösung verraten")
        }
    }

    func testLetterTasksCorrectChoiceMatchesLetter() {
        for level in 0...Game.letters.maxLevel {
            for _ in 0..<60 {
                for task in TaskFactory.tasks(for: .letters, level: level) {
                    guard case let .letter(letter, _) = task.prompt else { return XCTFail("Falscher Prompt") }
                    let correct = task.choices.first(where: \.isCorrect)
                    XCTAssertTrue(correct?.spokenName.uppercased().hasPrefix(letter) ?? false)
                    for wrong in task.choices where !wrong.isCorrect {
                        XCTAssertFalse(wrong.spokenName.uppercased().hasPrefix(letter))
                    }
                }
            }
        }
    }

    func testPatternAnswerContinuesSequence() {
        for level in 0...Game.patterns.maxLevel {
            for _ in 0..<60 {
                for task in TaskFactory.tasks(for: .patterns, level: level) {
                    guard case let .sequence(items) = task.prompt,
                          case let .emoji(answer)? = task.choices.first(where: \.isCorrect)?.content else {
                        return XCTFail("Ungültige Musteraufgabe")
                    }
                    let period = (1...items.count).first { p in
                        items.indices.allSatisfy { items[$0] == items[$0 % p] }
                    } ?? items.count
                    XCTAssertEqual(answer, items[items.count % period], "\(items)")
                }
            }
        }
    }

    func testMoreLessCorrectGroupMatchesQuestion() {
        for level in 0...Game.moreLess.maxLevel {
            for _ in 0..<60 {
                for task in TaskFactory.tasks(for: .moreLess, level: level) {
                    let counts = task.choices.compactMap { choice -> Int? in
                        if case let .group(_, count) = choice.content { return count }
                        return nil
                    }
                    XCTAssertEqual(counts.count, 2)
                    guard case let .group(_, answer)? = task.choices.first(where: \.isCorrect)?.content else {
                        return XCTFail("Keine richtige Gruppe")
                    }
                    let asksMore = task.instruction.contains(" mehr ")
                    XCTAssertEqual(answer, asksMore ? counts.max() : counts.min(), task.instruction)
                    XCTAssertTrue(counts.allSatisfy { $0 >= 2 }, "„Hier sind es eins“ wäre falsches Deutsch")
                }
            }
        }
    }

    func testSyllableAnswerMatchesSyllableCount() {
        for word in TaskFactory.syllableWords {
            XCTAssertEqual(word.syllables.joined().lowercased(), word.word.lowercased(), word.word)
        }
        for level in 0...Game.syllables.maxLevel {
            for task in TaskFactory.tasks(for: .syllables, level: level) {
                guard case let .word(_, syllables) = task.prompt,
                      case let .claps(claps)? = task.choices.first(where: \.isCorrect)?.content else {
                    return XCTFail("Ungültige Silbenaufgabe")
                }
                XCTAssertEqual(syllables.split(separator: "-").count, claps, syllables)
            }
        }
    }

    func testRhymeAnswerIsPartner() {
        let partners = Dictionary(uniqueKeysWithValues: TaskFactory.rhymePairs.map { ($0.0.word, $0.1.word) })
        let allWords = TaskFactory.rhymePairs.flatMap { [$0.0.word, $0.1.word] }
        XCTAssertEqual(Set(allWords).count, allWords.count, "jedes Wort nur einmal")
        for level in 0...Game.rhymes.maxLevel {
            for _ in 0..<60 {
                for task in TaskFactory.tasks(for: .rhymes, level: level) {
                    guard case let .word(_, spoken) = task.prompt else { return XCTFail("Falscher Prompt") }
                    let target = String(spoken.dropLast())
                    let correct = task.choices.first(where: \.isCorrect)?.spokenName
                    XCTAssertEqual(correct, partners[target], target)
                    // Alle Bilder werden in der Anweisung benannt.
                    for choice in task.choices {
                        XCTAssertTrue(task.instruction.contains(choice.spokenName + "."), choice.spokenName)
                    }
                }
            }
        }
    }

    func testClockTimeTexts() {
        XCTAssertEqual(TaskFactory.timeText(hour: 1, minute: 0), "ein Uhr")
        XCTAssertEqual(TaskFactory.timeText(hour: 3, minute: 0), "drei Uhr")
        XCTAssertEqual(TaskFactory.timeText(hour: 3, minute: 30), "halb vier")
        XCTAssertEqual(TaskFactory.timeText(hour: 12, minute: 30), "halb eins")
        // Volle Stunden auf Stufe 0 und 1, halbe erst ab Stufe 2.
        for level in 0...1 {
            for task in TaskFactory.tasks(for: .clock, level: level) {
                for choice in task.choices {
                    guard case let .clock(_, minute) = choice.content else { return XCTFail("Keine Uhr") }
                    XCTAssertEqual(minute, 0)
                }
            }
        }
    }
}

final class ProgressStoreTests: XCTestCase {
    private func makeStore() throws -> (ProgressStore, UserDefaults, String) {
        let suite = "ProgressStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        return (ProgressStore(defaults: defaults), defaults, suite)
    }

    func testStarsAndResultsArePersistedAndResettable() throws {
        let (store, defaults, suite) = try makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.completeRound(for: .counting, result: RoundResult(firstTry: 5, total: 5))
        store.completeRound(for: .counting, result: RoundResult(firstTry: 1, total: 5))
        store.completeRound(for: .memory, result: RoundResult(firstTry: 4, total: 6))
        XCTAssertEqual(store.stars(for: .counting), 2)
        XCTAssertEqual(store.totalStars, 3)

        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.totalStars, 3)
        XCTAssertEqual(reloaded.firstTryRate(for: .counting) ?? -1, 0.6, accuracy: 0.001)

        reloaded.reset()
        let afterReset = ProgressStore(defaults: defaults)
        XCTAssertEqual(afterReset.totalStars, 0)
        XCTAssertNil(afterReset.firstTryRate(for: .counting))
        XCTAssertEqual(afterReset.level(for: .counting), 0)
    }

    func testLevelAdaptsToResults() throws {
        let (store, defaults, suite) = try makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(store.level(for: .colors), 0)
        store.completeRound(for: .colors, result: RoundResult(firstTry: 5, total: 5))
        XCTAssertEqual(store.level(for: .colors), 1)
        store.completeRound(for: .colors, result: RoundResult(firstTry: 4, total: 5))
        XCTAssertEqual(store.level(for: .colors), 2)
        store.completeRound(for: .colors, result: RoundResult(firstTry: 5, total: 5))
        XCTAssertEqual(store.level(for: .colors), 2, "nicht über die höchste Stufe hinaus")
        store.completeRound(for: .colors, result: RoundResult(firstTry: 1, total: 5))
        XCTAssertEqual(store.level(for: .colors), 1, "bei Schwierigkeiten wieder leichter")
    }

    func testTipsListPracticeGamesFirst() throws {
        let (store, defaults, suite) = try makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        for _ in 0..<2 {
            store.completeRound(for: .letters, result: RoundResult(firstTry: 1, total: 5))
            store.completeRound(for: .counting, result: RoundResult(firstTry: 5, total: 5))
        }
        XCTAssertEqual(store.gamesForTips().first, .letters)
        XCTAssertTrue(store.needsPractice(.letters))
        XCTAssertFalse(store.needsPractice(.counting))
        XCTAssertFalse(store.needsPractice(.shapes), "ohne gespielte Runden keine Einschätzung")
    }
}

final class ChildProfileTests: XCTestCase {
    func testNicknamesAreUniqueAndUseValidAdjectives() {
        let names = ChildProfile.nicknames.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
        XCTAssertFalse(names.contains("Eule"), "Die Eule ist Huhu – kein Spitzname fürs Kind")
        for nickname in ChildProfile.nicknames {
            XCTAssertTrue(ChildProfile.adjectives.contains(nickname.adjective), nickname.name)
        }
    }

    func testTitleAndSpokenName() {
        XCTAssertEqual(ChildProfile.title(name: "Max", adjective: "Kleiner"), "Kleiner Max")
        XCTAssertEqual(ChildProfile.title(name: "  ", adjective: "Kleiner"), ChildProfile.defaultTitle)
        XCTAssertEqual(ChildProfile.spokenName(name: "Biene", adjective: "Kleine"), "kleine Biene")
        XCTAssertNil(ChildProfile.spokenName(name: "", adjective: "Kleine"))
    }

    func testOnlyRecordedNicknamesAreSpoken() {
        XCTAssertEqual(ChildProfile.recordedSpokenName(name: "Biene", adjective: "Kleine"), "kleine Biene")
        XCTAssertNil(ChildProfile.recordedSpokenName(name: "Max", adjective: "Kleiner"), "eingetippte Namen nur anzeigen")
    }
}

final class PaletteTests: XCTestCase {
    /// Kinder müssen alle Farben sicher auseinanderhalten können (z. B. Rosa ≠ Rot).
    func testPaletteColorsAreClearlyDistinct() {
        let components = TaskFactory.palette.map { named -> (String, [CGFloat]) in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            UIColor(named.color).getRed(&r, green: &g, blue: &b, alpha: &a)
            return (named.name, [r, g, b])
        }
        for i in components.indices {
            for j in components.indices where j > i {
                let (nameA, a) = components[i]
                let (nameB, b) = components[j]
                var sum: CGFloat = 0
                for (x, y) in zip(a, b) {
                    let d: CGFloat = x - y
                    sum += d * d
                }
                let distance: CGFloat = sqrt(sum) * 255
                XCTAssertGreaterThan(distance, 70, "\(nameA) und \(nameB) sind zu ähnlich")
            }
        }
    }
}
