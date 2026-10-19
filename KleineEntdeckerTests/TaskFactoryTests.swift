import SwiftUI
import UIKit
import XCTest
@testable import KleineEntdecker

final class TaskFactoryTests: XCTestCase {
    private let quizGames = Game.allCases.filter { $0 != .memory }

    func testEveryTaskHasExactlyOneCorrectAndUniqueChoices() {
        for game in quizGames {
            for _ in 0..<100 {
                let tasks = TaskFactory.tasks(for: game, countingUpTo: 10)
                XCTAssertEqual(tasks.count, TaskFactory.tasksPerRound, "\(game)")
                for task in tasks {
                    XCTAssertEqual(task.choices.filter(\.isCorrect).count, 1, "\(game): \(task.instruction)")
                    XCTAssertGreaterThanOrEqual(task.choices.count, 3, "\(game)")
                    XCTAssertEqual(Set(task.choices.map(\.content)).count, task.choices.count, "\(game): doppelte Antwort")
                }
            }
        }
    }

    func testCountingRespectsUpperLimit() {
        for _ in 0..<100 {
            for task in TaskFactory.tasks(for: .counting, countingUpTo: 5) {
                guard case let .objects(_, count) = task.prompt else { return XCTFail("Falscher Prompt") }
                XCTAssertTrue((1...5).contains(count))
                for choice in task.choices {
                    guard case let .number(value) = choice.content else { return XCTFail("Falscher Inhalt") }
                    XCTAssertTrue((1...5).contains(value))
                    XCTAssertEqual(choice.isCorrect, value == count)
                }
            }
        }
    }

    func testCountingTasksDoNotRepeatNumbersWithinRound() {
        let counts = TaskFactory.tasks(for: .counting, countingUpTo: 5).compactMap { task -> Int? in
            if case let .objects(_, count) = task.prompt { return count }
            return nil
        }
        XCTAssertEqual(Set(counts).count, counts.count)
    }

    func testLetterWordsStartWithTheirLetter() {
        for word in TaskFactory.letterWords {
            XCTAssertTrue(word.word.uppercased().hasPrefix(word.letter), word.word)
        }
    }

    func testLetterTasksCorrectChoiceMatchesLetter() {
        for _ in 0..<100 {
            for task in TaskFactory.tasks(for: .letters, countingUpTo: 5) {
                guard case let .letter(letter) = task.prompt else { return XCTFail("Falscher Prompt") }
                let correct = task.choices.first(where: \.isCorrect)
                XCTAssertTrue(correct?.spokenName.uppercased().hasPrefix(letter) ?? false)
                for wrong in task.choices where !wrong.isCorrect {
                    XCTAssertFalse(wrong.spokenName.uppercased().hasPrefix(letter))
                }
            }
        }
    }

    func testPatternAnswerContinuesSequence() {
        for _ in 0..<100 {
            for task in TaskFactory.tasks(for: .patterns, countingUpTo: 5) {
                guard case let .sequence(items) = task.prompt,
                      case let .emoji(answer)? = task.choices.first(where: \.isCorrect)?.content else {
                    return XCTFail("Ungültige Musteraufgabe")
                }
                // Die kleinste Periode der gezeigten Folge muss die Antwort bestimmen.
                let period = (1...items.count).first { p in
                    items.indices.allSatisfy { items[$0] == items[$0 % p] }
                } ?? items.count
                XCTAssertEqual(answer, items[items.count % period], "\(items)")
            }
        }
    }
}

final class ProgressStoreTests: XCTestCase {
    func testStarsArePersistedAndResettable() throws {
        let suite = "ProgressStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ProgressStore(defaults: defaults)
        store.addStar(for: .counting)
        store.addStar(for: .counting)
        store.addStar(for: .memory)
        XCTAssertEqual(store.stars(for: .counting), 2)
        XCTAssertEqual(store.totalStars, 3)

        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.totalStars, 3)

        reloaded.reset()
        XCTAssertEqual(ProgressStore(defaults: defaults).totalStars, 0)
    }
}

final class ChildProfileTests: XCTestCase {
    func testNicknamesAreUniqueAndUseValidAdjectives() {
        let names = ChildProfile.nicknames.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
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
                let distance = sqrt(zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)) * 255
                XCTAssertGreaterThan(distance, 70, "\(nameA) und \(nameB) sind zu ähnlich")
            }
        }
    }
}
