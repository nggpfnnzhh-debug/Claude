import XCTest
@testable import KleineEntdecker

final class NewPreschoolGamesTests: XCTestCase {
    func testMissingNumberLinesAreConsecutiveWithOneGap() {
        for level in 0...Game.missingNumber.maxLevel {
            for task in TaskFactory.tasks(for: .missingNumber, level: level) {
                guard case let .numberLine(line) = task.prompt else { return XCTFail("Keine Zahlenreihe") }
                XCTAssertEqual(line.filter { $0 == nil }.count, 1)
                XCTAssertNotNil(line.first ?? nil, "Die erste Zahl darf nicht fehlen")
                let answer = task.choices.first(where: \.isCorrect)
                guard case let .number(value) = answer?.content else { return XCTFail("Keine richtige Zahl") }
                let filled = line.map { $0 ?? value }
                let steps = Set(zip(filled, filled.dropFirst()).map { $1 - $0 })
                XCTAssertTrue(steps == [1] || steps == [-1], "Reihe \(filled) ist nicht lückenlos")
                XCTAssertTrue(filled.allSatisfy { (1...TaskFactory.missingNumberLimits[level]).contains($0) })
                XCTAssertEqual(Set(task.choices.map(\.spokenName)).count, 3)
            }
        }
    }

    func testPositionsUseOnlyTermsOfTheLevel() {
        for level in 0...Game.positions.maxLevel {
            for task in TaskFactory.tasks(for: .positions, level: level) {
                XCTAssertEqual(task.choices.filter(\.isCorrect).count, 1)
                for choice in task.choices {
                    guard case let .scene(_, position) = choice.content else { return XCTFail("Kein Bild") }
                    XCTAssertTrue(TaskFactory.positionLevels[level].contains(position))
                }
            }
        }
        XCTAssertEqual(TaskFactory.positionStatement(TaskFactory.positionAnimals[0], .under), "Die Katze ist unter dem Tisch.")
        XCTAssertEqual(TaskFactory.positionAnswer(.behind), "Hinter dem Tisch!")
    }

    func testStoriesAreNeverAlreadySorted() {
        for level in 0...Game.story.maxLevel {
            for task in Stories.tasks(level: level) {
                XCTAssertNotEqual(task.shuffledIndices, Array(task.story.steps.indices))
                XCTAssertEqual(task.shuffledIndices.sorted(), Array(task.story.steps.indices))
                XCTAssertTrue(level != 0 || task.story.steps.count == 3)
                XCTAssertTrue(level != 2 || task.story.steps.count == 4)
            }
        }
    }
}
